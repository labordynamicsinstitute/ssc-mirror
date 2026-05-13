*! _xtccecoint_plot.ado — Visualization for xtccecoint
*! Version 1.0.0 — 2026-05-11
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Produces 4 publication-quality plots:
*!   1. Individual CADF statistics dot chart (all units)
*!   2. Cross-section averages (CCE factor proxies) over time
*!   3. Summary comparison bar: CADF_P vs. critical values
*!   4. Combined 2×2 dashboard

capture program drop _xtccecoint_plot
program define _xtccecoint_plot
    version 14
    syntax, depopt(string) indepopt(string)             ///
        modelopt(string) nunits(string) tperiods(string)  ///
        plagopt(string) cv5(string) cv10(string)        ///
        [saving(string)]

    local model_n2 = real("`modelopt'")
    local N_n      = real("`nunits'")
    local T_n      = real("`tperiods'")
    local p_n      = real("`plagopt'")
    local cv5_n    = real("`cv5'")
    local cv10_n   = real("`cv10'")

    // Aliases used in body
    local depvar    "`depopt'"
    local indepvars "`indepopt'"

    // Retrieve individual statistics
    tempname t_ind ids_m
    matrix `t_ind' = _xcce_t_ind
    local nind = colsof(`t_ind')

    // ════════════════════════════════════════════════════════════════════════
    //  PLOT 1: Individual CADF Statistics (Cleveland dot chart)
    // ════════════════════════════════════════════════════════════════════════
    preserve
    quietly {
        clear
        set obs `nind'
        gen unit_id = .
        gen cadf_i  = .
        gen reject5 = .

        forvalues i = 1/`nind' {
            replace unit_id = `i'          in `i'
            replace cadf_i  = `t_ind'[1, `i'] in `i'
            replace reject5 = (`t_ind'[1, `i'] < `cv5_n') in `i'
        }

        // Sort by statistic for visual clarity
        gsort cadf_i

        // Color: red if reject at 5%, blue otherwise
        gen color_ind = cond(reject5 == 1, 2, 1)  // 2=red, 1=navy

        // CV reference lines
        local cv5_str  = string(round(`cv5_n', 0.001))
        local cv10_str = string(round(`cv10_n', 0.001))
    }

    local save_opt1 ""
    if "`saving'" != "" local save_opt1 `"saving("`saving'_ind", replace)"'

    twoway ///
        (scatter unit_id cadf_i if reject5 == 0, ///
            mcolor("68 114 196") msymbol(O) msize(medsmall)) ///
        (scatter unit_id cadf_i if reject5 == 1, ///
            mcolor("192 0 0") msymbol(D) msize(medsmall)) ///
        (scatteri 0 `cv5_n' `nind' `cv5_n', ///
            recast(line) lcolor("203 65 84") lwidth(medthick) lpattern(dash)) ///
        (scatteri 0 `cv10_n' `nind' `cv10_n', ///
            recast(line) lcolor("112 173 71") lwidth(thin) lpattern(shortdash)), ///
        title("{bf:Individual CADF Statistics}", size(medium) color(black)) ///
        subtitle("t_{α̂_i}: unit-specific cointegration tests | p = `p_n'", ///
                 size(small) color(gs5)) ///
        xtitle("CADF statistic (t_{α̂_i})", size(small)) ///
        ytitle("Panel unit", size(small)) ///
        legend(order(1 "No rejection (5%)" 2 "Reject H0 at 5%" ///
                     3 "5% CV = `cv5_str'" 4 "10% CV = `cv10_str'") ///
               rows(2) size(vsmall) position(6)) ///
        ylabel(, angle(0) labsize(tiny)) ///
        xlabel(, labsize(small)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(medium)) ///
        scheme(s2color) ///
        note("Red diamonds = rejected at 5%; Blue circles = not rejected" ///
             "N = `N_n' units | Model `model_n2'", size(vsmall)) ///
        name(xcce_ind, replace) `save_opt1'

    restore

    // ════════════════════════════════════════════════════════════════════════
    //  PLOT 2: Cross-section averages (CCE factor proxies)
    // ════════════════════════════════════════════════════════════════════════
    qui xtset
    local timevar2 "`r(timevar)'"
    local panelvar2 "`r(panelvar)'"

    local save_opt2 ""
    if "`saving'" != "" local save_opt2 `"saving("`saving'_csa", replace)"'

    // Calculate cross-section averages and plot
    preserve
    quietly {
        // Collapse to time-level means (CS averages)
        local first_dep = "`depvar'"
        local first_ind : word 1 of `indepvars'

        collapse (mean) `depvar' `first_ind', by(`timevar2')
    }

    twoway ///
        (line `depvar' `timevar2', lcolor("68 114 196") lwidth(medthick)) ///
        (line `first_ind' `timevar2', lcolor("237 125 49") lwidth(medthick) lpattern(dash)), ///
        title("{bf:Cross-Section Averages (CCE Factor Proxies)}", ///
              size(medium) color(black)) ///
        subtitle("ȳ_t and x̄_t as proxies for common factors", ///
                 size(small) color(gs5)) ///
        xtitle("Time (`timevar2')", size(small)) ///
        ytitle("Cross-section mean", size(small)) ///
        legend(order(1 "ȳ_t (`depvar')" 2 "x̄_t (`first_ind')") ///
               rows(1) size(small) position(6)) ///
        ylabel(, angle(0) labsize(small)) ///
        xlabel(, labsize(small)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(medium)) ///
        scheme(s2color) ///
        name(xcce_csa, replace) `save_opt2'

    restore

    // ════════════════════════════════════════════════════════════════════════
    //  PLOT 3: Distribution of individual statistics (histogram)
    // ════════════════════════════════════════════════════════════════════════
    preserve
    quietly {
        clear
        set obs `nind'
        gen cadf_i = .
        forvalues i = 1/`nind' {
            replace cadf_i = `t_ind'[1, `i'] in `i'
        }
    }

    local save_opt3 ""
    if "`saving'" != "" local save_opt3 `"saving("`saving'_hist", replace)"'

    local cadfp_v = _xcce_cadfp
    local cadfp_disp = string(round(`cadfp_v', 0.001))

    twoway ///
        (histogram cadf_i, freq fcolor("68 114 196%60") lcolor("47 82 143") lwidth(thin) bin(15)) ///
        (scatteri 0 `cv5_n' `nind' `cv5_n', recast(line) lcolor("192 0 0") lwidth(medthick) lpattern(dash)) ///
        (scatteri 0 `cv10_n' `nind' `cv10_n', recast(line) lcolor("112 173 71") lwidth(thin) lpattern(shortdash)) ///
        (scatteri 0 `cadfp_v' `nind' `cadfp_v', recast(line) lcolor("237 125 49") lwidth(medthick) lpattern(solid)), ///
        title("{bf:Distribution of Individual CADF Statistics}", ///
              size(medium) color(black)) ///
        subtitle("N = `N_n' individual test statistics | p = `p_n'", ///
                 size(small) color(gs5)) ///
        xtitle("t_{α̂_i}", size(small)) ///
        ytitle("Frequency", size(small)) ///
        legend(order(1 "Individual t_{α̂_i}" 2 "5% CV = `cv5'" ///
                     3 "10% CV = `cv10'" 4 "CADF_P = `cadfp_disp'") ///
               rows(2) size(vsmall) position(6)) ///
        ylabel(, angle(0) labsize(small)) ///
        xlabel(, labsize(small)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(medium)) ///
        scheme(s2color) ///
        name(xcce_hist, replace) `save_opt3'

    restore

    // ════════════════════════════════════════════════════════════════════════
    //  PLOT 4: Panel statistic vs. critical values (summary bar)
    // ════════════════════════════════════════════════════════════════════════
    preserve
    quietly {
        clear
        set obs 3
        gen label  = ""
        gen value  = .
        gen cat    = .

        replace label = "CADF_P" in 1
        replace value = _xcce_cadfp in 1
        replace cat = 1 in 1

        replace label = "CV (5%)" in 2
        replace value = `cv5_n' in 2
        replace cat = 2 in 2

        replace label = "CV (10%)" in 3
        replace value = `cv10_n' in 3
        replace cat = 3 in 3

        encode label, gen(lab_enc)
    }

    local cadfp_val = _xcce_cadfp
    local reject_col = cond(`cadfp_val' < `cv5_n', `"68 114 196"', `"192 0 0"')

    local save_opt4 ""
    if "`saving'" != "" local save_opt4 `"saving("`saving'_summary", replace)"'

    twoway ///
        (bar value cat if cat == 1, barw(0.6) fcolor("`reject_col'") lcolor(gs5) lwidth(thin)) ///
        (bar value cat if cat == 2, barw(0.6) fcolor("192 0 0%40") lcolor("192 0 0") lwidth(thin)) ///
        (bar value cat if cat == 3, barw(0.6) fcolor("112 173 71%40") lcolor("112 173 71") lwidth(thin)), ///
        title("{bf:Panel CADF_P vs. Critical Values}", ///
              size(medium) color(black)) ///
        subtitle("Model `model_n2' | N = `N_n' | T ≈ `=round(`T_n')' | p = `p_n'", ///
                 size(small) color(gs5)) ///
        xtitle("") ytitle("Statistic value", size(small)) ///
        xlabel(1 "CADF_P" 2 "CV (5%)" 3 "CV (10%)", labsize(small)) ///
        ylabel(, angle(0) labsize(small)) ///
        legend(off) ///
        note("Negative values: bar below zero indicates stronger rejection" ///
             "CADF_P < CV → Reject H0 (cointegration exists)", size(vsmall)) ///
        graphregion(color(white) margin(small)) ///
        plotregion(margin(medium)) ///
        scheme(s2color) ///
        name(xcce_sum, replace) `save_opt4'

    restore

    // ════════════════════════════════════════════════════════════════════════
    //  COMBINED DASHBOARD (2×2)
    // ════════════════════════════════════════════════════════════════════════
    local save_opt5 ""
    if "`saving'" != "" local save_opt5 "name(xcce_dashboard, replace)"

    graph combine xcce_ind xcce_csa xcce_hist xcce_sum, ///
        rows(2) cols(2) ///
        title("{bf:xtccecoint — Panel CCE Cointegration Test Dashboard}", ///
              size(medium) color(black)) ///
        subtitle("`depvar' ~ `indepvars' | Model `model_n2' | N = `N_n' | T ≈ `=round(`T_n')'", ///
                 size(small) color(gs5)) ///
        graphregion(color(white)) ///
        name(xcce_dashboard, replace)

    if "`saving'" != "" {
        graph export "`saving'_dashboard.png", ///
            name(xcce_dashboard) replace width(1800)
        di as text "  Dashboard saved: `saving'_dashboard.png"
    }

    di as text "  Plots created: xcce_ind, xcce_csa, xcce_hist, xcce_sum, xcce_dashboard"
end
