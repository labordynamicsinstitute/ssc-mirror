

program epicheck4, rclass

	version 11 
	
	syntax, diaryid(string)
	
	/* epicheck4 checks thats start_t==end_t-1 */

quietly {
	
	capture drop flag
	capture drop invalidep
	
	sort `diaryid' start
	capture drop epnum
	bysort `diaryid': gen epnum=_n
	
	
	tempvar lag_end dif1

	tempvar id
	egen `id'=group(`diaryid')
	
	xtset `id' epnum
	gen `lag_end'=l1.end
	gen `dif1'=start-`lag_end'
	replace `dif1'=0 if epnum==1 
	
	capture drop invalidep
	gen invalidep=.
	replace invalidep=1 if `dif1'!=0
	count if invalidep==1
	local error=r(N)
	
	capture drop flag_gaps
	bysort `diaryid': egen flag_gaps=total(invalidep)
	recode flag_gaps (0=0) (1/max=1) 
	lab var flag_gaps "diaries with at least one episode where start_n!=end_n-1"


}


			if `error'>0 { 
		
				disp in red "there are `error' episodes where start_n!=end_n-1"
				disp in red "<flag_gaps> shows the problematic diaries"
				disp as text "fix problems and run epichecks again."
			}
	
			else {
				
				disp as text "there are no episodes where start_n!=end_n-1"
				
			}


end

