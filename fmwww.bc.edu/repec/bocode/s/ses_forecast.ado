*! 1.0.0 Ariel Linden 30Jan2026

program define ses_forecast, rclass
	version 11
	syntax varname [if] [in] [,			///
		Forecast(integer 2)				///
		Level(cilevel)					///		
		REPLace							/// 
		PREfix(string)					/// 
		FIGure TWowayopts(string asis)	///
		* ]


	// check level
	if `level' <= 0 | `level' >= 100 {
		di as error "level() must be between 0 and 100"
		exit 198
	}

	// mark estimation sample
	marksample touse
	qui replace `touse' = 0 if missing(`varlist')

	// ts settings
	qui tsset
	local timevar `r(timevar)'

	// store time range
	qui summarize `timevar' if `touse'
	local first_obs = r(min)
	local last_obs  = r(max)
	local first_fc  = `last_obs' + 1
	local last_fc   = `last_obs' + `forecast'

	// variable names
	local stub = cond("`prefix'" != "", "`prefix'", "")
	local fvar  "`stub'forecast"
	local sevar "`stub'se"
	local lbvar "`stub'll`level'"
	local ubvar "`stub'ul`level'"

	// replace logic
	if "`replace'" != "" {
		foreach v in `fvar' `sevar' `lbvar' `ubvar' {
			capture confirm variable `v'
			if !_rc {
				drop `v'
			}
		}
	}
	else {
		local conflict 0
		foreach v in `fvar' `sevar' `lbvar' `ubvar' {
			capture confirm variable `v'
			if !_rc {
				di as error "`v' already exists; use replace"
				local conflict 1
			}
		}
		if `conflict' {
			exit 110
		}
	}

	// fit SES and generate forecasts
	tempvar smooth resid sq
	tssmooth exponential `smooth' = `varlist' if `touse', ///
		forecast(`forecast')

	// smoothing parameter
	local alpha = r(alpha)

	// innovation variance
	qui gen double `resid' = `varlist' - `smooth' if `touse'
	qui gen double `sq' = `resid'^2 if `touse'
	quietly summarize `sq'
	local sigma2 = r(mean)

	// two-sided z for normal approximation
	local zalpha = (100 - `level') / 100
	local z = invnormal(1 - `zalpha'/2)

	// copy forecasts from tssmooth output
	qui gen double `fvar' = `smooth' if `timevar' >= `first_fc'
	
	// initialize other output variables
	qui gen double `sevar' = .
	qui gen double `lbvar' = .
	qui gen double `ubvar' = .

	// forecast loop - calculate SE and CI
	forvalues h = 1/`forecast' {
		local t = `last_obs' + `h'

		// Get forecast value from tssmooth
		qui summarize `smooth' if `timevar' == `t'
		local yhat = r(mean)

		// forecast variance
		local var_h = `sigma2' * (1 + (`h' - 1) * `alpha'^2)
		local se_h  = sqrt(`var_h')

		local lower = `yhat' - `z' * `se_h'
		local upper = `yhat' + `z' * `se_h'

		// Fill in SE and CI
		qui replace `sevar' = `se_h' if `timevar' == `t'
		qui replace `lbvar' = `lower' if `timevar' == `t'
		qui replace `ubvar' = `upper' if `timevar' == `t'

		local f`h'  = `yhat'
		local se`h' = `se_h'
		local lo`h' = `lower'
		local hi`h' = `upper'
	}

	// variable labels
	label var `fvar'  "SES point forecast"
	label var `sevar' "Forecast standard error"
	label var `lbvar' "`level'% lower confidence limit"
	label var `ubvar' "`level'% upper confidence limit"

	// return scalars
	return scalar alpha    = `alpha'
	return scalar sigma2  = `sigma2'
	return scalar forecast = `forecast'

	// return matrix
	tempname results
	matrix `results' = J(`forecast', 5, .)
	forvalues h = 1/`forecast' {
		matrix `results'[`h',1] = `h'
		matrix `results'[`h',2] = `f`h''
		matrix `results'[`h',3] = `se`h''
		matrix `results'[`h',4] = `lo`h''
		matrix `results'[`h',5] = `hi`h''
	}
	matrix colnames `results' = horizon forecast se lower upper
	return matrix results = `results'

	// list results
	qui count if `timevar' >= `first_fc' & `timevar' <= `last_fc'
	if r(N) > 0 {
		list `timevar' `fvar' `lbvar' `ubvar' ///
			if `timevar' >= `first_fc' & `timevar' <= `last_fc', ///
			noobs clean
	}

	// figure option
	if "`figure'" != "" {

		// axis labels
		capture local tlabel : variable label `timevar'
		if "`tlabel'" == "" local tlabel "`timevar'"

		capture local ylabel : variable label `varlist'
		if "`ylabel'" == "" local ylabel "`varlist'"

		twoway ///
			(rarea `lbvar' `ubvar' `timevar', color(gs12)) ///
			(line `varlist' `timevar' if `touse', lcolor(black)) ///
			(line `fvar' `timevar', lcolor(blue)), ///
			legend(off) ///
			title("Forecasts from simple exponential smoothing with `level'% CIs", size(medlarge)) ///
			xtitle("`tlabel'") ///
			ytitle("`ylabel'") ///
			`twowayopts'
	}

end