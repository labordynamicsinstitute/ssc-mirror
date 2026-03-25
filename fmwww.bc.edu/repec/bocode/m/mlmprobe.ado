*! mlmprobe v1.0.0  Subir Hait  2026
*! Simple slopes for a two-way interaction from mixed
*! Requires mixed to have been run immediately before
program define mlmprobe, rclass
    version 14.1
    syntax ,                         ///
        Pred(string)                 ///
        Modx(string)                 ///
        [ AT(numlist)                ///
          Values(string)             ///
          Level(cilevel) ]

    // ---------- guard: must follow mixed -----------------------------------
    if "`e(cmd)'" != "mixed" {
        di as error "mlmprobe must be run immediately after -mixed-"
        exit 301
    }

    // ---------- defaults ---------------------------------------------------
    if "`values'" == "" local values "meansd"
    if "`level'"  == "" local level  95

    // ---------- extract coefficients and VCV from e() --------------------
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `b'

    // find column indices for pred, modx, and interaction
    local idx_pred 0
    local idx_int  0
    local k 1
    foreach nm of local colnames {
        if "`nm'" == "`pred'" local idx_pred `k'
        // interaction name can be c.pred#c.modx or c.modx#c.pred
        if inlist("`nm'",                          ///
            "c.`pred'#c.`modx'",                   ///
            "c.`modx'#c.`pred'",                   ///
            "`pred'#c.`modx'",                     ///
            "`modx'#c.`pred'") {
            local idx_int `k'
        }
        local ++k
    }

    if `idx_pred' == 0 {
        di as error "Predictor '`pred'' not found in e(b)."
        di as error "Column names available: `colnames'"
        exit 111
    }
    if `idx_int' == 0 {
        di as error "Interaction c.`pred'#c.`modx' not found in e(b)."
        di as error "Ensure model was fitted with c.`pred'##c.`modx'"
        exit 111
    }

    // ---------- scalar extraction ------------------------------------------
    local b_pred = `b'[1, `idx_pred']
    local b_int  = `b'[1, `idx_int']
    local v_pred = `V'[`idx_pred', `idx_pred']
    local v_int  = `V'[`idx_int',  `idx_int']
    local c_pi   = `V'[`idx_pred', `idx_int']

    // residual df: N - p (fixed effects only)
    local N   = e(N)
    local p   = colsof(`b')
    local df_r = `N' - `p'
    if `df_r' < 1 local df_r 1

    // ---------- get moderator values ---------------------------------------
    if "`at'" != "" {
        local modx_vals `at'
        local val_labels `at'
    }
    else {
        quietly summarize `modx'
        local m_mean = r(mean)
        local m_sd   = r(sd)

        if "`values'" == "meansd" {
            local v1 = `m_mean' - `m_sd'
            local v2 = `m_mean'
            local v3 = `m_mean' + `m_sd'
            local modx_vals  `v1' `v2' `v3'
            local val_labels "-1 SD" "Mean" "+1 SD"
        }
        else if "`values'" == "quartiles" {
            quietly _pctile `modx', p(25 50 75)
            local v1 = r(r1)
            local v2 = r(r2)
            local v3 = r(r3)
            local modx_vals  `v1' `v2' `v3'
            local val_labels "25th pct" "50th pct" "75th pct"
        }
        else if "`values'" == "tertiles" {
            quietly _pctile `modx', p(33.33 66.67)
            local v1 = r(r1)
            local v2 = r(r2)
            local modx_vals  `v1' `v2'
            local val_labels "1st tertile" "2nd tertile"
        }
        else {
            di as error "values() must be meansd, quartiles, or tertiles"
            exit 198
        }
    }

    // ---------- critical t -------------------------------------------------
    local alpha  = (100 - `level') / 100
    local t_crit = invttail(`df_r', `alpha' / 2)

    // ---------- header ------------------------------------------------------
    di ""
    di as text "{hline 78}"
    di as text "  Simple Slopes: mlmprobe"
    di as text "  Focal predictor : " as result "`pred'"
    di as text "  Moderator       : " as result "`modx'"
    di as text "  Confidence level: " as result "`level'" as text "%"
    di as text "  Residual df     : " as result `df_r'
    di as text "{hline 78}"
    di as text %12s "`modx'" %10s "Slope" %8s "SE" %9s "t" %12s "p" ///
               %10s "CI lower" %10s "CI upper"
    di as text "{hline 78}"

    // ---------- loop over moderator values ---------------------------------
    local i 1
    foreach w of local modx_vals {
        local slope    = `b_pred' + `b_int' * `w'
        local var_slp  = `v_pred' + `w'^2 * `v_int' + 2 * `w' * `c_pi'
        if `var_slp' < 0 local var_slp 0
        local se_slp   = sqrt(`var_slp')
        local t_val    = `slope' / `se_slp'
        local p_val    = 2 * ttail(`df_r', abs(`t_val'))
        local ci_lo    = `slope' - `t_crit' * `se_slp'
        local ci_hi    = `slope' + `t_crit' * `se_slp'

        if `p_val' < 0.001 local p_str "< .001"
        else                local p_str : display %7.3f `p_val'

        di as result %12.4f `w' %10.4f `slope' %8.4f `se_slp' ///
           %9.3f `t_val' %12s "`p_str'" %10.4f `ci_lo' %10.4f `ci_hi'

        // return values
        return scalar w_`i'     = `w'
        return scalar slope_`i' = `slope'
        return scalar se_`i'    = `se_slp'
        return scalar t_`i'     = `t_val'
        return scalar p_`i'     = `p_val'
        return scalar cilo_`i'  = `ci_lo'
        return scalar cihi_`i'  = `ci_hi'
        local ++i
    }

    di as text "{hline 78}"
    di ""
    return scalar n_values = `i' - 1
    return scalar df_r     = `df_r'
    return scalar b_pred   = `b_pred'
    return scalar b_int    = `b_int'
end
