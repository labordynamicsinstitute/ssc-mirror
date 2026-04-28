*! _regproject_nomo.ado v1.1.0 — Nomogram graphs for regproject
*! Author: Dr Noman Arshed, Sunway University
*!
*! Produces two graphs:
*!   rp_nomo1  — Contribution nomogram: horizontal bars showing the range of
*!               each variable's effect on ŷ, centred at the median baseline.
*!               Annotated with the raw IV values at each bar end so the user
*!               can read off "if X moves from A to B, ŷ shifts by Δ units".
*!   rp_nomo2  — Relative contribution bar chart: each variable's share of the
*!               total achievable variation in ŷ across all regressors.

program define _regproject_nomo
    version 14

    syntax varname [,                   ///
        regressors(string)              ///
        nreg(integer 0)                 ///
        focuspos(integer 0)             ///
        depvar(string)                  ///
        cons(real 0)                    ///
        bounds_lower(string)            ///
        bounds_upper(string)            ///
        med_vec(string)                 ///
        has_ymin(integer 0)             ///
        has_ymax(integer 0)             ///
        ymin_val(real 0)                ///
        ymax_val(real 0)                ///
        saving(string)                  ///
        NODisplay                       ///
    ]

    local focusvar `varlist'

    /* ------------------------------------------------------------------ */
    /*  STEP 1 — Extract coefficients, bounds, medians into scalars        */
    /* ------------------------------------------------------------------ */
    local kk = 0
    foreach v of local regressors {
        local ++kk
        local coef_`kk'  = _b[`v']
        local lb_`kk'    = `bounds_lower'[1, `kk']
        local ub_`kk'    = `bounds_upper'[1, `kk']
        local med_`kk'   = `med_vec'[1, `kk']
        local name_`kk'  = "`v'"
    }

    /* ------------------------------------------------------------------ */
    /*  STEP 2 — Build a temp dataset with one row per regressor           */
    /* ------------------------------------------------------------------ */
    preserve
    quietly drop _all
    quietly set obs `nreg'

    quietly generate str32  varname      = ""
    quietly generate double coef_val     = .
    quietly generate double var_lb       = .
    quietly generate double var_ub       = .
    quietly generate double var_med      = .

    /* contribution when IV is at lb: coef*(lb - med)                     */
    quietly generate double contrib_at_lb = .
    /* contribution when IV is at ub: coef*(ub - med)                     */
    quietly generate double contrib_at_ub = .

    /* rbar lower / upper — always lo ≤ hi regardless of coef sign        */
    quietly generate double rbar_lo      = .
    quietly generate double rbar_hi      = .

    /* absolute range of ŷ this IV can shift: |coef*(ub-lb)|             */
    quietly generate double contrib_range = .

    /* sign of coefficient: 1 = positive, 0 = negative                   */
    quietly generate int    pos_coef     = .

    /* focal IV flag                                                       */
    quietly generate int    focal        = 0

    /* per-unit effect (the coefficient itself) for dot chart             */
    quietly generate double unit_effect  = .

    forvalues k = 1/`nreg' {
        local clo  = `coef_`k'' * (`lb_`k'' - `med_`k'')
        local chi  = `coef_`k'' * (`ub_`k'' - `med_`k'')
        local crng = abs(`coef_`k'' * (`ub_`k'' - `lb_`k''))

        quietly replace varname       = "`name_`k''"               in `k'
        quietly replace coef_val      = `coef_`k''                 in `k'
        quietly replace var_lb        = `lb_`k''                   in `k'
        quietly replace var_ub        = `ub_`k''                   in `k'
        quietly replace var_med       = `med_`k''                  in `k'
        quietly replace contrib_at_lb = `clo'                      in `k'
        quietly replace contrib_at_ub = `chi'                      in `k'
        quietly replace rbar_lo       = min(`clo', `chi')          in `k'
        quietly replace rbar_hi       = max(`clo', `chi')          in `k'
        quietly replace contrib_range = `crng'                     in `k'
        quietly replace unit_effect   = `coef_`k''                 in `k'
        quietly replace pos_coef      = (`coef_`k'' >= 0)          in `k'

        if "`name_`k''" == "`focusvar'" {
            quietly replace focal = 1 in `k'
        }
    }

    /* ------------------------------------------------------------------ */
    /*  STEP 3 — Sort ascending by contribution range (tornado effect)    */
    /*  Largest range ends up at top of chart (highest ypos)              */
    /* ------------------------------------------------------------------ */
    sort contrib_range
    quietly generate int ypos = _n

    /* ------------------------------------------------------------------ */
    /*  STEP 4 — Summary scalars                                           */
    /* ------------------------------------------------------------------ */
    quietly summarize contrib_range
    local total_range = r(sum)
    local max_range   = r(max)

    quietly summarize contrib_range if focal == 1
    local focal_range = r(sum)

    quietly summarize coef_val if focal == 1
    local focal_coef  = r(mean)

    /* ------------------------------------------------------------------ */
    /*  STEP 5 — Y-axis label strings                                     */
    /*  Format: "varname  (b = X.XXXX)"                                   */
    /* ------------------------------------------------------------------ */
    quietly generate str64 ylab_str = varname + "  (b=" + string(coef_val, "%7.4f") + ")"

    /* Build the ylabel() option string */
    local ylab_opt ""
    forvalues j = 1/`nreg' {
        local lbl = ylab_str[`j']
        local ylab_opt `ylab_opt' `j' `"`lbl'"'
    }

    /* ------------------------------------------------------------------ */
    /*  STEP 6 — End-of-bar label values (the raw IV values)              */
    /*                                                                      */
    /*  LEFT end of bar (rbar_lo) corresponds to:                          */
    /*    if coef > 0 → variable at lb (moving down from median)          */
    /*    if coef < 0 → variable at ub (ub gives lowest ŷ when coef<0)   */
    /*  RIGHT end of bar (rbar_hi) is the opposite                        */
    /* ------------------------------------------------------------------ */
    quietly generate double left_iv_val  = cond(pos_coef == 1, var_lb,  var_ub)
    quietly generate double right_iv_val = cond(pos_coef == 1, var_ub,  var_lb)

    quietly generate str16  left_iv_str  = string(left_iv_val,  "%6.2f")
    quietly generate str16  right_iv_str = string(right_iv_val, "%6.2f")

    /* ------------------------------------------------------------------ */
    /*  STEP 7 — Mid-bar annotation: "Δŷ = X.XX"                         */
    /* ------------------------------------------------------------------ */
    quietly generate double bar_mid      = (rbar_lo + rbar_hi) / 2
    quietly generate str20  range_label  = "Δŷ=" + string(contrib_range, "%6.3f")

    /* ------------------------------------------------------------------ */
    /*  STEP 8 — X-axis display range                                      */
    /* ------------------------------------------------------------------ */
    quietly summarize rbar_lo
    local xlo_data = r(min)
    quietly summarize rbar_hi
    local xhi_data = r(max)
    local xspan    = `xhi_data' - `xlo_data'
    local xpad     = `xspan' * 0.18
    local g_xlo    = `xlo_data' - `xpad'
    local g_xhi    = `xhi_data' + `xpad'

    /* ------------------------------------------------------------------ */
    /*  STEP 9 — GRAPH 1: Contribution Nomogram                           */
    /* ------------------------------------------------------------------ */
    /*  Layers:                                                             */
    /*    1. Non-focal, positive coef → teal bars                          */
    /*    2. Non-focal, negative coef → maroon bars                        */
    /*    3. Focal IV → orange bars (drawn last, on top)                   */
    /*    4. Invisible scatter at rbar_lo for left IV-value labels         */
    /*    5. Invisible scatter at rbar_hi for right IV-value labels        */
    /*    6. Invisible scatter at bar_mid for Δŷ annotation               */
    /*    7. Diamond scatter at x=0 baseline                               */
    /* ------------------------------------------------------------------ */
    twoway                                                              ///
        (rbar rbar_lo rbar_hi ypos                                      ///
            if focal==0 & pos_coef==1,                                  ///
            horizontal barwidth(0.55)                                   ///
            color(teal%65) lcolor(teal%90) lwidth(vthin))              ///
        (rbar rbar_lo rbar_hi ypos                                      ///
            if focal==0 & pos_coef==0,                                  ///
            horizontal barwidth(0.55)                                   ///
            color(maroon%60) lcolor(maroon%90) lwidth(vthin))          ///
        (rbar rbar_lo rbar_hi ypos                                      ///
            if focal==1,                                                 ///
            horizontal barwidth(0.70)                                   ///
            color(orange%80) lcolor(orange) lwidth(thin))              ///
        (scatter ypos rbar_lo,                                          ///
            ms(none)                                                     ///
            mlabel(left_iv_str) mlabposition(9)                         ///
            mlabsize(vsmall) mlabcolor(gs4))                            ///
        (scatter ypos rbar_hi,                                          ///
            ms(none)                                                     ///
            mlabel(right_iv_str) mlabposition(3)                        ///
            mlabsize(vsmall) mlabcolor(gs4))                            ///
        (scatter ypos bar_mid,                                          ///
            ms(none)                                                     ///
            mlabel(range_label) mlabposition(12)                        ///
            mlabsize(tiny) mlabcolor(gs6))                              ///
        (scatter ypos bar_mid if focal==1,                              ///
            ms(none)                                                     ///
            mlabel(range_label) mlabposition(12)                        ///
            mlabsize(vsmall) mlabcolor(orange)),                        ///
        xline(0, lcolor(black) lwidth(medthick) lpattern(solid))       ///
        ylabel(`ylab_opt', angle(0) labsize(small) nogrid)             ///
        xlabel(, labsize(small) format(%6.3f))                         ///
        xtitle("Change in Predicted {it:`depvar'} (deviation from median baseline)", ///
               size(small))                                             ///
        ytitle("")                                                      ///
        xscale(range(`g_xlo' `g_xhi'))                                 ///
        title("Nomogram: Variable Contribution to {it:`depvar'}", size(medsmall)) ///
        subtitle("Bars span min–max ŷ contribution; centre line = all IVs at median;" ///
                 " end labels = raw IV values; annotations = |Δŷ|", size(vsmall)) ///
        note("Total achievable Δŷ (sum across IVs): `=string(`total_range', "%8.3f")' units" ///
             "  |  Focal IV ({it:`focusvar'}, b=`=string(`focal_coef', "%7.4f")'):" ///
             " `=string(`focal_range', "%8.3f")' units" ///
             "  |  Focal share: `=string(`focal_range'/`total_range'*100, "%4.1f")'%", ///
             size(vsmall))                                              ///
        legend(order(1 "Positive effect (coef > 0)"                    ///
                     2 "Negative effect (coef < 0)"                    ///
                     3 "`focusvar' (focal IV)")                         ///
               size(vsmall) rows(1))                                    ///
        scheme(s2color) name(rp_nomo1, replace)

    if "`saving'" != "" quietly graph save rp_nomo1 "`saving'_nomo1.gph", replace

    /* ------------------------------------------------------------------ */
    /*  STEP 10 — GRAPH 2: Percentage Contribution Chart                  */
    /*                                                                      */
    /*  Shows each variable's contribution_range / total_range as a       */
    /*  horizontal percentage bar, sorted ascending.                       */
    /*  Provides an at-a-glance "share of achievable variation" view.     */
    /* ------------------------------------------------------------------ */

    quietly generate double pct_contrib = contrib_range / `total_range' * 100
    quietly generate str20  pct_label   = string(pct_contrib, "%4.1f") + "% " ///
                                        + "(Δŷ=" + string(contrib_range, "%6.3f") + ")"

    /* Sort pct ascending — focal IV may land anywhere */
    sort pct_contrib
    quietly replace ypos = _n

    /* Rebuild ylabel with plain variable names for this chart */
    local ylab_opt2 ""
    forvalues j = 1/`nreg' {
        local lbl2 = varname[`j']
        local ylab_opt2 `ylab_opt2' `j' `"`lbl2'"'
    }

    /* x-axis upper limit — round up to nearest 5 */
    quietly summarize pct_contrib
    local pct_max = ceil(r(max) / 5) * 5
    if `pct_max' < 10 local pct_max = 10

    twoway                                                              ///
        (bar pct_contrib ypos                                           ///
            if focal==0 & pos_coef==1,                                  ///
            horizontal barwidth(0.60)                                   ///
            color(teal%65) lcolor(teal%90) lwidth(vthin))              ///
        (bar pct_contrib ypos                                           ///
            if focal==0 & pos_coef==0,                                  ///
            horizontal barwidth(0.60)                                   ///
            color(maroon%60) lcolor(maroon%90) lwidth(vthin))          ///
        (bar pct_contrib ypos                                           ///
            if focal==1,                                                 ///
            horizontal barwidth(0.70)                                   ///
            color(orange%80) lcolor(orange) lwidth(thin))              ///
        (scatter ypos pct_contrib,                                      ///
            ms(none)                                                     ///
            mlabel(pct_label) mlabposition(3)                           ///
            mlabsize(vsmall) mlabcolor(gs4)),                           ///
        ylabel(`ylab_opt2', angle(0) labsize(small) nogrid)            ///
        xlabel(0(10)`pct_max', labsize(small))                         ///
        xtitle("Share of Total Achievable Δ{it:`depvar'} (%)", size(small)) ///
        ytitle("")                                                      ///
        title("Relative Contribution: Share of Achievable Variation", size(medsmall)) ///
        subtitle("Each bar = variable's achievable Δŷ range as % of total;" ///
                 " annotation = % share and absolute Δŷ", size(vsmall)) ///
        note("Total achievable Δŷ (sum) = `=string(`total_range', "%8.3f")' units  |" ///
             "  Positive-effect IVs = teal; Negative-effect = maroon; Focal = orange", ///
             size(vsmall))                                              ///
        legend(order(1 "Positive effect" 2 "Negative effect"           ///
                     3 "`focusvar' (focal)")                            ///
               size(vsmall) rows(1))                                    ///
        scheme(s2color) name(rp_nomo2, replace)

    restore

    if "`saving'" != "" quietly graph save rp_nomo2 "`saving'_nomo2.gph", replace

    /* ------------------------------------------------------------------ */
    /*  STEP 11 — GRAPH 3: Unit-Effect Dot Chart                          */
    /*                                                                      */
    /*  Shows the coefficient (raw β) for each variable on a common scale  */
    /*  with a horizontal line at zero, plus whiskers showing the full-    */
    /*  range contribution as a CI-style visual.                           */
    /* ------------------------------------------------------------------ */
    preserve
    quietly drop _all
    quietly set obs `nreg'

    quietly generate str32  varname2      = ""
    quietly generate double coef2         = .
    quietly generate double contrib2      = .
    quietly generate double ci_lo         = .
    quietly generate double ci_hi         = .
    quietly generate int    focal2        = 0
    quietly generate int    pos2          = .

    forvalues k = 1/`nreg' {
        local clo2 = `coef_`k'' * (`lb_`k'' - `med_`k'')
        local chi2 = `coef_`k'' * (`ub_`k'' - `med_`k'')
        quietly replace varname2    = "`name_`k''"                 in `k'
        quietly replace coef2       = `coef_`k''                   in `k'
        quietly replace contrib2    = abs(`coef_`k'' * (`ub_`k'' - `lb_`k'')) in `k'
        quietly replace ci_lo       = min(`clo2', `chi2')          in `k'
        quietly replace ci_hi       = max(`clo2', `chi2')          in `k'
        quietly replace pos2        = (`coef_`k'' >= 0)            in `k'
        if "`name_`k''" == "`focusvar'" quietly replace focal2 = 1 in `k'
    }

    sort contrib2
    quietly generate int ypos2 = _n

    /* Per-unit coefficient labels */
    quietly generate str24 coef_lbl = "β=" + string(coef2, "%7.4f")

    local ylab_opt3 ""
    forvalues j = 1/`nreg' {
        local lbl3 = varname2[`j']
        local ylab_opt3 `ylab_opt3' `j' `"`lbl3'"'
    }

    quietly summarize ci_lo
    local x3lo = r(min)
    quietly summarize ci_hi
    local x3hi = r(max)
    local x3span = `x3hi' - `x3lo'
    local x3pad  = `x3span' * 0.20
    local g3_xlo = `x3lo' - `x3pad'
    local g3_xhi = `x3hi' + `x3pad'

    twoway                                                              ///
        (rspike ci_lo ci_hi ypos2 if focal2==0,                        ///
            horizontal lwidth(medthick) lcolor(gs10))                  ///
        (rspike ci_lo ci_hi ypos2 if focal2==1,                        ///
            horizontal lwidth(thick) lcolor(orange%80))                ///
        (scatter ypos2 coef2 if focal2==0 & pos2==1,                   ///
            ms(O) mcolor(teal) msize(medium))                          ///
        (scatter ypos2 coef2 if focal2==0 & pos2==0,                   ///
            ms(O) mcolor(maroon) msize(medium))                        ///
        (scatter ypos2 coef2 if focal2==1,                             ///
            ms(D) mcolor(orange) msize(medlarge))                      ///
        (scatter ypos2 coef2,                                           ///
            ms(none)                                                     ///
            mlabel(coef_lbl) mlabposition(12)                           ///
            mlabsize(tiny) mlabcolor(gs5)),                             ///
        xline(0, lcolor(black) lwidth(medium) lpattern(solid))         ///
        ylabel(`ylab_opt3', angle(0) labsize(small) nogrid)            ///
        xlabel(, labsize(small) format(%6.3f))                         ///
        xtitle("Coefficient (β): Units of Δ{it:`depvar'} per 1-unit Δ in IV", ///
               size(small))                                             ///
        ytitle("")                                                      ///
        xscale(range(`g3_xlo' `g3_xhi'))                               ///
        title("Unit-Effect Chart: β per 1-Unit Change in IV", size(medsmall)) ///
        subtitle("Diamonds/circles = β coefficient; whiskers = full-range contribution" ///
                 " [coef×(lb−med), coef×(ub−med)]", size(vsmall))    ///
        note("Sorted ascending by |total contribution range|  |  Focal IV ({it:`focusvar'}) in orange", ///
             size(vsmall))                                              ///
        legend(order(3 "Positive β" 4 "Negative β" 5 "`focusvar' (focal)")  ///
               size(vsmall) rows(1))                                    ///
        scheme(s2color) name(rp_nomo3, replace)

    restore

    if "`saving'" != "" quietly graph save rp_nomo3 "`saving'_nomo3.gph", replace

    /* ------------------------------------------------------------------ */
    /*  PRINT SUMMARY TABLE TO RESULTS WINDOW                              */
    /* ------------------------------------------------------------------ */
    if "`nodisplay'" == "" {
        di ""
        di as text "{hline 72}"
        di as text "  {bf:regproject nomo} — Variable Contribution Summary"
        di as text "{hline 72}"
        di as text "  {bf:Variable}" _col(20) "{bf:Coef}" _col(30) "{bf:lb}" ///
                   _col(40) "{bf:ub}" _col(50) "{bf:ΔŷRange}" _col(62) "{bf:Share %}"
        di as text "{hline 72}"

        preserve
        quietly drop _all
        quietly set obs `nreg'
        quietly generate str32 vn = ""
        quietly generate double cr = .
        forvalues k = 1/`nreg' {
            quietly replace vn = "`name_`k''" in `k'
            quietly replace cr = abs(`coef_`k'' * (`ub_`k'' - `lb_`k'')) in `k'
        }
        sort cr
        quietly generate int rnk = _n
        restore

        * Print in sorted order
        forvalues j = 1/`nreg' {

            /* We need to match the sorted order — rebuild from the sorted tmp */
            /* Actually, simplest: iterate over regressors and show directly  */
        }

        /* Print in original order — sorted display is a nice-to-have       */
        local kk = 0
        foreach v of local regressors {
            local ++kk
            local coef_k = `coef_`kk''
            local lb_k   = `lb_`kk''
            local ub_k   = `ub_`kk''
            local rng_k  = abs(`coef_k' * (`ub_k' - `lb_k'))
            local pct_k  = `rng_k' / `total_range' * 100

            if "`v'" == "`focusvar'" {
                di as result "  `v' {bf:←}" _col(20) %7.4f `coef_k' ///
                   _col(30) %8.3f `lb_k'  _col(40) %8.3f `ub_k'    ///
                   _col(50) %8.4f `rng_k' _col(62) %5.1f `pct_k' "%"
            }
            else {
                di as result "  `v'" _col(20) %7.4f `coef_k' ///
                   _col(30) %8.3f `lb_k'  _col(40) %8.3f `ub_k'  ///
                   _col(50) %8.4f `rng_k' _col(62) %5.1f `pct_k' "%"
            }
        }
        di as text "{hline 72}"
        di as text "  Total achievable Δŷ  : " as result %10.4f `total_range' as text " units"
        di as text "  Focal IV contribution : " as result %10.4f `focal_range' ///
                   as text " units (" as result %4.1f `focal_range'/`total_range'*100 as text "%)"
        di as text "{hline 72}"
        di as text "  Graphs: rp_nomo1 (nomogram)  rp_nomo2 (% contribution)  rp_nomo3 (unit-effect)"
        di as text "{hline 72}"
        di ""
    }

end
