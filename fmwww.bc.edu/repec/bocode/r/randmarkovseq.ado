*! 2.0.0 Ariel Linden 21Apr2025 // changed methodology for generating the sequence
*! 1.0.1 Ariel Linden 04Apr2025 // fixed error coding for row sum = 1
*! 1.0.0 Ariel Linden 26Mar2025 

program randmarkovseq, rclass
		version 11.0
		syntax , 						///
		OBS(integer)					///
		LAbels(string asis)				/// 
		MATrix(string)					///
		[ First(string) 				///
		TRANSition * ]

		quietly {

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
			set obs `obs'
			
			// check that matrix is symmetrical
			if rowsof("`matrix'") != colsof("`matrix'") {
				di as err "the matrix must be symmetrical"
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
					di as err "row `i' of matrix `matrix' does not sum to 1. Sum = " row_sum
					exit 198
				}
			}

			
			tempname state
			
			// start sequence by using "first" (either specified or randomly chosen)
			if "`first'" == "" {
				scalar `state' = runiformint(1,rowsof(`matrix'))
			}
			else {
				scalar `state' = `k'
			}
			
			// gen the variable sequence
			gen sequence = .
			
			// first run of sequence
			mata: state = st_numscalar("`state'")
			mata: `matrix' = st_matrix("`matrix'")

			// remaining runs of sequence up to N
			forvalues i = 1/`obs' {
				mata row = `matrix'[state,]
				mata: next = rdiscrete(1, 1, (row))
				mata: seqval = next[1,1]
				mata: st_numscalar("seqval", seqval)
	
				replace sequence = seqval in `i'
				mata: state = next
			}
				
			// label labels with those provided by user
			tokenize `labels'
			forval i = 1/`labcnt' { 
				label define labels `i' `"``i''"', add 
			} 
			forval j = 1/`labcnt' { 
				label values sequence labels
 
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
