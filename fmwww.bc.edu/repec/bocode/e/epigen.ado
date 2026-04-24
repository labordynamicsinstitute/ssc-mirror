 

program epigen

    version 11 
    
    syntax varlist(min=1 max=20), did(varlist) [DST(numlist max=1 integer) NOLABEL]

	
local err 0

// Check 'tslot'
capture confirm variable tslot
if _rc {
    display as error "Error: Variable 'tslot' is missing."
    local err = 1
}
else {
    capture confirm numeric variable tslot
    if _rc {
        display as error "Error: Variable 'tslot' is not numeric."
        local err = 1
    }
}

if `err' {
    exit 198
}



// dst() only required if we are producing labels (i.e. when nolabel is NOT specified)
if "`nolabel'" == "" {
    if "`dst'" == "" {
        di as error "Error: dst() is required unless you specify the nolabel option."
        di as error "Example: epigen ..., did(...) dst(0)"
        di as error "Or:      epigen ..., did(...) nolabel"
        exit 198
    }
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

quietly count if __skip
if r(N) > 0 {
    di as result "Warning: `r(N)' observations have missing values in did() and will be ignored."
    drop if __skip
}

	tslotcheck, did(`did') quiet 


    quietly {
		
	        *------------------------------------------------------------
        * Determine expected number of slots per diary (robust)
        *------------------------------------------------------------
        capture drop __maxslot __first
        bysort `did': egen __maxslot = max(tslot)
        bysort `did': gen byte __first = (_n==1)

        quietly summarize __maxslot if __first, detail
        local nslots = r(p50)

        if missing(`nslots') | `nslots' <= 0 {
            di as error "Error: could not determine expected number of slots (median max(tslot))."
            exit 198
        }

        local slotdur = 1440/`nslots'

		
		sort `did' tslot 
		bysort `did': gen epnum=_n
		
		tempvar episode 
		egen `episode'=group(`varlist'), missing 
		
                tempvar udid
		egen `udid'=group(`did')
		xtset `udid' epnum
		
		capture drop __change 
		gen __change=`episode'-l1.`episode'
		replace __change=1 if epnum==1
		
		drop if __change==0
	
		drop epnum
		sort `did' tslot
		bysort `did': gen epnum=_n
		
		tempvar lastep
		bysort `did': egen `lastep'=max(epnum)

		xtset `udid' epnum
		
		// START and END
	
		capture drop start
		gen start=tslot*`slotdur'-`slotdur'
		capture drop end
		gen end=f1.start 
		replace end=1440 if epnum==`lastep'
		
		// TIME
        capture drop time
		gen time=end-start 

	
		
if "`nolabel'" == "" {
    // ADDING LABELS TO START AND END.
    local hh0 = string(mod(`dst',24), "%02.0f")
    label define clock`dst' 0 "`hh0':00", replace

    forvalues i = 1/1440 {
        local minutes = (`dst'*60) + `i'
        local hour = mod(floor(`minutes'/60), 24)
        local min  = mod(`minutes', 60)
        local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
        label define clock`dst' `i' "`time'", modify
    }

    label value start clock`dst'
    label value end   clock`dst'

    // CLOCKST
    capture drop clockst
    tempvar label
    decode start, gen(`label')
    split `label', p(:)
    tempvar new
    gen `new' = `label'1 + "." + `label'2
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

		drop tslot 
        // FINAL REPORTING
        count
        local endN = r(N)
		count if epnum==1
		local ndiaries=r(N)
        local mean2 = `endN' / `ndiaries'
		  
        
         capture drop __skip `udid' __maxslot __first __change
   

    } // End of quietly

	disp as text "The new file contains `endN' episodes (" %3.1f `mean2' " episodes per diary)"

	
end

