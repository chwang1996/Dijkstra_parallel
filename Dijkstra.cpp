#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <sys/time.h>

#define UNKNOWN_DISTANCE -1
#define UNKNOWN_NODE -2
#define NO_EDGE_BEWTEEN -3
#define GENEDGE_HAS_PATH_TO_START 0
#define GENEDGE_NO_PATH_TO_START -1
#define MAXIMUM_WEIGHT 100
#define NODE_VISITED 1
#define NODE_UNVISITED 0

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

void DijkstraUpdate(int nodeNum, int* visited, int** edges, int curNode, int* disFromStart, int* prevNode){
    int curDis = disFromStart[curNode];
    for(int i=0; i<nodeNum; i++) {
        if((visited[i] == NODE_VISITED) || (i == curNode)) continue;
        if(edges[curNode][i] != NO_EDGE_BEWTEEN){
            if ((disFromStart[i] == UNKNOWN_DISTANCE) 
                || (disFromStart[i] > (curDis + edges[curNode][i]))){
                disFromStart[i] = (curDis + edges[curNode][i]);
                prevNode[i] = curNode;
            }
        }
    }
}

void DijkstraMain(int nodeNum, int edgeNum, int** edges, int* disFromStart, int* prevNode){
    // Initialize visited list
    int *visited = (int*)malloc(sizeof(int) * nodeNum);         // Careful! can overflow.
    for (int i=0; i<nodeNum; i++) visited[i] = NODE_UNVISITED;
    for (int i=0; i<nodeNum; i++) {
        int curNode = DijkstraSelectNode(nodeNum, visited, disFromStart); 
        DijkstraUpdate(nodeNum, visited, edges, curNode, disFromStart, prevNode);
        visited[curNode] = NODE_VISITED;
    }
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
    int **edges = (int**)malloc(sizeof(int*) * nodeNum);
    for (int i=0; i<nodeNum; i++) edges[i] = (int*)malloc(sizeof(int) * nodeNum);
    for (int i=0; i<nodeNum; i++){
        for (int j=i; j<nodeNum; j++){
            int tmp;
            input.read((char *)&tmp, sizeof(int));
            edges[i][j] = tmp;
            edges[j][i] = tmp;
        }
    }
    
    printf("Input completed.\n");

    // Initialize timer.
    struct timeval start,end;

    // ************************** //
    // *** DIJKSTRA ALGORITHM *** //
    // ************************** //

    // Start timer
    gettimeofday(&start,NULL);

    // Initialize node list.
    // The node list is the distance to each node from node 0(which is the beginning.
    int *disFromStart = (int*)malloc(sizeof(int) * nodeNum);
    for (int i=0; i<nodeNum; i++) disFromStart[i] = UNKNOWN_DISTANCE;
    disFromStart[0] = 0;

    // Initialize previous node list.
    // The previous node list record the last node of each shortest path to each node.
    int *prevNode = (int*)malloc(sizeof(int) * nodeNum);
    for (int i=0; i<nodeNum; i++) prevNode[i] = UNKNOWN_NODE;
    prevNode[0] = 0;
    DijkstraMain(nodeNum, edgeNum, edges, disFromStart, prevNode);
    gettimeofday(&end,NULL);
    printf("Serial version of Dijkstra used %lf sec.\n", end.tv_sec-start.tv_sec+(double)(end.tv_usec-start.tv_usec)/1000000);
    std::fstream outputTime;
    outputTime.open("serial_time.txt", std::fstream::out | std::fstream::app);
    outputTime << end.tv_sec-start.tv_sec+(double)(end.tv_usec-start.tv_usec)/1000000 << std::endl;
    outputTime.close();
    // ************************************ //
    // *** DIJKSTRA ALGORITHM COMPLETED *** //
    // ************************************ //


    // DEBUG: print the edge matrix
    if(argc == 4){
        for (int i=0; i<nodeNum; i++) {
            for (int j=0; j<nodeNum; j++) {
                printf("%3d ",edges[i][j] == NO_EDGE_BEWTEEN ? 0 : edges[i][j]);
            }
            printf("\n");
        }
    }

    // Output the shortest distance of every node from start.
    printf("Shortest distance from start:\n");
    for (int i=0; i<nodeNum; i++) {
        printf("%3d ",disFromStart[i]);
    }

    // Output the last node of every node's shortest path.
    printf("\n");
    printf("\nPrevious node:\n");
    for (int i=0; i<nodeNum; i++) {
        printf("%3d ",prevNode[i]);
    }
    printf("\n");

    // Output result
    std::fstream outputDis, outputPre;
    outputDis.open("distance", std::fstream::out | std::fstream::trunc | std::fstream::binary);
    for(int i=0; i<nodeNum; i++){
        outputDis.write((char *)&(disFromStart[i]), sizeof(int));
    }
    outputDis.close();

    outputPre.open("prevnode", std::fstream::out | std::fstream::trunc | std::fstream::binary);
    for(int i=0; i<nodeNum; i++){
        outputPre.write((char *)&(prevNode[i]), sizeof(int));
    }
    outputPre.close();


    // End of the program.
    free(disFromStart);
    for (int i=0; i<nodeNum; i++) free(edges[i]);
    free(edges);
    return 0;
}
