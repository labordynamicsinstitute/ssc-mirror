***Manski-type Confidence Intervals*********************
***by John Ternovski************************************
***McCourt School of Public Policy at Georgetown********
***Version 1.1******************************************
***2022-03-22*******************************************

program define manski_ci , eclass
	version 13.0
	syntax [if] [in], OUTcome(varname) TReat(varname) [COVars(varlist fv) DISplayall] [MISsingflag(varname)] [max(numlist max=1)] [min(numlist max=1)] [vce(passthru)] [REGType(string)] [Level(cilevel)]

	* handling if/in 
	if "`in'"!="" | "`if'"!="" {
		preserve
		qui keep `in' `if'
	}
	
	* default ols if regtype not specified
	if "`regtype'"=="" {
		local regtype "regress"
	}
	
	*setting up display option
	if "`displayall'"=="" {
		local prefix "quietly"
	}
	
	* check for missing flag and infer missingness if needed
	if "`missingflag'"=="" {
	tempvar missingflag
		gen `missingflag'=`outcome'==.
	}
	
	*define matrix
	tempname mat
	matrix `mat' = J(3,1,.)
	matrix colnames `mat' = "`treat'"
	matrix rownames `mat' = coef `level'lowerbound `level'upperbound
	
	* get max and min of outcome variable 
	if "`max'"=="" | "`min'"=="" {
		`prefix' dis in yellow "Inferring maximum/minimum values from outcome data..." 
		`prefix' sum `outcome' 
	}
	if "`max'"=="" { 
		local max=`r(max)'
	}
	if "`min'"=="" {
		local min=`r(min)'
	}
		
	*WORST CASE 
	tempvar outcomenew
	`prefix' gen `outcomenew'=`outcome'
	`prefix' replace `outcomenew'=`max' if `treat'==0 & `missingflag'==1 	/* replace missing outcomes with bounds*/
	`prefix' replace `outcomenew'=`min' if `treat'==1 & `missingflag'==1    /* replace missing outcomes with bounds*/
	`prefix' disp "WORST CASE"
	`prefix' disp `"`e(cmdline)'"'
	`prefix' `regtype' `outcomenew' `treat' `covars', `vce' level(`level')
	tempname worst
	matrix `worst'=r(table)
	matrix `mat'[2,1]=`worst'[5,1]
		
	* WITHOUT BOUNDS 
	`prefix' disp "WITHOUT BOUNDS"
	`prefix' disp `"`e(cmdline)'"'
	`prefix' `regtype' `outcome' `treat' `covars', `vce' level(`level')
	matrix `mat'[1,1]=_b[`treat']
		
	*BEST CASE 
	tempvar outcomenew
	`prefix' gen `outcomenew'=`outcome'
	`prefix' replace `outcomenew'=`max' if `treat'==1 & `missingflag'==1 /* replace missing outcomes with bounds*/
	`prefix' replace `outcomenew'=`min' if `treat'==0 & `missingflag'==1 /* replace missing outcomes with bounds*/
	`prefix' disp "BEST CASE"
	`prefix' disp `"`e(cmdline)'"'
	`prefix' `regtype' `outcomenew' `treat' `covars', `vce'  level(`level')
	tempname best
	matrix `best'=r(table)
	matrix `mat'[3,1]=`best'[6,1]
	
	ereturn matrix worst=`worst'
	ereturn matrix best=`best'
	ereturn matrix manski_ci=`mat'
	matrix list e(manski_ci)
	
	* restoring data for if/in cases
	if "`in'"!="" | "`if'"!="" {
		restore
	}

	
end
*
