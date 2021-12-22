program define var_nr_narr_create, rclass
version 16.0

	syntax , VARname(string) NSRname(string)
	
	mata: `nsrname' = nr_create(`varname')

end