*! _xtpvarcoint_pvar.ado — Panel VAR/VECM Estimation
*! MG of VAR, PMG of VECM, individual VECM
*! Version 1.0.1 — 05 April 2026
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

// ============================================================
// Panel VAR (Mean Group)
// ============================================================
capture program drop _xpvc_pvar
program define _xpvc_pvar, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    Lags(numlist integer >0) ///
    [Type(string) NFActors(integer 0) NITer(integer 0) ///
     TSHift(numlist) EXog(varlist ts)]
  
  if "`type'" == "" local type "const"
  
  qui xtset
  local ivar "`r(panelvar)'"
  local tvar "`r(timevar)'"
  if "`ivar'" == "" {
    di in red "panel variable not set; use {bf:xtset} first"
    exit 459
  }
  
  marksample touse
  
  tempvar g
  qui egen `g' = group(`ivar') if `touse'
  qui sum `g', meanonly
  local dim_N = r(max)
  local dim_K : word count `varlist'
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint pvar} — Panel VAR Estimation (Mean Group)" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Deterministic: " in ye "`type'"
  di in gr "  Variables (K): " in ye "`dim_K'"
  di in gr "  Individuals:   " in ye "`dim_N'"
  if `nfactors' > 0 {
    di in gr "  Common factors: " in ye "`nfactors'"
    di in gr "  Iterations:     " in ye "`niter'"
  }
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_pvar_run("`varlist'", "`ivar'", "`tvar'", "`touse'", ///
    "`type'", `dim_N', `dim_K', `nfactors', `niter', "`lags'")
  
  return add
end

// ============================================================
// Panel VECM (Pooled Mean Group)
// ============================================================
capture program drop _xpvc_pvec
program define _xpvc_pvec, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    Lags(numlist integer >0) Rank(integer) ///
    [Type(string) POol(numlist integer) ///
     NFActors(integer 0) NITer(integer 0) ///
     TBReak(numlist) TSHift(numlist)]
  
  if "`type'" == "" local type "Case3"
  
  qui xtset
  local ivar "`r(panelvar)'"
  local tvar "`r(timevar)'"
  if "`ivar'" == "" {
    di in red "panel variable not set; use {bf:xtset} first"
    exit 459
  }
  
  marksample touse
  
  tempvar g
  qui egen `g' = group(`ivar') if `touse'
  qui sum `g', meanonly
  local dim_N = r(max)
  local dim_K : word count `varlist'
  
  di
  di in smcl in gr "{hline 78}"
  if "`pool'" != "" {
    di in gr "{bf:xtpvarcoint pvec} — Panel VECM (Pooled Mean Group)" ///
      _col(60) in ye "v1.0.0"
  }
  else {
    di in gr "{bf:xtpvarcoint pvec} — Panel VECM (Mean Group)" ///
      _col(60) in ye "v1.0.0"
  }
  di in smcl in gr "{hline 78}"
  di in gr "  Deterministic:   " in ye "`type'"
  di in gr "  Variables (K):   " in ye "`dim_K'"
  di in gr "  Individuals (N): " in ye "`dim_N'"
  di in gr "  Coint. rank (r): " in ye "`rank'"
  if "`pool'" != "" {
    di in gr "  Pooled indices:  " in ye "`pool'"
  }
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_pvec_run("`varlist'", "`ivar'", "`tvar'", "`touse'", ///
    "`type'", `dim_N', `dim_K', `rank', `nfactors', `niter', ///
    "`lags'", "`pool'")
  
  return add
end

// ============================================================
// Individual VECM
// ============================================================
capture program drop _xpvc_vecm
program define _xpvc_vecm, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    Lags(integer) [Rank(integer 0) Type(string) ///
    EXog(varlist ts) EXlags(integer 0)]
  
  if "`type'" == "" local type "Case3"
  
  marksample touse
  local dim_K : word count `varlist'
  
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint vecm} — VECM Estimation" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Deterministic:   " in ye "`type'"
  di in gr "  Variables (K):   " in ye "`dim_K'"
  di in gr "  Lag order (p):   " in ye "`lags'"
  di in gr "  Coint. rank (r): " in ye "`rank'"
  di in smcl in gr "{hline 78}"
  di
  
  mata: _xpvc_vecm_run("`varlist'", "`touse'", "`type'", ///
    `lags', `dim_K', `rank')
  
  return add
end

mata:
mata set matastrict off

// ============================================================
// Panel VAR estimation engine
// ============================================================

void _xpvc_pvar_run(string scalar varlist, string scalar ivar,
                     string scalar tvar, string scalar touse,
                     string scalar type, real scalar dim_N,
                     real scalar dim_K, real scalar n_factors,
                     real scalar n_iter, string scalar lags_str)
{
  string rowvector vnames
  real colvector id_all, id_vals, lags_vec
  real scalar i, j, dim_T_i, lag_i
  pointer(real matrix) colvector L_A, L_SIGMA, L_resid
  real matrix A_mg, A_var, data_i, y_i
  string scalar _hline78
  
  _hline78 = 78 * "-"
  
  vnames = tokens(varlist)
  st_view(id_all, ., ivar, touse)
  id_vals = uniqrows(id_all)
  
  lags_vec = strtoreal(tokens(lags_str))'
  if (rows(lags_vec) == 1) lags_vec = J(dim_N, 1, lags_vec)
  
  L_A = J(dim_N, 1, NULL)
  L_SIGMA = J(dim_N, 1, NULL)
  L_resid = J(dim_N, 1, NULL)
  
  real scalar max_p
  max_p = max(lags_vec)
  
  printf("  Estimating individual VAR models...\n\n")
  
  for (i = 1; i <= dim_N; i++) {
    real colvector sel
    sel = selectindex(id_all :== id_vals[i])
    
    data_i = J(rows(sel), dim_K, .)
    for (j = 1; j <= dim_K; j++) {
      real colvector v
      st_view(v, ., vnames[j], touse)
      data_i[., j] = v[sel]
    }
    
    y_i = data_i'  // K x T
    dim_T_i = cols(y_i)
    lag_i = lags_vec[i]
    
    // Build Z = [D; y_{t-1}; ...; y_{t-p}]
    real matrix Y, Z, D_i
    real scalar dim_T_eff
    
    dim_T_eff = dim_T_i - lag_i
    Y = y_i[., lag_i+1..dim_T_i]
    
    // Stack lags
    Z = J(0, dim_T_eff, .)
    for (j = 1; j <= lag_i; j++) {
      Z = Z \ y_i[., lag_i+1-j..dim_T_i-j]
    }
    
    // Add deterministic
    D_i = _xpvc_dummy(dim_T_i, type)
    if (rows(D_i) > 0) {
      Z = D_i[., lag_i+1..dim_T_i] \ Z
    }
    
    // OLS: A = Y * Z' * (Z*Z')^{-1}
    real matrix A_i, resid_i, OMEGA_i, SIGMA_i
    A_i = Y * Z' * invsym(Z * Z')
    resid_i = Y - A_i * Z
    OMEGA_i = resid_i * resid_i' / dim_T_eff
    SIGMA_i = resid_i * resid_i' / (dim_T_eff - cols(A_i))
    
    // Store coefficient matrices (only lagged endogenous part)
    real scalar n_det
    n_det = rows(D_i)
    
    // Pad to common max_p
    real matrix A_pad
    A_pad = J(dim_K, dim_K * max_p, 0)
    if (n_det > 0) {
      A_pad[., 1..dim_K * lag_i] = A_i[., n_det+1..cols(A_i)]
    }
    else {
      A_pad[., 1..dim_K * lag_i] = A_i
    }
    
    L_A[i] = &A_pad
    L_SIGMA[i] = &SIGMA_i
    L_resid[i] = &resid_i
    
    printf("  Unit %g: T=%g, p=%g, det(Sigma)=%g\n", ///
      i, dim_T_eff, lag_i, det(SIGMA_i))
  }
  
  // Mean-group estimation
  _xpvc_MG(L_A, dim_N, A_mg, A_var)
  
  printf("\n  Mean-Group VAR Coefficients:\n")
  printf("%s\n", _hline78)
  
  // Display A matrices
  for (j = 1; j <= max_p; j++) {
    printf("  A_%g:\n", j)
    real matrix Aj
    Aj = A_mg[., (j-1)*dim_K+1..j*dim_K]
    for (k = 1; k <= dim_K; k++) {
      printf("  ")
      for (l = 1; l <= dim_K; l++) {
        printf("  %g", Aj[k, l])
      }
      printf("\n")
    }
    printf("\n")
  }
  
  // Stability check
  real matrix C_comp
  C_comp = _xpvc_companion(A_mg, max_p)
  real colvector eig_vals
  real matrix eig_vecs
  eigensystem(C_comp, eig_vecs, eig_vals)
  real colvector mod_eig
  mod_eig = abs(eig_vals)'  // transpose to column vector
  
  printf("  Companion Matrix Eigenvalues (moduli):\n  ")
  for (j = 1; j <= min((rows(mod_eig), 10)); j++) {
    printf("%g ", mod_eig[j])
  }
  printf("\n")
  
  if (max(mod_eig) >= 1) {
    printf("  WARNING: VAR is NOT stable (max modulus >= 1).\n")
  }
  else {
    printf("  VAR is stable (max modulus = %g).\n", max(mod_eig))
  }
  printf("%s\n\n", _hline78)
  
  // Store results
  st_rclear()
  st_numscalar("_xpvc_N", dim_N)
  st_numscalar("_xpvc_K", dim_K)
  st_numscalar("_xpvc_max_p", max_p)
  st_matrix("_xpvc_A", A_mg)
  st_matrix("_xpvc_A_var", A_var)
  st_numscalar("_xpvc_max_eigenmod", max(mod_eig))
  st_global("r(method)", "MG of VAR")
  st_global("r(type)", type)
}


// ============================================================
// Panel VECM estimation engine
// ============================================================

void _xpvc_pvec_run(string scalar varlist, string scalar ivar,
                     string scalar tvar, string scalar touse,
                     string scalar type, real scalar dim_N,
                     real scalar dim_K, real scalar dim_r,
                     real scalar n_factors, real scalar n_iter,
                     string scalar lags_str, string scalar pool_str)
{
  string rowvector vnames
  real colvector id_all, id_vals, lags_vec
  real scalar i, j, lag_i
  pointer(real matrix) colvector L_alpha, L_beta, L_GAMMA, L_SIGMA
  real matrix data_i, y_i
  string scalar _hline60
  
  _hline60 = 60 * "-"
  
  vnames = tokens(varlist)
  st_view(id_all, ., ivar, touse)
  id_vals = uniqrows(id_all)
  
  lags_vec = strtoreal(tokens(lags_str))'
  if (rows(lags_vec) == 1) lags_vec = J(dim_N, 1, lags_vec)
  
  L_alpha = J(dim_N, 1, NULL)
  L_beta = J(dim_N, 1, NULL)
  L_GAMMA = J(dim_N, 1, NULL)
  L_SIGMA = J(dim_N, 1, NULL)
  
  real scalar max_p
  max_p = max(lags_vec)
  
  printf("  Estimating individual VECM models (r=%g)...\n\n", dim_r)
  
  for (i = 1; i <= dim_N; i++) {
    real colvector sel
    sel = selectindex(id_all :== id_vals[i])
    
    data_i = J(rows(sel), dim_K, .)
    for (j = 1; j <= dim_K; j++) {
      real colvector v
      st_view(v, ., vnames[j], touse)
      data_i[., j] = v[sel]
    }
    
    y_i = data_i'
    lag_i = lags_vec[i]
    
    // RRR
    struct _xpvc_RRRdef scalar def
    struct _xpvc_RRRresult scalar rrr
    
    def = _xpvc_stackRRR(y_i, lag_i, type)
    rrr = _xpvc_RRR(def.Z0, def.Z1, def.Z2, 1)
    
    // Estimate beta
    real matrix beta_i
    beta_i = _xpvc_beta(rrr.V, dim_r, "natural")
    
    // Estimate VECM
    struct _xpvc_VECMresult scalar vecm
    vecm = _xpvc_VECM(beta_i, rrr)
    
    L_alpha[i] = &(vecm.alpha)
    L_beta[i] = &beta_i
    L_GAMMA[i] = &(vecm.GAMMA)
    L_SIGMA[i] = &(vecm.SIGMA)
    
    printf("  Unit %g: T=%g, p=%g, det(Sigma)=%g\n", ///
      i, def.dim_T, lag_i, det(vecm.SIGMA))
  }
  
  // Pad GAMMA matrices to common size before MG averaging
  // GAMMA includes both K*(p-1) endogenous and deterministic columns,
  // so we find the actual max column count from the estimated matrices.
  real scalar max_gamma_cols, gc
  max_gamma_cols = 0
  for (i = 1; i <= dim_N; i++) {
    gc = cols(*L_GAMMA[i])
    if (gc > max_gamma_cols) max_gamma_cols = gc
  }
  
  // If column counts differ across units, pad to the max
  pointer(real matrix) colvector L_GAMMA_pad
  L_GAMMA_pad = L_GAMMA
  for (i = 1; i <= dim_N; i++) {
    if (cols(*L_GAMMA[i]) < max_gamma_cols) {
      real matrix gpad
      gpad = J(dim_K, max_gamma_cols, 0)
      if (cols(*L_GAMMA[i]) > 0) {
        gpad[., 1..cols(*L_GAMMA[i])] = *L_GAMMA[i]
      }
      L_GAMMA_pad[i] = &gpad
    }
  }
  
  // Mean-group of VECM components
  real matrix alpha_mg, alpha_var, beta_mg, beta_var, gamma_mg, gamma_var
  _xpvc_MG(L_alpha, dim_N, alpha_mg, alpha_var)
  _xpvc_MG(L_beta, dim_N, beta_mg, beta_var)
  _xpvc_MG(L_GAMMA_pad, dim_N, gamma_mg, gamma_var)
  
  // PI = alpha * beta'
  real matrix PI_mg
  PI_mg = alpha_mg * beta_mg'
  
  // Convert to VAR in levels
  real matrix A_mg
  A_mg = _xpvc_vec2var(PI_mg, gamma_mg, max_p)
  
  // Display
  printf("\n  Mean-Group Cointegrating Vectors (beta):\n")
  printf("%s\n", _hline60)
  for (j = 1; j <= rows(beta_mg); j++) {
    printf("  ")
    for (k = 1; k <= cols(beta_mg); k++) {
      printf("%g", beta_mg[j, k])
    }
    printf("\n")
  }
  printf("%s\n", _hline60)
  
  printf("\n  Mean-Group Loading Matrix (alpha):\n")
  printf("%s\n", _hline60)
  for (j = 1; j <= rows(alpha_mg); j++) {
    printf("  ")
    for (k = 1; k <= cols(alpha_mg); k++) {
      printf("%g", alpha_mg[j, k])
    }
    printf("\n")
  }
  printf("%s\n", _hline60)
  
  printf("\n  Long-Run Impact Matrix (PI = alpha*beta'):\n")
  printf("%s\n", _hline60)
  for (j = 1; j <= rows(PI_mg); j++) {
    printf("  ")
    for (k = 1; k <= cols(PI_mg); k++) {
      printf("%g", PI_mg[j, k])
    }
    printf("\n")
  }
  printf("%s\n\n", _hline60)
  
  // Store results
  st_rclear()
  st_numscalar("_xpvc_N", dim_N)
  st_numscalar("_xpvc_K", dim_K)
  st_numscalar("_xpvc_r", dim_r)
  st_numscalar("_xpvc_max_p", max_p)
  st_matrix("_xpvc_A", A_mg)
  st_matrix("_xpvc_alpha", alpha_mg)
  st_matrix("_xpvc_beta", beta_mg)
  st_matrix("_xpvc_PI", PI_mg)
  st_matrix("_xpvc_GAMMA", gamma_mg)
  if (pool_str != "") st_global("r(method)", "PMG of rank-restricted VAR")
  else st_global("r(method)", "MG of rank-restricted VAR")
  st_global("r(type)", type)
}


// ============================================================
// Individual VECM estimation engine
// ============================================================

void _xpvc_vecm_run(string scalar varlist, string scalar touse,
                     string scalar type, real scalar dim_p,
                     real scalar dim_K, real scalar dim_r)
{
  string rowvector vnames
  real matrix data, y
  real scalar j, k
  string scalar _hline60
  
  _hline60 = 60 * "-"
  
  vnames = tokens(varlist)
  
  data = J(0, dim_K, .)
  for (j = 1; j <= dim_K; j++) {
    real colvector v
    st_view(v, ., vnames[j], touse)
    if (j == 1) data = J(rows(v), dim_K, .)
    data[., j] = v
  }
  
  y = data'
  
  // RRR
  struct _xpvc_RRRdef scalar def
  struct _xpvc_RRRresult scalar rrr
  
  def = _xpvc_stackRRR(y, dim_p, type)
  rrr = _xpvc_RRR(def.Z0, def.Z1, def.Z2, 1)
  
  // Beta
  real matrix beta
  beta = _xpvc_beta(rrr.V, dim_r, "natural")
  
  // VECM
  struct _xpvc_VECMresult scalar vecm
  vecm = _xpvc_VECM(beta, rrr)
  
  // VAR in levels
  real matrix A
  A = _xpvc_vec2var(vecm.PI, vecm.GAMMA, dim_p)
  
  // Display
  printf("  Eigenvalues:\n")
  for (j = 1; j <= dim_K; j++) {
    printf("    lambda_%g = %g\n", j, rrr.lambda[j])
  }
  
  printf("\n  Cointegrating Vectors (beta):\n")
  printf("%s\n", _hline60)
  printf("  %-10s", "")
  for (j = 1; j <= dim_r; j++) printf("  %10s", sprintf("ect.%g", j))
  printf("\n")
  for (j = 1; j <= rows(beta); j++) {
    printf("  %-10s", (j <= dim_K ? vnames[j] : sprintf("d%g", j-dim_K)))
    for (k = 1; k <= cols(beta); k++) {
      printf("  %g", beta[j, k])
    }
    printf("\n")
  }
  printf("%s\n", _hline60)
  
  printf("\n  Loading Matrix (alpha):\n")
  printf("%s\n", _hline60)
  for (j = 1; j <= dim_K; j++) {
    printf("  %-10s", vnames[j])
    for (k = 1; k <= dim_r; k++) {
      printf("  %g", vecm.alpha[j, k])
    }
    printf("\n")
  }
  printf("%s\n", _hline60)
  
  printf("\n  Residual Covariance (Sigma):\n")
  printf("%s\n", _hline60)
  for (j = 1; j <= dim_K; j++) {
    printf("  ")
    for (k = 1; k <= dim_K; k++) {
      printf("%g", vecm.SIGMA[j, k])
    }
    printf("\n")
  }
  printf("%s\n\n", _hline60)
  
  // Store
  st_rclear()
  st_numscalar("_xpvc_K", dim_K)
  st_numscalar("_xpvc_T", def.dim_T)
  st_numscalar("_xpvc_p", dim_p)
  st_numscalar("_xpvc_r", dim_r)
  st_matrix("_xpvc_A", A)
  st_matrix("_xpvc_alpha", vecm.alpha)
  st_matrix("_xpvc_beta", beta)
  st_matrix("_xpvc_PI", vecm.PI)
  st_matrix("_xpvc_GAMMA", vecm.GAMMA)
  st_matrix("_xpvc_OMEGA", vecm.OMEGA)
  st_matrix("_xpvc_SIGMA", vecm.SIGMA)
  st_matrix("_xpvc_eigenvalues", rrr.lambda')
  st_global("r(method)", "RRR")
  st_global("r(type)", type)
}

end
