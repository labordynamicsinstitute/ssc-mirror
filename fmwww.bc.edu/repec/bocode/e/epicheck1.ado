


program epicheck1, rclass

	version 11 
	
	syntax , diaryid(string) 
	
	*disp as text "epicheck1 looks for missing values in START and END"
	
		quietly {
		
			capture drop flag_start 
			capture drop flag_end
			
			tempvar x
			qui recode start (0/1439=0) (else=1), gen(`x')
			qui count if `x'==1
			local estart=r(N)
			
			tempvar check
			bysort `diaryid': egen `check'=total(`x')
			sort `diaryid' start
			capture drop epnum
			bysort `diaryid': gen epnum=_n
			qui count if epnum==1 & `check'!=0
			local ndstart=r(N)
			qui count if epnum==1
			local dtotal=r(N)
			tempvar rate
			gen `rate'=(`ndstart'/`dtotal')*100
			replace `rate'=round(`rate')
			qui sum `rate'
			local srate=r(mean)
			
			capture drop flag_start
			bysort `diaryid': egen flag_start=total(`x')
			recode flag_start (0=0) (else=1)
			lab var flag_start "Diaries with some missing/invalid value in START"
		
			tempvar x
			qui recode end (1/1440=0) (else=1), gen(`x')
			qui count if `x'==1
			local eend=r(N)
			
			tempvar check
			bysort `diaryid': egen `check'=total(`x')
			sort `diaryid' start
			capture drop epnum
			bysort `diaryid': gen epnum=_n
			qui count if epnum==1 & `check'!=0
			local ndend=r(N)
			
			qui count if epnum==1
			local dtotal=r(N)
			tempvar rate
			gen `rate'=(`ndend'/`dtotal')*100
			replace `rate'=round(`rate')
			qui sum `rate'
			local erate=r(mean)
			
			capture drop flag_end
			bysort `diaryid': egen flag_end=total(`x')
			recode flag_end (0=0) (else=1)
			lab var flag_end "Diaries with some missing/invalid value in END"
		
		} // end of quietly.
		
		
		if `estart'>0 { 
				disp in red "<start> has `estart' missing or invalid value."
				disp in red "affecting `ndstart' diaries, `srate'% of total."
				disp in red "<flag_start> shows the problematic diaries."
				disp in red "Fix problem and run epichecks again."
			}
	
			else {
				disp as text "<start> has no missing or invalid value."
			}
			
		
		if `eend'>0 { 
				disp in red "<end> has `eend' missing or invalid value."
				disp in red "affecting `ndend' diaries, `erate'% of total."
				disp in red "<flag_end> shows the problematic diaries."
				disp in red "fix problem and run epichecks again."
			}
	
			else {
				disp as text "<end> has no missing or invalid value."
			}
		
	if `estart'>0|`eend'>0 { 
				disp as error "fix problem and run epichecks again."
			}
	if `estart'==0 & `eend'==0 { 
				
			}

			
end

	
