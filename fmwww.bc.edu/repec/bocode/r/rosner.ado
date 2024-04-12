*! version 1.0.0 Ariel Linden 06apr2024

capture program drop rosner
program define rosner, rclass byable(recall)
		version 11.0
		syntax varlist(numeric min=1 max=1) [if] [in] , [ K(integer 1) Alpha(real 0.05) ]
		
		quietly {
			preserve
			marksample touse
			keep if `touse'
			
			local x "`varlist'"
			

			// alpha
			if `alpha' <= 0 | `alpha' >= 100 { 
				di as err "{bf:'alpha'} must be > 0 and < 100"
				error 499
			}

			// get sample size
			sum `x', meanonly
			local n = r(N)
			
			// tempvars and tempnames
			tempvar new`x' z`i'
			tempname mean`i' sd`i' zmax`i' val`i' p t lambda`i'

			// generate copy of x in order to preserve the original
			clonevar `new`x'' = `x'
			// loop for each k
			forvalues i = 1/`k' {
				sum `new`x''
				scalar `mean'`i' = r(mean)
				scalar `sd'`i' = r(sd)	
				gen `z'`i' = abs(`new`x'' - `mean'`i') / `sd'`i'
				sum `z'`i', meanonly
				scalar `zmax'`i' = r(max)
				gsort -`z'`i'
				scalar `val'`i' = `new`x''[1]
				replace `new`x'' = . in 1
				
				// compute lambda
				local l = `i' - 1
				scalar `p' = 1 - ((`alpha'/2) / (`n' - `l'))
				scalar `t' = invt(`n' - `l' - 2, `p')
				scalar `lambda'`i' = `t' * (`n' - `l' - 1) / sqrt((`n' - `l' - 2 + `t'^2) * (`n' - `l'))

				// determine if each k is an outlier
				local outlier`i' = cond(`zmax'`i' > `lambda'`i', 1 , 0)

				// accumulate outlier values in a macro
				local outtest "`outtest' `outlier`i''"
			} // end forvalues loop

			// find 1s amongst outliers and change all values
			// up to that point to 1s as well
			local hit = strrpos("`outtest'", "1") / 2
			if `hit' > 0 {			
				forvalues i = 1/`k' {
					if `i' <= `hit' {
						local outlier`i' = 1
					}	
				}
			}	
		
		} // end quietly			

		// check number of characters in alpha in order to display alpha nicely
		local levlen = strlen(string(`alpha'))
		if `levlen' > 3 {
			local fmt %4.3f 
		}
		else local fmt %3.2f
		
		di _newline
		di as text "{p}{bf:Rosner's generalized ESD test for outliers}{p_end}"
		di as text _newline %40s "Number of observations: " %-6.0fc `n'

		di _newline
		if `levlen' > 3 {
			local len = strlen("`x'") + 45
		}
		else local len = strlen("`x'") + 44
		
		di as text "{p}Suspected outlier values in {bf:`x'} (alpha = " `fmt' `alpha' "):{p_end}"
		di in smcl in gr "{hline `len'}"	
		
		// display "none detected" if there are no outliers
		if "`hit'" == "0" {
			di "none detected"
		exit
		}
		
		// display outliers 		
		local format : format `x'
		forvalues i = 1/`k' {
			if `outlier`i'' == 1 {
				di as text "" `format' `val'`i'
			}
		}
		
end		