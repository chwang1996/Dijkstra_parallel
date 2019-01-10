# Dijkstra_parallel
parallel Dijkstra with openmp and CUDA

## compile
```
g++ graph.cpp -o gen_graph -Wall -pedantic
g++ Dijkstra-openmp.cpp -o Dijkstra_openmp -I /usr/local/include -L /usr/local/lib -std=c++11 -Wall -pedantic -pthread -fopenmp
nvcc cuda Dijkstra.cu -o Dijkstra_cuda
```
## execution
```
./gen_graph [num of nodes] [num of edges] (optional: --display-node)
./Dijkstra_openmp [num of nodes] [num of edges]
./Dijkstra_cuda [num of nodes] [num of edges]
```
