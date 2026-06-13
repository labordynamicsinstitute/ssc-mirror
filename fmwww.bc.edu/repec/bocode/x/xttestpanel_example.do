*=======================================================================*
*  xttestpanel  --  full self-test / demonstration do-file
*  Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Run this whole file to exercise EVERY subcommand, both in the
*  standalone form and in the postestimation form, on a simulated panel
*  that deliberately contains heteroskedasticity, serial correlation,
*  cross-sectional dependence, a nonlinear term, near-collinearity and a
*  fixed-effects/regressor correlation (so FE is the correct model).
*=======================================================================*
clear all
set more off
version 14.0

*--- 0. make the package visible (point this at the folder you unzipped) -
* If you installed with -net install- you can delete the next two lines.
local PKGDIR "C:/Users/HP/Documents/xtpmg/xttestpanel"
adopath ++ "`PKGDIR'"
discard

*--- 1. simulate a panel  (N units, T periods) --------------------------
set seed 20260609
local N = 50
local T = 20
set obs `=`N'*`T''
gen long id = ceil(_n/`T')
bys id: gen int t = _n
xtset id t

* unit effects correlated with x1  => FE is correct, RE is biased
bysort id (t): gen double mu = rnormal() if _n==1
bysort id (t): replace mu = mu[1]
gen double x1 = 0.6*mu + rnormal()
gen double x2 = 0.4*x1 + rnormal()          // mild collinearity with x1
gen double x3 = 0.95*x2 + 0.1*rnormal()     // strong collinearity  => high VIF
gen double x4 = rnormal()

* common factor (positive loadings => positive average cross-correlation,
* so Pesaran CD as well as the LM tests detect the dependence)
bysort id (t): gen double load = 0.6 + abs(rnormal()) if _n==1
bysort id (t): replace load = load[1]
bysort t (id): gen double ftime = rnormal() if _n==1
bysort t (id): replace ftime = ftime[1]

* AR(1) idiosyncratic error with heteroskedasticity in x4
sort id t
gen double e = .
replace e = rnormal()*sqrt(exp(0.4*x4)) if t==1
replace e = 0.5*L.e + rnormal()*sqrt(exp(0.4*x4)) if t>1
gen double u = mu + load*ftime + e

* outcome WITH a nonlinear term (x2^2) so the functional-form test bites
gen double y = 1 + 1.0*x1 + 0.8*x2 + 0.5*x2^2 - 0.3*x4 + u

*=======================================================================*
*  2. STANDALONE FORM  -- pass depvar indepvars + model()
*=======================================================================*
di as txt _n "{hline 70}"
di as txt "  STANDALONE FORM"
di as txt "{hline 70}"

xttestpanel het     y x1 x2 x3 x4, model(fe) graph
xttestpanel het     y x1 x2 x3 x4, model(re)
xttestpanel het     y x1 x2 x3 x4, model(tw)

xttestpanel serial  y x1 x2 x3 x4, lags(2) graph

xttestpanel csd     y x1 x2 x3 x4, graph

xttestpanel vif     y x1 x2 x3 x4, graph

xttestpanel hausman y x1 x2 x3 x4, graph

xttestpanel func    y x1 x2 x3 x4, reps(199)

*=======================================================================*
*  3. POSTESTIMATION FORM  -- fit once, then test what is in memory
*=======================================================================*
di as txt _n "{hline 70}"
di as txt "  POSTESTIMATION FORM"
di as txt "{hline 70}"

xtreg y x1 x2 x3 x4, fe
xttestpanel het
xttestpanel serial, lags(2)
xttestpanel csd
xttestpanel vif
xttestpanel hausman
xttestpanel func

*=======================================================================*
*  4. THE WHOLE SUITE AT ONCE  + combined dashboard
*=======================================================================*
di as txt _n "{hline 70}"
di as txt "  FULL SUITE (xttestpanel all)"
di as txt "{hline 70}"

xttestpanel all y x1 x2 x3 x4, model(fe) dashboard

* inspect a few stored results
di as txt _n "Stored p-values from -all-:"
di as txt "  het    p = " as res %6.4f r(p_het)
di as txt "  serial p = " as res %6.4f r(p_serial)
di as txt "  csd    p = " as res %6.4f r(p_csd)
di as txt "  func   p = " as res %6.4f r(p_func)
di as txt "  hausm  p = " as res %6.4f r(p_hausman)

di as txt _n "{hline 70}"
di as txt "  ALL TESTS RAN.  Expected pattern with this DGP:"
di as txt "   - heteroskedasticity : REJECT  (variance depends on x4)"
di as txt "   - serial correlation : REJECT  (AR(1), rho=0.5)"
di as txt "   - cross-sec depend.  : REJECT  (common factor)"
di as txt "   - functional form    : REJECT  (omitted x2^2)"
di as txt "   - Hausman FE vs RE   : REJECT  (mu correlated with x1)"
di as txt "   - VIF                : x2,x3 high (strong collinearity)"
di as txt "{hline 70}"
