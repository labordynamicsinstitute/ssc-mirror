*! 1.0.0 Ariel Linden 30Jun2023 

capture program drop robinson
program robinson, rclass byable(recall)

		version 11
		syntax varlist(min=2 numeric) [if] [in] 
		
			quietly {
				preserve
				tokenize `varlist'
				local ncol : word count `varlist'

				marksample touse
				count if `touse'
				if r(N) == 0 error 2000
				keep if `touse' 
				keep `varlist' `id'
				local nrow = r(N) 
				

				// rename variables
				local i = 1
				tempvar r
				foreach x of local varlist {
					clonevar `r'`i' = `x'
					local i = `i' + 1
				}
				
				// compute SSbetween
				tempvar rowmean num j
				egen `rowmean' = rowmean(`r'1 - `r'`ncol') 
				sum `rowmean'
				
				local ssb = r(Var) * `ncol' * (`nrow'- 1)

				// reshape long to compute SStotal and SSw
				gen `num' = _n
				reshape long `r', i(`num') j(`j')
				anova `r' `j'
				
				local ssw = e(mss)
				local sstotal = e(mss) + e(rss)
				local ssr = `sstotal' - `ssb' - `ssw'
				local robinson = `ssb' / (`ssb' + `ssr')
			
			} // end quietly	
				
			// header info
			disp _newline "Robinson's coefficient of agreement"
			disp "         Number of raters = " %4.0f `ncol'
			disp "            Number of obs = " %4.0f `nrow'
			
			disp _newline
			disp "       Robinson's coefficient = " %9.5f `robinson'

			//	return list
			return scalar nrows = `nrow'
			return scalar ncols = `ncol' 
			return scalar ssb = `ssb'
			return scalar ssw = `ssw'
			return scalar sstotal = `sstotal'
			return scalar ssr = `ssr'
			return scalar robinson = `robinson'
				
			
end
