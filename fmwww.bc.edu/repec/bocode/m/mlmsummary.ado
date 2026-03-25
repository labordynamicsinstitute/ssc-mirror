*! mlmsummary v1.0.0  Subir Hait  2026
*! Consolidated moderation summary report for two-way MLM interaction
*! Requires mixed to have been run immediately before
program define mlmsummary, rclass
    version 14.1
    syntax ,                         ///
        Pred(string)                 ///
        Modx(string)                 ///
        [ Alpha(real 0.05)           ///
          Level(cilevel)             ///
          Values(string) ]

    // ---------- guard ------------------------------------------------------
    if "`e(cmd)'" != "mixed" {
        di as error "mlmsummary must be run immediately after -mixed-"
        exit 301
    }

    if "`values'" == "" local values "meansd"
    if "`level'"  == "" local level  95

    // ---------- extract e() -----------------------------------------------
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `b'
    local depvar = e(depvar)

    local idx_pred 0
    local idx_modx 0
    local idx_int  0
    local idx_cons 0
    local k 1
    foreach nm of local colnames {
        if "`nm'" == "`pred'"  local idx_pred `k'
        if "`nm'" == "`modx'"  local idx_modx `k'
        if "`nm'" == "_cons"   local idx_cons `k'
        if inlist("`nm'",      ///
            "c.`pred'#c.`modx'", "c.`modx'#c.`pred'", ///
            "`pred'#c.`modx'",   "`modx'#c.`pred'") {
            local idx_int `k'
        }
        local ++k
    }

    if `idx_pred' == 0 | `idx_int' == 0 {
        di as error "Cannot find `pred' or interaction in e(b)."
        exit 111
    }

    local b_pred = `b'[1, `idx_pred']
    local b_modx = `b'[1, `idx_modx']
    local b_int  = `b'[1, `idx_int']
    local se_pred = sqrt(`V'[`idx_pred', `idx_pred'])
    local se_modx = sqrt(`V'[`idx_modx', `idx_modx'])
    local se_int  = sqrt(`V'[`idx_int',  `idx_int'])
    local N    = e(N)
    local p    = colsof(`b')
    local df_r = max(`N' - `p', 1)

    local t_pred = `b_pred' / `se_pred'
    local t_modx = `b_modx' / `se_modx'
    local t_int  = `b_int'  / `se_int'
    local p_pred = 2 * ttail(`df_r', abs(`t_pred'))
    local p_modx = 2 * ttail(`df_r', abs(`t_modx'))
    local p_int  = 2 * ttail(`df_r', abs(`t_int'))

    local alpha_ci = (100 - `level') / 100
    local t_crit   = invttail(`df_r', `alpha_ci' / 2)

    // ---------- ICC ---------------------------------------------------------
    // Extract from e(V_r) or compute from variance components
    // In Stata 14.1 mixed, use e(b) lns1_1_1 and lnsig_e for variances
    local tau2  = .
    local sig2  = .
    local icc   = .
    capture {
        // lns1_1_1 = log(SD of random intercept)
        // lnsig_e  = log(SD of residual)
        local lns_re = `b'[1, colnumb(`b', "lns1_1_1")]
        local lns_re2 = exp(`lns_re')^2
        local lns_res = `b'[1, colnumb(`b', "lnsig_e")]
        local lns_res2 = exp(`lns_res')^2
        local tau2 = `lns_re2'
        local sig2 = `lns_res2'
        local icc  = `tau2' / (`tau2' + `sig2')
    }

    // ---------- JN boundary (analytical) ----------------------------------
    local v11 = `V'[`idx_pred', `idx_pred']
    local v33 = `V'[`idx_int',  `idx_int']
    local v13 = `V'[`idx_pred', `idx_int']
    local b1  = `b_pred'
    local b3  = `b_int'
    local t_c = invttail(`df_r', `alpha' / 2)

    local A = `b3'^2 - `t_c'^2 * `v33'
    local B = 2 * (`b1' * `b3' - `t_c'^2 * `v13')
    local C = `b1'^2 - `t_c'^2 * `v11'
    local jn1 = .
    local jn2 = .
    if abs(`A') < 1e-12 {
        if abs(`B') > 1e-12 local jn1 = -`C' / `B'
    }
    else {
        local disc = `B'^2 - 4 * `A' * `C'
        if `disc' >= 0 {
            local sq = sqrt(`disc')
            local jn1 = (-`B' - `sq') / (2 * `A')
            local jn2 = (-`B' + `sq') / (2 * `A')
            if `jn1' > `jn2' {
                local tmp = `jn1'
                local jn1 = `jn2'
                local jn2 = `tmp'
            }
        }
    }
    quietly summarize `modx'
    local modx_min = r(min)
    local modx_max = r(max)
    if `jn1' != . {
        if `jn1' < `modx_min' | `jn1' > `modx_max' local jn1 = .
    }
    if `jn2' != . {
        if `jn2' < `modx_min' | `jn2' > `modx_max' local jn2 = .
    }

    // ---------- print report -----------------------------------------------
    di ""
    di as text "{hline 68}"
    di as text "  Moderation Summary Report: mlmsummary"
    di as text "{hline 68}"
    di as text "  Outcome  : " as result "`depvar'"
    di as text "  Predictor: " as result "`pred'"
    di as text "  Moderator: " as result "`modx'"
    di as text "  N obs    : " as result `N' ///
       as text "    |    df_r: " as result `df_r'
    di as text "{hline 68}"

    di ""
    di as text "  Fixed Effects (focal terms)"
    di as text "  {hline 62}"
    di as text %20s "Term" %10s "b" %10s "SE" %9s "t" %12s "p"
    di as text "  {hline 62}"

    foreach term in pred modx int {
        if "`term'" == "pred" local tnm "`pred'"
        if "`term'" == "modx" local tnm "`modx'"
        if "`term'" == "int"  local tnm "`pred'#`modx'"
        local bv   = `b_`term''
        local sev  = `se_`term''
        local tv   = `t_`term''
        local pv   = `p_`term''
        if `pv' < 0.001 local ps "< .001"
        else             local ps : display %7.3f `pv'
        local star ""
        if `pv' < 0.001 local star "***"
        else if `pv' < 0.01  local star "** "
        else if `pv' < 0.05  local star "*  "
        else                  local star "   "
        di as text %20s "`tnm'" as result %10.4f `bv' %10.4f `sev' ///
           %9.3f `tv' %12s "`ps'" as text "  `star'"
    }
    di as text "  {hline 62}"
    di as text "  * p<.05  ** p<.01  *** p<.001"

    if `icc' != . {
        di ""
        di as text "  Variance Components"
        di as text "  {hline 40}"
        di as text %25s "Random intercept var:" as result %10.4f `tau2'
        di as text %25s "Residual var:"         as result %10.4f `sig2'
        di as text %25s "ICC:"                  as result %10.4f `icc'
        di as text "  {hline 40}"
    }

    di ""
    di as text "  Johnson-Neyman Boundary"
    di as text "  {hline 40}"
    if `jn1' == . & `jn2' == . {
        di as text "  No JN boundary within observed range."
    }
    else {
        if `jn1' != . di as text "  `modx' = " as result %9.4f `jn1'
        if `jn2' != . di as text "  `modx' = " as result %9.4f `jn2'
    }

    di ""
    di as text "  Simple Slopes at -1SD, Mean, +1SD of `modx'"
    di as text "  {hline 62}"
    di as text %14s "`modx'" %10s "Slope" %8s "SE" %9s "t" %12s "p"
    di as text "  {hline 62}"

    quietly summarize `modx'
    local m_mean = r(mean)
    local m_sd   = r(sd)
    foreach lbl in "-1 SD" "Mean" "+1 SD" {
        if "`lbl'" == "-1 SD" local wv = `m_mean' - `m_sd'
        if "`lbl'" == "Mean"  local wv = `m_mean'
        if "`lbl'" == "+1 SD" local wv = `m_mean' + `m_sd'
        local slope   = `b1' + `b3' * `wv'
        local var_slp = `v11' + `wv'^2 * `v33' + 2 * `wv' * `v13'
        if `var_slp' < 0 local var_slp 0
        local se_slp  = sqrt(`var_slp')
        local tv      = `slope' / `se_slp'
        local pv      = 2 * ttail(`df_r', abs(`tv'))
        if `pv' < 0.001 local ps "< .001"
        else             local ps : display %7.3f `pv'
        di as text %14s "`lbl'" as result %10.4f `slope' %8.4f `se_slp' ///
           %9.3f `tv' %12s "`ps'"
    }
    di as text "  {hline 62}"
    di as text ""
    di as text "{hline 68}"
    di ""

    return scalar b_int   = `b_int'
    return scalar se_int  = `se_int'
    return scalar t_int   = `t_int'
    return scalar p_int   = `p_int'
    return scalar icc     = `icc'
    return scalar jn1     = `jn1'
    return scalar jn2     = `jn2'
end
