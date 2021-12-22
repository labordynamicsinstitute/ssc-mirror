program define var_nr_irf_bands, rclass
version 16.0

	syntax , VARname(string) OPTname(string) OUTname(string) [statamatrix(string)]
	
	mata: `outname' = irf_bands_funct(`varname',`optname')
	
end