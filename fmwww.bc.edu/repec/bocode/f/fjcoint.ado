*! fjcoint.ado -- Johansen-Fourier Cointegration Tests for Time Series
*! Version 1.0.0
*!
*! Implements:
*!   Johansen  -- Standard Johansen (1991) cointegration test
*!   Fourier   -- Johansen-Fourier test (Pascalau, Lee, Nazlioglu & Lu, 2022)
*!   SBC       -- Schwarz Bayes Criterion model selection procedure
*!
*! Translated from GAUSS code by Saban Nazlioglu
*! Stata version by Dr Merwan Roudane (merwanroudane920@gmail.com)

program define fjcoint, rclass
  version 14.0
  
  * ---- Parse syntax ----
  syntax varlist(min=2 ts) [if] [in], ///
    [                                  ///
      Test(string)                     ///
      MODel(string)                    ///
      MAXLag(integer 2)               ///
      FReq(integer 1)                 ///
      OPTion(string)                  ///
      MAXFreq(integer 3)              ///
      TRIMming(real 0.1)              ///
      GRaph                           ///
      NOTable                         ///
    ]
  
  * ---- Time-series check ----
  qui tsset
  if "`r(timevar)'" == "" {
    di in red "time-series data not set; use {bf:tsset} first"
    exit 459
  }
  
  * ---- Validate test ----
  if "`test'" == "" local test "fourier"
  local test_str = lower("`test'")
  
  if !inlist("`test_str'", "johansen", "fourier", "sbc", "all") {
    di in red "invalid test(`test'). Choose: johansen, fourier, sbc, or all"
    exit 198
  }
  
  * ---- Parse model ----
  if "`model'" == "" local model "rc"
  local model_str = lower("`model'")
  
  * Map to Johansen model numbers (1-5)
  if "`model_str'" == "none"     local model_num = 1
  else if "`model_str'" == "rc"  local model_num = 2
  else if inlist("`model_str'", "constant", "uc") local model_num = 3
  else if "`model_str'" == "rt"  local model_num = 4
  else if inlist("`model_str'", "trend", "ut")    local model_num = 5
  else {
    di in red "invalid model(`model'). Choose: none, rc, constant/uc, rt, trend/ut"
    exit 198
  }
  
  * Map to Fourier model numbers (1-4, different from Johansen)
  * Fourier GAUSS: 1=UC, 2=UT, 3=RC, 4=RT
  if "`model_str'" == "none"     local fmodel = 3
  else if "`model_str'" == "rc"  local fmodel = 3
  else if inlist("`model_str'", "constant", "uc") local fmodel = 1
  else if "`model_str'" == "rt"  local fmodel = 4
  else if inlist("`model_str'", "trend", "ut")    local fmodel = 2
  else                           local fmodel = 3
  
  * ---- Parse option ----
  if "`option'" == "" local option "single"
  local opt_str = lower("`option'")
  
  if "`opt_str'" == "single"          local opt_num = 1
  else if inlist("`opt_str'", "cumulative", "cumul") local opt_num = 2
  else {
    di in red "invalid option(`option'). Choose: single or cumulative"
    exit 198
  }
  
  * ---- Validate ----
  if `freq' < 1 {
    di in red "freq() must be at least 1"
    exit 198
  }
  if `freq' > 5 {
    di as txt "  Note: freq() capped at 5"
    local freq = 5
  }
  if `maxlag' < 1 {
    di in red "maxlag() must be at least 1"
    exit 198
  }
  
  * ---- Mark sample ----
  marksample touse
  markout `touse' `varlist'
  
  qui count if `touse'
  local T = r(N)
  
  if `T' < 30 {
    di in red "insufficient observations (T = `T'). Need at least 30."
    exit 2001
  }
  
  local nvars : word count `varlist'
  
  * ---- Main header ----
  di
  di in smcl in gr _col(5) "{c TLC}{hline 66}{c TRC}"
  di in smcl in gr _col(5) "{c |}" _col(12) ///
     "{bf:fjcoint: Johansen-Fourier Cointegration Tests}" _col(72) "{c |}"
  di in smcl in gr _col(5) "{c |}" _col(12) ///
     "Pascalau, Lee, Nazlioglu & Lu (2022)" _col(72) "{c |}"
  di in smcl in gr _col(5) "{c BLC}{hline 66}{c BRC}"
  di in gr "  Variables : " in ye "`varlist'"
  di in gr "  Obs (T)   : " in ye "`T'" ///
     _col(36) in gr "# Variables : " in ye "`nvars'"
  di in smcl in gr "{hline 72}"
  
  * ---- Dispatch ----
  
  if "`test_str'" == "johansen" | "`test_str'" == "all" {
    _fjcoint_johansen, varlist(`varlist') touse(`touse') ///
      model(`model_num') lags(`maxlag') `notable'
    
    if "`test_str'" == "johansen" {
      return add
    }
  }
  
  if "`test_str'" == "fourier" | "`test_str'" == "all" {
    _fjcoint_fourier, varlist(`varlist') touse(`touse') ///
      model(`fmodel') lags(`maxlag') freq(`freq') option(`opt_num') ///
      `notable'
    
    if "`test_str'" == "fourier" {
      return add
    }
  }
  
  if "`test_str'" == "sbc" | "`test_str'" == "all" {
    _fjcoint_sbc, varlist(`varlist') touse(`touse') ///
      model(`fmodel') maxlag(`maxlag') trimming(`trimming') ///
      maxfreq(`maxfreq') option(`opt_num') `notable'
    
    if "`test_str'" == "sbc" {
      return add
    }
  }
  
  * ---- Graphs ----
  if "`graph'" != "" {
    _fjcoint_graph, varlist(`varlist') touse(`touse') ///
      model(`fmodel') freq(`freq') option(`opt_num') lags(`maxlag') ///
      test(`test_str')
  }
  
  * Store common results
  return local  cmd       "fjcoint"
  return local  varlist   "`varlist'"
  return scalar nobs      = `T'
  return scalar nvars     = `nvars'
  return local  test      "`test_str'"
  return local  model     "`model_str'"
  return scalar maxlag    = `maxlag'
  return scalar frequency = `freq'
  return local  option    "`opt_str'"
  
end
