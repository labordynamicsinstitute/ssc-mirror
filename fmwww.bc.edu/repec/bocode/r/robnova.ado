program robnova, rclass
	version 10
	syntax varlist(min=2 max=2 numeric) [if] [in]
	preserve
	tokenize `varlist'
	local dv `1'
	local iv `2'
	marksample touse
	qui levelsof `iv' if `touse', local(ivlevels)
	local size : list sizeof ivlevels
	if `size' <=2 {
		dis as error "Minimum number of groups needed in `iv' is 3."
		dis as error "The number of groups currently being compared in `iv' is `size'."
		dis as error "Model has been deliberately stopped."	
		error
	}
		else if `size' >= 2500 {
			dis as error "Maximum number of groups allowed in `iv' is 2,499."
			dis as error "Model has been deliberately stopped."
			error
		}
	foreach n of numlist `ivlevels' {
		if `n' < 0 {
			dis as error "`iv' has factor levels which are negative, this is not permitted."
			error
		}
		if mod(`n',1) {
			dis as error "`iv' has factor levels which are non-integer. Integer values are required."
			dis as error "The value producing this error is `n'."
			error
		}
	}
	*data screen & general descriptives
	foreach valid of numlist `ivlevels' {
		capture: sum `dv' if `touse' & `iv' == `valid'
		if _rc {
			dis as error "sum command did not run; error code "_rc
			error
		}
		if r(N) <= 1 {
			dis as error "There were insufficient observations in `iv' (Group #`valid') for outcome `dv'."
			error
		}
		if r(sd) == 0 {
			dis as error "There is no variability in `iv' (Group #`valid') for `dv'; the standard deviation is 0.00"
			error
		}
		if missing("`r(mean)'") {
			dis as error "Mean was not produced in `iv' (Group #`valid') for `dv'."
			error
		}
		if missing("`r(sd)'") {
			dis as error "SD was not produced in `iv' (Group #`valid') for `dv'."
			error
		}	
		if missing("`r(Var)'") {
			dis as error "Variance was not produced in `iv' (Group #`valid') for `dv'."
			error
		}	
		local m`valid' = r(mean) 
		local sd`valid' = r(sd)
		local var`valid' = r(Var)
		local n`valid' = r(N)
	}
	*fisher's statistics stuff
	capture: oneway `dv' `iv' if `touse'
	if _rc {
		dis as error "The basic ANOVA model you have specified cannot be run."
		dis as error "Model has been deliberately stopped."
		error
	}	
	local fis_df1 = r(df_m)
	local fis_df2 = r(df_r)
	local fis_f = r(F)
	local fis_p = Ftail(`fis_df1',`fis_df2',`fis_f')
	local ssm = `r(mss)'
	local ssr = `r(rss)'
	local sst = `ssm' + `ssr'
	local r2 = `ssm'/`sst'
	local num = `ssm'
	local totn = r(N)
	local nobs = string(round(`totn',1),"%14.0fc")
	if (`fis_df1' == . | `fis_df2' == . | `fis_f' == . | `fis_p' == .) {
		dis as error "Basic ANOVA model did not produce needed value."
		error
	}
	*welch's calcs
	foreach n of numlist `ivlevels' {													//weighting calculation per level of group
		local wght`n' = `n`n''/`var`n''
	}
	local weighttotal = 0
	foreach n of numlist `ivlevels' {
		local weighttotal = `weighttotal' + `wght`n''									//weights are summed together	
	}
	foreach n of numlist `ivlevels' {
		local w`n' = `wght`n'' * `m`n''
	}	
	local mean_num = 0
	local mean_den = 0
	foreach n of numlist `ivlevels' {
		local mean_num = `mean_num' + `w`n''
		local mean_den = `mean_den' + `wght`n''
	}	
	local grandmean = `mean_num'/`mean_den'
	foreach n of numlist `ivlevels' {
		local welch_ss`n' = `w`n'' * (`m`n'' - `grandmean')
	}
	local welch_ssm = 0
	foreach n of numlist `ivlevels' {
		local welch_ssm = `welch_ssm' + `welch_ss`n''
	}
	local welch_msm = `welch_ssm'/(`size' - 1)											//mean sums of squares		
	foreach n of numlist `ivlevels' {													//lambda numerator calculation
		local lam`n' = (1-(`wght`n''/`weighttotal'))^2/(`n`n''-1)						//lambda numerator calculated per group
	}	
	foreach n of numlist `ivlevels' {													//lambda numerator calculation
		local lam_num = `lam_num' + `lam`n''											//lambda totalled across groups
	}
	local lam_num = 3 * `lam_num'														//lambda numerator produced
	local lam_den = `size'^2-1															//lambda denominator produced
	local lambda = `lam_num'/`lam_den'													//lambda is stored as local
	local wel_f = `welch_msm'/(1+(2*`lambda'*(`size'-2)/3))								//welch's f stat
	local wel_df1 = `size' - 1															//welch's df1
	local wel_df2 = 1/`lambda'															//welch's df2
	local wel_p = Ftail(`wel_df1',`wel_df2',`wel_f')									//welch's p-value
	*brown-forsythe calcs
	foreach n of numlist `ivlevels' {													//denominator calculation per group
		local den`n' = (1-(`n`n''/`totn')) * `var`n''
	}
	local denom = 0
	foreach n of numlist `ivlevels' {													//denominator calculation per group
		local denom = `denom' + `den`n''												//group denominators become summed
	}
	foreach n of numlist `ivlevels' {
		local s`n' = (`den`n''/`denom')^2/(`n`n''-1)
	}
	local stot = 0
	foreach n of numlist `ivlevels' {
		local stot = `stot' + `s`n''
	}
	local bf_f = `num'/`denom'															//bf f-stat
	local bf_df1 = `size' - 1															//bf df1
	local bf_df2 = 1/`stot'																//bf df2; //reciprocal of summed total value
	local bf_p = Ftail(`bf_df1',`bf_df2',`bf_f')										//bf p-value
	*scalars
	return scalar N = `totn'
	return scalar lambda = `lambda'
	return scalar r2 = `r2'
	return scalar sst = `sst'
	return scalar ssr = `ssr'
	return scalar ssm = `ssm'
	return scalar bf_p = `bf_p'
	return scalar bf_df2 = `bf_df2'
	return scalar bf_df1 = `bf_df1'	
	return scalar bf_F = `bf_f'	
	return scalar wel_p = `wel_p'	
	return scalar wel_df2 = `wel_df2'	
	return scalar wel_df1 = `wel_df1'	
	return scalar wel_F = `wel_f'	
	return scalar fis_p = `fis_p'	
	return scalar fis_df2 = `fis_df2'	
	return scalar fis_df1 = `fis_df1'
	return scalar fis_F = `fis_f'
	clear
	tempvar row column cell
	qui gen strL `row' = ""
	label var `row' "Test"
	qui gen strL `column' = " "
	label var `column' " "
	qui gen strL `cell' = " "
	qui set obs 12
	local loop = 0
	foreach t in fis wel bf {
		foreach tt in f df1 df2 p {
			local ++loop
			if "`t'" == "fis" {
				qui replace `row' = "Fisher's" in `loop'
			}
				else if "`t'" == "wel" {
					qui replace `row' = "Welch's" in `loop'
				}
					else if "`t'" == "bf" {
						qui replace `row' = "Brown-Forsythe's" in `loop'
					}
			if "`tt'" == "f" {
				qui replace `column' = "F" in `loop'
			}
				else if "`tt'" == "df1" {
					qui replace `column' = "df1" in `loop'
				}
					else if "`tt'" == "df2" {
						qui replace `column' = "df2" in `loop'
					}
						else if "`tt'" == "p" {
							qui replace `column' = "p" in `loop'
						}
			local temp = string(round(``t'_`tt'',.0001),"%20.4f")
			if "`tt'" == "df1" {
				local temp = string(round(``t'_`tt'',1),"%20.0f")
			}
			qui replace `cell' = "`temp'" in `loop'
		}
	}
	local r2temp = string(round(`r2',.000001),"%8.6f")
	dis ""
	dis as text "Outcome variable was " as result "`dv'" as text " and predictor variable was " as result "`iv'"
	dis ""
	local temp = string(round(`ssm',.0001),"%20.4f")
	dis as text "Sum of Squares Model = " as result "`temp'"
	local temp = string(round(`ssr',.0001),"%20.4f")
	dis as text "Sum of Squares Residual = " as result "`temp'"
	local temp = string(round(`sst',.0001),"%20.4f")
	dis as text "Sum of Squares Total = " as result "`temp'"
	dis as text "R-squared = " as result"`r2temp'"
	tabdisp `row' `column', cellvar(`cell') cen
	dis as text "Total number of observations used was " as result "`nobs'" as text "."
end
