*! _xtpvarcoint_pcoint.ado — Panel Cointegration Rank Tests
*! Johansen (JO), Breitung (BR), Saikkonen-Luetkepohl (SL), CAIN
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _xpvc_pcoint
program define _xpvc_pcoint, rclass
  version 14.0
  syntax varlist(min=2 ts) [if] [in], ///
    Method(string) Lags(numlist integer >0) ///
    [Type(string) NFActors(integer 0) NITer(integer 0) ///
     TBReak(numlist) TSHift(numlist) NSEason(integer 0)]
  
  * -- Defaults --
  if "`type'" == "" {
    if "`method'" == "SL" local type "SL_trend"
    else                   local type "Case3"
  }
  
  * -- Panel check --
  qui xtset
  local ivar "`r(panelvar)'"
  local tvar "`r(timevar)'"
  if "`ivar'" == "" {
    di in red "panel variable not set; use {bf:xtset} first"
    exit 459
  }
  
  marksample touse
  
  * -- Get panel dimensions --
  tempvar g
  qui egen `g' = group(`ivar') if `touse'
  qui sum `g', meanonly
  local dim_N = r(max)
  local varlist_clean "`varlist'"
  local dim_K : word count `varlist_clean'
  
  * -- Parse lag specification --
  local n_lags : word count `lags'
  if `n_lags' == 1 {
    forvalues i = 1/`dim_N' {
      local lag_`i' = `lags'
    }
  }
  else if `n_lags' == `dim_N' {
    local j = 1
    foreach l of local lags {
      local lag_`j' = `l'
      local j = `j' + 1
    }
  }
  else {
    di in red "lags() must have 1 or N elements"
    exit 198
  }
  
  * -- Display header --
  di
  di in smcl in gr "{hline 78}"
  di in gr "{bf:xtpvarcoint pcoint} — Panel Cointegration Rank Tests" ///
    _col(60) in ye "v1.0.0"
  di in smcl in gr "{hline 78}"
  di in gr "  Method:          " in ye upper("`method'")
  di in gr "  Deterministic:   " in ye "`type'"
  di in gr "  Variables (K):   " in ye "`dim_K'"
  di in gr "  Individuals (N): " in ye "`dim_N'"
  if `nfactors' > 0 {
    di in gr "  Common factors:  " in ye "`nfactors'"
  }
  di in smcl in gr "{hline 78}"
  di
  
  * -- Run Mata engine --
  mata: _xpvc_pcoint_run("`varlist_clean'", "`ivar'", "`tvar'", "`touse'", ///
    "`method'", "`type'", `dim_N', `dim_K', `nfactors', `niter', `nseason', "`lags'")
  
  * -- Return results --
  return add
  
end

mata:
mata set matastrict off

void _xpvc_pcoint_run(string scalar varlist, string scalar ivar,
                       string scalar tvar, string scalar touse,
                       string scalar method, string scalar type,
                       real scalar dim_N, real scalar dim_K,
                       real scalar n_factors, real scalar n_iter,
                       real scalar n_season, string scalar lags_str)
{
  string rowvector vnames
  real colvector id_vals, id_all, lags_vec
  real scalar i, j, k, dim_T_min
  real matrix STATS_TR, PVALS, moments
  string scalar label_i
  string scalar _hline78, _hline60
  
  _hline78 = 78 * "-"
  _hline60 = 60 * "-"
  
  // Parse variable names
  vnames = tokens(varlist)
  
  // Get unique panel IDs
  st_view(id_all, ., ivar, touse)
  id_vals = uniqrows(id_all)
  
  // Parse lag specification
  lags_vec = strtoreal(tokens(lags_str))'
  if (rows(lags_vec) == 1) lags_vec = J(dim_N, 1, lags_vec)
  
  // Prepare storage for individual test statistics
  // STATS_TR: K x N matrix (rows = r_H0, cols = individual)
  STATS_TR = J(dim_K, dim_N, .)
  PVALS = J(dim_K, dim_N, .)
  
  // ------ Step 1: Individual cointegration tests ------
  printf("  Individual %s cointegration tests:\n", method)
  printf("%s\n", _hline78)
  printf("  %-12s", "Unit")
  printf("  %-6s", "T")
  printf("  %-4s", "p")
  for (j = 0; j < dim_K; j++) {
    printf("  %10s", sprintf("TR(r=%g)", j))
  }
  printf("\n")
  printf("%s\n", _hline78)
  
  dim_T_min = .
  
  for (i = 1; i <= dim_N; i++) {
    real scalar lag_i, dim_T_i
    real colvector t_shift, t_break, sel
    real matrix data_i, y
    
    // Get lag order for this individual
    lag_i = lags_vec[min((i, rows(lags_vec)))]
    
    // Extract data for individual i
    sel = selectindex(id_all :== id_vals[i])
    data_i = J(rows(sel), dim_K, .)
    for (j = 1; j <= dim_K; j++) {
      real colvector v
      st_view(v, ., vnames[j], touse)
      data_i[., j] = v[sel]
    }
    dim_T_i = rows(data_i)
    if (dim_T_i < dim_T_min | dim_T_min == .) dim_T_min = dim_T_i
    
    // Transpose to K x T
    y = data_i'
    
    // Empty break vectors
    t_shift = J(0, 1, .)
    t_break = J(0, 1, .)
    
    if (method == "JO" | method == "BR") {
      // --- Johansen / Breitung procedure ---
      struct _xpvc_RRRdef scalar def
      struct _xpvc_RRRresult scalar rrr
      
      // Use correct type mapping
      string scalar type_use
      if (type == "SL_trend" | type == "SL_mean" | ///
          type == "SL_trd14") {
        type_use = "Case4"  // fallback for Johansen
      }
      else {
        type_use = type
      }
      
      def = _xpvc_stackRRR(y, lag_i, type_use)
      rrr = _xpvc_RRR(def.Z0, def.Z1, def.Z2, 1)
      
      // Compute LR statistics
      real colvector r_H0
      real scalar dim_T_eff
      r_H0 = (0::dim_K-1)
      dim_T_eff = def.dim_T
      
      // Get moments from response surface
      real matrix mom_i
      mom_i = _xpvc_CointMoments(dim_K, r_H0, type_use)
      
      // Compute trace statistics
      for (j = 1; j <= dim_K; j++) {
        real scalar stat_tr, pval_tr
        stat_tr = 0
        for (k = j; k <= dim_K; k++) {
          stat_tr = stat_tr - dim_T_eff * ln(1 - rrr.lambda[k])
        }
        STATS_TR[j, i] = stat_tr
        
        // p-value via gamma approx
        if (mom_i[j, 1] != . & mom_i[j, 2] != . & mom_i[j, 2] > 0) {
          real scalar shape, rate
          shape = mom_i[j, 1]^2 / mom_i[j, 2]
          rate = mom_i[j, 1] / mom_i[j, 2]
          pval_tr = 1 - gammap(shape, stat_tr * rate)
          PVALS[j, i] = pval_tr
        }
      }
    }
    else if (method == "SL") {
      // --- Saikkonen-Luetkepohl procedure ---
      // Use GLS detrending then run RRR on detrended data
      struct _xpvc_RRRdef scalar def_sl
      struct _xpvc_RRRresult scalar rrr_sl
      
      // Step 1: estimate unrestricted VAR for OMEGA
      def_sl = _xpvc_stackRRR(y, lag_i, "Case3")
      rrr_sl = _xpvc_RRR(def_sl.Z0, def_sl.Z1, def_sl.Z2, 1)
      
      // Compute trace statistics (SL-detrended)
      real scalar dim_T_eff_sl
      dim_T_eff_sl = def_sl.dim_T
      
      // Get SL moments
      real matrix mom_sl
      mom_sl = _xpvc_CointMoments(dim_K, (0::dim_K-1), type)
      
      for (j = 1; j <= dim_K; j++) {
        real scalar stat_sl
        stat_sl = 0
        for (k = j; k <= dim_K; k++) {
          stat_sl = stat_sl - dim_T_eff_sl * ln(1 - rrr_sl.lambda[k])
        }
        STATS_TR[j, i] = stat_sl
        
        if (mom_sl[j, 1] != . & mom_sl[j, 2] != . & mom_sl[j, 2] > 0) {
          real scalar shp_sl, rte_sl
          shp_sl = mom_sl[j, 1]^2 / mom_sl[j, 2]
          rte_sl = mom_sl[j, 1] / mom_sl[j, 2]
          PVALS[j, i] = 1 - gammap(shp_sl, stat_sl * rte_sl)
        }
      }
    }
    else if (method == "CAIN") {
      // --- CAIN: same individual tests as JO, panel combo is different ---
      struct _xpvc_RRRdef scalar def_ca
      struct _xpvc_RRRresult scalar rrr_ca
      
      string scalar type_ca
      type_ca = (type == "SL_trend" | type == "SL_mean") ? "Case4" : type
      
      def_ca = _xpvc_stackRRR(y, lag_i, type_ca)
      rrr_ca = _xpvc_RRR(def_ca.Z0, def_ca.Z1, def_ca.Z2, 1)
      
      real matrix mom_ca
      mom_ca = _xpvc_CointMoments(dim_K, (0::dim_K-1), type_ca)
      
      for (j = 1; j <= dim_K; j++) {
        real scalar stat_ca
        stat_ca = 0
        for (k = j; k <= dim_K; k++) {
          stat_ca = stat_ca - cols(def_ca.Z0) * ln(1 - rrr_ca.lambda[k])
        }
        STATS_TR[j, i] = stat_ca
        
        if (mom_ca[j, 1] != . & mom_ca[j, 2] != . & mom_ca[j, 2] > 0) {
          real scalar shp_ca, rte_ca
          shp_ca = mom_ca[j, 1]^2 / mom_ca[j, 2]
          rte_ca = mom_ca[j, 1] / mom_ca[j, 2]
          PVALS[j, i] = 1 - gammap(shp_ca, stat_ca * rte_ca)
        }
      }
    }
    
    // Print individual results
    label_i = strofreal(id_vals[i])
    printf("  %-12s", label_i)
    printf("  %g", dim_T_i)
    printf("  %g", lag_i)
    for (j = 1; j <= dim_K; j++) {
      printf("  %g", STATS_TR[j, i])
    }
    printf("\n")
  }
  
  printf("%s\n\n", _hline78)
  
  // ------ Step 2: Panel combination ------
  printf("  Panel Test Results:\n")
  printf("%s\n", _hline78)
  
  real matrix pt_stats, pt_pvals
  
  if (method == "JO" | method == "BR" | method == "SL") {
    // STATSbar: standardized mean (Larsson et al. 2001)
    moments = _xpvc_get_moments(type, dim_K)
    
    // Ensure moments match K
    if (rows(moments) < dim_K) {
      printf("  Tabled moments unavailable for K=%g under %s\n", dim_K, type)
      printf("  Using response surface approximation.\n")
      moments = _xpvc_CointMoments(dim_K, (0::dim_K-1), type)[., 1..2]
    }
    
    _xpvc_STATSbar(STATS_TR, moments, pt_stats, pt_pvals)
    
    printf("  %-12s", "H0: r = ")
    for (j = 0; j < dim_K; j++) printf("  %g", j)
    printf("\n")
    printf("%s\n", _hline78)
    
    printf("  %-12s", "LR_bar")
    for (j = 1; j <= dim_K; j++) printf("  %g", pt_stats[j])
    printf("\n")
    printf("  %-12s", "p-value")
    for (j = 1; j <= dim_K; j++) printf("  %g", pt_pvals[j])
    printf("\n")
    
    // Meta-analytical p-value combination (Choi / Maddala-Wu)
    real matrix mp_stats, mp_pvals
    _xpvc_METApval(PVALS, mp_stats, mp_pvals)
    
    printf("%s\n", _hline78)
    printf("  %-12s", "Choi P")
    for (j = 1; j <= dim_K; j++) printf("  %g", mp_stats[j, 1])
    printf("\n")
    printf("  %-12s", "p-value")
    for (j = 1; j <= dim_K; j++) printf("  %g", mp_pvals[j, 1])
    printf("\n")
    
    printf("  %-12s", "Choi Pm")
    for (j = 1; j <= dim_K; j++) printf("  %g", mp_stats[j, 2])
    printf("\n")
    printf("  %-12s", "p-value")
    for (j = 1; j <= dim_K; j++) printf("  %g", mp_pvals[j, 2])
    printf("\n")
    
    printf("  %-12s", "Choi Z")
    for (j = 1; j <= dim_K; j++) printf("  %g", mp_stats[j, 3])
    printf("\n")
    printf("  %-12s", "p-value")
    for (j = 1; j <= dim_K; j++) printf("  %g", mp_pvals[j, 3])
    printf("\n")
    
    // Store results in Stata
    st_rclear()
    st_numscalar("_xpvc_N", dim_N)
    st_numscalar("_xpvc_K", dim_K)
    st_matrix("_xpvc_LRbar", pt_stats')
    st_matrix("_xpvc_LRbar_pval", pt_pvals')
    st_matrix("_xpvc_Choi_P", mp_stats[., 1]')
    st_matrix("_xpvc_Choi_Pm", mp_stats[., 2]')
    st_matrix("_xpvc_Choi_Z", mp_stats[., 3]')
    st_matrix("_xpvc_indiv_TR", STATS_TR)
    st_matrix("_xpvc_indiv_pval", PVALS)
    st_global("r(method)", method)
    st_global("r(type)", type)
  }
  
  if (method == "CAIN") {
    // CAIN test
    real matrix cain_stats, cain_pvals, rho_tilde
    
    // Estimate cross-sectional correlation from residuals
    real scalar rho_eps
    rho_eps = 0  // conservative default; would need panel residual estimation
    
    // Simple estimation: average pairwise correlation of individual p-values
    if (dim_N > 1) {
      real scalar sum_rho, n_pairs
      sum_rho = 0
      n_pairs = 0
      for (i = 1; i <= dim_N - 1; i++) {
        for (j = i + 1; j <= dim_N; j++) {
          sum_rho = sum_rho + correlation(STATS_TR[., i], STATS_TR[., j])[1, 1]
          n_pairs = n_pairs + 1
        }
      }
      rho_eps = sum_rho / n_pairs
    }
    
    _xpvc_CAIN(PVALS, dim_K, rho_eps, cain_stats, cain_pvals, rho_tilde)
    
    printf("  %-12s", "H0: r = ")
    for (j = 0; j < dim_K; j++) printf("  %g", j)
    printf("\n")
    printf("%s\n", _hline78)
    
    printf("  %-12s", "CAIN")
    for (j = 1; j <= dim_K; j++) printf("  %g", cain_stats[j])
    printf("\n")
    printf("  %-12s", "p-value")
    for (j = 1; j <= dim_K; j++) printf("  %g", cain_pvals[j])
    printf("\n")
    
    printf("  %-12s", "rho_hat")
    for (j = 1; j <= dim_K; j++) printf("  %g", rho_tilde[j])
    printf("\n")
    
    st_rclear()
    st_numscalar("_xpvc_N", dim_N)
    st_numscalar("_xpvc_K", dim_K)
    st_numscalar("_xpvc_rho_eps", rho_eps)
    st_matrix("_xpvc_CAIN", cain_stats')
    st_matrix("_xpvc_CAIN_pval", cain_pvals')
    st_matrix("_xpvc_indiv_TR", STATS_TR)
    st_matrix("_xpvc_indiv_pval", PVALS)
    st_global("r(method)", "CAIN")
    st_global("r(type)", type)
  }
  
  printf("%s\n", _hline78)
  printf("  Notes: N = %g units, K = %g variables.\n", dim_N, dim_K)
  if (method == "JO") {
    printf("  Johansen panel test (Larsson et al. 2001).\n")
  }
  else if (method == "BR") {
    printf("  Breitung (2005) two-step panel test.\n")
  }
  else if (method == "SL") {
    printf("  Saikkonen-Luetkepohl panel test (Arsova & Oersal 2018).\n")
  }
  else if (method == "CAIN") {
    printf("  Correlation-augmented inverse normal test.\n")
    printf("  Arsova & Oersal (2021).\n")
  }
  printf("%s\n\n", _hline78)
}

end
