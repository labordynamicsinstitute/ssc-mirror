*! 1.0.0 Ariel Linden 01Nov2021 

capture program drop rmclass
program rmclass, rclass byable(recall)

		version 11
		syntax varlist(min=2 max=2 numeric)	 	///
			[if] [in] 							///
			[, Id(varlist min=1 max=1 numeric) 	///
			Level(real `c(level)') 				///
			GEE									///
			* 									///
			] 								
								
											

		quietly {
			marksample touse
			tokenize `varlist'
			local refvar = `"`1'"'
			local classvar = `"`2'"'
		
			cap assert `refvar'==0 | `refvar'==1 if `touse'
			if _rc~=0 {
				noi di in red "true status variable `refvar' must be 0 or 1"
				exit
			}
			
			cap assert `classvar'==0 | `classvar'==1 if `touse'
			if _rc~=0 {
				noi di in red "classification variable `classvar' must be 0 or 1"
				exit
			}

			if "`gee'" != "" & "`id'" == "" {
				noi di in red "id() must be specified with gee"
				exit
			} 
		
			// collect cell values for classification
			count if `refvar' != 0 & `classvar' == 1 & `touse'
			local a = r(N)
	
			count if `refvar' == 0 & `classvar' == 1 & `touse'
			local b = r(N)
	
			count if `refvar' != 0 & `classvar' == 0 & `touse'
			local c = r(N)
                
			count if `refvar' == 0 & `classvar' == 0 & `touse'
			local d = r(N)


			// gen inverses of refvar and classvar 
			tempvar inv_refvar inv_classvar 
			recode `refvar' (1=0)(0=1), gen(`inv_refvar')
			recode `classvar' (1=0)(0=1), gen(`inv_classvar')
				
			if "`id'" != "" {
				local cluster vce(cluster `id')
				local margvce vce(unconditional)
			}
		
			*******************
			****** logit ******
			*******************
			if "`gee'" == "" {
				* sensitivity
				logit `classvar' if `refvar'== 1 & `touse', level(`level') `cluster' `options'
				margins, level(`level') `margvce'
				mat A = r(table)
				tempvar sens sensll sensul
				scalar `sens' = A[1,1] *100
				scalar `sensll' = A[5,1] * 100
				scalar `sensul' = A[6,1] * 100
			
				* specificity
				logit `inv_classvar' if `refvar'== 0 & `touse', level(`level') `cluster' `options'
				margins, level(`level') `margvce'
				mat B = r(table)
				tempvar spec specll specul
				scalar `spec' = B[1,1] *100
				scalar `specll' = B[5,1] * 100
				scalar `specul' = B[6,1] * 100
			
				* positive predictive value
				logit `refvar' if `classvar'== 1 & `touse', level(`level') `cluster' `options'
				margins, level(`level') `margvce'
				mat C = r(table) 
				tempvar ppv ppvll ppvul
				scalar `ppv' = C[1,1] *100
				scalar `ppvll' = C[5,1] * 100
				scalar `ppvul' = C[6,1] * 100
			
				* negative predictive value
				logit `inv_refvar' if `classvar'== 0 & `touse', level(`level') `cluster' `options'
				margins, level(`level') `margvce'
				mat D = r(table)
				tempvar npv npvll npvul
				scalar `npv' = D[1,1] *100
				scalar `npvll' = D[5,1] * 100
				scalar `npvul' = D[6,1] * 100
			
				* false positive rate
				logit `classvar' if `inv_refvar'== 1 & `touse', level(`level') `cluster' `options'
				margins, level(`level') `margvce'
				mat E = r(table)
				tempvar fpr fprll fprul
				scalar `fpr' = E[1,1] *100
				scalar `fprll' = E[5,1] * 100
				scalar `fprul' = E[6,1] * 100
			
				* false negative rate
				logit `inv_classvar' if `refvar'== 1 & `touse', level(`level') `cluster' `options'
				margins, level(`level') `margvce'
				mat E = r(table)
				tempvar fnr fnrll fnrul
				scalar `fnr' = E[1,1] *100
				scalar `fnrll' = E[5,1] * 100
				scalar `fnrul' = E[6,1] * 100
			
			} // end logit
		
			*******************
			****** gee ******
			*******************
			if "`gee'" != ""  {
				
				* sensitivity
				xtgee `classvar' if `refvar'== 1 & `touse', family(binomial) link(logit) i(`id') vce(robust) level(`level') `options'
				margins, level(`level')
				mat A = r(table)
				tempvar sens sensll sensul
				scalar `sens' = A[1,1] *100
				scalar `sensll' = A[5,1] * 100
				scalar `sensul' = A[6,1] * 100
			
				* specificity
				xtgee `inv_classvar' if `refvar'== 0 & `touse', family(binomial) link(logit) i(`id') vce(robust) level(`level') `options'
				margins, level(`level')
				mat B = r(table)
				tempvar spec specll specul
				scalar `spec' = B[1,1] *100
				scalar `specll' = B[5,1] * 100
				scalar `specul' = B[6,1] * 100
			
				* positive predictive value
				xtgee `refvar' if `classvar'== 1 & `touse', family(binomial) link(logit) i(`id') vce(robust) level(`level') `options'
				margins, level(`level')
				mat C = r(table) 
				tempvar ppv ppvll ppvul
				scalar `ppv' = C[1,1] *100
				scalar `ppvll' = C[5,1] * 100
				scalar `ppvul' = C[6,1] * 100
			
				* negative predictive value
				xtgee `inv_refvar' if `classvar'== 0 & `touse', family(binomial) link(logit) i(`id') vce(robust) level(`level') `options'
				margins, level(`level')
				mat D = r(table)
				tempvar npv npvll npvul
				scalar `npv' = D[1,1] *100
				scalar `npvll' = D[5,1] * 100
				scalar `npvul' = D[6,1] * 100
			
				* false positive rate
				xtgee `classvar' if `inv_refvar'== 1 & `touse', family(binomial) link(logit) i(`id') vce(robust) level(`level') `options'
				margins, level(`level')
				mat E = r(table)
				tempvar fpr fprll fprul
				scalar `fpr' = E[1,1] *100
				scalar `fprll' = E[5,1] * 100
				scalar `fprul' = E[6,1] * 100
			
				* false negative rate
				xtgee `inv_classvar' if `refvar'== 1 & `touse', family(binomial) link(logit) i(`id') vce(robust) level(`level') `options'
				margins, level(`level') 
				mat E = r(table)
				tempvar fnr fnrll fnrul
				scalar `fnr' = E[1,1] *100
				scalar `fnrll' = E[5,1] * 100
				scalar `fnrul' = E[6,1] * 100
			
			} // end gee
		
			// save in r()
			ret scalar sens = `sens' 	/* sensitivity               */
			ret scalar spec = `spec'	/* specificity               */
			ret scalar ppv = `ppv'		/* positive predictive value */
			ret scalar npv = `npv'		/* negative predictive value */
			ret scalar fpr = `fpr'		/* false positive		       */
			ret scalar fnr = `fnr'		/* false negative            */

			if "`gee'" != "" {
				local model `"General estimating equation model for `refvar'"'
			}
			else if "`gee'" == "" & "`id'" != "" {
				local model `"Logit model for `refvar' with clustering on `id' "'
			}
			else {
				local model `"Logit model for `refvar' assuming independent observations "'
			}
			
		} // end quietly

		// output tables
		#delimit ;
		di _n in smcl in gr _col(14) "{hline 8}   Actual {hline 7}" _n
                    `"Classified {c |}"' _col(22) `"+"' _col(35) 
                    `"-   {c |}"' _col(46) `"Total"' ;
		di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
		di    in smcl in gr _col(6) "+" _col(12) `"{c |} "'
              in ye %9.0g `a' _col(28) %9.0g `b'
              in gr `"  {c |}  "'
              in ye %9.0g `a'+`b' ;
		di    in smcl in gr _col(6) "-" _col(12) "{c |} "
              in ye %9.0g `c' _col(28) %9.0g `d'
              in gr `"  {c |}  "'
              in ye %9.0g `c'+`d' ;
		di    in smcl in gr "{hline 11}{c +}{hline 26}{c +}{hline 11}"  ;
		di    in smcl in gr `"   Total   {c |} "'
              in ye %9.0g `a'+`c' _col(28) %9.0g `b'+`d'
              in gr `"  {c |}  "'
              in ye %9.0g `a'+`b'+`c'+`d' _n ;
		di _n in gr "`model'" _n ;
		di    in gr _col(42) `"Estimate"'
		 	  in gr	_col(52) `"[`level'% Conf. Interval]"' ;
		di    in smcl in gr "{hline 72}" ;
		di    in gr `"Sensitivity"' _col(33) `"A/(A+C)"'
              in ye %8.2f return(sens) `"%"'
			  in ye _col(51) %8.2f `sensll' `"%"'
			  in ye _col(61) %8.2f `sensul' `"%"' _n
              in gr `"Specificity"' _col(33) `"D/(B+D)"'
              in ye %8.2f return(spec) `"%"'
			  in ye _col(51) %8.2f `specll' `"%"'
			  in ye _col(61) %8.2f `specul' `"%"' _n
              in gr `"Positive predictive value"' _col(33) `"A/(A+B)"'
              in ye %8.2f return(ppv) `"%"' 
			  in ye _col(51) %8.2f `ppvll' `"%"'
			  in ye _col(61) %8.2f `ppvul' `"%"' _n
              in gr `"Negative predictive value"' _col(33) `"D/(C+D)"'
              in ye %8.2f return(npv) `"%"'
			  in ye _col(51) %8.2f `npvll' `"%"'
			  in ye _col(61) %8.2f `npvul' `"%"' ;
		di    in smcl in gr "{hline 72}"  ;
		di    in gr `"False positive rate"' _col(33) `"B/(B+D)"'
              in ye %8.2f return(fpr) `"%"' 
			  in ye _col(51) %8.2f `fprll' `"%"'
			  in ye _col(61) %8.2f `fprul' `"%"' _n
              in gr `"False negative rate"' _col(33) `"C/(A+C)"'
              in ye %8.2f return(fnr) `"%"'
			  in ye _col(51) %8.2f `fnrll' `"%"'
			  in ye _col(61) %8.2f `fnrul' `"%"' ;
		di    in smcl in gr "{hline 72}"  ;

		#delimit cr		
end 

