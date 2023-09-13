// Jul 19 2016 23:09:55
// Improved coding, avoids sorting, faster

// Jun 22 2012 15:19:40
// Discrepancy as per Studer et al.

// VARLIST is the grouping variable
// DISTMAT is the distance matrix
// NITER (optional) is the number of permutations to test.
// DCG (optional) names a variable to store the distance-to-COG vector   

program define sddiscrep, rclass
version 10.0
syntax varlist (min=1 max=1), DISTmat(string) IDvar(varname) [NITer(integer 100) DCG(string)]

tempname resmat
tempname groupN
tempname distvar

// Check dist-mat exists
qui matlist `distmat'[1,1]

// Insist on correct sort order, and that it is unique
qui des, varlist
local so `r(sortlist)'
local mainsort : word 1 of `so'
if ("`mainsort'" != "`idvar'") {
  di in red "Error: data must be sorted by same ID variable as used for defining distances"
  error 5
}
isid `idvar'

// Get the classification and its size into matrices
qui tab `varlist', matcell(`groupN')

// Call the main mata function and display the key results
mata: st_matrix("`resmat'",discgroup(st_matrix("`distmat'"), st_matrix("`groupN'"),st_data(.,("`varlist'")),`niter', "`distvar'"))
mat colnames `resmat' = "pseudo R2" "pseudo F" "p-value"
mat rownames `resmat' = "`varlist'"
di _newline "Discrepancy based R2 and F, `niter' permutations for p-value"
matlist `resmat'

// Save the distance-to-COG vector, if requested
if ("`dcg'" != "") {
  gen `dcg' = `distvar'
  table `varlist', c(n `dcg' min `dcg' mean `dcg' max `dcg')
}

// Return the three key numbers
return scalar pseudoR2 = `resmat'[1,1]
return scalar pseudoF  = `resmat'[1,2]
return scalar p_perm   = `resmat'[1,3]
end


mata
real matrix sum_within_clusters_by_group (real matrix distmat, real matrix group) {
  N = rows(distmat)
  Nk = max(group)

  SS = J(Nk,1,.)
  for (i=1;i<=Nk;i++) {
    selector = select(range(1,N,1), (group :== i))
    clusterdistmat = distmat[selector, selector]
    SS[i] =sum(clusterdistmat)*0.5/rows(clusterdistmat)
  }
  return(SS)
}

real matrix discgroup(real matrix dist, real vector groupsize,
                      real vector groupvar, real scalar niter, string dgvar) {

  real scalar N, ngroups, i, low, high, SSt, SumSSg
  real vector ro, dg, permutations, SSg
  real matrix distg
  real scalar pseudoR2, pseudoF, pval

  N = rows(dist)
  ngroups  = rows(groupsize)

  // SSt is discrepancy across the whole matrix
  SSt = sum(dist)*0.5/N
  SSg = sum_within_clusters_by_group(dist, groupvar)
  SumSSg = sum(SSg)

  dg = J(N,1,.)
  for (i=1; i<=ngroups; i++) {
    selector = select(range(1,N,1), (groupvar :== i))
    ro = rowsum(dist[selector,selector])
    for (j=1; j<=length(selector); j++) {
      dg[selector[j]] = (ro[j] :- SSg[i]) :/ length(selector)
    }
  }

  // Give the distance-to-COG back to Stata as a variable
  idx = st_addvar("double",dgvar)
  st_view(V=.,.,idx)
  V[.,.] = (dg)

  // Calculate the main values to return
  pseudoF  = ((SSt - SumSSg)/(ngroups - 1)) / (SumSSg/(N-ngroups))
  pseudoR2 =  (SSt - SumSSg)/SSt

  // Permute the distance matrix to generate a distribution of pseudo-Fs under the null
  permutations = J(niter,1,.)
  for (i=1; i<=niter; i++) {
    distg = dist[order(uniform(rows(dist),1),1),order(uniform(rows(dist),1),1)]
    SumSSg = sum(sum_within_clusters_by_group(distg, groupvar))
    permutations[i] = ((SSt - SumSSg)/(ngroups - 1))/(SumSSg/(rows(distg)-ngroups))
  }

  // The p-value is the proportion of permutation-based Fs that are greater
  // than the calculated F. If none are greater, return 1/niter. 
  pval = max( ( 1/niter, sum(permutations :> pseudoF)/niter ) )

  // Return the values in a vector
  return((pseudoR2,pseudoF,pval))
}

end
