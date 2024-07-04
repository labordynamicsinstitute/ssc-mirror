


program clocktomins, rclass

	version 11 
	
	syntax varlist(min=1 max=1 string), diaryid(string) epnum(string) diaryst(string) 

	tokenize `varlist'
	local start_clock `1'
	
	quietly {
	
		tempvar starthour startminute
		
		split `start_clock', parse(:)

		destring `start_clock'1, replace
		destring `start_clock'2, replace
		
		rename `start_clock'1 `starthour'
		rename `start_clock'2 `startminute'

		tempvar last
		sort `diaryid' `epnum'
		bysort `diaryid': egen `last'=max(`epnum')

		gen start=((`starthour'*60+`startminute')-(`diaryst'*60)) 
		replace start=1440-(((`diaryst'-`starthour')*60)+`startminute') if `starthour'<`diaryst'

		tempvar udid 
		egen `udid'=group(`diaryid')
		xtset `udid' `epnum' 
		
		gen end=start[_n+1] 
		replace end=1440 if `epnum'==`last'
	
		*gen time=end-start
		
		xclock`diaryst'
		lab value start xclock`diaryst'
		lab value end xclock`diaryst'
		
		drop `start_clock'3 
		
		lab var start "start time of the episode (minute of day)"
        lab var end "end time of the episode (minute of day)"
		 
	    order `diaryid' `epnum' start end
} 


end

