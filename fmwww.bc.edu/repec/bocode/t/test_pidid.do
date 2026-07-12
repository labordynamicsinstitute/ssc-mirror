*-------------------------------------------------------------------
* test_pidid.do
* Certification script for the pidid / pididplot package.
* Run this before submitting to SSC / the Stata Journal, and after
* any code change. It should complete with no red output and print
* "ALL TESTS PASSED" at the end.
*
* Tests:
*   1. Numeric accuracy against the paper's Table 1 (exact values)
*   2. Robustness to set varabbrev off  (SSC requirement)
*   3. Basic error handling (bad treatvar coding, t1<=t0, etc.)
*
* Note: the worked-example dataset is built once with -input- and
* saved to a tempfile, then reloaded with -use- wherever a fresh copy
* is needed. (Do NOT wrap -input ... end- inside a -program define-
* block: Stata's program parser closes the program at the first bare
* "end" it meets, which is -input-'s own terminator, not the program's
* -- the "end" you intended to close the program is then left
* dangling as an unrecognized top-level command.)
*-------------------------------------------------------------------

capture adopath ++ "`c(pwd)'"
set more off

tempfile exampledata

clear
input id time treat earnings
1 0 0 50000
1 1 0 52000
1 2 0 54000
1 3 0 56000
1 4 0 58000
1 5 0 60000
2 0 1 50000
2 1 1 62000
2 2 1 61000
2 3 1 59000
2 4 1 58500
2 5 1 60000
end
quietly save "`exampledata'"

di as text "{hline 60}"
di as text "TEST 1: numeric accuracy vs. paper Table 1"
di as text "{hline 60}"

set varabbrev off
quietly use "`exampledata'", clear
quietly pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) notable

assert reldif(r(sigma), 20500) < 1e-6
assert reldif(r(att_path), 4100) < 1e-6
assert abs(r(did_static)) < 1e-6
assert abs(r(tau_t0)) < 1e-6
di as result "PASS: sigma=20500, tau-bar=4100, static DiD=0, tau(t0)=0"

di as text ""
di as text "{hline 60}"
di as text "TEST 2: pididplot runs cleanly with varabbrev off"
di as text "{hline 60}"
quietly use "`exampledata'", clear
quietly pididplot earnings, panelvar(id) timevar(time) treatvar(treat) ///
	t0(0) t1(5) t2(5) name(_test_impact)
di as result "PASS: pididplot executed without error"

di as text ""
di as text "{hline 60}"
di as text "TEST 3: truncated horizon still returns the same plateaued sigma"
di as text "{hline 60}"
quietly use "`exampledata'", clear
quietly pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(3) notable
* sigma up to year 3 should be 5000+8500+5000 = 18500 by the trapezoidal rule
assert reldif(r(sigma), 18500) < 1e-6
di as result "PASS: partial-horizon sigma = 18500 as expected"

di as text ""
di as text "{hline 60}"
di as text "TEST 4: error handling"
di as text "{hline 60}"

* 4a. treatvar not 0/1 should abort with rc 198
quietly use "`exampledata'", clear
quietly replace treat = 2 in 1
capture noisily pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5)
assert _rc == 198
di as result "PASS: non-binary treatvar correctly rejected (rc=198)"

* 4b. t1 <= t0 should abort with rc 198
quietly use "`exampledata'", clear
capture noisily pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(3) t1(1)
assert _rc == 198
di as result "PASS: t1<=t0 correctly rejected (rc=198)"

* 4c. t0 outside observed range should abort with rc 198
quietly use "`exampledata'", clear
capture noisily pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(-1) t1(5)
assert _rc == 198
di as result "PASS: out-of-range t0 correctly rejected (rc=198)"

di as text ""
di as result "{hline 60}"
di as result "ALL TESTS PASSED"
di as result "{hline 60}"
