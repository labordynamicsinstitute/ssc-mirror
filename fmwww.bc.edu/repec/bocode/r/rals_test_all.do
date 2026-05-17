*------------------------------------------------------------------------------
*  rals_test_all.do
*  Single end-to-end test of the rals package.
*  Copy/paste into Stata and run.  Prints PASS/FAIL per step at the end.
*  Author: Dr Merwan Roudane  <merwanroudane920@gmail.com>
*------------------------------------------------------------------------------

clear all
discard
mata: mata clear
set more off

local pkgpath = "C:/Users/HP/Documents/xtpmg/RALS/stata_rals"

* container for pass/fail results
tempname results
matrix `results' = J(15, 1, 0)
local rownames "install banner load_probe diagnostics ralsadf ralslm ralslmb ralsfadf ralsfkss ralscoint ralsfadl battery_1var battery_multi mata_persist help_pages"
matrix rownames `results' = `rownames'

di as text "{hline 78}"
di as result "  RALS package -- end-to-end self-test"
di as text "{hline 78}"

*------------------------------------------------------------------------------
*  1. Install from local copy
*------------------------------------------------------------------------------
di _n as text "[ 1/15 ] Install ..."
capture noisily net install rals, from("`pkgpath'") replace
matrix `results'[1,1] = !_rc

*------------------------------------------------------------------------------
*  1b. Verify _rals_mata.mata landed in the PLUS subdirectory
*------------------------------------------------------------------------------
di _n as text "[ 1b/15] Locate installed _rals_mata.mata ..."
capture findfile _rals_mata.mata
if !_rc {
    di as text "         found at: " as result `"`r(fn)'"'
}
else {
    di as error "         _rals_mata.mata is NOT on the adopath."
    di as text  "         Inspect c:\ado\plus\r\ -- the install must have skipped it."
}

*------------------------------------------------------------------------------
*  2. Banner / about
*------------------------------------------------------------------------------
di _n as text "[ 2/15 ] rals about ..."
capture noisily rals about
matrix `results'[2,1] = !_rc

*------------------------------------------------------------------------------
*  3. Sentinel load probe (Kit's check)
*------------------------------------------------------------------------------
di _n as text "[ 3/15 ] Mata sentinel probe ..."
capture mata: __rals_loaded()
matrix `results'[3,1] = !_rc

*------------------------------------------------------------------------------
*  4-11. Run every command on bundled sp500 data
*------------------------------------------------------------------------------
sysuse sp500, clear
gen t = _n
tsset t

di _n as text "[ 4/15 ] ralsdiag ..."
capture noisily ralsdiag close, trend
matrix `results'[4,1] = !_rc

di _n as text "[ 5/15 ] ralsadf ..."
capture noisily ralsadf close, trend
matrix `results'[5,1] = !_rc

di _n as text "[ 6/15 ] ralslm ..."
capture noisily ralslm close
matrix `results'[6,1] = !_rc

di _n as text "[ 7/15 ] ralslmb ..."
capture noisily ralslmb close, model(2) breaks(1)
matrix `results'[7,1] = !_rc

di _n as text "[ 8/15 ] ralsfadf ..."
capture noisily ralsfadf close, trend
matrix `results'[8,1] = !_rc

di _n as text "[ 9/15 ] ralsfkss ..."
capture noisily ralsfkss close, trend
matrix `results'[9,1] = !_rc

di _n as text "[10/15 ] ralscoint ..."
capture noisily ralscoint close volume open, trend
matrix `results'[10,1] = !_rc

di _n as text "[11/15 ] ralsfadl ..."
capture noisily ralsfadl close volume open, trend
matrix `results'[11,1] = !_rc

*------------------------------------------------------------------------------
*  12-13. Battery driver -- single variable then multivariate
*------------------------------------------------------------------------------
di _n as text "[12/15 ] ralsbattery (one variable) ..."
capture noisily ralsbattery close, trend
matrix `results'[12,1] = !_rc

di _n as text "[13/15 ] ralsbattery (multivariate + cointegration) ..."
capture noisily ralsbattery close volume open, trend
matrix `results'[13,1] = !_rc

*------------------------------------------------------------------------------
*  14. Mata workspace persistence -- probe several known functions
*------------------------------------------------------------------------------
di _n as text "[14/15 ] Mata workspace persistence ..."

* `direxternal' lists Mata external variables, NOT functions, so we cannot
* count functions that way.  Probe a handful of known functions directly.
local nfuncs = 0

capture mata: __rals_loaded()
if !_rc local ++nfuncs

capture mata: __rals_chk_ = __rals_cv_lm()
if !_rc local ++nfuncs
capture mata: mata drop __rals_chk_

capture mata: __rals_chk_ = __rals_cv_adf(1)
if !_rc local ++nfuncs
capture mata: mata drop __rals_chk_

capture mata: __rals_chk_ = __rals_cv_df(100, 2)
if !_rc local ++nfuncs
capture mata: mata drop __rals_chk_

if `nfuncs' >= 4 {
    matrix `results'[14,1] = 1
    di as text "         " as result "`nfuncs'/4" as text " sentinel probes responded -- Mata workspace is persistent."
}
else {
    di as error "         only `nfuncs'/4 probes responded -- loader failed."
}

*------------------------------------------------------------------------------
*  15. Help pages -- check each .sthlp loads
*------------------------------------------------------------------------------
di _n as text "[15/15 ] Help pages ..."
local helps  "rals ralsadf ralslm ralslmb ralsfadf ralsfkss ralsbattery ralscoint ralsfadl ralsdiag"
local hok = 1
foreach h of local helps {
    capture viewsource `h'.sthlp
    if _rc {
        di as error "         help `h' missing!"
        local hok = 0
    }
}
matrix `results'[15,1] = `hok'

*------------------------------------------------------------------------------
*  Final summary
*------------------------------------------------------------------------------
di _n as text "{hline 78}"
di as result "  RALS self-test summary"
di as text "{hline 78}"

local total = 15
local passed = 0
local i 1
foreach name of local rownames {
    local v = `results'[`i',1]
    if `v' {
        di as text   "  [" as result "PASS" as text "]  " "`name'"
        local ++passed
    }
    else {
        di as text   "  [" as err    "FAIL" as text "]  " "`name'"
    }
    local ++i
}
di as text "{hline 78}"
di as result "  " `passed' "/" `total' " checks passed."
di as text "{hline 78}"

if `passed' == `total' {
    di as result _n "  ALL TESTS PASSED. The rals package is fully functional."
}
else {
    di as error _n "  Some tests failed; inspect the per-step output above for details."
}
