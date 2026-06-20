*! version 1.0.0 18may2026 Viviano, Wuthrich, Niehaus & Rosas Lopez
*! Perform hypothesis tests with optimal MHT adjustment
*! Based on Viviano, Wuthrich, and Niehaus (2026)

/*
    mht_test - Perform multiple hypothesis tests using the optimal protocol

    Given p-values or test statistics, applies the model-optimal adjustment
    from Proposition 4.1 and returns rejection decisions, adjusted critical
    values, and comparisons with Bonferroni, Holm, and BH procedures.

    Input: variable containing p-values (one-sided) or z-statistics
    Output: new variables with rejection indicators and adjusted values
*/

program define mht_test, rclass
    version 15.0
    syntax varname(numeric)        /// Variable with p-values or z-stats
           [if] [in],             ///
           ALPHAbar(real)          /// Benchmark single-hypothesis size
           [                       ///
           Zstat                   /// Input is z-statistics (default: p-values)
           MODel(string)           /// Cost model: "linear" or "cobbdouglas"
           CFshare(real 0.46)      /// Fixed cost share (Linear model)
           Jbar(real 3)           /// Average number of subgroups (Linear model)
           NMratio(real 1.0)       /// Ratio n_bar / m_bar
           BETA(real 0.13)         /// Arms elasticity (Cobb-Douglas)
           IOTA(real 0.075)        /// Sample size elasticity (Cobb-Douglas)
           GENerate(string)        /// Prefix for generated variables
           Replace                 /// Replace existing variables
           ]

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
        local model "linear"
    }

    // Default prefix
    if "`generate'" == "" {
        local generate "mht"
    }

    // Number of hypotheses = number of observations in sample
    local J = `N'

    // Convert z-stats to p-values if needed
    tempvar pval
    if "`zstat'" != "" {
        qui gen double `pval' = 1 - normal(`varlist') if `touse'
    }
    else {
        qui gen double `pval' = `varlist' if `touse'
    }

    // Compute optimal alpha using the same logic as mht_critical
    if "`model'" == "linear" {
        local ratio = `cfshare' * `jbar' / (1 - `cfshare')
        local multiplicity_adj = (1 + `ratio' / `J') / (1 + `ratio')
        local sample_adj = (`nmratio' - 1) / (1 + `ratio')
        local alpha_opt = `alphabar' * (`multiplicity_adj' + `sample_adj')
    }
    else if "`model'" == "cobbdouglas" {
        local alpha_opt = `alphabar' * `J'^(`beta' - 1) * `nmratio'^`iota'
    }
    else {
        display as error `"Model must be "linear" or "cobbdouglas""'
        exit 198
    }

    // Clamp
    local alpha_opt = min(max(`alpha_opt', 0), 1)

    // Bonferroni alpha
    local alpha_bonf = `alphabar' / `J'

    // ----- Generate rejection variables -----

    // Handle replace option
    if "`replace'" != "" {
        capture drop `generate'_reject_opt
        capture drop `generate'_reject_bonf
        capture drop `generate'_reject_holm
        capture drop `generate'_reject_bh
        capture drop `generate'_reject_unadj
        capture drop `generate'_alpha_opt
    }

    // 1. Optimal (model-based) rejection
    qui gen byte `generate'_reject_opt = (`pval' <= `alpha_opt') if `touse'
    label variable `generate'_reject_opt "Reject (Optimal MHT)"

    // 2. Bonferroni rejection
    qui gen byte `generate'_reject_bonf = (`pval' <= `alpha_bonf') if `touse'
    label variable `generate'_reject_bonf "Reject (Bonferroni)"

    // 3. Unadjusted rejection
    qui gen byte `generate'_reject_unadj = (`pval' <= `alphabar') if `touse'
    label variable `generate'_reject_unadj "Reject (Unadjusted)"

    // 4. Holm step-down procedure
    // Sort p-values, reject if p_(k) <= alpha / (J - k + 1), stop at first non-rejection
    tempvar rank_pval sorted_pval holm_reject
    qui egen `rank_pval' = rank(`pval') if `touse'
    qui gen double `sorted_pval' = . if `touse'
    qui gen byte `holm_reject' = 0 if `touse'

    // Find the Holm threshold for each rank
    forvalues k = 1/`J' {
        local holm_thresh = `alphabar' / (`J' - `k' + 1)
        // Find the observation with rank k
        qui replace `holm_reject' = 1 if `rank_pval' == `k' & `pval' <= `holm_thresh' & `touse'
    }
    // Holm is step-down: if rank k is not rejected, all ranks > k are not rejected
    // Find first non-rejection rank and zero out everything from there
    forvalues k = 1/`J' {
        local holm_thresh = `alphabar' / (`J' - `k' + 1)
        qui count if `rank_pval' == `k' & `pval' > `holm_thresh' & `touse'
        if r(N) > 0 {
            // All ranks >= k should not be rejected
            qui replace `holm_reject' = 0 if `rank_pval' >= `k' & `touse'
            continue, break
        }
    }
    qui gen byte `generate'_reject_holm = `holm_reject' if `touse'
    label variable `generate'_reject_holm "Reject (Holm)"

    // 5. Benjamini-Hochberg (BH) procedure
    // Reject if p_(k) <= k * alpha / J, using the largest such k
    tempvar bh_reject bh_threshold bh_pass
    qui gen byte `bh_reject' = 0 if `touse'
    qui gen double `bh_threshold' = `rank_pval' * `alphabar' / `J' if `touse'
    qui gen byte `bh_pass' = (`pval' <= `bh_threshold') if `touse'
    qui sum `rank_pval' if `bh_pass' == 1 & `touse', meanonly
    if r(N) > 0 {
        local max_k = r(max)
        qui replace `bh_reject' = 1 if `rank_pval' <= `max_k' & `touse'
    }
    qui gen byte `generate'_reject_bh = `bh_reject' if `touse'
    label variable `generate'_reject_bh "Reject (BH/FDR)"

    // Store optimal alpha
    qui gen double `generate'_alpha_opt = `alpha_opt' if `touse'
    label variable `generate'_alpha_opt "Optimal test size"

    // ----- Count rejections -----
    qui count if `generate'_reject_opt == 1 & `touse'
    local n_reject_opt = r(N)
    qui count if `generate'_reject_bonf == 1 & `touse'
    local n_reject_bonf = r(N)
    qui count if `generate'_reject_holm == 1 & `touse'
    local n_reject_holm = r(N)
    qui count if `generate'_reject_bh == 1 & `touse'
    local n_reject_bh = r(N)
    qui count if `generate'_reject_unadj == 1 & `touse'
    local n_reject_unadj = r(N)

    // ----- Display results -----
    display ""
    display as text "{hline 65}"
    display as result "  Multiple Hypothesis Testing Results"
    display as text "  Viviano, Wuthrich, and Niehaus (2026)"
    display as text "{hline 65}"
    display ""
    display as text "  Hypotheses tested:   " as result %6.0f `J'
    display as text "  Benchmark alpha:     " as result %9.4f `alphabar'

    if "`model'" == "linear" {
        display as text "  Cost model:          " as result "Linear"
    }
    else {
        display as text "  Cost model:          " as result "Cobb-Douglas"
    }
    display ""

    display as text "  {hline 49}"
    display as text "  Procedure              Test size    Rejections"
    display as text "  {hline 49}"
    display as text "  Optimal (model-based)" _col(28) as result %9.6f `alpha_opt' _col(42) %5.0f `n_reject_opt'
    display as text "  Bonferroni"            _col(28) as result %9.6f `alpha_bonf' _col(42) %5.0f `n_reject_bonf'
    display as text "  Holm (step-down)"      _col(28) as result %9.6f `alphabar' " *" _col(42) %5.0f `n_reject_holm'
    display as text "  BH (FDR control)"      _col(28) as result %9.6f `alphabar' " *" _col(42) %5.0f `n_reject_bh'
    display as text "  Unadjusted"            _col(28) as result %9.6f `alphabar'    _col(42) %5.0f `n_reject_unadj'
    display as text "  {hline 49}"
    display as text "  * Step-wise procedures; effective threshold varies by rank"
    display ""

    // ----- Per-hypothesis rejection table -----
    display as text "  Per-hypothesis rejection decisions:"
    display as text "  {hline 65}"
    display as text "  Hyp.    p-value     Optimal   Bonf   Holm   BH    Unadj."
    display as text "  {hline 65}"

    // Build a sequential index across in-sample observations (handles if/in)
    tempvar _row
    qui gen long `_row' = sum(`touse')
    qui replace `_row' = . if !`touse'

    local k = 0
    forvalues i = 1/`=_N' {
        if `touse'[`i'] == 0 continue
        local k = `k' + 1

        local p_k     = `pval'[`i']
        local r_opt   = cond(`generate'_reject_opt[`i']   == 1, "*", ".")
        local r_bonf  = cond(`generate'_reject_bonf[`i']  == 1, "*", ".")
        local r_holm  = cond(`generate'_reject_holm[`i']  == 1, "*", ".")
        local r_bh    = cond(`generate'_reject_bh[`i']    == 1, "*", ".")
        local r_unadj = cond(`generate'_reject_unadj[`i'] == 1, "*", ".")

        display as text "  " %3.0f `k'  ///
            "    " as result %8.4f `p_k' ///
            as text "       " "`r_opt'" ///
            "       " "`r_bonf'" ///
            "      " "`r_holm'" ///
            "    " "`r_bh'" ///
            "     " "`r_unadj'"
    }
    display as text "  {hline 65}"
    display as text "  * = reject;  . = fail to reject"
    display ""
    display as text "  Generated variables: `generate'_reject_opt, `generate'_reject_bonf,"
    display as text "    `generate'_reject_holm, `generate'_reject_bh, `generate'_reject_unadj,"
    display as text "    `generate'_alpha_opt"
    display as text "{hline 65}"
    display ""

    // Return results
    return scalar alpha_opt = `alpha_opt'
    return scalar alpha_bonf = `alpha_bonf'
    return scalar alpha_bar = `alphabar'
    return scalar J = `J'
    return scalar n_reject_opt = `n_reject_opt'
    return scalar n_reject_bonf = `n_reject_bonf'
    return scalar n_reject_holm = `n_reject_holm'
    return scalar n_reject_bh = `n_reject_bh'
    return scalar n_reject_unadj = `n_reject_unadj'
    return local model = "`model'"

end
