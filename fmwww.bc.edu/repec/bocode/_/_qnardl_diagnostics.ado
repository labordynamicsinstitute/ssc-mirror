*! _qnardl_diagnostics v1.0.0  28may2026
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Post-estimation diagnostics for QNARDL URECM residuals at chosen tau.
*!
*! Tests performed per tau (defaults to all the user's taus):
*!   1. Breusch-Godfrey LM (serial correlation, lags 1..L)
*!   2. Breusch-Pagan / Cook-Weisberg (heteroskedasticity)
*!   3. White general test (heteroskedasticity, with cross-products)
*!   4. Jarque-Bera (normality of residuals)
*!   5. Ramsey RESET (functional form, powers 2..4 of fitted values)
*!

program define _qnardl_diagnostics, rclass
    version 14.0

    syntax , depvar(varname) pos_vars(varlist) neg_vars(varlist) ///
        touse(varname) [ linear_vars(string) exog(string) ///
        trendvar(string) case(integer 3) ///
        p(integer 1) q(integer 1) r(integer 1) ///
        tau(numlist) BGLags(integer 4) ]

    if "`tau'" == "" local tau 0.5

    local kasym : word count `pos_vars'
    local klin  : word count `linear_vars'

    local has_const = (`case' >= 3)
    local has_trend = inlist(`case', 4, 5, 6, 7, 8, 9, 10, 11)
    local has_quad  = inlist(`case', 8, 9, 10, 11)
    if `has_quad' & "`trendvar'" != "" {
        tempvar t2var
        qui gen double `t2var' = (`trendvar')^2 if `touse'
    }
    local consopt = cond(`has_const', "", "noconstant")

    // Build URECM
    local urecm "L.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L.`lv'"
        }
    }
    if `p' > 1  local urecm "`urecm' L(1/`=`p'-1').D.`depvar'"
    foreach pv of varlist `pos_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`pv'"
    }
    foreach nv of varlist `neg_vars' {
        local urecm "`urecm' L(0/`=`q'-1').D.`nv'"
    }
    if `klin' > 0 {
        foreach lv of varlist `linear_vars' {
            local urecm "`urecm' L(0/`=`r'-1').D.`lv'"
        }
    }
    if "`exog'" != ""                       local urecm "`urecm' `exog'"
    if `has_trend' & "`trendvar'" != ""     local urecm "`urecm' `trendvar'"
    if `has_quad' & "`trendvar'" != ""      local urecm "`urecm' `t2var'"

    qui tsrevar `urecm'
    local urecm_temps `r(varlist)'
    qui tsrevar D.`depvar'
    local dydepvar `r(varlist)'

    di as txt _n "{hline 78}"
    di as res "[G] DIAGNOSTIC TESTS  (post-estimation, applied to URECM residuals)"
    di as txt _col(3) "Breusch-Godfrey LM (BG): serial correlation"
    di as txt _col(3) "Breusch-Pagan  (BPG):    heteroskedasticity"
    di as txt _col(3) "Jarque-Bera     (JB):    normality"
    di as txt _col(3) "Ramsey RESET   (RST):    functional form (powers 2..4 of yhat)"
    di as txt "{hline 78}"

    local ntau : word count `tau'
    tempname diag_mat
    matrix `diag_mat' = J(`ntau', 8, .)
    // columns: BG_stat, BG_p, BPG_stat, BPG_p, JB_stat, JB_p, RESET_stat, RESET_p

    di as txt _col(3) %-8s "tau" ///
              _col(13) %10s "BG(LM)" _col(25) %8s "p" ///
              _col(35) %10s "BPG"    _col(47) %8s "p" ///
              _col(57) %10s "JB"     _col(69) %8s "p"
    di as txt _col(3) "{hline 75}"

    local itau = 0
    foreach t of numlist `tau' {
        local ++itau

        capture qui qreg `dydepvar' `urecm_temps' if `touse', ///
            quantile(`t') `consopt'
        if _rc continue

        tempvar resid yhat e2 esample
        qui gen byte `esample' = e(sample)
        qui predict double `resid' if `esample', residuals
        qui predict double `yhat'  if `esample', xb
        qui gen double `e2' = `resid'^2 if `esample'

        // ---- 1. Breusch-Godfrey LM (serial correlation) ----
        // Regress residuals on URECM + L1..LB residuals
        local bg_res_lags ""
        forvalues kk = 1/`bglags' {
            tempvar reslag_`kk'
            qui gen double `reslag_`kk'' = L`kk'.`resid' if `esample'
            local bg_res_lags `bg_res_lags' `reslag_`kk''
        }
        capture qui regress `resid' `urecm_temps' `bg_res_lags' if `esample', `consopt'
        if !_rc {
            local bg_lm = e(N) * e(r2)        // LM = nR^2
            local bg_df = `bglags'
            local bg_p  = chi2tail(`bg_df', `bg_lm')
            matrix `diag_mat'[`itau', 1] = `bg_lm'
            matrix `diag_mat'[`itau', 2] = `bg_p'
        }

        // ---- 2. Breusch-Pagan ----
        capture qui regress `e2' `urecm_temps' if `esample', `consopt'
        if !_rc {
            local bp = e(N) * e(r2)
            local bp_df = e(df_m)
            local bp_p = chi2tail(`bp_df', `bp')
            matrix `diag_mat'[`itau', 3] = `bp'
            matrix `diag_mat'[`itau', 4] = `bp_p'
        }

        // ---- 3. Jarque-Bera ----
        qui sum `resid' if `esample', detail
        local nobs    = r(N)
        local skewns  = r(skewness)
        local kurts   = r(kurtosis)
        local jb = (`nobs'/6) * (`skewns'^2 + (`kurts' - 3)^2 / 4)
        local jb_p = chi2tail(2, `jb')
        matrix `diag_mat'[`itau', 5] = `jb'
        matrix `diag_mat'[`itau', 6] = `jb_p'

        // ---- 4. RESET ----
        tempvar yhat2 yhat3
        qui gen double `yhat2' = `yhat'^2 if `esample'
        qui gen double `yhat3' = `yhat'^3 if `esample'
        capture qui regress `resid' `urecm_temps' `yhat2' `yhat3' if `esample', `consopt'
        if !_rc {
            capture qui test `yhat2' `yhat3'
            if !_rc {
                local rs = r(F)
                local rs_p = r(p)
                matrix `diag_mat'[`itau', 7] = `rs'
                matrix `diag_mat'[`itau', 8] = `rs_p'
            }
        }

        // Print row
        local bg_s   = `diag_mat'[`itau', 1]
        local bg_p   = `diag_mat'[`itau', 2]
        local bp_s   = `diag_mat'[`itau', 3]
        local bp_p   = `diag_mat'[`itau', 4]
        local jb_s   = `diag_mat'[`itau', 5]
        local jb_p   = `diag_mat'[`itau', 6]

        local bg_p_str = cond(missing(`bg_p'), "  n/a", string(`bg_p', "%6.3f"))
        local bp_p_str = cond(missing(`bp_p'), "  n/a", string(`bp_p', "%6.3f"))
        local jb_p_str = cond(missing(`jb_p'), "  n/a", string(`jb_p', "%6.3f"))

        di as txt _col(3) %-8s "`t'" ///
                  as res _col(13) %10.3f `bg_s'  _col(25) %8s "`bg_p_str'" ///
                  _col(35) %10.3f `bp_s'         _col(47) %8s "`bp_p_str'" ///
                  _col(57) %10.3f `jb_s'         _col(69) %8s "`jb_p_str'"
    }
    di as txt _col(3) "{hline 75}"
    di as txt _col(3) "BG  H0: no serial correlation up to lag `bglags'  (chi^2(`bglags'))"
    di as txt _col(3) "BPG H0: homoskedasticity                          (chi^2(k))"
    di as txt _col(3) "JB  H0: residuals normally distributed            (chi^2(2))"
    di as txt _col(3) "p < 0.05  ==>  reject H0"

    matrix rownames `diag_mat' = `tau'
    matrix colnames `diag_mat' = BG p_BG BPG p_BPG JB p_JB RESET p_RESET

    return matrix diag = `diag_mat'
end
