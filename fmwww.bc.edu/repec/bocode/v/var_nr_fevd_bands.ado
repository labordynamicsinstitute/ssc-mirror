program define var_nr_fevd_bands, rclass
version 16.0

	syntax , VARname(string) OPTname(string) OUTname(string) [statamatrix(string)]
	
	mata: `outname' = fevd_bands_funct(`varname',`optname')
	
end