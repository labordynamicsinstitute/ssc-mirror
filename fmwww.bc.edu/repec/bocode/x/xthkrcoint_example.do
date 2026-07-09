*! xthkrcoint_example.do  08jul2026
*! Worked examples for xthkrcoint (Hadri, Kurozumi & Rao 2015)
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
clear all
set more off

*----------------------------------------------------------------------
* A. A cointegrated panel WITH cross-section dependence (H0 true)
*    y_it = 1 + x_it + u_it,  u stationary AR(.5) + common factor
*    x_it a random walk.  The test should NOT reject cointegration.
*----------------------------------------------------------------------
set seed 12345
local N 10
local T 200
set obs `=`N'*`T''
gen id = ceil(_n/`T')
bysort id: gen t = _n
xtset id t

* a common factor shared by all units -> strong cross-section dependence
sort t id
by t: gen double ef = rnormal() if _n==1
by t: replace ef = ef[1]
sort id t
by id: gen double factor = sum(ef)

* I(1) regressor
by id: gen double vx = rnormal()
by id: gen double x  = sum(vx)

* stationary equilibrium error + factor loading
by id: gen double eu = rnormal()
gen double u = .
by id: replace u = eu           if t==1
by id: replace u = .5*u[_n-1]+eu if t>1
gen double y = 1 + x + u + 0.5*factor

* baseline test
xthkrcoint y x

* trend case, OLS comparator, and the diagnostics dashboard
xthkrcoint y x, trend ols graph name(fig_coint)

* robustness across the lag order K
xthkrcoint y x, ksens(8 11 14 17 20 23 26)
matrix list r(ksens)

*----------------------------------------------------------------------
* B. A NON-cointegrated panel (H0 false): y and x are independent
*    random walks.  The test should REJECT, and the per-unit table
*    should flag the offending units.
*----------------------------------------------------------------------
by id: gen double vy = rnormal()
by id: gen double ync = sum(vy)
xthkrcoint ync x, graph name(fig_nocoint)

*----------------------------------------------------------------------
* C. Single time series (tsset): reduces to the univariate test
*----------------------------------------------------------------------
preserve
keep if id==1
tsset t
xthkrcoint y x
restore

di as txt "==== xthkrcoint examples finished ===="
