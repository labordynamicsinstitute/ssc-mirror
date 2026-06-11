*! _qnardl_decompose v0.1.1  27may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Partial-sum decomposition for QNARDL
*!
*! For each input variable v, generates two permanent variables v_pos and v_neg
*! holding the partial sums of positive and negative first differences:
*!
*!     v_pos_t = sum_{j=1..t} max(Dv_j - threshold, 0)
*!     v_neg_t = sum_{j=1..t} min(Dv_j - threshold, 0)
*!
*! (Shin, Yu & Greenwood-Nimmo 2014; threshold parameterisation follows
*! Cho/Greenwood-Nimmo/Shin 2020c TARDL when threshold != 0.)
*!
*! Returns in r():
*!   r(pos_vars)  space-separated names of positive partial-sum vars
*!   r(neg_vars)  space-separated names of negative partial-sum vars

program define _qnardl_decompose, rclass
    version 14.0

    syntax varlist(numeric ts) [if] [in] , ///
        [ THReshold(numlist) PREfix(string) TOUse(varname) ]

    if "`prefix'" == "" local prefix "_qnardl"

    // tsset required for D. operator
    qui tsset
    local timevar "`r(timevar)'"

    // Establish the working sample: prefer the touse passed in by the caller
    if "`touse'" == "" {
        marksample touse
    }

    // Threshold vector: 0 by default, one value applies to all, else one per var
    local k : word count `varlist'
    if "`threshold'" == "" {
        local threshold 0
    }
    local nthr : word count `threshold'
    if `nthr' == 1 {
        local thr1 : word 1 of `threshold'
        local threshold ""
        forvalues i = 1/`k' {
            local threshold "`threshold' `thr1'"
        }
    }
    else if `nthr' != `k' {
        di as error "_qnardl_decompose: threshold() must have 1 or `k' values"
        exit 198
    }

    local pos_vars ""
    local neg_vars ""

    local i = 0
    foreach v of varlist `varlist' {
        local ++i
        local thr_i : word `i' of `threshold'

        local pname "`prefix'_`v'_pos"
        local nname "`prefix'_`v'_neg"

        // Drop any previous copies from an earlier qnardl call in this session
        capture drop `pname'
        capture drop `nname'

        tempvar dv pinc ninc
        qui gen double `dv'   = D.`v' - (`thr_i') if `touse'
        qui gen double `pinc' = cond(missing(`dv'), 0, max(`dv', 0)) if `touse'
        qui gen double `ninc' = cond(missing(`dv'), 0, min(`dv', 0)) if `touse'

        // Cumulative partial sums within the working sample.
        // sum() is a running sum that skips missing.
        qui gen double `pname' = sum(`pinc') if `touse'
        qui gen double `nname' = sum(`ninc') if `touse'

        label var `pname' "partial sum of positive D.`v' (threshold `thr_i')"
        label var `nname' "partial sum of negative D.`v' (threshold `thr_i')"

        local pos_vars "`pos_vars' `pname'"
        local neg_vars "`neg_vars' `nname'"
    }

    local pos_vars : list retokenize pos_vars
    local neg_vars : list retokenize neg_vars

    return local pos_vars `pos_vars'
    return local neg_vars `neg_vars'
    return scalar k = `k'
end
