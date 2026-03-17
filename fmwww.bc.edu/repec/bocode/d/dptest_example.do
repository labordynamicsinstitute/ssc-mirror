* ==============================================================================
* dptest_example.do
* Example usage of the dptest package
* Author: Dr. Merwan Roudane
* Date: 2026-03-14
* ==============================================================================

clear all
set more off

* ==============================================================================
* PART 1: Unit Root Tests on a Single Time Series
* ==============================================================================

di _n "{hline 78}"
di "{bf:PART 1: Unit Root Tests — Air Passengers Data}"
di "{hline 78}"

* Load built-in data
webuse air2, clear
tsset t

* --- Run all three unit root tests at once ---
di _n "{bf:Test 1: All unit root tests with constant}"
dptest air

* Expected: The air passengers series shows strong trending behavior.
* The DP test should find the series is I(1) or I(2).
* HF and HZ tests determine if two unit roots are present.

* --- Individual tests ---
di _n "{bf:Test 2: Dickey-Pantula only, constant+trend}"
dptest air, test(dp) det(trend)

* Expected: Including a trend may change the DP conclusion because
* the critical values are different (more negative) when a trend is included.

di _n "{bf:Test 3: Hasza-Fuller F test, no deterministics}"
dptest air, test(hf) det(none)

* Expected: The F statistic tests H0: alpha=beta=1 (two unit roots).
* If F > CV, reject → at most I(1). If F <= CV, cannot reject I(2).

di _n "{bf:Test 4: Haldrup Z(F*) with quadratic trend}"
dptest air, test(hz) det(qtrend)

* Expected: Z(F*) corrects for serial correlation. If the uncorrected HF
* rejected but Z(F*) does not, the HF rejection was likely a size distortion.

di _n "{bf:Test 5: All tests at 1% significance}"
dptest air, level(1)

* Expected: 1% level is more conservative (harder to reject nulls).
* Some rejections at 5% may become non-rejections at 1%.

* Check returned values
return list

* ==============================================================================
* PART 2: Unit Root Tests on Simulated I(2) Data
* ==============================================================================

di _n(2) "{hline 78}"
di "{bf:PART 2: Simulated I(2) Process}"
di "{hline 78}"

* Generate I(2) process: Delta^2(y) = epsilon
* This means y_t = y_{t-1} + dy_{t-1} + eps_t, where dy is a random walk
clear
set obs 200
set seed 12345
gen t = _n
tsset t

gen double eps = rnormal()
gen double dy = sum(eps)        // I(1): random walk
gen double y_i2 = sum(dy)       // I(2): cumulated random walk

di _n "{bf:Test 6: All tests on simulated I(2) series}"
dptest y_i2

* Expected:
*   DP  → I(2): rejects d=2, does not reject d=1
*   HF  → I(2): F statistic below critical value (cannot reject two unit roots)
*   Z(F*) → I(2): same conclusion as HF (semiparametric confirms)

di _n "{bf:Test 7: DP test with diagnostic graphs}"
dptest y_i2, test(dp) graph

* Expected graphs:
*   Level series: smooth, drifting curve (characteristic of I(2))
*   First difference: random walk pattern (still non-stationary)
*   Second difference: white noise scatter around zero (stationary)
*   ACF level: very slow linear decay
*   ACF first diff: slow decay
*   ACF second diff: quick cutoff (near zero after lag 1)

* ==============================================================================
* PART 3: Unit Root Tests on Simulated I(1) Data
* ==============================================================================

di _n(2) "{hline 78}"
di "{bf:PART 3: Simulated I(1) Process}"
di "{hline 78}"

gen double y_i1 = sum(rnormal())    // I(1): simple random walk

di _n "{bf:Test 8: All tests on I(1) series}"
dptest y_i1

* Expected:
*   DP  → I(1): rejects d=2 at step 2, does not reject d=1
*   HF  → <= I(1): F > CV (rejects two unit roots)
*   Z(F*) → <= I(1): Z(F*) > CV (confirms)

* ==============================================================================
* PART 4: Unit Root Tests on Simulated I(0) Data
* ==============================================================================

di _n(2) "{hline 78}"
di "{bf:PART 4: Simulated I(0)/Stationary Process}"
di "{hline 78}"

gen double y_stat = rnormal()       // I(0): white noise

di _n "{bf:Test 9: All tests on stationary series}"
dptest y_stat

* Expected:
*   DP  → I(0): rejects at all steps
*   HF  → <= I(1): strongly rejects two unit roots
*   Z(F*) → <= I(1): strongly rejects

* ==============================================================================
* PART 5: Cointegration Test with I(1) and I(2) Variables
* ==============================================================================

di _n(2) "{hline 78}"
di "{bf:PART 5: Cointegration Test — Haldrup (1994 JoE)}"
di "{hline 78}"

* Generate cointegrated system:
*   x1 ~ I(1), x2 ~ I(2)
*   y = x2 + 0.5*x1 + v, where v ~ I(1)
*   Since y - x2 - 0.5*x1 = v ~ I(1), there exists a CI(2,1) relationship

gen double e1 = rnormal()
gen double e2 = rnormal()
gen double ev = rnormal()

gen double x1 = sum(e1)            // I(1) regressor
gen double dx2 = sum(e2)           // I(1) intermediate
gen double x2 = sum(dx2)           // I(2) regressor
gen double v = sum(ev)             // I(1) equilibrium error
gen double y_coint = x2 + 0.5*x1 + v

di _n "{bf:Test 10: Cointegration with 1 I(1) and 1 I(2) regressor}"
dptest y_coint x1 x2, test(coint) i2vars(x2)

* Expected: With m1=1 (I(1) vars) and m2=1 (I(2) vars), the ADF statistic
* on residuals should be sufficiently negative to reject H0 of no
* cointegration, confirming a long-run equilibrium exists.

* Check returned values
di _n "Returned values:"
return list

* Two I(2) regressors
gen double e3 = rnormal()
gen double dx3 = sum(e3)
gen double x3 = sum(dx3)           // Second I(2) regressor
gen double y_coint2 = x2 + x3 + 0.3*x1 + v

di _n "{bf:Test 11: Cointegration with 1 I(1) and 2 I(2) regressors}"
dptest y_coint2 x1 x2 x3, test(coint) i2vars(x2 x3)

* Expected: m1=1, m2=2. Critical values are more negative (harder to reject)
* because more I(2) regressors increase spurious cointegration risk.

* ==============================================================================
* PART 6: Sensitivity Analysis
* ==============================================================================

di _n(2) "{hline 78}"
di "{bf:PART 6: Sensitivity to Significance Level}"
di "{hline 78}"

foreach lev in 1 5 10 {
    di _n "{bf:Level: `lev'%}"
    dptest y_i2, test(hf) level(`lev')
}

* Expected: At more liberal levels (10%), you may reject when you wouldn't at
* conservative levels (1%). If results switch between 5% and 10%, the
* evidence is borderline.

di _n(2) "{hline 78}"
di "{bf:All examples completed successfully.}"
di "{hline 78}"
