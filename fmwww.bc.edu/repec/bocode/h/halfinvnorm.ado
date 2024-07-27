*! 1.00 Ariel Linden 11/07/2024

program halfinvnorm, rclass

version 11

		syntax newvarname [if][in] , 	///
                p(varname numeric)		/// p is required                
				[ 						///
				Mean(varname numeric) 	/// 				
				Sd(varname numeric) 	///
				THeta(varname numeric) 	///
                ]
				
				marksample touse, novarlist 
				
				if "`theta'" !="" & "`sd'" !="" {    
					di as err "{bf:theta} and {bf:sd} cannot both be specified"
					exit 198
				}
				
				if "`mean'" == "" {
					tempvar mean
					qui gen `mean' = 0 if `touse'
				}
				
				if "`theta'" == "" {
					tempvar theta
					qui gen `theta' = sqrt(_pi/2) if `touse'
				}
				else qui replace `theta' = (sqrt(_pi/2)/`theta') if `touse'				
				
				if "`sd'" == "" {
					tempvar sd
					qui gen `sd' = sqrt(_pi/2)/`theta' if `touse' 
				}
				
				qui gen `varlist' = cond(`p' < 0, ., (`mean' + invnormal((`p'+ 1)/2) * `sd')) if `touse'				
				
end
