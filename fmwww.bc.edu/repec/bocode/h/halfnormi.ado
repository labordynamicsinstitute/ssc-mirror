*! 1.00 Ariel Linden 11/07/2024

program halfnormi, rclass

version 11

		syntax anything(id="a value for z is"),	///
				[ 								///
				Mean(numlist max = 1) 			/// 
				Sd(numlist max = 1) 			///
				THeta(numlist max = 1) 			///				
                ]
				
				local varcount : word count `anything'
				if (`varcount' > 1) {
					di as err "too many values specified"
					exit = 103
				}

				tokenize `anything'
				confirm number  `anything'	
			
				if "`theta'" !="" & "`sd'" !="" {    
					di as err "{bf:theta} and {bf:sd} cannot both be specified"
					exit 198
				}
				
				if "`mean'" == "" {
					local mean = 0
				}
				
				if "`theta'" == "" {
					local theta = sqrt(_pi/2)
				}
				else local theta = (sqrt(_pi/2)/`theta')

				if "`sd'" == "" {
					local sd  = (sqrt(_pi/2)/`theta')
				}
				
				local halfnorm = cond(`anything' < 0, 0, 2 * normal((`anything'- (`mean'))/`sd')-1)					
				di `halfnorm'
				
				// saved results
				return scalar halfnorm = `halfnorm'
				
end