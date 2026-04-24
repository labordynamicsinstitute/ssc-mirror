


program timeallocx

	version 11 
	
	syntax varlist(min=1 max=1 numeric), did(string) dst(string)

	tokenize `varlist'
	
		local activity `1'
		
	quietly {
	
		
		tempfile existingfile
		save "`existingfile'"
	
			//keeping the variables of interest only.
			keep `did' start end `activity'
		
			//making a new seq file where eps are defined by ACTIVITY.
			epigenx `activity', did(`did') dst(`dst')
	
			//keeping track of non participants:
			preserve
		
			tempvar epcounter
			sort `did' start
			bysort `did': gen `epcounter'=_n
			keep if `epcounter'==1
			keep `did'   
			tempfile participants
			save "`participants'"
		
			restore
			
			*the calculations begin:
		
			keep if `activity'==1 
			count 
			
			if r(N)==0 {
				disp as error "no time in activity at all."
			}
		
			else {
				
				*total time in the activity:
		
				tempvar time
				gen `time'=end-start
				bysort `did': egen total=total(`time')
				lab var total "total time in activity"
		
				*numberof episodes:

				tempvar epcounter
				sort `did' start
				bysort `did': gen `epcounter'=_n
				bysort `did': egen episodes=max(`epcounter')
				lab var episodes "number of episodes in activity"
		
				*timing of epidoses 
		
				keep `did' start end `time' `epcounter' total episodes
		
				gen duration=`time'
				drop `time'
		
				reshape wide start end duration, i(`did') j(`epcounter')
		
				recode total (0=0) (else=1), gen(participation)
		
				gen start_last=.
				gen end_last=.
				gen duration_last=.
		
				sum episodes
		
				foreach n of numlist 1/`r(max)' {
			
					replace start_last=start`n' if episodes==`n'
					replace end_last=end`n' if episodes==`n'
					replace duration_last=duration`n' if episodes==`n'
		
				}
		
				lab var start_last "start time of last episode"
				lab var end_last "end time of last episode"

		
		sort `did'
		merge 1:1 `did' using "`participants'"
		
		replace total=0 if _merge==2
		replace episodes=0 if _merge==2
		replace participation=0 if _merge==2
		
		
		sum episodes
		
		foreach n of numlist 1/`r(max)' {
			replace duration`n'=0 if _merge==2
		}
	
		sum episodes
		
		foreach n of numlist 1/`r(max)' {
			
			lab var start`n' "start time of episode `n'" 
			lab var end`n' "end time of episode `n'" 
			lab var duration`n' "duration of episode `n'" 
			
		}
		
		drop _merge
		drop participation
		
		sort `did'
		tempfile results
		save "`results'"
		
		*merging the background vars again
		use "`existingfile'", clear
		drop start end 
		bysort `did': gen `epcounter'=_n
		keep if `epcounter'==1
		sort `did'
		tempfile background
		save "`background'"
		
		use "`results'"
		merge 1:1 `did' using "`background'"
		keep if _merge==3
		drop _merge
		
		
		/* creating the value label for start and end */
		
		label define clock`dst' 0 "`mymacro':00", replace

		forvalues i = 1/1440 { // we need the label to end at 1440.

				local minutes = (`dst'*60-0) + `i'  // Convert index to minute count (4 AM = 240 minutes)
				local hour = mod(floor(`minutes' / 60), 24)  // Ensure hour cycles through 0-23
				local min = mod(`minutes', 60)
				local time = string(`hour', "%02.0f") + ":" + string(`min', "%02.0f")
			label define clock`dst' `i' "`time'", modify
		}

		label define clock`dst' 0 "`: label clock`dst' 1440'", modify

		label value start* end* clock`dst'

		drop `activity'
		
		format start* end* duration* %7.0g
	
		local primeras "`did' total episodes"
		local ultimas "start_last end_last duration_last"
		local lista ""
		
		sum episodes
		
		foreach n of numlist 1/`r(max)' {
			local lista "`lista' start`n' end`n' duration`n'"
		}

	order `primeras' `lista' `ultimas'

	
	} // end of "if there is data"
	
} // end of quietly

end

