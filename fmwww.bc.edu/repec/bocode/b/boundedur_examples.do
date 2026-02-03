*===============================================================================
* BOUNDEDUR EXAMPLES
* Unit Root Tests for Bounded Time Series
* Dr. Merwan Roudane - 02Feb2026
*===============================================================================

version 14.0
clear all
set more off

*===============================================================================
* EXAMPLE 1: Basic usage with lower bound only
*===============================================================================

* Load sample data
webuse lutkepohl, clear
tsset qtr

* Generate a bounded series (for illustration)
gen investment_bounded = investment
replace investment_bounded = max(investment_bounded, 1)

* Test with lower bound at 1
boundedur investment_bounded, lbound(1)

* Store results
return list

*===============================================================================
* EXAMPLE 2: Two-sided bounds
*===============================================================================

* Create series with two bounds
gen rate = uniform()*5 + 2
replace rate = L.rate + rnormal()*0.5
replace rate = max(min(rate, 8), 2)
tsset, clear
tsset qtr

* Test with both bounds
boundedur rate, lbound(2) ubound(8)

*===============================================================================
* EXAMPLE 3: Manual lag selection
*===============================================================================

* Test with user-specified lags
boundedur investment_bounded, lbound(1) lags(4)

* Compare with automatic MAIC selection
boundedur investment_bounded, lbound(1)

*===============================================================================
* EXAMPLE 4: Re-coloring for improved finite sample performance
*===============================================================================

* Without re-coloring
boundedur investment_bounded, lbound(1)
scalar pval_norec = r(pval_adf_t)

* With re-coloring (recommended)
boundedur investment_bounded, lbound(1) recolor
scalar pval_rec = r(pval_adf_t)

* Display comparison
display "p-value without re-coloring: " pval_norec
display "p-value with re-coloring: " pval_rec

*===============================================================================
* EXAMPLE 5: Individual test statistics
*===============================================================================

* Run only ADF_alpha test
boundedur investment_bounded, lbound(1) test(adfalpha)

* Run only MZ_alpha test
boundedur investment_bounded, lbound(1) test(mzalpha)

* Run only MSB test
boundedur investment_bounded, lbound(1) test(msb)

*===============================================================================
* EXAMPLE 6: Varying number of simulations
*===============================================================================

* Quick test with fewer simulations
boundedur investment_bounded, lbound(1) nsim(199)

* More accurate with more simulations
boundedur investment_bounded, lbound(1) nsim(999)

* Very precise (slow)
*boundedur investment_bounded, lbound(1) nsim(4999)

*===============================================================================
* EXAMPLE 7: Comparison with standard tests
*===============================================================================

* Standard ADF test (ignores bounds - may be oversized)
dfuller investment_bounded, lags(4)
scalar pval_standard = r(p)

* Bounded ADF test (accounts for bounds)
boundedur investment_bounded, lbound(1) lags(4) recolor
scalar pval_bounded = r(pval_adf_t)

display _n "=== Comparison with Standard Tests ==="
display "Standard ADF p-value: " pval_standard
display "Bounded ADF p-value: " pval_bounded
display "Difference: " pval_bounded - pval_standard

*===============================================================================
* EXAMPLE 8: Reproducible results with seed
*===============================================================================

* First run
boundedur investment_bounded, lbound(1) seed(12345)
scalar pval1 = r(pval_adf_t)

* Second run with same seed
boundedur investment_bounded, lbound(1) seed(12345)
scalar pval2 = r(pval_adf_t)

* Verify reproducibility
assert abs(pval1 - pval2) < 1e-10

*===============================================================================
* EXAMPLE 9: Monte Carlo study
*===============================================================================

* Simulate bounded I(1) process
clear
set obs 200
gen t = _n
tsset t

* Generate bounded random walk
gen epsilon = rnormal()
gen y = 0 in 1
forvalues i = 2/200 {
    qui replace y = y[`i'-1] + epsilon[`i'] in `i'
    * Reflect at bounds
    qui replace y = max(min(y, 10), 0) in `i'
}

* Test the simulated series
boundedur y, lbound(0) ubound(10) recolor

*===============================================================================
* EXAMPLE 10: US Treasury Bill application (replicating paper)
*===============================================================================

* Note: This example requires the actual T-bill data used in the paper
* The paper uses monthly 3-month T-bill rates from 1957:01 to 2008:09

/*
* Load T-bill data
use "us_tbill_data.dta", clear
tsset time_monthly

* Standard test (ignores lower bound)
dfuller tbill_rate
display "Standard test p-value: " r(p)

* Bounded test with re-coloring (as in paper)
boundedur tbill_rate, lbound(0) recolor
display "Bounded test p-value (ADF_alpha): " r(pval_adf_alpha)
display "Bounded test p-value (ADF_t): " r(pval_adf_t)
display "Bounded test p-value (MZ_alpha): " r(pval_mz_alpha)
display "Bounded test p-value (MZ_t): " r(pval_mz_t)
display "Bounded test p-value (MSB): " r(pval_msb)

* Display bound parameter estimates
display "Estimated c_lower: " r(c_lower)
display "Long-run variance: " r(sigma2_lr)

* The paper reports:
* - Standard tests reject strongly (p < 0.01)
* - Bounded tests fail to reject (p ≈ 0.08-0.12 with re-coloring)
* - Estimated c_lower ≈ -0.16
*/

*===============================================================================
* EXAMPLE 11: Testing with no simulation (standard statistics only)
*===============================================================================

* Compute standard test statistics without bound correction
boundedur investment_bounded, lbound(1) nosimulation

* These statistics may be compared to standard critical values
* but are likely oversized in the presence of bounds

*===============================================================================
* EXAMPLE 12: Testing across different bound values
*===============================================================================

* Create matrix to store results
matrix results = J(5, 3, .)
matrix colnames results = lower_bound test_stat pvalue

local row = 1
foreach lb of numlist 0.5 1 1.5 2 2.5 {
    qui boundedur investment_bounded, lbound(`lb') test(adft)
    matrix results[`row', 1] = `lb'
    matrix results[`row', 2] = r(adf_t)
    matrix results[`row', 3] = r(pval_adf_t)
    local row = `row' + 1
}

* Display sensitivity to bound specification
matrix list results

*===============================================================================
* EXAMPLE 13: Comparison of discretization steps
*===============================================================================

* n = T (recommended)
qui boundedur investment_bounded, lbound(1) nstep(0)
scalar pval_nT = r(pval_adf_t)

* n = 20,000 (as discussed in paper)
qui boundedur investment_bounded, lbound(1) nstep(20000)
scalar pval_n20000 = r(pval_adf_t)

display "p-value with n=T: " pval_nT
display "p-value with n=20,000: " pval_n20000

*===============================================================================
* END OF EXAMPLES
*===============================================================================

display _n "=== All examples completed successfully ==="
