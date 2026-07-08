*! boundedur_examples.do  --  worked examples for boundedur v2.0.0
*! Cavaliere & Xu (2014) bounded unit-root tests
*! Merwan Roudane -- merwanroudane920@gmail.com

clear all
set more off

*-----------------------------------------------------------------------------
* Example 1.  A bounded RANDOM WALK in [0,100] (a bounded unit root).
*             The tests should FAIL TO REJECT the unit-root null.
*-----------------------------------------------------------------------------
set seed 12345
set obs 250
gen t = _n
tsset t
gen y = 50 in 1
forvalues i = 2/250 {
    qui replace y = y[`i'-1] + rnormal(0,3) in `i'
    qui replace y = 0   in `i' if y[`i'] < 0
    qui replace y = 100 in `i' if y[`i'] > 100
}
boundedur y, lbound(0) ubound(100)
* -> examine r(results), r(c_lower), r(c_upper)

*-----------------------------------------------------------------------------
* Example 2.  A bounded STATIONARY series. The tests should REJECT.
*-----------------------------------------------------------------------------
clear
set seed 6789
set obs 250
gen t = _n
tsset t
gen y = 50 in 1
forvalues i = 2/250 {
    qui replace y = 50 + 0.3*(y[`i'-1]-50) + rnormal(0,5) in `i'
    qui replace y = 0   in `i' if y[`i'] < 0
    qui replace y = 100 in `i' if y[`i'] > 100
}
boundedur y, lbound(0) ubound(100) nograph

*-----------------------------------------------------------------------------
* Example 3.  One-sided lower bound (e.g. a nominal interest rate >= 0),
*             GLS de-meaning, re-colouring, only the MSB test, reproducible.
*-----------------------------------------------------------------------------
boundedur cx y, lbound(0) detrend(gls) recolor test(msb) seed(101) nograph

*-----------------------------------------------------------------------------
* Example 4.  Fix the lag, raise simulation accuracy, keep the null draws.
*-----------------------------------------------------------------------------
boundedur y, lbound(0) ubound(100) lags(2) nsim(1999) savesim(nulldraw) nograph
summarize nulldraw1 nulldraw2 nulldraw3

* help boundedur   // full documentation and roadmap
