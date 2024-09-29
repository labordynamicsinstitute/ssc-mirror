*! 1.0.0 Ariel Linden 16Sep2024

program define csum, rclass

	version 11.0

	/* obtain settings */
	syntax varlist(min=2 max=2 numeric) [if] [in] , ///
	BLProb(numlist >0 <1 max=1)						///
	[ ODDS(real 2)									///
	LIMit(numlist max=1)							///
	Reps(integer 50)				                ///	
	SEED(string) 									///
	CENtile(real 95)								///
	Wt(varlist min=1 max=1)							///
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
		
		// error if odds multiplier == 1
		if `odds' == 1 { 
			di as err "the odds multiplier cannot be set to 1 because it won't detect a process change"
            exit 198  
        } 
		
		// set default odds multiplier == 2
		if `odds' <= 0 {
			di as err "the odds multiplier must be greater than 0"
            exit 198  
		}	
				
		// replace previously generated variables by csum
		if "`replace'" != "" {
			local csumvars : char _dta[_csumvars]
			if "`csumvars'" != "" {
				foreach v of local csumvars {
					capture drop `v'
				}
			}
		}
		
		// recode baseline probability (blprob) if > 50%
		if `blprob' >  0.50 {
			local blprob = 1 - `blprob'
		}
	
		// compute limit if not specified
		if "`limit'" == "" {
			if `odds' > 1 { 
				preserve
				simulate ct_max = r(max) , reps(`reps') seed(`seed') nolegend: csumdgp , obs(`N') mult(`odds') p0(`blprob')
				qui centile ct_max, centile(`centile')
				local limit = r(c_1) 
				restore
			}
			else if `odds' < 1 { 
				preserve
				local centile = 100 - `centile'
				simulate ct_min = r(min) , reps(`reps') seed(`seed') nolegend: csumdgp , obs(`N') mult(`odds') p0(`blprob')
				qui centile ct_min, centile(`centile')
				local limit = r(c_1) 
				restore
			}
		} // end no limit 	
		return scalar limit = `limit'

		// weighting
		local o0 = `blprob' / (1 - `blprob')
		local oA = `odds' * `o0'
		local pA = `oA' / (1 + `oA')
				
		if 	"`wt'" == "" {
			local wf = log(`pA' /  `blprob')
			local ws = log((1 - `pA') / (1 - `blprob'))
			qui gen _wt = cond(y==1, `wf', `ws') if `touse'
		}
		else {
			qui gen _wt = `wt' if `touse'
		}	
			
		// generate cusum
		qui gen _ct = 0 if `touse'
	
		sort `touse' `xvar'	
	
		// odds multiplier > 1 indicates process deterioration
		if `odds' > 1 {
			qui replace _ct in 1 = max(0, _ct[1] + _wt[1]) if `touse'
			forvalues ii = 2/`N' {
				qui replace _ct in `ii' = max(0, _ct[`ii'-1] + _wt[`ii']) if `touse'
			}
			qui gen _signal = cond(_ct > `limit', 1, 0) if `touse'		
		}	
		// odds multiplier < 1 indicates process improvement
		else if `odds' < 1 {
			qui replace _ct in 1 = min(0, _ct[1] - _wt[1]) if `touse'
			forvalues ii = 2/`N' {
				qui replace _ct in `ii' = min(0, _ct[`ii'-1] - _wt[`ii']) if `touse'	
			}
			qui gen _signal = cond(_ct < `limit', 1, 0) if `touse'		
		}	

		// keep track of variables created by csum
		local csumvars _wt _ct _signal
        char def _dta[_csumvars] "`csumvars'"
		

		// graph it
        if "`graph'" == ""  {	
			local roundlimit = round(`limit',.001)
			twoway(scatter _ct `xvar' if `touse', mcol(black) msize(vsmall))(scatter _ct `xvar' if _signal==1 & `touse', mcol(orange) msize(vsmall)), yline(`limit') ///
				ytitle("Cusum (`1')") note("control limit: `roundlimit'") legend(off) `options'
		}		
	
end	
