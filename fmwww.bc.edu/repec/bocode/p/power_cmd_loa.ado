*! 1.0.0 Ariel Linden 15May2023 

capture program drop power_cmd_loa
program power_cmd_loa, rclass

	version 11
		syntax anything, SD(numlist max=1) [, Alpha(real 0.05) Gamma(real 0.05) Power(numlist max=1) n(numlist max=1 integer) Max(numlist max=1 integer) ONESIDed ]

			local kn : list sizeof anything
			if `kn' !=2 {
				di as err "the syntax requires two values: mu and delta"
				exit
			}

			gettoken mu 0 : 0 					// mean of differences
			confirm number  `mu'                   
			gettoken delta 0 : 0, parse(" ,")	// max allowable mean difference (delta) 
			confirm number  `delta'
			
			

			if `gamma' < 0 | `gamma' > .99 { 
				di as err "gamma() must be between 0 and 0.99 inclusive"
				exit
			}
			
			if `alpha' < 0 | `alpha' > .99 { 
				di as err "alpha() must be between 0 and 0.99 inclusive"
				exit
			}
		
			if "`power'" != "" {
				if `power' < 0 | `power' > 1.0 { 
					di as err "power() must be between 0 and 1.0 inclusive"
					exit
				}
			}
			
			if "`max'" == "" {
				local max = 100000
			}
			
			// set default test type to "twosided"  
			if "`onesided'" != "" {
				local sidegamma = `gamma'
				local sidealpha = `alpha'
			}
			else {
				local sidegamma = `gamma'/ 2
				local sidealpha = `alpha' / 2
			}	
			
			tempname zgamma zalpha
			scalar `zgamma' = 1 * invnorm(1-`sidegamma')
			scalar `zalpha' = 1 * invnorm(1-`sidealpha')
			
			local uloa = `mu' + `zgamma' * `sd'
			local lloa = `mu' - `zgamma' * `sd'
			
			// assess whether delta is > LOA
			if `delta' < `uloa' {
				di as err "the max allowable mean difference (delta) must be greater than the LOA (" %5.4f `uloa' ")"
				exit
			}
	
			local N = 1
			local power2 = 0 

	
			// compute sample size
			if "`power'" != "" {
				while `power2' < `power' & `N' < `max' {
					quietly { 
						local N = `N' + 1
						local se = `sd' * sqrt((1/`N') + (`zgamma'^2)/(2*(`N' - 1)))
						local talpha = invttail(`N'-1,(`sidealpha'))
						local tau1 = (`delta' - `mu' - `zgamma' * `sd')/ `se'
						local tau2 = (`delta' + `mu' - `zgamma' * `sd')/ `se'
						local beta1 = nt(`N'- 1,`tau1',`talpha')
						local beta2 = nt(`N'- 1,`tau2',`talpha')
						local power2 = 1 - (`beta1' + `beta2')
					} // quietly
				} // end while
			} // end sample size
			
			// compute power
			if "`n'" != "" {
				while `N' < `n' {
					quietly { 
						local N = `N' + 1
						local se = `sd' * sqrt((1/`N') + (`zgamma'^2)/(2*(`N' - 1)))
						local talpha = invttail(`N'-1,(`sidealpha'))
						local tau1 = (`delta' - `mu' - `zgamma' * `sd')/ `se'
						local tau2 = (`delta' + `mu' - `zgamma' * `sd')/ `se'
						local beta1 = nt(`N'- 1,`tau1',`talpha')
						local beta2 = nt(`N'- 1,`tau2',`talpha')
						local power2 = 1 - (`beta1' + `beta2')
					} // quietly
				} // end while
			} // end power
			
			
			//  CIs on lower and upper LOA (Lu eq 1 and 2)
			local lloaUCL = `lloa' + `talpha' * `se'
			local lloaLCL = `lloa' - `talpha' * `se'
			local uloaUCL = `uloa' + `talpha' * `se'
			local uloaLCL = `uloa' - `talpha' * `se'
			
			// Get actual or specified power 
			if "`power'" != "" {
				local power = `power'
			}
			else local power = `power2'

			// return variables     
			return scalar mu = `mu'
			return scalar delta = `delta'
			return scalar sd = `sd'
			return scalar uloa = `uloa'
			return scalar lloa = `lloa'
			return scalar lloaUCL = `lloaUCL'
			return scalar lloaLCL = `lloaLCL'
			return scalar uloaUCL = `uloaUCL'
			return scalar uloaLCL = `uloaLCL'
			return scalar alpha = `alpha'
			return scalar gamma = `gamma'
			return scalar power = `power'
			return scalar N = `N'
                
end