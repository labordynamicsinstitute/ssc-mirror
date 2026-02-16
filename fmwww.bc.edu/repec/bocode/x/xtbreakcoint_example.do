*! xtbreakcoint_example.do
*! Example do-file using Banerjee & Carrion-i-Silvestre (2015) replication data
*! Data: European import prices, foreign prices, exchange rates
*! 10 countries, 9 sectors, monthly 1995m1-2005m3
*!
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.1 — 13 February 2026

clear all
set more off

* ============================================================
* STEP 1: Load the replication data (sector 0)
* ============================================================

* The xlsx was created from the original GAUSS data files
import excel "xtbreakcoint_example.xlsx", sheet("sector0") firstrow clear

* Create panel identifiers
encode country, gen(id)
xtset id t

* Describe the data
describe
xtsum lpm lfp lexrate

* ============================================================
* STEP 2: Basic cointegration test (Model 4 = trendshift)
*         This matches the GAUSS code: model=4|1, k=12|1
* ============================================================

di _n "{hline 78}"
di "{bf:Test 1: Trend shift model (default, matching GAUSS model=4)}"
di "{hline 78}"

xtbreakcoint lpm lfp lexrate, model(trendshift) maxlag(12)

* Store results for comparison
local Zt_m4 = r(Z_t)
local pv_m4 = r(p_value)
local nf_m4 = r(nfactors)

di _n "Results: Z_t = " %8.4f `Zt_m4' ", p = " %6.4f `pv_m4' ", factors = " `nf_m4'

* ============================================================
* STEP 3: Constant model (Model 1, no breaks)
* ============================================================

di _n "{hline 78}"
di "{bf:Test 2: Constant model (no breaks)}"
di "{hline 78}"

xtbreakcoint lpm lfp lexrate, model(constant) maxlag(12)

* ============================================================
* STEP 4: Level shift model (Model 3)
* ============================================================

di _n "{hline 78}"
di "{bf:Test 3: Level shift model}"
di "{hline 78}"

xtbreakcoint lpm lfp lexrate, model(levelshift) maxlag(12)

* ============================================================
* STEP 5: Regime shift model (Model 5) with graph
* ============================================================

di _n "{hline 78}"
di "{bf:Test 4: Regime shift model with graph}"
di "{hline 78}"

xtbreakcoint lpm lfp lexrate, model(regimeshift) maxlag(12) graph

* ============================================================
* STEP 6: No factor estimation (for comparison)
* ============================================================

di _n "{hline 78}"
di "{bf:Test 5: Trendshift without factor estimation}"
di "{hline 78}"

xtbreakcoint lpm lfp lexrate, model(trendshift) maxlag(12) nofactor

* ============================================================
* STEP 7: Access stored results
* ============================================================

di _n "{hline 78}"
di "{bf:Stored Results from Last Estimation}"
di "{hline 78}"

di "Panel Z_t:           " %9.4f r(Z_t)
di "P-value:             " %9.4f r(p_value)
di "Average t-ADF:       " %9.4f r(tbar)
di "E[t] under H0:       " %9.4f r(mean_t)
di "Var[t] under H0:     " %9.4f r(var_t)
di "N (panels):          " r(N)
di "T (periods):         " r(T)
di "Common factors:      " r(nfactors)
di "MQ_np (stat):        " %9.4f r(MQ_np)
di "Stochastic trends:   " r(n_trends) " (non-parametric)"
di "MQ_p (stat):         " %9.4f r(MQ_p)
di "Stochastic trends:   " r(n_trends_p) " (parametric)"
di "Rejection rate (%):  " %5.1f r(reject_pct)
di "Iterations:          " r(iterations)

* Individual ADF statistics
mat list r(adf), title("Individual ADF Statistics")

* Selected lag orders
mat list r(lags), title("Selected Lag Orders")

* Estimated break dates
mat list r(breaks), title("Estimated Break Dates (index)")

* ============================================================
* NOTE: For cross-section dependence testing, use existing
* Stata commands AFTER running xtbreakcoint:
*
*   . xtcsd, pesaran      (Pesaran 2004 CD test)
*   . ssc install xtcd2   (if not installed)
*   . xtcd2               (Pesaran 2015 weak CD test)
*
* For panel DOLS estimation, use:
*   . ssc install xtpedroni
*   . xtpedroni lpm lfp lexrate
* ============================================================

di _n "{bf:Example complete.}"
