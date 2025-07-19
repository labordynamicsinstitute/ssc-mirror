*! 1.0.0 Ariel Linden 04Jul2025 

program markovmeanrecurrence, rclass
		version 11.0
		
		syntax anything  [, FORmat(string) ]
					
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
			
			
			mata: recurr("`anything'")
			
			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %6.3f 
						
			// assign original colnames to states  
			matrix colnames meanrecurr = `colnames'
			matrix rownames meanrecurr = Time
		
			matlist meanrecurr,  border(top bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(`format') title(Markov chain mean recurrence time)

			// save matrix
			return matrix meanrecurr = meanrecurr

end


version 11.0
mata:
mata clear
void function recurr(string scalar stata_matrixname)

{

		real matrix A
        
		// Convert Stata matrix to Mata		
		A = st_matrix(stata_matrixname)

		// Get dimensions
		nrows = rows(A)

		// transpose the matrix
		at = A'

		// create matrix with diag = 1
		I = diag(J(nrows, 1, 1))

		// Subtract identity matrix
		Q = (at - I)

		// add contstraints
		c = J(1, nrows, 1)
		Q = Q \ c
		b = J(1, nrows, 0)
		b = b , 1

		// solve the system of steady states
		steadystate = qrsolve(Q,b')
		L = J(nrows, 1, 1)
		meanrecurr = L :/ steadystate

		// save as Stata matrix
		st_matrix("meanrecurr", meanrecurr')
}
end