// =========================================================================
// mvardlurt_example.do — Example: Multivariate ARDL Unit Root Test
// =========================================================================
// Version 1.0.0 — 2026-02-24
// Author: Dr. Merwan Roudane
//
// This example demonstrates the mvardlurt command using the
// Lutkepohl (1993) macroeconomic dataset (built into Stata).
//
// Reference: Sam, McNown, Goh & Goh (2024) — "A multivariate
// autoregressive distributed lag unit root test."
// =========================================================================

clear all
set more off

// ─── 1. LOAD SAMPLE DATA ───
// Lutkepohl (1993): West German quarterly macroeconomic data, 1960q1-1982q4
// Variables: ln_inv (log investment), ln_inc (log income), ln_consump (log consumption)
webuse lutkepohl2, clear
tsset

di as txt ""
di as txt "{hline 60}"
di as res "  Lutkepohl (1993) — West German Macro Data"
di as txt "{hline 60}"
summarize ln_inv ln_inc ln_consump
di as txt "{hline 60}"
di as txt ""

// =========================================================================
// EXAMPLE 1: Case 3 — Intercept Only (default)
//   Test H0: ln_inv has a unit root
//   Covariate: ln_inc
//   Matches EViews %regtype = "i"
// =========================================================================
di as res _n "=============================================="
di as res "  Example 1: Case 3 — Intercept Only"
di as res "=============================================="

mvardlurt ln_inv ln_inc, case(3) maxlag(4) reps(999) seed(12345)

di as txt _n "Stored results:"
ereturn list

// =========================================================================
// EXAMPLE 2: Case 5 — Intercept and Trend
//   Test H0: ln_inv has a unit root (with trend)
//   Matches EViews %regtype = "t"
// =========================================================================
di as res _n "=============================================="
di as res "  Example 2: Case 5 — Intercept + Trend"
di as res "=============================================="

mvardlurt ln_inv ln_inc, case(5) maxlag(4) reps(999) seed(12345) nograph

// =========================================================================
// EXAMPLE 3: Case 1 — No Deterministics
//   Matches EViews %regtype = "n"
// =========================================================================
di as res _n "=============================================="
di as res "  Example 3: Case 1 — No Deterministics"
di as res "=============================================="

mvardlurt ln_inv ln_inc, case(1) maxlag(4) reps(999) seed(12345) nograph

// =========================================================================
// EXAMPLE 4: BIC-Based Lag Selection with More Reps
//   Uses BIC instead of AIC for model selection
//   2000 bootstrap replications for more precise critical values
// =========================================================================
di as res _n "=============================================="
di as res "  Example 4: BIC Selection, 2000 reps"
di as res "=============================================="

mvardlurt ln_inv ln_inc, case(3) maxlag(6) ic(bic) reps(2000) seed(54321) nograph

// =========================================================================
// EXAMPLE 5: Manual Lag Specification
//   Manually specify ARDL(2, 1) instead of auto-selection
//   Matches EViews %selfspec = "M" with !fix_p = 2, !fix_q = 1
// =========================================================================
di as res _n "=============================================="
di as res "  Example 5: Manual Lag — ARDL(2, 1)"
di as res "=============================================="

mvardlurt ln_inv ln_inc, fixlag(2 1) case(3) reps(999) seed(12345) nograph

// =========================================================================
// EXAMPLE 6: Quick Check Without Bootstrap
//   For fast preliminary analysis
// =========================================================================
di as res _n "=============================================="
di as res "  Example 6: No Bootstrap (Quick Check)"
di as res "=============================================="

mvardlurt ln_inv ln_inc, case(3) maxlag(4) noboot nograph

// =========================================================================
// EXAMPLE 7: Different Variable Pair
//   Test ln_consump with ln_inc as covariate
// =========================================================================
di as res _n "=============================================="
di as res "  Example 7: ln_consump / ln_inc"
di as res "=============================================="

mvardlurt ln_consump ln_inc, case(3) maxlag(4) reps(999) seed(12345) nograph

// =========================================================================
// EXAMPLE 8: Minimal Output
//   Suppress everything except the core results
// =========================================================================
di as res _n "=============================================="
di as res "  Example 8: Minimal Output"
di as res "=============================================="

mvardlurt ln_inv ln_inc, case(3) maxlag(4) reps(499) notable nodiag nograph

// ─── Done ───
di as txt _n "{hline 60}"
di as res "  All mvardlurt examples completed successfully."
di as txt "{hline 60}"
