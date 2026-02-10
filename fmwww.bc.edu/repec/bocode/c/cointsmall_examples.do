*===============================================================================
* COINTSMALL PACKAGE - COMPREHENSIVE EXAMPLES
*===============================================================================
* Package: cointsmall v1.0.0
* Author: Dr. Merwan Roudane, Independent Researcher
* Email: merwanroudane920@gmail.com
* Date: February 8, 2026
* Based on: Trinh (2022) "Testing for cointegration with structural changes 
*           in very small sample"
*===============================================================================

clear all
set more off
version 14.0

*===============================================================================
* EXAMPLE 1: Basic Usage with Lutkepohl Data
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 1: Basic Usage - Testing Cointegration with One Structural Break"
di "{hline 78}"

* Load sample data
webuse lutkepohl2, clear
describe
tsset qtr

* Look at the data
list in 1/10

* Basic test with default options (1 break, model cs, ADF criterion)
cointsmall dln_inv dln_inc dln_consump

* Access stored results
di _n "Stored results:"
return list

* Display key results
di _n "Sample size: " r(T)
di "Number of regressors: " r(m)
di "ADF* statistic: " r(adf_stat)
di "Critical value: " r(cv)
di "Break date: " r(break1)

*===============================================================================
* EXAMPLE 2: Different Model Specifications
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 2: Comparing Different Model Specifications"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Test without structural break (model o)
di _n "Model O: No structural break"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(0)

* Test with break in constant only (model c)
di _n "Model C: Break in constant only"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(c)

* Test with break in constant and slope (model cs)
di _n "Model CS: Break in constant and slope"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)

*===============================================================================
* EXAMPLE 3: Testing with Two Structural Breaks
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 3: Testing with Two Structural Breaks"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Test with 2 breaks in constant
di _n "Two breaks in constant (model c)"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(2) model(c)

* Test with 2 breaks in constant and slope
di _n "Two breaks in constant and slope (model cs)"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(2) model(cs)

* Access both break dates
di _n "First break: " r(break1) " (observation " r(break1_obs) ")"
di "Second break: " r(break2) " (observation " r(break2_obs) ")"

*===============================================================================
* EXAMPLE 4: Combined Testing Procedure (Recommended)
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 4: Combined Testing Procedure"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Run combined procedure - tests all models and selects best
cointsmall dln_inv dln_inc dln_consump, breaks(1) combined

* Show results from all models
di _n "Results from combined procedure:"
di "ADF statistic (model o): " r(adf_o)
di "ADF statistic (model c): " r(adf_c)
di "ADF statistic (model cs): " r(adf_cs)
di _n "Rejections:"
di "Model o rejects null: " r(reject_o)
di "Model c rejects null: " r(reject_c)
di "Model cs rejects null: " r(reject_cs)
di _n "Selected model: " r(selected_model)

*===============================================================================
* EXAMPLE 5: Using Different Selection Criteria
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 5: ADF vs SSR Criterion for Break Selection"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Using ADF criterion (default) - minimizes test statistic
di _n "ADF Criterion: Minimizes test statistic"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs) criterion(adf)
local break_adf = r(break1)
local adf_adf = r(adf_stat)

* Using SSR criterion - minimizes sum of squared residuals
di _n "SSR Criterion: Minimizes sum of squared residuals"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs) criterion(ssr)
local break_ssr = r(break1)
local adf_ssr = r(adf_stat)

* Compare results
di _n "Comparison:"
di "ADF criterion - Break date: " `break_adf' ", ADF*: " `adf_adf'
di "SSR criterion - Break date: " `break_ssr' ", ADF*: " `adf_ssr'

*===============================================================================
* EXAMPLE 6: Detailed Output
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 6: Detailed Regression Output"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Run test with detail option to see regression coefficients
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs) detail

*===============================================================================
* EXAMPLE 7: Adjusting Trimming and Lag Selection
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 7: Custom Trimming and Lag Parameters"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Default settings (trim=0.15, maxlags automatic)
di _n "Default settings:"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1)
local lags_default = r(lags)

* Custom trimming - allow breaks closer to boundaries
di _n "Custom trimming (trim=0.10):"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1) trim(0.10)

* Custom maximum lags
di _n "Custom maximum lags (maxlags=2):"
di "{hline 40}"
cointsmall dln_inv dln_inc dln_consump, breaks(1) maxlags(2)
local lags_custom = r(lags)

di _n "Lags selected - Default: " `lags_default' ", Custom: " `lags_custom'

*===============================================================================
* EXAMPLE 8: Small Sample Application (T < 30)
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 8: Very Small Sample Application"
di "{hline 78}"

* Generate synthetic small sample data
clear
set obs 25
set seed 12345

gen t = _n
tsset t

* Generate I(1) processes with cointegration
gen e = rnormal()
gen u = sum(e)

gen x = rnormal()
gen v = sum(x)

* Cointegrating relationship with break
gen y = 2 + 0.5*v + u + (t>=15)*(-1 + 0.3*v)

* Test for cointegration
di _n "Testing with T = 25 observations:"
di "{hline 40}"
cointsmall y v, breaks(1) model(cs)

di _n "Note: This very small sample demonstrates the test's capability"
di "to work with limited data, typical of emerging economy time series."

*===============================================================================
* EXAMPLE 9: Comparison Across Sample Sizes
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 9: Critical Values Across Different Sample Sizes"
di "{hline 78}"

* Display critical values for different sample sizes
di _n "Critical values for model CS with 1 break, m=1:"
di "{hline 60}"
di "Sample Size (T)" _col(25) "5% Critical Value"
di "{hline 60}"

foreach T in 15 20 30 40 50 75 100 {
    _cointsmall_crit, t(`T') m(1) breaks(1) model(cs) level(95)
    di %10.0f `T' _col(25) %12.3f r(cv)
}

di "{hline 60}"
di "Note: Critical values become less negative as sample size increases,"
di "reflecting improved power of the test."

*===============================================================================
* EXAMPLE 10: Practical Application - Testing Economic Relationships
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 10: Economic Application - Consumption Function"
di "{hline 78}"

* Load quarterly US data
webuse lutkepohl2, clear
tsset qtr

* Generate log levels from log differences
gen ln_inv = sum(dln_inv)
gen ln_inc = sum(dln_inc)
gen ln_consump = sum(dln_consump)

* Test consumption function: ln_consump = f(ln_inc)
di _n "Testing long-run consumption function with structural break:"
di "{hline 60}"
cointsmall ln_consump ln_inc, breaks(1) model(cs) detail

* Interpretation
di _n "Economic Interpretation:"
di "- If null is rejected: Income and consumption are cointegrated"
di "- Break date indicates structural change in consumption behavior"
di "- Useful for policy analysis and forecasting"

*===============================================================================
* EXAMPLE 11: Model Selection Example
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 11: Systematic Model Selection"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Test sequence: Start general, test restrictions
di _n "Step 1: Test most general model (CS with 2 breaks)"
cointsmall dln_inv dln_inc dln_consump, breaks(2) model(cs)
local reject_cs2 = (r(adf_stat) < r(cv))

di _n "Step 2: Test CS with 1 break"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)
local reject_cs1 = (r(adf_stat) < r(cv))

di _n "Step 3: Test C with 1 break"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(c)
local reject_c1 = (r(adf_stat) < r(cv))

di _n "Step 4: Test no break (model O)"
cointsmall dln_inv dln_inc dln_consump, breaks(0)
local reject_o = (r(adf_stat) < r(cv))

* Summary
di _n(2) "Model Selection Summary:"
di "{hline 60}"
di "Model" _col(30) "Rejects Null?"
di "{hline 60}"
di "O (no break)" _col(30) "`=cond(`reject_o',"Yes","No")'"
di "C (1 break, constant)" _col(30) "`=cond(`reject_c1',"Yes","No")'"
di "CS (1 break, full)" _col(30) "`=cond(`reject_cs1',"Yes","No")'"
di "CS (2 breaks)" _col(30) "`=cond(`reject_cs2',"Yes","No")'"
di "{hline 60}"

*===============================================================================
* EXAMPLE 12: Post-Estimation Analysis
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 12: Post-Estimation Analysis"
di "{hline 78}"

webuse lutkepohl2, clear
tsset qtr

* Run test and save results
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)

* Store key results
local T = r(T)
local break_date = r(break1)
local break_obs = r(break1_obs)
local adf_stat = r(adf_stat)
local cv = r(cv)
local n_lags = r(lags)

* Compute additional statistics
local pct_before = round((`break_obs'/`T')*100, 0.1)
local pct_after = round(((`T'-`break_obs')/`T')*100, 0.1)

* Display comprehensive results
di _n "Comprehensive Test Results:"
di "{hline 60}"
di "Sample characteristics:"
di "  Total observations: " `T'
di "  Number of lags used: " `n_lags'
di _n "Break point:"
di "  Date: " `break_date'
di "  Observation: " `break_obs'
di "  Share of sample before break: " `pct_before' "%"
di "  Share of sample after break: " `pct_after' "%"
di _n "Test statistics:"
di "  ADF* statistic: " %6.3f `adf_stat'
di "  Critical value (5%): " %6.3f `cv'
di "  Test decision: " cond(`adf_stat'<`cv', "Reject null", "Do not reject")
di "{hline 60}"

*===============================================================================
* EXAMPLE 13: Handling Different Data Frequencies
*===============================================================================
di _n(2) "{hline 78}"
di "EXAMPLE 13: Annual vs Quarterly Data"
di "{hline 78}"

* Annual data example (small sample)
clear
set obs 30
set seed 54321
gen year = 1990 + _n - 1
tsset year

gen x = rnormal()
gen v = sum(x)
gen e = 0.5*rnormal()
gen u = sum(e)
gen y = 1 + 0.8*v + u + (year>=2005)*(-0.5 + 0.2*v)

di _n "Annual data (1990-2019, T=30):"
cointsmall y v, breaks(1) model(cs)

* Quarterly data example
clear
webuse lutkepohl2, clear
tsset qtr

di _n "Quarterly data (T=" _N "):"
cointsmall dln_inv dln_inc dln_consump, breaks(1) model(cs)

di _n "Note: The test is designed for annual data with small T,"
di "but also works with quarterly or monthly data."

*===============================================================================
* END OF EXAMPLES
*===============================================================================

di _n(2) "{hline 78}"
di "END OF COINTSMALL EXAMPLES"
di "{hline 78}"
di _n "For more information, type: help cointsmall"
di "Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)"
di "{hline 78}" _n
