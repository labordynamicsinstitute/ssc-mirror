/*──────────────────────────────────────────────────────────────────────────────
  trop_ereturn_store.mata

  Post-estimation result storage for the TROP estimator.

  Reads intermediate scalars and matrices written by the computational
  backend (temporary Stata scalars/matrices with the __trop_ prefix) and
  posts them into Stata's e() return structure.

  The TROP model decomposes the outcome as

      Y_{it} = alpha_i + beta_t + mu_{it} + tau_{it} * W_{it}

  where alpha_i are unit fixed effects, beta_t are time fixed effects,
  mu_{it} is a low-rank (nuclear-norm penalised) component, and tau_{it}
  is the treatment effect.

  e(mu) semantics differ by estimation method:
    - Twostep:  e(mu) = .  (no global intercept; model is Y = alpha + beta + L)
    - Joint:    e(mu) = mu (scalar intercept with identification constraint
                alpha_1 = beta_1 = 0)

  Contents
    trop_store_results()                main e() storage entry point
    _trop_safe_read_scalar()            safe scalar reader
    _trop_lambda_nn_user_face()         1e10 (internal +inf sentinel) -> .
    _trop_display_warnings()            estimation diagnostic messages
    _trop_display_conv_diagnostics()  convergence health check + suggestions
    _trop_compute_effective_rank()      SVD-based effective rank
    _trop_display_bootstrap_warnings()  bootstrap diagnostic messages
    _trop_store_lambda_grids()          LOOCV grid and CV curve storage
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  trop_store_results()

  Main entry point for e() result storage.

  Arguments
    method   "twostep" or "joint"

  Stored e() returns
    Scalars   att, se, t, ci_lower, ci_upper, pvalue, df_r, mu,
              lambda_time, lambda_unit, lambda_nn,
              loocv_first_failed_t, loocv_first_failed_i,
              n_iterations, converged, n_obs_estimated, n_obs_failed,
              n_bootstrap_valid, level, ci_lower_percentile,
              ci_upper_percentile, N_treated, N_treated_obs,
              N_treated_units, effective_rank, alpha_level
    Matrices  alpha, beta, tau, factor_matrix, bootstrap_estimates,
              theta/omega (twostep), delta_time/delta_unit (joint),
              lambda_grid, cv_curve
    Globals   title, predict
──────────────────────────────────────────────────────────────────────────────*/

void trop_store_results(string scalar method)
{
    real scalar att, se, ci_lower, ci_upper, pvalue
    real scalar lambda_time, lambda_unit, lambda_nn
    real scalar stage1_lambda_time, stage1_lambda_unit, stage1_lambda_nn
    real scalar n_iterations, converged, bootstrap_reps, alpha_level
    real scalar n_units, n_periods, n_treated, effective_rank
    real scalar loocv_first_failed_t, loocv_first_failed_i
    real scalar loocv_score, loocv_n_valid, loocv_n_attempted
    real matrix alpha, beta, factor_matrix, tau, bootstrap_estimates
    real scalar mu
    real scalar n_bootstrap_valid, level
    real scalar tstat
    real scalar n_treated_obs, n_treated_units, df_pvalue
    real scalar ci_lower_pct, ci_upper_pct
    real scalar ci_lower_t, ci_upper_t, pvalue_t
    real scalar ci_lower_normal, ci_upper_normal, pvalue_normal
    string scalar cimethod_req, cimethod_used
    real scalar n_obs_estimated, n_obs_failed
    real matrix temp_mat, temp_scalar

    /* ── verify that the core ATT scalar exists ──────────────────────── */
    temp_scalar = st_numscalar("__trop_att")
    if (rows(temp_scalar) == 0) {
        errprintf("Error: TROP estimation did not produce results.\n")
        errprintf("       __trop_att is missing. Check if plugin executed correctly.\n")
        _error(3200)
    }
    att = temp_scalar

    /* ── core estimation results ─────────────────────────────────────── */

    se = _trop_safe_read_scalar("__trop_se")

    /* Resolve significance level: prefer bootstrap-specific alpha,
       fall back to estimation-level alpha, then default 0.05. */
    alpha_level = _trop_safe_read_scalar("__trop_bs_alpha")
    if (alpha_level >= . | alpha_level <= 0 | alpha_level >= 1) {
        alpha_level = _trop_safe_read_scalar("__trop_alpha_level")
    }
    if (alpha_level >= . | alpha_level <= 0 | alpha_level >= 1) {
        alpha_level = 0.05
    }

    /* Number of treated observations (treated cells W_{it}=1).  Kept for
       display as e(N_treated_obs); NOT used as the reference df.

       Twostep: length of the tau vector (one per treated cell).
       Joint:   count of W_{it}=1 cells in the panel. */
    n_treated_obs = _trop_safe_read_scalar("__trop_n_treated")
    if (n_treated_obs >= .) {
        temp_mat = st_matrix("__trop_tau")
        if (rows(temp_mat) > 0) {
            n_treated_obs = rows(temp_mat)
        }
        else {
            n_treated_obs = .
        }
    }

    /* Number of ever-treated units N_1.  Algorithm 3 resamples units
       with replacement inside the treated stratum, so the bootstrap SE's
       effective df is governed by the cluster count (units), not by the
       number of treated cells. */
    n_treated_units = _trop_safe_read_scalar("__trop_n_treated_units")

    /* Percentile CI from the bootstrap empirical CDF (paper Algorithm 3
       step 6).  Read before the parametric branch so the caller-selected
       cimethod() can promote it to the primary CI below. */
    ci_lower_pct = _trop_safe_read_scalar("__trop_ci_lower_percentile")
    ci_upper_pct = _trop_safe_read_scalar("__trop_ci_upper_percentile")

    /* Compute all three candidate CI pairs (t, normal, percentile) so
       consumers can switch interval types without rerunning the model.
       One of them will be promoted to the authoritative
       e(ci_lower)/e(ci_upper) pair below, based on __trop_cimethod. */
    ci_lower_t = .
    ci_upper_t = .
    pvalue_t = .
    ci_lower_normal = .
    ci_upper_normal = .
    pvalue_normal = .

    if (se > 0 && se < .) {
        tstat = att / se
        /* Standard-normal wrap (always defined when SE > 0). */
        pvalue_normal = 2 * normal(-abs(tstat))
        ci_lower_normal = att - invnormal(1 - alpha_level / 2) * se
        ci_upper_normal = att + invnormal(1 - alpha_level / 2) * se

        /* t(N_1 - 1) wrap whenever at least 2 treated units are available;
           otherwise the t branch collapses to the normal branch. */
        if (n_treated_units < . && n_treated_units >= 2) {
            df_pvalue = max((1, n_treated_units - 1))
            pvalue_t = 2 * ttail(df_pvalue, abs(tstat))
            ci_lower_t = att - invttail(df_pvalue, alpha_level / 2) * se
            ci_upper_t = att + invttail(df_pvalue, alpha_level / 2) * se
        }
        else {
            df_pvalue = .
            pvalue_t = pvalue_normal
            ci_lower_t = ci_lower_normal
            ci_upper_t = ci_upper_normal
        }
    }
    else {
        tstat = .
        df_pvalue = .
    }

    /* Resolve which CI method is authoritative.  The ADO layer normally
       sets __trop_cimethod; when absent we default to "percentile"
       whenever a valid percentile CI exists and to "t" otherwise.  When
       the user requested "percentile" but the bootstrap produced no
       finite quantiles we downgrade to "t" and report the downgrade
       through e(cimethod). */
    cimethod_req = st_global("__trop_cimethod")
    if (cimethod_req == "") {
        if (ci_lower_pct < . && ci_upper_pct < .) cimethod_req = "percentile"
        else cimethod_req = "t"
    }
    cimethod_used = cimethod_req
    if (cimethod_req == "percentile" && (ci_lower_pct >= . || ci_upper_pct >= .)) {
        cimethod_used = "t"
    }

    if (cimethod_used == "percentile") {
        ci_lower = ci_lower_pct
        ci_upper = ci_upper_pct
        /* Percentile CI does not yield a p-value directly; report the
           t-based p-value so e(pvalue) remains defined.  Consumers that
           want a percentile-consistent test should invert e(ci_lower/
           ci_upper) manually. */
        pvalue = pvalue_t
    }
    else if (cimethod_used == "normal") {
        ci_lower = ci_lower_normal
        ci_upper = ci_upper_normal
        pvalue = pvalue_normal
    }
    else {  /* "t" or any unforeseen token */
        ci_lower = ci_lower_t
        ci_upper = ci_upper_t
        pvalue = pvalue_t
    }

    /* ── regularization hyperparameters ──────────────────────────────── */
    lambda_time = _trop_safe_read_scalar("__trop_lambda_time")
    lambda_unit = _trop_safe_read_scalar("__trop_lambda_unit")
    lambda_nn = _trop_safe_read_scalar("__trop_lambda_nn")

    /* ── LOOCV diagnostics ───────────────────────────────────────────── */
    loocv_score = _trop_safe_read_scalar("__trop_loocv_score")
    loocv_n_valid = _trop_safe_read_scalar("__trop_loocv_n_valid")
    loocv_n_attempted = _trop_safe_read_scalar("__trop_loocv_n_attempted")
    loocv_first_failed_t = _trop_safe_read_scalar("__trop_loocv_first_failed_t")
    loocv_first_failed_i = _trop_safe_read_scalar("__trop_loocv_first_failed_i")

    /* ── Stage-1 univariate initial lambda triple (paper Footnote 2) ──
       Written by the cycling LOOCV paths only.  Exhaustive search does
       not use a Stage-1 initialisation and leaves these scalars unset,
       in which case `_trop_safe_read_scalar` returns missing (.), which
       is the correct e() value semantically ("not applicable"). */
    stage1_lambda_time = _trop_safe_read_scalar("__trop_stage1_lambda_time")
    stage1_lambda_unit = _trop_safe_read_scalar("__trop_stage1_lambda_unit")
    stage1_lambda_nn   = _trop_safe_read_scalar("__trop_stage1_lambda_nn")

    /* ── convergence information ─────────────────────────────────────── */
    n_iterations = _trop_safe_read_scalar("__trop_n_iterations")
    converged = _trop_safe_read_scalar("__trop_converged")
    n_obs_estimated = _trop_safe_read_scalar("__trop_n_obs_estimated")
    n_obs_failed = _trop_safe_read_scalar("__trop_n_obs_failed")

    /* ── bootstrap configuration ─────────────────────────────────────── */
    bootstrap_reps = _trop_safe_read_scalar("__trop_n_bootstrap")

    /* ── bootstrap diagnostics ───────────────────────────────────────── */
    n_bootstrap_valid = _trop_safe_read_scalar("__trop_n_bootstrap_valid")
    /* stata_bridge.c writes __trop_level = 1 - alpha (e.g. 0.95).  Convert
       to Stata-convention percent form for e(level) (e.g. 95). */
    level = _trop_safe_read_scalar("__trop_level")
    if (level < . & level > 0 & level < 1) {
        level = level * 100
    }

    /* Percentile CI was already read above (for cimethod resolution).
       Emit the companion scalars into e() below alongside the other
       candidate intervals. */

    /* ── sample information ──────────────────────────────────────────── */
    n_units = _trop_safe_read_scalar("__trop_n_units")
    n_periods = _trop_safe_read_scalar("__trop_n_periods")
    effective_rank = .

    /* ── read matrices from temporary storage ────────────────────────── */

    temp_mat = st_matrix("__trop_alpha")
    if (rows(temp_mat) > 0) alpha = temp_mat
    else alpha = J(0, 1, .)

    temp_mat = st_matrix("__trop_beta")
    if (rows(temp_mat) > 0) beta = temp_mat
    else beta = J(0, 1, .)

    temp_mat = st_matrix("__trop_factor_matrix")
    if (rows(temp_mat) > 0) factor_matrix = temp_mat
    else factor_matrix = J(0, 0, .)

    if (bootstrap_reps > 0) {
        temp_mat = st_matrix("__trop_bootstrap_estimates")
        if (rows(temp_mat) > 0) {
            /* Filter trailing missing values: the matrix is pre-allocated
               at full size; only the first n_valid rows are populated. */
            bootstrap_estimates = select(temp_mat, temp_mat :< .)
        }
        else {
            bootstrap_estimates = J(0, 1, .)
        }
    }
    else {
        bootstrap_estimates = J(0, 1, .)
    }

    /* ═══════════════════ store into e() ══════════════════════════════ */

    /* ── core estimation results ─────────────────────────────────────── */
    st_numscalar("e(att)", att)
    st_numscalar("e(se)", se)
    st_numscalar("e(t)", tstat)
    st_numscalar("e(ci_lower)", ci_lower)
    st_numscalar("e(ci_upper)", ci_upper)
    st_numscalar("e(pvalue)", pvalue)
    /* e(df_r) reflects the reference distribution actually used above:
       t(N_1 - 1) when N_1 >= 2, missing (normal fallback) otherwise. */
    if (n_treated_units < . && n_treated_units >= 2) {
        st_numscalar("e(df_r)", max((1, n_treated_units - 1)))
    }
    else {
        st_numscalar("e(df_r)", .)
    }

    /* ── regularization hyperparameters ──────────────────────────────── */
    /* Round-trip the lambda_nn sentinel back to Stata missing (.) when the
       estimator ran in the DID/TWFE corner (internal value 1e10) so the
       exported e(lambda_nn) matches what the user typed / the grid
       displayed.  Without this the C-bridge-converted 1e10 would leak into
       user code, breaking symbolic comparisons like `if e(lambda_nn) >= .`. */
    st_numscalar("e(lambda_time)", lambda_time)
    st_numscalar("e(lambda_unit)", lambda_unit)
    st_numscalar("e(lambda_nn)", _trop_lambda_nn_user_face(lambda_nn))

    /* ── Stage-1 univariate initial lambda triple (paper Footnote 2) ──
       Cycling LOOCV paths perform three univariate sweeps to seed the
       Stage-2 coordinate descent; exposing this triple lets downstream
       diagnostics compare the initial and refined optima.  A large
       (lambda_stage1, lambda_final) gap indicates Stage-2 did non-
       trivial work on a non-convex Q(lambda) surface.  The exhaustive
       LOOCV paths do not use a Stage-1 initialisation and leave these
       scalars missing. */
    st_numscalar("e(stage1_lambda_time)", stage1_lambda_time)
    st_numscalar("e(stage1_lambda_unit)", stage1_lambda_unit)
    st_numscalar(
        "e(stage1_lambda_nn)",
        _trop_lambda_nn_user_face(stage1_lambda_nn)
    )

    /* ── LOOCV diagnostics (first-failure indices) ───────────────────── */
    st_numscalar("e(loocv_first_failed_t)", loocv_first_failed_t)
    st_numscalar("e(loocv_first_failed_i)", loocv_first_failed_i)

    /* ── convergence information ─────────────────────────────────────── */
    st_numscalar("e(n_iterations)", n_iterations)
    st_numscalar("e(converged)", converged)
    if (n_obs_estimated < .) {
        st_numscalar("e(n_obs_estimated)", n_obs_estimated)
    }
    if (n_obs_failed < . && n_obs_failed > 0) {
        st_numscalar("e(n_obs_failed)", n_obs_failed)
    }

    /* ── bootstrap diagnostics ───────────────────────────────────────── */
    st_numscalar("e(n_bootstrap_valid)", n_bootstrap_valid)
    st_numscalar("e(level)", level)

    /* Bootstrap failure rate in [0, 1].  Mirrors e(loocv_fail_rate) so
       downstream consumers can compare failure severity across the
       LOOCV and bootstrap stages using a single scalar.  Missing when
       bootstrap_reps is zero or n_bootstrap_valid was not populated. */
    if (bootstrap_reps < . & bootstrap_reps > 0 & n_bootstrap_valid < .) {
        st_numscalar(
            "e(bootstrap_fail_rate)",
            (bootstrap_reps - n_bootstrap_valid) / bootstrap_reps
        )
    }
    else {
        st_numscalar("e(bootstrap_fail_rate)", .)
    }

    /* All three candidate interval pairs are always written when defined,
       so downstream consumers can switch cimethod without re-running the
       model.  e(ci_lower)/e(ci_upper) above holds the one selected via
       cimethod(); e(cimethod) below records that choice. */
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

    /* Record which CI method actually populated e(ci_lower)/e(ci_upper).
       When cimethod(percentile) was requested but the bootstrap produced
       no finite quantiles, we downgrade to "t" and surface the downgrade
       as "percentile->t" so downstream code can detect the auto-repair. */
    if (cimethod_used != cimethod_req) {
        st_global("e(cimethod)", cimethod_req + "->" + cimethod_used)
    }
    else {
        st_global("e(cimethod)", cimethod_used)
    }

    /* ── parameter matrices ──────────────────────────────────────────── */
    st_matrix("e(alpha)", alpha)
    st_matrix("e(beta)", beta)
    st_matrix("e(factor_matrix)", factor_matrix)

    /* Effective rank via continuous SVD criterion: sum(s) / s[1] */
    effective_rank = _trop_compute_effective_rank(factor_matrix)
    if (effective_rank < .) {
        st_numscalar("e(effective_rank)", effective_rank)
    }

    /* ── bootstrap replicate distribution ────────────────────────────── */
    if (bootstrap_reps > 0 && rows(bootstrap_estimates) > 0) {
        st_matrix("e(bootstrap_estimates)", bootstrap_estimates)
    }

    /* ── lambda grids and CV curve ───────────────────────────────────── */
    _trop_store_lambda_grids(lambda_time, lambda_unit, lambda_nn, loocv_score)

    /* ── LOOCV RMSE (root mean squared pseudo-treatment-effect) ────────
       RMSE = sqrt(Q(lambda_hat) / n_valid) measures the cross-validation
       prediction error; smaller values indicate better out-of-sample fit.
       Not defined when LOOCV was not performed (e.g. fixedlambda mode). */
    if (loocv_score < . & loocv_n_valid < . & loocv_n_valid > 0) {
        st_numscalar("e(loocv_rmse)", sqrt(loocv_score / loocv_n_valid))
    }

    /* ── raw LOOCV diagnostics exposed on e() ─────────────────────────
       These are consumed directly by estat loocv and estat sensitivity. */
    if (loocv_score < .) {
        st_numscalar("e(loocv_score)", loocv_score)
    }
    if (loocv_n_valid < .) {
        st_numscalar("e(loocv_n_valid)", loocv_n_valid)
    }
    if (loocv_n_attempted < .) {
        st_numscalar("e(loocv_n_attempted)", loocv_n_attempted)
    }

    /* ── LOOCV failure rate ────────────────────────────────────────────
       Fraction of grid-point evaluations that did not converge during
       the LOOCV search; mirrors e(bootstrap_fail_rate) above. */
    if (loocv_n_attempted < . & loocv_n_attempted > 0 & loocv_n_valid < .) {
        st_numscalar("e(loocv_fail_rate)",
                     (loocv_n_attempted - loocv_n_valid) / loocv_n_attempted)
    }

    /* ── method-specific storage ─────────────────────────────────────── */
    /* n_treated_units was already read above for the df reference
       distribution; only expose it on e() here. */
    if (n_treated_units < .) {
        st_numscalar("e(N_treated_units)", n_treated_units)
    }

    if (method == "twostep") {
        /* Twostep: no global intercept; model is Y = alpha + beta + L */
        st_numscalar("e(mu)", .)

        /* Individual treatment effect vector tau_{i,t} */
        temp_mat = st_matrix("__trop_tau")
        if (rows(temp_mat) > 0) {
            tau = temp_mat
            st_matrix("e(tau)", tau)
            n_treated = rows(tau)
            st_numscalar("e(N_treated)", n_treated)
            st_numscalar("e(N_treated_obs)", n_treated)
        }

        /* Per-observation convergence diagnostics.  When every entry is ≥ 0,
           the plugin populated the matrix; skip on pre-allocation (−1). */
        temp_mat = st_matrix("__trop_converged_by_obs")
        if (rows(temp_mat) > 0 && min(temp_mat) > -0.5) {
            st_matrix("e(converged_by_obs)", temp_mat)
        }
        temp_mat = st_matrix("__trop_n_iters_by_obs")
        if (rows(temp_mat) > 0 && min(temp_mat) > -0.5) {
            st_matrix("e(n_iters_by_obs)", temp_mat)
        }

        /* Time weights theta (T x 1) and unit weights omega (N x 1) */
        temp_mat = st_matrix("__trop_theta")
        if (rows(temp_mat) > 0 && any(temp_mat)) {
            st_matrix("e(theta)", temp_mat)
        }
        temp_mat = st_matrix("__trop_omega")
        if (rows(temp_mat) > 0 && any(temp_mat)) {
            st_matrix("e(omega)", temp_mat)
        }
    }
    else if (method == "joint") {
        /* Joint: global intercept mu with alpha_1 = beta_1 = 0 */
        mu = _trop_safe_read_scalar("__trop_mu")
        st_numscalar("e(mu)", mu)

        n_treated = _trop_safe_read_scalar("__trop_n_treated")
        st_numscalar("e(N_treated)", n_treated)
        st_numscalar("e(N_treated_obs)", n_treated)

        /* Individual treatment effect vector tau_{i,t} per Eq 13.  The joint
           method extracts τ post-hoc: τ_{it} = Y_{it} − μ − α_i − β_t − L_{it}
           for each treated cell.  ATT = mean(τ) by Eq 1. */
        temp_mat = st_matrix("__trop_tau")
        if (rows(temp_mat) > 0) {
            tau = temp_mat
            st_matrix("e(tau)", tau)
        }

        /* Time weights delta_time (T x 1) and unit weights delta_unit (N x 1) */
        temp_mat = st_matrix("__trop_delta_time")
        if (rows(temp_mat) > 0 && any(temp_mat)) {
            st_matrix("e(delta_time)", temp_mat)
        }
        temp_mat = st_matrix("__trop_delta_unit")
        if (rows(temp_mat) > 0 && any(temp_mat)) {
            st_matrix("e(delta_unit)", temp_mat)
        }
    }

    /* ── (time x unit) treatment-effect matrix ───────────────────────
       e(tau) is a vector of length N_treated (time-major).  Build a
       T x N matrix with tau_{it} in its (t, i) cell and missing values
       elsewhere, so that consumers can locate effects by (time, panel)
       without reconstructing the ordering. */
    _trop_build_tau_matrix(n_periods, n_units)

    /* ── covariate coefficients (gamma) ──────────────────────────────
       When covariates are present, the plugin writes the fitted gamma
       vector into __trop_gamma (1 x p row vector).  Store as e(gamma)
       and record p as e(n_covariates).  When p = 0 (no covariates),
       skip so e(gamma) remains undefined and consumers can branch on
       `missing(e(n_covariates))` or `e(n_covariates) == 0`. */
    {
        real scalar _p_cov
        real matrix _gamma_mat
        _p_cov = _trop_safe_read_scalar("__trop_n_covariates")
        if (_p_cov < . & _p_cov > 0) {
            st_numscalar("e(n_covariates)", _p_cov)
            _gamma_mat = st_matrix("__trop_gamma")
            if (cols(_gamma_mat) >= _p_cov) {
                st_matrix("e(gamma)", _gamma_mat)
            }
        }
        else {
            st_numscalar("e(n_covariates)", 0)
        }
    }

    /* ── condition number of covariate X'WX system ──────────────────
       kappa(X'WX) = s_max/s_min of the SVD used in gamma estimation.
       Large values (>1e8) indicate near-collinearity among covariates
       and potential numerical instability in gamma. */
    {
        real scalar _cond_num
        _cond_num = _trop_safe_read_scalar("__trop_condition_number")
        if (_cond_num < . & _cond_num > 0) {
            st_numscalar("e(condition_number)", _cond_num)
        }
    }

    /* ── diagnostic warnings ─────────────────────────────────────────── */
    _trop_display_warnings(loocv_n_valid, loocv_n_attempted,
        converged, n_iterations, method, n_obs_estimated, n_obs_failed)

    /* ── convergence diagnostics with actionable suggestions ──────────── */
    _trop_display_conv_diagnostics(
        loocv_n_valid, loocv_n_attempted, converged, n_iterations)

    if (bootstrap_reps > 0 && n_bootstrap_valid < bootstrap_reps) {
        _trop_display_bootstrap_warnings(n_bootstrap_valid, bootstrap_reps)
    }

    /* ── command metadata ────────────────────────────────────────────── */
    st_global("e(title)", "TROP Estimator")
    st_global("e(predict)", "trop_p")

    /* ── specification string ───────────────────────────────────────────
       Records the estimation call parameters for reproducibility. */
    {
        string scalar spec_str
        spec_str = st_global("__trop_spec_string")
        if (spec_str != "") {
            st_global("e(spec_string)", spec_str)
        }
    }

    /* ── semantics of nuisance parameters (alpha/beta/factor_matrix) ─
       Under method(twostep), each treated cell (i,t) has its own
       (alpha^{i,t}, beta^{i,t}, L^{i,t}); for display we average across
       treated observations before storing into e(alpha)/e(beta)/
       e(factor_matrix).  Under method(joint), a single global model
       produces one (alpha, beta, L, mu) triple.  Downstream consumers
       can read this tag (e.g. `predict`, user scripts) to branch on
       the intended interpretation. */
    if (method == "twostep") {
        st_global("e(alpha_semantics)", "obs_average")
    }
    else {
        st_global("e(alpha_semantics)", "single_model")
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_safe_read_scalar()

  Reads a Stata scalar by name.  Returns missing (.) when the scalar
  does not exist (st_numscalar() yields a 0x0 matrix in that case).

  Arguments
    name   Stata scalar name

  Returns
    real scalar   the scalar value, or missing
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_safe_read_scalar(string scalar name)
{
    real matrix temp
    temp = st_numscalar(name)
    if (rows(temp) == 0) {
        return(.)
    }
    return(temp)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_lambda_nn_user_face()

  Map the internal large-finite sentinel for lambda_nn = +infinity back to
  Stata missing (.) for user-facing output.

  Pipeline symmetry
    User input:    lambda_nn = .   (Stata missing, interpreted as +inf)
    Grid layer:    stored as .     (trop_numlist_to_grid preserves missing)
    C bridge:      . -> 1e10       (convert_lambda_infinity in stata_bridge.c)
    Rust layer:    1e10 triggers the no-low-rank / DID branch (estimation.rs)
    Plugin return: writes the *converted* value 1e10 back to __trop_lambda_nn
    Display:       this helper maps 1e10 back to . so the user sees the same
                   sentinel they typed in.

  The threshold used here (_TROP_LAMBDA_NN_INF_VALUE()) must stay in sync
  with the threshold used in convert_lambda_infinity() on the C side and
  the "ln_eff >= 1e10" branch in loocv.rs / estimation.rs on the Rust
  side; a mismatch would silently display a small finite lambda_nn even
  though the estimator ran in the DID/TWFE corner.
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_lambda_nn_user_face(real scalar v)
{
    if (v >= .) {
        /* Already Stata missing, e.g. when LOOCV did not produce a value.
           Round-trip faithfully (missing in -> missing out). */
        return(.)
    }
    if (v >= _TROP_LAMBDA_NN_INF_VALUE()) {
        /* Post-C-bridge sentinel for +inf; user typed "." so show ".". */
        return(.)
    }
    return(v)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_display_warnings()

  Emits diagnostic messages for estimation issues:
    - Per-observation estimation failures (twostep only)
    - Non-convergence warnings

  LOOCV failure-rate warnings are handled separately by
  check_loocv_fail_rate().

  Arguments
    loocv_n_valid      successful LOOCV fits
    loocv_n_attempted  attempted LOOCV fits
    converged          convergence flag (1 = converged)
    n_iterations       iteration count
    method             "twostep" or "joint"
    n_obs_estimated    successfully estimated observations
    n_obs_failed       failed observations
──────────────────────────────────────────────────────────────────────────────*/

void _trop_display_warnings(
    real scalar loocv_n_valid,
    real scalar loocv_n_attempted,
    real scalar converged,
    real scalar n_iterations,
    string scalar method,
    real scalar n_obs_estimated,
    real scalar n_obs_failed
)
{
    if (method == "twostep" && n_obs_failed < . && n_obs_failed > 0) {
        printf("{res}Warning: %g of %g treated observations failed to estimate.{txt}\n",
               n_obs_failed, n_obs_estimated + n_obs_failed)
        printf("{res}         ATT is based on %g successfully estimated observations.{txt}\n",
               n_obs_estimated)
    }

    if (converged == 0) {
        if (method == "twostep") {
            printf("{res}Warning: Not all treated observations converged (max iterations=%g){txt}\n", n_iterations)
            _trop_display_unconverged_obs(n_iterations)
        }
        else {
            printf("{res}Warning: Estimation did not converge (iterations=%g){txt}\n", n_iterations)
        }
        printf("{res}         Results may be unreliable.{txt}\n")
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_display_conv_diagnostics

  Post-estimation convergence health check.  Inspects the LOOCV failure
  rate and final-estimation convergence flag, and prints actionable
  suggestions when problems are detected.

  This function is complementary to check_loocv_fail_rate() (which runs
  earlier, before estimation starts, at a 5 % threshold) and the basic
  convergence warning in _trop_display_warnings().  Here we apply a
  10 % threshold for the LOOCV failure rate (stricter messaging) and
  provide explicit user-facing remedies.

  Theoretical context:
    - The alternating minimisation (alpha -> beta -> gamma -> L cycle,
      Algorithm 1-2) is guaranteed monotone but convergence speed depends
      on the condition number of the loss Hessian.
    - A high LOOCV failure rate means many lambda combinations on the
      grid did not produce a converged fit; the selected lambda_hat may
      lie off of Q(lambda)'s true argmin (paper Eq. 5).
    - Reaching max iterations without convergence means the reported ATT
      is evaluated at a non-stationary point.

  Arguments
    loocv_n_valid      successful LOOCV fits
    loocv_n_attempted  attempted LOOCV fits
    converged          convergence flag (1 = converged, 0 = not)
    n_iterations       final iteration count
──────────────────────────────────────────────────────────────────────────────*/

void _trop_display_conv_diagnostics(
    real scalar loocv_n_valid,
    real scalar loocv_n_attempted,
    real scalar converged,
    real scalar n_iterations
)
{
    real scalar fail_rate

    /* ── LOOCV failure rate check (threshold: 10%) ────────────────────── */
    fail_rate = .
    if (loocv_n_attempted < . & loocv_n_attempted > 0 &
        loocv_n_valid < .) {
        fail_rate = (loocv_n_attempted - loocv_n_valid) / loocv_n_attempted
    }

    if (fail_rate < . & fail_rate > 0.10) {
        displayas("err")
        printf("{err}Warning: LOOCV convergence rate is low (%.1f%% of grid points failed){txt}\n",
               fail_rate * 100)
        displayas("txt")
        printf("  Suggestions:\n")
        printf("    1) Try grid_style(extended) to widen the lambda search range\n")
        printf("    2) Check data for extreme outliers or collinearity\n")
        printf("    3) Consider increasing tol() to relax convergence tolerance\n")
    }

    /* ── Max-iteration-reached check ──────────────────────────────────── */
    if (converged < . & converged == 0 &
        n_iterations < . & n_iterations > 0) {
        displayas("err")
        printf("{err}Warning: Estimation reached the maximum iteration limit (%g){txt}\n",
               n_iterations)
        displayas("txt")
        printf("  Suggestions:\n")
        printf("    1) Increase maxiter() option (current limit: %g)\n",
               n_iterations)
        printf("    2) Relax convergence tolerance with tol()\n")
        printf("    3) Check data conditioning; near-collinear panels slow convergence\n")
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_display_unconverged_obs()

  List the first few unconverged (t, i) cells using the per-obs diagnostics
  that the twostep plugin emits.  Helps the user target maxiter() bumps or
  inspect specific panel cells after a non-convergence warning.

  The indices are 1-based Stata-style panel-unit / time-period positions
  derived from the ordering in which the plugin enumerated treated cells
  (for t in 1..T { for i in 1..N { if D[t,i]=1 ... } }).  To recover the
  original panel IDs, the user can cross-reference e(panelvar) and
  e(timevar) with the estimation sample.
──────────────────────────────────────────────────────────────────────────────*/

void _trop_display_unconverged_obs(real scalar n_iterations)
{
    real colvector converged_vec
    real matrix    tau_mat
    real scalar    k, n_tot, n_unconv, n_to_show, shown

    tau_mat = st_matrix("__trop_tau")
    converged_vec = st_matrix("__trop_converged_by_obs")
    if (rows(converged_vec) == 0) return

    n_tot = rows(converged_vec)
    n_unconv = 0
    for (k = 1; k <= n_tot; k++) {
        if (converged_vec[k] == 0) n_unconv++
    }
    if (n_unconv == 0) return

    printf("{res}         %g of %g treated cells reached maxiter=%g without converging.{txt}\n",
           n_unconv, n_tot, n_iterations)

    n_to_show = min((n_unconv, 5))
    if (n_to_show < n_unconv) {
        printf("{res}         First %g unconverged cells (tau reported; index = row in e(tau)):{txt}\n",
               n_to_show)
    }
    else {
        printf("{res}         Unconverged cells (tau reported; index = row in e(tau)):{txt}\n")
    }
    shown = 0
    for (k = 1; k <= n_tot & shown < n_to_show; k++) {
        if (converged_vec[k] == 0) {
            if (rows(tau_mat) >= k) {
                printf("{res}           #%g: tau = %12.6f{txt}\n", k, tau_mat[k, 1])
            }
            else {
                printf("{res}           #%g{txt}\n", k)
            }
            shown++
        }
    }
    printf("{res}         See e(converged_by_obs) and e(n_iters_by_obs) for the full pattern.{txt}\n")
    printf("{res}         Consider increasing maxiter() (default 500) or adjusting lambda_nn.{txt}\n")
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_compute_effective_rank()

  Computes the continuous effective rank of a matrix via SVD:

      effective_rank = sum(s) / s[1]

  where s is the vector of singular values.  This measures the degree
  to which the low-rank component mu concentrates on a small number of
  factors.

  Arguments
    L   real matrix (T x N factor matrix)

  Returns
    real scalar   effective rank, 0 for empty/zero matrices, . on failure
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_compute_effective_rank(real matrix L)
{
    real matrix Lcopy, Vt
    real colvector s
    real scalar s_sum, min_dim, rc, r, c

    if (rows(L) == 0 || cols(L) == 0) return(0)

    min_dim = min((rows(L), cols(L)))
    if (min_dim < 1) return(0)

    Lcopy = L

    /* Replace missing values with zero (SVD requires finite entries) */
    for (r = 1; r <= rows(Lcopy); r++) {
        for (c = 1; c <= cols(Lcopy); c++) {
            if (Lcopy[r, c] >= .) {
                Lcopy[r, c] = 0
            }
        }
    }

    if (max(abs(Lcopy)) == 0) return(0)

    /* _svd() requires rows >= cols; transpose if necessary */
    if (rows(Lcopy) < cols(Lcopy)) {
        Lcopy = Lcopy'
    }
    _svd(Lcopy, s, Vt)
    if (length(s) == 0 || hasmissing(s)) return(.)

    if (length(s) == 0) return(0)
    if (s[1] <= 0) return(0)

    s_sum = sum(s)
    return(s_sum / s[1])
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_display_bootstrap_warnings()

  Emits warnings or errors based on the bootstrap failure rate:
    > 50%   error message and deferred fatal exit flag
    >  5%   warning that standard errors may be less reliable

  The 5% warning threshold is tight enough that high-failure runs
  (e.g. 11 of 200 replicates) surface instead of passing silently.
  The 50% abort threshold is retained as a stronger user protection.

  Arguments
    n_valid   number of successful bootstrap replications
    n_total   total number of bootstrap replications attempted
──────────────────────────────────────────────────────────────────────────────*/

void _trop_display_bootstrap_warnings(
    real scalar n_valid,
    real scalar n_total
)
{
    real scalar failure_rate, lt, lu, ln
    real matrix temp
    string scalar ln_str

    if (n_total <= 0) return

    failure_rate = (n_total - n_valid) / n_total

    /* Selected lambda triple, rendered identically to the LOOCV failure
       message (paper Algorithm 3 steps 1--6 are evaluated at the winning
       lambda, so the user should see which triple the Standard-Error
       distribution was built around when failures surface).  +Inf is
       user-face represented as Stata missing; render as "+Inf". */
    lt = .
    lu = .
    ln = .
    temp = st_numscalar("e(lambda_time)")
    if (rows(temp) > 0) lt = temp
    temp = st_numscalar("e(lambda_unit)")
    if (rows(temp) > 0) lu = temp
    temp = st_numscalar("e(lambda_nn)")
    if (rows(temp) > 0) ln = temp
    ln_str = (ln >= . ? "+Inf" : strofreal(ln, "%10.4g"))

    if (failure_rate > 0.50) {
        errprintf("Error: Bootstrap failure rate exceeds 50%% (%5.1f%%)\n", failure_rate * 100)
        errprintf("       %g of %g bootstrap iterations failed.\n",
                  n_total - n_valid, n_total)
        if (lt < . & lu < .) {
            errprintf(
                "       Selected lambda: (time=%10.4g, unit=%10.4g, nn=%s).\n",
                lt, lu, ln_str)
        }
        errprintf("       Check data quality or reduce bootstrap replications.\n")
        st_numscalar("__trop_fatal_rc", 504)
    }
    else if (failure_rate > 0.05) {
        printf("{res}Warning: Bootstrap failure rate is %5.1f%% (%g/%g successful){txt}\n",
               failure_rate * 100, n_valid, n_total)
        if (lt < . & lu < .) {
            printf(
                "{txt}         Selected lambda: (time={res}%10.4g{txt}, unit={res}%10.4g{txt}, nn={res}%s{txt}).\n",
                lt, lu, ln_str)
        }
        printf("{res}         Standard errors may be less reliable.{txt}\n")
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_store_lambda_grids()

  Constructs e(lambda_grid) and e(cv_curve) from the individual
  per-dimension lambda grids produced during LOOCV.

  TROP uses cycling (coordinate descent) LOOCV, which does not evaluate
  the full Cartesian product of the grid.  Consequently, e(cv_curve)
  records the LOOCV score Q(lambda_hat) only at the row closest to the
  selected optimal lambdas; all other rows have missing CV loss.

  Arguments
    opt_time    selected lambda_time
    opt_unit    selected lambda_unit
    opt_nn      selected lambda_nn
    opt_score   LOOCV score at the optimum
──────────────────────────────────────────────────────────────────────────────*/

void _trop_store_lambda_grids(
    real scalar opt_time,
    real scalar opt_unit,
    real scalar opt_nn,
    real scalar opt_score
)
{
    real matrix lt_grid, lu_grid, ln_grid
    real scalar n_lt, n_lu, n_ln, n_combo
    real matrix lambda_grid, cv_curve
    real scalar idx, ilt, ilu, iln
    real scalar best_dist, dist, best_row

    lt_grid = st_matrix("__trop_lambda_time_grid")
    lu_grid = st_matrix("__trop_lambda_unit_grid")
    ln_grid = st_matrix("__trop_lambda_nn_grid")

    if (rows(lt_grid) == 0 || rows(lu_grid) == 0 || rows(ln_grid) == 0) {
        return
    }

    n_lt = cols(lt_grid)
    n_lu = cols(lu_grid)
    n_ln = cols(ln_grid)

    /* Cartesian product: e(lambda_grid) is N_combo x 3 */
    n_combo = n_lt * n_lu * n_ln
    lambda_grid = J(n_combo, 3, .)
    cv_curve = J(n_combo, 4, .)

    idx = 0
    for (ilt = 1; ilt <= n_lt; ilt++) {
        for (ilu = 1; ilu <= n_lu; ilu++) {
            for (iln = 1; iln <= n_ln; iln++) {
                idx++
                lambda_grid[idx, 1] = lt_grid[1, ilt]
                lambda_grid[idx, 2] = lu_grid[1, ilu]
                lambda_grid[idx, 3] = ln_grid[1, iln]
                cv_curve[idx, 1] = lt_grid[1, ilt]
                cv_curve[idx, 2] = lu_grid[1, ilu]
                cv_curve[idx, 3] = ln_grid[1, iln]
            }
        }
    }

    /* Locate the grid row closest to the optimal lambdas.

       lambda_grid[, 3] is stored verbatim from __trop_lambda_nn_grid, which
       preserves Stata missing (.) for the DID/TWFE corner (lambda_nn =
       +inf).  opt_nn, on the other hand, has already been round-tripped
       through the C bridge, so a winning +inf entry arrives here as 1e10.

       A naive `(grid_nn - opt_nn)^2` would evaluate to missing whenever
       grid_nn == . (Stata arithmetic with missing propagates missing),
       which in turn is never `< best_dist` and the +inf row can therefore
       never pin as best_row.  We sidestep this by lifting both sides to
       the common internal-space representation (. -> 1e10) before the
       squared distance, so the +inf row can match opt_nn == 1e10 with
       distance zero. */
    real scalar opt_nn_internal, grid_nn_internal, diff_nn
    opt_nn_internal = (opt_nn >= . ? _TROP_LAMBDA_NN_INF_VALUE() : opt_nn)
    best_dist = 1e100
    best_row = 1
    for (idx = 1; idx <= n_combo; idx++) {
        grid_nn_internal = (lambda_grid[idx, 3] >= . ? _TROP_LAMBDA_NN_INF_VALUE() : lambda_grid[idx, 3])
        diff_nn = grid_nn_internal - opt_nn_internal
        dist = (lambda_grid[idx, 1] - opt_time)^2 +
               (lambda_grid[idx, 2] - opt_unit)^2 +
               diff_nn * diff_nn
        if (dist < best_dist) {
            best_dist = dist
            best_row = idx
        }
    }
    cv_curve[best_row, 4] = opt_score

    st_matrix("e(lambda_grid)", lambda_grid)
    st_matrix("e(cv_curve)", cv_curve)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_build_tau_matrix()

  Assemble a T x N matrix of treatment effects, mirroring the structure of
  the panel.  Non-treated cells are filled with Stata missing (.).

  Inputs
    - global __trop_touse_var       touse (estimation-sample marker)
    - global __trop_treatvar        treatment indicator W_{it}
    - global __trop_panel_idx_var   consecutive panel index 1..N
    - global __trop_time_idx_var    consecutive time index 1..T
    - stata matrix __trop_tau       N_treated x 1 (time-major)

  Arguments
    T   number of time periods
    N   number of panel units

  Output
    e(tau_matrix)   T x N real matrix; tau_{t,i} for treated cells, missing
                    elsewhere; empty when required inputs are missing.
──────────────────────────────────────────────────────────────────────────────*/

void _trop_build_tau_matrix(real scalar T, real scalar N)
{
    string scalar touse_var, treatvar, panel_var, time_var
    real matrix  tau_vec, obs_data, treated_info, tau_matrix
    real scalar  n_obs, k, n_treated_obs, n_filled, tau_k, row_t, col_i

    /* Plugin may not populate __trop_tau under every failure mode. */
    tau_vec = st_matrix("__trop_tau")
    if (rows(tau_vec) == 0) {
        return
    }
    n_treated_obs = rows(tau_vec)

    /* Require complete index metadata.  Silently skip when any piece is
       missing; keep e(tau) available so consumers still have access. */
    touse_var = st_global("__trop_touse_var")
    treatvar  = st_global("__trop_treatvar")
    panel_var = st_global("__trop_panel_idx_var")
    time_var  = st_global("__trop_time_idx_var")
    if (touse_var == "" || treatvar == "" ||
        panel_var == "" || time_var == "") {
        return
    }
    if (T <= 0 || T >= . || N <= 0 || N >= .) {
        return
    }
    /* Guard against tempvars that may have been dropped (e.g. when the
       touse variable was consumed by `ereturn post ... esample(var)`).
       If any key variable is missing from the dataset we cannot rebuild
       the (t, i) coordinates, so we bail out silently. */
    if (_st_varindex(touse_var) == . || _st_varindex(treatvar) == . ||
        _st_varindex(panel_var) == . || _st_varindex(time_var) == .) {
        return
    }

    /* Read (time, panel, treat) triplets for the estimation sample. */
    obs_data = st_data(., (time_var, panel_var, treatvar), touse_var)
    n_obs = rows(obs_data)
    if (n_obs == 0) {
        return
    }

    /* Keep only treated rows, then sort by (time, panel) to match the
       time-major ordering of tau_vec produced by the Rust backend. */
    treated_info = select(obs_data, obs_data[., 3] :!= 0)
    if (rows(treated_info) == 0) {
        return
    }
    if (rows(treated_info) != n_treated_obs) {
        /* Ordering mismatch is recoverable only when counts align.
           Log once (as a note) and fall back to leaving e(tau_matrix)
           unset so consumers detect the absence rather than reading
           silently mis-aligned values. */
        printf("{txt}(note: treated-cell count %g != e(tau) length %g; skipping e(tau_matrix) construction){txt}\n",
               rows(treated_info), n_treated_obs)
        return
    }
    treated_info = sort(treated_info, (1, 2))

    /* Fill the T x N grid. */
    tau_matrix = J(T, N, .)
    n_filled = 0
    for (k = 1; k <= n_treated_obs; k++) {
        row_t = treated_info[k, 1]
        col_i = treated_info[k, 2]
        if (row_t >= 1 && row_t <= T && col_i >= 1 && col_i <= N) {
            tau_k = tau_vec[k, 1]
            if (tau_k < .) {
                tau_matrix[row_t, col_i] = tau_k
                n_filled++
            }
        }
    }

    if (n_filled > 0) {
        st_matrix("e(tau_matrix)", tau_matrix)
    }
}

end
