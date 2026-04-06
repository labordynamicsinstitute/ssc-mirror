*! _regproject_pan.ado v1.0.2 — Panel data graphs for regproject
*! Author: Dr Noman Arshed, Sunway University

program define _regproject_pan
    version 14
    
    syntax varname [,                   ///
        regressors(string)              ///
        nreg(integer 0)                 ///
        focuspos(integer 0)             ///
        depvar(string)                  ///
        cons(real 0)                    ///
        panelvar(string)                ///
        timevar(string)                 ///
        latest_t(real 0)                ///
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
    /*  SAVE ALL ORIGINAL COEFFICIENTS FIRST                               */
    /*  predict does not overwrite e(b), but saving upfront is consistent  */
    /* ------------------------------------------------------------------ */
    local kk = 0
    foreach v of local regressors {
        local ++kk
        local orig_coef_`kk' = _b[`v']
    }
    local orig_cons  = `cons'
    local coef_focus = `orig_coef_`focuspos''
    
    /* ------------------------------------------------------------------ */
    /*  REFERENCE LINE VALUES (median base, focal IV varies)               */
    /* ------------------------------------------------------------------ */
    local xb_med_base = `orig_cons'
    local kk = 0
    foreach v of local regressors {
        local ++kk
        if `kk' != `focuspos' {
            local xb_med_base = `xb_med_base' + `orig_coef_`kk'' * `med_vec'[1, `kk']
        }
    }
    
    local focus_lb = `bounds_lower'[1, `focuspos']
    local focus_ub = `bounds_upper'[1, `focuspos']
    
    quietly summarize `focusvar', meanonly
    local focus_dmin = r(min)
    local focus_dmax = r(max)
    
    local ref_maxobs = `xb_med_base' + `coef_focus' * `focus_dmax'
    local ref_minobs = `xb_med_base' + `coef_focus' * `focus_dmin'
    local ref_ubuser = `xb_med_base' + `coef_focus' * `focus_ub'
    local ref_lbuser = `xb_med_base' + `coef_focus' * `focus_lb'
    
    /* ------------------------------------------------------------------ */
    /*  DETECT STRING LABEL VARIABLE FOR ENTITY NAMES                      */
    /* ------------------------------------------------------------------ */
    local entlabel ""
    foreach v of varlist _all {
        local vtype : type `v'
        if substr("`vtype'", 1, 3) == "str" {
            local entlabel `v'
            continue, break
        }
    }
    
    /* flag: is_latest = 1 for each entity's last observed period */
    tempvar is_latest
    quietly bysort `panelvar' (`timevar'): generate `is_latest' = (_n == _N)
    
    /* ------------------------------------------------------------------ */
    /*  HELPER PROGRAM: clipped_yline                                      */
    /*  returns yline option only if val strictly inside [vis_lo, vis_hi]  */
    /* ------------------------------------------------------------------ */
    /* inline: used as local conditional assignment below each graph       */
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 1 — Dot chart at latest period, sorted by focal IV           */
    /* ------------------------------------------------------------------ */
    preserve
    quietly keep if `is_latest' == 1
    quietly predict _yhat_pan, xb
    sort `focusvar'
    quietly generate _xpos1 = _n
    local n_ent = _N
    
    /* visible y range — absolute padding, correct for negative values */
    quietly summarize _yhat_pan, meanonly
    local g1_raw_lo = r(min)
    local g1_raw_hi = r(max)
    local g1_pad    = (`g1_raw_hi' - `g1_raw_lo') * 0.08
    if `g1_pad' == 0 local g1_pad = 0.5   /* guard: constant yhat */
    local g1_vis_lo = `g1_raw_lo' - `g1_pad'
    local g1_vis_hi = `g1_raw_hi' + `g1_pad'
    
    /* reference lines — strictly inside visible frame */
    local p1_rl_max ""
    local p1_rl_min ""
    local p1_rl_ub  ""
    local p1_rl_lb  ""
    if `ref_maxobs' > `g1_vis_lo' & `ref_maxobs' < `g1_vis_hi' {
        local p1_rl_max "yline(`ref_maxobs', lcolor(dkgreen) lpattern(solid) lwidth(medium))"
    }
    if `ref_minobs' > `g1_vis_lo' & `ref_minobs' < `g1_vis_hi' {
        local p1_rl_min "yline(`ref_minobs', lcolor(maroon) lpattern(solid) lwidth(medium))"
    }
    if `ref_ubuser' > `g1_vis_lo' & `ref_ubuser' < `g1_vis_hi' {
        local p1_rl_ub "yline(`ref_ubuser', lcolor(dkgreen) lpattern(dash) lwidth(medium))"
    }
    if `ref_lbuser' > `g1_vis_lo' & `ref_lbuser' < `g1_vis_hi' {
        local p1_rl_lb "yline(`ref_lbuser', lcolor(maroon) lpattern(dash) lwidth(medium))"
    }
    local p1_ymax_line ""
    local p1_ymin_line ""
    if `has_ymax' {
        if `ymax_val' > `g1_vis_lo' & `ymax_val' < `g1_vis_hi' {
            local p1_ymax_line "yline(`ymax_val', lcolor(red) lpattern(dash) lwidth(medthin))"
        }
    }
    if `has_ymin' {
        if `ymin_val' > `g1_vis_lo' & `ymin_val' < `g1_vis_hi' {
            local p1_ymin_line "yline(`ymin_val', lcolor(orange) lpattern(dash) lwidth(medthin))"
        }
    }
    
    /* x-axis labels: entity names if string var exists, else panelvar values */
    local g1_xlab ""
    if "`entlabel'" != "" {
        forvalues i = 1/`n_ent' {
            local lbl = `entlabel'[`i']
            local g1_xlab `g1_xlab' `i' "`lbl'"
        }
        local g1_xlabel "xlabel(`g1_xlab', angle(45) labsize(vsmall))"
    }
    else {
        local g1_xlabel "xlabel(1(1)`n_ent', angle(45) labsize(vsmall))"
    }
    
    twoway (scatter _yhat_pan _xpos1,                                    ///
                msymbol(O) msize(medlarge) mcolor(navy)),                 ///
        `p1_rl_max' `p1_rl_min' `p1_rl_ub' `p1_rl_lb'                   ///
        `p1_ymax_line' `p1_ymin_line'                                    ///
        `g1_xlabel'                                                       ///
        xtitle("Entity (sorted ascending by `focusvar', t=`latest_t')")  ///
        ytitle("Predicted `depvar'")                                      ///
        title("Panel Projection at Latest Period (t=`latest_t')", size(medsmall)) ///
        subtitle("Dots = entity ŷ at latest period; Lines = benchmark projections", size(vsmall)) ///
        legend(order(2 "Max IV" 3 "Min IV" 4 "User upper IV" 5 "User lower IV") ///
               size(vsmall) rows(1))                                      ///
        scheme(s2color) name(rp_pan1, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_pan1 "`saving'_1.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 2 — Spaghetti: entity yhat trajectories over time            */
    /* ------------------------------------------------------------------ */
    preserve
    quietly predict _yhat_sp, xb
    quietly bysort `timevar': egen _med_traj = median(_yhat_sp)
    
    quietly levelsof `panelvar', local(entity_list)
    local nentities = wordcount(`"`entity_list'"')
    
    /* build one line plot per entity */
    local sp_plots ""
    foreach ent of local entity_list {
        local sp_plots `sp_plots' ///
            (line _yhat_sp `timevar' if `panelvar' == `ent', ///
             lcolor(navy%25) lwidth(thin))
    }
    
    /* DV limit lines for spaghetti — compute visible range first */
    quietly summarize _yhat_sp, meanonly
    local g2_vis_lo = r(min) - (r(max) - r(min)) * 0.08
    local g2_vis_hi = r(max) + (r(max) - r(min)) * 0.08
    local sp_ymax_line ""
    local sp_ymin_line ""
    if `has_ymax' {
        if `ymax_val' > `g2_vis_lo' & `ymax_val' < `g2_vis_hi' {
            local sp_ymax_line "yline(`ymax_val', lcolor(red) lpattern(dash) lwidth(medthin))"
        }
    }
    if `has_ymin' {
        if `ymin_val' > `g2_vis_lo' & `ymin_val' < `g2_vis_hi' {
            local sp_ymin_line "yline(`ymin_val', lcolor(orange) lpattern(dash) lwidth(medthin))"
        }
    }
    
    twoway `sp_plots'                                                     ///
           (line _med_traj `timevar',                                     ///
                sort lcolor(red) lwidth(thick) lpattern(solid)),          ///
        `sp_ymax_line' `sp_ymin_line'                                    ///
        xtitle("Time Period (`timevar')")                                  ///
        ytitle("Predicted `depvar'")                                      ///
        title("Entity Trajectories Over Time", size(medsmall))            ///
        subtitle("Light blue = individual entities; Red = median trajectory", size(vsmall)) ///
        legend(order(`=`nentities'+1' "Median") size(vsmall) rows(1))    ///
        scheme(s2color) name(rp_pan2, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_pan2 "`saving'_2.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 3 — Delta IV vs Delta yhat scatter per entity                */
    /* ------------------------------------------------------------------ */
    preserve
    quietly predict _yhat_full, xb
    
    quietly bysort `panelvar' (`timevar'): generate _yhat_first = _yhat_full[1]
    quietly bysort `panelvar' (`timevar'): generate _yhat_last  = _yhat_full[_N]
    quietly bysort `panelvar' (`timevar'): generate _iv_first   = `focusvar'[1]
    quietly bysort `panelvar' (`timevar'): generate _iv_last    = `focusvar'[_N]
    quietly bysort `panelvar' (`timevar'): keep if _n == _N
    
    quietly generate _delta_iv   = _iv_last   - _iv_first
    quietly generate _delta_yhat = _yhat_last - _yhat_first
    
    quietly summarize _delta_iv, meanonly
    local dmin = r(min)
    local dmax = r(max)
    /* extend function range slightly beyond data */
    local fpad = (`dmax' - `dmin') * 0.1
    local flo  = `dmin' - `fpad'
    local fhi  = `dmax' + `fpad'
    
    local coef_str = string(`coef_focus', "%6.3f")
    
    if "`entlabel'" != "" {
        twoway (scatter _delta_yhat _delta_iv,                            ///
                    mlabel(`entlabel') mlabsize(vsmall)                   ///
                    msymbol(O) mcolor(navy%70) msize(medium))             ///
               (function y = `coef_focus' * x,                           ///
                    range(`flo' `fhi')                                    ///
                    lcolor(red) lpattern(dash) lwidth(medium)),           ///
            xtitle("Δ `focusvar' (last − first period)")                  ///
            ytitle("Δ Predicted `depvar'")                                ///
            title("IV Change vs Outcome Change by Entity", size(medsmall)) ///
            subtitle("Dashed = theoretical slope (β = `coef_str')", size(vsmall)) ///
            legend(order(2 "β = `coef_str'") size(vsmall))               ///
            scheme(s2color) name(rp_pan3, replace)
    }
    else {
        twoway (scatter _delta_yhat _delta_iv,                            ///
                    msymbol(O) mcolor(navy%70) msize(medium))             ///
               (function y = `coef_focus' * x,                           ///
                    range(`flo' `fhi')                                    ///
                    lcolor(red) lpattern(dash) lwidth(medium)),           ///
            xtitle("Δ `focusvar' (last − first period)")                  ///
            ytitle("Δ Predicted `depvar'")                                ///
            title("IV Change vs Outcome Change by Entity", size(medsmall)) ///
            subtitle("Dashed = theoretical slope (β = `coef_str')", size(vsmall)) ///
            legend(order(2 "β = `coef_str'") size(vsmall))               ///
            scheme(s2color) name(rp_pan3, replace)
    }
    
    restore
    if "`saving'" != "" quietly graph save rp_pan3 "`saving'_3.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 4 — Heat map: entities × time periods, color = yhat          */
    /* ------------------------------------------------------------------ */
    quietly predict _yhat_heat, xb
    
    capture which heatplot
    if _rc == 0 {
        /* heatplot: zvar yvar xvar — entities on y-axis, time on x-axis */
        heatplot _yhat_heat `panelvar' `timevar',                         ///
            colors(RdBu, reverse) cuts(10)                                ///
            xtitle("Time (`timevar')")                                    ///
            ytitle("Entity (`panelvar')")                                 ///
            title("Predicted `depvar' — Heat Map", size(medsmall))        ///
            subtitle("RdBu: blue = low, red = high `depvar'", size(vsmall)) ///
            name(rp_pan4, replace)
    }
    else {
        /* fallback: bubble scatter sized by predicted value */
        quietly summarize _yhat_heat, meanonly
        local hmin = r(min)
        local hmax = r(max)
        quietly generate _heat_norm = 10 * (_yhat_heat - `hmin') / ///
                                      max(`hmax' - `hmin', 0.001) + 2
        
        twoway scatter `panelvar' `timevar',                              ///
            msymbol(S) msize(_heat_norm) mcolor(navy%60)                  ///
            xtitle("Time (`timevar')")                                    ///
            ytitle("Entity (`panelvar')")                                  ///
            title("Predicted `depvar' — Period × Entity", size(medsmall)) ///
            subtitle("Dot size ∝ predicted `depvar'; install heatplot (SSC) for full heat map", ///
                     size(vsmall))                                         ///
            scheme(s2color) name(rp_pan4, replace)
        
        quietly drop _heat_norm
    }
    
    quietly drop _yhat_heat
    if "`saving'" != "" quietly graph save rp_pan4 "`saving'_4.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  COMBINE — 2×2 grid                                                 */
    /* ------------------------------------------------------------------ */
    if "`combine'" != "" {
        graph combine rp_pan1 rp_pan2 rp_pan3 rp_pan4,                   ///
            cols(2) iscale(0.85)                                           ///
            title("regproject — Panel Analysis: `depvar' ~ `focusvar'",   ///
                  size(small))                                             ///
            scheme(s2color) name(rp_pan_combined, replace)
        if "`saving'" != "" quietly graph save rp_pan_combined "`saving'_combined.gph", replace
    }
    
    if "`nodisplay'" == "" {
        di as text "  Panel graphs generated: rp_pan1  rp_pan2  rp_pan3  rp_pan4"
        di as text "  Graph 1: latest-period dots   Graph 2: trajectories"
        di as text "  Graph 3: delta IV vs delta ŷ  Graph 4: heat map"
    }
    
end
