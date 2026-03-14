*! twostep_nardl_estat version 2.0.0  09mar2026
*! Post-estimation commands for twostep_nardl

program twostep_nardl_estat , rclass sortpreserve
    version 14

    if "`e(cmd)'" != "twostep_nardl" error 301

    gettoken subcmd rest : 0, parse(" ,")
    local lsubcmd = length(`"`subcmd'"')
    confirm name `subcmd'

    if "`subcmd'" == substr("ectest", 1, max(3, `lsubcmd')) {
        _2snardl_ectest `rest'
    }
    else if "`subcmd'" == substr("waldtest", 1, max(4, `lsubcmd')) {
        _2snardl_waldtest_post `rest'
    }
    else if "`subcmd'" == substr("multiplier", 1, max(4, `lsubcmd')) {
        _2snardl_multiplier `rest'
    }
    else if "`subcmd'" == substr("diagnostics", 1, max(4, `lsubcmd')) {
        _2snardl_diagnostics `rest'
    }
    else if "`subcmd'" == substr("halflife", 1, max(4, `lsubcmd')) {
        _2snardl_halflife `rest'
    }
    else if "`subcmd'" == substr("asymadj", 1, max(4, `lsubcmd')) {
        _2snardl_asymadj `rest'
    }
    else if "`subcmd'" == substr("irf", 1, max(3, `lsubcmd')) {
        _2snardl_irf `rest'
    }
    else if "`subcmd'" == substr("ecmtable", 1, max(4, `lsubcmd')) {
        _2snardl_ecmtable `rest'
    }
    else if inlist("`subcmd'", "summarize", "su", "ic", "vce") {
        estat_default `0'
    }
    else {
        di as error `"`subcmd' is not a recognized subcommand"'
        exit 198
    }
end


// ============================================================================
// ECTEST - Cointegration test (clean output)
// ============================================================================

program _2snardl_ectest, rclass

    syntax , [ Level(cilevel) SIGlevels(passthru) ASYmptotic ]

    // ---- Read stored values from e() ----
    local k = e(k)
    local case_n = e(case)
    local N_obs = e(N)
    local rho_val = e(rho)

    tempname F_pss t_pss
    scalar `F_pss' = e(F_pss)
    scalar `t_pss' = e(t_bdm)

    // ---- Count short-run coefficients (matching ardl_estat.ado formula) ----
    // sr = df_m - (k+1) - (case>=4)
    // For NARDL: k = number of asymmetric variables, level vars = 2*k+1 (or 1 for twostep)
    local p_lag = e(p_lag)
    local q_lag = e(q_lag)
    local sr_count = `p_lag' + 2 * `q_lag' * `k'

    // ---- Display header ----
    di ""
    di as text "{hline 78}"
    di as text _col(3) "{bf:Pesaran, Shin, and Smith (2001) Bounds Test}"
    di as text "{hline 78}"
    di ""
    di as text _col(5) "H0: no level relationship"
    di ""
    di as text _col(5) "F-statistic (PSS)" _col(30) "=" as result %12.4f scalar(`F_pss')
    di as text _col(5) "t-statistic (BDM)" _col(30) "=" as result %12.4f scalar(`t_pss')
    di as text _col(5) "Speed of adjustment" _col(30) "=" as result %12.4f `rho_val'
    di as text _col(5) "Case" _col(30) "=" as result %12.0f `case_n'
    di ""

    // ---- Kripfganz & Schneider critical values via ardlbounds ----
    capture which ardlbounds
    if !_rc {
        // For asymptotic: omit n() and sr() options
        local _ns_opts ""
        if "`asymptotic'" == "" {
            local _ns_opts "n(`N_obs') sr(`sr_count')"
            di as text _col(5) "Finite sample (" as result "`k'" ///
                as text " variables, " as result "`N_obs'" ///
                as text " observations, " as result "`sr_count'" ///
                as text " short-run coefficients)"
        }
        else {
            di as text _col(5) "Asymptotic (" as result "`k'" as text " variables)"
        }

        // F-bounds + t-bounds combined
        tempname cvmat
        qui ardlbounds , case(`case_n') stat(F) k(`k') `_ns_opts' ///
            `siglevels' pvalue(`=scalar(`F_pss')')
        matrix `cvmat' = r(cvmat)
        qui ardlbounds , case(`case_n') stat(t) k(`k') `_ns_opts' ///
            `siglevels' pvalue(`=scalar(`t_pss')')
        matrix `cvmat' = `cvmat' \ r(cvmat)
        local siglevels = r(siglevels)

        // Display critical values
        di ""
        di as text _col(5) "Kripfganz and Schneider (2020) critical values and approximate p-values"
        di ""
        local cspec : disp _dup(`=colsof("`cvmat'")/2') "| %7.3f & %7.3f "
        matlist `cvmat', cspec(& %2s `cspec' &) rspec(&|&&)

        // Decision matrix
        tempname decmat F_pv0 t_pv0 F_pv1 t_pv1 sl_frac decval
        local numlevels : word count `siglevels'
        matrix `decmat' = J(1, `numlevels', .)
        local cnames = subinstr("`siglevels' ", " ", "% ", .)
        matrix colnames `decmat' = `cnames'
        matrix rownames `decmat' = decision

        scalar `F_pv0' = `cvmat'[1, colnumb(`cvmat', "p-value:I(0)")]
        scalar `t_pv0' = `cvmat'[2, colnumb(`cvmat', "p-value:I(0)")]
        scalar `F_pv1' = `cvmat'[1, colnumb(`cvmat', "p-value:I(1)")]
        scalar `t_pv1' = `cvmat'[2, colnumb(`cvmat', "p-value:I(1)")]
        foreach sl of local siglevels {
            scalar `sl_frac' = `sl' / 100
            local decval .
            if (`F_pv0'>`sl_frac') | (`t_pv0'>`sl_frac') {
                local decval .a
            }
            else if (`F_pv1'<`sl_frac') & (`t_pv1'<`sl_frac') {
                local decval .r
            }
            matrix `decmat'[1,colnumb(`decmat', "`sl'%")] = `decval'
        }

        di ""
        di as text _col(5) "do not reject H0 if"
        di as text _col(7) "either F or t are closer to zero than critical values for I(0) variables"
        di as text _col(5) "reject H0 if"
        di as text _col(7) "both F and t are more extreme than critical values for I(1) variables"
        di ""
        di as text _col(5) "decision: no rejection (.a), inconclusive (.), or rejection (.r) at levels:"
        matlist `decmat'

        di as text "{hline 78}"

        return local siglevels = "`siglevels'"
        return matrix cvmat  = `cvmat'
        return matrix decmat = `decmat'
    }
    else {
        // Fallback: hardcoded PSS (2001) asymptotic critical values
        di as text _col(5) "(Install {cmd:ardl} package for Kripfganz-Schneider critical values)"
        di ""
        if `case_n' == 3 {
            di as text "{hline 60}"
            di as text _col(5) "Significance" _col(22) "I(0)" _col(34) "I(1)"
            di as text "{hline 60}"
            if `k' == 1 {
                di as text _col(5) "10%" _col(18) "F:" as result %6.2f 4.04 _col(32) as result %6.2f 4.78
                di as text _col(18) "t:" as result %6.2f -2.57 _col(32) as result %6.2f -3.21
                di as text _col(5) " 5%" _col(18) "F:" as result %6.2f 4.94 _col(32) as result %6.2f 5.73
                di as text _col(18) "t:" as result %6.2f -2.86 _col(32) as result %6.2f -3.53
                di as text _col(5) " 1%" _col(18) "F:" as result %6.2f 6.84 _col(32) as result %6.2f 7.84
                di as text _col(18) "t:" as result %6.2f -3.43 _col(32) as result %6.2f -4.10
            }
            else if `k' == 2 {
                di as text _col(5) "10%" _col(18) "F:" as result %6.2f 3.17 _col(32) as result %6.2f 4.14
                di as text _col(18) "t:" as result %6.2f -2.57 _col(32) as result %6.2f -3.46
                di as text _col(5) " 5%" _col(18) "F:" as result %6.2f 3.79 _col(32) as result %6.2f 4.85
                di as text _col(18) "t:" as result %6.2f -2.86 _col(32) as result %6.2f -3.78
                di as text _col(5) " 1%" _col(18) "F:" as result %6.2f 5.15 _col(32) as result %6.2f 6.36
                di as text _col(18) "t:" as result %6.2f -3.43 _col(32) as result %6.2f -4.37
            }
            else {
                di as text _col(5) "(Critical values unavailable for k=`k')"
            }
            di as text "{hline 60}"
        }
    }

    return scalar F_pss = scalar(`F_pss')
    return scalar t_pss = scalar(`t_pss')
    return scalar rho   = e(rho)
    return scalar case  = e(case)
    return scalar k     = e(k)
end



// ============================================================================
// WALDTEST - Clean Wald tests table
// ============================================================================

program _2snardl_waldtest_post, rclass

    syntax , [ LRsymmetry SRsymmetry IMPact PAIRwise ALL ]

    if "`lrsymmetry'`srsymmetry'`impact'`pairwise'`all'" == "" {
        local all "all"
    }

    di ""
    di as text "{hline 78}"
    di as text _col(3) "{bf:Asymmetry Tests}"
    di as text "{hline 78}"
    di as text _col(3) "Hypothesis" _col(38) "Wald" _col(52) "p-value" _col(66) ""
    di as text "{hline 78}"

    if "`lrsymmetry'" != "" | "`all'" != "" {
        capture confirm scalar e(W_lr)
        if !_rc {
            local star = cond(e(p_lr)<0.01,"***",cond(e(p_lr)<0.05,"**",cond(e(p_lr)<0.10,"*","")))
            di as text _col(3) "Long-run symmetry" ///
               _col(35) as result %10.4f e(W_lr) ///
               _col(50) as result %10.4f e(p_lr) ///
               _col(66) as text "`star'"
            return scalar W_lr = e(W_lr)
            return scalar p_lr = e(p_lr)
        }
    }

    if "`srsymmetry'" != "" | "`all'" != "" {
        capture confirm scalar e(W_sr)
        if !_rc {
            local star = cond(e(p_sr)<0.01,"***",cond(e(p_sr)<0.05,"**",cond(e(p_sr)<0.10,"*","")))
            di as text _col(3) "Short-run symmetry (additive)" ///
               _col(35) as result %10.4f e(W_sr) ///
               _col(50) as result %10.4f e(p_sr) ///
               _col(66) as text "`star'"
            return scalar W_sr = e(W_sr)
            return scalar p_sr = e(p_sr)
        }
    }

    if "`impact'" != "" | "`all'" != "" {
        capture confirm scalar e(W_impact)
        if !_rc {
            local star = cond(e(p_impact)<0.01,"***",cond(e(p_impact)<0.05,"**",cond(e(p_impact)<0.10,"*","")))
            di as text _col(3) "Short-run symmetry (impact)" ///
               _col(35) as result %10.4f e(W_impact) ///
               _col(50) as result %10.4f e(p_impact) ///
               _col(66) as text "`star'"
            return scalar W_impact = e(W_impact)
            return scalar p_impact = e(p_impact)
        }
    }

    di as text "{hline 78}"
    di as text _col(3) "*** p<0.01, ** p<0.05, * p<0.10"

end


// ============================================================================
// MULTIPLIER - Dynamic multiplier with beautiful visualization
// ============================================================================

program _2snardl_multiplier, rclass

    syntax , [ Horizon(integer 40) GRaph noTable SAVing(string) ///
               POScolor(string) NEGcolor(string) ASYMcolor(string) ///
               SCHeme(string) TItle(string) ]

    // Load Mata routines
    qui findfile _2snardl_mata.do
    qui run "`r(fn)'"

    tempname mult_mat

    local p_lag = e(p_lag)
    local q_lag = e(q_lag)
    local k     = e(k)

    // Call Mata wrapper (no inline blocks)
    mata: _2snardl_run_dynmult("e(b_sr)", "e(b_lr)", `p_lag', `q_lag', `k', `horizon', "`mult_mat'")

    // ---- Table display ----
    if "`table'" != "notable" {
        di ""
        di as text "{hline 78}"
        di as text _col(3) "{bf:Cumulative Dynamic Multipliers}"
        di as text "{hline 78}"
        di as text _col(5) "Horizon" ///
           _col(20) "Positive" ///
           _col(36) "Negative" ///
           _col(52) "Difference" ///
           _col(68) "Asymmetry"
        di as text "{hline 78}"

        // Display selected horizons for clean output
        local show_h "1 2 3 4 5 10 15 20 25 30 40"
        foreach h of local show_h {
            if `h' > `horizon' continue
            if `k' == 1 {
                local mpos = `mult_mat'[`h', 1]
                local mneg = `mult_mat'[`h', 2]
                local mdiff = `mpos' - `mneg'
                // Asymmetry indicator
                local asym_ind ""
                if abs(`mdiff') > 0.1 * max(abs(`mpos'), abs(`mneg')) {
                    local asym_ind "***"
                }
                else if abs(`mdiff') > 0.05 * max(abs(`mpos'), abs(`mneg')) {
                    local asym_ind "**"
                }
                di as result _col(5) %5.0f `h' ///
                   _col(18) %10.4f `mpos' ///
                   _col(34) %10.4f `mneg' ///
                   _col(50) %10.4f `mdiff' ///
                   _col(68) "`asym_ind'"
            }
        }

        // LR equilibrium values
        if `k' == 1 {
            local lr_pos = e(b_lr)[1, 1]
            local lr_neg = e(b_lr)[1, 2]
            di as text "{hline 78}"
            di as text _col(5) "LR eq." ///
               _col(18) as result %10.4f `lr_pos' ///
               _col(34) as result %10.4f `lr_neg' ///
               _col(50) as result %10.4f `=`lr_pos'-`lr_neg''
        }
        di as text "{hline 78}"
    }

    // ---- Beautiful graph ----
    if "`graph'" != "" {
        // Colors
        if "`poscolor'" == ""  local poscolor "navy"
        if "`negcolor'" == ""  local negcolor "cranberry"
        if "`asymcolor'" == "" local asymcolor "forest_green"
        if "`scheme'" == ""    local scheme "s2color"
        if "`title'" == ""     local title "Cumulative Dynamic Multipliers"

        // Copy to persistent matrix name for svmat inside preserve
        matrix _2snardl_mult = `mult_mat'

        // Store LR values before preserve
        if `k' == 1 {
            local lr_pos_g = e(b_lr)[1, 1]
            local lr_neg_g = e(b_lr)[1, 2]
        }

        preserve
        qui {
            clear
            set obs `horizon'
            gen int horizon = _n

            if `k' == 1 {
                svmat _2snardl_mult, names(mult)
                rename mult1 m_pos
                rename mult2 m_neg
                gen double m_diff = m_pos - m_neg
                gen double zero = 0

                gen double lr_pos = `lr_pos_g'
                gen double lr_neg = `lr_neg_g'

                twoway ///
                    (rarea zero m_diff horizon , ///
                        color("`asymcolor'%15") lwidth(none)) ///
                    (line m_pos horizon , ///
                        lcolor("`poscolor'") lwidth(medthick) lpattern(solid)) ///
                    (line m_neg horizon , ///
                        lcolor("`negcolor'") lwidth(medthick) lpattern(solid)) ///
                    (line m_diff horizon , ///
                        lcolor("`asymcolor'") lwidth(medium) lpattern(dash)) ///
                    (line lr_pos horizon , ///
                        lcolor("`poscolor'%50") lwidth(thin) lpattern(shortdash)) ///
                    (line lr_neg horizon , ///
                        lcolor("`negcolor'%50") lwidth(thin) lpattern(shortdash)) ///
                    (line zero horizon , ///
                        lcolor(gs10) lwidth(thin) lpattern(solid)) ///
                    , ///
                    legend(order( ///
                        2 "Positive shock" ///
                        3 "Negative shock" ///
                        4 "Asymmetry" ///
                      ) rows(1) position(6) size(small) ///
                        region(lcolor(gs14) fcolor(white))) ///
                    title("`title'", size(medium) color(black)) ///
                    xtitle("Horizon", size(small)) ///
                    ytitle("Cumulative effect", size(small)) ///
                    xlabel(, labsize(small) grid gstyle(dot)) ///
                    ylabel(, labsize(small) grid gstyle(dot) angle(0) format(%9.2f)) ///
                    graphregion(color(white) lcolor(white)) ///
                    plotregion(lcolor(gs14) margin(small)) ///
                    scheme(`scheme') ///
                    name(dynmult, replace)
            }
        }

        if "`saving'" != "" {
            qui graph export "`saving'", replace
            di as text "(graph saved to `saving')"
        }

        restore
        capture matrix drop _2snardl_mult
    }

    return matrix multipliers = `mult_mat'
end


// ============================================================================
// DIAGNOSTICS - Residual diagnostics panel
// ============================================================================

program _2snardl_diagnostics, rclass

    syntax , [ GRaph ]

    // Save twostep_nardl e() results so we can restore after regress
    tempname _nardl_est
    estimates store `_nardl_est'

    // Save needed values in locals before regress overwrites e()
    local _depvar    "`e(depvar)'"
    local _sr_regvars    "`e(sr_regvars)'"
    local _sr_regdepvar  "`e(sr_regdepvar)'"
    local _sr_nocons     "`e(sr_noconstant)'"
    local _p_lag = e(p_lag)
    local _rmse  = e(rmse)

    // Save sample in a tempvar before regress overwrites e(sample)
    tempvar touse
    qui gen byte `touse' = e(sample)

    // Get residuals
    tempvar resid yhat
    qui predict double `yhat' if `touse', xb
    qui gen double `resid' = D.`_depvar' - `yhat' if `touse'

    // Re-run the Step 2 OLS regression so estat bgodfrey/imtest/ovtest work
    local _did_regress = 0
    if "`_sr_regvars'" != "" {
        capture qui regress `_sr_regdepvar' `_sr_regvars' if `touse' , `_sr_nocons'
        if !_rc {
            local _did_regress = 1
        }
    }

    // Capture all diagnostic tests to guarantee estimates restore on error
    local _diag_rc = 0
    capture noisily {

    di ""
    di as text "{hline 78}"
    di as text _col(3) "{bf:Residual Diagnostics}"
    di as text "{hline 78}"
    di as text _col(3) "Test" _col(38) "Statistic" _col(54) "p-value" _col(68) ""
    di as text "{hline 78}"

    // 1. Serial correlation (Breusch-Godfrey LM)
    local _bg_ok = 0
    if `_did_regress' {
        local bg_lags = max(1, `_p_lag' + 1)
        capture qui estat bgodfrey, lags(`bg_lags')
        if !_rc {
            capture local bg_chi2 = r(chi2)
            if _rc == 0 {
                capture local bg_p = r(p)
                if _rc == 0 local _bg_ok = 1
            }
        }
    }
    if `_bg_ok' {
        local bg_star = cond(`bg_p'<0.01,"***",cond(`bg_p'<0.05,"**",cond(`bg_p'<0.10,"*","")))
        di as text _col(3) "Serial correlation" ///
           _col(35) as result %10.4f `bg_chi2' ///
           _col(52) as result %10.4f `bg_p' ///
           _col(68) as text "`bg_star'"
        return scalar bg_chi2 = `bg_chi2'
        return scalar bg_p    = `bg_p'
    }
    else {
        di as text _col(3) "Serial correlation" _col(35) as text "(not available)"
    }

    // 2. Heteroskedasticity (White's test)
    local _wh_ok = 0
    if `_did_regress' {
        capture qui estat imtest, white
        if !_rc {
            capture local wh_chi2 = r(chi2)
            if _rc == 0 {
                capture local wh_p = r(p)
                if _rc == 0 local _wh_ok = 1
            }
        }
    }
    if `_wh_ok' {
        local wh_star = cond(`wh_p'<0.01,"***",cond(`wh_p'<0.05,"**",cond(`wh_p'<0.10,"*","")))
        di as text _col(3) "Heteroskedasticity" ///
           _col(35) as result %10.4f `wh_chi2' ///
           _col(52) as result %10.4f `wh_p' ///
           _col(68) as text "`wh_star'"
        return scalar white_chi2 = `wh_chi2'
        return scalar white_p    = `wh_p'
    }
    else {
        di as text _col(3) "Heteroskedasticity" _col(35) as text "(not available)"
    }

    // 3. Normality (skewness/kurtosis - uses residuals, not regress context)
    local _sk_ok = 0
    capture qui sktest `resid'
    if !_rc {
        // sktest returns r(chi2) and either r(P_chi2) or r(p) depending on version
        capture local sk_chi2 = r(chi2)
        if _rc == 0 {
            // Try r(P_chi2) first (Stata 14+), then r(p)
            capture local sk_p = r(P_chi2)
            if _rc != 0 {
                capture local sk_p = r(p)
            }
            if _rc == 0 {
                local _sk_ok = 1
            }
        }
    }
    if `_sk_ok' {
        local sk_star = cond(`sk_p'<0.01,"***",cond(`sk_p'<0.05,"**",cond(`sk_p'<0.10,"*","")))
        di as text _col(3) "Normality" ///
           _col(35) as result %10.4f `sk_chi2' ///
           _col(52) as result %10.4f `sk_p' ///
           _col(68) as text "`sk_star'"
        return scalar norm_chi2 = `sk_chi2'
        return scalar norm_p    = `sk_p'
    }
    else {
        di as text _col(3) "Normality" _col(35) as text "(not available)"
    }

    // 4. Functional form (Ramsey RESET)
    local _rs_ok = 0
    if `_did_regress' {
        capture qui estat ovtest
        if !_rc {
            capture local rs_F = r(F)
            if _rc == 0 {
                capture local rs_p = r(p)
                if _rc == 0 local _rs_ok = 1
            }
        }
    }
    if `_rs_ok' {
        local rs_star = cond(`rs_p'<0.01,"***",cond(`rs_p'<0.05,"**",cond(`rs_p'<0.10,"*","")))
        di as text _col(3) "Functional form" ///
           _col(35) as result %10.4f `rs_F' ///
           _col(52) as result %10.4f `rs_p' ///
           _col(68) as text "`rs_star'"
        return scalar reset_F = `rs_F'
        return scalar reset_p = `rs_p'
    }
    else {
        di as text _col(3) "Functional form" _col(35) as text "(not available)"
    }

    di as text "{hline 78}"
    di as text _col(3) "*** p<0.01, ** p<0.05, * p<0.10"
    di as text _col(3) "Rejection indicates violation of the assumption"
    di as text "{hline 78}"

    } // end capture noisily
    local _diag_rc = _rc

    // ALWAYS restore twostep_nardl e() context so other post-estimation works
    qui estimates restore `_nardl_est'
    estimates drop `_nardl_est'

    // Re-throw any error that occurred during diagnostics
    if `_diag_rc' != 0 {
        exit `_diag_rc'
    }

    // CUSUM graph
    if "`graph'" != "" {
        tempvar cumresid cumresid_u cumresid_l obs_n
        qui gen double `cumresid' = sum(`resid') / `_rmse' if `touse'
        qui gen int `obs_n' = _n if `touse'

        // Approximate 5% significance bands
        qui su `obs_n' if `touse', meanonly
        local n_min = r(min)
        local n_max = r(max)
        local n_obs = r(N)
        qui gen double `cumresid_u' =  0.948 * sqrt(`n_obs') * ((`obs_n' - `n_min') / (`n_max' - `n_min')) if `touse'
        qui gen double `cumresid_l' = -0.948 * sqrt(`n_obs') * ((`obs_n' - `n_min') / (`n_max' - `n_min')) if `touse'

        twoway ///
            (rarea `cumresid_l' `cumresid_u' `obs_n' , ///
                color(navy%10) lwidth(none)) ///
            (line `cumresid_u' `obs_n' , ///
                lcolor(cranberry%60) lwidth(thin) lpattern(dash)) ///
            (line `cumresid_l' `obs_n' , ///
                lcolor(cranberry%60) lwidth(thin) lpattern(dash)) ///
            (line `cumresid' `obs_n' , ///
                lcolor(navy) lwidth(medium)) ///
            , ///
            legend(off) ///
            title("CUSUM Stability Test", size(medium) color(black)) ///
            xtitle("Observation", size(small)) ///
            ytitle("CUSUM", size(small)) ///
            xlabel(, labsize(small) grid gstyle(dot)) ///
            ylabel(, labsize(small) grid gstyle(dot) angle(0) format(%9.1f)) ///
            graphregion(color(white) lcolor(white)) ///
            plotregion(lcolor(gs14) margin(small)) ///
            note("5% significance boundaries shown as dashed lines", size(vsmall)) ///
            name(cusum, replace)
    }

end


// ============================================================================
// HALFLIFE - ECM Half-Life & Persistence Profile
// ============================================================================

program _2snardl_halflife, rclass

    syntax , [ Horizon(integer 40) GRaph ]

    local rho = e(rho)
    local p_lag = e(p_lag)

    // Load Mata routines
    qui findfile _2snardl_mata.do
    qui run "`r(fn)'"

    // ---- A. ECM Half-Life ----
    di ""
    di as text "{hline 78}"
    di as text _col(3) "{bf:Half-Life & Persistence Analysis}"
    di as text "{hline 78}"
    di ""
    di as text _col(3) "{bf:A. ECM Speed of Adjustment}"
    di as text "{hline 65}"
    di ""

    // Get ECM coefficient from posted b/V
    local ecm_b  = _b[ADJ:L.ect]
    local ecm_se = _se[ADJ:L.ect]
    local ecm_t  = `ecm_b' / `ecm_se'
    local ecm_p  = 2 * ttail(e(df_r), abs(`ecm_t'))
    local star   = cond(`ecm_p'<0.01,"***",cond(`ecm_p'<0.05,"**",cond(`ecm_p'<0.10,"*","")))

    di as text _col(5) "ECM coefficient (rho)    = " as result %10.6f `ecm_b' ///
       as text "  (`star')"
    di as text _col(5) "Std. Error               = " as result %10.6f `ecm_se'
    di as text _col(5) "t-statistic              = " as result %10.4f `ecm_t'
    di ""

    if `rho' >= 0 {
        di as error _col(5) "WARNING: ECM coefficient is non-negative."
        di as error _col(5) "The error correction mechanism is NOT convergent."
        di as text "{hline 65}"
    }
    else if `rho' <= -1 {
        local half_life = -ln(2) / ln(abs(1 + `rho'))
        di as text _col(5) "Half-Life                = " as result %8.2f `half_life' as text " periods"
        di as error _col(5) "Note: rho < -1 implies oscillatory convergence."
        di as text "{hline 65}"
    }
    else {
        local half_life = -ln(2) / ln(1 + `rho')
        local mal       = -(1 + `rho') / `rho'
        local full_adj  = ln(0.01) / ln(1 + `rho')

        di as text _col(5) "Half-Life (50%)          = " as result %8.2f `half_life' as text " periods"
        di as text _col(5) "Mean Adjustment Lag      = " as result %8.2f `mal' as text " periods"
        di as text _col(5) "99% Adjustment Time      = " as result %8.2f `full_adj' as text " periods"
        di ""
        di as text _col(5) "Interpretation: After a disequilibrium shock,"
        di as text _col(5) "50% corrected in " as result %3.1f `half_life' as text " periods, " ///
           "99% in " as result %3.0f `full_adj' as text " periods."
        di as text "{hline 65}"

        return scalar half_life = `half_life'
        return scalar mal       = `mal'
        return scalar full_adj  = `full_adj'
    }

    // ---- B. Persistence Profile (Pesaran & Shin 1996) ----
    di ""
    di as text _col(3) "{bf:B. Persistence Profile (Pesaran & Shin, 1996)}"
    di as text "{hline 65}"
    di ""

    // Extract AR coefficients from b_sr
    // b_sr layout: [ECT, L1Dy, L2Dy, ..., D.xpos, ..., D.xneg, ..., exog, _cons]
    forvalues j = 1/`p_lag' {
        capture local phi_`j' = e(b_sr)[1, 1 + `j']
        if _rc != 0 local phi_`j' = 0
    }
    if `p_lag' == 0 local phi_1 = 0

    // Compute AR coefficients in levels from ECM
    // a_1 = 1 + rho + phi_1
    // a_j = phi_j - phi_{j-1} for j=2..p
    // a_{p+1} = -phi_p
    local nlevels = `p_lag' + 1
    forvalues j = 1/`nlevels' {
        local a_`j' = 0
    }

    if `p_lag' == 0 {
        local a_1 = 1 + `rho'
    }
    else {
        local a_1 = 1 + `rho' + `phi_1'
        if `p_lag' >= 2 {
            forvalues j = 2/`p_lag' {
                local jm1 = `j' - 1
                local a_`j' = `phi_`j'' - `phi_`jm1''
            }
        }
        local a_`nlevels' = -`phi_`p_lag''
    }

    // Persistence profile: PP(0)=1, PP(h) = sum a_j * PP(h-j)
    tempname pp_mat
    mat `pp_mat' = J(`horizon' + 1, 1, 0)
    mat `pp_mat'[1, 1] = 1

    forvalues h = 1/`horizon' {
        local idx = `h' + 1
        local pp_h = 0
        local jmax = min(`h', `nlevels')
        forvalues j = 1/`jmax' {
            local prev_idx = `h' - `j' + 1
            local pp_h = `pp_h' + `a_`j'' * el(`pp_mat', `prev_idx', 1)
        }
        mat `pp_mat'[`idx', 1] = `pp_h'
    }

    // Find half-life from PP
    local pp_halflife = `horizon'
    forvalues h = 1/`horizon' {
        local idx = `h' + 1
        if abs(el(`pp_mat', `idx', 1)) < 0.5 {
            local pp_halflife = `h'
            continue, break
        }
    }

    // Display table
    di as text _col(5) "Horizon" _col(18) "PP(h)" _col(32) "% Remaining"
    di as text "  {hline 50}"

    forvalues h = 0/`horizon' {
        local idx = `h' + 1
        local pp_val = el(`pp_mat', `idx', 1)
        local pct = `pp_val' * 100

        if `h' <= 10 | mod(`h', 5) == 0 | `h' == `horizon' | `h' == `pp_halflife' {
            if `h' == `pp_halflife' {
                di as result _col(5) %4.0f `h' _col(16) %10.6f `pp_val' _col(30) %8.2f `pct' ///
                   "%  <-- Half-life"
            }
            else {
                di as text _col(5) %4.0f `h' _col(16) %10.6f `pp_val' _col(30) %8.2f `pct' "%"
            }
        }
    }
    di as text "  {hline 50}"
    di as text _col(5) "PP Half-Life = " as result `pp_halflife' as text " periods"

    return scalar pp_halflife = `pp_halflife'

    // Copy to named matrix for graph (return matrix moves the tempname)
    matrix _2snardl_pp = `pp_mat'
    return matrix pp = `pp_mat'

    // ---- Persistence Profile Graph ----
    if "`graph'" != "" {
        preserve
        capture noisily {
            qui clear
            qui set obs `= `horizon' + 1'
            qui gen horizon = _n - 1
            qui gen double pp = .
            qui gen double half_line = 0.5
            qui gen double zero_line = 0

            forvalues h = 0/`horizon' {
                local idx = `h' + 1
                qui replace pp = el(_2snardl_pp, `idx', 1) in `idx'
            }

            twoway (area pp horizon, color(navy%30) lcolor(navy) lwidth(medthick)) ///
                   (line half_line horizon, lcolor(cranberry) lwidth(thin) lpattern(dash)) ///
                   (line zero_line horizon, lcolor(gs8) lwidth(vthin)), ///
                   title("Persistence Profile", size(medium)) ///
                   subtitle("Convergence to Long-Run Equilibrium", size(small)) ///
                   ytitle("PP(h)", size(small)) ///
                   xtitle("Horizon", size(small)) ///
                   ylabel(0(0.25)1, format(%4.2f) labsize(small)) ///
                   xline(`pp_halflife', lcolor(cranberry) lwidth(thin) lpattern(shortdash)) ///
                   legend(order(1 "Persistence Profile" 2 "50% (Half-Life = `pp_halflife')") ///
                       size(vsmall) rows(1) position(6)) ///
                   graphregion(color(white) lcolor(white)) ///
                   plotregion(lcolor(gs14) margin(small)) ///
                   scheme(s2color) name(persist, replace)
        }
        restore
    }
    capture matrix drop _2snardl_pp

    di ""
    di as text "{hline 78}"
end


// ============================================================================
// ASYMADJ - Asymmetric Adjustment Speed
// ============================================================================

program _2snardl_asymadj, rclass

    syntax , [ Horizon(integer 40) GRaph ]

    local rho   = e(rho)
    local p_lag = e(p_lag)
    local q_lag = e(q_lag)
    local k     = e(k)

    // Load Mata routines
    qui findfile _2snardl_mata.do
    qui run "`r(fn)'"

    // Compute dynamic multipliers via Mata
    tempname mult_mat
    mata: _2snardl_run_dynmult("e(b_sr)", "e(b_lr)", `p_lag', `q_lag', `k', `horizon', "`mult_mat'")

    di ""
    di as text "{hline 78}"
    di as text _col(3) "{bf:Asymmetric Adjustment Speed}"
    di as text "{hline 78}"
    di ""

    // For each asymmetric variable (k==1 for now)
    if `k' == 1 {
        local lr_pos = e(b_lr)[1, 1]
        local lr_neg = e(b_lr)[1, 2]

        // Find effective LR from multiplier convergence
        local eff_lr_pos = `mult_mat'[`horizon', 1]
        local eff_lr_neg = `mult_mat'[`horizon', 2]

        // Impact multipliers (h=1)
        local impact_pos = `mult_mat'[1, 1]
        local impact_neg = `mult_mat'[1, 2]

        // Impact as % of LR
        local pct_pos = 0
        local pct_neg = 0
        if `eff_lr_pos' != 0 local pct_pos = (`impact_pos' / `eff_lr_pos') * 100
        if `eff_lr_neg' != 0 local pct_neg = (`impact_neg' / `eff_lr_neg') * 100

        // Half-life: first h where cumulative >= 50% of effective LR
        local hl_pos = `horizon'
        local hl_neg = `horizon'
        if `eff_lr_pos' != 0 {
            forvalues h = 1/`horizon' {
                if abs(`mult_mat'[`h', 1]) >= abs(0.5 * `eff_lr_pos') {
                    local hl_pos = `h'
                    continue, break
                }
            }
        }
        if `eff_lr_neg' != 0 {
            forvalues h = 1/`horizon' {
                if abs(`mult_mat'[`h', 2]) >= abs(0.5 * `eff_lr_neg') {
                    local hl_neg = `h'
                    continue, break
                }
            }
        }

        // 90% adjustment
        local adj90_pos = `horizon'
        local adj90_neg = `horizon'
        if `eff_lr_pos' != 0 {
            forvalues h = 1/`horizon' {
                if abs(`mult_mat'[`h', 1]) >= abs(0.9 * `eff_lr_pos') {
                    local adj90_pos = `h'
                    continue, break
                }
            }
        }
        if `eff_lr_neg' != 0 {
            forvalues h = 1/`horizon' {
                if abs(`mult_mat'[`h', 2]) >= abs(0.9 * `eff_lr_neg') {
                    local adj90_neg = `h'
                    continue, break
                }
            }
        }

        // Overshooting detection
        local overshoot_pos = (abs(`pct_pos') > 100 & `eff_lr_pos' != 0)
        local overshoot_neg = (abs(`pct_neg') > 100 & `eff_lr_neg' != 0)

        // Display
        di as text _col(5) "" _col(30) "Positive (+)" _col(50) "Negative (-)"
        di as text "  {hline 65}"
        di as text _col(5) "Analytical LR Multiplier" ///
           _col(28) as result %10.4f `lr_pos' _col(48) %10.4f `lr_neg'
        di as text _col(5) "Effective LR (converged)" ///
           _col(28) as result %10.4f `eff_lr_pos' _col(48) %10.4f `eff_lr_neg'
        di as text _col(5) "Impact Multiplier (h=1)" ///
           _col(28) as result %10.4f `impact_pos' _col(48) %10.4f `impact_neg'
        di as text _col(5) "Impact as % of Eff. LR" ///
           _col(28) as result %9.1f `pct_pos' "%" _col(48) %9.1f `pct_neg' "%"

        if `overshoot_pos' {
            di as text _col(5) "Half-Life (+)" _col(28) as result "  Overshoot"
        }
        else {
            di as text _col(5) "Half-Life (+)" _col(28) as result %10.0f `hl_pos' as text " periods"
        }
        if `overshoot_neg' {
            di as text _col(5) "Half-Life (-)" _col(48) as result "  Overshoot"
        }
        else {
            di as text _col(5) "Half-Life (-)" _col(48) as result %10.0f `hl_neg' as text " periods"
        }
        di as text _col(5) "90% Adjustment (periods)" ///
           _col(28) as result %10.0f `adj90_pos' _col(48) %10.0f `adj90_neg'
        di as text "  {hline 65}"

        // Interpretation
        if `overshoot_pos' | `overshoot_neg' {
            di as text _col(5) "Note: 'Overshoot' = impact exceeds LR; initial"
            di as text _col(5) "over-reaction followed by partial reversal."
        }

        if !`overshoot_pos' & !`overshoot_neg' {
            if `hl_pos' < `hl_neg' {
                di as result _col(5) "=> Positive shocks absorbed FASTER than negative."
            }
            else if `hl_pos' > `hl_neg' {
                di as result _col(5) "=> Negative shocks absorbed FASTER than positive."
            }
            else {
                di as text _col(5) "=> Symmetric adjustment speed."
            }
        }

        return scalar hl_pos    = `hl_pos'
        return scalar hl_neg    = `hl_neg'
        return scalar adj90_pos = `adj90_pos'
        return scalar adj90_neg = `adj90_neg'

        // ---- Graph ----
        if "`graph'" != "" {
            matrix _2snardl_mult = `mult_mat'
            local lr_pos_g = `lr_pos'
            local lr_neg_g = `lr_neg'

            preserve
            capture noisily {
                qui clear
                qui set obs `horizon'
                qui gen int horizon = _n
                qui svmat _2snardl_mult, names(mult)
                qui rename mult1 cum_pos
                qui rename mult2 cum_neg
                qui gen double lr_pos_line = `lr_pos_g'
                qui gen double lr_neg_line = `lr_neg_g'

                twoway (line cum_pos horizon, lcolor(navy) lwidth(medthick)) ///
                       (line cum_neg horizon, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
                       (line lr_pos_line horizon, lcolor(navy%40) lwidth(thin) lpattern(longdash)) ///
                       (line lr_neg_line horizon, lcolor(cranberry%40) lwidth(thin) lpattern(longdash)), ///
                       title("Asymmetric Adjustment Paths", size(medium)) ///
                       subtitle("Positive vs. Negative Shock Absorption", size(small)) ///
                       ytitle("Cumulative Multiplier", size(small)) ///
                       xtitle("Horizon", size(small)) ///
                       xline(`hl_pos', lcolor(navy%40) lwidth(vthin) lpattern(dot)) ///
                       xline(`hl_neg', lcolor(cranberry%40) lwidth(vthin) lpattern(dot)) ///
                       legend(order(1 "Positive (HL=`hl_pos')" ///
                                    2 "Negative (HL=`hl_neg')" ///
                                    3 "LR+ target" 4 "LR- target") ///
                           size(vsmall) rows(1) position(6)) ///
                       yline(0, lcolor(gs12) lwidth(vthin)) ///
                       graphregion(color(white) lcolor(white)) ///
                       plotregion(lcolor(gs14) margin(small)) ///
                       scheme(s2color) name(asymadj, replace)
            }
            restore
            capture matrix drop _2snardl_mult
        }
    }
    else {
        di as text _col(5) "(Asymmetric adjustment for k>1 not yet implemented)"
    }

    di ""
    di as text "{hline 78}"
end


// ============================================================================
// IRF - Impulse Response Functions (marginal dynamic multipliers)
// ============================================================================

program _2snardl_irf, rclass

    syntax , [ Horizon(integer 40) GRaph Shock(string) ]

    if "`shock'" == "" local shock "both"

    local p_lag = e(p_lag)
    local q_lag = e(q_lag)
    local k     = e(k)

    // Load Mata routines
    qui findfile _2snardl_mata.do
    qui run "`r(fn)'"

    // Dynamic multipliers (cumulative) via Mata
    tempname mult_mat
    mata: _2snardl_run_dynmult("e(b_sr)", "e(b_lr)", `p_lag', `q_lag', `k', `horizon', "`mult_mat'")

    // Compute marginal (non-cumulative) IRFs from cumulative
    tempname irf_mat
    mat `irf_mat' = J(`horizon', 2, 0)

    // h=1: marginal = cumulative at h=1
    mat `irf_mat'[1, 1] = `mult_mat'[1, 1]
    mat `irf_mat'[1, 2] = `mult_mat'[1, 2]

    // h>1: marginal = cumulative(h) - cumulative(h-1)
    forvalues h = 2/`horizon' {
        mat `irf_mat'[`h', 1] = `mult_mat'[`h', 1] - `mult_mat'[`=`h'-1', 1]
        mat `irf_mat'[`h', 2] = `mult_mat'[`h', 2] - `mult_mat'[`=`h'-1', 2]
    }

    // ---- Table ----
    di ""
    di as text "{hline 78}"
    di as text _col(3) "{bf:Impulse Response Functions}"
    di as text "{hline 78}"
    di as text _col(5) "Horizon" ///
       _col(18) "IRF(+)" ///
       _col(32) "Cum(+)" ///
       _col(46) "IRF(-)" ///
       _col(60) "Cum(-)"
    di as text "{hline 78}"

    local show_h "1 2 3 4 5 6 7 8 9 10 15 20 25 30 40"
    foreach h of local show_h {
        if `h' > `horizon' continue
        if `k' == 1 {
            local irf_pos = `irf_mat'[`h', 1]
            local irf_neg = `irf_mat'[`h', 2]
            local cum_pos = `mult_mat'[`h', 1]
            local cum_neg = `mult_mat'[`h', 2]

            if "`shock'" == "both" | "`shock'" == "pos" | "`shock'" == "neg" {
                di as result _col(5) %5.0f `h' ///
                   _col(16) %10.4f `irf_pos' ///
                   _col(30) %10.4f `cum_pos' ///
                   _col(44) %10.4f `irf_neg' ///
                   _col(58) %10.4f `cum_neg'
            }
        }
    }
    di as text "{hline 78}"

    // Copy to named matrices before return moves them
    matrix _2snardl_irf = `irf_mat'
    return matrix irf = `irf_mat'
    return matrix cumulative = `mult_mat'

    // ---- Graph ----
    if "`graph'" != "" & `k' == 1 {
        preserve
        capture noisily {
            qui clear
            qui set obs `horizon'
            qui gen int horizon = _n
            qui svmat _2snardl_irf, names(irf)
            qui rename irf1 irf_pos
            qui rename irf2 irf_neg
            qui gen double zero = 0

            twoway (line irf_pos horizon, lcolor(navy) lwidth(medthick)) ///
                   (line irf_neg horizon, lcolor(cranberry) lwidth(medthick) lpattern(dash)) ///
                   (line zero horizon, lcolor(gs10) lwidth(thin)), ///
                   title("Impulse Response Functions", size(medium)) ///
                   subtitle("Marginal response to unit +/- shock", size(small)) ///
                   ytitle("Response", size(small)) ///
                   xtitle("Horizon", size(small)) ///
                   ylabel(, labsize(small) grid gstyle(dot) angle(0) format(%9.3f)) ///
                   xlabel(, labsize(small) grid gstyle(dot)) ///
                   legend(order(1 "Positive shock" 2 "Negative shock") ///
                       size(vsmall) rows(1) position(6)) ///
                   graphregion(color(white) lcolor(white)) ///
                   plotregion(lcolor(gs14) margin(small)) ///
                   scheme(s2color) name(irf, replace)
        }
        restore
    }
    capture matrix drop _2snardl_irf

end


// ============================================================================
// ECMTABLE - Dynamic Parameter Estimates (CGS 2020, Table 9 style)
//
// Runs BOTH one-step and two-step, displays side-by-side
// ============================================================================

program _2snardl_ecmtable, rclass

    syntax , [ STEP1(string) ]

    // ---- Capture current estimation info to re-run ----
    local depvar   "`e(depvar)'"
    local xvars    "`e(xvars)'"
    local asymvars "`e(asymvars)'"
    local linvars  "`e(linvars)'"
    local lagstr   "`e(lagstructure)'"
    local pos_vars "`e(pos_vars)'"
    local neg_vars "`e(neg_vars)'"
    local k        = e(k)
    local k_lin    = e(k_lin)

    // Parse lag structure: "4,4" -> numlist "4 4"
    local laglist = subinstr("`lagstr'", ",", " ", .)

    // Determine step1 method for two-step
    if "`step1'" == "" local step1 "`e(step1)'"
    if "`step1'" == "" local step1 "fmols"
    local step1u = upper("`step1'")

    // ---- Run one-step silently ----
    qui twostep_nardl `depvar' `xvars', decompose(`asymvars') lags(`laglist') onestep noctable noheader nowaldtest

    // Store one-step results
    tempname os_b os_V os_b_lr os_V_lr
    matrix `os_b'    = e(b_sr)
    matrix `os_V'    = e(V_sr)
    matrix `os_b_lr' = e(b_lr)
    matrix `os_V_lr' = e(V_lr)
    local os_n_sr    = colsof(`os_b')
    local os_srnames : colnames `os_b'
    local os_r2a     = e(r2_a)
    local os_N       = e(N)
    local os_levels  = 1 + 2 * `k' + `k_lin'

    // Diagnostics for one-step
    capture qui estat bgodfrey, lags(1 2 3 4)
    local os_bgp = cond(_rc == 0, r(p), .)
    capture qui estat hettest
    local os_htp = cond(_rc == 0, r(p), .)

    // ---- Run two-step silently ----
    qui twostep_nardl `depvar' `xvars', decompose(`asymvars') lags(`laglist') step1(`step1') noctable noheader nowaldtest

    // Store two-step results
    tempname ts_b ts_V ts_b_lr ts_V_lr
    matrix `ts_b'    = e(b_sr)
    matrix `ts_V'    = e(V_sr)
    matrix `ts_b_lr' = e(b_lr)
    matrix `ts_V_lr' = e(V_lr)
    local ts_n_sr    = colsof(`ts_b')
    local ts_srnames : colnames `ts_b'
    local ts_r2a     = e(r2_a)
    local ts_N       = e(N)

    // Diagnostics for two-step
    capture qui estat bgodfrey, lags(1 2 3 4)
    local ts_bgp = cond(_rc == 0, r(p), .)
    capture qui estat hettest
    local ts_htp = cond(_rc == 0, r(p), .)

    // ================================================================
    // DISPLAY TABLE
    // ================================================================

    local w = 78
    di ""
    di as text "{hline `w'}"
    di as text _col(26) "One-step NARDL        " _col(54) "Two-step `step1u'/OLS"
    di as text _col(5) "Variable" ///
       _col(24) "Estimate     S.E." ///
       _col(52) "Estimate     S.E."
    di as text "{hline `w'}"

    // ==== Row: Intercept ====
    // One-step: _cons is last element
    local os_c = `os_b'[1, `os_n_sr']
    local os_s = sqrt(`os_V'[`os_n_sr', `os_n_sr'])
    // Two-step: _cons is last element
    local ts_c = `ts_b'[1, `ts_n_sr']
    local ts_s = sqrt(`ts_V'[`ts_n_sr', `ts_n_sr'])

    di as text _col(5) "Intercept" ///
       as result _col(22) %10.3f `os_c' _col(35) %8.3f `os_s' ///
       as result _col(50) %10.3f `ts_c' _col(63) %8.3f `ts_s'

    // ==== Rows: D_{t-1}, E+_{t-1}, E-_{t-1} - one-step only ====
    local os_Dt1    = `os_b'[1, 1]
    local os_Dt1_se = sqrt(`os_V'[1, 1])

    di as text _col(5) "`depvar'(t-1)" ///
       as result _col(22) %10.3f `os_Dt1' _col(35) %8.3f `os_Dt1_se' ///
       as text   _col(55) "{c -}" _col(66) "{c -}"

    forvalues j = 1/`k' {
        local av : word `j' of `asymvars'
        local idx_p = 1 + 2*(`j'-1) + 1
        local idx_n = 1 + 2*(`j'-1) + 2

        local os_Ep    = `os_b'[1, `idx_p']
        local os_Ep_se = sqrt(`os_V'[`idx_p', `idx_p'])
        local os_En    = `os_b'[1, `idx_n']
        local os_En_se = sqrt(`os_V'[`idx_n', `idx_n'])

        di as text _col(5) "`av'+(t-1)" ///
           as result _col(22) %10.3f `os_Ep' _col(35) %8.3f `os_Ep_se' ///
           as text   _col(55) "{c -}" _col(66) "{c -}"

        di as text _col(5) "`av'-(t-1)" ///
           as result _col(22) %10.3f `os_En' _col(35) %8.3f `os_En_se' ///
           as text   _col(55) "{c -}" _col(66) "{c -}"
    }

    // ==== Row: ECM_{t-1} - two-step only ====
    local ts_ecm    = `ts_b'[1, 1]
    local ts_ecm_se = sqrt(`ts_V'[1, 1])

    di as text _col(5) "ECM(t-1)" ///
       as text   _col(27) "{c -}" _col(40) "{c -}" ///
       as result _col(50) %10.3f `ts_ecm' _col(63) %8.3f `ts_ecm_se'

    di as text _col(5) "{hline 68}"

    // ==== SR dynamic rows ====
    // One-step: indices os_levels+1 to os_n_sr-1 (skip _cons at end)
    // Two-step: indices 2 to ts_n_sr-1 (skip ECM at 1 and _cons at end)
    local os_sr_start = `os_levels' + 1
    local os_sr_end   = `os_n_sr' - 1
    local ts_sr_start = 2
    local ts_sr_end   = `ts_n_sr' - 1

    local n_sr_rows = `os_sr_end' - `os_sr_start' + 1

    forvalues r = 1/`n_sr_rows' {
        local os_idx = `os_sr_start' + `r' - 1
        local ts_idx = `ts_sr_start' + `r' - 1

        // Get variable name and clean it
        local vname : word `os_idx' of `os_srnames'
        local cname = subinstr("`vname'", "_xpos_nardl_", "x+", .)
        local cname = subinstr("`cname'", "_xneg_nardl_", "x-", .)

        if regexm("`cname'", "^L([0-9]*)D\.(.+)$") {
            local lag_num = regexs(1)
            local rest    = regexs(2)
            if "`lag_num'" == "" local lag_num "1"
            local dname "d`rest'(t-`lag_num')"
        }
        else if regexm("`cname'", "^D\.(.+)$") {
            local rest = regexs(1)
            local dname "d`rest'"
        }
        else {
            local dname "`cname'"
        }

        local os_c = `os_b'[1, `os_idx']
        local os_s = sqrt(`os_V'[`os_idx', `os_idx'])

        if `ts_idx' <= `ts_sr_end' {
            local ts_c = `ts_b'[1, `ts_idx']
            local ts_s = sqrt(`ts_V'[`ts_idx', `ts_idx'])

            di as text _col(5) "`dname'" ///
               as result _col(22) %10.3f `os_c' _col(35) %8.3f `os_s' ///
               as result _col(50) %10.3f `ts_c' _col(63) %8.3f `ts_s'
        }
        else {
            di as text _col(5) "`dname'" ///
               as result _col(22) %10.3f `os_c' _col(35) %8.3f `os_s' ///
               as text   _col(55) "{c -}" _col(66) "{c -}"
        }
    }

    // ==== Diagnostics footer ====
    di as text "{hline `w'}"
    di as text _col(5) "Adjusted R{sup:2}" ///
       as result _col(22) %10.3f `os_r2a' ///
       as result _col(50) %10.3f `ts_r2a'

    if `os_bgp' < . | `ts_bgp' < . {
        di as text _col(5) "X{sup:2}(S.Corr.) [p]" _c
        if `os_bgp' < . {
            di as result _col(22) %10.3f `os_bgp' _c
        }
        else {
            di as text _col(27) "{c -}" _c
        }
        if `ts_bgp' < . {
            di as result _col(50) %10.3f `ts_bgp'
        }
        else {
            di as text _col(55) "{c -}"
        }
    }

    if `os_htp' < . | `ts_htp' < . {
        di as text _col(5) "X{sup:2}(Hetero.) [p]" _c
        if `os_htp' < . {
            di as result _col(22) %10.3f `os_htp' _c
        }
        else {
            di as text _col(27) "{c -}" _c
        }
        if `ts_htp' < . {
            di as result _col(50) %10.3f `ts_htp'
        }
        else {
            di as text _col(55) "{c -}"
        }
    }

    di as text "{hline `w'}"
    di as text _col(3) "Table reports parameter estimates for the NARDL model in ECM form."
    di as text _col(3) "One-step: single-equation OLS (SYG 2014). Two-step: `step1u'"
    di as text _col(3) "in step 1, OLS in step 2 (CGS 2020). {c -} denotes not applicable."
    di as text _col(3) "X{sup:2}(S.Corr.): BG LM p-value. X{sup:2}(Hetero.): White test p-value."
    di as text "{hline `w'}"

end




