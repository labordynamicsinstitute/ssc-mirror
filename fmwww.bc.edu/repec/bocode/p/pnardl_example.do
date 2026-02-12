********************************************************************************
* pnardl: Panel Nonlinear ARDL — Example Do-File
* Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
* Date: 11 February 2026
*
* This example demonstrates the full Panel NARDL workflow using the 
* pnardl command with simulated data.
*
* Reference: Shin, Yu and Greenwood-Nimmo (2014)
*            "Modelling Asymmetric Cointegration and Dynamic Multipliers 
*             in a Nonlinear ARDL Framework"
********************************************************************************

clear all
set more off

* ==============================================================================
* 1. INSTALL REQUIRED PACKAGES
* ==============================================================================

* Install xtpmg (version 2.0.0 required for Stata 15+ compatibility)
* ssc install xtpmg, replace

* ==============================================================================
* 2. LOAD AND PREPARE DATA
* ==============================================================================

* Set your panel data (replace with your actual data)
* use "your_data.dta", clear
* xtset id year

* --- Example with simulated data ---
* (Replace this block with your actual data loading)

set seed 12345
set obs 500

* Create panel structure: 10 countries, 50 periods
gen id = ceil(_n/50)
bysort id: gen year = _n + 1970
xtset id year

* Generate simulated variables
gen x1 = rnormal(0, 1)
gen x2 = rnormal(0, 1)
gen y = 0.5*x1 - 0.3*x2 + rnormal(0, 0.5)

* Add persistence (make it look like real macro data)
sort id year
by id: replace y = 0.7*l.y + 0.3*x1 - 0.2*x2 + rnormal(0,0.3) if _n > 1
by id: replace x1 = 0.8*l.x1 + rnormal(0,0.3) if _n > 1
by id: replace x2 = 0.85*l.x2 + rnormal(0,0.3) if _n > 1

* ==============================================================================
* 3. BASIC PANEL NARDL — PMG (default)
* ==============================================================================

* Decompose x1 into positive and negative shocks, estimate PMG
pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) replace

* ==============================================================================
* 4. MEAN GROUP ESTIMATION
* ==============================================================================

* Same with MG estimator
pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) mg replace

* ==============================================================================
* 5. PMG WITH HAUSMAN TEST
* ==============================================================================

* PMG with Hausman test to compare MG vs PMG
pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) pmg hausman replace

* ==============================================================================
* 6. MULTIPLE ASYMMETRIC VARIABLES
* ==============================================================================

* Both x1 and x2 decomposed asymmetrically
pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1 x2) replace

* ==============================================================================
* 7. DFE ESTIMATION (no asymmetry tests)
* ==============================================================================

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) dfe noasymtest replace

* ==============================================================================
* 8. MANUAL APPROACH (for comparison / understanding)
* ==============================================================================
* This shows what pnardl does internally:

* Step 1: Generate partial sums manually
capture drop x1_pos x1_neg
gen dx1 = d.x1
gen dx1_pos = max(dx1, 0) if dx1 != .
gen dx1_neg = min(dx1, 0) if dx1 != .
replace dx1_pos = 0 if dx1_pos == .
replace dx1_neg = 0 if dx1_neg == .
sort id year
bysort id: gen x1_pos = sum(dx1_pos)
bysort id: gen x1_neg = sum(dx1_neg)

* Step 2: Estimate with xtpmg directly
capture drop ECT
xtpmg d.y d.x1_pos d.x1_neg d.x2, lr(l.y x1_pos x1_neg x2) pmg replace
estimates store PMG

* Step 3: Test long-run asymmetry
test [ECT]x1_pos = [ECT]x1_neg

* Step 4: Test short-run asymmetry
test [SR]d.x1_pos = [SR]d.x1_neg

* Clean up
drop dx1 dx1_pos dx1_neg x1_pos x1_neg

********************************************************************************
* END OF EXAMPLE
********************************************************************************
