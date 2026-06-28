*! _diddesign_parse.ado - Parameter parsing and validation for DIDdesign
*!
*! This module parses command-line options, sets default values, and validates
*! all parameters before estimation. It serves as the interface between user
*! input and the core estimation routines.

version 16.0

program define _diddesign_parse, rclass
    
    // =========================================================================
    // SECTION 1: SYNTAX PARSING
    // =========================================================================
    // The varlist contains the outcome variable followed by optional inline
    // covariates. Factor variable notation (fv) is supported for covariates.
    
    syntax anything(name=rawvars) [if] [in], ///
        TREATment(varname)              /// Required: treatment indicator
        [ID(varname)]                   /// Unit identifier (required for panel)
        [TIME(varname)]                 /// Time identifier (required)
        [POST(varname)]                 /// Post-treatment indicator (RCS only)
        [CLuster(varname)]              /// Cluster variable for SEs
        [COVariates(string asis)]       /// Additional covariates (supports factor variables via string)
        [NBoot(integer 30)]             /// Bootstrap iterations (default: 30)
        [LEAD(numlist >=0 integer)]     /// Lead values for staggered adoption design
        [LAG(numlist >=0 integer)]      /// Lag values for diagnostics
        [THRes(integer 2)]              /// SA threshold (default: 2)
        [LEVEL(cilevel)]                /// Confidence level (default: 95)
        [SEED(integer -1)]              /// Random seed (-1 = not specified)
        [DESIGN(string)]                /// Design type: "did" (default) or "sa"
        [PARALlel]                      /// Use parallel computing
        [SEBoot]                        /// Use bootstrap SE/CI
        [PANEL]                         /// Panel data format
        [RCS]                           /// Repeated cross-section format

    // Normalize covariate tokenization so wrapper handoff preserves the
    // requested terms instead of silently collapsing them to empty.
    local covariates_clean : list retokenize covariates
    
    // =========================================================================
    // SECTION 2: SAMPLE MARKING
    // =========================================================================
    // Observations with missing values in required variables are excluded.
    
    local varlist = trim("`rawvars'")

    marksample touse, novarlist
    markout `touse' `treatment'
    
    if "`id'" != "" {
        markout `touse' `id'
    }
    if "`time'" != "" {
        markout `touse' `time'
    }
    if "`post'" != "" {
        markout `touse' `post'
    }
    if "`cluster'" != "" {
        markout `touse' `cluster'
    }

    gettoken outcome_var inline_covars : varlist
    
    // =========================================================================
    // SECTION 3: DEFAULT VALUE ASSIGNMENT
    // =========================================================================
    // Default values match the R package DIDdesign for cross-platform consistency.
    
    local nboot_val = `nboot'
    local parallel_val = ("`parallel'" != "")  // Enable parallel bootstrap
    local seboot_val = ("`seboot'" != "")
    local cluster_val = "`cluster'"
    
    if "`lead'" == "" {
        local lead_val = "0"
    }
    else {
        local lead_val = "`lead'"
    }
    
    local thres_val = `thres'
    
    if "`lag'" == "" {
        local lag_val = "1"
    }
    else {
        local lag_val = "`lag'"
    }
    
    local level_val = `level'
    
    // Unspecified seed (-1) is represented as missing for conditional application
    if `seed' == -1 {
        local seed_val = .
    }
    else {
        local seed_val = `seed'
    }
    
    if "`design'" == "" {
        local design_val = "did"
    }
    else {
        local design_val = lower("`design'")
    }
    
    // =========================================================================
    // SECTION 4: PARAMETER VALIDATION
    // =========================================================================
    
    // Minimum of 2 bootstrap iterations required for variance estimation
    if `nboot_val' < 2 {
        display as error "E002: Option nboot() must be at least 2 for variance estimation"
        exit 198
    }
    
    if `thres_val' < 1 {
        display as error "E002: Option thres() must be a positive integer >= 1"
        exit 198
    }
    
    if `level_val' <= 0 | `level_val' >= 100 {
        display as error "E002: Option level() must be between 0 and 100 (exclusive)"
        exit 198
    }
    
    foreach l of numlist `lead_val' {
        if `l' < 0 {
            display as error "E002: Option lead() values must be non-negative integers"
            exit 198
        }
    }

    local unique_leads : list uniq lead_val
    local n_lead_all : word count `lead_val'
    local n_lead_unique : word count `unique_leads'
    if `n_lead_unique' < `n_lead_all' {
        local duplicate_leads ""
        local seen_leads ""
        foreach l of numlist `lead_val' {
            local lead_token "`l'"
            local already_seen : list lead_token in seen_leads
            if `already_seen' {
                local already_listed : list lead_token in duplicate_leads
                if !`already_listed' {
                    local duplicate_leads "`duplicate_leads' `lead_token'"
                }
            }
            else {
                local seen_leads "`seen_leads' `lead_token'"
            }
        }
        local duplicate_leads = strtrim("`duplicate_leads'")
        display as error "E002: Option lead() contains duplicate values: `duplicate_leads'"
        display as error "       Each event time may be requested at most once"
        exit 198
    }
    
    foreach l of numlist `lag_val' {
        if `l' < 0 {
            display as error "E002: Option lag() values must be non-negative integers >= 0"
            exit 198
        }
    }
    
    if `seed_val' != . {
        if `seed_val' < 0 | `seed_val' > 2147483647 {
            display as error "E002: Option seed() must be a valid integer (0 to 2147483647)"
            exit 198
        }
    }
    
    local is_panel = ("`panel'" != "")
    local is_rcs = ("`rcs'" != "")

    if "`id'" != "" & "`post'" != "" {
        display as error "E016: Options id() and post() are mutually exclusive"
        display as error "      Use id() for panel data or post() for repeated cross-section data"
        exit 198
    }
    
    if `is_panel' & `is_rcs' {
        display as error "E016: Options panel and rcs are mutually exclusive"
        exit 198
    }
    
    if "`design_val'" != "did" & "`design_val'" != "sa" {
        display as error "E002: Option design() must be 'did' or 'sa'"
        exit 198
    }
    
    // Staggered adoption (SA) design requires panel structure for cohort tracking
    if "`design_val'" == "sa" & `is_rcs' {
        display as error "E014: Only panel data is supported in the SA design"
        exit 198
    }
    
    // -------------------------------------------------------------------------
    // Data type auto-detection
    // -------------------------------------------------------------------------
    // Data structure is inferred from id() (panel) or post() (RCS) options.
    if !`is_panel' & !`is_rcs' {
        if "`id'" != "" {
            local is_panel = 1
        }
        else if "`post'" != "" {
            local is_rcs = 1
        }
        else {
            display as error "E016: Must specify id() for panel data or post() for RCS data"
            exit 198
        }
    }

    if `is_panel' & "`post'" != "" {
        display as error "E016: Option post() is only valid for RCS data"
        display as error "      Remove post() or re-run without the panel option"
        exit 198
    }

    if `is_rcs' & "`id'" != "" {
        display as error "E016: Option id() is only valid for panel data"
        display as error "      Remove id() or re-run with the panel option"
        exit 198
    }

    // =========================================================================
    // SECTION 5: REQUIRED OPTION VALIDATION
    // =========================================================================
    
    if "`time'" == "" {
        display as error "E001: Option time() is required"
        exit 198
    }
    
    if `is_panel' & "`id'" == "" {
        display as error "E001: Option id() required for panel data"
        exit 198
    }
    
    if `is_rcs' & "`post'" == "" {
        display as error "E001: Option post() required for RCS data"
        exit 198
    }
    
    // =========================================================================
    // SECTION 6: VARIABLE VALIDATION
    // =========================================================================
    
    gettoken outcome_var rest : varlist
    
    // -------------------------------------------------------------------------
    // Outcome variable validation
    // -------------------------------------------------------------------------
    // Factor variable notation is restricted to covariates only.
    if regexm("`outcome_var'", "^(i\.|c\.|o\.|b[0-9]*\.|ib[0-9]+\.)") {
        display as error "E001: Outcome variable cannot use factor variable notation"
        display as error "       Got: `outcome_var'"
        display as error "       Use a plain numeric variable as the dependent variable"
        display as error "       Factor variables (e.g., i.var) are only allowed for covariates"
        exit 198
    }
    
    local covar_inline = "`rest'"
    local all_covariates = `"`covar_inline' `covariates_clean'"'
    local all_covariates = strtrim(`"`all_covariates'"')
    
    // -------------------------------------------------------------------------
    // Duplicate covariate removal
    // -------------------------------------------------------------------------
    
    if "`all_covariates'" != "" {
        local unique_covars : list uniq all_covariates
        local n_all : word count `all_covariates'
        local n_unique : word count `unique_covars'
        
        if `n_unique' < `n_all' {
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
    
    // -------------------------------------------------------------------------
    // Factor variable expansion
    // -------------------------------------------------------------------------
    // Expansion is deferred to the caller to preserve temporary variables.
    
    capture confirm numeric variable `outcome_var'
    if _rc {
        if _rc == 111 {
            display as error "E001: Variable `outcome_var' not found"
        }
        else {
            display as error "E017: Variable `outcome_var' must be numeric"
        }
        exit _rc
    }
    
    capture confirm numeric variable `treatment'
    if _rc {
        if _rc == 111 {
            display as error "E001: Variable `treatment' not found"
        }
        else {
            display as error "E017: Variable `treatment' must be numeric"
        }
        exit _rc
    }
    
    // -------------------------------------------------------------------------
    // Unit identifier validation
    // -------------------------------------------------------------------------
    // String identifiers are flagged for automatic encoding.
    local id_is_string = 0
    if "`id'" != "" {
        capture confirm variable `id'
        if _rc {
            display as error "E001: Variable `id' not found"
            exit 111
        }
        capture confirm string variable `id'
        if _rc == 0 {
            local id_is_string = 1
        }
        else {
            capture confirm numeric variable `id'
            if _rc {
                display as error "E017: Variable `id' must be numeric or string"
                exit _rc
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // Time variable validation
    // -------------------------------------------------------------------------
    // Time may be numeric or string. String time is encoded in the main
    // command using egen group(), matching the reference R behavior that maps
    // factor levels to numeric period indices.
    local time_is_string = 0
    capture confirm variable `time'
    if _rc {
        display as error "E001: Variable `time' not found"
        exit 111
    }
    capture confirm string variable `time'
    if _rc == 0 {
        local time_is_string = 1
    }
    else {
        capture confirm numeric variable `time'
        if _rc {
            display as error "E017: Variable `time' must be numeric or string"
            exit _rc
        }
    }
    
    if "`post'" != "" {
        capture confirm numeric variable `post'
        if _rc {
            if _rc == 111 {
                display as error "E001: Variable `post' not found"
            }
            else {
                display as error "E017: Variable `post' must be numeric"
            }
            exit _rc
        }
    }
    
    // -------------------------------------------------------------------------
    // Cluster variable validation
    // -------------------------------------------------------------------------
    // String clusters are flagged for automatic encoding.
    local cluster_is_string = 0
    if "`cluster_val'" != "" {
        capture confirm variable `cluster_val'
        if _rc {
            display as error "E001: Variable `cluster_val' not found"
            exit 111
        }
        capture confirm string variable `cluster_val'
        if _rc == 0 {
            local cluster_is_string = 1
        }
        else {
            capture confirm numeric variable `cluster_val'
            if _rc {
                display as error "E017: Variable `cluster_val' must be numeric or string"
                exit _rc
            }
        }
    }
    
    // Covariate validation is deferred for factor variable expansion.
    
    // =========================================================================
    // SECTION 7: RETURN VALUES
    // =========================================================================
    
    return local outcome = "`outcome_var'"
    return local treatment = "`treatment'"
    return local id = "`id'"
    return local time = "`time'"
    return local post = "`post'"
    return local cluster = "`cluster_val'"
    return local covariates = "`all_covariates'"
    
    return scalar nboot = `nboot_val'
    return scalar thres = `thres_val'
    return scalar level = `level_val'
    return scalar seed = `seed_val'
    
    return local lead = "`lead_val'"
    return local lag = "`lag_val'"
    
    return scalar parallel = `parallel_val'
    return scalar seboot = `seboot_val'
    return scalar is_panel = `is_panel'
    
    // Flags indicating string variables requiring numeric encoding
    return scalar id_is_string = `id_is_string'
    return scalar time_is_string = `time_is_string'
    return scalar cluster_is_string = `cluster_is_string'
    
    return local design = "`design_val'"
    
    // =========================================================================
    // SECTION 8: MATA LIBRARY CHECK
    // =========================================================================
    // The Mata library must be loaded prior to estimation. Direct invocation
    // of this program without the main command will produce a clear error.
    
    capture mata: mata describe _diddesign_populate_option()
    if _rc != 0 {
        display as error "E015: DIDdesign Mata library not loaded"
        display as error "       Please use 'diddesign' command which auto-loads the library"
        display as error "       Or run: do diddesign-stata/mata/diddesign_mata.do"
        exit 499
    }
    
    // =========================================================================
    // SECTION 9: MATA STRUCTURE POPULATION
    // =========================================================================
    // Parsed values are transferred to the did_option Mata structure for
    // use by the GMM estimation routines.
    
    if `seed_val' != . {
        set seed `seed_val'
    }
    
    local lead_mata = subinstr("`lead_val'", " ", ", ", .)
    local lag_mata = subinstr("`lag_val'", " ", ", ", .)
    
    mata: st_local("mata_rc", strofreal(_diddesign_populate_option( ///
        `nboot_val',           /* n_boot     */ ///
        `parallel_val',        /* parallel   */ ///
        `seboot_val',          /* se_boot    */ ///
        "`cluster_val'",       /* id_cluster */ ///
        (`lead_mata'),         /* lead       */ ///
        `thres_val',           /* thres      */ ///
        (`lag_mata'),          /* lag        */ ///
        `level_val',           /* level      */ ///
        `seed_val'             /* seed       */ ///
    )))
    
    if `mata_rc' != 0 {
        display as error "Error populating Mata did_option structure"
        exit 498
    }

end
