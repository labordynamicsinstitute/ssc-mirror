*! xtqrplot v1.3.0  02apr2026
*! Author: Dr Noman Arshed, Sunway University, nouman.arshed@gmail.com
*! Supports balanced and unbalanced panel data

program define xtqrplot
    version 14.0
    syntax varlist(min=2 numeric) [if] [in],  ///
        PANELvar(varname) TIMEvar(varname)    ///
        [ Method(string) REPs(integer 200)    ///
          SEED(integer -1)                    ///
          NWindows(integer 9) EFFect(string)  ///
          PLOTtype(string) SAVing(string)     ///
          REPLACE NOPlot NONOrmal ]

    di as text "  [xtqrplot v1.3.0]"

    tokenize `varlist'
    local depvar "`1'"
    macro shift
    local xvars "`*'"
    local nx : word count `xvars'

    if "`method'"   == "" local method   "xtqreg"
    if "`effect'"   == "" local effect   "coef"
    if "`plottype'" == "" local plottype "cross"

    if !inlist("`method'","xtqreg","qregpd") {
        di as error "method() must be xtqreg or qregpd"
        exit 198
    }
    if !inlist("`effect'","coef","semi","elast","bp") {
        di as error "effect() must be coef semi elast or bp"
        exit 198
    }
    if !inlist("`plottype'","cross","time","twoway") {
        di as error "plottype() must be cross time or twoway"
        exit 198
    }
    if `nwindows' < 1 | `nwindows' > 49 {
        di as error "nwindows() must be 1-49"
        exit 198
    }
    if "`method'" == "xtqreg" {
        capture which xtqreg
        if _rc {
            di as error "xtqreg not installed. Run: ssc install xtqreg"
            exit 199
        }
    }
    if "`method'" == "qregpd" {
        capture which qregpd
        if _rc {
            di as error "qregpd not installed. Run: ssc install qregpd"
            exit 199
        }
    }

    capture quietly xtset `panelvar' `timevar'
    if _rc {
        di as error "Cannot xtset with panelvar(`panelvar') timevar(`timevar')"
        exit 459
    }

    marksample touse
    markout `touse' `panelvar' `timevar'
    quietly count if `touse'
    if r(N) == 0 {
        di as error "No observations in estimation sample."
        exit 2000
    }
    local n_obs = r(N)

    // Build quantile grid -- store as rounded strings to avoid float mismatch
    local quantiles  ""
    local qdecimals  ""
    local qpct_str   ""
    forvalues i = 1/`nwindows' {
        local q_prop = `i' / (`nwindows' + 1)
        local q_pct  = round(`q_prop' * 100, 0.001)
        local quantiles  "`quantiles' `q_pct'"
        local qdecimals  "`qdecimals' `q_prop'"
    }
    local nq : word count `quantiles'

    // Pre-capture labels before any data change
    local xi = 1
    foreach xv of local xvars {
        local vlab`xi' : variable label `xv'
        if `"`vlab`xi''"' == "" local vlab`xi' "`xv'"
        local xi = `xi' + 1
    }
    local delab : variable label `depvar'
    if `"`delab'"' == "" local delab "`depvar'"

    preserve
    quietly keep if `touse'

    // ------------------------------------------------------------------
    // NORMALITY TESTS
    // ------------------------------------------------------------------
    if "`nonormal'" == "" {
        di as text _n "{hline 65}"
        di as text "  PRE-ESTIMATION NORMALITY DIAGNOSTICS"
        di as text "{hline 65}"
        local nbins = `nwindows' + 1
        foreach v in `depvar' `xvars' {
            local vl : variable label `v'
            if "`vl'" == "" local vl "`v'"
            di as text _n "  Variable: {bf:`v'} (`vl')"
            di as text "  {hline 45}"
            quietly count if !missing(`v')
            local sk_n = r(N)

            // sktest -- r() names vary by Stata version; try both
            capture sktest `v'
            if !_rc {
                // Try Stata 17 names first (p_skew, p_kurt, p)
                local sk_psk = r(p_skew)
                local sk_pku = r(p_kurt)
                local sk_p   = r(p)
                // If missing, try older names (Pr_skew, Pr_kurt, P_chi2)
                if missing(`sk_psk') local sk_psk = r(Pr_skew)
                if missing(`sk_pku') local sk_pku = r(Pr_kurt)
                if missing(`sk_p')   local sk_p   = r(P_chi2)
                local sk_psk_s : di %6.4f `sk_psk'
                local sk_pku_s : di %6.4f `sk_pku'
                local sk_p_s   : di %6.4f `sk_p'
                di as text "    sktest:    N=`sk_n'  Pr(Skew)=`sk_psk_s'  Pr(Kurt)=`sk_pku_s'  Joint=`sk_p_s'"
            }
            else di as text "    sktest: skipped (rc=" _rc ")"

            capture swilk `v'
            if !_rc {
                local sw_W : di %7.5f r(W)
                local sw_p : di %6.4f r(p)
                di as text "    swilk:    W=`sw_W'  p=`sw_p'"
            }
            else di as text "    swilk: skipped"

            capture sfrancia `v'
            if !_rc {
                local sf_W : di %7.5f r(W)
                local sf_p : di %6.4f r(p)
                di as text "    sfrancia: W=`sf_W'  p=`sf_p'"
            }
            else di as text "    sfrancia: skipped"

            // Histogram using addplot(kdensity) -- Test 4 approach
            capture twoway                                            ///
                (histogram `v', bin(`nbins')                          ///
                    fcolor("31 119 180%55") lcolor(white) lwidth(thin) ///
                    frequency)                                         ///
                (kdensity `v',                                         ///
                    lcolor("200 50 50") lwidth(medthick)               ///
                    yaxis(2)),                                         ///
                title("Distribution: `vl'", size(small))              ///
                subtitle("`nbins' bins = quantile windows",           ///
                    size(vsmall))                                      ///
                xtitle("`vl'", size(small))                           ///
                ytitle("Frequency", size(small))                      ///
                ytitle("Density", size(small) axis(2))                ///
                legend(order(2 "Kernel density") size(vsmall)         ///
                    pos(1) ring(0))                                    ///
                note("Red curve = kernel density estimate",           ///
                    size(vsmall))                                      ///
                name(_hist_`v', replace)
            if _rc {
                di as text "    Histogram (rc=" _rc "): run manually --"
                di as text "      twoway (histogram `v', bin(`nbins') frequency) (kdensity `v')"
            }
        }
        di as text "{hline 65}"
    }

    // ------------------------------------------------------------------
    // PANEL QUANTILE REGRESSIONS
    // ------------------------------------------------------------------
    tempname B SE
    matrix `B'  = J(`nq', `nx', .)
    matrix `SE' = J(`nq', `nx', .)

    // Set seed for reproducibility if using qregpd
    if "`method'" == "qregpd" & `seed' >= 0 {
        set seed `seed'
        di as text "  (seed set to `seed' for reproducibility)"
    }

    di as text _n "{hline 65}"
    di as text "  xtqrplot v1.3.0  --  method: `method'"
    di as text "  Dep.var: `delab'  |  effect: `effect'  |  windows: `nq'"
    di as text "{hline 65}"

    local qi = 1
    foreach q_pct of local quantiles {
        local q_prop : word `qi' of `qdecimals'
        local q_disp = round(`q_pct', 0.001)
        local q_disp_s = strofreal(`q_disp', "%12.0g")
        di as text "  Quantile `q_disp_s'%" _continue

        if "`method'" == "xtqreg" {
            capture quietly xtqreg `depvar' `xvars',  ///
                i(`panelvar') quantile(`q_prop')
        }
        else {
            // qregpd syntax: reps() goes inside vce(), no comma before reps
            capture quietly qregpd `depvar' `xvars',  ///
                id(`panelvar') quantile(`q_prop')      ///
                reps(`reps')
        }
        if _rc {
            local rc_save = _rc
            di as error _n "  FAILED at q`q_disp'% (rc=`rc_save'). Possible causes:"
            di as error "    1. Too few obs for this quantile -- reduce nwindows()"
            di as error "    2. Collinear or time-invariant regressor"
            if "`method'" == "qregpd" {
                di as error "    3. qregpd needs more within-panel variation"
                di as error "    4. Try xtqreg instead: method(xtqreg)"
            }
            else {
                di as error "    3. Try fewer windows: nwindows(" int(`nwindows'/2) ")"
            }
            restore
            exit `rc_save'
        }
        di as text "  [ok]"
        local xi = 1
        foreach xv of local xvars {
            matrix `B'[`qi',`xi']  = _b[`xv']
            matrix `SE'[`qi',`xi'] = _se[`xv']
            local xi = `xi' + 1
        }
        local qi = `qi' + 1
    }

    // ------------------------------------------------------------------
    // MEDIAN-LEVEL SUMMARY TABLE
    // ------------------------------------------------------------------
    local med_qi    = 1
    local med_qdist = 999
    local med_qpct  = .
    local qi = 1
    foreach q_pct of local quantiles {
        local dist = abs(`q_pct' - 50)
        if `dist' < `med_qdist' {
            local med_qdist = `dist'
            local med_qi    = `qi'
            local med_qpct  = `q_pct'
        }
        local qi = `qi' + 1
    }
    local med_qpct_r  = round(`med_qpct', 0.001)
    local med_qpct_s = strofreal(`med_qpct_r', "%12.0g")

    di as text _n "{hline 65}"
    di as text "  MEDIAN-LEVEL RESULTS  (nearest to q50, estimated at q`med_qpct_s'%)"
    di as text "{hline 65}"
    di as text "  {col 5}Variable{col 26}Coef{col 37}Std.Err{col 49}z{col 57}p"
    di as text "  {hline 60}"
    forvalues xi = 1/`nx' {
        local bval  = `B'[`med_qi',`xi']
        local seval = `SE'[`med_qi',`xi']
        if !missing(`seval') & `seval' > 0 {
            local zval = `bval' / `seval'
            local pval = 2*(1-normal(abs(`zval')))
        }
        else {
            local zval = .
            local pval = .
        }
        di as text   "  {col 5}`vlab`xi''" ///
           as result _col(26) %8.4f `bval' _col(37) %8.4f `seval' ///
                     _col(49) %6.2f `zval' _col(57) %6.4f `pval'
    }
    di as text "  {hline 60}"
    // Replication command -- printed once, clean
    local med_q_prop : word `med_qi' of `qdecimals'
    local med_q_prop_s : di %6.4f `med_q_prop'
    if "`method'" == "xtqreg" {
        di as text "  Replicate: xtqreg `depvar' `xvars', i(`panelvar') quantile(`med_q_prop_s')"
    }
    else {
        if `seed' >= 0 {
            di as text "  Replicate: set seed `seed'"
            di as text "             qregpd `depvar' `xvars', id(`panelvar') quantile(`med_q_prop_s') reps(`reps')"
        }
        else {
            di as text "  Replicate: qregpd `depvar' `xvars', id(`panelvar') quantile(`med_q_prop_s') reps(`reps')"
            di as text "  Note: add seed(#) option for exact reproducibility"
        }
    }
    // ------------------------------------------------------------------
    // EFFECT LABEL
    // ------------------------------------------------------------------
    if "`effect'" == "coef"  local efflab "Marginal Effect (Coefficient)"
    if "`effect'" == "semi"  local efflab "Semi-Elasticity (beta x X)"
    if "`effect'" == "elast" local efflab "Elasticity (beta x X / Y)"
    if "`effect'" == "bp"    local efflab "Basis Points (beta x 10,000)"

    // ------------------------------------------------------------------
    // BUILD ENTITY DATASET + COMPUTE EFFECTS
    // ------------------------------------------------------------------
    di as text _n "  Computing entity-level effects..."

    if "`plottype'" == "cross" {
        local coll "collapse (mean) _my = `depvar'"
        local xi = 1
        foreach xv of local xvars {
            local coll "`coll' (mean) _mx`xi' = `xv'"
            local xi = `xi' + 1
        }
        quietly `coll', by(`panelvar')
    }
    else if "`plottype'" == "time" {
        local coll "collapse (mean) _my = `depvar'"
        local xi = 1
        foreach xv of local xvars {
            local coll "`coll' (mean) _mx`xi' = `xv'"
            local xi = `xi' + 1
        }
        quietly `coll', by(`timevar')
    }
    else {
        quietly gen _my = `depvar'
        local xi = 1
        foreach xv of local xvars {
            quietly gen _mx`xi' = `xv'
            local xi = `xi' + 1
        }
        quietly keep `panelvar' `timevar' _my _mx*
    }

    // Percentile rank
    sort _my
    quietly gen _pctrank = (_n - 0.5) / _N * 100

    // Nearest-window assignment using rounded quantile values
    quietly gen _q_win    = .
    quietly gen _q_win_d  = 999   // distance tracker
    foreach q_pct of local quantiles {
        quietly replace _q_win   = `q_pct' if missing(_q_win)
        quietly replace _q_win_d = abs(_pctrank - `q_pct') if missing(_q_win_d)
        quietly replace _q_win   = `q_pct' if abs(_pctrank - `q_pct') < _q_win_d
        quietly replace _q_win_d = abs(_pctrank - `q_pct') if abs(_pctrank - `q_pct') < _q_win_d
    }
    quietly drop _q_win_d

    // Compute effects + 95% CI for each X
    forvalues xi = 1/`nx' {
        quietly gen _eff`xi'    = .
        quietly gen _eff`xi'_lo = .
        quietly gen _eff`xi'_hi = .
        label variable _eff`xi'    "`vlab`xi''"
        label variable _eff`xi'_lo "`vlab`xi'' CI-lo"
        label variable _eff`xi'_hi "`vlab`xi'' CI-hi"
        local qi = 1
        foreach q_pct of local quantiles {
            local bval  = `B'[`qi',`xi']
            local seval = `SE'[`qi',`xi']
            local lo    = `bval' - 1.96*`seval'
            local hi    = `bval' + 1.96*`seval'
            // Match using rounded window value
            local qm = round(`q_pct', 0.001)
            if "`effect'" == "coef" {
                quietly replace _eff`xi'    = `bval' if round(_q_win,0.001)==`qm'
                quietly replace _eff`xi'_lo = `lo'   if round(_q_win,0.001)==`qm'
                quietly replace _eff`xi'_hi = `hi'   if round(_q_win,0.001)==`qm'
            }
            else if "`effect'" == "semi" {
                quietly replace _eff`xi'    = `bval'*_mx`xi' if round(_q_win,0.001)==`qm'
                quietly replace _eff`xi'_lo = `lo'  *_mx`xi' if round(_q_win,0.001)==`qm'
                quietly replace _eff`xi'_hi = `hi'  *_mx`xi' if round(_q_win,0.001)==`qm'
            }
            else if "`effect'" == "elast" {
                quietly count if _my<=0 & round(_q_win,0.001)==`qm'
                if r(N)>0 di as text "  Warning: `r(N)' obs Y<=0 at q`q_pct'"
                quietly replace _eff`xi'    = (`bval'*_mx`xi')/_my if round(_q_win,0.001)==`qm' & _my>0
                quietly replace _eff`xi'_lo = (`lo'  *_mx`xi')/_my if round(_q_win,0.001)==`qm' & _my>0
                quietly replace _eff`xi'_hi = (`hi'  *_mx`xi')/_my if round(_q_win,0.001)==`qm' & _my>0
            }
            else if "`effect'" == "bp" {
                quietly replace _eff`xi'    = `bval'*10000 if round(_q_win,0.001)==`qm'
                quietly replace _eff`xi'_lo = `lo'  *10000 if round(_q_win,0.001)==`qm'
                quietly replace _eff`xi'_hi = `hi'  *10000 if round(_q_win,0.001)==`qm'
            }
            local qi = `qi' + 1
        }
    }

    // ------------------------------------------------------------------
    // RESULTS TABLE
    // ------------------------------------------------------------------
    if "`plottype'" == "cross" {
        local idvar "`panelvar'"
        local idlbl "Entity"
    }
    else if "`plottype'" == "time" {
        local idvar "`timevar'"
        local idlbl "Period"
    }
    else {
        local idvar "`panelvar'"
        local idlbl "Entity"
    }

    di as text _n "{hline 65}"
    di as text "  RESULTS TABLE  --  `efflab'"
    di as text "{hline 65}"
    di as text _col(2) "`idlbl'" _col(17) "Mean(Y)" _col(26) "Pctile" _col(34) "Q-win" _continue
    forvalues xi = 1/`nx' {
        local hcol = 42 + (`xi'-1)*13
        di as text _col(`hcol') abbrev("`vlab`xi''",11) _continue
    }
    di as text ""
    di as text "  {hline 65}"
    quietly levelsof `idvar', local(idvals)
    foreach iv of local idvals {
        local lbl : label (`idvar') `iv'
        if "`lbl'" == "" local lbl "`iv'"
        quietly summarize _my      if `idvar'==`iv', meanonly
        local myval  = r(mean)
        quietly summarize _pctrank if `idvar'==`iv', meanonly
        local pctval = r(mean)
        quietly summarize _q_win   if `idvar'==`iv', meanonly
        local qwin   = r(mean)
        di as result _col(2) abbrev("`lbl'",13)       ///
            _col(17) %7.3f `myval'                    ///
            _col(26) %5.1f `pctval' "%"               ///
            _col(34) %4.1f `qwin'   "%" _continue
        forvalues xi = 1/`nx' {
            quietly summarize _eff`xi' if `idvar'==`iv', meanonly
            local ecol = 42 + (`xi'-1)*13
            di as result _col(`ecol') %9.4f r(mean) _continue
        }
        di as text ""
    }
    di as text "  {hline 65}"
    di as text "  Columns: Mean(Y)=mean dependent variable, Pctile=exact percentile,"
    di as text "           Q-win=assigned quantile window"
    di as text "  Tip: add saving(filename) to export this dataset."

    // ------------------------------------------------------------------
    // SAVE DATASET
    // ------------------------------------------------------------------
    if "`saving'" != "" {
        local sfx = cond("`plottype'"=="cross","cross", ///
                    cond("`plottype'"=="time","time","twoway"))
        local dsave "`saving'_`sfx'.dta"
        if "`replace'" != "" {
            quietly save "`dsave'", replace
        }
        else {
            capture quietly save "`dsave'"
            if _rc==602 {
                di as error "`dsave' already exists. Add replace option."
                restore
                exit 602
            }
        }
        di as text "  Dataset saved: `dsave'"
    }

    // ------------------------------------------------------------------
    // PLOTS
    // ------------------------------------------------------------------
    if "`noplot'" == "" {
        local vlabstr ""
        forvalues xi = 1/`nx' {
            if `xi'==1 local vlabstr `"`vlab`xi''"'
            else        local vlabstr `"`vlabstr'|`vlab`xi''"'
        }
        if inlist("`plottype'","cross","time") {
            local entvar = cond("`plottype'"=="cross","`panelvar'","`timevar'")
            capture confirm variable `entvar'
            if _rc {
                di as error "Internal: `entvar' not found after collapse."
                restore
                exit 111
            }
            _xtqrplot_bar `entvar',           ///
                nx(`nx')                       ///
                vlabstr(`"`vlabstr'"')         ///
                efflab(`"`efflab'"')           ///
                plottype(`plottype')           ///
                saving(`saving') `replace'
        }
        else {
            _xtqrplot_2d `panelvar' `timevar', ///
                nx(`nx')                        ///
                vlabstr(`"`vlabstr'"')          ///
                efflab(`"`efflab'"')            ///
                delab(`"`delab'"')              ///
                saving(`saving') `replace'
        }
    }

    restore
    di as text _n "{hline 65}"
    di as text "  xtqrplot complete."
    di as text "{hline 65}"
end


// ====================================================================
// BAR CHART SUBROUTINE (cross / time)
// Shows: bars coloured red/blue + 95% CI error bars
//        + secondary x-axis with exact percentile as circle marker
// ====================================================================
program define _xtqrplot_bar
    syntax varlist(min=1 max=1), nx(integer) vlabstr(string) ///
        efflab(string) plottype(string) [saving(string) replace]

    local entvar "`varlist'"
    tempvar enum
    capture confirm numeric variable `entvar'
    if _rc {
        encode `entvar', gen(`enum')
    }
    else {
        quietly gen `enum' = `entvar'
    }

    quietly levelsof `enum', local(evals)
    local ylabs ""
    foreach ev of local evals {
        local lbl : label (`enum') `ev'
        if "`lbl'" == "" local lbl "`ev'"
        local ylabs `"`ylabs' `ev' "`lbl'""'
    }

    local glist ""
    forvalues xi = 1/`nx' {
        local efflbl : variable label _eff`xi'
        if `"`efflbl'"' == "" {
            local efflbl : word `xi' of `vlabstr'
            local efflbl = subinstr("`efflbl'","|"," ",.)
        }

        tempvar pos neg lo hi pctdot
        quietly gen `pos'    = _eff`xi'    if _eff`xi' >= 0
        quietly gen `neg'    = _eff`xi'    if _eff`xi' <  0
        quietly gen `lo'     = _eff`xi'_lo
        quietly gen `hi'     = _eff`xi'_hi
        // Percentile as secondary axis dot: scale to same range as effects
        // We plot _pctrank on xaxis(2) as a scatter circle
        quietly gen `pctdot' = _pctrank

        twoway                                                         ///
            (bar `pos' `enum', horizontal barwidth(0.6)               ///
                fcolor("178 24 43%75") lcolor(none))                   ///
            (bar `neg' `enum', horizontal barwidth(0.6)               ///
                fcolor("33 102 172%75") lcolor(none))                  ///
            (rcap `lo' `hi' `enum', horizontal                        ///
                lcolor(gs5) lwidth(thin) msize(small))                 ///
            (scatter `enum' `pctdot',                                  ///
                msymbol(circle) msize(medium)                          ///
                mcolor("50 150 50%80") mlcolor(gs4) mlwidth(vthin)     ///
                xaxis(2)),                                             ///
            ytitle("") xtitle("`efflab'", size(small))                ///
            xtitle("Exact percentile of Mean(Y)", size(small)         ///
                axis(2))                                               ///
            xlabel(0(25)100, axis(2) labsize(vsmall) grid)            ///
            title("`efflbl'", size(medsmall) margin(b=1))             ///
            subtitle("`efflab'  |  Green circle = percentile of Mean(Y)", ///
                size(vsmall) margin(b=1))                             ///
            ylabel(`ylabs', labsize(vsmall) angle(0) nogrid)          ///
            xline(0, lcolor(gs10) lwidth(thin) lpattern(dash))        ///
            plotregion(fcolor(white) lcolor(white) margin(l=2 r=6))   ///
            graphregion(fcolor(white) lcolor(white))                  ///
            legend(order(3 "95% CI" 4 "Percentile (2nd axis)")        ///
                size(vsmall) pos(6) rows(1))                          ///
            name(_xtqrpb`xi', replace) nodraw
        local glist "`glist' _xtqrpb`xi'"
    }

    if `nx' == 1 {
        graph display _xtqrpb1
        local finalg "_xtqrpb1"
    }
    else {
        local cols = min(`nx',3)
        graph combine `glist', cols(`cols')                            ///
            title("Panel Quantile -- Entity Effects", size(small))    ///
            subtitle("`efflab'", size(vsmall))                        ///
            graphregion(fcolor(white) lcolor(white))                  ///
            name(_xtqrpb_c, replace)
        local finalg "_xtqrpb_c"
    }

    if "`saving'" != "" {
        local gf "`saving'_`plottype'.gph"
        if "`replace'" != "" {
            graph save `finalg' "`gf'", replace
        }
        else {
            capture graph save `finalg' "`gf'"
            if _rc==602 di as error "`gf' exists. Add replace."
        }
        if !_rc di as text "  Graph saved: `gf'"
    }
end


// ====================================================================
// 2D HEAT MAP SUBROUTINE (panel x time)
// Uses msize proportional to abs(effect) for visual weight
// Also prints a matrix table of coefficient values
// ====================================================================
// ====================================================================
// _xtqrplot_2d: contour heat map (panel x time), one per X variable
// Uses twoway contour -- z=effect, y=panel index, x=time
// Also prints a matrix table with auto column width
// ====================================================================
// ====================================================================
// _xtqrplot_2d  v1.3.0
// Heat map: panel (rows) x time (cols), colour = effect magnitude
// Primary:  heatplot (ssc install heatplot / palettes / colrspace)
// Fallback: twoway scatter with pre-expanded colour locals
// Also prints a coefficient matrix table to the screen
// ====================================================================
program define _xtqrplot_2d
    syntax varlist(min=2 max=2), nx(integer) vlabstr(string) ///
        efflab(string) delab(string) [saving(string) replace]

    tokenize `varlist'
    local panelvar "`1'"
    local timevar  "`2'"

    // Numeric panel index
    tempvar pnum
    capture confirm numeric variable `panelvar'
    if _rc {
        encode `panelvar', gen(`pnum')
    }
    else {
        quietly gen `pnum' = `panelvar'
    }

    quietly levelsof `pnum', local(pvals)
    local np : word count `pvals'
    local ylabs ""
    foreach pv of local pvals {
        local lbl : label (`pnum') `pv'
        if "`lbl'" == "" local lbl "`pv'"
        local ylabs `"`ylabs' `pv' "`lbl'""'
    }

    quietly levelsof `timevar', local(tvals)
    local nt : word count `tvals'

    // X-axis labels: integer strings, thinned if many periods
    local xstep = 1
    if `nt' > 12 local xstep = 2
    if `nt' > 24 local xstep = 3
    local xval_list ""
    local xi2 = 0
    foreach tv of local tvals {
        local xi2 = `xi2' + 1
        if mod(`xi2'-1, `xstep') == 0 {
            local tvstr = strofreal(`tv', "%12.0g")
            local xval_list `"`xval_list' `tv' "`tvstr'""'
        }
    }

    local xsize = max(14, `nt' * 1.3)

    // Check whether heatplot is installed
    capture which heatplot
    local have_heatplot = (_rc == 0)

    // One plot per X variable
    forvalues xi = 1/`nx' {

        local efflbl : variable label _eff`xi'
        if `"`efflbl'"' == "" {
            local efflbl : word `xi' of `vlabstr'
            local efflbl = subinstr("`efflbl'","|"," ",.)
        }

        quietly summarize _eff`xi'
        local emin    = r(min)
        local emax    = r(max)
        local eabsmax = max(abs(`emin'), abs(`emax'), 1e-10)
        local lmin : di %6.3f `emin'
        local lmax : di %6.3f `emax'

        // ==============================================================
        // METHOD 1: heatplot (requires heatplot + palettes + colrspace)
        // Builds a Stata matrix from the data and passes to heatplot
        // ==============================================================
        if `have_heatplot' {

            // Build a matrix: rows=panel units, cols=time periods
            // Row/col names must be valid Stata names (no spaces)
            local rnames ""
            foreach pv of local pvals {
                local lbl : label (`pnum') `pv'
                if "`lbl'" == "" local lbl "`pv'"
                // Replace spaces with underscores for matrix rowname
                local lbl2 = subinstr("`lbl'"," ","_",.)
                local rnames "`rnames' `lbl2'"
            }
            local cnames ""
            foreach tv of local tvals {
                local cnames "`cnames' y`tv'"
            }

            tempname M
            matrix `M' = J(`np', `nt', .)
            local ri = 1
            foreach pv of local pvals {
                local ci = 1
                foreach tv of local tvals {
                    quietly summarize _eff`xi' ///
                        if `pnum'==`pv' & `timevar'==`tv', meanonly
                    if r(N) > 0 {
                        matrix `M'[`ri',`ci'] = r(mean)
                    }
                    local ci = `ci' + 1
                }
                local ri = `ri' + 1
            }
            matrix rownames `M' = `rnames'
            matrix colnames `M' = `cnames'

            capture heatplot `M',                                     ///
                values(format(%5.3f) color(black) size(small))        ///
                aspectratio(1)                                        ///
                ylabel(`ylabs', angle(0) labsize(small))              ///
                xlabel(`xval_list', angle(45) labsize(small))         ///
                color(hcl diverging, reverse)                         ///
                cuts(`emin'(` = (`emax'-`emin')/15 ')`emax')          ///
                legend(title("`efflbl'", size(small)) size(vsmall))   ///
                title("Effect of `efflbl' on `delab'",                ///
                    size(small) margin(b=1))                          ///
                subtitle("`efflab'", size(vsmall) margin(b=1))        ///
                plotregion(color(white))                              ///
                graphregion(color(white))                             ///
                xsize(`xsize') ysize(12)                              ///
                name(_xtqrp2d`xi', replace)
            if _rc {
                di as text "  heatplot failed (rc=" _rc "), using scatter fallback"
                local have_heatplot = 0
            }
        }

        // ==============================================================
        // METHOD 2: Scatter fallback (no extra packages needed)
        // 10 layers with pre-expanded RGB colour strings
        // Avoids the ``c`b'' double-dereference quoting trap by
        // using a forvalues loop with explicit if-then colour assignment
        // ==============================================================
        if !`have_heatplot' {

            tempvar cbin effval_v
            quietly gen `effval_v' = _eff`xi'

            // Assign bins 1-5 (negative, light->dark blue) and
            // 6-10 (positive, light->dark red)
            quietly gen `cbin' = 6   // default: lightest red (near zero)

            forvalues b = 1/5 {
                local lo_b = (`b'-1) * `eabsmax' / 5
                local hi_b =  `b'    * `eabsmax' / 5
                quietly replace `cbin' = `b' if _eff`xi' < 0 ///
                    & abs(_eff`xi') > `lo_b'                   ///
                    & abs(_eff`xi') <= `hi_b'                  ///
                    & !missing(_eff`xi')
            }
            forvalues b = 1/5 {
                local lo_b = (`b'-1) * `eabsmax' / 5
                local hi_b =  `b'    * `eabsmax' / 5
                local bpos = `b' + 5
                quietly replace `cbin' = `bpos' if _eff`xi' >= 0 ///
                    & _eff`xi' > `lo_b'                            ///
                    & _eff`xi' <= `hi_b'                           ///
                    & !missing(_eff`xi')
            }

            // Build 10 scatter layers with literal RGB colours
            // (no macro dereference inside mcolor -- all values hardcoded
            //  per iteration to avoid Stata quoting issues)
            local scmd ""
            // bin 1: lightest blue  "209 229 240"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==1,  msymbol(square) msize(vhuge) mcolor("209 229 240") mlcolor(white) mlwidth(vthin))"'
            // bin 2: "146 197 222"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==2,  msymbol(square) msize(vhuge) mcolor("146 197 222") mlcolor(white) mlwidth(vthin))"'
            // bin 3: "67 147 195"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==3,  msymbol(square) msize(vhuge) mcolor("67 147 195")  mlcolor(white) mlwidth(vthin))"'
            // bin 4: "33 102 172"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==4,  msymbol(square) msize(vhuge) mcolor("33 102 172")  mlcolor(white) mlwidth(vthin))"'
            // bin 5: darkest blue  "5 48 97"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==5,  msymbol(square) msize(vhuge) mcolor("5 48 97")     mlcolor(white) mlwidth(vthin))"'
            // bin 6: lightest red  "253 219 199"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==6,  msymbol(square) msize(vhuge) mcolor("253 219 199") mlcolor(white) mlwidth(vthin))"'
            // bin 7: "244 165 130"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==7,  msymbol(square) msize(vhuge) mcolor("244 165 130") mlcolor(white) mlwidth(vthin))"'
            // bin 8: "214 96 77"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==8,  msymbol(square) msize(vhuge) mcolor("214 96 77")   mlcolor(white) mlwidth(vthin))"'
            // bin 9: "178 24 43"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==9,  msymbol(square) msize(vhuge) mcolor("178 24 43")   mlcolor(white) mlwidth(vthin))"'
            // bin 10: darkest red  "103 0 31"
            local scmd `"`scmd' (scatter `pnum' `timevar' if `cbin'==10, msymbol(square) msize(vhuge) mcolor("103 0 31")    mlcolor(white) mlwidth(vthin))"'
            // value labels below each cell
            local scmd `"`scmd' (scatter `pnum' `timevar', msymbol(none) mlabel(`effval_v') mlabsize(vsmall) mlabcolor(gs3) mlabformat(%5.3f) mlabposition(6) mlabgap(0))"'

            capture twoway `scmd',                                    ///
                ytitle("`panelvar'", size(small))                     ///
                xtitle("`timevar'", size(small))                      ///
                title("Effect of `efflbl' on `delab'",               ///
                    size(small) margin(b=1))                          ///
                subtitle("`efflab'  |  Blue=neg  Red=pos",           ///
                    size(vsmall) margin(b=1))                         ///
                ylabel(`ylabs', labsize(vsmall) angle(0) nogrid)     ///
                xlabel(`xval_list', labsize(vsmall) angle(45)        ///
                    nogrid labgap(2))                                 ///
                plotregion(fcolor(white) lcolor(white)               ///
                    margin(r=4 l=4 t=4 b=4))                         ///
                graphregion(fcolor(white) lcolor(white))              ///
                xsize(`xsize') ysize(12)                              ///
                legend(order(                                          ///
                    1 "Strong neg (`lmin')"                           ///
                    3 "Moderate neg"                                   ///
                    5 "Weak neg"                                       ///
                    6 "Weak pos"                                       ///
                    8 "Moderate pos"                                   ///
                    10 "Strong pos (`lmax')")                          ///
                    rows(2) size(vsmall) pos(6)                        ///
                    symysize(2) symxsize(4))                           ///
                name(_xtqrp2d`xi', replace)
            if _rc {
                di as error "  Scatter heat map failed for `efflbl' (rc=" _rc ")."
                di as error "  Matrix table below still shows all values."
            }
        }

        // ==============================================================
        // MATRIX TABLE (always shown regardless of plot outcome)
        // Auto column width based on number of time periods
        // ==============================================================
        local colw = 8
        if `nt' > 15 local colw = 7
        if `nt' > 20 local colw = 6
        local labw = 13
        local totw = `labw' + `nt' * `colw' + 4
        if `totw' > 100 local totw = 100

        di as text _n "  {hline `totw'}"
        di as text "  TWOWAY MATRIX TABLE: `efflbl' on `delab'"
        di as text "  `efflab'"
        di as text "  {hline `totw'}"
        di as text _col(2) "Entity" _continue
        local tcol = `labw' + 3
        foreach tv of local tvals {
            local tvstr = strofreal(`tv', "%12.0g")
            di as text _col(`tcol') %`colw's "`tvstr'" _continue
            local tcol = `tcol' + `colw'
        }
        di as text ""
        di as text "  {hline `totw'}"
        foreach pv of local pvals {
            local plbl : label (`pnum') `pv'
            if "`plbl'" == "" local plbl "`pv'"
            di as result _col(2) abbrev("`plbl'", `labw') _continue
            local tcol = `labw' + 3
            foreach tv of local tvals {
                quietly summarize _eff`xi' ///
                    if `pnum'==`pv' & `timevar'==`tv', meanonly
                if r(N) > 0 {
                    di as result _col(`tcol') %`colw'.3f r(mean) _continue
                }
                else {
                    di as text _col(`tcol') %`colw's "." _continue
                }
                local tcol = `tcol' + `colw'
            }
            di as text ""
        }
        di as text "  {hline `totw'}"

        if "`saving'" != "" {
            local gf "`saving'_twoway_x`xi'.gph"
            if "`replace'" != "" {
                capture graph save _xtqrp2d`xi' "`gf'", replace
            }
            else {
                capture graph save _xtqrp2d`xi' "`gf'"
                if _rc==602 di as error "`gf' exists. Add replace."
            }
            if !_rc di as text "  Graph saved: `gf'"
        }
    }
end
