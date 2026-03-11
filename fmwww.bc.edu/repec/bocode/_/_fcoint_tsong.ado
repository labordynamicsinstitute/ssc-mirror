*! _fcoint_tsong.ado -- Fourier Cointegration Test (Null of Cointegration)
*! Implements: Tsong, Lee, Tsai & Hu (2016, Empirical Economics)
*! "The Fourier approximation and testing for the null of cointegration"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

program define _fcoint_tsong, rclass
  version 14.0
  
  syntax, depvar(string) indepvars(string) touse(string) ///
    model(string) maxfreq(integer) [dolslags(integer 0) graph]
  
  * ---- Setup ----
  qui tsset
  local tvar = r(timevar)
  
  qui count if `touse'
  local T = r(N)
  
  local nxvars : word count `indepvars'
  
  * DOLS leads/lags
  if `dolslags' <= 0 {
    * Use AIC to select optimal leads/lags (try 1 to 4)
    local dolslags_max = min(4, int(`T'/10))
    local best_aic_dols = 1e30
    local dolslags = 1
    
    forvalues ll = 1/`dolslags_max' {
      * Build DOLS regressors for testing
      local dols_rhs ""
      local dols_ok = 1
      forvalues i = 1/`nxvars' {
        local xv : word `i' of `indepvars'
        forvalues j = -`ll'/`ll' {
          if `j' < 0 {
            local absj = -`j'
            tempvar dxl_`i'_`absj'_neg
            capture qui gen double `dxl_`i'_`absj'_neg' = F`absj'.D.`xv' if `touse'
            if _rc {
              local dols_ok = 0
              continue, break
            }
            local dols_rhs "`dols_rhs' `dxl_`i'_`absj'_neg'"
          }
          else if `j' == 0 {
            tempvar dx0_`i'
            qui gen double `dx0_`i'' = D.`xv' if `touse'
            local dols_rhs "`dols_rhs' `dx0_`i''"
          }
          else {
            tempvar dxl_`i'_`j'_pos
            capture qui gen double `dxl_`i'_`j'_pos' = L`j'.D.`xv' if `touse'
            if _rc {
              local dols_ok = 0
              continue, break
            }
            local dols_rhs "`dols_rhs' `dxl_`i'_`j'_pos'"
          }
        }
        if !`dols_ok' continue, break
      }
      
      if !`dols_ok' continue
      
      * Quick regression to get AIC
      tempvar s1 c1
      qui gen double `s1' = sin(2 * _pi * 1 * `tvar' / `T') if `touse'
      qui gen double `c1' = cos(2 * _pi * 1 * `tvar' / `T') if `touse'
      local det "`s1' `c1'"
      if "`model'" == "trend" {
        tempvar trd_aic
        qui gen double `trd_aic' = `tvar' if `touse'
        local det "`det' `trd_aic'"
      }
      
      capture qui reg `depvar' `indepvars' `det' `dols_rhs' if `touse'
      if _rc continue
      
      local nobs_t = e(N)
      local nreg_t = e(df_m) + 1
      local sigsq_t = e(rss) / `nobs_t'
      local aic_t = ln(`sigsq_t') + 2 * `nreg_t' / `nobs_t'
      
      if `aic_t' < `best_aic_dols' {
        local best_aic_dols = `aic_t'
        local dolslags = `ll'
      }
    }
  }
  
  * ---- Frequency selection: minimize SSR ----
  local best_ssr = 1e30
  local best_k = 1
  local freq_max = min(`maxfreq', 3)
  
  forvalues kk = 1/`freq_max' {
    
    tempvar sin_t`kk' cos_t`kk'
    qui gen double `sin_t`kk'' = sin(2 * _pi * `kk' * `tvar' / `T') if `touse'
    qui gen double `cos_t`kk'' = cos(2 * _pi * `kk' * `tvar' / `T') if `touse'
    
    local det "`sin_t`kk'' `cos_t`kk''"
    if "`model'" == "trend" {
      tempvar trd_`kk'
      qui gen double `trd_`kk'' = `tvar' if `touse'
      local det "`det' `trd_`kk''"
    }
    
    * DOLS leads/lags of dx
    local dols_rhs ""
    forvalues i = 1/`nxvars' {
      local xv : word `i' of `indepvars'
      forvalues j = -`dolslags'/`dolslags' {
        if `j' < 0 {
          local absj = -`j'
          tempvar dxf_`kk'_`i'_`absj'
          capture qui gen double `dxf_`kk'_`i'_`absj'' = F`absj'.D.`xv' if `touse'
          if _rc continue
          local dols_rhs "`dols_rhs' `dxf_`kk'_`i'_`absj''"
        }
        else if `j' == 0 {
          tempvar dx0_`kk'_`i'
          qui gen double `dx0_`kk'_`i'' = D.`xv' if `touse'
          local dols_rhs "`dols_rhs' `dx0_`kk'_`i''"
        }
        else {
          tempvar dxl_`kk'_`i'_`j'
          capture qui gen double `dxl_`kk'_`i'_`j'' = L`j'.D.`xv' if `touse'
          if _rc continue
          local dols_rhs "`dols_rhs' `dxl_`kk'_`i'_`j''"
        }
      }
    }
    
    capture qui reg `depvar' `indepvars' `det' `dols_rhs' if `touse'
    if _rc continue
    
    if e(rss) < `best_ssr' {
      local best_ssr = e(rss)
      local best_k = `kk'
    }
  }
  
  * ---- Re-estimate DOLS with optimal k ----
  tempvar sin_best cos_best
  qui gen double `sin_best' = sin(2 * _pi * `best_k' * `tvar' / `T') if `touse'
  qui gen double `cos_best' = cos(2 * _pi * `best_k' * `tvar' / `T') if `touse'
  
  local det_best "`sin_best' `cos_best'"
  if "`model'" == "trend" {
    tempvar trd_b
    qui gen double `trd_b' = `tvar' if `touse'
    local det_best "`det_best' `trd_b'"
  }
  
  local dols_best ""
  forvalues i = 1/`nxvars' {
    local xv : word `i' of `indepvars'
    forvalues j = -`dolslags'/`dolslags' {
      if `j' < 0 {
        local absj = -`j'
        tempvar dxbf_`i'_`absj'
        capture qui gen double `dxbf_`i'_`absj'' = F`absj'.D.`xv' if `touse'
        if !_rc local dols_best "`dols_best' `dxbf_`i'_`absj''"
      }
      else if `j' == 0 {
        tempvar dxb0_`i'
        qui gen double `dxb0_`i'' = D.`xv' if `touse'
        local dols_best "`dols_best' `dxb0_`i''"
      }
      else {
        tempvar dxbl_`i'_`j'
        capture qui gen double `dxbl_`i'_`j'' = L`j'.D.`xv' if `touse'
        if !_rc local dols_best "`dols_best' `dxbl_`i'_`j''"
      }
    }
  }
  
  qui reg `depvar' `indepvars' `det_best' `dols_best' if `touse'
  local nobs_dols = e(N)
  local nreg_dols = e(df_m) + 1
  
  * ---- Get residuals ----
  tempvar eps_star
  qui predict double `eps_star' if `touse', resid
  
  * ---- Compute KPSS-type statistic: CI_f = T^-2 * omega^-2 * sum(S_t^2) ----
  * S_t = partial sum of residuals
  
  * Sort by time
  qui sort `tvar'
  
  * Compute partial sums
  tempvar S_t S_t2
  qui gen double `S_t' = sum(`eps_star') if `touse'
  qui gen double `S_t2' = `S_t'^2 if `touse'
  
  * Sum of S_t^2
  qui summ `S_t2' if `touse', meanonly
  local sum_S2 = r(sum)
  
  * ---- Estimate long-run variance using Bartlett kernel ----
  local bw = int(`nobs_dols'^(1/3))
  
  * Gamma(0)
  tempvar eps2
  qui gen double `eps2' = `eps_star'^2 if `touse'
  qui summ `eps2' if `touse', meanonly
  local omega2 = r(mean)
  
  * Add weighted autocovariances
  forvalues j = 1/`bw' {
    local bartlett_w = 1 - `j'/(`bw' + 1)
    
    tempvar eps_lag`j' eps_cross`j'
    qui gen double `eps_lag`j'' = L`j'.`eps_star' if `touse'
    qui gen double `eps_cross`j'' = `eps_star' * `eps_lag`j'' if `touse'
    
    qui summ `eps_cross`j'' if `touse', meanonly
    local omega2 = `omega2' + 2 * `bartlett_w' * r(mean)
  }
  
  if `omega2' <= 0 local omega2 = 0.00001
  
  * KPSS statistic
  local CI_stat = (1/(`nobs_dols'^2)) * (1/`omega2') * `sum_S2'
  
  * ---- F-test for presence of Fourier component ----
  * F(k) = [(SSR0 - SSR1(k)) / 2] / [SSR1(k) / (T - q)]
  
  * SSR under null (no Fourier)
  local det_null ""
  if "`model'" == "trend" {
    tempvar trd_null
    qui gen double `trd_null' = `tvar' if `touse'
    local det_null "`trd_null'"
  }
  
  local dols_null ""
  forvalues i = 1/`nxvars' {
    local xv : word `i' of `indepvars'
    forvalues j = -`dolslags'/`dolslags' {
      if `j' < 0 {
        local absj = -`j'
        tempvar dxnf_`i'_`absj'
        capture qui gen double `dxnf_`i'_`absj'' = F`absj'.D.`xv' if `touse'
        if !_rc local dols_null "`dols_null' `dxnf_`i'_`absj''"
      }
      else if `j' == 0 {
        tempvar dxn0_`i'
        qui gen double `dxn0_`i'' = D.`xv' if `touse'
        local dols_null "`dols_null' `dxn0_`i''"
      }
      else {
        tempvar dxnl_`i'_`j'
        capture qui gen double `dxnl_`i'_`j'' = L`j'.D.`xv' if `touse'
        if !_rc local dols_null "`dols_null' `dxnl_`i'_`j''"
      }
    }
  }
  
  if "`det_null'" != "" {
    qui reg `depvar' `indepvars' `det_null' `dols_null' if `touse'
  }
  else {
    qui reg `depvar' `indepvars' `dols_null' if `touse'
  }
  local ssr0 = e(rss)
  
  * SSR under alternative (with Fourier) -- already computed
  local ssr1 = `best_ssr'
  
  local F_stat = ((`ssr0' - `ssr1') / 2) / (`ssr1' / (`nobs_dols' - `nreg_dols'))
  
  * ---- Critical values ----
  _fcoint_cv_tsong, p(`nxvars') k(`best_k') model(`model')
  local ci_cv1  = r(cv1)
  local ci_cv5  = r(cv5)
  local ci_cv10 = r(cv10)
  
  _fcoint_cv_tsong_ftest, model(`model')
  local f_cv1  = r(cv1)
  local f_cv5  = r(cv5)
  local f_cv10 = r(cv10)
  
  * ---- Significance ----
  * NOTE: This is an upper-tail test! Reject H0 (cointegration) if stat > cv
  local ci_stars ""
  local ci_decision "Fail to reject H0 -- evidence of cointegration"
  if `CI_stat' > `ci_cv1' {
    local ci_stars "***"
    local ci_decision "Reject H0 at 1% -- no cointegration"
  }
  else if `CI_stat' > `ci_cv5' {
    local ci_stars "**"
    local ci_decision "Reject H0 at 5% -- no cointegration"
  }
  else if `CI_stat' > `ci_cv10' {
    local ci_stars "*"
    local ci_decision "Reject H0 at 10% -- weak evidence against cointegration"
  }
  
  * F-test significance
  local f_stars ""
  local f_decision "Fourier component not significant -- use Shin (1994) test"
  if `F_stat' > `f_cv1' {
    local f_stars "***"
    local f_decision "Fourier component significant at 1%"
  }
  else if `F_stat' > `f_cv5' {
    local f_stars "**"
    local f_decision "Fourier component significant at 5%"
  }
  else if `F_stat' > `f_cv10' {
    local f_stars "*"
    local f_decision "Fourier component significant at 10%"
  }
  
  * ---- Display ----
  local model_label = "Constant"
  if "`model'" == "trend" local model_label = "Constant + Trend"
  
  di
  di in smcl in gr "{hline 70}"
  di in gr "{bf:Fourier Cointegration Test -- Null of Cointegration}" ///
    _col(58) "fcoint v1.1"
  di in smcl in gr "{hline 70}"
  di in gr "  Dep. variable: " in ye "`depvar'" ///
    in gr _col(40) "Observations:  " in ye "`T'"
  di in gr "  Regressors:    " in ye "`indepvars'" ///
    in gr _col(40) "Model:         " in ye "`model_label'"
  di in gr "  Frequency:     " in ye "k* = `best_k'" ///
    in gr _col(40) "DOLS lags:     " in ye "`dolslags'"
  di in gr "  LR bandwidth:  " in ye "`bw'"
  di in smcl in gr "{hline 70}"
  di in gr "  H0: Cointegration exists" _col(40) "H1: No cointegration"
  di in smcl in gr "{hline 70}"
  di in gr _col(20) "{bf:Panel A: KPSS-type Test (CI_f)}"
  di in smcl in gr "{hline 70}"
  di in gr "  CI_f statistic" ///
    in ye _col(54) "{bf:" %9.6f `CI_stat' "}`ci_stars'"
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Critical values}" _col(24) "10%: " in ye %8.6f `ci_cv10' ///
    in gr _col(40) "5%: " in ye %8.6f `ci_cv5' ///
    in gr _col(56) "1%: " in ye %8.6f `ci_cv1'
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Decision:} " in ye "`ci_decision'"
  di in smcl in gr "{hline 70}"
  di in gr _col(20) "{bf:Panel B: F-test for Fourier Component}"
  di in smcl in gr "{hline 70}"
  di in gr "  F(k*) statistic" ///
    in ye _col(54) "{bf:" %9.4f `F_stat' "}`f_stars'"
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Critical values}" _col(24) "10%: " in ye %8.4f `f_cv10' ///
    in gr _col(40) "5%: " in ye %8.4f `f_cv5' ///
    in gr _col(56) "1%: " in ye %8.4f `f_cv1'
  di in smcl in gr "{hline 70}"
  di in gr "  `f_decision'"
  di in smcl in gr "{hline 70}"
  di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
  di in gr "  Note: Upper-tail test. Large CI_f => reject cointegration"
  di in smcl in gr "{hline 70}"
  
  * ---- Graph (optional) ----
  if "`graph'" != "" {
    preserve
    
    * Panel 1: DOLS fit vs actual
    tempvar yhat_dols
    qui reg `depvar' `indepvars' `det_best' `dols_best' if `touse'
    qui predict double `yhat_dols' if `touse', xb
    
    * Pre-format values for graph notes
    local ci_fmt : di %9.6f `CI_stat'
    local cv5_fmt : di %9.6f `ci_cv5'
    
    twoway (line `depvar' `tvar' if `touse', ///
        lcolor(gs11) lwidth(thin)) ///
      (line `yhat_dols' `tvar' if `touse', ///
        lcolor(dkgreen) lwidth(medthick)), ///
      title("{bf:Tsong: DOLS Fit vs Actual}", size(medsmall)) ///
      subtitle("y = d(t) + x'beta + DOLS leads/lags, " ///
        "k* = `best_k', l = `dolslags'", size(vsmall)) ///
      legend(order(1 "Actual `depvar'" 2 "DOLS fitted") ///
        size(vsmall) rows(1) position(6)) ///
      ytitle("`depvar'", size(small)) ///
      xtitle("Time", size(small)) ///
      note("CI_f = `ci_fmt', CV(5%) = `cv5_fmt'. `ci_decision'", ///
        size(vsmall)) ///
      scheme(s2color) name(fcoint_tsong_fit, replace)
    
    * Panel 2: CUSUM of DOLS residuals (partial sums S_t)
    * Recompute S_t from DOLS residuals, normalized by sqrt(omega2)
    tempvar eps_graph S_t_graph
    qui predict double `eps_graph' if `touse', resid
    qui gen double `S_t_graph' = sum(`eps_graph' / sqrt(`omega2')) if `touse'
    
    * Critical bounds: +/- 0.948 * sqrt(T) at 5% (Brownian bridge)
    local cusum_bound = 0.948 * sqrt(`nobs_dols')
    
    twoway (line `S_t_graph' `tvar' if `touse', ///
        lcolor(dknavy) lwidth(medthick)) ///
      (function y = `cusum_bound', range(`tvar') ///
        lcolor(cranberry) lwidth(medium) lpattern(dash)) ///
      (function y = -`cusum_bound', range(`tvar') ///
        lcolor(cranberry) lwidth(medium) lpattern(dash)), ///
      title("{bf:Tsong: CUSUM of DOLS Residuals (S*_t)}", ///
        size(medsmall)) ///
      subtitle("Paths staying within bounds support " ///
        "cointegration", size(vsmall)) ///
      legend(order(1 "CUSUM S*_t" 2 "5% bounds") ///
        size(vsmall) rows(1) position(6)) ///
      ytitle("Normalized partial sum S*_t", size(small)) ///
      xtitle("Time", size(small)) ///
      yline(0, lcolor(gs8) lwidth(vthin) lpattern(dot)) ///
      scheme(s2color) name(fcoint_tsong_cusum, replace)
    
    * Combine
    * Pre-format F-stat for graph note
    local fstat_fmt : di %6.3f `F_stat'
    
    graph combine fcoint_tsong_fit fcoint_tsong_cusum, ///
      cols(1) ///
      title("{bf:Fourier Null-of-Cointegration Diagnostics}", ///
        size(medsmall)) ///
      subtitle("`depvar' -- k* = `best_k', `model_label'", ///
        size(vsmall)) ///
      note("F-test = `fstat_fmt' (`f_decision')", size(vsmall)) ///
      scheme(s2color) name(fcoint_tsong, replace) ///
      xsize(7) ysize(9)
    
    capture graph drop fcoint_tsong_fit
    capture graph drop fcoint_tsong_cusum
    
    restore
  }
  
  * ---- Store results ----
  return scalar CI_stat    = `CI_stat'
  return scalar F_stat     = `F_stat'
  return scalar omega2     = `omega2'
  return scalar frequency  = `best_k'
  return scalar nobs       = `nobs_dols'
  return scalar dolslags   = `dolslags'
  return scalar ci_cv1     = `ci_cv1'
  return scalar ci_cv5     = `ci_cv5'
  return scalar ci_cv10    = `ci_cv10'
  return scalar f_cv1      = `f_cv1'
  return scalar f_cv5      = `f_cv5'
  return scalar f_cv10     = `f_cv10'
  return local  test       "tsong"
  return local  model      "`model_label'"
end
