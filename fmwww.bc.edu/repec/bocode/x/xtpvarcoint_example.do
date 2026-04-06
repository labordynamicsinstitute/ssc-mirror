*! xtpvarcoint_example.do
*! Complete demonstration of xtpvarcoint package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version: 1.0.0

clear all
set more off
capture log close

// ============================================================
// 1. SETUP: Load example data
// ============================================================

di
di "{hline 78}"
di "  xtpvarcoint — Complete Package Demonstration"
di "{hline 78}"
di

* Use Grunfeld dataset (available in Stata)
webuse grunfeld2, clear
xtset company year

describe
xtdes

di
di "  Variables: invest (Investment), mvalue (Market Value), kstock (Capital Stock)"
di "  Panel: 10 firms, 1935-1954 (T=20, N=10)"
di

// ============================================================
// 2. SPECIFICATION: Lag order selection
// ============================================================

di
di "{hline 78}"
di "  Step 1: Lag Order Selection"
di "{hline 78}"
di

xtpvarcoint speci var invest mvalue kstock, lagset(1 2 3 4)

// ============================================================
// 3. PANEL COINTEGRATION TESTS
// ============================================================

di
di "{hline 78}"
di "  Step 2: Panel Cointegration Rank Tests"
di "{hline 78}"
di

* Johansen panel test
di "--- Johansen Panel Test (Larsson et al. 2001) ---"
xtpvarcoint pcoint invest mvalue kstock, method(JO) lags(2) type(Case3)

* CAIN panel test (robust to cross-sectional dependence)
di "--- CAIN Panel Test (Arsova & Oersal 2021) ---"
xtpvarcoint pcoint invest mvalue kstock, method(CAIN) lags(2) type(Case3)

// ============================================================
// 4. INDIVIDUAL COINTEGRATION TEST (for a single unit)
// ============================================================

di
di "{hline 78}"
di "  Step 3: Individual Cointegration Test (Company 1)"
di "{hline 78}"
di

preserve
keep if company == 1
tsset year

xtpvarcoint coint invest mvalue kstock, lags(2) type(Case3) method(JO)

restore

// ============================================================
// 5. PANEL VAR ESTIMATION
// ============================================================

di
di "{hline 78}"
di "  Step 4: Panel VAR Estimation (Mean Group)"
di "{hline 78}"
di

xtpvarcoint pvar invest mvalue kstock, lags(2) type(const)

* Store results for IRF
mat A_est = r(A)

// ============================================================
// 6. PANEL VECM ESTIMATION
// ============================================================

di
di "{hline 78}"
di "  Step 5: Panel VECM Estimation (rank = 1)"
di "{hline 78}"
di

xtpvarcoint pvec invest mvalue kstock, lags(2) rank(1) type(Case3)

// ============================================================
// 7. IMPULSE RESPONSE FUNCTIONS
// ============================================================

di
di "{hline 78}"
di "  Step 6: Impulse Response Functions"
di "{hline 78}"
di

* First re-estimate pvar for stored results
xtpvarcoint pvar invest mvalue kstock, lags(2) type(const)

* Compute IRFs
xtpvarcoint irf, horizon(20)

// ============================================================
// 8. FORECAST ERROR VARIANCE DECOMPOSITION
// ============================================================

di
di "{hline 78}"
di "  Step 7: Forecast Error Variance Decomposition"
di "{hline 78}"
di

xtpvarcoint fevd, horizon(20)

// ============================================================
// 9. SPECIFICATION: Common Factors
// ============================================================

di
di "{hline 78}"
di "  Step 8: Number of Common Factors"
di "{hline 78}"
di

xtpvarcoint speci factors invest mvalue kstock, ///
  kmax(5) differenced centered nfactors(2)

// ============================================================
// 10. SUMMARY
// ============================================================

di
di "{hline 78}"
di "  xtpvarcoint — Demonstration Complete"
di "{hline 78}"
di
di "  All 7 modules demonstrated successfully:"
di "    1. Specification tools (lag order, factor number)"
di "    2. Panel cointegration tests (JO, CAIN)"
di "    3. Individual cointegration tests"
di "    4. Panel VAR estimation (Mean Group)"
di "    5. Panel VECM estimation"
di "    6. Impulse response functions"
di "    7. Forecast error variance decomposition"
di
di "  For bootstrap inference, use:"
di "    xtpvarcoint sboot, method(pmb) nboot(500) horizon(20)"
di
di "  For SVAR identification, use:"
di "    xtpvarcoint pid, method(chol)"
di "    xtpvarcoint pid, method(grt)"
di "    xtpvarcoint pid, method(dc) combine(pool)"
di
di "  For plots, use:"
di "    xtpvarcoint plot, plottype(irf)"
di "    xtpvarcoint plot, plottype(fevd)"
di "    xtpvarcoint plot, plottype(eigenvalues)"
di
di "{hline 78}"
di "  Dr Merwan Roudane — merwanroudane920@gmail.com"
di "{hline 78}"
