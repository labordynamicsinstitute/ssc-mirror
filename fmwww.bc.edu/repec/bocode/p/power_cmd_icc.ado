*! 1.0.0 Ariel Linden 01Jul2023

capture program drop power_cmd_icc
program power_cmd_icc, rclass
	
version 11.0
	
	
        /* obtain settings */
		syntax anything(id="numlist"),	///
			[ Alpha(real 0.05) 		/// significance level
			n(string) 				/// total sample size
			nr(integer 2)			/// number of ratings
			Power(string)  			///
			ONESIDed				///
			]						///

			gettoken icc0 rest : anything
			gettoken icc1 rest : rest
			
			numlist "`anything'", min(2) max(2)
			
			if `icc0' < 0.0 | `icc0' > 1.0 { 
				di as err "icc0 must be a number between 0 and 1"
				exit 198
			}
			
			if `icc1' < 0.0 | `icc1' > 1.0 { 
				di as err "icc1 must be a number between 0 and 1"
				exit 198
			}
	
			// set default test type to "twosided"  
			if "`onesided'" != "" {
				local zalpha = `alpha'
			}
			else local zalpha = `alpha' / 2
			
			// compute delta for output
			tempname delta
			scalar `delta' = `icc1' - `icc0'
			
			// compute F for the two ICCs
			tempname ficc1 ficc0	
			scalar `ficc1' = (1 + (`nr'- 1) * `icc1') / (1 - `icc1')
			scalar `ficc0' = (1 + (`nr'- 1) * `icc0') / (1 - `icc0')	
			
			
			*******************************
			**** compute sample size ******
			*******************************
			if (`"`n'"' == "") {
				tempname n
				scalar `n' = ceil((1 + (2 * (invnorm(1-`zalpha') + invnorm(`power'))^2 * `nr') / ((log(`ficc1'/`ficc0'))^2 * (`nr' - 1))))
			} // end sample size
		
			
			*************************
			**** compute power ******
			*************************
			else if (`"`n'"' != "" ) {
				tempname power
				scalar `power' = normal(sqrt(((`nr' - 1) * (`n' - 1)) / (2 * `nr')) * log(`ficc1'/`ficc0') - invnorm(1 - `zalpha'))
			} // end power					

		
			// saved results
			return scalar N = `n'
			return scalar alpha = `alpha'
			return scalar power = `power'
			return scalar nr = `nr'
			return scalar icc1 = `icc1'
			return scalar icc0 = `icc0'
			return scalar delta = `delta'


		
end
