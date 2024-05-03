/*******************************************************************************
*! healthequal version 1.0 02 May 2024

About: 			healthequal calculates summary measures of health inequality
Copyright: 		(C) World Health Organization 2024
License:		GNU Affero General Public License, version 3, 19 November 2007 (AGPL v3)
				https://www.gnu.org/licenses/agpl-3.0.txt
*******************************************************************************/

program define healthequal, rclass byable(recall) sortpreserve
version 11.0
syntax varname [if] [pweight/], Measure(string) [AVerage(varname numeric)] [se(varname numeric)] [Order(varname numeric)] [SCale(varname numeric)] [fav(varname numeric)] [REFerence(varname numeric)] [DIMension(varname numeric)] [svy] [linear] [LIMits(numlist min=1 max=2 missingok)] [WAGstaff] [ERReygers] [sim(numlist integer max=1)] [FORmat(passthru)] [noPRINT] [FORCE] 

clear matrix
preserve
quietly {

*	Implement [if] (note: novarlist option keeps missing values) 
	marksample touse, novarlist
	qui keep if `touse'==1

********************************************************************************
*	DATA CHECKS 

*	Measure
	foreach m in `measure' {
		if !inlist("`m'","aci","bgsd","bgv","cov","idisu","idisw","mdbu","mdbw","mdmu") {
			if !inlist("`m'","mdmw","mdru","mdrw","mld","paf","par","rci","rii","sii") {
				if !inlist("`m'","ti","d","r") {
					di as error "ERROR: Measure name not specified correctly."
					exit
				}
			}
		}
	}

*	Simulations
	if "`sim'"=="" local sim 100
	
*	Estimate variable
	local estimate `varlist'
	
*	Population weight variable
	tempvar population
	if "`exp'" != "" gen `population'=`exp'
	
*	Save original dataset (including missing values)
	tempfile data 
	save `data', replace
		
*	Loop over selected measures
	foreach m in `measure' {
		
		use `data', clear
		
	*OPTION SPECIFICATION CHECKS

		*WEIGHT must be specified for certain measures if the SVY option not used 
		if inlist("`m'","aci","rci","rii","sii") {
			if "`svy'"=="" {
				capture qui tab `population'
				if _rc!=0 {
					di as error "ERROR [" "`m'" "]: weight variable must be specified or the svy option used."
					exit
				}
				if _rc==0 local weight `population'
			}
			*If SVY option is used, svyset must be used
			if "`svy'"!="" {
				capture qui svyset
				if _rc==111 {
					di as error "ERROR [" "`m'" "]: svyset must be used to identify the survey design characteristics prior to running healthequal with the svy option."
					exit
				}
				qui svyset
				if r(settings)==", clear" {
					di as error "ERROR [" "`m'" "]: svyset must be used to identify the survey design characteristics prior to running healthequal with the svy option."
					exit
				}
				*If SVY option is used, WEIGHT must not be specified
				capture qui tab `population'
				if _rc==0 {
					di as error "ERROR [" "`m'" "]: When the svy option is used, population weights should only be specified using svyset."
					exit
				}
				if _rc!=0 {
					qui svyset
					local wvar=r(wvar)
					if "`wvar'"!="." local weight "`wvar'"
					else local weight=1
				}
			}
		}
	
		*WEIGHT must be specified for certain measures
		if inlist("`m'","bgsd","bgv","cov","mdmw","idisw","mdbw","mdrw","mld","ti") {
			capture qui tab `population'
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: population weight variable must be specified."
				exit
			}
		}

		*If WEIGHT is not specified for certain measures then AVERAGE must be specified
		if inlist("`m'","idisu","mdmu","paf","par") {
			capture qui tab `population'
			if _rc!=0 {
				capture qui tab `average'
				if _rc!=0 {
					di as error "ERROR [" "`m'" "]: either a population weight variable or average() must be specified."
					exit
				}
			}
			capture qui tab `average'
			if _rc==0 {
				qui summ `average'
				if r(min)!=r(max) {
					di as error "ERROR [" "`m'" "]: average() variable must be consistent across all subgroups, for the same indicator."
					exit
				}
				capture qui tab `population'
				if _rc!=0 {
					di as error "WARNING [" "`m'" "]: population weight variable is required for the calculation of 95% confidence intervals."
				}
			}
		}
		
		*DIMENSION must be specified for certain measures 
		if inlist("`m'","paf","par","d","r") {
			capture qui tab `dimension'
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: dimension() must be specified."
				exit
			}
			*Must contain 0 or 1 and be consistent across all subgroups 
			capture assert inlist(`dimension', 0, 1) 
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: dimension() variable must contain 0 or 1."
				exit
			}
			qui summ `dimension'
			if r(min)!=r(max) {
				di as error "ERROR [" "`m'" "]: dimension() variable must be consistent across all subgroups, for the same indicator."
				exit
			}
		}
		
		*SUBGROUP ORDER must be specified for certain measures 
		if inlist("`m'","aci","sii","rci","rii") {
			capture qui tab `order'
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: order() must be specified."
				exit
			}
			*Must be integers in ascending order
			qui inspect `order'
			if r(N)!=r(N_posint) {
				di as error "ERROR [" "`m'" "]: order() variable must contain integers."
				exit
			}
			keep `order'
			duplicates drop
			sort `order'
			tempname n diff
			gen `n'=_n
			gen `diff'=`n'-`order'
			qui summ `diff'
			if r(max)!=0 | r(min)!=0 {
				di as error "ERROR [" "`m'" "]: order() variable must contain integers in increasing order (when all non-missing estimates are considered)."
				exit
			}
			use `data', clear
		}
	
		*SUBGROUP ORDER must be specified for certain measures if the dimension is ordered 
		if inlist("`m'","paf","par","d","r") {
			qui summ `dimension'
			if r(max)==1 {
				capture qui tab `order'
				if _rc!=0 {
					di as error "ERROR [" "`m'" "]: order() must be specified."
					exit
				}
				*Must be integers in ascending order
				qui inspect `order'
				if r(N)!=r(N_posint) {
					di as error "ERROR [" "`m'" "]: order() variable must contain integers."
					exit
				}
				keep `order'
				duplicates drop
				sort `order'
				tempname n diff
				gen `n'=_n
				gen `diff'=`n'-`order'
				qui summ `diff'
				if (r(max)!=0 | r(min)!=0) {
					di as error "ERROR [" "`m'" "]: order() variable must contain integers in increasing order (when all non-missing estimates are considered)."
					exit
				}
				use `data', clear
			}
		}	
		
		*INDICATOR SCALE optional for certain measures. Must contain value greater than 0 and be consistent across all subgroups 
		if inlist("`m'","bgsd","cov","mdbu","mdbw","mdmu","mdmw","mdru","mdrw") {
			capture qui tab `scale'
			if _rc!=0 {
				di as error "WARNING [" "`m'" "]: scale() is required for the calculation of 95% confidence intervals."
			}
			if _rc==0 {
				qui summ `scale'
				if r(min)==0 {
					di as error "ERROR [" "`m'" "]: scale() variable must be greater than zero."
					exit
				}
				if r(min)!=r(max) {
					di as error "ERROR [" "`m'" "]: scale() variable must be consistent across all subgroups, for the same indicator."
					exit
				}
			}
		}
		
		if inlist("`m'","idisu","idisw","paf","par") {
			capture qui tab `scale'
			if _rc!=0 {
				di as error "WARNING [" "`m'" "]: scale() is required for the calculation of 95% confidence intervals."
			}
			if _rc==0 {
				qui summ `scale'
				if r(min)==0 {
					di as error "ERROR [" "`m'" "]: scale() variable must be greater than zero."
					exit
				}
				if r(min)!=r(max) {
					di as error "ERROR [" "`m'" "]: scale() variable must be consistent across all subgroups, for the same indicator."
					exit
				}
			}
		}
		
		*FAVOURABLE INDICATOR must be specified for certain measures 
		if inlist("`m'","paf","par","mdbu","mdbw","d","r") {
			capture qui tab `fav'
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: fav() must be specified."
				exit
			}
			*Must contain 0 or 1, consistent across all subgroups 
			capture assert inlist(`fav', 0, 1) 
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: fav() variable must contain 0 or 1."
				exit
			}
			qui summ `fav'
			if r(min)!=r(max) {
				di as error "ERROR [" "`m'" "]: fav() variable must be consistent across all subgroups, for the same indicator."
				exit
			}
		}
	
		*REFERENCE SUBGROUP must be specified for certain measures
		if inlist("`m'","mdru","mdrw") {
			capture qui tab `reference'
			if _rc!=0 {
				di as error "ERROR [" "`m'" "]: reference() must be specified."
				exit
			}
			*Must contain 1 for one subgroup 
			count if `reference'==1
			if r(N)!=1 {
				di as error "ERROR [" "`m'" "]: reference() must identify one reference subgroup with the value 1."
				exit
			}
		}
		
	*ESTIMATES CHECKS

		*Estimate cannot be missing for any subgroups (for ordered measures)
		if "`force'"=="" {
			if inlist("`m'","aci","sii","rci","rii") {
				qui misstable summarize `estimate'
				if r(N_eq_dot)!=. {
					di as error "ERROR [" "`m'" "]: Estimate value is missing for at least one record. Specify the force option to allow missing values."
					exit
				}
			}
		}
	
		*Estimate cannot be missing for more than 85% of subgroups (for non-ordered measures)
		if inlist("`m'","bgsd","bgv","cov","idisu","idisw","mdbu","mdbw","mdmu","mdmw") {
			qui tab `estimate', mi
			scalar total=r(N)
			qui tab `estimate'
			scalar nomissing=r(N)
			tempname prop
			gen `prop'=nomissing/total*100
			if `prop' < 85 & "`force'"=="" {
				di as error "ERROR [" "`m'" "]: More than 85% of subgroups have missing estimates. Specify the force option to allow missing values."
				exit
			}
			if `prop' != 100 {
				replace `prop'=round(`prop',1)
				di as error "WARNING [" "`m'" "]: Summary measure calculation based on " `prop' "% of subgroups, with data available."
			}
		}
		
		if inlist("`m'","mld","ti") {
			qui summarize `estimate'
			scalar nomissing=r(N)
			tempname n prop
			gen `n'=_n
			qui summarize `n'
			scalar rows=r(N)
			gen `prop'=nomissing/rows*100
			if `prop' < 85 & "`force'"=="" {
				di as error "ERROR [" "`m'" "]: More than 85% of subgroups have missing estimates. Specify the force option to allow missing values."
				exit
			}
			if `prop' != 100 {
				replace `prop'=round(`prop',1)
				di as error "WARNING [" "`m'" "]: Summary measure calculation based on " `prop' "% of subgroups, with data available."
			}
		}
		
		*Estimate cannot be missing for any subgroups (for ordered measures) or cannot be missing for more than 85% of subgroups (for non-ordered measures)
		if "`force'"=="" {
			if inlist("`m'","par","paf") {
				qui summarize `dimension'
				if r(max)==1 {
					qui misstable summarize `estimate'
					if r(N_eq_dot)!=. {
						di as error "ERROR [" "`m'" "]: Estimate value is missing for at least one record."
						exit
					}
				}
				if r(max)==0 {
					qui summarize `estimate'
					scalar nomissing=r(N)
					tempname n prop
					gen `n'=_n
					qui summarize `n'
					scalar rows=r(N)
					gen `prop'=nomissing/rows*100
					if `prop' < 85 & "`force'"=="" {
						di as error "ERROR [" "`m'" "]: More than 85% of subgroups have missing estimates. Specify the force option to allow missing values."
						exit
					}
					if `prop' != 100 {
						replace `prop'=round(`prop',1)
						di as error "WARNING [" "`m'" "]: Summary measure calculation based on " `prop' "% of subgroups, with data available."
					}			
				}
			}
		}
		
		*Identify reference estimates for d and r
		if inlist("`m'","d","r") {
			tempname y1 y2 se1 se2
			if `dimension'==1 {										// ordered dimension
				if `fav'==1 sort `order'
				else gsort - `order'
				qui summarize `estimate' if _n==_N
				scalar `y1'=r(max)
				qui summarize `estimate' if _n==1
				scalar `y2'=r(max)
				capture qui tab `se'
				if _rc==0 {
					qui summarize `se' if _n==_N
					scalar `se1'=r(max)
					qui summarize `se' if _n==1
					scalar `se2'=r(max)	
				}
			}
			capture qui tab `reference'
			if _rc!=0 & `dimension'==0 {							// non-ordered dimension, no reference subgroup 
				sort `estimate'
				qui summarize `estimate' if _n==_N
				scalar `y1'=r(max)
				qui summarize `estimate' if _n==1
				scalar `y2'=r(max)
				capture qui tab `se'
				if _rc==0 {
					qui summarize `se' if _n==_N
					scalar `se1'=r(max)
					qui summarize `se' if _n==1
					scalar `se2'=r(max)	
				}
			}
			capture qui tab `reference'
			if _rc==0 {
				count if `reference'==1
				if r(N)!=1 {
					di as error "ERROR [" "`m'" "]: reference() must identify one reference subgroup with the value 1."
					exit
				}
				if `dimension'==0 & `fav'==1 {						// non-ordered dimension, reference subgroup, favourable indicator 
					qui summarize `estimate' if `reference'==1
					scalar `y1'=r(max)
					qui summarize `estimate' if `reference'!=1
					scalar `y2'=r(min)
					capture qui tab `se'
					if _rc==0 {
						qui summarize `se' if `reference'==1
						scalar `se1'=r(max)
						qui summarize `estimate' if `reference'!=1
						qui summarize `se' if `estimate'==r(min)
						scalar `se2'=r(max)
					}
				}
				if `dimension'==0 & `fav'==0 {						// non-ordered dimension, reference subgroup, adverse indicator 
					qui summarize `estimate' if `reference'==1
					scalar `y2'=r(max)
					qui summarize `estimate' if `reference'!=1
					scalar `y1'=r(max)
					capture qui tab `se'
					if _rc==0 {
						qui summarize `se' if `reference'==1
						scalar `se2'=r(max)
						qui summarize `estimate' if `reference'!=1
						qui summarize `se' if `estimate'==r(max)
						scalar `se1'=r(max)
					}
				}
			}
			if (`y1'==. | `y2'==.) {
				di as error "ERROR [" "`m'" "]: Estimate value is missing for one or both subgroups required for the calculation."
				exit
			}
		}
		
		*Identify reference estimates for par and paf
		if inlist("`m'","par","paf") {
			tempname refgroup
			qui summarize `dimension'
			if r(max)==1 {
				qui summarize `order'
				gen `refgroup'=1 if `order'==r(max)
			}
			if r(max)==0 {
				qui summarize `estimate'
				gen `refgroup'=1 if `estimate'==r(max) & `fav'==1
				replace `refgroup'=1 if `estimate'==r(min) & `fav'==0
			}
			qui summ `estimate' if `refgroup'==1
			if r(mean)==. {
				di as error "ERROR [" "`m'" "]: Estimate value is missing for the reference subgroup."
				exit
			}
		}
		
		*Drop missing estimates
		drop if `estimate'==.

		*All estimates cannot be equal to zero or missing
		if !inlist("`m'","d","r") {
			qui summarize `estimate'
			if r(mean)==0 {
				di as error "ERROR [" "`m'" "]: Estimate value is equal to zero for all subgroups."
				exit
			}
		}
		
		*More than two subgroups with data 
		if !inlist("`m'","d","r") {
			qui inspect `estimate'
			if r(N)<=2 {
				di as error "ERROR [" "`m'" "]: There must more than two subgroups with data."
				exit 
			}
		}
		
	*WEIGHT CHECKS
	
		*If WEIGHT is specified, it cannot be missing for any subgroups and cannot be equal to zero for all subgroups 
		if !inlist("`m'","mdbu","mdru","d","r") {
			capture qui tab `population'
			if _rc==0 {
				qui misstable summarize `population'
				if r(N_eq_dot)!=. {
					di as error "ERROR [" "`m'" "]: Population weight value is missing for at least one subgroup."
					exit
				}
				qui inspect `population'
				if r(N)==0 {
					di as error "ERROR [" "`m'" "]: Population weight value is equal to zero for all subgroups."
					exit
				}
			}
		}
		
	*STANDARD ERROR CHECKS
	
		*SE must be specified for the calculation of CIs for certain measures 
		if inlist("`m'","bgv","bgsd","cov","d","idisu","idisw","mdbu","mdbw") {
			capture qui tab `se'
			if _rc!=0 {
				di as error "WARNING [" "`m'" "]: se() is required for the calculation of 95% confidence intervals."
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					di as error "WARNING [" "`m'" "]: Standard error value is missing for at least one subgroup; unable to calculate 95% confidence intervals."
				}
			}
		}
		
		if inlist("`m'","mdmu","mdmw","mdru","mdrw","mld","r","ti") {
			capture qui tab `se'
			if _rc!=0 {
				di as error "WARNING [" "`m'" "]: se() is required for the calculation of 95% confidence intervals."
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					di as error "WARNING [" "`m'" "]: Standard error value is missing for at least one subgroup; unable to calculate 95% confidence intervals."
				}
			}
		}
		
	*LIMITS, WAGSTAFF, ERREYGERS CHECKS
	
		*LIMITS option must be specified correctly 
		if inlist("`m'","aci","rci") {
			local xxmin: word 1 of `limits'
			local xxmax: word 2 of `limits'
			if "`xxmin'"=="" {
				scalar xmin=.
			}
			else scalar xmin=`xxmin'
			if "`xxmax'"=="" {
				scalar xmax=.
			}
			else scalar xmax=`xxmax'
			capture qui tab `limits'
			if _rc==198 {
				local bounded=1
				if xmin>xmax | xmin==xmax | xmin==. {
					di as error "ERROR [" "`m'" "]: The limits option must be specified as limits(#1 #2) where #1 is the minimum and #2 is the maximum."
					exit 
				}
				qui summarize `estimate'
				if r(min)<xmin {
					di as error "ERROR [" "`m'" "]: Estimate variable has values outside of the specified limits."
					exit 
				}
			}
			else local bounded=0
		}
		
		*WAGSTAFF and ERREYGERS options must be specified correctly 
		if inlist("`m'","rci") {
			if "`erreygers'"=="erreygers" local erreygers=1 
				else local erreygers=0
			if "`wagstaff'"=="wagstaff" local wagstaff=1 
				else local wagstaff=0
			if (`erreygers'==1 & `wagstaff'==1) {
				di as error "ERROR [" "`m'" "]: The option wagstaff cannot be used in conjunction with the option erreygers."
				exit
			}
			if (`erreygers'==1 & `bounded'==0) {
				di as error "ERROR [" "`m'" "]: Erreygers Normalisations is only for use with bounded variables, hence the limits(#1 #2) option must be used to specify the theoretical minimum (#1) and maximum (#2)."
				exit
			}
			if (`wagstaff'==1 & `bounded'==0) {
				di as error "ERROR [" "`m'" "]: Wagstaff Normalisations is only for use with bounded variables, hence the limits(#1 #2) option must be used to specify the theoretical minimum (#1) and maximum (#2)."
				exit
			}
			if `erreygers'==1 {
				di as error "NOTE [" "`m'" "]: Erreygers Normalisation has been applied."
			}
			if `wagstaff'==1 {
				di as error "NOTE [" "`m'" "]: Wagstaff Normalisation has been applied."
			}
		}

	
********************************************************************************
	*	ACI 

		if "`m'" == "aci" {
			tempname intercept sumw cumw cumw_1 cumwr cumwr_1 rank temp sigma meanlhs lhs intercept rhs aci aci_se aci_ll aci_ul m mse mll mul
			*Calculate measure
			if `bounded'==1 {
				qui summarize `estimate'
				if r(min)>=xmin & r(max)<=xmax {
					replace `estimate'=(`estimate'-xmin)/(xmax-xmin)
				}
			}
			if "`svy'"!="" gen `intercept'=1
				else gen `intercept'=sqrt(`weight')
			sort `order'
			egen `sumw'=sum(`weight')
			gen `cumw'=sum(`weight')
			gen `cumw_1'=`cumw'[_n-1]
			replace `cumw_1'=0 if `cumw_1'==.
			bysort `order': egen `cumwr'=max(`cumw')
			bysort `order': egen `cumwr_1'=min(`cumw_1')
			gen `rank'=(`cumwr_1'+0.5*(`cumwr'-`cumwr_1'))/`sumw'
			gen `temp'=(`weight'/`sumw')*((`rank'-0.5)^2)
			egen `sigma'=sum(`temp')
				replace `temp'=`weight'*`estimate'
			egen `meanlhs'=sum(`temp')
				replace `meanlhs'=`meanlhs'/`sumw'
			gen `lhs'=2*`sigma'*(`estimate'/`meanlhs')*`intercept'
				replace `lhs'=`lhs'*`meanlhs'
			gen `rhs'=`rank'*`intercept'
			if "`svy'"!="" svy: qui regress `lhs' `rhs' `intercept', noconstant
				else qui regress `lhs' `rhs' `intercept', noconstant
			gen `aci'=e(b)[1,1]
			scalar `m'=`aci'
			return scalar aci=`m'
			*Calculate 95% confidence intervals
			matrix V=e(V)
			gen `aci_se'=sqrt(V[1,1])
			gen `aci_ll'=`aci'-1.96*`aci_se'
			gen `aci_ul'=`aci'+1.96*`aci_se'
			ereturn clear
			scalar `mse'=`aci_se'
			scalar `mll'=`aci_ll'
			scalar `mul'=`aci_ul'
			return scalar aci_se=`mse'
			return scalar aci_ll=`mll'
			return scalar aci_ul=`mul'
			*Matrix		
			matrix aci = `m', `mse', `mll', `mul'
			matrix rownames aci = "ACI"
		}

********************************************************************************
	*	BGSD

		if "`m'" == "bgsd" {
			tempname sum_pop popshare weighted_mean bgsd_prep bgsd bgsd_se count m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			egen `bgsd_prep'=total(`popshare'*((`estimate'-`weighted_mean')^2))
			gen `bgsd'=sqrt(`bgsd_prep')
			scalar `m'=`bgsd'
			return scalar bgsd=`bgsd'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							egen _weighted_mean_`j'=total(`popshare'*_est_`j')
							egen _bgsd_prep_`j'=total(`popshare'*((_est_`j'-_weighted_mean_`j')^2))
							gen _bgsd_`j'=sqrt(_bgsd_prep_`j')
							drop _est_`j' _weighted_mean_`j' _bgsd_prep_`j'
						}
						tempfile bgsd
						save `bgsd'
							keep in 1
							keep _bgsd_*
							gen `count'=1
							reshape long _bgsd_, i(`count') j(simulation)
							centile _bgsd_, c(2.5 97.5)
							matrix bgsd_ll=(r(c_1))
							matrix bgsd_ul=(r(c_2))
						use `bgsd', clear
						drop _bgsd_*
						scalar `mse'=.
						scalar `mll'=bgsd_ll[1,1]
						scalar `mul'=bgsd_ul[1,1]
						return scalar bgsd_ll=`mll'
						return scalar bgsd_ul=`mul'
					}
				}
			}
			*Matrix
			matrix bgsd = `m', `mse', `mll', `mul'
			matrix rownames bgsd = "BGSD"
		}
		
********************************************************************************
	*	BGV

		if "`m'" == "bgv" {
			tempname sum_pop popshare weighted_mean bgv se2 s2 se4 s4 bgv_se m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			egen `bgv'=total(`popshare'*((`estimate'-`weighted_mean')^2))
			scalar `m'=`bgv'
			return scalar bgv=`bgv'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				egen `se2'=total((`popshare'^2)*(`se'^2)*((`estimate'-`weighted_mean')^2))
				egen `s2'=total((`popshare'^2)*(`se'^2))
				egen `s4'=total((`popshare'^4)*(`se'^4))
				egen `se4'=total((`popshare'^2)*((1-`popshare')^2)*(`se'^4))
				gen `bgv_se'=sqrt(4*`se2'+2*((`s2'^2)-`s4'+`se4'))
				scalar `mse'=`bgv_se'
				scalar `mll'=`bgv'-1.96*`bgv_se'
				scalar `mul'=`bgv'+1.96*`bgv_se'
				return scalar bgv_se=`mse'
				return scalar bgv_ll=`mll'
				return scalar bgv_ul=`mul'
			}
			*Matrix
			matrix bgv = `m', `mse', `mll', `mul'
			matrix rownames bgv = "BGV"
		}

********************************************************************************
	*	COV

		if "`m'" == "cov" {
			tempname sum_pop popshare weighted_mean bgsd_prep bgsd cov cov_se count m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			egen `bgsd_prep'=total(`popshare'*((`estimate'-`weighted_mean')^2))
			gen `bgsd'=sqrt(`bgsd_prep')
			gen `cov'=(`bgsd'/`weighted_mean')*100
			scalar `m'=`cov'
			return scalar cov=`cov'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							egen _weighted_mean_`j'=total(`popshare'*_est_`j')
							egen _bgsd_prep_`j'=total(`popshare'*((_est_`j'-_weighted_mean_`j')^2))
							gen _bgsd_`j'=sqrt(_bgsd_prep_`j')
							gen _cov_`j'=(_bgsd_`j'/_weighted_mean_`j')*100
							drop _weighted_mean_`j' _bgsd_prep_`j' _bgsd_`j'
						}  
						tempfile cov
						save `cov'
							keep in 1
							keep _cov_*
							gen `count'=1
							reshape long _cov_, i(`count') j(simulation)
							centile _cov_, c(2.5 97.5)
							matrix cov_ll=(r(c_1))
							matrix cov_ul=(r(c_2))
						use `cov', clear
						drop _cov_*
						scalar `mse'=.
						scalar `mll'=cov_ll[1,1]
						scalar `mul'=cov_ul[1,1]
						return scalar cov_ll=`mll'
						return scalar cov_ul=`mul'
					}
				}
			}
			*Matrix
			matrix cov = `m', `mse', `mll', `mul'
			matrix rownames cov = "COV"
		}
		
********************************************************************************
	*	D

		if "`m'" == "d" {
			tempname d d_se m mse mll mul
			*Calculate measure
			gen `d'=`y1'-`y2'
			scalar `m'=`d'
			return scalar d=`d'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				gen `d_se'=sqrt(`se1'^2+`se2'^2)
				scalar `mse'=`d_se'
				scalar `mll'=`d'-1.96*`d_se'
				scalar `mul'=`d'+1.96*`d_se'
				return scalar d_se=`mse'
				return scalar d_ll=`mll'
				return scalar d_ul=`mul'
			}
			*Matrix
			matrix d = `m', `mse', `mll', `mul'
			matrix rownames d = "D"
		}

********************************************************************************
	*	IDISU

		if "`m'" == "idisu" {
			tempname sum_pop popshare weighted_mean idisu idisu_prep count m mse mll mul
			*Calculate measure
			capture qui tab `population'
			if _rc!=0 {
				egen `idisu_prep'=total(abs(`estimate'-`average'))
				gen `idisu'=(`idisu_prep'/_N/`average')*100
				scalar `m'=`idisu'
				return scalar idisu=`idisu'
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
				di `m'
			}
			else {
				egen `sum_pop'=total(`population')
				gen `popshare'=`population'/`sum_pop'
				egen `weighted_mean'=total(`popshare'*`estimate')
				egen `idisu_prep'=total(abs(`estimate'-`weighted_mean'))
				gen `idisu'=(`idisu_prep'/_N/`weighted_mean')*100
				scalar `m'=`idisu'
				return scalar idisu=`idisu'
				*Calculate 95% confidence intervals
				capture qui tab `se'
				if _rc!=0 {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.
				}
				if _rc==0 {
					qui misstable summarize `se'
					if r(N_eq_dot)!=. {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.			
					}
					else {
						capture qui tab `scale'
						if _rc!=0 {
							scalar `mse'=.
							scalar `mll'=.
							scalar `mul'=.
						}
						if _rc==0 {
							set seed 123456
							forvalues j = 1/`sim' {	
								gen _est_`j'=.
								forvalues n = 1/`=_N' {
									tempname i`n'
									gen `i`n''=.
									*Indicators measured as a percentage
									if `scale'==100 {
										while `i`n''==. {
											gen _simulation=rnormal(`estimate',`se')
											qui summarize _simulation if _n==`n'
											if r(mean)>=0 & r(mean)<=100 {
												replace `i`n''=r(mean)
											}
											drop _simulation
										}
										replace _est_`j'=`i`n'' if _n==`n'
										drop `i`n''
									}
									*Indicators not measured as a percentage
									if `scale'!=100 {
										while `i`n''==. {
											gen _simulation=rnormal(`estimate',`se')
											qui summarize _simulation if _n==`n'
											if r(mean)>=0 {
												replace `i`n''=r(mean)
											}
											drop _simulation
										}
										replace _est_`j'=`i`n'' if _n==`n'
										drop `i`n''
									}
								}
								egen _weighted_mean_`j'=total(`popshare'*_est_`j')
								egen _idisu_prep_`j'=total(abs(_est_`j'-_weighted_mean_`j'))
								gen _idisu_`j'=(_idisu_prep_`j'/_N/_weighted_mean_`j')*100
								drop _weighted_mean_`j' _idisu_prep_`j'
							}
							tempfile idisu
							save `idisu'
								keep in 1
								keep _idisu_*
								gen `count'=1
								reshape long _idisu_, i(`count') j(simulation)
								centile _idisu_, c(2.5 97.5)
								matrix idisu_ll=(r(c_1))
								matrix idisu_ul=(r(c_2))
							use `idisu', clear
							drop _est_* _idisu_*
							scalar `mse'=.
							scalar `mll'=idisu_ll[1,1]
							scalar `mul'=idisu_ul[1,1]
							return scalar idisu_ll=`mll'
							return scalar idisu_ul=`mul'
						}
					}
				}
			}
			*Matrix
			matrix idisu = `m', `mse', `mll', `mul'
			matrix rownames idisu = "IDISU"
		}
	
********************************************************************************
	*	IDISW

		if "`m'" == "idisw" {
			tempname sum_pop popshare weighted_mean idisw_prep idisw count m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			egen `idisw_prep'=total(`popshare'*abs(`estimate'-`weighted_mean'))
			gen `idisw'=(`idisw_prep'/`weighted_mean')*100
			scalar `m'=`idisw'
			return scalar idisw=`idisw'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							egen _weighted_mean_`j'=total(`popshare'*_est_`j')
							egen _idisw_prep_`j'=total(`popshare'*abs(_est_`j'-_weighted_mean_`j'))
							gen _idisw_`j'=(_idisw_prep_`j'/_weighted_mean_`j')*100
							drop _weighted_mean_`j' _idisw_prep_`j'
						}
						tempfile idisw
						save `idisw'
							keep in 1
							keep _idisw_*
							gen `count'=1
							reshape long _idisw_, i(`count') j(simulation)
							centile _idisw_, c(2.5 97.5)
							matrix idisw_ll=(r(c_1))
							matrix idisw_ul=(r(c_2))
						use `idisw', clear
						drop _est_* _idisw_*
						gen idisw_ll=idisw_ll[1,1]
						gen idisw_ul=idisw_ul[1,1]
						*Store results
						scalar `mse'=.
						scalar `mll'=idisw_ll[1,1]
						scalar `mul'=idisw_ul[1,1]
						return scalar idisw_ll=`mll'
						return scalar idisw_ul=`mul'
					}
				}
			}
			*Matrix
			matrix idisw = `m', `mse', `mll', `mul'
			matrix rownames idisw = "IDISW"
		}
		
********************************************************************************
	*	MDBU

		if "`m'" == "mdbu" {
			tempname ref_estimate mdbu_prep mdbu count m mse mll mul
			*Calculate measure
			qui summarize `estimate'
			gen `ref_estimate'=r(max) if `fav'==1
			replace `ref_estimate'=r(min) if `fav'==0
			egen `mdbu_prep'=total(abs(`estimate'-`ref_estimate'))
			gen `mdbu'=`mdbu_prep'/_N
			scalar `m'=`mdbu'
			return scalar mdbu=`mdbu'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							qui summarize _est_`j'
							gen _ref_estimate_`j'=r(max) if `fav'==1
							replace _ref_estimate_`j'=r(min) if `fav'==0
							egen _mdbu_prep_`j'=total(abs(_est_`j'-_ref_estimate_`j'))
							gen _mdbu_`j'=_mdbu_prep_`j'/_N
							drop _ref_estimate_`j' _mdbu_prep_`j'
						}
						tempfile mdbu
						save `mdbu'
							keep in 1
							keep _mdbu_*
							gen `count'=1
							reshape long _mdbu_, i(`count') j(simulation)
							centile _mdbu_, c(2.5 97.5)
							matrix mdbu_ll=(r(c_1))
							matrix mdbu_ul=(r(c_2))
						use `mdbu', clear
						drop _est_* _mdbu_*
						scalar `mse'=.
						scalar `mll'=mdbu_ll[1,1]
						scalar `mul'=mdbu_ul[1,1]
						return scalar mdbu_ll=`mll'
						return scalar mdbu_ul=`mul'
					}
				}
			}
			*Matrix
			matrix mdbu = `m', `mse', `mll', `mul'
			matrix rownames mdbu = "MDBU"
		}
		
********************************************************************************
	*	MDBW

		if "`m'" == "mdbw" {
			tempname ref_estimate sum_pop popshare mdbw count m mse mll mul
			*Calculate measure
			qui summarize `estimate'
			gen `ref_estimate'=r(max) if `fav'==1
			replace `ref_estimate'=r(min) if `fav'==0
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `mdbw'=total(`popshare'*abs(`estimate'-`ref_estimate'))
			scalar `m'=`mdbw'
			return scalar mdbw=`mdbw'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							qui summarize _est_`j'
							gen _ref_estimate_`j'=r(max) if `fav'==1
							replace _ref_estimate_`j'=r(min) if `fav'==0
							egen _mdbw_`j'=total(`popshare'*abs(_est_`j'-_ref_estimate_`j'))
							drop _ref_estimate_`j'
						} 
						tempfile mdbw
						save `mdbw'
							keep in 1
							keep _mdbw_*
							gen `count'=1
							reshape long _mdbw_, i(`count') j(simulation)
							centile _mdbw_, c(2.5 97.5)
							matrix mdbw_ll=(r(c_1))
							matrix mdbw_ul=(r(c_2))
						use `mdbw', clear
						drop _est_* _mdbw_*
						scalar `mse'=.
						scalar `mll'=mdbw_ll[1,1]
						scalar `mul'=mdbw_ul[1,1]
						return scalar mdbw_ll=`mll'
						return scalar mdbw_ul=`mul'
					}
				}
			}
			*Matrix
			matrix mdbw = `m', `mse', `mll', `mul'
			matrix rownames mdbw = "MDBW"
		}
		
********************************************************************************
	*	MDMU

		if "`m'" == "mdmu" {
			tempname sum_pop popshare weighted_mean mdmu_prep mdmu count m mse mll mul
			*Calculate measure
			capture qui tab `population'
			if _rc!=0 {
				egen `mdmu_prep'=total(abs(`estimate'-`average'))
				gen `mdmu'=`mdmu_prep'/_N
				scalar `m'=`mdmu'
				return scalar mdmu=`mdmu'
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			else {
				egen `sum_pop'=total(`population')
				gen `popshare'=`population'/`sum_pop'
				egen `weighted_mean'=total(`popshare'*`estimate')
				egen `mdmu_prep'=total(abs(`estimate'-`weighted_mean'))
				gen `mdmu'=`mdmu_prep'/_N
				scalar `m'=`mdmu'
				return scalar mdmu=`mdmu'
				*Calculate 95% confidence intervals
				capture qui tab `se'
				if _rc!=0 {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.
				}
				if _rc==0 {
					qui misstable summarize `se'
					if r(N_eq_dot)!=. {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.			
					}
					else {
						capture qui tab `scale'
						if _rc!=0 {
							scalar `mse'=.
							scalar `mll'=.
							scalar `mul'=.
						}
						if _rc==0 {
							set seed 123456
							forvalues j = 1/`sim' {	
								gen _est_`j'=.
								forvalues n = 1/`=_N' {
									tempname i`n'
									gen `i`n''=.
									*Indicators measured as a percentage
									if `scale'==100 {
										while `i`n''==. {
											gen _simulation=rnormal(`estimate',`se')
											qui summarize _simulation if _n==`n'
											if r(mean)>=0 & r(mean)<=100 {
												replace `i`n''=r(mean)
											}
											drop _simulation
										}
										replace _est_`j'=`i`n'' if _n==`n'
										drop `i`n''
									}
									*Indicators not measured as a percentage
									if `scale'!=100 {
										while `i`n''==. {
											gen _simulation=rnormal(`estimate',`se')
											qui summarize _simulation if _n==`n'
											if r(mean)>=0 {
												replace `i`n''=r(mean)
											}
											drop _simulation
										}
										replace _est_`j'=`i`n'' if _n==`n'
										drop `i`n''
									}
								}
								egen _weighted_mean_`j'=total(`popshare'*_est_`j')
								egen _mdmu_prep_`j'=total(abs(_est_`j'-_weighted_mean_`j'))
								gen _mdmu_`j'=_mdmu_prep_`j'/_N
								drop _weighted_mean_`j' _mdmu_prep_`j'
							}  
							tempfile mdmu
							save `mdmu'
								keep in 1
								keep _mdmu_*
								gen `count'=1
								reshape long _mdmu_, i(`count') j(simulation)
								centile _mdmu_, c(2.5 97.5)
								matrix mdmu_ll=(r(c_1))
								matrix mdmu_ul=(r(c_2))
							use `mdmu', clear
							drop _est_* _mdmu_*
							scalar `mse'=.
							scalar `mll'=mdmu_ll[1,1]
							scalar `mul'=mdmu_ul[1,1]
							return scalar mdmu_ll=`mll'
							return scalar mdmu_ul=`mul'
						}
					}
				}
			}
			*Matrix
			matrix mdmu = `m', `mse', `mll', `mul'
			matrix rownames mdmu = "MDMU"
		}
		
********************************************************************************
	*	MDMW

		if "`m'" == "mdmw" {
			tempname sum_pop popshare weighted_mean mdmw count m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			egen `mdmw'=total(`popshare'*abs(`estimate'-`weighted_mean'))
			scalar `m'=`mdmw'
			return scalar mdmw=`mdmw'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {	
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							egen _weighted_mean_`j'=total(`popshare'*_est_`j')
							egen _mdmw_`j'=total(`popshare'*abs(_est_`j'-_weighted_mean_`j'))
							drop _weighted_mean_`j'
						}  
						tempfile mdmw
						save `mdmw'
							keep in 1
							keep _mdmw_*
							gen `count'=1
							reshape long _mdmw_, i(`count') j(simulation)
							centile _mdmw_, c(2.5 97.5)
							matrix mdmw_ll=(r(c_1))
							matrix mdmw_ul=(r(c_2))
						use `mdmw', clear
						drop _est_* _mdmw_*
						scalar `mse'=.
						scalar `mll'=mdmw_ll[1,1]
						scalar `mul'=mdmw_ul[1,1]
						return scalar mdmw_ll=`mll'
						return scalar mdmw_ul=`mul'
					}
				}
			}
			*Matrix
			matrix mdmw = `m', `mse', `mll', `mul'
			matrix rownames mdmw = "MDMW"
		}

********************************************************************************
	*	MDRU

		if "`m'" == "mdru" {
			tempname ref_estimate mdru_prep mdru count m mse mll mul
			*Calculate measure
			qui summarize `estimate' if `reference'==1
			gen `ref_estimate'=r(max) 
			egen `mdru_prep'=total(abs(`estimate'-`ref_estimate'))
			gen `mdru'=`mdru_prep'/_N
			scalar `m'=`mdru'
			return scalar mdru=`mdru'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							qui summarize _est_`j' if `reference'==1
							gen _ref_estimate_`j'=r(max) 
							egen _mdru_prep_`j'=total(abs(_est_`j'-_ref_estimate_`j'))
							gen _mdru_`j'=_mdru_prep_`j'/_N
							drop _ref_estimate_`j' _mdru_prep_`j'
						}
						tempfile mdru
						save `mdru'
							keep in 1
							keep _mdru_*
							gen `count'=1
							reshape long _mdru_, i(`count') j(simulation)
							centile _mdru_, c(2.5 97.5)
							matrix mdru_ll=(r(c_1))
							matrix mdru_ul=(r(c_2))
						use `mdru', clear
						drop _est_* _mdru_*
						scalar `mse'=.
						scalar `mll'=mdru_ll[1,1]
						scalar `mul'=mdru_ul[1,1]
						return scalar mdru_ll=`mll'
						return scalar mdru_ul=`mul'
					}
				}
			}
			*Matrix
			matrix mdru = `m', `mse', `mll', `mul'
			matrix rownames mdru = "MDRU"
		}

********************************************************************************
	*	MDRW

		if "`m'" == "mdrw" {
			tempname ref_estimate sum_pop popshare mdrw count m mse mll mul
			*Calculate measure
			qui summarize `estimate' if `reference'==1
			gen `ref_estimate'=r(max) 
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `mdrw'=total(`popshare'*abs(`estimate'-`ref_estimate'))
			scalar `m'=`mdrw'
			return scalar mdrw=`mdrw'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				qui misstable summarize `se'
				if r(N_eq_dot)!=. {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.			
				}
				else {
					capture qui tab `scale'
					if _rc!=0 {
						scalar `mse'=.
						scalar `mll'=.
						scalar `mul'=.
					}
					if _rc==0 {
						set seed 123456
						forvalues j = 1/`sim' {	
							gen _est_`j'=.
							forvalues n = 1/`=_N' {
								tempname i`n'
								gen `i`n''=.
								*Indicators measured as a percentage
								if `scale'==100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 & r(mean)<=100 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
								*Indicators not measured as a percentage
								if `scale'!=100 {
									while `i`n''==. {
										gen _simulation=rnormal(`estimate',`se')
										qui summarize _simulation if _n==`n'
										if r(mean)>=0 {
											replace `i`n''=r(mean)
										}
										drop _simulation
									}
									replace _est_`j'=`i`n'' if _n==`n'
									drop `i`n''
								}
							}
							qui summarize _est_`j' if `reference'==1
							gen _ref_estimate_`j'=r(max) 
							egen _mdrw_`j'=total(`popshare'*abs(_est_`j'-_ref_estimate_`j'))
							drop _ref_estimate_`j'
						}
						tempfile mdrw
						save `mdrw'
							keep in 1
							keep _mdrw_*
							gen `count'=1
							reshape long _mdrw_, i(`count') j(simulation)
							centile _mdrw_, c(2.5 97.5)
							matrix mdrw_ll=(r(c_1))
							matrix mdrw_ul=(r(c_2))
						use `mdrw', clear
						drop _est_* _mdrw_*
						scalar `mse'=.
						scalar `mll'=mdrw_ll[1,1]
						scalar `mul'=mdrw_ul[1,1]
						return scalar mdrw_ll=`mll'
						return scalar mdrw_ul=`mul'
					}
				}
			}
			*Matrix
			matrix mdrw = `m', `mse', `mll', `mul'
			matrix rownames mdrw = "MDRW"
		}
		
********************************************************************************
	*	MLD

		if "`m'" == "mld" {
			tempname sum_pop popshare weighted_mean estimate_nozeros mld_prep rj mld mld_var mld_se m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			gen `estimate_nozeros'=`estimate'
			replace `estimate_nozeros'=0.000001 if `estimate'==0
			egen `mld_prep'=total(`popshare'*-log(`estimate_nozeros'/`weighted_mean'))
			gen `mld'=`mld_prep'*1000
			scalar `m'=`mld'
			return scalar mld=`mld'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				gen `rj'=`estimate_nozeros'/`weighted_mean'
				egen `mld_var'=total((((`se'^2)*(`popshare'^2))/(`weighted_mean'^2))*((1-(1/`rj'))^2))
				gen `mld_se'=sqrt(`mld_var')
				scalar `mse'=`mld_se'
				scalar `mll'=`mld'-1.96*`mld_se'
				scalar `mul'=`mld'+1.96*`mld_se'
				return scalar mld_se=`mse'
				return scalar mld_ll=`mll'
				return scalar mld_ul=`mul'
			}
			*Matrix
			matrix mld = `m', `mse', `mll', `mul'
			matrix rownames mld = "MLD"
		}
		
********************************************************************************
	*	PAF

		if "`m'" == "paf" {
			tempname sum_pop popshare weighted_mean ref_estimate ref_population a b c d N paf paf_se m mse mll mul
			*Calculate measure
			capture qui tab `population'
			if _rc!=0 {
				qui summarize `estimate' if `refgroup'==1
				gen `ref_estimate'=r(max)
				gen `paf'=((`ref_estimate'-`average')/`average')*100
				replace `paf'=0 if `fav'==1 & `paf'<0
				replace `paf'=0 if `fav'==0 & `paf'>0
				scalar `m'=`paf'
				return scalar paf=`paf'
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			else {
				egen `sum_pop'=total(`population')
				gen `popshare'=`population'/`sum_pop'
				egen `weighted_mean'=total(`popshare'*`estimate')
				qui summarize `estimate' if `refgroup'==1
				gen `ref_estimate'=r(max)
				gen `paf'=((`ref_estimate'-`weighted_mean')/`weighted_mean')*100
				replace `paf'=0 if `fav'==1 & `paf'<0
				replace `paf'=0 if `fav'==0 & `paf'>0
				scalar `m'=`paf'
				return scalar paf=`paf'
				*Calculate 95% confidence intervals
				capture qui tab `scale'
				if _rc!=0 {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.
				}
				if _rc==0 {
					qui summarize `population' if `refgroup'==1
					gen `ref_population'=r(max)
					gen `c'=(`ref_estimate'/`scale')*`ref_population'
					gen `d'=`ref_population'-`c'
					gen `a'=(`weighted_mean'/`scale')*`sum_pop'-`c'
					gen `b'=`sum_pop'-`a'-`ref_population'
					gen `N'=`a'+`b'+`c'+`d'
					gen `paf_se'=sqrt((`c'*`N'*(`a'*`d'*(`N'-`c')+`b'*`c'^2))/((`a'+`c')^3*(`c'+`d')^3))
					scalar `mse'=`paf_se'
					scalar `mll'=`paf'-1.96*`paf_se'
					scalar `mul'=`paf'+1.96*`paf_se'
					return scalar paf_se=`mse'
					return scalar paf_ll=`mll'
					return scalar paf_ul=`mul'
				}
			}
			*Matrix
			matrix paf = `m', `mse', `mll', `mul'
			matrix rownames paf = "PAF"
		}
		
********************************************************************************
	*	PAR

		if "`m'" == "par" {
			tempname sum_pop popshare weighted_mean ref_estimate ref_population a b c d N paf paf_se par par_se m mse mll mul
			*Calculate measure
			capture qui tab `population'
			if _rc!=0 {
				qui summarize `estimate' if `refgroup'==1
				gen `ref_estimate'=r(max)
				gen `par'=`ref_estimate'-`average'
				replace `par'=0 if `fav'==1 & `par'<0
				replace `par'=0 if `fav'==0 & `par'>0	
				scalar `m'=`par'
				return scalar par=`par'
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			else {
				egen `sum_pop'=total(`population')
				gen `popshare'=`population'/`sum_pop'
				egen `weighted_mean'=total(`popshare'*`estimate')
				qui summarize `estimate' if `refgroup'==1
				gen `ref_estimate'=r(max)
				gen `par'=`ref_estimate'-`weighted_mean'
				replace `par'=0 if `fav'==1 & `par'<0
				replace `par'=0 if `fav'==0 & `par'>0	
				scalar `m'=`par'
				return scalar par=`par'
				*Calculate 95% confidence intervals
				capture qui tab `scale'
				if _rc!=0 {
					scalar `mse'=.
					scalar `mll'=.
					scalar `mul'=.
				}
				if _rc==0 {
					qui summarize `population' if `refgroup'==1
					gen `ref_population'=r(max)
					gen `c'=(`ref_estimate'/`scale')*`ref_population'
					gen `d'=`ref_population'-`c'
					gen `a'=(`weighted_mean'/`scale')*`sum_pop'-`c'
					gen `b'=`sum_pop'-`a'-`ref_population'
					gen `N'=`a'+`b'+`c'+`d'
					gen `paf_se'=sqrt((`c'*`N'*(`a'*`d'*(`N'-`c')+`b'*`c'^2))/((`a'+`c')^3*(`c'+`d')^3))
					gen `paf'=((`ref_estimate'-`weighted_mean')/`weighted_mean')*100
					gen `par_se'=abs(`weighted_mean'*((`paf'+1.96*`paf_se')-(`paf'-1.96*`paf_se')))/(2*1.96)
					scalar `mse'=`par_se'
					scalar `mll'=`par'-1.96*`par_se'
					scalar `mul'=`par'+1.96*`par_se'
					return scalar par_se=`mse'
					return scalar par_ll=`mll'
					return scalar par_ul=`mul'
				}
			}
			*Matrix
			matrix par = `m', `mse', `mll', `mul'
			matrix rownames par = "PAR"
		}

********************************************************************************
	*	R

		if "`m'" == "r" {
			tempname r r_se r_log r_log_se m mse mll mul
			*Calculate measure			
			gen `r'=`y1'/`y2'
			scalar `m'=`r'
			return scalar r=`r'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				gen `r_se'=sqrt(((1/`y2'^2))*((`se1'^2)+((`r'^2)*(`se2'^2))))
				gen `r_log'=log(`r')
				gen `r_log_se'=`r_se'/`r'
				scalar `mse'=`r_log_se'
				scalar `mll'=exp(`r_log'-1.96*`r_log_se')
				scalar `mul'=exp(`r_log'+1.96*`r_log_se')
				return scalar r_se=`mse'
				return scalar r_ll=`mll'
				return scalar r_ul=`mul'
			}
			*Matrix
			matrix r = `m', `mse', `mll', `mul'
			matrix rownames r = "R"
		}
		
********************************************************************************
	*	RCI

		if "`m'" == "rci" {
			tempname intercept sumw cumw cumw_1 cumwr cumwr_1 rank temp sigma meanlhs lhs intercept rhs rci rci_se rci_ll rci_ul m mse mll mul
			*Calculate measure
			if `bounded'==1 {
				qui summarize `estimate'
				if r(min)>=xmin & r(max)<=xmax {
					replace `estimate'=(`estimate'-xmin)/(xmax-xmin)
				}
			}
			if "`svy'"!="" gen `intercept'=1
				else gen `intercept'=sqrt(`weight')
			sort `order'
			egen `sumw'=sum(`weight')
			gen `cumw'=sum(`weight')
			gen `cumw_1'=`cumw'[_n-1]
			replace `cumw_1'=0 if `cumw_1'==.
			bysort `order': egen `cumwr'=max(`cumw')
			bysort `order': egen `cumwr_1'=min(`cumw_1')
			gen `rank'=(`cumwr_1'+0.5*(`cumwr'-`cumwr_1'))/`sumw'
			gen `temp'=(`weight'/`sumw')*((`rank'-0.5)^2)
			egen `sigma'=sum(`temp')
				replace `temp'=`weight'*`estimate'
			egen `meanlhs'=sum(`temp')
				replace `meanlhs'=`meanlhs'/`sumw'
			gen `lhs'=2*`sigma'*(`estimate'/`meanlhs')*`intercept'
			if `wagstaff'==1 {
				replace `lhs'=`lhs'/(1-`meanlhs')
			}
			if `erreygers'==1 {
				replace `lhs'= `lhs'*(4*`meanlhs')
			}
			gen `rhs'=`rank'*`intercept'
			if "`svy'"!="" svy: qui regress `lhs' `rhs' `intercept', noconstant
				else qui regress `lhs' `rhs' `intercept', noconstant
			gen `rci'=e(b)[1,1]
			scalar `m'=`rci'
			return scalar rci=`m'
			*Calculate 95% confidence intervals
			matrix V=e(V)
			gen `rci_se'=sqrt(V[1,1])
			gen `rci_ll'=`rci'-1.96*`rci_se'
			gen `rci_ul'=`rci'+1.96*`rci_se'
			ereturn clear
			scalar `mse'=`rci_se'
			scalar `mll'=`rci_ll'
			scalar `mul'=`rci_ul'
			return scalar rci_se=`mse'
			return scalar rci_ll=`mll'
			return scalar rci_ul=`mul'
			*Matrix		
			matrix rci = `m', `mse', `mll', `mul'
			matrix rownames rci = "RCI"
		}
		
********************************************************************************
	*	RII

		if "`m'" == "rii" {
			tempname sc estimate_sc sumw cumw cumw_1 cumwr cumwr_1 rank rii lnRII rii_var rii_se rii_ll rii_ul m mse mll mul
			*Calculate measure
			qui summarize `estimate'
			gen `sc'=1 if r(max)<=1
				replace `sc'=100 if r(max)>1 & r(max)<=100
				replace `sc'=1000 if r(max)>100 & r(max)<=1000
				replace `sc'=10000 if r(max)>1000 & r(max)<=10000
				replace `sc'=100000 if r(max)>10000 & r(max)<=100000
				replace `sc'=1000000 if r(max)>100000 & r(max)<=1000000
			gen `estimate_sc'=`estimate'/`sc'
			cap qui tab `estimate_sc'
			if r(r)==1 {
				scalar `m'=.
				scalar `mll'=.
				scalar `mul'=. 
				di as error "WARNING [" "`m'" "]: Not calculated - all estimates have the same value."
			}
			else {
				sort `order'
				egen `sumw'=sum(`weight')
				gen `cumw'=sum(`weight')
				gen `cumw_1'=`cumw'[_n-1]
				replace `cumw_1'=0 if `cumw_1'==.
				bysort `order': egen `cumwr'=max(`cumw')
				bysort `order': egen `cumwr_1'=min(`cumw_1')
				gen `rank'=(`cumwr_1'+0.5*(`cumwr'-`cumwr_1'))/`sumw'
				if "`svy'"=="" {
					if "`linear'"!="" glm `estimate_sc' `rank' [pw=`weight'], nolog
					else glm `estimate_sc' `rank' [pw=`weight'], link(logit) family(binomial) nolog
				}
				if "`svy'"!="" {
					if "`linear'"!="" svy: glm `estimate_sc' `rank', nolog
					else svy: glm `estimate_sc' `rank', link(logit) family(binomial) nolog
				}
				margins, at(`rank'=(0 1)) post
				nlcom (RII: (_b[2._at] / _b[1._at])), post
				gen `rii'=e(b)[1,1]
				scalar `m'=`rii'
				return scalar rii=`m'
				*Calculate 95% confidence intervals
				if "`svy'"=="" {
					if "`linear'"!="" glm `estimate_sc' `rank' [pw=`weight'], nolog
					else glm `estimate_sc' `rank' [pw=`weight'], link(logit) family(binomial) nolog
				}
				if "`svy'"!="" {
					if "`linear'"!="" svy: glm `estimate_sc' `rank', nolog
					else svy: glm `estimate_sc' `rank', link(logit) family(binomial) nolog
				}
				margins, at(`rank'=(0 1)) post
				nlcom (lnRII: ln(_b[2._at] / _b[1._at])), post
				gen `lnRII'=e(b)[1,1]
				gen `rii_var'=e(V)[1,1]
				gen `rii_se'=sqrt(`rii_var')
				gen `rii_ll'=exp(`lnRII'-1.96*`rii_se')
				gen `rii_ul'=exp(`lnRII'+1.96*`rii_se')	
				ereturn clear
				scalar `mse'=`rii_se'
				scalar `mll'=`rii_ll'
				scalar `mul'=`rii_ul'
				return scalar rii_ll=`mll'
				return scalar rii_ul=`mul'
				return scalar rii_se=`rii_se'
			}
			*Matrix		
			matrix rii = `m', `mse', `mll', `mul'
			matrix rownames rii = "RII"
		}
		
********************************************************************************
	*	SII

		if "`m'" == "sii" {
			tempname sc estimate_sc sumw cumw cumw_1 cumwr cumwr_1 rank sii sii_se sii_ll sii_ul m mse mll mul
			*Calculate measure
			qui summarize `estimate'
			gen `sc'=1 if r(max)<=1
				replace `sc'=100 if r(max)>1 & r(max)<=100
				replace `sc'=1000 if r(max)>100 & r(max)<=1000
				replace `sc'=10000 if r(max)>1000 & r(max)<=10000
				replace `sc'=100000 if r(max)>10000 & r(max)<=100000
				replace `sc'=1000000 if r(max)>100000 & r(max)<=1000000
			gen `estimate_sc'=`estimate'/`sc'
			cap qui tab `estimate_sc'
			if r(r)==1 {
				scalar `m'=.
				scalar `mll'=.
				scalar `mul'=. 
				di as error "WARNING [" "`m'" "]: Not calculated - all estimates have the same value."
			}
			else {
				sort `order'
				egen `sumw'=sum(`weight')
				gen `cumw'=sum(`weight')
				gen `cumw_1'=`cumw'[_n-1]
				replace `cumw_1'=0 if `cumw_1'==.
				bysort `order': egen `cumwr'=max(`cumw')
				bysort `order': egen `cumwr_1'=min(`cumw_1')
				gen `rank'=(`cumwr_1'+0.5*(`cumwr'-`cumwr_1'))/`sumw'
				if "`svy'"=="" {
					if "`linear'"!="" glm `estimate_sc' `rank' [pw=`weight'], nolog
					else glm `estimate_sc' `rank' [pw=`weight'], link(logit) family(binomial) nolog
				}
				if "`svy'"!="" {
					if "`linear'"!="" svy: glm `estimate_sc' `rank', nolog
					else svy: glm `estimate_sc' `rank', link(logit) family(binomial) nolog
				}
				margins, at(`rank'=(0 1)) post
				nlcom (SII: (_b[2._at] - _b[1._at])), post
				gen `sii'=e(b)[1,1]
				*Calculate 95% confidence intervals
				matrix V=e(V)
				gen `sii_se'=sqrt(V[1,1])
				gen `sii_ll'=`sii'-1.96*`sii_se'
				gen `sii_ul'=`sii'+1.96*`sii_se'
				ereturn clear
				*Rescale 
				scalar `m'=`sii'*`sc'
				scalar `mse'=`sii_se'
				scalar `mll'=`sii_ll'*`sc'
				scalar `mul'=`sii_ul'*`sc'
				return scalar sii=`m'
				return scalar sii_ll=`mll'
				return scalar sii_ul=`mul'
				return scalar sii_se=`sii_se'
			}
			*Matrix		
			matrix sii = `m', `mse', `mll', `mul'
			matrix rownames sii = "SII"
		}
		
********************************************************************************
	*	TI

		if "`m'" == "ti" {
			tempname sum_pop popshare weighted_mean estimate_nozeros rj ti_prep ti var_prep ti_var ti_se m mse mll mul
			*Calculate measure
			egen `sum_pop'=total(`population')
			gen `popshare'=`population'/`sum_pop'
			egen `weighted_mean'=total(`popshare'*`estimate')
			gen `estimate_nozeros'=`estimate'
			replace `estimate_nozeros'=0.000001 if `estimate'==0
			gen `rj'=`estimate_nozeros'/`weighted_mean'
			egen `ti_prep'=total(`rj'*log(`rj')*`popshare')
			gen `ti'=`ti_prep'*1000
			scalar `m'=`ti'
			return scalar ti=`ti'
			*Calculate 95% confidence intervals
			capture qui tab `se'
			if _rc!=0 {
				scalar `mse'=.
				scalar `mll'=.
				scalar `mul'=.
			}
			if _rc==0 {
				egen `var_prep'=total(`rj'*(1+log(`rj'))*`popshare')
				egen `ti_var'=total(((1+log(`rj')-`var_prep')^2)*((`popshare'^2)*(`se'^2)/(`weighted_mean'^2)))
				gen `ti_se'=sqrt(`ti_var')
				scalar `mse'=`ti_se'
				scalar `mll'=`ti'-1.96*`ti_se'
				scalar `mul'=`ti'+1.96*`ti_se'
				return scalar ti_se=`mse'
				return scalar ti_ll=`mll'
				return scalar ti_ul=`mul'
			}
			*Matrix		
			matrix ti = `m', `mse', `mll', `mul'
			matrix rownames ti = "TI"
		}
		
********************************************************************************
		
	}	// end loop over measures
	
}	// end quietly

*	Display results
	foreach m in `measure' {
		matrix all = nullmat(all) \ `m'
	}
	matrix colnames all = "Value" "Std. Err." "[95% Conf." "Interval]"
	if "`print'" != "noprint" {
		local l1=strpos("`format'","(")
		local l2=strpos("`format'",")")
		local l3=substr("`format'",`l1'+1,`l2'-`l1'-1)
		local n=`:word count `measure''
		local lines=`n'*"|"
		matlist all, rowt(Measure) cspec(& w13 & "`l3'" w13 & "`l3'" w13 & "`l3'" w13 & "`l3'" w13 &) rspec(||`lines')
	}
	
end 
