

program epicheck3, rclass

	version 11 
	
	syntax , diaryid(string) 
	
	*disp as text "epicheck3 checks that all diaries end at minute 1440"
	

quietly {
	
	sort `diaryid' start
	capture drop epnum
	bysort `diaryid': gen epnum=_n
	
	tempvar lastep
	bysort `diaryid': egen `lastep'=max(epnum)
	
	tempvar invalidep
	gen `invalidep'=0
	replace `invalidep'=1 if epnum==`lastep' & end!=1440
	
	capture drop flag_badend 
	bysort `diaryid': egen flag_badend=total(`invalidep') 
	recode flag_badend (0=0) (else=1)
	lab var flag_badend "diaries that do not end at minute 1440"
	
	qui count if epnum==`lastep' & `invalidep'==1
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

				disp in red "`invalid' diaries do not end at minute 1440, `rate'% of total."
				disp in red "<flag_badend> flags the problematic diaries"
				disp as red "fix problem and run epichecks again."
			}
	
			else {
			
				disp as text "all diaries end at minute 1440"
				
			}
	


end


	
	






