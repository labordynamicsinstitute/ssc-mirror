*! xtfpanic_example.do  23jul2026
*! Demonstration of xtfpanic (Fourier-PANIC panel unit-root test)
*! Author: Dr Merwan Roudane

clear all
set more off

* --- simulate a factor-structured panel with a common smooth break ---------
set seed 20260723
local N 15
local T 60
set obs `=`N'*`T''
egen id = seq(), block(`T')
by id, sort: gen t = _n
xtset id t

* one common factor (random walk) + a shared gradual (Fourier) break
by id: gen double f = sum(rnormal())
gen double y = .
by id: replace y = sum(0.5*(f-f[_n-1]) + rnormal()) if _n>1
by id: replace y = 0 if _n==1
replace y = y + 1.5*sin(2*_pi*1*t/`T')

* --- Fourier-PANIC, single frequency then cumulative frequencies 1 and 2 ---
xtfpanic y, freq(1)
xtfpanic y, freq(2)

* --- change the max factors and the lag settings ---------------------------
xtfpanic y, freq(1) kmax(3) pmax(5)
