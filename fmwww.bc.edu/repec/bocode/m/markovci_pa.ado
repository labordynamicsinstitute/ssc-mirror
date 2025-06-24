*! 1.1.0 Ariel Linden 23Jun2025 // ensure that varname is numeric
								// replaced forvalues with foreach since some variables may have different ranges of values
								// wrote secondary program "getlab" instead of dependency of Ben Jann's "labelsof" 
*! 1.0.0 Ariel Linden 21Jun2025

program markovci_pa, rclass
	version 11

		syntax varname(numeric) , 	///		
		[ LEVel(cilevel)			///	
		FORmat(string) 	]

		quietly {

			tempvar prev
			gen `prev' = `varlist'[_n - 1] 
		
			levelsof `varlist' , local(levels)
			foreach i of local levels {		
				local out `out' predict(outcome(`i'))
			}	
		
			// generate matrices for each state
			foreach i of local levels {
				tempname table`i' prop`i' lcl`i' ucl`i' 
				mlogit `varlist' i.`prev' , level(`level')
				margins if `prev'==`i', `out' level(`level') post
				mat `table`i'' = r(table)
				mat `prop`i'' = `table`i''[1,1...]
				local prop `prop' `prop`i''
				mat `lcl`i'' = `table`i''[5,1...]			
				local lcl `lcl' `lcl`i''
				mat `ucl`i'' = `table`i''[6,1...]			
				local ucl `ucl' `ucl`i''
			}
		
			// generate final matrices
			tempname emprop emlcl emucl
			local prop : subinstr local prop " " " \ ", all 
			mat `emprop' = `prop'
			local lcl : subinstr local lcl " " " \ ", all 
			mat `emlcl' = `lcl'
			local ucl : subinstr local ucl " " " \ ", all 
			mat `emucl' = `ucl'	
	
			if "`format'" != "" { 
				confirm numeric format `format' 
			}
			else local format %9.4f 

			local type (parametric)

			// check if the sequence variable has value labels
			local lab: value label `varlist'
			if `"`lab'"' != "" { 
				getlab `varlist'				
				local names =  r(labels)
				mat rownames `emprop' = `names'
				mat colnames `emprop' = `names'
				mat rownames `emlcl' = `names'
				mat colnames `emlcl' = `names'
				mat rownames `emucl' = `names'
				mat colnames `emucl' = `names'	
			}
			else {
				mat rownames `emprop' = `levels'
				mat colnames `emprop' = `levels'
				mat rownames `emlcl' = `levels'
				mat colnames `emlcl' = `levels'
				mat rownames `emucl' = `levels'
				mat colnames `emucl' = `levels'	
			}		
		
		
		} // end quietly
		
		matlist `emprop', border(all) lines(cell) format(`format')  title(predicted transition probabilities) tindent(1) aligncolnames(center) twidth(8)
		matlist `emlcl', border(all) lines(cell) format(`format')  title(lower "`level'%" confidence limit `type') tindent(1) aligncolnames(center) twidth(8)
		matlist `emucl', border(all) lines(cell) format(`format')  title(upper "`level'%" confidence limit `type') tindent(1) aligncolnames(center) twidth(8)	
	
		// return matrices
		return matrix ucl = `emucl'
		return matrix lcl = `emlcl'
		return matrix prop = `emprop'		

end


// this is based on Benn Jann's -labelsof- command
program getlab, rclass
	version 11
		syntax name

		tempfile fn
		qui label save `labdef' using `"`fn'"'
		tempname fh
		file open `fh' using `"`fn'"', read
		file read `fh' line
		local values
		local labels
		local space
		while r(eof)==0 {
			gettoken value line : line
			gettoken value line : line
			gettoken value line : line
			gettoken value line : line
			gettoken label line : line, parse(", ") match(paren)
			local values "`values'`space'`value'"
			local labels `"`labels'`space'`"`label'"'"'
			file read `fh' line
			local space " "
		}
		file close `fh'
		ret local labels `"`labels'"'
end

