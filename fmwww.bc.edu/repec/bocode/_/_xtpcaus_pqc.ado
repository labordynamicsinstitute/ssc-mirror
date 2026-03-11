*! _xtpcaus_pqc v1.0.1
*! Panel Quantile Causality Test
*! Based on: Wang & Nguyen (2022), Eq.(2)-(7)
*!           Chuang, Kuan, Lin (2009), Sup-Wald theory
*!           Koenker & Machado (1999), Wald process
*!           Koenker & Bassett (1978), Quantile Regression

capture program drop _xtpcaus_pqc
program define _xtpcaus_pqc, eclass
    version 14
    syntax varlist(min=2 max=2 ts) [if] [in], ///
        PANELvar(varname) TIMEvar(varname) ///
        PMAX(integer) DMAX(integer) ///
        NBOOT(integer) Quantiles(numlist) ///
        Npanels(integer) Tperiods(integer) TMIN(integer) TMAX(integer) ///
        Level(integer) SCHeme(string) ///
        [NOGRaph NOTABle]

    marksample touse
    tokenize `varlist'
    local depvar   `1'
    local indepvar `2'

    local nq : word count `quantiles'

    // ── Step 1: Select optimal lag via pooled OLS (AIC) ──────────
    // Wang & Nguyen (2022): "AIC determines the optimal lag order"
    local best_ic = 1e15
    local p_opt = 1

    // Generate panel dummies for fixed effects
    tempvar gid
    qui egen `gid' = group(`panelvar') if `touse'
    qui summ `gid' if `touse', meanonly
    local n_groups = r(max)

    // tsrevar for qreg compatibility
    forval p = 1/`pmax' {
        local dlags ""
        local ilags ""
        forval l = 1/`p' {
            local dlags "`dlags' L`l'.`depvar'"
            local ilags "`ilags' L`l'.`indepvar'"
        }
        qui tsrevar `dlags' `ilags'
        local tmpv `r(varlist)'

        capture qui reg `depvar' `tmpv' i.`gid' if `touse'
        if _rc continue
        local nobs = e(N)
        local nk = e(df_model) + 1
        local rss = e(rss)
        local aic = log(`rss'/`nobs') + 2*`nk'/`nobs'
        if `aic' < `best_ic' {
            local best_ic = `aic'
            local p_opt = `p'
        }
    }

    di ""
    di as txt "  Panel Quantile Causality: optimal lag = " as res `p_opt'
    di as txt "  Quantiles: `quantiles'"
    di as txt "  Bootstrap reps: `nboot'"

    // ── Build permanent regressor lists ──────────────────────────
    // Panel quantile VAR model Eq.(2) of Wang & Nguyen (2022):
    // Q_{y_it}(τ | Y_{i,t-1}) = β_{01i}(τ) + Σ β_{11,ij}(τ) y_{i,t-j}
    //                          + Σ β_{12,ij}(τ) x_{i,t-j}

    local dep_tsop ""
    local cause_tsop ""
    forval l = 1/`p_opt' {
        local dep_tsop   "`dep_tsop' L`l'.`depvar'"
        local cause_tsop "`cause_tsop' L`l'.`indepvar'"
    }
    qui tsrevar `dep_tsop' `cause_tsop'
    local all_tmp `r(varlist)'

    // Split
    local dep_tmp ""
    forval idx = 1/`p_opt' {
        local v : word `idx' of `all_tmp'
        local dep_tmp "`dep_tmp' `v'"
    }
    local cause_tmp ""
    forval idx = `=`p_opt'+1'/`=2*`p_opt'' {
        local v : word `idx' of `all_tmp'
        local cause_tmp "`cause_tmp' `v'"
    }

    // Panel dummies for fixed effects (country-specific intercepts β_{01i}(τ))
    local pdummies "i.`gid'"

    // Full model: dep_tmp + cause_tmp + panel_dummies
    // Restricted model: dep_tmp + panel_dummies (no cause vars)

    // ── Initialize result matrices ───────────────────────────────
    tempname Wq Coefq PBq WqR CoefqR PBqR
    mat `Wq'    = J(1, `nq', .)
    mat `Coefq' = J(1, `nq', .)
    mat `PBq'   = J(1, `nq', .)
    mat `WqR'   = J(1, `nq', .)
    mat `CoefqR'= J(1, `nq', .)
    mat `PBqR'  = J(1, `nq', .)

    local qcols ""
    foreach tau of local quantiles {
        local qs = subinstr("`tau'", ".", "p", .)
        local qcols "`qcols' `qs'"
    }
    mat colnames `Wq'    = `qcols'
    mat colnames `Coefq' = `qcols'
    mat colnames `PBq'   = `qcols'
    mat colnames `WqR'   = `qcols'
    mat colnames `CoefqR'= `qcols'
    mat colnames `PBqR'  = `qcols'

    // ══════════════════════════════════════════════════════════════
    // Direction 1: indepvar => depvar   (Eq. 2 of Wang & Nguyen)
    // ══════════════════════════════════════════════════════════════
    di as txt "  {hline 60}"
    di as txt "  Testing: `indepvar' => `depvar' ..."

    local qq = 0
    foreach tau of local quantiles {
        local ++qq
        di as txt "    tau = `tau' ..." _continue

        // Full quantile regression with panel dummies
        capture qui qreg `depvar' `dep_tmp' `cause_tmp' `pdummies' if `touse', quantile(`tau')
        if _rc {
            mat `Wq'[1, `qq']    = .
            mat `Coefq'[1, `qq'] = .
            mat `PBq'[1, `qq']   = .
            di as txt " failed"
            continue
        }

        // Sum of cause coefficients (Eq. 5 of Wang & Nguyen)
        local coef_sum = 0
        forval ii = 1/`p_opt' {
            local cv : word `ii' of `cause_tmp'
            local coef_sum = `coef_sum' + _b[`cv']
        }
        mat `Coefq'[1, `qq'] = `coef_sum'

        // Wald test for H0: β_{12}(τ) = 0
        local first = 1
        foreach cv of local cause_tmp {
            if `first' {
                qui test `cv'
                local first = 0
            }
            else {
                qui test `cv', accum
            }
        }
        local W_obs = `p_opt' * r(F)
        if missing(`W_obs') | `W_obs' < 0 local W_obs = 0
        mat `Wq'[1, `qq'] = `W_obs'

        // Bootstrap p-value
        capture qui qreg `depvar' `dep_tmp' `pdummies' if `touse', quantile(`tau')
        if _rc {
            mat `PBq'[1, `qq'] = .
            di as txt " (no boot)"
            continue
        }
        cap drop _pqcyh1 _pqcre1 _pqcys1 _pqcsel1
        qui predict double _pqcyh1 if `touse', xb
        qui gen double _pqcre1 = `depvar' - _pqcyh1 if `touse'
        qui summ _pqcre1 if `touse', meanonly
        qui replace _pqcre1 = _pqcre1 - r(mean) if `touse'
        qui gen double _pqcys1 = `depvar' if `touse'
        qui gen byte _pqcsel1 = (`touse' & !missing(_pqcyh1))

        local Wboot_ge = 0
        mata: st_view(__pqc_er = ., ., "_pqcre1", "_pqcsel1")
        mata: st_view(__pqc_yh = ., ., "_pqcyh1", "_pqcsel1")
        mata: __pqc_nr = rows(__pqc_er)

        forval b = 1/`nboot' {
            mata: __pqc_idx = ceil(__pqc_nr :* runiform(__pqc_nr, 1))
            mata: __pqc_es = __pqc_er[__pqc_idx, .]
            mata: __pqc_es = __pqc_es :- mean(__pqc_es)
            mata: __pqc_ys = __pqc_yh + __pqc_es
            mata: st_store(., "_pqcys1", "_pqcsel1", __pqc_ys)

            capture qui qreg _pqcys1 `dep_tmp' `cause_tmp' `pdummies' if `touse', quantile(`tau')
            if _rc continue

            local Wb = 0
            capture {
                local first3 = 1
                foreach cv of local cause_tmp {
                    if `first3' {
                        qui test `cv'
                        local first3 = 0
                    }
                    else {
                        qui test `cv', accum
                    }
                }
                local Wb = `p_opt' * r(F)
            }
            if missing(`Wb') | `Wb' < 0 local Wb = 0
            if `Wb' >= `W_obs' local Wboot_ge = `Wboot_ge' + 1
        }

        capture mata: mata drop __pqc_er __pqc_yh __pqc_nr __pqc_idx __pqc_es __pqc_ys

        mat `PBq'[1, `qq'] = `Wboot_ge' / `nboot'
        cap drop _pqcyh1 _pqcre1 _pqcys1 _pqcsel1
        di as txt " W=" as res %7.3f `W_obs' as txt " p=" as res %5.3f `=`Wboot_ge'/`nboot''
    }

    // ══════════════════════════════════════════════════════════════
    // Direction 2: depvar => indepvar   (Eq. 3 of Wang & Nguyen)
    // ══════════════════════════════════════════════════════════════
    di as txt "  Testing: `depvar' => `indepvar' ..."

    // Reverse: now indepvar is the dependent variable
    local dep_tsop_r ""
    local cause_tsop_r ""
    forval l = 1/`p_opt' {
        local dep_tsop_r   "`dep_tsop_r' L`l'.`indepvar'"
        local cause_tsop_r "`cause_tsop_r' L`l'.`depvar'"
    }
    qui tsrevar `dep_tsop_r' `cause_tsop_r'
    local all_tmp_r `r(varlist)'

    local dep_tmp_r ""
    forval idx = 1/`p_opt' {
        local v : word `idx' of `all_tmp_r'
        local dep_tmp_r "`dep_tmp_r' `v'"
    }
    local cause_tmp_r ""
    forval idx = `=`p_opt'+1'/`=2*`p_opt'' {
        local v : word `idx' of `all_tmp_r'
        local cause_tmp_r "`cause_tmp_r' `v'"
    }

    local qq = 0
    foreach tau of local quantiles {
        local ++qq
        di as txt "    tau = `tau' ..." _continue

        capture qui qreg `indepvar' `dep_tmp_r' `cause_tmp_r' `pdummies' if `touse', quantile(`tau')
        if _rc {
            mat `WqR'[1, `qq']    = .
            mat `CoefqR'[1, `qq'] = .
            mat `PBqR'[1, `qq']   = .
            di as txt " failed"
            continue
        }

        local coef_sum = 0
        forval ii = 1/`p_opt' {
            local cv : word `ii' of `cause_tmp_r'
            local coef_sum = `coef_sum' + _b[`cv']
        }
        mat `CoefqR'[1, `qq'] = `coef_sum'

        local first = 1
        foreach cv of local cause_tmp_r {
            if `first' {
                qui test `cv'
                local first = 0
            }
            else {
                qui test `cv', accum
            }
        }
        local W_obs2 = `p_opt' * r(F)
        if missing(`W_obs2') | `W_obs2' < 0 local W_obs2 = 0
        mat `WqR'[1, `qq'] = `W_obs2'

        // Bootstrap for reverse direction
        capture qui qreg `indepvar' `dep_tmp_r' `pdummies' if `touse', quantile(`tau')
        if _rc {
            mat `PBqR'[1, `qq'] = .
            di as txt " (no boot)"
            continue
        }
        cap drop _pqcyh2 _pqcre2 _pqcys2 _pqcsel2
        qui predict double _pqcyh2 if `touse', xb
        qui gen double _pqcre2 = `indepvar' - _pqcyh2 if `touse'
        qui summ _pqcre2 if `touse', meanonly
        qui replace _pqcre2 = _pqcre2 - r(mean) if `touse'
        qui gen double _pqcys2 = `indepvar' if `touse'
        qui gen byte _pqcsel2 = (`touse' & !missing(_pqcyh2))

        local Wboot_ge2 = 0
        mata: st_view(__pqc_er2 = ., ., "_pqcre2", "_pqcsel2")
        mata: st_view(__pqc_yh2 = ., ., "_pqcyh2", "_pqcsel2")
        mata: __pqc_nr2 = rows(__pqc_er2)

        forval b = 1/`nboot' {
            mata: __pqc_idx2 = ceil(__pqc_nr2 :* runiform(__pqc_nr2, 1))
            mata: __pqc_es2 = __pqc_er2[__pqc_idx2, .]
            mata: __pqc_es2 = __pqc_es2 :- mean(__pqc_es2)
            mata: __pqc_ys2 = __pqc_yh2 + __pqc_es2
            mata: st_store(., "_pqcys2", "_pqcsel2", __pqc_ys2)

            capture qui qreg _pqcys2 `dep_tmp_r' `cause_tmp_r' `pdummies' if `touse', quantile(`tau')
            if _rc continue

            local Wb2 = 0
            capture {
                local first4 = 1
                foreach cv of local cause_tmp_r {
                    if `first4' {
                        qui test `cv'
                        local first4 = 0
                    }
                    else {
                        qui test `cv', accum
                    }
                }
                local Wb2 = `p_opt' * r(F)
            }
            if missing(`Wb2') | `Wb2' < 0 local Wb2 = 0
            if `Wb2' >= `W_obs2' local Wboot_ge2 = `Wboot_ge2' + 1
        }

        capture mata: mata drop __pqc_er2 __pqc_yh2 __pqc_nr2 __pqc_idx2 __pqc_es2 __pqc_ys2

        mat `PBqR'[1, `qq'] = `Wboot_ge2' / `nboot'
        cap drop _pqcyh2 _pqcre2 _pqcys2 _pqcsel2
        di as txt " W=" as res %7.3f `W_obs2' as txt " p=" as res %5.3f `=`Wboot_ge2'/`nboot''
    }

    // ── Sup-Wald statistics (Eq. 7 of Wang & Nguyen / Chuang 2009) ──
    local supW1 = 0
    local supW2 = 0
    forval qq = 1/`nq' {
        local w1 = `Wq'[1, `qq']
        local w2 = `WqR'[1, `qq']
        if !missing(`w1') & `w1' > `supW1' local supW1 = `w1'
        if !missing(`w2') & `w2' > `supW2' local supW2 = `w2'
    }

    // Critical values from Chuang (2009) Table 1 for [0.05, 0.95]
    // q=1: 13.01(1%), 9.84(5%), 8.19(10%)
    // q=2: 16.30(1%), 12.77(5%), 11.05(10%)
    // q=3: 19.21(1%), 15.28(5%), 13.49(10%)
    local cv_01 = cond(`p_opt' <= 1, 13.01, cond(`p_opt' == 2, 16.30, 19.21))
    local cv_05 = cond(`p_opt' <= 1,  9.84, cond(`p_opt' == 2, 12.77, 15.28))
    local cv_10 = cond(`p_opt' <= 1,  8.19, cond(`p_opt' == 2, 11.05, 13.49))

    // ── Display results ──────────────────────────────────────────
    if "`notable'" == "" {
        _xtpcaus_pqc_table "`depvar'" "`indepvar'" "`panelvar'" ///
            `npanels' `tperiods' `nboot' `p_opt' `nq' "`quantiles'" ///
            `supW1' `supW2' `cv_01' `cv_05' `cv_10' ///
            `Wq' `Coefq' `PBq' `WqR' `CoefqR' `PBqR'
    }

    // ── Graphs ───────────────────────────────────────────────────
    if "`nograph'" == "" {
        _xtpcaus_pqc_graph "`depvar'" "`indepvar'" `nq' "`quantiles'" ///
            `Wq' `Coefq' `PBq' `WqR' `CoefqR' `PBqR' ///
            `cv_05' "`scheme'"
    }

    // ── Store results ────────────────────────────────────────────
    ereturn clear
    ereturn matrix wald_xy   = `Wq'
    ereturn matrix coef_xy   = `Coefq'
    ereturn matrix pval_xy   = `PBq'
    ereturn matrix wald_yx   = `WqR'
    ereturn matrix coef_yx   = `CoefqR'
    ereturn matrix pval_yx   = `PBqR'
    ereturn scalar supwald_xy = `supW1'
    ereturn scalar supwald_yx = `supW2'
    ereturn scalar cv_01      = `cv_01'
    ereturn scalar cv_05      = `cv_05'
    ereturn scalar cv_10      = `cv_10'
    ereturn scalar p_opt      = `p_opt'

end


// ══════════════════════════════════════════════════════════════════
// TABLE DISPLAY
// ══════════════════════════════════════════════════════════════════
capture program drop _xtpcaus_pqc_table
program define _xtpcaus_pqc_table
    args depvar indepvar panelvar N T nboot p_opt nq quantiles ///
         supW1 supW2 cv_01 cv_05 cv_10 ///
         Wq Coefq PBq WqR CoefqR PBqR

    di ""
    di as txt "  {hline 72}"
    di as txt "  Panel Quantile Causality Test"
    di as txt "  {hline 72}"
    di as txt "  Panels (N): " as res `N' as txt "    Periods (T): " as res `T' as txt "    VAR lag: " as res `p_opt' as txt "    Bootstrap: " as res `nboot'
    di as txt "  {hline 72}"

    // ── Direction 1: indepvar ≠> depvar ──────────────────────────
    di ""
    di as txt "  H0: {bf:`indepvar'} does not Granger-cause {bf:`depvar'}"
    di as txt "  {hline 68}"
    di as txt _col(3) %10s "Quantile" ///
       _col(15) %11s "Coeff." ///
       _col(28) %9s  "Wald" ///
       _col(39) %11s "p-value" ///
       _col(52) %5s  "Sig." ///
       _col(60) %10s "Causality"
    di as txt "  {hline 68}"

    forval q = 1/`nq' {
        local tau : word `q' of `quantiles'
        local w   = `Wq'[1, `q']
        local c   = `Coefq'[1, `q']
        local pb  = `PBq'[1, `q']
        local st  = cond(`pb' < 0.01, "***", cond(`pb' < 0.05, "**", cond(`pb' < 0.10, "*", "")))
        local caus = cond(`pb' < 0.05, "Yes", "")
        local dir  = cond(`c' > 0, "+", cond(`c' < 0, "-", ""))

        di as txt _col(3) %10.3f `tau' ///
           as res _col(15) %11.4f `c' ///
           as txt _col(28) %9.3f `w' ///
           as res _col(39) %11.3f `pb' ///
                  _col(52) "`st'" ///
           as txt _col(60) "`caus'" ///
                  _col(68) "`dir'"
    }
    di as txt "  {hline 68}"
    di as txt _col(3) "Sup-Wald = " as res %8.3f `supW1'

    // ── Direction 2: depvar ≠> indepvar ──────────────────────────
    di ""
    di as txt "  H0: {bf:`depvar'} does not Granger-cause {bf:`indepvar'}"
    di as txt "  {hline 68}"
    di as txt _col(3) %10s "Quantile" ///
       _col(15) %11s "Coeff." ///
       _col(28) %9s  "Wald" ///
       _col(39) %11s "p-value" ///
       _col(52) %5s  "Sig." ///
       _col(60) %10s "Causality"
    di as txt "  {hline 68}"

    forval q = 1/`nq' {
        local tau : word `q' of `quantiles'
        local w   = `WqR'[1, `q']
        local c   = `CoefqR'[1, `q']
        local pb  = `PBqR'[1, `q']
        local st  = cond(`pb' < 0.01, "***", cond(`pb' < 0.05, "**", cond(`pb' < 0.10, "*", "")))
        local caus = cond(`pb' < 0.05, "Yes", "")
        local dir  = cond(`c' > 0, "+", cond(`c' < 0, "-", ""))

        di as txt _col(3) %10.3f `tau' ///
           as res _col(15) %11.4f `c' ///
           as txt _col(28) %9.3f `w' ///
           as res _col(39) %11.3f `pb' ///
                  _col(52) "`st'" ///
           as txt _col(60) "`caus'" ///
                  _col(68) "`dir'"
    }
    di as txt "  {hline 68}"
    di as txt _col(3) "Sup-Wald = " as res %8.3f `supW2'

    // ── Sup-Wald critical values ─────────────────────────────────
    di ""
    di as txt "  {hline 68}"
    di as txt "  Sup-Wald Critical Values (q=`p_opt'):"
    di as txt _col(5) "1%:  " as res %6.2f `cv_01' ///
       as txt "    5%:  " as res %6.2f `cv_05' ///
       as txt "    10%: " as res %6.2f `cv_10'
    di as txt "  {hline 68}"
    di as txt "  *p<0.10, **p<0.05, ***p<0.01 (bootstrap)"
    di ""

end


// ══════════════════════════════════════════════════════════════════
// GRAPHS (coefficient path + Wald + p-value, as in Fig.1-2 Wang 2022)
// ══════════════════════════════════════════════════════════════════
capture program drop _xtpcaus_pqc_graph
program define _xtpcaus_pqc_graph
    args depvar indepvar nq quantiles ///
         Wq Coefq PBq WqR CoefqR PBqR ///
         cv_05 scheme

    preserve
    qui drop _all
    qui set obs `nq'

    qui gen double tau = .
    qui gen double coef_xy = .
    qui gen double wald_xy = .
    qui gen double pval_xy = .
    qui gen double coef_yx = .
    qui gen double wald_yx = .
    qui gen double pval_yx = .

    forval q = 1/`nq' {
        local t : word `q' of `quantiles'
        qui replace tau     = `t'                in `q'
        qui replace coef_xy = `Coefq'[1, `q']    in `q'
        qui replace wald_xy = `Wq'[1, `q']       in `q'
        qui replace pval_xy = `PBq'[1, `q']      in `q'
        qui replace coef_yx = `CoefqR'[1, `q']   in `q'
        qui replace wald_yx = `WqR'[1, `q']      in `q'
        qui replace pval_yx = `PBqR'[1, `q']     in `q'
    }

    qui gen zero = 0

    // ── Coefficient paths (Fig. 1 of Wang & Nguyen 2022) ─────────
    twoway ///
        (rarea zero coef_xy tau, fcolor(navy%15) lwidth(none)) ///
        (connected coef_xy tau, mcolor(navy) lcolor(navy) msymbol(circle) msize(small) lwidth(medthick)) ///
        , ///
        xlabel(`quantiles', format(%4.2f) angle(45)) ///
        xtitle("Quantile ({it:{&tau}})", size(small)) ///
        ytitle("Coefficient", size(small)) ///
        title("`indepvar' => `depvar'", color(navy) size(medsmall)) ///
        subtitle("Quantile Causal Effect Path", size(small) color(gs6)) ///
        yline(0, lcolor(gs8) lwidth(thin)) ///
        legend(off) ///
        scheme(`scheme') name(pqc_coef_xy, replace) nodraw

    twoway ///
        (rarea zero coef_yx tau, fcolor(maroon%15) lwidth(none)) ///
        (connected coef_yx tau, mcolor(maroon) lcolor(maroon) msymbol(circle) msize(small) lwidth(medthick)) ///
        , ///
        xlabel(`quantiles', format(%4.2f) angle(45)) ///
        xtitle("Quantile ({it:{&tau}})", size(small)) ///
        ytitle("Coefficient", size(small)) ///
        title("`depvar' => `indepvar'", color(maroon) size(medsmall)) ///
        subtitle("Quantile Causal Effect Path", size(small) color(gs6)) ///
        yline(0, lcolor(gs8) lwidth(thin)) ///
        legend(off) ///
        scheme(`scheme') name(pqc_coef_yx, replace) nodraw

    // ── Wald statistics ──────────────────────────────────────────
    twoway ///
        (bar wald_xy tau, barwidth(0.07) fcolor(navy%50) lcolor(navy) lwidth(vthin)) ///
        (connected wald_xy tau, mcolor(navy) lcolor(navy) msymbol(circle) msize(small) lwidth(medthick)) ///
        , ///
        xlabel(`quantiles', format(%4.2f) angle(45)) ///
        xtitle("Quantile ({it:{&tau}})", size(small)) ///
        ytitle("Wald Statistic", size(small)) ///
        title("`indepvar' => `depvar'", color(navy) size(medsmall)) ///
        yline(`cv_05', lcolor(red%70) lwidth(thin) lpattern(dash)) ///
        note("Dashed: Sup-Wald 5% cv (`cv_05')", size(vsmall)) ///
        legend(off) ///
        scheme(`scheme') name(pqc_wald_xy, replace) nodraw

    twoway ///
        (bar wald_yx tau, barwidth(0.07) fcolor(maroon%50) lcolor(maroon) lwidth(vthin)) ///
        (connected wald_yx tau, mcolor(maroon) lcolor(maroon) msymbol(circle) msize(small) lwidth(medthick)) ///
        , ///
        xlabel(`quantiles', format(%4.2f) angle(45)) ///
        xtitle("Quantile ({it:{&tau}})", size(small)) ///
        ytitle("Wald Statistic", size(small)) ///
        title("`depvar' => `indepvar'", color(maroon) size(medsmall)) ///
        yline(`cv_05', lcolor(red%70) lwidth(thin) lpattern(dash)) ///
        note("Dashed: Sup-Wald 5% cv (`cv_05')", size(vsmall)) ///
        legend(off) ///
        scheme(`scheme') name(pqc_wald_yx, replace) nodraw

    // ── P-value plots ────────────────────────────────────────────
    twoway ///
        (area pval_xy tau, fcolor(navy%15) lwidth(none)) ///
        (connected pval_xy tau, mcolor(navy) lcolor(navy) msymbol(circle) msize(small) lwidth(medthick)) ///
        , ///
        xlabel(`quantiles', format(%4.2f) angle(45)) ///
        xtitle("Quantile ({it:{&tau}})", size(small)) ///
        ytitle("Bootstrap p-value", size(small)) ///
        title("`indepvar' => `depvar'", color(navy) size(medsmall)) ///
        yline(0.05, lcolor(red%70) lwidth(thin) lpattern(dash)) ///
        yline(0.10, lcolor(orange%70) lwidth(thin) lpattern(shortdash)) ///
        yscale(range(0 1)) ylabel(0(0.1)1, format(%3.1f)) ///
        note("Red: 5% | Orange: 10%", size(vsmall)) ///
        legend(off) ///
        scheme(`scheme') name(pqc_pval_xy, replace) nodraw

    twoway ///
        (area pval_yx tau, fcolor(maroon%15) lwidth(none)) ///
        (connected pval_yx tau, mcolor(maroon) lcolor(maroon) msymbol(circle) msize(small) lwidth(medthick)) ///
        , ///
        xlabel(`quantiles', format(%4.2f) angle(45)) ///
        xtitle("Quantile ({it:{&tau}})", size(small)) ///
        ytitle("Bootstrap p-value", size(small)) ///
        title("`depvar' => `indepvar'", color(maroon) size(medsmall)) ///
        yline(0.05, lcolor(red%70) lwidth(thin) lpattern(dash)) ///
        yline(0.10, lcolor(orange%70) lwidth(thin) lpattern(shortdash)) ///
        yscale(range(0 1)) ylabel(0(0.1)1, format(%3.1f)) ///
        note("Red: 5% | Orange: 10%", size(vsmall)) ///
        legend(off) ///
        scheme(`scheme') name(pqc_pval_yx, replace) nodraw

    // ── Combined panels ──────────────────────────────────────────
    graph combine pqc_coef_xy pqc_coef_yx, ///
        title("Quantile Causal Effect Paths", size(medsmall) margin(b=2)) ///
        scheme(`scheme') ycommon name(pqc_coef_combined, replace)

    graph combine pqc_wald_xy pqc_wald_yx, ///
        title("Quantile Wald Statistics", size(medsmall) margin(b=2)) ///
        scheme(`scheme') ycommon name(pqc_wald_combined, replace)

    graph combine pqc_pval_xy pqc_pval_yx, ///
        title("Quantile Bootstrap p-values", size(medsmall) margin(b=2)) ///
        scheme(`scheme') ycommon name(pqc_pval_combined, replace)

    di ""
    di as txt "  Graphs: {cmd:pqc_coef_combined} | {cmd:pqc_wald_combined} | {cmd:pqc_pval_combined}"

    restore
end
