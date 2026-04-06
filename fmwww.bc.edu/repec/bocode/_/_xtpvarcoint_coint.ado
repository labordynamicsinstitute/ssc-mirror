*! _xtpvarcoint_coint.ado — Individual Cointegration Rank Tests
*! Johansen (JO) and Saikkonen-Luetkepohl (SL)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_coint
program define _xpvc_coint, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    Lags(integer) [Type(string) Method(string) ///
    TBReak(numlist) TSHift(numlist) NSEason(integer 0)]
  
  if "`type'" == "" local type "Case3"
  if "`method'" == "" local method "JO"
  
  marksample touse
  
  local dim_K : word count `varlist'
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint coint} — Individual Cointegration Rank Test" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Method:        " in ye upper("`method'")
  di in gr "  Deterministic: " in ye "`type'"
  di in gr "  Variables (K): " in ye "`dim_K'"
  di in gr "  Lag order (p): " in ye "`lags'"
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_coint_run("`varlist'", "`touse'", "`method'", ///
    "`type'", `lags', `dim_K')
  
  return add
end

mata:
mata set matastrict off

void _xpvc_coint_run(string scalar varlist, string scalar touse,
                      string scalar method, string scalar type,
                      real scalar dim_p, real scalar dim_K)
{
  string rowvector vnames
  real matrix data, y
  real scalar j, k
  string scalar _hline60
  
  _hline60 = 60 * "-"
  
  vnames = tokens(varlist)
  
  // Load data
  data = J(0, dim_K, .)
  for (j = 1; j <= dim_K; j++) {
    real colvector v
    st_view(v, ., vnames[j], touse)
    if (j == 1) data = J(rows(v), dim_K, .)
    data[., j] = v
  }
  
  y = data'  // K x T
  
  // Run RRR
  struct _xpvc_RRRdef scalar def
  struct _xpvc_RRRresult scalar rrr
  
  string scalar type_rrr
  if (type == "SL_trend" | type == "SL_mean") {
    type_rrr = "Case4"
  }
  else {
    type_rrr = type
  }
  
  def = _xpvc_stackRRR(y, dim_p, type_rrr)
  rrr = _xpvc_RRR(def.Z0, def.Z1, def.Z2, 1)
  
  // Get moments
  real matrix moments
  moments = _xpvc_CointMoments(dim_K, (0::dim_K-1), type)
  
  // Compute trace and max-eigenvalue statistics
  real colvector stats_TR, stats_ME, pvals_TR, pvals_ME
  stats_TR = J(dim_K, 1, .)
  stats_ME = J(dim_K, 1, .)
  pvals_TR = J(dim_K, 1, .)
  pvals_ME = J(dim_K, 1, .)
  
  for (j = 1; j <= dim_K; j++) {
    // Max eigenvalue
    stats_ME[j] = -def.dim_T * ln(1 - rrr.lambda[j])
    
    // Trace
    stats_TR[j] = 0
    for (k = j; k <= dim_K; k++) {
      stats_TR[j] = stats_TR[j] - def.dim_T * ln(1 - rrr.lambda[k])
    }
    
    // p-values via gamma approximation
    if (moments[j, 1] != . & moments[j, 2] != . & moments[j, 2] > 0) {
      real scalar shape, rate
      shape = moments[j, 1]^2 / moments[j, 2]
      rate = moments[j, 1] / moments[j, 2]
      pvals_TR[j] = 1 - gammap(shape, stats_TR[j] * rate)
    }
    if (cols(moments) >= 4) {
      if (moments[j, 3] != . & moments[j, 4] != . & moments[j, 4] > 0) {
        shape = moments[j, 3]^2 / moments[j, 4]
        rate = moments[j, 3] / moments[j, 4]
        pvals_ME[j] = 1 - gammap(shape, stats_ME[j] * rate)
      }
    }
  }
  
  // Display eigenvalues
  printf("  Eigenvalues:\n")
  for (j = 1; j <= dim_K; j++) {
    printf("    lambda_%g = %g\n", j, rrr.lambda[j])
  }
  printf("\n")
  
  // Display trace test
  printf("  Trace Test:\n")
  printf("%s\n", _hline60)
  printf("  %-8s  %12s  %12s  %12s\n", "H0: r", "Statistic", "p-value", "")
  printf("%s\n", _hline60)
  for (j = 1; j <= dim_K; j++) {
    string scalar sig
    sig = ""
    if (pvals_TR[j] != .) {
      if (pvals_TR[j] < 0.01) sig = "***"
      else if (pvals_TR[j] < 0.05) sig = "**"
      else if (pvals_TR[j] < 0.10) sig = "*"
    }
    printf("  %g  %g  %g  %s\n", ///
      j-1, stats_TR[j], pvals_TR[j], sig)
  }
  printf("%s\n", _hline60)
  printf("  Significance: *** 1%%, ** 5%%, * 10%%\n")
  
  // Display max eigenvalue (if moments available)
  printf("\n  Maximum Eigenvalue Test:\n")
  printf("%s\n", _hline60)
  printf("  %-8s  %12s  %12s  %12s\n", "H0: r", "Statistic", "p-value", "")
  printf("%s\n", _hline60)
  for (j = 1; j <= dim_K; j++) {
    string scalar sig2
    sig2 = ""
    if (pvals_ME[j] != .) {
      if (pvals_ME[j] < 0.01) sig2 = "***"
      else if (pvals_ME[j] < 0.05) sig2 = "**"
      else if (pvals_ME[j] < 0.10) sig2 = "*"
    }
    printf("  %g  %g  %g  %s\n", ///
      j-1, stats_ME[j], pvals_ME[j], sig2)
  }
  printf("%s\n\n", _hline60)
  
  // Display cointegrating vectors
  printf("  Cointegrating vectors (normalized, natural):\n")
  real matrix beta
  beta = _xpvc_beta(rrr.V, dim_K, "natural")
  
  printf("  %-10s", "")
  for (j = 1; j <= dim_K; j++) printf("  %10s", sprintf("ect.%g", j))
  printf("\n")
  printf("%s\n", _hline60)
  for (j = 1; j <= rows(beta); j++) {
    printf("  %-10s", vnames[min((j, cols(vnames)))])
    for (k = 1; k <= cols(beta); k++) {
      printf("  %g", beta[j, k])
    }
    printf("\n")
  }
  printf("%s\n\n", _hline60)
  
  // Store results
  st_rclear()
  st_numscalar("_xpvc_K", dim_K)
  st_numscalar("_xpvc_T", def.dim_T)
  st_numscalar("_xpvc_p", dim_p)
  st_matrix("_xpvc_eigenvalues", rrr.lambda')
  st_matrix("_xpvc_trace_stat", stats_TR')
  st_matrix("_xpvc_trace_pval", pvals_TR')
  st_matrix("_xpvc_maxeig_stat", stats_ME')
  st_matrix("_xpvc_maxeig_pval", pvals_ME')
  st_matrix("_xpvc_beta", beta)
  st_global("r(method)", method)
  st_global("r(type)", type)
}

end
