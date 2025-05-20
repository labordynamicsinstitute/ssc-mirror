*! 1.0.0 Ariel Linden 17May2025 

program markovpredict, rclass
	version 11.0
	syntax varname	,	///
		Past(string)	///
		[ 				///
		NOIsily]
		
	quietly {
		         
		local pastcnt: list sizeof past
		local rpast: list rsort past
		 
		// check if past values are among values in varname
		levelsof `varlist' , local(levt)
		forvalues i = 1 / `pastcnt' {	
			local a : word `i' of `past'
			if !`: list a in levt' {
				di as err "{bf:`a'} specified in {bf:past()} is not found in {bf:`varlist'}"
				exit 198
			}
		}	

		// empty ifs
		local ifs if

		// loop to get all the "if" qualifiers
		forvalues i = 1 / `pastcnt' {
			tempvar past`i'
		
			// generates past states
			gen `past`i'' = `varlist'[_n - `i']
			local a : word `i' of `past'
			if `i' < `pastcnt'  {
				local and &
			}
			else local and 
		
			// determine if entries in past are numeric or string
			local qq : word 1 of `past'
			capture confirm number `qq'
			if _rc == 0 {
				local ifs `ifs' `past`i'' == `a' `and'
			}
			else {
				local ifs `ifs' `past`i'' == "`a'" `and'
			}
		}	
		
*		noi di "`ifs'"
		// if the user wants to see how the next state was determined
		`noisily' tab `varlist' `ifs', nolabel
		if r(N) == 0 {
			di as err "there are no predictions based on the specified past states"
			exit 198
		}

		// the next state with the highest frequency is the prediction
		tempvar count
		preserve
		contract `varlist'  `ifs', freq(`count')
		gsort -`count'
		local predict = `varlist' in 1		
		noisily di as txt _n "   The prediction for the next state is {bf:`predict'}, based on the past `pastcnt' states (from most recent to most distant): {bf:`past'}		
		restore		

		// return result
		return local predict = "`predict'"

	} // end quietly
	
end	
