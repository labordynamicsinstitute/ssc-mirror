*! 1.0.1 Ariel Linden 12May2025 // replaced tostring with decode for variables with labels 
*! 1.0.0 Ariel Linden 08May2025 

program markovfirstorder, rclass
	version 11.0
	syntax varname [, NOIsily]  

	quietly {	

		// create a copy of the sequence variable to ensure consecutive numbering (and proper labeling)
		// if string  
		capture confirm numeric variable `varlist'
		tempvar new_seq2 sequence
		if _rc != 0 {
			encode `varlist', gen(`sequence')
			levelsof `sequence'
			local scnt = r(r)
			local lbls
			forvalues i = 1/`scnt' {
				local lbl : label (`sequence') `i'
				local lbls `" `lbls' "`lbl'" "'
			}	
		} // end if sequence is a string
		// if numeric
		else if _rc == 0 {
			if "`: value label `varlist''" != "" {
				decode `varlist', gen(`new_seq2') // to get labels, not underlying numeric values
				encode `new_seq2', gen(`sequence')
				levelsof `sequence'
				local scnt = r(r)
				local lbls
				forvalues i = 1/`scnt' {
					local lbl : label (`sequence') `i'
					local lbls `" `lbls' "`lbl'" "'
				}
			}	
			else {
				tostring `varlist', gen(`new_seq2')
				encode `new_seq2', gen(`sequence')
				levelsof `varlist', local(levels)	
				local lbls
				foreach i of local levels {
					local lbl  `i'
					local lbls `lbls' `lbl'				
				}
			}
		}	
		
		// generate independent state Markov chain
		tempvar present
		tempname XX mat matfull
		gen `present' = `varlist'[_n+1]
		tab `varlist' `present', matcell(`XX')
		mat rownames `XX' = `lbls' 
		mat colnames `XX' = `lbls' 
		nois matchi2 `XX', title(Independent state frequency table)		
		
		
		// generate first order Markov chain 
		levelsof `sequence', local(states)
		local n2 = r(N) - 2		
		local nelements = r(r)

		local tstat = 0
		matrix `matfull' = J(`nelements', `nelements', 0)
		foreach l of local states {
			local a : word `l' of `lbls'
			matrix `mat' = J(`nelements', `nelements', 0)
			mat rownames `mat' = `lbls' 
			mat colnames `mat' = `lbls' 
			forvalues i = 1 / `n2' {
				if `l' == `sequence'[`i' + 1] {
					local past = `sequence'[`i']
					local future = `sequence'[`i' + 2]
					mat `mat'[`past', `future'] = `mat'[`past', `future'] + 1
				}
			} // end forvals 1/n-2
			// gen composite matrix
			mat `matfull' = `matfull' + `mat'
	
			// gen chi2 from each matrix
			`noisily' matchi2 `mat', title(First order frequency table for state `a')
			local tstat = `tstat' + r(chi2)
			local k = `nelements'
			local df = `k' * (`k' - 1)^2
			local pval =  1-chi2(`df',`tstat')
		} // end foreach state

	} // quietly
	
	mat rownames `matfull' = `lbls' 
	mat colnames `matfull' = `lbls' 
	matlist `matfull',  border(bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(%6.0f) title(First order Markov chain frequency table)
    di as txt _n "   Pearson chi2({bf:`df'}) = " as result %6.4f `tstat' as txt "   Pr = " as result %5.3f `pval'
	
	// generate matrix of row probabilities
	mata: B = st_matrix("`matfull'")          
	mata: r = rows(B)
	mata: c = cols(B)
	mata: rowsum = rowsum(B)
	mata: rowprobs = J(r, c, 0)
	mata: rowprobs = (B:/rowsum)
	mata: st_matrix("rowprobs", rowprobs)
	mat rownames rowprobs = `lbls' 
	mat colnames rowprobs = `lbls' 
	
	// return results
	return scalar p = `pval'
	return scalar chi2 = `tstat'
	return matrix rowprobs = rowprobs
	return matrix table = `matfull'


end		