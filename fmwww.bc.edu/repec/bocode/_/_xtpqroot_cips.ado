*! _xtpqroot_cips v1.0.1
*! Quantile Panel Unit Root Test with Common Shocks (CIPS(tau))
*! Implements: Yang, Wei & Cai (2022, EL) / Nazlioglu et al. (2026, NAJEF)
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: March 2026
capture program drop _xtpqroot_cips
program define _xtpqroot_cips, rclass sortpreserve
    version 14.0
    syntax varname(numeric ts) [if] [in], ///
        PANELvar(varname) TIMEvar(varname) ///
        Quantile(numlist >0 <1) Model(string) ///
        MAXLag(integer) REPS(integer) ///
        Level(integer) N(integer) T(integer) NTobs(integer) ///
        [NOGRaph NOTABle CDtest INDividual]
    
    marksample touse
    
    * syntax creates lowercase locals; code uses uppercase
    local N `n'
    local T `t'
    local NTobs `ntobs'
    
    sort `panelvar' `timevar'
    qui xtset `panelvar' `timevar'
    
    * =========================================================================
    * STEP 0: Setup storage
    * =========================================================================
    local nq : word count `quantile'
    tempname cips_mat cipstau_mat cadf_mat cadftau_mat pval_cips pval_cipstau
    tempname cadf_ind_mat cd_mat rho_mat
    
    mat `cips_mat' = J(1, 2, .)      // CIPS stat, p-value
    mat `cipstau_mat' = J(`nq', 3, .) // tau, CIPS(tau) stat, p-value
    
    * Storage for individual results: N x (3 + 3*nq)
    * Layout: [CADF_tstat, CADF_pval, rho_OLS, CADF(tau1)_tstat, CADF(tau1)_pval, rho(tau1), ...]
    mat `cadf_ind_mat' = J(`N', 3 + 3*`nq', .)
    
    * Storage for rho estimates: N x nq_fine (for graph)
    local nq_fine = 99
    mat `rho_mat' = J(`N', `nq_fine', .)
    
    * CD test storage
    mat `cd_mat' = J(1 + `nq', 2, .)  // stat, p-value for OLS + each tau
    
    * Truncation constants (Pesaran 2007, p.35)
    if "`model'" == "intercept" {
        local K1 = 6.19
        local K2 = 2.16
    }
    else {
        local K1 = 6.19
        local K2 = 2.61
    }
    
    * =========================================================================
    * STEP 1: Compute cross-sectional averages
    * =========================================================================
    tempvar ybar dybar
    qui bysort `timevar': egen double `ybar' = mean(`varlist') if `touse'
    sort `panelvar' `timevar'
    qui xtset `panelvar' `timevar'
    qui gen double `dybar' = D.`ybar' if `touse'
    
    * Pre-compute L.ybar for qreg compatibility (qreg doesn't support TS operators)
    tempvar Lybar
    qui gen double `Lybar' = L.`ybar' if `touse'
    
    * Also generate lagged cross-averages
    forvalues j = 1/`maxlag' {
        tempvar dybar_L`j'
        qui gen double `dybar_L`j'' = L`j'.`dybar' if `touse'
    }
    
    * Generate lagged dependent variable terms
    tempvar Ly
    qui gen double `Ly' = L.`varlist' if `touse'
    
    forvalues j = 1/`maxlag' {
        tempvar dy_L`j'
        qui gen double `dy_L`j'' = L`j'.D.`varlist' if `touse'
    }
    
    * =========================================================================
    * STEP 2: Mean-based CIPS (standard Pesaran 2007)
    * =========================================================================
    
    * Get panel identifiers
    qui levelsof `panelvar' if `touse', local(panels)
    local panel_count = 0
    
    * Storage for individual CADF statistics
    tempname cadf_vec
    mat `cadf_vec' = J(`N', 1, .)
    
    local i = 0
    foreach pid of local panels {
        local ++i
        
        * Build regressor list: y_{i,t-1}, ybar_{t-1}, Dybar_t, Dybar_{t-1}, ..., Dy_{i,t-1}, ...
        local xvars "`Ly' `Lybar' `dybar'"
        forvalues j = 1/`maxlag' {
            local xvars "`xvars' `dybar_L`j''"
        }
        forvalues j = 1/`maxlag' {
            local xvars "`xvars' `dy_L`j''"
        }
        
        * Run ADF regression for panel i (OLS-based CADF)
        * Regression: y_it on (1, y_{i,t-1}, ybar_{t-1}, Dybar_t, lags...)
        capture qui reg `varlist' `xvars' if `panelvar' == `pid' & `touse'
        
        if _rc == 0 {
            * t-ratio testing H0: rho = 1  =>  t = (rho_hat - 1) / se(rho_hat)
            local rho_hat_ols = _b[`Ly']
            local se_rho_ols  = _se[`Ly']
            if `se_rho_ols' > 0 & `se_rho_ols' < . {
                local cadf_i = (`rho_hat_ols' - 1) / `se_rho_ols'
            }
            else {
                local cadf_i = .
            }
        }
        else {
            local cadf_i = .
        }
        
        * Store un-truncated stat and rho_hat for individual results
        mat `cadf_ind_mat'[`i', 1] = `cadf_i'
        if _rc == 0 {
            mat `cadf_ind_mat'[`i', 3] = `rho_hat_ols'
        }
        
        * Truncate for aggregate CIPS (Pesaran 2007, p.35)
        if `cadf_i' != . {
            if `cadf_i' < -`K1' local cadf_i = -`K1'
            if `cadf_i' > `K2'  local cadf_i = `K2'
        }
        
        mat `cadf_vec'[`i', 1] = `cadf_i'
    }
    
    * Compute CIPS = mean of truncated CADF
    mata: st_local("cips_stat", strofreal(mean(st_matrix("`cadf_vec'"))))
    
    * =========================================================================
    * STEP 3: Quantile-based CIPS(tau) (Yang et al. 2022, Eq. 5 / pq2 Eq. 8)
    * Following Koenker & Xiao (2004) for sparsity estimation
    * Uses Mata-based qreg (IRLS) to avoid Stata qreg VCE failure at extremes
    * =========================================================================
    
    local q_idx = 0
    foreach tau of numlist `quantile' {
        local ++q_idx
        
        tempname cadftau_vec_`q_idx'
        mat `cadftau_vec_`q_idx'' = J(`N', 1, .)
        
        * Call Mata to compute CADF(tau) for ALL panels at this quantile
        mata: _xtpqroot_cadf_tau_real("`varlist'", "`Ly'", "`Lybar'", "`dybar'", ///
            "`panelvar'", "`touse'", `tau', `maxlag', `K1', `K2', `N', ///
            "`cadftau_vec_`q_idx''", "`cadf_ind_mat'", `q_idx')
        
        * CIPS(tau) = average of truncated CADF(tau)
        mata: st_local("cipstau_`q_idx'", strofreal(mean(st_matrix("`cadftau_vec_`q_idx''"))))
        
        mat `cipstau_mat'[`q_idx', 1] = `tau'
        mat `cipstau_mat'[`q_idx', 2] = `cipstau_`q_idx''
    }
    
    * =========================================================================
    * STEP 4: Simulate p-values (Yang et al. 2022, Section 2)
    * =========================================================================
    
    di as text ""
    di as text "  Simulating p-values (`reps' replications, T=`T', N=`N')..."
    
    local do_individual = ("`individual'" != "")
    mata: _xtpqroot_simulate_pvalues(`N', `T', `maxlag', "`model'", `reps', ///
        "`quantile'", `K1', `K2', ///
        strtoreal(st_local("cips_stat")), "`cips_mat'", "`cipstau_mat'", ///
        "`cadf_ind_mat'", `do_individual')
    
    * Extract p-values
    local pval_cips = `cips_mat'[1,2]
    
    * =========================================================================
    * STEP 5: CD test for cross-sectional dependence (if requested)
    * =========================================================================
    
    if "`cdtest'" != "" {
        * Standard CD test on panel-specific OLS CADF residuals
        * Pesaran (2004, 2015): CD computed from panel-specific regression residuals
        tempvar ols_resid dy_cd
        qui gen double `dy_cd' = D.`varlist' if `touse'
        qui gen double `ols_resid' = . if `touse'
        
        * Run panel-specific OLS CADF regressions and collect residuals
        foreach pid of local panels {
            local xvars "`Ly' `Lybar' `dybar'"
            forvalues j = 1/`maxlag' {
                local xvars "`xvars' `dybar_L`j''"
            }
            forvalues j = 1/`maxlag' {
                local xvars "`xvars' `dy_L`j''"
            }
            capture qui reg `varlist' `xvars' if `panelvar' == `pid' & `touse'
            if _rc == 0 {
                tempvar _tmpresid
                qui predict double `_tmpresid' if `panelvar' == `pid' & `touse', resid
                qui replace `ols_resid' = `_tmpresid' if `panelvar' == `pid' & `touse'
                drop `_tmpresid'
            }
        }
        
        * Compute Pesaran CD statistic from panel-specific residuals
        mata: _xtpqroot_cd_test("`ols_resid'", "`panelvar'", "`timevar'", "`touse'", `N', `T', "`cd_mat'", 1)
        
        * CD(tau) at each quantile using panel-specific CADF(tau) residuals
        * Uses Mata-based qreg to avoid Stata qreg VCE failures at extreme quantiles
        local q_idx = 0
        foreach tau of numlist `quantile' {
            local ++q_idx
            tempvar qr_resid_`q_idx'
            qui gen double `qr_resid_`q_idx'' = . if `touse'
            
            * Run panel-specific quantile CADF regressions
            mata: _xtpqroot_cd_qreg_panel("`varlist'", "`Ly'", "`Lybar'", "`dybar'", ///
                "`panelvar'", "`touse'", `tau', `maxlag', `N', "`qr_resid_`q_idx''")
            
            mata: _xtpqroot_cd_test("`qr_resid_`q_idx''", "`panelvar'", "`timevar'", "`touse'", `N', `T', "`cd_mat'", `=1+`q_idx'')
        }
    }
    
    * =========================================================================
    * STEP 6: Estimate rho(tau) for persistence graph
    * =========================================================================
    
    if "`nograph'" == "" {
        mata: _xtpqroot_rho_graph("`varlist'", "`Ly'", "`Lybar'", "`dybar'", ///
            "`panelvar'", "`touse'", `maxlag', `N', `nq_fine', "`rho_mat'")
    }
    
    * =========================================================================
    * DISPLAY OUTPUT
    * =========================================================================
    
    if "`notable'" == "" {
        _xtpqroot_cips_display, ///
            varname(`varlist') panelvar(`panelvar') timevar(`timevar') ///
            model(`model') maxlag(`maxlag') reps(`reps') ///
            level(`level') n(`N') t(`T') ntobs(`NTobs') ///
            k1(`K1') k2(`K2') nq(`nq') ///
            cips_stat(`cips_stat') pval_cips(`pval_cips') ///
            cips_mat(`cips_mat') cipstau_mat(`cipstau_mat') ///
            cadf_ind_mat(`cadf_ind_mat') ///
            quantile(`quantile') ///
            `cdtest' cd_mat(`cd_mat') ///
            `individual' panels(`panels')
    }
    
    * =========================================================================
    * GRAPHS
    * =========================================================================
    
    if "`nograph'" == "" {
        _xtpqroot_cips_graph, ///
            panelvar(`panelvar') timevar(`timevar') ///
            n(`N') nq(`nq') nq_fine(`nq_fine') ///
            rho_mat(`rho_mat') cipstau_mat(`cipstau_mat') ///
            varname(`varlist') panels(`panels')
    }
    
    * =========================================================================
    * RETURN VALUES
    * =========================================================================
    
    return scalar cips     = `cips_stat'
    return scalar cips_p   = `pval_cips'
    
    * Store individual quantile results BEFORE return matrix (which moves/destroys original)
    local q_idx = 0
    foreach tau of numlist `quantile' {
        local ++q_idx
        local tau_lbl = subinstr("`tau'", ".", "", .)
        return scalar cipstau_`tau_lbl' = el(`cipstau_mat', `q_idx', 2)
        return scalar pval_`tau_lbl'    = el(`cipstau_mat', `q_idx', 3)
    }
    
    return local test "CIPStau"
    return scalar maxlag = `maxlag'
    return scalar reps   = `reps'
    return matrix cipstau = `cipstau_mat'
    
end

* =============================================================================
* DISPLAY PROGRAM
* =============================================================================
capture program drop _xtpqroot_cips_display
program define _xtpqroot_cips_display
    syntax, varname(string) panelvar(string) timevar(string) ///
        model(string) maxlag(integer) reps(integer) ///
        level(integer) n(integer) t(integer) ntobs(integer) ///
        k1(real) k2(real) nq(integer) ///
        cips_stat(real) pval_cips(real) ///
        cips_mat(string) cipstau_mat(string) ///
        cadf_ind_mat(string) ///
        quantile(numlist) ///
        [CDtest cd_mat(string) INDividual panels(string)]
    
    * =================================================================
    * HEADER
    * =================================================================
    di ""
    di as text "{hline 78}"
    di as text "{bf: Quantile Panel Unit Root Test with Common Shocks (CIPS(tau))}"
    di as text "{hline 78}"
    
    * =================================================================
    * DATA SUMMARY
    * =================================================================
    di ""
    di as text " {bf:Data Summary}"
    di as text "{hline 78}"
    
    if "`model'" == "intercept" {
        local model_label "Intercept only"
    }
    else {
        local model_label "Intercept + Trend"
    }
    
    di as text " Variable          : {res:`varname'}" ///
        _col(45) as text "Panel variable  : {res:`panelvar'}"
    di as text " Time variable     : {res:`timevar'}" ///
        _col(45) as text "Panel structure : {res:Balanced}"
    di as text " N (panels)        : {res:`n'}" ///
        _col(45) as text "T (time periods): {res:`t'}"
    di as text " Total obs         : {res:`ntobs'}" ///
        _col(45) as text "Deterministics  : {res:`model_label'}"
    di as text " Lag order (p)     : {res:`maxlag'}" ///
        _col(45) as text "MC replications : {res:`reps'}"
    di as text " Truncation        : K1={res:`=string(`k1',"%5.2f")'}" ///
        _col(45) as text "K2={res:`=string(`k2',"%5.2f")'}"
    di as text "{hline 78}"
    
    * =================================================================
    * PANEL UNIT ROOT TESTS TABLE (matching pq2 Table 1 format)
    * =================================================================
    di ""
    di as text " {bf:Panel Unit Root Tests}"
    di as text "{hline 78}"
    di as text %30s "Test" _col(35) %14s "Statistic" _col(52) %12s "p-value" _col(66) %12s ""
    di as text "{hline 78}"
    
    * Standard CIPS
    _xtpqroot_display_row "CIPS" `cips_stat' `pval_cips'
    
    di as text "{hline 78}"
    
    * CIPS(tau) at each quantile
    di as text ""
    di as text " {bf:CIPS(tau) (Quantile Panel Unit Root)}"
    di as text "{hline 78}"
    di as text %10s "(tau)" _col(20) %14s "CIPS(tau)" _col(38) %12s "p-value" _col(54) %12s "Stars" _col(68) %10s "Decision"
    di as text "{hline 78}"
    
    forvalues q = 1/`nq' {
        local tau  = `cipstau_mat'[`q', 1]
        local stat = `cipstau_mat'[`q', 2]
        local pval = `cipstau_mat'[`q', 3]
        
        * Format significance
        local stars ""
        local scol "text"
        if `pval' < 0.01 & `pval' != . {
            local stars "***"
            local scol "err"
        }
        else if `pval' < 0.05 & `pval' != . {
            local stars "**"
            local scol "err"
        }
        else if `pval' < 0.10 & `pval' != . {
            local stars "*"
            local scol "result"
        }
        
        * Decision
        local dec "Fail to reject"
        if `pval' < (100-`level')/100 & `pval' != . {
            local dec "Reject H0"
        }
        
        * Format p-value
        if `pval' < 0.001 & `pval' != . {
            local pstr "<0.001"
        }
        else if `pval' == . {
            local pstr "---"
        }
        else {
            local pstr : di %8.3f `pval'
            local pstr = strtrim("`pstr'")
        }
        
        di as text %10.1f `tau' ///
            _col(20) as result %14.3f `stat' ///
            _col(38) as `scol' %12s "`pstr'" ///
            _col(54) as `scol' %8s "`stars'" ///
            _col(66) as `scol' %12s "`dec'"
    }
    
    di as text "{hline 78}"
    
    * =================================================================
    * CD TEST TABLE (if requested)
    * =================================================================
    if "`cdtest'" != "" {
        di ""
        di as text " {bf:Cross-Sectional Dependence Tests (Pesaran 2021)}"
        di as text "{hline 78}"
        di as text %16s "Test" _col(24) %14s "Statistic" _col(42) %12s "p-value" _col(58) %10s ""
        di as text "{hline 78}"
        
        * OLS-based CD
        local cd_stat = `cd_mat'[1, 1]
        local cd_pval = `cd_mat'[1, 2]
        _xtpqroot_display_row "CD" `cd_stat' `cd_pval'
        
        di as text "{hline 78}"
        
        * CD(tau) at each quantile
        di as text ""
        di as text " {bf:CD(tau)}"
        di as text "{hline 78}"
        
        local q_idx = 0
        foreach tau of numlist `quantile' {
            local ++q_idx
            local cd_stat = `cd_mat'[1+`q_idx', 1]
            local cd_pval = `cd_mat'[1+`q_idx', 2]
            _xtpqroot_display_row "CD(tau)((tau)=`tau')" `cd_stat' `cd_pval'
        }
        di as text "{hline 78}"
    }
    
    * =================================================================
    * HYPOTHESES & INTERPRETATION
    * =================================================================
    di ""
    di as text " {bf:Hypotheses}"
    di as text "{hline 78}"
    di as text " H0: rho_i((tau)) = 1 for all i and (tau)   (All panels contain a unit root)"
    di as text " H1: rho_i((tau)) < 1 for some i        (Some panels are stationary)"
    di as text ""
    di as text " {bf:Interpretation:}"
    di as text " Rejection at low (tau) but not high (tau): Inflation/variable is {bf:mean-reverting}"
    di as text "   during stable periods but {bf:persistent} during extreme episodes."
    di as text " Rejection at high (tau) but not low (tau): Opposite asymmetry."
    di as text " Rejection across all (tau): Strong evidence of overall stationarity."
    di as text "{hline 78}"
    
    * =================================================================
    * INDIVIDUAL RESULTS TABLE (if requested)
    * =================================================================
    if "`individual'" != "" {
        di ""
        di as text " {bf:Individual Panel Results}"
        di as text " {it:rho} = autoregressive coefficient (rho<1: stationary, rho>=1: unit root)"
        di as text " Significance stars based on CADF p-values from MC simulation"
        di as text "{hline 78}"
        
        * Build header dynamically
        local col_w = 14
        di as text %10s "Panel" _col(14) %12s "rho(OLS)" _c
        
        local q_idx = 0
        foreach tau of numlist `quantile' {
            local ++q_idx
            local cpos = 14 + `q_idx' * `col_w'
            di as text _col(`cpos') %12s "rho(`tau')" _c
        }
        di ""
        di as text "{hline 78}"
        
        * Count rejections for summary
        local rej_ols = 0
        local nq_val : word count `quantile'
        forvalues qq = 1/`nq_val' {
            local rej_`qq' = 0
        }
        
        local i = 0
        foreach pid of local panels {
            local ++i
            
            * OLS rho and p-value
            local rho_ols = `cadf_ind_mat'[`i', 3]
            local pval_ols = `cadf_ind_mat'[`i', 2]
            
            * Determine stars and color
            local stars_ols ""
            local col_ols "result"
            if `pval_ols' < 0.01 & `pval_ols' != . {
                local stars_ols "***"
                local col_ols "err"
                local ++rej_ols
            }
            else if `pval_ols' < 0.05 & `pval_ols' != . {
                local stars_ols "**"
                local col_ols "err"
                local ++rej_ols
            }
            else if `pval_ols' < 0.10 & `pval_ols' != . {
                local stars_ols "*"
                local ++rej_ols
            }
            
            if `rho_ols' != . {
                local rho_str : di %7.3f `rho_ols'
                local rho_str = strtrim("`rho_str'") + "`stars_ols'"
            }
            else {
                local rho_str "---"
                local col_ols "text"
            }
            
            di as text %10s "`pid'" _col(14) as `col_ols' %12s "`rho_str'" _c
            
            local q_idx = 0
            foreach tau of numlist `quantile' {
                local ++q_idx
                local cpos = 14 + `q_idx' * `col_w'
                local rho_q = `cadf_ind_mat'[`i', 3 + 3*(`q_idx'-1) + 3]
                local pval_q = `cadf_ind_mat'[`i', 3 + 3*(`q_idx'-1) + 2]
                
                * Determine stars and color
                local stars_q ""
                local col_q "result"
                if `pval_q' < 0.01 & `pval_q' != . {
                    local stars_q "***"
                    local col_q "err"
                    local ++rej_`q_idx'
                }
                else if `pval_q' < 0.05 & `pval_q' != . {
                    local stars_q "**"
                    local col_q "err"
                    local ++rej_`q_idx'
                }
                else if `pval_q' < 0.10 & `pval_q' != . {
                    local stars_q "*"
                    local ++rej_`q_idx'
                }
                
                if `rho_q' != . {
                    local rhoq_str : di %7.3f `rho_q'
                    local rhoq_str = strtrim("`rhoq_str'") + "`stars_q'"
                }
                else {
                    local rhoq_str "---"
                    local col_q "text"
                }
                
                di _col(`cpos') as `col_q' %12s "`rhoq_str'" _c
            }
            di ""
        }
        di as text "{hline 78}"
        
        * Summary line: rejection counts
        di as text %10s "Reject" _col(14) %12s "`rej_ols'/`n'" _c
        local q_idx = 0
        foreach tau of numlist `quantile' {
            local ++q_idx
            local cpos = 14 + `q_idx' * `col_w'
            di as text _col(`cpos') %12s "`rej_`q_idx''/`n'" _c
        }
        di ""
        di as text "{hline 78}"
    }
    
    * =================================================================
    * FOOTER
    * =================================================================
    di ""
    di as text " *** p<0.01, ** p<0.05, * p<0.10"
    di as text " Source: Yang, Wei & Cai (2022, Econ. Letters); Nazlioglu et al. (2026, NAJEF)"
    di as text "{hline 78}"
    
end

* =============================================================================
* SINGLE ROW DISPLAY HELPER
* =============================================================================
capture program drop _xtpqroot_display_row
program define _xtpqroot_display_row
    args label stat pval
    
    local stars ""
    local scol "text"
    if `pval' < 0.01 & `pval' != . {
        local stars "***"
        local scol "err"
    }
    else if `pval' < 0.05 & `pval' != . {
        local stars "**"
        local scol "err"
    }
    else if `pval' < 0.10 & `pval' != . {
        local stars "*"
        local scol "result"
    }
    
    if `pval' < 0.001 & `pval' != . {
        local pstr "<0.001"
    }
    else if `pval' == . {
        local pstr "---"
    }
    else {
        local pstr : di %8.3f `pval'
        local pstr = strtrim("`pstr'")
    }
    
    di as text %30s "`label'" _col(35) as result %14.3f `stat' ///
       _col(52) as `scol' %12s "`pstr'`stars'"
end

* =============================================================================
* GRAPH PROGRAM
* =============================================================================
capture program drop _xtpqroot_cips_graph
program define _xtpqroot_cips_graph
    syntax, panelvar(string) timevar(string) ///
        n(integer) nq(integer) nq_fine(integer) ///
        rho_mat(string) cipstau_mat(string) ///
        varname(string) panels(string)
    
    preserve
    
    * --- Graph 1: CIPS(tau) across quantiles ---
    qui clear
    qui set obs `nq'
    qui gen double tau = .
    qui gen double cipstau = .
    
    forvalues q = 1/`nq' {
        qui replace tau = el(`cipstau_mat', `q', 1) in `q'
        qui replace cipstau = el(`cipstau_mat', `q', 2) in `q'
    }
    
    * --- Graph 1: CIPS(tau) statistic across quantiles (publication style) ---
    twoway (connected cipstau tau, lcolor("0 102 204") mcolor("0 102 204") ///
            msymbol(diamond) lwidth(medthick) msize(medlarge)) ///
           (scatteri 0 0 0 1, recast(line) lcolor("204 0 51") ///
            lwidth(thin) lpattern(dash)), ///
           title("{bf:CIPS(tau) Panel Statistic across Quantiles}", ///
               size(medium) color("0 51 102")) ///
           xtitle("Quantile ((tau))", size(small)) ///
           ytitle("CIPS(tau) Statistic", size(small)) ///
           xlabel(0.1(0.1)0.9, labsize(small) grid glcolor(gs14)) ///
           ylabel(, labsize(small) grid glcolor(gs14)) ///
           legend(off) ///
           graphregion(color(white) margin(small)) ///
           plotregion(margin(small) lcolor(gs12)) ///
           note("More negative -> stronger rejection of H0 (unit root)", ///
               size(vsmall) color(gs8)) ///
           scheme(s2color) name(xtpqroot_cipstau, replace) nodraw
    
    * --- Graph 2: Persistence degree rho(tau) across quantiles ---
    * (Matching pq2 Figs 2-4 style)
    qui clear
    qui set obs `nq_fine'
    qui gen double tau = _n / 100
    qui gen double mean_rho = .
    qui gen double p10_rho = .
    qui gen double p90_rho = .
    
    * Compute mean and quantiles of rho across panels (pure Stata)
    forvalues jj = 1/`nq_fine' {
        local sum_rho = 0
        local cnt_rho = 0
        forvalues ii = 1/`n' {
            local rval = el(`rho_mat', `ii', `jj')
            if `rval' < . {
                local sum_rho = `sum_rho' + `rval'
                local ++cnt_rho
            }
        }
        if `cnt_rho' > 0 {
            qui replace mean_rho = `sum_rho' / `cnt_rho' in `jj'
            * Approximate p10 and p90 using min/max as fallback
            local p10_val = .
            local p90_val = .
            forvalues ii = 1/`n' {
                local rval = el(`rho_mat', `ii', `jj')
                if `rval' < . {
                    if `p10_val' == . | `rval' < `p10_val' {
                        local p10_val = `rval'
                    }
                    if `p90_val' == . | `rval' > `p90_val' {
                        local p90_val = `rval'
                    }
                }
            }
            qui replace p10_rho = `p10_val' in `jj'
            qui replace p90_rho = `p90_val' in `jj'
        }
    }
    
    twoway (rarea p10_rho p90_rho tau, ///
               fcolor("153 204 255%40") lcolor("102 178 255%60") lwidth(vthin)) ///
           (line mean_rho tau, lcolor("0 102 204") lwidth(medthick)) ///
           (scatteri 1 0.01 1 0.99, recast(line) ///
               lcolor("204 0 51") lwidth(medium) lpattern(dash)), ///
           title("{bf:Persistence Degree} {it:{&rho}((tau))} {bf:across Quantiles}", ///
               size(medium) color("0 51 102")) ///
           subtitle("Average across `n' panels with 10%-90% confidence bands", ///
               size(small) color(gs6)) ///
           xtitle("Quantile ((tau))", size(small)) ///
           ytitle("{it:{&rho}}((tau))", size(small)) ///
           xlabel(0.01 "0" 0.25 "0.25" 0.5 "0.5" 0.75 "0.75" 0.99 "1", ///
               labsize(small) grid glcolor(gs14)) ///
           ylabel(, labsize(small) grid glcolor(gs14)) ///
           legend(order(2 "Mean {it:{&rho}}((tau))" 1 "10%-90% band" ///
               3 "Unit root ({it:{&rho}}=1)") ///
               size(vsmall) cols(3) position(6) ///
               region(lcolor(gs14) color(white))) ///
           graphregion(color(white) margin(small)) ///
           plotregion(margin(small) lcolor(gs12)) ///
           note("{it:{&rho}}((tau)) >= 1 -> persistence;  {it:{&rho}}((tau)) < 1 -> mean reversion", ///
               size(vsmall) color(gs8)) ///
           scheme(s2color) name(xtpqroot_rho, replace) nodraw
    
    * --- Combine into publication panel ---
    graph combine xtpqroot_cipstau xtpqroot_rho, ///
        title("{bf:Quantile Panel Unit Root Analysis -- `varname'}", ///
            size(medsmall) color("0 51 102")) ///
        cols(2) iscale(0.85) ysize(4) xsize(8) ///
        graphregion(color(white) margin(small)) ///
        name(xtpqroot_cips_combined, replace)
    
    restore
end

* =============================================================================
* MATA: SIMULATE P-VALUES FOR CIPS AND CIPS(tau)
* =============================================================================

capture mata: mata drop _xtpqroot_cadf_tau_real()
capture mata: mata drop _xtpqroot_simulate_pvalues()
capture mata: mata drop _xtpqroot_qreg()
capture mata: mata drop _xtpqroot_cd_test()
capture mata: mata drop _xtpqroot_cd_qreg_panel()
capture mata: mata drop _xtpqroot_rho_graph()

mata:

// =========================================================================
// Compute CADF(tau) for all panels from real data (avoids Stata qreg VCE)
// Implements Yang et al. (2022) Eq. 5, Nazlioglu et al. (2026) Eq. 8
// =========================================================================
void _xtpqroot_cadf_tau_real(
    string scalar depvar,
    string scalar lyvar,
    string scalar lybarvar,
    string scalar dybarvar,
    string scalar panelvar,
    string scalar tousevar,
    real scalar tau,
    real scalar maxlag,
    real scalar K1,
    real scalar K2,
    real scalar N_panels,
    string scalar cadftau_matname,
    string scalar cadf_ind_matname,
    real scalar q_idx
)
{
    real colvector dep_all, ly_all, lybar_all, dybar_all, panel_all
    real colvector unique_panels, sel, dep_i, ly_i, lybar_i, dybar_i
    real colvector dep_full, dy_i, dybar_lj, dy_lj
    real matrix X_i, X_nolag, XnXn_inv, cadftau_vec, cadf_ind
    real colvector bq, resid_q, sorted_resid, mx_resid
    real scalar i, n_i, t_eff, k, n_raw, t_start, tt, jj
    real scalar hn, tau_plus, tau_minus
    real scalar idx_plus, idx_minus, q_plus, q_minus, s_hat
    real scalar rss_mx, se_rho, cadftau_i, rr, cc
    
    // Get data views
    st_view(dep_all, ., depvar, tousevar)
    st_view(ly_all, ., lyvar, tousevar)
    st_view(lybar_all, ., lybarvar, tousevar)
    st_view(dybar_all, ., dybarvar, tousevar)
    st_view(panel_all, ., panelvar, tousevar)
    
    unique_panels = uniqrows(panel_all)
    
    cadftau_vec = st_matrix(cadftau_matname)
    cadf_ind = st_matrix(cadf_ind_matname)
    
    for (i = 1; i <= rows(unique_panels); i++) {
        if (i > N_panels) break
        
        cadftau_i = .
        
        sel = (panel_all :== unique_panels[i])
        dep_i = select(dep_all, sel)
        ly_i  = select(ly_all, sel)
        lybar_i = select(lybar_all, sel)
        dybar_i = select(dybar_all, sel)
        n_raw = rows(dep_i)
        
        // Find first non-missing observation
        t_start = n_raw + 1
        for (tt = 1; tt <= n_raw; tt++) {
            if (dep_i[tt] < . & ly_i[tt] < . & lybar_i[tt] < . & dybar_i[tt] < .) {
                t_start = tt
                break
            }
        }
        t_start = t_start + maxlag
        
        if (t_start <= n_raw) {
            t_eff = n_raw - t_start + 1
            
            if (t_eff >= 8) {
                // Build X: intercept, ly, lybar, dybar
                X_i = J(t_eff, 1, 1), ly_i[t_start..n_raw], lybar_i[t_start..n_raw], dybar_i[t_start..n_raw]
                dep_i = dep_i[t_start..n_raw]
                
                // Compute dy_i for full panel
                dep_full = select(dep_all, sel)
                dy_i = J(n_raw, 1, .)
                for (tt = 2; tt <= n_raw; tt++) {
                    if (dep_full[tt] < . & dep_full[tt-1] < .) {
                        dy_i[tt] = dep_full[tt] - dep_full[tt-1]
                    }
                }
                
                // Add lagged dybar and dy
                for (jj = 1; jj <= maxlag; jj++) {
                    dybar_lj = J(t_eff, 1, 0)
                    dy_lj = J(t_eff, 1, 0)
                    for (tt = t_start; tt <= n_raw; tt++) {
                        if (tt - jj >= 1) {
                            if (dybar_i[tt - jj] < .) {
                                dybar_lj[tt - t_start + 1] = dybar_i[tt - jj]
                            }
                            if (dy_i[tt - jj] < .) {
                                dy_lj[tt - t_start + 1] = dy_i[tt - jj]
                            }
                        }
                    }
                    X_i = X_i, dybar_lj, dy_lj
                }
                
                // Replace remaining missings with 0 (vectorized)
                X_i = editmissing(X_i, 0)
                
                k = cols(X_i)
                n_i = rows(X_i)
                
                if (det(cross(X_i, X_i)) >= 1e-15) {
                    
                    // (a) Quantile regression via IRLS
                    bq = _xtpqroot_qreg(dep_i, X_i, tau, 50)
                    
                    if (bq != J(0,0,.)) {
                        // (b) Sparsity from residual quantiles (KX 2004)
                        resid_q = dep_i - X_i * bq
                        
                        hn = n_i^(-1/5) * ((4.5 * normalden(invnormal(tau))^4) / (2*invnormal(tau)^2 + 1)^2)^(1/5)
                        // Ensure minimum bandwidth for small-sample stability
                        // (at least 5 obs used for density estimate)
                        if (hn < min((0.49, 5.0/n_i))) hn = min((0.49, 5.0/n_i))
                        if (hn > 0.49) hn = 0.49
                        
                        tau_plus  = min((tau + hn, 0.999))
                        tau_minus = max((tau - hn, 0.001))
                        
                        sorted_resid = sort(resid_q, 1)
                        idx_plus  = max((1, min((n_i, ceil(tau_plus * n_i)))))
                        idx_minus = max((1, min((n_i, ceil(tau_minus * n_i)))))
                        q_plus  = sorted_resid[idx_plus]
                        q_minus = sorted_resid[idx_minus]
                        
                        s_hat = (q_plus - q_minus) / (2 * hn)
                        if (s_hat < 1e-10 | s_hat >= .) s_hat = 1
                        
                        // (c) M_X projection: RSS of col2 on other cols
                        X_nolag = X_i[., 1], X_i[., 3..k]
                        XnXn_inv = invsym(cross(X_nolag, X_nolag))
                        mx_resid = X_i[., 2] - X_nolag * (XnXn_inv * cross(X_nolag, X_i[., 2]))
                        rss_mx = cross(mx_resid, mx_resid)
                        
                        // (d) t-stat = (rho-1)/SE
                        if (rss_mx > 0) {
                            se_rho = sqrt(tau * (1 - tau)) * s_hat / sqrt(rss_mx)
                            if (se_rho > 0 & se_rho < .) {
                                cadftau_i = (bq[2] - 1) / se_rho
                            }
                        }
                    }
                }
            }
        }
        
        // Store un-truncated stat and rho_hat for individual p-values
        cadf_ind[i, 3 + 3*(q_idx-1) + 1] = cadftau_i
        if (bq != J(0,0,.)) {
            cadf_ind[i, 3 + 3*(q_idx-1) + 3] = bq[2]
        }
        
        // Truncate for aggregate CIPS(tau) (Pesaran 2007, p.35)
        if (cadftau_i < .) {
            if (cadftau_i < -K1) cadftau_i = -K1
            if (cadftau_i > K2)  cadftau_i = K2
        }
        
        cadftau_vec[i, 1] = cadftau_i
    }
    
    st_matrix(cadftau_matname, cadftau_vec)
    st_matrix(cadf_ind_matname, cadf_ind)
}


void _xtpqroot_simulate_pvalues(
    real scalar N,
    real scalar T,
    real scalar maxlag,
    string scalar model,
    real scalar reps,
    string scalar quantile_str,
    real scalar K1,
    real scalar K2,
    real scalar cips_obs,
    string scalar cips_matname,
    string scalar cipstau_matname,
    string scalar cadf_ind_matname,
    real scalar do_individual
)
{
    real rowvector taus, lambda_vec
    real scalar nq, use_trend, rep, i, j, tt
    real colvector sim_cips, g
    real matrix sim_cipstau, Y_panel, E_panel
    real colvector ybar, dybar, cadf_vec, yi
    real matrix cadftau_mat_sim
    real scalar t_start, t_eff
    real colvector dep, yi_lag, ybar_lag, dybar_curr
    real matrix X
    real colvector dyi, dybar_lj, dyi_lj, bhat, resid
    real matrix XtX, XtXinv
    real scalar sigma2, se_rho, t_stat, tau_j
    real colvector bq, resid_q
    real scalar hn, se_q, tq, tau_plus, tau_minus
    real colvector valid_cips, valid_ct
    real scalar pval_cips, obs_ct, pval_ct
    real matrix cips_res, cipstau_res
    real colvector sorted_resid, mx_resid
    real scalar idx_plus, idx_minus, q_plus, q_minus, s_hat
    real matrix X_nolag, XnXn_inv
    real scalar rss_mx
    // Per-panel p-value accumulators (only allocated when needed)
    real matrix sim_cadf_ind, sim_cadftau_ind
    real matrix cadf_ind_obs
    real scalar obs_val, n_valid, pval_ind
    real colvector valid_sim
    // Vectorized DGP
    real matrix Z_norm, chi2_vals
    
    taus = strtoreal(tokens(quantile_str))
    nq = cols(taus)
    sim_cips = J(reps, 1, .)
    sim_cipstau = J(reps, nq, .)
    use_trend = (model == "trend")
    
    // Only allocate individual accumulators if needed
    if (do_individual) {
        sim_cadf_ind = J(reps, N, .)
        sim_cadftau_ind = J(reps, N * nq, .)
    }
    
    for (rep = 1; rep <= reps; rep++) {
        // === Vectorized DGP: generate all N panels at once ===
        g = rnormal(T, 1, 0, 1)
        
        // Vectorized t(5) errors: z/sqrt(chi2_5/5) where chi2_5 = sum of 5 N(0,1)^2
        Z_norm = rnormal(T, N, 0, 1)
        chi2_vals = rnormal(T*N, 5, 0, 1)
        chi2_vals = rowsum(chi2_vals :^ 2)
        chi2_vals = colshape(chi2_vals, N)
        E_panel = sqrt(5/3) :* Z_norm :/ sqrt(chi2_vals :/ 5)
        
        // Random loadings and random walk
        lambda_vec = runiform(1, N) :* 2
        Y_panel = J(T, N, 0)
        Y_panel[1, .] = lambda_vec :* g[1] + E_panel[1, .]
        for (tt = 2; tt <= T; tt++) {
            Y_panel[tt, .] = Y_panel[tt-1, .] + lambda_vec :* g[tt] + E_panel[tt, .]
        }
        
        ybar = mean(Y_panel')'
        dybar = ybar[2..T] - ybar[1..T-1]
        dybar = (.\dybar)
        
        cadf_vec = J(N, 1, .)
        cadftau_mat_sim = J(N, nq, .)
        
        for (i = 1; i <= N; i++) {
            yi = Y_panel[., i]
            t_start = maxlag + 2
            t_eff = T - t_start + 1
            
            if (t_eff < 10) continue
            
            dep      = yi[t_start..T]
            yi_lag   = yi[(t_start-1)..(T-1)]
            ybar_lag = ybar[(t_start-1)..(T-1)]
            dybar_curr = dybar[t_start..T]
            
            X = J(t_eff, 1, 1), yi_lag, ybar_lag, dybar_curr
            
            if (use_trend) {
                X = X, (t_start..T)'
            }
            
            dyi = yi[2..T] - yi[1..T-1]
            dyi = (.\dyi)
            
            for (j = 1; j <= maxlag; j++) {
                dybar_lj = J(T, 1, .)
                dyi_lj   = J(T, 1, .)
                for (tt = j+1; tt <= T; tt++) {
                    dybar_lj[tt] = dybar[tt-j]
                    dyi_lj[tt]   = dyi[tt-j]
                }
                X = X, dybar_lj[t_start..T], dyi_lj[t_start..T]
            }
            
            // Replace missings with 0 (vectorized)
            X = editmissing(X, 0)
            
            XtX = cross(X, X)
            if (det(XtX) < 1e-15) continue
            
            XtXinv = invsym(XtX)
            bhat = XtXinv * cross(X, dep)
            resid = dep - X * bhat
            sigma2 = cross(resid, resid) / (t_eff - cols(X))
            se_rho = sqrt(sigma2 * XtXinv[2,2])
            
            if (se_rho > 0 & se_rho < .) {
                t_stat = (bhat[2] - 1) / se_rho
                // Store un-truncated for individual p-values (only if needed)
                if (do_individual) sim_cadf_ind[rep, i] = t_stat
                // Truncate for aggregate CIPS
                if (t_stat < -K1) t_stat = -K1
                if (t_stat > K2)  t_stat = K2
                cadf_vec[i] = t_stat
            }
            
            for (j = 1; j <= nq; j++) {
                tau_j = taus[j]
                bq = _xtpqroot_qreg(dep, X, tau_j, 20)
                
                if (bq != J(0,0,.)) {
                    resid_q = dep - X * bq
                    
                    hn = t_eff^(-1/5) * ((4.5 * normalden(invnormal(tau_j))^4) / (2*invnormal(tau_j)^2 + 1)^2)^(1/5)
                    if (hn < min((0.49, 5.0/t_eff))) hn = min((0.49, 5.0/t_eff))
                    if (hn > 0.49) hn = 0.49
                    
                    tau_plus  = min((tau_j + hn, 0.999))
                    tau_minus = max((tau_j - hn, 0.001))
                    
                    sorted_resid = sort(resid_q, 1)
                    idx_plus  = max((1, min((t_eff, ceil(tau_plus * t_eff)))))
                    idx_minus = max((1, min((t_eff, ceil(tau_minus * t_eff)))))
                    q_plus  = sorted_resid[idx_plus]
                    q_minus = sorted_resid[idx_minus]
                    
                    s_hat = (q_plus - q_minus) / (2 * hn)
                    if (s_hat < 1e-10 | s_hat >= .) s_hat = 1
                    
                    X_nolag = X[., 1], X[., 3..cols(X)]
                    XnXn_inv = invsym(cross(X_nolag, X_nolag))
                    mx_resid = yi_lag - X_nolag * (XnXn_inv * cross(X_nolag, yi_lag))
                    rss_mx = cross(mx_resid, mx_resid)
                    
                    if (rss_mx > 0) {
                        se_q = sqrt(tau_j * (1 - tau_j)) * s_hat / sqrt(rss_mx)
                        
                        if (se_q > 0 & se_q < .) {
                            tq = (bq[2] - 1) / se_q
                            if (do_individual) sim_cadftau_ind[rep, (i-1)*nq + j] = tq
                            if (tq < -K1) tq = -K1
                            if (tq > K2)  tq = K2
                            cadftau_mat_sim[i, j] = tq
                        }
                    }
                }
            }
        }
        
        valid_cips = select(cadf_vec, cadf_vec :< .)
        if (rows(valid_cips) > 0) {
            sim_cips[rep] = mean(valid_cips)
        }
        
        for (j = 1; j <= nq; j++) {
            valid_ct = select(cadftau_mat_sim[.,j], cadftau_mat_sim[.,j] :< .)
            if (rows(valid_ct) > 0) {
                sim_cipstau[rep, j] = mean(valid_ct)
            }
        }
    }
    
    // === Aggregate p-values (CIPS, CIPS(tau)) ===
    valid_cips = select(sim_cips, sim_cips :< .)
    pval_cips = sum(valid_cips :<= cips_obs) / rows(valid_cips)
    
    cips_res = (cips_obs, pval_cips)
    st_matrix(cips_matname, cips_res)
    
    cipstau_res = st_matrix(cipstau_matname)
    for (j = 1; j <= nq; j++) {
        valid_ct = select(sim_cipstau[.,j], sim_cipstau[.,j] :< .)
        obs_ct = cipstau_res[j, 2]
        if (rows(valid_ct) > 0 & obs_ct < .) {
            pval_ct = sum(valid_ct :<= obs_ct) / rows(valid_ct)
        }
        else {
            pval_ct = .
        }
        cipstau_res[j, 3] = pval_ct
    }
    st_matrix(cipstau_matname, cipstau_res)
    
    // === Individual panel p-values (only when requested) ===
    if (do_individual) {
        cadf_ind_obs = st_matrix(cadf_ind_matname)
        
        for (i = 1; i <= N; i++) {
            obs_val = cadf_ind_obs[i, 1]
            if (obs_val < .) {
                valid_sim = select(sim_cadf_ind[., i], sim_cadf_ind[., i] :< .)
                n_valid = rows(valid_sim)
                if (n_valid > 0) {
                    pval_ind = sum(valid_sim :<= obs_val) / n_valid
                    cadf_ind_obs[i, 2] = pval_ind
                }
            }
            
            for (j = 1; j <= nq; j++) {
                obs_val = cadf_ind_obs[i, 3 + 3*(j-1) + 1]
                if (obs_val < .) {
                    valid_sim = select(sim_cadftau_ind[., (i-1)*nq + j], sim_cadftau_ind[., (i-1)*nq + j] :< .)
                    n_valid = rows(valid_sim)
                    if (n_valid > 0) {
                        pval_ind = sum(valid_sim :<= obs_val) / n_valid
                        cadf_ind_obs[i, 3 + 3*(j-1) + 2] = pval_ind
                    }
                }
            }
        }
        
        st_matrix(cadf_ind_matname, cadf_ind_obs)
    }
}

// Quantile regression via IRLS - fully vectorized weights
real colvector _xtpqroot_qreg(
    real colvector y,
    real matrix X,
    real scalar tau,
    real scalar maxiter
)
{
    real scalar n, k, iter
    real colvector beta, resid, w, beta_new, abs_r, pos, neg
    real matrix XtWX
    
    n = rows(y)
    k = cols(X)
    
    if (n < k + 2) return(J(0, 0, .))
    
    beta = invsym(cross(X, X)) * cross(X, y)
    
    for (iter = 1; iter <= maxiter; iter++) {
        resid = y - X * beta
        
        // Vectorized weight computation (no per-element loop)
        abs_r = abs(resid)
        abs_r = rowmax((abs_r, J(n, 1, 1e-6)))  // clamp minimum
        pos = (resid :> 1e-6)
        neg = (resid :< -1e-6)
        w = (tau :* pos + (1 - tau) :* neg + (1 :- pos :- neg)) :/ abs_r
        
        XtWX = cross(X, w, X)
        if (det(XtWX) < 1e-15) return(J(0, 0, .))
        
        beta_new = invsym(XtWX) * cross(X, w, y)
        
        if (max(abs(beta_new - beta)) < 1e-8) {
            return(beta_new)
        }
        beta = beta_new
    }
    
    return(beta)
}

// Compute panel-specific QR CADF residuals for CD(tau) test
// Runs a separate quantile regression per panel, stores residuals
void _xtpqroot_cd_qreg_panel(
    string scalar depvar,
    string scalar lyvar,
    string scalar lybarvar,
    string scalar dybarvar,
    string scalar panelvar,
    string scalar tousevar,
    real scalar tau,
    real scalar maxlag,
    real scalar N_panels,
    string scalar residvar
)
{
    real colvector dep_all, ly_all, lybar_all, dybar_all, panel_all
    real colvector unique_panels, sel, dep_i, ly_i, lybar_i, dybar_i
    real colvector dep_full, dy_i, dybar_lj, dy_lj
    real matrix X_i
    real colvector bq, resid_i, full_resid
    real scalar i, n_raw, t_start, tt, jj, rr, cc, t_eff, k, idx, r_idx
    
    st_view(dep_all, ., depvar, tousevar)
    st_view(ly_all, ., lyvar, tousevar)
    st_view(lybar_all, ., lybarvar, tousevar)
    st_view(dybar_all, ., dybarvar, tousevar)
    st_view(panel_all, ., panelvar, tousevar)
    
    unique_panels = uniqrows(panel_all)
    full_resid = J(rows(dep_all), 1, .)
    
    for (i = 1; i <= rows(unique_panels); i++) {
        if (i > N_panels) break
        
        sel = (panel_all :== unique_panels[i])
        dep_i = select(dep_all, sel)
        ly_i  = select(ly_all, sel)
        lybar_i = select(lybar_all, sel)
        dybar_i = select(dybar_all, sel)
        n_raw = rows(dep_i)
        
        // Find first non-missing observation
        t_start = n_raw + 1
        for (tt = 1; tt <= n_raw; tt++) {
            if (dep_i[tt] < . & ly_i[tt] < . & lybar_i[tt] < . & dybar_i[tt] < .) {
                t_start = tt
                break
            }
        }
        t_start = t_start + maxlag
        
        if (t_start <= n_raw) {
            t_eff = n_raw - t_start + 1
            
            if (t_eff >= 8) {
                // Build X: intercept, ly, lybar, dybar
                X_i = J(t_eff, 1, 1), ly_i[t_start..n_raw], lybar_i[t_start..n_raw], dybar_i[t_start..n_raw]
                dep_i = dep_i[t_start..n_raw]
                
                // Compute dy_i for full panel
                dep_full = select(dep_all, sel)
                dy_i = J(n_raw, 1, .)
                for (tt = 2; tt <= n_raw; tt++) {
                    if (dep_full[tt] < . & dep_full[tt-1] < .) {
                        dy_i[tt] = dep_full[tt] - dep_full[tt-1]
                    }
                }
                
                // Add lagged dybar and dy
                for (jj = 1; jj <= maxlag; jj++) {
                    dybar_lj = J(t_eff, 1, 0)
                    dy_lj = J(t_eff, 1, 0)
                    for (tt = t_start; tt <= n_raw; tt++) {
                        if (tt - jj >= 1) {
                            if (dybar_i[tt - jj] < .) dybar_lj[tt - t_start + 1] = dybar_i[tt - jj]
                            if (dy_i[tt - jj] < .)    dy_lj[tt - t_start + 1] = dy_i[tt - jj]
                        }
                    }
                    X_i = X_i, dybar_lj, dy_lj
                }
                
                // Replace remaining missings with 0
                for (rr = 1; rr <= rows(X_i); rr++) {
                    for (cc = 1; cc <= cols(X_i); cc++) {
                        if (X_i[rr,cc] == .) X_i[rr,cc] = 0
                    }
                }
                
                k = cols(X_i)
                if (det(cross(X_i, X_i)) >= 1e-15) {
                    bq = _xtpqroot_qreg(dep_i, X_i, tau, 50)
                    if (bq != J(0,0,.)) {
                        resid_i = dep_i - X_i * bq
                        // Store residuals back into the panel's positions
                        idx = 0
                        r_idx = 0
                        for (tt = 1; tt <= rows(dep_all); tt++) {
                            if (sel[tt]) {
                                idx = idx + 1
                                if (idx >= t_start) {
                                    r_idx = r_idx + 1
                                    full_resid[tt] = resid_i[r_idx]
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    st_store(., residvar, tousevar, full_resid)
}

// CD test for cross-sectional dependence
void _xtpqroot_cd_test(
    string scalar residvar,
    string scalar panelvar,
    string scalar timevar,
    string scalar touse,
    real scalar N,
    real scalar T,
    string scalar cd_matname,
    real scalar row
)
{
    real matrix resid_panel
    real colvector resid_vec, panel_ids, time_ids
    real colvector unique_panels, unique_times
    real scalar n_actual, t_actual, i, j, t_idx, r_idx
    real scalar cd_stat, sum_rho, valid_t, corr_ij, cd_pval
    real colvector ri, rj, sel
    real matrix cd_res
    
    st_view(resid_vec, ., residvar, touse)
    st_view(panel_ids, ., panelvar, touse)
    st_view(time_ids, ., timevar, touse)
    
    unique_panels = uniqrows(panel_ids)
    unique_times  = uniqrows(time_ids)
    
    n_actual = rows(unique_panels)
    t_actual = rows(unique_times)
    
    resid_panel = J(t_actual, n_actual, .)
    
    for (i = 1; i <= n_actual; i++) {
        for (t_idx = 1; t_idx <= t_actual; t_idx++) {
            for (r_idx = 1; r_idx <= rows(resid_vec); r_idx++) {
                if (panel_ids[r_idx] == unique_panels[i] & time_ids[r_idx] == unique_times[t_idx]) {
                    resid_panel[t_idx, i] = resid_vec[r_idx]
                    break
                }
            }
        }
    }
    
    sum_rho = 0
    for (i = 1; i <= n_actual - 1; i++) {
        for (j = i + 1; j <= n_actual; j++) {
            ri = resid_panel[., i]
            rj = resid_panel[., j]
            
            sel = (ri :< . :& rj :< .)
            valid_t = sum(sel)
            if (valid_t > 3) {
                ri = select(ri, sel)
                rj = select(rj, sel)
                corr_ij = correlation((ri, rj))
                corr_ij = corr_ij[1,2]
                sum_rho = sum_rho + corr_ij
            }
        }
    }
    
    cd_stat = sqrt(2 * t_actual / (n_actual * (n_actual - 1))) * sum_rho
    cd_pval = 2 * (1 - normal(abs(cd_stat)))
    
    cd_res = st_matrix(cd_matname)
    cd_res[row, 1] = cd_stat
    cd_res[row, 2] = cd_pval
    st_matrix(cd_matname, cd_res)
}

// =========================================================================
// Compute rho(tau) for persistence graph - replaces N*99 Stata qreg calls
// =========================================================================
void _xtpqroot_rho_graph(
    string scalar depvar,
    string scalar lyvar,
    string scalar lybarvar,
    string scalar dybarvar,
    string scalar panelvar,
    string scalar tousevar,
    real scalar maxlag,
    real scalar N_panels,
    real scalar nq_fine,
    string scalar rho_matname
)
{
    real colvector dep_all, ly_all, lybar_all, dybar_all, panel_all
    real colvector unique_panels, sel, dep_i, ly_i, lybar_i, dybar_i
    real colvector dep_full, dy_i, dybar_lj, dy_lj
    real matrix X_i, rho_mat
    real colvector bq
    real scalar i, n_raw, t_start, t_eff, tt, jj, kk, rr, cc
    real scalar tau_fine
    
    st_view(dep_all, ., depvar, tousevar)
    st_view(ly_all, ., lyvar, tousevar)
    st_view(lybar_all, ., lybarvar, tousevar)
    st_view(dybar_all, ., dybarvar, tousevar)
    st_view(panel_all, ., panelvar, tousevar)
    
    unique_panels = uniqrows(panel_all)
    rho_mat = st_matrix(rho_matname)
    
    for (i = 1; i <= rows(unique_panels); i++) {
        if (i > N_panels) break
        
        sel = (panel_all :== unique_panels[i])
        dep_i = select(dep_all, sel)
        ly_i  = select(ly_all, sel)
        lybar_i = select(lybar_all, sel)
        dybar_i = select(dybar_all, sel)
        n_raw = rows(dep_i)
        
        // Find first non-missing observation
        t_start = n_raw + 1
        for (tt = 1; tt <= n_raw; tt++) {
            if (dep_i[tt] < . & ly_i[tt] < . & lybar_i[tt] < . & dybar_i[tt] < .) {
                t_start = tt
                break
            }
        }
        t_start = t_start + maxlag
        
        if (t_start > n_raw) continue
        t_eff = n_raw - t_start + 1
        if (t_eff < 8) continue
        
        // Build X: intercept, ly, lybar, dybar
        X_i = J(t_eff, 1, 1), ly_i[t_start..n_raw], lybar_i[t_start..n_raw], dybar_i[t_start..n_raw]
        dep_i = dep_i[t_start..n_raw]
        
        // Compute dy_i for full panel
        dep_full = select(dep_all, sel)
        dy_i = J(n_raw, 1, .)
        for (tt = 2; tt <= n_raw; tt++) {
            if (dep_full[tt] < . & dep_full[tt-1] < .) {
                dy_i[tt] = dep_full[tt] - dep_full[tt-1]
            }
        }
        
        // Add lagged dybar and dy
        for (jj = 1; jj <= maxlag; jj++) {
            dybar_lj = J(t_eff, 1, 0)
            dy_lj = J(t_eff, 1, 0)
            for (tt = t_start; tt <= n_raw; tt++) {
                if (tt - jj >= 1) {
                    if (dybar_i[tt - jj] < .) dybar_lj[tt - t_start + 1] = dybar_i[tt - jj]
                    if (dy_i[tt - jj] < .)    dy_lj[tt - t_start + 1] = dy_i[tt - jj]
                }
            }
            X_i = X_i, dybar_lj, dy_lj
        }
        
        // Replace remaining missings with 0 (vectorized)
        X_i = editmissing(X_i, 0)
        
        if (det(cross(X_i, X_i)) < 1e-15) continue
        
        // Run qreg at each of 99 quantiles (reuses compiled _xtpqroot_qreg)
        for (kk = 1; kk <= nq_fine; kk++) {
            tau_fine = kk / 100
            bq = _xtpqroot_qreg(dep_i, X_i, tau_fine, 20)
            if (bq != J(0,0,.)) {
                rho_mat[i, kk] = bq[2]
            }
        }
    }
    
    st_matrix(rho_matname, rho_mat)
}

end
