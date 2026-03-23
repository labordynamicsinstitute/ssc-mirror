*! _fjcoint_scvecm.ado -- SC-VECM Cointegration Test with Structural Break
*! Translation of SC_VECM, _get_logL_vecm, _get_logL_vecm_break
*! from appl_SBCunion.gss by Saban Nazlioglu
*! Reference: Harris, Leybourne & Taylor (2016, J. Econometrics)
*! Part of fjcoint package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _fjcoint_scvecm, rclass
  version 14.0
  
  syntax, VARlist(string) TOUSE(string) RANK(integer) ///
         MAXLag(integer) TRIMming(real)
  
  local m : word count `varlist'
  
  mata: _fjcoint_scvecm_mata("`varlist'", "`touse'", `rank', `m', `maxlag', `trimming')
  
  return scalar tr0   = _fjc_scvecm_tr0
  return scalar sc0   = _fjc_scvecm_sc0
  return scalar p0    = _fjc_scvecm_p0
  return scalar cv0   = _fjc_scvecm_cv0
  return scalar tr1   = _fjc_scvecm_tr1
  return scalar sc1   = _fjc_scvecm_sc1
  return scalar p1    = _fjc_scvecm_p1
  return scalar cv1   = _fjc_scvecm_cv1
  return scalar tb    = _fjc_scvecm_tb
  
end

mata:
void _fjcoint_scvecm_mata(string scalar varlist, string scalar touse,
                          real scalar r, real scalar n,
                          real scalar MaxLag, real scalar q)
{
  real matrix y
  st_view(y, ., tokens(varlist), touse)
  
  real scalar T, pc, lo, hi
  T = rows(y)
  
  // Break point candidates (trimmed)
  lo = floor(q * T) + 1
  hi = T - floor(q * T)
  real colvector bv
  bv = (lo::hi)
  
  // ==========================================
  // No-break model: log-likelihood for each lag
  // ==========================================
  real matrix loglp
  loglp = J(n + 1, MaxLag, .)
  
  for (pc = 1; pc <= MaxLag; pc++) {
    loglp[., pc] = _scvecm_get_logL(y, pc, T, n)
  }
  
  // Select optimal lag by SBC (no break, full rank model)
  real colvector sbc_nb
  sbc_nb = J(MaxLag, 1, .)
  for (pc = 1; pc <= MaxLag; pc++) {
    sbc_nb[pc] = -2 * loglp[n + 1, pc] + (n * n * pc) * ln(T)
  }
  
  real scalar p0, min_sbc
  p0 = 1
  min_sbc = sbc_nb[1]
  for (pc = 2; pc <= MaxLag; pc++) {
    if (sbc_nb[pc] < min_sbc) {
      min_sbc = sbc_nb[pc]
      p0 = pc
    }
  }
  
  // ==========================================
  // Break model: log-likelihood for each lag and break point
  // ==========================================
  real matrix loglbp
  loglbp = J(rows(bv), (n + 1) * MaxLag, .)
  
  for (pc = 1; pc <= MaxLag; pc++) {
    real matrix ll_bp
    ll_bp = _scvecm_get_logL_break(y, pc, bv, T, n)
    real scalar c1, c2
    c1 = (pc - 1) * (n + 1) + 1
    c2 = pc * (n + 1)
    loglbp[., c1::c2] = ll_bp
  }
  
  // For each lag, find best break point (max LL at full rank)
  real colvector sbc_br, bestbr
  sbc_br = J(MaxLag, 1, .)
  bestbr = J(MaxLag, 1, .)
  
  for (pc = 1; pc <= MaxLag; pc++) {
    real scalar c1b, c2b, best_b, bb
    real scalar best_ll
    c1b = (pc - 1) * (n + 1) + 1
    c2b = pc * (n + 1)
    
    // Find break with max LL at full rank
    best_b = 1
    best_ll = loglbp[1, c2b]
    for (bb = 2; bb <= rows(bv); bb++) {
      if (loglbp[bb, c2b] > best_ll) {
        best_ll = loglbp[bb, c2b]
        best_b = bb
      }
    }
    bestbr[pc] = best_b
    sbc_br[pc] = -2 * loglbp[best_b, c1b + r] + (n + r + 2 + n * n * pc) * ln(T)
  }
  
  // Select optimal lag for break model
  real scalar pbr, brphat_ind
  pbr = 1
  min_sbc = sbc_br[1]
  for (pc = 2; pc <= MaxLag; pc++) {
    if (sbc_br[pc] < min_sbc) {
      min_sbc = sbc_br[pc]
      pbr = pc
    }
  }
  brphat_ind = bestbr[pbr]
  
  // ==========================================
  // Trace statistics
  // ==========================================
  real scalar tr0_val, tr1_val
  tr0_val = 2 * (loglp[n + 1, p0] - loglp[r + 1, p0])
  
  real scalar c1_sel, c2_sel
  c1_sel = (pbr - 1) * (n + 1) + 1
  c2_sel = pbr * (n + 1)
  tr1_val = 2 * (loglbp[brphat_ind, c2_sel] - loglbp[brphat_ind, c1_sel + r])
  
  // ==========================================
  // Critical values
  // ==========================================
  real scalar cv0_val, cv1_val, nr
  nr = n - r
  
  // No-break CV
  real rowvector cv_nb_all
  cv_nb_all = (11.417, 23.453, 40.093, 60.511, 84.266, 113.479, 148.181, 181.694)
  if (nr >= 1 & nr <= 8) {
    cv0_val = cv_nb_all[nr]
  }
  else {
    cv0_val = .
  }
  
  // Break CV — map break fraction to row index
  real scalar break_frac, break_frac_row
  break_frac = bv[brphat_ind] / T
  break_frac_row = round((break_frac - 0.20) / 0.05) + 1
  if (break_frac_row < 1) break_frac_row = 1
  if (break_frac_row > 13) break_frac_row = 13
  
  real matrix cv_br_all
  cv_br_all = (
    18.238, 35.592, 54.792, 80.841, 109.971, 144.105, 181.728, 221.975 \
    18.675, 35.496, 56.462, 82.441, 111.072, 145.295, 183.790, 224.711 \
    19.060, 36.346, 58.111, 83.015, 112.578, 146.397, 183.065, 225.524 \
    18.953, 37.514, 58.143, 84.500, 113.961, 148.633, 185.059, 226.288 \
    19.052, 37.772, 59.125, 83.779, 114.942, 147.862, 183.674, 228.352 \
    19.386, 37.161, 60.049, 85.043, 114.669, 147.522, 184.661, 228.268 \
    19.433, 37.630, 59.589, 85.410, 115.677, 149.247, 186.269, 227.513 \
    19.151, 37.473, 60.148, 84.451, 114.448, 148.469, 186.010, 228.331 \
    19.188, 38.139, 59.113, 84.792, 114.127, 147.147, 186.128, 226.948 \
    18.810, 37.276, 57.609, 84.144, 113.760, 147.268, 184.999, 224.648 \
    19.047, 36.215, 57.709, 83.754, 113.414, 146.012, 183.213, 226.712 \
    18.334, 36.155, 56.317, 82.000, 111.022, 145.528, 183.468, 225.314 \
    17.886, 35.112, 55.102, 81.178, 109.589, 143.111, 179.543, 222.283)
  
  if (nr >= 1 & nr <= 8) {
    cv1_val = cv_br_all[break_frac_row, nr]
  }
  else {
    cv1_val = .
  }
  
  // SBC values for model selection
  real scalar SC0r, SC1r
  SC0r = -2 * loglp[r + 1, p0] + (n * n) * p0 * ln(T)
  SC1r = -2 * loglbp[brphat_ind, c1_sel + r] + (n + r + 2 + (n * n) * pbr) * ln(T)
  
  // Store results
  st_numscalar("_fjc_scvecm_tr0", tr0_val)
  st_numscalar("_fjc_scvecm_sc0", SC0r)
  st_numscalar("_fjc_scvecm_p0", p0)
  st_numscalar("_fjc_scvecm_cv0", cv0_val)
  st_numscalar("_fjc_scvecm_tr1", tr1_val)
  st_numscalar("_fjc_scvecm_sc1", SC1r)
  st_numscalar("_fjc_scvecm_p1", pbr)
  st_numscalar("_fjc_scvecm_cv1", cv1_val)
  st_numscalar("_fjc_scvecm_tb", bv[brphat_ind])
}

// _get_logL_vecm: VECM log-likelihood without break
// Faithful translation from GAUSS appl_SBCunion.gss
real colvector _scvecm_get_logL(real matrix y, real scalar p,
                                real scalar T, real scalar n)
{
  real matrix dy, z0, z1, z2
  real matrix r0, r1, Li
  real colvector lam, logL
  real scalar j, T_eff
  
  // dy = diff(y)
  dy = J(1, n, .) \ (y[2::T, .] - y[1::T-1, .])
  
  // z0 = trimr(dy, p, 0)
  z0 = dy[p+1::T, .]
  
  // z1 = [y(t-p), trend] => trimr(lagn(y,p) ~ trend, p, 0)
  real colvector tr
  tr = (1::T)
  real matrix ylag
  ylag = J(p, n, .) \ y[1::T-p, .]
  z1 = ylag[p+1::T, .], tr[p+1::T]
  
  // z2 = [constant, lagged dy]
  z2 = J(T, 1, 1)
  for (j = 1; j <= p - 1; j++) {
    real matrix dylag
    dylag = J(j, n, .) \ dy[1::T-j, .]
    z2 = z2, dylag
  }
  z2 = z2[p+1::T, .]
  
  T_eff = rows(z0)
  
  r0 = z0 - z2 * qrsolve(z2, z0)
  r1 = z1 - z2 * qrsolve(z2, z1)
  
  Li = luinv(cholesky(r1' * r1))
  real matrix eigM
  eigM = Li * r1' * r0 * invsym(r0' * r0) * r0' * r1 * Li'
  eigM = (eigM + eigM') / 2
  
  real matrix eigvecs
  real rowvector eigvals_raw
  eigensystem(eigM, eigvecs, eigvals_raw)
  real colvector eigvals
  eigvals = Re(eigvals_raw')
  real matrix idx
  idx = order(eigvals, -1)
  eigvals = eigvals[idx]
  
  // Clamp
  real scalar i
  for (i = 1; i <= rows(eigvals); i++) {
    if (eigvals[i] < 0) eigvals[i] = 0
    if (eigvals[i] >= 1) eigvals[i] = 0.9999
  }
  
  lam = 0 \ eigvals[1::n]
  
  logL = J(n + 1, 1, .)
  real scalar cumln
  cumln = 0
  for (i = 1; i <= n + 1; i++) {
    cumln = cumln + ln(1 - lam[i])
    logL[i] = -(T_eff) / 2 * (ln(det(r0' * r0 / T_eff)) + cumln)
  }
  
  return(logL)
}

// _get_logL_vecm_break: VECM log-likelihood with break at each candidate
real matrix _scvecm_get_logL_break(real matrix y, real scalar k,
                                   real colvector bv, real scalar T,
                                   real scalar n)
{
  real matrix dy, z0, z1, z2
  real matrix r0, r1, Li, D
  real colvector E1, E2, tr, lam
  real matrix tE, logL_all
  real scalar bc, b, j, T_eff, i
  
  tr = (1::T)
  dy = J(1, n, .) \ (y[2::T, .] - y[1::T-1, .])
  z0 = dy[k+1::T, .]
  
  logL_all = J(rows(bv), n + 1, .)
  
  for (bc = 1; bc <= rows(bv); bc++) {
    b = bv[bc]
    
    // Break dummies (impulse at b+1 .. b+k)
    D = J(T, 0, .)
    for (j = 1; j <= k; j++) {
      D = D, (tr :== (b + j))
    }
    
    // Segmented trends
    E1 = (tr :<= b)
    E2 = (tr :> b)
    tE = runningsum(E1), runningsum(E2)
    
    // z1 = [y(t-k), segmented trends]
    real matrix ylag_k
    ylag_k = J(k, n, .) \ y[1::T-k, .]
    z1 = ylag_k[k+1::T, .], tE[k+1::T, .]
    
    // z2 = [E1, E2, D, lagged dy]
    z2 = E1[k+1::T], E2[k+1::T], D[k+1::T, .]
    for (j = 1; j <= k - 1; j++) {
      real matrix dylag
      dylag = J(j, n, .) \ dy[1::T-j, .]
      z2 = z2, dylag[k+1::T, .]
    }
    
    T_eff = rows(z0)
    
    r0 = z0 - z2 * qrsolve(z2, z0)
    r1 = z1 - z2 * qrsolve(z2, z1)
    
    Li = luinv(cholesky(r1' * r1))
    real matrix eigM
    eigM = Li * r1' * r0 * invsym(r0' * r0) * r0' * r1 * Li'
    eigM = (eigM + eigM') / 2
    
    real matrix eigvecs
    real rowvector eigvals_raw
    eigensystem(eigM, eigvecs, eigvals_raw)
    real colvector eigvals
    eigvals = Re(eigvals_raw')
    real matrix idx
    idx = order(eigvals, -1)
    eigvals = eigvals[idx]
    
    for (i = 1; i <= rows(eigvals); i++) {
      if (eigvals[i] < 0) eigvals[i] = 0
      if (eigvals[i] >= 1) eigvals[i] = 0.9999
    }
    
    lam = 0 \ eigvals[1::n]
    
    real colvector logLb
    logLb = J(n + 1, 1, .)
    real scalar cumln
    cumln = 0
    for (i = 1; i <= n + 1; i++) {
      cumln = cumln + ln(1 - lam[i])
      logLb[i] = -(T_eff) / 2 * (ln(det(r0' * r0 / T_eff)) + cumln)
    }
    
    logL_all[bc, .] = logLb'
  }
  
  return(logL_all)
}
end
