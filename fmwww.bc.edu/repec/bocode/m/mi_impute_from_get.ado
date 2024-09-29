*! v.1.0.0 2024Sept17 Orsini N. & Thiesmeier R. 

capture program drop mi_impute_from_get
program define mi_impute_from_get, rclass
version 18.0
syntax [anything] [, b(string) v(string) colnames(string) tf(string) imodel(string) VALues(numlist integer) path(string) ]

	tempname get_b get_V

	local np_b: word count `b'
	local np_v: word count `v'
	local np : word count `colnames'
	local nr_values: word count `values'
	
	if (`np_b' != `np_v') {
			di as err "The number of files in options b() and v() needs to be the same"
			exit 198
	}
	
	if "`tf'" == "" local fmt "txt"
	if "`tf'" == "excel" local fmt "xlsx"
	if "`tf'" == "delimited" local fmt "txt"
	
	preserve
		
	// Get b 
	forv i = 1/`np_b' {
		tempname get_b_`i'
		local file_name: word `i' of `b'
		if "`fmt'" == "xlsx" quietly import excel using "`path'`file_name'.`fmt'", clear 
		if "`fmt'" == "txt" quietly import delimited using "`path'`file_name'.`fmt'", clear 
		qui mkmat * , matrix(`get_b_`i'')		
	}

	local nr_cols : colsof `get_b_1'
	
	if "`imodel'" == "mlogit" {
		if "`values'"=="" {
				di as err "specify the values() option"
				exit 198
		}
	}
		
	/*
	if "`imodel'" == "mlogit" {
		local nr_eqs = `nr_cols'/`np'
		if `nr_eqs' != `nr_values' {
				di as err "check the b vector, it should be 1 by (`np'*`nr_values')"
				exit 198
		}
	}
	
	if "`imodel'" == "qreg" {
		local nr_eqs = `nr_cols'/`np'
		if `nr_eqs' != 99 {
				di as err "check the b vector, it should be 1 by (`np'*99)"
				exit 198
		}
	
	}
	*/
	
	// Get V 

	forv i = 1/`np_v' {
		tempname get_v_`i'
		local file_name: word `i' of `v'
		if "`fmt'" == "xlsx" quietly import excel using "`path'`file_name'.`fmt'", clear 
		if "`fmt'" == "txt"  quietly import delimited using "`path'`file_name'.`fmt'", clear 
		qui mkmat * , matrix(`get_v_`i'')
		}

	// If one file 
	
	mat `get_b' = `get_b_1'
	mat `get_V' = `get_v_1'
	
	// Otherwise combine using IWLS 
	
	if (`np_b'>1) {
		
		// Set the names of the b and V 
		local list_name_b ""
		forv i = 1/`nr_cols' {
			local list_name_b "`list_name_b' y`i'"
		}
				
		local list_name_V ""
		local tot_nr_V = `nr_cols'
		forv i = 1/`tot_nr_V' {
			local list_name_V "`list_name_V' V`i'"
		}
		capture frame drop mv_imputation study
		frame create mv_imputation study `list_name_b' `list_name_V'
		// For each study post reg coef and var/cov 
		forv t = 1/`np_b' {
				local post_est_b_`t' ""
				local post_est_V_`t' ""
				
				forv i = 1/`nr_cols' {
					local post_est_b_`t' "`post_est_b_`t'' (`=`get_b_`t''[1,`i']')"
				}	
				forv i = 1/`nr_cols' {
						local post_est_V_`t' "`post_est_V_`t'' (`=`get_v_`t''[`i',`i']')"
				}
				frame post mv_imputation (`t') `post_est_b_`t'' `post_est_V_`t''
		}
 
	mat `get_b' = J(1, `nr_cols', 0)
	mat `get_V' = J(`nr_cols', `nr_cols', 0)

	 frame mv_imputation {
			* univariate meta-analysis for each regression coefficient using IVWLS
			  quietly forv i = 1/`nr_cols' {
					 
					if (y`i'[1] != 0 & V`i'[1] != 0)  {
						regress y`i' [iw=1/V`i'] , mse1
						mat `get_b'[1, `i'] = _b[_cons]
						mat `get_V'[`i', `i'] = _se[_cons]^2
					}
					else {
						mat `get_b'[1, `i'] = 0
						mat `get_V'[`i', `i'] = 0	
					}
				}	
	}
	
	}
	
	local set_colnames "`colnames'"
	local set_eqnames ""

	if "`imodel'" == "qreg" {
		forv i = 2/99 {
			local set_colnames "`set_colnames' `colnames'"
		}
		
		forv i = 1/99 {
			forv j = 1/`np' {
				local set_eqnames "`set_eqnames' q`i': "
			}
		}
	}
	
 	if "`imodel'" == "mlogit" {
		forv i = 2/`nr_values' {
			local set_colnames "`set_colnames' `colnames'"
		}
		
		foreach i of local values {
			forv j = 1/`np' {
				local set_eqnames "`set_eqnames' `i': "
			}
		}
	}
	
	matrix colnames `get_b' = `set_colnames'
	matrix coleq `get_b' = `set_eqnames'
	matrix colnames `get_V' = `set_colnames'
	matrix rownames `get_V' = `set_colnames'
	matrix roweq `get_V' = `set_eqnames'
	matrix coleq `get_V' = `set_eqnames'
	return matrix get_ib = `get_b'
	return matrix get_iV = `get_V'
	
	restore 
end
