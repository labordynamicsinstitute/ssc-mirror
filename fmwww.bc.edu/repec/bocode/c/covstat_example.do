*! covstat_example.do  --  self-test for -covstat- (flexur library)
*! Dr Merwan Roudane
*! Run after: adopath + "<folder>"   then   do covstat_example.do

clear
set more off
set seed 20260723

*==========================================================================
* CASE A -- stationary AR(1) with chi-square(1) (non-normal) errors.
*   Truth: stationary => do NOT reject; rho^2 should be sizeable (non-normal).
*==========================================================================
di _n(2) as txt "{hline 72}"
di as txt "CASE A : stationary AR(1), chi-square errors -- do NOT reject"
di as txt "{hline 72}"
quietly set obs 300
gen t = _n
tsset t
gen double y = .
quietly replace y = 0 in 1
forvalues i = 2/300 {
    quietly replace y = 0.5*y[`i'-1] + (rchi2(1)-1) in `i'
}
covstat y, model(constant)

*==========================================================================
* CASE B -- random walk (non-stationary) => REJECT stationarity.
*==========================================================================
di _n(2) as txt "{hline 72}"
di as txt "CASE B : random walk -- REJECT stationarity (large L_T, small p)"
di as txt "{hline 72}"
clear
quietly set obs 300
gen t = _n
tsset t
gen double y = sum(rnormal())
covstat y, model(trend) graph gname(covstat_caseB)

di _n as txt "{hline 72}"
di as txt "Validation note: on the Nelson-Plosser data (NP_Data.xlsx) with"
di as txt "model(trend), covstat reproduces Table 9 of Nazlioglu et al. (2021)"
di as txt "to the last reported digit (Ly_T, Qy_T, L_T, Q_T, rho^2 and p-values)."
di as txt "{hline 72}"
