




program epigenx

    version 11 
    
    syntax varlist(min=1 max=20), did(varlist) [DST(numlist max=1 integer) NOLABEL]

	
// hard check: warn if START and/or END are missing and/or numerical.
local err 0

// Check 'start'
capture confirm variable start
if _rc {
    display as error "Error: Variable 'start' is missing."
    local err = 1
}
else {
    capture confirm numeric variable start
    if _rc {
        display as error "Error: Variable 'start' is not numeric."
        local err = 1
    }
}

// Check 'end'
capture confirm variable end
if _rc {
    display as error "Error: Variable 'end' is missing."
    local err = 1
}
else {
    capture confirm numeric variable end
    if _rc {
        display as error "Error: Variable 'end' is not numeric."
        local err = 1
    }
}

if `err' {
    exit 198
}


// dst() is only required if we are producing labels (i.e. when nolabel is NOT specified)
if "`nolabel'" == "" {
    if "`dst'" == "" {
        di as error "Error: dst() is required unless you specify the nolabel option."
        di as error "Example: epigenx ..., did(...) dst(0)"
        di as error "Or:      epigenx ..., did(...) nolabel"
        exit 198
    }
    // Range check for valid clock offsets
    if real("`dst'") < 0 | real("`dst'") > 23 {
        di as error "Error: dst() must be an integer between 0 and 23. You entered: `dst'"
        exit 198
    }
}



	// Check for missing values in the ID variable
	quietly {
	capture drop __skip
    gen byte __skip = 0
    foreach v of varlist `did' {
        replace __skip = 1 if missing(`v')
		}
	}
	
    quietly count if __skip
    if r(N) > 0 {
        di as result "Warning: `r(N)' observations have missing values in did() and will be ignored in the checks."
		di as result "Warning: The ID variable `did' contains 	`r(N)' missing values."
		disp as result "These will be ignored for the creation of episodes"
    }

	epicheck, did(`did') quiet 

    quietly {

        // Parameters for the final report
        count
        local startN = r(N)
        count if start == 0
        local ndiaries = r(N)
        count if start == .
        local missing = r(N)
        drop if start == .

	

		capture drop epnum
		sort `did' start 
		bysort `did': gen epnum=_n
		
		tempvar lastep
		egen `lastep'=max(epnum)
		
		tempvar episode 
		egen `episode'=group(`varlist'), missing 
		
                tempvar udid
		egen `udid'=group(`did')
		xtset `udid' epnum
		
		gen __change=`episode'-l1.`episode'
		replace __change=1 if epnum==1
		
		gen __tofix=0
		replace __tofix=1 if f1.__change==0
		
		drop if __change==0
	
		drop epnum
		sort `did' start 
		bysort `did': gen epnum=_n
		
		tempvar lastep
		bysort `did': egen `lastep'=max(epnum)

		xtset `udid' epnum
		replace end=f1.start if __tofix==1
		replace end=1440 if __tofix==1 & epnum==`lastep'
		
		// TIME
        capture drop time
		gen time=end-start 

		drop __tofix __change
	
		        if "`nolabel'" == "" {
            // ADDING LABELS TO START AND END.
            
local hh0 = string(mod(`dst',24), "%02.0f")
label define clock`dst' 0 "`hh0':00", replace


            forvalues i = 1/1440 { // we need the label to end at 1440.
                local minutes = (`dst'*60-0) + `i'  
                local hour = mod(floor(`minutes' / 60), 24)
                local min = mod(`minutes', 60)
                local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
                label define clock`dst' `i' "`time'", modify
            }

      
            label value start clock`dst'
            label value end clock`dst'
            
            // CLOCKST 
            capture drop clockst
            tempvar label 
            decode start, gen(`label')
            split `label', p(:)
            tempvar new 
            gen `new'=`label'1+"."+`label'2
            destring `new', gen(clockst)
            drop `label'1 `label'2
        }
		
        // Ordering of vars.
if "`nolabel'" == "" {
    order `did' epnum start end time clockst `varlist'
    
}
else {
    order `did' epnum start end time `varlist'
}



		lab var epnum "episode number"	
		lab var start "start time of episode (minute of day)"
		lab var end "end time of episode (minute of day)"
		lab var time "duration of episode (minutes)"
		lab var clockst "start time on 24-hour clock"	

        // LABELING VARIABLES
        lab var epnum "Episode number"
        lab var start "Start time of episode (minute of day)"
        lab var end "End time of episode (minute of day)"
        lab var time "Duration of episode (minutes)"

        // FINAL REPORTING
        count
        local endN = r(N)
        local change = `endN' - `startN'
        local mean1 = `startN' / `ndiaries'
        local mean2 = `endN' / `ndiaries'
        local check = `startN' - (`ndiaries' * `mean1')

    } // End of quietly

	disp as result "The starting file:"
	disp as text "`startN' episodes (" %3.1f `mean1' " episodes per diary)"
	disp as result "The new file:"
	disp as text "`endN' episodes (" %3.1f `mean2' " episodes per diary)"

capture drop `episode' `udid'
capture drop __skip

	
end

