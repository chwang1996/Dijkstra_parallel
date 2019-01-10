# Dijkstra_parallel
parallel Dijkstra with openmp and CUDA

## environment
CPU: i7-8700K
GPU: RTX-2070
RAM: 16GB DDR4-2400 
DISK: 256GB SATA3 SSD
OS: ubuntu 16.04

g++: upper than 7 

## compile
```
g++ graph.cpp -o gen_graph -Wall -pedantic -O3
g++ Dijkstra-openmp.cpp -o Dijkstra_openmp -I /usr/local/include -L /usr/local/lib -std=c++11 -Wall -pedantic -pthread -O3 -fopenmp
nvcc cuda Dijkstra.cu -o Dijkstra_cuda
```
## execution
```
./gen_graph [num of nodes] [num of edges] (optional: --display-node)
./Dijkstra_openmp [num of nodes] [num of edges]
./Dijkstra_cuda [num of nodes] [num of edges]
```
