* ======================================================================
* xtheteroquant_example.do
* Self-test / demonstration for xtheteroquant
* (two-step tau-quantile of heterogeneous unit-specific coefficients,
*  Galvao, Hounyo and Lin, 2026, arXiv:2605.01923)
* Author: Merwan Roudane (merwanroudane920@gmail.com)
* https://github.com/merwanroudane
* Run:  do xtheteroquant_example.do
* ======================================================================
version 14
clear all
discard
set more off
set seed 20260612

* ----------------------------------------------------------------------
* DGP:  y_it = a_i + b1_i*x1_it + b2_i*x2_it + e_it
*       a_i  ~ N(0,1)
*       b1_i ~ chi2(2)/2   (right-skewed: mean 1, true q25/q50/q75 below)
*       b2_i ~ N(1, .5)    (symmetric around 1)
* ----------------------------------------------------------------------
local N 150
local T 60
set obs `N'
gen long id = _n
gen double a_i  = rnormal(0,1)
gen double b1_i = rchi2(2)/2
gen double b2_i = rnormal(1, .5)
expand `T'
bysort id: gen int t = _n
xtset id t
gen double x1 = rnormal()
gen double x2 = rnormal()
gen double y  = a_i + b1_i*x1 + b2_i*x2 + rnormal()

* true cross-sectional quantiles of the heterogeneous slopes (this sample)
preserve
keep if t == 1
di as txt _n "{hline 70}"
di as txt "TRUE in-sample quantiles of the heterogeneous coefficients:"
foreach v in a_i b1_i b2_i {
    _pctile `v', p(25 50 75)
    di as txt "  `v' : q25 = " as res %8.4f r(r1) ///
       as txt "   q50 = " as res %8.4f r(r2)      ///
       as txt "   q75 = " as res %8.4f r(r3)
}
di as txt "{hline 70}"
restore

* ----------------------------------------------------------------------
* 1) Basic call: quartiles, both designs (SQB + CDQB)
* ----------------------------------------------------------------------
di as txt _n "===> [1] Basic call: xtheteroquant y x1 x2"
xtheteroquant y x1 x2, tau(.25 .5 .75) reps(200) seed(1001)
return list
matrix list r(table), format(%9.4f)

* ----------------------------------------------------------------------
* 2) More taus, percentile CIs, first-step distribution detail,
*    save the first-step coefficients with gen1()
* ----------------------------------------------------------------------
di as txt _n "===> [2] tau(.1 .25 .5 .75 .9), percentile CIs, detail, gen1()"
xtheteroquant y x1 x2, tau(.1 .25 .5 .75 .9) reps(200) seed(1002) ///
    citype(percentile) detail gen1(bhat)
egen byte _tag = tag(id)
di as txt _n "first-step coefficients saved by gen1(bhat):"
summarize bhat_x1 bhat_x2 bhat_cons if _tag

* check: first-step estimates track the true heterogeneous slopes
corr bhat_x1 b1_i if _tag
corr bhat_x2 b2_i if _tag
drop bhat_x1 bhat_x2 bhat_cons _tag

* ----------------------------------------------------------------------
* 3) Quantile process plot (Figure 1/2 style) + first-step densities
* ----------------------------------------------------------------------
di as txt _n "===> [3] plot + dist graphs (xthq_demo, xthq_demo_dist)"
xtheteroquant y x1 x2, tau(.5) reps(200) seed(1003) ///
    plot grid(19) dist name(xthq_demo) nodots

* ----------------------------------------------------------------------
* 4) Single design displays
* ----------------------------------------------------------------------
di as txt _n "===> [4] design(sqb) only, slope on x1 only in the plot"
xtheteroquant y x1 x2, tau(.5) reps(200) seed(1004) design(sqb) ///
    plot plotvars(x1) name(xthq_sqb_x1) nodots

di as txt _n "===> [5] design(cdqb) only, table output"
xtheteroquant y x1 x2, tau(.25 .5 .75) reps(200) seed(1005) design(cdqb) nodots

* ----------------------------------------------------------------------
* 6) Postestimation mode after xtreg, fe
* ----------------------------------------------------------------------
di as txt _n "===> [6] postestimation after xtreg, fe"
xtreg y x1 x2, fe
xtheteroquant, tau(.25 .5 .75) reps(200) seed(1006) nodots
* confirm the user's e() results survived
di as txt "e(cmd) after xtheteroquant = " as res e(cmd)

* ----------------------------------------------------------------------
* 7) Intercept-only model: tau-quantile of unit long-run means
*    (Example 2 in the paper)
* ----------------------------------------------------------------------
di as txt _n "===> [7] intercept-only model: quantiles of long-run means"
xtheteroquant y, tau(.25 .5 .75) reps(200) seed(1007) nodots

* ----------------------------------------------------------------------
* 8) noconstant and null() options
* ----------------------------------------------------------------------
di as txt _n "===> [8] noconstant, testing H0: theta(tau) = 1"
xtheteroquant y x1 x2, tau(.5) reps(200) seed(1008) noconstant null(1) nodots

* ----------------------------------------------------------------------
* 9) Unbalanced panel robustness: delete 20% of rows at random
* ----------------------------------------------------------------------
di as txt _n "===> [9] unbalanced panel (20% of observations dropped)"
preserve
drop if runiform() < .20
xtheteroquant y x1 x2, tau(.25 .5 .75) reps(200) seed(1009) nodots
restore

di as txt _n "{hline 70}"
di as txt "xtheteroquant self-test completed."
di as txt "Graphs created: xthq_demo, xthq_demo_dist, xthq_sqb_x1"
di as txt "Compare the [1] estimates with the TRUE quantiles printed above."
di as txt "{hline 70}"
