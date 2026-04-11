*! metalong_plot v1.5.0  metaLong for Stata 14.1
*! Combined publication-ready figures
*! Subir Hait, Michigan State University  |  haitsubi@msu.edu
*!
*! FIX v1.5.0: entire syntax statement on ONE line — no /// continuation.
*! Multi-line syntax declarations with /// cause r(198) in Stata 14.1
*! when the option list is complex. Single-line syntax avoids this.

program define metalong_plot
    version 14.1

    syntax , METAfile(string) [SENSfile(string) SPLINEfile(string) FRAGfile(string) SAVing(string) REPlace]

    local has_sens   = ("`sensfile'"   != "")
    local has_spline = ("`splinefile'" != "")
    local has_frag   = ("`fragfile'"   != "")
    local n_panels   = 1 + `has_sens' + `has_spline' + `has_frag'

    /* ================================================================== */
    /*  Panel 1 — Pooled effect trajectory                               */
    /* ================================================================== */
    preserve
    quietly use "`metafile'", clear

    twoway (rcap ci_ub ci_lb time if !missing(theta), lcolor(navy) lwidth(thin)) (connected theta time if !missing(theta), lcolor(navy) lwidth(medthick) msymbol(O) mcolor(navy)) (scatter theta time if !missing(theta) & sig==1, msymbol(D) mcolor(red) msize(medsmall)), yline(0, lpattern(dash) lcolor(gs10)) xtitle("Follow-up time") ytitle("Pooled effect") title("Pooled Effects", size(medsmall)) note("Bars=95%CI  |  Red=significant", size(vsmall)) legend(off) name(ml_p1, replace) nodraw

    restore

    /* ================================================================== */
    /*  Panel 2 — Sensitivity (ITCV) profile                            */
    /* ================================================================== */
    if `has_sens' {
        preserve
        quietly use "`sensfile'", clear

        twoway (connected itcv_alpha time if !missing(itcv_alpha), lcolor(navy) lwidth(medium) msymbol(O) mcolor(navy)), yline(0.15, lpattern(dash) lcolor(gs6)) xtitle("Follow-up time") ytitle("ITCV-adj") title("Sensitivity (ITCV)", size(medsmall)) note("Dashed line = threshold 0.15", size(vsmall)) legend(off) name(ml_p2, replace) nodraw

        restore
    }

    /* ================================================================== */
    /*  Panel 3 — Spline smooth                                          */
    /* ================================================================== */
    if `has_spline' {
        preserve
        quietly use "`splinefile'", clear
        tempfile spline_pred
        quietly save `spline_pred'
        restore

        preserve
        quietly use "`metafile'", clear
        quietly gen byte _src = 0
        quietly append using `spline_pred'
        quietly replace _src = 1 if missing(_src)

        twoway (line theta_hat time if _src==1, lcolor(maroon) lwidth(medthick)) (rcap ci_ub ci_lb time if _src==0 & !missing(theta), lcolor(gs10) lwidth(thin)) (scatter theta time if _src==0 & !missing(theta), msymbol(O) mcolor(gs6) msize(small)), yline(0, lpattern(dash) lcolor(gs10)) xtitle("Follow-up time") ytitle("Pooled effect") title("Spline Trend", size(medsmall)) note("Maroon=spline  |  Grey=observed", size(vsmall)) legend(off) name(ml_p3, replace) nodraw

        restore
    }

    /* ================================================================== */
    /*  Panel 4 — Fragility index                                        */
    /* ================================================================== */
    if `has_frag' {
        preserve
        quietly use "`fragfile'", clear

        twoway (bar fragility_index time if !missing(fragility_index), fcolor(navy) lcolor(navy)), yline(1, lpattern(dash) lcolor(gs10)) xtitle("Follow-up time") ytitle("Fragility index") title("Fragility Index", size(medsmall)) note("Dashed line at FI=1", size(vsmall)) legend(off) name(ml_p4, replace) nodraw

        restore
    }

    /* ================================================================== */
    /*  Combine all panels                                                */
    /* ================================================================== */
    local panels "ml_p1"
    if `has_sens'   local panels "`panels' ml_p2"
    if `has_spline' local panels "`panels' ml_p3"
    if `has_frag'   local panels "`panels' ml_p4"

    if `n_panels' == 1 {
        graph combine `panels', name(ml_combined, replace)
    }
    else if `n_panels' == 2 {
        graph combine `panels', cols(2) name(ml_combined, replace)
    }
    else if `n_panels' == 3 {
        graph combine `panels', cols(3) name(ml_combined, replace)
    }
    else {
        graph combine `panels', cols(2) name(ml_combined, replace)
    }

    foreach p of local panels {
        graph drop `p'
    }

    /* ================================================================== */
    /*  Save                                                              */
    /* ================================================================== */
    if "`saving'" != "" {
        if "`replace'" != "" {
            graph save ml_combined "`saving'", replace
        }
        else {
            graph save ml_combined "`saving'"
        }
        di as txt "  Figure saved to: " as res "`saving'"
    }

end
