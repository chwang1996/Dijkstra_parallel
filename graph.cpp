#include <iostream>
#include <fstream>
#include <stdlib.h>
#define GENEDGE_HAS_PATH_TO_START 0
#define GENEDGE_NO_PATH_TO_START -1
#define MAXIMUM_WEIGHT 100
#define NO_EDGE_BEWTEEN -3

void genEdge(int nodeNum, int edgeNum, int** edges){
    // Ensure that a connected graph is generated.
    for (int i=1; i<nodeNum; i++) {
        int nodeIndex = rand() % i;                 // Because (node index < 1) is a connected graph, join them from anywhere.
        int weight = (rand() % (MAXIMUM_WEIGHT - 1)) + 1;
        edges[i][nodeIndex] =  weight;
        edges[nodeIndex][i] =  weight;
        edgeNum--;
    }

    // Randomly generate edges.
    while(edgeNum > 0){
        int nodeIndex1, nodeIndex2;
        do{
            nodeIndex1 = rand() % nodeNum;
            nodeIndex2 = rand() % nodeNum;
        } while ((nodeIndex1 == nodeIndex2) || (edges[nodeIndex1][nodeIndex2] != NO_EDGE_BEWTEEN));
        int weight = (rand() % (MAXIMUM_WEIGHT - 1)) + 1;
        edges[nodeIndex1][nodeIndex2] = weight;
        edges[nodeIndex2][nodeIndex1] = weight;
        edgeNum--;
    }
    return;
}

void genEdgeFullyConnected(int nodeNum, int edgeNum, int** edges){
    for (int i=0; i<nodeNum; i++) {
        for (int j=i; j<nodeNum; j++) {
            if (i == j) continue;
            int weight = rand() % (MAXIMUM_WEIGHT - 1) + 1;
            edges[i][j] =  weight;
            edges[j][i] =  weight;
        }
    }
}
void genEdgeDefault(int nodeNum, int edgeNum, int** edges){
    //for (int i=0; i<nodeNum; i++) {
    //    for (int j=i; j<nodeNum; j++) {
    //        if (i == j) continue;
    //        int weight = rand() % (MAXIMUM_WEIGHT - 1) + 1;
    //        edges[i][j] =  weight;
    //        edges[j][i] =  weight;
    //    }
    //}
    edges[0][1] = 10;
    edges[1][0] = 10;
    edges[0][9] = 85;
    edges[9][0] = 85;
    edges[1][2] = 10;
    edges[2][1] = 10;
    edges[2][3] = 10;
    edges[3][2] = 10;
    edges[3][4] = 10;
    edges[4][3] = 10;
    edges[4][5] = 10;
    edges[5][4] = 10;
    edges[5][6] = 10;
    edges[6][5] = 10;
    edges[5][7] = 10;
    edges[7][5] = 10;
    edges[6][7] = 10;
    edges[7][6] = 10;
    edges[7][8] = 10;
    edges[8][7] = 10;
    edges[8][9] = 10;
    edges[9][8] = 10;


}

int main(int argc, char* argv[]){
    srand(time(NULL));
    // Check the number of nodes and average number of edges are provided.
    if(argc < 3){
        printf("Usage: %s [num of nodes] [num of edges] (optional: --display-edge, --fully-connected)\n", argv[0]);
        return 0;
    }
    if(std::atoi(argv[2]) < (std::atoi(argv[1]) - 1)){
        printf("%s: (num of edges) must greater than (num of nodes - 1)\n", argv[0]);
        return 0;
    }  
    bool fullyConnected = false;
    bool displayEdge = false;
    bool ex = false;
    int curArgc = 3;
    while (argc > curArgc) {
        std::string in(argv[curArgc]);
        if (in == "--display-edge") {
            displayEdge = true;
        } else if (in == "--fully-connected") {
            fullyConnected = true;
        } else if (in == "--theone"){
	    ex = true;
	    printf("Using default edges.\n");
        } else {
            printf("Unknown option: %s\n", argv[curArgc]);
            return 0;
        }
        curArgc++;
    }


    // ************************ //
    // *** GRAPH GENERATING *** //
    // ************************ //

    int nodeNum = std::atoi(argv[1]);
    int edgeNum = std::atoi(argv[2]);

    // Initialize edge.
    // Currently implement is that for every node, generate random number of edges to random nodes.
    // User input a average number of edge for nodes.
    int **edges = (int**)malloc(sizeof(int*) * nodeNum);
    for (int i=0; i<nodeNum; i++) edges[i] = (int*)malloc(sizeof(int) * nodeNum);
    for (int i=0; i<nodeNum; i++) {
        for (int j=0; j<nodeNum; j++) {
            edges[i][j] = NO_EDGE_BEWTEEN;
        }
    }
    if (fullyConnected) {
        edgeNum = (nodeNum * (nodeNum - 1))/2;
        printf("Generating fully connected graph.\n");
        genEdgeFullyConnected(nodeNum, edgeNum, edges);
    }
    else if (ex) genEdgeDefault(nodeNum, edgeNum, edges);
    else genEdge(nodeNum, edgeNum, edges);
    printf("Graph generated, output is on the way...\n");

    // ********************************** //
    // *** GRAPH GENERATING COMPLETED *** //
    // ********************************** //

    // DEBUG: print the edge matrix
    if (displayEdge) {
        for (int i=0; i<nodeNum; i++) {
            for (int j=0; j<nodeNum; j++) {
                printf("%3d ",edges[i][j] == NO_EDGE_BEWTEEN ? 0 : edges[i][j]);
            }
            printf("\n");
        }
    }

    // Output graph
    // For a 5 node graph, the output order will be:
    // ----------------
    // | 1| 2| 3| 4| 5|
    // | *| 6| 7| 8| 9|
    // | *| *|10|11|12|
    // | *| *| *|13|14|
    // | *| *| *| *|15|
    // ----------------
    std::fstream output;
    output.open("graph", std::fstream::out | std::fstream::trunc | std::fstream::binary);
    for(int i=0; i<nodeNum; i++){
        for(int j=i; j<nodeNum; j++){
            output.write((char *)&(edges[i][j]), sizeof(int));
        }
    }
    output.close();
    for (int i=0; i<nodeNum; i++) free(edges[i]);
    free(edges);
    return 0;
}
