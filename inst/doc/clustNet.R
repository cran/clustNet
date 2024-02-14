## ----setup--------------------------------------------------------------------
library(clustNet)

## ---- message=FALSE, warning=FALSE, results='hide'----------------------------
library(clustNet)

# Simulate data
k_clust <- 3 # numer of clusters
ss <- c(400, 500, 600) # samples in each cluster
simulation_data <- sampleData(k_clust = k_clust, n_vars = 20, n_samples = ss)
sampled_data <- simulation_data$sampled_data

# Network-based clustering
cluster_results <- get_clusters(sampled_data, k_clust = k_clust)

## -----------------------------------------------------------------------------

# Load additional pacakges to visualize the networks
library(ggplot2)
library(ggraph)
library(igraph)
library(ggpubr)

# Visualize networks
plot_clusters(cluster_results)

## -----------------------------------------------------------------------------
# Load additional pacakges to create a 2d dimensionality reduction
library(car)
library(ks)
library(graphics)
library(stats)

# Plot a 2d dimensionality reduction
density_plot(cluster_results)

