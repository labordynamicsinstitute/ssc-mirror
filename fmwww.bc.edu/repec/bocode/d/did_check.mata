*! did_check.mata - Parallel trends diagnostic functions
*!
*! Implements placebo tests for assessing the parallel trends assumption in
*! difference-in-differences designs. Supports both standard DID and staggered
*! adoption designs. Provides cluster-bootstrap inference and equivalence
*! confidence intervals for pre-treatment trend evaluation.

version 16.0

mata:
mata set matastrict on

// ============================================================================
// Parallel Trends Diagnostic Module
// ============================================================================
//
// This module implements placebo tests for evaluating the parallel trends
// assumption in difference-in-differences designs. Under parallel trends,
// pre-treatment DID estimates should be approximately zero; significant
// deviations indicate potential violations.
//
// Placebo test procedure:
//   For each pre-treatment lag l:
//     1. Subset data to periods {-l, -l-1}
//     2. Define pseudo-treatment indicator It = 1{time >= -l}
//     3. Estimate DID coefficient (expected zero under parallel trends)
//     4. Standardize by control group baseline standard deviation
//
// Core functionality:
//   - Standard DID placebo tests (did_placebo)
//   - Staggered adoption placebo tests (did_sad_placebo)
//   - Cluster-bootstrap standard errors (did_placebo_boot_full)
//   - Equivalence confidence intervals for trend assessment
//
// ============================================================================

// ----------------------------------------------------------------------------
// DATA STRUCTURES
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * struct placebo_result
 *
 * placebo test point estimates.
 *---------------------------------------------------------------------------*/
struct placebo_result {
    real colvector est           // Raw estimates
    real colvector est_std       // Standardized estimates
    real colvector lags          // Feasible lag values
}

/*---------------------------------------------------------------------------
 * struct placebo_boot_result
 *
 * bootstrap results including standard errors.
 *---------------------------------------------------------------------------*/
struct placebo_boot_result {
    real colvector se            // Bootstrap standard errors (raw)
    real colvector se_std        // Bootstrap standard errors (standardized)
    real scalar n_valid          // Number of successful iterations
    real matrix boot_est         // Bootstrap estimates (raw)
    real matrix boot_est_std     // Bootstrap estimates (standardized)
}

/*---------------------------------------------------------------------------
 * struct check_result
 *
 * Complete diagnostic check results including standard errors and
 * equivalence confidence intervals for parallel trends assessment.
 *---------------------------------------------------------------------------*/
struct check_result {
    real colvector lag           // Lag values
    real colvector estimate      // Standardized estimates
    real colvector estimate_raw  // Raw estimates
    real colvector std_error     // Standard errors (standardized)
    real colvector std_error_raw // Standard errors (raw)
    real colvector eq_ci_low     // Equivalence CI lower bounds
    real colvector eq_ci_high    // Equivalence CI upper bounds
}

// ----------------------------------------------------------------------------
// CORE FUNCTIONS
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * did_placebo() - Compute Placebo DID Estimates
 *
 * Computes placebo DID estimates for pre-treatment periods to assess
 * the parallel trends assumption. Under parallel trends, these estimates
 * should be approximately zero.
 *
 * Arguments:
 *   Y        : real colvector - outcome variable
 *   Gi       : real colvector - treatment group indicator 
 *   time_std : real colvector - standardized time (0 = treatment)
 *   X        : real matrix - covariates 
 *   lags     : real rowvector - lag periods to test 
 * Returns:
 *   struct placebo_result with raw and standardized estimates
 *
 * Algorithm:
 *   1. Filter infeasible lags: keep only lags < max_lag
 *      where max_lag = abs(min(time_std))
 *   
 *   For each valid lag l:
 *     2. Filter data to periods {-l, -l-1}
 *     3. Create pseudo-treatment indicator It = 1{time_std >= -l}
 *     4. Compute raw DID estimate via OLS
 *     5. Standardize by control group baseline SD:
 *        outcome_std = (outcome - mean(control)) / sd(control)
 *     6. Compute standardized DID estimate
 *---------------------------------------------------------------------------*/
struct placebo_result scalar did_placebo(real colvector Y,
                                         real colvector Gi,
                                         real colvector time_std,
                                         real matrix X,
                                         real rowvector lags)
{
    struct placebo_result scalar result
    real rowvector lags_abs, valid_lags
    real colvector idx, Y_use, Gi_use, time_use, It
    real colvector Y_std, ct_idx
    real colvector ct_candidate_idx
    real matrix X_use, design
    real scalar max_lag, n_lags, i, lag, ct_mean, ct_sd
    real scalar est_raw, est_standardized, n_use, k_cov
    
    // Lag feasibility filtering
    lags_abs = abs(lags)
    max_lag = abs(min(time_std))

    // Keep only feasible lags
    valid_lags = select(lags_abs, lags_abs :< max_lag)
    n_lags = cols(valid_lags)
    
    // Handle empty case
    if (n_lags == 0) {
        result.est = J(0, 1, .)
        result.est_std = J(0, 1, .)
        result.lags = J(0, 1, .)
        return(result)
    }
    
    // Initialize result containers
    result.est = J(n_lags, 1, .)
    result.est_std = J(n_lags, 1, .)
    result.lags = valid_lags'
    
    k_cov = cols(X)
    
    // -------------------------------------------------------------------------
    // Main loop over lags
    // -------------------------------------------------------------------------
    for (i = 1; i <= n_lags; i++) {
        lag = valid_lags[i]
        
        // Subset to periods {-lag, -lag-1}
        idx = selectindex((time_std :== -lag) :| (time_std :== -lag - 1))
        
        if (length(idx) == 0) {
            continue
        }
        
        // Extract subset
        Y_use = Y[idx]
        Gi_use = Gi[idx]
        time_use = time_std[idx]
        n_use = length(idx)
        
        if (k_cov > 0) {
            X_use = X[idx, .]
        }
        else {
            X_use = J(n_use, 0, .)
        }
        
        // Define pseudo-treatment indicator
        It = (time_use :>= -lag)
        
        // Estimate raw DID
        est_raw = _ols_did_coef(Y_use, Gi_use, It, X_use)
        result.est[i] = est_raw
        
        // Standardize using the control-group baseline, matching the paper
        // and reference package where placebo diagnostics always report both
        // standardized and raw estimates.
        ct_candidate_idx = selectindex((It :== 0) :& (Gi_use :== 0) :& (Y_use :< .))
        if (k_cov > 0 && length(ct_candidate_idx) > 0) {
            ct_candidate_idx = select(ct_candidate_idx, rowmissing(X_use[ct_candidate_idx, .]) :== 0)
        }
        ct_idx = ct_candidate_idx
        
        if (length(ct_idx) == 0) {
            result.est_std[i] = .
            continue
        }
        
        // Exclude missing values from control baseline
        real colvector ct_vals, ct_vals_valid
        ct_vals = Y_use[ct_idx]
        ct_vals_valid = select(ct_vals, ct_vals :< .)
        
        // Require at least 2 observations for sample variance
        if (length(ct_vals_valid) < 2) {
            result.est_std[i] = .
            continue
        }
        
        // Compute control baseline statistics
        ct_mean = mean(ct_vals_valid)
        ct_sd = sqrt(variance(ct_vals_valid))
        
        if (ct_sd == 0 | missing(ct_sd)) {
            result.est_std[i] = .
            continue
        }
        
        // Standardize outcome
        Y_std = (Y_use :- ct_mean) :/ ct_sd
        
        // Estimate standardized DID
        est_standardized = _ols_did_coef(Y_std, Gi_use, It, X_use)
        result.est_std[i] = est_standardized
    }
    
    return(result)
}

/*---------------------------------------------------------------------------
 * _std_placebo_support_idx() - Rows used by standardized placebo OLS
 *
 * Reconstructs the listwise-deletion sample for a single placebo lag after
 * the control-group baseline standardization step. The returned indices are
 * positions in the current Y/Gi/time_std vectors, not the full dataset.
 *---------------------------------------------------------------------------*/
real colvector _std_placebo_support_idx(real colvector Y,
                                        real colvector Gi,
                                        real colvector time_std,
                                        real matrix X,
                                        real scalar lag)
{
    real colvector idx, Y_use, Gi_use, time_use, It, ct_idx, Y_std, valid_idx
    real colvector ct_candidate_idx
    real matrix X_use
    real scalar ct_mean, ct_sd, k_cov

    idx = selectindex((time_std :== -lag) :| (time_std :== -lag - 1))
    if (length(idx) == 0) {
        return(J(0, 1, .))
    }

    Y_use = Y[idx]
    Gi_use = Gi[idx]
    time_use = time_std[idx]
    It = (time_use :>= -lag)
    k_cov = cols(X)

    if (k_cov > 0) {
        X_use = X[idx, .]
    }
    else {
        X_use = J(rows(idx), 0, .)
    }

    ct_candidate_idx = selectindex((It :== 0) :& (Gi_use :== 0) :& (Y_use :< .))
    if (k_cov > 0 && length(ct_candidate_idx) > 0) {
        ct_candidate_idx = select(ct_candidate_idx, rowmissing(X_use[ct_candidate_idx, .]) :== 0)
    }
    ct_idx = ct_candidate_idx
    if (length(ct_idx) == 0) {
        return(J(0, 1, .))
    }

    real colvector ct_vals, ct_vals_valid
    ct_vals = Y_use[ct_idx]
    ct_vals_valid = select(ct_vals, ct_vals :< .)
    if (length(ct_vals_valid) < 2) {
        return(J(0, 1, .))
    }

    ct_mean = mean(ct_vals_valid)
    ct_sd = sqrt(variance(ct_vals_valid))
    if (ct_sd == 0 | missing(ct_sd)) {
        return(J(0, 1, .))
    }

    Y_std = (Y_use :- ct_mean) :/ ct_sd
    valid_idx = selectindex((Y_std :< .) :& (Gi_use :< .) :& (It :< .))

    if (k_cov > 0 && length(valid_idx) > 0) {
        valid_idx = select(valid_idx, rowmissing(X_use[valid_idx, .]) :== 0)
    }

    if (length(valid_idx) == 0) {
        return(J(0, 1, .))
    }

    return(idx[valid_idx])
}

/*---------------------------------------------------------------------------
 * _raw_placebo_support_idx() - Rows used by raw placebo OLS
 *
 * Reconstructs the listwise-deletion sample for a single raw placebo lag.
 * The returned indices are positions in the current Y/Gi/time_std vectors.
 *---------------------------------------------------------------------------*/
real colvector _raw_placebo_support_idx(real colvector Y,
                                        real colvector Gi,
                                        real colvector time_std,
                                        real matrix X,
                                        real scalar lag)
{
    real colvector idx, Y_use, Gi_use, time_use, It, valid_idx
    real matrix X_use
    real scalar k_cov

    idx = selectindex((time_std :== -lag) :| (time_std :== -lag - 1))
    if (length(idx) == 0) {
        return(J(0, 1, .))
    }

    Y_use = Y[idx]
    Gi_use = Gi[idx]
    time_use = time_std[idx]
    It = (time_use :>= -lag)
    k_cov = cols(X)

    if (k_cov > 0) {
        X_use = X[idx, .]
    }
    else {
        X_use = J(rows(idx), 0, .)
    }

    valid_idx = selectindex((Y_use :< .) :& (Gi_use :< .) :& (It :< .))

    if (k_cov > 0 && length(valid_idx) > 0) {
        valid_idx = select(valid_idx, rowmissing(X_use[valid_idx, .]) :== 0)
    }

    if (length(valid_idx) == 0) {
        return(J(0, 1, .))
    }

    return(idx[valid_idx])
}

/*---------------------------------------------------------------------------
 * _warn_lag0_placebo() - Emit lag(0) placebo interpretation warning once
 *
 * The lag(0) note is user-facing command guidance, not iteration-level state.
 * It should be printed once per command execution, not once per bootstrap draw
 * or once per staggered-adoption cohort loop.
 *---------------------------------------------------------------------------*/
void _warn_lag0_placebo(real rowvector lags, real scalar quiet)
{
    if (quiet == 0 && any(lags :== 0)) {
        printf("{txt}Warning: lag=0 tests treatment period vs pre-period, not a true placebo test\n")
    }
}

/*---------------------------------------------------------------------------
 * _ols_did_coef() - Extract DID Coefficient via OLS
 *
 * Constructs design matrix [1, Gi, It, Gi*It, X] and extracts the
 * interaction coefficient. Listwise deletion handles missing values.
 *
 * Arguments:
 *   Y  : real colvector - outcome variable
 *   Gi : real colvector - group indicator
 *   It : real colvector - time indicator
 *   X  : real matrix - covariates 
 *
 * Returns:
 *   real scalar: coefficient on Gi*It interaction term
 *---------------------------------------------------------------------------*/
real scalar _ols_did_coef(real colvector Y, real colvector Gi, 
                          real colvector It, real matrix X)
{
    real matrix design
    real colvector valid_idx
    real scalar n, n_valid, k_cov
    
    n = rows(Y)
    k_cov = cols(X)
    
    // Listwise deletion: exclude missing observations
    valid_idx = selectindex((Y :< .) :& (Gi :< .) :& (It :< .))
    
    if (k_cov > 0 && length(valid_idx) > 0) {
        valid_idx = select(valid_idx, rowmissing(X[valid_idx, .]) :== 0)
    }
    
    n_valid = length(valid_idx)
    
    if (n_valid == 0) {
        return(.)
    }
    
    // Construct design matrix: [1, Gi, It, Gi*It, X]
    design = J(n_valid, 1, 1), Gi[valid_idx], It[valid_idx], Gi[valid_idx] :* It[valid_idx]
    
    if (k_cov > 0) {
        design = design, X[valid_idx, .]
    }
    
    return(ols_coef(design, Y[valid_idx], 4))
}

/*---------------------------------------------------------------------------
 * did_placebo_boot() - Single Bootstrap Iteration for Placebo Tests
 *
 * Performs one cluster bootstrap iteration for placebo test inference.
 *
 * Arguments:
 *   data        : struct did_data - data structure
 *   cluster_ids : real colvector - cluster identifiers
 *   cluster_var : real colvector - cluster membership
 *   lags        : real rowvector - lag parameters
 *   is_panel    : real scalar - data type indicator
 *
 * Returns:
 *   struct placebo_result with bootstrap estimates
 *
 * Algorithm:
 *   1. Sample clusters with replacement
 *   2. Construct bootstrap dataset preserving within-cluster structure
 *   3. Renumber unit IDs in bootstrap sample
 *   4. Compute placebo estimates on bootstrap sample
 *---------------------------------------------------------------------------*/
struct placebo_result scalar did_placebo_boot(struct did_data scalar data,
                                              real colvector cluster_ids,
                                              real colvector cluster_var,
                                              real rowvector lags,
                                              real scalar is_panel)
{
    struct placebo_result scalar result
    real colvector id_boot, idx, new_id_unit
    real colvector Y_boot, Gi_boot, time_std_boot
    real matrix X_boot
    real scalar n_clusters, i, j, k, n_obs, k_cov
    
    n_clusters = rows(cluster_ids)
    k_cov = cols(data.covariates)
    
    // Sample clusters with replacement
    id_boot = cluster_ids[safe_sample_idx(n_clusters, n_clusters)]
    
    // Count total observations
    n_obs = 0
    for (j = 1; j <= n_clusters; j++) {
        idx = selectindex(cluster_var :== id_boot[j])
        n_obs = n_obs + length(idx)
    }
    
    // Allocate bootstrap arrays
    Y_boot = J(n_obs, 1, .)
    Gi_boot = J(n_obs, 1, .)
    time_std_boot = J(n_obs, 1, .)
    new_id_unit = J(n_obs, 1, .)
    if (k_cov > 0) {
        X_boot = J(n_obs, k_cov, .)
    }
    else {
        X_boot = J(0, 0, .)
    }
    
    // Second pass: fill bootstrap data
    k = 1
    for (j = 1; j <= n_clusters; j++) {
        idx = selectindex(cluster_var :== id_boot[j])
        
        if (length(idx) > 0) {
            // Copy data for this cluster
            Y_boot[|k \ k + length(idx) - 1|] = data.outcome[idx]
            Gi_boot[|k \ k + length(idx) - 1|] = data.Gi[idx]
            time_std_boot[|k \ k + length(idx) - 1|] = data.id_time_std[idx]
            
            // Renumber id_unit for bootstrap sample
            new_id_unit[|k \ k + length(idx) - 1|] = J(length(idx), 1, j)
            
            // Copy covariates if present
            if (k_cov > 0) {
                X_boot[|k, 1 \ k + length(idx) - 1, k_cov|] = data.covariates[idx, .]
            }
            
            k = k + length(idx)
        }
    }
    
    // Compute placebo estimates on bootstrap sample
    result = did_placebo(Y_boot, Gi_boot, time_std_boot, X_boot, lags)
    
    return(result)
}

/*---------------------------------------------------------------------------
 * did_placebo_boot_full() - Complete Bootstrap SE Computation
 *
 * Performs n_boot bootstrap iterations and computes standard errors.
 * Failed iterations are tracked and excluded from variance computation.
 *
 * Arguments:
 *   data     : struct did_data - data structure
 *   lags     : real rowvector - lag parameters
 *   n_boot   : real scalar - number of bootstrap iterations
 *   is_panel : real scalar - data type indicator
 *   cluster  : string scalar - cluster variable name (optional)
 *
 * Returns:
 *   struct placebo_boot_result with standard errors and estimates
 *---------------------------------------------------------------------------*/
struct placebo_boot_result scalar did_placebo_boot_full(
    struct did_data scalar data,
    real rowvector lags,
    real scalar n_boot,
    real scalar is_panel,
    string scalar cluster)
{
    struct placebo_boot_result scalar result
    struct placebo_result scalar boot_est
    real matrix boot_est_mat, boot_est_std_mat
    real colvector valid_idx, cluster_ids, cluster_var
    real colvector valid_rows, col_data
    real scalar b, n_valid, n_lags, i, lag_idx
    
    // Handle cluster variable
    if (cluster == "" & is_panel) {
        cluster_var = data.id_unit
    }
    else if (cluster == "") {
        cluster_var = (1::rows(data.outcome))
    }
    else {
        cluster_var = data.cluster_var
    }
    
    cluster_ids = unique_in_order(select(cluster_var, cluster_var :< .))
    
    // Pre-allocate result matrices
    n_lags = cols(lags)
    boot_est_mat = J(n_boot, n_lags, .)
    boot_est_std_mat = J(n_boot, n_lags, .)
    valid_idx = J(n_boot, 1, 0)

    // Bootstrap loop. Each iteration forms both the raw and the standardized
    // pre-treatment contrast from the resampled data, matching the reference
    // R implementation (DIDdesign): the bootstrap SE of the standardized
    // estimator therefore captures sampling variability in both the contrast
    // numerator and the standardization scale 1/sigma_hat_0.
    for (b = 1; b <= n_boot; b++) {
        boot_est = did_placebo_boot(data, cluster_ids, cluster_var, lags, is_panel)
        
        if (rows(boot_est.lags) > 0) {
            for (i = 1; i <= rows(boot_est.lags); i++) {
                lag_idx = _find_lag_position(lags, boot_est.lags[i])
                if (lag_idx > 0) {
                    boot_est_mat[b, lag_idx] = boot_est.est[i]
                    boot_est_std_mat[b, lag_idx] = boot_est.est_std[i]
                }
            }
            valid_idx[b] = 1
        }
    }
    
    // Remove invalid iterations
    n_valid = sum(valid_idx)
    
    if (n_valid > 0) {
        valid_rows = selectindex(valid_idx)
        boot_est_mat = boot_est_mat[valid_rows, .]
        boot_est_std_mat = boot_est_std_mat[valid_rows, .]
    }
    else {
        // All iterations failed
        boot_est_mat = J(0, n_lags, .)
        boot_est_std_mat = J(0, n_lags, .)
    }
    
    // Compute standard errors (using n-1 denominator)
    result.se = J(n_lags, 1, .)
    result.se_std = J(n_lags, 1, .)
    
    if (n_valid > 1) {
        for (i = 1; i <= n_lags; i++) {
            col_data = boot_est_mat[., i]
            col_data = select(col_data, col_data :< .)  // Remove missing values
            if (rows(col_data) > 1) {
                result.se[i] = sqrt(variance(col_data))
            }
            
            col_data = boot_est_std_mat[., i]
            col_data = select(col_data, col_data :< .)  // Remove missing values
            if (rows(col_data) > 1) {
                result.se_std[i] = sqrt(variance(col_data))
            }
        }
    }
    
    result.n_valid = n_valid
    result.boot_est = boot_est_mat
    result.boot_est_std = boot_est_std_mat
    
    return(result)
}

/*---------------------------------------------------------------------------
 * _find_lag_position() - Find position of lag value in lags vector
 *
 * Maps bootstrap results to lag positions.
 *
 * Arguments:
 *   lags    : real rowvector, original lag values
 *   lag_val : real scalar, lag value to find
 *
 * Returns:
 *   real scalar: position (1-indexed), or 0 if not found
 *---------------------------------------------------------------------------*/
real scalar _find_lag_position(real rowvector lags, real scalar lag_val)
{
    real scalar i, n, tol
    
    // Use tolerance comparison for floating-point robustness
    tol = 1e-10
    
    n = cols(lags)
    for (i = 1; i <= n; i++) {
        if (abs(abs(lags[i]) - abs(lag_val)) < tol) {
            return(i)
        }
    }
    return(0)
}

/*---------------------------------------------------------------------------
 * _boot_valid_counts() - Count Non-missing Bootstrap Draws by Lag
 *
 * Returns a n_lags x 2 matrix. Column 1 counts non-missing standardized
 * bootstrap draws; column 2 counts non-missing raw bootstrap draws.
 *---------------------------------------------------------------------------*/
real matrix _boot_valid_counts(real matrix boot_est_std,
                               real matrix boot_est_raw)
{
    real scalar n_lags, i
    real matrix counts
    real colvector col_data

    n_lags = max((cols(boot_est_std), cols(boot_est_raw)))
    counts = J(n_lags, 2, 0)

    for (i = 1; i <= n_lags; i++) {
        if (cols(boot_est_std) >= i) {
            col_data = boot_est_std[., i]
            counts[i, 1] = rows(select(col_data, col_data :< .))
        }
        if (cols(boot_est_raw) >= i) {
            col_data = boot_est_raw[., i]
            counts[i, 2] = rows(select(col_data, col_data :< .))
        }
    }

    return(counts)
}

/*---------------------------------------------------------------------------
 * _posted_placebo_joint_vcov() - Joint-valid VCOV for posted placebo vector
 *
 * Rebuilds the public covariance matrix for the standardized placebo vector
 * using exactly the subset of lags jointly posted in e(b).
 *---------------------------------------------------------------------------*/
real matrix _posted_placebo_joint_vcov(real matrix boot_est_std,
                                       real colvector est_std,
                                       real colvector se_std,
                                       real colvector est_raw,
                                       real colvector se_raw)
{
    real colvector posted_idx
    real matrix boot_posted

    posted_idx = selectindex((est_std :< .) :& (se_std :< .) :&
                             (est_raw :< .) :& (se_raw :< .))

    if (rows(posted_idx) == 0) {
        return(J(0, 0, .))
    }

    boot_posted = boot_est_std[., posted_idx]
    return(compute_vcov_joint_valid(boot_posted))
}

/*---------------------------------------------------------------------------
 * did_sad_placebo() - Staggered Adoption Design Placebo Tests
 *
 * Computes time-weighted placebo estimates aggregated across treatment
 * cohorts for staggered adoption designs. Infeasible periods are excluded
 * and weights are renormalized to sum to unity.
 *
 * Arguments:
 *   data   : struct did_data - panel data structure
 *   option : struct did_option - estimation options
 *
 * Returns:
 *   struct sa_placebo_result containing:
 *     - estimates[,1]: standardized placebo estimates
 *     - estimates[,2]: raw placebo estimates
 *     - Gmat: treatment timing matrix
 *
 * Algorithm:
 *   1. Construct Gmat (treatment timing indicator matrix)
 *   2. Identify valid treatment periods via threshold criterion
 *   3. For each valid period t:
 *      a. Subset to units treated at t and their controls
 *      b. Compute period-specific placebo estimates
 *   4. Aggregate using time weights with renormalization
 *---------------------------------------------------------------------------*/
struct sa_placebo_result scalar did_sad_placebo(struct did_data scalar data,
                                                 struct did_option scalar option)
{
    struct sa_placebo_result scalar result
    struct placebo_result scalar placebo_tmp
    real matrix Gmat, est_did, est_did_std, treated_count, treated_count_std
    real colvector id_time_use
    pointer vector id_subj_use
    real scalar n_periods, n_lags, i, j, lag_idx
    real colvector Y_use, Gi_use, time_std_use
    real colvector support_unit_ids, support_Gi
    real matrix X_use
    real colvector idx, idx_subj, lag_idx_use
    real scalar t, n_use, lag_val
    
    // Initialize result
    n_lags = cols(option.lag)
    result.estimates = J(n_lags, 2, .)
    result.valid_lags = option.lag
    result.has_valid_periods = 1
    result.support_mask_std = J(rows(data.outcome), n_lags, 0)
    result.support_mask_raw = J(rows(data.outcome), n_lags, 0)
    
    // Create Gmat (group indicator matrix)
    Gmat = create_gmat(data.id_unit, data.id_time, data.treatment)
    result.Gmat = Gmat
    
    if (rows(Gmat) == 0 || cols(Gmat) == 0) {
        result.estimates = J(0, 2, .)
        result.valid_lags = J(1, 0, .)
        result.has_valid_periods = 0
        return(result)
    }
    
    // Get valid periods
    id_time_use = get_periods(Gmat, option.thres)
    
    if (rows(id_time_use) == 0) {
        result.estimates = J(0, 2, .)
        result.valid_lags = J(1, 0, .)
        result.has_valid_periods = 0
        return(result)
    }
    
    // Get valid subjects for each period
    id_subj_use = get_subjects(Gmat, id_time_use)
    
    n_periods = rows(id_time_use)
    
    // Initialize period-specific estimate matrices
    est_did = J(n_periods, n_lags, .)
    est_did_std = J(n_periods, n_lags, .)
    treated_count = J(n_periods, n_lags, 0)
    treated_count_std = J(n_periods, n_lags, 0)
    
    // For each valid period, compute placebo estimates
    for (i = 1; i <= n_periods; i++) {
        t = id_time_use[i]
        idx_subj = *id_subj_use[i]
        
        // Subset data: units in id_subj_use[i], times <= t
        idx = _sa_placebo_subset_idx(data, idx_subj, t)
        
        if (length(idx) == 0) {
            continue
        }
        
        Y_use = data.outcome[idx]
        n_use = rows(Y_use)
        
        // Compute Gi and id_time_std for subset
        _sa_placebo_compute_Gi_time_std(data, idx, idx_subj, t, Gmat, &Gi_use, &time_std_use)
        
        if (cols(data.covariates) > 0) {
            X_use = data.covariates[idx, .]
        }
        else {
            X_use = J(n_use, 0, .)
        }
        
        // Run placebo regression
        placebo_tmp = did_placebo(Y_use, Gi_use, time_std_use, X_use, option.lag)
        
        // Store results (handle infeasible lags via lag name matching)
        for (j = 1; j <= rows(placebo_tmp.lags); j++) {
            lag_idx = _find_lag_position(option.lag, placebo_tmp.lags[j])
            if (lag_idx > 0) {
                est_did[i, lag_idx] = placebo_tmp.est[j]
                est_did_std[i, lag_idx] = placebo_tmp.est_std[j]
                if (placebo_tmp.est[j] < .) {
                    lag_val = placebo_tmp.lags[j]
                    lag_idx_use = _raw_placebo_support_idx(Y_use, Gi_use, time_std_use, X_use, lag_val)
                    if (rows(lag_idx_use) > 0) {
                        result.support_mask_raw[idx[lag_idx_use], lag_idx] = J(rows(lag_idx_use), 1, 1)
                        support_unit_ids = data.id_unit[idx[lag_idx_use]]
                        support_Gi = Gi_use[lag_idx_use]
                        treated_count[i, lag_idx] = rows(uniqrows(select(support_unit_ids, support_Gi :== 1)))
                    }
                }
                if (placebo_tmp.est_std[j] < .) {
                    lag_val = placebo_tmp.lags[j]
                    lag_idx_use = _std_placebo_support_idx(Y_use, Gi_use, time_std_use, X_use, lag_val)
                    if (rows(lag_idx_use) > 0) {
                        result.support_mask_std[idx[lag_idx_use], lag_idx] = J(rows(lag_idx_use), 1, 1)
                        support_unit_ids = data.id_unit[idx[lag_idx_use]]
                        support_Gi = Gi_use[lag_idx_use]
                        treated_count_std[i, lag_idx] = rows(uniqrows(select(support_unit_ids, support_Gi :== 1)))
                    }
                }
            }
        }
    }

    // Aggregate over adoption periods using lag-specific effective treated counts.
    result.estimates[., 1] = _agg_placebo_counts(est_did_std, treated_count_std)'
    result.estimates[., 2] = _agg_placebo_counts(est_did, treated_count)'
    
    return(result)
}

/*---------------------------------------------------------------------------
 * _sa_placebo_period_raw_matrix() - Period-by-Lag Raw Placebo Surface
 *---------------------------------------------------------------------------*/
real matrix _sa_placebo_period_raw_matrix(struct did_data scalar data,
                                          real matrix Gmat,
                                          real colvector id_time_use,
                                          pointer vector id_subj_use,
                                          struct did_option scalar option)
{
    real matrix raw_mat
    real scalar i, j, lag_idx, t, n_use
    real colvector idx, idx_subj, Y_use, Gi_use, time_std_use
    real matrix X_use
    struct placebo_result scalar placebo_tmp

    raw_mat = J(rows(id_time_use), cols(option.lag), .)

    for (i = 1; i <= rows(id_time_use); i++) {
        t = id_time_use[i]
        idx_subj = *id_subj_use[i]
        idx = _sa_placebo_subset_idx(data, idx_subj, t)
        if (rows(idx) == 0) {
            continue
        }

        n_use = rows(idx)
        Y_use = data.outcome[idx]
        _sa_placebo_compute_Gi_time_std(data, idx, idx_subj, t, Gmat, &Gi_use, &time_std_use)

        if (cols(data.covariates) > 0) {
            X_use = data.covariates[idx, .]
        }
        else {
            X_use = J(n_use, 0, .)
        }

        placebo_tmp = did_placebo(Y_use, Gi_use, time_std_use, X_use, option.lag)
        for (j = 1; j <= rows(placebo_tmp.lags); j++) {
            lag_idx = _find_lag_position(option.lag, placebo_tmp.lags[j])
            if (lag_idx > 0) {
                raw_mat[i, lag_idx] = placebo_tmp.est[j]
            }
        }
    }

    return(raw_mat)
}

/*---------------------------------------------------------------------------
 * _sa_placebo_rs_matrices() - Joint Raw and Standardized Surfaces
 *
 * Returns, as a (2 x 1) pointer vector, the period-by-lag matrices for the
 * raw and standardized placebo DID estimates in a single sweep. Each cell
 * (i, lag_idx) stores the placebo statistic evaluated on the cohort-period
 * subsample, so the standardized surface is standardized by the within-sample
 * control-group baseline SD rather than by any externally fixed scale. This
 * shared-pass construction is used by the SA bootstrap to guarantee that the
 * resampled standardized contrast is formed entirely from the resampled data.
 *---------------------------------------------------------------------------*/
pointer vector _sa_placebo_rs_matrices(struct did_data scalar data,
                                                   real matrix Gmat,
                                                   real colvector id_time_use,
                                                   pointer vector id_subj_use,
                                                   struct did_option scalar option)
{
    pointer vector out
    real matrix raw_mat, std_mat
    real scalar i, j, lag_idx, t, n_use
    real colvector idx, idx_subj, Y_use, Gi_use, time_std_use
    real matrix X_use
    struct placebo_result scalar placebo_tmp

    raw_mat = J(rows(id_time_use), cols(option.lag), .)
    std_mat = J(rows(id_time_use), cols(option.lag), .)

    for (i = 1; i <= rows(id_time_use); i++) {
        t = id_time_use[i]
        idx_subj = *id_subj_use[i]
        idx = _sa_placebo_subset_idx(data, idx_subj, t)
        if (rows(idx) == 0) {
            continue
        }

        n_use = rows(idx)
        Y_use = data.outcome[idx]
        _sa_placebo_compute_Gi_time_std(data, idx, idx_subj, t, Gmat, &Gi_use, &time_std_use)

        if (cols(data.covariates) > 0) {
            X_use = data.covariates[idx, .]
        }
        else {
            X_use = J(n_use, 0, .)
        }

        placebo_tmp = did_placebo(Y_use, Gi_use, time_std_use, X_use, option.lag)
        for (j = 1; j <= rows(placebo_tmp.lags); j++) {
            lag_idx = _find_lag_position(option.lag, placebo_tmp.lags[j])
            if (lag_idx > 0) {
                raw_mat[i, lag_idx] = placebo_tmp.est[j]
                std_mat[i, lag_idx] = placebo_tmp.est_std[j]
            }
        }
    }

    out = J(2, 1, NULL)
    out[1] = &raw_mat
    out[2] = &std_mat
    return(out)
}

/*---------------------------------------------------------------------------
 * _sa_placebo_treat_counts() - Effective treated counts by lag
 *---------------------------------------------------------------------------*/
real matrix _sa_placebo_treat_counts(struct did_data scalar data,
                                     real matrix Gmat,
                                     real colvector id_time_use,
                                     pointer vector id_subj_use,
                                     struct did_option scalar option)
{
    real matrix count_mat
    real scalar i, j, lag_idx, t, n_use
    real colvector idx, idx_subj, Y_use, Gi_use, time_std_use, lag_idx_use
    real colvector support_unit_ids, support_Gi
    real matrix X_use
    struct placebo_result scalar placebo_tmp

    count_mat = J(rows(id_time_use), cols(option.lag), 0)

    for (i = 1; i <= rows(id_time_use); i++) {
        t = id_time_use[i]
        idx_subj = *id_subj_use[i]
        idx = _sa_placebo_subset_idx(data, idx_subj, t)
        if (rows(idx) == 0) {
            continue
        }

        n_use = rows(idx)
        Y_use = data.outcome[idx]
        _sa_placebo_compute_Gi_time_std(data, idx, idx_subj, t, Gmat, &Gi_use, &time_std_use)

        if (cols(data.covariates) > 0) {
            X_use = data.covariates[idx, .]
        }
        else {
            X_use = J(n_use, 0, .)
        }

        placebo_tmp = did_placebo(Y_use, Gi_use, time_std_use, X_use, option.lag)
        for (j = 1; j <= rows(placebo_tmp.lags); j++) {
            lag_idx = _find_lag_position(option.lag, placebo_tmp.lags[j])
            if (lag_idx > 0 && placebo_tmp.est[j] < .) {
                lag_idx_use = _raw_placebo_support_idx(Y_use, Gi_use, time_std_use, X_use, placebo_tmp.lags[j])
                if (rows(lag_idx_use) > 0) {
                    support_unit_ids = data.id_unit[idx[lag_idx_use]]
                    support_Gi = Gi_use[lag_idx_use]
                    count_mat[i, lag_idx] = rows(uniqrows(select(support_unit_ids, support_Gi :== 1)))
                }
            }
        }
    }

    return(count_mat)
}

/*---------------------------------------------------------------------------
 * _aggregate_placebo_periods() - Time-Weighted Aggregation over Valid Periods
 *---------------------------------------------------------------------------*/
real rowvector _aggregate_placebo_periods(real matrix period_mat,
                                          real colvector time_weight)
{
    real rowvector out
    real scalar j
    real colvector valid_idx, w_use

    out = J(1, cols(period_mat), .)
    for (j = 1; j <= cols(period_mat); j++) {
        valid_idx = selectindex(period_mat[., j] :< .)
        if (rows(valid_idx) == 0) {
            continue
        }
        w_use = time_weight[valid_idx]
        if (sum(w_use) <= 0) {
            continue
        }
        w_use = w_use / sum(w_use)
        out[j] = sum(period_mat[valid_idx, j] :* w_use)
    }

    return(out)
}

/*---------------------------------------------------------------------------
 * _agg_placebo_counts() - Aggregate with effective treated counts
 *---------------------------------------------------------------------------*/
real rowvector _agg_placebo_counts(real matrix period_mat,
                                   real matrix treated_count_mat)
{
    real rowvector out
    real scalar j
    real colvector valid_idx, w_use

    out = J(1, cols(period_mat), .)
    for (j = 1; j <= cols(period_mat); j++) {
        valid_idx = selectindex((period_mat[., j] :< .) :& (treated_count_mat[., j] :> 0))
        if (rows(valid_idx) == 0) {
            continue
        }
        w_use = treated_count_mat[valid_idx, j]
        if (sum(w_use) <= 0) {
            continue
        }
        w_use = w_use / sum(w_use)
        out[j] = sum(period_mat[valid_idx, j] :* w_use)
    }

    return(out)
}

/*---------------------------------------------------------------------------
 * _sa_placebo_subset_idx() - Subset Indices for Staggered Adoption
 *
 * Returns observation indices satisfying:
 *   - Unit is in the valid subject set for this period
 *   - Time is at or before the current period t
 *
 * Arguments:
 *   data     : struct did_data - full panel data
 *   idx_subj : real colvector - valid unit indices (rows in Gmat)
 *   t        : real scalar - current period (column in Gmat)
 *
 * Returns:
 *   real colvector: observation row indices
 *---------------------------------------------------------------------------*/
real colvector _sa_placebo_subset_idx(struct did_data scalar data,
                                       real colvector idx_subj,
                                       real scalar t)
{
    real colvector units, valid_units, idx
    real scalar N, i
    real colvector is_valid_unit, is_valid_time
    transmorphic scalar valid_set
    
    N = rows(data.outcome)
    
    // Get unique unit IDs
    units = uniqrows(data.id_unit)
    
    // Validate idx_subj bounds before array access
    if (rows(idx_subj) > 0) {
        if (max(idx_subj) > rows(units) || min(idx_subj) < 1) {
            errprintf("Error: _sa_placebo_subset_idx(): idx_subj contains out-of-bounds indices\n")
            errprintf("       idx_subj range: [%g, %g], units count: %g\n", 
                      min(idx_subj), max(idx_subj), rows(units))
            return(J(0, 1, .))
        }
    }
    
    // Get valid unit IDs
    valid_units = units[idx_subj]
    
    // Build valid_units set for O(1) lookup
    valid_set = asarray_create("real", 1)
    for (i = 1; i <= rows(valid_units); i++) {
        asarray(valid_set, valid_units[i], 1)
    }
    
    // Create indicator for valid units in O(N)
    is_valid_unit = J(N, 1, 0)
    for (i = 1; i <= N; i++) {
        if (asarray_contains(valid_set, data.id_unit[i])) {
            is_valid_unit[i] = 1
        }
    }
    
    // Create indicator for valid times (time <= t)
    is_valid_time = (data.id_time :<= t)
    
    // Return indices where both conditions are met
    idx = selectindex(is_valid_unit :& is_valid_time)
    
    return(idx)
}

/*---------------------------------------------------------------------------
 * _sa_placebo_compute_Gi_time_std() - Compute Group and Time Indicators
 *
 * For the data subset, computes treatment group indicator and
 * standardized time relative to treatment period.
 *
 * Arguments:
 *   data         : struct did_data - full panel data
 *   idx          : real colvector - observation row indices
 *   idx_subj     : real colvector - valid unit indices (rows in Gmat)
 *   t            : real scalar - current treatment period
 *   Gmat         : real matrix - treatment timing indicator matrix
 *   Gi           : pointer(real colvector) - output group indicator
 *   id_time_std  : pointer(real colvector) - output standardized time
 *
 * Output:
 *   Gi = 1 if unit is newly treated at t, 0 if control
 *   id_time_std = id_time - t (time relative to treatment)
 *---------------------------------------------------------------------------*/
void _sa_placebo_compute_Gi_time_std(struct did_data scalar data,
                                      real colvector idx,
                                      real colvector idx_subj,
                                      real scalar t,
                                      real matrix Gmat,
                                      pointer(real colvector) scalar Gi,
                                      pointer(real colvector) scalar id_time_std)
{
    real scalar n_obs, i, u, unit_idx
    real colvector units, valid_units
    transmorphic scalar unit_idx_map
    
    n_obs = rows(idx)
    *Gi = J(n_obs, 1, .)
    *id_time_std = J(n_obs, 1, .)
    
    // Get unique units and valid units
    units = uniqrows(data.id_unit)
    valid_units = units[idx_subj]
    
    // Build unit index map for O(1) lookup
    unit_idx_map = asarray_create("real", 1)
    for (i = 1; i <= rows(units); i++) {
        asarray(unit_idx_map, units[i], i)
    }
    
    for (i = 1; i <= n_obs; i++) {
        u = data.id_unit[idx[i]]
        
        // Find unit index in Gmat using asarray (O(1) lookup)
        if (asarray_contains(unit_idx_map, u)) {
            unit_idx = asarray(unit_idx_map, u)
            
            if (unit_idx > 0 && unit_idx <= rows(Gmat)) {
                // Gi = 1 if Gmat[unit, t] == 1 (newly treated at t)
                // Gi = 0 if Gmat[unit, t] == 0 (control)
                (*Gi)[i] = (Gmat[unit_idx, t] == 1) ? 1 : 0
                
                // id_time_std = id_time - t
                (*id_time_std)[i] = data.id_time[idx[i]] - t
            }
        }
    }
}

/*---------------------------------------------------------------------------
 * did_sad_placebo_boot() - Bootstrap SE for Staggered Adoption Placebo
 *
 * Computes cluster-bootstrap standard errors for staggered adoption
 * placebo tests. Failed iterations are excluded from variance computation.
 *
 * Arguments:
 *   data   : struct did_data - panel data structure
 *   option : struct did_option - estimation options including n_boot
 *
 * Returns:
 *   struct sa_placebo_boot_result containing:
 *     - se_std, se_orig: bootstrap standard errors
 *     - boot_est_std, boot_est_orig: bootstrap estimate matrices
 *     - n_valid: count of successful iterations
 *
 * Algorithm:
 *   1. For each bootstrap iteration:
 *      a. Sample units with replacement
 *      b. Compute staggered adoption placebo estimates
 *      c. Validate and store results
 *   2. Compute SE as sample standard deviation of valid estimates
 *---------------------------------------------------------------------------*/
struct sa_placebo_boot_result scalar did_sad_placebo_boot(
    struct did_data scalar data,
    struct did_option scalar option)
{
    struct sa_placebo_boot_result scalar result
    struct did_data scalar boot_data
    real matrix boot_est_std, boot_est_orig
    real scalar n_boot, n_lags, b, j
    real colvector col_data
    
    n_boot = option.n_boot
    n_lags = cols(option.lag)
    
    // Initialize result
    result.n_boot = n_boot
    result.se_std = J(n_lags, 1, .)
    result.se_orig = J(n_lags, 1, .)
    
    // Pre-allocate bootstrap estimate matrices
    boot_est_std = J(n_boot, n_lags, .)
    boot_est_orig = J(n_boot, n_lags, .)

    // Bootstrap loop with validation
    real scalar valid_count, progress_freq
    valid_count = 0
    
    // Progress display frequency
    progress_freq = max((1, floor(n_boot / 10)))
    
    for (b = 1; b <= n_boot; b++) {
        // Progress display (controlled by quiet option)
        if (option.quiet == 0 && mod(b, progress_freq) == 0) {
            printf("{txt}Bootstrap: %g/%g (%g%%)\n", b, n_boot, round(100*b/n_boot))
            displayflush()
        }
        
        // Sample panel data with replacement (unit-level)
        boot_data = sample_panel(data)

        // Form the raw and standardized period-by-lag surfaces jointly on
        // the resampled panel. Standardization uses the resampled cohort's
        // own control-group baseline SD, matching the reference R
        // implementation and yielding a bootstrap SE for the standardized
        // estimator that captures variability in both the contrast and the
        // standardization scale.
        real matrix Gmat_boot, raw_boot, std_boot, treated_count_boot
        real colvector periods_boot
        pointer vector subj_boot, rs_pair
        real rowvector agg_raw_boot, agg_std_boot
        real scalar any_lag_valid

        any_lag_valid = 0
        Gmat_boot = create_gmat(boot_data.id_unit, boot_data.id_time, boot_data.treatment)
        periods_boot = get_periods(Gmat_boot, option.thres)
        if (rows(periods_boot) > 0) {
            subj_boot = get_subjects(Gmat_boot, periods_boot)
            rs_pair = _sa_placebo_rs_matrices(boot_data, Gmat_boot, periods_boot, subj_boot, option)
            raw_boot = *rs_pair[1]
            std_boot = *rs_pair[2]
            treated_count_boot = _sa_placebo_treat_counts(boot_data, Gmat_boot, periods_boot, subj_boot, option)

            agg_raw_boot = _agg_placebo_counts(raw_boot, treated_count_boot)
            agg_std_boot = _agg_placebo_counts(std_boot, treated_count_boot)
            boot_est_orig[b, .] = agg_raw_boot
            boot_est_std[b, .] = agg_std_boot
            any_lag_valid = any((agg_std_boot :< .) :| (agg_raw_boot :< .))
        }
        
        if (any_lag_valid) {
            valid_count++
        }
    }
    
    // Final progress display
    if (option.quiet == 0) {
        printf("{txt}Bootstrap: %g/%g (100%%)\n", n_boot, n_boot)
        displayflush()
    }
    
    // Store valid count and warn if some iterations failed
    result.n_valid = valid_count
    
    if (valid_count < n_boot & option.quiet == 0) {
        printf("{txt}Warning: %g of %g staggered adoption placebo bootstrap iterations failed\n",
               n_boot - valid_count, n_boot)
    }
    
    // Remove invalid rows from bootstrap matrices
    if (valid_count > 0 && valid_count < n_boot) {
        real colvector valid_idx, valid_rows
        real scalar row_valid
        valid_idx = J(n_boot, 1, 0)
        for (b = 1; b <= n_boot; b++) {
            row_valid = any((boot_est_std[b, .] :< .) :| (boot_est_orig[b, .] :< .))
            valid_idx[b] = row_valid
        }
        valid_rows = selectindex(valid_idx)
        if (rows(valid_rows) > 0) {
            boot_est_std = boot_est_std[valid_rows, .]
            boot_est_orig = boot_est_orig[valid_rows, .]
        }
        else {
            boot_est_std = J(0, n_lags, .)
            boot_est_orig = J(0, n_lags, .)
        }
    }
    else if (valid_count == 0) {
        // All iterations failed
        boot_est_std = J(0, n_lags, .)
        boot_est_orig = J(0, n_lags, .)
    }
    
    // Store bootstrap estimates
    result.boot_est_std = boot_est_std
    result.boot_est_orig = boot_est_orig
    
    // Compute standard errors (using n-1 denominator)
    for (j = 1; j <= n_lags; j++) {
        col_data = boot_est_std[., j]
        col_data = select(col_data, col_data :< .)  // Remove missing values
        if (rows(col_data) > 1) {
            result.se_std[j] = sqrt(variance(col_data))
        }
        
        col_data = boot_est_orig[., j]
        col_data = select(col_data, col_data :< .)  // Remove missing values
        if (rows(col_data) > 1) {
            result.se_orig[j] = sqrt(variance(col_data))
        }
    }
    
    return(result)
}

// ----------------------------------------------------------------------------
// MODULE VERIFICATION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_check_loaded() - Module Load Verification
 *---------------------------------------------------------------------------*/
void _did_check_loaded()
{
    printf("{txt}did_check.mata loaded successfully\n")
}

/*---------------------------------------------------------------------------
 * _test_did_placebo() - Test Wrapper for did_placebo()
 *
 * Wrapper function for interactive testing that returns a matrix
 * instead of a struct for easier inspection.
 *
 * Arguments:
 *   Y        : real colvector - outcome variable
 *   Gi       : real colvector - group indicator
 *   time_std : real colvector - standardized time index
 *   lags     : real rowvector - lag periods to test
 *
 * Returns:
 *   real matrix (n_lags x 3): columns are [lag, est, est_std]
 *---------------------------------------------------------------------------*/
real matrix _test_did_placebo(real colvector Y, real colvector Gi,
                              real colvector time_std, real rowvector lags)
{
    struct placebo_result scalar res
    real matrix output
    real scalar i, n
    
    res = did_placebo(Y, Gi, time_std, J(rows(Y), 0, .), lags)
    
    n = rows(res.lags)
    if (n == 0) {
        return(J(0, 3, .))
    }
    
    output = J(n, 3, .)
    for (i = 1; i <= n; i++) {
        output[i, 1] = res.lags[i]
        output[i, 2] = res.est[i]
        output[i, 3] = res.est_std[i]
    }
    
    return(output)
}

/*---------------------------------------------------------------------------
 * _test_did_placebo_boot() - Test Wrapper for Bootstrap Functions
 *
 * Wrapper function for interactive testing of bootstrap SE computation.
 * Returns a matrix for easier inspection.
 *
 * Arguments:
 *   Y        : real colvector - outcome variable
 *   Gi       : real colvector - group indicator
 *   time_std : real colvector - standardized time index
 *   id_unit  : real colvector - unit identifier
 *   lags     : real rowvector - lag periods to test
 *   n_boot   : real scalar - number of bootstrap iterations
 *
 * Returns:
 *   real matrix (n_lags x 5): columns are [lag, est, est_std, se, se_std]
 *---------------------------------------------------------------------------*/
real matrix _test_did_placebo_boot(real colvector Y, real colvector Gi,
                                   real colvector time_std, real colvector id_unit,
                                   real rowvector lags, real scalar n_boot)
{
    struct did_data scalar data
    struct placebo_result scalar point_res
    struct placebo_boot_result scalar boot_res
    real matrix output
    real scalar i, n
    
    // Populate data structure
    data.outcome = Y
    data.Gi = Gi
    data.id_time_std = time_std
    data.id_unit = id_unit
    data.covariates = J(0, 0, .)
    data.cluster_var = J(0, 1, .)
    data.is_panel = 1
    
    // Get point estimates
    point_res = did_placebo(Y, Gi, time_std, J(rows(Y), 0, .), lags)
    
    // Get bootstrap SE
    boot_res = did_placebo_boot_full(data, lags, n_boot, 1, "")
    
    n = rows(point_res.lags)
    if (n == 0) {
        return(J(0, 5, .))
    }
    
    output = J(n, 5, .)
    for (i = 1; i <= n; i++) {
        output[i, 1] = point_res.lags[i]
        output[i, 2] = point_res.est[i]
        output[i, 3] = point_res.est_std[i]
        if (i <= rows(boot_res.se)) {
            output[i, 4] = boot_res.se[i]
            output[i, 5] = boot_res.se_std[i]
        }
    }
    
    return(output)
}

/*---------------------------------------------------------------------------
 * _diddesign_check_main() - Main Entry Point for diddesign_check
 *
 * Called from diddesign_check.ado to perform parallel trends diagnostics.
 * Reads data from Stata, computes placebo estimates and bootstrap SE,
 * and stores results in external global variables.
 *
 * Arguments:
 *   depvar      : string scalar - outcome variable name
 *   treatment   : string scalar - treatment variable name
 *   id_var      : string scalar - unit identifier variable name
 *   time_var    : string scalar - time variable name
 *   post_var    : string scalar - post-treatment indicator (RCS only)
 *   covars      : string scalar - covariate names (optional)
 *   cluster_var : string scalar - cluster variable name
 *   touse       : string scalar - sample marker variable name
 *   design      : string scalar - design type ("did" or "sa")
 *   lags        : real rowvector - lag values for placebo tests
 *   n_boot      : real scalar - number of bootstrap iterations
 *   thres       : real scalar - staggered adoption threshold
 *   is_panel    : real scalar - data type indicator
 *   quiet       : real scalar - suppress progress (1=yes, 0=no)
 *
 * Side Effects:
 *   Populates external globals: _check_placebo, _check_trends, _check_Gmat,
 *   _check_n_lags, _check_n_boot_valid, _check_filtered_lags
 *---------------------------------------------------------------------------*/
void _diddesign_check_main(
    string scalar depvar,
    string scalar treatment,
    string scalar id_var,
    string scalar time_var,
    string scalar post_var,
    string scalar covars,
    string scalar cluster_var,
    string scalar touse,
    string scalar design,
    real rowvector lags,
    real scalar n_boot,
    real scalar thres,
    real scalar is_panel,
    real scalar quiet
)
{
    // Declare external global result variables
    external real matrix _check_placebo
    external real matrix _check_trends
    external real matrix _check_Gmat
    external real matrix _check_posted_vcov
    external real matrix _check_n_boot_valid_lag
    external real scalar _check_n_lags
    external real scalar _check_n_boot_valid
    external real scalar _check_max_preperiods
    external real scalar _check_no_valid_periods
    external string scalar _check_filtered_lags
    
    struct did_data scalar data
    struct placebo_result scalar point_res
    struct placebo_boot_result scalar boot_res
    real matrix eq_ci, trends_data
    real colvector Y, D, id_unit, id_time, Gi, id_time_std
    real colvector cluster_col, It_post
    real matrix X
    string rowvector covar_list
    real scalar N, n_lags, i, max_lag
    real rowvector valid_lags, filtered_lags_vec
    string scalar filtered_str
    
    // Read data from Stata
    Y = st_data(., depvar, touse)
    D = st_data(., treatment, touse)
    id_time = st_data(., time_var, touse)
    N = rows(Y)
    
    // Handle panel vs RCS data
    if (is_panel) {
        id_unit = st_data(., id_var, touse)
    }
    else {
        // RCS data: use observation row numbers as pseudo-id
        id_unit = (1::N)
    }
    
    // Read post-treatment indicator for RCS data
    if (!is_panel && post_var != "") {
        It_post = st_data(., post_var, touse)
        It_post = normalize_binary01(It_post, 1e-6)
    }
    else {
        It_post = J(0, 1, .)
    }
    
    // Read covariates if specified
    if (covars != "") {
        covar_list = tokens(covars)
        X = st_data(., covar_list, touse)
    }
    else {
        X = J(N, 0, .)
    }
    
    // Read cluster variable if specified
    if (cluster_var != "") {
        cluster_col = st_data(., cluster_var, touse)
    }
    else {
        cluster_col = J(0, 1, .)
    }
    
    // Step 1.5: Normalize id_time to consecutive integers (1, 2, 3, ...)
    // This ensures lag filtering works correctly for any time scale
    {
        real colvector unique_times, id_time_norm
        real scalar n_times_uniq
        transmorphic scalar time_map
        
        unique_times = uniqrows(id_time)
        n_times_uniq = rows(unique_times)
        
        // Build hash map for O(1) lookup
        time_map = asarray_create("real", 1)
        for (i = 1; i <= n_times_uniq; i++) {
            asarray(time_map, unique_times[i], i)
        }
        
        // Map to normalized integers, preserving missing values
        id_time_norm = J(N, 1, .)
        for (i = 1; i <= N; i++) {
            if (id_time[i] >= .) {
                id_time_norm[i] = .
            }
            else {
                id_time_norm[i] = asarray(time_map, id_time[i])
            }
        }
        
        id_time = id_time_norm
    }
    
    // Step 1.6: Normalize id_unit for staggered adoption design (required for Gmat)
    if (design == "sa") {
        real colvector unique_units, id_unit_norm
        real scalar n_units_uniq
        transmorphic scalar unit_map
        
        unique_units = uniqrows(id_unit)
        n_units_uniq = rows(unique_units)
        
        unit_map = asarray_create("real", 1)
        for (i = 1; i <= n_units_uniq; i++) {
            asarray(unit_map, unique_units[i], i)
        }
        
        // Map to normalized integers, preserving missing values
        id_unit_norm = J(N, 1, .)
        for (i = 1; i <= N; i++) {
            if (id_unit[i] >= .) {
                id_unit_norm[i] = .
            }
            else {
                id_unit_norm[i] = asarray(unit_map, id_unit[i])
            }
        }
        
        id_unit = id_unit_norm
    }
    
    // Compute Gi (group indicator) and id_time_std (standardized time)
    if (is_panel) {
        // Panel: Gi = 1 if unit ever treated
        // id_time_std = time relative to treatment
        _compute_Gi_and_time_std(Y, D, id_unit, id_time, &Gi, &id_time_std)
    }
    else {
        // RCS: Gi = treatment indicator, id_time_std = time relative to treatment year
        _compute_Gi_and_time_std_rcs(D, id_time, It_post, &Gi, &id_time_std)
    }
    
    // -------------------------------------------------------------------------
    // Populate did_data structure
    // -------------------------------------------------------------------------
    data.outcome = Y
    data.treatment = D
    data.id_unit = id_unit
    data.id_time = id_time
    data.covariates = X
    data.Gi = Gi
    data.id_time_std = id_time_std
    data.N = N
    data.is_panel = is_panel
    
    if (rows(cluster_col) > 0) {
        data.cluster_var = cluster_col
    }
    else {
        data.cluster_var = J(0, 1, .)
    }
    
    // -------------------------------------------------------------------------
    // Filter lags and track filtered ones
    // -------------------------------------------------------------------------
    // Standard DID uses a single global event-time origin, so feasibility can
    // be determined from the full-sample pre-treatment span. Staggered
    // adoption placebo tests are cohort-specific; a late cohort may support a
    // requested lag even when the earliest cohort does not. For SA we defer
    // lag support checks to did_sad_placebo(), which evaluates each adoption
    // period separately.
    if (design == "sa") {
        max_lag = .
        valid_lags = lags
        filtered_lags_vec = J(1, 0, .)
    }
    else {
        max_lag = abs(min(id_time_std))
        valid_lags = select(lags, lags :< max_lag)
        filtered_lags_vec = select(lags, lags :>= max_lag)
    }
    
    // Build filtered lags string for warning
    filtered_str = ""
    if (cols(filtered_lags_vec) > 0) {
        for (i = 1; i <= cols(filtered_lags_vec); i++) {
            if (i > 1) filtered_str = filtered_str + " "
            filtered_str = filtered_str + strofreal(filtered_lags_vec[i])
        }
    }
    _check_filtered_lags = filtered_str
    _check_max_preperiods = max_lag
    _check_no_valid_periods = 0
    
    n_lags = cols(valid_lags)
    _check_n_lags = n_lags
    
    // Handle case with no valid lags
    if (n_lags == 0) {
        _check_placebo = J(0, 7, .)
        _check_trends = J(0, 5, .)
        _check_Gmat = J(0, 0, .)
        _check_n_boot_valid_lag = J(0, 2, .)
        _check_n_boot_valid = 0
        return
    }
    
    // Branch by design type
    if (design == "did") {
        _check_std_did(data, valid_lags, n_boot, cluster_var, quiet)
    }
    else if (design == "sa") {
        _check_sa_did(data, valid_lags, n_boot, thres, cluster_var, quiet)
    }
    else {
        errprintf("Error: Invalid design type '%s'. Expected 'did' or 'sa'.\n", design)
        _check_placebo = J(0, 7, .)
        _check_trends = J(0, 5, .)
        _check_Gmat = J(0, 0, .)
        _check_n_boot_valid_lag = J(0, 2, .)
        _check_n_boot_valid = 0
        return
    }
    
    // -------------------------------------------------------------------------
    // Compute trends data
    // -------------------------------------------------------------------------
    _check_trends = _compute_trends(Y, Gi, id_time_std)
}

/*---------------------------------------------------------------------------
 * _compute_Gi_and_time_std() - Compute Gi and Standardized Time (Panel)
 *
 * For panel data, computes group indicator and time relative to treatment.
 *
 * Arguments:
 *   Y           : real colvector - outcome variable
 *   D           : real colvector - treatment indicator
 *   id_unit     : real colvector - unit identifier
 *   id_time     : real colvector - time identifier
 *   Gi          : pointer(real colvector) - output group indicator
 *   id_time_std : pointer(real colvector) - output standardized time
 *
 * Output:
 *   Gi = 1 if unit ever treated, 0 otherwise
 *   id_time_std: time relative to the common treatment year (0 = treatment)
 *     - All units are aligned to min(time | D_it = 1), matching did_panel_data()
 *       in the reference R implementation and the main Stata diddesign path
 *---------------------------------------------------------------------------*/
void _compute_Gi_and_time_std(
    real colvector Y,
    real colvector D,
    real colvector id_unit,
    real colvector id_time,
    pointer(real colvector) scalar Gi,
    pointer(real colvector) scalar id_time_std
)
{
    // Optimized algorithm using asarray for O(N + n_units) complexity
    real scalar N, n_units, i, u, u_idx, treat_time, common_treat_time
    real colvector units, unit_treat_time, unit_Gi
    real colvector idx
    transmorphic scalar unit_idx_map, unit_to_pos
    
    N = rows(Y)
    units = uniqrows(id_unit)
    n_units = rows(units)
    
    // Build hash map: unit -> position in 'units' array
    unit_to_pos = asarray_create("real")
    for (i = 1; i <= n_units; i++) {
        asarray(unit_to_pos, units[i], i)
    }
    
    // Build observation index lists for each unit in O(N) time
    unit_idx_map = asarray_create("real")
    for (i = 1; i <= N; i++) {
        u = id_unit[i]
        u_idx = asarray(unit_to_pos, u)
        if (asarray_contains(unit_idx_map, u_idx)) {
            asarray(unit_idx_map, u_idx, asarray(unit_idx_map, u_idx) \ i)
        }
        else {
            asarray(unit_idx_map, u_idx, i)
        }
    }
    
    // Initialize unit-level arrays
    unit_treat_time = J(n_units, 1, .)  // Treatment time for each unit (. if never treated)
    unit_Gi = J(n_units, 1, 0)          // Group indicator for each unit
    
    // Find treatment time for each unit using pre-built index lists
    for (i = 1; i <= n_units; i++) {
        idx = asarray(unit_idx_map, i)
        
        // Check if unit ever treated
        if (any(D[idx] :== 1)) {
            // Find first treatment time
            treat_time = min(select(id_time[idx], D[idx] :== 1))
            unit_treat_time[i] = treat_time
            unit_Gi[i] = 1
        }
    }
    
    // Standard DID aligns every unit to the earliest treatment period observed
    // in the sample, not to cohort-specific event time.
    common_treat_time = min(select(unit_treat_time, unit_Gi :== 1))

    // Handle case where no units are treated
    if (missing(common_treat_time)) {
        common_treat_time = max(id_time)
    }
    
    // Compute Gi and id_time_std for each observation
    // Using pre-built index lists - no additional selectindex() calls
    *Gi = J(N, 1, .)
    *id_time_std = J(N, 1, .)
    
    for (i = 1; i <= n_units; i++) {
        idx = asarray(unit_idx_map, i)
        
        // Set Gi
        (*Gi)[idx] = J(length(idx), 1, unit_Gi[i])
        
        // Set id_time_std
        (*id_time_std)[idx] = id_time[idx] :- common_treat_time
    }
}

/*---------------------------------------------------------------------------
 * _compute_Gi_and_time_std_rcs() - Compute Gi and Standardized Time (RCS)
 *
 * For repeated cross-section data, computes group indicator and
 * time relative to treatment period.
 *
 * Arguments:
 *   D           : real colvector - treatment/group indicator
 *   id_time     : real colvector - time identifier
 *   It_post     : real colvector - post-treatment indicator 
 *   Gi          : pointer(real colvector) - output group indicator
 *   id_time_std : pointer(real colvector) - output standardized time
 *
 * Output:
 *   Gi = D (treatment variable is the group indicator for RCS)
 *   id_time_std = normalized_time - treat_year
 *   where treat_year = min(time where It_post == 1)
 *---------------------------------------------------------------------------*/
void _compute_Gi_and_time_std_rcs(
    real colvector D,
    real colvector id_time,
    real colvector It_post,
    pointer(real colvector) scalar Gi,
    pointer(real colvector) scalar id_time_std
)
{
    real scalar N, i, treat_year
    real colvector unique_times, id_time_norm
    real colvector post_times
    transmorphic scalar time_map
    
    N = rows(D)
    It_post = normalize_binary01(It_post, 1e-6)
    
    // Gi = D (for RCS, treatment variable IS the group indicator)
    *Gi = D
    
    // Normalize id_time to sequential integers (1, 2, 3, ...)
    unique_times = uniqrows(id_time)
    time_map = asarray_create("real", 1)
    for (i = 1; i <= rows(unique_times); i++) {
        asarray(time_map, unique_times[i], i)
    }
    
    // Map to normalized integers, preserving missing values
    id_time_norm = J(N, 1, .)
    for (i = 1; i <= N; i++) {
        if (id_time[i] >= .) {
            id_time_norm[i] = .
        }
        else {
            id_time_norm[i] = asarray(time_map, id_time[i])
        }
    }
    
    // Find treat_year = min(id_time where It_post == 1)
    post_times = select(id_time_norm, It_post :== 1)
    if (rows(post_times) > 0) {
        treat_year = min(post_times)
    }
    else {
        treat_year = max(id_time_norm)
    }
    
    // id_time_std = id_time - treat_year
    *id_time_std = id_time_norm :- treat_year
}

/*---------------------------------------------------------------------------
 * _check_std_did() - Standard DID Placebo Tests
 *
 * Computes placebo estimates and bootstrap SE for standard DID design.
 *
 * Arguments:
 *   data        : struct did_data - data structure
 *   lags        : real rowvector - lag values to test
 *   n_boot      : real scalar - number of bootstrap iterations
 *   cluster_var : string scalar - cluster variable name
 *   quiet       : real scalar - suppress progress (1=yes)
 *
 * Side Effects:
 *   Populates external globals _check_placebo, _check_n_boot_valid
 *---------------------------------------------------------------------------*/
void _check_std_did(
    struct did_data scalar data,
    real rowvector lags,
    real scalar n_boot,
    string scalar cluster_var,
    real scalar quiet
)
{
    external real matrix _check_placebo
    external real matrix _check_posted_vcov
    external real matrix _check_n_boot_valid_lag
    external real scalar _check_n_boot_valid
    
    struct placebo_result scalar point_res
    struct placebo_boot_result scalar boot_res
    real matrix eq_ci
    real scalar n_lags, i

    _warn_lag0_placebo(lags, quiet)

    // -------------------------------------------------------------------------
    // Compute point estimates
    // -------------------------------------------------------------------------
    point_res = did_placebo(data.outcome, data.Gi, data.id_time_std, 
                            data.covariates, lags)
    
    n_lags = rows(point_res.lags)
    
    // Handle empty result
    if (n_lags == 0) {
        _check_placebo = J(0, 7, .)
        _check_posted_vcov = J(0, 0, .)
        _check_n_boot_valid_lag = J(0, 2, .)
        _check_n_boot_valid = 0
        return
    }
    
    // -------------------------------------------------------------------------
    // Compute bootstrap standard errors
    // -------------------------------------------------------------------------
    boot_res = did_placebo_boot_full(data, lags, n_boot, data.is_panel, cluster_var)
    _check_n_boot_valid = boot_res.n_valid
    _check_n_boot_valid_lag = _boot_valid_counts(boot_res.boot_est_std, boot_res.boot_est)
    _check_posted_vcov = _posted_placebo_joint_vcov(
        boot_res.boot_est_std,
        point_res.est_std,
        boot_res.se_std,
        point_res.est,
        boot_res.se
    )
    
    // Compute equivalence CIs (with dimension check)
    if (rows(point_res.est_std) != rows(boot_res.se_std)) {
        printf("{err}Warning: Dimension mismatch between point estimates (%g) and bootstrap SE (%g)\n",
               rows(point_res.est_std), rows(boot_res.se_std))
        printf("{err}Using minimum dimension for equivalence CI computation\n")
        real scalar min_dim
        min_dim = min((rows(point_res.est_std), rows(boot_res.se_std)))
        eq_ci = J(n_lags, 2, .)
        if (min_dim > 0) {
            for (i = 1; i <= min_dim; i++) {
                eq_ci[i, .] = compute_eq_ci(point_res.est_std[i], boot_res.se_std[i])
            }
        }
    }
    else {
        eq_ci = J(n_lags, 2, .)
        for (i = 1; i <= n_lags; i++) {
            eq_ci[i, .] = compute_eq_ci(point_res.est_std[i], boot_res.se_std[i])
        }
    }
    
    // -------------------------------------------------------------------------
    // Build result matrix
    // Columns: lag, estimate, std_error, estimate_orig, std_error_orig, EqCI95_LB, EqCI95_UB
    // -------------------------------------------------------------------------
    _check_placebo = J(n_lags, 7, .)
    
    for (i = 1; i <= n_lags; i++) {
        _check_placebo[i, 1] = point_res.lags[i]           // lag
        _check_placebo[i, 2] = point_res.est_std[i]        // estimate (standardized)
        _check_placebo[i, 3] = boot_res.se_std[i]          // std_error (standardized)
        _check_placebo[i, 4] = point_res.est[i]            // estimate_orig (raw)
        _check_placebo[i, 5] = boot_res.se[i]              // std_error_orig (raw)
        _check_placebo[i, 6] = eq_ci[i, 1]                 // EqCI95_LB
        _check_placebo[i, 7] = eq_ci[i, 2]                 // EqCI95_UB
    }
}

/*---------------------------------------------------------------------------
 * _check_sa_did() - Staggered Adoption Placebo Tests
 *
 * Computes placebo estimates and bootstrap SE for staggered adoption design.
 *
 * Arguments:
 *   data        : struct did_data - data structure
 *   lags        : real rowvector - lag values to test
 *   n_boot      : real scalar - number of bootstrap iterations
 *   thres       : real scalar - minimum treated fraction threshold
 *   cluster_var : string scalar - cluster variable name
 *   quiet       : real scalar - suppress progress (1=yes)
 *
 * Side Effects:
 *   Populates external globals _check_placebo, _check_Gmat, _check_n_boot_valid
 *---------------------------------------------------------------------------*/
void _check_sa_did(
    struct did_data scalar data,
    real rowvector lags,
    real scalar n_boot,
    real scalar thres,
    string scalar cluster_var,
    real scalar quiet
)
{
    external real matrix _check_placebo
    external real matrix _check_Gmat
    external real matrix _check_posted_vcov
    external real matrix _check_sa_support_mask_raw
    external real matrix _check_sa_support_mask
    external real matrix _check_n_boot_valid_lag
    external real scalar _check_n_boot_valid
    external real scalar _check_no_valid_periods
    
    struct did_option scalar option
    struct sa_placebo_result scalar point_res
    struct sa_placebo_boot_result scalar boot_res
    real matrix eq_ci
    real scalar n_lags, i

    _warn_lag0_placebo(lags, quiet)

    // -------------------------------------------------------------------------
    // Setup option structure
    // -------------------------------------------------------------------------
    option = init_did_option()
    option.lag = lags
    option.n_boot = n_boot
    option.thres = thres
    option.quiet = quiet
    
    // Handle cluster variable (default to id_unit for panel data)
    if (cluster_var == "" & data.is_panel) {
        option.id_cluster = "id_unit"
    }
    else {
        option.id_cluster = cluster_var
    }
    
    // Compute point estimates
    point_res = did_sad_placebo(data, option)
    
    if (point_res.has_valid_periods == 0) {
        _check_placebo = J(0, 7, .)
        _check_Gmat = J(0, 0, .)
        _check_posted_vcov = J(0, 0, .)
        _check_sa_support_mask_raw = J(0, 0, .)
        _check_sa_support_mask = J(0, 0, .)
        _check_n_boot_valid_lag = J(0, 2, .)
        _check_n_boot_valid = 0
        _check_no_valid_periods = 1
        return
    }
    
    n_lags = rows(point_res.estimates)
    _check_sa_support_mask_raw = point_res.support_mask_raw
    _check_sa_support_mask = point_res.support_mask_std
    
    // Store Gmat only if staggered adoption succeeded (valid Gmat has >1 row and >1 column)
    if (n_lags > 0 && rows(point_res.Gmat) > 1 && cols(point_res.Gmat) > 1) {
        _check_Gmat = point_res.Gmat
    }
    else {
        // Set to empty matrix (0x0) instead of placeholder
        // This will cause ado level to skip e(Gmat) storage
        _check_Gmat = J(0, 0, .)
    }
    
    // Handle empty result
    if (n_lags == 0) {
        _check_placebo = J(0, 7, .)
        _check_posted_vcov = J(0, 0, .)
        _check_sa_support_mask_raw = J(0, 0, .)
        _check_sa_support_mask = J(0, 0, .)
        _check_n_boot_valid_lag = J(0, 2, .)
        _check_n_boot_valid = 0
        return
    }
    
    // Compute bootstrap standard errors
    boot_res = did_sad_placebo_boot(data, option)
    _check_n_boot_valid = boot_res.n_valid
    _check_n_boot_valid_lag = _boot_valid_counts(boot_res.boot_est_std, boot_res.boot_est_orig)
    _check_posted_vcov = _posted_placebo_joint_vcov(
        boot_res.boot_est_std,
        point_res.estimates[., 1],
        boot_res.se_std,
        point_res.estimates[., 2],
        boot_res.se_orig
    )
    
    // Compute equivalence CIs (with dimension check)
    if (rows(point_res.estimates) != rows(boot_res.se_std)) {
        printf("{err}Warning: Dimension mismatch in staggered adoption placebo results\n")
        printf("{err}Point estimates: %g rows, Bootstrap SE: %g rows\n",
               rows(point_res.estimates), rows(boot_res.se_std))
        eq_ci = J(n_lags, 2, .)
    }
    else {
        eq_ci = J(n_lags, 2, .)
        for (i = 1; i <= n_lags; i++) {
            eq_ci[i, .] = compute_eq_ci(point_res.estimates[i, 1], boot_res.se_std[i])
        }
    }
    
    // Build result matrix
    // Columns: lag, estimate, std_error, estimate_orig, std_error_orig, EqCI95_LB, EqCI95_UB
    _check_placebo = J(n_lags, 7, .)
    
    for (i = 1; i <= n_lags; i++) {
        _check_placebo[i, 1] = option.lag[i]                    // lag
        _check_placebo[i, 2] = point_res.estimates[i, 1]        // estimate (standardized)
        _check_placebo[i, 3] = boot_res.se_std[i]               // std_error (standardized)
        _check_placebo[i, 4] = point_res.estimates[i, 2]        // estimate_orig (raw)
        _check_placebo[i, 5] = boot_res.se_orig[i]              // std_error_orig (raw)
        _check_placebo[i, 6] = eq_ci[i, 1]                      // EqCI95_LB
        _check_placebo[i, 7] = eq_ci[i, 2]                      // EqCI95_UB
    }
}

/*---------------------------------------------------------------------------
 * _compute_trends() - Compute Trends Data for Visualization
 *
 * Computes group-period summary statistics for parallel trends visualization.
 *
 * Arguments:
 *   Y           : real colvector - outcome variable
 *   Gi          : real colvector - group indicator
 *   id_time_std : real colvector - standardized time
 *
 * Returns:
 *   real matrix (n_rows x 5) with columns:
 *     [id_time_std, Gi, outcome_mean, outcome_sd, n_obs]
 *   Rows are ordered by (time, group) and exclude empty cells.
 *   outcome_sd is sample standard deviation (n-1 denominator)
 *---------------------------------------------------------------------------*/
real matrix _compute_trends(
    real colvector Y,
    real colvector Gi,
    real colvector id_time_std
)
{
    real matrix result
    real colvector times, groups, idx
    real scalar n_times, n_groups, t, g, row, n_obs
    real scalar y_mean, y_sd
    
    // Get unique times and groups
    times = uniqrows(id_time_std)
    groups = uniqrows(Gi)
    n_times = rows(times)
    n_groups = rows(groups)
    
    // Allocate result matrix
    result = J(n_times * n_groups, 5, .)
    
    row = 1
    for (t = 1; t <= n_times; t++) {
        for (g = 1; g <= n_groups; g++) {
            // Find observations for this time-group combination
            idx = selectindex((id_time_std :== times[t]) :& (Gi :== groups[g]))
            
            // Filter out missing outcome values before counting
            if (length(idx) > 0) {
                idx = select(idx, Y[idx] :< .)
            }
            
            n_obs = length(idx)
            
            if (n_obs > 0) {
                y_mean = mean(Y[idx])
                // SD uses n-1 denominator (sample standard deviation)
                y_sd = sqrt(variance(Y[idx]))
            }
            else {
                y_mean = .
                y_sd = .
            }
            
            result[row, 1] = times[t]      // id_time_std
            result[row, 2] = groups[g]     // Gi
            result[row, 3] = y_mean        // outcome_mean
            result[row, 4] = y_sd          // outcome_sd (SD, not SE)
            result[row, 5] = n_obs         // n_obs
            
            row++
        }
    }
    
    // Filter out rows with n_obs == 0
    real colvector valid_rows
    valid_rows = selectindex(result[., 5] :> 0)
    if (rows(valid_rows) > 0) {
        result = result[valid_rows, .]
    }
    else {
        // If all rows are empty, return empty matrix with correct dimensions
        result = J(0, 5, .)
    }
    
    return(result)
}

// ============================================================================
// GLOBAL VARIABLE INITIALIZATION
// ============================================================================
// External variables for communication between Mata functions and ado file.
// Initialized at module load time.
// ============================================================================
void _diddesign_check_init_globals()
{
    external real matrix _check_placebo
    external real matrix _check_trends
    external real matrix _check_Gmat
    external real matrix _check_posted_vcov
    external real matrix _check_sa_support_mask_raw
    external real matrix _check_sa_support_mask
    external real matrix _check_n_boot_valid_lag
    external real scalar _check_n_lags
    external real scalar _check_n_boot_valid
    external real scalar _check_max_preperiods
    external real scalar _check_no_valid_periods
    external string scalar _check_filtered_lags
    
    // Initialize with empty/default values
    _check_placebo = J(0, 7, .)
    _check_trends = J(0, 5, .)
    _check_Gmat = J(0, 0, .)
    _check_posted_vcov = J(0, 0, .)
    _check_sa_support_mask_raw = J(0, 0, .)
    _check_sa_support_mask = J(0, 0, .)
    _check_n_boot_valid_lag = J(0, 2, .)
    _check_n_lags = 0
    _check_n_boot_valid = 0
    _check_max_preperiods = 0
    _check_no_valid_periods = 0
    _check_filtered_lags = ""
}

// Call initialization function immediately when module is loaded
_diddesign_check_init_globals()

/*---------------------------------------------------------------------------
 * _did_check_tail_loaded() - Tail Sentinel for Full Module Load Verification
 *---------------------------------------------------------------------------*/
void _did_check_tail_loaded()
{
}

end
