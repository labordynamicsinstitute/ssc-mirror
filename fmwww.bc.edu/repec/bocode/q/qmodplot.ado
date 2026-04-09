*! version 1.0.0  qmodplot  Noman Arshed  26aug2025
*! Quadratic Moderation Plot
*! Sunway Business School, Sunway University, Malaysia
*! Pure Stata — no Mata; requires Stata 14+

capture program drop qmodplot

program define qmodplot
    version 14.0
    syntax ,                            ///
        MODEL(integer)                  ///
       [B0(real 0)                      ///
        BX(real 0)                      ///
        BXSQ(real 0)                    ///
        BMOD(real 0)                    ///
        BXM(real 0)                     ///
        BXSQM(real 0)                   ///
        XNAME(string)                   ///
        MNAME(string)                   ///
        YNAME(string)                   ///
        XRANGE(numlist min=2 max=2)     ///
        NPOINTS(integer 200)            ///
        MVALUES(numlist)                ///
        MDATA(varname numeric)          ///
        NQUANTILES(integer 3)           ///
        TITLE(string)                   ///
        SCHEME(string)                  ///
        FROMERETURN                     ///
        XVAR(string)                    ///
        XSQVAR(string)                  ///
        MVAR(string)                    ///
        XMVAR(string)                   ///
        XSQMVAR(string)                 ///
        CI                              ///
        LEVEL(integer 95)               ///
        XDATA(varname numeric)          ///
        YDATA(varname numeric)          ///
        LABELVAR(varname)               ///
        PANELID(varname)                ///
        CUTSTATS                        ///
        SCATTER                         ///
        SAVETABLE(string asis)          ///
        EXPGRAPH(string asis)           ///
        COMBINE                         ]

    /* 0. Defaults */
    if "`xname'" == "" local xname "x"
    if "`mname'" == "" local mname "m"
    if "`yname'" == "" local yname "y"
    if "`scheme'" == "" local scheme "s2color"

    /* 1. Coefficient locals */
    local c_b0    = `b0'
    local c_bx    = `bx'
    local c_bxsq  = `bxsq'
    local c_bmod  = `bmod'
    local c_bxm   = `bxm'
    local c_bxsqm = `bxsqm'

    /* 2. Validate model */
    if !inlist(`model', 1, 2, 3) {
        di as error "model() must be 1, 2, or 3"
        exit 198
    }
    if `model' == 1 local modlab "Linear x + Linear Moderation"
    if `model' == 2 local modlab "Quadratic x + Linear Moderation"
    if `model' == 3 local modlab "Quadratic x + Quadratic Moderation"

    /* 3. Load from e(b) */
    if "`fromereturn'" != "" {
        capture confirm matrix e(b)
        if _rc {
            di as error "No estimation results found."
            exit 301
        }
        capture local c_b0 = _b[_cons]
        if "`xvar'" != "" {
            capture local c_bx = _b[`xvar']
            if _rc {
                di as error "xvar: `xvar' not found in e(b)"
                exit 198
            }
        }
        if "`xsqvar'" != "" {
            capture local c_bxsq = _b[`xsqvar']
            if _rc {
                di as error "xsqvar: `xsqvar' not found in e(b)"
                exit 198
            }
        }
        if "`mvar'" != "" {
            capture local c_bmod = _b[`mvar']
            if _rc {
                di as error "mvar: `mvar' not found in e(b)"
                exit 198
            }
        }
        if "`xmvar'" != "" {
            capture local c_bxm = _b[`xmvar']
            if _rc {
                di as error "xmvar: `xmvar' not found in e(b)"
                exit 198
            }
        }
        if "`xsqmvar'" != "" {
            capture local c_bxsqm = _b[`xsqmvar']
            if _rc {
                di as error "xsqmvar: `xsqmvar' not found in e(b)"
                exit 198
            }
        }
        di as text "(Coefficients loaded from e(b))"
    }

    /* 4. Extract VCV elements for delta-method CI */
    local do_ci 0
    if "`ci'" != "" & "`fromereturn'" != "" {
        local ci_ok 1
        if "`xvar'"    == "" local ci_ok 0
        if "`mvar'"    == "" local ci_ok 0
        if "`xmvar'"   == "" local ci_ok 0
        if inlist(`model',2,3) & "`xsqvar'"  == "" local ci_ok 0
        if `model' == 3        & "`xsqmvar'" == "" local ci_ok 0
        if `ci_ok' {
            local do_ci 1
            tempname eV
            matrix `eV' = e(V)
            local zcrit = invnormal(1 - (1 - `level'/100)/2)
            /* Core elements (all models) */
            local s_cc   = `eV'["_cons","_cons"]
            local s_cx   = `eV'["_cons","`xvar'"]
            local s_cm   = `eV'["_cons","`mvar'"]
            local s_cxm  = `eV'["_cons","`xmvar'"]
            local s_xx   = `eV'["`xvar'","`xvar'"]
            local s_xm   = `eV'["`xvar'","`mvar'"]
            local s_xxm  = `eV'["`xvar'","`xmvar'"]
            local s_mm   = `eV'["`mvar'","`mvar'"]
            local s_mxm  = `eV'["`mvar'","`xmvar'"]
            local s_xmxm = `eV'["`xmvar'","`xmvar'"]
            /* Model 2 & 3 extra elements */
            if inlist(`model',2,3) {
                local s_cx2  = `eV'["_cons","`xsqvar'"]
                local s_xx2  = `eV'["`xvar'","`xsqvar'"]
                local s_x2m  = `eV'["`xsqvar'","`mvar'"]
                local s_x2xm = `eV'["`xsqvar'","`xmvar'"]
                local s_x2x2 = `eV'["`xsqvar'","`xsqvar'"]
            }
            /* Model 3 extra elements */
            if `model' == 3 {
                local s_cx2m   = `eV'["_cons","`xsqmvar'"]
                local s_xx2m   = `eV'["`xvar'","`xsqmvar'"]
                local s_x2x2m  = `eV'["`xsqvar'","`xsqmvar'"]
                local s_mx2m   = `eV'["`mvar'","`xsqmvar'"]
                local s_xmx2m  = `eV'["`xmvar'","`xsqmvar'"]
                local s_x2mx2m = `eV'["`xsqmvar'","`xsqmvar'"]
            }
            di as text "(VCV extracted for `level'% CI)"
        }
        else {
            di as text "(ci skipped: missing variable name options)"
        }
    }

    /* 5. Validate moderator
       mvalues() drives the plotted curves.
       mdata()   drives quantile-based curves when mvalues() is absent;
                 when mvalues() IS present, mdata() is still allowed and
                 used only for scatter predictions and summary statistics. */
    if "`mvalues'" == "" & "`mdata'" == "" {
        di as error "Specify mvalues(numlist)  or  mdata(varname) [nquantiles(#)]"
        exit 198
    }

    /* 6. Moderator values for curves */
    if "`mvalues'" == "" & "`mdata'" != "" {
        /* derive curve values from quantiles of mdata() */
        local nm = `nquantiles'
        forvalues k = 1/`nm' {
            local p   = 100*`k'/(`nm'+1)
            local p_r = round(`p')
            quietly _pctile `mdata', p(`p')
            local mval_`k' = r(r1)
            local mlab_`k' "`mname' (p`p_r')"
        }
    }
    else {
        /* mvalues() drives the curves; mdata() (if supplied) is for scatter/stats only */
        local nm = 0
        foreach mv of numlist `mvalues' {
            local ++nm
            local mval_`nm' = `mv'
            local mvt : display %10.4g `mv'
            local mvt = strtrim("`mvt'")
            local mlab_`nm' "`mname'=`mvt'"
        }
    }
    if `nm' == 0 {
        di as error "No moderator values derived."
        exit 198
    }

    /* 7. X range */
    if "`xrange'" == "" {
        local xmin = -3
        local xmax =  3
    }
    else {
        tokenize `xrange'
        local xmin = `1'
        local xmax = `2'
    }
    if `xmin' >= `xmax' {
        di as error "xrange(): first value must be less than second"
        exit 198
    }
    if `npoints' < 5 {
        di as error "npoints() must be >= 5"
        exit 198
    }

    /* 8. Pre-preserve summary statistics */
    local have_means 0
    if "`xdata'" != "" | "`ydata'" != "" | "`mdata'" != "" {
        local have_means 1
    }
    if "`xdata'" != "" {
        quietly summarize `xdata'
        local mean_x = r(mean)
        local sd_x   = r(sd)
        local n_x    = r(N)
    }
    if "`ydata'" != "" {
        quietly summarize `ydata'
        local mean_y = r(mean)
        local sd_y   = r(sd)
        local n_y    = r(N)
    }
    if "`mdata'" != "" {
        quietly summarize `mdata'
        local mean_m = r(mean)
        local sd_m   = r(sd)
        local n_m    = r(N)
    }

    /* 9. Pre-preserve scatter predictions */
    if "`scatter'" != "" {
        if "`xdata'" == "" & "`xvar'" != "" {
            local xdata `xvar'
        }
        if "`xdata'" == "" | "`mdata'" == "" {
            di as text "(scatter requires xdata() and mdata() — scatter disabled)"
            local scatter ""
        }
    }

    if "`scatter'" != "" {
        if "`panelid'" != "" {
            preserve
            if "`ydata'" != "" {
                quietly collapse (mean) `xdata' `mdata' `ydata', by(`panelid')
            }
            else {
                quietly collapse (mean) `xdata' `mdata', by(`panelid')
            }
            quietly gen double _yhat = `c_b0'          ///
                + `c_bx'   * `xdata'                   ///
                + `c_bxsq' * `xdata'^2                 ///
                + `c_bmod' * `mdata'                   ///
                + `c_bxm'  * `xdata' * `mdata'         ///
                + `c_bxsqm'* `xdata'^2 * `mdata'
            tempname sc_x sc_m sc_yhat
            quietly mkmat `xdata', matrix(`sc_x')
            quietly mkmat `mdata', matrix(`sc_m')
            quietly mkmat _yhat,   matrix(`sc_yhat')
            if "`ydata'" != "" {
                tempname sc_y
                quietly mkmat `ydata', matrix(`sc_y')
            }
            local sc_n = _N
            forvalues i = 1/`sc_n' {
                local sc_lab_`i' = `panelid'[`i']
            }
            restore
            local sc_labeltype "panel"
        }
        else {
            preserve
            quietly gen double _yhat = `c_b0'          ///
                + `c_bx'   * `xdata'                   ///
                + `c_bxsq' * `xdata'^2                 ///
                + `c_bmod' * `mdata'                   ///
                + `c_bxm'  * `xdata' * `mdata'         ///
                + `c_bxsqm'* `xdata'^2 * `mdata'
            tempname sc_x sc_m sc_yhat
            quietly mkmat `xdata', matrix(`sc_x')
            quietly mkmat `mdata', matrix(`sc_m')
            quietly mkmat _yhat,   matrix(`sc_yhat')
            if "`ydata'" != "" {
                tempname sc_y
                quietly mkmat `ydata', matrix(`sc_y')
            }
            local sc_n = _N
            if "`labelvar'" != "" {
                forvalues i = 1/`sc_n' {
                    local sc_lab_`i' = `labelvar'[`i']
                }
            }
            else {
                forvalues i = 1/`sc_n' {
                    local sc_lab_`i' = `i'
                }
            }
            restore
            local sc_labeltype "cross"
        }
    }

    /* 10. Build grid and generate curves */
    local colors "navy cranberry forest_green dkorange purple teal"
    local lpatts "solid dash dash_dot longdash shortdash dot"

    preserve
    quietly {
        drop _all
        set obs `npoints'
        gen double _x = `xmin' + (_n-1)*(`xmax'-`xmin')/(`npoints'-1)
    }

    local tw_y   ""
    local tw_me  ""
    local leg_y  ""
    local leg_me ""

    forvalues k = 1/`nm' {
        local mk  = `mval_`k''
        local mk2 = (`mk')^2
        local lbl "`mlab_`k''"

        tempvar _y _me

        if `model' == 1 {
            quietly gen double `_y' = `c_b0'           ///
                + `c_bx' * _x                          ///
                + `c_bmod' * `mk'                      ///
                + `c_bxm'  * _x * `mk'
            quietly gen double `_me' = `c_bx' + `c_bxm' * `mk'
        }
        if `model' == 2 {
            quietly gen double `_y' = `c_b0'           ///
                + `c_bx'  * _x                         ///
                + `c_bxsq'* _x^2                       ///
                + `c_bmod'* `mk'                       ///
                + `c_bxm' * _x * `mk'
            quietly gen double `_me' = `c_bx'          ///
                + 2 * `c_bxsq' * _x                    ///
                + `c_bxm' * `mk'
        }
        if `model' == 3 {
            quietly gen double `_y' = `c_b0'           ///
                + `c_bx'   * _x                        ///
                + `c_bxsq' * _x^2                      ///
                + `c_bmod' * `mk'                      ///
                + `c_bxm'  * _x * `mk'                 ///
                + `c_bxsqm'* _x^2 * `mk'
            quietly gen double `_me' = `c_bx'          ///
                + 2 * `c_bxsq'  * _x                   ///
                + `c_bxm'  * `mk'                      ///
                + 2 * `c_bxsqm' * _x * `mk'
        }

        /* CI bands — delta method, all Var(y) and Var(ME) formulas */
        if `do_ci' {
            tempvar _ylo _yhi _melo _mehi

            if `model' == 1 {
                /* g=[1,x,mk,x*mk]  Var(y)=g'Vg */
                quietly gen double `_ylo' = `_y' - `zcrit' * sqrt(max(0, ///
                    `s_cc'                          ///
                    + _x^2  * `s_xx'                ///
                    + `mk2' * `s_mm'                ///
                    + _x^2  * `mk2' * `s_xmxm'      ///
                    + 2 * _x       * `s_cx'         ///
                    + 2 * `mk'     * `s_cm'         ///
                    + 2 * _x*`mk'  * `s_cxm'        ///
                    + 2 * _x*`mk'  * `s_xm'         ///
                    + 2 * _x^2*`mk'* `s_xxm'        ///
                    + 2 * _x*`mk2' * `s_mxm'        ))
                quietly gen double `_yhi' = `_y' + `zcrit' * sqrt(max(0, ///
                    `s_cc'                          ///
                    + _x^2  * `s_xx'                ///
                    + `mk2' * `s_mm'                ///
                    + _x^2  * `mk2' * `s_xmxm'      ///
                    + 2 * _x       * `s_cx'         ///
                    + 2 * `mk'     * `s_cm'         ///
                    + 2 * _x*`mk'  * `s_cxm'        ///
                    + 2 * _x*`mk'  * `s_xm'         ///
                    + 2 * _x^2*`mk'* `s_xxm'        ///
                    + 2 * _x*`mk2' * `s_mxm'        ))
                /* g_me=[0,1,0,mk]  Var(ME)=g_me'V g_me */
                quietly gen double `_melo' = `_me' - `zcrit' * sqrt(max(0, ///
                    `s_xx' + `mk2'*`s_xmxm' + 2*`mk'*`s_xxm' ))
                quietly gen double `_mehi' = `_me' + `zcrit' * sqrt(max(0, ///
                    `s_xx' + `mk2'*`s_xmxm' + 2*`mk'*`s_xxm' ))
            }

            if `model' == 2 {
                /* g=[1,x,x²,mk,x*mk]  Var(y) */
                quietly gen double `_ylo' = `_y' - `zcrit' * sqrt(max(0,  ///
                    `s_cc'                              ///
                    + _x^2    * `s_xx'                  ///
                    + _x^4    * `s_x2x2'                ///
                    + `mk2'   * `s_mm'                  ///
                    + _x^2*`mk2' * `s_xmxm'             ///
                    + 2*_x       * `s_cx'               ///
                    + 2*_x^2     * `s_cx2'              ///
                    + 2*`mk'     * `s_cm'               ///
                    + 2*_x*`mk'  * `s_cxm'              ///
                    + 2*_x^3     * `s_xx2'              ///
                    + 2*_x*`mk'  * `s_xm'               ///
                    + 2*_x^2*`mk'* `s_xxm'              ///
                    + 2*_x^2*`mk'* `s_x2m'              ///
                    + 2*_x^3*`mk'* `s_x2xm'             ///
                    + 2*_x*`mk2' * `s_mxm'              ))
                quietly gen double `_yhi' = `_y' + `zcrit' * sqrt(max(0,  ///
                    `s_cc'                              ///
                    + _x^2    * `s_xx'                  ///
                    + _x^4    * `s_x2x2'                ///
                    + `mk2'   * `s_mm'                  ///
                    + _x^2*`mk2' * `s_xmxm'             ///
                    + 2*_x       * `s_cx'               ///
                    + 2*_x^2     * `s_cx2'              ///
                    + 2*`mk'     * `s_cm'               ///
                    + 2*_x*`mk'  * `s_cxm'              ///
                    + 2*_x^3     * `s_xx2'              ///
                    + 2*_x*`mk'  * `s_xm'               ///
                    + 2*_x^2*`mk'* `s_xxm'              ///
                    + 2*_x^2*`mk'* `s_x2m'              ///
                    + 2*_x^3*`mk'* `s_x2xm'             ///
                    + 2*_x*`mk2' * `s_mxm'              ))
                /* g_me=[0,1,2x,0,mk]  Var(ME) */
                quietly gen double `_melo' = `_me' - `zcrit' * sqrt(max(0, ///
                    `s_xx'                             ///
                    + 4*_x^2   * `s_x2x2'              ///
                    + `mk2'    * `s_xmxm'              ///
                    + 4*_x     * `s_xx2'               ///
                    + 2*`mk'   * `s_xxm'               ///
                    + 4*_x*`mk'* `s_x2xm'              ))
                quietly gen double `_mehi' = `_me' + `zcrit' * sqrt(max(0, ///
                    `s_xx'                             ///
                    + 4*_x^2   * `s_x2x2'              ///
                    + `mk2'    * `s_xmxm'              ///
                    + 4*_x     * `s_xx2'               ///
                    + 2*`mk'   * `s_xxm'               ///
                    + 4*_x*`mk'* `s_x2xm'              ))
            }

            if `model' == 3 {
                /* g=[1,x,x²,mk,x*mk,x²*mk]  Var(y) — 21 terms */
                quietly gen double `_ylo' = `_y' - `zcrit' * sqrt(max(0,   ///
                    `s_cc'                               ///
                    + _x^2       * `s_xx'                ///
                    + _x^4       * `s_x2x2'              ///
                    + `mk2'      * `s_mm'                ///
                    + _x^2*`mk2' * `s_xmxm'              ///
                    + _x^4*`mk2' * `s_x2mx2m'            ///
                    + 2*_x         * `s_cx'              ///
                    + 2*_x^2       * `s_cx2'             ///
                    + 2*`mk'       * `s_cm'              ///
                    + 2*_x*`mk'    * `s_cxm'             ///
                    + 2*_x^2*`mk'  * `s_cx2m'            ///
                    + 2*_x^3       * `s_xx2'             ///
                    + 2*_x*`mk'    * `s_xm'              ///
                    + 2*_x^2*`mk'  * `s_xxm'             ///
                    + 2*_x^3*`mk'  * `s_xx2m'            ///
                    + 2*_x^2*`mk'  * `s_x2m'             ///
                    + 2*_x^3*`mk'  * `s_x2xm'            ///
                    + 2*_x^4*`mk'  * `s_x2x2m'           ///
                    + 2*_x*`mk2'   * `s_mxm'             ///
                    + 2*_x^2*`mk2' * `s_mx2m'            ///
                    + 2*_x^3*`mk2' * `s_xmx2m'           ))
                quietly gen double `_yhi' = `_y' + `zcrit' * sqrt(max(0,   ///
                    `s_cc'                               ///
                    + _x^2       * `s_xx'                ///
                    + _x^4       * `s_x2x2'              ///
                    + `mk2'      * `s_mm'                ///
                    + _x^2*`mk2' * `s_xmxm'              ///
                    + _x^4*`mk2' * `s_x2mx2m'            ///
                    + 2*_x         * `s_cx'              ///
                    + 2*_x^2       * `s_cx2'             ///
                    + 2*`mk'       * `s_cm'              ///
                    + 2*_x*`mk'    * `s_cxm'             ///
                    + 2*_x^2*`mk'  * `s_cx2m'            ///
                    + 2*_x^3       * `s_xx2'             ///
                    + 2*_x*`mk'    * `s_xm'              ///
                    + 2*_x^2*`mk'  * `s_xxm'             ///
                    + 2*_x^3*`mk'  * `s_xx2m'            ///
                    + 2*_x^2*`mk'  * `s_x2m'             ///
                    + 2*_x^3*`mk'  * `s_x2xm'            ///
                    + 2*_x^4*`mk'  * `s_x2x2m'           ///
                    + 2*_x*`mk2'   * `s_mxm'             ///
                    + 2*_x^2*`mk2' * `s_mx2m'            ///
                    + 2*_x^3*`mk2' * `s_xmx2m'           ))
                /* g_me=[0,1,2x,0,mk,2x*mk]  Var(ME) — 10 terms */
                quietly gen double `_melo' = `_me' - `zcrit' * sqrt(max(0, ///
                    `s_xx'                              ///
                    + 4*_x^2       * `s_x2x2'           ///
                    + `mk2'        * `s_xmxm'           ///
                    + 4*_x^2*`mk2' * `s_x2mx2m'         ///
                    + 4*_x         * `s_xx2'            ///
                    + 2*`mk'       * `s_xxm'            ///
                    + 4*_x*`mk'    * `s_xx2m'           ///
                    + 4*_x*`mk'    * `s_x2xm'           ///
                    + 8*_x^2*`mk'  * `s_x2x2m'          ///
                    + 4*_x*`mk2'   * `s_xmx2m'          ))
                quietly gen double `_mehi' = `_me' + `zcrit' * sqrt(max(0, ///
                    `s_xx'                              ///
                    + 4*_x^2       * `s_x2x2'           ///
                    + `mk2'        * `s_xmxm'           ///
                    + 4*_x^2*`mk2' * `s_x2mx2m'         ///
                    + 4*_x         * `s_xx2'            ///
                    + 2*`mk'       * `s_xxm'            ///
                    + 4*_x*`mk'    * `s_xx2m'           ///
                    + 4*_x*`mk'    * `s_x2xm'           ///
                    + 8*_x^2*`mk'  * `s_x2x2m'          ///
                    + 4*_x*`mk2'   * `s_xmx2m'          ))
            }
        }

        local ci_idx = mod(`k'-1, 6) + 1
        local col : word `ci_idx' of `colors'
        local lp  : word `ci_idx' of `lpatts'

        if `do_ci' {
            local tw_y  `"`tw_y'  (rarea `_ylo' `_yhi' _x, color(`col'%25) lwidth(none))"'
            local tw_me `"`tw_me' (rarea `_melo' `_mehi' _x, color(`col'%25) lwidth(none))"'
        }
        local tw_y  `"`tw_y'  (line `_y'  _x, lcolor(`col') lpattern(`lp') lwidth(medthick))"'
        local tw_me `"`tw_me' (line `_me' _x, lcolor(`col') lpattern(`lp') lwidth(medthick))"'
        local leg_y  `"`leg_y'  label(`k' "`lbl'")"'
        local leg_me `"`leg_me' label(`k' "`lbl'")"'
    }

    local zk = `nm' + 1
    local tw_me `"`tw_me' (function y=0, range(`xmin' `xmax') lcolor(black) lpattern(dash) lwidth(thin))"'
    local leg_me `"`leg_me' label(`zk' "Zero")"'

    /* 11. Titles */
    if "`title'" == "" local title "Effect of `xname' on `yname'"
    local me_title "Marginal Effect of `xname' on `yname'"
    local subtitle "(`modlab')"
    if `model' == 1 local me_note "Note: Model 1 ME is constant in `xname'"
    else            local me_note ""
    if `do_ci'      local ci_note " | `level'% CI (delta method)"
    else            local ci_note ""

    /* 12. Graphs */
    twoway `tw_y',                                              ///
        title("`title'", size(medlarge))                        ///
        subtitle("`subtitle'", size(small) color(gs8))          ///
        xtitle("`xname'") ytitle("`yname'")                     ///
        yline(0, lcolor(gs12) lpattern(dot) lwidth(thin))       ///
        legend(on `leg_y' rows(1) position(6) size(small))      ///
        note("`ci_note'", size(vsmall))                         ///
        scheme(`scheme')                                        ///
        name(qmodplot_curves, replace)

    twoway `tw_me',                                             ///
        title("`me_title'", size(medlarge))                     ///
        subtitle("`subtitle'", size(small) color(gs8))          ///
        xtitle("`xname'") ytitle("d(`yname')/d(`xname')")       ///
        legend(on `leg_me' rows(1) position(6) size(small))     ///
        note("`me_note'`ci_note'", size(vsmall))                ///
        scheme(`scheme')                                        ///
        name(qmodplot_me, replace)

    if "`combine'" != "" {
        graph combine qmodplot_curves qmodplot_me,                ///
            rows(2) imargin(small)                              ///
            title("`title'")                                    ///
            scheme(`scheme')                                    ///
            name(qmodplot_combined, replace)
    }

    if `"`expgraph'"' != "" {
        local fn = strtrim(`"`expgraph'"')
        if regexm("`fn'", "^(.+)(\.[a-zA-Z0-9]+)$") {
            local fb = regexs(1)
            local fe = regexs(2)
        }
        else {
            local fb "`fn'"
            local fe ".png"
        }
        if "`combine'" != "" {
            graph export `"`fn'"', name(qmodplot_combined) replace
        }
        else {
            graph export `"`fb'_curves`fe'"', name(qmodplot_curves) replace
            graph export `"`fb'_me`fe'"',     name(qmodplot_me)     replace
        }
    }

    restore

    /* 13. Scatter plot */
    if "`scatter'" != "" {
        preserve
        quietly {
            drop _all
            set obs `sc_n'
            gen double _sc_x    = .
            gen double _sc_m    = .
            gen double _sc_yhat = .
        }
        if "`ydata'" != "" quietly gen double _sc_yact = .
        quietly gen str80 _sc_lbl = ""

        forvalues i = 1/`sc_n' {
            quietly replace _sc_x    = `sc_x'[`i',1]    in `i'
            quietly replace _sc_m    = `sc_m'[`i',1]    in `i'
            quietly replace _sc_yhat = `sc_yhat'[`i',1] in `i'
            if "`ydata'" != "" quietly replace _sc_yact = `sc_y'[`i',1] in `i'
            quietly replace _sc_lbl = "`sc_lab_`i''" in `i'
        }

        local tw_sc ""
        forvalues k = 1/`nm' {
            local mv_k  = `mval_`k''
            local ci_k  = mod(`k'-1, 6) + 1
            local col_k : word `ci_k' of `colors'
            local lp_k  : word `ci_k' of `lpatts'
            local tw_sc `"`tw_sc' (function y=`c_b0'+`c_bx'*x+`c_bxsq'*x^2+`c_bmod'*`mv_k'+`c_bxm'*x*`mv_k'+`c_bxsqm'*x^2*`mv_k', range(`xmin' `xmax') lcolor(`col_k') lpattern(`lp_k') lwidth(medthick))"'
        }
        local tw_sc `"`tw_sc' (scatter _sc_yhat _sc_x, msymbol(Oh) mcolor(gs6) msize(small) mlabel(_sc_lbl) mlabsize(vsmall) mlabcolor(gs4) mlabposition(12))"'

        if "`sc_labeltype'" == "panel" {
            local sc_title "Panel-Mean Predictions by Unit"
        }
        else {
            local sc_title "Fitted Values by Observation"
        }

        local nleg_sc = `nm' + 1
        local leg_sc ""
        forvalues k = 1/`nm' {
            local leg_sc `"`leg_sc' label(`k' "`mlab_`k''")"'
        }
        local leg_sc `"`leg_sc' label(`nleg_sc' "Fitted")"'

        twoway `tw_sc',                                             ///
            title("`sc_title'", size(medlarge))                     ///
            subtitle("`subtitle'", size(small) color(gs8))          ///
            xtitle("`xname'") ytitle("Fitted `yname'")              ///
            legend(on `leg_sc' rows(1) position(6) size(small))     ///
            scheme(`scheme')                                        ///
            name(qmodplot_scatter, replace)
        restore
    }

    /* 14. Cutoff / turning-point table */
    local do_cutoff 0
    if "`cutstats'" != "" & inlist(`model', 2, 3) local do_cutoff 1

    if `do_cutoff' {
        di as text ""
        di as text "{hline 70}"
        di as text "  Turning Point Analysis  (`modlab')"
        di as text "{hline 70}"
        di as text "  {col 3}Moderator      {col 24}m{col 36}x* (cutoff){col 52}y(x*){col 64}In range?"
        di as text "  {col 3}{hline 64}"

        local _d0 = 2 * (`c_bxsq' + `c_bxsqm' * 0)
        if abs(`_d0') < 1e-14 {
            di as text "  {col 3}Baseline (m=0)" _col(24) %8.4g 0 _col(36) "undefined (linear)"
        }
        else {
            local _xs0 = -(`c_bx' + `c_bxm' * 0) / `_d0'
            local _ys0 = `c_b0' + `c_bx' * `_xs0' + `c_bxsq' * `_xs0'^2
            local _in0 = cond(`_xs0' >= `xmin' & `_xs0' <= `xmax', "Yes", "No")
            di as text "  {col 3}Baseline (m=0)" _col(24) %8.4g 0 _col(36) %10.4g `_xs0' _col(52) %10.4g `_ys0' _col(64) "`_in0'"
        }

        forvalues k = 1/`nm' {
            local mv_k = `mval_`k''
            local _dk  = 2 * (`c_bxsq' + `c_bxsqm' * `mv_k')
            if abs(`_dk') < 1e-14 {
                di as text "  {col 3}`mlab_`k''" _col(24) %8.4g `mv_k' _col(36) "undefined (linear)"
            }
            else {
                local _xsk = -(`c_bx' + `c_bxm' * `mv_k') / `_dk'
                local _ysk = `c_b0' + `c_bx' * `_xsk' + `c_bxsq' * `_xsk'^2 ///
                           + `c_bmod' * `mv_k' + `c_bxm' * `_xsk' * `mv_k'   ///
                           + `c_bxsqm' * `_xsk'^2 * `mv_k'
                local _ink = cond(`_xsk' >= `xmin' & `_xsk' <= `xmax', "Yes", "No")
                di as text "  {col 3}`mlab_`k''" _col(24) %8.4g `mv_k' _col(36) %10.4g `_xsk' _col(52) %10.4g `_ysk' _col(64) "`_ink'"
            }
        }
        di as text "  {col 3}{hline 64}"
        di as text "  Formula: x* = -(bx + bxm*m) / [2*(bxsq + bxsqm*m)]"
    }
    else if "`cutstats'" != "" & `model' == 1 {
        di as text "(cutstats: no turning point in Model 1 — linear ME)"
    }

    /* 15. Summary statistics */
    if `have_means' {
        di as text ""
        di as text "  Summary statistics:"
        di as text "  {col 5}{hline 52}"
        di as text "  {col 5}Variable          {col 26}Mean{col 38}SD{col 50}N"
        di as text "  {col 5}{hline 52}"
        if "`xdata'" != "" {
            di as text "  {col 5}`xname'" _col(26) %9.4g `mean_x' _col(38) %9.4g `sd_x' _col(50) `n_x'
        }
        if "`ydata'" != "" {
            di as text "  {col 5}`yname'" _col(26) %9.4g `mean_y' _col(38) %9.4g `sd_y' _col(50) `n_y'
        }
        if "`mdata'" != "" {
            di as text "  {col 5}`mname'" _col(26) %9.4g `mean_m' _col(38) %9.4g `sd_m' _col(50) `n_m'
        }
        di as text "  {col 5}{hline 52}"
    }

    /* 16. Scatter table */
    if "`scatter'" != "" {
        di as text ""
        di as text "  {hline 68}"
        if "`sc_labeltype'" == "panel" {
            di as text "  Panel-Unit Mean Predictions"
        }
        else {
            di as text "  Observation-Level Predictions"
        }
        if "`ydata'" != "" {
            di as text "  {col 5}Label{col 22}`xname'{col 36}`mname'{col 50}Fitted{col 62}Actual"
        }
        else {
            di as text "  {col 5}Label{col 22}`xname'{col 36}`mname'{col 50}Fitted"
        }
        di as text "  {col 5}{hline 60}"
        forvalues i = 1/`sc_n' {
            local rx = `sc_x'[`i',1]
            local rm = `sc_m'[`i',1]
            local ry = `sc_yhat'[`i',1]
            if "`ydata'" != "" {
                local ra = `sc_y'[`i',1]
                di as text "  {col 5}`sc_lab_`i''" _col(22) %8.4g `rx' _col(36) %8.4g `rm' _col(50) %10.4g `ry' _col(62) %10.4g `ra'
            }
            else {
                di as text "  {col 5}`sc_lab_`i''" _col(22) %8.4g `rx' _col(36) %8.4g `rm' _col(50) %10.4g `ry'
            }
        }
        di as text "  {col 5}{hline 60}"
    }

    /* 17. Save CSV */
    if `"`savetable'"' != "" {
        local fn = strtrim(`"`savetable'"')
        tempname fh
        file open `fh' using `"`fn'"', write replace
        file write `fh' "qmodplot v1.0 — `modlab'" _n _n

        if `do_cutoff' {
            file write `fh' "Turning Point Analysis" _n
            file write `fh' "Moderator,m,x* cutoff,y at x*,In range?" _n
            local _d0 = 2 * (`c_bxsq' + `c_bxsqm' * 0)
            if abs(`_d0') >= 1e-14 {
                local _xs0 = -`c_bx' / `_d0'
                local _ys0 = `c_b0' + `c_bx' * `_xs0' + `c_bxsq' * `_xs0'^2
                local _in0 = cond(`_xs0' >= `xmin' & `_xs0' <= `xmax', "Yes", "No")
                file write `fh' "Baseline(m=0),0,`_xs0',`_ys0',`_in0'" _n
            }
            forvalues k = 1/`nm' {
                local mv_k = `mval_`k''
                local _dk  = 2 * (`c_bxsq' + `c_bxsqm' * `mv_k')
                if abs(`_dk') >= 1e-14 {
                    local _xsk = -(`c_bx' + `c_bxm' * `mv_k') / `_dk'
                    local _ysk = `c_b0' + `c_bx' * `_xsk' + `c_bxsq' * `_xsk'^2 + `c_bmod' * `mv_k' + `c_bxm' * `_xsk' * `mv_k' + `c_bxsqm' * `_xsk'^2 * `mv_k'
                    local _ink = cond(`_xsk' >= `xmin' & `_xsk' <= `xmax', "Yes", "No")
                    file write `fh' "`mlab_`k'',`mv_k',`_xsk',`_ysk',`_ink'" _n
                }
            }
            file write `fh' _n
        }

        if `have_means' {
            file write `fh' "Summary Statistics" _n
            file write `fh' "Variable,Mean,SD,N" _n
            if "`xdata'" != "" file write `fh' "`xname',`mean_x',`sd_x',`n_x'" _n
            if "`ydata'" != "" file write `fh' "`yname',`mean_y',`sd_y',`n_y'" _n
            if "`mdata'" != "" file write `fh' "`mname',`mean_m',`sd_m',`n_m'" _n
            file write `fh' _n
        }

        if "`scatter'" != "" {
            if "`ydata'" != "" {
                file write `fh' "Label,`xname',`mname',Fitted,Actual" _n
            }
            else {
                file write `fh' "Label,`xname',`mname',Fitted" _n
            }
            forvalues i = 1/`sc_n' {
                local rx = `sc_x'[`i',1]
                local rm = `sc_m'[`i',1]
                local ry = `sc_yhat'[`i',1]
                if "`ydata'" != "" {
                    local ra = `sc_y'[`i',1]
                    file write `fh' "`sc_lab_`i'',`rx',`rm',`ry',`ra'" _n
                }
                else {
                    file write `fh' "`sc_lab_`i'',`rx',`rm',`ry'" _n
                }
            }
        }
        file close `fh'
        di as text "(Table saved: `fn')"
    }

    /* 18. Summary */
    di as text ""
    di as text "{hline 65}"
    di as text "  {bf:qmodplot} v1.0  —  Moderated Regression Visualiser"
    di as text "{hline 65}"
    di as text "  Model  : `modlab'"
    di as text "  X range: [`xmin', `xmax']  (`npoints' points)"
    if `do_ci' di as text "  CI     : `level'% (delta method)"
    di as text ""
    di as text "  `mname' values:"
    forvalues k = 1/`nm' {
        di as text "    [`k']  " %10.5g `mval_`k'' "  (`mlab_`k'')"
    }
    di as text ""
    local gnames "qmodplot_curves  qmodplot_me"
    if "`combine'" != "" local gnames "`gnames'  qmodplot_combined"
    if "`scatter'" != "" local gnames "`gnames'  qmodplot_scatter"
    di as text "  Graphs: `gnames'"
    di as text "{hline 65}"

end
