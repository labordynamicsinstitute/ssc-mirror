program define var_nr_fevd, rclass
version 16.0

	syntax , VARname(string) OPTname(string) OUTname(string) [statamatrix(string) SRname(string)]
	
	if "`srname'"=="" {
		mata: `outname' = fevd_funct(`varname',`optname')
	}
	else {
		mata: `outname' = sr_analysis_funct("fevd",`srname',`optname')
	}
	
	// create matrix in stata storing FEVD values
	if ("`statamatrix'"!=""&"`srname'"=="") {
		// pass FEVD matrix to Stata
		loc temploc = ""
		mata: st_matrix("`statamatrix'",fevd_to_stmat(`outname',`varname'))
		mata: st_local("temploc",fevd_to_stcolnames(`outname',`varname'))
		mat colnames `statamatrix' = `temploc'
		di "FEVD stored in Stata matrix {`statamatrix'}"
	}
end

// function to set up matrix in mata
mata:
real matrix function fevd_to_stmat(transmorphic scalar fevd, struct var_struct scalar v) {
	transmorphic matrix 	outmat
	real scalar 			nn
	// generate matrix by horizontal concatenations of IRFs
	for (nn=1; nn<=v.nvar; nn++) {
		if (nn==1) outmat = asarray(fevd,nn)
		else outmat = (outmat,asarray(fevd,nn))
	}
	return(outmat)
}
end

// function to set up colnames in mata
mata:
string scalar function fevd_to_stcolnames(transmorphic scalar fevd, struct var_struct scalar v) {
	string scalar 	colnames
	real scalar 	nn
	real scalar 	pp
	string scalar 	lbl1
	string scalar 	lbl2
	
	// generate column names of FEVD matrix; format is "varpp_to_varnn"
	for (nn=1; nn<=v.nvar; nn++) {
		for (pp=1; pp<=v.nvar; pp++) {
			lbl1 = v.plt_lbls[pp]
			lbl2 = v.plt_lbls[nn]
			if (nn==1 & pp==1) colnames = lbl2 + "_to_" + lbl1
			else colnames = colnames + " " + lbl2 + "_to_" + lbl1
		}
	}
	return(colnames)
}
end