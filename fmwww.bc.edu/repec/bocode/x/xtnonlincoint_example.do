*! xtnonlincoint_example.do  -- self-test / demonstration
*! Merwan Roudane  (merwanroudane920@gmail.com)
*!
*! Exercises every code path of xtnonlincoint on a simulated balanced panel:
*!   - a COINTEGRATED design (the tests should reject H0 -> cointegration)
*!   - a NON-cointegrated design (the tests should not reject)
*! in standalone (ecm, fffff) and combined (all) forms, with options and graphs.
*!
*! If a Mata block fails to compile, run  do xtnonlincoint.ado  directly to see
*! the exact offending line.

clear all
set more off
version 14.0

*-----------------------------------------------------------------------------
* 1. Cointegrated panel:  y = x + stationary error  (=> cointegration, power)
*-----------------------------------------------------------------------------
clear
set seed 20260621
local N = 10
local T = 60
set obs `=`N'*`T''
egen id = seq(), from(1) to(`N') block(`T')
bysort id: gen t = _n
xtset id t

* random-walk regressor
gen double ex = rnormal()
bysort id (t): gen double x = sum(ex)

* stationary AR(1) equilibrium error
gen double eu = rnormal()
bysort id (t): gen double u = eu
bysort id (t): replace u = 0.6*L.u + eu if t>1

* cointegrated dependent variable
gen double y = 1 + x + u

di as txt _n "{hline 70}"
di as txt "DESIGN A: cointegrated panel (expect rejection of H0)"
di as txt "{hline 70}"

* --- ECM test, default ---
xtnonlincoint ecm y x
di as txt "ECM group stat = " as res r(stat) as txt "  p = " as res r(p)
matrix list r(indstat)

* --- ECM test, more lags + detrended + graph ---
xtnonlincoint ecm y x, lags(2) varlags(2) trend breps(199) seed(7) graph

* --- FFFFF test, default ---
xtnonlincoint fffff y x
di as txt "FFFFF group stat = " as res r(stat) as txt "  p = " as res r(p)

* --- FFFFF test, SPSM + graph + finer grid ---
xtnonlincoint fffff y x, maxlags(2) kstep(0.2) spsm graph
matrix list r(spsm)

* --- both at once ---
xtnonlincoint all y x, breps(199) seed(99) spsm

* --- noprint returns-only path ---
xtnonlincoint ecm y x, noprint
di as txt "silent ECM p-value = " as res r(p)

*-----------------------------------------------------------------------------
* 2. Non-cointegrated panel: two independent random walks (expect no rejection)
*-----------------------------------------------------------------------------
clear
set seed 1234
local N = 8
local T = 50
set obs `=`N'*`T''
egen id = seq(), from(1) to(`N') block(`T')
bysort id: gen t = _n
xtset id t
gen double ey = rnormal()
gen double ex = rnormal()
bysort id (t): gen double y = sum(ey)
bysort id (t): gen double x = sum(ex)

di as txt _n "{hline 70}"
di as txt "DESIGN B: independent random walks (expect non-rejection)"
di as txt "{hline 70}"

xtnonlincoint ecm y x, breps(199)
xtnonlincoint fffff y x, breps(199) spsm

*-----------------------------------------------------------------------------
* 3. Multiple regressors + unbalanced-panel error check
*-----------------------------------------------------------------------------
clear
set seed 55
local N = 6
local T = 55
set obs `=`N'*`T''
egen id = seq(), from(1) to(`N') block(`T')
bysort id: gen t = _n
xtset id t
gen double e1 = rnormal()
gen double e2 = rnormal()
gen double eu = rnormal()
bysort id (t): gen double x1 = sum(e1)
bysort id (t): gen double x2 = sum(e2)
bysort id (t): gen double u  = eu
bysort id (t): replace u = 0.5*L.u + eu if t>1
gen double y = 2 + 0.8*x1 - 0.5*x2 + u

di as txt _n "Two regressors:"
xtnonlincoint ecm y x1 x2, breps(199)
xtnonlincoint fffff y x1 x2, breps(199)

di as txt _n "Unbalanced-panel error (should stop with rc 459):"
drop if id==1 & t<=5
capture xtnonlincoint ecm y x1 x2
di as txt "  return code = " as res _rc

di as txt _n "{hline 70}"
di as txt "All paths exercised."
di as txt "{hline 70}"
