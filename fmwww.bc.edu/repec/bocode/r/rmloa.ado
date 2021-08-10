*! 1.0.0 Ariel Linden 29July2021 

capture program drop rmloa
program rmloa, rclass byable(recall)

	version 11
	syntax varlist(min=2 max=2 numeric) [if] [in] [, I(varlist min=1 max=1 numeric) CONstant Level(real `c(level)') FIGure FIGure2(str asis) ]

		tokenize `varlist'
		local var1 `1'
		local var2 `2'

		
		// get length of Y and X for table formatting
		local len1 = length("`var1'")
		local len2 = length("`var2'")
		local len = max(`len1',`len2') + 6

		marksample touse 
		qui count if `touse'
		if r(N) == 0 error 2000 
		local n = r(N) 
		
		if "`i'" !="" {
		    qui tab `i' if `touse'
			local n1 = r(r)
		}
			
		if `level' <= 0 | `level' >= 100 { 
			di as err "invalid confidence level"
			error 499
		}
		
		if "`i'" == "" & "`constant'" != "" {
		    di as err "constant must be specified with i()"
			error 198
		}
	
		tempvar diff cnt cntsq diff_mean mult b
		tempname d zval sd lb ub mss mss1 mss2 val1 val2 val3 m m1 m2 m2_2 m2_22 var_c x x1 x2
		
		****************************
		* INDEPENDENT OBSERVATIONS *
		****************************
		
		if "`i'" == "" {
			quietly {
			    gen `diff' = `var1' - `var2' if `touse'
				sum `diff' if `touse'
				scalar `d' = r(mean)
				scalar `sd' = r(sd)
				scalar `zval' = -1 * invnorm((1 - `level' / 100) / 2)
				scalar `lb' = `d' - `zval' * `sd'
				scalar `ub' = `d' + `zval' * `sd'
			}
		
		// Display table header information 
		disp _newline "LOA for independent observations"
		disp "   Number of obs =" %4.0f `n'
		
		} 

		**************************************
		* METHOD WHERE THE TRUE VALUE VARIES *
		**************************************		
		
		if "`i'" != "" & "`constant'" == "" {
			quietly {
				gen `diff' = `var1' - `var2' if `touse'
				sum `diff' if `touse'
				scalar `d' = r(mean)
				oneway `diff' `i' if `touse'
				scalar `mss' = (r(rss) / r(df_r))
				scalar `val1' = (r(mss) / r(df_m)) - (r(rss) / r(df_r))
								
				preserve
				collapse (count) `cnt' = `diff' if `touse', by(`i')
				total `cnt'

				mat `m' = e(b) 
				scalar `m1' = `m'[1,1]
				scalar `m2' = `m1'^2
				
				gen `cntsq' = `cnt'^2
				total `cntsq'
				mat `m2_2' = e(b) 
				scalar `m2_22' = `m2_2'[1,1]
				scalar `val2' = (`m2' - `m2_22') / ((`n1'-1) * `m1')
				scalar `val3' = `val1' / `val2'
				scalar `sd' = sqrt(`mss' + `val3')
				scalar `zval' = -1 * invnorm((1 - `level' / 100) / 2)

				scalar `lb' = `d' - `zval' * `sd'
				scalar `ub' = `d' + `zval' * `sd'
				restore		
			} // end quietly

		// Display table header information 
		disp _newline "LOA for repeated measures where the true value varies"
		disp "  Number of `i' =" %4.0f `n1'
		disp "  Number of obs =" %4.0f `n'
		
		} // end if	
				
		*******************************************
		* METHOD WHERE THE TRUE VALUE IS CONSTANT *
		*******************************************				
				
		if "`i'" != "" & "`constant'" != "" {
			quietly {		
				gen `diff' = `var1' - `var2' if `touse'
				sum `diff' if `touse'
				scalar `d' = r(mean)
				
				oneway `var1' `i' if `touse'
				scalar `mss1' = (r(rss) / r(df_r))
 
				oneway `var2' `i' if `touse'
				scalar `mss2' = (r(rss) / r(df_r))
 
				preserve
				collapse (count) `cnt' = `diff' (mean) `diff_mean' = `diff' if `touse', by(`i')
				sum `diff_mean'
				scalar `var_c' = r(Var) 
 
				gen `mult' = 1/`cnt'
				total `mult'
				mat `x' = e(b) 
				scalar `x1' = `x'[1,1]
				scalar `x2' = 1-(1/`n1') * `x1'
				scalar `sd' =  sqrt(`var_c' + (`x2' * `mss1') + (`x2' * `mss2'))
				scalar `zval' = -1 * invnorm((1 - `level' / 100) / 2)

				scalar `lb' = `d' - `zval' * `sd'
				scalar `ub' = `d' + `zval' * `sd'
				restore
			} // end quietly
			
			// Display table header information 
			disp _newline "LOA for repeated measures where the true value is constant"
			disp "  Number of `i' =" %4.0f `n1'
			disp "  Number of obs =" %4.0f `n'
		
		} // end if	
				
		// Display output table
		tempname mytab
		.`mytab' = ._tab.new, col(5) lmargin(0)
		.`mytab'.width    `len'   |7  5  19    19
		.`mytab'.titlefmt  .     .   . %24s   .
		.`mytab'.pad       .     1   2  5     5
		.`mytab'.numfmt    . %9.0g %9.4f %9.0g %9.0g
		.`mytab'.strcolor result  .  .  .  .
		.`mytab'.strfmt    %19s  .  .  .  .
		.`mytab'.strcolor   text  .  .  .  .
		.`mytab'.sep, top
		.`mytab'.titles "`var1'"								/// 1
						"  Avg. Diff."							/// 2
						"  Std. Dev."							/// 3
						"  [`level'% limits of agreement]" ""    //  4 5
		.`mytab'.sep, middle
		.`mytab'.strfmt    %`len's  .  .  .  .
		.`mytab'.row    "`var2' "  		    		///
				`d' 	                      		///
				`sd'								///
				`lb'                 				///
				`ub'
		.`mytab'.sep, bottom
		

		**********
		* Figure *
		**********
		
		if `"`figure'`figure2'"' != "" {
			gen `b' = (`var1' + `var2') / 2
			
			// create note
			if "`i'" == "" {
				local note "`level'% LOA for independent observations"
			}
			else if "`i'" != "" & "`constant'" == "" {
				local note "`level'% LOA when the true value varies"
			}
			else {
			    local note "`level'% LOA when the true value is constant"
			}
			
			// use id labels for markers in repeated measures LOA
			if  "`i'" != "" {
				local mlab mlabel(`i') mlabposition(0) msymbol(i)
			}
		
			// get Y and X labels
			local ydesc : var label `var1'
			local xdesc : var label `var2'
			local lnth = length(`"`var1'"') + length(`"`var2'"')
			if `"`xdesc'"' == `""' | `lnth' > 50 local xdesc "`var2'"
			if `"`ydesc'"' == `""' | `lnth' > 50 local ydesc "`var1'"
			
			// use locals for yline 
			local d = `d'
			local lb = `lb'
			local ub = `ub'
			
			// set ylabel range
			quietly sum `diff'
			local max = max(r(max), `ub')
			local min = min(r(min), `lb')
			local inc = (`max' - `min') / 5
			
			if abs(`max') > 1 { 
				local ylab ylabel(`min'(`inc') `max', format(%9.0f))
			}
			else local ylab ylabel(`min'(`inc') `max', format(%9.2f))
			
			// graph
			scatter `diff' `b', `ylab'  yline(`d' `lb' `ub') `mlab' ytitle("Difference: `ydesc' - `xdesc'") xtitle("Average of `ydesc' and `xdesc'") legend(off) note(`"`note'"') `figure2'
		
		} // end figure
		
		// return variables	
		return scalar obs = `n'
		return scalar ub = `ub'
		return scalar lb = `lb'
		return scalar sd = `sd'
		return scalar diff = `d'

		
end