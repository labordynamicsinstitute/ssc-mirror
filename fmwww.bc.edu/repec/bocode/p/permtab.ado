// permtab3.ado
// May 28 2017 17:42:04

// Copyright Brendan Halpin 2007-2017

/* Takes a square table (e.g. comparing two equal-sized clusterings of a
   data set) and permutes the column variable to maximise agreement.
   Agreement is calculated as Cohen's Kappa (see e.g., Reilly, Wang and
   Rutherford 2005).

   Three algorithms are used. By default all permutations are examined.
   This is slow for more than 8 categories, and become impossible above
   about 11. Second, a hill-climb algorithm takes either the current
   ordering or a random permutation of it and looks for all pairwise
   swaps that improve fit. Third, a genetic algorithm efficiently
   searches for an approximate maximum in the permutation space. 


*/

// Define Mata functions
mata

// Cohen's Kappa for a square table
real permtab_kappa(real matrix D, real gtot) {
  real po, pe, ktmp
  po=trace(D)/gtot
  pe=trace(rowsum(D)*colsum(D)/gtot)/gtot
  ktmp = (po-pe)/(1-pe)
  return(ktmp)
}

// Go through all permutations, returning the one with the highest Kappa (only feasible for small tables)
real permtab_permute_all(real matrix perm,real matrix D, real gtot) {
  real matrix info, p
  real kmax
  info=cvpermutesetup(perm)
  kmax = 0
  
  while ((p=cvpermute(info)) != J(0,1,.)) {
    temp = permtab_kappa(D[.,p],gtot)
    if (temp>kmax) {
      kmax=temp
      perm=p
    }
  }
  return(kmax)
}

// Main function to carry out Genetic Algorithm selection of permutations
real permtabga_evolve(real matrix pv, real matrix D, real gtot, real niter) {
  real genepoolsize, nsurv, nmate_die, nnewblood
  real matrix survivors, offspring, maters, scoreboard
  real scalar noffspring, nmaters, Dtot, i, j, k, l, index, dim, meanscore
  
  genepoolsize = 8000
  nsurv = 2000
  nmate_die = 2000
  nnewblood = 2000
  
  nmaters = nsurv + nmate_die + nnewblood
  noffspring = genepoolsize - nsurv
  
  dim = rows(D)
  Dtot = sum(D)
  // Initialise genepool with random values
  genepool = uniform(genepoolsize,dim)
  
  scoreboard = J(genepoolsize,1,0)
  
  // For each being, get its score
  for (i=1; i<=genepoolsize; i++) {
    // Permutation order is based on the random values in each row 
    pv = order(transposeonly(genepool[i,]),1)
    // The score for the being is based on the permuted D 
    scoreboard[i,1] = permtab_kappa(D[.,pv],Dtot)
  }
  printf("          Max   Mean(top)  Mean(low)     Var(top)\n")
  printf("%5.0f: %7.4f   %7.4f     %7.4f     %8.6f\n",
         0,
         scoreboard[nsurv],
         mean(scoreboard[1..nsurv]),
         mean(scoreboard[nsurv+1..genepoolsize]),
         variance(scoreboard[1..nsurv]))
  displayflush()
      
  converged = 0
      
  for (index = 1; ((index<=niter) & !converged); index++) {
    // sort genepool in ascending order of fitness 
    genepool = genepool[transposeonly(order(scoreboard,1)),]
    scoreboard = scoreboard[transposeonly(order(scoreboard,1)),]
    
    // Mate random pairs
    // All of nsurv plus the next nmate_die plus nnewblood mate
    // indiscriminately, providing noffspring offspring. 
    
    survivors = genepool[(genepoolsize-nsurv+1)..genepoolsize,.]
    
    maters = survivors\genepool[(genepoolsize-nsurv-nmate_die+1)..genepoolsize-nsurv,.]\uniform(nnewblood,dim)
    
    offspring = J(noffspring,dim,.)
         
         
    for (i=1;i<=noffspring;i++) {
      j = round(0.5+uniform(1,1)*nmaters)
      k = round(0.5+uniform(1,1)*nmaters)
      l = round(0.5+uniform(1,1)*(dim-1))
      
      offspring[i,1..l] = maters[j,1..l]
      offspring[i,l+1..dim] = maters[k,l+1..dim]
    }
         
    genepool = survivors \ offspring
    scoreboard[1..nsurv] = scoreboard[(genepoolsize-nsurv+1)..genepoolsize,.]
         
    // Implicit: genepool[newblood+noffpring+1 .. genepoolsize,] = survivors
         
    for (i=nsurv+1; i<=genepoolsize; i++) {
      pv = order(transposeonly(genepool[i,]),1)
      scoreboard[i,1] = permtab_kappa(D[.,pv],Dtot)
    }
    
    meanscore = mean(scoreboard[1..nsurv])
    
    if (mod(index,10)==0) {
      printf("%5.0f: %7.4f   %7.4f     %7.4f     %8.6f\n",
             index,
             scoreboard[nsurv],
             meanscore,
             mean(scoreboard[nsurv+1..genepoolsize]),
             variance(scoreboard[1..nsurv]))
      displayflush()
    }
    converged = abs(scoreboard[nsurv] - meanscore) < 0.000001
  }
  if ((index>=niter) & !converged) {
    "Warning: hit max iterations without converging"
  }
  pv = order(transposeonly(genepool[nsurv,]),1)
  kmax = permtab_kappa(D[,pv],Dtot)
  return(pv)
}

// Hill-climb: starting from the current permutation,
// search for all pairwise swaps that improve fit,
// iterate until no improvements found
real function permtab_hillclimb(real matrix pv, real matrix table) {
  real converged, index, niter, tabtot
  real matrix newpv
  converged = 0
  niter = 200

  tabtot = sum(table)

  for (index = 1; (index <= niter) & !converged; index++) {
    newpv = permtab_hc_pv(pv, table, 1)
    if (newpv == pv) {
      // No change found by pair-swap
      converged = 1
    } else {
      pv = newpv
    }
  }
  return(pv)
}

// Hill-climb core function: with current permutation, consider all pairwise swaps, return best
real matrix function permtab_hc_pv ( real matrix pv, real matrix table, real step) {
  real i, j, basescore, newscore, tabtot
  real vector pv1, pv2, pvmax

  pv1 = pv
  
  dim = length(pv1)
  tabtot = sum(table)
  basescore = permtab_kappa(table[,pv1],tabtot)
  
  for (i=1; i<=dim-1; i++) {
    for (j=i+1; j<=dim; j++) {
      pv2 = pv1
      pv2[i] = pv1[j]
      pv2[j] = pv1[i]
      newscore = permtab_kappa(table[,pv2],tabtot)
      if (newscore>basescore) {
        basescore = newscore
        pv1 = pv2
      }
    }
  }
  return(pv1)
}

// "Main" function
// Take parameters from Stata, select and execute appropriate calculations, return results
void permute_square_table(string matrix tabmat, real nodisplay, real which, real maxiter) {
  real grandtotal
  real matrix permmax
  string recodestr
  // Read stata matrix into mata
  G=st_matrix(tabmat)
  
  if (rows(G)!=cols(G)) {
    "Table isn't square, padding with zeros"
    if (rows(G)<cols(G)) {
      G = G \ J(cols(G)-rows(G),cols(G),0)
    }
    else {
      G = G , J(rows(G),rows(G)-cols(G),0)
    }
  }
  
  grandtotal=sum(G)
  permmax=range(1,rows(G),1)
  
  if (which==1) {
    // initialise permutation col-vector
    // Setup and loop through all permutations
    kmax = permtab_permute_all(permmax,G,grandtotal)
  } else if ((which==2) | (which==3)) {
    if (which==3) {
      permmax = permmax[order(runiform(rows(G),1),1)]
    }
    permmax = permtab_hillclimb(permmax,G)
    kmax = permtab_kappa(G[,permmax],grandtotal)
  } else if (which==4) {
    // do it evolve-style
    permmax = permtabga_evolve(permmax,G,grandtotal, maxiter)
    printf("GA high score: %7.4f\n",permtab_kappa(G[,permmax],grandtotal))
    displayflush()
    permmax = permtab_hillclimb(permmax,G)
    printf("Hillclimb high score: %7.4f\n",permtab_kappa(G[,permmax],grandtotal))
    displayflush()
    
    kmax = permtab_kappa(G[,permmax],grandtotal)
  } else {
    error("incorrect type")
  }
 
  // Report max and permutation
  printf("Kappa max: %6.4f\n",kmax)
  printf("Permutation vector:\n")
  transposeonly(permmax)
  
  // Show permuted and original crosstab matrices
  if (nodisplay==0) {
    printf("Permuted table:\n")
    G[.,permmax]
    printf("Original table:\n")
    G
  }
  
  recodestr = ""
  for (i=1;i<=rows(permmax);i++) {
    recodestr = recodestr + strofreal(permmax[i]) + "=" + strofreal(i) + " "
  }
  
  st_local("permtabperm",recodestr)
  st_local("kappamax",strofreal(kmax))
  st_matrix("permmax",transposeonly(permmax))

}

end // End of Mata definitions

// Define Stata program
program permtab, rclass
version 9.0
syntax varlist(min=2 max=2) [if] [in] [, gen(namelist max=1) TABles ALGorithm(string) RANdom MAXITer(real 250)]
tokenize `varlist'
local rowvar `1'
local colvar `2'
tempname tabmat nrows

marksample touse

// Handle options
local algorithm = strlower("`algorithm'")
if ("`algorithm'"=="" |"`algorithm'"=="full") {
  local algorithm 1
} 
else if ("`algorithm'"=="hc")  {
  local algorithm 2
}
else if ("`algorithm'"=="ga")  {
  local algorithm 4
}
else {
  local algorithm 1
}

if ("`random'"!="") {
  if ("`algorithm'"=="2")  {
    local algorithm 3
  }
  else {
    di "RANDOM ignored, only relevant for hill-climbing"
  }
}

if ("`tables'"=="") {
  local nodisplay 1
}
else {
  local nodisplay 0
}
if ("`nodisplay'"=="1") {
     qui tab `rowvar' `colvar' if `touse',  matcell(`tabmat')
   }
   else {
     di "Tabulating raw data:"
     tab `rowvar' `colvar' if `touse',  matcell(`tabmat')
   }

scalar `nrows' = rowsof(`tabmat')
di "Calculating permutations:"

if (`algorithm'==1) {
   if `nrows'== 9 di "Will be slow: " `nrows' " by " `nrows' " table => `=round(exp(lnfactorial(`nrows')),1)' permutations; use option algorithm(hc) or algorithm(ga) instead"
   if `nrows'==10 di "Will be very slow: " `nrows' " by " `nrows' " table => `=round(exp(lnfactorial(`nrows')),1)' permutations; use option algorithm(hc) or algorithm(ga) instead"
   if `nrows'>=11 di "Will be infeasibly slow: " `nrows' " by " `nrows' " table => `=round(exp(lnfactorial(`nrows')),1)' permutations; use option algorithm(hc) or algorithm(ga) instead"
 }

// Pass to Mata to do the work
mata: permute_square_table("`tabmat'",`nodisplay', `algorithm', `maxiter')

// Create permuted column variable, if requested
if "`gen'"!="" {
  gen `gen'=`colvar'
  qui recode `gen' `permtabperm'
  di "Permuted column variable generated from `colvar': `gen'"
}

// Return kappamax and the final permutation
return scalar kappamax = `kappamax'
return matrix perm = permmax

end
