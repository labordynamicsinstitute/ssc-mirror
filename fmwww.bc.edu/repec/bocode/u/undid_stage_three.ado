/*------------------------------------*/
/*undid_stage_three*/
/*written by Eric Jamieson */
/*version 2.0.1 2026-02-17 */
/*------------------------------------*/
cap program drop undid_stage_three
program define undid_stage_three, rclass
    version 16
    syntax, dir_path(string) /// 
            [agg(string) weights(string) covariates(int 0) notyet(int 0) ///
            nperm(int 999) verbose(int 250) seed(int 0) max_attempts(int 100) check_anon_size(int 0) hc(int 3) ///
            omit(string) only(string)]

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------- PART ONE: Basic Input Checks ------------------------------ // 
    // ---------------------------------------------------------------------------------------- //

    // First, check all the binary inputs:
    // Check covariates
    if !inlist(`covariates', 0, 1) {
        di as error "Error: covariates must be set to 0 (false) or to 1 (true)."
        exit 3
    }
    // Check verbose
    if `verbose' < 0 {
        di as error "Error: verbose must be set to 0 (off) or a positive integer denoting how often to print progress messages for randomization inference."
        exit 4
    }
    // Check notyet
    if !inlist(`notyet', 0, 1) {
        di as error "Error: notyet must be set to either 0 (false) or 1 (true)."
        exit 8
    }

    if !inlist(`check_anon_size', 0, 1) {
        di as error "Error: 'check_anon_size' must be set to either 0 (false) or 1 (true)."
        exit 17
    }

    // Check other numeric args
    // Check nperm
    if `nperm' < 1 {
        di as error "Error: nperm must be greater than 0" 
        exit 5
    }

    // Process seed
    if "`seed'" != "0" {
        set seed `seed'
    }
    // Check max_attempts
    if `max_attempts' < 1 {
        di as error "Error: 'max_attempts' must be > 0!"
        exit 16
    }
    // Check hc
    if !inlist(`hc', 0, 1, 2, 3, 4) {
        di as error "Error: 'hc' options are: 0, 1, 2, 3, or 4."
        exit 19
    }

    // Check string inputs
    // Check agg
    local agg = lower("`agg'")
    if "`agg'" == "" {
        local agg = "g"
    }
    if !inlist("`agg'", "silo", "g", "gt", "sgt", "none", "time") {
        di as error "Error: agg must be one of: silo, g, gt, sgt, none, time"
        exit 6
    }
    // Check weights
    local weights = lower("`weights'")
    local get_weights = 0
    if "`weights'" == "" {
        local get_weights = 1
    }
    else if !inlist("`weights'", "none", "diff", "att", "both") {
        di as error "Error: weights must be either blank or one of: none, diff, att, both."
        exit 15
    }
    
    // ---------------------------------------------------------------------------------------- //
    // ---------------------------- PART TWO: Read and Combine Data --------------------------- // 
    // ---------------------------------------------------------------------------------------- // 
    
    // Grab all filled_diff_df file names
    local files : dir "`dir_path'" files "filled_diff_df_*.csv"
    local nfiles : word count `files'
    if `nfiles' == 0 {
        display as error "No filled_diff_df_*.csv files found in `dir_path'"
        exit 7
    }

    // Create tempframe to import each csv file and push to a master frame
    tempfile master
    local first = 1
    qui tempname temploadframe
    qui cap frame drop `temploadframe'  
    qui frame create `temploadframe'
    qui frame change `temploadframe'
    foreach f of local files {
        local fn = "`dir_path'/`f'"
        qui import delimited using "`fn'", clear stringcols(_all) case(preserve)

        if `first' {
            qui save "`master'", replace
            local first = 0
        }
        else {
            qui append using "`master'"
            qui save "`master'", replace
        }
    }
    qui use "`master'", clear
    // Grab date format
    local date_format = date_format[1]
    if `get_weights' == 1 {
        local weights = weights[1]
    }

    // Check if staggered or common adoption
    local expected_common "silo_name treat common_treatment_time start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size"
    local expected_staggered "silo_name gvar treat diff_times gt RI start_time end_time weights diff_estimate diff_var diff_estimate_covariates diff_var_covariates covariates date_format freq n n_t anonymize_size"
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
        di as error "Error: The loaded CSVs do not match the expected staggered adoption or common treatment time structure."
        exit 9
    }

    // Remove any whitespace from state names 
    qui replace silo_name = subinstr(silo_name, " ", "", .)

    // Apply the only arg
    if "`only'" != "" {
        tempvar keep_flag
        qui gen byte `keep_flag' = 0
        foreach silo in `only' {
            qui replace `keep_flag' = 1 if silo_name == "`silo'"
        }
        qui keep if `keep_flag' == 1
        drop `keep_flag'
    }
    
    // Apply the omit arg
    if "`omit'" != "" {
        foreach silo in `omit' {
            qui drop if silo_name == "`silo'"
        }
    }

    // Process columns with potential NA/missing to be missing strings then convert to numeric columns
    foreach var in treat n n_t {
        qui replace `var' = "" if `var' == "NA" | `var' == "missing"
        qui destring `var', replace
    }
    foreach var in diff_estimate diff_var {
        qui replace `var' = "" if `var' == "NA" | `var' == "missing"
        qui destring `var', replace
        qui gen double `var'_tmp = `var'
        qui drop `var'
        qui gen double `var' = `var'_tmp
        qui drop `var'_tmp
        qui format `var' %20.15g 
    }
    if `covariates' == 1 {
        foreach var in diff_estimate_covariates diff_var_covariates {
        qui replace `var' = "" if `var' == "NA" | `var' == "missing"
        qui destring `var', replace
        qui gen double `var'_tmp = `var'
        qui drop `var'
        qui gen double `var' = `var'_tmp
        qui drop `var'_tmp
        qui format `var' %20.15g
        }
    }

    // Set y depending on covariates selection
    if `covariates' == 1 {
        qui gen double y = diff_estimate_covariates
        qui format y %20.15g
        // Check if all values of y are missing
        qui count if !missing(y)
        if r(N) == 0 {
            di as err "Error: All values of diff_estimate_covariates are missing, try setting covariates(0)."
            exit 10
        }
        qui gen double yvar =  diff_var_covariates
        qui format yvar %20.15g
    }
    else {
        qui gen double y = diff_estimate
        qui format y %20.15g
        qui gen double yvar = diff_var
        qui format yvar %20.15g
    }

    // Drop rows where y is missing 
    if `check_staggered' == 1 {
        qui count if missing(y)
        local nmiss = r(N)
        if `nmiss' > 0 {
            di as error "Dropping the following rows where y is missing:"
            list silo_name gt treat if missing(y), noobs sepby(silo_name)
            qui drop if missing(y)
        }
    }
    else if `check_common' == 1 {
        qui count if missing(y)
        local nmiss = r(N)
        if `nmiss' > 0 {
            di as error "Dropping the following silo_names for which y is missing:"
            list silo_name if missing(y), noobs sepby(silo_name)
            qui drop if missing(y)
        }
    }

    // If notyet is toggled on, rearrange the data as necessary
    if `check_staggered' == 1 {
        qui gen t_str = substr(gt, strpos(gt, ";") + 1, .)
        qui _parse_string_to_date, varname(t_str) date_format("`date_format'") newvar(t) 
        qui _parse_string_to_date, varname(gvar) date_format("`date_format'") newvar(gvar_date) 
    }
    if `check_staggered' == 1 & `notyet' == 1 {
        qui egen double treated_time_silo = min(cond(treat==1, gvar_date, .)), by(silo_name)
        qui replace treat = 0 if treat == -1 & t < treated_time_silo
        qui drop treated_time_silo
    }

    // Ensure that agg option of "none" isn't selected for staggered adoption
    if `check_staggered' == 1 & "`agg'" == "none" {
        di as error "Error: Cannot use 'none' aggregation for staggered adoption."
        exit 18
    }
    
    // Check that at least one treat and untreated diff exist for each sub-agg ATT computation, drop that sub-agg ATT if not
    // Also do some extra processing if agg == "time" then create the time column which indicates periods since treatment
    if `check_staggered' == 1 {
        if inlist("`agg'", "g", "silo") {
            qui levelsof gvar, local(gvars)
            foreach g of local gvars {
                qui count if treat == 1 & gvar == "`g'"
                local treated_count = r(N)
                qui count if treat == 0 & gvar == "`g'"
                local control_count = r(N)
                if `treated_count' < 1 | `control_count' < 1 {
                    di as err "Warning: Could not find at least one treated and one control observation for gvar = `g'."
                    di as err "Warning: Dropping rows where gvar = `g'."
                    qui drop if gvar == "`g'"
                }
            }
            qui count if treat == 1
            local treated_count = r(N)
            qui count if treat == 0
            local control_count = r(N)
            if `treated_count' < 1 | `control_count' < 1 {
                di as err "Error: Need at least one treated and one control observation."
                exit 11
            }
        }
        if inlist("`agg'", "gt", "sgt") {
            qui levelsof gt, local(gts)
            foreach gt of local gts {
                qui count if treat == 1 & gt == "`gt'"
                local treated_count = r(N)
                qui count if treat == 0 & gt == "`gt'"
                local control_count = r(N)
                if `treated_count' < 1 | `control_count' < 1 {
                    di as err "Warning: Could not find at least one treated and one control observation for gt = `gt'."
                    di as err "Warning: Dropping rows where gt = `gt'."
                    qui drop if gt == "`gt'"
                }
            }
            qui count if treat == 1
            local treated_count = r(N)
            qui count if treat == 0
            local control_count = r(N)
            if `treated_count' < 1 | `control_count' < 1 {
                di as err "Error: Need at least one treated and one control observation."
                exit 11
            }
        }
        if "`agg'" == "silo" {
            qui levelsof silo_name if treat == 1, local(treated_silos)
            local num_treated_silos : word count `treated_silos'
            if `num_treated_silos' < 1 {
                di as error "Error: Could not find any treated silos!"
                exit 12
            }
            foreach s of local treated_silos {
                qui levelsof gvar if silo_name == "`s'" & treat == 1, local(silo_gvar)
                foreach g of local silo_gvar {
                    // Implictly already determined that there will be at least one treated obs so can just count control obs
                    qui count if treat == 0 & gvar == "`g'"
                    local control_count = r(N)
                    if `control_count' < 1 {
                        di as err "Warning: Could not find at least one control obs where gvar = `g' to match to treat = 1 & silo_name = `s' & gvar = `g'."
                        di as err "Warning: Dropping rows where treat = 1 & gvar == `g' & silo_name == `s'"
                        qui drop if treat == 1 & gvar == "`g'" & silo_name == "`s'"
                    }
                }
            }
            qui count if treat == 1
            local treated_count = r(N)
            qui count if treat == 0
            local control_count = r(N)
            if `treated_count' < 1 | `control_count' < 1 {
                di as err "Error: Need at least one treated and one control observation."
                exit 11
            }
        }
        if "`agg'" == "sgt" {
            qui levelsof silo_name if treat == 1, local(treated_silos)
            local num_treated_silos : word count `treated_silos'
            if `num_treated_silos' < 1 {
                di as error "Error: Could not find any treated silos!"
                exit 12
            }
            foreach s of local treated_silos {
                qui levelsof gt if silo_name == "`s'" & treat == 1, local(silo_gts)
                foreach gt of local silo_gts {
                    // Implictly already determined that there will be at least one treated obs so can just count control obs
                    qui count if treat == 0 & gt == "`gt'"
                    local control_count = r(N)
                    if `control_count' < 1 {
                        di as err "Warning: Could not find at least one control obs where gt = `gt' to match to treat = 1 & silo_name = `s' & gt = `gt'."
                        di as err "Warning: Dropping rows where treat = 1 & gt == `gt' & silo_name == `s'"
                        qui drop if treat == 1 & gt == "`gt'" & silo_name == "`s'"
                    }
                }
            }
            qui count if treat == 1
            local treated_count = r(N)
            qui count if treat == 0
            local control_count = r(N)
            if `treated_count' < 1 | `control_count' < 1 {
                di as err "Error: Need at least one treated and one control observation."
                exit 11
            }
        }
        if "`agg'" == "time" {
            qui gen double time = .
            qui gen freq_n = real(word(freq, 1))
            qui gen freq_unit = lower(word(freq, 2))
            if substr(freq_unit, 1, 3) == "yea" {
                qui replace time = floor((year(t) - year(gvar_date)) / freq_n)
            }
            else if substr(freq_unit, 1, 3) == "mon" {
                qui replace time = floor((ym(year(t),  month(t)) - ym(year(gvar_date), month(gvar_date))) / freq_n)
            }
            else if substr(freq_unit, 1, 3) == "wee" {
                qui replace time = floor((t - gvar_date) / (7 * freq_n))
            }
            else if substr(freq_unit, 1, 3) == "day" { 
                qui replace time = floor((t - gvar_date) / freq_n)
            }
            qui drop freq_n
            qui drop freq_unit
            qui levelsof time, local(time_groups)
            foreach time_g of local time_groups {
                qui count if treat == 1 & time == `time_g'
                local treated_count = r(N)
                qui count if treat == 0 & time == `time_g'
                local control_count = r(N)
                if `treated_count' < 1 | `control_count' < 1 {
                    di as err "Warning: Could not find at least one treated and one control obs for periods since treatment: `time_g'."
                    di as err "Dropping all rows where periods since treatment = `time_g'."
                    qui drop if time == `time_g'
                }
            }
            qui count if treat == 1
            local treated_count = r(N)
            qui count if treat == 0
            local control_count = r(N)
            if `treated_count' < 1 | `control_count' < 1 {
                di as err "Error: Need at least one treated and one control observation."
                exit 11
            }
        }
    }

    // Force the agg and weights arguments to different strings, depening on how many treated silos there are 
    if `check_common' == 1 {
        qui count if treat == 1
        local treated_count = r(N)
        qui count if treat == 0
        local control_count = r(N)
        if `treated_count' < 1 | `control_count' < 1 {
            di as err "Error: Need at least one treated and one control observation."
            exit 11
        }
        if (!inlist("`agg'", "silo", "sgt")) & inlist("`weights'", "att", "both") {
            di as error "Warning: weighting methods 'att' and 'both' are only applicable to aggregation method of 'silo' or 'sgt' for common adoption scenarios as they apply weights to sub-aggregate ATTs which are not caluclated in a common adoption scenario when agg is any of 'g', 'gt', 'time', or 'none'. Overwriting weights to 'diff'."
            local weights "diff"
        }
        qui levelsof silo_name if treat == 1, local(treated_silos)
        local num_treated_silos : word count `treated_silos'
        if `num_treated_silos' == 1 {
            if inlist("`weights'", "diff", "att", "both") {
                di as error "Warning: only one treated silo detected, setting weights to: diff"
                local weights "diff"
            }
            if inlist("`agg'", "sgt", "silo") {
                di as error "Warning: only one treated silo detected, setting agg to: none"
                local agg "none"
            }
            else if inlist("`agg'", "g", "gt", "time") {
                local agg "none"
            }
        }
        else {
            if inlist("`agg'", "g", "gt", "time") {
                local agg "none"
            }
            else if inlist("`agg'", "sgt", "silo") {
                local agg "silo"
                qui rename common_treatment_time gvar
                qui _parse_string_to_date, varname(gvar) date_format("`date_format'") newvar(gvar_date)
                // This is the same check used in the staggered checks block preceding this section: 
                qui levelsof silo_name if treat == 1, local(treated_silos)
                local num_treated_silos : word count `treated_silos'
                if `num_treated_silos' < 1 {
                    di as error "Error: Could not find any treated silos!"
                    exit 12
                }
                foreach s of local treated_silos {
                    qui levelsof gvar if silo_name == "`s'" & treat == 1, local(silo_gvar)
                    foreach g of local silo_gvar {
                        // Implictly already determined that there will be at least one treated obs so can just count control obs
                        qui count if treat == 0 & gvar == "`g'"
                        local control_count = r(N)
                        if `control_count' < 1 {
                            di as err "Warning: Could not find at least one control obs where gvar = `g' to match to treat = 1 & silo_name = `s' & gvar = `g'."
                            di as err "Warning: Dropping rows where treat = 1 & gvar == `g' & silo_name == `s'"
                            qui drop if treat == 1 & gvar == "`g'" & silo_name == "`s'"
                        }
                    }
                }
                qui count if treat == 1
                local treated_count = r(N)
                qui count if treat == 0
                local control_count = r(N)
                if `treated_count' < 1 | `control_count' < 1 {
                    di as err "Error: Need at least one treated and one control observation."
                    exit 11
                }
            }
        }
    }

    // Throw error if weights selection depends on n or n_t vals that are NA/missing
    if inlist("`weights'", "diff", "both") {
        qui count if missing(n)
        local n_missing = r(N)
        if `n_missing' > 0 {
            di as error "Error: missing counts of n which are required with weighting options: diff and both"
            exit 13
        }
    }
    if inlist("`weights'", "att", "both") {
        qui count if missing(n_t)
        local n_t_missing = r(N)
        if `n_t_missing' > 0 {
            di as error "Error: missing counts of n_t which are required with weighting options: att and both"
            exit 14
        }
    }

    // Check if randomization inference should be done
    local randomize = 1 // Always possible for common adoption
    if `check_staggered' == 1 {
        tempvar has_treat0 has_treat1
        qui bysort gt: egen `has_treat0' = max(treat == 0)
        qui bysort gt: egen `has_treat1' = max(treat == 1)
        
        qui levelsof gt if `has_treat0' == 1 & `has_treat1' == 1, local(gts)
        qui levelsof silo_name, local(silo_names)

        foreach g of local gts {
            foreach s of local silo_names {
                qui count if gt == "`g'" & silo_name == "`s'"
                if r(N) == 0 {
                    local randomize = 0
                    continue, break
                }
            }
            if `randomize' == 0 continue, break
        }
    }

    // If common treatment scenario and gvar doesnt exist, create it 
    if `check_common' == 1 & "`agg'" != "silo" {
        qui rename common_treatment_time gvar
        qui _parse_string_to_date, varname(gvar) date_format("`date_format'") newvar(gvar_date)
    }
    
    // Encode silo_name as silo_id so it can looped thru in the same way in Stata + Mata
    qui encode silo_name, gen(silo_id)

    // Check anon size if requested
    if `check_anon_size' == 1 {
        preserve
            qui drop if anonymize_size == "NA" | anonymize_size == "missing"
            qui count 
            if r(N) > 0 {
                qui duplicates drop silo_name anonymize_size, force
                di as result "Displaying anonymize_size option used at any included silo:"
                list silo_name anonymize_size
            }
            else {
                di as result "None of the included silos used the anonymize_size option."
            }
        restore
    }

    // Sort data and create id columns as needed
    if "`agg'" == "g" {
        qui sort gvar_date
    }
    else if "`agg'" == "gt" {
        qui sort gvar_date t
        qui encode gt, gen(gt_id)
        qui order gt_id, last
    }
    else if "`agg'" == "silo" {
        qui sort silo_id
    }
    else if "`agg'" == "sgt" {
        qui sort silo_id gvar_date t
        qui egen sgt_id = group(silo_name gt)
        qui order sgt_id, last
    }
    else if "`agg'" == "time" {
        qui sort time
    }

    // Store the sub_agg_label
    local sub_agg_label ""
    if "`agg'" == "g" {
        qui levelsof gvar_date, local(gvars)
        foreach g of local gvars {
            preserve 
            qui keep if gvar_date == `g' & treat >= 0
            qui levelsof(gvar), local(g_label)
            local sub_agg_label "`sub_agg_label' `g_label'"
            restore
        }
    }
    else if "`agg'" == "gt" {
        qui levelsof gvar_date, local(gvar_dates)
        foreach g of local gvar_dates {
            preserve
            qui keep if gvar_date == `g' & treat >= 0
            qui levelsof t, local(time)
            foreach t of local time {
                tempfile gt_temp
                qui save `gt_temp', replace
                qui keep if t == `t' & treat >= 0       
                qui levelsof gt if treat > 0, local(gt_label)
                local sub_agg_label "`sub_agg_label' `gt_label'"
                qui use `gt_temp', clear
            }
            restore
        }
    }
    else if "`agg'" == "silo" {
        qui levelsof silo_id if treat == 1, local(silos)
        foreach s of local silos {
            preserve
            qui levelsof gvar_date if silo_id == `s' & treat == 1, local(g)
            qui keep if ((silo_id == `s' & treat == 1) | (treat == 0 & gvar_date == `g' & silo_id != `s'))   
            qui levelsof(silo_name) if treat > 0, local(s_label)
            local sub_agg_label "`sub_agg_label' `s_label'"
            restore
        }        
    }
    else if "`agg'" == "sgt" {
        qui levelsof silo_id if treat == 1, local(silos)
        foreach s of local silos {
            qui levelsof gvar_date if silo_id == `s' & treat == 1, local(gvars)
            foreach gvar of local gvars {
                qui levelsof t if silo_id == `s' & treat == 1 & gvar_date == `gvar', local(times)
                foreach t of local times {
                preserve
                    qui keep if ((silo_id == `s' & treat == 1 & gvar_date == `gvar' & t == `t') | (treat == 0 & gvar_date == `gvar' & t == `t' & silo_id != `s'))
                    qui levelsof silo_name if treat > 0, local(s_label)
                    local clean_s_label : word 1 of `s_label'
                    qui levelsof gt if treat > 0, local(gt_label)
                    local clean_gt_label : word 1 of `gt_label'
                    local sub_agg_label "`sub_agg_label' "`clean_s_label': `clean_gt_label'""
                restore
                }
            }  
        }        
    }
    else if "`agg'" == "time" {
        qui levelsof time, local(times)
        foreach t of local times {
            preserve
            qui keep if time == `t' & treat >= 0
            local sub_agg_label "`sub_agg_label' `t'"
            restore
        }
    }

    // After all the pre-processing checks are done, can finally move on to computation

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------- PART THREE: Compute Results ------------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    // Create the table matrix 
    if "`agg'" != "none" {        
        qui tempname table_matrix
        // Calculate number of rows based on aggregation method
        local nrows : word count `sub_agg_label'
        local num_cols = 7
        qui matrix `table_matrix' = J(`nrows', `num_cols', .)

        // Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
    
        // Set row names for the matrix using the labels
        matrix rownames `table_matrix' = `sub_agg_label'
    }

    // Define some tempnames for scalars for the aggregate levels results 
    qui tempname agg_att 
    qui tempname agg_att_se 
    qui tempname agg_att_jknife_se 
    qui tempname agg_att_pval 
    qui tempname agg_att_jknife_pval
    qui scalar `agg_att' = .
    qui scalar `agg_att_se' = .
    qui scalar `agg_att_jknife_se' = .
    qui scalar `agg_att_pval' = .
    qui scalar `agg_att_jknife_pval' = .

    mata : undid_stage_three_compute(`hc', "`agg'", "`weights'", "`agg_att'", "`agg_att_se'", "`agg_att_pval'", "`agg_att_jknife_se'", "`agg_att_jknife_pval'", `check_common', "`table_matrix'")

    // ---------------------------------------------------------------------------------------- //
    // ------------------------- PART FOUR: Randomization Inference! -------------------------- // 
    // ---------------------------------------------------------------------------------------- //
    qui tempname ri_pval_aggregate
    qui tempname actual_perms_scalar
    qui scalar `ri_pval_aggregate' = .
    qui scalar `actual_perms_scalar' = .
    if `randomize' == 1 {
        // Part 5a : Compute n_unique_assignments

        // Compute numerator
        qui levelsof silo_name, local(unique_silos)
        local n_silos: word count `unique_silos'
        local ln_num = lnfactorial(`n_silos')

        // Grab all of the gvar assignments and treated silos and compute denominator
        preserve 
            qui keep if treat == 1
            qui bysort silo_name: egen min_gvar= min(gvar_date)
            qui keep if gvar_date == min_gvar
            qui drop min_gvar
            qui contract gvar silo_name

            local gvar_assignments ""
            qui count
             forvalues i = 1/`r(N)' {
                local current_gvar = gvar[`i']
                local gvar_assignments "`gvar_assignments' `current_gvar'"
            }

            // Compute first part of the denominator
            local n_gvar_assignments: word count `gvar_assignments'
            local ln_den = lnfactorial(`n_silos' - `n_gvar_assignments')

            // Compute frequencies of unique gvar values and their factorial contributions
            qui levelsof gvar, local(unique_gvars)
            foreach m in `unique_gvars' {
                qui count if gvar == "`m'"
                local n_m = r(N)
                local ln_den = `ln_den' + lnfactorial(`n_m')
            }
        restore

        // Compute the final permutation result and return scalar
        // Note that this calculation may end up being different from Julia's due to floating point precision... 
        // e.g. for 51 states (10 treated), Julia gives 5795970104231798 while Stata gives 5795970104232000 (difference of less than 0.000000001%)
        local n_unique_assignments = round(exp(`ln_num' - `ln_den'))
        if `nperm' > `n_unique_assignments' {
            di as error "Warning: 'nperm' = `nperm' is greater than the number of unique permutations (`n_unique_assignments'). Setting 'nperm' to `n_unique_assignments'."
            local nperm = `n_unique_assignments'
        }
        if `nperm' < 399 {
            di as error "Warning: 'nperm' is less than 399."
        }

         // Part 5b : Do randomization inference
         // Call the Mata function and capture the results
     
        mata: undid_randomize_treatment(`nperm', `seed', `notyet', `max_attempts', `check_common', "`agg'", "`weights'", `verbose', "`ri_pval_aggregate'", "`actual_perms_scalar'", "`agg_att'", "`table_matrix'")
     }
     else {
        di as error "Warning: Missing some differences required for randomization inference."
     }
 
    // ---------------------------------------------------------------------------------------- //
    // ------------------------- PART FIVE: Return and Display Results ------------------------ // 
    // ---------------------------------------------------------------------------------------- //

    if "`agg'" != "none" {
        di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                     undid: Sub-Aggregate Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "Sub-Aggregate Group       | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		forvalues i = 1/`nrows' {
            local lbl     : word `i' of `sub_agg_label'
            local att = el(`table_matrix',`i',1)
            local se = el(`table_matrix',`i',2)
            local pval = el(`table_matrix',`i',3)
            local jse = el(`table_matrix',`i',4)
            local jpval = el(`table_matrix',`i',5)
            local sub_agg_weight = el(`table_matrix',`i',7)
            local ri_pval = el(`table_matrix',`i',6)
			di as text %-25s "`lbl'" as text " |" as result %-16.7f real("`att'") as text " | " as result  %-7.3f real("`se'") as text "| " as result %-7.3f real("`pval'") as text "| " as result  %-11.3f real("`jse'") as text "| " as result %-13.3f real("`jpval'") as text "|" as result %-9.3f `ri_pval' as text "|"
    
			di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"
            
		}
		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the labels
        matrix rownames `table_matrix' = `sub_agg_label'
        
        // Store the matrix in r()
        return matrix undid = `table_matrix'

		local linesize = c(linesize)
		if `linesize' < 103 {
			di as text "Results table may be squished, try expanding Stata results window."
		}
    }

    di as text _n "------------------------------"
    di as text "   undid: Aggregate Results"
    di as text "------------------------------"
    di as text "Aggregation: `agg'"
    di as text "Weighting: `weights'"
    di as text "Aggregate ATT: " as result `agg_att'
    di as text "Standard error: " as result `agg_att_se'
    di as text "p-value: " as result `agg_att_pval'
    di as text "Jackknife SE: " as result `agg_att_jknife_se'
    di as text "Jackknife p-value: " as result `agg_att_jknife_pval'
    di as text "RI p-value: " as result `ri_pval_aggregate'
    di as text "Permutations: " as result `actual_perms_scalar'

    return scalar att = `agg_att'
    return scalar se = `agg_att_se'
    return scalar p = `agg_att_pval'
    return scalar jkse = `agg_att_jknife_se'
    return scalar jkp = `agg_att_jknife_pval'
    return scalar rip = `ri_pval_aggregate'
    return scalar perms = `actual_perms_scalar'

    qui frame change default


end

// Mata functions for third stage computations:
qui cap mata: mata which undid_stage_three_compute()
if _rc {
mata:
void undid_stage_three_compute(
    real scalar hc,
    string agg,
    string weighting,
    string scalar agg_att,
    string scalar agg_att_se,
    string scalar agg_att_pval,
    string scalar agg_att_jknife_se,
    string scalar agg_att_jknife_pval,
    real scalar common_flag, | string scalar undid_matrix
)
{
    // Get ordering of columns
    if (common_flag == 1) {
        M = st_data(., ("silo_id", "gvar_date", "treat", "n", "n_t", "y"))
        nrows = rows(M)
        treat_col = 3
        n_col = 4
        n_t_col = 5
        y_col = 6
    } 
    else if (agg == "time") {
        M = st_data(., ("silo_id", "gvar_date", "t", "treat", "n", "n_t", "y", "time"))
        nrows = rows(M)
        t_col = 3
        treat_col = 4
        n_col = 5
        n_t_col = 6
        y_col = 7
        time_col = 8
    }
    else {
        if (agg == "gt" | agg == "sgt") {
            M = st_data(., ("silo_id", "gvar_date", "t", "treat", "n", "n_t", "y", agg + "_id"))
        }
        else {
            M = st_data(., ("silo_id", "gvar_date", "t", "treat", "n", "n_t", "y"))
        }
        nrows = rows(M)
        t_col = 3
        treat_col = 4
        n_col = 5
        n_t_col = 6
        y_col = 7
    }
    gvar_col = 2
    silo_col = 1
    last_col = cols(M)

    // Define the iterable based on the aggregation type
    if (agg == "silo") {
        iterable = uniqrows(select(M, M[.,treat_col] :== 1)[.,silo_col])
    }
    else if (agg == "g") {
        iterable = uniqrows(select(M, M[.,treat_col] :== 1)[.,gvar_col])
    }
    else if (agg == "gt") {
        gt_col = last_col
        iterable = uniqrows(select(M, M[.,treat_col] :== 1)[.,gt_col])
    }
    else if (agg == "sgt") {
        sgt_col = last_col
        iterable = uniqrows(select(M, M[.,treat_col] :== 1)[.,sgt_col])
    }
    else if (agg == "time") {
        iterable = uniqrows(select(M, M[.,treat_col] :== 1)[.,time_col])
    }

    // Grab the table for storing subaggregate results
    // And compute aggregate results directly if aggregation is none
    if (agg != "none") {
        sub_agg_results = st_matrix(undid_matrix)
    }
    else if (agg == "none") {
        subset = select(M, M[.,treat_col] :!= -1)
        X = J(rows(subset), 1, 1), subset[., treat_col]
        Y = subset[., y_col]
        W = J(0,0,.)
        if (weighting == "both" | weighting == "diff") {
            W = subset[., n_col]
            W = W :/ sum(W)
        }
        regresults = undid_regress_ols(X, Y, W, hc)
        st_numscalar(agg_att, regresults[1,1])
        st_numscalar(agg_att_se, regresults[2,1])
        st_numscalar(agg_att_pval, regresults[3,1])
        undid_jackknife_procedure(agg_att_jknife_se, agg_att_jknife_pval, subset, agg, weighting, regresults[1,1])
        return
    }

    // Loop thru the iterable and compute subaggregate results
    for (i=1; i<=rows(iterable); i++) {
        subgroup = iterable[i]
        mask = undid_stage_three_mask(agg, M, subgroup)
        subset = select(M, mask)
        X = J(rows(subset), 1, 1), subset[., treat_col]
        Y = subset[., y_col]

        // Add dummies for time since treatment aggregation
        if (agg == "time") {
            X = X, subset[., gvar_col]
            X = design_matrix_time_agg(X, 3)
        }

        // Record weights
        W = J(0,0,.)
        if (weighting == "diff" | weighting == "both") {
            W = subset[., n_col]
            W = W :/ sum(W)
        }
        if (weighting == "att" | weighting == "both") {
            sub_agg_results[i, 7]= sum(select(subset[.,n_t_col], subset[., treat_col] :== 1))
        }

        // Run regression, store results
        regresults = undid_regress_ols(X, Y, W, hc)
        sub_agg_results[i, 1] = regresults[1,1]
        sub_agg_results[i, 2] = regresults[2,1]
        sub_agg_results[i, 3] = regresults[3,1]

    }

    // Decide whether to use weights for aggregate ATT
    W = J(0,0,.)
    if (weighting == "att" | weighting == "both") {
        W = sub_agg_results[., 7]
        W = W :/ sum(W)
        sub_agg_results[., 7] = W
    }

    // Run aggregate regression
    n = rows(sub_agg_results)
    regresults = undid_regress_ols(J(n, 1, 1), sub_agg_results[., 1], W, hc)
    st_numscalar(agg_att, regresults[1,1])
    st_numscalar(agg_att_se, regresults[2,1])
    st_numscalar(agg_att_pval, regresults[3,1])
    sub_agg_results = undid_jackknife_procedure(agg_att_jknife_se, agg_att_jknife_pval, M, agg, weighting, regresults[1,1], sub_agg_results, iterable)
    st_matrix(undid_matrix, sub_agg_results)

}
end
}

qui cap mata: mata which undid_jackknife_procedure()
if _rc {
mata:
real matrix undid_jackknife_procedure(
    string scalar agg_att_jknife_se,
    string scalar agg_att_jknife_pval,
    real matrix data,
    string scalar agg,
    string scalar weighting,
    real scalar agg_att,
    | real matrix sub_agg_results,
    real colvector iterable
)
{
    real scalar silo_col, gvar_col, t_col, treat_col, n_col, n_t_col, y_col
    real scalar time_col, gt_col, sgt_col
    real matrix results
    
    // Define column indexes based on matrix structure
    silo_col = 1
    gvar_col = 2
    
    if (cols(data) == 6) {
        // Common adoption
        treat_col = 3
        n_col = 4
        n_t_col = 5
        y_col = 6
    }
    else if (cols(data) == 8) {
        // staggered, either agg is time, gt, or sgt
        t_col = 3
        treat_col = 4
        n_col = 5
        n_t_col = 6
        y_col = 7
        if (agg == "time") {
            time_col = 8
        }
        else {
            gt_col = 8
            sgt_col = 8
        }
    }
    else if (cols(data) == 7) {
        // standard case without extra columns
        t_col = 3
        treat_col = 4
        n_col = 5
        n_t_col = 6
        y_col = 7
    }

    // Filter out any differences that were only meant for RI procedure
    data = select(data, data[.,treat_col] :!= -1)

    // Get all states, and assign a dummy value to iterable when agg is none
    all_states = uniqrows(data[.,silo_col])
    if (agg == "none") {
        iterable = J(1,1, 1)
    }

    // Make jackdf preallocation matrix
    // Columns: [without, sub_group, att, weights]
    n_states = rows(all_states)
    n_iter = rows(iterable)
    n_jack = n_states * n_iter
    jackdf = J(n_jack, 4, .)
    
    // Fill in without and sub_group columns
    idx = 1
    for (i=1; i<=n_states; i++) {
        for (j=1; j<=n_iter; j++) {
            jackdf[idx, 1] = all_states[i]      // without
            jackdf[idx, 2] = iterable[j]        // sub_group
            idx = idx + 1
        }
    }

    idx_jack = 1
    for (i=1; i<=n_states; i++) {
        without = all_states[i]
        without_mask = data[.,silo_col] :!= without
        for (j=1; j<=n_iter; j++) {
            sg = iterable[j]
            mask = undid_stage_three_mask(agg, data, sg) :& without_mask
            temp = select(data, mask)
            X = temp[.,treat_col]
            Y = temp[., y_col]

            // Record att as missing if temp is blank or or no variation in treatment
            if (rows(temp) == 0 | rows(uniqrows(temp[.,treat_col])) < 2) {
                att = .
            }
            else if (agg == "time") {
                // Handle the time aggregation edge case
                X = J(rows(X), 1, 1), X
                X = X, temp[.,gvar_col]
                X = design_matrix_time_agg(X, 3)

                // Record weights
                if (weighting == "diff" | weighting == "both") {
                    W = temp[.,n_col]
                }
                else if (weighting == "none" | weighting == "att") {
                    W = J(0,0,.)
                }
                time_regress_results = undid_regress_ols(X, Y, W, 0)
                att = time_regress_results[1,1]
            }
            else {
                // Do computation using weighted dot product otherwise
                att = compute_ri_sub_agg_att(temp, treat_col, n_col, y_col, weighting)
            }

            // Record weights
            if (weighting == "att" | weighting == "both") {
                if (att == .) {
                    W_agg = 0
                }
                else {
                    W_agg = sum(select(temp[.,n_t_col], temp[.,treat_col] :== 1))
                }
            }
            else {
                W_agg = .
            }

            // Assign values to jackdf
            jackdf[idx_jack, 3] = att
            jackdf[idx_jack, 4] = W_agg
            idx_jack = idx_jack + 1

        }
    }

    // Use jackknife computations to compute aggregate standard errors and pvals
    agg_jacks = J(n_states, 1, .)
    for (i=1; i<=n_states; i++) {
        without = all_states[i]
        mask = jackdf[.,1] :== without :& jackdf[.,3] :!= .
        temp = select(jackdf, mask)
        if (rows(temp) == 0) {
            agg_jacks[i] = .
        }
        else {
            if (weighting == "att" | weighting == "both") {
                agg_jacks[i] = sum((temp[., 4] :/ sum(temp[., 4])) :* temp[.,3])
            }
            else if (weighting == "diff" | weighting == "none") {
                agg_jacks[i] = mean(temp[.,3])
            }
        }
    }
    agg_jacks = select(agg_jacks, agg_jacks :!= .)
    n = rows(agg_jacks)
    if (n >= 2) {
        jknife_se = sqrt(sum((agg_jacks :- agg_att):^2) * ((n-1) / n))
    }
    else {
        jknife_se = .
    }
    dof_jack = n - 1
    if ((dof_jack > 0) & (jknife_se != .)) {
        pval_jknife = 2 * (1 - t(dof_jack, abs(agg_att / jknife_se)))
    }
    else {
        pval_jknife = .
    }
    st_numscalar(agg_att_jknife_se, jknife_se)
    st_numscalar(agg_att_jknife_pval, pval_jknife)

    // If aggregation was none, at this point we can exit the function
    if (agg == "none") {
        return(J(0,0,.))
    }

    // Use jackknife computations to compute subaggregate standard errors and pvals
    if (agg == "sgt" | agg == "silo") {
        // Note that for sgt or silo aggregation we cannot compute subaggregate jackknife SE or pvals
        return(sub_agg_results)
    }

    // Then for aggregations of g, gt, or time it is possible to compute the subaggregate jackknifes
    for (i=1; i<=n_iter; i++) {
        sg = iterable[i]
        sub_jacks = select(jackdf[.,3], jackdf[.,2] :== sg)
        n_sub = rows(sub_jacks)
        sg_att = sub_agg_results[i, 1]

        if (hasmissing(sub_jacks)) {
            dof_jack_sub = 0
        }
        else {
            dof_jack_sub = n_sub - 1
        }

        if ((n_sub >= 2) & (!hasmissing(sub_jacks))) {
            jknife_se_sub = sqrt(sum((sub_jacks :- sg_att):^2) * ((n_sub-1) / n_sub))
        }
        else {
            jknife_se_sub = .
        }

        if ((dof_jack_sub > 0) & (jknife_se_sub != .)) {
            pval_att_jknife_sub = 2 * (1 - t(dof_jack_sub, abs(sg_att / jknife_se_sub)))
        }
        else {
            pval_att_jknife_sub = .
        }

        sub_agg_results[i,4] = jknife_se_sub
        sub_agg_results[i,5] = pval_att_jknife_sub

    }

    return(sub_agg_results)
    
}
end
}

// Mata functions for randomization inference:
qui cap mata: mata which undid_randomize_treatment()
if _rc {
mata:
void undid_randomize_treatment(
    real scalar nperm,
    real scalar seed,
    real scalar notyet,
    real scalar max_attempts,
    real scalar common_flag,
    string agg,
    string weighting,
    real scalar verbose,
    string scalar ri_pval,
    string scalar n_computed_perms,
    string scalar agg_att, | string scalar undid_matrix
)
{
    real matrix M, original_treated, all_states, treatment_times, results, combined_results, common_staggered
    real scalar i, k, nrows, j, row_idx, state, trt_time, t, n_all_states, n_treat_times, attempts
    real vector shuffled_indices, new_treated_states, new_treated_times, new_treat, treat_indices
    string scalar key
    string vector seen, pairs_str, sorted_pairs
    real matrix assigned_tt
    real scalar found_match, assigned_time

    // Randomimzation Inference Part One: Treatment Assignment
    // Get data from Stata
    original_agg_att = st_numscalar(agg_att)
    if (agg != "none") {
        temp_matrix = st_matrix(undid_matrix)
        original_sub_agg_atts = temp_matrix[.,1]
    }    
    if (common_flag == 1) {
        M = st_data(., ("silo_id", "gvar_date", "treat", "n", "n_t", "y"))
        nrows = rows(M)
        treat_col = 3
        n_col = 4
        n_t_col = 5
        y_col = 6
        col_adj = 6
    } 
    else if (agg == "time") {
        M = st_data(., ("silo_id", "gvar_date", "t", "treat", "n", "n_t", "y", "time"))
        nrows = rows(M)
        t_col = 3
        treat_col = 4
        n_col = 5
        n_t_col = 6
        y_col = 7
        time_col = 8
        col_adj = 8
    }
    else {
        M = st_data(., ("silo_id", "gvar_date", "t", "treat", "n", "n_t", "y"))
        nrows = rows(M)
        t_col = 3
        treat_col = 4
        n_col = 5
        n_t_col = 6
        y_col = 7
        col_adj = 7
    }
    gvar_col = 2
    silo_col = 1
    
    // Initialize results matrix: nrows x nperm
    results = J(nrows, nperm, .)
    
    // Extract unique treated units (where treat == 1)
    original_treated = select(M, M[.,treat_col] :== 1)
    original_treated = uniqrows(original_treated[.,(1,2)])
    original_treated_times = original_treated[., 2]
    original_treated_states = sort(original_treated[., 1],1)
    k = rows(original_treated)

    // Get all unique states and treatment times
    all_states = uniqrows(M[.,1])
    treatment_times = sort(uniqrows(original_treated[.,2]), 1)
    n_all_states = rows(all_states)
    n_treatment_times = rows(treatment_times)

    // Set random seed
    if (seed != 0) {
        rseed(seed)
    }
    
    // Initialize tracking
    i = 1
    seen = J(0, 1, "")
    
    // Create key for original treatment assignment
    pairs_str = J(k, 1, "")
    for (j = 1; j <= k; j++) {
        pairs_str[j] = strofreal(original_treated[j,1]) + "-" + strofreal(original_treated[j,2])
    }
    sorted_pairs = sort(pairs_str, 1)
    key = invtokens(sorted_pairs', "")
    seen = seen \ key
    attempts = 0

    // Randomization assignment loop
    while (i <= nperm & attempts < max_attempts) {
        attempts++

        // Shuffle states and select k of them
        shuffled_indices = jumble(1::n_all_states)
        new_treated_states = all_states[shuffled_indices[1::k]]
        
        // Randomly permute treatment times
        treat_indices = jumble(1::k)
        new_treated_times = original_treated_times[treat_indices]  
        
        // Create key for this permutation
        pairs_str = J(k, 1, "")
        for (j = 1; j <= k; j++) {
            pairs_str[j] = strofreal(new_treated_states[j]) + "-" + strofreal(new_treated_times[j])
        }
        sorted_pairs = sort(pairs_str, 1)
        key = invtokens(sorted_pairs', "")
        
        // Check if we've seen this combination before
        if (rows(seen) > 0 && anyof(seen, key)) {
            continue
        } 
        
        // Add to seen combinations
        seen = seen \ key
        
        // Create assignment matrix
        assigned_tt = new_treated_states, new_treated_times
        
        // Generate new treatment vector
        new_treat = J(nrows, 1, .)
        
        for (row_idx = 1; row_idx <= nrows; row_idx++) {
            state = M[row_idx, 1]
            trt_time = M[row_idx, 2]
            
            // Check if this state is in assigned_tt
            found_match = 0
            assigned_time = .
            for (j = 1; j <= rows(assigned_tt); j++) {
                if (assigned_tt[j,1] == state) {
                    found_match = 1
                    assigned_time = assigned_tt[j,2]
                    break
                }
            }
            
            if (found_match) {
                if (trt_time == assigned_time) {
                    new_treat[row_idx] = 1
                } else {
                    if (notyet & !common_flag) {
                        t = M[row_idx, 3]
                        if (t < assigned_time) {
                            new_treat[row_idx] = 0
                        } else {
                            new_treat[row_idx] = -1
                        }
                    } else {
                        new_treat[row_idx] = -1
                    }
                }
            } else {
                new_treat[row_idx] = 0
            }
        }
        
        // Store this permutation in results matrix
        results[., i] = new_treat
        i++
        attempts=0
    }

    // Store the actual number of permutations in a Stata local
    real scalar actual_perms
    actual_perms = i - 1
    st_numscalar(n_computed_perms, actual_perms)
    // Combine original data with randomized results
    df = M, results[., 1::actual_perms]

    // Randomimzation Inference Part Two: Computation 
    att_ri = J(actual_perms, 1, .)
    if (agg == "g") {
        l = n_treatment_times
        att_ri_g = J(actual_perms, l, .)
        sub_agg_ri_pvals = J(l, 1, .)
        for (j = 1; j <= actual_perms; j++) {
            W = J(l, 1, .)
            for (i = 1; i <= l; i++) {
                trt = treatment_times[i]
                temp = select(df, df[.,j+col_adj] :!= -1 :& df[.,gvar_col] :== trt)
                att_ri_g[j,i] = compute_ri_sub_agg_att(temp, j+col_adj, n_col, y_col, weighting)

                if (weighting == "att" | weighting == "both") {
                    W[i] = sum(select(temp[.,n_t_col], temp[.,j+col_adj] :== 1))
                }
            }

            if (weighting == "att" | weighting == "both") {
                W = W :/ sum(W)
            }
            if (weighting == "diff" | weighting == "none") {
                W = J(l, 1, 1/l)
            }
            att_ri[j] = att_ri_g[j,.] * W
            if (verbose != 0) {
                if (mod(j, verbose) :== 0) {
                    printf("Completed %f of %f permutations! \n", j, actual_perms)
                }
            }
        }
        for (i = 1; i <= l; i++) {
            sub_agg_ri_pvals[i] = (sum(abs(att_ri_g[.,i]) :> abs(original_sub_agg_atts[i]))) / actual_perms
        }
        temp_matrix[.,6] = sub_agg_ri_pvals
        st_matrix(undid_matrix, temp_matrix)
        agg_ri_pval = (sum(abs(att_ri) :> abs(original_agg_att))) / actual_perms
        st_numscalar(ri_pval, agg_ri_pval)
    }
    else if (agg == "silo") {
        l = rows(original_treated_states)
        att_ri_silo = J(actual_perms, l, .)
        sub_agg_ri_pvals = J(l, 1, .)
        for (j = 1; j <= actual_perms; j++) {
            W = J(l, 1, .)
            for (i = 1; i <= l; i++) {
                silo = original_treated_states[i]
                trt = select(original_treated, original_treated[.,1] :== silo)[,2][1]
                temp = select(df, df[.,j+col_adj] :!= -1 :& df[.,gvar_col] :== trt)
                temp_treated_silo = jumble(uniqrows(select(temp, temp[., j+col_adj] :== 1)[.,silo_col]))[1]
                temp = select(temp, temp[.,silo_col] :== temp_treated_silo :| temp[.,j+col_adj] :== 0)
                att_ri_silo[j,i] = compute_ri_sub_agg_att(temp, j+col_adj, n_col, y_col, weighting)

                if (weighting == "att" | weighting == "both") {
                    W[i] = sum(select(temp[.,n_t_col], temp[.,j+col_adj] :== 1))
                }
            }

            if (weighting == "att" | weighting == "both") {
                W = W :/ sum(W)
            }
            if (weighting == "diff" | weighting == "none") {
                W = J(l, 1, 1/l)
            }
            att_ri[j] = att_ri_silo[j,.] * W
            if (verbose != 0) {
                if (mod(j, verbose) :== 0) {
                    printf("Completed %f of %f permutations! \n", j, actual_perms)
                }
            }
        }
        for (i = 1; i <= l; i++) {
            sub_agg_ri_pvals[i] = (sum(abs(att_ri_silo[.,i]) :> abs(original_sub_agg_atts[i]))) / actual_perms
        }
        temp_matrix[.,6] = sub_agg_ri_pvals
        st_matrix(undid_matrix, temp_matrix)
        agg_ri_pval = (sum(abs(att_ri) :> abs(original_agg_att))) / actual_perms
        st_numscalar(ri_pval, agg_ri_pval)
    }
    else if (agg == "gt") {
        unique_diffs = sort(uniqrows(M[.,(gvar_col, t_col)]), (1,2))
        l = rows(unique_diffs)
        att_ri_gt = J(actual_perms, l, .)
        sub_agg_ri_pvals = J(l, 1, .)
        for (j = 1; j <= actual_perms; j++) {
            W = J(l, 1, .)
            for (i = 1; i <= l; i++) {
                t = unique_diffs[i,2]
                gvar = unique_diffs[i,1]
                temp = select(df, df[.,j+col_adj] :!= -1 :& df[.,t_col] :== t :& df[.,gvar_col] :== gvar)
                att_ri_gt[j,i] = compute_ri_sub_agg_att(temp, j+col_adj, n_col, y_col, weighting)

                if (weighting == "att" | weighting == "both") {
                    W[i] = sum(select(temp[.,n_t_col], temp[.,j+col_adj] :== 1))
                }
            }

            if (weighting == "att" | weighting == "both") {
                W = W :/ sum(W)
            }
            if (weighting == "diff" | weighting == "none") {
                W = J(l, 1, 1/l)
            }
            att_ri[j] = att_ri_gt[j,.] * W
            if (verbose != 0) {
                if (mod(j, verbose) :== 0) {
                    printf("Completed %f of %f permutations! \n", j, actual_perms)
                }
            }
        }
        for (i = 1; i <= l; i++) {
            sub_agg_ri_pvals[i] = (sum(abs(att_ri_gt[.,i]) :> abs(original_sub_agg_atts[i]))) / actual_perms
        }
        temp_matrix[.,6] = sub_agg_ri_pvals
        st_matrix(undid_matrix, temp_matrix)
        agg_ri_pval = (sum(abs(att_ri) :> abs(original_agg_att))) / actual_perms
        st_numscalar(ri_pval, agg_ri_pval)
    }
    else if (agg == "sgt") {
        unique_diffs = sort(uniqrows(select(M[.,(silo_col, gvar_col, t_col)], M[.,treat_col] :== 1)), (1,2,3))
        l = rows(unique_diffs)
        att_ri_sgt = J(actual_perms, l, .)
        sub_agg_ri_pvals = J(l, 1, .)
        for (j = 1; j <= actual_perms; j++) {
            W = J(l, 1, .)
            for (i = 1; i <= l; i++) {
                t = unique_diffs[i,3]
                gvar = unique_diffs[i,2]
                temp = select(df, df[.,j+col_adj] :!= -1 :& df[.,t_col] :== t :& df[.,gvar_col] :== gvar)
                temp_treated_silo = jumble(uniqrows(select(temp, temp[., j+col_adj] :== 1)[.,silo_col]))[1]
                temp = select(temp, temp[.,silo_col] :== temp_treated_silo :| temp[.,j+col_adj] :== 0)
                att_ri_sgt[j,i] = compute_ri_sub_agg_att(temp, j+col_adj, n_col, y_col, weighting)

                if (weighting == "att" | weighting == "both") {
                    W[i] = sum(select(temp[.,n_t_col], temp[.,j+col_adj] :== 1))
                }
            }

            if (weighting == "att" | weighting == "both") {
                W = W :/ sum(W)
            }
            if (weighting == "diff" | weighting == "none") {
                W = J(l, 1, 1/l)
            }
            att_ri[j] = att_ri_sgt[j,.] * W
            if (verbose != 0) {
                if (mod(j, verbose) :== 0) {
                    printf("Completed %f of %f permutations! \n", j, actual_perms)
                }
            }
        }
        for (i = 1; i <= l; i++) {
            sub_agg_ri_pvals[i] = (sum(abs(att_ri_sgt[.,i]) :> abs(original_sub_agg_atts[i]))) / actual_perms
        }
        temp_matrix[.,6] = sub_agg_ri_pvals
        st_matrix(undid_matrix, temp_matrix)
        agg_ri_pval = (sum(abs(att_ri) :> abs(original_agg_att))) / actual_perms
        st_numscalar(ri_pval, agg_ri_pval)
    }
    else if (agg == "none") {
        for (j = 1; j <= actual_perms; j++) {
            temp = select(df, df[.,j+col_adj] :!= -1)
            att_ri[j] = compute_ri_sub_agg_att(temp, j+col_adj, n_col, y_col, weighting)
            if (verbose != 0) {
                if (mod(j, verbose) :== 0) {
                    printf("Completed %f of %f permutations! \n", j, actual_perms)
                }
            }
        }
        agg_ri_pval = (sum(abs(att_ri) :> abs(original_agg_att))) / actual_perms
        st_numscalar(ri_pval, agg_ri_pval)
    }
    else if (agg == "time") {
        times = sort(uniqrows(M[.,time_col]),1)
        l = rows(times)
        att_ri_time = J(actual_perms, l, .)
        sub_agg_ri_pvals = J(l, 1, .)
        for (j = 1; j <= actual_perms; j++) {
            W = J(l, 1, .)
            for (i = 1; i <= l; i++) {
                t = times[i]
                temp = select(df, df[.,j+col_adj] :!= -1 :& df[.,time_col] :== t)
                Y = temp[.,y_col]
                X = design_matrix_time_agg((J(rows(temp),1,1),temp[.,(j+col_adj, gvar_col)]), 3)
                if (weighting == "diff" | weighting == "both") {
                    W_diff = temp[.,n_col]
                    W_diff = W_diff :/ sum(W_diff)
                    sq_W_diff = sqrt(W_diff)
                    X = X :* sq_W_diff
                    Y = Y :* sq_W_diff
                }
                beta = luinv(X' * X) * (X' * Y)
                att_ri_time[j,i] = beta[2]
                if (weighting == "att" | weighting == "both") {
                    W[i] = sum(select(temp[.,n_t_col], temp[.,j+col_adj] :== 1))
                }
            }

            if (weighting == "att" | weighting == "both") {
                W = W :/ sum(W)
            }
            if (weighting == "diff" | weighting == "none") {
                W = J(l, 1, 1/l)
            }
            att_ri[j] = att_ri_time[j,.] * W
            if (verbose != 0) {
                if (mod(j, verbose) :== 0) {
                    printf("Completed %f of %f permutations! \n", j, actual_perms)
                }
            }
        }
        for (i = 1; i <= l; i++) {
            sub_agg_ri_pvals[i] = (sum(abs(att_ri_time[.,i]) :> abs(original_sub_agg_atts[i]))) / actual_perms
        }
        temp_matrix[.,6] = sub_agg_ri_pvals
        st_matrix(undid_matrix, temp_matrix)
        agg_ri_pval = (sum(abs(att_ri) :> abs(original_agg_att))) / actual_perms
        st_numscalar(ri_pval, agg_ri_pval)
    }

}
end
}

qui cap mata: mata which compute_ri_sub_agg_att()
if _rc {
mata:
real scalar compute_ri_sub_agg_att(
    real matrix temp,
    real scalar treat_col,
    real scalar n_col,
    real scalar y_col,
    string weighting
)
{
    X = temp[., treat_col]
    Y = temp[., y_col]
    mask_trt = X:==1
    mask_ctrl = X:==0
    // Calculate weighted dot producted or difference of means to avoid having to invert any matrices
    if (weighting == "both" | weighting == "diff") {
        W_diff = temp[., n_col]
        W_diff = W_diff :/ sum(W_diff)
        sub_agg_att = ((select(W_diff, mask_trt)' * select(Y, mask_trt)) / sum(select(W_diff, mask_trt))) - ((select(W_diff, mask_ctrl)' * select(Y, mask_ctrl)) / sum(select(W_diff, mask_ctrl)))
    }
    if (weighting == "none" | weighting == "att") {
        sub_agg_att = mean(select(Y, mask_trt)) - mean(select(Y, mask_ctrl))
    }
    return(sub_agg_att)
}
end
}

qui cap mata: mata which design_matrix_time_agg()
if _rc {
mata:
real matrix design_matrix_time_agg(
    real matrix temp,
    real scalar gvar_col
)
{
    real matrix gvars, D, x
    real scalar i, rank_val, ncolx
    
    // Get unique group values
    gvars = sort(uniqrows(temp[.,gvar_col]), 1)
    
    // Start with base columns (1 and 2)
    x = temp[., (1,2)]
    
    // Add indicator columns for each unique gvar
    for (i=1; i<=rows(gvars); i++) {
        x = (x, (temp[.,gvar_col] :== gvars[i]))
    }
    
    // Check rank and remove columns if needed
    rank_val = rank(x)
    ncolx = cols(x)
    
    // Remove columns from the right while rank < ncol and ncol >= 4
    while ((rank_val < ncolx) & (ncolx >= 4)) {
        // Keep columns 1, 2, and from ncolx down to 4 (removing column 3)
        x = x[., (1, 2, (4..ncolx))]
        ncolx = cols(x)
        rank_val = rank(x)
    }
    
    // If still not full rank, return only first two columns
    if (rank_val < ncolx) {
        x = x[., (1,2)]
    }
    
    return(x)
}
end
}

qui cap mata: mata which undid_compute_hc_covariance()
if _rc {
mata:
real matrix undid_compute_hc_covariance(
    real matrix x,
    real colvector resid,
    real scalar hc
)
{
    real scalar n, k, i, h_bar
    real matrix XXinv, omega, h, delta, omega_diag
    
    n = rows(x)
    k = cols(x)
    
    // Compute (X'X)^-1 using LU decomposition (like solve() in R)
    XXinv = luinv(cross(x, x))
    if (hasmissing(XXinv)) {
        return(J(0, 0, .))
    }
    
    // Compute hat matrix diagonal if needed for HC2/HC3/HC4
    if (hc == 2 | hc == 3 | hc == 4) {
        h = J(n, 1, .)
        for (i=1; i<=n; i++) {
            h[i] = x[i,.] * XXinv * x[i,.]'
        }
    }
    
    // Construct omega based on HC type
    if (hc == 0) {
        omega_diag = resid :^ 2
    }
    else if (hc == 1) {
        omega_diag = (n / (n - k)) :* (resid :^ 2)
    }
    else if (hc == 2) {
        omega_diag = (resid :^ 2) :/ (1 :- h)
    }
    else if (hc == 3) {
        omega_diag = (resid :^ 2) :/ ((1 :- h) :^ 2)
    }
    else if (hc == 4) {
        h_bar = mean(h)
        delta = rowmin((J(n, 1, 4), h :/ h_bar))
        omega_diag = (resid :^ 2) :/ ((1 :- h) :^ delta)
    }
    
    // Sandwich estimator
    return(XXinv * cross(x, omega_diag :* x) * XXinv)
}
end
}

qui cap mata: mata which undid_regress_ols()
if _rc {
mata:
real matrix undid_regress_ols(
    real matrix x,
    real colvector y,
    real matrix w,
    real scalar hc
)
{
    real scalar n, ncolx, extract, dof
    real matrix valid_mask, beta_hat_cov, XXinv
    real colvector beta_hat, resid, resid_w, sw
    real matrix xw
    real colvector yw
    real scalar beta_hat_se, pval
    
    // Check for and remove missing values
    valid_mask = rowmissing(x) :== 0 :& rowmissing(y) :== 0
    if (w != J(0,0,.)) {
        valid_mask = valid_mask :& (rowmissing(w) :== 0)
    }
    
    x = select(x, valid_mask)
    y = select(y, valid_mask)
    if (w != J(0,0,.)) {
        w = select(w, valid_mask)
    }
    
    // Make sure we have enough observations
    n = rows(y)
    ncolx = cols(x)
    if (n < ncolx) {
        return((. \ . \ .))
    }
    
    // Computations without weights
    if (w == J(0,0,.)) {
        XXinv = luinv(cross(x, x))
        if (hasmissing(XXinv)) {
            return((. \ . \ .))
        }
        beta_hat = XXinv * cross(x, y)
        if (n > ncolx) {
            resid = y - (x * beta_hat)
            beta_hat_cov = undid_compute_hc_covariance(x, resid, hc)
        }
    }
    else {
        w = w :/ sum(w)
        sw = sqrt(w)
        xw = x :* sw
        yw = y :* sw
        XXinv = luinv(cross(xw, xw))
        if (hasmissing(XXinv)) {
            return((. \ . \ .))
        }
        beta_hat = XXinv * cross(xw, yw)
        if (n > ncolx) {
            resid_w = yw - (xw * beta_hat)
            beta_hat_cov = undid_compute_hc_covariance(xw, resid_w, hc)
        }
    }
    
    // Extract the appropriate coefficient
    if (ncolx == 1) {
        extract = 1
    }
    else {
        extract = 2
    }
    
    beta_hat = beta_hat[extract]
    
    if ((n > ncolx) && (beta_hat_cov != J(0,0,.))) {
        beta_hat_se = sqrt(diagonal(beta_hat_cov)[extract])
    }
    else {
        beta_hat_se = .
    }
    
    // Get p-value if possible
    dof = n - ncolx
    if (dof > 0 & beta_hat_se != .) {
        pval = 2 * (1 - t(dof, abs(beta_hat / beta_hat_se)))
    }
    else {
        pval = .
    }
    
    return((beta_hat \ beta_hat_se \ pval))
}
end
}

qui cap mata: mata which undid_stage_three_mask()
if _rc {
mata:
real colvector undid_stage_three_mask(
    string scalar agg,
    real matrix M,
    real scalar subgroup
)
{
    real colvector mask, treated_mask, control_mask, sgt_mask
    real scalar gvar_treated, gvar_val, time_val, silo_val
    real scalar silo_col, gvar_col, t_col, treat_col, gt_col, sgt_col, time_col
    
    // Define column indexes based on matrix structure
    silo_col = 1
    gvar_col = 2
    
    if (cols(M) == 6) {
        // Common adoption
        treat_col = 3
    }
    else if (cols(M) == 8) {
        // staggered, either agg is time, gt, or sgt
        t_col = 3
        treat_col = 4
        if (agg == "time") {
            time_col = 8
        }
        else {
            // gt_col or sgt_col is last column
            gt_col = 8
            sgt_col = 8
        }
    }
    else if (cols(M) == 7) {
        // standard case without extra columns
        t_col = 3
        treat_col = 4
    }
    
    if (agg == "silo") {
        treated_mask = (M[.,silo_col] :== subgroup) :& (M[.,treat_col] :== 1)
        gvar_treated = select(M[.,gvar_col], treated_mask)[1]
        control_mask = (M[.,treat_col] :== 0) :& (M[.,gvar_col] :== gvar_treated)
        mask = treated_mask :| control_mask
    }
    else if (agg == "g") {
        mask = (M[.,treat_col] :!= -1) :& (M[.,gvar_col] :== subgroup)
    }
    else if (agg == "gt") {
        mask = (M[.,treat_col] :!= -1) :& (M[.,gt_col] :== subgroup)
    }
    else if (agg == "sgt") {
        sgt_mask = M[.,sgt_col] :== subgroup
        gvar_val = select(M[.,gvar_col], sgt_mask)[1]
        time_val = select(M[.,t_col], sgt_mask)[1]
        silo_val = select(M[.,silo_col], sgt_mask)[1]
        
        mask = (M[.,treat_col] :!= -1) :& 
               (M[.,gvar_col] :== gvar_val) :& 
               (M[.,t_col] :== time_val) :&
               ((M[.,silo_col] :== silo_val) :| (M[.,treat_col] :== 0))
    }
    else if (agg == "time") {
        mask = (M[.,time_col] :== subgroup) :& (M[.,treat_col] :!= -1)
    }
    else if (agg == "none") {
        mask = M[.,treat_col] :!= -1
    }
    
    // Final filter: ensure treat != -1
    mask = mask :& (M[.,treat_col] :!= -1)
    
    return(mask)
}
end
}


/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*2.0.1 - made the HCCME computation more efficient
*2.0.0 - added additional check for RI procedure, disallowed none aggregation for staggered adoption, added HCCME options via the hc arg, fixed issue with jackknife calculation, moved computation to Mata, changed use_pre_controls arg to notyet
*1.0.0 - created function