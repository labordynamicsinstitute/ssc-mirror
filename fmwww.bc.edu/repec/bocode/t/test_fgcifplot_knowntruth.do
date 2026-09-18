version 14.2
clear all
set more off

* Load the release-candidate source from this directory.
quietly run "fgcifplot.ado"

* =====================================================================
* fgcifplot exact known-truth test
*
* A 12-pattern competing-risks dataset is replicated five times to give
* stable estimation while preserving hand-calculable risk-set quantities.
* Status: 0=censored, 1=event of interest, 2=competing event.
* =====================================================================

input byte pattern byte grp double dftime byte status
 1 0 1 1
 2 0 1 2
 3 0 1 0
 4 0 2 1
 5 0 2 2
 6 0 3 0
 7 1 1 1
 8 1 1 2
 9 1 2 0
10 1 3 1
11 1 3 2
12 1 4 0
end

expand 5
sort pattern
gen long id = _n

label define grp_lbl 0 "Group A" 1 "Group B"
label values grp grp_lbl

stset dftime, failure(status==1)
stcrreg i.grp, compete(status==2) nolog

tempfile risklong
fgcifplot grp, values(0 1) risktimes(0 1 2 3 4) ///
    risktable(all) nograph risksaving("`risklong'") replace

matrix C = r(conventional)
matrix R = r(retained)
matrix W = r(weighted)
matrix G = r(censor_survival)

* Exact conventional risk-set counts.
matrix Cstar = (30,30,15,5,0 \ 30,30,20,15,5)

* Exact unweighted Fine-Gray retained-set counts.
matrix Rstar = (30,30,20,15,10 \ 30,30,25,20,15)

* Exact Fine-Gray weighted totals.
* Under the censoring KM: G(0)=1, G(1)=1, G(2)=11/12,
* G(3)=11/14, G(4)=33/56.  Replication by five multiplies the
* group-specific totals but leaves G unchanged.
matrix Wstar = (30,30,19.58333333333333,13.21428571428571,6.160714285714286 \ ///
                30,30,24.58333333333333,18.92857142857143,11.69642857142857)
matrix Gstar = (1,1,.9166666666666667,.7857142857142857,.5892857142857143)

forvalues i = 1/2 {
    forvalues j = 1/5 {
        assert abs(C[`i',`j'] - Cstar[`i',`j']) < 1e-10
        assert abs(R[`i',`j'] - Rstar[`i',`j']) < 1e-10
        assert abs(W[`i',`j'] - Wstar[`i',`j']) < 1e-9
    }
}
forvalues j = 1/5 {
    assert abs(G[1,`j'] - Gstar[1,`j']) < 1e-10
}

* Independent check against Stata's own censoring-survival prediction.
tempvar Gstata
predict double `Gstata', kmcensor
local j = 1
foreach tt in 1 2 3 4 {
    local ++j
    quietly summarize `Gstata' if e(sample) & _t == `tt', meanonly
    assert r(N) > 0
    assert abs(r(mean) - Gstar[1,`j']) < 1e-10
}

* Verify that attached group labels survive into the saved long table.
capture confirm file "`risklong'"
assert _rc == 0
preserve
    use "`risklong'", clear
    assert group_label == "Group A" if group_value == 0
    assert group_label == "Group B" if group_value == 1
    confirm variable risk_type
    confirm variable group_value
    confirm variable group_label
    confirm variable time
    confirm variable value
    capture confirm variable row_y
    assert _rc != 0
    capture confirm variable display
    assert _rc != 0
    quietly levelsof risk_type, local(savedtypes)
    local nsaved : word count `savedtypes'
    assert `nsaved' == 3
    quietly count
    assert r(N) == 30
restore

di as result "fgcifplot exact known-truth test PASSED"
