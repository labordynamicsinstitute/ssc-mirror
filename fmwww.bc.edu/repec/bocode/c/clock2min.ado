


program clock2min

	version 11 
	
	syntax varlist(min=1 max=2 string), did(string) dst(string) clockt(string)

	// Hard check. dst must be an integer between 0 and 23
	if `dst' < 0 | `dst' > 23 {
    di as error "Error: dst() must be an integer between 0 and 23. You entered: `dst'"
    exit 198
}

// Determine expected number of colons based on clockt()
local expected_colons = .
if "`clockt'" == "h" {
    local expected_colons = 0
}
else if "`clockt'" == "hm" {
    local expected_colons = 1
}
else if "`clockt'" == "hms" {
    local expected_colons = 2
}
else {
    di as error "Invalid format specified in clockt(). Allowed values are: h, hm, and hms."
    exit 198
}

// Generate a temporary variable to count colons in each observation
tempvar coloncount

foreach var of varlist `varlist' {
    gen byte `coloncount' = length(`var') - length(subinstr(`var', ":", "", .))

    quietly count if `coloncount' != `expected_colons' & !missing(`var')
    if r(N) > 0 {
        di as error "Mismatch detected: variable `var' does not match the clockt(`clockt') format."
        //di as error "Expected `expected_colons' colon(s), but found `r(N)' incompatible observation(s)."
        di as error "Examples: clockt(h) → '04', clockt(hm) → '04:00', clockt(hms) → '04:00:00'"
        exit 198
    }

    drop `coloncount'
}

		
	local numvars : word count `varlist'  // Count number of variables

    if `numvars' == 2 { // Two variables specified
        
		quietly {
			
		local var1 : word 1 of `varlist'
        local var2 : word 2 of `varlist'
		
		* 1) The following code creates START out of TS.
		tempvar milliseconds minutes
		gen `milliseconds' = clock(`var1', "`clockt'") 
		gen `minutes' = mod(`milliseconds', 86400000) / 60000 
		gen start=mod(`minutes'-(`dst'*60),1440)

		* 2) sort the episodes using the new START.
		tempvar epnum 
		sort `did' start
		bysort `did': gen `epnum'=_n 

        * 3) create end
		tempvar milliseconds minutes
		gen `milliseconds' = clock(`var2', "`clockt'") 
		gen `minutes' = mod(`milliseconds', 86400000) / 60000 
		//gen end=mod(`minutes'-(`dst'*60),1440)	
		gen end = cond(mod(`minutes' - (`dst'*60), 1440)==0, 1440, mod(`minutes' - (`dst'*60), 1440))
		
		* 4) labelling
		label define clock`dst' 0 "`mymacro':00", replace

		forvalues i = 1/1440 { // we need the label to end at 1440.

			local minutes = (`dst'*60-0) + `i'  // Convert index to minute count (4 AM = 240 minutes)
			local hour = mod(floor(`minutes' / 60), 24)  // Ensure hour cycles through 0-23
			local min = mod(`minutes', 60)
			local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
			label define clock`dst' `i' "`time'", modify
		}

			label define clock`dst' 0 "`: label clock`dst' 1440'", modify

		label value start clock`dst'
		label value end clock`dst'

		lab var start "start time of the episode (minute of day)"
        lab var end "end time of the episode (minute of day)"
       
		order `did' `epnum' start end 
		
		}
	
	display as text "The variables " ///
    as result "start" ///
    as text " and " ///
    as result "end" ///
    as text " have been created using `varlist'."
	
	
	
    }
	
    else if `numvars' == 1 { // Only one variable specified
		
        quietly {
		
		local var1 `varlist'
		
		* 1) The following code creates START out of TS.
		tempvar milliseconds minutes
		gen `milliseconds' = clock(`var1', "`clockt'") 
		gen `minutes' = mod(`milliseconds', 86400000) / 60000 
		gen start=mod(`minutes'-(`dst'*60),1440)

		* 2) sort the episodes using the new START.
		tempvar epnum 
		sort `did' start
		bysort `did': gen `epnum'=_n 

        * 3) create end

		tempvar last
		sort `did' `epnum'
		bysort `did': egen `last'=max(`epnum')
       
		gen end=start[_n+1] 
		replace end=1440 if `epnum'==`last'
		
		* 4) labelling

		label define clock`dst' 0 "`mymacro':00", replace

		forvalues i = 1/1440 { 
			local minutes = (`dst'*60-0) + `i'  
			local hour = mod(floor(`minutes' / 60), 24) 
			local min = mod(`minutes', 60)
			local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
			label define clock`dst' `i' "`time'", modify
		}

		label define clock`dst' 0 "`: label clock`dst' 1440'", modify

		label value start clock`dst'
		label value end clock`dst'

		lab var start "start time of the episode (minute of day)"
        lab var end "end time of the episode (minute of day)"
       
		order `did' `epnum' start end 
		
		}

	display as text "The variable " ///
    as result `"start"' ///
    as text " has been created using `varlist', and " ///
    as result `"end"' ///
    as text " has been created assuming that each episode ends when the next episode begins."
	
    }
	
end

