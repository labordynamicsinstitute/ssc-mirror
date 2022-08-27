*! 1.0.0 Ariel Linden 28Jul2022

capture program drop power_cmd_onespec
program power_cmd_onespec, rclass
	
version 11.0
	
	
        /* obtain settings */
		syntax anything(id="numlist"),	///
			[ Alpha(real 0.05) 		/// significance level
			n(string) 				/// total sample size
			Power(string)  			///
			PREV(real 0.5)			/// prevalence of disease
			ONESIDed				///
			]						///

			gettoken spec0 rest : anything
			gettoken spec1 rest : rest
			
			numlist "`anything'", min(2) max(2)
			
			if `spec0' < 0.0 | `spec0' > 1.0 { 
				di as err "spec0 must be a number between 0 and 1"
				exit 198
			}
			
			if `spec1' < 0.0 | `spec1' > 1.0 { 
				di as err "spec1 must be a number between 0 and 1"
				exit 198
			}
			
	
			// set default test type to "twosided"  
			if "`onesided'" != "" {
				local test = `alpha'
			}
			else local test = `alpha' / 2
			
			*******************************
			**** compute sample size ******
			*******************************
			if (`"`n'"' == "") {
				tempname delta n1 n0 n
				scalar `delta' = `spec1' - `spec0'
				scalar `n0' = ceil(((invnorm(1 - `test') * sqrt(`spec0' * (1 - `spec0')) + invnorm(`power') * sqrt(`spec1' * (1 - `spec1')))/(`spec1' - `spec0'))^2)	
				scalar `n' = ceil(`n0' / (1 - `prev')) // (method 0) Li & Fine (2004)
				scalar `n1' = ceil(`n' - `n0')
			} // end sample size
			
			*************************
			**** compute power ******
			*************************
			else if (`"`n'"' != "") {	
				tempname delta p k s n1 n0 power
				scalar `delta' = `spec1' - `spec0'
				scalar `p' = 0
				forvalues k = 0 / `n' {
					scalar `s' = sqrt(`k' * `spec0' * (1 - `spec0')) * invnorm(1 - `test') + `k' * `spec0'
					scalar `p' = `p' + (1 - binomial(`k',`s', `spec1')) * binomialp(`n',`k',(1-`prev'))
				}
				scalar `n0' = ceil(`n' * (1-`prev'))
				scalar `n1' = ceil(`n' - `n0')
				scalar `power' = `p'
			} // end power
		
			
			// saved results
			return scalar N = `n'
			return scalar N1 = `n1'
			return scalar N0 = `n0'
			return scalar alpha = `alpha'
			return scalar power = `power'
			return scalar spec1 = `spec1'
			return scalar spec0 = `spec0'
			return scalar delta = `delta'
			return scalar prev = `prev'
		
end