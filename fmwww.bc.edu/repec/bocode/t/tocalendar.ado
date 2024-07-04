
	
program tocalendar, rclass

	version 11 
	
	syntax, diaryid(string) diaryst(string)
	
		quietly {
	
			sum time 
			replace time=time/`r(min)' 
			expand time
			sort `diaryid' epnum 
			drop epnum 
			capture drop tslot
			bysort `diaryid': gen tslot=_n
			capture drop time 
			
		xclock`diaryst'
		
		capture drop start
		gen start=(tslot*10)-10
		label value start xclock`diaryst'
		
		capture drop end
		gen end=tslot*10
		label value end xclock`diaryst'
		
		capture drop clockst
		
		order `diaryid' tslot start end 
		sort `diaryid' tslot 
		
		lab var tslot "time slot"
*lab var clockst "start time on 24-hour clock"		
lab var start "start time of episode (minute of day)"
lab var end "end time of episode (minute of day)"

	}			
	    
end








