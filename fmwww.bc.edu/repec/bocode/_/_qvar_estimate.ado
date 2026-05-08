*! _qvar_estimate.ado — Core QVAR Estimation Engine
*! Implements Quantile Vector Autoregression following:
*!   Chavleishvili & Manganelli (2019/2024), ECB WP 2330
*!   Surprenant (2025), Bank of Canada SWP 2025-4
*!
*! The QVAR model is estimated equation-by-equation using quantile regression.
*! For each quantile τ and each variable k, the conditional τ-quantile is:
*!
*!   Q_{y_k,t}(τ | x_t) = Σ_{i≤k} a_{0,k,i}(τ) y_{i,t}
*!                        + Σ_{i=1}^{K} Σ_{j=1}^{p} a_{j,k,i}(τ) y_{i,t-j} + ε_k(τ)
*!
*! with A₀(τ) lower-triangular with zero diagonal (recursive structure).
*!
*! Version 0.1.0

program define _qvar_estimate, eclass
    version 16.0
    syntax varlist(min=2 ts), Lags(integer) ///
        [TAUs(numlist >0 <1) RECursive NORECursive ///
         MAXiter(integer 1000) TOLerance(real 1e-6)]

    // ─── Defaults ───
    if "`taus'" == "" {
        local taus "0.05 0.25 0.50 0.75 0.95"
    }

    // Recursive is default unless norecursive specified
    local do_recursive = 1
    if "`norecursive'" != "" {
        local do_recursive = 0
    }

    // ─── Variable setup ───
    local varnames "`varlist'"
    local nvars : word count `varnames'
    local ntaus : word count `taus'

    // ─── Preserve and set up time series ───
    qui tsset
    local timevar  = r(timevar)
    local panelvar = r(panelvar)

    // ─── Clean up previous results ───
    capture drop _qvar_resid_*

    // ─── Build lag matrix ───
    _qvar_build_lags `varnames', lags(`lags')
    local lagvars = r(lagvars)

    // ─── Drop missing observations from lagging ───
    tempvar touse
    mark `touse'
    markout `touse' `varnames' `lagvars'

    qui count if `touse'
    local T = r(N)

    di as text ""
    di as text "{hline 78}"
    di as result _col(20) "QVAR Estimation Results"
    di as text "{hline 78}"
    di as text "  Variables     : `varnames'"
    di as text "  Lags          : `lags'"
    di as text "  Observations  : `T'"
    di as text "  Quantiles     : `taus'"
    di as text "  Recursive     : " cond(`do_recursive', "Yes", "No")
    di as text "{hline 78}"

    // ─── Storage matrices ───
    // For each tau: store coefficients, std errors, t-stats, p-values
    // Matrix naming: _qvar_b_tau##_eq##, _qvar_se_tau##_eq##

    local tau_idx = 0
    foreach tau of numlist `taus' {
        local ++tau_idx

        // Clean tau label for matrix names (replace . with _)
        local tau_label = subinstr("`tau'", ".", "_", .)

        di as text ""
        di as text "{hline 78}"
        di as result "  Quantile τ = `tau'"
        di as text "{hline 78}"

        local eq_idx = 0
        foreach depvar of varlist `varnames' {
            local ++eq_idx

            // ─── Build regressor list for this equation ───
            local regressors ""

            // Contemporaneous variables (recursive structure)
            if `do_recursive' & `eq_idx' > 1 {
                local contemp_idx = 0
                foreach cvar of varlist `varnames' {
                    local ++contemp_idx
                    if `contemp_idx' < `eq_idx' {
                        local regressors "`regressors' `cvar'"
                    }
                }
            }

            // Lagged variables (all variables, all lags)
            local regressors "`regressors' `lagvars'"

            // ─── Quantile Regression ───
            di as text ""
            di as result "  Equation: `depvar'"
            di as text "  " "{hline 64}"

            capture noisily {
                qui qreg `depvar' `regressors' if `touse', ///
                    quantile(`tau') wlsiter(`maxiter')

                // Store results
                local nparams = e(k)
                tempname b_eq se_eq t_eq p_eq

                matrix `b_eq'  = e(b)
                matrix `se_eq' = vecdiag(e(V))

                // Compute standard errors from variance diagonal
                local ncols = colsof(`se_eq')
                forvalues j = 1/`ncols' {
                    matrix `se_eq'[1, `j'] = sqrt(`se_eq'[1, `j'])
                }

                // Display coefficient table
                di as text %20s "Variable" ///
                           %12s "Coef" ///
                           %12s "Std.Err" ///
                           %10s "t-stat" ///
                           %8s  "P>|t|" ///
                           %5s  ""
                di as text "  " "{hline 64}"

                local pnames : colnames `b_eq'
                local j = 0
                foreach pname of local pnames {
                    local ++j
                    local coef  = `b_eq'[1, `j']
                    local se    = `se_eq'[1, `j']
                    local tstat = `coef' / `se'
                    local pval  = 2 * (1 - normal(abs(`tstat')))

                    // Significance stars
                    _qvar_significance_stars `pval'
                    local stars = r(stars)

                    di as result %20s "`pname'" ///
                                 %12.6f `coef' ///
                                 %12.6f `se' ///
                                 %10.3f `tstat' ///
                                 %7.4f  `pval' ///
                                 %4s    "`stars'"
                }

                // Store matrices for post-estimation
                matrix _qvar_b_`tau_label'_eq`eq_idx' = `b_eq'
                matrix _qvar_se_`tau_label'_eq`eq_idx' = `se_eq'

                // Store residuals
                capture drop _qvar_resid_t`tau_label'_`depvar'
                qui predict double _qvar_resid_t`tau_label'_`depvar' if `touse', residuals
            }

            if _rc != 0 {
                di as error "  ⚠ QR failed for τ=`tau', equation=`depvar'"
                di as error "  Setting coefficients to missing."
            }
        }
    }

    // ─── Final summary ───
    di as text ""
    di as text "{hline 78}"
    di as text "  Significance: *** p<0.01, ** p<0.05, * p<0.1"
    di as text "{hline 78}"

    // ─── Store e-class results ───
    // (last qreg is still in e(), augment it)
    ereturn local cmd         "qvar estimate"
    ereturn local varnames    "`varnames'"
    ereturn local taus        "`taus'"
    ereturn scalar n_vars     = `nvars'
    ereturn scalar n_lags     = `lags'
    ereturn scalar n_obs      = `T'
    ereturn scalar n_taus     = `ntaus'
    ereturn scalar recursive  = `do_recursive'

    di as text ""
    di as result "  Results stored in e(). Use {cmd:ereturn list} to view."
    di as text "  Coefficient matrices: {cmd:matrix list _qvar_b_*}"
    di as text "  Residuals: variables {cmd:_qvar_resid_*}"
    di as text "{hline 78}"
end
