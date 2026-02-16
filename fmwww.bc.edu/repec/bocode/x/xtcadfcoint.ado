*! xtcadfcoint.ado — Panel CADF Cointegration Test with Structural Breaks
*! Implements Banerjee & Carrion-i-Silvestre (2025, JBES)
*! "Panel Data Cointegration Testing with Structural Instabilities"
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Version 1.0.0 — 14 February 2026

program define xtcadfcoint, rclass sortpreserve
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in],  ///
        [Model(integer 1)]                        ///
        [BReaks(integer 0)]                       ///
        [TRIMming(real 0.15)]                     ///
        [MAXlags(integer 4)]                      ///
        [LAGselect(string)]                       ///
        [NFActors(integer 1)]                     ///
        [BRKSlope]                                ///
        [BRKLoadings]                             ///
        [NOCCE]                                   ///
        [SIMulate(integer 0)]                     ///
        [Level(integer 95)]

    // ---- Validate panel ----
    qui xtset
    local panelvar = r(panelvar)
    local timevar  = r(timevar)

    if "`panelvar'" == "" {
        di as error "panel variable not set; use {cmd:xtset panelvar timevar}"
        exit 459
    }

    // ---- Parse options ----
    local opt_brk_slope    = ("`brkslope'" != "")
    local opt_brk_loadings = ("`brkloadings'" != "")
    local opt_CCE          = ("`nocce'" == "")

    // Lag selection
    local opt_auto = 1
    local opt_ic   = 1  // default BIC
    if "`lagselect'" != "" {
        if "`lagselect'" == "aic" {
            local opt_ic = 0
        }
        else if "`lagselect'" == "bic" {
            local opt_ic = 1
        }
        else if "`lagselect'" == "maic" {
            local opt_ic = 2
        }
        else if "`lagselect'" == "mbic" {
            local opt_ic = 3
        }
        else if "`lagselect'" == "fixed" {
            local opt_auto = 0
        }
        else {
            di as error "lagselect() must be one of: aic, bic, maic, mbic, fixed"
            exit 198
        }
    }

    // Validate model
    if `model' < 0 | `model' > 5 {
        di as error "model() must be between 0 and 5"
        exit 198
    }

    // Validate breaks
    if `breaks' < 0 | `breaks' > 2 {
        di as error "breaks() must be 0, 1, or 2"
        exit 198
    }

    if `breaks' == 0 & `model' >= 3 {
        di as error "models 3-5 require breaks() >= 1"
        exit 198
    }

    if `breaks' > 0 & `model' < 3 {
        di as error "breaks() > 0 requires model() >= 3"
        exit 198
    }

    // ---- Identify dep and indep vars ----
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if `k' == 0 {
        di as error "at least one independent variable required"
        exit 198
    }

    // ---- Mark sample ----
    marksample touse
    markout `touse' `depvar' `indepvars'

    // ---- Get panel structure ----
    tempvar panelid timeid
    qui egen `panelid' = group(`panelvar') if `touse'
    qui egen `timeid'  = group(`timevar')  if `touse'

    qui summ `panelid' if `touse', meanonly
    local N = r(max)
    qui summ `timeid' if `touse', meanonly
    local TT = r(max)

    // Validate panel is balanced
    qui count if `touse'
    if r(N) != `N' * `TT' {
        di as error "panel must be balanced (no gaps) for xtcadfcoint"
        exit 459
    }

    // Validate num_factors
    if `nfactors' < 1 {
        di as error "nfactors() must be at least 1"
        exit 198
    }
    if `nfactors' > `k' + 1 {
        di as text "Warning: nfactors() > k+1; rank condition may not be satisfied"
        di as text "Setting nfactors = " `k' + 1
        local nfactors = `k' + 1
    }

    // ---- Reshape to wide matrices (T x N) ----
    // Sort by panel then time
    sort `panelvar' `timevar'

    // Load Mata engine
    capture mata: mata drop _bcs_cadfcoin_main()
    capture mata: mata drop _bcs_cadf_test()
    capture mata: mata drop _bcs_adf_test()
    capture mata: mata drop _bcs_cadfcoin_endog()
    capture mata: mata drop _bcs_kimperron_trim()
    capture mata: mata drop _bcs_simulate_cv()
    capture mata: mata drop _bcs_lagn()
    capture mata: mata drop _bcs_lagn_mat()
    capture qui run "`c(sysdir_plus)'x/xtcadfcoint_mata.ado"
    capture qui run "xtcadfcoint_mata.ado"

    // Build matrices in Mata
    tempname mat_Y mat_X mat_beta mat_SSR mat_t mat_p
    tempname mat_beta_alt mat_Tb mat_Tb_alt
    tempname mat_Tb_trim mat_t_trim

    mata: _xtcadfcoint_run()

    // Immediately capture Mata-posted r() scalars into locals,
    // because subsequent rclass commands (levelsof etc.) will clear r()
    local _panel_cips = r(panel_cips)
    local _panel_cips_alt = r(panel_cips_alt)
    capture local _panel_cips_trim = r(panel_cips_trim)

    // ---- Display results ----
    local model_desc ""
    if `model' == 0 local model_desc "No deterministic component"
    if `model' == 1 local model_desc "Constant"
    if `model' == 2 local model_desc "Linear trend"
    if `model' == 3 local model_desc "Constant with level shifts"
    if `model' == 4 local model_desc "Linear trend with level shifts"
    if `model' == 5 local model_desc "Linear trend with level and slope shifts"

    local lagsel_desc ""
    if `opt_auto' == 0 local lagsel_desc "Fixed (p = `maxlags')"
    if `opt_auto' == 1 & `opt_ic' == 0 local lagsel_desc "Automatic (AIC)"
    if `opt_auto' == 1 & `opt_ic' == 1 local lagsel_desc "Automatic (BIC)"
    if `opt_auto' == 1 & `opt_ic' == 2 local lagsel_desc "Automatic (MAIC)"
    if `opt_auto' == 1 & `opt_ic' == 3 local lagsel_desc "Automatic (MBIC)"

    local cce_desc = cond(`opt_CCE', "Yes (CCE)", "No")

    di ""
    di as text "{hline 78}"
    di as text "{bf: Banerjee & Carrion-i-Silvestre (2025) Panel CADF Cointegration Test}"
    di as text "{hline 78}"
    di as text ""
    di as text "  H0: No cointegration"
    di as text "  H1: Cointegration (panel is cointegrated)"
    di as text ""
    di as text "{hline 78}"
    di as text "  Model specification    : " _col(38) "`model_desc'"
    di as text "  Number of breaks (m)   : " _col(38) "`breaks'"
    di as text "  Trimming fraction      : " _col(38) %5.2f `trimming'
    di as text "  Cross-section dep (CCE): " _col(38) "`cce_desc'"
    di as text "  Number of factors      : " _col(38) "`nfactors'"
    di as text "  Cointegrating vec shift: " _col(38) cond(`opt_brk_slope', "Yes", "No")
    di as text "  Factor loading shift   : " _col(38) cond(`opt_brk_loadings', "Yes", "No")
    di as text "  Lag selection          : " _col(38) "`lagsel_desc'"
    di as text "  Max lag order (p_max)  : " _col(38) "`maxlags'"
    di as text "{hline 78}"
    di as text "  Panel dimensions       : " _col(38) "N = `N', T = `TT'"
    di as text "  Dependent variable     : " _col(38) "`depvar'"
    di as text "  Regressors (k = `k')   : " _col(38) "`indepvars'"
    di as text "{hline 78}"
    di as text ""

    // --- Panel CIPS statistic ---
    di as text "{bf: Panel CIPS Cointegration Test Results}"
    di as text "{hline 78}"

    if `breaks' == 0 {
        di as text "  CIPS statistic (lambda_hat)  : " _col(44) as result %12.4f `_panel_cips'
    }
    else {
        di as text "  CIPS statistic (lambda_hat)  : " _col(44) as result %12.4f `_panel_cips'
        di as text "  CIPS statistic (lambda_tilde): " _col(44) as result %12.4f `_panel_cips_alt'
        if `model' == 5 & `breaks' > 0 {
            if "`_panel_cips_trim'" != "" & "`_panel_cips_trim'" != "." {
                di as text "  CIPS statistic (KP trimmed) : " _col(44) as result %12.4f `_panel_cips_trim'
            }
        }
    }
    di as text "{hline 78}"

    // Display critical values note
    di as text ""
    di as text "  {it:Note: Critical values depend on N, T, k, model and break specification.}"
    di as text "  {it:Refer to Tables B.13-B.24 in Banerjee & Carrion-i-Silvestre (2025, JBES)}"
    di as text "  {it:or simulate using: simulate(1000)}"
    di as text ""

    // --- Bootstrap Critical Values ---
    if `simulate' > 0 {
        tempname mat_pcv mat_icv

        di as text "{bf: Simulating Critical Values (Bootstrap under H0)}"
        di as text "  Replications: `simulate'"
        di as text "  DGP: Independent random walks (no cointegration)"
        di as text "  Lags: p = 0, fixed (matching GAUSS convention)"
        di as text ""

        mata: _xtcadfcoint_simulate()

        // Retrieve CV
        local cv1  = `mat_pcv'[1, 1]
        local cv25 = `mat_pcv'[2, 1]
        local cv5  = `mat_pcv'[3, 1]
        local cv10 = `mat_pcv'[4, 1]

        local icv1  = `mat_icv'[1, 1]
        local icv25 = `mat_icv'[2, 1]
        local icv5  = `mat_icv'[3, 1]
        local icv10 = `mat_icv'[4, 1]

        // Panel CIPS critical values
        di as text "{hline 78}"
        di as text "{bf: Panel CIPS Critical Values}"
        di as text "{hline 78}"
        di as text _col(5) "Sig. Level" _col(20) "Critical Value" _col(40) "Test Stat" _col(56) "Decision"
        di as text "{hline 78}"

        // CIPS test stat (lambda_hat)
        foreach lev in 1 2.5 5 10 {
            if `lev' == 1 {
                local this_cv = `cv1'
            }
            else if `lev' == 2.5 {
                local this_cv = `cv25'
            }
            else if `lev' == 5 {
                local this_cv = `cv5'
            }
            else {
                local this_cv = `cv10'
            }
            local decision "Fail to reject"
            local stars ""
            if `_panel_cips' < `this_cv' {
                local decision "Reject H0"
                if `lev' == 1      local stars " ***"
                if `lev' == 2.5    local stars " ***"
                if `lev' == 5      local stars " **"
                if `lev' == 10     local stars " *"
            }
            di as text _col(5) %5.1f `lev' "%" _col(20) as result %12.4f `this_cv' _col(40) as result %12.4f `_panel_cips' _col(56) as text "`decision'`stars'"
        }
        di as text "{hline 78}"

        // Individual critical values
        di as text ""
        di as text "{bf: Individual CADF Critical Values}"
        di as text "{hline 56}"
        di as text _col(5) "Sig. Level" _col(20) "Critical Value"
        di as text "{hline 56}"
        di as text _col(5) "  1.0%" _col(20) as result %12.4f `icv1'
        di as text _col(5) "  2.5%" _col(20) as result %12.4f `icv25'
        di as text _col(5) "  5.0%" _col(20) as result %12.4f `icv5'
        di as text _col(5) " 10.0%" _col(20) as result %12.4f `icv10'
        di as text "{hline 56}"
        di as text ""

        // Store CV in return list
        return scalar cv_panel_1   = `cv1'
        return scalar cv_panel_2_5 = `cv25'
        return scalar cv_panel_5   = `cv5'
        return scalar cv_panel_10  = `cv10'
        return scalar cv_ind_1     = `icv1'
        return scalar cv_ind_2_5   = `icv25'
        return scalar cv_ind_5     = `icv5'
        return scalar cv_ind_10    = `icv10'
        return scalar simulate     = `simulate'
    }

    // --- Pooled CCE beta ---
    di as text "{bf: Pooled CCE Estimator (beta_hat)}"
    di as text "{hline 46}"
    di as text _col(5) "Variable" _col(25) "Coefficient"
    di as text "{hline 46}"

    local beta_rows = rowsof(`mat_beta')
    if `breaks' > 0 & `opt_brk_slope' == 1 {
        local regime = 0
        forvalues j = 1/`beta_rows' {
            local v_idx = mod(`j' - 1, `k') + 1
            local r_idx = floor((`j' - 1) / `k')
            local vname : word `v_idx' of `indepvars'
            if `r_idx' == 0 {
                di as text _col(5) "`vname'" _col(25) as result %12.6f `mat_beta'[`j', 1]
            }
            else {
                di as text _col(5) "`vname'_brk`r_idx'" _col(25) as result %12.6f `mat_beta'[`j', 1]
            }
        }
    }
    else {
        forvalues j = 1/`beta_rows' {
            local vname : word `j' of `indepvars'
            di as text _col(5) "`vname'" _col(25) as result %12.6f `mat_beta'[`j', 1]
        }
    }
    di as text "{hline 46}"

    // --- Estimated break dates ---
    if `breaks' > 0 {
        di as text ""
        di as text "{bf: Estimated Break Dates}"
        di as text "{hline 56}"
        di as text _col(5) "Break" _col(20) "Tb_hat (lambda_hat)" _col(44) "Tb_tilde (lambda_tilde)"
        di as text "{hline 56}"
        forvalues j = 1/`breaks' {
            di as text _col(5) "Break `j'" _col(24) as result %6.0f `mat_Tb'[`j', 1] _col(48) as result %6.0f `mat_Tb_alt'[`j', 1]
        }
        di as text "{hline 56}"
    }

    // --- Panel BIC ---
    di as text ""
    di as text "{bf: Panel BIC for Model Selection}"
    di as text "{hline 46}"
    local C_p = ln(`N' * `TT' / (`N' + `TT')) * (`N' + `TT') / (`N' * `TT')

    if `breaks' == 0 {
        local panel_bic = ln(`mat_SSR'[3, 1] / (`N' * `TT')) + `k' * `C_p'
        di as text "  Panel BIC (no breaks)  : " _col(38) as result %12.6f `panel_bic'
    }
    else {
        local panel_bic_hat   = ln(`mat_SSR'[3, 1] / (`N' * `TT')) + (`breaks' + 1) * `k' * `C_p'
        di as text "  Panel BIC (lambda_hat) : " _col(38) as result %12.6f `panel_bic_hat'
    }
    di as text "{hline 46}"

    // --- Individual statistics ---
    di as text ""
    di as text "{bf: Individual CADF/ADF Statistics}"
    di as text "{hline 56}"
    di as text _col(5) "Unit" _col(20) "t-statistic" _col(38) "Selected lag"
    di as text "{hline 56}"

    qui levelsof `panelvar' if `touse', local(panels)
    local ui = 0
    foreach p of local panels {
        local ui = `ui' + 1
        if `ui' <= `N' {
            di as text _col(5) "`p'" _col(20) as result %12.4f `mat_t'[`ui', 1] _col(40) as result %6.0f `mat_p'[`ui', 1]
        }
    }
    di as text "{hline 56}"

    // ---- Store results ----
    return scalar panel_cips     = `_panel_cips'
    return scalar N              = `N'
    return scalar T              = `TT'
    return scalar k              = `k'
    return scalar model          = `model'
    return scalar breaks         = `breaks'
    return scalar nfactors       = `nfactors'
    return scalar brk_slope      = `opt_brk_slope'
    return scalar brk_loadings   = `opt_brk_loadings'
    return scalar cce            = `opt_CCE'
    return scalar trimming       = `trimming'
    return scalar maxlags        = `maxlags'
    if `breaks' > 0 {
        return scalar panel_cips_alt = `_panel_cips_alt'
        if "`_panel_cips_trim'" != "" & "`_panel_cips_trim'" != "." {
            return scalar panel_cips_trim = `_panel_cips_trim'
        }
    }

    return matrix beta_ccep      = `mat_beta'
    return matrix SSR            = `mat_SSR'
    return matrix t_individual   = `mat_t'
    return matrix p_selected     = `mat_p'
    if `breaks' > 0 {
        return matrix Tb_hat     = `mat_Tb'
        return matrix Tb_tilde   = `mat_Tb_alt'
        capture confirm matrix `mat_Tb_trim'
        if !_rc {
            return matrix Tb_trim = `mat_Tb_trim'
        }
    }

    di as text ""
    di as text "{hline 78}"
    di as text "  Reference: Banerjee, A. and Carrion-i-Silvestre, J.L. (2025)"
    di as text "  {it:Panel Data Cointegration Testing with Structural Instabilities}"
    di as text "  {it:Journal of Business & Economic Statistics}"
    di as text "{hline 78}"

end

// ======================================================================
// Mata bridge: orchestrates the data reshaping and calls the engine
// ======================================================================

mata:

void _xtcadfcoint_run()
{
    real scalar N, TT, k, model_m, breaks_m, brk_slope_m, brk_loadings_m
    real scalar nfactors_m, p_max_m, opt_auto_m, opt_ic_m, opt_CCE_m
    real scalar trimming_m
    real matrix Y, X, data_wide
    real colvector beta_ccep, SSR_resid, t_cadf, p_est
    real scalar panel_t_cadf, panel_t_cadf_alt, panel_t_cadf_trim
    real colvector beta_ccep_alt, Tb_est, Tb_est_alt
    real colvector t_cadf_trim, Tb_est_trim
    string scalar depvar, indepvars, panelvar, timevar, touse
    string rowvector xvars
    real scalar i, j

    // Get Stata locals/scalars
    depvar   = st_local("depvar")
    indepvars = st_local("indepvars")
    panelvar = st_local("panelvar")
    timevar  = st_local("timevar")
    touse    = st_local("touse")

    model_m       = strtoreal(st_local("model"))
    breaks_m      = strtoreal(st_local("breaks"))
    brk_slope_m   = strtoreal(st_local("opt_brk_slope"))
    brk_loadings_m = strtoreal(st_local("opt_brk_loadings"))
    nfactors_m    = strtoreal(st_local("nfactors"))
    p_max_m       = strtoreal(st_local("maxlags"))
    opt_auto_m    = strtoreal(st_local("opt_auto"))
    opt_ic_m      = strtoreal(st_local("opt_ic"))
    opt_CCE_m     = strtoreal(st_local("opt_CCE"))
    trimming_m    = strtoreal(st_local("trimming"))

    N  = strtoreal(st_local("N"))
    TT = strtoreal(st_local("TT"))
    k  = strtoreal(st_local("k"))

    xvars = tokens(indepvars)

    // ---- Reshape long -> wide ----
    // Y is T x N, X is T x (N*k)
    Y = J(TT, N, .)
    X = J(TT, N * k, .)

    // Get panel IDs
    real colvector panel_ids, time_ids, y_data
    real matrix x_data
    real colvector all_panels, all_times

    st_view(y_data, ., depvar, touse)
    st_view(x_data, ., xvars, touse)
    st_view(panel_ids, ., st_local("panelid"), touse)
    st_view(time_ids, ., st_local("timeid"), touse)

    real scalar pi, ti
    for (i = 1; i <= rows(y_data); i++) {
        pi = panel_ids[i]
        ti = time_ids[i]
        Y[ti, pi] = y_data[i]
        for (j = 1; j <= k; j++) {
            X[ti, pi + (j - 1) * N] = x_data[i, j]
        }
    }

    // ---- Call engine ----
    if (breaks_m == 0) {
        _bcs_cadfcoin_main(Y, X, model_m, (0), brk_slope_m, brk_loadings_m,
            nfactors_m, p_max_m, opt_auto_m, opt_ic_m, opt_CCE_m,
            beta_ccep, SSR_resid, panel_t_cadf, t_cadf, p_est)

        Tb_est = (0)
        Tb_est_alt = (0)
        panel_t_cadf_alt = panel_t_cadf
        beta_ccep_alt = beta_ccep
        panel_t_cadf_trim = .
        t_cadf_trim = J(N, 1, .)
        Tb_est_trim = (0)
    }
    else {
        _bcs_cadfcoin_endog(Y, X, model_m, breaks_m, trimming_m,
            brk_slope_m, brk_loadings_m, nfactors_m, p_max_m,
            opt_auto_m, opt_ic_m, opt_CCE_m,
            beta_ccep, SSR_resid, panel_t_cadf, t_cadf, p_est,
            Tb_est, panel_t_cadf_alt, beta_ccep_alt, Tb_est_alt,
            panel_t_cadf_trim, t_cadf_trim, Tb_est_trim)
    }

    // ---- Post results to Stata ----
    st_matrix(st_local("mat_beta"), beta_ccep)
    st_matrix(st_local("mat_SSR"), SSR_resid)
    st_matrix(st_local("mat_t"), t_cadf)
    st_matrix(st_local("mat_p"), p_est)

    if (breaks_m > 0) {
        st_matrix(st_local("mat_Tb"), Tb_est)
        st_matrix(st_local("mat_Tb_alt"), Tb_est_alt)

        // Model 5 Kim-Perron trim results
        if (model_m == 5 & !missing(panel_t_cadf_trim)) {
            st_numscalar("r(panel_cips_trim)", panel_t_cadf_trim)
            st_matrix(st_local("mat_t_trim"), t_cadf_trim)
            st_matrix(st_local("mat_Tb_trim"), Tb_est_trim)
        }
    }

    // Return scalars
    st_numscalar("r(panel_cips)", panel_t_cadf)
    if (breaks_m > 0) {
        st_numscalar("r(panel_cips_alt)", panel_t_cadf_alt)
    }
}


void _xtcadfcoint_simulate()
{
    real scalar N, TT, k, model_m, breaks_m, brk_slope_m, brk_loadings_m
    real scalar nfactors_m, opt_CCE_m
    real scalar reps_m
    real colvector Tb_sim, panel_cv, ind_cv

    model_m       = strtoreal(st_local("model"))
    breaks_m      = strtoreal(st_local("breaks"))
    brk_slope_m   = strtoreal(st_local("opt_brk_slope"))
    brk_loadings_m = strtoreal(st_local("opt_brk_loadings"))
    nfactors_m    = strtoreal(st_local("nfactors"))
    opt_CCE_m     = strtoreal(st_local("opt_CCE"))

    N  = strtoreal(st_local("N"))
    TT = strtoreal(st_local("TT"))
    k  = strtoreal(st_local("k"))
    reps_m = strtoreal(st_local("simulate"))

    // Build break dates for simulation
    // Use break fractions at even spacing (matching GAUSS convention)
    if (breaks_m == 0) {
        Tb_sim = (0)
    }
    else if (breaks_m == 1) {
        Tb_sim = (floor(0.5 * TT))  // lambda = 0.5
    }
    else if (breaks_m == 2) {
        Tb_sim = (floor(0.3 * TT) \ floor(0.7 * TT))  // lambda = 0.3, 0.7
    }

    // GAUSS critical value scripts always use p=0, opt_lags_sel=0 (fixed zero lags)
    // This is essential: auto-lag with small T causes near-singular regressions
    _bcs_simulate_cv(N, TT, k, model_m, Tb_sim, brk_slope_m, brk_loadings_m,
        nfactors_m, 0, 0, 0, opt_CCE_m,
        reps_m, panel_cv, ind_cv)

    st_matrix(st_local("mat_pcv"), panel_cv)
    st_matrix(st_local("mat_icv"), ind_cv)
}

end
