*=======================================================================*
*  xttestpanel  --  POSTESTIMATION workflow example
*  Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Pattern: fit your panel model ONCE with xtreg, then call each
*  xttestpanel subcommand with NO varlist.  Each test reuses the
*  depvar, regressors, model type and estimation sample from the
*  fitted model in memory, and restores e() afterwards so you can keep
*  chaining tests (or run -all-) without refitting.
*=======================================================================*
clear all
set more off
version 14.0

*--- make the package visible (delete if installed via net install) -----
adopath ++ "C:/Users/HP/Documents/xtpmg/xttestpanel"
discard

*--- simulate a panel with built-in problems ----------------------------
set seed 20260609
local N = 50
local T = 20
set obs `=`N'*`T''
gen long id = ceil(_n/`T')
bysort id: gen int t = _n
xtset id t

* unit effects correlated with x1  => FE correct, RE biased (Hausman rejects)
bysort id (t): gen double mu = rnormal() if _n==1
bysort id (t): replace mu = mu[1]
gen double x1 = 0.6*mu + rnormal()
gen double x2 = 0.4*x1 + rnormal()
gen double x3 = 0.95*x2 + 0.1*rnormal()      // near-collinear with x2 => high VIF
gen double x4 = rnormal()

* common factor with positive loadings => cross-sectional dependence
bysort id (t): gen double load = 0.6 + abs(rnormal()) if _n==1
bysort id (t): replace load = load[1]
bysort t (id): gen double ftime = rnormal() if _n==1
bysort t (id): replace ftime = ftime[1]

* AR(1) errors with heteroskedasticity driven by x4
sort id t
gen double e = .
replace e = rnormal()*sqrt(exp(0.4*x4)) if t==1
replace e = 0.5*L.e + rnormal()*sqrt(exp(0.4*x4)) if t>1
gen double u = mu + load*ftime + e

* outcome with an omitted nonlinear term (x2^2) => functional-form test bites
gen double y = 1 + 1.0*x1 + 0.8*x2 + 0.5*x2^2 - 0.3*x4 + u

*=======================================================================*
*  STEP 1 -- fit your model ONCE
*=======================================================================*
xtreg y x1 x2 x3 x4, fe

*=======================================================================*
*  STEP 2 -- run every diagnostic as postestimation (no varlist needed)
*=======================================================================*

* heteroskedasticity of the idiosyncratic errors  (+ diagnostic plot)
xttestpanel het, graph

* serial correlation, up to 2 lags  (+ e(t) vs e(t-1) plot)
xttestpanel serial, lags(2) graph

* cross-sectional dependence  (+ correlation heatmap if heatplot installed)
xttestpanel csd, graph

* multicollinearity of the within design  (+ VIF bar chart)
xttestpanel vif, graph

* FE-vs-RE specification, classical + robust  (+ residual distribution)
xttestpanel hausman, graph

* functional-form (Lin-Li-Sun), 299 bootstrap reps
xttestpanel func, reps(299)

*=======================================================================*
*  STEP 3 -- or run the whole battery at once + a combined dashboard
*=======================================================================*
xttestpanel all, dashboard

* the headline p-values are returned in r()
return list

di as txt _n "{hline 70}"
di as txt "  Expected with this DGP (all should REJECT except where noted):"
di as txt "   het      : REJECT  (variance depends on x4)"
di as txt "   serial   : REJECT  (AR(1), rho=0.5)"
di as txt "   csd      : REJECT  (common factor, positive loadings)"
di as txt "   func     : REJECT  (omitted x2^2)"
di as txt "   hausman  : REJECT  => use FE (mu correlated with x1)"
di as txt "   vif      : x2 & x3 ~ 100 (strong collinearity)"
di as txt "{hline 70}"
