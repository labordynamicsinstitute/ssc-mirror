*! _xtpcointegboot_engine.ado
*! Engine subroutines for xtpcointegboot (Mata version)
*! Westerlund & Edgerton (2007, Economics Letters)
*! Maps to: cointboot.src (GAUSS)
*!
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 3.0.0 — 26 March 2026 (No void output params)

* ====================================================================
* _boot_moments: Adjustment moments (stays in Stata — tiny function)
* GAUSS: mom_cointboot(mod, k) — lines 174-186
* ====================================================================
capture program drop _boot_moments
program define _boot_moments, rclass
  args mod k
  
  if `mod' == 1 {
    if `k' == 1 {
      local mu = 0.11601
      local vr = 0.01151
    }
    else if `k' == 2 {
      local mu = 0.08464
      local vr = 0.00559
    }
    else if `k' == 3 {
      local mu = 0.06539
      local vr = 0.00266
    }
    else if `k' == 4 {
      local mu = 0.05295
      local vr = 0.00144
    }
    else {
      local mu = 0.04442
      local vr = 0.00086
    }
  }
  else if `mod' == 2 {
    if `k' == 1 {
      local mu = 0.05530
      local vr = 0.00115
    }
    else if `k' == 2 {
      local mu = 0.04686
      local vr = 0.00078
    }
    else if `k' == 3 {
      local mu = 0.04063
      local vr = 0.00056
    }
    else if `k' == 4 {
      local mu = 0.03532
      local vr = 0.00036
    }
    else {
      local mu = 0.03133
      local vr = 0.00027
    }
  }
  
  return scalar mu = `mu'
  return scalar vr = `vr'
end

* ====================================================================
* All heavy computation in Mata — NO void output params
* ====================================================================

mata:
mata clear

// Fejer kernel — returns SCALAR for col vector
real scalar _mt_fejer_s(real colvector uv, real scalar k) {
  real scalar TT, i, a
  TT = rows(uv)
  if (k == 0) return(0)
  a = 0
  for (i=1; i<=k; i++) a = a + (1-i/(k+1)) * cross(uv[(i+1)..TT], uv[1..(TT-i)])
  return(a / TT)
}

// Fejer kernel — returns MATRIX for multi-column
real matrix _mt_fejer_m(real matrix uv, real scalar k) {
  real scalar TT, i
  real matrix a
  TT = rows(uv)
  if (k == 0) return(J(cols(uv), cols(uv), 0))
  a = J(cols(uv), cols(uv), 0)
  for (i=1; i<=k; i++) a = a + (1-i/(k+1)) * (uv[(i+1)..TT,.]' * uv[1..(TT-i),.])
  return(a / TT)
}

// FM-OLS — stores results in external (package-level) variables
// _mt_fm_coef and _mt_fm_resid are created via 'external' inside functions

void _mt_do_fm(real colvector y, real matrix x, real scalar mod, real scalar q) {
  external real matrix _mt_fm_coef, _mt_fm_resid
  real scalar TT, K, Tm1
  real matrix w, b, u, dx, e, vl, v0, s, d_mat
  real matrix s22, s21, d21, d22, d_top, d_adj, s22inv_s21
  real matrix y_adj, w_adj

  TT = rows(y); K = cols(x)
  if (mod == 1) w = x, J(TT, 1, 1)
  else w = x, J(TT, 1, 1), (1::TT)

  b = invsym(w'*w) * (w'*y)
  u = y - w*b
  Tm1 = TT - 1
  dx = x[2..TT,.] - x[1..Tm1,.]
  e = u[2..TT], dx
  vl = _mt_fejer_m(e, q)
  v0 = (e'*e) / Tm1
  s = v0 + vl + vl'
  d_mat = v0 + vl'

  s22 = s[2..(K+1), 2..(K+1)]
  s21 = s[2..(K+1), 1]
  d21 = d_mat[2..(K+1), 1]
  d22 = d_mat[2..(K+1), 2..(K+1)]
  d_top = d21 - d22 * invsym(s22) * s21
  d_adj = TT * (d_top \ J(cols(w)-K, 1, 0))

  s22inv_s21 = invsym(s22) * s21
  y_adj = y[2..TT] - dx * s22inv_s21
  w_adj = w[2..TT, .]
  b = invsym(w_adj'*w_adj) * ((w_adj'*y_adj) - d_adj)
  u = y_adj - w_adj*b

  _mt_fm_coef = b
  _mt_fm_resid = u
}

// LM statistic — RETURNS scalar directly
real scalar _mt_lm(real colvector y, real matrix x, real scalar mod, real scalar q) {
  real scalar TT, K, Tm1, s_val
  real matrix w, b, u, dx, e, vl, v0, s, d_mat
  real matrix s22, s21, d21, d22, d_top, d_adj, s22inv_s21
  real matrix y_adj, w_adj, v0_u, vl_u, s_u
  real colvector cu

  TT = rows(y); K = cols(x)
  if (mod == 1) w = x, J(TT, 1, 1)
  else w = x, J(TT, 1, 1), (1::TT)

  b = invsym(w'*w) * (w'*y)
  u = y - w*b
  Tm1 = TT - 1
  dx = x[2..TT,.] - x[1..Tm1,.]
  e = u[2..TT], dx
  vl = _mt_fejer_m(e, q)
  v0 = (e'*e) / Tm1
  s = v0 + vl + vl'
  d_mat = v0 + vl'

  s22 = s[2..(K+1), 2..(K+1)]
  s21 = s[2..(K+1), 1]
  d21 = d_mat[2..(K+1), 1]
  d22 = d_mat[2..(K+1), 2..(K+1)]
  d_top = d21 - d22 * invsym(s22) * s21
  d_adj = TT * (d_top \ J(cols(w)-K, 1, 0))

  s22inv_s21 = invsym(s22) * s21
  y_adj = y[2..TT] - dx * s22inv_s21
  w_adj = w[2..TT, .]
  b = invsym(w_adj'*w_adj) * ((w_adj'*y_adj) - d_adj)
  u = y_adj - w_adj*b

  // LRV of residuals
  s_val = cross(u,u)/TT + 2*_mt_fejer_s(u, K)

  cu = runningsum(u)
  return(sum(cu:^2) / (TT^2 * s_val))
}

// Yule-Walker — stores results in external (package-level) variables
// _mt_yw_coef and _mt_yw_resid are created via 'external' inside functions

void _mt_do_yw(real matrix x_in, real scalar p) {
  external real matrix _mt_yw_coef, _mt_yw_resid
  real scalar TT, j
  real matrix x, x0, xl

  TT = rows(x_in)
  x = x_in :- mean(x_in)
  x0 = x[(p+1)..TT, .]
  xl = x[p..(TT-1), .]
  for (j=2; j<=p; j++) xl = xl, x[(p+1-j)..(TT-j), .]

  _mt_yw_coef = invsym(xl'*xl) * (xl'*x0)
  _mt_yw_resid = x0 - xl * _mt_yw_coef
}

// AR filter (GAUSS: pfilter) — RETURNS result
real matrix _mt_pfilter(real matrix x, real matrix rho, real scalar p) {
  real scalar TT, N, i, j
  real matrix y
  TT = rows(x); N = cols(x)
  y = J(TT+p, N, 0)
  for (i=p+1; i<=TT+p; i++) {
    y[i, .] = x[i-p, .]
    for (j=1; j<=p; j++) y[i,.] = y[i,.] + y[i-j,.] * rho[((j-1)*N+1)..(j*N), .]
  }
  return(y[(p+1)..(TT+p), .])
}

// Main bootstrap procedure
void _mt_boot_panel(string scalar yname, string scalar xname,
                    real scalar mod, real scalar est,
                    real scalar nboot, real scalar q,
                    real scalar mu_in, real scalar vr_in) {
  external real matrix _mt_fm_coef, _mt_fm_resid
  external real matrix _mt_yw_coef, _mt_yw_resid
  real scalar N, TT, K, Kp1, Tm1, i, j
  real matrix Y, X, yi, xi, wi, dxi
  real matrix b_all, p_all, u_all, indiv_lm
  real scalar mu, vr, l_sum, Tu, lm_i, lmn
  real matrix boot_dist, h, e_boot, rho_i, e_filt
  real matrix e_dx, xb, wb, yb

  Y = st_matrix(yname); X = st_matrix(xname)
  N = cols(Y); TT = rows(Y); K = cols(X)/N; Kp1 = K+1; Tm1 = TT-1
  mu = mu_in; vr = vr_in

  // Step 1: FM-OLS + VAR for each unit
  b_all = J(mod+K, N, 0)
  p_all = J(Kp1*q, Kp1*N, 0)
  u_all = J(Tm1-q, Kp1*N, 0)
  indiv_lm = J(N, 1, 0)
  l_sum = 0

  for (i=1; i<=N; i++) {
    yi = Y[.,i]; xi = X[., ((i-1)*K+1)..(i*K)]

    _mt_do_fm(yi, xi, mod, q)
    b_all[.,i] = _mt_fm_coef
    
    lm_i = _mt_lm(yi, xi, mod, q)
    indiv_lm[i] = lm_i; l_sum = l_sum + lm_i

    dxi = xi[2..TT,.] - xi[1..Tm1,.]
    wi = _mt_fm_resid, dxi

    _mt_do_yw(wi, q)
    p_all[., ((i-1)*Kp1+1)..(i*Kp1)] = _mt_yw_coef
    u_all[., ((i-1)*Kp1+1)..(i*Kp1)] = _mt_yw_resid
  }

  st_matrix("__indiv_lm", indiv_lm)
  lmn = sqrt(N) * (l_sum/N - mu) / sqrt(vr)
  st_numscalar("__lmn", lmn)

  // Step 2: Bootstrap
  boot_dist = J(nboot, 1, 0)
  Tu = rows(u_all)

  for (j=1; j<=nboot; j++) {
    l_sum = 0
    h = ceil(uniform(TT, 1) * Tu)
    h = rowmax((h, J(TT, 1, 1)))
    h = rowmin((h, J(TT, 1, Tu)))

    for (i=1; i<=N; i++) {
      e_boot = u_all[h[.,1], ((i-1)*Kp1+1)..(i*Kp1)]
      e_boot = e_boot :- mean(e_boot)

      rho_i = p_all[., ((i-1)*Kp1+1)..(i*Kp1)]
      e_filt = _mt_pfilter(e_boot, rho_i, q)

      e_dx = e_filt[., 2..Kp1]
      xb = _mt_pfilter(e_dx, I(K), 1)

      if (mod == 1) wb = xb, J(TT, 1, 1)
      else wb = xb, J(TT, 1, 1), (1::TT)

      yb = wb * b_all[.,i] + e_filt[.,1]
      l_sum = l_sum + _mt_lm(yb, xb[., 1..K], mod, q)
    }
    boot_dist[j] = sqrt(N) * (l_sum/N - mu) / sqrt(vr)
  }

  _sort(boot_dist, 1)
  st_matrix("__boot_dist", boot_dist)
}

end

* Stata wrappers
capture program drop _boot_run
program define _boot_run, rclass
  args ymat xmat mod est nboot q mu vr
  mata: _mt_boot_panel("`ymat'", "`xmat'", `mod', `est', `nboot', `q', `mu', `vr')
  tempname bd
  matrix `bd' = __boot_dist
  capture matrix drop __boot_dist
  return matrix bootdist = `bd'
end
