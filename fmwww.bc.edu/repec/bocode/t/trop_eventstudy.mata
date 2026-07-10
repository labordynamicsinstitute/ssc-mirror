/*──────────────────────────────────────────────────────────────────────────────
  trop_eventstudy.mata

  Event-study core computation for the TROP estimator.

  Implements aggregation of individual treatment effects by relative event
  time (horizon) and placebo (pre-trend) testing.  These functions are called
  by the ADO-layer `trop_eventstudy` command to produce dynamic treatment
  effect estimates and pre-trend diagnostics.

  The TROP model produces a T x N matrix of individual treatment effects
  tau_{i,t}.  For event-study analysis, these are re-indexed relative to
  each unit's first treatment period g_i:

      h = t - g_i     (h=0 is the first treatment period)

  and averaged across units at each horizon h to obtain dynamic ATT(h).

  Contents
    _trop_aggregate_by_horizon()   aggregate tau by relative event time
    _trop_placebo_effects()        compute pre-treatment pseudo-effects
    _trop_pretrend_test()          joint Wald test of pre-trend = 0
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  _trop_aggregate_by_horizon()

  Aggregates treatment effects from a T x N tau_matrix by relative event
  time (horizon).  For each unit i, the horizon is h = t - g_i where g_i
  is the first period in which D_{i,t} = 1.

  Only treated cells (D_{i,t} = 1 and tau_{i,t} != .) contribute to the
  aggregation at their respective horizon.

  Arguments
    tau_matrix   T x N matrix of individual treatment effects (from e(tau_matrix))
    D_matrix     T x N binary treatment indicator matrix
    level        confidence level in percent (e.g. 95)

  Returns
    K x 6 real matrix: [horizon, mean_tau, se, ci_lower, ci_upper, n_cells]
    Returns a 0 x 6 empty matrix when no valid horizon can be computed.
──────────────────────────────────────────────────────────────────────────────*/

real matrix _trop_aggregate_by_horizon(
    real matrix tau_matrix,
    real matrix D_matrix,
    real scalar level
)
{
    real scalar n_periods, n_units, i, t, h
    real scalar min_h, max_h
    real scalar n_horizons, h_idx
    real scalar z, se_h
    real colvector first_treat, tau_h
    real matrix result

    n_periods = rows(tau_matrix)
    n_units = cols(tau_matrix)

    /* ── Step 1: determine first treatment period g_i for each unit ──── */
    first_treat = J(n_units, 1, .)
    for (i = 1; i <= n_units; i++) {
        for (t = 1; t <= n_periods; t++) {
            if (D_matrix[t, i] == 1) {
                first_treat[i] = t
                break
            }
        }
    }

    /* ── Step 2: determine horizon range ─────────────────────────────── */
    min_h = .
    max_h = .
    for (i = 1; i <= n_units; i++) {
        if (first_treat[i] >= .) continue
        for (t = 1; t <= n_periods; t++) {
            if (D_matrix[t, i] == 1 & tau_matrix[t, i] < .) {
                h = t - first_treat[i]
                if (min_h >= . | h < min_h) min_h = h
                if (max_h >= . | h > max_h) max_h = h
            }
        }
    }

    if (min_h >= . | max_h >= .) return(J(0, 6, .))

    /* ── Step 3: aggregate by horizon ────────────────────────────────── */
    n_horizons = max_h - min_h + 1
    result = J(n_horizons, 6, .)

    z = invnormal(1 - (1 - level / 100) / 2)

    for (h_idx = 1; h_idx <= n_horizons; h_idx++) {
        h = min_h + h_idx - 1
        result[h_idx, 1] = h

        /* Collect all tau values at this horizon */
        tau_h = J(0, 1, .)
        for (i = 1; i <= n_units; i++) {
            if (first_treat[i] >= .) continue
            t = first_treat[i] + h
            if (t >= 1 & t <= n_periods) {
                if (D_matrix[t, i] == 1 & tau_matrix[t, i] < .) {
                    tau_h = tau_h \ tau_matrix[t, i]
                }
            }
        }

        result[h_idx, 6] = rows(tau_h)
        if (rows(tau_h) > 0) {
            result[h_idx, 2] = mean(tau_h)
            if (rows(tau_h) > 1) {
                se_h = sqrt(variance(tau_h)) / sqrt(rows(tau_h))
                result[h_idx, 3] = se_h
                result[h_idx, 4] = result[h_idx, 2] - z * se_h
                result[h_idx, 5] = result[h_idx, 2] + z * se_h
            }
        }
    }

    return(result)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_placebo_effects()

  Computes pre-treatment placebo effects using the estimated model
  parameters.  For each unit i and pre-treatment period t < g_i:

      placebo_{i,t} = Y_{i,t} - alpha_i - beta_t - L_{t,i}

  If parallel trends holds, these residuals should be close to zero.

  The function reads the estimated parameters from e() and reconstructs
  the counterfactual for the pre-treatment window.  Results are aggregated
  by relative horizon h = t - g_i (h < 0).

  Arguments
    depvar      name of the outcome variable in the Stata dataset
    panelvar    name of the panel (unit) variable
    timevar     name of the time variable
    treatvar    name of the treatment indicator variable
    n_placebo   number of pre-treatment periods to include (h = -1, ..., -n_placebo)
    level       confidence level in percent (e.g. 95)

  Returns
    K x 6 real matrix: [horizon, mean_placebo, se, ci_lower, ci_upper, n_cells]
    Returns a 0 x 6 empty matrix when required e() components are unavailable.
──────────────────────────────────────────────────────────────────────────────*/

real matrix _trop_placebo_effects(
    string scalar depvar,
    string scalar panelvar,
    string scalar timevar,
    string scalar treatvar,
    real scalar n_placebo,
    real scalar level
)
{
    real matrix alpha, beta, factor_matrix, D_matrix
    real scalar n_periods, n_units, i, t, h, g_i
    real scalar min_h, max_h, n_horizons, h_idx
    real scalar z, se_h, placebo_val
    real colvector first_treat, placebo_h
    real matrix Y_matrix, result
    string scalar touse_var, panel_idx_var, time_idx_var

    /* ── Read estimated parameters from e() ──────────────────────────── */
    alpha = st_matrix("e(alpha)")
    beta = st_matrix("e(beta)")
    factor_matrix = st_matrix("e(factor_matrix)")

    /* Cannot compute placebo without all model components */
    if (rows(alpha) == 0 | rows(beta) == 0 | rows(factor_matrix) == 0) {
        return(J(0, 6, .))
    }
    if (cols(factor_matrix) == 0) {
        return(J(0, 6, .))
    }

    n_periods = rows(factor_matrix)
    n_units = cols(factor_matrix)

    /* Validate dimension consistency */
    if (rows(alpha) < n_units | rows(beta) < n_periods) {
        return(J(0, 6, .))
    }

    /* ── Reconstruct panel data matrices ─────────────────────────────── */
    touse_var = st_global("__trop_touse_var")
    panel_idx_var = st_global("__trop_panel_idx_var")
    time_idx_var = st_global("__trop_time_idx_var")

    if (touse_var == "" | panel_idx_var == "" | time_idx_var == "") {
        return(J(0, 6, .))
    }
    /* Guard against dropped tempvars */
    if (_st_varindex(touse_var) >= . | _st_varindex(panel_idx_var) >= . |
        _st_varindex(time_idx_var) >= . | _st_varindex(depvar) >= . |
        _st_varindex(treatvar) >= .) {
        return(J(0, 6, .))
    }

    /* Build T x N outcome matrix and treatment indicator matrix */
    Y_matrix = J(n_periods, n_units, .)
    D_matrix = J(n_periods, n_units, 0)
    {
        real matrix obs_data
        real scalar n_obs, k, row_t, col_i
        obs_data = st_data(., (depvar, treatvar, panel_idx_var, time_idx_var), touse_var)
        n_obs = rows(obs_data)
        for (k = 1; k <= n_obs; k++) {
            row_t = obs_data[k, 4]
            col_i = obs_data[k, 3]
            if (row_t >= 1 & row_t <= n_periods & col_i >= 1 & col_i <= n_units) {
                Y_matrix[row_t, col_i] = obs_data[k, 1]
                D_matrix[row_t, col_i] = (obs_data[k, 2] != 0 ? 1 : 0)
            }
        }
    }

    /* ── Determine first treatment period for each unit ──────────────── */
    first_treat = J(n_units, 1, .)
    for (i = 1; i <= n_units; i++) {
        for (t = 1; t <= n_periods; t++) {
            if (D_matrix[t, i] == 1) {
                first_treat[i] = t
                break
            }
        }
    }

    /* ── Compute placebo residuals for pre-treatment periods ─────────── */
    /* Determine horizon range: restrict to -n_placebo .. -1 */
    min_h = -n_placebo
    max_h = -1

    n_horizons = max_h - min_h + 1
    if (n_horizons <= 0) return(J(0, 6, .))

    result = J(n_horizons, 6, .)
    z = invnormal(1 - (1 - level / 100) / 2)

    for (h_idx = 1; h_idx <= n_horizons; h_idx++) {
        h = min_h + h_idx - 1
        result[h_idx, 1] = h

        /* Collect placebo residuals at this horizon */
        placebo_h = J(0, 1, .)
        for (i = 1; i <= n_units; i++) {
            g_i = first_treat[i]
            if (g_i >= .) continue

            t = g_i + h
            if (t < 1 | t > n_periods) continue
            if (Y_matrix[t, i] >= .) continue

            /* placebo = Y_{i,t} - alpha_i - beta_t - L_{t,i} */
            placebo_val = Y_matrix[t, i] - alpha[i, 1] - beta[t, 1] - factor_matrix[t, i]
            placebo_h = placebo_h \ placebo_val
        }

        result[h_idx, 6] = rows(placebo_h)
        if (rows(placebo_h) > 0) {
            result[h_idx, 2] = mean(placebo_h)
            if (rows(placebo_h) > 1) {
                se_h = sqrt(variance(placebo_h)) / sqrt(rows(placebo_h))
                result[h_idx, 3] = se_h
                result[h_idx, 4] = result[h_idx, 2] - z * se_h
                result[h_idx, 5] = result[h_idx, 2] + z * se_h
            }
        }
    }

    return(result)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_pretrend_test()

  Joint Wald test of the null hypothesis that all pre-treatment placebo
  effects are zero:

      H0: tau(-1) = tau(-2) = ... = tau(-K) = 0

  Uses a simplified (independence assumption) Wald statistic:

      W = sum_h (tau_h / se_h)^2

  Under H0 with independent estimates, W ~ chi2(K) where K is the number
  of horizons with valid (finite) tau and se.

  Arguments
    placebo_result   K x 6 matrix from _trop_placebo_effects()
                     [horizon, mean_placebo, se, ci_lower, ci_upper, n_cells]

  Returns
    1 x 3 real rowvector: (chi2_stat, df, p_value)
    Returns (., ., .) when the test cannot be computed.
──────────────────────────────────────────────────────────────────────────────*/

real rowvector _trop_pretrend_test(real matrix placebo_result)
{
    real scalar K, k, df, W, tau_h, se_h
    real rowvector test_result

    test_result = (., ., .)

    if (rows(placebo_result) == 0) return(test_result)

    K = rows(placebo_result)
    W = 0
    df = 0

    for (k = 1; k <= K; k++) {
        tau_h = placebo_result[k, 2]
        se_h = placebo_result[k, 3]

        /* Skip horizons without valid tau or se */
        if (tau_h >= . | se_h >= . | se_h <= 0) continue

        W = W + (tau_h / se_h)^2
        df++
    }

    if (df == 0) return(test_result)

    test_result[1] = W
    test_result[2] = df
    test_result[3] = 1 - chi2(df, W)

    return(test_result)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_run_pretrend_test()

  Enhanced pre-trend test invoked by `estat pretrend`.  Computes pre-treatment
  placebo effects and performs a joint Wald test of the null hypothesis:

      H0: tau(-K) = tau(-K+1) = ... = tau(-1) = 0

  Default mode (diagonal covariance, independence assumption):
      W = sum_h (tau_h / se_h)^2 ~ chi2(K)

  Robust mode (uses Bootstrap covariance, if available):
      W = tau_pre' * V_pre^{-1} * tau_pre ~ chi2(K)
      where V_pre is estimated from Bootstrap replicates.

  Displays formatted output and stores results in Stata scalars for the
  ADO-layer to retrieve.

  Arguments
    n_periods   number of pre-treatment periods to test (0 = all available)
    level       confidence level in percent (e.g. 95)
    robust      "robust" to use Bootstrap covariance, "" for diagonal
    depvar      name of the outcome variable
    panelvar    name of the panel variable
    timevar     name of the time variable
    treatvar    name of the treatment indicator variable

  Side effects
    Stores in Stata scalars:
      __pretrend_chi2      test statistic
      __pretrend_df        degrees of freedom
      __pretrend_p         p-value
      __pretrend_pass      1 = cannot reject H0, 0 = reject
      __pretrend_nperiods  number of pre-periods tested
──────────────────────────────────────────────────────────────────────────────*/

void _trop_run_pretrend_test(
    real scalar n_periods,
    real scalar level,
    string scalar robust,
    string scalar depvar,
    string scalar panelvar,
    string scalar timevar,
    string scalar treatvar
)
{
    real matrix placebo_result
    real scalar K, k, df, W, tau_h, se_h
    real scalar alpha_level, pass
    real scalar actual_periods

    /* ── Step 1: Compute placebo effects ───────────────────────────────── */
    /* Determine how many pre-periods to use */
    if (n_periods <= 0) {
        /* Use all available: set a large number and let _trop_placebo_effects
           handle the actual available range */
        actual_periods = 100
    }
    else {
        actual_periods = n_periods
    }

    placebo_result = _trop_placebo_effects(depvar, panelvar, timevar,
                                           treatvar, actual_periods, level)

    if (rows(placebo_result) == 0) {
        /* Cannot compute: store missing values */
        st_numscalar("__pretrend_chi2", .)
        st_numscalar("__pretrend_df", .)
        st_numscalar("__pretrend_p", .)
        st_numscalar("__pretrend_pass", .)
        st_numscalar("__pretrend_nperiods", 0)
        return
    }

    /* If user specified fewer periods than available, trim to last n_periods */
    if (n_periods > 0 & rows(placebo_result) > n_periods) {
        /* Keep only the last n_periods rows (closest to treatment) */
        K = rows(placebo_result)
        placebo_result = placebo_result[(K - n_periods + 1)::K, .]
    }

    /* ── Step 2: Compute Wald statistic ────────────────────────────────── */
    if (robust == "robust") {
        /* TODO: Robust mode using Bootstrap covariance matrix.
           Requires reconstructing per-horizon effects from Bootstrap replicates,
           which is not currently stored in e(). For now, fall back to diagonal. */
        printf("{txt}(note: robust covariance not yet available; using diagonal approximation)\n")
    }

    /* Diagonal (independence) Wald test: W = sum (tau_h / se_h)^2 */
    K = rows(placebo_result)
    W = 0
    df = 0

    for (k = 1; k <= K; k++) {
        tau_h = placebo_result[k, 2]
        se_h = placebo_result[k, 3]

        /* Skip horizons without valid tau or se */
        if (tau_h >= . | se_h >= . | se_h <= 0) continue

        W = W + (tau_h / se_h)^2
        df++
    }

    if (df == 0) {
        st_numscalar("__pretrend_chi2", .)
        st_numscalar("__pretrend_df", .)
        st_numscalar("__pretrend_p", .)
        st_numscalar("__pretrend_pass", .)
        st_numscalar("__pretrend_nperiods", 0)
        return
    }

    alpha_level = 1 - level / 100
    pass = (1 - chi2(df, W) > alpha_level ? 1 : 0)

    /* ── Step 3: Display formatted output ──────────────────────────────── */
    printf("\n")
    printf("{txt}{hline 60}\n")
    printf("{txt}Pre-trend test (H{subscript:0}: all pre-treatment effects = 0)\n")
    printf("{txt}{hline 60}\n")
    printf("{txt}  Test statistic:    Chi2(%g) = {res}%8.4f\n", df, W)
    printf("{txt}  p-value:           {res}%8.4f\n", 1 - chi2(df, W))
    printf("{txt}  Pre-periods tested: %g\n", df)
    printf("{txt}{hline 60}\n")

    if (pass) {
        printf("{txt}  Result: {res}Cannot reject parallel trends (p > %g)\n",
               alpha_level)
    }
    else {
        printf("{err}  Result: Pre-trends detected (p <= %g){txt}\n",
               alpha_level)
    }

    printf("{txt}{hline 60}\n")
    if (robust != "robust") {
        printf("{txt}  Note: Test assumes independence of pre-period effects.\n")
        printf("{txt}        Use option 'robust' for Bootstrap-based covariance.\n")
    }
    printf("\n")

    /* ── Step 4: Store results in Stata scalars ────────────────────────── */
    st_numscalar("__pretrend_chi2", W)
    st_numscalar("__pretrend_df", df)
    st_numscalar("__pretrend_p", 1 - chi2(df, W))
    st_numscalar("__pretrend_pass", pass)
    st_numscalar("__pretrend_nperiods", df)
}



/* ── version tag: trop_eventstudy.mata v1.1 ─────────────────────────────── */

/*──────────────────────────────────────────────────────────────────────────────
  _trop_estat_eventstudy_compute()
  Extracted from _trop_estat_eventstudy.ado for Stata 19 compatibility.
──────────────────────────────────────────────────────────────────────────────*/
void _trop_estat_eventstudy_compute(string scalar tau_mat_name, ///
    string scalar treatvar, real scalar level)
{
    real matrix _es_tau_m, _es_D_m, _es_result
    real scalar _es_nT, _es_nN, _es_nobs, _es_k
    real scalar _es_row_t, _es_col_i
    real matrix _es_obs_data
    string scalar _es_touse_var, _es_panel_idx_var, _es_time_idx_var

    _es_tau_m = st_matrix(tau_mat_name)
    _es_nT = rows(_es_tau_m)
    _es_nN = cols(_es_tau_m)

    _es_touse_var = st_global("__trop_touse_var")
    _es_panel_idx_var = st_global("__trop_panel_idx_var")
    _es_time_idx_var = st_global("__trop_time_idx_var")

    if (_es_touse_var != "" & _es_panel_idx_var != "" & _es_time_idx_var != "" & ///
        _st_varindex(_es_touse_var) < . & _st_varindex(_es_panel_idx_var) < . & ///
        _st_varindex(_es_time_idx_var) < . & _st_varindex(treatvar) < .) {

        _es_D_m = J(_es_nT, _es_nN, 0)
        _es_obs_data = st_data(., (treatvar, _es_panel_idx_var, _es_time_idx_var), _es_touse_var)
        _es_nobs = rows(_es_obs_data)
        for (_es_k = 1; _es_k <= _es_nobs; _es_k++) {
            _es_row_t = _es_obs_data[_es_k, 3]
            _es_col_i = _es_obs_data[_es_k, 2]
            if (_es_row_t >= 1 & _es_row_t <= _es_nT & _es_col_i >= 1 & _es_col_i <= _es_nN) {
                _es_D_m[_es_row_t, _es_col_i] = (_es_obs_data[_es_k, 1] != 0 ? 1 : 0)
            }
        }
    }
    else {
        _es_D_m = (_es_tau_m :< .)
    }

    _es_result = _trop_aggregate_by_horizon(_es_tau_m, _es_D_m, level)
    st_matrix("__es_result", _es_result)
}


/*── Window filter helper ──*/
void _trop_estat_eventstudy_filter(real scalar wlow, real scalar whigh, real scalar nkeep)
{
    real matrix _es_orig, _es_filtered
    real scalar _es_r, _es_cnt
    _es_orig = st_matrix("__es_result")
    _es_filtered = J(nkeep, 6, .)
    _es_cnt = 0
    for (_es_r = 1; _es_r <= rows(_es_orig); _es_r++) {
        if (_es_orig[_es_r, 1] >= wlow & _es_orig[_es_r, 1] <= whigh) {
            _es_cnt++
            _es_filtered[_es_cnt, .] = _es_orig[_es_r, .]
        }
    }
    st_matrix("__es_result", _es_filtered)
}

/*── Placebo/pretrend helper ──*/
void _trop_estat_eventstudy_placebo(string scalar depvar, string scalar panelvar, ///
    string scalar timevar, string scalar treatvar, ///
    real scalar placebo_periods, real scalar level)
{
    real matrix _es_placebo_result
    real rowvector _es_pretrend
    _es_placebo_result = _trop_placebo_effects(depvar, panelvar, ///
        timevar, treatvar, placebo_periods, level)
    st_matrix("__es_placebo", _es_placebo_result)
    _es_pretrend = _trop_pretrend_test(_es_placebo_result)
    st_numscalar("__es_chi2", _es_pretrend[1])
    st_numscalar("__es_df", _es_pretrend[2])
    st_numscalar("__es_pval", _es_pretrend[3])
}

end
