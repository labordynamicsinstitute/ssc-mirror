*! xtlmbreak_example.do
*! Complete example and test do-file for xtlmbreak
*! Westerlund (2006) Panel LM Cointegration Test with Structural Breaks
*!
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0 — 25 March 2026

clear all
set more off

* Add the xtlmbreak directory to Stata's search path
adopath + "c:\Users\HP\Documents\xtpmg\lmbreak"

* ============================================================
* PART 1: COINTEGRATED PANEL (no breaks)
*         DGP from Westerlund (2006, Section VI)
*         y_it = c_i + x_it * b_i + e_it
*         x_it = x_{i,t-1} + v_it
*         e_it = u_it  (under H0: phi=0)
*         (u_it, v_it) ~ bivariate Normal, corr = 0.4
* ============================================================

di _n(3) "{hline 78}"
di "{bf:PART 1: Cointegrated panel — NO structural breaks}"
di "{hline 78}"

local N = 10
local T = 100

set obs `= `N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t

set seed 54321
gen double v = rnormal()
gen double u = 0.4 * v + rnormal() * sqrt(1 - 0.16)

bysort id (t): gen double x = sum(v)
gen double e = u

gen double b_i = .
gen double c_i = .
forvalues i = 1/`N' {
  qui replace b_i = rnormal(1, 1) if id == `i' & t == 1
  qui replace c_i = rnormal(1, 1) if id == `i' & t == 1
}
bysort id (t): replace b_i = b_i[1]
bysort id (t): replace c_i = c_i[1]

gen double y = c_i + x * b_i + e

xtsum y x

* ---- Test 1: Case 2 (intercept) — DOLS [correctly specified] ----
di _n "{hline 78}"
di "{bf:Test 1: Case 2 (intercept) — DOLS}"
di "Expected: Fail to reject (data IS cointegrated)"
di "{hline 78}"

xtlmbreak y x, model(intercept) estimator(dols)

local Z1 = r(Z_M)
local p1 = r(p_value)

* ---- Test 2: Case 3 (trend) — DOLS ----
di _n "{hline 78}"
di "{bf:Test 2: Case 3 (trend) — DOLS}"
di "Expected: Fail to reject (overspecified but still valid)"
di "{hline 78}"

xtlmbreak y x, model(trend)

local Z2 = r(Z_M)
local p2 = r(p_value)

* ---- Test 3: Case 1 (none) — DOLS [misspecified] ----
di _n "{hline 78}"
di "{bf:Test 3: Case 1 (none) — DOLS}"
di "Expected: REJECT (model omits intercepts → spurious rejection)"
di "{hline 78}"

xtlmbreak y x, model(none)

local Z3 = r(Z_M)
local p3 = r(p_value)

* ---- Test 4: Case 2 — FMOLS ----
di _n "{hline 78}"
di "{bf:Test 4: Case 2 (intercept) — FMOLS}"
di "Expected: Fail to reject (both estimators should agree)"
di "{hline 78}"

xtlmbreak y x, model(intercept) estimator(fmols)

local Z4 = r(Z_M)
local p4 = r(p_value)

* ---- Test 5: Case 4 (level break) — no true breaks ----
di _n "{hline 78}"
di "{bf:Test 5: Case 4 (level break) — DOLS}"
di "Expected: Fail to reject, BIC should select 0 breaks"
di "{hline 78}"

xtlmbreak y x, model(levelbreak) maxbreaks(3)

local Z5 = r(Z_M)
local p5 = r(p_value)


* ============================================================
* PART 2: COINTEGRATED PANEL WITH STRUCTURAL BREAKS
*         y_it = c_ij + x_it * b_i + e_it
*         c_ij shifts at known break dates
* ============================================================

clear
di _n(3) "{hline 78}"
di "{bf:PART 2: Cointegrated panel WITH structural breaks}"
di "{hline 78}"

local N = 10
local T = 200

set obs `= `N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t

set seed 99999
gen double v = rnormal()
gen double u = 0.3 * v + rnormal() * sqrt(1 - 0.09)

bysort id (t): gen double x = sum(v)
gen double e = u

gen double c_i = .
gen double b_i = .
gen double shift = 0

di _n "True break dates and shift sizes:"
di "{hline 50}"
forvalues i = 1/`N' {
  local ci = rnormal(2, 1)
  local bi = rnormal(1, 0.5)
  local tb = 80 + floor((`i' - 1) * 60 / (`N' - 1))
  local shift_size = rnormal(3, 1)

  qui replace b_i = `bi' if id == `i'
  qui replace c_i = `ci' if id == `i'
  qui replace shift = `shift_size' * (t > `tb') if id == `i'

  di "  Panel " %2.0f `i' ":  break at t = " %3.0f `tb' ///
    ",  shift = " %6.2f `shift_size'
}
di "{hline 50}"

gen double y = c_i + shift + x * b_i + e

xtsum y x

* ---- Test 6: Case 4 (level break) with graph ----
di _n "{hline 78}"
di "{bf:Test 6: Case 4 (level break) — DOLS + graph}"
di "Expected: Fail to reject; break dates should match true dates"
di "{hline 78}"

xtlmbreak y x, model(levelbreak) maxbreaks(3) graph

local Z6 = r(Z_M)
local p6 = r(p_value)

* ---- Test 7: Case 5 (trend break) with graph ----
di _n "{hline 78}"
di "{bf:Test 7: Case 5 (trend break) — DOLS + graph}"
di "Expected: Fail to reject"
di "{hline 78}"

xtlmbreak y x, model(trendbreak) maxbreaks(3) graph

local Z7 = r(Z_M)
local p7 = r(p_value)

* ---- Test 8: Case 4, FMOLS ----
di _n "{hline 78}"
di "{bf:Test 8: Case 4 (level break) — FMOLS}"
di "Expected: Fail to reject"
di "{hline 78}"

xtlmbreak y x, model(levelbreak) maxbreaks(3) estimator(fmols)

local Z8 = r(Z_M)
local p8 = r(p_value)

* ---- Test 9: Case 2 WITHOUT accounting for breaks ----
di _n "{hline 78}"
di "{bf:Test 9: Case 2 (intercept) — ignoring true breaks}"
di "Expected: May REJECT — omitting breaks causes size distortions"
di "{hline 78}"

xtlmbreak y x, model(intercept)

local Z9 = r(Z_M)
local p9 = r(p_value)


* ============================================================
* PART 3: NON-COINTEGRATED PANEL (phi > 0)
*         Under H1: e_it = r_it + u_it, r_it = r_{i,t-1} + u_it
* ============================================================

clear
di _n(3) "{hline 78}"
di "{bf:PART 3: Non-cointegrated panel (phi = 1)}"
di "{hline 78}"

local N = 10
local T = 100

set obs `= `N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t

set seed 11111
gen double v = rnormal()
gen double u = rnormal()

bysort id (t): gen double x = sum(v)
bysort id (t): gen double r = sum(u)
gen double y = 1 + x + r

xtsum y x

* ---- Test 10: Should REJECT ----
di _n "{hline 78}"
di "{bf:Test 10: Case 2 — Non-cointegrated data}"
di "Expected: REJECT H0 (data is NOT cointegrated)"
di "{hline 78}"

xtlmbreak y x, model(intercept)

local Z10 = r(Z_M)
local p10 = r(p_value)


* ============================================================
* SUMMARY TABLE
* ============================================================

di _n(3) "{hline 78}"
di "{bf:                     SUMMARY OF ALL TEST RESULTS}"
di "{hline 78}"
di ""
di "  {hline 72}"
di "  Test  Model                   Est.    Z(M)      p-val   Result"
di "  {hline 72}"
di "  {bf:Part 1: Cointegrated, no breaks (N=10, T=100)}"
di %4s "  1" "    Case 2 (intercept)      DOLS" ///
  %10.4f `Z1' %10.4f `p1' _c
if `p1' >= 0.10 { 
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}
di %4s "  2" "    Case 3 (trend)          DOLS" ///
  %10.4f `Z2' %10.4f `p2' _c
if `p2' >= 0.10 {
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}
di %4s "  3" "    Case 1 (none)           DOLS" ///
  %10.4f `Z3' %10.4f `p3' _c
if `p3' < 0.05 {
  di "   {bf:OK} ✓ (expected reject)"
}
else {
  di "   FAIL ✗"
}
di %4s "  4" "    Case 2 (intercept)      FMOLS" ///
  %10.4f `Z4' %10.4f `p4' _c
if `p4' >= 0.10 {
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}
di %4s "  5" "    Case 4 (levelbreak)     DOLS" ///
  %10.4f `Z5' %10.4f `p5' _c
if `p5' >= 0.10 {
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}

di ""
di "  {bf:Part 2: Cointegrated WITH level breaks (N=10, T=200)}"
di %4s "  6" "    Case 4 (levelbreak)     DOLS" ///
  %10.4f `Z6' %10.4f `p6' _c
if `p6' >= 0.10 {
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}
di %4s "  7" "    Case 5 (trendbreak)     DOLS" ///
  %10.4f `Z7' %10.4f `p7' _c
if `p7' >= 0.10 {
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}
di %4s "  8" "    Case 4 (levelbreak)     FMOLS" ///
  %10.4f `Z8' %10.4f `p8' _c
if `p8' >= 0.10 {
  di "   {bf:OK} ✓"
}
else {
  di "   FAIL ✗"
}
di %4s "  9" "    Case 2 — ignore breaks  DOLS" ///
  %10.4f `Z9' %10.4f `p9' _c
if `p9' < 0.05 {
  di "   {bf:OK} ✓ (expected reject)"
}
else {
  di "   Ambiguous"
}

di ""
di "  {bf:Part 3: NOT cointegrated (phi=1, N=10, T=100)}"
di %4s "  10" "   Case 2 (intercept)      DOLS" ///
  %10.4f `Z10' %10.4f `p10' _c
if `p10' < 0.05 {
  di "   {bf:OK} ✓ (correctly rejects)"
}
else {
  di "   Low power"
}

di ""
di "  {hline 72}"
di ""
di "  Graphs saved: xtlmbreak_breaks.png, xtlmbreak_lm.png"
di ""
di "{hline 78}"
di "{bf:                       ALL TESTS COMPLETE}"
di "{hline 78}"
