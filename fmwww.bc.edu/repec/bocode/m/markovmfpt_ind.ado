*! 1.0.0 Ariel Linden 30Jun2025 

program markovmfpt_ind, rclass
		version 11.0
		
		syntax anything , DESTination(string) [ FORmat(string) TITle(string) ]
		
			
			// only one matrix may be specified
			local matcount : word count `anything'
			if (`matcount' > 1) {
				di as err "only one matrix may be specified"				
				exit = 103
			}
			// only one destination may be specified
			local destcount : word count `destination'
			if (`destcount' > 1) {
				di as err "only one destination may be specified"
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
			

			// determine if destination is a number or letter or combo //
			// Check for integer
			if regexm("`destination'", "^[0-9]+$") {
				local nrows = rowsof(`anything')
				if `destination' > `nrows' {
					di as err "`destination' is not a valid row number"
					exit 198
				}
				else {
					local holdout = `destination'
				}	
			}	
			// Check for alpha
			else if regexm("`destination'", "^[a-zA-Z]+$") {
				if !`: list destination in rownames'  {
					di as err "{bf:`destination'} is not in the list of matrix rownames: " "{bf:`rownames'}"
					exit 198
				}
				else {
					local i : list posof "`destination'" in rownames
					local holdout = `i'
				}
			}	
			// else it's mixed alpha and numeric
			else if regexm("`destination'", "^(?=.*[a-zA-Z])(?=.*[0-9]).+$") {
				if !`: list destination in rownames'  {
					di as err "{bf:`destination'} is not in the list of matrix rownames: " "{bf:`rownames'}"
					exit 198
				}
				else {
					local i : list posof "`destination'" in rownames
					local holdout = `i'
				}
			}				
			else {
				di as err "`destination' is not in the list of matrix rownames or a row number"
				exit 198
			}
			
			mata: afpt(`holdout', "`anything'")
			
			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %6.3f 
						
			local title title(`title')	
						
			// assign original rownames and colname that corresponds to the destination  
			matrix rownames afpt_full = `rownames'
			local colfind : word `holdout' of `rownames'
			matrix colnames afpt_full = `colfind'
		
			matlist afpt_full,  border(top bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(`format') `title'

			// save matrix
			return matrix mfpt = afpt_full

end


version 11.0
mata:
mata clear
void function afpt(real holdout, string scalar stata_matrixname)

{

		real matrix A
        
		// Convert Stata matrix to Mata		
		A = st_matrix(stata_matrixname)

		// Indices of row and column to delete
		row_to_delete = holdout
		col_to_delete = holdout

		// Get dimensions
		nrows = rows(A)
		ncols = cols(A)

		// Delete row
		if (row_to_delete == 1) {
			B = A[2..nrows, .]
		}
		else if (row_to_delete == nrows) {
			B = A[1..nrows-1, .]
		}
		else {
			B = A[1..row_to_delete-1, .] \ A[row_to_delete+1..nrows, .]
		}

		// Delete column
		if (col_to_delete == 1) {
			Q = B[., 2..ncols]
		}
		else if (col_to_delete == ncols) {
			Q = B[., 1..ncols-1]
		}
		else {
			Q = B[., 1..col_to_delete-1], B[., col_to_delete+1..ncols]
		}

		// create matrix with diag = 1
		I = J(nrows-1, 1, 1)
		I = diag(I)

		// subtract the probs from 1
		I_minus_Q = I - Q

		// get the inverse
		fundamental_matrix = luinv(I_minus_Q)

		// summing the rows gives us the AFPT
		afpt = rowsum(fundamental_matrix)

		// produce zeros for same state
		afpt_full = vec(J(nrows, 1, (0)))'
		// find the position where to replace vector with AFPT
		replace_pos = select(1..nrows, (1..ncols) :!= row_to_delete)
		// the full MFPT whcih includes zeros for the same state
		afpt_full[1, replace_pos] = afpt'

		// save as Stata matrix
		st_matrix("afpt_full", afpt_full')
}
end