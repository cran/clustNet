BBMMclusterEM <- function(binaryMatrix, chi, k_clust, startseed=100, nIterations=50, verbose=FALSE) {

    # set.seed(startseed)
    # Check for input arguments
    if (missing(binaryMatrix) || !all(binaryMatrix < 2)) stop("Need a binary matrix as input to cluster.")
    if(missing(chi)) stop('Need to provide a value for chi.')
    if(chi==0) {
        #print('Zero chi, setting chi to 1e-3')
        chi<-1e-3
    }
    if (missing(k_clust)) stop('Need to provide a value for k_clust.')
    if (as.integer(nIterations) < 1) {
        stop('Need to specify a positive integer.')
    } else {
        nIterations <- as.integer(nIterations)
    }
    if (startseed < 0) stop("Need to specify a positive integer as startseed.")

    tmp <- lapply(seq(nIterations), doIterate, startseed, chi, k_clust, binaryMatrix,verbose)

    idx <- which.min(sapply(tmp, '[', 'testAIC'))

    output <- tmp[[idx]]

    return(output)
}

doIterate <- function(idx, startseed, chi, k_clust, datatocluster,verbose) {

    seednumber <- startseed + idx
    # set.seed(seednumber)

    if(verbose==TRUE){
      print(paste("Seed", seednumber, "with", k_clust, "clusters and", chi, "pseudocounts"))
    }

    clusterresults <- BBMMclusterEMcore(k_clust,chi,datatocluster)

    # finally assign to the maximal cluster
    newclustermembership <- reassignsamples(clusterresults$relativeweights)
    # could also output the relative probability of being in that cluster?

    clustersizes <- table(newclustermembership)
    kfound <- length(which(clustersizes>0))

   # these values include the pseudocounts

    #totalloglike <- calcloglike(clusterresults$scoresagainstclusters,clusterresults$tauvec)

    #totalAIC <- 2*kfound*ncol(datatocluster)+2*(kfound-1)-2*totalloglike
    #totalBIC <- log(nrow(datatocluster))*(kfound*ncol(datatocluster)+kfound-1)-2*totalloglike

    #print(totalloglike)
    #print(totalAIC)
    #print(totalBIC)

    # now we recompute with (almost) no pseudocounts to get a ML limit

    againstclusterresults <- scoreagainstemptyEMcluster(k_clust,1e-3,clusterresults$relativeweights,clusterresults$tauvec,datatocluster,datatocluster)

    testloglike <- calcloglike(againstclusterresults$scoresagainstclusters,clusterresults$tauvec)
    #print(testloglike)

    testAIC <- 2*kfound*ncol(datatocluster)+2*(kfound-1)-2*testloglike
    testBIC <- log(nrow(datatocluster))*(kfound*ncol(datatocluster)+kfound-1)-2*testloglike

    #print(testAIC)
    #print(testBIC)

    if(verbose==TRUE){
      print(paste("Log likelihood is",testloglike))
      print(paste("AIC is",testAIC))
      print(paste("BIC is",testBIC))
    }

    return(list(seed = seednumber, testAIC = testAIC, testBIC = testBIC, newclustermembership = newclustermembership, relativeweights=clusterresults$relativeweights))
}

# categorical version of binary clustering function BBMMclusterEM
BMMclusterEM <- function(binaryMatrix, chi, k_clust, startseed=100, nIterations=50, verbose=FALSE) {

  # set.seed(startseed)
  # Check for input arguments
  if (missing(binaryMatrix)) stop("Need a binary matrix as input to cluster.")
  if(missing(chi)) stop('Need to provide a value for chi.')
  if(chi==0) {
    #print('Zero chi, setting chi to 1e-3')
    chi<-1e-3
  }
  if (missing(k_clust)) stop('Need to provide a value for k_clust.')
  if (as.integer(nIterations) < 1) {
    stop('Need to specify a positive integer.')
  } else {
    nIterations <- as.integer(nIterations)
  }
  if (startseed < 0) stop("Need to specify a positive integer as startseed.")

  tmp <- lapply(seq(nIterations), doIterate_cat, startseed, chi, k_clust, binaryMatrix,verbose)

  idx <- which.min(sapply(tmp, '[', 'testAIC'))

  output <- tmp[[idx]]

  return(output)
}


#' @title get_clusters_bernoulli
#'
#' @description Categorical version of Bernoulli mixture model (binary clustering function BBMMclusterEM)
#'
#' @param binaryMatrix Data to be clustered
#' @param chi hyperparameter chi
#' @param k_clust Number of clusters
#' @param startseed Start seed
#' @param nIterations number of iterations
#' @param verbose set TRUE to display progress
#'
#' @return a list containing the clusterMemberships
#' @export
get_clusters_bernoulli <- function(binaryMatrix, chi = 0.5, k_clust = 5, startseed=100, nIterations=10, verbose=FALSE) {

  # set.seed(startseed)
  # Check for input arguments
  if (missing(binaryMatrix)) stop("Need a categorical matrix as input to cluster.")
  if (!all(binaryMatrix%%1==0)) stop("All categorical variables need to be specified as integers. Binary variables can be 0 or 1.")
  # if(missing(chi)) stop('Need to provide a value for chi.')
  if(chi==0) {
    #print('Zero chi, setting chi to 1e-3')
    chi<-1e-3
  }
  # if (missing(k_clust)) stop('Need to provide a value for k_clust.')
  if (as.integer(nIterations) < 1) {
    stop('Need to specify a positive integer.')
  } else {
    nIterations <- as.integer(nIterations)
  }
  if (startseed < 0) stop("Need to specify a positive integer as startseed.")

  if (!all(binaryMatrix < 2)){
    # cetegorical version
    tmp <- lapply(seq(nIterations), doIterate_cat, startseed, chi, k_clust, binaryMatrix,verbose)
  }else{
    # binary version
    tmp <- lapply(seq(nIterations), doIterate, startseed, chi, k_clust, binaryMatrix,verbose)
  }

  idx <- which.min(sapply(tmp, '[', 'testAIC'))

  output <- tmp[[idx]]

  return(output)
}

doIterate_cat <- function(idx, startseed, chi, k_clust, datatocluster,verbose) {
  # categorical version

  seednumber <- startseed + idx
  # set.seed(seednumber)

  if(verbose==TRUE){
    print(paste("Seed", seednumber, "with", k_clust, "clusters and", chi, "pseudocounts"))
  }

  clusterresults <- BMMclusterEMcore(k_clust,chi,datatocluster)

  # finally assign to the maximal cluster
  newclustermembership <- reassignsamples(clusterresults$relativeweights)
  # could also output the relative probability of being in that cluster?

  clustersizes <- table(newclustermembership)
  kfound <- length(which(clustersizes>0))

  # these values include the pseudocounts

  #totalloglike <- calcloglike(clusterresults$scoresagainstclusters,clusterresults$tauvec)

  #totalAIC <- 2*kfound*ncol(datatocluster)+2*(kfound-1)-2*totalloglike
  #totalBIC <- log(nrow(datatocluster))*(kfound*ncol(datatocluster)+kfound-1)-2*totalloglike

  #print(totalloglike)
  #print(totalAIC)
  #print(totalBIC)

  # now we recompute with (almost) no pseudocounts to get a ML limit

  againstclusterresults <- scoreagainstemptyEMcluster(k_clust,1e-3,clusterresults$relativeweights,clusterresults$tauvec,datatocluster,datatocluster)

  testloglike <- calcloglike(againstclusterresults$scoresagainstclusters,clusterresults$tauvec)
  #print(testloglike)

  testAIC <- 2*kfound*ncol(datatocluster)+2*(kfound-1)-2*testloglike
  testBIC <- log(nrow(datatocluster))*(kfound*ncol(datatocluster)+kfound-1)-2*testloglike

  #print(testAIC)
  #print(testBIC)

  if(verbose==TRUE){
    print(paste("Log likelihood is",testloglike))
    print(paste("AIC is",testAIC))
    print(paste("BIC is",testBIC))
  }

  return(list(seed = seednumber, testAIC = testAIC, testBIC = testBIC, newclustermembership = newclustermembership, relativeweights=clusterresults$relativeweights))
}
# This function samples an element from a vector properly

propersample <- function(x){if(length(x)==1) x else sample(x,1)}

# this function assigns sample to the cluster with the highest weight

reassignsamples <- function(sampleprobs){
    newclustermembership <-apply(sampleprobs,1,propersample(which.max)) # find the max per row
    return(newclustermembership)
}

# this function takes in log scores and returns normalised probabilities

allrelativeprobs <- function(samplescores){
    maxscorey<-apply(samplescores,1,max) # find the max of each row
    relativeprobs<-exp(samplescores-maxscorey) # remove max for numerical stability and exponentiate
    relativeprobs<-relativeprobs/rowSums(relativeprobs) # normalise
    return(relativeprobs)
}

# this function takes in probabilities, weights them by the vector tau
# and returns normalised probabilities

allrelativeweights <- function(sampleprobs,tau){
    relativeprobs<-t(t(sampleprobs)*tau)
    relativeprobs<-relativeprobs/rowSums(relativeprobs) # normalise
    return(relativeprobs)
}

# this function takes in log scores with the weight vector and returns the log likelihood

calcloglike <- function(samplescores,tau){
    maxscorey<-apply(samplescores,1,max) # find the max of each row
    loglike<-sum(log(colSums(t(exp(samplescores-maxscorey))*tau))+maxscorey) # remove max for numerical stability and exponentiate
    return(loglike)
}

BBMMclusterEMcore <- function(k_clust, chi, datatocluster){

    nbig<-ncol(datatocluster)
    mbig<-nrow(datatocluster)
    scoresagainstclusters<-matrix(0,mbig,k_clust)

    diffystart<-10
    diffy<-diffystart # to check for convergence
    county<-0 # to check how many loops we run
    countlimit<-1e4 # hard limit on the number of loops
    errortol<-1e-10# when to stop the assignment

    clustermembership<-sample.int(k_clust,mbig,replace=TRUE) # start with random groupings

    for(k in 1:k_clust){
        clustersamps<-which(clustermembership==k) # find the members of the cluster
        scoresagainstclusters[clustersamps,k]<-1e-3 # increase the probabilty of clustermembership
        # to get non-uniform starting point
    }

    # this is the weights of each sample for each cluster
    relativeprobabs<-allrelativeprobs(scoresagainstclusters)
    relativeweights<-relativeprobabs # for the starting value

    # main loop
    while((diffy>0) && (county<countlimit)){

        county<-county+1 # update counter

        # first given the current weights we can update tau

        rowtots<-colSums(relativeweights) + chi # add prior to clustersizes
        tauvec<-rowtots/sum(rowtots)

        # and the posterior means

        for(kk in 1:k_clust){
            weightvec<-relativeweights[,kk]
            Datawone<- datatocluster*weightvec # the weighted 1s
            #Datawzero<- (t(1-Datafull)*weightvec) # the weighted 0s
            thetas<-(colSums(Datawone)+0.5*chi)/(sum(weightvec)+chi) # we add the prior
            # the posterior means give the (log) probability of the observations
            scoresagainstclusters[,kk]<-colSums(t(datatocluster)*log(thetas)+t(1-datatocluster)*log(1-thetas))
        }

        # now we can update the weights

        relativeprobabs<-allrelativeprobs(scoresagainstclusters)
        newrelativeweights<-allrelativeweights(relativeprobabs,tauvec)

        # calculate the difference
        diffy3<-sum((newrelativeweights-relativeweights)^2)

        if(diffy3<errortol){
            diffy<-diffy-1
        } else {
            diffy<-diffystart # otherwise reset the counter
        }

        relativeweights<-newrelativeweights # for the next loop
    }

    output<-vector("list",0)
    output$relativeweights<-relativeweights
    output$relativeprobs<-relativeprobabs
    output$scoresagainstclusters<-scoresagainstclusters
    output$tauvec<-tauvec

    return(output)

}

BMMclusterEMcore <- function(k_clust, chi, datatocluster){

  # categorical version

  nbig<-ncol(datatocluster)
  mbig<-nrow(datatocluster)
  scoresagainstclusters<-matrix(0,mbig,k_clust)

  diffystart<-10
  diffy<-diffystart # to check for convergence
  county<-0 # to check how many loops we run
  countlimit<-1e4 # hard limit on the number of loops
  errortol<-1e-10# when to stop the assignment

  clustermembership<-sample.int(k_clust,mbig,replace=TRUE) # start with random groupings

  for(k in 1:k_clust){
    clustersamps<-which(clustermembership==k) # find the members of the cluster
    scoresagainstclusters[clustersamps,k]<-1e-3 # increase the probabilty of clustermembership
    # to get non-uniform starting point
  }

  # this is the weights of each sample for each cluster
  relativeprobabs<-allrelativeprobs(scoresagainstclusters)
  relativeweights<-relativeprobabs # for the starting value

  # main loop
  while((diffy>0) && (county<countlimit)){

    county<-county+1 # update counter

    # first given the current weights we can update tau

    rowtots<-colSums(relativeweights) + chi # add prior to clustersizes
    tauvec<-rowtots/sum(rowtots)

    # and the posterior means

    for(kk in 1:k_clust){
      # the binary version is commented out
      # weightvec<-relativeweights[,kk]
      # Datawone<- datatocluster*weightvec # the weighted 1s
      #Datawzero<- (t(1-Datafull)*weightvec) # the weighted 0s
      # thetas<-(colSums(Datawone)+0.5*chi)/(sum(weightvec)+chi) # we add the prior
      # the posterior means give the (log) probability of the observations
      # scoresagainstclusters[,kk]<-colSums(t(datatocluster)*log(thetas)+t(1-datatocluster)*log(1-thetas))

      # categorical version: this part inserts an empty graph to the scoreagainstDAG function
      bdepar=list(chi = chi, edgepf = 16)
      clustercenters <- matrix(0, nrow = nbig, ncol = nbig) # empty graph
      scorepar <- BiDAG::scoreparameters("bdecat", as.data.frame(datatocluster), weightvector = relativeweights[,kk], bdepar = bdepar)
      scoresagainstclusters[,kk] <- BiDAG::scoreagainstDAG(scorepar,clustercenters, bdecatCvec = apply(datatocluster, 2, function(x) length(unique(x))))
    }

    # now we can update the weights

    relativeprobabs<-allrelativeprobs(scoresagainstclusters)
    newrelativeweights<-allrelativeweights(relativeprobabs,tauvec)

    # calculate the difference
    diffy3<-sum((newrelativeweights-relativeweights)^2)

    if(diffy3<errortol){
      diffy<-diffy-1
    } else {
      diffy<-diffystart # otherwise reset the counter
    }

    relativeweights<-newrelativeweights # for the next loop
  }

  output<-vector("list",0)
  output$relativeweights<-relativeweights
  output$relativeprobs<-relativeprobabs
  output$scoresagainstclusters<-scoresagainstclusters
  output$tauvec<-tauvec

  return(output)

}


scoreagainstemptyEMcluster <- function(k_clust, chi, relativeweights, tauvec, datatocluster, datatoscore){

    nbig<-ncol(datatoscore)
    mbig<-nrow(datatoscore)

    scoresagainstclusters<-matrix(0,mbig,k_clust)

    for(kk in 1:k_clust){
        # the binary version is commented out
        # weightvec<-relativeweights[,kk]
        # Datawone<- datatocluster*weightvec # the weighted 1s
        #Datawzero<- (t(1-Datafull)*weightvec) # the weighted 0s
        # thetas<-(colSums(Datawone)+0.5*chi)/(sum(weightvec)+chi) # we add the prior
        # the posterior means give the (log) probability of the observations
        # scoresagainstclusters[,kk]<-colSums(t(datatocluster)*log(thetas)+t(1-datatocluster)*log(1-thetas))

        # categorical version: this part inserts an empty graph to the scoreagainstDAG function
        bdepar=list(chi = chi, edgepf = 16)
        clustercenters <- matrix(0, nrow = nbig, ncol = nbig) # empty graph
        scorepar <- BiDAG::scoreparameters("bdecat", as.data.frame(datatocluster), weightvector = relativeweights[,kk], bdepar = bdepar)
        scoresagainstclusters[,kk] <- BiDAG::scoreagainstDAG(scorepar,clustercenters)
    }

    # calculate the weights

    relativeprobabs<-allrelativeprobs(scoresagainstclusters)
    relativeweights<-allrelativeweights(relativeprobabs,tauvec)

    output<-vector("list",0)
    output$relativeweights<-relativeweights
    output$relativeprobs<-relativeprobabs
    output$scoresagainstclusters<-scoresagainstclusters

    return(output)

}
