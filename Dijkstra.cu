#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <time.h>
#include <cstdio>

#define UNKNOWN_DISTANCE -1
#define UNKNOWN_NODE -2
#define NO_EDGE_BEWTEEN -3
#define GENEDGE_HAS_PATH_TO_START 0
#define GENEDGE_NO_PATH_TO_START -1
#define MAXIMUM_WEIGHT 100
#define NODE_VISITED 1
#define NODE_UNVISITED 0
#define INT32_MAX 2147483647

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    //std::cout << "gpuErrchk: " << cudaGetErrorString(code) << std::endl;
   if (code != cudaSuccess) 
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}

int DijkstraSelectNode(int nodeNum, int* visited, int* disFromStart){
    int curClosestNode = -1;
    int curClosestDistance = INT32_MAX;
    for(int i=0; i<nodeNum; i++){
        if((visited[i] == NODE_UNVISITED) 
           && (disFromStart[i] != UNKNOWN_DISTANCE)
           && (disFromStart[i] < curClosestDistance)) {
            curClosestNode = i;
            curClosestDistance = disFromStart[i];
        }
    }
    return curClosestNode;
}
__global__ void divide100(int nodeNum,int *visited_addr,int *dis_addr,int *max_addr,int *index_addr)
{
    int b = nodeNum/100;
    int start = threadIdx.x * b;

    int curClosestNode = -1;
    int curClosestDistance = INT32_MAX;
    for(int i=start; i<start+b; i++){
        if((visited_addr[i] == NODE_UNVISITED)  && (dis_addr[i] != UNKNOWN_DISTANCE)  && (dis_addr[i] < curClosestDistance)) {
            curClosestNode = i;
            curClosestDistance = dis_addr[i];
        }
    }
    //printf("thread %d closest dis = %d\n",threadIdx.x,curClosestDistance);
    max_addr[threadIdx.x]=curClosestDistance;
    index_addr[threadIdx.x]=curClosestNode;
}

__global__ void select(int nodeNum,int *visited_addr,int *max_addr,int *index_addr,int *cur_addr)
{
    int cur=0;
    int curClosestDistance = INT32_MAX;
    for(int i=0;i<100;i++)
    {
        //printf("i=%d max=%d\n",i,max_addr[i]);
        if(max_addr[i]<curClosestDistance)
        {
            curClosestDistance = max_addr[i];
            cur=index_addr[i];
        }
    }
    *cur_addr = cur;
    visited_addr[cur]=NODE_VISITED;
    //printf("current=%d\n",cur);
}

__global__ void selectall(int nodeNum,int *visited_addr,int *dis_addr,int *cur_addr)
{
    int cur=0;
    int curClosestDistance = INT32_MAX;
    for(int i=0;i<nodeNum;i++)
    {
        if((visited_addr[i] == NODE_UNVISITED)  && (dis_addr[i] != UNKNOWN_DISTANCE)  && (dis_addr[i] < curClosestDistance)) 
        {
            curClosestDistance = dis_addr[i];
            cur=i;
        }
    }
    *cur_addr = cur;
    visited_addr[cur]=NODE_VISITED;
    //printf("current=%d\n",cur);
}
__global__ void test( int *disFromStart,int nodeNum)
{
    for(int i =0 ; i<nodeNum;i++)
    {
        printf("node %d dis = %d",i,disFromStart[i]);
    }
}
__global__ void init(int* visited_addr, int *dis_addr, int* prevNode_addr,int nodeNum )
{
    int i = blockIdx.x*1024 + threadIdx.x;
    if(i<nodeNum) //boundery check
    {    
        if(i==0)
        {
            dis_addr[i]=0;
            prevNode_addr[i]=0;
        }
        else
        {
            visited_addr[i]=NODE_UNVISITED;
            dis_addr[i]=UNKNOWN_DISTANCE;
            prevNode_addr[i]=-2;
        }
    }
}

__global__ void visit_update(int* visited_addr, int *cur_addr)
{
    visited_addr[*cur_addr]=NODE_VISITED;
} 
__global__ void update( int *edges, int* visited, int *disFromStart,int *prevNode, int* cur_addr ,int nodeNum )
{
    int    i = blockIdx.x*blockDim.x + threadIdx.x;
    int curNode = *cur_addr;
    if(i<nodeNum) //boundery check
    {        
        if((visited[i] != NODE_VISITED) && (i != curNode) )
        {
            if(edges[i+curNode*nodeNum] != NO_EDGE_BEWTEEN)
            {
                if ( (disFromStart[i] == UNKNOWN_DISTANCE)  || (disFromStart[i] > (disFromStart[curNode] + edges[i+curNode*nodeNum])) )
                {
                    disFromStart[i] = (disFromStart[curNode] + edges[i+curNode*nodeNum]);
                    prevNode[i] = curNode;
                }
            }
        }
    } 
}
void DijkstraMain(int nodeNum, int edgeNum,void * e, int* disFromStart, int* prevNode){
    clock_t ini,inid,start,divi,mid,u;
    ini = clock();
    std::cout <<"start disj\n"  << std::endl;
    int (*edges)[nodeNum] = (int (*)[nodeNum])e;
    // Initialize visited list
    int block = (nodeNum-1)/1024 +1;
    int size = block*1024*sizeof(int);

    //int *visited = (int*)malloc(sizeof(int) *  block * 1024);
    int *edges_addr;
    int *dis_addr, *visited_addr, *prevNode_addr;//size
    int *max_addr,*index_addr;//100
    int *cur_addr;
    
    float selectt, updatet;
    selectt = 0.0;
    updatet = 0.0;
    gpuErrchk(cudaMalloc(&dis_addr,size));
    gpuErrchk(cudaMalloc(&visited_addr,size));
    gpuErrchk(cudaMalloc(&prevNode_addr,size));
    gpuErrchk(cudaMalloc(&cur_addr,sizeof(int))); 
    gpuErrchk(cudaMalloc(&max_addr,100*sizeof(int)));
    gpuErrchk(cudaMalloc(&index_addr,100*sizeof(int)));
    gpuErrchk(cudaMalloc(&edges_addr,nodeNum* nodeNum * sizeof(int))); //nodenum * size of int x nodenum
    //inid = clock();
    //printf("malloc= %lf", ((double) (inid - ini)) / CLOCKS_PER_SEC);
    //cudaMemset(edges_addr,0x01,pitch* nodeNum * sizeof(int));
    gpuErrchk(cudaMemcpy(edges_addr,edges, nodeNum* nodeNum * sizeof(int), cudaMemcpyHostToDevice));
    //ini = clock();
    //printf("memcpy= %lf", ((double) (ini - inid)) / CLOCKS_PER_SEC);
    //gpuErrchk(cudaMemcpy(visited_addr,visited,size,cudaMemcpyHostToDevice));
    //gpuErrchk(cudaMemcpy(prevNode_addr,prevNode,size,cudaMemcpyHostToDevice));
    //test<<<1,1024>>>();
    //cudaDeviceSynchronize();
    init<<<block,1024>>>(visited_addr, dis_addr,prevNode_addr,nodeNum); 
    //cudaDeviceSynchronize();
    inid = clock();
    //printf("init func= %lf", ((double) (inid - ini)) / CLOCKS_PER_SEC);
    //std::cout <<"init complete";
    for (int i=0; i<nodeNum; i++) {
        //int curNode = DijkstraSelectNode(nodeNum, visited, disFromStart); 
        //start = clock();
        divide100<<<1,100>>>(nodeNum,visited_addr,dis_addr,max_addr,index_addr);
        //divi = clock();
        select<<<1,1>>>(nodeNum,visited_addr,max_addr,index_addr,cur_addr);
        //selectall<<<1,1>>>(nodeNum,visited_addr,dis_addr,cur_addr);
        //mid = clock();
        //save to current node in cuda
        update<<<block,1024>>>(edges_addr, visited_addr, dis_addr, prevNode_addr, cur_addr, nodeNum);
        //u  = clock();
        //gpuErrchk(cudaMemcpy(disFromStart,dis_addr,size,cudaMemcpyDeviceToHost));
        //visit_update<<<1,1>>>(visited_addr,cur_addr);
        
        //printf("divide= %lf select= %lf update= %lf   \n", ((double) (divi - start)) / CLOCKS_PER_SEC,((double) (mid - divi)) / CLOCKS_PER_SEC,((double) (u - mid)) / CLOCKS_PER_SEC);
        //selectt += ((double) (mid - divi)) / CLOCKS_PER_SEC;
        //updatet += ((double) (u - mid)) / CLOCKS_PER_SEC;
        //printf("round %d   \n",i);
        //printf("dijk = %lf \n", ((double) (end - start)) / CLOCKS_PER_SEC);
    }
    ini = clock();
    printf("for looop= %lf", ((double) (ini - inid)) / CLOCKS_PER_SEC);
    //printf("select= %lf, update= %lf\n", selectt, updatet);
    gpuErrchk(cudaMemcpy(disFromStart,dis_addr,size,cudaMemcpyDeviceToHost));
    gpuErrchk(cudaMemcpy(prevNode,prevNode_addr,size,cudaMemcpyDeviceToHost));
    gpuErrchk(cudaFree(dis_addr));
    gpuErrchk(cudaFree(visited_addr));
    gpuErrchk(cudaFree(prevNode_addr));
    gpuErrchk(cudaFree(edges_addr));
    //free(visited);
    //inid = clock();
    //printf("free= %lf", ((double) (inid - ini)) / CLOCKS_PER_SEC);
}

int main(int argc, char* argv[]){
    srand(time(NULL));
    // Check the number of nodes and average number of edges are provided.
    if(argc < 2){
        printf("Usage: %s [num of nodes] [num of edges] (option: --display-graph)\n", argv[0]);
        return 0;
    }
    if(std::atoi(argv[2]) < (std::atoi(argv[1]) - 1)){
        printf("%s: (num of edges) must greater than (num of nodes - 1)\n", argv[0]);
        return 0;
    }

    int nodeNum = std::atoi(argv[1]);
    int edgeNum = std::atoi(argv[2]);

    // Read input
    std::fstream input;
    input.open("graph", std::fstream::in | std::fstream::binary);
    int *edges = (int*)malloc(sizeof(int*) * nodeNum * nodeNum);
    //int edges[nodeNum][nodeNum];
    for (int i=0; i<nodeNum; i++){
        for (int j=i; j<nodeNum; j++){
            int tmp;
            input.read((char *)&tmp, sizeof(int));
            edges[i*nodeNum+j] = tmp;
            edges[j*nodeNum+i] = tmp;
        }
    }
    // ************************** //
    // *** DIJKSTRA ALGORITHM *** //
    // ************************** //
    printf("efge complete ");
    int block = (nodeNum-1)/1024 +1;
    // Initialize node list.
    // The node list is the distance to each node from node 0(which is the beginning.
    int *disFromStart = (int*)malloc(sizeof(int) * block * 1024);
    for (int i=0; i<nodeNum; i++) disFromStart[i] = UNKNOWN_DISTANCE;
    disFromStart[0] = 0;

    // Initialize previous node list.
    // The previous node list record the last node of each shortest path to each node.
    int *prevNode = (int*)malloc(sizeof(int) * block * 1024);
    for (int i=0; i<nodeNum; i++) prevNode[i] = UNKNOWN_NODE;
    prevNode[0] = 0;


    clock_t start , end;
	start = clock();
    double cpu_time_used;
    
    DijkstraMain(nodeNum, edgeNum, (void *)edges, disFromStart, prevNode);

    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
    printf("cuda = %lf \n", cpu_time_used);
    FILE* timeout;
    timeout = fopen("cuda_time.txt", "a");
    fprintf(timeout, "%lf\n", cpu_time_used);
    // ************************************ //
    // *** DIJKSTRA ALGORITHM COMPLETED *** //
    // ************************************ //


    // DEBUG: print the edge matrix
    //if(argc == 4){
    //    for (int i=0; i<nodeNum; i++) {
    //        for (int j=0; j<nodeNum; j++) {
    //            printf("%3d ",edges[i*nodeNum+j] == NO_EDGE_BEWTEEN ? 0 : edges[i*nodeNum+j]);
    //        }
    //        printf("\n");
    //    }
    //}

    // Output the shortest distance of every node from start.
    //printf("Shortest distance from start:\n");
    //for (int i=0; i<nodeNum; i++) {
     //   printf("%3d ",disFromStart[i]);
    //}

    // Output the last node of every node's shortest path.
    //printf("\n");
    //printf("\nPrevious node:\n");
    //for (int i=0; i<nodeNum; i++) {
    //    printf("%3d ",prevNode[i]);
    //}
    //printf("\n");


    // End of the program.
    free(disFromStart);
    free(prevNode);
    //for (int i=0; i<nodeNum; i++) free(edges[i]);
    //free(edges);
    return 0;
}