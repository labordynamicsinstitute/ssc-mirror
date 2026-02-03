*! _boundedur_adf v1.0.0 Dr. Merwan Roudane 02Feb2026
*! ADF test for bounded time series (internal routine)
*! Implements Algorithm 1 from Cavaliere & Xu (2014)

program define _boundedur_adf, rclass
    version 14.0
    
    syntax varlist(max=1 ts) [if] [in], ///
        lags(integer) ///
        [clower(real -999)] ///
        [cupper(real 999)] ///
        [nsim(integer 499)] ///
        [nstep(integer 0)] ///
        [detrend(string)] ///
        [stat(string)] ///
        [krclag(integer -1)] ///
        [recolor] ///
        [nosimulation]
    
    marksample touse
    
    * Defaults
    if "`detrend'" == "" local detrend "constant"
    if "`stat'" == "" local stat "alpha"
    if `krclag' == -1 local krclag = `lags'
    
    * Get sample size
    qui count if `touse'
    local T = r(N)
    
    * De-mean or de-trend the data
    tempvar Xhat
    if "`detrend'" == "constant" {
        qui reg `varlist' if `touse'
        qui predict `Xhat' if `touse', residuals
    }
    else {
        qui gen `Xhat' = `varlist' if `touse'
    }
    
    * Run ADF regression (Equation 3.7)
    * Delta X_t = alpha * X_{t-1} + sum_i alpha_i * Delta X_{t-i} + epsilon_{t,k}
    
    if `lags' > 0 {
        qui reg D.`Xhat' L.`Xhat' LD(1/`lags').D.`Xhat' if `touse', nocons
    }
    else {
        qui reg D.`Xhat' L.`Xhat' if `touse', nocons
    }
    
    * Extract alpha_hat
    tempname alpha_hat
    scalar `alpha_hat' = _b[L.`Xhat']
    
    * Compute alpha(1) = 1 - sum(alpha_i)
    tempname alpha1_hat
    scalar `alpha1_hat' = 1
    if `lags' > 0 {
        forvalues i = 1/`lags' {
            scalar `alpha1_hat' = `alpha1_hat' - _b[LD`i'.D.`Xhat']
        }
    }
    
    * Standard error of alpha
    tempname se_alpha
    scalar `se_alpha' = _se[L.`Xhat']
    
    * Compute test statistics
    if "`stat'" == "alpha" {
        * ADF_alpha = T*(alpha_hat - 1) / alpha(1)
        tempname test_stat
        scalar `test_stat' = `T' * (`alpha_hat' - 1) / `alpha1_hat'
        return scalar adf_alpha = `test_stat'
    }
    else if "`stat'" == "t" {
        * ADF_t = (alpha_hat - 1) / se(alpha_hat)
        tempname test_stat
        scalar `test_stat' = (`alpha_hat' - 1) / `se_alpha'
        return scalar adf_t = `test_stat'
    }
    
    * If simulation requested, compute p-value
    if "`nosimulation'" == "" {
        
        * Set discretization step
        if `nstep' == 0 {
            local nstep = `T'  // Paper recommendation: n=T
        }
        
        * Get residuals for re-coloring
        tempvar resid
        qui predict `resid' if `touse', residuals
        
        * Estimate re-coloring AR polynomial if requested
        tempname krc_coef
        if "`recolor'" != "" & `krclag' > 0 {
            * Fit AR(krc) to residuals for re-coloring (Section 4.3)
            qui reg D.`Xhat' L.`Xhat' LD(1/`krclag').D.`Xhat' if `touse', nocons
            
            matrix `krc_coef' = J(`krclag', 1, .)
            forvalues i = 1/`krclag' {
                matrix `krc_coef'[`i',1] = _b[LD`i'.D.`Xhat']
            }
        }
        
        * Monte Carlo simulation (Algorithm 1)
        tempname mc_stat pval count_below
        scalar `count_below' = 0
        
        forvalues b = 1/`nsim' {
            * Step (i): Generate i.i.d. N(0,1) innovations
            tempvar epsilon_star
            qui gen `epsilon_star' = rnormal() if `touse'
            
            * Step (ii): Generate re-colored innovations if requested
            tempvar u_star
            if "`recolor'" != "" & `krclag' > 0 {
                * Apply AR filter: u*_t = alpha_krc(L)/alpha_krc(1) * epsilon*_t
                * This implements Equation 4.14
                
                qui gen `u_star' = `epsilon_star' if `touse'
                
                * Apply AR polynomial
                local alpha_krc_1 = 1
                forvalues i = 1/`krclag' {
                    local alpha_krc_1 = `alpha_krc_1' - `krc_coef'[`i',1]
                }
                
                * Initialize
                sort `touse' 
                qui replace `u_star' = `epsilon_star' if _n <= `krclag' & `touse'
                
                * Recursive application
                forvalues i = 1/`krclag' {
                    qui replace `u_star' = `u_star' + ///
                        `krc_coef'[`i',1] * L`i'.`u_star' / `alpha_krc_1' ///
                        if _n > `krclag' & `touse'
                }
            }
            else {
                qui gen `u_star' = `epsilon_star' if `touse'
            }
            
            * Step (ii): Generate bounded process (Equation 4.11 or 4.13)
            tempvar X_star
            qui gen `X_star' = 0 if _n == 1
            
            qui count if `touse'
            local n_sim = min(`nstep', r(N))
            
            * Recursive generation with reflection at bounds
            forvalues t = 2/`n_sim' {
                qui replace `X_star' = ///
                    cond(L.`X_star' + `u_star'/sqrt(`n_sim') > `cupper', `cupper', ///
                    cond(L.`X_star' + `u_star'/sqrt(`n_sim') < `clower', `clower', ///
                    L.`X_star' + `u_star'/sqrt(`n_sim'))) ///
                    if _n == `t'
            }
            
            * De-mean simulated series
            tempvar Xstar_tilde
            qui gen `Xstar_tilde' = `X_star' - sum(`X_star')/`n_sim'
            
            * Step (iii): Compute MC statistic
            if `lags' > 0 {
                qui reg D.`Xstar_tilde' L.`Xstar_tilde' LD(1/`lags').D.`Xstar_tilde', nocons
            }
            else {
                qui reg D.`Xstar_tilde' L.`Xstar_tilde', nocons
            }
            
            tempname alpha_star alpha1_star
            scalar `alpha_star' = _b[L.`Xstar_tilde']
            scalar `alpha1_star' = 1
            if `lags' > 0 {
                forvalues i = 1/`lags' {
                    scalar `alpha1_star' = `alpha1_star' - _b[LD`i'.D.`Xstar_tilde']
                }
            }
            
            if "`stat'" == "alpha" {
                scalar `mc_stat' = `n_sim' * (`alpha_star' - 1) / `alpha1_star'
            }
            else {
                tempname se_alpha_star
                scalar `se_alpha_star' = _se[L.`Xstar_tilde']
                scalar `mc_stat' = (`alpha_star' - 1) / `se_alpha_star'
            }
            
            * Count if MC statistic is below observed
            if `mc_stat' < `test_stat' {
                scalar `count_below' = `count_below' + 1
            }
            
            * Clean up temporary variables for next iteration
            drop `epsilon_star' `u_star' `X_star' `Xstar_tilde'
        }
        
        * Step (iv): Compute p-value (Theorem 2)
        scalar `pval' = `count_below' / `nsim'
        return scalar pval = `pval'
    }
    
end
