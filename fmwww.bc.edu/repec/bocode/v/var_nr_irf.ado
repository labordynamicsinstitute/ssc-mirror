program define var_nr_irf, rclass
version 16.0

	syntax , VARname(string) OPTname(string) OUTname(string) [statamatrix(string) SRname(string)]
	
	if "`srname'"=="" {
		mata: `outname' = irf_funct(`varname',`optname')
	}
	else {
		mata: `outname' = sr_analysis_funct("irf",`srname',`optname')
	}
	
	// create matrix in stata storing IRF values
	if ("`statamatrix'"!=""&"`srname'"=="") {
		// pass IRF matrix to Stata
		loc temploc = ""
		mata: st_matrix("`statamatrix'",irf_to_stmat(`outname',`varname'))
		mata: st_local("temploc",irf_to_stcolnames(`outname',`varname'))
		mat colnames `statamatrix' = `temploc'
		di "IRF stored in Stata matrix {`statamatrix'}"
	}
end


// function to set up matrix in mata
mata:
real matrix function irf_to_stmat(transmorphic scalar irs, struct var_struct scalar v) {
	transmorphic matrix 	outmat
	real scalar 			nn
	// generate matrix by horizontal concatenations of IRFs
	for (nn=1; nn<=v.nvar; nn++) {
		if (nn==1) outmat = asarray(irs,nn)
		else outmat = (outmat,asarray(irs,nn))
	}
	return(outmat)
}
end

// function to set up colnames in mata
mata:
string scalar function irf_to_stcolnames(transmorphic scalar irs, struct var_struct scalar v) {
	string scalar 	colnames
	real scalar 	nn
	real scalar 	pp
	string scalar 	lbl1
	string scalar 	lbl2
	
	// generate column names of IRF matrix; format is "varnn_to_varpp"
	for (nn=1; nn<=v.nvar; nn++) {
		for (pp=1; pp<=v.nvar; pp++) {
			lbl1 = v.plt_lbls[pp]
			lbl2 = v.plt_lbls[nn]
			if (nn==1 & pp==1) colnames = lbl1 + "_to_" + lbl2
			else colnames = colnames + " " + lbl1 + "_to_" + lbl2
		}
	}
	return(colnames)
}
end