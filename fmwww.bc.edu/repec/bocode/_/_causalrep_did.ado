*! version 1.0.0  25jul2026  Alexandre Poirier and Tymon Słoczyński

* SPDX-License-Identifier: MIT
* Copyright (c) 2026 Alexandre Poirier and Tymon Słoczyński
* See the LICENSE file in this distribution for full text.

capture program drop _causalrep_did
program define _causalrep_did, eclass sortpreserve
	version 14
	syntax varlist(min=2 max=2 numeric) [if] [in], Treatment(varname numeric) [Outcome(varname numeric) cate(varname numeric) NOIsily vce(str)]
	
	tokenize `varlist'
	
	if "`outcome'"=="" & "`cate'"!="" {
		display as error "option {bf:cate} requires outcome to be specified"
		exit 198
	}
	
	preserve
	if "`outcome'"!="" {
		drop `outcome'
		capture summarize `1'
		if _rc!=0 {
			display as error "outcome and group variables must not be the same"
			exit 498
		}
		capture summarize `2'
		if _rc!=0 {
			display as error "outcome and time variables must not be the same"
			exit 498
		}
		capture summarize `treatment'
		if _rc!=0 {
			display as error "outcome and treatment must not be the same"
			exit 498
		}
	}
	
	restore, preserve
	drop `treatment'
	capture summarize `1'
	if _rc!=0 {
		display as error "treatment and group variables must not be the same"
		exit 498
	}
	capture summarize `2'
	if _rc!=0 {
		display as error "treatment and time variables must not be the same"
		exit 498
	}
	
	restore, preserve
	drop `1'
	capture summarize `2'
	if _rc!=0 {
		display as error "group and time variables must not be the same"
		exit 498
	}
	
	restore
	
	quietly {
		if "`outcome'"!="" {
			tempvar touse
			tempname b V N df_r twfe
			
			if "`vce'"=="" local vce = "cluster `1'"
			`noisily' regress `outcome' `treatment' i.`1' i.`2' `if' `in', vce(`vce')
			matrix `b' = e(b)
			matrix `V' = e(V)
			scalar `N' = e(N)
			scalar `df_r' = e(df_r)
			scalar `twfe' = _b[`treatment']
			generate byte `touse' = e(sample)
		}
		else {
			tempvar touse
			tempname N
			
			regress `treatment' i.`1' i.`2' `if' `in'
			scalar `N' = e(N)
			generate byte `touse' = e(sample)
		}
		
		*the time variable must be recorded as integer values
		capture assert `2'==int(`2') if `touse'==1
		if _rc!=0 {
			noisily display as error "the time variable must be recorded as integer values"
			exit 459
		}
		
		*causalrep did only allows binary treatments
		capture tabulate `treatment' if `touse'==1
		if _rc!=0 | (_rc==0 & r(r)!=2) {
			noisily display as error "treatment must be binary"
			exit 450
		}
		
		*causalrep did only allows treatments that take on values zero or one
		quietly summarize `treatment' if `touse'==1
		if r(min)!=0 | r(max)!=1 {
			noisily display as error "treatment must only take on values zero or one"
			exit 450
		}
		
		*verify whether there are any missing CATE values within the estimation sample
		if "`cate'"!="" {
			quietly count if `touse'==1 & `treatment'==1 & missing(`cate')
			if r(N)>0 {
				noisily display as error "CATE must be nonmissing for all treated units in the estimation sample"
				exit 416
			}
		}
		
		*verify the balanced group-period structure
		tempvar tag_t tag_gt nperiods_g
		tempvar n_gt min_n_gt max_n_gt
		tempvar dmin_gt dmax_gt
		
		*count the number of distinct periods in the estimation sample
		egen byte `tag_t' = tag(`2') if `touse'==1
		count if `tag_t'==1
		local nperiods = r(N)
		
		*check that every group is represented in every period
		egen byte `tag_gt' = tag(`1' `2') if `touse'==1
		bysort `1': egen long `nperiods_g' = total(`tag_gt')
		capture assert `nperiods_g'==`nperiods' if `touse'==1
		if _rc!=0 {
			noisily display as error "the estimation sample is not balanced across group-period cells; every group must be represented in every sample period"
			exit 459
		}
		
		*count observations in each group-period cell
		bysort `1' `2': egen long `n_gt' = total(`touse')
		
		*check that each group contributes the same number of observations in every period
		bysort `1': egen long `min_n_gt' = min(cond(`touse'==1, `n_gt', .))
		bysort `1': egen long `max_n_gt' = max(cond(`touse'==1, `n_gt', .))
		capture assert `min_n_gt'==`max_n_gt' if `touse'==1
		if _rc!=0 {
			noisily display as error "group-period cell sizes must be constant over time within each group"
			exit 459
		}
		
		*check that treatment is constant within each group-period cell
		bysort `1' `2': egen double `dmin_gt' = min(cond(`touse'==1, `treatment', .))
		bysort `1' `2': egen double `dmax_gt' = max(cond(`touse'==1, `treatment', .))
		capture assert `dmin_gt'==`dmax_gt' if `touse'==1
		if _rc!=0 {
			noisily display as error "treatment must be constant within each group-period cell"
			exit 459
		}
		
		*record all timing groups
		tempvar aux1 aux2 group
		tempname always
		
		summarize `2' if `touse'==1
		local minT = r(min)
		local maxT = r(max)
		
		summarize `2' if `touse'==1 & `treatment'==1
		local minTD = r(min)
		local maxTD = r(max)
		
		scalar `always' = `minT'==`minTD'
		
		if `always'==1 {
			noisily display as error "at least one group is treated in the first sample period"
			exit 459
		}
		
		sort `touse' `1' `2'
		
		generate double `aux1' = `2' if `touse'==1 & `treatment'==1
		by `touse' `1': egen double `group' = min(`aux1')
		
		generate double `aux2' = `group' - `2'
		summarize `aux2' if `touse'==1 & `treatment'==0
		if r(min)<0 {
			noisily display as error "there is a group that exits the treatment"
			exit 459
		}
		
		*compute the weights
		tempvar share_t share_g weight
		tempname N_neg N_tot
		
		by `touse' `1': egen double `share_t' = mean(`treatment')
		bysort `touse' `2': egen double `share_g' = mean(`treatment')
		
		summarize `treatment' if `touse'==1
		generate double `weight' = 1 - `share_t' - `share_g' + r(mean)
		
		count if `touse'==1 & `treatment'==1 & `weight'<0
		scalar `N_neg' = r(N)
		
		count if `touse'==1 & `treatment'==1
		scalar `N_tot' = r(N)
		
		if `N_neg'>0 {
			noisily display ""
			noisily display as error "Negative weights detected: " `N_neg' " of " `N_tot' " estimated weights are below 0."
			noisily display ""
			noisily display as error "The value reported below as the measure of internal validity (MIV) when the CATE function is unrestricted is the inverse maximum weight. The value reported as the measure of representativeness (MR) is the product of the inverse maximum weight and the estimated proportion of treated units. If any population weights are negative, the corresponding MIV and MR are zero. See Poirier and Słoczyński (2026) for details."
		}
		else {
			noisily display ""
			noisily display as text "No negative weights detected."
		}
		
		*compute the MIV and MR
		tempname prtreat miv mr
		
		summarize `treatment' if `touse'==1
		scalar `prtreat' = r(mean)
		
		summarize `weight' if `touse'==1 & `treatment'==1
		local max_weight = r(max)
		if abs(`max_weight') <= 1e-12 {
			noisily display ""
			noisily display as error "the maximum estimated TWFE weight is zero; the unrestricted-CATE MIV cannot be computed"
			exit 459
		}
		
		scalar `miv' = r(mean)/`max_weight'
		scalar `mr' = `prtreat'*`miv'
		
		*consider a given CATE function
		if "`cate'"!="" {
			tempvar diff
			tempname att miv_cate mr_cate
			
			summarize `cate' if `touse'==1 & `treatment'==1
			scalar `att' = r(mean)
			
			generate double `diff' = `cate' - `twfe'
			summarize `diff' if `touse'==1 & `treatment'==1
			local full_diff = r(mean)
			
			summarize `cate' if `touse'==1 & `treatment'==1
			local min_cate = r(min)
			local max_cate = r(max)
			
			local cate_tol = 1e-10 * max(1, abs(`twfe'), abs(`att'), abs(`min_cate'), abs(`max_cate'))
			
			if `twfe' < `min_cate' - `cate_tol' | `twfe' > `max_cate' + `cate_tol' {
				scalar `miv_cate' = 0
				scalar `mr_cate' = 0
			}
			else if abs(`full_diff') <= `cate_tol' {
				scalar `miv_cate' = 1
				scalar `mr_cate' = `prtreat'
			}
			else if abs(`twfe' - `min_cate') <= `cate_tol' | abs(`twfe' - `max_cate') <= `cate_tol' {
				count if `touse'==1 & `treatment'==1 & abs(`diff') <= `cate_tol'
				scalar `miv_cate' = r(N)/`N_tot'
				scalar `mr_cate' = `prtreat'*`miv_cate'
			}
			else {
				*if original value of MIV is sufficiently small, search from the top; otherwise, search from the bottom
				if `miv' < 0.2 {
					local i = 0
					
					if `twfe' > `att' {
						*the starting value of local mean can be an arbitrary value with a specific sign
						local mean = 1
						gsort -`touse' -`treatment' -`diff'
						while `mean'>0 {
							local i = `i' + 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
					else {
						local mean = -1
						gsort -`touse' -`treatment' +`diff'
						while `mean'<0 {
							local i = `i' + 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
				}
				else {
					local i = `N_tot' + 1
					
					if `twfe' > `att' {
						local mean = -1
						gsort -`touse' -`treatment' -`diff'
						while `mean'<0 {
							local i = `i' - 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
					else {
						local mean = 1
						gsort -`touse' -`treatment' +`diff'
						while `mean'>0 {
							local i = `i' - 1
							summarize `diff' in 1/`i'
							local mean = r(mean)
						}
					}
					
					if `i' < `N_tot' {
						local i = `i' + 1
						summarize `diff' in 1/`i'
						local mean = r(mean)
					}
				}
				
				scalar `miv_cate' = (`i'/`N_tot') - ((`i'/`N_tot')*`mean')/`diff'[`i']
				scalar `mr_cate' = `prtreat'*`miv_cate'
			}
		}
	}
	
	if "`outcome'"!="" {
		display ""
		display as text `""TWFE" is the TWFE estimate of the effect of "' as result `"`treatment'"' as text `" on "' as result `"`outcome'"' as text `"."'
		display ""
		if abs(`twfe')>1 display as text "  TWFE  =  " as result %-9.4g `twfe'
		else display as text "  TWFE  =  " as result %5.3f `twfe'
	}
	display ""
	display as text `""MIV" is the estimated measure of internal validity of the TWFE estimand with respect to the subpopulation of treated units."'
	display ""
	if "`cate'"=="" display as text "   MIV  =  " as result %5.3f `miv'
	else {
		display as text "No restrictions on the CATE function:   MIV  =  " as result %5.3f `miv'
		display as text "   Using the estimated CATE function:   MIV  =  " as result %5.3f `miv_cate'
	}
	display ""
	display as text `""MR" is the estimated measure of representativeness, which equals the MIV times the proportion of treated units."'
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
	if "`outcome'"!="" ereturn scalar twfe = `twfe'
	if "`cate'"!="" ereturn scalar att = `att'
	ereturn scalar miv = `miv'
	if "`cate'"!="" ereturn scalar miv_cate = `miv_cate'
	ereturn scalar mr = `mr'
	if "`cate'"!="" ereturn scalar mr_cate = `mr_cate'
	
	if "`outcome'"!="" ereturn local depvar `"`outcome'"'
end
