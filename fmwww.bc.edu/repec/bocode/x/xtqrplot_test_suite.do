// ====================================================================
// xtqrplot_test_suite.do  v1.3.0
// Pre-submission test suite -- run top to bottom.
// All results printed as [PASS] or [FAIL].
// Zero FAIL lines = ready for SSC submission.
// ====================================================================

version 14.0
clear all
set more off
cap log close
log using "C:\Users\NOMAN ARSHED\ado\personal\xtqrplot_test_log.txt", text replace

program drop _all
discard

di _n "========================================================"
di    "  xtqrplot v1.3.0  --  Pre-submission Test Suite"
di    "  $(c(current_date)) $(c(current_time))"
di    "========================================================"

// ----------------------------------------------------------------
// HELPER: capture rc into a local BEFORE calling check_rc
// Usage:
//   capture xtqrplot ...
//   local rc = _rc
//   check_rc "label" expected_rc rc
// ----------------------------------------------------------------
program define check_rc
    args testname expected got
    // got is passed as a local name -- evaluate it
    if `got' == `expected' {
        di as text "  [PASS] `testname'"
    }
    else {
        di as error "  [FAIL] `testname'  (expected rc=`expected', got rc=`got')"
    }
end

// ----------------------------------------------------------------
// SETUP: balanced 10x10 panel, skewed x2
// ----------------------------------------------------------------
di _n "--- SETUP ---"
set seed 2024
set obs 100
gen country_id = ceil(_n/10)
gen year        = mod(_n-1,10) + 2010
gen x1 = rnormal(2,1)
gen u1 = runiform()
gen u2 = runiform()
gen x2 = -ln(u1) - ln(u2) - 2
drop u1 u2
gen fe  = rnormal(0,0.8)
bysort country_id: replace fe = fe[1]
gen eps = rnormal(0,1)*(1 + 0.5*abs(x2))
gen y   = 1 + 0.4*x1 + 0.3*x2 + fe + eps
label define clab 1 "Argentina" 2 "Brazil"  3 "Chile"   4 "Colombia" ///
                  5 "Ecuador"   6 "Mexico"   7 "Panama"  8 "Peru"     ///
                  9 "Uruguay"  10 "Venezuela"
label values country_id clab
label variable y  "GDP Growth"
label variable x1 "Trade Openness"
label variable x2 "Investment Shock"
xtset country_id year
di "  Setup complete: 100 obs, 10 countries, 10 years"

// ================================================================
// BLOCK 1: INPUT VALIDATION
// ================================================================
di _n "--- BLOCK 1: Input Validation ---"

capture xtqrplot y x1, panelvar(country_id) timevar(year) method(abc)
local rc = _rc
check_rc "T01 invalid method()" 198 `rc'

capture xtqrplot y x1, panelvar(country_id) timevar(year) effect(xyz)
local rc = _rc
check_rc "T02 invalid effect()" 198 `rc'

capture xtqrplot y x1, panelvar(country_id) timevar(year) plottype(diagonal)
local rc = _rc
check_rc "T03 invalid plottype()" 198 `rc'

capture xtqrplot y x1, panelvar(country_id) timevar(year) nwindows(0)
local rc = _rc
check_rc "T04 nwindows(0) out of range" 198 `rc'

capture xtqrplot y x1, panelvar(country_id) timevar(year) nwindows(50)
local rc = _rc
check_rc "T05 nwindows(50) out of range" 198 `rc'

capture xtqrplot y x1 if y > 9999, panelvar(country_id) timevar(year)
local rc = _rc
check_rc "T06 empty sample" 2000 `rc'

// ================================================================
// BLOCK 2: BASIC ESTIMATION
// ================================================================
di _n "--- BLOCK 2: Basic xtqreg estimation ---"

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T07 default cross-section plot" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    effect(semi) nonormal
local rc = _rc
check_rc "T08 effect(semi)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    effect(elast) nonormal
local rc = _rc
check_rc "T09 effect(elast)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    effect(bp) nonormal
local rc = _rc
check_rc "T10 effect(bp)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(time) nonormal
local rc = _rc
check_rc "T11 plottype(time)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(twoway) nonormal
local rc = _rc
check_rc "T12 plottype(twoway)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    nwindows(4) nonormal
local rc = _rc
check_rc "T13 nwindows(4)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    nwindows(19) nonormal
local rc = _rc
check_rc "T14 nwindows(19)" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    noplot nonormal
local rc = _rc
check_rc "T15 noplot" 0 `rc'

capture xtqrplot y x1, panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T16 nonormal only" 0 `rc'

// ================================================================
// BLOCK 3: SAVING OUTPUT
// ================================================================
di _n "--- BLOCK 3: Saving output ---"

// Create output directory
capture mkdir test_output

// T17: cross dataset saved
capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    noplot nonormal saving(test_output/t17) replace
local rc = _rc
check_rc "T17 saving(cross) no error" 0 `rc'

capture confirm file "test_output/t17_cross.dta"
local rc = _rc
check_rc "T17b cross dta file exists on disk" 0 `rc'

// T18: time dataset saved
capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(time) noplot nonormal saving(test_output/t18) replace
local rc = _rc
check_rc "T18 saving(time)" 0 `rc'

capture confirm file "test_output/t18_time.dta"
local rc = _rc
check_rc "T18b time dta file exists" 0 `rc'

// T19: twoway dataset saved
capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(twoway) noplot nonormal saving(test_output/t19) replace
local rc = _rc
check_rc "T19 saving(twoway)" 0 `rc'

capture confirm file "test_output/t19_twoway.dta"
local rc = _rc
check_rc "T19b twoway dta file exists" 0 `rc'

// T20: overwrite protection -- file exists, no replace = should fail with 602
capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    noplot nonormal saving(test_output/t17)
local rc = _rc
check_rc "T20 no replace blocked with rc=602" 602 `rc'

// T21: replace allowed
capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    noplot nonormal saving(test_output/t17) replace
local rc = _rc
check_rc "T21 saving with replace allowed" 0 `rc'

// ================================================================
// BLOCK 4: SAVED DATASET CONTENT
// ================================================================
di _n "--- BLOCK 4: Saved dataset content ---"

capture use "test_output/t17_cross.dta", clear
local rc = _rc
check_rc "T22a saved dataset loads cleanly" 0 `rc'

if `rc' == 0 {
    capture confirm variable _my _pctrank _q_win _eff1 _eff2
    local rc = _rc
    check_rc "T22b required variables present" 0 `rc'

    capture confirm variable _eff1_lo _eff1_hi _eff2_lo _eff2_hi
    local rc = _rc
    check_rc "T23 CI bound variables present" 0 `rc'

    quietly count if missing(_eff1)
    if r(N) == 0 di as text "  [PASS] T24 no missing _eff1 values"
    else         di as error "  [FAIL] T24 `r(N)' missing _eff1 values"

    quietly count if _pctrank < 0 | _pctrank > 100
    if r(N) == 0 di as text "  [PASS] T25 _pctrank in [0,100]"
    else         di as error "  [FAIL] T25 _pctrank out of range"

    quietly count if _q_win <= 0 | _q_win >= 100
    if r(N) == 0 di as text "  [PASS] T26 _q_win in (0,100)"
    else         di as error "  [FAIL] T26 _q_win out of (0,100)"

    // CI bounds: lo <= eff <= hi
    quietly count if _eff1_lo > _eff1 & !missing(_eff1)
    if r(N) == 0 di as text "  [PASS] T27 _eff1_lo <= _eff1 always"
    else         di as error "  [FAIL] T27 CI lower bound exceeds point estimate"

    quietly count if _eff1_hi < _eff1 & !missing(_eff1)
    if r(N) == 0 di as text "  [PASS] T28 _eff1_hi >= _eff1 always"
    else         di as error "  [FAIL] T28 CI upper bound below point estimate"
}
else {
    di as error "  [SKIP] T22b-T28 skipped because dataset did not load"
}

// ================================================================
// BLOCK 5: SINGLE VARIABLE
// ================================================================
di _n "--- BLOCK 5: Single independent variable ---"
xtset country_id year

capture xtqrplot y x1, panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T29 single regressor cross" 0 `rc'

capture xtqrplot y x1, panelvar(country_id) timevar(year) ///
    plottype(twoway) nonormal
local rc = _rc
check_rc "T30 single regressor twoway" 0 `rc'

// ================================================================
// BLOCK 6: UNBALANCED PANEL
// ================================================================
di _n "--- BLOCK 6: Unbalanced panel ---"
preserve
set seed 999
gen _dropme = runiform() < 0.15
drop if _dropme
xtset country_id year

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T31 unbalanced panel cross" 0 `rc'

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    plottype(twoway) nonormal
local rc = _rc
check_rc "T32 unbalanced panel twoway" 0 `rc'
restore

// ================================================================
// BLOCK 7: IF / IN SUBSETTING
// ================================================================
di _n "--- BLOCK 7: if/in subsetting ---"
xtset country_id year

capture xtqrplot y x1 x2 if year >= 2013, ///
    panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T33 if year >= 2013" 0 `rc'

capture xtqrplot y x1 x2 in 1/80, ///
    panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T34 in 1/80" 0 `rc'

// ================================================================
// BLOCK 8: NORMALITY DIAGNOSTICS
// ================================================================
di _n "--- BLOCK 8: Normality diagnostics ---"

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    noplot nwindows(4)
local rc = _rc
check_rc "T35 normality diagnostics complete" 0 `rc'

// ================================================================
// BLOCK 9: NUMERIC ID WITHOUT LABELS
// ================================================================
di _n "--- BLOCK 9: Numeric panel ID, no value labels ---"
preserve
label drop clab
capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T36 numeric ID without value labels" 0 `rc'
restore

// ================================================================
// BLOCK 10: EDGE CASES
// ================================================================
di _n "--- BLOCK 10: Edge cases ---"

capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
    nwindows(1) nonormal
local rc = _rc
check_rc "T37 nwindows(1) median only" 0 `rc'

gen x3 = rnormal(0,1)
capture xtqrplot y x1 x2 x3, panelvar(country_id) timevar(year) nonormal
local rc = _rc
check_rc "T38 three regressors" 0 `rc'
drop x3

quietly summarize y
if r(min) > 0 {
    capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
        effect(elast) nonormal
    local rc = _rc
    check_rc "T39 effect(elast) with Y > 0" 0 `rc'
}
else {
    di as text "  [SKIP] T39 Y has non-positive values in this sample"
}

// All effect types x all plot types grid
di _n "--- BLOCK 11: Effect x plottype grid ---"
foreach eff in coef semi elast bp {
    foreach plt in cross time twoway {
        capture xtqrplot y x1 x2, panelvar(country_id) timevar(year) ///
            effect(`eff') plottype(`plt') noplot nonormal nwindows(4)
        local rc = _rc
        check_rc "T40 effect(`eff') plottype(`plt')" 0 `rc'
    }
}

// ================================================================
// SUMMARY
// ================================================================
di _n "========================================================"
di    "  Test suite complete."
di    "  Scan above for any [FAIL] lines."
di    "  Zero FAIL = ready for SSC submission."
di    "========================================================"

log close
