*! hatemicoint v1.0.1
*! Tests for cointegration with two unknown regime shifts
*! Author: Dr. Merwan ROUDANE, Independent Researcher
*! Email: merwanroudane920@gmail.com
*! Date: February 2026
*! Reference: Hatemi-J, A. (2008). Tests for cointegration with two unknown 
*! regime shifts with an application to financial market integration.
*! Empirical Economics, 35, 497-505.
*! 
*! Version history:
*! v1.0.1 - Added model() option and iid kernel option to match GAUSS implementation
*! v1.0.0 - Initial release

program define hatemicoint, rclass
    version 14.0
    
    syntax varlist(min=2 numeric ts) [if] [in] , ///
        [ ///
        Maxlags(integer 8) ///
        LAGSelection(string) ///
        Kernel(string) ///
        BWL(integer -999) ///
        TRIMming(real 0.15) ///
        Model(integer 3) ///
        ]
    
    marksample touse
    qui count if `touse'
    if r(N) == 0 error 2000
    local nobs = r(N)
    
    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'
    
    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use single time series."
        exit 198
    }
    
    if "`timevar'" == "" {
        di as error "Time variable not set. Use {bf:tsset} to set time variable."
        exit 198
    }
    
    preserve
    qui keep if `touse'
    
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    
    if `k' > 4 {
        di as error "Maximum of 4 independent variables allowed (k<=4)"
        exit 198
    }
    
    if `maxlags' < 0 {
        di as error "maxlags() must be non-negative"
        exit 198
    }
    
    if `trimming' <= 0 | `trimming' >= 0.5 {
        di as error "trimming() must be between 0 and 0.5"
        exit 198
    }
    
    if `model' != 3 {
        di as error "Only model=3 (regime shift) is supported"
        exit 198
    }
    
    if "`lagselection'" == "" local lagselection "tstat"
    local lagselection = lower("`lagselection'")
    if !inlist("`lagselection'", "aic", "sic", "tstat") {
        di as error "lagselection() must be: aic, sic, or tstat"
        exit 198
    }
    
    if "`kernel'" == "" local kernel "iid"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'", "iid", "bartlett", "qs", "quadraticspectral") {
        di as error "kernel() must be: iid, bartlett, or qs (quadraticspectral)"
        exit 198
    }
    
    if `bwl' == -999 {
        local bwl = round(4 * (`nobs'/100)^(2/9))
    }
    else if `bwl' <= 0 {
        di as error "bwl() must be positive"
        exit 198
    }
    
    tempname Y X n T1 T2 T3
    
    mkmat `depvar' if `touse', matrix(`Y')
    mkmat `indepvars' if `touse', matrix(`X')
    
    scalar `n' = `nobs'
    scalar `T1' = round(`trimming' * `n')
    scalar `T2' = round((1 - 2*`trimming') * `n')
    scalar `T3' = round((1 - `trimming') * `n')
    
    tempname ADF_min Zt_min Za_min TB1_adf TB2_adf TB1_zt TB2_zt TB1_za TB2_za
    scalar `ADF_min' = 1000
    scalar `Zt_min' = 1000
    scalar `Za_min' = 1000
    scalar `TB1_adf' = 0
    scalar `TB2_adf' = 0
    scalar `TB1_zt' = 0
    scalar `TB2_zt' = 0
    scalar `TB1_za' = 0
    scalar `TB2_za' = 0
    
    tempname DF_mat Zt_mat Za_mat
    
    local rows = `T2' - `T1' + 1
    local cols = `T3' - `T1'*2 + 1
    
    matrix `DF_mat' = J(`rows', `cols', .)
    matrix `Zt_mat' = J(`rows', `cols', .)
    matrix `Za_mat' = J(`rows', `cols', .)
    
    qui {
        forvalues tb1 = `=`T1'' / `=`T2'' {
            forvalues tb2 = `=`tb1' + `T1'' / `=`T3'' {
                
                tempvar du1 du2
                gen byte `du1' = (_n > `tb1')
                gen byte `du2' = (_n > `tb2')
                
                local xvars
                local xcount = 1
                foreach xvar of local indepvars {
                    tempvar du1x`xcount' du2x`xcount'
                    gen double `du1x`xcount'' = `du1' * `xvar'
                    gen double `du2x`xcount'' = `du2' * `xvar'
                    local xvars `xvars' `xvar' `du1x`xcount'' `du2x`xcount''
                    local xcount = `xcount' + 1
                }
                
                tempvar resid
                reg `depvar' `du1' `du2' `xvars'
                predict double `resid', residuals
                
                tempname adf_stat zt_stat za_stat
                
                _compute_adf `resid', maxlags(`maxlags') ic(`lagselection')
                scalar `adf_stat' = r(adf_stat)
                
                _compute_pp `resid', bwl(`bwl') kernel(`kernel')
                scalar `zt_stat' = r(zt_stat)
                scalar `za_stat' = r(za_stat)
                
                local row = `tb1' - `T1' + 1
                local col = `tb2' - `T1'*2 + 1
                
                matrix `DF_mat'[`row', `col'] = `adf_stat'
                matrix `Zt_mat'[`row', `col'] = `zt_stat'
                matrix `Za_mat'[`row', `col'] = `za_stat'
                
                if `adf_stat' < `ADF_min' {
                    scalar `ADF_min' = `adf_stat'
                    scalar `TB1_adf' = `tb1'
                    scalar `TB2_adf' = `tb2'
                }
                
                if `zt_stat' < `Zt_min' {
                    scalar `Zt_min' = `zt_stat'
                    scalar `TB1_zt' = `tb1'
                    scalar `TB2_zt' = `tb2'
                }
                
                if `za_stat' < `Za_min' {
                    scalar `Za_min' = `za_stat'
                    scalar `TB1_za' = `tb1'
                    scalar `TB2_za' = `tb2'
                }
                
                drop `du1' `du2' `resid'
                local xcount = 1
                foreach xvar of local indepvars {
                    drop `du1x`xcount'' `du2x`xcount''
                    local xcount = `xcount' + 1
                }
            }
        }
    }
    
    tempname cv_adfzt cv_za
    _get_critical_values `k'
    matrix `cv_adfzt' = r(cv_adfzt)
    matrix `cv_za' = r(cv_za)
    
    di _n
    di as text "{hline 78}"
    di as text "Hatemi-J Cointegration Test with Two Unknown Regime Shifts"
    di as text "{hline 78}"
    di as text "Reference: Hatemi-J, A. (2008). Empirical Economics, 35, 497-505."
    di as text "{hline 78}"
    di _n
    di as text "Dependent variable: " as result "`depvar'"
    di as text "Independent variables: " as result "`indepvars'"
    di as text "Number of observations: " as result %8.0f `nobs'
    di as text "Number of regressors (k): " as result %8.0f `k'
    di as text "Trimming rate: " as result %8.3f `trimming'
    di as text "Maximum lags: " as result %8.0f `maxlags'
    di as text "Lag selection: " as result "`lagselection'"
    di as text "Kernel: " as result "`kernel'"
    if "`kernel'" != "iid" {
        di as text "Bandwidth: " as result %8.0f `bwl'
    }
    di _n
    
    di as text "{hline 78}"
    di as text "Test Results"
    di as text "{hline 78}"
    di _n
    di as text %12s "Test" " " %12s "Statistic" " " %10s "Break 1" " " %10s "Break 2"
    di as text "{hline 78}"
    di as text %12s "ADF*" " " as result %12.3f `ADF_min' " " %10.0f `TB1_adf' " " %10.0f `TB2_adf'
    di as text %12s "Zt*" " " as result %12.3f `Zt_min' " " %10.0f `TB1_zt' " " %10.0f `TB2_zt'
    di as text %12s "Za*" " " as result %12.3f `Za_min' " " %10.0f `TB1_za' " " %10.0f `TB2_za'
    di as text "{hline 78}"
    di _n
    
    di as text "{hline 78}"
    di as text "Critical Values (ADF* and Zt*)"
    di as text "{hline 78}"
    di as text %12s "Test" " " %12s "1%" " " %12s "5%" " " %12s "10%"
    di as text "{hline 78}"
    di as text %12s "ADF*/Zt*" " " as result %12.3f `cv_adfzt'[1,1] " " %12.3f `cv_adfzt'[1,2] " " %12.3f `cv_adfzt'[1,3]
    di as text "{hline 78}"
    di _n
    
    di as text "{hline 78}"
    di as text "Critical Values (Za*)"
    di as text "{hline 78}"
    di as text %12s "Test" " " %12s "1%" " " %12s "5%" " " %12s "10%"
    di as text "{hline 78}"
    di as text %12s "Za*" " " as result %12.3f `cv_za'[1,1] " " %12.3f `cv_za'[1,2] " " %12.3f `cv_za'[1,3]
    di as text "{hline 78}"
    di _n
    
    di as text "H0: No cointegration"
    di as text "Ha: Cointegration with two regime shifts"
    di _n
    
    di as text "Note: Smaller (more negative) values provide evidence against H0"
    di as text "Break locations are in observation numbers"
    di _n
    
    return scalar adf_min = `ADF_min'
    return scalar tb1_adf = `TB1_adf'
    return scalar tb2_adf = `TB2_adf'
    return scalar zt_min = `Zt_min'
    return scalar tb1_zt = `TB1_zt'
    return scalar tb2_zt = `TB2_zt'
    return scalar za_min = `Za_min'
    return scalar tb1_za = `TB1_za'
    return scalar tb2_za = `TB2_za'
    return scalar nobs = `nobs'
    return scalar k = `k'
    return matrix cv_adfzt = `cv_adfzt'
    return matrix cv_za = `cv_za'
    
    restore
end


program define _compute_adf, rclass
    syntax varname [if] [in], maxlags(integer) ic(string)
    
    marksample touse
    tempvar resid_lag delta_resid
    
    qui gen double `resid_lag' = L.`varlist' if `touse'
    qui gen double `delta_resid' = D.`varlist' if `touse'
    
    if "`ic'" == "tstat" {
        local lag_optimal = 0
        local best_stat = .
        
        forvalues p = `maxlags'(-1)0 {
            local lagterms
            if `p' > 0 {
                forvalues i = 1/`p' {
                    tempvar dlag`i'
                    qui gen double `dlag`i'' = L`i'.`delta_resid' if `touse'
                    local lagterms `lagterms' `dlag`i''
                }
            }
            
            qui reg `delta_resid' `resid_lag' `lagterms' if `touse', nocons
            
            if `p' > 0 {
                local last_coef = _b[`dlag`p'']
                local last_se = _se[`dlag`p'']
                local t_stat = abs(`last_coef'/`last_se')
                
                if `t_stat' > 1.645 {
                    local lag_optimal = `p'
                    continue, break
                }
            }
            else {
                local lag_optimal = 0
                continue, break
            }
        }
    }
    else if "`ic'" == "aic" {
        local lag_optimal = 0
        local best_ic = .
        
        forvalues p = 0/`maxlags' {
            local lagterms
            if `p' > 0 {
                forvalues i = 1/`p' {
                    tempvar dlag`i'
                    qui gen double `dlag`i'' = L`i'.`delta_resid' if `touse'
                    local lagterms `lagterms' `dlag`i''
                }
            }
            
            qui reg `delta_resid' `resid_lag' `lagterms' if `touse', nocons
            local aic_val = ln(e(rss)/e(N)) + 2*(1+`p')/e(N)
            
            if `best_ic' == . | `aic_val' < `best_ic' {
                local best_ic = `aic_val'
                local lag_optimal = `p'
            }
        }
    }
    else {
        local lag_optimal = 0
        local best_ic = .
        
        forvalues p = 0/`maxlags' {
            local lagterms
            if `p' > 0 {
                forvalues i = 1/`p' {
                    tempvar dlag`i'
                    qui gen double `dlag`i'' = L`i'.`delta_resid' if `touse'
                    local lagterms `lagterms' `dlag`i''
                }
            }
            
            qui reg `delta_resid' `resid_lag' `lagterms' if `touse', nocons
            local sic_val = ln(e(rss)/e(N)) + (1+`p')*ln(e(N))/e(N)
            
            if `best_ic' == . | `sic_val' < `best_ic' {
                local best_ic = `sic_val'
                local lag_optimal = `p'
            }
        }
    }
    
    local lagterms
    if `lag_optimal' > 0 {
        forvalues i = 1/`lag_optimal' {
            tempvar dlag`i'
            qui gen double `dlag`i'' = L`i'.`delta_resid' if `touse'
            local lagterms `lagterms' `dlag`i''
        }
    }
    
    qui reg `delta_resid' `resid_lag' `lagterms' if `touse', nocons
    local adf_stat = _b[`resid_lag']/_se[`resid_lag']
    
    return scalar adf_stat = `adf_stat'
    return scalar lags = `lag_optimal'
end


program define _compute_pp, rclass
    syntax varname [if] [in], bwl(integer) kernel(string)
    
    marksample touse
    qui count if `touse'
    local T = r(N)
    
    tempvar resid_lag delta_resid
    qui gen double `resid_lag' = L.`varlist' if `touse'
    qui gen double `delta_resid' = D.`varlist' if `touse'
    
    qui reg `delta_resid' `resid_lag' if `touse', nocons
    tempname rho_hat
    scalar `rho_hat' = _b[`resid_lag']
    
    tempvar u_hat
    qui predict double `u_hat' if `touse', residuals
    
    tempname gamma0
    qui egen double temp_mean_u = mean(`u_hat') if `touse'
    qui gen double temp_u_sq = (`u_hat' - temp_mean_u)^2 if `touse'
    qui su temp_u_sq if `touse', meanonly
    scalar `gamma0' = r(sum)/r(N)
    qui drop temp_mean_u temp_u_sq
    
    tempname lrvar
    scalar `lrvar' = `gamma0'
    
    if "`kernel'" != "iid" {
        forvalues j = 1/`bwl' {
            tempvar u_t u_tlag
            qui gen double `u_t' = `u_hat' if `touse'
            qui gen double `u_tlag' = L`j'.`u_hat' if `touse'
            qui egen double temp_mean_ut = mean(`u_t') if `touse'
            qui egen double temp_mean_utlag = mean(`u_tlag') if `touse'
            qui gen double temp_prod = (`u_t' - temp_mean_ut)*(`u_tlag' - temp_mean_utlag) if `touse'
            qui su temp_prod if `touse', meanonly
            
            tempname gammaj
            scalar `gammaj' = r(sum)/r(N)
            
            if "`kernel'" == "bartlett" {
                local weight = 1 - `j'/(`bwl'+1)
                scalar `lrvar' = `lrvar' + 2*`weight'*`gammaj'
            }
            else {
                local x = 6*_pi*`j'/`bwl'
                if `j' > 0 {
                    local weight = 3/((`x')^2) * (sin(`x')/`x' - cos(`x'))
                    scalar `lrvar' = `lrvar' + 2*`weight'*`gammaj'
                }
            }
            qui drop temp_mean_ut temp_mean_utlag temp_prod
        }
    }
    
    tempname sum_resid2
    qui egen double temp_mean_resid = mean(`varlist') if `touse'
    qui gen double temp_resid_sq = (`varlist' - temp_mean_resid)^2
    qui su temp_resid_sq if `touse', meanonly
    scalar `sum_resid2' = r(sum)
    qui drop temp_mean_resid temp_resid_sq
    
    tempname lambda2
    scalar `lambda2' = `lrvar' - `gamma0'
    
    tempname rho_star
    scalar `rho_star' = `rho_hat' - `lambda2'/`sum_resid2'
    
    tempname za_stat zt_stat
    scalar `za_stat' = `T' * `rho_star'
    scalar `zt_stat' = `rho_star' * sqrt(`lrvar'/`sum_resid2' * `T')
    
    return scalar zt_stat = `zt_stat'
    return scalar za_stat = `za_stat'
end


program define _get_critical_values, rclass
    args k
    
    tempname cv_adfzt cv_za
    
    if `k' == 1 {
        matrix `cv_adfzt' = (-6.503, -6.015, -5.653)
        matrix `cv_za' = (-90.794, -76.003, -52.232)
    }
    else if `k' == 2 {
        matrix `cv_adfzt' = (-6.928, -6.458, -6.224)
        matrix `cv_za' = (-99.458, -83.644, -76.806)
    }
    else if `k' == 3 {
        matrix `cv_adfzt' = (-7.833, -7.352, -7.118)
        matrix `cv_za' = (-118.577, -104.860, -97.749)
    }
    else if `k' == 4 {
        matrix `cv_adfzt' = (-8.353, -7.903, -7.705)
        matrix `cv_za' = (-140.135, -123.870, -116.169)
    }
    
    return matrix cv_adfzt = `cv_adfzt'
    return matrix cv_za = `cv_za'
end
