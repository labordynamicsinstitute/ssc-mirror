
*lzqreg v1.0.0

program lzqreg, eclass byable(onecall) prop(sw mi)
	version 18
    if _by() {
        local BY `"by `_byvars'`_byrc0':"'
    }
    if replay() {
        if "`BY'" != "" error 190
        if `"`e(cmd)'"' != "lzqreg" error 301
        qreg, `0'
        exit
    }

    syntax varlist(numeric fv) [fw iw pw aw] [if] [in] [, *]

    gettoken dep indep : varlist

    marksample touse

    if "`weight'" != "" local wtexp [`weight'`exp']

    // The most negative value storable in a Stata double
    local floor = -1e35

    // Smallest positive value of the outcome in the estimation sample
    tempvar dep_pos
    qui gen double `dep_pos' = `dep' if `dep' > 0 & `touse'
    qui summarize `dep_pos', meanonly
    local ln_min_pos = ln(r(min))

    // Step 1: initial sentinel = midpoint between floor and ln(min positive y)
    local sentinel = (`floor' + `ln_min_pos') / 2

    // Build transformed outcome using initial sentinel
    tempvar dep_trans
    qui gen double `dep_trans' = ///
        cond(`dep' > 0, ln(`dep'), `sentinel') if `touse'

    // Steps 2-3: iterate up to 10 times
    local success = 0
    forvalues iter = 1/10 {

        // Update transformed outcome with current sentinel
        qui replace `dep_trans' = ///
            cond(`dep' > 0, ln(`dep'), `sentinel') if `touse'

        // Run qreg on transformed outcome
        local newvarlist `dep_trans' `indep'
        quietly `BY' qreg `newvarlist' if `touse' `wtexp', `options'

        // Check whether all fitted values exceed the sentinel
        tempvar yhat
        qui predict double `yhat' if `touse', xb
        qui count if `yhat' <= `sentinel' & `touse'

        if r(N) == 0 {
            local success = 1
            continue, break
        }

        // Not all fitted values above sentinel: move sentinel halfway to floor
        local sentinel = (`floor' + `sentinel') / 2
        drop `yhat'
    }

    if `success' == 0 {
        ereturn clear
        di as err "{p}Convergence failure: after 10 iterations, some fitted values " ///
            "from quantile regression on the transformed outcome remain at or " ///
            "below the psi value; results suppressed{p_end}"
        exit 459
    }

    // Fix up e() before displaying
    ereturn local cmd     "lzqreg"
    ereturn local depvar  "ln(`dep')"
    ereturn local cmdline `"lzqreg `0'"'

    // Display header and coefficient table manually
    di ""
    di as txt "Quantile regression" ///
        _col(49) "Number of obs = " as res %8.0f e(N)
    di as txt _col(49) "Pseudo R2     = " as res %8.4f e(r2_p)
    di ""
    _coef_table, level(`level')

    // Citation disclaimer
    di ""
    di as txt "Please cite the papers underlying this command:"
    di as txt `"  Fitzgerald, J., Adema, J., Fiala, L., Kujansuu, E., & Valenta, D. (2026). "Non-Robustness in Log-Like Specifications." MetaArXiv. https://doi.org/10.31222/osf.io/juda7_v1"'
    di as txt `"  Liu, X., & Kaplan, D. M. (2025). "Quantile Regression with Log(0) Outcomes." https://drive.google.com/file/d/1F3dnhm8MrlO5aRrGt48rBWAEaBqdCBH-/view"'
end
