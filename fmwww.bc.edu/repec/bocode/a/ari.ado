mata:


real function ARI(real matrix D) {
/* Take a matrix D which is the body of an RxC table, and return the
   Adjusted Rand Index. \cite{vinhar:_infor_theor_measur_clust_compar}

Adjusted Rand Index:

For RxC contingency table (e.g. cluster comparison)

                     sum(combination(2,n_ij) - [ sum(combination(2, n_i+)*sum(combination(2, n_+i))]/combination(2,N)
ARI = ------------------------------------------------------------------------------------------------------------------------------------
      0.5*[ sum(combination(2, n_i+) + sum(combination(2, n_+i)) ] - [sum(combination(2, n_i+)*sum(combination(2, n_+i))]/combination(2,N)

combination(2,x) is the number of pairs of x, which is n!/2!(n-2)! = n*(n-1)/2

*/
  real matrix Dc,r,rc,c,cc
  real N, c2N, ari

  Dc = D :* (D :- 1) :/ 2

  r=rowsum(D)
  rc = r :* (r :- 1) :/ 2

  c=colsum(D)
  cc = c :* (c :- 1) :/ 2

  N = sum(D)
  c2N = N*(N-1)/2

  ari = ( sum(Dc) - (sum(rc)*sum(cc))/c2N ) / ( 0.5*(sum(rc) + sum(cc)) - (sum(rc)*sum(cc))/c2N )

      return(ari)
  }


real matrix function ARIptest (string rowvar, string colvar, string touse, real scalar nperm, real scalar ari) {
  rv = st_data(., rowvar   , touse)
  cv = st_data(., colvar, touse)

  dims = max((max(rv), max(cv)))
  results = J(nperm,1,.)

  for (i=1; i<=nperm; i++) {
    cv[.,.] = jumble(cv)
    tabmat = J(dims,dims,0)
    for (j=1; j<=length(rv); j++) {
      tabmat[rv[j],cv[j]] = 1 + tabmat[rv[j],cv[j]]
    }
    results[i] = ARI(tabmat)
  }
  results = results[order(results,1)]
  return(
    (1+sum(results  :>= ari))/nperm , // P is <= than this
    results[floor(0.95*nperm)]        // 95 percentile
    )
}

end

   

program ari, rclass
version 9.0
syntax varlist [if] [in] [, VERsion Permute(real 0)]
tokenize `varlist'
local rowvar `1'
macro shift
local colvar `1'
tempname tabmat retval pret pval p95

if ("`version'"!="") di "$Id: ari.ado,v 1.5 2018/10/26 08:32:54 brendan Exp brendan $"

marksample touse

qui tab `rowvar' `colvar' if `touse',  matcell(`tabmat')

mata: st_numscalar("`retval'",ARI(st_matrix("`tabmat'")))
di "Adjusted Rand Index: " %7.4f `retval'
if (`permute' != 0) {
  mata: st_matrix("`pret'",ARIptest("`rowvar'", "`colvar'", "`touse'", `permute', `=`retval''))
  return scalar arip = `pret'[1,1]
  return scalar arip95 = `pret'[1,2]
  di "95% percentile of ARI using " `permute' " permutations: " `pret'[1,2]
  di "P(A>a) <= " `pret'[1,1]
}
return scalar ari = `retval'
end
   
