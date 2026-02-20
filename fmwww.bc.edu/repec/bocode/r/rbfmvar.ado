*! rbfmvar — Residual-Based Fully Modified VAR estimation
*! Version 2.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*!
*! Reference:
*!   Chang, Y. (2000). Vector Autoregressions with Unknown Mixtures
*!   of I(0), I(1), and I(2) Components.
*!   Econometric Theory, 16(6), 905-926.
*!
*! The RBFM-VAR procedure extends Phillips (1995) FM-VAR to handle
*! any unknown mixture of I(0), I(1), and I(2) variables without
*! prior knowledge of the number or location of unit roots.

capture program drop rbfmvar
program define rbfmvar, eclass sortpreserve
    version 14.0

    syntax varlist(ts min=2) [if] [in], [         ///
        Lags(integer 2)                           /// VAR order p
        MAXLags(integer 8)                        /// max lags for IC selection
        IC(string)                                /// Lag IC: aic bic hq none
        KERnel(string)                            /// LRV kernel: bartlett parzen qs
        BANDwidth(real -1)                        /// bandwidth (-1 = automatic)
        GRanger(string asis)                      /// Granger: "y1 -> y2"
        IRF(integer 0)                            /// IRF horizon (0=skip)
        BOOTreps(integer 500)                     /// Bootstrap reps for IRF CI (0=skip)
        BOOTci(integer 90)                        /// CI level for bootstrap IRF
        FEVD                                      /// Compute FEVD
        FORecast(integer 0)                       /// Forecast steps ahead
        NOPRint                                   /// suppress table
        Level(cilevel)                            /// confidence level
        ]

    *--------------------------------------------------------------------------
    * Load Mata library
    *--------------------------------------------------------------------------
    capture findfile _rbfmvar_mata.ado
    if _rc {
        di as error "Required file _rbfmvar_mata.ado not found."
        di as error "Ensure the rbfmvar package is properly installed."
        exit 601
    }
    qui run `"`r(fn)'"'

    *--------------------------------------------------------------------------
    * Input validation
    *--------------------------------------------------------------------------
    marksample touse
    _ts timevar panelvar if `touse', sort onepanel
    markout `touse' `timevar'

    * Count variables
    local nvars : word count `varlist'
    if `nvars' < 2 {
        di as error "At least 2 variables required for VAR"
        exit 102
    }

    * Validate lags
    if `lags' < 1 {
        di as error "lags() must be at least 1"
        exit 198
    }
    if `maxlags' < 1 {
        di as error "maxlags() must be at least 1"
        exit 198
    }

    * Validate kernel
    if "`kernel'" == "" {
        local kernel "bartlett"
    }
    else {
        local kernel = lower("`kernel'")
        if !inlist("`kernel'", "bartlett", "parzen", "qs") {
            di as error "kernel() must be {bf:bartlett}, {bf:parzen}, or {bf:qs}"
            exit 198
        }
    }

    * Validate IC
    if "`ic'" == "" {
        local ic "none"
    }
    else {
        local ic = lower("`ic'")
        if !inlist("`ic'", "aic", "bic", "hq", "none") {
            di as error "ic() must be {bf:aic}, {bf:bic}, {bf:hq}, or {bf:none}"
            exit 198
        }
    }

    * Validate IRF
    if `irf' < 0 {
        di as error "irf() must be non-negative"
        exit 198
    }

    * Validate IRF bootstrap
    if `bootreps' < 0 {
        di as error "bootreps() must be non-negative"
        exit 198
    }
    if `bootci' < 50 | `bootci' > 99 {
        di as error "bootci() must be between 50 and 99"
        exit 198
    }

    * Validate forecast
    if `forecast' < 0 {
        di as error "forecast() must be non-negative"
        exit 198
    }

    * FEVD flag
    local do_fevd = 0
    if "`fevd'" != "" local do_fevd = 1

    * Check sample size
    qui count if `touse'
    local N = r(N)
    if `N' < 20 {
        di as error "insufficient observations (need at least 20, have `N')"
        exit 2001
    }

    *--------------------------------------------------------------------------
    * Lag selection via IC if requested
    *--------------------------------------------------------------------------
    local p_use = `lags'

    if "`ic'" != "none" {
        tempvar y_temp_ic
        qui gen double `y_temp_ic' = .

        * Use Mata for lag selection
        mata: st_numscalar("r(best_p)", _rbfm_select_lags( ///
            st_data(., "`varlist'", "`touse'"), `maxlags', "`ic'"))

        local p_use = r(best_p)
        di as txt "{col 5}Lag selection ({bf:`ic'}): optimal p = " as res `p_use'
    }

    *--------------------------------------------------------------------------
    * Run RBFM-VAR estimation via Mata
    *--------------------------------------------------------------------------
    local granger_clean `granger'

    mata: rbfmvar_estimate("`varlist'", `p_use', "`kernel'", `bandwidth', ///
        `"`granger_clean'"', "`touse'", `irf', `bootreps', `bootci', ///
        `do_fevd', `forecast')

    * Retrieve results
    local nobs      = r(nobs)
    local T_eff     = r(T_eff)
    local n_vars    = r(n_vars)
    local p_lags    = r(p_lags)
    local bw_used   = r(bandwidth)

    tempname F_ols F_plus Sigma_e SE_mat Omega_ev Omega_vv Delta_vdw
    tempname Pi1_ols Pi2_ols Pi1_plus Pi2_plus
    tempname Gamma_ols Gamma_plus

    mat `F_ols'    = r(F_ols)
    mat `F_plus'   = r(F_plus)
    mat `Sigma_e'  = r(Sigma_e)
    mat `SE_mat'   = r(SE_mat)
    mat `Omega_ev' = r(Omega_ev)
    mat `Omega_vv' = r(Omega_vv)
    mat `Delta_vdw' = r(Delta_vdw)
    mat `Pi1_ols'  = r(Pi1_ols)
    mat `Pi2_ols'  = r(Pi2_ols)
    mat `Pi1_plus' = r(Pi1_plus)
    mat `Pi2_plus' = r(Pi2_plus)

    capture mat `Gamma_ols'  = r(Gamma_ols)
    capture mat `Gamma_plus' = r(Gamma_plus)

    * Granger test results
    local has_granger = 0
    if `"`granger_clean'"' != "" {
        local wald_stat = r(wald_stat)
        local wald_pval = r(wald_pval)
        local wald_df   = r(wald_df)
        local has_granger = 1
    }

    * IRF results
    local has_irf = 0
    local has_irf_ci = 0
    tempname irf_mat irf_lo irf_hi
    if `irf' > 0 {
        capture mat `irf_mat' = r(irf)
        if _rc == 0 {
            local has_irf = 1
        }
        capture mat `irf_lo' = r(irf_lo)
        capture mat `irf_hi' = r(irf_hi)
        if _rc == 0 {
            local has_irf_ci = 1
        }
    }

    * FEVD results
    local has_fevd = 0
    tempname fevd_mat
    if `do_fevd' {
        capture mat `fevd_mat' = r(fevd)
        if _rc == 0 {
            local has_fevd = 1
        }
    }

    * Forecast results
    local has_forecast = 0
    tempname fcast_mat fcast_se
    if `forecast' > 0 {
        capture mat `fcast_mat' = r(forecast)
        capture mat `fcast_se' = r(forecast_se)
        if _rc == 0 {
            local has_forecast = 1
        }
    }

    * Residuals
    tempname resid_mat
    capture mat `resid_mat' = r(residuals)

    *--------------------------------------------------------------------------
    * Label matrices with variable names
    *--------------------------------------------------------------------------
    local varnames_list ""
    foreach v of local varlist {
        local varnames_list "`varnames_list' `v'"
    }

    capture {
        matrix rownames `Pi1_ols'  = `varnames_list'
        matrix colnames `Pi1_ols'  = `varnames_list'
        matrix rownames `Pi2_ols'  = `varnames_list'
        matrix colnames `Pi2_ols'  = `varnames_list'
        matrix rownames `Pi1_plus' = `varnames_list'
        matrix colnames `Pi1_plus' = `varnames_list'
        matrix rownames `Pi2_plus' = `varnames_list'
        matrix colnames `Pi2_plus' = `varnames_list'
        matrix rownames `Sigma_e'  = `varnames_list'
        matrix colnames `Sigma_e'  = `varnames_list'
    }

    *--------------------------------------------------------------------------
    * Kernel label
    *--------------------------------------------------------------------------
    if "`kernel'" == "bartlett" {
        local kernel_label "Bartlett"
    }
    else if "`kernel'" == "parzen" {
        local kernel_label "Parzen"
    }
    else {
        local kernel_label "Quadratic Spectral"
    }

    *--------------------------------------------------------------------------
    * Build regressor names with lag notation
    *--------------------------------------------------------------------------
    local ncols_z = `n_vars' * max(`p_use' - 2, 0)
    local regnames ""

    * Γ regressors: Δ²y_{t-j} for j = 1,...,p-2
    if `p_use' >= 3 {
        forval j = 1/`=`p_use'-2' {
            foreach v of local varlist {
                local regnames "`regnames' L`j'D2.`v'"
            }
        }
    }

    * Π₁ regressors: Δy_{t-1}
    foreach v of local varlist {
        local regnames "`regnames' LD.`v'"
    }

    * Π₂ regressors: y_{t-1}
    foreach v of local varlist {
        local regnames "`regnames' L.`v'"
    }

    *--------------------------------------------------------------------------
    * Display results
    *--------------------------------------------------------------------------
    if "`noprint'" == "" {

        di
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:Residual-Based Fully Modified VAR (RBFM-VAR)}"
        di as txt "{col 5}{it:Chang, Y. (2000). Econometric Theory, 16(6), 905-926.}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}Variables:{col 25}" as res "`varlist'"
        di as txt "{col 5}VAR order (p):{col 25}" as res "`p_use'" ///
           as txt "{col 45}Number of obs{col 62}=" as res %10.0f `nobs'
        di as txt "{col 5}Kernel:{col 25}" as res "`kernel_label'" ///
           as txt "{col 45}Effective T{col 62}=" as res %10.0f `T_eff'
        di as txt "{col 5}Bandwidth:{col 25}" as res %7.2f `bw_used' ///
           as txt "{col 45}Variables (n){col 62}=" as res %10.0f `n_vars'
        if "`ic'" != "none" {
            di as txt "{col 5}Lag selection:{col 25}" as res "`=upper("`ic'")': p = `p_use' (max = `maxlags')"
        }
        if `has_irf_ci' {
            di as txt "{col 5}IRF Bootstrap:{col 25}" as res "`bootreps' reps, `bootci'% CI"
        }
        di

        * --- Equation-by-equation coefficient tables ---
        local np_total = colsof(`F_plus')
        local eq_num = 0
        foreach dep of local varlist {
            local eq_num = `eq_num' + 1

            di as txt "{hline 78}"
            di as txt "    {bf:Equation: `dep'}"
            di as txt "{hline 78}"
            di as txt %16s "" " {c |}" ///
               %11s "Coef." ///
               %11s "Std.Err." ///
               %9s "z"  ///
               %9s "P>|z|" ///
               "    [" %2.0f `level' "%  Conf. Interval]"
            di as txt "{hline 16}{c +}{hline 61}"

            forval c = 1/`np_total' {
                local rname : word `c' of `regnames'
                local coef = `F_plus'[`eq_num', `c']
                local se   = `SE_mat'[`eq_num', `c']
                local zval = 0
                local pval = 1
                local ci_lo = .
                local ci_hi = .
                local stars ""

                if `se' > 0 & `se' < . {
                    local zval = `coef' / `se'
                    local pval = 2 * (1 - normal(abs(`zval')))
                    local cv = invnormal(1 - (100 - `level') / 200)
                    local ci_lo = `coef' - `cv' * `se'
                    local ci_hi = `coef' + `cv' * `se'
                }

                if `pval' < 0.01 {
                    local stars "***"
                }
                else if `pval' < 0.05 {
                    local stars " **"
                }
                else if `pval' < 0.10 {
                    local stars "  *"
                }
                else {
                    local stars "   "
                }

                di as txt %16s abbrev("`rname'", 16) " {c |}" ///
                   as res %11.6f `coef' ///
                   as res %11.6f `se' ///
                   as res %9.3f `zval' ///
                   as res %9.3f `pval' ///
                   as txt "`stars'" ///
                   as res %11.6f `ci_lo' ///
                   as res %12.6f `ci_hi'
            }

            di as txt "{hline 16}{c BT}{hline 61}"
            di
        }

        * --- Significance note ---
        di as txt "{col 5}*** p<0.01, ** p<0.05, * p<0.10"
        di as txt "{col 5}Note: SEs from Var(vec(F+')) = Sigma_e (x) (X'X)^{-1}."
        di as txt "{col 5}      P-values conservative for nonstationary regressors (Thm 2)."
        di

        * --- Error Covariance ---
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:Error Covariance Matrix (Sigma_e)}"
        di as txt "{hline 78}"
        di
        _rbfmvar_display_matrix `Sigma_e'
        di

        * --- LRV Diagnostics ---
        di as txt "{hline 78}"
        di as txt "{col 5}{bf:Long-Run Variance Estimation}"
        di as txt "{hline 78}"
        di
        di as txt "{col 5}Kernel:{col 30}" as res "`kernel_label'"
        di as txt "{col 5}Bandwidth (K):{col 30}" as res %9.2f `bw_used'
        if `bandwidth' < 0 {
            di as txt "{col 5}Selection:{col 30}" as res "Andrews (1991) automatic"
        }
        else {
            di as txt "{col 5}Selection:{col 30}" as res "User-specified"
        }
        di

        * --- Granger Causality Test ---
        if `has_granger' {
            di as txt "{hline 78}"
            di as txt "{col 5}{bf:Granger Non-Causality Test (Modified Wald)}"
            di as txt "{hline 78}"
            di
            di as txt "{col 5}Hypothesis:{col 25}" as res `"`granger_clean'"'
            di as txt "{col 5}H0:{col 25}" as res "No Granger causality"
            di

            * Significance stars
            local stars ""
            if `wald_pval' < 0.01 {
                local stars "***"
            }
            else if `wald_pval' < 0.05 {
                local stars "**"
            }
            else if `wald_pval' < 0.10 {
                local stars "*"
            }

            di as txt "{col 5}Modified Wald (W_F+):{col 35}" as res %12.4f `wald_stat' ///
               as txt "  `stars'"
            di as txt "{col 5}Degrees of freedom:{col 35}" as res %12.0f `wald_df'
            di as txt "{col 5}Conservative p-value:{col 35}" as res %12.4f `wald_pval'
            di
            di as txt "{col 5}{bf:Decision:}"
            if `wald_pval' < 0.01 {
                di as res "{col 5}Reject H0 at 1%: Strong evidence of Granger causality"
            }
            else if `wald_pval' < 0.05 {
                di as res "{col 5}Reject H0 at 5%: Evidence of Granger causality"
            }
            else if `wald_pval' < 0.10 {
                di as res "{col 5}Reject H0 at 10%: Weak evidence of Granger causality"
            }
            else {
                di as txt "{col 5}Cannot reject H0: No evidence of Granger causality"
            }
            di
            di as txt "{col 5}Note: p-value is conservative (bounded above by chi2 per Thm 2)"
            di as txt "{col 5}      *** p<0.01, ** p<0.05, * p<0.10"
        }

        di as txt "{hline 78}"
        di

        * --- FEVD Summary ---
        if `has_fevd' {
            di as txt "{hline 78}"
            di as txt "{col 5}{bf:Forecast Error Variance Decomposition (FEVD)}"
            di as txt "{hline 78}"
            di
            di as txt "{col 5}Horizon: `irf' periods"
            di as txt "{col 5}Cholesky ordering: `varlist'"
            di as txt "{col 5}Use {bf:rbfmvar_graph, fevd} to visualize."
            di
        }

        * --- Forecast Summary ---
        if `has_forecast' {
            di as txt "{hline 78}"
            di as txt "{col 5}{bf:Out-of-Sample Forecast}"
            di as txt "{hline 78}"
            di
            di as txt "{col 5}Forecast horizon: `forecast' steps"
            di

            * Display forecast table
            di as txt %6s "Step" " {c |}" _c
            foreach v of local varlist {
                di as txt %12s "`v'" %8s "SE" _c
            }
            di
            di as txt "{hline 6}{c +}{hline 60}"
            forval s = 1/`forecast' {
                di as txt %6.0f `s' " {c |}" _c
                forval v = 1/`n_vars' {
                    local fc_val = `fcast_mat'[`v', `s']
                    local fc_se  = `fcast_se'[`v', `s']
                    di as res %12.4f `fc_val' as res %8.4f `fc_se' _c
                }
                di
            }
            di as txt "{hline 6}{c BT}{hline 60}"
            di
        }

        * --- IC Comparison Table ---
        if "`ic'" != "none" {
            di as txt "{hline 78}"
            di as txt "{col 5}{bf:Information Criteria Comparison}"
            di as txt "{hline 78}"
            di

            * Compute IC table via Mata
            mata: _rbfm_ic_table(st_data(., "`varlist'", "`touse'"), `maxlags')
            tempname ic_tbl
            capture mat `ic_tbl' = r(ic_table)
            if _rc == 0 {
                local ic_nrows = rowsof(`ic_tbl')
                di as txt %6s "Lag" %14s "AIC" %14s "BIC" %14s "HQ" %8s "T_eff"
                di as txt "{hline 56}"
                forval ir = 1/`ic_nrows' {
                    local ic_p  = `ic_tbl'[`ir', 1]
                    local ic_a  = `ic_tbl'[`ir', 2]
                    local ic_b  = `ic_tbl'[`ir', 3]
                    local ic_h  = `ic_tbl'[`ir', 4]
                    local ic_t  = `ic_tbl'[`ir', 5]

                    * Mark selected lag
                    local ic_mark ""
                    if `ic_p' == `p_use' {
                        local ic_mark " <--"
                    }

                    di as txt %6.0f `ic_p' ///
                       as res %14.4f `ic_a' ///
                       as res %14.4f `ic_b' ///
                       as res %14.4f `ic_h' ///
                       as txt %8.0f  `ic_t' ///
                       as res "`ic_mark'"
                }
                di as txt "{hline 56}"
                di as txt "{col 5}Selected: p = `p_use' by `=upper("`ic'")'"
                di
            }
        }
    }

    *--------------------------------------------------------------------------
    * ereturn results
    *--------------------------------------------------------------------------
    ereturn clear
    ereturn post , obs(`nobs') esample(`touse')

    ereturn scalar N         = `nobs'
    ereturn scalar T_eff     = `T_eff'
    ereturn scalar n_vars    = `n_vars'
    ereturn scalar p_lags    = `p_use'
    ereturn scalar bandwidth = `bw_used'

    ereturn matrix F_ols     = `F_ols'
    ereturn matrix F_plus    = `F_plus'
    ereturn matrix SE_mat    = `SE_mat'
    ereturn matrix Sigma_e   = `Sigma_e'
    ereturn matrix Pi1_ols   = `Pi1_ols'
    ereturn matrix Pi2_ols   = `Pi2_ols'
    ereturn matrix Pi1_plus  = `Pi1_plus'
    ereturn matrix Pi2_plus  = `Pi2_plus'
    ereturn matrix Omega_ev  = `Omega_ev'
    ereturn matrix Omega_vv  = `Omega_vv'
    ereturn matrix Delta_vdw = `Delta_vdw'

    capture ereturn matrix Gamma_ols  = `Gamma_ols'
    capture ereturn matrix Gamma_plus = `Gamma_plus'

    if `has_granger' {
        ereturn scalar wald_stat = `wald_stat'
        ereturn scalar wald_pval = `wald_pval'
        ereturn scalar wald_df   = `wald_df'
        ereturn local  granger   `"`granger_clean'"'
    }

    if `has_irf' {
        ereturn matrix irf       = `irf_mat'
        ereturn scalar irf_horizon = `irf'
    }

    if `has_irf_ci' {
        ereturn matrix irf_lo     = `irf_lo'
        ereturn matrix irf_hi     = `irf_hi'
        ereturn scalar irf_ci_level = `bootci'
        ereturn scalar irf_boot_reps = `bootreps'
    }

    if `has_fevd' {
        ereturn matrix fevd      = `fevd_mat'
    }

    if `has_forecast' {
        ereturn matrix forecast     = `fcast_mat'
        ereturn matrix forecast_se  = `fcast_se'
        ereturn scalar forecast_steps = `forecast'
    }

    capture ereturn matrix residuals = `resid_mat'

    ereturn local  varlist   "`varlist'"
    ereturn local  kernel    "`kernel'"
    ereturn local  ic        "`ic'"
    ereturn local  cmdline   `"rbfmvar `0'"'
    ereturn local  cmd       "rbfmvar"
end


*--------------------------------------------------------------------------
* Utility: Display a matrix nicely
*--------------------------------------------------------------------------
capture program drop _rbfmvar_display_matrix
program define _rbfmvar_display_matrix
    args mat_name

    local nr = rowsof(`mat_name')
    local nc = colsof(`mat_name')

    * Get row and column names
    local rnames : rownames `mat_name'
    local cnames : colnames `mat_name'

    * Header row
    di as txt _col(18) _c
    forval j = 1/`nc' {
        local cj : word `j' of `cnames'
        di as txt %12s "`cj'" _c
    }
    di

    * Data rows
    forval i = 1/`nr' {
        local ri : word `i' of `rnames'
        di as txt "{col 5}" %12s "`ri'" _c
        forval j = 1/`nc' {
            local val = `mat_name'[`i', `j']
            di as res %12.6f `val' _c
        }
        di
    }
end
