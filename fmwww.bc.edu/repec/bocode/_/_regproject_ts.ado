*! _regproject_ts.ado v1.0.2 — Time series graphs for regproject
*! Author: Dr Noman Arshed, Sunway University

program define _regproject_ts
    version 14
    
    syntax varname [,                   ///
        regressors(string)              ///
        nreg(integer 0)                 ///
        focuspos(integer 0)             ///
        depvar(string)                  ///
        cons(real 0)                    ///
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
    /*  Must happen before ANY auxiliary regress call overwrites e(b)      */
    /* ------------------------------------------------------------------ */
    local kk = 0
    foreach v of local regressors {
        local ++kk
        local orig_coef_`kk' = _b[`v']
    }
    local orig_cons  = `cons'
    local coef_focus = `orig_coef_`focuspos''
    
    local focus_lb = `bounds_lower'[1, `focuspos']
    local focus_ub = `bounds_upper'[1, `focuspos']
    
    /* ------------------------------------------------------------------ */
    /*  BASE xb: all non-focal covariates at their medians                 */
    /* ------------------------------------------------------------------ */
    local xb_med_base = `orig_cons'
    local kk = 0
    foreach v of local regressors {
        local ++kk
        if `kk' != `focuspos' {
            local xb_med_base = `xb_med_base' + `orig_coef_`kk'' * `med_vec'[1, `kk']
        }
    }
    
    /* latest observed IV value */
    local latest_t_val = `latest_t'
    quietly summarize `focusvar' if `timevar' == `latest_t_val', meanonly
    local iv_latest   = r(mean)
    local yhat_latest = `xb_med_base' + `coef_focus' * `iv_latest'
    
    local se_focus = sqrt(e(V)[`focuspos', `focuspos'])
    
    /* ------------------------------------------------------------------ */
    /*  HELPER MACRO: yline option — returns empty string if val           */
    /*  is strictly outside the visible axis range [vis_lo, vis_hi]       */
    /* ------------------------------------------------------------------ */
    /* Called as: `_rp_clip_yline val vis_lo vis_hi color pattern'        */
    /* Sets local `_clip_result' to yline(...) or ""                      */
    
    /* ------------------------------------------------------------------ */
    /*  TREND SLOPES — auxiliary regressions (safe: coefs already saved)  */
    /* ------------------------------------------------------------------ */
    quietly regress `focusvar' `timevar'
    local trend_focus = _b[`timevar']
    
    local kk = 0
    foreach v of local regressors {
        local ++kk
        quietly regress `v' `timevar'
        local trend_`kk' = _b[`timevar']
    }
    
    /* latest values of all regressors */
    local kk = 0
    foreach v of local regressors {
        local ++kk
        quietly summarize `v' if `timevar' == `latest_t_val', meanonly
        local latest_`kk' = r(mean)
    }
    
    /* ------------------------------------------------------------------ */
    /*  SHARED HELPER: compute visible y range with absolute padding       */
    /*  Absolute padding avoids wrong direction when values are negative   */
    /* ------------------------------------------------------------------ */
    /* Usage after summarize: compute vis_lo/vis_hi from r(min)/r(max)    */
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 1 — Static line sweep                                        */
    /* ------------------------------------------------------------------ */
    local n_sweep = 100
    local iv_step = (`focus_ub' - `focus_lb') / (`n_sweep' - 1)
    
    preserve
    quietly drop _all
    quietly set obs `n_sweep'
    quietly generate _iv_sweep = `focus_lb' + (_n - 1) * `iv_step'
    quietly generate _yhat_sw  = `xb_med_base' + `coef_focus' * _iv_sweep
    quietly generate _yhat_hi  = _yhat_sw + 1.96 * `se_focus' * abs(_iv_sweep - `iv_latest')
    quietly generate _yhat_lo  = _yhat_sw - 1.96 * `se_focus' * abs(_iv_sweep - `iv_latest')
    
    /* visible y range: absolute padding, correct for negative values */
    quietly summarize _yhat_hi, meanonly
    local g1_raw_hi = r(max)
    quietly summarize _yhat_lo, meanonly
    local g1_raw_lo = r(min)
    local g1_raw_hi = max(`g1_raw_hi', `yhat_latest')
    local g1_raw_lo = min(`g1_raw_lo', `yhat_latest')
    local g1_pad    = (`g1_raw_hi' - `g1_raw_lo') * 0.08
    local g1_vis_lo = `g1_raw_lo' - `g1_pad'
    local g1_vis_hi = `g1_raw_hi' + `g1_pad'
    
    /* DV limit lines — only drawn when strictly inside visible range */
    local g1_upper ""
    local g1_lower ""
    if `has_ymax' {
        if `ymax_val' > `g1_vis_lo' & `ymax_val' < `g1_vis_hi' {
            local g1_upper "yline(`ymax_val', lcolor(red) lpattern(dash) lwidth(medium))"
        }
    }
    if `has_ymin' {
        if `ymin_val' > `g1_vis_lo' & `ymin_val' < `g1_vis_hi' {
            local g1_lower "yline(`ymin_val', lcolor(orange) lpattern(dash) lwidth(medium))"
        }
    }
    
    twoway (rarea _yhat_hi _yhat_lo _iv_sweep, color(navy%20))           ///
           (line  _yhat_sw            _iv_sweep, lcolor(navy) lwidth(medium)) ///
           (scatteri `yhat_latest' `iv_latest',                           ///
                msymbol(D) mcolor(red) msize(medium)),                    ///
        `g1_upper' `g1_lower'                                             ///
        xline(`iv_latest', lcolor(red) lpattern(dot) lwidth(thin))       ///
        xtitle("`focusvar'")                                              ///
        ytitle("Predicted `depvar'")                                      ///
        title("Static Projection Sweep", size(medsmall))                  ///
        subtitle("CI ribbon = ±1.96×SE; Red diamond = latest observed", size(vsmall)) ///
        legend(order(2 "Predicted `depvar'" 1 "95% CI" 3 "Latest (`=string(`iv_latest', "%6.2f")')") ///
               size(vsmall) rows(1))                                      ///
        scheme(s2color) name(rp_ts1, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_ts1 "`saving'_1.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 2 — Forward projection: IV trended, others at median         */
    /* ------------------------------------------------------------------ */
    local horizon = 25
    
    preserve
    quietly drop _all
    quietly set obs `horizon'
    quietly generate _period  = _n
    quietly generate _iv_proj = `iv_latest' + (_n - 1) * `trend_focus'
    quietly generate _yhat_p2 = `xb_med_base' + `coef_focus' * _iv_proj
    
    /* crossing detection */
    local cross_upper_p2 = .
    local cross_lower_p2 = .
    forvalues p = 1/`horizon' {
        local yhp = `xb_med_base' + `coef_focus' * (`iv_latest' + (`p'-1) * `trend_focus')
        if `has_ymax' & `cross_upper_p2' == . & `yhp' >= `ymax_val' local cross_upper_p2 = `p'
        if `has_ymin' & `cross_lower_p2' == . & `yhp' <= `ymin_val' local cross_lower_p2 = `p'
    }
    
    /* visible range — absolute padding */
    quietly summarize _yhat_p2, meanonly
    local g2_raw_lo = r(min)
    local g2_raw_hi = r(max)
    if `has_ymax' & `ymax_val' > `g2_raw_lo' & `ymax_val' < `g2_raw_hi' * 1.15 {
        local g2_raw_hi = max(`g2_raw_hi', `ymax_val')
    }
    if `has_ymin' & `ymin_val' < `g2_raw_hi' & `ymin_val' > `g2_raw_lo' * 1.15 {
        local g2_raw_lo = min(`g2_raw_lo', `ymin_val')
    }
    local g2_pad    = (`g2_raw_hi' - `g2_raw_lo') * 0.08
    local g2_vis_lo = `g2_raw_lo' - `g2_pad'
    local g2_vis_hi = `g2_raw_hi' + `g2_pad'
    
    local g2_upper ""
    local g2_lower ""
    if `has_ymax' {
        if `ymax_val' > `g2_vis_lo' & `ymax_val' < `g2_vis_hi' {
            local g2_upper "yline(`ymax_val', lcolor(red) lpattern(dash) lwidth(medium))"
        }
    }
    if `has_ymin' {
        if `ymin_val' > `g2_vis_lo' & `ymin_val' < `g2_vis_hi' {
            local g2_lower "yline(`ymin_val', lcolor(orange) lpattern(dash) lwidth(medium))"
        }
    }
    
    /* crossing annotation */
    local cross_note2 ""
    if `has_ymax' {
        if `cross_upper_p2' != . local cross_note2 "Upper limit at period +`cross_upper_p2'"
        else                      local cross_note2 "Upper limit not reached within `horizon' periods"
    }
    if `has_ymin' {
        local lo_txt = cond(`cross_lower_p2' != ., "Lower limit at +`cross_lower_p2'", "Lower limit not reached")
        if "`cross_note2'" != "" local cross_note2 "`cross_note2'  |  `lo_txt'"
        else                      local cross_note2 "`lo_txt'"
    }
    if "`cross_note2'" == "" local cross_note2 "No DV limits specified"
    
    /* note text: always show IV trend rate; append DV limits if within visible range */
    local g2_note_txt "IV (`focusvar') trend: `=string(`trend_focus', "%8.4f")' per period; other covariates held at median"
    if `has_ymin' & `ymin_val' > `g2_vis_lo' & `ymin_val' < `g2_vis_hi' {
        local g2_note_txt "`g2_note_txt'  |  DV lower limit: `=string(`ymin_val', "%9.3g")'"
    }
    if `has_ymax' & `ymax_val' > `g2_vis_lo' & `ymax_val' < `g2_vis_hi' {
        local g2_note_txt "`g2_note_txt'  |  DV upper limit: `=string(`ymax_val', "%9.3g")'"
    }

    twoway (line _yhat_p2 _period, lcolor(navy) lwidth(medium)),         ///
        `g2_upper' `g2_lower'                                             ///
        xlabel(1(4)`horizon') xtitle("Periods Ahead")                    ///
        ytitle("Projected `depvar'")                                      ///
        title("Forward Projection: IV Trended, Others Fixed", size(medsmall)) ///
        subtitle("`cross_note2'", size(vsmall))                           ///
        note("`g2_note_txt'", size(vsmall))                               ///
        scheme(s2color) name(rp_ts2, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_ts2 "`saving'_2.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  GRAPH 3 — Full system projection: all covariates trended           */
    /*  Uses orig_coef_* — safe after auxiliary regressions               */
    /* ------------------------------------------------------------------ */
    preserve
    quietly drop _all
    quietly set obs `horizon'
    quietly generate _period  = _n
    quietly generate _yhat_p3 = `orig_cons'
    
    local kk = 0
    foreach v of local regressors {
        local ++kk
        quietly replace _yhat_p3 = _yhat_p3 + ///
            `orig_coef_`kk'' * (`latest_`kk'' + (_n-1) * `trend_`kk'')
    }
    
    /* crossing detection */
    local cross_upper_p3 = .
    local cross_lower_p3 = .
    forvalues p = 1/`horizon' {
        local yh3 = `orig_cons'
        local kk2 = 0
        foreach v of local regressors {
            local ++kk2
            local yh3 = `yh3' + `orig_coef_`kk2'' * (`latest_`kk2'' + (`p'-1) * `trend_`kk2'')
        }
        if `has_ymax' & `cross_upper_p3' == . & `yh3' >= `ymax_val' local cross_upper_p3 = `p'
        if `has_ymin' & `cross_lower_p3' == . & `yh3' <= `ymin_val' local cross_lower_p3 = `p'
    }
    
    /* visible range — absolute padding */
    quietly summarize _yhat_p3, meanonly
    local g3_raw_lo = r(min)
    local g3_raw_hi = r(max)
    if `has_ymax' & `ymax_val' > `g3_raw_lo' & `ymax_val' < `g3_raw_hi' * 1.15 {
        local g3_raw_hi = max(`g3_raw_hi', `ymax_val')
    }
    if `has_ymin' & `ymin_val' < `g3_raw_hi' & `ymin_val' > `g3_raw_lo' * 1.15 {
        local g3_raw_lo = min(`g3_raw_lo', `ymin_val')
    }
    local g3_pad    = (`g3_raw_hi' - `g3_raw_lo') * 0.08
    local g3_vis_lo = `g3_raw_lo' - `g3_pad'
    local g3_vis_hi = `g3_raw_hi' + `g3_pad'
    
    local g3_upper ""
    local g3_lower ""
    if `has_ymax' {
        if `ymax_val' > `g3_vis_lo' & `ymax_val' < `g3_vis_hi' {
            local g3_upper "yline(`ymax_val', lcolor(red) lpattern(dash) lwidth(medium))"
        }
    }
    if `has_ymin' {
        if `ymin_val' > `g3_vis_lo' & `ymin_val' < `g3_vis_hi' {
            local g3_lower "yline(`ymin_val', lcolor(orange) lpattern(dash) lwidth(medium))"
        }
    }
    
    local cross_note3 ""
    if `has_ymax' {
        if `cross_upper_p3' != . local cross_note3 "Upper limit at period +`cross_upper_p3'"
        else                      local cross_note3 "Upper limit not reached within `horizon' periods"
    }
    if `has_ymin' {
        local lo_txt3 = cond(`cross_lower_p3' != ., "Lower limit at +`cross_lower_p3'", "Lower limit not reached")
        if "`cross_note3'" != "" local cross_note3 "`cross_note3'  |  `lo_txt3'"
        else                      local cross_note3 "`lo_txt3'"
    }
    if "`cross_note3'" == "" local cross_note3 "No DV limits specified"
    
    twoway (line _yhat_p3 _period, lcolor(dkgreen) lwidth(medium)),      ///
        `g3_upper' `g3_lower'                                             ///
        xlabel(1(4)`horizon') xtitle("Periods Ahead")                    ///
        ytitle("Projected `depvar'")                                      ///
        title("Full System Projection: All Covariates Trended", size(medsmall)) ///
        subtitle("`cross_note3'", size(vsmall))                           ///
        note("All covariates trended linearly. Inhibitor dynamics reflected in trajectory.", size(vsmall)) ///
        scheme(s2color) name(rp_ts3, replace)
    
    restore
    if "`saving'" != "" quietly graph save rp_ts3 "`saving'_3.gph", replace
    
    /* ------------------------------------------------------------------ */
    /*  COMBINE — 2×2 grid (3 graphs + blank cell)                        */
    /* ------------------------------------------------------------------ */
    if "`combine'" != "" {
        graph combine rp_ts1 rp_ts2 rp_ts3, ///
            cols(2) iscale(0.85)              ///
            title("regproject — Time Series: `depvar' ~ `focusvar'", size(small)) ///
            scheme(s2color) name(rp_ts_combined, replace)
        if "`saving'" != "" quietly graph save rp_ts_combined "`saving'_combined.gph", replace
    }
    
    if "`nodisplay'" == "" {
        di as text "  Time series graphs generated: rp_ts1  rp_ts2  rp_ts3"
        di as text "  Graph 1: static sweep    Graph 2: IV-trended projection"
        di as text "  Graph 3: full-system projection"
    }
    
end
