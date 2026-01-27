*! 1.0.0 Ariel Linden 23Jan2026

program define ocsb_ndiff, rclass
	version 11
	syntax varname(ts) [if][in] [,	///
		MAXdiffs(integer 2)			/// maximum D
		Lag(integer 0)				/// initial lag order
		SEasonal(integer 0)			/// seasonal period
		FOrce						/// force differencing even if insufficient obs
		QUiet ]						 // suppress iteration output

	
	// check for tsset
	if "`_dta[_TStvar]'" == "" {
		di as error "time variable not set, use {bf:tsset} {it:varname ...}"
		exit 111
	}
    
	marksample touse
    
	// preserve and save original data
    preserve
	tempfile original_data
	qui save "`original_data'"
    
	// initialize
	local D = 0
	local x = "`varlist'"
	tempvar current_series
	qui gen `current_series' = `x' if `touse'
    
	// try to determine seasonal period from tsset if not specified
	if `seasonal' == 0 {
		capture tsset
		if _rc == 0 {
			local timeunit = r(unit1)
            
			// convert time unit to numeric seasonal period
			if "`timeunit'" == "4" | "`timeunit'" == "q" {
				local seasonal = 4
			}
			else if "`timeunit'" == "12" | "`timeunit'" == "m" {
				local seasonal = 12
			}
			else if "`timeunit'" == "52" | "`timeunit'" == "w" {
				local seasonal = 52
			}
			else if "`timeunit'" == "2" {
				local seasonal = 2
			}
			else if "`timeunit'" == "1" | "`timeunit'" == "" {
				di as err "non-seasonal data: D = 0"
				return scalar D = 0
				exit
			}
			else {
				di as err "Cannot determine seasonal period from tsset."
				di as err "Please specify seasonal() option."
				exit 498
			}
		}
        else {
			di as err "specify seasonal() option"
			exit 498
		}
	}
    
	local m = round(`seasonal')
    
	// check if series is constant
	qui sum `current_series' if `touse'
	if r(sd) == 0 {
		di as txt "Constant series: D = 0"
		return scalar D = 0
		exit
	}
    
	// display header (unless quiet)
	if "`quiet'" == "" {
		di as txt _n "{hline 58}"
		di as txt "OCSB Seasonal Differencing Determination"
		di as txt "{hline 58}"
		di as txt "Series: `varlist'"
		di as txt "Seasonal period (m): " as result `m'
		di as txt "Maximum D: " as result `maxdiffs'
		di as txt "Initial lag: " as result `lag'
		di as txt "{hline 58}"
		di as txt " Step    Test Stat      Critical        Decision       D"
		di as txt "{hline 58}"
	} // end header
    
	// main loop
	while `D' <= `maxdiffs' {
		// count non-missing observations
		qui count if !missing(`current_series') & `touse'
		local N_current = r(N)
        
		// check if enough observations for testing
		local min_obs = `m' + `lag' + 3
		if `N_current' < `min_obs' {
			if "`force'" != "" & `D' > 0 {
				if "`quiet'" == "" {
					di as result %4.0f `D' "    " %10s "N/A" "    " ///
						%10s "N/A" "    " %12s "INSUFF_OBS" "    " ///
						%4.0f `D'
				}
				continue, break
			}
			else if "`force'" == "" {
                di as err "insufficient observations for testing at D=`D'".
				di as err "Need at least `min_obs' observations, have `N_current'"
				local D = `D' - 1
				continue, break
			}
		} // end enough obs
        
		// run OCSB test on current series
		capture ocsb `current_series' if `touse', lag(`lag') seasonal(`m')
        
		if _rc != 0 {
			di as err "error running OCSB test at D=`D'"
            
			// try with lower lag if possible
			if `lag' > 0 {
				local try_lag = `lag' - 1
				di as txt "Trying with lag=`try_lag'"
				capture ocsb `current_series' if `touse', lag(`try_lag') seasonal(`m')
                
				if _rc == 0 {
					local stat = r(tstat)
					local crit = r(crit)
				}
				else {
					local D = `D' - 1
					continue, break
				}
			}
			else {
				local D = `D' - 1
				continue, break
			}
		}
		else {
			local stat = r(tstat)
			local crit = r(crit)
		}
        
		// decision: need differencing if t-statistic > critical value
		local dodiff = (`stat' > `crit')
        
		// display current step (unless quiet)
		if "`quiet'" == "" {
			di as result %4.0f `D' "    " %10.4f `stat' "    " ///
				%10.4f `crit' "    " ///
				%12s cond(`dodiff', "Difference", "Stop") "    " ///
				%4.0f `D'
		}
        
		// if no differencing needed or reached max, exit
		if !`dodiff' | `D' == `maxdiffs' {
			continue, break
		}
        
		// apply seasonal difference
		local D = `D' + 1
        
		// create seasonal difference
		tempvar new_series
		qui gen `new_series' = .
        
		// apply D-th seasonal difference
		if `D' == 1 {
			// first seasonal difference
			qui replace `new_series' = `current_series' - L`m'.`current_series' if `touse'
		}
		else if `D' == 2 {
			// second seasonal difference
			tempvar first_diff
			qui gen `first_diff' = `current_series' - L`m'.`current_series' if `touse'
			qui replace `new_series' = `first_diff' - L`m'.`first_diff' if `touse'
		}
		else {
			// higher order differences (using while loop)
			tempvar temp_series
			qui gen `temp_series' = `current_series'
            
			forvalues i = 1/`D' {
				tempvar diff`i'
				qui gen `diff`i'' = `temp_series' - L`m'.`temp_series' if `touse'
				qui replace `temp_series' = `diff`i'' if `touse'
				drop `diff`i''
			}
            
			qui replace `new_series' = `temp_series' if `touse'
		}
        
		// replace current series
		qui replace `current_series' = `new_series' if `touse'
		drop `new_series'
        
		// check if series became constant after differencing
		qui sum `current_series' if `touse' & !missing(`current_series')
		if r(sd) == 0 {
			if "`quiet'" == "" {
				di as result %4.0f `D' "    " %10s "N/A" "    " ///
					%10s "N/A" "    " %12s "CONSTANT" "    " ///
					%4.0f `D'
			}
			continue, break
		}
        
	} // end while
    
	if "`quiet'" == "" {
		di as txt "{hline 58}"
		di as txt _n "Final result: " as result "D = `D'"
	}
	else {
		di as txt _n "Final result: " as result "D = `D'"
	}
    
	// saved results
	return scalar D = `D'
	return scalar m = `m'
	return scalar maxD = `maxdiffs'
    
	// restore original data
	restore

end
