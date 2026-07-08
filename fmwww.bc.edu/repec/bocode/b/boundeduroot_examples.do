*! boundeduroot_examples.do  --  worked examples for the boundeduroot library
*! Carrion-i-Silvestre & Gadea bounded tests (mtests 2013, breaks 2016, hlt 2024)
*! Merwan Roudane -- merwanroudane920@gmail.com

clear all
set more off

*-----------------------------------------------------------------------------
* A bounded RANDOM WALK in [0,100] (a bounded unit root)
*-----------------------------------------------------------------------------
set seed 12345
set obs 220
gen t = _n
tsset t
gen y = 50 in 1
forvalues i = 2/220 {
    qui replace y = y[`i'-1] + rnormal(0,3) in `i'
    qui replace y = 0   in `i' if y[`i'] < 0
    qui replace y = 100 in `i' if y[`i'] > 100
}

* GLS M-tests (Carrion-i-Silvestre & Gadea 2013)
boundeduroot mtests y, lbound(0) ubound(100)

*-----------------------------------------------------------------------------
* A bounded random walk with a LEVEL SHIFT (still a unit root, with a break)
*-----------------------------------------------------------------------------
clear
set seed 321
set obs 240
gen t = _n
tsset t
gen y = 30 in 1
forvalues i = 2/240 {
    qui replace y = y[`i'-1] + rnormal(0,3) in `i'
    qui replace y = 0   in `i' if y[`i'] < 0
    qui replace y = 100 in `i' if y[`i'] > 100
}
qui replace y = y + 35 if t >= 120
qui replace y = 100 if y > 100

* bounded unit-root tests allowing 0/1/2 breaks (Carrion-i-Silvestre & Gadea 2016)
boundeduroot breaks y, lbound(0) ubound(100)

*-----------------------------------------------------------------------------
* A bounded STATIONARY series with a genuine level shift
*-----------------------------------------------------------------------------
clear
set seed 77
set obs 200
gen t = _n
tsset t
gen y = 5 in 1
forvalues i = 2/200 {
    qui replace y = 5 + 0.5*(y[`i'-1]-5) + rnormal(0,1.5) in `i'
    qui replace y = 2  in `i' if y[`i'] < 2
    qui replace y = 20 in `i' if y[`i'] > 20
}
qui replace y = y + 9 if t >= 100
qui replace y = 20 if y > 20

* multiple level-shift detection (Carrion-i-Silvestre & Gadea 2024)
boundeduroot hlt y, lbound(2) ubound(20) iter(400)

* help boundeduroot
