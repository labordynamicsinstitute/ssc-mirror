*! ardldml_validate.do -- compatibility check against the reference implementation
*! Dr Merwan Roudane -- merwanroudane920@gmail.com
*! https://github.com/merwanroudane
*
*  Reproduces every deterministic quantity of the worked example in
*  Villena (2026), as computed by the Python reference package `ardldml`
*  (docs/_results.json, B = 999, R = 60, seed 20260625).
*
*  The bootstrap p-value is NOT checked here: it depends on the random
*  number stream, and Stata's RNG cannot reproduce NumPy's PCG64. Use
*  ardldml's etafile() option to feed in the reference weights when an
*  exact cross-language bootstrap check is wanted.
*
*  ONE documented deviation from the published reference figures.
*  For 1999-2007 on the REDUCED control set, docs/_results.json reports
*  F = 1.3728 (theta = -0.8990, se = 0.3786); ardldml returns F = 1.3467
*  (theta = -0.9043, se = 0.3806), and the targets below are the latter.
*
*  This is not a porting error. In fold 2 of the m_Z projection for Y, one
*  control (unrate) sits exactly on the selection boundary. The reference
*  calls scikit-learn's Lasso at its default tol = 1e-4, which stops before
*  convergence and returns lambda = 0.0117571177042, selecting nothing.
*  Tightening the reference's own solver by a single decade (tol = 1e-5 or
*  anything smaller) returns lambda = 0.0117552765138 and selects unrate --
*  which is ardldml's answer to eleven significant digits. Re-running the
*  whole Python reference with a converged solver reproduces every target
*  below exactly, this cell included.
*
*  ardldml therefore computes the converged solution by default, which is
*  deterministic and independent of the BLAS in use. Set ltol() larger to
*  loosen the first stage and see the sensitivity for yourself.

version 14.0
clear
set more off

local DTA "ardldml_passthrough.dta"

capture confirm file "`DTA'"
if _rc {
	di as error "run this from the folder holding `DTA'"
	exit 601
}

tempname pass fail
scalar `pass' = 0
scalar `fail' = 0

capture program drop _chk
program define _chk, rclass
	syntax , Name(string) Got(real) Want(real) [Tol(real 0.001)]
	local ok = (abs(`got' - `want') <= `tol')
	local mark = "FAIL"
	if (`ok') local mark = "ok"
	di as text %-22s "`name'" as res %12.4f `want' %12.4f `got' ///
		as text "   " %-6s "`mark'"
	return scalar ok = `ok'
end

di ""
di as text "{hline 78}"
di as text "ardldml -- compatibility check against the Python reference implementation"
di as text "{hline 78}"
di as text %-22s "quantity" %12s "reference" %12s "ardldml" "   status"
di as text "{hline 78}"

local nok = 0
local nbad = 0

foreach spec in ///
	"1973m1 1985m12 full  151  9.111 -0.0018   3.814 10.355" ///
	"1973m1 1985m12 red   151  8.358 -0.0008  10.285 14.132" ///
	"1986m1 1998m12 full  151 18.712  0.0040  -1.068  0.366" ///
	"1986m1 1998m12 red   151 32.848  0.0052  -1.110  0.275" ///
	"1999m1 2007m12 full  103  0.404  0.0022  -0.971  0.897" ///
	"1999m1 2007m12 red   103  1.3467  0.0057  -0.9043  0.3806" ///
	"2008m1 2020m12 full  151  3.703 -0.0087   0.571  0.222" ///
	"2008m1 2020m12 red   151  3.384 -0.0087   0.555  0.226" {

	local t1   : word 1 of `spec'
	local t2   : word 2 of `spec'
	local set  : word 3 of `spec'
	local wN   : word 4 of `spec'
	local wF   : word 5 of `spec'
	local wA   : word 6 of `spec'
	local wT   : word 7 of `spec'
	local wS   : word 8 of `spec'

	if ("`set'" == "full") {
		local ctrl "m2 ffr ip unrate oil gs10 baa"
		local intg "m2 ip oil gs10 baa ffr"
	}
	else {
		local ctrl "ffr ip unrate gs10 baa"
		local intg "ip gs10 baa ffr"
	}

	qui use "`DTA'", clear
	foreach v in cpi neer m2 ip oil {
		qui replace `v' = ln(`v')
	}
	qui tsset mdate
	qui keep if inrange(mdate, tm(`t1'), tm(`t2'))

	qui ardldml cpi neer, controls(`ctrl') integrated(`intg') ///
		lags(4) blocks(5) buffer(6) nobootstrap

	di as text "`t1'-`t2', `set' set:"
	_chk, name("  N")     got(`=e(N)')        want(`wN') tol(0)
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
	_chk, name("  F")     got(`=e(F)')        want(`wF') tol(0.001)
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
	_chk, name("  alpha") got(`=e(alpha)')    want(`wA') tol(0.0001)
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
	_chk, name("  theta") got(`=e(theta)')    want(`wT') tol(0.001)
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
	_chk, name("  se")    got(`=e(theta_se)') want(`wS') tol(0.001)
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
}

* ---------------------------------------------------------------------
* the four fits of the trend-absorption diagnostic (Definition 2),
* 1999-2007, and the unpenalised m_Z arm
* ---------------------------------------------------------------------
di ""
di as text "trend-absorption arms, 1999m1-2007m12:"

qui use "`DTA'", clear
foreach v in cpi neer m2 ip oil {
	qui replace `v' = ln(`v')
}
qui tsset mdate
qui keep if inrange(mdate, tm(1999m1), tm(2007m12))

qui ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa) ///
	integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6) ///
	mzproj(plain) nobootstrap
di as text "full set, m_Z = plain (the diagnostic's Delta_m arm):"
_chk, name("  F")     got(`=e(F)')        want(1.1066)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))
_chk, name("  theta") got(`=e(theta)')    want(-0.0122)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))
_chk, name("  se")    got(`=e(theta_se)') want(0.1652)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))

qui ardldml cpi neer, controls(ffr ip unrate gs10 baa) ///
	integrated(ip gs10 baa ffr) lags(4) blocks(5) buffer(6) ///
	mzproj(plain) nobootstrap
di as text "reduced set, m_Z = plain:"
_chk, name("  F")     got(`=e(F)')        want(2.3336)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))
_chk, name("  theta") got(`=e(theta)')    want(-2.7910) tol(0.01)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))
_chk, name("  se")    got(`=e(theta_se)') want(7.4333) tol(0.01)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))

* ---------------------------------------------------------------------
* penalty / projection sweep, 1999-2007 (Section 7.5 robustness grid)
* ---------------------------------------------------------------------
di ""
di as text "penalty sweep, 1999m1-2007m12 (full set):"

foreach cell in "adaptive low 1 0.5454" "adaptive medium 1 0.2794" ///
	"adaptive high 1 0.6869" "plain low 5 0.8890" ///
	"plain medium 5 1.2933" "plain high 5 0.3238" {

	local pj : word 1 of `cell'
	local pn : word 2 of `cell'
	local nz : word 3 of `cell'
	local wF : word 4 of `cell'

	qui ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa) ///
		integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6) ///
		mzproj(`pj') penalty(`pn') nobootstrap
	di as text "m_Z = `pj', penalty = `pn':"
	_chk, name("  F")           got(`=e(F)')      want(`wF')
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
	_chk, name("  n selected Z") got(`=e(nsel_z)') want(`nz') tol(0)
	local nok = `nok' + r(ok)
	local nbad = `nbad' + (1 - r(ok))
}

qui ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa) ///
	integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6) ///
	mzproj(ols) nobootstrap
di as text "m_Z = ols:"
_chk, name("  F")            got(`=e(F)')      want(1.1250)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))
_chk, name("  n selected Z") got(`=e(nsel_z)') want(7) tol(0)
local nok = `nok' + r(ok)
local nbad = `nbad' + (1 - r(ok))

di as text "{hline 78}"
di as text "checks passed: " as res `nok' as text "   failed: " as res `nbad'
di as text "{hline 78}"
if (`nbad' > 0) {
	di as error "compatibility check FAILED"
	exit 9
}
di as result "ardldml reproduces the reference implementation on every checked quantity."

capture program drop _chk
