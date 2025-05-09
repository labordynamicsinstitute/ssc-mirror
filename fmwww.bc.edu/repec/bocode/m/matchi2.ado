*! 1.0.1 Ariel Linden 07May2025 // added the "title" option
*! 1.0.0 Ariel Linden 03May2025 

program matchi2, rclass
		version 11.0
		syntax anything [, TITle(string)]    
		
		local count : word count `anything'
		if (`count' > 1) exit = 103

		local nrows = rowsof(`anything')
		local ncols = colsof(`anything')
		
		if `nrows' < 2 {
			di as err "the matrix must have at least 2 rows"
			exit 198
		}
		
		local df = (`nrows' - 1) * (`ncols' - 1)
		mata: matchi("`anything'")
		local pval =  1-chi2(`df',`chisq')
		
		local title title(`title')
		matlist `anything',  border(bottom) lines(oneline) tindent(1) aligncolnames(ralign) twidth(8) format(%6.0f) `title'
		
		di as txt _n "   Pearson chi2({bf:`df'}) = " as result %6.4f `chisq' as txt "   Pr = " as result %5.3f `pval'
		
		// return values
		return scalar r = `nrows'
		return scalar c = `ncols'
		return scalar chi2 = `chisq'
		return scalar p = `pval'
		
end		
		
version 11.0
mata:
mata clear
void function matchi(string scalar stata_matrixname)

{

	real matrix X
	real scalar chisq
	
    X = st_matrix(stata_matrixname)
	
	nrows = rows(X)
	ncols = cols(X)
	row_sums = rowsum(X)
	col_sums = colsum(X)'
	total = sum(row_sums)
	
	expected = (row_sums * col_sums') / total
	
    chisq = 0
    for (i = 1; i <= nrows; i++) {
        for (j = 1; j <= ncols; j++) {
            chisq = chisq + (X[i,j] - expected[i,j])^2 / expected[i,j]
        }
    }	
	st_local("chisq", strofreal(chisq))
}
end
