

program sequence, rclass

	version 11 
	
	syntax varlist(min=1 max=30 numeric), diaryid(string) diaryst(string)
	
	quietly {
		
				count
				local startN=r(N)
	
				count if tslot==1
				local ndiaries=r(N)
	
				count if tslot==.
				local missing=r(N)
				drop if tslot==.
	
				tempvar slotcounter nslots minslot maxslot sloterror mine maxe x a b c 
	
				sort `diaryid' tslot 
	
				bysort `diaryid': gen `slotcounter'=_n
				bysort `diaryid': egen `minslot'=min(tslot)
				bysort `diaryid': egen `maxslot'=max(tslot)
				bysort `diaryid': egen `nslots'=max(`slotcounter')
	
		
				* (a) flagging if not all diaries start at slot 1
				count if `minslot'!=1
				gen `a'=0
				replace `a'=1 if r(N)>0 
	
				* (b) flagging if all dairies dont have the same number of slots.
				sum `nslots'
				gen `b'=0
				replace `b'=1 if r(min)!=r(max)
				
				* (c) flagging if the slots do not have the right values:
				gen `c'=0
				replace `c'=1 if `nslots'!=`maxslot'
	
	
				gen `x'=0 // tracking errors.
				replace `x'=1 if `a'==1|`b'==1|`c'==1
				
				sum `x'
				local error=r(mean) 

			}
	
	
	if `error'==0 {
		
		quietly {
		
	
			count
			local startN=r(N)
	
			count if tslot==1
			local ndiaries=r(N)
	
			count if tslot==.
			local missing=r(N)
			drop if tslot==.
	
			tempvar slotcounter nslots minslot maxslot sloterror mine maxe 
	
			sort `diaryid' tslot 

			tempvar id
			egen `id'=group(`diaryid') 
	
			sum tslot
			local time_interval=1440/r(max)
			
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
	
		
			xtset `id' tslot
			
			foreach var in `varlist' {
				
				tempvar diff_`var'
				gen `diff_`var''=`var'-l1.`var'
				recode `diff_`var'' (0=0) (.=.) (else=1) 
			    replace `diff_`var''=10 if tslot==1 // guarantees that the first slot
			} 
			
		tempvar superdiff
		gen `superdiff'=0
		
		foreach var in `varlist' {
			replace `superdiff'=`superdiff'+`diff_`var''
	    }
		
		drop if `superdiff'==0 
			
			capture drop epnum
			bysort `diaryid': gen epnum=_n
		
			
			capture drop start 
			gen start=tslot*`time_interval'-`time_interval'
		
			
			capture drop end
			xtset `id' epnum
			gen end=f.start
			replace end=1440 if f.start==.
		
			
			capture drop time
			gen time=end-start

			
			* clockst *
			
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

	
	drop tslot

	order `diaryid' epnum start end time clockst `varlist'

lab var epnum "episode number"
lab var clockst "start time on 24-hour clock"		
lab var start "start time of episode (minute of day)"
lab var end "end time of episode (minute of day)"
lab var time "duration of episode (minutes)"
	
		count
		local endN=r(N)
		
		local change=`endN'-`startN'
	
		local mean1=`startN'/`ndiaries'
		
		local mean2=`endN'/`ndiaries'
		
		local check=`startN'-(`ndiaries'*`mean1')
		
} 

		if `missing'>0 {
	
			disp as text "`missing' observations have been dropped because tslot had a missing value."
}

else {
	
}

* The report:
	
disp as text "the starting file had `startN' time-slots ("`ndiaries' " diaries with" %4.0f `mean1' " time slots per diary)"
disp as text "the new file has `endN' episodes (Avg. of " %3.1f `mean2' " episodes per diary)"
		

}

	else {
	
		disp as error "The variable tslot does not value the same values across diaries. Fix and run program again"
		 
	}

	
end


