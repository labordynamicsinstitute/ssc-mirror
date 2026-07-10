/*──────────────────────────────────────────────────────────────────────────────
  trop_estat_helpers.mata

  Helper functions for estat subcommands: weight diagnostics and SVD
  analysis of the low-rank factor matrix.

  The TROP estimator assigns exponential-decay weights to both units and
  time periods.  These helpers quantify the effective concentration of
  those weights via Shannon entropy, Kish's effective sample size, and a
  top-k concentration index.  A separate routine performs SVD on the
  estimated factor matrix mu to report its effective rank, singular-value
  spectrum, and matrix norms (Frobenius and nuclear).

  Contents
    _compute_entropy()            Shannon entropy of a weight vector
    _compute_ess()                effective sample size (Kish, 1965)
    _compute_concentration()      top-k cumulative weight fraction
    compute_weight_stats()        aggregate weight diagnostics
    compute_bootstrap_stats()     bootstrap distribution summary
    _trop_estat_factors_svd()     SVD of the factor matrix
    _trop_interpolate_percentile() percentile via linear interpolation
──────────────────────────────────────────────────────────────────────────────*/

version 17
mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  _compute_entropy()

  Shannon entropy of a normalised weight vector:

      H(w) = -sum_{i: w_i > 0} w_i * ln(w_i)

  with the convention 0 * ln(0) = 0.

  Bounds:  H = ln(n) when w_i = 1/n for all i  (uniform);
           H = 0     when a single w_k = 1      (degenerate).

  Arguments
    w   N x 1 column vector with sum(w) = 1

  Returns
    real scalar in [0, ln(n)]
──────────────────────────────────────────────────────────────────────────────*/

real scalar _compute_entropy(real colvector w)
{
    real scalar entropy
    real colvector w_safe

    w_safe = w :+ (w :== 0)
    entropy = -sum(w :* ln(w_safe))

    return(entropy)
}

/*──────────────────────────────────────────────────────────────────────────────
  _compute_ess()

  Effective sample size (Kish, 1965) for a normalised weight vector:

      ESS = 1 / sum(w_i^2)     when sum(w) = 1

  Bounds:  ESS = n when w_i = 1/n  (uniform);
           ESS = 1 when a single w_k = 1  (degenerate).

  Arguments
    w   N x 1 column vector with sum(w) = 1

  Returns
    real scalar in [1, n]
──────────────────────────────────────────────────────────────────────────────*/

real scalar _compute_ess(real colvector w)
{
    real scalar ess, sum_w_squared

    sum_w_squared = sum(w :^ 2)

    if (sum_w_squared < 1e-16) {
        ess = 1
    }
    else {
        ess = 1 / sum_w_squared
    }

    return(ess)
}

/*──────────────────────────────────────────────────────────────────────────────
  _compute_concentration()

  Concentration index: the smallest fraction k/n of units whose
  cumulative weight (sorted descending) reaches at least 50%.

  Arguments
    w               N x 1 column vector with sum(w) = 1
    concentration   (output) scalar k/n
    top_k           (output) scalar k
──────────────────────────────────────────────────────────────────────────────*/

void _compute_concentration(real colvector w,
                            real scalar concentration,
                            real scalar top_k)
{
    real colvector w_sorted, cumsum_w
    real scalar n

    n = rows(w)

    w_sorted = sort(w, -1)
    cumsum_w = runningsum(w_sorted)

    top_k = sum(cumsum_w :< 0.5) + 1

    if (top_k < 1) top_k = 1
    if (top_k > n) top_k = n

    concentration = top_k / n
}

/*──────────────────────────────────────────────────────────────────────────────
  struct weight_stats

  Container for weight-vector diagnostics.
──────────────────────────────────────────────────────────────────────────────*/

struct weight_stats {
    real scalar n
    real scalar min_val
    real scalar max_val
    real scalar mean_val
    real scalar entropy
    real scalar ess
    real scalar concentration
    real scalar top_k
}

/*──────────────────────────────────────────────────────────────────────────────
  compute_weight_stats()

  Computes descriptive statistics, Shannon entropy, effective sample size,
  and concentration index for a weight vector.

  Arguments
    w      N x 1 weight vector (normalised)
    type   string label ("time" or "unit")

  Returns
    struct weight_stats
──────────────────────────────────────────────────────────────────────────────*/

struct weight_stats scalar compute_weight_stats(real colvector w,
                                                string scalar type)
{
    struct weight_stats scalar stats
    real scalar concentration_val, top_k_val

    stats.n = rows(w)
    stats.min_val = min(w)
    stats.max_val = max(w)
    stats.mean_val = mean(w)

    stats.entropy = _compute_entropy(w)
    stats.ess = _compute_ess(w)

    _compute_concentration(w, concentration_val, top_k_val)
    stats.concentration = concentration_val
    stats.top_k = top_k_val

    return(stats)
}

/*──────────────────────────────────────────────────────────────────────────────
  struct bootstrap_stats

  Container for bootstrap distribution summary statistics.
──────────────────────────────────────────────────────────────────────────────*/

struct bootstrap_stats {
    real scalar mean_val
    real scalar sd
    real scalar skewness
    real scalar kurtosis
    real scalar min_val
    real scalar max_val
    real scalar n_converged
    string scalar skew_label
    string scalar kurt_label
}

/*──────────────────────────────────────────────────────────────────────────────
  compute_bootstrap_stats()

  Distributional diagnostics of bootstrap ATT estimates: mean, standard
  deviation, skewness, and kurtosis.

      skewness = E[(X - mu)^3] / sigma^3
      kurtosis = E[(X - mu)^4] / sigma^4

  Missing values (from non-converged iterations) are excluded.

  Arguments
    att_boot    B x 1 vector of bootstrap ATT estimates
    converged   optional B x 1 convergence indicator

  Returns
    struct bootstrap_stats
──────────────────────────────────────────────────────────────────────────────*/

struct bootstrap_stats scalar compute_bootstrap_stats(
    real colvector att_boot,
    | real colvector converged
)
{
    struct bootstrap_stats scalar stats
    real colvector z, att_valid
    real scalar has_converged, n_total

    has_converged = (args() >= 2 && rows(converged) > 0)

    n_total = rows(att_boot)
    att_valid = select(att_boot, att_boot :< .)

    stats.mean_val = mean(att_valid)
    stats.sd = sqrt(variance(att_valid))
    stats.min_val = min(att_valid)
    stats.max_val = max(att_valid)

    if (has_converged) {
        stats.n_converged = sum(converged)
    }
    else {
        stats.n_converged = rows(att_valid)
    }

    if (stats.sd > 0) {
        z = (att_valid :- stats.mean_val) / stats.sd
        stats.skewness = mean(z :^ 3)
        stats.kurtosis = mean(z :^ 4)
    }
    else {
        stats.skewness = 0
        stats.kurtosis = .
    }

    if (abs(stats.skewness) < 0.5) {
        stats.skew_label = "(approximately symmetric)"
    }
    else if (stats.skewness > 0) {
        stats.skew_label = "(right-skewed)"
    }
    else {
        stats.skew_label = "(left-skewed)"
    }

    if (stats.kurtosis >= .) {
        stats.kurt_label = "(degenerate: all estimates identical)"
    }
    else if (stats.kurtosis >= 2.5 && stats.kurtosis <= 3.5) {
        stats.kurt_label = "(approximately normal)"
    }
    else if (stats.kurtosis > 3.5) {
        stats.kurt_label = "(heavy-tailed)"
    }
    else {
        stats.kurt_label = "(light-tailed)"
    }

    return(stats)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_estat_factors_svd()

  Singular value decomposition of a factor matrix stored in e().

  Displays: singular values, variance explained, matrix norms, and
  element-level statistics.

      L = U * diag(sigma) * V'
      variance share:   sigma_i^2 / sum(sigma^2)
      Frobenius norm:   ||L||_F = sqrt(sum(sigma^2))
      nuclear norm:     ||L||_* = sum(sigma_i)

  The nuclear norm is the penalty term in the TROP objective; its
  magnitude relative to the Frobenius norm indicates how much
  regularisation is active.

  If the matrix is numerically zero, abbreviated output is printed.
  When e(effective_rank) is unavailable, the continuous effective rank
  sum(sigma) / sigma_1 is computed as a fallback.

  Arguments
    matname   name of a Stata matrix stored in e()
──────────────────────────────────────────────────────────────────────────────*/

void _trop_estat_factors_svd(string scalar matname)
{
    real matrix L, L_work, Vt
    real vector s
    real scalar i, total_var, tol, n_sv, effective_rank
    real scalar frob_norm, nuclear_norm, max_abs, min_abs
    real scalar T, N, transposed

    L = st_matrix(matname)
    T = rows(L)
    N = cols(L)

    frob_norm = sqrt(sum(L:^2))
    if (frob_norm < 1e-30) {
        printf("{txt}Singular value decomposition:\n")
        printf("{txt}  Effective rank  = {res}%8.2f\n", 0)
        printf("{txt}  Top singular values:\n")
        printf("{txt}  (factor matrix is effectively zero, no variance to decompose)\n")
        printf("\n{txt}Matrix norms:\n")
        printf("{txt}  ||L||_F (Frobenius) = {res}%10.3f\n", frob_norm)
        printf("{txt}  ||L||_* (Nuclear)   = {res}%10.3f\n", 0)
        printf("\n{txt}Element statistics:\n")
        printf("{txt}  max|L_it|           = {res}%10.3f\n", max(abs(L)))
        printf("{txt}  min|L_it|           = {res}%10.3f\n", min(abs(L)))
        return
    }

    /* _svd() requires rows >= cols; transpose if needed */
    transposed = 0
    if (T < N) {
        L_work = L'
        transposed = 1
    }
    else {
        L_work = L
    }

    s = J(0, 1, .)
    Vt = J(0, 0, .)
    _svd(L_work, s, Vt)
    if (length(s) == 0 || hasmissing(s)) {
        printf("{err}SVD decomposition failed. Factor matrix may be degenerate.{txt}\n")
        return
    }

    tol = 1e-10
    total_var = sum(s:^2)
    n_sv = length(s)

    /* Retrieve stored effective rank; fall back to sum(sigma)/sigma_1 */
    effective_rank = .
    if (length(st_numscalar("e(effective_rank)")) == 1) {
        effective_rank = st_numscalar("e(effective_rank)")
    }
    if (effective_rank >= . | effective_rank == .) {
        if (length(s) > 0 && s[1] > 0) {
            effective_rank = sum(s) / s[1]
        }
        else {
            effective_rank = 0
        }
    }

    printf("{txt}Singular value decomposition:\n")
    printf("{txt}  Effective rank  = {res}%8.2f\n", effective_rank)
    printf("{txt}  Top singular values:\n")

    for (i = 1; i <= min((5, n_sv)); i++) {
        if (s[i] < tol) {
            printf("{txt}    σ%g = {res}%9.3f{txt} (< tol, effectively zero)\n",
                   i, s[i])
        }
        else {
            printf("{txt}    σ%g = {res}%9.3f{txt} (explains {res}%5.1f%%{txt} variance)\n",
                   i, s[i], 100 * s[i]^2 / total_var)
        }
    }

    nuclear_norm = sum(s)

    printf("\n{txt}Matrix norms:\n")
    printf("{txt}  ||L||_F (Frobenius) = {res}%10.3f\n", frob_norm)
    printf("{txt}  ||L||_* (Nuclear)   = {res}%10.3f\n", nuclear_norm)

    max_abs = max(abs(L))
    min_abs = min(abs(L))

    printf("\n{txt}Element statistics:\n")
    printf("{txt}  max|L_it|           = {res}%10.3f\n", max_abs)
    printf("{txt}  min|L_it|           = {res}%10.3f\n", min_abs)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_estat_triplerob()

  Triple-robustness bias decomposition (paper Theorem 5.1).  The bias bound
  factorises into a product of three terms:

      | E[ tauhat - tau | L ] |
          <=  | Delta^u( omega, Gamma ) |_2
            * | Delta^t( theta, Lambda ) |_2
            * | B |_*

  where Gamma (N × k) and Lambda (T × k) are the rank-k SVD loadings /
  factors of the estimated L, and Delta^u, Delta^t are the unit- and
  time-weight imbalances evaluated at each treated cell against the target.

  Joint method:   delta_unit / delta_time are global (paper Remark 6.1).
                  The imbalance is averaged over all treated cells using
                  the tau_matrix stored in e().
  Twostep method: theta / omega in e() are the weights for the FIRST
                  treated cell only; the decomposition is therefore shown
                  for that cell alone.  The aggregate is a conservative
                  upper bound for any single treated effect.

  For the third term the "discarded nuclear mass" is reported both as
  `sigma_{k+1}` (the largest truncated singular value) and as the
  fraction `sum(sigma_{k+1:end}) / sum(sigma)`.  Both are zero when the
  factor matrix is exactly rank k, and rise monotonically with truncation
  error.

  The full bias bound in Theorem 5.1 additionally carries a constant
  factor from the weight normalisation; this diagnostic reports the
  un-normalised product as a comparative scale only.  The message text
  is anchored to paper Eq.  13 and Theorem 5.1.

  Scratch scalars written to Stata namespace:
      __trop_tr_du      unit-imbalance term  | Delta^u |_2
      __trop_tr_dt      time-imbalance term  | Delta^t |_2
      __trop_tr_res     rank-k residual      | B |_*  proxy
      __trop_tr_bound   product of the three
──────────────────────────────────────────────────────────────────────────────*/

void _trop_estat_triplerob(
    string scalar method,
    real scalar rank_request,
    real scalar topk)
{
    real matrix L, U, Vt, tau_mat, treated_info, gamma_k, lambda_k
    real matrix weights_time, weights_unit
    real colvector s
    real scalar T, N, r, k, transposed, rank_used, i, j
    real scalar n_treated_cells, du_sum, dt_sum, du_k, dt_k
    real scalar d_unit_mag, d_time_mag, nuclear_k, nuclear_tot, residual_mass
    real scalar se_boot, product_bound, sig_kp1
    real scalar t_cell, i_cell
    string scalar method_label

    L = st_matrix("e(factor_matrix)")
    T = rows(L)
    N = cols(L)

    if (T == 0 || N == 0) {
        printf("{err}factor matrix is empty; triplerob cannot run{txt}\n")
        _trop_triplerob_stash(., ., ., .)
        return
    }

    /* _svd() requires rows >= cols.  Track the transpose so that U/Vt can
       be interpreted as (time-factors, unit-loadings) afterwards. */
    transposed = 0
    if (T < N) {
        U = L'
        transposed = 1
    }
    else {
        U = L
    }
    s = J(0, 1, .)
    Vt = J(0, 0, .)
    _svd(U, s, Vt)
    if (length(s) == 0 || hasmissing(s)) {
        printf("{err}SVD of factor matrix failed; triplerob cannot run{txt}\n")
        _trop_triplerob_stash(., ., ., .)
        return
    }

    r = length(s)

    /* After _svd with rows >= cols:
         L_work = U[:, 1..r] * diag(s) * Vt[1..r, :]
       where U has dim (rows-of-L_work × r) and Vt has dim (r × cols-of-L_work).
       If we transposed above, time is on cols and units are on rows of L_work,
       so we swap the roles back out.
    */
    if (transposed) {
        /* L_work = L' = U * diag(s) * Vt  =>
           L = Vt' * diag(s) * U'
           Time factor (rows of L)   = Vt'[:, 1..r]       (T × r)
           Unit loading (cols of L) = U[:, 1..r]          (N × r)
        */
        lambda_k = Vt'
        gamma_k  = U
    }
    else {
        /* L = U * diag(s) * Vt
           Time factor (rows of L)   = U[:, 1..r]          (T × r)
           Unit loading (cols of L) = Vt'[:, 1..r]         (N × r)
        */
        lambda_k = U
        gamma_k  = Vt'
    }

    rank_used = min((max((1, rank_request)), r))
    k = rank_used

    /* Truncate to rank k. */
    if (k < cols(gamma_k)) gamma_k  = gamma_k[ ., 1..k]
    if (k < cols(lambda_k)) lambda_k = lambda_k[., 1..k]

    /* Residual nuclear mass from truncation. */
    nuclear_tot = sum(s)
    nuclear_k   = sum(s[1..k])
    residual_mass = nuclear_tot - nuclear_k
    if (k < r) {
        sig_kp1 = s[k + 1]
    }
    else {
        sig_kp1 = 0
    }

    /* Fetch the treatment layout and weight vectors.  Joint uses global
       delta_*, twostep uses the first-treated-cell theta/omega. */
    method_label = strlower(method)
    if (method_label == "joint" || method_label == "global") {
        weights_time = _trop_vec_or_missing("e(delta_time)", T)
        weights_unit = _trop_vec_or_missing("e(delta_unit)", N)
    }
    else {
        weights_time = _trop_vec_or_missing("e(theta)", T)
        weights_unit = _trop_vec_or_missing("e(omega)", N)
    }

    if (hasmissing(weights_time) || hasmissing(weights_unit)) {
        printf("{err}weight vectors not available in e(); triplerob cannot run{txt}\n")
        printf("{err}  expected e(theta)/e(omega) (twostep) or " +
               "e(delta_time)/e(delta_unit) (joint){txt}\n")
        _trop_triplerob_stash(., ., ., .)
        return
    }

    /* Normalise weight vectors so they sum to 1 (paper Eq. 3 does not
       require this but the imbalance terms are scale-equivariant and
       normalising makes the diagnostic interpretable). */
    if (sum(weights_time) > 0) weights_time = weights_time / sum(weights_time)
    if (sum(weights_unit) > 0) weights_unit = weights_unit / sum(weights_unit)

    /* Determine treated cells.  tau_matrix has tau_{it} on treated cells
       and missing elsewhere.  If it is not available, fall back to the
       first treated cell implied by e(N_treated_obs) > 0. */
    tau_mat = _trop_safe_tau_matrix()
    treated_info = _trop_treated_coords(tau_mat)
    n_treated_cells = rows(treated_info)

    if (n_treated_cells == 0) {
        /* Fallback: evaluate imbalance against the first treated cell that
           estat weights would use (unit i=1, time t=T).  This is only
           reached in degenerate configurations. */
        treated_info = (T, 1)
        n_treated_cells = 1
    }

    /* Accumulate |Delta^u|_2 and |Delta^t|_2 over treated cells.
       Delta^u(i) = Σ_j omega_j Γ_j - Γ_i                (k-vector)
       Delta^t(t) = Σ_s theta_s Λ_s - Λ_t                (k-vector)
       Product term in paper Theorem 5.1 averages these over treated
       cells; we report both mean and max for robustness. */
    du_sum = 0
    dt_sum = 0
    du_k   = 0
    dt_k   = 0
    for (i = 1; i <= n_treated_cells; i++) {
        t_cell = treated_info[i, 1]
        i_cell = treated_info[i, 2]
        if (t_cell < 1 || t_cell > T || i_cell < 1 || i_cell > N) continue

        /* Δ^u(i_cell) */
        d_unit_mag = norm(weights_unit' * gamma_k  - gamma_k[i_cell, .], 2)
        /* Δ^t(t_cell) */
        d_time_mag = norm(weights_time' * lambda_k - lambda_k[t_cell, .], 2)

        du_sum = du_sum + d_unit_mag
        dt_sum = dt_sum + d_time_mag
        if (d_unit_mag > du_k) du_k = d_unit_mag
        if (d_time_mag > dt_k) dt_k = d_time_mag
    }
    /* Means over treated cells. */
    du_sum = du_sum / n_treated_cells
    dt_sum = dt_sum / n_treated_cells

    product_bound = du_sum * dt_sum * residual_mass

    se_boot = _trop_safe_read_scalar("e(se)")

    /* ── Print formatted report ─────────────────────────────────────── */
    printf("\n{txt}Triple-robustness bias decomposition (paper Theorem 5.1)\n")
    printf("{hline 61}\n")
    printf("{txt}Method          = {res}%s\n",
           (method_label == "joint" || method_label == "global") ? "joint (global weights)" : "twostep (per-obs weights)")
    printf("{txt}Dimensions      = T = {res}%g{txt},  N = {res}%g\n", T, N)
    printf("{txt}SVD rank r      = {res}%g{txt}   truncation k = {res}%g\n", r, k)
    printf("{txt}Treated cells   = {res}%g\n", n_treated_cells)
    printf("{txt}Singular values (top %g):\n", min((topk, r)))
    for (j = 1; j <= min((topk, r)); j++) {
        printf("{txt}  sigma_%g       = {res}%10.4f\n", j, s[j])
    }
    printf("\n{txt}Component 1: Unit imbalance  |Delta^u(omega, Gamma)|_2\n")
    printf("{txt}  mean over treated cells   = {res}%10.6f\n", du_sum)
    printf("{txt}  max  over treated cells   = {res}%10.6f\n", du_k)
    printf("\n{txt}Component 2: Time imbalance  |Delta^t(theta, Lambda)|_2\n")
    printf("{txt}  mean over treated cells   = {res}%10.6f\n", dt_sum)
    printf("{txt}  max  over treated cells   = {res}%10.6f\n", dt_k)
    printf("\n{txt}Component 3: Rank-k residual  |B|_*\n")
    printf("{txt}  sigma_{k+1}               = {res}%10.6f\n", sig_kp1)
    printf("{txt}  discarded nuclear mass    = {res}%10.6f\n", residual_mass)
    if (nuclear_tot > 0) {
        printf("{txt}  discarded fraction        = {res}%10.4f\n",
               residual_mass / nuclear_tot)
    }
    printf("\n{txt}Product bound (Theorem 5.1)\n")
    printf("{txt}  Delta^u * Delta^t * |B|_* = {res}%10.6f\n", product_bound)
    if (se_boot < .) {
        printf("{txt}  Observed bootstrap SE     = {res}%10.6f\n", se_boot)
        if (product_bound > 0) {
            printf("{txt}  ratio (bound / SE)        = {res}%10.4f\n",
                   product_bound / se_boot)
        }
    }
    else {
        printf("{txt}  Observed bootstrap SE     = (not computed; use bootstrap())\n")
    }
    printf("{hline 61}\n")
    printf("{txt}Interpretation: the product bound is a diagnostic proxy; " +
           "a value much smaller than the bootstrap SE suggests the triple-" +
           "robustness guarantee is well satisfied and residual bias is " +
           "negligible relative to sampling variability.\n")

    /* Degenerate-L warning: when L is numerically zero (lambda_nn = +Inf
       or perfectly separable two-way fixed effects), the SVD loadings
       Gamma = Vt' and Lambda = U are mathematically arbitrary — every
       orthogonal basis satisfies L = U * 0 * Vt.  LAPACK picks *a*
       basis, and that basis can differ across BLAS backends (Accelerate
       / OpenBLAS / MKL).  The resulting |Delta^u|_2 / |Delta^t|_2
       values reported above are therefore basis-dependent and may
       fluctuate across platforms.  The product bound itself is
       platform-invariant: it is ||B||_* = 0 times anything = 0. */
    if (nuclear_tot < 1e-30) {
        printf("\n{txt}Note: L is numerically zero (||L||_* = {res}%10.2e{txt}),\n",
               nuclear_tot)
        printf("{txt}      e.g. when {res}lambda_nn = +Inf{txt} or the alpha+beta fit\n")
        printf("{txt}      absorbs every signal.  The SVD loadings Gamma / Lambda\n")
        printf("{txt}      are then mathematically arbitrary (any orthogonal basis\n")
        printf("{txt}      satisfies L = U*0*V'), so the |Delta^u|_2 / |Delta^t|_2\n")
        printf("{txt}      numbers above may differ across BLAS backends.  The\n")
        printf("{txt}      product bound ({res}0{txt}) is platform-invariant.\n")
    }

    /* Stash scratch scalars for the ado caller. */
    _trop_triplerob_stash(du_sum, dt_sum, residual_mass, product_bound)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_vec_or_missing()

  Read a vector (row or column) from Stata matrix `name`; if the matrix is
  absent or of the wrong length, return a vector of `expected_len` missing
  values.  The caller uses `hasmissing()` to detect "unavailable".
──────────────────────────────────────────────────────────────────────────────*/
real colvector _trop_vec_or_missing(string scalar name, real scalar expected_len)
{
    real matrix M
    real colvector v

    M = st_matrix(name)
    if (rows(M) == 0 && cols(M) == 0) {
        return(J(expected_len, 1, .))
    }
    if (rows(M) == 1 && cols(M) >= 1) {
        v = M'
    }
    else {
        v = M[., 1]
    }
    if (rows(v) != expected_len) {
        return(J(expected_len, 1, .))
    }
    return(v)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_safe_tau_matrix()

  Read e(tau_matrix) (T × N, missing where untreated) if available; else
  return an empty matrix.  Consumers should test rows() == 0.
──────────────────────────────────────────────────────────────────────────────*/
real matrix _trop_safe_tau_matrix()
{
    real matrix M
    M = st_matrix("e(tau_matrix)")
    return(M)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_treated_coords()

  Given a T × N tau_matrix with non-missing entries on treated cells,
  return an n_treated × 2 matrix with columns (t, i).  Empty matrix when
  tau_matrix is absent.
──────────────────────────────────────────────────────────────────────────────*/
real matrix _trop_treated_coords(real matrix tau_mat)
{
    real scalar T, N, t, i, k, n
    real matrix out

    T = rows(tau_mat)
    N = cols(tau_mat)
    if (T == 0 || N == 0) return(J(0, 2, .))

    /* Count first to allocate once. */
    n = 0
    for (t = 1; t <= T; t++) {
        for (i = 1; i <= N; i++) {
            if (tau_mat[t, i] < .) n++
        }
    }
    if (n == 0) return(J(0, 2, .))

    out = J(n, 2, .)
    k = 0
    for (t = 1; t <= T; t++) {
        for (i = 1; i <= N; i++) {
            if (tau_mat[t, i] < .) {
                k = k + 1
                out[k, 1] = t
                out[k, 2] = i
            }
        }
    }
    return(out)
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_interpolate_percentile()

  Calculates the p-th percentile of a sorted vector using linear interpolation.
  Index calculation: (n-1)*p.

  Arguments
    sorted_v   Sorted column vector
    p          Percentile (0 to 1)

  Returns
    Interpolated value
──────────────────────────────────────────────────────────────────────────────*/

real scalar _trop_interpolate_percentile(real colvector sorted_v, real scalar p)
{
    real scalar n, idx_f, idx_low, idx_high, frac

    n = rows(sorted_v)
    if (n == 0) return(.)
    if (n == 1) return(sorted_v[1])

    idx_f = (n - 1) * p
    idx_low = floor(idx_f)
    idx_high = ceil(idx_f)

    idx_low = max((0, min((n - 1, idx_low))))
    idx_high = max((0, min((n - 1, idx_high))))

    if (idx_low == idx_high) {
        return(sorted_v[idx_low + 1])
    }
    else {
        frac = idx_f - idx_low
        return(sorted_v[idx_low + 1] * (1 - frac) + sorted_v[idx_high + 1] * frac)
    }
}

/*──────────────────────────────────────────────────────────────────────────────
  _trop_triplerob_stash()

  Store the four summary scalars in the Stata scalar namespace so the
  ado caller can promote them to r().
──────────────────────────────────────────────────────────────────────────────*/
void _trop_triplerob_stash(
    real scalar du, real scalar dt, real scalar res, real scalar bound)
{
    st_numscalar("__trop_tr_du",    du)
    st_numscalar("__trop_tr_dt",    dt)
    st_numscalar("__trop_tr_res",   res)
    st_numscalar("__trop_tr_bound", bound)
}

end

mata:
mata set matastrict on

/*──────────────────────────────────────────────────────────────────────────────
  _trop_estat_distance_compute()

  Extracted from _trop_estat_distance.ado to avoid Stata 19 `mata: {}` block
  parsing incompatibility inside program define.
──────────────────────────────────────────────────────────────────────────────*/

void _trop_estat_distance_compute(real scalar n_units, real scalar n_periods,
    string scalar depvar, string scalar treatvar)
{
    real matrix _ed_Y, _ed_D, _ed_obs_data
    real scalar _ed_N, _ed_T, _ed_nobs, _ed_k
    real scalar _ed_row_t, _ed_col_i
    string scalar _ed_panel_idx_var, _ed_time_idx_var, _ed_touse_var

    _ed_N = n_units
    _ed_T = n_periods

    _ed_panel_idx_var = st_global("__trop_panel_idx_var")
    _ed_time_idx_var  = st_global("__trop_time_idx_var")
    _ed_touse_var     = ""

    if (_ed_panel_idx_var == "" | _ed_time_idx_var == "" | ///
        _st_varindex(_ed_panel_idx_var) >= . | ///
        _st_varindex(_ed_time_idx_var) >= .) {
        errprintf("Panel index variables not found in memory.\n")
        errprintf("Re-run trop estimation before using estat distance.\n")
        st_local("_ed_rc", "459")
    }
    else {
        st_local("_ed_rc", "0")

        _ed_obs_data = st_data(., ///
            (depvar, treatvar, _ed_panel_idx_var, _ed_time_idx_var), ///
            st_global("__trop_touse_var") != "" ? st_global("__trop_touse_var") : "")
        _ed_nobs = rows(_ed_obs_data)

        _ed_Y = J(_ed_T, _ed_N, .)
        _ed_D = J(_ed_T, _ed_N, 0)

        for (_ed_k = 1; _ed_k <= _ed_nobs; _ed_k++) {
            _ed_row_t = _ed_obs_data[_ed_k, 4]
            _ed_col_i = _ed_obs_data[_ed_k, 3]
            if (_ed_row_t >= 1 & _ed_row_t <= _ed_T & ///
                _ed_col_i >= 1 & _ed_col_i <= _ed_N) {
                _ed_Y[_ed_row_t, _ed_col_i] = _ed_obs_data[_ed_k, 1]
                _ed_D[_ed_row_t, _ed_col_i] = (_ed_obs_data[_ed_k, 2] != 0 ? 1 : 0)
            }
        }

        /* Compute pairwise distances */
        real matrix _ed_dist_mat
        real scalar _ed_i, _ed_j, _ed_t
        real scalar _ed_sum_sq, _ed_n_common
        real colvector _ed_valid_dist

        _ed_dist_mat = J(_ed_N, _ed_N, .)
        _ed_valid_dist = J(0, 1, .)

        for (_ed_i = 1; _ed_i <= _ed_N; _ed_i++) {
            _ed_dist_mat[_ed_i, _ed_i] = 0
            for (_ed_j = _ed_i + 1; _ed_j <= _ed_N; _ed_j++) {
                _ed_sum_sq = 0
                _ed_n_common = 0
                for (_ed_t = 1; _ed_t <= _ed_T; _ed_t++) {
                    if (_ed_D[_ed_t, _ed_i] == 0 & _ed_D[_ed_t, _ed_j] == 0 & ///
                        _ed_Y[_ed_t, _ed_i] < . & _ed_Y[_ed_t, _ed_j] < .) {
                        _ed_sum_sq = _ed_sum_sq + ///
                            (_ed_Y[_ed_t, _ed_i] - _ed_Y[_ed_t, _ed_j])^2
                        _ed_n_common++
                    }
                }
                if (_ed_n_common > 0) {
                    _ed_dist_mat[_ed_i, _ed_j] = sqrt(_ed_sum_sq / _ed_n_common)
                    _ed_dist_mat[_ed_j, _ed_i] = _ed_dist_mat[_ed_i, _ed_j]
                    _ed_valid_dist = _ed_valid_dist \ _ed_dist_mat[_ed_i, _ed_j]
                }
            }
        }

        st_matrix("__ed_dist_mat", _ed_dist_mat)
        if (rows(_ed_valid_dist) > 0) {
            st_numscalar("__ed_mean", mean(_ed_valid_dist))
            st_numscalar("__ed_sd", sqrt(variance(_ed_valid_dist)))
            st_numscalar("__ed_min", min(_ed_valid_dist))
            st_numscalar("__ed_max", max(_ed_valid_dist))
            st_numscalar("__ed_N_pairs", rows(_ed_valid_dist))

            real scalar _ed_p25_idx, _ed_p50_idx, _ed_p75_idx
            real colvector _ed_sorted
            _ed_sorted = sort(_ed_valid_dist, 1)
            _ed_p25_idx = max((1, ceil(0.25 * rows(_ed_sorted))))
            _ed_p50_idx = max((1, ceil(0.50 * rows(_ed_sorted))))
            _ed_p75_idx = max((1, ceil(0.75 * rows(_ed_sorted))))
            st_numscalar("__ed_p25", ///
                _ed_sorted[_ed_p25_idx])
            st_numscalar("__ed_p50", ///
                _ed_sorted[_ed_p50_idx])
            st_numscalar("__ed_p75", ///
                _ed_sorted[_ed_p75_idx])

            st_matrix("__ed_distances", _ed_valid_dist')
        }
        else {
            /* Zero valid pairs: set N_pairs = 0, others to missing */
            st_numscalar("__ed_N_pairs", 0)
            st_numscalar("__ed_mean", .)
            st_numscalar("__ed_sd", .)
            st_numscalar("__ed_min", .)
            st_numscalar("__ed_max", .)
            st_numscalar("__ed_p25", .)
            st_numscalar("__ed_p50", .)
            st_numscalar("__ed_p75", .)
        }
    }
}

end
