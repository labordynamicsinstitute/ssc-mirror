*! 1.0.0 Ariel Linden 05July2023 

capture program drop iota
program iota, rclass byable(recall)

		version 12
		syntax anything [if] [in] , RATer(varlist min=1 max=1 numeric) TARget(varlist min=1 max=1 numeric) [ STandardize NOminal ]
		
			quietly {
				preserve
				tokenize `anything'
				local nvar : word count `anything'
				marksample touse
				count if `touse'
				if r(N) == 0 error 2000
				keep if `touse' 
				keep `anything' `rater' `target'
				local nobs = r(N) 
				tab `rater'
				local nrat = r(r)
				tab `target'
				local ntar = r(r)
				
				// interval (quantitative) data
				if "`nominal'" == "" {
					
					// standardize variables
					if "`standardize'" != "" {
						foreach i of local anything {
							sum `i'
							local mean = r(mean)
							local sd = r(sd)
							replace `i' = (`i' - `mean') / `sd'
						}
					}
					local varlist `anything'
				} // end interval data	
				
				// interval (quantitative) data
				else if "`nominal'" != "" {			
					tempvar z v
					local num 1
					foreach i of local anything {
						tabulate `i', generate(`z') nofreq
						rename (`z'*) (`v'#), addnumber(`num')
						local num = `num' + `r(r)'
					}

					foreach i of varlist `v'* {
						replace `i' = 2^-.50 if `i' == 1
						local varlist `varlist' `i'
					}
				} // end nominal 	
	
				local doss = 0
				local dess = 0
					
				foreach x of local varlist {
					anova `x' `rater' `target'
					local sst = e(ss_1) + e(ss_2) + e(rss)
					local ssw = e(rss) + e(ss_1)
					local ssb = e(ss_1)
						
					local doss = `doss' + `ssw'
					local dess = `dess' + ((`nrat' - 1) * `sst' + `ssb')
				}

				local iota  = 1 - (`nrat' * `doss') / `dess'	
					
			} // end quietly
			
			
			// header info
			
			if `nvar' > 1 {
				local s s
			}
			if "`standardize'" !="" {
				disp _newline "Janson/Olsson coefficient of agreement for `nvar' z-standardized variable`s' "
			}
			else {
				disp _newline "Janson/Olsson coefficient of agreement for `nvar' variable`s' "
			}
			disp "         Number of targets =" %3.0f `ntar'
			disp "          Number of raters =" %3.0f `nrat'
			
			disp _newline
			disp "       iota = " %9.5f `iota'	
				
			//	return list
			return scalar nobs = `nobs'
			return scalar nvar = `nvar'
			return scalar nrat = `nrat'
			return scalar ntar = `ntar'
			return scalar iota = `iota'
				
end
