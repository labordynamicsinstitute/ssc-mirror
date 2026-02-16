*! _qardl_rolling v1.1.0 - Rolling window QARDL estimation
*! Translates rollingQardl() from GAUSS (qardl.src)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_rolling, rclass
    version 14.0
    
    syntax varlist(min=2 numeric ts) [if] [in], P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) WINdow(integer) [NOCONStant]
    
    marksample touse
    
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    
    qui count if `touse'
    local nobs = r(N)
    
    if `window' == 0 {
        local window = max(int(`nobs' * 0.1), `p' + `q' + `k' + 10)
    }
    
    local num_est = `nobs' - `window'
    if `num_est' < 1 {
        di as error "window too large for available observations"
        exit 198
    }
    
    local ntau : word count `tau'
    
    * Get first and last obs numbers
    tempvar obsnum
    qui gen long `obsnum' = _n if `touse'
    qui sum `obsnum' if `touse', meanonly
    local first_obs = r(min)
    local last_obs = r(max)
    
    * Storage matrices
    local beta_cols = `k' * `ntau'
    local gamma_cols = `k' * `ntau'
    local phi_cols = `p' * `ntau'
    
    tempname rbeta rgamma rphi rbeta_se rgamma_se rphi_se
    tempname rwald_beta rwald_phi rwald_gamma
    
    mat `rbeta' = J(`num_est', `beta_cols', 0)
    mat `rgamma' = J(`num_est', `gamma_cols', 0)
    mat `rphi' = J(`num_est', `phi_cols', 0)
    mat `rbeta_se' = J(`num_est', `beta_cols', 0)
    mat `rgamma_se' = J(`num_est', `gamma_cols', 0)
    mat `rphi_se' = J(`num_est', `phi_cols', 0)
    mat `rwald_beta' = J(`num_est', 2, 0)
    mat `rwald_phi' = J(`num_est', 2, 0)
    mat `rwald_gamma' = J(`num_est', 2, 0)
    
    * Rolling estimation loop
    tempvar roll_touse
    qui gen byte `roll_touse' = 0
    
    forvalues w = 1/`num_est' {
        local win_start = `first_obs' + `w' - 1
        local win_end = `win_start' + `window' - 1
        
        * Set rolling window sample
        qui replace `roll_touse' = (`obsnum' >= `win_start' & `obsnum' <= `win_end')
        
        * Estimate on this window
        capture {
            _qardl_estimate `varlist' if `roll_touse', p(`p') q(`q') ///
                tau(`tau') `noconstant'
            
            tempname wbeta wbeta_cov wphi wphi_cov wgamma wgamma_cov
            mat `wbeta' = r(beta)
            mat `wbeta_cov' = r(beta_cov)
            mat `wphi' = r(phi)
            mat `wphi_cov' = r(phi_cov)
            mat `wgamma' = r(gamma)
            mat `wgamma_cov' = r(gamma_cov)
            
            * Store beta estimates and SEs
            local ncb = min(rowsof(`wbeta'), `beta_cols')
            forvalues j = 1/`ncb' {
                mat `rbeta'[`w', `j'] = `wbeta'[`j', 1]
                if `wbeta_cov'[`j', `j'] > 0 {
                    mat `rbeta_se'[`w', `j'] = sqrt(`wbeta_cov'[`j', `j']) / (`window' - 1)
                }
            }
            
            * Store gamma estimates and SEs
            local ncg = min(rowsof(`wgamma'), `gamma_cols')
            forvalues j = 1/`ncg' {
                mat `rgamma'[`w', `j'] = `wgamma'[`j', 1]
                if `wgamma_cov'[`j', `j'] > 0 {
                    mat `rgamma_se'[`w', `j'] = sqrt(`wgamma_cov'[`j', `j']) / sqrt(`window' - 1)
                }
            }
            
            * Store phi estimates and SEs
            local ncp = min(rowsof(`wphi'), `phi_cols')
            forvalues j = 1/`ncp' {
                mat `rphi'[`w', `j'] = `wphi'[`j', 1]
                if `wphi_cov'[`j', `j'] > 0 {
                    mat `rphi_se'[`w', `j'] = sqrt(`wphi_cov'[`j', `j']) / sqrt(`window' - 1)
                }
            }
        }
        
        * Progress indicator
        if mod(`w', 50) == 0 {
            di as txt "  Rolling window `w' of `num_est' completed"
        }
    }
    
    * Summary
    di as txt _n "{hline 70}"
    di as res "  Rolling QARDL Summary"
    di as txt "{hline 70}"
    di as txt "  Number of windows  : " as res `num_est'
    di as txt "  Window size        : " as res `window'
    di as txt "{hline 70}"
    
    * Return results
    return matrix rolling_beta = `rbeta'
    return matrix rolling_gamma = `rgamma'
    return matrix rolling_phi = `rphi'
    return matrix rolling_beta_se = `rbeta_se'
    return matrix rolling_gamma_se = `rgamma_se'
    return matrix rolling_phi_se = `rphi_se'
    return matrix rolling_wald_beta = `rwald_beta'
    return matrix rolling_wald_phi = `rwald_phi'
    return matrix rolling_wald_gamma = `rwald_gamma'
    return scalar window = `window'
    return scalar num_est = `num_est'
end
