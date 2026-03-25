capture program drop mlmsens
*! mlmsens v1.0.1  Subir Hait  2026
*! Robustness diagnostics: ICC-shift and leave-one-cluster-out (LOCO)
*! Requires mixed to have been run immediately before
program define mlmsens, rclass
    version 14.1
    syntax ,                                ///
        Pred(string)                        ///
        Modx(string)                        ///
        Cluster(varname)                    ///
        [ Alpha(real 0.05)                  ///
          ICCrange(numlist min=2 max=2)     ///
          ICCgrid(integer 40)               ///
          NOLOCO                            ///
          VERBose                           ///
          PLOT                              ///
          Saving(string asis) ]

    // ---------- guard ------------------------------------------------------
    if "`e(cmd)'" != "mixed" {
        di as error "mlmsens must be run immediately after -mixed-"
        exit 301
    }

    // ---------- defaults ---------------------------------------------------
    if "`iccrange'" == "" local iccrange "0.01 0.40"
    local icc_lo : word 1 of `iccrange'
    local icc_hi : word 2 of `iccrange'

    // ---------- store cmdline before anything changes ----------------------
    local cmdline = e(cmdline)

    // ---------- extract e() -----------------------------------------------
    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)
    local colnames : colnames `b'
    local N        = e(N)
    local p        = colsof(`b')
    local df_r     = max(`N' - `p', 1)
    local depvar   = e(depvar)

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

    local b_int  = `b'[1, `idx_int']
    local se_int = sqrt(`V'[`idx_int', `idx_int'])
    local t_int  = `b_int' / `se_int'
    local p_int  = 2 * ttail(`df_r', abs(`t_int'))

    // ---------- observed ICC using _b[] notation ---------------------------
    // _b[equation:_cons] is more reliable than colnumb in Stata 14.1
    local tau2 = 0
    local sig2 = 1

    // Get residual variance
    capture local sig2 = exp(_b[lnsig_e:_cons])^2
    if _rc {
        // fallback: search colnames
        local k 1
        foreach nm of local colnames {
            if "`nm'" == "lnsig_e" {
                local sig2 = exp(`b'[1,`k'])^2
            }
            local ++k
        }
    }

    // Get random intercept variance
    // With random slope: Stata names intercept SD as lns1_1_2
    // With random intercept only: lns1_1_1
    local got_tau 0
    capture {
        local tau2    = exp(_b[lns1_1_2:_cons])^2
        local got_tau = 1
    }
    if `got_tau' == 0 {
        capture {
            local tau2    = exp(_b[lns1_1_1:_cons])^2
            local got_tau = 1
        }
    }
    if `got_tau' == 0 {
        // scan colnames for lns
        local k 1
        foreach nm of local colnames {
            if substr("`nm'",1,6) == "lns1_1" & `got_tau' == 0 {
                local tau2    = exp(`b'[1,`k'])^2
                local got_tau = 1
            }
            local ++k
        }
    }

    local icc_obs = `tau2' / (`tau2' + `sig2')

    // cluster info
    quietly levelsof `cluster', local(clusters)
    local n_clust : word count `clusters'
    local n_avg   = `N' / `n_clust'

    // observed deff
    local deff_obs = max(1 + (`n_avg' - 1) * `icc_obs', 0.001)

    // ---------- JN boundary -----------------------------------------------
    local b1  = `b'[1, `idx_pred']
    local b3  = `b_int'
    local v11 = `V'[`idx_pred', `idx_pred']
    local v33 = `V'[`idx_int',  `idx_int']
    local v13 = `V'[`idx_pred', `idx_int']
    local t_c = invttail(`df_r', `alpha' / 2)

    local A = `b3'^2 - `t_c'^2 * `v33'
    local B = 2 * (`b1' * `b3' - `t_c'^2 * `v13')
    local C = `b1'^2 - `t_c'^2 * `v11'
    local jn_obs = .
    if abs(`A') < 1e-12 {
        if abs(`B') > 1e-12 local jn_obs = -`C' / `B'
    }
    else {
        local disc = `B'^2 - 4 * `A' * `C'
        if `disc' >= 0 {
            local sq = sqrt(`disc')
            local jn_obs = (-`B' - `sq') / (2 * `A')
        }
    }

    // ---------- print header ----------------------------------------------
    di ""
    di as text "{hline 68}"
    di as text "  Robustness Diagnostics: mlmsens"
    di as text "  Predictor: " as result "`pred'" ///
       as text "   Moderator: " as result "`modx'" ///
       as text "   Cluster: " as result "`cluster'"
    di as text "{hline 68}"
    di ""
    di as text "  Observed interaction: b = " as result %7.4f `b_int' ///
       as text "  SE = " as result %7.4f `se_int' ///
       as text "  t = " as result %6.3f `t_int'
    if `p_int' < 0.001 di as text "  p < .001"
    else di as text "  p = " as result %6.3f `p_int'
    di as text "  Observed ICC = " as result %6.4f `icc_obs' ///
       as text "   J = " as result `n_clust' as text " clusters" ///
       as text "   avg n = " as result %5.1f `n_avg'

    di ""
    di as text "  --- ICC-Shift Robustness ---"
    di as text "  ICC range: [" as result `icc_lo' ///
       as text " , " as result `icc_hi' as text "]"
    di as text "  {hline 55}"
    di as text %10s "ICC" %12s "SE (adj)" %10s "t (adj)" %10s "p (adj)" %10s "Sig?"
    di as text "  {hline 55}"

    local step_icc = (`icc_hi' - `icc_lo') / (`iccgrid' - 1)
    local n_sig_icc 0

    tempfile iccdata
    preserve
        quietly {
            clear
            set obs `iccgrid'
            generate double icc_val = .
            generate double se_adj  = .
            generate double t_adj   = .
            generate double p_adj   = .
            generate byte   sig_adj = .
        }

        local row 1
        forvalues i = 1/`iccgrid' {
            local rho      = `icc_lo' + (`i' - 1) * `step_icc'
            local deff_adj = 1 + (`n_avg' - 1) * `rho'
            local se_a     = `se_int' * sqrt(max(`deff_adj',0.001) / `deff_obs')
            local t_a      = `b_int' / `se_a'
            local p_a      = 2 * ttail(`df_r', abs(`t_a'))
            local sig_a    = (`p_a' < `alpha')
            if `sig_a' local ++n_sig_icc

            quietly replace icc_val = `rho'   in `row'
            quietly replace se_adj  = `se_a'  in `row'
            quietly replace t_adj   = `t_a'   in `row'
            quietly replace p_adj   = `p_a'   in `row'
            quietly replace sig_adj = `sig_a' in `row'
            local ++row

            if mod(`i', max(1, int(`iccgrid'/8))) == 1 | `i' == `iccgrid' {
                if `p_a' < 0.001 local ps_a "< .001"
                else              local ps_a : display %7.3f `p_a'
                local sig_str = cond(`sig_a', "Yes", "No ")
                di as text %10.3f `rho' as result %12.4f `se_a' ///
                   %10.3f `t_a' %10s "`ps_a'" %10s "`sig_str'"
            }
        }
        quietly save `iccdata'
    restore

    di as text "  {hline 55}"
    local rob_idx = `n_sig_icc' / `iccgrid'
    di ""
    di as text "  Robustness index: " as result %5.1f `rob_idx' * 100 ///
       as text "% of ICC range interaction remains significant"

    if `rob_idx' > 0.90 {
        di as text "  OVERALL: Interaction is STABLE across the ICC range tested."
    }
    else if `rob_idx' > 0.60 {
        di as text "  OVERALL: Interaction is MODERATELY sensitive to ICC assumptions."
    }
    else {
        di as text "  OVERALL: Interaction is FRAGILE -- sensitive to ICC assumptions."
    }

    // ---------- LOCO analysis ---------------------------------------------
    if "`noloco'" == "" {
        di ""
        di as text "  --- Leave-One-Cluster-Out (LOCO) ---"
        di as text "  Refitting model dropping one cluster at a time..."
        if "`verbose'" != "" di as text "  (verbose mode)"
        di as text "  {hline 60}"
        di as text %14s "Cluster" %10s "b_int" %10s "SE" %10s "b_change" %10s "Sig?"
        di as text "  {hline 60}"

        // Build refit command by inserting "if cluster != X" before "||"
        // e(cmdline) = "mixed depvar ... || groupvar: ..."
        // We need: "mixed depvar ... if cluster != X || groupvar: ..."
        local pipe_pos = strpos("`cmdline'", "||")
        local cmd_pre  = strtrim(substr("`cmdline'", 1, `pipe_pos' - 1))
        local cmd_post = substr("`cmdline'", `pipe_pos', .)

        local n_sig_loco  0
        local n_valid     0
        local b_min       = `b_int'
        local b_max       = `b_int'
        local max_change  0
        local max_pct     0
        local inf_cluster ""

        foreach cid of local clusters {
            if "`verbose'" != "" di as text "  Dropping cluster: `cid'"

            capture quietly `cmd_pre' if `cluster' != `cid' `cmd_post'

            if _rc {
                if "`verbose'" != "" di as text "  Cluster `cid': failed (rc=`_rc')"
                continue
            }

            tempname b_sub V_sub
            matrix `b_sub' = e(b)
            matrix `V_sub' = e(V)
            local colnames_sub : colnames `b_sub'

            local idx_int_sub 0
            local ks 1
            foreach nm of local colnames_sub {
                if inlist("`nm'",                        ///
                    "c.`pred'#c.`modx'", "c.`modx'#c.`pred'", ///
                    "`pred'#c.`modx'",   "`modx'#c.`pred'") {
                    local idx_int_sub `ks'
                }
                local ++ks
            }

            if `idx_int_sub' == 0 continue

            local b_sub_int  = `b_sub'[1, `idx_int_sub']
            local se_sub_int = sqrt(`V_sub'[`idx_int_sub', `idx_int_sub'])
            local N_sub      = e(N)
            local p_sub      = colsof(`b_sub')
            local df_sub     = max(`N_sub' - `p_sub', 1)
            local t_sub      = `b_sub_int' / `se_sub_int'
            local p_sub_v    = 2 * ttail(`df_sub', abs(`t_sub'))
            local sig_sub    = (`p_sub_v' < `alpha')
            local b_chg      = `b_sub_int' - `b_int'
            local pct_chg    = 100 * abs(`b_chg') / max(abs(`b_int'), 1e-10)

            if `sig_sub' local ++n_sig_loco
            local ++n_valid

            if `b_sub_int' < `b_min' local b_min = `b_sub_int'
            if `b_sub_int' > `b_max' local b_max = `b_sub_int'
            if abs(`b_chg') > `max_change' {
                local max_change = abs(`b_chg')
                local max_pct    = `pct_chg'
                local inf_cluster "`cid'"
            }

            local sig_str = cond(`sig_sub', "Yes", "No ")
            di as text %14s "`cid'" as result %10.4f `b_sub_int' ///
               %10.4f `se_sub_int' %10.4f `b_chg' %10s "`sig_str'"
        }

        di as text "  {hline 60}"
        di ""
        if `n_valid' > 0 {
            di as text "  LOCO Summary:"
            di as text "  Significant in: " as result `n_sig_loco' ///
               as text " / " as result `n_valid' as text " fits" ///
               as result " (" %5.1f 100 * `n_sig_loco' / `n_valid' "%)"
            di as text "  b range: [" as result %7.4f `b_min' ///
               as text " , " as result %7.4f `b_max' as text "]"
            if "`inf_cluster'" != "" {
                di as text "  Most influential: cluster " as result "`inf_cluster'" ///
                   as text "  (b change = " as result %6.4f `max_change' ///
                   as text ", " %5.1f `max_pct' as text "%)"
            }
        }
        else {
            di as text "  No LOCO fits succeeded. Check model convergence."
            di as text "  Tip: Use a simpler random effects structure for LOCO."
        }
    }

    // ---------- plot ------------------------------------------------------
    if "`plot'" != "" {
        preserve
            use `iccdata', clear
            twoway ///
                (line se_adj icc_val if sig_adj == 1, lcolor(navy)     lwidth(medthick)) ///
                (line se_adj icc_val if sig_adj == 0, lcolor(cranberry) lwidth(medthick)), ///
                legend(order(1 "p < `alpha'" 2 "p >= `alpha'")                           ///
                       position(6) rows(1))                                               ///
                xtitle("Intraclass Correlation (ICC)")                                    ///
                ytitle("Adjusted SE of interaction")                                      ///
                title("ICC Sensitivity: Interaction SE")                                  ///
                scheme(s2color)                                                           ///
                `saving'
        restore
    }

    di as text "{hline 68}"
    di ""
    di as text "  NOTE: These are robustness diagnostics, not a full causal"
    di as text "  sensitivity analysis. They do not quantify unmeasured"
    di as text "  confounding needed to explain away the interaction."
    di ""

    return scalar b_int      = `b_int'
    return scalar se_int     = `se_int'
    return scalar icc_obs    = `icc_obs'
    return scalar rob_index  = `rob_idx'
    return scalar n_clusters = `n_clust'
end
