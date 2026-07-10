*! trop_bootstrap — post-estimation bootstrap inference for trop

/*
    Post-estimation command for bootstrap variance estimation of the ATT.

    Implements Algorithm 3 (Bootstrap Variance Estimation with multiple
    treated units): for each replication b = 1,...,B, resample N_0 control
    rows and N_1 treated rows with replacement, re-estimate the TROP
    estimator tau^(b), and compute the sample variance of {tau^(b)}.

    Syntax
        trop_bootstrap [if] [in] , [nreps(#) level(#) bsalpha(#)
                                     seed(#) maxiter(#) tol(#) verbose]

    Prerequisites
        Requires a prior call to -trop- with results stored in e().

    Stored results
        Updates e() with bootstrap standard errors, t-statistics,
        confidence intervals, p-values, and the distribution of
        bootstrap estimates in e(bootstrap_estimates).
*/


program trop_bootstrap, eclass
    version 17

    syntax [if] [in], ///
        [Nreps(integer 1000)]    /// number of bootstrap replications B
        [Level(real -1)]         /// confidence level in percent (10–99.99)
        [BSalpha(real -1)]       /// significance level alpha (deprecated)
        [SEED(integer 42)]       /// random-number seed
        [MAXiter(integer 500)]   /// maximum iterations per replication
        [TOL(real 1e-6)]         /// convergence tolerance per replication
        [BSVARiance(string)]     /// variance denominator: "sample" (1/(B-1), default) or "paper" (1/B, Alg 3)
        [CImethod(string)]       /// primary CI: "percentile" (default), "t", or "normal"
        [VERbose]                //  display progress information

    // Resolve bsvariance() to an integer ddof forwarded to the plugin.
    // Default policy mirrors trop.ado: fall back to e(bsvariance) if the
    // caller omits the option, and finally to "sample".
    local _bsvar = trim(lower("`bsvariance'"))
    if "`_bsvar'" == "" {
        local _bsvar "`e(bsvariance)'"
        local _bsvar = trim(lower("`_bsvar'"))
    }
    if "`_bsvar'" == "" {
        local _bsvar "sample"
    }
    if "`_bsvar'" == "sample" {
        local _ddof_arg "1"
    }
    else if "`_bsvar'" == "paper" | "`_bsvar'" == "population" {
        local _ddof_arg "0"
    }
    else {
        di as error "bsvariance() must be 'sample' or 'paper'"
        exit 198
    }

    // Resolve cimethod() using the same precedence as bsvariance().
    // Bootstrap here is guaranteed (nreps >= 1), so the "percentile"
    // default is always viable.  An explicit cimethod() override wins.
    local _cimethod = trim(lower("`cimethod'"))
    if "`_cimethod'" == "" {
        local _cimethod "`e(cimethod)'"
        local _cimethod = trim(lower("`_cimethod'"))
        // Strip any downgrade trace stored on e() ("percentile->t" etc.)
        local _dpos = strpos("`_cimethod'", "->")
        if `_dpos' > 0 {
            local _cimethod = substr("`_cimethod'", `_dpos' + 2, length("`_cimethod'"))
        }
    }
    if "`_cimethod'" == "" {
        local _cimethod "percentile"
    }
    if !inlist("`_cimethod'", "percentile", "t", "normal") {
        di as error "cimethod() must be one of {bf:percentile}, {bf:t}, or {bf:normal}"
        exit 198
    }

    // ---------------------------------------------------------------
    // Resolve significance level.
    // Priority: level() > bsalpha() > e(alpha_level) > c(level).
    // ---------------------------------------------------------------
    if `level' != -1 {
        if `level' < 10 | `level' > 99.99 {
            di as error "level() must be between 10 and 99.99"
            exit 198
        }
        local bsalpha = 1 - `level'/100
    }
    else if `bsalpha' != -1 {
        // bsalpha() supplied directly; keep as-is
    }
    else {
        local _prior_alpha = .
        capture local _prior_alpha = e(alpha_level)
        if `_prior_alpha' > 0 & `_prior_alpha' < 1 {
            local bsalpha = `_prior_alpha'
        }
        else {
            local bsalpha = 1 - c(level)/100
        }
    }

    // ---------------------------------------------------------------
    // Validate that trop estimation results exist in e().
    // ---------------------------------------------------------------
    if "`e(cmd)'" != "trop" {
        di as error "trop_bootstrap is a post-estimation command."
        di as error "Execute {bf:trop} before running bootstrap inference."
        di as error ""
        di as error "Usage:"
        di as error "  1. Estimation:  trop y d, panelvar(id) timevar(t)"
        di as error "  2. Bootstrap:   trop_bootstrap, nreps(1000)"
        di as error ""
        di as error "Alternative:"
        di as error "  trop y d, panelvar(id) timevar(t) bootstrap(1000)"
        exit 301
    }

    // ---------------------------------------------------------------
    // Retrieve estimation context stored by trop.
    // ---------------------------------------------------------------
    local method    "`e(method)'"
    local depvar    "`e(depvar)'"
    local treatvar  "`e(treatvar)'"
    local panelvar  "`e(panelvar)'"
    local timevar   "`e(timevar)'"
    // Weight variable (empty when the original call omitted [pweight]).
    // When non-empty, the Mata runner enables the weighted bootstrap path
    // and forwards the variable to trop_prepare_pweights().
    local weight_var "`e(weight_var)'"

    local lambda_time = e(lambda_time)
    local lambda_unit = e(lambda_unit)
    local lambda_nn   = e(lambda_nn)

    local N_units   = e(N_units)
    local N_periods = e(N_periods)

    // ---------------------------------------------------------------
    // Input validation.
    // ---------------------------------------------------------------
    if missing(`lambda_time') | missing(`lambda_unit') | missing(`lambda_nn') {
        di as error "Lambda values not found in estimation results."
        di as error "Re-run {bf:trop} first to obtain lambda values."
        exit 301
    }

    if "`method'" == "" {
        di as error "Method not found in estimation results. Re-run {bf:trop} first."
        exit 301
    }

    if `nreps' < 10 {
        di as error "nreps() must be at least 10"
        exit 198
    }

    if `bsalpha' <= 0 | `bsalpha' >= 1 {
        di as error "Significance level (alpha) must be in (0, 1)"
        di as error "  Use level(95) for 95% CI, or bsalpha(0.05)"
        exit 198
    }

    // Confirm that the variables from the prior estimation still exist
    foreach v in `depvar' `treatvar' `panelvar' `timevar' {
        capture confirm variable `v'
        if _rc {
            di as error "Variable `v' not found."
            exit 111
        }
    }

    // ---------------------------------------------------------------
    // Mark estimation sample and construct panel/time indices.
    // ---------------------------------------------------------------
    marksample touse
    markout `touse' `depvar' `treatvar' `panelvar' `timevar'
    if "`weight_var'" != "" {
        capture confirm numeric variable `weight_var'
        if _rc {
            di as error "weight_var from e() is missing or non-numeric: `weight_var'"
            exit 111
        }
        markout `touse' `weight_var'
    }

    tempvar panel_idx time_idx
    qui egen `panel_idx' = group(`panelvar') if `touse'
    qui egen `time_idx' = group(`timevar') if `touse'
    sort `panel_idx' `time_idx'

    // ---------------------------------------------------------------
    // Display header when verbose output is requested.
    // ---------------------------------------------------------------
    if "`verbose'" != "" {
        di as txt _n "{hline 60}"
        di as txt "TROP Post-Estimation Bootstrap"
        di as txt "{hline 60}"
        di as txt "Method:         " as res "`method'"
        di as txt "Replications:   " as res `nreps'
        di as txt "Alpha:          " as res `bsalpha'
        di as txt "Seed:           " as res `seed'
        di as txt "Lambda (fixed): (" as res `lambda_time' as txt ", " ///
            as res `lambda_unit' as txt ", " as res `lambda_nn' as txt ")"
        di as txt "{hline 60}"
    }

    // ---------------------------------------------------------------
    // Load compiled plugin and Mata routines.
    // ---------------------------------------------------------------
    capture _trop_load_plugin
    if _rc {
        di as error "TROP plugin not found. Cannot run bootstrap."
        exit 601
    }

    _trop_load_mata

    // ---------------------------------------------------------------
    // Delegate to Mata bootstrap wrapper.
    // The cimethod choice is forwarded via the __trop_cimethod global to
    // keep the Mata function signature stable; the Mata wrapper reads it
    // when populating e(ci_lower)/e(ci_upper).
    // ---------------------------------------------------------------
    mata: st_global("__trop_cimethod", "`_cimethod'")
    mata: _trop_run_post_bootstrap( ///
        "`depvar'", "`treatvar'", "`panel_idx'", "`time_idx'", "`touse'", ///
        `lambda_time', `lambda_unit', `lambda_nn', ///
        `nreps', `bsalpha', `seed', `maxiter', `tol', ///
        "`method'", ("`verbose'" != ""), `_ddof_arg', "`weight_var'")
    mata: st_global("__trop_cimethod", "")

    // ---------------------------------------------------------------
    // Synchronize e(V) with the bootstrap standard error.
    // e(V)[1,1] should equal e(se)^2 so that subsequent Stata
    // post-estimation commands (_coef_table, test, etc.) work.
    // Three fallback strategies are attempted in order.
    // ---------------------------------------------------------------
    if !missing(e(se)) & e(se) > 0 {
        local _v_synced = 0

        // Strategy 1: ereturn repost with properties
        tempname _newV _newb
        matrix `_newV' = (e(se) ^ 2)
        matrix colnames `_newV' = att
        matrix rownames `_newV' = att
        matrix `_newb' = (e(att))
        matrix colnames `_newb' = att
        capture ereturn repost b = `_newb' V = `_newV', properties("b V")
        if !_rc {
            local _v_synced = 1
        }

        // Strategy 2: ereturn repost without properties
        if !`_v_synced' {
            tempname _newV2 _newb2
            matrix `_newV2' = (e(se) ^ 2)
            matrix colnames `_newV2' = att
            matrix rownames `_newV2' = att
            matrix `_newb2' = (e(att))
            matrix colnames `_newb2' = att
            capture ereturn repost b = `_newb2' V = `_newV2'
            if !_rc {
                local _v_synced = 1
            }
        }

        // Strategy 3: full ereturn post cycle via helper program
        if !`_v_synced' {
            capture _trop_bs_repost_V, att_val(`=e(att)') se_val(`=e(se)')
            if !_rc {
                local _v_synced = 1
            }
        }

        if !`_v_synced' {
            di as txt "(Note: e(V) could not be updated. Use e(se) directly.)"
        }
    }

    // Refresh e(bsvariance) so the e() record reflects the option that
    // drove this bootstrap (even when the user overrode the original
    // setting stored by trop).
    ereturn local bsvariance "`_bsvar'"

    // ---------------------------------------------------------------
    // Display results table.
    // ---------------------------------------------------------------
    local ci_level = round((1 - `bsalpha') * 100, 0.1)

    di as txt _n "{hline 60}"
    di as txt "TROP Bootstrap Inference Results"
    di as txt "{hline 60}"
    di as txt "ATT estimate:   " as res %12.6f e(att)
    di as txt "Bootstrap SE:   " as res %12.6f e(se)
    di as txt "`ci_level'% CI:       [" as res %12.6f e(ci_lower) ///
        as txt ", " as res %12.6f e(ci_upper) as txt "]"

    if !missing(e(pvalue)) {
        di as txt "p-value:        " as res %12.4f e(pvalue)
    }

    di as txt ""
    di as txt "Bootstrap reps: " as res %9.0f e(bootstrap_reps)
    di as txt "Valid reps:     " as res %9.0f e(n_bootstrap_valid)
    di as txt "{hline 60}"

end


/*
    _trop_bs_repost_V — helper for e(b)/e(V) synchronization

    Performs a full ereturn post cycle: saves all current e() contents,
    posts the new b and V matrices, then restores every saved scalar,
    local, and matrix.  Used as a last resort when ereturn repost fails.
*/

capture program drop _trop_bs_repost_V
program _trop_bs_repost_V, eclass
    syntax, att_val(real) se_val(real)

    // --- save e() locals ---
    local _cmd "`e(cmd)'"
    local _method "`e(method)'"
    local _vcetype "`e(vcetype)'"
    local _properties "`e(properties)'"
    local _depvar "`e(depvar)'"
    local _treatvar "`e(treatvar)'"
    local _panelvar "`e(panelvar)'"
    local _timevar "`e(timevar)'"
    local _cmdline "`e(cmdline)'"
    local _estat_cmd "`e(estat_cmd)'"
    local _predict "`e(predict)'"
    local _title "`e(title)'"
    local _grid_style "`e(grid_style)'"
    local _treatment_pattern "`e(treatment_pattern)'"
    local _data_signature "`e(data_signature)'"
    local _bsvariance "`e(bsvariance)'"
    local _cimethod "`e(cimethod)'"

    // --- save e() scalars ---
    local _att = e(att)
    local _se = e(se)
    local _t = e(t)
    local _pvalue = e(pvalue)
    local _ci_lower = e(ci_lower)
    local _ci_upper = e(ci_upper)
    local _ci_lower_t   = e(ci_lower_t)
    local _ci_upper_t   = e(ci_upper_t)
    local _pvalue_t     = e(pvalue_t)
    local _ci_lower_nor = e(ci_lower_normal)
    local _ci_upper_nor = e(ci_upper_normal)
    local _pvalue_nor   = e(pvalue_normal)
    local _ci_lower_pct = e(ci_lower_percentile)
    local _ci_upper_pct = e(ci_upper_percentile)
    local _df_r         = e(df_r)
    local _mu = e(mu)
    local _lambda_time = e(lambda_time)
    local _lambda_unit = e(lambda_unit)
    local _lambda_nn = e(lambda_nn)
    local _loocv_score = e(loocv_score)
    local _converged = e(converged)
    local _n_iterations = e(n_iterations)
    local _bootstrap_reps = e(bootstrap_reps)
    local _n_bootstrap_valid = e(n_bootstrap_valid)
    local _alpha_level = e(alpha_level)
    local _level = e(level)
    local _N_units = e(N_units)
    local _N_periods = e(N_periods)
    local _N_obs = e(N_obs)
    local _N_treat = e(N_treat)
    local _N_treated = e(N_treated)
    local _N_treated_obs = e(N_treated_obs)
    local _N_treated_units = e(N_treated_units)
    local _T_treat_periods = e(T_treat_periods)
    local _N_control = e(N_control)
    local _N_control_units = e(N_control_units)
    local _balanced = e(balanced)
    local _miss_rate = e(miss_rate)
    local _effective_rank = e(effective_rank)
    local _data_validated = e(data_validated)
    local _min_pre_treated = e(min_pre_treated)
    local _min_valid_pairs = e(min_valid_pairs)
    local _has_switching = e(has_switching)
    local _max_switches = e(max_switches)
    local _time_min = e(time_min)
    local _time_max = e(time_max)
    local _time_range = e(time_range)
    local _n_pre_periods = e(n_pre_periods)
    local _n_post_periods = e(n_post_periods)
    local _loocv_used = e(loocv_used)
    local _seed = e(seed)
    local _loocv_n_valid = e(loocv_n_valid)
    local _loocv_n_attempted = e(loocv_n_attempted)
    local _loocv_fail_rate = e(loocv_fail_rate)
    local _loocv_first_failed_t = e(loocv_first_failed_t)
    local _loocv_first_failed_i = e(loocv_first_failed_i)
    local _bootstrap_fail_rate = e(bootstrap_fail_rate)
    local _n_lambda_time = e(n_lambda_time)
    local _n_lambda_unit = e(n_lambda_unit)
    local _n_lambda_nn = e(n_lambda_nn)
    local _n_grid_combinations = e(n_grid_combinations)
    local _n_grid_per_cycle = e(n_grid_per_cycle)

    // --- save e() matrices ---
    tempname _m_alpha _m_beta _m_tau _m_factor _m_bs_est
    tempname _m_lt_grid _m_lu_grid _m_ln_grid _m_lambda_grid _m_cv_curve
    tempname _m_theta _m_omega _m_delta_time _m_delta_unit

    capture matrix `_m_alpha' = e(alpha)
    capture matrix `_m_beta' = e(beta)
    capture matrix `_m_tau' = e(tau)
    capture matrix `_m_factor' = e(factor_matrix)
    capture matrix `_m_bs_est' = e(bootstrap_estimates)
    capture matrix `_m_lt_grid' = e(lambda_time_grid)
    capture matrix `_m_lu_grid' = e(lambda_unit_grid)
    capture matrix `_m_ln_grid' = e(lambda_nn_grid)
    capture matrix `_m_lambda_grid' = e(lambda_grid)
    capture matrix `_m_cv_curve' = e(cv_curve)
    capture matrix `_m_theta' = e(theta)
    capture matrix `_m_omega' = e(omega)
    capture matrix `_m_delta_time' = e(delta_time)
    capture matrix `_m_delta_unit' = e(delta_unit)

    // --- post new b and V ---
    tempname _b _V
    matrix `_b' = (`att_val')
    matrix colnames `_b' = att
    matrix `_V' = (`se_val' ^ 2)
    matrix colnames `_V' = att
    matrix rownames `_V' = att
    ereturn post `_b' `_V'

    // --- restore e() locals ---
    if "`_cmd'" != "" ereturn local cmd "`_cmd'"
    if "`_method'" != "" ereturn local method "`_method'"
    if "`_vcetype'" != "" ereturn local vcetype "`_vcetype'"
    if "`_depvar'" != "" ereturn local depvar "`_depvar'"
    if "`_treatvar'" != "" ereturn local treatvar "`_treatvar'"
    if "`_panelvar'" != "" ereturn local panelvar "`_panelvar'"
    if "`_timevar'" != "" ereturn local timevar "`_timevar'"
    if "`_cmdline'" != "" ereturn local cmdline "`_cmdline'"
    if "`_estat_cmd'" != "" ereturn local estat_cmd "`_estat_cmd'"
    if "`_predict'" != "" ereturn local predict "`_predict'"
    if "`_title'" != "" ereturn local title "`_title'"
    if "`_grid_style'" != "" ereturn local grid_style "`_grid_style'"
    if "`_treatment_pattern'" != "" ereturn local treatment_pattern "`_treatment_pattern'"
    if "`_data_signature'" != "" ereturn local data_signature "`_data_signature'"
    if "`_bsvariance'" != "" ereturn local bsvariance "`_bsvariance'"
    if "`_cimethod'"   != "" ereturn local cimethod   "`_cimethod'"

    // --- restore e() scalars ---
    foreach s in att se t pvalue ci_lower ci_upper mu ///
        ci_lower_t ci_upper_t pvalue_t ///
        ci_lower_nor ci_upper_nor pvalue_nor ///
        ci_lower_pct ci_upper_pct df_r ///
        lambda_time lambda_unit lambda_nn loocv_score ///
        converged n_iterations ///
        bootstrap_reps n_bootstrap_valid alpha_level level ///
        N_units N_periods N_obs N_treat N_treated N_treated_obs ///
        N_treated_units T_treat_periods N_control N_control_units ///
        balanced miss_rate effective_rank ///
        data_validated min_pre_treated min_valid_pairs ///
        has_switching max_switches time_min time_max time_range ///
        n_pre_periods n_post_periods ///
        loocv_used seed ///
        loocv_n_valid loocv_n_attempted ///
        loocv_fail_rate ///
        loocv_first_failed_t loocv_first_failed_i ///
        bootstrap_fail_rate ///
        n_lambda_time n_lambda_unit n_lambda_nn ///
        n_grid_combinations n_grid_per_cycle {
        if !missing(`_`s'') {
            // Map the abbreviated local names back to their canonical e()
            // names.  ci_lower_nor -> ci_lower_normal, etc.
            local _ename "`s'"
            if "`s'" == "ci_lower_nor" local _ename "ci_lower_normal"
            else if "`s'" == "ci_upper_nor" local _ename "ci_upper_normal"
            else if "`s'" == "pvalue_nor" local _ename "pvalue_normal"
            else if "`s'" == "ci_lower_pct" local _ename "ci_lower_percentile"
            else if "`s'" == "ci_upper_pct" local _ename "ci_upper_percentile"
            ereturn scalar `_ename' = `_`s''
        }
    }

    // --- restore e() matrices ---
    capture confirm matrix `_m_alpha'
    if !_rc ereturn matrix alpha = `_m_alpha'
    capture confirm matrix `_m_beta'
    if !_rc ereturn matrix beta = `_m_beta'
    capture confirm matrix `_m_tau'
    if !_rc ereturn matrix tau = `_m_tau'
    capture confirm matrix `_m_factor'
    if !_rc ereturn matrix factor_matrix = `_m_factor'
    capture confirm matrix `_m_bs_est'
    if !_rc ereturn matrix bootstrap_estimates = `_m_bs_est'
    capture confirm matrix `_m_lt_grid'
    if !_rc ereturn matrix lambda_time_grid = `_m_lt_grid'
    capture confirm matrix `_m_lu_grid'
    if !_rc ereturn matrix lambda_unit_grid = `_m_lu_grid'
    capture confirm matrix `_m_ln_grid'
    if !_rc ereturn matrix lambda_nn_grid = `_m_ln_grid'
    capture confirm matrix `_m_lambda_grid'
    if !_rc ereturn matrix lambda_grid = `_m_lambda_grid'
    capture confirm matrix `_m_cv_curve'
    if !_rc ereturn matrix cv_curve = `_m_cv_curve'
    capture confirm matrix `_m_theta'
    if !_rc ereturn matrix theta = `_m_theta'
    capture confirm matrix `_m_omega'
    if !_rc ereturn matrix omega = `_m_omega'
    capture confirm matrix `_m_delta_time'
    if !_rc ereturn matrix delta_time = `_m_delta_time'
    capture confirm matrix `_m_delta_unit'
    if !_rc ereturn matrix delta_unit = `_m_delta_unit'
end


/*
    Mata: _trop_run_post_bootstrap()

    Prepares panel data, invokes the compiled bootstrap routine
    (Algorithm 3), and stores inference results in e().

    The bootstrap resamples control and treated units independently
    with replacement, re-estimates the ATT on each bootstrap sample,
    and derives the variance from the empirical distribution of
    {tau^(b)}.  Confidence intervals and p-values are computed from
    a t-distribution with (N_1 - 1) degrees of freedom whenever the
    number of ever-treated units N_1 is at least 2, and from the
    standard normal distribution otherwise (Algorithm 3 treats N_1
    as the cluster count, so a single treated unit collapses df to 0).
*/

version 17
mata:

void _trop_run_post_bootstrap(
    string scalar depvar,
    string scalar treatvar,
    string scalar panel_idx_var,
    string scalar time_idx_var,
    string scalar touse_var,
    real scalar lambda_time,
    real scalar lambda_unit,
    real scalar lambda_nn,
    real scalar nreps,
    real scalar alpha,
    real scalar seed,
    real scalar max_iter,
    real scalar tol,
    string scalar method,
    real scalar verbose,
    | real scalar ddof,
    string scalar weight_var
)
{
    real scalar ddof_eff
    real scalar have_ddof
    real scalar have_weight, pw_rc
    real scalar rc, n_units, n_periods, n_treated, n_treated_units
    real colvector panel_idx, time_idx, d_vec
    real scalar se, ci_lower, ci_upper, pvalue, tstat, att
    real scalar ci_lower_t, ci_upper_t, pvalue_t
    real scalar ci_lower_normal, ci_upper_normal, pvalue_normal
    real scalar ci_lower_pct, ci_upper_pct
    string scalar cimethod_req, cimethod_used
    real scalar n_bootstrap_valid, level
    real matrix bootstrap_estimates

    // Determine panel dimensions
    panel_idx = st_data(., panel_idx_var, touse_var)
    time_idx = st_data(., time_idx_var, touse_var)
    n_units = max(panel_idx)
    n_periods = max(time_idx)

    // Count treated cells (length of the tau vector; used for plugin
    // output pre-allocation, NOT for the reference df).
    d_vec = st_data(., treatvar, touse_var)
    n_treated = sum(d_vec :!= 0)
    if (n_treated < 1) n_treated = 1

    // Count ever-treated units N_1 (Algorithm 3 cluster count).
    // Prefer the upstream value already stored on e() by the preceding
    // `trop` run; fall back to an inline count of unique panel ids with
    // any treated observation when absent (e.g. after ereturn clear).
    n_treated_units = _trop_safe_read_scalar("e(N_treated_units)")
    if (n_treated_units >= .) {
        real colvector _treated_ids
        _treated_ids = uniqrows(select(panel_idx, d_vec :!= 0))
        n_treated_units = rows(_treated_ids)
    }

    if (verbose) {
        printf("{txt}\n")
        printf("{txt}Preparing data for bootstrap (N=%g, T=%g)...\n", n_units, n_periods)
    }

    // Transfer panel data to plugin workspace
    trop_prepare_data(depvar, treatvar, panel_idx_var, time_idx_var, n_units, n_periods)
    st_global("__trop_touse_var", touse_var)

    // Allocate output matrices
    trop_prepare_output_matrices(n_units, n_periods, n_treated)

    // Optional pweight path: set __trop_use_weights and __trop_unit_weights
    // when the caller forwarded a non-empty variable name.  Without a
    // weight the plugin falls back to the unweighted bootstrap ABI.
    st_numscalar("__trop_use_weights", 0)
    have_weight = (args() >= 17 & weight_var != "")
    if (have_weight) {
        pw_rc = trop_prepare_pweights(weight_var, panel_idx_var, touse_var, n_units)
        if (pw_rc != 0) {
            errprintf("Failed to prepare pweights for bootstrap (rc=%g)\n", pw_rc)
            exit(pw_rc)
        }
        if (verbose) {
            printf("{txt}Bootstrap: weighted (pweight = %s)\n", weight_var)
        }
    }

    // Set regularization parameters (held fixed across replications)
    st_numscalar("__trop_lambda_time", lambda_time)
    st_numscalar("__trop_lambda_unit", lambda_unit)
    st_numscalar("__trop_lambda_nn", lambda_nn)

    // Set bootstrap-specific parameters.  Forward ddof only when the
    // caller supplied a finite value so that legacy sites remain on the
    // sample-variance default.
    have_ddof = (args() >= 16 & ddof < .)
    if (have_ddof) {
        ddof_eff = (ddof == 0) ? 0 : 1
        trop_prepare_bootstrap(nreps, alpha, seed,
            lambda_time, lambda_unit, lambda_nn,
            max_iter, tol, ddof_eff)
    }
    else {
        trop_prepare_bootstrap(nreps, alpha, seed,
            lambda_time, lambda_unit, lambda_nn,
            max_iter, tol)
    }

    // Set algorithm options.  The signature is
    //   trop_prepare_options(max_iter, tol, seed, nreps, alpha, verbose)
    // The stray leading zero previously passed here caused a 7-argument
    // dispatch that Mata rejected with r(3001).
    trop_prepare_options(max_iter, tol, seed, nreps, alpha, verbose)

    if (verbose) {
        printf("{txt}Running %s bootstrap (%g replications)...\n", method, nreps)
    }

    // Dispatch to the appropriate bootstrap routine
    if (method == "twostep") {
        rc = trop_bootstrap_twostep()
    }
    else if (method == "joint") {
        rc = trop_bootstrap_joint()
    }
    else {
        errprintf("Unknown method: %s\n", method)
        exit(198)
    }

    if (rc != 0) {
        errprintf("Bootstrap failed with error code %g\n", rc)
        exit(rc)
    }

    // Retrieve bootstrap outputs
    se = _trop_safe_read_scalar("__trop_se")
    n_bootstrap_valid = _trop_safe_read_scalar("__trop_n_bootstrap_valid")
    // stata_bridge.c writes __trop_level = 1 - alpha in probability form
    // (e.g. 0.95).  Normalize to the Stata percent convention (95).
    level = _trop_safe_read_scalar("__trop_level")
    if (level < . && level > 0 && level < 1) {
        level = level * 100
    }

    // ------------------------------------------------------------------
    // Inference.
    //   - t(N_1 - 1) wrap when N_1 >= 2 (matches the unit-level
    //     stratified resampling of Algorithm 3).
    //   - Standard-normal wrap always (large-sample fallback).
    //   - Percentile CI from the bootstrap empirical CDF (paper Alg 3).
    // All three are stored on e(); the authoritative e(ci_lower)/
    // e(ci_upper) follows __trop_cimethod.
    // ------------------------------------------------------------------
    att = st_numscalar("e(att)")

    // Read percentile CI that the plugin wrote (finite only when bootstrap
    // produced >= 1 valid replicate, otherwise the reader yields missing).
    ci_lower_pct = _trop_safe_read_scalar("__trop_ci_lower_percentile")
    ci_upper_pct = _trop_safe_read_scalar("__trop_ci_upper_percentile")

    // Parametric candidates.
    ci_lower_t = .
    ci_upper_t = .
    pvalue_t = .
    ci_lower_normal = .
    ci_upper_normal = .
    pvalue_normal = .
    tstat = .

    if (se > 0 && se < .) {
        real scalar df_pvalue
        tstat = att / se
        pvalue_normal = 2 * normal(-abs(tstat))
        ci_lower_normal = att - invnormal(1 - alpha/2) * se
        ci_upper_normal = att + invnormal(1 - alpha/2) * se

        if (n_treated_units >= 2 && n_treated_units < .) {
            df_pvalue = max((1, n_treated_units - 1))
            pvalue_t = 2 * ttail(df_pvalue, abs(tstat))
            ci_lower_t = att - invttail(df_pvalue, alpha/2) * se
            ci_upper_t = att + invttail(df_pvalue, alpha/2) * se
        }
        else {
            pvalue_t = pvalue_normal
            ci_lower_t = ci_lower_normal
            ci_upper_t = ci_upper_normal
        }
    }

    // Resolve cimethod from the ADO wrapper (set through __trop_cimethod
    // global); default to "percentile" when the string is empty.
    cimethod_req = st_global("__trop_cimethod")
    if (cimethod_req == "") {
        cimethod_req = "percentile"
    }
    cimethod_used = cimethod_req
    if (cimethod_req == "percentile" && (ci_lower_pct >= . || ci_upper_pct >= .)) {
        cimethod_used = "t"
    }

    if (cimethod_used == "percentile") {
        ci_lower = ci_lower_pct
        ci_upper = ci_upper_pct
        pvalue = pvalue_t
    }
    else if (cimethod_used == "normal") {
        ci_lower = ci_lower_normal
        ci_upper = ci_upper_normal
        pvalue = pvalue_normal
    }
    else {
        ci_lower = ci_lower_t
        ci_upper = ci_upper_t
        pvalue = pvalue_t
    }

    if (tstat >= .) {
        pvalue = .
        ci_lower = .
        ci_upper = .
    }

    // Store results in e()
    st_numscalar("e(se)", se)
    st_numscalar("e(t)", tstat)
    st_numscalar("e(ci_lower)", ci_lower)
    st_numscalar("e(ci_upper)", ci_upper)
    st_numscalar("e(pvalue)", pvalue)
    st_numscalar("e(bootstrap_reps)", nreps)
    st_numscalar("e(alpha_level)", alpha)
    st_numscalar("e(n_bootstrap_valid)", n_bootstrap_valid)
    st_numscalar("e(level)", level)
    st_global("e(vcetype)", "Bootstrap")

    // All three candidate CI pairs are persisted so consumers can switch
    // cimethod without rerunning the bootstrap.
    if (ci_lower_t < . & ci_upper_t < .) {
        st_numscalar("e(ci_lower_t)", ci_lower_t)
        st_numscalar("e(ci_upper_t)", ci_upper_t)
        st_numscalar("e(pvalue_t)", pvalue_t)
    }
    if (ci_lower_normal < . & ci_upper_normal < .) {
        st_numscalar("e(ci_lower_normal)", ci_lower_normal)
        st_numscalar("e(ci_upper_normal)", ci_upper_normal)
        st_numscalar("e(pvalue_normal)", pvalue_normal)
    }
    if (ci_lower_pct < . & ci_upper_pct < .) {
        st_numscalar("e(ci_lower_percentile)", ci_lower_pct)
        st_numscalar("e(ci_upper_percentile)", ci_upper_pct)
    }

    // Record the CI method (with downgrade trace when applicable).
    if (cimethod_used != cimethod_req) {
        st_global("e(cimethod)", cimethod_req + "->" + cimethod_used)
    }
    else {
        st_global("e(cimethod)", cimethod_used)
    }

    if (n_treated_units >= 2 && n_treated_units < .) {
        st_numscalar("e(df_r)", max((1, n_treated_units - 1)))
    }
    else {
        st_numscalar("e(df_r)", .)
    }

    // Store the empirical bootstrap distribution, dropping missing entries
    bootstrap_estimates = st_matrix("__trop_bootstrap_estimates")
    if (rows(bootstrap_estimates) > 0) {
        bootstrap_estimates = select(bootstrap_estimates, bootstrap_estimates :< .)
    }
    if (rows(bootstrap_estimates) > 0) {
        st_matrix("e(bootstrap_estimates)", bootstrap_estimates)
    }

    // Warn if a substantial fraction of replications failed
    if (n_bootstrap_valid < nreps) {
        _trop_display_bootstrap_warnings(n_bootstrap_valid, nreps)
    }

    // Release temporary plugin workspace
    trop_cleanup_temp_vars()

    if (verbose) {
        printf("{txt}Bootstrap complete: SE=%g, %g/%g valid replications\n",
               se, n_bootstrap_valid, nreps)
    }
}

end
