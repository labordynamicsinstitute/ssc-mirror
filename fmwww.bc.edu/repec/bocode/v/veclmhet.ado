*	VEC Residual Heteroskedasticity Tests
* 	Version 1.0.1	Manh H. B. 01/08/2025
*	Following Doornik (1996)
* 	Mod 1.0.1 to replace all global macros by local macros

cap program drop veclmhet
program define veclmhet, rclass
	version 11.0
	
	syntax , [Nocross]
	
		
	if "`e(cmd)'" != "vec" {
        display in red as error "Last estimates not vec"
        exit 301
    }
	
		
	tempname vec_res model_f model_r veclag omega omega0 LM lm lm_df lm_p
	
	if "`e(trend)'"=="trend" {
		tempvar _trend
		qui gen `_trend' = _n
		local yvar `_trend'
	}
	
	else {
		local yvar
	}

	* Predict e_i, e_ij
	qui estimates store `vec_res'	
	forvalues i=1/`e(k_dv)' {
		tempvar _e`i'
		qui predict `_e`i'' if e(sample), r eq(#`i')
	}	
	
	* Predict _ce_i
	forvalues i=1/`e(k_ce)' {
		tempvar _ce`i' l_ce`i'
		qui predict `_ce`i'' if e(sample), ce eq(#`i')
		qui gen `l_ce`i'' = 0
		qui replace `l_ce`i'' = `_ce`i''[_n-1] if `_ce`i''[_n-1]<. 
		local yvar `yvar' `l_ce`i''
	}
	
	local sigma_ij
	forvalues i=1/`e(k_dv)' {
		forvalues j=1/`e(k_dv)' {
			if `j'>=`i' {
				tempvar _e`i'`j'
				qui gen `_e`i'`j''=`_e`i''*`_e`j'' if e(sample)
				local sigma_ij `sigma_ij' `_e`i'`j''
			}
		}
	}
	
	* Generating right hand-side variables
	*		Linear term
	*local yvar `yvar'
	scalar `veclag' = e(n_lags) - 1
	local mlag = `veclag'
	forvalues i=1/`mlag' {
		foreach var of varlist `e(endog)' {
			tempvar dl`i'_`var'
			qui gen `dl`i'_`var'' = dl`i'.`var'
			local yvar `yvar' `dl`i'_`var''
		}
	}
	
	*		Squared term
	local yvar_sq
	foreach var of varlist `yvar' {
		tempvar `var'_sq
		qui gen ``var'_sq' = `var'^2
		local yvar_sq `yvar_sq' ``var'_sq'
	}
	
	* Auxiliary regression (White, 1980)
	*		Cross-term
	if "`nocross'"=="" {
		qui reg3 (`sigma_ij' = c.(`yvar')##c.(`yvar' `e(sindicators)')) ///
			if e(sample), ols small
	}
	
	else {
		qui reg3 (`sigma_ij' = `yvar' `yvar_sq' `e(sindicators)') ///
			if e(sample), ols small
	}
			
	qui estimates store `model_f'
	qui reg3 (`sigma_ij' = ) if e(sample), ols small
	qui estimates store `model_r'

	*	LM test for heteroscedasticity (~ EViews version)
	qui estimates restore `model_r'
	mat `omega0' = e(Sigma)*(e(N)-e(k)/e(k_eq))

	qui estimates restore `model_f'
	scalar `lm_df' = e(k)-e(k_eq)
	mat `omega' = e(Sigma)*(e(N)-e(k)/e(k_eq))
	mat `LM' = e(N)*trace((`omega0'-`omega')*invsym(`omega0'))
	scalar `lm' = `LM'[1,1]
	scalar `lm_p' = 1-chi2(`lm_df', `lm')
	
	qui estimates restore `vec_res'
			
	
	if "`nocross'"=="" {
		di as txt "VEC Residual Heteroscedasticity Tests (Includes Cross Terms)"
	}
	else {
		di as txt "VEC Residual Heteroscedasticity Tests (Excludes Cross Terms)"
	}
	di as txt "H0: Homoscedasticity"
	di as txt _col(5) "Chi2( " %3.0f `lm_df' ") = " 	///
		as res %10.4f `lm'
	di as txt _col(5) "Prob > chi2 = " as res %11.4f `lm_p'
	di
	
	ret scalar lm   = `lm'
	ret scalar df   = `lm_df'
	ret scalar p    = `lm_p'
			
end