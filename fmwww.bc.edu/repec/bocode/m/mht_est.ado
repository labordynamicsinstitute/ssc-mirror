*! version 1.0.0 18may2026 Viviano, Wuthrich, Niehaus & Rosas Lopez
*! mht_est -- MHT adjustment postestimation command
*! Based on Viviano, Wuthrich, and Niehaus (2026)
*! "A Model of Multiple Hypothesis Testing"

/*
    mht_est -- Optimal MHT correction applied to postestimation results

    Works after any Stata estimation command (regress, logit, ivregress,
    areg, xtreg, etc.) by reading coefficients and standard errors directly
    from e(b) and e(V). Follows the postestimation paradigm described in
    Stata [U] 20 Estimation and postestimation commands.

    Syntax:
        mht_est, vars(varlist) alphabar(#) [options]

    Example:
        . regress y treat1 treat2 treat3 controls, cluster(hh_id)
        . mht_est, vars(treat1 treat2 treat3) alphabar(0.05)

        . logit y treat1 treat2 treat3, robust
        . mht_est, vars(treat1 treat2 treat3) alphabar(0.05)

    Options:
        vars(varlist)    : names of coefficients to test (required)
        alphabar(#)      : benchmark single-hypothesis significance level
        model(string)    : linear (default) or cobbdouglas
        cfshare(#)       : fixed cost share (Linear model; default 0.46)
        jbar(#)          : average subgroups (Linear model; default 3)
        nmratio(#)       : sample size ratio n_bar/m_bar (default 1.0)
        mbar(#)          : benchmark per-arm sample size; if given, nm_ratio is
                           computed as (e(N)/J)/mbar (overrides nmratio)
        beta(#)          : arms elasticity (Cobb-Douglas; default 0.13)
        iota(#)          : size elasticity (Cobb-Douglas; default 0.075)
        onesided         : use one-sided p-values, positive direction (default)
        twosided         : use two-sided p-values instead

    Stored results (r()):
        Scalars:
            r(alpha_opt)       optimal test size
            r(alpha_bonf)      Bonferroni test size
            r(alpha_bar)       benchmark alpha
            r(J)               number of hypotheses
            r(nm_ratio)        sample size ratio used
            r(n_reject_opt)    rejections under optimal procedure
            r(n_reject_bonf)   rejections under Bonferroni
            r(n_reject_holm)   rejections under Holm
            r(n_reject_bh)     rejections under BH/FDR
            r(n_reject_unadj)  rejections unadjusted
            r(coef_<varname>)  coefficient for each tested variable
            r(se_<varname>)    standard error for each tested variable
            r(t_<varname>)     t-statistic for each tested variable
            r(p_<varname>)     p-value used for each tested variable
            r(rej_opt_<varname>)  1 if rejected under optimal, 0 otherwise
        Macros:
            r(model)           cost model used
            r(vars)            variable list tested
            r(cmd)             estimation command (from e(cmd))
*/

program define mht_est, rclass
    version 15.0
    syntax , Vars(namelist)            ///
             ALPHAbar(real)             ///
             [                          ///
             MODel(string)              ///  linear or cobbdouglas
             CFshare(real 0.46)         ///  Linear: fixed cost share
             Jbar(real 3)              ///  Linear: avg subgroups
             NMratio(real 1.0)          ///  sample size ratio (overridden by mbar if given)
             MBar(real -1)              ///  benchmark per-arm sample size; nm_ratio = (e(N)/J)/mbar
             BETA(real 0.13)            ///  Cobb-Douglas: arms elasticity
             IOTA(real 0.075)           ///  Cobb-Douglas: size elasticity
             ONEsided                   ///  use one-sided p-values (default)
             TWOsided                   ///  use two-sided p-values
             ]

    // ------------------------------------------------------------------
    // 1. Validate prerequisites
    // ------------------------------------------------------------------

    if "`e(cmd)'" == "" {
        display as error "mht_est: no estimation results in memory."
        display as error "  Run an estimation command (regress, logit, etc.) first."
        exit 301
    }

    if `alphabar' <= 0 | `alphabar' >= 1 {
        display as error "alphabar() must be strictly between 0 and 1"
        exit 198
    }

    if "`onesided'" != "" & "`twosided'" != "" {
        display as error "Cannot specify both onesided and twosided"
        exit 198
    }

    // Default model
    if "`model'" == "" local model "linear"
    if "`model'" != "linear" & "`model'" != "cobbdouglas" {
        display as error `"model() must be "linear" or "cobbdouglas""'
        exit 198
    }

    // P-value direction: default is onesided
    if "`twosided'" != "" {
        local side "two"
    }
    else {
        local side "one"
    }

    // ------------------------------------------------------------------
    // 2. Copy e(b) and e(V) into temp matrices; capture e(N) for mbar
    // ------------------------------------------------------------------

    local n_obs = e(N)   // capture before anything overwrites e()

    tempname b_mat V_mat
    matrix `b_mat' = e(b)
    matrix `V_mat' = e(V)

    // Degrees of freedom for t-distribution (use if available)
    local df_r = .
    capture local df_r = e(df_r)
    if _rc != 0 | `df_r' == . | `df_r' <= 0 {
        local df_r = .
    }

    // ------------------------------------------------------------------
    // 3. Extract coefficients and compute p-values for each variable
    // ------------------------------------------------------------------

    local vlist `vars'
    local J : word count `vlist'

    if `J' < 1 {
        display as error "vars() must contain at least one variable name"
        exit 198
    }

    // If mbar supplied, override nmratio: nm_ratio = (e(N)/J) / mbar
    if `mbar' > 0 {
        if `n_obs' == . {
            display as error "mht_est: e(N) not available; cannot compute nm_ratio from mbar."
            exit 198
        }
        local nmratio = (`n_obs' / `J') / `mbar'
    }

    forvalues i = 1/`J' {
        local vn : word `i' of `vlist'

        // Look up column index in e(b)
        local cidx = colnumb(`b_mat', "`vn'")
        if `cidx' == . {
            display as error "mht_est: variable '`vn'' not found in e(b)."
            display as error "  Check spelling. Use -ereturn list- to see available names."
            exit 198
        }

        // Extract coefficient and SE
        local b_`i'  = `b_mat'[1, `cidx']
        local var_`i' = `V_mat'[`cidx', `cidx']
        if `var_`i'' <= 0 {
            display as error "mht_est: variance for '`vn'' is non-positive. Cannot compute SE."
            exit 198
        }
        local se_`i' = sqrt(`var_`i'')
        local t_`i'  = `b_`i'' / `se_`i''

        // Two-sided p-value
        if `df_r' < . {
            local p2_`i' = 2 * ttail(`df_r', abs(`t_`i''))
        }
        else {
            // Large-sample normal approximation
            local p2_`i' = 2 * (1 - normal(abs(`t_`i'')))
        }

        // One-sided p-value (upper tail, positive direction)
        if "`side'" == "one" {
            if `t_`i'' >= 0 {
                local p_`i' = `p2_`i'' / 2
            }
            else {
                // Negative effect: p-value > 0.5, will not be rejected
                local p_`i' = 1 - `p2_`i'' / 2
            }
        }
        else {
            local p_`i' = `p2_`i''
        }
    }

    // ------------------------------------------------------------------
    // 4. Compute optimal alpha via mht_critical (Proposition 4.1)
    // ------------------------------------------------------------------

    quietly mht_critical, jhypotheses(`J') alphabar(`alphabar') ///
        model(`model') cfshare(`cfshare') jbar(`jbar')          ///
        nmratio(`nmratio') beta(`beta') iota(`iota')

    local alpha_opt  = r(alpha_opt)
    local alpha_bonf = r(alpha_bonf)

    // ------------------------------------------------------------------
    // 5. Holm step-down and BH step-up (sort p-values, map back)
    // ------------------------------------------------------------------

    // Initialize sorted arrays (copy p-values with original indices)
    forvalues i = 1/`J' {
        local sp_`i' = `p_`i''
        local si_`i' = `i'
    }

    // Selection sort: ascending order of p-values
    forvalues i = 1/`J' {
        local min_val = `sp_`i''
        local min_k   = `i'
        local jstart  = `i' + 1
        if `jstart' <= `J' {
            forvalues k = `jstart'/`J' {
                if `sp_`k'' < `min_val' {
                    local min_val = `sp_`k''
                    local min_k   = `k'
                }
            }
        }
        if `min_k' != `i' {
            local tmp_p  = `sp_`i''
            local tmp_i  = `si_`i''
            local sp_`i' = `sp_`min_k''
            local si_`i' = `si_`min_k''
            local sp_`min_k' = `tmp_p'
            local si_`min_k' = `tmp_i'
        }
    }
    // Now: sp_1 <= sp_2 <= ... <= sp_J, si_k = original 1-based index

    // Holm step-down: reject rank k if p_(k) <= alpha/(J-k+1)
    // Stop at first non-rejection; do not reject any subsequent rank
    local holm_stop = 0
    forvalues k = 1/`J' {
        local holm_thresh_k = `alphabar' / (`J' - `k' + 1)
        if `holm_stop' == 0 & `sp_`k'' <= `holm_thresh_k' {
            local holm_sorted_`k' = 1
        }
        else {
            local holm_sorted_`k' = 0
            local holm_stop = 1
        }
    }

    // BH: find largest rank k* where p_(k) <= k*alpha/J
    // Reject all ranks 1..k*
    local bh_max_k = 0
    forvalues k = 1/`J' {
        local bh_thresh_k = `k' * `alphabar' / `J'
        if `sp_`k'' <= `bh_thresh_k' {
            local bh_max_k = `k'
        }
    }

    // Map sorted rejections back to original variable order
    forvalues i = 1/`J' {
        local holm_rej_`i' = 0
        local bh_rej_`i'   = 0
    }
    forvalues k = 1/`J' {
        local orig = `si_`k''
        local holm_rej_`orig' = `holm_sorted_`k''
        if `k' <= `bh_max_k' {
            local bh_rej_`orig' = 1
        }
    }

    // ------------------------------------------------------------------
    // 6. Count rejections
    // ------------------------------------------------------------------

    local n_opt = 0
    local n_bonf = 0
    local n_holm = 0
    local n_bh   = 0
    local n_unadj = 0

    forvalues i = 1/`J' {
        if `p_`i'' <= `alpha_opt'  local n_opt   = `n_opt'   + 1
        if `p_`i'' <= `alpha_bonf' local n_bonf  = `n_bonf'  + 1
        if `holm_rej_`i''          local n_holm  = `n_holm'  + 1
        if `bh_rej_`i''            local n_bh    = `n_bh'    + 1
        if `p_`i'' <= `alphabar'   local n_unadj = `n_unadj' + 1
    }

    // ------------------------------------------------------------------
    // 7. Display results
    // ------------------------------------------------------------------

    local model_str = cond("`model'" == "linear", "Linear (Eq. 26)", "Cobb-Douglas (App. A)")
    local side_str  = cond("`side'" == "one", "one-sided (positive direction)", "two-sided")
    local est_cmd   = "`e(cmd)'"

    display ""
    display as text "{hline 72}"
    display as result "  MHT Postestimation Results"
    display as text "  Viviano, Wuthrich, and Niehaus (2026)"
    display as text "  After: " as result "`est_cmd'"
    display as text "{hline 72}"
    display ""
    display as text "  Hypotheses tested:   " as result %4.0f `J'
    display as text "  Benchmark alpha:     " as result %6.4f `alphabar'
    display as text "  Cost model:          " as result "`model_str'"
    display as text "  P-values:            " as result "`side_str'"
    display as text "  n/m ratio:           " as result %6.4f `nmratio'
    display ""
    display as text "  {hline 58}"
    display as text "  Procedure              Test size    Rejections"
    display as text "  {hline 58}"
    display as text "  Optimal (model-based)" _col(30) as result %9.6f `alpha_opt'  _col(44) %5.0f `n_opt'
    display as text "  Bonferroni"            _col(30) as result %9.6f `alpha_bonf' _col(44) %5.0f `n_bonf'
    display as text "  Holm (step-down)"      _col(30) as result "  step-wise"      _col(44) %5.0f `n_holm'
    display as text "  BH (FDR control)"      _col(30) as result "  step-wise"      _col(44) %5.0f `n_bh'
    display as text "  Unadjusted"            _col(30) as result %9.6f `alphabar'   _col(44) %5.0f `n_unadj'
    display as text "  {hline 58}"
    display ""
    display as text "  Coefficient-level results:"
    display ""
    display as text "  Variable            Coef.     SE      t-stat  p-val   Opt  Bonf Holm BH   Unadj"
    display as text "  {hline 80}"

    forvalues i = 1/`J' {
        local vn : word `i' of `vlist'
        local r_opt   = cond(`p_`i'' <= `alpha_opt',  "*", ".")
        local r_bonf  = cond(`p_`i'' <= `alpha_bonf', "*", ".")
        local r_holm  = cond(`holm_rej_`i'',           "*", ".")
        local r_bh    = cond(`bh_rej_`i'',             "*", ".")
        local r_unadj = cond(`p_`i'' <= `alphabar',   "*", ".")

        display as text "  " %-18s "`vn'" ///
            as result %8.4f `b_`i'' "  " %6.4f `se_`i'' ///
            "  " %6.3f `t_`i'' "  " %6.4f `p_`i'' ///
            "    " %-2s "`r_opt'" ///
            "    " %-4s "`r_bonf'" ///
            "   " %-4s "`r_holm'" ///
            "   " %-2s "`r_bh'" ///
            "    " %-5s "`r_unadj'"
    }

    display as text "  {hline 80}"
    display as text "  * = reject;  . = fail to reject"
    display ""

    // ------------------------------------------------------------------
    // 8. Store results in r()
    // ------------------------------------------------------------------

    return scalar alpha_opt      = `alpha_opt'
    return scalar alpha_bonf     = `alpha_bonf'
    return scalar alpha_bar      = `alphabar'
    return scalar J              = `J'
    return scalar nm_ratio       = `nmratio'
    return scalar n_reject_opt   = `n_opt'
    return scalar n_reject_bonf  = `n_bonf'
    return scalar n_reject_holm  = `n_holm'
    return scalar n_reject_bh    = `n_bh'
    return scalar n_reject_unadj = `n_unadj'
    return local  model          = "`model'"
    return local  vars           = "`vars'"
    return local  cmd            = "`est_cmd'"

    // Per-variable results for programmatic access
    forvalues i = 1/`J' {
        local vn : word `i' of `vlist'
        return scalar coef_`vn'    = `b_`i''
        return scalar se_`vn'      = `se_`i''
        return scalar t_`vn'       = `t_`i''
        return scalar p_`vn'       = `p_`i''
        return scalar rej_opt_`vn' = (`p_`i'' <= `alpha_opt')
        return scalar rej_bonf_`vn' = (`p_`i'' <= `alpha_bonf')
        return scalar rej_holm_`vn' = `holm_rej_`i''
        return scalar rej_bh_`vn'   = `bh_rej_`i''
    }

end
