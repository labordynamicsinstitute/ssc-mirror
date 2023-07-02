*! 1.0.0 Ariel Linden 19Jun2023 

capture program drop finn
program finn, rclass byable(recall)

        version 11
        syntax varlist(min=2 numeric) [if] [in] , [ Id(varlist min=1 max=1 numeric) CATegories(numlist min=1 max=1 integer) ]

			quietly {
				preserve
				tokenize `varlist'
				local varcount : word count `varlist'

				marksample touse
				count if `touse'
				if r(N) == 0 error 2000
				keep if `touse' 
                keep `varlist' `id'
                local n = r(N) 
				
				// get counts for output display
				if "`id'" !="" {
					tab `id'
					local n1 = r(r)
				}


				// rename variables
				local i = 1
				tempvar r
				foreach x of local varlist {
					clonevar `r'`i' = `x'
					local i = `i' + 1
				}
				
				// compute expected mean subject variance (eMSV)  
				// reshape to long
				tempvar idm runiq
				gen `idm' = _n
				reshape long `r', i(`idm')
			
				if "`categories'" == "" {
					tempvar evar
					levelsof `r',  local(rlevs)
					local rcnt : word count `rlevs'
									
					gen `runiq' = ""
					forval x = 1 / `rcnt' {
						replace `runiq' = " `:word `x' of `rlevs'' " in `x'
					}
					
					destring `runiq', replace
					sum `runiq', meanonly
					
					// get variances
					gen `evar' = (`runiq' - r(mean))^2
					sum `evar'
					local eMSV = r(mean)
				}
				else {
					local eMSV = ((`categories'-1)*(`categories'+1))/12
				}

			
				// compute mean subject variance (MSV)
				tempvar r_sd avar
				if "`id'" !="" {
					collapse (sd) `r_sd' = `r', by( `id' )
				}
				else {
					collapse (sd) `r_sd' = `r', by( `idm' )
				}
				gen `avar' = `r_sd'^2
				sum `avar', meanonly
				local MSV = r(mean)
				
				// compute Finn's coefficient
				local finn = 1-(`MSV'/`eMSV')
					
			} // end quietly	
			// header info
			if "`id'" == "" {
				disp _newline "Finn's coefficient for independent observations"
				disp "         Number of raters = " %4.0f `varcount'
				disp "            Number of obs = " %4.0f `n'
			}
			else {
				disp _newline "Finn's coefficient for repeated measures"
				disp "         Number of raters = " %4.0f `varcount'
				disp "       Number of subjects = " %4.0f `n1'
				disp "            Number of obs = " %4.0f `n'
			}
				
				disp _newline
				disp "       Finn's coefficient = " %9.5f `finn'
			
			
			restore	
			
			
			// return list
			return scalar MSV = `MSV'
			return scalar eMSV = `eMSV'
			return scalar finn = `finn'

				
end
