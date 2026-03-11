*! _fcoint_feg2.ado -- Modified Fourier Engle-Granger (FEG2) Cointegration Test
*! Implements: Banerjee & Lee (working paper), Eq. (8)
*! "Residual-based Cointegration Tests for Smooth Structural Breaks"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

program define _fcoint_feg2, rclass
  version 14.0
  
  syntax, depvar(string) indepvars(string) touse(string) ///
    model(string) maxfreq(integer) maxlag(integer) ///
    criterion(string) [cumfreq graph]
  
  * ---- Setup ----
  qui tsset
  local tvar = r(timevar)
  
  qui count if `touse'
  local T = r(N)
  
  local nxvars : word count `indepvars'
  
  if `maxlag' <= 0 {
    local maxlag = int(12 * (`T'/100)^0.25)
    if `maxlag' < 1 local maxlag = 1
  }
  
  * ---- 1. Frequency selection: minimize SSR of long-run equation ----
  local best_ssr = 1e30
  local best_k = 1
  local freq_end = min(`maxfreq', 5)
  
  forvalues kk = 1/`freq_end' {
    
    local fvars ""
    if "`cumfreq'" == "" {
      tempvar sn`kk' cn`kk'
      qui gen double `sn`kk'' = sin(2 * _pi * `kk' * `tvar' / `T') if `touse'
      qui gen double `cn`kk'' = cos(2 * _pi * `kk' * `tvar' / `T') if `touse'
      local fvars "`sn`kk'' `cn`kk''"
    }
    else {
      forvalues ff = 1/`kk' {
        tempvar sn`kk'_`ff' cn`kk'_`ff'
        qui gen double `sn`kk'_`ff'' = sin(2 * _pi * `ff' * `tvar' / `T') if `touse'
        qui gen double `cn`kk'_`ff'' = cos(2 * _pi * `ff' * `tvar' / `T') if `touse'
        local fvars "`fvars' `sn`kk'_`ff'' `cn`kk'_`ff''"
      }
    }
    
    local det_rhs "`fvars'"
    if "`model'" == "trend" {
      tempvar trd`kk'
      qui gen double `trd`kk'' = `tvar' if `touse'
      local det_rhs "`det_rhs' `trd`kk''"
    }
    
    capture qui reg `depvar' `indepvars' `det_rhs' if `touse'
    if _rc continue
    
    if e(rss) < `best_ssr' {
      local best_ssr = e(rss)
      local best_k = `kk'
    }
  }
  
  * ---- 2. Re-estimate long-run equation with best k ----
  local fvars_best ""
  if "`cumfreq'" == "" {
    tempvar sinb cosb
    qui gen double `sinb' = sin(2 * _pi * `best_k' * `tvar' / `T') if `touse'
    qui gen double `cosb' = cos(2 * _pi * `best_k' * `tvar' / `T') if `touse'
    local fvars_best "`sinb' `cosb'"
  }
  else {
    forvalues ff = 1/`best_k' {
      tempvar sbf`ff' cbf`ff'
      qui gen double `sbf`ff'' = sin(2 * _pi * `ff' * `tvar' / `T') if `touse'
      qui gen double `cbf`ff'' = cos(2 * _pi * `ff' * `tvar' / `T') if `touse'
      local fvars_best "`fvars_best' `sbf`ff'' `cbf`ff''"
    }
  }
  
  local det_rhs "`fvars_best'"
  if "`model'" == "trend" {
    tempvar trd_b
    qui gen double `trd_b' = `tvar' if `touse'
    local det_rhs "`det_rhs' `trd_b'"
  }
  
  qui reg `depvar' `indepvars' `det_rhs' if `touse'
  
  tempvar resid
  qui predict double `resid' if `touse', resid
  
  * ---- 3. FEG2 testing regression (Eq. 8) ----
  * d(mu_hat) = c + delta * mu_hat(-1) + dx2t' * tau + sum(alpha_i * d(mu_hat(-i))) + eps
  
  tempvar dresid resid_lag1
  qui gen double `dresid' = D.`resid' if `touse'
  qui gen double `resid_lag1' = L.`resid' if `touse'
  
  * First differences of independent variables (contemporaneous)
  local dx_vars ""
  forvalues i = 1/`nxvars' {
    local xv : word `i' of `indepvars'
    tempvar dx`i'
    qui gen double `dx`i'' = D.`xv' if `touse'
    local dx_vars "`dx_vars' `dx`i''"
  }
  
  * Generate lagged differences of residuals
  forvalues j = 1/`maxlag' {
    tempvar dresid_lag`j'
    qui gen double `dresid_lag`j'' = L`j'.`dresid' if `touse'
  }
  
  * ---- General-to-specific lag selection ----
  local opt_lag = `maxlag'
  
  forvalues p = `maxlag'(-1)1 {
    local rhs "`resid_lag1' `dx_vars'"
    forvalues j = 1/`p' {
      local rhs "`rhs' `dresid_lag`j''"
    }
    
    capture qui reg `dresid' `rhs' if `touse'
    if _rc {
      local opt_lag = `p' - 1
      continue
    }
    
    local last_t = abs(_b[`dresid_lag`p''] / _se[`dresid_lag`p''])
    if `last_t' >= 1.645 {
      local opt_lag = `p'
      continue, break
    }
    local opt_lag = `p' - 1
  }
  
  if `opt_lag' < 0 local opt_lag = 0
  
  * ---- 4. Final FEG2 estimation ----
  local rhs_final "`resid_lag1' `dx_vars'"
  forvalues j = 1/`opt_lag' {
    local rhs_final "`rhs_final' `dresid_lag`j''"
  }
  
  qui reg `dresid' `rhs_final' if `touse'
  
  local feg2_tstat = _b[`resid_lag1'] / _se[`resid_lag1']
  local feg2_delta = _b[`resid_lag1']
  local feg2_se = _se[`resid_lag1']
  local feg2_nobs = e(N)
  
  * ---- 5. Estimate rho-squared (long-run squared correlation) ----
  * Eq. (11): rho^2 = sigma_ve^2 / (sigma_eps^2 * sigma_v^2)
  * v_t = residual from FEG regression (Eq. 3, without dx2)
  * eps_t = residual from FEG2 regression (Eq. 8)
  
  * Get FEG residuals (without dx2 augmentation)
  local rhs_feg "`resid_lag1'"
  forvalues j = 1/`opt_lag' {
    local rhs_feg "`rhs_feg' `dresid_lag`j''"
  }
  
  qui reg `dresid' `rhs_feg' if `touse', noconstant
  tempvar vhat
  qui predict double `vhat' if `touse', resid
  
  * eps from FEG2
  tempvar epshat
  qui reg `dresid' `rhs_final' if `touse'
  qui predict double `epshat' if `touse', resid
  
  * Estimate long-run variances using Bartlett kernel
  * Bandwidth: Andrews (1991) rule
  local bw = int(`T'^(1/3))
  
  * Variance of v
  qui summ `vhat' if `touse', meanonly
  local v_mean = r(mean)
  
  tempvar v_dm eps_dm
  qui gen double `v_dm' = `vhat' - `v_mean' if `touse'
  qui gen double `eps_dm' = `epshat' if `touse'
  qui summ `eps_dm' if `touse', meanonly
  qui replace `eps_dm' = `eps_dm' - r(mean) if `touse'
  
  * Autocovariances
  local sigma_v = 0
  local sigma_eps = 0
  local sigma_ve = 0
  
  qui summ `v_dm' if `touse'
  local Nv = r(N)
  
  * Gamma(0)
  tempvar v2 e2 ve
  qui gen double `v2' = `v_dm'^2 if `touse'
  qui gen double `e2' = `eps_dm'^2 if `touse'  
  qui gen double `ve' = `v_dm' * `eps_dm' if `touse'
  
  qui summ `v2' if `touse', meanonly
  local gamma0_v = r(mean)
  qui summ `e2' if `touse', meanonly
  local gamma0_e = r(mean)
  qui summ `ve' if `touse', meanonly
  local gamma0_ve = r(mean)
  
  local sigma_v = `gamma0_v'
  local sigma_eps = `gamma0_e'
  local sigma_ve = `gamma0_ve'
  
  * Add weighted autocovariances
  forvalues j = 1/`bw' {
    local bartlett_w = 1 - `j'/(`bw' + 1)
    
    tempvar v_lag`j' e_lag`j'
    qui gen double `v_lag`j'' = L`j'.`v_dm' if `touse'
    qui gen double `e_lag`j'' = L`j'.`eps_dm' if `touse'
    
    tempvar cv_j ce_j cve_j1 cve_j2
    qui gen double `cv_j' = `v_dm' * `v_lag`j'' if `touse'
    qui gen double `ce_j' = `eps_dm' * `e_lag`j'' if `touse'
    qui gen double `cve_j1' = `v_dm' * `e_lag`j'' if `touse'
    qui gen double `cve_j2' = `eps_dm' * `v_lag`j'' if `touse'
    
    qui summ `cv_j' if `touse', meanonly
    local sigma_v = `sigma_v' + 2 * `bartlett_w' * r(mean)
    
    qui summ `ce_j' if `touse', meanonly
    local sigma_eps = `sigma_eps' + 2 * `bartlett_w' * r(mean)
    
    qui summ `cve_j1' if `touse', meanonly
    local sv1 = r(mean)
    qui summ `cve_j2' if `touse', meanonly
    local sv2 = r(mean)
    local sigma_ve = `sigma_ve' + `bartlett_w' * (`sv1' + `sv2')
  }
  
  * rho^2 = sigma_ve^2 / (sigma_eps * sigma_v)
  if `sigma_eps' > 0 & `sigma_v' > 0 {
    local rho2 = (`sigma_ve'^2) / (`sigma_eps' * `sigma_v')
  }
  else {
    local rho2 = 1
  }
  
  if `rho2' > 1 local rho2 = 1
  if `rho2' < 0.1 local rho2 = 0.1
  
  * ---- 6. Get critical values ----
  _fcoint_cv_feg2, n(`nxvars') k(`best_k') tobs(`T') model(`model') rho2(`rho2')
  local cv1  = r(cv1)
  local cv5  = r(cv5)
  local cv10 = r(cv10)
  
  * ---- Significance ----
  local stars ""
  local decision "Fail to reject H0 -- no evidence of cointegration"
  if `feg2_tstat' < `cv1' {
    local stars "***"
    local decision "Reject H0 at 1% -- strong evidence of cointegration"
  }
  else if `feg2_tstat' < `cv5' {
    local stars "**"
    local decision "Reject H0 at 5% -- evidence of cointegration"
  }
  else if `feg2_tstat' < `cv10' {
    local stars "*"
    local decision "Reject H0 at 10% -- weak evidence of cointegration"
  }
  
  * ---- Display ----
  local freq_label = "Single"
  if "`cumfreq'" != "" local freq_label = "Cumulative (1-`best_k')"
  local model_label = "Constant"
  if "`model'" == "trend" local model_label = "Constant + Trend"
  
  di
  di in smcl in gr "{hline 70}"
  di in gr "{bf:Modified Fourier Engle-Granger Test (FEG2)}" _col(58) "fcoint v1.1"
  di in smcl in gr "{hline 70}"
  di in gr "  Dep. variable: " in ye "`depvar'" ///
    in gr _col(40) "Observations:  " in ye "`T'"
  di in gr "  Regressors:    " in ye "`indepvars'" ///
    in gr _col(40) "Model:         " in ye "`model_label'"
  di in gr "  Frequency:     " in ye "k* = `best_k' (`freq_label')" ///
    in gr _col(40) "ADF lags:      " in ye "`opt_lag'"
  di in gr "  Est. rho-sq:   " in ye %6.4f `rho2'
  di in smcl in gr "{hline 70}"
  di in gr "  H0: No cointegration" _col(40) "H1: Cointegration"
  di in smcl in gr "{hline 70}"
  di in gr _col(20) "{bf:Coefficient}" _col(38) "{bf:Std. Error}" ///
    _col(54) "{bf:t-statistic}"
  di in smcl in gr "{hline 70}"
  di in gr "  delta(u_{t-1})" ///
    in ye _col(18) %12.6f `feg2_delta' ///
    _col(36) %12.6f `feg2_se' ///
    _col(54) "{bf:" %9.4f `feg2_tstat' "}`stars'"
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Critical values}" _col(28) "1%: " in ye %7.4f `cv1' ///
    in gr _col(44) "5%: " in ye %7.4f `cv5' ///
    in gr _col(58) "10%: " in ye %7.4f `cv10'
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Decision:} " in ye "`decision'"
  di in smcl in gr "{hline 70}"
  di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
  di in gr "  Note: CVs depend on rho-sq (CFR nuisance parameter)"
  di in smcl in gr "{hline 70}"
  
  * ---- Store results ----
  return scalar tstat     = `feg2_tstat'
  return scalar delta     = `feg2_delta'
  return scalar se_delta  = `feg2_se'
  return scalar rho2      = `rho2'
  return scalar frequency = `best_k'
  return scalar nobs      = `feg2_nobs'
  return scalar lag       = `opt_lag'
  return scalar cv1       = `cv1'
  return scalar cv5       = `cv5'
  return scalar cv10      = `cv10'
  return local  test      "feg2"
  return local  model     "`model_label'"
end
