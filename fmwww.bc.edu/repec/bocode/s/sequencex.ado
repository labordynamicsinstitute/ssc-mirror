

program sequencex, rclass

	version 11 
	
	syntax varlist(min=1 max=30 numeric), diaryid(string) diaryst(string)

	tokenize `varlist'
		
		quietly {
			
		//for the report
		count
		local startN=r(N)
		
		capture drop epnum
		sort `diaryid' start 
		bysort `diaryid': gen epnum=_n
		
		count if epnum==1
		local ndiaries=r(N)
		
		sort `diaryid'
		tempvar udid
		egen `udid'=group(`diaryid') 
		
		
	foreach var in `varlist' {
				
		replace `var'=999999 if `var'==.
		replace `var'=888888 if `var'==.a
		replace `var'=777777 if `var'==.b
		replace `var'=666666 if `var'==.c
		replace `var'=555555 if `var'==.d
		replace `var'=444444 if `var'==.e
		replace `var'=333333 if `var'==.f
		replace `var'=222222 if `var'==.g
		replace `var'=111111 if `var'==.h
		
	} 
	
			
		sort `udid' start
		capture drop epnum
		bysort `udid': gen epnum=_n
		xtset `udid' epnum
	
			
		foreach var in `varlist' {
				
				tempvar diff_`var'
				gen `diff_`var''=`var'-l1.`var'
				recode `diff_`var'' (0=0) (.=.) (else=1) 
			    replace `diff_`var''=10 if epnum==1 // guarantees that the first ep will never be deleted
			} 
			
		
		tempvar superdiff
		gen `superdiff'=0
		
		foreach var in `varlist' {
			
			replace `superdiff'=`superdiff'+`diff_`var''
			
	    }
		
		
		drop if `superdiff'==0 
		sort `udid' epnum
		drop epnum
		bysort `udid': gen epnum=_n
		
		xtset `udid' epnum
		tempvar f1_start
		gen `f1_start'=f1.start
		
		capture drop end
		
		gen end=`f1_start' 
		
		tempvar lastep
		bysort `diaryid': egen `lastep'=max(epnum)
		
		replace end=1440 if epnum==`lastep' 
		
		capture drop time
		gen time=end-start
		
		capture drop epnum
		sort `udid' start
		bysort `udid': gen epnum=_n
		
		
		*clockst
		xclock`diaryst' 
		label value start xclock`diaryst'
		label value end xclock`diaryst'
		
		capture drop clockst
		decode start, gen(xxxxx)
        split xxxxx, p(:)
        gen yyyyy=xxxxx1+"."+xxxxx2
        destring yyyyy, gen(clockst)
		drop xxxxx xxxxx1 xxxxx2 yyyyy
		
	
		foreach var in `varlist' {
			
			replace `var'=.  if `var'==999999
			replace `var'=.a if `var'==888888 
			replace `var'=.b if `var'==777777 
			replace `var'=.c if `var'==666666 
			replace `var'=.d if `var'==555555 
			replace `var'=.e if `var'==444444 
			replace `var'=.f if `var'==333333
			replace `var'=.g if `var'==222222
			replace `var'=.h if `var'==111111
			
		}
		
		
order `diaryid' epnum start end time clockst `varlist'

lab var epnum "episode number"
lab var clockst "start time on 24-hour clock"		
lab var start "start time of episode (minute of day)"
lab var end "end time of episode (minute of day)"
lab var time "duration of episode (minutes)"

		sort `diaryid' 
		
		count
		local endN=r(N)
		
		local change=`startN'-`endN'
		
		local percent=(`change'/`startN')*100	
		
		local mean1=`startN'/`ndiaries'
		
		local mean2=`endN'/`ndiaries'

}

*the report

if `change'==0 {
	disp as text "there is no change in the number of episodes"
}

else {
	disp as text "the starting file had `startN' episodes (avg. of " %3.1f `mean1' " episodes per diary)"
	disp as text "the new file has `endN' episodes (avg. of " %3.1f `mean2' " episodes per diary)."
	disp as text "The new file has `change' fewer episodes that the starting file (" %3.1f `percent' "% reduction)"
}

	
end
