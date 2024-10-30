


program clocktomin, rclass

	version 11 
	
	syntax varlist(min=2 max=2 string), diaryid(string) diaryst(string) 

	tokenize `varlist'
	local start_clock `1'
	local end_clock `2'
	
	quietly {
	
		* 1) The following code creates START out of TS.

		tempvar starthour startminute
		
		split `start_clock', parse(:)

		destring `start_clock'1, replace
		destring `start_clock'2, replace
		
		rename `start_clock'1 `starthour'
		rename `start_clock'2 `startminute'
		
		gen start=((`starthour'*60+`startminute')-(`diaryst'*60)) 
		*replace start=1440-(((`diaryst'-`starthour')*60)+`startminute') if `starthour'<`diaryst'
		replace start=[1440-(`diaryst'*60)] + [(`starthour'*60)+`startminute'] if `starthour'<`diaryst'
		
		* 2) sort the episodes using the new START.
		
		tempvar epnum 
		
		sort `diaryid' start
		bysort `diaryid': gen `epnum'=_n 

        * 3) create end.
		
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
		
		*gen end=((`endhour'*60+`endminute')-(`diaryst'*60)) 
		*replace end=1440-(((`diaryst'-`endhour')*60)+`endminute') if `endhour'<`diaryst'
		*replace end=1440 if `endhour'==`diaryst' & `endminute'==0
		
		gen end=((`endhour'*60+`endminute')-(`diaryst'*60)) 
		replace end=[1440-(`diaryst'*60)] + [(`endhour'*60)+`endminute'] if `endhour'<`diaryst'
		replace end=1440 if `endhour'==`diaryst' & `endminute'==0
		
		xclock`diaryst'
		lab value start xclock`diaryst'
		lab value end xclock`diaryst'
		lab value end_atus xclock`diaryst'
		
		capture drop `start_clock'3 `end_clock'3
		
		lab var start "start time of the episode (minute of day)"
        lab var end "end time of the episode (minute of day)"
        lab var end_atus "end time of the last episode in ATUS files (minute of day)"
		
		order `diaryid' `epnum' start end end_atus 
	
} 


end

