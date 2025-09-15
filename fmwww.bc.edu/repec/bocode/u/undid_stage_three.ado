/*------------------------------------*/
/*undid_stage_three*/
/*written by Eric Jamieson */
/*version 1.0.0 2025-09-14 */
/*------------------------------------*/
cap program drop undid_stage_three
program define undid_stage_three, rclass
    version 16
    syntax, dir_path(string) /// 
            [agg(string) weights(string) covariates(int 0) use_pre_controls(int 0) ///
            nperm(int 1000) verbose(int 0) seed(int 0) max_attempts(int 100) check_anon_size(int 0)]

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
    // Check use_pre_controls
    if !inlist(`use_pre_controls', 0, 1) {
        di as error "Error: use_pre_controls must be set to either 0 (false) or 1 (true)."
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
    else {
        local nperm = `nperm' + 1
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

    // If use_pre_controls is toggled on, rearrange the data as necessary
    if `check_staggered' == 1 {
        qui gen t_str = substr(gt, strpos(gt, ";") + 1, .)
        qui _parse_string_to_date, varname(t_str) date_format("`date_format'") newvar(t) 
        qui _parse_string_to_date, varname(gvar) date_format("`date_format'") newvar(gvar_date) 
    }
    if `check_staggered' == 1 & `use_pre_controls' == 1 {
        qui egen double treated_time_silo = min(cond(treat==1, gvar_date, .)), by(silo_name)
        qui replace treat = 0 if treat == -1 & t < treated_time_silo
        qui drop treated_time_silo
    }

    // Check that at least one treat and untreated diff exist for each sub-agg ATT computation, drop that sub-agg ATT if not
    // Also do some extra processing if agg == "time" then create the time column which indicates periods since treatment
    if `check_staggered' == 1 {
        if "`agg'" == "none" {
            if inlist("`weights'", "att", "both") {
                di as err "Warning: weighting methods 'att' and 'both' are not applicable to aggregation method of 'none' as they apply weights to sub-aggregate ATTs which are not caluclated with 'agg = none'. Overwriting weights to 'diff'."
                local weights "diff"
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

    // After all the pre-processing checks are done, can finally move on to regressions

    // ---------------------------------------------------------------------------------------- //
    // ---------------------------- PART THREE: Compute Results ------------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    // Create a column of ones for the regressions
    qui gen byte const = 1

    // Define some tempnames for scalars for the aggregate levels results 
    qui tempname agg_att 
    qui tempname agg_att_se 
    qui tempname agg_att_jknife_se 
    qui tempname agg_att_pval 
    qui tempname agg_att_jknife_pval
    qui tempname agg_att_tstat
    qui tempname agg_att_tstat_jknife
    qui tempname agg_att_dof
    
    // For storing counts and other scalars
    qui tempname total_n
    qui tempname total_n_t
    qui tempname sub_agg_dof
    qui tempname sub_agg_tstat

    // For edge cases
    qui tempname trt0_var
    qui tempname trt0_weight
    qui tempname trt1_var
    qui tempname trt1_weight

    // Define some locals to store the sub-aggregate level results
    local sub_agg_label ""
    local sub_agg_atts ""
    local sub_agg_atts_se ""
    local sub_agg_atts_pval ""
    local sub_agg_atts_jknife ""
    local sub_agg_atts_jknife_pval ""
    local sub_agg_atts_ri_pval ""
    local sub_agg_weights ""

    if "`agg'" == "none" {
        // Still need to add functionality with common adoption (and its edge case)
        // Basically, should manually calculate the edge case for common adoption
        preserve
        qui keep if treat >= 0
        if "`weights'" == "diff" {
            qui sum n 
            qui scalar `total_n' = r(sum)
            qui gen w = n / `total_n'
            qui gen double sw = sqrt(w)
            qui replace y = y * sw
            qui replace treat = treat * sw
            qui replace const = const * sw
        }
        qui reg y const treat if treat >= 0, noconstant vce(robust)
        qui scalar `agg_att' = _b[treat]
        qui scalar `agg_att_se' = _se[treat]
        qui scalar `agg_att_dof' = e(df_r)
        qui count if treat > 0
        local treated_obs = r(N)
        qui count if treat == 0 
        local control_obs = r(N)
        if `treated_obs' + `control_obs' == 2 { //Only two obs - can't compute standard errors for staggered
            if `check_staggered' == 1 {
                qui scalar `agg_att_se' = .
                qui scalar `agg_att_pval' = .
                qui scalar `agg_att_jknife_se' = .
                qui scalar `agg_att_jknife_pval' = .
            }
            else if `check_common' == 1 {
                // Can manually compute standard error here, but not pval
                qui count if missing(yvar)
                local nmiss = r(N)
                if `nmiss' > 0 {
                    di as error "Warning: Missing values of variance estimate, could not compute the standard error!"
                    local sub_agg_att_se "."
                }
                else {
                    qui summ yvar if treat == 0, meanonly
                    qui scalar `trt0_var' = r(min)
                    qui summ yvar if treat > 0, meanonly
                    qui scalar `trt1_var' = r(min)
                    if "`weights'" == "diff" {
                        qui sum n if treat >= 0 
                        qui scalar `total_n' = r(sum)
                        qui sum n if treat == 0 
                        qui scalar `trt0_weight' = (r(min) / `total_n')^2
                        qui sum n if treat > 0 
                        qui scalar `trt1_weight' = (r(min) / `total_n')^2
                        qui scalar `agg_att_se' = sqrt((`trt1_var' * `trt1_weight' + `trt0_var' * `trt0_weight')/(`trt0_weight' + `trt1_weight'))
                    } 
                    else {
                        qui scalar `agg_att_se' = sqrt(`trt1_var' + `trt0_var')
                    }
                }
                qui scalar `agg_att_pval' = .
                qui scalar `agg_att_jknife_se' = .
                qui scalar `agg_att_jknife_pval' = .
            }
        }
        else if `treated_obs' == 1 | `control_obs' == 1 { // If only one of treated_obs or control_obs, can't compute jackknife
                qui scalar `agg_att_tstat' = `agg_att' / `agg_att_se'
                qui scalar `agg_att_pval' = 2 * ttail(`agg_att_dof', abs(`agg_att_tstat'))
                qui scalar `agg_att_jknife_se' = .
                qui scalar `agg_att_jknife_pval' = .
        }
        else {
            qui scalar `agg_att_tstat' = `agg_att' / `agg_att_se'
            qui scalar `agg_att_pval' = 2 * ttail(`agg_att_dof', abs(`agg_att_tstat'))
            qui reg y const treat if treat >= 0, noconstant vce(jackknife)
            qui scalar `agg_att_dof' = e(N) - 1
            qui scalar `agg_att_jknife_se' = _se[treat]
            qui scalar `agg_att_tstat_jknife' = `agg_att' / `agg_att_jknife_se'
            qui scalar `agg_att_jknife_pval' = 2 * ttail(`agg_att_dof', abs(`agg_att_tstat_jknife'))
        }
        restore
    } 
    else if "`agg'" == "g" {
        qui levelsof gvar_date, local(gvars)
        foreach g of local gvars {
            preserve 
            qui keep if gvar_date == `g' & treat >= 0
            if inlist("`weights'", "diff", "both") {
                qui sum n
                qui scalar `total_n' = r(sum)
                qui gen w = n / `total_n'
                qui gen double sw = sqrt(w)
                qui replace y = y * sw
                qui replace treat = treat * sw
                qui replace const = const * sw
            }

            if inlist("`weights'", "att", "both") {
                qui sum n_t if treat > 0 
                qui scalar `total_n_t' = r(sum)
                local sub_agg_weights "`sub_agg_weights' `=scalar(`total_n_t')'"
            }
            else {
                local sub_agg_weights "`sub_agg_weights' ."
            }
            
            qui reg y const treat if treat >= 0, noconstant vce(robust)
            local sub_agg_att = _b[treat]
            qui scalar `sub_agg_dof' = e(df_r)
            if `sub_agg_dof' > 0 {
                local sub_agg_att_se = _se[treat]
                qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                local sub_agg_att_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
            }
            else {
                local sub_agg_att_se "."
                local sub_agg_att_pval "."
            }
            
            qui count if treat > 0
            local treated_obs = r(N)
            qui count if treat == 0
            local control_obs = r(N)
            if `treated_obs' == 1 | `control_obs' == 1 {
                local sub_agg_att_jknife "."
                local sub_agg_att_jknife_pval "."
            }
            else {
                qui reg y const treat if treat >= 0, noconstant vce(jackknife)
                local sub_agg_att_jknife = _se[treat]
                qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                qui scalar `sub_agg_dof' = e(N) - 1
                local sub_agg_att_jknife_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
            }      

            qui levelsof(gvar), local(g_label)
            local sub_agg_label "`sub_agg_label' `g_label'"
            local sub_agg_atts "`sub_agg_atts' `sub_agg_att'"
            local sub_agg_atts_se "`sub_agg_atts_se' `sub_agg_att_se'"
            local sub_agg_atts_pval "`sub_agg_atts_pval' `sub_agg_att_pval'"
            local sub_agg_atts_jknife "`sub_agg_atts_jknife' `sub_agg_att_jknife'"
            local sub_agg_atts_jknife_pval "`sub_agg_atts_jknife_pval' `sub_agg_att_jknife_pval'"
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
                if inlist("`weights'", "diff", "both") {
                    qui sum n
                    qui scalar `total_n' = r(sum)
                    qui gen w = n / `total_n'
                    qui gen double sw = sqrt(w)
                    qui replace y = y * sw
                    qui replace treat = treat * sw
                    qui replace const = const * sw
                }

                if inlist("`weights'", "att", "both") {
                    qui sum n_t if treat > 0
                    qui scalar `total_n_t' = r(sum)
                    local sub_agg_weights "`sub_agg_weights' `=scalar(`total_n_t')'"
                }
                else {
                    local sub_agg_weights "`sub_agg_weights' ."
                }

                qui reg y const treat if treat >= 0, noconstant vce(robust)
                local sub_agg_att = _b[treat]
                qui scalar `sub_agg_dof' = e(df_r)
                if `sub_agg_dof' > 0 {
                    local sub_agg_att_se = _se[treat]
                    qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                    local sub_agg_att_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
                }
                else {
                    qui count if missing(yvar)
                    local nmiss = r(N)
                    if `nmiss' > 0 {
                        di as error "Warning: Missing values of variance estimate, could not compute the standard error for gt: `gt'"
                        local sub_agg_att_se "."
                    }
                    else {
                        qui summ yvar if treat == 0, meanonly
                        qui scalar `trt0_var' = r(min)
                        qui summ yvar if treat > 0, meanonly
                        qui scalar `trt1_var' = r(min)
                        if inlist("`weights'", "diff", "both") {
                            qui sum n if treat >= 0 
                            qui scalar `total_n' = r(sum)
                            qui sum n if treat == 0 
                            qui scalar `trt0_weight' = (r(min) / `total_n')^2
                            qui sum n if treat > 0 
                            qui scalar `trt1_weight' = (r(min) / `total_n')^2
                            local sub_agg_att_se = sqrt((`trt1_var' * `trt1_weight' + `trt0_var' * `trt0_weight')/(`trt0_weight' + `trt1_weight'))
                        } 
                        else {
                            local sub_agg_att_se = sqrt(`trt1_var' + `trt0_var')
                        }
                    }
                    local sub_agg_att_pval "."
                }

                qui count if treat > 0
                local treated_obs = r(N)
                qui count if treat == 0
                local control_obs = r(N)
                if `treated_obs' == 1 | `control_obs' == 1 {
                        local sub_agg_att_jknife "."
                        local sub_agg_att_jknife_pval "."
                }
                else {
                    qui reg y const treat if treat >= 0, noconstant vce(jackknife)
                    local sub_agg_att_jknife = _se[treat]
                    qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                    qui scalar `sub_agg_dof' = e(N) - 1
                    local sub_agg_att_jknife_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
                }            

                qui levelsof gt if treat > 0, local(gt_label)
                local sub_agg_label "`sub_agg_label' `gt_label'"
                local sub_agg_atts "`sub_agg_atts' `sub_agg_att'"
                local sub_agg_atts_se "`sub_agg_atts_se' `sub_agg_att_se'"
                local sub_agg_atts_pval "`sub_agg_atts_pval' `sub_agg_att_pval'"
                local sub_agg_atts_jknife "`sub_agg_atts_jknife' `sub_agg_att_jknife'"
                local sub_agg_atts_jknife_pval "`sub_agg_atts_jknife_pval' `sub_agg_att_jknife_pval'"
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
            if inlist("`weights'", "diff", "both") {
                qui sum n
                qui scalar `total_n' = r(sum)
                qui gen w = n / `total_n'
                qui gen double sw = sqrt(w)
                qui replace y = y * sw
                qui replace treat = treat * sw
                qui replace const = const * sw
            }

            if inlist("`weights'", "att", "both") {
                qui sum n_t if treat > 0
                qui scalar `total_n_t' = r(sum)
                local sub_agg_weights "`sub_agg_weights' `=scalar(`total_n_t')'"
            }
            else {
                local sub_agg_weights "`sub_agg_weights' ."
            }
            
            qui reg y const treat if treat >= 0, noconstant vce(robust)
            local sub_agg_att = _b[treat]
            qui scalar `sub_agg_dof' = e(df_r)
            if `sub_agg_dof' > 0 {
                local sub_agg_att_se = _se[treat]
                qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                local sub_agg_att_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
            }
            else {
                local sub_agg_att_se "."
                local sub_agg_att_pval "."
            }
            
            qui count if treat > 0
            local treated_obs = r(N)
            qui count if treat == 0
            local control_obs = r(N)
            if `treated_obs' == 1 | `control_obs' == 1 {
                    local sub_agg_att_jknife "."
                    local sub_agg_att_jknife_pval "."
            }
            else {
                qui reg y const treat if treat >= 0, noconstant vce(jackknife)
                local sub_agg_att_jknife = _se[treat]
                qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                qui scalar `sub_agg_dof' = e(N) - 1
                local sub_agg_att_jknife_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
            }          

            qui levelsof(silo_name) if treat > 0, local(s_label)
            local sub_agg_label "`sub_agg_label' `s_label'"
            local sub_agg_atts "`sub_agg_atts' `sub_agg_att'"
            local sub_agg_atts_se "`sub_agg_atts_se' `sub_agg_att_se'"
            local sub_agg_atts_pval "`sub_agg_atts_pval' `sub_agg_att_pval'"
            local sub_agg_atts_jknife "`sub_agg_atts_jknife' `sub_agg_att_jknife'"
            local sub_agg_atts_jknife_pval "`sub_agg_atts_jknife_pval' `sub_agg_att_jknife_pval'"
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
                    if inlist("`weights'", "diff", "both") {
                        qui sum n
                        qui scalar `total_n' = r(sum)
                        qui gen w = n / `total_n'
                        qui gen double sw = sqrt(w)
                        qui replace y = y * sw
                        qui replace treat = treat * sw
                        qui replace const = const * sw
                    }

                    if inlist("`weights'", "att", "both") {
                        qui sum n_t if treat > 0 
                        qui scalar `total_n_t' = r(sum)
                        local sub_agg_weights "`sub_agg_weights' `=scalar(`total_n_t')'"
                    }
                    else {
                        local sub_agg_weights "`sub_agg_weights' ."
                    }

                    qui reg y const treat if treat >= 0, noconstant vce(robust)
                    local sub_agg_att = _b[treat]
                    qui scalar `sub_agg_dof' = e(df_r)
                    if `sub_agg_dof' > 0 {
                        local sub_agg_att_se = _se[treat]
                        qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                        local sub_agg_att_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
                    }
                    else {
                        qui count if missing(yvar)
                        local nmiss = r(N)
                        if `nmiss' > 0 {
                            di as error "Warning: Missing values of variance estimate, could not compute the standard error for gt: `gt'"
                            local sub_agg_att_se "."
                        }
                        else {
                            qui summ yvar if treat == 0, meanonly
                            qui scalar `trt0_var' = r(min)
                            qui summ yvar if treat > 0, meanonly
                            qui scalar `trt1_var' = r(min)
                            if inlist("`weights'", "diff", "both") {
                                qui sum n if treat >= 0 
                                qui scalar `total_n' = r(sum)
                                qui sum n if treat == 0 
                                qui scalar `trt0_weight' = (r(min) / `total_n')^2
                                qui sum n if treat > 0 
                                qui scalar `trt1_weight' = (r(min) / `total_n')^2
                                local sub_agg_att_se = sqrt((`trt1_var' * `trt1_weight' + `trt0_var' * `trt0_weight')/(`trt0_weight' + `trt1_weight'))
                            } 
                            else {
                                local sub_agg_att_se = sqrt(`trt1_var' + `trt0_var')
                            }
                        }
                        local sub_agg_att_pval "."
                    }

                    qui count if treat > 0
                    local treated_obs = r(N)
                    qui count if treat == 0
                    local control_obs = r(N)
                    if `treated_obs' == 1 | `control_obs' == 1 {
                        local sub_agg_att_jknife "."
                        local sub_agg_att_jknife_pval "."
                    }
                    else {
                        qui reg y const treat if treat >= 0, noconstant vce(jackknife)
                        local sub_agg_att_jknife = _se[treat]
                        qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                        qui scalar `sub_agg_dof' = e(N) - 1
                        local sub_agg_att_jknife_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
                    }            
                    qui levelsof silo_name if treat > 0, local(s_label)
                    local clean_s_label : word 1 of `s_label'
                    qui levelsof gt if treat > 0, local(gt_label)
                    local clean_gt_label : word 1 of `gt_label'
                    local sub_agg_label "`sub_agg_label' "`clean_s_label': `clean_gt_label'""
                    local sub_agg_atts "`sub_agg_atts' `sub_agg_att'"
                    local sub_agg_atts_se "`sub_agg_atts_se' `sub_agg_att_se'"
                    local sub_agg_atts_pval "`sub_agg_atts_pval' `sub_agg_att_pval'"
                    local sub_agg_atts_jknife "`sub_agg_atts_jknife' `sub_agg_att_jknife'"
                    local sub_agg_atts_jknife_pval "`sub_agg_atts_jknife_pval' `sub_agg_att_jknife_pval'"
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
            if inlist("`weights'", "diff", "both") {
                qui sum n
                qui scalar `total_n' = r(sum)
                qui gen w = n / `total_n'
                qui gen double sw = sqrt(w)
                qui replace y = y * sw
                qui replace treat = treat * sw
                qui replace const = const * sw
            }

            if inlist("`weights'", "att", "both") {
                qui sum n_t if treat > 0
                qui scalar `total_n_t' = r(sum)
                local sub_agg_weights "`sub_agg_weights' `=scalar(`total_n_t')'"
            }
            else {
                local sub_agg_weights "`sub_agg_weights' ."
            }

            qui count if treat > 0
            local treated_obs = r(N)
            qui count if treat == 0
            local control_obs = r(N)

            qui sum gvar_date, meanonly
            local min_gvar = r(min)
            
            if inlist("`weights'", "diff", "both") {
                qui reg y const treat c.sw#ib`min_gvar'.(gvar_date) if treat >= 0, noconstant vce(robust)
            }
            else {
                qui reg y const treat ib`min_gvar'.(gvar_date) if treat >= 0, noconstant vce(robust)
            }
            
            local sub_agg_att = _b[treat]
            qui scalar `sub_agg_dof' = e(df_r)
            if `sub_agg_dof' > 0 {
                qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                local sub_agg_att_se = _se[treat]
                local sub_agg_att_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
            }
            else {
                local sub_agg_att_se "."
                local sub_agg_att_pval "."
            }

            if `treated_obs' == 1 | `control_obs' == 1 {
                local sub_agg_att_jknife "."
                local sub_agg_att_jknife_pval "."
            }
            else {
                if inlist("`weights'", "diff", "both") {
                    qui reg y const treat c.sw#ib`min_gvar'.(gvar_date) if treat >= 0, noconstant vce(jackknife)
                }
                else {
                    qui reg y const treat ib`min_gvar'.(gvar_date) if treat >= 0, noconstant vce(jackknife)
                }                
                local sub_agg_att_jknife = _se[treat]
                qui scalar `sub_agg_tstat' = _b[treat] / _se[treat]
                qui scalar `sub_agg_dof' = e(N) - 1
                    local sub_agg_att_jknife_pval = 2 * ttail(`sub_agg_dof', abs(`sub_agg_tstat'))
            }            

            local sub_agg_label "`sub_agg_label' `t'"
            local sub_agg_atts "`sub_agg_atts' `sub_agg_att'"
            local sub_agg_atts_se "`sub_agg_atts_se' `sub_agg_att_se'"
            local sub_agg_atts_pval "`sub_agg_atts_pval' `sub_agg_att_pval'"
            local sub_agg_atts_jknife "`sub_agg_atts_jknife' `sub_agg_att_jknife'"
            local sub_agg_atts_jknife_pval "`sub_agg_atts_jknife_pval' `sub_agg_att_jknife_pval'"
            restore
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // ------------------------- PART FOUR: Compute Aggregate Values -------------------------- // 
    // ---------------------------------------------------------------------------------------- //

    if "`agg'" != "none" {

        // Initialize a temporary matrix to store the numeric results
        tempname weight_total
        qui scalar `weight_total' = 0
        tempname table_matrix
        local nrows : word count `sub_agg_label'  
        local num_cols = 7
        qui matrix `table_matrix' = J(`nrows', `num_cols', .)

        forvalues i = 1/`nrows' {
            local lbl     : word `i' of `sub_agg_label'
            local att     : word `i' of `sub_agg_atts'
            local se      : word `i' of `sub_agg_atts_se'
            local pval    : word `i' of `sub_agg_atts_pval'
            local jse     : word `i' of `sub_agg_atts_jknife'
            local jpval   : word `i' of `sub_agg_atts_jknife_pval'
            local sub_agg_weight : word `i' of `sub_agg_weights'

            // Fill the matrix with numeric values, note that randomization inference p-val can't be assigned yet
            matrix `table_matrix'[`i', 1] = real("`att'")
            matrix `table_matrix'[`i', 2] = real("`se'")
            matrix `table_matrix'[`i', 3] = real("`pval'")
            matrix `table_matrix'[`i', 4] = real("`jse'")
            matrix `table_matrix'[`i', 5] = real("`jpval'")
            matrix `table_matrix'[`i', 7]  = .
            
            qui scalar `weight_total' = `weight_total' + `sub_agg_weight'

        }

        if inlist("`weights'", "att", "both") {
            forvalues i = 1/`nrows' {
                local sub_agg_weight : word `i' of `sub_agg_weights'
                matrix `table_matrix'[`i', 7] = `sub_agg_weight' / `weight_total'
            } 
        }

		// Set column names for the matrix
        matrix colnames `table_matrix' = ATT SE pval JKNIFE_SE JKNIFE_pval RI_pval W
        
        // Set row names for the matrix using the labels
        matrix rownames `table_matrix' = `sub_agg_label'

        // Compute aggregate results
        preserve
            clear
            qui svmat double `table_matrix', names(col)
            qui gen byte const = 1
            if inlist("`weights'", "att", "both") {
                qui gen double sw = sqrt(W)
                qui replace ATT = ATT * sw
                qui replace const = const * sw
            }

            // Compute aggregate ATT and robust SE
            if `nrows'  > 1 {
                qui reg ATT const, noconstant vce(robust)
                qui scalar `agg_att' = _b[const]
                qui scalar `agg_att_se' = _se[const]
                qui scalar `agg_att_dof' = e(df_r)
                qui scalar `agg_att_tstat' = `agg_att' / `agg_att_se'
                qui scalar `agg_att_pval' = 2 * ttail(`agg_att_dof', abs(`agg_att_tstat'))
            }
            else {
                qui scalar `agg_att' = ATT
                qui scalar `agg_att_se' = .
                qui scalar `agg_att_pval' = .
            }

            // Compute jackknife SE
            if `nrows' > 2 {
                qui reg ATT const, noconstant vce(jackknife)
                qui scalar `agg_att_jknife_se' = _se[const]
                qui scalar `agg_att_tstat_jknife' = `agg_att' / `agg_att_jknife_se'
                qui scalar `agg_att_jknife_pval' = 2 * ttail(`agg_att_dof', abs(`agg_att_tstat_jknife'))
            }
            else if `nrows' == 2 { // Manually compute since vce(jackknife) fails for n = 2
                qui scalar `agg_att_jknife_se' = sqrt( ((2-1)/2) * ((ATT[1] - `agg_att')^2 + (ATT[2] - `agg_att')^2))
                qui scalar `agg_att_tstat_jknife' = `agg_att' / `agg_att_jknife_se'
                qui scalar `agg_att_jknife_pval' = 2 * ttail(`agg_att_dof', abs(`agg_att_tstat_jknife'))
            }
            else {
                qui scalar `agg_att_jknife_se' = .
                qui scalar `agg_att_jknife_pval' = .
            }
        restore
        
    }

    // ---------------------------------------------------------------------------------------- //
    // ------------------------- PART FIVE: Randomization Inference! -------------------------- // 
    // ---------------------------------------------------------------------------------------- //

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
        di as error "'nperm' = `nperm' is greater than the number of unique permutations (`n_unique_assignments'). Setting 'nperm' to `n_unique_assignments'."
        local nperm = `n_unique_assignments'
    }

     // Part 5b : Do randomization inference
     qui tempname ri_pval_aggregate
     qui tempname actual_perms_scalar
     qui scalar `ri_pval_aggregate' = .
     qui scalar `actual_perms_scalar' = .

     // Call the Mata function and capture the results
     mata: undid_randomize_treatment(`nperm', `seed', `use_pre_controls', `max_attempts', `check_common', "`agg'", "`weights'", `verbose', "`ri_pval_aggregate'", "`actual_perms_scalar'", "`agg_att'", "`table_matrix'")
 
    // ---------------------------------------------------------------------------------------- //
    // -------------------------- PART SIX: Return and Display Results ------------------------ // 
    // ---------------------------------------------------------------------------------------- //

    if "`agg'" != "none" {
        di as text "-----------------------------------------------------------------------------------------------------"
		di as text "                                     undid: Sub-Aggregate Results                    "
		di as text "-----------------------------------------------------------------------------------------------------"
		di as text "Sub-Aggregate Group       | " as text "ATT             | SE     | p-val  | JKNIFE SE  | JKNIFE p-val | RI p-val"
		di as text "--------------------------|-----------------|--------|--------|------------|--------------|---------|"  
		
		forvalues i = 1/`nrows' {
            local lbl     : word `i' of `sub_agg_label'
            local att     : word `i' of `sub_agg_atts'
            local se      : word `i' of `sub_agg_atts_se'
            local pval    : word `i' of `sub_agg_atts_pval'
            local jse     : word `i' of `sub_agg_atts_jknife'
            local jpval   : word `i' of `sub_agg_atts_jknife_pval'
            local sub_agg_weight : word `i' of `sub_agg_weights'
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

// Mata functions for randomization inference:
qui cap mata: mata which undid_randomize_treatment()
if _rc {
mata:
void undid_randomize_treatment(
    real scalar nperm,
    real scalar seed,
    real scalar use_pre_controls,
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
    results = J(nrows, nperm-1, .)
    
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
    while (i < nperm & attempts < max_attempts) {
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
                    if (use_pre_controls & !common_flag) {
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
                beta = invsym(X' * X) * (X' * Y)
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
    gvars = sort(uniqrows(temp[.,gvar_col]),1)
    if (rows(gvars) == 1) {
        return(temp[.,(1,2)])
    }
    
    D = J(rows(temp), rows(gvars)-1, .)
    for (i=2; i<=rows(gvars); i++) {
        D[.,i-1] = (temp[.,gvar_col] :== gvars[i])
    }
    return((temp[.,(1,2)], D))

}
end
}


/*--------------------------------------*/
/* Change Log */
/*--------------------------------------*/
*1.0.0 - created function