********************************************************************
*	PROGRAM GENERATES SYNTHETIC INSTRUMENTAL VARIBALES
*				IN SPATIAL REGRESSION
*					-----------
*	According to Le Gallo & Paez (2013) and Fingleton (2022)
*					-----------
*	Version 1.1		Manh Hoang Ba (hbmanh9492@gmail.com)
*					
********************************************************************
*	Version history
*		02 Sep 25: 1.0 - first time contribution
*		22 Oct 25: 1.1 - upspeed and modify results
********************************************************************

cap program drop spsiv
program define spsiv
	version 11.1	// According to spmat.ado
	
	syntax varlist(min=1) [if] [in] , Mmat(name) [Alpha(real 0.05)]
	
	preserve

*	mark sample	
	tempvar touse
	mark `touse' `if' `in'
	
	tempfile raw_data siv_data
	tempvar sp_id sp_t id_t

*	Remove duplicate variables from varlist
	local varlist : list uniq varlist

*	Check spset
	qui cap confirm v _ID
	if _rc>0 {
		di in red "data must be {bf:spset}"
		exit 198
	}

	else {
*	Check xtset/tsset	
		qui cap xtset
		if _rc>0 {			// Cross-sectional data
			qui cap spset
			if _rc>0 {
				di in red "data must be {bf:spset}"
				exit 198
			}
		}
		else {				// Panel data
			if "`r(timevar)'"=="" {
				di in red "time variable not set; use {bf:xtset} {it:panelvar} {it:timevar}"
				exit 198
			}
			local ivar `r(panelvar)'
			local tvar `r(timevar)'
			qui xtset `ivar' `tvar'
			qui spset, modify nocoord
		}
	}
*
*	Get sp_id, time_id
	local sp_id_var `r(sp_id_var)'
	qui egen `sp_id' = group(`sp_id_var') if `touse'	// sp_id = 1 to N
	sort `sp_id' `tvar'
	qui by `sp_id': gen `sp_t' = _n if `touse'			// sp_t  = 1 to T
	qui egen `id_t' = group(`sp_id_var' `tvar')

*	Get N, T
	qui sum `sp_t' if `touse'
	local T = r(max)
	qui sum `sp_id' if `touse'
	local N = r(max)

*	Save data
	sort `id_t'
	qui save `raw_data', replace
	
*	Reshape wide data
	qui keep if `touse'
	qui keep `id_t' `sp_id' `sp_t' `varlist'
	qui ds `id_t' `sp_id' `sp_t', not
	local bf_vars `r(varlist)'
	qui reshape wide `id_t' `bf_vars', i(`sp_id') j(`sp_t')
		
*	Calculate eigenvectors Ei
	qui _eigvecvars, w(`mmat')

*	Calculate Synthetic instrument for varlist
//	local siv_vars

*	MATA:
qui	mata: select_vars("`bf_vars'", `T', `N', `alpha', "E")
	
*	STATA
/*	
	qui foreach name in `bf_vars' {
		forvalues t=1/`T' {
			
			local Vit
			forvalues i=1/`N' {
				tempvar V`t'`i'
			}			
			tempname p
		
			forvalues i=1/`N' {					
				qui reg `name'`t' E`i'
				scalar `p' = 1-F(e(df_m), e(df_r),e(F))
				if `p' < `alpha' {
					qui gen double `V`t'`i'' =  _b[E`i']*E`i'
					local Vit `Vit' `V`t'`i''
				}
			}		
			qui reg `name'`t' `Vit'
			scalar noE_`name' = e(df_m)
			qui predict double siv_`name'`t'
		}
		local siv_vars `siv_vars' siv_`name'
	}
*/

	qui drop E*

*	Reshape long data
	qui reshape long `id_t' `bf_vars' `siv_vars' , i(`sp_id') j(`sp_t')
	qui drop `bf_vars'
	sort `id_t'
	qui save `siv_data', replace

*	Merge data
	restore
	use `raw_data', clear
	foreach name in `siv_vars' {
		qui cap confirm v `name'
		if _rc==0 qui drop `name'
	}
	
	qui merge 1:1 `id_t' using `siv_data', nogen
	foreach name in `bf_vars' {
		qui corr `name' siv_`name' if `touse'
		scalar corr_`name' = r(rho)
	}

	
*	Display results
	di _n in ye "Correlation between X and synthetic intrumental variables"

	local k : word count `bf_vars'
	local hline = 12*(`k'+1)

	// Loop through first 6 variables
	local groups = ceil(`k'/6)
	forvalues g = 1/`groups' {
		local start = (`g'-1)*6 + 1
		local end = min(`start'+5, `k')
		
		// First line: title "Variables" and varnames
		di as text "{hline `hline'}"
*		di ""
		di _column(1) "Variable (X)" _continue
		local col = 13
		forvalues j = `start'/`end' {
			local var : word `j' of `bf_vars'
			di _column(`col') %9s "`var'" _continue
			local col = `col' + 12
		}
		di ""
		di as text "{hline `hline'}"
		
		// Second line: "Corr(X,SIV)" and correlation coef.
		di _column(1) "Correlation" _continue
		local col = 13
		forvalues j = `start'/`end' {
			local var : word `j' of `bf_vars'
			di _column(`col') %9.4f in ye corr_`var' _continue
			local col = `col' + 12
		}
		di ""

/*		version 1.1 - display number of Eigenvectors		
		// Third line: "Eigvectors" and number of eigenvectors
		di _column(1) as text "Eig. vector" _continue
		local col = 13
		forvalues j = `start'/`end' {
			local var : word `j' of `bf_vars' 
			di _column(`col') %9.0g in ye noE_`var' _continue
			local col = `col' + 12
		}
		di ""
*/		
		di as text "{hline `hline'}"
		
		// If not the last group, print a blank line to space the next table.
		if `g' < `groups' {
			di ""
		}
	}

	sort `sp_id' `sp_t'
	qui cap xtset	
end


*********************************************************************
*	Program calculate Eigenvectors variables
*		from a Symmetric Adjacency matrix
*********************************************************************
cap program drop _eigvecvars	
program define _eigvecvars
	version 11.1
	syntax , Wmatrix(name)

	tempname w_m E_m E_vectors E_values r j_r q_r p_r
	
*	Check spmat object
	qui cap spmat summarize `wmatrix'
	if _rc > 0 {
		di as err "{bf:spmat} object {it:`wmatrix'} not found"
		exit 498
	}
	
*	Check square matrix
	if r(b) != r(n) {
		errprintf("{Matrix {it:`wmatrix'} is not square")
		exit(498)
	}

	spmat getmatrix `wmatrix' `w_m'
	mata {
		
*	Check symmetric
		if (!issymmetric(`w_m')) {
			errprintf("Matrix {it:`wmatrix'} must be symmetrical")
			exit(498)
		}

*	Projection matrix: P = (I-1*1'/N)M(I-1*1'/N)
		`r'=rows(`w_m')
		`j_r' = J(`r',1,1)
		`q_r' = I(`r')-`j_r'*`j_r''/`r'
		`p_r '= `q_r'*`w_m'*`q_r'

		symeigensystem(`p_r', `E_vectors'=., `E_values'=.)
		st_matrix("`E_m'", `E_vectors')
	}
	svmat `E_m', names(E)
end


*********************************************************************
*	Program define seclect_vars() in MATA
*********************************************************************

mata:
mata clear
	void select_vars( /*
*/		string scalar bf_vars_str, /*
*/		real scalar T, /*
*/		real scalar N, /*
*/		real scalar alpha, /*
*/		string scalar E_prefix /*
*/	) {
		
		bf_vars = tokens(bf_vars_str)
		n_vars = length(bf_vars)
		n_obs = st_nobs()
		
		// Get data Ei
		E_varnames = J(1, N, "")
		for (i = 1; i <= N; i++) {
			E_varnames[i] = E_prefix + strofreal(i)
		}
		E_data = st_data(., E_varnames)
		
		// Make siv_vars
		siv_vars_list = ""

		for (v = 1; v <= n_vars; v++) {
			name = bf_vars[v]
			
			// Get data for all t
			varnames_t = J(1, T, "")
			for (t = 1; t <= T; t++) {
				varnames_t[t] = name + strofreal(t)
			}
			X_all = st_data(., varnames_t)
			
//			n_selected = 0
			
			siv_name = "siv_" + name
			
			for (t = 1; t <= T; t++) {
				x = X_all[., t]
				
				// Mean and Std
				mean_x = mean(x)
				sd_x = sqrt(diag(variance(x)))
				x_centered = x :- mean_x

				E_means = colsum(E_data) / n_obs
				E_sds = sqrt(diag(colsum((E_data :- E_means):^2) / (n_obs-1)))
				
				// Vectorized correlation calculation
				E_centered = E_data :- E_means
				corr_vec = (x_centered' * E_centered) * invsym(sd_x) * invsym(E_sds) / (n_obs-1) 
				corr_vec = corr_vec[1, .] 
				
				// Vectorized p-value calculation
				t_stats = corr_vec :* sqrt(n_obs - 2) :/ sqrt(1 :- corr_vec:^2 :+ 1e-10)
//				p_vals = 2 :* (1 :- normal(abs(t_stats)))
				p_vals = 2 :* (1 :- t(n_obs - 2, abs(t_stats)))
				
				// Mark index with p-value < alpha
				idx_sig = selectindex(p_vals :< alpha)
			
				// Number of E_i selected
//				n_selected = length(idx_sig)
				
				// Collect E_i
				if (length(idx_sig) > 0) {
					E_sig = E_prefix :+ strofreal(idx_sig')		
//					Vit = invtokens(E_sig')
				} 
			
				// OLS in MATA
				varname_t = name + strofreal(t)
				siv_namet = "siv_" + varname_t
				
				y = st_data(., varname_t)
				
				if (length(idx_sig) > 0) {
					X_reg = st_data(., E_sig')
					X_reg = (J(n_obs, 1, 1), X_reg)
//					n_cols = cols(X_reg)
				} else {
					X_reg = J(n_obs, 1, 1)
//					n_cols = 1
				}
				
				beta = invsym(X_reg' * X_reg) * X_reg' * y
				yhat = X_reg * beta
				
				// Store to Stata		
				st_addvar("double", siv_namet)				
				st_store(., siv_namet, yhat)
				
				// Lưu hệ số tự do (bậc tự do = số biến ngoài constant)
//				n_selected = n_cols - 1				
			}
			
//			st_numscalar("noE_" + name, n_selected)
			
			// Add to siv_vars
			if (siv_vars_list == "") {
				siv_vars_list = siv_name
			} else {
				siv_vars_list = siv_vars_list + " " + siv_name
			}			
		}
		
		// Return local siv_vars to Stata
		st_local("siv_vars", siv_vars_list) 
		
	}
end

// Gọi hàm từ Stata
