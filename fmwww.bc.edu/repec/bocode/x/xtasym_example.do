*! xtasym_example 1.0.0  09aug2026
*! Self-test and demonstration for xtasym
*! Merwan Roudane <merwanroudane920@gmail.com>
*
* Run this AFTER the command is available:
*     do xtasym.ado           // surfaces any Mata compile error with its line
*     do xtasym_example.do
*
* The panel below has a known data-generating process, so every claim the
* command makes can be checked against the truth. Sections marked CHECK end in
* an assert. If the script runs to the end without stopping, the command
* reproduced the construction exactly.

version 14.0
clear
set more off
set seed 20260809

*======================================================================
* 0.  DGP in the style of Thombs, Huang and Fitzgerald (2022), eq. (17):
*     an autoregressive outcome driven asymmetrically by the partial
*     sums of x. One common factor enters x, so that the partial sums
*     are cross-sectionally dependent and the CD test has something to
*     find; y itself is left free of it so that fixed effects can
*     recover the truth in section 8.
*
*     TRUE VALUES    lambda = .7    x+ = .8     x- = .4
*                                   L.x+ = -.4  L.x- = -.2
*     long run       x+ : (.8 - .4)/(1 - .7) = 1.3333
*                    x- : (.4 - .2)/(1 - .7) =  .6667
*======================================================================

local N  40
local T  45

set obs `=`N'*`T''
gen int id = ceil(_n/`T')
bysort id: gen int t = _n
xtset id t

* ---- one common factor, generated ONCE and shared by every panel ----
gen double f = .
qui forvalues s = 1/`T' {
	if (`s'==1) {
		local fprev = rnormal()
	}
	else {
		local fprev = .7*`fprev' + rnormal()
	}
	replace f = `fprev' if t==`s'
}

* ---- heterogeneous loadings and panel effects -----------------------
bysort id (t): gen double gam = rnormal(1,.2) if _n==1
bysort id (t): replace gam = gam[1]
bysort id (t): gen double cy  = rnormal(1,1)  if _n==1
bysort id (t): replace cy = cy[1]

* ---- x wanders, so increases and decreases both occur ---------------
gen double e = rnormal()
bysort id (t): gen double x = 0 if t==1
bysort id (t): replace x = x[_n-1] + .02 + .35*e + .30*gam*f if t>1

* ---- the TRUE partial sums (Shin convention) ------------------------
bysort id (t): gen double dx = x - x[_n-1]
gen double dp = max(dx,0)
gen double dn = min(dx,0)
replace dp = 0 if mi(dx)
replace dn = 0 if mi(dx)
bysort id (t): gen double xp_true = sum(dp)
bysort id (t): gen double xn_true = sum(dn)

* ---- the outcome, built recursively ---------------------------------
gen double u = rnormal()
bysort id (t): gen double y = cy + u if t==1
bysort id (t): replace y = .7*y[_n-1] + .8*xp_true + .4*xn_true       ///
	- .4*xp_true[_n-1] - .2*xn_true[_n-1] + cy + u if t>1

label variable x "simulated driver"
label variable y "simulated outcome"


*======================================================================
* 1.  Everything on
*======================================================================
di as txt _n "{hline 72}"
di as txt "1.  xtasym x, all"
di as txt "{hline 72}"

xtasym x, all nodraw

local ps "`r(partialsums)'"
local cv "`r(convention)'"
local th = r(threshold)
matrix F1 = r(frequency)
matrix S1 = r(summary)
matrix C1 = r(csd)

di as txt _n "r(partialsums) : " as res "`ps'"
di as txt    "r(convention)  : " as res "`cv'"
di as txt    "r(threshold)   : " as res `th'
matrix list F1
matrix list S1
matrix list C1
matrix drop F1 S1 C1


*======================================================================
* 2.  CHECK  the partial sums reproduce the construction exactly
*======================================================================
di as txt _n "{hline 72}"
di as txt "2.  CHECK  x_p and x_n against the true partial sums"
di as txt "{hline 72}"

qui gen double err_p = abs(x_p - xp_true)
qui gen double err_n = abs(x_n - xn_true)
qui su err_p
di as txt "max |x_p - truth| = " as res %14.12f r(max)
qui su err_n
di as txt "max |x_n - truth| = " as res %14.12f r(max)
assert err_p < 1e-9
assert err_n < 1e-9
drop err_p err_n
di as result "PASS  partial sums reproduce the data-generating process"

assert x_n <= 0
di as result "PASS  the negative arm is signed and never positive"


*======================================================================
* 3.  CHECK  the two conventions differ by one sign and nothing else
*======================================================================
di as txt _n "{hline 72}"
di as txt "3.  CHECK  convention(allison) flips the negative arm only"
di as txt "{hline 72}"

qui xtasym x, convention(allison) prefix(a_)
assert a_x_p == x_p
assert reldif(a_x_n, -x_n) < 1e-12 | (a_x_n==0 & x_n==0)
assert a_x_n >= 0
di as result "PASS  Z+ = x+, Z- = -x-, both non-negative"


*======================================================================
* 4.  CHECK  the fdm components add back to the first difference, and
*            differencing a partial sum returns its own component
*======================================================================
di as txt _n "{hline 72}"
di as txt "4.  CHECK  first-difference-method components"
di as txt "{hline 72}"

qui xtasym x, fdm prefix(f_)
assert reldif(f_x_pfd + f_x_nfd, dx) < 1e-9 if !mi(dx)
di as result "PASS  x_pfd + x_nfd = D.x"

qui gen double gap = D.x_p - f_x_pfd
qui su gap
di as txt "max |D.x_p - x_pfd| = " as res %14.12f abs(r(max))
assert abs(gap) < 1e-9 if !mi(gap)
drop gap
di as result "PASS  D.(positive partial sum) = positive component"


*======================================================================
* 5.  CHECK  the frequency table is internally consistent
*======================================================================
di as txt _n "{hline 72}"
di as txt "5.  CHECK  frequency table"
di as txt "{hline 72}"

qui xtasym x, frequency replace
matrix F = r(frequency)
scalar pct = F[1,2] + F[1,4] + F[1,6]
di as txt "shares sum to " as res %8.4f pct
assert abs(pct - 100) < 1e-6

scalar cnt = F[1,1] + F[1,3] + F[1,5]
qui count if !mi(dx)
assert cnt == r(N)
di as result "PASS  counts equal the number of usable first differences"
scalar drop pct cnt
matrix drop F


*======================================================================
* 6.  CHECK  a dead band never sends a positive change to the
*            negative arm
*======================================================================
di as txt _n "{hline 72}"
di as txt "6.  CHECK  threshold() is applied symmetrically"
di as txt "{hline 72}"

qui xtasym x, threshold(.20) prefix(b_) frequency

* under a symmetric band the negative arm can only fall, the positive
* arm can only rise
qui gen double db_n = D.b_x_n
qui gen double db_p = D.b_x_p
assert db_n <= 0 if !mi(db_n)
assert db_p >= 0 if !mi(db_p)
drop db_n db_p
di as result "PASS  each arm moves in one direction only under a dead band"

* every movement that clears the band must exceed it in absolute value
qui count if D.b_x_p > 0 & D.b_x_p <= .20 & !mi(D.b_x_p)
assert r(N)==0
qui count if D.b_x_n < 0 & D.b_x_n >= -.20 & !mi(D.b_x_n)
assert r(N)==0
di as result "PASS  no change inside the dead band reaches either arm"


*======================================================================
* 7.  The CD test: a series carrying the common factor against one
*     that does not
*======================================================================
di as txt _n "{hline 72}"
di as txt "7.  Cross-sectional dependence, common factor vs idiosyncratic"
di as txt "{hline 72}"

qui gen double z_common = f + .3*rnormal()
qui gen double z_idio   = rnormal()

xtasym z_common z_idio, nogenerate csd
matrix C = r(csd)
di as txt _n "CD (common factor) = " as res %9.3f C[1,1] as txt "   p = " as res %6.4f C[1,2]
di as txt    "CD (idiosyncratic) = " as res %9.3f C[2,1] as txt "   p = " as res %6.4f C[2,2]
if (C[1,2] < .01 & C[2,2] > .05) {
	di as result "PASS  the test separates common-factor from idiosyncratic series"
}
else {
	di as error  "NOTE  unexpected CD outcome; inspect the two statistics above"
}
matrix drop C


*======================================================================
* 8.  Using the partial sums: dynamic fixed effects in ARDL form
*     (Thombs et al. 2022, eq. 18) against the known truth
*======================================================================
di as txt _n "{hline 72}"
di as txt "8.  Estimation against the truth"
di as txt "{hline 72}"

qui xtasym x, replace
xtreg y L.y x_p x_n L.x_p L.x_n, fe cluster(id)

di as txt _n "{hline 56}"
di as txt %-18s "Parameter" %14s "True" %12s "Estimate" %12s "Error"
di as txt "{hline 56}"
di as txt %-18s "L.y"   as res %14.4f  .7 %12.4f _b[L.y]   %12.4f _b[L.y]   - .7
di as txt %-18s "x_p"   as res %14.4f  .8 %12.4f _b[x_p]   %12.4f _b[x_p]   - .8
di as txt %-18s "x_n"   as res %14.4f  .4 %12.4f _b[x_n]   %12.4f _b[x_n]   - .4
di as txt %-18s "L.x_p" as res %14.4f -.4 %12.4f _b[L.x_p] %12.4f _b[L.x_p] + .4
di as txt %-18s "L.x_n" as res %14.4f -.2 %12.4f _b[L.x_n] %12.4f _b[L.x_n] + .2
di as txt "{hline 56}"

nlcom (lr_pos: (_b[x_p] + _b[L.x_p])/(1 - _b[L.y]))   ///
      (lr_neg: (_b[x_n] + _b[L.x_n])/(1 - _b[L.y]))
di as txt "true long-run effects: x+ = " as res %6.4f 4/3 as txt ", x- = " as res %6.4f 2/3

di as txt _n "Short-run symmetry test, Shin convention (H0: b+ = b-):"
test x_p = x_n


*======================================================================
* 9.  Graphics, one run per colour scheme
*======================================================================
di as txt _n "{hline 72}"
di as txt "9.  Graphics"
di as txt "{hline 72}"

qui xtasym x, graph scheme(parula)  name(g_parula)  nodraw replace
qui xtasym x, graph scheme(viridis) name(g_viridis) nodraw replace
qui xtasym x, graph scheme(journal) name(g_journal) nodraw replace
qui xtasym x, graph scheme(mono)    name(g_mono)    nodraw replace

qui xtasym x, graph scheme(parula) name(fig) combine nodraw replace
di as txt "graphs in memory: " as res "`r(graphs)'"
graph display fig_all


*======================================================================
* 10. Error paths, each of which should be refused
*======================================================================
di as txt _n "{hline 72}"
di as txt "10. Error handling"
di as txt "{hline 72}"

capture noisily xtasym x, nogenerate threshold(.1)
assert _rc == 198
capture noisily xtasym x, nogenerate fdm
assert _rc == 198
capture noisily xtasym x, convention(banana)
assert _rc == 198
capture noisily xtasym x, scheme(neon)
assert _rc == 198
capture noisily xtasym x
assert _rc == 110
capture noisily xtasym x, csdopt(nothing)
assert _rc == 198
di as result "PASS  every invalid combination was refused"

preserve
	qui xtset, clear
	capture noisily xtasym x
	assert _rc == 459
restore
di as result "PASS  unset data is refused"


di as txt _n "{hline 72}"
di as result "ALL CHECKS PASSED"
di as txt "{hline 72}"
