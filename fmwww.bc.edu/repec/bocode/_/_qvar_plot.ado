*! _qvar_plot.ado — Publication-Quality Visualizations for QVAR
*! Translates Python plotting.py color palette & chart types to Stata
*! Color palette: Teal #0A6C74, Coral #E8714A, Gold #F4B942,
*!   Slate #4A5568, Lavender #8B7EC8, Mint #2ECC9B, Rose #E85D75
*! Version 0.1.0

program define _qvar_plot
    version 16.0
    gettoken plottype 0 : 0, parse(" ,")

    local plottype = lower("`plottype'")

    if "`plottype'" == "coef" | "`plottype'" == "coefficients" {
        _qvar_plot_coef `0'
    }
    else if "`plottype'" == "cusum" {
        _qvar_plot_cusum `0'
    }
    else if "`plottype'" == "regime" | "`plottype'" == "regimes" {
        _qvar_plot_regime `0'
    }
    else if "`plottype'" == "fan" | "`plottype'" == "forecast" {
        _qvar_plot_fan `0'
    }
    else if "`plottype'" == "irf" {
        _qvar_plot_irf `0'
    }
    else if "`plottype'" == "gar" | "`plottype'" == "growthatrisk" {
        _qvar_plot_gar `0'
    }
    else if "`plottype'" == "irfcompare" {
        _qvar_plot_irf_compare `0'
    }
    else {
        di as error "Unknown plot type: `plottype'"
        di as error "Available: coef, cusum, regime, fan, irf, irfcompare, gar"
        exit 198
    }
end

// ═══════════════════════════════════════════════════════════════════════════
// 1. COEFFICIENT HEATMAP ACROSS QUANTILES
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_coef
    version 16.0
    syntax, EQuation(string) TAUs(numlist >0 <1) ///
        [SAVing(string) TItle(string)]

    if "`title'" == "" {
        local title "QVAR Coefficients Across Quantiles — `equation'"
    }

    local ntaus : word count `taus'

    // Collect coefficient values across quantiles
    local tau_idx = 0
    local tau_labels ""

    foreach tau of numlist `taus' {
        local ++tau_idx
        local tau_label = subinstr("`tau'", ".", "_", .)
        local tau_labels "`tau_labels' `tau'"

        // Find the equation index
        local eq_idx = 1
        local varnames = e(varnames)
        foreach v of local varnames {
            if "`v'" == "`equation'" continue, break
            local ++eq_idx
        }

        // Get coefficient matrix
        capture confirm matrix _qvar_b_`tau_label'_eq`eq_idx'
        if _rc != 0 {
            di as error "Coefficients not found for tau=`tau', eq=`equation'"
            di as error "Run {cmd:qvar estimate} first."
            exit 301
        }
    }

    // Build a dataset for the heatmap
    preserve
    clear

    // Get parameter names from first tau
    local first_tau : word 1 of `taus'
    local first_label = subinstr("`first_tau'", ".", "_", .)
    local pnames : colnames _qvar_b_`first_label'_eq`eq_idx'
    local nparms : word count `pnames'

    qui set obs `=`nparms' * `ntaus''
    qui gen str30 param = ""
    qui gen double tau = .
    qui gen double coef = .
    qui gen int param_id = .
    qui gen int tau_id = .

    local row = 0
    local tau_idx = 0
    foreach tau of numlist `taus' {
        local ++tau_idx
        local tau_label = subinstr("`tau'", ".", "_", .)

        local p_idx = 0
        foreach pname of local pnames {
            local ++p_idx
            local ++row
            qui replace param    = "`pname'" in `row'
            qui replace tau      = `tau'     in `row'
            qui replace param_id = `p_idx'   in `row'
            qui replace tau_id   = `tau_idx' in `row'
            qui replace coef = _qvar_b_`tau_label'_eq`eq_idx'[1, `p_idx'] in `row'
        }
    }

    // Create heatmap using marker-based scatter
    // Color intensity proportional to coefficient magnitude
    qui gen double abscoef = abs(coef)
    qui sum abscoef
    local maxabs = r(max)

    // Map coefficients to color intensity (red=negative, blue=positive)
    qui gen double color_val = coef / `maxabs' if `maxabs' > 0

    // Size proportional to |coef|
    qui gen double msize = 2 + 6 * abscoef / `maxabs' if `maxabs' > 0

    // Positive vs negative markers
    qui gen double coef_pos = coef if coef >= 0
    qui gen double coef_neg = coef if coef < 0

    // Create the heatmap plot
    local pos_opts "msymbol(O) mcolor("0 108 116") mlcolor("0 108 116")"
    local neg_opts "msymbol(O) mcolor("232 93 117") mlcolor("232 93 117")"

    twoway ///
        (scatter param_id tau_id if coef >= 0 [w=msize], ///
            `pos_opts' msize(*1.5) jitter(0)) ///
        (scatter param_id tau_id if coef < 0 [w=msize], ///
            `neg_opts' msize(*1.5) jitter(0)), ///
        title("`title'", color("27 40 56") size(medium)) ///
        subtitle("Bubble size = |coefficient|", ///
            color("74 85 104") size(small)) ///
        ytitle("") xtitle("Quantile ({&tau})", color("74 85 104")) ///
        ylabel(1(1)`nparms', valuelabel angle(0) labsize(vsmall) ///
            labcolor("74 85 104") nogrid) ///
        xlabel(1(1)`ntaus', valuelabel labsize(vsmall) ///
            labcolor("74 85 104")) ///
        legend(order(1 "Positive" 2 "Negative") ///
            ring(0) pos(2) cols(1) size(vsmall) ///
            region(lcolor("107 123 141") fcolor(white))) ///
        graphregion(color("250 251 252") margin(small)) ///
        plotregion(color("250 251 252") margin(medium)) ///
        note("Significance: bubble area {&prop} |{&beta}|", ///
            color("107 123 141") size(vsmall))

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
        di as text "  Plot saved: `saving'"
    }

    restore
end

// ═══════════════════════════════════════════════════════════════════════════
// 2. CUSUM PROCESS WITH BREAKPOINTS
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_cusum
    version 16.0
    syntax varname, [SAVing(string) TItle(string) ///
        BREAKpoint(integer 0)]

    if "`title'" == "" {
        local title "CUSUM Process — Quantile Granger Causality"
    }

    local cusum_var "`varlist'"
    qui count if !missing(`cusum_var')
    local n = r(N)

    tempvar obs_id
    qui gen long `obs_id' = _n if !missing(`cusum_var')

    // Build the plot
    local plot_cmd ""
    local plot_cmd "`plot_cmd' (rarea `cusum_var' `obs_id' `obs_id'"
    local plot_cmd "`plot_cmd' if !missing(`cusum_var'),"
    local plot_cmd "`plot_cmd' color("10 108 116%20") lwidth(none))"

    local plot_cmd "`plot_cmd' (line `cusum_var' `obs_id'"
    local plot_cmd "`plot_cmd' if !missing(`cusum_var'),"
    local plot_cmd "`plot_cmd' lcolor("10 108 116") lwidth(medthick))"

    if `breakpoint' > 0 {
        local plot_cmd "`plot_cmd' (scatteri 0 `breakpoint',"
        local plot_cmd "`plot_cmd' msymbol(D) mcolor("232 93 117")"
        local plot_cmd "`plot_cmd' msize(large))"
    }

    twoway `plot_cmd', ///
        title("`title'", color("27 40 56") size(medium)) ///
        xtitle("Observation", color("74 85 104")) ///
        ytitle("CUSUM statistic", color("74 85 104")) ///
        legend(off) ///
        graphregion(color("250 251 252")) ///
        plotregion(color("250 251 252")) ///
        xline(`breakpoint', lcolor("232 93 117") lpattern(dash) lwidth(medium)) ///
        yline(0, lcolor("74 85 104") lpattern(solid) lwidth(thin))

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
    }
end

// ═══════════════════════════════════════════════════════════════════════════
// 3. REGIME TIMELINE BAR
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_regime
    version 16.0
    syntax, DEPname(string) CAUSEname(string) ///
        [NRegimes(integer 1) BREAKfrac(real 0.5) ///
         GC1(integer 1) GC2(integer 0) ///
         SAVing(string) TItle(string)]

    if "`title'" == "" {
        local title "Granger Causality Regimes: `causename' {&rarr} `depname'"
    }

    preserve
    clear
    qui set obs 2

    qui gen double start = 0   in 1
    qui gen double end   = `breakfrac' in 1
    qui gen int    gc    = `gc1' in 1

    if `nregimes' >= 2 {
        qui replace start = `breakfrac' in 2
        qui replace end   = 1.0         in 2
        qui replace gc    = `gc2'       in 2
    }

    qui gen double width = end - start
    qui gen double mid   = (start + end) / 2
    qui gen byte   y     = 0

    // Regime colors: Teal=GC, Coral=No GC
    if `nregimes' >= 2 {
        twoway ///
            (rbar start end y if gc == 1, ///
                horizontal barwidth(0.4) ///
                color("10 108 116%85") lcolor(white) lwidth(medium)) ///
            (rbar start end y if gc == 0, ///
                horizontal barwidth(0.4) ///
                color("232 113 74%85") lcolor(white) lwidth(medium)), ///
            title("`title'", color("27 40 56") size(medium)) ///
            xtitle("Relative sample position ({&lambda})", ///
                color("74 85 104")) ///
            ytitle("") ylabel(, nolabel notick nogrid) ///
            xlabel(0(0.2)1, labcolor("74 85 104")) ///
            legend(order(1 "GC {&check}" 2 "No GC {&cross}") ///
                ring(0) pos(6) cols(2) size(small) ///
                region(lcolor("107 123 141") fcolor(white))) ///
            graphregion(color("250 251 252")) ///
            plotregion(color("250 251 252")) ///
            yscale(range(-0.5 0.5))
    }
    else {
        local bar_color = cond(`gc1'==1, "10 108 116%85", "232 113 74%85")
        local bar_label = cond(`gc1'==1, "GC throughout", "No GC")

        twoway ///
            (rbar start end y, ///
                horizontal barwidth(0.4) ///
                color("`bar_color'") lcolor(white) lwidth(medium)), ///
            title("`title'", color("27 40 56") size(medium)) ///
            xtitle("Relative sample position ({&lambda})", ///
                color("74 85 104")) ///
            ytitle("") ylabel(, nolabel notick nogrid) ///
            xlabel(0(0.2)1, labcolor("74 85 104")) ///
            legend(order(1 "`bar_label'") ring(0) pos(6) ///
                region(lcolor("107 123 141") fcolor(white))) ///
            graphregion(color("250 251 252")) ///
            plotregion(color("250 251 252")) ///
            yscale(range(-0.5 0.5))
    }

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
    }

    restore
end

// ═══════════════════════════════════════════════════════════════════════════
// 4. FORECAST FAN CHART
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_fan
    version 16.0
    syntax, Q05(varname) Q25(varname) Q50(varname) ///
        Q75(varname) Q95(varname) ///
        [MEAN(varname) VARname(string) ///
         SAVing(string) TItle(string)]

    if "`varname'" == "" local varname "Y"
    if "`title'" == ""   local title "Forecast Distribution — `varname'"

    // Fan chart: nested confidence bands
    twoway ///
        (rarea `q05' `q95' _n, ///
            color("10 108 116%12") lwidth(none)) ///
        (rarea `q25' `q75' _n, ///
            color("10 108 116%25") lwidth(none)) ///
        (line `q50' _n, ///
            lcolor("10 108 116") lwidth(medthick) ///
            lpattern(solid)) ///
        `=cond("`mean'"!="", ///
            "(line `mean' _n, lcolor(""232 113 74"") lwidth(medium) lpattern(dash))", ///
            "")' ///
        , ///
        title("`title'", color("27 40 56") size(medium)) ///
        subtitle("Quantile fan chart", color("74 85 104") size(small)) ///
        xtitle("Horizon", color("74 85 104")) ///
        ytitle("`varname'", color("74 85 104")) ///
        legend(order(1 "5%-95%" 2 "25%-75%" 3 "Median" ///
            `=cond("`mean'"!="","4 ""Mean""","")') ///
            ring(0) pos(2) cols(1) size(vsmall) ///
            region(lcolor("107 123 141") fcolor(white))) ///
        graphregion(color("250 251 252")) ///
        plotregion(color("250 251 252"))

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
    }
end

// ═══════════════════════════════════════════════════════════════════════════
// 5. QUANTILE IRF WITH CONFIDENCE BANDS
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_irf
    version 16.0
    syntax, IRF(varname) LOwer(varname) UPper(varname) ///
        [SHOCKvar(string) RESPvar(string) TAU(real 0.5) ///
         SAVing(string) TItle(string)]

    if "`shockvar'" == "" local shockvar "Shock"
    if "`respvar'" == ""  local respvar "Response"
    if "`title'" == "" {
        local title "Quantile IRF: `shockvar' {&rarr} `respvar'  ({&tau} = `tau')"
    }

    twoway ///
        (rarea `lower' `upper' _n, ///
            color("10 108 116%20") lwidth(none)) ///
        (connected `irf' _n, ///
            lcolor("10 108 116") lwidth(medthick) ///
            mcolor("10 108 116") msymbol(O) msize(small)) ///
        , ///
        yline(0, lcolor("74 85 104") lwidth(thin) lpattern(solid)) ///
        title("`title'", color("27 40 56") size(medium)) ///
        xtitle("Horizon", color("74 85 104")) ///
        ytitle("Response", color("74 85 104")) ///
        legend(order(1 "68% CI" 2 "IRF") ///
            ring(0) pos(2) cols(1) size(vsmall) ///
            region(lcolor("107 123 141") fcolor(white))) ///
        graphregion(color("250 251 252")) ///
        plotregion(color("250 251 252"))

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
    }
end

// ═══════════════════════════════════════════════════════════════════════════
// 6. MULTI-QUANTILE IRF COMPARISON
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_irf_compare
    version 16.0
    syntax varlist(min=2), TAUs(numlist >0 <1) ///
        [SHOCKvar(string) RESPvar(string) ///
         SAVing(string) TItle(string)]

    if "`shockvar'" == "" local shockvar "Shock"
    if "`respvar'" == ""  local respvar "Response"
    if "`title'" == "" {
        local title "Quantile IRFs: `shockvar' {&rarr} `respvar'"
    }

    // Colors for different quantiles (coolwarm palette)
    local c1 "232 93 117"   // rose - low quantile
    local c2 "232 113 74"   // coral
    local c3 "244 185 66"   // gold - center
    local c4 "46 204 155"   // mint
    local c5 "10 108 116"   // teal - high quantile
    local c6 "139 126 200"  // lavender
    local c7 "27 40 56"     // navy

    local nvars : word count `varlist'
    local ntaus : word count `taus'

    local plot_cmd ""
    local legend_order ""
    local idx = 0

    foreach v of varlist `varlist' {
        local ++idx
        local tau : word `idx' of `taus'

        // Cycle through colors
        local ci = mod(`idx' - 1, 7) + 1
        local this_color "`c`ci''"

        local plot_cmd "`plot_cmd' (connected `v' _n,"
        local plot_cmd "`plot_cmd' lcolor("`this_color'") lwidth(medium)"
        local plot_cmd "`plot_cmd' mcolor("`this_color'") msymbol(O) msize(vsmall))"

        local legend_order "`legend_order' `idx' `""{&tau} = `tau'""'"
    }

    twoway `plot_cmd', ///
        yline(0, lcolor("74 85 104") lwidth(thin)) ///
        title("`title'", color("27 40 56") size(medium)) ///
        xtitle("Horizon", color("74 85 104")) ///
        ytitle("Response", color("74 85 104")) ///
        legend(order(`legend_order') ///
            ring(0) pos(2) cols(1) size(vsmall) ///
            region(lcolor("107 123 141") fcolor(white))) ///
        graphregion(color("250 251 252")) ///
        plotregion(color("250 251 252"))

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
    }
end

// ═══════════════════════════════════════════════════════════════════════════
// 7. GROWTH-AT-RISK PLOT
// ═══════════════════════════════════════════════════════════════════════════
program define _qvar_plot_gar
    version 16.0
    syntax, MEAN(varname) QLOwer(varname) QUPper(varname) ///
        [VARname(string) SAVing(string) TItle(string)]

    if "`varname'" == "" local varname "GDP Growth"
    if "`title'" == ""   local title "Growth-at-Risk: `varname'"

    twoway ///
        (rarea `qlower' `qupper' _n, ///
            color("10 108 116%15") lwidth(none)) ///
        (line `mean' _n, ///
            lcolor("27 40 56") lwidth(medthick)) ///
        (line `qlower' _n, ///
            lcolor("232 93 117") lwidth(medium) lpattern(dash)) ///
        (line `qupper' _n, ///
            lcolor("46 204 155") lwidth(medium) lpattern(dash)) ///
        , ///
        yline(0, lcolor("74 85 104") lwidth(thin) lpattern(solid)) ///
        title("`title'", color("27 40 56") size(medium)) ///
        xtitle("Time", color("74 85 104")) ///
        ytitle("`varname'", color("74 85 104")) ///
        legend(order(1 "10%-90% range" 2 "Conditional Mean" ///
            3 "10% quantile (GaR)" 4 "90% quantile") ///
            ring(0) pos(2) cols(1) size(vsmall) ///
            region(lcolor("107 123 141") fcolor(white))) ///
        graphregion(color("250 251 252")) ///
        plotregion(color("250 251 252"))

    if "`saving'" != "" {
        graph export "`saving'", replace as(png) width(1400)
    }
end
