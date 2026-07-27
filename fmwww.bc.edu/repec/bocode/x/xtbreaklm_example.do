*! xtbreaklm_example.do  23jul2026
*! Demonstration of xtbreaklm (panel LM unit-root tests with breaks)
*! Author: Dr Merwan Roudane

clear all
set more off

* --- simulate a strongly balanced panel with a smooth break --------------
set seed 20260723
local N 12
local T 60
set obs `=`N'*`T''
egen id   = seq(), block(`T')
by id, sort: gen t = _n
xtset id t

* unit-root panels with a common gradual level shift
gen double y = .
by id: replace y = sum(rnormal()) + 2*(1/(1+exp(-0.3*(t-30))))

* --- Enders-Lee smooth-break panel LM ------------------------------------
xtbreaklm y, type(fourier) nharm(1) pmax(3)
matrix list r(units)

* add the second Fourier harmonic
xtbreaklm y, type(fourier) nharm(2) pmax(3)

* --- Lee-Tieslau two sharp breaks ----------------------------------------
xtbreaklm y, type(sharp) pmax(3)
matrix list r(units)
