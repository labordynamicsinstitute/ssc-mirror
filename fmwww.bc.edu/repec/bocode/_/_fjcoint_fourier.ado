*! _fjcoint_fourier.ado -- Johansen-Fourier Cointegration Test
*! Faithful line-by-line translation of Johansen_Fourier() from
*! appl_Johansen_Fourier.gss by Saban Nazlioglu
*! Reference: Pascalau, Lee, Nazlioglu & Lu (2022, J. Time Series Analysis)
*! Part of fjcoint package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _fjcoint_fourier, rclass
  version 14.0
  
  syntax, VARlist(string) TOUSE(string) MODel(integer) LAGs(integer) ///
         FREQ(integer) OPTion(integer) [NOTable GRaph]
  
  local m : word count `varlist'
  
  if `m' < 2 | `m' > 5 {
    di as err "number of variables must be between 2 and 5 for Fourier test"
    exit 198
  }
  if `model' < 1 | `model' > 4 {
    di as err "Fourier model must be 1-4"
    exit 198
  }
  
  * Model names for display
  if `model' == 1      local modname "Unrestricted Constant"
  else if `model' == 2 local modname "Unrestricted Trend"
  else if `model' == 3 local modname "Restricted Constant"
  else if `model' == 4 local modname "Restricted Trend"
  
  if `option' == 1 local optname "Single"
  else             local optname "Cumulative"
  
  * ---- Mata computation ----
  mata: _fjcoint_fourier_mata("`varlist'", "`touse'", `model', `m', `lags', `freq', `option')
  
  * Get critical values
  _fjcoint_cv_trace `option' `model' `freq' `m'
  tempname cv_tr_mat
  matrix `cv_tr_mat' = r(cv_matrix)
  
  _fjcoint_cv_lambda `option' `model' `freq' `m'
  tempname cv_lam_mat
  matrix `cv_lam_mat' = r(cv_matrix)
  
  * Build CV vectors for display (reversed order like GAUSS: rev(cv'))
  tempname cv_tr cv_lam
  matrix `cv_tr' = J(1, `m', .)
  matrix `cv_lam' = J(1, `m', .)
  forvalues r = 1/`m' {
    * GAUSS cv_lr1 = rev(cv_lr1') => column r maps to m-r+1
    matrix `cv_tr'[1, `r'] = `cv_tr_mat'[`freq', `m' - `r' + 1]
    matrix `cv_lam'[1, `r'] = `cv_lam_mat'[`freq', `m' - `r' + 1]
  }
  
  * ---- Display ----
  if "`notable'" == "" {
    _fjcoint_display_fourier, m(`m') lags(`lags') freq(`freq') ///
      modname("`modname'") optname("`optname'") model(`model') ///
      option(`option')
  }
  
  * Return results
  return matrix eigenvalues = _fjc_eigenvals
  return matrix lambda     = _fjc_lambda
  return matrix trace      = _fjc_trace
  return matrix cv_trace   = `cv_tr'
  return matrix cv_lambda  = `cv_lam'
  return matrix logL       = _fjc_logL
  return scalar nobs       = _fjc_nobs
  return scalar nvars      = `m'
  return scalar frequency  = `freq'
  return scalar option     = `option'
  return local  model      "`modname'"
  return local  test       "fourier"
  
end

* ---- Display subroutine ----
program define _fjcoint_display_fourier
  syntax, m(integer) lags(integer) freq(integer) ///
          modname(string) optname(string) model(integer) option(integer)
  
  local T = _fjc_nobs
  
  di
  di in smcl in gr "{hline 72}"
  di in gr _col(7) "{bf:Johansen-Fourier Cointegration Test}"
  di in smcl in gr "{hline 72}"
  di in gr "  # Variables = " in ye "`m'" ///
     _col(36) in gr "VAR lags  = " in ye "`lags'" ///
     _col(56) in gr "Obs = " in ye %6.0f `T'
  di in gr "  Specification: " in ye "`modname'"
  di in gr _col(36) "VECM lags = " in ye %2.0f `=`lags'-1'
  di in gr "  Frequency  = " in ye "`freq'" ///
     _col(36) in gr "Option    = " in ye "`optname'"
  di in smcl in gr "{hline 72}"
  di in gr "           Fourier    Fourier    cv(5%)     cv(5%)"  _col(58) "Log-"
  di in gr "   Rank    Lambda     Trace      Lambda     Trace" _col(56) "Likelihood"
  di in smcl in gr "{hline 72}"
  
  * Row for rank = 0
  local logL0 = _fjc_logL[1,1]
  di in ye _col(5) %3.0f 0 _col(56) %14.3f `logL0'
  
  * Get CVs
  _fjcoint_cv_trace `option' `model' `freq' `m'
  tempname cv_tr_m
  matrix `cv_tr_m' = r(cv_matrix)
  
  _fjcoint_cv_lambda `option' `model' `freq' `m'
  tempname cv_lam_m
  matrix `cv_lam_m' = r(cv_matrix)
  
  forvalues r = 1/`m' {
    local lam   = _fjc_lambda[`r', 1]
    local tr    = _fjc_trace[`r', 1]
    local logLr = _fjc_logL[`=`r'+1', 1]
    
    * CVs reversed (GAUSS rev())
    local cv_lam_r = `cv_lam_m'[`freq', `m' - `r' + 1]
    local cv_tr_r  = `cv_tr_m'[`freq', `m' - `r' + 1]
    
    local star_lam ""
    local star_tr  ""
    if `lam' > `cv_lam_r' local star_lam "**"
    if `tr'  > `cv_tr_r'  local star_tr  "**"
    
    di in ye _col(5) %3.0f `r' _col(11) %10.3f `lam' _col(22) %10.3f `tr' ///
       _col(33) %10.3f `cv_lam_r' "`star_lam'" _col(44) %10.3f `cv_tr_r' "`star_tr'" ///
       _col(56) %14.3f `logLr'
  }
  
  di in smcl in gr "{hline 72}"
  di in gr "  ** denotes rejection at the 5% significance level"
  di in smcl in gr "{hline 72}"
  
end

* ---- Mata engine ----
* Faithful translation of Johansen_Fourier() from appl_Johansen_Fourier.gss
mata:
void _fjcoint_fourier_mata(string scalar varlist, string scalar touse,
                           real scalar model, real scalar m, real scalar k,
                           real scalar f, real scalar option)
{
  real matrix X, dx, z, lx, x_adj
  real matrix constant, trend, sink, cosk, dt
  real matrix r0, r1, s00, sk0, skk, sig
  real colvector a, lr1, lr2
  real matrix Li
  real colvector lam, logL
  real scalar T, T_eff, q, i, j, n, kk
  
  // Load data
  st_view(X, ., tokens(varlist), touse)
  T = rows(X)
  
  // dx = x - lagn(x, 1)
  dx = J(1, m, .) \ (X[2::T, .] - X[1::T-1, .])
  
  // Deterministic terms
  constant = J(T, 1, 1)
  trend = (1::T)
  
  // Fourier series (exactly as GAUSS)
  if (option == 1) {
    // Single frequency
    sink = sin(2 * pi() * f * (1::T) / T)
    cosk = cos(2 * pi() * f * (1::T) / T)
  }
  else {
    // Cumulative frequencies
    sink = J(T, 0, .)
    cosk = J(T, 0, .)
    for (j = 1; j <= f; j++) {
      sink = sink, sin(2 * pi() * j * (1::T) / T)
      cosk = cosk, cos(2 * pi() * j * (1::T) / T)
    }
  }
  
  // Model specification (exactly as GAUSS models 1-4)
  x_adj = X
  
  if (model == 1) {
    // Unrestricted constant: dt = constant ~ sink ~ cosk
    dt = constant, sink, cosk
    x_adj = X
  }
  else if (model == 2) {
    // Unrestricted trend: dt = constant ~ trend ~ sink ~ cosk
    dt = constant, trend, sink, cosk
    x_adj = X
  }
  else if (model == 3) {
    // Restricted constant: dt = sink ~ cosk; x = x ~ constant
    dt = sink, cosk
    x_adj = X, constant
  }
  else if (model == 4) {
    // Restricted trend: dt = constant ~ sink ~ cosk; x = x ~ trend
    dt = constant, sink, cosk
    x_adj = X, trend
  }
  
  // z = lagn(dx, 1)
  z = J(1, m, .) \ dx[1::T-1, .]
  
  // Add more lags: z = z ~ lagn(dx, q) for q = 2..k-1
  q = 2
  while (q < k) {
    z = z, (J(q, m, .) \ dx[1::T-q, .])
    q = q + 1
  }
  
  // z = z ~ dt
  z = z, dt
  
  // trimr(z, k, 0) — remove k rows from top
  z  = z[k+1::T, .]
  dx = dx[k+1::T, .]
  // lx = trimr(lagn(x, k), k, 0) — X_adj lagged by k, trimmed
  lx = x_adj[1::T-k, .]
  
  T_eff = rows(dx)
  
  // Residuals
  r0 = dx - z * qrsolve(z, dx)
  r1 = lx - z * qrsolve(z, lx)
  
  // Product moment matrices
  skk = (r1' * r1) / T_eff
  sk0 = (r1' * r0) / T_eff
  s00 = (r0' * r0) / T_eff
  sig = sk0 * invsym(s00) * sk0'
  
  // Eigenvalue decomposition
  real matrix eigvecs
  real rowvector eigvals_raw
  eigensystem(invsym(skk) * sig, eigvecs, eigvals_raw)
  a = Re(eigvals_raw')
  
  // Sort descending
  real matrix sort_idx
  sort_idx = order(a, -1)
  a = a[sort_idx]
  
  // Clamp eigenvalues
  for (i = 1; i <= rows(a); i++) {
    if (a[i] < 0) a[i] = 0
    if (a[i] >= 1) a[i] = 0.9999
  }
  
  // Trace statistics
  lr1 = J(rows(a), 1, .)
  for (i = 1; i <= rows(a); i++) {
    real scalar s
    s = 0
    for (q = i; q <= rows(a); q++) {
      s = s + ln(1 - a[q])
    }
    lr1[i] = -T_eff * s
  }
  
  // Lambda-max statistics
  lr2 = -T_eff * ln(1 :- a)
  
  // Trim if model >= 3 (restricted: extra column in x_adj)
  if (model >= 3) {
    lr1 = lr1[1::m]
    lr2 = lr2[1::m]
    a = a[1::m]
  }
  
  // Log-likelihood computation
  n = cols(x_adj)
  Li = luinv(cholesky(r1' * r1))
  
  real matrix eigM
  real rowvector eigvals2_raw
  eigM = Li * r1' * r0 * invsym(r0' * r0) * r0' * r1 * Li'
  eigM = (eigM + eigM') / 2  // symmetrize
  
  real matrix eigvecs2
  eigensystem(eigM, eigvecs2, eigvals2_raw)
  real colvector eigvals2
  eigvals2 = Re(eigvals2_raw')
  sort_idx = order(eigvals2, -1)
  eigvals2 = eigvals2[sort_idx]
  
  for (i = 1; i <= rows(eigvals2); i++) {
    if (eigvals2[i] < 0) eigvals2[i] = 0
    if (eigvals2[i] >= 1) eigvals2[i] = 0.9999
  }
  
  if (model >= 3) {
    // Remove extra eigenvalue (from the restricted coeff)
    lam = 0 \ eigvals2[1::m]
  }
  else {
    lam = 0 \ eigvals2
  }
  
  // k = cols(dx/z) — in GAUSS this returns cols of OLS coeff = cols(dx) = m
  kk = m
  
  // logL = -(T/2) * (k*(1+ln(2*pi)) + ln(det(r0'r0/T)) + cumsum(ln(1-lam)))
  logL = J(rows(lam), 1, .)
  real scalar cumln
  cumln = 0
  for (i = 1; i <= rows(lam); i++) {
    cumln = cumln + ln(1 - lam[i])
    logL[i] = -(T_eff / 2) * (kk * (1 + ln(2 * pi())) + ln(det(r0' * r0 / T_eff)) + cumln)
  }
  
  // Store results
  st_matrix("_fjc_eigenvals", a[1::m])
  st_matrix("_fjc_lambda", lr2[1::m])
  st_matrix("_fjc_trace", lr1[1::m])
  st_matrix("_fjc_logL", logL)
  st_numscalar("_fjc_nobs", T_eff)
}
end
