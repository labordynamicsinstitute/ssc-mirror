*! 1.00 Ariel Linden 30Nov2023

capture program drop invnorm
program invnorm, rclass

version 11

		syntax newvarname [if][in] , 	///
                p(varname numeric)		/// p is required                
				[ 						///
				Mean(varname numeric) 	/// 
				Sd(varname numeric) 	///
                ]
				
				tempvar touse
				qui gen byte `touse'= 1 `if' `in'
				
				if "`mean'" == "" {
					tempvar mean
					gen `mean' = 0 if `touse'
				}
				
				if "`sd'" == "" {
					tempvar sd
					gen `sd' = 1 if `touse'
				}

				qui gen `varlist' = `mean' + invnormal(`p') * `sd' if `touse' == 1
				
end