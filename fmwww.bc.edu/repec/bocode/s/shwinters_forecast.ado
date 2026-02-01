*! 1.0.0 Ariel Linden 20Jan2026

program define shwinters_forecast, rclass
    version 11
     syntax varname [if] [in], [ Forecast(int 2) Level(real 95) REPLace FIGure PREfix(string) TWowayopts(string asis) * ]
    
	// check level
	if `level' <= 0 | `level' >= 100 {
		di as error "level() must be between 0 and 100"
		exit 198
	}
    
	// mark estimation sample
    marksample touse
    qui replace `touse' = 0 if missing(`varlist')
    
	// get tsset values
	qui tsset
	local timevar_name `r(timevar)'
	local tsfreq `r(unit1)'
    
	// store original data range
	qui sum `timevar_name' if `touse'
	local first_obs_time = r(min)
	local last_obs_time = r(max)
	local first_forecast = `last_obs_time' + 1
	local last_forecast = `last_obs_time' + `forecast'
    
	// if prefix is specified
	if "`prefix'" != "" {
		local pred_stub "`prefix'"
	}
	else {
		local pred_stub ""
	}
    
	local level_suffix = string(`level')
	local forecast_var "`pred_stub'forecast"
	local se_var "`pred_stub'se"
	local lb_var "`pred_stub'll`level_suffix'"
	local ub_var "`pred_stub'ul`level_suffix'"
	local forecast_vars `forecast_var' `se_var' `lb_var' `ub_var'
    
	// if replace is specified
	if "`replace'" != "" {
		foreach var of local forecast_vars {
			cap drop `var'
		}
	}
	else {
		foreach var of local forecast_vars {
			cap confirm variable `var'
			if !_rc {
				di as error "`var' already exists"
				di as error "use the replace option to overwrite"
				exit 110
			}
		}
	}
    
	// fit seasonal Holt-Winters model
	tempvar yhat
	tssmooth shwinters `yhat' = `varlist' if `touse', forecast(`forecast') `options'
    
	local alpha = r(alpha)
	local beta = r(beta)
	local gamma = r(gamma)
	local rmse = r(rmse)
	local s2 = (`rmse')^2
	local method = r(method)
    
	// determine if the model was multiplicative or additive
	local is_multiplicative = strpos("`method'", "multiplicative") > 0
	local type = "additive"
	if `is_multiplicative' local type = "multiplicative"
    
	// generate the forecast variables
	qui {
		gen `forecast_var' = .
		gen `se_var' = .
		gen `lb_var' = .
		gen `ub_var' = .
	}
    
	* compute z-value for confidence interval (two-sided)
	local crit = (100 - `level')/100
	local z = invnormal(1 - `crit'/2)		
	
	// determine seasonal period
	local m = 1
	if "`gamma'" != "0" & "`gamma'" != "." {
		if "`tsfreq'" == "month" | "`tsfreq'" == "monthly" {
			local m = 12
		}
		else if "`tsfreq'" == "quarter" | "`tsfreq'" == "quarterly" {
			local m = 4
		}
		else if "`tsfreq'" == "year" | "`tsfreq'" == "yearly" {
			local m = 1
		}
		else {
			local m = r(unit0)
			if missing(`m') | `m' == 0 local m = 1
		}
	}
    
	*************************************************
	* ADDITIVE HOLT-WINTERS (Yar & Chatfield, 1990)
	*************************************************
	if `is_multiplicative' == 0 {
        
		forvalues h = 1/`forecast' {
			local forecast_time_val = `last_obs_time' + `h'
            
			qui sum `yhat' if `timevar_name' == `forecast_time_val'
			local point_fc = r(mean)
            
			// compute forecast variance V_h
			if ("`beta'" == "0" | "`beta'" == ".") & ("`gamma'" == "0" | "`gamma'" == ".") {
				// no trend, no seasonality
				local var_h = `s2' * (1 + (`h'-1) * `alpha'^2)
			}
			else if ("`beta'" == "0" | "`beta'" == ".") & ("`gamma'" != "0" & "`gamma'" != ".") {
				// no trend, with seasonality
				local I_hm = 0
				if `h' > `m' local I_hm = 1
				local var_h = `s2' * (1 + (`h'-1) * `alpha'^2 + `gamma'^2 * (1 - `alpha')^2 * `I_hm')
			}
			else if ("`beta'" != "0" & "`beta'" != ".") & ("`gamma'" == "0" | "`gamma'" == ".") {
				// with trend, no seasonality
				local term1 = (`h'-1) * `alpha'^2
				local term2 = `alpha' * `beta' * `h' * (`h'-1)
				local term3 = `beta'^2 * `h' * (`h'-1) * (2*`h'-1) / 6
				local var_h = `s2' * (1 + `term1' + `term2' + `term3')
			}
			else {
				// full model with trend and seasonality
				local I_hm = 0
				if `h' > `m' local I_hm = 1
				local term1 = (`h'-1) * `alpha'^2
				local term2 = `alpha' * `beta' * `h' * (`h'-1)
				local term3 = `beta'^2 * `h' * (`h'-1) * (2*`h'-1) / 6
				local term4 = `gamma'^2 * (1 - `alpha')^2 * `I_hm'
				local var_h = `s2' * (1 + `term1' + `term2' + `term3' + `term4')
			}
            
			local se_h = sqrt(`var_h')
			local margin = `z' * `se_h'
			local lower = `point_fc' - `margin'
			local upper = `point_fc' + `margin'
            
			qui replace `forecast_var' = `point_fc' if `timevar_name' == `forecast_time_val'
			qui replace `se_var' = `se_h' if `timevar_name' == `forecast_time_val'
			qui replace `lb_var' = `lower' if `timevar_name' == `forecast_time_val'
			qui replace `ub_var' = `upper' if `timevar_name' == `forecast_time_val'
            
			local f`h' = `point_fc'
			local se`h' = `se_h'
			local lower`h' = `lower'
			local upper`h' = `upper'
		}
	}	// end additive
    
	
	*********************************************************
	* MULTIPLICATIVE HOLT-WINTERS (Chatfield & Yar, 1991)
	*********************************************************
	else {

		// get mean absolute value of the series for scaling (using estimation sample)
		qui sum `varlist' if `touse'
		local mean_abs_y = abs(r(mean))
        
		// coefficient of variation
		local cv = `rmse' / `mean_abs_y'
        
		forvalues h = 1/`forecast' {
			local forecast_time_val = `last_obs_time' + `h'
            
			qui sum `yhat' if `timevar_name' == `forecast_time_val'
			local point_fc = r(mean)
			if `point_fc' <= 0 local point_fc = 0.001
            
			// compute variance factor
			if ("`beta'" == "0" | "`beta'" == ".") & ("`gamma'" == "0" | "`gamma'" == ".") {
				local var_factor = 1 + (`h'-1) * `alpha'^2
			}
			else if ("`beta'" == "0" | "`beta'" == ".") & ("`gamma'" != "0" & "`gamma'" != ".") {
				local I_hm = 0
				if `h' > `m' local I_hm = 1
				local var_factor = 1 + (`h'-1) * `alpha'^2 + `gamma'^2 * (1 - `alpha')^2 * `I_hm'
			}
			else if ("`beta'" != "0" & "`beta'" != ".") & ("`gamma'" == "0" | "`gamma'" == ".") {
				local term1 = (`h'-1) * `alpha'^2
				local term2 = `alpha' * `beta' * `h' * (`h'-1)
				local term3 = `beta'^2 * `h' * (`h'-1) * (2*`h'-1) / 6
				local var_factor = 1 + `term1' + `term2' + `term3'
			}
			else {
				local I_hm = 0
				if `h' > `m' local I_hm = 1
				local term1 = (`h'-1) * `alpha'^2
				local term2 = `alpha' * `beta' * `h' * (`h'-1)
				local term3 = `beta'^2 * `h' * (`h'-1) * (2*`h'-1) / 6
				local term4 = `gamma'^2 * (1 - `alpha')^2 * `I_hm'
				local term5 = 0
				if `I_hm' == 1 & "`beta'" != "0" & "`beta'" != "." {
					local term5 = `beta' * `gamma' * (1 - `alpha') * (`h' - `m')
				}
                
				local var_factor = 1 + `term1' + `term2' + `term3' + `term4' + `term5'
			}
            
			// variance on log scale
			local sigma2_log = (`cv'^2) * `var_factor'
            
			// bias adjustment
			local bias_factor = 1 + `sigma2_log'/2
			local unbiased_fc = `point_fc' / `bias_factor'
            
			// log-normal prediction intervals
			local mu_log = ln(`unbiased_fc') - `sigma2_log'/2
			local sigma_log = sqrt(`sigma2_log')
            
			local lower = exp(`mu_log' - `z' * `sigma_log')
			local upper = exp(`mu_log' + `z' * `sigma_log')
            
			// standard error
			local se_h = `point_fc' * `sigma_log'
            
			// replace results
			qui replace `forecast_var' = `point_fc' if `timevar_name' == `forecast_time_val'
			qui replace `se_var' = `se_h' if `timevar_name' == `forecast_time_val'
			qui replace `lb_var' = `lower' if `timevar_name' == `forecast_time_val'
			qui replace `ub_var' = `upper' if `timevar_name' == `forecast_time_val'
            
			local f`h' = `point_fc'
			local se`h' = `se_h'
			local lower`h' = `lower'
			local upper`h' = `upper'
		}
	} // end multiplicative
    
	// label variables
	label var `forecast_var' "Holt-Winters point forecast"
	label var `se_var' "Standard error of forecast"
	label var `lb_var' "`level'% lower confidence limit"
	label var `ub_var' "`level'% upper confidence limit"
    
	// save results
	return scalar alpha = `alpha'
	return scalar beta = `beta'
	return scalar gamma = `gamma'
	return scalar rmse = `rmse'
	return scalar forecast = `forecast'
	return scalar is_multiplicative = `is_multiplicative'
	return scalar m = `m'
	if `is_multiplicative' {
		qui sum `varlist' if `touse'
		local mean_abs_y = abs(r(mean))
		return scalar cv = `rmse' / `mean_abs_y'
	}
    
	tempname results_mat
	matrix `results_mat' = J(`forecast', 5, .)
	forvalues h = 1/`forecast' {
		matrix `results_mat'[`h', 1] = `h'
		matrix `results_mat'[`h', 2] = `f`h''
		matrix `results_mat'[`h', 3] = `se`h''
		matrix `results_mat'[`h', 4] = `lower`h''
		matrix `results_mat'[`h', 5] = `upper`h''
	}
	matrix colnames `results_mat' = horizon point_fc se lower upper
	return matrix results = `results_mat'
    
	// display forecasts
	qui count if `timevar_name' >= `first_forecast' & `timevar_name' <= `last_forecast'
	if r(N) > 0 {
		list `timevar_name' `forecast_var' `lb_var' `ub_var' ///
		if `timevar_name' >= `first_forecast' & `timevar_name' <= `last_forecast', ///
			noobs clean
	}
    
	// if figure is specified
	if "`figure'" != "" {
		// get time variable label for xtitle
		capture local timevar_label : variable label `timevar_name'
		if "`timevar_label'" == "" {
			local timevar_label "`timevar_name'"
		}
        
		// get y variable label for ytitle
		capture local yvar_label : variable label `varlist'
		if "`yvar_label'" == "" {
			local yvar_label "`varlist'"
		}
        
		// generate the graph
		twoway (rarea `lb_var' `ub_var' `timevar_name' , color(gs12)) ///
			(line `varlist' `timevar_name' if `touse', lcolor(black)) ///
			(line `forecast_var' `timevar_name' , lcolor(blue)), ///
			legend(off) ///
			title("Forecasts from Holt-Winters' `type' method with `level'% CIs", size(medlarge)) ///
			xtitle("`timevar_label'") ///
			ytitle("`yvar_label'") ///
			`twowayopts'			
	}
    
end