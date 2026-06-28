*! _diddesign_prep.ado - Data preparation for DID estimation
*!
*! Prepares panel data or repeated cross-sectional data for difference-in-
*! differences estimation. Implements time normalization, group indicator
*! construction, and lagged outcome transformation for the double DID estimator.

version 16.0

program define _diddesign_prep, rclass
    
    // =========================================================================
    // SECTION 1: INPUT PARAMETERS
    // =========================================================================
    
    syntax, ///
        OUTCOME(varname)        /// Outcome variable
        TREATment(varname)      /// Treatment indicator
        TIME(varname)           /// Time variable
        [ID(varname)]           /// Unit ID (panel only)
        [POST(varname)]         /// Post indicator (RCS only)
        [CLuster(varname)]      /// Cluster variable
        [COVariates(varlist)]   /// Covariates (already expanded by caller)
        [TOUSE(varname)]        /// Sample marker
        [IDTIMEVAR(name)]       /// Internal id_time variable name
        [IDTIMESTDVAR(name)]    /// Internal standardized time variable name
        [GIVAR(name)]           /// Internal Gi variable name
        [ITVAR(name)]           /// Internal It variable name
        [DELTAVAR(name)]        /// Internal outcome_delta variable name
        [PANEL]                 /// Panel data flag
        [RCS]                   /// RCS data flag
    
    // Determine data type
    local is_panel = ("`panel'" != "")
    local is_rcs = ("`rcs'" != "")
    
    // Default to panel if neither specified but id is provided
    if !`is_panel' & !`is_rcs' {
        if "`id'" != "" {
            local is_panel = 1
        }
        else {
            display as error "E003: Must specify panel or rcs data type"
            exit 198
        }
    }

    if "`idtimevar'" == "" local idtimevar "_did_id_time"
    if "`idtimestdvar'" == "" local idtimestdvar "_did_id_time_std"
    if "`givar'" == "" local givar "_did_Gi"
    if "`itvar'" == "" local itvar "_did_It"
    if "`deltavar'" == "" local deltavar "_did_outcome_delta"
    
    // =========================================================================
    // SECTION 2: DATA VALIDATION
    // =========================================================================
    // Validates data structure requirements for DID estimation:
    // - Binary treatment indicator (0/1)
    // - Presence of both treatment and control observations
    // - For RCS: binary post-treatment indicator
    
    // Initialize sample marker if not provided
    if "`touse'" == "" {
        tempvar touse
        gen byte `touse' = 1
    }

    // Preserve the caller's row order so panel bysort/egen steps do not
    // leak id-label-sensitive ordering into downstream bootstrap frames.
    tempvar did_obs_order
    quietly gen long `did_obs_order' = _n if `touse'
    
    // Count observations
    quietly count if `touse'
    local N = r(N)
    if `N' == 0 {
        display as error "E003: No observations in sample"
        exit 2000
    }

    // Tiny float outcomes are already quantized before Mata sees the data.
    // Reject them here so storage-type-dependent ATT / VCOV results do not
    // silently propagate through the standard DID pipeline.
    capture confirm float variable `outcome'
    if _rc == 0 {
        quietly summarize `outcome' if `touse' & !missing(`outcome'), meanonly
        if r(N) > 0 {
            local outcome_abs_max = max(abs(r(min)), abs(r(max)))
            // Moderate float outcomes remain stable at much larger scales, but
            // values below this cutoff are small enough to make ATT depend on
            // float versus double storage after repeated centering/differencing.
            local float_tiny_cutoff = 1e-10
            if `outcome_abs_max' > 0 & `outcome_abs_max' <= `float_tiny_cutoff' {
                local outcome_abs_max_txt : display %21.15g `outcome_abs_max'
                local float_tiny_cutoff_txt : display %21.15g `float_tiny_cutoff'
                display as error "E003: Outcome variable `outcome' is stored as float at an unsupported tiny scale"
                display as error "      Recast `outcome' to double before estimation"
                display as error "      max(abs(`outcome')) = `outcome_abs_max_txt' is <= `float_tiny_cutoff_txt'"
                exit 198
            }
        }
    }
    
    // Canonicalize treatment to exact 0/1 before downstream preparation.
    tempvar treatment_work
    quietly gen double `treatment_work' = . if `touse'
    quietly replace `treatment_work' = 0 if abs(`treatment') < 1e-6 & `touse'
    quietly replace `treatment_work' = 1 if abs(`treatment' - 1) < 1e-6 & `touse'

    quietly count if missing(`treatment_work') & `touse'
    if r(N) > 0 {
        display as error "E003: Treatment variable must be binary (0/1)"
        display as error "      Found `r(N)' observations outside the 1e-6 tolerance around 0/1"
        exit 198
    }

    // Check for treated observations (preliminary)
    // Definitive check is performed after Gi computation for panel data
    quietly count if `treatment_work' == 1 & `touse'
    if r(N) == 0 {
        display as error "E003: No treated units found in data"
        exit 198
    }
    
    // Check for control observations (preliminary)
    // Definitive check is performed after Gi computation for panel data
    quietly count if `treatment_work' == 0 & `touse'
    if r(N) == 0 {
        display as error "E003: No control units found in data"
        exit 198
    }

    local treatment "`treatment_work'"
    
    // For RCS: validate post indicator is binary
    if `is_rcs' {
        quietly summarize `post' if `touse'
        
        // Handle all-missing post variable
        if r(N) == 0 | missing(r(min)) | missing(r(max)) {
            display as error "E003: Post-treatment indicator contains only missing values"
            exit 198
        }
        
        tempvar post_work
        quietly gen double `post_work' = . if `touse'
        quietly replace `post_work' = 0 if abs(`post') < 1e-6 & `touse'
        quietly replace `post_work' = 1 if abs(`post' - 1) < 1e-6 & `touse'

        quietly count if missing(`post_work') & `touse'
        if r(N) > 0 {
            display as error "E003: Post-treatment indicator must be binary (0/1)"
            display as error "      Found `r(N)' observations outside the 1e-6 tolerance around 0/1"
            exit 198
        }

        quietly tab `post_work' if `touse'
        if r(r) > 2 {
            display as error "E003: Post-treatment indicator must be binary (0/1)"
            display as error "       Found " r(r) " distinct values after tolerance canonicalization (expected 2)"
            exit 198
        }

        quietly summarize `post_work' if `touse'
        local post_min_round = r(min)
        local post_max_round = r(max)
        
        // Ensure both pre- and post-treatment observations exist
        if r(min) == r(max) {
            if `post_min_round' == 0 {
                display as error "E003: Post-treatment indicator is all 0 (no post-treatment observations)"
            }
            else {
                display as error "E003: Post-treatment indicator is all 1 (no pre-treatment observations)"
            }
            exit 198
        }

        local post "`post_work'"
    }

    // =========================================================================
    // SECTION 3: PANEL DATA PREPARATION
    // =========================================================================
    // Prepares panel data by:
    // 1. Converting time variable to consecutive integers
    // 2. Identifying treatment time (first period where treatment == 1)
    // 3. Creating group indicator Gi (1 if unit ever treated)
    // 4. Creating post-treatment indicator It
    // 5. Creating standardized time index (centered at treatment time)
    
    if `is_panel' {

        // Panel DID requires each unit-time cell to appear at most once in
        // the estimation sample. Duplicate cells would otherwise distort the
        // prepared design matrix and bootstrap logic.
        tempvar did_dup_cell
        quietly bysort `id' `time': gen byte `did_dup_cell' = (_N > 1) if `touse'
        quietly count if `did_dup_cell' == 1 & `touse'
        if r(N) > 0 {
            display as error "E003: Panel data must be uniquely identified by id() and time()"
            display as error "      Found duplicate unit-time observations in the estimation sample"
            exit 459
        }
        
        // -----------------------------------------------------------------
        // Step 1: Time index conversion
        // Convert time variable to consecutive integers for standardization
        // -----------------------------------------------------------------
        tempvar id_time_n
        egen `id_time_n' = group(`time') if `touse'
        
        // -----------------------------------------------------------------
        // Step 2: Identify treatment time
        // Treatment time is the minimum time period where treatment == 1
        // -----------------------------------------------------------------
        quietly summarize `id_time_n' if `treatment' == 1 & `touse', meanonly
        if r(N) == 0 {
            display as error "E003: Cannot identify treatment time"
            exit 198
        }
        local treat_year = r(min)

        // Standard DID requires an absorbing treatment path within each unit.
        tempvar treat_bin treat_lag treat_diff
        quietly gen double `treat_bin' = round(`treatment', 1e-6) if `touse'
        quietly bysort `id' (`id_time_n'): gen double `treat_lag' = `treat_bin'[_n-1] if `touse'
        quietly gen double `treat_diff' = `treat_bin' - `treat_lag' if `touse' & `treat_lag' < .
        quietly count if `treat_diff' < 0 & `touse'
        if r(N) > 0 {
            display as error "E003: Treatment variable must be cumulative (absorbing)"
            display as error "      Found `r(N)' observations with treatment decreasing over time"
            display as error "      Standard DID requires treatment to remain 1 once it starts"
            exit 459
        }

        // Standard DID requires a common treatment adoption time for all
        // eventually treated units. Later cohorts must use design(sa).
        tempvar first_treat_obs first_treat_unit unit_treat_tag
        quietly gen double `first_treat_obs' = `id_time_n' if `treatment' == 1 & `touse'
        quietly egen double `first_treat_unit' = min(`first_treat_obs') if `touse', by(`id')
        quietly egen `unit_treat_tag' = tag(`id') if `touse' & `first_treat_unit' < .
        quietly levelsof `first_treat_unit' if `unit_treat_tag' == 1 & `touse', local(first_treat_levels)
        local n_treat_times : word count `first_treat_levels'
        if `n_treat_times' > 1 {
            display as error "E003: Staggered adoption detected under the standard DID design"
            display as error "      Treated units do not share a common treatment adoption time"
            display as error "      Re-run with design(sa) for staggered-adoption estimation"
            exit 459
        }
        
        // -----------------------------------------------------------------
        // Step 3: Create group indicator (Gi)
        // Gi = 1 if unit is ever treated, 0 otherwise.
        // Rounding ensures Gi is exactly 0 or 1 for downstream comparisons.
        // -----------------------------------------------------------------
        tempvar Gi_temp
        egen `Gi_temp' = max(`treatment') if `touse', by(`id')
        replace `Gi_temp' = round(`Gi_temp', 1) if `touse'
        
        // -----------------------------------------------------------------
        // Step 4: Create post-treatment indicator (It)
        // It = 1 if time period >= treatment time, 0 otherwise
        // -----------------------------------------------------------------
        tempvar It_temp
        gen `It_temp' = (`id_time_n' >= `treat_year') if `touse'

        // Standard DID requires at least one pre-treatment period in the
        // estimation sample. Guard here so the failure does not leak into the
        // later lagged-mean merge step.
        quietly count if `It_temp' == 0 & `touse'
        if r(N) == 0 {
            display as error "E003: No pre-treatment observations in sample"
            display as error "      Standard DID requires at least one pre-treatment period in the estimation sample"
            exit 198
        }

        // -----------------------------------------------------------------
        // Step 5: Create standardized time index
        // Centered at treatment time (treatment time = 0)
        // -----------------------------------------------------------------
        tempvar id_time_std_temp
        gen `id_time_std_temp' = `id_time_n' - `treat_year' if `touse'
        
        // -----------------------------------------------------------------
        // Step 6: Validate control units exist
        // After Gi is computed, units with Gi = 0 must exist
        // -----------------------------------------------------------------
        quietly count if `Gi_temp' == 0 & `touse'
        if r(N) == 0 {
            display as error "E003: No control units found in data (all units eventually treated)"
            exit 198
        }
        
        // -----------------------------------------------------------------
        // Step 7: Count units and periods
        // -----------------------------------------------------------------
        tempvar unit_tag
        egen `unit_tag' = tag(`id') if `touse'
        quietly count if `unit_tag' == 1 & `touse'
        local n_units = r(N)
        
        quietly summarize `id_time_n' if `touse'
        local n_periods = r(max) - r(min) + 1
        
        // Store in caller-provided internal variables
        capture drop `idtimevar'
        capture drop `idtimestdvar'
        capture drop `givar'
        capture drop `itvar'
        
        gen `idtimevar' = `id_time_n' if `touse'
        gen `idtimestdvar' = `id_time_std_temp' if `touse'
        gen `givar' = `Gi_temp' if `touse'
        gen `itvar' = `It_temp' if `touse'
        
        local id_var = "`id'"
    }

    // =========================================================================
    // SECTION 4: REPEATED CROSS-SECTIONAL DATA PREPARATION
    // =========================================================================
    // Prepares repeated cross-sectional (RCS) data by:
    // 1. Assigning Gi directly from treatment variable
    // 2. Assigning It directly from post indicator variable
    // 3. Converting time variable to consecutive integers
    // 4. Creating standardized time index (centered at treatment time)
    //
    // Key difference from panel: Gi and It are directly observed, not derived
    
    else if `is_rcs' {
        
        // -----------------------------------------------------------------
        // Step 1-2: Assign Gi and It directly
        // For RCS data, Gi (treatment group) and It (post period) are
        // directly observed rather than derived from panel structure.
        // -----------------------------------------------------------------
        tempvar Gi_temp It_temp
        gen `Gi_temp' = `treatment' if `touse'
        gen `It_temp' = `post' if `touse'
        replace `It_temp' = round(`It_temp', 1) if `touse'
        
        // -----------------------------------------------------------------
        // Step 3: Time index conversion
        // Convert time variable to consecutive integers for standardization
        // -----------------------------------------------------------------
        tempvar id_time_n
        egen `id_time_n' = group(`time') if `touse'
        
        // -----------------------------------------------------------------
        // Step 4: Identify treatment time
        // For RCS, treatment time is the minimum time period where It == 1
        // -----------------------------------------------------------------
        quietly summarize `id_time_n' if abs(`It_temp' - 1) < 1e-6 & `touse', meanonly
        if r(N) == 0 {
            display as error "E003: Cannot identify treatment time from post indicator"
            exit 198
        }
        local treat_year = r(min)
        
        // -----------------------------------------------------------------
        // Step 5: Create standardized time index
        // Centered at treatment time (treatment time = 0)
        // -----------------------------------------------------------------
        tempvar id_time_std_temp
        gen `id_time_std_temp' = `id_time_n' - `treat_year' if `touse'
        
        // -----------------------------------------------------------------
        // Step 6: Count periods
        // Unit count is not applicable for RCS data
        // -----------------------------------------------------------------
        local n_units = .  // Not applicable for RCS
        
        quietly summarize `id_time_n' if `touse'
        local n_periods = r(max) - r(min) + 1
        
        // Store in caller-provided internal variables
        capture drop `idtimevar'
        capture drop `idtimestdvar'
        capture drop `givar'
        capture drop `itvar'
        
        gen `idtimevar' = `id_time_n' if `touse'
        gen `idtimestdvar' = `id_time_std_temp' if `touse'
        gen `givar' = `Gi_temp' if `touse'
        gen `itvar' = `It_temp' if `touse'
        
        local id_var = ""  // No unit ID for RCS
    }

    // =========================================================================
    // SECTION 5: LAGGED OUTCOME TRANSFORMATION
    // =========================================================================
    // Computes the lagged group mean transformation for the sequential DID
    // estimator, which is consistent under the parallel trends-in-trends
    // assumption:
    //
    //   ΔY_{it} = Y_{it} - Ȳ_{Gi,t-1}
    //
    // where Ȳ_{Gi,t-1} is the mean outcome for group Gi at standardized time t-1.
    // This transformation enables the double DID estimator to combine standard
    // DID and sequential DID via GMM for optimal efficiency.
    //
    // Algorithm:
    // 1. Compute mean outcome for each (Gi, id_time_std) combination
    // 2. Shift time index by +1 to create the lag structure
    // 3. Merge lagged means back to original data
    // 4. Compute outcome_delta = outcome - lagged_group_mean
    //
    // The earliest period has missing outcome_delta (no prior period to lag from)
    // =========================================================================
    
    // -----------------------------------------------------------------
    // Step 1: Compute group-period means
    // Mean outcome is computed for each (Gi, id_time_std) combination.
    // Groups containing any missing values are assigned missing mean.
    // -----------------------------------------------------------------
    
    // Use preserve/restore to create the collapsed dataset
    tempvar did_ymean did_merge
    preserve
    
    // Keep only needed variables and sample (quietly to suppress output)
    quietly keep if `touse'
    quietly keep `outcome' `givar' `idtimestdvar'
    
    // Compute means by (Gi, id_time_std) using the observed sample analogue.
    // Missing outcomes drop out of the group mean but do not invalidate the
    // entire group-period lag mean for other observations.
    quietly collapse (mean) `did_ymean' = `outcome', by(`givar' `idtimestdvar')
    
    // -----------------------------------------------------------------
    // Step 2: Time-shift by one period
    // Shifting id_time_std by +1 creates the lagged structure.
    // After merge, each observation at time t receives the mean from t-1.
    // -----------------------------------------------------------------
    quietly replace `idtimestdvar' = `idtimestdvar' + 1
    
    // Save lagged means to tempfile
    tempfile lagged_means
    quietly save `lagged_means', replace
    
    restore
    
    // -----------------------------------------------------------------
    // Step 3: Merge lagged means
    // Left join preserves all observations. Unmatched observations
    // (earliest period) receive missing lagged mean.
    // -----------------------------------------------------------------
    quietly merge m:1 `givar' `idtimestdvar' using `lagged_means', ///
        keep(master match) generate(`did_merge')

    // Restore the caller's observation order so downstream routines that
    // preserve first-appearance semantics (for example bootstrap cluster
    // enumeration) remain invariant to the internal lagged-mean merge.
    quietly sort `did_obs_order'
    
    // -----------------------------------------------------------------
    // Validate merge results
    // -----------------------------------------------------------------
    quietly count if `did_merge' == 1 & `touse'  // master only (no match)
    local n_nomatch = r(N)
    
    quietly count if `did_merge' == 3 & `touse'  // matched
    local n_matched = r(N)
    
    if `n_matched' == 0 {
        display as error "E011: Merge failed - no observations matched lagged means"
        display as error "      This may indicate data structure issues"
        quietly drop `did_merge'
        exit 198
    }
    
    // Warning for high non-match rate (expected for earliest period, but warn if excessive)
    quietly count if `touse'
    local n_total_merge = r(N)
    local pct_nomatch = 100 * `n_nomatch' / `n_total_merge'
    if `pct_nomatch' > 50 {
        display as text "Warning: `pct_nomatch'% of observations had no matching lagged mean"
    }
    
    quietly drop `did_merge'
    
    // -----------------------------------------------------------------
    // Step 4: Compute outcome delta
    // ΔY_{it} = Y_{it} - Ȳ_{Gi,t-1}
    // Missing lagged mean produces missing outcome_delta (earliest period).
    // -----------------------------------------------------------------
    capture drop `deltavar'
    quietly gen double `deltavar' = `outcome' - `did_ymean' if `touse'
    
    // Clean up temporary Ymean variable (not needed after delta calculation)
    capture drop `did_ymean'
    capture drop `did_obs_order'
    
    // -----------------------------------------------------------------
    // Step 5: Validate outcome delta
    // -----------------------------------------------------------------
    
    // Count missing outcome_delta
    quietly count if missing(`deltavar') & `touse'
    local n_missing_delta = r(N)
    
    // Count observations in earliest period (expected to have missing delta)
    quietly summarize `idtimestdvar' if `touse', meanonly
    if r(N) == 0 | missing(r(min)) {
        display as text "Warning: Cannot determine earliest time period (all id_time_std missing)"
        local min_time_std = .
        local n_earliest = 0
    }
    else {
        local min_time_std = r(min)
        quietly count if `idtimestdvar' == `min_time_std' & `touse'
        local n_earliest = r(N)
    }
    
    // Warning if more observations have missing delta than expected
    quietly count if `touse'
    local n_total = r(N)
    
    if `n_missing_delta' > `n_earliest' {
        local extra_missing = `n_missing_delta' - `n_earliest'
        display as text "Warning: `extra_missing' additional observations have missing outcome_delta"
        display as text "         (beyond the `n_earliest' expected for earliest time period)"
        display as text "         This may indicate missing outcome values in the data"
    }
    
    // General warning if high percentage missing
    // For short panels/RCS designs, the earliest period structurally lacks a
    // lagged group mean, so that baseline missingness alone should not be
    // reported as an abnormal high-missing share.
    local pct_missing = 100 * `n_missing_delta' / `n_total'
    if `pct_missing' > 30 & `n_periods' <= 3 & `n_missing_delta' == `n_earliest' {
        // This is expected for short designs when only the earliest period
        // lacks lagged data to compute outcome_delta.
    }
    else if `pct_missing' > 30 {
        display as text "Warning: `pct_missing'% of observations have missing outcome_delta"
    }

    // =========================================================================
    // SECTION 6: MATA STRUCTURE POPULATION
    // =========================================================================
    // Transfer prepared data to Mata structure for estimation
    
    // Store scalar values for Mata
    local treat_year_std = 0  // Standardized treatment time is defined as zero
    
    // Call Mata function to populate structure
    mata: st_local("mata_rc", strofreal(_diddesign_populate_data( ///
        "`outcome'",           /* outcome variable name     */ ///
        "`treatment'",         /* treatment variable name   */ ///
        "`id_var'",            /* id variable name (or "")  */ ///
        "`idtimevar'",         /* id_time variable name     */ ///
        "`covariates'",        /* covariate variable names  */ ///
        "`cluster'",           /* cluster variable name     */ ///
        "`givar'",             /* Gi variable name          */ ///
        "`itvar'",             /* It variable name          */ ///
        "`idtimestdvar'",      /* id_time_std variable name */ ///
        "`deltavar'",          /* outcome_delta var name    */ ///
        `N',                   /* N observations            */ ///
        `n_units',             /* n_units                   */ ///
        `n_periods',           /* n_periods                 */ ///
        `treat_year',          /* treat_year (calendar-normalized) */ ///
        `is_panel',            /* is_panel flag             */ ///
        "`touse'"              /* touse variable name       */ ///
    )))
    
    if `mata_rc' != 0 {
        display as error "Error populating Mata did_data structure"
        exit 498
    }
    
    // =========================================================================
    // SECTION 7: RETURN VALUES
    // =========================================================================
    // Return prepared variable names and computed scalars to caller
    
    // Variable names (created variables)
    return local id_time = "`idtimevar'"
    return local id_time_std = "`idtimestdvar'"
    return local Gi = "`givar'"
    return local It = "`itvar'"
    return local outcome_delta = "`deltavar'"
    
    // Scalar values
    return scalar N = `N'
    return scalar n_units = `n_units'
    return scalar n_periods = `n_periods'
    return scalar treat_year = `treat_year'
    return scalar treat_year_std = `treat_year_std'
    return scalar is_panel = `is_panel'
    return scalar n_missing_delta = `n_missing_delta'

end
