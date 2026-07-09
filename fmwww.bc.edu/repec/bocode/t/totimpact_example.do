*! totimpact_example.do  08jul2026
*! Self-test / demonstration for totimpact (Pesaran & Smith, 2014)
*! Merwan Roudane  merwanroudane920@gmail.com  github.com/merwanroudane
*
* Run with:  do totimpact_example.do
* Exercises every code path (standalone, postestimation, focus, gamma, graph,
* noheader) and numerically verifies the two core Pesaran-Smith identities:
*   (a) total impact effect  == simple-regression slope of y on the focus var
*   (b) corrected s.e.        == omega(full model) / sqrt( sum (x-xbar)^2 )

clear all
set more off
set seed 12345

*--------------------------------------------------------------------
* 1. A DGP with correlated regressors and a genuine SIGN REVERSAL.
*    x1 and x2 are strongly positively correlated; beta on x2 is
*    negative, but its TOTAL impact (letting x1 move with it) is positive.
*--------------------------------------------------------------------
set obs 300
gen x1 = rnormal()
gen x2 = 0.9*x1 + 0.4*rnormal()
gen x3 = 0.3*x1 + rnormal()
gen y  = 1.0*x1 - 0.2*x2 + 0.5*x3 + rnormal()

*--------------------------------------------------------------------
* 2. Standalone use — full table (should flag a sign reversal on x2).
*--------------------------------------------------------------------
totimpact y x1 x2 x3
matrix TAB = r(table)
matrix list TAB

*--------------------------------------------------------------------
* 3. Verify identity (a): total == simple-regression slope of y on x2.
*--------------------------------------------------------------------
totimpact y x1 x2 x3, focus(x2)
scalar lam_x2 = r(table)[1,3]

regress y x2
scalar simpb = _b[x2]

di as txt "lambda(x2) from totimpact = " as res lam_x2
di as txt "simple-regression b(x2)  = " as res simpb
assert reldif(lam_x2, simpb) < 1e-8
di as result "PASS: total impact effect equals the simple-regression slope."

*--------------------------------------------------------------------
* 4. Verify identity (b): corrected s.e. = omega(full) / sqrt(Sxx).
*--------------------------------------------------------------------
quietly totimpact y x1 x2 x3, focus(x2)
scalar se_x2   = r(table)[1,4]
scalar omega   = r(rmse)
quietly summarize x2
scalar Sxx     = r(Var)*(r(N)-1)
scalar se_check = omega/sqrt(Sxx)

di as txt "reported s.e.(x2)   = " as res se_x2
di as txt "omega/sqrt(Sxx)     = " as res se_check
assert reldif(se_x2, se_check) < 1e-7
di as result "PASS: corrected standard error matches omega/sqrt(Sxx)."

*--------------------------------------------------------------------
* 5. Postestimation use after regress (+ focus + level).
*--------------------------------------------------------------------
regress y x1 x2 x3
totimpact, focus(x2 x3) level(90)

* e() must be untouched afterwards
di as txt "e(cmd) after totimpact = " as res "`e(cmd)'"
assert "`e(cmd)'" == "regress"
di as result "PASS: regress results preserved after postestimation call."

*--------------------------------------------------------------------
* 6. gamma matrix and noheader (silent, results only).
*--------------------------------------------------------------------
totimpact y x1 x2 x3, gamma
quietly totimpact y x1 x2 x3, noheader
di as txt "silent run stored r(lambda):"
matrix list r(lambda)

*--------------------------------------------------------------------
* 7. Graphs.
*--------------------------------------------------------------------
* Full dashboard (compare + decompose + gamma):
totimpact y x1 x2 x3, graph name(dashboard)

* Individual plots:
totimpact y x1 x2 x3, plots(compare)   name(g_compare)
totimpact y x1 x2 x3, plots(decompose) name(g_decomp)
totimpact y x1 x2 x3, plots(gamma)     name(g_gamma)

* A chosen subset, saved to disk and exported to PNG:
totimpact y x1 x2 x3, plots(compare gamma) name(g_sub) saving(totimpact_sub)
* graph export totimpact_sub.png, replace width(1400)

di as result _n "All totimpact self-tests passed."
