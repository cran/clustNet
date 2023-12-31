% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/classify.R
\name{get_classification}
\alias{get_classification}
\title{get_classification}
\usage{
get_classification(cluster_results, data_classify)
}
\arguments{
\item{cluster_results}{Output from get_clusters()}

\item{data_classify}{Data that should be classified; colnames need to match the ones of cluster_results$data; missing cols are allowed}
}
\value{
a list containing the classification as "clustermembership" and the probabilities of belonging to the clusters as "allrelativeprobabs"
}
\description{
Classification based on clustering
}
\examples{
\donttest{
# choose data
sampled_data <- sampleData(n_vars = 15, n_samples = c(300,300,300))$sampled_data
# learn clusters
cluster_results <- get_clusters(sampled_data)
# visualize the networks
classification_results <- get_classification(cluster_results, sampled_data)
}
}
