*===============================================================================
* BOUNDEDUR CERTIFICATION SCRIPT
* Verify package installation and functionality
* Dr. Merwan Roudane - 02Feb2026
*===============================================================================

version 14.0
clear all
set more off

display as text "{hline 78}"
display as text "BOUNDEDUR PACKAGE CERTIFICATION"
display as text "Testing Unit Root Tests for Bounded Time Series"
display as text "{hline 78}"

*===============================================================================
* TEST 1: Basic functionality with time series data
*===============================================================================

display _n as text "TEST 1: Basic functionality with time series"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr

* Generate bounded series
qui gen y = investment
qui replace y = max(y, 2)

* Run test
boundedur y, lbound(2)

* Check returns
assert !missing(r(adf_alpha))
assert !missing(r(pval_adf_alpha))
assert r(N) > 0
assert r(lags) >= 0

display as result "✓ TEST 1 PASSED"

*===============================================================================
* TEST 2: Panel data rejection
*===============================================================================

display _n as text "TEST 2: Panel data should be rejected"
display as text "{hline 78}"

webuse grunfeld, clear
xtset company year

* This should produce an error
capture noisily boundedur invest, lbound(0)
assert _rc == 198

display as result "✓ TEST 2 PASSED (panel data correctly rejected)"

*===============================================================================
* TEST 3: Non-tsset data rejection
*===============================================================================

display _n as text "TEST 3: Non-tsset data should be rejected"
display as text "{hline 78}"

sysuse auto, clear

* This should produce an error
capture noisily boundedur price, lbound(0)
assert _rc == 111

display as result "✓ TEST 3 PASSED (non-tsset data correctly rejected)"

*===============================================================================
* TEST 4: Bound validation
*===============================================================================

display _n as text "TEST 4: Bound validation"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = investment

* Lower bound exceeds data minimum
capture noisily boundedur y, lbound(1000)
assert _rc == 198

* Upper bound less than data maximum
qui summarize y
local ymax = r(max)
capture noisily boundedur y, lbound(0) ubound(`=`ymax'-1')
assert _rc == 198

* Invalid bounds (lower >= upper)
capture noisily boundedur y, lbound(10) ubound(5)
assert _rc == 198

display as result "✓ TEST 4 PASSED (bounds validated correctly)"

*===============================================================================
* TEST 5: Lag selection methods
*===============================================================================

display _n as text "TEST 5: Lag selection"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

* Automatic MAIC selection
qui boundedur y, lbound(1)
local auto_lags = r(lags)

* Manual selection
qui boundedur y, lbound(1) lags(3)
assert r(lags) == 3

display as result "✓ TEST 5 PASSED (lag selection works)"

*===============================================================================
* TEST 6: All test statistics
*===============================================================================

display _n as text "TEST 6: All test statistics"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

* Run all tests
qui boundedur y, lbound(1) test(all) nsim(99)

* Check all statistics are returned
assert !missing(r(adf_alpha))
assert !missing(r(adf_t))
assert !missing(r(mz_alpha))
assert !missing(r(mz_t))
assert !missing(r(msb))

* Check all p-values are in [0,1]
assert r(pval_adf_alpha) >= 0 & r(pval_adf_alpha) <= 1
assert r(pval_adf_t) >= 0 & r(pval_adf_t) <= 1
assert r(pval_mz_alpha) >= 0 & r(pval_mz_alpha) <= 1
assert r(pval_mz_t) >= 0 & r(pval_mz_t) <= 1
assert r(pval_msb) >= 0 & r(pval_msb) <= 1

display as result "✓ TEST 6 PASSED (all statistics computed)"

*===============================================================================
* TEST 7: Individual tests
*===============================================================================

display _n as text "TEST 7: Individual test selection"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

* ADF_alpha only
qui boundedur y, lbound(1) test(adfalpha) nsim(99)
assert !missing(r(adf_alpha))
assert missing(r(adf_t))

* MZ_t only
qui boundedur y, lbound(1) test(mzt) nsim(99)
assert !missing(r(mz_t))
assert missing(r(adf_alpha))

display as result "✓ TEST 7 PASSED (individual tests work)"

*===============================================================================
* TEST 8: Re-coloring device
*===============================================================================

display _n as text "TEST 8: Re-coloring device"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

* Without re-coloring
qui boundedur y, lbound(1) nsim(99)
local pval_norec = r(pval_adf_t)

* With re-coloring
qui boundedur y, lbound(1) recolor nsim(99)
local pval_rec = r(pval_adf_t)

* Both should produce valid p-values
assert `pval_norec' >= 0 & `pval_norec' <= 1
assert `pval_rec' >= 0 & `pval_rec' <= 1

display as result "✓ TEST 8 PASSED (re-coloring works)"

*===============================================================================
* TEST 9: Reproducibility with seed
*===============================================================================

display _n as text "TEST 9: Reproducibility"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

* First run
qui boundedur y, lbound(1) seed(12345) nsim(99)
local pval1 = r(pval_adf_t)

* Second run with same seed
qui boundedur y, lbound(1) seed(12345) nsim(99)
local pval2 = r(pval_adf_t)

* Should be identical
assert abs(`pval1' - `pval2') < 1e-10

display as result "✓ TEST 9 PASSED (results are reproducible)"

*===============================================================================
* TEST 10: No simulation mode
*===============================================================================

display _n as text "TEST 10: No simulation mode"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

* Run without simulation
qui boundedur y, lbound(1) nosimulation

* Should have statistics but no p-values
assert !missing(r(adf_alpha))
assert missing(r(pval_adf_alpha))

display as result "✓ TEST 10 PASSED (no simulation mode works)"

*===============================================================================
* TEST 11: One-sided vs two-sided bounds
*===============================================================================

display _n as text "TEST 11: One-sided vs two-sided bounds"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 2)
qui replace y = min(y, 10)

* One-sided (lower only)
qui boundedur y, lbound(2) nsim(99)
assert r(c_lower) < 0
assert missing(r(c_upper))

* Two-sided
qui boundedur y, lbound(2) ubound(10) nsim(99)
assert r(c_lower) < 0
assert r(c_upper) > 0

display as result "✓ TEST 11 PASSED (one/two-sided bounds work)"

*===============================================================================
* TEST 12: Results matrix
*===============================================================================

display _n as text "TEST 12: Results matrix"
display as text "{hline 78}"

webuse lutkepohl, clear
tsset qtr
gen y = max(investment, 1)

qui boundedur y, lbound(1) nsim(99)

* Check matrix exists
matrix list r(results)
local rows = rowsof(r(results))
local cols = colsof(r(results))

assert `rows' > 0
assert `cols' == 3

display as result "✓ TEST 12 PASSED (results matrix created)"

*===============================================================================
* FINAL SUMMARY
*===============================================================================

display _n as text "{hline 78}"
display as result "ALL CERTIFICATION TESTS PASSED ✓"
display as text "{hline 78}"
display as text "Package: boundedur v1.0.0"
display as text "Author: Dr. Merwan Roudane"
display as text "Email: merwanroudane920@gmail.com"
display as text "{hline 78}"
display _n as result "Package is ready for use and SSC submission!"
