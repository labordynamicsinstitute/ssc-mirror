*! garchur_graph.ado — Visual diagnostics for garchur
*! Version 1.1.0, February 2026
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

program define garchur_graph
    version 14.0

    syntax varname(ts) [if] [in],    ///
        [                            ///
        Model(string)                ///
        BREAKs(integer 2)            ///
        TB1(string)                  ///
        TB2(string)                  ///
        TB3(string)                  ///
        SAVEgraph(string)            ///
        ]

    marksample touse
    _ts timevar panelvar if `touse', sort onepanel
    markout `touse' `timevar'

    if "`model'" == "" local model "ct"

    *--------------------------------------------------------------------------
    * Check required variables exist
    *--------------------------------------------------------------------------
    capture confirm variable _garchur_ht
    if _rc {
        di as error "Run garchur first to generate _garchur_ht"
        exit 111
    }
    capture confirm variable _garchur_sr
    if _rc {
        di as error "Run garchur first to generate _garchur_sr"
        exit 111
    }

    *--------------------------------------------------------------------------
    * Colors
    *--------------------------------------------------------------------------
    local c_series  "navy"
    local c_trend   "cranberry"
    local c_ht      "dkorange"
    local c_sr      "teal"
    local c_ref     "gs8"

    *--------------------------------------------------------------------------
    * Build individual xline options (separate macros — avoids /// parsing issues
    * that arise with compound-quote concatenation loops)
    *--------------------------------------------------------------------------
    local xline1 ""
    local xline2 ""
    local xline3 ""

    if "`tb1'" != "" & "`tb1'" != "." {
        local xline1 "xline(`tb1', lcolor(red) lwidth(medium) lpattern(dash))"
    }
    if "`tb2'" != "" & "`tb2'" != "." {
        local xline2 "xline(`tb2', lcolor(blue) lwidth(medium) lpattern(dash))"
    }
    if "`tb3'" != "" & "`tb3'" != "." {
        local xline3 "xline(`tb3', lcolor(forest_green) lwidth(medium) lpattern(dash))"
    }

    *--------------------------------------------------------------------------
    * OLS trend for Panel A overlay
    *--------------------------------------------------------------------------
    tempvar trend_fit tindex
    qui gen double `tindex' = _n if `touse'
    qui reg `varlist' `tindex' if `touse'
    qui predict double `trend_fit' if `touse', xb

    *--------------------------------------------------------------------------
    * Break date note for Panel A subtitle
    *--------------------------------------------------------------------------
    local note1 ""
    if "`tb1'" != "" & "`tb1'" != "." local note1 "TB{sub:1}=`tb1'"
    if "`tb2'" != "" & "`tb2'" != "." {
        if "`note1'" != "" local note1 "`note1'  |  "
        local note1 "`note1'TB{sub:2}=`tb2'"
    }
    if "`tb3'" != "" & "`tb3'" != "." {
        if "`note1'" != "" local note1 "`note1'  |  "
        local note1 "`note1'TB{sub:3}=`tb3'"
    }
    if "`note1'" == "" local note1 "No breaks specified"

    *--------------------------------------------------------------------------
    * PANEL A: Time series + OLS trend + break lines
    * ring(1) places the legend OUTSIDE the plot region
    *--------------------------------------------------------------------------
    twoway                                                               ///
        (line `varlist'   `timevar' if `touse',                        ///
             lcolor(`c_series') lwidth(medthin))                        ///
        (line `trend_fit' `timevar' if `touse',                        ///
             lcolor(`c_trend') lwidth(medium) lpattern(solid)),         ///
        `xline1' `xline2' `xline3'                                      ///
        legend(order(1 "Observed" 2 "OLS trend")                        ///
               position(3) ring(1) cols(1) size(vsmall)                 ///
               region(fcolor(none) lcolor(none)))                       ///
        ytitle("Price", size(small))                                    ///
        xtitle("")                                                       ///
        title("{bf:Panel A: Time Series with Structural Breaks}",       ///
              size(medsmall) color(navy))                                ///
        subtitle("`note1'", size(small) color(gs6))                     ///
        scheme(s2color)                                                  ///
        graphregion(color(white) margin(small))                         ///
        plotregion(color(white))                                        ///
        xlabel(, labsize(vsmall) angle(45))                             ///
        ylabel(, labsize(vsmall))                                       ///
        name(garchur_p1, replace)

    *--------------------------------------------------------------------------
    * PANEL B: Conditional variance h_t (no legend needed)
    *--------------------------------------------------------------------------
    twoway                                                               ///
        (line _garchur_ht `timevar' if `touse',                        ///
             lcolor(`c_ht') lwidth(medthin)),                           ///
        `xline1' `xline2' `xline3'                                      ///
        legend(off)                                                      ///
        ytitle("h{sub:t}", size(small))                                 ///
        xtitle("")                                                       ///
        title("{bf:Panel B: Conditional Variance — GARCH(1,1)}",        ///
              size(medsmall) color(navy))                                ///
        scheme(s2color)                                                  ///
        graphregion(color(white) margin(small))                         ///
        plotregion(color(white))                                        ///
        xlabel(, labsize(vsmall) angle(45))                             ///
        ylabel(, labsize(vsmall))                                       ///
        name(garchur_p2, replace)

    *--------------------------------------------------------------------------
    * PANEL C: Standardised residuals ±2 reference
    * legend outside (ring(1), position(6)=bottom, 3 columns)
    *--------------------------------------------------------------------------
    twoway                                                               ///
        (bar _garchur_sr `timevar' if `touse' & (_garchur_sr > 0),     ///
             barwidth(0.3) color(navy) lcolor(none))                    ///
        (bar _garchur_sr `timevar' if `touse' & (_garchur_sr <= 0),    ///
             barwidth(0.3) color(cranberry) lcolor(none))               ///
        (line _garchur_sr `timevar' if `touse',                        ///
             lcolor(`c_sr') lwidth(thin)),                              ///
        `xline1' `xline2' `xline3'                                      ///
        yline( 2, lcolor(`c_ref') lpattern(dash) lwidth(thin))          ///
        yline(-2, lcolor(`c_ref') lpattern(dash) lwidth(thin))          ///
        yline( 0, lcolor(black)   lpattern(solid) lwidth(vthin))        ///
        legend(order(1 "Positive" 2 "Negative" 3 "Std. residual")       ///
               position(6) ring(1) cols(3) size(vsmall)                 ///
               region(fcolor(none) lcolor(none)))                       ///
        ytitle("e(t)/sqrt[h(t)]", size(small))                          ///
        xtitle("Time", size(small))                                      ///
        title("{bf:Panel C: Standardised Residuals}",                   ///
              size(medsmall) color(navy))                                ///
        subtitle("e(t)/sqrt[h(t)] with +/-2 sigma reference lines",     ///
              size(small) color(gs6))                                   ///
        scheme(s2color)                                                  ///
        graphregion(color(white) margin(small))                         ///
        plotregion(color(white))                                        ///
        xlabel(, labsize(vsmall) angle(45))                             ///
        ylabel(, labsize(vsmall))                                       ///
        name(garchur_p3, replace)

    *--------------------------------------------------------------------------
    * Combine into 3-panel figure
    *--------------------------------------------------------------------------
    local note_txt "Narayan, P.K. & Liu, R. (2015). A Unit Root Model for Trending Time-Series Energy Variables. {it:Energy Economics}."

    graph combine garchur_p1 garchur_p2 garchur_p3,                    ///
        rows(3) cols(1)                                                  ///
        title("{bf:Trend-GARCH Unit Root Test -- Diagnostic Graphs}",   ///
              size(medium) color(navy))                                  ///
        subtitle("`varlist'", size(small) color(gs6))                   ///
        note("`note_txt'", size(vsmall) color(gs8))                     ///
        graphregion(color(white) margin(medium))                         ///
        xsize(8) ysize(12)                                               ///
        name(garchur_combined, replace)

    * All 4 graphs remain visible: garchur_p1, garchur_p2, garchur_p3,
    * and garchur_combined. They can be browsed in the Graph window.

    *--------------------------------------------------------------------------
    * Save if requested
    *--------------------------------------------------------------------------
    if "`savegraph'" != "" {
        graph export "`savegraph'", replace
        di as txt "{col 3}Graph saved to: `savegraph'"
    }

end
