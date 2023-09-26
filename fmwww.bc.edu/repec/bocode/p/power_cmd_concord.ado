*! 1.0.0 Ariel Linden 22Sep2023 


capture program drop power_cmd_concord
program define power_cmd_concord, rclass
version 12.0


			/* obtain settings */
			syntax anything(id="numlist"),	///
				[ Alpha(real 0.05)        	/// significance level
				n(string)					/// total sample size
				Power(string)				///
				ONESIDed					///
				]

				numlist "`anything'", min(2) max(2)
				
				gettoken concord0 rest : anything
				gettoken concord1 rest : rest
				
				if `concord0' < 0 | `concord0' > 1 {
					noi di in red "concord0 must be a number between 0 and 1"
					exit 198
				} 
				if `concord1' < 0 | `concord1' > 1 {
					noi di in red "concord1 must be a number between 0 and 1"
					exit 198
				} 
				
				if `concord0' == `concord1' {
					noi di in red "concord0 must be different than concord1"
					exit 198					
				}
				if `alpha' < 0 | `alpha' > 1 {
					di as err "option {bf:alpha()} must contain numbers between 0 and 1"
					exit 121
				}
				

				*******************
				// Sample size  //
				*******************
				if ("`n'" == "") {
					
					if `power' < 0 | `power' > 1 {
						di as err "option {bf:power()} must contain numbers between 0 and 1"
						exit 121
					} 
					tempname zalpha zbeta delta n z0 z1
				
					// set default test type to "twosided"  
					if "`onesided'" == "" {
						local test = `alpha'/ 2
					}
					else local test = `alpha'

					scalar `zalpha' = invnorm(1-`test')
					scalar `zbeta' = invnorm(`power')
					scalar `delta' = abs(`concord0' - `concord1')
					
					scalar `z0' = log((1 + `concord0') / (1 - `concord0')) / 2
					scalar `z1' = log((1 + `concord1') / (1 - `concord1')) / 2					

 					scalar `n' =  ceil((((`zalpha' + `zbeta') / (`z1' - `z0'))^2)+2) 
				
				} // end sample size

				
				*******************
				// Power  //
				*******************				
				else if ("`n'" !="") {	
					
					tempname zalpha delta power z0 z1
				
					// set default test type to "twosided"  
					if "`onesided'" == "" {
						local test = `alpha'/ 2
					}
					else local test = `alpha'

					scalar `zalpha' = invnorm(1-`test')
					scalar `delta' = abs(`concord0' - `concord1')
					scalar `z0' = log((1 + `concord0') / (1 - `concord0')) / 2
					scalar `z1' = log((1 + `concord1') / (1 - `concord1')) / 2	

					scalar `power' = normal(((`z1' - `z0') * sqrt(`n' - 2) - (`zalpha')))
							
				} // end power
			
				// saved results
				return scalar N = `n'
				return scalar alpha = `alpha'
				return scalar power = `power'
				return scalar concord0 = `concord0'
				return scalar concord1 = `concord1'
				return scalar delta = `delta'



end				
                        

