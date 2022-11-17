program robnova, rclass
version 10
args dv iv
syntax varlist(min=2 max=2 numeric) [if]
qui levelsof `iv' `if', local(levels)
	foreach l of local levels {
	local burn = mod(`l',1)
		if `burn' != 0 {
		dis as error "robnova requires factor variables are integers; `iv' has fractional value for a variable level (i.e., `l')"
		error
		}
	}
local size : list sizeof levels
capture: anova `dv' `iv' `if'															//FISHER'S F 	
local fisdf1 = e(df_m)
local fisdf2 = e(df_r)
local fisf = e(F)
local fisp = Ftail(`fisdf1',`fisdf2',`fisf')
local r2val = e(r2)
local r2adj = e(r2_a)
local ssm = e(mss)
local ssr = e(rss)
local sst = `ssm' + `ssr'
	if (_rc != 0 | `fisdf1' == . | `fisdf2' == . | `fisf' == . | `fisp' == .) {
	dis as error "The basic ANOVA model you have specified cannot be run."
	dis as error "Perhaps you have restricted the sample to a single group?"	
	dis as error "Model has been deliberately stopped."
	error
	}
	if `size' <=2 {
	dis as error "Minimum number of groups needed in `iv' is 3."
	dis as error "The number of groups currently being compared in `iv' is `size'."
	dis as error "Model has been deliberately stopped."	
	error
	}
	if "`if'" == "" {
	local cond = 0 
	local tcomm1 "qui tabstat `dv' if `iv'=="
	local tcomm2 ", statistics(mean sd n) save"
	}
		else if "`if'" != "" {
		local cond = 1
		local tcomm1 "qui tabstat `dv' `if' & `iv'=="
		local tcomm2 ", statistics(mean sd n) save"
		}
			else {
			}
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	`tcomm1'`nn'`tcomm2'
	matrix mat = r(StatTotal)
	local m`n' = mat[1,1]															
	local sd`n' = mat[2,1]
	local var`n' = mat[2,1]^2														
	local n`n' = mat[3,1]															
		if `sd`n'' == 0 | `sd`n'' == . {
		dis as error "No variance in Group #`nn' in `iv'."
		dis as error "All observations in this group have reported the same score for `dv'. "
		dis as error "Model has been deliberately stopped."
		error
		}
		if `n`n'' <=1 {
		dis as error "Sample size for Group #`nn' in `iv' is insufficient for calculations."
		dis as error "There are `n`n'' observations."
		dis as error "Model has been deliberately stopped."
		error
		}
	}
	foreach nn of numlist `levels' {													//weighting calculation per level of group
	local n : list posof "`nn'" in levels
	local wght`n' = `n`n''/`var`n''
	}
local weighttotal = 0
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local weighttotal = `weighttotal' + `wght`n''									//weights are summed together	
	}
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local w`n' = `wght`n'' * `m`n''
	}	
local mean_num = 0
local mean_den = 0
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local mean_num = `mean_num' + `w`n''
	local mean_den = `mean_den' + `wght`n''
	}	
local grandmean = `mean_num'/`mean_den'
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local welch_ss`n' = `w`n'' * (`m`n'' - `grandmean')
	}
local welch_ssm = 0
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local welch_ssm = `welch_ssm' + `welch_ss`n''
	}
local welch_msm = `welch_ssm'/(`size' - 1)											//mean sums of squares		
	foreach nn of numlist `levels' {													//lambda numerator calculation
	local n : list posof "`nn'" in levels
	local lam`n' = (1-(`wght`n''/`weighttotal'))^2/(`n`n''-1)						//lambda numerator calculated per group
	}	
	foreach nn of numlist `levels' {												//lambda numerator calculation
	local n : list posof "`nn'" in levels
	local lam_num = `lam_num' + `lam`n''											//lambda totalled across groups
	}
local lam_num = 3 * `lam_num'														//lambda numerator produced
local lam_den = `size'^2-1															//lambda denominator produced
local lambda = `lam_num'/`lam_den'													//lambda is stored as local
local welf = `welch_msm'/(1+(2*`lambda'*(`size'-2)/3))								//welch's f stat
local weldf1 = `size' - 1															//welch's df1
local weldf2 = 1/`lambda'															//welch's df2
local welp = Ftail(`weldf1',`weldf2',`welf')										//welch's p-value
qui oneway `dv' `iv' `if'															//BROWN-FORSYTHE'S F STATISTIC
local totn = r(N)
local num = r(mss)
	foreach nn of numlist `levels' {													//denominator calculation per group
	local n : list posof "`nn'" in levels
	local den`n' = (1-(`n`n''/`totn')) * `var`n''
	}
local denom = 0
	foreach nn of numlist `levels' {													//denominator calculation per group
	local n : list posof "`nn'" in levels
	local denom = `denom' + `den`n''												//group denominators become summed
	}
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local s`n' = (`den`n''/`denom')^2/(`n`n''-1)
	}
local stot = 0
	foreach nn of numlist `levels' {
	local n : list posof "`nn'" in levels
	local stot = `stot' + `s`n''
	}
local stot = 1/`stot'																//reciprocal of summed total value
local bff = `num'/`denom'															//bf f-stat
local bfdf1 = `size' - 1															//bf df1
local bfdf2 = `stot'																//bf df2
local bfp = Ftail(`bfdf1',`bfdf2',`bff')											//bf p-value
local r2 = `ssm'/`sst'
return clear
ereturn clear
sreturn clear
return scalar lambda = `lambda'
return scalar r2 = `r2'
return scalar sst = `sst'
return scalar ssr = `ssr'
return scalar ssm = `ssm'
return scalar bf_p = `bfp'
return scalar bf_df2 = `bfdf2'
return scalar bf_df1 = `bfdf1'	
return scalar bf_F = `bff'	
return scalar wel_p = `welp'	
return scalar wel_df2 = `weldf2'	
return scalar wel_df1 = `weldf1'	
return scalar wel_F = `welf'	
return scalar fis_p = `fisp'	
return scalar fis_df2 = `fisdf2'	
return scalar fis_df1 = `fisdf1'
return scalar fis_F = `fisf'
local bf_p = `bfp'
local bf_df2 = `bfdf2'
local bf_df1 = `bfdf1'	
local bf_F = `bff'	
local wel_p = `welp'	
local wel_df2 = `weldf2'	
local wel_df1 = `weldf1'	
local wel_F = `welf'	
local fis_p = `fisp'	
local fis_df2 = `fisdf2'	
local fis_df1 = `fisdf1'
local fis_F = `fisf'
local temp = string(round(`r2',.00001),"%7.05f")
	dis as text "Outcome variable is " as result"`dv'"
	dis as text "Predictor variable is " as result"`iv'"
	dis as text "R-squared = " as result"`temp'" _newline(1)
	dis as text "  Test " _skip(13) "{c |} " _skip(4) "F" _skip(7)"df1"  _skip(6) "df2"  _skip(9) "p"
	dis as text "{hline 20}{c +}{hline 40}"
	dis as text _skip(2) "Fisher's          {c |}" as result %9.04f `fisf' "    " %2.0f `fis_df1' "   "  %9.04f `fis_df2' "    "  %06.04f `fisp'
	dis as text _skip(2) "Welch's           {c |}" as result %9.04f `welf' "    " %2.0f `wel_df1' "   "  %9.04f `wel_df2' "    "  %06.04f `welp'
	dis as text _skip(2) "Brown-Forsythe's  {c |}" as result %9.04f `bff'  "    " %2.0f `bf_df1'  "   "  %9.04f `bf_df2'  "    "  %06.04f `bfp' 
	dis as text "{hline 61}"
end
