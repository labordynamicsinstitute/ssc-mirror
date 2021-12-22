*! 1.0.0 Ariel Linden 21August2021 

capture program drop loasampsi
program loasampsi, rclass

	version 11
		syntax anything, SD(numlist max=1) [, Level(real `c(level)') Power(numlist max=1) n(numlist max=1 integer)]

			local kn : list sizeof anything
			if `kn' !=2 {
				di as err "the syntax requires two values: mu and delta"
				exit
			}

			gettoken mu 0 : 0 					// mean of differences
			confirm number  `mu'                   
			gettoken delta 0 : 0, parse(" ,")	// delta 
			confirm number  `delta'
			
			*** test whether delta is > LOA
			local zgamma = -1 * invnorm((1 - `level' / 100) / 2)
			local loa = `mu' + `zgamma' * `sd'
			if `delta' < `loa' {
				di as err "delta must be greater than the LOA (" %5.2f `loa' ")"
				exit
			}
						
			if `level' < 10 | `level' > 99.99 { 
				di as err "level() must be between 10 and 99.99 inclusive"
				exit
			}
		
			if "`power'" != "" & "`n'" != "" {
				di as err "either power() or n() must be specified, not both"
				exit
			}
		
			if "`power'" == "" & "`n'" == "" {
				di as err "either power() or n() must be specified"
				exit
			}
			
			if "`power'" != "" {
				if `power' < 0 | `power' > 1.0 { 
					di as err "power() must be between 0 and 1.0 inclusive"
					exit
				}
			}	

			local N = 1
			local power2 = 0 

			di as txt " "
			di as txt "Performing iteration ..."
		
			// if power is specified
			if "`power'" != "" {
				while `power2' < `power' {
					quietly { 
						local N = `N' + 1
						local se = `sd' * sqrt((1/`N') + (`zgamma'^2)/(2*(`N' - 1)))
						local talpha = invttail(`N'-1,(1 - `level' / 100) / 2)
						local tau1 = (`delta' - `mu' - `zgamma' * `sd')/ `se'
						local tau2 = (`delta' + `mu' - `zgamma' * `sd')/ `se'
						local beta1 = nt(`N'- 1,`tau1',`talpha')
						local beta2 = nt(`N'- 1,`tau2',`talpha')
						local power2 = 1 - (`beta1' + `beta2')
					} // quietly
				} // end while
			} // end power

			// if n is specified
			if "`n'" != "" {
				while `N' < `n' {
					quietly { 
						local N = `N' + 1
						local se = `sd' * sqrt((1/`N') + (`zgamma'^2)/(2*(`N' - 1)))
						local talpha = invttail(`N'-1,(1 - `level' / 100) / 2)
						local tau1 = (`delta' - `mu' - `zgamma' * `sd')/ `se'
						local tau2 = (`delta' + `mu' - `zgamma' * `sd')/ `se'
						local beta1 = nt(`N'- 1,`tau1',`talpha')
						local beta2 = nt(`N'- 1,`tau2',`talpha')
						local power2 = 1 - (`beta1' + `beta2')
					} // quietly
				} // end while
			} // end n
			
			// display table header information 
			disp _newline "Study parameters:"
			di as txt " "
			di as txt "           Mean of differences = " as result `mu'
			di as txt "  Maximum allowable difference = " as result `delta'
			di as txt "        Std dev of differences = " as result `sd'
			di as txt "                      CI level = " as result `level'
			di _n
			disp as txt "Estimated sample sizes:"
			di as txt " "
			di as txt " Number of paired observations = " as result `N'
			di as txt "                  Actual power = " as result `power2'

			// return variables     
			return scalar mu = `mu'
			return scalar delta = `delta'
			return scalar sd = `sd'
			return scalar level = `level'
			return scalar power = `power2'
			return scalar n = `N'
                
end