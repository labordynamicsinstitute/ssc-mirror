*! _xtpvarcoint_irf.ado — Impulse Response Functions & FEVD
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_irf
program define _xpvc_irf, rclass
  version 14.0
  syntax [, Horizon(integer 20) CI(real 0.95) BOOT(integer 0) ///
    BLOCKsize(integer 0) CUMulative ORTHogonal]
  
  * Check previous estimation
  capture confirm matrix _xpvc_A
  if _rc {
    di in red "VAR model must be estimated first"
    exit 301
  }
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint irf} — Impulse Response Functions" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Horizon:  " in ye "`horizon'"
  if `boot' > 0 {
    di in gr "  Bootstrap: " in ye "`boot' replications"
    di in gr "  CI level:  " in ye "`ci'"
  }
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_irf_run(`horizon', `ci', `boot', `blocksize', ///
    ("`cumulative'" != ""), ("`orthogonal'" != ""))
  
  return add
end

capture program drop _xpvc_fevd
program define _xpvc_fevd, rclass
  version 14.0
  syntax [, Horizon(integer 20)]
  
  capture confirm matrix _xpvc_A
  if _rc {
    di in red "VAR model must be estimated first"
    exit 301
  }
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint fevd} — Forecast Error Variance Decomposition" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_fevd_run(`horizon')
  
  return add
end

mata:
mata set matastrict off

void _xpvc_irf_run(real scalar n_ahead, real scalar ci_level,
                     real scalar n_boot, real scalar block_size,
                     real scalar cumulative, real scalar orthogonal)
{
  real matrix A, B
  real scalar dim_K, dim_p, h, j, k
  string scalar _hline78
  
  _hline78 = 78 * "-"
  
  A = st_matrix("_xpvc_A")
  dim_K = rows(A)
  dim_p = cols(A) / dim_K
  
  // Get B matrix
  B = st_matrix("_xpvc_B")
  if (rows(B) == 0 | cols(B) == 0) {
    real matrix OMEGA
    OMEGA = st_matrix("_xpvc_OMEGA")
    if (rows(OMEGA) > 0) {
      if (orthogonal) {
        B = cholesky(OMEGA)
      }
      else {
        B = I(dim_K)
      }
    }
    else {
      B = I(dim_K)
    }
  }
  
  // Compute MA coefficients PHI
  pointer(real matrix) colvector PHI
  _xpvc_IRF_phi(A, dim_p, n_ahead, PHI)
  
  // Compute structural IRF: THETA_h = PHI_h * B
  pointer(real matrix) colvector THETA
  _xpvc_IRF_theta(PHI, B, n_ahead, THETA)
  
  // Store IRF in matrix: (n_ahead+1) x (K*K)
  real matrix IRF_mat, IRF_cum
  IRF_mat = J(n_ahead + 1, dim_K * dim_K, 0)
  IRF_cum = J(n_ahead + 1, dim_K * dim_K, 0)
  
  for (h = 0; h <= n_ahead; h++) {
    real matrix theta_h
    theta_h = *THETA[h+1]
    for (j = 1; j <= dim_K; j++) {
      for (k = 1; k <= dim_K; k++) {
        IRF_mat[h+1, (j-1)*dim_K + k] = theta_h[j, k]
      }
    }
    if (h == 0) {
      IRF_cum[1, .] = IRF_mat[1, .]
    }
    else {
      IRF_cum[h+1, .] = IRF_cum[h, .] + IRF_mat[h+1, .]
    }
  }
  
  // Display IRF table
  printf("  Impulse Response Functions (structural):\n")
  printf("%s\n", _hline78)
  
  for (j = 1; j <= dim_K; j++) {
    for (k = 1; k <= dim_K; k++) {
      printf("  Response of var%g to shock%g:\n", j, k)
      printf("  %6s", "h")
      printf("  %12s", "IRF")
      if (cumulative) printf("  %12s", "Cum.IRF")
      printf("\n")
      
      for (h = 0; h <= min((n_ahead, 10)); h++) {
        real scalar irf_val
        irf_val = IRF_mat[h+1, (j-1)*dim_K + k]
        printf("  %g  %g", h, irf_val)
        if (cumulative) {
          printf("  %g", IRF_cum[h+1, (j-1)*dim_K + k])
        }
        printf("\n")
      }
      if (n_ahead > 10) printf("  ... (%g more periods)\n", n_ahead - 10)
      printf("\n")
    }
  }
  printf("%s\n\n", _hline78)
  
  // Store
  st_matrix("_xpvc_IRF", IRF_mat)
  if (cumulative) st_matrix("_xpvc_IRF_cum", IRF_cum)
  st_numscalar("_xpvc_horizon", n_ahead)
}


void _xpvc_fevd_run(real scalar n_ahead)
{
  real matrix A, B
  real scalar dim_K, dim_p, h, j, k
  string scalar _hline78
  
  _hline78 = 78 * "-"
  
  A = st_matrix("_xpvc_A")
  dim_K = rows(A)
  dim_p = cols(A) / dim_K
  
  B = st_matrix("_xpvc_B")
  if (rows(B) == 0) {
    real matrix OMEGA
    OMEGA = st_matrix("_xpvc_OMEGA")
    if (rows(OMEGA) > 0) B = cholesky(OMEGA)
    else B = I(dim_K)
  }
  
  // Compute THETA
  pointer(real matrix) colvector PHI, THETA
  _xpvc_IRF_phi(A, dim_p, n_ahead, PHI)
  _xpvc_IRF_theta(PHI, B, n_ahead, THETA)
  
  // Compute FEVD
  real matrix FEVD_mat
  _xpvc_FEVD(THETA, n_ahead, dim_K, FEVD_mat)
  
  // Display
  printf("  Forecast Error Variance Decomposition:\n")
  printf("%s\n", _hline78)
  
  for (j = 1; j <= dim_K; j++) {
    printf("  Variable %g — contribution of each shock:\n", j)
    printf("  %6s", "h")
    for (k = 1; k <= dim_K; k++) {
      printf("  %10s", sprintf("Shock%g", k))
    }
    printf("\n")
    
    for (h = 0; h <= min((n_ahead, 15)); h++) {
      printf("  %g", h)
      for (k = 1; k <= dim_K; k++) {
        printf("  %g", FEVD_mat[h+1, (j-1)*dim_K + k])
      }
      printf("\n")
    }
    if (n_ahead > 15) printf("  ... (%g more periods)\n", n_ahead - 15)
    printf("\n")
  }
  printf("%s\n\n", _hline78)
  
  // Store
  st_matrix("_xpvc_FEVD", FEVD_mat)
  st_numscalar("_xpvc_horizon", n_ahead)
}

end
