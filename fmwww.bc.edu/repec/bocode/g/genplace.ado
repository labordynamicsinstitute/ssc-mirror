capture program drop genplace
program define genplace
	version 9.0
	syntax varlist, [STAckid(varname)] WEIght(varname) [PREfix(name)]
	
	local stkid = "`stackid'"
	if ("`stackid'"=="") {
		local stkid = "genstacks_stack"
	}

	local pfix = "`prefix'"
	if ("`prefix'"=="") {
		local pfix = "plw`weight'_"
	}

	display "Generating placements of objects identified by `stkid',"
	display "by weighting respondents on `weight'..."
	set more off
	qui levelsof `stkid', local(parties)
	foreach var of varlist `varlist' {
		local destvar = "`pfix'`var'"

		capture drop `destvar'
		
		display "`var' => `destvar'"
		
		qui gen `destvar' = .
		foreach party in `parties' {
			qui summarize `var' [aweight=`weight'] if `stkid'==`party'
			qui replace `destvar' = `r(mean)' if `stkid'==`party'
		}
		
	}

end
