*! ffadf_example.do  23jul2026
*! Demonstration of ffadf (flexible-Fourier ADF with RALS)
*! Author: Dr Merwan Roudane
clear all
set seed 20260723
set obs 120
gen t = _n
tsset t
gen double e = rchi2(3) - 3
gen double y = 5 + 0.02*t + 1.5*sin(2*_pi*1*t/120) + e
ffadf y, rals(0) det(2)
ffadf y, rals(1) det(2)
gen double rw = sum(rnormal())
ffadf rw, rals(1)
