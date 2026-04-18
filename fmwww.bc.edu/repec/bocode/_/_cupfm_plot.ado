*! _cupfm_plot.ado - Publication-quality visualizations for cupfm
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Version: 1.0.1 - 2026-04-16 (First SSC submission)
*!
*! Produces:
*!  Plot 1: Coefficient comparison (all 5 estimators with 95% CI)
*!  Plot 2: Estimated common factors (time series)
*!  Plot 3: Factor loadings

capture program drop _cupfm_plot
program define _cupfm_plot
    version 14
    // STATA 17 BATCH FIX: integer() options cause r(197) in batch mode.
    // All numeric options declared as string() and converted manually.
    syntax, ///
        DEPvar(string)     ///
        INDepvars(string)  ///
        TIMevar(string)    ///
        Ng(string)         ///
        Tobs(string)       ///
        Rfact(string)      ///
        [SAVing(string)    ///
         GRaph(string)]    // all | coef | factors | loadings
    // Convert string -> integer
    local ng    = int(real("`ng'"))
    local tobs  = int(real("`tobs'"))
    local rfact = int(real("`rfact'"))

    // Pre-compute filename prefix ONCE - avoids nested-quote r(132)
    local _pfx = cond("`saving'"!="", "`saving'", "cupfm")

    local do_coef    = ("`graph'" == "" | "`graph'" == "all" | "`graph'" == "coef")
    local do_factors = ("`graph'" == "" | "`graph'" == "all" | "`graph'" == "factors")
    local do_loads   = ("`graph'" == "" | "`graph'" == "all" | "`graph'" == "loadings")

    local nv   : word count `indepvars'
    local cv05 = invnormal(0.975)   // 1.960

    // ── Graphics scheme setup ────────────────────────────────────────────
    capture set scheme economist
    if _rc != 0 {
        capture set scheme s2color
    }

    // ═══════════════════════════════════════════════════════════════════
    //  PLOT 1: COEFFICIENT COMPARISON - all 5 estimators
    // ═══════════════════════════════════════════════════════════════════
    if `do_coef' {
        preserve
        clear
        local nrows = `nv' * 5
        quietly set obs `nrows'

        tempname B_lsdv B_bai B_cup B_cup2 B_bc
        tempname T_lsdv T_bai T_cup T_cup2 T_bc
        matrix `B_lsdv'  = _cupfm_b_lsdv
        matrix `B_bai'   = _cupfm_b_baifm
        matrix `B_cup'   = _cupfm_b_cupfm
        matrix `B_cup2'  = _cupfm_b_cupfm2
        matrix `B_bc'    = _cupfm_b_cupbc
        matrix `T_lsdv'  = _cupfm_t_lsdv
        matrix `T_bai'   = _cupfm_t_baifm
        matrix `T_cup'   = _cupfm_t_cupfm
        matrix `T_cup2'  = _cupfm_t_cupfm2
        matrix `T_bc'    = _cupfm_t_cupbc

        quietly gen double coef_val  = .
        quietly gen double ci_lo     = .
        quietly gen double ci_hi     = .
        quietly gen str20  estimator = ""
        quietly gen str20  varname   = ""
        quietly gen int    est_id    = .
        quietly gen int    var_id    = .

        local obs = 0
        // STATA 17 BATCH FIX: avoid quoted-string list; use per-estimator name locals
        // ":word N of" with quoted multi-word names returns surrounding quotes -> r(132)
        local ename1 LSDV
        local ename2 Bai_FM
        local ename3 CupFM
        local ename4 CupFM-bar
        local ename5 CupBC

        forvalues j = 1/`nv' {
            local vname : word `j' of `indepvars'
            local vabbr = abbrev("`vname'", 10)

            forvalues ei = 1/5 {
                local ++obs
                local bval = (`ei'==1)*`B_lsdv'[1,`j'] + ///
                             (`ei'==2)*`B_bai'[1,`j']  + ///
                             (`ei'==3)*`B_cup'[1,`j']  + ///
                             (`ei'==4)*`B_cup2'[1,`j'] + ///
                             (`ei'==5)*`B_bc'[1,`j']
                local tval = (`ei'==1)*`T_lsdv'[1,`j'] + ///
                             (`ei'==2)*`T_bai'[1,`j']  + ///
                             (`ei'==3)*`T_cup'[1,`j']  + ///
                             (`ei'==4)*`T_cup2'[1,`j'] + ///
                             (`ei'==5)*`T_bc'[1,`j']
                local se_val = cond(abs(`tval') > 0.001, abs(`bval'/`tval'), 0)
                local lo_val = `bval' - `cv05'*`se_val'
                local hi_val = `bval' + `cv05'*`se_val'
                local ename `ename`ei''
                quietly replace coef_val  = `bval'    in `obs'
                quietly replace ci_lo     = `lo_val'  in `obs'
                quietly replace ci_hi     = `hi_val'  in `obs'
                quietly replace estimator = "`ename'"  in `obs'
                quietly replace varname   = "`vabbr'"  in `obs'
                quietly replace est_id    = `ei'       in `obs'
                quietly replace var_id    = `j'        in `obs'
            }
        }

        forvalues j = 1/`nv' {
            local vname : word `j' of `indepvars'
            local vabbr = abbrev("`vname'", 10)

            quietly twoway ///
                (rcap ci_lo ci_hi est_id if var_id==`j', horizontal lcolor(gs8) lwidth(thin)) ///
                (scatter est_id coef_val if var_id==`j' & est_id==1, msymbol(D) mcolor(navy)         msize(medlarge)) ///
                (scatter est_id coef_val if var_id==`j' & est_id==2, msymbol(D) mcolor(orange)       msize(medlarge)) ///
                (scatter est_id coef_val if var_id==`j' & est_id==3, msymbol(D) mcolor(forest_green) msize(medlarge)) ///
                (scatter est_id coef_val if var_id==`j' & est_id==4, msymbol(D) mcolor(purple)       msize(medlarge)) ///
                (scatter est_id coef_val if var_id==`j' & est_id==5, msymbol(D) mcolor(cranberry)    msize(medlarge)) ///
                , ///
                ylabel(1 "LSDV" 2 "Bai FM" 3 "CupFM" 4 "CupFM-bar" 5 "CupBC", ///
                    angle(0) labsize(small)) ///
                xtitle("Coefficient Estimate", size(small)) ytitle("") ///
                title("Coefficient Comparison: `vabbr'", ///
                    size(medsmall) color(black)) ///
                subtitle("95% CIs | Bai, Kao & Ng (2009)", size(vsmall)) ///
                xline(0, lcolor(red) lpattern(dash) lwidth(thin)) ///
                legend(off) ///
                graphregion(color(white)) plotregion(color(white)) ///
                note("Dep var: `depvar' | CupFM = recommended", size(vsmall))

            if "`saving'" != "" {
                capture quietly graph save "`saving'_coef`j'", replace
            }
            local _fn "`_pfx'_coef_`vabbr'.png"
            capture graph export "`_fn'", replace width(1200) height(700)
            if _rc == 0 di as text "  Plot saved: " as result "`_fn'"
            else        di as text "  Note: PNG export skipped for `_fn' (check display/path)"
        }
        restore
    }

    // ═══════════════════════════════════════════════════════════════════
    //  PLOT 2: ESTIMATED COMMON FACTORS (Time series)
    // ═══════════════════════════════════════════════════════════════════
    if `do_factors' & `rfact' > 0 {
        preserve
        tempname F_hat
        matrix `F_hat' = _cupfm_f

        clear
        quietly set obs `tobs'
        quietly gen int t = _n

        forvalues ri = 1/`rfact' {
            quietly gen double F`ri' = .
            forvalues ti = 1/`tobs' {
                quietly replace F`ri' = `F_hat'[`ti', `ri'] in `ti'
            }
        }

        // STATA 17 BATCH FIX: named colors avoid nested-quote r(132) in tw_cmd
        // lcolor(name) needs no quotes; avoids "..." inside "..." parse error
        local tw_cmd ""
        if `rfact' >= 1 local tw_cmd "`tw_cmd' (line F1 t, lcolor(navy)      lwidth(medthick) lpattern(solid))"
        if `rfact' >= 2 local tw_cmd "`tw_cmd' (line F2 t, lcolor(cranberry)  lwidth(medthick) lpattern(dash))"
        if `rfact' >= 3 local tw_cmd "`tw_cmd' (line F3 t, lcolor(forest_green) lwidth(medthick) lpattern(longdash))"
        if `rfact' >= 4 local tw_cmd "`tw_cmd' (line F4 t, lcolor(red)        lwidth(medthick) lpattern(dot))"
        if `rfact' >= 5 local tw_cmd "`tw_cmd' (line F5 t, lcolor(purple)     lwidth(medthick) lpattern(shortdash))"

        // Legend order only — labels drawn from variable names
        local leg_label ""
        forvalues ri = 1/`rfact' {
            local leg_label "`leg_label' `ri'"
        }

        twoway `tw_cmd' ///
            , ///
            xtitle("Time Period", size(small)) ///
            ytitle("Factor Score", size(small)) ///
            title("Estimated Common Factors (r=`rfact')", size(medsmall) color(black)) ///
            subtitle("Panel Cointegration CupFM | Bai, Kao & Ng (2009)", size(vsmall)) ///
            yline(0, lcolor(gs10) lpattern(dash) lwidth(vthin)) ///
            legend(order(`leg_label') size(small) position(6) rows(1)) ///
            graphregion(color(white)) plotregion(color(white)) ///
            note("I(1) Stochastic Trends | `ng' cross-sections x `tobs' periods", size(vsmall))

        if "`saving'" != "" {
            capture quietly graph save "`saving'_factors", replace
        }
        local _fn "`_pfx'_factors.png"
        capture graph export "`_fn'", replace width(1200) height(700)
        if _rc == 0 di as text "  Plot saved: " as result "`_fn'"
        else        di as text "  Note: PNG export skipped for `_fn' (check display/path)"
        restore
    }

    // ═══════════════════════════════════════════════════════════════════
    //  PLOT 3: FACTOR LOADINGS
    // ═══════════════════════════════════════════════════════════════════
    if `do_loads' & `rfact' > 0 {
        preserve
        tempname L_hat
        matrix `L_hat' = _cupfm_lambda

        clear
        quietly set obs `ng'
        quietly gen int unit = _n

        forvalues ri = 1/`rfact' {
            quietly gen double lambda`ri' = .
            forvalues ni = 1/`ng' {
                quietly replace lambda`ri' = `L_hat'[`ni', `ri'] in `ni'
            }
        }

        if `rfact' == 1 {
            twoway (bar lambda1 unit, barwidth(0.7) color(navy%70) lcolor(navy)) ///
                , ///
                xtitle("Cross-Section Unit (i)", size(small)) ///
                ytitle("Factor Loading lambda_i", size(small)) ///
                title("Factor Loadings: lambda_i (r=1)", size(medsmall)) ///
                subtitle("Heterogeneous factor responses | Bai & Ng (2002)", size(vsmall)) ///
                yline(0, lcolor(red) lpattern(dash) lwidth(vthin)) ///
                graphregion(color(white)) plotregion(color(white))
        }
        else if `rfact' >= 2 {
            twoway ///
                (scatter lambda2 lambda1, msymbol(O) mcolor(navy%80) msize(medlarge) ///
                 mlabel(unit) mlabsize(tiny) mlabcolor(gs6)) ///
                , ///
                xtitle("Loading Factor 1 (lambda_i1)", size(small)) ///
                ytitle("Loading Factor 2 (lambda_i2)", size(small)) ///
                title("Factor Loadings Scatter: lambda_1 vs lambda_2", size(medsmall)) ///
                subtitle("Each point = one cross-section unit | r=2", size(vsmall)) ///
                xline(0, lcolor(gs12) lpattern(dash) lwidth(vthin)) ///
                yline(0, lcolor(gs12) lpattern(dash) lwidth(vthin)) ///
                graphregion(color(white)) plotregion(color(white)) ///
                note("N=`ng' units | Bai, Kao & Ng (2009)", size(vsmall))
        }

        if "`saving'" != "" {
            capture quietly graph save "`saving'_loadings", replace
        }
        local _fn "`_pfx'_loadings.png"
        capture graph export "`_fn'", replace width(1000) height(700)
        if _rc == 0 di as text "  Plot saved: " as result "`_fn'"
        else        di as text "  Note: PNG export skipped for `_fn' (check display/path)"
        restore
    }
end
