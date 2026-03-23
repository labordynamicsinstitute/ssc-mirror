*! _fjcoint_johansen.ado -- Standard Johansen Cointegration Test
*! Faithful line-by-line translation of appl_Johansen.gss by Saban Nazlioglu
*! Reference: Johansen (1991, Econometrica), Johansen & Juselius (1990)
*! Part of fjcoint package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _fjcoint_johansen, rclass
  version 14.0
  
  syntax, VARlist(string) TOUSE(string) MODel(integer) LAGs(integer) ///
         [NOTable GRaph]
  
  local m : word count `varlist'
  
  if `m' < 2 | `m' > 6 {
    di as err "number of variables must be between 2 and 6"
    exit 198
  }
  if `model' < 1 | `model' > 5 {
    di as err "model must be 1-5"
    exit 198
  }
  
  if `model' == 1      local modname "None"
  else if `model' == 2 local modname "Restricted Constant"
  else if `model' == 3 local modname "Unrestricted Constant"
  else if `model' == 4 local modname "Restricted Trend"
  else if `model' == 5 local modname "Unrestricted Trend"
  
  * ---- Mata computation ----
  mata: _fjcoint_johansen_mata("`varlist'", "`touse'", `model', `m', `lags')
  
  * Get critical values
  _fjcoint_cv_johansen `model' `m'
  tempname cv_tr
  matrix `cv_tr' = r(cv_trace)
  
  * ---- Display ----
  if "`notable'" == "" {
    _fjcoint_display_johansen, m(`m') lags(`lags') modname("`modname'") ///
      model(`model')
  }
  
  * Return results
  return matrix eigenvalues = _fjc_eigenvals
  return matrix lambda     = _fjc_lambda
  return matrix trace      = _fjc_trace
  return matrix cv_trace   = `cv_tr'
  return matrix logL       = _fjc_logL
  return scalar nobs       = _fjc_nobs
  return scalar nvars      = `m'
  return local  model      "`modname'"
  return local  test       "johansen"
  
end

* ---- Display subroutine ----
program define _fjcoint_display_johansen
  syntax, m(integer) lags(integer) modname(string) model(integer)
  
  local T = _fjc_nobs
  
  _fjcoint_cv_johansen `model' `m'
  tempname cv_tr
  matrix `cv_tr' = r(cv_trace)
  
  di
  di in smcl in gr "{hline 72}"
  di in gr _col(10) "{bf:Johansen Cointegration Test}"
  di in smcl in gr "{hline 72}"
  di in gr "  # Variables = " in ye "`m'" ///
     _col(36) in gr "VAR lags  = " in ye "`lags'" ///  
     _col(56) in gr "Obs = " in ye %6.0f `T'
  di in gr "  Specification: " in ye "`modname'"
  di in gr _col(36) "VECM lags = " in ye %2.0f `=`lags'-1'
  di in smcl in gr "{hline 72}"
  di in gr "             Eigen                           cv(5%)" _col(60) "Log-"
  di in gr "   Rank      Value      Lambda      Trace    Trace" _col(58) "Likelihood"
  di in smcl in gr "{hline 72}"
  
  * Row for rank = 0 (only log-likelihood)
  local logL0 = _fjc_logL[1,1]
  di in ye _col(5) %3.0f 0 _col(58) %12.3f `logL0'
  
  * Rows for rank = 1, ..., m
  forvalues r = 1/`m' {
    local ev    = _fjc_eigenvals[`r', 1]
    local lam   = _fjc_lambda[`r', 1]
    local tr    = _fjc_trace[`r', 1]
    local logLr = _fjc_logL[`=`r'+1', 1]
    local cv    = `cv_tr'[1, `r']
    
    local star ""
    if `tr' > `cv' local star "**"
    
    di in ye _col(5) %3.0f `r' _col(13) %8.4f `ev' _col(25) %10.4f `lam' ///
       _col(37) %10.4f `tr' _col(49) %8.3f `cv' "`star'" _col(58) %12.3f `logLr'
  }
  
  di in smcl in gr "{hline 72}"
  di in gr "  ** denotes rejection at the 5% significance level"
  di in smcl in gr "{hline 72}"
  
end

* ---- Mata engine ----
* This is a faithful translation of the GAUSS procedure Johansen()
* from appl_Johansen.gss
mata:
void _fjcoint_johansen_mata(string scalar varlist, string scalar touse,
                            real scalar model, real scalar m, real scalar k)
{
  real matrix X, dx, z, lx, x_adj
  real matrix constant, trend, dt
  real matrix r0, r1, s00, sk0, skk, sig
  real colvector a, lr1, lr2
  real matrix Li
  real colvector lam, logL
  real scalar T, T_eff, q, i, n, kk
  
  // Load data
  st_view(X, ., tokens(varlist), touse)
  T = rows(X)
  
  // dx = x - lagn(x, 1)  => first difference, first row missing
  dx = J(1, m, .) \ (X[2::T, .] - X[1::T-1, .])
  
  // z = lagn(dx, 1)
  z = J(1, m, .) \ dx[1::T-1, .]
  
  // Add more lags: z = z ~ lagn(dx, q)
  q = 2
  while (q < k) {
    z = z, (J(q, m, .) \ dx[1::T-q, .])
    q = q + 1
  }
  
  // Deterministic terms
  constant = J(T, 1, 1)
  trend = (1::T)
  
  // Model specification (exactly as GAUSS)
  x_adj = X
  
  if (model == 1) {
    // None
    dt = J(T, 0, .)
    x_adj = X
  }
  else if (model == 2) {
    // Restricted constant
    dt = J(T, 0, .)
    x_adj = X, constant
  }
  else if (model == 3) {
    // Unrestricted constant
    dt = constant
    x_adj = X
  }
  else if (model == 4) {
    // Restricted trend
    dt = constant
    x_adj = X, trend
  }
  else if (model == 5) {
    // Unrestricted trend
    dt = constant, trend
    x_adj = X
  }
  
  // z = z ~ dt  (combine lags with deterministic)
  if (cols(dt) > 0) {
    z = z, dt
  }
  
  // trimr(z, k, 0)  - remove k rows from top
  z  = z[k+1::T, .]
  // trimr(dx, k, 0)
  dx = dx[k+1::T, .]
  // lx = trimr(lagn(x, k), k, 0)  - X lagged by k, then trim
  lx = x_adj[1::T-k, .]
  
  T_eff = rows(dx)
  
  // Residuals: r0 = dx - z*(dx/z) and r1 = lx - z*(lx/z)
  // GAUSS dx/z = OLS of dx on z => Stata: qrsolve(z, dx)
  r0 = dx - z * qrsolve(z, dx)
  r1 = lx - z * qrsolve(z, lx)
  
  // Product moment matrices
  skk = (r1' * r1) / T_eff
  sk0 = (r1' * r0) / T_eff
  s00 = (r0' * r0) / T_eff
  sig = sk0 * invsym(s00) * sk0'
  
  // Eigenvalue decomposition: eigrg2(inv(skk)*sig)
  real matrix eigvecs
  real rowvector eigvals_raw
  eigensystem(invsym(skk) * sig, eigvecs, eigvals_raw)
  a = Re(eigvals_raw')
  
  // Sort descending (GAUSS: rev(sortc(a,1)))
  real matrix sort_idx
  sort_idx = order(a, -1)
  a = a[sort_idx]
  
  // Keep only m eigenvalues
  a = a[1::m]
  
  // Clamp eigenvalues to [0, 1) range to avoid log issues
  for (i = 1; i <= rows(a); i++) {
    if (a[i] < 0) a[i] = 0
    if (a[i] >= 1) a[i] = 0.9999
  }
  
  // Trace statistics: lr1[i] = -T * sum(ln(1-a[j]) for j=i..m)
  lr1 = J(m, 1, .)
  for (i = 1; i <= m; i++) {
    real scalar s
    s = 0
    for (q = i; q <= m; q++) {
      s = s + ln(1 - a[q])
    }
    lr1[i] = -T_eff * s
  }
  
  // Lambda-max statistics
  lr2 = -T_eff * ln(1 :- a)
  
  // Trim if model >= 2 (GAUSS: if model >= 2 or model == 4)
  if (model >= 2) {
    lr1 = lr1[1::m]
    lr2 = lr2[1::m]
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
  
  // Clamp
  for (i = 1; i <= rows(eigvals2); i++) {
    if (eigvals2[i] < 0) eigvals2[i] = 0
    if (eigvals2[i] >= 1) eigvals2[i] = 0.9999
  }
  
  // lam = 0 | rev(eigh(...))
  if (model == 2 | model == 4) {
    // lam = 0 | rev(trimr(eigh(...), 1, 0))
    // Remove the first eigenvalue (extra from restricted model), keep m
    lam = 0 \ eigvals2[1::m]
  }
  else {
    lam = 0 \ eigvals2
  }
  
  // k = cols(dx/z) = cols of OLS coefficient matrix = cols(dx) = m
  kk = m
  
  // logL = -(T/2) * (k*(1+ln(2*pi)) + ln(det(r0'r0/T)) + cumsum(ln(1-lam)))
  logL = J(rows(lam), 1, .)
  real scalar cumln
  cumln = 0
  for (i = 1; i <= rows(lam); i++) {
    cumln = cumln + ln(1 - lam[i])
    logL[i] = -(T_eff / 2) * (kk * (1 + ln(2 * pi())) + ln(det(r0' * r0 / T_eff)) + cumln)
  }
  
  // Store results in Stata matrices
  st_matrix("_fjc_eigenvals", a)
  st_matrix("_fjc_lambda", lr2)
  st_matrix("_fjc_trace", lr1)
  st_matrix("_fjc_logL", logL)
  st_numscalar("_fjc_nobs", T_eff)
}
end
