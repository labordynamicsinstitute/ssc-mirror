*! 1.0.0 Ariel Linden 20Jan2026

program define arima_forecast, rclass
    version 11
    syntax [, h(integer 1) Level(cilevel) PREfix(name) FIGure REPLace *]
    
	// error if -arima- was not the previous estimation model
	if "`e(cmd)'" != "arima" {
		di as error "arima_forecast can only be used after arima estimation"
		exit 301
	}
    
	// error if arima has covariates
	if "`e(covariates)'" != "_NONE" {
        di as error "arima_forecast cannot be used with arima models that have covariates"
        exit 198
    }
    
	// error if arima was run with [if][in] qualifiers
	local cmdline `e(cmdline)'
	if ustrregexm("`cmdline'", "(if |in )") {
        di as error "arima_forecast cannot be used with arima models that have [if][in] qualifiers"
		exit 198
	}
    
	************************************************
	// replace variables in data and drop added rows
	************************************************
	if "`replace'" != "" {
		* get time variable and current max time
		qui tsset
		local timevar `r(timevar)'
		local tmaxs `r(tmaxs)'
        
		* get the numeric value of the last time in estimation sample
		sort `timevar'
		local orig_obs = e(N)
		qui sum `timevar' in 1/`orig_obs'
		local last_est_time = r(max)
        
		* drop any observations with time > last_est_time (this assumes that the user has not added additional obs)
		qui count if `timevar' > `last_est_time' & !missing(`timevar')
		local num_to_drop = r(N)
		if `num_to_drop' > 0 {
			qui drop if `timevar' > `last_est_time'
		}
        
		* generate variable names to check and drop if they exist
		if "`prefix'" != "" {
			local pred_stub "`prefix'"
		}
		else {
			local pred_stub ""
		}
        
		* get confidence level suffix
		if "`level'" != "" {
			local level_suffix "`level'"
		}
		else {
			local level_suffix "95"  // default
		}
        
		* generate variable names
		local pred_var "`pred_stub'pred"
		local se_var "`pred_stub'se"
		local lb_var "`pred_stub'll`level_suffix'"
		local ub_var "`pred_stub'ul`level_suffix'"
		local forecast_ind "`pred_stub'forecast"
        
		* drop existing forecast variables if they exist
		foreach var in `pred_var' `se_var' `lb_var' `ub_var' `forecast_ind' {
			capture confirm variable `var'
			if !_rc {
				qui drop `var'
			}
		}
	} // end replace
    
	******************************************************************************************
	// make sure that the arima model was specified with arima(p,d,q) and sarima(P,D,Q) format
	******************************************************************************************
	* check if arima() was used with p,d,q specification
	local has_arima_spec = ustrregexm("`cmdline'", "arima\([0-9]+,[0-9]+,[0-9]+\)")
    
	* check if ar() and/or ma() were used separately
	local has_ar_spec = ustrregexm("`cmdline'", "ar\(")
	local has_ma_spec = ustrregexm("`cmdline'", "ma\(")
    
	* check for seasonal specification - expanded to include mar() and mma()
	local has_sarima_spec = ustrregexm("`cmdline'", "sarima\([0-9]+,[0-9]+,[0-9]+,[0-9]+\)")
	local has_sar_spec = ustrregexm("`cmdline'", "sar\(")
	local has_sma_spec = ustrregexm("`cmdline'", "sma\(")
	local has_mar_spec = ustrregexm("`cmdline'", "mar\(")
	local has_mma_spec = ustrregexm("`cmdline'", "mma\(")
    
	* error if ar() or ma() were used separately
	if (!`has_arima_spec') & (`has_ar_spec' | `has_ma_spec') {
		di as error "arima_forecast requires the arima(p,d,q) specification"
		exit 198
	}
    
	* default orders
	local p 0
	local d 0
	local q 0
	local P 0
	local D 0
	local Q 0
	local s 1
    
	* parse non-seasonal arima(p,d,q) specification
	if `has_arima_spec' {
		if ustrregexm("`cmdline'", "arima\(([0-9]+),([0-9]+),([0-9]+)\)") {
			local p = ustrregexs(1)
			local d = ustrregexs(2)
			local q = ustrregexs(3)
		}
	}
	else {
		* if user does not specify arima() components at all (mean model)
		di as text "could not parse full ARIMA(p,d,q) specification from command line"
	}
    
	* parse seasonal sarima(P,D,Q,s) specification if present
	if `has_sarima_spec' {
		if ustrregexm("`cmdline'", "sarima\(([0-9]+),([0-9]+),([0-9]+),([0-9]+)\)") {
			local P = ustrregexs(1)
			local D = ustrregexs(2)
			local Q = ustrregexs(3)
			local s = ustrregexs(4)
		}
	}
    else if `has_sar_spec' | `has_sma_spec' | `has_mar_spec' | `has_mma_spec' {
		di as error "seasonal models must use sarima(P,D,Q,s) specification"
        exit 198
	}
    
	***********************************************************
	// verify that "nonconstant" is specified with differencing
	***********************************************************
	local has_constant = 0
    
	* look for a constant in the first position of the coefficient matrix
	matrix b = e(b)
	local colnames : colfullnames b
	local first_name : word 1 of `colnames'
    
	* check if the first coefficient name contains "_cons"
	if strpos("`first_name'", "_cons") > 0 {
		local has_constant = 1
	}
    
	if (`d' > 0 | `D' > 0) & `has_constant' {
		di as error "specify {bf:{ul:nocons}tant} with an arima model when differencing"
		exit 198
	}
    
	***********************
	// extract coefficients
	***********************
	local sigma = e(sigma)
	local sigma2 = `sigma'^2
    
	* extract AR and MA coefficients by name pattern
	local phi_str    // Non-seasonal AR
	local theta_str  // Non-seasonal MA
	local Phi_str    // Seasonal AR
	local Theta_str  // Seasonal MA
    
	local i 0
	foreach name in `colnames' {
		local i = `i' + 1
		local val = b[1, `i']
        
		* skip sigma constant
		if "`name'" == "sigma:_cons" continue
        
		* non-seasonal AR coefficients: pattern ends with .ar and starts with ARMA:
		if ustrregexm("`name'", "^ARMA:L[0-9]*\.ar$") {
			local phi_str `phi_str' `val'
		}
		* non-seasonal MA coefficients: pattern ends with .ma and starts with ARMA:
		else if ustrregexm("`name'", "^ARMA:L[0-9]*\.ma$") {
			local theta_str `theta_str' `val'
		}
		* seasonal AR coefficients: pattern ends with .ar and starts with ARMA[2-9]:
		else if ustrregexm("`name'", "^ARMA[2-9]:L[0-9]*\.ar$") {
			local Phi_str `Phi_str' `val'
		}
		* seasonal MA coefficients: pattern ends with .ma and starts with ARMA[2-9]:
		else if ustrregexm("`name'", "^ARMA[2-9]:L[0-9]*\.ma$") {
			local Theta_str `Theta_str' `val'
		}
	}
    
	* count coefficients found
	local p_found : word count `phi_str'
	local q_found : word count `theta_str'
	local P_found : word count `Phi_str'
	local Q_found : word count `Theta_str'
    
	* use found counts if specification was incomplete or could not be parsed
	if `p' == 0 & `p_found' > 0 local p = `p_found'
	if `q' == 0 & `q_found' > 0 local q = `q_found'
	if `P' == 0 & `P_found' > 0 local P = `P_found'
	if `Q' == 0 & `Q_found' > 0 local Q = `Q_found'
    
	**********************
	// display model info
	**********************
	di ""
	di as txt "{hline 42}"
	di as txt "ARIMA Forecasts"
	di as txt "{hline 42}"
    
	* create model specification string for display and figure title
	if `P' == 0 & `D' == 0 & `Q' == 0 {
		local model_str "ARIMA(`p',`d',`q')"
	}
	else {
		local model_str "ARIMA(`p',`d',`q')(`P',`D',`Q')[`s']"
	}
    
	di as txt "Model: " as res "`model_str'"
	di as txt "Horizon: " as res "`h' steps"
	if "`level'" != "" {
		di as txt "Confidence level: " as res "`level'%"
	}
	di as txt "{hline 42}"
    
	// call mata function that computes std errs
	mata: arima_fixed_compute_se(`h', `sigma', `d', `p', `q', ///
		"`phi_str'", "`theta_str'")
    
	// generate matrix of std errs
	tempname se_mat
	matrix `se_mat' = J(`h', 3, .)
	matrix colnames `se_mat' = h Variance SE
    
	forval i = 1/`h' {
		local var_i = scalar(var_h`i')
		local se_i = sqrt(`var_i')
        
		matrix `se_mat'[`i', 1] = `i'
		matrix `se_mat'[`i', 2] = `var_i'
		matrix `se_mat'[`i', 3] = `se_i'
	}
    
    ************************
	// get info for graph and add forecasts to data 
	************************	

	* Initialize variables for figure option
	local orig_var_name ""  // Store original variable name for figure
	local timevar_name ""   // Store time variable name for figure
	local yvar_label ""     // Store Y variable label for figure
	local has_forecast_vars 0
	local first_forecast_obs 0  // Store first forecast observation number
	local last_forecast_obs 0   // Store last forecast observation number
    
	* get dependent variable info
    local depvar_raw = e(depvar)
    
	* clean the dependent variable name (if there are any time series operators)
	local depvar_clean = "`depvar_raw'"
	foreach op in D S L F {
		local depvar_clean = ustrregexra("`depvar_clean'", "^`op'[0-9]*\.", "")
	}
	if "`depvar_clean'" == "" {
		local depvar_clean "`depvar_raw'"
	}
    
	* get original variable name from command line
	if ustrregexm("`cmdline'", "^arima ([a-zA-Z0-9_]+)") {
		local orig_var = ustrregexs(1)
	}
	else {
		local orig_var "`depvar_clean'"
	}
    
	* store original variable name for figure option
	local orig_var_name "`orig_var'"
    
	* get Y variable label for figure ytitle
	capture local yvar_label : variable label `orig_var_name'
	if "`yvar_label'" == "" {
		local yvar_label "`orig_var_name'"
	}
    
	* generate forecast variables
	local pred_var "`prefix'pred"
	local se_var "`prefix'se"
	local lb_var "`prefix'll`level_suffix'"
	local ub_var "`prefix'ul`level_suffix'"
    
	* compute z-value for confidence interval (two-sided)
	local alpha = (100 - `level')/100
	local z = invnormal(1 - `alpha'/2)	
    
	* get time variable and ensure data is sorted
	qui tsset
	local timevar `r(timevar)'
	local tsfmt `r(tsfmt)'
	local tmaxs `r(tmaxs)'  // max time value (we assume it's also the last)
	sort `timevar'
    
	* store time variable name for figure option
	local timevar_name "`timevar'"
    
	* get the last time value in the current dataset (numeric)
	qui sum `timevar'
	local last_time = r(max)
    
	* get total number of observations before appending
	local N_before = _N
    
	* calculate the first forecast period (tmaxs + 1 period)
	if "`tsfmt'" == "%tm" {
		* for monthly: "1979m10" -> "1979m11"
		* extract year and month
		tokenize "`tmaxs'", parse("m")
		local year `1'
		local month `3'
        
		* Calculate next month
		local month = `month' + 1
		if `month' > 12 {
			local month = 1
			local year = `year' + 1
		}
        
		local first_forecast_str "`year'm`month'"
		local dyn_spec "tm(`first_forecast_str')"
	}
	else if "`tsfmt'" == "%tq" {
		* for quarterly: "1979q4" -> "1980q1"
		tokenize "`tmaxs'", parse("q")
		local year `1'
		local quarter `3'
        
		local quarter = `quarter' + 1
		if `quarter' > 4 {
			local quarter = 1
			local year = `year' + 1
		}
        
		local first_forecast_str "`year'q`quarter'"
		local dyn_spec "tq(`first_forecast_str')"
	}
	else if "`tsfmt'" == "%td" {
		* for daily: add 1 to numeric value
		local first_forecast_num = `last_time' + 1
		local dyn_spec "td(`first_forecast_num')"
	}
	else if "`tsfmt'" == "%tw" {
		* for weekly: add 1 to numeric value
		local first_forecast_num = `last_time' + 1
		local dyn_spec "tw(`first_forecast_num')"
	}
	else if "`tsfmt'" == "%th" {
		* for half-yearly: add 1 to numeric value
		local first_forecast_num = `last_time' + 1
		local dyn_spec "th(`first_forecast_num')"
	}
	else if "`tsfmt'" == "%ty" {
		* for yearly: add 1 to numeric value
		local first_forecast_num = `last_time' + 1
		local dyn_spec "`first_forecast_num'"
	}
	else {
        * for other formats, use numeric + 1 and hope for the best
		local first_forecast_num = `last_time' + 1
		local dyn_spec "`first_forecast_num'"
	}
    
	* append observations
	capture tsappend, add(`h')
	if _rc {
		di as error "data is no longer properly tsset. Re-run tsset before using arima_forecast"
		exit 459
	}
    
	* calculate observation numbers for forecast periods
	local first_forecast_obs = `N_before' + 1
	local last_forecast_obs = `first_forecast_obs' + `h' - 1
    
    * generate forecast variables
	qui gen `pred_var' = .
	qui gen `se_var' = .
	qui gen `lb_var' = .
	qui gen `ub_var' = .
    
	* label the variables
	label var `pred_var' "ARIMA forecast for `orig_var'"
	label var `se_var' "Forecast standard error"
	label var `lb_var' "`level'% lower confidence level"
	label var `ub_var' "`level'% upper confidence level"
    
	* generate dynamic forecasts starting from first forecast period
	tempvar temp_pred
	qui predict `temp_pred', y dynamic(`dyn_spec')
    
	* fill in forecast values for forecast periods
	qui replace `pred_var' = `temp_pred' if `timevar' > `last_time' & !missing(`temp_pred')
    
	* fill in standard errors and confidence bounds for each forecast step
	local forecast_num = 1
	forval obs = `first_forecast_obs'/`last_forecast_obs' {
		local se_i = sqrt(scalar(var_h`forecast_num'))
		local pred_val = `temp_pred'[`obs']
		if !missing(`pred_val') {
			qui replace `se_var' = `se_i' in `obs'
			qui replace `lb_var' = `pred_val' - `z' * `se_i' in `obs'
			qui replace `ub_var' = `pred_val' + `z' * `se_i' in `obs'
		}
		local forecast_num = `forecast_num' + 1
	}	
  
	*********************************
	// display (list) forecast values
	*********************************
	di ""
	di as txt "Forecast values:"
	list `timevar' `pred_var' `se_var' `lb_var' `ub_var' in `first_forecast_obs'/`last_forecast_obs', clean noobs

    
	*****************
	// figure option
	*****************
	if "`figure'" != "" {
		* get time variable label for xtitle
		capture local timevar_label : variable label `timevar_name'
		if "`timevar_label'" == "" {
			local timevar_label "`timevar_name'"
		}
            
		* generate the graph
		twoway (rarea `lb_var' `ub_var' `timevar_name' , color(gs12)) ///
			(line `orig_var_name' `timevar_name' , lcolor(black)) ///
			(line `pred_var' `timevar_name' , lcolor(blue)), ///
			legend(off) ///
			title("Forecasts from `model_str' with `level'% CIs", size(medlarge)) ///
			xtitle("`timevar_label'") ///
			ytitle("`yvar_label'") ///
			`options'
	
	} // end figure			
            
	****************
	// saved values
	****************	
	return matrix se = `se_mat'
    return scalar h = `h'
    
end

**************************************
* mata functions to compute std errors 
**************************************
mata:
mata clear

void arima_fixed_compute_se(
    real scalar h,
    real scalar sigma,
    real scalar d,
    real scalar p,
    real scalar q,
    string scalar phi_str,
    string scalar theta_str)
{
    // parse coefficients - handle empty strings properly
    if (phi_str != "") {
        phi_tokens = tokens(phi_str)
        if (length(phi_tokens) > 0) {
            phi = strtoreal(phi_tokens)
        }
        else {
            phi = J(1, 0, .)
        }
    }
    else {
        phi = J(1, 0, .)
    }
    
    if (theta_str != "") {
        theta_tokens = tokens(theta_str)
        if (length(theta_tokens) > 0) {
            theta = strtoreal(theta_tokens)
        }
        else {
            theta = J(1, 0, .)
        }
    }
    else {
        theta = J(1, 0, .)
    }
    
    sigma2 = sigma^2
    
    if (d == 0) {
        // stationary ARMA
        psi = compute_arma_psi(h, phi, theta)
    }
    else if (d == 1) {
        // I(1) models
        
        if (p == 3 & q == 0) {
            // special case ARIMA(3,1,0) (since R gave us different results)
            a1 = 1 + phi[1]
            a2 = phi[2] - phi[1]
            a3 = phi[3] - phi[2]
            a4 = -phi[3]
            
            ar_expanded = (a1, a2, a3, a4)
            psi = compute_ar_psi(h, ar_expanded)
        }
        else {
            // general ARIMA(p,1,q)
            ar_expanded = J(1, p+1, 0)
            
            if (p == 0) {
                ar_expanded[1] = 1
            }
            else {
                ar_expanded[1] = 1 + phi[1]
                for (j = 2; j <= p; j++) {
                    ar_expanded[j] = phi[j] - phi[j-1]
                }
                ar_expanded[p+1] = -phi[p]
            }
            
            psi = compute_arma_psi(h, ar_expanded, theta)
        }
    }
    else if (d == 2) {
        // I(2) models
        ar_expanded = J(1, p+2, 0)
        
        if (p == 0) {
            ar_expanded[1] = 2
            ar_expanded[2] = -1
        }
        else {
            poly1 = J(1, p+1, 0)
            poly1[1] = 1
            for (j = 1; j <= p; j++) {
                poly1[j+1] = -phi[j]
            }
            
            poly2 = (1, -2, 1)
            ar_expanded = convolve(poly1, poly2)
        }
        
        psi = compute_arma_psi(h, ar_expanded, theta)
    }
    else {
        errprintf("Differencing order d=%g not supported\n", d)
        exit(498)
    }
    
    // compute variances
    for (h_step = 1; h_step <= h; h_step++) {
        sum_sq = 1
        
        for (j = 1; j <= h_step-1; j++) {
            if (j+1 <= length(psi)) {
                sum_sq = sum_sq + (psi[j+1])^2
            }
        }
        
        variance = sum_sq * sigma2
        stata(sprintf("scalar var_h%g = %g", h_step, variance))
    }
}

// compute psi-weights for AR(p) model
real vector compute_ar_psi(real scalar n, real vector ar)
{
    p = length(ar)
    psi = J(1, n, 0)
    
    if (n >= 1) psi[1] = 1
    
    for (j = 1; j <= n-1; j++) {
        pos = j + 1
        
        for (i = 1; i <= min((p, j)); i++) {
            psi[pos] = psi[pos] + ar[i] * psi[pos - i]
        }
    }
    
    return(psi)
}

// compute psi-weights for ARMA(p,q) model
real vector compute_arma_psi(real scalar n, real vector ar, real vector ma)
{
    p = length(ar)
    q = length(ma)
    psi = J(1, n, 0)
    
    if (n >= 1) psi[1] = 1
    
    for (j = 1; j <= n-1; j++) {
        pos = j + 1
        
        if (p > 0) {
            for (i = 1; i <= min((p, j)); i++) {
                psi[pos] = psi[pos] + ar[i] * psi[pos - i]
            }
        }
        
        if (j <= q) {
            psi[pos] = psi[pos] + ma[j]
        }
    }
    
    return(psi)
}

// convolution of two polynomials
real vector convolve(real vector a, real vector b)
{
    na = length(a)
    nb = length(b)
    nresult = na + nb - 1
    result = J(1, nresult, 0)
    
    for (i = 1; i <= na; i++) {
        for (j = 1; j <= nb; j++) {
            result[i + j - 1] = result[i + j - 1] + a[i] * b[j]
        }
    }
    
    return(result)
}
end