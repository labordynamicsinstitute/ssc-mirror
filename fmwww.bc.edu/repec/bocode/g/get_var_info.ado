// Program to get var characteristics
// Author Christiaan Righolt
// Version history
// 1.0	Dec 2022	Initial version

program define get_var_info, rclass
	syntax varname(fv)
	// Categorical if string OR i. OR val label
	// Else continuous

	local dot_pos = strpos("`varlist'",".")
	local base_name = substr("`varlist'",`dot_pos'+1,.)
	loca pre_dot = substr("`varlist'",1,`dot_pos'-1)

	if "`pre_dot'"=="i" {
		local is_i_dot = 1
		quietly levelsof(`base_name'), local(var_levels)
		local base_level : word 1 of `var_levels'
	}
	else if substr("`pre_dot'",1,2)=="ib" { // Stata converts bNi. into ibN.
		local is_i_dot = 1
		local base_level = substr("`pre_dot'",3,.)
	}
	else {
		local is_i_dot = 0
		local base_level = .
	}

	local var_type : type `base_name'
	local is_string = substr("`var_type'",1,3)=="str"

	local val_label : val label `base_name'
	local has_label = !missing("`val_label'")

	if `is_i_dot' | `is_string' | `has_label' return local type = "cat"
	else return local type = "cont" 

	return local is_i_dot = `is_i_dot'
	return local is_string = `is_string'
	return local base_name = "`base_name'"
	return local base_level = `base_level'
end
