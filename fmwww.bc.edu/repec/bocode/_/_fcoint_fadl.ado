*! _fcoint_fadl.ado -- Fourier ADL Cointegration Test
*! Implements: Banerjee, Arcabic & Lee (2017, Economic Modelling)
*! "Fourier ADL cointegration test to approximate smooth breaks"
*! Translated from WinRATS code: FADL_Empirical with Kilian Data.RPF
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.1.0 -- Audited against WinRATS

program define _fcoint_fadl, rclass
  version 14.0
  
  syntax, depvar(string) indepvars(string) touse(string) ///
    model(string) maxfreq(integer) maxlag(integer) ///
    criterion(string) [cumfreq graph]
  
  * ---- Setup ----
  qui tsset
  local tvar = r(timevar)
  
  * Total observations (= cap_t in WinRATS, used for Fourier normalization)
  qui count if `touse'
  local T = r(N)
  
  * Count regressors (= m in WinRATS)
  local nxvars : word count `indepvars'
  
  * Maximum lag search (= nlags in WinRATS, default 6)
  if `maxlag' <= 0 {
    local maxlag = 6
  }
  local nlags = min(`maxlag', 6)
  
  * ---- Pre-generate all variables ----
  * WinRATS: dy, y{1}, x_i{1}, dx_i, dx_i{1..nlags}, dy{1..nlags}
  
  tempvar dy y_lag1
  qui gen double `dy' = D.`depvar' if `touse'
  qui gen double `y_lag1' = L.`depvar' if `touse'
  
  * For each indepvar: lagged level, contemporaneous diff, lagged diffs
  forvalues i = 1/`nxvars' {
    local xv : word `i' of `indepvars'
    tempvar x`i'_lag1 dx`i'_0
    qui gen double `x`i'_lag1' = L.`xv' if `touse'
    qui gen double `dx`i'_0' = D.`xv' if `touse'
    
    forvalues j = 1/`nlags' {
      tempvar dx`i'_`j'
      qui gen double `dx`i'_`j'' = L`j'.D.`xv' if `touse'
    }
  }
  
  * Lagged differences of dy
  forvalues j = 1/`nlags' {
    tempvar dy_`j'
    qui gen double `dy_`j'' = L`j'.`dy' if `touse'
  }
  
  * ---- Fix estimation sample ----
  * WinRATS: first estimates with max lags to fix start/end
  * (line 89-91: linreg with max lags, compute start=%regstart(),end=%regend())
  
  tempvar esample
  qui gen byte `esample' = `touse'
  
  * Mark out all potential variables to fix sample
  local all_mark "`dy' `y_lag1'"
  forvalues i = 1/`nxvars' {
    local all_mark "`all_mark' `x`i'_lag1' `dx`i'_0'"
    forvalues j = 1/`nlags' {
      local all_mark "`all_mark' `dx`i'_`j''"
    }
  }
  forvalues j = 1/`nlags' {
    local all_mark "`all_mark' `dy_`j''"
  }
  qui markout `esample' `all_mark'
  
  * ---- Trend variable (if model = trend) ----
  * WinRATS: "trend" is included in ADL eq (line 81: ...sinx cosx trend)
  local trend_var ""
  if "`model'" == "trend" {
    tempvar trd
    qui gen double `trd' = `tvar' if `esample'
    local trend_var "`trd'"
  }
  
  * ================================================================
  * MAIN FREQUENCY LOOP
  * WinRATS (line 68): do freq=1,3
  * ================================================================
  
  local best_ssr_global = 1e30
  local best_k = 1
  local best_tstat = .
  local best_delta = .
  local best_se = .
  local best_nlag_dy = 1
  local best_nobs = .
  local best_aic_val = .
  local best_bic_val = .
  
  * Store per-x variable best lags
  forvalues i = 1/`nxvars' {
    local best_nlag_dx`i' = 1
  }
  
  local freq_end = min(`maxfreq', 5)
  
  forvalues kk = 1/`freq_end' {
    
    * ---- Generate Fourier terms ----
    * WinRATS (line 72-73): sinx = sin(2*pi*freq*t/cap_t)
    
    local fourier_vars ""
    
    if "`cumfreq'" == "" {
      * Single frequency
      tempvar sinx_`kk' cosx_`kk'
      qui gen double `sinx_`kk'' = sin(2 * _pi * `kk' * `tvar' / `T') if `touse'
      qui gen double `cosx_`kk'' = cos(2 * _pi * `kk' * `tvar' / `T') if `touse'
      local fourier_vars "`sinx_`kk'' `cosx_`kk''"
    }
    else {
      * Cumulative frequencies 1..kk
      forvalues ff = 1/`kk' {
        tempvar sin_c`ff' cos_c`ff'
        qui gen double `sin_c`ff'' = sin(2 * _pi * `ff' * `tvar' / `T') if `touse'
        qui gen double `cos_c`ff'' = cos(2 * _pi * `ff' * `tvar' / `T') if `touse'
        local fourier_vars "`fourier_vars' `sin_c`ff'' `cos_c`ff''"
      }
    }
    
    * ================================================================
    * NESTED GRID SEARCH OVER LAG LENGTHS
    * WinRATS (lines 93-107): 3-nested loop
    *   do dylags = 1,nlags
    *     do dx1lags = 1,nlags
    *       do dx2lags = 1,nlags
    *
    * For general m regressors, we do:
    *   - if nxvars == 1: 2-nested (dylags, dx1lags)
    *   - if nxvars == 2: 3-nested (dylags, dx1lags, dx2lags) -- matches WinRATS
    *   - if nxvars >= 3: use common dx lag to keep tractable
    * ================================================================
    
    local k_best_ic  = 1e30
    local k_best_ssr = 1e30
    local k_best_tstat = .
    local k_best_delta = .
    local k_best_se = .
    local k_best_dy = 1
    forvalues i = 1/`nxvars' {
      local k_best_dx`i' = 1
    }
    
    if `nxvars' == 1 {
      * ---- 2-nested loop (matches WinRATS with m=1) ----
      forvalues dylags = 1/`nlags' {
        forvalues dx1lags = 1/`nlags' {
          
          * WinRATS eq (line 97):
          * constant sinx cosx y{1} x1{1} dx1 dx1{1 to dx1lags} dy{1 to dylags}
          local rhs "`fourier_vars' `y_lag1' `x1_lag1' `dx1_0'"
          forvalues j = 1/`dx1lags' {
            local rhs "`rhs' `dx1_`j''"
          }
          forvalues j = 1/`dylags' {
            local rhs "`rhs' `dy_`j''"
          }
          if "`trend_var'" != "" local rhs "`rhs' `trend_var'"
          
          capture qui reg `dy' `rhs' if `esample'
          if _rc continue
          
          * WinRATS (line 98-100): AIC/BIC
          local nobs_r = e(N)
          local nreg_r = e(df_m) + 1
          local ssr_r  = e(rss)
          local sigsq  = `ssr_r' / `nobs_r'
          
          if "`criterion'" == "bic" {
            local ic = ln(`sigsq') + ln(`nobs_r') * `nreg_r' / `nobs_r'
          }
          else {
            local ic = ln(`sigsq') + 2.0 * `nreg_r' / `nobs_r'
          }
          
          if `ic' < `k_best_ic' {
            local k_best_ic  = `ic'
            local k_best_ssr = `ssr_r'
            local k_best_dy  = `dylags'
            local k_best_dx1 = `dx1lags'
            
            * WinRATS (line 85): tstat = %tstats(2) -- t-stat on y{1}
            local k_best_delta = _b[`y_lag1']
            local k_best_se    = _se[`y_lag1']
            if `k_best_se' > 0 {
              local k_best_tstat = `k_best_delta' / `k_best_se'
            }
            local k_best_nobs = `nobs_r'
          }
        }
      }
    }
    else if `nxvars' == 2 {
      * ---- 3-nested loop (exact WinRATS match for m=2) ----
      * WinRATS (lines 93-107):
      *   do dylags = 1,nlags
      *     do dx1lags = 1,nlags
      *       do dx2lags = 1,nlags
      
      forvalues dylags = 1/`nlags' {
        forvalues dx1lags = 1/`nlags' {
          forvalues dx2lags = 1/`nlags' {
            
            * WinRATS eq (line 97):
            * constant sinx cosx y{1} x1{1} x2{1} dx1 dx1{1..dx1lags} dx2 dx2{1..dx2lags} dy{1..dylags}
            local rhs "`fourier_vars' `y_lag1' `x1_lag1' `x2_lag1'"
            
            * dx1 contemporaneous + lags
            local rhs "`rhs' `dx1_0'"
            forvalues j = 1/`dx1lags' {
              local rhs "`rhs' `dx1_`j''"
            }
            
            * dx2 contemporaneous + lags
            local rhs "`rhs' `dx2_0'"
            forvalues j = 1/`dx2lags' {
              local rhs "`rhs' `dx2_`j''"
            }
            
            * dy lags
            forvalues j = 1/`dylags' {
              local rhs "`rhs' `dy_`j''"
            }
            
            if "`trend_var'" != "" local rhs "`rhs' `trend_var'"
            
            capture qui reg `dy' `rhs' if `esample'
            if _rc continue
            
            local nobs_r = e(N)
            local nreg_r = e(df_m) + 1
            local ssr_r  = e(rss)
            local sigsq  = `ssr_r' / `nobs_r'
            
            if "`criterion'" == "bic" {
              local ic = ln(`sigsq') + ln(`nobs_r') * `nreg_r' / `nobs_r'
            }
            else {
              local ic = ln(`sigsq') + 2.0 * `nreg_r' / `nobs_r'
            }
            
            if `ic' < `k_best_ic' {
              local k_best_ic  = `ic'
              local k_best_ssr = `ssr_r'
              local k_best_dy  = `dylags'
              local k_best_dx1 = `dx1lags'
              local k_best_dx2 = `dx2lags'
              local k_best_delta = _b[`y_lag1']
              local k_best_se    = _se[`y_lag1']
              if `k_best_se' > 0 {
                local k_best_tstat = `k_best_delta' / `k_best_se'
              }
              local k_best_nobs = `nobs_r'
            }
          }
        }
      }
    }
    else {
      * ---- General case (nxvars >= 3): common dx lag ----
      forvalues dylags = 1/`nlags' {
        forvalues dxlags = 1/`nlags' {
          
          local rhs "`fourier_vars' `y_lag1'"
          
          * x lagged levels
          forvalues i = 1/`nxvars' {
            local rhs "`rhs' `x`i'_lag1'"
          }
          
          * dx contemporaneous + lags (common lag for all x)
          forvalues i = 1/`nxvars' {
            local rhs "`rhs' `dx`i'_0'"
            forvalues j = 1/`dxlags' {
              local rhs "`rhs' `dx`i'_`j''"
            }
          }
          
          * dy lags
          forvalues j = 1/`dylags' {
            local rhs "`rhs' `dy_`j''"
          }
          
          if "`trend_var'" != "" local rhs "`rhs' `trend_var'"
          
          capture qui reg `dy' `rhs' if `esample'
          if _rc continue
          
          local nobs_r = e(N)
          local nreg_r = e(df_m) + 1
          local ssr_r  = e(rss)
          local sigsq  = `ssr_r' / `nobs_r'
          
          if "`criterion'" == "bic" {
            local ic = ln(`sigsq') + ln(`nobs_r') * `nreg_r' / `nobs_r'
          }
          else {
            local ic = ln(`sigsq') + 2.0 * `nreg_r' / `nobs_r'
          }
          
          if `ic' < `k_best_ic' {
            local k_best_ic  = `ic'
            local k_best_ssr = `ssr_r'
            local k_best_dy  = `dylags'
            forvalues i = 1/`nxvars' {
              local k_best_dx`i' = `dxlags'
            }
            local k_best_delta = _b[`y_lag1']
            local k_best_se    = _se[`y_lag1']
            if `k_best_se' > 0 {
              local k_best_tstat = `k_best_delta' / `k_best_se'
            }
            local k_best_nobs = `nobs_r'
          }
        }
      }
    }
    
    * ---- Select best frequency by SSR ----
    * WinRATS: frequency selected by AIC/BIC from the same criterion
    if `k_best_ssr' < `best_ssr_global' {
      local best_ssr_global = `k_best_ssr'
      local best_k      = `kk'
      local best_tstat   = `k_best_tstat'
      local best_delta   = `k_best_delta'
      local best_se      = `k_best_se'
      local best_nlag_dy = `k_best_dy'
      local best_nobs    = `k_best_nobs'
      local best_aic_val = `k_best_ic'
      forvalues i = 1/`nxvars' {
        local best_nlag_dx`i' = `k_best_dx`i''
      }
    }
  }
  
  * ---- Get critical values ----
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
  if `best_tstat' < `cv1' {
    local stars "***"
    local decision "Reject H0 at 1% -- strong evidence of cointegration"
  }
  else if `best_tstat' < `cv5' {
    local stars "**"
    local decision "Reject H0 at 5% -- evidence of cointegration"
  }
  else if `best_tstat' < `cv10' {
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
  di in gr "{bf:Fourier ADL Cointegration Test (FADL)}" _col(58) "fcoint v1.1"
  di in smcl in gr "{hline 70}"
  di in gr "  Dep. variable: " in ye "`depvar'" ///
    in gr _col(40) "Observations:  " in ye "`T'"
  di in gr "  Regressors:    " in ye "`indepvars'" ///
    in gr _col(40) "Model:         " in ye "`model_label'"
  di in gr "  Frequency:     " in ye "k* = `best_k' (`freq_label')" ///
    in gr _col(40) "Lag selection: " in ye upper("`criterion'")
  di in gr "  Lags (Dy):     " in ye "`best_nlag_dy'" ///
    in gr _col(40) "Lags (Dx):     " in ye "`best_nlag_dx1'"
  di in smcl in gr "{hline 70}"
  di in gr "  H0: No cointegration" _col(40) "H1: Cointegration"
  di in smcl in gr "{hline 70}"
  di in gr _col(20) "{bf:Coefficient}" _col(38) "{bf:Std. Error}" ///
    _col(54) "{bf:t-statistic}"
  di in smcl in gr "{hline 70}"
  di in gr "  delta(y_{t-1})" ///
    in ye _col(18) %12.6f `best_delta' ///
    _col(36) %12.6f `best_se' ///
    _col(54) "{bf:" %9.4f `best_tstat' "}`stars'"
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Critical values}" _col(28) "1%: " in ye %7.4f `cv1' ///
    in gr _col(44) "5%: " in ye %7.4f `cv5' ///
    in gr _col(58) "10%: " in ye %7.4f `cv10'
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Decision:} " in ye "`decision'"
  di in smcl in gr "{hline 70}"
  di in gr "  *** p<0.01, ** p<0.05, * p<0.10"
  di in smcl in gr "{hline 70}"
  
  * ---- EG test within FADL ----
  * WinRATS lines 124-161: also runs EG test on residuals from long-run eq
  * This is the companion Fourier EG test from the same empirical program
  
  * Step 1: Long-run equation (WinRATS line 76-77)
  * lin y / resid ; # constant sinx cosx x1 x2

  local fvars_eg ""
  if "`cumfreq'" == "" {
    tempvar sin_eg cos_eg
    qui gen double `sin_eg' = sin(2 * _pi * `best_k' * `tvar' / `T') if `touse'
    qui gen double `cos_eg' = cos(2 * _pi * `best_k' * `tvar' / `T') if `touse'
    local fvars_eg "`sin_eg' `cos_eg'"
  }
  else {
    forvalues ff = 1/`best_k' {
      tempvar seg`ff' ceg`ff'
      qui gen double `seg`ff'' = sin(2 * _pi * `ff' * `tvar' / `T') if `touse'
      qui gen double `ceg`ff'' = cos(2 * _pi * `ff' * `tvar' / `T') if `touse'
      local fvars_eg "`fvars_eg' `seg`ff'' `ceg`ff''"
    }
  }
  
  local eg_det "`fvars_eg'"
  if "`model'" == "trend" {
    tempvar trd_eg
    qui gen double `trd_eg' = `tvar' if `touse'
    local eg_det "`eg_det' `trd_eg'"
  }
  
  * Long-run regression
  qui reg `depvar' `fvars_eg' `indepvars' `trend_var' if `touse'
  tempvar eg_resid
  qui predict double `eg_resid' if `touse', resid
  
  * EG test on residuals (WinRATS lines 126-161)
  tempvar deg_resid eg_resid_lag1
  qui gen double `deg_resid' = D.`eg_resid' if `touse'
  qui gen double `eg_resid_lag1' = L.`eg_resid' if `touse'
  
  * Same nested search for EG lags
  local eg_best_ic = 1e30
  local eg_best_tstat = .
  local eg_nlags = `nlags'
  local eg_best_lag = 1
  
  forvalues dlags = 1/`eg_nlags' {
    local eg_rhs "`fvars_eg' `eg_resid_lag1'"
    forvalues j = 1/`dlags' {
      tempvar degr_`j'
      capture drop `degr_`j''
      qui gen double `degr_`j'' = L`j'.`deg_resid' if `touse'
      local eg_rhs "`eg_rhs' `degr_`j''"
    }
    
    capture qui reg `deg_resid' `eg_rhs' if `esample'
    if _rc continue
    
    local nobs_eg = e(N)
    local nreg_eg = e(df_m) + 1
    local ssr_eg  = e(rss)
    local sigsq_eg = `ssr_eg' / `nobs_eg'
    
    if "`criterion'" == "bic" {
      local ic_eg = ln(`sigsq_eg') + ln(`nobs_eg') * `nreg_eg' / `nobs_eg'
    }
    else {
      local ic_eg = ln(`sigsq_eg') + 2.0 * `nreg_eg' / `nobs_eg'
    }
    
    if `ic_eg' < `eg_best_ic' {
      local eg_best_ic = `ic_eg'
      local eg_best_tstat = _b[`eg_resid_lag1'] / _se[`eg_resid_lag1']
      local eg_best_lag = `dlags'
    }
  }
  
  * Display companion EG results
  di
  di in smcl in gr "{hline 70}"
  di in gr "  {bf:Companion: Fourier EG on Residuals}" ///
    _col(40) "t-stat: " in ye %9.4f `eg_best_tstat' ///
    in gr _col(62) "lags: " in ye "`eg_best_lag'"
  di in smcl in gr "{hline 70}"
  
  * ---- Graphs (optional) ----
  if "`graph'" != "" {
    preserve
    
    * ========================================
    * Graph 1: Fourier Deterministic Fit
    * Shows: depvar, Fourier fit, mean
    * ========================================
    
    * Full long-run equation with Fourier + regressors
    local eg_trend ""
    if "`model'" == "trend" {
      tempvar trd_g
      qui gen double `trd_g' = `tvar' if `touse'
      local eg_trend "`trd_g'"
    }
    
    qui reg `depvar' `fvars_eg' `indepvars' `eg_trend' if `touse'
    tempvar yhat_full
    qui predict double `yhat_full' if `touse', xb
    
    * Just Fourier deterministic component (no regressors)
    qui reg `depvar' `fvars_eg' `eg_trend' if `touse'
    tempvar yhat_fourier
    qui predict double `yhat_fourier' if `touse', xb
    
    * Mean only
    qui summ `depvar' if `touse', meanonly
    local ymean = r(mean)
    
    * Pre-format values for graph notes
    local tstat_fmt : di %7.3f `best_tstat'
    local cv5_fmt : di %7.3f `cv5'
    
    twoway (line `depvar' `tvar' if `touse', ///
        lcolor(gs11) lwidth(thin)) ///
      (line `yhat_full' `tvar' if `touse', ///
        lcolor(dkgreen) lwidth(medthick)) ///
      (line `yhat_fourier' `tvar' if `touse', ///
        lcolor(cranberry) lwidth(medium) lpattern(dash)), ///
      title("{bf:FADL: `depvar' -- Fourier Deterministic Fit}", ///
        size(medsmall)) ///
      subtitle("Frequency k* = `best_k' (`freq_label'), " ///
        "Model: `model_label'", size(vsmall)) ///
      legend(order(1 "Actual `depvar'" ///
        2 "Long-run fit (Fourier + X)" ///
        3 "Fourier component only") ///
        size(vsmall) rows(1) position(6)) ///
      ytitle("`depvar'", size(small)) ///
      xtitle("Time", size(small)) ///
      yline(`ymean', lcolor(navy) lwidth(vthin) lpattern(shortdash)) ///
      note("t_ADL^F = `tstat_fmt', CV(5%) = `cv5_fmt'. `decision'", ///
        size(vsmall)) ///
      scheme(s2color) name(fcoint_fadl_fit, replace)
    
    * ========================================
    * Graph 2: Long-Run Residuals
    * Should look stationary if cointegrated
    * ========================================

    tempvar eg_resid_g
    qui reg `depvar' `fvars_eg' `indepvars' `eg_trend' if `touse'
    qui predict double `eg_resid_g' if `touse', resid
    
    twoway (line `eg_resid_g' `tvar' if `touse', ///
        lcolor(dknavy) lwidth(thin)) ///
      (lowess `eg_resid_g' `tvar' if `touse', ///
        lcolor(cranberry) lwidth(medthick) bwidth(0.3)), ///
      title("{bf:FADL: Long-Run Equation Residuals}", ///
        size(medsmall)) ///
      subtitle("Should appear stationary (mean-reverting) " ///
        "if cointegrated", size(vsmall)) ///
      legend(order(1 "Residuals" 2 "Lowess smoother") ///
        size(vsmall) rows(1) position(6)) ///
      ytitle("Residual", size(small)) ///
      xtitle("Time", size(small)) ///
      yline(0, lcolor(gs8) lwidth(vthin) lpattern(dash)) ///
      scheme(s2color) name(fcoint_fadl_resid, replace)
    
    * ========================================
    * Graph 3: Isolated Fourier Component
    * Shows the smooth structural break pattern
    * ========================================
    
    tempvar fourier_only
    qui reg `depvar' `fvars_eg' if `touse'
    qui predict double `fourier_only' if `touse', xb
    * Remove constant to show pure Fourier shape
    qui summ `fourier_only' if `touse', meanonly
    qui replace `fourier_only' = `fourier_only' - r(mean) if `touse'
    
    twoway (area `fourier_only' `tvar' if `touse', ///
        fcolor(cranberry%20) lcolor(cranberry) lwidth(medthick)), ///
      title("{bf:FADL: Fourier Structural Break Component}", ///
        size(medsmall)) ///
      subtitle("Smooth break approximated by " ///
        "sin(2{&pi}k*t/T) + cos(2{&pi}k*t/T), k* = `best_k'", ///
        size(vsmall)) ///
      ytitle("Fourier component (demeaned)", size(small)) ///
      xtitle("Time", size(small)) ///
      yline(0, lcolor(gs8) lwidth(vthin) lpattern(dash)) ///
      note("Positive values: upward shift. " ///
        "Negative: downward shift.", size(vsmall)) ///
      scheme(s2color) name(fcoint_fadl_fourier, replace)
    
    * ========================================
    * Combined graph
    * ========================================
    graph combine fcoint_fadl_fit fcoint_fadl_resid fcoint_fadl_fourier, ///
      cols(1) ///
      title("{bf:Fourier ADL Cointegration Diagnostics}", ///
        size(medsmall)) ///
      subtitle("`depvar' -- k* = `best_k', `model_label'", ///
        size(vsmall)) ///
      scheme(s2color) name(fcoint_fadl, replace) ///
      xsize(7) ysize(12)
    
    * Clean up sub-graphs
    capture graph drop fcoint_fadl_fit
    capture graph drop fcoint_fadl_resid
    capture graph drop fcoint_fadl_fourier
    
    restore
  }
  
  * ---- Store results ----
  return scalar tstat      = `best_tstat'
  return scalar delta      = `best_delta'
  return scalar se_delta   = `best_se'
  return scalar frequency  = `best_k'
  return scalar ssr        = `best_ssr_global'
  return scalar nobs       = `best_nobs'
  return scalar lag_dy     = `best_nlag_dy'
  return scalar lag_dx     = `best_nlag_dx1'
  return scalar eg_tstat   = `eg_best_tstat'
  return scalar eg_lag     = `eg_best_lag'
  return scalar cv1        = `cv1'
  return scalar cv5        = `cv5'
  return scalar cv10       = `cv10'
  return local  test       "fadl"
  return local  model      "`model_label'"
  return local  criterion  "`criterion'"
end
