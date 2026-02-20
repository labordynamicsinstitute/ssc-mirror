*! _fbnardl_diagtest — Diagnostic Tests for FBNARDL
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fbnardl_diagtest
program define _fbnardl_diagtest
    version 17
    args residvar nobs nparams

    // Note: nobs and nparams are passed from the calling program.
    // The last regression must still be active in e() for estat commands.

    // =========================================================================
    // NORMALITY TESTS
    // =========================================================================
    di as txt ""
    di as txt "  A. Normality Tests"
    di as txt "  {hline 60}"

    // Jarque-Bera / Normality test
    // Primary: use Stata's sktest (D'Agostino, Belanger & D'Agostino, 1990
    //          with Royston 1991 adjustment) — returns adjusted chi2
    // Fallback: manual JB = n*(S^2/6 + (K-3)^2/24)
    tempvar resid_copy
    qui gen double `resid_copy' = `residvar'

    local jb_stat = .
    local jb_pval = .

    // Method 1: sktest (preferred — adjusted for sample size)
    capture qui sktest `resid_copy'
    if _rc == 0 & !missing(r(chi2)) {
        local jb_stat = r(chi2)
        local jb_pval = r(P_chi2)
    }
    else {
        // Method 2: Manual Jarque-Bera computation
        // JB = n * (S^2/6 + (K-3)^2/24), chi2(2) under H0
        qui sum `resid_copy', detail
        local resid_n = r(N)
        local resid_skew = r(skewness)
        local resid_kurt = r(kurtosis)
        if !missing(`resid_skew') & !missing(`resid_kurt') {
            local jb_stat = `resid_n' * ((`resid_skew'^2)/6 + ((`resid_kurt' - 3)^2)/24)
            if `jb_stat' < 0 local jb_stat = 0
            local jb_pval = chi2tail(2, `jb_stat')
        }
    }

    if !missing(`jb_stat') {
        di as txt "  " _col(5) "Jarque-Bera" _col(30) "Chi2 = " %10.4f `jb_stat' _col(50) "p = " %6.4f `jb_pval' _c
        _fbnardl_stars `jb_pval'
    }
    else {
        di as txt "  " _col(5) "Jarque-Bera" _col(30) "Not available"
    }

    // Shapiro-Wilk test
    capture qui swilk `resid_copy'
    if _rc == 0 {
        local sw_stat = r(W)
        local sw_pval = r(p)
        di as txt "  " _col(5) "Shapiro-Wilk" _col(30) "W = " %10.4f `sw_stat' _col(50) "p = " %6.4f `sw_pval' _c
        _fbnardl_stars `sw_pval'
    }

    // Shapiro-Francia (for large samples)
    capture qui sfrancia `resid_copy'
    if _rc == 0 {
        local sf_stat = r(W)
        local sf_pval = r(p)
        di as txt "  " _col(5) "Shapiro-Francia" _col(30) "W' = " %10.4f `sf_stat' _col(50) "p = " %6.4f `sf_pval' _c
        _fbnardl_stars `sf_pval'
    }

    di as txt "  {hline 60}"

    // =========================================================================
    // SERIAL CORRELATION TESTS
    // =========================================================================
    di as txt ""
    di as txt "  B. Serial Correlation Tests"
    di as txt "  {hline 60}"

    // Breusch-Godfrey LM test (run separately for each lag)
    forvalues lag = 1/4 {
        capture {
            qui estat bgodfrey, lags(`lag')
            tempname _bg_chi2m _bg_pm
            mat `_bg_chi2m' = r(chi2)
            mat `_bg_pm' = r(p)
            local bg_chi2 = `_bg_chi2m'[1,1]
            local bg_p = `_bg_pm'[1,1]
        }
        if _rc == 0 {
            di as txt "  " _col(5) "B-G LM(lag=`lag')" _col(30) "Chi2 = " %10.4f `bg_chi2' _col(50) "p = " %6.4f `bg_p' _c
            _fbnardl_stars `bg_p'
        }
    }

    // Durbin-Watson (informational only — not valid with lagged dep var)
    capture {
        qui estat dwatson
        local dw_val = r(dw)
    }
    if _rc == 0 {
        di as txt "  " _col(5) "Durbin-Watson" _col(30) "d = " %10.4f `dw_val' _col(50) "(informational)"
    }

    di as txt "  {hline 60}"

    // =========================================================================
    // HETEROSKEDASTICITY TESTS
    // =========================================================================
    di as txt ""
    di as txt "  C. Heteroskedasticity Tests"
    di as txt "  {hline 60}"

    // Breusch-Pagan
    capture {
        qui estat hettest
        local bp_chi2 = r(chi2)
        local bp_p = r(p)
    }
    if _rc == 0 {
        di as txt "  " _col(5) "Breusch-Pagan" _col(30) "Chi2 = " %10.4f `bp_chi2' _col(50) "p = " %6.4f `bp_p' _c
        _fbnardl_stars `bp_p'
    }
    else {
        di as txt "  " _col(5) "Breusch-Pagan: Not available"
    }

    // White's test
    capture {
        qui estat imtest, white
        local w_chi2 = r(chi2)
        local w_p = r(p)
    }
    if _rc == 0 {
        di as txt "  " _col(5) "White's test" _col(30) "Chi2 = " %10.4f `w_chi2' _col(50) "p = " %6.4f `w_p' _c
        _fbnardl_stars `w_p'
    }

    // ARCH LM test
    capture {
        qui estat archlm, lags(1)
        local arch_chi2 = r(chi2)
        local arch_p = r(p)
    }
    if _rc == 0 {
        di as txt "  " _col(5) "ARCH LM(1)" _col(30) "Chi2 = " %10.4f `arch_chi2' _col(50) "p = " %6.4f `arch_p' _c
        _fbnardl_stars `arch_p'
    }
    else {
        di as txt "  " _col(5) "ARCH LM: Not available"
    }

    di as txt "  {hline 60}"

    // =========================================================================
    // FUNCTIONAL FORM / STABILITY TESTS
    // =========================================================================
    di as txt ""
    di as txt "  D. Functional Form / Stability Tests"
    di as txt "  {hline 60}"

    // Ramsey RESET
    capture {
        qui estat ovtest
        local reset_f = r(F)
        local reset_p = r(p)
    }
    if _rc == 0 {
        di as txt "  " _col(5) "Ramsey RESET" _col(30) "F = " %10.4f `reset_f' _col(50) "p = " %6.4f `reset_p' _c
        _fbnardl_stars `reset_p'
    }
    else {
        di as txt "  " _col(5) "Ramsey RESET: Not available"
    }

    di as txt "  {hline 60}"

    // =========================================================================
    // CUSUM AND CUSUM-SQ TESTS
    // =========================================================================
    di as txt ""
    di as txt "  E. Stability Tests (CUSUM & CUSUM-SQ)"
    di as txt "  {hline 60}"

    // CUSUM test
    _fbnardl_cusum `resid_copy' `nparams' `nobs'

    // CUSUM of Squares test
    _fbnardl_cumsq `resid_copy' `nparams' `nobs'

    di as txt "  {hline 60}"
    di as txt "{hline 70}"

end


// =============================================================================
// CUSUM Test
// =============================================================================
capture program drop _fbnardl_cusum
program define _fbnardl_cusum
    version 17
    args residvar k n

    // Compute CUSUM statistic
    tempvar w
    qui gen double `w' = `residvar'
    qui sum `w'
    local w_sd = r(sd)
    qui replace `w' = sum(`w' / `w_sd')

    // Critical value at 5%
    local c_val = 0.948

    // Get max absolute CUSUM / boundary ratio
    qui sum `w'
    local cusum_max = max(abs(r(min)), abs(r(max)))

    local boundary = `c_val' * sqrt(`n' - `k') + 2 * `c_val' * sqrt(`n' - `k')
    local cusum_ratio = `cusum_max' / `boundary'

    if `cusum_max' <= `boundary' {
        di as txt "  " _col(5) "CUSUM test" _col(30) "Max|CUSUM| = " %8.3f `cusum_max'
        di as res "  " _col(5) "  => Stable at 5% (within bounds)"
    }
    else {
        di as txt "  " _col(5) "CUSUM test" _col(30) "Max|CUSUM| = " %8.3f `cusum_max'
        di as err "  " _col(5) "  => UNSTABLE at 5% (exceeds bounds)"
    }

    // Generate CUSUM plot
    capture {
        tempvar cusum_var cusum_upper cusum_lower cusum_x
        local nres = `n' - `k'
        qui gen `cusum_x' = _n if _n <= `nres'
        qui gen double `cusum_var' = `w' if _n <= `nres'
        qui gen double `cusum_upper' = `c_val' * sqrt(`n' - `k') + ///
            2 * `c_val' * sqrt(`n' - `k') * (`cusum_x' - `k') / `nres' if `cusum_x' != .
        qui gen double `cusum_lower' = -`c_val' * sqrt(`n' - `k') + ///
            (-2 * `c_val' * sqrt(`n' - `k')) * (`cusum_x' - `k') / `nres' if `cusum_x' != .

        twoway (line `cusum_var' `cusum_x', lcolor(blue) lwidth(medium)) ///
               (line `cusum_upper' `cusum_x', lcolor(red) lpattern(dash) lwidth(medium)) ///
               (line `cusum_lower' `cusum_x', lcolor(red) lpattern(dash) lwidth(medium)), ///
               title("CUSUM Test", size(medium)) ///
               subtitle("FBNARDL Model", size(small)) ///
               ytitle("CUSUM", size(small)) xtitle("Observation", size(small)) ///
               legend(order(1 "CUSUM" 2 "5% Critical Bounds") size(small)) ///
               note("fbnardl package", size(vsmall)) ///
               scheme(s2color) name(cusum_fbnardl, replace)

        qui graph export "cusum_fbnardl.png", replace width(1200)
        di as txt "  " _col(5) "  Graph saved: cusum_fbnardl.png"
    }
end


// =============================================================================
// CUSUM of Squares Test
// =============================================================================
capture program drop _fbnardl_cumsq
program define _fbnardl_cumsq
    version 17
    args residvar k n

    // Compute CUSUM of Squares
    tempvar w2 w2_cum
    qui gen double `w2' = `residvar'^2

    qui sum `w2'
    local sum_w2 = r(sum)

    qui gen double `w2_cum' = sum(`w2') / `sum_w2'

    // Critical value approximation
    local m = abs(0.5 * (`n' - `k') - 1)
    local c_val = 0.74191 - 0.17459 * ln(`m') - 0.26526 * (1/`m') + ///
                  0.0029985 * `m' - 0.000010943 * `m'^2

    // Check stability
    tempvar expected cumsq_dev
    local nres = `n' - `k'
    qui gen double `expected' = (_n - `k') / (`n' - `k') if _n <= `nres' + `k'
    qui gen double `cumsq_dev' = abs(`w2_cum' - `expected') if `expected' != .
    qui sum `cumsq_dev'
    local max_dev = r(max)

    if `max_dev' <= `c_val' {
        di as txt "  " _col(5) "CUSUM-SQ test" _col(30) "Max|Dev| = " %8.4f `max_dev'
        di as res "  " _col(5) "  => Stable at 5% (within bounds)"
    }
    else {
        di as txt "  " _col(5) "CUSUM-SQ test" _col(30) "Max|Dev| = " %8.4f `max_dev'
        di as err "  " _col(5) "  => UNSTABLE at 5% (exceeds bounds)"
    }

    // Generate CUSUM-SQ plot
    capture {
        tempvar cumsq_var cumsq_upper cumsq_lower cumsq_x
        qui gen `cumsq_x' = _n if _n <= `nres'
        qui gen double `cumsq_var' = `w2_cum' if _n <= `nres'
        qui gen double `cumsq_upper' = `c_val' + (`cumsq_x' - `k') / (`n' - `k') if `cumsq_x' != .
        qui gen double `cumsq_lower' = -`c_val' + (`cumsq_x' - `k') / (`n' - `k') if `cumsq_x' != .

        twoway (line `cumsq_var' `cumsq_x', lcolor(blue) lwidth(medium)) ///
               (line `cumsq_upper' `cumsq_x', lcolor(red) lpattern(dash) lwidth(medium)) ///
               (line `cumsq_lower' `cumsq_x', lcolor(red) lpattern(dash) lwidth(medium)), ///
               title("CUSUM of Squares Test", size(medium)) ///
               subtitle("FBNARDL Model", size(small)) ///
               ytitle("CUSUM-SQ", size(small)) xtitle("Observation", size(small)) ///
               legend(order(1 "CUSUM-SQ" 2 "5% Critical Bounds") size(small)) ///
               note("fbnardl package", size(vsmall)) ///
               scheme(s2color) name(cumsq_fbnardl, replace)

        qui graph export "cumsq_fbnardl.png", replace width(1200)
        di as txt "  " _col(5) "  Graph saved: cumsq_fbnardl.png"
    }
end
