*! _rals_graph_ur 1.0.0  12may2026  Dr Merwan Roudane
*! Shared time-series plot for unit-root commands in the rals package.
program define _rals_graph_ur
    args y timevar touse testname stat cv5
    tempvar plot
    qui gen `plot' = `y' if `touse'
    local statf : di %6.3f `stat'
    local cv5f  : di %6.3f `cv5'
    local note  "`testname' = `statf'   |   5% CV = `cv5f'"

    * Stata graph names cannot contain hyphens; sanitize.
    local gname = subinstr("`testname'", "-", "_", .)
    local gname = subinstr("`gname'", " ", "_", .)

    twoway (line `plot' `timevar', lcolor("32 119 180") lwidth(medthick)),  ///
        title("`testname' applied to `y'", size(medium))                    ///
        subtitle("`note'", size(small))                                     ///
        ytitle("`y'") xtitle("`timevar'")                                   ///
        scheme(s2color) graphregion(color(white)) plotregion(color(white))  ///
        name(rals_`gname'_`y', replace)
end
