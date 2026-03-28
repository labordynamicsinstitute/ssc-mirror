*! xtpunitcoint_example.do
*! Complete example and test do-file for the xtpunitcoint library
*! Tests all three panel tests with full visualisation:
*!   1. xtpcointegwe   — Westerlund & Edgerton (2008) cointegration
*!   2. xtpcointegboot — Westerlund & Edgerton (2007) bootstrap cointegration
*!   3. xtpkpss        — Carrion-i-Silvestre et al. (2005) panel KPSS
*!
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 2.0.0 — 26 March 2026

clear all
set more off
set seed 12345

* Add library to Stata path
adopath + "c:\Users\HP\Documents\xtpmg\xtpunitcoint"


* ============================================================
* PART 1: COINTEGRATED PANEL (no breaks)
*   y_it = a_i + x_it * b_i + e_it  (stationary e)
*   x_it = x_{i,t-1} + v_it  (random walk)
* ============================================================

di _n(3) "{hline 78}"
di "{bf:PART 1: Cointegrated panel data — NO structural breaks}"
di "{hline 78}"

local N = 10
local T = 100

set obs `= `N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t

gen double v = rnormal()
gen double u = 0.4*v + rnormal() * sqrt(1 - 0.16)

bysort id (t): gen double x = sum(v)
gen double e = u

* Individual-specific intercepts and slopes
gen double bb = .
gen double cc = .
forvalues i = 1/`N' {
  qui replace bb = rnormal(1, 0.5) if id == `i' & t == 1
  qui replace cc = rnormal(2, 1) if id == `i' & t == 1
}
bysort id (t): replace bb = bb[1]
bysort id (t): replace cc = cc[1]

gen double y = cc + x*bb + e

* ---- Test 1a: xtpcointegwe — no break ----
di _n(2) "{hline 78}"
di "{bf:Test 1a: xtpcointegwe — No break model}"
di "Expected: REJECT H0 (data IS cointegrated, so we reject no-cointegration)"
di "{hline 78}"

xtpcointegwe y x, model(nobreak) maxfactors(3)

local zt_1a = r(zt)
local pzt_1a = r(pval_zt)
local za_1a = r(za)
local pza_1a = r(pval_za)


* ---- Test 1b: xtpcointegboot — constant (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 1b: xtpcointegboot — Constant model, 99 bootstrap reps}"
di "Expected: Fail to reject H0 (data IS cointegrated)"
di "{hline 78}"

xtpcointegboot y x, model(constant) nboot(99) lags(2) graph

local lm_1b = r(lm)
local bp_1b = r(boot_pval)
local ap_1b = r(asym_pval)


* ---- Test 1c: xtpkpss — constant on stationary residuals (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 1c: xtpkpss — Constant model on stationary data}"
di "Expected: Fail to reject H0 (residuals are stationary)"
di "{hline 78}"

gen double e_stat = rnormal()
xtpkpss e_stat, model(constant) graph

local zhom_1c = r(z_hom)
local phom_1c = r(pval_hom)
local zhet_1c = r(z_het)
local phet_1c = r(pval_het)


* ============================================================
* PART 2: COINTEGRATED PANEL WITH STRUCTURAL BREAKS
* ============================================================

clear
di _n(3) "{hline 78}"
di "{bf:PART 2: Cointegrated panel WITH structural breaks}"
di "{hline 78}"

local N = 8
local T = 150

set obs `= `N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t

set seed 67890
gen double v = rnormal()
gen double u = 0.3*v + rnormal()*sqrt(1-0.09)
bysort id (t): gen double x = sum(v)

gen double shift = 0
gen double bb = .
gen double cc = .

forvalues i = 1/`N' {
  local ci = rnormal(2, 1)
  local bi = rnormal(1, 0.5)
  local tb = 50 + floor((`i'-1)*50/(`N'-1))
  local ss = rnormal(3, 1)
  qui replace bb = `bi' if id == `i'
  qui replace cc = `ci' if id == `i'
  qui replace shift = `ss'*(t > `tb') if id == `i'
}

gen double y = cc + shift + x*bb + u

* ---- Test 2a: xtpcointegwe — level shift (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 2a: xtpcointegwe — Level shift model with graph}"
di "Expected: REJECT H0 (data is cointegrated with breaks)"
di "{hline 78}"

xtpcointegwe y x, model(levelshift) trim(0.15) maxfactors(3) graph

local zt_2a = r(zt)
local pzt_2a = r(pval_zt)
local za_2a = r(za)
local pza_2a = r(pval_za)

* ---- Test 2b: xtpcointegwe — regime shift (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 2b: xtpcointegwe — Regime shift model with graph}"
di "Expected: REJECT H0"
di "{hline 78}"

xtpcointegwe y x, model(regimeshift) trim(0.15) maxfactors(3) graph

local zt_2b = r(zt)
local pzt_2b = r(pval_zt)
local za_2b = r(za)
local pza_2b = r(pval_za)


* ---- Test 2c: xtpcointegboot — trend model (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 2c: xtpcointegboot — Trend model with bootstrap}"
di "Expected: Fail to reject H0 (data IS cointegrated)"
di "{hline 78}"

xtpcointegboot y x, model(trend) estimator(yw) nboot(99) graph

local lm_2c = r(lm)
local bp_2c = r(boot_pval)
local ap_2c = r(asym_pval)


* ---- Test 2d: xtpkpss — constbreak (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 2d: xtpkpss — Constant + breaks on stationary + shift data}"
di "Expected: Fail to reject H0 (stationary with breaks)"
di "{hline 78}"

gen double e_brk = u + shift
xtpkpss e_brk, model(constbreak) maxbreaks(3) graph

local zhom_2d = r(z_hom)
local phom_2d = r(pval_hom)
local zhet_2d = r(z_het)
local phet_2d = r(pval_het)


* ---- Test 2e: xtpkpss — trendbreak (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 2e: xtpkpss — Trend + breaks model}"
di "Expected: Varies"
di "{hline 78}"

xtpkpss e_brk, model(trendbreak) maxbreaks(3) graph

local zhom_2e = r(z_hom)
local phom_2e = r(pval_hom)
local zhet_2e = r(z_het)
local phet_2e = r(pval_het)


* ============================================================
* PART 3: NON-COINTEGRATED PANEL (spurious regression)
* ============================================================

clear
di _n(3) "{hline 78}"
di "{bf:PART 3: Non-cointegrated panel (spurious regression)}"
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

* ---- Test 3a: xtpcointegwe — should fail to reject (no cointegration) ----
di _n(2) "{hline 78}"
di "{bf:Test 3a: xtpcointegwe — Non-cointegrated data}"
di "Expected: Fail to reject H0 (data is NOT cointegrated)"
di "{hline 78}"

xtpcointegwe y x, model(nobreak) maxfactors(2)

local zt_3a = r(zt)
local pzt_3a = r(pval_zt)
local za_3a = r(za)
local pza_3a = r(pval_za)

* ---- Test 3b: xtpcointegboot — should REJECT H0 of cointegration (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 3b: xtpcointegboot — Non-cointegrated data}"
di "Expected: REJECT H0 (data is NOT cointegrated)"
di "{hline 78}"

xtpcointegboot y x, model(constant) nboot(99) lags(2) graph

local lm_3b = r(lm)
local bp_3b = r(boot_pval)
local ap_3b = r(asym_pval)

* ---- Test 3c: xtpcointegboot — OLS estimator variant (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 3c: xtpcointegboot — OLS estimator on non-cointegrated data}"
di "Expected: REJECT H0"
di "{hline 78}"

xtpcointegboot y x, model(constant) estimator(ols) nboot(99) lags(2) graph

local lm_3c = r(lm)
local bp_3c = r(boot_pval)
local ap_3c = r(asym_pval)


* ============================================================
* PART 4: UNIT ROOT PANEL (for KPSS)
* ============================================================

clear
di _n(3) "{hline 78}"
di "{bf:PART 4: Unit root panel (for KPSS power test)}"
di "{hline 78}"

local N = 10
local T = 100

set obs `= `N' * `T''
gen id = ceil(_n / `T')
bysort id: gen t = _n
xtset id t

set seed 22222
bysort id (t): gen double y_rw = sum(rnormal())

* ---- Test 4a: xtpkpss — should REJECT stationarity (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 4a: xtpkpss — Unit root data (constant model)}"
di "Expected: REJECT H0 (data has unit root, not stationary)"
di "{hline 78}"

xtpkpss y_rw, model(constant) graph

local zhom_4a = r(z_hom)
local phom_4a = r(pval_hom)
local zhet_4a = r(z_het)
local phet_4a = r(pval_het)

* ---- Test 4b: xtpkpss — trend model (with graph) ----
di _n(2) "{hline 78}"
di "{bf:Test 4b: xtpkpss — Unit root data (trend model)}"
di "Expected: REJECT H0"
di "{hline 78}"

xtpkpss y_rw, model(trend) graph

local zhom_4b = r(z_hom)
local phom_4b = r(pval_hom)
local zhet_4b = r(z_het)
local phet_4b = r(pval_het)

* ---- Test 4c: xtpkpss — QS kernel variant ----
di _n(2) "{hline 78}"
di "{bf:Test 4c: xtpkpss — Unit root data (QS kernel)}"
di "Expected: REJECT H0"
di "{hline 78}"

xtpkpss y_rw, model(constant) kernel(qs) bandwidth(6)

local zhom_4c = r(z_hom)
local phom_4c = r(pval_hom)


* ============================================================
* SUMMARY TABLE
* ============================================================

di _n(3) "{hline 78}"
di "{bf:                    SUMMARY OF ALL TEST RESULTS}"
di "{hline 78}"
di
di " {hline 74}"
di "  Test   Command            Setting                  Stat    p-value  OK?"
di " {hline 74}"
di

di "  {bf:Part 1: Cointegrated, no breaks (N=10, T=100)}"
di %4s "  1a" "   xtpcointegwe       No break (PD Tau)      " ///
  %10.4f `zt_1a' %10.4f `pzt_1a' _c
if `pzt_1a' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  1b" "   xtpcointegboot     Constant (bootstrap)   " ///
  %10.4f `lm_1b' %10.4f `bp_1b' _c
if `bp_1b' >= 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  1c" "   xtpkpss            Constant Z(hom)        " ///
  %10.4f `zhom_1c' %10.4f `phom_1c' _c
if `phom_1c' >= 0.10 {
  di "   Yes"
}
else {
  di "   --"
}

di
di "  {bf:Part 2: Cointegrated WITH breaks (N=8, T=150)}"
di %4s "  2a" "   xtpcointegwe       Level shift (PD Tau)   " ///
  %10.4f `zt_2a' %10.4f `pzt_2a' _c
if `pzt_2a' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  2b" "   xtpcointegwe       Regime shift (PD Tau)  " ///
  %10.4f `zt_2b' %10.4f `pzt_2b' _c
if `pzt_2b' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  2c" "   xtpcointegboot     Trend (bootstrap)      " ///
  %10.4f `lm_2c' %10.4f `bp_2c' _c
if `bp_2c' >= 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  2d" "   xtpkpss            Const+breaks Z(hom)    " ///
  %10.4f `zhom_2d' %10.4f `phom_2d' _c
if `phom_2d' >= 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  2e" "   xtpkpss            Trend+breaks Z(hom)    " ///
  %10.4f `zhom_2e' %10.4f `phom_2e' _c
if `phom_2e' >= 0.10 {
  di "   Yes"
}
else {
  di "   --"
}

di
di "  {bf:Part 3: NOT cointegrated (N=10, T=100)}"
di %4s "  3a" "   xtpcointegwe       No break (PD Tau)      " ///
  %10.4f `zt_3a' %10.4f `pzt_3a' _c
if `pzt_3a' >= 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  3b" "   xtpcointegboot     Constant (YW, boot)    " ///
  %10.4f `lm_3b' %10.4f `bp_3b' _c
if `bp_3b' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  3c" "   xtpcointegboot     Constant (OLS, boot)   " ///
  %10.4f `lm_3c' %10.4f `bp_3c' _c
if `bp_3c' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}

di
di "  {bf:Part 4: Unit root (N=10, T=100)}"
di %4s "  4a" "   xtpkpss            Constant Z(hom)        " ///
  %10.4f `zhom_4a' %10.4f `phom_4a' _c
if `phom_4a' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  4b" "   xtpkpss            Trend Z(hom)           " ///
  %10.4f `zhom_4b' %10.4f `phom_4b' _c
if `phom_4b' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}
di %4s "  4c" "   xtpkpss            Constant QS-kernel     " ///
  %10.4f `zhom_4c' %10.4f `phom_4c' _c
if `phom_4c' < 0.10 {
  di "   Yes"
}
else {
  di "   --"
}

di
di " {hline 74}"
di
di "{hline 78}"
di "{bf:                       ALL TESTS COMPLETE}"
di "{hline 78}"
di
di "  Graphs generated:"
di "    1b  xtpcointegboot_dist  — Bootstrap distribution histogram"
di "    1c  xtpkpss_kpss         — KPSS bar chart (constant, no breaks)"
di "    2a  xtpcointegwe_breaks  — Line graph with level shift breaks"
di "    2b  xtpcointegwe_breaks  — Line graph with regime shift breaks"
di "    2c  xtpcointegboot_dist  — Bootstrap distribution histogram (trend)"
di "    2d  xtpkpss_kpss + xtpkpss_breaks — KPSS + break timeline (constbreak)"
di "    2e  xtpkpss_kpss + xtpkpss_breaks — KPSS + break timeline (trendbreak)"
di "    3b  xtpcointegboot_dist  — Bootstrap distribution histogram"
di "    3c  xtpcointegboot_dist  — Bootstrap distribution histogram (OLS)"
di "    4a  xtpkpss_kpss         — KPSS bar chart (constant, unit root)"
di "    4b  xtpkpss_kpss         — KPSS bar chart (trend, unit root)"
di "{hline 78}"
