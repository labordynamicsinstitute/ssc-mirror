*	VAR Residual Heteroskedasticity Tests
* 	Version 1.0.1	Manh H. B. 01/08/2025
*	Following Doornik (1996)
* 	Mod 1.0.1 to allow time series operator in VAR: exog() option
*				and replace all global macros by local macros


cap program drop varlmhet
program define varlmhet, rclass
	version 11.0
	
	syntax , [Nocross]
			
	if "`e(cmd)'" != "var" {
        display in red as error "Last estimates not var"
        exit 301
    }
			
	tempname var_res model_f model_r omega omega0 LM lm lm_df lm_p

	* Predict e_i, e_ij
	qui estimates store `var_res'	
	forvalues i=1/`e(k_dv)' {
		tempvar _e`i'
		qui predict `_e`i'' if e(sample), r eq(#`i')
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
* 1.0.1 Allow time series operator in exog() option!
	qui tsrevar `e(exog)'
	
	*		Linear term
	local yvar "`r(varlist)'"
	forvalues i=1/`e(mlag)' {
		foreach var of varlist `e(endog)' {
			tempvar l`i'_`var'
			qui gen `l`i'_`var'' = 0
			qui replace `l`i'_`var'' = `var'[_n-`i'] if _n>`i' & `var'[_n-`i']<.
			local yvar `yvar' `l`i'_`var''
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
		qui reg3 (`sigma_ij' = c.(`yvar')##c.(`yvar')) ///
			if e(sample), ols small
	}
	
	else {
		qui reg3 (`sigma_ij' = `yvar' `yvar_sq') ///
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
	
	qui estimates restore `var_res'
	
	*	Display
 	
	if "`nocross'"=="" {
		di as txt "VAR Residual Heteroscedasticity Tests (Includes Cross Terms)"
	}
	else {
		di as txt "VAR Residual Heteroscedasticity Tests (Excludes Cross Terms)"
	}
	di as txt "H0: Homoscedasticity"
	di as txt _col(5) "Chi2(" %3.0f `lm_df' ") = " 	///
		as res %10.4f `lm'
	di as txt _col(5) "Prob > chi2 = " as res %11.4f `lm_p'
	di
	
	ret scalar lm   = `lm'
	ret scalar df   = `lm_df'
	ret scalar p    = `lm_p'
			
end