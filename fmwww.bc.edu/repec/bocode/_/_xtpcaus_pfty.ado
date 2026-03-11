*! _xtpcaus_pfty v1.0.3
*! Panel Fourier Toda-Yamamoto Causality Test
*! Based on: Yilanci & Gorus (2020), Eq.(3)-(5)
*!           Emirmahmutoglu & Kose (2011), Fisher panel stat
*!           Nazlioglu et al. (2016), Fourier TY bootstrap
*!           Toda & Yamamoto (1995)
*!           Dumitrescu & Hurlin (2012), Z-bar / Z-bar-tilde

capture program drop _xtpcaus_pfty
program define _xtpcaus_pfty, eclass
    version 14
    syntax varlist(min=2 max=2 ts) [if] [in], ///
        PANELvar(varname) TIMEvar(varname) ///
        PMAX(integer) DMAX(integer) KMAX(integer) ///
        IC(string) NBOOT(integer) ///
        Npanels(integer) Tperiods(integer) TMIN(integer) TMAX(integer) ///
        Level(integer) SCHeme(string) ///
        [NOGRaph NOTABle]

    marksample touse
    tokenize `varlist'
    local depvar   `1'
    local indepvar `2'

    local mypi = c(pi)

    // ── Panel units ───────────────────────────────────────────────
    qui levelsof `panelvar' if `touse', local(idlist)
    local N_units : word count `idlist'

    // ── Pre-generate all lagged variables ─────────────────────────
    // Use a cleanup-safe prefix instead of tempvar inside loops
    local maxlag = `pmax' + `dmax'
    local Ldep_list ""
    local Lind_list ""
    forval ll = 1/`maxlag' {
        cap drop _pftyd`ll'
        cap drop _pftyi`ll'
        qui gen double _pftyd`ll' = L`ll'.`depvar' if `touse'
        qui gen double _pftyi`ll' = L`ll'.`indepvar' if `touse'
        local Ldep_list "`Ldep_list' _pftyd`ll'"
        local Lind_list "`Lind_list' _pftyi`ll'"
    }

    // ── Pre-generate Fourier terms ────────────────────────────────
    cap drop _pftytrend
    qui gen double _pftytrend = `timevar' - `tmin' + 1 if `touse'
    local TT = `tperiods'
    local sint_list ""
    local cost_list ""
    forval f = 1/`kmax' {
        cap drop _pftys`f'
        cap drop _pftyc`f'
        qui gen double _pftys`f' = sin(2 * `mypi' * `f' * (_pftytrend / `TT')) if `touse'
        qui gen double _pftyc`f' = cos(2 * `mypi' * `f' * (_pftytrend / `TT')) if `touse'
        local sint_list "`sint_list' _pftys`f'"
        local cost_list "`cost_list' _pftyc`f'"
    }

    // ── Initialize result matrices ────────────────────────────────
    tempname Wald Freq Pval_a Pval_b Lags
    mat `Wald'   = J(`N_units', 1, .)
    mat `Freq'   = J(`N_units', 1, .)
    mat `Pval_a' = J(`N_units', 1, .)
    mat `Pval_b' = J(`N_units', 1, .)
    mat `Lags'   = J(`N_units', 1, .)

    local rnames ""
    foreach i of local idlist {
        local rnames "`rnames' u`i'"
    }
    mat rownames `Wald'   = `rnames'
    mat rownames `Freq'   = `rnames'
    mat rownames `Pval_a' = `rnames'
    mat rownames `Pval_b' = `rnames'
    mat rownames `Lags'   = `rnames'

    // ── Progress ──────────────────────────────────────────────────
    di ""
    di as txt "  Panel Fourier Toda-Yamamoto: running individual tests..."
    di as txt "  Panels: " as res `N_units' as txt "   T: " as res `TT' as txt "   Bootstrap reps: " as res `nboot'
    di as txt "  {hline 60}"

    // ── Individual FTY tests (Eq. 3 of Yilanci 2020) ─────────────
    local j = 0
    foreach i of local idlist {
        local ++j
        di as txt "    Panel `panelvar'=`i' (`j'/`N_units') ..." _continue

        // --- Select optimal lag p and frequency f ---
        local best_ic = 1e15
        local p_opt = 1
        local f_opt = 1

        forval f = 1/`kmax' {
            forval pp = 1/`pmax' {
                local plg = `pp' + `dmax'
                if `TT' <= `plg' + 5 continue

                // Build var lists
                local xvars ""
                forval ll = 1/`plg' {
                    local xvars "`xvars' _pftyd`ll' _pftyi`ll'"
                }

                capture qui reg `depvar' `xvars' _pftys`f' _pftyc`f' if `panelvar' == `i' & `touse'
                if _rc continue
                if e(N) < `plg' + 5 continue

                local nobs = e(N)
                local nk   = e(df_model) + 1
                local rss  = e(rss)
                if "`ic'" == "aic" {
                    local icv = log(`rss'/`nobs') + 2*`nk'/`nobs'
                }
                else {
                    local icv = log(`rss'/`nobs') + `nk'*log(`nobs')/`nobs'
                }
                if `icv' < `best_ic' {
                    local best_ic = `icv'
                    local p_opt = `pp'
                    local f_opt = `f'
                }
            }
        }

        mat `Lags'[`j', 1] = `p_opt'
        mat `Freq'[`j', 1] = `f_opt'

        // --- Full model VAR(k+dmax) with Fourier ---
        local plg = `p_opt' + `dmax'
        local xvars_full ""
        forval ll = 1/`plg' {
            local xvars_full "`xvars_full' _pftyd`ll' _pftyi`ll'"
        }

        local test_vars ""
        forval ll = 1/`p_opt' {
            local test_vars "`test_vars' _pftyi`ll'"
        }

        capture qui reg `depvar' `xvars_full' _pftys`f_opt' _pftyc`f_opt' if `panelvar' == `i' & `touse'
        if _rc {
            di as txt " skipped"
            continue
        }

        // Wald test
        local first = 1
        foreach tv of local test_vars {
            if `first' {
                qui test `tv'
                local first = 0
            }
            else {
                qui test `tv', accum
            }
        }
        local F_stat = r(F)
        local W_i    = `p_opt' * `F_stat'
        if missing(`W_i') local W_i = 0
        local pa_i   = 1 - chi2(`p_opt', max(`W_i', 0))

        mat `Wald'[`j', 1]   = `W_i'
        mat `Pval_a'[`j', 1] = `pa_i'

        // --- Bootstrap p-value ---
        local xvars_rest ""
        forval ll = 1/`plg' {
            local xvars_rest "`xvars_rest' _pftyd`ll'"
        }
        forval ll = `=`p_opt'+1'/`plg' {
            local xvars_rest "`xvars_rest' _pftyi`ll'"
        }

        capture qui reg `depvar' `xvars_rest' _pftys`f_opt' _pftyc`f_opt' if `panelvar' == `i' & `touse'
        if _rc {
            mat `Pval_b'[`j', 1] = `pa_i'
            di as txt " done (asymp)"
            continue
        }

        cap drop _pftyh0yh _pftyh0re _pftyboot _pftysel
        qui predict double _pftyh0yh if `panelvar' == `i' & `touse', xb
        qui gen double _pftyh0re = `depvar' - _pftyh0yh if `panelvar' == `i' & `touse'
        qui summ _pftyh0re if `panelvar' == `i' & `touse', meanonly
        qui replace _pftyh0re = _pftyh0re - r(mean) if `panelvar' == `i' & `touse'
        qui gen double _pftyboot = . if `panelvar' == `i' & `touse'
        qui gen byte _pftysel = (`panelvar' == `i' & `touse' & !missing(_pftyh0re))

        mata: st_view(__pf_r = ., ., "_pftyh0re", "_pftysel")
        mata: st_view(__pf_yh = ., ., "_pftyh0yh", "_pftysel")
        mata: __pf_nr = rows(__pf_r)

        local Wboot_ge = 0
        forval b = 1/`nboot' {
            mata: __pf_idx = ceil(__pf_nr :* runiform(__pf_nr, 1))
            mata: __pf_es = __pf_r[__pf_idx, .]
            mata: __pf_es = __pf_es :- mean(__pf_es)
            mata: __pf_ys = __pf_yh + __pf_es
            mata: st_store(., "_pftyboot", "_pftysel", __pf_ys)

            capture qui reg _pftyboot `xvars_full' _pftys`f_opt' _pftyc`f_opt' if `panelvar' == `i' & `touse'
            if _rc continue

            local Wb = 0
            capture {
                local ff = 1
                foreach tv of local test_vars {
                    if `ff' {
                        qui test `tv'
                        local ff = 0
                    }
                    else {
                        qui test `tv', accum
                    }
                }
                local Wb = `p_opt' * r(F)
            }
            if missing(`Wb') local Wb = 0
            if `Wb' >= `W_i' local Wboot_ge = `Wboot_ge' + 1
        }

        capture mata: mata drop __pf_r __pf_yh __pf_nr __pf_idx __pf_es __pf_ys

        local pb_i = `Wboot_ge' / `nboot'
        mat `Pval_b'[`j', 1] = `pb_i'

        cap drop _pftyh0yh _pftyh0re _pftyboot _pftysel
        di as txt " W=" as res %7.3f `W_i' as txt " f=" as res `f_opt' as txt " p=" as res %5.3f `pb_i'
    }

    // ── Cleanup generated variables ───────────────────────────────
    forval ll = 1/`maxlag' {
        cap drop _pftyd`ll' _pftyi`ll'
    }
    cap drop _pftytrend
    forval f = 1/`kmax' {
        cap drop _pftys`f' _pftyc`f'
    }
    cap drop _pftyh0yh _pftyh0re _pftyboot _pftysel

    // ── Panel Fisher statistic (Eq. 5: FTYP = -2 Σ ln(p*_i)) ────
    local fisher = 0
    local n_valid = 0
    forval j = 1/`N_units' {
        local pb = `Pval_b'[`j', 1]
        if !missing(`pb') & `pb' > 0 & `pb' < 1 {
            local fisher = `fisher' + (-2 * ln(`pb'))
            local ++n_valid
        }
        else if !missing(`pb') & `pb' == 0 {
            local fisher = `fisher' + (-2 * ln(0.5/`nboot'))
            local ++n_valid
        }
    }
    local fisher_df = 2 * `n_valid'
    if `fisher_df' > 0 {
        local fisher_pv = chi2tail(`fisher_df', `fisher')
    }
    else {
        local fisher_pv = .
    }

    // ── DH Z-bar and Z-bar-tilde ──────────────────────────────────
    local wbar = 0
    local K_sum = 0
    forval j = 1/`N_units' {
        local w_j = `Wald'[`j', 1]
        local k_j = `Lags'[`j', 1]
        if !missing(`w_j') {
            local wbar = `wbar' + `w_j'
            local K_sum = `K_sum' + `k_j'
        }
    }
    local wbar = `wbar' / `N_units'
    local K_avg = max(round(`K_sum' / `N_units'), 1)

    local zbar = sqrt(`N_units' / (2 * `K_avg')) * (`wbar' - `K_avg')
    local zbar_pv = 2 * (1 - normal(abs(`zbar')))
    local TK = `TT' - `K_avg'
    if `TK' > 2*`K_avg' + 5 {
        local zbart = sqrt(`N_units' / (2*`K_avg') * (`TK'-2*`K_avg'-5) / (`TK'-`K_avg'-3)) * ((`TK'-2*`K_avg'-3) / (`TK'-2*`K_avg'-1) * `wbar' - `K_avg')
    }
    else {
        local zbart = .
    }
    local zbart_pv = 2 * (1 - normal(abs(`zbart')))

    // ── Display ───────────────────────────────────────────────────
    if "`notable'" == "" {
        _xtpcaus_pfty_table "`depvar'" "`indepvar'" "`panelvar'" ///
            `N_units' `TT' `nboot' `fisher' `fisher_df' `fisher_pv' ///
            `wbar' `zbar' `zbar_pv' `zbart' `zbart_pv' ///
            `Wald' `Freq' `Pval_a' `Pval_b' `Lags'
    }

    if "`nograph'" == "" {
        _xtpcaus_pfty_graph "`depvar'" "`indepvar'" "`panelvar'" ///
            `N_units' `Wald' `Pval_b' `Freq' "`scheme'" "`idlist'"
    }

    // ── Store results ─────────────────────────────────────────────
    ereturn clear
    ereturn matrix wald   = `Wald'
    ereturn matrix freq   = `Freq'
    ereturn matrix pval_a = `Pval_a'
    ereturn matrix pval_b = `Pval_b'
    ereturn matrix lags   = `Lags'
    ereturn scalar fisher    = `fisher'
    ereturn scalar fisher_df = `fisher_df'
    ereturn scalar fisher_pv = `fisher_pv'
    ereturn scalar wbar      = `wbar'
    ereturn scalar zbar      = `zbar'
    ereturn scalar zbar_pv   = `zbar_pv'
    ereturn scalar zbart     = `zbart'
    ereturn scalar zbart_pv  = `zbart_pv'

end


// ══════════════════════════════════════════════════════════════════
// TABLE
// ══════════════════════════════════════════════════════════════════
capture program drop _xtpcaus_pfty_table
program define _xtpcaus_pfty_table
    args depvar indepvar panelvar N T nboot fisher fisher_df fisher_pv ///
         wbar zbar zbar_pv zbart zbart_pv W FR PA PB LG

    di ""
    di as txt "  {hline 72}"
    di as txt "  Panel Fourier Toda-Yamamoto Causality Test"
    di as txt "  {hline 72}"
    di as txt "  H0: {bf:`indepvar'} does not Granger-cause {bf:`depvar'}"
    di as txt "  Panels (N): " as res `N' as txt "    Periods (T): " as res `T' as txt "    Bootstrap: " as res `nboot'
    di as txt "  {hline 72}"
    di as txt _col(3) %-16s "Panel" ///
       _col(20) %9s  "Wald" ///
       _col(30) %5s  "Freq" ///
       _col(36) %9s  "Asym.p" ///
       _col(46) %9s  "Boot.p" ///
       _col(56) %5s  "Sig." ///
       _col(62) %3s  "Lag"
    di as txt "  {hline 72}"

    local nr = rowsof(`W')
    local rn : rownames `W'
    forval r = 1/`nr' {
        local h : word `r' of `rn'
        local w  = `W'[`r', 1]
        local fr = `FR'[`r', 1]
        local pa = `PA'[`r', 1]
        local pb = `PB'[`r', 1]
        local lg = `LG'[`r', 1]
        local st = cond(`pb' < 0.01, "***", cond(`pb' < 0.05, "**", cond(`pb' < 0.10, "*", "")))

        di as txt _col(3) %-16s "`h'" ///
           as res _col(20) %9.3f `w' ///
           as txt _col(30) %5.0f `fr' ///
                  _col(36) %9.3f `pa' ///
           as res _col(46) %9.3f `pb' ///
                  _col(56) "`st'" ///
           as txt _col(62) %3.0f `lg'
    }

    di as txt "  {hline 72}"

    local fst = cond(`fisher_pv' < 0.01, "***", cond(`fisher_pv' < 0.05, "**", cond(`fisher_pv' < 0.10, "*", "")))
    di as res _col(3) "PFTY (Fisher)" ///
       as res _col(20) %9.3f `fisher' ///
       as txt _col(46) %9.3f `fisher_pv' ///
       as res _col(56) "`fst'"

    di as txt _col(3) "W-bar" ///
       as res _col(20) %9.4f `wbar'
    di as txt _col(3) "Z-bar" ///
       as res _col(20) %9.4f `zbar' ///
       as txt _col(36) %9.4f `zbar_pv'
    di as txt _col(3) "Z-bar tilde" ///
       as res _col(20) %9.4f `zbart' ///
       as txt _col(36) %9.4f `zbart_pv'

    di as txt "  {hline 72}"
    di as txt _col(3) "*p<0.10, **p<0.05, ***p<0.01 (bootstrap)"
    di ""
end


// ══════════════════════════════════════════════════════════════════
// GRAPH
// ══════════════════════════════════════════════════════════════════
capture program drop _xtpcaus_pfty_graph
program define _xtpcaus_pfty_graph
    args depvar indepvar panelvar N_units W PB FR scheme idlist

    preserve
    qui drop _all

    local nr = rowsof(`W')
    qui set obs `nr'
    qui gen panel_id = _n
    qui gen str30 panel_name = ""
    qui gen double wald_stat = .
    qui gen double boot_pval = .
    qui gen double freq = .

    local rn : rownames `W'
    forval r = 1/`nr' {
        local h : word `r' of `rn'
        qui replace panel_name = "`h'" in `r'
        qui replace wald_stat  = `W'[`r', 1] in `r'
        qui replace boot_pval  = `PB'[`r', 1] in `r'
        qui replace freq       = `FR'[`r', 1] in `r'
    }

    qui gen byte sig_level = cond(boot_pval < 0.01, 3, cond(boot_pval < 0.05, 2, cond(boot_pval < 0.10, 1, 0)))

    twoway ///
        (bar wald_stat panel_id if sig_level == 3, fcolor(cranberry%80) lcolor(cranberry)) ///
        (bar wald_stat panel_id if sig_level == 2, fcolor(orange%70) lcolor(orange)) ///
        (bar wald_stat panel_id if sig_level == 1, fcolor(gold%60) lcolor(gold)) ///
        (bar wald_stat panel_id if sig_level == 0, fcolor(gs12%50) lcolor(gs10)) ///
        , ///
        xlabel(1(1)`nr', valuelabel angle(45) labsize(vsmall)) ///
        xtitle("Panel Unit", size(small)) ///
        ytitle("Wald Statistic", size(small)) ///
        title("PFTY Individual Wald Statistics", size(medsmall)) ///
        subtitle("H0: `indepvar' does not cause `depvar'", size(small) color(gs6)) ///
        legend(order(1 "p<0.01" 2 "p<0.05" 3 "p<0.10" 4 "p>=0.10") ///
               rows(1) size(vsmall) position(6)) ///
        yline(3.841, lcolor(red%50) lwidth(thin) lpattern(dash)) ///
        note("Dashed: Chi2(1) 5% cv", size(vsmall)) ///
        scheme(`scheme') name(pfty_wald, replace)

    twoway ///
        (bar boot_pval panel_id, fcolor(navy%40) lcolor(navy)) ///
        (scatter boot_pval panel_id, mcolor(navy) msymbol(circle) msize(small)) ///
        , ///
        xlabel(1(1)`nr', valuelabel angle(45) labsize(vsmall)) ///
        xtitle("Panel Unit", size(small)) ///
        ytitle("Bootstrap p-value", size(small)) ///
        title("PFTY Bootstrap p-values", size(medsmall)) ///
        subtitle("H0: `indepvar' does not cause `depvar'", size(small) color(gs6)) ///
        yline(0.05, lcolor(red%70) lwidth(thin) lpattern(dash)) ///
        yline(0.10, lcolor(orange%70) lwidth(thin) lpattern(shortdash)) ///
        yscale(range(0 1)) ylabel(0(0.1)1, format(%3.1f)) ///
        note("Red: 5% | Orange: 10%", size(vsmall)) ///
        legend(off) ///
        scheme(`scheme') name(pfty_pval, replace)

    di ""
    di as txt "  Graphs: {cmd:graph display pfty_wald} | {cmd:graph display pfty_pval}"

    restore
end
