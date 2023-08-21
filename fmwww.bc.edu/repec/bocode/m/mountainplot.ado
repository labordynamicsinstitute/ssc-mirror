*! 1.0.0 Ariel Linden 17Aug2023 

capture program drop mountainplot
program mountainplot, rclass

		version 11
		syntax varlist(min=1 numeric) [if] [in] [, STandardize * ]
		
			quietly {
				preserve
				tokenize `varlist'
				local nvars : word count `varlist'

				marksample touse
				count if `touse'
				if r(N) == 0 error 2000
				keep if `touse' 
				keep `varlist'

				// standardize variables
				if "`standardize'" != "" {
					foreach var of local varlist {
						sum `var'
						local mean = r(mean)
						local sd = r(sd)
						replace `var' = (`var' - `mean') / `sd'
					}
				local note "standardized variables"
				}
				
				// generate mountainplot data for each variable
				tempvar pcnt
				local i = 1
				foreach var of local varlist {
					sort `var'
					egen `pcnt'`i' = rank( `var')
					label var `pcnt'`i' "`var'"
					replace `pcnt'`i'  = 100 * (`pcnt'`i' / (`pcnt'`i'[_N]+1))
					replace `pcnt'`i' = cond(`pcnt'`i' <= 50, `pcnt'`i', 100 - `pcnt'`i')					
					
					local gx`i' "(connected `pcnt'`i' `var', sort)"
					local g `g' `gx`i''					
					local i = `i' + 1
				} // end foreach
				
				// graph it!
				twoway `g' , ytitle("Percentile") note(`"`note'"') `options'
				
			} // end quietly	
				
end				