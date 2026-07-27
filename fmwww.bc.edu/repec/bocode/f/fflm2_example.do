*! fflm2_example.do  23jul2026
*! Demonstration of fflm2 (two-break LM with RALS)
*! Author: Dr Merwan Roudane
clear all
set seed 20260723
set obs 120
gen t = _n
tsset t
gen double e = rchi2(3) - 3
gen double y = sum(rnormal()) + 3*(t>=40) - 2*(t>=80) + 0.3*e
fflm2 y, rals(0)
fflm2 y, rals(1)
