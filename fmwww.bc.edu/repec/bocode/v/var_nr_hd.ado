program define var_nr_hd, rclass
version 16.0

	syntax , VARname(string) OPTname(string) OUTname(string) [SRname(string)]
	
	if "`srname'"=="" {
		mata: `outname' = hd_funct(`varname',`optname')
	}
	else {
		mata: `outname' = sr_analysis_funct("hd",`srname',`optname')
	}
	
end
