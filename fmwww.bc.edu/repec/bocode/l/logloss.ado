*! 1.0.0 Ariel Linden 19jan2025


program define logloss, rclass byable(recall) sort
		version 11, missing
		syntax varlist(min=2 max=2) [if] [in]
		tokenize `varlist'
        local dvar `1'
        local pred `2'

        marksample touse 
        quietly count if `touse' 
        if r(N) < 2 error 2001

		quietly {
			capture assert `dvar'==0 | `dvar'==1 if `touse'
			if _rc {
				di in red "first variable must be 0/1"
				exit 198
			}
			capture assert `pred'>=0 & `pred'<=1 if `touse'
			if _rc {
				di in red "second variable must be a probability"
				exit 198
			}			
			
			tempvar ll			
			sort `touse' `pred'
			gen `ll' = (log(1 - abs(`dvar' - `pred')) * - 1) if `touse'				
			sum `ll', meanonly
			local logloss = r(mean)

			// return result
			ret scalar logloss = `logloss'
				
		} // end quietly				
		
		di		
		di in gr "    Log loss score" _col(30) in ye %7.4f `logloss'		

				
end