*! _boundedur_m v1.0.0 Dr. Merwan Roudane 02Feb2026
*! M tests for bounded time series (internal routine)
*! Implements MZ_alpha, MZ_t, and MSB tests from Cavaliere & Xu (2014)

program define _boundedur_m, rclass
    version 14.0
    
    syntax varlist(max=1 ts) [if] [in], ///
        lags(integer) ///
        test(string) ///
        sigma2(real) ///
        [clower(real -999)] ///
        [cupper(real 999)] ///
        [nsim(integer 499)] ///
        [nstep(integer 0)] ///
        [detrend(string)] ///
        [nosimulation]
    
    marksample touse
    
    * Defaults
    if "`detrend'" == "" local detrend "constant"
    local test = lower("`test'")
    
    * Get sample size
    qui count if `touse'
    local T = r(N)
    
    * De-mean the data
    tempvar Xhat
    if "`detrend'" == "constant" {
        qui reg `varlist' if `touse'
        qui predict `Xhat' if `touse', residuals
    }
    else {
        qui gen `Xhat' = `varlist' if `touse'
    }
    
    * Sort data by time variable
    qui tsset
    local timevar `r(timevar)'
    sort `timevar'
    
    * Compute components for M statistics
    * We need: X_hat^2_T, X_hat^2_0, sum(X_hat^2_{t-1}), s^2_AR(k)
    
    tempname Xhat_T Xhat_0 sum_Xhat2_lag s2_AR
    
    * Get first and last values
    qui sum `Xhat' if `touse' & _n == 1
    scalar `Xhat_0' = r(mean)
    qui sum `Xhat' if `touse' & _n == `T'
    scalar `Xhat_T' = r(mean)
    
    * Sum of squared lagged values
    tempvar Xhat_lag2
    qui gen `Xhat_lag2' = L.`Xhat'^2 if `touse'
    qui sum `Xhat_lag2' if `touse'
    scalar `sum_Xhat2_lag' = r(sum)
    
    * Long-run variance (spectral AR estimator already computed)
    scalar `s2_AR' = `sigma2'
    
    * Compute test statistics
    if "`test'" == "mzalpha" {
        * MZ_alpha = (T^{-1}*Xhat_T^2 - T^{-1}*Xhat_0^2 - s^2_AR) / (2*T^{-2}*sum(Xhat^2_{t-1}))
        tempname test_stat
        scalar `test_stat' = (`Xhat_T'^2/`T' - `Xhat_0'^2/`T' - `s2_AR') / ///
                              (2 * `sum_Xhat2_lag' / (`T'^2))
        return scalar mz_alpha = `test_stat'
    }
    else if "`test'" == "msb" {
        * MSB = sqrt(T^{-2}*sum(Xhat^2_{t-1}) / s^2_AR)
        tempname test_stat
        scalar `test_stat' = sqrt(`sum_Xhat2_lag' / (`T'^2 * `s2_AR'))
        return scalar msb = `test_stat'
    }
    else if "`test'" == "mzt" {
        * MZ_t = MZ_alpha * MSB
        tempname mz_alpha msb
        scalar `mz_alpha' = (`Xhat_T'^2/`T' - `Xhat_0'^2/`T' - `s2_AR') / ///
                             (2 * `sum_Xhat2_lag' / (`T'^2))
        scalar `msb' = sqrt(`sum_Xhat2_lag' / (`T'^2 * `s2_AR'))
        
        tempname test_stat
        scalar `test_stat' = `mz_alpha' * `msb'
        return scalar mz_t = `test_stat'
    }
    
    * If simulation requested, compute p-value
    if "`nosimulation'" == "" {
        
        * Set discretization step
        if `nstep' == 0 {
            local nstep = `T'
        }
        
        * Monte Carlo simulation
        tempname mc_stat pval count_below
        scalar `count_below' = 0
        
        forvalues b = 1/`nsim' {
            * Generate i.i.d. N(0,1) innovations
            tempvar epsilon_star
            qui gen `epsilon_star' = rnormal() if _n <= `nstep'
            
            * Generate bounded process
            tempvar X_star
            qui gen `X_star' = 0 if _n == 1
            
            * Recursive generation with reflection at bounds
            forvalues t = 2/`nstep' {
                qui replace `X_star' = ///
                    cond(L.`X_star' + `epsilon_star'/sqrt(`nstep') > `cupper', `cupper', ///
                    cond(L.`X_star' + `epsilon_star'/sqrt(`nstep') < `clower', `clower', ///
                    L.`X_star' + `epsilon_star'/sqrt(`nstep'))) ///
                    if _n == `t'
            }
            
            * De-mean simulated series
            qui sum `X_star' in 1/`nstep'
            local X_star_mean = r(mean)
            tempvar Xstar_tilde
            qui gen `Xstar_tilde' = `X_star' - `X_star_mean' if _n <= `nstep'
            
            * Compute MC statistic components
            qui sum `Xstar_tilde' if _n == 1
            local Xstar_0 = r(mean)
            qui sum `Xstar_tilde' if _n == `nstep'
            local Xstar_T = r(mean)
            
            tempvar Xstar_lag2
            qui gen `Xstar_lag2' = L.`Xstar_tilde'^2 if _n <= `nstep'
            qui sum `Xstar_lag2'
            local sum_Xstar2 = r(sum)
            
            * Compute MC statistic (using unit long-run variance for simulated data)
            if "`test'" == "mzalpha" {
                scalar `mc_stat' = (`Xstar_T'^2/`nstep' - `Xstar_0'^2/`nstep' - 1) / ///
                                    (2 * `sum_Xstar2' / (`nstep'^2))
            }
            else if "`test'" == "msb" {
                scalar `mc_stat' = sqrt(`sum_Xstar2' / (`nstep'^2))
            }
            else if "`test'" == "mzt" {
                local mz_alpha_star = (`Xstar_T'^2/`nstep' - `Xstar_0'^2/`nstep' - 1) / ///
                                       (2 * `sum_Xstar2' / (`nstep'^2))
                local msb_star = sqrt(`sum_Xstar2' / (`nstep'^2))
                scalar `mc_stat' = `mz_alpha_star' * `msb_star'
            }
            
            * Count if MC statistic is in rejection region
            if "`test'" == "msb" {
                * MSB rejects for small values
                if `mc_stat' < `test_stat' {
                    scalar `count_below' = `count_below' + 1
                }
            }
            else {
                * MZ_alpha and MZ_t reject for large negative values
                if `mc_stat' < `test_stat' {
                    scalar `count_below' = `count_below' + 1
                }
            }
            
            * Clean up
            drop `epsilon_star' `X_star' `Xstar_tilde' `Xstar_lag2'
        }
        
        * Compute p-value
        scalar `pval' = `count_below' / `nsim'
        return scalar pval = `pval'
    }
    
end
