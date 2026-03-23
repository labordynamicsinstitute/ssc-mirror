*! _fjcoint_sbc.ado -- SBC Model Selection Procedure
*! Translation of SBC and SC_Fourier procedures from appl_SBCunion.gss
*! Reference: Pascalau, Lee, Nazlioglu & Lu (2022, J. Time Series Analysis)
*! Part of fjcoint package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _fjcoint_sbc, rclass
  version 14.0
  
  syntax, VARlist(string) TOUSE(string) MODel(integer) ///
         MAXLag(integer) TRIMming(real) MAXFreq(integer) ///
         OPTion(integer) [NOTable GRaph]
  
  local m : word count `varlist'
  
  qui count if `touse'
  local T = r(N)
  
  * Model name
  if `model' == 1      local modname "Unrestricted Constant"
  else if `model' == 2 local modname "Unrestricted Trend"
  else if `model' == 3 local modname "Restricted Constant"
  else                 local modname "Restricted Trend"
  
  if `option' == 1 local optname "Single"
  else             local optname "Cumulative"
  
  * ---- Display header ----
  if "`notable'" == "" {
    di
    di in smcl in gr "{hline 72}"
    di in gr _col(8) "{bf:SBC Model Selection Procedure}"
    di in smcl in gr "{hline 72}"
    di in gr "  # Variables = " in ye "`m'" ///
       _col(36) in gr "Max lag = " in ye "`maxlag'" ///
       _col(56) in gr "Obs = " in ye "`T'"
    di in gr "  Specification: " in ye "`modname'"
    di in gr "  Frequency    : " in ye "`optname'" ///
       _col(36) in gr "Max freq = " in ye "`maxfreq'"
  }
  
  * ---- Run for each rank ----
  local rm1 = `m' - 1
  
  forvalues r = 0/`rm1' {
    * 1) SC-VECM
    _fjcoint_scvecm, varlist(`varlist') touse(`touse') rank(`r') ///
      maxlag(`maxlag') trimming(`trimming')
    
    local tr0_`r' = r(tr0)
    local sc0_`r' = r(sc0)
    local p0_`r'  = r(p0)
    local cv0_`r' = r(cv0)
    local tr1_`r' = r(tr1)
    local sc1_`r' = r(sc1)
    local p1_`r'  = r(p1)
    local cv1_`r' = r(cv1)
    local tb_`r'  = r(tb)
    
    * 2) SC-Fourier: grid search
    mata: _fjcoint_sc_fourier_mata("`varlist'", "`touse'", `r', `m', ///
                                   `model', `maxlag', `maxfreq', `option')
    
    local tr2_`r' = _fjc_scf_tr
    local sc2_`r' = _fjc_scf_sc
    local p2_`r'  = _fjc_scf_p
    local f_`r'   = _fjc_scf_f
    
    * CV for SC-Fourier
    local n_r = `m' - `r'
    if `n_r' >= 1 & `n_r' <= 8 & `f_`r'' >= 1 & `f_`r'' <= 5 {
      _fjcoint_cv_sbc fourier `option' `model' `=int(`f_`r'')' `n_r'
      local cv2_`r' = r(cv)
    }
    else {
      local cv2_`r' = .
    }
    
    * 3) SBC selection
    local sbc_min = `sc0_`r''
    local tr_sbc  = `tr0_`r''
    local cv_sbc  = `cv0_`r''
    local p_sbc   = `p0_`r''
    local br_sbc  = .
    local sel     = "Johansen"
    
    if `sc1_`r'' < `sbc_min' {
      local sbc_min = `sc1_`r''
      local tr_sbc  = `tr1_`r''
      local cv_sbc  = `cv1_`r''
      local p_sbc   = `p1_`r''
      local br_sbc  = `tb_`r''
      local sel     = "SC-VECM"
    }
    
    if `sc2_`r'' < `sbc_min' {
      local sbc_min = `sc2_`r''
      local tr_sbc  = `tr2_`r''
      local cv_sbc  = `cv2_`r''
      local p_sbc   = `p2_`r''
      local br_sbc  = `f_`r''
      local sel     = "Fourier"
    }
    
    local sel_`r' = "`sel'"
    local trsbc_`r' = `tr_sbc'
    local cvsbc_`r' = `cv_sbc'
    local psbc_`r'  = `p_sbc'
    local brsbc_`r' = `br_sbc'
    local sbcmin_`r' = `sbc_min'
  }
  
  * ---- Display table ----
  if "`notable'" == "" {
    di in smcl in gr "{hline 72}"
    di in gr _col(15) "Johansen" _col(28) "SC-VECM" _col(40) "SC-Fourier" _col(55) "SBC"
    di in smcl in gr "{hline 72}"
    
    forvalues r = 0/`rm1' {
      di in ye "  Rank(r)=" %1.0f `r'
      
      * Significance markers
      local s0 ""
      local s1 ""
      local s2 ""
      local ss ""
      if `tr0_`r'' > `cv0_`r'' & `cv0_`r'' < . local s0 "**"
      if `tr1_`r'' > `cv1_`r'' & `cv1_`r'' < . local s1 "**"
      if `tr2_`r'' > `cv2_`r'' & `cv2_`r'' < . local s2 "**"
      if `trsbc_`r'' > `cvsbc_`r'' & `cvsbc_`r'' < . local ss "**"
      
      di in gr "    Trace  = " in ye %10.3f `tr0_`r'' _col(28) %10.3f `tr1_`r'' ///
         _col(40) %10.3f `tr2_`r'' _col(55) %10.3f `trsbc_`r''
      di in gr "    SBC    = " in ye %10.3f `sc0_`r'' _col(28) %10.3f `sc1_`r'' ///
         _col(40) %10.3f `sc2_`r'' _col(55) %10.3f `sbcmin_`r''
      di in gr "    Lag    = " in ye _col(15) %5.0f `p0_`r'' _col(28) %5.0f `p1_`r'' ///
         _col(40) %5.0f `p2_`r'' _col(55) %5.0f `psbc_`r''
      di in gr "    TB & F = " in ye _col(15) %10s "." _col(28) %10.0f `tb_`r'' ///
         _col(40) %10.0f `f_`r'' _col(55) %10.3f `brsbc_`r''
      di in gr "    5% cv  = " in ye %10.3f `cv0_`r'' "`s0'" _col(28) %10.3f `cv1_`r'' "`s1'" ///
         _col(40) %10.3f `cv2_`r'' "`s2'" _col(55) %10.3f `cvsbc_`r'' "`ss'"
      di in gr "    Select : " in ye "`sel_`r''"
      di in smcl in gr "  {hline 66}"
    }
    
    di in smcl in gr "{hline 72}"
    di in gr "  ** denotes rejection at the 5% significance level"
    di in smcl in gr "{hline 72}"
  }
  
  return local  test     "sbc"
  return local  selected "`sel_0'"
  
end

* ---- Mata: SC-Fourier grid search ----
mata:
void _fjcoint_sc_fourier_mata(string scalar varlist, string scalar touse,
                              real scalar r, real scalar m,
                              real scalar model, real scalar k_max,
                              real scalar f_max, real scalar option)
{
  real matrix y
  st_view(y, ., tokens(varlist), touse)
  
  real scalar T, n
  T = rows(y)
  n = m
  
  // Grid search over frequencies and lags
  real matrix keep_mat
  keep_mat = J(0, 4, .)
  
  real scalar f, k
  for (f = 1; f <= f_max; f++) {
    for (k = 1; k <= k_max; k++) {
      real colvector TR, SBC_vec
      _jf_compute(y, r, model, k, f, option, T, n, TR, SBC_vec)
      
      // bounds check
      if (r + 1 <= rows(TR) & r + 1 <= rows(SBC_vec)) {
        keep_mat = keep_mat \ (f, k, TR[r + 1], SBC_vec[r + 1])
      }
    }
  }
  
  // Min-SBC
  if (rows(keep_mat) == 0) {
    st_numscalar("_fjc_scf_f", 1)
    st_numscalar("_fjc_scf_p", 1)
    st_numscalar("_fjc_scf_tr", .)
    st_numscalar("_fjc_scf_sc", .)
    return
  }
  
  real scalar min_ind, min_sbc, ii
  min_ind = 1
  min_sbc = keep_mat[1, 4]
  for (ii = 2; ii <= rows(keep_mat); ii++) {
    if (keep_mat[ii, 4] < min_sbc) {
      min_sbc = keep_mat[ii, 4]
      min_ind = ii
    }
  }
  
  st_numscalar("_fjc_scf_f", keep_mat[min_ind, 1])
  st_numscalar("_fjc_scf_p", keep_mat[min_ind, 2])
  st_numscalar("_fjc_scf_tr", keep_mat[min_ind, 3])
  st_numscalar("_fjc_scf_sc", keep_mat[min_ind, 4])
}

// Compute Johansen-Fourier log-L, trace, SBC for given params
void _jf_compute(real matrix x, real scalar r_val,
                 real scalar model, real scalar k, real scalar f,
                 real scalar option, real scalar T, real scalar n,
                 real colvector TR, real colvector SBC_out)
{
  real matrix dx, constant, trend, sink, cosk, dt, z, lx, x_adj
  real matrix r0, r1, s00, sk0, skk, sig
  real colvector a
  real colvector lr1
  real matrix Li
  real colvector lam, logL
  real scalar T_eff, q, i, j, m, kk, nn
  
  m = cols(x)
  
  // dx = x - lagn(x,1)
  dx = J(1, m, .) \ (x[2::T, .] - x[1::T-1, .])
  
  constant = J(T, 1, 1)
  trend = (1::T)
  
  // Fourier
  if (option == 1) {
    sink = sin(2 * pi() * f * (1::T) / T)
    cosk = cos(2 * pi() * f * (1::T) / T)
  }
  else {
    sink = J(T, 0, .)
    cosk = J(T, 0, .)
    for (j = 1; j <= f; j++) {
      sink = sink, sin(2 * pi() * j * (1::T) / T)
      cosk = cosk, cos(2 * pi() * j * (1::T) / T)
    }
  }
  
  // Model
  x_adj = x
  if (model == 1) {
    dt = constant, sink, cosk
    x_adj = x
  }
  else if (model == 2) {
    dt = constant, trend, sink, cosk
    x_adj = x
  }
  else if (model == 3) {
    dt = sink, cosk
    x_adj = x, constant
  }
  else if (model == 4) {
    dt = constant, sink, cosk
    x_adj = x, trend
  }
  
  // Lag matrix
  z = J(1, m, .) \ dx[1::T-1, .]
  q = 2
  while (q < k) {
    z = z, (J(q, m, .) \ dx[1::T-q, .])
    q = q + 1
  }
  
  z = z, dt
  z  = z[k+1::T, .]
  dx = dx[k+1::T, .]
  lx = x_adj[1::T-k, .]
  
  T_eff = rows(dx)
  
  // Residuals
  r0 = dx - z * qrsolve(z, dx)
  r1 = lx - z * qrsolve(z, lx)
  
  // Eigenvalues
  skk = (r1' * r1) / T_eff
  sk0 = (r1' * r0) / T_eff
  s00 = (r0' * r0) / T_eff
  sig = sk0 * invsym(s00) * sk0'
  
  real matrix eigvecs
  real rowvector eigvals_raw
  eigensystem(invsym(skk) * sig, eigvecs, eigvals_raw)
  a = Re(eigvals_raw')
  real matrix idx
  idx = order(a, -1)
  a = a[idx]
  
  for (i = 1; i <= rows(a); i++) {
    if (a[i] < 0) a[i] = 0
    if (a[i] >= 1) a[i] = 0.9999
  }
  
  // Trace
  lr1 = J(rows(a), 1, .)
  for (i = 1; i <= rows(a); i++) {
    real scalar s
    s = 0
    for (q = i; q <= rows(a); q++) {
      s = s + ln(1 - a[q])
    }
    lr1[i] = -T_eff * s
  }
  
  // Trim for restricted models
  if (model >= 3) {
    lr1 = lr1[1::m]
    a = a[1::m]
  }
  
  // Log-likelihood
  nn = cols(x_adj)
  Li = luinv(cholesky(r1' * r1))
  real matrix eigM
  eigM = Li * r1' * r0 * invsym(r0' * r0) * r0' * r1 * Li'
  eigM = (eigM + eigM') / 2
  
  real matrix eigvecs2
  real rowvector eigvals2_raw
  eigensystem(eigM, eigvecs2, eigvals2_raw)
  real colvector eigvals2
  eigvals2 = Re(eigvals2_raw')
  idx = order(eigvals2, -1)
  eigvals2 = eigvals2[idx]
  
  for (i = 1; i <= rows(eigvals2); i++) {
    if (eigvals2[i] < 0) eigvals2[i] = 0
    if (eigvals2[i] >= 1) eigvals2[i] = 0.9999
  }
  
  if (model >= 3) {
    lam = 0 \ eigvals2[1::m]
  }
  else {
    lam = 0 \ eigvals2
  }
  
  kk = m
  
  logL = J(rows(lam), 1, .)
  real scalar cumln
  cumln = 0
  for (i = 1; i <= rows(lam); i++) {
    cumln = cumln + ln(1 - lam[i])
    logL[i] = -(T_eff / 2) * (kk * (1 + ln(2 * pi())) + ln(det(r0' * r0 / T_eff)) + cumln)
  }
  
  // SBC
  SBC_out = J(rows(lam), 1, .)
  for (i = 1; i <= rows(lam); i++) {
    real scalar r_i
    r_i = i - 1
    SBC_out[i] = -2 * logL[i] + (nn + r_i + 2 + (nn * nn) * k) * ln(T_eff)
  }
  
  TR = lr1
}
end
