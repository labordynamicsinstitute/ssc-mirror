* weakiv cert script MS 28jul2013

cscript weakiv adofile weakiv

clear all
capture log close
set more off
set rmsg on

log using cs_weakiv, replace
about
which weakiv
which ivreg2
which ranktest
which livreg2.mlib
weakiv, version
assert "`e(version)'" == "01.0.04"
ivreg2, version
assert "`e(version)'" == "03.1.06"
ranktest, version
assert "`r(version)'" == "01.3.02"

* Replication options:
* (a) Wald AR stat by hand
* (b) condivreg results (but not close because stats have diff dfns)
* (c) Properties of LIML and CUE
* (d) Vs. original rivtest (basic VCV variants only) (but K-J is slightly diff)
* (e) weakiv as postestimation vs. weakiv as estimation
* (f) ivregress vs. ivreg2

**********************************************************************
************************ CX AND CLUSTER ******************************
**********************************************************************

use http://www.stata.com/data/jwooldridge/eacsap/mroz.dta, clear
cap drop poshours
gen byte poshours=(hours>0)

**********************************************************************
* VCE and other opts
* Wald AR stat by hand
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)"	///
				"nocons" "nocons rob" "nocons cluster(age)"		{
	di "opt=`opt'"
	qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt'
	qui weakiv
	scalar ARa=e(ar_chi2)
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt'
	scalar ARb=e(ar_chi2)
	qui ivreg2 lwage exper expersq fatheduc motheduc, `opt'
	qui test fatheduc motheduc
	assert reldif(ARa,r(chi2))< 1e-7
	assert reldif(ARb,r(chi2))< 1e-7
}
**********************************************************************
* ivreg2 vs ivregress
foreach opt in " " "rob" "cluster(age)"							///
				"nocons" "nocons rob" "nocons cluster(age)"		{
	di "opt=`opt'"
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt'
	savedresults save wivreg2 e()
	qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `opt'
	savedresults comp wivreg2 e(), tol(1e-10)
}
**********************************************************************
* VCE opts w/ and w/o partial
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	di "opt=`opt'"
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt'
	savedresults save nopartial e()
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' partial(exper expersq)
	savedresults comp nopartial e(), include(		///
		scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
		tol(1e-7)
	qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' partial(exper expersq)
	qui weakiv
	savedresults comp nopartial e(), include(		///
		scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
		tol(1e-7)
}
* Confirm small dof adj also handled correctly
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	di "opt=`opt'"
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' small
	savedresults save nopartial e()
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' partial(exper expersq) small
	savedresults comp nopartial e(), include(		///
		scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
		tol(1e-7)
	qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' partial(exper expersq) small
	qui weakiv
	savedresults comp nopartial e(), include(		///
		scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
		tol(1e-7)
}
**********************************************************************
* Vs. condivreg (homoskedastic case)
* Different statistics (e.g., MD AR is Wald), therefore NOT close: 5e-3 only
qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc)
scalar AR_p=e(ar_p)
scalar K_p=e(k_p)
scalar CLR_p=e(clr_p)
qui condivreg lwage exper expersq (educ = fatheduc motheduc), ar lm
assert reldif(AR_p,e(AR_p))< 5e-3
assert reldif(K_p,e(LM_p))< 5e-3
assert reldif(CLR_p,e(LR_p))< 5e-3
**********************************************************************
* K=0 and CLR=0 at LIML and CUE b0
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), cue
global b0=_b[educ]
qui weakiv, null($b0)
assert reldif(e(k_chi2),0)< 1e-10
assert reldif(e(clr_stat),0)< 1e-10
* Diff model and low-ish tolerance because of numerical accuracy issues with cluster VCV
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	di "opt=`opt'"
	qui ivreg2 exper (educ = fatheduc motheduc), `opt' cue
	global b0=_b[educ]
	qui weakiv, null($b0)
	assert reldif(e(k_chi2),0)< 1e-4
	assert reldif(e(clr_stat),0)< 1e-4
}
**********************************************************************
* Numerical vs. grid search
* Check grid options too
set matsize 800
qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc)
savedresults save numerical e()
qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), usegrid points(800)
assert "`e(grid_description)'"=="[-.061256, .184049]"
savedresults comp numerical e(), include(		///
	scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
	tol(1e-7)
qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), usegrid points(800) gridmult(1)
assert "`e(grid_description)'"=="[  .00007, .122723]"
savedresults comp numerical e(), include(		///
	scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
	tol(1e-7)
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
qui weakiv
savedresults save numerical e()
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
qui weakiv, usegrid points(800)
savedresults comp numerical e(), include(		///
	scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
	tol(1e-7)
qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), gridlimits(-1 1)
assert "`e(grid_description)'"=="[      -1,       1]"
**********************************************************************
* Vs. original rivest
* Linear model, various VCVs, ivreg2 and ivregress
foreach opt in " " "rob" "cluster(age)" {
	di "opt=`opt'"
	qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt'
	scalar Wald_chi2=e(wald_chi2)
	scalar AR_chi2=e(ar_chi2)
	scalar K_chi2=e(k_chi2)
	scalar CLR_chi2=e(clr_chi2)
	qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt'
	qui rivtest
	assert reldif(Wald_chi2,r(wald_chi2))< 1e-10
	assert reldif(AR_chi2,r(ar_chi2))< 1e-10
	assert reldif(K_chi2,r(lm_chi2))< 1e-10
	assert reldif(CLR_chi2,r(clr_chi2))< 1e-10
	qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `opt'
	qui rivtest
	assert reldif(Wald_chi2,r(wald_chi2))< 1e-10
	assert reldif(AR_chi2,r(ar_chi2))< 1e-10
	assert reldif(K_chi2,r(lm_chi2))< 1e-10
	assert reldif(CLR_chi2,r(clr_chi2))< 1e-10
}
* ivprobit
qui weakiv ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep
scalar Wald_chi2=e(wald_chi2)
scalar AR_chi2=e(ar_chi2)
scalar K_chi2=e(k_chi2)
scalar CLR_chi2=e(clr_chi2)
local CLR_cset "`e(clr_cset)'"
local K_cset "`e(k_cset)'"
local AR_cset "`e(ar_cset)'"
qui ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep
qui rivtest, ci
assert reldif(Wald_chi2,r(wald_chi2))< 1e-6
assert reldif(AR_chi2,r(ar_chi2))< 1e-6
assert reldif(K_chi2,r(lm_chi2))< 1e-6
assert reldif(CLR_chi2,r(clr_chi2))< 1e-6
assert "`CLR_cset'"=="`r(clr_cset)'"
assert "`K_cset'"=="`r(lm_cset)'"
assert "`AR_cset'"=="`r(ar_cset)'"
* ivtobit
qui weakiv ivtobit hours exper expersq (educ = fatheduc motheduc), ll
scalar Wald_chi2=e(wald_chi2)
scalar AR_chi2=e(ar_chi2)
scalar K_chi2=e(k_chi2)
scalar CLR_chi2=e(clr_chi2)
local CLR_cset "`e(clr_cset)'"
local K_cset "`e(k_cset)'"
local AR_cset "`e(ar_cset)'"
qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll
qui rivtest, ci
assert reldif(Wald_chi2,r(wald_chi2))< 1e-9
assert reldif(AR_chi2,r(ar_chi2))< 1e-9
assert reldif(K_chi2,r(lm_chi2))< 1e-9
assert reldif(CLR_chi2,r(clr_chi2))< 1e-9
assert "`CLR_cset'"=="`r(clr_cset)'"
assert "`K_cset'"=="`r(lm_cset)'"
assert "`AR_cset'"=="`r(ar_cset)'"
**********************************************************************
* Check non-graphics options work
* estadd after previous estimation
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
qui weakiv, estadd
assert "`e(cmd)'"=="ivregress"
assert "`e(clr_cset)'"=="[-.008238, .123148]"
qui weakiv, estadd(prefix_) level(90) eststore(mymodel)
assert "`e(cmd)'"=="ivregress"
assert "`e(prefix_clr_cset)'"=="[ .002957,  .11322]"
* display Wald model
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, display
* use stored model
est drop _all
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
est store mymodel
ereturn clear
ereturn list
est dir
* store wald model
est drop _all
est dir
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, eststore(mymodel)
est dir
* Misc
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, noci
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, ci		// legacy option, has no effect
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, retmat	// legacy option, has no effect
**********************************************************************
* Check graphics options work
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
weakiv, graph(wald ar k j kj clr)
weakiv, graph(wald ar k j kj clr) graphxrange(0 0.1)
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
weakiv, graph(wald ar k) graphopt(title("3 stats only"))
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc)
assert "`e(clr_cset)'"=="[-.004127,  .12228]"
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc)
qui weakiv
assert "`e(clr_cset)'"=="[-.004127,  .12228]"
qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), level(90)
assert "`e(clr_cset)'"=="[ .006972, .112469]"
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc)
qui weakiv, level(90)
assert "`e(clr_cset)'"=="[ .006972, .112469]"
**********************************************************************
* Catch various errors
* ivprobit requires twostep option
qui ivprobit poshours exper expersq (educ = fatheduc motheduc)
cap noi weakiv
rcof "weakiv" == 198
cap noi weakiv ivprobit poshours exper expersq (educ = fatheduc motheduc)
rcof "weakiv" == 198
* ivprobit and ivtobit require iid - no robust or cluster
foreach opt in "rob" "cluster(age)" {
	di "opt=`opt'"
	rcof "weakiv poshours exper expersq (educ = fatheduc motheduc), model(ivprobit) `opt'" == 198
	qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll `opt'
	rcof "weakiv" == 198
	rcof "weakiv hours exper expersq (educ = fatheduc motheduc), model(ivtobit) ll `opt'
}	
**********************************************************************

**********************************************************************
************************ AC AND HAC VCV ******************************
**********************************************************************

use http://fmwww.bc.edu/ec-p/data/wooldridge/phillips.dta, clear
tsset year, yearly

**********************************************************************
* VCE and other opts
* Wald AR stat by hand
foreach opt in "bw(3)" "rob bw(3)" {
	di "opt=`opt'"
	qui ivreg2 cinf (unem = l(1/3).unem), `opt'
	qui weakiv
	scalar AR=e(ar_chi2)
	qui ivreg2 cinf l(1/3).unem, `opt'
	qui test L1.unem L2.unem L3.unem
	assert reldif(AR,r(chi2))< 1e-7
}
* ivreg2 vs ivregress
qui weakiv ivreg2 cinf (unem = l(1/3).unem), rob bw(3)
savedresults save wivreg2 e()
qui weakiv ivregress 2sls cinf (unem = l(1/3).unem), vce(hac bartlett 2)
savedresults comp wivreg2 e(), tol(1e-10)

log close
set more on
set rmsg off
