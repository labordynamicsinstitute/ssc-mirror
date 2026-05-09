*! quasicoint_example.do — Complete tutorial for quasicoint
*! Version 1.0.2 — 2026-05-09
*! Author: Dr. Merwan Roudane
*!
*! This file demonstrates the quasicoint package using Stata's built-in
*! Lutkepohl (2005) dataset. Variables should be in LEVELS (not differences)
*! since the method targets near-unit root processes.

// ============================================================================
//  SETUP
// ============================================================================
clear all
set more off
set scheme s2color

// ============================================================================
//  EXAMPLE 1: Basic bivariate — levels data with near-unit roots
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 1: Bivariate Levels (ln_inv, ln_inc)}"
di "{hline 72}" _n

webuse lutkepohl2, clear
tsset qtr

// Level variables have roots near unity — ideal for quasi-cointegration
quasicoint ln_inv ln_inc, rho(0.95)

// Key results:
//   Dominant root: 0.994 (half-life ~123 quarters)
//   QCS beta:     (1, -0.857)
//   Johansen beta: (1, -0.857)
//   LR(lambda=1):  0.000 => Cannot reject unit root

// ============================================================================
//  EXAMPLE 2: Three variables in levels
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 2: Trivariate System}"
di "{hline 72}" _n

quasicoint ln_inv ln_inc ln_consump, rho(0.95) nroots(1)

// p=3, q=1 => r=2 quasi-cointegrating relations

// ============================================================================
//  EXAMPLE 3: Specific lag order with LaTeX export
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 3: VAR(4) with LaTeX Export}"
di "{hline 72}" _n

quasicoint ln_inv ln_inc, rho(0.95) lags(4) export(latex) saving(qc_results)

// Creates: qc_results_quasicoint.tex (booktabs table with stars)

// ============================================================================
//  EXAMPLE 4: Plots
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 4: Full Analysis with Plots}"
di "{hline 72}" _n

quasicoint ln_inv ln_inc, rho(0.95) plot saving(qc_analysis)

// Creates: qc_analysis_profile.png  (profile likelihood + conditional CIs)
//          qc_analysis_irf.png      (impulse response functions)
//          qc_analysis_roots.png    (characteristic root map)

// ============================================================================
//  EXAMPLE 5: Robustness — varying rho
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 5: Robustness Across rho}"
di "{hline 72}" _n

di as text _col(5) "rho" _col(18) "half-life" _col(33) "lambda" _col(48) "beta"
di as text "{hline 60}"

foreach rr in 0.90 0.93 0.95 0.97 0.99 {
    qui quasicoint ln_inv ln_inc, rho(`rr')
    local hl = -ln(2)/ln(`rr')
    di as result _col(5) %5.2f `rr' ///
       _col(18) %8.1f `hl' ///
       _col(33) %10.5f e(lambda_hat) ///
       _col(48) %10.5f e(b)[1,1]
}
di as text "{hline 60}"
di as text "  beta is stable across all rho values"

// ============================================================================
//  EXAMPLE 6: Stationary data — triggers WARNING
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 6: Stationary Data (growth rates) — expect WARNING}"
di "{hline 72}" _n

quasicoint dln_inv dln_inc, rho(0.95)

// The WARNING tells you these are already stationary — use levels instead

// ============================================================================
//  EXAMPLE 7: Post-estimation
// ============================================================================
di _n "{hline 72}"
di "{bf:EXAMPLE 7: Post-Estimation Commands}"
di "{hline 72}" _n

qui quasicoint ln_inv ln_inc, rho(0.95)

di "=== KEY SCALARS ==="
di "  Dominant root (lambda_hat): " %8.5f e(lambda_hat)
di "  LR statistic (H0: lam=1):  " %8.3f e(LR_lambda)
di "  VAR lag order (k):          " e(k)
di "  QCS dimension (r):          " e(r)
di "  Observations (N):           " e(N)

di _n "=== MATRICES ==="
matrix list e(b), title("Free QCS coefficients")
matrix list e(beta_qcs), title("Full QCS vector")
matrix list e(beta_johansen), title("Johansen comparison")
matrix list e(eigenvalues), title("Characteristic roots")

// ============================================================================
di _n "{hline 72}"
di "{bf:All examples completed successfully.}"
di "{hline 72}"
