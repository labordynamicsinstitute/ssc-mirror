*! 1.1.0 Ariel Linden 10oct2025		// changed code to display xvar values rather than sequential numbering
									// fixed width of table columns
*! 1.0.0 Ariel Linden 07oct2025

program define menger, rclass
    version 11
    syntax varlist(min=2 max=2 numeric) [if] [in] [, GRaph DEtail]
    
	qui {
    
		* Parse variables xvar and yvar
		tokenize `varlist'
		local xvar `1'
		local yvar `2'
    
		* Mark the sample to use
		marksample touse
    
		* Sort data by xvar
		sort `xvar'
    
		* Initialize results
		tempvar curvature menger_results
		gen `curvature' = .
    
		* Calculate Menger curvature for each triplet of consecutive points
		count if `touse'
		local N = r(N)
    
		forvalues i = 2/`=`N'-1' {
			local i1 = `i' - 1
			local i2 = `i'
			local i3 = `i' + 1
        
			* Get the three points
			local x1 = `xvar'[`i1']
			local y1 = `yvar'[`i1']
			local x2 = `xvar'[`i2']
			local y2 = `yvar'[`i2']
			local x3 = `xvar'[`i3']
			local y3 = `yvar'[`i3']
        
			* Calculate area of triangle using determinant formula
			local area = 0.5 * abs((`x1'*(`y2'-`y3') + `x2'*(`y3'-`y1') + `x3'*(`y1'-`y2')))
        
			* Calculate side lengths
			local a = sqrt((`x2'-`x3')^2 + (`y2'-`y3')^2)  // side between points 2 and 3
			local b = sqrt((`x1'-`x3')^2 + (`y1'-`y3')^2)  // side between points 1 and 3
			local c = sqrt((`x1'-`x2')^2 + (`y1'-`y2')^2)  // side between points 1 and 2
        
			* Calculate Menger curvature: 4 * area / (product of sides)
			if `a' * `b' * `c' > 0 {
				replace `curvature' = 4 * `area' / (`a' * `b' * `c') in `i'
			}
		}
    
		* create matrix of relevant values
		count if `curvature' != .
		local matrix_rows = r(N)
		matrix `menger_results' = J(`matrix_rows', 2, .)
		local row = 1
		forvalues i = 2/`=`N'-1' {
			if `curvature'[`i'] != . {
				// Get the format of xvar
				local fmt : format `xvar'
				local fmt_clean = substr("`fmt'", 2, .)
				// Extract the value of xvar[`i`] formatted
				quietly {
					local xi : display %`fmt_clean' `xvar'[`i']
				}
				local rname `rname' `xi'
				matrix `menger_results'[`row', 1] = `yvar'[`i']
				matrix `menger_results'[`row', 2] = `curvature'[`i']
				local row = `row' + 1
			}
		}
		
		* matrix names
		matrix colnames `menger_results' = `yvar' curvature
		matrix rownames `menger_results' = `rname' 
		
		
		* if detail is specified *
		if "`detail'" != "" {
			* get rspec() values
			local ylablen = strlen("`yvar'")
			local yvalen : format `yvar'
			local yvalen = substr(substr("`yvalen'", 2, .), 1, strpos(substr("`yvalen'", 2, .), ".") - 1)
			local ylen = max(`ylablen', `yvalen' )
			local xlablen = strlen("`xvar'")
			local xvalen : format `xvar'
			local xvalen = substr(substr("`xvalen'", 2, .), 1, strpos(substr("`xvalen'", 2, .), ".") - 1)
			local xlen = max(`xlablen', `xvalen')

			local nrows = rowsof(`menger_results')
			local rspec_str "&-"
			forvalues i = 1/`=`nrows'-1' {
				local rspec_str "`rspec_str'&"
			}
			local rspec_str "`rspec_str'-"
    
			* Display the matrix
			noi di " "
			noi matlist `menger_results',  rowtitle(`xvar') cspec(o4& %`xlen's | w`ylen' %8.5f & w9 %8.5f &)  rspec("`rspec_str'")		

		} // end detail
	
		* Find maximum curvature and corresponding xvar
		tempvar has_curvature
		gen `has_curvature' = `curvature' != .
    
		sum `curvature' if `has_curvature', meanonly
		local max_curvature = r(max)
    
		* Find the xvar value where maximum curvature occurs
		levelsof `xvar' if abs(`curvature' - `max_curvature') < 1e-10 & `has_curvature', local(elbow)
    
	    * Save results
		return scalar max_curv = `max_curvature'
		return scalar elbow = `elbow'
		return matrix results = `menger_results'
    
		noi di " " 
		noi di "Max curvature:  " %8.5f `max_curvature' " at `xvar' = " %`fmt_clean' `elbow'
	
	} // end qui
	
	// Optional graph
    if "`graph'" != "" {
		* get var labels for graph	
		local yl : variable label `yvar'
		if `"`yl'"' == "" local yl "`yvar'"  
		local xl : variable label `xvar'
		if `"`xl'"' == "" local xl "`xvar'"  
	
        twoway (connected `yvar' `xvar', lwidth(medthick) msymbol(o)) ///
               (scatter `yvar' `xvar' if `xvar'==`elbow', ///
					msymbol(O) mcolor(red) msize(large) mlabel(`xvar') mlabposition(2) mlabsize(medium)),  ///
					title("Menger Curvature") ///
					xtitle(`xl') ytitle("`yl'") ///
					legend(off)
    }
	
end
