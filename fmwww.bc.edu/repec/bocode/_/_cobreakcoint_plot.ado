*! _cobreakcoint_plot.ado — Visualization plots for cobreakcoint
*! Version 1.0.0 — 2026-04-18
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _cobreakcoint_plot
program define _cobreakcoint_plot
    version 14
    syntax, DEPvar(string) INDepvar(string) Model(string) ///
        Tobs(string) Px(string) Nk(string) Maxm(string) ///
        [SAVing(string) GRaph(string)]

    local model_n = real("`model'")
    local tobs_n  = real("`tobs'")
    local px_n    = real("`px'")
    local nk_n    = real("`nk'")
    local maxm_n  = real("`maxm'")

    if "`graph'" == "" local graph "all"

    tempname TestM ACV5 Bmat Bfm
    matrix `TestM' = _cbc_TestM
    matrix `ACV5'  = _cbc_ACV5
    matrix `Bmat'  = _cbc_Bmat
    matrix `Bfm'   = _cbc_Bfm

    // ═══════════════════════════════════════════════════════════════════════
    //  PLOT 1: TEST STATISTICS DASHBOARD (bar chart)
    // ═══════════════════════════════════════════════════════════════════════
    if inlist("`graph'", "all", "tests") {

        // Create temp dataset for plotting
        preserve
        clear
        quietly set obs `nk_n'

        quietly gen k_val = .
        quietly gen Qr1   = .
        quietly gen Qcb1  = .
        quietly gen Qct1  = .
        quietly gen Dmax_cb = .
        quietly gen Dmax_ct = .
        quietly gen cv_qr   = `ACV5'[1,4]
        quietly gen cv_qcb  = `ACV5'[1,5]
        quietly gen cv_qct  = `ACV5'[1,6]
        quietly gen cv_dmcb = `ACV5'[1,10]
        quietly gen cv_dmct = `ACV5'[1,11]

        forvalues i = 1/`nk_n' {
            quietly replace k_val   = `TestM'[`i',12] in `i'
            quietly replace Qr1     = `TestM'[`i',4]  in `i'
            quietly replace Qcb1    = `TestM'[`i',5]  in `i'
            quietly replace Qct1    = `TestM'[`i',6]  in `i'
            quietly replace Dmax_cb = `TestM'[`i',10] in `i'
            quietly replace Dmax_ct = `TestM'[`i',11] in `i'
        }

        // Panel A: Robust CI tests (Qr) across lags
        local save_opt1 ""
        if "`saving'" != "" local save_opt1 `"saving("`saving'_qr", replace)"'

        twoway (bar Qr1 k_val, barw(1.2) fcolor("68 114 196") ///
                lcolor("47 82 143") lwidth(thin)) ///
               (line cv_qr k_val, lcolor("192 0 0") lwidth(medthick) ///
                lpattern(dash)), ///
            title("{bf:Robust Cointegration Test (Qr)}", ///
                  size(medium) color(black)) ///
            subtitle("H0: Cointegration | Model `model_n'", ///
                     size(small) color(gs5)) ///
            ytitle("Qr(1) Statistic", size(small)) ///
            xtitle("DOLS Lags/Leads (k)", size(small)) ///
            legend(order(1 "Qr(1) statistic" 2 "5% critical value") ///
                   rows(1) size(vsmall) position(6)) ///
            ylabel(, angle(0) labsize(small)) ///
            xlabel(, labsize(small)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(medium)) ///
            scheme(s2color) ///
            name(cbc_qr, replace) `save_opt1'

        // Panel B: Joint CI/CB tests across lags
        local save_opt2 ""
        if "`saving'" != "" local save_opt2 `"saving("`saving'_joint_cb", replace)"'

        twoway (bar Qcb1 k_val, barw(1.2) fcolor("112 173 71") ///
                lcolor("76 127 43") lwidth(thin)) ///
               (line cv_qcb k_val, lcolor("192 0 0") lwidth(medthick) ///
                lpattern(dash)), ///
            title("{bf:Joint Test: CI & Cobreaking (Qcb)}", ///
                  size(medium) color(black)) ///
            subtitle("H0: CI + CB | Model `model_n'", ///
                     size(small) color(gs5)) ///
            ytitle("Qcb(1) Statistic", size(small)) ///
            xtitle("DOLS Lags/Leads (k)", size(small)) ///
            legend(order(1 "Qcb(1) statistic" 2 "5% critical value") ///
                   rows(1) size(vsmall) position(6)) ///
            ylabel(, angle(0) labsize(small)) ///
            xlabel(, labsize(small)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(medium)) ///
            scheme(s2color) ///
            name(cbc_qcb, replace) `save_opt2'

        // Panel C: Joint CI/CT tests (Model II only)
        if `model_n' == 2 {
            local save_opt3 ""
            if "`saving'" != "" local save_opt3 `"saving("`saving'_joint_ct", replace)"'

            twoway (bar Qct1 k_val, barw(1.2) fcolor("237 125 49") ///
                    lcolor("192 80 22") lwidth(thin)) ///
                   (line cv_qct k_val, lcolor("192 0 0") lwidth(medthick) ///
                    lpattern(dash)), ///
                title("{bf:Joint Test: CI & Cotrending (Qct)}", ///
                      size(medium) color(black)) ///
                subtitle("H0: CI + CT | Model `model_n'", ///
                         size(small) color(gs5)) ///
                ytitle("Qct(1) Statistic", size(small)) ///
                xtitle("DOLS Lags/Leads (k)", size(small)) ///
                legend(order(1 "Qct(1) statistic" 2 "5% critical value") ///
                       rows(1) size(vsmall) position(6)) ///
                ylabel(, angle(0) labsize(small)) ///
                xlabel(, labsize(small)) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(medium)) ///
                scheme(s2color) ///
                name(cbc_qct, replace) `save_opt3'
        }

        // Panel D: Dmax tests
        local save_opt4 ""
        if "`saving'" != "" local save_opt4 `"saving("`saving'_dmax", replace)"'

        if `model_n' == 2 {
            twoway (bar Dmax_cb k_val, barw(0.6) fcolor("68 114 196") ///
                    lcolor("47 82 143") lwidth(thin)) ///
                   (bar Dmax_ct k_val, barw(0.6) fcolor("237 125 49") ///
                    lcolor("192 80 22") lwidth(thin)) ///
                   (line cv_dmcb k_val, lcolor("0 128 0") lwidth(medthick) ///
                    lpattern(dash)) ///
                   (line cv_dmct k_val, lcolor("192 0 0") lwidth(medthick) ///
                    lpattern(shortdash)), ///
                title("{bf:Double-Max (Dmax) Tests}", ///
                      size(medium) color(black)) ///
                subtitle("Omnibus CI/CB and CI/CT | Model `model_n'", ///
                         size(small) color(gs5)) ///
                ytitle("Dmax Statistic", size(small)) ///
                xtitle("DOLS Lags/Leads (k)", size(small)) ///
                legend(order(1 "Dmax_cb" 2 "Dmax_ct" ///
                             3 "5% CV (CB)" 4 "5% CV (CT)") ///
                       rows(1) size(vsmall) position(6)) ///
                ylabel(, angle(0) labsize(small)) ///
                xlabel(, labsize(small)) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(medium)) ///
                scheme(s2color) ///
                name(cbc_dmax, replace) `save_opt4'
        }
        else {
            twoway (bar Dmax_cb k_val, barw(1.2) fcolor("68 114 196") ///
                    lcolor("47 82 143") lwidth(thin)) ///
                   (line cv_dmcb k_val, lcolor("192 0 0") lwidth(medthick) ///
                    lpattern(dash)), ///
                title("{bf:Double-Max (Dmax) Test: CI/CB}", ///
                      size(medium) color(black)) ///
                subtitle("Omnibus CI/CB | Model `model_n'", ///
                         size(small) color(gs5)) ///
                ytitle("Dmax Statistic", size(small)) ///
                xtitle("DOLS Lags/Leads (k)", size(small)) ///
                legend(order(1 "Dmax_cb" 2 "5% critical value") ///
                       rows(1) size(vsmall) position(6)) ///
                ylabel(, angle(0) labsize(small)) ///
                xlabel(, labsize(small)) ///
                graphregion(color(white) margin(small)) ///
                plotregion(margin(medium)) ///
                scheme(s2color) ///
                name(cbc_dmax, replace) `save_opt4'
        }

        restore
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  PLOT 2: TIME SERIES WITH BREAK DATES
    // ═══════════════════════════════════════════════════════════════════════
    if inlist("`graph'", "all", "series") {

        // Get time variable
        quietly tsset
        local timevar "`r(timevar)'"
        local timefmt "`r(tsfmt)'"
        quietly summarize `timevar', meanonly
        local t_min = r(min)

        // Use first row's break dates (k=1) — convert obs to time values
        local tb1_obs = `Bmat'[1, 1]
        local tb1_time = `t_min' + `tb1_obs' - 1

        local xline_opt "xline(`tb1_time', lcolor(cranberry) lwidth(medium) lpattern(dash))"
        if `maxm_n' >= 2 {
            local tb2a_obs = `Bmat'[1, 4]
            local tb2b_obs = `Bmat'[1, 5]
            if `tb2a_obs' < . {
                local tb2a_time = `t_min' + `tb2a_obs' - 1
                local tb2b_time = `t_min' + `tb2b_obs' - 1
                local xline_opt "`xline_opt' xline(`tb2a_time', lcolor(navy) lwidth(medium) lpattern(shortdash)) xline(`tb2b_time', lcolor(dkgreen) lwidth(medium) lpattern(shortdash))"
            }
        }

        local save_opt5 ""
        if "`saving'" != "" local save_opt5 `"saving("`saving'_series", replace)"'

        twoway (line `depvar' `timevar', lcolor("68 114 196") lwidth(medthick)) ///
               (line `indepvar' `timevar', lcolor("112 173 71") lwidth(medthick)) , ///
            `xline_opt' ///
            title("{bf:Time Series with Estimated Break Dates}", ///
                  size(medium) color(black)) ///
            subtitle("Model `model_n' | T = `tobs'", ///
                     size(small) color(gs5)) ///
            ytitle("Value", size(small)) ///
            xtitle("", size(small)) ///
            legend(order(1 "`depvar'" 2 "`indepvar'") ///
                   rows(1) size(vsmall) position(6)) ///
            ylabel(, angle(0) labsize(small)) ///
            xlabel(, labsize(small)) ///
            graphregion(color(white) margin(small)) ///
            plotregion(margin(medium)) ///
            scheme(s2color) ///
            note("Dashed lines = estimated break dates (m=1: red; m=2: blue/green)") ///
            name(cbc_series, replace) `save_opt5'
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  PLOT 3: COMBINED SUMMARY DASHBOARD
    // ═══════════════════════════════════════════════════════════════════════
    if inlist("`graph'", "all", "dashboard") {
        if `model_n' == 2 {
            graph combine cbc_qr cbc_qcb cbc_qct cbc_dmax, ///
                rows(2) cols(2) ///
                title("{bf:Cobreakcoint Test Results Dashboard}", ///
                      size(medium) color(black)) ///
                subtitle("Model `model_n' | T = `tobs' | `depvar' ~ `indepvar'", ///
                         size(small) color(gs5)) ///
                graphregion(color(white)) ///
                name(cbc_dashboard, replace)
        }
        else {
            graph combine cbc_qr cbc_qcb cbc_dmax, ///
                rows(1) cols(3) ///
                title("{bf:Cobreakcoint Test Results Dashboard}", ///
                      size(medium) color(black)) ///
                subtitle("Model `model_n' | T = `tobs' | `depvar' ~ `indepvar'", ///
                         size(small) color(gs5)) ///
                graphregion(color(white)) ///
                name(cbc_dashboard, replace)
        }

        if "`saving'" != "" {
            graph export "`saving'_dashboard.png", name(cbc_dashboard) replace width(1600)
        }
    }

    di as text "  {it:Plots created: cbc_qr, cbc_qcb" ///
        cond(`model_n'==2, ", cbc_qct", "")  ///
        ", cbc_dmax, cbc_series, cbc_dashboard}"
end
