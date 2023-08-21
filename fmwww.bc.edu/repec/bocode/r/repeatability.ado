*! 1.0.0 Ariel Linden 13Aug2023 

capture program drop repeatability
program repeatability, rclass byable(recall)

		version 11
		syntax varlist(min=2 numeric) [if] [in] [, Level(real 95) ONESIDed ]
		
			quietly {
				preserve
				tokenize `varlist'
				local ncol : word count `varlist'

				marksample touse
				count if `touse'
				if r(N) == 0 error 2000
				keep if `touse' 
				keep `varlist'
				local nrow = r(N) 
				

				// rename variables
				local i = 1
				tempvar r
				foreach x of local varlist {
					clonevar `r'`i' = `x'
					local i = `i' + 1
				}
				
				// set default test type to "twosided"  
				if "`onesided'" != "" {
					local alpha = (100 - `level') / 100
				}
				else local alpha = ((100 - `level') / 100) / 2

				local zalpha = invnorm(1 - `alpha')
				
				// reshape long to run ANOVA, get MS-residual and then compute within subject s.d.
				tempvar id j				
				gen `id' = _n
				reshape long `r', i(`id') j(`j')
				anova `r' `id'
				local wssd = e(rmse)
				local repeat = sqrt(2) * `zalpha' * `wssd'
				
				// compute CIs
				local lcl = `repeat' * sqrt(`nrow' * (`ncol' - 1) / invchi2(`nrow' * (`ncol' - 1), 1 - `alpha'))
				local ucl = `repeat' * sqrt(`nrow' * (`ncol' - 1) / invchi2(`nrow' * (`ncol' - 1), `alpha'))				

		
			} // end quietly	
				
			// header info
			disp _newline as text "Repeatability coefficient with confidence intervals"

			disp _newline
			disp %35s "Number of ratings = " %4.0f `ncol'
			disp %35s "Number of targets = " %4.0f `nrow'
			
			
			// Display output table

			tempname mytab
			.`mytab' = ._tab.new, col(4) lmargin(0)
			.`mytab'.width    22   |11  12  12
			.`mytab'.titlefmt  .    .   . %24s
			.`mytab'.pad       .     1   3   3
			.`mytab'.numfmt    . %9.6f %9.6g %9.6g
			.`mytab'.strcolor result  .  .  .
			.`mytab'.strfmt    %19s   .  .  .
			.`mytab'.strcolor   text  .  .  .
			.`mytab'.sep, top
			.`mytab'.titles ""										/// 1
							"Estimate"								/// 2
							"    [`level'% Conf. Interval]" ""		//  3 4
			.`mytab'.sep, middle
				.`mytab'.strfmt    %20s  .  .  .
				.`mytab'.row    "repeatability"	///
					`repeat'					///
					`lcl'						///
					`ucl'
			.`mytab'.sep, bottom				
			
			//	return list
			return scalar ntar = `nrow'
			return scalar nrat = `ncol' 
			return scalar wssd = `wssd'
			return scalar repeat = `repeat'
			return scalar lcl = `lcl'	
			return scalar ucl = `ucl'				

end
