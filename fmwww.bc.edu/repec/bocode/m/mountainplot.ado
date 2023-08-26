*! 1.0.0 Ariel Linden 17Aug2023 

capture program drop mountainplot
program mountainplot, rclass

		version 11
		syntax varlist(min=1 numeric) [if] [in] [, DIFFerence STandardize * ]
		
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
				
				// generate mountainplot data if "difference" option is specified
				if "`difference'" != "" {
					tempvar diff pcnt					
					local i = 1
					forvalues v = 2/`nvars' {
						gen `diff'`i' = `:word 1 of `varlist'' - `:word `v' of `varlist'' 
						sort `diff'`i'
						egen `pcnt'`i' = rank( `diff'`i')
						label var `pcnt'`i' "`:word `v' of `varlist''"
						replace `pcnt'`i'  = 100 * (`pcnt'`i' / (`pcnt'`i'[_N]+1))
						replace `pcnt'`i' = cond(`pcnt'`i' <= 50, `pcnt'`i', 100 - `pcnt'`i')							
						
						local gx`i' "(connected `pcnt'`i' `diff'`i', sort)"
						local g `g' `gx`i''					
						local i = `i' + 1
					} // end forval

					if `nvars' < 3 {
						local xtit "`:word 1 of `varlist'' - `:word 2 of `varlist''"
					}
					else local xtit "Difference with `:word 1 of `varlist''"
					
					twoway `g' , ytitle("Percentile") xtitle(`xtit')note(`"`note'"') `options'

				}	// end if difference is specified
					
				else {
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
					
					twoway `g' , ytitle("Percentile") note(`"`note'"') `options'
				
				} // end else				
				
			} // end quietly	
				
end				