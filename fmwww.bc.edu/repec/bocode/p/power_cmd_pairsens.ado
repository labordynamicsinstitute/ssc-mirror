*! 1.0.0 Ariel Linden 05Aug2022

capture program drop power_cmd_pairsens
program power_cmd_pairsens, rclass
	
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

			gettoken sens1 rest : anything
			gettoken sens2 rest : rest
			
			numlist "`anything'", min(2) max(2)
			
			if `sens1' < 0.0 | `sens1' > 1.0 { 
				di as err "sens1 must be a number between 0 and 1"
				exit 198
			}
			
			if `sens2' < 0.0 | `sens2' > 1.0 { 
				di as err "sens2 must be a number between 0 and 1"
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
				scalar `eta' = (1-`sens1') * `sens2' + (1-`sens2') * `sens1'
				scalar `delta' = `sens2' - `sens1'
				scalar `D' = (1-`sens1') * `sens2' - (1-`sens2') * `sens1'
				scalar `n1' = ceil(((invnorm(1-`test') * `eta' + invnorm(`power')*((`eta'^2-`D'^2*(3+`eta')/4)^0.5)))^2 / (`eta' * `D'^2))
				scalar `n' = ceil(`n1' / `prev') // (method 0) Li & Fine (2004)
				scalar `n0' = ceil(`n' - `n1')
				
			} // end sample size
			
/*
			*************************
			**** compute power ******
			*************************
			else if (`"`n'"' != "") {	
				tempname delta p k s n1 n0 power
				scalar `delta' = `sens1' - `sens0'
				scalar `p' = 0
				forvalues k = 0 / `n' {
					scalar `s' = sqrt(`k' * `sens0' * (1 - `sens0')) * invnorm(1 - `test') + `k' * `sens0'
					scalar `p' = `p' + (1 - binomial(`k',`s', `sens1')) * binomialp(`n',`k',`prev')
				}
				scalar `n1' = ceil(`n' * `prev')
				scalar `n0' = ceil(`n' - `n1')
				scalar `power' = `p'
			} // end power
*/		

			else if (`"`n'"' != "") {
				
				tempname eta delta D n1 n0 power
				scalar `delta' = `sens2' - `sens1'
				scalar `eta' = (1-`sens1') * `sens2' + (1-`sens2') * `sens1'
				scalar `D' = (1-`sens1') * `sens2' - (1-`sens2') * `sens1'
				
				local nlast = 0
				while `nlast' <= `n'  & `init' <= 10000 {	
					scalar `n1' = ceil(((invnorm(1-`test') * `eta' + invnorm(`init'/10000)*((`eta'^2-`D'^2*(3+`eta')/4)^0.5)))^2 / (`eta' * `D'^2))
					local nlast = ceil(`n1' / `prev') // (method 0) divide n1 by prevalence
					local plast `init'
					local ++init
				}  // end while
				
				scalar `n0' = ceil(`n' - `n1')
				scalar `power' = `plast' / 10000
			
			} // end power	
		
			// saved results
			return scalar N = `n'
			return scalar N1 = `n1'
			return scalar N0 = `n0'
			return scalar alpha = `alpha'
			return scalar power = `power'
			return scalar sens1 = `sens1'
			return scalar sens2 = `sens2'
			return scalar delta = `delta'
			return scalar prev = `prev'
			return scalar init = `init'
		
end
