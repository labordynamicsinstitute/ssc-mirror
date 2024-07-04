


program clocktomine, rclass

	version 11 
	
	syntax varlist(min=1 max=1 string), diaryid(string) epnum(string) diaryst(string) 

	tokenize `varlist'
	local end_clock `1'
	
	quietly {
	
		tempvar endhour endminute trueendhour trueendminute 
		
		split `end_clock', parse(:)

		destring `end_clock'1, replace
		destring `end_clock'2, replace

		rename `end_clock'1 `endhour' 
		rename `end_clock'2 `endminute'

		gen `trueendhour'=`endhour' 
		gen `trueendminute'=`endminute'
		
		tempvar last
		sort `diaryid' `epnum'
		bysort `diaryid': egen `last'=max(`epnum')
		replace `endhour'=`diaryst' if `epnum'==`last'
		replace `endminute'=0 if `epnum'==`last'

		gen end_atus=((`trueendhour'*60+`trueendminute')-(`diaryst'*60)) 
		replace end_atus=1440-(((`diaryst'-`trueendhour')*60)+`trueendminute') if `trueendhour'<`diaryst'
		replace end_atus=. if `epnum'!=`last'
		
		gen end=((`endhour'*60+`endminute')-(`diaryst'*60)) 
		replace end=1440-(((`diaryst'-`endhour')*60)+`endminute') if `endhour'<`diaryst'
		replace end=1440 if `endhour'==`diaryst' & `endminute'==0
		
		tempvar udid 
		egen `udid'=group(`diaryid')
		xtset `udid' `epnum' 
		
		gen start=l1.end
		replace start=0 if `epnum'==1
		
		xclock`diaryst'
		lab value start xclock`diaryst'
		lab value end xclock`diaryst'
		lab value end_atus xclock`diaryst'
		
		drop `end_clock'3
		
		lab var start "start time of the episode (minute of day)"
        lab var end "end time of the episode (minute of day)"
        lab var end_atus "end time of the last episode in ATUS files (minute of day)"
		
		order `diaryid' `epnum' start end end_atus 
	
} // end of quietly


end

