// =============================================================================
// fbardl_example.do — Example Do-File for FBARDL Package
// Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
// =============================================================================
// This do-file demonstrates the fbardl package with simulated data.
// It tests all three model types: Fourier ARDL, Fourier Bootstrap ARDL
// (McNown 2018), and Fourier Bootstrap ARDL (Bertelli et al. 2022).
// =============================================================================

clear all
set more off
set varabbrev off

// ─────────────────────────────────────────────────────────────────────────────
// 1. GENERATE SIMULATED TIME-SERIES DATA
// ─────────────────────────────────────────────────────────────────────────────
set obs 200
set seed 54321
gen t = _n
tsset t

// Generate I(1) regressors
gen double x1 = 0
gen double x2 = 0
replace x1 = L.x1 + rnormal(0, 1) if _n > 1
replace x2 = L.x2 + rnormal(0, 0.8) if _n > 1

// Generate dependent variable with cointegration + Fourier structural break
// y_t = 0.5*y_{t-1} + 0.8*x1 + 0.4*x2 + structural_break + error
// Structural break is a slow Fourier shift
gen double fourier_break = 2 * sin(2 * c(pi) * 1.5 * t / 200) + cos(2 * c(pi) * 1.5 * t / 200)

gen double y = 0
replace y = 0.5 * L.y + 0.8 * x1 + 0.3 * L.x1 ///
            + 0.4 * x2 + fourier_break + rnormal(0, 1) if _n > 1

drop fourier_break

// ─────────────────────────────────────────────────────────────────────────────
// 2. FOURIER ARDL (PSS bounds test with Kripfganz & Schneider CVs)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 1: Fourier ARDL (type = fardl)"
di as res "============================================================"

fbardl y x1 x2, type(fardl) maxlag(4) maxk(3) ic(aic)

// Check stored results
di _newline
di as res "--- Stored Results ---"
ereturn list

// ─────────────────────────────────────────────────────────────────────────────
// 3. FOURIER BOOTSTRAP ARDL — McNown et al. (2018)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 2: Fourier Bootstrap ARDL — McNown et al. (2018)"
di as res "============================================================"

fbardl y x1 x2, type(fbardl_mcnown) maxlag(3) maxk(2) ic(aic) reps(499)

di _newline
di as res "--- Stored Results ---"
ereturn list

// ─────────────────────────────────────────────────────────────────────────────
// 4. FOURIER BOOTSTRAP ARDL — Bertelli, Vacca & Zoia (2022)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 3: Fourier Bootstrap ARDL — Bertelli et al. (2022)"
di as res "============================================================"

fbardl y x1 x2, type(fbardl_bvz) maxlag(3) maxk(2) ic(aic) reps(499)

di _newline
di as res "--- Stored Results ---"
ereturn list

// ─────────────────────────────────────────────────────────────────────────────
// 5. PURE ARDL (no Fourier terms)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 4: Pure ARDL (no Fourier, type = fardl)"
di as res "============================================================"

fbardl y x1 x2, type(fardl) nofourier maxlag(4) ic(bic)

// ─────────────────────────────────────────────────────────────────────────────
// 6. MINIMAL OUTPUT (suppress diagnostics and multipliers)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 5: Minimal output"
di as res "============================================================"

fbardl y x1 x2, type(fardl) nodiag nodynmult noadvanced maxlag(2)

// ─────────────────────────────────────────────────────────────────────────────
// 7. ROBUST STANDARD ERRORS — hac()
// ─────────────────────────────────────────────────────────────────────────────
// The point estimates are identical across all three; only the standard
// errors, t statistics, p-values and Wald (F) statistics change.
di _newline(3)
di as res "============================================================"
di as res "  TEST 6: hac(hetero) — heteroskedasticity-robust (White HC1)"
di as res "============================================================"

fbardl y x1 x2, type(fardl) maxlag(2) maxk(2) hac(hetero) ///
    nodynmult noadvanced

di _newline(3)
di as res "============================================================"
di as res "  TEST 7: hac(both) — HAC (Newey-West), automatic lag"
di as res "============================================================"

fbardl y x1 x2, type(fardl) maxlag(2) maxk(2) hac(both) ///
    nodynmult noadvanced

di _newline(3)
di as res "============================================================"
di as res "  TEST 8: hac(both) with a user-specified truncation lag"
di as res "============================================================"

fbardl y x1 x2, type(fardl) maxlag(2) maxk(2) hac(both) haclags(6) ///
    nodiag nodynmult noadvanced

// The tabulated PSS / Kripfganz-Schneider bounds assume i.i.d. errors.
// With hac() the bootstrap types are the consistent choice: they re-derive
// the critical values under the same covariance estimator.
di _newline(3)
di as res "============================================================"
di as res "  TEST 9: HAC errors with bootstrap critical values"
di as res "============================================================"

fbardl y x1 x2, type(fbardl_mcnown) maxlag(2) maxk(2) reps(499) hac(both) ///
    nodiag nodynmult noadvanced

// ─────────────────────────────────────────────────────────────────────────────
// 8. FIXED (EXOGENOUS) REGRESSORS — exog() / fixed()
// ─────────────────────────────────────────────────────────────────────────────
// Fixed regressors enter contemporaneously, without lag selection, and are
// excluded from the long-run relationship and the cointegration tests.
gen byte step  = (t > 150)              // step / regime dummy
gen byte pulse = (t == 100)             // one-off outlier
gen byte grp   = mod(t, 4)              // for a factor-variable example

di _newline(3)
di as res "============================================================"
di as res "  TEST 10: exog() — step dummy and pulse dummy"
di as res "============================================================"

fbardl y x1 x2, type(fardl) maxlag(2) maxk(2) exog(step pulse) ///
    nodiag nodynmult noadvanced

di _newline(3)
di as res "============================================================"
di as res "  TEST 11: fixed() synonym with factor variables"
di as res "============================================================"

fbardl y x1 x2, type(fardl) maxlag(2) maxk(2) fixed(i.grp) ///
    nodiag nodynmult noadvanced

di _newline(3)
di as res "============================================================"
di as res "  TEST 12: hac() and exog() combined, bootstrap CVs"
di as res "============================================================"

fbardl y x1 x2, type(fbardl_bvz) maxlag(2) maxk(2) reps(499) ///
    hac(both) exog(step pulse) nodynmult noadvanced

di _newline
di as res "--- Stored Results ---"
di "covariance estimator : " e(vce)
di "fixed regressors     : " e(exog)
di "n fixed estimated    : " e(n_exog)
di "Newey-West lag       : " e(haclags)

// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  ALL TESTS COMPLETED SUCCESSFULLY"
di as res "  Package: fbardl v1.2.0"
di as res "  Author: Dr. Merwan Roudane"
di as res "============================================================"
