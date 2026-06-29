*------------------------------------------------------------------------------
* xtlongestim_example.do
* Self-test: simulate a dynamic heterogeneous panel with a KNOWN long-run
* coefficient and exercise every estimator / code path of xtlongestim.
*
*   DGP (Pesaran & Zhao 1999, Sec. 4.2):
*     y(it) = a(i) + lambda(i) y(i,t-1) + beta(i) x(it) + e(it)
*     x(it) = rho x(i,t-1) + u(it)
*     beta(i) = (1 - lambda(i)) * theta(i),  theta(i) ~ N(THETA, .)
*   so the average long-run effect E[beta/(1-lambda)] = THETA (known truth).
*
* Run from this folder:  do xtlongestim_example.do
*------------------------------------------------------------------------------
clear all
set more off
version 15.1

* make the package visible if running from the source folder
capture ado uninstall xtlongestim
net install xtlongestim, from("`c(pwd)'") replace

*------------------------------------------------------------------------------
* 1.  Simulate the panel
*------------------------------------------------------------------------------
set seed 20260626

local N  = 40            // panels
local T  = 45            // periods generated (first `burn' dropped)
local burn = 15
local rho  = 0.6         // regressor persistence
local THETA = 2          // TRUE average long-run coefficient

set obs `N'
gen long id = _n
gen double a_i   = rnormal(0, 1)                 // group intercept
gen double lam_i = 0.4 + 0.15*runiform()         // lambda in (0.4,0.55), stable
gen double th_i  = `THETA' + rnormal(0, 0.25)    // heterogeneous long-run
gen double bet_i = (1 - lam_i) * th_i            // implied short-run beta

expand `T'
bysort id: gen int t = _n
xtset id t

gen double x = .
bysort id (t): replace x = rnormal()                       if _n == 1
bysort id (t): replace x = `rho'*x[_n-1] + rnormal()       if _n > 1

gen double y = .
bysort id (t): replace y = a_i + rnormal()                            if _n == 1
bysort id (t): replace y = a_i + lam_i*y[_n-1] + bet_i*x + rnormal()  if _n > 1

* drop the burn-in periods and re-time
drop if t <= `burn'
bysort id (t): replace t = _n
xtset id t

di as txt _n "True average long-run coefficient theta = " as res `THETA'

*------------------------------------------------------------------------------
* 2.  Default run  (mg dbc1 dbc2 bsbc)
*------------------------------------------------------------------------------
xtlongestim y x, reps(200)

di as txt "primary posted method: " as res "`e(primary)'"
matrix list e(LR_b)
matrix list e(LR_se)

*------------------------------------------------------------------------------
* 3.  Replay (no recomputation)
*------------------------------------------------------------------------------
xtlongestim

*------------------------------------------------------------------------------
* 4.  ALL methods, incl. Empirical & Hierarchical Bayes
*     (smaller Gibbs run to keep the self-test quick)
*------------------------------------------------------------------------------
xtlongestim y x, methods(all) reps(200) burnin(300) draws(600)
matrix list e(SR_b)
matrix list e(SR_se)

*------------------------------------------------------------------------------
* 5.  Short-run comparison only, parametric bootstrap
*------------------------------------------------------------------------------
xtlongestim y x, methods(shortrun) parametric reps(150) nodots

*------------------------------------------------------------------------------
* 6.  Two regressors, long-run reported for one of them only
*------------------------------------------------------------------------------
gen double z = .
bysort id (t): replace z = rnormal()                  if _n == 1
bysort id (t): replace z = 0.5*z[_n-1] + rnormal()    if _n > 1
* add a true effect of z to y so it is a genuine regressor
bysort id (t): replace y = y + 0.3*z

xtlongestim y x z, methods(mg dbc1 bsbc ebayes) lr(x) reps(150)

*------------------------------------------------------------------------------
* 7.  No constant
*------------------------------------------------------------------------------
xtlongestim y x, methods(mg dbc1) noconstant reps(100) nodots

*------------------------------------------------------------------------------
* 8.  Postestimation on the posted (primary) long-run coefficient
*------------------------------------------------------------------------------
xtlongestim y x z, methods(dbc1 mg) lr(x z) reps(150)
test x
lincom x

*------------------------------------------------------------------------------
* 9.  Publication graphs + journal-style tables
*     - forest plots (long-run & short-run), per variable
*     - cross-panel heterogeneity caterpillar of theta_i
*     - LaTeX (booktabs) and CSV export of the long-run table
*------------------------------------------------------------------------------
xtlongestim y x, methods(all) reps(200) burnin(300) draws(600) ///
    graph gname(fig) export("xtlongestim_results")

* the graphs are stored as fig_lr, fig_sr, fig_het (single long-run var here);
* export any of them to a file (set graphics on first if running headless):
set graphics on
capture graph export "xtlongestim_forest.png",      name(fig_lr)  width(1800) replace
capture graph export "xtlongestim_caterpillar.png", name(fig_het) width(1800) replace

di as result _n "*** xtlongestim self-test completed successfully ***"
