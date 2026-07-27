*! xtfaclm_example.do  23jul2026
*! Demonstration of xtfaclm (factor-augmented two-break panel LM unit-root test)
*! Author: Dr Merwan Roudane

clear all
set more off

* --- simulate a factor-structured panel with two breaks --------------------
set seed 20260723
local N 25
local T 40
set obs `=`N'*`T''
egen id = seq(), block(`T')
by id, sort: gen t = _n
xtset id t

* one common factor (random walk) + unit-specific breaks
by id: gen double f = sum(rnormal())
gen double y = .
by id: replace y = sum(0.5*(f-f[_n-1]) + rnormal()) if _n>1
by id: replace y = 0 if _n==1
* add two level breaks per unit
by id: replace y = y + 2*(t>=15) - 1.5*(t>=28)

* --- factor-augmented two-break panel LM (level breaks) --------------------
xtfaclm y, model(constant)
matrix list r(units)

* --- level & trend breaks, and a fixed factor count ------------------------
xtfaclm y, model(trend)
xtfaclm y, model(constant) factors(1)
