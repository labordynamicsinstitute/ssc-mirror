*! mtnardl — Bootstrap Multiple Threshold Nonlinear ARDL
*! Version 1.0.0 — 2026-02-24
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Implements Pal & Mitra (2016) MTNARDL with bootstrap cointegration
*! References:
*!   Pal & Mitra (2016) — Multiple Threshold NARDL
*!   Pesaran, Shin & Smith (2001) — ARDL bounds testing
*!   McNown, Sam & Goh (2018) — Bootstrap ARDL
*!   Bertelli, Vacca & Zoia (2022) — Bootstrap ARDL (conditional)
*!   Kripfganz & Schneider (2020) — ARDL bounds test critical values

capture program drop mtnardl
program define mtnardl, eclass sortpreserve
    version 17

    // =====================================================================
    // 1. SYNTAX PARSING
    // =====================================================================
    syntax varlist(min=2 ts fv) [if] [in], ///
        Decompose(varlist ts)            ///
        [Partition(string)               ///
         CUTpoints(numlist)              ///
         Maxlag(integer 4)               ///
         IC(string)                      ///
         CASE(integer 3)                 ///
         Level(integer 95)               ///
         HORizon(integer 20)             ///
         REPS(integer 999)               ///
         TYPE(string)                    ///
         SAVEDecomp                      ///
         NODiag NODynmult NOAdvanced     ///
         NOTable noGRAPH                 ///
        ]

    marksample touse
    markout `touse' `decompose'

    // Defaults
    if "`partition'" == "" local partition "quintile"
    if "`ic'" == "" local ic "aic"
    if "`type'" == "" local type "mtnardl"
    local type = lower("`type'")

    // Validate
    if !inlist("`type'", "mtnardl", "mtnardl_mcnown", "mtnardl_bvz") {
        di as err "type() must be {bf:mtnardl}, {bf:mtnardl_mcnown}, or {bf:mtnardl_bvz}"
        exit 198
    }
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }
    if `maxlag' < 1 | `maxlag' > 12 {
        di as err "maxlag() must be between 1 and 12"
        exit 198
    }
    if !inlist(`case', 2, 3, 4, 5) {
        di as err "case() must be 2, 3, 4, or 5"
        exit 198
    }

    // Confirm time series
    qui tsset
    local timevar "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "mtnardl is designed for time-series data only"
        exit 198
    }

    // Parse variables
    gettoken depvar indepvars : varlist
    local nindep : word count `indepvars'
    if `nindep' < 1 {
        di as err "at least one independent variable required"
        exit 198
    }

    // =====================================================================
    // 2. PRESERVE & PREPARE
    // =====================================================================
    preserve
    qui keep if `touse'
    qui count
    local T = r(N)
    if `T' < 20 {
        di as err "sample size too small (N = `T')"
        exit 198
    }

    // =====================================================================
    // 3. DECOMPOSE VARIABLES
    // =====================================================================
    di as txt ""
    di as txt "{hline 78}"
    if inlist("`type'", "mtnardl_mcnown", "mtnardl_bvz") {
        di as res _col(3) "  Bootstrap Multiple Threshold Nonlinear ARDL (BMTNARDL)"
    }
    else {
        di as res _col(3) "  Multiple Threshold Nonlinear ARDL (MTNARDL)"
    }
    di as txt "{hline 78}"
    di as txt _col(5) "Dependent variable  : " as res "`depvar'"
    di as txt _col(5) "Independent var(s)  : " as res "`indepvars'"
    di as txt _col(5) "Decomposed var(s)   : " as res "`decompose'"
    di as txt _col(5) "Partition type      : " as res "`partition'"
    di as txt _col(5) "Sample size (T)     : " as res "`T'"
    di as txt _col(5) "Max lag order       : " as res "`maxlag'"
    di as txt _col(5) "Information crit.   : " as res upper("`ic'")
    di as txt _col(5) "PSS Case            : " as res "Case `case'"
    if inlist("`type'", "mtnardl_mcnown", "mtnardl_bvz") {
        di as txt _col(5) "Bootstrap reps      : " as res "`reps'"
    }
    di as txt "{hline 78}"
    di as txt ""

    // Call decomposition
    local graph_opt ""
    if "`graph'" == "nograph" local graph_opt "nograph"
    local cp_opt ""
    if "`cutpoints'" != "" local cp_opt "cutpoints(`cutpoints')"

    _mtnardl_decompose, depvar(`depvar') decompose(`decompose') ///
        partition(`partition') `cp_opt' `graph_opt'

    local decomp_vars "`r(decomp_vars)'"
    local nq = r(nq)
    local partition_label "`r(partition_label)'"

    // Build list of all independent variables for the ARDL
    // Non-decomposed indepvars + decomposed partial sums
    local all_indepvars ""
    local ctrl_vars ""
    foreach xvar of local indepvars {
        local is_decomposed = 0
        foreach dvar of local decompose {
            if "`xvar'" == "`dvar'" local is_decomposed = 1
        }
        if `is_decomposed' == 0 {
            local ctrl_vars "`ctrl_vars' `xvar'"
            local all_indepvars "`all_indepvars' `xvar'"
        }
    }
    // Add decomposed partial sums
    local all_indepvars "`all_indepvars' `decomp_vars'"
    local n_all_indep : word count `all_indepvars'

    // =====================================================================
    // 4. LAG SELECTION (exhaustive grid search)
    // =====================================================================
    di as txt _col(3) "Step 1: Selecting lag orders by " upper("`ic'") "..."

    tempname best_ic_val
    scalar `best_ic_val' = .
    local best_p = 1
    foreach xv of local all_indepvars {
        local cn = subinstr("`xv'", ".", "_", .)
        local best_q_`cn' = 0
    }
    local total_specs = 0
    local nq_levels = `maxlag' + 1

    // Limit combinations to avoid explosion
    local nq_combos = 1
    forvalues i = 1/`n_all_indep' {
        local nq_combos = `nq_combos' * `nq_levels'
    }
    // Cap at reasonable number
    if `nq_combos' > 50000 {
        // Use simplified search: same q for all decomposed vars of same original
        di as txt _col(5) "Large search space — using grouped lag selection..."
        local use_grouped = 1
    }
    else {
        local use_grouped = 0
    }

    if `use_grouped' == 1 {
        // Grouped: same q for all regimes of same variable
        local n_orig_decomp : word count `decompose'
        local n_ctrl : word count `ctrl_vars'
        local n_groups = `n_orig_decomp' + `n_ctrl'
        local nq_combos_g = 1
        forvalues i = 1/`n_groups' {
            local nq_combos_g = `nq_combos_g' * `nq_levels'
        }

        forvalues p = 1/`maxlag' {
            forvalues qidx = 0/`=`nq_combos_g' - 1' {
                local total_specs = `total_specs' + 1
                local qidx_tmp = `qidx'

                // Decode q for each group
                local gidx = 0
                foreach dvar of local decompose {
                    local cdn = subinstr("`dvar'", ".", "_", .)
                    local q_group_`cdn' = mod(`qidx_tmp', `nq_levels')
                    local qidx_tmp = floor(`qidx_tmp' / `nq_levels')
                    // Apply same q to all regimes
                    forvalues qq = 1/`nq' {
                        local psn "_mt_`cdn'_q`qq'"
                        local cn2 = subinstr("`psn'", ".", "_", .)
                        local q_`cn2' = `q_group_`cdn''
                    }
                }
                foreach cvar of local ctrl_vars {
                    local cn3 = subinstr("`cvar'", ".", "_", .)
                    local q_`cn3' = mod(`qidx_tmp', `nq_levels')
                    local qidx_tmp = floor(`qidx_tmp' / `nq_levels')
                }

                // Build regressors
                local regvars "L.`depvar'"
                foreach xv of local all_indepvars {
                    local regvars "`regvars' L.`xv'"
                }
                forvalues j = 1/`p' {
                    local regvars "`regvars' L`j'.D.`depvar'"
                }
                foreach xv of local all_indepvars {
                    local cn4 = subinstr("`xv'", ".", "_", .)
                    local qi = `q_`cn4''
                    forvalues j = 0/`qi' {
                        if `j' == 0 {
                            local regvars "`regvars' D.`xv'"
                        }
                        else {
                            local regvars "`regvars' L`j'.D.`xv'"
                        }
                    }
                }

                capture qui regress D.`depvar' `regvars'
                if _rc == 0 {
                    local nobs_tmp = e(N)
                    local k_tmp = e(df_m) + 1
                    local ll_tmp = e(ll)
                    if "`ic'" == "aic" {
                        local ic_tmp = -2 * `ll_tmp' + 2 * `k_tmp'
                    }
                    else {
                        local ic_tmp = -2 * `ll_tmp' + `k_tmp' * ln(`nobs_tmp')
                    }
                    if `ic_tmp' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                        scalar `best_ic_val' = `ic_tmp'
                        local best_p = `p'
                        foreach xv of local all_indepvars {
                            local cn5 = subinstr("`xv'", ".", "_", .)
                            local best_q_`cn5' = `q_`cn5''
                        }
                    }
                }
            }
        }
    }
    else {
        // Full exhaustive search
        forvalues p = 1/`maxlag' {
            forvalues qidx = 0/`=`nq_combos' - 1' {
                local total_specs = `total_specs' + 1
                local qidx_tmp = `qidx'
                foreach xv of local all_indepvars {
                    local cn6 = subinstr("`xv'", ".", "_", .)
                    local q_`cn6' = mod(`qidx_tmp', `nq_levels')
                    local qidx_tmp = floor(`qidx_tmp' / `nq_levels')
                }

                local regvars "L.`depvar'"
                foreach xv of local all_indepvars {
                    local regvars "`regvars' L.`xv'"
                }
                forvalues j = 1/`p' {
                    local regvars "`regvars' L`j'.D.`depvar'"
                }
                foreach xv of local all_indepvars {
                    local cn7 = subinstr("`xv'", ".", "_", .)
                    local qi = `q_`cn7''
                    forvalues j = 0/`qi' {
                        if `j' == 0 {
                            local regvars "`regvars' D.`xv'"
                        }
                        else {
                            local regvars "`regvars' L`j'.D.`xv'"
                        }
                    }
                }

                capture qui regress D.`depvar' `regvars'
                if _rc == 0 {
                    local nobs_tmp = e(N)
                    local k_tmp = e(df_m) + 1
                    local ll_tmp = e(ll)
                    if "`ic'" == "aic" {
                        local ic_tmp = -2 * `ll_tmp' + 2 * `k_tmp'
                    }
                    else {
                        local ic_tmp = -2 * `ll_tmp' + `k_tmp' * ln(`nobs_tmp')
                    }
                    if `ic_tmp' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                        scalar `best_ic_val' = `ic_tmp'
                        local best_p = `p'
                        foreach xv of local all_indepvars {
                            local cn8 = subinstr("`xv'", ".", "_", .)
                            local best_q_`cn8' = `q_`cn8''
                        }
                    }
                }
            }
        }
    }

    // Display optimal lags
    di as txt _col(5) "Optimal p = " as res "`best_p'" as txt ", q = " _c
    local first = 1
    foreach xv of local all_indepvars {
        local cn9 = subinstr("`xv'", ".", "_", .)
        if `first' == 0 di as txt "," _c
        di as res "`best_q_`cn9''" _c
        local first = 0
    }
    di as txt " (" as res "`total_specs'" as txt " models evaluated)"
    di as txt ""

    // =====================================================================
    // 5. FINAL ESTIMATION
    // =====================================================================
    di as txt _col(3) "Step 2: Final MTNARDL estimation..."
    di as txt ""

    // Build final regressors
    local regvars ""
    local levelvars ""
    local indeplev ""

    local regvars "L.`depvar'"
    local levelvars "L.`depvar'"
    foreach xv of local all_indepvars {
        local regvars "`regvars' L.`xv'"
        local levelvars "`levelvars' L.`xv'"
        local indeplev "`indeplev' L.`xv'"
    }

    local sr_depvars ""
    forvalues j = 1/`best_p' {
        local regvars "`regvars' L`j'.D.`depvar'"
        local sr_depvars "`sr_depvars' L`j'.D.`depvar'"
    }

    local sr_indepvars ""
    foreach xv of local all_indepvars {
        local cn10 = subinstr("`xv'", ".", "_", .)
        local q_this = `best_q_`cn10''
        forvalues j = 0/`q_this' {
            if `j' == 0 {
                local regvars "`regvars' D.`xv'"
                local sr_indepvars "`sr_indepvars' D.`xv'"
            }
            else {
                local regvars "`regvars' L`j'.D.`xv'"
                local sr_indepvars "`sr_indepvars' L`j'.D.`xv'"
            }
        }
    }

    // Final OLS
    qui regress D.`depvar' `regvars'
    estimates store _mtnardl_main

    local nobs = e(N)
    local nparams = e(df_m) + 1
    local r2 = e(r2)
    local r2_a = e(r2_a)
    local ll = e(ll)
    local rss = e(rss)
    local F_model = e(F)
    local F_model_p = Ftail(e(df_m), e(df_r), e(F))
    local df_m = e(df_m)
    local df_r = e(df_r)
    local rmse = e(rmse)
    local aic_val = -2 * `ll' + 2 * `nparams'
    local bic_val = -2 * `ll' + `nparams' * ln(`nobs')

    // Save residuals
    capture drop _mtnardl_resid
    qui predict double _mtnardl_resid, residuals

    // ECM coefficient
    local ecm_coef = _b[L.`depvar']
    local ecm_se = _se[L.`depvar']
    local ecm_t = `ecm_coef' / `ecm_se'
    local ecm_p = 2 * ttail(`df_r', abs(`ecm_t'))

    // =====================================================================
    // TABLE 1: MODEL SELECTION SUMMARY
    // =====================================================================
    di as txt "{hline 78}"
    di as res _col(5) "Table 1: Model Selection Summary"
    di as txt "{hline 78}"
    di as txt ""
    di as txt "  {hline 68}"
    di as txt _col(5) "Partition" _col(45) "`partition_label'"
    di as txt _col(5) "Number of regimes" _col(45) "`nq'"
    di as txt _col(5) "ARDL Specification" _col(45) "ARDL(`best_p'" _c
    foreach xv of local all_indepvars {
        local cn11 = subinstr("`xv'", ".", "_", .)
        di as txt ",`best_q_`cn11''" _c
    }
    di as txt ")"
    di as txt _col(5) "PSS Case" _col(45) "Case `case'"
    di as txt "  {hline 68}"
    di as txt _col(5) "Observations" _col(45) as res %8.0f `nobs'
    di as txt _col(5) "R-squared" _col(45) as res %8.6f `r2'
    di as txt _col(5) "Adjusted R-squared" _col(45) as res %8.6f `r2_a'
    di as txt _col(5) "Log-Likelihood" _col(45) as res %12.4f `ll'
    di as txt _col(5) "AIC" _col(45) as res %12.4f `aic_val'
    di as txt _col(5) "BIC" _col(45) as res %12.4f `bic_val'
    di as txt _col(5) "F-statistic" _col(45) as res %8.4f `F_model' ///
       as txt " (p = " as res %6.4f `F_model_p' as txt ")"
    di as txt _col(5) "RMSE" _col(45) as res %12.6f `rmse'
    di as txt _col(5) "Models evaluated" _col(45) as res %8.0f `total_specs'
    di as txt "  {hline 68}"
    di as txt ""

    // =====================================================================
    // TABLE 2: EC REPRESENTATION
    // =====================================================================
    if "`notable'" == "" {
        di as txt "{hline 78}"
        di as res _col(5) "Table 2: MTNARDL EC Representation"
        di as txt "{hline 78}"
        di as txt ""

        // ADJ
        di as txt "  {bf:ADJ — Speed of Adjustment}"
        di as txt "  {hline 68}"
        di as txt _col(5) "Variable" _col(28) "Coef." _col(40) "Std.Err." ///
           _col(52) "t-stat" _col(62) "p-value"
        di as txt "  {hline 68}"
        di as txt _col(5) "L.`depvar'" _col(25) as res %10.6f `ecm_coef' ///
           _col(37) %10.6f `ecm_se' _col(49) %8.4f `ecm_t' _col(59) %8.4f `ecm_p' _c
        _mtnardl_stars `ecm_p'
        di as txt "  {hline 68}"

        // LR per regime
        di as txt ""
        di as txt "  {bf:LR — Long-Run Coefficients per Regime}  {it:(delta method)}"
        di as txt "  {hline 68}"
        di as txt _col(5) "Variable" _col(22) "LR Coef." _col(34) "Std.Err." ///
           _col(46) "z-stat" _col(56) "p-value" _col(66) "[`level'% CI]"
        di as txt "  {hline 68}"

        foreach xv of local all_indepvars {
            // Clean display name: _mt_lcrude_q1 -> lcrude(Q1)
            local dname "`xv'"
            if strpos("`xv'", "_mt_") == 1 {
                local dname = substr("`xv'", 5, .)
                // Extract quantile part: e.g., lcrude_q1 -> find _q
                local qpos = strpos("`dname'", "_q")
                if `qpos' > 0 {
                    local vpart = substr("`dname'", 1, `qpos' - 1)
                    local qpart = upper(substr("`dname'", `qpos' + 1, .))
                    local dname "`vpart'(`qpart')"
                }
            }
            capture qui nlcom (LR: -_b[L.`xv'] / _b[L.`depvar']), level(`level')
            if _rc == 0 {
                mat _nlcom_b = r(b)
                mat _nlcom_V = r(V)
                local lr_b = _nlcom_b[1,1]
                local lr_se = sqrt(_nlcom_V[1,1])
                local lr_z = `lr_b' / `lr_se'
                local lr_p = 2 * (1 - normal(abs(`lr_z')))
                local lr_lo = `lr_b' - invnormal(1 - (100-`level')/200) * `lr_se'
                local lr_hi = `lr_b' + invnormal(1 - (100-`level')/200) * `lr_se'
                di as txt _col(5) "`dname'" _col(20) as res %10.6f `lr_b' ///
                   _col(32) %10.6f `lr_se' _col(44) %8.4f `lr_z' _col(54) %8.4f `lr_p' ///
                   _col(63) "[" %7.4f `lr_lo' "," %7.4f `lr_hi' "]" _c
                _mtnardl_stars `lr_p'
                mat drop _nlcom_b _nlcom_V
            }
            else {
                di as txt _col(5) "`dname'" _col(20) as err "could not compute"
            }
        }
        di as txt "  {hline 68}"

        // SR
        di as txt ""
        di as txt "  {bf:SR — Short-Run Coefficients}"
        di as txt "  {hline 68}"
        di as txt _col(5) "Variable" _col(28) "Coef." _col(40) "Std.Err." ///
           _col(52) "t-stat" _col(62) "p-value"
        di as txt "  {hline 68}"

        forvalues j = 1/`best_p' {
            local b = _b[L`j'.D.`depvar']
            local se = _se[L`j'.D.`depvar']
            local t = `b' / `se'
            local p = 2 * ttail(`df_r', abs(`t'))
            di as txt _col(5) "L`j'.D.`depvar'" _col(25) as res %10.6f `b' ///
               _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
            _mtnardl_stars `p'
        }

        foreach xv of local all_indepvars {
            // Clean display name
            local dname "`xv'"
            if strpos("`xv'", "_mt_") == 1 {
                local dname = substr("`xv'", 5, .)
                local qpos = strpos("`dname'", "_q")
                if `qpos' > 0 {
                    local vpart = substr("`dname'", 1, `qpos' - 1)
                    local qpart = upper(substr("`dname'", `qpos' + 1, .))
                    local dname "`vpart'(`qpart')"
                }
            }
            local cn12 = subinstr("`xv'", ".", "_", .)
            local q_this = `best_q_`cn12''
            forvalues j = 0/`q_this' {
                if `j' == 0 {
                    local vname "D.`xv'"
                    local vlabel "D.`dname'"
                }
                else {
                    local vname "L`j'.D.`xv'"
                    local vlabel "L`j'.D.`dname'"
                }
                local b = _b[`vname']
                local se = _se[`vname']
                local t = `b' / `se'
                local p = 2 * ttail(`df_r', abs(`t'))
                di as txt _col(5) "`vlabel'" _col(25) as res %10.6f `b' ///
                   _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
                _mtnardl_stars `p'
            }
        }
        di as txt "  {hline 68}"

        // Constant
        di as txt ""
        di as txt "  {bf:Deterministics}"
        di as txt "  {hline 68}"
        local b = _b[_cons]
        local se = _se[_cons]
        local t = `b' / `se'
        local p = 2 * ttail(`df_r', abs(`t'))
        di as txt _col(5) "Constant" _col(25) as res %10.6f `b' ///
           _col(37) %10.6f `se' _col(49) %8.4f `t' _col(59) %8.4f `p' _c
        _mtnardl_stars `p'
        di as txt "  {hline 68}"
        di as txt _col(5) "{it:Stars: *** p<0.01, ** p<0.05, * p<0.10}"
        di as txt ""
    }

    // =====================================================================
    // TABLE 3: COINTEGRATION TESTS
    // =====================================================================
    qui test `levelvars'
    local Fov_stat = r(F)
    local t_stat = `ecm_t'
    qui test `indeplev'
    local Find_stat = r(F)

    di as txt "{hline 78}"
    di as res _col(5) "Table 3: Cointegration Test Results"
    di as txt "{hline 78}"
    di as txt ""

    if "`type'" == "mtnardl" {
        // PSS Bounds Test with KS critical values
        di as txt _col(5) "{bf:PSS Bounds Test} (Pesaran, Shin & Smith, 2001)"
        di as txt _col(5) "Critical values: Kripfganz & Schneider (2020)"
        di as txt ""

        local sr_count = `best_p'
        foreach xv of local all_indepvars {
            local cn13 = subinstr("`xv'", ".", "_", .)
            local sr_count = `sr_count' + `best_q_`cn13'' + 1
        }

        local k_pss = `n_all_indep'
        local has_ardlbounds = 0

        capture which ardlbounds
        if _rc == 0 {
            local has_ardlbounds = 1

            // --- F-statistic CVs (separate call per significance level) ---
            capture noisily {
                tempname Fcv10 Fcv05 Fcv01
                qui ardlbounds, case(`case') stat(F) n(`nobs') k(`k_pss') ///
                    sr(`sr_count') siglevels(10)
                mat `Fcv10' = r(cvmat)
                local F_I0_10 = `Fcv10'[1, 1]
                local F_I1_10 = `Fcv10'[1, 2]
                qui ardlbounds, case(`case') stat(F) n(`nobs') k(`k_pss') ///
                    sr(`sr_count') siglevels(5)
                mat `Fcv05' = r(cvmat)
                local F_I0_05 = `Fcv05'[1, 1]
                local F_I1_05 = `Fcv05'[1, 2]
                qui ardlbounds, case(`case') stat(F) n(`nobs') k(`k_pss') ///
                    sr(`sr_count') siglevels(1)
                mat `Fcv01' = r(cvmat)
                local F_I0_01 = `Fcv01'[1, 1]
                local F_I1_01 = `Fcv01'[1, 2]
            }
            if _rc != 0 local has_ardlbounds = 0

            // --- F-statistic p-value (separate call with pvalue) ---
            local F_pv_I0 = .
            local F_pv_I1 = .
            if `has_ardlbounds' == 1 {
                capture noisily {
                    qui ardlbounds, case(`case') stat(F) n(`nobs') k(`k_pss') ///
                        sr(`sr_count') pvalue(`Fov_stat')
                    tempname Fpvmat
                    mat `Fpvmat' = r(cvmat)
                    local ncol_F = colsof(`Fpvmat')
                    local nrow_F = rowsof(`Fpvmat')
                    if `ncol_F' >= 2 {
                        local F_pv_I0 = `Fpvmat'[`nrow_F', `ncol_F' - 1]
                        local F_pv_I1 = `Fpvmat'[`nrow_F', `ncol_F']
                    }
                }
            }

            // --- t-statistic CVs (separate call per significance level) ---
            if `has_ardlbounds' == 1 {
                capture noisily {
                    tempname tcv10 tcv05 tcv01
                    qui ardlbounds, case(`case') stat(t) n(`nobs') k(`k_pss') ///
                        sr(`sr_count') siglevels(10)
                    mat `tcv10' = r(cvmat)
                    local t_I0_10 = `tcv10'[1, 1]
                    local t_I1_10 = `tcv10'[1, 2]
                    qui ardlbounds, case(`case') stat(t) n(`nobs') k(`k_pss') ///
                        sr(`sr_count') siglevels(5)
                    mat `tcv05' = r(cvmat)
                    local t_I0_05 = `tcv05'[1, 1]
                    local t_I1_05 = `tcv05'[1, 2]
                    qui ardlbounds, case(`case') stat(t) n(`nobs') k(`k_pss') ///
                        sr(`sr_count') siglevels(1)
                    mat `tcv01' = r(cvmat)
                    local t_I0_01 = `tcv01'[1, 1]
                    local t_I1_01 = `tcv01'[1, 2]
                }
                if _rc != 0 local has_ardlbounds = 0
            }

            // --- t-statistic p-value ---
            local t_pv_I0 = .
            local t_pv_I1 = .
            if `has_ardlbounds' == 1 {
                capture noisily {
                    qui ardlbounds, case(`case') stat(t) n(`nobs') k(`k_pss') ///
                        sr(`sr_count') pvalue(`t_stat')
                    tempname tpvmat
                    mat `tpvmat' = r(cvmat)
                    local ncol_t = colsof(`tpvmat')
                    local nrow_t = rowsof(`tpvmat')
                    if `ncol_t' >= 2 {
                        local t_pv_I0 = `tpvmat'[`nrow_t', `ncol_t' - 1]
                        local t_pv_I1 = `tpvmat'[`nrow_t', `ncol_t']
                    }
                }
            }
        }

        // Fallback PSS CVs
        if `has_ardlbounds' == 0 {
            di as txt _col(5) "{it:Using PSS (2001) asymptotic CVs}"
            local F_I0_10 = 2.45 ; local F_I1_10 = 3.52
            local F_I0_05 = 2.86 ; local F_I1_05 = 4.01
            local F_I0_01 = 3.74 ; local F_I1_01 = 5.06
            local t_I0_10 = -2.57 ; local t_I1_10 = -3.66
            local t_I0_05 = -2.86 ; local t_I1_05 = -3.99
            local t_I0_01 = -3.43 ; local t_I1_01 = -4.60
            local F_pv_I0 = . ; local F_pv_I1 = .
            local t_pv_I0 = . ; local t_pv_I1 = .
        }

        // Restore estimation (ardlbounds clobbers e())
        capture estimates restore _mtnardl_main

        if `has_ardlbounds' == 1 {
            di as txt _col(5) "Finite-sample CVs (k = " as res "`k_pss'" ///
               as txt ", N = " as res "`nobs'" as txt ", sr = " as res "`sr_count'" as txt ")"
        }
        di as txt ""

        // Display table
        di as txt "  {hline 74}"
        di as txt _col(5) "Test" _col(18) "Stat" ///
           _col(27) "  10% cv" _col(41) "   5% cv" _col(55) "   1% cv" _col(67) "p-value"
        di as txt _col(27) " I(0)  I(1)" _col(41) " I(0)  I(1)" ///
           _col(55) " I(0)  I(1)" _col(67) "I(0)  I(1)"
        di as txt "  {hline 74}"

        // F_ov decision
        if `Fov_stat' > `F_I1_05' {
            local Fov_dec "Reject H0"
        }
        else if `Fov_stat' < `F_I0_05' {
            local Fov_dec "Fail to reject"
        }
        else {
            local Fov_dec "Inconclusive"
        }

        di as txt _col(3) "F_ov" _col(15) as res %7.3f `Fov_stat' ///
           _col(25) %6.3f `F_I0_10' " " %6.3f `F_I1_10' ///
           _col(39) %6.3f `F_I0_05' " " %6.3f `F_I1_05' ///
           _col(53) %6.3f `F_I0_01' " " %6.3f `F_I1_01' _c
        if `F_pv_I0' < . & `F_pv_I1' < . {
           di as res _col(65) %5.3f `F_pv_I0' " " %5.3f `F_pv_I1'
        }
        else {
           di as txt ""
        }

        // t decision
        if `t_stat' < `t_I1_05' {
            local t_dec "Reject H0"
        }
        else if `t_stat' > `t_I0_05' {
            local t_dec "Fail to reject"
        }
        else {
            local t_dec "Inconclusive"
        }

        di as txt _col(3) "t_DV" _col(15) as res %7.3f `t_stat' ///
           _col(25) %6.3f `t_I0_10' " " %6.3f `t_I1_10' ///
           _col(39) %6.3f `t_I0_05' " " %6.3f `t_I1_05' ///
           _col(53) %6.3f `t_I0_01' " " %6.3f `t_I1_01' _c
        if `t_pv_I0' < . & `t_pv_I1' < . {
           di as res _col(65) %5.3f `t_pv_I0' " " %5.3f `t_pv_I1'
        }
        else {
           di as txt ""
        }

        di as txt _col(3) "F_ind" _col(15) as res %7.3f `Find_stat' ///
           _col(25) as txt "(use bootstrap for critical values)"

        di as txt "  {hline 74}"
        di as txt ""

        // Decision
        di as txt _col(5) "{bf:Decision at 5%:}"
        di as txt _col(7) "F_overall  : " _c
        if "`Fov_dec'" == "Reject H0" {
            di as res "`Fov_dec'"
        }
        else if "`Fov_dec'" == "Inconclusive" {
            di as err "`Fov_dec'"
        }
        else {
            di as txt "`Fov_dec'"
        }
        di as txt _col(7) "t_dependent: " _c
        if "`t_dec'" == "Reject H0" {
            di as res "`t_dec'"
        }
        else if "`t_dec'" == "Inconclusive" {
            di as err "`t_dec'"
        }
        else {
            di as txt "`t_dec'"
        }
        di as txt ""

        local Fov_pval = `F_pv_I1'
        local t_pval = `t_pv_I1'
        local Find_pval = .
    }
    else {
        // Bootstrap cointegration test
        if "`type'" == "mtnardl_mcnown" {
            di as txt _col(5) "{bf:Bootstrap MTNARDL} (McNown, Sam & Goh, 2018)"
        }
        else {
            di as txt _col(5) "{bf:Bootstrap MTNARDL} (Bertelli, Vacca & Zoia, 2022)"
        }
        di as txt ""

        _mtnardl_bootstrap D.`depvar' `regvars', ///
            depvar(`depvar') indepvars(`indepvars') ///
            decomp_vars(`decomp_vars') ///
            levelvars(`levelvars') indeplev(`indeplev') ///
            ecmvar(L.`depvar') bootstrap_type(`type') ///
            reps(`reps') nobs(`nobs') best_p(`best_p') ///
            timevar(`timevar') nq(`nq')

        local Fov_pval = r(Fov_pval)
        local t_pval = r(t_pval)
        local Find_pval = r(Find_pval)
        local Fov_cv01 = r(Fov_cv01)
        local Fov_cv05 = r(Fov_cv05)
        local Fov_cv10 = r(Fov_cv10)
        local t_cv01 = r(t_cv01)
        local t_cv05 = r(t_cv05)
        local t_cv10 = r(t_cv10)
        local Find_cv01 = r(Find_cv01)
        local Find_cv05 = r(Find_cv05)
        local Find_cv10 = r(Find_cv10)

        // Restore estimation after bootstrap
        capture estimates restore _mtnardl_main

        // Bootstrap results table
        di as txt "  {hline 68}"
        di as txt _col(5) "Test" _col(20) "Statistic" _col(32) "p-value" ///
           _col(42) "1% cv" _col(50) "5% cv" _col(58) "10% cv" _col(66) "Decision"
        di as txt "  {hline 68}"

        if `Fov_pval' < 0.05 {
            local Fov_dec "Reject H0"
        }
        else {
            local Fov_dec "Fail to reject"
        }
        di as txt _col(5) "F_overall" _col(18) as res %8.4f `Fov_stat' ///
           _col(30) %8.4f `Fov_pval' ///
           _col(40) %7.3f `Fov_cv01' _col(48) %7.3f `Fov_cv05' ///
           _col(56) %7.3f `Fov_cv10' _col(64) as txt "`Fov_dec'" _c
        _mtnardl_stars `Fov_pval'

        if `t_pval' < 0.05 {
            local t_dec "Reject H0"
        }
        else {
            local t_dec "Fail to reject"
        }
        di as txt _col(5) "t_dependent" _col(18) as res %8.4f `t_stat' ///
           _col(30) %8.4f `t_pval' ///
           _col(40) %7.3f `t_cv01' _col(48) %7.3f `t_cv05' ///
           _col(56) %7.3f `t_cv10' _col(64) as txt "`t_dec'" _c
        _mtnardl_stars `t_pval'

        if `Find_pval' < 0.05 {
            local Find_dec "Reject H0"
        }
        else {
            local Find_dec "Fail to reject"
        }
        di as txt _col(5) "F_indep" _col(18) as res %8.4f `Find_stat' ///
           _col(30) %8.4f `Find_pval' ///
           _col(40) %7.3f `Find_cv01' _col(48) %7.3f `Find_cv05' ///
           _col(56) %7.3f `Find_cv10' _col(64) as txt "`Find_dec'" _c
        _mtnardl_stars `Find_pval'

        di as txt "  {hline 68}"
        di as txt ""

        // Conclusion
        if "`Fov_dec'" == "Reject H0" & "`t_dec'" == "Reject H0" & "`Find_dec'" == "Reject H0" {
            di as res _col(5) "=> COINTEGRATION detected (all three tests reject)"
        }
        else if "`Fov_dec'" != "Reject H0" & "`t_dec'" != "Reject H0" {
            di as txt _col(5) "=> NO COINTEGRATION detected"
        }
        else {
            di as txt _col(5) "=> PARTIAL EVIDENCE: see individual tests"
        }
        di as txt ""
    }

    // =====================================================================
    // TABLE 4: DIAGNOSTICS
    // =====================================================================
    capture estimates restore _mtnardl_main
    if "`nodiag'" == "" {
        di as txt "{hline 78}"
        di as res _col(5) "Table 4: Diagnostic Tests"
        di as txt "{hline 78}"
        _mtnardl_diagtest _mtnardl_resid `nobs' `nparams'
    }

    // =====================================================================
    // TABLE 5: DYNAMIC MULTIPLIERS
    // =====================================================================
    capture estimates restore _mtnardl_main
    if "`nodynmult'" == "" {
        _mtnardl_dynmult, depvar(`depvar') decomp_vars(`decomp_vars') ///
            orig_vars(`decompose') nq(`nq') p(`best_p') horizon(`horizon') ///
            partition_label(`partition_label')
    }

    // =====================================================================
    // TABLE 6: ADVANCED ANALYSIS (Wald tests, asymmetric ratios, etc.)
    // =====================================================================
    capture estimates restore _mtnardl_main
    if "`noadvanced'" == "" {
        _mtnardl_advanced, depvar(`depvar') decomp_vars(`decomp_vars') ///
            orig_vars(`decompose') nq(`nq') p(`best_p') horizon(`horizon') ///
            ecmcoef(`ecm_coef') partition_label(`partition_label')
    }

    // =====================================================================
    // STORE e() RESULTS
    // =====================================================================
    capture estimates drop _mtnardl_main
    ereturn clear
    ereturn post, obs(`nobs') esample(`touse')

    ereturn scalar N = `nobs'
    ereturn scalar best_p = `best_p'
    ereturn scalar nq = `nq'
    ereturn scalar ic_val = scalar(`best_ic_val')
    ereturn scalar aic = `aic_val'
    ereturn scalar bic = `bic_val'
    ereturn scalar ll = `ll'
    ereturn scalar r2 = `r2'
    ereturn scalar r2_a = `r2_a'
    ereturn scalar F = `F_model'
    ereturn scalar df_m = `df_m'
    ereturn scalar df_r = `df_r'
    ereturn scalar rmse = `rmse'
    ereturn scalar Fov = `Fov_stat'
    ereturn scalar t_dep = `t_stat'
    ereturn scalar Find = `Find_stat'
    ereturn scalar ecm_coef = `ecm_coef'

    foreach xv of local all_indepvars {
        local cn14 = subinstr("`xv'", ".", "_", .)
        ereturn scalar best_q_`cn14' = `best_q_`cn14''
    }

    ereturn local cmd "mtnardl"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local decompose "`decompose'"
    ereturn local decomp_vars "`decomp_vars'"
    ereturn local type "`type'"
    ereturn local partition "`partition'"
    ereturn local ic "`ic'"

    // =====================================================================
    // FOOTER
    // =====================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "mtnardl v1.0.0 — Pal & Mitra (2016)"
    di as txt "{hline 78}"

    // Clean up
    capture drop _mtnardl_resid
    // Keep decomposed vars if savedecomp specified
    if "`savedecomp'" == "" {
        foreach dvar of local decompose {
            local cdn = subinstr("`dvar'", ".", "_", .)
            forvalues q = 1/`nq' {
                capture drop _mt_`cdn'_q`q'
            }
        }
    }
    restore
end
