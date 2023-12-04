*! 1.00 Ariel Linden 30Nov2023

capture program drop invnormi
program invnormi, rclass

version 11

		syntax anything(id="a value for p is"),	///
				[ 								///
				Mean(numlist max = 1) 			/// 
				Sd(numlist max = 1) 			///
                ]
				
				local varcount : word count `anything'
				if (`varcount' > 1) {
					di as err "too many values specified"
					exit = 103
				}

				if `anything' <= 0 | `anything' >= 1 { 
					di as err "p must be greater than 0 and less than 1"
					error 198
				}
			
				tokenize `anything'
				confirm number  `anything'				
				
				if "`mean'" == "" {
					local mean = 0
				}
				
				if "`sd'" == "" {
					local sd = 1
				}
				
				local invnorm = `mean' + invnormal(`anything') * `sd'
				di `invnorm'
				
				// saved results
				return scalar invnorm = `invnorm'
				
end