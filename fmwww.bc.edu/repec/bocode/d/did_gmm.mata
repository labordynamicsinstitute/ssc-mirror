*! did_gmm.mata - GMM optimal weighting and double DID estimation
*!
*! Implements the generalized method of moments (GMM) framework for combining
*! the standard DID estimator and the sequential DID estimator into the double
*! difference-in-differences (double DID) estimator.
*!
*! GMM Objective:
*!   tau_dDID = argmin (tau - tau_DID, tau - tau_sDID)' W (tau - tau_DID, tau - tau_sDID)
*!
*! Optimal Weight Computation:
*!   W = Sigma^{-1}                             (precision matrix when invertible)
*!   w_DID  = (Var(sDID) - Cov) / (Var(DID) + Var(sDID) - 2*Cov)
*!   w_sDID = (Var(DID) - Cov) / (Var(DID) + Var(sDID) - 2*Cov)
*!   tau_dDID = w_DID * tau_DID + w_sDID * tau_sDID
*!   Var(tau_dDID) = 1 / sum(W) = w' Sigma w    (equivalent when W is available)

version 16.0

mata:
mata set matastrict on

// ============================================================================
// GMM OPTIMAL WEIGHTING AND DOUBLE DID ESTIMATION
// ============================================================================
// This module implements the GMM framework for double DID estimation:
//   1. Optimal weight matrix computation from bootstrap variance-covariance
//   2. Double DID point estimation combining DID and sequential DID
//   3. Staggered adoption design extensions with time-weighted aggregation
// ============================================================================

// ----------------------------------------------------------------------------
// DATA STRUCTURES
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * struct gmm_weights - GMM Optimal Weight Structure
 *
 * Stores the precision matrix and derived optimal weights for combining
 * the DID and sequential DID estimators via GMM.
 *---------------------------------------------------------------------------*/
struct gmm_weights {
    real matrix W                // W = Sigma^{-1}, precision matrix (2x2)
    real matrix vcov             // Sigma, bootstrap VCOV of (tau_DID, tau_sDID)
    real scalar w_did            // Optimal weight for DID estimator
    real scalar w_sdid           // Optimal weight for sequential DID estimator
}

/*---------------------------------------------------------------------------
 * struct ddid_result - Double DID Estimation Result
 *
 * Stores complete results from double DID estimation including point
 * estimates, variance, confidence intervals, and GMM weights.
 *---------------------------------------------------------------------------*/
struct ddid_result {
    real scalar estimate         // tau_dDID, double DID point estimate
    real scalar variance         // Var(tau_dDID), asymptotic or bootstrap
    real scalar std_error        // SE(tau_dDID) = sqrt(variance)
    real scalar ci_low           // Confidence interval lower bound
    real scalar ci_high          // Confidence interval upper bound
    real scalar w_did            // GMM weight for DID estimator
    real scalar w_sdid           // GMM weight for sequential DID estimator
    real scalar tau_did          // tau_DID, standard DID point estimate
    real scalar tau_sdid         // tau_sDID, sequential DID point estimate
    real scalar var_did          // Var(tau_DID) from bootstrap
    real scalar var_sdid         // Var(tau_sDID) from bootstrap
    real scalar lead             // Lead value (post-treatment periods ahead)
}

/*---------------------------------------------------------------------------
 * _boot_pair_cov() - Pairwise bootstrap covariance
 *
 * Computes sample covariance using only bootstrap draws where both series
 * are observed. Returns missing when fewer than two paired draws exist.
 *---------------------------------------------------------------------------*/
real scalar _boot_pair_cov(real colvector x, real colvector y)
{
    real colvector valid_idx
    real matrix pair_data

    valid_idx = selectindex((x :< .) :& (y :< .))
    if (rows(valid_idx) < 2) {
        return(.)
    }

    pair_data = x[valid_idx], y[valid_idx]
    return(compute_vcov(pair_data)[1, 2])
}

/*---------------------------------------------------------------------------
 * struct sa_ddid_result - Staggered Adoption Double DID Result
 *
 * Stores complete results for staggered adoption double DID estimation
 * across multiple lead values, including GMM weights and precision matrices.
 *---------------------------------------------------------------------------*/
struct sa_ddid_result {
    real colvector estimate      // tau_dDID, double DID estimates (n_lead x 1)
    real colvector variance      // Var(tau_dDID) from bootstrap (n_lead x 1)
    real colvector std_error     // SE(tau_dDID) = sqrt(variance) (n_lead x 1)
    real colvector ci_low        // CI lower bounds (n_lead x 1)
    real colvector ci_high       // CI upper bounds (n_lead x 1)
    real colvector w_did         // GMM weights for DID (n_lead x 1)
    real colvector w_sdid        // GMM weights for sequential DID (n_lead x 1)
    real colvector tau_did       // tau_DID estimates (n_lead x 1)
    real colvector tau_sdid      // tau_sDID estimates (n_lead x 1)
    real colvector var_did       // Var(tau_DID) from bootstrap (n_lead x 1)
    real colvector var_sdid      // Var(tau_sDID) from bootstrap (n_lead x 1)
    pointer vector W_matrices    // Precision matrices W, one per lead
    pointer vector VCOV_matrices // GMM covariance matrices Sigma, one per lead
}

/*---------------------------------------------------------------------------
 * recover_tiny_scale_weights() - Recover weights under tiny positive VCOV
 *
 * The common compute_weights() helper intentionally suppresses Double-DID
 * weights when the bootstrap VCOV is numerically near zero in absolute scale,
 * protecting truly degenerate zero-variation cases. This helper distinguishes
 * those cases from harmless outcome rescaling by checking whether the jointly
 * observed bootstrap pairs are structurally constant. When they are not,
 * normalizing Sigma by its own absolute scale preserves equation (14) weights
 * while avoiding the absolute 1e-24 guard.
 *---------------------------------------------------------------------------*/
struct gmm_weights scalar recover_tiny_scale_weights(real matrix vcov,
                                                     real matrix boot_pairs)
{
    struct gmm_weights scalar weights
    real colvector complete_idx
    real matrix complete_pairs, normalized_vcov
    real scalar vcov_scale, pair_level, pair_spread

    weights.vcov = vcov
    weights.W = J(2, 2, .)
    weights.w_did = .
    weights.w_sdid = .

    if (rows(vcov) != 2 || cols(vcov) != 2) {
        return(weights)
    }

    if (rows(boot_pairs) == 0 || cols(boot_pairs) != 2) {
        return(weights)
    }

    complete_idx = selectindex(rowmissing(boot_pairs) :== 0)
    if (rows(complete_idx) < 2) {
        return(weights)
    }

    complete_pairs = boot_pairs[complete_idx, .]

    // Preserve the zero-VCOV contract when every joint-valid bootstrap pair is
    // exactly constant. This is the structural-degeneracy case covered by the
    // existing round174/233 contract.
    if (max(abs(complete_pairs :- complete_pairs[1, .])) == 0) {
        return(weights)
    }

    pair_level = max(abs(complete_pairs))
    if (missing(pair_level) || pair_level <= 0) {
        return(weights)
    }

    // Preserve the zero-VCOV contract when the jointly observed bootstrap
    // pairs are effectively constant relative to their own level, which
    // indicates numerical drift around a structurally degenerate design rather
    // than a genuinely identified tiny-positive VCOV.
    pair_spread = max(abs(complete_pairs :- complete_pairs[1, .]))
    if (missing(pair_spread) || pair_spread / pair_level <= 1e-8) {
        return(weights)
    }

    vcov_scale = max(abs(vcov))
    if (missing(vcov_scale) || vcov_scale <= 0) {
        return(weights)
    }

    normalized_vcov = vcov / vcov_scale
    weights = compute_weights(normalized_vcov)
    weights.vcov = vcov

    // The normalized precision matrix is only an internal device to recover
    // scale-invariant weights. Do not expose it as the inverse of the original
    // tiny-scale VCOV.
    if (!missing(weights.w_did) && !missing(weights.w_sdid)) {
        weights.W = J(2, 2, .)
    }

    return(weights)
}

/*---------------------------------------------------------------------------
 * struct sa_ddid_var_result - Staggered Adoption Variance Result
 *
 * Stores bootstrap variance and percentile confidence intervals for
 * double DID, DID, and sequential DID estimators at a specific lead.
 *---------------------------------------------------------------------------*/
struct sa_ddid_var_result {
    real scalar var              // Bootstrap variance of double DID
    real rowvector ci_low        // Percentile CI lower bounds (dDID, DID, sDID)
    real rowvector ci_high       // Percentile CI upper bounds (dDID, DID, sDID)
}

// struct sa_point is defined in did_utils.mata (loaded before did_bootstrap.mata)

// ----------------------------------------------------------------------------
// GMM WEIGHT COMPUTATION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * compute_weights() - Compute Optimal GMM Weight Matrix
 *
 * Computes the optimal weight matrix W and derived scalar weights from
 * the bootstrap variance-covariance matrix of (tau_DID, tau_sDID).
 *
 * Arguments:
 *   vcov : real matrix (2x2) - Bootstrap VCOV matrix Sigma
 *
 * Returns:
 *   struct gmm_weights - Contains W, vcov, w_did, w_sdid
 *
 * GMM Weight Computation:
 *   W = Sigma^{-1}                                (precision matrix)
 *   w_DID  = (W[1,1] + W[1,2]) / sum(W)           (optimal DID weight)
 *   w_sDID = (W[2,2] + W[1,2]) / sum(W)           (optimal sDID weight)
 *
 * Closed-form equivalence:
 *   w_DID  = (Var(sDID) - Cov) / (Var(DID) + Var(sDID) - 2*Cov)
 *   w_sDID = (Var(DID) - Cov) / (Var(DID) + Var(sDID) - 2*Cov)
 *
 * Property: w_DID + w_sDID = 1.0 (convex combination)
 *---------------------------------------------------------------------------*/
struct gmm_weights scalar compute_weights(real matrix vcov)
{
    struct gmm_weights scalar weights
    real matrix W
    real scalar sum_W, success
    real rowvector eigs
    real scalar cond_num, vcov_maxabs
    real scalar var_did, var_sdid, cov_did_sdid
    real scalar denom, denom_tol
    
    // Initialize result structure with input VCOV and missing weights
    weights.vcov = vcov
    weights.W = J(2, 2, .)
    weights.w_did = .
    weights.w_sdid = .
    
    // -------------------------------------------------------------------------
    // Validate input dimensions
    // -------------------------------------------------------------------------
    if (rows(vcov) != 2 || cols(vcov) != 2) {
        errprintf("Error: VCOV must be a 2x2 matrix\n")
        return(weights)
    }
    
    // -------------------------------------------------------------------------
    // Validate variance positivity (diagonal elements must be non-negative)
    // -------------------------------------------------------------------------
    if (vcov[1,1] < 0 || vcov[2,2] < 0) {
        errprintf("Error: Negative variance detected\n")
        errprintf("  Var(DID) = %g, Var(sDID) = %g\n", vcov[1,1], vcov[2,2])
        return(weights)
    }

    var_did = vcov[1,1]
    var_sdid = vcov[2,2]
    cov_did_sdid = vcov[1,2]

    // -------------------------------------------------------------------------
    // Guard against structurally degenerate bootstrap VCOV matrices. A matrix
    // can have a benign condition number yet still be numerically zero in
    // absolute scale, in which case W = Var^{-1} is not a meaningful object.
    // -------------------------------------------------------------------------
    vcov_maxabs = max(abs(vcov))
    if (missing(vcov_maxabs) || vcov_maxabs <= 1e-24) {
        printf("{txt}Warning: Bootstrap VCOV is effectively zero; Double-DID weights are unavailable\n")
        printf("{txt}         DID and sDID are retained when separately identified\n")
        return(weights)
    }
    
    // -------------------------------------------------------------------------
    // Assess numerical stability via condition number
    // A high condition number indicates near-singularity
    // -------------------------------------------------------------------------
    eigs = symeigenvalues(vcov)
    if (min(eigs) > 0) {
        cond_num = max(eigs) / min(eigs)
        if (cond_num > 1e10) {
            printf("{txt}Warning: VCOV matrix is near-singular (cond=%g), results may be unreliable\n", cond_num)
        }
        else if (cond_num > 1e8) {
            printf("{txt}Note: VCOV matrix condition number is moderately large (cond=%g)\n", cond_num)
        }
    }
    
    // -------------------------------------------------------------------------
    // Compute precision matrix W = Sigma^{-1}
    // Tolerance 1e-10 used for numerical stability in matrix inversion
    // -------------------------------------------------------------------------
    W = safe_invert(vcov, 1e-10, &success)
    
    // -------------------------------------------------------------------------
    // Handle singular matrix case
    // -------------------------------------------------------------------------
    if (success == 0 || missing(W[1,1])) {
        denom = var_did + var_sdid - 2 * cov_did_sdid
        denom_tol = max((1e-12, 1e-8 * vcov_maxabs))

        if (!missing(denom) && denom > 0) {
            if (denom <= denom_tol) {
                printf("{txt}Note: VCOV matrix is singular and the equation (14) denominator is very small; using closed-form GMM weights\n")
            }
            else {
                printf("{txt}Note: VCOV matrix is singular; using closed-form GMM weights from equation (14)\n")
            }
            weights.w_did = (var_sdid - cov_did_sdid) / denom
            weights.w_sdid = (var_did - cov_did_sdid) / denom
            return(weights)
        }

        printf("{txt}Warning: Variance-covariance matrix is singular; Double-DID weights are unavailable\n")
        printf("{txt}         DID and sDID are retained when separately identified\n")
        weights.W = J(2, 2, .)
        weights.w_did = .
        weights.w_sdid = .
        return(weights)
    }
    
    // -------------------------------------------------------------------------
    // Compute weight sum: sum(W) = W[1,1] + W[2,2] + 2*W[1,2]
    // Even when this quantity becomes tiny in absolute scale after a pure
    // outcome rescaling, equation (14) remains unchanged because both the
    // numerator and denominator of the closed-form weights scale with VCOV.
    // -------------------------------------------------------------------------
    sum_W = sum(W)
    denom = var_did + var_sdid - 2 * cov_did_sdid
    denom_tol = max((1e-12, 1e-8 * vcov_maxabs))
    
    // -------------------------------------------------------------------------
    // Compute optimal GMM weights via the scale-invariant closed form
    // -------------------------------------------------------------------------
    weights.W = W
    if (missing(denom) || denom <= 0) {
        printf("{txt}Warning: Double-DID weight denominator is zero or near-zero; weights are unavailable\n")
        weights.w_did = .
        weights.w_sdid = .
        return(weights)
    }

    if (denom <= denom_tol) {
        printf("{txt}Note: Double-DID weight denominator is very small; using equation (14) closed-form weights\n")
    }

    if (missing(sum_W) || abs(sum_W) <= 1e-10) {
        printf("{txt}Note: sum(W) is near zero in absolute scale; using equation (14) closed-form weights\n")
    }

    weights.w_did = (var_sdid - cov_did_sdid) / denom
    weights.w_sdid = (var_did - cov_did_sdid) / denom
    
    // -------------------------------------------------------------------------
    // Verify convex combination property: w_DID + w_sDID = 1
    // -------------------------------------------------------------------------
    if (abs(weights.w_did + weights.w_sdid - 1.0) > 1e-10) {
        printf("{txt}Warning: GMM weights do not sum to 1.0 (sum = %18.15f)\n", 
               weights.w_did + weights.w_sdid)
    }
    
    // -------------------------------------------------------------------------
    // Check for weights outside [0,1] (occurs with high positive correlation)
    // -------------------------------------------------------------------------
    if (weights.w_did < 0 | weights.w_did > 1 | weights.w_sdid < 0 | weights.w_sdid > 1) {
        printf("{txt}Warning: GMM weights are outside [0,1] range (w_did=%g, w_sdid=%g)\n", 
               weights.w_did, weights.w_sdid)
        printf("{txt}         This may indicate high positive correlation between DID and sDID estimates\n")
    }
    
    return(weights)
}

/*---------------------------------------------------------------------------
 * _combine_bootstrap_ddid() - Combine bootstrap component draws for dDID
 *
 * Forms bootstrap dDID draws while respecting exact zero-weight components.
 * If a component weight is exactly zero, missing values in that component
 * must not invalidate the dDID draw.
 *---------------------------------------------------------------------------*/
real colvector _combine_bootstrap_ddid(real colvector boot_did,
                                       real colvector boot_sdid,
                                       real scalar w_did,
                                       real scalar w_sdid)
{
    real colvector boot_ddid
    real scalar n_boot, b
    real scalar use_did, use_sdid
    real scalar draw_val

    n_boot = rows(boot_did)
    if (rows(boot_sdid) != n_boot) {
        return(J(0, 1, .))
    }

    // Only an exact zero weight may drop a component from bootstrap draw
    // construction. Tiny but nonzero GMM weights still define the estimator
    // and therefore require jointly observed component draws.
    use_did = (!missing(w_did) && w_did != 0)
    use_sdid = (!missing(w_sdid) && w_sdid != 0)

    boot_ddid = J(n_boot, 1, .)

    for (b = 1; b <= n_boot; b++) {
        if (use_did && missing(boot_did[b])) {
            continue
        }
        if (use_sdid && missing(boot_sdid[b])) {
            continue
        }

        draw_val = 0
        if (use_did) {
            draw_val = draw_val + w_did * boot_did[b]
        }
        if (use_sdid) {
            draw_val = draw_val + w_sdid * boot_sdid[b]
        }

        boot_ddid[b] = draw_val
    }

    return(boot_ddid)
}

/*---------------------------------------------------------------------------
 * std_posted_joint_vcov() - Joint-valid covariance for posted standard DID vector
 *
 * The public multi-lead e(V) matrix should represent the covariance of the
 * posted estimator vector itself. We therefore use only bootstrap rows where
 * every posted component is jointly observed.
 *---------------------------------------------------------------------------*/
real matrix std_posted_joint_vcov(real matrix boot_posted)
{
    return(compute_vcov_joint_valid(boot_posted))
}

// ----------------------------------------------------------------------------
// DOUBLE DID ESTIMATION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * compute_double_did() - Compute Double DID Point Estimate and Inference
 *
 * Combines the DID and sequential DID estimators using optimal GMM weights
 * to produce the double DID estimator with variance and confidence intervals.
 *
 * Arguments:
 *   tau_did   : real scalar - Standard DID point estimate
 *   tau_sdid  : real scalar - Sequential DID point estimate
 *   weights   : struct gmm_weights - Optimal weights from compute_weights()
 *   boot_est  : real matrix (B x 2) - Bootstrap estimates [tau_DID, tau_sDID] (optional)
 *   se_boot   : real scalar - Inference method: 0 = asymptotic, 1 = bootstrap
 *   level     : real scalar - Confidence level in percent (default: 95)
 *
 * Returns:
 *   struct ddid_result - Complete double DID results
 *
 * Point Estimation:
 *   tau_dDID = w_DID * tau_DID + w_sDID * tau_sDID
 *
 * Asymptotic Inference (se_boot = 0):
 *   Var(tau_dDID) = 1 / sum(W) when W is numerically reliable
 *   Var(tau_dDID) = w' Sigma w when W is unavailable or tiny in absolute scale
 *   CI: tau_dDID +/- z_{alpha/2} * sqrt(Var)
 *
 * Bootstrap Inference (se_boot = 1):
 *   tau_dDID^{(b)} = w_DID * tau_DID^{(b)} + w_sDID * tau_sDID^{(b)}
 *   Var(tau_dDID) = sample variance of tau_dDID^{(b)}
 *   CI: percentile method at (alpha/2, 1-alpha/2)
 *---------------------------------------------------------------------------*/
struct ddid_result scalar compute_double_did(real scalar tau_did,
                                             real scalar tau_sdid,
                                             struct gmm_weights scalar weights,
                                             | real matrix boot_est,
                                             real scalar se_boot,
                                             real scalar level)
{
    struct ddid_result scalar result
    real scalar tau_ddid, var_ddid, var_did, var_sdid
    real scalar alpha, z, n_boot
    real colvector boot_ddid
    real scalar w_did, w_sdid
    
    // -------------------------------------------------------------------------
    // Set default parameters
    // -------------------------------------------------------------------------
    if (args() < 5) se_boot = 0
    if (args() < 6) level = 95
    
    // Validate confidence level
    if (level <= 0 || level >= 100) {
        printf("{txt}Warning: Invalid confidence level %g%%, using 95%%\n", level)
        level = 95
    }
    
    // -------------------------------------------------------------------------
    // Extract weights
    // -------------------------------------------------------------------------
    w_did = weights.w_did
    w_sdid = weights.w_sdid
    
    // Return missing result if weights are invalid
    if (missing(w_did) || missing(w_sdid)) {
        result.estimate = .
        result.variance = .
        result.std_error = .
        result.ci_low = .
        result.ci_high = .
        result.w_did = .
        result.w_sdid = .
        result.tau_did = tau_did
        result.tau_sdid = tau_sdid
        result.var_did = .
        result.var_sdid = .
        result.lead = .
        return(result)
    }
    
    // -------------------------------------------------------------------------
    // Compute double DID point estimate as weighted combination
    // -------------------------------------------------------------------------
    tau_ddid = w_did * tau_did + w_sdid * tau_sdid
    
    // -------------------------------------------------------------------------
    // Extract component variances from bootstrap VCOV diagonal
    // -------------------------------------------------------------------------
    var_did = weights.vcov[1,1]
    var_sdid = weights.vcov[2,2]
    
    // -------------------------------------------------------------------------
    // Compute critical value for confidence interval
    // -------------------------------------------------------------------------
    alpha = 1 - level / 100
    z = invnormal(1 - alpha / 2)
    
    // -------------------------------------------------------------------------
    // Select inference method based on se_boot flag and bootstrap availability
    // -------------------------------------------------------------------------
    n_boot = (args() >= 4 && rows(boot_est) > 0) ? rows(boot_est) : 0
    
    if (se_boot == 0 || n_boot < 2) {
        // ---------------------------------------------------------------------
        // Asymptotic inference: variance derived from precision matrix
        // ---------------------------------------------------------------------
        {
            real scalar sum_W
            if (!missing(weights.W[1,1])) {
                sum_W = sum(weights.W)
                if (!missing(sum_W) && abs(sum_W) > 1e-10) {
                    var_ddid = 1 / sum_W
                    result.ci_low = tau_ddid - z * sqrt(var_ddid)
                    result.ci_high = tau_ddid + z * sqrt(var_ddid)
                }
                else {
                    // When sum(W) becomes tiny after a pure scale change, fall
                    // back to the scale-invariant quadratic form w' Σ w.
                    var_ddid = w_did^2 * var_did + 2 * w_did * w_sdid * weights.vcov[1,2] + w_sdid^2 * var_sdid
                    if (!missing(var_ddid) && var_ddid < 0 && abs(var_ddid) <= 1e-12) {
                        var_ddid = 0
                    }

                    if (missing(var_ddid) || var_ddid < 0) {
                        result.ci_low = .
                        result.ci_high = .
                    }
                    else {
                        result.ci_low = tau_ddid - z * sqrt(var_ddid)
                        result.ci_high = tau_ddid + z * sqrt(var_ddid)
                    }
                }
            }
            else {
                var_ddid = w_did^2 * var_did + 2 * w_did * w_sdid * weights.vcov[1,2] + w_sdid^2 * var_sdid
                if (!missing(var_ddid) && var_ddid < 0 && abs(var_ddid) <= 1e-12) {
                    var_ddid = 0
                }

                if (missing(var_ddid) || var_ddid < 0) {
                    result.ci_low = .
                    result.ci_high = .
                }
                else {
                    result.ci_low = tau_ddid - z * sqrt(var_ddid)
                    result.ci_high = tau_ddid + z * sqrt(var_ddid)
                }
            }
        }
    } 
    else {
        // ---------------------------------------------------------------------
        // Bootstrap inference: variance and CI from bootstrap distribution
        // ---------------------------------------------------------------------
        
        // Apply GMM weights to bootstrap estimates while allowing zero-weight
        // components to drop out of the bootstrap draw construction.
        boot_ddid = _combine_bootstrap_ddid(boot_est[., 1], boot_est[., 2],
                                            w_did, w_sdid)
        
        // Exclude missing values before variance computation
        real colvector boot_ddid_valid
        real scalar n_valid
        boot_ddid_valid = select(boot_ddid, boot_ddid :< .)
        n_valid = rows(boot_ddid_valid)
        
        // Sample variance with Bessel correction (B-1 denominator)
        if (n_valid >= 2) {
            var_ddid = variance(boot_ddid_valid)
            result.ci_low = quantile_sorted(boot_ddid_valid, alpha / 2)
            result.ci_high = quantile_sorted(boot_ddid_valid, 1 - alpha / 2)
        }
        else {
            var_ddid = .
            result.ci_low = .
            result.ci_high = .
        }
    }
    
    // -------------------------------------------------------------------------
    // Populate result structure with all computed values
    // -------------------------------------------------------------------------
    result.estimate = tau_ddid
    result.variance = var_ddid
    result.std_error = sqrt(var_ddid)
    result.w_did = w_did
    result.w_sdid = w_sdid
    result.tau_did = tau_did
    result.tau_sdid = tau_sdid
    result.var_did = var_did
    result.var_sdid = var_sdid
    result.lead = .
    
    return(result)
}

// ----------------------------------------------------------------------------
// STAGGERED ADOPTION DESIGN FUNCTIONS
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * sa_to_ddid() - Staggered Adoption Double DID Estimation
 *
 * Computes the double DID estimator for staggered adoption designs across
 * multiple lead values using GMM optimal weighting at each lead.
 *
 * Arguments:
 *   point_est : struct sa_point - Time-weighted DID and sDID estimates
 *   boot_est  : pointer vector - Bootstrap sa_point structures (B elements)
 *   lead      : real rowvector - Lead values, e.g., (0) or (0, 1, 2)
 *   level     : real scalar - Confidence level in percent (default: 95)
 *
 * Returns:
 *   struct sa_ddid_result - Complete results for all lead values
 *
 * Algorithm (for each lead value l):
 *   1. Compute bootstrap VCOV: Sigma_l = sa_calc_cov(boot_est, l)
 *   2. Compute precision matrix: W_l = Sigma_l^{-1}
 *   3. Compute GMM weights:
 *        w_DID  = (W[1,1] + W[1,2]) / sum(W)
 *        w_sDID = (W[2,2] + W[1,2]) / sum(W)
 *   4. Compute double DID: tau_dDID = w_DID * tau_DID + w_sDID * tau_sDID
 *   5. Compute bootstrap variance and percentile CI via sa_calc_ddid_var()
 *---------------------------------------------------------------------------*/
struct sa_ddid_result scalar sa_to_ddid(struct sa_point scalar point_est,
                                        pointer(struct sa_point scalar) vector boot_est,
                                        real rowvector lead,
                                        real scalar level)
{
    struct sa_ddid_result scalar result
    struct sa_ddid_var_result scalar var_result
    struct gmm_weights scalar weights
    real matrix VC, VC_component, boot_pairs
    real scalar n_lead, n_boot, ll, lead_idx
    real scalar w_did, w_sdid
    real scalar tau_did, tau_sdid, tau_ddid
    real scalar var_did, var_sdid, var_ddid
    real scalar success
    
    // -------------------------------------------------------------------------
    // Set default parameters and validate inputs
    // -------------------------------------------------------------------------
    if (args() < 4) level = 95
    
    n_lead = cols(lead)
    n_boot = length(boot_est)
    
    // -------------------------------------------------------------------------
    // Initialize result structure
    // -------------------------------------------------------------------------
    result.estimate = J(n_lead, 1, .)
    result.variance = J(n_lead, 1, .)
    result.std_error = J(n_lead, 1, .)
    result.ci_low = J(n_lead, 1, .)
    result.ci_high = J(n_lead, 1, .)
    result.w_did = J(n_lead, 1, .)
    result.w_sdid = J(n_lead, 1, .)
    result.tau_did = J(n_lead, 1, .)
    result.tau_sdid = J(n_lead, 1, .)
    result.var_did = J(n_lead, 1, .)
    result.var_sdid = J(n_lead, 1, .)
    result.W_matrices = J(n_lead, 1, NULL)
    result.VCOV_matrices = J(n_lead, 1, NULL)
    
    // -------------------------------------------------------------------------
    // Validate bootstrap sample availability
    // -------------------------------------------------------------------------
    if (n_boot == 0) {
        errprintf("sa_to_ddid(): No Bootstrap samples\n")
        return(result)
    }
    
    if (n_boot < 2) {
        errprintf("sa_to_ddid(): Cannot compute variance with single Bootstrap sample\n")
        return(result)
    }
    
    // -------------------------------------------------------------------------
    // Loop over each lead value
    // -------------------------------------------------------------------------
    for (ll = 1; ll <= n_lead; ll++) {
        
        // Lead index for bootstrap access (1-based)
        lead_idx = ll
        
        // ---------------------------------------------------------------------
        // Get point estimates for this lead
        // ---------------------------------------------------------------------
        tau_did = point_est.DID[ll]
        tau_sdid = point_est.sDID[ll]
        
        result.tau_did[ll] = tau_did
        result.tau_sdid[ll] = tau_sdid
        
        // ---------------------------------------------------------------------
        // Compute component variances and the joint-valid GMM covariance
        // separately. SA component SEs use marginally valid bootstrap draws,
        // while the efficient-GMM weight matrix must be based on the jointly
        // observed bootstrap vector.
        // ---------------------------------------------------------------------
        VC_component = sa_calc_cov(boot_est, lead_idx)
        VC = sa_calc_gmm_cov(boot_est, lead_idx)
        boot_pairs = sa_collect_boot_draws(boot_est, lead_idx)
        result.VCOV_matrices[ll] = &(VC)

        // Handle invalid component variances
        if (missing(VC_component[1,1]) || missing(VC_component[2,2])) {
            errprintf("{err}Warning: Failed to compute component bootstrap variances for lead %g\n", lead[ll])
            errprintf("{err}         SA-DID / SA-sDID require at least two valid bootstrap draws each\n")
            result.estimate[ll] = .
            result.variance[ll] = .
            result.std_error[ll] = .
            result.ci_low[ll] = .
            result.ci_high[ll] = .
            result.w_did[ll] = .
            result.w_sdid[ll] = .
            result.var_did[ll] = .
            result.var_sdid[ll] = .
            continue
        }

        // Store marginal component variances
        var_did = VC_component[1,1]
        var_sdid = VC_component[2,2]
        result.var_did[ll] = var_did
        result.var_sdid[ll] = var_sdid

        // Handle invalid joint-valid GMM covariance
        if (missing(VC[1,1]) || missing(VC[1,2]) || missing(VC[2,2])) {
            errprintf("{err}Warning: Failed to compute joint-valid GMM covariance for lead %g\n", lead[ll])
            errprintf("{err}         SA-Double-DID requires at least two jointly observed bootstrap pairs\n")
            result.estimate[ll] = .
            result.variance[ll] = .
            result.std_error[ll] = .
            result.ci_low[ll] = .
            result.ci_high[ll] = .
            result.w_did[ll] = .
            result.w_sdid[ll] = .
            continue
        }
        
        // ---------------------------------------------------------------------
        // Compute GMM weights from the bootstrap VCOV. When the VCOV is
        // singular but the closed-form equation (14) denominator remains
        // positive, compute_weights() falls back to the scalar formula.
        // ---------------------------------------------------------------------
        weights = compute_weights(VC)
        if (missing(weights.w_did) || missing(weights.w_sdid)) {
            weights = recover_tiny_scale_weights(VC, boot_pairs)
            if (!missing(weights.w_did) && !missing(weights.w_sdid)) {
                printf("{txt}Note: SA joint-valid bootstrap VCOV is tiny but non-degenerate; using scale-normalized equation (14) weights\n")
            }
        }
        w_did = weights.w_did
        w_sdid = weights.w_sdid

        if (missing(w_did) || missing(w_sdid)) {
            errprintf("{err}Warning: Variance-covariance matrix is singular for lead %g\n", lead[ll])
            errprintf("{err}         Cannot compute GMM weights for SA design\n")
            errprintf("{err}         This may be caused by:\n")
            errprintf("{err}         - Insufficient bootstrap samples for this lead\n")
            errprintf("{err}         - Collinear data at this lead value\n")
            errprintf("{err}         - Insufficient variation in treatment timing\n")
            result.estimate[ll] = .
            result.variance[ll] = .
            result.std_error[ll] = .
            result.ci_low[ll] = .
            result.ci_high[ll] = .
            result.w_did[ll] = .
            result.w_sdid[ll] = .
            continue
        }

        if (!missing(weights.W[1,1])) {
            result.W_matrices[ll] = &(safe_invert(VC, 1e-10, &success))
        }
        
        // Verify convex combination property
        if (abs(w_did + w_sdid - 1.0) > 1e-10) {
            printf("{txt}Warning: GMM weights do not sum to 1.0 for lead %g (sum = %18.15f)\n", 
                   lead[ll], w_did + w_sdid)
        }
        
        // Warn if weights are outside [0,1] range
        if (w_did < 0 | w_did > 1 | w_sdid < 0 | w_sdid > 1) {
            printf("{txt}Warning: GMM weights outside [0,1] for lead %g (w_did=%g, w_sdid=%g)\n", 
                   lead[ll], w_did, w_sdid)
            printf("{txt}         This may indicate high positive correlation between DID and sDID estimates\n")
        }
        
        result.w_did[ll] = w_did
        result.w_sdid[ll] = w_sdid
        
        // ---------------------------------------------------------------------
        // Compute SA-Double-DID point estimate
        // tau_dDID = w_did * tau_DID + w_sdid * tau_sDID
        // ---------------------------------------------------------------------
        tau_ddid = w_did * tau_did + w_sdid * tau_sdid
        result.estimate[ll] = tau_ddid
        
        // ---------------------------------------------------------------------
        // Compute bootstrap variance and CI
        // ---------------------------------------------------------------------
        var_result = sa_calc_ddid_var(boot_est, lead_idx, w_did, w_sdid, level)
        
        // Store variance and standard error
        var_ddid = var_result.var
        result.variance[ll] = var_ddid
        result.std_error[ll] = sqrt(var_ddid)
        
        // Store CI bounds
        result.ci_low[ll] = var_result.ci_low[1]
        result.ci_high[ll] = var_result.ci_high[1]
    }
    
    return(result)
}

/*---------------------------------------------------------------------------
 * sa_collect_boot_draws() - Gather SA Bootstrap DID / sDID Draws
 *
 * Extracts the lead-specific bootstrap vector used by both component
 * variance summaries and the joint GMM covariance.
 *---------------------------------------------------------------------------*/
real matrix sa_collect_boot_draws(pointer(struct sa_point scalar) vector boot_est,
                                  real scalar lead_idx)
{
    real matrix combined
    real scalar n_boot, b
    struct sa_point scalar pt

    n_boot = length(boot_est)
    if (n_boot == 0) return(J(0, 2, .))

    combined = J(n_boot, 2, .)

    for (b = 1; b <= n_boot; b++) {
        if (boot_est[b] == NULL) {
            continue
        }

        pt = *boot_est[b]
        if (lead_idx < 1 || lead_idx > cols(pt.DID) || lead_idx > cols(pt.sDID)) {
            continue
        }

        combined[b, 1] = pt.DID[lead_idx]
        combined[b, 2] = pt.sDID[lead_idx]
    }

    return(combined)
}

/*---------------------------------------------------------------------------
 * sa_calc_cov() - Compute Marginal Bootstrap VCOV for SA Components
 *
 * Returns the component bootstrap covariance surface used for SA-DID / SA-sDID
 * variances: diagonal entries use all marginally valid draws while the
 * off-diagonal continues to use jointly observed bootstrap pairs.
 *---------------------------------------------------------------------------*/
real matrix sa_calc_cov(pointer(struct sa_point scalar) vector boot_est, real scalar lead_idx)
{
    real matrix combined, vcov
    real scalar n_valid_did, n_valid_sdid

    combined = sa_collect_boot_draws(boot_est, lead_idx)
    if (rows(combined) < 2) {
        return(J(2, 2, .))
    }

    n_valid_did = rows(select(combined[., 1], combined[., 1] :< .))
    n_valid_sdid = rows(select(combined[., 2], combined[., 2] :< .))
    if (n_valid_did < 2 || n_valid_sdid < 2) {
        return(J(2, 2, .))
    }

    vcov = compute_vcov_pairwise(combined)
    return(vcov)
}

/*---------------------------------------------------------------------------
 * sa_calc_gmm_cov() - Compute Joint-Valid GMM Covariance for SA dDID
 *
 * The efficient-GMM weight matrix in the paper is defined on the jointly
 * observed bootstrap vector (tau_DID^b, tau_sDID^b). This helper therefore
 * uses only complete bootstrap pairs when assembling the 2x2 covariance sent
 * into compute_weights().
 *---------------------------------------------------------------------------*/
real matrix sa_calc_gmm_cov(pointer(struct sa_point scalar) vector boot_est, real scalar lead_idx)
{
    real matrix combined
    real scalar n_valid_did, n_valid_sdid

    combined = sa_collect_boot_draws(boot_est, lead_idx)
    if (rows(combined) < 2) {
        return(J(2, 2, .))
    }

    n_valid_did = rows(select(combined[., 1], combined[., 1] :< .))
    n_valid_sdid = rows(select(combined[., 2], combined[., 2] :< .))
    if (n_valid_did < 2 || n_valid_sdid < 2) {
        return(J(2, 2, .))
    }

    return(compute_vcov_joint_valid(combined))
}

/*---------------------------------------------------------------------------
 * sa_calc_ddid_var() - Compute Bootstrap Variance and CI for SA Double DID
 *
 * Computes bootstrap variance and percentile confidence intervals for the
 * double DID estimator and its component estimators (DID and sequential DID).
 *
 * Arguments:
 *   boot_est : pointer vector - Bootstrap sa_point structures (B elements)
 *   lead_idx : real scalar - Lead index (1-based)
 *   w_did    : real scalar - GMM weight for DID estimator
 *   w_sdid   : real scalar - GMM weight for sequential DID estimator
 *   level    : real scalar - Confidence level in percent (default: 95)
 *
 * Returns:
 *   struct sa_ddid_var_result:
 *     var     : Bootstrap variance of SA-Double-DID
 *     ci_low  : (1x3) lower CI bounds for (dDID, DID, sDID)
 *     ci_high : (1x3) upper CI bounds for (dDID, DID, sDID)
 *---------------------------------------------------------------------------*/
struct sa_ddid_var_result scalar sa_calc_ddid_var(pointer(struct sa_point scalar) vector boot_est,
                                                   real scalar lead_idx,
                                                   real scalar w_did,
                                                   real scalar w_sdid,
                                                   real scalar level)
{
    struct sa_ddid_var_result scalar result
    struct sa_point scalar pt
    real colvector boot_ddid, boot_did, boot_sdid
    real scalar n_boot, b, alpha
    
    // -------------------------------------------------------------------------
    // Set default parameters
    // -------------------------------------------------------------------------
    if (args() < 5) level = 95
    
    // Initialize result with missing values
    result.var = .
    result.ci_low = (., ., .)
    result.ci_high = (., ., .)
    
    n_boot = length(boot_est)
    
    // -------------------------------------------------------------------------
    // Require at least 2 bootstrap samples for variance estimation
    // -------------------------------------------------------------------------
    if (n_boot == 0) {
        return(result)
    }
    
    if (n_boot < 2) {
        return(result)
    }
    
    // -------------------------------------------------------------------------
    // Extract bootstrap estimates and apply GMM weights
    // -------------------------------------------------------------------------
    boot_ddid = J(n_boot, 1, .)
    boot_did = J(n_boot, 1, .)
    boot_sdid = J(n_boot, 1, .)
    
    for (b = 1; b <= n_boot; b++) {
        // Skip null pointers from failed bootstrap iterations
        if (boot_est[b] == NULL) {
            continue
        }
        
        // Dereference pointer to access bootstrap estimates
        pt = *boot_est[b]
        
        // Validate lead_idx bounds before vector access
        if (lead_idx < 1 || lead_idx > cols(pt.DID) || lead_idx > cols(pt.sDID)) {
            continue
        }
        
        // Extract bootstrap estimates for this lead
        boot_did[b] = pt.DID[lead_idx]
        boot_sdid[b] = pt.sDID[lead_idx]
        
    }

    boot_ddid = _combine_bootstrap_ddid(boot_did, boot_sdid, w_did, w_sdid)
    
    // -------------------------------------------------------------------------
    // Exclude missing values before variance computation
    // -------------------------------------------------------------------------
    real colvector boot_ddid_valid, boot_did_valid, boot_sdid_valid
    real scalar n_valid
    
    boot_ddid_valid = select(boot_ddid, boot_ddid :< .)
    n_valid = rows(boot_ddid_valid)
    
    // -------------------------------------------------------------------------
    // Compute sample variance with Bessel correction (n-1 denominator)
    // -------------------------------------------------------------------------
    if (n_valid >= 2) {
        result.var = variance(boot_ddid_valid)
    }
    
    // -------------------------------------------------------------------------
    // Compute percentile confidence intervals from bootstrap distribution
    // -------------------------------------------------------------------------
    alpha = 1 - level / 100
    
    // Double DID percentile CI must fail closed below the two-draw floor.
    if (n_valid >= 2) {
        result.ci_low[1] = quantile_sorted(boot_ddid_valid, alpha / 2)
        result.ci_high[1] = quantile_sorted(boot_ddid_valid, 1 - alpha / 2)
    }
    
    // DID percentile CI
    result.ci_low[2] = quantile_sorted(boot_did, alpha / 2)
    result.ci_high[2] = quantile_sorted(boot_did, 1 - alpha / 2)
    
    // Sequential DID percentile CI
    result.ci_low[3] = quantile_sorted(boot_sdid, alpha / 2)
    result.ci_high[3] = quantile_sorted(boot_sdid, 1 - alpha / 2)
    
    return(result)
}

// ============================================================================
// GENERALIZED K-DID: K-DIMENSIONAL GMM
// ============================================================================

/*---------------------------------------------------------------------------
 * struct gmm_weights_k - K-dimensional GMM weight structure
 *---------------------------------------------------------------------------*/
struct gmm_weights_k {
    real matrix W                // W = Sigma^{-1}, precision matrix (K×K)
    real matrix vcov             // Sigma, bootstrap VCOV (K×K)
    real rowvector weights       // Optimal weights (1×K), sum to 1
    real scalar K_final          // Number of moments actually used
    real rowvector moment_mask   // 1×kmax, 1 = moment used, 0 = dropped
    real rowvector dropped_numerical  // 1×kmax, 1 = dropped for numerical reasons
    real rowvector dropped_jtest      // 1×kmax, 1 = dropped by J-test
    real scalar jtest_stat       // J-test statistic (. if not computed)
    real scalar jtest_df         // J-test degrees of freedom
    real scalar jtest_pval       // J-test p-value
}

/*---------------------------------------------------------------------------
 * compute_weights_k() - Compute optimal GMM weights for K moments
 *
 * Generalizes compute_weights() to K dimensions.
 *
 * GMM optimal weights: w = (1'W1)^{-1} W 1  where W = Sigma^{-1}
 * GMM variance: Var(τ̂) = (1'W1)^{-1}
 *
 * Includes numerical fallback: if Sigma is singular or ill-conditioned,
 * drops the highest-order moment and retries until invertible or K=1.
 *
 * Arguments:
 *   vcov_full : real matrix (K×K) - Bootstrap VCOV matrix
 *   kmax      : real scalar - original kmax
 *
 * Returns:
 *   struct gmm_weights_k - weights, diagnostics
 *---------------------------------------------------------------------------*/
struct gmm_weights_k scalar compute_weights_k(real matrix vcov_full,
                                               real scalar kmax)
{
    struct gmm_weights_k scalar result
    real matrix vcov_sub, W_sub
    real colvector ones_sub
    real rowvector eigs, w_sub
    real scalar K_try, success, sum_W, cond_num, vcov_maxabs
    real scalar i, j, idx_out

    // Initialize result
    result.W = J(kmax, kmax, .)
    result.vcov = vcov_full
    result.weights = J(1, kmax, .)
    result.K_final = 0
    result.moment_mask = J(1, kmax, 1)
    result.dropped_numerical = J(1, kmax, 0)
    result.dropped_jtest = J(1, kmax, 0)
    result.jtest_stat = .
    result.jtest_df = .
    result.jtest_pval = .

    // Try from full K down to 1
    for (K_try = kmax; K_try >= 1; K_try--) {

        // Extract submatrix for moments 1..K_try
        vcov_sub = vcov_full[1..K_try, 1..K_try]

        // Check for missing values
        if (hasmissing(vcov_sub)) {
            // Mark highest moment as numerically dropped
            if (K_try <= kmax) {
                result.dropped_numerical[K_try] = 1
                result.moment_mask[K_try] = 0
            }
            continue
        }

        // Check for negative variances
        real scalar has_neg_var
        has_neg_var = 0
        for (i = 1; i <= K_try; i++) {
            if (vcov_sub[i, i] < 0) {
                has_neg_var = 1
                break
            }
        }
        if (has_neg_var) {
            result.dropped_numerical[K_try] = 1
            result.moment_mask[K_try] = 0
            continue
        }

        // Check absolute scale
        vcov_maxabs = max(abs(vcov_sub))
        if (missing(vcov_maxabs) || vcov_maxabs <= 1e-24) {
            result.dropped_numerical[K_try] = 1
            result.moment_mask[K_try] = 0
            continue
        }

        // Check condition number
        eigs = symeigenvalues(vcov_sub)
        if (min(eigs) <= 0) {
            result.dropped_numerical[K_try] = 1
            result.moment_mask[K_try] = 0
            continue
        }
        cond_num = max(eigs) / min(eigs)
        if (cond_num > 1e12) {
            result.dropped_numerical[K_try] = 1
            result.moment_mask[K_try] = 0
            continue
        }

        // Invert
        W_sub = safe_invert(vcov_sub, 1e-10, &success)
        if (success == 0 || hasmissing(W_sub)) {
            result.dropped_numerical[K_try] = 1
            result.moment_mask[K_try] = 0
            continue
        }

        // Compute weights: w = (1'W1)^{-1} W 1
        ones_sub = J(K_try, 1, 1)
        sum_W = ones_sub' * W_sub * ones_sub
        if (missing(sum_W) || sum_W <= 0) {
            result.dropped_numerical[K_try] = 1
            result.moment_mask[K_try] = 0
            continue
        }

        w_sub = (W_sub * ones_sub)' / sum_W

        // Success: store results
        // Embed K_try × K_try results into kmax × kmax structure
        result.W = J(kmax, kmax, .)
        result.W[1..K_try, 1..K_try] = W_sub
        result.weights = J(1, kmax, .)
        result.weights[1..K_try] = w_sub
        result.K_final = K_try

        // Mark moments K_try+1..kmax as dropped
        for (i = K_try + 1; i <= kmax; i++) {
            result.moment_mask[i] = 0
            if (result.dropped_jtest[i] == 0) {
                result.dropped_numerical[i] = 1
            }
        }

        return(result)
    }

    // All moments failed: K_final = 0
    printf("{txt}Warning: All K-DID moments failed numerical checks; no valid GMM estimate\n")
    return(result)
}

/*---------------------------------------------------------------------------
 * jtest_select() - J-test moment selection for K-DID
 *
 * Uses Hansen's J-statistic for overidentification testing.
 * Lowest-order-first nested deletion: tests full set first, if rejected
 * at alpha=0.05, drops k=K_start (lowest-order moment), re-tests, etc.
 *
 * Rationale: PTT₁ ⊂ PTT₂ ⊂ ... ⊂ PTT_K (PTT₁ is the most restrictive).
 * If the J-test rejects, the lowest-order moment (standard parallel trends)
 * is most likely violated. Dropping from the bottom preserves higher-order
 * moments that require weaker assumptions.
 *
 * J = g(τ̂)' W g(τ̂), df = K_active - 1, under H0 ~ chi2(df)
 * where g(τ) = τ̂ · 1 - τ_components (active subset).
 *
 * Arguments:
 *   tau_components : real rowvector (1×K) - component estimates
 *   vcov_k        : real matrix (K×K) - bootstrap VCOV
 *   K_init        : real scalar - initial number of moments
 *   alpha_j       : real scalar - significance level (default 0.05)
 *
 * Returns:
 *   struct gmm_weights_k - with jtest fields filled, moment_mask indicating
 *                          which moments are active (may not start from k=1)
 *---------------------------------------------------------------------------*/
struct gmm_weights_k scalar jtest_select(real rowvector tau_components,
                                          real matrix vcov_k,
                                          real scalar K_init,
                                          | real scalar alpha_j)
{
    struct gmm_weights_k scalar result
    real scalar _alpha, K_start, K_sel, K_active
    real scalar tau_gmm, sum_W, J_stat, J_df, J_pval, success
    real matrix vcov_sub, W_sub
    real colvector g_vec, ones_sub, active_idx
    real rowvector w_sub, tau_active
    real scalar kmax, i, j

    _alpha = (args() >= 4 ? alpha_j : 0.05)
    kmax = cols(tau_components)

    // Start with compute_weights_k to get initial numerical feasibility
    result = compute_weights_k(vcov_k, kmax)

    // If K_final <= 1, J-test is not applicable (just-identified or failed)
    if (result.K_final <= 1) {
        return(result)
    }

    // K_sel = numerically feasible upper bound from compute_weights_k
    K_sel = result.K_final

    // Lowest-order-first nested deletion:
    // Test {K_start, K_start+1, ..., K_sel}
    // On rejection, drop k=K_start (lowest in current set), try K_start+1
    for (K_start = 1; K_start <= K_sel - 1; K_start++) {

        K_active = K_sel - K_start + 1

        // Build active index vector: K_start, K_start+1, ..., K_sel
        active_idx = (K_start::K_sel)

        // Extract VCOV submatrix for active moments
        vcov_sub = vcov_k[active_idx, active_idx]
        if (hasmissing(vcov_sub)) {
            // Numerically infeasible for this subset; drop K_start and continue
            result.dropped_jtest[K_start] = 1
            result.moment_mask[K_start] = 0
            continue
        }

        W_sub = safe_invert(vcov_sub, 1e-10, &success)
        if (success == 0 || hasmissing(W_sub)) {
            result.dropped_jtest[K_start] = 1
            result.moment_mask[K_start] = 0
            continue
        }

        ones_sub = J(K_active, 1, 1)
        sum_W = ones_sub' * W_sub * ones_sub
        if (missing(sum_W) || sum_W <= 0) {
            result.dropped_jtest[K_start] = 1
            result.moment_mask[K_start] = 0
            continue
        }

        w_sub = (W_sub * ones_sub)' / sum_W

        // Extract active component estimates
        tau_active = J(1, K_active, .)
        for (j = 1; j <= K_active; j++) {
            tau_active[j] = tau_components[active_idx[j]]
        }

        // GMM estimate for active subset
        tau_gmm = w_sub * tau_active'

        // Residual vector g(τ̂)
        g_vec = (tau_gmm :- tau_active)'

        // J-statistic: g'Wg (no N scaling for the GMM with bootstrap W)
        J_stat = g_vec' * W_sub * g_vec
        J_df = K_active - 1

        if (J_df > 0 && !missing(J_stat) && J_stat >= 0) {
            J_pval = 1 - chi2(J_df, J_stat)
        }
        else {
            J_pval = .
        }

        result.jtest_stat = J_stat
        result.jtest_df = J_df
        result.jtest_pval = J_pval

        // If fail to reject H0 (p > alpha), accept this moment set
        if (!missing(J_pval) && J_pval > _alpha) {
            result.K_final = K_active
            result.W = J(kmax, kmax, .)
            result.W[active_idx, active_idx] = W_sub
            result.weights = J(1, kmax, .)
            for (j = 1; j <= K_active; j++) {
                result.weights[active_idx[j]] = w_sub[j]
            }

            // Mark moments outside active set
            result.moment_mask = J(1, kmax, 0)
            for (j = 1; j <= K_active; j++) {
                result.moment_mask[active_idx[j]] = 1
            }
            // Mark dropped moments below K_start as J-test dropped
            for (i = 1; i <= K_start - 1; i++) {
                result.dropped_jtest[i] = 1
            }
            // Mark dropped moments above K_sel as numerical/jtest
            for (i = K_sel + 1; i <= kmax; i++) {
                if (result.dropped_numerical[i] == 0) {
                    result.dropped_jtest[i] = 1
                }
            }

            return(result)
        }

        // Reject H0: drop k=K_start (lowest-order in current set)
        result.dropped_jtest[K_start] = 1
        result.moment_mask[K_start] = 0
    }

    // All nested subsets rejected by J-test; fall back to single moment k=K_sel
    // (just-identified, no overidentification test needed)
    result.K_final = 1
    result.W = J(kmax, kmax, .)
    result.W[K_sel, K_sel] = 1 / vcov_k[K_sel, K_sel]
    result.weights = J(1, kmax, .)
    result.weights[K_sel] = 1
    result.moment_mask = J(1, kmax, 0)
    result.moment_mask[K_sel] = 1
    for (i = 1; i <= K_sel - 1; i++) {
        result.dropped_jtest[i] = 1
    }
    for (i = K_sel + 1; i <= kmax; i++) {
        if (result.dropped_numerical[i] == 0) {
            result.dropped_jtest[i] = 1
        }
    }

    return(result)
}

/*---------------------------------------------------------------------------
 * compute_kdid_estimate() - Compute K-DID GMM estimate and inference
 *
 * τ̂ = w' τ_components
 * Var(τ̂) = (1'W1)^{-1}  (asymptotic)
 * or bootstrap variance of w'τ^{(b)} (bootstrap)
 *
 * Arguments:
 *   tau_components : real rowvector (1×K) - component point estimates
 *   weights_k     : struct gmm_weights_k - GMM weights
 *   boot_draws    : real matrix (B×K) - bootstrap component draws
 *   se_boot       : real scalar - 0=asymptotic, 1=bootstrap
 *   level         : real scalar - confidence level
 *
 * Returns:
 *   real rowvector: (estimate, variance, std_error, ci_lo, ci_hi)
 *---------------------------------------------------------------------------*/
real rowvector compute_kdid_estimate(real rowvector tau_components,
                                     struct gmm_weights_k scalar weights_k,
                                     real matrix boot_draws,
                                     real scalar se_boot,
                                     real scalar level)
{
    real scalar K_f, tau_kdid, var_kdid, se_kdid, alpha, z
    real scalar ci_lo, ci_hi
    real rowvector w_f, tau_f, boot_row_f
    real colvector ones_f, boot_kdid, valid_boot, active_idx
    real matrix W_f
    real scalar b, n_boot, sum_W, j, kmax

    K_f = weights_k.K_final
    kmax = cols(weights_k.moment_mask)

    if (K_f == 0) {
        return((., ., ., ., .))
    }

    // Build active index vector from moment_mask
    active_idx = selectindex(weights_k.moment_mask :> 0)'
    if (rows(active_idx) != K_f) {
        // Fallback: mismatch between K_final and moment_mask count
        active_idx = selectindex(weights_k.moment_mask :> 0)'
        K_f = rows(active_idx)
        if (K_f == 0) return((., ., ., ., .))
    }

    // Extract used components and weights at active indices
    w_f = J(1, K_f, .)
    tau_f = J(1, K_f, .)
    for (j = 1; j <= K_f; j++) {
        w_f[j] = weights_k.weights[active_idx[j]]
        tau_f[j] = tau_components[active_idx[j]]
    }

    // Point estimate
    tau_kdid = w_f * tau_f'

    // Variance
    alpha = 1 - level / 100
    z = invnormal(1 - alpha / 2)

    if (se_boot && rows(boot_draws) >= 2) {
        // Bootstrap variance
        n_boot = rows(boot_draws)
        boot_kdid = J(n_boot, 1, .)
        for (b = 1; b <= n_boot; b++) {
            // Extract active columns from this bootstrap row
            boot_row_f = J(1, K_f, .)
            for (j = 1; j <= K_f; j++) {
                boot_row_f[j] = boot_draws[b, active_idx[j]]
            }
            if (rowmissing(boot_row_f) == 0) {
                boot_kdid[b] = w_f * boot_row_f'
            }
        }
        valid_boot = select(boot_kdid, boot_kdid :< .)
        if (rows(valid_boot) >= 2) {
            var_kdid = variance(valid_boot)
            se_kdid = sqrt(var_kdid)
            ci_lo = quantile_sorted(valid_boot, alpha / 2)
            ci_hi = quantile_sorted(valid_boot, 1 - alpha / 2)
        }
        else {
            var_kdid = .
            se_kdid = .
            ci_lo = .
            ci_hi = .
        }
    }
    else {
        // Asymptotic variance: (1'W1)^{-1}
        W_f = weights_k.W[active_idx, active_idx]
        if (!hasmissing(W_f)) {
            ones_f = J(K_f, 1, 1)
            sum_W = ones_f' * W_f * ones_f
            if (!missing(sum_W) && sum_W > 0) {
                var_kdid = 1 / sum_W
            }
            else {
                var_kdid = .
            }
        }
        else {
            var_kdid = .
        }
        se_kdid = sqrt(var_kdid)
        if (!missing(se_kdid)) {
            ci_lo = tau_kdid - z * se_kdid
            ci_hi = tau_kdid + z * se_kdid
        }
        else {
            ci_lo = .
            ci_hi = .
        }
    }

    return((tau_kdid, var_kdid, se_kdid, ci_lo, ci_hi))
}


// ----------------------------------------------------------------------------
// MAIN ESTIMATION FUNCTION: GENERALIZED K-DID
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_std_main_k() - Main Orchestrator for Generalized K-DID
 *
 * K-dimensional extension of _did_std_main(). Coordinates:
 *   1. K-dimensional point estimation via did_fit_k()
 *   2. K-dimensional bootstrap via did_boot_std_k()
 *   3. Optional J-test moment selection
 *   4. K-dimensional GMM weighting with numerical fallback
 *   5. Result storage in extended e() format
 *
 * Arguments:
 *   lead     : real rowvector - lead values
 *   n_boot   : real scalar - bootstrap iterations
 *   se_boot  : real scalar - 0=asymptotic, 1=bootstrap CI
 *   level    : real scalar - confidence level
 *   kmax     : real scalar - max number of components
 *   jtest_on : real scalar - 1=enable J-test
 *
 * Returns:
 *   real scalar - 0=success, non-zero=error
 *
 * Side Effects:
 *   Populates global result variables for Stata retrieval
 *---------------------------------------------------------------------------*/
real scalar _did_std_main_k(real rowvector lead, real scalar n_boot,
                            real scalar se_boot, real scalar level,
                            real scalar kmax, real scalar jtest_on)
{
    external struct did_data scalar did_dat
    external struct did_option scalar did_opt

    // Global result variables
    external real rowvector _did_b
    external real matrix _did_V
    external real matrix _did_estimates
    external real rowvector _did_lead_values
    external real matrix _did_weights
    external real matrix _did_W
    external real matrix _did_vcov_gmm
    external real matrix _did_bootstrap_support
    external real scalar _did_n_boot_success
    // New K-DID specific globals
    external real matrix _did_k_summary
    external real matrix _did_moment_selected
    external real matrix _did_moment_dropped_jtest
    external real matrix _did_moment_dropped_numerical
    external real matrix _did_jtest_stats

    struct boot_result_k scalar boot_res_k
    struct gmm_weights_k scalar wk
    real rowvector point_est_k, kdid_est
    real scalar n_lead, l, k_comp, row, alpha, z
    real scalar K_f, tau_kdid, var_kdid, se_kdid
    real scalar ci_lo_kdid, ci_hi_kdid
    real scalar var_comp, se_comp, ci_lo_comp, ci_hi_comp
    real matrix boot_est_lead_k
    real colvector boot_comp_valid
    real scalar n_rows_per_lead, col_start, col_end

    n_lead = cols(lead)
    n_rows_per_lead = 1 + kmax   // 1 final + kmax components

    // Initialize result storage
    _did_b = J(1, n_rows_per_lead * n_lead, .)
    _did_V = J(n_rows_per_lead * n_lead, n_rows_per_lead * n_lead, 0)
    _did_estimates = J(n_rows_per_lead * n_lead, 14, .)
    _did_lead_values = lead
    _did_weights = J(n_lead, kmax, .)
    _did_W = J(n_lead, kmax * kmax, .)
    _did_vcov_gmm = J(n_lead, kmax * kmax, .)
    _did_bootstrap_support = J(n_lead, kmax, 0)
    _did_k_summary = J(n_lead, 3, .)       // K_init, K_sel, K_final
    _did_moment_selected = J(n_lead, kmax, 0)
    _did_moment_dropped_jtest = J(n_lead, kmax, 0)
    _did_moment_dropped_numerical = J(n_lead, kmax, 0)
    _did_jtest_stats = J(n_lead, 3, .)     // J_stat, J_df, J_pval

    alpha = 1 - level / 100
    z = invnormal(1 - alpha / 2)

    // -------------------------------------------------------------------------
    // Run K-dimensional bootstrap
    // -------------------------------------------------------------------------
    boot_res_k = did_boot_std_k(did_dat, lead, n_boot, kmax, did_opt.seed)
    _did_n_boot_success = boot_res_k.n_successful

    if (boot_res_k.n_successful < 2) {
        errprintf("Error: Bootstrap failed - insufficient successful iterations (%g)\n",
                  boot_res_k.n_successful)
        return(1)
    }

    // -------------------------------------------------------------------------
    // Process each lead
    // -------------------------------------------------------------------------
    row = 1
    for (l = 1; l <= n_lead; l++) {

        // Compute K-dimensional point estimates
        point_est_k = did_fit_k(
            did_dat.outcome,
            did_dat.Gi,
            did_dat.It,
            did_dat.id_unit,
            did_dat.covariates,
            did_dat.id_time_std,
            lead[l],
            kmax,
            did_dat.is_panel
        )

        // Determine K_init: how many components are identified
        real scalar K_init_l
        K_init_l = 0
        for (k_comp = 1; k_comp <= kmax; k_comp++) {
            if (!missing(point_est_k[k_comp])) {
                K_init_l = k_comp
            }
            else {
                break
            }
        }

        // Extract bootstrap draws for this lead
        col_start = kmax * (l - 1) + 1
        col_end = kmax * l
        boot_est_lead_k = boot_res_k.estimates[., col_start..col_end]

        // Record bootstrap support counts
        for (k_comp = 1; k_comp <= kmax; k_comp++) {
            _did_bootstrap_support[l, k_comp] = rows(select(boot_est_lead_k[., k_comp], boot_est_lead_k[., k_comp] :< .))
        }

        // GMM weighting
        if (K_init_l >= 1 && boot_res_k.vcov[l] != NULL) {
            real matrix VC_l_k
            VC_l_k = *boot_res_k.vcov[l]
            _did_vcov_gmm[l, .] = vec(VC_l_k)'

            if (jtest_on && K_init_l >= 2) {
                wk = jtest_select(point_est_k, VC_l_k, K_init_l)
            }
            else {
                wk = compute_weights_k(VC_l_k, kmax)
            }

            K_f = wk.K_final

            // Store K summary
            _did_k_summary[l, .] = (K_init_l, K_f, K_f)
            _did_moment_selected[l, .] = wk.moment_mask
            _did_moment_dropped_jtest[l, .] = wk.dropped_jtest
            _did_moment_dropped_numerical[l, .] = wk.dropped_numerical
            _did_jtest_stats[l, .] = (wk.jtest_stat, wk.jtest_df, wk.jtest_pval)
            _did_weights[l, .] = wk.weights
            _did_W[l, .] = vec(wk.W)'

            // Compute K-DID GMM estimate
            kdid_est = compute_kdid_estimate(point_est_k, wk, boot_est_lead_k, se_boot, level)
            tau_kdid = kdid_est[1]
            var_kdid = kdid_est[2]
            se_kdid = kdid_est[3]
            ci_lo_kdid = kdid_est[4]
            ci_hi_kdid = kdid_est[5]
        }
        else {
            K_f = (K_init_l >= 1 ? 1 : 0)
            _did_k_summary[l, .] = (K_init_l, K_init_l, K_f)

            if (K_init_l == 1) {
                tau_kdid = point_est_k[1]
                // Single component: use its bootstrap variance
                boot_comp_valid = select(boot_est_lead_k[., 1], boot_est_lead_k[., 1] :< .)
                if (rows(boot_comp_valid) >= 2) {
                    var_kdid = variance(boot_comp_valid)
                }
                else {
                    var_kdid = .
                }
                se_kdid = sqrt(var_kdid)
                if (!missing(se_kdid)) {
                    if (se_boot) {
                        ci_lo_kdid = quantile_sorted(boot_comp_valid, alpha / 2)
                        ci_hi_kdid = quantile_sorted(boot_comp_valid, 1 - alpha / 2)
                    }
                    else {
                        ci_lo_kdid = tau_kdid - z * se_kdid
                        ci_hi_kdid = tau_kdid + z * se_kdid
                    }
                }
                else {
                    ci_lo_kdid = .
                    ci_hi_kdid = .
                }
                _did_weights[l, 1] = 1
            }
            else {
                tau_kdid = .
                var_kdid = .
                se_kdid = .
                ci_lo_kdid = .
                ci_hi_kdid = .
            }
        }

        // Store final row in e(estimates)
        // Columns: lead, estimate, std_error, ci_lo, ci_hi, weight,
        //          component_k, selected_jtest, selected_final,
        //          dropped_jtest, dropped_numerical, K_init, K_sel, K_final
        _did_estimates[row, .] = (lead[l], tau_kdid, se_kdid, ci_lo_kdid, ci_hi_kdid, .,
                                  0, ., ., ., ., K_init_l,
                                  _did_k_summary[l, 2], K_f)
        _did_b[row] = tau_kdid
        if (!missing(var_kdid)) {
            _did_V[row, row] = var_kdid
        }
        row++

        // Store component rows
        for (k_comp = 1; k_comp <= kmax; k_comp++) {
            real scalar tau_comp_k, var_comp_k, se_comp_k
            real scalar ci_lo_comp_k, ci_hi_comp_k, w_comp_k
            real scalar sel_j, sel_f, dr_j, dr_n

            tau_comp_k = point_est_k[k_comp]
            w_comp_k = _did_weights[l, k_comp]
            sel_f = _did_moment_selected[l, k_comp]
            dr_j = _did_moment_dropped_jtest[l, k_comp]
            dr_n = _did_moment_dropped_numerical[l, k_comp]
            sel_j = (dr_j == 0 ? 1 : 0)

            // Component variance from bootstrap
            var_comp_k = .
            se_comp_k = .
            ci_lo_comp_k = .
            ci_hi_comp_k = .
            if (!missing(tau_comp_k)) {
                boot_comp_valid = select(boot_est_lead_k[., k_comp], boot_est_lead_k[., k_comp] :< .)
                if (rows(boot_comp_valid) >= 2) {
                    var_comp_k = variance(boot_comp_valid)
                    se_comp_k = sqrt(var_comp_k)
                    if (se_boot) {
                        ci_lo_comp_k = quantile_sorted(boot_comp_valid, alpha / 2)
                        ci_hi_comp_k = quantile_sorted(boot_comp_valid, 1 - alpha / 2)
                    }
                    else {
                        ci_lo_comp_k = tau_comp_k - z * se_comp_k
                        ci_hi_comp_k = tau_comp_k + z * se_comp_k
                    }
                }
            }

            _did_estimates[row, .] = (lead[l], tau_comp_k, se_comp_k,
                                      ci_lo_comp_k, ci_hi_comp_k, w_comp_k,
                                      k_comp, sel_j, sel_f, dr_j, dr_n,
                                      K_init_l, _did_k_summary[l, 2], K_f)
            _did_b[row] = tau_comp_k
            if (!missing(var_comp_k)) {
                _did_V[row, row] = var_comp_k
            }
            row++
        }
    }

    return(0)
}


// ----------------------------------------------------------------------------
// MAIN ESTIMATION FUNCTION FOR STANDARD DID
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_std_main() - Main Estimation Orchestrator for Standard DID Design
 *
 * Coordinates the complete double DID estimation workflow for the standard
 * (non-staggered) difference-in-differences design.
 *
 * Workflow:
 *   1. Initialize result storage matrices
 *   2. Run cluster bootstrap for variance estimation
 *   3. For each lead value:
 *      a. Compute DID and sequential DID point estimates
 *      b. Compute GMM optimal weights from bootstrap VCOV
 *      c. Compute double DID point estimate and inference
 *   4. Store results in global variables for Stata retrieval
 *
 * Arguments:
 *   lead    : real rowvector - Lead values, e.g., (0) or (0, 1, 2)
 *   n_boot  : real scalar - Number of bootstrap iterations
 *   se_boot : real scalar - Inference method: 0 = asymptotic, 1 = bootstrap
 *   level   : real scalar - Confidence level in percent, e.g., 95
 *
 * Returns:
 *   real scalar - Return code: 0 = success, non-zero = error
 *     1 = Bootstrap failed (insufficient successful iterations)
 *     2 = VCOV computation failed (singular matrix)
 *
 * Side Effects:
 *   Populates global result variables: _did_b, _did_V, _did_estimates,
 *   _did_lead_values, _did_weights, _did_W, _did_vcov_gmm, _did_n_boot_success
 *---------------------------------------------------------------------------*/
real scalar _did_std_main(real rowvector lead, real scalar n_boot, 
                          real scalar se_boot, real scalar level)
{
    // External data structures populated by data preparation
    external struct did_data scalar did_dat
    external struct did_option scalar did_opt
    
    // External result variables for Stata retrieval
    external real rowvector _did_b
    external real matrix _did_V
    external real matrix _did_estimates
    external real rowvector _did_lead_values
    external real matrix _did_weights
    external real matrix _did_W
    external real matrix _did_vcov_gmm
    external real matrix _did_bootstrap_support
    external real scalar _did_n_boot_success
    
    struct boot_result scalar boot_res
    struct gmm_weights scalar weights
    struct ddid_result scalar ddid_res
    
    real scalar n_lead, l, m, row, alpha, z
    real rowvector point_est
    real scalar se_did, se_sdid
    real matrix boot_est_l, VC_l, boot_ddid_all, boot_block_l, boot_block_m
    real colvector boot_did_valid, boot_sdid_valid
    real scalar n_valid_did, n_valid_sdid, n_joint_valid
    real scalar tau_did, tau_sdid, tau_ddid
    real scalar var_did, var_sdid, var_ddid
    real scalar cov_did_sdid, cov_ddid_did, cov_ddid_sdid
    real scalar ci_lo_did, ci_hi_did, ci_lo_sdid, ci_hi_sdid
    real scalar ci_lo_ddid, ci_hi_ddid
    real scalar w_did, w_sdid
    real scalar a, b, row_l, row_m, cov_pair
    real colvector valid_boot_idx, posted_idx, complete_posted_idx
    real matrix boot_posted_all, boot_posted_joint, posted_joint_vcov
    
    // -------------------------------------------------------------------------
    // Initialize result storage matrices
    // -------------------------------------------------------------------------
    n_lead = cols(lead)
    
    _did_b = J(1, 3 * n_lead, .)           // Coefficient vector: [dDID, DID, sDID] per lead
    _did_V = J(3 * n_lead, 3 * n_lead, 0)  // Variance-covariance matrix
    _did_estimates = J(3 * n_lead, 6, .)   // Full results table
    _did_lead_values = lead                 // Lead values for reference
    _did_weights = J(n_lead, 2, .)          // GMM weights (w_DID, w_sDID) per lead
    _did_W = J(n_lead, 4, .)                // Precision matrices (flattened) per lead
    _did_vcov_gmm = J(n_lead, 4, .)         // VCOV matrices (flattened) per lead
    _did_bootstrap_support = J(n_lead, 3, 0)
    _did_n_boot_success = n_boot            // Number of successful bootstrap iterations
    
    // Compute critical value for confidence intervals
    alpha = 1 - level / 100
    z = invnormal(1 - alpha / 2)
    
    // -------------------------------------------------------------------------
    // Run bootstrap for all lead values
    // -------------------------------------------------------------------------
    boot_res = did_boot_std(did_dat, lead, n_boot, did_opt.seed)
    _did_n_boot_success = boot_res.n_successful
    boot_ddid_all = J(rows(boot_res.estimates), n_lead, .)
    
    // Require minimum bootstrap successes for variance estimation
    if (boot_res.n_successful < 2) {
        errprintf("Error: Bootstrap failed - insufficient successful iterations\n")
        errprintf("       Only %g of %g iterations succeeded\n", 
                  boot_res.n_successful, n_boot)
        return(1)
    }
    
    // -------------------------------------------------------------------------
    // Compute estimates for each lead value
    // -------------------------------------------------------------------------
    row = 1
    for (l = 1; l <= n_lead; l++) {
        
        // ---------------------------------------------------------------------
        // Compute DID and sequential DID point estimates
        // ---------------------------------------------------------------------
        point_est = did_fit(
            did_dat.outcome,
            did_dat.outcome_delta,
            did_dat.Gi,
            did_dat.It,
            did_dat.id_unit,
            did_dat.covariates,
            did_dat.id_time_std,
            lead[l],
            did_dat.is_panel
        )
        
        tau_did = point_est[1]
        tau_sdid = point_est[2]
        tau_ddid = .
        var_did = .
        var_sdid = .
        var_ddid = .
        se_did = .
        se_sdid = .
        ci_lo_did = .
        ci_hi_did = .
        ci_lo_sdid = .
        ci_hi_sdid = .
        ci_lo_ddid = .
        ci_hi_ddid = .
        w_did = .
        w_sdid = .
        cov_did_sdid = .
        cov_ddid_did = .
        cov_ddid_sdid = .
        boot_est_l = boot_res.estimates[., (2*l-1)..(2*l)]
        n_valid_did = rows(select(boot_est_l[., 1], boot_est_l[., 1] :< .))
        n_valid_sdid = rows(select(boot_est_l[., 2], boot_est_l[., 2] :< .))
        n_joint_valid = sum(rowmissing(boot_est_l) :== 0)
        _did_bootstrap_support[l, .] = (n_valid_did, n_valid_sdid, n_joint_valid)
        
        // ---------------------------------------------------------------------
        // Compute component standard errors from each bootstrap margin
        // ---------------------------------------------------------------------
        if (!missing(tau_did)) {
            boot_did_valid = select(boot_est_l[., 1], boot_est_l[., 1] :< .)
            if (rows(boot_did_valid) >= 2) {
                var_did = variance(boot_did_valid)
            }
            se_did = sqrt(var_did)
            if (se_boot) {
                if (rows(boot_did_valid) >= 2) {
                    ci_lo_did = quantile_sorted(boot_did_valid, alpha / 2)
                    ci_hi_did = quantile_sorted(boot_did_valid, 1 - alpha / 2)
                }
            }
            else {
                ci_lo_did = tau_did - z * se_did
                ci_hi_did = tau_did + z * se_did
            }
        }

        if (!missing(tau_sdid)) {
            boot_sdid_valid = select(boot_est_l[., 2], boot_est_l[., 2] :< .)
            if (rows(boot_sdid_valid) >= 2) {
                var_sdid = variance(boot_sdid_valid)
            }
            se_sdid = sqrt(var_sdid)
            if (se_boot) {
                if (rows(boot_sdid_valid) >= 2) {
                    ci_lo_sdid = quantile_sorted(boot_sdid_valid, alpha / 2)
                    ci_hi_sdid = quantile_sorted(boot_sdid_valid, 1 - alpha / 2)
                }
            }
            else {
                ci_lo_sdid = tau_sdid - z * se_sdid
                ci_hi_sdid = tau_sdid + z * se_sdid
            }
        }

        // ---------------------------------------------------------------------
        // Compute GMM aggregation only when both component estimators are
        // identified. This matches the R reference behavior for partially
        // identifiable repeated cross-sections.
        // ---------------------------------------------------------------------
        if (!missing(tau_did) && !missing(tau_sdid)) {
            if (boot_res.vcov[l] == NULL) {
                errprintf("{err}Error: Bootstrap VCOV computation failed for lead %g\n", lead[l])
                errprintf("{err}       VCOV pointer is NULL - no valid bootstrap covariance available\n")
                errprintf("{err}       This may be caused by:\n")
                errprintf("{err}       - Insufficient successful bootstrap iterations\n")
                errprintf("{err}       - All bootstrap estimates are missing for this lead\n")
                return(2)
            }

            VC_l = *boot_res.vcov[l]
            _did_vcov_gmm[l, .] = vec(VC_l)'
            weights = compute_weights(VC_l)
            if (missing(weights.w_did) || missing(weights.w_sdid)) {
                weights = recover_tiny_scale_weights(VC_l, boot_est_l)
                if (!missing(weights.w_did) && !missing(weights.w_sdid)) {
                    printf("{txt}Note: standard DID bootstrap VCOV is tiny but non-degenerate; using scale-normalized equation (14) weights\n")
                }
            }
            w_did = weights.w_did
            w_sdid = weights.w_sdid
            _did_weights[l, .] = (w_did, w_sdid)
            _did_W[l, .] = vec(weights.W)'
            boot_ddid_all[., l] =
                _combine_bootstrap_ddid(boot_est_l[., 1], boot_est_l[., 2],
                                        w_did, w_sdid)

            ddid_res = compute_double_did(tau_did, tau_sdid, weights,
                                          boot_est_l, se_boot, level)

            tau_ddid = ddid_res.estimate
            var_ddid = ddid_res.variance
            ci_lo_ddid = ddid_res.ci_low
            ci_hi_ddid = ddid_res.ci_high
            cov_did_sdid = VC_l[1, 2]
            cov_ddid_did = w_did * var_did + w_sdid * cov_did_sdid
            cov_ddid_sdid = w_did * cov_did_sdid + w_sdid * var_sdid
        }
        
        // ---------------------------------------------------------------------
        // Populate Stata result matrices
        // ---------------------------------------------------------------------
        
        // Coefficient vector e(b): [dDID, DID, sDID] for each lead
        _did_b[1, 3*(l-1)+1] = tau_ddid
        _did_b[1, 3*(l-1)+2] = tau_did
        _did_b[1, 3*(l-1)+3] = tau_sdid
        
        // Variance matrix e(V): diagonal elements
        _did_V[3*(l-1)+1, 3*(l-1)+1] = var_ddid
        _did_V[3*(l-1)+2, 3*(l-1)+2] = var_did
        _did_V[3*(l-1)+3, 3*(l-1)+3] = var_sdid
        
        // Off-diagonal: DID-sDID covariance from bootstrap
        if (!missing(tau_did) && !missing(tau_sdid) && boot_res.vcov[l] != NULL) {
            _did_V[3*(l-1)+2, 3*(l-1)+3] = (*boot_res.vcov[l])[1, 2]
            _did_V[3*(l-1)+3, 3*(l-1)+2] = (*boot_res.vcov[l])[2, 1]
            if (!missing(cov_ddid_did)) {
                _did_V[3*(l-1)+1, 3*(l-1)+2] = cov_ddid_did
                _did_V[3*(l-1)+2, 3*(l-1)+1] = cov_ddid_did
            }
            if (!missing(cov_ddid_sdid)) {
                _did_V[3*(l-1)+1, 3*(l-1)+3] = cov_ddid_sdid
                _did_V[3*(l-1)+3, 3*(l-1)+1] = cov_ddid_sdid
            }
        }
        
        // Results table e(estimates): [lead, estimate, SE, CI_lo, CI_hi, weight]
        // Row order per lead: double DID, DID, sequential DID
        
        // Double DID result row
        _did_estimates[row, 1] = lead[l]
        _did_estimates[row, 2] = tau_ddid
        _did_estimates[row, 3] = sqrt(var_ddid)
        _did_estimates[row, 4] = ci_lo_ddid
        _did_estimates[row, 5] = ci_hi_ddid
        _did_estimates[row, 6] = .
        row = row + 1
        
        // DID result row
        _did_estimates[row, 1] = lead[l]
        _did_estimates[row, 2] = tau_did
        _did_estimates[row, 3] = se_did
        _did_estimates[row, 4] = ci_lo_did
        _did_estimates[row, 5] = ci_hi_did
        _did_estimates[row, 6] = w_did
        row = row + 1
        
        // Sequential DID result row
        _did_estimates[row, 1] = lead[l]
        _did_estimates[row, 2] = tau_sdid
        _did_estimates[row, 3] = se_sdid
        _did_estimates[row, 4] = ci_lo_sdid
        _did_estimates[row, 5] = ci_hi_sdid
        _did_estimates[row, 6] = w_sdid
        row = row + 1
    }

    // -------------------------------------------------------------------------
    // Rebuild the public multi-lead e(V) on the jointly observed posted
    // bootstrap vector. Pairwise mixed-support blocks are not a valid joint
    // covariance matrix for postestimation.
    // -------------------------------------------------------------------------
    if (rows(boot_res.estimates) >= 2) {
        boot_posted_all = J(rows(boot_res.estimates), 3 * n_lead, .)
        for (l = 1; l <= n_lead; l++) {
            row_l = 3 * (l - 1)
            boot_posted_all[., row_l + 1] = boot_ddid_all[., l]
            boot_posted_all[., row_l + 2] = boot_res.estimates[., 2*l - 1]
            boot_posted_all[., row_l + 3] = boot_res.estimates[., 2*l]
        }

        posted_idx = selectindex((_did_b' :< .) :& (diagonal(_did_V) :< .))
        if (rows(posted_idx) >= 2) {
            boot_posted_joint = boot_posted_all[., posted_idx]
            complete_posted_idx = selectindex(rowmissing(boot_posted_joint) :== 0)
            if (rows(complete_posted_idx) >= 2) {
                posted_joint_vcov = std_posted_joint_vcov(boot_posted_joint)
                _did_V[posted_idx, posted_idx] = posted_joint_vcov
            }
            else {
                errprintf("{err}Warning: Fewer than two jointly observed bootstrap draws remain for the posted multi-lead covariance vector\n")
                return(3)
            }
        }
    }
    
    return(0)
}

// ----------------------------------------------------------------------------
// PARALLEL BOOTSTRAP: MATRIX-BASED GMM FUNCTIONS
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * sa_to_ddid_matrix() - SA GMM Aggregation (Matrix Version)
 *
 * Matrix-based version of sa_to_ddid() for parallel bootstrap path.
 * The existing sa_to_ddid() uses pointer(struct sa_point) vector which
 * cannot be reconstructed from disk-based .dta files. This function
 * accepts an n_success x 2*n_lead matrix (from appended worker outputs)
 * and produces mathematically equivalent results.
 *
 * Arguments:
 *   point_est : struct sa_point - point estimate on original data
 *   boot_mat  : real matrix - n_success x 2*n_lead bootstrap matrix;
 *                             columns 2l-1, 2l = (DID[l], sDID[l])
 *   lead      : real rowvector - lead values
 *   level     : real scalar - confidence level (default: 95)
 *
 * Returns:
 *   struct sa_ddid_result - same format as sa_to_ddid()
 *---------------------------------------------------------------------------*/
struct sa_ddid_result scalar sa_to_ddid_matrix(
    struct sa_point scalar point_est,
    real matrix boot_mat,
    real rowvector lead,
    real scalar level)
{
    struct sa_ddid_result scalar result
    struct gmm_weights scalar weights
    real matrix boot_pairs, VC, VC_component
    real scalar n_lead, n_boot, ll
    real scalar tau_did, tau_sdid, tau_ddid
    real colvector boot_ddid, boot_ddid_valid, valid_joint
    real scalar n_valid_ddid, success
    real rowvector ci

    if (args() < 4) level = 95

    n_lead = cols(lead)
    n_boot = rows(boot_mat)

    // Initialize result (same structure as sa_to_ddid())
    result.estimate     = J(n_lead, 1, .)
    result.variance     = J(n_lead, 1, .)
    result.std_error    = J(n_lead, 1, .)
    result.ci_low       = J(n_lead, 1, .)
    result.ci_high      = J(n_lead, 1, .)
    result.w_did        = J(n_lead, 1, .)
    result.w_sdid       = J(n_lead, 1, .)
    result.tau_did      = J(n_lead, 1, .)
    result.tau_sdid     = J(n_lead, 1, .)
    result.var_did      = J(n_lead, 1, .)
    result.var_sdid     = J(n_lead, 1, .)
    result.W_matrices   = J(n_lead, 1, NULL)
    result.VCOV_matrices = J(n_lead, 1, NULL)

    if (n_boot < 2) {
        errprintf("sa_to_ddid_matrix(): Need at least 2 bootstrap samples\n")
        return(result)
    }

    for (ll = 1; ll <= n_lead; ll++) {

        tau_did  = point_est.DID[ll]
        tau_sdid = point_est.sDID[ll]
        result.tau_did[ll]  = tau_did
        result.tau_sdid[ll] = tau_sdid

        // Extract bootstrap (DID, sDID) column pair for this lead
        boot_pairs = boot_mat[., (2*ll - 1)..(2*ll)]

        // Component variances (marginal): use compute_vcov_pairwise() which
        // handles marginal missingness separately for each component
        VC_component = compute_vcov_pairwise(boot_pairs)
        // Joint-valid GMM covariance: only jointly observed (non-missing) pairs
        VC = compute_vcov_joint_valid(boot_pairs)

        result.VCOV_matrices[ll] = &(VC)

        if (missing(VC_component[1,1]) || missing(VC_component[2,2])) {
            errprintf("{err}Warning: Component variances missing for lead %g\n", lead[ll])
            continue
        }
        result.var_did[ll]  = VC_component[1,1]
        result.var_sdid[ll] = VC_component[2,2]

        if (missing(VC[1,1]) || missing(VC[1,2]) || missing(VC[2,2])) {
            errprintf("{err}Warning: Joint GMM covariance missing for lead %g\n", lead[ll])
            continue
        }

        // Compute optimal GMM weights W* = Sigma^{-1}
        weights = compute_weights(VC)

        // Fallback for tiny-scale VCOV (same pattern as sa_to_ddid())
        if (missing(weights.w_did) || missing(weights.w_sdid)) {
            weights = recover_tiny_scale_weights(VC, boot_pairs)
            if (!missing(weights.w_did) && !missing(weights.w_sdid)) {
                printf("{txt}Note: SA bootstrap VCOV is tiny but non-degenerate; using scale-normalized equation (14) weights\n")
            }
        }

        result.w_did[ll]    = weights.w_did
        result.w_sdid[ll]   = weights.w_sdid
        result.W_matrices[ll] = &(weights.W)

        // Double DID point estimate (paper eq. 14)
        tau_ddid = weights.w_did * tau_did + weights.w_sdid * tau_sdid
        result.estimate[ll] = tau_ddid

        // Compute bootstrap dDID draws for this lead from raw (DID, sDID) pairs.
        // boot_pairs is an n_success x 2 matrix; rows with any missing are excluded
        // for the double DID draw but retained in component-level counts above.
        boot_ddid = weights.w_did :* boot_pairs[., 1] + weights.w_sdid :* boot_pairs[., 2]

        // Select draws where the combined dDID estimate is non-missing
        valid_joint = (boot_ddid :< .)    // non-missing condition in Mata
        boot_ddid_valid = select(boot_ddid, valid_joint)
        n_valid_ddid = rows(boot_ddid_valid)

        if (n_valid_ddid < 2) {
            errprintf("{err}Warning: Fewer than 2 valid joint bootstrap draws for lead %g\n", lead[ll])
            continue
        }

        // Bootstrap variance and percentile CI for double DID.
        // variance() is a built-in Mata function; bootstrap_ci() is defined in
        // did_bootstrap.mata and computes percentile intervals via quantile_sorted().
        result.variance[ll]  = variance(boot_ddid_valid)
        result.std_error[ll] = sqrt(result.variance[ll])
        ci = bootstrap_ci(boot_ddid_valid, level)
        result.ci_low[ll]    = ci[1]
        result.ci_high[ll]   = ci[2]
    }

    return(result)
}

/*---------------------------------------------------------------------------
 * _did_std_main_from_boot() - Standard DID GMM from Pre-Collected Bootstrap
 *
 * Parallel bootstrap path: accepts pre-collected bootstrap estimates via
 * Mata external global _par_boot_est (populated by putmata in coordinator),
 * then runs the GMM → e() storage pipeline without re-running bootstrap.
 *
 * This function replicates the GMM and result storage logic from
 * _did_std_main() (lines 1193-1408) but skips the did_boot_std() call.
 * The sequential path _did_std_main() remains completely unmodified.
 *
 * Arguments:
 *   lead    : real rowvector - lead values
 *   seboot  : real scalar - 1 = bootstrap SE, 0 = asymptotic SE
 *   level   : real scalar - confidence level (e.g., 95)
 *
 * Returns:
 *   real scalar - 0 = success, non-zero = error code
 *     4 = No valid bootstrap samples in _par_boot_est
 *     5 = Column count mismatch in _par_boot_est
 *
 * Side Effects:
 *   Populates global result variables: _did_b, _did_V, _did_estimates, etc.
 *   Clears _par_boot_est after use to avoid stale data.
 *---------------------------------------------------------------------------*/
real scalar _did_std_main_from_boot(
    real rowvector lead,
    real scalar seboot,
    real scalar level)
{
    external struct did_data scalar did_dat
    external real matrix _par_boot_est    // populated by putmata in coordinator ado
    external real rowvector _did_b
    external real matrix _did_V
    external real matrix _did_estimates
    external real rowvector _did_lead_values
    external real matrix _did_weights
    external real matrix _did_W
    external real matrix _did_vcov_gmm
    external real matrix _did_bootstrap_support
    external real scalar _did_n_boot_success

    struct boot_result scalar boot_res
    struct gmm_weights scalar weights
    struct ddid_result scalar ddid_res
    real scalar n_lead, l, row, alpha, z
    real rowvector point_est
    real scalar se_did, se_sdid
    real matrix boot_est_l, VC_l, boot_ddid_all, boot_posted_all, boot_posted_joint, posted_joint_vcov
    real colvector boot_did_valid, boot_sdid_valid
    real scalar n_valid_did, n_valid_sdid, n_joint_valid
    real scalar tau_did, tau_sdid, tau_ddid
    real scalar var_did, var_sdid, var_ddid
    real scalar cov_did_sdid, cov_ddid_did, cov_ddid_sdid
    real scalar ci_lo_did, ci_hi_did, ci_lo_sdid, ci_hi_sdid
    real scalar ci_lo_ddid, ci_hi_ddid
    real scalar w_did, w_sdid
    real scalar row_l
    real colvector posted_idx, complete_posted_idx

    n_lead = cols(lead)

    // Retrieve pre-collected bootstrap estimates from external global.
    // _par_boot_est is an n_success x (2*n_lead) matrix, populated by putmata
    // in the coordinator before this function is called.
    if (rows(_par_boot_est) == 0) {
        errprintf("_did_std_main_from_boot(): No valid bootstrap samples\n")
        return(4)
    }
    if (rows(_par_boot_est) < 2) {
        errprintf("_did_std_main_from_boot(): Insufficient bootstrap samples (%g); need at least 2\n",
                  rows(_par_boot_est))
        return(1)
    }
    if (cols(_par_boot_est) != 2 * n_lead) {
        errprintf("_did_std_main_from_boot(): Column count mismatch (%g vs %g expected)\n",
                  cols(_par_boot_est), 2 * n_lead)
        return(5)
    }

    // Populate boot_result struct for compatibility with downstream GMM pipeline.
    boot_res.estimates    = _par_boot_est
    boot_res.n_successful = rows(_par_boot_est)
    boot_res.n_failed     = .    // not tracked in parallel path

    // Compute per-lead joint VCOV exactly as in did_boot_std().
    boot_res.vcov = J(n_lead, 1, NULL)
    for (l = 1; l <= n_lead; l++) {
        real matrix vcov_joint
        vcov_joint = compute_vcov_joint_valid(_par_boot_est[., (2*l-1)..(2*l)])
        boot_res.vcov[l] = &(J(2, 2, .))
        *boot_res.vcov[l] = vcov_joint
    }

    // Initialize result storage matrices.
    _did_b = J(1, 3 * n_lead, .)
    _did_V = J(3 * n_lead, 3 * n_lead, 0)
    _did_estimates = J(3 * n_lead, 6, .)
    _did_lead_values = lead
    _did_weights = J(n_lead, 2, .)
    _did_W = J(n_lead, 4, .)
    _did_vcov_gmm = J(n_lead, 4, .)
    _did_bootstrap_support = J(n_lead, 3, 0)
    _did_n_boot_success = boot_res.n_successful

    alpha = 1 - level / 100
    z = invnormal(1 - alpha / 2)
    boot_ddid_all = J(rows(boot_res.estimates), n_lead, .)

    row = 1
    for (l = 1; l <= n_lead; l++) {
        point_est = did_fit(
            did_dat.outcome,
            did_dat.outcome_delta,
            did_dat.Gi,
            did_dat.It,
            did_dat.id_unit,
            did_dat.covariates,
            did_dat.id_time_std,
            lead[l],
            did_dat.is_panel
        )

        tau_did = point_est[1]
        tau_sdid = point_est[2]
        tau_ddid = .
        var_did = .
        var_sdid = .
        var_ddid = .
        se_did = .
        se_sdid = .
        ci_lo_did = .
        ci_hi_did = .
        ci_lo_sdid = .
        ci_hi_sdid = .
        ci_lo_ddid = .
        ci_hi_ddid = .
        w_did = .
        w_sdid = .
        cov_did_sdid = .
        cov_ddid_did = .
        cov_ddid_sdid = .

        boot_est_l = boot_res.estimates[., (2*l-1)..(2*l)]
        VC_l = *boot_res.vcov[l]
        n_valid_did = rows(select(boot_est_l[., 1], boot_est_l[., 1] :< .))
        n_valid_sdid = rows(select(boot_est_l[., 2], boot_est_l[., 2] :< .))
        n_joint_valid = sum(rowmissing(boot_est_l) :== 0)
        _did_bootstrap_support[l, .] = (n_valid_did, n_valid_sdid, n_joint_valid)

        if (!missing(tau_did)) {
            boot_did_valid = select(boot_est_l[., 1], boot_est_l[., 1] :< .)
            if (rows(boot_did_valid) >= 2) {
                var_did = variance(boot_did_valid)
            }
            se_did = sqrt(var_did)
            if (seboot) {
                if (rows(boot_did_valid) >= 2) {
                    ci_lo_did = quantile_sorted(boot_did_valid, alpha / 2)
                    ci_hi_did = quantile_sorted(boot_did_valid, 1 - alpha / 2)
                }
            }
            else {
                ci_lo_did = tau_did - z * se_did
                ci_hi_did = tau_did + z * se_did
            }
        }

        if (!missing(tau_sdid)) {
            boot_sdid_valid = select(boot_est_l[., 2], boot_est_l[., 2] :< .)
            if (rows(boot_sdid_valid) >= 2) {
                var_sdid = variance(boot_sdid_valid)
            }
            se_sdid = sqrt(var_sdid)
            if (seboot) {
                if (rows(boot_sdid_valid) >= 2) {
                    ci_lo_sdid = quantile_sorted(boot_sdid_valid, alpha / 2)
                    ci_hi_sdid = quantile_sorted(boot_sdid_valid, 1 - alpha / 2)
                }
            }
            else {
                ci_lo_sdid = tau_sdid - z * se_sdid
                ci_hi_sdid = tau_sdid + z * se_sdid
            }
        }

        if (!missing(tau_did) && !missing(tau_sdid)) {
            weights = compute_weights(VC_l)
            if (missing(weights.w_did) || missing(weights.w_sdid)) {
                weights = recover_tiny_scale_weights(VC_l, boot_est_l)
                if (!missing(weights.w_did) && !missing(weights.w_sdid)) {
                    printf("{txt}Note: standard DID bootstrap VCOV is tiny but non-degenerate; using scale-normalized equation (14) weights\n")
                }
            }
            w_did = weights.w_did
            w_sdid = weights.w_sdid
            _did_weights[l, .] = (w_did, w_sdid)
            _did_W[l, .] = vec(weights.W)'
            _did_vcov_gmm[l, .] = vec(VC_l)'
            boot_ddid_all[., l] =
                _combine_bootstrap_ddid(boot_est_l[., 1], boot_est_l[., 2],
                                        w_did, w_sdid)

            ddid_res = compute_double_did(tau_did, tau_sdid, weights,
                                          boot_est_l, seboot, level)

            tau_ddid = ddid_res.estimate
            var_ddid = ddid_res.variance
            ci_lo_ddid = ddid_res.ci_low
            ci_hi_ddid = ddid_res.ci_high
            cov_did_sdid = VC_l[1, 2]
            cov_ddid_did = w_did * var_did + w_sdid * cov_did_sdid
            cov_ddid_sdid = w_did * cov_did_sdid + w_sdid * var_sdid
        }

        _did_b[1, 3*(l-1)+1] = tau_ddid
        _did_b[1, 3*(l-1)+2] = tau_did
        _did_b[1, 3*(l-1)+3] = tau_sdid

        _did_V[3*(l-1)+1, 3*(l-1)+1] = var_ddid
        _did_V[3*(l-1)+2, 3*(l-1)+2] = var_did
        _did_V[3*(l-1)+3, 3*(l-1)+3] = var_sdid
        if (!missing(tau_did) && !missing(tau_sdid)) {
            _did_V[3*(l-1)+2, 3*(l-1)+3] = VC_l[1, 2]
            _did_V[3*(l-1)+3, 3*(l-1)+2] = VC_l[2, 1]
            if (!missing(cov_ddid_did)) {
                _did_V[3*(l-1)+1, 3*(l-1)+2] = cov_ddid_did
                _did_V[3*(l-1)+2, 3*(l-1)+1] = cov_ddid_did
            }
            if (!missing(cov_ddid_sdid)) {
                _did_V[3*(l-1)+1, 3*(l-1)+3] = cov_ddid_sdid
                _did_V[3*(l-1)+3, 3*(l-1)+1] = cov_ddid_sdid
            }
        }

        _did_estimates[row, 1] = lead[l]
        _did_estimates[row, 2] = tau_ddid
        _did_estimates[row, 3] = sqrt(var_ddid)
        _did_estimates[row, 4] = ci_lo_ddid
        _did_estimates[row, 5] = ci_hi_ddid
        _did_estimates[row, 6] = .
        row = row + 1

        _did_estimates[row, 1] = lead[l]
        _did_estimates[row, 2] = tau_did
        _did_estimates[row, 3] = se_did
        _did_estimates[row, 4] = ci_lo_did
        _did_estimates[row, 5] = ci_hi_did
        _did_estimates[row, 6] = w_did
        row = row + 1

        _did_estimates[row, 1] = lead[l]
        _did_estimates[row, 2] = tau_sdid
        _did_estimates[row, 3] = se_sdid
        _did_estimates[row, 4] = ci_lo_sdid
        _did_estimates[row, 5] = ci_hi_sdid
        _did_estimates[row, 6] = w_sdid
        row = row + 1
    }

    if (rows(boot_res.estimates) >= 2) {
        boot_posted_all = J(rows(boot_res.estimates), 3 * n_lead, .)
        for (l = 1; l <= n_lead; l++) {
            row_l = 3 * (l - 1)
            boot_posted_all[., row_l + 1] = boot_ddid_all[., l]
            boot_posted_all[., row_l + 2] = boot_res.estimates[., 2*l - 1]
            boot_posted_all[., row_l + 3] = boot_res.estimates[., 2*l]
        }

        posted_idx = selectindex((_did_b' :< .) :& (diagonal(_did_V) :< .))
        if (rows(posted_idx) >= 2) {
            boot_posted_joint = boot_posted_all[., posted_idx]
            complete_posted_idx = selectindex(rowmissing(boot_posted_joint) :== 0)
            if (rows(complete_posted_idx) >= 2) {
                posted_joint_vcov = std_posted_joint_vcov(boot_posted_joint)
                _did_V[posted_idx, posted_idx] = posted_joint_vcov
            }
            else {
                errprintf("{err}Warning: Fewer than two jointly observed bootstrap draws remain for the posted multi-lead covariance vector\n")
                return(3)
            }
        }
    }

    // Clean up external global to avoid stale data in subsequent calls
    _par_boot_est = J(0, 0, .)

    return(0)
}

// ----------------------------------------------------------------------------
// MODULE VERIFICATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_gmm_loaded() - Module Load Verification
 *
 * Prints confirmation message when module is successfully loaded.
 *---------------------------------------------------------------------------*/
void _did_gmm_loaded()
{
    printf("{txt}did_gmm.mata loaded successfully\n")
}

end
