*! 1.0.0 Ariel Linden 19May2025

program define mode, rclass
version 11.0

	syntax varname [if][in] [, NOMISS ]
	
		quietly {

			// manually generate touse to catch both string variables and missing values		
			tempvar touse
			gen `touse' = 0
			replace `touse' = 1 `if' `in'

			preserve
			tempname count
		
			contract `varlist' if `touse', freq(`count') `nomiss'
		
			// if the variable is string, replace "" with "." to catch missing value
			capture confirm numeric variable `varlist'
			if _rc != 0 {
				if "`nomiss'" == "" {
					replace `varlist' = "." if `varlist' == ""
				}
			}	

			summarize `count', meanonly
			local N = r(N)
			local max = r(max)

			// collect all values having the max frequency
			local mode
			forvalues i = 1/`N' {
				if `count'[`i'] == `max' {
					local mode `mode'	`=`varlist'[`i']'
				}
			}
			restore
			
		} // end quietly				
			
		di _n
		di as txt "   The mode of the variable {bf:`varlist'} is [ {bf:`mode'} ]" 
		
		// return mode as a macro
		return local mode `mode'

end