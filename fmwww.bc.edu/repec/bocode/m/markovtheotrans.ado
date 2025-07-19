*! 1.1.0 Ariel Linden 07Jul2025 // fixed labeling of tables to mirror value labels of sequence variable
*! 1.0.0 Ariel Linden 17Jun2025 

program markovtheotrans, rclass
		version 11.0
			syntax varname,	trans(string)

				// generate transition table
				tempvar prev table
				qui gen `prev' = `varlist'[_n-1]
				label var `prev' "current"
				local lblname : value label `varlist'
				label values `prev' `lblname'
				tab `prev' `varlist', row matcell(`table')
				
				local rcnt = r(r)
				local ccnt = r(c)
			
				// check that matrix "table" is symmetrical
				if rowsof("`table'") != colsof("`table'") {
					di as err "the matrix must be symmetrical"
					exit 198        
				}

				// check that matrix "trans" is symmetrical
				if rowsof("`trans'") != colsof("`trans'") {
					di as err "the matrix {bf:`trans'} must be symmetrical"
					exit 198        
				}
				
				// verify that the empirical and theoretical matrices have the same number of rows and columns 
				if rowsof("`trans'") ! = `rcnt' {
					di as err "the transition probabilities matrix {bf:`trans'} does not have the same number of rows as in the empirical table"
				}
				
				if colsof("`trans'") ! = `rcnt' {
					di as err "the transition probabilities matrix {bf:`trans'} does not have the same number of columns as in the empirical table"
				}
				
				// check if the sequence variable has value labels
				local lab: value label `varlist'
				if `"`lab'"' != "" { 
					getlab `varlist'                                
					local names =  r(labels)
					mat rownames `trans' = `names'
					mat colnames `trans' = `names'
				}	

				di _n
				local title2 title(Theoretical transition probabilities)
				matlist `trans',  border(bottom) lines(oneline) tindent(10) left(10) aligncolnames(ralign) names(all)  twidth(8) format(%6.3f) `title2'

				// get chisq and df from mata
				mata: theor("`table'", "`trans'")
				
				local pval =  1-chi2(`df',`chisq')
				di as txt _n "            chi2({bf:`df'}) = " as result %6.4f `chisq' as txt "   Pr = " as result %5.3f `pval'
				
                // return values
                return scalar r = `rcnt'
                return scalar c = `ccnt'
                return scalar chi2 = `chisq'
                return scalar p = `pval'

end

		version 11.0
		mata:
		mata clear
		void function theor(string scalar stata_matrixdata, string scalar stata_matrixtrans)

		{

			data = st_matrix(stata_matrixdata)
			trans = st_matrix(stata_matrixtrans)
	
			col_sums = colsum(data)	  
			nrows = rows(data)
			ncols = cols(data)

			chisq = 0
			for (i = 1; i <= nrows; i++) {
				for (j = 1; j <= ncols; j++) {
					chisq = chisq + data[i, j] * log(data[i,j]/(col_sums[i] * trans[i, j]))
				}
			}   
	
			chisq = chisq * 2

			nnull = sum(object :== 0)
			df = (nrows * (ncols - 1)) -  nnull

			st_local("chisq", strofreal(chisq))
			st_local("df", strofreal(df))	
		}
	
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
