*! wavenardl_example.do - self-test / worked examples for the wavenardl package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Run from the folder containing the package files, or after net install.

clear all
set more off
version 17

* ============================================================================
* PART 0 - Numerical validation of the Haar "a trous" denoiser
*          Reference values computed independently (wavenardl Python library)
* ============================================================================
di as res _n "=== PART 0: HTW numerical validation ==="

quietly {
    clear
    input double x
    1.0
    2.5
    1.8
    3.2
    2.9
    4.1
    3.6
    5.0
    4.4
    5.8
    5.1
    6.5
    6.0
    7.2
    6.8
    8.1
    end
    gen t = _n
    tsset t
}

wdenoise x, generate(dn) levels(3) nograph

assert abs(r(sigma_x)  - 0.6300963677) < 1e-8
assert abs(r(lambda_x) - 1.4837635569) < 1e-8
assert r(J_x) == 3
assert abs(dn_x[1]  - 1.0000000000) < 1e-8
assert abs(dn_x[2]  - 1.1875000000) < 1e-8
assert abs(dn_x[5]  - 1.8000000000) < 1e-8
assert abs(dn_x[16] - 6.2375000000) < 1e-8

* hard thresholding on the same series (same result here: all |d| < lambda)
wdenoise x, generate(hd) levels(3) threshold(hard) nograph
assert abs(hd_x[16] - 6.2375000000) < 1e-8

di as res "PART 0 passed: Mata HTW matches the independent reference values."

* ============================================================================
* PART 1 - Simulated asymmetric cointegrated system
* ============================================================================
di as res _n "=== PART 1: simulated W-NARDL, one decomposed variable ==="

clear
set seed 20260702
set obs 200
gen t = _n
tsset t

* random-walk regressor and its partial sums
gen double ex = rnormal()
gen double x = sum(ex)
gen double xp = sum(max(ex, 0))
gen double xn = sum(min(ex, 0))

* control variable (random walk)
gen double ez = rnormal()
gen double z = sum(ez)

* asymmetric long-run relation + observation noise (so denoising matters)
gen double y = 2 + 0.9*xp + 0.4*xn + 0.3*z + rnormal(0, 1.5)

* --- basic call: denoise all, BIC, compare with raw NARDL ---
wavenardl y, decompose(x) maxlag(2) nograph

* stored results must exist
assert e(N) > 100
assert !missing(e(F_pss))
assert !missing(e(lr_pos_x))
assert !missing(e(lr_neg_x))
assert !missing(e(bic))
assert !missing(e(bic_raw))
assert "`e(cmd)'" == "wavenardl"
di as res "PART 1 passed."

* ============================================================================
* PART 2 - Control variable, AIC, hard threshold, trend (case V)
* ============================================================================
di as res _n "=== PART 2: control + trend + hard threshold, ic(aic) ==="

wavenardl y z, decompose(x) maxlag(2) ic(aic) threshold(hard) trend nograph
assert "`e(case)'" == "5"
assert !missing(e(F_pss))
di as res "PART 2 passed."

* ============================================================================
* PART 3 - denoise() variants, generate(), nocompare
* ============================================================================
di as res _n "=== PART 3: denoise variants ==="

* denoise the dependent variable only, skip the comparison
wavenardl y, decompose(x) maxlag(2) denoise(dep) nocompare nograph
assert !missing(e(sigma_y))

* denoise the regressors only, save the denoised series
capture drop s_*
wavenardl y, decompose(x) maxlag(2) denoise(indep) generate(s) nograph
confirm variable s_x
assert !missing(e(sigma_x))

* plain NARDL (no denoising) - comparison is skipped automatically
wavenardl y, decompose(x) maxlag(2) denoise(none) nograph
assert "`e(denoise)'" == "none"
di as res "PART 3 passed."

* ============================================================================
* PART 4 - two decomposed variables, levels(), horizon()
* ============================================================================
di as res _n "=== PART 4: two decomposed variables ==="

wavenardl y, decompose(x z) maxlag(1) levels(4) horizon(10) nograph
assert !missing(e(lr_pos_x))
assert !missing(e(lr_pos_z))
assert e(J_y) == 4
di as res "PART 4 passed."

* ============================================================================
* PART 5 - wdenoise on multiple variables, replace, if/in
* ============================================================================
di as res _n "=== PART 5: wdenoise variants ==="

capture drop dn_*
wdenoise y x z, generate(dn) nograph
confirm variable dn_y
confirm variable dn_x
confirm variable dn_z

gen double ycopy = y
wdenoise ycopy, replace nograph
assert ycopy[50] != y[50]

capture drop dsub_*
wdenoise y if t <= 150, generate(dsub) nograph
assert missing(dsub_y[175])
assert !missing(dsub_y[100])
di as res "PART 5 passed."

* ============================================================================
* PART 6 - full output run with graphs (visual inspection)
* ============================================================================
di as res _n "=== PART 6: full run with graphs and tables ==="

wavenardl y z, decompose(x) maxlag(2) horizon(15)

di as res _n "{hline 60}"
di as res "ALL PARTS PASSED - wavenardl package self-test complete."
di as res "{hline 60}"
