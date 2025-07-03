*! 1.0.0 Ariel Linden 01Jul2025 

program markovmfpt_all, rclass
	version 11.0
		syntax anything [ , FORmat(string) TITle(string) ]

		quietly {
			local rows = rowsof(`anything')

			forvalues i = 1/`rows' {
				tempname afpt`i'
				markovmfpt_ind `anything', dest(`i')
				mat `afpt`i'' = r(mfpt)
				local afpt `afpt' `afpt`i''	
			}
	
			local afpt : subinstr local afpt " " " , ", all 
			tempname afpt_all
			mat `afpt_all' = `afpt'

			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %6.3f 
			
			local title title(`title')			
			
		} // end quietly	

		matlist `afpt_all',  border(top bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(`format') `title'
		
		// save matrix
		return matrix mfpt = `afpt_all'
		
end		