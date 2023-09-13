
capture program drop ssci
program define ssci, eclass 
	version 12.1
	
	/*INPUT SYNTAX*/
	syntax varlist(max=1)					///
		[,									///  
		type(string)						///
		alpha(real 0.05) 					///
		above(namelist)						///
		below(namelist)						///
		bounds(string)						///
		]	
	
	/* INPUTTING Y AND SIGMA */
	tempname Y
	matrix `Y' = e(b)
	local len = colsof(`Y')
	local names: colnames `Y'

	tempname Sigma
	matrix `Sigma' = e(V)
	matrix colnames `Sigma' = `names'
	matrix rownames `Sigma' = `names'
		
	/*CHECKING THAT VARS ARE IN REG OUTPUT*/
	local x = 0
	foreach name of local names{	
		if "`name'" == "`varlist'"{
			local x = 1
		}
		if "`name'," == "`varlist'"{
			local x = 1
		}
	}
	if `x' == 0 {
		display as error _newline(1) ///
		"`varlist' omitted from regression" 
		local codebreak = 1
		exit 111
	}
	foreach var of local below{
		local x = 0
		foreach name of local names{	
			if "`name'" == "`var'"{
				local x = 1
			}
			if "`name'," == "`var'"{
				local x = 1
			}
		}
		if `x' == 0 {
			display as error _newline(1) ///
			"variable `var' from below() not found in last estimates..." _newline(1) ///
			"possibly either not included or omitted in regression"
			exit 111
		}
	}
	foreach var of local above{
		local x = 0
		foreach name of local names{	
			if "`name'" == "`var'"{
				local x = 1
			}
			if "`name'," == "`var'"{
				local x = 1
			}
		}
		if `x' == 0 {
			display as error _newline(1) ///
			"variable `var' from above() not found in last estimates..." _newline(1) ///
			"possibly either not included or omitted in regression" 
			exit 111
		}
	}
	//

	
	
	
	/*INDEX NUMBER*/
	tokenize `varlist', parse(" ,")
	local index = colnumb(`Y',"`1'")



	
	/*TYPE*/
	if "`type'" != "" & "`type'" != "two-sided" & "`type'" != "upper" & "`type'" != "lower" & "`type'" != "1" & "`type'" != "0" & "`type'" != "-1" {
		display as error _newline(1) ///
		"type needs to be two-sided, upper, or lower!"
		exit 198
	}
	
	if "`type'" == ""{
		local type = "two-sided"
	}
	if "`type'" == "two-sided"{
		local type = 0
	}
	if "`type'" == "upper"{
		local type = 1
	}
	if "`type'" == "lower"{
		local type = -1
	}
	//
	


	
	/*BOUNDED*/
	tempname m_bounded
	matrix `m_bounded' = J(1,`len',0)
	matrix colnames `m_bounded' = `names'

	foreach var of local above{
		local c = colnumb(`Y', "`var'")
		matrix `m_bounded'[1,`c'] = -1
	} 
	foreach var of local below{
		local c = colnumb(`Y', "`var'")
		matrix `m_bounded'[1,`c'] = 1
	}
	//
	
	

	
	/*BOUNDS*/
	tempname m_bounds
	matrix `m_bounds' = J(1,`len',0)
	matrix colnames `m_bounds' = `names'
	
	foreach bound of local bounds{
		tokenize `bound', parse("=")
		local c = colnumb(`Y', "`1'")
		
		if "`3'" == ""{
			display as error _newline(1) ///
			"Invalid Syntax for bounds()" _newline(1) ///
			"Make sure there are not extra spaces between the var and its bound, only an = sign."
			exit 198
		}

		local x = "`3'"
		capture confirm number `x'
		if _rc==7{
			display as error _newline(1) ///
			" Invalid syntax for option bounds()" _newline(1) ///
			" '`x'' found where number expected."
			exit 7
		}
		
		matrix `m_bounds'[1,`c'] = `3'
	}
	//

	

	
	/*CHECKING Alpha*/
	if `alpha' != .05 & `alpha' != .01 & `alpha' != .1 {
		display as error _newline(1) ///
		"Alpha needs to be in the set {0.1, 0.05, 0.01}!"
		exit 175
	}
	//

	
	
	
	/*READ IN POLYNOMIAL COEFFICIENTS (copy-pasted from paper)*/
	if `type' == 1 | `type' == -1 {
		if `alpha' == 0.01 {
			local poly_coef_local = "2.3241 2.5073 -19.6229 65.0489 -122.0242 112.9814 -40.9895"
		}
		if `alpha' == 0.05 {
			local poly_coef_local = "1.6385 2.4813 -16.1007 52.6998 -98.9348 91.7646 -33.3628"
		}
		if `alpha' == 0.1 {
			local poly_coef_local = "1.2726 2.4250 -14.1041 46.0326 -86.7946 80.8189 -29.4840"
		}
	}
	else{
		if `alpha' == .01 {
			local poly_coef_local = "2.5710 1.1854 -16.4621 63.1856 -128.0372 123.3096 -45.5050 1.4378 -1.1672 -2.1843 8.4153 -9.2032 3.1479 -4.7977 3.6035 -2.6765 1.0849 -0.3625 12.2591 -2.5234 0.8411 0.7850 -20.5823 0.2467 -0.6847 18.2815 0.6751 -6.5866"
		}
		
		if `alpha' == .05 {
			local poly_coef_local = "1.9540 1.1289 -12.2929 45.6505 -92.3587 89.5045 -33.3683 1.3388 -0.8006 0.0090 0.5939 -1.0048 0.2851 -4.5110 1.1262 0.9084 0.8153 -0.9854 11.7294 -1.1742 -3.2329 1.7625 -18.8756 2.1281 0.1723 15.5342 -0.5511 -5.2786"
		}
		
		if `alpha' == .1 {
			local poly_coef_local = "1.6348 1.2271 -11.7243 43.6253 -87.8291 84.6893 -31.4176 1.2890 0.0224 -2.0585 3.2898 -2.6854 0.5102 -4.8501 -0.6555 3.7550 -1.7097 0.6640 14.0485 0.7875 -5.0051 1.1221 -23.9082 1.0308 1.5399 20.3891 -0.5813 -7.0186" 
		}
	}	
	local size : list sizeof poly_coef_local
	tempname poly_coef
	matrix `poly_coef' = J(1,`size',0)
	forvalues i = 1/`size'{
		local a : word `i' of `poly_coef_local'
		matrix `poly_coef'[1,`i'] = `a'
	}
	//

	
	
		
	/*DROP ENTRIES THAT ARE NOT BOUNDED*/
	
	//Dealing with Y
	local tool = 0
	if `index' > 1 {													// tool = number of `m_bounded'(1:index-1) that = 0
		local a = `index'-1
		forvalues i = 1/`a'{
			if `m_bounded'[1,`i'] == 0{
				local tool = `tool' + 1
			}
		}
	}
	local new_index = `index' - `tool'

	tempname keep
	matrix `keep' = J(1,`len',0)
	matrix colnames `keep' = `names'

	forvalues i = 1/`len'{												// Keep = 1 whenever `m_bounded' != 0 and 0 else.
		if `m_bounded'[1,`i'] != 0{
			matrix `keep'[1,`i']=1
		}
	}
	matrix `keep'[1,`index'] = 1										// Keep also = 1 at `index' entry 
		
	local keep_len = 0													// number of vars kept
	foreach i in `names'{
		local col_var_i = colnumb(`Y',"`i'")
		if `keep'[1,`col_var_i'] ==1{
			local keep_len = `keep_len' + 1
			local keep_names `keep_names' `i'
		}
	}

	tempname Ynew
	matrix `Ynew' = J(1,`keep_len',0)									// Dropping unbounded Y entries
	local a = 0
	local b = 0
	forvalues i = 1/`keep_len'{
		local b = `i' + `a' 
		while `keep'[1,`b'] == 0{
			local a = `a' + 1
			local b = `i' + `a'
		}
		matrix `Ynew'[1,`i'] = `Y'[1,`b']
	}
	matrix `Y' = `Ynew'
	matrix colnames `Y' = `keep_names'
			
			
	local len = colsof(`Y')												// Updating index and len 
	tokenize `varlist', parse(" ,")
	local index = colnumb(`Y',"`1'")
	
	
	//Dealing with Sigma
	tempname Snew
	matrix `Snew' = J(`keep_len',`keep_len',0)
	local ar = 0
	local ac = 0
	local br = 0
	local bc = 0
	forvalues r = 1/`keep_len'{											// Dropping unbounded Y entries from Omega		
		local ac = 0 //reset for each row
		
		local br = `r' + `ar'
		while `keep'[1,`br'] == 0{
			local ar = `ar' + 1
			local br = `r' + `ar'
		}
		
		forvalues c = 1/`keep_len'{
			
			local bc = `c' + `ac'
			while `keep'[1,`bc'] == 0{
				local ac = `ac' + 1
				local bc = `c' + `ac'
			}
			
			matrix `Snew'[`r',`c'] = `Sigma'[`br',`bc']
		}
	}
	matrix `Sigma' = `Snew'
	
	
	// Dealing with bounds and bounded
	tempname m_bounds_old
	tempname m_bounded_old
	matrix `m_bounds_old' = `m_bounds'
	matrix `m_bounded_old' = `m_bounded'
	matrix `m_bounds' = J(1,`len',.)
	matrix `m_bounded' = J(1,`len',.)
	matrix colnames `m_bounds' = `keep_names'
	matrix colnames `m_bounded' = `keep_names'

	foreach i in `keep_names'{
		local new = colnumb(`m_bounds', "`i'")
		local old = colnumb(`m_bounds_old', "`i'")
		matrix `m_bounded'[1,`new'] = `m_bounded_old'[1,`old']
		matrix `m_bounds'[1,`new'] = `m_bounds_old'[1,`old']
	} 
	//

	
	
	
	/*NORMALIZE NUISANCE PARAMETERS*/
	// Normalize nuisance parameters to be bounded below by zero and accomodate
	// lower one-sided CI 
	matrix `m_bounds'[1,`index'] = 0	
	matrix `Y' = `Y' - `m_bounds'

	if `type' == 1 {
		matrix `m_bounded'[1,`index'] = 1
	}
	if `type' == -1 {
		matrix `m_bounded'[1,`index'] = -1
	}
	tempname tool
	matrix `tool' = `m_bounded'
																
	forvalues i = 1/`len'{												//Replace tool = 1 if `m_bounded' ==0
		if `m_bounded'[1,`i'] == 0 {
			matrix `tool'[1,`i']==1 
		}
	}
	tempname Y2
	matrix `Y2' = `Y'
	forvalues i = 1/`len'{												//Element-wise multiplication
		matrix `Y'[1,`i'] = `tool'[1,`i']*`Y2'[1,`i']
	}
	matrix `Sigma' = diag(`tool')*`Sigma'*diag(`tool')
	
	
	
	
	/*NORMALIZE Y TO HAVE UNIT VARIANCES*/
	tempname std_err
	matrix `std_err' = J(`len',`len',0)									//Square root of sigma
	forvalues i = 1/`len' {
		matrix `std_err'[`i',`i'] = sqrt(`Sigma'[`i',`i'])
	}
	matrix `std_err' = vecdiag(`std_err')								//Taking only diagonals 

	matrix `Y' = inv(diag(`std_err'))*`Y'' 								//Y is now Standardized 
	matrix `Y' = `Y'' 													//Keeping Y as row vector	

	tempname Omega
	matrix `Omega' = inv(diag(`std_err'))*`Sigma'*inv(diag(`std_err')) 	//Correlation matrix
	
	
	
	
	
	/*CREATE Y_b*/

	local Y_b = `Y'[1, `new_index']										// Y_b is the coefficient of interest											
	tempname tool2
	matrix `tool2' = J(`keep_len',`keep_len',1)							// tool 2 is off diag 1, on diag 0
	forvalues i = 1/`keep_len'{
		matrix `tool2'[`i',`i'] = 0
	}
	tempname tool
	matrix `tool' = J(1,`keep_len',.)
	forvalues i = 1/`keep_len'{
		matrix `tool'[1,`i'] = `tool2'[`new_index',`i']					// keeping only new index row from tool2
	}
	//
	
	
	
	
	/*CREATE CONFIDENCE INTERVAL IF ALL VARS UNBOUNDED*/
	if `keep_len' == 1{
		if `type' == 0{
			local lb = `Y_b' - invnormal(1-`alpha'/2)
			local ub = `Y_b' + invnormal(1-`alpha'/2)
		}
		if `type' == 1{
			local lb = `Y_b' - invnormal(1-`alpha')
			local ub = . 
		}
		if `type' == -1{
			local lb = .
			local ub = -(`Y_b' - invnormal(1-`alpha'))
		}
	}
	else{
		
		
		
		
		
		/*CREATE Y_d, Omega_bd AND Omega_dd*/

		local ld = `keep_len' -1
		tempname Omega_bd
		matrix `Omega_bd' = J(1,`ld', .)

		local a = 0
		forvalues i = 1/`ld'{
			if `tool'[1,`i'] == 0{
				local a = `a' + 1
			}
			local b = `i' + `a'
			matrix `Omega_bd'[1,`i'] = `Omega'[`new_index', `b']
		}	
		
		tempname Omega_dd
		matrix `Omega_dd' = J(`ld', `ld', .)
		local ar = 0
		local ac = 0
		local br = 0
		local bc = 0
		forvalues r = 1/`ld'{											// Omega_dd is values of Omega not in row or column of new index (std error for controls d)
			local ac = 0  
			if `r' == `new_index'{
					local ar = `ar' + 1
			}
			
			forvalues c = 1/`ld'{
				
				if `c' == `new_index'{
					local ac = `ac' + 1
				}
				local bc = `c' + `ac'
				local br = `r' + `ar'
				matrix `Omega_dd'[`r',`c'] = `Omega'[`br',`bc']
			}
		}
		local a = 0														// Y_dd is only control coefficients 
		tempname Y_d
		matrix `Y_d' = J(1,`ld',.)
		forvalues i = 1/`ld'{
			local b = `i' + `a'
			while `b' == `new_index'{
				local a = `a' + 1
				local b = `i' + `a'
			}
			matrix `Y_d'[1, `i'] = `Y'[1, `b']
		}
		//
		
		
		
		
		/*CONFIDENCE INTERVALS*/
		local n_ss = 2^`ld'
		numlist "1/`ld'"
		_ffdtcomb, n(`ld') elist("`r(numlist)'")						// Creating power set of subsets 

		
		
		
		/*One Sided CI*/
		if abs(`type') == 1{

			local s_star = 0
			local factor_star = 0
			local omega_star = 0

			forvalues i =1/`r(cmax)' {
				
				local subset = r(v`i')
				local size : list sizeof subset
				tempname Omega_bd_s
				matrix `Omega_bd_s' = J(1,`size',.)						// Omega_bd_s is each subset of variables from Omega_bd
				local c1 = 1
				while `c1' <= `size' {
					foreach c of numlist `subset'{
						matrix `Omega_bd_s'[1,`c1'] = `Omega_bd'[1,`c']
						local c1 = `c1' + 1
					}
				}
				
				tempname Omega_dd_s
				matrix `Omega_dd_s' = J(`size',`size',.)				// Omega_dd_s is each subset of variables from Omega_dd
				local r1 = 1
				while `r1' <= `size'{
					foreach r of numlist `subset'{	
						local c1 = 1
						while `c1' <= `size'{
							foreach c of numlist `subset'{
								matrix `Omega_dd_s'[`r1',`c1'] = `Omega_dd'[`r',`c']
								local c1 = `c1' + 1
							}
						local r1 = `r1' + 1
						}	
					}
				}
				tempname m_omega_temp
				tempname factor_temp
				matrix `factor_temp' = `Omega_bd_s'*inv(`Omega_dd_s')
				
				mata : x = min(st_matrix("`factor_temp'"))
				mata : st_local("min_ft", strofreal(x))
				
				if `min_ft' >= 0{
					tempname m_omega_temp
					matrix `m_omega_temp' = `factor_temp'*`Omega_bd_s''
					local omega_temp = `m_omega_temp'[1,1]
					if `omega_temp' > `omega_star'{
						local s_star = `i'
						tempname m_factor_star
						matrix `m_factor_star' = `factor_temp'
						local omega_star = `omega_temp'
					}
				}
			}
			
			if `s_star' > 0{
				tempname poly
				matrix `poly' = J(1,7,.)
				forvalues i = 0/6 {
					local j = `i' + 1
					matrix `poly'[1,`j'] = `omega_star'^(`i')
				}
				
				tempname m_c
				matrix `m_c' = `poly'*`poly_coef''
				local subset_star = r(v`s_star')
				local size : list sizeof subset_star
				
				tempname Y_d_subset
				matrix `Y_d_subset' = J(1,`size',.)
				local c1 = 1
				while `c1' <= `size' {
					foreach c of numlist `subset_star'{
						matrix `Y_d_subset'[1,`c1'] = `Y_d'[1,`c']
						local c1 = `c1' + 1
					}
				}
				
				local a = invnormal(1-`alpha'*9/10)
				tempname m_b
				matrix `m_b' = `m_factor_star'*`Y_d_subset''
				local b = .
				local b = `m_b'[1,1] + `m_c'[1,1]
				
				if `a'<`b'{
					local lb = `Y_b' - `a'
				}
				else{
					local lb = `Y_b' - `b'
				}
			}
			else{
				local lb = `Y_b' - invnormal(1-`alpha')
			}
			
			local ub = .
			
			if `type' == -1 {
				local ub = -`lb'
				local lb = .
			}
		}
		//
		
		
		
		
		/*Two Sided CI*/
		else {

			local s1_star = 0											
			local s2_star = 0												
			local factor1_star = 0
			local factor2_star = 0
			local omega1_star = 0
			local omega2_star = 0
			
			forvalues i = 1/`r(cmax)' {
				local subset = r(v`i')
				local size : list sizeof subset
				
				tempname Omega_bd_s
				matrix `Omega_bd_s' = J(1,`size',.)						// Omega_bd_s is each subset of variables from Omega_bd
				local c1 = 1
				while `c1' <= `size' {
					foreach c of numlist `subset'{
						matrix `Omega_bd_s'[1,`c1'] = `Omega_bd'[1,`c']
						local c1 = `c1' + 1
					}
				}
				
				tempname Omega_dd_s
				matrix `Omega_dd_s' = J(`size',`size',.)				// Omega_dd_s is each subset of variables from Omega_dd
				local r1 = 1
				while `r1' <= `size'{
					foreach r of numlist `subset'{	
						local c1 = 1
						while `c1' <= `size'{
							foreach c of numlist `subset'{
								matrix `Omega_dd_s'[`r1',`c1'] = `Omega_dd'[`r',`c']
								local c1 = `c1' + 1
							}
						local r1 = `r1' + 1
						}	
					}
				}
				
				tempname factor_temp
				matrix `factor_temp' = `Omega_bd_s'*inv(`Omega_dd_s')
				tempname m_omega_temp
				matrix `m_omega_temp' = `factor_temp'*`Omega_bd_s''
				local omega_temp = `m_omega_temp'[1,1]

				mata : x = min(st_matrix("`factor_temp'"))
				mata : st_local("min_ft", strofreal(x))
				
				mata : x = max(st_matrix("`factor_temp'"))
				mata : st_local("max_ft", strofreal(x))
				
				if `min_ft' >= 0{
					if `omega_temp' > `omega1_star'{
						
						local s1_star = `i'
						
						tempname factor1_star
						matrix `factor1_star' = `factor_temp'
						
						local omega1_star = `omega_temp'
					}
				}
				if `max_ft' <= 0{
					if `omega_temp' > `omega2_star'{
						local s2_star = `i'
						
						tempname factor2_star
						matrix `factor2_star' = `factor_temp'
						
						local omega2_star = `omega_temp'
					}
				}
			}
			
			if `s1_star' + `s2_star' > 0{							
				local degree = 6
				local deg_p1 = `degree' + 1
				local size = `deg_p1'^2									//size = 49
				local poly_u = "blank"
				local poly_l = "blank"
				
				tempname powers
				matrix `powers' = J(`size', 2,.) 						//Creating matrix 'powers', all subsets of [0,6] of size 2
				local counter = 0
				forvalues i = 0/`degree'{
					forvalues j = 1/`deg_p1'{
						local row = `j' + `counter'
						matrix `powers'[`row',1] = `i'
						matrix `powers'[`row',2] = `j'-1
					}
					local counter = `counter' + 7	
				}
				
				forvalues m = 1/`size'{									//Creating poly_u and poly_l
					tempname d
					matrix `d' = (`powers'[`m',1], `powers'[`m',2])
					local d_sum = `d'[1,1] + `d'[1,2]
					if `d_sum' <= `degree'{
						local u = `omega1_star'^`d'[1,1]*`omega2_star'^`d'[1,2]
						local l = `omega2_star'^`d'[1,1]*`omega1_star'^`d'[1,2]
						
						if "`poly_u'" == "blank"{
							local poly_u = "`u'"
						}
						else{
							local poly_u = "`poly_u' `u'"
						}
						
						if "`poly_l'" == "blank"{
							local poly_l = "`l'"
						}
						else{
							local poly_l = "`poly_l' `l'"
						}
					}
				}
				
				local size_u : list sizeof poly_u
				tempname m_poly_u
				matrix `m_poly_u' = J(1,`size_u',0)
				forvalues i = 1/`size_u'{								//Changing poly_u and poly_l to matrices
					local a : word `i' of `poly_u'
					local coef = `a'
					matrix `m_poly_u'[1,`i'] = `coef'
				}
				
				local size_l : list sizeof poly_l
				tempname m_poly_l
				matrix `m_poly_l' = J(1,`size_l',0)
				forvalues i = 1/`size_l'{								//Changing poly_u and poly_l to matrices
					local a : word `i' of `poly_l'
					local coef = `a'
					matrix `m_poly_l'[1,`i'] = `coef'
				}
				
				tempname c_u
				tempname c_l
				matrix `c_u' = `m_poly_u'*`poly_coef''
				matrix `c_l' = `m_poly_l'*`poly_coef''
				local cv_alt = invnormal(1-`alpha'*9/20)
				
				local subset_star1 = r(v`s1_star')
				local size : list sizeof subset_star1
				
				tempname Y_d_subset1
				matrix `Y_d_subset1' = J(1,`size',.)
				local c1 = 1
				while `c1' <= `size' {
					foreach c of numlist `subset_star1'{
						matrix `Y_d_subset1'[1,`c1'] = `Y_d'[1,`c']
						local c1 = `c1' + 1
					}
				}
				
				tempname b1 
				if `s1_star' > 0{										 
					matrix `b1' = `factor1_star'*`Y_d_subset1''
					local b1 = `b1'[1,1] + `c_l'[1,1]
					if `cv_alt' < `b1'{
						local lb = `Y_b' - `cv_alt'
					}
					else{
						local lb = `Y_b' - `b1'
					}
				}
				else{
					if `cv_alt' < `c_l'[1,1]{
						local lb = `Y_b' - `cv_alt'
					}
					else{
						local lb = `Y_b' - `c_l'[1,1]
					}
				}
				
				local subset_star2 = r(v`s2_star')
				local size : list sizeof subset_star2
				
				tempname Y_d_subset2
				matrix `Y_d_subset2' = J(1,`size',.)
				local c1 = 1
				while `c1' <= `size' {
					foreach c of numlist `subset_star2'{
						matrix `Y_d_subset2'[1,`c1'] = `Y_d'[1,`c']
						local c1 = `c1' + 1
					}
				}
				tempname b2
				if `s2_star' > 0{										
					matrix `b2' = `factor2_star'*`Y_d_subset2''
					local b2 = -`b2'[1,1] + `c_u'[1,1]
					
					if `cv_alt' < `b2'{
						local ub = `Y_b' + `cv_alt'
					}
					else{
						local ub = `Y_b' + `b2'
					}
				}
				else{
					if `cv_alt' < `c_u'[1,1]{
						local ub = `Y_b' + `cv_alt'
					}
					else{
						local ub = `Y_b' + `c_u'[1,1]
					}
				}
				
				// Addition by Philipp
				if `lb' > `ub' {
					local lb = .
					local ub = .
				}
			}
			
			else{
				local lb = `Y_b' - invnormal(1-`alpha'/2)
				local ub = `Y_b' + invnormal(1-`alpha'/2)
			}
		}
	}
	
	
	
	/*RESULTS*/ // Changed by Philipp
	if `type' == 1 {
		local ci_type = "Upper one-sided"
	}
	else if `type' == -1 {
		local ci_type = "Lower one-sided"
	}
	else{
		local ci_type = "Two-sided"
	}
	
	if `alpha' == 0.01 {
			local Interval = "99%"
		}
		if `alpha' == 0.05 {
			local Interval = "95%"
		}
		if `alpha' == 0.1 {
			local Interval = "90%"
		}	
	//
	
	
	tempname CI 
	matrix `CI' = J(1,2,.)
	matrix `CI'[1,1] = `lb' * `std_err'[1,`index']
	matrix `CI'[1,2] = `ub' * `std_err'[1,`index']	
	
	matrix colnames `CI' = "lower" "upper"
	matrix rownames `CI' = `varlist'
	
	di _newline(2)
	matlist `CI', ///
		title("`ci_type' `Interval' confidence interval:") ///
		border(rows) ///
		noblank
	
	
	ereturn matrix SSCI `CI'
end	
//****************************************************************************//
//****************************************************************************//














//****************************************************************************//
//****************************************************************************//
/*								PROGRAM _ffdtcomb							  */
//****************************************************************************//
//****************************************************************************//


/* 
This program, _ffdtcomb, is used in SSCI to create a power set of subsets. 

The original code can be found at 
http://familyfinder.dk/repository/_/_ffdtcomb.ado
*/


/*
*------------------------------------------------------------------------*
* Description ($
*! _ffdtcomb version 2.0 - 26feb2005 - familyfinder@stat.sdu.dk
	-	ffdtcomb renamed to _ffdtcomb. All programs in separate
		ado files are renamed to lower-case, to ensure functionality across
		(win, linux etc.)
*! ffdtcomb version 1.0 - 14nov2004 - familyfinder@stat.sdu.dk

Sub-program used to make all possible combinations of a macro list
and return combinations in r() to the calling program (one r() for
each possible combination).

Used in the following programs:
	-	ffdtallcomb
	-	ffdtdeclareconcur
$)
*/
*------------------------------------------------------------------------*
capture program drop _ffdtcomb
program define _ffdtcomb, rclass
	
	//version 8.2
	version 12.1 	// SSCI changed
	preserve 	// SSCI added
	
	syntax , n(integer) Elist(str) [k(integer 0)]
	* n is the number of elements in the set, which is to be drawn from
	* k is the number of elements to be drawn from n. 
	*    k = 2 means k = 1, 2
	*    if k is not set, k = 1, 2, 3, ..., n
	* elist is the list of actual elements (numbers or strings)
	* there should be n elements in elist

	if (`k' == 0) local k = `n'
	if `:word count `elist'' != `n' {
		
		di as err "Error executing program _ffdtcomb..." _n ///
		  "local macro elist should contain exactly n elements " ///
		  "(see local macro n)."
		exit 197
		
	}
		
	*--------------------------------------------------------------------*
	* Calculating the total number of combinations C(n,k) for the given n and k
	forval i = 1/`k' {
	
		local cmax = `cmax' + `=comb(`n',`i')'
	
	}

	*--------------------------------------------------------------------*
	* Creating dataset with combinations (given (n,k)). Clearing memory
	
	forval m = 1/`k' {
	
		tempfile combset
		tempfile subset`m'
		
	}
	
	clear
	qui set obs `n'
	gen byte i1 = _n
	qui save `subset1'
	qui forval i = 2/`k' {
	
		use `subset`=`i'-1''
		gen byte from = i`=`i'-1' + 1
		gen byte to = `n'
		gen byte n = to - from + 1
		gen byte line = _n
		expand n
		bys line: gen byte i`i' = from + _n - 1 
		drop if n < 1
		drop from to n line
		save `subset`i''

	}
	
	use `subset1'
	forval m = 2/`k' {
	
		append using `subset`m''
		
	}
			
	*--------------------------------------------------------------------*
	* Replacing values k = 1,2,...,n with the values in local elist,
	* i.e. 1 replaced with the first element of value, ..., n replaced
	* with the n'th element of value

	* Generating string variables from variables i*
	forval i = 1/`k' {
	
		qui gen str I`i' = string(i`i')
	
	}
	
	* Replacing values in I*
	forval i = 1/`k' {
	
		forval j = `n'(-1)`i' {
		
			local num : word `j' of `elist'
			qui replace I`i' = "`num'" if i`i' == `j'
			
		}

	}
	
	*--------------------------------------------------------------------*
	* Copying combinations to local macros, one macro for each observation
	* = cmax macros (macros v1-vj, j=1,2,..,cmax)
	local N = _N
	assert `cmax' == `N'
	forval i = 1/`N' {
	
		forval j = 1/`k' {
		
			if `=i`j'[`i']' != . {
			
				local v`i' `"`v`i'' `=I`j'[`i']'"'
				
			}
			
		}
		
	}
	
	* Locals containing combinations returned (see -return list-)
	* Going through forval step backwards only so that results 
	* are displayed in the correct order (1--n) and not (n--1)
	forval i = `cmax'(-1)1 {
	
		return local v`i' = "`v`i''"
		
	}
		
	return local cmax = `cmax'
	clear
	restore // SSCI added
end

*------------------------------------------------------------------------*




