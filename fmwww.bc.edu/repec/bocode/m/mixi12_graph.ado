*! mixi12_graph 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Diagnostic plots for mixed I(1)/I(2) analysis.
*
*  Modes:
*     mixi12_graph levels VARLIST [, save(filename)]
*       — 4-panel plot: levels, first differences, 4-quarter MA of Δ,
*         and second differences.  The hallmark I(2) "smoothness" is
*         visually obvious here.
*
*     mixi12_graph cointspace
*       — after mixi12_johansen: cointegrating relations β'X_t against
*         residual β'R_{1t} (Juselius's I(2)-symptom diagnostic).
*
*     mixi12_graph trends
*       — after mixi12_johansen: cumulated common stochastic trends
*         α'_⊥1 Σε_i and α'_⊥2 ΣΣε_i.

program define mixi12_graph
    version 14
    gettoken sub 0 : 0, parse(" ,")
    syntax [varlist(ts default=none)] [, SAVE(string) NAME(string) SCHeme(string)]
    if "`name'" == "" local name "mixi12graph"
    if "`scheme'" == "" local scheme "s2color"

    if "`sub'" == "levels" {
        if "`varlist'" == "" {
            di as err "mixi12_graph levels: specify the variable list"
            exit 102
        }
        // build (or recover) a time index for the x axis
        capture tsset
        local tvar `r(timevar)'
        if "`tvar'" == "" {
            tempvar tvar_local
            qui gen long `tvar_local' = _n
            local tvar `tvar_local'
        }
        tempvar ma4
        local glist ""
        local glist_d ""
        local glist_d2 ""
        foreach v of varlist `varlist' {
            local glist `glist' (line `v' `tvar', lcolor(navy))
            tempvar d_`v' d2_`v' ma_`v'
            qui gen double `d_`v''  = D.`v'
            qui gen double `d2_`v'' = D2.`v'
            qui gen double `ma_`v'' = (L2.`d_`v''+L.`d_`v''+`d_`v''+F.`d_`v'')/4
            local glist_d `glist_d' (line `d_`v'' `tvar', lcolor(maroon)) ///
                                   (line `ma_`v'' `tvar', lcolor(black) lwidth(medthick))
            local glist_d2 `glist_d2' (line `d2_`v'' `tvar', lcolor(forest_green))
        }
        twoway `glist',  name(`name'_lev,  replace) title("Levels") ///
               scheme(`scheme') ylabel(, angle(0) nogrid) xtitle("t") legend(off)
        twoway `glist_d', name(`name'_d, replace) title("First differences (with 4-period MA)") ///
               scheme(`scheme') ylabel(, angle(0) nogrid) xtitle("t") legend(off)
        twoway `glist_d2', name(`name'_d2, replace) title("Second differences") ///
               scheme(`scheme') ylabel(, angle(0) nogrid) xtitle("t") legend(off)
        graph combine `name'_lev `name'_d `name'_d2, ///
            name(`name', replace) cols(1) ysize(8) xsize(6) ///
            title("{bf:mixi12 diagnostics} - integration features", size(medium))
        if "`save'" != "" graph export "`save'", replace
    }
    else if "`sub'" == "cointspace" {
        if "`e(cmd)'" != "mixi12_johansen" {
            di as err "mixi12_graph cointspace: run mixi12_johansen first"
            exit 301
        }
        capture tsset
        local tvar `r(timevar)'
        if "`tvar'" == "" {
            tempvar tvar_local
            qui gen long `tvar_local' = _n
            local tvar `tvar_local'
        }
        // β'X_t  for each column of β
        tempname beta
        matrix `beta' = e(beta)
        local p = e(p)
        local r = e(rank)
        local i 0
        local depvars `e(depvars)'
        local glist ""
        forvalues j = 1/`r' {
            tempvar bx`j'
            qui gen double `bx`j'' = 0
            local k 0
            foreach v of varlist `depvars' {
                local ++k
                if `k' > `p' continue
                local coef = `beta'[`k', `j']
                qui replace `bx`j'' = `bx`j'' + `coef'*`v'
            }
            local glist `glist' (line `bx`j'' `tvar', name(`name'_cv`j', replace))
        }
        twoway `glist', name(`name', replace) ///
            title("{bf:Cointegrating relations β'X_t}", size(medium)) ///
            ytitle("β_j' X_t") xtitle("t") legend(off) scheme(`scheme')
        if "`save'" != "" graph export "`save'", replace
    }
    else if "`sub'" == "trends" {
        if "`e(cmd)'" != "mixi12_johansen" {
            di as err "mixi12_graph trends: run mixi12_johansen first"
            exit 301
        }
        capture tsset
        local tvar `r(timevar)'
        if "`tvar'" == "" {
            tempvar tvar_local
            qui gen long `tvar_local' = _n
            local tvar `tvar_local'
        }
        local depvars `e(depvars)'
        local glist ""
        foreach v of varlist `depvars' {
            tempvar c_`v'
            qui gen double `c_`v'' = sum(`v')
            local glist `glist' (line `c_`v'' `tvar', name(`name'_t_`v', replace))
        }
        twoway `glist', name(`name', replace) ///
            title("{bf:Cumulated common-trend proxies}", size(medium)) ///
            ytitle("Σ X_t") xtitle("t") legend(off) scheme(`scheme')
        if "`save'" != "" graph export "`save'", replace
    }
    else {
        di as err "mixi12_graph: subcommand must be levels | cointspace | trends"
        exit 198
    }
end
