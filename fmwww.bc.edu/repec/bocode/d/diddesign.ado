*! diddesign.ado - Main estimation command for Double DID
*!
*! Implements the Double Difference-in-Differences estimator for standard
*! DID designs with multiple pre-treatment periods. Combines standard DID
*! and sequential DID estimators via GMM for optimal efficiency.

program define diddesign, eclass
    version 16.0

    // Clear stale estimation results before any failure path can exit.
    ereturn clear
    
    // =========================================================================
    // SECTION 0: Initialize Mata Library
    // =========================================================================
    // Mata functions are loaded if not already available in memory
    
    capture mata: mata describe _did_std_main()
    if _rc != 0 {
        // Mata functions are not loaded; attempt to locate and load them
        local mata_loaded = 0
        
        // Method 1: Direct findfile for diddesign_mata.do (works after net install)
        qui capture findfile diddesign_mata.do
        if _rc == 0 {
            quietly do "`r(fn)'"
            local mata_loaded = 1
        }
        
        // Method 2: Relative path from ado file (works in development environment)
        if !`mata_loaded' {
            qui capture findfile diddesign.ado
            if _rc == 0 {
                local ado_path = subinstr("`r(fn)'", char(92), "/", .)
                local ado_dir = reverse(substr(reverse("`ado_path'"), strpos(reverse("`ado_path'"), "/") + 1, .))
                local mata_path "`ado_dir'/../mata/diddesign_mata.do"
                capture confirm file "`mata_path'"
                if _rc == 0 {
                    quietly do "`mata_path'"
                    local mata_loaded = 1
                }
            }
        }
        
        // Verify loading succeeded
        if !`mata_loaded' {
            capture mata: mata describe _did_std_main()
            if _rc != 0 {
                display as error "E001: DIDdesign Mata functions not found"
                display as error "Mata files could not be located in adopath or relative paths."
                display as error "Solutions:"
                display as error "  1. Reinstall: net install diddesign, from(...) replace"
                display as error "  2. Or manually: do {path}/diddesign_mata.do"
                exit 198
            }
        }
    }
    // =========================================================================
    // SECTION 1: Parse Command Syntax
    // =========================================================================
    
    syntax anything(name=rawvars) [if] [in], ///
        TREATment(varname)              /// Required: treatment indicator
        [ID(varname)]                   /// Unit identifier (required for panel)
        [TIME(varname)]                 /// Time identifier (required)
        [POST(varname)]                 /// Post-treatment indicator (RCS only)
        [CLuster(varname)]              /// Cluster variable for SEs
        [COVariates(string asis)]       /// Additional covariates (supports factor variables via string)
        [NBoot(integer 30)]             /// Bootstrap iterations (default: 30)
        [LEAD(numlist >=0 integer)]     /// Lead values for SA design
        [THRes(integer 2)]              /// SA threshold (default: 2)
        [LEVEL(cilevel)]                /// Confidence level (Stata default: 95)
        [SEED(integer -1)]              /// Random seed (-1 = not specified)
        [DESIGN(string)]                /// Design type: "did" (default) or "sa"
        [PARALlel]                      /// Use parallel computing
        [SEBoot]                        /// Use bootstrap SE/CI
        [PANEL]                         /// Panel data format
        [RCS]                           /// Repeated cross-section format
        [QUIET]                         /// Suppress progress display
        [KMAX(integer 2)]               /// Max K-DID components (default: 2)
        [JTEST(string)]                 /// J-test moment selection: "on" or "off" (default)

    // Normalize outer quotes so quoted and unquoted covariates() forms
    // share the same downstream parse path.
    local covariates_clean = subinstr(`"`covariates'"', `"""', "", .)
    local covariates_clean = strtrim(`"`covariates_clean'"')
    
    // Full command line is stored for e(cmdline)
    local cmdline "diddesign `0'"
    local varlist "`rawvars'"
    local parse_varlist "`varlist'"
    if `"`covariates_clean'"' != "" {
        local parse_varlist `"`parse_varlist' `covariates_clean'"'
    }
    local design_requested = lower("`design'")
    if "`design_requested'" == "" {
        local design_requested "did"
    }
    local thres_specified = strpos(lower("`0'"), "thres(") > 0
    if `thres_specified' & "`design_requested'" != "sa" {
        display as error "E002: thres() is only allowed with design(sa)"
        exit 198
    }
    
    // =========================================================================
    // SECTION 2: Validate Parameters
    // =========================================================================
    // Detailed validation is delegated to _diddesign_parse
    
    local parse_opts "treatment(`treatment')"
    if "`id'" != "" {
        local parse_opts "`parse_opts' id(`id')"
    }
    if "`time'" != "" {
        local parse_opts "`parse_opts' time(`time')"
    }
    if "`post'" != "" {
        local parse_opts "`parse_opts' post(`post')"
    }
    if "`cluster'" != "" {
        local parse_opts "`parse_opts' cluster(`cluster')"
    }
    local parse_opts "`parse_opts' nboot(`nboot')"
    if "`lead'" != "" {
        local parse_opts "`parse_opts' lead(`lead')"
    }
    local parse_opts "`parse_opts' thres(`thres')"
    local parse_opts "`parse_opts' level(`level')"
    local parse_opts "`parse_opts' seed(`seed')"
    if "`design'" != "" {
        local parse_opts "`parse_opts' design(`design')"
    }
    if "`parallel'" != "" {
        local parse_opts "`parse_opts' parallel"
    }
    if "`seboot'" != "" {
        local parse_opts "`parse_opts' seboot"
    }
    if "`panel'" != "" {
        local parse_opts "`parse_opts' panel"
    }
    if "`rcs'" != "" {
        local parse_opts "`parse_opts' rcs"
    }
    
    _diddesign_parse `parse_varlist' `if' `in', `parse_opts'
    
    // Parsed values are retrieved from r() before subsequent commands overwrite them
    local outcome "`r(outcome)'"
    local treatment_var "`r(treatment)'"
    local id_var "`r(id)'"
    local time_var "`r(time)'"
    local post_var "`r(post)'"
    local cluster_var "`r(cluster)'"
    local covariates_list "`r(covariates)'"
    local covariates_spec "`covariates_list'"
    
    // Scalar returns
    local nboot_val = r(nboot)
    local thres_val = r(thres)
    local level_val = r(level)
    local seed_val = r(seed)
    
    // String returns
    local lead_val "`r(lead)'"
    
    // Scalar returns
    local parallel_val = r(parallel)
    local seboot_val = r(seboot)
    local is_panel = r(is_panel)
    
    // String variable indicators for automatic encoding
    local id_is_string = r(id_is_string)
    local time_is_string = r(time_is_string)
    local cluster_is_string = r(cluster_is_string)
    
    // String return
    local design_val "`r(design)'"
    
    // -------------------------------------------------------------------------
    // String Variable Encoding
    // -------------------------------------------------------------------------
    // Encode string id()/time()/cluster() variables to numeric.
    // Original names are preserved in e() returns for interpretability.
    // Original variable names are preserved for reporting in e() returns
    marksample touse, novarlist
    tempvar did_cmd_obs_order
    quietly gen long `did_cmd_obs_order' = _n
    
    local id_var_orig "`id_var'"
    local time_var_orig "`time_var'"
    local post_var_orig "`post_var'"
    local cluster_var_orig "`cluster_var'"
    local cluster_var_report "`cluster_var_orig'"
    if `is_panel' & "`cluster_var_report'" == "" {
        local cluster_var_report "`id_var_orig'"
    }
    
    if `id_is_string' == 1 & "`id_var'" != "" {
        tempvar id_encoded
        quietly egen `id_encoded' = group(`id_var')
        display as text "Note: String variable `id_var' automatically encoded to numeric"
        local id_var "`id_encoded'"
    }

    // Exclude observations with missing structural variables from the working
    // sample before any downstream sample-dependent transformations.
    markout `touse' `treatment_var', strok
    if "`id_var'" != "" {
        markout `touse' `id_var', strok
    }
    if "`time_var'" != "" {
        markout `touse' `time_var', strok
    }
    if "`post_var'" != "" {
        markout `touse' `post_var', strok
    }
    // cluster() defines the bootstrap block, not the point-estimation sample.
    // Missing cluster values are handled by bootstrap support guards later on.

    // -------------------------------------------------------------------------
    // Factor Variable Expansion
    // -------------------------------------------------------------------------
    // Factor variables (i.var, ibn.var, etc.) are expanded into dummy variables
    // Base category is excluded to avoid collinearity with the intercept term
    if "`covariates_list'" != "" {
        quietly _diddesign_expand_covariates, covars(`covariates_list') touse(`touse')
        local covariates_list "`r(varlist)'"
        local generated_covariates "`r(generated_vars)'"
        local encoded_string_covariates "`r(encoded_sources)'"
        local n_fv_expanded = r(n_factor_expanded)

        foreach covar_name of local encoded_string_covariates {
            display as text "Note: String factor covariate `covar_name' automatically encoded to numeric"
        }

        if `n_fv_expanded' > 0 {
            display as text "Note: Factor variables expanded to `n_fv_expanded' dummy variables (base/constant columns excluded)"
        }

        // Keep covariate-missing rows through data preparation so outcome_delta
        // remains a pure outcome-based transformation, matching the reference
        // algorithm. Listwise deletion for covariates happens inside did_fit().
    }
    
    if `time_is_string' == 1 & "`time_var'" != "" {
        // Guard against ambiguous string-time labels whose lexicographic
        // order differs from their first appearance in the actual regression
        // sample. Silent reordering can invalidate time-sensitive DID/SA logic.
        local time_order_mismatch_n = 0
        tempvar time_guard_touse
        quietly gen byte `time_guard_touse' = `touse'
        quietly markout `time_guard_touse' `outcome'
        if "`design_val'" == "sa" {
            // SA keeps pre2 support rows in e(sample) even when covariates are
            // missing there, but it drops covariate-incomplete rows that enter
            // the actual SA DID/sDID regressions. It also ignores time labels
            // from periods that never enter any valid lead window. Build the
            // string-time guard on that estimator-facing sample, not on a
            // generic outcome+covariate complete-case sample.
            tempvar time_guard_cov_complete time_guard_seen
            tempvar time_guard_sa_sample time_guard_sa_regress
            tempvar time_guard_treat_work time_guard_first_treat
            tempvar time_guard_treat_lag time_guard_treat_diff
            tempfile time_guard_seen_map

            quietly gen byte `time_guard_cov_complete' = 1 if `time_guard_touse'
            if "`covariates_list'" != "" {
                quietly markout `time_guard_cov_complete' `covariates_list'
            }

            preserve
                quietly keep if `time_guard_touse'
                keep `time_var'
                tempvar time_first_idx
                quietly gen long `time_first_idx' = _n
                quietly bysort `time_var' (`time_first_idx'): keep if _n == 1
                quietly sort `time_first_idx'
                quietly gen long `time_guard_seen' = _n
                keep `time_var' `time_guard_seen'
                save `time_guard_seen_map'
            restore

            quietly merge m:1 `time_var' using `time_guard_seen_map', nogen keep(master match)
            quietly sort `did_cmd_obs_order'

            quietly gen byte `time_guard_sa_sample' = 0
            quietly gen byte `time_guard_sa_regress' = 0
            quietly gen double `time_guard_treat_work' = . if `time_guard_touse'
            quietly replace `time_guard_treat_work' = 0 if abs(`treatment_var') < 1e-6 & `time_guard_touse'
            quietly replace `time_guard_treat_work' = 1 if abs(`treatment_var' - 1) < 1e-6 & `time_guard_touse'
            quietly bysort `id_var' (`time_guard_seen'): gen double `time_guard_treat_lag' = ///
                `time_guard_treat_work'[_n-1] if `time_guard_touse'
            quietly gen double `time_guard_treat_diff' = ///
                `time_guard_treat_work' - `time_guard_treat_lag' if `time_guard_touse' & `time_guard_treat_lag' < .
            quietly bysort `id_var': egen double `time_guard_first_treat' = ///
                min(cond(`time_guard_touse' & `time_guard_treat_work' == 1, `time_guard_seen', .))

            local time_guard_leads "0"
            if "`lead_val'" != "" {
                local time_guard_leads "`lead_val'"
            }

            quietly levelsof `time_guard_seen' if `time_guard_touse', local(time_guard_periods)
            foreach period_cur of local time_guard_periods {
                if `period_cur' < 3 {
                    continue
                }
                quietly count if `time_guard_touse' & `time_guard_first_treat' == `period_cur'
                if r(N) < `thres_val' {
                    continue
                }
                foreach lead_step of numlist `time_guard_leads' {
                    local period_post = `period_cur' + `lead_step'
                    quietly count if `time_guard_touse' & `time_guard_seen' == `period_post'
                    if r(N) == 0 {
                        continue
                    }

                    quietly replace `time_guard_sa_sample' = 1 if `time_guard_touse' & ///
                        (`time_guard_first_treat' == `period_cur' | missing(`time_guard_first_treat') | ///
                        `time_guard_first_treat' > `period_post') & ///
                        inlist(`time_guard_seen', `=`period_cur' - 2', `=`period_cur' - 1', `period_post')

                    quietly replace `time_guard_sa_regress' = 1 if `time_guard_touse' & ///
                        (`time_guard_first_treat' == `period_cur' | missing(`time_guard_first_treat') | ///
                        `time_guard_first_treat' > `period_post') & ///
                        inlist(`time_guard_seen', `=`period_cur' - 1', `period_post')
                }
            }

            if "`covariates_list'" != "" {
                quietly replace `time_guard_sa_sample' = 0 if `time_guard_sa_sample' == 1 & ///
                    `time_guard_sa_regress' == 1 & `time_guard_cov_complete' == 0
            }
            quietly replace `time_guard_touse' = (`time_guard_sa_sample' == 1) if `time_guard_touse'
        }
        else if "`covariates_list'" != "" {
            quietly markout `time_guard_touse' `covariates_list'
        }
        preserve
            quietly keep if `time_guard_touse'
            keep `time_var'
            tempvar time_first_idx time_alpha_idx time_seen_idx
            tempvar time_num_suffix time_prefix time_suffix_tag time_suffix_prefix_tag
            quietly gen long `time_first_idx' = _n
            quietly bysort `time_var' (`time_first_idx'): keep if _n == 1
            quietly egen long `time_alpha_idx' = group(`time_var')
            quietly sort `time_first_idx'
            quietly gen long `time_seen_idx' = _n
            quietly count if `time_alpha_idx' != `time_seen_idx'
            local time_order_mismatch_n = r(N)
            quietly gen double `time_num_suffix' = .
            quietly replace `time_num_suffix' = real(regexs(1)) if regexm(`time_var', "([0-9]+)$")
            quietly gen str244 `time_prefix' = ""
            quietly replace `time_prefix' = regexr(`time_var', "[0-9]+$", "") if regexm(`time_var', "([0-9]+)$")
            quietly egen byte `time_suffix_tag' = tag(`time_var')
            quietly count if missing(`time_num_suffix') & `time_suffix_tag' == 1
            local time_suffix_missing_n = r(N)
            local time_suffix_prefix_count = 0
            local time_suffix_order_mismatch_n = 0
            if `time_suffix_missing_n' == 0 {
                quietly egen byte `time_suffix_prefix_tag' = tag(`time_prefix') if `time_suffix_tag' == 1
                quietly count if `time_suffix_prefix_tag' == 1
                local time_suffix_prefix_count = r(N)
                if `time_suffix_prefix_count' == 1 {
                    quietly sort `time_num_suffix' `time_var'
                    quietly gen long time_numeric_idx = _n
                    quietly count if `time_alpha_idx' != time_numeric_idx
                    local time_suffix_order_mismatch_n = r(N)
                }
            }
        restore
        if `time_order_mismatch_n' > 0 | `time_suffix_order_mismatch_n' > 0 {
            display as error "E002: Ambiguous string time order detected for `time_var'"
            display as error "      Automatic encoding would reorder observed time labels lexicographically"
            display as error "      Recode time() to numeric or lexically ordered strings before estimation"
            _dd_cleanup_fv, generated(`generated_covariates')
            exit 198
        }
        if "`design_val'" == "sa" {
            // The SA guard is now built on a first-seen encoding of the
            // estimator-facing sample. Reuse that same encoding so off-support
            // labels cannot reorder treatment paths after the guard has passed.
            display as text "Note: String variable `time_var' automatically encoded to numeric"
            local time_var "`time_guard_seen'"
        }
        else {
            tempvar time_encoded
            quietly egen `time_encoded' = group(`time_var')
            display as text "Note: String variable `time_var' automatically encoded to numeric"
            local time_var "`time_encoded'"
        }
    }
    
    if `cluster_is_string' == 1 & "`cluster_var'" != "" {
        tempvar cluster_encoded
        quietly egen `cluster_encoded' = group(`cluster_var')
        display as text "Note: String variable `cluster_var' automatically encoded to numeric"
        local cluster_var "`cluster_encoded'"
    }
    
    // For RCS data, the bootstrap block must be declared explicitly.
    // Silent observation-level fallback can materially overstate precision
    // relative to the paper's treatment-assignment-level bootstrap.
    if !`is_panel' & "`cluster_var'" == "" {
        _dd_cleanup_fv, generated(`generated_covariates')
        display as error "E018: cluster() is required for RCS data"
        display as error "      Specify cluster() at the treatment-assignment level for bootstrap inference"
        exit 198
    }

    // Bootstrap inference requires at least two distinct resampling blocks.
    local cluster_guard_var "`cluster_var'"
    if "`cluster_guard_var'" == "" & `is_panel' {
        local cluster_guard_var "`id_var'"
    }
    if "`cluster_guard_var'" != "" {
        tempvar cluster_tag
        quietly egen `cluster_tag' = tag(`cluster_guard_var') if `touse' & !missing(`cluster_guard_var')
        quietly count if `cluster_tag' == 1 & `touse' & !missing(`cluster_guard_var')
        local n_clusters_boot = r(N)
        if `n_clusters_boot' < 2 {
            _dd_cleanup_fv, generated(`generated_covariates')
            display as error "E003: At least 2 clusters are required for bootstrap inference"
            display as error "      Found only `n_clusters_boot' unique cluster in the estimation sample"
            exit 198
        }
    }
    
    // =========================================================================
    // SECTION 3: Design Routing
    // =========================================================================
    // Estimation is routed to staggered adoption (SA) or standard DID design
    
    if "`design_val'" == "sa" {
        quietly sort `did_cmd_obs_order'
        // SA design is handled by the _diddesign_sa subprogram
        // Outcome-missing rows can never contribute to SA ATT estimation.
        // Exclude them before handing touse to _diddesign_sa so its balanced-
        // panel guard sees the same working sample as the downstream estimator.
        tempvar sa_touse
        quietly gen byte `sa_touse' = `touse'
        quietly markout `sa_touse' `outcome'

        // Option string is constructed for SA estimation
        local sa_opts "treatment(`treatment_var') id(`id_var') time(`time_var')"
        local sa_opts "`sa_opts' nboot(`nboot_val') thres(`thres_val') level(`level_val')"
        
        if "`cluster_var'" != "" {
            local sa_opts "`sa_opts' cluster(`cluster_var')"
        }
        if "`covariates_list'" != "" {
            local sa_opts `sa_opts' covariates(`covariates_list')
        }
        if "`covariates_spec'" != "" {
            local sa_opts `sa_opts' covariatesorig(`covariates_spec')
        }
        if "`lead_val'" != "" {
            local sa_opts "`sa_opts' lead(`lead_val')"
        }
        if `seed_val' != . {
            local sa_opts "`sa_opts' seed(`seed_val')"
        }
        if "`quiet'" != "" {
            local sa_opts "`sa_opts' quiet"
        }
        if `parallel_val' {
            local sa_opts "`sa_opts' parallel"
        }
        if `seboot_val' {
            local sa_opts "`sa_opts' seboot"
        }
        
        // Pass K-DID options
        local sa_opts "`sa_opts' kmax(`kmax')"
        if "`jtest'" != "" {
            local sa_opts "`sa_opts' jtest(`jtest')"
        }
        
        // Original variable names are passed for e() reporting
        local sa_opts "`sa_opts' idorig(`id_var_orig') timeorig(`time_var_orig')"
        if "`cluster_var_orig'" != "" {
            local sa_opts "`sa_opts' clusterorig(`cluster_var_orig')"
        }
        
        // Global macro is used to pass cmdline (avoids parsing issues with special characters)
        global DIDDESIGN_CMDLINE `"`cmdline'"'
        local sa_opts "`sa_opts' touse(`sa_touse')"
        
        // Pass SA covariates only once via covariates() to avoid spurious
        // duplicate warnings when the user supplied them inline.
        capture noisily _diddesign_sa `outcome', `sa_opts'
        local sa_rc = _rc
        
        // Global macro is always cleaned up, even if _diddesign_sa exits early.
        capture macro drop DIDDESIGN_CMDLINE
        _dd_cleanup_fv, generated(`generated_covariates')

        if `sa_rc' != 0 {
            exit `sa_rc'
        }
        
        // Execution ends here; _diddesign_sa handles all e() returns and display
        exit
    }
    
    // Continue with standard DID design
    
    // =========================================================================
    // SECTION 4: Data Preparation
    // =========================================================================
    // Data structures are prepared for GMM estimation
    tempvar did_id_time_var did_id_time_std_var did_gi_var did_it_var did_outcome_delta_var
    
    local prep_opts "outcome(`outcome') treatment(`treatment_var') time(`time_var')"
    
    if `is_panel' {
        local prep_opts "`prep_opts' id(`id_var') panel"
    }
    else {
        local prep_opts "`prep_opts' post(`post_var') rcs"
    }
    
    if "`cluster_var'" != "" {
        local prep_opts "`prep_opts' cluster(`cluster_var')"
    }
    if "`covariates_list'" != "" {
        local prep_opts "`prep_opts' covariates(`covariates_list')"
    }
    local prep_opts "`prep_opts' idtimevar(`did_id_time_var')"
    local prep_opts "`prep_opts' idtimestdvar(`did_id_time_std_var')"
    local prep_opts "`prep_opts' givar(`did_gi_var')"
    local prep_opts "`prep_opts' itvar(`did_it_var')"
    local prep_opts "`prep_opts' deltavar(`did_outcome_delta_var')"
    local prep_opts "`prep_opts' touse(`touse')"
    
    capture noisily _diddesign_prep, `prep_opts'
    local prep_rc = _rc
    if `prep_rc' != 0 {
        _dd_cleanup_fv, generated(`generated_covariates')
        exit `prep_rc'
    }
    
    // Data preparation results are retrieved
    local N = r(N)
    local n_units = r(n_units)
    local n_periods = r(n_periods)
    local treat_year = r(treat_year)
    local n_missing_delta = r(n_missing_delta)
    local requested_lead_val "`lead_val'"
    local n_lead_requested : word count `requested_lead_val'

    // -------------------------------------------------------------------------
    // Filter infeasible lead values before entering bootstrap / GMM
    // -------------------------------------------------------------------------
    // A lead is feasible when the exact two-period estimation window {-1, lead}
    // has enough support for either DID or sDID after the same missing-value
    // handling used inside did_fit().
    local valid_leads ""
    local filtered_leads ""
    tempvar lead_cov_complete
    tempvar pre_period_tag pre_treat_count pre_control_count
    quietly gen byte `lead_cov_complete' = 1 if `touse'
    if "`covariates_list'" != "" {
        quietly markout `lead_cov_complete' `covariates_list'
    }
    quietly bysort `did_id_time_std_var': egen long `pre_treat_count' = total(`touse' ///
        & `lead_cov_complete' == 1 & `did_id_time_std_var' < 0 ///
        & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
        & `did_gi_var' == 1)
    quietly bysort `did_id_time_std_var': egen long `pre_control_count' = total(`touse' ///
        & `lead_cov_complete' == 1 & `did_id_time_std_var' < 0 ///
        & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
        & `did_gi_var' == 0)
    quietly egen `pre_period_tag' = tag(`did_id_time_std_var') if `touse' ///
        & `lead_cov_complete' == 1 & `did_id_time_std_var' < 0 ///
        & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
        & `pre_treat_count' > 0 & `pre_control_count' > 0
    quietly count if `pre_period_tag' == 1
    local n_pre_periods = r(N)

    // Generalized K-DID: determine effective kmax from data support
    local kmax_val = max(1, `kmax')
    if `kmax_val' > `n_pre_periods' {
        local kmax_val = `n_pre_periods'
    }
    // kmax=1: route to K-DID path (single moment = pure DID, per requirements 3.5)
    // kmax=2: stay on original K=2 Double-DID path (backward compatible)
    // kmax>2: use generalized K-DID path
    local use_kdid_path = (`kmax_val' != 2)
    
    // Parse jtest option
    local jtest_val = lower("`jtest'")
    if "`jtest_val'" == "" {
        local jtest_on = 0
    }
    else if "`jtest_val'" == "on" {
        local jtest_on = 1
    }
    else if "`jtest_val'" == "off" {
        local jtest_on = 0
    }
    else {
        _dd_cleanup_fv, generated(`generated_covariates')
        display as error "E020: jtest() must be 'on' or 'off'"
        exit 198
    }

    foreach l of numlist `lead_val' {
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 0 & `did_it_var' == 0
        local did_n00 = r(N)
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 0 & `did_it_var' == 1
        local did_n01 = r(N)
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 1 & `did_it_var' == 0
        local did_n10 = r(N)
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`outcome') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 1 & `did_it_var' == 1
        local did_n11 = r(N)

        local did_estimable = (`did_n00' > 0 & `did_n01' > 0 & `did_n10' > 0 & `did_n11' > 0)

        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`did_outcome_delta_var') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 0 & `did_it_var' == 0
        local sdid_n00 = r(N)
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`did_outcome_delta_var') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 0 & `did_it_var' == 1
        local sdid_n01 = r(N)
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`did_outcome_delta_var') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 1 & `did_it_var' == 0
        local sdid_n10 = r(N)
        quietly count if `touse' & inlist(`did_id_time_std_var', -1, `l') ///
            & !missing(`did_outcome_delta_var') & !missing(`did_gi_var') & !missing(`did_it_var') ///
            & `lead_cov_complete' == 1 & `did_gi_var' == 1 & `did_it_var' == 1
        local sdid_n11 = r(N)

        local sdid_estimable = (`sdid_n00' > 0 & `sdid_n01' > 0 & `sdid_n10' > 0 & `sdid_n11' > 0)

        if `did_estimable' | `sdid_estimable' {
            local valid_leads "`valid_leads' `l'"
        }
        else {
            local filtered_leads "`filtered_leads' `l'"
        }
    }

    local valid_leads : list retokenize valid_leads
    local filtered_leads : list retokenize filtered_leads
    local n_lead_filtered : word count `filtered_leads'

    if "`filtered_leads'" != "" {
        display as error "Warning: The following lead(s) were filtered out because support over {-1, lead} is insufficient for DID and sDID after missing-value handling: `filtered_leads'"
    }

    if "`valid_leads'" == "" {
        _dd_cleanup_fv, generated(`generated_covariates')
        display as error "E011: No feasible lead() values remain after filtering"
        display as error "      Check support in {-1, lead} for all 2x2 DID cells after missing-value handling"
        exit 498
    }

    local lead_val "`valid_leads'"

    // Align the cluster bootstrap guard with the actual lead-window complete-case
    // support used by DID / sDID, rather than the coarse pre-filter touse sample.
    if "`cluster_guard_var'" != "" {
        tempvar pre_mata_esample pre_mata_cluster_tag
        quietly gen byte `pre_mata_esample' = 0
        foreach l of numlist `lead_val' {
            quietly replace `pre_mata_esample' = 1 if `touse' ///
                & (`did_id_time_std_var' == -1 | `did_id_time_std_var' == `l') ///
                & `lead_cov_complete' == 1 ///
                & !missing(`did_gi_var') ///
                & !missing(`did_it_var') ///
                & (!missing(`outcome') | !missing(`did_outcome_delta_var'))
        }
        if "`cluster_var'" != "" {
            quietly count if `pre_mata_esample' == 1 & `touse' & missing(`cluster_var')
            local n_missing_cluster_support_pre = r(N)
            if `n_missing_cluster_support_pre' > 0 {
                _dd_cleanup_fv, generated(`generated_covariates')
                display as error "E003: cluster() contains missing values in the estimation support sample"
                display as error "      Found `n_missing_cluster_support_pre' observations with undefined bootstrap blocks"
                display as error "      Fill cluster() at the treatment-assignment level or omit cluster() for panel unit-level bootstrap"
                exit 198
            }
        }
        quietly egen `pre_mata_cluster_tag' = tag(`cluster_guard_var') if `pre_mata_esample' == 1 & `touse' & !missing(`cluster_guard_var')
        quietly count if `pre_mata_cluster_tag' == 1 & `pre_mata_esample' == 1 & `touse' & !missing(`cluster_guard_var')
        local n_clusters_support_pre = r(N)
        if `n_clusters_support_pre' < 2 {
            _dd_cleanup_fv, generated(`generated_covariates')
            display as error "E003: At least 2 clusters are required for bootstrap inference"
            display as error "      Found only `n_clusters_support_pre' unique cluster in the final lead support sample"
            exit 198
        }
    }

    // Lead-support prechecks rely on bysort/egen and therefore reorder the
    // dataset. Restore the caller's row order before bootstrap sampling so
    // repeated public invocations with the same seed remain deterministic.
    quietly sort `did_cmd_obs_order'

    // =========================================================================
    // SECTION 5: GMM Estimation
    // =========================================================================
    // Double DID estimator via Generalized Method of Moments (GMM):
    //
    //   tau_ddid = argmin (m - tau)' W (m - tau)
    //
    // where m = (tau_DID, tau_sDID)' contains the standard DID and sequential
    // DID estimators, and W is the optimal GMM weight matrix (inverse of the
    // variance-covariance matrix of m). The Double DID achieves efficiency
    // under the parallel trends assumption and remains consistent under the
    // weaker parallel trends-in-trends assumption.
    
    // Random seed is set if specified
    if `seed_val' != . {
        set seed `seed_val'
    }

    // Lead numlist is converted to Mata format
    local lead_mata = subinstr("`lead_val'", " ", ", ", .)
    local n_lead : word count `lead_val'
    local parallel_route_opts "outcome(`outcome') treatment(`treatment_var')"
    local parallel_route_opts "`parallel_route_opts' nboot(`nboot_val') lead(`lead_val')"
    local parallel_route_opts "`parallel_route_opts' thres(`thres_val') level(`level_val')"
    if `seed_val' != . {
        local parallel_route_opts "`parallel_route_opts' seed(`seed_val')"
    }
    local parallel_route_opts "`parallel_route_opts' design(`design_val')"
    local parallel_route_opts "`parallel_route_opts' touse(`touse') ispanel(`is_panel')"
    if "`id_var'" != "" {
        local parallel_route_opts "`parallel_route_opts' id(`id_var')"
    }
    if "`time_var'" != "" {
        local parallel_route_opts "`parallel_route_opts' time(`time_var')"
    }
    if "`post_var'" != "" {
        local parallel_route_opts "`parallel_route_opts' post(`post_var')"
    }
    if "`cluster_var'" != "" {
        local parallel_route_opts "`parallel_route_opts' cluster(`cluster_var')"
    }
    if "`covariates_list'" != "" {
        local parallel_route_opts "`parallel_route_opts' covariates(`covariates_list')"
    }
    global DIDDESIGN_PAR_IDTIMEVAR "`did_id_time_var'"
    global DIDDESIGN_PAR_IDTIMESTDVAR "`did_id_time_std_var'"
    global DIDDESIGN_PAR_GIVAR "`did_gi_var'"
    global DIDDESIGN_PAR_ITVAR "`did_it_var'"
    global DIDDESIGN_PAR_DELTAVAR "`did_outcome_delta_var'"
    global DIDDESIGN_PAR_NOBS "`N'"
    global DIDDESIGN_PAR_NPERIODS "`n_periods'"
    global DIDDESIGN_PAR_TREATYEAR "`treat_year'"
    if `is_panel' {
        global DIDDESIGN_PAR_NUNITS "`n_units'"
    }
    else {
        capture macro drop DIDDESIGN_PAR_NUNITS
    }

    // Route: parallel or sequential bootstrap
    local parallel_actually_used = 0
    local n_workers_used = 0
    local n_boot_attempted = `nboot_val'

    if `use_kdid_path' {
        // Generalized K-DID path (kmax > 2)
        // Note: parallel bootstrap not yet supported for K>2; uses sequential
        mata: st_local("mata_rc", strofreal( ///
            _did_std_main_k((`lead_mata'), `nboot_val', `seboot_val', `level_val', `kmax_val', `jtest_on')))
    }
    else if `parallel_val' == 1 {
        // Parallel bootstrap via _diddesign_parallel_boot coordinator
        capture noisily _diddesign_parallel_boot,              ///
            `parallel_route_opts'                              ///
            seboot(`seboot_val') `quiet'
        local par_rc = _rc
        local parallel_actually_used = r(parallel_used)
        local n_workers_used = r(n_workers)
        capture macro drop DIDDESIGN_PAR_IDTIMEVAR DIDDESIGN_PAR_IDTIMESTDVAR ///
            DIDDESIGN_PAR_GIVAR DIDDESIGN_PAR_ITVAR DIDDESIGN_PAR_DELTAVAR ///
            DIDDESIGN_PAR_NOBS DIDDESIGN_PAR_NUNITS DIDDESIGN_PAR_NPERIODS ///
            DIDDESIGN_PAR_TREATYEAR

        if `par_rc' != 0 & `parallel_actually_used' != 0 {
            // Coordinator hard failure (not a graceful degradation)
            _dd_cleanup_fv, generated(`generated_covariates')
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

            // Count _boot_col* variables to determine column count
            local boot_ncols = 0
            foreach v of varlist _boot_col* {
                local ++boot_ncols
            }

            if `boot_ncols' > 0 & _N > 0 {
                // Transfer matrix to Mata via putmata
                unab boot_cols : _boot_col*
                putmata _par_boot_est = (`boot_cols'), replace

                restore
                capture erase "`boot_combined_file'"
                capture rmdir "`boot_tmpdir_path'"

                // Run GMM pipeline from pre-collected bootstrap
                mata: st_local("mata_rc", strofreal( ///
                    _did_std_main_from_boot((`lead_mata'), `seboot_val', `level_val')))
            }
            else {
                restore
                capture erase "`boot_combined_file'"
                capture rmdir "`boot_tmpdir_path'"
                // No valid bootstrap results; fall back to sequential.
                display as text "Note: Parallel bootstrap produced no valid results; falling back to sequential."
                local parallel_actually_used = 0
                mata: st_local("mata_rc", strofreal( ///
                    _did_std_main((`lead_mata'), `nboot_val', `seboot_val', `level_val')))
            }
        }
        else {
            // Graceful degradation to sequential
            mata: st_local("mata_rc", strofreal( ///
                _did_std_main((`lead_mata'), `nboot_val', `seboot_val', `level_val')))
        }
    }
    else {
        // Sequential bootstrap (existing Mata path for K=2, unchanged)
        mata: st_local("mata_rc", strofreal( ///
            _did_std_main((`lead_mata'), `nboot_val', `seboot_val', `level_val')))
    }

    if `mata_rc' != 0 {
        // Specific error messages are provided based on error code
        if `mata_rc' == 1 {
            display as error "E011: Estimation failed - insufficient valid bootstrap iterations"
            display as error "      Try increasing the number of bootstrap iterations (nboot option)"
        }
        else if `mata_rc' == 2 {
            display as error "E011: Estimation failed - bootstrap VCOV computation failed"
            display as error "      This may be caused by insufficient valid bootstrap samples"
        }
        else if `mata_rc' == 3 {
            display as error "E011: Estimation failed - insufficient jointly observed bootstrap draws for the posted multi-lead covariance"
            display as error "      Try estimating fewer lead() values or increasing nboot()"
        }
        else {
            display as error "E011: Estimation failed in Mata (error code: `mata_rc')"
        }
        _dd_cleanup_fv, generated(`generated_covariates')
        exit 498
    }
    
    // =========================================================================
    // SECTION 6: Store Estimation Results
    // =========================================================================
    // Results are stored in e() for post-estimation commands
    
    // --- Matrices ---
    // Matrices are retrieved from Mata first (before ereturn post clears them)
    tempname b_mat V_mat estimates_mat lead_mat weights_mat W_mat vcov_gmm_mat bootstrap_support_mat
    tempname b_post V_post
    
    mata: st_matrix("`b_mat'", _did_b)
    mata: st_matrix("`V_mat'", _did_V)
    mata: st_matrix("`estimates_mat'", _did_estimates)
    mata: st_matrix("`lead_mat'", _did_lead_values)
    mata: st_matrix("`weights_mat'", _did_weights)
    mata: st_matrix("`bootstrap_support_mat'", _did_bootstrap_support)
    
    // GMM weight matrix W and variance-covariance matrix of moment conditions
    mata: st_matrix("`W_mat'", _did_W)
    mata: st_matrix("`vcov_gmm_mat'", _did_vcov_gmm)
    
    // Estimation results are validated
    capture confirm matrix `lead_mat'
    if _rc != 0 {
        _dd_cleanup_fv, generated(`generated_covariates')
        display as error "Error: Estimation produced no valid results (lead_mat not found)"
        exit 498
    }
    if colsof(`lead_mat') == 0 {
        _dd_cleanup_fv, generated(`generated_covariates')
        display as error "Error: Estimation produced no valid results (lead_mat is empty)"
        exit 498
    }
    
    // For single lead, matrices are reshaped to KxK
    local n_lead = colsof(`lead_mat')
    if !`use_kdid_path' {
        // K=2 path: reshape to 2x2
        if `n_lead' == 1 {
            matrix `W_mat' = (`W_mat'[1,1], `W_mat'[1,3] \ `W_mat'[1,2], `W_mat'[1,4])
            matrix `vcov_gmm_mat' = (`vcov_gmm_mat'[1,1], `vcov_gmm_mat'[1,3] \ `vcov_gmm_mat'[1,2], `vcov_gmm_mat'[1,4])
        }
    }
    
    // Row and column names are set for e(b)
    local b_names ""
    if `use_kdid_path' {
        // K>2 path: 1 final + kmax components per lead
        foreach l of numlist `lead_val' {
            local b_names "`b_names' KDID:lead_`l'"
            forvalues kk = 1/`kmax_val' {
                local b_names "`b_names' k`kk':lead_`l'"
            }
        }
    }
    else {
        // K=2 path: 3 rows per lead (backward compatible)
        foreach l of numlist `lead_val' {
            local b_names "`b_names' dDID:lead_`l' DID:lead_`l' sDID:lead_`l'"
        }
    }
    // Leading space is trimmed
    local b_names = trim("`b_names'")
    matrix colnames `b_mat' = `b_names'
    
    // Row and column names are set for e(V)
    matrix rownames `V_mat' = `b_names'
    matrix colnames `V_mat' = `b_names'
    
    // e(b) / e(V) cannot contain missing values. When some estimators are not
    // identified, they are retained as missing in e(estimates) but omitted from
    // the posted coefficient vector and variance matrix.
    local post_idx ""
    forvalues j = 1/`=colsof(`b_mat')' {
        local b_val = el(`b_mat', 1, `j')
        local v_val = el(`V_mat', `j', `j')
        if !missing(`b_val') & !missing(`v_val') {
            local post_idx "`post_idx' `j'"
        }
    }
    local post_idx = trim("`post_idx'")
    local post_ncoef : word count `post_idx'
    
    if `post_ncoef' == 0 {
        _dd_cleanup_fv, generated(`generated_covariates')
        display as error "E011: Estimation failed - no estimable coefficients remain after handling missing components"
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

    local posted_leads ""
    local unidentified_leads ""
    local posted_lead_pos ""
    local requested_n_lead : word count `requested_lead_val'
    local current_n_lead : word count `lead_val'
    forvalues req_i = 1/`requested_n_lead' {
        local req_lead : word `req_i' of `requested_lead_val'
        local current_pos 0
        forvalues cur_i = 1/`current_n_lead' {
            local cur_lead : word `cur_i' of `lead_val'
            if "`cur_lead'" == "`req_lead'" {
                local current_pos = `cur_i'
            }
        }
        local lead_posted 0
        if `current_pos' > 0 {
            if `use_kdid_path' {
                local _block_size = 1 + `kmax_val'
            }
            else {
                local _block_size = 3
            }
            local block_start = `_block_size' * (`current_pos' - 1) + 1
            local block_end = `block_start' + `_block_size' - 1
            foreach coef_idx of local post_idx {
                if `coef_idx' >= `block_start' & `coef_idx' <= `block_end' {
                    local lead_posted = 1
                }
            }
        }
        if `lead_posted' {
            local posted_leads "`posted_leads' `req_lead'"
            if `current_pos' > 0 {
                local posted_lead_pos "`posted_lead_pos' `current_pos'"
            }
        }
        else {
            local unidentified_leads "`unidentified_leads' `req_lead'"
        }
    }
    local posted_leads : list retokenize posted_leads
    local unidentified_leads : list retokenize unidentified_leads
    local posted_lead_pos : list retokenize posted_lead_pos
    local n_lead_posted : word count `posted_leads'

    tempname lead_posted_mat
    local posted_lead_pos_mata = subinstr("`posted_lead_pos'", " ", ", ", .)
    mata: idx = (`posted_lead_pos_mata')
    mata: st_matrix("`lead_posted_mat'", st_matrix("`lead_mat'")[1, idx])
    mata: mata drop idx

    local identified_leads "`posted_leads'"
    local n_lead_identified = `n_lead_posted'
    
    // Reconstruct the estimation sample from the retained lead windows and the
    // same listwise-deletion rules used by the DID/sDID regressions. This keeps
    // e(sample), e(N), and the header aligned with observations that actually
    // enter at least one component estimator, rather than the raw time window.
    tempvar std_esample cluster_support_tag
    tempvar std_cov_complete
    quietly gen byte `std_esample' = 0
    quietly gen byte `std_cov_complete' = 0
    quietly replace `std_cov_complete' = 1 if `touse'
    if "`covariates_list'" != "" {
        quietly markout `std_cov_complete' `covariates_list'
    }
    foreach l of numlist `identified_leads' {
        quietly replace `std_esample' = 1 if `touse' ///
            & (`did_id_time_std_var' == -1 | `did_id_time_std_var' == `l') ///
            & `std_cov_complete' == 1 ///
            & !missing(`did_gi_var') ///
            & !missing(`did_it_var') ///
            & (!missing(`outcome') | !missing(`did_outcome_delta_var'))
    }
    quietly count if `std_esample' == 1 & `touse'
    local N_support = r(N)
    if "`cluster_guard_var'" != "" {
        quietly egen `cluster_support_tag' = tag(`cluster_guard_var') if `std_esample' == 1 & `touse' & !missing(`cluster_guard_var')
        quietly count if `cluster_support_tag' == 1 & `std_esample' == 1 & `touse' & !missing(`cluster_guard_var')
        local n_clusters_support = r(N)
        if `n_clusters_support' < 2 {
            _dd_cleanup_fv, generated(`generated_covariates')
            display as error "E003: At least 2 clusters are required for bootstrap inference"
            display as error "      Found only `n_clusters_support' unique cluster in the final posted lead support sample"
            exit 198
        }
    }
    else {
        local n_clusters_support = .
    }

    _dd_cleanup_fv, generated(`generated_covariates')
    
    // Coefficient vector and variance-covariance matrix are posted
    ereturn post `b_post' `V_post', esample(`std_esample') obs(`N_support') depname("`outcome'")
    
    ereturn local properties "b V"
    
    // --- Scalars ---
    if `is_panel' {
        ereturn scalar n_units = `n_units'
    }
    ereturn scalar n_periods = `n_periods'
    ereturn scalar n_boot = `nboot_val'
    if `n_clusters_support' < . {
        ereturn scalar n_clusters = `n_clusters_support'
    }
    ereturn scalar level = `level_val'
    ereturn scalar n_lead = `n_lead_identified'
    ereturn scalar n_lead_requested = `n_lead_requested'
    ereturn scalar n_lead_filtered = `n_lead_filtered'
    ereturn scalar n_lead_identified = `n_lead_identified'
    ereturn scalar is_panel = `is_panel'
    ereturn scalar seboot = `seboot_val'
    ereturn scalar kmax = `kmax_val'
    ereturn scalar jtest_on = `jtest_on'
    ereturn scalar parallel = `parallel_actually_used'
    if `parallel_actually_used' {
        ereturn scalar n_workers = `n_workers_used'
        ereturn scalar n_boot_attempted = `n_boot_attempted'
    }
    
    // Always expose bootstrap success counts for auditability.
    mata: st_local("n_boot_success", strofreal(_did_n_boot_success))
    if "`n_boot_success'" != "" & "`n_boot_success'" != "." {
        ereturn scalar n_boot_success = `n_boot_success'
    }
    
    // --- Macros ---
    ereturn local cmd "diddesign"
    ereturn local cmdline "`cmdline'"
    ereturn local design "`design_val'"
    ereturn local depvar "`outcome'"
    ereturn local treatment "`treatment_var'"
    ereturn local covariates "`covariates_spec'"
    ereturn local covars "`covariates_spec'"
    ereturn local sample_ifin `"`if' `in'"'
    ereturn local id "`id_var_orig'"
    ereturn local time "`time_var_orig'"
    ereturn local post "`post_var_orig'"
    if `is_panel' {
        ereturn local datatype "panel"
    }
    else {
    ereturn local datatype "rcs"
    }
    ereturn local clustvar "`cluster_var_report'"
    ereturn local lead "`identified_leads'"
    ereturn local requested_lead "`requested_lead_val'"
    ereturn local filtered_lead "`filtered_leads'"
    ereturn local identified_lead "`identified_leads'"
    ereturn local unidentified_lead "`unidentified_leads'"
    
    if `seboot_val' {
        ereturn local ci_method "bootstrap"
    }
    else {
        ereturn local ci_method "asymptotic"
    }
    
    // --- Additional Matrices (stored using ereturn matrix after ereturn post) ---
    // Row and column names are set for e(estimates)
    local est_rownames ""
    if `use_kdid_path' {
        foreach l of numlist `lead_val' {
            local est_rownames "`est_rownames' final:lead_`l'"
            forvalues kk = 1/`kmax_val' {
                local est_rownames "`est_rownames' k`kk':lead_`l'"
            }
        }
        local est_rownames = trim("`est_rownames'")
        matrix rownames `estimates_mat' = `est_rownames'
        matrix colnames `estimates_mat' = lead estimate std_error ci_lo ci_hi weight component_k selected_jtest selected_final dropped_jtest dropped_numerical K_init K_sel K_final
    }
    else {
        foreach l of numlist `lead_val' {
            local est_rownames "`est_rownames' dDID:lead_`l' DID:lead_`l' sDID:lead_`l'"
        }
        local est_rownames = trim("`est_rownames'")
        matrix rownames `estimates_mat' = `est_rownames'
        matrix colnames `estimates_mat' = lead estimate std_error ci_lo ci_hi weight
    }
    
    // Names are set for e(lead_values)
    matrix colnames `lead_posted_mat' = `identified_leads'
    
    // Names are set for e(weights)
    local wt_rownames ""
    foreach l of numlist `lead_val' {
        local wt_rownames "`wt_rownames' lead_`l'"
    }
    local wt_rownames = trim("`wt_rownames'")
    matrix rownames `weights_mat' = `wt_rownames'
    if `use_kdid_path' {
        local wt_colnames ""
        forvalues kk = 1/`kmax_val' {
            local wt_colnames "`wt_colnames' w_k`kk'"
        }
        matrix colnames `weights_mat' = `wt_colnames'
    }
    else {
        matrix colnames `weights_mat' = w_did w_sdid
    }
    matrix rownames `bootstrap_support_mat' = `wt_rownames'
    
    // A copy of estimates_mat is made for display (before ereturn matrix moves it)
    tempname display_mat
    matrix `display_mat' = `estimates_mat'
    
    // Additional matrices are stored
    ereturn matrix estimates = `estimates_mat'
    ereturn matrix lead_values = `lead_posted_mat'
    ereturn matrix weights = `weights_mat'
    ereturn matrix W = `W_mat'
    ereturn matrix vcov_gmm = `vcov_gmm_mat'
    ereturn matrix bootstrap_support = `bootstrap_support_mat'
    
    // K-DID specific matrices
    if `use_kdid_path' {
        tempname k_summary_mat moment_sel_mat moment_dj_mat moment_dn_mat jtest_stats_mat
        mata: st_matrix("`k_summary_mat'", _did_k_summary)
        mata: st_matrix("`moment_sel_mat'", _did_moment_selected)
        mata: st_matrix("`moment_dj_mat'", _did_moment_dropped_jtest)
        mata: st_matrix("`moment_dn_mat'", _did_moment_dropped_numerical)
        mata: st_matrix("`jtest_stats_mat'", _did_jtest_stats)
        matrix rownames `k_summary_mat' = `wt_rownames'
        matrix colnames `k_summary_mat' = K_init K_sel K_final
        matrix colnames `jtest_stats_mat' = J_stat J_df J_pval
        matrix rownames `jtest_stats_mat' = `wt_rownames'
        ereturn matrix k_summary = `k_summary_mat'
        ereturn matrix moment_selected = `moment_sel_mat'
        ereturn matrix moment_dropped_jtest = `moment_dj_mat'
        ereturn matrix moment_dropped_numerical = `moment_dn_mat'
        ereturn matrix jtest_stats = `jtest_stats_mat'
    }
    
    if `post_ncoef' < colsof(`b_mat') {
        display as text "Note: Some estimators are not identified for the requested lead(s)."
        display as text "      They are stored as missing in e(estimates) and omitted from e(b) and e(V)."
    }
    
    // =========================================================================
    // SECTION 7: Display Results
    // =========================================================================
    
    // Header is displayed
    if `is_panel' {
        local datatype "Panel"
        _diddesign_display_header, cmd("diddesign") design("std") ///
            datatype("`datatype'") n(`N_support') n_units(`n_units') ///
            n_periods(`n_periods') n_boot(`nboot_val') cluster("`cluster_var_report'")
    }
    else {
        local datatype "Repeated Cross-Section"
        _diddesign_display_header, cmd("diddesign") design("std") ///
            datatype("`datatype'") n(`N_support') ///
            n_periods(`n_periods') n_boot(`nboot_val') cluster("`cluster_var_report'")
    }
    
    // Confidence interval method is displayed
    display as text ""
    if `seboot_val' {
        display as text "Confidence intervals: Bootstrap percentile (`level_val'%)"
    }
    else {
        display as text "Confidence intervals: Asymptotic (`level_val'%)"
    }
    
    if `use_kdid_path' {
        display as text "Generalized K-DID: kmax = `kmax_val'" _continue
        if `jtest_on' {
            display as text ", J-test = on"
        }
        else {
            display as text ""
        }
    }
    
    // Results table is displayed
    display as text ""
    display as text "{hline 78}"
    display as text %13s "Estimator" " | " %9s "Estimate" %10s "Std.Err." %20s "[`level_val'% Conf. Interval]" %9s "Weight"
    display as text "{hline 14}+{hline 64}"
    
    // Results are displayed for each lead value
    local row = 1
    foreach l of numlist `lead_val' {
        // Lead header is displayed
        display as text ""
        display as text "Lead = `l'"
        display as text "{hline 14}+{hline 64}"
        
        if `use_kdid_path' {
            // K-DID path: final + components
            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            local k_f = `display_mat'[`row', 14]
            _diddesign_display_result, label("K-DID (K=`k_f')") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1
            
            forvalues kk = 1/`kmax_val' {
                local est = `display_mat'[`row', 2]
                local se = `display_mat'[`row', 3]
                local ci_lo = `display_mat'[`row', 4]
                local ci_hi = `display_mat'[`row', 5]
                local wt = `display_mat'[`row', 6]
                if `kk' == 1 {
                    local klabel "DID (k=1)"
                }
                else if `kk' == 2 {
                    local klabel "sDID (k=2)"
                }
                else {
                    local klabel "k=`kk' DID"
                }
                _diddesign_display_result, label("`klabel'") ///
                    estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
                local row = `row' + 1
            }
        }
        else {
            // K=2 path: backward compatible display
            // Double DID
            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            _diddesign_display_result, label("Double DID") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1
            
            // DID
            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            _diddesign_display_result, label("DID") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1
            
            // sDID
            local est = `display_mat'[`row', 2]
            local se = `display_mat'[`row', 3]
            local ci_lo = `display_mat'[`row', 4]
            local ci_hi = `display_mat'[`row', 5]
            local wt = `display_mat'[`row', 6]
            _diddesign_display_result, label("sDID") ///
                estimate(`est') se(`se') ci_low(`ci_lo') ci_high(`ci_hi') weight(`wt')
            local row = `row' + 1
        }
    }
    
    display as text "{hline 78}"
    
    // Notes are displayed
    display as text ""
    if `use_kdid_path' {
        display as text "Note: K-DID combines k=1,...,K components using optimal GMM weights."
        display as text "      Weight column shows GMM weights for each component."
    }
    else {
        display as text "Note: Double DID combines DID and sDID using optimal GMM weights."
        display as text "      Weight column shows GMM weights (w_did for DID, w_sdid for sDID)."
    }
    
end

program define _dd_cleanup_fv
    version 16.0
    syntax, [generated(string asis)]

    if "`generated'" != "" {
        capture drop `generated'
    }
end
