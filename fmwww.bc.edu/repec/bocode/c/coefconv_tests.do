*! coefconv v1.1.0 — test script
*! Verifies Family 8, plot option, gybench, and negative-Pratt detection.
*! Run after installing or copying coefconv.ado v1.1.0 to your adopath.
*! ─────────────────────────────────────────────────────────────────

clear all
set more off
capture log close
log using coefconv_v1_1_0_tests.log, replace text

di _newline _newline ///
   "=================================================================="
di "  TEST 1: Cross-sectional (auto) — Family 8 partial, no gY"
di "=================================================================="
di "Expected: Family 8 rows for sigmaY and IQR populated;"
di "          period and attribution rows MISSING (no tsset)."
di "          Plot shows 4 bars (no Y-period, no growth attribution)."

sysuse auto, clear
regress price mpg weight foreign
coefconv

* Plot — auto has no time structure, so only 4 of 6 bars per IV
coefconv, plot

* Confirm returned scalars
di _newline "Returned scalars (selected):"
di "  r(has_time)         = " r(has_time)       "  (expect 0)"
di "  r(gY_src)           = " r(gY_src)         "  (expect n/a)"
di "  r(gY)               = " r(gY)             "  (expect .)"
di "  r(ref_sd_weight)    = " r(ref_sd_weight)
di "  r(ref_iqr_weight)   = " r(ref_iqr_weight)
di "  r(ref_period_weight)= " r(ref_period_weight) "  (expect .)"
di "  r(ref_attrib_weight)= " r(ref_attrib_weight) "  (expect .)"


di _newline _newline ///
   "=================================================================="
di "  TEST 2: Cross-sectional + gybench(0.02) — period populated"
di "=================================================================="
di "Expected: ref_period now NUMERIC (uses USER 2% benchmark);"
di "          attribution still MISSING (gX needs tsset/xtset);"
di "          header reads 'Y growth: 2.0000% (USER benchmark)'."

coefconv, gybench(0.02) plot

di _newline "Returned scalars:"
di "  r(gY_src)            = " r(gY_src)              "  (expect USER)"
di "  r(gY)                = " r(gY)                  "  (expect 0.02)"
di "  r(ref_period_weight) = " r(ref_period_weight)   "  (expect numeric)"
di "  r(ref_attrib_weight) = " r(ref_attrib_weight)   "  (expect . — no gX)"


di _newline _newline ///
   "=================================================================="
di "  TEST 3: Panel (grunfeld) — Family 8 fully populated"
di "=================================================================="
di "Expected: header reads 'Y growth: x.xx% (OBSERVED)';"
di "          all six Family 8 bars present per IV;"
di "          attribution metric numeric for both mvalue and kstock."

webuse grunfeld, clear
xtset company year
xtreg invest mvalue kstock, fe
coefconv, plot

di _newline "Returned scalars:"
di "  r(has_time)            = " r(has_time)               "  (expect 1)"
di "  r(gY_src)              = " r(gY_src)                 "  (expect OBSERVED)"
di "  r(gY)                  = " r(gY)
di "  r(gX_mvalue)           = " r(gX_mvalue)
di "  r(gX_kstock)           = " r(gX_kstock)
di "  r(ref_attrib_mvalue)   = " r(ref_attrib_mvalue)
di "  r(ref_attrib_kstock)   = " r(ref_attrib_kstock)


di _newline _newline ///
   "=================================================================="
di "  TEST 4: Negative-Pratt detection (squared term)"
di "=================================================================="
di "Expected: Pratt summary shows one negative %, followed by the"
di "          explanatory note on negative Pratt components."

sysuse auto, clear
regress price c.mpg##c.mpg weight foreign
coefconv


di _newline _newline ///
   "=================================================================="
di "  TEST 5: notable still returns Pratt% (v1.0.0 had a gap here)"
di "=================================================================="
di "Expected: r(pratt_pct_weight) is numeric, even though nothing"
di "          was displayed."

sysuse auto, clear
regress price mpg weight foreign
coefconv, notable
di "  r(pratt_pct_weight) = " r(pratt_pct_weight) "  (expect numeric, not .)"
di "  r(pratt_pct_mpg)    = " r(pratt_pct_mpg)


di _newline _newline ///
   "=================================================================="
di "  TEST 6: saving() includes Family 8 columns + gX"
di "=================================================================="

sysuse auto, clear
regress price mpg weight foreign
coefconv, saving(coefconv_v1_1_0_results, replace) notable

preserve
    use coefconv_v1_1_0_results, clear
    describe varname beta ref_pctY ref_sd ref_iqr ref_period ref_attrib gX_v
    list varname beta ref_sd ref_iqr ref_attrib, noobs abbreviate(15)
restore


di _newline _newline ///
   "=================================================================="
di "  ALL TESTS COMPLETE — review log file for any unexpected output"
di "=================================================================="

log close
