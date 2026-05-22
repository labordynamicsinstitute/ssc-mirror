* ============================================================================
* mixi01 — Example / Demo Script  (LIVE EXECUTION)
* Version 1.0.1, 20 May 2026
* ============================================================================
* This script ACTUALLY RUNS every mixi01 command using simulated data.
*
* DGP: 4-variable mixed I(1)/I(0) system
*   y1 = I(1): output        y2 = I(1): prices
*   y3 = I(1): oil price     y4 = I(0): interest rate
*   Cointegration: y1 - 2*y3 ≈ I(0)
* ============================================================================

clear all
set more off
set seed 20260520

di _n
di as txt "{hline 70}"
di as txt "  mixi01 Package — LIVE Demonstration"
di as txt "  Running ALL mixi01 commands on simulated data"
di as txt "{hline 70}"
di _n

* ============================================================================
* STEP 1: Generate simulated data
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 1: Generate mixed I(1)/I(0) data  (T=300)"
di as txt "{hline 70}"

local T = 300
set obs `T'
gen t = _n
tsset t

* Structural shocks
gen eps1 = rnormal(0, 1)
gen eps2 = rnormal(0, 0.8)
gen eps3 = rnormal(0, 0.6)
gen eps4 = rnormal(0, 0.5)

* I(1) common trends
gen tau1 = sum(eps1)
gen tau2 = sum(eps3)

* Stationary component
gen v_t = 0
replace v_t = 0.7 * L.v_t + eps2 if t > 1

* y1: I(1) — output
gen y1 = 2.0 * tau1 + 0.3 * tau2 + rnormal(0, 0.3)

* y2: I(1) — price level
gen y2 = 1.5 * tau1 - 0.5 * tau2 + v_t + rnormal(0, 0.3)

* y3: I(1) — oil price (cointegrated with y1: y1 - 2*y3 ~ I(0))
gen y3 = 1.0 * tau1 + 0.15 * tau2 + 0.5*v_t + rnormal(0, 0.2)

* y4: I(0) — interest rate
gen y4 = 0
replace y4 = 0.75 * L.y4 + eps4 + 0.2*eps1 if t > 1
replace y4 = eps4 if t == 1

* Cross-variable dynamics
replace y1 = y1 + 0.15 * L.y4 if t > 1
replace y2 = y2 + 0.10 * L.y4 if t > 1

label variable y1 "Output (I(1))"
label variable y2 "Price Level (I(1))"
label variable y3 "Oil Price (I(1))"
label variable y4 "Interest Rate (I(0))"

summarize y1 y2 y3 y4

di _n
di as txt "  Data ready: `T' obs, 3 I(1) + 1 I(0) variables"
di _n


* ============================================================================
* STEP 2: FM-OLS — Phillips (1995)
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 2: mixi01_fmols — FM-OLS with mixed I(1)/I(0)"
di as txt "{hline 70}"
di _n

mixi01_fmols y1 y2 y3 y4, i1vars(y2 y3) i0vars(y4) kernel(bartlett)

di _n
di as txt "  FM-OLS complete. Stored results:"
ereturn list
di _n


* ============================================================================
* STEP 3: FM-VAR — Phillips (1995)
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 3: mixi01_fmvar — FM-VAR(2) system estimation"
di as txt "{hline 70}"
di _n

mixi01_fmvar y1 y2 y3 y4, lags(2) i1vars(y1 y2 y3) i0vars(y4) kernel(bartlett)

di _n
di as txt "  FM-VAR complete. Stored results:"
ereturn list
di _n


* ============================================================================
* STEP 4: Granger Causality — Phillips (1995) Theorem 6.1
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 4: mixi01_test — Granger causality with mixed chi2 limits"
di as txt "{hline 70}"
di _n

* Re-estimate FM-VAR so e() is populated
qui mixi01_fmvar y1 y2 y3 y4, lags(2) i1vars(y1 y2 y3) i0vars(y4) kernel(bartlett)

mixi01_test, granger(y4) conservative

di _n


* ============================================================================
* STEP 5: SVAR with P0/T0 — Fisher, Huh & Pagan (2015)
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 5: mixi01_svar — Structural VAR with P0/T0 shocks"
di as txt "{hline 70}"
di _n

mixi01_svar y1 y2 y3 y4, lags(2) i1vars(y1 y2 y3) i0vars(y4)

di _n
di as txt "  SVAR complete. Stored results:"
ereturn list
di _n


* ============================================================================
* STEP 6: IRF/FEVD — post-SVAR
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 6: mixi01_irf — Impulse responses with P1/T1/P0/T0 labels"
di as txt "{hline 70}"
di _n

* Re-estimate SVAR so e() is populated
qui mixi01_svar y1 y2 y3 y4, lags(2) i1vars(y1 y2 y3) i0vars(y4)

mixi01_irf, step(40)

di _n


* ============================================================================
* STEP 7: Mixed VECM — Chen (2022)
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 7: mixi01_vecm — Mixed VECM with pseudo-cointegration"
di as txt "{hline 70}"
di _n

mixi01_vecm y1 y2 y3 y4, i1vars(y1 y2 y3) i0vars(y4) lags(2) rank(1)

di _n
di as txt "  VECM complete. Stored results:"
ereturn list
di _n


* ============================================================================
* STEP 8: FM-IV — Kitamura & Phillips (1997)
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 8: mixi01_fmiv — FM-IV with mixed I(1)/I(0)"
di as txt "{hline 70}"
di _n

* Generate instruments
gen z1 = L2.y2
gen z2 = L2.y3
gen z3 = L2.y4

mixi01_fmiv y1 (y2 y3 = z1 z2 z3), i1vars(y2 y3) i0vars(y4) method(iv) kernel(bartlett)

di _n
di as txt "  FM-IV complete. Stored results:"
ereturn list
di _n


* ============================================================================
* STEP 9: Comparison with standard OLS
* ============================================================================
di as txt "{hline 70}"
di as txt "  STEP 9: Comparison — Standard OLS vs FM-OLS"
di as txt "{hline 70}"
di _n

qui reg y1 y2 y3 y4
estimates store ols_baseline

qui mixi01_fmols y1 y2 y3 y4, i1vars(y2 y3) i0vars(y4) kernel(bartlett)
estimates store fmols_baseline

estimates table ols_baseline fmols_baseline, b(%9.4f) se(%9.4f) ///
    title("Coefficient Comparison: OLS vs FM-OLS")

di _n


* ============================================================================
* SUMMARY
* ============================================================================
di _n
di as txt "{hline 70}"
di as txt "  SUMMARY — All mixi01 commands executed successfully"
di as txt "{hline 70}"
di _n
di as txt "  Commands tested:"
di as txt "    [x] mixi01_fmols  — FM-OLS (Phillips 1995)"
di as txt "    [x] mixi01_fmvar  — FM-VAR (Phillips 1995)"
di as txt "    [x] mixi01_test   — Wald tests (Phillips 1995, Thm 6.1)"
di as txt "    [x] mixi01_svar   — SVAR P0/T0 (Fisher et al. 2015)"
di as txt "    [x] mixi01_irf    — IRF/FEVD"
di as txt "    [x] mixi01_vecm   — Mixed VECM (Chen 2022)"
di as txt "    [x] mixi01_fmiv   — FM-IV (Kitamura & Phillips 1997)"
di _n
di as txt "  Type {cmd:help mixi01} for full documentation."
di as txt "{hline 70}"
