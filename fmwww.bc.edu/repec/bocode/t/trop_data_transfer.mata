/*──────────────────────────────────────────────────────────────────────────────
  trop_data_transfer.mata

  Data transfer layer between Mata and the native-code plugin.

  Stores variable indices, regularization grids, estimation options, and
  pre-allocated output matrices into the Stata namespace (scalars, matrices,
  global macros) so that the plugin can retrieve them via the Stata Plugin
  Interface (SPI).  Observation-level data is read by the plugin directly
  through SF_vdata(); this module does not construct large Mata matrices.

  Contents
    trop_prepare_data()              variable-index and panel-dimension setup
    trop_prepare_lambda_grids()      regularization-parameter grids
    trop_prepare_options()           estimation and inference options
    trop_prepare_output_matrices()   pre-allocate plugin output matrices
    trop_prepare_bootstrap()         bootstrap parameters and output matrix
    trop_cleanup_temp_vars()         drop all __trop_* temporaries
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_data()

  Maps variable names to positional indices within the plugin-call varlist
  and stores them as Stata scalars.  Records panel dimensions (N, T) and
  constructs the T x T time-distance matrix used by the exponential
  time-decay kernel  theta_s(t) = exp(-lambda_time * |t - s|).

  Arguments
    y_varname       outcome variable name          (Y)
    d_varname       binary treatment indicator name (W)
    panel_varname   panel (unit) identifier name
    time_varname    time period identifier name
    n_units         number of cross-sectional units (N)
    n_periods       number of time periods          (T)

  Stored scalars
    __trop_y_varindex, __trop_d_varindex, __trop_ctrl_varindex,
    __trop_panel_varindex, __trop_time_varindex,
    __trop_n_units, __trop_n_periods

  Stored globals
    __trop_varlist, __trop_y_varname, __trop_d_varname,
    __trop_panel_varname, __trop_time_varname

  Stored matrix
    __trop_time_dist   T x T absolute period distances
──────────────────────────────────────────────────────────────────────────────*/

void trop_prepare_data(
    string scalar y_varname,
    string scalar d_varname,
    string scalar panel_varname,
    string scalar time_varname,
    real scalar n_units,
    real scalar n_periods
)
{
    /* Varlist order for `plugin call`: Y, W, panel_id, time_id.
       Variable indices are therefore fixed at 1..4. */
    st_global("__trop_varlist", y_varname + " " + d_varname + " " + panel_varname + " " + time_varname)

    st_numscalar("__trop_y_varindex", 1)
    st_numscalar("__trop_d_varindex", 2)

    /* Control indicator reuses the treatment column; the plugin
       identifies control observations as those with W_{it} = 0. */
    st_numscalar("__trop_ctrl_varindex", 2)

    st_numscalar("__trop_panel_varindex", 3)
    st_numscalar("__trop_time_varindex", 4)

    st_numscalar("__trop_n_units", n_units)
    st_numscalar("__trop_n_periods", n_periods)

    st_global("__trop_y_varname", y_varname)
    st_global("__trop_d_varname", d_varname)
    st_global("__trop_panel_varname", panel_varname)
    st_global("__trop_time_varname", time_varname)

    _trop_prepare_time_dist_matrix(n_periods)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_lambda_grids()

  Stores candidate grids for the three regularization parameters
  (lambda_time, lambda_unit, lambda_nn) as Stata matrices, together with
  the corresponding grid lengths as scalars.

  Arguments
    lambda_time_grid   row vector of lambda_time candidates
    lambda_unit_grid   row vector of lambda_unit candidates
    lambda_nn_grid     row vector of lambda_nn   candidates
──────────────────────────────────────────────────────────────────────────────*/

void trop_prepare_lambda_grids(
    real rowvector lambda_time_grid,
    real rowvector lambda_unit_grid,
    real rowvector lambda_nn_grid
)
{
    st_matrix("__trop_lambda_time_grid", lambda_time_grid)
    st_matrix("__trop_lambda_unit_grid", lambda_unit_grid)
    st_matrix("__trop_lambda_nn_grid", lambda_nn_grid)

    st_numscalar("__trop_n_lambda_time", cols(lambda_time_grid))
    st_numscalar("__trop_n_lambda_unit", cols(lambda_unit_grid))
    st_numscalar("__trop_n_lambda_nn", cols(lambda_nn_grid))
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_prepare_time_dist_matrix()   [private]

  Constructs a T x T symmetric matrix of absolute period distances:

      time_dist[t, s] = |t - s|

  These distances enter the exponential time-decay kernel

      theta_s^{i,t}(lambda) = exp(-lambda_time * |t - s|)

  which down-weights periods far from the target period t.

  Argument
    n_periods   number of time periods (T)
──────────────────────────────────────────────────────────────────────────────*/

void _trop_prepare_time_dist_matrix(real scalar n_periods)
{
    real matrix time_dist
    real scalar t, s

    time_dist = J(n_periods, n_periods, 0)

    for (t = 1; t <= n_periods; t++) {
        for (s = 1; s <= n_periods; s++) {
            time_dist[t, s] = abs(t - s)
        }
    }

    st_matrix("__trop_time_dist", time_dist)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_output_matrices()

  Pre-allocates Stata matrices that the plugin fills via SF_mat_store().
  Must be called before `plugin call`.

  Arguments
    n_units     number of units   (N)
    n_periods   number of periods (T)
    n_treated   number of treated observations (optional; default 1)

  Pre-allocated matrices
    __trop_alpha           N x 1          unit fixed effects   (alpha_i)
    __trop_beta            T x 1          time fixed effects   (beta_t)
    __trop_tau             n_treated x 1  treatment effects    (tau_{i,t})
    __trop_factor_matrix   T x N          low-rank component   (mu)
    __trop_theta           T x 1          time weights   (two-step)
    __trop_omega           N x 1          unit weights   (two-step)
    __trop_delta_time      T x 1          time weights   (joint)
    __trop_delta_unit      N x 1          unit weights   (joint)
──────────────────────────────────────────────────────────────────────────────*/

void trop_prepare_output_matrices(
    real scalar n_units,
    real scalar n_periods,
    | real scalar n_treated
)
{
    if (args() < 3 || n_treated < 1) {
        n_treated = 1
    }

    /* Parameter estimates */
    st_matrix("__trop_alpha", J(n_units, 1, 0))
    st_matrix("__trop_beta", J(n_periods, 1, 0))
    st_matrix("__trop_tau", J(n_treated, 1, 0))
    st_matrix("__trop_factor_matrix", J(n_periods, n_units, 0))

    /* Per-observation diagnostics for the twostep method.  Pre-allocate so
       the plugin can always st_store into these matrices.  -1 sentinels
       distinguish "never written" from "solver returned failure". */
    st_matrix("__trop_converged_by_obs", J(n_treated, 1, -1))
    st_matrix("__trop_n_iters_by_obs",   J(n_treated, 1, -1))

    /* Weight vectors for both estimator variants.
       SF_mat_store() requires the target matrix to exist before the
       plugin call. */
    st_matrix("__trop_theta", J(n_periods, 1, 0))
    st_matrix("__trop_omega", J(n_units, 1, 0))
    st_matrix("__trop_delta_time", J(n_periods, 1, 0))
    st_matrix("__trop_delta_unit", J(n_units, 1, 0))

    /* Pre-allocate gamma output (covariates) as 1 x p row vector.
       trop_prepare_covariates() has already set __trop_n_covariates when
       covariates are present; honour that value.  Fall back to 1 x 1 when
       no covariates so that the matrix always exists for the ADO-side
       `capture confirm matrix __trop_gamma` check.

       Note: st_numscalar() returns J(0,0,.) when the scalar does not exist
       (e.g. after trop_cleanup_temp_vars).  We must read into a matrix
       first to avoid a conformability error assigning void to real scalar. */
    {
        real scalar _p_gamma
        real matrix _tmp_ncov
        _tmp_ncov = st_numscalar("__trop_n_covariates")
        _p_gamma = (rows(_tmp_ncov) > 0 ? _tmp_ncov : .)
        if (_p_gamma >= . | _p_gamma < 1) _p_gamma = 1
        st_matrix("__trop_gamma", J(1, _p_gamma, 0))
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_options()

  Stores estimation options as Stata scalars for the plugin.

  Arguments
    max_iter            maximum iterations for alternating minimization
    tol                 convergence tolerance
    seed                PRNG seed for bootstrap
    bootstrap_reps      number of bootstrap replications
    alpha_level         significance level (e.g. 0.05 for 95% CI)
    verbose             verbosity level (0 = silent)
──────────────────────────────────────────────────────────────────────────────*/

void trop_prepare_options(
    real scalar max_iter,
    real scalar tol,
    real scalar seed,
    real scalar bootstrap_reps,
    real scalar alpha_level,
    real scalar verbose
)
{
    st_numscalar("__trop_max_iter", max_iter)
    st_numscalar("__trop_tol", tol)
    st_numscalar("__trop_seed", seed)
    st_numscalar("__trop_n_bootstrap", bootstrap_reps)
    st_numscalar("__trop_alpha_level", alpha_level)
    st_numscalar("__trop_verbose", verbose)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_bootstrap()

  Stores bootstrap parameters and pre-allocates the output matrix that
  collects replicate estimates.

  Arguments
    n_bootstrap   number of bootstrap replications
    alpha         significance level for confidence intervals
    seed          PRNG seed
    lambda_time   selected lambda_time
    lambda_unit   selected lambda_unit
    lambda_nn     selected lambda_nn
    max_iter      maximum iterations per replicate
    tol           convergence tolerance per replicate

  Optional argument
    ddof          variance denominator selector forwarded to the plugin:
                  1 = sample variance 1/(B-1) (default);
                  0 = paper Algorithm 3 population variance 1/B.
                  Any other value collapses to 1.  When omitted the scalar
                  __trop_bs_ddof is left unset and the plugin applies its
                  own default (1), preserving pre-existing call sites.

  Pre-allocated matrix
    __trop_bootstrap_estimates   n_bootstrap x 1, initialised to missing
──────────────────────────────────────────────────────────────────────────────*/

void trop_prepare_bootstrap(
    real scalar n_bootstrap,
    real scalar alpha,
    real scalar seed,
    real scalar lambda_time,
    real scalar lambda_unit,
    real scalar lambda_nn,
    real scalar max_iter,
    real scalar tol,
    | real scalar ddof
)
{
    real scalar ddof_eff

    st_numscalar("__trop_n_bootstrap", n_bootstrap)
    /* Named __trop_bs_alpha to avoid collision with the unit-fixed-effects
       matrix __trop_alpha. */
    st_numscalar("__trop_bs_alpha", alpha)
    st_numscalar("__trop_seed", seed)

    st_numscalar("__trop_lambda_time", lambda_time)
    st_numscalar("__trop_lambda_unit", lambda_unit)
    st_numscalar("__trop_lambda_nn", lambda_nn)

    st_numscalar("__trop_max_iter", max_iter)
    st_numscalar("__trop_tol", tol)

    if (args() >= 9 & ddof < .) {
        /* Clamp to {0, 1}; any other value collapses to 1. */
        ddof_eff = (ddof == 0) ? 0 : 1
        st_numscalar("__trop_bs_ddof", ddof_eff)
    }

    st_matrix("__trop_bootstrap_estimates", J(n_bootstrap, 1, .))
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_covariates()

  Reads covariate variables from the Stata dataset, pivots each into a
  (T x N) matrix (same layout as Y), then stacks them column-wise into
  a (T*N) x p matrix stored as __trop_covariates.  The row ordering is
  time-major: row k = t * n_units + i, matching the Rust internal layout.

  Arguments
    cov_varnames    row vector of covariate variable names
    panel_idx_var   panel index variable (1..N from egen group)
    time_idx_var    time index variable (1..T from egen group)
    touse_var       estimation-sample marker
    n_units         number of cross-sectional units (N)
    n_periods       number of time periods (T)

  Stored matrices
    __trop_covariates   (T*N) x p covariate matrix
  
  Stored scalars
    __trop_n_covariates   number of covariates (p)

  Returns
    0 on success; nonzero on failure
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_prepare_covariates(
    string rowvector cov_varnames,
    string scalar panel_idx_var,
    string scalar time_idx_var,
    string scalar touse_var,
    real scalar n_units,
    real scalar n_periods
)
{
    real scalar p, n_obs, i, obs, t_val, u_val, row_idx
    real colvector panel_idx, time_idx, cov_data
    real matrix X
    string scalar varname

    p = cols(cov_varnames)
    n_obs = n_periods * n_units

    /* Read panel and time indices */
    panel_idx = st_data(., panel_idx_var, touse_var)
    time_idx  = st_data(., time_idx_var,  touse_var)

    /* Allocate output matrix */
    X = J(n_obs, p, 0)

    /* Fill each covariate column */
    for (i = 1; i <= p; i++) {
        varname = cov_varnames[i]
        cov_data = st_data(., varname, touse_var)

        /* Map observation-level data to (t-1)*n_units + (u-1) + 1 row */
        for (obs = 1; obs <= rows(cov_data); obs++) {
            t_val = time_idx[obs]    /* 1-based time index */
            u_val = panel_idx[obs]   /* 1-based unit index */
            /* Row index: time-major, 1-based for Mata */
            row_idx = (t_val - 1) * n_units + u_val
            if (row_idx >= 1 & row_idx <= n_obs) {
                X[row_idx, i] = cov_data[obs]
            }
        }
    }

    /* Secondary validation: reject if covariate matrix contains missing values.
       This should never trigger because the ADO layer rejects missing covariates
       upstream; included as defensive programming. */
    if (hasmissing(X)) {
        _error(416, "internal error: covariate matrix contains missing values after validation")
    }

    /* Store to Stata */
    st_matrix("__trop_covariates", X)
    st_numscalar("__trop_n_covariates", p)

    /* Pre-allocate gamma output as 1 x p row vector (Stata convention).
       The plugin writes SF_mat_store("__trop_gamma", 1, j+1, val) so this
       must exist with the correct dimensions before the plugin call. */
    st_matrix("__trop_gamma", J(1, p, 0))

    return(0)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_pweights()

  Extracts a strictly positive, constant-within-unit pweight vector from a
  Stata variable and stores the resulting N x 1 column of per-unit weights
  in the matrix __trop_unit_weights.  Also sets __trop_use_weights = 1 so
  the plugin dispatches to the weighted Rust ABI.

  Arguments
    weight_var       name of the pweight variable
    panel_idx_var    unit identifier (1..N) after egen group
    touse_var        estimation-sample marker
    n_units          number of units (N)

  Returns
    0 on success; nonzero Stata return code on validation failure:
      198 if any weight is missing, non-positive, or non-finite
      198 if pweight is not constant within a unit

  Side effects
    __trop_unit_weights  (N x 1 matrix)
    __trop_use_weights   = 1
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_prepare_pweights(
    string scalar weight_var,
    string scalar panel_idx_var,
    string scalar touse_var,
    real scalar n_units
)
{
    real colvector panel_idx, w_obs, w_unit, seen
    real scalar i, idx, wi

    panel_idx = st_data(., panel_idx_var, touse_var)
    w_obs     = st_data(., weight_var,    touse_var)

    if (rows(panel_idx) != rows(w_obs)) {
        errprintf("pweight (%s) and panel index lengths differ\n", weight_var)
        return(459)
    }

    /* Any missing / non-positive pweight cell is a hard error. */
    for (i = 1; i <= rows(w_obs); i++) {
        wi = w_obs[i]
        if (wi >= . | wi <= 0) {
            errprintf("pweight %s must be strictly positive; found %g at obs %g\n",
                      weight_var, wi, i)
            return(459)
        }
    }

    /* Collect the first-seen weight per unit, then enforce that every
       subsequent observation in the unit reports the same value. */
    w_unit = J(n_units, 1, .)
    seen   = J(n_units, 1, 0)

    for (i = 1; i <= rows(w_obs); i++) {
        idx = panel_idx[i]
        if (idx < 1 | idx > n_units) {
            errprintf("panel index %g out of range [1, %g]\n", idx, n_units)
            return(459)
        }
        if (!seen[idx]) {
            w_unit[idx] = w_obs[i]
            seen[idx]   = 1
        }
        else if (reldif(w_unit[idx], w_obs[i]) > 1e-12) {
            errprintf("pweight %s is not constant within unit %g (found %g and %g)\n",
                      weight_var, idx, w_unit[idx], w_obs[i])
            return(459)
        }
    }

    /* Units absent from the touse sample receive 0; the Rust aggregator
       ignores non-positive weights, so this is safe. */
    for (i = 1; i <= n_units; i++) {
        if (!seen[i]) w_unit[i] = 0
    }

    st_matrix("__trop_unit_weights", w_unit)
    st_numscalar("__trop_use_weights", 1)
    st_global("__trop_weight_var", weight_var)

    return(0)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_prepare_survey_design()

  Reads survey design variables (strata, PSU, FPC) from the Stata dataset,
  collapses observation-level values to unit-level (verifying within-unit
  constancy), encodes them as 0-based integer indices, and stores the
  results as Stata matrices for the Rao-Wu bootstrap plugin.

  Arguments
    strata_var      name of the stratification variable
    psu_var         name of the primary sampling unit variable
    fpc_var         name of the FPC variable ("" if not specified)
    panel_idx_var   panel index variable (1..N, from egen group)
    touse_var       estimation-sample marker
    n_units         number of cross-sectional units (N)
    do_nest         1 = nest PSU within strata (combine strata*PSU labels)

  Stored matrices
    __trop_strata   N x 1  integer-encoded strata (0-based)
    __trop_psu      N x 1  integer-encoded PSU    (0-based)
    __trop_fpc      N x 1  FPC values (or empty if fpc_var=="")

  Stored scalars
    __trop_has_survey_design = 1
    __trop_n_strata          number of distinct strata
    __trop_n_psu             number of distinct PSU

  Returns
    0 on success; nonzero Stata return code on validation failure.
──────────────────────────────────────────────────────────────────────────────*/

real scalar trop_prepare_survey_design(
    string scalar strata_var,
    string scalar psu_var,
    string scalar fpc_var,
    string scalar panel_idx_var,
    string scalar touse_var,
    real scalar n_units,
    real scalar do_nest
)
{
    real colvector panel_idx, strata_obs, psu_obs, fpc_obs
    real colvector strata_unit, psu_unit, fpc_unit, seen
    real colvector strata_encoded, psu_encoded
    real scalar i, idx, n_obs
    real scalar n_strata, n_psu
    real colvector strata_labels, psu_labels
    real scalar found

    /* 1. Read observation-level data */
    panel_idx  = st_data(., panel_idx_var, touse_var)
    strata_obs = st_data(., strata_var,    touse_var)
    psu_obs    = st_data(., psu_var,       touse_var)
    n_obs = rows(panel_idx)

    if (fpc_var != "") {
        fpc_obs = st_data(., fpc_var, touse_var)
    }

    /* 2. Collapse to unit-level and verify within-unit constancy */
    strata_unit = J(n_units, 1, .)
    psu_unit    = J(n_units, 1, .)
    fpc_unit    = J(n_units, 1, .)
    seen        = J(n_units, 1, 0)

    for (i = 1; i <= n_obs; i++) {
        idx = panel_idx[i]
        if (idx < 1 | idx > n_units) {
            errprintf("panel index %g out of range [1, %g]\n", idx, n_units)
            return(459)
        }
        if (!seen[idx]) {
            strata_unit[idx] = strata_obs[i]
            psu_unit[idx]    = psu_obs[i]
            if (fpc_var != "") fpc_unit[idx] = fpc_obs[i]
            seen[idx] = 1
        }
        else {
            /* Verify within-unit constancy */
            if (strata_unit[idx] != strata_obs[i]) {
                errprintf("strata variable '%s' is not constant within unit %g "
                    + "(found %g and %g)\n",
                    strata_var, idx, strata_unit[idx], strata_obs[i])
                return(459)
            }
            if (psu_unit[idx] != psu_obs[i]) {
                errprintf("psu variable '%s' is not constant within unit %g "
                    + "(found %g and %g)\n",
                    psu_var, idx, psu_unit[idx], psu_obs[i])
                return(459)
            }
            if (fpc_var != "") {
                if (reldif(fpc_unit[idx], fpc_obs[i]) > 1e-12) {
                    errprintf("fpc variable '%s' is not constant within unit %g "
                        + "(found %g and %g)\n",
                        fpc_var, idx, fpc_unit[idx], fpc_obs[i])
                    return(459)
                }
            }
        }
    }

    /* 3. Integer encoding (0-based) */
    /* If nest=1, combine strata+PSU into a single label before encoding PSU */
    if (do_nest) {
        /* Create composite label: strata * 1e9 + psu */
        for (i = 1; i <= n_units; i++) {
            psu_unit[i] = strata_unit[i] * 1e9 + psu_unit[i]
        }
    }

    /* Encode strata: map unique values to 0, 1, 2, ... */
    strata_labels = J(0, 1, .)
    strata_encoded = J(n_units, 1, 0)
    for (i = 1; i <= n_units; i++) {
        found = 0
        for (idx = 1; idx <= rows(strata_labels); idx++) {
            if (strata_labels[idx] == strata_unit[i]) {
                strata_encoded[i] = idx - 1
                found = 1
                break
            }
        }
        if (!found) {
            strata_labels = strata_labels \ strata_unit[i]
            strata_encoded[i] = rows(strata_labels) - 1
        }
    }
    n_strata = rows(strata_labels)

    /* Encode PSU: map unique values to 0, 1, 2, ... */
    psu_labels = J(0, 1, .)
    psu_encoded = J(n_units, 1, 0)
    for (i = 1; i <= n_units; i++) {
        found = 0
        for (idx = 1; idx <= rows(psu_labels); idx++) {
            if (psu_labels[idx] == psu_unit[i]) {
                psu_encoded[i] = idx - 1
                found = 1
                break
            }
        }
        if (!found) {
            psu_labels = psu_labels \ psu_unit[i]
            psu_encoded[i] = rows(psu_labels) - 1
        }
    }
    n_psu = rows(psu_labels)

    /* 3a. Validate FPC >= n_psu_in_stratum for each stratum */
    if (fpc_var != "") {
        real scalar h, n_psu_h, fpc_h
        real colvector psu_in_h
        for (h = 0; h < n_strata; h++) {
            psu_in_h = J(0, 1, .)
            fpc_h = .
            for (i = 1; i <= n_units; i++) {
                if (strata_encoded[i] == h) {
                    if (fpc_h == .) fpc_h = fpc_unit[i]
                    found = 0
                    for (idx = 1; idx <= rows(psu_in_h); idx++) {
                        if (psu_in_h[idx] == psu_encoded[i]) {
                            found = 1
                            break
                        }
                    }
                    if (!found) {
                        psu_in_h = psu_in_h \ psu_encoded[i]
                    }
                }
            }
            n_psu_h = rows(psu_in_h)
            if (fpc_h < n_psu_h) {
                errprintf("fpc() value (%.0f) is less than the number of "
                    + "PSUs (%g) in stratum %g\n", fpc_h, n_psu_h, h + 1)
                return(459)
            }
        }
    }

    /* 3b. nest=0: verify PSU codes are globally unique across strata */
    if (!do_nest) {
        real colvector psu_unique, strata_for_p, distinct_s
        real scalar p_idx, p_val
        psu_unique = uniqrows(psu_encoded)
        for (p_idx = 1; p_idx <= rows(psu_unique); p_idx++) {
            p_val = psu_unique[p_idx]
            strata_for_p = select(strata_encoded, psu_encoded :== p_val)
            distinct_s = uniqrows(strata_for_p)
            if (rows(distinct_s) > 1) {
                errprintf("psu variable is not globally unique "
                    + "(nest option not specified): ")
                errprintf("PSU code %g appears in %g different strata\n",
                    p_val, rows(distinct_s))
                errprintf("  Use the 'nest' option if PSUs are nested "
                    + "within strata\n")
                return(459)
            }
        }
    }

    /* 4. Store to Stata matrices */
    st_matrix("__trop_strata", strata_encoded)
    st_matrix("__trop_psu", psu_encoded)
    if (fpc_var != "") {
        st_matrix("__trop_fpc", fpc_unit)
    }
    else {
        /* Empty 0x1 sentinel: plugin checks rows==0 to skip FPC */
        st_matrix("__trop_fpc", J(0, 1, .))
    }

    /* 5. Store metadata scalars */
    st_numscalar("__trop_has_survey_design", 1)
    st_numscalar("__trop_n_strata", n_strata)
    st_numscalar("__trop_n_psu", n_psu)

    return(0)
}

/*──────────────────────────────────────────────────────────────────────────────
  trop_cleanup_temp_vars()

  Drops every __trop_* scalar, matrix, and global macro from the Stata
  namespace.  Uses st_dir() to enumerate names programmatically so that
  newly introduced temporaries are covered without code changes.
──────────────────────────────────────────────────────────────────────────────*/

void trop_cleanup_temp_vars()
{
    string colvector names
    real scalar i

    /* Scalars */
    names = st_dir("global", "numscalar", "__trop_*")
    for (i = 1; i <= length(names); i++) {
        stata("capture scalar drop " + names[i])
    }

    /* Matrices */
    names = st_dir("global", "matrix", "__trop_*")
    for (i = 1; i <= length(names); i++) {
        stata("capture matrix drop " + names[i])
    }

    /* Global macros */
    names = st_dir("global", "macro", "__trop_*")
    for (i = 1; i <= length(names); i++) {
        st_global(names[i], "")
    }
    st_global("__trop_touse_var", "")
    st_global("__trop_varlist", "")
    st_global("__trop_y_varname", "")
    st_global("__trop_d_varname", "")
    st_global("__trop_panel_varname", "")
    st_global("__trop_time_varname", "")

    /* Clean up the shared random seed scalar (not __trop_ prefixed) */
    stata("capture scalar drop TROP_GLOBAL_SEED")
}

end
