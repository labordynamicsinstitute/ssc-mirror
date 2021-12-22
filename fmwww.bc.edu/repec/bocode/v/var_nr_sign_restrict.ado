program define var_nr_sign_restrict, rclass
version 16.0

	syntax , VARname(string) SRname(string) OPTname(string) OUTname(string) [NSRname(string)]
	
	if ("`nsrname'"=="") {
		mata: `outname' = sign_restrict(`varname',`srname',`optname')
	}
	else {
		mata: `outname' = narr_sign_restrict(`varname',`srname',`optname',`nsrname')
	}
	
end