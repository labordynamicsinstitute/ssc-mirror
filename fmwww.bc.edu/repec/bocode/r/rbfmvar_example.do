*! rbfmvar_example.do — Example do-file for RBFM-VAR package
*! Version 2.0.0, February 2026
*! Author: Dr. Merwan Roudane

// =========================================================================
// RBFM-VAR: Residual-Based Fully Modified VAR Estimation
// Chang, Y. (2000). Econometric Theory, 16(6), 905-926.
// =========================================================================

clear all
set more off

// =========================================================================
// 1. SIMULATED DATA: Two I(1) random walks
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 1: Basic RBFM-VAR with simulated I(1) data}"
di as txt "{hline 78}"

clear
set seed 54321
set obs 200

gen t = _n
tsset t

* Generate two correlated I(1) processes
gen e1 = rnormal(0, 1)
gen e2 = 0.5 * e1 + rnormal(0, sqrt(1.25))
gen y1 = sum(e1)
gen y2 = sum(e2)

* Basic estimation with 1 lag
rbfmvar y1 y2, lags(1) kernel(bartlett)

* View stored results
ereturn list


// =========================================================================
// 2. GRANGER CAUSALITY TEST
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 2: Granger causality testing}"
di as txt "{hline 78}"

* Test: does y2 Granger-cause y1?
rbfmvar y1 y2, lags(1) granger("y2 -> y1")

* Test: does y1 Granger-cause y2?
rbfmvar y1 y2, lags(1) granger("y1 -> y2")


// =========================================================================
// 3. AUTOMATIC LAG SELECTION WITH IC TABLE
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 3: Automatic lag selection via AIC with comparison table}"
di as txt "{hline 78}"

* IC comparison table is displayed automatically when ic() is specified
rbfmvar y1 y2, ic(aic) maxlags(6) kernel(parzen)


// =========================================================================
// 4. IMPULSE RESPONSE FUNCTIONS WITH BOOTSTRAP CI
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 4: IRF with 90% bootstrap confidence intervals}"
di as txt "{hline 78}"

* Compute IRFs with 500 bootstrap replications and 90% CI
rbfmvar y1 y2, lags(1) irf(20) bootreps(500) bootci(90)

* Beautiful IRF plot with shaded CI bands
rbfmvar_graph, irf


// =========================================================================
// 5. IRF WITHOUT BOOTSTRAP (faster, point estimates only)
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 5: IRF point estimates only (no bootstrap)}"
di as txt "{hline 78}"

rbfmvar y1 y2, lags(1) irf(20) bootreps(0)
rbfmvar_graph, irf


// =========================================================================
// 6. FORECAST ERROR VARIANCE DECOMPOSITION
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 6: FEVD computation and visualization}"
di as txt "{hline 78}"

* Estimate with FEVD and IRF
rbfmvar y1 y2, lags(1) irf(20) bootreps(500) fevd

* FEVD stacked area chart
rbfmvar_graph, fevd


// =========================================================================
// 7. FORECASTING WITH FAN CHART
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 7: Multi-step ahead forecast with fan chart}"
di as txt "{hline 78}"

* Estimate with 10-step forecast
rbfmvar y1 y2, lags(1) forecast(10)

* Forecast fan chart (50%, 80%, 95% CI bands)
rbfmvar_graph, forecast


// =========================================================================
// 8. EIGENVALUE STABILITY
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 8: Eigenvalue stability check}"
di as txt "{hline 78}"

rbfmvar y1 y2, lags(1)
rbfmvar_graph, eig


// =========================================================================
// 9. RESIDUAL DENSITY DIAGNOSTICS
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 9: Residual density vs. Normal distribution}"
di as txt "{hline 78}"

rbfmvar y1 y2, lags(1)
rbfmvar_graph, density


// =========================================================================
// 10. FULL ANALYSIS — ALL FEATURES COMBINED
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 10: Complete analysis pipeline}"
di as txt "{hline 78}"

rbfmvar y1 y2, lags(1) irf(20) bootreps(200) bootci(95) ///
    fevd forecast(8) ic(bic) maxlags(6)

* All graphs (default shows everything available)
rbfmvar_graph, saving("rbfmvar_output")


// =========================================================================
// 11. MIXED I(1)/I(2) DATA
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 11: Mixed I(1)/I(2) data}"
di as txt "{hline 78}"

* Generate I(2) process
gen dy3 = sum(rnormal())
gen y3 = sum(dy3)

* RBFM-VAR handles this without pretesting
rbfmvar y1 y3, lags(1) irf(15) bootreps(200) granger("y3 -> y1") kernel(qs)
rbfmvar_graph, irf eig


// =========================================================================
// 12. THREE-VARIABLE SYSTEM
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 12: Three-variable RBFM-VAR}"
di as txt "{hline 78}"

clear
set seed 99999
set obs 300

gen t = _n
tsset t

gen x1 = sum(rnormal())
gen x2 = sum(rnormal())
gen x3 = sum(rnormal())

rbfmvar x1 x2 x3, lags(2) irf(20) bootreps(200) fevd granger("x2 -> x1")
rbfmvar_graph, irf fevd


// =========================================================================
// 13. MONTE CARLO SIMULATION — CASE A (Size, both I(2))
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 13: Monte Carlo — Case A (both I(2))}"
di as txt "{hline 78}"

rbfmvar_simulate, case(a) nobs(150) reps(500) seed(12345)


// =========================================================================
// 14. MONTE CARLO SIMULATION — CASE C (Power)
// =========================================================================

di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:Example 14: Monte Carlo — Case C (Granger causality present)}"
di as txt "{hline 78}"

rbfmvar_simulate, case(c) nobs(150) reps(500) seed(12345)


di _newline as txt "{hline 78}"
di as txt "{col 5}{bf:All examples completed successfully.}"
di as txt "{hline 78}"
