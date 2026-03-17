*! ivlpirf2 — Example do-file
*! Version 1.0.0  15mar2026
*! Author: Dr. Merwan Roudane

/* ═══════════════════════════════════════════════════════════
   Example 1: Basic Time-Series IV Local Projection IRF
   ═══════════════════════════════════════════════════════════ */

* Load Lütkepohl's macroeconomic dataset
webuse lutkepohl2, clear
tsset

* Estimate IRF: response of investment and consumption
* to an income shock, instrumented by its own lags
ivlpirf2 dln_inv dln_consump, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(8) graph


/* ═══════════════════════════════════════════════════════════
   Example 2: With First-Stage Diagnostics
   ═══════════════════════════════════════════════════════════ */

* Check instrument strength
ivlpirf2 dln_inv, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(8) firststage graph


/* ═══════════════════════════════════════════════════════════
   Example 3: Cumulative IRF
   ═══════════════════════════════════════════════════════════ */

* Cumulative response (sum of IRF from 0 to h)
ivlpirf2 dln_inv, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(8) cumulative graph


/* ═══════════════════════════════════════════════════════════
   Example 4: HAC Standard Errors (Newey-West)
   ═══════════════════════════════════════════════════════════ */

ivlpirf2 dln_inv, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(8) vce(hac nw 4) graph


/* ═══════════════════════════════════════════════════════════
   Example 5: Simulated Panel Data with Driscoll-Kraay
   ═══════════════════════════════════════════════════════════ */

* Generate simulated panel data
clear
set seed 42
local N_units 30
local T_periods 50
set obs `= `N_units' * `T_periods''

* Panel structure
gen unit = ceil(_n / `T_periods')
bysort unit: gen period = _n
xtset unit period

* Generate common shock (cross-sectionally dependent)
bysort period: gen common_shock = rnormal() if _n == 1
bysort period: replace common_shock = common_shock[1]

* Generate instrument (correlated with shock, not with error)
gen z = 0.6 * common_shock + 0.4 * rnormal()

* Generate endogenous impulse (driven by shock + endogeneity)
gen x = 0.5 * z + 0.3 * common_shock + rnormal()

* Generate response with dynamic effects
gen y = 0
replace y = 0.8 * x + rnormal() if period == 1
replace y = 0.6 * L.y + 0.8 * x - 0.3 * L.x + rnormal() if period > 1

* Estimate with Driscoll-Kraay standard errors
ivlpirf2 D.y, ///
	endogenous(x = z) ///
	vce(dkraay) fe ///
	step(6) graph ///
	firststage ///
	title("Response of GDP growth to shock (DK inference)")


/* ═══════════════════════════════════════════════════════════
   Example 6: Panel with Cluster-Robust SEs (for comparison)
   ═══════════════════════════════════════════════════════════ */

ivlpirf2 D.y, ///
	endogenous(x = z) ///
	vce(cluster unit) fe ///
	step(6) graph ///
	title("Response of GDP growth (cluster-robust)")


/* ═══════════════════════════════════════════════════════════
   Example 7: Custom Confidence Levels
   ═══════════════════════════════════════════════════════════ */

ivlpirf2 dln_inv, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(8) graph level(90 95)


/* ═══════════════════════════════════════════════════════════
   Example 8: Suppress Table, Show Only Graph
   ═══════════════════════════════════════════════════════════ */

webuse lutkepohl2, clear
tsset

ivlpirf2 dln_inv dln_consump, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(12) notable graph ///
	title("Structural IRF: Income shock")


/* ═══════════════════════════════════════════════════════════
   Example 9: Accessing Stored Results
   ═══════════════════════════════════════════════════════════ */

ivlpirf2 dln_inv, ///
	endogenous(dln_inc = L(2/4).dln_inc) ///
	step(4) notable

* Display stored IRF coefficients
matrix list e(irf_b), title("IRF coefficients")
matrix list e(irf_se), title("IRF standard errors")
display "Number of obs: " e(N)
display "VCE type: " e(vce)
