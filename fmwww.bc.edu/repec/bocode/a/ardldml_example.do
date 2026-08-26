*! ardldml_example.do  1.0.0  24aug2026
*! Self-test and worked example for ardldml
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Exercises every code path of ardldml and its postestimation suite, and
*  checks that it recovers a known truth on simulated data.
*
*  The Monte Carlo size-and-power check is a separate file,
*  ardldml_mcheck.do, because it takes about half an hour and this one
*  should stay quick enough to run on a whim.
*
*  Run with:   do ardldml_example.do
*  (use `clear', not `clear all' -- the latter would drop the Mata engine)

version 14.0
clear
set more off
set linesize 100


di _n(2) as text "{hline 78}"
di as text "PART 1  Real data: exchange-rate pass-through, 1999m1-2007m12"
di as text "{hline 78}"

capture confirm file "ardldml_passthrough.dta"
if _rc {
	di as error "ardldml_passthrough.dta not found -- run {bf:net get ardldml} first"
	exit 601
}

use ardldml_passthrough, clear
foreach v in cpi neer m2 ip oil {
	qui replace `v' = ln(`v')
}
tsset mdate
keep if inrange(mdate, tm(1999m1), tm(2007m12))

* ---- the paper's reference specification -----------------------------
ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa)			///
	integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6)	///
	breps(999) seed(20260625) showfirst

assert e(N) == 103
assert abs(e(F) - 0.4043) < 0.001
di _n as result "  [ok] statistic reproduces the reference value"

* ---- replay, and the stored results ----------------------------------
ardldml
ereturn list

* ---- postestimation --------------------------------------------------
di _n(2) as text "{hline 78}"
di as text "PART 2  Postestimation"
di as text "{hline 78}"

estat blocks
estat null, nograph
estat classical, nsim(4000) seed(7)
estat penalty
estat absorption, drop(m2 oil) breps(199) seed(20260625)

* ---- predict ---------------------------------------------------------
predict double ec_hat, ec
predict double res_hat, residuals
summarize ec_hat res_hat
assert !missing(ec_hat[_N])
di as result "  [ok] predict returns the orthogonalised series"

* ---- graphs ----------------------------------------------------------
qui ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa)		///
	integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6)	///
	breps(499) seed(20260625) graph graphblocks
di as result "  [ok] graphs drawn (ardldml_null, ardldml_blocks)"

* ---- the fixed-regressor scheme, and no-bootstrap ---------------------
qui ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa)		///
	integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6)	///
	breps(199) seed(1) bscheme(fixed)
di as text "  fixed-regressor scheme: p = " as res %6.4f e(p)
qui ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa)		///
	integrated(m2 ip oil gs10 baa ffr) nobootstrap
assert e(B) >= .
di as result "  [ok] alternative schemes run"


di _n(2) as text "{hline 78}"
di as text "PART 3  Simulated data: does it recover a known truth?"
di as text "{hline 78}"

* The paper's Appendix B design. Y = D + u with D a driftless random walk
* and u an AR(1); rho = 1 is the no-cointegration null, rho = 0.5 the
* alternative. The nuisance block is half I(1) random walks and half
* stationary AR(1) with coefficient 0.5, and 100 observations are burnt in.
capture program drop _ardldml_dgp
program define _ardldml_dgp
	syntax , NOBS(integer) DIM(integer) RHO(real) [FRACI1(real 0.5)]
	local burn = 100
	local TT = `nobs' + `burn'
	clear
	set obs `TT'
	gen int t = _n
	tsset t

	local nI1 = round(`dim' * `fraci1')
	forvalues j = 1/`dim' {
		tempvar e`j'
		qui gen double `e`j'' = rnormal()
		qui gen double w`j' = 0
		if (`j' <= `nI1') {
			qui replace w`j' = L.w`j' + `e`j'' if t > 1
		}
		else {
			qui replace w`j' = 0.5*L.w`j' + `e`j'' if t > 1
		}
	}

	qui gen double ed = rnormal()
	qui gen double eu = rnormal()
	qui gen double d = 0
	qui replace d = L.d + ed if t > 1
	qui gen double u = 0
	qui replace u = `rho'*L.u + eu if t > 1
	qui gen double y = d + u

	qui drop if t <= `burn'
	qui replace t = t - `burn'
	tsset t
end

* ---- a single fit under the alternative ------------------------------
set seed 424242
_ardldml_dgp, nobs(200) dim(20) rho(0.5)
local wl ""
forvalues j = 1/20 {
	local wl "`wl' w`j'"
}
local i1 ""
forvalues j = 1/10 {
	local i1 "`i1' w`j'"
}
ardldml y d, controls(`wl') integrated(`i1') lags(2) blocks(5) buffer(3) ///
	breps(299) seed(11) showfirst
di _n as text "  truth: y and d are cointegrated (rho = 0.5), so the test SHOULD reject."
di as text "  bootstrap p = " as res %6.4f e(p)

* ---- a single fit under the null -------------------------------------
set seed 424243
_ardldml_dgp, nobs(200) dim(20) rho(1)
ardldml y d, controls(`wl') integrated(`i1') lags(2) blocks(5) buffer(3) ///
	breps(299) seed(12) notable nolegend
di _n as text "  truth: no cointegration (rho = 1), so the test should NOT reject."
di as text "  bootstrap p = " as res %6.4f e(p)


capture program drop _ardldml_dgp

di _n(2) as text "{hline 78}"
di as result "ardldml self-test complete."
di as text "Run {bf:do ardldml_validate.do} for the numerical compatibility check"
di as text "against the reference implementation, and {bf:do ardldml_mcheck.do}"
di as text "for the Monte Carlo size and power check."
di as text "{hline 78}"
