*! mlmjn v1.0.0  Subir Hait  2026
*! Johnson-Neyman interval for two-way MLM interaction
*! Analytical solution via quadratic formula (exact, no grid search)
*! Requires mixed to have been run immediately before
program define mlmjn, rclass
    version 14.1
    syntax ,                         ///
        Pred(string)                 ///
        Modx(string)                 ///
        [ Alpha(real 0.05)           ///
          PLOT                       ///
          Grid(integer 200)          ///
          Saving(string) ]

    // ---------- guard ------------------------------------------------------
    if "`e(cmd)'" != "mixed" {
        di as error "mlmjn must be run immediately after -mixed-"
        exit 301
    }

    // ---------- extract e() -----------------------------------------------
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `b'

    local idx_pred 0
    local idx_int  0
    local k 1
    foreach nm of local colnames {
        if "`nm'" == "`pred'" local idx_pred `k'
        if inlist("`nm'",                        ///
            "c.`pred'#c.`modx'",                 ///
            "c.`modx'#c.`pred'",                 ///
            "`pred'#c.`modx'",                   ///
            "`modx'#c.`pred'") {
            local idx_int `k'
        }
        local ++k
    }

    if `idx_pred' == 0 | `idx_int' == 0 {
        di as error "Cannot find `pred' or interaction in e(b)."
        di as error "Ensure model fitted with c.`pred'##c.`modx'"
        exit 111
    }

    local b1 = `b'[1, `idx_pred']
    local b3 = `b'[1, `idx_int']
    local v11 = `V'[`idx_pred', `idx_pred']
    local v33 = `V'[`idx_int',  `idx_int']
    local v13 = `V'[`idx_pred', `idx_int']

    local N    = e(N)
    local p    = colsof(`b')
    local df_r = max(`N' - `p', 1)

    // ---------- critical t -------------------------------------------------
    local t_crit = invttail(`df_r', `alpha' / 2)

    // ---------- analytical JN: solve quadratic ----------------------------
    // (b1 + b3*w)^2 / (v11 + w^2*v33 + 2w*v13) = t_crit^2
    // => A*w^2 + B*w + C = 0
    local A = `b3'^2 - `t_crit'^2 * `v33'
    local B = 2 * (`b1' * `b3' - `t_crit'^2 * `v13')
    local C = `b1'^2 - `t_crit'^2 * `v11'

    local jn1 = .
    local jn2 = .
    local n_bounds 0

    if abs(`A') < 1e-12 {
        // degenerate: linear equation
        if abs(`B') > 1e-12 {
            local jn1 = -`C' / `B'
            local n_bounds 1
        }
    }
    else {
        local disc = `B'^2 - 4 * `A' * `C'
        if `disc' >= 0 {
            local sq = sqrt(`disc')
            local jn1 = (-`B' - `sq') / (2 * `A')
            local jn2 = (-`B' + `sq') / (2 * `A')
            // sort
            if `jn1' > `jn2' {
                local tmp = `jn1'
                local jn1 = `jn2'
                local jn2 = `tmp'
            }
            local n_bounds 2
        }
    }

    // get moderator range from data
    quietly summarize `modx'
    local modx_min = r(min)
    local modx_max = r(max)

    // keep only bounds within observed range
    if `n_bounds' >= 1 {
        if `jn1' < `modx_min' | `jn1' > `modx_max' local jn1 = .
    }
    if `n_bounds' == 2 {
        if `jn2' < `modx_min' | `jn2' > `modx_max' local jn2 = .
    }

    // ---------- print results ---------------------------------------------
    di ""
    di as text "{hline 65}"
    di as text "  Johnson-Neyman Interval: mlmjn"
    di as text "  Focal predictor : " as result "`pred'"
    di as text "  Moderator       : " as result "`modx'"
    di as text "  Alpha           : " as result `alpha'
    di as text "  Moderator range : " as result %7.3f `modx_min' ///
               as text " to " as result %7.3f `modx_max'
    di as text "  Residual df     : " as result `df_r'
    di as text "{hline 65}"

    if `jn1' == . & `jn2' == . {
        di as text "  No Johnson-Neyman boundary found within the observed range."
        // check if universally sig or non-sig
        local w_mid = (`modx_min' + `modx_max') / 2
        local slope_mid = `b1' + `b3' * `w_mid'
        local var_mid = `v11' + `w_mid'^2 * `v33' + 2 * `w_mid' * `v13'
        local t_mid = `slope_mid' / sqrt(`var_mid')
        local p_mid = 2 * ttail(`df_r', abs(`t_mid'))
        if `p_mid' < `alpha' {
            di as text "  The slope of `pred' is significant across the entire range."
        }
        else {
            di as text "  The slope of `pred' is non-significant across the entire range."
        }
    }
    else {
        di as text "  Johnson-Neyman boundary/boundaries:"
        if `jn1' != . {
            di as text "    `modx' = " as result %9.4f `jn1'
        }
        if `jn2' != . {
            di as text "    `modx' = " as result %9.4f `jn2'
        }
        di ""
        di as text "  Interpretation: The simple slope of '`pred'' is significant"
        di as text "  (p < `alpha') at moderator values outside this boundary."
    }
    di as text "{hline 65}"
    di ""

    // ---------- optional plot ---------------------------------------------
    if "`plot'" != "" {
        // build grid dataset for plotting
        local step = (`modx_max' - `modx_min') / (`grid' - 1)
        tempfile plotdata
        preserve
            quietly {
                clear
                set obs `grid'
                generate double modx_val = `modx_min' + (_n - 1) * `step'
                generate double slope    = `b1' + `b3' * modx_val
                generate double var_slp  = `v11' + modx_val^2 * `v33' + ///
                                           2 * modx_val * `v13'
                replace var_slp = 0 if var_slp < 0
                generate double se_slp   = sqrt(var_slp)
                generate double t_val    = slope / se_slp
                generate double p_val    = 2 * ttail(`df_r', abs(t_val))
                generate byte   sig      = p_val < `alpha'
                generate double ci_lo    = slope - `t_crit' * se_slp
                generate double ci_hi    = slope + `t_crit' * se_slp
                save `plotdata'
            }

            use `plotdata', clear

            twoway ///
                (rarea ci_lo ci_hi modx_val if sig == 0, ///
                    color(cranberry) fintensity(20) lwidth(none)) ///
                (rarea ci_lo ci_hi modx_val if sig == 1, ///
                    color(navy) fintensity(20) lwidth(none))      ///
                (line slope modx_val if sig == 0,                 ///
                    lcolor(cranberry) lwidth(medthick))            ///
                (line slope modx_val if sig == 1,                 ///
                    lcolor(navy) lwidth(medthick)),                ///
                yline(0, lcolor(gs8) lpattern(dash))              ///
                legend(order(3 "Non-significant" 4 "Significant") ///
                       position(6) rows(1))                        ///
                xtitle("`modx'")                                   ///
                ytitle("Simple slope of `pred'")                   ///
                title("Johnson-Neyman Plot")                       ///
                subtitle("Regions where slope of `pred' is significant (p < `alpha')") ///
                scheme(s2color)
        restore
    }

    // ---------- return scalars --------------------------------------------
    return scalar jn1     = `jn1'
    return scalar jn2     = `jn2'
    return scalar t_crit  = `t_crit'
    return scalar df_r    = `df_r'
    return scalar b_pred  = `b1'
    return scalar b_int   = `b3'
    return scalar alpha   = `alpha'
end
