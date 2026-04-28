*! _regproject_cs.ado — Cross-section graphs for regproject
*! Author: Dr Noman Arshed, Sunway University

program define _regproject_cs
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
        COMBINE                         ///
        NODisplay                       ///
    ]
    
    local focusvar `varlist'
    
    /* ------------------------------------------------------------------ */
    /*  HELPER MACRO: compute yhat for a given observation using e(b)      */
    /*  We use _regproject_yhat which fills a tempvar                      */
    /* ------------------------------------------------------------------ */
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 1 — Entity bar chart                                         */
    /*  Bar height = yhat_i using entity's own values                      */
    /*  Sorted ascending by focal IV value                                 */
    /* ------------------------------------------------------------------ */
    
    tempvar yhat_cs sort_iv obs_id
    quietly predict `yhat_cs', xb
    quietly generate `sort_iv' = `focusvar'
    quietly generate `obs_id'  = _n
    
    /* entity labels — try to find a string id variable */
    local idlabel ""
    foreach v of varlist _all {
        local vtype : type `v'
        if substr("`vtype'", 1, 3) == "str" {
            local idlabel `v'
            continue, break
        }
    }
    
    /* sort by focal IV */
    tempvar rank_iv
    quietly egen `rank_iv' = rank(`sort_iv'), unique
    
    /* compute 4 reference lines at median base */
    /* line 1: predicted y at max observed IV */
    /* line 2: predicted y at min observed IV */
    /* line 3: predicted y at user upper IV bound (=line 1 if no user input) */
    /* line 4: predicted y at user lower IV bound (=line 2 if no user input) */
    
    local focus_lb = `bounds_lower'[1, `focuspos']
    local focus_ub = `bounds_upper'[1, `focuspos']
    
    quietly summarize `focusvar', meanonly
    local focus_dmin = r(min)
    local focus_dmax = r(max)
    
    /* build xb at median for all non-focal regressors */
    local xb_med_base = `cons'
    local kk = 0
    foreach v of local regressors {
        local ++kk
        if `kk' != `focuspos' {
            local med_k = `med_vec'[1, `kk']
            local coef_k = _b[`v']
            local xb_med_base = `xb_med_base' + `coef_k' * `med_k'
        }
    }
    local coef_focus = _b[`focusvar']
    
    local ref_maxobs = `xb_med_base' + `coef_focus' * `focus_dmax'
    local ref_minobs = `xb_med_base' + `coef_focus' * `focus_dmin'
    local ref_ubuser = `xb_med_base' + `coef_focus' * `focus_ub'
    local ref_lbuser = `xb_med_base' + `coef_focus' * `focus_lb'
    
    /* y-axis display range — used to clip reference lines */
    quietly summarize `yhat_cs', meanonly
    local yhat_gmin = r(min)
    local yhat_gmax = r(max)
    
    /* extend range to include any ref lines that are close */
    local all_refs "`ref_maxobs' `ref_minobs' `ref_ubuser' `ref_lbuser'"
    foreach rv of local all_refs {
        if `rv' > `yhat_gmax' & `rv' < `yhat_gmax' * 1.3 local yhat_gmax = `rv'
        if `rv' < `yhat_gmin' & `rv' > `yhat_gmin' * 1.3 local yhat_gmin = `rv'
    }
    local ypad = (`yhat_gmax' - `yhat_gmin') * 0.08
    local g1_ylo = `yhat_gmin' - `ypad'
    local g1_yhi = `yhat_gmax' + `ypad'
    if `g1_ylo' > 0 local g1_ylo = 0
    
    /* reference lines — only if within visible frame */
    local rl_maxobs ""
    local rl_minobs ""
    local rl_ubuser ""
    local rl_lbuser ""
    if `ref_maxobs' >= `g1_ylo' & `ref_maxobs' <= `g1_yhi' {
        local rl_maxobs "yline(`ref_maxobs', lcolor(dkgreen) lpattern(solid) lwidth(medium))"
    }
    if `ref_minobs' >= `g1_ylo' & `ref_minobs' <= `g1_yhi' {
        local rl_minobs "yline(`ref_minobs', lcolor(maroon) lpattern(solid) lwidth(medium))"
    }
    if `ref_ubuser' >= `g1_ylo' & `ref_ubuser' <= `g1_yhi' {
        local rl_ubuser "yline(`ref_ubuser', lcolor(dkgreen) lpattern(dash) lwidth(medium))"
    }
    if `ref_lbuser' >= `g1_ylo' & `ref_lbuser' <= `g1_yhi' {
        local rl_lbuser "yline(`ref_lbuser', lcolor(maroon) lpattern(dash) lwidth(medium))"
    }
    
    /* DV limit shading lines — only if within visible frame */
    local shade_upper ""
    local shade_lower ""
    if `has_ymax' {
        if `ymax_val' >= `g1_ylo' & `ymax_val' <= `g1_yhi' {
            local shade_upper "yline(`ymax_val', lcolor(red) lpattern(dash) lwidth(medthin))"
        }
    }
    if `has_ymin' {
        if `ymin_val' >= `g1_ylo' & `ymin_val' <= `g1_yhi' {
            local shade_lower "yline(`ymin_val', lcolor(orange) lpattern(dash) lwidth(medthin))"
        }
    }
    
    /* build x-axis labels */
    local n = _N
    local xlab_str ""
    forvalues i = 1/`n' {
        if "`idlabel'" != "" {
            local lbl = `idlabel'[`i']
        }
        else {
            local lbl = `i'
        }
        local xlab_str `xlab_str' `i' "`lbl'"
    }
    
    /* DV limit note — only include each limit when it falls inside the visible frame */
    local g1_note_parts ""
    if `has_ymin' {
        if `ymin_val' >= `g1_ylo' & `ymin_val' <= `g1_yhi' {
            local g1_note_parts "`g1_note_parts'DV lower limit = `=string(`ymin_val', "%9.3g")'  "
        }
    }
    if `has_ymax' {
        if `ymax_val' >= `g1_ylo' & `ymax_val' <= `g1_yhi' {
            local g1_note_parts "`g1_note_parts'DV upper limit = `=string(`ymax_val', "%9.3g")'"
        }
    }
    local g1_note_opt ""
    if `"`g1_note_parts'"' != "" {
        local g1_note_opt `"note("`g1_note_parts'", size(vsmall))"'
    }

    /* sort dataset temporarily for graph */
    preserve
    sort `sort_iv'
    
    quietly generate _xpos = _n
    
    twoway bar `yhat_cs' _xpos,                                    ///
        barwidth(0.7) color(navy%70)                               ///
        `rl_maxobs' `rl_minobs' `rl_ubuser' `rl_lbuser'           ///
        `shade_upper' `shade_lower'                                ///
        xlabel(1(1)`n', valuelabel angle(45) labsize(vsmall))      ///
        xtitle("`focusvar' (sorted ascending)")                    ///
        ytitle("Predicted `depvar'")                               ///
        title("Projected Effect: `depvar' by Entity", size(medsmall)) ///
        subtitle("Bars = entity ŷ using own values; Lines = benchmark projections") ///
        `g1_note_opt'                                              ///
        legend(order(2 "Max IV ref" 3 "Min IV ref" 4 "User upper IV" 5 "User lower IV") ///
               size(vsmall) rows(1))                               ///
        scheme(s2color) name(rp_cs1, replace)
    
    restore
    
    if "`saving'" != "" quietly graph save rp_cs1 "`saving'_1.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 2 — Sensitivity ranking (all IVs, min-to-max yhat range)     */
    /* ------------------------------------------------------------------ */
    
    tempname sens_range sens_names
    
    /* compute range for each regressor */
    local kk = 0
    local sens_vals ""
    local sens_labs ""
    
    foreach v of local regressors {
        local ++kk
        local lb_k   = `bounds_lower'[1, `kk']
        local ub_k   = `bounds_upper'[1, `kk']
        local coef_k = _b[`v']
        local rng_k  = abs(`coef_k' * (`ub_k' - `lb_k'))
        local sens_vals `sens_vals' `rng_k'
        local sens_labs `sens_labs' "`v'"
    }
    
    /* build temp dataset for sensitivity bar */
    preserve
    quietly drop _all
    local nsens = wordcount("`sens_vals'")
    quietly set obs `nsens'
    quietly generate sens_var = ""
    quietly generate sens_val = .
    quietly generate sens_focal = 0
    
    forvalues j = 1/`nsens' {
        local sv : word `j' of `sens_vals'
        local sl : word `j' of `sens_labs'
        quietly replace sens_var   = "`sl'" in `j'
        quietly replace sens_val   = `sv'   in `j'
        if "`sl'" == "`focusvar'" quietly replace sens_focal = 1 in `j'
    }
    
    sort sens_val
    quietly generate _srank = _n
    
    /* build explicit ylabel from variable names in sorted order */
    local g2_ylab ""
    forvalues j = 1/`nsens' {
        local lbl_j = sens_var[`j']
        local g2_ylab `g2_ylab' `j' `"`lbl_j'"'
    }
    
    twoway (bar sens_val _srank if sens_focal == 0,                ///
                barwidth(0.6) color(navy%60) horizontal)           ///
           (bar sens_val _srank if sens_focal == 1,                ///
                barwidth(0.6) color(orange%80) horizontal),        ///
        ylabel(`g2_ylab', angle(0) labsize(small))                 ///
        ytitle("")                                                  ///
        xtitle("Range of Predicted `depvar' (min-to-max)")         ///
        title("Sensitivity Ranking of Regressors", size(medsmall)) ///
        subtitle("Length = |coef × (upper - lower)|; orange = focal IV") ///
        legend(order(1 "Other IVs" 2 "`focusvar' (focal)") size(vsmall)) ///
        scheme(s2color) name(rp_cs2, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_cs2 "`saving'_2.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 3 — Gap to boundary                                          */
    /* ------------------------------------------------------------------ */
    
    if `has_ymax' | `has_ymin' {
        
        preserve
        quietly predict _yhat_gap, xb
        sort `focusvar'
        quietly generate _xpos3 = _n
        
        quietly generate _gap_upper = .
        quietly generate _gap_lower = .
        
        if `has_ymax' quietly replace _gap_upper = `ymax_val' - _yhat_gap
        if `has_ymin' quietly replace _gap_lower = _yhat_gap  - `ymin_val'
        
        /* diverging bar: positive = headroom, negative = breach */
        local gap_var ""
        local gap_title ""
        if `has_ymax' {
            local gap_var  "_gap_upper"
            local gap_title "Gap to Upper Bound (`ymax_val')"
        }
        else {
            local gap_var  "_gap_lower"
            local gap_title "Gap to Lower Bound (`ymin_val')"
        }
        
        quietly generate _gap_color = (`gap_var' < 0)
        
        /* choose boundary label for subtitle */
        if `has_ymax' & `has_ymin' {
            local g3_sub "How far each entity's projected `depvar' sits from the user-specified DV limits"
        }
        else if `has_ymax' {
            local g3_sub "How far each entity's projected `depvar' sits from the upper DV limit (`ymax_val')"
        }
        else {
            local g3_sub "How far each entity's projected `depvar' sits from the lower DV limit (`ymin_val')"
        }

        twoway (bar `gap_var' _xpos3 if _gap_color == 0, barwidth(0.7) color(teal%70)) ///
               (bar `gap_var' _xpos3 if _gap_color == 1, barwidth(0.7) color(red%70)), ///
            yline(0, lcolor(black) lwidth(thin))                   ///
            xlabel(1(1)`n', valuelabel angle(45) labsize(vsmall))  ///
            xtitle("`focusvar' (sorted ascending)")                ///
            ytitle("Gap (DV units)")                               ///
            title("`gap_title'", size(medsmall))                   ///
            subtitle("`g3_sub'", size(vsmall))                     ///
            note("Teal bars (positive) = headroom remaining to the limit;  Red bars (negative) = limit already breached", ///
                 size(vsmall))                                      ///
            legend(order(1 "Within bounds" 2 "Limit breached") size(vsmall)) ///
            scheme(s2color) name(rp_cs3, replace)
        
        restore
        if "`saving'" != "" quietly graph save rp_cs3 "`saving'_3.gph", replace
    }
    else {
        di as text "  Note: Graph 3 (gap-to-boundary) skipped — ymin/ymax not supplied."
    }
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 4 — Counterfactual: actual yhat vs median-IV yhat            */
    /* ------------------------------------------------------------------ */
    
    preserve
    quietly predict _yhat_actual, xb
    
    /* counterfactual: replace focal IV with median */
    quietly summarize `focusvar', detail
    local foc_med = r(p50)
    local coef_foc = _b[`focusvar']
    
    quietly generate _yhat_cf = _yhat_actual - `coef_foc' * `focusvar' + `coef_foc' * `foc_med'
    
    sort `focusvar'
    quietly generate _xpos4 = _n
    
    twoway (bar _yhat_actual _xpos4, barwidth(0.35) color(navy%70) base(0))   ///
           (bar _yhat_cf    _xpos4, barwidth(0.35) color(maroon%60) base(0)), ///
        xlabel(1(1)`n', valuelabel angle(45) labsize(vsmall))                  ///
        xtitle("`focusvar' (sorted ascending)")                                ///
        ytitle("Predicted `depvar'")                                           ///
        title("Actual vs Counterfactual Projection", size(medsmall))           ///
        subtitle("Counterfactual: focal IV (`focusvar') replaced with its median") ///
        legend(order(1 "Actual ŷ" 2 "Counterfactual ŷ (median IV)") size(vsmall)) ///
        scheme(s2color) name(rp_cs4, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_cs4 "`saving'_4.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  COMBINE                                                             */
    /* ------------------------------------------------------------------ */
    if "`combine'" != "" {
        capture graph combine rp_cs1 rp_cs2 rp_cs3 rp_cs4, ///
            cols(2) title("regproject — Cross-Section Analysis: `depvar' ~ `focusvar'") ///
            scheme(s2color) name(rp_cs_combined, replace)
        if _rc {
            graph combine rp_cs1 rp_cs2 rp_cs4, ///
                cols(2) title("regproject — Cross-Section Analysis: `depvar' ~ `focusvar'") ///
                scheme(s2color) name(rp_cs_combined, replace)
        }
        if "`saving'" != "" quietly graph save rp_cs_combined "`saving'_combined.gph", replace
    }
    
    if "`nodisplay'" == "" {
        di as text "  Cross-section graphs generated: rp_cs1 rp_cs2 rp_cs3 rp_cs4"
    }
    
end
