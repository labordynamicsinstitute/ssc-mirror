* weakiv cert script MS 08sep2013

cscript weakiv adofile weakiv

clear all
capture log close
set more off
set rmsg on

log using cs_weakiv, replace
about
which weakiv
which ivreg2
which avar
which livreg2.mlib
weakiv, version
assert "`e(version)'" == "01.0.06"
ivreg2, version
assert "`e(version)'" == "03.1.06"
avar, version
assert "`r(version)'" == "01.0.04"

* Replication options:
* (a) Wald AR stat by hand
* (b) condivreg results
* (c) Properties of LIML and CUE
* (d) Vs. original rivtest (basic VCV variants only) (but K-J is slightly diff)
* (e) weakiv as postestimation vs. weakiv as estimation
* (f) ivregress vs. ivreg2
* (g) forcerobust option - general (robust) code used to estimate (special) iid case

**********************************************************************
************************ CX AND CLUSTER ******************************
**********************************************************************

use http://www.stata.com/data/jwooldridge/eacsap/mroz.dta, clear
cap drop poshours
gen byte poshours=(hours>0)
gen byte one=1

**********************************************************************
* VCE and other opts
* Wald AR stat by hand
tempvar ytilda
gen double `ytilda'=.
foreach opt in	" " "rob" "cluster(age)" "cluster(age exper)"	///
				"nocons" "nocons rob" "nocons cluster(age)"		///
				{
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null' `small'"
			qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small'
			qui test (educ=`null')
			scalar Wa=r(chi2)
			if Wa==. {
				scalar Wa=r(F)
			}
			qui weakiv, null(`null')
			scalar ARa=e(ar_chi2)
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			assert reldif(Wa,e(wald_chi2))< 1e-7
			scalar ARb=e(ar_chi2)
			qui replace `ytilda' = lwage - `null'*educ
			qui ivreg2 `ytilda' exper expersq fatheduc motheduc, `opt' `small'
			qui test fatheduc motheduc
			scalar ARc=r(chi2)
			if ARc==. {
				scalar ARc = r(F)*r(df)
			}
			assert reldif(ARa,ARc)< 1e-7
			assert reldif(ARb,ARc)< 1e-7
		}
	}
}
**********************************************************************
* ivreg2 vs ivregress
foreach opt in " " "rob" "cluster(age)"							///
				"nocons" "nocons rob" "nocons cluster(age)"		{
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null' `small'"
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			savedresults save wivreg2 e()
			qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			savedresults comp wivreg2 e(), tol(1e-10)
		}
	}
}
**********************************************************************
* VCE opts w/ and w/o partial
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null' `small'"
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			savedresults save nopartial e()
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null') partial(exper expersq)
			savedresults comp nopartial e(), include(		///
				scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
				tol(1e-7)
			qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' partial(exper expersq)
			qui weakiv, null(`null')
			savedresults comp nopartial e(), include(		///
				scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
				tol(1e-7)
		}
	}
}
**********************************************************************
* forcerobust option causes general robust code to calculate stats for iid case
* Compare with results produced by iid-specific code
foreach small in " " "small"	{
	foreach null of numlist 0 0.1 {
		di "null=`null' `small'"
		qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `small' null(`null')
		scalar wald_chi2=e(wald_chi2)
		scalar ar_chi2=e(ar_chi2)
		scalar k_chi2=e(k_chi2)
		scalar clr_stat=e(clr_stat)
		scalar kj_p=e(kj_p)
		qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), forcerobust `small' null(`null')
		assert reldif(wald_chi2,e(wald_chi2))< 1e-7
		assert reldif(ar_chi2,e(ar_chi2))< 1e-7
		assert reldif(k_chi2,e(k_chi2))< 1e-7
		assert reldif(clr_stat,e(clr_stat))< 1e-7
		assert reldif(kj_p,e(kj_p))< 1e-7
	}
}
**********************************************************************
* Vs. condivreg (homoskedastic case)
* condivreg uses different (wrong) df - double-counts constant - so use explicit constant+nocons
foreach null of numlist 0 0.1 {
	di "null=`null'"
	qui condivreg lwage exper expersq one (educ = fatheduc motheduc), ar lm nocons noinstcons test(`null')
	scalar ar_chi2=invchi2tail(2, e(AR_p))
	scalar k_chi2=invchi2tail(1, e(LM_p))
	scalar clr_p=e(LR_p)
	qui weakiv ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), small null(`null')
	assert reldif(ar_chi2,e(ar_chi2))< 1e-7
	assert reldif(k_chi2,e(k_chi2))< 1e-7
	assert reldif(clr_p,e(clr_p))<1e-7
}
**********************************************************************
* K=0 and CLR=0 at LIML and CUE b0
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), cue
local b0=_b[educ]
qui weakiv, null(`b0')
assert reldif(e(k_chi2),0)< 1e-10
assert reldif(e(clr_stat),0)< 1e-10
* Diff model and low-ish tolerance because of numerical accuracy issues with cluster VCV
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	di "opt=`opt'"
	qui ivreg2 exper (educ = fatheduc motheduc), `opt' cue
	local b0=_b[educ]
	qui weakiv, null(`b0')
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
* Vs. original rivtest
* Linear model, various VCVs, ivreg2 and ivregress
foreach opt in " " "rob" "cluster(age)" {
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null' `small'"
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' null(`null') `small'
			scalar Wald_chi2=e(wald_chi2)
			scalar AR_chi2=e(ar_chi2)
			scalar K_chi2=e(k_chi2)
			scalar CLR_chi2=e(clr_chi2)
			qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small'
			qui rivtest, null(`null')
			assert reldif(Wald_chi2,r(wald_chi2))< 1e-10
			assert reldif(AR_chi2,r(ar_chi2))< 1e-10
			assert reldif(K_chi2,r(lm_chi2))< 1e-10
			assert reldif(CLR_chi2,r(clr_chi2))< 1e-10
			qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `opt' `small'
			qui rivtest, null(`null')
			assert reldif(Wald_chi2,r(wald_chi2))< 1e-10
			assert reldif(AR_chi2,r(ar_chi2))< 1e-10
			assert reldif(K_chi2,r(lm_chi2))< 1e-10
			assert reldif(CLR_chi2,r(clr_chi2))< 1e-10
		}
	}
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
weakiv, ci		// legacy option, has no effect in 1-endog-regressor case
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, retmat	// legacy option, has no effect
**********************************************************************
* Check graphics options work
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
weakiv, graph(wald ar k j kj clr)
weakiv, graph(wald ar k j kj clr) graphxrange(0 0.1)
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
weakiv, level(95 90 80) graph(wald ar k) graphopt(title("3 stats only, 3 levels"))
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll
weakiv, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
**********************************************************************
* Check intervals vs. condivreg
* condivreg has bug in df code with constant so use col of ones and nocons options
qui condivreg2 lwage exper expersq one (educ = fatheduc motheduc), ar lm nocons noinstcons
scalar AR_x1=e(AR_x1)
scalar AR_x2=e(AR_x2)
scalar CLR_x1=e(LR_x1)
scalar CLR_x2=e(LR_x2)
scalar K_x1=e(LM_x1)
scalar K_x2=e(LM_x2)
qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), small
tokenize "`e(clr_cset)'", parse(" [,]")
local nulla_clr = `2'
local nullb_clr = `4'
tokenize "`e(ar_cset)'", parse(" [,]")
local nulla_ar = `2'
local nullb_ar = `4'
tokenize "`e(k_cset)'", parse(" [,]")
local nulla_k = `2'
local nullb_k = `4'
assert reldif(AR_x1,`nulla_ar')< 1e-5
assert reldif(AR_x2,`nullb_ar')< 1e-5
assert reldif(CLR_x1,`nulla_clr')< 1e-5
assert reldif(CLR_x2,`nullb_clr')< 1e-5
assert reldif(K_x1,`nulla_k')< 1e-5
assert reldif(K_x2,`nullb_k')< 1e-5
**********************************************************************
* Check endpoints of confidence intervals
* Non-iid case uses grid search so tolerance is set low.
foreach opt in " " "rob" "cluster(age)" {
	foreach small in " " "small"	{
		if "`opt'"==" " {
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `small'
		}
		else {
			qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' points(800)
		}
		tokenize "`e(clr_cset)'", parse(" [,]")
		local nulla_clr = `2'
		local nullb_clr = `4'
		tokenize "`e(ar_cset)'", parse(" [,]")
		local nulla_ar = `2'
		local nullb_ar = `4'
		tokenize "`e(k_cset)'", parse(" [,]")
		local nulla_k = `2'
		local nullb_k = `4'
		di "opt=`opt' `small' nulla_clr=`nulla_clr'"
		qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nulla_clr') noci
		if "`opt'"==" " {
			assert reldif(e(clr_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(clr_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nullb_clr=`nullb_clr'"
		qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nullb_clr') noci
		if "`opt'"==" " {
			assert reldif(e(clr_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(clr_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nulla_ar=`nulla_ar'"
		qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nulla_ar') noci
		if "`opt'"==" " {
			assert reldif(e(ar_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(ar_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nullb_ar=`nullb_ar'"
		qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nullb_ar') noci
		if "`opt'"==" " {
			assert reldif(e(ar_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(ar_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nulla_l=`nulla_k'"
		qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nulla_k') noci
		if "`opt'"==" " {
			assert reldif(e(k_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(k_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nullb_k=`nullb_k'"
		qui weakiv ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nullb_k') noci
		if "`opt'"==" " {
			assert reldif(e(k_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(k_p),0.05)< 5e-2
		}
	}
}

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
******************************* K=2 **********************************
**********************************************************************
* VCE and other opts
* Wald AR stat by hand
tempvar ytilda
gen double `ytilda'=.
foreach opt in	" " "rob" "cluster(age)" "cluster(age exper)"	///
				"nocons" "nocons rob" "nocons cluster(age)"		///
				{
	foreach small in " " "small"	{
		foreach null1 of numlist 0 0.1 {
			foreach null2 of numlist 0 0.1 {
				di "opt=`opt' `small' null1=`null1' null2=`null2'"
				qui ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs), `opt' `small'
				qui test (educ=`null1') (hours=`null2')
				scalar Wa=r(chi2)
				if Wa==. {
					scalar Wa=r(F)*r(df)
				}
				qui weakiv, null1(`null1') null2(`null2')
				scalar ARa=e(ar_chi2)
				qui weakiv ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs),	///
					`opt' `small' null1(`null1') null2(`null2')
				assert reldif(Wa,e(wald_chi2))< 1e-7
				scalar ARb=e(ar_chi2)
				qui replace `ytilda' = lwage - `null1'*educ - `null2'*hours
				cap ivreg2 `ytilda' exper expersq fatheduc motheduc hushrs, `opt' `small'		// cap because of non-full-rank warning
				qui test fatheduc motheduc hushrs
				scalar ARc=r(chi2)
				if ARc==. {
					scalar ARc = r(F)*r(df)
				}
				assert reldif(ARa,ARc)< 1e-7
				assert reldif(ARb,ARc)< 1e-7
			}
		}
	}
}
**********************************************************************
* forcerobust option forces robust code to calculate iid stat - should match
foreach small in " " "small"	{
	foreach null1 of numlist 0 0.1 {
		foreach null2 of numlist 0 0.1 {
			di "null1=`null1' null2=`null2'"
			qui weakiv ivregress 2sls lwage exper expersq (educ hours = fatheduc motheduc hushrs), `small' null1(`null1') null2(`null2')
			scalar wald_chi2=e(wald_chi2)
			scalar ar_chi2=e(ar_chi2)
			scalar k_chi2=e(k_chi2)
			scalar clr_stat=e(clr_stat)
			scalar kj_p=e(kj_p)
			qui weakiv ivregress 2sls lwage exper expersq (educ hours = fatheduc motheduc hushrs), forcerobust `small' null1(`null1') null2(`null2')
			assert reldif(wald_chi2,e(wald_chi2))< 1e-7
			assert reldif(ar_chi2,e(ar_chi2))< 1e-7
			assert reldif(k_chi2,e(k_chi2))< 1e-7
			assert reldif(clr_stat,e(clr_stat))< 1e-7
			assert reldif(kj_p,e(kj_p))< 1e-7
		}
	}
}
**********************************************************************
* Check graphics options work
weakiv ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs), rob points1(25) points2(25)
weakiv, graph(ar)
weakiv, graph(wald ar)
weakiv, graph(wald k) level(95 90 80)
weakiv ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs), rob points(25) gridmult(4)
weakiv, graph(wald k) surfaceopt(nowire)
weakiv, graph(wald ar) contouronly
weakiv, graph(wald ar) surfaceonly surfaceopt(nowire)

**********************************************************************
************************ AC AND HAC VCV ******************************
**********************************************************************

use http://fmwww.bc.edu/ec-p/data/wooldridge/phillips.dta, clear
tsset year, yearly

**********************************************************************
* VCE and other opts
* Wald AR stat by hand
tempvar ytilda
gen double `ytilda'=.
foreach opt in "bw(3)" "rob bw(3)" {
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' `small' null=`null'"
			qui ivreg2 cinf (unem = l(1/3).unem), `opt' `small'
			qui test (unem=`null')
			scalar Wa=r(chi2)
			if Wa==. {
				scalar Wa=r(F)*r(df)
			}
			qui weakiv, null(`null')
			scalar ARa=e(ar_chi2)
			qui weakiv ivreg2 cinf (unem = l(1/3).unem), `opt' `small' null(`null')
			assert reldif(Wa,e(wald_chi2))< 1e-7
			scalar ARb=e(ar_chi2)
			qui replace `ytilda' = cinf - `null'*unem
			qui ivreg2 `ytilda' l(1/3).unem, `opt' `small'
			qui test L1.unem L2.unem L3.unem
			scalar ARc=r(chi2)
			if ARc==. {
				scalar ARc = r(F)*r(df)
			}
			assert reldif(ARa,ARc)< 1e-7
			assert reldif(ARb,ARc)< 1e-7
		}
	}
}
* ivreg2 vs ivregress
foreach small in " " "small"	{
	qui weakiv ivreg2 cinf (unem = l(1/3).unem), rob bw(3) `small'
	savedresults save wivreg2 e()
	qui weakiv ivregress 2sls cinf (unem = l(1/3).unem), vce(hac bartlett 2) `small'
	savedresults comp wivreg2 e(), tol(1e-10)
}
**********************************************************************
******************************* K=2 **********************************
**********************************************************************
* VCE and other opts
* Wald AR stat by hand
tempvar ytilda
gen double `ytilda'=.
foreach opt in "bw(3)" "rob bw(3)" {
	foreach small in " " "small"	{
		foreach null1 of numlist 0 0.1 {
			foreach null2 of numlist 0 0.1 {
				di "opt=`opt' `small' null1=`null1' null2=`null2'"
				qui ivreg2 cinf (unem l.unem = l(2/4).unem), `opt' `small'
				qui test (unem=`null1') (l.unem=`null2')
				scalar Wa=r(chi2)
				if Wa==. {
					scalar Wa=r(F)*r(df)
				}
				qui weakiv, null1(`null1') null2(`null2')
				scalar ARa=e(ar_chi2)
				qui weakiv ivreg2 cinf (unem l.unem = l(2/4).unem), `opt' `small' null1(`null1') null2(`null2')
				assert reldif(Wa,e(wald_chi2))< 1e-7
				scalar ARb=e(ar_chi2)
				qui replace `ytilda' = cinf - `null1'*unem - `null2'*l.unem
				qui ivreg2 `ytilda' l(2/4).unem, `opt' `small'
				qui test L2.unem L3.unem L4.unem
				scalar ARc=r(chi2)
				if ARc==. {
					scalar ARc = r(F)*r(df)
				}
				assert reldif(ARa,ARc)< 1e-7
				assert reldif(ARb,ARc)< 1e-7
			}
		}
	}
}

**********************************************************************
* Check graphics options work
* Should be 25 points in both dimensions
qui weakiv ivreg2 cinf (unem l.unem = l(2/4).unem),	///
			rob bw(3) usegrid points(25)
weakiv, graph(wald ar)
weakiv, graph(k)



log close
set more on
set rmsg off
