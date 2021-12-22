program define var_nr_shock_create, rclass
version 16.0

	syntax , VARname(string) SRname(string)
	
	mata: `srname' = shock_create(`varname')

end