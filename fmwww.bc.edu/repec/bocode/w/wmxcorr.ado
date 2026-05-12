*! wmxcorr — Wavelet Multiple Cross-Correlation
*! Version 1.0.0  2026-05-10
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*! Part of the lwavelet package
*! Reference: Fernandez-Macho (2012)

program define wmxcorr, eclass sortpreserve
    version 11

    syntax varlist(min=2 ts) [if] [in], ///
        [Levels(integer 4)          ///
         Filter(string)             ///
         MAXlag(integer 10)         ///
         Level(real 0.95)           ///
         NODisplay                  ///
         PLOT                       ///
        ]

    * ── Defaults ──
    if ("`filter'" == "") local filter "la8"
    local filter = lower(trim("`filter'"))

    marksample touse
    qui count if `touse'
    local N = r(N)
    local d : word count `varlist'

    * ── Extract data ──
    tempname Xmat vnames
    mata: `Xmat' = st_data(., "`varlist'", "`touse'")
    mata: `vnames' = tokens("`varlist'")'

    * ── Compute ──
    tempname result
    mata: `result' = _wv_wmxcorr(`Xmat', "`filter'", `levels', `maxlag', `level')

    * ── Store results ──
    local nlags = 2 * `maxlag' + 1

    forvalues j = 1/`levels' {
        tempname r_`j' clo_`j' cup_`j'
        mata: st_matrix("`r_`j''",   `result'.val[`j', .])
        mata: st_matrix("`clo_`j''", `result'.ci_lo[`j', .])
        mata: st_matrix("`cup_`j''", `result'.ci_up[`j', .])
    }

    tempname ymaxr_mat
    mata: st_matrix("`ymaxr_mat'", `result'.ymaxr)

    ereturn clear
    ereturn local cmd      "wmxcorr"
    ereturn local varlist  "`varlist'"
    ereturn local filter   "`filter'"
    ereturn scalar N       = `N'
    ereturn scalar J       = `levels'
    ereturn scalar maxlag  = `maxlag'
    ereturn scalar d       = `d'
    ereturn matrix ymaxr   = `ymaxr_mat'

    forvalues j = 1/`levels' {
        ereturn matrix xcorr`j'  = `r_`j''
        ereturn matrix ci_lo`j'  = `clo_`j''
        ereturn matrix ci_up`j'  = `cup_`j''
    }

    * ── Display ──
    if ("`nodisplay'" == "") {
        mata: _wv_display_wmxcorr(`result', `vnames')
    }

    * ── Plot ──
    if ("`plot'" != "") {
        _wmxcorr_plot, levels(`levels') maxlag(`maxlag')
    }

    * ── Cleanup ──
    mata: mata drop `Xmat' `vnames' `result'
end

* ═══════════════════════════════════════════════════════════════════════════
* Internal: Cross-correlation lag plot
* ═══════════════════════════════════════════════════════════════════════════
program define _wmxcorr_plot
    syntax, levels(integer) maxlag(integer)

    preserve
    clear

    local nlags = 2 * `maxlag' + 1
    qui set obs `nlags'
    qui gen int _lag = _n - `maxlag' - 1

    * MATLAB-style colors per level
    local colors `""24 116 205" "220 50 50" "34 139 34" "148 103 189" "255 127 14" "140 86 75""'

    local plotcmd ""
    local legcmd ""

    forvalues j = 1/`levels' {
        local jc : word `j' of `colors'
        if "`jc'" == "" local jc "100 100 100"

        qui gen double _R`j' = .
        tempname rj
        matrix `rj' = e(xcorr`j')

        forvalues l = 1/`nlags' {
            qui replace _R`j' = `rj'[1, `l'] in `l'
        }

        local plotcmd `"`plotcmd' (connected _R`j' _lag, lcolor("`jc'") mcolor("`jc'") lwidth(medthick) msymbol(circle) msize(small))"'
        local legcmd `"`legcmd' `j' "D`j'""'
    }

    twoway `plotcmd' ///
        (function y=0, range(-`maxlag' `maxlag') ///
            lcolor(gs8) lpattern(dash) lwidth(thin)) ///
        , ///
        legend(order(`legcmd') rows(1) size(small) region(lstyle(none))) ///
        xtitle("Lag") ///
        ytitle("Cross-correlation R") ///
        xlabel(-`maxlag'(5)`maxlag') ///
        ylabel(0(0.2)1) ///
        xline(0, lcolor(gs10) lpattern(dash)) ///
        graphregion(color(white)) ///
        plotregion(color(white)) ///
        scheme(s2mono) ///
        name(wmxcorr, replace)

    restore
end
