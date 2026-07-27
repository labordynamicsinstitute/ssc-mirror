*! version 1.0.0  25jul2026  Alexandre Poirier and Tymon Słoczyński

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 Alexandre Poirier and Tymon Słoczyński
* See the LICENSE file in this distribution for full text.

capture program drop _causalrep_ols
program define _causalrep_ols, eclass sortpreserve
	version 14
	syntax varlist(num fv) [if] [in], Treatment(varname numeric) [Outcome(varname numeric) tmodel(string) cate(varname numeric) NOIsily vce(str)]
	
	local controls `"`varlist'"'
	fvrevar `controls', list
	local basevars `r(varlist)'
	
	if "`outcome'"=="" & "`cate'"!="" {
		display as error "option {bf:cate} requires outcome to be specified"
		exit 198
	}
	
	preserve
	if "`outcome'"!="" {
		drop `outcome'
		capture summarize `treatment'
		if _rc!=0 {
			display as error "outcome and treatment must not be the same"
			exit 498
		}
	}
	
	restore, preserve
	drop `basevars'
	
	if "`outcome'"!="" {
		capture summarize `outcome'
		if _rc!=0 {
			display as error "outcome must not appear on the list of control variables"
			exit 498
		}
	}
	
	capture summarize `treatment'
	if _rc!=0 {
		display as error "treatment must not appear on the list of control variables"
		exit 498
	}
	
	restore
	
	if "`tmodel'"=="" {
		local tmodel regress
	}
	
	if "`tmodel'"!="regress" & "`tmodel'"!="logit" & "`tmodel'"!="probit" {
		display as error "{bf:tmodel(`tmodel')} not allowed"
		exit 198
	}
	
	if "`outcome'"!="" {
		tempvar touse pscore
		tempname b V N df_r ols
		
		if `"`vce'"'=="" local vce = "robust"
		
		quietly {
			`noisily' regress `outcome' `treatment' `controls' `if' `in', vce(`vce')
			matrix `b' = e(b)
			matrix `V' = e(V)
			scalar `N' = e(N)
			scalar `df_r' = e(df_r)
			scalar `ols' = _b[`treatment']
			generate `touse' = e(sample)
			
			if "`tmodel'"=="regress" regress `treatment' `controls' if `touse'==1
			else {
				capture `tmodel' `treatment' `controls' if `touse'==1, asis
				if _rc!=0 {
					noisily display as error "the propensity score model cannot be estimated"
					exit 430
				}
				if e(converged)==0 {
					noisily display as error "the propensity score model cannot be estimated"
					exit 430
				}
			}
			predict double `pscore'
		}
	}
	else {
		tempvar touse pscore
		tempname N
		
		quietly {
			if "`tmodel'"=="regress" regress `treatment' `controls' `if' `in'
			else {
				capture `tmodel' `treatment' `controls' `if' `in', asis
				if _rc!=0 {
					noisily display as error "the propensity score model cannot be estimated"
					exit 430
				}
				if e(converged)==0 {
					noisily display as error "the propensity score model cannot be estimated"
					exit 430
				}
			}
			scalar `N' = e(N)
			generate `touse' = e(sample)
			predict double `pscore'
		}
	}
	
	*causalrep ols only allows binary treatments
	capture tabulate `treatment' if `touse'==1
	if _rc!=0 | (_rc==0 & r(r)!=2) {
		display as error "treatment must be binary"
		exit 450
	}
	
	*causalrep ols only allows treatments that take on values zero or one
	quietly summarize `treatment' if `touse'==1
	if r(min)!=0 | r(max)!=1 {
		display as error "treatment must only take on values zero or one"
		exit 450
	}
	
	*verify whether there are any missing CATE values within the estimation sample
	if "`cate'"!="" {
		quietly count if `touse'==1 & `cate'<.
		if r(N)<`N' {
			display as error "there must be no missing CATE values within the estimation sample"
			exit 416
		}
	}
	
	*verify whether any estimated propensity scores are below 0 or above 1
	if "`tmodel'"=="regress" {
		quietly count if `touse'==1 & (`pscore'<0 | `pscore'>1)
		if r(N)>0 {
			display ""
			display as error "Negative weights detected: " r(N) " of " `N' " estimated propensity scores are below 0 or above 1."
			display ""
			display as error "The value reported below as the measure of internal validity (MIV) when the CATE function is unrestricted is the inverse maximum weight. If any population weights are negative, the corresponding MIV is zero. See Poirier and Słoczyński (2026) for details."
		}
		else {
			display ""
			display as text "No negative weights detected."
		}
	}
	
	tempvar weight
	tempname miv
	
	quietly {
		generate double `weight' = `pscore'*(1-`pscore')
		
		summarize `weight' if `touse'==1
		local max_weight = r(max)
		if abs(`max_weight') <= 1e-12 {
			if "`tmodel'"=="regress" noisily display ""
			noisily display as error "the maximum estimated OLS weight is zero; the unrestricted-CATE MIV cannot be computed"
			exit 459
		}
		scalar `miv' = r(mean)/`max_weight'
		
		if "`cate'"!="" {
			tempvar diff
			tempname ate miv_cate
			
			generate double `diff' = `cate' - `ols'
			
			summarize `diff' if `touse'==1
			local full_diff = r(mean)
			
			summarize `cate' if `touse'==1
			scalar `ate' = r(mean)
			
			local min_cate = r(min)
			local max_cate = r(max)
			
			local cate_tol = 1e-10 * max(1, abs(`ols'), abs(`ate'), abs(`min_cate'), abs(`max_cate'))
			
			if `ols' < `min_cate' - `cate_tol' | `ols' > `max_cate' + `cate_tol' {
				scalar `miv_cate' = 0
			}
			else if abs(`full_diff') <= `cate_tol' {
				scalar `miv_cate' = 1
			}
			else if abs(`ols' - `min_cate') <= `cate_tol' | abs(`ols' - `max_cate') <= `cate_tol' {
				count if `touse'==1 & abs(`diff') <= `cate_tol'
				scalar `miv_cate' = r(N)/`N'
			}
			else {
				*if original value of MIV is sufficiently small, search from the top; otherwise, search from the bottom
				if `miv' < 0.2 {
					local i = 0
					
					if `ols' > `ate' {
						*the starting value of local mean can be an arbitrary value with a specific sign
						local mean = 1
						gsort -`touse' -`diff'
						while `mean'>0 {
							local i = `i' + 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
					else {
						local mean = -1
						gsort -`touse' +`diff'
						while `mean'<0 {
							local i = `i' + 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
				}
				else {
					local i = `N' + 1
					
					if `ols' > `ate' {
						local mean = -1
						gsort -`touse' -`diff'
						while `mean'<0 {
							local i = `i' - 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
					else {
						local mean = 1
						gsort -`touse' +`diff'
						while `mean'>0 {
							local i = `i' - 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
					
					if `i' < `N' {
						local i = `i' + 1
						summarize `diff' in 1/`i'
						local mean = r(mean)
					}
				}
				
				scalar `miv_cate' = (`i'/`N') - ((`i'/`N')*`mean')/`diff'[`i']
			}
		}
	}
	
	if "`outcome'"!="" {
		display ""
		display as text `""OLS" is the OLS estimate of the effect of "' as result `"`treatment'"' as text `" on "' as result `"`outcome'"' as text `"."'
		display ""
		if abs(`ols')>1 display as text "   OLS  =  " as result %-9.4g `ols'
		else display as text "   OLS  =  " as result %5.3f `ols'
	}
	display ""
	display as text `""MIV" is the estimated measure of internal validity of the OLS estimand with respect to the entire population."'
	display ""
	if "`cate'"=="" display as text "   MIV  =  " as result %5.3f `miv'
	else {
		display as text "No restrictions on the CATE function:   MIV  =  " as result %5.3f `miv'
		display as text "   Using the estimated CATE function:   MIV  =  " as result %5.3f `miv_cate'
	}
	
	if "`outcome'"!="" ereturn post `b' `V', esample(`touse') depname(`outcome') buildfvinfo
	else {
		ereturn clear
		ereturn post, esample(`touse')
	}
	
	ereturn scalar N = `N'
	if "`outcome'"!="" ereturn scalar df_r = `df_r'
	if "`outcome'"!="" ereturn scalar ols = `ols'
	if "`cate'"!="" ereturn scalar ate = `ate'
	ereturn scalar miv = `miv'
	if "`cate'"!="" ereturn scalar miv_cate = `miv_cate'
	
	if "`outcome'"!="" ereturn local depvar `"`outcome'"'
end
