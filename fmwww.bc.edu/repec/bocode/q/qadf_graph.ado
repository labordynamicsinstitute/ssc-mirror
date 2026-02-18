*! qadf_graph - Quantile ADF Unit Root Test: Visualization
*! Version 1.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*!
*! Creates publication-quality plots after running qadf_process
*! Replicates the visualization from Python qadf package

program define qadf_graph
    version 14.0

    syntax [, ///
        SAVing(string)                        /// Save graph to file
        SCHEME(string)                        /// Stata graph scheme
        TItle(string)                         /// Custom title
        COMBine                               /// Show combined 4-panel plot
        RHOonly                               /// Only rho plot
        TSTATonly                             /// Only t-stat plot
        DELTA2only                            /// Only delta2 plot
        HALFLIFEonly                          /// Only half-life plot
        ]

    *--------------------------------------------------------------------------
    * Check that qadf_results matrix exists
    *--------------------------------------------------------------------------
    capture confirm matrix qadf_results
    if _rc {
        di as error "No qadf_process results found. Run {bf:qadf_process} first."
        exit 198
    }

    local nq = rowsof(qadf_results)
    if `nq' < 2 {
        di as error "Need at least 2 quantiles for visualization."
        exit 198
    }

    if "`scheme'" == "" local scheme "s2color"

    *--------------------------------------------------------------------------
    * Extract data into temporary variables
    *--------------------------------------------------------------------------
    preserve

    qui {
        clear
        set obs `nq'

        gen double tau     = .
        gen double rho     = .
        gen double tstat   = .
        gen double Ustat   = .
        gen double delta2  = .
        gen double cv5     = .
        gen double halflife = .

        forvalues i = 1/`nq' {
            replace tau      = qadf_results[`i', 1] in `i'
            replace rho      = qadf_results[`i', 2] in `i'
            replace tstat    = qadf_results[`i', 3] in `i'
            replace Ustat    = qadf_results[`i', 4] in `i'
            replace delta2   = qadf_results[`i', 5] in `i'
            replace cv5      = qadf_results[`i', 7] in `i'
            replace halflife = qadf_results[`i', 9] in `i'
        }

        * Unit root reference line
        gen double unity = 1

        * Negative CV for shading
        gen double neg_cv5 = -abs(cv5)
    }

    *--------------------------------------------------------------------------
    * Determine which plots to create
    *--------------------------------------------------------------------------
    local do_rho = 1
    local do_tstat = 1
    local do_delta2 = 1
    local do_halflife = 1
    local do_combine = 1

    if "`rhoonly'" != "" {
        local do_tstat = 0
        local do_delta2 = 0
        local do_halflife = 0
        local do_combine = 0
    }
    if "`tstatonly'" != "" {
        local do_rho = 0
        local do_delta2 = 0
        local do_halflife = 0
        local do_combine = 0
    }
    if "`delta2only'" != "" {
        local do_rho = 0
        local do_tstat = 0
        local do_halflife = 0
        local do_combine = 0
    }
    if "`halflifeonly'" != "" {
        local do_rho = 0
        local do_tstat = 0
        local do_delta2 = 0
        local do_combine = 0
    }

    if "`combine'" != "" local do_combine = 1

    *--------------------------------------------------------------------------
    * Plot 1: Autoregressive coefficient rho_1(tau) across quantiles
    *--------------------------------------------------------------------------
    if `do_rho' {
        twoway ///
            (rarea unity unity tau, ///
                color(gs14) lwidth(none)) ///
            (connected rho tau, ///
                lcolor(navy) mcolor(navy) msymbol(circle) ///
                lwidth(medthick) msize(small)) ///
            (line unity tau, ///
                lcolor(cranberry) lpattern(dash) lwidth(medium)) ///
            , ///
            title("{bf:Autoregressive Coefficient}", size(medium)) ///
            subtitle("rho_1(tau) across quantiles", size(small)) ///
            ytitle("rho_1(tau)", size(small)) ///
            xtitle("Quantile (tau)", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            ylabel(, labsize(small) angle(0)) ///
            yline(1, lcolor(cranberry) lpattern(dash) lwidth(thin)) ///
            legend(order(2 "rho(tau)" 3 "rho=1") ///
                ring(1) pos(6) size(vsmall) rows(1) symxsize(5) keygap(1)) ///
            scheme(`scheme') ///
            name(qadf_rho, replace) ///
            nodraw
    }

    *--------------------------------------------------------------------------
    * Plot 2: t-statistic with critical values
    *--------------------------------------------------------------------------
    if `do_tstat' {
        twoway ///
            (rarea neg_cv5 cv5 tau if cv5 < 0, ///
                color(cranberry%15) lwidth(none)) ///
            (connected tstat tau, ///
                lcolor(navy) mcolor(navy) msymbol(circle) ///
                lwidth(medthick) msize(small)) ///
            (line cv5 tau, ///
                lcolor(cranberry) lpattern(dash) lwidth(medium)) ///
            , ///
            title("{bf:t-statistic}", size(medium)) ///
            subtitle("t_n(tau) with 5% critical values", size(small)) ///
            ytitle("t_n(tau)", size(small)) ///
            xtitle("Quantile (tau)", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            ylabel(, labsize(small) angle(0)) ///
            yline(0, lcolor(gs10) lpattern(solid) lwidth(thin)) ///
            legend(order(2 "t_n(tau)" 3 "5% CV") ///
                ring(1) pos(6) size(vsmall) rows(1) symxsize(5) keygap(1)) ///
            scheme(`scheme') ///
            name(qadf_tstat, replace) ///
            nodraw
    }

    *--------------------------------------------------------------------------
    * Plot 3: Delta-squared across quantiles
    *--------------------------------------------------------------------------
    if `do_delta2' {
        twoway ///
            (bar delta2 tau, ///
                barwidth(0.06) fcolor(navy%60) lcolor(navy)) ///
            , ///
            title("{bf:Nuisance Parameter}", size(medium)) ///
            subtitle("delta-squared across quantiles", size(small)) ///
            ytitle("delta-sq", size(small)) ///
            xtitle("Quantile (tau)", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            ylabel(0(0.2)1, labsize(small) angle(0)) ///
            scheme(`scheme') ///
            name(qadf_delta2, replace) ///
            nodraw
    }

    *--------------------------------------------------------------------------
    * Plot 4: Half-life across quantiles
    *--------------------------------------------------------------------------
    if `do_halflife' {
        twoway ///
            (connected halflife tau if halflife < ., ///
                lcolor(dkorange) mcolor(dkorange) msymbol(diamond) ///
                lwidth(medthick) msize(small)) ///
            , ///
            title("{bf:Shock Persistence}", size(medium)) ///
            subtitle("Half-life across quantiles", size(small)) ///
            ytitle("Half-life (periods)", size(small)) ///
            xtitle("Quantile (tau)", size(small)) ///
            xlabel(0.1(0.1)0.9, labsize(small)) ///
            ylabel(, labsize(small) angle(0)) ///
            scheme(`scheme') ///
            name(qadf_halflife, replace) ///
            nodraw

    }

    *--------------------------------------------------------------------------
    * Combined 4-panel plot
    *--------------------------------------------------------------------------
    if `do_combine' & `do_rho' & `do_tstat' & `do_delta2' & `do_halflife' {
        if "`title'" == "" {
            local title "Quantile ADF Unit Root Test — Koenker & Xiao (2004)"
        }

        graph combine qadf_rho qadf_tstat qadf_delta2 qadf_halflife, ///
            rows(2) cols(2) ///
            title("{bf:`title'}", size(medium)) ///
            scheme(`scheme') ///
            name(qadf_combined, replace) ///
            xsize(10) ysize(8)

        if "`saving'" != "" {
            graph export "`saving'", replace
            di as txt "Graph saved to: `saving'"
        }
    }
    else {
        * Draw individual plots
        if `do_rho'      graph display qadf_rho
        if `do_tstat'    graph display qadf_tstat
        if `do_delta2'   graph display qadf_delta2
        if `do_halflife' graph display qadf_halflife

        if "`saving'" != "" {
            if `do_rho'      graph export "`saving'_rho.png", name(qadf_rho) replace
            if `do_tstat'    graph export "`saving'_tstat.png", name(qadf_tstat) replace
            if `do_delta2'   graph export "`saving'_delta2.png", name(qadf_delta2) replace
            if `do_halflife' graph export "`saving'_halflife.png", name(qadf_halflife) replace
        }
    }

    restore
end
