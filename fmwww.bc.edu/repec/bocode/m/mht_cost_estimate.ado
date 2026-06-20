*! version 1.0.0 18may2026 Viviano, Wuthrich, Niehaus & Rosas Lopez
*! Estimate cost function parameters for MHT adjustment
*! Based on Viviano, Wuthrich, and Niehaus (2026)

/*
    mht_cost_estimate - Estimate cost function parameters from data on research costs

    Given data on project costs, number of treatment arms, and sample sizes,
    estimates the parameters of the cost function and computes implied optimal
    test sizes. Supports two models:

    1. Linear: C = c_f + c_v * |J| * n
       Estimated via OLS (levels regression) to recover c_f and c_v,
       then fixed-cost share = c_f / mean(C)

    2. Cobb-Douglas: log(C) = log(k) + beta * log(|J|) + iota * log(n)
       Estimated via OLS on log-linearized equation (as in Table 2 of the paper)

    The Cobb-Douglas model is estimated by default as it is the approach
    used in the J-PAL application (Appendix A).
*/

program define mht_cost_estimate, eclass
    version 15.0
    syntax varlist(min=3 max=3 numeric)  /// cost_var arms_var samplesize_var
           [if] [in],                    ///
           ALPHAbar(real)                /// Benchmark single-hypothesis size
           [                              ///
           MODel(string)                  /// "cobbdouglas" (default) or "linear_share"
           CONTROLs(varlist)              /// Additional controls for the regression
           Robust                         /// Use robust standard errors
           CLuster(varname)               /// Cluster variable for standard errors
           TOTalsize                      /// sizevar is total sample size (J*n_bar), auto-convert to per-arm
           TABle                          /// Display critical value table
           ]

    // Parse variable names
    tokenize `varlist'
    local costvar `1'
    local armsvar `2'
    local sizevar `3'

    // Mark sample
    marksample touse
    qui count if `touse'
    local N = r(N)

    if `N' == 0 {
        display as error "No observations"
        exit 2000
    }

    // Default model
    if "`model'" == "" {
        local model "cobbdouglas"
    }

    // -------------------------------------------------------------------
    // Sample size convention warning / auto-conversion
    //
    // The paper's parameterization uses per-arm (per-subgroup) sample size
    // n_bar. The estimated iota is interpreted as the elasticity of cost
    // wrt n_bar, which feeds into the alpha formula via (n_bar/m_bar)^iota.
    // If the user passes TOTAL sample size (n_total = J * n_bar), the
    // coefficient on log(arms) becomes (beta - iota) instead of beta.
    //
    // Behavior:
    //   - default: assume sizevar is per-arm; print a one-line note.
    //   - totalsize: divide by armsvar internally before logging; report.
    // -------------------------------------------------------------------
    if "`totalsize'" != "" {
        display as text "  Note: " as result "totalsize" as text ///
            " specified -- converting `sizevar' to per-arm by dividing by `armsvar'."
    }
    else {
        display as text "  Note: `sizevar' is assumed to be PER-ARM sample size."
        display as text "        If it is total (= arms x per-arm), pass option {bf:totalsize}."
    }

    if "`model'" == "cobbdouglas" {
        // ============================================================
        // Cobb-Douglas estimation: log(C) = const + beta*log(|J|) + iota*log(n_bar) + controls
        //
        // We create named log variables prefixed with "_log_" so the
        // regression output shows meaningful names without colliding with
        // user variables. Variables are dropped at the end of the program.
        // ============================================================
        local lcost _log_`costvar'
        local larms _log_`armsvar'
        local lsize _log_`sizevar'

        // Drop any pre-existing variables with these names (clean slate)
        capture drop `lcost'
        capture drop `larms'
        capture drop `lsize'

        qui gen double `lcost' = ln(`costvar') if `touse'
        qui gen double `larms' = ln(`armsvar') if `touse'
        if "`totalsize'" != "" {
            // Convert total to per-arm: log(n_bar) = log(n_total/J)
            qui gen double `lsize' = ln(`sizevar' / `armsvar') if `touse'
            label variable `lsize' "log(`sizevar' / `armsvar') [per-arm]"
        }
        else {
            qui gen double `lsize' = ln(`sizevar') if `touse'
            label variable `lsize' "log(`sizevar') [per-arm]"
        }

        label variable `lcost' "log(`costvar')"
        label variable `larms' "log(`armsvar')"

        // Build regression command
        local regcmd "regress `lcost' `larms' `lsize'"
        if "`controls'" != "" {
            local regcmd "`regcmd' `controls'"
        }
        local regcmd "`regcmd' if `touse'"
        if "`robust'" != "" {
            local regcmd "`regcmd', robust"
        }
        else if "`cluster'" != "" {
            local regcmd "`regcmd', cluster(`cluster')"
        }

        // Run regression
        display ""
        display as text "{hline 65}"
        display as result "  Cost Function Estimation (Cobb-Douglas)"
        display as text "  log(`costvar') = const + beta*log(`armsvar') + iota*log(`sizevar')"
        display as text "{hline 65}"
        display ""

        qui `regcmd'

        // Extract coefficients
        local beta_hat = _b[`larms']
        local iota_hat = _b[`lsize']
        local beta_se  = _se[`larms']
        local iota_se  = _se[`lsize']

        // Display regression output
        `regcmd'

        display ""
        display as text "{hline 65}"
        display as result "  Hypothesis Tests on Cost Parameters"
        display as text "{hline 65}"

        // Test beta = 0 (costs invariant to arms => Bonferroni)
        qui test `larms' = 0
        local p_beta0 = r(p)
        display as text "  H0: beta = 0 (Bonferroni appropriate):     " ///
                as result "p = " %6.4f `p_beta0'

        // Test beta = 1 (costs proportional => no adjustment)
        qui test `larms' = 1
        local p_beta1 = r(p)
        display as text "  H0: beta = 1 (no adjustment needed):       " ///
                as result "p = " %6.4f `p_beta1'

        // Test iota = 0 (costs invariant to sample size)
        qui test `lsize' = 0
        local p_iota0 = r(p)
        display as text "  H0: iota = 0 (costs invariant to n):       " ///
                as result "p = " %6.4f `p_iota0'

        // Test iota = 1 (costs proportional to n)
        qui test `lsize' = 1
        local p_iota1 = r(p)
        display as text "  H0: iota = 1 (costs proportional to n):    " ///
                as result "p = " %6.4f `p_iota1'

        display as text "{hline 65}"
        display ""

        // Implied critical values
        display as text "{hline 65}"
        display as result "  Implied Optimal Test Sizes"
        display as text "  alpha(|J|, n/m) = alpha_bar * |J|^(beta-1) * (n/m)^iota"
        display as text "  Using alpha_bar = " %6.4f `alphabar'
        display as text "  beta = " %6.3f `beta_hat' ", iota = " %6.3f `iota_hat'
        display as text "{hline 65}"
        display ""

        if "`table'" != "" {
            // Display table of critical values (like Table 1 / Table 3)
            display as text "  |J|     n/m=0.5    n/m=1.0    n/m=1.5    n/m=2.0"
            display as text "  {hline 50}"
            foreach j in 1 2 3 4 5 6 7 8 9 {
                local a50  = `alphabar' * `j'^(`beta_hat' - 1) * 0.5^`iota_hat'
                local a100 = `alphabar' * `j'^(`beta_hat' - 1) * 1.0^`iota_hat'
                local a150 = `alphabar' * `j'^(`beta_hat' - 1) * 1.5^`iota_hat'
                local a200 = `alphabar' * `j'^(`beta_hat' - 1) * 2.0^`iota_hat'
                display as text "  " %2.0f `j' _col(12) ///
                    as result %8.4f `a50' _col(23) %8.4f `a100' _col(34) %8.4f `a150' _col(45) %8.4f `a200'
            }
            display as text "  {hline 50}"
            display ""
        }

        // Return results
        ereturn scalar beta = `beta_hat'
        ereturn scalar iota = `iota_hat'
        ereturn scalar beta_se = `beta_se'
        ereturn scalar iota_se = `iota_se'
        ereturn scalar p_beta0 = `p_beta0'
        ereturn scalar p_beta1 = `p_beta1'
        ereturn scalar p_iota0 = `p_iota0'
        ereturn scalar p_iota1 = `p_iota1'
        ereturn scalar alpha_bar = `alphabar'
        ereturn scalar N = `N'
        ereturn local model = "cobbdouglas"

        // Clean up generated log variables
        capture drop `lcost'
        capture drop `larms'
        capture drop `lsize'
    }
    else if "`model'" == "linear_share" {
        // ============================================================
        // Linear fixed-cost-share approach
        // Estimate: fixed cost share = c_f / (c_f + c_v * mean(|J| * n_bar))
        // Regress cost on (J * n_bar) to recover c_f and c_v.
        //
        // Use a named interaction variable (with `_` prefix) so the
        // regression output shows a meaningful name without colliding
        // with user variables.
        // ============================================================
        local jnint _`armsvar'_x_`sizevar'
        capture drop `jnint'
        if "`totalsize'" != "" {
            // Already total; just use sizevar directly (J * n_bar = total when sizevar=total/J*J)
            // For total: J * n_bar = J * (total/J) = total. So just use sizevar.
            qui gen double `jnint' = `sizevar' if `touse'
            label variable `jnint' "`sizevar' (total)"
        }
        else {
            qui gen double `jnint' = `armsvar' * `sizevar' if `touse'
            label variable `jnint' "`armsvar' x `sizevar'"
        }

        display ""
        display as text "{hline 65}"
        display as result "  Cost Function Estimation (Linear Model)"
        display as text "  `costvar' = c_f + c_v * `armsvar' * `sizevar'"
        display as text "{hline 65}"
        display ""

        local regcmd "regress `costvar' `jnint'"
        if "`controls'" != "" {
            local regcmd "`regcmd' `controls'"
        }
        local regcmd "`regcmd' if `touse'"
        if "`robust'" != "" {
            local regcmd "`regcmd', robust"
        }
        else if "`cluster'" != "" {
            local regcmd "`regcmd', cluster(`cluster')"
        }

        qui `regcmd'
        `regcmd'

        local c_f = _b[_cons]
        local c_v = _b[`jnint']

        // Compute fixed cost share
        qui sum `costvar' if `touse', meanonly
        local mean_cost = r(mean)
        local cf_share = max(0, min(1, `c_f' / `mean_cost'))

        qui sum `armsvar' if `touse', meanonly
        local mean_J = r(mean)

        display ""
        display as text "{hline 65}"
        display as result "  Estimated Parameters"
        display as text "{hline 65}"
        display as text "  Fixed cost (c_f):        " as result %12.2f `c_f'
        display as text "  Variable cost (c_v):     " as result %12.4f `c_v'
        display as text "  Fixed cost share:        " as result %12.3f `cf_share'
        display as text "  Mean arms (J_bar):       " as result %12.1f `mean_J'
        display as text "{hline 65}"
        display ""

        if "`table'" != "" {
            local ratio = `cf_share' * `mean_J' / (1 - `cf_share')
            local denom = 1 + `ratio'

            display as text "  |J|     n/m=0.5    n/m=1.0    n/m=1.5    n/m=2.0"
            display as text "  {hline 50}"
            foreach j in 1 2 3 4 5 6 7 8 9 {
                foreach nm in 0.5 1.0 1.5 2.0 {
                    local nm_key = subinstr("`nm'", ".", "p", .)
                    local a_`j'_`nm_key' = `alphabar' * ((1 + `ratio'/`j') / `denom' + (`nm' - 1) / `denom')
                }
                display as text "  " %2.0f `j' _col(12) ///
                    as result %8.4f `a_`j'_0p5' _col(23) %8.4f `a_`j'_1p0' _col(34) %8.4f `a_`j'_1p5' _col(45) %8.4f `a_`j'_2p0'
            }
            display as text "  {hline 50}"
            display ""
        }

        // Return results
        ereturn scalar c_f = `c_f'
        ereturn scalar c_v = `c_v'
        ereturn scalar cf_share = `cf_share'
        ereturn scalar mean_J = `mean_J'
        ereturn scalar alpha_bar = `alphabar'
        ereturn scalar N = `N'
        ereturn local model = "linear_share"

        // Clean up generated interaction variable
        capture drop `jnint'
    }
    else {
        display as error `"Model must be "cobbdouglas" or "linear_share""'
        exit 198
    }

end
