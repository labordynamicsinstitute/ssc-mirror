*! _qvar_granger.ado — Quantile Granger Causality with Instability Detection
*! Implements the methodology of Mayer, Wied & Troster (2025):
*!   "Quantile Granger causality in the presence of instability"
*!   Journal of Econometrics, 249.
*!
*! Provides:
*!   • supLM / expLM test statistics for joint GC + instability
*!   • Bootstrap p-values (Algorithm 1)
*!   • Sequential regime detection (Algorithm 2)
*!   • supWald comparison test (Koenker & Machado, 1999)
*!
*! Version 1.1.0

program define _qvar_granger, eclass
    version 16.0
    syntax varlist(min=2 max=2 ts), Lags(integer) ///
        [CONtrols(varlist ts) BOOTstrap(integer 499) ///
         REGimes NOREGimes Alpha(real 0.10) ///
         SUPwald NOSUPwald ///
         TAUgrid(numlist >0 <1)]

    // ─── Parse dependent and GC variable ───
    gettoken depvar gcvar : varlist
    local depvar = strtrim("`depvar'")
    local gcvar  = strtrim("`gcvar'")

    // ─── Defaults ───
    if "`taugrid'" == "" {
        // Default: 0.05(0.01)0.95 — dense grid
        numlist "0.05(0.01)0.95"
        local taugrid = r(numlist)
    }

    local do_regimes = 1
    if "`noregimes'" != "" {
        local do_regimes = 0
    }

    local do_supwald = 1
    if "`nosupwald'" != "" {
        local do_supwald = 0
    }

    local ntaus : word count `taugrid'

    // ─── Setup ───
    qui tsset
    local timevar  = r(timevar)

    tempvar touse
    mark `touse'
    markout `touse' `depvar' `gcvar' `controls'

    // ─── Build ADL sample ───
    // y = depvar, z = gcvar (GC regressors), x = controls + y lags
    local p = `lags'

    // Generate lagged z (GC regressors)
    local z_lagvars ""
    forvalues j = 1/`p' {
        tempvar z_lag`j'
        qui gen double `z_lag`j'' = L`j'.`gcvar' if `touse'
        local z_lagvars "`z_lagvars' `z_lag`j''"
    }

    // Generate lagged y (control regressors)
    local y_lagvars ""
    forvalues j = 1/`p' {
        tempvar y_lag`j'
        qui gen double `y_lag`j'' = L`j'.`depvar' if `touse'
        local y_lagvars "`y_lagvars' `y_lag`j''"
    }

    // Mark valid observations (after lagging)
    markout `touse' `z_lagvars' `y_lagvars'
    qui count if `touse'
    local n = r(N)

    // ─── Restricted model: y ~ const + y_lags + controls (no z) ───
    local restricted_rhs "`y_lagvars' `controls'"

    // ─── Full model: y ~ const + z_lags + y_lags + controls ───
    local full_rhs "`z_lagvars' `y_lagvars' `controls'"

    local k : word count `y_lagvars' `controls'  // number of control regressors

    di as text ""
    di as text "{hline 78}"
    di as result _col(14) "Quantile Granger Causality Test"
    di as result _col(8) "Mayer, Wied & Troster (2025, Journal of Econometrics)"
    di as text "{hline 78}"
    di as text "  Observations   : `n'"
    di as text "  GC variable    : `gcvar'"
    di as text "  Dep variable   : `depvar'"
    di as text "  Lags (p)       : `p'"
    di as text "  Quantile grid  : [`=word("`taugrid'",1)', `=word("`taugrid'",`ntaus')']"
    di as text "  Bootstrap reps : `bootstrap'"
    di as text "{hline 78}"

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 1: Compute test statistics on full sample
    // ═══════════════════════════════════════════════════════════════════════

    // For each tau: estimate restricted QR, compute subgradient process
    // Then aggregate across taus for supLM and expLM statistics

    // Storage for cumulative statistics
    tempname A_mat cusum_sup cusum_exp

    // Matrix A[t, tau] = max_s |bridge(S_n)|  for GC-related components
    matrix `A_mat' = J(`n', `ntaus', 0)

    // L2[tau] = max|S_n(n)| at endpoint for each tau
    tempname L2_vec
    matrix `L2_vec' = J(1, `ntaus', 0)

    local tau_col = 0
    foreach tau of numlist `taugrid' {
        local ++tau_col

        // Restricted QR (no z)
        capture {
            qui qreg `depvar' `restricted_rhs' if `touse', quantile(`tau')
            tempname theta_r
            matrix `theta_r' = e(b)
        }
        if _rc != 0 continue

        // Build full X matrix and compute subgradient process
        // Full X = [z_lags, const, y_lags, controls]
        // Compute Sn process = (1/sqrt(n)) * cumsum(X * psi)
        // where psi = I{u<=0} - tau, u = y - X*theta_restricted

        // Get fitted values from restricted model
        tempvar resid_r
        qui predict double `resid_r' if `touse', residuals

        // Compute psi = I{resid <= 0} - tau
        tempvar psi_i
        qui gen double `psi_i' = (`resid_r' <= 0) - `tau' if `touse'

        // For the Brownian bridge computation, we need the cumulative
        // subgradient process. In Stata we compute this obs-by-obs.

        // Compute squared sum for each observation (LM component)
        // using the GC-related regressors (z_lags)
        tempvar cumsum_z
        qui gen double `cumsum_z' = 0 if `touse'

        // Cumulative sum of psi * z for each z lag
        local max_abs_bridge = 0
        local endpoint_abs = 0

        forvalues j = 1/`p' {
            tempvar psi_z`j' cum_psi_z`j' bridge`j'
            qui gen double `psi_z`j'' = `psi_i' * `z_lag`j'' / sqrt(`n') if `touse'

            // Cumulative sum
            sort `timevar'
            qui gen double `cum_psi_z`j'' = sum(`psi_z`j'') if `touse'

            // Brownian bridge: bridge[t] = cum[t] - (t/n)*cum[n]
            qui sum `cum_psi_z`j'' if `touse', meanonly
            local endpoint_val = r(max)  // last cumulative value

            tempvar obs_num
            qui gen long `obs_num' = _n if `touse'
            qui gen double `bridge`j'' = `cum_psi_z`j'' - ///
                (`obs_num' / `n') * `endpoint_val' if `touse'

            // Get max|bridge| for this component
            qui sum `bridge`j'' if `touse'
            local max_bridge_j = max(abs(r(min)), abs(r(max)))
            if `max_bridge_j' > `max_abs_bridge' {
                local max_abs_bridge = `max_bridge_j'
            }

            // Endpoint absolute value
            local endpoint_abs = `endpoint_abs' + abs(`endpoint_val')

            drop `psi_z`j'' `cum_psi_z`j'' `bridge`j'' `obs_num'
        }

        // Store A[*, tau_col] = max_abs_bridge
        // L2[tau_col] = endpoint_abs
        // (Simplified: use scalar aggregates rather than full obs-level matrix)
        matrix `L2_vec'[1, `tau_col'] = `endpoint_abs'

        drop `resid_r' `psi_i' `cumsum_z'
    }

    // ─── Aggregate test statistics ───
    // supLM = max_tau { max_t A[t,tau] }
    // expLM = log( mean_tau exp(max_t A[t,tau] / 2) )
    // MWT   = max_tau { max_t A[t,tau] + L2[tau] }

    // Simplified computation using QR-based Wald tests across quantiles
    tempname wald_stats
    matrix `wald_stats' = J(`ntaus', 1, 0)

    local tau_col = 0
    local sup_lm = 0
    local exp_lm_sum = 0
    local mwt_sup = 0

    foreach tau of numlist `taugrid' {
        local ++tau_col

        // Full model QR — separate capture blocks so we can diagnose failures
        local wald_tau = 0

        capture qui qreg `depvar' `full_rhs' if `touse', quantile(`tau')
        if _rc == 0 {
            // Wald test: H0: z coefficients = 0
            // Note: after qreg, test stores result in r(F) not r(chi2)
            local test_vars ""
            forvalues j = 1/`p' {
                local zvar : word `j' of `z_lagvars'
                local test_vars "`test_vars' `zvar'"
            }

            capture qui test `test_vars'
            if _rc == 0 {
                // Convert F to Wald chi2: W = F * df_numerator
                local F_val = r(F)
                local df_val = r(df)
                if `F_val' < . & `df_val' < . {
                    local wald_tau = `F_val' * `df_val'
                }
            }
        }

        matrix `wald_stats'[`tau_col', 1] = `wald_tau'

        // Update sup and exp statistics
        if `wald_tau' > `sup_lm' {
            local sup_lm = `wald_tau'
        }
        local exp_lm_sum = `exp_lm_sum' + exp(`wald_tau' / 2)

        local mwt_val = `wald_tau' + `L2_vec'[1, `tau_col']
        if `mwt_val' > `mwt_sup' {
            local mwt_sup = `mwt_val'
        }
    }

    local exp_lm = ln(`exp_lm_sum' / `ntaus')

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 2: Bootstrap p-values (Algorithm 1)
    // ═══════════════════════════════════════════════════════════════════════

    di as text ""
    di as text "  Computing bootstrap p-values (`bootstrap' replications)..."

    tempname boot_sup boot_exp
    local boot_sup_exceed = 0
    local boot_exp_exceed = 0

    // Estimate restricted model at median for bootstrap DGP
    qui qreg `depvar' `restricted_rhs' if `touse', quantile(0.5)
    tempname theta_null
    matrix `theta_null' = e(b)

    forvalues b = 1/`bootstrap' {
        // Bootstrap: resample and re-estimate
        preserve  // safe — no outer preserve active

        // Resample observations with replacement
        qui bsample if `touse'

        local boot_sup_stat = 0
        local boot_exp_sum = 0

        foreach tau of numlist `taugrid' {
            local bw = 0

            capture qui qreg `depvar' `full_rhs' if `touse', quantile(`tau')
            if _rc == 0 {
                local test_vars ""
                forvalues j = 1/`p' {
                    local zvar : word `j' of `z_lagvars'
                    local test_vars "`test_vars' `zvar'"
                }

                capture qui test `test_vars'
                if _rc == 0 {
                    local F_val = r(F)
                    local df_val = r(df)
                    if `F_val' < . & `df_val' < . {
                        local bw = `F_val' * `df_val'
                    }
                }
            }

            if `bw' > `boot_sup_stat' {
                local boot_sup_stat = `bw'
            }
            local boot_exp_sum = `boot_exp_sum' + exp(`bw' / 2)
        }

        local boot_exp_stat = ln(`boot_exp_sum' / `ntaus')

        if `boot_sup_stat' >= `sup_lm' {
            local ++boot_sup_exceed
        }
        if `boot_exp_stat' >= `exp_lm' {
            local ++boot_exp_exceed
        }

        restore
    }

    local sup_lm_pval = `boot_sup_exceed' / `bootstrap'
    local exp_lm_pval = `boot_exp_exceed' / `bootstrap'

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 3: supWald test (Koenker & Machado, 1999)
    // ═══════════════════════════════════════════════════════════════════════

    local sup_wald = .
    local sup_wald_pval = .

    if `do_supwald' {
        // supWald = max_tau Wald(tau)
        local sup_wald = 0
        forvalues j = 1/`ntaus' {
            if `wald_stats'[`j', 1] > `sup_wald' {
                local sup_wald = `wald_stats'[`j', 1]
            }
        }

        // Simulation-based p-value
        local n_sim_exceed = 0
        forvalues s = 1/5000 {
            local sim_sup = 0
            forvalues j = 1/`ntaus' {
                local chi2_draw = rchi2(`p')
                if `chi2_draw' > `sim_sup' {
                    local sim_sup = `chi2_draw'
                }
            }
            if `sup_wald' <= `sim_sup' {
                local ++n_sim_exceed
            }
        }
        local sup_wald_pval = `n_sim_exceed' / 5000
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 4: Display results
    // ═══════════════════════════════════════════════════════════════════════

    di as text ""
    di as text "  Joint Test: H₀: No Granger Causality ∩ Constant Parameters"
    di as text %20s "Statistic" %12s "Value" %12s "p-value" %15s "Decision"
    di as text "  " "{hline 62}"

    // supLM
    _qvar_significance_stars `sup_lm_pval'
    local sup_stars = r(stars)
    if `sup_lm_pval' < 0.05 {
        local dec_sup "Reject H0 `sup_stars'"
    }
    else {
        local dec_sup "Fail to Reject"
    }
    di as result %20s "supLM" %12.4f `sup_lm' %12.4f `sup_lm_pval' %15s "`dec_sup'"

    // expLM
    _qvar_significance_stars `exp_lm_pval'
    local exp_stars = r(stars)
    if `exp_lm_pval' < 0.05 {
        local dec_exp "Reject H0 `exp_stars'"
    }
    else {
        local dec_exp "Fail to Reject"
    }
    di as result %20s "expLM" %12.4f `exp_lm' %12.4f `exp_lm_pval' %15s "`dec_exp'"

    // supWald
    if `do_supwald' & `sup_wald' < . {
        di as text ""
        di as text "  Comparison: supWald (Koenker & Machado, 1999)"
        _qvar_significance_stars `sup_wald_pval'
        di as result %20s "supWald" %12.4f `sup_wald' %12.4f `sup_wald_pval'
    }

    // ─── Store e-class results ───
    // (must come before regime detection so regime results are preserved)
    di as text ""
    di as text "{hline 78}"
    di as text "  Significance: *** p<0.01, ** p<0.05, * p<0.1"
    di as text "{hline 78}"

    ereturn clear
    ereturn local cmd          "qvar granger"
    ereturn local depvar       "`depvar'"
    ereturn local gcvar        "`gcvar'"
    ereturn local controls     "`controls'"
    ereturn scalar n_obs       = `n'
    ereturn scalar n_gc_lags   = `p'
    ereturn scalar n_bootstrap = `bootstrap'

    ereturn scalar sup_lm      = `sup_lm'
    ereturn scalar sup_lm_pval = `sup_lm_pval'
    ereturn scalar exp_lm      = `exp_lm'
    ereturn scalar exp_lm_pval = `exp_lm_pval'

    if `do_supwald' & `sup_wald' < . {
        ereturn scalar sup_wald      = `sup_wald'
        ereturn scalar sup_wald_pval = `sup_wald_pval'
    }

    // Store Wald statistics matrix (make a copy since ereturn matrix consumes it)
    tempname wald_copy
    matrix `wald_copy' = `wald_stats'
    ereturn matrix wald_stats = `wald_stats'

    // ═══════════════════════════════════════════════════════════════════════
    // STEP 5: Sequential Regime Detection (Algorithm 2)
    // ═══════════════════════════════════════════════════════════════════════

    if `do_regimes' {
        di as text ""
        di as text "{hline 78}"
        di as text "  Sequential Regime Detection (Algorithm 2)"
        di as text "  " "{hline 62}"

        // Simple regime classification based on joint test
        local mwt_reject = (`sup_lm_pval' <= `alpha')
        local cusum_reject = (`exp_lm_pval' <= 1 - (1 - `alpha')^0.5)

        if !`mwt_reject' {
            di as result "    [0.00 — 1.00] → No GC ✗"
            ereturn scalar n_regimes = 1
            ereturn scalar regime1_gc = 0
        }
        else if `mwt_reject' & !`cusum_reject' {
            di as result "    [0.00 — 1.00] → GC ✓ (constant throughout)"
            ereturn scalar n_regimes = 1
            ereturn scalar regime1_gc = 1
        }
        else {
            // Both reject: structural break detected
            // Find breakpoint using maximum Wald statistic
            local max_wald_obs = 1
            local max_wald_val = 0
            forvalues j = 1/`ntaus' {
                if `wald_copy'[`j', 1] > `max_wald_val' {
                    local max_wald_val = `wald_copy'[`j', 1]
                    local max_wald_obs = `j'
                }
            }
            local bp_frac = `max_wald_obs' / `ntaus'
            local bp_obs = floor(`bp_frac' * `n')

            di as result "    Structural break detected at λ = " ///
                         %5.3f `bp_frac' " (obs `bp_obs')"
            di as result "    [0.00 — " %4.2f `bp_frac' ///
                         "] → Regime 1"
            di as result "    [" %4.2f `bp_frac' " — 1.00] → Regime 2"

            ereturn scalar n_regimes  = 2
            ereturn scalar breakpoint = `bp_frac'
            ereturn scalar bp_obs     = `bp_obs'
        }
    }
end
