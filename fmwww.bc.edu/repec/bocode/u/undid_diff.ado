/*------------------------------------*/
/*undid_diff*/
/*written by Eric Jamieson */
/*version 1.0.0 2025-08-04 */
/*------------------------------------*/
cap program drop undid_diff
program define undid_diff
    version 16
    syntax, init_filepath(string) date_format(string) freq(string) ///
            [covariates(string) freq_multiplier(int 1) weights(string) ///
            filename(string) filepath(string)]

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------------- PART ONE: Checks ------------------------------------ // 
    // ---------------------------------------------------------------------------------------- // 

    // Define UNDID variables
    local UNDID_DATE_FORMATS "ddmonyyyy yyyym00 yyyy/mm/dd yyyy-mm-dd yyyymmdd yyyy/dd/mm yyyy-dd-mm yyyyddmm dd/mm/yyyy dd-mm-yyyy ddmmyyyy mm/dd/yyyy mm-dd-yyyy mmddyyyy yyyy"
    local UNDID_WEIGHTS "none diff att both"
    local UNDID_FREQ "year month week day years months weeks days"

    // Define default values
    if missing("`filename'") local filename "empty_diff_df.csv"
    if missing("`weights'") local weights "both"

    // Remove whitespace from date_format and freq
    local date_format = trim("`date_format'")
    local freq = trim("`freq'")
    
    // If no filepath given, use tempdir
    if "`filepath'" == "" {
        local filepath "`c(tmpdir)'"
    }
    
    // Make sure filename ends in a .csv
    if substr("`filename'", -4, .) != ".csv" {
        di as error "Error: Filename must end in .csv"
        exit 21
    }

    // Make sure the init_filepath actually goes to a CSV file
    if substr("`init_filepath'", -4, .) != ".csv" {
        di as error "Error: init_filepath should end in .csv"
        exit 22
    }

    // Normalize filepath to always use `/` as the separator
    local filepath_fixed = subinstr("`filepath'", "\", "/", .)
    local fullpath "`filepath_fixed'/`filename'"
    local fullpath = subinstr("`fullpath'", "//", "/", .)
    local fullpath = subinstr("`fullpath'", "//", "/", .)

    // Read the init.csv file with all string columns
    qui tempname empty_diff_df  
    qui cap frame drop `empty_diff_df'  
    qui frame create `empty_diff_df'
    qui frame change `empty_diff_df'
    qui import delimited "`init_filepath'", clear stringcols(_all)

    // Check for missing values in all columns
    qui ds
    foreach var in `r(varlist)' {
        cap assert !missing(`var')
        if _rc {
            di as error "Error: Missing values detected in column `var' in the initializing CSV."
            exit 3
        }
    }

    // Make sure freq and treatment_time are lowercase
    qui replace treatment_time = lower(treatment_time)
    local freq = lower("`freq'")

    // Trim any whitespace from start_time and end_time
    qui replace start_time = trim(start_time)
    qui replace end_time = trim(end_time)

    // Check that all start_time and end_time values have the same length
    qui gen start_length = strlen(start_time)
    qui gen end_length = strlen(end_time)
    qui sum start_length, meanonly
    cap assert start_length == r(min)
    if _rc {
        di as err "Error: Ensure all start_time values are written in the same date format."
        exit 4
    }
    qui sum end_length, meanonly
    cap assert end_length == r(min)
    if _rc {
        di as err "Error: Ensure all end_time values are written in the same date format."
        exit 5
    }
    cap assert start_length == end_length
    if _rc {
        di as err "Error: Ensure start_time and end_time are written in the same date format."
        exit 6
    }

    // Check that at least one treatment_time is "control" and one is not control
    local found_control = 0
    local found_treated = 0
    qui count if lower(treatment_time) == "control"
    if r(N) > 0 {
        local found_control = 1
    }
    if `found_control' == 0 {
        di as error "Error: At least one treatment_time must be 'control'."
        exit 7
    }
    qui count if lower(treatment_time) != "control"
    if r(N) > 0 {
        local found_treated = 1
    }
    if `found_treated' == 0 {
        di as error "Error: At least one treatment_time must be a non 'control' entry."
        exit 8
    }

    // Check that non control treatment_time entries have the same length as start_length
    qui gen treatment_length = strlen(treatment_time) if lower(treatment_time) != "control"
    qui sum start_length, meanonly
    local ref_length = r(min)
    qui sum treatment_length if !missing(treatment_length), meanonly
    cap assert r(min) == `ref_length' & r(max) == `ref_length'
    if _rc {
        di as error "Error: All non 'control' treatment_time values must written in the same date format as start_time and end_time."
        exit 9
    }

    // Ensure date_format_length == start_length == end_length == treat_length
    local date_format_length = strlen("`date_format'")
    if `date_format_length' != `ref_length' {
        di as error "Error: start_time, end_time and non 'control' treatment_time values must all be written in the date_format specified: `date_format'."
        exit 10
    }
    qui drop start_length
    qui drop end_length
    qui drop treatment_length

    // Check that there is just on inputted start_time and end_time 
    qui levelsof start_time, local(unique_vals_start)
    qui local num_vals_start: word count `unique_vals_start'
    if `num_vals_start' > 1 {
        di as error "Error: More than one unique start_time value found. Please specify a single commont start time for the analysis."
        exit 16
    }
    qui levelsof end_time, local(unique_vals_end)
    qui local num_vals_end: word count `unique_vals_end'
    if `num_vals_end' > 1 {
        di as error "Error: More than one unique end_time value found. Please specify a single commont end time for the analysis."
        exit 17
    }

    // If covariates are specified, process them
    if "`covariates'" != "" {
        local covariates_trimmed_length = strlen(trim("`covariates'"))
        if `covariates_trimmed_length' == 0 {
            di as error "Error: Covariates cannot be entered as a block of whitespace. To drop covariates entirely, ensure no covariates column is specified in the init CSV."
            exit 14
        }
        local formatted_covariates = subinstr("`covariates'", " ", ";", .)
        cap confirm variable covariates
        if _rc { 
            qui gen covariates = "`formatted_covariates'"
        }
        else {
            qui replace covariates = "`formatted_covariates'"
        }
    }

    // Ensure freq_multiplier > 0, append or delete letter s to freq if necessary
    if `freq_multiplier' < 1 {
        di as error "Error: freq_multiplier must be entered as an integer > 0."
        exit 11
    }
    if `freq_multiplier' > 1 & substr("`freq'", -1, 1) != "s" {
        local freq "`freq's"
    }
    if `freq_multiplier' == 1 & substr("`freq'", -1, 1) == "s" {
        local freq = substr("`freq'", 1, strlen("`freq'") - 1)
    }

    // Ensure date_format, weights, and freq are defined in the env
    local found_date_format = 0
    local found_weights = 0
    local found_freq = 0
    foreach format in `UNDID_DATE_FORMATS' {
        if "`date_format'" == "`format'" {
            local found_date_format = 1
            continue, break
        }
    }
    if `found_date_format' == 0 {
        di as error "Error: The date_format (`date_format') is not recognized. Must be one of: `UNDID_DATE_FORMATS'."
        exit 12
    }
    foreach weight in `UNDID_WEIGHTS' {
        if "`weights'" == "`weight'" {
            local found_weights = 1
            continue, break
        }
    }
    if `found_weights' == 0 {
        di as error "Error: The weight (`weights') is not recognized. Must be one of: `UNDID_WEIGHTS'."
        exit 13
    }
    foreach freq_format in `UNDID_FREQ' {
        if "`freq'" == "`freq_format'" {
            local found_freq = 1
            continue, break
        }
    }
    if `found_freq' == 0 {
        di as error "Error: The freq (`freq') is not recognized. Must be one of: `UNDID_FREQ'."
        exit 15
    }
    local freq_string "`freq_multiplier' `freq'"

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------------- PART TWO: Processing -------------------------------- // 
    // ---------------------------------------------------------------------------------------- // 

    // Convert start_time, end_time, and treatment_time to dates, check that start_time < treatment_time < end_time
    qui _parse_string_to_date, varname(start_time) date_format("`date_format'") newvar(start_time_date)
    qui _parse_string_to_date, varname(end_time) date_format("`date_format'") newvar(end_time_date)
    qui _parse_string_to_date, varname(treatment_time) date_format("`date_format'") newvar(treatment_time_date)
    qui capture assert start_time_date < end_time_date
    if _rc {
        di as error "Error: Found values of start_time that are after the end_time"
        exit 18
    }
    qui capture assert start_time_date < treatment_time_date if !missing(treatment_time_date)
    if _rc {
        di as error "Error: Found values of treatment_time that are equal to or less than start_time."
        exit 19
    }
    qui capture assert treatment_time_date <= end_time_date if !missing(treatment_time_date)
    if _rc {
        di as error "Error: Found values of treatment_time that are greater than end_time."
        exit 20
    }

    // Count number of unique treatment dates and proceed accordingly
    qui preserve
    qui contract treatment_time if treatment_time != "control"
    qui levelsof treatment_time, local(unique_treatment_dates)
    qui local num_unique_treatment_dates: word count `unique_treatment_dates'
    qui restore
    if `num_unique_treatment_dates' == 1 {
        // Common Adoption
        qui gen treat = (treatment_time != "control")
        qui levelsof treatment_time if treatment_time != "control", local(unique_treatment_time)
        qui gen common_treatment_time = `unique_treatment_time'
        qui gen weights = "`weights'"
        qui gen diff_estimate = "NA"
        qui gen diff_var = "NA"
        qui gen diff_estimate_covariates = "NA"
        qui gen diff_var_covariates = "NA"
        qui gen date_format = "`date_format'"
        qui gen freq = "`freq_string'"
        cap confirm variable covariates
        if _rc {
            qui gen covariates = "none"
        }
        qui drop start_time
        qui drop end_time
        qui _parse_date_to_string, varname(start_time_date) date_format("`date_format'") newvar(start_time)
        qui _parse_date_to_string, varname(end_time_date) date_format("`date_format'") newvar(end_time)
        qui gen n = "NA"
        qui gen n_t = "NA"
        qui gen anonymize_size = "NA"
        qui drop start_time_date
        qui drop end_time_date
        qui drop treatment_time_date
        qui drop treatment_time
        qui order silo_name treat common_treatment_time start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq
        qui export delimited using "`fullpath'", replace
        frame change default
    }
    else if `num_unique_treatment_dates' > 1 {
        local start_time_date = start_time_date[1]
        local end_time_date = end_time_date[1]
        cap confirm variable covariates 
        if _rc {
	        local covariates = "none"
        }
        else {
	        local covariates = covariates[1]
        }
        // Staggered Adoption, create the staggered adoption frame
        tempname seq_frame
        qui cap frame drop `seq_frame'
        qui frame create `seq_frame' str20 silo_name gvar t pre treat RI
        
        // Define date increments
        local num = real(word("`freq_string'", 1))
        local unit = word("`freq_string'", 2)
        local increment = .
        if "`unit'" == "weeks" | "`unit'" == "week" {
            local increment = 7 * `num'
        } 
        else if "`unit'" == "months" | "`unit'" == "month" {
            local increment = .
        } 
        else if "`unit'" == "years" | "`unit'" == "year" {
            local increment = .
        } 
        else if "`unit'" == "days" | "`unit'" == "day"{
            local increment = `num'
        }

        // Loop through each `silo_name` to generate sequences
        qui levelsof silo_name if treatment_time != "control", local(treated_silos)
        qui levelsof silo_name if treatment_time == "control", local(control_silos) // Stored for later
        foreach silo of local treated_silos {
            // Get the treatment time (gvar) for the silo 
            qui levelsof treatment_time_date if silo_name == "`silo'", local(gvar_list)
            foreach gvar of local gvar_list {
                local gvar_num = `gvar' // store gvar

                // Get the corresponding end time
                qui summarize end_time_date if silo_name == "`silo'", meanonly
                local end_date = r(min)  // Extract the minimum (should be only one value)

                // Generate starting pre period
                local current = `gvar_num'
    		    if "`unit'" == "months" | "`unit'" == "month" {
                    local pre_month = month(`current') - `num'
                    local pre_year = year(`current')
                    // Adjust for out-of-range months (e.g., month <= 0)
                    while `pre_month' <= 0 {
                        local pre_month = `pre_month' + 12
                        local pre_year = `pre_year' - 1
                    }
                    // Generate valid pre-date
                    local proposed_day = day(mdy(`pre_month', day(`current'), `pre_year'))
                    local proposed_day_minus_one = day(mdy(`pre_month', day(`current') - 1, `pre_year'))
                    local proposed_day_minus_two = day(mdy(`pre_month', day(`current') - 2, `pre_year'))
                    local proposed_day_minus_three = day(mdy(`pre_month', day(`current') - 3, `pre_year'))
                    local day_final = max(`proposed_day', `proposed_day_minus_one', `proposed_day_minus_two', `proposed_day_minus_three')
                    local pre = mdy(`pre_month', `day_final', `pre_year')
    		    }
    		    else if "`unit'" == "years" | "`unit'" == "year" {
    		    	local pre = mdy(month(`current'), day(`current'), year(`current') - `num')
    		    }
    		    else {
    		    	local pre = `current' - `increment'
    		    }

                // Generate the sequence of t periods (post periods)
                while `current' <= `end_date' {
                    qui frame post `seq_frame' ("`silo'") (`gvar_num') (`current') (`pre') (1) (0) 
                    // Handle different units
    		    	if "`unit'" == "months" | "`unit'" == "month" {
    		    		local next_month = month(`current') + `num'
    		    		local year_adj = floor(`next_month'/12)
    		    		if `next_month' > 12 {
                            local proposed_day = day(mdy(month(`current') + `num' - 12*`year_adj', day(`current'), year(`current') + `year_adj'))
                            local proposed_day_minus_one = day(mdy(month(`current') + `num' - 12*`year_adj', day(`current') - 1, year(`current') + `year_adj'))
                            local proposed_day_minus_two = day(mdy(month(`current') + `num' - 12*`year_adj', day(`current') - 2, year(`current') + `year_adj'))
                            local proposed_day_minus_three = day(mdy(month(`current') + `num' - 12*`year_adj', day(`current') - 3, year(`current') + `year_adj'))
                            local day_final = max(`proposed_day', `proposed_day_minus_one', `proposed_day_minus_two', `proposed_day_minus_three')
    		    			local current = mdy(month(`current') + `num' - 12*`year_adj', `day_final', year(`current') + `year_adj')
    		    		}
    		    		else if `next_month' <= 12 {
                            local proposed_day = day(mdy(month(`current') + `num', day(`current'), year(`current')))
                            local proposed_day_minus_one = day(mdy(month(`current') + `num', day(`current') - 1, year(`current')))
                            local proposed_day_minus_two = day(mdy(month(`current') + `num', day(`current') - 2, year(`current')))
                            local proposed_day_minus_three = day(mdy(month(`current') + `num', day(`current') - 3, year(`current')))
                            local day_final = max(`proposed_day', `proposed_day_minus_one', `proposed_day_minus_two', `proposed_day_minus_three')
    		    			local current = mdy(month(`current') + `num', day(`current'), year(`current'))
    		    		}
    		    	}
    		    	else if "`unit'" == "years" | "`unit'" == "year" {
    		    		local current = mdy(month(`current'), day(`current'), year(`current') + `num')
    		    	}
    		    	else {
    		    		local current = `current' + `increment'
    		    	}
                }
            }
        }

        // Switch explicitly to the staggered adoption frame and add the RI rows
        qui frame change `seq_frame'
        qui gen unique_flag = .
        qui bysort gvar t (silo_name): replace unique_flag = (_n == 1) 
        qui sort silo_name gvar t 
        foreach silo of local treated_silos {
        	qui levelsof gvar if silo_name == "`silo'", local(silo_gvar)
        	qui levelsof gvar if silo_name != "`silo'" & gvar != `silo_gvar', local(ri_gvars)
        	foreach ri_gvar of local ri_gvars {
                // Get all unique (t, pre) combinations for the given gvar
                qui levelsof t if gvar == `ri_gvar' & silo_name != "`silo'", local(t_list)
                qui levelsof pre if gvar == `ri_gvar' & silo_name != "`silo'", local(pre_list)

                foreach t_val of local t_list {
                    foreach pre_val of local pre_list {
                        // Append new row with RI = 1, treat = -1, unique_flag = 0
                        qui frame post `seq_frame' ("`silo'") (`ri_gvar') (`t_val') (`pre_val') (-1) (1) (0)
                    }
                }
            }
        }

        // Add the control silos
        qui preserve
            qui keep if unique_flag == 1
            qui keep gvar t pre unique_flag
            qui tempfile base_data
            qui save `base_data', replace
            qui tempfile new_rows
            qui save `new_rows', emptyok replace
            foreach silo of local control_silos {
                qui use `base_data', clear
                qui gen silo_name = "`silo'"
                qui gen RI = 0
                qui gen treat = 0
                qui replace unique_flag = 0
                qui append using `new_rows'
                qui save `new_rows', replace
            }
        qui restore
        qui append using `new_rows'
        qui drop if missing(silo_name)
        qui drop unique_flag

        // Add start_time and end_time
        qui gen start_t = `start_time_date'
        qui gen end_t =  `end_time_date'
        qui _parse_date_to_string, varname(start_t) date_format("`date_format'") newvar(start_time)
        qui _parse_date_to_string, varname(end_t) date_format("`date_format'") newvar(end_time)
        qui drop start_t
        qui drop end_t
 
        // Add gt and diff_times
        qui _parse_date_to_string, varname(gvar) date_format("`date_format'") newvar(gvar_str)
        qui _parse_date_to_string, varname(t) date_format("`date_format'") newvar(t_str)
        qui _parse_date_to_string, varname(pre) date_format("`date_format'") newvar(pre_str)
        qui egen gt = concat(gvar_str t_str), punct(;)
        qui egen diff_times = concat(t_str pre_str), punct(;)
        qui tostring gvar, replace
        qui replace gvar = gvar_str
        qui drop t pre gvar_str t_str pre_str 

        // Add freq, date_format, covariates, diff estimates, variances, and weights and reorder
        qui gen freq = "`freq_string'"
        qui gen date_format = "`date_format'"
        qui gen covariates = "`covariates'"
        qui gen weights = "`weights'"
        qui gen diff_estimate = "NA"
        qui gen diff_var = "NA"
        qui gen diff_estimate_covariates = "NA"
        qui gen diff_var_covariates = "NA"
        qui gen n = "NA"
        qui gen n_t = "NA"
        qui gen anonymize_size = "NA"
        qui order silo_name gvar treat diff_times gt RI start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq
 
        qui export delimited using "`fullpath'", replace
        qui frame change default
    }

    // Convert to Windows-friendly format for display if on Windows
    if "`c(os)'" == "Windows" {
        local fullpath_display = subinstr("`fullpath'", "/", "\", .)
    } 
    else {
        local fullpath_display "`fullpath'"
    }
    di as result "`filename' file saved to: `fullpath_display'"

end


/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*1.0.0 - created function