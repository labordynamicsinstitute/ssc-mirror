*! boundeduroot_selftest.do  --  install + exercise every module, export figures
clear all
set more off
capture ado uninstall boundeduroot
net install boundeduroot, from("C:/Users/HP/Documents/xtpmg/boundeduroot") replace
which boundeduroot
which boundeduroot_mtests
which boundeduroot_breaks
which boundeduroot_hlt

*--- mtests -------------------------------------------------------------------
clear
set seed 12345
set obs 200
gen t = _n
tsset t
gen y = 50 in 1
forvalues i = 2/200 {
    qui replace y = y[`i'-1] + rnormal(0,3) in `i'
    qui replace y = 0 in `i' if y[`i']<0
    qui replace y = 100 in `i' if y[`i']>100
}
di as text _n ">>>>> MTESTS"
boundeduroot mtests y, lbound(0) ubound(100) iter(400) gname(mt)
graph export "C:/Users/HP/Documents/xtpmg/boundeduroot/_fig_mtests.png", replace width(1400)

*--- breaks -------------------------------------------------------------------
clear
set seed 321
set obs 240
gen t = _n
tsset t
gen y = 30 in 1
forvalues i = 2/240 {
    qui replace y = y[`i'-1] + rnormal(0,3) in `i'
    qui replace y = 0 in `i' if y[`i']<0
    qui replace y = 100 in `i' if y[`i']>100
}
qui replace y = y + 35 if t>=120
qui replace y = 100 if y>100
di as text _n ">>>>> BREAKS"
boundeduroot breaks y, lbound(0) ubound(100) iter(400) gname(bk)
graph export "C:/Users/HP/Documents/xtpmg/boundeduroot/_fig_breaks.png", replace width(1400)

*--- hlt ----------------------------------------------------------------------
clear
set seed 77
set obs 200
gen t = _n
tsset t
gen y = 5 in 1
forvalues i = 2/200 {
    qui replace y = 5 + 0.5*(y[`i'-1]-5) + rnormal(0,1.5) in `i'
    qui replace y = 2 in `i' if y[`i']<2
    qui replace y = 20 in `i' if y[`i']>20
}
qui replace y = y + 9 if t>=100
qui replace y = 20 if y>20
di as text _n ">>>>> HLT"
boundeduroot hlt y, lbound(2) ubound(20) iter(300) gname(hl)
graph export "C:/Users/HP/Documents/xtpmg/boundeduroot/_fig_hlt.png", replace width(1400)

di as result _n ">>> BOUNDEDUROOT SELFTEST COMPLETE"
