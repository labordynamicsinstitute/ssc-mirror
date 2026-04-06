*! _xtpvarcoint_speci.ado — Specification Tools
*! Factor number criteria, lag & break selection
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

// ============================================================
// Factor number determination
// ============================================================
capture program drop _xpvc_speci
program define _xpvc_speci, rclass
  version 14.0
  
  gettoken what 0 : 0
  
  if "`what'" == "factors" {
    _xpvc_speci_factors `0'
  }
  else if "`what'" == "var" {
    _xpvc_speci_var `0'
  }
  else {
    di in red "unknown speci subcommand: `what'"
    di in red "use: {bf:xtpvarcoint speci factors} or {bf:xtpvarcoint speci var}"
    exit 198
  }
end

capture program drop _xpvc_speci_factors
program define _xpvc_speci_factors, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    [Kmax(integer 20) NITer(integer 4) ///
     DIFferenced CENtered SCAled NFActors(integer 0)]
  
  qui xtset
  local ivar "`r(panelvar)'"
  local tvar "`r(timevar)'"
  
  marksample touse
  
  local dim_K : word count `varlist'
  
  local do_diff = ("`differenced'" != "")
  local do_center = ("`centered'" != "")
  local do_scale = ("`scaled'" != "")
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint speci factors} — Number of Common Factors" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Max factors (k_max): " in ye "`kmax'"
  di in gr "  Differenced:         " in ye cond(`do_diff', "Yes", "No")
  di in gr "  Centered:            " in ye cond(`do_center', "Yes", "No")
  di in gr "  Scaled:              " in ye cond(`do_scale', "Yes", "No")
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_speci_factors_run("`varlist'", "`ivar'", "`touse'", ///
    `kmax', `niter', `do_diff', `do_center', `do_scale', `nfactors')
  
  return add
end

capture program drop _xpvc_speci_var
program define _xpvc_speci_var, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    LAGSet(numlist integer >0) ///
    [BREaks(integer 0) TRIm(real 0.15) ///
     BREAKType(string) ADDdummy]
  
  if "`breaktype'" == "" local breaktype "const"
  
  marksample touse
  local dim_K : word count `varlist'
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint speci var} — Lag & Break Selection" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Lag set:    " in ye "`lagset'"
  di in gr "  Breaks (m): " in ye "`breaks'"
  di in gr "  Trim:       " in ye "`trim'"
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_speci_var_run("`varlist'", "`touse'", ///
    "`lagset'", `breaks', `trim', "`breaktype'")
  
  return add
end

mata:
mata set matastrict off

// ============================================================
// Factor specification engine
// ============================================================

void _xpvc_speci_factors_run(string scalar varlist, string scalar ivar,
                              string scalar touse,
                              real scalar k_max, real scalar n_iter,
                              real scalar do_diff, real scalar do_center,
                              real scalar do_scale, real scalar n_factors)
{
  string rowvector vnames
  real colvector id_all, id_vals, sel, sel_eff, s, evals, V_k
  real scalar dim_N, dim_T, dim_K, i, j, k, T_i, ev_sum, cum_ev
  real scalar dim_T_eff, n_vals, C2_NT, dim_KN
  real scalar p1, p2, p3, ic1_min, ic2_min, ic3_min, ic1_k, ic2_k, ic3_k
  real scalar r_onc, r_ER, r_GR
  real matrix X, xit, xsd, U, Vt, IC_vals
  real rowvector sd_x
  real colvector v
  string scalar _hline50
  
  _hline50 = 50 * "-"
  
  vnames = tokens(varlist)
  dim_K = cols(vnames)
  
  st_view(id_all, ., ivar, touse)
  id_vals = uniqrows(id_all)
  dim_N = rows(id_vals)
  
  // Build data panel X (T x KN)
  // First pass: find common T
  dim_T = .
  for (i = 1; i <= dim_N; i++) {
    sel = selectindex(id_all :== id_vals[i])
    if (rows(sel) < dim_T | dim_T == .) dim_T = rows(sel)
  }
  
  X = J(dim_T, dim_K * dim_N, .)
  for (i = 1; i <= dim_N; i++) {
    sel = selectindex(id_all :== id_vals[i])
    T_i = rows(sel)
    // Take last dim_T observations
    sel_eff = sel[T_i-dim_T+1..T_i]
    
    for (j = 1; j <= dim_K; j++) {
      st_view(v, ., vnames[j], touse)
      X[., (i-1)*dim_K + j] = v[sel_eff]
    }
  }
  
  // Transform
  if (do_diff) {
    xit = X[2..dim_T, .] - X[1..dim_T-1, .]
  }
  else {
    xit = X
  }
  if (do_center) xit = xit :- mean(xit)
  if (do_scale) {
    sd_x = sqrt(diagonal(variance(xit)))'
    sd_x = sd_x + (sd_x :== 0)
    xsd = xit :/ sd_x
  }
  else {
    xsd = xit
  }
  
  // SVD - ensure matrix dimensions are valid
  dim_T_eff = rows(xsd)
  dim_KN = cols(xsd)
  
  // Guard: k_max must be less than min(T_eff, KN)
  real scalar max_sv, do_transpose
  max_sv = min((dim_T_eff, dim_KN))
  if (k_max >= max_sv) k_max = max_sv - 1
  if (k_max < 1) k_max = 1
  
  // Stata's svd() requires rows >= cols. Transpose if needed.
  do_transpose = (dim_T_eff < dim_KN)
  if (do_transpose) {
    real matrix xsd_t, U_t, Vt_t
    xsd_t = xsd'
    svd(xsd_t, U_t, s, Vt_t)
    // For xsd = U*diag(s)*Vt => xsd' = Vt'*diag(s)*U'
    // So U_t = Vt', s = s, Vt_t = U'
    U = Vt_t'   // recover original U (only first max_sv cols valid)
  }
  else {
    svd(xsd, U, s, Vt)
  }
  evals = s:^2 / (dim_T_eff)
  
  // Onatski — guard against insufficient eigenvalues
  real scalar k_max_onc
  k_max_onc = min((k_max, rows(evals) - 6))
  if (k_max_onc < 1) k_max_onc = 1
  r_onc = _xpvc_ONC(evals, k_max_onc, n_iter)
  
  // Ahn-Horenstein — guard
  real scalar k_max_ah
  k_max_ah = min((k_max, rows(evals) - 2))
  if (k_max_ah < 1) k_max_ah = 1
  _xpvc_AHC(evals, k_max_ah, r_ER, r_GR)
  
  // Bai-Ng IC
  V_k = J(k_max + 1, 1, .)
  ev_sum = sum(evals)
  cum_ev = 0
  for (k = 0; k <= k_max; k++) {
    V_k[k+1] = (ev_sum - cum_ev) / dim_KN
    if (k < rows(evals)) cum_ev = cum_ev + evals[k+1]
  }
  
  // IC penalties
  n_vals = dim_KN * dim_T_eff
  C2_NT = min((dim_KN, dim_T_eff))
  
  IC_vals = J(k_max + 1, 3, .)  // IC1, IC2, IC3
  for (k = 0; k <= k_max; k++) {
    p1 = (dim_KN + dim_T_eff) / n_vals * ln(n_vals / (dim_KN + dim_T_eff))
    p2 = (dim_KN + dim_T_eff) / n_vals * ln(C2_NT)
    p3 = ln(C2_NT) / C2_NT
    
    IC_vals[k+1, 1] = ln(V_k[k+1]) + k * p1
    IC_vals[k+1, 2] = ln(V_k[k+1]) + k * p2
    IC_vals[k+1, 3] = ln(V_k[k+1]) + k * p3
  }
  
  // Find minimizers
  ic1_min = .
  ic2_min = .
  ic3_min = .
  ic1_k = 0
  ic2_k = 0
  ic3_k = 0
  for (k = 0; k <= k_max; k++) {
    if (IC_vals[k+1, 1] < ic1_min | ic1_min == .) { 
      ic1_min = IC_vals[k+1, 1]
      ic1_k = k 
    }
    if (IC_vals[k+1, 2] < ic2_min | ic2_min == .) { 
      ic2_min = IC_vals[k+1, 2]
      ic2_k = k 
    }
    if (IC_vals[k+1, 3] < ic3_min | ic3_min == .) { 
      ic3_min = IC_vals[k+1, 3]
      ic3_k = k 
    }
  }
  
  // Display
  printf("  Eigenvalues (first %g):\n", min((10, rows(evals))))
  printf("%s\n", _hline50)
  printf("  %5s  %12s  %12s\n", "k", "Eigenvalue", "Share")
  printf("%s\n", _hline50)
  for (k = 1; k <= min((10, rows(evals))); k++) {
    printf("  %g  %g  %g\n", k, evals[k], evals[k]/ev_sum)
  }
  printf("%s\n\n", _hline50)
  
  printf("  Selection Criteria:\n")
  printf("%s\n", _hline50)
  printf("  %-20s  k* = %g\n", "Onatski ED", r_onc)
  printf("  %-20s  k* = %g\n", "Ahn-Horenstein ER", r_ER)
  printf("  %-20s  k* = %g\n", "Ahn-Horenstein GR", r_GR)
  printf("  %-20s  k* = %g\n", "Bai-Ng IC(p1)", ic1_k)
  printf("  %-20s  k* = %g\n", "Bai-Ng IC(p2)", ic2_k)
  printf("  %-20s  k* = %g\n", "Bai-Ng IC(p3)", ic3_k)
  printf("%s\n\n", _hline50)
  
  // Estimate factors if requested
  if (n_factors > 0) {
    real matrix evecs, ft, Ft, LAMBDA
    real scalar n_f_use
    n_f_use = min((n_factors, cols(U), rows(evals)))
    evecs = U[., 1..n_f_use]
    ft = sqrt(dim_T_eff) * evecs
    LAMBDA = xit' * ft / dim_T_eff
    
    if (do_diff) {
      real scalar t
      Ft = J(dim_T, n_f_use, 0)
      for (t = 2; t <= dim_T; t++) {
        Ft[t, .] = Ft[t-1, .] + ft[t-1, .]
      }
    }
    else {
      Ft = ft
    }
    
    printf("  Estimated %g common factors stored in r(Ft).\n", n_f_use)
    printf("  Factor loadings stored in r(LAMBDA).\n\n")
    
    st_matrix("_xpvc_Ft", Ft)
    st_matrix("_xpvc_LAMBDA", LAMBDA)
  }
  
  // Store
  st_rclear()
  st_numscalar("_xpvc_r_ONC", r_onc)
  st_numscalar("_xpvc_r_ER", r_ER)
  st_numscalar("_xpvc_r_GR", r_GR)
  st_numscalar("_xpvc_r_IC1", ic1_k)
  st_numscalar("_xpvc_r_IC2", ic2_k)
  st_numscalar("_xpvc_r_IC3", ic3_k)
  st_matrix("_xpvc_eigenvalues", evals[1..min((k_max+1, rows(evals)))]')
  st_matrix("_xpvc_IC", IC_vals)
  st_global("r(specifies)", "number of common factors")
}


// ============================================================
// VAR lag & break selection engine
// ============================================================

void _xpvc_speci_var_run(string scalar varlist, string scalar touse,
                          string scalar lagset_str, real scalar dim_m,
                          real scalar trim, string scalar breaktype)
{
  string rowvector vnames
  real colvector lag_set, v
  real scalar dim_K, dim_T, j, p, dim_T_eff, ip, lag_max
  real scalar aic, hqc, sic, fpe
  real scalar best_aic, best_hqc, best_sic, best_fpe
  real scalar p_aic, p_hqc, p_sic, p_fpe
  real matrix data, y, results, Y, Z, D_i, A_p, resid_p, OMEGA_p
  string scalar _hline60, _hline40
  
  _hline60 = 60 * "-"
  _hline40 = 40 * "-"
  
  vnames = tokens(varlist)
  dim_K = cols(vnames)
  lag_set = strtoreal(tokens(lagset_str))'
  
  // Load data
  data = J(0, dim_K, .)
  for (j = 1; j <= dim_K; j++) {
    st_view(v, ., vnames[j], touse)
    if (j == 1) data = J(rows(v), dim_K, .)
    data[., j] = v
  }
  y = data'
  dim_T = cols(y)
  
  lag_max = max(lag_set)
  
  // Results storage
  results = J(rows(lag_set), 5, .)  // p, AIC, HQC, SIC, FPE
  
  printf("  Information Criteria:\n")
  printf("%s\n", _hline60)
  printf("  %-4s  %-12s  %-12s  %-12s  %-12s\n", "p", "AIC", "HQC", "SIC", "FPE")
  printf("%s\n", _hline60)
  
  for (ip = 1; ip <= rows(lag_set); ip++) {
    p = lag_set[ip]
    dim_T_eff = dim_T - lag_max
    
    // Build Y and Z
    Y = y[., lag_max+1..dim_T]
    
    Z = J(0, dim_T_eff, .)
    for (j = 1; j <= p; j++) {
      Z = Z \ y[., lag_max+1-j..dim_T-j]
    }
    
    // Add constant
    D_i = J(1, dim_T_eff, 1)
    Z = D_i \ Z
    
    // OLS
    A_p = Y * Z' * invsym(Z * Z')
    resid_p = Y - A_p * Z
    OMEGA_p = resid_p * resid_p' / dim_T_eff
    
    // IC
    _xpvc_MIC(OMEGA_p, A_p, dim_T_eff, aic, hqc, sic, fpe)
    
    results[ip, .] = (p, aic, hqc, sic, fpe)
    printf("  %g  %g  %g  %g  %g\n", p, aic, hqc, sic, fpe)
  }
  
  printf("%s\n", _hline60)
  
  // Find optima
  best_aic = .
  best_hqc = .
  best_sic = .
  best_fpe = .
  p_aic = 1
  p_hqc = 1
  p_sic = 1
  p_fpe = 1
  
  for (ip = 1; ip <= rows(results); ip++) {
    if (results[ip, 2] < best_aic | best_aic == .) { 
      best_aic = results[ip, 2]
      p_aic = results[ip, 1] 
    }
    if (results[ip, 3] < best_hqc | best_hqc == .) { 
      best_hqc = results[ip, 3]
      p_hqc = results[ip, 1] 
    }
    if (results[ip, 4] < best_sic | best_sic == .) { 
      best_sic = results[ip, 4]
      p_sic = results[ip, 1] 
    }
    if (results[ip, 5] < best_fpe | best_fpe == .) { 
      best_fpe = results[ip, 5]
      p_fpe = results[ip, 1] 
    }
  }
  
  printf("\n  Optimal Lag Order:\n")
  printf("%s\n", _hline40)
  printf("  AIC:  p* = %g\n", p_aic)
  printf("  HQC:  p* = %g\n", p_hqc)
  printf("  SIC:  p* = %g\n", p_sic)
  printf("  FPE:  p* = %g\n", p_fpe)
  printf("%s\n\n", _hline40)
  
  // Store
  st_rclear()
  st_numscalar("_xpvc_p_aic", p_aic)
  st_numscalar("_xpvc_p_hqc", p_hqc)
  st_numscalar("_xpvc_p_sic", p_sic)
  st_numscalar("_xpvc_p_fpe", p_fpe)
  st_matrix("_xpvc_IC_table", results)
  st_global("r(specifies)", "lag-order")
}

end
