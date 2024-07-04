

program epicheck2, rclass

	version 11 
	
	syntax , diaryid(string) 
	
	*disp as text "epicheck2 checks that all diaries start at minute 0."
	
quietly {
	
	*All diaries must start at minute 0:
	
	*capture drop flag
	*capture drop flag_start
	
	sort `diaryid' start
	capture drop epnum
	bysort `diaryid': gen epnum=_n
	
	tempvar invalidep
	gen `invalidep'=0
	replace `invalidep'=1 if epnum==1 & start!=0 
	
	capture drop flag_badstart
	bysort `diaryid': egen flag_badstart=total(`invalidep') 
	recode flag_badstart (0=0) (else=1)
	lab var flag_badstart "diaries that do not start at minute 0"

	*locals
	qui count if epnum==1 & `invalidep'==1
	local invalid=r(N)
	qui count if epnum==1
	local dtotal=r(N)
	tempvar rate
	gen `rate'=(`invalid'/`dtotal')*100
	replace `rate'=round(`rate')
	qui sum `rate'
	local rate=r(mean)
				
}
		
	if `invalid'>0 { 
				//count if `invalidep'==1
				disp in red "`invalid' diaries don't start at minute 0, `rate'% of total."
				disp in red "<flag_badstart> shows the problematic diaries"
				disp as error "fix problem and run epichecks again."
				
			}
	
			else {
			
				disp as text "all diaries start at minute 0"
				
			}


end


	
	






