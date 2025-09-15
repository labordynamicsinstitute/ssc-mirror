/*------------------------------------*/
/*undid_stage_two*/
/*written by Eric Jamieson */
/*version 1.0.0 2025-06-16 */
/*------------------------------------*/
cap program drop undid_stage_two
program define undid_stage_two
    version 16
    syntax, empty_diff_filepath(string) silo_name(string) ///
            time_column(varname) outcome_column(varname) silo_date_format(string) ///
            [consider_covariates(int 1) filepath(string) anonymize_weights(int 0) anonymize_size(int 5)]

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------------- PART ONE: Checks ------------------------------------ // 
    // ---------------------------------------------------------------------------------------- // 

    // Define undid variables
    local UNDID_DATE_FORMATS "ddmonyyyy yyyym00 yyyy/mm/dd yyyy-mm-dd yyyymmdd yyyy/dd/mm yyyy-dd-mm yyyyddmm dd/mm/yyyy dd-mm-yyyy ddmmyyyy mm/dd/yyyy mm-dd-yyyy mmddyyyy yyyy"
    local expected_common "silo_name treat common_treatment_time start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size"
    local expected_staggered "silo_name gvar treat diff_times gt RI start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size"

    // Check anonymize_weights
    if `anonymize_weights' < 0 | `anonymize_weights' > 1 {
        di as error "Error: anonymize_weights must be set to 0 (false) or to 1 (true)."
        exit 15
    }

    // Check anonymize_size
    if `anonymize_weights' == 1 {
        if `anonymize_size' < 1 {
            di as error "Error: anonymize_size must be set to an integer > 0"
            exit 16
        }
    }

    // Check consider_covariates
    if `consider_covariates' < 0 | `consider_covariates' > 1 {
        di as error "Error: consider_covariates must be set to 0 (false) or to 1 (true)."
        exit 2
    }

    // If no filepath given, use tempdir, construct output paths for filled_diff and trends_data
    if "`filepath'" == "" {
        local filepath "`c(tmpdir)'"
    }
    local fullpath_diff "`filepath'/filled_diff_df_`silo_name'.csv"
    local fullpath_diff = subinstr("`fullpath_diff'", "\", "/", .)
    local fullpath_diff = subinstr("`fullpath_diff'", "//", "/", .)
    local fullpath_diff = subinstr("`fullpath_diff'", "//", "/", .)
    local fullpath_trends "`filepath'/trends_data_`silo_name'.csv"
    local fullpath_trends = subinstr("`fullpath_trends'", "\", "/", .)
    local fullpath_trends = subinstr("`fullpath_trends'", "//", "/", .)
    local fullpath_trends = subinstr("`fullpath_trends'", "//", "/", .)

    // Make sure the empty_diff_filepath actually goes to a CSV file
    if substr("`empty_diff_filepath'", -4, .) != ".csv" {
        di as error "Error: empty_diff_filepath should end in .csv"
        exit 3
    }

    // Check that the silo_date_format is a valid option
    local silo_date_format = lower("`silo_date_format'")
    local found_date_format = 0
    foreach format in `UNDID_DATE_FORMATS' {
        if "`silo_date_format'" == "`format'" {
            local found_date_format = 1
            continue, break
        }
    }
    if `found_date_format' == 0 {
        di as error "Error: The date_format (`silo_date_format') is not recognized. Must be one of: `UNDID_DATE_FORMATS'."
        exit 4
    }

    // Read in empty_diff, check that silo_name exists and that the csv matches the common treatment or staggered adoption format
    qui tempname diff_df  
    qui cap frame drop `diff_df'  
    qui frame create `diff_df'
    qui frame change `diff_df'
    qui import delimited "`empty_diff_filepath'", clear stringcols(_all) case(preserve)
    local check_common 1
    foreach header of local expected_common {
        qui capture confirm variable `header'
        if _rc {
            local check_common 0
            break
        }
    }
    local check_staggered 1
    foreach header of local expected_staggered {
        qui capture confirm variable `header'
        if _rc {
            local check_staggered 0
            break
        }
    }
    if (`check_common' == 0 & `check_staggered' == 0) | (`check_common' == 1 & `check_staggered' == 1)  {
        di as error "Error: The loaded CSV does not match the expected staggered adoption or common treatment time formats."
        exit 9
    }
    local found_silo_name = 0 
    qui levelsof silo_name, local(silos) clean
    foreach silo of local silos {
        if "`silo_name'" == "`silo'" {
            local found_silo_name = 1
            continue, break
        }
    }
    if `found_silo_name' == 0 {
        di as error "Error: The silo_name: `silo_name' is not recognized. Must be one of: `silos'."
        exit 5
    }
    qui keep if silo_name == "`silo_name'"

    // Grab empty_diff date format and weights
    local empty_diff_date_format = date_format[1]
    local weight = lower(weights[1])
    if !inlist("`weight'", "none", "diff", "att", "both") {
        di as error "Error: Found a weight that was not one of: none, diff, att, or both."
        exit 17
    }

    // Convert diff_estimate, diff_var, diff_estimate_covariates, and diff_var_covariates in to numeric (double) columns with maximum precision
    foreach var in diff_estimate diff_var diff_estimate_covariates diff_var_covariates {
        qui replace `var' = "" if `var' == "NA" | `var' == "missing"
        qui destring `var', replace
        qui gen double `var'_tmp = `var'
        qui drop `var'
        qui gen double `var' = `var'_tmp
        qui drop `var'_tmp
        qui format `var' %20.15g
    }

    // Grab information to post to trends_data.csv files
    if `check_common' == 1 {
        if treat[1] == "0" {
            local treatment_time_trends "control"
        }
        else if treat[1] == "1" {
            local treatment_time_trends = common_treatment_time[1]
        }
    }
    else {
        levelsof treat if RI == "0", local(levels_treat)
        local first_treat : word 1 of `levels_treat'
        if "`first_treat'" == "0" {
            local treatment_time_trends "control"
        }
        else if "`first_treat'" == "1" {
            levelsof gvar if RI == "0", local(levels_gvar)
            local first_gvar : word 1 of `levels_gvar'
            local treatment_time_trends "`first_gvar'"
        }
    }

    // Check that covariates specified in empty_diff_df exist in the silo data
    if `consider_covariates' == 1 {
        local covariates = subinstr(covariates[1], ";", " ", .)
    }
    else if `consider_covariates' == 0 {
        local covariates = "none"
    }
    qui local n_covariates = wordcount("`covariates'")
    local covariates_missing = 0
    local covariates_numeric = 0
    qui frame change default
    if "`covariates'" != "none" {
        forvalues i = 1/`n_covariates' {
            local covariate : word `i' of `covariates'
            qui capture confirm variable `covariate'
            if _rc {
                di as error "`covariate' could not be found in the local silo data."
                local covariates_missing = 1
            }
        }
    }
    if `covariates_missing' == 1 {
         di as error "Consider renaming variables in the local silo to match: `covariates'."
         di as error "Alternatively, set consider_covariates = 0."
         exit 6
    }

    // time_column and outcome_column are implicitly checked for existence in the local silo data
    // Make sure time_column is a string: if its a numeric value there could be severe issues, e.g.
    // if the time_column is years in numeric value that could be either 1991 or, a Stata date object being the 
    // number of days since Jan 1 1960 (11323). Putting time_column into a specific date format removes ambiguity
    // and ensure the date information is processed correctly. Also make sure outcome_column and covariate columns are numeric
    qui cap confirm string variable `time_column'
    if _rc {
        di as error "Error: `time_column' must be a string variable in the given date format (`silo_date_format')."
        exit 7
    }
    qui ds `outcome_column', has(type numeric)
    if "`r(varlist)'" == "" {
        di as error "Error: `outcome_column' must be a numeric variable."
        exit 8
    }
    if "`covariates'" != "none" {
        forvalues i = 1/`n_covariates' {
            local covariate : word `i' of `covariates'
            qui ds `covariate', has(type numeric)
            if "`r(varlist)'" == "" {
                di as error "Error: `covariate' must be a numeric variable."
                local covariates_numeric = 1
            }
        }
    }
    if `covariates_numeric' == 1 {
        exit 9
    }

    // Check for missing values in time_column, outcome_column and covariate columns if applicable
    qui count if missing(`outcome_column')
    if r(N) > 0 {
        di as error "Error: `outcome_column' has `r(N)' missing values!"
        exit 10
    }
    qui count if `time_column' == ""
    if r(N) > 0 {
        di as error "Error: `time_column' has `r(N)' missing values!"
        exit 11
    }
    local covariate_missing_values = 0
    if "`covariates'" != "none" {
        forvalues i = 1/`n_covariates' {
            local covariate : word `i' of `covariates'
            qui count if missing(`covariate')
            if r(N) > 0 {
                di as error "Error: `covariate' has missing values."
                local covariate_missing_values = 1
            }
        }
    }
    if `covariate_missing_values' == 1 {
        di as error "Error: Encountered covariate columns with missing values."
        exit 12
    }

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------------- PART TWO: Processing -------------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    // Switch to empty_diff and create the start and end times as date objects (useful for both common and staggered scenarios)
    qui frame change `diff_df'
    qui _parse_string_to_date, varname(start_time) date_format("`empty_diff_date_format'") newvar(start_date)
    qui _parse_string_to_date, varname(end_time) date_format("`empty_diff_date_format'") newvar(end_date)
    local end_date = end_date[1]
    local start_date = start_date[1]
    // Define date increments
    local freq_string = freq[1]
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

    if `check_common' == 1 {
        // Compute diff_estimate and diff_var
        qui levelsof common_treatment_time, local(common_treatment_local) clean
        local cmn_trt_time = word("`common_treatment_local'", 1)
        qui levelsof date_format, local(date_formats) clean
        local diff_df_date_format = word("`date_formats'", 1)
        qui _parse_string_to_date, varname(common_treatment_time) date_format("`diff_df_date_format'") newvar(cmn_trt_date)
        qui summarize cmn_trt_date
        local trt_date = r(min)
        qui drop cmn_trt_date
        qui frame change default
        tempvar start_date_fixed
        gen `start_date_fixed' = real("`start_date'")
        tempvar end_date_fixed
        gen `end_date_fixed' = real("`end_date'")
        tempvar date
        tempvar trt_indicator
        qui _parse_string_to_date, varname(`time_column') date_format("`silo_date_format'") newvar(`date')
        qui gen `trt_indicator' = (`date' >= `trt_date')
        qui count if `trt_indicator' == 0
        local count_0 = r(N)
        qui count if `trt_indicator' == 1
        local count_1 = r(N)
        if `count_0' == 0 | `count_1' == 0 {
            di as error "Error: The local silo must have at least one obs before and after (or at) `cmn_trt_time'."
            exit 13
        }
        local weight_val_n = .
        local weight_val_n_t = .
        if inlist("`weight'", "diff", "both") {
            local weight_val_n = `count_0' + `count_1'
            if `anonymize_weights' == 1 {
                local weight_val_n = max(`anonymize_size', `anonymize_size' * round(`weight_val_n' / `anonymize_size'))
            }
        }
        if inlist("`weight'", "att", "both") {
            local weight_val_n_t = `count_1'
            if `anonymize_weights' == 1 {
                local weight_val_n_t = max(`anonymize_size', `anonymize_size' * round(`weight_val_n_t' / `anonymize_size'))
            }
        }
        
        qui regress `outcome_column' `trt_indicator' if `date' >= `start_date_fixed' & `date' <= `end_date_fixed', robust
        local diff_estimate = _b[`trt_indicator']
        local diff_var = e(V)[1,1]

        // Compute diff_estimate_covariates and diff_var_covariates
        if "`covariates'" != "none" {
            qui regress `outcome_column' `trt_indicator' `covariates' if `date' >= `start_date_fixed' & `date' <= `end_date_fixed', robust
            local diff_estimate_covariates = _b[`trt_indicator']
            local diff_var_covariates = e(V)[1,1]
        }

        // Store values and write filled_diff_df CSV
        qui frame change `diff_df'
        qui replace diff_estimate = `diff_estimate'
        qui replace diff_var = `diff_var'
        qui replace n = cond("`weight_val_n'" == "." | "`weight_val_n'" == "", "NA", string(real("`weight_val_n'"), "%12.0f"))
        qui replace n_t = cond("`weight_val_n_t'" == "." | "`weight_val_n_t'" == "", "NA", string(real("`weight_val_n_t'"), "%12.0f"))
        if `anonymize_weights' == 1 {
            qui replace anonymize_size = string(real("`anonymize_size'"), "%12.0f")
        }
        else {
            qui replace anonymize_size = "NA"
        }
        
        if "`covariates'" != "none" {
            qui replace diff_estimate_covariates = `diff_estimate_covariates'
            qui replace diff_var_covariates = `diff_var_covariates'
        }
        else if "`covariates'" == "none" {
            qui tostring diff_estimate_covariates, replace
            qui tostring diff_var_covariates, replace
            qui replace diff_estimate_covariates = "NA"
            qui replace diff_var_covariates = "NA"
        }
        qui drop start_date
        qui drop end_date
        qui order silo_name treat common_treatment_time start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size
        qui export delimited using "`fullpath_diff'", replace datafmt

        // Before starting the trends data need to regenerate the start_date and end_date
        qui _parse_string_to_date, varname(start_time) date_format("`empty_diff_date_format'") newvar(start_date)
        qui _parse_string_to_date, varname(end_time) date_format("`empty_diff_date_format'") newvar(end_date)
        local end_date = end_date[1]
        local start_date = start_date[1]

        // Start date matching procedure for trends_data
        // Loop through dates from start to one period past end time to create local of dates to be used for trends_data
        local list_of_dates ""
        local current = start_date[1]
        local list_of_dates "`list_of_dates' `current'"
        while `current' <= `end_date' {
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
                    local list_of_dates "`list_of_dates' `current'"
    		    }
    		    else if `next_month' <= 12 {
                    local proposed_day = day(mdy(month(`current') + `num', day(`current'), year(`current')))
                    local proposed_day_minus_one = day(mdy(month(`current') + `num', day(`current') - 1, year(`current')))
                    local proposed_day_minus_two = day(mdy(month(`current') + `num', day(`current') - 2, year(`current')))
                    local proposed_day_minus_three = day(mdy(month(`current') + `num', day(`current') - 3, year(`current')))
                    local day_final = max(`proposed_day', `proposed_day_minus_one', `proposed_day_minus_two', `proposed_day_minus_three')
    		        local current = mdy(month(`current') + `num', day(`current'), year(`current'))
                    local list_of_dates "`list_of_dates' `current'"
    		    }
    		}
    		else if "`unit'" == "years" | "`unit'" == "year" {
    			local current = mdy(month(`current'), day(`current'), year(`current') + `num')
                local list_of_dates "`list_of_dates' `current'"
    		}
    		else {
    			local current = `current' + `increment'
                local list_of_dates "`list_of_dates' `current'"
    		}
        }

        // Match dates from the local silo to the most recently passed date in the list_of_dates local
        qui frame change default
        qui tempvar matched_date
        qui gen `matched_date' = .
        foreach date_str of local list_of_dates {
            tempvar temp_date
            qui gen `temp_date' = real("`date_str'")
            qui replace `matched_date' = `temp_date' if `temp_date' <= `date' & (`matched_date' < `temp_date' | `matched_date' == .)
        }

        // Compute trends_data
        // Initialize locals
        local mean_outcome_count
        local mean_outcome_trends
        if "`covariates'" != "none" {
            local mean_outcome_resid_trends
        }

        // Compute conditional means
        qui levelsof `matched_date', local(matched_dates) clean
        foreach m_date of local matched_dates {
            qui summarize `outcome_column' if `matched_date' == `m_date'
            qui local mean_outcome = r(mean)
            if inlist("`weight'", "diff", "att", "both") {
                qui local n_outcome = r(N)
                if `anonymize_weights' == 1 {
                    local n_outcome  = max(`anonymize_size', `anonymize_size' * round(`n_outcome' / `anonymize_size'))
                }
            }
            else {
                qui local n_outcome = .
            }
            local mean_outcome_trends "`mean_outcome_trends' `mean_outcome'"
            local mean_outcome_count "`mean_outcome_count' `n_outcome'"
            if "`covariates'" != "none" {
                qui reg `outcome_column' `covariates' if `matched_date' == `m_date', noconstant
                tempvar resid_trends
                qui predict double `resid_trends' if `matched_date' == `m_date', residuals
                qui summarize `resid_trends'
                qui local mean_outcome_resid = r(mean)
                qui drop `resid_trends'
                local mean_outcome_resid_trends "`mean_outcome_resid_trends' `mean_outcome_resid'"
            }
        }

        // Create trends frame
        if "`covariates'" == "none" {
            tempname trends_frame
            qui cap frame drop `trends_frame'
            qui frame create `trends_frame' ///
            strL silo_name ///
            strL treatment_time ///
            double time_numeric int ///
            double mean_outcome /// 
            strL mean_outcome_residualized ///
            strL covariates ///
            strL date_format ///
            strL freq ///
            strL n

        }
        else if "`covariates'" != "none"{
            tempname trends_frame
            qui cap frame drop `trends_frame'
            qui frame create `trends_frame' ///
            strL silo_name ///
            strL treatment_time ///
            double time_numeric int ///
            double mean_outcome /// 
            double mean_outcome_residualized ///
            strL covariates ///
            strL date_format ///
            strL freq ///
            strL n
        }
        
        // Populate trends frame
        qui frame change `trends_frame'
        local N : word count `matched_dates'
        local covariates = subinstr("`covariates'", " ", ";", .)
        forvalues i = 1/`N' {
            local time : word `i' of `matched_dates'
            local mean_outcome : word `i' of `mean_outcome_trends'
            local n_count : word `i' of `mean_outcome_count'
            local n_count = cond("`n_count'" == "." | "`n_count'" == "", "NA", string(real("`n_count'"), "%12.0f"))
            if "`covariates'" == "none" {
                qui frame post `trends_frame' ("`silo_name'") ("`treatment_time_trends'") (`time') (`mean_outcome') ("NA") ("`covariates'") ("`empty_diff_date_format'") ("`freq_string'") ("`n_count'")
            }
            else if "`covariates'" != "none" {
                local mean_outcome_resid : word `i' of `mean_outcome_resid_trends'
                qui frame post `trends_frame' ("`silo_name'") ("`treatment_time_trends'") (`time') (`mean_outcome') (`mean_outcome_resid') ("`covariates'") ("`empty_diff_date_format'") ("`freq_string'") ("`n_count'")
            }    
        }
        
        // Convert numeric time in the trends data to a readable format 
        qui _parse_date_to_string, varname(time_numeric) date_format("`empty_diff_date_format'") newvar(time)
        qui order silo_name treatment_time time mean_outcome mean_outcome_residualized covariates date_format freq
        qui drop time_numeric 

        // Write trends_data CSV file
        qui export delimited using "`fullpath_trends'", replace
        qui frame change default
        
    }
    else if `check_staggered' == 1 {
        // Start by doing the date matching procedure
        // Loop through dates from start to one period past end time 
        local list_of_dates ""
        local current = start_date[1]
        local list_of_dates "`list_of_dates' `current'"
        while `current' <= `end_date' {
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
                    local list_of_dates "`list_of_dates' `current'"
    		    }
    		    else if `next_month' <= 12 {
                    local proposed_day = day(mdy(month(`current') + `num', day(`current'), year(`current')))
                    local proposed_day_minus_one = day(mdy(month(`current') + `num', day(`current') - 1, year(`current')))
                    local proposed_day_minus_two = day(mdy(month(`current') + `num', day(`current') - 2, year(`current')))
                    local proposed_day_minus_three = day(mdy(month(`current') + `num', day(`current') - 3, year(`current')))
                    local day_final = max(`proposed_day', `proposed_day_minus_one', `proposed_day_minus_two', `proposed_day_minus_three')
    		        local current = mdy(month(`current') + `num', day(`current'), year(`current'))
                    local list_of_dates "`list_of_dates' `current'"
    		    }
    		}
    		else if "`unit'" == "years" | "`unit'" == "year" {
    			local current = mdy(month(`current'), day(`current'), year(`current') + `num')
                local list_of_dates "`list_of_dates' `current'"
    		}
    		else {
    			local current = `current' + `increment'
                local list_of_dates "`list_of_dates' `current'"
    		}
        }

        // Grab all of the pre and post times for the diff_estimate calculations
        qui tempvar post pre
        qui tempvar post_date
        qui tempvar pre_date
        qui gen `post' = substr(diff_times, 1, strpos(diff_times, ";") - 1)
        qui gen `pre'  = substr(diff_times, strpos(diff_times, ";") + 1, .)
        qui _parse_string_to_date, varname(`post') date_format("`empty_diff_date_format'") newvar(`post_date') 
        qui _parse_string_to_date, varname(`pre') date_format("`empty_diff_date_format'") newvar(`pre_date')
        local postlist
        local prelist
        qui {
            forvalues i = 1/`=_N' {
                local post = `post_date'[`i']
                local pre  = `pre_date'[`i']

                local postlist "`postlist' `post'"
                local prelist  "`prelist' `pre'"
            }
        }

        // Match dates from the local silo to the most recently passed date in the list_of_dates local
        qui frame change default
        qui tempvar date
        qui _parse_string_to_date, varname(`time_column') date_format("`silo_date_format'") newvar(`date')
        qui tempvar matched_date
        qui gen `matched_date' = .
        foreach date_str of local list_of_dates {
            tempvar temp_date
            qui gen `temp_date' = real("`date_str'")
            qui replace `matched_date' = `temp_date' if `temp_date' <= `date' & (`matched_date' < `temp_date' | `matched_date' == .)
        }
                  
        // Start running regressions 
        local coef_list ""
        local coef_list_var ""
        local weight_val_n_list ""
        local weight_val_n_t_list ""
        if  "`covariates'" != "none" {
            local coef_list_cov ""
            local coef_list_cov_var ""
        }
        local n_pairs : word count `postlist'
        forvalues i = 1/`n_pairs' {
            local this_post = word("`postlist'", `i')
            local this_pre  = word("`prelist'", `i')
            preserve
                qui count if `matched_date' == `this_pre'
                local n_pre = r(N)
                qui count if `matched_date' == `this_post'
                local n_post = r(N)
                if `n_pre' == 0 | `n_post' == 0 {
                    local coef_list "`coef_list' ."
                    local coef_list_var "`coef_list_var' ."
                    local coef_list_cov "`coef_list_cov' ."
                    local coef_list_cov_var "`coef_list_cov_var' ."
                    local weight_val_n_list "`weight_val_n_list' ."
                    local weight_val_n_t_list "`weight_val_n_t_list' ."
                }
                else if `n_pre' + `n_post' < 2 {
                    local coef_list "`coef_list' ."
                    local coef_list_var "`coef_list_var' ."
                    local coef_list_cov "`coef_list_cov' ."
                    local coef_list_cov_var "`coef_list_cov_var' ."
                    local weight_val_n_list "`weight_val_n_list' ."
                    local weight_val_n_t_list "`weight_val_n_t_list' ."
                }
                else {
                    qui keep if `matched_date' == `this_post' | `matched_date' == `this_pre'
                    tempvar x
                    qui gen `x' = (`matched_date' == real("`this_post'"))
                    qui regress `outcome_column' `x', robust
                    local b = _b[`x']
                    local b_var = e(V)[1,1]
                    local weight_val_n = "."
                    local weight_val_n_t = "."
                    if "`covariates'" != "none" {
                        qui regress `outcome_column' `x' `covariates', robust
                        local b_cov = _b[`x']
                        local b_cov_var = e(V)[1,1]
                        local coef_list_cov "`coef_list_cov' `b_cov'"
                        local coef_list_cov_var "`coef_list_cov_var' `b_cov_var'"
                    }
                    else {
                        local coef_list_cov "`coef_list_cov' ."
                        local coef_list_cov_var "`coef_list_cov_var' ."
                    }
                    local coef_list "`coef_list' `b'"
                    local coef_list_var "`coef_list_var' `b_var'"
                    if inlist("`weight'", "diff", "both") {
                        local weight_val_n = `n_pre' + `n_post'
                        if `anonymize_weights' == 1 {
                            local weight_val_n = max(`anonymize_size', `anonymize_size' * round(`weight_val_n' / `anonymize_size'))
                        }
                    }
                    local weight_val_n_list "`weight_val_n_list' `weight_val_n'"
                    if inlist("`weight'", "att", "both") {
                        local weight_val_n_t = `n_post'
                        if `anonymize_weights' == 1 {
                            local weight_val_n_t = max(`anonymize_size', `anonymize_size' * round(`weight_val_n_t' / `anonymize_size'))
                        }
                    }
                    local weight_val_n_t_list "`weight_val_n_t_list' `weight_val_n_t'"

                }
            restore
        }

        // Switch back to the diff_df and post results and write the csv output
        qui frame change `diff_df'
        local n_coefs : word count `coef_list'
        qui set obs `n_coefs'
        qui drop diff_estimate
        qui drop diff_var
        qui drop diff_estimate_covariates
        qui drop diff_var_covariates
        qui drop n 
        qui drop n_t
        qui drop anonymize_size
        qui gen str12 n = ""
        qui gen str12 n_t = ""
        qui gen str25 diff_estimate = ""
        qui gen str25 diff_var = ""
        qui gen str25 diff_estimate_covariates = ""
        qui gen str25 diff_var_covariates = ""
        forvalues i = 1/`n_coefs' {
            local coef : word `i' of `coef_list'
            local coef_var : word `i' of `coef_list_var'
            local coef_cov : word `i' of `coef_list_cov'
            local coef_cov_var : word `i' of `coef_list_cov_var'
            local n : word `i' of `weight_val_n_list'
            local n_t : word `i' of `weight_val_n_t_list'
            qui replace diff_estimate = cond("`coef'" == "." | "`coef'" == "", "NA", string(real("`coef'"), "%21.18f")) in `i'
            qui replace diff_var = cond("`coef_var'" == "." | "`coef_var'" == "", "NA", string(real("`coef_var'"), "%21.18f")) in `i'
            qui replace diff_estimate_covariates = cond("`coef_cov'" == "." | "`coef_cov'" == "", "NA", string(real("`coef_cov'"), "%21.18f")) in `i'
            qui replace diff_var_covariates = cond("`coef_cov_var'" == "." | "`coef_cov_var'" == "", "NA", string(real("`coef_cov_var'"), "%21.18f")) in `i'
            qui replace n = cond("`n'" == "." | "`n'" == "", "NA", string(real("`n'"), "%12.0f")) in `i'
            qui replace n_t = cond("`n_t'" == "." | "`n_t'" == "", "NA", string(real("`n_t'"), "%12.0f")) in `i'
        }
        if `anonymize_weights' == 1 {
            qui gen anonymize_size = `anonymize_size'
        }
        else {
            qui gen anonymize_size = "NA"
        }
        qui keep silo_name gvar treat diff_times gt RI start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size
        qui order silo_name gvar treat diff_times gt RI start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size
        qui export delimited using "`fullpath_diff'", replace datafmt        

        // Now do trends data!
        qui frame change default 
        // Initialize locals
        local mean_outcome_count
        local mean_outcome_trends
        if "`covariates'" != "none" {
            local mean_outcome_resid_trends
        }

        // Compute conditional means
        qui levelsof `matched_date', local(matched_dates) clean
        foreach m_date of local matched_dates {
            qui summarize `outcome_column' if `matched_date' == `m_date'
            qui local mean_outcome = r(mean)
            local mean_outcome_trends "`mean_outcome_trends' `mean_outcome'"
            if inlist("`weight'", "diff", "att", "both") {
                qui local n_outcome = r(N)
                if `anonymize_weights' == 1 {
                    local n_outcome  = max(`anonymize_size', `anonymize_size' * round(`n_outcome' / `anonymize_size'))
                }
            }
            else {
                qui local n_outcome = .
            }
            local mean_outcome_count "`mean_outcome_count' `n_outcome'"
            if "`covariates'" != "none" {
                qui reg `outcome_column' `covariates' if `matched_date' == `m_date', noconstant
                tempvar resid_trends
                qui predict double `resid_trends' if `matched_date' == `m_date', residuals
                qui summarize `resid_trends'
                qui local mean_outcome_resid = r(mean)
                qui drop `resid_trends'
                local mean_outcome_resid_trends "`mean_outcome_resid_trends' `mean_outcome_resid'"
            }
        }
        
        // Create trends frame
        if "`covariates'" == "none" {
            tempname trends_frame
            qui cap frame drop `trends_frame'
            qui frame create `trends_frame' ///
            strL silo_name ///
            strL treatment_time ///
            double time_numeric int ///
            double mean_outcome /// 
            strL mean_outcome_residualized ///
            strL covariates ///
            strL date_format ///
            strL freq ///
            strL n
        }
        else if "`covariates'" != "none"{
            tempname trends_frame
            qui cap frame drop `trends_frame'
            qui frame create `trends_frame' ///
            strL silo_name ///
            strL treatment_time ///
            double time_numeric int ///
            double mean_outcome /// 
            double mean_outcome_residualized ///
            strL covariates ///
            strL date_format ///
            strL freq ///
            strL n
        }
        
        // Populate trends frame
        qui frame change `trends_frame'
        local N : word count `matched_dates'
        local covariates = subinstr("`covariates'", " ", ";", .)
        forvalues i = 1/`N' {
            local time : word `i' of `matched_dates'
            local mean_outcome : word `i' of `mean_outcome_trends'
            local n_count : word `i' of `mean_outcome_count'
            local n_count = cond("`n_count'" == "." | "`n_count'" == "", "NA", string(real("`n_count'"), "%12.0f"))
            if "`covariates'" == "none" {
                qui frame post `trends_frame' ("`silo_name'") ("`treatment_time_trends'") (`time') (`mean_outcome') ("NA") ("`covariates'") ("`empty_diff_date_format'") ("`freq_string'") ("`n_count'")
            }
            else if "`covariates'" != "none" {
                local mean_outcome_resid : word `i' of `mean_outcome_resid_trends'
                qui frame post `trends_frame' ("`silo_name'") ("`treatment_time_trends'") (`time') (`mean_outcome') (`mean_outcome_resid') ("`covariates'") ("`empty_diff_date_format'") ("`freq_string'") ("`n_count'")
            }    
        }
        
        // Convert numeric time in the trends data to a readable format 
        qui _parse_date_to_string, varname(time_numeric) date_format("`empty_diff_date_format'") newvar(time)
        qui order silo_name treatment_time time mean_outcome mean_outcome_residualized covariates date_format freq
        qui drop time_numeric 

        // Write trends_data CSV file
        qui export delimited using "`fullpath_trends'", replace
        qui frame change default
    }

    // Convert to Windows-friendly format for display if on Windows
    if "`c(os)'" == "Windows" {
        local fullpath_display_diff = subinstr("`fullpath_diff'", "/", "\", .)
        local fullpath_display_trends = subinstr("`fullpath_trends'", "/", "\", .)
    } 
    else {
        local fullpath_display_diff "`fullpath_diff'"
        local fullpath_display_trends "`fullpath_trends'"
    }
    di as result "filled_diff_df_`silo_name'.csv file saved to: `fullpath_display_diff'"
    di as result "trends_data_`silo_name'.csv file saved to: `fullpath_display_trends'"
    
end

/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*1.0.0 - created function