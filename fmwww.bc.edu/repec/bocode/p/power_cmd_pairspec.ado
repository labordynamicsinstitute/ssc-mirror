*! 1.0.0 Ariel Linden 05Aug2022

capture program drop power_cmd_pairspec
program power_cmd_pairspec, rclass
	
version 11.0
	
	
        /* obtain settings */
		syntax anything(id="numlist"),	///
			[ Alpha(real 0.05) 		/// significance level
			n(string) 				/// total sample size
			Power(string)  			///
			PREV(real 0.5)			/// prevalence of disease
			ONESIDed				///
			init(real 10)			/// initial value for estimating power			
			]						///

			gettoken spec1 rest : anything
			gettoken spec2 rest : rest
			
			numlist "`anything'", min(2) max(2)
			
			if `spec1' < 0.0 | `spec1' > 1.0 { 
				di as err "spec1 must be a number between 0 and 1"
				exit 198
			}
			
			if `spec2' < 0.0 | `spec2' > 1.0 { 
				di as err "spec2 must be a number between 0 and 1"
				exit 198
			}
			
			if `init' < 0 {
				di as err "init() must be a positive number"
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
				tempname eta delta D n1 n0 n
				
				scalar `eta' = (1-`spec1') * `spec2' + (1-`spec2') * `spec1'
				scalar `delta' = `spec2' - `spec1'
				scalar `D' = (1-`spec1') * `spec2' - (1-`spec2') * `spec1'
				scalar `n0' = ceil(((invnorm(1-`test') * `eta' + invnorm(`power') * ((`eta'^2-`D'^2*(3+`eta')/4)^0.5)))^2 / (`eta' * `D'^2))
				scalar `n' = ceil(`n0' / (1 - `prev')) // (method 0) Li & Fine (2004)
				scalar `n1' = ceil(`n' - `n0')

			} // end sample size
			
/*
			*************************
			**** compute power ******
			*************************
			else if (`"`n'"' != "") {	
				tempname delta p k s n1 n0 power
				scalar `delta' = `spec1' - `spec0'
				scalar `p' = 0
				forvalues k = 0 / `n' {
					scalar `s' = sqrt(`k' * `spec0' * (1 - `spec0')) * invnorm(1 - `test') + `k' * `spec0'
					scalar `p' = `p' + (1 - binomial(`k',`s', `spec1')) * binomialp(`n',`k',`prev')
				}
				scalar `n1' = ceil(`n' * `prev')
				scalar `n0' = ceil(`n' - `n1')
				scalar `power' = `p'
			} // end power
*/		
			
			else if (`"`n'"' != "") {
				
				tempname eta delta D n1 n0 power
				scalar `delta' = `spec2' - `spec1'
				scalar `eta' = (1-`spec1') * `spec2' + (1-`spec2') * `spec1'
				scalar `D' = (1-`spec1') * `spec2' - (1-`spec2') * `spec1'
				
				local nlast = 0
				while `nlast' <= `n'  & `init' <= 10000 {	
					scalar `n0' = ceil(((invnorm(1-`test') * `eta' + invnorm(`init'/10000)*((`eta'^2-`D'^2*(3+`eta')/4)^0.5)))^2 / (`eta' * `D'^2))
					local nlast = ceil(`n0' / (1-`prev')) // (method 0) divide n1 by prevalence
					local plast `init'
					local ++init
				}  // end while
				
				scalar `n1' = ceil(`n' - `n0')
				scalar `power' = `plast' / 10000
			
			} // end power	
			
			// saved results
			return scalar N = `n'
			return scalar N1 = `n1'
			return scalar N0 = `n0'
			return scalar alpha = `alpha'
			return scalar power = `power'
			return scalar spec1 = `spec1'
			return scalar spec2 = `spec2'
			return scalar delta = `delta'
			return scalar prev = `prev'
			return scalar init = `init'
		
end
