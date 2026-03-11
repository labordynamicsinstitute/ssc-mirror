*! _fcoint_feg.ado -- Fourier Engle-Granger (FEG) Cointegration Test
*! Implements: Banerjee & Lee (working paper)
*! "Residual-based Cointegration Tests for Smooth Structural Breaks"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

program define _fcoint_feg, rclass
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
  
  * ---- Frequency selection: minimize SSR of long-run equation ----
  local best_ssr = 1e30
  local best_k = 1
  
  local freq_end = min(`maxfreq', 5)
  
  forvalues kk = 1/`freq_end' {
    
    local fvars ""
    if "`cumfreq'" == "" {
      tempvar sin_`kk' cos_`kk'
      qui gen double `sin_`kk'' = sin(2 * _pi * `kk' * `tvar' / `T') if `touse'
      qui gen double `cos_`kk'' = cos(2 * _pi * `kk' * `tvar' / `T') if `touse'
      local fvars "`sin_`kk'' `cos_`kk''"
    }
    else {
      forvalues ff = 1/`kk' {
        tempvar sc`ff' cc`ff'
        qui gen double `sc`ff'' = sin(2 * _pi * `ff' * `tvar' / `T') if `touse'
        qui gen double `cc`ff'' = cos(2 * _pi * `ff' * `tvar' / `T') if `touse'
        local fvars "`fvars' `sc`ff'' `cc`ff''"
      }
    }
    
    * Long-run equation: x1t = d(t) + x2t'beta + mu_t
    * d(t) = constant [+ trend] + sin + cos
    local det_rhs "`fvars'"
    if "`model'" == "trend" {
      tempvar trd_`kk'
      qui gen double `trd_`kk'' = `tvar' if `touse'
      local det_rhs "`det_rhs' `trd_`kk''"
    }
    
    capture qui reg `depvar' `indepvars' `det_rhs' if `touse'
    if _rc continue
    
    if e(rss) < `best_ssr' {
      local best_ssr = e(rss)
      local best_k = `kk'
    }
  }
  
  * ---- Re-estimate with best frequency ----
  local fvars_best ""
  if "`cumfreq'" == "" {
    tempvar sinbest cosbest
    qui gen double `sinbest' = sin(2 * _pi * `best_k' * `tvar' / `T') if `touse'
    qui gen double `cosbest' = cos(2 * _pi * `best_k' * `tvar' / `T') if `touse'
    local fvars_best "`sinbest' `cosbest'"
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
    tempvar trd_best
    qui gen double `trd_best' = `tvar' if `touse'
    local det_rhs "`det_rhs' `trd_best'"
  }
  
  qui reg `depvar' `indepvars' `det_rhs' if `touse'
  
  * Get residuals
  tempvar resid
  qui predict double `resid' if `touse', resid
  
  * ---- ADF test on residuals ----
  * Eq (3): d(mu_hat) = delta * mu_hat(-1) + sum(alpha_i * d(mu_hat(-i))) + v_t
  * Use general-to-specific for lag selection
  
  tempvar dresid resid_lag1
  qui gen double `dresid' = D.`resid' if `touse'
  qui gen double `resid_lag1' = L.`resid' if `touse'
  
  * Generate lagged differences
  forvalues j = 1/`maxlag' {
    tempvar dresid_lag`j'
    qui gen double `dresid_lag`j'' = L`j'.`dresid' if `touse'
  }
  
  * General-to-specific: start with maxlag, drop if last lag insignificant
  local opt_lag = `maxlag'
  
  forvalues p = `maxlag'(-1)1 {
    local rhs "`resid_lag1'"
    forvalues j = 1/`p' {
      local rhs "`rhs' `dresid_lag`j''"
    }
    
    capture qui reg `dresid' `rhs' if `touse', noconstant
    if _rc {
      local opt_lag = `p' - 1
      continue
    }
    
    * Check significance of last lag
    local last_t = abs(_b[`dresid_lag`p''] / _se[`dresid_lag`p''])
    if `last_t' >= 1.645 {
      local opt_lag = `p'
      continue, break
    }
    local opt_lag = `p' - 1
  }
  
  if `opt_lag' < 0 local opt_lag = 0
  
  * Final estimation with optimal lags
  local rhs "`resid_lag1'"
  forvalues j = 1/`opt_lag' {
    local rhs "`rhs' `dresid_lag`j''"
  }
  
  if `opt_lag' == 0 {
    qui reg `dresid' `resid_lag1' if `touse', noconstant
  }
  else {
    qui reg `dresid' `rhs' if `touse', noconstant
  }
  
  local feg_tstat = _b[`resid_lag1'] / _se[`resid_lag1']
  local feg_delta = _b[`resid_lag1']
  local feg_se = _se[`resid_lag1']
  local feg_nobs = e(N)
  
  * ---- Critical values: use FADL table as approximation for FEG ----
  * (The FEG asymptotic CVs are similar to the FADL ones by paper)
  if "`cumfreq'" != "" {
    _fcoint_cv_fadl, n(`nxvars') k(`best_k') tobs(`T') model(`model') cumfreq
  }
  else {
    _fcoint_cv_fadl, n(`nxvars') k(`best_k') tobs(`T') model(`model')
  }
  local cv1  = r(cv1)
  local cv5  = r(cv5)
  local cv10 = r(cv10)
  
  * ---- Significance ----
  local stars ""
  local decision "Fail to reject H0 -- no evidence of cointegration"
  if `feg_tstat' < `cv1' {
    local stars "***"
    local decision "Reject H0 at 1% -- strong evidence of cointegration"
  }
  else if `feg_tstat' < `cv5' {
    local stars "**"
    local decision "Reject H0 at 5% -- evidence of cointegration"
  }
  else if `feg_tstat' < `cv10' {
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
  di in gr "{bf:Fourier Engle-Granger Test (FEG)}" _col(58) "fcoint v1.1"
  di in smcl in gr "{hline 70}"
  di in gr "  Dep. variable: " in ye "`depvar'" ///
    in gr _col(40) "Observations:  " in ye "`T'"
  di in gr "  Regressors:    " in ye "`indepvars'" ///
    in gr _col(40) "Model:         " in ye "`model_label'"
  di in gr "  Frequency:     " in ye "k* = `best_k' (`freq_label')" ///
    in gr _col(40) "ADF lags:      " in ye "`opt_lag'"
  di in smcl in gr "{hline 70}"
  di in gr "  H0: No cointegration" _col(40) "H1: Cointegration"
  di in smcl in gr "{hline 70}"
  di in gr _col(20) "{bf:Coefficient}" _col(54) "{bf:t-statistic}"
  di in smcl in gr "{hline 70}"
  di in gr "  delta(u_{t-1})" ///
    in ye _col(18) %12.6f `feg_delta' ///
    _col(54) "{bf:" %9.4f `feg_tstat' "}`stars'"
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Critical values}" _col(28) "1%: " in ye %7.4f `cv1' ///
    in gr _col(44) "5%: " in ye %7.4f `cv5' ///
    in gr _col(58) "10%: " in ye %7.4f `cv10'
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Decision:} " in ye "`decision'"
  di in smcl in gr "{hline 70}"
  di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
  di in smcl in gr "{hline 70}"
  
  * ---- Graph ----
  if "`graph'" != "" {
    preserve
    
    * Fourier + regressors fit
    local det_g "`fvars_best'"
    if "`model'" == "trend" {
      tempvar trd_g
      qui gen double `trd_g' = `tvar' if `touse'
      local det_g "`det_g' `trd_g'"
    }
    
    qui reg `depvar' `indepvars' `det_g' if `touse'
    tempvar yhat_full_g
    qui predict double `yhat_full_g' if `touse', xb
    
    qui summ `depvar' if `touse', meanonly
    local ymean = r(mean)
    
    * Pre-format values for graph notes
    local tstat_fmt : di %7.3f `feg_tstat'
    local cv5_fmt : di %7.3f `cv5'
    
    * Panel 1: Fit
    twoway (line `depvar' `tvar' if `touse', ///
        lcolor(gs11) lwidth(thin)) ///
      (line `yhat_full_g' `tvar' if `touse', ///
        lcolor(dkgreen) lwidth(medthick)), ///
      title("{bf:FEG: Long-Run Equation Fit}", size(medsmall)) ///
      subtitle("y = d(t) + x'beta, k* = `best_k' (`freq_label')" ///
        , size(vsmall)) ///
      legend(order(1 "Actual `depvar'" 2 "Fitted (Fourier + X)") ///
        size(vsmall) rows(1) position(6)) ///
      ytitle("`depvar'", size(small)) ///
      xtitle("Time", size(small)) ///
      yline(`ymean', lcolor(navy) lwidth(vthin) lpattern(shortdash)) ///
      note("t_EG^F = `tstat_fmt', CV(5%) = `cv5_fmt'. `decision'", ///
        size(vsmall)) ///
      scheme(s2color) name(fcoint_feg_fit, replace)
    
    * Panel 2: Residuals
    twoway (line `resid' `tvar' if `touse', ///
        lcolor(dknavy) lwidth(thin)) ///
      (lowess `resid' `tvar' if `touse', ///
        lcolor(cranberry) lwidth(medthick) bwidth(0.3)), ///
      title("{bf:FEG: Long-Run Residuals}", size(medsmall)) ///
      subtitle("Stationary residuals => cointegration", ///
        size(vsmall)) ///
      legend(order(1 "Residuals mu_hat" 2 "Lowess") ///
        size(vsmall) rows(1) position(6)) ///
      ytitle("Residual", size(small)) ///
      xtitle("Time", size(small)) ///
      yline(0, lcolor(gs8) lwidth(vthin) lpattern(dash)) ///
      scheme(s2color) name(fcoint_feg_resid, replace)
    
    * Combine
    graph combine fcoint_feg_fit fcoint_feg_resid, ///
      cols(1) ///
      title("{bf:Fourier Engle-Granger Diagnostics}", ///
        size(medsmall)) ///
      subtitle("`depvar' -- k* = `best_k', `model_label'", size(vsmall)) ///
      scheme(s2color) name(fcoint_feg, replace) ///
      xsize(7) ysize(9)
    
    capture graph drop fcoint_feg_fit
    capture graph drop fcoint_feg_resid
    
    restore
  }
  
  * ---- Store results ----
  return scalar tstat     = `feg_tstat'
  return scalar delta     = `feg_delta'
  return scalar se_delta  = `feg_se'
  return scalar frequency = `best_k'
  return scalar nobs      = `feg_nobs'
  return scalar lag       = `opt_lag'
  return scalar cv1       = `cv1'
  return scalar cv5       = `cv5'
  return scalar cv10      = `cv10'
  return local  test      "feg"
  return local  model     "`model_label'"
end
