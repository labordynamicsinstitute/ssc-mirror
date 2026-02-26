*! _mvardlurt_graph — Publication-quality visualizations for mvardlurt
*! Version 1.1.0 — 2026-02-24

capture program drop _mvardlurt_graph
program define _mvardlurt_graph
    version 14

    syntax varname(ts), ///
        INDEPvar(varname ts)    /// independent variable
        TSTAT(string)           /// observed t-statistic (string to handle negatives)
        FSTAT(string)           /// observed F-statistic
        TCV10(string)           /// t critical values
        TCV05(string)           ///
        TCV01(string)           ///
        FCV10(string)           /// F critical values
        FCV05(string)           ///
        FCV01(string)           ///
        Plag(integer)           /// optimal p
        Qlag(integer)           /// optimal q
        CASEname(string)        /// case label

    local depvar "`varlist'"
    local opt_p = `plag'
    local opt_q = `qlag'

    // Color palette (premium aesthetic)
    local c_blue    "31 119 180"
    local c_red     "214 39 40"
    local c_green   "44 160 44"
    local c_purple  "148 103 189"
    local c_orange  "255 127 14"
    local c_gray    "127 127 127"
    local c_ltgray  "220 220 220"

    // =========================================================================
    // 1. RESIDUAL DIAGNOSTICS
    // =========================================================================
    tempvar resid yhat

    capture {
        qui predict double `resid', residuals
        qui predict double `yhat', xb

        // ─── Fitted vs Residuals ───
        twoway (scatter `resid' `yhat', mcolor("`c_blue'%60") msize(small) msymbol(circle)) ///
               (lowess `resid' `yhat', lcolor("`c_red'") lwidth(medthick)), ///
               title("Residuals vs Fitted Values", size(medium) color(black)) ///
               subtitle("ARDL(`opt_p', `opt_q') — `casename'", size(small) color(gs6)) ///
               ytitle("Residuals", size(small)) ///
               xtitle("Fitted Values", size(small)) ///
               yline(0, lcolor("`c_gray'") lpattern(dash) lwidth(thin)) ///
               legend(order(1 "Residuals" 2 "LOWESS fit") size(vsmall) rows(1)) ///
               graphregion(color(white)) plotregion(color(white)) ///
               scheme(s2color) name(mvardlurt_resid, replace)
    }
    if _rc != 0 {
        di as txt _col(5) "(Residual plot skipped)"
    }

    // ─── Residual Histogram + Kernel Density ───
    capture {
        twoway (histogram `resid', fcolor("`c_blue'%40") lcolor("`c_blue'%80") ///
                lwidth(thin) bin(20) frequency) ///
               (kdensity `resid', lcolor("`c_red'") lwidth(medthick)), ///
               title("Distribution of Residuals", size(medium) color(black)) ///
               subtitle("ARDL(`opt_p', `opt_q') — Jarque-Bera normality assessment", ///
                   size(small) color(gs6)) ///
               xtitle("Residuals", size(small)) ///
               ytitle("Frequency", size(small)) ///
               legend(order(1 "Histogram" 2 "Kernel density") size(vsmall) rows(1)) ///
               graphregion(color(white)) plotregion(color(white)) ///
               scheme(s2color) name(mvardlurt_hist, replace)
    }
    if _rc != 0 {
        di as txt _col(5) "(Histogram skipped)"
    }

    // =========================================================================
    // 2. TIME SERIES PLOTS
    // =========================================================================
    capture {
        qui tsset

        // Levels
        twoway (tsline `depvar', lcolor("`c_blue'") lwidth(medthick)) ///
               (tsline `indepvar', lcolor("`c_red'") lwidth(medthick) lpattern(dash)), ///
               title("Time Series — Levels", size(medium) color(black)) ///
               subtitle("`depvar' and `indepvar'", size(small) color(gs6)) ///
               ytitle("Value", size(small)) ///
               xtitle("Time", size(small)) ///
               legend(order(1 "`depvar'" 2 "`indepvar'") size(vsmall) rows(1)) ///
               graphregion(color(white)) plotregion(color(white)) ///
               scheme(s2color) name(mvardlurt_levels, replace)

        // First differences
        twoway (tsline D.`depvar', lcolor("`c_blue'") lwidth(medium)) ///
               (tsline D.`indepvar', lcolor("`c_red'") lwidth(medium) lpattern(dash)), ///
               title("Time Series — First Differences", size(medium) color(black)) ///
               subtitle("{&Delta}`depvar' and {&Delta}`indepvar'", size(small) color(gs6)) ///
               ytitle("{&Delta}Value", size(small)) ///
               xtitle("Time", size(small)) ///
               yline(0, lcolor("`c_gray'") lpattern(dash) lwidth(thin)) ///
               legend(order(1 "{&Delta}`depvar'" 2 "{&Delta}`indepvar'") size(vsmall) rows(1)) ///
               graphregion(color(white)) plotregion(color(white)) ///
               scheme(s2color) name(mvardlurt_diffs, replace)
    }
    if _rc != 0 {
        di as txt _col(5) "(Time series plots skipped)"
    }

    // =========================================================================
    // 3. COMBINED PANEL
    // =========================================================================
    capture {
        graph combine mvardlurt_resid mvardlurt_hist mvardlurt_levels mvardlurt_diffs, ///
            cols(2) ///
            title("Multivariate ARDL Unit Root Test — Diagnostics Panel", ///
                size(medsmall) color(black)) ///
            subtitle("Sam, McNown, Goh & Goh (2024) — ARDL(`opt_p', `opt_q') `casename'", ///
                size(small) color(gs6)) ///
            graphregion(color(white)) ///
            scheme(s2color) name(mvardlurt_panel, replace)
    }
    if _rc != 0 {
        di as txt _col(5) "(Combined panel skipped)"
    }

    // =========================================================================
    // 4. CUSUM STABILITY TEST
    // =========================================================================
    capture {
        tempvar cusum_var upper_bound lower_bound obs_idx resid2

        qui predict double `resid2', residuals
        qui su `resid2'
        local sd_resid = r(sd)
        local n_cusum = r(N)

        qui gen double `cusum_var' = sum(`resid2' / `sd_resid')
        qui gen `obs_idx' = _n

        // 5% significance bands
        local band = 0.948 * sqrt(`n_cusum')
        qui gen double `upper_bound' = `band' * `obs_idx' / `n_cusum'
        qui gen double `lower_bound' = -`band' * `obs_idx' / `n_cusum'

        twoway (tsline `cusum_var', lcolor("`c_blue'") lwidth(medthick)) ///
               (line `upper_bound' `obs_idx', lcolor("`c_red'") lwidth(medium) lpattern(dash)) ///
               (line `lower_bound' `obs_idx', lcolor("`c_red'") lwidth(medium) lpattern(dash)), ///
               title("CUSUM Stability Test", size(medium) color(black)) ///
               subtitle("ARDL(`opt_p', `opt_q') — 5% significance bands", ///
                   size(small) color(gs6)) ///
               ytitle("Cumulative Sum", size(small)) ///
               xtitle("Observation", size(small)) ///
               legend(order(1 "CUSUM" 2 "5% bounds") size(vsmall) rows(1)) ///
               graphregion(color(white)) plotregion(color(white)) ///
               scheme(s2color) name(mvardlurt_cusum, replace)
    }
    if _rc != 0 {
        di as txt _col(5) "(CUSUM plot skipped)"
    }

    di as txt ""
    di as txt _col(3) "Graphs: mvardlurt_panel, mvardlurt_cusum"
    di as txt ""

end
