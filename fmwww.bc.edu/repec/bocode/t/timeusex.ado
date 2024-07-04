


program timeusex, rclass

	version 11 
	
	syntax varlist(min=1 max=1 numeric), diaryid(string) diaryst(string)

	tokenize `varlist'
	
		local activity `1'
		
	quietly {
	
		
		tempfile existingfile
		save "`existingfile'"
	
			//keeping the variables of interest only.
			keep `diaryid' start end `activity'
		
			//making a new seq file where eps are defined by ACTIVITY.
			sequencex `activity', diaryid(`diaryid') diaryst(`diaryst')
	
			//keeping track of non participants:
			preserve
		
			tempvar epcounter
			sort `diaryid' start
			bysort `diaryid': gen `epcounter'=_n
			keep if `epcounter'==1
			keep `diaryid' // `weight'  
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
				bysort `diaryid': egen total=total(`time')
				lab var total "total time in activity"
		
				*numberof episodes:

				tempvar epcounter
				sort `diaryid' start
				bysort `diaryid': gen `epcounter'=_n
				bysort `diaryid': egen episodes=max(`epcounter')
				lab var episodes "number of episodes in activity"
		
				*timing of epidoses 
		
				keep `diaryid' start end `time' `epcounter' total episodes
		
				gen duration=`time'
				drop `time'
		
				reshape wide start end duration, i(`diaryid') j(`epcounter')
		
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

		
		sort `diaryid'
		merge 1:1 `diaryid' using "`participants'"
		
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
		
		sort `diaryid'
		tempfile results
		save "`results'"
		
		*merging the background vars again
		use "`existingfile'", clear
		drop start end time 
		bysort `diaryid': gen `epcounter'=_n
		keep if `epcounter'==1
		sort `diaryid'
		tempfile background
		save "`background'"
		
		use "`results'"
		merge 1:1 `diaryid' using "`background'"
		keep if _merge==3
		drop _merge
		
		xclock`diaryst'
		lab value start* end* xclock`diaryst'
		
		drop `activity'
		
		format start* end* duration* %7.0g
	
		
		local primeras "`diaryid' total episodes"
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

