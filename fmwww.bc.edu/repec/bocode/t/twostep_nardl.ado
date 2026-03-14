*! twostep_nardl version 3.0.0  09mar2026
*! Two-Step Estimation of the Nonlinear ARDL Model

program define twostep_nardl , eclass sortpreserve
    version 14

    local cmd = "twostep_nardl"

    if replay() {
        if "`e(cmd)'" != "`cmd'" error 301
        _2snardl_display , `0'
        exit
    }

    local cmdline_orig `"`0'"'

    // =========================================================================
    // SYNTAX PARSING
    // =========================================================================

    capture syntax anything [if] [in] , TRendvar [ * ]
    if !_rc {
        tsset , noquery
        local trendvar `r(timevar)'
        local 0 `"`anything' `if' `in' , `options'"'
    }
    else {
        local trendvaropt "TRendvar(varlist min=1 max=1 numeric)"
    }

    syntax varlist(min=2 numeric ts) [if] [in] , ///
        DECompose(varlist numeric ts)              ///
        [                                          ///
        LAgs(numlist >=0 int miss)                 ///
        MAxlags(numlist >=0 int miss)              ///
        AIC BIC                                    ///
        STEP1(string)                              ///
        ONESTEP                                    ///
        THRESHold(numlist)                         ///
        BWIdth(numlist min=1 max=1 int >0)          ///
        noConstant                                 ///
        `trendvaropt'                              ///
        REStricted                                 ///
        Exog(varlist numeric ts)                   ///
        MULTiplier(numlist min=1 max=1 int >0)     ///
        noCTable                                   ///
        noHEader                                   ///
        noWALDtest                                 ///
        DOTs                                       ///
        Level(cilevel)                             ///
        * ]

    // =========================================================================
    // INPUT VALIDATION
    // =========================================================================

    local numvars  : word count `varlist'
    local numxvars = `numvars' - 1
    forvalues i = 1/`numvars' {
        local var`i' : word `i' of `varlist'
    }
    local depvar `var1'
    local xvars : list varlist - depvar

    // Method: onestep or twostep (default)
    if "`onestep'" != "" {
        local method "onestep"
    }
    else {
        local method "twostep"
    }

    if "`step1'" == "" local step1 "fmols"
    local step1 = lower("`step1'")
    if !inlist("`step1'", "fmols", "ols", "tols", "fmtols") {
        di as error `"step1() must be: fmols, ols, tols, or fmtols"'
        exit 198
    }

    if `numxvars' > 1 & inlist("`step1'", "fmols", "ols") {
        if "`step1'" == "fmols" local step1 "fmtols"
        else                   local step1 "tols"
    }

    // Classify independent variables: decompose vs linear
    local asymmetry `decompose'
    local asym_check : list decompose - xvars
    if "`asym_check'" != "" {
        di as error "decompose() variables must be a subset of independent variables"
        exit 198
    }
    // Linear variables = xvars that are NOT in decompose()
    local linear_vars : list xvars - decompose
    local k_lin : word count `linear_vars'

    local num_asym : word count `asymmetry'
    if "`threshold'" == "" {
        forvalues i = 1/`num_asym' {
            local thresh`i' = 0
        }
    }
    else {
        local num_thresh : word count `threshold'
        if `num_thresh' == 1 {
            forvalues i = 1/`num_asym' {
                local thresh`i' `threshold'
            }
        }
        else if `num_thresh' == `num_asym' {
            forvalues i = 1/`num_asym' {
                local thresh`i' : word `i' of `threshold'
            }
        }
        else {
            di as error "threshold() must have 1 or `num_asym' values"
            exit 125
        }
    }

    if "`bwidth'" == "" local bwidth 0

    if "`aic'" != "" & "`bic'" != "" {
        di as error "aic and bic are mutually exclusive"
        exit 198
    }
    if "`aic'" == "" local ic_type "bic"
    else             local ic_type "aic"

    // Lags - following ardl convention:
    //   omit lags() => all lags optimized via IC
    //   lags(p q)   => fixed lags, no search
    //   lags(. q)   => optimize p, fix q
    local maxlag_default = 4
    local do_lagselect = 0

    if "`lags'" == "" {
        // No lags specified => optimize all
        forvalues i = 1/`numvars' {
            local lag`i' = .
        }
        local do_lagselect = 1
    }
    else {
        local numlagargs : word count `lags'
        if `numlagargs' == 1 {
            forvalues i = 1/`numvars' {
                local lag`i' `lags'
            }
        }
        else if `numlagargs' == `numvars' {
            forvalues i = 1/`numvars' {
                local lag`i' : word `i' of `lags'
            }
        }
        else {
            error 125
        }
        // Check if any lag is missing => partial optimization
        forvalues i = 1/`numvars' {
            if `lag`i'' >= . {
                local do_lagselect = 1
            }
        }
    }

    if "`maxlags'" != "" {
        local nummaxlagsargs : word count `maxlags'
        if `nummaxlagsargs' == 1 {
            forvalues i = 1/`numvars' {
                local maxlag`i' `maxlags'
            }
        }
        else if `nummaxlagsargs' == `numvars' {
            forvalues i = 1/`numvars' {
                local maxlag`i' : word `i' of `maxlags'
            }
        }
        else {
            error 125
        }
    }
    else {
        forvalues i = 1/`numvars' {
            local maxlag`i' = `maxlag_default'
        }
    }

    // Validate: depvar lag must be >= 1
    if `lag1' < . & `lag1' == 0 {
        di as error "Dependent variable must have at least 1 lag"
        error 125
    }
    if `maxlag1' == 0 {
        di as error "maxlags for dependent variable must be >= 1"
        error 125
    }

    // Deterministic terms
    if "`constant'" != "noconstant" local _cons _cons
    local case 3
    if "`constant'" == "noconstant" {
        if "`trendvar'" != "" {
            di as error "trendvar requires a constant"
            exit 198
        }
        if "`restricted'" != "" {
            di as error "restricted requires deterministic terms"
            exit 198
        }
        local case 1
    }
    else {
        if "`trendvar'" == "" {
            local case 3
            if "`restricted'" != "" local case 2
        }
        else {
            local case 5
            if "`restricted'" != "" local case 4
        }
    }

    // =========================================================================
    // MARK SAMPLE & TIME SERIES SETUP
    // =========================================================================

    tsset , noquery
    marksample touse

    // Use maxlags to ensure consistent sample across all candidate models
    local ml1 = cond(`lag1' < ., `lag1', `maxlag1')
    local markoutstr "L(1/`ml1').`depvar'"
    if `numxvars' >= 1 {
        forvalues i = 2/`numvars' {
            local mli = cond(`lag`i'' < ., `lag`i'', `maxlag`i'')
            local markoutstr `markoutstr' L(0/`mli').`var`i''
        }
    }
    markout `touse' `markoutstr' `exog'

    _ts timevar panelvar if `touse', onepanel sort

    _get_diopts diopts , `options'

    // =========================================================================
    // LOAD MATA ROUTINES
    // =========================================================================
    qui findfile _2snardl_mata.do
    qui run "`r(fn)'"

    // =========================================================================
    // PARTIAL SUM DECOMPOSITION
    // =========================================================================

    local asym_pos_vars ""
    local asym_neg_vars ""
    local asym_pos_names ""
    local asym_neg_names ""
    local asym_pos_stored ""
    local asym_neg_stored ""

    local asym_idx = 0
    foreach xv of local xvars {
        local is_asym : list xv & asymmetry
        if "`is_asym'" != "" {
            local ++asym_idx
            local thresh_val = `thresh`asym_idx''

            // Use permanent variables so predict can find them
            local pv "_xpos_nardl_`asym_idx'"
            local nv "_xneg_nardl_`asym_idx'"
            capture drop `pv'
            capture drop `nv'
            qui gen double `pv' = 0 if `touse'
            qui gen double `nv' = 0 if `touse'

            mata: _2snardl_psum("`xv'", "`touse'", "`pv'", "`nv'", `thresh_val')

            local asym_pos_vars `asym_pos_vars' `pv'
            local asym_neg_vars `asym_neg_vars' `nv'
            local asym_pos_names `asym_pos_names' `xv'_pos
            local asym_neg_names `asym_neg_names' `xv'_neg
            local asym_pos_stored `asym_pos_stored' `pv'
            local asym_neg_stored `asym_neg_stored' `nv'
        }
    }

    local k_asym : word count `asymmetry'

    // =========================================================================
    // ESTIMATION - branch on method
    // =========================================================================

    tempname b_lr V_lr tau2 alpha_lr b_lin V_lin
    local lr_colnames "`asym_pos_names' `asym_neg_names'"
    local lr_lin_colnames "`linear_vars'"

    if "`method'" == "twostep" {

    // =========================================================================
    // STEP 1: LONG-RUN PARAMETER ESTIMATION (Two-Step only)
    // =========================================================================

    // Use permanent variable for ECT so _predict can find it
    capture drop _ect_nardl
    qui gen double _ect_nardl = . if `touse'
    local ect_var "_ect_nardl"

    if `k_asym' == 1 {
        local use_fmols = ("`step1'" == "fmols")
        local xv1 : word 1 of `asymmetry'
        local pv1 : word 1 of `asym_pos_vars'
        local nv1 : word 1 of `asym_neg_vars'

        mata: _2snardl_run_step1_k1("`depvar'", "`pv1'", "`xv1'", "`nv1'", "`linear_vars'", "`touse'", `use_fmols', `bwidth', "`b_lr'", "`V_lr'", "`tau2'", "`alpha_lr'", "`ect_var'", "`b_lin'", "`V_lin'")

        matrix colnames `b_lr' = `lr_colnames'
        matrix colnames `V_lr' = `lr_colnames'
        matrix rownames `V_lr' = `lr_colnames'
        if `k_lin' > 0 {
            matrix colnames `b_lin' = `lr_lin_colnames'
            matrix colnames `V_lin' = `lr_lin_colnames'
            matrix rownames `V_lin' = `lr_lin_colnames'
        }
    }
    else {
        local use_fm = ("`step1'" == "fmtols")

        mata: _2snardl_run_step1_kn("`depvar'", "`asym_pos_vars'", "`asymmetry'", "`asym_neg_vars'", "`linear_vars'", "`touse'", `use_fm', `bwidth', "`b_lr'", "`V_lr'", "`tau2'", "`alpha_lr'", "`ect_var'", "`b_lin'", "`V_lin'")

        matrix colnames `b_lr' = `lr_colnames'
        matrix colnames `V_lr' = `lr_colnames'
        matrix rownames `V_lr' = `lr_colnames'
        if `k_lin' > 0 {
            matrix colnames `b_lin' = `lr_lin_colnames'
            matrix colnames `V_lin' = `lr_lin_colnames'
            matrix rownames `V_lin' = `lr_lin_colnames'
        }
    }

    // =========================================================================
    // STEP 2: SHORT-RUN PARAMETER ESTIMATION (Two-Step)
    // =========================================================================

    local regdepvar "D.`depvar'"

    // -----------------------------------------------------------------
    // LAG SELECTION (if do_lagselect == 1)
    // -----------------------------------------------------------------
    if `do_lagselect' {
        // Determine search ranges for each variable
        local search_lo1 = cond(`lag1' < ., `lag1', 1)
        local search_hi1 = cond(`lag1' < ., `lag1', `maxlag1')
        forvalues i = 2/`numvars' {
            local search_lo`i' = cond(`lag`i'' < ., `lag`i'', 0)
            local search_hi`i' = cond(`lag`i'' < ., `lag`i'', `maxlag`i'')
        }

        // Count total combinations
        local numcombs = `search_hi1' - `search_lo1' + 1
        forvalues i = 2/`numvars' {
            local numcombs = `numcombs' * (`search_hi`i'' - `search_lo`i'' + 1)
        }

        if "`dots'" != "" {
            di as text _n "  Lag selection (" as result upper("`ic_type'") as text ///
               "): searching " as result "`numcombs'" as text " combinations..."
        }

        // Grid search
        tempname best_ic
        scalar `best_ic' = .
        local best_lag1 = `search_lo1'
        forvalues i = 2/`numvars' {
            local best_lag`i' = `search_lo`i''
        }
        local n_searched = 0

        // Nested loops: depvar p x x-var q's
        // For simplicity, handle up to 5 x-variables with recursive-style iteration
        // We iterate depvar lag in outer loop, then iterate x-var lags

        forvalues try_p = `search_lo1'/`search_hi1' {
            // Build the search for x-variable lags
            // Since Stata doesn't have dynamic nesting, we use a single
            // loop over combination index for the x-variables

            // Compute x-variable combinations
            local n_xcomb = 1
            forvalues i = 2/`numvars' {
                local n_xcomb = `n_xcomb' * (`search_hi`i'' - `search_lo`i'' + 1)
            }

            forvalues xidx = 0/`=`n_xcomb'-1' {
                // Decode xidx into per-variable lags
                local xidx_tmp = `xidx'
                forvalues i = 2/`numvars' {
                    local nlevels_i = `search_hi`i'' - `search_lo`i'' + 1
                    local try_q`i' = `search_lo`i'' + mod(`xidx_tmp', `nlevels_i')
                    local xidx_tmp = int(`xidx_tmp' / `nlevels_i')
                }

                // Build SR regressor list for this combination
                local try_sr "L.`ect_var'"

                // Lagged Delta_y
                local try_plag = `try_p' - 1
                if `try_plag' > 0 {
                    local try_sr "`try_sr' L(1/`try_plag')D.`depvar'"
                }

                // Delta_x_pos and Delta_x_neg
                local try_aidx = 0
                foreach xv of local asymmetry {
                    local ++try_aidx
                    local try_xi = 0
                    forvalues j = 2/`numvars' {
                        if "`var`j''" == "`xv'" local try_xi = `j'
                    }
                    local try_qt = `try_q`try_xi''
                    local try_pv : word `try_aidx' of `asym_pos_vars'
                    local try_nv : word `try_aidx' of `asym_neg_vars'

                    if `try_qt' > 0 {
                        local try_sr "`try_sr' L(0/`=`try_qt'-1')D.`try_pv'"
                        local try_sr "`try_sr' L(0/`=`try_qt'-1')D.`try_nv'"
                    }
                    else {
                        local try_sr "`try_sr' D.`try_pv'"
                        local try_sr "`try_sr' D.`try_nv'"
                    }
                }

                // Exogenous and deterministic
                if "`exog'" != "" {
                    local try_sr "`try_sr' `exog'"
                }
                if "`trendvar'" != "" & "`restricted'" == "" {
                    local try_sr "`try_sr' `trendvar'"
                }

                // Run regression
                capture qui regress `regdepvar' `try_sr' if `touse' , `constant'
                if _rc != 0 continue

                local ++n_searched

                // Compute IC
                local try_N = e(N)
                local try_k = e(df_m) + 1
                local try_ll = e(ll)
                if "`ic_type'" == "aic" {
                    local try_ic = -2 * `try_ll' + 2 * `try_k'
                }
                else {
                    local try_ic = -2 * `try_ll' + `try_k' * ln(`try_N')
                }

                // Update best
                if `try_ic' < scalar(`best_ic') | missing(scalar(`best_ic')) {
                    scalar `best_ic' = `try_ic'
                    local best_lag1 = `try_p'
                    forvalues i = 2/`numvars' {
                        local best_lag`i' = `try_q`i''
                    }
                }
            }
        }

        // Set optimal lags
        forvalues i = 1/`numvars' {
            local lag`i' = `best_lag`i''
        }

        if "`dots'" != "" {
            di as text "  Optimal: ARDL(" _c
            forvalues i = 1/`numvars' {
                if `i' > 1 di as text "," _c
                di as result "`lag`i''" _c
            }
            di as text ")" _col(40) as text upper("`ic_type'") " = " ///
               as result %10.3f scalar(`best_ic')
        }
    }

    // -----------------------------------------------------------------
    // Build final SR regressor list with selected/fixed lags
    // -----------------------------------------------------------------
    local sr_indepvars ""

    // Lagged ECT
    local sr_indepvars "L.`ect_var'"

    // Lagged Delta_y
    local p_lag = `lag1' - 1
    if `p_lag' > 0 {
        local sr_indepvars "`sr_indepvars' L(1/`p_lag')D.`depvar'"
    }

    // Delta_x_pos and Delta_x_neg with lags - compute q_lag
    // q_lag must be >= 1 because contemporaneous D.x_pos/D.x_neg are always included
    local q_lag = 1
    local asym_idx2 = 0
    foreach xv of local asymmetry {
        local ++asym_idx2
        local xi = 0
        forvalues j = 2/`numvars' {
            if "`var`j''" == "`xv'" {
                local xi = `j'
            }
        }
        if `xi' == 0 {
            di as error "Internal error: variable `xv' not in varlist"
            exit 498
        }
        local q_this = `lag`xi''
        if `q_this' > `q_lag' local q_lag = `q_this'

        // Get the permanent partial sum variable names
        local pv_i : word `asym_idx2' of `asym_pos_vars'
        local nv_i : word `asym_idx2' of `asym_neg_vars'

        if `q_this' > 0 {
            local sr_indepvars "`sr_indepvars' L(0/`=`q_this'-1')D.`pv_i'"
            local sr_indepvars "`sr_indepvars' L(0/`=`q_this'-1')D.`nv_i'"
        }
        else {
            local sr_indepvars "`sr_indepvars' D.`pv_i'"
            local sr_indepvars "`sr_indepvars' D.`nv_i'"
        }
    }

    // Linear variable differences with lags (if any)
    local n_lin_sr = 0
    if `k_lin' > 0 {
        local lin_idx2 = 0
        foreach zv of local linear_vars {
            local ++lin_idx2
            // Find this variable's index in the varlist
            local zi = 0
            forvalues j = 2/`numvars' {
                if "`var`j''" == "`zv'" {
                    local zi = `j'
                }
            }
            local r_this = `lag`zi''
            local r_use = max(`r_this', 1)
            local n_lin_sr = `n_lin_sr' + `r_use'
            if `r_this' > 0 {
                local sr_indepvars "`sr_indepvars' L(0/`=`r_this'-1')D.`zv'"
            }
            else {
                local sr_indepvars "`sr_indepvars' D.`zv'"
            }
        }
    }

    if "`exog'" != "" {
        local sr_indepvars "`sr_indepvars' `exog'"
    }

    if "`trendvar'" != "" & "`restricted'" == "" {
        local sr_indepvars "`sr_indepvars' `trendvar'"
    }

    // Run Step 2 OLS with final (optimal) lags
    qui regress `regdepvar' `sr_indepvars' if `touse' , `constant'

    tempname b_sr V_sr N_obs df_m df_r r2 r2_a rmse_val ll_val rss_val F_val
    matrix `b_sr' = e(b)
    matrix `V_sr' = e(V)
    scalar `N_obs'   = e(N)
    scalar `df_m'    = e(df_m)
    scalar `df_r'    = e(df_r)
    scalar `r2'      = e(r2)
    scalar `r2_a'    = e(r2_a)
    scalar `rmse_val' = e(rmse)
    scalar `ll_val'   = e(ll)
    scalar `rss_val'  = e(rss)
    scalar `F_val'    = e(F)

    tempname rho_hat
    scalar `rho_hat' = _b[L.`ect_var']

    // HC-robust VCE for Wald tests
    tempname V_sr_hc
    qui regress `regdepvar' `sr_indepvars' if `touse' , `constant' vce(robust)
    matrix `V_sr_hc' = e(V)

    // Re-run standard OLS
    qui regress `regdepvar' `sr_indepvars' if `touse' , `constant'

    // =========================================================================
    // WALD TESTS FOR ASYMMETRY
    // =========================================================================

    tempname W_lr p_lr W_sr p_sr W_impact p_impact

    if "`waldtest'" != "nowaldtest" {
        if `k_asym' == 1 {
            mata: _2snardl_run_wald_lr_k1("`b_lr'", "`V_lr'", "`W_lr'", "`p_lr'")
        }
        else {
            mata: _2snardl_run_wald_lr_kn("`b_lr'", "`V_lr'", `k_asym', "`W_lr'", "`p_lr'")
        }

        mata: _2snardl_run_wald_sr("`b_sr'", "`V_sr_hc'", `p_lag', `q_lag', `k_asym', `n_lin_sr', "additive", "`W_sr'", "`p_sr'")

        mata: _2snardl_run_wald_sr("`b_sr'", "`V_sr_hc'", `p_lag', `q_lag', `k_asym', `n_lin_sr', "impact", "`W_impact'", "`p_impact'")
    }

    // BDM t-test
    tempname t_bdm F_pss_val
    scalar `t_bdm' = _b[L.`ect_var'] / _se[L.`ect_var']
    // PSS F-test: for two-step, F_pss = t^2 (single level regressor: L.ect)
    scalar `F_pss_val' = (scalar(`t_bdm'))^2

    scalar `tau2'    = 0
    scalar `alpha_lr' = 0

    } // end if twostep

    // =========================================================================
    // ONE-STEP NARDL (Shin, Yu & Greenwood-Nimmo 2014)
    // =========================================================================

    else {

    local regdepvar "D.`depvar'"
    local ect_var "_ect_nardl"
    capture drop _ect_nardl

    // -----------------------------------------------------------------
    // LAG SELECTION FOR ONE-STEP (if do_lagselect == 1)
    // -----------------------------------------------------------------
    if `do_lagselect' {
        local search_lo1 = cond(`lag1' < ., `lag1', 1)
        local search_hi1 = cond(`lag1' < ., `lag1', `maxlag1')
        forvalues i = 2/`numvars' {
            local search_lo`i' = cond(`lag`i'' < ., `lag`i'', 0)
            local search_hi`i' = cond(`lag`i'' < ., `lag`i'', `maxlag`i'')
        }

        local numcombs = `search_hi1' - `search_lo1' + 1
        forvalues i = 2/`numvars' {
            local numcombs = `numcombs' * (`search_hi`i'' - `search_lo`i'' + 1)
        }

        if "`dots'" != "" {
            di as text _n "  Lag selection (" as result upper("`ic_type'") as text ///
               "): searching " as result "`numcombs'" as text " combinations..."
        }

        tempname best_ic
        scalar `best_ic' = .
        local best_lag1 = `search_lo1'
        forvalues i = 2/`numvars' {
            local best_lag`i' = `search_lo`i''
        }

        forvalues try_p = `search_lo1'/`search_hi1' {
            local n_xcomb = 1
            forvalues i = 2/`numvars' {
                local n_xcomb = `n_xcomb' * (`search_hi`i'' - `search_lo`i'' + 1)
            }

            forvalues xidx = 0/`=`n_xcomb'-1' {
                local xidx_tmp = `xidx'
                forvalues i = 2/`numvars' {
                    local nlevels_i = `search_hi`i'' - `search_lo`i'' + 1
                    local try_q`i' = `search_lo`i'' + mod(`xidx_tmp', `nlevels_i')
                    local xidx_tmp = int(`xidx_tmp' / `nlevels_i')
                }

                // Build one-step regressors for this combo
                local try_sr "L.`depvar'"
                // Level x terms
                local try_aidx = 0
                foreach xv of local asymmetry {
                    local ++try_aidx
                    local try_pv : word `try_aidx' of `asym_pos_vars'
                    local try_nv : word `try_aidx' of `asym_neg_vars'
                    local try_sr "`try_sr' L.`try_pv' L.`try_nv'"
                }
                // Level linear variables
                if `k_lin' > 0 {
                    foreach zv of local linear_vars {
                        local try_sr "`try_sr' L.`zv'"
                    }
                }
                // Lagged Delta_y
                local try_plag = `try_p' - 1
                if `try_plag' > 0 {
                    local try_sr "`try_sr' L(1/`try_plag')D.`depvar'"
                }
                // Delta_x_pos and Delta_x_neg
                local try_aidx = 0
                foreach xv of local asymmetry {
                    local ++try_aidx
                    local try_xi = 0
                    forvalues j = 2/`numvars' {
                        if "`var`j''" == "`xv'" local try_xi = `j'
                    }
                    local try_qt = `try_q`try_xi''
                    local try_pv : word `try_aidx' of `asym_pos_vars'
                    local try_nv : word `try_aidx' of `asym_neg_vars'
                    if `try_qt' > 0 {
                        local try_sr "`try_sr' L(0/`=`try_qt'-1')D.`try_pv'"
                        local try_sr "`try_sr' L(0/`=`try_qt'-1')D.`try_nv'"
                    }
                    else {
                        local try_sr "`try_sr' D.`try_pv'"
                        local try_sr "`try_sr' D.`try_nv'"
                    }
                }
                // Differenced linear variables
                if `k_lin' > 0 {
                    foreach zv of local linear_vars {
                        local zi = 0
                        forvalues j = 2/`numvars' {
                            if "`var`j''" == "`zv'" local zi = `j'
                        }
                        local try_rz = `try_q`zi''
                        if `try_rz' > 0 {
                            local try_sr "`try_sr' L(0/`=`try_rz'-1')D.`zv'"
                        }
                        else {
                            local try_sr "`try_sr' D.`zv'"
                        }
                    }
                }
                // Exogenous and deterministic
                if "`exog'" != "" {
                    local try_sr "`try_sr' `exog'"
                }
                if "`trendvar'" != "" & "`restricted'" == "" {
                    local try_sr "`try_sr' `trendvar'"
                }

                capture qui regress `regdepvar' `try_sr' if `touse' , `constant'
                if _rc != 0 continue

                local try_N = e(N)
                local try_k = e(df_m) + 1
                local try_ll = e(ll)
                if "`ic_type'" == "aic" {
                    local try_ic = -2 * `try_ll' + 2 * `try_k'
                }
                else {
                    local try_ic = -2 * `try_ll' + `try_k' * ln(`try_N')
                }

                if `try_ic' < scalar(`best_ic') | missing(scalar(`best_ic')) {
                    scalar `best_ic' = `try_ic'
                    local best_lag1 = `try_p'
                    forvalues i = 2/`numvars' {
                        local best_lag`i' = `try_q`i''
                    }
                }
            }
        }

        // Set optimal lags
        forvalues i = 1/`numvars' {
            local lag`i' = `best_lag`i''
        }

        if "`dots'" != "" {
            di as text "  Optimal: ARDL(" _c
            forvalues i = 1/`numvars' {
                if `i' > 1 di as text "," _c
                di as result "`lag`i''" _c
            }
            di as text ")" _col(40) as text upper("`ic_type'") " = " ///
               as result %10.3f scalar(`best_ic')
        }
    }

    // Build one-step regression:
    // Dy = c + rho*L.y + theta_pos*L.x_pos + theta_neg*L.x_neg
    //      + phi_j*L(j).D.y + pi_pos*L(j).D.x_pos + pi_neg*L(j).D.x_neg
    local os_regressors "L.`depvar'"

    // Level x terms (for LR derivation)
    foreach xv of local asymmetry {
        local asym_idx3 = 0
        forvalues ii = 1/`num_asym' {
            local av : word `ii' of `asymmetry'
            if "`av'" == "`xv'" local asym_idx3 = `ii'
        }
        local pv_i : word `asym_idx3' of `asym_pos_vars'
        local nv_i : word `asym_idx3' of `asym_neg_vars'
        local os_regressors "`os_regressors' L.`pv_i' L.`nv_i'"
    }

    // Level linear variables (for LR derivation)
    if `k_lin' > 0 {
        foreach zv of local linear_vars {
            local os_regressors "`os_regressors' L.`zv'"
        }
    }

    // Lagged Dy
    local p_lag = `lag1' - 1
    if `p_lag' > 0 {
        local os_regressors "`os_regressors' L(1/`p_lag')D.`depvar'"
    }

    // Delta x_pos, x_neg with lags
    local q_lag = 1
    local asym_idx2 = 0
    foreach xv of local asymmetry {
        local ++asym_idx2
        local xi = 0
        forvalues j = 2/`numvars' {
            if "`var`j''" == "`xv'" local xi = `j'
        }
        local q_this = `lag`xi''
        if `q_this' > `q_lag' local q_lag = `q_this'

        local pv_i : word `asym_idx2' of `asym_pos_vars'
        local nv_i : word `asym_idx2' of `asym_neg_vars'

        if `q_this' > 0 {
            local os_regressors "`os_regressors' L(0/`=`q_this'-1')D.`pv_i'"
            local os_regressors "`os_regressors' L(0/`=`q_this'-1')D.`nv_i'"
        }
        else {
            local os_regressors "`os_regressors' D.`pv_i'"
            local os_regressors "`os_regressors' D.`nv_i'"
        }
    }

    // Differenced linear variables with lags
    local n_lin_sr = 0
    if `k_lin' > 0 {
        foreach zv of local linear_vars {
            local zi = 0
            forvalues j = 2/`numvars' {
                if "`var`j''" == "`zv'" local zi = `j'
            }
            local r_this = `lag`zi''
            local r_use = max(`r_this', 1)
            local n_lin_sr = `n_lin_sr' + `r_use'
            if `r_this' > 0 {
                local os_regressors "`os_regressors' L(0/`=`r_this'-1')D.`zv'"
            }
            else {
                local os_regressors "`os_regressors' D.`zv'"
            }
        }
    }

    if "`exog'" != "" {
        local os_regressors "`os_regressors' `exog'"
    }
    if "`trendvar'" != "" & "`restricted'" == "" {
        local os_regressors "`os_regressors' `trendvar'"
    }

    // Run one-step OLS
    qui regress `regdepvar' `os_regressors' if `touse' , `constant'

    tempname b_sr V_sr N_obs df_m df_r r2 r2_a rmse_val ll_val rss_val F_val
    matrix `b_sr' = e(b)
    matrix `V_sr' = e(V)
    scalar `N_obs'   = e(N)
    scalar `df_m'    = e(df_m)
    scalar `df_r'    = e(df_r)
    scalar `r2'      = e(r2)
    scalar `r2_a'    = e(r2_a)
    scalar `rmse_val' = e(rmse)
    scalar `ll_val'   = e(ll)
    scalar `rss_val'  = e(rss)
    scalar `F_val'    = e(F)

    tempname rho_hat
    scalar `rho_hat' = _b[L.`depvar']

    // BDM t-test (on L.depvar for one-step)
    tempname t_bdm F_pss_val
    scalar `t_bdm' = _b[L.`depvar'] / _se[L.`depvar']

    // PSS F-test: joint test on level variables (matching ardl.ado approach)
    local level_test_vars "L.`depvar'"
    foreach pv_t of local asym_pos_vars {
        local level_test_vars "`level_test_vars' L.`pv_t'"
    }
    foreach nv_t of local asym_neg_vars {
        local level_test_vars "`level_test_vars' L.`nv_t'"
    }
    if `k_lin' > 0 {
        foreach zv of local linear_vars {
            local level_test_vars "`level_test_vars' L.`zv'"
        }
    }
    qui test `level_test_vars'
    scalar `F_pss_val' = r(F)

    // Derive LR coefficients: beta = -theta/rho via nlcom
    // theta_pos = _b[L.x_pos], theta_neg = _b[L.x_neg], rho = _b[L.y]
    local nlcom_expr ""
    local nlcom_idx = 0
    foreach xv of local asymmetry {
        local asym_idx4 = 0
        forvalues ii = 1/`num_asym' {
            local av : word `ii' of `asymmetry'
            if "`av'" == "`xv'" local asym_idx4 = `ii'
        }
        local pv_i : word `asym_idx4' of `asym_pos_vars'
        local nv_i : word `asym_idx4' of `asym_neg_vars'
        local pn   : word `asym_idx4' of `asym_pos_names'
        local nn   : word `asym_idx4' of `asym_neg_names'

        local ++nlcom_idx
        if `nlcom_idx' > 1 local nlcom_expr "`nlcom_expr' "
        local nlcom_expr "`nlcom_expr' (`pn': -_b[L.`pv_i'] / _b[L.`depvar'])"
        local nlcom_expr "`nlcom_expr' (`nn': -_b[L.`nv_i'] / _b[L.`depvar'])"
    }

    // Linear variable LR coefficients: beta_j = -_b[L.z_j] / _b[L.y]
    if `k_lin' > 0 {
        foreach zv of local linear_vars {
            local ++nlcom_idx
            if `nlcom_idx' > 1 local nlcom_expr "`nlcom_expr' "
            local nlcom_expr "`nlcom_expr' (`zv': -_b[L.`zv'] / _b[L.`depvar'])"
        }
    }

    qui nlcom `nlcom_expr'

    // Split into asymmetric LR and linear LR
    local n_lr_nlcom = 2 * `k_asym'
    matrix `b_lr' = r(b)[1, 1..`n_lr_nlcom']
    matrix `V_lr' = r(V)[1..`n_lr_nlcom', 1..`n_lr_nlcom']
    matrix colnames `b_lr' = `lr_colnames'
    matrix colnames `V_lr' = `lr_colnames'
    matrix rownames `V_lr' = `lr_colnames'
    if `k_lin' > 0 {
        matrix `b_lin' = r(b)[1, `=`n_lr_nlcom'+1'..`=`n_lr_nlcom'+`k_lin'']
        matrix `V_lin' = r(V)[`=`n_lr_nlcom'+1'..`=`n_lr_nlcom'+`k_lin'', `=`n_lr_nlcom'+1'..`=`n_lr_nlcom'+`k_lin'']
        matrix colnames `b_lin' = `lr_lin_colnames'
        matrix colnames `V_lin' = `lr_lin_colnames'
        matrix rownames `V_lin' = `lr_lin_colnames'
    }
    else {
        // No linear variables — b_lin/V_lin not needed (checked via k_lin > 0 downstream)
    }

    scalar `tau2'     = 0
    scalar `alpha_lr' = 0

    // HC-robust VCE for Wald tests
    tempname V_sr_hc
    qui regress `regdepvar' `os_regressors' if `touse' , `constant' vce(robust)
    matrix `V_sr_hc' = e(V)

    // Re-run standard OLS to restore e()
    qui regress `regdepvar' `os_regressors' if `touse' , `constant'

    // Build sr_indepvars for post-estimation compatibility
    local sr_indepvars "`os_regressors'"

    // Wald tests
    tempname W_lr p_lr W_sr p_sr W_impact p_impact

    if "`waldtest'" != "nowaldtest" {
        // LR Wald test uses nlcom-derived LR coefficients
        if `k_asym' == 1 {
            mata: _2snardl_run_wald_lr_k1("`b_lr'", "`V_lr'", "`W_lr'", "`p_lr'")
        }
        else {
            mata: _2snardl_run_wald_lr_kn("`b_lr'", "`V_lr'", `k_asym', "`W_lr'", "`p_lr'")
        }

        // SR Wald tests - extract SR portion to match two-step layout
        // One-step b_sr: [L.y, L.x_pos, L.x_neg, L1Dy..., D.x_pos..., D.x_neg..., exog, _cons]
        // Two-step b_sr: [ECT, L1Dy..., D.x_pos..., D.x_neg..., exog, _cons]
        // We remap: L.y -> ECT position, skip L.x_pos/L.x_neg
        local os_levels = 1 + 2 * `k_asym' + `k_lin'
        local n_os = colsof(`b_sr')
        local n_sr_part = `n_os' - `os_levels'
        tempname b_sr_compat V_sr_compat
        // Build compatible vector: [rho, SR_coeffs_after_levels]
        matrix `b_sr_compat' = `b_sr'[1, 1], `b_sr'[1, `=`os_levels'+1'..`n_os']
        matrix `V_sr_compat' = J(1 + `n_sr_part', 1 + `n_sr_part', 0)
        matrix `V_sr_compat'[1, 1] = `V_sr_hc'[1, 1]
        forvalues i = 1/`n_sr_part' {
            matrix `V_sr_compat'[1, 1+`i'] = `V_sr_hc'[1, `os_levels'+`i']
            matrix `V_sr_compat'[1+`i', 1] = `V_sr_hc'[`os_levels'+`i', 1]
            forvalues j = 1/`n_sr_part' {
                matrix `V_sr_compat'[1+`i', 1+`j'] = `V_sr_hc'[`os_levels'+`i', `os_levels'+`j']
            }
        }
        capture mata: _2snardl_run_wald_sr("`b_sr_compat'", "`V_sr_compat'", `p_lag', `q_lag', `k_asym', `n_lin_sr', "additive", "`W_sr'", "`p_sr'")
        capture mata: _2snardl_run_wald_sr("`b_sr_compat'", "`V_sr_compat'", `p_lag', `q_lag', `k_asym', `n_lin_sr', "impact", "`W_impact'", "`p_impact'")
    }

    // Generate ECT for post-estimation
    qui gen double _ect_nardl = . if `touse'

    } // end else (onestep)

    // =========================================================================
    // ASSEMBLE AND POST RESULTS
    // =========================================================================

    tempname b_combined V_combined

    local sr_names : colnames `b_sr'
    local n_sr = colsof(`b_sr')

    // ADJ coefficient
    tempname b_adj V_adj
    matrix `b_adj' = `b_sr'[1, 1]
    matrix colnames `b_adj' = L.ect

    // SR coefficients (after ADJ term, skipping level x terms for one-step)
    tempname b_sr2 V_sr2
    if "`method'" == "onestep" {
        // One-step layout: [L.y, L.x_pos, L.x_neg, L.z, SR_terms...]
        local os_skip = 1 + 2 * `k_asym' + `k_lin'
        if `n_sr' > `os_skip' {
            matrix `b_sr2' = `b_sr'[1, `=`os_skip'+1'..`n_sr']
            matrix `V_sr2' = `V_sr'[`=`os_skip'+1'..`n_sr', `=`os_skip'+1'..`n_sr']
        }
        else {
            matrix `b_sr2' = J(1, 0, .)
        }
    }
    else {
        // Two-step layout: [L.ect, SR_terms...]
        if `n_sr' > 1 {
            matrix `b_sr2' = `b_sr'[1, 2..`n_sr']
            matrix `V_sr2' = `V_sr'[2..`n_sr', 2..`n_sr']
        }
        else {
            matrix `b_sr2' = J(1, 0, .)
        }
    }

    // Combined: [ADJ, LR_asym, LR_lin, SR]
    if `k_lin' > 0 {
        matrix `b_combined' = `b_adj', `b_lr', `b_lin', `b_sr2'
    }
    else {
        matrix `b_combined' = `b_adj', `b_lr', `b_sr2'
    }

    local n_adj = 1
    local n_lr  = colsof(`b_lr')
    local n_lin_lr = `k_lin'
    local n_lr_total = `n_lr' + `n_lin_lr'
    local n_sr2 = colsof(`b_sr2')
    local n_total = `n_adj' + `n_lr_total' + `n_sr2'

    matrix `V_combined' = J(`n_total', `n_total', 0)

    // ADJ variance
    matrix `V_combined'[1, 1] = `V_sr'[1, 1]

    // LR asymmetric variance
    forvalues i = 1/`n_lr' {
        forvalues j = 1/`n_lr' {
            matrix `V_combined'[`n_adj'+`i', `n_adj'+`j'] = `V_lr'[`i', `j']
        }
    }

    // LR linear variance
    if `n_lin_lr' > 0 {
        forvalues i = 1/`n_lin_lr' {
            forvalues j = 1/`n_lin_lr' {
                matrix `V_combined'[`n_adj'+`n_lr'+`i', `n_adj'+`n_lr'+`j'] = `V_lin'[`i', `j']
            }
        }
    }

    // SR variance + cross-cov with ADJ
    if `n_sr2' > 0 {
        // Offset into V_sr for SR portion
        local sr_offset = cond("`method'" == "onestep", 1 + 2 * `k_asym' + `k_lin', 1)
        forvalues i = 1/`n_sr2' {
            forvalues j = 1/`n_sr2' {
                matrix `V_combined'[`n_adj'+`n_lr_total'+`i', `n_adj'+`n_lr_total'+`j'] = `V_sr2'[`i', `j']
            }
            matrix `V_combined'[1, `n_adj'+`n_lr_total'+`i'] = `V_sr'[1, `sr_offset'+`i']
            matrix `V_combined'[`n_adj'+`n_lr_total'+`i', 1] = `V_sr'[`sr_offset'+`i', 1]
        }
    }

    // Equation labels
    local eqnames "ADJ"
    forvalues i = 1/`n_lr' {
        local eqnames `eqnames' LR
    }
    forvalues i = 1/`n_lin_lr' {
        local eqnames `eqnames' LR
    }
    forvalues i = 1/`n_sr2' {
        local eqnames `eqnames' SR
    }

    // Build proper SR column names with actual variable names
    local sr2_colnames ""
    if `n_sr2' > 0 {
        // Lags of dependent variable
        forvalues j = 1/`p_lag' {
            local sr2_colnames "`sr2_colnames' LD`j'.`depvar'"
        }
        // SR pi coefficients
        foreach xv of local asymmetry {
            local xi = 0
            forvalues j = 2/`numvars' {
                if "`var`j''" == "`xv'" local xi = `j'
            }
            local q_this = `lag`xi''
            local q_use = max(`q_this', 1)
            forvalues j = 0/`=`q_use'-1' {
                if `j' == 0 local sr2_colnames "`sr2_colnames' D.`xv'_pos"
                else        local sr2_colnames "`sr2_colnames' LD`j'.`xv'_pos"
            }
            forvalues j = 0/`=`q_use'-1' {
                if `j' == 0 local sr2_colnames "`sr2_colnames' D.`xv'_neg"
                else        local sr2_colnames "`sr2_colnames' LD`j'.`xv'_neg"
            }
        }
        // SR linear variable difference coefficients
        if `k_lin' > 0 {
            foreach zv of local linear_vars {
                local zi = 0
                forvalues j = 2/`numvars' {
                    if "`var`j''" == "`zv'" local zi = `j'
                }
                local r_this = `lag`zi''
                local r_use = max(`r_this', 1)
                forvalues j = 0/`=`r_use'-1' {
                    if `j' == 0 local sr2_colnames "`sr2_colnames' D.`zv'"
                    else        local sr2_colnames "`sr2_colnames' LD`j'.`zv'"
                }
            }
        }
        // Exogenous and trend
        if "`exog'" != "" {
            foreach v of local exog {
                local sr2_colnames "`sr2_colnames' `v'"
            }
        }
        if "`trendvar'" != "" & "`restricted'" == "" {
            local sr2_colnames "`sr2_colnames' `trendvar'"
        }
        if "`constant'" != "noconstant" {
            local sr2_colnames "`sr2_colnames' _cons"
        }
    }

    local combined_names "L.ect `lr_colnames'"
    if `k_lin' > 0 {
        local combined_names "`combined_names' `lr_lin_colnames'"
    }
    if `n_sr2' > 0 {
        local combined_names "`combined_names' `sr2_colnames'"
    }

    matrix colnames `b_combined' = `combined_names'
    matrix colnames `V_combined' = `combined_names'
    matrix rownames `V_combined' = `combined_names'
    matrix coleq `b_combined' = `eqnames'
    matrix coleq `V_combined' = `eqnames'
    matrix roweq `V_combined' = `eqnames'

    // Post results
    tempvar esample
    qui gen byte `esample' = e(sample)
    local dof = `df_r'
    ereturn post `b_combined' `V_combined', esample(`esample') depname(D.`depvar') dof(`dof')

    // Scalars
    ereturn scalar N     = `N_obs'
    ereturn scalar df_m  = `df_m'
    ereturn scalar df_r  = `df_r'
    ereturn scalar r2    = `r2'
    ereturn scalar r2_a  = `r2_a'
    ereturn scalar rmse  = `rmse_val'
    ereturn scalar ll    = `ll_val'
    ereturn scalar rss   = `rss_val'
    ereturn scalar F     = `F_val'
    ereturn scalar tau2  = `tau2'
    ereturn scalar rho   = `rho_hat'
    ereturn scalar t_bdm = `t_bdm'
    ereturn scalar F_pss = `F_pss_val'
    ereturn scalar case  = `case'
    ereturn scalar k     = `k_asym'
    ereturn scalar p_lag = `p_lag'
    ereturn scalar q_lag = `q_lag'
    ereturn scalar alpha_lr = `alpha_lr'

    // Lag selection results
    if `do_lagselect' {
        ereturn scalar ic_opt    = scalar(`best_ic')
        ereturn scalar numcombs  = `numcombs'
        ereturn local  ic_type   "`ic_type'"
        ereturn scalar lagselect = 1
    }
    else {
        ereturn scalar lagselect = 0
    }

    // Store lags and maxlags matrices
    tempname lagsmat maxlagsmat
    matrix `lagsmat'    = J(1, `numvars', 0)
    matrix `maxlagsmat' = J(1, `numvars', 0)
    forvalues i = 1/`numvars' {
        matrix `lagsmat'[1, `i']    = `lag`i''
        matrix `maxlagsmat'[1, `i'] = `maxlag`i''
    }
    matrix colnames `lagsmat'    = `varlist'
    matrix colnames `maxlagsmat' = `varlist'
    ereturn matrix lags    = `lagsmat'
    ereturn matrix maxlags = `maxlagsmat'

    if "`waldtest'" != "nowaldtest" {
        ereturn scalar W_lr     = `W_lr'
        ereturn scalar p_lr     = `p_lr'
        ereturn scalar W_sr     = `W_sr'
        ereturn scalar p_sr     = `p_sr'
        ereturn scalar W_impact = `W_impact'
        ereturn scalar p_impact = `p_impact'
    }

    // Matrices
    ereturn matrix b_lr  = `b_lr'
    ereturn matrix V_lr  = `V_lr'
    ereturn matrix b_sr  = `b_sr'
    ereturn matrix V_sr  = `V_sr'
    if `k_lin' > 0 {
        ereturn matrix b_lin = `b_lin'
        ereturn matrix V_lin = `V_lin'
    }

    // Locals
    ereturn local depvar    "`depvar'"
    ereturn local xvars     "`xvars'"
    ereturn local asymvars  "`asymmetry'"
    ereturn local linvars   "`linear_vars'"
    ereturn local step1     "`step1'"
    ereturn local trendvar  "`trendvar'"
    ereturn local exogvars  "`exog'"
    ereturn scalar k_lin    = `k_lin'
    ereturn local cmdversion "3.0.0"
    ereturn local cmdline   `"`cmd' `cmdline_orig'"'
    ereturn local cmd       "`cmd'"
    ereturn local predict   "twostep_nardl_p"
    ereturn local estat_cmd "twostep_nardl_estat"
    ereturn local ect_var   "_ect_nardl"
    ereturn local pos_vars  "`asym_pos_stored'"
    ereturn local neg_vars  "`asym_neg_stored'"
    ereturn local sr_regvars    "`sr_indepvars'"
    ereturn local sr_regdepvar  "`regdepvar'"
    ereturn local sr_noconstant "`constant'"

    // Build title
    local lagstr ""
    forvalues i = 1/`numvars' {
        if `i' > 1 local lagstr "`lagstr',"
        local lagstr "`lagstr'`lag`i''"
    }
    ereturn local lagstructure "`lagstr'"
    ereturn local method    "`method'"
    if "`method'" == "onestep" {
        ereturn local step1_label "One-step OLS"
    }
    else {
        local step1_label = upper("`step1'")
        ereturn local step1_label "`step1_label'"
    }
    ereturn local lagselect_str = cond(`do_lagselect', "yes", "no")

    // =========================================================================
    // DISPLAY
    // =========================================================================

    _2snardl_display , `diopts' `ctable' `header' `waldtest'

end


// ============================================================================
// DISPLAY SUBROUTINE - JOURNAL-QUALITY FORMAT
// ============================================================================

program define _2snardl_display

    syntax , * [noCTable noHEADer noWALDtest]

    _get_diopts diopts , `options'

    // Header
    if "`header'" != "noheader" {
        di ""
        di as text "{hline 78}"
        di as text "  Nonlinear ARDL(" as result "`e(lagstructure)'" as text ") Estimation" ///
           _col(52) as text "Obs" _col(68) "=" ///
           _col(70) as result %9.0fc e(N)
        di as text "{hline 78}"
        if "`e(method)'" == "onestep" {
            di as text "  Method  :  One-step OLS (SYG 2014)" ///
               _col(52) as text "R-squared" _col(68) "=" ///
               _col(70) as result %9.4f e(r2)
            di as text _col(52) "Adj R-sq" _col(68) "=" ///
               _col(70) as result %9.4f e(r2_a)
            di as text _col(52) "F-stat" _col(68) "=" ///
               _col(70) as result %9.2f e(F)
        }
        else {
        di as text "  Long-run  :  " as result "`e(step1_label)'" ///
           _col(52) as text "R-squared" _col(68) "=" ///
           _col(70) as result %9.4f e(r2)
        if e(lagselect) == 1 {
            di as text "  Short-run :  OLS" ///
               _col(52) as text "Adj R-sq" _col(68) "=" ///
               _col(70) as result %9.4f e(r2_a)
            di as text "  Lag select:  " as result upper("`e(ic_type)'") ///
               as text " (" as result e(numcombs) as text " combs)" ///
               _col(52) as text "F-stat" _col(68) "=" ///
               _col(70) as result %9.2f e(F)
        }
        else {
            di as text "  Short-run :  OLS" ///
               _col(52) as text "Adj R-sq" _col(68) "=" ///
               _col(70) as result %9.4f e(r2_a)
            di as text _col(52) "F-stat" _col(68) "=" ///
               _col(70) as result %9.2f e(F)
        }
        } // end else twostep
        di as text _col(52) "RMSE" _col(68) "=" ///
           _col(70) as result %9.4f e(rmse)
        di as text "{hline 78}"
        di ""
    }

    // Coefficient table
    if "`ctable'" != "noctable" {
        _coef_table , `diopts'
    }

    // Wald tests - clean table, no math
    if "`waldtest'" != "nowaldtest" {
        capture confirm scalar e(W_lr)
        if !_rc {
            di ""
            di as text "{hline 78}"
            di as text _col(3) "Asymmetry Tests" ///
               _col(36) "Statistic" _col(52) "p-value" _col(66) "Decision"
            di as text "{hline 78}"

            // LR symmetry
            local lr_star ""
            local lr_dec "  --"
            if e(p_lr) < 0.01 {
                local lr_star "***"
                local lr_dec "Reject"
            }
            else if e(p_lr) < 0.05 {
                local lr_star "**"
                local lr_dec "Reject"
            }
            else if e(p_lr) < 0.10 {
                local lr_star "*"
                local lr_dec "Reject"
            }
            di as text _col(3) "Long-run" ///
               _col(33) as result %10.3f e(W_lr) ///
               _col(49) as result %10.4f e(p_lr) ///
               _col(66) as result "`lr_dec'" as text " `lr_star'"

            // SR additive
            local sr_star ""
            local sr_dec "  --"
            if e(p_sr) < 0.01 {
                local sr_star "***"
                local sr_dec "Reject"
            }
            else if e(p_sr) < 0.05 {
                local sr_star "**"
                local sr_dec "Reject"
            }
            else if e(p_sr) < 0.10 {
                local sr_star "*"
                local sr_dec "Reject"
            }
            di as text _col(3) "Short-run (additive)" ///
               _col(33) as result %10.3f e(W_sr) ///
               _col(49) as result %10.4f e(p_sr) ///
               _col(66) as result "`sr_dec'" as text " `sr_star'"

            // Impact
            local imp_star ""
            local imp_dec "  --"
            if e(p_impact) < 0.01 {
                local imp_star "***"
                local imp_dec "Reject"
            }
            else if e(p_impact) < 0.05 {
                local imp_star "**"
                local imp_dec "Reject"
            }
            else if e(p_impact) < 0.10 {
                local imp_star "*"
                local imp_dec "Reject"
            }
            di as text _col(3) "Short-run (impact)" ///
               _col(33) as result %10.3f e(W_impact) ///
               _col(49) as result %10.4f e(p_impact) ///
               _col(66) as result "`imp_dec'" as text " `imp_star'"

            di as text "{hline 78}"

            // Cointegration
            di as text _col(3) "Cointegration" ///
               _col(24) "t-stat =" as result %8.3f e(t_bdm) ///
               _col(47) as text "Speed of adj. =" as result %7.4f e(rho)
            di as text "{hline 78}"
            di as text _col(3) "*** p<0.01, ** p<0.05, * p<0.10"
        }
    }

end
