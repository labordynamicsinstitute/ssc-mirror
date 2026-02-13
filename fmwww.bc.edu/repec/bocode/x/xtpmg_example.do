********************************************************************************
* xtpmg 2.0.1: Complete Example — All New Features
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
* Date: 12 February 2026
*
* This example demonstrates the full XTPMG 2.0.1 workflow:
*   1. Automatic lag selection (AIC/BIC)
*   2. PMG estimation with ARDL order display
*   3. Per-panel short-run coefficient table
*   4. Half-life of adjustment computation
*   5. Impulse response simulation
********************************************************************************

clear all
set more off

* ==============================================================================
* 1. GENERATE SIMULATED PANEL DATA
* ==============================================================================

* 10 countries, 50 time periods
set seed 54321
set obs 500

gen id = ceil(_n/50)
bysort id: gen year = _n + 1970
xtset id year

* Generate I(1) variables with cointegrating relationship
* True DGP: y = 0.5*x1 + 0.3*x2 + u (long-run)
* With error correction speed ~ -0.3

gen x1 = 0
gen x2 = 0
gen y  = 0

sort id year

* Generate random walks for x1 and x2
by id: replace x1 = rnormal(0, 0.5) if _n == 1
by id: replace x1 = l.x1 + rnormal(0, 0.5) if _n > 1
by id: replace x2 = rnormal(0, 0.3) if _n == 1
by id: replace x2 = l.x2 + rnormal(0, 0.3) if _n > 1

* Generate y with error correction mechanism
by id: replace y = 0.5*x1 + 0.3*x2 + rnormal(0, 0.5) if _n == 1
by id: replace y = l.y - 0.3*(l.y - 0.5*l.x1 - 0.3*l.x2) ///
	+ 0.2*d.x1 + 0.1*d.x2 + rnormal(0, 0.2) if _n > 1

label variable y  "Dependent variable (GDP)"
label variable x1 "Independent variable 1 (Investment)"
label variable x2 "Independent variable 2 (Trade)"

* ==============================================================================
* 2. BASIC PMG ESTIMATION (as before)
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 1: Basic PMG Estimation"
di "============================================================"

xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) pmg replace


* ==============================================================================
* 3. PMG WITH LAG SELECTION (NEW in 2.0.1)
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 2: PMG with Automatic Lag Selection (AIC)"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) maxlag(4) lagsel(aic) pmg replace


* ==============================================================================
* 4. PMG WITH BOTH AIC AND BIC
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 3: PMG with AIC & BIC Comparison"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) maxlag(4) lagsel(both) pmg replace


* ==============================================================================
* 5. PMG WITH SHORT-RUN TABLE (NEW in 2.0.1)
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 4: PMG with Per-Panel Short-Run Table"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) pmg srtable full replace


* ==============================================================================
* 6. PMG WITH HALF-LIFE (NEW in 2.0.1)
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 5: PMG with Half-Life of Adjustment"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) pmg halflife full replace


* ==============================================================================
* 7. PMG WITH IMPULSE RESPONSE (NEW in 2.0.1)
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 6: PMG with Impulse Response (20 periods)"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) pmg irf(20) full replace


* ==============================================================================
* 8. FULL ANALYSIS — ALL FEATURES COMBINED
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 7: Full Analysis — All New Features"
di "============================================================"
di "  This demonstrates the complete researcher workflow:"
di "  lag selection + estimation + SR table + half-life + IRF"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) ///
	maxlag(4) lagsel(both) ///
	srtable halflife irf(15) ///
	pmg full replace


* ==============================================================================
* 9. MEAN GROUP WITH DIAGNOSTICS
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 8: Mean Group (MG) Estimation"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) mg replace


* ==============================================================================
* 10. DFE ESTIMATION
* ==============================================================================

di _n(3)
di "============================================================"
di "  EXAMPLE 9: Dynamic Fixed Effects (DFE)"
di "============================================================"

capture drop ECT
xtpmg d.y d.x1 d.x2, lr(l.y x1 x2) fe replace


********************************************************************************
* END OF EXAMPLES
********************************************************************************

di _n(3)
di "============================================================"
di "  All examples completed successfully!"
di "  XTPMG version 2.0.1 — Dr Merwan Roudane"
di "============================================================"
