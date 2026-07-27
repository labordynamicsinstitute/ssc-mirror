*! xtpdcause_example.do  23jul2026
*! Demonstration of xtpdcause (factor-corrected panel Granger causality)
*! Author: Dr Merwan Roudane

clear all
set more off

* --- simulate a strongly balanced panel with a common factor + causality ---
set seed 20260723
local N 20
local T 96
set obs `=`N'*`T''
egen id = seq(), block(`T')
by id, sort: gen t = _n
xtset id t

* common global factor
by id: gen double f = sum(rnormal())
gen double gdp    = .
gen double export = .
by id: replace gdp    = sum(0.4*(f-f[_n-1]) + rnormal())          if _n>1
by id: replace export = sum(0.5*(f-f[_n-1]) + 0.3*(gdp[_n-1]-gdp[_n-2]) + rnormal()) if _n>2
by id: replace gdp    = 0 if _n==1
by id: replace export = 0 if _n<=2

* --- PANIC-corrected causality (both directions) ------------------------
xtpdcause gdp export, method(panic)
matrix list r(units)
xtpdcause export gdp, method(panic)

* --- cross-section-average correction and no correction -----------------
xtpdcause export gdp, method(panicca)
xtpdcause export gdp, method(none)
