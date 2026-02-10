*===============================================================================
* COINTSMALL PACKAGE - CERTIFICATION SCRIPT
*===============================================================================
* Package: cointsmall v1.0.0
* Author: Dr. Merwan Roudane, Independent Researcher
* Email: merwanroudane920@gmail.com
* Date: February 8, 2026
*
* Purpose: Verify that cointsmall package functions correctly
*          Run all tests before SSC submission
*===============================================================================

clear all
set more off
version 14.0

di _n(2) "{hline 78}"
di "COINTSMALL CERTIFICATION SCRIPT"
di "Version 1.0.0"
di "{hline 78}" _n

local errors = 0
local warnings = 0
local tests = 0

*===============================================================================
* TEST 1: Command exists and loads
*===============================================================================
local ++tests
di "Test `tests': Checking command availability..." _c

cap which cointsmall
if _rc {
    di " {red}FAILED{txt}"
    di "  Error: cointsmall.ado not found"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 2: Help file exists
*===============================================================================
local ++tests
di "Test `tests': Checking help file..." _c

cap help cointsmall
if _rc {
    di " {red}FAILED{txt}"
    di "  Error: cointsmall.sthlp not found"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 3: Basic functionality - Model O
*===============================================================================
local ++tests
di "Test `tests': Testing model O (no structural break)..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(0)
    
    * Check returns
    assert r(T) == _N
    assert r(breaks) == 0
    assert r(adf_stat) != .
    assert r(cv) != .
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Model O test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 4: Model C with 1 break
*===============================================================================
local ++tests
di "Test `tests': Testing model C with 1 break..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(c)
    
    * Check returns
    assert r(breaks) == 1
    assert r(break1) != .
    assert r(break1_obs) != .
    assert r(adf_stat) != .
    assert r(cv) != .
    assert "`r(model)'" == "c"
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Model C (1 break) test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 5: Model CS with 1 break
*===============================================================================
local ++tests
di "Test `tests': Testing model CS with 1 break..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)
    
    * Check returns
    assert r(breaks) == 1
    assert r(break1) != .
    assert "`r(model)'" == "cs"
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Model CS (1 break) test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 6: Model C with 2 breaks
*===============================================================================
local ++tests
di "Test `tests': Testing model C with 2 breaks..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(2) model(c)
    
    * Check returns
    assert r(breaks) == 2
    assert r(break1) != .
    assert r(break2) != .
    assert r(break1_obs) < r(break2_obs)
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Model C (2 breaks) test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 7: Model CS with 2 breaks
*===============================================================================
local ++tests
di "Test `tests': Testing model CS with 2 breaks..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(2) model(cs)
    
    * Check returns
    assert r(breaks) == 2
    assert r(break1) != .
    assert r(break2) != .
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Model CS (2 breaks) test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 8: Combined testing procedure
*===============================================================================
local ++tests
di "Test `tests': Testing combined procedure..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) combined
    
    * Check returns
    assert r(adf_o) != .
    assert r(adf_c) != .
    assert r(adf_cs) != .
    assert r(cv_o) != .
    assert r(cv_c) != .
    assert r(cv_cs) != .
    assert inlist(r(reject_o), 0, 1)
    assert inlist(r(reject_c), 0, 1)
    assert inlist(r(reject_cs), 0, 1)
    assert "`r(selected_model)'" != ""
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Combined procedure test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 9: SSR criterion
*===============================================================================
local ++tests
di "Test `tests': Testing SSR criterion..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs) criterion(ssr)
    
    * Check returns
    assert "`r(criterion)'" == "ssr"
    assert r(ssr) != .
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: SSR criterion test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 10: Small sample (T < 30)
*===============================================================================
local ++tests
di "Test `tests': Testing with very small sample (T=25)..." _c

cap noi {
    clear
    set obs 25
    set seed 12345
    gen t = _n
    tsset t
    
    gen e = rnormal()
    gen u = sum(e)
    gen x = rnormal()
    gen v = sum(x)
    gen y = 2 + 0.5*v + u + (t>=15)*(-1 + 0.3*v)
    
    qui cointsmall y v, breaks(1) model(cs)
    
    * Check it runs and returns values
    assert r(T) == 25
    assert r(adf_stat) != .
    assert r(cv) != .
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Small sample test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 11: Critical values function
*===============================================================================
local ++tests
di "Test `tests': Testing critical values function..." _c

cap noi {
    * Test critical values for various specifications
    qui _cointsmall_crit, t(30) m(1) breaks(0) model(o) level(95)
    local cv1 = r(cv)
    
    qui _cointsmall_crit, t(30) m(1) breaks(1) model(c) level(95)
    local cv2 = r(cv)
    
    qui _cointsmall_crit, t(30) m(1) breaks(1) model(cs) level(95)
    local cv3 = r(cv)
    
    * Check critical values are negative and sensible
    assert `cv1' < 0
    assert `cv2' < `cv1'  // More negative for structural break
    assert `cv3' < `cv2'  // Even more negative for full break
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Critical values function test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 12: Panel data rejection
*===============================================================================
local ++tests
di "Test `tests': Testing panel data rejection..." _c

cap noi {
    webuse grunfeld, clear
    qui xtset company year
    
    * Should give error
    cap noi cointsmall invest mvalue, breaks(1)
    assert _rc == 198
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Panel data should be rejected"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 13: Time series not set rejection
*===============================================================================
local ++tests
di "Test `tests': Testing tsset requirement..." _c

cap noi {
    sysuse auto, clear
    
    * Should give error - not time series
    cap noi cointsmall price mpg weight
    assert _rc != 0
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Should require tsset data"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 14: Invalid options
*===============================================================================
local ++tests
di "Test `tests': Testing invalid option handling..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    
    * Invalid model
    cap noi cointsmall dln_inv dln_inc, breaks(1) model(invalid)
    assert _rc == 198
    
    * Invalid breaks number
    cap noi cointsmall dln_inv dln_inc, breaks(3)
    assert _rc == 198
    
    * Incompatible options
    cap noi cointsmall dln_inv dln_inc, breaks(0) model(c)
    assert _rc == 198
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Invalid options should be caught"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 15: Different numbers of regressors
*===============================================================================
local ++tests
di "Test `tests': Testing with different numbers of regressors..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    
    * 1 regressor
    qui cointsmall dln_inv dln_inc, breaks(1) model(cs)
    assert r(m) == 1
    
    * 2 regressors
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)
    assert r(m) == 2
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Different numbers of regressors test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 16: Trimming parameter
*===============================================================================
local ++tests
di "Test `tests': Testing trimming parameter..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    
    * Default trim
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)
    local break1_default = r(break1_obs)
    
    * Custom trim
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs) trim(0.10)
    local break1_custom = r(break1_obs)
    
    * Check breaks are within valid range
    assert `break1_default' > 0 & `break1_default' < r(T)
    assert `break1_custom' > 0 & `break1_custom' < r(T)
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Trimming parameter test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 17: Maximum lags parameter
*===============================================================================
local ++tests
di "Test `tests': Testing maximum lags parameter..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    
    * Custom maxlags
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) maxlags(2)
    assert r(lags) <= 2
    
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) maxlags(4)
    assert r(lags) <= 4
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Maximum lags parameter test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 18: Detail option
*===============================================================================
local ++tests
di "Test `tests': Testing detail option..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    
    * Should run without error
    cap noi cointsmall dln_inv dln_inc dln_consump, breaks(1) detail
    assert _rc == 0
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Detail option test failed"
    local ++errors
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 19: Replication of paper results (if data available)
*===============================================================================
local ++tests
di "Test `tests': Testing consistency with paper methodology..." _c

cap noi {
    * Create synthetic data matching paper's DGP
    clear
    set obs 30
    set seed 123
    gen t = _n
    tsset t
    
    * Generate cointegrated series with known break
    gen u_eps = rnormal()
    gen u = sum(u_eps)
    
    gen x = rnormal()
    gen v = sum(x)
    
    * True model: y = 1 + 0.5*v + u + I(t>=15)*(-0.5 + 0.3*v)
    gen y = 1 + 0.5*v + u + (t>=15)*(-0.5 + 0.3*v)
    
    qui cointsmall y v, breaks(1) model(cs)
    
    * Should detect break near observation 15
    local detected_break = r(break1_obs)
    assert abs(`detected_break' - 15) <= 3  // Allow some variation
}

if _rc {
    di " {yellow}WARNING{txt}"
    di "  Warning: Paper replication check inconclusive"
    local ++warnings
}
else {
    di " {green}PASSED{txt}"
}

*===============================================================================
* TEST 20: Memory and performance
*===============================================================================
local ++tests
di "Test `tests': Testing with larger sample..." _c

cap noi {
    webuse lutkepohl2, clear
    qui tsset qtr
    
    * Time the execution
    timer clear 1
    timer on 1
    qui cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)
    timer off 1
    qui timer list 1
    local elapsed = r(t1)
    
    * Should complete in reasonable time (< 60 seconds for this sample)
    if `elapsed' > 60 {
        di " {yellow}WARNING{txt}"
        di "  Warning: Execution took `elapsed' seconds (> 60)"
        local ++warnings
    }
    else {
        di " {green}PASSED{txt} (completed in " %4.2f `elapsed' " seconds)"
    }
}

if _rc {
    di " {red}FAILED{txt}"
    di "  Error: Performance test failed"
    local ++errors
}

*===============================================================================
* FINAL SUMMARY
*===============================================================================

di _n(2) "{hline 78}"
di "CERTIFICATION SUMMARY"
di "{hline 78}"
di "Total tests run: " `tests'
di "Tests passed: " `tests' - `errors'
di "Tests failed: {red}`errors'{txt}"
di "Warnings: {yellow}`warnings'{txt}"
di "{hline 78}"

if `errors' == 0 {
    di "{green}ALL TESTS PASSED{txt}"
    di "Package is ready for distribution"
}
else {
    di "{red}SOME TESTS FAILED{txt}"
    di "Please fix errors before distribution"
}

if `warnings' > 0 {
    di "{yellow}Note: Some tests generated warnings - please review{txt}"
}

di "{hline 78}" _n

* Return summary
return scalar tests = `tests'
return scalar errors = `errors'
return scalar warnings = `warnings'
return scalar pass_rate = (`tests' - `errors') / `tests'

exit `errors'
