*! version 1.1, February 2025
*! Authors: Vesa-Matti Heikkuri and Matthias Schief
*! This program computes the Gini coefficient and implements the decomposition 
*! by population subgroups derived in Heikkuri and Schief (2024)
*! The program builds on "ineqdecgini.ado" by Stephen P. Jenkins



version 13.1

program ginidecomp, sortpreserve rclass 

syntax varname(numeric) [aweight fweight iweight pweight] [if] [in] [, BYgroup(varlist)]

set more off
local inc "`varlist'"

if strlen("`inc'") > 14{
	local inc_short = substr("`inc'", 1, 14)
}

* Temporary variables	 
tempvar w cumulProp gini firstObs meanIncome_k relativeMeanIncome_k totalWeights_k relativeWeight_k popShare_k incomeShare_k cumulProp_k gini_k
  
* Weight handling
if "`weight'" == "" gen byte `w' = 1
else qui gen `w' `exp'

* Data validation
marksample touse
qui count if `touse'
if r(N) == 0 error 2000
lab var `touse' "NumObs"
lab def `touse' 1 "`r(N)'"
lab val `touse' `touse'

* Report the number of missing values
qui count if missing(`inc') | missing(`w')
if r(N) > 0 {
	di as txt "(`r(N)' observations omitted due to missing values in `inc' or the weight variable)"
}

* Gini calculation
qui sum `inc' [w = `w'] if `touse'
local totalWeights = r(sum_w)
local meanIncome = r(mean)
gsort -`touse' `inc' 
qui gen double `cumulProp' = (2 * sum(`w') - `totalWeights' - `w')/(`totalWeights'*`totalWeights'*`meanIncome') if `touse'
qui egen double `gini' = total(`w'*`inc'*`cumulProp') if `touse'

lab var `gini' "Gini"


* Subgroup decomposition

if "`bygroup'" != "" {	
	
	* Bygroup handling
	tempvar bygroup_num
	qui egen double `bygroup_num' = group(`bygroup'), missing
	label variable `bygroup_num' "Subgroup"
	markout `touse' `bygroup_num'
	
	capture levelsof `bygroup_num' if `touse' , local(groupLevels)
	qui if _rc levels `bygroup_num' if `touse' , local(groupLevels)

	foreach var in `bygroup'{
		qui count if missing(`var')
		if r(N)>0{
			di as text "  "
			di as text "(Note: the bygroup variable(s) contain(s) missing values.  By default, missing values in the groupvar variables are treated as group identifiers. For more information, see help file.)"
			di as text "  "
			continue, break
		}
	}	

	qui{
	
		
		* Create subgroup labels
		tempvar sortVar
		gen `sortVar'=0
		foreach g in `groupLevels' {
			replace `sortVar' = `bygroup_num' != `g'
			sort `sortVar'
			local firstBygroup = 1
			foreach var in `bygroup'{
				local value = `var'[1]
				if `firstBygroup' == 1{
					local label_text = "`var' = `value'"
				}
				else{
					local label_text = "`label_text'" + ",  `var' = `value'"
				}
				local firstBygroup = 0
			}
			label define bygroup_num_label `g' "`label_text'", modify
		}
		label values `bygroup_num' bygroup_num_label
		
		
		* Compute and print subgroup summary statistics
		tempvar notuse
		qui gen byte `notuse' = -`touse'
		sort `notuse' `bygroup_num' `inc'

		by `notuse' `bygroup_num': gen byte `firstObs' = _n == 1 if `touse'
		by `notuse' `bygroup_num': egen `totalWeights_k' = sum(`w') if `touse'
		gen double `popShare_k' = `totalWeights_k' / `totalWeights' if `touse'
		gen double `relativeWeight_k' = `w' / `totalWeights_k' if `touse'
		by `notuse' `bygroup_num': egen  double `meanIncome_k' = sum(`relativeWeight_k' * `inc') if `touse'
		gen double `relativeMeanIncome_k' = `meanIncome_k' / `meanIncome' if `touse'
		gen double `incomeShare_k' = `popShare_k' * `relativeMeanIncome_k' if `touse'

		bysort `notuse' `bygroup_num' (`inc'): gen double `cumulProp_k' = (2 * sum(`w') - `totalWeights_k' - `w')/(`totalWeights_k'*`totalWeights_k'*`meanIncome_k') if `touse'
		by `notuse' `bygroup_num': egen double `gini_k' = total(`w'*`inc'*`cumulProp_k') if `touse'
		replace `gini_k' = abs(`gini_k')

		lab var `popShare_k' "Population share"
		lab var `meanIncome_k' "Mean"
		lab var `incomeShare_k' "`inc_short' share"
		lab var `gini_k' "Gini"	

		* Compute within and between-group inequality terms
		local giniW = 0

		gsort -`firstObs' `bygroup_num'
		local i = 1
		foreach k of local groupLevels {
			local giniW = `giniW' +  sqrt(`popShare_k'[`i'] * `incomeShare_k'[`i'] * `gini_k'[`i'])
			local ++i
		}
		
		local giniW = `giniW' * `giniW'
		local giniB = `gini'-`giniW'

		return scalar within = `giniW'
		return scalar between = `giniB'
	
	}
		
	* Compute decomposition results
	
	tempvar withinGroupIneq betweenGroupIneq

	qui gen double `withinGroupIneq' = `giniW' in 1
	label var `withinGroupIneq' "Within"
		
	qui gen double `betweenGroupIneq' = `gini'-`giniW'
	label var `betweenGroupIneq' "Between"

	tempvar withinGroupIneq_percent betweenGroupIneq_percent

	qui gen double `withinGroupIneq_percent' = 100 * `withinGroupIneq' / `gini' in 1
	label var `withinGroupIneq_percent' "Within (%)"

	qui gen double `betweenGroupIneq_percent' = 100 * `betweenGroupIneq' / `gini' in 1
	label var `betweenGroupIneq_percent' "Between (%)"
	
	return scalar within_pct = `withinGroupIneq_percent'
	return scalar between_pct = `betweenGroupIneq_percent'
	


}


* Print aggregate Gini coefficient
di "  "
di as txt "Aggregate Gini coefficient of `inc':"
tabdisp `touse' in 1, c(`gini') f(%9.5f)
return scalar gini = `gini'

if "`bygroup'" != "" {
	* Print subgroup summary statistics
	noi di "  "
	noi di as txt "Subgroup summary statistics:"
	capture noi tabdisp `bygroup_num' if `firstObs' & `touse' , c(`popShare_k' `meanIncome_k' `incomeShare_k' `gini_k') f(%15.5f)

	* Print the decomposition results
	di "  "
	di as txt "Subgroup Decomposition:"
	tabdisp `touse' in 1, c(`gini' `withinGroupIneq' `betweenGroupIneq') f(%9.5f)
	di "  "
	di as txt "Sugroup Decomposition (% of total):"
	tabdisp `touse' in 1, c(`withinGroupIneq_percent' `betweenGroupIneq_percent') f(%9.5f)
	di "Note: The above results show the decomposition of the aggregate Gini coefficient of '`inc'' into inequality within and between subgroups defined by '`bygroup''. The subgroup decomposition is based on the formula presented in Heikkuri and Schief (2024). For more information, type 'help ginidecomp'."
}
		


end

