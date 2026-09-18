version 14.2
clear all
set more off

* Load the release-candidate source from this directory.
quietly run "fgcifplot.ado"

* =====================================================================
* fgcifplot edge-case / defensive-behavior tests
* Version target: fgcifplot 1.0.0+
* =====================================================================

di as text "============================================================"
di as text "FGCIFPLOT EDGE-CASE TESTS"
di as text "============================================================"

* ---------------------------------------------------------------------
* 1. Command must follow stcrreg.
* ---------------------------------------------------------------------
clear
sysuse auto, clear
capture noisily fgcifplot foreign, nograph
local rc = _rc
assert `rc' == 301
di as result "PASS 1: rejects use without a preceding stcrreg fit"

* ---------------------------------------------------------------------
* 2. groupvar must be represented in the fitted model.
* ---------------------------------------------------------------------
clear
webuse hypoxia, clear
stset dftime, failure(failtype==1)
stcrreg ifp tumsize, compete(failtype==2) nolog
capture noisily fgcifplot pelnode, values(0 1) risktimes(0 2 4) nograph
local rc = _rc
assert `rc' == 498
di as result "PASS 2: rejects a group variable absent from the fitted model"

* ---------------------------------------------------------------------
* 3-7. Public hypoxia model: invalid requests should fail explicitly.
* ---------------------------------------------------------------------
stcrreg ifp tumsize i.pelnode, compete(failtype==2) nolog

* Requested group absent from estimation sample.
capture noisily fgcifplot pelnode, values(0 2) risktimes(0 2 4) nograph
local rc = _rc
assert `rc' == 2000
di as result "PASS 3: rejects values() levels absent from e(sample)"

* Negative displayed time.
capture noisily fgcifplot pelnode, values(0 1) risktimes(-1 0 2) nograph
local rc = _rc
assert `rc' == 198
di as result "PASS 4: rejects negative risktimes()"

* Invalid risk-table type.
capture noisily fgcifplot pelnode, values(0 1) risktimes(0 2 4) risktable(foo) nograph
local rc = _rc
assert `rc' == 198
di as result "PASS 5: rejects invalid risktable() type"

* Table panel cannot exceed one third of figure.
capture noisily fgcifplot pelnode, values(0 1) risktimes(0 2 4) ///
    risktable(all) tablepct(40) nograph
local rc = _rc
assert `rc' == 198
di as result "PASS 6: enforces tablepct() <= 33"

* risktable(none) remains a valid computational request, and risksaving()
* exports all three summaries rather than an empty/display-dependent file.
tempfile risknone
quietly fgcifplot pelnode, values(0 1) risktimes(0 2 4) ///
    risktable(none) nograph risksaving("`risknone'") replace
assert "`r(risk_types)'" == "none"
preserve
    use "`risknone'", clear
    quietly levelsof risk_type, local(savedtypes)
    local nsaved : word count `savedtypes'
    assert `nsaved' == 3
    quietly count
    assert r(N) == 18
    capture confirm variable row_y
    assert _rc != 0
    capture confirm variable display
    assert _rc != 0
restore
di as result "PASS 7: risktable(none) works and risksaving() exports all summaries"

* ---------------------------------------------------------------------
* 8. A group with no competing events must still work.
*    In that group retained == weighted == conventional.
* ---------------------------------------------------------------------
clear
set obs 120
gen byte grp = (_n > 60)
gen double dftime = 1 + mod(_n-1,5)
gen byte status = 0

* Group 0: event of interest or censoring only; NO competing events.
replace status = 1 if grp==0 & mod(_n,2)==0

* Group 1: event of interest, competing event, and censoring.
replace status = 1 if grp==1 & mod(_n,3)==0
replace status = 2 if grp==1 & mod(_n,3)==1

stset dftime, failure(status==1)
stcrreg i.grp, compete(status==2) nolog
quietly fgcifplot grp, values(0 1) risktimes(0 1 2 3 4 5) risktable(all) nograph
matrix C = r(conventional)
matrix R = r(retained)
matrix W = r(weighted)

forvalues j = 1/6 {
    assert abs(C[1,`j'] - R[1,`j']) < 1e-10
    assert abs(C[1,`j'] - W[1,`j']) < 1e-10
}
di as result "PASS 8: group with no competing events behaves correctly"

* ---------------------------------------------------------------------
* 9. With no ordinary censoring, G(t)=1 and weighted == retained.
* ---------------------------------------------------------------------
clear
set obs 120
gen byte grp = (_n > 60)
gen double dftime = 1 + mod(_n-1,6)
gen byte status = cond(mod(_n,3)==0, 2, 1)

stset dftime, failure(status==1)
stcrreg i.grp, compete(status==2) nolog
quietly fgcifplot grp, values(0 1) risktimes(0 1 2 3 4 5 6) risktable(all) nograph
matrix R = r(retained)
matrix W = r(weighted)
matrix G = r(censor_survival)

forvalues j = 1/7 {
    assert abs(G[1,`j'] - 1) < 1e-10
    forvalues i = 1/2 {
        assert abs(R[`i',`j'] - W[`i',`j']) < 1e-10
    }
}
di as result "PASS 9: no-censoring case gives G(t)=1 and weighted=retained"

* ---------------------------------------------------------------------
* 10. Missing group values in the raw data are excluded by the fitted
*     model and must not appear as automatically selected groups.
* ---------------------------------------------------------------------
clear
set obs 150
gen double grp = cond(_n<=70,0,cond(_n<=140,1,.))
gen double dftime = 1 + mod(_n-1,6)
gen byte status = cond(mod(_n,4)==0,2,cond(mod(_n,4)==1,0,1))

stset dftime, failure(status==1)
stcrreg i.grp, compete(status==2) nolog
quietly fgcifplot grp, risktimes(0 2 4 6) risktable(all) nograph
matrix GV = r(group_values)
assert colsof(GV) == 2
assert GV[1,1] == 0
assert GV[1,2] == 1
di as result "PASS 10: missing group values do not become plotted groups"

* ---------------------------------------------------------------------
* 11. A bare competing-event indicator may not overlap _d==1.
*     Fit with a valid indicator, then mutate one failure to verify that
*     fgcifplot fails loudly instead of treating it as a retained event.
* ---------------------------------------------------------------------
clear
set obs 180
gen byte grp = (_n > 90)
gen double dftime = 1 + mod(_n-1,8)
gen byte status = cond(mod(_n,5)==0,2,cond(mod(_n,5)==1,0,1))
gen byte compflag = (status==2)
stset dftime, failure(status==1)
stcrreg i.grp, compete(compflag) nolog
quietly replace compflag = 1 if _d==1 in 1/L
capture noisily fgcifplot grp, values(0 1) risktimes(0 2 4 6 8) nograph
local rc = _rc
assert `rc' == 459
di as result "PASS 11: failure/competing-event overlap is rejected explicitly"

* ---------------------------------------------------------------------
* 12. Multiple-record survival data are deliberately rejected in v1.0.
* ---------------------------------------------------------------------
clear
set obs 200
gen long id = ceil(_n/2)
gen byte interval = mod(_n-1,2)
gen byte grp = (id > 50)
gen double enter = interval
gen double exit = interval + 1
gen byte status = 0
replace status = 1 if interval==1 & mod(id,3)==0
replace status = 2 if interval==1 & mod(id,3)==1
stset exit, id(id) enter(time enter) failure(status==1)
stcrreg i.grp, compete(status==2) nolog
capture noisily fgcifplot grp, values(0 1) risktimes(0 1 2) nograph
local rc = _rc
assert `rc' == 459
di as result "PASS 12: multiple-record survival data are rejected explicitly"

* ---------------------------------------------------------------------
* 13. Weighted stset data are deliberately rejected in v1.0.
* ---------------------------------------------------------------------
clear
set obs 180
gen byte grp = (_n > 90)
gen double dftime = 1 + mod(_n-1,8)
gen byte status = cond(mod(_n,5)==0,2,cond(mod(_n,5)==1,0,1))
gen double pw = 1 + mod(_n,3)/10
stset dftime [pweight=pw], failure(status==1)
stcrreg i.grp, compete(status==2) nolog
capture noisily fgcifplot grp, values(0 1) risktimes(0 2 4 6 8) nograph
local rc = _rc
assert `rc' == 459
di as result "PASS 13: weighted stset data are rejected explicitly"

* ---------------------------------------------------------------------
* 14. Delayed entry / left truncation is deliberately rejected in v1.0.
* ---------------------------------------------------------------------
clear
set obs 160
gen byte grp = (_n > 80)
gen double enter = mod(_n-1,3)
gen double dftime = enter + 1 + mod(_n-1,5)
gen byte status = cond(mod(_n,5)==0,2,cond(mod(_n,5)==1,0,1))
stset dftime, failure(status==1) enter(time enter)
stcrreg i.grp, compete(status==2) nolog

capture noisily fgcifplot grp, values(0 1) risktimes(0 1 2 3 4 5 6 7) risktable(all) nograph
local rc = _rc
assert `rc' == 459
di as result "PASS 14: delayed entry is rejected explicitly rather than approximated"

di as result ""
di as result "FGCIFPLOT EDGE-CASE TESTS PASSED"
