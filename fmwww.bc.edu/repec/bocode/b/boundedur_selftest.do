*! boundedur_selftest.do  --  compile + smoke test of boundedur v2.0.0
clear all
set more off
adopath ++ "C:/Users/HP/Documents/boundedur_corrected"
discard
which boundedur

*--- 1. A bounded UNIT-ROOT series in [0,100] (H0 true) -----------------------
clear
set seed 12345
set obs 300
gen t = _n
tsset t
gen y = 50 in 1
* reflected random walk between 0 and 100
forvalues i = 2/300 {
    qui replace y = y[`i'-1] + rnormal(0,3) in `i'
    qui replace y = 0   in `i' if y[`i'] < 0
    qui replace y = 100 in `i' if y[`i'] > 100
}
di as text _n "==================  BOUNDED UNIT ROOT (expect: fail to reject)  =================="
boundedur y, lbound(0) ubound(100) nsim(299) nograph
matrix list r(results)
di as text "returned c_lower=" r(c_lower) "  c_upper=" r(c_upper) "  lags=" r(lags)

*--- 2. A bounded STATIONARY series (H0 false, expect reject) -----------------
clear
set seed 6789
set obs 300
gen t = _n
tsset t
gen y = 50 in 1
forvalues i = 2/300 {
    qui replace y = 50 + 0.3*(y[`i'-1]-50) + rnormal(0,5) in `i'
    qui replace y = 0   in `i' if y[`i'] < 0
    qui replace y = 100 in `i' if y[`i'] > 100
}
di as text _n "==================  BOUNDED STATIONARY (expect: reject H0)  =================="
boundedur y, lbound(0) ubound(100) nsim(299) nograph

*--- 3. one-sided lower bound + GLS detrend + recolor + explicit cx -----------
di as text _n "==================  ONE-SIDED + GLS + RECOLOR  =================="
boundedur cx y, lbound(0) detrend(gls) recolor nsim(199) nograph
di as text _n "==================  MTESTS STUB (expect informative error)  =================="
capture noisily boundedur mtests y, lbound(0) ubound(100)

di as result _n ">>> SELFTEST COMPLETE"
