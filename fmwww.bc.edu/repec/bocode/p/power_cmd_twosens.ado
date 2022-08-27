*! 1.0.0 Ariel Linden 28Jul2022

capture program drop power_cmd_twosens
program power_cmd_twosens, rclass
	
version 11.0
	
	
        /* obtain settings */
		syntax anything(id="numlist"),	///
			[ Alpha(real 0.05) 		/// significance level
			n(string) 				/// total sample size
			FRACtion(real 0.5)		/// fraction of total sample assigned to test 1
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
			
			if `fraction' < 0.0 | `fraction' > .999 { 
				di as err "fraction must be a number greater than 0 and less than 1"
				exit 198
			}
	
			// set default test type to "twosided"  
			if "`onesided'" != "" {
				local test = `alpha'
			}
			else local test = `alpha'/ 2
			
			tempname fract1 fract2
			scalar `fract1' = `fraction' // the fraction of subjects that will be assigned to group 1 
			scalar `fract2' = 1 - `fract1' // the fraction of subjects assigned to group 2

			*******************************
			**** compute sample size ******
			*******************************
			if (`"`n'"' == "") {
				
				tempname delta n1 n0 n
				scalar `delta' = `sens2' - `sens1'
				scalar `n1' = ceil(((invnorm(1-`test')*sqrt((`sens1'*`fract1'+`fract2'*`sens2')*(1-`sens1'*`fract1'-`sens2'*`fract2')*(1/`fract1'+1/`fract2')) ///
					+invnorm(`power')*sqrt(`sens2'*(1-`sens2') /`fract2'+`sens1'*(1-`sens1')/`fract1')) / (`sens2'-`sens1'))^2)
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
				
				tempname delta n1 n0 power
				scalar `delta' = `sens2' - `sens1'
				
				local nlast = 0
				while `nlast' <= `n'  & `init' <= 10000 {	
					scalar `n1' = ceil(((invnorm(1-`test')*sqrt((`sens1'*`fract1'+`fract2'*`sens2')*(1-`sens1'*`fract1'-`sens2'*`fract2')*(1/`fract1'+1/`fract2')) ///
						+invnorm(`init'/10000)*sqrt(`sens2'*(1-`sens2') /`fract2'+`sens1'*(1-`sens1')/`fract1')) / (`sens2'-`sens1'))^2)
					local nlast = ceil(`n1' / `prev') // (method 0) Li & Fine (2004)
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
			return scalar fraction = `fract1'
			return scalar init = `init'
		
end
