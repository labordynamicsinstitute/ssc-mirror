/*============================================================================
	Test for heteroscedasticity in fixed-T panel data models
============================================================================*/

*	Version 1.4		17 Jan 2026 by Manh Hoang-Ba (hbmanh9492@gmail.com)

/* -----------------------------------------------------------------
	Kezdi (2003) LM test for fixed-T one-way fixed-effects models
------------------------------------------------------------------*/
*	Version 1.1 Correct degrees of freedom of tests 
*				in the presence of perfect multicollinearity
*	Version 1.2 works without vech() matrix function
*	Version 1.3 works with unbalanced data

/* -----------------------------------------------------------------
	Add regression-based tests for fixed-T one-way effects models
------------------------------------------------------------------*/
*	Version 1.4 precise Time-demeaning steps
*				use generalized inverse when covariance matrix is singular
*				not allow weight in xtreg, fe
*				add regression-based test for FEM and REM


cap program drop xttest4
program define xttest4, rclass
	version 11.0
	
	syntax [, kezdi]
	
	if "`e(cmd)'" != "xtreg" {
        display in red as error "last estimates not xtreg"
        exit 301
    }
	
	if "`e(model)'" != "fe" & "`e(model)'" != "re" {
		di in red "last estimates not xtreg, fe or xtreg, re"
		exit 301
	}
	
	if "`e(model)'"=="fe" {
		if "`e(wexp)'" != "" {
			di as err "weights not allowed"
			exit
		}
		
		local est = 1
	}
	else {
		local est = 2
		if "`kezdi'" != "" {
			di as err "`kezdi' not allowed"
			exit
		}
	} 
	
preserve

	tempvar e
	qui predict double `e' if e(sample) , e
	
	*	Get xvar form cmdline	(or use -indeplist- command)
	local cmdline `e(cmdline)'
	gettoken cmd rest : cmdline     // remove "xtreg"
	gettoken depvar rest : rest     // remove depvar	
	_get_indvars `rest'				// keep indep. variables
	fvrevar `r(varlist)'				
	local xvar "`r(varlist)'"

	tempvar touse
	qui gen byte `touse'=e(sample)
	qui keep if `touse'
	

/*==========================================================================
		1. Test for heteroscedasticity in fixed-effects models
==========================================================================*/	
	*	Predict e_it
	
	if `est'==1 & "`kezdi'" != "" {
	
/*==========================================================================
			1.1. Kezdi LM test
==========================================================================*/	
		di
		di as text "Test for heteroscedasticity in fixed-T panel data models"	
		
/*==========================================================================
			1.1.1. BALANCED PANEL
==========================================================================*/

		if `e(Tcon)'==1 {
			
			*	id, time, obs
			tempvar id time obs
			qui egen `id' = group(`e(ivar)') if `touse'
			sort `id' `r(timevar)'
			qui by `id': gen `time'=_n if `touse'
			sort `id' `time'
			qui gen `obs'=_n
			
			*	Get N, T of balanced subsample
			tempname NT N T K
			qui xtsum `e(depvar)' 
			scalar `NT'=r(N)
			scalar `N'=r(n)
			scalar `T'=r(Tbar)
			scalar `K'= e(rank)-1

			*	Predict e_it
			tempvar s2
			qui sum `e' , d
			scalar `s2'=r(Var)*(r(N)-1)/(`NT'-`N')

			*	Time-Demeaning
			sort `id' `time'
			local xvar_dm
			foreach var of varlist `xvar' {
				tempvar `var'_m `var'_dm 
				qui by `id': egen double ``var'_m'=mean(`var') 
				qui gen double ``var'_dm' = `var'-``var'_m' 
				local xvar_dm `xvar_dm' ``var'_dm'
			}
			
			capture matrix drop `Omega' `V0' `V1' `V2' `V3' `E'
			tempname Omega V0 V1 V2 V3 E
				
			*	Omega ========================
			capture drop _t*
			qui tab `time' if `touse', gen(_t)
			mat opaccum `Omega' = _t* , gr(`id') opvar(`e') nocons
			capture drop _t*
			
			mat `Omega' = `Omega'/`N'

				
			*	V0 ========================
			mat opaccum `V0' = `xvar_dm' , gr(`id') opvar(`e') nocons
			mat `V0' = `V0'/`N'
			
			*	V1 ========================
			mat glsa `V1' = `xvar_dm' , gr(`id') gl(`Omega') r(`time') nocons
			mat `V1' = `V1'/`N'

			*	V2 ========================
			sort `obs'
			mat opaccum `V2' = `xvar_dm' , gr(`obs') opvar(`e') nocons
			mat `V2'=`V2'*`T'/(`NT'-`N')
			
			*	V3 ========================
			qui mat ac `V3' = `xvar_dm' , abs(`id') nocons
			mat `V3' = `V3'*`s2'/`N'
		
			*	vj = vech(Vj) =============
			tempname v0 v1 v2 v3
			
			if c(version) >= 18 {
				forvalues i=0/3 {
					mat `v`i'' = vech(`V`i'')
				}	    
			}
			else {
				forvalues i=0/3 {
					vec_h `V`i''
					mat `v`i'' = r(v)
				}
			}	

			*	Cj ========================
			tempname m C1 C2 C3 X c1i c2i c3i M1 M2 M3

			scalar `m'=rowsof(`v1')	
			mat `C1' = J(`m',`m',0)
			mat `C2' = J(`m',`m',0)
			mat `C3' = J(`m',`m',0)
			
			if c(version) >= 18 {			
				forvalues i=1/`=`N'' {		
					mkmat `e' if `id'==`i', mat(`E')
					mkmat `xvar_dm' if `id'==`i', mat(`X')

					* C1
					mat `M1' = `X''*`E'*`E''*`X'-`X''*`Omega'*`X'
					mat `c1i' = vech(`M1')
					mat `C1' = `C1' + `c1i'*`c1i''
					
					* C2
					mat `M2' = `X''*`E'*`E''*`X'-`X''*diag(vecdiag(`E'*`E''))*`X'
					mat `c2i' = vech(`M2')
					mat `C2' = `C2' + `c2i'*`c2i''
						
					* C3
					mat `M3' = `X''*`E'*`E''*`X'-`X''*`s2'*`X'
					mat `c3i' = vech(`M3')
					mat `C3' = `C3' + `c3i'*`c3i''

				}	    
			}
			
			else {
				forvalues i=1/`=`N'' {

					mkmat `e' if `id'==`i', mat(`E')
					mkmat `xvar_dm' if `id'==`i', mat(`X')

					* C1
					mat `M1' = `X''*`E'*`E''*`X'-`X''*`Omega'*`X'
					vec_h `M1'
					mat `c1i' = r(v)
					mat `C1' = `C1' + `c1i'*`c1i''
					
					* C2
					mat `M2' = `X''*`E'*`E''*`X'-`X''*diag(vecdiag(`E'*`E''))*`X'
					vec_h `M2'
					mat `c2i' = r(v)
					mat `C2' = `C2' + `c2i'*`c2i''
						
					* C3
					mat `M3' = `X''*`E'*`E''*`X'-`X''*`s2'*`X'
					vec_h `M3'
					mat `c3i' = r(v)
					mat `C3' = `C3' + `c3i'*`c3i''
						
				}	    
			}
				
			mat `C1' = `C1'/`N'
			mat `C2' = `C2'/`N'
			mat `C3' = `C3'/`N'
			
			*	Test 
			tempname df h1 h2 h3 h1_p h2_p h3_p
			scalar `df'=`K'*(`K'+1)/2+1

			forvalues i=1/3 {
				tempname _h`i' _pinvC`i'

				if det(`C`i'') == 0 {
					di as err "Covariance matrix C`i' is singular. Use generalized inverse."
					mata: st_matrix("`_pinvC`i''",pinv(st_matrix("`C`i''")))
					mat `_h`i'' = `N'*(`v`i''-`v0')'*`_pinvC`i''*(`v`i''-`v0')
				}
				else {
					mat `_h`i'' = `N'*(`v`i''-`v0')'*invsym(`C`i'')*(`v`i''-`v0')
				}
				scalar `h`i'' = `_h`i''[1,1]
				scalar `h`i'_p' = 1-chi2(`df', `h`i'')
			}
			
			*	Format statistics
			forvalues i=1/3 {
				if `h`i'' > 99999 {
					local h`i'_fmt `"%9.0g"'
				}
				else	local h`i'_fmt `"%9.3f"'	
			}
		}

	/*==========================================================================
			1.1.2. UNBALANCED PANEL
	==========================================================================*/
		
		else {
			
			*	id, time, obs
			tempvar id Ti time obs _ones e_Ti
			qui egen long `id' = group(`e(ivar)') if `touse'
			sort `id' `r(timevar)'
			qui by `id': gen `time'=_n if `touse'
			sort `id' `time'
			qui gen `obs'=_n
			qui gen byte `_ones' = 1
			qui by `id': egen long `Ti' = total(`_ones')
			qui gen double `e_Ti' = `e'*(`Ti'/(`Ti'-1))^0.5 
			
			*	Get N, T, K
			tempname NT N K
			
			scalar `K'= e(rank)-1
			qui xtsum `e(depvar)' if `touse'
			scalar `N' = r(n)
			scalar `NT' = r(N)

			*	s2
			tempvar s2
			qui sum `e'
			scalar `s2'= r(Var)*(`NT'-1)/(`NT'-`N')

			*	Time-Demeaning
			sort `id' `time'
			local xvar_dm
			foreach var of varlist `xvar' {
				tempvar `var'_m `var'_dm
				qui by `id': egen double ``var'_m'=mean(`var') 
				qui gen double ``var'_dm' = `var'-``var'_m' 
				local xvar_dm `xvar_dm' ``var'_dm'
			}
			
			capture matrix drop `Omega' `V0' `V2' `V3' `E'
			tempname V0 V2 V3 E
			
				
			*	V0 ========================
			mat opaccum `V0' = `xvar_dm' , gr(`id') opvar(`e') nocons
			mat `V0' = `V0'/`N'
			
		*	V2 ========================
			sort `obs'
			mat opaccum `V2' = `xvar_dm' , gr(`obs') opvar(`e_Ti') nocons
			mat `V2'=`V2'/`N'
			
		*	V3 ========================
			sort `id' `time'
			qui mat ac `V3' = `xvar_dm' , abs(`id') nocons
			mat `V3' = `V3'*`s2'/`N'
			
			*	vj = vech(Vj) =============
			tempname v0 v2 v3
			
			
			if c(version) >= 18 {
				foreach i of numlist 0 2 3 {
					mat `v`i'' = vech(`V`i'')
				}	    
			}
			else {
				foreach i of numlist 0 2 3 {
					vec_h `V`i''
					mat `v`i'' = r(v)
				}
			}	

			*	Cj ========================
			tempname m C2 C3 X c2i c3i M2 M3

			scalar `m'=rowsof(`v0')	

			mat `C2' = J(`m',`m',0)
			mat `C3' = J(`m',`m',0)

			if c(version) >= 18 {
				forvalues i=1/`=`N'' {
					
					mkmat `e' if `id'==`i', mat(`E')
					mkmat `xvar_dm' if `id'==`i', mat(`X')
					
					* C2
					mat `M2' = `X''*`E'*`E''*`X'-`X''*diag(vecdiag(`E'*`E''))*`X'
					mat `c2i' = vech(`M2')
					mat `C2' = `C2' + `c2i'*`c2i''
						
					* C3
					mat `M3' = `X''*`E'*`E''*`X'-`X''*`s2'*`X'
					mat `c3i' = vech(`M3')
					mat `C3' = `C3' + `c3i'*`c3i''
					
				}	    
			}
			else {
				forvalues i=1/`=`N'' {

					mkmat `e' if `id'==`i', mat(`E')
					mkmat `xvar_dm' if `id'==`i', mat(`X')
				
					* C2
					mat `M2' = `X''*`E'*`E''*`X'-`X''*diag(vecdiag(`E'*`E''))*`X'
					vec_h `M2'
					mat `c2i' = r(v)
					mat `C2' = `C2' + `c2i'*`c2i''
				
					* C3
					mat `M3' = `X''*`E'*`E''*`X'-`X''*`s2'*`X'
					vec_h `M3'
					mat `c3i' = r(v)
					mat `C3' = `C3' + `c3i'*`c3i''
					
				}	    
			}
				
			mat `C2' = `C2'/`N'
			mat `C3' = `C3'/`N'		

			*	Test 
			tempname df h2 h3 h2_p h3_p
			scalar `df'=`K'*(`K'+1)/2+1

			forvalues i=2/3 {
				tempname _h`i' _pinvC`i'
				
				if det(`C`i'') == 0 {
					di "Covariance matrix C`i' is singular. Use generalized inverse."
					mata: st_matrix("`_pinvC`i''",pinv(st_matrix("`C`i''")))
					mat `_h`i'' = `N'*(`v`i''-`v0')'*`_pinvC`i''*(`v`i''-`v0')
				}
				else {
					mat `_h`i'' = `N'*(`v`i''-`v0')'*invsym(`C`i'')*(`v`i''-`v0')
				}
				
				scalar `h`i'' = `_h`i''[1,1]
				scalar `h`i'_p' = 1-chi2(`df', `h`i'')			

			}
			
			*	Format statistics
			foreach i of numlist 2 3 {
				if `h`i'' > 99999 {
					local h`i'_fmt `"%9.0g"'
				}
				else	local h`i'_fmt `"%9.3f"'	
			}

		}

		*	Display

		di as text "{hline 50}"
		di as text "Hypothesis         Statistic    df     P-value"
		di as text "{hline 50}"
		
		if `e(Tcon)'==1 {
			di as result " H1 vs. Ha    " 	_col(19) `h1_fmt' `h1' 	///
											_col(30) %5.0f `df' 	///
											_col(37) %9.3f `h1_p'		
		}
		
		di as result " H2 vs. Ha    " 	_col(19) `h2_fmt' `h2'   	///
										_col(30) %5.0f `df' 		///
										_col(37) %9.3f `h2_p'
		di as result " H3 vs. Ha    " 	_col(19) `h3_fmt' `h3'   	///
										_col(30) %5.0f `df' 		///
										_col(37) %9.3f `h3_p'
		di as text "{hline 50}"
		if `e(Tcon)'==1 {
			di as text "H1: Cross-sectional homoskedasticity"
		}
		else {
			di as error "H1 is missing due to unbalanced data"
		}
		di as text "H2: Serially uncorrelated: e_it, x_it or both"
		di as text "H3: Homoskedasticity and serially uncorrelated"
		di as text "Ha: Heteroskedasticity"
		di
			
		*	Return list
		if `e(Tcon)'==1 {
			ret scalar df1   = `df'
			ret scalar h1   = `h1'
			ret scalar h1_p   = `h1_p'
		}
		
		ret scalar df2   = `df'
		ret scalar h2   = `h2'
		ret scalar h2_p   = `h2_p'
		
		ret scalar df3   = `df'
		ret scalar h3   = `h3'
		ret scalar h3_p   = `h3_p'	
	
	}	// end kezdi test

	
/*==========================================================================
			1.2. FEM: Regression-based test (Juhl & Sosa-Escudero, 2014)
==========================================================================*/
	
	else if `est' == 1 {
		tempvar e2	e2_i e2_dm

		qui gen  double `e2' = `e'^2
		qui egen double `e2_i' = mean(`e2')
		qui gen  double `e2_dm' = `e2' - `e2_i'
		
		local xvar_dm
		qui foreach var of local xvar {
			tempvar `var'_i `var'_dm
			egen double ``var'_i' = mean(`var'), by(id)
			gen double ``var'_dm' = `var' - ``var'_i'
			local xvar_dm `xvar_dm' ``var'_dm'
		}
		
*		H1: Var(e_it|X, u_i) = sigma_it^2

		qui reg `e2' `xvar'
		local lm1 = e(N) * e(r2)
		local df1 = e(df_m)
		local lm1_p = 1- chi2(`df1', `lm1')

*		H2: Var(e_it|X, u_i) = sigma_i^2

		qui reg `e2_dm' `xvar_dm'
		local lm2 = e(N) * e(r2)
		local df2 = e(df_m)
		local lm2_p = 1- chi2(`df2', `lm2')			
		
*		Show results

		forvalues i = 1/2 {
			if `lm`i'' > 99999 {
					local lm`i'_fmt `"%9.0g"'
			}
			else	local lm`i'_fmt `"%9.3f"'	
		}
		

		di
		di as text "Test for heteroscedasticity in fixed-T panel data models"
		di as text "Model:" _col(8) "Fixed-effects"
		di as text "H0:" 	_col(8) "Var(e_it | X_i, u_i) = " as result "sigma^2"
		di as text "{hline 50}"
		di as text _col(1) "H1" /*_col(15) "|"*/ 	_col(19) "Statistic" ///
								_col(33) "df" 	_col(39)  "P-value"
		di as text "{hline 50}"
		
		di as result "sigma_it^2    " 	_col(19) `lm1_fmt' `lm1'   	///
										_col(30) %5.0f `df1' 		///
										_col(37) %9.3f `lm1_p'
										
		di as result "sigma_i^2    " 	_col(19) `lm2_fmt' `lm2'   	///
										_col(30) %5.0f `df2' 		///
										_col(37) %9.3f `lm2_p'
		di as text "{hline 50}"	
		
*		return scalar
		ret scalar lm1_p	= `lm1_p'
		ret scalar df1   	= `df1'
		ret scalar lm1   	= `lm1'
		
		ret scalar lm2_p	= `lm2_p'
		ret scalar df2   	= `df2'
		ret scalar lm2   	= `lm2'
		
	}

	
/*==========================================================================
		2. REM: Regression-based test (Montes-Rojas & Sosa-Escudero, 2011)
==========================================================================*/
	
	else {

		qui reg `depvar' `xvar'		// OLS
		
		tempvar w w_i w_dm w_i_sq w_dm_sq w_dm_sq_i w_i_dm_sq _cons Ti p_Ti
		qui predict double `w' , r	
		qui egen double `w_i' = mean(`w') , by(id)
		qui gen  double `w_dm' = `w' - `w_i'
		qui gen  double `w_i_sq' = `w_i'^2
		qui gen  double `w_dm_sq' = `w_dm'^2
		
		qui gen  byte `_cons' = 1
		qui egen long `Ti' = total(`_cons'), by(id)
//		qui gen  double `p_Ti' = 1 / `Ti'
		qui egen double `w_dm_sq_i' = mean(`w_dm_sq'), by(id)
		qui gen  double `w_i_dm_sq' = `w_i_sq' - `w_dm_sq_i'/(`Ti'-1)
		qui by id: replace `w_i_dm_sq' = . if _n > 1
		
		local xvar_i
		local xvar_dm
		qui foreach var of local xvar {
			tempvar `var'_i `var'_dm
			
			egen double ``var'_i' = mean(`var'), by(id)
			local xvar_i `xvar_i' ``var'_i'
			
			gen double ``var'_dm' = `var' - ``var'_i'
			local xvar_dm `xvar_dm' ``var'_dm'
		}
		
*		H01: Var(e_it|X) = sigma_e^2 | Var(u_i|X) = sigma_u^2
		qui reg `w_dm_sq' `xvar_dm'
		local lm1 = e(N) * e(r2)
		local df1 = e(df_m)
		local lm1_p = 1- chi2(`df1', `lm1')

*		H02: Var(u_i|X) = sigma_u^2 | Var(e_it|X) = sigma_e^2
		qui reg `w_i_dm_sq' `xvar_i'
		local lm2 = e(N) * e(r2)
		local df2 = e(df_m)
		local lm2_p = 1- chi2(`df2', `lm2')	
		
*		H03: Var(u_i|X) = sigma_u^2, Var(e_it|X) = sigma_e^2	
		local lm3 = `lm1' + `lm2'
		local df3 = `df1' + `df2'
		local lm3_p = 1- chi2(`df3', `lm3')
		
*		Show results
		forvalues i = 1/3 {
			if `lm`i'' > 99999 {
					local lm`i'_fmt `"%9.0g"'
			}
			else	local lm`i'_fmt `"%9.3f"'	
		}
		

		di
		di as text "Test for heteroscedasticity in fixed-T panel data models"
		di as text "Model:" _col(8) "Random-effects"
		di as text "H1:" 	_col(8) "Var(u_i + e_it | X_i) = " as result "sigma_it^2"
		di as text "{hline 53}"
		di as text "Null hypothesis (H0)" _col(25) "Statistic" ///
								_col(39) "df" 	_col(45)  "P-value"
		di as text "{hline 53}"
		
		di as result "sigma_e^2 | sigma_u^2" 	_col(25) `lm1_fmt' `lm1'   	///
										_col(36) %5.0f `df1' 		///
										_col(43) %9.3f `lm1_p'
										
		di as result "sigma_u^2 | sigma_e^2" 	_col(25) `lm2_fmt' `lm2'   	///
										_col(36) %5.0f `df2' 		///
										_col(43) %9.3f `lm2_p'
										
		di as result "sigma_e^2 & sigma_u^2" _col(25) `lm3_fmt' `lm3'   	///
										_col(36) %5.0f `df3' 		///
										_col(43) %9.3f `lm3_p'										
		di as text "{hline 53}"	
		
*		return scalar
		ret scalar lm1_p	= `lm1_p'
		ret scalar df1   	= `df1'
		ret scalar lm1   	= `lm1'
		
		ret scalar lm2_p	= `lm2_p'
		ret scalar df2   	= `df2'
		ret scalar lm2   	= `lm2'
		
		ret scalar lm3_p	= `lm3_p'
		ret scalar df3   	= `df3'
		ret scalar lm3   	= `lm3'			
		
	}

restore
qui `cmdline'
	
end


/*=====================================================================
	Define vec_h() for STATA versions not allow vech()
=====================================================================*/

capture program drop vec_h
program define vec_h, rclass
	syntax name(name=matname)
	
	// Check if matrix exists
	capture matrix list `matname'
	if _rc {
	    di as error "Matrix `matname' not found"
		exit 198
	}

	// Get row/col number
	local n = rowsof(`matname')
	local k = colsof(`matname')

	// Check square matrix
	if `n' != `k' {
		di as error "Matrix must be square"
		exit 198
	}

	// Create empty column vector
	tempname v
	matrix `v' = J(`=(`n'*(`n'+1))/2', 1, .)

	// Get the lower triangle elements
	local idx = 1
	forvalues i = 1/`n' {
		forvalues j = 1/`i' {
			matrix `v'[`idx',1] = `matname'[`i',`j']
			local idx = `idx' + 1
		}
	}

    // Return in r()
    return matrix v = `v'
end


/*=====================================================================
	Define _get_indvars to get independent varlist from cmdline
=====================================================================*/

cap pro drop _get_indvars
pro def _get_indvars, rclass
	cap syntax varlist(ts fv) [if] [in] [aw pw fw] [, *]
//	di "`varlist'"
	return local varlist "`varlist'"
end
