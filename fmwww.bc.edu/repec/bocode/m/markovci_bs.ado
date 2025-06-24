*! 1.0.0 Ariel Linden 21jun2025

program markovci_bs, rclass
	version 11

	syntax , 			///
	MATrix(string) 		///
	obs(real) 			///
	LABels(string) 		///
	[ First(string)		///
	Reps(integer 50) 	///
	PERcentile			///
	LEVel(cilevel)		///	
	FORmat(string) 		///
	SAving(string asis)	///
	]

			preserve
			// ensure that more than one label is specified
			local labcnt : word count `labels'
			if `labcnt' < 2 {
				di as err "at least 2 labels must be specified"
				exit 198			
			}
			
			local dups : list dups labels
			local ndups : list sizeof dups
			if `ndups' > 0 {
				di as err "{bf:`dups'} appears more than once in {bf:labels(`labels')}"
				exit 198			
			}	
			
			// check that first is in the list of labels
			if "`first'" != "" {
				local k : list posof "`first'" in labels
				if `k' == 0 {
					di as err "{bf:`first'} is not found in list of labels" 
					exit 198							
				}
			}	
			
			// check that matrix is symmetrical
			if rowsof("`matrix'") != colsof("`matrix'") {
				di as err "{bf:matrix(`matrix')} must be symmetrical"
				exit 198	
			}

			// get row count
			local rows = rowsof("`matrix'")

			// Loop through each row to check if the sum equals 1
			forval i = 1/`rows' {
				* Calculate the row sum
				scalar row_sum = 0
				forval j = 1/`rows' {
					scalar row_sum = row_sum + `matrix'[`i', `j']
				}
				* Check if the row sum is not equal to 1
				if abs(row_sum - 1) > 1e-6 {
					di as err "row `i' of {bf:matrix(`matrix')} does not sum to 1. Sum = " row_sum
					exit 198
				}
			}
			
			// format the numeric values in tables
			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %9.4f 
			
			// set up postfile 
			tempname sim
			tempfile bootmarkchain

			local cols = colsof(`matrix')

			// Loop over each element to generate the variables that hold the cell probabilities
			local bag
			forvalues i = 1/`rows' {
				forvalues j = 1/`cols' {
					// Get the value
					local cell_`i'_`j' = `matrix'[`i', `j']
					local bag `bag' cell_`i'_`j'
				}
			}

			qui postfile `sim' `bag' using `bootmarkchain', replace

			// setup for dots
			di _n
			di as txt "Iterating across (" as res `reps' as txt ") bootstrap samples "

			_dots 0
			forvalues i = 1/`reps' {
				_dots `i' 0
				randmarkovseq , obs(`obs') labels(`labels') first(`first') matrix(`matrix')
			
				tempname X
				mat `X' = r(rowprobs)
				local rows = rowsof(`X')
				local cols = colsof(`X')

				// Loop over each element to generate the scalars of the cell probabilities
				local grab
				forvalues i = 1/`rows' {
					forvalues j = 1/`cols' {
						// Get the value
						scalar cell_`i'_`j' = `X'[`i', `j']
						local grab `grab' (cell_`i'_`j')
					}
				}	
			
				post `sim' `grab'
						
			} // end bootstrap loop					
	
			postclose `sim'
	
			// open file with bootstrapped data
			use `bootmarkchain', clear
			
			if "`saving'" != "" {
				save `saving', replace
			}

			tempname bsmean bsprop bslcl bsucl prop sd se lcl ucl
			matrix `bsprop' = J(`rows', `cols', .)
			matrix `bslcl' = J(`rows', `cols', .)
			matrix `bsucl' = J(`rows', `cols', .)

			forval i = 1/`rows' {
				forval j = 1/`cols' {
					qui sum cell_`i'_`j' , d
					qui mean cell_`i'_`j', level(`level')
					matrix `bsmean' = r(table)
					scalar `prop' = `bsmean'[1,1]
					// normal CIs
					if "`normal'" != "" {
						scalar `lcl' = `bsmean'[5,1]
						scalar `ucl' = `bsmean'[6,1]
					}
					// percentile CIs
					else {
						qui centile cell_`i'_`j', centile(`= (100 - `level')/2' `= 100 - (100 - `level')/2')		
						scalar `lcl' = r(c_1)
						scalar `ucl' =	r(c_2)	
					}

					matrix `bsprop'[`i', `j'] = `prop'
					matrix `bslcl'[`i', `j'] = `lcl'
					matrix `bsucl'[`i', `j'] = `ucl'				

				}	
			}
	
			// create the tables
			di _n
			
			matrix rownames `bsprop' = `labels'
			matrix colnames `bsprop' = `labels'
			matlist `bsprop', border(all) lines(cell) format(`format')  title(mean transition probabilities) tindent(1) aligncolnames(center) twidth(8)
	
			if "`percentile'" != "" {
				local type (percentile)
			}
			else local type (normal)			
			
			matrix rownames `bslcl' = `labels'
			matrix colnames `bslcl' = `labels'
			matlist `bslcl', border(all) lines(cell) format(`format')  title(lower "`level'%" confidence limit `type') tindent(1) aligncolnames(center) twidth(8)
	
			matrix rownames `bsucl' = `labels'
			matrix colnames `bsucl' = `labels'
			matlist `bsucl', border(all) lines(cell) format(`format')  title(upper "`level'%" confidence limit `type') tindent(1) aligncolnames(center) twidth(8)
	
			// return matrices
			return matrix ucl = `bsucl'
			return matrix lcl = `bslcl'
			return matrix prop = `bsprop'	
			
			restore
	
end



