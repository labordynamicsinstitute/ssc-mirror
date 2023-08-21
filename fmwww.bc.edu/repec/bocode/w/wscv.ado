*! 1.0.0 Ariel Linden 12Aug2023 

capture program drop wscv
program wscv, rclass byable(recall)

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
				
				// compute mu
				tempvar rowmean id j
				egen `rowmean' = rowmean(`r'1 - `r'`ncol') 
				sum `rowmean'
				local mu = r(mean)
				
				// reshape long to run ANOVA, get MS-residual and then compute within subject s.d.
				gen `id' = _n
				reshape long `r', i(`id') j(`j')
				anova `r' `id'
				local msr = e(rmse)^2
				local wssd = e(rmse)
				local msb = e(mss)/(`nrow' - 1)
				local wscv = `wssd' / `mu'
				
				// set default test type to "twosided"  
				if "`onesided'" != "" {
					local alpha = (100 - `level') / 100
				}
				else local alpha = ((100 - `level') / 100) / 2

				local zalpha = invnorm(1 -`alpha')
				
				// compute variance/sd and CIs according to the delta method
				local rho = ((`nrow' - 1) * `msb' - `nrow' * `msr') / ((`nrow' - 1) * `msb' + `nrow' * (`ncol'- 1) * `msr')
				local wscv_sd = sqrt(`wscv'^4 / (`ncol' * `nrow') * (1 + `ncol' * `rho'/ (1 - `rho')) + `wscv'^2 / (2 * `nrow' * (`ncol'- 1)))
				local lcl = `wscv' - (`zalpha' * `wscv_sd')
				local ucl = `wscv' + (`zalpha' * `wscv_sd')

		
			
			} // end quietly	
				
			// header info
			disp _newline as text "Within-subject coefficient of variation"

			disp _newline
			disp %35s "Number of ratings = " %4.0f `ncol'
			disp %35s "Number of targets = " %4.0f `nrow'
			
			
			// Display output table

			tempname mytab
			.`mytab' = ._tab.new, col(5) lmargin(0)
			.`mytab'.width    22   |11  12  12    12
			.`mytab'.titlefmt  .     .   . %24s   .
			.`mytab'.pad       .     1   1  3     3
			.`mytab'.numfmt    . %9.6f %9.6f %9.6f %9.6f
			.`mytab'.strcolor result  .  .  .  .
			.`mytab'.strfmt    %19s  .  .  .  .
			.`mytab'.strcolor   text  .  .  .  .
			.`mytab'.sep, top
			.`mytab'.titles ""										/// 1
							"Estimate"								/// 2
							"Std. Dev."								/// 3
							"[`level'% Conf. Interval]" ""          //  4 5
			.`mytab'.sep, middle
				.`mytab'.strfmt    %20s  .  .  .  .
				.`mytab'.row    "wscv"			///
					`wscv'						///
					`wscv_sd'					///
					`lcl'						///
					`ucl'
			.`mytab'.sep, bottom				
			
			//	return list
			return scalar ntar = `nrow'
			return scalar nrat = `ncol' 
			return scalar mu = `mu'
			return scalar wssd = `wssd'
			return scalar wscv = `wscv'
			return scalar sd = `wscv_sd'
			return scalar lcl = `lcl'
			return scalar ucl = `ucl'	
			
end
