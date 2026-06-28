*! did_utils.mata - Core utility functions for DIDdesign
*!
*! This module serves as the foundational layer (Layer 1) of the DIDdesign Mata
*! library, providing essential utilities for the double difference-in-differences
*! (double DID) estimator and its extension to the staggered adoption (SA) design.
*! All other modules in the package depend upon this foundation.
*!
*! Functional groups:
*!   - Staggered adoption utilities: group indicator matrix (Gmat) construction,
*!     period and subject selection, and time weight computation for aggregating
*!     period-specific SA-ATT estimates
*!   - Statistical utilities: bootstrap variance-covariance estimation for GMM
*!     optimal weighting, robust matrix inversion, and quantile computation
*!   - Numerical utilities: safe arithmetic operations for edge case handling
*!   - Visualization utilities: treatment timing computation for pattern plots
*!   - Sampling utilities: random index generation for bootstrap resampling

version 16.0

mata:
mata set matastrict on

// -------------------------------------------------------------------------
// Staggered Adoption Design Utilities
// -------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * create_gmat() - Create Group Indicator Matrix for Staggered Adoption Design
 *
 * In the staggered adoption (SA) design, different units receive treatment at
 * different time periods. This function constructs an N_units × T group indicator
 * matrix encoding treatment timing:
 *
 *   G_{it} =  1   if A_i = t  (unit i first treated at time t)
 *   G_{it} =  0   if A_i > t  (unit i not yet treated by time t)
 *   G_{it} = -1   if A_i < t  (unit i already treated before time t)
 *
 * where A_i = min{t : D_{it} = 1} denotes the treatment adoption time.
 *
 * Arguments:
 *   id_subject : real colvector - unit identifiers (N × 1)
 *   id_time    : real colvector - time period indices (N × 1), values 1, 2, ..., T
 *   treatment  : real colvector - cumulative treatment indicator (N × 1), binary 0/1
 *
 * Returns:
 *   real matrix (N_units × T): group indicator matrix Gmat
 *
 * Algorithm:
 *   The treatment adoption time A_i follows the paper definition:
 *     A_i = min{t : D_{it} = 1}
 *   based on the observed treatment path for each unit. For never-treated
 *   units, A_i = T + 1 > T, so G_{it} = 0 for all t.
 *---------------------------------------------------------------------------*/
real matrix create_gmat(real colvector id_subject,
                        real colvector id_time,
                        real colvector treatment)
{
    real matrix Gmat
    real colvector units, idx, treat_i, time_i, treated_time_i
    real scalar N_units, T, N, i, t, g_sum
    
    N = rows(id_subject)
    if (N == 0 || rows(id_time) != N || rows(treatment) != N) {
        return(J(0, 0, .))
    }
    
    units = uniqrows(id_subject)
    N_units = rows(units)
    T = max(id_time)
    
    if (missing(T)) {
        errprintf("Error: Cannot determine time periods (all id_time values are missing)\n")
        return(J(0, 0, .))
    }
    if (T < 1) {
        errprintf("Error: Invalid time period range (max id_time = %g)\n", T)
        return(J(0, 0, .))
    }
    
    Gmat = J(N_units, T, 0)
    
    for (i = 1; i <= N_units; i++) {
        idx = selectindex(id_subject :== units[i])
        treat_i = treatment[idx]
        time_i = id_time[idx]

        treated_time_i = select(time_i, treat_i :== 1)
        if (rows(treated_time_i) == 0) {
            g_sum = T + 1
        }
        else {
            g_sum = min(treated_time_i)
        }

        for (t = 1; t <= T; t++) {
            if (g_sum > t) {
                Gmat[i, t] = 0
            }
            else if (g_sum == t) {
                Gmat[i, t] = 1
            }
            else {
                Gmat[i, t] = -1
            }
        }
    }
    
    return(Gmat)
}

/*---------------------------------------------------------------------------
 * get_periods() - Select Valid Time Periods for SA Design Analysis
 *
 * Time periods with sufficient treated units (>= threshold) are selected.
 * The edge case where all units are eventually treated (no control group) is handled.
 *
 * Arguments:
 *   Gmat  : real matrix (N_units × T) - group indicator matrix from create_gmat()
 *   thres : real scalar - minimum treated units threshold (default: 2)
 *
 * Returns:
 *   real colvector: indices of valid time periods (may be empty)
 *
 * Algorithm:
 *   1. Count treated units per period: n_treated[t] = Σ_i 1{G_{it} = 1}
 *   2. Select periods where n_treated >= threshold
 *   3. Edge case: if all units are treated within valid periods, the last
 *      period is removed to ensure at least one G=0 control unit exists
 *---------------------------------------------------------------------------*/
real colvector get_periods(real matrix Gmat, | real scalar thres)
{
    real colvector n_treated, use_id
    real scalar N, T, t, total_treated
    
    if (args() < 2 || missing(thres)) thres = 2
    if (thres < 1) thres = 1
    
    N = rows(Gmat)
    T = cols(Gmat)
    if (N == 0 || T == 0) {
        return(J(0, 1, .))
    }
    
    n_treated = J(T, 1, 0)
    for (t = 1; t <= T; t++) {
        n_treated[t] = sum(Gmat[, t] :== 1)
    }
    
    use_id = selectindex(n_treated :>= thres)
    
    if (rows(use_id) == 0) {
        return(J(0, 1, .))
    }
    
    // When all units are treated within valid periods, exclude last period
    // to ensure at least one control unit (G=0) exists
    total_treated = sum(n_treated[use_id])
    if (total_treated == N) {
        if (rows(use_id) > 1) {
            use_id = use_id[1..(rows(use_id) - 1)]
        }
        else {
            return(J(0, 1, .))
        }
    }
    
    return(use_id)
}

/*---------------------------------------------------------------------------
 * get_subjects() - Select Valid Subjects for Each Time Period
 *
 * For each valid time period, indices of units that are either treated at
 * that time (G = 1) or not yet treated (G = 0) are returned.
 * Units already treated in previous periods (G = -1) are excluded.
 *
 * Arguments:
 *   Gmat        : real matrix (N_units × T) - group indicator matrix
 *   id_time_use : real colvector - valid time period indices from get_periods()
 *
 * Returns:
 *   pointer vector (K × 1): each element points to a colvector of valid unit indices
 *
 * Algorithm:
 *   For each valid period t in id_time_use, find indices where G_{it} >= 0.
 *---------------------------------------------------------------------------*/
pointer vector get_subjects(real matrix Gmat, real colvector id_time_use)
{
    pointer vector id_use
    real colvector col
    real scalar K, T, i, t
    
    K = rows(id_time_use)
    if (K == 0) {
        return(J(0, 1, NULL))
    }
    
    T = cols(Gmat)
    id_use = J(K, 1, NULL)
    
    for (i = 1; i <= K; i++) {
        t = id_time_use[i]
        
        if (t < 1 | t > T | missing(t)) {
            errprintf("Error: id_time_use[%g] = %g is out of valid range [1, %g]\n", i, t, T)
            return(J(0, 1, NULL))
        }
        
        col = Gmat[, t]
        id_use[i] = &(selectindex(col :>= 0))
    }
    
    return(id_use)
}

/*---------------------------------------------------------------------------
 * get_time_weight() - Compute Time Weights for SA Design
 *
 * Weights proportional to the number of treated units at each period are computed.
 * These weights are used for aggregating period-specific treatment effects in SA design.
 *
 * Arguments:
 *   Gmat        : real matrix (N_units × T) - group indicator matrix
 *   id_time_use : real colvector - valid time period indices from get_periods()
 *
 * Returns:
 *   real colvector (K × 1): time weights summing to 1.0
 *
 * Formula:
 *   π_t = n_{1t} / Σ_{t' ∈ T_use} n_{1t'}
 *   where n_{1t} = Σ_i 1{A_i = t} = number of units treated at time t
 *
 * In the staggered adoption design, these weights aggregate period-specific
 * SA-ATT estimates into the time-average SA-ATT.
 *---------------------------------------------------------------------------*/
real colvector get_time_weight(real matrix Gmat, real colvector id_time_use)
{
    real colvector time_weight
    real scalar K, T, n_total, i, t, n_t
    
    K = rows(id_time_use)
    if (K == 0) {
        return(J(0, 1, .))
    }
    
    T = cols(Gmat)
    
    for (i = 1; i <= K; i++) {
        t = id_time_use[i]
        if (t < 1 | t > T | missing(t)) {
            errprintf("Error: id_time_use[%g] = %g is out of valid range [1, %g]\n", i, t, T)
            return(J(K, 1, .))
        }
    }
    
    n_total = 0
    for (i = 1; i <= K; i++) {
        t = id_time_use[i]
        n_total = n_total + sum(Gmat[, t] :== 1)
    }
    
    if (n_total == 0) {
        return(J(K, 1, .))
    }
    
    time_weight = J(K, 1, .)
    for (i = 1; i <= K; i++) {
        t = id_time_use[i]
        n_t = sum(Gmat[, t] :== 1)
        time_weight[i] = n_t / n_total
    }
    
    return(time_weight)
}

// -------------------------------------------------------------------------
// Statistical Utility Functions
// -------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * compute_vcov() - Compute Variance-Covariance Matrix from Bootstrap Samples
 *
 * The sample variance-covariance matrix from bootstrap estimates is computed
 * using the unbiased estimator with (B-1) denominator.
 *
 * Arguments:
 *   boot_est : real matrix (B × k) - bootstrap estimates
 *              B = number of bootstrap iterations
 *              k = number of estimators (typically 2: standard DID, sequential DID)
 *
 * Returns:
 *   real matrix (k × k): variance-covariance matrix
 *
 * Formula:
 *   VCOV[i,j] = (1/(B-1)) Σ_b (θ̂_i^{(b)} - θ̄_i)(θ̂_j^{(b)} - θ̄_j)
 *
 * where θ̄_i = (1/B) Σ_b θ̂_i^{(b)} is the bootstrap mean.
 *
 * In the double DID framework, this variance-covariance matrix serves as the
 * basis for computing optimal GMM weights: W = VCOV^{-1}.
 *
 * Note: If any value in boot_est is missing, a missing matrix is returned.
 * This conservative behavior ensures GMM weights are well-defined.
 *---------------------------------------------------------------------------*/
real matrix compute_vcov(real matrix boot_est)
{
    real scalar n_boot, k
    real rowvector means
    real matrix centered, vcov
    
    k = cols(boot_est)
    n_boot = rows(boot_est)
    
    if (n_boot == 0 || k == 0) {
        return(J(k, k, .))
    }
    
    // Require at least 2 observations for (B-1) denominator
    if (n_boot < 2) {
        return(J(k, k, .))
    }
    
    if (missing(boot_est)) {
        return(J(k, k, .))
    }

    means = mean(boot_est)
    centered = boot_est :- means
    vcov = (centered' * centered) / (n_boot - 1)

    return(vcov)
}

/*---------------------------------------------------------------------------
 * compute_pairwise_cov() - Pairwise covariance for bootstrap columns
 *
 * Computes sample covariance using only rows where both series are observed.
 * Returns missing when fewer than two paired draws exist.
 *---------------------------------------------------------------------------*/
real scalar compute_pairwise_cov(real colvector x, real colvector y)
{
    real colvector valid_idx
    real matrix paired

    valid_idx = selectindex((x :< .) :& (y :< .))
    if (rows(valid_idx) < 2) {
        return(.)
    }

    paired = x[valid_idx], y[valid_idx]
    return(compute_vcov(paired)[1, 2])
}

/*---------------------------------------------------------------------------
 * compute_vcov_pairwise() - Bootstrap VCOV with marginal variances
 *
 * Diagonal variances are computed from all non-missing draws in each column,
 * while off-diagonal covariances use only paired non-missing draws.
 * This helper is appropriate for component-level uncertainty summaries, but it
 * should not be treated as the joint covariance matrix of a bootstrap vector
 * when different components are observed on different supports.
 *---------------------------------------------------------------------------*/
real matrix compute_vcov_pairwise(real matrix boot_est)
{
    real scalar n_boot, k, i, j
    real scalar psd_tol, vcov_scale
    real matrix vcov, joint_vcov, complete_est
    real colvector valid_col
    real colvector complete_idx
    real scalar cov_ij
    real rowvector eigs

    n_boot = rows(boot_est)
    k = cols(boot_est)

    if (n_boot == 0 || k == 0) {
        return(J(k, k, .))
    }

    if (n_boot < 2) {
        return(J(k, k, .))
    }

    vcov = J(k, k, .)

    for (i = 1; i <= k; i++) {
        valid_col = select(boot_est[., i], boot_est[., i] :< .)
        if (rows(valid_col) >= 2) {
            vcov[i, i] = variance(valid_col)
        }
    }

    for (i = 1; i <= k; i++) {
        for (j = i + 1; j <= k; j++) {
            cov_ij = compute_pairwise_cov(boot_est[., i], boot_est[., j])
            vcov[i, j] = cov_ij
            vcov[j, i] = cov_ij
        }
    }

    // Mixed marginal/pairwise moments can violate PSD in partial-missing
    // bootstrap samples. When that happens for the 2x2 DID / sDID system,
    // fall back to the complete-case covariance of observed bootstrap pairs so
    // downstream GMM weights always see a valid covariance matrix.
    if (k == 2 && !missing(vcov[1, 1]) && !missing(vcov[1, 2]) && !missing(vcov[2, 2])) {
        vcov_scale = max(abs(vcov))
        psd_tol = max((1e-12, 1e-8 * vcov_scale))
        eigs = symeigenvalues(vcov)

        if (min(eigs) < -psd_tol) {
            complete_idx = selectindex(rowmissing(boot_est) :== 0)
            if (rows(complete_idx) >= 2) {
                complete_est = boot_est[complete_idx, .]
                joint_vcov = compute_vcov(complete_est)
                return(joint_vcov)
            }
        }
    }

    return(vcov)
}

/*---------------------------------------------------------------------------
 * compute_vcov_joint_valid() - Bootstrap VCOV on complete joint draws
 *
 * Computes the variance-covariance matrix using only bootstrap rows where all
 * components are jointly observed. This is the correct GMM input when the
 * weight matrix is defined as the covariance of a jointly observed bootstrap
 * vector.
 *---------------------------------------------------------------------------*/
real matrix compute_vcov_joint_valid(real matrix boot_est)
{
    real scalar n_boot, k
    real colvector complete_idx
    real matrix complete_est

    n_boot = rows(boot_est)
    k = cols(boot_est)

    if (n_boot == 0 || k == 0) {
        return(J(k, k, .))
    }

    if (n_boot < 2) {
        return(J(k, k, .))
    }

    complete_idx = selectindex(rowmissing(boot_est) :== 0)
    if (rows(complete_idx) < 2) {
        return(J(k, k, .))
    }

    complete_est = boot_est[complete_idx, .]
    return(compute_vcov(complete_est))
}

/*---------------------------------------------------------------------------
 * safe_invert() - Safe Matrix Inversion with Singularity Handling
 *
 * A matrix is inverted with robust handling of singular and near-singular cases.
 *
 * Arguments:
 *   A       : real matrix (k × k) - matrix to invert
 *   tol     : real scalar - tolerance for singularity detection (default: 1e-10)
 *   success : pointer to scalar - returns 1 if successful, 0 if singular
 *
 * Returns:
 *   real matrix (k × k): inverse of A, or missing matrix if singular
 *
 * Algorithm:
 *   1. Verify matrix is square
 *   2. Compute reciprocal condition number
 *   3. If rcond < tol, matrix is near-singular, return failure
 *   4. Otherwise, compute inverse via LU decomposition
 *---------------------------------------------------------------------------*/
real matrix safe_invert(real matrix A, | real scalar tol, pointer(real scalar) scalar success)
{
    real scalar k, kA, rcond, success_local
    real matrix Ainv
    
    if (args() < 2) tol = 1e-10
    success_local = 0
    
    k = rows(A)
    kA = cols(A)
    
    if (k != kA) {
        if (success != NULL) *success = 0
        return(J(k, kA, .))
    }
    
    if (k == 0) {
        if (success != NULL) *success = 0
        return(J(0, 0, .))
    }
    
    if (missing(A)) {
        if (success != NULL) *success = 0
        return(J(k, k, .))
    }
    
    rcond = 1 / cond(A)
    
    if (rcond < tol | missing(rcond)) {
        if (success != NULL) *success = 0
        return(J(k, k, .))
    }
    
    Ainv = luinv(A)
    
    if (missing(Ainv)) {
        if (success != NULL) *success = 0
        return(J(k, k, .))
    }
    
    success_local = 1
    if (success != NULL) *success = success_local
    
    return(Ainv)
}

/*---------------------------------------------------------------------------
 * quantile_sorted() - Compute Sample Quantile
 *
 * Sample quantiles are computed using linear interpolation (type 7 method).
 *
 * Arguments:
 *   x : real colvector - sample values
 *   p : real scalar - probability (0 to 1)
 *
 * Returns:
 *   real scalar: p-th quantile value
 *
 * Algorithm (linear interpolation):
 *   index = 1 + (n-1) * p
 *   lo = floor(index), hi = ceil(index)
 *   h = index - lo
 *   result = (1-h) * x_sorted[lo] + h * x_sorted[hi]
 *---------------------------------------------------------------------------*/
real scalar quantile_sorted(real colvector x, real scalar p)
{
    real scalar n, index, lo, hi, h
    real colvector xs
    
    if (p < 0 | p > 1 | missing(p)) {
        return(.)
    }
    
    xs = select(x, x :< .)
    n = rows(xs)
    
    if (n == 0) return(.)
    if (n == 1) return(xs[1])
    
    xs = sort(xs, 1)
    
    if (p == 0) return(xs[1])
    if (p == 1) return(xs[n])
    
    index = 1 + (n - 1) * p
    lo = floor(index)
    hi = ceil(index)
    
    if (lo < 1) lo = 1
    if (hi > n) hi = n
    if (lo == hi) return(xs[lo])
    
    h = index - lo
    
    return((1 - h) * xs[lo] + h * xs[hi])
}

/*---------------------------------------------------------------------------
 * _percentile() - Convenience wrapper for quantile_sorted()
 *---------------------------------------------------------------------------*/
real scalar _percentile(real colvector x, real scalar p)
{
    return(quantile_sorted(x, p))
}

// -------------------------------------------------------------------------
// Numerical Utility Functions
// -------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * safe_divide() - Safe Division Avoiding Divide by Zero
 *
 * Arguments:
 *   num         : real scalar - numerator
 *   denom       : real scalar - denominator
 *   default_val : real scalar - value returned if division is undefined (default: .)
 *
 * Returns:
 *   num/denom if denom != 0 and not missing, default_val otherwise
 *---------------------------------------------------------------------------*/
real scalar safe_divide(real scalar num, real scalar denom, | real scalar default_val)
{
    if (args() < 3) default_val = .
    
    if (missing(num) | missing(denom)) {
        return(default_val)
    }
    
    if (denom == 0) {
        return(default_val)
    }
    
    return(num / denom)
}

/*---------------------------------------------------------------------------
 * rel_error() - Compute Relative Error
 *
 * Arguments:
 *   computed  : real scalar - computed value
 *   reference : real scalar - reference value
 *
 * Returns:
 *   |computed - reference| / |reference|
 *   Returns 0 if both values are zero, missing if reference is zero
 *---------------------------------------------------------------------------*/
real scalar rel_error(real scalar computed, real scalar reference)
{
    if (missing(computed) | missing(reference)) {
        return(.)
    }
    
    if (reference == 0) {
        if (computed == 0) return(0)
        return(.)
    }
    
    return(abs(computed - reference) / abs(reference))
}

/*---------------------------------------------------------------------------
 * is_zero() - Check if Value is Effectively Zero
 *
 * Arguments:
 *   x   : real scalar - value to check
 *   tol : real scalar - tolerance (default: 1e-10)
 *
 * Returns:
 *   1 if |x| < tol, 0 otherwise (returns 0 if x is missing)
 *---------------------------------------------------------------------------*/
real scalar is_zero(real scalar x, | real scalar tol)
{
    if (args() < 2) tol = 1e-10
    
    if (missing(x)) return(0)
    
    return(abs(x) < tol)
}

/*---------------------------------------------------------------------------
 * normalize_binary01() - Snap near-binary values to exact 0/1
 *
 * Values within tolerance of 0 or 1 are normalized to exact binary values.
 * Missing values and values outside the tolerance band are preserved.
 *---------------------------------------------------------------------------*/
real colvector normalize_binary01(real colvector x, | real scalar tol)
{
    real colvector y
    real colvector idx0, idx1
    
    if (args() < 2) tol = 1e-6
    
    y = x
    if (rows(y) == 0) {
        return(y)
    }
    
    idx0 = selectindex(abs(y) :< tol)
    if (rows(idx0) > 0) {
        y[idx0] = J(rows(idx0), 1, 0)
    }
    
    idx1 = selectindex(abs(y :- 1) :< tol)
    if (rows(idx1) > 0) {
        y[idx1] = J(rows(idx1), 1, 1)
    }
    
    return(y)
}

/*---------------------------------------------------------------------------
 * safe_log() - Safe Natural Logarithm
 *
 * Arguments:
 *   x           : real scalar - value to take log of
 *   default_val : real scalar - value returned if x <= 0 (default: .)
 *
 * Returns:
 *   ln(x) if x > 0, default_val otherwise
 *---------------------------------------------------------------------------*/
real scalar safe_log(real scalar x, | real scalar default_val)
{
    if (args() < 2) default_val = .
    
    if (missing(x) | x <= 0) {
        return(default_val)
    }
    
    return(ln(x))
}

/*---------------------------------------------------------------------------
 * safe_sqrt() - Safe Square Root
 *
 * Arguments:
 *   x           : real scalar - value to take sqrt of
 *   default_val : real scalar - value returned if x < 0 (default: .)
 *
 * Returns:
 *   sqrt(x) if x >= 0, default_val otherwise
 *---------------------------------------------------------------------------*/
real scalar safe_sqrt(real scalar x, | real scalar default_val)
{
    if (args() < 2) default_val = .
    
    if (missing(x) | x < 0) {
        return(default_val)
    }
    
    return(sqrt(x))
}

// -------------------------------------------------------------------------
// Pattern Plot Utility Functions
// -------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _compute_treat_timing() - Compute Treatment Timing for SA Pattern Plot
 *
 * The treatment adoption time A_i for each unit is computed and mapped to
 * Y-axis positions for visualizing staggered adoption (SA) design patterns.
 *
 * Arguments:
 *   Gmat_name : string scalar - name of Stata matrix containing Gmat
 *               Gmat is N_units × T matrix where:
 *               - Gmat[i,t] = 0: unit i not yet treated at time t
 *               - Gmat[i,t] = 1: unit i treated at time t
 *               - Gmat[i,t] = -1: unit i already treated before time t
 *
 * Returns (via st_matrix):
 *   r(sort_order) : N_units × 1 matrix
 *                   sorted_pos[i] = Y-axis position for unit i
 *                   - Never-treated units appear at the bottom (Y = 1)
 *                   - Latest-treated units appear in the middle
 *                   - Earliest-treated units appear at the top (Y = N_units)
 *
 * Algorithm:
 *   1. For each unit, find first_treat = first period where G_{it} = 1
 *   2. Sort units by first_treat in descending order
 *   3. Map sorted indices to Y-axis positions
 *---------------------------------------------------------------------------*/
void _compute_treat_timing(string scalar Gmat_name)
{
    real matrix Gmat
    real colvector first_treat, first_treat_adj, sort_order, sorted_pos
    real scalar n_units, n_times, i, j
    
    Gmat = st_matrix(Gmat_name)
    n_units = rows(Gmat)
    n_times = cols(Gmat)
    
    if (n_units == 0 || n_times == 0) {
        st_matrix("r(sort_order)", J(0, 1, .))
        return
    }
    
    first_treat = J(n_units, 1, .)
    for (i = 1; i <= n_units; i++) {
        first_treat[i] = .
        for (j = 1; j <= n_times; j++) {
            if (Gmat[i, j] == 1) {
                first_treat[i] = j
                break
            }
        }
    }
    
    // Never-treated units (missing) sort to the front in descending order
    first_treat_adj = first_treat
    for (i = 1; i <= n_units; i++) {
        if (first_treat_adj[i] == .) {
            first_treat_adj[i] = n_times + 1
        }
    }
    
    sort_order = order(first_treat_adj, -1)
    
    sorted_pos = J(n_units, 1, .)
    for (i = 1; i <= n_units; i++) {
        sorted_pos[sort_order[i]] = i
    }
    
    st_matrix("r(sort_order)", sorted_pos)
}

// -------------------------------------------------------------------------
// Random Sampling Utilities
// -------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * unique_in_order() - Unique values preserving first appearance order
 *
 * Returns the first occurrence of each finite value without sorting. This is
 * useful when bootstrap resampling should be invariant to pure relabeling of
 * cluster identifiers under a fixed RNG seed.
 *---------------------------------------------------------------------------*/
real colvector unique_in_order(real colvector x)
{
    transmorphic scalar seen
    real colvector out
    real scalar i

    out = J(0, 1, .)
    seen = asarray_create("real", 1)

    for (i = 1; i <= rows(x); i++) {
        if (missing(x[i])) continue

        if (!asarray_contains(seen, x[i])) {
            asarray(seen, x[i], 1)
            out = out \ x[i]
        }
    }

    return(out)
}

/*---------------------------------------------------------------------------
 * safe_sample_idx() - Generate Random Sample Indices with Boundary Handling
 *
 * Random indices for sampling with replacement are generated, ensuring valid
 * 1-based Mata indices.
 *
 * Arguments:
 *   n    : real scalar - range of indices (1 to n)
 *   size : real scalar - number of indices to generate
 *
 * Returns:
 *   real colvector (size × 1): random indices in range [1, n]
 *
 * Algorithm:
 *   1. Generate random values using ceil(runiform() * n)
 *   2. Clamp to ensure all indices are in [1, n]
 *---------------------------------------------------------------------------*/
real colvector safe_sample_idx(real scalar n, real scalar size)
{
    real colvector idx
    
    if (n <= 0 || size <= 0) {
        return(J(0, 1, .))
    }
    
    idx = ceil(runiform(size, 1) * n)
    
    // Clamp to ensure valid 1-based indices
    idx = rowmax((idx, J(size, 1, 1)))
    idx = rowmin((idx, J(size, 1, n)))
    
    return(idx)
}

// -------------------------------------------------------------------------
// Module Verification
// -------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_utils_loaded() - Verify module is loaded
 *---------------------------------------------------------------------------*/
void _did_utils_loaded()
{
    printf("{txt}did_utils.mata loaded successfully\n")
}

// ----------------------------------------------------------------------------
// Forward struct declarations for cross-module dependencies
// ----------------------------------------------------------------------------
// These structs are defined here (in the first-loaded module) because they are
// referenced by did_bootstrap.mata (loaded before did_gmm.mata where they were
// originally defined). Defining them here avoids "already exists" errors.

/*---------------------------------------------------------------------------
 * struct sa_point - Staggered Adoption Point Estimates
 *
 * Stores time-weighted DID and sequential DID estimates for each lead
 * value in staggered adoption designs.
 *---------------------------------------------------------------------------*/
struct sa_point {
    real rowvector DID           // Time-weighted tau_DID for each lead (1 x n_lead)
    real rowvector sDID          // Time-weighted tau_sDID for each lead (1 x n_lead)
    real colvector periods       // Public period index for SA aggregation weights
    real matrix weights_common   // Common-support time weights by lead
}

end
