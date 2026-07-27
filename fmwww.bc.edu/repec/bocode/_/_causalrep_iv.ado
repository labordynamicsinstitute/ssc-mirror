*! version 1.0.0  25jul2026  Alexandre Poirier and Tymon Słoczyński

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 Alexandre Poirier and Tymon Słoczyński
* See the LICENSE file in this distribution for full text.

capture program drop _causalrep_iv
program define _causalrep_iv, eclass sortpreserve
	version 14
	syntax varlist(num fv) [if] [in], Treatment(varname numeric) Instrument(varname numeric) [Outcome(varname numeric) ivmodel(string) fsmodel(string) cate(varname numeric) PSTOLerance(numlist max=1) OSample(name) NOIsily vce(string)]
	
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
		capture summarize `instrument'
		if _rc!=0 {
			display as error "outcome and instrument must not be the same"
			exit 498
		}
	}
	
	restore, preserve
	drop `treatment'
	capture summarize `instrument'
	if _rc!=0 {
		display as error "treatment and instrument must not be the same"
		exit 498
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
	
	capture summarize `instrument'
	if _rc!=0 {
		display as error "instrument must not appear on the list of control variables"
		exit 498
	}
	
	restore
	
	if "`ivmodel'"=="" {
		local ivmodel regress
	}
	
	if "`ivmodel'"!="regress" & "`ivmodel'"!="logit" & "`ivmodel'"!="probit" {
		display as error "{bf:ivmodel(`ivmodel')} not allowed"
		exit 198
	}
	
	if "`fsmodel'"=="" {
		local fsmodel logit
	}
	
	if "`fsmodel'"!="regress" & "`fsmodel'"!="logit" & "`fsmodel'"!="probit" {
		display as error "{bf:fsmodel(`fsmodel')} not allowed"
		exit 198
	}
	
	if "`outcome'"!="" {
		tempvar touse pscore
		tempname b V N df_r iv
		
		if `"`vce'"'=="" local vce = "robust"
		
		quietly {
			`noisily' ivregress 2sls `outcome' (`treatment' = `instrument') `controls' `if' `in', vce(`vce')
			matrix `b' = e(b)
			matrix `V' = e(V)
			scalar `N' = e(N)
			scalar `df_r' = e(df_r)
			scalar `iv' = _b[`treatment']
			generate `touse' = e(sample)
			
			if "`ivmodel'"=="regress" regress `instrument' `controls' if `touse'==1
			else {
				capture `ivmodel' `instrument' `controls' if `touse'==1, asis
				if _rc!=0 {
					noisily display as error "the instrument propensity score model cannot be estimated"
					exit 430
				}
				if e(converged)==0 {
					noisily display as error "the instrument propensity score model cannot be estimated"
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
			regress `treatment' `instrument' `controls' `if' `in'
			scalar `N' = e(N)
			generate `touse' = e(sample)
			
			if "`ivmodel'"=="regress" regress `instrument' `controls' if `touse'==1
			else {
				capture `ivmodel' `instrument' `controls' if `touse'==1, asis
				if _rc!=0 {
					noisily display as error "the instrument propensity score model cannot be estimated"
					exit 430
				}
				if e(converged)==0 {
					noisily display as error "the instrument propensity score model cannot be estimated"
					exit 430
				}
			}
			predict double `pscore'
		}
	}
	
	*causalrep iv only allows binary treatments and instruments
	capture tabulate `treatment' if `touse'==1
	if _rc!=0 | (_rc==0 & r(r)!=2) {
		display as error "treatment must be binary"
		exit 450
	}
	
	capture tabulate `instrument' if `touse'==1
	if _rc!=0 | (_rc==0 & r(r)!=2) {
		display as error "instrument must be binary"
		exit 450
	}
	
	*causalrep iv only allows treatments and instruments that take on values zero or one
	quietly summarize `treatment' if `touse'==1
	if r(min)!=0 | r(max)!=1 {
		display as error "treatment must only take on values zero or one"
		exit 450
	}
	
	quietly summarize `instrument' if `touse'==1
	if r(min)!=0 | r(max)!=1 {
		display as error "instrument must only take on values zero or one"
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
	
	*overlap check
	if "`pstolerance'"=="" local pstolerance 1E-5
	if `pstolerance'<=0 | `pstolerance'>=0.5 {
		display as error "{bf:pstolerance()} must be > 0 and < 0.5"
		exit 198
	}
	
	tempvar violators
	quietly generate byte `violators' = (`pscore' < `pstolerance' | `pscore' > (1-`pstolerance')) if `touse'==1
	
	if "`osample'"!="" {
		capture confirm variable `osample'
		if _rc==0 {
			display as error "variable {bf:`osample'} already exists"
			exit 110
		}
		
		quietly generate byte `osample' = `violators'
		label variable `osample' "overlap violation indicator"
	}
	
	quietly count if `violators'==1
	local fail = r(N)
	if `fail' {
		if `pstolerance' < 0.001 display as error "{p}" `fail' " observation" ///
			cond(`fail'>1,"s","") " violate" cond(`fail'>1,"","s") ///
			" the overlap assumption (instrument propensity score outside [" ///
			trim(strofreal(`pstolerance',"%9.3e")) ///
			", 1 - " trim(strofreal(`pstolerance',"%9.3e")) "]);"
		else display as error "{p}" `fail' " observation" ///
			cond(`fail'>1,"s","") " violate" cond(`fail'>1,"","s") ///
			" the overlap assumption (instrument propensity score outside [" ///
			trim(strofreal(`pstolerance',"%9.3f")) ///
			", 1 - " trim(strofreal(`pstolerance',"%9.3f")) "]);"
		
		if "`osample'"!="" display as error "see variable {bf:`osample'}{p_end}"
		else display as error "use {bf:osample()} to identify violators{p_end}"
		
		exit 498
	}
	
	*estimate the conditional proportion of compliers
	tempvar D1 D0 fs weight varz
	tempname meanw prcomp miv mr
	
	if "`fsmodel'"=="regress" {
		capture regress `treatment' `controls' if `touse'==1 & `instrument'==1
		if _rc!=0 {
			display as error "conditional mean of treatment given Z=1 cannot be estimated"
			exit 430
		}
		else {
			quietly predict double `D1'
		}
		capture regress `treatment' `controls' if `touse'==1 & `instrument'==0
		if _rc!=0 {
			display as error "conditional mean of treatment given Z=0 cannot be estimated"
			exit 430
		}
		else {
			quietly predict double `D0'
		}
	}
	else {
		capture `fsmodel' `treatment' `controls' if `touse'==1 & `instrument'==1, asis
		if _rc!=0 {
			display as error "conditional mean of treatment given Z=1 cannot be estimated"
			exit 430
		}
		if e(converged)==0 {
			display as error "conditional mean of treatment given Z=1 cannot be estimated"
			exit 430
		}
		else {
			quietly predict double `D1'
		}
		capture `fsmodel' `treatment' `controls' if `touse'==1 & `instrument'==0, asis
		if _rc!=0 {
			display as error "conditional mean of treatment given Z=0 cannot be estimated"
			exit 430
		}
		if e(converged)==0 {
			display as error "conditional mean of treatment given Z=0 cannot be estimated"
			exit 430
		}
		else {
			quietly predict double `D0'
		}
	}
	
	quietly generate double `fs' = `D1' - `D0'
	
	quietly count if `touse'==1 & `fs'<0
	if "`cate'"!="" & r(N)>0 {
		display as error "the CATE-based MIV cannot be computed when estimated conditional complier shares are negative; rerun the command without {bf:cate()}"
		exit 459
	}
	
	quietly summarize `fs' if `touse'==1
	if abs(r(mean)) <= 1e-12 {
		display as error "the estimated proportion of compliers is zero; the unrestricted-CATE MIV cannot be computed"
		exit 459
	}
	else if r(mean)<0 {
		display ""
		display as error "Package assumes direction of monotonicity is D(1) >= D(0), but the average conditional first stage is negative. Consider redefining the instrument."
	}
	
	quietly generate double `varz' = `pscore'*(1-`pscore')
	quietly generate double `weight' = `fs'*`pscore'*(1-`pscore')
	quietly count if `touse'==1 & `weight'<0
	if r(N)>0 {
		display ""
		display as error "Negative weights detected: " r(N) " of " `N' " estimated weights are below 0."
		display ""
		display as error "The value reported below as the measure of internal validity (MIV) when the CATE function is unrestricted is the inverse maximum weight. The value reported as the measure of representativeness (MR) is the product of the inverse maximum weight and the estimated proportion of compliers. If any population weights are negative, the corresponding MIV and MR are zero. See Poirier and Słoczyński (2026) for details."
	}
	else {
		display ""
		display as text "No negative weights detected."
	}
	
	quietly {
		summarize `fs' if `touse'==1
		scalar `prcomp' = r(mean)
		summarize `weight' if `touse'==1
		scalar `meanw' = r(mean)
		summarize `varz' if `touse'==1
		local max_abs_varz = max(abs(r(min)), abs(r(max)))
		if `max_abs_varz' <= 1e-12 {
			noisily display ""
			noisily display as error "the maximum conditional variance of the instrument is zero; the unrestricted-CATE MIV cannot be computed"
			exit 459
		}
		
		scalar `miv' = `meanw'/(`prcomp'*r(max))
		scalar `mr' = `prcomp'*`miv'
		
		if "`cate'"!="" {
			tempvar aux diff rawdiff
			tempname late miv_cate mr_cate
			
			generate double `aux' = `fs'*`cate'
			summarize `aux' if `touse'==1
			scalar `late' = r(mean)/`prcomp'
			
			generate double `diff' = `fs'*(`cate' - `iv')
			summarize `diff' if `touse'==1
			local full_diff = r(mean)/`prcomp'
			
			generate double `rawdiff' = `cate' - `iv'
			
			summarize `cate' if `touse'==1
			local min_cate = r(min)
			local max_cate = r(max)
			
			local cate_tol = 1e-10 * max(1, abs(`iv'), abs(`late'), abs(`min_cate'), abs(`max_cate'))
			
			if `iv' < `min_cate' - `cate_tol' | `iv' > `max_cate' + `cate_tol' {
				scalar `miv_cate' = 0
				scalar `mr_cate' = 0
			}
			else if abs(`full_diff') <= `cate_tol' {
				scalar `miv_cate' = 1
				scalar `mr_cate' = `prcomp'
			}
			else if abs(`iv' - `min_cate') <= `cate_tol' | abs(`iv' - `max_cate') <= `cate_tol' {
				summarize `fs' if `touse'==1 & abs(`rawdiff') <= `cate_tol'
				scalar `miv_cate' = ((r(N)/`N')*r(mean))/`prcomp'
				scalar `mr_cate' = `prcomp'*`miv_cate'
			}
			else {
				*if original value of MIV is sufficiently small, search from the top; otherwise, search from the bottom
				if `miv' < 0.2 {
					local i = 0
					
					if `iv' > `late' {
						*the starting value of local mean can be an arbitrary value with a specific sign
						local mean = 1
						gsort -`touse' -`rawdiff'
						while `mean'>0 {
							local i = `i' + 1
							summarize `diff' in 1/`i'
							local mean = r(mean)/`prcomp'
						}
					}
					else {
						local mean = -1
						gsort -`touse' +`rawdiff'
						while `mean'<0 {
							local i = `i' + 1
							summarize `diff' in 1/`i'
							local mean = r(mean)/`prcomp'
						}
					}
				}
				else {
					local i = `N' + 1
					
					if `iv' > `late' {
						local mean = -1
						gsort -`touse' -`rawdiff'
						while `mean'<0 {
							local i = `i' - 1
							summarize `diff' in 1/`i'
							local mean = r(mean)/`prcomp'
						}
					}
					else {
						local mean = 1
						gsort -`touse' +`rawdiff'
						while `mean'>0 {
							local i = `i' - 1
							summarize `diff' in 1/`i'
							local mean = r(mean)/`prcomp'
						}
					}
					
					if `i' < `N' {
						local i = `i' + 1
						summarize `diff' in 1/`i'
						local mean = r(mean)/`prcomp'
					}
				}
				
				summarize `fs' in 1/`i'
				scalar `miv_cate' = ((`i'/`N')*r(mean))/`prcomp' - ((`i'/`N')*`mean')/`rawdiff'[`i']
				scalar `mr_cate' = `prcomp'*`miv_cate'
			}
		}
	}
	
	if "`outcome'"!="" {
		display ""
		display as text `""IV" is the linear IV estimate of the effect of "' as result `"`treatment'"' as text `" on "' as result `"`outcome'"' as text `"."'
		display ""
		if abs(`iv')>1 display as text "    IV  =  " as result %-9.4g `iv'
		else display as text "    IV  =  " as result %5.3f `iv'
	}
	display ""
	display as text `""MIV" is the estimated measure of internal validity of the IV estimand with respect to the subpopulation of compliers."'
	display ""
	if "`cate'"=="" display as text "   MIV  =  " as result %5.3f `miv'
	else {
		display as text "No restrictions on the CATE function:   MIV  =  " as result %5.3f `miv'
		display as text "   Using the estimated CATE function:   MIV  =  " as result %5.3f `miv_cate'
	}
	display ""
	display as text `""MR" is the estimated measure of representativeness, which equals the MIV times the proportion of compliers."'
	display ""
	if "`cate'"=="" display as text "    MR  =  " as result %5.3f `mr'
	else {
		display as text "No restrictions on the CATE function:    MR  =  " as result %5.3f `mr'
		display as text "   Using the estimated CATE function:    MR  =  " as result %5.3f `mr_cate'
	}
	
	if "`outcome'"!="" ereturn post `b' `V', esample(`touse') depname(`outcome') buildfvinfo
	else {
		ereturn clear
		ereturn post, esample(`touse')
	}
	
	ereturn scalar N = `N'
	if "`outcome'"!="" ereturn scalar df_r = `df_r'
	if "`outcome'"!="" ereturn scalar iv = `iv'
	if "`cate'"!="" ereturn scalar late = `late'
	ereturn scalar miv = `miv'
	if "`cate'"!="" ereturn scalar miv_cate = `miv_cate'
	ereturn scalar mr = `mr'
	if "`cate'"!="" ereturn scalar mr_cate = `mr_cate'
	
	if "`outcome'"!="" ereturn local depvar `"`outcome'"'
end
