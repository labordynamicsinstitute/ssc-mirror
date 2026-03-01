*! _tptest_qgraph v1.0.0  28feb2026  Dr Merwan Roudane
*! Quantile trajectory graph for tptest

capture program drop _tptest_qgraph
program define _tptest_qgraph
    syntax anything, NTAU(integer) MODEL(string) CMD(string) ///
        [SAVing(string) TItle(string asis)]

    tempname tpmat
    mat `tpmat' = `anything'

    preserve
    qui drop _all
    qui set obs `ntau'

    qui gen double _tau     = .
    qui gen double _tp      = .
    qui gen double _tp_se   = .
    qui gen double _tp_lo   = .
    qui gen double _tp_hi   = .
    qui gen double _pval    = .

    forvalues i = 1/`ntau' {
        qui replace _tau    = `tpmat'[`i', 1] in `i'
        qui replace _tp     = `tpmat'[`i', 2] in `i'
        qui replace _tp_se  = `tpmat'[`i', 3] in `i'
        qui replace _pval   = `tpmat'[`i', 5] in `i'
    }

    // CI bands (95%)
    qui gen double _tp_lo2 = _tp - 1.96 * _tp_se
    qui gen double _tp_hi2 = _tp + 1.96 * _tp_se

    // Significance markers
    qui gen byte _sig = (_pval < 0.05)

    if `"`title'"' == "" {
        local title "Turning Point Trajectory Across Quantiles"
    }

    // Main graph: TP(tau) with CI band
    twoway rarea _tp_lo2 _tp_hi2 _tau, color("24 100 170%20") lwidth(none) ///
        || line _tp _tau, lcolor("24 100 170") lwidth(medthick) ///
        || scatter _tp _tau if _sig == 1, msymbol(circle) msize(medium) ///
            mcolor("220 50 47") ///
        || scatter _tp _tau if _sig == 0, msymbol(circle_hollow) msize(medium) ///
            mcolor(gs8) ///
        || , ///
        title("`title'", size(medium) color(black)) ///
        subtitle("Estimator: `cmd' | Model: `model'", size(small) color(gs5)) ///
        xtitle("Quantile ({&tau})", size(medsmall)) ///
        ytitle("Turning Point (x*)", size(medsmall)) ///
        legend(order(2 "x*({&tau})" 1 "95% CI" 3 "Significant (p<0.05)" 4 "Not significant") ///
            rows(1) size(vsmall) region(lcolor(gs12))) ///
        note("Filled markers = significant U/inverted-U shape (p < 0.05)" ///
            "95% CI via delta method", ///
            size(vsmall) color(gs5)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(small)) ///
        scheme(s2color) ///
        name(_tptest_qtraj, replace)

    if "`saving'" != "" {
        qui graph export "`saving'_quantile_trajectory.png", replace width(1600) height(1000)
        di in gr "  Graph saved: `saving'_quantile_trajectory.png"
    }

    restore
end
