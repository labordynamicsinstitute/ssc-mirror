*! xtpanicsb_example.do  23jul2026
*! Demonstration of xtpanicsb (PANIC panel unit-root test with sharp breaks)
*! Author: Dr Merwan Roudane

clear all
set more off

* --- simulate a factor-structured panel with two sharp breaks --------------
set seed 20260723
local N 20
local T 49
set obs `=`N'*`T''
egen id = seq(), block(`T')
by id, sort: gen t = _n
xtset id t

* one common factor (random walk) + unit-specific level & trend breaks
by id: gen double f = sum(rnormal())
gen double y = .
by id: replace y = sum(0.5*(f-f[_n-1]) + rnormal()) if _n>1
by id: replace y = 0 if _n==1
by id: replace y = y + 3*(t>=17) - 2*(t>=34)

* --- sharp-break PANIC, two level & trend breaks ---------------------------
xtpanicsb y, model(trend) breaks(2) kmax(2)
matrix list r(units)

* --- level breaks only, one factor imposed ---------------------------------
xtpanicsb y, model(constant) breaks(2) factors(1)
