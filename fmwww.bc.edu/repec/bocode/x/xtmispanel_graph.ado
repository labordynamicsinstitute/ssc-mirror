*! version 1.0.1  03mar2026  Dr Merwan Roudane  merwanroudane920@gmail.com
*! xtmispanel_graph: Publication-quality visualizations for missing data
*! Generates 8 diagnostic graphs for panel data missingness analysis
*! Fix: graphs 2-5 now use robust single-layer twoway to avoid empty-group errors

capture program drop xtmispanel_graph
program define xtmispanel_graph
    version 15.0
    syntax [varlist(default=none)] [if] [in], ///
        PANELvar(varname) TIMEvar(varname) ///
        [IMPVar(varname)]

    marksample touse, novarlist

    * If no varlist, use all numeric variables
    if "`varlist'" == "" {
        ds, has(type numeric)
        local varlist `r(varlist)'
        local varlist : list varlist - panelvar
        local varlist : list varlist - timevar
    }

    di
    di in smcl in ye "{bf:╔══════════════════════════════════════════════════════════════════════════╗}"
    di in ye        "{bf:║}" in gr "  VISUALIZATION MODULE: Generating Diagnostic Graphs" ///
        _col(75) in ye "{bf:║}"
    di in ye        "{bf:╚══════════════════════════════════════════════════════════════════════════╝}"
    di

    local nvars : word count `varlist'

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 1: Missing Data Heatmap (Panel × Time)
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [1/8] Generating missing data heatmap..."

    local firstvar : word 1 of `varlist'

    tempvar _pid _miss_ind
    qui egen `_pid' = group(`panelvar') if `touse'
    qui gen byte `_miss_ind' = missing(`firstvar') if `touse'

    local _g1_ok = 0
    capture noisily {
        twoway (scatter `_pid' `timevar' if `_miss_ind' == 0 & `touse', ///
                msymbol(square) msize(large) mcolor("59 130 73%80") ///
                mlwidth(vthin) mlcolor(white)) ///
               (scatter `_pid' `timevar' if `_miss_ind' == 1 & `touse', ///
                msymbol(square) msize(large) mcolor("220 50 47%90") ///
                mlwidth(vthin) mlcolor(white)), ///
            title("{bf:Missing Data Heatmap}", size(medium) color(black)) ///
            subtitle("Green = Observed  |  Red = Missing", size(small) color(gs6)) ///
            ytitle("Panel Unit", size(small)) ///
            xtitle("Time Period", size(small)) ///
            ylabel(, labsize(vsmall) angle(0) nogrid) ///
            xlabel(, labsize(vsmall) angle(45)) ///
            legend(order(1 "Observed" 2 "Missing") ///
                rows(1) size(small) position(6) ring(1)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            name(xtmis_heatmap, replace) nodraw
        local _g1_ok = 1
    }
    if `_g1_ok' {
        di in gr "    ✓ {it:xtmis_heatmap} stored"
    }
    else {
        di in ye "    ⚠ Heatmap could not be generated"
    }

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 2: Missing % by Variable (Horizontal Bar Chart)
    * Uses a simple approach: create temp data, graph, restore
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [2/8] Generating per-variable missing bar chart..."

    * Compute % missing for each variable into a matrix
    tempname vpctmat
    matrix `vpctmat' = J(`nvars', 1, 0)
    local vi = 0
    local varnames ""
    foreach v of local varlist {
        local vi = `vi' + 1
        qui count if `touse'
        local ntot = r(N)
        qui count if missing(`v') & `touse'
        local nmiss = r(N)
        local pctv = 0
        if `ntot' > 0 local pctv = `nmiss' / `ntot' * 100
        matrix `vpctmat'[`vi', 1] = `pctv'
        local vab = abbrev("`v'", 12)
        local varnames "`varnames' `vab'"
    }

    preserve
    local _g2_ok = 0
    qui {
        clear
        set obs `nvars'
        gen double pct_miss = .
        gen long vid = _n

        forv i = 1/`nvars' {
            replace pct_miss = `vpctmat'[`i', 1] in `i'
        }
    }

    * Build ylabel labels
    local vlabels ""
    local vi = 0
    foreach vn of local varnames {
        local vi = `vi' + 1
        local vlabels `"`vlabels' `vi' "`vn'""'
    }

    capture noisily {
        twoway (bar pct_miss vid, horizontal barwidth(0.7) ///
                color("41 128 185%80") lcolor(white) lwidth(thin)), ///
            title("{bf:Missing Data by Variable}", size(medium) color(black)) ///
            subtitle("% of observations missing", size(small) color(gs6)) ///
            ytitle("") xtitle("% Missing", size(small)) ///
            ylabel(`vlabels', labsize(vsmall) angle(0) nogrid) ///
            xlabel(, labsize(vsmall)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            name(xtmis_barvar, replace) nodraw
        local _g2_ok = 1
    }
    restore

    if `_g2_ok' {
        di in gr "    ✓ {it:xtmis_barvar} stored"
    }
    else {
        di in ye "    ⚠ Variable bar chart could not be generated"
    }

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 3: Missing % by Panel (Bar Chart)
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [3/8] Generating per-panel missing bar chart..."

    qui levelsof `panelvar' if `touse', local(panels)
    local npanels : word count `panels'

    tempname ppctmat
    matrix `ppctmat' = J(`npanels', 1, 0)
    local pi = 0
    local panelnames ""
    foreach p of local panels {
        local pi = `pi' + 1
        local pmiss = 0
        local pobs  = 0
        foreach v of local varlist {
            qui count if `panelvar' == `p' & `touse'
            local pobs = `pobs' + r(N)
            qui count if `panelvar' == `p' & `touse' & missing(`v')
            local pmiss = `pmiss' + r(N)
        }
        local ppct = 0
        if `pobs' > 0 local ppct = `pmiss' / `pobs' * 100
        matrix `ppctmat'[`pi', 1] = `ppct'
        local pab = abbrev("`p'", 10)
        local panelnames "`panelnames' `pab'"
    }

    preserve
    local _g3_ok = 0
    qui {
        clear
        set obs `npanels'
        gen double pct_miss = .
        gen long pid = _n

        forv i = 1/`npanels' {
            replace pct_miss = `ppctmat'[`i', 1] in `i'
        }
    }

    * Build xlabel labels
    local plabels ""
    local pi = 0
    foreach pn of local panelnames {
        local pi = `pi' + 1
        local plabels `"`plabels' `pi' "`pn'""'
    }

    capture noisily {
        twoway (bar pct_miss pid, barwidth(0.7) ///
                color("155 89 182%80") lcolor(white) lwidth(thin)), ///
            title("{bf:Missing Data by Panel}", size(medium) color(black)) ///
            subtitle("% of observations missing", size(small) color(gs6)) ///
            ytitle("% Missing", size(small)) xtitle("Panel", size(small)) ///
            xlabel(`plabels', labsize(vsmall) angle(45) nogrid) ///
            ylabel(, labsize(vsmall) angle(0)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            name(xtmis_barpanel, replace) nodraw
        local _g3_ok = 1
    }
    restore

    if `_g3_ok' {
        di in gr "    ✓ {it:xtmis_barpanel} stored"
    }
    else {
        di in ye "    ⚠ Panel bar chart could not be generated"
    }

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 4: Missing % by Time Period (Area Chart)
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [4/8] Generating per-time-period missing chart..."

    qui levelsof `timevar' if `touse', local(times)
    local ntimes : word count `times'

    tempname tpctmat
    matrix `tpctmat' = J(`ntimes', 2, 0)
    local ti = 0
    foreach t of local times {
        local ti = `ti' + 1
        local tmiss = 0
        local tobs  = 0
        foreach v of local varlist {
            qui count if `timevar' == `t' & `touse'
            local tobs = `tobs' + r(N)
            qui count if `timevar' == `t' & `touse' & missing(`v')
            local tmiss = `tmiss' + r(N)
        }
        local tpct = 0
        if `tobs' > 0 local tpct = `tmiss' / `tobs' * 100
        matrix `tpctmat'[`ti', 1] = `t'
        matrix `tpctmat'[`ti', 2] = `tpct'
    }

    preserve
    local _g4_ok = 0
    qui {
        clear
        set obs `ntimes'
        gen double time_period = .
        gen double pct_miss = .

        forv i = 1/`ntimes' {
            replace time_period = `tpctmat'[`i', 1] in `i'
            replace pct_miss = `tpctmat'[`i', 2] in `i'
        }
    }

    capture noisily {
        twoway (area pct_miss time_period, color("220 50 47%30") ///
                lcolor("220 50 47") lwidth(medthick)) ///
               (line pct_miss time_period, lcolor("220 50 47") ///
                lwidth(medthick) lpattern(solid)), ///
            title("{bf:Missing Data Over Time}", size(medium) color(black)) ///
            subtitle("% missing across all panels and variables", ///
                size(small) color(gs6)) ///
            ytitle("% Missing", size(small)) ///
            xtitle("Time Period", size(small)) ///
            ylabel(, labsize(vsmall) angle(0) nogrid) ///
            xlabel(, labsize(vsmall) angle(0)) ///
            legend(off) ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            name(xtmis_bartime, replace) nodraw
        local _g4_ok = 1
    }
    restore

    if `_g4_ok' {
        di in gr "    ✓ {it:xtmis_bartime} stored"
    }
    else {
        di in ye "    ⚠ Time-period chart could not be generated"
    }

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 5: Missingness Pattern Plot
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [5/8] Generating missingness pattern plot..."

    local _g5_ok = 0
    if `nvars' <= 15 {
        * Create pattern string
        tempvar _patt
        qui gen str1 `_patt' = "" if `touse'
        foreach v of local varlist {
            qui replace `_patt' = `_patt' + cond(missing(`v'), "0", "1") if `touse'
        }

        * Count patterns into a matrix
        qui levelsof `_patt' if `touse', local(patterns)
        local npatt : word count `patterns'
        local maxpatt = min(`npatt', 20)

        tempname pattmat
        matrix `pattmat' = J(`maxpatt', 1, 0)
        local pi = 0
        foreach pat of local patterns {
            local pi = `pi' + 1
            if `pi' > `maxpatt' continue, break
            qui count if `_patt' == "`pat'" & `touse'
            matrix `pattmat'[`pi', 1] = r(N)
        }
        * Sort descending by count
        drop `_patt'

        preserve
        qui {
            clear
            set obs `maxpatt'
            gen double freq = .
            gen long pid = _n
            forv i = 1/`maxpatt' {
                replace freq = `pattmat'[`i', 1] in `i'
            }
            gsort -freq
            replace pid = _n
        }

        capture noisily {
            twoway (bar freq pid, barwidth(0.7) ///
                    color("255 127 14%80") lcolor(white) lwidth(thin)), ///
                title("{bf:Missingness Patterns}", size(medium) color(black)) ///
                subtitle("Frequency of each unique pattern", ///
                    size(small) color(gs6)) ///
                ytitle("Frequency", size(small)) ///
                xtitle("Pattern Rank", size(small)) ///
                ylabel(, labsize(vsmall) angle(0) nogrid) ///
                xlabel(1(1)`maxpatt', labsize(vsmall)) ///
                legend(off) ///
                graphregion(color(white) margin(small)) ///
                plotregion(color(white) margin(small)) ///
                name(xtmis_pattern, replace) nodraw
            local _g5_ok = 1
        }
        restore
    }

    if `_g5_ok' {
        di in gr "    ✓ {it:xtmis_pattern} stored"
    }
    else if `nvars' > 15 {
        di in ye "    ⚠ Pattern plot skipped (too many variables)"
    }
    else {
        di in ye "    ⚠ Pattern plot could not be generated"
    }

    * -----------------------------------------------------------------
    * GRAPH 6: Density Overlay (Original vs Imputed)
    * If no impvar specified, auto-impute using linear interpolation
    * -----------------------------------------------------------------
    di in gr "  [6/8] Generating density overlay..."

    local _g6_ok = 0
    local firstvar : word 1 of `varlist'
    local densevar "`impvar'"
    local auto_imp = 0

    * Auto-impute if no impvar specified
    if "`densevar'" == "" {
        qui count if missing(`firstvar') & `touse'
        if r(N) > 0 {
            tempvar _auto_imp _ipol _pmean2
            qui gen double `_auto_imp' = `firstvar' if `touse'
            * Quick linear interpolation
            qui bysort `panelvar': ipolate `firstvar' `timevar' if `touse', gen(`_ipol')
            qui replace `_auto_imp' = `_ipol' if missing(`_auto_imp') & `touse'
            * Fill remaining with panel mean
            qui bysort `panelvar': egen double `_pmean2' = mean(`firstvar') if `touse'
            qui replace `_auto_imp' = `_pmean2' if missing(`_auto_imp') & `touse'
            * Fill remaining with global mean
            qui su `firstvar' if `touse' & !missing(`firstvar'), meanonly
            qui replace `_auto_imp' = r(mean) if missing(`_auto_imp') & `touse'
            local densevar "`_auto_imp'"
            local auto_imp = 1
            di in gr "      (auto-imputed `firstvar' via linear interpolation)"
        }
    }

    if "`densevar'" != "" {
        capture noisily {
            twoway (kdensity `firstvar' if `touse' & !missing(`firstvar'), ///
                    lcolor("41 128 185") lwidth(medthick) lpattern(solid)) ///
                   (kdensity `densevar' if `touse' & !missing(`densevar'), ///
                    lcolor("220 50 47") lwidth(medthick) lpattern(dash)), ///
                title("{bf:Distribution: Original vs Imputed}", ///
                    size(medium) color(black)) ///
                subtitle("`firstvar': observed (blue) vs complete (red)", ///
                    size(small) color(gs6)) ///
                ytitle("Density", size(small)) ///
                xtitle("Value", size(small)) ///
                ylabel(, labsize(vsmall) angle(0) nogrid) ///
                xlabel(, labsize(vsmall)) ///
                legend(order(1 "Original (observed)" 2 "Imputed (complete)") ///
                    rows(1) size(vsmall) position(6) ring(1)) ///
                graphregion(color(white) margin(small)) ///
                plotregion(color(white) margin(small)) ///
                name(xtmis_density, replace) nodraw
            local _g6_ok = 1
        }
        if `_g6_ok' {
            di in gr "    {it:xtmis_density} stored"
        }
        else {
            di in ye "    Density plot could not be generated"
        }
    }
    else {
        di in gr "    Density plot skipped (no missing data in `firstvar')"
    }

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 7: Missing Data Timeline per Panel (Scatter)
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [7/8] Generating panel timeline scatter..."

    local _g7_ok = 0
    capture noisily {
        twoway (scatter `_pid' `timevar' if !missing(`firstvar') & `touse', ///
                msymbol(circle) msize(small) mcolor("59 130 73%60")) ///
               (scatter `_pid' `timevar' if missing(`firstvar') & `touse', ///
                msymbol(X) msize(medlarge) mcolor("220 50 47%90")), ///
            title("{bf:Missing Data Timeline by Panel}", ///
                size(medium) color(black)) ///
            subtitle("`firstvar': ● = Observed  |  ✗ = Missing", ///
                size(small) color(gs6)) ///
            ytitle("Panel Unit", size(small)) ///
            xtitle("Time Period", size(small)) ///
            ylabel(, labsize(vsmall) angle(0) nogrid) ///
            xlabel(, labsize(vsmall) angle(45)) ///
            legend(order(1 "Observed" 2 "Missing") ///
                rows(1) size(small) position(6) ring(1)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(color(white) margin(small)) ///
            name(xtmis_timeline, replace) nodraw
        local _g7_ok = 1
    }
    if `_g7_ok' {
        di in gr "    ✓ {it:xtmis_timeline} stored"
    }
    else {
        di in ye "    ⚠ Timeline scatter could not be generated"
    }

    * ─────────────────────────────────────────────────────────────────────
    * GRAPH 8: Combined Diagnostic Dashboard (4-panel)
    * ─────────────────────────────────────────────────────────────────────
    di in gr "  [8/8] Generating combined diagnostic dashboard..."

    * Build list of available graphs to combine
    local combo_graphs ""
    if `_g1_ok' local combo_graphs "`combo_graphs' xtmis_heatmap"
    if `_g2_ok' local combo_graphs "`combo_graphs' xtmis_barvar"
    if `_g4_ok' local combo_graphs "`combo_graphs' xtmis_bartime"
    if `_g5_ok' local combo_graphs "`combo_graphs' xtmis_pattern"
    if `_g3_ok' & "`combo_graphs'" == "" local combo_graphs "`combo_graphs' xtmis_barpanel"
    if `_g7_ok' & "`combo_graphs'" == "" local combo_graphs "`combo_graphs' xtmis_timeline"

    local ngraphs : word count `combo_graphs'
    local _g8_ok = 0

    if `ngraphs' >= 2 {
        local ncols = 2
        local nrows = ceil(`ngraphs' / 2)
        capture noisily {
            graph combine `combo_graphs', ///
                cols(`ncols') ///
                title("{bf:Missing Data Diagnostic Dashboard}", ///
                    size(medium) color(black)) ///
                subtitle("xtmispanel v1.0.0", size(small) color(gs6)) ///
                graphregion(color(white) margin(small)) ///
                name(xtmis_combined, replace) nodraw
            local _g8_ok = 1
        }
    }

    if `_g8_ok' {
        di in gr "    ✓ {it:xtmis_combined} stored"
    }
    else {
        di in ye "    ⚠ Combined dashboard could not be generated (need ≥ 2 graphs)"
    }

    * ─── Summary ──────────────────────────────────────────────────────────
    di
    di in gr "  {hline 60}"
    di in gr "  {bf:Graphs generated:}"
    if `_g1_ok' di in gr "    ✓ xtmis_heatmap   — Missing data heatmap"
    if `_g2_ok' di in gr "    ✓ xtmis_barvar    — % missing per variable"
    if `_g3_ok' di in gr "    ✓ xtmis_barpanel  — % missing per panel"
    if `_g4_ok' di in gr "    ✓ xtmis_bartime   — % missing over time"
    if `_g5_ok' di in gr "    ✓ xtmis_pattern   — Missingness patterns"
    if `_g6_ok' di in gr "    ✓ xtmis_density   — Original vs imputed density"
    if `_g7_ok' di in gr "    ✓ xtmis_timeline  — Panel timeline scatter"
    if `_g8_ok' di in gr "    ✓ xtmis_combined  — Diagnostic dashboard"
    di
    di in gr "  {bf:To view:}  {cmd:graph display xtmis_heatmap}"
    di in gr "  {bf:To export:} {cmd:graph export xtmis_heatmap.png, name(xtmis_heatmap) replace width(1200)}"
    di in gr "  {hline 60}"
    di
end
