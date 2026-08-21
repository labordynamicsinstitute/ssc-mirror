*------------------------------------------------------------------------------
* xtbfkbreak_diagnose.do
* Regression test for the r(509) bug fixed in version 1.0.1.
*
* THE BUG.  The display routine computed
*       local kcoef = colsof(e(b))
* Under -version 14- control, colsof() requires a matrix NAME; e(b) is a matrix
* operand, so the scalar expression fails with
*       matrix operators that return matrices not allowed in this context
* r(509).  The estimation had already completed, and all display happens inside
* that routine, so the symptom was an error with NO output at all -- which made
* it look like an estimation failure rather than a display one.
*
* Under -version 15- or later the same expression is accepted, which is why
* other packages using the identical idiom are unaffected.  Part 1 below proves
* the mechanism.
*
* THE FIX.  Copy e(b) into a real matrix first, then take colsof() of that.
*
* Dr Merwan Roudane -- merwanroudane920@gmail.com
* RUN:  do xtbfkbreak_diagnose.do
*------------------------------------------------------------------------------
version 14.0
set more off
capture log close _all
log using "xtbfkbreak_diagnose.smcl", replace name(bfkdx)

di as text _n "{hline 79}"
di as text "xtbfkbreak 1.0.1 -- regression test for the r(509) display bug"
di as text "{hline 79}"

/*==============================================================================
  PART 1 -- prove the mechanism, independently of xtbfkbreak
==============================================================================*/
di as text _n "1. The mechanism: colsof(e(b)) under different version control"
di as text "{hline 79}"
sysuse auto, clear
qui regress price mpg weight

capture noisily version 14: local k1 = colsof(e(b))
di as text "   version 14: local k = colsof(e(b))      _rc = " as result _rc ///
    as text "   (expect 509)"

tempname bb
matrix `bb' = e(b)
capture noisily version 14: local k2 = colsof(`bb')
di as text "   version 14: copy to a matrix first      _rc = " as result _rc ///
    as text "   (expect 0, k = `k2')"

capture noisily version 17: local k3 = colsof(e(b))
di as text "   version 17: local k = colsof(e(b))      _rc = " as result _rc ///
    as text "   (expect 0 -- why other packages are unaffected)"
di as text "{hline 79}"

/*==============================================================================
  PART 2 -- the panel that used to fail
==============================================================================*/
clear
set seed 1234
local N  = 20
local T  = 40
local k0 = 20

qui set obs `=`N'*`T''
qui gen long id = ceil(_n/`T')
qui bysort id: gen int t = _n
xtset id t
qui gen double vf = rnormal(0, sqrt(0.75)) if id==1
qui bysort t (id): replace vf = vf[1]
sort id t
qui by id: gen double f = vf if _n==1
qui by id: replace f = 0.5*f[_n-1] + vf if _n>1
foreach v in a_i G1i G2i b1i b2i g_i s2i {
    qui by id: gen double `v' = .
}
qui by id: replace a_i = rnormal(1,1)           if _n==1
qui by id: replace G1i = rnormal(0,sqrt(0.5))   if _n==1
qui by id: replace G2i = rnormal(0.5,sqrt(0.5)) if _n==1
qui by id: replace b1i = rnormal(1,0.2)         if _n==1
qui by id: replace b2i = rnormal(2,0.2)         if _n==1
qui by id: replace g_i = rnormal(0.2,sqrt(0.5)) if _n==1
qui by id: replace s2i = runiform(0.5,1.5)      if _n==1
foreach v in a_i G1i G2i b1i b2i g_i s2i {
    qui by id: replace `v' = `v'[1]
}
qui gen double x1 = G1i*f + rnormal(0,sqrt(0.75))
qui gen double x2 = G2i*f + rnormal(0,sqrt(0.50))
qui gen double ee = g_i*f + rnormal(0,sqrt(s2i))
qui gen byte post = (t > `k0')
qui gen double y  = a_i + (b1i + 0.2*post)*x1 + b2i*x2 + ee
qui keep id t y x1 x2
xtset id t

di as text _n "2. The failing call  (EXPECT: full table, _rc = 0)"
di as text "{hline 79}"
capture noisily xtbfkbreak y x1 x2, breaks(1)
local rc2 = _rc
di as text "   _rc = " as result `rc2'

di as text _n "3. Replay path  (EXPECT: reprints the table, _rc = 0)"
di as text "{hline 79}"
capture noisily xtbfkbreak
local rc3 = _rc
di as text "   _rc = " as result `rc3'

di as text _n "4. Option coverage  (EXPECT: all _rc = 0)"
di as text "{hline 79}"
local rc4 = 0
foreach o in "breaks(1)" "breaks(1) nocce" "breaks(1) noconstant" "breaks(2)" ///
             "breaks(1) trim(0.2)" "breaks(1) graph" {
    capture xtbfkbreak y x1 x2, `o'
    di as text %-30s "   `o'" " " as result %-8.0f _rc
    local rc4 = `rc4' + _rc
}
capture xtbfkbreak y x1, breaks(1)
di as text %-30s "   y x1, breaks(1)" " " as result %-8.0f _rc
local rc4 = `rc4' + _rc

di as text _n "5. Namespacing (1.0.1 also renamed the helpers)"
di as text "{hline 79}"
capture program drop Display
program define Display
    syntax [, * ]
    di as error "   FOREIGN Display ran -- namespacing failed"
    exit 198
end
capture noisily xtbfkbreak y x1 x2, breaks(1)
local rc5 = _rc
capture program drop Display
di as text "   with a foreign -Display- resident: _rc = " as result `rc5'

di as text _n "6. The pipeline this serves"
di as text "{hline 79}"
capture noisily xtflucbreak y x1 x2, cce
if (_rc==0) {
    di as text "   xtflucbreak khat = " as result r(khat) as text "  (true k0 = `k0')"
    qui capture xtbfkbreak y x1 x2, breaks(1)
    di as text "   xtbfkbreak _rc   = " as result _rc
    if (_rc==0) di as text "   xtbfkbreak break = " as result "`e(breaks)'"
}

di as text _n "{hline 79}"
di as text "VERDICT"
di as text "{hline 79}"
di as text "   step 2 estimate      _rc = " as result `rc2'
di as text "   step 3 replay        _rc = " as result `rc3'
di as text "   step 4 options (sum) _rc = " as result `rc4'
di as text "   step 5 namespacing   _rc = " as result `rc5'
di as text ""
if (`rc2'==0 & `rc3'==0 & `rc4'==0 & `rc5'==0) {
    di as text "   All zero: 1.0.1 is fixed and safe to submit."
}
else {
    di as error "   Still failing.  Re-run with tracing and send the log:"
    di as error "       set trace on"
    di as error "       set tracedepth 2"
    di as error "       xtbfkbreak y x1 x2, breaks(1)"
    di as error "       set trace off"
}
di as text "{hline 79}"

log close bfkdx
