* ranktest cert script 1.0.02 MS 19jan2012
cscript ranktest adofile ranktest
clear all
capture log close
set more off
set rmsg on
program drop _all
log using cs_ranktest,replace
about
which ivreg2
which ranktest
ranktest, version  
assert "`r(version)'" == "01.3.01"

webuse klein, clear
tsset yr

* Equivalence of rk statistic and canonical correlations under homoskedasticity
canon (profits wagetot) (govt taxnetx year wagegovt)
mat canon=e(ccorr)
ranktest (profits wagetot) (govt taxnetx year wagegovt)
mat ccorr=r(rkmatrix)
mat ccorr=ccorr[1..2,6]
mat ccorr=ccorr'
assert reldif(ccorr[1,1],canon[1,1]) < 1e-7
assert reldif(ccorr[1,2],canon[1,2]) < 1e-7

* Equality of rk statistic of null rank and Wald test from OLS regressions and suest.
* To show equality, use suest to test joint significance of Z variables in both
* regressions.  L.profits is the partialled-out variable and is not tested.   Note that
* suest introduces a finite sample adjustment of (N-1)/N.)

ranktest (profits wagetot) (govt taxnetx year wagegovt capital1 L.totinc), partial(L.profits) wald null robust
scalar rkstat = r(chi2)*(r(N)-1)/r(N)
regress profits govt taxnetx year wagegovt capital1 L.totinc L.profits
est store e1
qui regress wagetot govt taxnetx year wagegovt capital1 L.totinc L.profits
est store e2
qui suest e1 e2
qui test [e1_mean]govt [e1_mean]taxnetx [e1_mean]year [e1_mean]wagegovt [e1_mean]capital1 [e1_mean]L.totinc
test [e2_mean]govt [e2_mean]taxnetx [e2_mean]year [e2_mean]wagegovt [e2_mean]capital1 [e2_mean]L.totinc, accum
assert reldif(r(chi2), rkstat) < 1e-7

* Equality of rk statistic and Wald test from OLS regression in special case
* of single regressor.
ranktest (profits) (govt taxnetx year wagegovt capital1 L.totinc), partial(L.profits) wald robust
scalar rkstat=r(chi2)
regress profits govt taxnetx year wagegovt capital1 L.totinc L.profits, robust
testparm govt taxnetx year wagegovt capital1 L.totinc
assert reldif(r(F)*r(df)*e(N)/e(df_r) , rkstat) < 1e-7

* Equality of rk statistic and LM test from OLS regression in special case
* of single regressor. Generate a group variable to illustrate cluster.
* Requires ivreg2.
gen clustvar = round(yr/2)
ranktest (profits) (govt taxnetx year wagegovt capital1 L.totinc), partial(L.profits) cluster(clustvar)
scalar rkstat=r(chi2)
ivreg2 profits L.profits (=govt taxnetx year wagegovt capital1 L.totinc), cluster(clustvar)
assert reldif(e(j) , rkstat) < 1e-7

* As above, but for combinations of robust and weights.
* aw and pw
foreach wt in " " "[aw=profits]" "[pw=profits]" {
	foreach vcv in " " "rob" "cluster(clustvar)" "bw(2)" "rob bw(2)" {
		ranktest (profits) (govt taxnetx year wagegovt capital1 L.totinc) `wt', partial(L.profits) `vcv'
		scalar rkstat=r(chi2)
		ivreg2 profits L.profits (=govt taxnetx year wagegovt capital1 L.totinc) `wt', `vcv'
		assert reldif(e(j) , rkstat) < 1e-7
	}
}
* fw and iw
tsset, clear
foreach vcv in " " "rob" "cluster(clustvar)" {
	ranktest (profits) (govt taxnetx year wagegovt capital1) [fw=yr], `vcv'
	scalar rkstat=r(chi2)
	ivreg2 profits (=govt taxnetx year wagegovt capital1) [fw=yr], `vcv'
	assert reldif(e(j) , rkstat) < 1e-7
}
ranktest (profits) (govt taxnetx year wagegovt capital1) [iw=profits]
scalar rkstat=r(chi2)
ivreg2 profits (=govt taxnetx year wagegovt capital1) [iw=profits]
assert reldif(e(j) , rkstat) < 1e-7

* Bug fixed in ranktest 1.3.01 - 2-way cluster would crash if K>1
sysuse auto, clear
ranktest (price weight) (headroom trunk), cluster(turn trunk)

log close
set more on
set rmsg off
