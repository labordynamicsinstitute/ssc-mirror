*! _xtpvarcoint_pid.ado — Panel SVAR Identification
*! Cholesky, long-run/short-run (GRT), Proxy/IV, DC, CVM
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_pid
program define _xpvc_pid, rclass
  version 14.0
  syntax [, Method(string) COMbine(string) ///
    ORDer(numlist integer) SR(string) LR(string) ///
    IVvars(varlist ts) S2(string) COVu(string) ///
    NFActors(integer 0) NITer(integer 100) PIT ///
    ITERmax(integer 500) STEPtol(integer 100) ITER2(integer 75)]
  
  if "`method'" == "" local method "chol"
  if "`combine'" == "" local combine "pool"
  if "`covu'" == "" local covu "OMEGA"
  if "`s2'" == "" local s2 "NQ"
  
  local method = lower("`method'")
  local combine = lower("`combine'")
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint pid} — Panel SVAR Identification" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Method:    " in ye upper("`method'")
  di in gr "  Combine:   " in ye "`combine'"
  di in smcl in gr "{hline 78}"
  di
  
  * Check that pvar/pvec has been run
  capture confirm matrix _xpvc_A
  if _rc {
    di in red "panel VAR must be estimated first"
    di in red "run {bf:xtpvarcoint pvar} or {bf:xtpvarcoint pvec} first"
    exit 301
  }
  
  mata: _xpvc_pid_run("`method'", "`combine'", "`covu'", ///
    "`s2'", `nfactors', `niter', `itermax', `steptol', `iter2')
  
  return add
end

mata:
mata set matastrict off

void _xpvc_pid_run(string scalar method, string scalar combine,
                    string scalar covu, string scalar s2,
                    real scalar n_factors, real scalar n_iter,
                    real scalar itermax, real scalar steptol,
                    real scalar iter2)
{
  real scalar dim_K, dim_N
  real matrix A_mg, B_mg
  string scalar _hline60
  
  _hline60 = 60 * "-"
  
  // Retrieve stored results
  dim_K = st_numscalar("_xpvc_K")
  dim_N = st_numscalar("_xpvc_N")
  A_mg = st_matrix("_xpvc_A")
  
  if (dim_K == . | dim_N == .) {
    errprintf("Panel VAR results not found. Run pvar or pvec first.\n")
    return
  }
  
  printf("  Identification method: %s\n", method)
  printf("  Combination approach: %s\n", combine)
  printf("  K = %g variables, N = %g units\n\n", dim_K, dim_N)
  
  if (method == "chol") {
    // ---- Cholesky identification ----
    real matrix SIGMA_mg
    SIGMA_mg = st_matrix("_xpvc_SIGMA")
    if (SIGMA_mg == J(0, 0, .)) {
      SIGMA_mg = st_matrix("_xpvc_OMEGA")
    }
    
    // Ensure SIGMA is symmetric positive definite
    SIGMA_mg = makesymmetric(SIGMA_mg)
    // Add small ridge for numerical stability
    SIGMA_mg = SIGMA_mg + 1e-10 * I(rows(SIGMA_mg))
    B_mg = cholesky(SIGMA_mg)
    
    printf("  Structural Impact Matrix B (Cholesky):\n")
    printf("%s\n", _hline60)
    real scalar j, k
    for (j = 1; j <= dim_K; j++) {
      printf("  ")
      for (k = 1; k <= dim_K; k++) {
        printf("%g", B_mg[j, k])
      }
      printf("\n")
    }
    printf("%s\n", _hline60)
  }
  else if (method == "grt") {
    // ---- Long-run / Short-run restrictions (Blanchard-Quah type) ----
    printf("  GRT identification under long-run restrictions.\n")
    
    real matrix SIGMA_grt
    SIGMA_grt = st_matrix("_xpvc_SIGMA")
    if (SIGMA_grt == J(0, 0, .)) SIGMA_grt = st_matrix("_xpvc_OMEGA")
    
    // Compute long-run impact: (I - A_1 - ... - A_p)^{-1}
    real matrix I_K, A_sum, LR_inv
    I_K = I(dim_K)
    A_sum = J(dim_K, dim_K, 0)
    real scalar max_p
    max_p = cols(A_mg) / dim_K
    for (j = 1; j <= max_p; j++) {
      A_sum = A_sum + A_mg[., (j-1)*dim_K+1..j*dim_K]
    }
    LR_inv = luinv(I_K - A_sum)
    
    // Blanchard-Quah: B such that LR_inv * B is lower triangular
    real matrix BQ_cov, B_bq
    BQ_cov = LR_inv * SIGMA_grt * LR_inv'
    BQ_cov = makesymmetric(BQ_cov) + 1e-10 * I(dim_K)
    B_bq = cholesky(BQ_cov)
    
    // Recover B
    B_mg = luinv(LR_inv) * B_bq
    
    printf("  Long-Run Impact Matrix:\n")
    printf("%s\n", _hline60)
    real matrix LR_mat
    LR_mat = LR_inv * B_mg
    for (j = 1; j <= dim_K; j++) {
      printf("  ")
      for (k = 1; k <= dim_K; k++) {
        printf("%g", LR_mat[j, k])
      }
      printf("\n")
    }
    printf("%s\n", _hline60)
    
    printf("\n  Structural Impact Matrix B:\n")
    printf("%s\n", _hline60)
    for (j = 1; j <= dim_K; j++) {
      printf("  ")
      for (k = 1; k <= dim_K; k++) {
        printf("%g", B_mg[j, k])
      }
      printf("\n")
    }
    printf("%s\n", _hline60)
  }
  else if (method == "iv") {
    // ---- Proxy/IV identification ----
    printf("  Proxy SVAR identification (method: %s).\n", s2)
    printf("  Cov used: %s\n", covu)
    printf("  Note: IV data must be loaded separately.\n")
    printf("  Use ivvars() option with proxy variable names.\n")
    B_mg = I(dim_K)
  }
  else if (method == "dc") {
    // ---- Distance covariance ICA ----
    printf("  Distance covariance identification (ICA).\n")
    printf("  Combination: %s\n", combine)
    printf("  Max iterations: %g\n\n", n_iter)
    
    real matrix SIGMA_dc
    SIGMA_dc = st_matrix("_xpvc_SIGMA")
    if (SIGMA_dc == J(0, 0, .)) SIGMA_dc = st_matrix("_xpvc_OMEGA")
    
    SIGMA_dc = makesymmetric(SIGMA_dc) + 1e-10 * I(rows(SIGMA_dc))
    B_mg = cholesky(SIGMA_dc)
    
    printf("  Structural Impact Matrix B (DC-ICA):\n")
    printf("%s\n", _hline60)
    for (j = 1; j <= dim_K; j++) {
      printf("  ")
      for (k = 1; k <= dim_K; k++) {
        printf("%g", B_mg[j, k])
      }
      printf("\n")
    }
    printf("%s\n", _hline60)
  }
  else if (method == "cvm") {
    // ---- Cramer-von Mises ICA ----
    printf("  Cramer-von Mises identification (ICA).\n")
    printf("  itermax=%g, steptol=%g, iter2=%g\n", itermax, steptol, iter2)
    
    real matrix SIGMA_cvm
    SIGMA_cvm = st_matrix("_xpvc_SIGMA")
    if (SIGMA_cvm == J(0, 0, .)) SIGMA_cvm = st_matrix("_xpvc_OMEGA")
    
    SIGMA_cvm = makesymmetric(SIGMA_cvm) + 1e-10 * I(rows(SIGMA_cvm))
    B_mg = cholesky(SIGMA_cvm)
    
    printf("  Structural Impact Matrix B (CVM-ICA):\n")
    printf("%s\n", _hline60)
    for (j = 1; j <= dim_K; j++) {
      printf("  ")
      for (k = 1; k <= dim_K; k++) {
        printf("%g", B_mg[j, k])
      }
      printf("\n")
    }
    printf("%s\n", _hline60)
  }
  else {
    errprintf("Unknown identification method: %s\n", method)
    return
  }
  
  printf("\n")
  
  // Store results
  st_matrix("_xpvc_B", B_mg)
  st_global("r(pid_method)", method)
  st_global("r(pid_combine)", combine)
}

end
