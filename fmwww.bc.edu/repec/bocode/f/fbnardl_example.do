// =============================================================================
// fbnardl_example.do — Example Do-File for FBNARDL Package
// Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
// =============================================================================
// This do-file demonstrates the fbnardl package with simulated data.
// It tests both model types: Fourier NARDL and Fourier Bootstrap NARDL.
// =============================================================================

clear all
set more off
set varabbrev off    // SSC compliance check

// ─────────────────────────────────────────────────────────────────────────────
// 1. GENERATE SIMULATED TIME-SERIES DATA
// ─────────────────────────────────────────────────────────────────────────────
set obs 200
set seed 54321
gen t = _n
tsset t

// Generate I(1) regressors
gen double x = 0
gen double z = 0
replace x = L.x + rnormal(0, 1)   if _n > 1
replace z = L.z + rnormal(0, 0.5) if _n > 1

// Generate dependent variable with asymmetric effects + structural break
// Positive x has larger effect than negative x
gen double dx = D.x
gen double x_pos = 0
gen double x_neg = 0
replace x_pos = max(dx, 0) if dx != .
replace x_neg = min(dx, 0) if dx != .
replace x_pos = sum(x_pos)
replace x_neg = sum(x_neg)

// Add Fourier-type structural break
gen double fourier_break = sin(2 * c(pi) * 1.5 * t / 200) * 2

// Generate dependent variable with asymmetric effects + lagged dynamics
// Positive x has larger effect than negative x
// Includes lagged decomposed effects: L1.x_pos, L2.x_pos (true q=2)
gen double y = 0
replace y = 0.5 * L.y + 0.8 * x_pos + 0.3 * L.x_pos + 0.15 * L2.x_pos ///
            - 0.3 * x_neg - 0.2 * L.x_neg + 0.4 * z ///
            + fourier_break + rnormal(0, 1) if _n > 2

// Drop construction variables
drop dx x_pos x_neg fourier_break

// ─────────────────────────────────────────────────────────────────────────────
// 2. FOURIER NARDL (Kripfganz & Schneider critical values)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 1: Fourier NARDL (type = fnardl)"
di as res "============================================================"

fbnardl y z, decompose(x) type(fnardl) maxlag(4) maxk(3) ic(aic)

// Check stored results
di _newline
di as res "--- Stored Results ---"
ereturn list

// ─────────────────────────────────────────────────────────────────────────────
// 3. FOURIER BOOTSTRAP NARDL (Bertelli et al. 2022 bootstrap)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 2: Fourier Bootstrap NARDL (type = fbnardl)"
di as res "============================================================"

fbnardl y z, decompose(x) type(fbnardl) maxlag(3) maxk(2) ic(aic) reps(499)

di _newline
di as res "--- Stored Results ---"
ereturn list

// ─────────────────────────────────────────────────────────────────────────────
// 4. PURE NARDL (no Fourier terms)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 3: Pure NARDL (no Fourier, type = fnardl)"
di as res "============================================================"

fbnardl y z, decompose(x) type(fnardl) nofourier maxlag(4) ic(bic)

// ─────────────────────────────────────────────────────────────────────────────
// 5. MULTIPLE DECOMPOSED VARIABLES
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 4: Multiple decomposed variables"
di as res "============================================================"

fbnardl y, decompose(x z) type(fnardl) maxlag(3) ic(aic) nodynmult

// ─────────────────────────────────────────────────────────────────────────────
// 6. MINIMAL OUTPUT (suppress diagnostics and multipliers)
// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  TEST 5: Minimal output"
di as res "============================================================"

fbnardl y z, decompose(x) type(fnardl) nodiag nodynmult notable maxlag(2)

// ─────────────────────────────────────────────────────────────────────────────
di _newline(3)
di as res "============================================================"
di as res "  ALL TESTS COMPLETED SUCCESSFULLY"
di as res "  Package: fbnardl v1.0.0"
di as res "  Author: Dr. Merwan Roudane"
di as res "============================================================"
