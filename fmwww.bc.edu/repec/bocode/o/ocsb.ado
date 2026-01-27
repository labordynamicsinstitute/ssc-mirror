*! 1.0.0 Ariel Linden 23Jan2026

program define ocsb, rclass
	version 11
	syntax varname(ts) [if][in] [, Lag(integer 0) SEasonal(integer 0) REGress]
    
	if "`_dta[_TStvar]'" == "" {
		di as error "time variable not set, use {bf:tsset} {it:varname ...}"
		exit 111
    }
	
	marksample touse
    
	// preserve and save original data
	preserve
	tempfile original_data
	qui save "`original_data'"
    
	// get seasonal period, either from user or from tsset
	if `seasonal' > 0 {
		* user-specified seasonal period
		local m = `seasonal'
	}
	else {
		* try to get from tsset
		capture tsset
		if _rc != 0 {
			di as error "data must be tsset or specify seasonal()"
			qui use "`original_data'", clear
			exit 498
		}
        
		* get the time unit from tsset
		local timeunit = r(unit1)
        
		// convert time unit to numeric seasonal period
		if "`timeunit'" == "1" | "`timeunit'" == "" {
			local m = 1
		}
		else if "`timeunit'" == "2" {
			local m = 2
		}
		else if "`timeunit'" == "4" | "`timeunit'" == "q" {
			local m = 4
		}
		else if "`timeunit'" == "12" | "`timeunit'" == "m" {
			local m = 12
		}
		else if "`timeunit'" == "52" | "`timeunit'" == "w" {
			local m = 52
		}
		else if "`timeunit'" == "365" | "`timeunit'" == "d" {
			local m = 365
		}
		else if "`timeunit'" == "." {
			* time variable is just set of numbers
			di as error "cannot determine seasonal period from tsset."
			di as error "Please specify seasonal() option."
			exit 498
		}
	}
    
	// check if seasonal period is valid
	if `m' == 1 {
		di as error "data must be seasonal to use OCSB test"
		exit 498
	}
    
	// round time period to integer
	local m = round(`m')
    
	// use only touse data
	qui keep if `touse'
    
	local x "`varlist'"
	local N = _N
    
	// check if we have enough observations
	if `N' < `m' + `lag' + 3 {
		di as error "m = `m', lag = `lag', need at least " `m' + `lag' + 3 " observations."
		exit 498
	}
    
	tempvar obs_var
	qui gen `obs_var' = _n
    

	// gen y
	tempvar y
	qui gen `y' = .
    
	// gen seasonal difference
	tempvar sdiff
	qui gen `sdiff' = .
	forvalues i = `=`m'+1'/`N' {
		qui replace `sdiff' = `x'[`i'] - `x'[`=`i'-`m''] in `i'
	}
    
	// gen non-seasonal difference
	forvalues i = `=`m'+2'/`N' {
		qui replace `y' = `sdiff'[`i'] - `sdiff'[`=`i'-1'] in `i'
	}
    
	
	// gen AR lags
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			tempvar ar`i'
			qui gen `ar`i'' = .
			forvalues j = `=`m'+`i'+2'/`N' {
				qui replace `ar`i'' = `y'[`=`j'-`i''] in `j'
			}
		}
	}
    
	// apply tail(y, -lag) as in R
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			qui replace `y' = . in `i'
			if `lag' > 0 {
				forvalues j = 1/`lag' {
					qui replace `ar`j'' = . in `i'
				}
			}
		}
	}
    
	// keep only complete cases
	qui keep if !missing(`y')
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			qui keep if !missing(`ar`i'')
		}
	}
    
	local n_ar = _N
    
	if `n_ar' < 2 {
		di as error "insufficient observations after removing missing values for AR model"
		exit 498
	}
    
	// estimate AR model to get lambda coefficients
	if `lag' > 0 {
		local reg_eq "`y'"
		forvalues i = 1/`lag' {
			local reg_eq "`reg_eq' `ar`i''"
		}
		capture qui reg `reg_eq', noconstant
		if _rc != 0 {
			di as error "AR model estimation failed"
			exit 498
		}
	}
	else {
		capture qui reg `y', noconstant
		if _rc != 0 {
			di as error "AR model estimation failed"
			exit 498
		}
	}
    
	matrix lambda = e(b)
    
	// save mf data
	tempfile mf_data
	qui save "`mf_data'"
    

	// compute Z4
	qui use "`original_data'"
	qui keep if `touse'
    
	local N = _N
	tempvar obs_z4
	qui gen `obs_z4' = _n
    
	// gen seasonal difference
	tempvar sdx
	qui gen `sdx' = .
	forvalues i = `=`m'+1'/`N' {
		qui replace `sdx' = `x'[`i'] - `x'[`=`i'-`m''] in `i'
	}
    
	// gen lagged seasonal differences
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			tempvar sdx_lag`i'
			qui gen `sdx_lag`i'' = .
			forvalues j = `=`m'+`i'+1'/`N' {
				qui replace `sdx_lag`i'' = `sdx'[`=`j'-`i''] in `j'
			}
		}
	}
    
	// compute Z4
	tempvar Z4
	qui gen `Z4' = `sdx'
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			if `i' <= colsof(lambda) {
				local coef = lambda[1, `i']
				qui replace `Z4' = `Z4' - `coef' * `sdx_lag`i''
			}
		}
	}
    
	// save Z4
	keep `obs_z4' `Z4'
	rename `obs_z4' `obs_var'
	tempfile z4_data
	qui save "`z4_data'"
    
	qui use "`original_data'"
	qui keep if `touse'
    
	local N = _N
	tempvar obs_z5
	qui gen `obs_z5' = _n
    
	// gen non-seasonal difference
	tempvar dx
	qui gen `dx' = .
	forvalues i = 2/`N' {
		qui replace `dx' = `x'[`i'] - `x'[`=`i'-1'] in `i'
	}
    
	// gen lagged non-seasonal differences
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			tempvar dx_lag`i'
			qui gen `dx_lag`i'' = .
			forvalues j = `=`i'+2'/`N' {
				qui replace `dx_lag`i'' = `dx'[`=`j'-`i''] in `j'
			}
		}
	}
    
	// compute Z5
	tempvar Z5
	qui gen `Z5' = `dx'
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			if `i' <= colsof(lambda) {
				local coef = lambda[1, `i']
				qui replace `Z5' = `Z5' - `coef' * `dx_lag`i''
			}
		}
	}
    
	// save Z5
	keep `obs_z5' `Z5'
	rename `obs_z5' `obs_var'
	tempfile z5_data
	qui save "`z5_data'"
    
	qui use "`mf_data'"
    
	// merge with Z4 and Z5
	capture qui merge 1:1 `obs_var' using "`z4_data'", nogenerate
	if _rc != 0 {
		di as error "merge with Z4 data failed"
		exit 498
	}
    
	capture qui merge 1:1 `obs_var' using "`z5_data'", nogenerate
	if _rc != 0 {
		di as error "merge with Z5 data failed"
		exit 498
	}
    
	// gen lagged Z4 and Z5
	tempvar Z4_lag Z5_lag
	qui gen `Z4_lag' = .
	qui gen `Z5_lag' = .
    
	local n = _N
	forvalues i = 2/`n' {
		qui replace `Z4_lag' = `Z4'[`=`i'-1'] in `i'
	}
    
	forvalues i = `=`m'+1'/`n' {
		qui replace `Z5_lag' = `Z5'[`=`i'-`m''] in `i'
	}
    
	// keep complete cases for final regression
	qui keep if !missing(`y', `Z4_lag', `Z5_lag')
	if `lag' > 0 {
		forvalues i = 1/`lag' {
			qui keep if !missing(`ar`i'')
		}
	}
    
	local n_final = _N
    
	if `n_final' < 2 {
		di as error "insufficient observations for final regression"
		exit 498
	}
    
	// final regression with no constant
	if `lag' > 0 {
		local final_eq "`y'"
		forvalues i = 1/`lag' {
			local final_eq "`final_eq' `ar`i''"
		}
		local final_eq "`final_eq' `Z4_lag' `Z5_lag'"
		if "`regress'" != "" {
			reg `final_eq', noconstant
		}
		else {
			capture qui reg `final_eq', noconstant
		}
		if _rc != 0 {
			di as error "Final regression failed"
			exit 498
		}
	}
	else {
		* show regress table
		if "`regress'" != "" {
			reg `y' `Z4_lag' `Z5_lag', noconstant
		}
		else {
			capture qui reg `y' `Z4_lag' `Z5_lag', noconstant
		}
		if _rc != 0 {
			di as error "final regression failed"
			exit 498
		}
	}
    
	local tstat = _b[`Z5_lag'] / _se[`Z5_lag']
	local coeff = _b[`Z5_lag']
    
	// critical values
	local log_m = ln(`m')
	local critical = -0.2937411 * exp(-0.2850853*(`log_m' - 0.7656451) - 0.05983644*((`log_m' - 0.7656451)^2)) - 1.652202
    
	// display results
	di ""
	di as txt "Test statistic: " as result %7.4f `tstat' as txt", 5% critical value: " as result %7.4f `critical'
	di as txt "Coefficient: " as result %7.4f `coeff'
	di as txt "Observations: " as result `n_final' as txt ", Lag order: " as result `lag'
	di as txt "alternative hypothesis: stationary"
    

	// saved results
	return scalar tstat = `tstat'
	return scalar crit = `critical'
	return scalar coef = `coeff'
	return scalar lag = `lag'
	return scalar m = `m'
	return scalar N = `n_final'
    
	// restore original data
	restore

end