*! _tptest_graph v1.0.0  28feb2026  Dr Merwan Roudane
*! Visualization module for tptest
*! Produces publication-quality turning point graphs

capture program drop _tptest_graph
program define _tptest_graph
    syntax varlist(min=2 max=3 numeric), MODEL(string) TP(real) ///
        XMIN(real) XMAX(real) B1(real) B2(real) ///
        [B3(real 0) SHAPE(string) SPEC(string) ///
         TSAC(real 0) PSAC(real 1) ///
         TPSE(real 0) TPCILO(real 0) TPCIHI(real 0) ///
         IP(real 0) ///
         SAVing(string) TItle(string asis) GRAPHOpt(string asis)]

    // Map to internal names for readability
    local t_sac = `tsac'
    local p_sac = `psac'
    local tp_se = `tpse'
    local tp_ci_lo = `tpcilo'
    local tp_ci_hi = `tpcihi'

    local nvar : word count `varlist'
    tokenize `varlist'
    local var1 "`1'"
    local var2 "`2'"
    if `nvar' == 3 local var3 "`3'"

    // =====================================================================
    // GRAPH 1: Fitted Relationship with Turning Point
    // =====================================================================

    preserve

    // Generate a fine grid of x values for the fitted curve
    local npoints = 200
    qui drop _all
    qui set obs `npoints'

    qui gen double _tp_x = `xmin' + (_n - 1) * (`xmax' - `xmin') / (`npoints' - 1)

    // Compute fitted values
    if "`model'" == "quad" {
        qui gen double _tp_fitted = `b1'*_tp_x + `b2'*_tp_x^2
        qui gen double _tp_slope  = `b1' + 2*`b2'*_tp_x
        local ycurve_label "β̂₁·x + β̂₂·x²"
    }
    else if "`model'" == "cubic" {
        qui gen double _tp_fitted = `b1'*_tp_x + `b2'*_tp_x^2 + `b3'*_tp_x^3
        qui gen double _tp_slope  = `b1' + 2*`b2'*_tp_x + 3*`b3'*_tp_x^2
        local ycurve_label "β̂₁·x + β̂₂·x² + β̂₃·x³"
    }
    else if "`model'" == "logquad" {
        qui gen double _tp_fitted = `b1'*ln(_tp_x) + `b2'*(ln(_tp_x))^2 if _tp_x > 0
        qui gen double _tp_slope  = (`b1' + 2*`b2'*ln(_tp_x)) / _tp_x if _tp_x > 0
        local ycurve_label "β̂₁·ln(x) + β̂₂·[ln(x)]²"
    }
    else if "`model'" == "inv" {
        qui gen double _tp_fitted = `b1'*_tp_x + `b2'/_tp_x if _tp_x != 0
        qui gen double _tp_slope  = `b1' - `b2'/_tp_x^2 if _tp_x != 0
        local ycurve_label "β̂₁·x + β̂₂/x"
    }

    // Compute y-value at turning point
    local tp_y = .
    if `tp' != . {
        if "`model'" == "quad" {
            local tp_y = `b1'*`tp' + `b2'*`tp'^2
        }
        else if "`model'" == "cubic" {
            local tp_y = `b1'*`tp' + `b2'*`tp'^2 + `b3'*`tp'^3
        }
        else if "`model'" == "logquad" {
            local tp_y = `b1'*ln(`tp') + `b2'*(ln(`tp'))^2
        }
        else if "`model'" == "inv" {
            local tp_y = `b1'*`tp' + `b2'/`tp'
        }
    }

    // Stars for annotation
    local stars ""
    if `p_sac' < 0.01       local stars "***"
    else if `p_sac' < 0.05  local stars "**"
    else if `p_sac' < 0.10  local stars "*"

    // Title
    if `"`title'"' == "" {
        local title "Turning Point Analysis (`spec')"
    }

    // Significance note
    local sig_note ""
    if `p_sac' < 0.10 {
        local sig_note "Test: `shape' (t = `: di %5.3f `t_sac'', p = `: di %5.4f `p_sac'') `stars'"
    }
    else {
        local sig_note "Test: Cannot reject monotonicity (p = `: di %5.4f `p_sac'')"
    }

    // ----- Main curve with turning point -----

    // Generate CI band if available
    local ci_area ""
    if `tp_se' > 0 & `tp_ci_lo' != 0 {
        qui gen double _tp_ci_lo_x = `tp_ci_lo' in 1
        qui gen double _tp_ci_hi_x = `tp_ci_hi' in 1

        // Create shaded region for CI
        qui gen double _tp_ci_band = .
        qui replace _tp_ci_band = _tp_fitted if _tp_x >= `tp_ci_lo' & _tp_x <= `tp_ci_hi'
    }

    // TP marker data
    qui gen double _tp_mark_x = `tp' in 1
    qui gen double _tp_mark_y = `tp_y' in 1

    // Build graph
    local graph_cmd ""

    // Main curve
    local graph_cmd `"line _tp_fitted _tp_x, lcolor("24 100 170") lwidth(medthick) lpattern(solid)"'

    // CI band
    if `tp_se' > 0 & `tp_ci_lo' != 0 {
        local graph_cmd `"`graph_cmd' || rarea _tp_ci_band _tp_fitted _tp_x if _tp_x >= `tp_ci_lo' & _tp_x <= `tp_ci_hi', color("24 100 170%15") lwidth(none)"'
    }

    // Turning point marker
    if `tp' != . {
        local graph_cmd `"`graph_cmd' || scatter _tp_mark_y _tp_mark_x, msymbol(diamond) msize(large) mcolor("220 50 47")"'
    }

    // Vertical line at turning point
    if `tp' != . {
        local graph_cmd `"`graph_cmd' xline(`tp', lcolor("220 50 47") lpattern(dash) lwidth(thin))"'
    }

    // Zero line for reference
    local graph_cmd `"`graph_cmd' yline(0, lcolor(gs10) lpattern(dot))"'

    // Annotation
    local tp_annot "x* = `: di %9.4f `tp''"
    if `tp_se' > 0 {
        local tp_annot "`tp_annot' (SE = `: di %7.4f `tp_se'')"
    }

    // Execute graph
    twoway `graph_cmd' , ///
        title("`title'", size(medium) color(black)) ///
        subtitle("`sig_note'", size(small) color(gs5)) ///
        xtitle("`var1'", size(medsmall)) ///
        ytitle("Fitted: `ycurve_label'", size(medsmall)) ///
        legend(off) ///
        note("`tp_annot'" ///
            "Interval: [`=string(`xmin', "%9.4g")', `=string(`xmax', "%9.4g")']" ///
            "*** p<0.01, ** p<0.05, * p<0.10", ///
            size(vsmall) color(gs5)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(small)) ///
        scheme(s2color) ///
        name(_tptest_curve, replace) ///
        `graphopt'

    if "`saving'" != "" {
        qui graph export "`saving'_curve.png", replace width(1600) height(1000)
        di in gr "  Graph saved: `saving'_curve.png"
    }

    // =====================================================================
    // GRAPH 2: Slope Function (Marginal Effect)
    // =====================================================================

    twoway line _tp_slope _tp_x, lcolor("38 166 91") lwidth(medthick) ///
        || , ///
        yline(0, lcolor("220 50 47") lpattern(dash) lwidth(thin)) ///
        `=cond(`tp'!=., "xline(`tp', lcolor(" + char(34) + "220 50 47" + char(34) + ") lpattern(dash) lwidth(thin))", "")' ///
        title("Marginal Effect (Slope Function)", size(medium) color(black)) ///
        subtitle("dy/dx — zero crossing indicates turning point", size(small) color(gs5)) ///
        xtitle("`var1'", size(medsmall)) ///
        ytitle("dy/dx", size(medsmall)) ///
        legend(off) ///
        note("Turning point at x* = `: di %9.4f `tp'' where slope = 0", ///
            size(vsmall) color(gs5)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(small)) ///
        scheme(s2color) ///
        name(_tptest_slope, replace) ///
        `graphopt'

    if "`saving'" != "" {
        qui graph export "`saving'_slope.png", replace width(1600) height(1000)
        di in gr "  Graph saved: `saving'_slope.png"
    }

    // =====================================================================
    // GRAPH 3: Combined Panel (if cubic model with inflection)
    // =====================================================================
    if "`model'" == "cubic" & `ip' != . {
        // Second derivative for inflection visualization
        qui gen double _tp_d2 = 2*`b2' + 6*`b3'*_tp_x

        // Inflection point marker
        local ip_y = 2*`b2' + 6*`b3'*`ip'

        twoway line _tp_d2 _tp_x, lcolor("180 100 200") lwidth(medthick) ///
            || , ///
            yline(0, lcolor("220 50 47") lpattern(dash)) ///
            xline(`ip', lcolor("255 165 0") lpattern(dash) lwidth(thin)) ///
            title("Second Derivative & Inflection Point", size(medium) color(black)) ///
            subtitle("d²y/dx² — zero crossing indicates inflection", size(small) color(gs5)) ///
            xtitle("`var1'", size(medsmall)) ///
            ytitle("d²y/dx²", size(medsmall)) ///
            legend(off) ///
            note("Inflection at x = `: di %9.4f `ip''", ///
                size(vsmall) color(gs5)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(small)) ///
            scheme(s2color) ///
            name(_tptest_inflection, replace) ///
            `graphopt'

        if "`saving'" != "" {
            qui graph export "`saving'_inflection.png", replace width(1600) height(1000)
            di in gr "  Graph saved: `saving'_inflection.png"
        }
    }

    // Combine main graphs
    graph combine _tptest_curve _tptest_slope, ///
        rows(1) ///
        title("tptest: Turning Point Analysis", size(medium) color(black)) ///
        graphregion(color(white)) ///
        name(_tptest_combined, replace)

    if "`saving'" != "" {
        qui graph export "`saving'_combined.png", replace width(2400) height(1000)
        di in gr "  Graph saved: `saving'_combined.png"
    }

    restore
end


// =========================================================================
// QUANTILE TRAJECTORY GRAPH
// =========================================================================
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
        xtitle("Quantile (τ)", size(medsmall)) ///
        ytitle("Turning Point (x*)", size(medsmall)) ///
        legend(order(2 "x*(τ)" 1 "95% CI" 3 "Significant (p<0.05)" 4 "Not significant") ///
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
