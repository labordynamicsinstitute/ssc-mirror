*! regproject v1.1.0
*! Post-estimation projection and boundary analysis
*! Author : Dr Noman Arshed, Senior Lecturer
*!          Department of Business Analytics
*!          Sunway Business School, Sunway University
*! Email  : nouman.arshed@gmail.com
*! GitHub : nomanarshed/regproject
*! Date   : April 2026

program define regproject
    version 14
    
    /* ------------------------------------------------------------------ */
    /*  SYNTAX                                                              */
    /* ------------------------------------------------------------------ */
    syntax varname [,                   ///
        IVMin(real 99999999)            ///
        IVMax(real -99999999)           ///
        IVMins(numlist)                 ///
        IVMaxs(numlist)                 ///
        YMin(real 99999999)             ///
        YMax(real -99999999)            ///
        SAving(string)                  ///
        COMBINE                         ///
        NODisplay                       ///
        NOMO                            ///
    ]
    
    local focusvar `varlist'
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 1 — POST-ESTIMATION CHECKS                                   */
    /* ------------------------------------------------------------------ */
    if "`e(cmd)'" == "" {
        di as error "No estimation results found. Run a regression first."
        exit 301
    }
    
    local supported_cmds "regress xtreg xtregress qreg iqreg xtregar newey arima ardl ivregress"
    local ecmd = e(cmd)
    local cmd_ok = 0
    foreach c of local supported_cmds {
        if "`ecmd'" == "`c'" local cmd_ok = 1
    }
    if `cmd_ok' == 0 {
        di as error "regproject does not currently support e(cmd) = `ecmd'."
        di as error "Supported: `supported_cmds'"
        exit 322
    }
    
    capture confirm variable `focusvar'
    if _rc {
        di as error "Variable `focusvar' not found in dataset."
        exit 111
    }
    
    matrix _eb = e(b)
    local colnames : colnames _eb
    
    local focusfound = 0
    local focuspos   = 0
    local regressors ""
    
    foreach v of local colnames {
        if "`v'" == "_cons" continue
        /* strip equation prefix if present (e.g. "y:x1" -> "x1") */
        local vclean = "`v'"
        if strpos("`v'", ":") > 0 {
            local vclean = substr("`v'", strpos("`v'", ":") + 1, .)
        }
        local regressors `regressors' `vclean'
        if "`vclean'" == "`focusvar'" {
            local focusfound = 1
            local focuspos   = wordcount("`regressors'")
        }
    }
    
    if `focusfound' == 0 {
        di as error "`focusvar' not found in the estimated coefficients."
        exit 111
    }
    
    local nreg = wordcount("`regressors'")
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 2 — OPTION CONFLICT CHECKS                                   */
    /* ------------------------------------------------------------------ */
    local has_ivmin  = (`ivmin'  !=  99999999)
    local has_ivmax  = (`ivmax'  != -99999999)
    local has_ivmins = ("`ivmins'" != "")
    local has_ivmaxs = ("`ivmaxs'" != "")
    local has_ymin   = (`ymin'   !=  99999999)
    local has_ymax   = (`ymax'   != -99999999)
    
    if (`has_ivmin' | `has_ivmax') & (`has_ivmins' | `has_ivmaxs') {
        di as error "Cannot specify both ivmin()/ivmax() and ivmins()/ivmaxs()."
        exit 198
    }
    
    if `has_ivmins' {
        local nmins = wordcount("`ivmins'")
        if `nmins' != `nreg' {
            di as error "ivmins() has `nmins' value(s) but model has `nreg' regressor(s)."
            exit 198
        }
    }
    if `has_ivmaxs' {
        local nmaxs = wordcount("`ivmaxs'")
        if `nmaxs' != `nreg' {
            di as error "ivmaxs() has `nmaxs' value(s) but model has `nreg' regressor(s)."
            exit 198
        }
    }
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 3 — DATA MODE DETECTION                                      */
    /* ------------------------------------------------------------------ */
    local datamode ""
    local panelvar ""
    local timevar  ""
    
    capture quietly xtset
    if _rc == 0 {
        local panelvar "`r(panelvar)'"
        local timevar  "`r(timevar)'"
        if "`panelvar'" != "" & "`timevar'" != "" {
            local datamode "panel"
        }
        else if "`timevar'" != "" {
            local datamode "timeseries"
        }
    }
    
    if "`datamode'" == "" {
        capture quietly tsset
        if _rc == 0 {
            local timevar "`r(timevar)'"
            if "`timevar'" != "" local datamode "timeseries"
        }
    }
    
    if "`datamode'" == "" local datamode "crosssection"
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 4 — BUILD BOUNDS MATRIX                                      */
    /* ------------------------------------------------------------------ */
    tempname bounds_lower bounds_upper
    matrix `bounds_lower' = J(1, `nreg', 0)
    matrix `bounds_upper' = J(1, `nreg', 0)
    local bounds_source ""
    
    local kk = 0
    foreach v of local regressors {
        local ++kk
        
        if strpos("`v'", ".") > 0 {
            quietly summarize `focusvar', meanonly
            matrix `bounds_lower'[1, `kk'] = r(min)
            matrix `bounds_upper'[1, `kk'] = r(max)
            local bounds_source `bounds_source' "factor"
            continue
        }
        
        quietly summarize `v', meanonly
        local dmin_v = r(min)
        local dmax_v = r(max)
        
        if `kk' == `focuspos' {
            if `has_ivmin' {
                matrix `bounds_lower'[1, `kk'] = `ivmin'
                local src_k "ivmin/ivmax"
            }
            else if `has_ivmins' {
                local lb_k : word `kk' of `ivmins'
                matrix `bounds_lower'[1, `kk'] = `lb_k'
                local src_k "ivmins/ivmaxs"
            }
            else {
                matrix `bounds_lower'[1, `kk'] = `dmin_v'
                local src_k "data range"
            }
            
            if `has_ivmax' {
                matrix `bounds_upper'[1, `kk'] = `ivmax'
            }
            else if `has_ivmaxs' {
                local ub_k : word `kk' of `ivmaxs'
                matrix `bounds_upper'[1, `kk'] = `ub_k'
            }
            else {
                matrix `bounds_upper'[1, `kk'] = `dmax_v'
            }
        }
        else {
            if `has_ivmins' {
                local lb_k : word `kk' of `ivmins'
                matrix `bounds_lower'[1, `kk'] = `lb_k'
                local src_k "ivmins/ivmaxs"
            }
            else {
                matrix `bounds_lower'[1, `kk'] = `dmin_v'
                local src_k "data range"
            }
            
            if `has_ivmaxs' {
                local ub_k : word `kk' of `ivmaxs'
                matrix `bounds_upper'[1, `kk'] = `ub_k'
            }
            else {
                matrix `bounds_upper'[1, `kk'] = `dmax_v'
            }
        }
        
        local bounds_source `bounds_source' "`src_k'"
    }
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 5 — COMPUTE MEDIANS AND LATEST VALUES                        */
    /* ------------------------------------------------------------------ */
    tempname med_vec
    matrix `med_vec' = J(1, `nreg', 0)
    
    local kk = 0
    foreach v of local regressors {
        local ++kk
        quietly summarize `v', detail
        matrix `med_vec'[1, `kk'] = r(p50)
    }
    
    if "`datamode'" == "timeseries" | "`datamode'" == "panel" {
        quietly summarize `timevar', meanonly
        local latest_t = r(max)
    }
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 6 — EXTRACT REGRESSION COEFFICIENTS                          */
    /* ------------------------------------------------------------------ */
    local depvar   = e(depvar)
    local cons_val = 0
    capture local cons_val = _b[_cons]
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 7 — PRINT SPECIFICATION SUMMARY TABLE                        */
    /* ------------------------------------------------------------------ */
    di ""
    di as text "{hline 69}"
    di as text "  {bf:regproject} — Projection Specification Summary"
    di as text "{hline 69}"
    di as text "  Model        : " as result "`e(cmd)'" _col(40) as text "(" as result "`e(title)'" as text ")"
    
    if "`datamode'" == "panel" {
        di as text "  Data mode    : " as result "Panel data" ///
           _col(40) as text "(xtset: " as result "`panelvar'" as text ", " as result "`timevar'" as text ")"
    }
    else if "`datamode'" == "timeseries" {
        di as text "  Data mode    : " as result "Time series" ///
           _col(40) as text "(tsset/xtset: " as result "`timevar'" as text ")"
    }
    else {
        di as text "  Data mode    : " as result "Cross-sectional"
    }
    
    if `has_ymin' & `has_ymax' {
        local ybound_disp "[`=string(`ymin', "%9.3f")', `=string(`ymax', "%9.3f")']  (user-supplied)"
    }
    else if `has_ymax' & !`has_ymin' {
        local ybound_disp "[data min, `=string(`ymax', "%9.3f")']  (partial — upper only)"
    }
    else if `has_ymin' & !`has_ymax' {
        local ybound_disp "[`=string(`ymin', "%9.3f")', data max]  (partial — lower only)"
    }
    else {
        local ybound_disp "not specified — shading and crossing detection disabled"
    }
    di as text "  Dep. variable: " as result "`depvar'" _col(40) as text "Bounds: " as result "`ybound_disp'"
    di as text "  Focal IV     : " as result "`focusvar'"
    di as text "{hline 69}"
    di as text "  {bf:Variable}" _col(18) "{bf:Coef.}" _col(28) "{bf:Lower}" ///
               _col(38) "{bf:Upper}" _col(50) "{bf:Source}"
    di as text "{hline 69}"
    
    local kk = 0
    foreach v of local regressors {
        local ++kk
        local coef_k = _b[`v']
        local lb_k   = `bounds_lower'[1, `kk']
        local ub_k   = `bounds_upper'[1, `kk']
        local src_k  : word `kk' of `bounds_source'
        
        if "`v'" == "`focusvar'" {
            di as result "  `v' (focal)" _col(18) %8.4f `coef_k' ///
               _col(28) %8.3f `lb_k' _col(38) %8.3f `ub_k' ///
               _col(50) as text "`src_k'  {bf:←}"
        }
        else {
            di as result "  `v'" _col(18) %8.4f `coef_k' ///
               _col(28) %8.3f `lb_k' _col(38) %8.3f `ub_k' ///
               _col(50) as text "`src_k'"
        }
    }
    
    di as text "  _cons" _col(18) %8.4f `cons_val' _col(28) "—" _col(38) "—" _col(50) "—"
    di as text "{hline 69}"
    
    if "`datamode'" == "timeseries" local ngraphs = 3
    else                            local ngraphs = 4
    if "`nomo'" != ""               local ngraphs = `ngraphs' + 3

    di as text "  Graphs       : " as result "`ngraphs'" as text " (`datamode' mode`=cond("`nomo'"!="", " + nomogram", "")')"
    if "`saving'" != "" {
        di as text "  Saving       : " as result "`saving'_1.gph" as text " ..."
        if "`nomo'" != "" di as text "                  (nomo: `saving'_nomo1.gph  `saving'_nomo2.gph  `saving'_nomo3.gph)"
    }
    else {
        di as text "  Saving       : not specified"
    }
    di as text "{hline 69}"
    di ""
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 8 — PRESERVE e() THEN ROUTE TO GRAPH MODULES                */
    /*  Auxiliary regressions in sub-programs overwrite e().              */
    /*  We store here and restore after so repeated calls work.           */
    /* ------------------------------------------------------------------ */
    capture estimates drop _regproject_stored
    estimates store _regproject_stored
    
    if "`datamode'" == "crosssection" {
        _regproject_cs `focusvar', regressors(`regressors')           ///
            nreg(`nreg') focuspos(`focuspos') depvar(`depvar')        ///
            cons(`cons_val')                                           ///
            bounds_lower(`bounds_lower') bounds_upper(`bounds_upper') ///
            med_vec(`med_vec')                                         ///
            has_ymin(`has_ymin') has_ymax(`has_ymax')                 ///
            ymin_val(`ymin') ymax_val(`ymax')                         ///
            saving(`saving') `combine' `nodisplay'
    }
    else if "`datamode'" == "panel" {
        _regproject_pan `focusvar', regressors(`regressors')           ///
            nreg(`nreg') focuspos(`focuspos') depvar(`depvar')         ///
            cons(`cons_val') panelvar(`panelvar') timevar(`timevar')   ///
            latest_t(`latest_t')                                       ///
            bounds_lower(`bounds_lower') bounds_upper(`bounds_upper')  ///
            med_vec(`med_vec')                                         ///
            has_ymin(`has_ymin') has_ymax(`has_ymax')                  ///
            ymin_val(`ymin') ymax_val(`ymax')                          ///
            saving(`saving') `combine' `nodisplay'
    }
    else if "`datamode'" == "timeseries" {
        _regproject_ts `focusvar', regressors(`regressors')            ///
            nreg(`nreg') focuspos(`focuspos') depvar(`depvar')         ///
            cons(`cons_val') timevar(`timevar') latest_t(`latest_t')   ///
            bounds_lower(`bounds_lower') bounds_upper(`bounds_upper')  ///
            med_vec(`med_vec')                                         ///
            has_ymin(`has_ymin') has_ymax(`has_ymax')                  ///
            ymin_val(`ymin') ymax_val(`ymax')                          ///
            saving(`saving') `combine' `nodisplay'
    }
    
    /* ------------------------------------------------------------------ */
    /*  BLOCK 9 — NOMOGRAM GRAPHS (mode-agnostic, optional)               */
    /*  Runs after the mode-specific block so e(b) is still the stored    */
    /*  estimates (restored from _regproject_stored before this point).   */
    /* ------------------------------------------------------------------ */
    if "`nomo'" != "" {
        /* Restore before nomo so _b[] is available inside the sub-program */
        quietly estimates restore _regproject_stored
        _regproject_nomo `focusvar',                                    ///
            regressors(`regressors')                                    ///
            nreg(`nreg') focuspos(`focuspos') depvar(`depvar')         ///
            cons(`cons_val')                                            ///
            bounds_lower(`bounds_lower') bounds_upper(`bounds_upper')  ///
            med_vec(`med_vec')                                          ///
            has_ymin(`has_ymin') has_ymax(`has_ymax')                  ///
            ymin_val(`ymin') ymax_val(`ymax')                          ///
            saving(`saving') `nodisplay'
    }

    /* restore original estimation results for the user */
    quietly estimates restore _regproject_stored
    quietly estimates drop    _regproject_stored

end
