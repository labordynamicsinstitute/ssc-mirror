*! 1.00 Ariel Linden 30Nov2023

capture program drop normi
program normi, rclass

version 11

		syntax anything(id="a value for z is"),	///
				[ 								///
				Mean(numlist max = 1) 			/// 
				Sd(numlist max = 1) 			///
                ]
				
				local varcount : word count `anything'
				if (`varcount' > 1) {
					di as err "too many values specified"
					exit = 103
				}

				tokenize `anything'
				confirm number  `anything'				
				
				if "`mean'" == "" {
					local mean = 0
				}
				
				if "`sd'" == "" {
					local sd = 1
				}
				
				local norm = normal((`anything'- (`mean'))/`sd')
				di `norm'
				
				// saved results
				return scalar norm = `norm'
				
end