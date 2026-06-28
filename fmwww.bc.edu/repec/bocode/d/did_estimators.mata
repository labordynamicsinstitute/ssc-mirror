*! did_estimators.mata - Core estimation functions for difference-in-differences
*!
*! Implements point estimation for the standard DID estimator (under the parallel
*! trends assumption) and the sequential DID estimator (under the weaker parallel
*! trends-in-trends assumption). Also provides data structures and equivalence
*! confidence interval computation for assessing pre-treatment trends.

version 16.0

mata:
mata set matastrict on

// ----------------------------------------------------------------------------
// DATA STRUCTURES
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * struct did_data - Data container for DID estimation
 *
 * Stores outcome, treatment, and derived variables for difference-in-
 * differences estimation. Supports panel and repeated cross-sectional designs.
 *---------------------------------------------------------------------------*/
struct did_data {
    // Original variables
    real colvector outcome       // Y_it: outcome
    real colvector treatment     // D_it: treatment indicator (0/1)
    real colvector id_unit       // Unit identifier i
    real colvector id_time       // Time period t (normalized)
    real matrix    covariates    // X_it: covariates (optional)
    real colvector cluster_var   // Cluster identifier (optional)
    
    // Derived variables
    real colvector Gi            // G_i: treatment group (1) vs control (0)
    real colvector It            // I_t: post-treatment indicator (0/1)
    real colvector id_time_std   // Standardized time (0 = treatment period)
    real colvector outcome_delta // ΔY_it: first-differenced outcome
    
    // Metadata
    real scalar    N             // Number of observations
    real scalar    n_units       // Number of units
    real scalar    n_periods     // Number of time periods
    real scalar    treat_year    // Treatment period (standardized)
    real scalar    is_panel      // 1 = panel, 0 = repeated cross-section
}

/*---------------------------------------------------------------------------
 * struct did_option - Estimation options
 *
 * User-specified options for bootstrap, variance estimation, and display.
 *---------------------------------------------------------------------------*/
struct did_option {
    real scalar    n_boot        // Bootstrap replications
    real scalar    parallel      // 1 = parallel computing enabled
    real scalar    se_boot       // 1 = bootstrap CI, 0 = analytical
    string scalar  id_cluster    // Cluster variable name
    real rowvector lead          // Post-treatment period indices
    real scalar    thres         // Staggered adoption threshold
    real rowvector lag           // Pre-treatment period indices
    real scalar    level         // Confidence level (percent)
    real scalar    seed          // Random seed (. if unset)
    string scalar  var_cluster_pre  // Internal: original cluster variable
    real scalar    quiet         // 1 = suppress progress display
    real scalar    kmax          // Max number of K-DID components (default: 2)
    real scalar    jtest_on      // 1 = enable J-test moment selection
}

// ----------------------------------------------------------------------------
// INITIALIZATION FUNCTIONS
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * init_did_option() - Initialize did_option with default values
 *
 * Returns:
 *   struct did_option: initialized with default values
 *---------------------------------------------------------------------------*/
struct did_option scalar init_did_option()
{
    struct did_option scalar opt
    
    opt.n_boot         = 30
    opt.parallel       = 1
    opt.se_boot        = 0
    opt.id_cluster     = ""
    opt.lead           = 0
    opt.thres          = 2
    opt.lag            = 1
    opt.level          = 95
    opt.seed           = .
    opt.var_cluster_pre = ""
    opt.quiet          = 0
    opt.kmax           = 2
    opt.jtest_on       = 0
    
    return(opt)
}

// ----------------------------------------------------------------------------
// OLS HELPER FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * ols_coef() - Extract OLS coefficient via normal equations
 *
 * Computes β = (X'X)⁻¹X'y and returns the coefficient at specified index.
 *
 * Arguments:
 *   X        : real matrix (n × p), design matrix
 *   y        : real colvector (n × 1), outcome
 *   coef_idx : real scalar, coefficient index (1-based)
 *
 * Returns:
 *   real scalar: coefficient value, or missing if singular/invalid
 *---------------------------------------------------------------------------*/
real scalar ols_coef(real matrix X, real colvector y, real scalar coef_idx)
{
    real matrix X_valid, X_basis
    real colvector beta, valid_idx, coef_pos
    real rowvector basis_idx, other_basis_idx, trial_idx
    real scalar n, p, n_valid, current_rank, j
    
    n = rows(X)
    p = cols(X)
    
    // Check minimum observations
    if (n < p) {
        return(.)
    }
    
    // Listwise deletion for missing values
    valid_idx = selectindex(rowmissing(X) :== 0 :& y :< .)
    n_valid = length(valid_idx)
    
    if (n_valid == 0) {
        return(.)
    }
    X_valid = X[valid_idx, .]
    
    // Validate coefficient index
    if (coef_idx < 1 | coef_idx > p) {
        return(.)
    }
    
    // Build a full-rank basis for all non-target columns.
    other_basis_idx = J(1, 0, .)
    current_rank = 0
    for (j = 1; j <= p; j++) {
        if (j == coef_idx) {
            continue
        }
        if (length(other_basis_idx) == 0) {
            trial_idx = j
        }
        else {
            trial_idx = other_basis_idx, j
        }
        if (rank(X_valid[., trial_idx]) > current_rank) {
            other_basis_idx = trial_idx
            current_rank = rank(X_valid[., other_basis_idx])
        }
    }
    
    if (length(other_basis_idx) == 0) {
        basis_idx = coef_idx
    }
    else {
        basis_idx = other_basis_idx, coef_idx
    }
    
    // The target coefficient is not identified if it adds no independent variation.
    if (rank(X_valid[., basis_idx]) == current_rank) {
        return(.)
    }
    
    basis_idx = sort(basis_idx, 1)
    X_basis = X_valid[., basis_idx]

    if (n_valid < cols(X_basis)) {
        return(.)
    }
    
    beta = qrsolve(X_basis, y[valid_idx])
    if (rows(beta) != cols(X_basis)) {
        return(.)
    }
    if (any(beta :>= .)) {
        return(.)
    }
    
    coef_pos = selectindex(basis_idx' :== coef_idx)
    if (length(coef_pos) != 1) {
        return(.)
    }
    
    return(beta[coef_pos[1]])
}

/*---------------------------------------------------------------------------
 * _sdid_outcome_by_lead() - Lead-aware transformed outcome for k = 2 DID
 *
 * For lead = 0, the sequential DID estimator uses the original transformed
 * outcome_delta = Y_t - E[Y_{g,t-1}]. For lead > 0, Appendix E defines
 * tau_2(s) around the target post-treatment time T* + s:
 *
 *   [Y_{T*+s} - Y_{T*-1}] - (s+1)[Y_{T*-1} - Y_{T*-2}]
 *
 * This helper encodes the same estimand inside the 2x2 regression skeleton by
 * keeping post-period observations unchanged and replacing the t = -1 outcome
 * with (s+2)Y_{-1} - (s+1)E[Y_{g,-2}].
 *---------------------------------------------------------------------------*/
real colvector _sdid_outcome_by_lead(real colvector Y,
                                     real colvector Y_delta,
                                     real colvector Gi,
                                     real colvector time_std,
                                     real colvector id_unit,
                                     real colvector support_mask,
                                     real scalar lead)
{
    real colvector result, idx_pre1, idx_post, idx_pre1_valid, idx_target
    real colvector valid_units, idx_pre2, idx_pre2_valid
    real scalar g, mean_pre2, mean_lag, i, iter, target_ts, lag_ts
    transmorphic scalar unit_set

    result = J(rows(Y), 1, .)

    for (g = 0; g <= 1; g++) {
        idx_pre1_valid = selectindex((Gi :== g) :& (time_std :== -1) :& (support_mask :> 0) :& (Y :< .))
        if (length(idx_pre1_valid) == 0) {
            continue
        }

        valid_units = uniqrows(id_unit[idx_pre1_valid])
        unit_set = asarray_create("real", 1)
        for (i = 1; i <= rows(valid_units); i++) {
            asarray(unit_set, valid_units[i], 1)
        }

        if (lead <= 0) {
            for (target_ts = -1; target_ts <= 0; target_ts++) {
                idx_target = selectindex((Gi :== g) :& (time_std :== target_ts) :& (support_mask :> 0) :& (Y :< .))
                if (length(idx_target) == 0) {
                    continue
                }

                lag_ts = target_ts - 1
                idx_pre2 = selectindex((Gi :== g) :& (time_std :== lag_ts) :& (Y :< .))
                if (length(idx_pre2) == 0) {
                    continue
                }

                idx_pre2_valid = J(length(idx_pre2), 1, .)
                iter = 1
                for (i = 1; i <= length(idx_pre2); i++) {
                    if (asarray_contains(unit_set, id_unit[idx_pre2[i]])) {
                        idx_pre2_valid[iter] = idx_pre2[i]
                        iter++
                    }
                }

                mean_lag = .
                if (iter > 1) {
                    idx_pre2_valid = idx_pre2_valid[1::(iter - 1)]
                    if (all(Y[idx_pre2_valid] :< .)) {
                        mean_lag = mean(Y[idx_pre2_valid])
                    }
                }

                if (missing(mean_lag)) {
                    continue
                }

                result[idx_target] = Y[idx_target] :- mean_lag
            }

            continue
        }

        idx_post = selectindex((Gi :== g) :& (time_std :== lead) :& (support_mask :> 0) :& (Y :< .))
        if (length(idx_post) > 0) {
            result[idx_post] = Y[idx_post]
        }

        idx_pre2 = selectindex((Gi :== g) :& (time_std :== -2) :& (Y :< .))
        if (length(idx_pre2) == 0) {
            continue
        }

        idx_pre2_valid = J(length(idx_pre2), 1, .)
        iter = 1
        for (i = 1; i <= length(idx_pre2); i++) {
            if (asarray_contains(unit_set, id_unit[idx_pre2[i]])) {
                idx_pre2_valid[iter] = idx_pre2[i]
                iter++
            }
        }

        mean_pre2 = .
        if (iter > 1) {
            idx_pre2_valid = idx_pre2_valid[1::(iter - 1)]
            if (all(Y[idx_pre2_valid] :< .)) {
                mean_pre2 = mean(Y[idx_pre2_valid])
            }
        }

        if (missing(mean_pre2)) {
            continue
        }

        idx_pre1 = selectindex((Gi :== g) :& (time_std :== -1) :& (support_mask :> 0) :& (Y :< .))
        if (length(idx_pre1) > 0) {
            result[idx_pre1] = (lead + 2) :* Y[idx_pre1] :- (lead + 1) * mean_pre2
        }
    }

    return(result)
}


// ----------------------------------------------------------------------------
// MAIN DID ESTIMATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * did_fit() - Compute DID and sequential DID point estimates
 *
 * The standard DID estimator τ̂_DID is consistent under the parallel trends
 * assumption. The sequential DID estimator τ̂_sDID requires only the weaker
 * parallel trends-in-trends assumption for lead = 0 and uses the Appendix E
 * lead-aware k = 2 transformation when lead > 0.
 *
 * Arguments:
 *   Y        : real colvector, outcome Y_it
 *   Y_delta  : real colvector, baseline transformed outcome for lead = 0
 *   Gi       : real colvector, group indicator G_i (1 = treated)
 *   It       : real colvector, post-treatment indicator I_t
 *   id_unit   : real colvector, unit identifiers used for lag joins
 *   X        : real matrix, covariates (or empty)
 *   time_std : real colvector, standardized time index
 *   lead     : real scalar, post-treatment period (0 = treatment year)
 *
 * Returns:
 *   real rowvector (1 × 2): (τ̂_DID, τ̂_sDID)
 *
 * Regression models:
 *   DID:  Y_it = α + β₁G_i + β₂I_t + τG_i×I_t + X'γ + ε
 *   sDID (lead = 0):  ΔY_it = α + β₁G_i + β₂I_t + τG_i×I_t + X'γ + ε
 *   sDID (lead > 0): lead-aware Appendix E k = 2 transform on {-1, lead}
 *---------------------------------------------------------------------------*/
real rowvector did_fit(real colvector Y, real colvector Y_delta,
                       real colvector Gi, real colvector It,
                       real colvector id_unit, real matrix X,
                       real colvector time_std, real scalar lead,
                       | real scalar is_panel)
{
    real colvector idx, idx_did, idx_sdid, reg_valid, support_mask_full
    real colvector Y_sub, Yd_sub, Yd_lead, Gi_sub, It_sub
    real colvector Gi_did, It_did, Gi_sdid, It_sdid
    real colvector valid_did, valid_sdid, cov_valid, gi_it_valid
    real colvector id_unit_sub, cov_unit_complete, cov_counts, cov_unit_idx
    real colvector support_units, support_unit_idx
    real matrix X_sub, X_did, X_sdid, design_did, design_sdid
    real rowvector result
    real rowvector distinct_times
    real scalar tau_did, tau_sdid, n_sub, k_cov, i, required_periods, _is_panel
    transmorphic scalar cov_count_map
    
    // -------------------------------------------------------------------------
    // Input validation
    // -------------------------------------------------------------------------
    _is_panel = (args() >= 9 ? is_panel : 1)
    
    if (lead < 0) {
        errprintf("{err}Error: lead must be >= 0 (got %g)\n", lead)
        return((., .))
    }
    
    // Subset data to relevant time periods: t ∈ {-1, lead}
    idx = selectindex((time_std :== -1) :| (time_std :== lead))
    
    // Return missing if no observations in specified periods
    if (length(idx) == 0) {
        return((., .))
    }
    
    // Extract observations for the selected time periods
    Y_sub = Y[idx]
    Gi_sub = Gi[idx]
    It_sub = It[idx]
    id_unit_sub = id_unit[idx]
    n_sub = length(idx)
    
    // Handle covariates
    k_cov = cols(X)
    reg_valid = (Y :< .) :& (Gi :< .) :& (It :< .)
    if (k_cov > 0) {
        X_sub = X[idx, .]
        reg_valid = reg_valid :& (rowmissing(X) :== 0)
    }
    // Listwise deletion for missing values
    valid_did = (Y_sub :< .)
    
    // Exclude observations with missing covariates
    if (k_cov > 0) {
        cov_valid = (rowmissing(X_sub) :== 0)
        distinct_times = uniqrows(time_std[idx])
        required_periods = rows(distinct_times)

        cov_counts = J(n_sub, 1, 0)
        cov_count_map = asarray_create("real", 1)
        cov_unit_idx = selectindex(cov_valid)
        for (i = 1; i <= length(cov_unit_idx); i++) {
            if (asarray_contains(cov_count_map, id_unit_sub[cov_unit_idx[i]])) {
                asarray(
                    cov_count_map,
                    id_unit_sub[cov_unit_idx[i]],
                    asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]]) + 1
                )
            }
            else {
                asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]], 1)
            }
        }

        for (i = 1; i <= n_sub; i++) {
            if (asarray_contains(cov_count_map, id_unit_sub[i])) {
                cov_counts[i] = asarray(cov_count_map, id_unit_sub[i])
            }
        }

        if (_is_panel) {
            cov_unit_complete = cov_valid :& (cov_counts :== required_periods)
        }
        else {
            cov_unit_complete = cov_valid
        }
        valid_did = valid_did :& cov_unit_complete
    }
    
    // Exclude observations with missing group or time indicators
    gi_it_valid = (Gi_sub :< .) :& (It_sub :< .)
    valid_did = valid_did :& gi_it_valid

    support_mask_full = reg_valid
    if (k_cov > 0) {
        if (_is_panel) {
            support_units = uniqrows(id_unit_sub[selectindex(cov_unit_complete :& gi_it_valid)])
            support_mask_full = J(rows(Y), 1, 0)
            if (rows(support_units) > 0) {
                for (i = 1; i <= rows(Y); i++) {
                    if (anyof(support_units, id_unit[i])) {
                        support_mask_full[i] = 1
                    }
                }
            }
        }
        else {
            support_mask_full = reg_valid :& (rowmissing(X) :== 0)
        }
    }

    Yd_lead = _sdid_outcome_by_lead(Y, Y_delta, Gi, time_std, id_unit, support_mask_full, lead)
    Yd_sub = Yd_lead[idx]
    valid_sdid = (Yd_sub :< .)
    valid_sdid = valid_sdid :& gi_it_valid
    
    // Obtain indices of valid observations
    idx_did = selectindex(valid_did)
    idx_sdid = selectindex(valid_sdid)
    
    // Standard DID estimation (requires at least 4 observations)
    if (length(idx_did) < 4) {
        tau_did = .
    }
    else {
        Gi_did = Gi_sub[idx_did]
        It_did = It_sub[idx_did]
        
        // Check for sufficient variation
        if (min(Gi_did) == max(Gi_did)) {
            tau_did = .
        }
        else if (min(It_did) == max(It_did)) {
            tau_did = .
        }
        else if (sum((Gi_did :== 0) :& (It_did :== 0)) == 0 |
                 sum((Gi_did :== 0) :& (It_did :== 1)) == 0 |
                 sum((Gi_did :== 1) :& (It_did :== 0)) == 0 |
                 sum((Gi_did :== 1) :& (It_did :== 1)) == 0) {
            // DID requires support in every 2x2 group-period cell.
            tau_did = .
        }
        else {
            // Construct design matrix: [1, G_i, I_t, G_i×I_t, X]
            design_did = J(length(idx_did), 1, 1), Gi_did, It_did, Gi_did :* It_did
            
            if (k_cov > 0) {
                X_did = X_sub[idx_did, .]
                design_did = design_did, X_did
            }
            
            // Extract coefficient on interaction term (position 4)
            tau_did = ols_coef(design_did, Y_sub[idx_did], 4)
        }
    }
    
    // Sequential DID estimation
    if (length(idx_sdid) < 4) {
        tau_sdid = .
    }
    else {
        Gi_sdid = Gi_sub[idx_sdid]
        It_sdid = It_sub[idx_sdid]
        
        // Check for sufficient variation
        if (min(Gi_sdid) == max(Gi_sdid)) {
            tau_sdid = .
        }
        else if (min(It_sdid) == max(It_sdid)) {
            tau_sdid = .
        }
        else if (sum((Gi_sdid :== 0) :& (It_sdid :== 0)) == 0 |
                 sum((Gi_sdid :== 0) :& (It_sdid :== 1)) == 0 |
                 sum((Gi_sdid :== 1) :& (It_sdid :== 0)) == 0 |
                 sum((Gi_sdid :== 1) :& (It_sdid :== 1)) == 0) {
            // Sequential DID is unidentified if any 2x2 cell disappears
            // after outcome_delta listwise deletion.
            tau_sdid = .
        }
        else {
            // Construct design matrix: [1, G_i, I_t, G_i×I_t, X]
            design_sdid = J(length(idx_sdid), 1, 1), Gi_sdid, It_sdid, Gi_sdid :* It_sdid
            
            if (k_cov > 0) {
                X_sdid = X_sub[idx_sdid, .]
                design_sdid = design_sdid, X_sdid
            }
            
            // Extract coefficient on interaction term (position 4)
            tau_sdid = ols_coef(design_sdid, Yd_sub[idx_sdid], 4)
        }
    }
    
    // Return point estimates
    result = (tau_did, tau_sdid)
    return(result)
}

real rowvector did_fit_treated_support(real colvector Y, real colvector Y_delta,
                                       real colvector Gi, real colvector It,
                                       real colvector id_unit, real matrix X,
                                       real colvector time_std, real scalar lead,
                                       | real scalar is_panel)
{
    real colvector idx, Y_sub, Yd_sub, Gi_sub, It_sub, id_unit_sub, support_mask_full
    real colvector valid_did, valid_sdid, cov_valid, gi_it_valid
    real colvector reg_valid, cov_unit_complete, cov_counts, cov_unit_idx
    real colvector treated_idx_did, treated_idx_sdid, treated_idx_common, support_units
    real matrix X_sub
    real rowvector distinct_times, result
    real scalar n_sub, k_cov, i, required_periods, _is_panel
    transmorphic scalar cov_count_map

    _is_panel = (args() >= 9 ? is_panel : 1)

    idx = selectindex((time_std :== -1) :| (time_std :== lead))
    if (length(idx) == 0) {
        return((0, 0, 0))
    }

    Y_sub = Y[idx]
    Gi_sub = Gi[idx]
    It_sub = It[idx]
    id_unit_sub = id_unit[idx]
    n_sub = length(idx)
    k_cov = cols(X)

    reg_valid = (Y :< .) :& (Gi :< .) :& (It :< .)
    if (k_cov > 0) {
        X_sub = X[idx, .]
        reg_valid = reg_valid :& (rowmissing(X) :== 0)
    }
    else {
        X_sub = J(n_sub, 0, .)
    }

    valid_did = (Y_sub :< .)

    if (k_cov > 0) {
        cov_valid = (rowmissing(X_sub) :== 0)
        distinct_times = uniqrows(time_std[idx])
        required_periods = rows(distinct_times)
        cov_counts = J(n_sub, 1, 0)
        cov_count_map = asarray_create("real", 1)
        cov_unit_idx = selectindex(cov_valid)

        for (i = 1; i <= length(cov_unit_idx); i++) {
            if (asarray_contains(cov_count_map, id_unit_sub[cov_unit_idx[i]])) {
                asarray(
                    cov_count_map,
                    id_unit_sub[cov_unit_idx[i]],
                    asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]]) + 1
                )
            }
            else {
                asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]], 1)
            }
        }

        for (i = 1; i <= n_sub; i++) {
            if (asarray_contains(cov_count_map, id_unit_sub[i])) {
                cov_counts[i] = asarray(cov_count_map, id_unit_sub[i])
            }
        }

        if (_is_panel) {
            cov_unit_complete = cov_valid :& (cov_counts :== required_periods)
        }
        else {
            cov_unit_complete = cov_valid
        }
        valid_did = valid_did :& cov_unit_complete
    }

    gi_it_valid = (Gi_sub :< .) :& (It_sub :< .)
    valid_did = valid_did :& gi_it_valid

    support_mask_full = reg_valid
    if (k_cov > 0) {
        if (_is_panel) {
            support_units = uniqrows(id_unit_sub[selectindex(cov_unit_complete :& gi_it_valid)])
            support_mask_full = J(rows(Y), 1, 0)
            if (rows(support_units) > 0) {
                for (i = 1; i <= rows(Y); i++) {
                    if (anyof(support_units, id_unit[i])) {
                        support_mask_full[i] = 1
                    }
                }
            }
        }
        else {
            support_mask_full = reg_valid :& (rowmissing(X) :== 0)
        }
    }

    Yd_sub = _sdid_outcome_by_lead(Y, Y_delta, Gi, time_std, id_unit, support_mask_full, lead)[idx]
    valid_sdid = (Yd_sub :< .)
    valid_sdid = valid_sdid :& gi_it_valid

    treated_idx_did = selectindex(valid_did :& (Gi_sub :== 1))
    treated_idx_sdid = selectindex(valid_sdid :& (Gi_sub :== 1))
    treated_idx_common = selectindex(valid_did :& valid_sdid :& (Gi_sub :== 1))

    result = (
        rows(uniqrows(id_unit_sub[treated_idx_did])),
        rows(uniqrows(id_unit_sub[treated_idx_sdid])),
        rows(uniqrows(id_unit_sub[treated_idx_common]))
    )

    return(result)
}


/*---------------------------------------------------------------------------
 * did_fit_k() - Compute K-dimensional component point estimates
 *
 * Returns τ̂_1(s), τ̂_2(s), ..., τ̂_K(s) where K = min(kmax, K_init(s)).
 * Each τ̂_k(s) is computed via the k-th order transformed outcome DID
 * regression on {-1, lead}.
 *
 * k=1: standard DID (parallel trends)
 * k=2: sequential DID (parallel trends-in-trends)
 * k≥3: higher-order DID ((k-1)-th degree polynomial confounding)
 *
 * Arguments:
 *   Y        : real colvector, outcome Y_it
 *   Gi       : real colvector, group indicator G_i (1 = treated)
 *   It       : real colvector, post-treatment indicator I_t
 *   id_unit  : real colvector, unit identifiers
 *   X        : real matrix, covariates (or empty)
 *   time_std : real colvector, standardized time index
 *   lead     : real scalar, post-treatment period (0 = treatment year)
 *   kmax     : real scalar, maximum number of components
 *   is_panel : real scalar, 1 = panel, 0 = RCS
 *
 * Returns:
 *   real rowvector (1 × kmax): (τ̂_1, τ̂_2, ..., τ̂_kmax)
 *     Components beyond K_init are set to missing.
 *---------------------------------------------------------------------------*/
real rowvector did_fit_k(real colvector Y,
                         real colvector Gi, real colvector It,
                         real colvector id_unit, real matrix X,
                         real colvector time_std, real scalar lead,
                         real scalar kmax,
                         | real scalar is_panel)
{
    real rowvector result, point_est_k1
    real colvector idx, Y_sub, Gi_sub, It_sub, id_unit_sub
    real colvector Yd_k, Yd_k_sub
    real colvector valid_k, gi_it_valid, cov_valid, cov_unit_complete, cov_counts, cov_unit_idx
    real colvector idx_k, Gi_k, It_k, reg_valid, support_mask_full, support_units
    real matrix X_sub, X_k, design_k
    real rowvector distinct_times
    real scalar _is_panel, k_comp, n_sub, k_cov, i, required_periods, tau_k
    transmorphic scalar cov_count_map

    _is_panel = (args() >= 9 ? is_panel : 1)

    result = J(1, kmax, .)

    // Subset data to relevant time periods: t ∈ {-1, lead}
    idx = selectindex((time_std :== -1) :| (time_std :== lead))
    if (length(idx) == 0) {
        return(result)
    }

    Y_sub = Y[idx]
    Gi_sub = Gi[idx]
    It_sub = It[idx]
    id_unit_sub = id_unit[idx]
    n_sub = length(idx)
    k_cov = cols(X)

    // Build validity masks (same logic as did_fit)
    reg_valid = (Y :< .) :& (Gi :< .) :& (It :< .)
    if (k_cov > 0) {
        X_sub = X[idx, .]
        reg_valid = reg_valid :& (rowmissing(X) :== 0)
    }

    valid_k = (Y_sub :< .)
    if (k_cov > 0) {
        cov_valid = (rowmissing(X_sub) :== 0)
        distinct_times = uniqrows(time_std[idx])
        required_periods = rows(distinct_times)

        cov_counts = J(n_sub, 1, 0)
        cov_count_map = asarray_create("real", 1)
        cov_unit_idx = selectindex(cov_valid)
        for (i = 1; i <= length(cov_unit_idx); i++) {
            if (asarray_contains(cov_count_map, id_unit_sub[cov_unit_idx[i]])) {
                asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]],
                    asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]]) + 1)
            }
            else {
                asarray(cov_count_map, id_unit_sub[cov_unit_idx[i]], 1)
            }
        }
        for (i = 1; i <= n_sub; i++) {
            if (asarray_contains(cov_count_map, id_unit_sub[i])) {
                cov_counts[i] = asarray(cov_count_map, id_unit_sub[i])
            }
        }
        if (_is_panel) {
            cov_unit_complete = cov_valid :& (cov_counts :== required_periods)
        }
        else {
            cov_unit_complete = cov_valid
        }
        valid_k = valid_k :& cov_unit_complete
    }

    gi_it_valid = (Gi_sub :< .) :& (It_sub :< .)
    valid_k = valid_k :& gi_it_valid

    // Build support mask for full data (needed by _kdid_outcome_by_lead)
    support_mask_full = reg_valid
    if (k_cov > 0) {
        if (_is_panel) {
            support_units = uniqrows(id_unit_sub[selectindex(valid_k)])
            support_mask_full = J(rows(Y), 1, 0)
            if (rows(support_units) > 0) {
                for (i = 1; i <= rows(Y); i++) {
                    if (anyof(support_units, id_unit[i])) {
                        support_mask_full[i] = 1
                    }
                }
            }
        }
        else {
            support_mask_full = reg_valid :& (rowmissing(X) :== 0)
        }
    }

    // Loop over k = 1..kmax
    for (k_comp = 1; k_comp <= kmax; k_comp++) {

        // Compute k-th order transformed outcome
        Yd_k = _kdid_outcome_by_lead(Y, Gi, time_std, id_unit, support_mask_full, lead, k_comp)
        Yd_k_sub = Yd_k[idx]

        // Build validity mask for this component
        valid_k = (Yd_k_sub :< .) :& gi_it_valid
        if (k_cov > 0) {
            if (_is_panel) {
                valid_k = valid_k :& cov_unit_complete
            }
            else {
                valid_k = valid_k :& (rowmissing(X_sub) :== 0)
            }
        }

        idx_k = selectindex(valid_k)

        if (length(idx_k) < 4) {
            // Not enough obs; this and higher k are infeasible
            break
        }

        Gi_k = Gi_sub[idx_k]
        It_k = It_sub[idx_k]

        // Check sufficient variation in all 2×2 cells
        if (min(Gi_k) == max(Gi_k) || min(It_k) == max(It_k)) {
            break
        }
        if (sum((Gi_k :== 0) :& (It_k :== 0)) == 0 |
            sum((Gi_k :== 0) :& (It_k :== 1)) == 0 |
            sum((Gi_k :== 1) :& (It_k :== 0)) == 0 |
            sum((Gi_k :== 1) :& (It_k :== 1)) == 0) {
            break
        }

        // Construct design matrix: [1, G_i, I_t, G_i×I_t, X]
        design_k = J(length(idx_k), 1, 1), Gi_k, It_k, Gi_k :* It_k
        if (k_cov > 0) {
            X_k = X_sub[idx_k, .]
            design_k = design_k, X_k
        }

        // Extract coefficient on interaction term (position 4)
        tau_k = ols_coef(design_k, Yd_k_sub[idx_k], 4)
        result[k_comp] = tau_k
    }

    return(result)
}


/*---------------------------------------------------------------------------
 * did_fit_struct() - Wrapper for did_fit() using did_data structure
 *
 * Arguments:
 *   data : struct did_data, prepared data
 *   lead : real scalar, post-treatment period (default: 0)
 *
 * Returns:
 *   real rowvector (1 × 2): (τ̂_DID, τ̂_sDID)
 *---------------------------------------------------------------------------*/
real rowvector did_fit_struct(struct did_data scalar data, | real scalar lead)
{
    // Default lead = 0
    if (args() < 2) lead = 0
    
    // Extract data from structure and call did_fit()
    return(did_fit(
        data.outcome,
        data.outcome_delta,
        data.Gi,
        data.It,
        data.id_unit,
        data.covariates,
        data.id_time_std,
        lead,
        data.is_panel
    ))
}

// ----------------------------------------------------------------------------
// OPTION POPULATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _diddesign_populate_option() - Populate global did_option structure
 *
 * Internal function called from _diddesign_parse.ado to transfer parsed
 * command-line options to the global did_opt structure.
 *
 * Returns:
 *   0 on success
 *---------------------------------------------------------------------------*/
real scalar _diddesign_populate_option(
    real scalar n_boot,
    real scalar parallel,
    real scalar se_boot,
    string scalar id_cluster,
    real rowvector lead,
    real scalar thres,
    real rowvector lag,
    real scalar level,
    real scalar seed
)
{
    external struct did_option scalar did_opt
    
    did_opt = init_did_option()
    did_opt.n_boot         = n_boot
    did_opt.parallel       = parallel
    did_opt.se_boot        = se_boot
    did_opt.id_cluster     = id_cluster
    did_opt.lead           = lead
    did_opt.thres          = thres
    did_opt.lag            = lag
    did_opt.level          = level
    did_opt.seed           = seed
    did_opt.var_cluster_pre = ""
    
    return(0)
}

// ----------------------------------------------------------------------------
// DATA POPULATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _diddesign_populate_data() - Populate global did_data structure
 *
 * Internal function called from _diddesign_prep.ado to transfer prepared
 * data from Stata variables to the global did_dat structure.
 *
 * Returns:
 *   0 on success
 *---------------------------------------------------------------------------*/
real scalar _diddesign_populate_data(
    string scalar outcome_var,
    string scalar treatment_var,
    string scalar id_var,
    string scalar id_time_var,
    string scalar covar_vars,
    string scalar cluster_var,
    string scalar Gi_var,
    string scalar It_var,
    string scalar id_time_std_var,
    string scalar outcome_delta_var,
    real scalar N,
    real scalar n_units,
    real scalar n_periods,
    real scalar treat_year,
    real scalar is_panel,
    string scalar touse_var
)
{
    external struct did_data scalar did_dat
    string rowvector covar_list
    real scalar k
    
    did_dat = did_data()
    
    // Original variables
    did_dat.outcome = st_data(., outcome_var, touse_var)
    did_dat.treatment = st_data(., treatment_var, touse_var)
    
    if (id_var != "") {
        did_dat.id_unit = st_data(., id_var, touse_var)
    }
    else {
        did_dat.id_unit = J(N, 1, .)
    }
    
    did_dat.id_time = st_data(., id_time_var, touse_var)
    
    // Covariates
    if (covar_vars != "") {
        covar_list = tokens(covar_vars)
        did_dat.covariates = st_data(., covar_list, touse_var)
    }
    else {
        did_dat.covariates = J(0, 0, .)
    }
    
    // Cluster variable
    if (cluster_var != "") {
        did_dat.cluster_var = st_data(., cluster_var, touse_var)
    }
    else {
        did_dat.cluster_var = J(0, 1, .)
    }
    
    // Derived variables
    did_dat.Gi = st_data(., Gi_var, touse_var)
    did_dat.It = st_data(., It_var, touse_var)
    did_dat.id_time_std = st_data(., id_time_std_var, touse_var)
    did_dat.outcome_delta = st_data(., outcome_delta_var, touse_var)
    
    // Metadata
    did_dat.N = N
    did_dat.n_units = n_units
    did_dat.n_periods = n_periods
    did_dat.treat_year = treat_year
    did_dat.is_panel = is_panel
    
    return(0)
}

// ----------------------------------------------------------------------------
// EQUIVALENCE CONFIDENCE INTERVAL FUNCTIONS
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * compute_eq_ci() - Compute 95% equivalence confidence interval
 *
 * Computes the equivalence CI for assessing parallel trends using the
 * Two One-Sided Tests (TOST) methodology.
 *
 * Arguments:
 *   estimate  : real scalar, point estimate (e.g., placebo DID)
 *   std_error : real scalar, standard error
 *
 * Returns:
 *   real rowvector (1 × 2): symmetric equivalence interval (-ν, ν)
 *
 * Method:
 *   1. Construct 90% CI: estimate ± z_{0.95} × SE
 *   2. Compute ν = max(|CI90_UB|, |CI90_LB|)
 *   3. Return (-ν, ν)
 *---------------------------------------------------------------------------*/
real rowvector compute_eq_ci(real scalar estimate, real scalar std_error)
{
    real scalar z_95, CI90_UB, CI90_LB, CI90_UB_ab, CI90_LB_ab, nu
    
    // Input validation: return missing for invalid inputs
    if (missing(estimate) | missing(std_error) | std_error <= 0) {
        return((., .))
    }
    
    // z critical value for 90% CI (corresponds to 95% equivalence test)
    // invnormal(0.95) ≈ 1.64485362695147
    z_95 = invnormal(0.95)
    
    // Compute 90% CI bounds
    CI90_UB = estimate + z_95 * std_error
    CI90_LB = estimate - z_95 * std_error
    
    // Take absolute values
    CI90_UB_ab = abs(CI90_UB)
    CI90_LB_ab = abs(CI90_LB)
    
    // Symmetric equivalence bound: max of absolute values
    nu = max((CI90_UB_ab, CI90_LB_ab))
    
    // Return symmetric equivalence CI: (-nu, nu)
    return((-nu, nu))
}


/*---------------------------------------------------------------------------
 * compute_eq_ci_vec() - Vectorized equivalence CI computation
 *
 * Batch computation of equivalence confidence intervals.
 *
 * Arguments:
 *   estimates  : real colvector (n × 1), point estimates
 *   std_errors : real colvector (n × 1), standard errors
 *
 * Returns:
 *   real matrix (n × 2): each row is (-ν, ν) equivalence interval
 *---------------------------------------------------------------------------*/
real matrix compute_eq_ci_vec(real colvector estimates, real colvector std_errors)
{
    real scalar n, z_95, i
    real colvector CI90_UB, CI90_LB, CI90_UB_ab, CI90_LB_ab, nu
    real colvector invalid_mask
    real matrix result
    
    n = rows(estimates)
    
    // Dimension check
    if (rows(std_errors) != n) {
        _error("estimates and std_errors must have the same number of rows")
    }
    
    if (n == 0) {
        return(J(0, 2, .))
    }
    
    // 90% CI corresponds to 95% equivalence test
    z_95 = invnormal(0.95)
    
    // Vectorized computation
    CI90_UB = estimates :+ z_95 :* std_errors
    CI90_LB = estimates :- z_95 :* std_errors
    CI90_UB_ab = abs(CI90_UB)
    CI90_LB_ab = abs(CI90_LB)
    nu = rowmax((CI90_UB_ab, CI90_LB_ab))
    
    // Mark invalid entries
    invalid_mask = (estimates :>= .) :| (std_errors :>= .) :| (std_errors :<= 0)
    
    // Set nu to missing for invalid rows
    for (i = 1; i <= n; i++) {
        if (invalid_mask[i]) {
            nu[i] = .
        }
    }
    
    // Build result matrix: (-nu, nu)
    result = (-nu, nu)
    
    return(result)
}


// ============================================================================
// GENERALIZED K-DID: MATHEMATICAL HELPER FUNCTIONS
// ============================================================================
// Implements the k-th order difference operator from Appendix E.2 of
// Egami & Yamauchi (2022). The closed-form expansion is:
//
//   Δ^k_s(Ȳ_{g,T*+s}) = Ȳ_{g,T*+s} - Ȳ_{g,T*-1}
//                        - Σ_{j=1}^{k-1} M^{j+1}_s · Δ^j(Ȳ_{g,T*-1})
//
// where M^ℓ_s = C(s+ℓ-1, ℓ-1) is the binomial coefficient, and Δ^j is the
// standard j-th order finite difference on pre-treatment outcomes.
//
// Each k-th component estimator τ̂_k(s) can be computed via a standard 2×2
// DID regression on a "transformed outcome" that absorbs the pre-treatment
// polynomial trend, preserving the existing regression infrastructure.
// ============================================================================

/*---------------------------------------------------------------------------
 * compute_M_coeff() - Compute M^ℓ_s coefficient from paper Assumption E.1
 *
 * M^ℓ_s = Π_{j=1}^{ℓ-1} (s+j) / Π_{j=1}^{ℓ-1} j = C(s+ℓ-1, ℓ-1)
 *
 * Arguments:
 *   ell : real scalar, order ℓ (≥ 2)
 *   s   : real scalar, lead (≥ 0)
 *
 * Returns:
 *   real scalar: M^ℓ_s value
 *---------------------------------------------------------------------------*/
real scalar compute_M_coeff(real scalar ell, real scalar s)
{
    real scalar result, j

    if (ell < 2) {
        return(1)
    }

    result = 1
    for (j = 1; j <= ell - 1; j++) {
        result = result * (s + j) / j
    }

    return(result)
}

/*---------------------------------------------------------------------------
 * compute_kdid_pre_coefficients() - Compute pre-period transformation coeffs
 *
 * For the k-th component estimator with lead s, the Δ^k_s operator applied
 * to group means yields:
 *
 *   Δ^k_s(Ȳ_{g,T*+s}) = Ȳ_{g,T*+s} - α₀·Ȳ_{g,T*-1}
 *                        - α₁·Ȳ_{g,T*-2} - ... - α_{k-1}·Ȳ_{g,T*-k}
 *
 * This function returns the coefficient vector (α₀, α₁, ..., α_{k-1}).
 *
 * Derivation:
 *   α₀ = 1 + Σ_{j=1}^{k-1} M^{j+1}_s
 *   αₚ = Σ_{j=p}^{k-1} M^{j+1}_s · (-1)^p · C(j,p)   for p = 1..k-1
 *
 * These arise from expanding the closed-form Δ^k_s using the standard
 * finite difference Δ^j(Ȳ_{g,T*-1}) = Σ_{m=0}^{j} (-1)^m C(j,m) Ȳ_{g,T*-1-m}.
 *
 * Arguments:
 *   k : real scalar, component order (≥ 1)
 *   s : real scalar, lead (≥ 0)
 *
 * Returns:
 *   real rowvector (1 × k): (α₀, α₁, ..., α_{k-1})
 *
 * Special cases:
 *   k=1: (1)                   -- standard DID
 *   k=2, s=0: (2, -1)          -- sequential DID (lead=0)
 *   k=2, s>0: (s+2, -(s+1))   -- sequential DID (lead>0)
 *---------------------------------------------------------------------------*/
real rowvector compute_kdid_pre_coefficients(real scalar k, real scalar s)
{
    real rowvector alpha
    real scalar j, p, M_jp1, sign_p, comb_jp

    if (k < 1) {
        _error("compute_kdid_pre_coefficients: k must be >= 1")
    }

    alpha = J(1, k, 0)

    // α₀ = 1 + Σ_{j=1}^{k-1} M^{j+1}_s
    alpha[1] = 1
    for (j = 1; j <= k - 1; j++) {
        alpha[1] = alpha[1] + compute_M_coeff(j + 1, s)
    }

    // αₚ = Σ_{j=p}^{k-1} M^{j+1}_s · (-1)^p · C(j,p) for p = 1..k-1
    for (p = 1; p <= k - 1; p++) {
        sign_p = (mod(p, 2) == 0 ? 1 : -1)
        alpha[p + 1] = 0
        for (j = p; j <= k - 1; j++) {
            M_jp1 = compute_M_coeff(j + 1, s)
            comb_jp = comb(j, p)
            alpha[p + 1] = alpha[p + 1] + M_jp1 * sign_p * comb_jp
        }
    }

    return(alpha)
}

/*---------------------------------------------------------------------------
 * _kdid_outcome_by_lead() - Generalized k-th order transformed outcome
 *
 * For the k-th component estimator, constructs a transformed outcome such
 * that the standard 2×2 DID regression on {-1, lead} recovers τ̂_k(s).
 *
 * Post-period (time_std == lead): keeps Y unchanged.
 * Pre-period (time_std == -1):    replaces with
 *   Ỹ^{(k)}_{i,-1} = α₀ · Y_{i,T*-1} + Σ_{p=1}^{k-1} αₚ · Ȳ_{g_i,T*-1-p}
 *
 * For k=1 this is identity (standard DID).
 * For k=2 this matches _sdid_outcome_by_lead() exactly.
 *
 * Arguments:
 *   Y            : real colvector, outcome Y_it
 *   Gi           : real colvector, group indicator G_i (0/1)
 *   time_std     : real colvector, standardized time (0 = treatment period)
 *   id_unit      : real colvector, unit identifier
 *   support_mask : real colvector, valid observation mask
 *   lead         : real scalar, post-treatment period
 *   k            : real scalar, component order (≥ 1)
 *
 * Returns:
 *   real colvector: transformed outcome (same length as Y, missing where
 *                   the transformation cannot be computed)
 *---------------------------------------------------------------------------*/
real colvector _kdid_outcome_by_lead(real colvector Y,
                                     real colvector Gi,
                                     real colvector time_std,
                                     real colvector id_unit,
                                     real colvector support_mask,
                                     real scalar lead,
                                     real scalar k)
{
    real colvector result, idx_pre1, idx_post, idx_period, idx_valid
    real rowvector alpha
    real scalar g, p, mean_period, target_ts, n_Y
    real scalar alpha_0

    n_Y = rows(Y)
    result = J(n_Y, 1, .)

    // k=1: standard DID, the pre-period outcome is just Y itself
    if (k == 1) {
        // Post-period
        if (lead <= 0) {
            // lead=0: periods are {-1, 0}; post is time_std==0
            idx_post = selectindex((time_std :== 0) :& (support_mask :> 0) :& (Y :< .))
            if (length(idx_post) > 0) {
                result[idx_post] = Y[idx_post]
            }
            idx_pre1 = selectindex((time_std :== -1) :& (support_mask :> 0) :& (Y :< .))
            if (length(idx_pre1) > 0) {
                result[idx_pre1] = Y[idx_pre1]
            }
        }
        else {
            idx_post = selectindex((time_std :== lead) :& (support_mask :> 0) :& (Y :< .))
            if (length(idx_post) > 0) {
                result[idx_post] = Y[idx_post]
            }
            idx_pre1 = selectindex((time_std :== -1) :& (support_mask :> 0) :& (Y :< .))
            if (length(idx_pre1) > 0) {
                result[idx_pre1] = Y[idx_pre1]
            }
        }
        return(result)
    }

    // k >= 2: compute coefficients and construct transformed outcome
    alpha = compute_kdid_pre_coefficients(k, (lead <= 0 ? 0 : lead))
    alpha_0 = alpha[1]

    for (g = 0; g <= 1; g++) {

        // Post-period: keep Y unchanged
        if (lead <= 0) {
            target_ts = 0
        }
        else {
            target_ts = lead
        }
        idx_post = selectindex((Gi :== g) :& (time_std :== target_ts) :& (support_mask :> 0) :& (Y :< .))
        if (length(idx_post) > 0) {
            result[idx_post] = Y[idx_post]
        }

        // Pre-period (time_std == -1): build transformed outcome
        idx_pre1 = selectindex((Gi :== g) :& (time_std :== -1) :& (support_mask :> 0) :& (Y :< .))
        if (length(idx_pre1) == 0) {
            continue
        }

        // Start with α₀ · Y_{i,T*-1}
        result[idx_pre1] = alpha_0 :* Y[idx_pre1]

        // Add αₚ · Ȳ_{g,T*-1-p} for p = 1..k-1
        for (p = 1; p <= k - 1; p++) {
            // Find observations at time T*-1-p (i.e., time_std == -(p+1))
            idx_period = selectindex((Gi :== g) :& (time_std :== -(p + 1)) :& (Y :< .))
            if (length(idx_period) == 0) {
                // Cannot compute: need period T*-1-p but it's missing
                result[idx_pre1] = J(length(idx_pre1), 1, .)
                break
            }
            mean_period = mean(Y[idx_period])
            if (missing(mean_period)) {
                result[idx_pre1] = J(length(idx_pre1), 1, .)
                break
            }
            result[idx_pre1] = result[idx_pre1] :+ alpha[p + 1] * mean_period
        }
    }

    return(result)
}

/*---------------------------------------------------------------------------
 * kdid_max_k_for_lead() - Determine maximum feasible k for a given lead
 *
 * The k-th component requires pre-treatment periods T*-1, T*-2, ..., T*-k
 * with non-empty observations for both treatment and control groups.
 *
 * Arguments:
 *   Gi           : real colvector, group indicator (0/1)
 *   time_std     : real colvector, standardized time
 *   Y            : real colvector, outcome
 *   support_mask : real colvector, valid observation mask
 *   kmax_req     : real scalar, user-requested kmax
 *
 * Returns:
 *   real scalar: K_init = min(kmax_req, max feasible k)
 *---------------------------------------------------------------------------*/
real scalar kdid_max_k_for_lead(real colvector Gi,
                                real colvector time_std,
                                real colvector Y,
                                real colvector support_mask,
                                real scalar kmax_req)
{
    real scalar k, p, n_treat, n_control
    real colvector idx

    for (k = 1; k <= kmax_req; k++) {
        // k-th component needs period T*-1-p for p = 0..k-1
        // i.e., time_std == -1, -2, ..., -k
        for (p = 0; p <= k - 1; p++) {
            // Check treated group
            idx = selectindex((Gi :== 1) :& (time_std :== -(p + 1)) :& (support_mask :> 0) :& (Y :< .))
            n_treat = length(idx)
            // Check control group
            idx = selectindex((Gi :== 0) :& (time_std :== -(p + 1)) :& (support_mask :> 0) :& (Y :< .))
            n_control = length(idx)

            if (n_treat == 0 || n_control == 0) {
                return(k - 1)
            }
        }
    }

    return(kmax_req)
}


// ----------------------------------------------------------------------------
// MODULE VERIFICATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_estimators_loaded() - Verify module is loaded
 *---------------------------------------------------------------------------*/
void _did_estimators_loaded()
{
    printf("{txt}did_estimators.mata loaded successfully\n")
}

end
