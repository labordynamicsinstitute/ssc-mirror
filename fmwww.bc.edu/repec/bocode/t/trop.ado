*! trop -- Triply Robust Panel (TROP) estimator

/*
    trop -- Estimate average treatment effects on the treated (ATT) in panel
    data using the TROP framework of Athey, Imbens, Qu, and Viviano (2025):
    unit weights, time weights, and a nuclear-norm-penalised low-rank
    regression adjustment.

    Paper anchors
    -------------
    The estimator implemented here is paper Algorithm 1 (single treated
    unit, Eq. 2) extended to multiple treated cells via Algorithm 2
    (Eq. 13) under method(twostep), and to the homogeneous-tau aggregation
    of Remark 6.1 under method(joint).  Weight kernels follow Eq. 3.
    Hyperparameters (lambda_time, lambda_unit, lambda_nn) are selected by
    leave-one-out cross-validation Q(lambda) (Eq. 5) unless
    fixedlambda() is specified; the two-stage cycling search follows
    paper Footnote 2.  Inference uses paper Algorithm 3 (stratified unit
    bootstrap).  The triple-robustness bias bound (Theorem 5.1) is
    available as a post-estimation diagnostic via `estat triplerob`.

    Note on method(joint).  Paper Remark 6.1 defines the homogeneous-tau
    aggregation but does not prescribe a specific time/unit kernel under
    the shared-weight setting; trop adopts the post-block midpoint
    delta_time and the pre-period trajectory RMSE delta_unit as
    engineering choices.  See `help trop` Methods and formulas for the
    explicit definitions.

    Syntax
    ------
    trop depvar treatvar [if] [in], panelvar(varname) timevar(varname)
        [method(twostep|joint|local|global) grid_style(default|fine|extended)
         twostep_loocv(cycling|exhaustive) joint_loocv(cycling|exhaustive)
         lambda_time_grid(numlist) lambda_unit_grid(numlist)
         lambda_nn_grid(numlist) fixedlambda(numlist)
         tol(real) maxiter(integer)
         bootstrap(integer) bsalpha(real) seed(integer)
         bsvariance(sample|paper)
         cimethod(percentile|t|normal)
         verbose level(cilevel)]
*/


program define trop, eclass
    version 17.0

    // --- Version subcommand -----------------------------------------------
    // Intercept `trop, version` before the main syntax parser, which
    // requires exactly two variables.  This allows users to verify the
    // installed version without supplying a varlist.
    if `"`0'"' == ", version" | `"`0'"' == ",version" | `"`0'"' == "version" {
        di as txt "trop version 1.2.1"
        di as txt "Triply Robust Panel Estimator"
        di as txt "Athey, Imbens, Qu & Viviano (2025)"
        di as txt ""
        di as txt "Stata implementation by Xuanyu Cai & Wenli Xu"
        di as txt "License: AGPL-3.0"
        exit
    }

    // --- Syntax parsing ---------------------------------------------------
    // `[pweight]` enables survey-design weighted ATT aggregation: each
    // treated cell (t, i) receives the pweight attached to unit i.
    // LOOCV remains unweighted; inference is a pweight-only bootstrap
    // (no strata / PSU / FPC Rao-Wu rescaling).
    syntax varlist(min=2 max=2) [if] [in] [pweight/], ///
        Panelvar(varname)                   /// panel (unit) identifier
        Timevar(varname)                    /// time period identifier
        [                                   ///
        Method(string)                      /// "twostep" (per-obs tau) or "joint" (scalar tau)
        Grid_style(string)                  /// grid layout for LOOCV: "default" or "extended"
        TWostep_loocv(string)               /// twostep LOOCV strategy: "cycling" (default) or "exhaustive"
        JOint_loocv(string)                 /// joint LOOCV strategy: "cycling" or "exhaustive" (default)
        LAMbda_time_grid(numlist)                   /// user-supplied lambda_time grid
        LAMbda_unit_grid(numlist)                   /// user-supplied lambda_unit grid
        LAMbda_nn_grid(numlist missingokay)         /// user-supplied lambda_nn grid (`.` = inf)
        FIXEDlambda(string)                  /// fixed (l_time l_unit l_nn); `.` = inf for l_nn
        TOL(real 1e-6)                      /// convergence tolerance for iterative estimation
        MAXiter(integer 500)                /// maximum iterations for alternating minimization
                                            ///   Paper Algorithm 2/3 four-step ALS requires
                                            ///   sufficient iterations to guarantee convergence.
                                            ///   Theorem 8.1 convergence rate is O(1/k); 500
                                            ///   steps ensures residual < 1e-6 in practice.
                                            ///   100 steps may be insufficient when p > 20
                                            ///   covariates or condition number is large.
        BOOTstrap(integer 200)              /// number of bootstrap replications (paper Alg 3 default; 0 = skip)
        BSalpha(real -1)                    /// deprecated; retained for backward compatibility
        SEED(integer 42)                    /// RNG seed for bootstrap
        BSVARiance(string)                  /// bootstrap SE denominator: "sample" (1/(B-1), default) or "paper" (1/B, Alg 3)
        CImethod(string)                    /// primary CI: "percentile" (Alg 3 default when bootstrap>0), "t", or "normal"
        STRata(varname)                     /// survey: stratification variable
        PSU(varname)                        /// survey: primary sampling unit variable
        FPC(varname)                        /// survey: finite population correction variable
        NEST                                /// survey: nest PSU within strata
        SINGLEUnit(string)                  /// survey: lonely PSU strategy: "skip" (default) or "centered"
        COVariates(varlist)                 /// covariates for Eq.14 adjustment (Section 6.2)
        VERbose                             /// display progress and diagnostic messages (sets level 2)
        VLevel(integer -1)                  /// verbose level: 0=quiet 1=normal 2=detailed 3=debug 4=dev
        NOTIMing                            /// suppress timing estimate display
        Level(cilevel)                      /// confidence level for bootstrap CI
        ]

    // --- Resolve pweight expression --------------------------------------
    // The `/` flag in `[pweight/]` makes `exp` hold the bare variable name
    // (no leading `=`).  Empty string means pweights were not requested.
    local weight_var ""
    if "`weight'" != "" {
        if "`weight'" != "pweight" {
            di as error "trop only supports pweight; got `weight'."
            exit 101
        }
        local weight_var = trim("`exp'")
        // Confirm the expression reduces to a single existing numeric variable.
        capture confirm numeric variable `weight_var'
        if _rc {
            di as error "pweight expression must be a single numeric variable; got: `exp'"
            di as error "  Example: [pweight=wt]"
            exit 198
        }
    }

    // --- Variable extraction ----------------------------------------------
    gettoken depvar treatvar : varlist
    // gettoken preserves the separating whitespace; strip it so downstream
    // consumers (e(treatvar), Mata _st_varindex, etc.) see a clean name.
    local treatvar = trim("`treatvar'")

    // --- Default values ---------------------------------------------------
    if "`method'" == "" {
        local method "twostep"
    }
    // Accept paper terminology as aliases:
    //   method("local")  == method("twostep")  (per-observation weights)
    //   method("global") == method("joint")    (single scalar tau)
    if "`method'" == "local" {
        local method "twostep"
    }
    else if "`method'" == "global" {
        local method "joint"
    }
    if !inlist("`method'", "twostep", "joint") {
        di as error "method() must be {bf:twostep} (alias {bf:local}) or " ///
            "{bf:joint} (alias {bf:global})"
        exit 198
    }
    if "`grid_style'" == "" {
        local grid_style "default"
    }
    // grid_style alias mapping (normalize at entry point)
    //   standard   -> default   (paper Footnote 2 Stage-1 coarse search, 180 combos)
    //   exhaustive -> extended  (paper Table 2 full optimal-value coverage)
    if "`grid_style'" == "standard" {
        local grid_style "default"
    }
    else if "`grid_style'" == "exhaustive" {
        local grid_style "extended"
    }
    if !inlist("`grid_style'", "default", "fine", "extended") {
        di as error "grid_style() must be one of: standard (=default), fine, exhaustive (=extended)"
        di as error "  standard/default : 180 combinations (6 x 6 x 5)"
        di as error "  fine             : 343 combinations (7 x 7 x 7)"
        di as error "  exhaustive/extended : 4,256 combinations (includes DID/TWFE corner)"
        exit 198
    }
    if "`joint_loocv'" == "" {
        // Default to exhaustive Cartesian search: the joint objective has a
        // single closed-form WLS solution per grid point, so the O(|grid|^3)
        // cost is manageable and the result is the exact argmin over the
        // grid.  Users who need speed can opt into cycling coordinate
        // descent via joint_loocv(cycling).
        local joint_loocv "exhaustive"
    }
    if "`twostep_loocv'" == "" {
        // Default to the coordinate-descent cycling path: each cycle costs
        // O(|grid|) LOOCV evaluations per treated observation, which stays
        // affordable on healthy panel sizes.  Users on small panels (e.g.
        // Basque/Germany) can opt into exhaustive Cartesian search via
        // twostep_loocv(exhaustive) to eliminate BLAS-dependent lambda
        // drift caused by non-convex Q(lambda) surfaces with multiple
        // local minima.
        local twostep_loocv "cycling"
    }
    if "`level'" == "" {
        local level = c(level)
    }

    // --- Validate joint_loocv() -------------------------------------------
    // Accept only "exhaustive" (Cartesian product, O(|grid|^3), default;
    // guarantees the exact grid argmin) or "cycling" (coordinate descent,
    // O(|grid|*max_cycles), faster but may select a different lambda
    // because the Q(lambda) surface is non-convex).  The option is parsed
    // for any method() but only takes effect for method("joint") with LOOCV
    // enabled.
    if !inlist("`joint_loocv'", "cycling", "exhaustive") {
        di as error "joint_loocv() must be either {bf:exhaustive} or {bf:cycling}"
        di as error "  exhaustive (default): Cartesian product, O(|grid|^3),"
        di as error "                        guarantees the global grid minimum"
        di as error "  cycling             : coordinate descent, O(|grid|*cycles),"
        di as error "                        faster but may select a different lambda"
        exit 198
    }

    // --- Validate twostep_loocv() -----------------------------------------
    // Accept only "cycling" (default) or "exhaustive".  The option is parsed
    // for any method() but only takes effect for method("twostep") with LOOCV
    // enabled.
    if !inlist("`twostep_loocv'", "cycling", "exhaustive") {
        di as error "twostep_loocv() must be either {bf:cycling} or {bf:exhaustive}"
        di as error "  cycling (default): coordinate-descent, O(|grid|*cycles),"
        di as error "                     matches the historical default"
        di as error "  exhaustive       : Cartesian product, O(|grid|^3),"
        di as error "                     guarantees the global grid minimum"
        exit 198
    }

    // --- Validate bootstrap() --------------------------------------------
    // Bootstrap inference requires at least two replicates so that the
    // variance denominator (B-1 for sample, B for paper) is strictly
    // positive.  `bootstrap(0)` is the documented way to skip inference
    // entirely.  Reject `bootstrap(1)` explicitly because it would leave
    // the SE undefined (division by zero under ddof=1) while still
    // producing a misleading non-zero point estimate.
    if `bootstrap' < 0 {
        di as error "bootstrap() must be a non-negative integer."
        exit 198
    }
    if `bootstrap' == 1 {
        di as error "bootstrap(1) is not a valid configuration."
        di as error "  Use bootstrap(0) to skip inference entirely, or"
        di as error "  bootstrap(>=2) to produce a valid standard error."
        di as error "  The default is bootstrap(200)."
        exit 198
    }

    // bsalpha() is superseded by level().  When the sentinel value (-1)
    // indicates that bsalpha() was not specified, alpha is derived from
    // level().  Otherwise the user-supplied bsalpha() is honored with a
    // deprecation notice.
    if `bsalpha' != -1 {
        di as txt "{it:Note: bsalpha() is deprecated. Use level() instead.}"
        di as txt "{it:  bsalpha(`bsalpha') is equivalent to level(" %3.0f (1-`bsalpha')*100 ")}"
    }
    else {
        local bsalpha = 1 - `level'/100
    }

    // --- Estimation sample -------------------------------------------------
    marksample touse
    markout `touse' `panelvar' `timevar'
    if "`weight_var'" != "" {
        markout `touse' `weight_var'
    }

    // --- Header (display deferred to post-estimation table) -----------------

    // --- Load auxiliary ado-files -----------------------------------------
    // Each helper is loaded on demand: first from the PLUS sysdir, then the
    // current working directory, and finally via findfile along the adopath.
    foreach prog in _trop_load_plugin _trop_set_grid ///
                    _trop_validate_params ///
                    trop_handle_error trop_validate {
        capture program list `prog'
        if _rc {
            local _fl = substr("`prog'", 1, 1)
            capture quietly run "`c(sysdir_plus)'`_fl'/`prog'.ado"
            if _rc {
                capture quietly run "`c(pwd)'/`prog'.ado"
                if _rc {
                    capture quietly findfile `prog'.ado
                    if !_rc {
                        quietly run "`r(fn)'"
                    }
                }
            }
        }
    }

    // --- Plugin loading ---------------------------------------------------
    capture _trop_load_plugin
    if _rc {
        di as error "Error: TROP plugin not found. The compiled plugin is required."
        di as error ""
        di as error "Platform: `c(os)' `c(machine_type)'"
        di as error "Please install the TROP plugin for your platform."
        di as error "See {help trop##installation:trop installation} for details."
        exit 601
    }
    
    // --- One-time data deployment ------------------------------------------
    // Silently deploy example datasets to adopath on first invocation.
    // Uses findfile as sentinel; no-ops if data already cached.
    capture noisily _trop_deploy_data

    // --- Verbose level (early resolution) ----------------------------------
    // Resolve level here so that display guards below can use numeric thresholds.
    // The scalar write and backward-compat shim remain at the later block.
    local _verbose_level = 1
    if `vlevel' >= 0 {
        local _verbose_level = `vlevel'
    }
    else if "`verbose'" != "" {
        local _verbose_level = 2
    }

    // --- Lambda grid construction ------------------------------------------
    // Build the three-dimensional grid (lambda_time, lambda_unit, lambda_nn)
    // over which LOOCV minimizes Q(lambda).
    if `_verbose_level' >= 3 {
        di as txt _n "Setting lambda grids..."
    }

    _trop_set_grid, grid_style(`grid_style') ///
        lambda_time_grid(`lambda_time_grid') ///
        lambda_unit_grid(`lambda_unit_grid') ///
        lambda_nn_grid(`lambda_nn_grid')

    local lambda_time_grid "`_lambda_time_grid'"
    local lambda_unit_grid "`_lambda_unit_grid'"
    local lambda_nn_grid "`_lambda_nn_grid'"
    local grid_style "`_grid_style'"
    local n_combinations = `_n_combinations'
    local n_per_cycle = `_n_per_cycle'

    if `_verbose_level' >= 3 {
        di as txt "  Grid style: `_grid_style'"
        di as txt "  lambda_time: `_n_time' values"
        di as txt "  lambda_unit: `_n_unit' values"
        di as txt "  lambda_nn: `_n_nn' values"
        di as txt "  Grid points (Cartesian): `n_combinations'"
        di as txt "  Evaluations per cycle (coordinate descent): `n_per_cycle'"
    }

    // --- Parameter validation ---------------------------------------------
    if `_verbose_level' >= 3 {
        di as txt _n "Validating parameters..."
    }

    _trop_validate_params, depvar(`depvar') treatvar(`treatvar') ///
        panelvar(`panelvar') timevar(`timevar') ///
        method(`method') grid_style(`grid_style') ///
        lambda_time_grid(`lambda_time_grid') ///
        lambda_unit_grid(`lambda_unit_grid') ///
        lambda_nn_grid(`lambda_nn_grid') ///
        bootstrap(`bootstrap') bsalpha(`bsalpha') ///
        tol(`tol') maxiter(`maxiter') ///
        seed(`seed') ///
        touse(`touse')

    if `_verbose_level' >= 3 {
        di as txt "  All parameters valid"
    }

    // --- Covariate validation ------------------------------------------------
    local _n_covariates = 0
    if "`covariates'" != "" {
        // Check each covariate is numeric
        foreach var of local covariates {
            capture confirm numeric variable `var'
            if _rc {
                di as error "covariate '`var'' must be a numeric variable"
                exit 111
            }
        }
        // Covariates must not overlap with depvar or treatvar
        foreach var of local covariates {
            if "`var'" == "`depvar'" | "`var'" == "`treatvar'" {
                di as error "covariate '`var'' cannot be the outcome or treatment variable"
                exit 198
            }
        }
        // Check for missing values in the estimation sample
        foreach var of local covariates {
            quietly count if missing(`var') & `touse'
            if r(N) > 0 {
                display as error "covariate `var' has `r(N)' missing value(s) in the estimation sample"
                display as error "TROP requires complete covariate data. Options:"
                display as error "  1. Drop observations: drop if missing(`var')"
                display as error "  2. Impute missing values before estimation"
                exit 416
            }
        }
        local _n_covariates : word count `covariates'
        if `_verbose_level' >= 3 {
            di as txt "  Covariates (`_n_covariates'): `covariates'"
        }
    }

    // --- Mata function loading --------------------------------------------
    // Mata routines must be available before data validation, which calls
    // into Mata for panel structure checks.
    _trop_load_mata
    
    // --- Data validation ---------------------------------------------------
    if `_verbose_level' >= 3 {
        di as txt _n "Validating data..."
    }

    // Drop temporary variables that may persist from a prior estimation run
    _trop_cleanup_vars

    if `_verbose_level' >= 3 {
        capture noisily trop_validate `depvar' `treatvar' if `touse', ///
            panelvar(`panelvar') timevar(`timevar') method(`method')
    }
    else {
        capture trop_validate `depvar' `treatvar' if `touse', ///
            panelvar(`panelvar') timevar(`timevar') method(`method')
    }

    if _rc != 0 {
        if `_verbose_level' < 3 {
            // Re-run with output so the user can see what failed
            noisily trop_validate `depvar' `treatvar' if `touse', ///
                panelvar(`panelvar') timevar(`timevar') method(`method')
        }
        di as error _n "Data validation failed."
        exit _rc
    }

    if e(data_validated) != 1 {
        di as error _n "Data validation did not pass (e(data_validated)=0)"
        exit 459
    }

    local N = e(N)
    local T_val = e(T)
    local N_obs = e(N_obs)
    local N_treat = e(N_treat)
    local N_control = `N_obs' - `N_treat'

    // Cache validation diagnostics in locals; ereturn post (below) clears
    // all e() scalars and macros.
    local balanced = e(balanced)
    local miss_rate = e(miss_rate)
    local N_treated_units = e(N_treated_units)
    local T_treat_periods = e(T_treat_periods)
    local treatment_pattern "`e(treatment_pattern)'"
    local N_control_units = e(N_control_units)
    local min_pre_treated = e(min_pre_treated)
    local min_valid_pairs = e(min_valid_pairs)
    local has_switching = e(has_switching)
    local max_switches = e(max_switches)
    local data_validated = e(data_validated)
    local time_min = e(time_min)
    local time_max = e(time_max)
    local time_range = e(time_range)
    local n_pre_periods = e(n_pre_periods)
    local n_post_periods = e(n_post_periods)

    if `_verbose_level' >= 3 {
        di as txt "  Data validation passed"
        di as txt "  Units (N): `N'"
        di as txt "  Periods (T): `T_val'"
        di as txt "  Observations: `N_obs'"
        di as txt "  Treated: `N_treat' (" %4.1f 100*`N_treat'/`N_obs' "%)"
        di as txt "  Control: `N_control' (" %4.1f 100*`N_control'/`N_obs' "%)"
    }

    // --- Method-pattern compatibility check -------------------------------
    // The joint method solves a single weighted least-squares problem for a
    // scalar tau, which requires all treated units to share the same adoption
    // period.  Staggered adoption violates this assumption.
    if "`method'" == "joint" & inlist("`treatment_pattern'", "staggered_adoption", "switching_treatment") {
        di as error _n "{bf:ERROR: method('joint') requires simultaneous treatment adoption}"
        if "`treatment_pattern'" == "switching_treatment" {
            di as error "Your data shows switching treatment (units turn treatment on and off)."
        }
        else {
            di as error "Your data shows staggered adoption (units first treated at different periods)."
        }
        di as error ""
        di as error "The joint method estimates a single scalar tau with shared weights,"
        di as error "which assumes all treated units begin treatment at the same period"
        di as error "and remain treated afterwards (absorbing state)."
        di as error "This treatment pattern violates that assumption and would produce"
        di as error "incorrect results."
        di as error ""
        di as error "Solution: Use method('twostep') which estimates individual treatment"
        di as error "effects per (unit, period) pair and supports arbitrary 0/1 designs."
        di as error ""
        di as error "  trop `depvar' `treatvar', panelvar(`panelvar') timevar(`timevar') method(twostep)"
        exit 459
    }
    
    // --- Panel and time index variables ------------------------------------
    // Create consecutive integer indices for the plugin, which expects
    // 1-based contiguous identifiers.
    tempvar panel_idx time_idx
    qui egen `panel_idx' = group(`panelvar') if `touse'
    qui egen `time_idx' = group(`timevar') if `touse'
    sort `panel_idx' `time_idx'

    // --- Survey design options (Rao-Wu bootstrap) -------------------------
    // When strata/psu/fpc is specified, mark survey design active and pass
    // variable names to the Mata layer via globals.  The Mata function
    // trop_prepare_survey_design() will collapse obs-level values to
    // unit-level, encode them as integers, and store matrices.
    local _has_survey_design = 0
    local _survey_nest = 0
    if "`strata'" != "" | "`psu'" != "" | "`fpc'" != "" {
        local _has_survey_design = 1
        // Validate: strata is required when psu or fpc is specified
        if "`strata'" == "" {
            di as error "strata() is required when psu() or fpc() is specified."
            exit 198
        }
        // Validate: psu is required when strata is specified
        if "`psu'" == "" {
            di as error "psu() is required when strata() is specified."
            exit 198
        }
        // Validate that survey variables exist and are numeric
        capture confirm numeric variable `strata'
        if _rc {
            di as error "strata() variable '`strata'' not found or not numeric."
            exit 111
        }
        capture confirm numeric variable `psu'
        if _rc {
            di as error "psu() variable '`psu'' not found or not numeric."
            exit 111
        }
        if "`fpc'" != "" {
            capture confirm numeric variable `fpc'
            if _rc {
                di as error "fpc() variable '`fpc'' not found or not numeric."
                exit 111
            }
        }
        // nest option
        if "`nest'" != "" {
            local _survey_nest = 1
        }
        // Store survey metadata in globals for the Mata layer
        mata: st_global("__trop_strata_var", "`strata'")
        mata: st_global("__trop_psu_var", "`psu'")
        mata: st_global("__trop_fpc_var", "`fpc'")
        scalar __trop_has_survey_design = 1
        scalar __trop_survey_nest = `_survey_nest'
        // Parse singleunit() option for lonely PSU handling
        // Codes: 0 = skip (default backward compat), 1 = centered
        local _lonely_psu_code = 0  // default: skip (backward compatible)
        if "`singleunit'" != "" {
            if "`singleunit'" == "skip" {
                local _lonely_psu_code = 0
            }
            else if "`singleunit'" == "centered" {
                local _lonely_psu_code = 1
            }
            else {
                di as error "singleunit() must be 'centered' or 'skip'; got '`singleunit''"
                exit 198
            }
        }
        scalar __trop_lonely_psu = `_lonely_psu_code'
        if "`verbose'" != "" {
            di as txt _n "Survey design detected (Rao-Wu bootstrap):"
            di as txt "  Strata: `strata'"
            di as txt "  PSU: `psu'"
            if "`fpc'" != "" {
                di as txt "  FPC: `fpc'"
            }
            if `_survey_nest' {
                di as txt "  Nest: PSU nested within strata"
            }
        }
    }
    else {
        scalar __trop_has_survey_design = 0
        scalar __trop_survey_nest = 0
        scalar __trop_lonely_psu = 0
        mata: st_global("__trop_strata_var", "")
        mata: st_global("__trop_psu_var", "")
        mata: st_global("__trop_fpc_var", "")
    }

    // --- Transfer lambda grids to Stata matrices -------------------------
    // The plugin reads grids from named matrices __trop_lambda_*_grid.
    // Boundary encoding (inf -> 0 for time/unit, inf -> 1e10 for nn) is
    // performed by the C bridge layer, not here.
    local n_time : word count `lambda_time_grid'
    tempname mat_time_tmp mat_unit_tmp mat_nn_tmp
    matrix `mat_time_tmp' = J(1, `n_time', .)
    local i = 1
    foreach val of local lambda_time_grid {
        matrix `mat_time_tmp'[1, `i'] = `val'
        local ++i
    }
    matrix __trop_lambda_time_grid = `mat_time_tmp'

    local n_unit : word count `lambda_unit_grid'
    matrix `mat_unit_tmp' = J(1, `n_unit', .)
    local i = 1
    foreach val of local lambda_unit_grid {
        matrix `mat_unit_tmp'[1, `i'] = `val'
        local ++i
    }
    matrix __trop_lambda_unit_grid = `mat_unit_tmp'

    local n_nn : word count `lambda_nn_grid'
    matrix `mat_nn_tmp' = J(1, `n_nn', .)
    local i = 1
    foreach val of local lambda_nn_grid {
        matrix `mat_nn_tmp'[1, `i'] = `val'
        local ++i
    }
    matrix __trop_lambda_nn_grid = `mat_nn_tmp'

    // --- Fixed lambda option ----------------------------------------------
    // fixedlambda(lambda_time lambda_unit lambda_nn) bypasses LOOCV and
    // uses the supplied triplet directly for estimation.
    local run_cv = 1
    local lambda_time_fixed = 0
    local lambda_unit_fixed = 0
    local lambda_nn_fixed = 0
    local lambda_time_val = .
    local lambda_unit_val = .
    local lambda_nn_val = .

    if "`fixedlambda'" != "" {
        // Detect named format: lt()/lu()/lnn()
        local _fl_named = 0
        if strpos("`fixedlambda'", "lt(") > 0 | strpos("`fixedlambda'", "lu(") > 0 | strpos("`fixedlambda'", "lnn(") > 0 {
            local _fl_named = 1
        }

        if `_fl_named' {
            // Parse named format: fixedlambda(lt(#) lu(#) lnn(#))
            local _tmp "`fixedlambda'"
            local lambda_time_val ""
            local lambda_unit_val ""
            local lambda_nn_val ""

            // Extract lt(value)
            if regexm("`_tmp'", "lt\\(([^)]+)\\)") {
                local lambda_time_val = regexs(1)
            }
            // Extract lu(value)
            if regexm("`_tmp'", "lu\\(([^)]+)\\)") {
                local lambda_unit_val = regexs(1)
            }
            // Extract lnn(value)
            if regexm("`_tmp'", "lnn\\(([^)]+)\\)") {
                local lambda_nn_val = regexs(1)
            }

            // Validate all three parameters provided
            if "`lambda_time_val'" == "" | "`lambda_unit_val'" == "" | "`lambda_nn_val'" == "" {
                di as error "fixedlambda() named format requires all three: lt(#) lu(#) lnn(#)"
                di as error "  lt  = lambda_time (Eq.3 time decay parameter)"
                di as error "  lu  = lambda_unit (Eq.3 unit decay parameter)"
                di as error "  lnn = lambda_nn (nuclear norm regularization)"
                exit 198
            }
        }
        else {
            // Positional format: fixedlambda(lambda_time lambda_unit lambda_nn)
            local n_fixed : word count `fixedlambda'
            if `n_fixed' != 3 {
                di as error "fixedlambda() requires exactly 3 values: lambda_time lambda_unit lambda_nn"
                di as error "  or use named format: fixedlambda(lt(#) lu(#) lnn(#))"
                exit 198
            }
            local lambda_time_val : word 1 of `fixedlambda'
            local lambda_unit_val : word 2 of `fixedlambda'
            local lambda_nn_val : word 3 of `fixedlambda'
        }

        // λ_time and λ_unit must be non-negative finite numbers.  Per paper
        // Eq 3 the weights θ,ω are exp(−λ·dist); λ_time/λ_unit = ∞ would
        // collapse all weight to the target period/unit only, which is
        // degenerate and not a supported estimator configuration.
        foreach lname in lambda_time_val lambda_unit_val {
            // Detect the literal "." (Stata missing) before `confirm number`,
            // which rejects "." even though numlist(missingokay) accepts it.
            if "``lname''" == "." {
                di as error "fixedlambda() does not accept `.' (missing / inf) for lambda_time or lambda_unit."
                di as error "  Paper Eq 3: θ_s = exp(−lambda_time·|t−s|), ω_j = exp(−lambda_unit·dist)."
                di as error "  lambda_time = lambda_unit = 0 recovers uniform weights; use finite values ≥ 0."
                exit 198
            }
            capture confirm number ``lname''
            if _rc {
                di as error "fixedlambda() values must be numeric: found '``lname''"
                exit 198
            }
            if ``lname'' < 0 {
                di as error "fixedlambda() values must be non-negative"
                exit 198
            }
        }

        // λ_nn = missing / inf is the DID/TWFE special case (L ≡ 0).
        // Map to the large-finite sentinel 1e10 recognized by the C bridge.
        if "`lambda_nn_val'" == "." {
            local lambda_nn_val = 1e10
            if "`verbose'" != "" {
                di as txt "  lambda_nn = . (inf) → mapped to 1e10 (DID/TWFE special case: L ≡ 0)"
            }
        }
        else {
            capture confirm number `lambda_nn_val'
            if _rc {
                di as error "fixedlambda() values must be numeric: found '`lambda_nn_val''"
                exit 198
            }
            if `lambda_nn_val' < 0 {
                di as error "fixedlambda() lambda_nn must be non-negative (use . for +inf)"
                exit 198
            }
        }

        local run_cv = 0
        local lambda_time_fixed = 1
        local lambda_unit_fixed = 1
        local lambda_nn_fixed = 1

        if "`verbose'" != "" {
            di as txt "  Fixed lambda (LOOCV skipped):"
            di as txt "    lambda_time = `lambda_time_val'"
            di as txt "    lambda_unit = `lambda_unit_val'"
            di as txt "    lambda_nn   = `lambda_nn_val'"
        }
    }
    
    // --- Timing estimate (pure display, no effect on computation) ----------
    // Based on algorithm complexity: twostep O(grid×N_treated×iters×N×T),
    // joint O(grid×iters×N×T), plus bootstrap multiplier.
    if "`notiming'" == "" {
        local _panel_size = `N' * `T_val'
        if `_panel_size' >= 50000 {
            // Calibration constants (conservative, macOS ARM64 baseline)
            local _ops_per_sec = 50000000
            local _avg_iters = 30

            // LOOCV cost
            if `run_cv' {
                if "`method'" == "twostep" {
                    local _complexity = `n_combinations' * `N_treated_units' * `_avg_iters' * `_panel_size'
                }
                else {
                    local _complexity = `n_combinations' * `_avg_iters' * `_panel_size'
                }
            }
            else {
                // fixedlambda: only estimation, no grid search
                if "`method'" == "twostep" {
                    local _complexity = `N_treated_units' * `_avg_iters' * `_panel_size'
                }
                else {
                    local _complexity = `_avg_iters' * `_panel_size'
                }
            }

            // Bootstrap multiplier
            if `bootstrap' > 0 {
                if "`method'" == "twostep" {
                    local _bs_cost = `bootstrap' * `N_treated_units' * `_avg_iters' * `_panel_size'
                }
                else {
                    local _bs_cost = `bootstrap' * `_avg_iters' * `_panel_size'
                }
                local _complexity = `_complexity' + `_bs_cost'
            }

            local _est_seconds = `_complexity' / `_ops_per_sec'

            if `_panel_size' >= 500000 {
                local _est_minutes = `_est_seconds' / 60
                di as txt _n "{it:Estimated time: ~" %4.1f `_est_minutes' " min}"
            }
            else {
                di as txt _n "{it:Estimated time: ~" %4.0f `_est_seconds' " sec}"
            }
            di as txt "{it:(use notiming to suppress)}"
        }
    }

    // --- Estimation --------------------------------------------------------
    if "`verbose'" != "" {
        di as txt _n "Running TROP estimation..."
        di as txt "  Method: `method'"
        if `run_cv' {
            di as txt "  LOOCV: enabled"
        }
        else {
            di as txt "  LOOCV: disabled (using fixed lambda)"
        }
        if `bootstrap' > 0 {
            di as txt "  Bootstrap: `bootstrap' replications (paper Alg 3)"
        }
        else {
            di as txt "  Bootstrap: skipped (user requested bootstrap(0))"
        }
    }

    // --- Verbose level resolution -------------------------------------------
    // vlevel() takes precedence; otherwise `verbose` flag => level 2 (DETAILED);
    // default (neither specified) => level 1 (NORMAL: progress milestones).
    // Level 0 (QUIET) suppresses all non-error output.
    local _verbose_level = 1
    if `vlevel' >= 0 {
        local _verbose_level = `vlevel'
    }
    else if "`verbose'" != "" {
        local _verbose_level = 2
    }
    local verbose_flag = `_verbose_level'
    // Write verbose level to Stata scalar for plugin consumption.
    // The C bridge reads __trop_verbose_level at each plugin call entry.
    scalar __trop_verbose_level = `_verbose_level'
    // Ensure backward-compat: existing `if "`verbose'" != ""` guards fire
    // whenever the resolved level is >= 2 (DETAILED).
    if `_verbose_level' >= 2 & "`verbose'" == "" {
        local verbose "verbose"
    }
    local cv_mode = "exact"

    // The seed is forwarded to the plugin's internal RNG; Stata's global
    // RNG state is left unchanged.

    // Transfer joint_loocv() / twostep_loocv() modes to the Mata layer via
    // global macros.  The Mata dispatcher _trop_main reads the corresponding
    // global and routes to the cycling or exhaustive search variant when
    // LOOCV is enabled.
    //
    // The globals are set via Mata's st_global() because Stata's `global`
    // command rejects names with a leading underscore (r(198)), whereas
    // Mata's st_global() accepts any identifier.
    mata: st_global("__trop_joint_loocv_mode", "`joint_loocv'")
    mata: st_global("__trop_twostep_loocv_mode", "`twostep_loocv'")

    // Resolve bsvariance() into an integer ddof forwarded to the plugin.
    // "sample"            -> 1 (Bessel-corrected, default, matches
    //                         pre-existing Stata behavior)
    // "paper"|"population"-> 0 (paper Algorithm 3 denominator 1/B)
    // Empty string        -> "." (defer to Mata default; preserves the
    //                         historical wire format and avoids forcing a
    //                         scalar when the user did not request it).
    local _bsvar = trim(lower("`bsvariance'"))
    if "`_bsvar'" == "" {
        local _ddof_arg "."
    }
    else if "`_bsvar'" == "sample" {
        local _ddof_arg "1"
    }
    else if "`_bsvar'" == "paper" | "`_bsvar'" == "population" {
        local _ddof_arg "0"
    }
    else {
        di as error "bsvariance() must be 'sample' or 'paper'"
        exit 198
    }

    // Resolve cimethod() into a canonical label.  The primary CI surfaced
    // via e(ci_lower)/e(ci_upper) is selected here:
    //   percentile : Algorithm 3 default — distribution-free quantiles of
    //                the bootstrap empirical CDF; requires bootstrap > 0.
    //   t          : Gaussian large-sample wrap with t(N_1 - 1) tails.
    //   normal     : Gaussian large-sample wrap with standard-normal tails.
    //   <empty>    : auto = "percentile" whenever bootstrap > 0,
    //                "t" otherwise (SE is missing without bootstrap).
    // When the user requested bootstrap(0) but also cimethod(percentile)
    // we downgrade to "t" and print a note; percentile CI cannot be
    // produced without the empirical distribution.
    local _cimethod = trim(lower("`cimethod'"))
    if "`_cimethod'" == "" {
        if `bootstrap' > 0 {
            local _cimethod "percentile"
        }
        else {
            local _cimethod "t"
        }
    }
    if !inlist("`_cimethod'", "percentile", "t", "normal") {
        di as error "cimethod() must be one of {bf:percentile}, {bf:t}, or {bf:normal}"
        exit 198
    }
    if "`_cimethod'" == "percentile" & `bootstrap' <= 0 {
        di as txt "{it:Note: cimethod(percentile) requires bootstrap > 0; falling back to cimethod(t).}"
        local _cimethod "t"
    }
    mata: st_global("__trop_cimethod", "`_cimethod'")

    // --- Prepare covariates for plugin ----------------------------------------
    if `_n_covariates' > 0 {
        mata: st_local("_cov_rc", strofreal(trop_prepare_covariates( ///
            tokens("`covariates'"), "`panel_idx'", "`time_idx'", ///
            "`touse'", `N', `T_val')))
        if `_cov_rc' != 0 {
            di as error "Failed to prepare covariate matrix"
            exit 459
        }
    }
    else {
        // Ensure no stale covariates from prior run
        mata: st_numscalar("__trop_n_covariates", 0)
    }

    // --- LOOCV computational cost advisory --------------------------------
    if `run_cv' & `_verbose_level' >= 1 & `N_control' > 500 {
        di as txt "Note: LOOCV with `N_control' control cells may take several minutes."
    }

    // Dispatch to the compiled plugin through the Mata interface layer.
    // trop_main() returns 0 on success or a Stata return code on failure.
    // An empty `weight_var' is treated as "no pweight" by the Mata entry
    // point (the args() >= 18 guard degrades gracefully).
    mata: st_local("_trop_rc", strofreal(trop_main("`depvar'", "`treatvar'", "`panel_idx'", ///
        "`time_idx'", "`touse'", "`method'", ///
        `lambda_time_val', `lambda_unit_val', `lambda_nn_val', ///
        `run_cv', `bootstrap', `seed', `verbose_flag', ///
        `maxiter', `tol', `bsalpha', `_ddof_arg', "`weight_var'")))

    // Clear the globals once the Mata call returns so that stale state does
    // not leak into the next estimation.  Setting to "" via st_global is
    // equivalent to dropping from the Mata perspective.  Keep
    // __trop_cimethod until trop_store_results has consumed it (cleared
    // further below, after the ereturn post cycle).
    mata: st_global("__trop_joint_loocv_mode", "")
    mata: st_global("__trop_twostep_loocv_mode", "")

    // --- Post e(b) and e(V) ----------------------------------------------
    // ereturn post clears all prior e() contents, so it must precede the
    // storage of any other e() scalars or macros.

    if `_trop_rc' != 0 {
        di as error "Estimation failed (error code `_trop_rc')"
        exit `_trop_rc'
    }

    // Retrieve point estimate and standard error from plugin temporaries
    local _att_val = .
    capture local _att_val = scalar(__trop_att)
    local _se_val = .
    capture local _se_val = scalar(__trop_se)

    if missing(`_att_val') {
        di as error "Estimation failed: ATT is missing"
        exit 498
    }

    // Build b (1x1) and, when available, V (1x1).  No closed-form
    // asymptotic variance exists for the TROP estimator; V is populated
    // only when bootstrap inference has been performed.
    tempname _b
    matrix `_b' = (`_att_val')
    matrix colnames `_b' = att
    // `ereturn post … esample(var)` consumes `var` (it is dropped from the
    // data and preserved only as e(sample)).  Downstream Mata code still
    // needs to read the touse variable, so clone it into a fresh tempvar
    // before posting.  The clone is dropped automatically at program exit.
    tempvar _touse_esample
    qui gen byte `_touse_esample' = `touse'
    if `_se_val' > 0 & !missing(`_se_val') {
        tempname _V
        matrix `_V' = (`_se_val' ^ 2)
        matrix colnames `_V' = att
        matrix rownames `_V' = att
        ereturn post `_b' `_V', esample(`_touse_esample')
    }
    else {
        ereturn post `_b', esample(`_touse_esample')
    }

    // Expose the tempvar names so trop_store_results can build the
    // (time x unit) tau matrix by re-reading treatment coordinates.
    // Global macros are cleared automatically by trop_cleanup_temp_vars.
    mata: st_global("__trop_treatvar", "`treatvar'")
    mata: st_global("__trop_panel_idx_var", "`panel_idx'")
    mata: st_global("__trop_time_idx_var", "`time_idx'")

    // Build specification string for e(spec_string) — records the call
    // parameters so downstream consumers can reproduce the estimation.
    mata: st_global("__trop_spec_string", "method(`method'), lambda_time(`lambda_time_val'), lambda_unit(`lambda_unit_val'), lambda_nn(`lambda_nn_val')")
    if "`covariates'" != "" {
        mata: st_global("__trop_spec_string", st_global("__trop_spec_string") + ", covariates(`covariates')")
    }

    // Transfer remaining estimation results from plugin temporaries to e()
    mata: trop_store_results("`method'")

    // Now safe to release the cimethod global (trop_store_results has
    // already read it and written e(cimethod)).
    mata: st_global("__trop_cimethod", "")
    
    // --- Deferred error flag ------------------------------------------------
    local _fatal_rc = 0

    // --- LOOCV diagnostics ------------------------------------------------
    capture confirm scalar __trop_loocv_n_attempted
    if !_rc {
        mata: store_loocv_diagnostics("`method'", `seed')

        if "`verbose'" != "" {
            mata: display_loocv_verbose()
        }

        // A high LOOCV failure rate signals numerical problems; defer the
        // error exit until all e() results have been stored.
        mata: st_local("loocv_rc", strofreal(check_loocv_fail_rate()))
        if `loocv_rc' != 0 {
            local _fatal_rc = `loocv_rc'
        }
    }

    // --- Capture deferred fatal errors ------------------------------------
    // Bootstrap or LOOCV may flag a fatal condition via __trop_fatal_rc;
    // read it before temporary scalars are dropped.
    if `_fatal_rc' == 0 {
        capture confirm scalar __trop_fatal_rc
        if !_rc {
            local _fatal_rc = scalar(__trop_fatal_rc)
        }
    }

    // --- Store lambda grids in e() ----------------------------------------
    capture ereturn matrix lambda_time_grid = __trop_lambda_time_grid
    capture ereturn matrix lambda_unit_grid = __trop_lambda_unit_grid
    capture ereturn matrix lambda_nn_grid = __trop_lambda_nn_grid

    // --- Save gamma before cleanup ----------------------------------------
    // __trop_gamma is produced by the plugin and will be destroyed by
    // trop_cleanup_temp_vars().  Preserve it in a tempname matrix so that
    // the ereturn section further below can store e(gamma).
    tempname _gamma_saved
    capture confirm matrix __trop_gamma
    if !_rc {
        matrix `_gamma_saved' = __trop_gamma
    }

    // --- Drop plugin temporaries ------------------------------------------
    // All code that reads __trop_* scalars or matrices must appear above.
    capture scalar drop __trop_att __trop_se
    capture scalar drop __trop_deff_weights __trop_max_fh __trop_n_high_fpc
    capture mata: trop_cleanup_temp_vars()

    // --- Store estimation metadata ----------------------------------------
    ereturn local method "`method'"
    ereturn local grid_style "`grid_style'"
    ereturn local joint_loocv "`joint_loocv'"
    ereturn local twostep_loocv "`twostep_loocv'"
    ereturn local cmd "trop"
    ereturn local estat_cmd "trop_estat"
    ereturn local cmdline "trop `0'"
    ereturn local depvar "`depvar'"
    ereturn local treatvar "`treatvar'"
    ereturn local panelvar "`panelvar'"
    ereturn local timevar "`timevar'"

    // --- Attach original-ID row names to e(alpha) and e(beta) ------------
    // e(alpha) and e(beta) are N x 1 and T x 1 vectors ordered by the
    // consecutive group() index on (panelvar, timevar).  Users want to
    // read them keyed by the original panel / time identifiers rather
    // than by the 1..N / 1..T index.  We query `levelsof` on the
    // estimation sample (same order as `egen ... = group(...)` inside
    // the preparation path) and apply the values as matrix row names,
    // sanitising each to a valid Stata matrix name.  The helper is
    // silent on mismatch so any future change to panel indexing leaves
    // the core estimation unharmed.
    capture _trop_attach_idnames `panelvar' `timevar'

    // Covariate metadata
    if `_n_covariates' > 0 {
        ereturn local covariates "`covariates'"
        ereturn scalar n_covariates = `_n_covariates'
        // Store gamma coefficients from the pre-cleanup saved copy
        capture confirm matrix `_gamma_saved'
        if !_rc {
            tempname _gamma_mat
            matrix `_gamma_mat' = `_gamma_saved'
            // Name columns with covariate names
            local _cov_names ""
            foreach var of local covariates {
                local _cov_names "`_cov_names' `var'"
            }
            matrix colnames `_gamma_mat' = `_cov_names'
            ereturn matrix gamma = `_gamma_mat'
        }
    }
    else {
        ereturn scalar n_covariates = 0
    }

    // Survey-design metadata.  Populated only when [pweight] was supplied;
    // downstream post-estimation commands (e.g. `trop_bootstrap`) branch
    // on a non-empty e(weight_var) to enable the weighted Rust path.
    if "`weight_var'" != "" {
        ereturn local wtype "pweight"
        ereturn local wexp "= `weight_var'"
        ereturn local weight_var "`weight_var'"
    }

    // Survey design metadata
    if `_has_survey_design' {
        ereturn local strata_var "`strata'"
        ereturn local psu_var "`psu'"
        if "`fpc'" != "" {
            ereturn local fpc_var "`fpc'"
        }
        ereturn scalar has_survey_design = 1
        ereturn scalar survey_nest = `_survey_nest'
        ereturn local bootstrap_type "rao_wu"
        // Survey diagnostics: DEFF and high-FPC (P2 diagnostics)
        capture confirm scalar __trop_deff_weights
        if !_rc {
            ereturn scalar deff_weights = scalar(__trop_deff_weights)
        }
        capture confirm scalar __trop_max_fh
        if !_rc {
            ereturn scalar max_fh = scalar(__trop_max_fh)
        }
        capture confirm scalar __trop_n_high_fpc
        if !_rc {
            ereturn scalar n_high_fpc = scalar(__trop_n_high_fpc)
        }
    }
    else {
        ereturn scalar has_survey_design = 0
        ereturn local bootstrap_type "standard"
    }

    ereturn scalar N_units = `N'
    ereturn scalar N_periods = `T_val'
    ereturn scalar bootstrap_reps = `bootstrap'
    ereturn scalar alpha_level = `bsalpha'
    ereturn scalar loocv_used = `run_cv'
    if `bootstrap' > 0 {
        ereturn local vcetype "Bootstrap"
    }
    else {
        ereturn local vcetype ""
    }

    // Record the bootstrap-variance denominator for transparency.  An
    // empty bsvariance() option defers to the Rust default (sample).
    if "`_bsvar'" == "" {
        ereturn local bsvariance "sample"
    }
    else {
        ereturn local bsvariance "`_bsvar'"
    }

    // e(cimethod) is populated by trop_store_results() above and already
    // reflects percentile->t downgrade when applicable; no ADO-side
    // override here.

    // LOOCV configuration scalars
    ereturn scalar seed = `seed'

    // Lambda grid dimensions
    ereturn scalar n_lambda_time = `_n_time'
    ereturn scalar n_lambda_unit = `_n_unit'
    ereturn scalar n_lambda_nn = `_n_nn'
    ereturn scalar n_grid_combinations = `n_combinations'
    // Coordinate-descent LOOCV evaluates n_time + n_unit + n_nn grid points
    // per cycle (one univariate sweep per regularization parameter).
    ereturn scalar n_grid_per_cycle = `n_per_cycle'

    // --- Restore validation diagnostics -----------------------------------
    // These were cached in locals before ereturn post cleared e().
    ereturn scalar N = `N_obs'
    ereturn scalar N_obs = `N_obs'
    ereturn scalar balanced = `balanced'
    ereturn scalar miss_rate = `miss_rate'
    ereturn scalar N_treat = `N_treat'
    ereturn scalar N_control = `N_control'
    ereturn scalar N_treated_units = `N_treated_units'
    ereturn scalar T_treat_periods = `T_treat_periods'
    ereturn local treatment_pattern "`treatment_pattern'"
    ereturn scalar N_control_units = `N_control_units'
    ereturn scalar min_pre_treated = `min_pre_treated'
    ereturn scalar min_valid_pairs = `min_valid_pairs'
    ereturn scalar has_switching = `has_switching'
    ereturn scalar max_switches = `max_switches'
    if !missing(`n_pre_periods') {
        ereturn scalar n_pre_periods = `n_pre_periods'
    }
    if !missing(`n_post_periods') {
        ereturn scalar n_post_periods = `n_post_periods'
    }
    if !missing(`data_validated') {
        ereturn scalar data_validated = `data_validated'
    }
    if !missing(`time_min') {
        ereturn scalar time_min = `time_min'
    }
    if !missing(`time_max') {
        ereturn scalar time_max = `time_max'
    }
    if !missing(`time_range') {
        ereturn scalar time_range = `time_range'
    }

    // --- Cleanup temporary dataset variables ------------------------------
    _trop_cleanup_vars

    // --- Data integrity for predict consistency ----------------------------
    // The _depvar_checksum (below) provides a lightweight mechanism for
    // detecting whether the data has changed since estimation.  A full
    // datasignature is not stored because tempvars still exist in-scope
    // when this code runs, producing a false-positive mismatch after the
    // program returns and Stata drops those tempvars.

    // Lightweight checksum on the dependent variable
    capture {
        qui sum `depvar' if e(sample), meanonly
        ereturn scalar _depvar_checksum = r(sum)
    }

    // --- Deferred fatal error exit ----------------------------------------
    // Issued after all e() storage so that captured runs retain partial
    // results for diagnostic inspection.
    if `_fatal_rc' != 0 {
        exit `_fatal_rc'
    }
    
    // --- Display results (Stata standard format) --------------------------------

    local att = e(att)
    local se = e(se)
    local ci_lower = e(ci_lower)
    local ci_upper = e(ci_upper)
    local pvalue = e(pvalue)
    local tstat = e(t)

    // ─── Header with right-aligned metadata ─────────────────────────────────────
    di as txt ""
    di as txt "{hline 78}"
    local _col2 = 49
    di as txt "Triply Robust Panel Estimator" ///
        _col(`_col2') "Number of obs"   _col(68) "=" _col(70) as res %8.0fc `N_obs'
    di as txt "Method: " as res "`method'" ///
        _col(`_col2') as txt "Number of units" _col(68) "=" _col(70) as res %8.0fc `N'
    di as txt "" ///
        _col(`_col2') "Time periods"    _col(68) "=" _col(70) as res %8.0fc `T_val'
    di as txt "" ///
        _col(`_col2') "Treated obs"     _col(68) "=" _col(70) as res %8.0fc `N_treat'
    if `bootstrap' > 0 {
        di as txt "" ///
            _col(`_col2') "Bootstrap reps"  _col(68) "=" _col(70) as res %8.0fc `bootstrap'
    }

    // ─── Coefficient table ──────────────────────────────────────────────────────
    di as txt "{hline 13}{c TT}{hline 64}"
    if `bootstrap' > 0 {
        di as txt _col(14) "{c |}" ///
            _col(21) "ATT" ///
            _col(31) "Std. err." ///
            _col(44) "t" ///
            _col(50) "P>|t|" ///
            _col(59) "[`level'% conf. interval]"
    }
    else {
        di as txt _col(14) "{c |}" _col(21) "ATT"
    }
    di as txt "{hline 13}{c +}{hline 64}"

    // Data row: treatment variable
    local _tvar "`e(treatvar)'"
    if "`_tvar'" == "" local _tvar "d"
    if `bootstrap' > 0 {
        di as txt %12s abbrev("`_tvar'", 12) " {c |}" ///
            as res _col(16) %10.6f `att' ///
            _col(29) %10.6f `se' ///
            _col(41) %8.2f `tstat' ///
            _col(49) %7.3f `pvalue' ///
            _col(58) %10.6f `ci_lower' ///
            _col(70) %10.6f `ci_upper'
    }
    else {
        di as txt %12s abbrev("`_tvar'", 12) " {c |}" ///
            as res _col(16) %10.6f `att'
    }

    // Covariate gamma rows (if covariates present)
    if `_n_covariates' > 0 {
        di as txt "{hline 13}{c +}{hline 64}"
        di as txt _col(2) "{it:Covariates (Eq.14 gamma)}" _col(14) "{c |}"
        local _j = 1
        foreach var of local covariates {
            local _gamma_j = e(gamma)[1, `_j']
            di as txt %12s abbrev("`var'", 12) " {c |}" ///
                as res _col(16) %10.6f `_gamma_j'
            local ++_j
        }
    }

    // Table bottom
    di as txt "{hline 13}{c BT}{hline 64}"

    // ─── Footer notes (compact) ─────────────────────────────────────────────────

    // Lambda line
    local _lambda_source = cond(`run_cv', "LOOCV", "fixed")
    if missing(e(lambda_nn)) {
        di as txt "Lambda: time = " as res %5.3f e(lambda_time) ///
            as txt ", unit = " as res %5.3f e(lambda_unit) ///
            as txt ", nn = " as res "+inf" as txt " (`_lambda_source')"
    }
    else {
        di as txt "Lambda: time = " as res %5.3f e(lambda_time) ///
            as txt ", unit = " as res %5.3f e(lambda_unit) ///
            as txt ", nn = " as res %5.3f e(lambda_nn) as txt " (`_lambda_source')"
    }

    // Convergence (single line)
    if !missing(e(converged)) {
        local _conv = cond(e(converged)==1, "Yes", "No")
        local _iter_info = ""
        if !missing(e(n_iterations)) {
            local _iter_info = " (" + string(e(n_iterations)) + " iterations)"
        }
        di as txt "Convergence: " as res "`_conv'" as txt "`_iter_info'"
    }

    // No-bootstrap note
    if `bootstrap' == 0 {
        di as txt "{it:Note: SE/CI require bootstrap(); re-run with bootstrap(200).}"
    }

    // Global intercept (joint only)
    if "`method'" == "joint" & !missing(e(mu)) {
        di as txt "Global intercept (mu): " as res %10.6f e(mu)
    }

    // ─── Verbose 2+ diagnostics ─────────────────────────────────────────────────
    if `_verbose_level' >= 2 {
        di as txt ""
        // LOOCV score
        if !missing(e(loocv_score)) {
            di as txt "  Q(lambda_hat) = " as res %10.6f e(loocv_score)
        }
        // LOOCV/Grid strategy details
        if `run_cv' {
            if "`method'" == "joint" {
                di as txt "  LOOCV strategy: " as res "`joint_loocv'"
            }
            else {
                di as txt "  LOOCV strategy: " as res "`twostep_loocv'"
            }
        }
        // Auxiliary CIs (non-primary intervals)
        if `bootstrap' > 0 {
            local cimethod_used = "`e(cimethod)'"
            local _downpos = strpos("`cimethod_used'", "->")
            if `_downpos' > 0 {
                local _primary = substr("`cimethod_used'", `_downpos' + 2, length("`cimethod_used'"))
            }
            else {
                local _primary "`cimethod_used'"
            }
            local ci_lower_t = e(ci_lower_t)
            local ci_upper_t = e(ci_upper_t)
            local ci_lower_nor = e(ci_lower_normal)
            local ci_upper_nor = e(ci_upper_normal)
            local ci_lower_pct = e(ci_lower_percentile)
            local ci_upper_pct = e(ci_upper_percentile)

            if "`_primary'" != "t" & !missing(`ci_lower_t') & !missing(`ci_upper_t') {
                di as txt "  `level'% CI [t]:" _col(27) "[" ///
                    as res %10.6f `ci_lower_t' as txt ", " ///
                    as res %10.6f `ci_upper_t' as txt "]"
            }
            if "`_primary'" != "normal" & !missing(`ci_lower_nor') & !missing(`ci_upper_nor') {
                di as txt "  `level'% CI [normal]:" _col(27) "[" ///
                    as res %10.6f `ci_lower_nor' as txt ", " ///
                    as res %10.6f `ci_upper_nor' as txt "]"
            }
            if "`_primary'" != "percentile" & !missing(`ci_lower_pct') & !missing(`ci_upper_pct') {
                di as txt "  `level'% CI [percentile]:" _col(27) "[" ///
                    as res %10.6f `ci_lower_pct' as txt ", " ///
                    as res %10.6f `ci_upper_pct' as txt "]"
            }
            // SE denominator
            local bsvariance_used = "`e(bsvariance)'"
            if "`bsvariance_used'" == "paper" {
                di as txt "  SE denominator: " as res "paper (1/B)"
            }
            else {
                di as txt "  SE denominator: " as res "sample (1/(B-1))"
            }
            // Bootstrap summary
            di as txt "  Bootstrap: " as res "`bootstrap'" as txt " reps, alpha = " as res e(bsalpha)
        }
        // Convergence detail (twostep)
        if "`method'" == "twostep" {
            capture confirm scalar e(n_obs_estimated)
            if !_rc & !missing(e(n_obs_estimated)) {
                di as txt "  Obs estimated: " as res e(n_obs_estimated)
                capture confirm scalar e(n_obs_failed)
                if !_rc & !missing(e(n_obs_failed)) & e(n_obs_failed) > 0 {
                    di as txt "  Obs failed: " as res e(n_obs_failed)
                }
            }
        }
        // Nuisance parameter note
        if "`method'" == "twostep" {
            di as txt "  {it:Note: e(alpha)/e(beta) are averages across treated obs.}"
        }
        // Survey diagnostics
        if `_has_survey_design' & `bootstrap' > 0 {
            capture confirm scalar e(deff_weights)
            if !_rc & !missing(e(deff_weights)) & e(deff_weights) > 2 {
                di as txt "  {it:Weight DEFF = " as res %5.2f e(deff_weights) as txt " > 2}"
            }
            capture confirm scalar e(n_high_fpc)
            if !_rc & !missing(e(n_high_fpc)) & e(n_high_fpc) > 0 {
                capture confirm scalar e(max_fh)
                if !_rc & !missing(e(max_fh)) {
                    di as txt "  {it:FPC active: " as res e(n_high_fpc) as txt " strata with f_h > 0.5}"
                }
            }
        }
    }

    di as txt "{hline 78}"
end
