#' @importFrom BiDAG graph2m m2graph
#' @importFrom pcalg randDAG
#' @importFrom RBGL tsort
generatebinaryBN <- function (n, baseline, startadj=NULL,d=2) {
  # set.seed(ii)
  maxneib<-5
  if (is.null(startadj)) {
  while(maxneib>4) {
    mydag<-pcalg::randDAG(n, d, method ="power")
    adj<-BiDAG::graph2m(mydag)
    maxneib<-max(apply(adj,2,sum))
  }
  } else {mydag<-m2graph(startadj)}
  adj<-BiDAG::graph2m(mydag)
  parlist<-list()
  np<-vector()
  for (i in 1:n) {
    parlist[[i]]<-sort(which(adj[,i]==1))
    np[i]<-length(parlist[[i]])
  }

  mapping<-BNmaps(np)
  ord<-as.numeric(tsort(mydag))
  fp<-list()
  for (i in ord) {
    fp[[i]]<-generatefactors(np[i],baseline,mapping)
  }
  res<-list()
  res$DAG<-mydag
  res$adj<-adj
  res$parlist<-parlist
  res$np<-np
  res$fp<-fp
  res$ord<-ord
  res$map<-mapping
  res$skel<-1*(adj|t(adj))
  res$skel<-ifelse(upper.tri(res$skel)==TRUE,res$skel,0)
  return (res)
}

#' @importFrom stats rbinom
generatebinaryBN.data <- function(n,binaryBN,samplesize){
  BNsample<-matrix(ncol=n,nrow=samplesize)

  for (k in 1:samplesize) {
    for (i in binaryBN$ord) {
      if(binaryBN$np[i]==0) { #if node has no parents sample 0/1
        if (sum(binaryBN$adj[i,])==0) {
          BNsample[k,i]<-rbinom(1,1,0.03)
        } else {
        BNsample[k,i]<-rbinom(1,1,binaryBN$fp[[i]][1])}
      } else {
        binaryvec<-BNsample[k,binaryBN$parlist[[i]]]
        BNsample[k,i]<-rbinom(1,1,binaryBN$fp[[i]][which(binaryBN$map$index[[binaryBN$np[i]]]==BinToDec(binaryvec))])
      }
    }
  }
  return(BNsample)
}

BNmaps <- function (np) {
  uniquenp<-setdiff(unique(np),0)
  maps<-list()
  maps$partable<-list()
  maps$index<-list()
  for (i in uniquenp) {
    maps$partable[[i]]<-expand.grid(rep(list(0:1),i))
    maps$index[[i]]<-apply(maps$partable[[i]],1,BinToDec)
  }
  return(maps)
}

BinToDec <- function(x)
  sum(2^(which(rev(unlist(strsplit(as.character(x), "")) == 1))-1))

generatefactors <- function (nf,baselinevec,mapping) {

  prob0<-vector(length=2^nf)
  if (nf>0) {
    prob0[1]<-runif(1, min = 0.01, max = 0.1) #probability of 1 when parents are present
  } else {
    prob0[1]<-runif(1, min = baselinevec[1], max = baselinevec[2]) #probability of 1 when node has no parents
  }
  if(nf>0){
    if (4<5) {
      if (nf<3) {
        factorstrength<-runif(nf, min = 0.4, max = 0.9)
        prob0[2:(2^nf)]<-(apply(t(t(as.matrix(mapping$partable[[nf]]))*factorstrength),1,sum))[2:(2^nf)]
        prob0[which(prob0>0.95)]<-0.95
      } else {
        factorstrength<-runif(nf, min = 0.4, max = 0.9)
        prob0[2:(2^nf)]<-(apply(t(t(as.matrix(mapping$partable[[nf]]))*factorstrength),1,sum))[2:(2^nf)]
        prob0[which(prob0>0.95)]<-0.95
      }
    } else {
      if (nf<3) {
        factorstrength<--runif(nf, min = 0.45, max = 0.85)
        prob0[2:(2^nf)]<-(apply(t(t(as.matrix(mapping$partable[[nf]]))*factorstrength),1,sum))[2:(2^nf)]
        prob0[which(prob0<0.05)]<-0.05
      } else {
        factorstrength<--runif(nf, min = 0.45, max = 0.85)
        prob0[2:(2^nf)]<-(apply(t(t(as.matrix(mapping$partable[[nf]]))*factorstrength),1,sum))[2:(2^nf)]
        prob0[which(prob0<0.05)]<-0.05
      }
    }
  }
  return(prob0)
}

# functions added by F

addBackgroundNodes <- function(n,n_bg,startBN,probOfBG=0.3){

  # set.seed(sseed)

  # add background nodes
  tempBN <- rbind(startBN$adj, array(sample(c(1,0), n*n_bg, replace = T, prob = c(probOfBG,1-probOfBG)),c(n_bg,n)))
  tempBN <- cbind(tempBN, array(0,c(n_bg+n,n_bg)))

  # to make sure that background nodes don't interact themselves
  tempBN[(n+1):(n+n_bg),(n+1):(n+n_bg)] <- 0

  # label new nodes
  rownames(tempBN)[n:(n+n_bg)] <- as.character(n:(n+n_bg))
  colnames(tempBN)[n:(n+n_bg)] <- as.character(n:(n+n_bg))

  # make BN from adjacency matrix
  endBN <- generatebinaryBN(n+n_bg,baseline=c(0.3,0.5),startadj = tempBN)

  return(endBN)
}

addFixedBackgroundNodes <- function(n,n_bg,sseed,startBN, adjacenyMatrixBG,probOfBG=0.3){
  # add background nodes to BN
  tempBN <- adjacenyMatrixBG
  tempBN[1:n,1:n] <- startBN$adj

  # make BN from adjacency matrix
  endBN <- generatebinaryBN(n+n_bg,baseline=c(0.3,0.5),startadj = tempBN)

  return(endBN)
}

getBackgroundNodes <- function(n,n_bg,probOfBG=0.3){

  # set.seed(sseed)

  # add background nodes
  tempBN <- rbind(array(0,c(n,n)), array(sample(c(1,0), n*n_bg, replace = T, prob = c(probOfBG,1-probOfBG)),c(n_bg,n)))
  tempBN <- cbind(tempBN, array(0,c(n_bg+n,n_bg)))

  # to make sure that background nodes don't interact themselves
  tempBN[(n+1):(n+n_bg),(n+1):(n+n_bg)] <- 0

  # label new nodes
  rownames(tempBN)[1:(n+n_bg)] <- as.character(1:(n+n_bg))
  colnames(tempBN)[1:(n+n_bg)] <- as.character(1:(n+n_bg))

  return(tempBN)
}

generateBNs <- function(k_clust, n_vars, n_bg, bgedges="different", equal_cpt_bg=TRUE, baseline=c(0.3,0.5), plotnets=TRUE){
  # simulate k_clust Bayesian networks with n_vars variables and n_bg background variables

  # set.seed(sseed)
  sseed <- 1

  #generate 3 power-law networks each with 20 nodes
  BNs<-list()
  for (gg in 1:k_clust){
    BNs[[gg]]<-generatebinaryBN(n_vars,baseline=baseline)
  }

  if(n_bg==0){
    BNsBG<-list()
    for (gg in 1:k_clust){
      BNsBG[[gg]]<-BNs[[gg]]
    }
  }

  # # plot the BN without background variables
  # if (plotnets==TRUE){
  #   #plot BNs
  #   par(mfrow=c(1,3))
  #   for (gg in 1:k_clust){
  #     plot(BNs[[gg]]$DAG, attrs=list(node=list(fontsize=10, fixedsize=TRUE,
  #                                             height=0.5,width=0.5)))
  #   }
  # }

  if(n_bg>0){

    if (bgedges=="different"){

      #generate 3 power-law networks each with 20 nodes and 3 background nodes
      BNsBG<-list()
      for (gg in 1:k_clust){
        BNsBG[[gg]]<-addBackgroundNodes(n_vars,n_bg,BNs[[gg]],probOfBG=0.3)
      }
    }else if (bgedges=="same"){

      # get nodes for background nodes
      adjacenyMatrixBG <- getBackgroundNodes(n_vars,n_bg,probOfBG=0.3)

      # unify background nodes with cluster BN
      BNsBG<-list()
      tempP <- runif(n_bg, 0.05,0.95)
      for (gg in 1:k_clust){
        BNsBG[[gg]]<-addFixedBackgroundNodes(n_vars,n_bg,sseed+gg,BNs[[gg]], adjacenyMatrixBG,probOfBG=0.3)
        # make CPTs of background nodes equal
        for (bb in 1:n_bg){
          BNsBG[[gg]]$fp[[n_vars+bb]] <- tempP[bb]
        }
      }

    }else {

      stop("Variable bgedges must be named either same or different")

    }

    if (equal_cpt_bg==TRUE){
      # set the CPTs of background nodes equal
      for (ss in 2:k_clust){
        BNsBG[[ss]]$fp[(n_vars+1):(n_vars+n_bg)] <- BNsBG[[1]]$fp[(n_vars+1):(n_vars+n_bg)]
      }
    }

  }

  if (plotnets==TRUE){
    #plot BNs
    for (gg in 1:k_clust){
      graph::plot(BNsBG[[gg]]$DAG, attrs=list(node=list(fontsize=10, fixedsize=TRUE,
                                               height=0.5,width=0.5)))
    }
  }

  return(BNsBG)
}

#' @importFrom stats rbinom
generatebinaryBN.data.bggroups <- function (n, n_bg, nbggroups, binaryBN,samplesize) {

  #simulate CPTs for the different groups of background nodes
  tempP <- array(runif(nbggroups*n_bg, 0.05,0.95), c(nbggroups,n_bg))

  BNsample<-matrix(ncol=n,nrow=samplesize)

  for (k in 1:samplesize) {
    for (i in binaryBN$ord) {
      if(binaryBN$np[i]==0) { #if node has no parents sample 0/1
        if (sum(binaryBN$adj[i,])==0) {
          BNsample[k,i]<-rbinom(1,1,0.03)
        } else {
          BNsample[k,i]<-rbinom(1,1,binaryBN$fp[[i]][1])}
      } else {
        binaryvec<-BNsample[k,binaryBN$parlist[[i]]]
        BNsample[k,i]<-rbinom(1,1,binaryBN$fp[[i]][which(binaryBN$map$index[[binaryBN$np[i]]]==BinToDec(binaryvec))])
      }
    }
  }
  return(BNsample)
}


generatebinaryBN.data.all <- function(nvar,BNsBG,lsamples, n_bg=NULL, nbggroups=NULL, lbgsamples=NULL){
  #generate binary data from BNs and potentially different background groups
  sampleList <- c()
  ss <- sum(lsamples)
  if (is.null(nbggroups)){
    #without different backround groups
    Datafull <- NULL
    for (nn in 1:length(BNsBG)){
      Datafull<-rbind(Datafull,generatebinaryBN.data(nvar,BNsBG[[nn]], lsamples[nn]))
    }
  } else if(is.null(lbgsamples)){
    #with different backround groups

    #sample background node group associations
    samplegroup <- sample(c(1:nbggroups),ss, replace = TRUE)
    #simulate CPTs for the different groups of background nodes
    tempParray <- array(runif(nbggroups*n_bg, 0.05,0.95), c(nbggroups,n_bg))

    Datafull <- NULL
    tcount <- 1
    for (nn in 1:length(BNsBG)){
      for (gg in 1:nbggroups){
        #get how many samples from this group are in that cluster
        ntempsamples <- length(which(samplegroup[tcount:(tcount-1+lsamples[nn])]==gg))
        #set CPTs of background nodes for respective group
        tempP <- tempParray[gg,]
        for (bb in 1:n_bg){
          BNsBG[[nn]]$fp[[nvar+bb]] <- tempP[bb]
        }
        #simlate the data
        Datafull <- rbind(Datafull,generatebinaryBN.data(nvar,BNsBG[[nn]], ntempsamples))
      }
      tcount <- tcount+lsamples[nn]
    }
  } else {
    #with different backround groups

    #sample background node group associations
    # samplegroup <- sample(c(1:nbggroups),ss, replace = TRUE)
    #simulate CPTs for the different groups of background nodes
    tempParray <- array(runif(nbggroups*n_bg, 0.05,0.95), c(nbggroups,n_bg))

    ss2 <- sum(lbgsamples)
    Datafull <- NULL
    sampleList <- c()
    for (gg in 1:nbggroups){
      # get probs
      probs <- runif(length(BNsBG),0.1,0.9)
      probs <- probs/sum(probs)
      samplegroup <- sample(c(1:length(BNsBG)),lbgsamples[gg], replace = TRUE, prob = probs)

      for (nn in 1:length(BNsBG)){
        #get how many samples from this group are in that cluster
        ntempsamples <- length(which(samplegroup==nn))
        #set CPTs of background nodes for respective group
        tempP <- tempParray[gg,]
        for (bb in 1:n_bg){
          BNsBG[[nn]]$fp[[nvar+bb]] <- tempP[bb]
        }
        #simlate the data
        Datafull <- rbind(Datafull,generatebinaryBN.data(nvar,BNsBG[[nn]], ntempsamples))
        sampleList <- c(sampleList, ntempsamples)
      }
    }
  }

  return(list("sampleList"=sampleList,"Datafull"=Datafull))
}

#' @title sampleData
#'
#' @description Sample binary data from different Bayes nets
#'
#' @param k_clust Number of clusters
#' @param n_vars Number of variables
#' @param n_bg number of conditioned covariates
#' @param n_samples number of samples
#' @param bgedges type of background edges
#' @param equal_cpt_bg specify if conditional probability table of the background edges is constant across clusters
#'
#' @return sampled binary data
#' @export
#' @examples
#' \donttest{
#' # sample data
#' simulation_data <- sampleData(k_clust = 3, n_vars = 15, n_samples = c(200,200,200))
#' sampled_data <- simulation_data$sampled_data
#' head(sampled_data)
#' }
sampleData <- function(k_clust = 3, n_vars = 20, n_bg = 0, n_samples = NULL, bgedges = "different", equal_cpt_bg=TRUE){
  # sample binary data from different Bayes nets

  # set sample size
  if (length(n_samples)==0){
    n_samples <- c()
    for (ll in 1:k_clust){
      n_samples <- c(n_samples, 100*ll+600)
    }
  }

  # sample Bayes nets
  sampled_data <- c()
  bayesnets <- generateBNs(k_clust = k_clust, n_vars = n_vars, n_bg = n_bg, bgedges = "different",
                           equal_cpt_bg=TRUE, baseline = c(0.3,0.5), plotnets = FALSE)

  # sample data from Bayes nets
  for (jj in 1:k_clust){
    # bnsseed <- sseed+jj
    binary_bn <- bayesnets[[jj]]
    temp_data <- generatebinaryBN.data(n_vars+n_bg, binary_bn, samplesize = n_samples[jj])
    sampled_data <- rbind(sampled_data,temp_data)
  }

  cluster_membership <- rep(1:k_clust, n_samples)
  return(list(sampled_data = sampled_data, cluster_membership = cluster_membership, bayes_nets=bayesnets,
              n_samples=n_samples))
}

# max_match <- function(membership1, membership2){
#   # find permutation with maximal match of assignment
#
#   permutations <- permn(1:n_bg)
#
#   n_matches <- c()
#   for (dd in 1:length(permutations)){
#
#     temp_perm <- permutations[[dd]]
#
#     perm_membership <- membership1
#     for (bb in 1:k_clust){
#       perm_membership <- replace(perm_membership, perm_membership==bb,temp_perm[bb]+n_bg)
#     }
#     perm_membership <- perm_membership-n_bg
#
#     n_matches[dd] <- sum(membership2==perm_membership)
#   }
#
#   temp_var <- which.max(n_matches)
#
#   permutations[temp_var]
#
#   return(max(n_matches))
# }

adjustedRandIndex <- function(x, y){
  # taken from the mclust package
  x <- as.vector(x)
  y <- as.vector(y)
  if (length(x) != length(y))
    stop("arguments must be vectors of the same length")
  tab <- table(x, y)
  if (all(dim(tab) == c(1, 1)))
    return(1)
  a <- sum(choose(tab, 2))
  b <- sum(choose(rowSums(tab), 2)) - a
  c <- sum(choose(colSums(tab), 2)) - a
  d <- choose(sum(tab), 2) - a - b - c
  ARI <- (a - (a + b) * (a + c)/(a + b + c + d))/((a + b +
                                                     a + c)/2 - (a + b) * (a + c)/(a + b + c + d))
  return(ARI)
}

cluster_benchmark <- function(sampled_data, sampled_membership, k_clust = 3, n_bg = 3, n_vars = 20, n_rep = 10){

  correct_samples <- matrix(NA, n_rep, 9)
  for (uu in 1:n_rep){

    set.seed(uu)

    ## cluster with covariate-adjusted framework
    cluster_results1 <- get_clusters(sampled_data, k_clust = k_clust, n_bg = n_bg, EMseeds=uu*100)

    # correct_samples1 <- max_match(sampled_membership, cluster_results1$clustermembership)
    correct_samples1 <- adjustedRandIndex(sampled_membership, cluster_results1$clustermembership)

    ## cluster all variables (variables and covariates)
    cluster_results2 <- get_clusters(sampled_data, k_clust = k_clust, n_bg = 0, EMseeds=uu*100)

    # correct_samples2 <- max_match(sampled_membership, cluster_results2$clustermembership)
    correct_samples2 <- adjustedRandIndex(sampled_membership, cluster_results2$clustermembership)

    # cluster only variables without covariates
    reduced_data <- sampled_data[,1:n_vars]
    cluster_results3 <- get_clusters(reduced_data, k_clust = k_clust, n_bg = 0, EMseeds=uu*100)

    # correct_samples3 <- max_match(sampled_membership, cluster_results3$clustermembership)
    correct_samples3 <- adjustedRandIndex(sampled_membership, cluster_results3$clustermembership)

    ## k-means
    res_kmeans1 <- stats::kmeans(sampled_data, k_clust)
    # correct_samples4 <- max_match(sampled_membership, res_kmeans1$cluster)
    correct_samples4 <- adjustedRandIndex(sampled_membership, res_kmeans1$cluster)

    res_kmeans2 <- stats::kmeans(reduced_data, k_clust)
    # correct_samples5 <- max_match(sampled_membership, res_kmeans2$cluster)
    correct_samples5 <- adjustedRandIndex(sampled_membership, res_kmeans2$cluster)

    ## Mclust
    res_mclust1 <- stats::kmeans(sampled_data, k_clust)
    # correct_samples6 <- max_match(sampled_membership, res_mclust1$classification)
    correct_samples6 <- adjustedRandIndex(sampled_membership, res_mclust1$cluster)

    res_mclust2 <- stats::kmeans(reduced_data, k_clust)
    # correct_samples7 <- max_match(sampled_membership, res_mclust2$classification)
    correct_samples7 <- adjustedRandIndex(sampled_membership, res_mclust2$cluster)

    ## Bernoulli Mixture Model (BBMMclusterEM)
    res_BBMM1 <- BBMMclusterEM(sampled_data, chi = 0.5, k_clust = 5, startseed = uu*100, nIterations = 1, verbose=TRUE)
    # correct_samples8 <- max_match(sampled_membership, res_BBMM1$newclustermembership)
    correct_samples8 <- adjustedRandIndex(sampled_membership, res_BBMM1$newclustermembership)

    res_BBMM2 <- BBMMclusterEM(reduced_data, chi = 0.5, k_clust = 5, startseed = uu*100, nIterations = 10, verbose=TRUE)
    # correct_samples9 <- max_match(sampled_membership, res_BBMM2$newclustermembership)
    correct_samples9 <- adjustedRandIndex(sampled_membership, res_BBMM2$newclustermembership)


    # summarize results
    correct_samples[uu,] <- c(correct_samples1, correct_samples2, correct_samples3, correct_samples4, correct_samples5,
                              correct_samples6, correct_samples7, correct_samples8, correct_samples9)
    # correct_fraction <- correct_samples/(dim(sampled_data)[1])
  }

  # label output
  colnames(correct_samples) <- c("Cov-Adjust", "BNMM (cov & var)", "BNMM (var)",
                                 "kmeans (cov & var)", "kmeans (var)", "Mclust (cov & var)",
                                 "Mclust (var)", "BMM (cov & var)", "BMM (var)")

  return(correct_samples)

}



benchmark_methods <- function(k_clust = 3, n_vars = 20, n_bg = 3, n_it = 10, n_samples = NULL, bgedges = "different",
                              equal_cpt_bg = TRUE, start_seed = 1){

  correct_samples <- matrix(NA, n_it, 9)
  sampled_results_list <- list()
  for (ww in 1:n_it){

    set.seed(ww+start_seed-1)

    # sample data
    sampled_results <- sampleData(k_clust=k_clust, n_vars=n_vars, n_bg=n_bg, n_samples=n_samples,
                                             bgedges=bgedges, equal_cpt_bg=equal_cpt_bg)
    sampled_data <- sampled_results$sampled_data
    sampled_membership <- sampled_results$cluster_membership
    n_samples <- sampled_results$n_samples

    sampled_results_list <- append(sampled_results_list, sampled_results)

    # clustering
    correct_samples[ww,] <- cluster_benchmark(sampled_data, sampled_membership, k_clust = k_clust,
                                                         n_bg = n_bg, n_vars = n_vars, n_rep = 1)
  }

  colnames(correct_samples) <- c("Cov-Adjust", "BNMM (cov & var)", "BNMM (var)",
                                 "kmeans (cov & var)", "kmeans (var)", "Mclust (cov & var)",
                                 "Mclust (var)", "BMM (cov & var)", "BMM (var)")


  simulation_params <- c(k_clust, n_vars, n_bg, n_it, n_samples, bgedges, equal_cpt_bg, start_seed)

  results <- list("sampled_results"=sampled_results_list, "correct_samples"=correct_samples,
       "simulation_params"=simulation_params)

  # save
  saveRDS(results, paste0("results--k_clust-", k_clust, "--n_vars-", n_vars, "--n_bg-", n_bg, "--n_it-",
                          n_it, "--", bgedges, "--", equal_cpt_bg, ".rds"))

  return(results)
}


