*! _xtpkpss_engine.ado
*! Engine subroutines for xtpkpss (Mata version)
*! Carrion-i-Silvestre, del Barrio-Castro & López-Bazo (2005)
*! Maps to: pd_kpss.src (GAUSS)
*!
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 2.0.0 — 26 March 2026 (Mata rewrite for performance)

mata:
mata clear

// LRV estimation (Bartlett kernel)
real scalar _kp_lrvar(real matrix u, real scalar bw) {
  real scalar T, s0, sl, j, w, Tj, gam
  
  T = rows(u)
  s0 = (u' * u)[1,1] / T
  sl = 0
  for (j=1; j<=bw; j++) {
    w = 1 - j/(bw+1)
    gam = (u[(j+1)..T]' * u[1..(T-j)])[1,1] / T
    sl = sl + 2 * w * gam
  }
  return(s0 + sl)
}

// Build deterministic matrix (GAUSS: __pd_dekpss)
real matrix _kp_determ(real scalar model, real scalar T, real matrix tb, real scalar nbr) {
  real matrix z, du, dt
  real scalar i
  
  if (model == 1) {
    z = J(T, 1, 1)
  }
  else if (model == 2) {
    z = J(T, 1, 1), (1::T)
  }
  else if (model == 3) {
    z = J(T, 1, 1)
    for (i=1; i<=nbr; i++) {
      du = J(tb[i], 1, 0) \ J(T - tb[i], 1, 1)
      z = z, du
    }
  }
  else if (model == 4) {
    z = J(T, 1, 1), (1::T)
    for (i=1; i<=nbr; i++) {
      du = J(tb[i], 1, 0) \ J(T - tb[i], 1, 1)
      dt = J(tb[i], 1, 0) \ (1::(T - tb[i]))
      z = z, du, dt
    }
  }
  return(z)
}

// Individual KPSS (GAUSS: __pd_kpss)
void _kp_individual(real matrix y, real scalar model,
                    real matrix tb, real scalar nbr, real scalar bw,
                    real scalar kpss_out, real scalar num_out, real scalar den_out) {
  real scalar T, lrv, num
  real matrix z, beta, e, St
  
  T = rows(y)
  z = _kp_determ(model, T, tb, nbr)
  beta = invsym(z' * z) * (z' * y)
  e = y - z * beta
  St = runningsum(e)
  lrv = _kp_lrvar(e, bw)
  num = (St' * St)[1,1] / T^2
  
  kpss_out = num / lrv
  num_out = num
  den_out = lrv
}

// Moments (GAUSS: __pd_calcdem)
void _kp_moments(real scalar model, real matrix tb, real scalar nbr, real scalar T,
                 real scalar mu_out, real scalar var_out) {
  real scalar A, B, k, nsegs
  real scalar prev_lam, lam_k, diff
  
  if (model == 1 | model == 3) {
    A = 1/6
    B = 1/45
  }
  else {
    A = 1/15
    B = 11/6300
  }
  
  nsegs = nbr + 1
  mu_out = 0
  var_out = 0
  prev_lam = 0
  
  for (k=1; k<=nsegs; k++) {
    if (k <= nbr) {
      lam_k = tb[k] / T
    }
    else {
      lam_k = 1
    }
    diff = lam_k - prev_lam
    mu_out = mu_out + A * diff^2
    var_out = var_out + B * diff^4
    prev_lam = lam_k
  }
}

// Break detection via BIC (simplified Bai-Perron)
void _kp_breaks(real matrix y, real matrix z, real scalar T,
                real scalar maxbrk, real scalar trimm,
                real scalar nbrk_out, real matrix brk_out) {
  real scalar seg, m, b, ssr, min_ssr, best_b
  real scalar bic0, bic_m, best_bic, ncol
  real matrix resid0, du, zb, rb
  real matrix curr_brk, best_brk
  real scalar kk, k, s1, s2
  
  seg = max((2, round(trimm * T)))
  
  // BIC for no-break model
  resid0 = y - z * invsym(z' * z) * (z' * y)
  bic0 = T * ln(sum(resid0:^2)/T) + cols(z) * ln(T)
  best_bic = bic0
  nbrk_out = 0
  best_brk = J(maxbrk, 1, 0)
  
  for (m=1; m<=maxbrk; m++) {
    curr_brk = J(m, 1, 0)
    
    if (m == 1) {
      // Grid search for single break
      min_ssr = .
      best_b = seg
      for (b=seg; b<=T-seg; b++) {
        du = J(b, 1, 0) \ J(T-b, 1, 1)
        zb = z, du
        rb = y - zb * invsym(zb' * zb) * (zb' * y)
        ssr = sum(rb:^2)
        if (ssr < min_ssr) {
          min_ssr = ssr
          best_b = b
        }
      }
      curr_brk[1] = best_b
    }
    else {
      // Initialize equally spaced
      for (k=1; k<=m; k++) {
        curr_brk[k] = round(seg + (k-1) * (T - 2*seg) / m)
      }
      
      // Refine each break
      for (k=1; k<=m; k++) {
        if (k == 1) {
          s1 = seg
        }
        else {
          s1 = curr_brk[k-1] + seg
        }
        if (k == m) {
          s2 = T - seg
        }
        else {
          s2 = curr_brk[k+1] - seg
        }
        
        min_ssr = .
        best_b = s1
        for (b=s1; b<=s2; b++) {
          curr_brk[k] = b
          zb = z
          for (kk=1; kk<=m; kk++) {
            du = J(curr_brk[kk], 1, 0) \ J(T - curr_brk[kk], 1, 1)
            zb = zb, du
          }
          rb = y - zb * invsym(zb' * zb) * (zb' * y)
          ssr = sum(rb:^2)
          if (ssr < min_ssr) {
            min_ssr = ssr
            best_b = b
          }
        }
        curr_brk[k] = best_b
      }
    }
    
    // BIC with m breaks (LWZ criterion)
    zb = z
    for (k=1; k<=m; k++) {
      du = J(curr_brk[k], 1, 0) \ J(T - curr_brk[k], 1, 1)
      zb = zb, du
    }
    rb = y - zb * invsym(zb' * zb) * (zb' * y)
    ncol = cols(zb)
    bic_m = T * ln(sum(rb:^2)/T) + ncol * 0.299 * ln(T)^2.1
    
    if (bic_m < best_bic) {
      best_bic = bic_m
      nbrk_out = m
      best_brk = J(maxbrk, 1, 0)
      for (k=1; k<=m; k++) {
        best_brk[k] = curr_brk[k]
      }
    }
  }
  
  brk_out = best_brk
}

// ---- Wrapper functions for single-line mata: calls from Stata ----

void _kp_mom_wrap(real scalar model, real matrix tb, real scalar nbr, real scalar T,
                  string scalar mu_name, string scalar var_name) {
  real scalar mu_v, var_v
  _kp_moments(model, tb, nbr, T, mu_v, var_v)
  st_numscalar(mu_name, mu_v)
  st_numscalar(var_name, var_v)
}

void _kp_brk_wrap(string scalar yname, string scalar zname,
                  real scalar T, real scalar maxbrk, real scalar trimm) {
  real scalar nbrk_v
  real matrix brk_v
  _kp_breaks(st_matrix(yname), st_matrix(zname), T, maxbrk, trimm, nbrk_v, brk_v)
  st_numscalar("__nbrk", nbrk_v)
  st_matrix("__brk", brk_v)
}

void _kp_ind_wrap(string scalar yname, real scalar model,
                  real matrix tb, real scalar nbr, real scalar bw,
                  string scalar kname, string scalar nname, string scalar dname) {
  real scalar kv, nv, dv
  _kp_individual(st_matrix(yname), model, tb, nbr, bw, kv, nv, dv)
  st_numscalar(kname, kv)
  st_numscalar(nname, nv)
  st_numscalar(dname, dv)
}

end

* ====================================================================
* Stata wrapper programs
* ====================================================================

capture program drop _kpss_deterministics
program define _kpss_deterministics, rclass
  args T model breakmat nbreaks
  * Not called directly anymore, but kept for compatibility
  tempname z
  if `nbreaks' == 0 {
    mata: st_matrix("`z'", _kp_determ(`model', `T', J(1,1,0), 0))
  }
  else {
    mata: st_matrix("`z'", _kp_determ(`model', `T', st_matrix("`breakmat'"), `nbreaks'))
  }
  return matrix result = `z'
end

capture program drop _kpss_moments
program define _kpss_moments, rclass
  args model breakmat nbreaks T
  
  tempname mu_s var_s
  if `nbreaks' == 0 {
    mata: _kp_mom_wrap(`model', J(1,1,0), 0, `T', "`mu_s'", "`var_s'")
  }
  else {
    mata: _kp_mom_wrap(`model', st_matrix("`breakmat'"), `nbreaks', `T', "`mu_s'", "`var_s'")
  }
  return scalar mu = `mu_s'
  return scalar var = `var_s'
end

capture program drop _kpss_breaks
program define _kpss_breaks, rclass
  args ymat zmat T maxbreaks trimm
  
  mata: _kp_brk_wrap("`ymat'", "`zmat'", `T', `maxbreaks', `trimm')
  
  return scalar nbreaks = __nbrk
  tempname br
  matrix `br' = __brk
  capture scalar drop __nbrk
  capture matrix drop __brk
  return matrix breaks = `br'
end

capture program drop _kpss_individual
program define _kpss_individual, rclass
  args ymat model breakmat nbreaks bw kernel
  
  tempname kpss_s num_s den_s
  if `nbreaks' == 0 {
    mata: _kp_ind_wrap("`ymat'", `model', J(1,1,0), 0, `bw', "`kpss_s'", "`num_s'", "`den_s'")
  }
  else {
    mata: _kp_ind_wrap("`ymat'", `model', st_matrix("`breakmat'"), `nbreaks', `bw', "`kpss_s'", "`num_s'", "`den_s'")
  }
  
  return scalar kpss = `kpss_s'
  return scalar num = `num_s'
  return scalar den = `den_s'
  return scalar lrv = `den_s'
end

capture program drop _kpss_panel_stats

program define _kpss_panel_stats, rclass
  args kpss_vec mu_vec var_vec num_vec den_vec N
  
  tempname kmat mumat vmat nmat dmat
  matrix `kmat' = `kpss_vec'
  matrix `mumat' = `mu_vec'
  matrix `vmat' = `var_vec'
  matrix `nmat' = `num_vec'
  matrix `dmat' = `den_vec'
  
  * Heterogeneous: mean of individual KPSS
  local lm_het = 0
  forvalues i = 1/`N' {
    local lm_het = `lm_het' + `kmat'[`i', 1]
  }
  local lm_het = `lm_het' / `N'
  
  * Homogeneous: meanc(num)/meanc(den)
  local num_bar = 0
  local den_bar = 0
  forvalues i = 1/`N' {
    local num_bar = `num_bar' + `nmat'[`i', 1]
    local den_bar = `den_bar' + `dmat'[`i', 1]
  }
  local lm_hom = (`num_bar'/`N') / (`den_bar'/`N')
  
  * Moments
  local mu_bar = 0
  local var_bar = 0
  forvalues i = 1/`N' {
    local mu_bar = `mu_bar' + `mumat'[`i', 1]
    local var_bar = `var_bar' + `vmat'[`i', 1]
  }
  local mu_bar = `mu_bar' / `N'
  local var_bar = `var_bar' / `N'
  
  local z_hom = sqrt(`N') * (`lm_hom' - `mu_bar') / sqrt(`var_bar')
  local z_het = sqrt(`N') * (`lm_het' - `mu_bar') / sqrt(`var_bar')
  
  return scalar z_hom = `z_hom'
  return scalar z_het = `z_het'
  return scalar lm_hom = `lm_hom'
  return scalar lm_het = `lm_het'
  return scalar mu_bar = `mu_bar'
  return scalar var_bar = `var_bar'
end
