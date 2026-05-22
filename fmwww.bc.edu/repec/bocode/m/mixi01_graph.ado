*! mixi01_graph 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! mixi01_graph — Visualization command for mixi01
*! Supports: irf, fevd, coefplot, permanent, transitory

program define mixi01_graph
    version 17.0

    syntax ,                         ///
        [IRF                         ///
         FEVD                        ///
         COEFplot                    ///
         PERManent                   ///
         TRANSitory                  ///
         Step(integer 20)            ///
         Shock(string)               ///
         Response(string)            ///
         CI                          ///
         Level(cilevel)              ///
         NReps(integer 500)          ///
         SCHeme(string)              ///
         SAVE(string)               ///
         COMBine                     ///
         TITle(string)               ///
         SUBtitle(string)            ///
         NOte(string)                ///
         name(string)                ///
        ]

    /* ── validate: must pick one graph type ── */
    local ntypes = ("`irf'" != "") + ("`fevd'" != "") + ///
                   ("`coefplot'" != "") + ("`permanent'" != "") + ///
                   ("`transitory'" != "")

    if `ntypes' == 0 {
        di as err "must specify one of: irf, fevd, coefplot, permanent, transitory"
        exit 198
    }
    if `ntypes' > 1 & "`combine'" == "" {
        di as err "specify only one graph type, or use combine option"
        exit 198
    }

    /* ── defaults ── */
    if `"`scheme'"' == "" local scheme "s2color"
    if `"`name'"' == "" local name "mixi01_graph"

    /* ── dispatch ── */
    if "`irf'" != "" {
        _mixi01_graph_irf, step(`step') shock(`shock') response(`response') ///
            `ci' level(`level') nreps(`nreps') scheme(`scheme') ///
            save(`save') title(`title') subtitle(`subtitle') ///
            note(`note') name(`name')
    }
    else if "`fevd'" != "" {
        _mixi01_graph_fevd, step(`step') shock(`shock') response(`response') ///
            scheme(`scheme') save(`save') title(`title') ///
            subtitle(`subtitle') note(`note') name(`name')
    }
    else if "`coefplot'" != "" {
        _mixi01_graph_coefplot, level(`level') scheme(`scheme') ///
            save(`save') title(`title') name(`name')
    }
    else if "`permanent'" != "" | "`transitory'" != "" {
        _mixi01_graph_components, ///
            permanent(`permanent') transitory(`transitory') ///
            scheme(`scheme') save(`save') title(`title') ///
            subtitle(`subtitle') name(`name')
    }
end


/* ================================================================== */
/*  IRF Grid Plot                                                      */
/*  Response of each variable to each shock                            */
/* ================================================================== */
program define _mixi01_graph_irf
    version 17.0

    syntax , step(integer) [shock(string) response(string) ///
        CI level(cilevel) nreps(integer 500) scheme(string) ///
        save(string) title(string) subtitle(string) ///
        note(string) name(string)]

    /* ── check estimation results ── */
    if "`e(cmd)'" == "" {
        di as err "no mixi01 estimation results found"
        exit 301
    }

    /* ── retrieve dimensions ── */
    tempname irf_mat
    cap matrix `irf_mat' = e(irf)
    if _rc {
        di as err "no IRF matrix found in e(irf). Run mixi01 irf first."
        exit 301
    }

    local nvars = e(n_vars)
    if `nvars' == . | `nvars' == 0 {
        /* Infer from matrix dimensions */
        local nvars = colsof(`irf_mat')
    }

    local varnames "`e(varnames)'"
    if `"`varnames'"' == "" {
        /* Generate generic names */
        forvalues i = 1/`nvars' {
            local varnames "`varnames' y`i'"
        }
    }

    /* ── determine which shocks/responses to plot ── */
    local shock_list ""
    if `"`shock'"' != "" {
        local shock_list "`shock'"
    }
    else {
        local shock_list "`varnames'"
    }

    local resp_list ""
    if `"`response'"' != "" {
        local resp_list "`response'"
    }
    else {
        local resp_list "`varnames'"
    }

    local n_shocks : word count `shock_list'
    local n_resp   : word count `resp_list'

    /* ── build IRF data for plotting ── */
    preserve
    clear
    qui set obs `= `step' + 1'
    qui gen horizon = _n - 1

    /* Extract IRF values from e(irf) matrix */
    /* IRF matrix layout: (nsteps+1)*nvars rows, nvars columns */
    /* Block h: rows h*nvars+1 .. (h+1)*nvars */

    local graph_list ""
    local plot_num = 0

    forvalues si = 1/`n_shocks' {
        local sname : word `si' of `shock_list'

        /* Find shock index in varnames */
        local s_idx = 0
        local vi = 0
        foreach v of local varnames {
            local ++vi
            if "`v'" == "`sname'" {
                local s_idx = `vi'
            }
        }
        if `s_idx' == 0 {
            di as txt "  warning: shock `sname' not found, skipping"
            continue
        }

        forvalues ri = 1/`n_resp' {
            local rname : word `ri' of `resp_list'

            /* Find response index */
            local r_idx = 0
            local vi = 0
            foreach v of local varnames {
                local ++vi
                if "`v'" == "`rname'" {
                    local r_idx = `vi'
                }
            }
            if `r_idx' == 0 continue

            local ++plot_num
            local vname "irf_`plot_num'"
            qui gen `vname' = .

            /* Fill IRF values */
            forvalues h = 0/`step' {
                local mat_row = `h' * `nvars' + `r_idx'
                if `mat_row' <= rowsof(`irf_mat') {
                    qui replace `vname' = `irf_mat'[`mat_row', `s_idx'] in `= `h' + 1'
                }
            }

            /* Generate CI bounds if requested */
            if "`ci'" != "" {
                qui gen `vname'_lo = .
                qui gen `vname'_hi = .

                /* Bootstrap CI from e(irf_lo) and e(irf_hi) if available */
                cap confirm matrix e(irf_lo)
                if !_rc {
                    tempname irf_lo irf_hi
                    matrix `irf_lo' = e(irf_lo)
                    matrix `irf_hi' = e(irf_hi)
                    forvalues h = 0/`step' {
                        local mat_row = `h' * `nvars' + `r_idx'
                        if `mat_row' <= rowsof(`irf_lo') {
                            qui replace `vname'_lo = `irf_lo'[`mat_row', `s_idx'] in `= `h' + 1'
                            qui replace `vname'_hi = `irf_hi'[`mat_row', `s_idx'] in `= `h' + 1'
                        }
                    }
                }
                else {
                    /* Simple analytical CI: IRF +/- 1.96 * se */
                    cap confirm matrix e(irf_se)
                    if !_rc {
                        tempname irf_se_mat
                        matrix `irf_se_mat' = e(irf_se)
                        local crit = invnormal(1 - (100 - `level') / 200)
                        forvalues h = 0/`step' {
                            local mat_row = `h' * `nvars' + `r_idx'
                            if `mat_row' <= rowsof(`irf_se_mat') {
                                local se_val = `irf_se_mat'[`mat_row', `s_idx']
                                local irf_val = `irf_mat'[`mat_row', `s_idx']
                                qui replace `vname'_lo = `irf_val' - `crit' * `se_val' in `= `h' + 1'
                                qui replace `vname'_hi = `irf_val' + `crit' * `se_val' in `= `h' + 1'
                            }
                        }
                    }
                }
            }

            /* Build individual graph */
            local gtitle "`rname' {&larr} `sname'"

            if "`ci'" != "" & "`vname'_lo" != "" {
                local gcmd `"(rarea `vname'_lo `vname'_hi horizon, "'
                local gcmd `"`gcmd' fcolor(navy%15) lcolor(navy%30) lwidth(none))"'
                local gcmd `"`gcmd' (line `vname' horizon, lcolor(navy) lwidth(medthick))"'
                local gcmd `"`gcmd', yline(0, lcolor(gs10) lpattern(dash))"'
                local gcmd `"`gcmd' title("`gtitle'", size(small))"'
                local gcmd `"`gcmd' xtitle("") ytitle("")"'
                local gcmd `"`gcmd' legend(off) scheme(`scheme')"'
                local gcmd `"`gcmd' name(irf_`plot_num', replace) nodraw"'
            }
            else {
                local gcmd `"twoway (line `vname' horizon, lcolor(navy) lwidth(medthick))"'
                local gcmd `"`gcmd', yline(0, lcolor(gs10) lpattern(dash))"'
                local gcmd `"`gcmd' title("`gtitle'", size(small))"'
                local gcmd `"`gcmd' xtitle("") ytitle("")"'
                local gcmd `"`gcmd' legend(off) scheme(`scheme')"'
                local gcmd `"`gcmd' name(irf_`plot_num', replace) nodraw"'
            }

            cap `gcmd'
            if !_rc {
                local graph_list "`graph_list' irf_`plot_num'"
            }
        }
    }

    /* ── combine into grid ── */
    if `plot_num' > 0 {
        if `"`title'"' == "" local title "Structural Impulse Response Functions"
        if `"`subtitle'"' == "" local subtitle "mixi01 `e(method)'"
        if `"`note'"' == "" local note "Shaded area: `level'% CI"

        local combine_cmd `"graph combine `graph_list',"'
        local combine_cmd `"`combine_cmd' title("`title'") subtitle("`subtitle'")"'
        local combine_cmd `"`combine_cmd' note("`note'")"'
        local combine_cmd `"`combine_cmd' scheme(`scheme') name(`name', replace)"'
        local combine_cmd `"`combine_cmd' cols(`n_shocks') iscale(0.6)"'

        cap noi `combine_cmd'

        if `"`save'"' != "" {
            qui graph export `"`save'"', replace
            di as txt "  Graph saved to: " as res `"`save'"'
        }
    }
    else {
        di as err "no valid shock-response pairs found"
    }

    restore
end


/* ================================================================== */
/*  FEVD Stacked Bar Chart                                             */
/* ================================================================== */
program define _mixi01_graph_fevd
    version 17.0

    syntax , step(integer) [shock(string) response(string) ///
        scheme(string) save(string) title(string) ///
        subtitle(string) note(string) name(string)]

    /* ── check estimation results ── */
    tempname fevd_mat
    cap matrix `fevd_mat' = e(fevd)
    if _rc {
        di as err "no FEVD matrix found in e(fevd). Run mixi01 irf first."
        exit 301
    }

    local nvars = e(n_vars)
    if `nvars' == . local nvars = colsof(`fevd_mat')

    local varnames "`e(varnames)'"
    if `"`varnames'"' == "" {
        forvalues i = 1/`nvars' {
            local varnames "`varnames' y`i'"
        }
    }

    /* ── determine responses to plot ── */
    local resp_list ""
    if `"`response'"' != "" {
        local resp_list "`response'"
    }
    else {
        local resp_list "`varnames'"
    }
    local n_resp : word count `resp_list'

    /* Colors for shocks */
    local colors "navy cranberry forest_green dkorange purple teal maroon olive_teal"

    /* ── build data and plot ── */
    preserve
    clear

    local graph_list ""
    local plot_cnt = 0

    forvalues ri = 1/`n_resp' {
        local rname : word `ri' of `resp_list'

        /* Find response index */
        local r_idx = 0
        local vi = 0
        foreach v of local varnames {
            local ++vi
            if "`v'" == "`rname'" local r_idx = `vi'
        }
        if `r_idx' == 0 continue

        local ++plot_cnt

        clear
        qui set obs `= `step' + 1'
        qui gen horizon = _n - 1

        /* Extract FEVD shares for this response variable */
        forvalues si = 1/`nvars' {
            local sname : word `si' of `varnames'
            qui gen fevd_`si' = .
            forvalues h = 0/`step' {
                local mat_row = `h' * `nvars' + `r_idx'
                if `mat_row' <= rowsof(`fevd_mat') {
                    qui replace fevd_`si' = `fevd_mat'[`mat_row', `si'] * 100 in `= `h' + 1'
                }
            }
        }

        /* Build stacked bar chart */
        local bar_cmd ""
        forvalues si = 1/`nvars' {
            local sname : word `si' of `varnames'
            local col   : word `si' of `colors'
            if "`col'" == "" local col "navy"
            local bar_cmd `"`bar_cmd' (bar fevd_`si' horizon, color(`col'%70))"'
        }

        if `"`title'"' == "" local gtitle "FEVD: `rname'"
        else local gtitle "`title'"

        /* Legend labels */
        local leg_labels ""
        forvalues si = 1/`nvars' {
            local sname : word `si' of `varnames'
            local leg_labels `"`leg_labels' label(`si' "`sname'")"'
        }

        local full_cmd `"twoway `bar_cmd',"'
        local full_cmd `"`full_cmd' title("`gtitle'", size(small))"'
        local full_cmd `"`full_cmd' xtitle("Horizon") ytitle("Percent")"'
        local full_cmd `"`full_cmd' ylabel(0(20)100) legend(rows(1) size(vsmall) `leg_labels')"'
        local full_cmd `"`full_cmd' scheme(`scheme') name(fevd_`plot_cnt', replace) nodraw"'

        cap noi `full_cmd'
        if !_rc {
            local graph_list "`graph_list' fevd_`plot_cnt'"
        }
    }

    /* Combine */
    if `plot_cnt' > 0 {
        if `plot_cnt' == 1 {
            cap graph display fevd_1
        }
        else {
            if `"`title'"' == "" local title "Forecast Error Variance Decomposition"
            cap graph combine `graph_list', ///
                title("`title'") scheme(`scheme') ///
                name(`name', replace) cols(2)
        }

        if `"`save'"' != "" {
            qui graph export `"`save'"', replace
            di as txt "  Graph saved to: " as res `"`save'"'
        }
    }

    restore
end


/* ================================================================== */
/*  Coefficient Comparison Plot                                        */
/*  I(1) vs I(0) blocks side by side                                  */
/* ================================================================== */
program define _mixi01_graph_coefplot
    version 17.0

    syntax [, level(cilevel) scheme(string) save(string) ///
        title(string) name(string)]

    if "`e(cmd)'" == "" {
        di as err "no mixi01 estimation results found"
        exit 301
    }

    tempname b V

    matrix `b' = e(b)
    matrix `V' = e(V)

    local k    = e(k)
    local k1   = e(k_stat)
    local k2   = e(k_nonstat)
    local crit = invnormal(1 - (100 - `level') / 200)

    local st_names  "`e(st_names)'"
    local ns_names  "`e(ns_names)'"

    preserve
    clear
    local total_k = `k1' + `k2'
    qui set obs `total_k'

    qui gen str32 varname = ""
    qui gen coef    = .
    qui gen ci_lo   = .
    qui gen ci_hi   = .
    qui gen byte order_type = .  /* 1=I(1), 2=I(0) */
    qui gen plotid  = _n

    /* Fill I(0) block */
    local j = 0
    forvalues i = 1/`k1' {
        local ++j
        local vn : word `i' of `st_names'
        if "`vn'" == "" local vn "x`i'"
        qui replace varname = "`vn'" in `j'
        qui replace coef = `b'[1, `i'] in `j'
        local se = sqrt(`V'[`i', `i'])
        qui replace ci_lo = `b'[1, `i'] - `crit' * `se' in `j'
        qui replace ci_hi = `b'[1, `i'] + `crit' * `se' in `j'
        qui replace order_type = 2 in `j'
    }

    /* Fill I(1) block */
    forvalues i = 1/`k2' {
        local ++j
        local idx = `k1' + `i'
        local vn : word `i' of `ns_names'
        if "`vn'" == "" local vn "z`i'"
        qui replace varname = "`vn'" in `j'
        qui replace coef = `b'[1, `idx'] in `j'
        local se = sqrt(`V'[`idx', `idx'])
        qui replace ci_lo = `b'[1, `idx'] - `crit' * `se' in `j'
        qui replace ci_hi = `b'[1, `idx'] + `crit' * `se' in `j'
        qui replace order_type = 1 in `j'
    }

    /* Plot */
    if `"`title'"' == "" local title "FM Coefficient Estimates"
    if `"`name'"' == "" local name "coefplot"

    twoway ///
        (rcap ci_lo ci_hi plotid if order_type == 1, ///
            horizontal lcolor(navy) lwidth(medthick)) ///
        (scatter plotid coef if order_type == 1, ///
            msymbol(O) mcolor(navy) msize(medium)) ///
        (rcap ci_lo ci_hi plotid if order_type == 2, ///
            horizontal lcolor(cranberry) lwidth(medthick)) ///
        (scatter plotid coef if order_type == 2, ///
            msymbol(D) mcolor(cranberry) msize(medium)) ///
        , ///
        xline(0, lcolor(gs10) lpattern(dash)) ///
        ylabel(1/`total_k', valuelabel angle(0) labsize(small)) ///
        ytitle("") xtitle("Coefficient") ///
        title("`title'") ///
        legend(order(2 "I(1)" 4 "I(0)") rows(1) size(small)) ///
        scheme(`scheme') name(`name', replace)

    /* Encode y-axis labels */
    cap labmask plotid, values(varname)
    cap label values plotid plotid

    if `"`save'"' != "" {
        qui graph export `"`save'"', replace
        di as txt "  Graph saved to: " as res `"`save'"'
    }

    restore
end


/* ================================================================== */
/*  Permanent / Transitory Component Plot                              */
/* ================================================================== */
program define _mixi01_graph_components
    version 17.0

    syntax , [permanent(string) transitory(string) ///
        scheme(string) save(string) title(string) ///
        subtitle(string) name(string)]

    if "`e(cmd)'" == "" {
        di as err "no mixi01 estimation results found"
        exit 301
    }

    /* ── retrieve component matrices ── */
    tempname y_perm y_trans

    cap matrix `y_perm'  = e(y_permanent)
    cap matrix `y_trans' = e(y_transitory)

    if _rc {
        di as err "no permanent/transitory components found."
        di as err "Run mixi01 with the components option first."
        exit 301
    }

    local nvars = colsof(`y_perm')
    local T     = rowsof(`y_perm')

    local varnames "`e(varnames)'"
    if `"`varnames'"' == "" {
        forvalues i = 1/`nvars' {
            local varnames "`varnames' y`i'"
        }
    }

    if `"`name'"' == "" local name "components"

    preserve
    clear
    qui set obs `T'
    qui gen t = _n

    local graph_list ""

    forvalues vi = 1/`nvars' {
        local vn : word `vi' of `varnames'

        qui gen actual_`vi' = .
        qui gen perm_`vi'   = .
        qui gen trans_`vi'  = .

        forvalues tt = 1/`T' {
            qui replace perm_`vi'  = `y_perm'[`tt', `vi']  in `tt'
            qui replace trans_`vi' = `y_trans'[`tt', `vi'] in `tt'
        }

        /* Actual = permanent + transitory */
        qui replace actual_`vi' = perm_`vi' + trans_`vi'

        if `"`title'"' == "" local gtitle "`vn': Permanent vs Transitory"
        else local gtitle "`title'"

        twoway ///
            (line actual_`vi' t, lcolor(gs8) lwidth(thin) lpattern(solid)) ///
            (line perm_`vi' t, lcolor(navy) lwidth(medthick)) ///
            (line trans_`vi' t, lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
            , ///
            title("`gtitle'", size(small)) ///
            xtitle("Time") ytitle("") ///
            legend(order(1 "Actual" 2 "Permanent (P{sub:0})" ///
                3 "Transitory (T{sub:0})") rows(1) size(vsmall)) ///
            scheme(`scheme') name(comp_`vi', replace) nodraw

        local graph_list "`graph_list' comp_`vi'"
    }

    /* Combine */
    if `nvars' > 1 {
        if `"`title'"' == "" local title "Beveridge-Nelson Decomposition"
        graph combine `graph_list', ///
            title("`title'") scheme(`scheme') ///
            name(`name', replace) cols(2)
    }
    else {
        graph display comp_1
    }

    if `"`save'"' != "" {
        qui graph export `"`save'"', replace
        di as txt "  Graph saved to: " as res `"`save'"'
    }

    restore
end
