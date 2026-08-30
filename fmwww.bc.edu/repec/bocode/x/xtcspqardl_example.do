*! xtcspqardl_example.do  v1.1.0  29aug2026
*! Dr Merwan Roudane  merwanroudane920@gmail.com  github.com/merwanroudane
*!
*! Self-test for xtcspqardl on the Monte Carlo design of
*! Harding, Lamarche & Pesaran (2018), section 3, so that every reported
*! quantity can be checked against a known truth.
*!
*!   y_it = a_i + lambda_i y_i,t-1 + b1_i x1_it + b2 x2_it
*!          + g1_i f1_t + g2_i f2_t + u_it
*!   x_jit = mu_i + G_ji f_jt + v_jit,  v AR(0.8),  f AR(0.9)
*!
*! Truths:  lambda_i ~ U(0.2, 0.8)   ->  mean 0.50
*!          b1_i     = 1 + U(-0.25, 0.25)   ->  mean 1.00
*!          b2       = 0.50
*!          long run theta_j = b_j / (1 - mean lambda)
*!
*! Run this after   do xtcspqardl.ado   (or after net install), then read
*! the truth-versus-estimate block printed at the end.

clear
set more off

* ---------------------------------------------------------------------
* 1.  Generate the panel
* ---------------------------------------------------------------------
set seed 20260829
local N = 40
local T = 80
local S = 150

set obs `= `N' * (`T' + `S')'
gen long id = ceil(_n / (`T' + `S'))
bysort id: gen int t = _n - `S'

* unit-specific parameters, drawn ONCE per unit
gen double g1 = .
gen double g2 = .
gen double G1 = .
gen double G2 = .
gen double a_i = .
gen double lam_i = .
gen double b1_i = .
forvalues i = 1/`N' {
	qui replace g1    = rnormal(0.5, 1)          if id == `i'
	qui replace g2    = rnormal(0.5, 1)          if id == `i'
	qui replace G1    = rnormal(0.5, 1)          if id == `i'
	qui replace G2    = rnormal(0.5, 1)          if id == `i'
	qui replace lam_i = 0.2 + 0.6 * runiform()   if id == `i'
	qui replace b1_i  = 1 + runiform(-0.25, 0.25) if id == `i'
	qui replace a_i   = rnormal(0, 1)            if id == `i'
}

* the factors are COMMON: draw one path and share it across units
gen double f1 = 0
gen double f2 = 0
bysort id (t): replace f1 = 0.9*f1[_n-1] + sqrt(1-0.81)*rnormal() if _n > 1
bysort id (t): replace f2 = 0.9*f2[_n-1] + sqrt(1-0.81)*rnormal() if _n > 1
bysort t: egen double m1 = mean(f1)
bysort t: egen double m2 = mean(f2)
replace f1 = m1
replace f2 = m2
drop m1 m2

* idiosyncratic regressor components
gen double v1 = 0
gen double v2 = 0
bysort id (t): replace v1 = 0.8*v1[_n-1] + sqrt(1-0.64)*rnormal() if _n > 1
bysort id (t): replace v2 = 0.8*v2[_n-1] + sqrt(1-0.64)*rnormal() if _n > 1
gen double x1 = 0.5 + G1*f1 + v1
gen double x2 = 0.5 + G2*f2 + v2

gen double y = 0
bysort id (t): replace y = a_i + lam_i*y[_n-1] + b1_i*x1 + 0.5*x2 ///
	+ g1*f1 + g2*f2 + rnormal() if _n > 1

drop if t <= 0
xtset id t
gen double dy  = D.y
gen double dx1 = D.x1
gen double dx2 = D.x2

qui summarize lam_i, meanonly
scalar TRUE_LAM = r(mean)
scalar TRUE_B1  = 1
scalar TRUE_B2  = 0.5
scalar TRUE_T1  = TRUE_B1 / (1 - TRUE_LAM)
scalar TRUE_T2  = TRUE_B2 / (1 - TRUE_LAM)

di _n as txt "{hline 74}"
di as txt "Simulated panel: N = `N', T = `T'"
di as txt "True mean lambda = " as res %6.4f TRUE_LAM
di as txt "True beta1 = 1.00, beta2 = 0.50"
di as txt "True long run: theta1 = " as res %6.4f TRUE_T1 ///
	as txt ", theta2 = " as res %6.4f TRUE_T2
di as txt "{hline 74}"


* ---------------------------------------------------------------------
* 2.  QCCEMG -- the baseline of Harding, Lamarche & Pesaran (2018)
* ---------------------------------------------------------------------
di _n as txt "{hline 74}"
di as txt "EXAMPLE 1  QCCEMG at the median"
di as txt "{hline 74}"
xtcspqardl y x1 x2, tau(0.5) qccemg

tempname B L
matrix `B' = e(b_sr)
matrix `L' = e(b_lr)
di _n as txt "  TRUTH vs ESTIMATE"
di as txt "    lambda : true " as res %7.4f TRUE_LAM ///
	as txt "   estimated " as res %7.4f `B'[1,1]
di as txt "    beta1  : true " as res %7.4f TRUE_B1  ///
	as txt "   estimated " as res %7.4f `B'[1,2]
di as txt "    beta2  : true " as res %7.4f TRUE_B2  ///
	as txt "   estimated " as res %7.4f `B'[1,3]
di as txt "    theta1 : true " as res %7.4f TRUE_T1  ///
	as txt "   estimated " as res %7.4f `L'[1,1]
di as txt "    theta2 : true " as res %7.4f TRUE_T2  ///
	as txt "   estimated " as res %7.4f `L'[1,2]


* ---------------------------------------------------------------------
* 3.  Several quantiles, with the inter-quantile analysis and figures
* ---------------------------------------------------------------------
di _n as txt "{hline 74}"
di as txt "EXAMPLE 2  QCCEMG at five quantiles, full analysis and figures"
di as txt "{hline 74}"
xtcspqardl y x1 x2, tau(0.1 0.25 0.5 0.75 0.9) qccemg full graph

* postestimation on the posted e(b)/e(V)
di _n as txt "  Cross-quantile test on the long-run effect of x1:"
test [lr090]x1 = [lr010]x1
lincom [lr090]x1 - [lr010]x1


* ---------------------------------------------------------------------
* 4.  QCCEPMG -- must NOT reproduce QCCEMG
* ---------------------------------------------------------------------
di _n as txt "{hline 74}"
di as txt "EXAMPLE 3  QCCEPMG (inverse-variance pooling)"
di as txt "{hline 74}"
qui xtcspqardl y x1 x2, tau(0.5) qccemg notable
tempname MG
matrix `MG' = e(b_sr)
xtcspqardl y x1 x2, tau(0.5) qccepmg
tempname PM
matrix `PM' = e(b_sr)
di _n as txt "  mean group  lambda = " as res %7.4f `MG'[1,1]
di as txt "  pooled      lambda = " as res %7.4f `PM'[1,1]
di as txt "  relative difference = " as res %7.4f mreldif(`MG', `PM')
di as txt "  (must be non-zero: before v1.1.0 the two were identical)"


* ---------------------------------------------------------------------
* 5.  One-step CS-PQARDL
* ---------------------------------------------------------------------
di _n as txt "{hline 74}"
di as txt "EXAMPLE 4  One-step CS-PQARDL, conditional ECM"
di as txt "{hline 74}"
xtcspqardl dy dx1 dx2, lr(L.y L.x1 L.x2) tau(0.25 0.5 0.75) srtable

tempname E
matrix `E' = e(b_sr)
di _n as txt "  Speed of adjustment at the median = " as res %7.4f `E'[1,4]
di as txt "  True value = mean(lambda) - 1 = " as res %7.4f (TRUE_LAM - 1)
di as txt "  (must lie strictly inside (-2, 0))"


* ---------------------------------------------------------------------
* 6.  Two-step CS-PQARDL as in Ul-Durar et al. (2025)
* ---------------------------------------------------------------------
di _n as txt "{hline 74}"
di as txt "EXAMPLE 5  Two-step CS-PQARDL (their Tables 7, 8 and 9)"
di as txt "{hline 74}"
xtcspqardl y x1 x2, tau(0.5) ecm reps(100) seed(4321) unittable showcsa


* ---------------------------------------------------------------------
* 7.  Exact quantiles: tau(0.125) must be 0.125, not 0.13
* ---------------------------------------------------------------------
di _n as txt "{hline 74}"
di as txt "EXAMPLE 6  Non-grid quantile"
di as txt "{hline 74}"
qui xtcspqardl y x1 x2, tau(0.125) qccemg notable
di as txt "  e(tau) = " as res "`e(tau)'" as txt "  (must read 0.125)"

di _n as txt "{hline 74}"
di as txt "Self-test complete."
di as txt "{hline 74}"
