*! diddesign_check.ado - Diagnostic tests for parallel trends assumption
*!
*! Implements placebo tests for assessing the parallel trends assumption in
*! difference-in-differences designs. Computes standardized pre-treatment DID
*! estimates and equivalence confidence intervals for both standard DID and
*! staggered adoption designs.

program define diddesign_check, eclass
    version 16.0

    // Clear stale estimation results before any validation or setup failure.
    ereturn clear
    
    // -------------------------------------------------------------------------
    // Load Mata Functions
    // -------------------------------------------------------------------------
    capture mata: _did_check_tail_loaded()
    if _rc != 0 {
        local mata_loaded = 0
        
        // Method 1: Direct findfile for diddesign_mata.do (works after net install)
        qui capture findfile diddesign_mata.do
        if _rc == 0 {
            quietly do "`r(fn)'"
            local mata_loaded = 1
        }
        
        // Method 2: Relative path from ado file (works in development environment)
        if !`mata_loaded' {
            qui capture findfile diddesign_check.ado
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
            capture mata: _did_check_tail_loaded()
            if _rc != 0 {
                display as error "E001: DIDdesign diagnostic Mata functions not fully loaded"
                display as error "The did_check.mata tail sentinel is unavailable."
                display as error "Solutions:"
                display as error "  1. Reinstall: net install diddesign, from(...) replace"
                display as error "  2. Or manually: do {path}/diddesign_mata.do"
                exit 198
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Syntax Parsing
    // -------------------------------------------------------------------------
    // Supports both panel data (with id()) and repeated cross-section (with post())
    // Standardization is always performed, returning both standardized and raw estimates
    syntax anything(name=rawvars) [if] [in], ///
        TREATment(varname)              /// Required: treatment indicator
        TIME(varname)                   /// Required: time identifier
        [ID(varname)]                   /// Unit identifier (required for panel)
        [POST(varname)]                 /// Post-treatment indicator (required for RCS)
        [DESIGN(string)]                /// Design type: "did" (default) or "sa"
        [PANEL]                         /// Panel data format
        [RCS]                           /// Repeated cross-section format
        [CLuster(varname)]              /// Cluster variable for SEs
        [NBoot(integer 30)]             /// Bootstrap iterations; default is 30
        [LAG(numlist >=0 integer)]      /// Lag values for placebo tests
        [THRes(integer 2)]              /// SA threshold; default is 2
        [PARALlel]                      /// Use parallel computing
        [SEED(integer -1)]              /// Random seed (-1 = not specified)
        [QUIET]                         /// Suppress progress display
    
    // Store full command line for e(cmdline)
    local cmdline "diddesign_check `0'"
    local id_orig "`id'"
    local time_orig "`time'"
    local post_orig "`post'"
    
    // -------------------------------------------------------------------------
    // Parse Variable List
    // -------------------------------------------------------------------------
    // The varlist contains the outcome variable followed by optional covariates
    gettoken depvar covariates : rawvars
    
    // Handle covariates (may be empty)
    if "`covariates'" == "" {
        local covars_str ""
    }
    else {
        local covars_str "`covariates'"
    }
    
    // -------------------------------------------------------------------------
    // Duplicate Covariate Check
    // -------------------------------------------------------------------------
    // Remove duplicate covariates to ensure proper model specification
    if "`covars_str'" != "" {
        local unique_covars : list uniq covars_str
        local n_all : word count `covars_str'
        local n_unique : word count `unique_covars'
        
        if `n_unique' < `n_all' {
            // Find duplicate variables by comparing original and unique lists
            local dups ""
            local seen ""
            foreach v of local covars_str {
                local is_seen : list v in seen
                if `is_seen' {
                    local is_dup : list v in dups
                    if !`is_dup' {
                        local dups "`dups' `v'"
                    }
                }
                local seen "`seen' `v'"
            }
            local dups = strtrim("`dups'")
            display as text "Warning: Duplicate covariates detected and removed: `dups'"
            local covars_str "`unique_covars'"
        }
    }
    local covars_spec : list retokenize covars_str
    
    // -------------------------------------------------------------------------
    // Early Validation: Treatment Variable
    // -------------------------------------------------------------------------
    // Verify treatment is numeric before expensive operations.
    capture confirm numeric variable `treatment'
    if _rc {
        display as error "E017: Variable `treatment' must be numeric"
        exit _rc
    }
    
    // -------------------------------------------------------------------------
    // Factor Variable Expansion
    // -------------------------------------------------------------------------
    // Expand factor variables (i.var, ibn.var) into dummy variables
    // Base category is excluded to avoid collinearity with intercept
    if "`covars_str'" != "" {
        // Create temporary sample marker for factor expansion
        marksample touse_temp, novarlist
        markout `touse_temp' `treatment' `time', strok
        if "`id'" != "" {
            markout `touse_temp' `id', strok
        }

        quietly _diddesign_expand_covariates, covars(`covars_str') touse(`touse_temp')
        local covars_str "`r(varlist)'"
        local generated_covariates "`r(generated_vars)'"
        local encoded_string_covariates "`r(encoded_sources)'"
        local n_fv_expanded = r(n_factor_expanded)

        foreach covar_name of local encoded_string_covariates {
            display as text "Note: String factor covariate `covar_name' automatically encoded to numeric"
        }

        if `n_fv_expanded' > 0 {
            display as text "Note: Factor variables expanded to `n_fv_expanded' dummy variables (base/constant columns excluded)"
        }
    }
    
    // -------------------------------------------------------------------------
    // Set Default Values
    // -------------------------------------------------------------------------
    // Default design: standard DID
    if "`design'" == "" {
        local design "did"
    }
    else {
        local design = lower("`design'")
    }

    local thres_specified = strpos(lower("`0'"), "thres(") > 0
    if `thres_specified' & "`design'" != "sa" {
        display as error "E002: thres() is only allowed with design(sa)"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // Default lag: 1 period
    if "`lag'" == "" {
        local lag "1"
    }

    local unique_lags : list uniq lag
    local n_lag_all : word count `lag'
    local n_lag_unique : word count `unique_lags'
    if `n_lag_unique' < `n_lag_all' {
        local duplicate_lags ""
        local seen_lags ""
        foreach l of numlist `lag' {
            local lag_token "`l'"
            local already_seen : list lag_token in seen_lags
            if `already_seen' {
                local already_listed : list lag_token in duplicate_lags
                if !`already_listed' {
                    local duplicate_lags "`duplicate_lags' `lag_token'"
                }
            }
            else {
                local seen_lags "`seen_lags' `lag_token'"
            }
        }
        local duplicate_lags = strtrim("`duplicate_lags'")
        display as error "E002: Option lag() contains duplicate values: `duplicate_lags'"
        display as error "       Each placebo lag may be requested at most once"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // Bootstrap iterations: defaults to 30
    local nboot_val = `nboot'
    
    // Staggered adoption threshold: defaults to 2
    local thres_val = `thres'
    
    // Random seed: -1 indicates user did not specify
    if `seed' == -1 {
        local seed_val = .
    }
    else {
        local seed_val = `seed'
    }
    
    // Quiet option - suppress bootstrap progress display
    local quiet_val = 0
    if "`quiet'" != "" {
        local quiet_val = 1
    }
    
    // Parallel option is not yet implemented; bootstrap runs sequentially
    if "`parallel'" != "" {
        display as text "{p 0 4 2}"
        display as text "Note: The {bf:parallel} option is currently not implemented. "
        display as text "Bootstrap iterations will run sequentially.{p_end}"
    }
    
    // -------------------------------------------------------------------------
    // Validate Data Type
    // -------------------------------------------------------------------------
    // Determine data type: panel vs repeated cross-section (RCS)
    // Panel and rcs options are mutually exclusive
    local is_panel_opt = ("`panel'" != "")
    local is_rcs_opt = ("`rcs'" != "")

    if "`id'" != "" & "`post'" != "" {
        display as error "E016: Options id() and post() are mutually exclusive"
        display as error "      Use id() for panel data or post() for repeated cross-section data"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    if `is_panel_opt' & `is_rcs_opt' {
        display as error "E016: Options panel and rcs are mutually exclusive"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // Determine data type (auto-detect if neither specified)
    local is_panel = 0
    if `is_panel_opt' {
        local is_panel = 1
    }
    else if `is_rcs_opt' {
        local is_panel = 0
    }
    else {
        // Auto-detect: panel if id() is specified, RCS if post() is specified
        if "`id'" != "" {
            local is_panel = 1
        }
        else if "`post'" != "" {
            local is_panel = 0
        }
        else {
            // Neither id() nor post() specified - require explicit choice
            display as error "E016: Must specify id() for panel data or post() for RCS data"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }
    }

    if `is_panel' & "`post'" != "" {
        display as error "E016: Option post() is only valid for RCS data"
        display as error "      Remove post() or re-run without panel/id()"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }

    if !`is_panel' & "`id'" != "" {
        display as error "E016: Option id() is only valid for panel data"
        display as error "      Remove id() or re-run with the panel option"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }

    // Validate required options based on data type
    if `is_panel' {
        // Panel data requires id()
        if "`id'" == "" {
            display as error "E001: Option id() is required for panel data"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }
    }
    else {
        // RCS data requires post() to identify treatment timing
        if "`post'" == "" {
            display as error "E001: Option post() is required for RCS data"
            display as error "       Specify the post-treatment indicator variable"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }
    }
    
    // -------------------------------------------------------------------------
    // Validate Parameters
    // -------------------------------------------------------------------------
    // nboot >= 2 required for variance estimation (denominator is n_boot - 1)
    if `nboot_val' < 2 {
        display as error "E002: Option nboot() must be at least 2 for variance estimation"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // Validate thres >= 1 (only used in SA design)
    if `thres_val' < 1 {
        display as error "E002: Option thres() must be a positive integer >= 1"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // Validate seed range if specified (must be in [0, 2147483647])
    if `seed' != -1 & (`seed' < 0 | `seed' > 2147483647) {
        display as error "E002: Option seed() must be a valid integer (0 to 2147483647)"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // -------------------------------------------------------------------------
    // Validate Design Type
    // -------------------------------------------------------------------------
    if !inlist("`design'", "did", "sa") {
        display as error "E002: design() must be 'did' or 'sa'"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // -------------------------------------------------------------------------
    // Handle Cluster Variable
    // -------------------------------------------------------------------------
    // For panel data, default cluster to unit identifier if not specified
    local clustvar "`cluster'"
    if "`clustvar'" == "" & `is_panel' & "`id'" != "" {
        local clustvar "`id'"
    }
    local clustvar_report "`cluster'"
    if "`clustvar_report'" == "" {
        if `is_panel' & "`id'" != "" {
            local clustvar_report "`id'"
        }
        else if !`is_panel' {
            display as error "E018: cluster() is required for RCS data"
            display as error "      Specify cluster() at the treatment-assignment level for bootstrap inference"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }
    }
    
    // -------------------------------------------------------------------------
    // Validate SA Design Requires Panel Data
    // -------------------------------------------------------------------------
    // Staggered adoption design only supports panel data structure
    if "`design'" == "sa" & !`is_panel' {
        display as error "E014: SA design requires panel data"
        display as error "       Only the standard DID design supports RCS data"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // -------------------------------------------------------------------------
    // Mark Sample
    // -------------------------------------------------------------------------
    marksample touse, novarlist
    markout `touse' `depvar' `treatment' `time', strok
    // Panel data: mark out missing id
    if `is_panel' & "`id'" != "" {
        markout `touse' `id', strok
    }
    // RCS data: mark out missing post indicator
    if !`is_panel' & "`post'" != "" {
        markout `touse' `post', strok
    }
    // cluster() affects placebo/bootstrap inference, not the diagnostic sample.
    // Missing cluster values are handled in the cluster-support guards below.
    // Keep covariate-missing rows in the diagnostic sample so baseline control
    // standardization uses the full outcome distribution. Regression-stage
    // listwise deletion is handled in Mata.
    
    // Count observations
    quietly count if `touse'
    local N = r(N)
    
    if `N' == 0 {
        display as error "E003: No observations"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 2000
    }
    
    // -------------------------------------------------------------------------
    // Canonicalize Treatment Variable
    // -------------------------------------------------------------------------
    // Near-binary treatment values within tolerance are mapped to exact 0/1
    // before any downstream validation or Mata calls.
    local treatment_orig "`treatment'"
    tempvar treatment_work
    quietly gen double `treatment_work' = . if `touse'
    quietly replace `treatment_work' = 0 if abs(`treatment_orig') < 1e-6 & `touse'
    quietly replace `treatment_work' = 1 if abs(`treatment_orig' - 1) < 1e-6 & `touse'

    quietly count if missing(`treatment_work') & `touse'
    if r(N) > 0 {
        display as error "E003: Treatment variable must be binary (0/1)"
        display as error "      Found `r(N)' observations outside the 1e-6 tolerance around 0/1"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }

    quietly count if `treatment_work' == 1 & `touse'
    if r(N) == 0 {
        display as error "E003: No treated observations found in data (treatment all 0)"
        display as error "       Placebo tests require at least one treated unit"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    quietly count if `treatment_work' == 0 & `touse'
    if r(N) == 0 {
        display as error "E003: No control observations found in data (treatment all 1)"
        display as error "       Placebo tests require at least one control unit"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }

    local treatment "`treatment_work'"

    // -------------------------------------------------------------------------
    // Compute Number of Clusters
    // -------------------------------------------------------------------------
    if "`clustvar'" != "" {
        tempvar cluster_tag
        quietly egen `cluster_tag' = tag(`clustvar') if `touse' & !missing(`clustvar')
        quietly count if `cluster_tag' == 1 & `touse' & !missing(`clustvar')
        local n_clusters = r(N)
    }
    else {
        local n_clusters = `N'
    }

    // Cluster bootstrap inference requires at least two distinct clusters.
    if "`clustvar'" != "" & `n_clusters' < 2 {
        display as error "E003: At least 2 clusters are required for cluster bootstrap inference"
        display as error "      Found only `n_clusters' unique cluster in the estimation sample"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 198
    }
    
    // -------------------------------------------------------------------------
    // Set Random Seed
    // -------------------------------------------------------------------------
    if `seed_val' != . {
        set seed `seed_val'
    }
    
    // -------------------------------------------------------------------------
    // Validate Variables
    // -------------------------------------------------------------------------
    // Validate outcome variable
    capture confirm numeric variable `depvar'
    if _rc {
        display as error "E017: Variable `depvar' must be numeric"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit _rc
    }
    
    // Validate treatment variable
    capture confirm numeric variable `treatment'
    if _rc {
        display as error "E017: Variable `treatment' must be numeric"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit _rc
    }
    
    // Validate id variable (only for panel data)
    // String variables are automatically encoded to numeric
    if `is_panel' & "`id'" != "" {
        capture confirm variable `id'
        if _rc {
            display as error "E001: Variable `id' not found"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 111
        }
        // Check if string variable - auto convert using egen group()
        capture confirm string variable `id'
        if _rc == 0 {
            // String variable detected - create numeric encoding
            tempvar id_encoded
            quietly egen `id_encoded' = group(`id')
            display as text "Note: String variable `id' automatically encoded to numeric"
            local id "`id_encoded'"
        }
        else {
            capture confirm numeric variable `id'
            if _rc {
                display as error "E017: Variable `id' must be numeric or string"
                _ddcheck_cleanup, vars(`generated_covariates')
                exit _rc
            }
        }
    }
    
    // Validate time variable
    // String time variables are encoded to numeric period indices using the
    // same sorted-factor-order contract as the main diddesign command and the
    // reference R implementation.
    capture confirm variable `time'
    if _rc {
        display as error "E001: Variable `time' not found"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 111
    }
    capture confirm string variable `time'
    if _rc == 0 {
        local time_order_mismatch_n = 0
        tempvar time_guard_touse
        quietly gen byte `time_guard_touse' = `touse'
        if "`covars_str'" != "" {
            quietly markout `time_guard_touse' `covars_str'
        }
        preserve
            quietly keep if `time_guard_touse'
            keep `time'
            tempvar time_first_idx time_alpha_idx time_seen_idx
            tempvar time_num_suffix time_prefix time_suffix_tag time_suffix_prefix_tag
            quietly gen long `time_first_idx' = _n
            quietly bysort `time' (`time_first_idx'): keep if _n == 1
            quietly egen long `time_alpha_idx' = group(`time')
            quietly sort `time_first_idx'
            quietly gen long `time_seen_idx' = _n
            quietly count if `time_alpha_idx' != `time_seen_idx'
            local time_order_mismatch_n = r(N)
            quietly gen double `time_num_suffix' = .
            quietly replace `time_num_suffix' = real(regexs(1)) if regexm(`time', "([0-9]+)$")
            quietly gen str244 `time_prefix' = ""
            quietly replace `time_prefix' = regexr(`time', "[0-9]+$", "") if regexm(`time', "([0-9]+)$")
            quietly egen byte `time_suffix_tag' = tag(`time')
            quietly count if missing(`time_num_suffix') & `time_suffix_tag' == 1
            local time_suffix_missing_n = r(N)
            local time_suffix_prefix_count = 0
            local time_suffix_order_mismatch_n = 0
            if `time_suffix_missing_n' == 0 {
                quietly egen byte `time_suffix_prefix_tag' = tag(`time_prefix') if `time_suffix_tag' == 1
                quietly count if `time_suffix_prefix_tag' == 1
                local time_suffix_prefix_count = r(N)
                if `time_suffix_prefix_count' == 1 {
                    quietly sort `time_num_suffix' `time'
                    quietly gen long time_numeric_idx = _n
                    quietly count if `time_alpha_idx' != time_numeric_idx
                    local time_suffix_order_mismatch_n = r(N)
                }
            }
        restore
        if `time_order_mismatch_n' > 0 | `time_suffix_order_mismatch_n' > 0 {
            display as error "E002: Ambiguous string time order detected for `time'"
            display as error "      Automatic encoding would reorder observed time labels lexicographically"
            display as error "      Recode time() to numeric or lexically ordered strings before estimation"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }
        tempvar time_encoded
        quietly egen `time_encoded' = group(`time')
        display as text "Note: String variable `time' automatically encoded to numeric"
        local time "`time_encoded'"
    }
    else {
        capture confirm numeric variable `time'
        if _rc {
            display as error "E017: Variable `time' must be numeric or string"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit _rc
        }
    }

    // Validate that panel samples still contain at least one control unit
    // after any if/in restriction is applied and after string IDs are encoded.
    if `is_panel' & "`id'" != "" {
        tempvar did_dup_cell
        quietly bysort `id' `time': gen byte `did_dup_cell' = (_N > 1) if `touse'
        quietly count if `did_dup_cell' == 1 & `touse'
        if r(N) > 0 {
            display as error "E003: Panel data must be uniquely identified by id() and time()"
            display as error "      Found duplicate unit-time observations in the estimation sample"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 459
        }

        if "`design'" == "sa" {
            tempvar did_unit_tag did_time_tag
            quietly egen `did_unit_tag' = tag(`id') if `touse'
            quietly count if `did_unit_tag' == 1 & `touse'
            local n_units_sa = r(N)

            quietly egen `did_time_tag' = tag(`time') if `touse'
            quietly count if `did_time_tag' == 1 & `touse'
            local n_periods_sa = r(N)

            local expected_cells_sa = `n_units_sa' * `n_periods_sa'
            if `N' != `expected_cells_sa' {
                display as error "E003: SA design requires a balanced panel with one observation per id() x time() cell"
                display as error "      Found `N' observations but expected `expected_cells_sa' from `n_units_sa' units x `n_periods_sa' periods"
                display as error "      Resolve missing or duplicated unit-time cells before using design(sa)"
                _ddcheck_cleanup, vars(`generated_covariates')
                exit 459
            }
        }

        if "`design'" == "did" {
            tempvar treat_lag treat_diff
            quietly bysort `id' (`time'): gen double `treat_lag' = `treatment'[_n-1] if `touse'
            quietly gen double `treat_diff' = `treatment' - `treat_lag' if `touse' & `treat_lag' < .
            quietly count if `treat_diff' < 0 & `touse'
            if r(N) > 0 {
                display as error "E003: Treatment variable must be cumulative (absorbing)"
                display as error "      Found `r(N)' observations with treatment decreasing over time"
                display as error "      Standard DID placebo checks require treatment to remain 1 once it starts"
                _ddcheck_cleanup, vars(`generated_covariates')
                exit 459
            }

            tempvar first_treat_obs first_treat_unit unit_treat_tag
            quietly gen double `first_treat_obs' = `time' if `treatment' == 1 & `touse'
            quietly egen double `first_treat_unit' = min(`first_treat_obs') if `touse', by(`id')
            quietly egen `unit_treat_tag' = tag(`id') if `touse' & `first_treat_unit' < .
            quietly levelsof `first_treat_unit' if `unit_treat_tag' == 1 & `touse', local(first_treat_levels)
            local n_treat_times : word count `first_treat_levels'
            if `n_treat_times' > 1 {
                display as error "E003: Staggered adoption detected under the standard DID design"
                display as error "      Treated units do not share a common treatment adoption time"
                display as error "      Re-run with design(sa) for staggered-adoption placebo checks"
                _ddcheck_cleanup, vars(`generated_covariates')
                exit 459
            }
        }

        tempvar Gi_check
        quietly egen `Gi_check' = max(`treatment') if `touse', by(`id')
        replace `Gi_check' = round(`Gi_check', 1) if `touse'

        quietly count if `Gi_check' == 0 & `touse'
        if r(N) == 0 {
            display as error "E003: No control units found in data (all units eventually treated)"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }
    }

    // Validate cluster variable
    // String variables are automatically encoded to numeric
    if "`clustvar'" != "" {
        capture confirm variable `clustvar'
        if _rc {
            display as error "E001: Variable `clustvar' not found"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 111
        }
        capture confirm string variable `clustvar'
        if _rc == 0 {
            tempvar cluster_encoded
            quietly egen `cluster_encoded' = group(`clustvar')
            display as text "Note: String variable `clustvar' automatically encoded to numeric"
            local clustvar "`cluster_encoded'"
        }
        else {
            capture confirm numeric variable `clustvar'
            if _rc {
                display as error "E017: Variable `clustvar' must be numeric or string"
                _ddcheck_cleanup, vars(`generated_covariates')
                exit _rc
            }
        }
    }
    
    // Validate post variable (only for RCS data)
    if !`is_panel' & "`post'" != "" {
        capture confirm numeric variable `post'
        if _rc {
            display as error "E017: Variable `post' must be numeric"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit _rc
        }
        
        tempvar post_work
        quietly gen double `post_work' = . if `touse'
        quietly replace `post_work' = 0 if abs(`post') < 1e-6 & `touse'
        quietly replace `post_work' = 1 if abs(`post' - 1) < 1e-6 & `touse'

        quietly count if missing(`post_work') & `touse'
        if r(N) > 0 {
            display as error "E003: Post-treatment indicator must be binary (0/1)"
            display as error "      Found `r(N)' observations outside the 1e-6 tolerance around 0/1"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }

        quietly tab `post_work' if `touse'
        if r(r) > 2 {
            display as error "E003: Post-treatment indicator must be binary (0/1)"
            display as error "       Found " r(r) " distinct values after tolerance canonicalization (expected 2)"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }

        quietly summarize `post_work' if `touse'
        local post_min_round = r(min)
        local post_max_round = r(max)
        
        // Ensure both 0 and 1 values exist for valid DID estimation
        if r(min) == r(max) {
            if `post_min_round' == 0 {
                display as error "E003: Post-treatment indicator is all 0 (no post-treatment observations)"
                display as error "       Placebo tests require at least one post-treatment period"
            }
            else {
                display as error "E003: Post-treatment indicator is all 1 (no pre-treatment observations)"
                display as error "       Placebo tests require at least one pre-treatment period"
            }
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 198
        }

        local post "`post_work'"
    }
    
    // Validate covariates
    if "`covars_str'" != "" {
        foreach var of local covars_str {
            capture confirm numeric variable `var'
            if _rc {
                display as error "E017: Variable `var' must be numeric"
                _ddcheck_cleanup, vars(`generated_covariates')
                exit _rc
            }
        }
    }

    // -------------------------------------------------------------------------
    // Validate SA Design Requires Absorbing Treatment Paths
    // -------------------------------------------------------------------------
    // Once treatment starts in the staggered adoption design, it must remain on
    // for all subsequent periods within the same unit.
    if `is_panel' {
        tempvar treat_bin treat_lag treat_diff
        quietly gen double `treat_bin' = round(`treatment', 1e-6) if `touse'
        quietly bysort `id' (`time'): gen double `treat_lag' = `treat_bin'[_n-1] if `touse'
        quietly gen double `treat_diff' = `treat_bin' - `treat_lag' if `touse' & `treat_lag' < .
        quietly count if `treat_diff' < 0 & `touse'
        if r(N) > 0 {
            display as error "E003: Treatment variable must be cumulative (absorbing)"
            display as error "      Found `r(N)' observations with treatment decreasing over time"
            display as error "      Panel DID designs require treatment to only transition from 0 to 1"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 459
        }
    }
    
    // -------------------------------------------------------------------------
    // Call Mata for Computation
    // -------------------------------------------------------------------------
    // Convert lag numlist to Mata format
    local lag_mata = subinstr("`lag'", " ", ", ", .)
    local n_lags : word count `lag'
    
    // Set id_var for Mata (empty string for RCS)
    local id_var = ""
    if `is_panel' & "`id'" != "" {
        local id_var "`id'"
    }
    
    // Set post_var for Mata (empty string for panel)
    local post_var = ""
    if !`is_panel' & "`post'" != "" {
        local post_var "`post'"
    }
    
    // Call Mata main function for placebo test computation
    mata: _diddesign_check_main( ///
        "`depvar'",           ///
        "`treatment'",        ///
        "`id_var'",           ///
        "`time'",             ///
        "`post_var'",         ///
        "`covars_str'",       ///
        "`clustvar'",         ///
        "`touse'",            ///
        "`design'",           ///
        (`lag_mata'),         ///
        `nboot_val',          ///
        `thres_val',          ///
        `is_panel',           ///
        `quiet_val'           ///
    )

    // -------------------------------------------------------------------------
    // Store e() Returns
    // -------------------------------------------------------------------------
    // Retrieve scalar results before touching result matrices. Stata does not
    // materialize 0 x k Mata matrices as named matrices, so zero-lag cases
    // must be handled before st_matrix()/matrix rownames calls.
    mata: st_local("n_lags_valid", strofreal(_check_n_lags))
    mata: st_local("n_boot_valid", strofreal(_check_n_boot_valid))
    mata: st_local("filtered_lags", _check_filtered_lags)
    mata: st_local("max_preperiods", strofreal(_check_max_preperiods))
    mata: st_local("check_no_valid_periods", strofreal(_check_no_valid_periods))

    if "`design'" == "sa" & `check_no_valid_periods' == 1 {
        display as error "E011: SA placebo check failed - no valid periods found"
        display as error "      Try reducing the threshold value (thres option)"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 498
    }

    if `n_lags_valid' == 0 {
        local max_preperiods_int = int(`max_preperiods')
        local max_requested_lag = 0
        foreach lag_val of numlist `lag' {
            if `lag_val' > `max_requested_lag' {
                local max_requested_lag = `lag_val'
            }
        }

        display as error "E011: No feasible lag() values remain for placebo tests"
        display as error "      Current sample has only `max_preperiods_int' pre-treatment period(s)"
        display as error "      The requested lag window requires at least `=`max_requested_lag' + 1' pre-treatment periods"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 498
    }

    // Retrieve matrices from Mata
    tempname placebo_mat trends_mat Gmat_mat lag_support_mat cluster_support_mat

    mata: st_matrix("`placebo_mat'", _check_placebo)
    mata: st_matrix("`trends_mat'", _check_trends)
    mata: st_matrix("`lag_support_mat'", _check_n_boot_valid_lag)
    mata: st_local("n_posted_vcov", strofreal(rows(_check_posted_vcov)))
    
    tempname placebo_keep lag_support_keep row_tmp support_row_tmp b_post V_post
    local b_names ""
    local identified_lags ""
    local posted_lags ""
    local raw_only_lags ""
    local unidentified_lags ""
    local n_lags_identified 0
    local n_lags_posted 0
    if `n_lags_valid' > 0 {
        forvalues i = 1/`n_lags_valid' {
            local lag_i = `placebo_mat'[`i', 1]
            local lag_i_int = int(`lag_i')
            local est_i = `placebo_mat'[`i', 2]
            local se_i = `placebo_mat'[`i', 3]
            local est_orig_i = `placebo_mat'[`i', 4]
            local se_orig_i = `placebo_mat'[`i', 5]
            local n_valid_std_i = `lag_support_mat'[`i', 1]
            local n_valid_raw_i = `lag_support_mat'[`i', 2]

            if `n_valid_raw_i' < 2 | missing(`est_orig_i') | missing(`se_orig_i') {
                local unidentified_lags "`unidentified_lags' `lag_i_int'"
                continue
            }

            matrix `row_tmp' = `placebo_mat'[`i', 1...]
            matrix `placebo_keep' = nullmat(`placebo_keep') \ `row_tmp'
            matrix `support_row_tmp' = `lag_support_mat'[`i', 1...]
            matrix `lag_support_keep' = nullmat(`lag_support_keep') \ `support_row_tmp'
            local identified_lags "`identified_lags' `lag_i_int'"
            local ++n_lags_identified

            if `n_valid_std_i' < 2 | missing(`est_i') | missing(`se_i') {
                local raw_only_lags "`raw_only_lags' `lag_i_int'"
                continue
            }

            matrix `b_post' = nullmat(`b_post'), `est_i'
            local b_names "`b_names' placebo:lag_`lag_i_int'"
            local posted_lags "`posted_lags' `lag_i_int'"
            local ++n_lags_posted
        }
    }

    local b_names = trim("`b_names'")
    local identified_lags = trim("`identified_lags'")
    local posted_lags = trim("`posted_lags'")
    local raw_only_lags = trim("`raw_only_lags'")
    local unidentified_lags = trim("`unidentified_lags'")

    if `n_lags_identified' == 0 {
        display as error "E011: No identifiable lag() values remain for placebo tests"
        display as error "      Requested lags are time-feasible, but raw placebo inference is not identifiable after support checks, including valid bootstrap-draw requirements"
        _ddcheck_cleanup, vars(`generated_covariates')
        exit 498
    }

    matrix `placebo_mat' = `placebo_keep'
    matrix `lag_support_mat' = `lag_support_keep'
    matrix `cluster_support_mat' = J(`n_lags_identified', 1, .)

    // Set matrix row and column names for e(placebo)
    local placebo_rownames ""
    forvalues i = 1/`n_lags_identified' {
        local lag_i = `placebo_mat'[`i', 1]
        local lag_i_int = int(`lag_i')
        local placebo_rownames "`placebo_rownames' `lag_i_int'"
    }
    local placebo_rownames = trim("`placebo_rownames'")
    if "`placebo_rownames'" != "" {
        matrix rownames `placebo_mat' = `placebo_rownames'
        capture matrix rownames `lag_support_mat' = `placebo_rownames'
    }
    matrix colnames `placebo_mat' = lag estimate std_error estimate_orig std_error_orig EqCI95_LB EqCI95_UB
    capture matrix colnames `lag_support_mat' = n_boot_valid_std n_boot_valid_raw
    
    // Set matrix column names for e(trends)
    matrix colnames `trends_mat' = id_time_std Gi outcome_mean outcome_sd n_obs
    
    // Post placeholder estimation results so that estimates store/restore works.
    // The posted coefficient vector uses standardized placebo estimates, while
    // e(placebo) retains the filtered diagnostic table used by diddesign_plot.
    local placeholder_posted = 0
    if `n_lags_posted' == 0 {
        matrix `b_post' = 0
        matrix `V_post' = 0
        // Keep a stable sentinel name for the internal placeholder matrix so
        // downstream callers never see a session-specific implementation leak.
        local b_names "__no_posted_standardized_lags__"
        local placeholder_posted = 1
    }
    else {
        if `n_posted_vcov' != `n_lags_posted' {
            display as error "E011: Posted placebo covariance could not be reconstructed"
            display as error "      Joint bootstrap support for the posted standardized placebo vector is inconsistent with e(b)"
            _ddcheck_cleanup, vars(`generated_covariates')
            exit 498
        }
        mata: st_matrix("`V_post'", _check_posted_vcov)
    }
    if `n_lags_posted' > 0 | `placeholder_posted' {
        matrix colnames `b_post' = `b_names'
        matrix rownames `V_post' = `b_names'
        matrix colnames `V_post' = `b_names'
    }

    // Reconstruct the union of placebo windows retained in e(placebo) so
    // cluster support is reported for the actual diagnostic sample rather than
    // the full pre-Mata touse sample.
    local posted_sample "`touse'"
    local N_support = `N'
    local n_clusters_support = `n_clusters'
    if "`design'" == "did" {
        tempvar placebo_support placebo_regress_sample time_order cluster_support_tag
        quietly gen byte `placebo_support' = 0
        quietly egen long `time_order' = group(`time') if `touse'

        local treat_order = .
        if `is_panel' {
            quietly summarize `time_order' if `touse' & `treatment' == 1, meanonly
            local treat_order = r(min)
        }
        else {
            quietly summarize `time_order' if `touse' & `post' == 1, meanonly
            local treat_order = r(min)
        }

        local lag_row = 0
        foreach lag_i of local identified_lags {
            local ++lag_row
            local placebo_post_order = `treat_order' - `lag_i'
            local placebo_pre_order = `placebo_post_order' - 1
            tempvar placebo_support_lag placebo_regress_sample_lag cluster_support_tag_lag
            quietly gen byte `placebo_support_lag' = 0
            quietly replace `placebo_support_lag' = 1 if `touse' & ///
                inlist(`time_order', `placebo_post_order', `placebo_pre_order')
            quietly replace `placebo_support' = 1 if `placebo_support_lag' == 1 & `touse'

            quietly gen byte `placebo_regress_sample_lag' = 0
            quietly replace `placebo_regress_sample_lag' = `placebo_support_lag' if `touse'
            if "`covars_str'" != "" {
                markout `placebo_regress_sample_lag' `covars_str', strok
            }

            if "`clustvar'" != "" {
                quietly egen byte `cluster_support_tag_lag' = tag(`clustvar') if `placebo_regress_sample_lag' == 1 & `touse'
                quietly count if `cluster_support_tag_lag' == 1 & `placebo_regress_sample_lag' == 1 & `touse'
            }
            else {
                quietly count if `placebo_regress_sample_lag' == 1 & `touse'
            }
            matrix `cluster_support_mat'[`lag_row', 1] = r(N)
        }

        // Match the posted sample to the actual placebo OLS sample.
        // Standardization still uses the wider placebo window, but e(sample)
        // must exclude rows later dropped by regression-stage listwise deletion.
        quietly gen byte `placebo_regress_sample' = 0
        quietly replace `placebo_regress_sample' = `placebo_support' if `touse'
        if "`covars_str'" != "" {
            markout `placebo_regress_sample' `covars_str', strok
        }

    quietly count if `placebo_regress_sample' == 1 & `touse'
    local N_support = r(N)
    local posted_sample "`placebo_regress_sample'"

    if "`clustvar'" != "" {
        quietly count if `placebo_regress_sample' == 1 & `touse' & missing(`clustvar')
        local n_missing_cluster_support = r(N)
        if `n_missing_cluster_support' > 0 {
            _ddcheck_cleanup, vars(`generated_covariates')
            display as error "E003: cluster() contains missing values in the posted diagnostic sample"
            display as error "      Found `n_missing_cluster_support' observations with undefined bootstrap blocks"
            display as error "      Fill cluster() at the treatment-assignment level or omit cluster() for panel unit-level bootstrap"
            exit 198
        }
        quietly egen byte `cluster_support_tag' = tag(`clustvar') if `placebo_regress_sample' == 1 & `touse' & !missing(`clustvar')
        quietly count if `cluster_support_tag' == 1 & `placebo_regress_sample' == 1 & `touse' & !missing(`clustvar')
        local n_clusters_support = r(N)
    }
        else {
            quietly count if `placebo_regress_sample' == 1 & `touse'
            local n_clusters_support = r(N)
        }
    }
    else if "`design'" == "sa" {
        local identified_pos ""
        local lag_col = 0
        foreach lag_req of numlist `lag' {
            local ++lag_col
            local lag_req_int = int(`lag_req')
            local lag_is_identified : list lag_req_int in identified_lags
            if `lag_is_identified' {
                local identified_pos "`identified_pos' `lag_col'"
            }
        }
        local identified_pos = trim("`identified_pos'")

        if "`identified_pos'" != "" {
            tempvar placebo_support_sa cluster_support_tag_sa
            quietly gen byte `placebo_support_sa' = 0 if `touse'
            local identified_pos_mata = subinstr("`identified_pos'", " ", ", ", .)
            mata: st_store(selectindex(st_data(., "`touse'")), st_varindex("`placebo_support_sa'"), rowsum(_check_sa_support_mask_raw[., (`identified_pos_mata')]) :> 0)

            quietly count if `placebo_support_sa' == 1 & `touse'
            if r(N) > 0 {
                local N_support = r(N)
                local posted_sample "`placebo_support_sa'"
                if "`clustvar'" != "" {
                    quietly egen byte `cluster_support_tag_sa' = tag(`clustvar') if `placebo_support_sa' == 1 & `touse' & !missing(`clustvar')
                    quietly count if `cluster_support_tag_sa' == 1 & `placebo_support_sa' == 1 & `touse' & !missing(`clustvar')
                    local n_clusters_support = r(N)
                }
                else {
                    quietly count if `placebo_support_sa' == 1 & `touse'
                    local n_clusters_support = r(N)
                }
            }
        }
    }

    ereturn post `b_post' `V_post', esample(`posted_sample') obs(`N_support') depname("`depvar'")
    if `n_lags_posted' > 0 {
        ereturn local properties "b V"
    }
    else {
        ereturn local properties ""
    }
    
    // --- Scalars ---
    ereturn scalar N = `N_support'
    ereturn scalar n_lags = `n_lags_identified'
    ereturn scalar n_lags_posted = `n_lags_posted'
    ereturn scalar n_boot = `nboot_val'
    ereturn scalar n_boot_valid = `n_boot_valid'
    ereturn scalar n_clusters = `n_clusters_support'
    // Placebo and equivalence intervals are defined from the 90% CI.
    ereturn scalar level = 90
    
    // --- Macros ---
    ereturn local cmd "diddesign_check"
    ereturn local cmdline "`cmdline'"
    ereturn local design "`design'"
    ereturn local depvar "`depvar'"
    ereturn local treatment "`treatment_orig'"
    ereturn local id "`id_orig'"
    ereturn local time "`time_orig'"
    ereturn local post "`post_orig'"
    ereturn local sample_ifin `"`if' `in'"'
    ereturn local clustvar "`clustvar_report'"
    ereturn local covars "`covars_spec'"
    ereturn local covariates "`covars_spec'"
    ereturn local identified_lags "`identified_lags'"
    ereturn local posted_lags "`posted_lags'"
    ereturn local raw_only_lags "`raw_only_lags'"
    ereturn local unidentified_lags "`unidentified_lags'"
    // This command stores e(placebo) and e(trends), not e(b) and e(V)
    
    // --- Matrices ---
    ereturn matrix placebo = `placebo_mat'
    ereturn matrix trends = `trends_mat'
    ereturn matrix n_boot_valid_lag = `lag_support_mat'
    if "`design'" == "did" {
        matrix rownames `cluster_support_mat' = `placebo_rownames'
        matrix colnames `cluster_support_mat' = n_clusters
        ereturn matrix n_clusters_lag = `cluster_support_mat'
    }
    
    // SA design: store treatment timing matrix (Gmat) only if valid
    // Invalid or placeholder matrices are not stored to prevent misleading plots
    if "`design'" == "sa" {
        capture mata: st_matrix("`Gmat_mat'", _check_Gmat)
        if _rc == 0 {
            capture confirm matrix `Gmat_mat'
            if _rc == 0 {
                local gmat_rows = rowsof(`Gmat_mat')
                local gmat_cols = colsof(`Gmat_mat')
                // Only store Gmat if it represents valid data (not 1x1 placeholder)
                if (`gmat_rows' > 1 | `gmat_cols' > 1) & `gmat_rows' > 0 & `gmat_cols' > 0 {
                    ereturn matrix Gmat = `Gmat_mat'
                }
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Store Data Type Info
    // -------------------------------------------------------------------------
    ereturn scalar is_panel = `is_panel'
    if `is_panel' {
        ereturn local datatype "panel"
    }
    else {
        ereturn local datatype "rcs"
    }
    
    // -------------------------------------------------------------------------
    // Display Results
    // -------------------------------------------------------------------------
    local quiet_display = ("`quiet'" != "")
    _diddesign_check_display, design("`design'") filtered_lags("`filtered_lags'") ///
        is_panel(`is_panel') cluster("`clustvar_report'") quiet(`quiet_display')

    _ddcheck_cleanup, vars(`generated_covariates')
    
end

program define _ddcheck_cleanup
    version 16.0

    syntax , [VARS(varlist)]

    if "`vars'" != "" {
        capture drop `vars'
    }
end

// =============================================================================
// _diddesign_check_display
// Formats and displays placebo test results
//
// Displays the parallel trends assessment output including design information,
// sample statistics, and a formatted table of placebo estimates with bootstrap
// standard errors and equivalence confidence intervals.
// =============================================================================
program define _diddesign_check_display
    syntax, design(string) [filtered_lags(string) is_panel(integer 1) cluster(string) quiet(integer 0)]
    
    // Header
    display ""
    display as text "Parallel Trends Assessment"
    display as text "{hline 60}"
    
    // Design info
    if "`design'" == "did" {
        display as text "Design:           " as result "Standard DID"
    }
    else {
        display as text "Design:           " as result "Staggered Adoption"
    }
    // Data type info
    if `is_panel' {
        display as text "Data type:        " as result "Panel"
    }
    else {
        display as text "Data type:        " as result "Repeated Cross-Section (RCS)"
    }
    display as text "Standardization:  " as result "Yes (by control group baseline)"
    if "`cluster'" != "" {
        display as text "Clustering:       " as result "`cluster'"
    }
    
    // Sample info
    display ""
    display as text "Sample: N = " as result e(N) as text ", Clusters = " as result e(n_clusters)
    display as text "Bootstrap: n_boot = " as result e(n_boot) as text ", n_boot_valid = " as result e(n_boot_valid)

    capture matrix lag_support = e(n_boot_valid_lag)
    if _rc == 0 {
        local n_support = rowsof(lag_support)
        if `n_support' > 0 {
            local lag_rows : rownames lag_support
            display as text "Lag bootstrap support (std/raw):"
            forvalues i = 1/`n_support' {
            local lag_label : word `i' of `lag_rows'
            local lag_support_std = lag_support[`i', 1]
            local lag_support_raw = lag_support[`i', 2]
            display as text "  lag " as result "`lag_label'" as text ": " ///
                    as result `lag_support_std' as text " / " as result `lag_support_raw'
        }
    }
    }

    if "`design'" == "did" {
        capture matrix lag_clusters = e(n_clusters_lag)
        if _rc == 0 {
            local n_cluster_rows = rowsof(lag_clusters)
            if `n_cluster_rows' > 0 {
                local lag_cluster_rows : rownames lag_clusters
                display as text "Lag cluster support:"
                forvalues i = 1/`n_cluster_rows' {
                    local lag_label : word `i' of `lag_cluster_rows'
                    local lag_cluster_count = lag_clusters[`i', 1]
                    display as text "  lag " as result "`lag_label'" as text ": " ///
                        as result `lag_cluster_count'
                }
            }
        }
    }
    
    // Warning for filtered lags
    if !`quiet' & "`filtered_lags'" != "" {
        display ""
        display as text "{p 0 4 2}"
        display as text "Warning: The following lag(s) were filtered out (exceed max available): `filtered_lags'"
        display as text "{p_end}"
    }

    local raw_only_lags "`e(raw_only_lags)'"
    if !`quiet' & "`raw_only_lags'" != "" {
        display ""
        display as text "{p 0 4 2}"
        display as text "Warning: The following lag(s) retain raw placebo estimates in e(placebo), but standardized placebo inference is not identifiable: `raw_only_lags'"
        display as text "{p_end}"
    }

    local unidentified_lags "`e(unidentified_lags)'"
    if !`quiet' & "`unidentified_lags'" != "" {
        display ""
        display as text "{p 0 4 2}"
        display as text "Warning: The following lag(s) were dropped after support checks because placebo inference is not identifiable on either standardized or raw scales: `unidentified_lags'"
        display as text "{p_end}"
    }
    
    // Table header
    display ""
    display as text "Placebo Tests (Pre-treatment DID):"
    display as text "{hline 78}"
    display as text "    Lag  |  Estimate   Std.Err.   Estimate(raw)  SE(raw)     95% Eq. CI"
    display as text "{hline 9}+{hline 68}"
    
    // Table content
    tempname placebo
    matrix `placebo' = e(placebo)
    local nrows = rowsof(`placebo')
    
    if `nrows' == 0 {
        display as text "    (no valid lags)"
    }
    else {
        forvalues i = 1/`nrows' {
            local lag_val = `placebo'[`i', 1]
            local est = `placebo'[`i', 2]
            local se = `placebo'[`i', 3]
            local est_orig = `placebo'[`i', 4]
            local se_orig = `placebo'[`i', 5]
            local ci_lb = `placebo'[`i', 6]
            local ci_ub = `placebo'[`i', 7]
            
            display as text %7.0f `lag_val' "  |" ///
                as result %10.4f `est' %10.4f `se' ///
                %14.4f `est_orig' %10.4f `se_orig' ///
                "   [" %6.3f `ci_lb' ", " %6.3f `ci_ub' "]"
        }
    }
    
    display as text "{hline 78}"
    
    // Interpretation
    display ""
    display as text "Interpretation:"
    display as text "- 'Estimate' column shows standardized placebo effects (divided by control SD)"
    display as text "- Estimates close to zero suggest parallel pre-treatment trends"
    display as text "- Narrower equivalence CI indicates stronger evidence for parallel trends"
    
end
