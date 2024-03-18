*! version 1.0.0 Ariel Linden 12mar2024

capture program drop bmtest
program define bmtest, rclass byable(recall)
		version 11.0
		syntax varlist(numeric min=1 max=1) [if] [in], BY(varname) [ DIRection(string)  REVerse Level(real `c(level)') ]
		
		quietly {
			preserve
			marksample touse
			keep if `touse'
			
			local y "`varlist'"
			
			// ensure that direction is either "lt", "gt", or ""
			if !inlist("`direction'", "lt", "gt", "") {
				di as err "{bf:direction} must be either 'lt', 'gt', or not specified"			
				exit 198
			}

			// alpha
			if `level' <= 0 | `level' >= 100 { 
				di as err "{bf:'level'} must be > 0 and < 100"
				error 499
			}
			local alpha = ((100 - `level') / 100) / 2				

			// ensure that `by' is numeric
			local origby "`by'"			
			capture confirm numeric variable `by'
			if _rc {
				tempvar numby
				encode `by', generate(`numby')
				local by "`numby'"
			}

			// ensure that 'by' is binary
			tab `by'
			if r(r) != 2 {
				noi di as err "{bf:`by'} must be a binary variable"				
				exit 420
			}  
			
			tempvar `y'1 `y'2 r r1 r2 V1 V2 pst v1 v2 stat dfbm pval lcl ucl
			
			// get coding levels per group		
			sum `by', meanonly
			local lev1 = r(min)
			local lev2 = r(max)
			
			// get labels for `by' variable
			levelsof `by', local(levels)
			local i = 1
			foreach l of local levels {
				local name`i' =  "`: label (`by') `l''"
				local i = `i' + 1
			}

			// reverse the group order			
			if "`reverse'" !="" {
				tempvar newby
				recode `by' (`lev1' = `lev2' "`name1'")	(`lev2' = `lev1' "`name2'"), gen(`newby') label(`by')
				local by `newby'
				
				levelsof `by', local(levels)
				local i = 1
				foreach l of local levels {
					local name`i' =  "`: label (`by') `l''"
					local i = `i' + 1
				}
			}			
			
			// gen Y's separately by group			
			gen ``y'1' = `varlist' if `by' == `lev1'
			gen ``y'2' = `varlist' if `by' == `lev2' 			

			// gen ranks separately by group and overall
			egen `r' = rank(`y')
			egen `r1' = rank(``y'1')
			egen `r2' = rank(``y'2')			

			// get n and means by group
			sum `r' if `by' == `lev1', meanonly
			local n1 = r(N)
			local m1 = r(mean)
			sum `r' if `by' == `lev2', meanonly
			local n2 = r(N)
			local m2 = r(mean)
			
			// BM estimate (coefficient)
			scalar `pst' = (`m2' - (`n2' + 1)/2)/`n1'

			// compute variances for each group
			gen `V1' = ((`r' - `r1' - `m1' + (`n1' + 1)/2)^2)/(`n1' - 1)
			sum `V1', meanonly
			scalar `v1' = r(sum)
			gen `V2' = ((`r' - `r2' - `m2' + (`n2' + 1)/2)^2)/(`n2' - 1) 
			sum `V2', meanonly
			scalar `v2' = r(sum)
			
			// get t-statistic and df
			scalar `stat' = `n1' * `n2' * (`m2' - `m1')/(`n1' + `n2')/sqrt(`n1' * `v1' + `n2' * `v2')
			scalar `dfbm' = ((`n1' * `v1' + `n2' * `v2')^2)/(((`n1' * `v1')^2)/(`n1' - 1) + ((`n2' * `v2')^2)/(`n2' - 1))
			
			// directional hypothesis
			* first group is greater than second
			if "`direction'" == "gt" {
				scalar `pval' = t(`dfbm', `stat')
			}
			* first group is lower than second
			else if "`direction'" == "lt" {
				scalar `pval' = ttail(`dfbm', `stat')
			}
			* the two groups are not equal
			else {
				scalar `pval' = 2 * min(t(abs(`dfbm'), `stat'), ttail(abs(`dfbm'), `stat'))
			}

			// Compute CIs
			scalar `lcl' = `pst' - invt(`dfbm', 1 - `alpha') * sqrt(`v1'/(`n1' * `n2'^2) + `v2'/(`n2' * `n1'^2))
			scalar `ucl' = `pst' + invt(`dfbm', 1 - `alpha') * sqrt(`v1'/(`n1' * `n2'^2) + `v2'/(`n2' * `n1'^2))			
		
		} // end quietly		
		
		// Display table header information 
		di _newline
		di as text "Two-sample Brunner-Munzel test"
		
		// null and alternative hypothesis
		di _newline
		if "`direction'" == "lt" {
			di as text "H0: P(" "`name1'" " < " "`name2'" ") + 0.5P(" "`name1'" " = " "`name2'" ") versus Ha: P(" "`name1'" " < " "`name2'" ") + 0.5P(" "`name1'" " = " "`name2'" ") < .5" 
		}
		else if "`direction'" == "gt" {
			di as text "H0: P(" "`name1'" " < " "`name2'" ") + 0.5P(" "`name1'" " = " "`name2'" ") versus Ha: P(" "`name1'" " < " "`name2'" ") + 0.5P(" "`name1'" " = " "`name2'" ") > .5"
		}
		else {
			di as text "H0: P(" "`name1'" " < " "`name2'" ") + 0.5P(" "`name1'" " = " "`name2'" ") versus Ha: P(" "`name1'" " < " "`name2'" ") + .5P(" "`name1'" " = " "`name2'" ") ≠ .5"
		}			
			
		di as text _newline %64s "Obs per group:"
		disp %64s "`name1'" " = " %10.0fc `n1'
		disp %64s "`name2'" " = " %10.0fc `n2'				

		local clv `level'
		local cil `=length("`clv'")'
		#delim ;
		di in smcl in gr "{hline 13}{c TT}{hline 64}"
		_newline "             {c |}"
		" Coefficient"   // model type //
		_col(32) "df"
		_col(41) "t"
		_col(50) "P"
		_col(`=61-`cil'') `"[`clv'% Conf. Interval]"'
		_newline
		in gr in smcl "{hline 13}{c +}{hline 64}"
		_newline
		_col(1) %12s "`y'"
		_col(14) "{c |}" in ye
		_col(17) %9.0g `pst'
		_col(30) %5.3f `dfbm'
		_col(35) %8.2f `stat'
		_col(48) %5.3f `pval'
		_col(58) %9.0g `lcl'
		_col(70) %9.0g `ucl'
		_newline
		in gr in smcl "{hline 13}{c BT}{hline 64}"
		;
		#delim cr
			
		// save results
		return scalar coef = `pst'
		return scalar t = `stat'
		return scalar df = `dfbm'		
		return scalar p = `pval'
		return scalar ll = `lcl'
		return scalar ul = `ucl'
		return scalar n1 = `n1'
		return scalar n2 = `n2'
		
end		

