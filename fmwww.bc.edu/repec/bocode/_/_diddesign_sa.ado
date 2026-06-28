*! _diddesign_sa.ado - Staggered adoption design estimation
*!
*! Implements the staggered adoption (SA) extension of the double DID estimator
*! for settings where treatment timing varies across units. The SA design
*! estimates period-specific ATT at each adoption time t using the double DID
*! framework, then aggregates via time-weighted average:
*!
*!   tau_bar^SA = Sum_t pi_t * tau^SA(t)
*!
*! where pi_t is the proportion of newly treated units at period t. This module
*! serves as the Stata interface for SA estimation, delegating numerical
*! computation to the Mata functions in did_sa.mata.

program define _diddesign_sa, eclass
    version 16.0
    
    // =========================================================================
    // SECTION 1: SYNTAX PARSING
    // =========================================================================
    syntax varlist(min=1 fv) [if] [in], ///
        TREATment(varname)              /// Required: treatment indicator
        ID(varname)                     /// Required for SA: unit identifier
        TIME(varname)                   /// Required for SA: time identifier
        [CLuster(varname)]              /// Cluster variable for SEs
        [COVariates(string asis)]       /// Additional covariates (supports factor variables)
        [COVariatesorig(string asis)]   /// Original covariate specification for e()
        [NBoot(integer 30)]             /// Bootstrap iterations (default: 30)
        [LEAD(numlist >=0 integer)]     /// Lead values for SA design
        [THRes(integer 2)]              /// SA threshold (default: 2)
        [LEVEL(cilevel)]                /// Confidence level (default: 95)
        [SEED(integer -1)]              /// Random seed (-1 = not specified)
        [PARALlel]                      /// Use parallel computing
        [SEBoot]                        /// Use bootstrap SE/CI
        [QUIET]                         /// Suppress progress display
        [KMAX(integer 2)]               /// Max K-DID components (default: 2)
        [JTEST(string)]                 /// J-test moment selection: "on" or "off"
        TOUSE(varname)                  /// Sample marker from main program
        [IDORIG(string)]                /// Original id variable name for ereturn
        [TIMEORIG(string)]              /// Original time variable name for ereturn
        [CLUSTERORIG(string)]           /// Original cluster variable name for ereturn
    
    // Read command line from global macro
    local cmdline "$DIDDESIGN_CMDLINE"
    
    // =========================================================================
    // SECTION 2: SET DEFAULTS
    // =========================================================================
    // Parse outcome from varlist
    gettoken outcome rest : varlist
    local covariates_inline = "`rest'"
    local all_covariates = "`covariates_inline' `covariates'"
    local all_covariates = strtrim("`all_covariates'")
    
    // -------------------------------------------------------------------------
    // Duplicate Covariate Check
    // -------------------------------------------------------------------------
    // Remove duplicate covariates when combining inline and covariates() option
    
    if "`all_covariates'" != "" {
        local unique_covars : list uniq all_covariates
        local n_all : word count `all_covariates'
        local n_unique : word count `unique_covars'
        
        if `n_unique' < `n_all' {
            // Find duplicate variables by comparing original and unique lists
            local dups ""
            local seen ""
            foreach v of local all_covariates {
                local is_seen : list v in seen
                if `is_seen' {
                    local is_dup : list v in dups
                    if !`is_dup' {
                        local dups "`dups' `v'"
                    }
                }
                else {
                    local seen "`seen' `v'"
                }
            }
            local dups = strtrim("`dups'")
            display as text "Warning: Duplicate covariates detected and removed: `dups'"
            local all_covariates "`unique_covars'"
        }
    }

    local covariates_spec "`all_covariates'"
    if "`covariatesorig'" != "" {
        local covariates_spec = strtrim("`covariatesorig'")
    }
    
    // -------------------------------------------------------------------------
    // Factor Variable Expansion
    // -------------------------------------------------------------------------
    // Expand factor variables (i.var, ibn.var) into dummy variables
    // Base category is excluded to avoid collinearity with the intercept
    
    tempvar sa_cov_complete_map
    quietly gen byte `sa_cov_complete_map' = 1 if `touse'

    if "`all_covariates'" != "" {
        quietly _diddesign_expand_covariates, covars(`all_covariates') touse(`touse')
        local all_covariates "`r(varlist)'"
        local generated_covariates "`r(generated_vars)'"
        local encoded_string_covariates "`r(encoded_sources)'"
        local n_fv_expanded = r(n_factor_expanded)

        foreach covar_name of local encoded_string_covariates {
            display as text "Note: String factor covariate `covar_name' automatically encoded to numeric"
        }

        quietly markout `sa_cov_complete_map' `all_covariates', strok

        if `n_fv_expanded' > 0 {
            display as text "Note: Factor variables expanded to `n_fv_expanded' dummy variables (base/constant columns excluded)"
        }
    }

    // Treat outcome-missing unit-time cells as unavailable before enforcing the
    // SA balanced-panel contract. Otherwise markout-only gaps can bypass the
    // public guard and silently shift adoption timing in later Mata steps.
    quietly markout `touse' `outcome'
    
    // Set default values
    if "`lead'" == "" local lead = "0"
    local requested_lead "`lead'"
    local nboot_val = `nboot'
    local thres_val = `thres'
    local level_val = `level'
    local n_lead_requested : word count `requested_lead'
    
    // Set default original variable names if not provided
    if "`idorig'" == "" local idorig "`id'"
    if "`timeorig'" == "" local timeorig "`time'"
    if "`clusterorig'" == "" local clusterorig "`cluster'"
    
    // Cluster defaults to id if not specified
    if "`cluster'" == "" {
        local cluster_var ""
        // Also set clusterorig to idorig if cluster was not specified
        if "`clusterorig'" == "" local clusterorig "`idorig'"
    }
    else {
        local cluster_var = "`cluster'"
    }
    
    // Seed handling
    if `seed' == -1 {
        local seed_val = .
    }
    else {
        local seed_val = `seed'
    }
    
    // Quiet option
    local quiet_val = 0
    if "`quiet'" != "" {
        local quiet_val = 1
    }
    
    // Parallel option
    local parallel_val = ("`parallel'" != "")
    local parallel_actually_used = 0
    local n_workers_used = 0
    local n_boot_attempted = `nboot'
    
    // seboot option
    local seboot_val = ("`seboot'" != "")
    
    // =========================================================================
    // SECTION 3: DATA PREPARATION
    // =========================================================================
    // SA design requires balanced panel structure where each unit is observed
    // across all time periods. The treatment timing matrix G_{it} classifies
    // each unit-period as: newly treated (1), not-yet-treated control (0), or
    // previously treated (-1). Valid periods must have at least 'thres' newly
    // treated units to ensure reliable estimation.
    // -------------------------------------------------------------------------
    tempvar sa_obs_order
    quietly gen long `sa_obs_order' = _n if `touse'
    
    // Count observations and units
    quietly count if `touse'
    local N = r(N)
    
    // Count unique units
    tempvar unit_tag
    quietly egen `unit_tag' = tag(`id') if `touse'
    quietly count if `unit_tag' == 1 & `touse'
    local n_units = r(N)
    
    // Count unique time periods
    tempvar time_tag
    quietly egen `time_tag' = tag(`time') if `touse'
    quietly count if `time_tag' == 1 & `touse'
    local n_periods = r(N)

    // Guard against duplicated id() x time() cells before constructing SA
    // cohort timing. The current SA implementation assumes exactly one
    // observation per unit-period in the estimation sample.
    tempvar sa_dup_cell
    quietly bysort `id' `time': gen byte `sa_dup_cell' = (_N > 1) if `touse'
    quietly count if `sa_dup_cell' == 1 & `touse'
    if r(N) > 0 {
        display as error "E003: SA design requires a balanced panel with one observation per id() x time() cell"
        display as error "      Found duplicated id() x time() cells in the estimation sample"
        display as error "      Resolve missing or duplicated unit-time cells before using design(sa)"
        exit 459
    }

    // Guard against incomplete id() x time() support before constructing SA
    // cohort timing.
    local expected_cells = `n_units' * `n_periods'
    if `N' != `expected_cells' {
        display as error "E003: SA design requires a balanced panel with one observation per id() x time() cell"
        display as error "      Found `N' observations but expected `expected_cells' from `n_units' units x `n_periods' periods"
        display as error "      Resolve missing or duplicated unit-time cells before using design(sa)"
        exit 459
    }
    
    // SA DID/sDID estimation uses {t-2, t-1, t} windows, so at least three
    // distinct time periods must be present before any SA period is estimable.
    if `n_periods' < 3 {
        display as error "E008: SA design requires at least 3 time periods"
        display as error "      Found only `n_periods' time period(s)"
        display as error "      SA design needs two pre-treatment periods and one treatment period"
        exit 198
    }
    
    // =========================================================================
    // SECTION 4: VALIDATE TREATMENT VARIABLE
    // =========================================================================
    // SA design requires an absorbing (cumulative) binary treatment indicator:
    //   - Binary: D_{it} in {0, 1} for all observations
    //   - Absorbing: once treated, units remain treated (D_{it} = 1 => D_{is} = 1
    //     for all s > t)
    // This structure enables identification of treatment adoption timing A_i,
    // defined as the first period where D_{it} = 1. The treatment timing matrix
    // G_{it} is then constructed based on A_i to classify unit-period cells.
    // -------------------------------------------------------------------------
    
    // Preserve the user-facing treatment name for e() metadata.
    local treatment_orig "`treatment'"

    // Canonicalize treatment to exact 0/1 before validating absorbing paths.
    tempvar treatment_work
    quietly gen double `treatment_work' = . if `touse'
    quietly replace `treatment_work' = 0 if abs(`treatment') < 1e-6 & `touse'
    quietly replace `treatment_work' = 1 if abs(`treatment' - 1) < 1e-6 & `touse'

    quietly count if missing(`treatment_work') & `touse'
    if r(N) > 0 {
        display as error "E007: Treatment variable must be binary (0/1)"
        display as error "      Found `r(N)' observations outside the 1e-6 tolerance around 0/1"
        display as error "      SA design requires cumulative binary treatment indicator"
        exit 459
    }

    quietly count if `treatment_work' == 1 & `touse'
    if r(N) == 0 {
        display as error "E007: Treatment variable must contain both 0 and 1 values"
        display as error "      SA design requires cumulative binary treatment indicator"
        exit 459
    }

    quietly count if `treatment_work' == 0 & `touse'
    if r(N) == 0 {
        display as error "E007: Treatment variable must contain both 0 and 1 values"
        display as error "      SA design requires cumulative binary treatment indicator"
        exit 459
    }

    local treatment "`treatment_work'"
    
    // Check cumulative treatment (absorbing treatment)
    // Treatment must only transition from 0 to 1, never decrease
    tempvar treat_lag treat_diff
    quietly {
        bysort `id' (`time'): gen `treat_lag' = `treatment'[_n-1] if `touse'
        gen `treat_diff' = `treatment' - `treat_lag' if `touse' & `treat_lag' != .
        count if `treat_diff' < 0 & `touse'
    }
    if r(N) > 0 {
        display as error "E003: Treatment variable must be cumulative (absorbing)"
        display as error "      Found `r(N)' observations with treatment decreasing over time"
        display as error "      SA design requires treatment to only transition from 0 to 1"
        exit 459
    }

    // The validation bysorts above should not leak label-dependent ordering
    // into the Mata bootstrap path. Restore the caller's sample order before
    // _did_sa_prepare_data() reads the data with st_data().
    quietly sort `sa_obs_order'
    
    // =========================================================================
    // SECTION 5: CALL MATA SA ESTIMATION
    // =========================================================================
    // Time-average SA-ATT (Staggered Adoption ATT):
    //
    //   tau_bar^SA = Sum_{t in T} pi_t * tau^SA(t)
    //
    // where:
    //   - pi_t = n_{1t} / Sum_{t'} n_{1t'} is the time weight (proportion of
    //     newly treated units at period t)
    //   - tau^SA(t) is the period-specific double DID estimate combining
    //     tau^SA_DID(t) and tau^SA_sDID(t) via GMM optimal weighting
    //   - Estimation uses three consecutive periods {t-2, t-1, t} per period t
    //
    // GMM weight matrix W = Omega^{-1} minimizes variance under heteroskedasticity.
    // Bootstrap variance estimation resamples units (not observations) with
    // replacement, recomputing all period-specific estimates in each iteration.
    // -------------------------------------------------------------------------
    
    // Set random seed if specified for bootstrap reproducibility
    if `seed_val' != . {
        set seed `seed_val'
    }
    
    // Convert lead numlist to Mata format
    local lead_mata = subinstr("`lead'", " ", ", ", .)
    local n_lead : word count `lead'
    
    // Prepare data in Mata
    mata: st_local("mata_rc", strofreal(_did_sa_prepare_data("`outcome'", "`treatment'", "`id'", "`time'", ///
                               "`cluster_var'", "`all_covariates'", "`touse'")))

    if "`generated_covariates'" != "" {
        capture drop `generated_covariates'
    }
    
    if `mata_rc' != 0 {
        display as error "E011: SA data preparation failed"
        display as error "      No valid observations selected for analysis"
        exit 498
    }
    
    // Parse kmax and jtest for SA K-DID
    local kmax_val = max(1, `kmax')
    local jtest_val = lower("`jtest'")
    if "`jtest_val'" == "" | "`jtest_val'" == "off" {
        local jtest_on = 0
    }
    else if "`jtest_val'" == "on" {
        local jtest_on = 1
    }
    else {
        display as error "E020: jtest() must be 'on' or 'off'"
        exit 198
    }
    // kmax=1: route to K-DID path (single moment = pure SA-DID)
    // kmax=2: stay on original K=2 SA Double-DID path (backward compatible)
    // kmax>2: use generalized K-DID path
    local use_sa_kdid_path = (`kmax_val' != 2)

    // Route: K-DID SA path or standard K=2 path
    if `use_sa_kdid_path' {
        // Generalized K-DID SA path (kmax != 2)
        mata: st_local("mata_rc", strofreal( ///
            _did_sa_main_k((`lead_mata'), `nboot_val', `thres_val', `level_val', `kmax_val', `jtest_on', `quiet_val')))
    }
    else if `parallel_val' == 1 {
        // Parallel SA bootstrap path:
        // 1. Compute point estimate on original data (needed for GMM weights)
        // 2. Run parallel bootstrap via coordinator
        // 3. Aggregate results via _did_sa_main_from_boot()

        // Set did_opt fields required by sa_double_did() (not set by _did_sa_prepare_data)
        mata: did_opt.thres = `thres_val'
        mata: did_opt.lead = (`lead_mata')
        mata: did_opt.n_boot = `nboot_val'
        mata: did_opt.level = `level_val'
        mata: did_opt.quiet = `quiet_val'

        // Compute SA point estimate and store as Mata external for later GMM
        mata: _par_sa_point_est = sa_double_did(did_dat, did_opt)

        // Build coordinator option string
        local parallel_route_opts "outcome(`outcome') treatment(`treatment')"
        local parallel_route_opts "`parallel_route_opts' id(`id') time(`time')"
        local parallel_route_opts "`parallel_route_opts' nboot(`nboot_val') lead(`lead')"
        local parallel_route_opts "`parallel_route_opts' thres(`thres_val') level(`level_val')"
        local parallel_route_opts "`parallel_route_opts' design(sa) touse(`touse')"
        local parallel_route_opts "`parallel_route_opts' ispanel(1) seboot(`seboot_val')"
        if `seed_val' != . {
            local parallel_route_opts "`parallel_route_opts' seed(`seed_val')"
        }
        if "`cluster_var'" != "" {
            local parallel_route_opts "`parallel_route_opts' cluster(`cluster_var')"
        }
        if "`all_covariates'" != "" {
            local parallel_route_opts "`parallel_route_opts' covariates(`all_covariates')"
        }
        if "`quiet'" != "" {
            local parallel_route_opts "`parallel_route_opts' quiet"
        }

        capture noisily _diddesign_parallel_boot, `parallel_route_opts'
        local par_rc = _rc
        local parallel_actually_used = r(parallel_used)
        local n_workers_used = r(n_workers)

        if `par_rc' != 0 & `parallel_actually_used' != 0 {
            exit `par_rc'
        }

        if `parallel_actually_used' == 1 {
            // Parallel succeeded: load combined bootstrap matrix into Mata
            local boot_combined_file "`r(boot_combined)'"
            local boot_tmpdir_path "`r(boot_tmpdir)'"
            local n_boot_success_par = r(n_boot_success)
            local n_boot_attempted = r(n_boot_attempted)

            // Transfer boot results to Mata external _par_boot_est
            preserve
            qui use "`boot_combined_file'", clear

            local boot_ncols = 0
            foreach v of varlist _boot_col* {
                local ++boot_ncols
            }

            if `boot_ncols' > 0 & _N > 0 {
                unab boot_cols : _boot_col*
                putmata _par_boot_est = (`boot_cols'), replace
                restore
                capture erase "`boot_combined_file'"
                capture rmdir "`boot_tmpdir_path'"

                // Run SA GMM pipeline from pre-collected bootstrap
                mata: st_local("mata_rc", strofreal( ///
                    _did_sa_main_from_boot((`lead_mata'), `level_val', `quiet_val')))
            }
            else {
                restore
                capture erase "`boot_combined_file'"
                capture rmdir "`boot_tmpdir_path'"
                display as text "Note: Parallel bootstrap produced no valid results; falling back to sequential."
                local parallel_actually_used = 0
                mata: st_local("mata_rc", strofreal( ///
                    _did_sa_main((`lead_mata'), `nboot_val', `thres_val', `level_val', `quiet_val')))
            }
        }
        else {
            // Graceful degradation to sequential
            mata: st_local("mata_rc", strofreal( ///
                _did_sa_main((`lead_mata'), `nboot_val', `thres_val', `level_val', `quiet_val')))
        }
    }
    else {
        // Sequential bootstrap (existing Mata path, unchanged)
        mata: st_local("mata_rc", strofreal(_did_sa_main((`lead_mata'), `nboot_val', `thres_val', `level_val', `quiet_val')))
    }
    
    if `mata_rc' != 0 {
        // Provide specific error messages based on error code
        if `mata_rc' == 1 {
            display as error "E011: SA estimation failed - could not create treatment timing matrix (Gmat)"
        }
        else if `mata_rc' == 2 {
            display as error "E011: SA estimation failed - no valid periods found"
            display as error "      Try reducing the threshold value (thres option)"
        }
        else if `mata_rc' == 3 {
            display as error "E011: SA estimation failed - point estimation returned missing values"
        }
        else if `mata_rc' == 4 {
            display as error "E011: SA estimation failed - insufficient valid bootstrap iterations"
            display as error "      Try increasing the number of bootstrap iterations (nboot option)"
        }
        else {
            display as error "E011: SA estimation failed in Mata (error code: `mata_rc')"
        }
        exit 498
    }
    
    // =========================================================================
    // SECTION 6: RETRIEVE RESULTS FROM MATA
    // =========================================================================
    // Transfer estimation metadata from Mata global scalars to Stata locals
    mata: st_local("n_periods_valid", strofreal(_sa_n_periods_valid))
    mata: st_local("n_boot_success", strofreal(_sa_n_boot_success))
    
    // =========================================================================
    // SECTION 7: STORE e() RETURNS
    // =========================================================================
    // Transfer estimation results from Mata to Stata e() class for post-estimation
    // commands. Results include: coefficient vector (b), variance matrix (V),
    // detailed estimates table, GMM weight matrix (W), and time weights (pi_t).
    // -------------------------------------------------------------------------
    
    tempname b_mat V_mat estimates_mat lead_mat weights_mat W_mat vcov_gmm_mat bootstrap_support_mat time_weights_mat time_weight_period_idx_mat time_weight_periods_mat time_weights_by_lead_mat
    
    mata: st_matrix("`b_mat'", _sa_b)
    mata: st_matrix("`V_mat'", _sa_V)
    mata: st_matrix("`estimates_mat'", _sa_estimates)
    mata: st_matrix("`lead_mat'", _sa_lead_values)
    mata: st_matrix("`weights_mat'", _sa_weights)
    mata: st_matrix("`W_mat'", _sa_W)
    mata: st_matrix("`vcov_gmm_mat'", _sa_vcov_gmm)
    mata: st_matrix("`bootstrap_support_mat'", _sa_bootstrap_support)
    mata: st_matrix("`time_weights_mat'", _sa_time_weights)
    mata: st_matrix("`time_weight_period_idx_mat'", _sa_time_weight_period_idx)
    mata: st_matrix("`time_weights_by_lead_mat'", _sa_time_weights_by_lead)

    tempvar touse_map
    quietly gen byte `touse_map' = `touse'
    
    // Validate result matrices exist and are non-empty
    capture confirm matrix `lead_mat'
    if _rc != 0 {
        display as error "Error: SA estimation produced no valid results (lead_mat not found)"
        exit 498
    }
    if colsof(`lead_mat') == 0 {
        display as error "Error: SA estimation produced no valid results (lead_mat is empty)"
        exit 498
    }
    
    // Reshape flattened W and VCOV matrices to proper 2x2 form for single lead case
    // Mata vec() uses column-major order: [W11, W21, W12, W22] for a 2x2 matrix
    // For multiple leads, matrices remain as n_lead x 4 (each row is one flattened 2x2)
    // K-DID path keeps the n_lead x kmax^2 layout as-is.
    local n_lead = colsof(`lead_mat')
    if !`use_sa_kdid_path' & `n_lead' == 1 {
        // Reconstruct 2x2 GMM weight matrix W = Omega^{-1}
        matrix `W_mat' = (`W_mat'[1,1], `W_mat'[1,3] \ `W_mat'[1,2], `W_mat'[1,4])
        
        // Reconstruct 2x2 variance-covariance matrix Omega of moment conditions
        matrix `vcov_gmm_mat' = (`vcov_gmm_mat'[1,1], `vcov_gmm_mat'[1,3] \ `vcov_gmm_mat'[1,2], `vcov_gmm_mat'[1,4])
    }

    // Single-lead posting still needs the bridge from e(vcov_gmm) into the
    // public 3x3 block. Multi-lead V_mat is fully assembled in Mata on the
    // jointly observed posted bootstrap vector and must not be overwritten here.
    // K-DID path: V_mat diagonal is already filled by _did_sa_main_k; skip bridging.
    if !`use_sa_kdid_path' & `n_lead' == 1 {
        scalar __sa_var_did = `V_mat'[2,2]
        scalar __sa_cov_did_sdid = `vcov_gmm_mat'[1,2]
        scalar __sa_var_sdid = `V_mat'[3,3]
        scalar __sa_w_did = `weights_mat'[1,1]
        scalar __sa_w_sdid = `weights_mat'[1,2]
        scalar __sa_cov_ddid_did = __sa_w_did * __sa_var_did + __sa_w_sdid * __sa_cov_did_sdid
        scalar __sa_cov_ddid_sdid = __sa_w_did * __sa_cov_did_sdid + __sa_w_sdid * __sa_var_sdid

        if !missing(__sa_cov_ddid_did) {
            matrix `V_mat'[1,2] = __sa_cov_ddid_did
            matrix `V_mat'[2,1] = __sa_cov_ddid_did
        }
        if !missing(__sa_cov_ddid_sdid) {
            matrix `V_mat'[1,3] = __sa_cov_ddid_sdid
            matrix `V_mat'[3,1] = __sa_cov_ddid_sdid
        }
        if !missing(__sa_cov_did_sdid) {
            matrix `V_mat'[2,3] = __sa_cov_did_sdid
            matrix `V_mat'[3,2] = __sa_cov_did_sdid
        }
    }
    
    // Set row and column names for e(b)
    local b_names ""
    if `use_sa_kdid_path' {
        foreach l of numlist `lead' {
            local b_names "`b_names' SA_KDID:lead_`l'"
            forvalues kk = 1/`kmax_val' {
                local b_names "`b_names' SA_k`kk':lead_`l'"
            }
        }
    }
    else {
        foreach l of numlist `lead' {
            local b_names "`b_names' SA_dDID:lead_`l' SA_DID:lead_`l' SA_sDID:lead_`l'"
        }
    }
    local b_names = trim("`b_names'")
    matrix colnames `b_mat' = `b_names'
    
    // Set row and column names for e(V)
    matrix rownames `V_mat' = `b_names'
    matrix colnames `V_mat' = `b_names'
    
    // e(b) / e(V) cannot contain missing values. Keep all requested leads in
    // e(estimates), but omit non-estimable coefficients from the posted result.
    tempname b_post V_post
    local post_idx ""
    local post_ddid_n = 0
    local _block_size = 3
    if `use_sa_kdid_path' {
        local _block_size = 1 + `kmax_val'
    }
    forvalues j = 1/`=colsof(`b_mat')' {
        local b_val = el(`b_mat', 1, `j')
        local v_val = el(`V_mat', `j', `j')
        if !missing(`b_val') & !missing(`v_val') {
            local post_idx "`post_idx' `j'"
            if mod(`j' - 1, `_block_size') == 0 {
                local ++post_ddid_n
            }
        }
    }
    local post_idx = trim("`post_idx'")
    local post_ncoef : word count `post_idx'
    
    if `post_ncoef' == 0 {
        display as error "E011: SA estimation failed - no estimable coefficients remain after handling missing components"
        exit 498
    }
    
    local post_idx_mata = subinstr("`post_idx'", " ", ", ", .)
    mata: idx = (`post_idx_mata')
    mata: st_matrix("`b_post'", st_matrix("`b_mat'")[1, idx])
    mata: st_matrix("`V_post'", st_matrix("`V_mat'")[idx, idx])
    mata: mata drop idx
    
    local post_names ""
    foreach idx of local post_idx {
        local cname : word `idx' of `b_names'
        local post_names "`post_names' `cname'"
    }
    local post_names = trim("`post_names'")
    
    matrix colnames `b_post' = `post_names'
    matrix rownames `V_post' = `post_names'
    matrix colnames `V_post' = `post_names'

    local identified_leads ""
    local unidentified_leads ""
    local n_lead_identified 0
    foreach l of numlist `lead' {
        local _lead_found 0
        if `use_sa_kdid_path' {
            local has_final : list posof "SA_KDID:lead_`l'" in post_names
            local has_k1 : list posof "SA_k1:lead_`l'" in post_names
            if `has_final' > 0 | `has_k1' > 0 {
                local _lead_found 1
            }
        }
        else {
            local has_ddid : list posof "SA_dDID:lead_`l'" in post_names
            local has_did : list posof "SA_DID:lead_`l'" in post_names
            local has_sdid : list posof "SA_sDID:lead_`l'" in post_names
            if `has_ddid' > 0 | `has_did' > 0 | `has_sdid' > 0 {
                local _lead_found 1
            }
        }
        if `_lead_found' {
            local identified_leads "`identified_leads' `l'"
            local ++n_lead_identified
        }
        else {
            local unidentified_leads "`unidentified_leads' `l'"
        }
    }
    local identified_leads : list retokenize identified_leads
    local unidentified_leads : list retokenize unidentified_leads

    local posted_lead_pos ""
    local current_n_lead : word count `lead'
    forvalues cur_i = 1/`current_n_lead' {
        local cur_lead : word `cur_i' of `lead'
        local lead_is_identified : list cur_lead in identified_leads
        if `lead_is_identified' {
            local posted_lead_pos "`posted_lead_pos' `cur_i'"
        }
    }
    local posted_lead_pos : list retokenize posted_lead_pos

    tempname lead_posted_mat
    local posted_lead_pos_mata = subinstr("`posted_lead_pos'", " ", ", ", .)
    mata: idx = (`posted_lead_pos_mata')
    mata: st_matrix("`lead_posted_mat'", st_matrix("`lead_mat'")[1, idx])
    mata: mata drop idx

    // Reconstruct the effective SA estimation sample from the valid period
    // support returned by Mata. Each estimable cohort contributes units that are
    // not previously treated at period t and observations in the union of the
    // required pre/post windows used by the requested lead() values.
    tempvar sa_esample sa_unit_tag sa_cluster_tag sa_regress_sample first_treat_period
    quietly gen byte `sa_esample' = 0
    quietly gen byte `sa_regress_sample' = 0
    quietly bysort `id': egen double `first_treat_period' = min(cond(`touse_map' & `treatment' == 1, `time', .))

    local n_tw = rowsof(`time_weights_mat')
    if `n_tw' > 0 {
        quietly levelsof `time' if `touse_map', local(time_levels_support)
        local n_requested_leads : word count `lead'
        forvalues i = 1/`n_tw' {
            local period_idx = el(`time_weight_period_idx_mat', `i', 1)
            local period_pos = int(`period_idx')
            local period_pre1_pos = `period_pos' - 1
            local period_pre2_pos = `period_pos' - 2

            if `period_pre1_pos' < 1 | `period_pre2_pos' < 1 {
                continue
            }

            local period_pre2 : word `period_pre2_pos' of `time_levels_support'
            local period_pre1 : word `period_pre1_pos' of `time_levels_support'
            local period_cur : word `period_pos' of `time_levels_support'

            forvalues lead_idx = 1/`n_requested_leads' {
                local lead_step : word `lead_idx' of `lead'

                if rowsof(`time_weights_by_lead_mat') == `n_tw' {
                    local lead_weight = el(`time_weights_by_lead_mat', `i', `lead_idx')
                    if missing(`lead_weight') | `lead_weight' <= 0 {
                        continue
                    }
                }

                local period_post_pos = `period_pos' + `lead_step'
                local period_post : word `period_post_pos' of `time_levels_support'
                if "`period_post'" == "" {
                    continue
                }

                // Appendix E.3 eligibility for lead s keeps treated units with
                // A_i = t and control units with A_i > t+s (or never treated).
                quietly replace `sa_esample' = 1 if `touse_map' & ///
                    (`first_treat_period' == `period_cur' | missing(`first_treat_period') | `first_treat_period' > `period_post') & ///
                    (`time' == `period_pre2' | `time' == `period_pre1' | `time' == `period_post')

                quietly replace `sa_regress_sample' = 1 if `touse_map' & ///
                    (`first_treat_period' == `period_cur' | missing(`first_treat_period') | `first_treat_period' > `period_post') & ///
                    (`time' == `period_pre1' | `time' == `period_post')
            }
        }
    }

    // Rows with missing outcomes never enter any valid SA DID/sDID component,
    // even if they belong to the raw support window. Exclude them so the
    // posted sample and header reflect observations that can actually
    // contribute to estimation under the current sample contract.
    quietly replace `sa_esample' = 0 if `sa_esample' == 1 & missing(`outcome')

    // Covariates matter only on rows that enter the SA DID/sDID regressions.
    // Keep the broader support window for outcome-based transformations, but do
    // not count support rows that the regression layer will drop for missing X.
    if "`all_covariates'" != "" {
        quietly replace `sa_esample' = 0 if `sa_esample' == 1 & `sa_regress_sample' == 1 & ///
            `sa_cov_complete_map' == 0
    }

    quietly count if `sa_esample' == 1 & `touse_map'
    local N_support = r(N)
    if `N_support' == 0 {
        display as error "E011: SA estimation failed - effective support sample is empty after period filtering"
        exit 498
    }

    quietly egen `sa_unit_tag' = tag(`id') if `sa_esample' == 1 & `touse_map'
    quietly count if `sa_unit_tag' == 1 & `sa_esample' == 1 & `touse_map'
    local n_units_support = r(N)
    local support_cluster_var "`cluster_var'"
    if "`support_cluster_var'" == "" {
        local support_cluster_var "`id'"
    }
    quietly egen `sa_cluster_tag' = tag(`support_cluster_var') if `sa_esample' == 1 & `touse_map'
    quietly count if `sa_cluster_tag' == 1 & `sa_esample' == 1 & `touse_map'
    local n_clusters_support = r(N)

    // Bootstrap inference is defined on treatment-assignment blocks. If the
    // final SA support sample collapses to fewer than two clusters after the
    // same Appendix E.3 eligibility and missing-value filtering used for
    // estimation, fail closed instead of posting degenerate near-zero SEs.
    if `n_clusters_support' < 2 {
        display as error "E003: At least 2 clusters are required for bootstrap inference"
        display as error "      Found only `n_clusters_support' unique cluster in the final SA support sample"
        exit 198
    }

    // Preserve the caller's dataset order after the post-Mata bysort/egen
    // support reconstruction above so repeated diddesign calls in the same
    // session do not inherit label-dependent row reordering.
    quietly sort `sa_obs_order'

    local N = `N_support'
    local n_units = `n_units_support'
    
    // Post filtered b and V matrices with sample marker
    ereturn post `b_post' `V_post', esample(`sa_esample') obs(`N') depname("`outcome'")
    
    // --- Scalars ---
    ereturn scalar n_units = `n_units'
    ereturn scalar n_periods = `n_periods'
    ereturn scalar n_periods_valid = `n_periods_valid'
    ereturn scalar n_boot = `nboot_val'
    ereturn scalar n_clusters = `n_clusters_support'
    ereturn scalar level = `level_val'
    ereturn scalar n_lead = `n_lead_identified'
    ereturn scalar n_lead_requested = `n_lead_requested'
    ereturn scalar n_lead_filtered = 0
    ereturn scalar n_lead_identified = `n_lead_identified'
    ereturn scalar thres = `thres_val'
    ereturn scalar is_panel = 1
    ereturn scalar seboot = `seboot_val'
    ereturn scalar kmax = `kmax_val'
    ereturn scalar jtest_on = `jtest_on'
    ereturn scalar parallel = `parallel_actually_used'
    if `parallel_actually_used' {
        ereturn scalar n_workers = `n_workers_used'
        ereturn scalar n_boot_attempted = `n_boot_attempted'
    }
    
    // Always expose bootstrap success counts for auditability.
    if "`n_boot_success'" != "" & "`n_boot_success'" != "." {
        ereturn scalar n_boot_success = `n_boot_success'
    }
    
    // --- Macros ---
    ereturn local cmd "diddesign"
    ereturn local cmdline "`cmdline'"
    ereturn local design "sa"
    ereturn local depvar "`outcome'"
    ereturn local treatment "`treatment_orig'"
    ereturn local covariates "`covariates_spec'"
    ereturn local covars "`covariates_spec'"
    ereturn local id "`idorig'"
    ereturn local time "`timeorig'"
    ereturn local clustvar "`clusterorig'"
    ereturn local datatype "panel"
    ereturn local sample_ifin ""
    ereturn local ci_method "bootstrap"
    ereturn local lead "`identified_leads'"
    ereturn local requested_lead "`requested_lead'"
    ereturn local filtered_lead ""
    ereturn local identified_lead "`identified_leads'"
    ereturn local unidentified_lead "`unidentified_leads'"
    ereturn local properties "b V"
    
    // --- Additional Matrices ---
    // Set row and column names for e(estimates)
    local est_rownames ""
    if `use_sa_kdid_path' {
        foreach l of numlist `lead' {
            local est_rownames "`est_rownames' SA_final:lead_`l'"
            forvalues kk = 1/`kmax_val' {
                local est_rownames "`est_rownames' SA_k`kk':lead_`l'"
            }
        }
    }
    else {
        foreach l of numlist `lead' {
            local est_rownames "`est_rownames' SA_dDID:lead_`l' SA_DID:lead_`l' SA_sDID:lead_`l'"
        }
    }
    local est_rownames = trim("`est_rownames'")
    matrix rownames `estimates_mat' = `est_rownames'
    if `use_sa_kdid_path' {
        matrix colnames `estimates_mat' = lead estimate std_error ci_lo ci_hi weight component_k selected_jtest selected_final dropped_jtest dropped_numerical K_init K_sel K_final
    }
    else {
        matrix colnames `estimates_mat' = lead estimate std_error ci_lo ci_hi weight
    }
    
    // Set names for e(lead_values)
    matrix colnames `lead_posted_mat' = `identified_leads'
    
    // Set names for e(weights)
    local wt_rownames ""
    foreach l of numlist `lead' {
        local wt_rownames "`wt_rownames' lead_`l'"
    }
    local wt_rownames = trim("`wt_rownames'")
    matrix rownames `weights_mat' = `wt_rownames'
    if `use_sa_kdid_path' {
        local wt_colnames ""
        forvalues kk = 1/`kmax_val' {
            local wt_colnames "`wt_colnames' w_k`kk'"
        }
        matrix colnames `weights_mat' = `wt_colnames'
    }
    else {
        matrix colnames `weights_mat' = w_did w_sdid
    }
    
    // Make a copy of estimates_mat for display
    tempname display_mat
    matrix `display_mat' = `estimates_mat'
    
    // Store additional matrices
    ereturn matrix estimates = `estimates_mat'
    ereturn matrix lead_values = `lead_posted_mat'
    ereturn matrix weights = `weights_mat'
    ereturn matrix W = `W_mat'
    ereturn matrix vcov_gmm = `vcov_gmm_mat'
    matrix rownames `bootstrap_support_mat' = `wt_rownames'
    if `use_sa_kdid_path' {
        local bs_colnames ""
        forvalues kk = 1/`kmax_val' {
            local bs_colnames "`bs_colnames' boot_k`kk'"
        }
        matrix colnames `bootstrap_support_mat' = `bs_colnames'
    }
    else {
        matrix colnames `bootstrap_support_mat' = n_valid_did n_valid_sdid n_joint_valid
    }
    ereturn matrix bootstrap_support = `bootstrap_support_mat'
    
    // Set row/column names for time_weights matrix
    local n_tw = rowsof(`time_weights_mat')
    if `n_tw' > 0 {
        local tw_rownames ""
        local tw_labels ""
        matrix `time_weight_periods_mat' = J(`n_tw', 1, .)
        quietly levelsof `time' if `touse_map', local(time_levels_used)
        forvalues i = 1/`n_tw' {
            local period_idx = el(`time_weight_period_idx_mat', `i', 1)
            local period_pos = int(`period_idx')
            local period_value : word `period_pos' of `time_levels_used'
            local period_label "`period_value'"
            local period_orig_label ""
            capture confirm variable `timeorig'
            if _rc == 0 {
                capture levelsof `timeorig' if `time' == `period_value' & `touse_map', local(period_orig_label)
                if _rc == 0 & "`period_orig_label'" != "" {
                    local period_label "`period_orig_label'"
                }
            }
            local period_stub = strtoname("time_`period_label'")
            if "`period_stub'" == "" {
                local period_stub "time_`period_pos'"
            }
            local tw_rownames "`tw_rownames' `period_stub'"
            matrix `time_weight_periods_mat'[`i', 1] = `period_value'
            if `i' == 1 {
                local tw_labels "`period_label'"
            }
            else {
                local tw_labels "`tw_labels'|`period_label'"
            }
        }
        local tw_rownames = trim("`tw_rownames'")
        matrix rownames `time_weights_mat' = `tw_rownames'
        matrix colnames `time_weights_mat' = weight
        matrix rownames `time_weight_periods_mat' = `tw_rownames'
        matrix colnames `time_weight_periods_mat' = period
        ereturn matrix time_weight_periods = `time_weight_periods_mat'
        ereturn local time_weight_labels "`tw_labels'"
        if rowsof(`time_weights_by_lead_mat') == `n_tw' {
            local tw_lead_colnames ""
            foreach l of numlist `lead' {
                local tw_lead_colnames "`tw_lead_colnames' lead_`l'"
            }
            local tw_lead_colnames = trim("`tw_lead_colnames'")
            matrix rownames `time_weights_by_lead_mat' = `tw_rownames'
            matrix colnames `time_weights_by_lead_mat' = `tw_lead_colnames'
            ereturn matrix time_weights_by_lead = `time_weights_by_lead_mat'
        }
    }
    ereturn matrix time_weights = `time_weights_mat'

    // K-DID specific matrices
    if `use_sa_kdid_path' {
        tempname sa_k_summary_mat sa_jtest_stats_mat
        mata: st_matrix("`sa_k_summary_mat'", _sa_k_summary)
        mata: st_matrix("`sa_jtest_stats_mat'", _sa_jtest_stats)
        matrix rownames `sa_k_summary_mat' = `wt_rownames'
        matrix colnames `sa_k_summary_mat' = K_init K_sel K_final
        matrix rownames `sa_jtest_stats_mat' = `wt_rownames'
        matrix colnames `sa_jtest_stats_mat' = J_stat J_df J_pval
        ereturn matrix k_summary = `sa_k_summary_mat'
        ereturn matrix jtest_stats = `sa_jtest_stats_mat'
        ereturn local moment_rule "drop-highest-order-on-rejection"
        ereturn local fallback_rule "drop-highest-order-until-invertible"
    }
    
    if `post_ncoef' < colsof(`b_mat') {
        display as text "Note: Some SA estimators are not identified for the requested lead(s)."
        display as text "      They are stored as missing in e(estimates) and omitted from e(b) and e(V)."
    }
    
    // =========================================================================
    // SECTION 8: DISPLAY RESULTS
    // =========================================================================
    _diddesign_display_header, cmd("diddesign") design("sa") ///
        datatype("Panel") n(`N') n_units(`n_units') ///
        n_periods(`n_periods') n_boot(`nboot_val') ///
        cluster("`clusterorig'") thres(`thres_val')
    
    // Display valid periods info
    display as text ""
    display as text "Valid periods:    " as result "`n_periods_valid'" ///
            as text " (threshold = `thres_val')"
    
    // Display CI method
    display as text ""
    display as text "Confidence intervals: Bootstrap percentile (`level_val'%)"
    
    // Display results table for each lead
    local row = 1
    if `use_sa_kdid_path' {
        display as text "Generalized SA-K-DID: kmax = `kmax_val'" _continue
        if `jtest_on' {
            display as text ", J-test = on"
        }
        else {
            display as text ", J-test = off"
        }
    }
    foreach l of numlist `lead' {
        // Display lead header
        display as text ""
        display as text "Results (lead = `l'):"
        display as text "{hline 78}"
        display as text %13s "Estimator" " | " %9s "Estimate" %10s "Std.Err." %20s "[`level_val'% Conf. Interval]" %9s "Weight"
        display as text "{hline 14}+{hline 64}"

        if `use_sa_kdid_path' {
            // SA K-DID path: final estimate + k components
            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local k_f = `display_mat'[`row', 14]
            _diddesign_display_result, label("SA-K-DID (K=`k_f')") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(.)
            local row = `row' + 1

            forvalues kk = 1/`kmax_val' {
                local est = `display_mat'[`row', 2]
                local se = `display_mat'[`row', 3]
                local ci_lo = `display_mat'[`row', 4]
                local ci_hi = `display_mat'[`row', 5]
                local wt = `display_mat'[`row', 6]
                _diddesign_display_result, label("SA-k`kk'") ///
                    estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
                local row = `row' + 1
            }
        }
        else {
            // Standard K=2 path: SA-Double-DID / SA-DID / SA-sDID
            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            _diddesign_display_result, label("SA-Double-DID") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1

            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            _diddesign_display_result, label("SA-DID") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1

            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            _diddesign_display_result, label("SA-sDID") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1
        }
    }
    
    display as text "{hline 78}"
    
    // Display notes
    display as text ""
    if `use_sa_kdid_path' {
        display as text "Note: SA-K-DID combines k=1,...,K components using optimal GMM weights."
        display as text "      Weight column shows GMM weights for each component."
    }
    else {
        display as text "Note: Weights sum to 1. CI computed using bootstrap quantiles."
    }
    
end
