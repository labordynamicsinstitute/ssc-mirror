*! 1.0.0 NJC 9 February 2025
program myrank, sortpreserve 
	version 8.2 

	// starts: myrank newvar = varname 
	gettoken newvar 0 : 0, parse(" =") 
	gettoken eqsign 0 : 0, parse("=") 
	syntax varname(numeric) [if] [in] ///
	[, over(varname) DESCending gap(numlist int max=1 >0)  VARLabel(str) ] 

	confirm new var `newvar' 
	if "`eqsign'" != "=" exit 198 

	// data to use 
	marksample touse
	if "`over'" != "" markout `touse' `over', strok
				
	quietly { 
		count if `touse' 
		if r(N) == 0 error 2000
		
		if "`gap'" == "" | "`over'" == "" local gap = 0  
	
		tempvar group 
		if "`over'" != "" { 
			egen `group' = group(`over') if `touse'
		}
		else gen byte `group' = `touse'
		
		replace `touse' = -`touse'
		
		if "`descending'" != "" { 
			tempvar work 
			clonevar `work' = `varlist'
			replace `work' = - `work'
			local varlist `work'
		}
	
		sort `touse' `over' `varlist' 
		gen `newvar' = sum(`gap' * (`group' > 1) * (`group' != `group'[_n-1])) + sum(1) if `touse'
		
		if `'"`varlabel'"' != "" label var `newvar' `'"`varlabel'"'
		else label var `newvar' "Ranks"
		
		/// leave group middles and gaps as local macros 
		su `group', meanonly 
		
		forval g = 1/`r(max)' { 
			summarize `newvar' if `group' == `g', meanonly 
			if `g' == 1 c_local gap0 = r(min) - `gap'/2 - 1/2 
			c_local mid`g' = r(mean)
			c_local gap`g' = r(max) + `gap'/2 + 1/2 
		} 
	}
end 



