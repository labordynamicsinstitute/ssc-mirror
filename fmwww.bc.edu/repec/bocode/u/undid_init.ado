/*------------------------------------*/
/*undid_init*/
/*written by Eric Jamieson */
/*version 1.0.0 2025-02-15 */
/*------------------------------------*/
cap program drop undid_init
program define undid_init
    version 16
    syntax , silo_names(string) start_times(string) end_times(string) ///
             treatment_times(string) [covariates(string)] ///
             [filename(string) filepath(string)]

    // Set default filename if not provided
    if "`filename'" == "" {
        local filename "init.csv"
    }
    else if substr("`filename'", -4, .) != ".csv" {
        di as error "Error: Filename must end in .csv"
        exit 8
    }

    // If no filepath given, set to tempdir
    if "`filepath'" == "" {
        local filepath "`c(tmpdir)'"
    }

    // Normalize filepath to always use `/` as the separator
    local filepath_fixed = subinstr("`filepath'", "\", "/", .)
    local fullpath "`filepath_fixed'/`filename'"
    local fullpath = subinstr("`fullpath'", "//", "/", .)
    local fullpath = subinstr("`fullpath'", "//", "/", .)

    // Split input strings into lists
    local nsilo : list sizeof silo_names
    local nstart : list sizeof start_times
    local nend : list sizeof end_times
    local ntreat : list sizeof treatment_times
    
    // Ensure at least two silos
    if (`nsilo' < 2) {
        di as error "Error: UNDID requires at least two silos!"
        exit 3
    }

    // Repeat start_times and end_times if they only have one value
    if (`nstart' == 1) {
        local single_start : word 1 of `start_times'
        local start_times
        forvalues i = 1/`nsilo' {
            local start_times "`start_times' `single_start'"
        }
    }
    if (`nend' == 1) {
        local single_end : word 1 of `end_times'
        local end_times
        forvalues i = 1/`nsilo' {
            local end_times "`end_times' `single_end'"
        }
    }
    local nstart : list sizeof start_times
    local nend : list sizeof end_times

    // Check that at least one treatment_time is "control" and one is not "control"
    local found_control = 0
    local found_treated = 0
    forval i = 1/`ntreat' {
        local current_value = lower(word("`treatment_times'", `i'))
        if "`current_value'" == "control"  {
            local found_control = 1
            continue, break
        }
    }
    if `found_control' == 0 {
        di as error "Error: At least one treatment_time must be 'control'."
        exit 4
    }
    forval i = 1/`ntreat' {
        local current_value = lower(word("`treatment_times'", `i'))
        if "`current_value'" != "control" {
            local found_treated = 1
            continue, break
        }
    }
    if `found_treated' == 0 {
        di as error "Error: At least one treatment_time must be a non 'control' entry."
        exit 5
    }

    // Open a new frame for storing data
    qui tempname init_data
    qui cap frame drop `init_data'
    qui frame create `init_data'
    qui frame change `init_data'

    // Set the number of observations
    qui set obs `nsilo'
    
    // Create variables
    qui gen silo_name = ""
    qui gen start_time = ""
    qui gen end_time = ""
    qui gen treatment_time = ""

    // Populate the data row by row
    forval i = 1/`nsilo' {
        qui replace silo_name = word("`silo_names'", `i') in `i'
        qui replace start_time = word("`start_times'", `i') in `i'
        qui replace end_time = word("`end_times'", `i') in `i'
        qui replace treatment_time = lower(word("`treatment_times'", `i')) in `i'
    }

    // Check that there is just on inputted start_time and end_time 
    qui levelsof start_time, local(unique_vals_start)
    local num_vals_start: word count `unique_vals_start'
    if `num_vals_start' > 1 {
        di as error "Error: More than one unique start_time value found. Please specify a single commont start time for the analysis."
        exit 6
    }
    qui levelsof end_time, local(unique_vals_end)
    local num_vals_end: word count `unique_vals_end'
    if `num_vals_end' > 1 {
        di as error "Error: More than one unique end_time value found. Please specify a single commont end time for the analysis."
        exit 7
    }

    // Handle optional covariates
    if "`covariates'" != "" {
        qui gen covariates = ""

        // Convert covariates into a single semicolon-separated string
        local covariates_combined = subinstr("`covariates'", " ", ";", .)

        // Copy and paste to all rows
        qui replace covariates = "`covariates_combined'"
    }
    
    // Export as CSV
    qui export delimited using "`fullpath'", replace

    // Return to default frame
    frame change default

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