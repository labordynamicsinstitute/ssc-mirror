*! xtkumblienhard version 1.0.0
*! Performs Estimations of Generalized 
*! Four-Component Panel Data 
*! Stochastic Frontier Models
*! Diallo Ibrahima Amadou
*! All comments are welcome, 05Jan2026



capture program drop xtkumblienhard
program xtkumblienhard, eclass sortpreserve
    version 18.0
	syntax varlist(fv ts) [if] [in] [fweight pweight], STUB(string) [ fe vce(passthru) Level(cilevel)  * ]
	gettoken lhs rhs : varlist
	_fv_check_depvar `lhs'
	if "`weight'" != "" {
		local wgt "[`weight'`exp']"
	}
	marksample touse
	if "`fe'" == "" {
		_vce_parse `touse', opt(Robust) argopt(CLuster): , `vce'
	}
	else {
		_vce_parse `touse', opt(Robust) argopt(CLuster): `wgt' , `vce'
	}
	if "`fe'" == "" {
		display
		display _dup(78) "="
		display "{bf:STEP 1: Random-Effects Panel Data Regression}"	
		display _dup(78) "="
		display
		quietly xtset
		xtreg `lhs' `rhs' if `touse', re `vce' level(`level') 
		quietly estimates store step_1_`stub'
		quietly {
			predict double Alpha_`stub' if `touse', u 
			predict double Epsilon_`stub' if `touse', e 
			label var Alpha_`stub' "Estimates of the Composed Random Individual-Specific Effects Alpha"
			label var Epsilon_`stub' "Estimates of the Composed Error Epsilon"
		}
	}
    else {
		display
		display _dup(78) "="
		display "{bf:STEP 1: Fixed-Effects Panel Data Regression}"	
		display _dup(78) "="
		display
		quietly xtset
		xtreg `lhs' `rhs' `wgt' if `touse', fe `vce' level(`level') 
		quietly estimates store step_1_`stub'
		quietly {
			predict double Alpha_`stub' if `touse', u 
			predict double Epsilon_`stub' if `touse', e 
			label var Alpha_`stub' "Estimates of the Composed Fixed Individual-Specific Effects Alpha"
			label var Epsilon_`stub' "Estimates of the Composed Error Epsilon"
		}
	}
	display
	display _dup(78) "="
	display "{bf:STEP 2: SFA Estimation to Obtain the Persistent (In)Efficiency}"	
	display _dup(78) "="
	display	
	frontier Alpha_`stub' `wgt' if `touse', distribution(hnormal) `vce' `options' level(`level')
	quietly estimates store step_2_`stub'
	quietly {
		predict double Ineff_Pers_`stub' if `touse', u 
		predict double Eff_Pers_`stub' if `touse', te 
		label var Ineff_Pers_`stub' "Persistent Inefficiency, E(u|e)"
		label var Eff_Pers_`stub' "Persistent Efficiency, E(exp(-u)|e)"
	}
	display
	display _dup(78) "="
	display "{bf:STEP 3: SFA Estimation to Obtain the Transitory (In)Efficiency}"	
	display _dup(78) "="
	display
	frontier Epsilon_`stub' `wgt' if `touse', distribution(hnormal) `vce' `options' level(`level')
	quietly estimates store step_3_`stub'
	quietly {
		predict double Ineff_Trans_`stub' if `touse', u 
		predict double Eff_Trans_`stub' if `touse', te 
		label var Ineff_Trans_`stub' "Transitory Inefficiency, E(u|e)"
		label var Eff_Trans_`stub' "Transitory Efficiency, E(exp(-u)|e)"
	}
	quietly { 
		generate double Overall_TE_`stub' if `touse' = Eff_Trans_`stub' * Eff_Pers_`stub'
		label var Overall_TE_`stub' "Overall Technical Efficiency"
	}
	quietly {
		generate double Overall_Ineff_`stub' if `touse' = Ineff_Trans_`stub' + Ineff_Pers_`stub'
		label var Overall_Ineff_`stub' "Overall Inefficiency"
	}
	
end


