// =========================================================================
// aardl_example.do — Example: Augmented ARDL Package (8 Models)
// =========================================================================
// Version 1.2.0 — 2026-03-04
// Author: Dr. Merwan Roudane
//
// This example demonstrates all 8 model types in the aardl package
// using the Lutkepohl (1993) macroeconomic dataset (built into Stata).
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
// MODEL 1: aardl — Augmented ARDL (asymptotic)
//   Uses Sam et al. (2019) 3-test framework
//   No bootstrap, no Fourier, no NARDL
// =========================================================================
di as res _n "=========================================="
di as res "  Example 1: aardl (Augmented ARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) ic(aic) case(3)

di as txt _n "Check stored results:"
ereturn list

// =========================================================================
// MODEL 2: baardl — Bootstrap Augmented ARDL
//   Uses bootstrap critical values (BVZ method)
// =========================================================================
di as res _n "=========================================="
di as res "  Example 2: baardl (Bootstrap A-ARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(baardl) maxlag(4) reps(499) bootstrap(bvz) case(3)

// =========================================================================
// MODEL 3: faardl — Fourier Augmented ARDL
//   Adds Fourier terms, selects k* by min SSR
// =========================================================================
di as res _n "=========================================="
di as res "  Example 3: faardl (Fourier A-ARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(faardl) maxlag(4) maxk(3) ic(aic) case(3)

// =========================================================================
// MODEL 4: fbaardl — Fourier Bootstrap Augmented ARDL
//   Combines Fourier + bootstrap
// =========================================================================
di as res _n "=========================================="
di as res "  Example 4: fbaardl (Fourier Bootstrap A-ARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(fbaardl) maxlag(3) maxk(3) reps(499) bootstrap(bvz) case(3)

// =========================================================================
// MODEL 5: nardl — Augmented NARDL (asymptotic)
//   NARDL with asymptotic PSS bounds tests
//   No bootstrap, no Fourier
// =========================================================================
di as res _n "=========================================="
di as res "  Example 5: nardl (Augmented NARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(nardl) decompose(ln_consump) maxlag(4) ic(aic) case(3)

// =========================================================================
// MODEL 6: fanardl — Fourier Augmented NARDL
//   NARDL + Fourier terms, asymptotic inference
// =========================================================================
di as res _n "=========================================="
di as res "  Example 6: fanardl (Fourier A-NARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(fanardl) decompose(ln_consump) maxlag(3) maxk(3) ic(aic) case(3)

// =========================================================================
// MODEL 7: banardl — Bootstrap Augmented NARDL
//   Decomposes ln_consump into positive/negative partial sums
// =========================================================================
di as res _n "=========================================="
di as res "  Example 7: banardl (Bootstrap A-NARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(banardl) decompose(ln_consump) maxlag(3) reps(499) bootstrap(bvz) case(3)

// =========================================================================
// MODEL 8: fbanardl — Fourier Bootstrap Augmented NARDL
//   Full model: Fourier + Bootstrap + NARDL
// =========================================================================
di as res _n "=========================================="
di as res "  Example 8: fbanardl (Fourier Bootstrap A-NARDL)"
di as res "=========================================="

aardl ln_inv ln_inc ln_consump, type(fbanardl) decompose(ln_consump) maxlag(3) maxk(3) reps(499) bootstrap(bvz) case(3)

// =========================================================================
// ADDITIONAL EXAMPLES
// =========================================================================

// Example 9: Use McNown bootstrap method instead of BVZ
di as res _n "=========================================="
di as res "  Example 9: baardl with McNown bootstrap"
di as res "=========================================="
aardl ln_inv ln_inc ln_consump, type(baardl) maxlag(4) reps(499) bootstrap(mcnown) case(3)

// Example 10: BIC instead of AIC
di as res _n "=========================================="
di as res "  Example 10: faardl with BIC selection"
di as res "=========================================="
aardl ln_inv ln_inc ln_consump, type(faardl) maxlag(4) maxk(5) ic(bic) case(3)

// Example 11: Minimal output (suppress diagnostics, multipliers, advanced)
di as res _n "=========================================="
di as res "  Example 11: Minimal output"
di as res "=========================================="
aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) nodiag nodynmult noadvanced notable

// Example 12: Post-estimation advanced analysis
di as res _n "=========================================="
di as res "  Example 12: Post-estimation aardl_advanced"
di as res "=========================================="
aardl ln_inv ln_inc ln_consump, type(aardl) maxlag(4) ic(aic) case(3) noadvanced nograph
aardl_advanced
aardl_advanced, horizon(30) nograph

// ─── Done ───
di as txt _n "{hline 60}"
di as res "  All aardl examples completed successfully."
di as txt "{hline 60}"
