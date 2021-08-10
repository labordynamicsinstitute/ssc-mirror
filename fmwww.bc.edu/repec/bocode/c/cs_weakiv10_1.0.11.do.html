* weakiv10 cert script MS 9sept2014

cscript weakiv10 adofile weakiv10

clear all
capture log close
set more off
set rmsg on

log using cs_weakiv10, replace
about
which weakiv10
which ivreg2
which avar
which livreg2.mlib
* expect condivreg version:		*! Version 2.0.4  17apr2006
which condivreg
* expect surface version:		*! Date    : 31 Jul 2013
*								*! Version : 1.06
which surface
weakiv10, version
assert "`e(version)'" == "01.0.11"
* weakiv10 cert script may run correctly with earlier or later versions, hence "cap noi"
ivreg2, version
cap noi assert "`e(version)'" == "03.1.08"
avar, version
cap noi assert "`r(version)'" == "01.0.05"
xtivreg2, version
cap noi assert "`e(version)'" == "01.0.13"

**********************************************************************
************************ CX AND CLUSTER ******************************
**********************************************************************

use http://www.stata.com/data/jwooldridge/eacsap/mroz.dta, clear
cap drop poshours
gen byte poshours=(hours>0)
gen byte one=1

**********************************************************************
* VCE and other opts
* Wald and LM AR stats by hand
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
			qui weakiv10, null(`null')
			scalar ARa=e(ar_chi2)
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
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
			qui ivreg2 `ytilda' exper expersq (=fatheduc motheduc), `opt' `small'
			scalar ARd=e(j)
			if "`small'"=="small" & "`e(clustvar)'"=="" {
				scalar ARd = ARd * (e(N)-e(inexog_ct)-e(exexog_ct)-e(cons))/e(N)
			}
			else if "`small'"=="small" {
				scalar ARd = ARd * (e(N)-e(inexog_ct)-e(exexog_ct)-e(cons))/(e(N)-1)*(e(N_clust)-1)/e(N_clust)
			}
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null') lm
			scalar ARe=e(ar_chi2)
			assert reldif(ARd,ARe)< 1e-7
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
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			savedresults save wivreg2 e()
			qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			savedresults comp wivreg2 e(), tol(1e-10)
		}
	}
}
**********************************************************************
* ivreg2 vs xtivreg2
cap drop id*
cap drop t
gen id=ceil(_n/8)
gen t=8*id-_n
xtset id t
qui tab id if inlf, gen(id_)
* Fixed effects
local dofminus = r(r)
foreach opt in " " "rob" "cluster(id)"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null'"
			qui weakiv10 ivreg2 lwage exper expersq id_* (educ = fatheduc motheduc), `opt' null(`null') partial(id_*) nocons dofminus(`dofminus')
			savedresults save wivreg2 e()
			qui weakiv10 xtivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' null(`null') fe
			savedresults comp wivreg2 e(), tol(1e-7) exclude(macros: inexog xtmodel scalars: N_g singleton)
	}
}
* First differences
foreach opt in " " "rob" "cluster(id)"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null'"
			qui weakiv10 ivreg2 D.lwage D.exper D.expersq (D.educ = D.fatheduc D.motheduc), `opt' null(`null')
			savedresults save wivreg2 e()
			qui weakiv10 xtivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' null(`null') fd
			savedresults comp wivreg2 e(), tol(1e-7) exclude(macros: xtmodel scalars: N_g singleton)
	}
}
* Compared with official xtivreg - requires small option - iid only
* Also checks small option
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null'"
			qui weakiv10 ivreg2 lwage exper expersq id_* (educ = fatheduc motheduc), null(`null') partial(id_* exper expersq) nocons small
			savedresults save wivreg2 e()
			qui weakiv10 xtivreg2 lwage exper expersq (educ = fatheduc motheduc), null(`null') fe small
			savedresults comp wivreg2 e(), tol(1e-7) exclude(macros: inexog xtmodel scalars: N_g singleton)
			qui weakiv10 xtivreg lwage exper expersq (educ = fatheduc motheduc), null(`null') fe small
			savedresults comp wivreg2 e(), tol(1e-7) exclude(macros: inexog xtmodel scalars: N_g singleton)
	}
* First differences
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null'"
			qui weakiv10 ivreg2 D.lwage D.exper D.expersq (D.educ = D.fatheduc D.motheduc), `opt' null(`null') small
			savedresults save wivreg2 e()
			qui weakiv10 xtivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' null(`null') fd small
			savedresults comp wivreg2 e(), tol(1e-7) exclude(macros: inexog xtmodel scalars: N_g singleton)
			qui weakiv10 xtivreg lwage exper expersq (educ = fatheduc motheduc), `opt' null(`null') fd small
			savedresults comp wivreg2 e(), tol(1e-7) exclude(macros: inexog xtmodel scalars: N_g singleton)
	}

/*
**********************************************************************
* VCE opts w/ and w/o partial
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null' `small'"
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null')
			savedresults save nopartial e()
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`null') partial(exper expersq)
			savedresults comp nopartial e(), include(		///
				scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
				tol(1e-7)
			qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' partial(exper expersq)
			qui weakiv10, null(`null')
			savedresults comp nopartial e(), include(		///
				scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
				tol(1e-7)
		}
	}
}
*/
**********************************************************************
* forcerobust option causes general robust code to calculate stats for iid case
* Compare with results produced by iid-specific code
foreach small in " " "small"	{
	foreach null of numlist 0 0.1 {
		di "null=`null' `small'"
		qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `small' null(`null')
		scalar wald_chi2=e(wald_chi2)
		scalar ar_chi2=e(ar_chi2)
		scalar k_chi2=e(k_chi2)
		scalar clr_stat=e(clr_stat)
		scalar kj_p=e(kj_p)
		qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), forcerobust `small' null(`null')
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
	qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), small null(`null')
	assert reldif(ar_chi2,e(ar_chi2))< 1e-7
	assert reldif(k_chi2,e(k_chi2))< 1e-7
	assert reldif(clr_p,e(clr_p))<1e-7
}
**********************************************************************
* K=0 and CLR=0 at LIML and CUE b0
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), cue
local b0=_b[educ]
qui weakiv10, null(`b0')
assert reldif(e(k_chi2),0)< 1e-10
assert reldif(e(clr_stat),0)< 1e-10
* Diff model and low-ish tolerance because of numerical accuracy issues with cluster VCV
foreach opt in " " "rob" "cluster(age)" "cluster(age exper)" {
	di "opt=`opt'"
	qui ivreg2 exper (educ = fatheduc motheduc), `opt' cue
	local b0=_b[educ]
	qui weakiv10, null(`b0')
	assert reldif(e(k_chi2),0)< 1e-4
	assert reldif(e(clr_stat),0)< 1e-4
}
**********************************************************************
* Numerical vs. grid search
* Check grid options too
set matsize 800
qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc)
savedresults save numerical e()
qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), usegrid points(800)
assert "`e(grid_description)'"=="[-.061256, .184049]"
savedresults comp numerical e(), include(		///
	scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
	tol(1e-7)
qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), usegrid points(800) gridmult(1)
assert "`e(grid_description)'"=="[  .00007, .122723]"
savedresults comp numerical e(), include(		///
	scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
	tol(1e-7)
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
qui weakiv10
savedresults save numerical e()
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
qui weakiv10, usegrid points(800)
savedresults comp numerical e(), include(		///
	scalar: ar_chi2 clr_stat k_chi2 j_chi2)		///
	tol(1e-7)
qui weakiv10 ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), gridlimits(-1 1)
assert "`e(grid_description)'"=="[      -1,       1]"
**********************************************************************
* Vs. original rivtest
* Linear model, various VCVs, ivreg2 and ivregress
foreach opt in " " "rob" "cluster(age)" {
	foreach small in " " "small"	{
		foreach null of numlist 0 0.1 {
			di "opt=`opt' null=`null' `small'"
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' null(`null') `small'
			scalar Wald_chi2=e(wald_chi2)
			scalar AR_chi2=e(ar_chi2)
			scalar K_chi2=e(k_chi2)
			scalar CLR_chi2=e(clr_chi2)
			qui ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small'
			qui rivtest, null(`null')
			assert reldif(Wald_chi2,r(wald_chi2))< 1e-7
			assert reldif(AR_chi2,r(ar_chi2))< 1e-7
			assert reldif(K_chi2,r(lm_chi2))< 1e-7
			assert reldif(CLR_chi2,r(clr_chi2))< 1e-7
			qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), `opt' `small'
			qui rivtest, null(`null')
			assert reldif(Wald_chi2,r(wald_chi2))< 1e-7
			assert reldif(AR_chi2,r(ar_chi2))< 1e-7
			assert reldif(K_chi2,r(lm_chi2))< 1e-7
			assert reldif(CLR_chi2,r(clr_chi2))< 1e-7
		}
	}
}
* ivprobit
qui weakiv10 ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep
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
qui weakiv10 ivtobit hours exper expersq (educ = fatheduc motheduc), ll
scalar Wald_chi2=e(wald_chi2)
scalar AR_chi2=e(ar_chi2)
scalar K_chi2=e(k_chi2)
scalar CLR_chi2=e(clr_chi2)
local CLR_cset "`e(clr_cset)'"
local K_cset "`e(k_cset)'"
local AR_cset "`e(ar_cset)'"
qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll
qui rivtest, ci
assert reldif(Wald_chi2,r(wald_chi2))< 1e-8
assert reldif(AR_chi2,r(ar_chi2))< 1e-8
assert reldif(K_chi2,r(lm_chi2))< 1e-8
assert reldif(CLR_chi2,r(clr_chi2))< 1e-8
assert "`CLR_cset'"=="`r(clr_cset)'"
assert "`K_cset'"=="`r(lm_cset)'"
assert "`AR_cset'"=="`r(ar_cset)'"
**********************************************************************
* Check non-graphics options work
* estadd after previous estimation
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
qui weakiv10, estadd
assert "`e(cmd)'"=="ivregress"
assert "`e(clr_cset)'"=="[-.008238, .123148]"
qui weakiv10, estadd(prefix_) level(90) eststore(mymodel)
assert "`e(cmd)'"=="ivregress"
assert "`e(prefix_clr_cset)'"=="[ .002957,  .11322]"
* display Wald model
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv10, display
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
weakiv10, eststore(mymodel)
est dir
* Misc
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv10, noci
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv10, ci		// legacy option, has no effect in 1-endog-regressor case
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv10, retmat	// legacy option, has no effect
**********************************************************************
* Check graphics options work
qui ivreg2 lwage exper expersq (educ = fatheduc motheduc)
weakiv10, graph(wald ar k j kj clr)
weakiv10, graph(wald ar k j kj clr) graphxrange(0 0.1)
weakiv10, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
weakiv10, level(95 90 80) graph(wald ar k) graphopt(title("3 stats only, 3 levels"))
qui ivregress 2sls lwage exper expersq (educ = fatheduc motheduc), rob
weakiv10, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep
weakiv10, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll
weakiv10, graph(wald ar k j kj clr) graphopt(title("All 6 stats"))
**********************************************************************
* Check intervals vs. condivreg
* condivreg has bug in df code with constant so use col of ones and nocons options
qui condivreg lwage exper expersq one (educ = fatheduc motheduc), ar lm nocons noinstcons
scalar AR_x1=e(AR_x1)
scalar AR_x2=e(AR_x2)
scalar CLR_x1=e(LR_x1)
scalar CLR_x2=e(LR_x2)
scalar K_x1=e(LM_x1)
scalar K_x2=e(LM_x2)
qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), small
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
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `small'
		}
		else {
			qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' points(800)
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
		qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nulla_clr') noci
		if "`opt'"==" " {
			assert reldif(e(clr_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(clr_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nullb_clr=`nullb_clr'"
		qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nullb_clr') noci
		if "`opt'"==" " {
			assert reldif(e(clr_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(clr_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nulla_ar=`nulla_ar'"
		qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nulla_ar') noci
		if "`opt'"==" " {
			assert reldif(e(ar_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(ar_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nullb_ar=`nullb_ar'"
		qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nullb_ar') noci
		if "`opt'"==" " {
			assert reldif(e(ar_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(ar_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nulla_l=`nulla_k'"
		qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nulla_k') noci
		if "`opt'"==" " {
			assert reldif(e(k_p),0.05)< 1e-5
		}
		else {
			assert reldif(e(k_p),0.05)< 5e-2
		}
		di "opt=`opt' `small' nullb_k=`nullb_k'"
		qui weakiv10 ivreg2 lwage exper expersq (educ = fatheduc motheduc), `opt' `small' null(`nullb_k') noci
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
cap noi weakiv10
rcof "weakiv10" == 198
cap noi weakiv10 ivprobit poshours exper expersq (educ = fatheduc motheduc)
rcof "weakiv10" == 198
* ivprobit and ivtobit require iid - no robust or cluster
foreach opt in "rob" "cluster(age)" {
	di "opt=`opt'"
	rcof "weakiv10 ivprobit poshours exper expersq (educ = fatheduc motheduc), twostep `opt'" == 198
	qui ivtobit hours exper expersq (educ = fatheduc motheduc), ll `opt'
	rcof "weakiv10" == 198
	rcof "weakiv10 ivtobit hours exper expersq (educ = fatheduc motheduc), ll `opt'
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
				qui weakiv10, null1(`null1') null2(`null2')
				scalar ARa=e(ar_chi2)
				qui weakiv10 ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs),	///
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
			qui weakiv10 ivregress 2sls lwage exper expersq (educ hours = fatheduc motheduc hushrs), `small' null1(`null1') null2(`null2')
			scalar wald_chi2=e(wald_chi2)
			scalar ar_chi2=e(ar_chi2)
			scalar k_chi2=e(k_chi2)
			scalar clr_stat=e(clr_stat)
			scalar kj_p=e(kj_p)
			qui weakiv10 ivregress 2sls lwage exper expersq (educ hours = fatheduc motheduc hushrs), forcerobust `small' null1(`null1') null2(`null2')
			assert reldif(wald_chi2,e(wald_chi2))< 1e-7
			assert reldif(ar_chi2,e(ar_chi2))< 1e-7
			assert reldif(k_chi2,e(k_chi2))< 1e-7
			assert reldif(clr_stat,e(clr_stat))< 1e-7
			assert reldif(kj_p,e(kj_p))< 1e-7
		}
	}
}
**********************************************************************
* strong(.) option; replicate by hand.
* H0: beta1=0.01
foreach opt in	" " "rob" "cluster(age)" "cluster(age exper)"	///
				"nocons" "nocons rob" "nocons cluster(age)"		///
				{
	di "opt=`opt'"
	qui ivreg2 lwage exper expersq (hours educ = fatheduc motheduc hushrs), `opt'
	qui test hours=0.01
	scalar wald_chi2=r(chi2)
	cap drop ytilda
	qui gen double ytilda=lwage-0.01*hours
	qui ivreg2 ytilda exper expersq (educ = fatheduc motheduc hushrs), `opt' gmm2s
	global b2=_b[educ]
	qui weakiv10 ivreg2 lwage exper expersq (hours educ = fatheduc motheduc hushrs), null1(0.01) null2($b2) `opt'
	scalar ar_chi2=e(ar_chi2)
	scalar k_chi2=e(k_chi2)
	scalar j_chi2=e(j_chi2)
	qui weakiv10 ivreg2 lwage exper expersq (hours educ = fatheduc motheduc hushrs), null(0.01) strong(educ) `opt'
	assert reldif(wald_chi2,e(wald_chi2))< 1e-7
	assert reldif(ar_chi2,e(ar_chi2))< 1e-7
	assert reldif(k_chi2,e(k_chi2))< 1e-7
	assert reldif(j_chi2,e(j_chi2))< 1e-7
}

**********************************************************************
* Check graphics options work
weakiv10 ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs), rob points1(25) points2(25)
weakiv10, graph(ar)
weakiv10, graph(wald ar)
weakiv10, graph(wald k) level(95 90 80)
weakiv10 ivreg2 lwage exper expersq (educ hours = fatheduc motheduc hushrs), rob points(25) gridmult(4)
weakiv10, graph(wald k) surfaceopt(nowire)
weakiv10, graph(wald ar) contouronly
weakiv10, graph(wald ar) surfaceonly surfaceopt(nowire)

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
			qui weakiv10, null(`null')
			scalar ARa=e(ar_chi2)
			qui weakiv10 ivreg2 cinf (unem = l(1/3).unem), `opt' `small' null(`null')
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
	qui weakiv10 ivreg2 cinf (unem = l(1/3).unem), rob bw(3) `small'
	savedresults save wivreg2 e()
	qui weakiv10 ivregress 2sls cinf (unem = l(1/3).unem), vce(hac bartlett 2) `small'
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
				qui weakiv10, null1(`null1') null2(`null2')
				scalar ARa=e(ar_chi2)
				qui weakiv10 ivreg2 cinf (unem l.unem = l(2/4).unem), `opt' `small' null1(`null1') null2(`null2')
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
qui weakiv10 ivreg2 cinf (unem l.unem = l(2/4).unem),	///
			rob bw(3) usegrid points(25)
weakiv10, graph(wald ar)
weakiv10, graph(k)

**********************************************************************
******************** AR, K and J by hand in Mata *********************
**********************************************************************

sysuse auto, clear
mata: mata clear
keep price foreign mpg weight turn displacement gear_ratio
* Mata code simplifies if exogenous regressors incl. constant are partialled out
foreach var of varlist price mpg weight turn displacement gear_ratio {
	qui reg `var' foreign
	qui predict double c_`var', resid
}

****************************** K=1 ***********************************

global y	price
global c_y	c_price
global Z	weight   turn   displacement
global c_Z	c_weight c_turn c_displacement
global X	mpg
global c_X	c_mpg
* Partialled-out exogenous regressors (not including constant)
global X2	foreign

scalar null=-400
global null=null
qui desc
scalar n=r(N)
global n=n

* Mata variables, projection and annihilation matrices
mata: null=st_numscalar("null")
mata: n   =st_numscalar("n")
putmata Z=($c_Z), replace
putmata X=($c_X), replace
putmata y=($c_y), replace
* Demeaning not actually necessary if constant partialled-out
mata: Z=Z :- mean(Z)
mata: X=X :- mean(X)
mata: y=y :- mean(y)
mata: Pz=Z*invsym(Z'Z)*Z'
mata: Mz=I(n) - Pz


mata: ytilda = y - null*X

***** K=1, iid *****

mata: Delta = invsym(Z'Z) * Z' * (X - (ytilda*ytilda'*Mz*X)/(ytilda' * Mz * ytilda))
mata: Ztilda = Z*Delta
mata: Pzt=Ztilda*invsym(Ztilda'Ztilda)*Ztilda'
mata: Mzt=I(n) - Pzt

* MD (Wald)
mata: AR = (ytilda' * Pz * ytilda) / (ytilda' * Mz * ytilda) * n
mata: K = (ytilda' * Pzt * ytilda) / (ytilda' * Mz * ytilda) * n
mata: J = AR-K
mata: st_numscalar("AR",AR)
mata: st_numscalar("K",K)
mata: st_numscalar("J",J)

* LM
mata: ARLM = (ytilda' * Pz * ytilda) / (ytilda' * ytilda) * n
mata: KLM = (ytilda' * Pzt * ytilda) / (ytilda' * ytilda) * n
mata: JLM = ARLM-KLM
mata: st_numscalar("ARLM",ARLM)
mata: st_numscalar("KLM",KLM)
mata: st_numscalar("JLM",JLM)

* MD (Wald), with/without partialling-out
qui weakiv10 ivreg2 $y $X2 ($X=$Z), null($null)
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null($null)
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
* LM with partialling-out (required)
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null($null) lm
assert reldif(ARLM,e(ar_chi2))< 1e-6
assert reldif(KLM,e(k_chi2))< 1e-6
assert reldif(JLM,e(j_chi2))< 1e-6

***** K=1, rob *****

mata: ehat = Mz*ytilda
mata: vhat = Mz*X

mata: S11_a = 1/n * quadcross(Z:*ytilda, Z:*ytilda)
mata: S11_b = 1/n * quadcross(Z:*ehat, Z:*ehat)
mata: S12_a = 1/n * quadcross(Z:*ytilda, Z:*X)
mata: S12_b = 1/n * quadcross(Z:*ehat, Z:*vhat)

mata: S11_ainv=invsym(S11_a)
mata: S11_binv=invsym(S11_b)

*******************************************

* Deltas, Ztildas, Ks
* LM
mata: Delta_a  = S11_ainv*Z'X  - S11_ainv*S12_a*S11_ainv*Z'ytilda
mata: Ztilda_a = Z*Delta_a
* MD
mata: Delta_b  = S11_binv*Z'X - S11_binv*S12_b*S11_binv*Z'ytilda
mata: Ztilda_b = Z*Delta_b

* MD (Wald)
mata: AR = ytilda' * Z * S11_binv * Z' * ytilda / n
mata: K = ytilda' * Ztilda_b * invsym(Delta_b' * S11_b * Delta_b) * Ztilda_b' * ytilda / n
mata: J = AR-K
mata: st_numscalar("AR",AR)
mata: st_numscalar("K",K)
mata: st_numscalar("J",J)

* LM
mata: ARLM = ytilda' * Z * S11_ainv * Z' * ytilda / n
mata: KLM = ytilda' * Ztilda_a * invsym(Delta_a' * S11_a * Delta_a) * Ztilda_a' * ytilda / n
mata: JLM = ARLM-KLM
mata: st_numscalar("ARLM",ARLM)
mata: st_numscalar("KLM",KLM)
mata: st_numscalar("JLM",JLM)

* MD (Wald), with/without partialling-out
qui weakiv10 ivreg2 $y $X2 ($X=$Z), null($null) rob
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null($null) rob
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
* LM with partialling-out (required)
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null($null) lm rob
assert reldif(ARLM,e(ar_chi2))< 1e-6
assert reldif(KLM,e(k_chi2))< 1e-6
assert reldif(JLM,e(j_chi2))< 1e-6

****************************** K=2 ***********************************

global y	price
global c_y	c_price
global Z	weight   turn   displacement
global c_Z	c_weight c_turn c_displacement
global X	mpg gear_ratio
global c_X	c_mpg c_gear_ratio
* Partialled-out exogenous regressors (not including constant)
global X2	foreign

scalar null_1=100
global null_1=null_1
scalar null_2=100
global null_2=null_2
qui desc
scalar n=r(N)
global n=n

* Mata variables, projection and annihilation matrices
mata: null_1=st_numscalar("null_1")
mata: null_2=st_numscalar("null_2")
* Column vector
mata: null=(null_1 \ null_2)
mata: n     =st_numscalar("n")
putmata Z=($c_Z), replace
putmata X=($c_X), replace
putmata y=($c_y), replace
* Demeaning not actually necessary if constant partialled-out
mata: Z=Z :- mean(Z)
mata: X=X :- mean(X)
mata: y=y :- mean(y)
mata: Pz=Z*invsym(Z'Z)*Z'
mata: Mz=I(n) - Pz


mata: ytilda = y - X*null

***** K=2, iid *****

mata: Delta = invsym(Z'Z) * Z' * (X - (ytilda*ytilda'*Mz*X)/(ytilda' * Mz * ytilda))
mata: Ztilda = Z*Delta
mata: Pzt=Ztilda*invsym(Ztilda'Ztilda)*Ztilda'
mata: Mzt=I(n) - Pzt

* MD (Wald)
mata: AR = (ytilda' * Pz * ytilda) / (ytilda' * Mz * ytilda) * n
mata: K = (ytilda' * Pzt * ytilda) / (ytilda' * Mz * ytilda) * n
mata: J = AR-K
mata: st_numscalar("AR",AR)
mata: st_numscalar("K",K)
mata: st_numscalar("J",J)

* LM
mata: ARLM = (ytilda' * Pz * ytilda) / (ytilda' * ytilda) * n
mata: KLM = (ytilda' * Pzt * ytilda) / (ytilda' * ytilda) * n
mata: JLM = ARLM-KLM
mata: st_numscalar("ARLM",ARLM)
mata: st_numscalar("KLM",KLM)
mata: st_numscalar("JLM",JLM)

* MD (Wald), with/without partialling-out
qui weakiv10 ivreg2 $y $X2 ($X=$Z), null1($null_1) null2($null_2)
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null1($null_1) null2($null_2)
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
* LM with partialling-out (required)
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null1($null_1) null2($null_2) lm
assert reldif(ARLM,e(ar_chi2))< 1e-6
assert reldif(KLM,e(k_chi2))< 1e-6
assert reldif(JLM,e(j_chi2))< 1e-6

***** K=2, rob *****

mata: ehat = Mz*ytilda
mata: vhat = Mz*X

mata: S11_a  = 1/n * quadcross(Z:*ytilda, Z:*ytilda)
mata: S11_b  = 1/n * quadcross(Z:*ehat, Z:*ehat)
mata: S12_a1 = 1/n * quadcross(Z:*ytilda, (Z:*X[.,1]) )
mata: S12_a2 = 1/n * quadcross(Z:*ytilda, (Z:*X[.,2]) )
mata: S12_b1 = 1/n * quadcross(Z:*ehat, (Z:*vhat[.,1]) )
mata: S12_b2 = 1/n * quadcross(Z:*ehat, (Z:*vhat[.,2]) )

mata: S11_ainv=invsym(S11_a)
mata: S11_binv=invsym(S11_b)

*******************************************

* Deltas, Ztildas, Ks
* LM
mata: Delta_a1 = S11_ainv*Z'X[.,1]  - S11_ainv*S12_a1*S11_ainv*Z'ytilda
mata: Delta_a2 = S11_ainv*Z'X[.,2]  - S11_ainv*S12_a2*S11_ainv*Z'ytilda
mata: Delta_a  = (Delta_a1, Delta_a2)
mata: Ztilda_a = Z*Delta_a
* MD
mata: Delta_b1 = S11_binv*Z'X[.,1] - S11_binv*S12_b1*S11_binv*Z'ytilda
mata: Delta_b2 = S11_binv*Z'X[.,2] - S11_binv*S12_b2*S11_binv*Z'ytilda
mata: Delta_b  = (Delta_b1, Delta_b2)
mata: Ztilda_b = Z*Delta_b

* MD (Wald)
mata: AR = ytilda' * Z * S11_binv * Z' * ytilda / n
mata: K = ytilda' * Ztilda_b * invsym(Delta_b' * S11_b * Delta_b) * Ztilda_b' * ytilda / n
mata: J = AR-K
mata: st_numscalar("AR",AR)
mata: st_numscalar("K",K)
mata: st_numscalar("J",J)

* LM
mata: ARLM = ytilda' * Z * S11_ainv * Z' * ytilda / n
mata: KLM = ytilda' * Ztilda_a * invsym(Delta_a' * S11_a * Delta_a) * Ztilda_a' * ytilda / n
mata: JLM = ARLM-KLM
mata: st_numscalar("ARLM",ARLM)
mata: st_numscalar("KLM",KLM)
mata: st_numscalar("JLM",JLM)

* MD (Wald), with/without partialling-out
qui weakiv10 ivreg2 $y $X2 ($X=$Z), null1($null_1) null2($null_2) rob
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null1($null_1) null2($null_2) rob
assert reldif(AR,e(ar_chi2))< 1e-6
assert reldif(K,e(k_chi2))< 1e-6
assert reldif(J,e(j_chi2))< 1e-6
* LM with partialling-out (required)
qui weakiv10 ivreg2 $y $X2 ($X=$Z), partial($X2) null1($null_1) null2($null_2) lm rob
assert reldif(ARLM,e(ar_chi2))< 1e-6
assert reldif(KLM,e(k_chi2))< 1e-6
assert reldif(JLM,e(j_chi2))< 1e-6


**********************************************************************
****************************** Done **********************************
**********************************************************************


log close
set more on
set rmsg off
