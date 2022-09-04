*! 1.0.0 Ariel Linden 02Aug2022 

program define classtab, rclass
version 11.0

        /* obtain settings */
		syntax varlist(min=2 max=2 numeric) [if] [in] , [Level(cilevel)]

			tokenize `varlist'
			local refvar `1'
			local classvar `2'
                
			marksample touse 
			qui count if `touse'
			if r(N) < 1 error 2001 

			cap assert `refvar'==0 | `refvar'==1 if `touse'
				if _rc~=0 {
				noi di in red "`refvar' must be coded as 0 or 1"
				exit
			}
                        
			cap assert `classvar'==0 | `classvar'==1 if `touse'
				if _rc~=0 {
				noi di in red "`classvar' must be coded as 0 or 1"
				exit
			}

			if `level' <= 0 | `level' >= 100 { 
				di as err "invalid confidence level"
				error 499
			}
			
			quietly {
				// true positives (A)
				count if `refvar' == 1 & `classvar' == 1 & `touse'
				local tp = r(N)
			
				// false negatives (B)
				count if `refvar' == 1 & `classvar' == 0 & `touse'
				local fn = r(N)
			
				// false positives (C)
				count if `refvar' == 0 & `classvar' == 1 & `touse'
				local fp = r(N)
			
				// true negatives (D)
				count if `refvar' == 0 & `classvar' == 0 & `touse'
				local tn = r(N)
				
			} // end quietly	
			
			classtabi `tp' `fn' `fp' `tn', level(`level')
			
			// saved values
			return scalar all = r(all)
			return scalar allub = r(allub)
			return scalar alllb = r(alllb)
			return scalar sens = r(sens)
			return scalar sensub = r(sensub)
			return scalar senslb = r(senslb)
			return scalar spec = r(spec)
			return scalar specub = r(specub)
			return scalar speclb = r(speclb)
			return scalar ppv = r(ppv)
			return scalar ppvub = r(ppvub)
			return scalar ppvlb = r(ppvlb)
			return scalar npv = r(npv)
			return scalar npvub = r(npvub)
			return scalar npvlb = r(npvlb)
			return scalar fpr = r(fpr)
			return scalar fprub = r(fprub)
			return scalar fprlb = r(fprlb)
			return scalar fnr = r(fnr)
			return scalar fnrub = r(fnrub)
			return scalar fnrlb = r(fnrlb)
			return scalar roc = r(roc)
			return scalar roclb = r(roclb)
			return scalar rocub = r(rocub)
			
			
			
			
end
			
			
			
