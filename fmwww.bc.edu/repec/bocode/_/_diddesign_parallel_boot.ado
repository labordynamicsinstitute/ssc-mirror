*! _diddesign_parallel_boot.ado - Parallel bootstrap coordinator
*!
*! Coordinates parallel bootstrap execution for both standard DID and SA designs.
*! Handles dependency detection, worker allocation, data distribution, and result aggregation.

version 16.0

program define _diddesign_parallel_boot, rclass
    syntax,                          ///
        OUTCOME(varname)             ///
        TREATMENT(varname)           ///
        [ ID(varname) ]              ///
        [ TIME(varname) ]            ///
        [ POST(varname) ]            ///
        [ CLuster(varname) ]         ///
        [ COVariates(varlist) ]      ///
        NBOOT(integer)               ///
        LEAD(numlist)                ///
        [ THRES(integer 2) ]         ///
        LEVEL(real)                  ///
        [ SEED(integer -1) ]         ///
        DESIGN(string)               ///
        TOUSE(varname)               ///
        [ ISPANEL(integer 1) ]       ///
        [ SEBOOT(integer 0) ]        ///
        [ QUIET ]

    local dataidtimevar "$DIDDESIGN_PAR_IDTIMEVAR"
    local dataidtimestdvar "$DIDDESIGN_PAR_IDTIMESTDVAR"
    local datagivar "$DIDDESIGN_PAR_GIVAR"
    local dataitvar "$DIDDESIGN_PAR_ITVAR"
    local datadeltavar "$DIDDESIGN_PAR_DELTAVAR"
    local nobs "$DIDDESIGN_PAR_NOBS"
    local nunits "$DIDDESIGN_PAR_NUNITS"
    local nperiods "$DIDDESIGN_PAR_NPERIODS"
    local treatyear "$DIDDESIGN_PAR_TREATYEAR"

    if "`nobs'" == "" local nobs = .
    if "`nunits'" == "" local nunits = .
    if "`nperiods'" == "" local nperiods = .
    if "`treatyear'" == "" local treatyear = .

    // =========================================================================
    // Step 1: Detect and (if needed) install parallel package
    // =========================================================================
    capture which parallel
    if _rc != 0 {
        display as text "Note: Installing -parallel- package from SSC (one-time setup)..."
        capture noisily ssc install parallel, replace
        local install_rc = _rc

        if `install_rc' != 0 {
            // Installation failed -> degrade to sequential (W_PAR01)
            display as text "Warning (W_PAR01): Could not install -parallel- from SSC."
            display as text "  Bootstrap will run sequentially this time."
            display as text "  To install manually: . ssc install parallel, replace"
            return scalar parallel_used = 0
            exit
        }

        // Installation succeeded -> re-verify
        capture which parallel
        if _rc != 0 {
            display as text "Warning (W_PAR01): parallel installed but not found in adopath."
            return scalar parallel_used = 0
            exit
        }
        display as text "Note: -parallel- installed successfully."
    }

    // =========================================================================
    // Step 2: Determine worker count
    // =========================================================================
    // Priority 1: User-specified global DIDDESIGN_NCORES
    // Priority 2 is approximated via c(processors_mach) because the SSC
    // parallel package version commonly installed with Stata 16/18 does not
    // expose a stable numprocessors subcommand.
    local ncores = .
    if "$DIDDESIGN_NCORES" != "" {
        local ncores = $DIDDESIGN_NCORES
    }
    else {
        local ncores = cond(`=c(processors)' > 2, `=c(processors) - 1', `=c(processors)')
    }

    // Clamp to valid range
    if `ncores' < 2 {
        display as text "Note: Fewer than 2 cores available; using sequential bootstrap."
        return scalar parallel_used = 0
        exit
    }

    local nworkers = min(`ncores', `nboot')
    if `nworkers' < 2 {
        display as text "Note: nboot(`nboot') < 2; using sequential bootstrap."
        return scalar parallel_used = 0
        exit
    }

    // =========================================================================
    // Step 3: Compute iteration allocation (FR-05 formula)
    // =========================================================================
    local chunk_size_base = floor(`nboot' / `nworkers')
    local n_extra = mod(`nboot', `nworkers')

    // Compute b_start_k, b_end_k, seed_k for each worker
    forvalues k = 1/`nworkers' {
        local prev_total = (`k' - 1) * `chunk_size_base' + min(`k' - 1, `n_extra')
        local b_start_`k' = `prev_total' + 1

        if `k' <= `n_extra' {
            local chunk_size_k = `chunk_size_base' + 1
        }
        else {
            local chunk_size_k = `chunk_size_base'
        }
        local b_end_`k' = `b_start_`k'' + `chunk_size_k' - 1

        // Derive seed for this worker (FR-06)
        if `seed' != -1 {
            local seed_k_val = `seed' + `k' * 9973
            // Handle overflow: mod by 2^31 - 1
            if `seed_k_val' > 2147483647 {
                local seed_k_val = mod(`seed_k_val', 2147483647)
            }
            local seed_`k' = `seed_k_val'
        }
        else {
            local seed_`k' = .
        }
    }

    // =========================================================================
    // Step 4: Create shared temporary directory for worker outputs
    // =========================================================================
    tempfile tmpdir_base
    local tmpdir "`tmpdir_base'_ddpar"
    capture mkdir "`tmpdir'"
    if _rc != 0 {
        // Fallback: use simpler temp path
        local tmpdir = "`c(tmpdir)'/diddesign_par_`=c(current_time)'"
        capture mkdir "`tmpdir'"
        if _rc != 0 {
            display as error "Failed to create temporary directory for parallel bootstrap"
            return scalar parallel_used = 0
            exit
        }
    }

    // =========================================================================
    // Step 5a: Save current data (touse subset) for workers
    // =========================================================================
    preserve
    quietly keep if `touse'
    capture drop __ddpar_touse
    quietly gen byte __ddpar_touse = 1
    tempfile data_for_workers
    qui save "`data_for_workers'", replace

    // =========================================================================
    // Step 5b: Create auxiliary dispatch dataset (one row per worker)
    // =========================================================================
    tempfile dispatch_data
    tempname postfh
    postfile `postfh' long(_ddpar_worker_id _ddpar_bstart _ddpar_bend) ///
        double(_ddpar_seed) using "`dispatch_data'"
    forvalues k = 1/`nworkers' {
        post `postfh' (`k') (`b_start_`k'') (`b_end_`k'') (`seed_`k'')
    }
    postclose `postfh'

    // =========================================================================
    // Step 5c: Set global macros for worker access
    // =========================================================================
    global DDPAR_DATA         "`data_for_workers'"
    global DDPAR_OUTCOME      "`outcome'"
    global DDPAR_TREATMENT    "`treatment'"
    global DDPAR_ID           "`id'"
    global DDPAR_TIME         "`time'"
    global DDPAR_POST         "`post'"
    global DDPAR_CLUSTER      "`cluster'"
    global DDPAR_COVARIATES   "`covariates'"
    global DDPAR_EXPANDED_COVARIATES "`covariates'"  // Assume already expanded
    global DDPAR_LEAD         "`lead'"
    global DDPAR_THRES        "`thres'"
    global DDPAR_LEVEL        "`level'"
    global DDPAR_DESIGN       "`design'"
    global DDPAR_ISPANEL      "`ispanel'"
    global DDPAR_SEBOOT       "`seboot'"
    global DDPAR_TMPDIR       "`tmpdir'"
    global DDPAR_TOUSEVAR     "__ddpar_touse"
    global DDPAR_NBOOT        "`nboot'"
    global DDPAR_NOBS         "`nobs'"
    global DDPAR_NUNITS       "`nunits'"
    global DDPAR_NPERIODS     "`nperiods'"
    global DDPAR_QUIET        "`=cond("`quiet'" != "", 1, 0)'"

    // Derived variable names for worker data reconstruction (standard DID).
    global DDPAR_GIVAR        "`datagivar'"
    global DDPAR_ITVAR        "`dataitvar'"
    global DDPAR_IDTIMESTDVAR "`dataidtimestdvar'"
    global DDPAR_DELTAVAR     "`datadeltavar'"
    global DDPAR_IDTIMEVAR    "`dataidtimevar'"
    global DDPAR_TREATYEAR    "`treatyear'"

    // Locate Mata library via findfile
    qui findfile diddesign_mata.do
    global DDPAR_MATALIB      "`r(fn)'"

    // =========================================================================
    // Step 6: Launch parallel execution
    // =========================================================================
    qui use "`dispatch_data'", clear
    sort _ddpar_worker_id

    // Locate worker file
    qui findfile _diddesign_parallel_worker.ado
    local worker_file "`r(fn)'"

    capture noisily parallel setclusters `nworkers', force
    local init_rc = _rc
    if `init_rc' != 0 {
        restore
        display as text "Warning (W_PAR02): parallel setclusters failed (rc=`init_rc'). Bootstrap will run sequentially."
        _dd_parallel_cleanup, tmpdir("`tmpdir'") nworkers(`nworkers')
        capture macro drop DDPAR_DATA DDPAR_OUTCOME DDPAR_TREATMENT DDPAR_ID ///
            DDPAR_TIME DDPAR_POST DDPAR_CLUSTER DDPAR_COVARIATES ///
            DDPAR_EXPANDED_COVARIATES DDPAR_LEAD DDPAR_THRES DDPAR_LEVEL ///
            DDPAR_DESIGN DDPAR_ISPANEL DDPAR_SEBOOT DDPAR_TMPDIR ///
            DDPAR_TOUSEVAR DDPAR_NBOOT DDPAR_NOBS DDPAR_NUNITS ///
            DDPAR_NPERIODS DDPAR_QUIET DDPAR_GIVAR DDPAR_ITVAR ///
            DDPAR_IDTIMESTDVAR DDPAR_DELTAVAR DDPAR_IDTIMEVAR ///
            DDPAR_TREATYEAR DDPAR_MATALIB
        capture macro drop DIDDESIGN_PAR_IDTIMEVAR DIDDESIGN_PAR_IDTIMESTDVAR ///
            DIDDESIGN_PAR_GIVAR DIDDESIGN_PAR_ITVAR DIDDESIGN_PAR_DELTAVAR ///
            DIDDESIGN_PAR_NOBS DIDDESIGN_PAR_NUNITS DIDDESIGN_PAR_NPERIODS ///
            DIDDESIGN_PAR_TREATYEAR
        return scalar parallel_used = 0
        return scalar n_workers = 0
        exit
    }

    capture noisily parallel, by(_ddpar_worker_id): do "`worker_file'"
    local par_rc = _rc

    // =========================================================================
    // Step 7: Aggregate results, then restore original data
    // =========================================================================
    // IMPORTANT: Aggregation (Pass 1 + Pass 2) must happen BEFORE restore,
    // because `use...clear` in the passes would destroy the restored dataset.
    // The preserve from Step 5a is still active here.

    if `par_rc' != 0 {
        // Parallel execution failed — restore first, then clean up
        restore
        display as error "Parallel execution failed with rc = `par_rc'"
        _dd_parallel_cleanup, tmpdir("`tmpdir'") nworkers(`nworkers')
        capture macro drop DDPAR_DATA DDPAR_OUTCOME DDPAR_TREATMENT DDPAR_ID ///
            DDPAR_TIME DDPAR_POST DDPAR_CLUSTER DDPAR_COVARIATES ///
            DDPAR_EXPANDED_COVARIATES DDPAR_LEAD DDPAR_THRES DDPAR_LEVEL ///
            DDPAR_DESIGN DDPAR_ISPANEL DDPAR_SEBOOT DDPAR_TMPDIR ///
            DDPAR_TOUSEVAR DDPAR_NBOOT DDPAR_NOBS DDPAR_NUNITS ///
            DDPAR_NPERIODS DDPAR_QUIET DDPAR_GIVAR DDPAR_ITVAR ///
            DDPAR_IDTIMESTDVAR DDPAR_DELTAVAR DDPAR_IDTIMEVAR ///
            DDPAR_TREATYEAR DDPAR_MATALIB
        capture macro drop DIDDESIGN_PAR_IDTIMEVAR DIDDESIGN_PAR_IDTIMESTDVAR ///
            DIDDESIGN_PAR_GIVAR DIDDESIGN_PAR_ITVAR DIDDESIGN_PAR_DELTAVAR ///
            DIDDESIGN_PAR_NOBS DIDDESIGN_PAR_NUNITS DIDDESIGN_PAR_NPERIODS ///
            DIDDESIGN_PAR_TREATYEAR
        return scalar parallel_used = 0
        exit `par_rc'
    }

    // Aggregate worker output files using two passes to correctly handle both
    // the n_failed count and the sequential append.
    // Both passes run while the original dataset is still preserved (from Step 5a).
    local boot_combined "`tmpdir'/boot_combined.dta"
    local total_n_success = 0
    local total_n_failed = 0

    // Pass 1: Collect per-worker n_failed and record file availability.
    forvalues k = 1/`nworkers' {
        local wfile_`k' = "`tmpdir'/boot_chunk_`k'.dta"
        capture confirm file "`wfile_`k''"
        local wfile_ok_`k' = (_rc == 0)
        if `wfile_ok_`k'' {
            // Load each file individually so r(max) reflects only this worker.
            quietly use "`wfile_`k''", clear
            capture confirm variable _ddpar_n_failed
            if _rc == 0 {
                quietly summarize _ddpar_n_failed
                // Every row in a worker file stores the same n_failed scalar.
                local total_n_failed = `total_n_failed' + r(max)
            }
        }
        else {
            display as text "Warning (W_PAR03): Worker `k' output missing"
        }
    }

    // Pass 2: Build combined file by sequential append.
    local first_append = 1

    forvalues k = 1/`nworkers' {
        if `wfile_ok_`k'' {
            if `first_append' {
                qui use "`wfile_`k''", clear
                local first_append = 0
            }
            else {
                qui append using "`wfile_`k''"
            }
        }
    }

    if `first_append' == 0 {
        quietly count if _ddpar_is_result == 1
        local total_n_success = r(N)
        keep if _ddpar_is_result == 1
        drop _ddpar_is_result _ddpar_n_failed
        qui save "`boot_combined'", replace emptyok
    }
    else {
        local total_n_success = 0
    }

    // NOW restore the original dataset (from Step 5a preserve)
    restore

    // =========================================================================
    // Step 8: Clean up worker chunk files (keep boot_combined for caller)
    // =========================================================================
    _dd_parallel_cleanup, tmpdir("`tmpdir'") nworkers(`nworkers')
    capture macro drop DDPAR_DATA DDPAR_OUTCOME DDPAR_TREATMENT DDPAR_ID ///
        DDPAR_TIME DDPAR_POST DDPAR_CLUSTER DDPAR_COVARIATES ///
        DDPAR_EXPANDED_COVARIATES DDPAR_LEAD DDPAR_THRES DDPAR_LEVEL ///
        DDPAR_DESIGN DDPAR_ISPANEL DDPAR_SEBOOT DDPAR_TMPDIR ///
        DDPAR_TOUSEVAR DDPAR_NBOOT DDPAR_NOBS DDPAR_NUNITS ///
        DDPAR_NPERIODS DDPAR_QUIET DDPAR_GIVAR DDPAR_ITVAR ///
        DDPAR_IDTIMESTDVAR DDPAR_DELTAVAR DDPAR_IDTIMEVAR ///
        DDPAR_TREATYEAR DDPAR_MATALIB
    capture macro drop DIDDESIGN_PAR_IDTIMEVAR DIDDESIGN_PAR_IDTIMESTDVAR ///
        DIDDESIGN_PAR_GIVAR DIDDESIGN_PAR_ITVAR DIDDESIGN_PAR_DELTAVAR ///
        DIDDESIGN_PAR_NOBS DIDDESIGN_PAR_NUNITS DIDDESIGN_PAR_NPERIODS ///
        DIDDESIGN_PAR_TREATYEAR

    // =========================================================================
    // Return results
    // =========================================================================
    return scalar parallel_used    = 1
    return scalar n_workers        = `nworkers'
    return scalar n_boot_attempted = `nboot'
    return scalar n_boot_success   = `total_n_success'
    return scalar n_boot_failed    = `total_n_failed'
    return local  boot_combined    "`boot_combined'"
    return local  boot_tmpdir      "`tmpdir'"
end

// =============================================================================
// Helper: Cleanup temporary files
// =============================================================================
program define _dd_parallel_cleanup
    syntax, tmpdir(string) nworkers(integer)

    forvalues k = 1/`nworkers' {
        capture erase "`tmpdir'/boot_chunk_`k'.dta"
    }
    // Note: boot_combined.dta may still be present; caller is responsible
    // for erasing it and then calling rmdir on the empty directory.
end
