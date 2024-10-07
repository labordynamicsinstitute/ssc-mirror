*! 1.0.0 Ariel Linden 30Sep2024

program define csumralimit, rclass

	version 11.0

	/* obtain settings */
	syntax varname [if] [in]  		///
		[, ODDS(real 2)				///
		Reps(integer 50)			///	
		SEED(string)				///
		CENtile(real 95)			///
        Local(str)					/// macro that can be used in -csumra-		
		]         

		
		marksample touse
		qui count if `touse'
		if r(N) == 0 error 2000
		local N = r(N)
		qui replace `touse' = -`touse'
		
		// error if odds multiplier == 1
		if `odds' == 1 { 
			di as err "the odds cannot be set to 1 because it won't detect a process change"
            exit 198  
        } 		

        // parse riskscore
		tokenize `varlist'
		local risk `1'

		tempname riskscore
		mkmat `risk' if `touse', matrix(`riskscore')

		// compute limit if not specified
			if `odds' > 1 { 
				preserve
				simulate ct_max = r(max), reps(`reps') seed(`seed') nolegend: csumradgp , obs(`N') odds(`odds') riskscore(`riskscore')
				qui centile ct_max, centile(`centile')
				local limit = r(c_1) 
				restore
			}
			else if `odds' < 1 { 
				preserve
				local centile = 100 - `centile'
				simulate ct_min = r(min) , reps(`reps') seed(`seed') nolegend: csumradgp , obs(`N') odds(`odds') riskscore(`riskscore')
				qui centile ct_min, centile(`centile')
				local limit = r(c_1) 
				restore
			}
			return scalar limit = `limit'
			c_local `local' `"`limit'"'
			
			di as txt _n
			di as txt "   Risk adjusted control limit:" as result %9.3f `limit'			

end	