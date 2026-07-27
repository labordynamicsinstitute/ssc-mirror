*! ffrals_example.do  23jul2026
*! Demonstration of ffrals (flexible-Fourier RALS LM unit-root test)
*! Author: Dr Merwan Roudane

clear all
set more off

* --- simulate a trend-stationary series with a smooth break + non-normal errors
set seed 20260723
set obs 120
gen t = _n
tsset t
gen double e = rchi2(3) - 3                     // skewed (non-normal) errors
gen double y = 5 + 0.02*t + 1.5*sin(2*_pi*1*t/120) + e

* --- plain flexible-Fourier LM, then RALS ------------------------------
ffrals y, rals(0)
ffrals y, rals(1)

* --- more Monte-Carlo replications for a smoother p-value ---------------
ffrals y, rals(1) nsim(100000)

* --- a genuine random walk (should NOT reject) -------------------------
gen double rw = sum(rnormal())
ffrals rw, rals(1)
