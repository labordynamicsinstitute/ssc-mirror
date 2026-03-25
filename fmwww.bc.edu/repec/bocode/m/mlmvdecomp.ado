*! mlmvdecomp v1.0.0  Subir Hait  2026
*! Decompose slope uncertainty into fixed vs random components
*! Requires mixed to have been run immediately before
program define mlmvdecomp, rclass
    version 14.1
    syntax ,                         ///
        Pred(string)                 ///
        Modx(string)                 ///
        [ Level(cilevel)             ///
          PLOT                       ///
          Saving(string asis) ]

    // ---------- guard ------------------------------------------------------
    if "`e(cmd)'" != "mixed" {
        di as error "mlmvdecomp must be run immediately after -mixed-"
        exit 301
    }

    if "`level'" == "" local level 95

    // ---------- extract e() -----------------------------------------------
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `b'
    local N    = e(N)
    local p    = colsof(`b')
    local df_r = max(`N' - `p', 1)

    local idx_pred 0
    local idx_int  0
    local k 1
    foreach nm of local colnames {
        if "`nm'" == "`pred'" local idx_pred `k'
        if inlist("`nm'",     ///
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
    local b_int  = `b'[1, `idx_int']
    local v11    = `V'[`idx_pred', `idx_pred']
    local v33    = `V'[`idx_int',  `idx_int']
    local v13    = `V'[`idx_pred', `idx_int']

    local alpha  = (100 - `level') / 100
    local t_crit = invttail(`df_r', `alpha' / 2)

    // ---------- moderator range & grid ------------------------------------
    quietly summarize `modx'
    local modx_min = r(mean) - 2 * r(sd)
    local modx_max = r(mean) + 2 * r(sd)
    local m_mean   = r(mean)
    local m_sd     = r(sd)

    // ---------- variance decomposition across moderator range -------------
    // var(slope) = var_fixed + var_random_contribution
    // var_fixed = var(b_pred) + w^2 * var(b_int) + 2w * cov(b_pred, b_int)
    //           = the SE^2 from delta method (fixed effects only)
    // If model has random slope on pred:
    //   var_total = var_fixed + tau11 (random slope variance)
    //   pct_random = tau11 / var_total * 100
    // We extract tau11 if available

    // try to get random slope variance for pred (tau_11)
    local tau11 = 0
    capture {
        // lns1_1_2 = log(SD of random slope) when random slope included
        local lns_rs = `b'[1, colnumb(`b', "lns1_1_2")]
        local tau11  = exp(`lns_rs')^2
    }
    if _rc local tau11 = 0

    local grid 100
    local step = (`modx_max' - `modx_min') / (`grid' - 1)

    // ---------- print header ----------------------------------------------
    di ""
    di as text "{hline 65}"
    di as text "  Variance Decomposition: mlmvdecomp"
    di as text "  Focal predictor: " as result "`pred'"
    di as text "  Moderator      : " as result "`modx'"
    di as text "{hline 65}"
    di ""
    di as text "  Slope variance components at -1SD, Mean, +1SD of `modx':"
    di as text "  {hline 60}"
    di as text %14s "`modx'" %14s "Var(fixed)" %14s "Var(random)" %12s "% random"
    di as text "  {hline 60}"

    foreach lbl in "-1 SD" "Mean" "+1 SD" {
        if "`lbl'" == "-1 SD" local wv = `m_mean' - `m_sd'
        if "`lbl'" == "Mean"  local wv = `m_mean'
        if "`lbl'" == "+1 SD" local wv = `m_mean' + `m_sd'

        local var_fixed = `v11' + `wv'^2 * `v33' + 2 * `wv' * `v13'
        if `var_fixed' < 0 local var_fixed 0
        local var_total = `var_fixed' + `tau11'
        if `var_total' > 0 local pct_r = 100 * `tau11' / `var_total'
        else                local pct_r = 0

        di as text %14s "`lbl'" as result %14.5f `var_fixed' ///
           %14.5f `tau11' %12.1f `pct_r' as text "%"
    }
    di as text "  {hline 60}"

    if `tau11' == 0 {
        di as text ""
        di as text "  NOTE: Random slope variance = 0."
        di as text "  If the model includes (1+`pred'|cluster), check lns1_1_2 in e(b)."
        di as text "  If random slope is absent, all variance is in fixed effects."
    }

    di ""
    di as text "  Fixed-effect 95% CI of slope at -1SD, Mean, +1SD:"
    di as text "  {hline 50}"
    di as text %14s "`modx'" %10s "Slope" %12s "CI lower" %12s "CI upper"
    di as text "  {hline 50}"

    foreach lbl in "-1 SD" "Mean" "+1 SD" {
        if "`lbl'" == "-1 SD" local wv = `m_mean' - `m_sd'
        if "`lbl'" == "Mean"  local wv = `m_mean'
        if "`lbl'" == "+1 SD" local wv = `m_mean' + `m_sd'
        local slope   = `b_pred' + `b_int' * `wv'
        local var_slp = `v11' + `wv'^2 * `v33' + 2 * `wv' * `v13'
        if `var_slp' < 0 local var_slp 0
        local se_slp  = sqrt(`var_slp')
        local ci_lo   = `slope' - `t_crit' * `se_slp'
        local ci_hi   = `slope' + `t_crit' * `se_slp'
        di as text %14s "`lbl'" as result %10.4f `slope' %12.4f `ci_lo' %12.4f `ci_hi'
    }
    di as text "  {hline 50}"
    di as text "{hline 65}"
    di ""

    // ---------- optional plot: prediction interval vs CI width -----------
    if "`plot'" != "" {
        preserve
            quietly {
                clear
                set obs `grid'
                generate double modx_val  = `modx_min' + (_n - 1) * `step'
                generate double slope     = `b_pred' + `b_int' * modx_val
                generate double var_fixed = `v11' + modx_val^2 * `v33' + ///
                                            2 * modx_val * `v13'
                replace var_fixed = 0 if var_fixed < 0
                generate double se_fixed  = sqrt(var_fixed)
                generate double ci_lo     = slope - `t_crit' * se_fixed
                generate double ci_hi     = slope + `t_crit' * se_fixed
                generate double se_total  = sqrt(var_fixed + `tau11')
                generate double pi_lo     = slope - `t_crit' * se_total
                generate double pi_hi     = slope + `t_crit' * se_total
            }

            twoway ///
                (rarea pi_lo pi_hi modx_val,               ///
                    color(navy) fintensity(15) lwidth(none)) ///
                (rarea ci_lo ci_hi modx_val,               ///
                    color(navy) fintensity(35) lwidth(none)) ///
                (line slope modx_val,                       ///
                    lcolor(navy) lwidth(medthick)),          ///
                yline(0, lcolor(gs8) lpattern(dash))        ///
                legend(order(1 "Prediction interval (with random slope)" ///
                             2 "Fixed-effect CI" 3 "Slope estimate")     ///
                       position(6) rows(2))                              ///
                xtitle("`modx'")                                         ///
                ytitle("Simple slope of `pred'")                         ///
                title("Variance Decomposition: `pred' x `modx'")        ///
                scheme(s2color)                                          ///
                `saving'
        restore
    }

    return scalar tau11  = `tau11'
    return scalar b_pred = `b_pred'
    return scalar b_int  = `b_int'
end
