*! fcoint.ado -- Fourier Cointegration Tests for Time Series
*! A comprehensive library implementing:
*!   FADL  -- Banerjee, Arcabic & Lee (2017, Economic Modelling)
*!   FEG   -- Banerjee & Lee (Working Paper)
*!   FEG2  -- Banerjee & Lee (Working Paper)
*!   Tsong -- Tsong, Lee, Tsai & Hu (2016, Empirical Economics)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

program define fcoint, rclass
  version 14.0
  
  * ---- Parse syntax ----
  syntax varlist(min=2 ts) [if] [in], ///
    Test(string)                       ///
    [                                  ///
      MODel(string)                    ///
      MAXFreq(integer 5)              ///
      MAXLag(integer 0)               ///
      CRIterion(string)               ///
      CUMFreq                         ///
      DOLS(integer 0)                 ///
      GRaph                           ///
    ]
  
  * ---- Time-series check ----
  qui tsset
  if "`r(timevar)'" == "" {
    di in red "time-series data not set; use {bf:tsset} first"
    exit 459
  }
  
  * ---- Parse depvar and indepvars ----
  gettoken depvar indepvars : varlist
  
  local nxvars : word count `indepvars'
  if `nxvars' == 0 {
    di in red "at least one independent variable required"
    exit 198
  }
  
  * ---- Validate test ----
  local test_str = lower("`test'")
  
  if !inlist("`test_str'", "fadl", "feg", "feg2", "tsong", "all") {
    di in red "invalid test(`test'). Choose: fadl, feg, feg2, tsong, or all"
    exit 198
  }
  
  * ---- Model ----
  if "`model'" == "" local model "constant"
  local model_str = lower("`model'")
  
  if !inlist("`model_str'", "constant", "trend") {
    di in red "invalid model(`model'). Choose: constant or trend"
    exit 198
  }
  
  * ---- Criterion ----
  if "`criterion'" == "" local criterion "aic"
  local crit_str = lower("`criterion'")
  
  if !inlist("`crit_str'", "aic", "bic") {
    di in red "invalid criterion(`criterion'). Choose: aic or bic"
    exit 198
  }
  
  * ---- MaxFreq ----
  if `maxfreq' < 1 {
    di in red "maxfreq() must be at least 1"
    exit 198
  }
  if `maxfreq' > 5 local maxfreq = 5
  
  * ---- Mark sample ----
  marksample touse
  markout `touse' `varlist'
  
  qui count if `touse'
  local T = r(N)
  
  if `T' < 30 {
    di in red "insufficient observations (T = `T'). Need at least 30."
    exit 2001
  }
  
  * ---- Dispatch to test(s) ----
  if "`test_str'" == "fadl" | "`test_str'" == "all" {
    _fcoint_fadl, depvar(`depvar') indepvars(`indepvars') ///
      touse(`touse') model(`model_str') maxfreq(`maxfreq') ///
      maxlag(`maxlag') criterion(`crit_str') ///
      `cumfreq' `graph'
    
    if "`test_str'" == "fadl" {
      * Return results from FADL
      return scalar tstat     = r(tstat)
      return scalar delta     = r(delta)
      return scalar se_delta  = r(se_delta)
      return scalar frequency = r(frequency)
      return scalar ssr       = r(ssr)
      return scalar nobs      = r(nobs)
      return scalar lag_dy    = r(lag_dy)
      return scalar lag_dx    = r(lag_dx)
      return scalar cv1       = r(cv1)
      return scalar cv5       = r(cv5)
      return scalar cv10      = r(cv10)
      return local  test      "fadl"
      return local  model     "`r(model)'"
      return local  criterion "`r(criterion)'"
      return local  depvar    "`depvar'"
      return local  indepvars "`indepvars'"
    }
  }
  
  if "`test_str'" == "feg" | "`test_str'" == "all" {
    _fcoint_feg, depvar(`depvar') indepvars(`indepvars') ///
      touse(`touse') model(`model_str') maxfreq(`maxfreq') ///
      maxlag(`maxlag') criterion(`crit_str') ///
      `cumfreq' `graph'
    
    if "`test_str'" == "feg" {
      return scalar tstat     = r(tstat)
      return scalar delta     = r(delta)
      return scalar se_delta  = r(se_delta)
      return scalar frequency = r(frequency)
      return scalar nobs      = r(nobs)
      return scalar lag       = r(lag)
      return scalar cv1       = r(cv1)
      return scalar cv5       = r(cv5)
      return scalar cv10      = r(cv10)
      return local  test      "feg"
      return local  model     "`r(model)'"
      return local  depvar    "`depvar'"
      return local  indepvars "`indepvars'"
    }
  }
  
  if "`test_str'" == "feg2" | "`test_str'" == "all" {
    _fcoint_feg2, depvar(`depvar') indepvars(`indepvars') ///
      touse(`touse') model(`model_str') maxfreq(`maxfreq') ///
      maxlag(`maxlag') criterion(`crit_str') ///
      `cumfreq' `graph'
    
    if "`test_str'" == "feg2" {
      return scalar tstat     = r(tstat)
      return scalar delta     = r(delta)
      return scalar se_delta  = r(se_delta)
      return scalar rho2      = r(rho2)
      return scalar frequency = r(frequency)
      return scalar nobs      = r(nobs)
      return scalar lag       = r(lag)
      return scalar cv1       = r(cv1)
      return scalar cv5       = r(cv5)
      return scalar cv10      = r(cv10)
      return local  test      "feg2"
      return local  model     "`r(model)'"
      return local  depvar    "`depvar'"
      return local  indepvars "`indepvars'"
    }
  }
  
  if "`test_str'" == "tsong" | "`test_str'" == "all" {
    _fcoint_tsong, depvar(`depvar') indepvars(`indepvars') ///
      touse(`touse') model(`model_str') maxfreq(`maxfreq') ///
      dolslags(`dols') `graph'
    
    if "`test_str'" == "tsong" {
      return scalar CI_stat    = r(CI_stat)
      return scalar F_stat     = r(F_stat)
      return scalar omega2     = r(omega2)
      return scalar frequency  = r(frequency)
      return scalar nobs       = r(nobs)
      return scalar dolslags   = r(dolslags)
      return scalar ci_cv1     = r(ci_cv1)
      return scalar ci_cv5     = r(ci_cv5)
      return scalar ci_cv10    = r(ci_cv10)
      return scalar f_cv1      = r(f_cv1)
      return scalar f_cv5      = r(f_cv5)
      return scalar f_cv10     = r(f_cv10)
      return local  test       "tsong"
      return local  model      "`r(model)'"
      return local  depvar     "`depvar'"
      return local  indepvars  "`indepvars'"
    }
  }
  
  * ---- Footer for "all" ----
  if "`test_str'" == "all" {
    di
    di in smcl in gr "{hline 70}"
    di in gr "{bf:Summary: All Fourier Cointegration Tests Complete}"
    di in smcl in gr "{hline 70}"
  }
end
