*! 1.0.0 Ariel Linden 160ct2025

program define alphaplot, rclass
	version 11
	syntax varlist(min=2 numeric) [if] [in] [, FORmat(string) TWoopts(string asis) *]

	// Mark sample and get sample size
	marksample touse
	quietly count if `touse'
	local N = r(N)

	// Count number of items in the varlist
	local total : word count `varlist'

	// Initialize result matrix
	tempname results
	matrix `results' = J(`=`total'-1', 2, .) // starts at 2 because that's the min for alpha
	local row = 1

	// Loop through increasing number of items
	forvalues i = 2/`total' {
		// Build subset of first i variables
		local subset
		forvalues j = 1/`i' {
			local v : word `j' of `varlist'
			local subset `subset' `v'
		}

        // run alpha
		quietly capture alpha `subset' if `touse', `options'
		if _rc == 0 {
			tempname a
			scalar `a' = r(alpha)
			// Store results in matrix
			matrix `results'[`row',1] = `i'
			matrix `results'[`row',2] = `a'
		}
		else {
			display as error "alpha failed at k = `i'"
		}
		local ++row
	} // end looping through items

	// Convert matrix to variables for plotting
	preserve
	clear

	matrix colnames `results' = k alpha	
	qui svmat `results', names(col)
	
	// Format alpha values for graph labels
	if "`format'" != "" { 
		confirm numeric format `format' 
	}
	else local format %6.3f 
	tempvar alpha_fmt
	gen str6 `alpha_fmt' = string(alpha, "`format'")

	// save results
	return matrix results = `results'
	return scalar N = `N'	
	
	// Create graph
	twoway connected alpha k, ///
		sort lwidth(medthick) ///
		mlabel(`alpha_fmt') mlabpos(12) mlabcolor(black) ///
		title("Cronbach's Alpha by Number of Items") ///
		ytitle("Alpha") xtitle("Number of Items (k)") ///
		xlabel(2(1)`total') ///
		`twoopts'		
	restore
	
end
