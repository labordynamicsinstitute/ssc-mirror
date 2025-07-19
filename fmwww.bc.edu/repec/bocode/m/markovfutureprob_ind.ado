*! 1.0.0 Ariel Linden 05Jul2025 

program markovfutureprob_ind, rclass
		version 11.0
		
		syntax anything , CURRent(string) [ PERiod(real 2) FORmat(string) TITle(string) ]

			// only one matrix may be specified
			local matcount : word count `anything'
			if (`matcount' > 1) {
				di as err "only one matrix may be specified"				
				exit = 103
			}
			// only one current state may be specified
			local currcount : word count `current'
			if (`currcount' > 1) {
				di as err "only one current state may be specified"
				exit = 103	
			}	
			
			local nrows = rowsof(`anything')
			local ncols = colsof(`anything')
                
			if `nrows' < 2 {
				di as err "the matrix must have at least 2 rows"
				exit 198
			}

			// check that matrix is symmetrical
			if `nrows' != `ncols' {
				di as err "the matrix must be symmetrical (equal number of rows and columns)"
				exit 198        
			}

			// loop through each row to check if the sum equals 1
			forval i = 1/`nrows' {
			* Calculate the row sum
				scalar row_sum = 0
				forval j = 1/`nrows' {
					scalar row_sum = row_sum + `anything'[`i', `j']
				}
				* Check if the row sum is not equal to 1
				if abs(row_sum - 1) > 1e-6 {
					di as err "row `i' of matrix `anything' does not sum to 1. Sum = " row_sum
					exit 198
				}
			}
			local rownames : rownames `anything'
			local colnames : colnames `anything'
			

			// determine if current state is a number or letter or combo //
			// Check for integer
			if regexm("`current'", "^[0-9]+$") {
				local nrows = rowsof(`anything')
				if `current' > `nrows' {
					di as err "`current' is not a valid row number"
					exit 198
				}
				else {
					local holdout = `current'
				}	
			}	
			// Check for alpha
			else if regexm("`current'", "^[a-zA-Z]+$") {
				if !`: list destination in rownames'  {
					di as err "{bf:`current'} is not in the list of matrix rownames: " "{bf:`rownames'}"
					exit 198
				}
				else {
					local i : list posof "`current'" in rownames
					local holdout = `i'
				}
			}	
			// else it's mixed alpha and numeric
			else if regexm("`current'", "^(?=.*[a-zA-Z])(?=.*[0-9]).+$") {
				if !`: list destination in rownames'  {
					di as err "{bf:`current'} is not in the list of matrix rownames: " "{bf:`rownames'}"
					exit 198
				}
				else {
					local i : list posof "`current'" in rownames
					local holdout = `i'
				}
			}				
			else {
				di as err "`current' is not in the list of matrix rownames or a row number"
				exit 198
			}
			
			mata: futureprob(`holdout', `period', "`anything'")
			
			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %6.3f 
						
			local title title(Probabilities for `period' periods into the future)	
						
			// assign original rownames and colname that corresponds to the current state  
			matrix colnames futureprobs_full = `colnames'
			local rowfind : word `holdout' of `rownames'
			matrix rownames futureprobs_full = `rowfind'			
			
			matlist futureprobs_full,  border(top bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(`format') `title'

			// save matrix
			return matrix futureprobs = futureprobs_full

end


version 11.0
mata:
mata clear
void function futureprob(real holdout, real period, string scalar stata_matrixname)

	{

		real matrix A
        
		// Convert Stata matrix to Mata		
		A = st_matrix(stata_matrixname)
		nrows = rows(A)
		// create matrix to identify current state
		curr = J(1, nrows, 0)		
		curr[holdout] = 1
		// Initialize matrix A as identity matrix
		ident = I(rows(A))
		
		// Multiply A by period (X times)
		for (i = 1; i <= period; i++) {
			ident = ident * A
		}		

		futureprobs_full = curr * ident
		
		// save as Stata matrix
		st_matrix("futureprobs_full", futureprobs_full)		
	}		
end		
