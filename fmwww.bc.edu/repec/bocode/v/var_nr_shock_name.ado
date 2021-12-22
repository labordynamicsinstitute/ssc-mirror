program define var_nr_shock_name, rclass
version 16.0

	syntax , LABels(string) SRname(string)
	
	loc wc = length("`labels'") - length(subinstr("`labels'",",","", .)) + 1
	loc tc = `wc'+`wc'-1
	
	mata: var_nr_temp_nsr_labels_matrix = J(1,`wc',"")
	
	tokenize "`labels'", parse(",")
	loc ct = 1
	foreach ii of numlist 1/`tc' {
		if ("``ii''"!=",") {
			mata: var_nr_temp_nsr_labels_matrix[`ct'] = "``ii''"
			loc ct = `ct'+1
		}
	}
	
	mata: shock_name(var_nr_temp_nsr_labels_matrix,`srname')
	mata: mata drop var_nr_temp_nsr_labels_matrix

end