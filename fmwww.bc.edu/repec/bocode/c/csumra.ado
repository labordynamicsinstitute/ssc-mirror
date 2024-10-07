*! 1.0.0 Ariel Linden 02Oct2024

program define csumra, rclass

	version 11.0

	/* obtain settings */
	syntax varlist(min=2 max=2 numeric) [if] [in] , ///
	RISK(varname)									///
	LIMit(numlist max=1)							///
	[ ODDS(real 2)									///
	Wt(varname)										///
	REPLace											///
	NOgraph	*										///
	]         

		marksample touse
		qui count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)
		qui replace `touse' = -`touse'

        // parse yvar and xvar
		tokenize `varlist'
		local yvar `1'
		local xvar `2'

        // verification that yvar is binary and coded as 0 or 1
        capture assert inlist(`yvar', 0, 1) if `touse' 
        if _rc { 
            di as err "`yvar' must be coded as either 0 or 1"
            exit 450 
        }
		
		// verification that riskscore values are between 0 and 1
		qui sum `risk' if `touse', meanonly
		if r(min) < 0 | r(max) > 1 {
            di as err "`risk' must only contain values between 0 and 1"
            exit 198 			
		} 

		// error if odds == 1
		if `odds' == 1 { 
			di as err "the odds cannot be set to 1 because it won't detect a process change"
            exit 198  
        } 
		
		// odds cannot be negative
		if `odds' <= 0 {
			di as err "the odds must be greater than 0"
            exit 198  
		}	
				
		// replace previously generated variables by csumra
		if "`replace'" != "" {
			local csumravars : char _dta[_csumravars]
			if "`csumravars'" != "" {
				foreach v of local csumravars {
					capture drop `v'
				}
			}
		}
		
		// weighting
		if 	"`wt'" == "" {		
			tempvar _ws _wf
			qui gen `_ws' = log((1)/(1 - `risk' + `odds' * `risk')) if `touse'
			qui gen `_wf' = log(`odds' / ((1 - `risk' + `odds' * `risk') * 1)) if `touse'
			qui gen _wt = cond(y,`_wf',`_ws') if `touse'
		}
		else {
			qui gen _wt = `wt' if `touse'
		}	
			
		// generate cusum
		qui gen _ct = 0 if `touse'
	
		sort `touse' `xvar'	
	
		// odds > 1 indicates process deterioration
		if `odds' > 1 {
			qui replace _ct in 1 = max(0, _ct[1] + _wt[1]) if `touse'
			forvalues ii = 2/`N' {
				qui replace _ct in `ii' = max(0, _ct[`ii'-1] + _wt[`ii']) if `touse'
			}
			qui gen _signal = cond(_ct > `limit', 1, 0) if `touse'		
		}	
		// odds < 1 indicates process improvement
		else if `odds' < 1 {
			qui replace _ct in 1 = min(0, _ct[1] - _wt[1]) if `touse'
			forvalues ii = 2/`N' {
				qui replace _ct in `ii' = min(0, _ct[`ii'-1] - _wt[`ii']) if `touse'	
			}
			qui gen _signal = cond(_ct < `limit', 1, 0) if `touse'		
		}	

		// keep track of variables created by csum
		local csumravars _wt _ct _signal
        char def _dta[_csumravars] "`csumravars'"
		

		// graph it
        if "`nograph'" == ""  {	
			local roundlimit = round(`limit',.001)
			twoway(connected _ct `xvar' if `touse', mcol(black) msize(vsmall) lcolor(black)) ///
			(connected _ct `xvar' if _signal==1 & `touse', mcol(orange) msize(vsmall) lcolor(orange)), yline(`limit') ///
				ytitle("Risk Adjusted Cusum (`1')") note("control limit: `roundlimit'") legend(off) `options'
		}		
	
end	
