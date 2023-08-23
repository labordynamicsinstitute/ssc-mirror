*! 1.0.0 Ariel Linden 21Aug2023 

capture program drop cvequal
program cvequal, rclass

		version 11
		syntax varname(numeric) [if] [in] , BY(varname)
		
			quietly {
				preserve
				tokenize `varlist'

				marksample touse
				count if `touse'
				if r(N) == 0 error 2000
				keep if `touse' 
				keep `varlist' `by'
				
				// check the number of groups
				levelsof `by'
				local k = r(r)
				local df = `k' - 1
				if `k' < 2 {
					di as err "at least two groups must be specified"
					exit 198
				}

				noisily tabstat `varlist' , by( `by' ) stat(n mean sd cv) nototal	
				
				 // Collapse data by grouping variable
				collapse (count) n_j=`varlist' (mean) x_j=`varlist' (sd) s_j=`varlist', by(`by')
				gen m_j = n_j - 1
				gen D = (sum(m_j * (s_j/x_j))) / sum(m_j)
				sum D
				local D = r(max)

				gen D_AD = (sum(m_j * (s_j/x_j - `D')^2 )) / ( `D'^2 * (0.5 + `D'^2) ) 
				sum D_AD
				local D_AD = r(max) 
				local pval = chi2tail(`df',`D_AD')

				restore 
			} // end quietly
			
			// header info
			disp _newline as text "Equality of coefficients of variation (CV) from `k' populations:"
			disp _newline
			disp as text " chi2(`df') =  " as result %5.4f `D_AD'
			disp as text "    Prob =  " as result %5.4f `pval'
			
			// Stored results
			return scalar chi2 = `D_AD'
			return scalar df = `df'
			return scalar pval = `pval'
				
end
