*! mvardlurt â€” Multivariate ARDL Unit Root Test
*! Version 1.0.0 â€” 2026-02-24
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Independent Researcher
*!
*! Implements the multivariate ARDL unit root test proposed by:
*!   Sam, C. Y., McNown R., Goh, S. K., & Goh, K. L. (2024).
*!   "A multivariate autoregressive distributed lag unit root test."
*!   Studies in Economics and Econometrics, 1-17.
*!
*! The test augments the standard ADF regression with lagged levels
*! of a covariate (independent variable) to improve power, especially
*! when cointegration exists. Bootstrap critical values ensure correct
*! size regardless of nuisance parameters.

capture program drop mvardlurt
program define mvardlurt, eclass sortpreserve
    version 14

    // =========================================================================
    // 1. SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=2 max=2 ts) [if] [in], ///
        [                                      ///
        Case(integer 3)                        /// 1=none, 3=intercept, 5=intercept+trend
        MAXLag(integer 10)                     /// maximum lag order (default: 10)
        REPS(integer 1000)                     /// bootstrap replications (default: 1000)
        IC(string)                             /// aic or bic (default: aic)
        FIXLag(numlist integer min=2 max=2)    /// manual lag specification: p q
        Level(cilevel)                         /// confidence level (default: 95)
        SEED(integer 12345)                    /// random seed
        NOGraph                                /// suppress graphs
        DIag                                   /// show diagnostic tests
        NOTable                                /// suppress AIC table
        NOBoot                                 /// suppress bootstrap (just show observed stats)
        ]

    // Mark estimation sample
    marksample touse

    // Parse variables
    gettoken depvar indepvar : varlist
    local indepvar = strtrim("`indepvar'")

    // Validate case
    if !inlist(`case', 1, 3, 5) {
        di as err "case() must be 1 (none), 3 (intercept), or 5 (intercept + trend)"
        exit 198
    }

    // Validate IC
    if "`ic'" == "" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic") {
        di as err "ic() must be {bf:aic} or {bf:bic}"
        exit 198
    }

    // Validate maxlag
    if `maxlag' < 0 | `maxlag' > 10 {
        di as err "maxlag() must be between 0 and 10"
        exit 198
    }

    // Validate reps
    if `reps' < 100 {
        di as err "reps() must be at least 100"
        exit 198
    }

    // Confirm time series
    qui tsset
    local timevar  "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "mvardlurt is designed for time-series data only, not panel data"
        exit 198
    }

    // =========================================================================
    // 2. PRESERVE & PREPARE DATA
    // =========================================================================
    preserve

    qui keep if `touse'
    qui count
    local T = r(N)

    if `T' < 30 {
        di as err "Too few observations (`T'). Need at least 30."
        exit 2001
    }

    // Set seed for reproducibility
    set seed `seed'

    // Generate differenced series
    tempvar dy dx
    qui gen double `dy' = D.`depvar'
    qui gen double `dx' = D.`indepvar'

    // Case labels
    local casename ""
    local det_terms ""
    if `case' == 1 {
        local casename "No Deterministic Terms"
        local det_terms ""
    }
    else if `case' == 3 {
        local casename "Intercept Only"
        local det_terms "c"
    }
    else if `case' == 5 {
        local casename "Intercept and Trend"
        local det_terms "c t"
    }

    // =========================================================================
    // 3. MINIMAL HEADER (details shown in Table 1)
    // =========================================================================
    // Identify sample range using tsset format
    qui su `timevar', meanonly
    local t_min = r(min)
    local t_max = r(max)
    qui tsset
    local tsfmt "`r(tsfmt)'"
    if "`tsfmt'" == "" local tsfmt "%td"
    local t_min_fmt : di `tsfmt' `t_min'
    local t_max_fmt : di `tsfmt' `t_max'

    di as txt ""
    di as res _col(3) "Multivariate ARDL Unit Root Test -- Sam, McNown, Goh and Goh (2024)"
    di as txt ""

    // =========================================================================
    // 4. AIC/BIC-BASED LAG SELECTION
    //    Grid search over p = 0..maxlag, q = 0..maxlag
    //    Mirrors EViews algorithm exactly
    // =========================================================================

    // Check for manual lag specification
    local manual_lag = 0
    if "`fixlag'" != "" {
        local manual_lag = 1
        local fix_p : word 1 of `fixlag'
        local fix_q : word 2 of `fixlag'
    }

    if `manual_lag' {
        local opt_p = `fix_p'
        local opt_q = `fix_q'
        di as txt _col(3) "Using manual lag specification: ARDL(`opt_p', `opt_q')"
        di as txt ""
    }
    else {

        tempname aic_matrix best_ic_val
        local dim = `maxlag' + 1
        mat `aic_matrix' = J(`dim', `dim', .)
        scalar `best_ic_val' = .

        local opt_p = 0
        local opt_q = 0
        local total_models = 0

        // Build deterministic terms
        local det_regs ""
        if `case' == 3 {
            local det_regs ""
            // constant is included automatically by regress
        }
        else if `case' == 5 {
            tempvar ttrend
            qui gen `ttrend' = _n
            local det_regs "`ttrend'"
        }

        forvalues p = 0/`maxlag' {
            forvalues q = 0/`maxlag' {
                local total_models = `total_models' + 1

                // Build regressor list
                local regvars "L.`depvar' L.`indepvar'"

                // Lagged differences of dy
                if `p' > 0 {
                    forvalues j = 1/`p' {
                        local regvars "`regvars' L`j'.D.`depvar'"
                    }
                }

                // Lagged differences of dx
                if `q' > 0 {
                    forvalues j = 1/`q' {
                        local regvars "`regvars' L`j'.D.`indepvar'"
                    }
                }

                // Add deterministics
                if "`det_regs'" != "" {
                    local regvars "`regvars' `det_regs'"
                }

                // Run regression
                if `case' == 1 {
                    capture qui regress D.`depvar' `regvars', noconstant
                }
                else {
                    capture qui regress D.`depvar' `regvars'
                }

                if _rc != 0 continue
                if e(N) < 15 continue

                // Compute IC
                local this_n = e(N)
                local this_k = e(df_m) + 1
                local this_ll = e(ll)

                if "`ic'" == "aic" {
                    local this_ic = -2 * `this_ll' + 2 * `this_k'
                }
                else {
                    local this_ic = -2 * `this_ll' + `this_k' * ln(`this_n')
                }

                mat `aic_matrix'[`p'+1, `q'+1] = `this_ic'

                // Update best model
                if `this_ic' < scalar(`best_ic_val') | missing(scalar(`best_ic_val')) {
                    scalar `best_ic_val' = `this_ic'
                    local opt_p = `p'
                    local opt_q = `q'
                }

            } // end q loop
        } // end p loop


        // Display AIC/BIC table
        if "`notable'" == "" {
            di as txt _col(3) upper("`ic'") " Selection Table â€” ARDL(p, q)"
            di as txt "{hline 78}"

            // Column headers (q values)
            di as txt _col(5) "p \ q" _c
            forvalues q = 0/`maxlag' {
                di as txt %11s "q=`q'" _c
            }
            di as txt ""
            di as txt "{hline 78}"

            forvalues p = 0/`maxlag' {
                di as txt _col(3) "p=`p'" _c
                forvalues q = 0/`maxlag' {
                    local aval = el(`aic_matrix', `p'+1, `q'+1)
                    if `aval' == . {
                        di as txt %11s "." _c
                    }
                    else {
                        // Highlight optimal
                        if `p' == `opt_p' & `q' == `opt_q' {
                            di as res %11.2f `aval' _c
                        }
                        else {
                            di as txt %11.2f `aval' _c
                        }
                    }
                }
                di as txt ""
            }
            di as txt "{hline 78}"
            di as txt _col(5) "Optimal: ARDL(`opt_p', `opt_q') â€” highlighted in yellow"
            di as txt ""
        }
    }

    // =========================================================================
    // 5. FINAL ESTIMATION â€” OPTIMAL MODEL (quiet)
    // =========================================================================

    // Build regressor list for optimal model
    local opt_regvars "L.`depvar' L.`indepvar'"
    if `opt_p' > 0 {
        forvalues j = 1/`opt_p' {
            local opt_regvars "`opt_regvars' L`j'.D.`depvar'"
        }
    }
    if `opt_q' > 0 {
        forvalues j = 1/`opt_q' {
            local opt_regvars "`opt_regvars' L`j'.D.`indepvar'"
        }
    }

    // Deterministics
    local det_regs_final ""
    if `case' == 5 {
        capture drop _trend
        qui gen double _trend = _n
        local det_regs_final "_trend"
    }
    if "`det_regs_final'" != "" {
        local opt_regvars "`opt_regvars' `det_regs_final'"
    }

    // Estimate quietly
    if `case' == 1 {
        qui regress D.`depvar' `opt_regvars', noconstant
    }
    else {
        qui regress D.`depvar' `opt_regvars'
    }

    // Store estimation results
    local nobs  = e(N)
    local df_m  = e(df_m)
    local df_r  = e(df_r)
    local r2    = e(r2)
    local r2_a  = e(r2_a)
    local ll    = e(ll)
    local rss   = e(rss)
    local rmse  = e(rmse)
    local nparams = e(df_m) + 1
    local aic_val = -2 * `ll' + 2 * `nparams'
    local bic_val = -2 * `ll' + `nparams' * ln(`nobs')

    // t-statistic on L.depvar
    local tstat_y = _b[L.`depvar'] / _se[L.`depvar']
    local pi_coef = _b[L.`depvar']
    local pi_se   = _se[L.`depvar']

    // delta coefficient on L.indepvar
    local delta_coef = _b[L.`indepvar']
    local delta_se   = _se[L.`indepvar']

    // F-statistic (Wald) on L.indepvar
    qui test L.`indepvar'
    local fstat_y = r(F)
    local fstat_p = r(p)

    // =========================================================================
    // 6. BOOTSTRAP
    // =========================================================================
    if "`noboot'" == "" {
        di as txt _col(3) "Computing bootstrap critical values (`reps' replications)..."
        di as txt ""

        _mvardlurt_bootstrap `depvar', ///
            indepvar(`indepvar') ///
            plag(`opt_p') ///
            qlag(`opt_q') ///
            case(`case') ///
            reps(`reps') ///
            seed(`seed')

        local t_cv10  = r(t_cv10)
        local t_cv05  = r(t_cv05)
        local t_cv025 = r(t_cv025)
        local t_cv01  = r(t_cv01)
        local f_cv10  = r(f_cv10)
        local f_cv05  = r(f_cv05)
        local f_cv025 = r(f_cv025)
        local f_cv01  = r(f_cv01)
    }
    else {
        local t_cv10  = .
        local t_cv05  = .
        local t_cv025 = .
        local t_cv01  = .
        local f_cv10  = .
        local f_cv05  = .
        local f_cv025 = .
        local f_cv01  = .
    }

    // =====================================================================
    //  TABLE 1: ARDL UNIT ROOT TEST (EViews table_result format)
    // =====================================================================
    di as txt ""
    di as txt "{hline 78}"
    di as res _col(5) "Table 1: ARDL Unit Root Test"
    di as txt _col(5) "Sam, McNown, Goh and Goh (2024)"
    di as txt "{hline 78}"
    di as txt _col(3) "Dependent variable :" ///
        _col(24) as res "`depvar'" ///
        _col(45) as txt "Sample:" ///
        _col(55) as res strtrim("`t_min_fmt'") " to " strtrim("`t_max_fmt'")
    di as txt _col(3) "Independent variable:" ///
        _col(24) as res "`indepvar'" ///
        _col(45) as txt "Optimal Model:" ///
        _col(61) as res "ARDL(`opt_p', `opt_q')"
    di as txt _col(3) "Regression:" ///
        _col(24) as res "Case `case' (`casename')" ///
        _col(55) as txt "Obs:" ///
        _col(61) as res "`nobs'"
    di as txt _col(3) "AIC:" ///
        _col(24) as res %12.4f `aic_val' ///
        _col(55) as txt "R-squared:" ///
        _col(67) as res %8.6f `r2'
    di as txt "{hline 78}"
    di as txt _col(3) "t-statistic:" ///
        _col(24) as res %12.6f `tstat_y' ///
        _col(45) as txt "(H0: pi = 0, unit root)"
    di as txt _col(3) "F-statistic:" ///
        _col(24) as res %12.6f `fstat_y' ///
        _col(45) as txt "(H0: delta = 0, no cointegration)"
    di as txt "{hline 78}"
    di as txt ""

    // =====================================================================
    //  TABLE 2: BOOTSTRAP CRITICAL VALUES
    // =====================================================================
    if "`noboot'" == "" {
        di as txt "{hline 78}"
        di as res _col(5) "Table 2: Bootstrap Critical Values (`reps' replications)"
        di as txt "{hline 78}"
        di as txt _col(3) "Sig. Level" ///
            _col(22) "10%" ///
            _col(36) "5%" ///
            _col(49) "2.5%" ///
            _col(63) "1%"
        di as txt "{hline 78}"
        di as txt _col(3) "t-critical value" ///
            _col(19) as res %10.4f `t_cv10' ///
            _col(33) as res %10.4f `t_cv05' ///
            _col(47) as res %10.4f `t_cv025' ///
            _col(61) as res %10.4f `t_cv01'
        di as txt _col(3) "F-critical value" ///
            _col(19) as res %10.4f `f_cv10' ///
            _col(33) as res %10.4f `f_cv05' ///
            _col(47) as res %10.4f `f_cv025' ///
            _col(61) as res %10.4f `f_cv01'
        di as txt "{hline 78}"
        di as txt ""
    }

    // =====================================================================
    //  TABLE 3: COEFFICIENT SUMMARY
    // =====================================================================
    di as txt "{hline 78}"
    di as res _col(5) "Table 3: ARDL Coefficient Summary"
    di as txt "{hline 78}"
    di as txt _col(3) "Parameter" ///
        _col(22) "Variable" ///
        _col(38) "Coefficient" ///
        _col(55) "Std. Err." ///
        _col(69) "t-stat"
    di as txt "{hline 78}"
    di as txt _col(3) "pi (unit root)" ///
        _col(22) "L.`depvar'" ///
        _col(35) as res %12.6f `pi_coef' ///
        _col(50) as res %12.6f `pi_se' ///
        _col(65) as res %8.4f `tstat_y'
    di as txt _col(3) "delta (cointegr.)" ///
        _col(22) "L.`indepvar'" ///
        _col(35) as res %12.6f `delta_coef' ///
        _col(50) as res %12.6f `delta_se'
    if `pi_coef' != 0 {
        local lr_mult = -1 * `delta_coef' / `pi_coef'
        di as txt "{hline 78}"
        di as txt _col(3) "Long-run multiplier (delta/pi):" ///
            _col(38) as res %12.6f `lr_mult'
    }
    di as txt "{hline 78}"
    di as txt ""

    // =====================================================================
    //  TABLE 4: COMPREHENSIVE DECISION AND INFERENCE
    // =====================================================================
    // Determine significance levels
    local t_sig = ""
    local t_level = ""
    local f_sig = ""
    local f_level = ""

    if "`noboot'" == "" {
        if `t_cv01' < . {
            if `tstat_y' < `t_cv01' {
                local t_sig "***"
                local t_level "1%"
            }
        }
        if "`t_sig'" == "" {
            if `t_cv025' < . {
                if `tstat_y' < `t_cv025' {
                    local t_sig "**"
                    local t_level "2.5%"
                }
            }
        }
        if "`t_sig'" == "" {
            if `t_cv05' < . {
                if `tstat_y' < `t_cv05' {
                    local t_sig "*"
                    local t_level "5%"
                }
            }
        }
        if "`t_sig'" == "" {
            if `t_cv10' < . {
                if `tstat_y' < `t_cv10' {
                    local t_sig "+"
                    local t_level "10%"
                }
            }
        }
        if `f_cv01' < . {
            if `fstat_y' > `f_cv01' {
                local f_sig "***"
                local f_level "1%"
            }
        }
        if "`f_sig'" == "" {
            if `f_cv025' < . {
                if `fstat_y' > `f_cv025' {
                    local f_sig "**"
                    local f_level "2.5%"
                }
            }
        }
        if "`f_sig'" == "" {
            if `f_cv05' < . {
                if `fstat_y' > `f_cv05' {
                    local f_sig "*"
                    local f_level "5%"
                }
            }
        }
        if "`f_sig'" == "" {
            if `f_cv10' < . {
                if `fstat_y' > `f_cv10' {
                    local f_sig "+"
                    local f_level "10%"
                }
            }
        }
    }

    di as txt "{hline 78}"
    di as res _col(5) "Table 4: Decision and Inference"
    di as txt "{hline 78}"
    di as txt ""

    // â”€â”€â”€ Part A: Test Decision Summary â”€â”€â”€
    di as txt _col(3) "A. Hypothesis Tests"
    di as txt _col(3) "{hline 74}"
    di as txt _col(5) "Test" ///
        _col(18) "Null Hypothesis" ///
        _col(42) "Statistic" ///
        _col(55) "Decision" ///
        _col(72) "Sig."
    di as txt _col(3) "{hline 74}"

    if "`t_sig'" != "" {
        di as txt _col(5) "t-test" ///
            _col(18) "H0: pi = 0" ///
            _col(42) as res %10.4f `tstat_y' ///
            _col(55) as res "Reject`t_sig'" ///
            _col(72) as txt "`t_level'"
    }
    else {
        di as txt _col(5) "t-test" ///
            _col(18) "H0: pi = 0" ///
            _col(42) as res %10.4f `tstat_y' ///
            _col(55) as txt "Fail to reject" ///
            _col(72) as txt "n.s."
    }

    if "`f_sig'" != "" {
        di as txt _col(5) "F-test" ///
            _col(18) "H0: delta = 0" ///
            _col(42) as res %10.4f `fstat_y' ///
            _col(55) as res "Reject`f_sig'" ///
            _col(72) as txt "`f_level'"
    }
    else {
        di as txt _col(5) "F-test" ///
            _col(18) "H0: delta = 0" ///
            _col(42) as res %10.4f `fstat_y' ///
            _col(55) as txt "Fail to reject" ///
            _col(72) as txt "n.s."
    }
    di as txt _col(3) "{hline 74}"
    di as txt ""

    // â”€â”€â”€ Part B: Four Cases Framework â”€â”€â”€
    di as txt _col(3) "B. Four-Case Framework (Sam, McNown, Goh and Goh, 2024)"
    di as txt _col(3) "{hline 74}"
    di as txt _col(5) "Case" ///
        _col(16) "t-test" ///
        _col(28) "F-test" ///
        _col(40) "Interpretation"
    di as txt _col(3) "{hline 74}"

    // Always show all 4 cases with arrow marking the applicable one
    local c1_mark = "  "
    local c2_mark = "  "
    local c3_mark = "  "
    local c4_mark = "  "

    if "`t_sig'" != "" {
        if "`f_sig'" != "" {
            local c1_mark = "=>"
        }
        else {
            local c2_mark = "=>"
        }
    }
    else {
        if "`f_sig'" != "" {
            local c3_mark = "=>"
        }
        else {
            local c4_mark = "=>"
        }
    }

    di as txt _col(3) "`c1_mark'" _col(5) " I" ///
        _col(16) "Reject" ///
        _col(28) "Reject" ///
        _col(40) "Cointegration"
    di as txt _col(3) "`c2_mark'" _col(5) " II" ///
        _col(16) "Reject" ///
        _col(28) "Accept" ///
        _col(40) "Degenerate case 1 (y may be I(0))"
    di as txt _col(3) "`c3_mark'" _col(5) " III" ///
        _col(16) "Accept" ///
        _col(28) "Reject" ///
        _col(40) "Degenerate case 2 (spurious)"
    di as txt _col(3) "`c4_mark'" _col(5) " IV" ///
        _col(16) "Accept" ///
        _col(28) "Accept" ///
        _col(40) "No cointegration"
    di as txt _col(3) "{hline 74}"
    di as txt ""

    // â”€â”€â”€ Part C: Detailed Conclusion â”€â”€â”€
    di as txt _col(3) "C. Conclusion"
    di as txt _col(3) "{hline 74}"
    if "`t_sig'" != "" {
        if "`f_sig'" != "" {
            di as res _col(5) "CASE I: Cointegration"
            di as txt _col(5) "  pi != 0 : Error correction exists; `depvar' adjusts to equilibrium"
            di as txt _col(5) "  delta != 0 : `indepvar' enters the long-run equation"
            di as txt _col(5) "  => `depvar' and `indepvar' are cointegrated"
            di as txt _col(5) "  => The ECM is valid; long-run equilibrium relationship exists"
        }
        else {
            di as res _col(5) "CASE II: Degenerate case 1"
            di as txt _col(5) "  pi != 0 : `depvar' is stationary or error-correcting"
            di as txt _col(5) "  delta = 0 : `indepvar' has no long-run effect on `depvar'"
            di as txt _col(5) "  => `depvar' may be I(0); `indepvar' is not a cointegrator"
            di as txt _col(5) "  => No long-run relationship via `indepvar'"
        }
    }
    else {
        if "`f_sig'" != "" {
            di as res _col(5) "CASE III: Degenerate case 2"
            di as txt _col(5) "  pi = 0 : `depvar' has a unit root (I(1))"
            di as txt _col(5) "  delta != 0 : `indepvar' coefficient is significant"
            di as txt _col(5) "  => Spurious result; unit root invalidates the relationship"
            di as txt _col(5) "  => The long-run relationship is not reliable"
        }
        else {
            di as res _col(5) "CASE IV: No cointegration"
            di as txt _col(5) "  pi = 0 : `depvar' has a unit root (I(1))"
            di as txt _col(5) "  delta = 0 : No cointegrating relationship"
            di as txt _col(5) "  => No evidence of long-run equilibrium"
            di as txt _col(5) "  => `depvar' and `indepvar' are not cointegrated"
        }
    }
    di as txt _col(3) "{hline 74}"
    di as txt ""
    di as txt _col(3) "Significance: *** 1%  ** 2.5%  * 5%  + 10%  n.s. not significant"
    di as txt "{hline 78}"
    di as txt ""

    // =========================================================================
    // 7. DIAGNOSTIC TESTS (opt-in with diag option)
    // =========================================================================
    if "`diag'" != "" {
        if `case' == 1 {
            qui regress D.`depvar' `opt_regvars', noconstant
        }
        else {
            qui regress D.`depvar' `opt_regvars'
        }
        _mvardlurt_diagtest
    }

    // =========================================================================
    // 8. GRAPHS
    // =========================================================================
    if "`nograph'" == "" {
        if `case' == 1 {
            qui regress D.`depvar' `opt_regvars', noconstant
        }
        else {
            qui regress D.`depvar' `opt_regvars'
        }

        _mvardlurt_graph `depvar', ///
            indepvar(`indepvar') ///
            tstat("`tstat_y'") ///
            fstat("`fstat_y'") ///
            tcv10("`t_cv10'") tcv05("`t_cv05'") tcv01("`t_cv01'") ///
            fcv10("`f_cv10'") fcv05("`f_cv05'") fcv01("`f_cv01'") ///
            plag(`opt_p') qlag(`opt_q') ///
            casename("`casename'")
    }

    // =========================================================================
    // 9. POST RESULTS (silent)
    // =========================================================================
    if `case' == 1 {
        qui regress D.`depvar' `opt_regvars', noconstant
    }
    else {
        qui regress D.`depvar' `opt_regvars'
    }

    ereturn scalar tstat     = `tstat_y'
    ereturn scalar fstat     = `fstat_y'
    ereturn scalar fstat_p   = `fstat_p'
    ereturn scalar pi_coef   = `pi_coef'
    ereturn scalar pi_se     = `pi_se'
    ereturn scalar delta_coef = `delta_coef'
    ereturn scalar delta_se  = `delta_se'
    if `pi_coef' != 0 {
        ereturn scalar lr_mult = -1 * `delta_coef' / `pi_coef'
    }
    ereturn scalar opt_p     = `opt_p'
    ereturn scalar opt_q     = `opt_q'
    ereturn scalar case      = `case'
    ereturn scalar reps      = `reps'
    ereturn scalar T         = `T'
    ereturn scalar aic       = `aic_val'
    ereturn scalar bic       = `bic_val'
    ereturn scalar t_cv10    = `t_cv10'
    ereturn scalar t_cv05    = `t_cv05'
    ereturn scalar t_cv025   = `t_cv025'
    ereturn scalar t_cv01    = `t_cv01'
    ereturn scalar f_cv10    = `f_cv10'
    ereturn scalar f_cv05    = `f_cv05'
    ereturn scalar f_cv025   = `f_cv025'
    ereturn scalar f_cv01    = `f_cv01'

    ereturn local cmd        "mvardlurt"
    ereturn local cmdline    "mvardlurt `0'"
    ereturn local depvar     "`depvar'"
    ereturn local indepvar   "`indepvar'"
    ereturn local casename   "`casename'"
    ereturn local ic         "`ic'"
    ereturn local title      "Multivariate ARDL Unit Root Test"

    if `manual_lag' == 0 {
        ereturn matrix aic_table = `aic_matrix'
    }

    restore

end
