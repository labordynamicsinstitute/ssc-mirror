*! tc_plot.ado -- threshold-cointegration visualisations
*! Author: Dr Merwan Roudane

program define tc_plot
    version 14
    gettoken what 0 : 0, parse(" ,")
    if "`what'" == "regime" {
        tc_plot_regime `0'
        exit 0
    }
    if "`what'" == "grid" {
        tc_plot_grid `0'
        exit 0
    }
    if "`what'" == "ect" {
        tc_plot_ect `0'
        exit 0
    }
    di as error "tc_plot: unknown sub-command '`what''. Use: regime, grid, ect"
    exit 198
end

// ---------------------------------------------------------------------
program define tc_plot_regime
    syntax varname(numeric) [if] [in] [, THReshold(real 0) MODEL(string) TITLE(string) SAVING(string) SCHEME(string)]
    if "`model'"  == "" local model "tar"
    if "`scheme'" == "" local scheme "s2color"

    marksample touse
    tempvar regime indicator t_idx
    qui gen long `t_idx' = _n if `touse'

    if "`model'" == "mtar" {
        capture qui gen double `indicator' = D.`varlist' if `touse'
        if _rc qui gen double `indicator' = `varlist'[_n] - `varlist'[_n-1] if `touse'
        qui replace `indicator' = 0 if missing(`indicator')
    }
    else {
        capture qui gen double `indicator' = L.`varlist' if `touse'
        if _rc qui gen double `indicator' = `varlist'[_n-1] if `touse'
    }

    qui gen byte `regime' = cond(`indicator' >= `threshold', 1, 0) if `touse'

    local ttl = cond("`title'"=="", "Regime classification on `varlist' (`model')", "`title'")

    twoway                                                                     ///
        (scatter `varlist' `t_idx' if `regime'==1 & `touse',                   ///
            msymbol(O) msize(small) mcolor(navy))                              ///
        (scatter `varlist' `t_idx' if `regime'==0 & `touse',                   ///
            msymbol(O) msize(small) mcolor(cranberry))                         ///
        , yline(`threshold', lcolor(purple) lwidth(medthick) lpattern(dash))   ///
        yline(0, lcolor(gs10) lwidth(thin))                                    ///
        scheme(`scheme') title("`ttl'")                                        ///
        subtitle("threshold tau = `=string(`threshold',"%9.4f")'")              ///
        ytitle("Residual") xtitle("Time index")                                 ///
        legend(order(1 "Regime 1 (indicator >= tau)" 2 "Regime 2 (indicator <  tau)") position(6) rows(1)) ///
        plotregion(margin(small))

    if "`saving'" != "" {
        graph save Graph `saving', replace
    }
end

// ---------------------------------------------------------------------
program define tc_plot_grid
    syntax [, TITLE(string) SAVING(string) SCHEME(string)]
    if "`scheme'" == "" local scheme "s2color"
    * Snapshot r() into temp matrices BEFORE anything else
    tempname gV gS
    capture matrix `gV' = r(grid_values)
    if _rc {
        di as error "tc_plot grid: last test did not store r(grid_values)."
        di as error "  Run tc_bf, tc_hs, or another sup-type test first."
        exit 198
    }
    capture matrix `gS' = r(grid_stats)
    if _rc {
        di as error "tc_plot grid: last test did not store r(grid_stats)."
        exit 198
    }
    di as text "(grid matrix dimensions: " as result rowsof(`gV') " x " colsof(`gV') as text ")"

    preserve
    quietly {
        drop _all
        svmat `gV', names("__tcgV")
        svmat `gS', names("__tcgS")
        rename __tcgV1 grid_threshold
        rename __tcgS1 grid_stat
        * Drop rows where the test couldn't be computed
        drop if missing(grid_stat) | missing(grid_threshold)
        * Deduplicate on threshold (in case of ties) and sort
        sort grid_threshold
    }
    qui count
    local ngp = r(N)
    di as text "(valid grid points for plot: " as result `ngp' as text ")"
    if `ngp' < 2 {
        di as error "tc_plot grid: not enough valid grid points to plot (N = `ngp')."
        restore
        exit 198
    }
    quietly summarize grid_stat, meanonly
    local maxs = r(max)
    * find argmax via sort (immune to float-equality issues)
    gsort -grid_stat
    local argmax = grid_threshold[1]
    qui sort grid_threshold
    * Tag the sup-stat observation robustly (avoid float-equality issues)
    tempvar is_sup
    qui gen byte `is_sup' = reldif(grid_stat, `maxs') < 1e-10

    local ttl = cond("`title'"=="", "Grid search: test statistic over threshold", "`title'")
    twoway                                                                       ///
        (line grid_stat grid_threshold,                                          ///
            lcolor(teal) lwidth(medthick))                                       ///
        (scatter grid_stat grid_threshold if `is_sup',                           ///
            msize(large) msymbol(O) mcolor(gold) mlcolor(black) mlwidth(thin))   ///
        , xline(`argmax', lcolor(purple) lpattern(dash))                         ///
        scheme(`scheme') title(`"`ttl'"')                                        ///
        subtitle("sup-stat = `=string(`maxs',"%9.3f")'   at tau = `=string(`argmax',"%9.4f")'") ///
        ytitle("Test statistic") xtitle("Threshold value (tau)")                 ///
        legend(order(1 "grid statistic" 2 "sup-stat") position(6) rows(1))       ///
        plotregion(margin(small))
    if "`saving'" != "" {
        graph save Graph `saving', replace
    }
    restore
end

// ---------------------------------------------------------------------
program define tc_plot_ect
    syntax varname(numeric) [if] [in] [, THReshold(real 0) TITLE(string) SAVING(string) SCHEME(string)]
    if "`scheme'" == "" local scheme "s2color"
    marksample touse
    tempvar regime t_idx
    qui gen long `t_idx' = _n if `touse'
    qui gen byte `regime' = cond(`varlist' <= `threshold', 0, 1) if `touse'
    local ttl = cond("`title'"=="", "TVECM error-correction term -- regime classification", "`title'")
    twoway                                                                     ///
        (scatter `varlist' `t_idx' if `regime'==0 & `touse',                   ///
            msymbol(O) msize(small) mcolor(navy))                              ///
        (scatter `varlist' `t_idx' if `regime'==1 & `touse',                   ///
            msymbol(O) msize(small) mcolor(cranberry))                         ///
        , yline(`threshold', lcolor(purple) lwidth(medthick) lpattern(dash))   ///
        scheme(`scheme') title("`ttl'")                                        ///
        subtitle("threshold gamma = `=string(`threshold',"%9.4f")'")           ///
        ytitle("ECT") xtitle("Time index")                                     ///
        legend(order(1 "Regime 1 (ECT <= gamma)" 2 "Regime 2 (ECT > gamma)") position(6) rows(1)) ///
        plotregion(margin(small))
    if "`saving'" != "" {
        graph save Graph `saving', replace
    }
end
