*! did_bootstrap.mata - Bootstrap variance estimation for DID estimators
*!
*! Implements block bootstrap for variance-covariance estimation of the
*! standard DID and sequential DID estimators. The VCOV matrix serves as
*! the optimal weight matrix in the GMM framework for the double DID estimator.
*!
*! Main functions:
*!   did_boot_std()    - Block bootstrap for standard DID design
*!   sample_panel()    - Unit-level bootstrap for staggered adoption design
*!   bootstrap_se()    - Extract standard errors from bootstrap VCOV
*!   bootstrap_ci()    - Compute percentile confidence intervals

version 16.0

mata:
mata set matastrict on

// ============================================================================
// Block Bootstrap for Variance Estimation
// ============================================================================
// The variance-covariance matrix of (tau_DID, tau_sDID) is computed via
// cluster bootstrap with the unbiased (B-1) denominator (see
// compute_vcov() in did_utils.mata):
//
//   Var(tau_DID, tau_sDID) = (1/(B-1)) * sum_b (tau^{(b)} - tau_bar)(tau^{(b)} - tau_bar)'
//
// This VCOV matrix is used as the optimal weight matrix W* in GMM estimation
// of the double DID estimator:
//
//   tau_ddid = argmin (tau - tau_DID, tau - tau_sDID)' W* (tau - tau_DID, tau - tau_sDID)
//
// Sampling is performed at the cluster level to preserve within-cluster
// correlation structure required for valid inference.
// ============================================================================

// ----------------------------------------------------------------------------
// Bootstrap Configuration Constants
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _BOOT_FAIL_WARN_PCT() - Warning threshold for bootstrap failure rate
 *---------------------------------------------------------------------------*/
real scalar _BOOT_FAIL_WARN_PCT()
{
    return(0.10)
}

/*---------------------------------------------------------------------------
 * _BOOT_MIN_SUCCESS() - Minimum successful iterations for reliable variance
 *---------------------------------------------------------------------------*/
real scalar _BOOT_MIN_SUCCESS()
{
    return(10)
}

// ----------------------------------------------------------------------------
// Data Structures
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * struct boot_result - Bootstrap result container
 *
 * Stores bootstrap estimates and metadata for variance computation.
 *---------------------------------------------------------------------------*/
struct boot_result {
    real matrix    estimates     // Bootstrap estimates (n_successful x 2*n_lead)
    pointer vector vcov          // VCOV matrix for each lead (pointer to 2x2 matrix)
    real scalar    n_successful  // Number of successful iterations
    real scalar    n_failed      // Number of failed iterations
}

/*---------------------------------------------------------------------------
 * struct boot_result_k - K-dimensional bootstrap result container
 *
 * Stores bootstrap estimates for K component estimators per lead.
 *---------------------------------------------------------------------------*/
struct boot_result_k {
    real matrix    estimates     // Bootstrap estimates (n_successful x kmax*n_lead)
    pointer vector vcov          // VCOV matrix for each lead (pointer to kmax x kmax matrix)
    real scalar    n_successful  // Number of successful iterations
    real scalar    n_failed      // Number of failed iterations
    real scalar    kmax          // Number of components per lead
}

// ----------------------------------------------------------------------------
// Cluster Sampling
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _boot_sample_clusters() - Sample cluster IDs with replacement
 *
 * Bootstrap sampling is performed at the cluster level to preserve
 * within-cluster correlation structure required for valid inference.
 *
 * Arguments:
 *   id_cluster_vec : real colvector - unique cluster identifiers
 *   n_clusters     : real scalar - number of clusters
 *
 * Returns:
 *   real colvector - sampled cluster IDs (same length as input)
 *---------------------------------------------------------------------------*/
real colvector _boot_sample_clusters(real colvector id_cluster_vec,
                                     real scalar n_clusters)
{
    real colvector random_idx, id_boot
    
    random_idx = safe_sample_idx(n_clusters, n_clusters)
    id_boot = id_cluster_vec[random_idx]
    
    return(id_boot)
}

// ----------------------------------------------------------------------------
// Bootstrap Dataset Construction
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _boot_create_dataset() - Construct bootstrap dataset from sampled clusters
 *
 * A new dataset is created by selecting observations belonging to sampled
 * clusters and reassigning sequential unit IDs. For panel data without an
 * explicit cluster variable, clustering is performed by id_unit.
 *
 * Arguments:
 *   data           : struct did_data - original data
 *   id_boot        : real colvector - sampled cluster IDs
 *   id_cluster_vec : real colvector - unique cluster identifiers
 *
 * Returns:
 *   struct did_data - bootstrap sample with reassigned unit IDs
 *---------------------------------------------------------------------------*/
struct did_data scalar _boot_create_dataset(struct did_data scalar data,
                                            real colvector id_boot,
                                            real colvector id_cluster_vec)
{
    struct did_data scalar dat_boot
    real scalar n_clusters, j, n_obs, start_idx, has_cluster, n_j, use_id_unit
    real scalar next_unit_id, k, h, n_units_boot
    real colvector idx, cluster_col, unit_ids_j, unit_source
    
    n_clusters = rows(id_boot)
    has_cluster = (rows(data.cluster_var) > 0 && cols(data.cluster_var) > 0)
    
    // Determine clustering column: explicit cluster, id_unit, or row-level
    use_id_unit = (!has_cluster && data.is_panel && rows(data.id_unit) > 0)
    
    if (has_cluster) {
        cluster_col = data.cluster_var
    }
    else if (use_id_unit) {
        cluster_col = data.id_unit
    }
    else if (!data.is_panel) {
        cluster_col = (1::data.N)
    }
    else {
        cluster_col = J(0, 1, .)
    }
    
    // First pass: count total observations
    n_obs = 0
    for (j = 1; j <= n_clusters; j++) {
        if (rows(cluster_col) == 0) {
            n_obs = n_obs + 1
        }
        else {
            n_obs = n_obs + sum(cluster_col :== id_boot[j])
        }
    }
    
    if (n_obs == 0) {
        dat_boot.N = 0
        return(dat_boot)
    }
    
    // Initialize bootstrap data structure
    dat_boot.outcome = J(n_obs, 1, .)
    dat_boot.outcome_delta = J(n_obs, 1, .)
    dat_boot.treatment = J(n_obs, 1, .)
    dat_boot.id_unit = J(n_obs, 1, .)
    dat_boot.id_time = J(n_obs, 1, .)
    dat_boot.id_time_std = J(n_obs, 1, .)
    dat_boot.Gi = J(n_obs, 1, .)
    dat_boot.It = J(n_obs, 1, .)
    
    if (cols(data.covariates) > 0) {
        dat_boot.covariates = J(n_obs, cols(data.covariates), .)
    }
    else {
        dat_boot.covariates = J(0, 0, .)
    }
    
    if (has_cluster) {
        dat_boot.cluster_var = J(n_obs, 1, .)
    }
    else {
        dat_boot.cluster_var = J(0, 1, .)
    }
    
    // Second pass: fill data
    start_idx = 1
    next_unit_id = 1
    for (j = 1; j <= n_clusters; j++) {
        if (rows(cluster_col) == 0) {
            dat_boot.outcome[start_idx] = data.outcome[id_boot[j]]
            dat_boot.treatment[start_idx] = data.treatment[id_boot[j]]
            dat_boot.id_time[start_idx] = data.id_time[id_boot[j]]
            dat_boot.id_unit[start_idx] = next_unit_id
            next_unit_id = next_unit_id + 1
            
            if (cols(data.covariates) > 0) {
                dat_boot.covariates[start_idx, .] = data.covariates[id_boot[j], .]
            }
            
            start_idx = start_idx + 1
        }
        else {
            idx = selectindex(cluster_col :== id_boot[j])
            n_j = rows(idx)
            if (n_j == 0) continue
            
            if (n_j == 1) {
                dat_boot.outcome[start_idx] = data.outcome[idx[1]]
                dat_boot.treatment[start_idx] = data.treatment[idx[1]]
                dat_boot.id_time[start_idx] = data.id_time[idx[1]]
                dat_boot.id_unit[start_idx] = next_unit_id
                next_unit_id = next_unit_id + 1
                
                if (has_cluster) {
                    dat_boot.cluster_var[start_idx] = data.cluster_var[idx[1]]
                }
                
                if (cols(data.covariates) > 0) {
                    dat_boot.covariates[start_idx, .] = data.covariates[idx[1], .]
                }
            }
            else {
                dat_boot.outcome[start_idx::(start_idx+n_j-1)] = data.outcome[idx]
                dat_boot.treatment[start_idx::(start_idx+n_j-1)] = data.treatment[idx]
                dat_boot.id_time[start_idx::(start_idx+n_j-1)] = data.id_time[idx]
                
                if (has_cluster) {
                    dat_boot.cluster_var[start_idx::(start_idx+n_j-1)] = data.cluster_var[idx]
                }
                
                if (cols(data.covariates) > 0) {
                    dat_boot.covariates[start_idx::(start_idx+n_j-1), .] = data.covariates[idx, .]
                }

                if (data.is_panel && has_cluster) {
                    // Preserve unit-level panel structure within each sampled cluster.
                    unit_source = data.id_unit[idx]
                    unit_ids_j = uniqrows(unit_source)
                    for (k = 1; k <= rows(unit_ids_j); k++) {
                        for (h = 1; h <= n_j; h++) {
                            if (unit_source[h] == unit_ids_j[k]) {
                                dat_boot.id_unit[start_idx + h - 1] = next_unit_id
                            }
                        }
                        next_unit_id = next_unit_id + 1
                    }
                }
                else {
                    dat_boot.id_unit[start_idx::(start_idx+n_j-1)] = J(n_j, 1, j)
                }
            }
            
            start_idx = start_idx + n_j
        }
    }
    
    // Set metadata
    dat_boot.N = n_obs
    if (data.is_panel) {
        n_units_boot = next_unit_id - 1
    }
    else {
        n_units_boot = n_clusters
    }
    dat_boot.n_units = n_units_boot
    dat_boot.n_periods = data.n_periods
    dat_boot.is_panel = data.is_panel
    dat_boot.treat_year = data.treat_year
    
    return(dat_boot)
}

// ----------------------------------------------------------------------------
// Outcome Delta Computation
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _compute_outcome_delta() - Outcome transformation for sequential DID
 *
 * The outcome transformation required for the sequential DID estimator
 * is computed. This estimator is consistent under the parallel trends-in-
 * trends assumption:
 *
 *   DeltaY_{it} = Y_{it} - E[Y_{i,t-1} | G_i]
 *
 * where E[Y_{i,t-1} | G_i] is the group mean outcome in the previous period.
 *
 * The sequential DID estimator subtracts the pre-treatment DID from the
 * standard DID to remove bias when trends are not parallel but the change
 * in trends is the same across groups (parallel trends-in-trends).
 *
 * Arguments:
 *   data : struct did_data - data with outcome, Gi, id_time_std
 *
 * Returns:
 *   real colvector - transformed outcome (Y - lagged group mean)
 *---------------------------------------------------------------------------*/
real colvector _compute_outcome_delta(struct did_data scalar data)
{
    real scalar n, i, g, t
    real colvector outcome_delta, Ymean
    string scalar key, lag_key
    transmorphic scalar group_sum_map, group_count_map
    real scalar sum_y, count_y
    
    n = data.N
    outcome_delta = J(n, 1, .)
    Ymean = J(n, 1, .)
    
    // Hash tables for O(N) complexity
    group_sum_map = asarray_create("string", 1)
    group_count_map = asarray_create("string", 1)
    
    // First pass: accumulate sums and counts for each (Gi, id_time_std) group
    for (i = 1; i <= n; i++) {
        g = data.Gi[i]
        t = data.id_time_std[i]
        
        if (missing(g) || missing(t)) continue
        
        key = strofreal(g) + "_" + strofreal(t)
        
        if (missing(data.outcome[i])) {
            continue
        }
        
        if (asarray_contains(group_sum_map, key)) {
            asarray(group_sum_map, key, asarray(group_sum_map, key) + data.outcome[i])
            asarray(group_count_map, key, asarray(group_count_map, key) + 1)
        }
        else {
            asarray(group_sum_map, key, data.outcome[i])
            asarray(group_count_map, key, 1)
        }
    }
    
    // Second pass: assign lag group means using O(1) lookups
    for (i = 1; i <= n; i++) {
        g = data.Gi[i]
        t = data.id_time_std[i]
        
        if (missing(g) || missing(t)) continue
        
        lag_key = strofreal(g) + "_" + strofreal(t - 1)
        
        if (asarray_contains(group_sum_map, lag_key)) {
            sum_y = asarray(group_sum_map, lag_key)
            count_y = asarray(group_count_map, lag_key)
            if (count_y > 0) {
                Ymean[i] = sum_y / count_y
            }
        }
    }
    
    outcome_delta = data.outcome - Ymean
    
    return(outcome_delta)
}

// ----------------------------------------------------------------------------
// Bootstrap Data Preparation
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _normalize_time() - Normalize time index to consecutive integers
 *
 * Time values are compressed to consecutive integers 1, 2, 3, ..., preserving
 * the temporal ordering. This is required for bootstrap samples that may have
 * non-consecutive time periods due to resampling.
 *
 * Arguments:
 *   time_values : real colvector - original time values
 *
 * Returns:
 *   real colvector - normalized time values (1, 2, 3, ...)
 *---------------------------------------------------------------------------*/
real colvector _normalize_time(real colvector time_values)
{
    real colvector unique_times, result
    real scalar n, n_unique, i
    transmorphic scalar time_map
    
    n = rows(time_values)
    if (n == 0) return(J(0, 1, .))
    
    unique_times = uniqrows(time_values)
    n_unique = rows(unique_times)
    
    result = J(n, 1, .)
    
    // Hash map for O(1) lookup
    time_map = asarray_create("real", 1)
    for (i = 1; i <= n_unique; i++) {
        asarray(time_map, unique_times[i], i)
    }
    
    for (i = 1; i <= n; i++) {
        if (!missing(time_values[i])) {
            result[i] = asarray(time_map, time_values[i])
        }
    }
    
    return(result)
}

/*---------------------------------------------------------------------------
 * _boot_panel_prep() - Re-run panel data preparation for bootstrap sample
 *
 * Derived variables (Gi, It, id_time_std, outcome_delta) are recomputed
 * for a bootstrap sample. Panel bootstrap draws must preserve the original
 * observed-sample treatment calendar; compressing time inside a draw can
 * fabricate valid-looking {-1,0} windows when the true t-1 period is absent.
 *
 * DID identification requires both treated and control units, and
 * observations in both pre- and post-treatment periods. An empty Gi
 * vector signals identification failure.
 *
 * Arguments:
 *   dat_boot : struct did_data - bootstrap sample
 *
 * Returns:
 *   struct did_data - bootstrap sample with recomputed derived variables
 *---------------------------------------------------------------------------*/
struct did_data scalar _boot_panel_prep(struct did_data scalar dat_boot)
{
    real scalar n, i, max_treat
    real colvector unit_ids, unit_idx
    
    n = dat_boot.N
    if (n == 0) return(dat_boot)
    
    // Compute Gi = max(treatment) by id_unit
    unit_ids = uniqrows(dat_boot.id_unit)
    dat_boot.Gi = J(n, 1, .)
    
    for (i = 1; i <= rows(unit_ids); i++) {
        unit_idx = selectindex(dat_boot.id_unit :== unit_ids[i])
        max_treat = max(dat_boot.treatment[unit_idx])
        dat_boot.Gi[unit_idx] = J(rows(unit_idx), 1, max_treat)
    }
    
    // Preserve the original treatment calendar. Re-normalizing a panel
    // bootstrap draw can turn a missing t-1 period into a pseudo-valid {-1,0}
    // window and pollute valid-draw counts plus downstream VCOV/CI paths.
    if (missing(dat_boot.treat_year)) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    
    // Validate identification: require both treated and control units
    if (sum(dat_boot.Gi :== 0) == 0) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    if (sum(dat_boot.Gi :== 1) == 0) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    
    // Compute standardized time index
    dat_boot.id_time_std = dat_boot.id_time :- dat_boot.treat_year
    
    // Compute post-treatment indicator
    dat_boot.It = (dat_boot.id_time :>= dat_boot.treat_year)
    
    // Validate identification: require both pre and post periods
    if (sum(dat_boot.It :== 0) == 0 || sum(dat_boot.It :== 1) == 0) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    
    // Compute outcome_delta for sequential DID
    dat_boot.outcome_delta = _compute_outcome_delta(dat_boot)
    
    return(dat_boot)
}

/*---------------------------------------------------------------------------
 * _boot_rcs_prep() - Re-run RCS data preparation for bootstrap sample
 *
 * For repeated cross-sectional data, Gi and It are input variables (not
 * computed from treatment timing). This function copies Gi and It from
 * original data, preserves the observed-sample calendar-time coding, and
 * recomputes id_time_std and outcome_delta for the sequential DID estimator.
 *
 * Arguments:
 *   dat_boot  : struct did_data - bootstrap sample
 *   data_orig : struct did_data - original data (source of Gi, It)
 *   id_boot   : real colvector - sampled indices
 *
 * Returns:
 *   struct did_data - bootstrap sample with recomputed time-relative variables
 *---------------------------------------------------------------------------*/
struct did_data scalar _boot_rcs_prep(struct did_data scalar dat_boot,
                                      struct did_data scalar data_orig,
                                      real colvector id_boot)
{
    real scalar n, j, start_idx, n_j, has_cluster
    real scalar n_orig, boot_idx
    real colvector idx, cluster_source
    
    n = dat_boot.N
    if (n == 0) return(dat_boot)
    
    has_cluster = (rows(data_orig.cluster_var) > 0 && cols(data_orig.cluster_var) > 0)
    n_orig = rows(data_orig.Gi)
    if (has_cluster) {
        cluster_source = data_orig.cluster_var
    }
    else {
        cluster_source = (1::n_orig)
    }
    
    // Copy Gi and It from original data
    dat_boot.Gi = J(n, 1, .)
    dat_boot.It = J(n, 1, .)
    
    start_idx = 1
    for (j = 1; j <= rows(id_boot); j++) {
        if (!has_cluster) {
            boot_idx = id_boot[j]
            if (boot_idx < 1 || boot_idx > n_orig) {
                continue
            }
            if (start_idx > n) {
                break
            }
            
            dat_boot.Gi[start_idx] = data_orig.Gi[boot_idx]
            dat_boot.It[start_idx] = data_orig.It[boot_idx]
            
            start_idx = start_idx + 1
        }
        else {
            idx = selectindex(cluster_source :== id_boot[j])
            n_j = rows(idx)
            if (n_j == 0) continue
            
            if (start_idx + n_j - 1 > n) {
                n_j = n - start_idx + 1
                if (n_j <= 0) break
            }
            
            if (n_j == 1) {
                dat_boot.Gi[start_idx] = data_orig.Gi[idx[1]]
                dat_boot.It[start_idx] = data_orig.It[idx[1]]
            }
            else {
                dat_boot.Gi[start_idx::(start_idx+n_j-1)] = data_orig.Gi[idx]
                dat_boot.It[start_idx::(start_idx+n_j-1)] = data_orig.It[idx]
            }
            
            start_idx = start_idx + n_j
        }
    }
    
    dat_boot.Gi = normalize_binary01(dat_boot.Gi, 1e-6)
    dat_boot.It = normalize_binary01(dat_boot.It, 1e-6)
    
    // Verify index consistency
    if (start_idx - 1 != n) {
        errprintf("{txt}Warning: _boot_rcs_prep index mismatch: expected %g rows, filled %g\n", 
                  n, start_idx - 1)
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    
    // Preserve the original calendar-time support. Compressing time inside a
    // bootstrap draw can fabricate valid-looking placebo / lead windows that
    // do not exist under the paper's original treatment calendar.
    if (missing(data_orig.treat_year)) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    dat_boot.treat_year = data_orig.treat_year
    
    // Validate identification
    if (sum(dat_boot.Gi :== 0) == 0) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    if (sum(dat_boot.Gi :== 1) == 0) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    if (sum(dat_boot.It :== 0) == 0) {
        dat_boot.Gi = J(0, 1, .)
        return(dat_boot)
    }
    
    // Recompute id_time_std and outcome_delta
    dat_boot.id_time_std = dat_boot.id_time :- data_orig.treat_year
    dat_boot.outcome_delta = _compute_outcome_delta(dat_boot)
    
    return(dat_boot)
}

// ----------------------------------------------------------------------------
// Main Bootstrap Function
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * did_boot_std() - Block bootstrap for standard DID design
 *
 * The variance-covariance matrix Sigma of (tau_DID, tau_sDID) is estimated
 * via cluster bootstrap. This VCOV matrix is used to construct the optimal
 * weight matrix in the GMM framework for the double DID estimator:
 *
 *   tau_dDID = argmin (tau - tau_DID, tau - tau_sDID)' W (tau - tau_DID, tau - tau_sDID)
 *
 * where W = Sigma^{-1} is the precision matrix (optimal GMM weight).
 * The double DID estimator combines the standard DID and sequential DID
 * to achieve efficiency under parallel trends and robustness under the
 * weaker parallel trends-in-trends assumption.
 *
 * Sampling is performed at the cluster level with replacement to preserve
 * within-cluster correlation structure for valid inference.
 *
 * Arguments:
 *   data   : struct did_data - prepared data
 *   lead   : real rowvector - post-treatment period indices
 *   n_boot : real scalar - number of bootstrap iterations
 *   seed   : real scalar - random seed (optional)
 *
 * Returns:
 *   struct boot_result - bootstrap estimates and VCOV matrices
 *---------------------------------------------------------------------------*/
struct boot_result scalar did_boot_std(struct did_data scalar data,
                                       real rowvector lead,
                                       real scalar n_boot,
                                       | real scalar seed)
{
    struct boot_result scalar result
    struct did_data scalar dat_boot
    real colvector id_cluster_vec, id_boot, valid_idx
    real scalar n_clusters, n_lead, b, l, n_successful, n_failed
    real matrix boot_est
    real rowvector est_b
    
    if (args() >= 4 && !missing(seed)) {
        rseed(seed)
    }
    
    n_lead = cols(lead)
    
    // Handle n_boot=0 case
    if (n_boot == 0) {
        printf("{txt}Note: n_boot=0, no bootstrap inference available\n")
        result.estimates = J(0, 2 * n_lead, .)
        result.vcov = J(n_lead, 1, NULL)
        result.n_successful = 0
        result.n_failed = 0
        return(result)
    }
    
    // Determine cluster structure for bootstrap sampling
    if (rows(data.cluster_var) > 0 && cols(data.cluster_var) > 0) {
        real colvector valid_cluster_mask, valid_clusters
        real scalar n_missing_clusters
        
        valid_cluster_mask = (data.cluster_var :< .)
        valid_clusters = select(data.cluster_var, valid_cluster_mask)
        n_missing_clusters = rows(data.cluster_var) - rows(valid_clusters)
        
        if (n_missing_clusters > 0) {
            printf("{txt}Warning: cluster variable contains %g missing values (excluded from bootstrap)\n",
                   n_missing_clusters)
        }
        
        if (rows(valid_clusters) > 0) {
            id_cluster_vec = unique_in_order(valid_clusters)
        }
        else {
            errprintf("Error: cluster variable contains only missing values\n")
            result.estimates = J(0, 2 * n_lead, .)
            result.vcov = J(n_lead, 1, NULL)
            result.n_successful = 0
            result.n_failed = n_boot
            return(result)
        }
    }
    else if (data.is_panel && rows(data.id_unit) > 0) {
        id_cluster_vec = unique_in_order(data.id_unit)
    }
    else {
        id_cluster_vec = (1::data.N)
    }
    n_clusters = rows(id_cluster_vec)
    
    // Initialize bootstrap estimates matrix
    boot_est = J(n_boot, 2 * n_lead, .)
    valid_idx = J(n_boot, 1, 0)
    
    // Bootstrap loop
    for (b = 1; b <= n_boot; b++) {
        
        // Sample clusters with replacement
        id_boot = _boot_sample_clusters(id_cluster_vec, n_clusters)
        
        // Construct bootstrap dataset
        dat_boot = _boot_create_dataset(data, id_boot, id_cluster_vec)
        
        if (dat_boot.N == 0) {
            continue
        }
        
        // Re-run data preparation
        if (data.is_panel) {
            dat_boot = _boot_panel_prep(dat_boot)
        }
        else {
            dat_boot = _boot_rcs_prep(dat_boot, data, id_boot)
        }
        
        if (rows(dat_boot.Gi) == 0) {
            continue
        }

        if (missing(dat_boot.Gi[1])) {
            continue
        }
        
        // Compute estimates for each lead
        est_b = J(1, 2 * n_lead, .)
        for (l = 1; l <= n_lead; l++) {
            est_b[1, (2*l-1)..(2*l)] = did_fit(
                dat_boot.outcome,
                dat_boot.outcome_delta,
                dat_boot.Gi,
                dat_boot.It,
                dat_boot.id_unit,
                dat_boot.covariates,
                dat_boot.id_time_std,
                lead[l],
                dat_boot.is_panel
            )
        }
        // Check if at least one lead has valid estimates
        real scalar has_valid_est, ll_check
        has_valid_est = 0
        for (ll_check = 1; ll_check <= n_lead; ll_check++) {
            if (!missing(est_b[1, 2*ll_check-1]) || !missing(est_b[1, 2*ll_check])) {
                has_valid_est = 1
                break
            }
        }
        if (has_valid_est) {
            boot_est[b, .] = est_b
            valid_idx[b] = 1
        }
    }
    
    // Summarize results
    n_successful = sum(valid_idx)
    n_failed = n_boot - n_successful
    
    if (n_successful > 0) {
        boot_est = select(boot_est, valid_idx)
    }
    else {
        boot_est = J(0, 2 * n_lead, .)
    }
    
    // Warn if many iterations failed
    if (n_failed > _BOOT_FAIL_WARN_PCT() * n_boot) {
        real scalar pct_failed
        pct_failed = 100 * n_failed / n_boot
        errprintf("Warning: %g / %g bootstrap iterations failed (%g percent)\n",
                  n_failed, n_boot, pct_failed)
    }
    
    if (n_successful < _BOOT_MIN_SUCCESS() && n_successful > 0) {
        if (n_failed > 0) {
            errprintf("Warning: Only %g bootstrap iterations succeeded, results may be unreliable\n",
                      n_successful)
        }
        else {
            errprintf("Warning: All %g bootstrap iterations succeeded, but nboot() is below the recommended minimum of %g\n",
                      n_successful, _BOOT_MIN_SUCCESS())
        }
    }
    
    // Compute VCOV for each lead
    result.estimates = boot_est
    result.vcov = J(n_lead, 1, NULL)
    result.n_successful = n_successful
    result.n_failed = n_failed
    
    if (n_successful >= 2) {
        for (l = 1; l <= n_lead; l++) {
            real matrix boot_est_lead
            real scalar n_valid_did, n_valid_sdid
            real matrix vcov_joint
            
            boot_est_lead = boot_est[., (2*l-1)..(2*l)]
            n_valid_did = rows(select(boot_est_lead[., 1], boot_est_lead[., 1] :< .))
            n_valid_sdid = rows(select(boot_est_lead[., 2], boot_est_lead[., 2] :< .))
            
            if (n_valid_did >= 2 && n_valid_sdid >= 2) {
                vcov_joint = compute_vcov_joint_valid(boot_est_lead)
                // Allocate a distinct matrix per lead so multi-lead runs do not
                // alias the last loop-local vcov_joint value across pointers.
                result.vcov[l] = &(J(2, 2, .))
                *result.vcov[l] = vcov_joint
            }
            else {
                result.vcov[l] = &(J(2, 2, .))
            }
        }
    }
    
    return(result)
}

// ----------------------------------------------------------------------------
// Standard Error and Confidence Interval Functions
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * bootstrap_se() - Extract standard errors from bootstrap VCOV
 *
 * Standard errors are computed as square roots of diagonal elements:
 *   SE(tau_DID)  = sqrt(Var[1,1])
 *   SE(tau_sDID) = sqrt(Var[2,2])
 *
 * Arguments:
 *   vcov : real matrix (2 x 2) - variance-covariance matrix
 *
 * Returns:
 *   real rowvector (1 x 2) - (SE_DID, SE_sDID)
 *---------------------------------------------------------------------------*/
real rowvector bootstrap_se(real matrix vcov)
{
    real rowvector se
    
    if (rows(vcov) != 2 || cols(vcov) != 2) {
        return((., .))
    }
    
    if (missing(vcov[1,1]) || missing(vcov[2,2])) {
        return((., .))
    }
    
    se = (sqrt(vcov[1,1]), sqrt(vcov[2,2]))
    
    return(se)
}

/*---------------------------------------------------------------------------
 * bootstrap_ci() - Compute percentile bootstrap confidence intervals
 *
 * Confidence intervals are computed using the percentile method:
 *   ci_low  = quantile(boot_est, alpha/2)
 *   ci_high = quantile(boot_est, 1 - alpha/2)
 * where alpha = 1 - level/100.
 *
 * Arguments:
 *   boot_est : real colvector - bootstrap estimates for one parameter
 *   level    : real scalar - confidence level (e.g., 95)
 *
 * Returns:
 *   real rowvector (1 x 2) - (ci_low, ci_high)
 *---------------------------------------------------------------------------*/
real rowvector bootstrap_ci(real colvector boot_est, real scalar level)
{
    real scalar alpha, p_low, p_high
    real rowvector ci
    
    if (level <= 0 || level >= 100) {
        return((., .))
    }
    
    alpha = 1 - level / 100
    p_low = alpha / 2
    p_high = 1 - alpha / 2
    
    ci = (quantile_sorted(boot_est, p_low), quantile_sorted(boot_est, p_high))
    
    return(ci)
}

// ============================================================================
// Panel Bootstrap for Staggered Adoption Design
// ============================================================================
// Unit-level bootstrap is implemented for the staggered adoption (SA) design
// where treatment timing varies across units. Unlike the standard DID bootstrap
// which samples clusters, the SA design requires sampling entire units with
// replacement to preserve the time series structure needed for:
//
//   1. Reconstructing the treatment timing matrix (Gmat) encoding adoption times
//   2. Computing period-specific SA-ATT estimates: tau_DID(t), tau_sDID(t)
//   3. Aggregating via time weights: tau_bar = sum_t pi_t * tau(t)
//
// The SA double DID extends the basic double DID framework by applying the
// GMM combination of DID and sequential DID estimators at each treatment time,
// then aggregating across time periods using appropriate weights.
// ============================================================================

/*---------------------------------------------------------------------------
 * sample_panel() - Unit-level bootstrap for staggered adoption design
 *
 * Entire units are sampled with replacement, preserving the time series
 * structure required for period-specific SA-ATT estimation. Each sampled
 * unit is assigned a new sequential ID to handle duplicate units.
 *
 * Derived fields (Gi, It, id_time_std, outcome_delta) are NOT populated here.
 * These must be recomputed downstream after the treatment timing matrix (Gmat)
 * is rebuilt from the bootstrap sample.
 *
 * Arguments:
 *   data : struct did_data - panel data structure
 *
 * Returns:
 *   struct did_data - bootstrap sample with reassigned unit IDs
 *---------------------------------------------------------------------------*/
struct did_data scalar sample_panel(struct did_data scalar data)
{
    struct did_data scalar boot_data
    real colvector block_vec, block_boot, idx, new_id_unit
    real matrix boot_outcome, boot_treatment, boot_time, boot_covariates
    real colvector boot_cluster
    real scalar n_blocks, i, j, n_obs_total, n_obs_i, n_units_boot
    real scalar has_covariates, has_cluster
    real colvector unit_ids_block, unique_units_block, mapped_units_block
    real scalar u, r
    transmorphic scalar unit_map
    
    // Validate panel data structure
    if (!data.is_panel) {
        errprintf("sample_panel(): Requires panel data (is_panel=1)\n")
        errprintf("               For RCS data, use cluster bootstrap instead\n")
        boot_data.outcome = J(0, 1, .)
        boot_data.treatment = J(0, 1, .)
        boot_data.id_unit = J(0, 1, .)
        boot_data.id_time = J(0, 1, .)
        boot_data.covariates = J(0, 0, .)
        boot_data.cluster_var = J(0, 1, .)
        boot_data.Gi = J(0, 1, .)
        boot_data.It = J(0, 1, .)
        boot_data.id_time_std = J(0, 1, .)
        boot_data.outcome_delta = J(0, 1, .)
        boot_data.N = 0
        boot_data.n_units = 0
        boot_data.n_periods = 0
        boot_data.treat_year = .
        boot_data.is_panel = 0
        return(boot_data)
    }
    
    // Handle empty dataset
    if (data.N == 0 || data.n_units == 0) {
        boot_data.outcome = J(0, 1, .)
        boot_data.treatment = J(0, 1, .)
        boot_data.id_unit = J(0, 1, .)
        boot_data.id_time = J(0, 1, .)
        boot_data.covariates = J(0, 0, .)
        boot_data.cluster_var = J(0, 1, .)
        boot_data.Gi = J(0, 1, .)
        boot_data.It = J(0, 1, .)
        boot_data.id_time_std = J(0, 1, .)
        boot_data.outcome_delta = J(0, 1, .)
        boot_data.N = 0
        boot_data.n_units = 0
        boot_data.n_periods = data.n_periods
        boot_data.treat_year = .
        boot_data.is_panel = data.is_panel
        return(boot_data)
    }
    
    has_covariates = (cols(data.covariates) > 0 && rows(data.covariates) == data.N)
    has_cluster = (rows(data.cluster_var) == data.N && cols(data.cluster_var) > 0)

    // Sample cluster IDs with replacement when cluster_var is available.
    // Otherwise fall back to the unit-level bootstrap.
    if (has_cluster) {
        block_vec = unique_in_order(data.cluster_var)
    }
    else {
        block_vec = unique_in_order(data.id_unit)
    }
    n_blocks = rows(block_vec)
    block_boot = block_vec[safe_sample_idx(n_blocks, n_blocks)]
    
    // Cache selectindex() results for efficiency
    transmorphic idx_cache
    idx_cache = asarray_create("real", 1)
    asarray_notfound(idx_cache, J(0, 1, .))
    
    // First pass: count total observations in the sampled blocks
    n_obs_total = 0
    for (i = 1; i <= n_blocks; i++) {
        if (has_cluster) {
            idx = selectindex(data.cluster_var :== block_boot[i])
        }
        else {
            idx = selectindex(data.id_unit :== block_boot[i])
        }
        asarray(idx_cache, i, idx)
        n_obs_total = n_obs_total + rows(idx)
    }
    
    // Allocate result matrices
    boot_outcome = J(n_obs_total, 1, .)
    boot_treatment = J(n_obs_total, 1, .)
    boot_time = J(n_obs_total, 1, .)
    new_id_unit = J(n_obs_total, 1, .)
    
    if (has_covariates) {
        boot_covariates = J(n_obs_total, cols(data.covariates), .)
    }
    else {
        boot_covariates = J(0, 0, .)
    }
    
    if (has_cluster) {
        boot_cluster = J(n_obs_total, 1, .)
    }
    else {
        boot_cluster = J(0, 1, .)
    }
    
    // Second pass: fill data using cached indices
    j = 1
    n_units_boot = 0
    for (i = 1; i <= n_blocks; i++) {
        idx = asarray(idx_cache, i)
        n_obs_i = rows(idx)
        
        if (n_obs_i == 0) continue

        // Renormalize unit identifiers within each sampled block so that the
        // bootstrap sample remains a valid balanced panel on consecutive ids.
        unit_ids_block = data.id_unit[idx]
        unique_units_block = uniqrows(unit_ids_block)
        unit_map = asarray_create("real")
        mapped_units_block = J(n_obs_i, 1, .)

        for (u = 1; u <= rows(unique_units_block); u++) {
            n_units_boot++
            asarray(unit_map, unique_units_block[u], n_units_boot)
        }

        for (r = 1; r <= n_obs_i; r++) {
            mapped_units_block[r] = asarray(unit_map, unit_ids_block[r])
        }
        
        if (n_obs_i == 1) {
            boot_outcome[j] = data.outcome[idx[1]]
            boot_treatment[j] = data.treatment[idx[1]]
            boot_time[j] = data.id_time[idx[1]]
            new_id_unit[j] = mapped_units_block[1]
            
            if (has_covariates) {
                boot_covariates[j, .] = data.covariates[idx[1], .]
            }
            
            if (has_cluster) {
                boot_cluster[j] = data.cluster_var[idx[1]]
            }
        }
        else {
            boot_outcome[j::(j+n_obs_i-1)] = data.outcome[idx]
            boot_treatment[j::(j+n_obs_i-1)] = data.treatment[idx]
            boot_time[j::(j+n_obs_i-1)] = data.id_time[idx]
            new_id_unit[j::(j+n_obs_i-1)] = mapped_units_block
            
            if (has_covariates) {
                boot_covariates[j::(j+n_obs_i-1), .] = data.covariates[idx, .]
            }
            
            if (has_cluster) {
                boot_cluster[j::(j+n_obs_i-1)] = data.cluster_var[idx]
            }
        }
        
        j = j + n_obs_i
    }
    
    // Populate result structure
    boot_data.outcome = boot_outcome
    boot_data.treatment = boot_treatment
    boot_data.id_time = boot_time
    boot_data.id_unit = new_id_unit
    boot_data.covariates = boot_covariates
    boot_data.cluster_var = boot_cluster
    
    // Update metadata
    boot_data.N = n_obs_total
    boot_data.n_units = n_units_boot
    boot_data.n_periods = data.n_periods
    boot_data.is_panel = data.is_panel
    
    // Derived fields are NOT populated - must be computed downstream
    boot_data.Gi = J(0, 1, .)
    boot_data.It = J(0, 1, .)
    boot_data.id_time_std = J(0, 1, .)
    boot_data.outcome_delta = J(0, 1, .)
    boot_data.treat_year = .
    
    return(boot_data)
}

// ============================================================================
// K-DIMENSIONAL BOOTSTRAP FOR GENERALIZED K-DID
// ============================================================================

/*---------------------------------------------------------------------------
 * did_boot_std_k() - Block bootstrap for generalized K-DID
 *
 * K-dimensional extension of did_boot_std(). Each bootstrap replication
 * produces a K-dimensional component vector (τ̂_1, ..., τ̂_K) per lead,
 * stored in an n_success × (kmax * n_lead) matrix.
 *
 * Arguments:
 *   data   : struct did_data - prepared data
 *   lead   : real rowvector - post-treatment lead values
 *   n_boot : real scalar - number of bootstrap iterations
 *   kmax   : real scalar - max number of K-DID components
 *   seed   : real scalar (optional) - random seed
 *
 * Returns:
 *   struct boot_result_k - K-dimensional bootstrap estimates and VCOV
 *---------------------------------------------------------------------------*/
struct boot_result_k scalar did_boot_std_k(struct did_data scalar data,
                                           real rowvector lead,
                                           real scalar n_boot,
                                           real scalar kmax,
                                           | real scalar seed)
{
    struct boot_result_k scalar result
    struct did_data scalar dat_boot
    real colvector id_cluster_vec, id_boot, valid_idx
    real scalar n_clusters, n_lead, b, l, k_comp, n_successful, n_failed
    real matrix boot_est
    real rowvector est_b, comp_k

    if (args() >= 5 && !missing(seed)) {
        rseed(seed)
    }

    n_lead = cols(lead)
    result.kmax = kmax

    // Handle n_boot=0 case
    if (n_boot == 0) {
        printf("{txt}Note: n_boot=0, no bootstrap inference available\n")
        result.estimates = J(0, kmax * n_lead, .)
        result.vcov = J(n_lead, 1, NULL)
        result.n_successful = 0
        result.n_failed = 0
        return(result)
    }

    // Determine cluster structure (same as did_boot_std)
    if (rows(data.cluster_var) > 0 && cols(data.cluster_var) > 0) {
        real colvector valid_cluster_mask, valid_clusters
        real scalar n_missing_clusters

        valid_cluster_mask = (data.cluster_var :< .)
        valid_clusters = select(data.cluster_var, valid_cluster_mask)
        n_missing_clusters = rows(data.cluster_var) - rows(valid_clusters)

        if (n_missing_clusters > 0) {
            printf("{txt}Warning: cluster variable contains %g missing values (excluded from bootstrap)\n",
                   n_missing_clusters)
        }

        if (rows(valid_clusters) > 0) {
            id_cluster_vec = unique_in_order(valid_clusters)
        }
        else {
            errprintf("Error: cluster variable contains only missing values\n")
            result.estimates = J(0, kmax * n_lead, .)
            result.vcov = J(n_lead, 1, NULL)
            result.n_successful = 0
            result.n_failed = n_boot
            return(result)
        }
    }
    else if (data.is_panel && rows(data.id_unit) > 0) {
        id_cluster_vec = unique_in_order(data.id_unit)
    }
    else {
        id_cluster_vec = (1::data.N)
    }
    n_clusters = rows(id_cluster_vec)

    // Initialize bootstrap estimates matrix: kmax columns per lead
    boot_est = J(n_boot, kmax * n_lead, .)
    valid_idx = J(n_boot, 1, 0)

    // Bootstrap loop
    for (b = 1; b <= n_boot; b++) {

        id_boot = _boot_sample_clusters(id_cluster_vec, n_clusters)
        dat_boot = _boot_create_dataset(data, id_boot, id_cluster_vec)

        if (dat_boot.N == 0) {
            continue
        }

        if (data.is_panel) {
            dat_boot = _boot_panel_prep(dat_boot)
        }
        else {
            dat_boot = _boot_rcs_prep(dat_boot, data, id_boot)
        }

        if (rows(dat_boot.Gi) == 0 || missing(dat_boot.Gi[1])) {
            continue
        }

        // Compute K-dimensional component estimates for each lead
        est_b = J(1, kmax * n_lead, .)
        for (l = 1; l <= n_lead; l++) {
            comp_k = did_fit_k(
                dat_boot.outcome,
                dat_boot.Gi,
                dat_boot.It,
                dat_boot.id_unit,
                dat_boot.covariates,
                dat_boot.id_time_std,
                lead[l],
                kmax,
                dat_boot.is_panel
            )
            est_b[1, (kmax*(l-1)+1)..(kmax*l)] = comp_k
        }

        // Check if at least one lead has a valid estimate
        real scalar has_valid_est_k, ll_k, kk
        has_valid_est_k = 0
        for (ll_k = 1; ll_k <= n_lead; ll_k++) {
            for (kk = 1; kk <= kmax; kk++) {
                if (!missing(est_b[1, kmax*(ll_k-1)+kk])) {
                    has_valid_est_k = 1
                    break
                }
            }
            if (has_valid_est_k) break
        }
        if (has_valid_est_k) {
            boot_est[b, .] = est_b
            valid_idx[b] = 1
        }
    }

    // Summarize results
    n_successful = sum(valid_idx)
    n_failed = n_boot - n_successful

    if (n_successful > 0) {
        boot_est = select(boot_est, valid_idx)
    }
    else {
        boot_est = J(0, kmax * n_lead, .)
    }

    if (n_failed > _BOOT_FAIL_WARN_PCT() * n_boot) {
        real scalar pct_failed_k
        pct_failed_k = 100 * n_failed / n_boot
        errprintf("Warning: %g / %g bootstrap iterations failed (%g percent)\n",
                  n_failed, n_boot, pct_failed_k)
    }

    if (n_successful < _BOOT_MIN_SUCCESS() && n_successful > 0) {
        errprintf("Warning: Only %g bootstrap iterations succeeded, results may be unreliable\n",
                  n_successful)
    }

    // Compute VCOV for each lead (K × K)
    result.estimates = boot_est
    result.vcov = J(n_lead, 1, NULL)
    result.n_successful = n_successful
    result.n_failed = n_failed

    if (n_successful >= 2) {
        for (l = 1; l <= n_lead; l++) {
            real matrix boot_est_lead_k, vcov_k
            real scalar col_start, col_end

            col_start = kmax * (l - 1) + 1
            col_end = kmax * l
            boot_est_lead_k = boot_est[., col_start..col_end]

            // Compute K×K VCOV using joint-valid observations
            vcov_k = compute_vcov_joint_valid(boot_est_lead_k)
            result.vcov[l] = &(J(kmax, kmax, .))
            *result.vcov[l] = vcov_k
        }
    }

    return(result)
}

// ----------------------------------------------------------------------------
// Parallel Bootstrap: Chunked Execution Functions
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * did_boot_std_chunk() - Chunked block bootstrap for standard DID
 *
 * Executes bootstrap iterations [b_start, b_end] using the same algorithm
 * as did_boot_std(). The optional seed_chunk is set before execution to
 * ensure reproducibility of this chunk across parallel runs.
 *
 * Arguments:
 *   data       : struct did_data - prepared data (same as did_boot_std)
 *   lead       : real rowvector  - post-treatment lead values
 *   b_start    : real scalar     - first iteration index of this chunk (>=1)
 *   b_end      : real scalar     - last iteration index of this chunk (>=b_start)
 *   seed_chunk : real scalar     - (optional) RNG seed for this chunk;
 *                                  if missing, no seed is set
 *
 * Returns:
 *   struct boot_result - same format as did_boot_std()
 *---------------------------------------------------------------------------*/
struct boot_result scalar did_boot_std_chunk(
    struct did_data scalar data,
    real rowvector lead,
    real scalar b_start,
    real scalar b_end,
    | real scalar seed_chunk)
{
    struct boot_result scalar result
    real scalar n_iter

    // Set RNG seed for this chunk if specified
    if (args() >= 5 && !missing(seed_chunk)) {
        rseed(seed_chunk)
    }

    // Compute number of iterations for this chunk
    n_iter = b_end - b_start + 1
    if (n_iter <= 0) {
        result.estimates    = J(0, 2 * cols(lead), .)
        result.vcov         = J(cols(lead), 1, NULL)
        result.n_successful = 0
        result.n_failed     = 0
        return(result)
    }

    // Delegate to did_boot_std() with n_iter iterations.
    // Seed is already set above; do NOT pass seed to did_boot_std()
    // to avoid overwriting the chunk seed.
    result = did_boot_std(data, lead, n_iter)

    return(result)
}

/*---------------------------------------------------------------------------
 * did_boot_sa_chunk() - Chunked unit bootstrap for staggered adoption design
 *
 * Executes SA bootstrap iterations [b_start, b_end]. Each iteration resamples
 * entire units via sample_panel(), re-estimates the time-weighted SA-DID and
 * SA-sDID for all leads via sa_double_did(), and accumulates raw (DID[l], sDID[l])
 * pairs. The resulting matrix preserves the bootstrap covariance structure
 * required by sa_to_ddid_matrix() for GMM-optimal weighting.
 *
 * Arguments:
 *   data       : struct did_data   - panel data (is_panel must equal 1)
 *   option     : struct did_option - estimation options (lead, thres, level, quiet)
 *   b_start    : real scalar       - first iteration index of this chunk (>=1)
 *   b_end      : real scalar       - last iteration index of this chunk (>=b_start)
 *   seed_chunk : real scalar       - (optional) RNG seed for this chunk
 *
 * Returns:
 *   struct boot_result
 *     .estimates    : n_successful x (2*n_lead) matrix;
 *                     columns 2l-1, 2l = (DID[l], sDID[l]) for lead index l
 *     .n_successful : count of iterations producing at least one valid estimate
 *     .n_failed     : count of failed iterations
 *     .vcov         : J(n_lead, 1, NULL)  -- filled by sa_to_ddid_matrix()
 *---------------------------------------------------------------------------*/
struct boot_result scalar did_boot_sa_chunk(
    struct did_data scalar data,
    struct did_option scalar option,
    real scalar b_start,
    real scalar b_end,
    | real scalar seed_chunk)
{
    struct boot_result scalar result
    struct did_data scalar dat_boot
    struct sa_point scalar boot_pt
    real matrix boot_mat
    real rowvector row_b
    real scalar n_iter, n_lead, b, l, n_failed, boot_has_valid

    // Set RNG seed for this chunk if specified
    if (args() >= 5 && !missing(seed_chunk)) {
        rseed(seed_chunk)
    }

    n_iter = b_end - b_start + 1
    n_lead = cols(option.lead)

    // Return empty result for degenerate chunk
    if (n_iter <= 0) {
        result.estimates    = J(0, 2 * n_lead, .)
        result.vcov         = J(n_lead, 1, NULL)
        result.n_successful = 0
        result.n_failed     = 0
        return(result)
    }

    boot_mat = J(0, 2 * n_lead, .)
    n_failed = 0

    for (b = 1; b <= n_iter; b++) {

        // Unit-level bootstrap: resample entire units with replacement
        dat_boot = sample_panel(data)

        if (dat_boot.N == 0 || dat_boot.n_units < 2) {
            n_failed++
            continue
        }

        // Compute time-weighted SA-DID and SA-sDID for all leads jointly.
        // sa_double_did() rebuilds Gmat, selects valid periods, applies pi_t
        // weights, and returns aggregated (DID[l], sDID[l]) for each lead l.
        boot_pt = sa_double_did(dat_boot, option)

        // Accept iteration if at least one lead has a valid estimate pair
        boot_has_valid = 0
        for (l = 1; l <= n_lead; l++) {
            if (!missing(boot_pt.DID[l]) || !missing(boot_pt.sDID[l])) {
                boot_has_valid = 1
                break
            }
        }

        if (!boot_has_valid) {
            n_failed++
            continue
        }

        // Store (DID[l], sDID[l]) for each lead as a 2*n_lead row vector.
        // Preserving raw pairs (not pre-combined dDID) is essential: the
        // bootstrap covariance Sigma = Cov(DID^b, sDID^b) determines the
        // GMM optimal weight W* = Sigma^{-1} (paper equation 13).
        row_b = J(1, 2 * n_lead, .)
        for (l = 1; l <= n_lead; l++) {
            row_b[2*l - 1] = boot_pt.DID[l]
            row_b[2*l]     = boot_pt.sDID[l]
        }
        boot_mat = boot_mat \ row_b
    }

    result.estimates    = boot_mat
    result.vcov         = J(n_lead, 1, NULL)
    result.n_successful = rows(boot_mat)
    result.n_failed     = n_failed

    return(result)
}

// ----------------------------------------------------------------------------
// Module Verification Function
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_bootstrap_loaded() - Verify module is loaded
 *---------------------------------------------------------------------------*/
void _did_bootstrap_loaded()
{
    printf("{txt}did_bootstrap.mata loaded successfully\n")
}

end
