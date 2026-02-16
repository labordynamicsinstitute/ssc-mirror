*! qardl v1.0.0 - Quantile Autoregressive Distributed Lag Model
*! Based on Cho, Kim & Shin (2015), Journal of Econometrics
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

program define qardl, eclass sortpreserve
    version 14.0
    
    syntax varlist(min=2 numeric ts) [if] [in], TAU(numlist >0 <1 sort) ///
        [P(integer 0) Q(integer 0) PMAX(integer 7) QMAX(integer 7) ///
         ECM ROLLing(integer 0) SIMulate(numlist) ///
         WALDtest(string) GRAPH NOCONStant LEVel(cilevel) ///
         WINdow(integer 0) NOTABle]
    
    * Mark sample
    marksample touse
    
    * Preserve touse for later use (ereturn post consumes it)
    tempvar touse2
    qui gen byte `touse2' = `touse'
    
    * Parse variables
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    
    if `k' < 1 {
        di as error "at least one independent variable required"
        exit 198
    }
    
    * Count observations
    qui count if `touse'
    local nobs = r(N)
    
    if `nobs' < 20 {
        di as error "insufficient observations (need at least 20)"
        exit 2001
    }
    
    * Parse tau values
    local ntau : word count `tau'
    tempname tau_vec
    mata: st_matrix("`tau_vec'", strtoreal(tokens(st_local("tau")))')
    
    * Determine p and q orders
    if `p' == 0 & `q' == 0 {
        * BIC-based automatic selection
        di as txt _n "{hline 70}"
        di as txt "  QARDL Lag Order Selection (BIC)"
        di as txt "{hline 70}"
        
        _qardl_icmean `varlist' if `touse', pmax(`pmax') qmax(`qmax')
        local p = r(p_opt)
        local q = r(q_opt)
        tempname bic_grid
        mat `bic_grid' = r(bic_grid)
        
        * Display BIC grid table
        di as txt _n "  BIC Grid: rows = p (AR lags), columns = q (DL lags)"
        di as txt "  {hline 62}"
        
        * Header row: q values
        di as txt "  {ralign 6:p \ q}" _c
        forvalues j = 1/`qmax' {
            di as txt "  {ralign 10:q=`j'}" _c
        }
        di ""
        di as txt "  {hline 62}"
        
        * BIC values
        forvalues i = 1/`pmax' {
            di as txt "  {ralign 6:p=`i'}" _c
            forvalues j = 1/`qmax' {
                local bval = `bic_grid'[`i', `j']
                if `i' == `p' & `j' == `q' {
                    * Highlight optimal with star
                    di as res " " %9.3f `bval' "*" _c
                }
                else {
                    di as txt "  " %9.3f `bval' " " _c
                }
            }
            di ""
        }
        di as txt "  {hline 62}"
        di as res "  Optimal: p = `p', q = `q'" ///
            as txt "  (min BIC = " %9.3f `bic_grid'[`p', `q'] ")"
        di as txt "  * denotes minimum BIC"
        di as txt "{hline 70}"
    }
    else {
        if `p' == 0 local p = 1
        if `q' == 0 local q = 1
    }
    
    * Validate lag orders
    if `p' < 1 {
        di as error "p must be at least 1"
        exit 198
    }
    if `q' < 1 {
        di as error "q must be at least 1"
        exit 198
    }
    
    local maxpq = max(`p', `q')
    if `nobs' <= `maxpq' + `k' + 5 {
        di as error "insufficient observations for specified lag orders"
        exit 2001
    }
    
    * ============================================================
    * Core QARDL Estimation
    * ============================================================
    
    if "`ecm'" == "" {
        * Standard QARDL estimation
        _qardl_estimate `varlist' if `touse', p(`p') q(`q') ///
            tau(`tau') `noconstant'
        
        tempname beta beta_cov phi phi_cov gamma gamma_cov
        mat `beta' = r(beta)
        mat `beta_cov' = r(beta_cov)
        mat `phi' = r(phi)
        mat `phi_cov' = r(phi_cov)
        mat `gamma' = r(gamma)
        mat `gamma_cov' = r(gamma_cov)
        
        tempname bt_raw fh_vec
        mat `bt_raw' = r(bt_raw)
        mat `fh_vec' = r(fh_vec)
        
        * Display results
        if "`notable'" == "" {
            _qardl_display_results `beta' `beta_cov' `phi' `phi_cov' ///
                `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' ///
                "`depvar'" "`indepvars'" 0
        }
        
        * Wald tests if requested
        if "`waldtest'" != "" {
            _qardl_parse_waldtest "`waldtest'" `k' `p' `ntau' 0
            
            * Run default Wald tests (across quantiles)
            _qardl_default_wald `beta' `beta_cov' `phi' `phi_cov' ///
                `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'"
        }
        else {
            * Always run default across-quantile Wald tests
            _qardl_default_wald `beta' `beta_cov' `phi' `phi_cov' ///
                `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'"
        }
        
        * Store results
        ereturn clear
        ereturn post, esample(`touse') obs(`nobs')
        ereturn matrix beta = `beta'
        ereturn matrix beta_cov = `beta_cov'
        ereturn matrix phi = `phi'
        ereturn matrix phi_cov = `phi_cov'
        ereturn matrix gamma = `gamma'
        ereturn matrix gamma_cov = `gamma_cov'
        ereturn matrix tau = `tau_vec'
        ereturn matrix bt_raw = `bt_raw'
        ereturn matrix fh = `fh_vec'
        ereturn scalar p = `p'
        ereturn scalar q = `q'
        ereturn scalar k = `k'
        ereturn scalar ntau = `ntau'
        ereturn local depvar "`depvar'"
        ereturn local indepvars "`indepvars'"
        ereturn local model "qardl"
        ereturn local cmd "qardl"
        ereturn local title "QARDL Estimation"
        ereturn local predict ""
        ereturn local author "Dr Merwan Roudane"
        ereturn local email "merwanroudane920@gmail.com"
    }
    else {
        * QARDL-ECM estimation
        _qardl_ecm `varlist' if `touse', p(`p') q(`q') ///
            tau(`tau') `noconstant'
        
        tempname beta beta_cov phi phi_cov gamma gamma_cov
        tempname phi_ecm phi_ecm_cov theta theta_cov
        
        mat `beta' = r(beta)
        mat `beta_cov' = r(beta_cov)
        mat `phi' = r(phi)
        mat `phi_cov' = r(phi_cov)
        mat `gamma' = r(gamma)
        mat `gamma_cov' = r(gamma_cov)
        mat `phi_ecm' = r(phi_ecm)
        mat `phi_ecm_cov' = r(phi_ecm_cov)
        mat `theta' = r(theta)
        mat `theta_cov' = r(theta_cov)
        
        tempname bt_raw fh_vec
        mat `bt_raw' = r(bt_raw)
        mat `fh_vec' = r(fh_vec)
        
        * Display results
        if "`notable'" == "" {
            _qardl_display_results `beta' `beta_cov' `phi' `phi_cov' ///
                `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' ///
                "`depvar'" "`indepvars'" 1
            
            _qardl_display_ecm `phi_ecm' `phi_ecm_cov' `theta' ///
                `theta_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'"
        }
        
        * Default Wald tests
        _qardl_default_wald `beta' `beta_cov' `phi' `phi_cov' ///
            `gamma' `gamma_cov' `tau_vec' `p' `q' `k' `nobs' "`indepvars'"
        
        * ECM-specific Wald tests
        _qardl_default_ecm_wald `phi_ecm' `phi_ecm_cov' `theta' ///
            `theta_cov' `tau_vec' `p' `q' `k' `nobs'
        
        * Store results
        ereturn clear
        ereturn post, esample(`touse') obs(`nobs')
        ereturn matrix beta = `beta'
        ereturn matrix beta_cov = `beta_cov'
        ereturn matrix phi = `phi'
        ereturn matrix phi_cov = `phi_cov'
        ereturn matrix gamma = `gamma'
        ereturn matrix gamma_cov = `gamma_cov'
        ereturn matrix phi_ecm = `phi_ecm'
        ereturn matrix phi_ecm_cov = `phi_ecm_cov'
        ereturn matrix theta = `theta'
        ereturn matrix theta_cov = `theta_cov'
        ereturn matrix tau = `tau_vec'
        ereturn matrix bt_raw = `bt_raw'
        ereturn matrix fh = `fh_vec'
        ereturn scalar p = `p'
        ereturn scalar q = `q'
        ereturn scalar k = `k'
        ereturn scalar ntau = `ntau'
        ereturn local depvar "`depvar'"
        ereturn local indepvars "`indepvars'"
        ereturn local model "qardl-ecm"
        ereturn local cmd "qardl"
        ereturn local title "QARDL-ECM Estimation"
        ereturn local author "Dr Merwan Roudane"
        ereturn local email "merwanroudane920@gmail.com"
    }
    
    * ============================================================
    * Rolling QARDL
    * ============================================================
    if `rolling' > 0 | `window' > 0 {
        local rwin = max(`rolling', `window')
        if `rwin' == 0 {
            local rwin = max(int(`nobs' * 0.1), `maxpq' + `k' + 10)
        }
        
        di as txt _n "{hline 70}"
        di as txt "  Rolling QARDL Estimation (window = `rwin')"
        di as txt "{hline 70}"
        
        _qardl_rolling `varlist' if `touse2', p(`p') q(`q') ///
            tau(`tau') window(`rwin') `noconstant'
        
        * Store rolling results
        tempname rbeta rgamma rphi rwald_beta rwald_phi rwald_gamma
        mat `rbeta' = r(rolling_beta)
        mat `rgamma' = r(rolling_gamma)
        mat `rphi' = r(rolling_phi)
        mat `rwald_beta' = r(rolling_wald_beta)
        mat `rwald_phi' = r(rolling_wald_phi)
        mat `rwald_gamma' = r(rolling_wald_gamma)
        
        ereturn matrix rolling_beta = `rbeta'
        ereturn matrix rolling_gamma = `rgamma'
        ereturn matrix rolling_phi = `rphi'
        ereturn matrix rolling_wald_beta = `rwald_beta'
        ereturn matrix rolling_wald_phi = `rwald_phi'
        ereturn matrix rolling_wald_gamma = `rwald_gamma'
        ereturn scalar rolling_window = `rwin'
    }
    
    * ============================================================
    * Monte Carlo Simulation
    * ============================================================
    if "`simulate'" != "" {
        local simreps : word 1 of `simulate'
        local simnn : word 2 of `simulate'
        if "`simnn'" == "" local simnn = `nobs'
        
        di as txt _n "{hline 70}"
        di as txt "  Monte Carlo Simulation (reps = `simreps', n = `simnn')"
        di as txt "{hline 70}"
        
        _qardl_simulate, reps(`simreps') nobs(`simnn') p(`p') q(`q') ///
            tau(`tau') k(`k')
        
        * Store simulation results
        tempname sim_res
        mat `sim_res' = r(sim_results)
        ereturn matrix sim_results = `sim_res'
    }
    
    * ============================================================
    * Graphs
    * ============================================================
    if "`graph'" != "" {
        qardl_graph, tau(`tau') p(`p') q(`q') k(`k') ///
            depvar("`depvar'") indepvars("`indepvars'") ///
            `= cond("`ecm'"!="", "ecm", "")'
    }
    
end

* ============================================================
* Display standard QARDL results
* ============================================================
program define _qardl_display_results
    args beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p q k nobs depvar indepvars is_ecm
    
    local ntau = rowsof(`tau_vec')
    
    * Header
    di as txt _n
    di as txt "{hline 70}"
    if `is_ecm' {
        di as res "  QARDL-ECM Estimation Results"
    }
    else {
        di as res "  QARDL Estimation Results"
    }
    di as txt "{hline 70}"
    di as txt "  Cho, Kim & Shin (2015), Journal of Econometrics"
    di as txt "{hline 70}"
    di as txt "  Dep. variable  : " as res "`depvar'"
    di as txt "  Indep. vars    : " as res "`indepvars'"
    di as txt "  Observations   : " as res `nobs'
    di as txt "  QARDL(" as res `p' as txt "," as res `q' as txt ")"
    di as txt "  Quantiles      : " _c
    forvalues i = 1/`ntau' {
        di as res %5.2f `tau_vec'[`i',1] " " _c
    }
    di ""
    di as txt "{hline 70}"
    
    * Long-run parameter: beta
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Long-Run Parameters: {it:beta}(tau)"
    di as txt "  beta_j(tau) = gamma_j(tau) / (1 - sum(phi_i(tau)))"
    di as txt "{hline 70}"
    di as txt "  {ralign 12:Variable}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:t-stat}" _c
    di as txt "  {ralign 10:p-value}"
    di as txt "{hline 70}"
    
    local beta_rows = rowsof(`beta')
    local idx = 1
    * vec() stacks columns: order is [var1_tau1, var2_tau1, var1_tau2, ...]
    * So outer loop = quantile, inner loop = variable
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        di as txt "  {hline 4} tau = " %5.2f `tauval' " {hline 48}"
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            if `idx' <= `beta_rows' {
                local est = `beta'[`idx', 1]
                local var_val = `beta_cov'[`idx', `idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / (`nobs' - 1)
                }
                else {
                    local se = .
                }
                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2 * (1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }
                
                di as txt "  {ralign 12:`v'}" _c
                di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
                di as res "  {ralign 12:" %10.4f `est' "}" _c
                if `se' != . {
                    di as txt "  {ralign 10:" %8.4f `se' "}" _c
                    di as txt "  {ralign 10:" %8.3f `tstat' "}" _c
                    if `pval' < 0.01 {
                        di as err "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else if `pval' < 0.05 {
                        di as res "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else {
                        di as txt "  {ralign 10:" %8.4f `pval' "}"
                    }
                }
                else {
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}"
                }
                local ++idx
            }
        }
    }
    di as txt "{hline 70}"
    
    * Short-run AR parameter: phi
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Short-Run AR Parameters: {it:phi}(tau)"
    di as txt "{hline 70}"
    di as txt "  {ralign 12:Lag}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:t-stat}" _c
    di as txt "  {ralign 10:p-value}"
    di as txt "{hline 70}"
    
    local phi_rows = rowsof(`phi')
    local idx = 1
    * vec() stacks columns: order is [lag1_tau1, lag2_tau1, lag1_tau2, ...]
    * So outer loop = quantile, inner loop = lag
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        di as txt "  {hline 4} tau = " %5.2f `tauval' " {hline 48}"
        forvalues j = 1/`p' {
            if `idx' <= `phi_rows' {
                local est = `phi'[`idx', 1]
                local var_val = `phi_cov'[`idx', `idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else {
                    local se = .
                }
                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2 * (1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }
                
                di as txt "  {ralign 12:L`j'.`depvar'}" _c
                di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
                di as res "  {ralign 12:" %10.4f `est' "}" _c
                if `se' != . {
                    di as txt "  {ralign 10:" %8.4f `se' "}" _c
                    di as txt "  {ralign 10:" %8.3f `tstat' "}" _c
                    if `pval' < 0.01 {
                        di as err "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else if `pval' < 0.05 {
                        di as res "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else {
                        di as txt "  {ralign 10:" %8.4f `pval' "}"
                    }
                }
                else {
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}"
                }
                local ++idx
            }
        }
    }
    di as txt "{hline 70}"
    
    * Short-run impact parameter: gamma
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Short-Run Impact Parameters: {it:gamma}(tau)"
    di as txt "{hline 70}"
    di as txt "  {ralign 12:Variable}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:t-stat}" _c
    di as txt "  {ralign 10:p-value}"
    di as txt "{hline 70}"
    
    local gamma_rows = rowsof(`gamma')
    local idx = 1
    * vec() stacks columns: order is [var1_tau1, var2_tau1, var1_tau2, ...]
    * So outer loop = quantile, inner loop = variable
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        di as txt "  {hline 4} tau = " %5.2f `tauval' " {hline 48}"
        local vnum = 0
        foreach v of local indepvars {
            local ++vnum
            if `idx' <= `gamma_rows' {
                local est = `gamma'[`idx', 1]
                local var_val = `gamma_cov'[`idx', `idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else {
                    local se = .
                }
                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2 * (1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }
                
                di as txt "  {ralign 12:`v'}" _c
                di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
                di as res "  {ralign 12:" %10.4f `est' "}" _c
                if `se' != . {
                    di as txt "  {ralign 10:" %8.4f `se' "}" _c
                    di as txt "  {ralign 10:" %8.3f `tstat' "}" _c
                    if `pval' < 0.01 {
                        di as err "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else if `pval' < 0.05 {
                        di as res "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else {
                        di as txt "  {ralign 10:" %8.4f `pval' "}"
                    }
                }
                else {
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}"
                }
                local ++idx
            }
        }
    }
    di as txt "{hline 70}"
end

* ============================================================
* Display ECM-specific results
* ============================================================
program define _qardl_display_ecm
    args phi_ecm phi_ecm_cov theta theta_cov tau_vec p q k nobs indepvars
    
    local ntau = rowsof(`tau_vec')
    
    * ECM phi parameters
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Short-Run Parameters: {it:phi*}(tau)"
    di as txt "  (Cumulative AR coefficients in ECM parameterization)"
    di as txt "{hline 70}"
    di as txt "  {ralign 12:Lag}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:t-stat}" _c
    di as txt "  {ralign 10:p-value}"
    di as txt "{hline 70}"
    
    local phi_rows = rowsof(`phi_ecm')
    local pp1 = `p' - 1
    if `pp1' < 1 local pp1 = 1
    local idx = 1
    * vec() stacks columns: outer = quantile, inner = lag
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        di as txt "  {hline 4} tau = " %5.2f `tauval' " {hline 48}"
        forvalues j = 1/`pp1' {
            if `idx' <= `phi_rows' {
                local est = `phi_ecm'[`idx', 1]
                local var_val = `phi_ecm_cov'[`idx', `idx']
                if `var_val' > 0 {
                    local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                }
                else {
                    local se = .
                }
                if `se' != . & `se' > 0 {
                    local tstat = `est' / `se'
                    local pval = 2 * (1 - normal(abs(`tstat')))
                }
                else {
                    local tstat = .
                    local pval = .
                }
                
                di as txt "  {ralign 12:phi*_`j'}" _c
                di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
                di as res "  {ralign 12:" %10.4f `est' "}" _c
                if `se' != . {
                    di as txt "  {ralign 10:" %8.4f `se' "}" _c
                    di as txt "  {ralign 10:" %8.3f `tstat' "}" _c
                    if `pval' < 0.01 {
                        di as err "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else if `pval' < 0.05 {
                        di as res "  {ralign 10:" %8.4f `pval' "}"
                    }
                    else {
                        di as txt "  {ralign 10:" %8.4f `pval' "}"
                    }
                }
                else {
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}" _c
                    di as txt "  {ralign 10:    .}"
                }
                local ++idx
            }
        }
    }
    di as txt "{hline 70}"
    
    * Theta parameters
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Short-Run Parameters: {it:theta}(tau)"
    di as txt "  (Impact coefficients of dx in ECM form)"
    di as txt "{hline 70}"
    di as txt "  {ralign 12:Variable}" _c
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:Estimate}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:t-stat}" _c
    di as txt "  {ralign 10:p-value}"
    di as txt "{hline 70}"
    
    local theta_rows = rowsof(`theta')
    local qk = `q' * `k'
    local idx = 1
    * vec() stacks columns: outer = quantile, inner = q*k block
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        di as txt "  {hline 4} tau = " %5.2f `tauval' " {hline 48}"
        forvalues lag = 0/`= `q' - 1' {
            foreach v of local indepvars {
                if `idx' <= `theta_rows' {
                    local est = `theta'[`idx', 1]
                    local var_val = `theta_cov'[`idx', `idx']
                    if `var_val' > 0 {
                        local se = sqrt(`var_val') / sqrt(`nobs' - 1)
                    }
                    else {
                        local se = .
                    }
                    if `se' != . & `se' > 0 {
                        local tstat = `est' / `se'
                        local pval = 2 * (1 - normal(abs(`tstat')))
                    }
                    else {
                        local tstat = .
                        local pval = .
                    }
                    
                    if `q' > 1 {
                        di as txt "  {ralign 12:L`lag'.d.`v'}" _c
                    }
                    else {
                        di as txt "  {ralign 12:d.`v'}" _c
                    }
                    di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
                    di as res "  {ralign 12:" %10.4f `est' "}" _c
                    if `se' != . {
                        di as txt "  {ralign 10:" %8.4f `se' "}" _c
                        di as txt "  {ralign 10:" %8.3f `tstat' "}" _c
                        if `pval' < 0.01 {
                            di as err "  {ralign 10:" %8.4f `pval' "}"
                        }
                        else if `pval' < 0.05 {
                            di as res "  {ralign 10:" %8.4f `pval' "}"
                        }
                        else {
                            di as txt "  {ralign 10:" %8.4f `pval' "}"
                        }
                    }
                    else {
                        di as txt "  {ralign 10:    .}" _c
                        di as txt "  {ralign 10:    .}" _c
                        di as txt "  {ralign 10:    .}"
                    }
                    local ++idx
                }
            }
        }
    }
    di as txt "{hline 70}"
end

* ============================================================
* Default Wald tests across quantiles
* ============================================================
program define _qardl_default_wald
    args beta beta_cov phi phi_cov gamma gamma_cov ///
         tau_vec p q k nobs indepvars
    
    local ntau = rowsof(`tau_vec')
    
    if `ntau' < 2 {
        exit
    }
    
    di as txt _n
    di as txt "{hline 70}"
    di as res "  Wald Tests for Parameter Constancy Across Quantiles"
    di as txt "  H0: parameter(tau_i) = parameter(tau_{i+1})"
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 12:Wald stat}" _c
    di as txt "  {ralign 8:df}" _c
    di as txt "  {ralign 12:p-value}" _c
    di as txt "  {ralign 12:Decision}"
    di as txt "{hline 70}"
    
    * Beta constancy test
    local beta_dim = rowsof(`beta')
    local beta_cov_dim = rowsof(`beta_cov')
    
    if `beta_dim' >= 2 * `k' & `beta_cov_dim' >= 2 * `k' {
        local nrestr = (`ntau' - 1) * `k'
        
        if `nrestr' > 0 & `nrestr' <= `beta_dim' {
            tempname R_beta r_beta wald_beta
            mata: _qardl_build_constancy_R(`k', `ntau', "`R_beta'", "`r_beta'")
            
            capture noisily mata: _qardl_wald_stat("`beta'", "`beta_cov'", "`R_beta'", ///
                "`r_beta'", `nobs', "lr", "`wald_beta'")
            if _rc == 0 {
                local wstat = `wald_beta'[1,1]
                local df = rowsof(matrix(`R_beta'))
                local wpv = chi2tail(`df', abs(`wstat'))
                
                if `wpv' < 0.01      local decision "Reject***"
                else if `wpv' < 0.05 local decision "Reject**"
                else if `wpv' < 0.10 local decision "Reject*"
                else                 local decision "Fail to reject"
                
                di as txt "  {ralign 20:Beta constancy}" _c
                di as res "  {ralign 12:" %10.3f `wstat' "}" _c
                di as txt "  {ralign 8:`df'}" _c
                if `wpv' < 0.05 {
                    di as err "  {ralign 12:" %10.4f `wpv' "}" _c
                    di as err "  {ralign 12:`decision'}"
                }
                else {
                    di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
                    di as txt "  {ralign 12:`decision'}"
                }
            }
        }
    }
    
    * Phi constancy test
    local phi_dim = rowsof(`phi')
    if `phi_dim' >= 2 * `p' {
        tempname R_phi r_phi wald_phi
        mata: _qardl_build_constancy_R(`p', `ntau', "`R_phi'", "`r_phi'")
        
        capture noisily mata: _qardl_wald_stat("`phi'", "`phi_cov'", "`R_phi'", ///
            "`r_phi'", `nobs', "sr", "`wald_phi'")
        if _rc == 0 {
            local wstat = `wald_phi'[1,1]
            local df = rowsof(matrix(`R_phi'))
            local wpv = chi2tail(`df', abs(`wstat'))
            
            if `wpv' < 0.01      local decision "Reject***"
            else if `wpv' < 0.05 local decision "Reject**"
            else if `wpv' < 0.10 local decision "Reject*"
            else                 local decision "Fail to reject"
            
            di as txt "  {ralign 20:Phi constancy}" _c
            di as res "  {ralign 12:" %10.3f `wstat' "}" _c
            di as txt "  {ralign 8:`df'}" _c
            if `wpv' < 0.05 {
                di as err "  {ralign 12:" %10.4f `wpv' "}" _c
                di as err "  {ralign 12:`decision'}"
            }
            else {
                di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
                di as txt "  {ralign 12:`decision'}"
            }
        }
    }
    
    * Gamma constancy test
    local gamma_dim = rowsof(`gamma')
    if `gamma_dim' >= 2 * `k' {
        tempname R_gamma r_gamma wald_gamma
        mata: _qardl_build_constancy_R(`k', `ntau', "`R_gamma'", "`r_gamma'")
        
        capture noisily mata: _qardl_wald_stat("`gamma'", "`gamma_cov'", "`R_gamma'", ///
            "`r_gamma'", `nobs', "sr", "`wald_gamma'")
        if _rc == 0 {
            local wstat = `wald_gamma'[1,1]
            local df = rowsof(matrix(`R_gamma'))
            local wpv = chi2tail(`df', abs(`wstat'))
            
            if `wpv' < 0.01      local decision "Reject***"
            else if `wpv' < 0.05 local decision "Reject**"
            else if `wpv' < 0.10 local decision "Reject*"
            else                 local decision "Fail to reject"
            
            di as txt "  {ralign 20:Gamma constancy}" _c
            di as res "  {ralign 12:" %10.3f `wstat' "}" _c
            di as txt "  {ralign 8:`df'}" _c
            if `wpv' < 0.05 {
                di as err "  {ralign 12:" %10.4f `wpv' "}" _c
                di as err "  {ralign 12:`decision'}"
            }
            else {
                di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
                di as txt "  {ralign 12:`decision'}"
            }
        }
    }
    
    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
    
    * ============================================================
    * ECM Speed-of-Adjustment Table (rho)
    * ============================================================
    * rho(tau) = sum(phi_i(tau)) - 1, the error correction coefficient
    
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Speed of Adjustment: {it:rho}(tau) = SUM {it:phi}_i(tau) - 1"
    di as txt "  (rho < 0 implies convergence to long-run equilibrium)"
    di as txt "{hline 70}"
    di as txt "  {ralign 8:Quantile}" _c
    di as txt "  {ralign 12:rho(tau)}" _c
    di as txt "  {ralign 10:Std.Err.}" _c
    di as txt "  {ralign 10:t-stat}" _c
    di as txt "  {ralign 10:p-value}" _c
    di as txt "  {ralign 8:Signal}"
    di as txt "{hline 70}"
    
    * Compute rho(tau) = sum(phi_i(tau)) - 1 for each quantile
    forvalues t = 1/`ntau' {
        local tauval = `tau_vec'[`t', 1]
        
        * Compute rho = sum(phi) - 1 at this quantile
        local sum_phi = 0
        forvalues i = 1/`p' {
            local phi_idx = (`t' - 1) * `p' + `i'
            local phi_rows = rowsof(`phi')
            if `phi_idx' <= `phi_rows' {
                local sum_phi = `sum_phi' + `phi'[`phi_idx', 1]
            }
        }
        local rho_val = `sum_phi' - 1
        
        * Approximate SE via delta method: SE(rho) = sqrt(sum of phi variances)
        * Since rho = sum(phi) - 1, Var(rho) = sum_i sum_j Cov(phi_i, phi_j)
        local var_rho = 0
        forvalues i = 1/`p' {
            forvalues j = 1/`p' {
                local pi = (`t' - 1) * `p' + `i'
                local pj = (`t' - 1) * `p' + `j'
                local phi_cov_dim = rowsof(`phi_cov')
                if `pi' <= `phi_cov_dim' & `pj' <= `phi_cov_dim' {
                    local var_rho = `var_rho' + `phi_cov'[`pi', `pj']
                }
            }
        }
        
        if `var_rho' > 0 {
            local se_rho = sqrt(`var_rho') / sqrt(`nobs' - 1)
        }
        else {
            local se_rho = .
        }
        
        if `se_rho' != . & `se_rho' > 0 {
            local tstat = `rho_val' / `se_rho'
            local pval = 2 * (1 - normal(abs(`tstat')))
        }
        else {
            local tstat = .
            local pval = .
        }
        
        * Determine convergence signal
        if `rho_val' < 0 {
            local signal "Conv."
        }
        else {
            local signal "Diverg."
        }
        
        di as txt "  {ralign 8:" %5.2f `tauval' "}" _c
        di as res "  {ralign 12:" %10.4f `rho_val' "}" _c
        if `se_rho' != . {
            di as txt "  {ralign 10:" %8.4f `se_rho' "}" _c
            di as txt "  {ralign 10:" %8.3f `tstat' "}" _c
            if `pval' < 0.01 {
                di as err "  {ralign 10:" %8.4f `pval' "}" _c
            }
            else if `pval' < 0.05 {
                di as res "  {ralign 10:" %8.4f `pval' "}" _c
            }
            else {
                di as txt "  {ralign 10:" %8.4f `pval' "}" _c
            }
        }
        else {
            di as txt "  {ralign 10:    .}" _c
            di as txt "  {ralign 10:    .}" _c
            di as txt "  {ralign 10:    .}" _c
        }
        if `rho_val' < 0 {
            di as res "  {ralign 8:`signal'}"
        }
        else {
            di as err "  {ralign 8:`signal'}"
        }
    }
    di as txt "{hline 70}"
    
    * ============================================================
    * Pairwise Equality Tests (Variable-Specific)
    * ============================================================
    if `ntau' >= 2 {
        di as txt _n
        di as txt "{hline 70}"
        di as res "  Pairwise Equality Tests Across Quantiles (by variable)"
        di as txt "  H0: param_v(tau_i) = param_v(tau_j)"
        di as txt "{hline 70}"
        
        * Get list of independent variable names
        local indep_list "`indepvars'"
        
        * --------------- Long-Run beta pairwise ---------------
        di as txt _n "  {bf:Long-Run Parameters (beta)}"
        di as txt "  {hline 66}"
        di as txt "  {ralign 12:Variable}" _c
        di as txt "  {ralign 8:tau_i}" _c
        di as txt "  {ralign 8:tau_j}" _c
        di as txt "  {ralign 10:Wald}" _c
        di as txt "  {ralign 6:df}" _c
        di as txt "  {ralign 10:p-value}" _c
        di as txt "  {ralign 10:Decision}"
        di as txt "  {hline 66}"
        
        local beta_dim = rowsof(`beta')
        local beta_cov_dim = rowsof(`beta_cov')
        
        local vnum = 0
        foreach v of local indep_list {
            local ++vnum
            forvalues i = 1/`ntau' {
                local ti = `tau_vec'[`i', 1]
                local ip1 = `i' + 1
                forvalues j = `ip1'/`ntau' {
                    local tj = `tau_vec'[`j', 1]
                    
                    * beta stacked: [var1_tau1, var2_tau1, var1_tau2, ...]
                    local idx_i = (`i' - 1) * `k' + `vnum'
                    local idx_j = (`j' - 1) * `k' + `vnum'
                    
                    if `idx_i' <= `beta_dim' & `idx_j' <= `beta_dim' ///
                     & `idx_i' <= `beta_cov_dim' & `idx_j' <= `beta_cov_dim' {
                        local b_i = `beta'[`idx_i', 1]
                        local b_j = `beta'[`idx_j', 1]
                        local diff = `b_i' - `b_j'
                        
                        local v_ii = `beta_cov'[`idx_i', `idx_i']
                        local v_jj = `beta_cov'[`idx_j', `idx_j']
                        local v_ij = `beta_cov'[`idx_i', `idx_j']
                        local var_diff = `v_ii' + `v_jj' - 2 * `v_ij'
                        
                        if `var_diff' > 1e-15 {
                            local wstat = (`nobs' - 1)^2 * (`diff')^2 / `var_diff'
                            local wpv = chi2tail(1, abs(`wstat'))
                            
                            if `wpv' < 0.01      local decision "Reject***"
                            else if `wpv' < 0.05 local decision "Reject**"
                            else if `wpv' < 0.10 local decision "Reject*"
                            else                 local decision "Accept"
                            
                            di as txt "  {ralign 12:`v'}" _c
                            di as txt "  {ralign 8:" %5.2f `ti' "}" _c
                            di as txt "  {ralign 8:" %5.2f `tj' "}" _c
                            di as res "  {ralign 10:" %8.3f `wstat' "}" _c
                            di as txt "  {ralign 6:1}" _c
                            if `wpv' < 0.05 {
                                di as err "  {ralign 10:" %8.4f `wpv' "}" _c
                                di as err "  {ralign 10:`decision'}"
                            }
                            else {
                                di as txt "  {ralign 10:" %8.4f `wpv' "}" _c
                                di as txt "  {ralign 10:`decision'}"
                            }
                        }
                    }
                }
            }
            if `vnum' < `k' {
                di as txt "  {hline 66}"
            }
        }
        di as txt "  {hline 66}"
        
        * --------------- Short-Run gamma pairwise ---------------
        di as txt _n "  {bf:Short-Run Impact Parameters (gamma)}"
        di as txt "  {hline 66}"
        di as txt "  {ralign 12:Variable}" _c
        di as txt "  {ralign 8:tau_i}" _c
        di as txt "  {ralign 8:tau_j}" _c
        di as txt "  {ralign 10:Wald}" _c
        di as txt "  {ralign 6:df}" _c
        di as txt "  {ralign 10:p-value}" _c
        di as txt "  {ralign 10:Decision}"
        di as txt "  {hline 66}"
        
        local gamma_dim = rowsof(`gamma')
        local gamma_cov_dim = rowsof(`gamma_cov')
        
        local vnum = 0
        foreach v of local indep_list {
            local ++vnum
            forvalues i = 1/`ntau' {
                local ti = `tau_vec'[`i', 1]
                local ip1 = `i' + 1
                forvalues j = `ip1'/`ntau' {
                    local tj = `tau_vec'[`j', 1]
                    
                    local idx_i = (`i' - 1) * `k' + `vnum'
                    local idx_j = (`j' - 1) * `k' + `vnum'
                    
                    if `idx_i' <= `gamma_dim' & `idx_j' <= `gamma_dim' ///
                     & `idx_i' <= `gamma_cov_dim' & `idx_j' <= `gamma_cov_dim' {
                        local g_i = `gamma'[`idx_i', 1]
                        local g_j = `gamma'[`idx_j', 1]
                        local diff = `g_i' - `g_j'
                        
                        local v_ii = `gamma_cov'[`idx_i', `idx_i']
                        local v_jj = `gamma_cov'[`idx_j', `idx_j']
                        local v_ij = `gamma_cov'[`idx_i', `idx_j']
                        local var_diff = `v_ii' + `v_jj' - 2 * `v_ij'
                        
                        if `var_diff' > 1e-15 {
                            local wstat = (`nobs' - 1) * (`diff')^2 / `var_diff'
                            local wpv = chi2tail(1, abs(`wstat'))
                            
                            if `wpv' < 0.01      local decision "Reject***"
                            else if `wpv' < 0.05 local decision "Reject**"
                            else if `wpv' < 0.10 local decision "Reject*"
                            else                 local decision "Accept"
                            
                            di as txt "  {ralign 12:`v'}" _c
                            di as txt "  {ralign 8:" %5.2f `ti' "}" _c
                            di as txt "  {ralign 8:" %5.2f `tj' "}" _c
                            di as res "  {ralign 10:" %8.3f `wstat' "}" _c
                            di as txt "  {ralign 6:1}" _c
                            if `wpv' < 0.05 {
                                di as err "  {ralign 10:" %8.4f `wpv' "}" _c
                                di as err "  {ralign 10:`decision'}"
                            }
                            else {
                                di as txt "  {ralign 10:" %8.4f `wpv' "}" _c
                                di as txt "  {ralign 10:`decision'}"
                            }
                        }
                    }
                }
            }
            if `vnum' < `k' {
                di as txt "  {hline 66}"
            }
        }
        di as txt "  {hline 66}"
        di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
    }
    di as txt "{hline 70}"
end

* ============================================================
* Default ECM Wald tests
* ============================================================
program define _qardl_default_ecm_wald
    args phi_ecm phi_ecm_cov theta theta_cov tau_vec p q k nobs
    
    local ntau = rowsof(`tau_vec')
    if `ntau' < 2 exit
    
    local pp1 = `p' - 1
    if `pp1' < 1 exit
    
    di as txt _n
    di as txt "{hline 70}"
    di as res "  ECM Wald Tests for Parameter Constancy Across Quantiles"
    di as txt "{hline 70}"
    di as txt "  {ralign 20:Test}" _c
    di as txt "  {ralign 12:Wald stat}" _c
    di as txt "  {ralign 8:df}" _c
    di as txt "  {ralign 12:p-value}" _c
    di as txt "  {ralign 12:Decision}"
    di as txt "{hline 70}"
    
    * Phi-ECM constancy
    tempname R_phi r_phi wald_phi_ecm
    mata: _qardl_build_constancy_R(`pp1', `ntau', "`R_phi'", "`r_phi'")
    
    capture noisily mata: _qardl_wald_stat("`phi_ecm'", "`phi_ecm_cov'", "`R_phi'", ///
        "`r_phi'", `nobs', "sr", "`wald_phi_ecm'")
    if _rc == 0 {
        local wstat = `wald_phi_ecm'[1,1]
        local df = rowsof(matrix(`R_phi'))
        local wpv = chi2tail(`df', abs(`wstat'))
        
        if `wpv' < 0.01      local decision "Reject***"
        else if `wpv' < 0.05 local decision "Reject**"
        else if `wpv' < 0.10 local decision "Reject*"
        else                  local decision "Fail to reject"
        
        di as txt "  {ralign 20:Phi-ECM constancy}" _c
        di as res "  {ralign 12:" %10.3f `wstat' "}" _c
        di as txt "  {ralign 8:`df'}" _c
        if `wpv' < 0.05 {
            di as err "  {ralign 12:" %10.4f `wpv' "}" _c
            di as err "  {ralign 12:`decision'}"
        }
        else {
            di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
            di as txt "  {ralign 12:`decision'}"
        }
    }
    
    * Theta constancy
    local theta_dim = `q' * `k'
    if `theta_dim' > 0 & `ntau' >= 2 {
        tempname R_th r_th wald_theta
        mata: _qardl_build_constancy_R(`theta_dim', `ntau', "`R_th'", "`r_th'")
        
        capture noisily mata: _qardl_wald_stat("`theta'", "`theta_cov'", "`R_th'", ///
            "`r_th'", `nobs', "sr2", "`wald_theta'")
        if _rc == 0 {
            local wstat = `wald_theta'[1,1]
            local df = rowsof(matrix(`R_th'))
            local wpv = chi2tail(`df', abs(`wstat'))
            
            if `wpv' < 0.01      local decision "Reject***"
            else if `wpv' < 0.05 local decision "Reject**"
            else if `wpv' < 0.10 local decision "Reject*"
            else                  local decision "Fail to reject"
            
            di as txt "  {ralign 20:Theta constancy}" _c
            di as res "  {ralign 12:" %10.3f `wstat' "}" _c
            di as txt "  {ralign 8:`df'}" _c
            if `wpv' < 0.05 {
                di as err "  {ralign 12:" %10.4f `wpv' "}" _c
                di as err "  {ralign 12:`decision'}"
            }
            else {
                di as txt "  {ralign 12:" %10.4f `wpv' "}" _c
                di as txt "  {ralign 12:`decision'}"
            }
        }
    }
    
    di as txt "{hline 70}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"
end

* ============================================================
* Parse Wald test specification
* ============================================================
program define _qardl_parse_waldtest
    args spec k p ntau is_ecm
    * placeholder - the default tests handle the typical cases
end

* ============================================================
* Mata functions for Wald tests
* ============================================================
capture mata: mata drop _qardl_build_constancy_R()
capture mata: mata drop _qardl_wald_stat()
capture mata: mata drop _qardl_pairwise_R()

mata:
mata set matastrict off

void _qardl_build_constancy_R(real scalar dim, real scalar ntau,
    string scalar Rname, string scalar rname)
{
    real scalar nrestr, i, j, row
    real matrix R, r
    
    nrestr = (ntau - 1) * dim
    R = J(nrestr, ntau * dim, 0)
    r = J(nrestr, 1, 0)
    
    row = 1
    for (i = 1; i <= ntau - 1; i++) {
        for (j = 1; j <= dim; j++) {
            R[row, (i-1)*dim + j] = 1
            R[row, i*dim + j] = -1
            row++
        }
    }
    
    st_matrix(Rname, R)
    st_matrix(rname, r)
}

void _qardl_wald_stat(string scalar beta_name, string scalar cov_name,
    string scalar R_name, string scalar r_name,
    real scalar nobs, string scalar type, string scalar result_name)
{
    real matrix beta, cov, R, r, diff, RCR, RCR_inv
    real scalar wstat, scale, dim_beta, dim_cov, dim_R
    
    beta = st_matrix(beta_name)
    cov = st_matrix(cov_name)
    R = st_matrix(R_name)
    r = st_matrix(r_name)
    
    dim_beta = rows(beta)
    dim_cov = rows(cov)
    dim_R = cols(R)
    
    // Ensure R columns match beta/cov dimensions
    if (dim_R > dim_beta | dim_R > dim_cov) {
        real scalar min_dim
        min_dim = min((dim_R, dim_beta, dim_cov))
        R = R[., 1..min_dim]
        // Also truncate rows to remove restrictions beyond available params
        real scalar max_restr
        max_restr = min((rows(R), min_dim))
        R = R[1..max_restr, .]
        r = r[1..max_restr]
    }
    
    // Trim beta and cov to match R columns
    if (rows(beta) > cols(R)) {
        beta = beta[1..cols(R), .]
    }
    if (rows(cov) > cols(R) | cols(cov) > cols(R)) {
        real scalar nc
        nc = cols(R)
        cov = cov[1..nc, 1..nc]
    }
    
    diff = R * beta - r
    RCR = R * cov * R'
    
    // Regularize if needed
    RCR = RCR + 1e-12 * I(rows(RCR))
    
    RCR_inv = luinv(RCR)
    
    // Scale factor depends on test type
    if (type == "lr") {
        scale = (nobs - 1)^2
    }
    else if (type == "sr2") {
        scale = (nobs - 2)
    }
    else {
        scale = (nobs - 1)
    }
    
    wstat = scale * diff' * RCR_inv * diff
    
    // Ensure non-negative
    if (wstat < 0) wstat = abs(wstat)
    
    st_matrix(result_name, wstat)
}

real matrix _qardl_pairwise_R(real scalar dim, real scalar ntau,
    real scalar qi, real scalar qj)
{
    real matrix R
    real scalar d
    
    // Build R matrix: dim rows, ntau*dim cols
    // R has I_dim at position (qi-1)*dim+1 and -I_dim at (qj-1)*dim+1
    R = J(dim, ntau * dim, 0)
    for (d = 1; d <= dim; d++) {
        R[d, (qi-1)*dim + d] = 1
        R[d, (qj-1)*dim + d] = -1
    }
    
    return(R)
}

end
