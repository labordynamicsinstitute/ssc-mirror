*author: Yannick Guyonvarch, date: July 22 2025. Version 3.

*twc_inf: Stata module that computes the inference tools developed in "Asymptotic results under two-way clustering" (Arxiv wp, 2025) by L. Davezies, X. D'Haultfoeuille and Y. Guyonvarch

quietly capture program drop twc_inf
quietly program twc_inf, byable(recall) rclass sortpreserve
 
	version 16.1
	
	*command's syntax
	syntax varlist(min=1 numeric) [if] [in] ///
	[, CLuster(varlist min=2 max=2 numeric) METHOD(namelist min=1 max=1) ///
	ALPHA(numlist integer max=1 >=1 <=99) NODOFCORR]
	
	*standard parsing routines
	marksample touse
	markout `touse' `cluster'
	
	tokenize `cluster'
	
	*several checks of the method option
	local method_check=wordcount("`method'")
	if `method_check' == 0 {
		local method = "regress"			
	}
	if "`method'" != "regress" & "`method'" != "logit" & "`method'" != "probit" ///
	& "`method'" != "poisson" {
		display as err _newline(1) "The method() option allows for the " ///
		"following Stata commands only: regress, logit, probit and poisson."
		exit
	}
	display _newline(1) "The method() option has been set to `method'." 
	
	*define several local objects to be filled in after
	tempname b bbis D M1 M2 M12 V1 V2 V12 Vu stacked_var var_vec var_mat ///
	se_vec eigenvec_vu eigenval_vu 
	tempvar e cell_clust
	
	*parse `varlist'
	tokenize `varlist'
	local Y: word 1 of `varlist'
	local varlist_bis : list varlist - Y
		
	*regression trick to obtain bread of the sandwich variance formula
	if "`method'"=="regress" {
		quietly `method' `varlist' if `touse', mse1
	}
	else {
		quietly `method' `varlist' if `touse'
	}
	
	*store estimated coefs, bread and some additional info
	matrix `b' = e(b)
	matrix `bbis' = e(b) /*duplicate storage of e(b) for practical reasons*/
	matrix `D' = e(V)
	local k = colsof(`D')
	local N = e(N)
	*Stata does not use the same dof correction for regress and for nonlinear 
	*mle-typem models -> we store the corresponding ingredient for dof
	*correction in a local named k
	if "`method'"=="regress" {
		local dof = e(rank)
	}
	else {
		local dof = 1
	}	
	
	*obtain residuals/scores of the (nonlinear) regression
	if "`method'"=="regress" {
		quietly predict double `e' if `touse', residual
	}
	else {
		quietly predict double `e' if `touse', score
	}

	*compute V1 and V2 (with standard DoF adjustments implemented in other
	*Stata routines)
	local cl1: word 1 of `cluster'
	local cl2: word 2 of `cluster'
	forvalues j = 1(1)2 {
		quietly tab `cl`j'' if `touse'
		local C`j' = r(r)
		sort `cl`j''
		matrix opaccum `M`j'' = `varlist_bis' if `touse', group(`cl`j'') opvar(`e')
		*compute dof correction if needed
		if "`nodofcorr'"!="" {
			local dof_corr = 1
		} 
		else {
			local dof_corr = ((`N'-1)/(`N'-`dof'))*(`C`j''/(`C`j''-1))
		}
		matrix `V`j'' = `dof_corr'*`D'*`M`j''*`D'
	}
	
	*compute V12 following the same rationale, treating intersection of the 
	*two clustering dimensions as a new cluster grid
	quietly gen `cell_clust' = `cl1' * `cl2'
	quietly tab `cell_clust' 
	local C12 = r(r)
	sort `cell_clust'
	matrix opaccum `M12' = `varlist_bis' if `touse', group(`cell_clust') opvar(`e')
	*compute dof correction if needed
	if "`nodofcorr'"!="" {
		local dof_corr = 1
	} 
	else {
		local dof_corr = ((`N'-1)/(`N'-`dof'))*(`C12'/(`C12'-1))
	}
	matrix `V12' = `dof_corr'*`D'*`M12'*`D'
	matrix colnames `V12' = `varlist_bis' _cons
	matrix rownames `V12' = `varlist_bis' _cons
	
	*compute Vu
	matrix `Vu' = `V1' + `V2' - `V12'
		
	* compute se^2 for each individual coef estimate
	matrix `stacked_var' = vecdiag(`V1') \ vecdiag(`V2') \ vecdiag(`Vu')
	mata: st_matrix("`var_vec'", colmax(st_matrix("`stacked_var'")))	
	
	*store individual variances in a diagonal matrix for convenience and 
	*replace entries of e(V) with this matrix. Store vector of se separately
	*as well
	matrix `var_mat' = diag(`var_vec')
	forvalues i=1(1)`k'{
		forvalues j=1(1)`k'{
			matrix `D'[`i',`j'] = `var_mat'[`i',`j']
		}
	}
	mata: st_matrix("`se_vec'", sqrt(st_matrix("`var_vec'")))
	matrix rownames `se_vec' = "`Y'"
	matrix colnames `se_vec' = `varlist_bis' _cons
	
	*display CIs for individual coefs using standard Stata post-estimation
	*format
	ereturn post `b' `D'
	if "`alpha'"==""{
		local level = 95
	}
	else {
		local level = 100-`alpha'
	}
	display _newline(1) "(Std. Err. adjusted for " ///
	`C1' " clusters in `cl1' and " `C2' " clusters in `cl2')" _newline(1)
	ereturn display, level(`level')	
		
	*check if Vu has at least one negative eigenvalue
	matrix symeigen `eigenvec_vu' `eigenval_vu' = `Vu'
	matrix rownames `eigenval_vu' = "Vu eigenvals"
	mata: st_local("eigenval_min_vu", strofreal(min(st_matrix("`eigenval_vu'"))))
	if `eigenval_min_vu' < 0 {
		display as err _newline(1) "The matrix Vu=V1+V2-V12 " ///
		"has at least one negative eigenvalue."			
	}	
	
	*clean environment and return relevant info in rclass objects
	ereturn clear
	return clear
	return matrix coef_vec = `bbis'
	return matrix V1 = `V1'
	return matrix V2 = `V2'
	return matrix V12 = `V12'
	return matrix Vu = `Vu'
	return matrix eigenvals_Vu = `eigenval_vu'
	return matrix se_vec = `se_vec'

end