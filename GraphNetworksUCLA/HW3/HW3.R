############################################ Homework 3 ###########################################
library(igraph)

# Reading in the data from the file and storing the edge set
# Change the directory of the data
data_list = scan("C:/Users/James/Desktop/sorted_directed_net.txt",what = list(0,0,0))
edge_in <- data_list[[1]] + 1
edge_out <- data_list[[2]] + 1
edge_set = cbind(edge_in,edge_out)

# Creating the graph 

network <- graph.edgelist(el = edge_set, directed = TRUE)
E(network)$weight <- data_list[[3]]



cat(" Running Exercise #1\n")
############################### Exercise #1 ###################################

# connectivity test

is.connected(network)
vcount(network)
diameter(network)
##plot(network,vertex.size=2,vertex.label=NA) //Takes a long time

# finding the giant connected component

network_component_list <- decompose.graph(network)
gcc_index <- which.max(sapply(network_component_list,vcount))
network_gcc <- network_component_list[[gcc_index]]
vcount(network_gcc)

cat(" Running Exercise #2\n")
############################### Exercise #2 ###################################

# Degree distribution of the network


plot(degree.distribution(network, mode = "in"),main = "In-degree distribution of the nodes in the network")
plot(degree.distribution(network, mode = "out"),main = "Out-degree distribution of the nodes in the network")


# Degree distribution of the GCC

# in-degree

plot(degree.distribution(network_gcc, mode = "in"),main = "In-degree distribution of the GCC")

# out-degree

plot(degree.distribution(network_gcc, mode = "out"),main = "Out-degree distribution of the GCC")


cat(" Running Exercise #3\n")
############################### Exercise #3 ###################################

# Option 1

network_gcc_undirected_1 <- as.undirected(network_gcc,mode="each")
network_gcc_undirected_1_comm <- label.propagation.community(network_gcc_undirected_1,weights = E(network_gcc_undirected_1)$weight)
modularity(network_gcc_undirected_1_comm)
print(sizes(network_gcc_undirected_1_comm))

# Plotting the community structure

cg_1 <- contract.vertices(network_gcc_undirected_1, membership(network_gcc_undirected_1_comm))
E(cg_1)$weight <- 1
cgsimp_1 <- simplify(cg_1, remove.loops=FALSE)

plot(cgsimp_1, edge.label=E(cgsimp_1)$weight, margin=.5, layout=layout.circle,main = "Community structure (Label Propagation)")



# Option 2

network_gcc_undirected_2 <- as.undirected(network_gcc,mode = "collapse",edge.attr.comb = list(weight = "prod"))
E(network_gcc_undirected_2)$weight <- sqrt(E(network_gcc_undirected_2)$weight)

network_gcc_undirected_2_lpc_comm <- label.propagation.community(network_gcc_undirected_2,weights = E(network_gcc_undirected_2)$weight)
modularity(network_gcc_undirected_2_lpc_comm)
print(sizes(network_gcc_undirected_2_lpc_comm))

network_gcc_undirected_2_fg_comm <- fastgreedy.community(network_gcc_undirected_2)
modularity(network_gcc_undirected_2_fg_comm)
print(sizes(network_gcc_undirected_2_fg_comm))

# Plotting the community structure

cg_2 <- contract.vertices(network_gcc_undirected_2, membership(network_gcc_undirected_2_fg_comm))
E(cg_2)$weight <- 1
cgsimp_2 <- simplify(cg_2, remove.loops=FALSE)

plot(cgsimp_2, edge.label=E(cgsimp_2)$weight, margin=.5, layout=layout.circle,main = "Community structure (Fast greedy)")


cat(" Running Exercise #4\n")
############################### Exercise #4 ################################### 

vertices_largest_comm <- c()
max_comm <- which.max(sizes(network_gcc_undirected_2_fg_comm))

for(i in V(network_gcc_undirected_2))
{
  if(network_gcc_undirected_2_fg_comm$membership[i] == max_comm)
  {
    vertices_largest_comm <- append(vertices_largest_comm,i)
  }
    
}

largest_comm <- induced.subgraph(network_gcc_undirected_2,vids = vertices_largest_comm)

# Finding the community structure of the subgraph

largest_comm_sub <- fastgreedy.community(largest_comm)
modularity(largest_comm_sub)
print(sizes(largest_comm_sub)) 

cg_3 <- contract.vertices(largest_comm, membership(largest_comm_sub))
E(cg_3)$weight <- 1
cgsimp_3 <- simplify(cg_3, remove.loops=FALSE)

plot(cgsimp_3, edge.label=E(cgsimp_3)$weight, margin=.5, layout=layout.circle,main = "subcommunity structure (Fast greedy)")


cat(" Running Exercise #5\n")
############################### Exercise #5 ###################################

mod_comm <- c()
struct_comm <- c()
for (i in 1:length(sizes((network_gcc_undirected_2_fg_comm))))
{
  vertices_temp <- c()
  temp_comm <-c()
  temp_comm_sub <- c()
  
  for(j in V(network_gcc_undirected_2))
  {
    if(network_gcc_undirected_2_fg_comm$membership[j] == i)
    {
      vertices_temp <- append(vertices_temp,j)
    }
    
  }
  
  temp_comm <-induced.subgraph(network_gcc_undirected_2,vids = vertices_temp)
  temp_comm_sub <- fastgreedy.community(temp_comm)
  mod_comm <- append(mod_comm,modularity(temp_comm_sub))
  struct_comm <- append(struct_comm,temp_comm_sub)
  print(sizes(temp_comm_sub))
}

print(mod_comm)


cat(" Running Exercise #6\n")
############################### Exercise #6 ###################################

library(netrw)
vis_prob <- c()
samp_nodes <- sample(1:vcount(network_gcc),10000)
iter_count = 0
for (i in samp_nodes)
{
  temp <-netrw(network_gcc,walker.num = 20,start.node = i,damping = 0.85,T = 20,local.pagerank = TRUE, output.visit.prob=TRUE)
  vis_prob <-append(vis_prob,temp$ave.visit.prob);
  iter_count = iter_count + 1
  print(iter_count)
  
}

vis_probm <-matrix(vis_prob,nrow = 10000,ncol=vcount(network_gcc),byrow = TRUE)
mship <- matrix(0,vcount(network_gcc),8)
for (i in 1:vcount(network_gcc)){
  temp <- rep(0,times = 8);
  temp[network_gcc_undirected_2_fg_comm$membership[i]] = 1
  mship[i,] <- temp
}

M <- matrix(0,10000,8)
for(k in 1:10000)
{
  for (i in 1:vcount(network_gcc))
  {
    prod = vis_probm[k,i]*mship[i,]
    M[k,] =M[k,]+ prod
  }
}

# Max/2 thresholding

temp_1 <- matrix(apply(M,1,max))
thresholding <- temp_1/2
M_comm <- M[,] >= thresholding[,] # Matrix containing the list of communities to which each node belongs

# Plotting
library(Matrixstats)
e <- rowCounts(M_comm)
hist(e,seq(-0.5, by=1, length.out = max(e)+2),xlab = "Number of communities",ylab = "Number of nodes",main = "Histogram of Multiple Community detection")




