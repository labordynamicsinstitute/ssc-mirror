*! mlmplot v1.0.0  Subir Hait  2026
*! Publication-ready interaction plot for two-way MLM interaction
*! Requires mixed to have been run immediately before
program define mlmplot
    version 14.1
    syntax ,                         ///
        Pred(string)                 ///
        Modx(string)                 ///
        [ AT(numlist)                ///
          Values(string)             ///
          Level(cilevel)             ///
          Xlabel(string)             ///
          Ylabel(string)             ///
          LEGendtitle(string)        ///
          NPred(integer 50)          ///
          NOInterval                 ///
          Saving(string asis) ]

    // ---------- guard ------------------------------------------------------
    if "`e(cmd)'" != "mixed" {
        di as error "mlmplot must be run immediately after -mixed-"
        exit 301
    }

    // ---------- defaults ---------------------------------------------------
    if "`values'" == "" local values "meansd"
    if "`level'"  == "" local level  95
    local depvar = e(depvar)
    if "`xlabel'"      == "" local xlabel      "`pred'"
    if "`ylabel'"      == "" local ylabel      "`depvar'"
    if "`legendtitle'" == "" local legendtitle "`modx'"

    // ---------- extract coefficients --------------------------------------
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `b'

    local idx_int 0
    local idx_pred 0
    local idx_modx 0
    local idx_cons 0
    local k 1
    foreach nm of local colnames {
        if "`nm'" == "`pred'"         local idx_pred `k'
        if "`nm'" == "`modx'"         local idx_modx `k'
        if "`nm'" == "_cons"          local idx_cons `k'
        if inlist("`nm'",             ///
            "c.`pred'#c.`modx'",      ///
            "c.`modx'#c.`pred'",      ///
            "`pred'#c.`modx'",        ///
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

    local b_pred = `b'[1, `idx_pred']
    local b_modx = `b'[1, `idx_modx']
    local b_int  = `b'[1, `idx_int']
    local b_cons = `b'[1, `idx_cons']

    local N    = e(N)
    local p    = colsof(`b')
    local df_r = max(`N' - `p', 1)
    local alpha  = (100 - `level') / 100
    local t_crit = invttail(`df_r', `alpha' / 2)

    // ---------- moderator values -----------------------------------------
    if "`at'" != "" {
        local modx_vals `at'
        local n_lines : word count `at'
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
            local lbl1 "-1 SD"
            local lbl2 "Mean"
            local lbl3 "+1 SD"
            local n_lines 3
        }
        else if "`values'" == "quartiles" {
            quietly _pctile `modx', p(25 50 75)
            local v1 = r(r1)
            local v2 = r(r2)
            local v3 = r(r3)
            local modx_vals  `v1' `v2' `v3'
            local lbl1 "25th pct"
            local lbl2 "50th pct"
            local lbl3 "75th pct"
            local n_lines 3
        }
        else if "`values'" == "tertiles" {
            quietly _pctile `modx', p(33.33 66.67)
            local v1 = r(r1)
            local v2 = r(r2)
            local modx_vals `v1' `v2'
            local lbl1 "1st tertile"
            local lbl2 "2nd tertile"
            local n_lines 2
        }
    }

    // ---------- predictor range ------------------------------------------
    quietly summarize `pred'
    local pred_min = r(min)
    local pred_max = r(max)
    local pred_step = (`pred_max' - `pred_min') / (`npred' - 1)

    // ---------- build plot dataset ----------------------------------------
    preserve
        quietly {
            clear
            local n_obs = `n_lines' * `npred'
            set obs `n_obs'
            generate double pred_val  = .
            generate double modx_val  = .
            generate double yhat      = .
            generate double ci_lo     = .
            generate double ci_hi     = .
            generate int    line_id   = .

            local row 1
            local lnum 1
            foreach w of local modx_vals {
                forvalues xi = 1/`npred' {
                    local xv = `pred_min' + (`xi' - 1) * `pred_step'
                    local yv = `b_cons' + `b_pred' * `xv' + `b_modx' * `w' + `b_int' * `xv' * `w'

                    // SE of fitted value via delta method
                    // grad = [1, xv, w, xv*w] for [cons, pred, modx, int]
                    // only use those 4 elements
                    local g_cons = 1
                    local g_pred = `xv'
                    local g_modx = `w'
                    local g_int  = `xv' * `w'

                    local var_fit =                                        ///
                        `g_cons'^2 * `V'[`idx_cons', `idx_cons'] +        ///
                        `g_pred'^2 * `V'[`idx_pred', `idx_pred'] +        ///
                        `g_modx'^2 * `V'[`idx_modx', `idx_modx'] +       ///
                        `g_int'^2  * `V'[`idx_int',  `idx_int']  +        ///
                        2 * `g_cons' * `g_pred' * `V'[`idx_cons', `idx_pred'] + ///
                        2 * `g_cons' * `g_modx' * `V'[`idx_cons', `idx_modx'] + ///
                        2 * `g_cons' * `g_int'  * `V'[`idx_cons', `idx_int']  + ///
                        2 * `g_pred' * `g_modx' * `V'[`idx_pred', `idx_modx'] + ///
                        2 * `g_pred' * `g_int'  * `V'[`idx_pred', `idx_int']  + ///
                        2 * `g_modx' * `g_int'  * `V'[`idx_modx', `idx_int']

                    if `var_fit' < 0 local var_fit 0
                    local se_fit = sqrt(`var_fit')

                    quietly replace pred_val = `xv'                       in `row'
                    quietly replace modx_val = `w'                        in `row'
                    quietly replace yhat     = `yv'                       in `row'
                    quietly replace ci_lo    = `yv' - `t_crit' * `se_fit' in `row'
                    quietly replace ci_hi    = `yv' + `t_crit' * `se_fit' in `row'
                    quietly replace line_id  = `lnum'                     in `row'
                    local ++row
                }
                local ++lnum
            }
        }

        // ---------- build twoway command ----------------------------------
        // colors: blue, red, green (Stata 14.1 named colors)
        local c1 "navy"
        local c2 "cranberry"
        local c3 "dkgreen"
        local colors `c1' `c2' `c3'

        local twoway_cmd ""
        local legend_order ""
        local leg_n 0

        local lnum 1
        foreach w of local modx_vals {
            local lbl : word `lnum' of `lbl1' `lbl2' `lbl3' `w'
            if "`lbl'" == "" local lbl = round(`w', 0.001)
            local cn : word `lnum' of `c1' `c2' `c3'

            if "`nointerval'" == "" {
                local twoway_cmd `twoway_cmd' ///
                    (rarea ci_lo ci_hi pred_val if line_id == `lnum', ///
                        color(`cn') fintensity(15) lwidth(none))
            }
            local twoway_cmd `twoway_cmd' ///
                (line yhat pred_val if line_id == `lnum', ///
                    lcolor(`cn') lwidth(medthick))

            if "`nointerval'" == "" {
                local ++leg_n  // skip rarea from legend
                local ++leg_n
                local legend_order "`legend_order' `leg_n' `"`lbl'"'"
            }
            else {
                local ++leg_n
                local legend_order "`legend_order' `leg_n' `"`lbl'"'"
            }
            local ++lnum
        }

        twoway `twoway_cmd',                              ///
            legend(order(`legend_order')                  ///
                   title("`legendtitle'", size(small))    ///
                   position(3) cols(1))                   ///
            xtitle("`xlabel'")                            ///
            ytitle("`ylabel'")                            ///
            title("Interaction Plot: `pred' x `modx'")   ///
            scheme(s2color)                               ///
            `saving'
    restore
end
