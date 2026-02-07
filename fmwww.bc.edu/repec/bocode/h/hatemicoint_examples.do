*! hatemicoint_examples.do
*! Example file for hatemicoint package
*! Author: Dr. Merwan ROUDANE, Independent Researcher
*! Date: February 2026

clear all
set more off

********************************************************************************
* EXAMPLE 1: Replicating Hatemi-J (2008) Application
* Testing financial market integration between US and UK
********************************************************************************

* Note: The original paper used weekly data from 1989-1999 for S&P 500 and FTSE 100
* Here we use available Stata datasets to illustrate the methodology

di as result "{hline 78}"
di as result "Example 1: Financial Market Integration Test"
di as result "{hline 78}"
di ""

* Use a built-in time series dataset
webuse lutkepohl2, clear
tsset qtr

* Test for cointegration between investment and income
* with two unknown regime shifts
hatemicoint ln_inv ln_inc

di ""
di as text "Interpretation:"
di as text "- If test statistic < critical value: Reject H0 (evidence of cointegration)"
di as text "- Break dates indicate structural changes in the relationship"
di ""

********************************************************************************
* EXAMPLE 2: Different Lag Selection Criteria
********************************************************************************

di as result "{hline 78}"
di as result "Example 2: Comparing Lag Selection Methods"
di as result "{hline 78}"
di ""

webuse lutkepohl2, clear
tsset qtr

di as result "Method 1: t-statistic approach (default)"
hatemicoint ln_inv ln_inc, lagselection(tstat) maxlags(8)
local adf1 = r(adf_min)

di ""
di as result "Method 2: Akaike Information Criterion"
hatemicoint ln_inv ln_inc, lagselection(aic) maxlags(8)
local adf2 = r(adf_min)

di ""
di as result "Method 3: Schwarz Information Criterion"
hatemicoint ln_inv ln_inc, lagselection(sic) maxlags(8)
local adf3 = r(adf_min)

di ""
di as text "Comparison of ADF statistics:"
di as text "  t-stat method: " as result %9.4f `adf1'
di as text "  AIC method:    " as result %9.4f `adf2'
di as text "  SIC method:    " as result %9.4f `adf3'
di ""

********************************************************************************
* EXAMPLE 3: Sensitivity to Trimming Parameter
********************************************************************************

di as result "{hline 78}"
di as result "Example 3: Sensitivity Analysis for Trimming Parameter"
di as result "{hline 78}"
di ""

webuse lutkepohl2, clear
tsset qtr

foreach trim in 0.10 0.15 0.20 0.25 {
    di as result "Trimming = `trim'"
    hatemicoint ln_inv ln_inc, trimming(`trim')
    di ""
}

di as text "Note: Different trimming values may identify different break dates"
di as text "Standard practice uses trimming = 0.15 (Gregory and Hansen 1996)"
di ""

********************************************************************************
* EXAMPLE 4: Multiple Regressors
********************************************************************************

di as result "{hline 78}"
di as result "Example 4: Testing with Multiple Independent Variables"
di as result "{hline 78}"
di ""

webuse lutkepohl2, clear
tsset qtr

* Test with one regressor
di as result "Model 1: One regressor (k=1)"
hatemicoint ln_inv ln_inc
matrix cv1 = r(cv_adfzt)

di ""

* Test with two regressors
di as result "Model 2: Two regressors (k=2)"
hatemicoint ln_inv ln_inc ln_consump
matrix cv2 = r(cv_adfzt)

di ""
di as text "Notice: Critical values become more negative as k increases"
di as text "Critical values for k=1: " as result %7.3f cv1[1,1] ", " %7.3f cv1[1,2] ", " %7.3f cv1[1,3]
di as text "Critical values for k=2: " as result %7.3f cv2[1,1] ", " %7.3f cv2[1,2] ", " %7.3f cv2[1,3]
di ""

********************************************************************************
* EXAMPLE 5: Kernel Choice for Long-Run Variance
********************************************************************************

di as result "{hline 78}"
di as result "Example 5: Comparing Kernel Functions"
di as result "{hline 78}"
di ""

webuse lutkepohl2, clear
tsset qtr

di as result "Bartlett Kernel"
hatemicoint ln_inv ln_inc, kernel(bartlett)
local zt1 = r(zt_min)
local za1 = r(za_min)

di ""

di as result "Quadratic Spectral Kernel"
hatemicoint ln_inv ln_inc, kernel(qs)
local zt2 = r(zt_min)
local za2 = r(za_min)

di ""
di as text "Comparison of Phillips-Perron statistics:"
di as text "  Bartlett kernel:"
di as text "    Zt = " as result %9.4f `zt1' as text ", Za = " as result %9.4f `za1'
di as text "  QS kernel:"
di as text "    Zt = " as result %9.4f `zt2' as text ", Za = " as result %9.4f `za2'
di ""

********************************************************************************
* EXAMPLE 6: Extracting and Using Results
********************************************************************************

di as result "{hline 78}"
di as result "Example 6: Working with Stored Results"
di as result "{hline 78}"
di ""

webuse lutkepohl2, clear
tsset qtr

hatemicoint ln_inv ln_inc

* Extract results
local adf_stat = r(adf_min)
local break1 = r(tb1_adf)
local break2 = r(tb2_adf)
matrix cv = r(cv_adfzt)

di ""
di as text "ADF* test statistic: " as result %9.4f `adf_stat'
di as text "First break at observation: " as result %4.0f `break1'
di as text "Second break at observation: " as result %4.0f `break2'
di ""

* Test decision
if `adf_stat' < cv[1,2] {
    di as result "Decision: Reject H0 at 5% level - Evidence of cointegration"
}
else {
    di as result "Decision: Fail to reject H0 - No evidence of cointegration"
}

di ""

* Get the actual dates if working with date variables
qui tsset
local timevar `r(timevar)'
qui levelsof `timevar' if _n == `break1', local(date1)
qui levelsof `timevar' if _n == `break2', local(date2)
di as text "First break date: " as result "`date1'"
di as text "Second break date: " as result "`date2'"
di ""

********************************************************************************
* EXAMPLE 7: Subsample Analysis
********************************************************************************

di as result "{hline 78}"
di as result "Example 7: Analyzing Subperiods"
di as result "{hline 78}"
di ""

webuse lutkepohl2, clear
tsset qtr

* Full sample
di as result "Full sample analysis"
hatemicoint ln_inv ln_inc
local adf_full = r(adf_min)

di ""

* First half
di as result "First half of sample"
hatemicoint ln_inv ln_inc if qtr < tq(1976q1)
local adf_first = r(adf_min)

di ""

* Second half
di as result "Second half of sample"
hatemicoint ln_inv ln_inc if qtr >= tq(1976q1)
local adf_second = r(adf_min)

di ""
di as text "Comparison:"
di as text "  Full sample:   ADF* = " as result %9.4f `adf_full'
di as text "  First half:    ADF* = " as result %9.4f `adf_first'
di as text "  Second half:   ADF* = " as result %9.4f `adf_second'
di ""

********************************************************************************
* BEST PRACTICES AND RECOMMENDATIONS
********************************************************************************

di as result "{hline 78}"
di as result "Best Practices and Recommendations"
di as result "{hline 78}"
di ""

di as text "1. Sample Size:"
di as text "   - Minimum: T > 50 observations recommended"
di as text "   - Larger samples provide more reliable inference"
di ""

di as text "2. Lag Selection:"
di as text "   - t-stat method is recommended for general use"
di as text "   - AIC/SIC may be preferred for short samples"
di as text "   - Check robustness across different criteria"
di ""

di as text "3. Trimming:"
di as text "   - Default 0.15 is standard (Gregory and Hansen 1996)"
di as text "   - More conservative (0.20) may be used for robustness"
di as text "   - Avoid very small trimming (<0.10)"
di ""

di as text "4. Kernel:"
di as text "   - Bartlett is simpler and widely used"
di as text "   - QS may provide better finite-sample properties"
di as text "   - Results should be robust to kernel choice"
di ""

di as text "5. Interpretation:"
di as text "   - Check all three test statistics (ADF*, Zt*, Za*)"
di as text "   - Break dates may differ slightly across tests"
di as text "   - Verify breaks align with known economic events"
di ""

di as text "6. Model Specification:"
di as text "   - Ensure variables are I(1) before testing"
di as text "   - Maximum of 4 independent variables (k <= 4)"
di as text "   - Consider economic theory when selecting variables"
di ""

di as result "{hline 78}"
di as result "End of Examples"
di as result "{hline 78}"
