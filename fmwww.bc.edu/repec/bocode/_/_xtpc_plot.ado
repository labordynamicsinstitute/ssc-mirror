*! _xtpc_plot v1.1.0 — Publication-quality visualizations for xtpanelcoint
*! Author: Dr. Merwan Roudane

program define _xtpc_plot
    version 14.0
    syntax [, TYpe(string) SAVing(string) COMPare ///
              TItle(string) SUBtitle(string) ///
              SCHeme(string) WIDTH(integer 900) HEIGHT(integer 600)]

    if "`scheme'" == "" local scheme "s2color"

    if "`type'" == "" {
        // Auto-detect from last estimation
        local etype "`e(estimator_type)'"
        if "`etype'" == "mgdl" {
            local type "irf"
        }
        else if "`etype'" == "pme" {
            local type "eigenvalue"
        }
        else if "`compare'" != "" {
            local type "compare"
        }
        else {
            local type "coeff"
        }
    }

    local _opts `"saving(`saving') title(`title') subtitle(`subtitle') scheme(`scheme') width(`width') height(`height')"'

    if "`type'" == "coeff" {
        _xtpc_plot_coeff, `_opts'
    }
    else if "`type'" == "compare" {
        _xtpc_plot_compare, `_opts'
    }
    else if "`type'" == "irf" {
        _xtpc_plot_irf, `_opts'
    }
    else if "`type'" == "eigenvalue" | "`type'" == "eigen" {
        _xtpc_plot_eigen, `_opts'
    }
    else if "`type'" == "cumulative" | "`type'" == "cum" {
        _xtpc_plot_cumulative, `_opts'
    }
    else {
        di as error "Unknown plot type: `type'"
        di as error "Available: coeff, compare, irf, eigenvalue, cumulative"
        exit 198
    }
end

// ═══════════════════════════════════════════════════════════════════════════════
// Single estimator coefficient plot with CI
// ═══════════════════════════════════════════════════════════════════════════════
program define _xtpc_plot_coeff
    syntax , [SAVing(string) TItle(string) SUBtitle(string) ///
              SCHeme(string) WIDTH(integer 900) HEIGHT(integer 600)]

    if "`e(cmd)'" != "xtpanelcoint" {
        di as error "No xtpanelcoint estimation results found"
        exit 301
    }

    local est   "`e(estimator)'"
    local theta = e(theta)
    local se    = e(se)
    local ci_lo = e(ci95_lo)
    local ci_hi = e(ci95_hi)
    local pval  = e(p_value)

    if "`title'" == "" local title "`est'"
    if "`subtitle'" == "" local subtitle "Long-Run Coefficient Estimate"

    // Build data for the plot
    preserve
    clear
    qui set obs 1
    qui gen estimator = "`est'"
    qui gen theta = `theta'
    qui gen ci_lo = `ci_lo'
    qui gen ci_hi = `ci_hi'
    qui gen pval  = `pval'
    qui gen id = 1

    // Check for bootstrap CI
    local has_boot = 0
    if e(boot_ci_lo) < . {
        local has_boot = 1
        local blo = e(boot_ci_lo)
        local bhi = e(boot_ci_hi)
        qui gen boot_lo = `blo'
        qui gen boot_hi = `bhi'
    }

    // Significance marker
    local sig_color "68 114 196"
    if `pval' < 0.01      local sig_color "0 100 0"
    else if `pval' < 0.05 local sig_color "0 128 0"
    else if `pval' < 0.10 local sig_color "200 150 0"
    else                   local sig_color "180 0 0"

    if `has_boot' {
        twoway ///
            (rcap boot_lo boot_hi id, lcolor("180 199 231") lwidth(vthick) ///
                horizontal) ///
            (rcap ci_lo ci_hi id, lcolor("68 114 196") lwidth(thick) ///
                horizontal) ///
            (scatter id theta, mcolor("`sig_color'") msize(vlarge) ///
                msymbol(diamond) mlcolor(black) mlwidth(thin)) ///
            , ///
            yline(0, lcolor(gs10) lpattern(dash)) ///
            xline(1, lcolor("200 50 50") lpattern(shortdash) lwidth(medthin)) ///
            title("{bf:`title'}", size(large) color(black)) ///
            subtitle("`subtitle'", size(medium) color(gs5)) ///
            xtitle("Coefficient Value", size(medsmall)) ///
            ytitle("") ///
            ylabel(1 "`est'", labsize(small) angle(0) nogrid) ///
            legend(order(3 "Point Estimate" 2 "95% Asymptotic CI" ///
                         1 "95% Bootstrap CI") ///
                   ring(0) pos(4) cols(1) size(vsmall) ///
                   region(lcolor(gs12) fcolor(white%80))) ///
            graphregion(color(white) margin(medium)) ///
            plotregion(color(white) margin(small)) ///
            note("{it:H{subscript:0}: {&theta} = 1 (red dashed line)}" ///
                 "{it:p-value = `=string(`pval', "%6.4f")'}", ///
                 size(vsmall) color(gs6)) ///
            scheme(`scheme') ///
            xsize(`=`width'/100') ysize(`=`height'/100')
    }
    else {
        twoway ///
            (rcap ci_lo ci_hi id, lcolor("68 114 196") lwidth(thick) ///
                horizontal) ///
            (scatter id theta, mcolor("`sig_color'") msize(vlarge) ///
                msymbol(diamond) mlcolor(black) mlwidth(thin)) ///
            , ///
            xline(1, lcolor("200 50 50") lpattern(shortdash) lwidth(medthin)) ///
            title("{bf:`title'}", size(large) color(black)) ///
            subtitle("`subtitle'", size(medium) color(gs5)) ///
            xtitle("Coefficient Value", size(medsmall)) ///
            ytitle("") ///
            ylabel(1 "`est'", labsize(small) angle(0) nogrid) ///
            legend(order(2 "Point Estimate" 1 "95% CI") ///
                   ring(0) pos(4) cols(1) size(vsmall) ///
                   region(lcolor(gs12) fcolor(white%80))) ///
            graphregion(color(white) margin(medium)) ///
            plotregion(color(white) margin(small)) ///
            note("{it:H{subscript:0}: {&theta} = 1 (red dashed line)}" ///
                 "{it:p-value = `=string(`pval', "%6.4f")'}", ///
                 size(vsmall) color(gs6)) ///
            scheme(`scheme') ///
            xsize(`=`width'/100') ysize(`=`height'/100')
    }

    if "`saving'" != "" {
        graph export "`saving'", replace width(`width') height(`height')
        di as txt "Graph saved: {bf:`saving'}"
    }

    restore
end

// ═══════════════════════════════════════════════════════════════════════════════
// Multi-estimator comparison (requires stored estimates)
// ═══════════════════════════════════════════════════════════════════════════════
program define _xtpc_plot_compare
    syntax , [SAVing(string) TItle(string) SUBtitle(string) ///
              SCHeme(string) WIDTH(integer 900) HEIGHT(integer 600)]

    if "`title'" == ""    local title    "{bf:Panel Cointegration: Estimator Comparison}"
    if "`subtitle'" == "" local subtitle "Long-Run Coefficient Estimates with 95% CI"

    // Check which estimates are stored
    local est_list ""
    local k = 0
    foreach est in spmg breitung pdols mgmw {
        cap estimates restore `est'
        if !_rc {
            local k = `k' + 1
            local est_list "`est_list' `est'"
        }
    }

    if `k' == 0 {
        di as error "No stored estimates found."
        di as error "Use {bf:estimates store name} after each estimation, then call:"
        di as error "  {bf:_xtpc_plot, type(compare)}"
        exit 301
    }

    // Build comparison dataset
    preserve
    clear
    qui set obs `k'
    qui gen str30 estimator = ""
    qui gen theta = .
    qui gen ci_lo = .
    qui gen ci_hi = .
    qui gen pval  = .
    qui gen id    = .

    local i = 0
    foreach est of local est_list {
        local i = `i' + 1
        estimates restore `est'
        qui replace estimator = "`e(estimator)'" in `i'
        qui replace theta = e(theta) in `i'
        qui replace ci_lo = e(ci95_lo) in `i'
        qui replace ci_hi = e(ci95_hi) in `i'
        qui replace pval  = e(p_value) in `i'
        qui replace id    = `i' in `i'
    }

    // Color palette: blues/greens based on significance
    local colors ""
    forvalues j = 1/`k' {
        local pv = pval[`j']
        if `pv' < 0.01       local cl "0 100 70"
        else if `pv' < 0.05  local cl "0 128 100"
        else if `pv' < 0.10  local cl "200 150 0"
        else                  local cl "180 0 0"
    }

    // Build ylabel labels
    local ylabs ""
    forvalues j = 1/`k' {
        local lbl = estimator[`j']
        local ylabs `"`ylabs' `j' "`lbl'""'
    }

    twoway ///
        (rcap ci_lo ci_hi id, lcolor("68 114 196") lwidth(thick) ///
            vertical) ///
        (scatter theta id, mcolor("44 62 80") msize(vlarge) ///
            msymbol(diamond) mlcolor(white) mlwidth(thin)) ///
        , ///
        yline(1, lcolor("200 50 50") lpattern(shortdash) lwidth(medthin)) ///
        title("`title'", size(large) color(black)) ///
        subtitle("`subtitle'", size(medium) color(gs5)) ///
        ytitle("Coefficient Value", size(medsmall)) ///
        xtitle("") ///
        xlabel(`ylabs', labsize(small) angle(30)) ///
        legend(order(2 "Point Estimate" 1 "95% CI") ///
               ring(0) pos(2) cols(1) size(vsmall) ///
               region(lcolor(gs12) fcolor(white%80))) ///
        graphregion(color(white) margin(medium)) ///
        plotregion(color(white) margin(small)) ///
        note("{it:H{subscript:0}: {&theta} = 1 (red dashed line)}", ///
             size(vsmall) color(gs6)) ///
        scheme(`scheme') ///
        xsize(`=`width'/100') ysize(`=`height'/100')

    if "`saving'" != "" {
        graph export "`saving'", replace width(`width') height(`height')
        di as txt "Graph saved: {bf:`saving'}"
    }

    restore
end

// ═══════════════════════════════════════════════════════════════════════════════
// MGDL Impulse Response Function plot
// ═══════════════════════════════════════════════════════════════════════════════
program define _xtpc_plot_irf
    syntax , [SAVing(string) TItle(string) SUBtitle(string) ///
              SCHeme(string) WIDTH(integer 900) HEIGHT(integer 600)]

    if "`e(estimator_type)'" != "mgdl" {
        di as error "IRF plot requires MGDL estimation results"
        exit 301
    }

    if "`title'" == ""    local title    "{bf:MGDL Impulse Response Functions}"
    if "`subtitle'" == "" local subtitle "Cumulative Multipliers with Confidence Intervals"

    tempname cm cl ch sg irfs
    mat `cm' = e(cum_mult)
    mat `cl' = e(cum_ci_lo)
    mat `ch' = e(cum_ci_hi)
    mat `sg' = e(significant)

    local M = rowsof(`cm')

    // Build dataset for plotting
    preserve
    clear
    qui set obs `M'
    qui gen id = _n
    qui gen str30 product = "Product " + string(_n)
    qui gen delta   = .
    qui gen ci_lo   = .
    qui gen ci_hi   = .
    qui gen sig     = .

    forvalues i = 1/`M' {
        qui replace delta = `cm'[`i', 1] in `i'
        qui replace ci_lo = `cl'[`i', 1] in `i'
        qui replace ci_hi = `ch'[`i', 1] in `i'
        qui replace sig   = `sg'[`i', 1] in `i'
    }

    // Separate significant vs not
    qui gen delta_sig   = delta if sig == 1
    qui gen delta_nsig  = delta if sig == 0

    twoway ///
        (rbar ci_lo ci_hi id, barwidth(0.5) ///
            fcolor("68 114 196%30") lcolor("68 114 196") lwidth(thin)) ///
        (scatter delta_sig id, mcolor("0 100 70") msize(large) ///
            msymbol(circle) mlcolor(white) mlwidth(thin)) ///
        (scatter delta_nsig id, mcolor("180 180 180") msize(large) ///
            msymbol(circle) mlcolor(gs10) mlwidth(thin)) ///
        , ///
        yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
        title("`title'", size(large) color(black)) ///
        subtitle("`subtitle'", size(medium) color(gs5)) ///
        ytitle("Cumulative Multiplier ({&delta}{subscript:h})", size(medsmall)) ///
        xtitle("Product", size(medsmall)) ///
        xlabel(1(1)`M', labsize(small)) ///
        legend(order(2 "Significant" 3 "Not significant" ///
                     1 "95% CI") ///
               ring(0) pos(1) cols(1) size(vsmall) ///
               region(lcolor(gs12) fcolor(white%80))) ///
        graphregion(color(white) margin(medium)) ///
        plotregion(color(white) margin(small)) ///
        note("{it:MGDL Mean Group Distributed Lag Estimator}" ///
             "{it:Horizon h = `=e(horizon)'}", ///
             size(vsmall) color(gs6)) ///
        scheme(`scheme') ///
        xsize(`=`width'/100') ysize(`=`height'/100')

    if "`saving'" != "" {
        graph export "`saving'", replace width(`width') height(`height')
        di as txt "Graph saved: {bf:`saving'}"
    }

    restore
end

// ═══════════════════════════════════════════════════════════════════════════════
// PME Eigenvalue scree plot
// ═══════════════════════════════════════════════════════════════════════════════
program define _xtpc_plot_eigen
    syntax , [SAVing(string) TItle(string) SUBtitle(string) ///
              SCHeme(string) WIDTH(integer 900) HEIGHT(integer 600)]

    if "`e(estimator_type)'" != "pme" {
        di as error "Eigenvalue plot requires PME estimation results"
        exit 301
    }

    if "`title'" == ""    local title    "{bf:PME Eigenvalue Analysis}"
    if "`subtitle'" == "" local subtitle "Pooled Minimum Eigenvalue Scree Plot"

    tempname ev
    mat `ev' = e(eigenvalues)
    local m = rowsof(`ev')
    local r = e(r_hat)
    local thr = e(T)^(-e(delta))

    // Build data
    preserve
    clear
    qui set obs `m'
    qui gen id = _n
    qui gen eigenvalue = .
    qui gen threshold  = `thr'
    qui gen is_lr      = (_n <= `r')

    forvalues j = 1/`m' {
        qui replace eigenvalue = `ev'[`j', 1] in `j'
    }

    qui gen ev_lr   = eigenvalue if is_lr == 1
    qui gen ev_rest = eigenvalue if is_lr == 0

    twoway ///
        (area threshold id, color("200 50 50%15") lcolor("200 50 50") ///
            lpattern(shortdash) lwidth(thin)) ///
        (connected ev_lr id, lcolor("0 100 70") lwidth(medthick) ///
            mcolor("0 100 70") msize(large) msymbol(circle) ///
            mlcolor(white) mlwidth(thin)) ///
        (connected ev_rest id, lcolor("68 114 196") lwidth(medthick) ///
            mcolor("68 114 196") msize(large) msymbol(square) ///
            mlcolor(white) mlwidth(thin)) ///
        , ///
        title("`title'", size(large) color(black)) ///
        subtitle("`subtitle'", size(medium) color(gs5)) ///
        ytitle("Eigenvalue ({&lambda}{subscript:j})", size(medsmall)) ///
        xtitle("Component (j)", size(medsmall)) ///
        xlabel(1(1)`m', labsize(small)) ///
        legend(order(2 "Long-run relation (j {&le} r{subscript:0})" ///
                     3 "Non-stationary" ///
                     1 "Threshold T{superscript:-{&delta}}") ///
               ring(0) pos(11) cols(1) size(vsmall) ///
               region(lcolor(gs12) fcolor(white%80))) ///
        graphregion(color(white) margin(medium)) ///
        plotregion(color(white) margin(small)) ///
        note("{it:Estimated r{subscript:0} = `r'}" ///
             "{it:Threshold T{superscript:-{&delta}} = `=string(`thr', "%9.6f")'}", ///
             size(vsmall) color(gs6)) ///
        scheme(`scheme') ///
        xsize(`=`width'/100') ysize(`=`height'/100')

    if "`saving'" != "" {
        graph export "`saving'", replace width(`width') height(`height')
        di as txt "Graph saved: {bf:`saving'}"
    }

    restore
end

// ═══════════════════════════════════════════════════════════════════════════════
// MGDL Cumulative multiplier bar chart
// ═══════════════════════════════════════════════════════════════════════════════
program define _xtpc_plot_cumulative
    syntax , [SAVing(string) TItle(string) SUBtitle(string) ///
              SCHeme(string) WIDTH(integer 900) HEIGHT(integer 600)]

    if "`e(estimator_type)'" != "mgdl" {
        di as error "Cumulative plot requires MGDL estimation results"
        exit 301
    }

    if "`title'" == ""    local title    "{bf:MGDL Cumulative Multipliers}"
    if "`subtitle'" == "" local subtitle "Product-Level Pass-Through with Significance"

    tempname cm cl ch sg
    mat `cm' = e(cum_mult)
    mat `cl' = e(cum_ci_lo)
    mat `ch' = e(cum_ci_hi)
    mat `sg' = e(significant)
    local M = rowsof(`cm')

    preserve
    clear
    qui set obs `M'
    qui gen id     = _n
    qui gen delta  = .
    qui gen ci_lo  = .
    qui gen ci_hi  = .
    qui gen sig    = .

    forvalues i = 1/`M' {
        qui replace delta = `cm'[`i', 1] in `i'
        qui replace ci_lo = `cl'[`i', 1] in `i'
        qui replace ci_hi = `ch'[`i', 1] in `i'
        qui replace sig   = `sg'[`i', 1] in `i'
    }

    qui gen bar_sig  = delta if sig == 1
    qui gen bar_nsig = delta if sig == 0

    twoway ///
        (bar bar_sig id, barwidth(0.6) ///
            fcolor("0 100 70%70") lcolor("0 100 70") lwidth(thin)) ///
        (bar bar_nsig id, barwidth(0.6) ///
            fcolor("180 180 180%70") lcolor(gs10) lwidth(thin)) ///
        (rcap ci_lo ci_hi id, lcolor("44 62 80") lwidth(medthin)) ///
        , ///
        yline(0, lcolor(gs8) lpattern(solid) lwidth(thin)) ///
        title("`title'", size(large) color(black)) ///
        subtitle("`subtitle'", size(medium) color(gs5)) ///
        ytitle("Cumulative Multiplier", size(medsmall)) ///
        xtitle("Product Index", size(medsmall)) ///
        xlabel(1(1)`M', labsize(small)) ///
        legend(order(1 "Significant" 2 "Not significant" ///
                     3 "95% CI") ///
               ring(0) pos(1) cols(1) size(vsmall) ///
               region(lcolor(gs12) fcolor(white%80))) ///
        graphregion(color(white) margin(medium)) ///
        plotregion(color(white) margin(small)) ///
        scheme(`scheme') ///
        xsize(`=`width'/100') ysize(`=`height'/100')

    if "`saving'" != "" {
        graph export "`saving'", replace width(`width') height(`height')
        di as txt "Graph saved: {bf:`saving'}"
    }

    restore
end
