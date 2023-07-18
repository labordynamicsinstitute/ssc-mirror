*! 1.0.0 Ariel Linden 16Jul2023 

program define maxwell, rclass
version 11.0

        /* obtain settings */
		syntax varlist(min=2 max=2 numeric) [if] [in] , [tab]

			tokenize `varlist'
			local rater1 `1'
			local rater2 `2'
                
			marksample touse 
			qui count if `touse'
			if r(N) < 1 error 2001 

			cap assert `rater1'==0 | `rater1'==1 if `touse'
				if _rc~=0 {
				noi di in red "`rater1' must be coded as 0 or 1"
				exit
			}
                        
			cap assert `rater2'==0 | `rater2'==1 if `touse'
				if _rc~=0 {
				noi di in red "`rater2' must be coded as 0 or 1"
				exit
			}


			quietly {
				// cell A
				count if `rater1' == 1 & `rater2' == 1 & `touse'
				local A = r(N)
			
				// cell B
				count if `rater1' == 1 & `rater2' == 0 & `touse'
				local B = r(N)
			
				// cell C
				count if `rater1' == 0 & `rater2' == 1 & `touse'
				local C = r(N)
			
				// cell D
				count if `rater1' == 0 & `rater2' == 0 & `touse'
				local D = r(N)
				
			} // end quietly	
			
			maxwelli `A' `B' `C' `D', `tab'
			
			// saved values
			return scalar nrat = r(nrat)
			return scalar ntar = r(ntar)
			return scalar maxwell = r(maxwell)

end
			
			
			
