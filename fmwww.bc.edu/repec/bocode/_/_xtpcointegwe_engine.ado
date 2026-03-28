*! _xtpcointegwe_engine.ado
*! Engine subroutines for xtpcointegwe (Mata version)
*! Westerlund & Edgerton (2008, OBES) panel cointegration test
*! Maps to: pd_coint_wedgerton (1).src (GAUSS)
*!
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 3.0.0 — 26 March 2026 (No void output params)

mata:
mata clear

// ====================================================================
// Fejer kernel — SCALAR for single-column input
// ====================================================================
real scalar _we_fejer_s(real colvector uv, real scalar k) {
  real scalar TT, i, a
  TT = rows(uv)
  if (k == 0) return(0)
  a = 0
  for (i=1; i<=k; i++) {
    a = a + (1 - i/(k+1)) * cross(uv[(i+1)..TT], uv[1..(TT-i)])
  }
  return(a / TT)
}

// ====================================================================
// Long-run variance — SCALAR for column vector input
// ====================================================================
real scalar _we_lrvar_s(real colvector u, real scalar k) {
  real scalar s0, sl
  s0 = cross(u, u) / rows(u)
  sl = _we_fejer_s(u, k)
  return(s0 + 2*sl)
}

// ====================================================================
// Build dummy (GAUSS: __pd_coint_dum)
// ====================================================================
real matrix _we_dum(real colvector x, real scalar br, real scalar model) {
  real scalar TT
  real colvector d
  real matrix z
  TT = rows(x)
  z = (1::TT)
  if (br != 0) {
    d = (J(br, 1, 0) \ J(TT-br, 1, 1))
    if (model == 1) z = z, d
    else if (model == 2) z = z, d, (d :* x)
  }
  return(z)
}

// ====================================================================
// SSR for break search
// ====================================================================
real scalar _we_ssr(real colvector y, real colvector x,
                    real scalar br, real scalar model) {
  real matrix z, dz, dx
  real colvector dy, u
  real scalar TT
  TT = rows(y)
  z = _we_dum(x, br, model)
  dz = z[2..TT, .] - z[1..(TT-1), .]
  dx = (x[2..TT] - x[1..(TT-1)]), dz
  dy = y[2..TT] - y[1..(TT-1)]
  u = dy - dx * (invsym(cross(dx,dx)) * cross(dx,dy))
  return(cross(u,u))
}

// ====================================================================
// Find breaks
// ====================================================================
real colvector _we_find_breaks(real matrix YY, real matrix XX,
                               real scalar trimm, real scalar model) {
  real scalar TT, NN, i, j, t1, t2, min_ssr, this_ssr, min_br
  real colvector br
  TT = rows(YY); NN = cols(YY)
  br = J(NN, 1, 0)
  t1 = round(trimm * TT); t2 = round((1 - trimm) * TT)
  for (i=1; i<=NN; i++) {
    min_ssr = .; min_br = t1
    for (j=t1; j<=t2; j++) {
      this_ssr = _we_ssr(YY[.,i], XX[.,i], j, model)
      if (this_ssr < min_ssr) { min_ssr = this_ssr; min_br = j; }
    }
    br[i] = min_br
  }
  return(br)
}

// ====================================================================
// Principal components — returns fl = f * lam' DIRECTLY (no output params!)
// Uses eigensystem with return values to avoid void param issues
// ====================================================================
real matrix _we_get_fl(real matrix e, real scalar nf) {
  real scalar TT, NN
  real matrix V, f_mat, l_mat
  real vector d

  TT = rows(e); NN = cols(e)

  if (NN > TT) {
    eigensystem(e * e', V, d)
    V = Re(V)
    f_mat = V[., 1..nf] * sqrt(TT)
    l_mat = cross(e', f_mat) / TT
  }
  else {
    eigensystem(cross(e, e), V, d)
    V = Re(V)
    l_mat = V[., 1..nf] * sqrt(NN)
    f_mat = (e * l_mat) / NN
  }
  return(f_mat * l_mat')
}

// ====================================================================
// Factor selection (Bai-Ng IC)
// ====================================================================
real scalar _we_select_factors(real matrix e, real scalar maxf) {
  real scalar TT, NN, k, minNT, s, pen, ic, min_ic, best_k
  real matrix uk, fl

  TT = rows(e); NN = cols(e)
  min_ic = .; best_k = 1

  for (k=1; k<=maxf; k++) {
    fl = _we_get_fl(e, k)
    uk = e - fl
    s = sum(uk :^ 2) / (NN * TT)
    minNT = min((NN, TT))
    pen = (NN + TT) / (NN * TT) * ln(minNT)
    ic = ln(s) + k * pen
    if (ic < min_ic) { min_ic = ic; best_k = k; }
  }
  return(best_k)
}

// ====================================================================
// Build lag matrix
// ====================================================================
real matrix _we_lagp(real colvector x, real scalar p) {
  real scalar TT, j
  real matrix xl
  TT = rows(x)
  xl = x[p..(TT-1), .]
  for (j=2; j<=p; j++) xl = xl, x[(p+1-j)..(TT-j), .]
  return(xl)
}

// ====================================================================
// Main computation (GAUSS: __pd_coint_wedgerton_fact)
// ====================================================================
void _we_compute(string scalar yname, string scalar xname,
                 string scalar brname,
                 real scalar p, real scalar q,
                 real scalar model, real scalar maxf) {
  real scalar TT, NN, Tm1, i, nf, Teff
  real matrix YY, XX, de, de_full, fl, f_cumul
  real colvector br, yi, xi, dyi, d_coef, s0, ds, ds_trim, uu
  real matrix zi, dzi, dxi_full, sl_mat, dd, v_diag
  real scalar zt_sum, za_sum, v0_s, vl_s, se1, alpha0

  YY = st_matrix(yname)
  XX = st_matrix(xname)
  br = st_matrix(brname)[., 1]
  TT = rows(YY); NN = cols(YY); Tm1 = TT - 1

  // Step 1: First-diff residuals
  de = J(Tm1, NN, 0)
  for (i=1; i<=NN; i++) {
    xi = XX[.,i]; yi = YY[.,i]
    zi = _we_dum(xi, br[i], model)
    dzi = zi[2..TT, .] - zi[1..Tm1, .]
    dyi = yi[2..TT, .] - yi[1..Tm1, .]
    dxi_full = (xi[2..TT, .] - xi[1..Tm1, .]), dzi
    de[.,i] = dyi - dxi_full * (invsym(cross(dxi_full,dxi_full)) * cross(dxi_full,dyi))
  }

  // Step 2: Factors
  de_full = J(1, NN, 0) \ de
  nf = 0
  f_cumul = J(TT, NN, 0)
  if (maxf > 0) {
    nf = _we_select_factors(de_full, maxf)
    fl = _we_get_fl(de_full, nf)
    for (i=1; i<=NN; i++) f_cumul[.,i] = runningsum(fl[.,i])
  }

  // Step 3: Individual Zt/Za
  zt_sum = 0; za_sum = 0
  for (i=1; i<=NN; i++) {
    yi = YY[.,i]; xi = XX[.,i]
    zi = _we_dum(xi, br[i], model)
    dzi = zi[2..TT, .] - zi[1..Tm1, .]
    dxi_full = (xi[2..TT, .] - xi[1..Tm1, .]), dzi
    dyi = yi[2..TT, .] - yi[1..Tm1, .]
    d_coef = invsym(cross(dxi_full,dxi_full)) * cross(dxi_full,dyi)

    // s0 = y - (y[1] - (x[1]~z[1])*d) - (x~z)*d - f
    alpha0 = yi[1,1] - cross((xi[1,.], zi[1,.])', d_coef)
    s0 = (yi :- alpha0) - (xi, zi) * d_coef - f_cumul[.,i]

    ds = s0[2..TT, .] - s0[1..Tm1, .]

    if (p > 0) {
      sl_mat = s0[(p+1)..(TT-1), .], _we_lagp(ds, p), dzi[(p+1)..Tm1, 1]
      ds_trim = ds[(p+1)..Tm1, .]
    }
    else {
      sl_mat = s0[1..Tm1, .], dzi[., 1]
      ds_trim = ds
    }

    dd = invsym(cross(sl_mat,sl_mat)) * cross(sl_mat, ds_trim)
    uu = ds_trim - sl_mat * dd

    v0_s = _we_lrvar_s(uu, 0)
    vl_s = _we_lrvar_s(ds_trim, q)
    v_diag = v0_s * invsym(cross(sl_mat,sl_mat))
    se1 = sqrt(v_diag[1,1])

    zt_sum = zt_sum + dd[1,1] / se1
    za_sum = za_sum + (TT - p - 1) * dd[1,1] * sqrt(vl_s / v0_s)
  }

  // Step 4: Normalize
  st_numscalar("__zt", sqrt(NN) * (zt_sum/NN + 1.9675) / sqrt(0.3301))
  st_numscalar("__za", sqrt(NN) * (za_sum/NN + 8.4376) / sqrt(25.8964))
  st_numscalar("__nf", nf)
}

end

* Stata wrappers
capture program drop _we_find_breaks
program define _we_find_breaks, rclass
  args ymat xmat trimm model npanels
  mata: st_matrix("__breaks", _we_find_breaks(st_matrix("`ymat'"), st_matrix("`xmat'"), `trimm', `model'))
  tempname br
  matrix `br' = __breaks
  capture matrix drop __breaks
  return matrix breaks = `br'
end

capture program drop _we_compute_test
program define _we_compute_test, rclass
  args ymat xmat brmat p q model maxf
  mata: _we_compute("`ymat'", "`xmat'", "`brmat'", `p', `q', `model', `maxf')
  return scalar zt = __zt
  return scalar za = __za
  return scalar nfactors = __nf
  capture scalar drop __zt
  capture scalar drop __za
  capture scalar drop __nf
end
