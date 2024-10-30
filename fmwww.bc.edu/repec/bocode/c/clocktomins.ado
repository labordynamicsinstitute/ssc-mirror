


program clocktomins, rclass

	version 11 
	
	syntax varlist(min=1 max=1 string), diaryid(string) diaryst(string) 

	tokenize `varlist'
	local start_clock `1'
	
	quietly {
	

		* 1) The following code creates START out of TS.

		tempvar starthour startminute
		
		split `start_clock', parse(:)

		destring `start_clock'1, replace
		destring `start_clock'2, replace
		
		rename `start_clock'1 `starthour'
		rename `start_clock'2 `startminute'
		
		gen start=((`starthour'*60+`startminute')-(`diaryst'*60)) 
		replace start=[1440-(`diaryst'*60)] + [(`starthour'*60)+`startminute'] if `starthour'<`diaryst'
		
		* 2) sort the episodes using the new START.
		
		tempvar epnum 
		sort `diaryid' start
		bysort `diaryid': gen `epnum'=_n 

		tempvar last
		sort `diaryid' `epnum'
		bysort `diaryid': egen `last'=max(`epnum')
       
		* CREATING END FROM START.
		
		gen end=start[_n+1] 
		replace end=1440 if `epnum'==`last'
		
		xclock`diaryst'
		lab value start xclock`diaryst'
		lab value end xclock`diaryst'
		
		capture drop `start_clock'3 `end_clock'3
		
		lab var start "start time of the episode (minute of day)"
        lab var end "end time of the episode (minute of day)"
		
		order `diaryid' `epnum' start end 

} 


end

