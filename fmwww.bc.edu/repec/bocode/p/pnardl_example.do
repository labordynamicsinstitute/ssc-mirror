* =========================================================================
* pnardl_example.do — Panel NARDL Examples (Version 1.1.0)
* Dr Merwan Roudane — merwanroudane920@gmail.com
* =========================================================================

clear all
set more off
discard

* =========================================================================
* 1. SIMULATE PANEL DATA
* =========================================================================

set seed 12345
set obs 300

* 10 panels, 30 time periods each
gen id = ceil(_n / 30)
bys id: gen year = 2000 + _n - 1
xtset id year

* Generate variables with asymmetric relationship
gen x1 = rnormal(0, 2) if year == 2000
bys id: replace x1 = x1[_n-1] + rnormal(0, 1.5) if _n > 1

gen x2 = rnormal(0, 1) if year == 2000
bys id: replace x2 = x2[_n-1] + rnormal(0, 0.8) if _n > 1

* y has asymmetric response to x1: positive changes = stronger effect
gen y = 0 if year == 2000
gen _dx1_pos = max(d.x1, 0) if year > 2000
gen _dx1_neg = min(d.x1, 0) if year > 2000
replace _dx1_pos = 0 if _dx1_pos == .
replace _dx1_neg = 0 if _dx1_neg == .

bys id: replace y = 0.85 * y[_n-1] + 0.7 * _dx1_pos + 0.3 * _dx1_neg ///
    + 0.4 * d.x2 + rnormal(0, 0.5) if _n > 1

drop _dx1_pos _dx1_neg

di ""
di "============================================"
di "  Panel NARDL Examples — Version 1.1.0"
di "============================================"
di ""


* =========================================================================
* 2. BASIC PNARDL ESTIMATION
* =========================================================================

di ""
di ">>> Example 1: Basic Panel NARDL (PMG)"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) replace


* =========================================================================
* 3. WITH ASYMMETRY TABLE
* =========================================================================

di ""
di ">>> Example 2: With asymmetry comparison table"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) asytable replace


* =========================================================================
* 4. PER-PANEL COEFFICIENTS
* =========================================================================

di ""
di ">>> Example 3: Per-panel coefficients"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) panelcoef replace


* =========================================================================
* 5. DYNAMIC MULTIPLIERS
* =========================================================================

di ""
di ">>> Example 4: Dynamic multipliers (20 periods)"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) multip(20) replace


* =========================================================================
* 6. IRF FOR POSITIVE VS NEGATIVE SHOCKS
* =========================================================================

di ""
di ">>> Example 5: IRF for positive vs negative shocks"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) irfshock(15) replace


* =========================================================================
* 7. FULL ANALYSIS WITH GRAPHS
* =========================================================================

di ""
di ">>> Example 6: Complete analysis with all diagnostics + graphs"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) ///
    asymmetric(x1) ///
    asytable panelcoef multip(20) irfshock(20) ///
    graph full replace

* Export graphs
capture graph export pnardl_ect.png, name(pnardl_ect) replace width(1200)
capture graph export pnardl_asym_lr.png, name(pnardl_asym_lr) replace width(1200)
capture graph export pnardl_multiplier.png, name(pnardl_multiplier) replace width(1200)


* =========================================================================
* 8. MULTIPLE ASYMMETRIC VARIABLES
* =========================================================================

di ""
di ">>> Example 7: Multiple asymmetric variables"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) ///
    asymmetric(x1 x2) asytable multip(15) replace


* =========================================================================
* 9. HAUSMAN TEST
* =========================================================================

di ""
di ">>> Example 8: With Hausman test"
di ""

pnardl d.y d.x1 d.x2, lr(l.y x1 x2) ///
    asymmetric(x1) hausman asytable replace


di ""
di "============================================"
di "  All examples completed successfully!"
di "============================================"
