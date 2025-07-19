*! 1.0.0 Ariel Linden 05Jul2025 

program markovfutureprob_all, rclass
	version 11.0
		syntax anything [ , PERiod(real 2) FORmat(string) TITle(string) ]

		quietly {
			local rows = rowsof(`anything')

			forvalues i = 1/`rows' {
				tempname futureprob`i'
				markovfutureprob_ind `anything', current(`i') period(`period')
				mat `futureprob`i'' = r(futureprobs)
				local futureprob `futureprob' `futureprob`i''	
			}
			
			local futureprob : subinstr local futureprob " " " \ ", all 
			tempname futureprob_all
			mat `futureprob_all' = `futureprob'

			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %6.3f 
			
			local title title(`title')			
			
		} // end quietly	

		matlist `futureprob_all',  border(top bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(`format') `title'
		
		// save matrix
		return matrix futureprob = `futureprob_all'
		
end		