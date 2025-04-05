*! 1.0.0 Ariel Linden 26Mar2025 

program randmarkovseq, rclass
		version 11.0
		syntax , 						///
		Sample(integer)					///
		LAbels(string asis)				/// 
		[ MATrix(string)				///
		SEED(string)					///
		First(string) 					///
		TRANSition * ]

		quietly {
			
			// set the seed
			if "`seed'" != "" set seed `seed'
			local seed `c(seed)'

			// ensure that more than one label is specified
			local labcnt : word count `labels'
			if `labcnt' < 2 {
				di as err "at least 2 labels must be specified"
				exit 198			
			}
			
			local dups : list dups labels
			local ndups : list sizeof dups
			if `ndups' > 0 {
				di as err "`dups' appears more than once in labels()"
				exit 198			
			}	
			
			// 
			if "`first'" != "" {
				local k : list posof "`first'" in labels
				if `k' == 0 {
					di as err "`first' is not found in list of labels" 
					exit 198							
				}
			}	
			
			clear
			
			// if the matrix is specified
			if "`matrix'" != "" {
				// check that matrix exists
				qui mat li `matrix'
				// check that matrix is symmetrical
				if rowsof("`matrix'") != colsof("`matrix'") {
					di as err "the matrix must be symmetrical"
					exit 198	
				}
				// check that rowtotals equal 1
				mata : X = rowsum(st_matrix("`matrix'"))
				mata: st_matrix("rowX", X)
				mata: st_numscalar("rowX", sum(st_matrix("rowX")))
				
				mata: st_numscalar("sumX", sum(st_matrix("X")))
				if scalar(rowX) != scalar(sumX) {
					di as err "row totals of matrix `matrix' do not equal 1.0"
					exit 198	
				}
				// check that number of labels equals number of values in matrix row
				if `labcnt' != rowsof("`matrix'") {
					di as err "the number of labels specified does not equal the number of values in the matrix row"
					exit 198			
				}
			
				mata : matvals(`sample', "`matrix'")

				// convert matrix A to variables
				tempvar freq col
				svmat int_matrix, name(`freq')

				//  reshape into long format
				gen sequence = _n  //  Create a row identifier
				reshape long `freq', i(sequence) j(`col')
				expand `freq'
				drop `freq'
				drop `col'
			}
			// if no matrix is specified
			else {
				set obs `labcnt'
				gen sequence = _n
				local cnt = ceil(`sample' / `labcnt')
				expand `cnt'
			}
			tempvar rand
			gen double `rand' = runiform()
			sort `rand'
			drop `rand'
			count
			drop if _n > `sample'

			// label labels with those provided by user
			tokenize `labels'
			forval i = 1/`labcnt' { 
				label define labels `i' `"``i''"', add 
			} 
			forval j = 1/`labcnt' { 
				label values sequence labels
 
			} 
			if "`first'" != "" {
				replace sequence = `k' in 1
			}
			
			// generate transition table
			tempvar prev table
			gen `prev' = sequence[_n-1]
			label var `prev' "current"
			label values `prev' labels
			quietly tab `prev' sequence, matcell(`table')
			
			if "`transition'" != "" {
					noisily tab `prev' sequence, row chi2 lrchi2 `options'
			} 
			
		} // end quietly
		
		// return list
		return matrix table = `table'
			
end

version 11.0
mata:
mata clear
void function matvals(real scalar grand, string scalar stata_matrixname)

{

	real matrix X
    X = st_matrix(stata_matrixname)

	total_sum = grand
		  
	r = rows(X)
	c = cols(X)

	// initialize a column vector of random values
	rand_vals = runiform(1, r)

    // sum of the random values
	total = sum(rand_vals)
    
    // scale the random values to sum to 1
	rand_vals_scaled = ceil((rand_vals / total) * total_sum)
	
    // initialize matrix to store the integer values
	int_matrix = J(r, c, 0)  
	
	// generate integer values
	int_matrix = round(X:*rand_vals_scaled')	
	
	// convert to Stata matrix 
	st_matrix("int_matrix", int_matrix)

}
end