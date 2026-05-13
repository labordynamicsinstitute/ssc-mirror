*! wmcorr — Wavelet Multiple Correlation
*! Version 1.1.0  2026-05-11
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package
*! Reference: Fernandez-Macho (2012)

program define wmcorr, eclass sortpreserve
    version 11

    syntax varlist(min=2 ts) [if] [in], ///
        [Levels(integer 4)          ///
         Filter(string)             ///
         Level(real 0.95)           ///
         NODisplay                  ///
         PLOT                       ///
        ]

    * ── Defaults ──
    if ("`filter'" == "") local filter "la8"
    local filter = lower(trim("`filter'"))

    * ── Sample ──
    marksample touse
    qui count if `touse'
    local N = r(N)
    local d : word count `varlist'

    if (`d' < 2) {
        di as error "Need at least 2 variables."
        exit 102
    }

    * ── Extract data ──
    tempname Xmat
    mata: `Xmat' = st_data(., "`varlist'", "`touse'")

    * ── Variable names ──
    tempname vnames
    mata: `vnames' = tokens("`varlist'")'

    * ── Compute ──
    tempname result
    mata: `result' = _wv_wmcorr(`Xmat', "`filter'", `levels', `level')

    * ── Store results ──
    tempname val_mat ymaxr_mat neff_mat

    mata: st_matrix("`val_mat'", `result'.val)
    mata: st_matrix("`ymaxr_mat'", `result'.ymaxr)
    mata: st_matrix("`neff_mat'", `result'.N_eff)

    * Row labels
    local rownames ""
    forvalues j = 1/`levels' {
        local rownames "`rownames' D`j'"
    }
    matrix rownames `val_mat' = `rownames'
    matrix colnames `val_mat' = R CI_low CI_up
    matrix rownames `ymaxr_mat' = `rownames'
    matrix colnames `ymaxr_mat' = YmaxR

    ereturn clear
    ereturn local cmd      "wmcorr"
    ereturn local varlist  "`varlist'"
    ereturn local filter   "`filter'"
    ereturn scalar N       = `N'
    ereturn scalar J       = `levels'
    ereturn scalar d       = `d'
    ereturn scalar level   = `level'
    ereturn matrix wmcorr  = `val_mat'
    ereturn matrix ymaxr   = `ymaxr_mat'
    ereturn matrix N_eff   = `neff_mat'

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_wmcorr(`result', `vnames')
    }

    * ── Plot ──
    if ("`plot'" != "") {
        _wmcorr_plot, levels(`levels') level(`level')
    }

    * ── Cleanup ──
    mata: mata drop `Xmat' `vnames' `result'
end

* ═════════════════════════════════════════════════════════════
* Internal: Wavelet multiple correlation plot
* ═════════════════════════════════════════════════════════════
program define _wmcorr_plot
    syntax , levels(integer) level(real)

    tempname wm ym
    matrix `wm' = e(wmcorr)
    matrix `ym' = e(ymaxr)

    preserve
    clear
    qui set obs `levels'

    qui gen int _level = _n
    qui gen double _R     = .
    qui gen double _CI_lo = .
    qui gen double _CI_up = .

    forvalues j = 1/`levels' {
        qui replace _R     = `wm'[`j', 1] in `j'
        qui replace _CI_lo = `wm'[`j', 2] in `j'
        qui replace _CI_up = `wm'[`j', 3] in `j'
    }

    * MATLAB-style colors
    local col_main  "24 116 205"
    local col_ci    "173 216 230"
    local col_zero  "220 50 50"

    twoway (rarea _CI_up _CI_lo _level, ///
                color("`col_ci'%40") lwidth(none)) ///
           (connected _R _level, ///
                lcolor("`col_main'") mcolor("`col_main'") ///
                lwidth(medthick) msymbol(circle) msize(medium)) ///
           (function y=0, range(0.5 `= `levels' + 0.5') ///
                lcolor("`col_zero'") lpattern(dash) lwidth(thin)) ///
           , ///
           legend(order(2 "Multiple R" 1 "`= round(`level'*100)'% CI") ///
                  ring(0) pos(5) rows(1) size(small)) ///
           xtitle("Wavelet scale") ///
           ytitle("Multiple correlation R") ///
           ylabel(0(0.2)1) ///
           xlabel(1(1)`levels') ///
           graphregion(color(white)) ///
           plotregion(color(white)) ///
           scheme(s2mono) ///
           name(wmcorr, replace)

    restore
end
