*! did_sa.mata - Staggered adoption design estimation
*!
*! Extends the double DID framework to settings where treatment timing varies
*! across units. Period-specific estimates are aggregated via time-weighted
*! averaging, with variance computed through panel bootstrap.

version 16.0

mata:
mata set matastrict on

// ============================================================================
// STAGGERED ADOPTION DESIGN ESTIMATION
// ============================================================================
//
// The staggered adoption (SA) design allows different units to receive treatment
// at different time periods. The SA-ATT at time t is defined as:
//   tau^SA(t) = E[Y_it(1) - Y_it(0) | G_it = 1]
//
// The time-average SA-ATT aggregates period-specific effects:
//   tau_bar^SA = sum_t pi_t * tau^SA(t)
// where pi_t = n_{1t} / sum_t' n_{1t'} (proportion treated at time t)
//
// Algorithm:
//   1. Construct treatment timing matrix G_it in {-1, 0, 1}
//   2. Identify valid periods with n_treated >= threshold
//   3. Compute time weights pi_t proportional to treated units
//   4. Estimate period-specific tau_DID(t) and tau_sDID(t) using {t-2, t-1, t}
//   5. Aggregate via time-weighted average
//   6. Compute variance via panel bootstrap
//
// ============================================================================


// ----------------------------------------------------------------------------
// DATA STRUCTURES
// ----------------------------------------------------------------------------

// Note: struct sa_point is defined in did_gmm.mata to resolve dependency order.

/*---------------------------------------------------------------------------
 * struct sa_data - Staggered Adoption Context
 *
 * Contains treatment timing information computed from panel data. This
 * structure enables code reuse between estimation and placebo tests.
 *---------------------------------------------------------------------------*/
struct sa_data {
    real matrix    Gmat          // Treatment timing matrix (N_units x T)
                                 // G_it: -1 = previously treated, 0 = control, 1 = newly treated
    real colvector id_time_use   // Valid period indices where n_treated >= threshold
    pointer vector id_subj_use   // Valid unit indices per period
    real colvector time_weight   // Time weights pi_t, normalized to sum to 1
}

/*---------------------------------------------------------------------------
 * struct sa_placebo_result - Placebo Test Results for SA Design
 *
 * Contains time-weighted placebo estimates for assessing the parallel
 * trends assumption in staggered adoption settings.
 *---------------------------------------------------------------------------*/
struct sa_placebo_result {
    real matrix    estimates     // n_lags x 2: (standardized, original scale)
    real matrix    Gmat          // Treatment pattern matrix for visualization
    real rowvector valid_lags    // Lag values included in estimation
    real scalar    has_valid_periods // 1 if threshold-selected periods exist
    real matrix    support_mask_std // Support rows used by standardized placebo, by lag
    real matrix    support_mask_raw // Support rows used by raw placebo, by lag
}

/*---------------------------------------------------------------------------
 * struct sa_placebo_boot_result - Bootstrap Results for SA Placebo Tests
 *
 * Contains bootstrap inference results including standard errors and
 * bootstrap distributions for SA placebo tests.
 *---------------------------------------------------------------------------*/
struct sa_placebo_boot_result {
    real colvector se_std        // Standard errors for standardized estimates
    real colvector se_orig       // Standard errors for original-scale estimates
    real scalar    n_boot        // Number of bootstrap iterations requested
    real scalar    n_valid       // Number of successful bootstrap iterations
    real matrix    boot_est_std  // Bootstrap estimates (standardized): n_valid x n_lags
    real matrix    boot_est_orig // Bootstrap estimates (original): n_valid x n_lags
}


// ----------------------------------------------------------------------------
// SA POINT ESTIMATION FUNCTIONS
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * sa_double_did() - SA Point Estimation Coordinator
 *
 * Coordinates the staggered adoption estimation process. Treatment timing
 * structures are constructed and period-specific estimation is delegated
 * to sa_compute_did().
 *
 * Arguments:
 *   data   : struct did_data - panel data structure
 *   option : struct did_option - estimation options (thres, lead)
 *
 * Returns:
 *   struct sa_point containing time-weighted (tau_DID, tau_sDID) for each lead
 *
 * Algorithm:
 *   1. Gmat is constructed from treatment timing
 *   2. Valid periods are identified where n_treated >= threshold
 *   3. Valid units per period are selected (not previously treated)
 *   4. Time weights are computed proportional to newly treated units
 *   5. Period-specific estimation is delegated to sa_compute_did()
 *---------------------------------------------------------------------------*/
struct sa_point scalar sa_double_did(struct did_data scalar data,
                                      struct did_option scalar option)
{
    struct sa_point scalar result
    real matrix Gmat
    real colvector id_time_use, time_weight, support_idx
    pointer vector id_subj_use
    real scalar n_lead
    
    // Initialize result with missing values
    n_lead = length(option.lead)
    result.DID = J(1, n_lead, .)
    result.sDID = J(1, n_lead, .)
    
    // Step 1: Create group matrix
    Gmat = create_gmat(data.id_unit, data.id_time, data.treatment)
    
    // Handle empty Gmat
    if (rows(Gmat) == 0 || cols(Gmat) == 0) {
        errprintf("sa_double_did(): Failed to create Gmat\n")
        return(result)
    }
    
    // Step 2: Get valid periods
    id_time_use = get_periods(Gmat, option.thres)
    
    // Handle no valid periods
    if (rows(id_time_use) == 0) {
        errprintf("sa_double_did(): No valid periods found\n")
        return(result)
    }
    
    // Step 3: Get valid subjects for each period
    id_subj_use = get_subjects(Gmat, id_time_use)
    
    // Step 4: Get time weights
    time_weight = get_time_weight(Gmat, id_time_use)
    
    // Verify weights sum to 1.0
    if (abs(sum(time_weight) - 1.0) > 1e-10) {
        errprintf("sa_double_did(): Time weights do not sum to 1.0\n")
        return(result)
    }
    
    // Step 5: Compute period-specific estimates and time-weighted average
    result = sa_compute_did(data, id_time_use, id_subj_use, time_weight, option.lead)
    
    return(result)
}


/*---------------------------------------------------------------------------
 * sa_get_estimable_period_idx() - Identify Periods That Enter SA Estimation
 *
 * Periods must satisfy the same feasibility checks used by sa_compute_did():
 *   1. Enough pre-treatment history exists
 *   2. At least one requested lead is available
 *   3. A non-empty subject set remains for period-specific estimation
 *
 * Returns:
 *   real colvector of row indices into id_time_use / time_weight
 *---------------------------------------------------------------------------*/
real colvector sa_get_estimable_period_idx(real colvector id_time_use,
                                            pointer vector id_subj_use,
                                            real rowvector lead,
                                            real scalar max_time,
                                            | real scalar min_time)
{
    real colvector support_idx, idx_subj
    real rowvector feasible_leads
    real scalar n_periods, i, t, iter

    if (args() < 5) min_time = 3

    n_periods = rows(id_time_use)
    support_idx = J(n_periods, 1, .)
    iter = 1

    for (i = 1; i <= n_periods; i++) {
        t = id_time_use[i]

        if (t < min_time) {
            continue
        }

        feasible_leads = select(lead, (t :+ lead) :<= max_time)
        if (length(feasible_leads) == 0) {
            continue
        }

        idx_subj = *id_subj_use[i]
        if (rows(idx_subj) == 0) {
            continue
        }

        support_idx[iter] = i
        iter++
    }

    if (iter == 1) {
        return(J(0, 1, .))
    }

    return(support_idx[1::(iter - 1)])
}


/*---------------------------------------------------------------------------
 * sa_get_lead_support_mask() - Identify Lead-Specific Common-Support Periods
 *
 * This helper reuses the same lead-specific eligibility filter and 2x2 DID
 * feasibility checks as sa_compute_did() so metadata surfaces match the
 * periods that actually contribute to the common DID/sDID target for each
 * lead. A period is retained only when both component estimators are jointly
 * identified on that period.
 *---------------------------------------------------------------------------*/
real matrix sa_get_lead_support_mask(struct did_data scalar data,
                                      real colvector id_time_use,
                                      pointer vector id_subj_use,
                                      real colvector period_idx,
                                      real rowvector lead,
                                      | real scalar min_time)
{
    struct did_data scalar dat_use, dat_did
    real matrix support_mask
    real colvector idx_subj, idx_subj_lead
    real rowvector est_t
    real scalar n_periods, n_lead, max_time, i, ll, row_idx, t

    if (args() < 6) min_time = 3

    n_periods = rows(period_idx)
    n_lead = length(lead)
    max_time = max(data.id_time)
    support_mask = J(n_periods, n_lead, 0)

    if (n_periods == 0) {
        return(support_mask)
    }

    for (i = 1; i <= n_periods; i++) {
        row_idx = period_idx[i]
        t = id_time_use[row_idx]

        if (t < min_time) {
            continue
        }

        idx_subj = *id_subj_use[row_idx]
        if (rows(idx_subj) == 0) {
            continue
        }

        for (ll = 1; ll <= n_lead; ll++) {
            if (t + lead[ll] > max_time) {
                continue
            }

            idx_subj_lead = sa_filter_subjects_by_lead(data, idx_subj, t, lead[ll])
            if (rows(idx_subj_lead) == 0) {
                continue
            }

            dat_use = subset_data_sa(data, idx_subj_lead, t, lead[ll])
            dat_did = sa_prepare_did_data(dat_use, t)
            est_t = did_fit(dat_did.outcome, dat_did.outcome_delta,
                           dat_did.Gi, dat_did.It, dat_did.id_unit,
                           dat_did.covariates, dat_did.id_time_std,
                           lead[ll], dat_did.is_panel)

            if (!missing(est_t[1]) && !missing(est_t[2])) {
                support_mask[i, ll] = 1
            }
        }
    }

    return(support_mask)
}


/*---------------------------------------------------------------------------
 * sa_compute_did() - Period-Specific DID/sDID Estimation
 *
 * Period-specific estimates are computed and aggregated via time-weighted
 * average. This function implements the core SA estimation algorithm.
 *
 * Arguments:
 *   data        : struct did_data - panel data
 *   id_time_use : real colvector - valid period indices
 *   id_subj_use : pointer vector - valid subject indices for each period
 *   time_weight : real colvector - time weights pi_t
 *   lead        : real rowvector - lead parameters for dynamic effects
 *   min_time    : real scalar - minimum time requirement (default=3)
 *
 * Returns:
 *   struct sa_point containing time-weighted (tau_DID, tau_sDID) for each lead
 *
 * Algorithm:
 *   For each valid period t where t >= min_time:
 *     1. Determine which requested leads are feasible at period t
 *     2. For each feasible lead s, keep units with A_i = t or A_i > t+s
 *     3. Subset data to the lead-specific window {t-2, t-1, t+s}
 *     4. tau_DID(s, t) and tau_sDID(s, t) are computed for that lead
 *     5. Corresponding time weight is stored once per period
 *   
 *   For each lead, time-weighted average is computed on the joint-support
 *   period set where both DID and sDID are identified:
 *     - common_idx = periods with finite tau_DID(t) and tau_sDID(t)
 *     - Weights are renormalized once on that common period set
 *     - tau_DID = sum(w_norm * tau_DID(t))
 *     - tau_sDID = sum(w_norm * tau_sDID(t))
 *---------------------------------------------------------------------------*/
struct sa_point scalar sa_compute_did(struct did_data scalar data,
                                       real colvector id_time_use,
                                       pointer vector id_subj_use,
                                       real colvector time_weight,
                                       real rowvector lead,
                                       | real scalar min_time)
{
    struct sa_point scalar result
    struct did_data scalar dat_use, dat_did
    real matrix est_did, est_sdid, treated_count_common
    real colvector time_weight_new, period_id_new, idx_subj, idx_subj_lead
    real colvector common_idx, weight_norm_common
    real rowvector est_t, support_t
    real scalar n_periods, max_time, i, t, iter, ll, n_lead
    real scalar n_valid
    real scalar sum_w_common
    real rowvector feasible_leads
    
    // Default min_time = 3 (requires t-2, t-1, t periods for sDID calculation)
    if (args() < 6) min_time = 3
    
    n_periods = rows(id_time_use)
    n_lead = length(lead)
    max_time = max(data.id_time)
    // Initialize result with missing values
    result.DID = J(1, n_lead, .)
    result.sDID = J(1, n_lead, .)
    result.periods = J(0, 1, .)
    result.weights_common = J(0, n_lead, .)
    
    // Handle empty input
    if (n_periods == 0) {
        errprintf("sa_compute_did(): No valid periods for SA estimation\n")
        return(result)
    }
    
    // Pre-allocate for maximum possible valid periods
    est_did = J(n_periods, n_lead, .)
    est_sdid = J(n_periods, n_lead, .)
    treated_count_common = J(n_periods, n_lead, 0)
    time_weight_new = J(n_periods, 1, .)
    period_id_new = J(n_periods, 1, .)
    
    // Initialize iter counter before the loop
    iter = 1
    
    // Loop over all periods
    for (i = 1; i <= n_periods; i++) {
        t = id_time_use[i]
        
        // Need min_time periods before estimation can be formed
        if (t >= min_time) {
            feasible_leads = select(lead, (t :+ lead) :<= max_time)
            
            // Skip periods where none of the requested leads are feasible
            if (length(feasible_leads) == 0) {
                continue
            }
            
            // 1. Get the period-specific subject set from G_it.
            idx_subj = *id_subj_use[i]
            
            // Skip if no valid subjects for this period
            if (rows(idx_subj) == 0) {
                continue
            }

            // 2. Compute estimates for feasible leads only. Lead s uses the
            // Appendix E.3 control set A_i > t+s rather than the baseline
            // G_it >= 0 eligibility that only conditions on time t.
            for (ll = 1; ll <= n_lead; ll++) {
                if (t + lead[ll] <= max_time) {
                    idx_subj_lead = sa_filter_subjects_by_lead(data, idx_subj, t, lead[ll])
                    if (rows(idx_subj_lead) == 0) {
                        continue
                    }

                    dat_use = subset_data_sa(data, idx_subj_lead, t, lead[ll])
                    dat_did = sa_prepare_did_data(dat_use, t)

                    est_t = did_fit(dat_did.outcome, dat_did.outcome_delta,
                                   dat_did.Gi, dat_did.It, dat_did.id_unit,
                                   dat_did.covariates, dat_did.id_time_std,
                                   lead[ll], dat_did.is_panel)
                    support_t = did_fit_treated_support(
                                   dat_did.outcome, dat_did.outcome_delta,
                                   dat_did.Gi, dat_did.It, dat_did.id_unit,
                                   dat_did.covariates, dat_did.id_time_std,
                                   lead[ll], dat_did.is_panel
                               )
                    est_did[iter, ll] = est_t[1]   // tau_DID(t)
                    est_sdid[iter, ll] = est_t[2]  // tau_sDID(t)
                    treated_count_common[iter, ll] = support_t[3]
                }
            }
            
            // 5. Store time weight for this period
            time_weight_new[iter] = time_weight[i]
            period_id_new[iter] = t
            
            // 6. Increment iteration counter
            iter++
        }
    }
    
    // Trim to actual number of valid periods
    n_valid = iter - 1
    
    // Handle no valid periods
    if (n_valid == 0) {
        errprintf("sa_compute_did(): No valid periods for SA estimation\n")
        return(result)
    }
    
    est_did = est_did[1::n_valid, .]
    est_sdid = est_sdid[1::n_valid, .]
    treated_count_common = treated_count_common[1::n_valid, .]
    time_weight_new = time_weight_new[1::n_valid]
    period_id_new = period_id_new[1::n_valid]
    result.periods = period_id_new
    result.weights_common = J(n_valid, n_lead, 0)
    
    // Compute time-weighted averages on the common-support period set.
    for (ll = 1; ll <= n_lead; ll++) {
        common_idx = selectindex(
            (est_did[., ll] :< .) :&
            (est_sdid[., ll] :< .) :&
            (treated_count_common[., ll] :> 0)
        )

        if (length(common_idx) > 0) {
            weight_norm_common = treated_count_common[common_idx, ll]
            sum_w_common = sum(weight_norm_common)
            if (sum_w_common > 0 & !missing(sum_w_common)) {
                weight_norm_common = weight_norm_common / sum_w_common
                result.DID[ll] = sum(est_did[common_idx, ll] :* weight_norm_common)
                result.sDID[ll] = sum(est_sdid[common_idx, ll] :* weight_norm_common)
                result.weights_common[common_idx, ll] = weight_norm_common
            }
        }
    }
    
    return(result)
}



/*---------------------------------------------------------------------------
 * sa_filter_subjects_by_lead() - Apply Appendix E.3 Lead-Specific Eligibility
 *
 * Keeps units with A_i = t in the treated group and units with A_i > t+s in
 * the control group. Units treated between t+1 and t+s are excluded.
 *---------------------------------------------------------------------------*/
real colvector sa_filter_subjects_by_lead(struct did_data scalar data,
                                          real colvector idx_subj,
                                          real scalar t,
                                          real scalar lead)
{
    real colvector units, valid_units, eligible_mask, first_treat, idx_treat
    real scalar i

    if (rows(idx_subj) == 0) {
        return(J(0, 1, .))
    }

    units = uniqrows(data.id_unit)
    valid_units = units[idx_subj]
    first_treat = J(rows(valid_units), 1, .)
    eligible_mask = J(rows(valid_units), 1, 0)

    for (i = 1; i <= rows(valid_units); i++) {
        idx_treat = selectindex((data.id_unit :== valid_units[i]) :& (data.treatment :== 1))
        if (rows(idx_treat) > 0) {
            first_treat[i] = min(data.id_time[idx_treat])
        }

        if (missing(first_treat[i]) || first_treat[i] == t || first_treat[i] > (t + lead)) {
            eligible_mask[i] = 1
        }
    }

    return(select(idx_subj, eligible_mask))
}


/*---------------------------------------------------------------------------
 * subset_data_sa() - Subset Data for Lead-Specific Period Estimation
 *
 * Panel data subset is extracted for specified units and times {t-2, t-1, t+s}.
 * The subset is prepared for period- and lead-specific DID estimation.
 *
 * Arguments:
 *   data     : struct did_data - full panel data
 *   idx_subj : real colvector - valid unit indices (Gmat row indices)
 *   t        : real scalar - treatment period
 *   lead     : real scalar - lead value s
 *
 * Returns:
 *   struct did_data containing subset with valid units and times
 *
 * Algorithm:
 *   1. Gmat row indices are mapped to unit IDs
 *   2. Observations are filtered for valid units and times {t-2, t-1, t+s}
 *   3. All relevant fields are copied to result structure
*---------------------------------------------------------------------------*/
struct did_data scalar subset_data_sa(struct did_data scalar data,
                                       real colvector idx_subj,
                                       real scalar t,
                                       | real scalar lead)
{
    struct did_data scalar result
    real colvector units, valid_units, idx, time_filter, unit_filter, combined_filter
    real colvector idx_treat_t
    real scalar i, N_orig, N_sub
    transmorphic scalar treat_map

    if (args() < 4) {
        lead = 0
    }
    
    // Initialize result structure
    result = did_data()
    
    // Handle empty input
    if (rows(idx_subj) == 0) {
        result.N = 0
        return(result)
    }
    
    N_orig = rows(data.id_unit)
    
    // Step 1: Get unique unit IDs from Gmat row indices
    // idx_subj contains row indices into Gmat (1-based)
    // Map Gmat row indices to actual unit IDs
    units = uniqrows(data.id_unit)
    
    // Validate idx_subj bounds before array access
    if (rows(idx_subj) > 0) {
        if (max(idx_subj) > rows(units) || min(idx_subj) < 1) {
            errprintf("Error: subset_data_sa(): idx_subj contains out-of-bounds indices\n")
            errprintf("       idx_subj range: [%g, %g], units count: %g\n", 
                      min(idx_subj), max(idx_subj), rows(units))
            result.N = 0
            return(result)
        }
    }
    
    valid_units = units[idx_subj]
    
    // Step 2: Create filter for valid units
    transmorphic scalar valid_set
    valid_set = asarray_create("real", 1)
    for (i = 1; i <= rows(valid_units); i++) {
        asarray(valid_set, valid_units[i], 1)
    }
    
    unit_filter = J(N_orig, 1, 0)
    for (i = 1; i <= N_orig; i++) {
        if (asarray_contains(valid_set, data.id_unit[i])) {
            unit_filter[i] = 1
        }
    }

    // Preserve treatment assignment at time t for all retained rows.
    // This matches the R path, which appends future outcomes but anchors
    // treatment coding to the target period before constructing Gi.
    treat_map = asarray_create("real", 1)
    idx_treat_t = selectindex(unit_filter :& (data.id_time :== t))
    for (i = 1; i <= rows(idx_treat_t); i++) {
        asarray(treat_map, data.id_unit[idx_treat_t[i]], data.treatment[idx_treat_t[i]])
    }
    
    // Step 3: Create filter for valid times {t-2, t-1, t+lead}
    time_filter = (data.id_time :== (t + lead)) :| (data.id_time :== (t-1)) :| (data.id_time :== (t-2))
    
    // Step 4: Combine filters
    combined_filter = unit_filter :& time_filter
    idx = selectindex(combined_filter)
    
    // Handle empty result
    N_sub = length(idx)
    if (N_sub == 0) {
        result.N = 0
        return(result)
    }
    
    // Step 5: Subset all fields
    result.outcome = data.outcome[idx]
    result.id_unit = data.id_unit[idx]
    result.id_time = data.id_time[idx]
    result.treatment = J(N_sub, 1, .)
    for (i = 1; i <= N_sub; i++) {
        if (asarray_contains(treat_map, result.id_unit[i])) {
            result.treatment[i] = asarray(treat_map, result.id_unit[i])
        }
        else {
            result.treatment[i] = data.treatment[idx[i]]
        }
    }
    
    // Covariates (if any)
    if (cols(data.covariates) > 0 && rows(data.covariates) > 0) {
        result.covariates = data.covariates[idx, .]
    }
    else {
        result.covariates = J(0, 0, .)
    }
    
    // Cluster variable (if any)
    if (rows(data.cluster_var) > 0) {
        result.cluster_var = data.cluster_var[idx]
    }
    else {
        result.cluster_var = J(0, 1, .)
    }
    
    // Derived variables (if available)
    if (rows(data.Gi) > 0) {
        result.Gi = data.Gi[idx]
    }
    if (rows(data.It) > 0) {
        result.It = data.It[idx]
    }
    if (rows(data.id_time_std) > 0) {
        result.id_time_std = data.id_time_std[idx]
    }
    if (rows(data.outcome_delta) > 0) {
        result.outcome_delta = data.outcome_delta[idx]
    }
    
    // Metadata
    result.N = N_sub
    result.n_units = rows(uniqrows(result.id_unit))
    result.n_periods = rows(uniqrows(result.id_time))
    result.treat_year = t
    result.is_panel = data.is_panel
    
    return(result)
}


/*---------------------------------------------------------------------------
 * add_lead_outcomes() - Append Future Outcome Observations
 *
 * Outcome observations from future periods (t+1 to t+max_lead) are appended
 * when lead > 0. Treatment status from time t is preserved.
 *
 * Arguments:
 *   dat_use  : struct did_data - current subset data (times {t-2, t-1, t})
 *   data     : struct did_data - full panel data
 *   idx_subj : real colvector - valid unit indices
 *   t        : real scalar - treatment period
 *   lead     : real rowvector - lead parameters for dynamic effects
 *
 * Returns:
 *   struct did_data with lead outcome observations appended
 *
 * Algorithm:
 *   1. Treatment status at time t is extracted for valid units
 *   2. Observations are filtered for lead time periods
 *   3. Treatment info is joined by unit ID
 *   4. Lead observations are appended to existing data structure
 *---------------------------------------------------------------------------*/
struct did_data scalar add_lead_outcomes(struct did_data scalar dat_use,
                                          struct did_data scalar data,
                                          real colvector idx_subj,
                                          real scalar t,
                                          real rowvector lead)
{
    struct did_data scalar result
    real colvector units, valid_units, idx_treat, idx_lead
    real colvector unit_filter, time_filter, combined_filter
    real colvector treat_info_unit, treat_info_val
    real colvector lead_outcome, lead_treatment, lead_id_unit, lead_id_time
    real matrix lead_covariates
    real colvector lead_cluster
    real scalar N_orig, N_use, N_lead, N_total
    real scalar min_lead_time, max_lead_time, i, j
    real scalar max_lead, min_lead
    
    // Get lead bounds
    max_lead = max(lead)
    min_lead = min(lead)
    
    // If max_lead <= 0, no lead data needed
    if (max_lead <= 0) {
        return(dat_use)
    }
    
    N_orig = rows(data.id_unit)
    N_use = dat_use.N
    
    // Step 1: Get unique unit IDs from Gmat row indices
    units = uniqrows(data.id_unit)
    valid_units = units[idx_subj]
    
    // Step 2: Get treatment info at time t for valid subjects
    {
        transmorphic scalar valid_set, treat_map
        string scalar key
        
        // Build valid_units set for efficient lookup
        valid_set = asarray_create("real", 1)
        for (i = 1; i <= rows(valid_units); i++) {
            asarray(valid_set, valid_units[i], 1)
        }
        
        // Filter observations to valid units
        unit_filter = J(N_orig, 1, 0)
        for (i = 1; i <= N_orig; i++) {
            if (asarray_contains(valid_set, data.id_unit[i])) {
                unit_filter[i] = 1
            }
        }
        
        time_filter = (data.id_time :== t)
        combined_filter = unit_filter :& time_filter
        idx_treat = selectindex(combined_filter)
        
        // Build treatment info map for efficient lookup
        treat_map = asarray_create("real", 1)
        for (i = 1; i <= rows(idx_treat); i++) {
            asarray(treat_map, data.id_unit[idx_treat[i]], data.treatment[idx_treat[i]])
        }
        
        // Step 3: Get outcome observations for lead times
        min_lead_time = t + (min_lead > 1 ? min_lead : 1)
        max_lead_time = t + max_lead
        
        // Explicitly exclude missing values in time filter
        // Required because Mata treats missing >= x as true
        time_filter = (data.id_time :< .) :& (data.id_time :>= min_lead_time) :& (data.id_time :<= max_lead_time)
        combined_filter = unit_filter :& time_filter
        idx_lead = selectindex(combined_filter)
        
        // Handle no lead observations
        N_lead = length(idx_lead)
        if (N_lead == 0) {
            return(dat_use)
        }
        
        // Step 4: Extract lead data and join treatment info
        lead_outcome = data.outcome[idx_lead]
        lead_id_unit = data.id_unit[idx_lead]
        lead_id_time = data.id_time[idx_lead]
        
        // Join treatment info by unit ID
        lead_treatment = J(N_lead, 1, .)
        for (i = 1; i <= N_lead; i++) {
            if (asarray_contains(treat_map, lead_id_unit[i])) {
                lead_treatment[i] = asarray(treat_map, lead_id_unit[i])
            }
        }
    }
    
    // Handle covariates
    if (cols(data.covariates) > 0 && rows(data.covariates) > 0) {
        lead_covariates = data.covariates[idx_lead, .]
    }
    else {
        lead_covariates = J(0, 0, .)
    }
    
    // Handle cluster variable
    if (rows(data.cluster_var) > 0) {
        lead_cluster = data.cluster_var[idx_lead]
    }
    else {
        lead_cluster = J(0, 1, .)
    }
    
    // Step 5: Append lead data to dat_use
    result = did_data()
    N_total = N_use + N_lead
    
    result.outcome = dat_use.outcome \ lead_outcome
    result.treatment = dat_use.treatment \ lead_treatment
    result.id_unit = dat_use.id_unit \ lead_id_unit
    result.id_time = dat_use.id_time \ lead_id_time
    
    // Covariates
    if (cols(dat_use.covariates) > 0 && cols(lead_covariates) > 0) {
        result.covariates = dat_use.covariates \ lead_covariates
    }
    else if (cols(dat_use.covariates) > 0) {
        result.covariates = dat_use.covariates \ J(N_lead, cols(dat_use.covariates), .)
    }
    else if (cols(lead_covariates) > 0) {
        result.covariates = J(N_use, cols(lead_covariates), .) \ lead_covariates
    }
    else {
        result.covariates = J(0, 0, .)
    }
    
    // Cluster variable
    if (rows(dat_use.cluster_var) > 0 && rows(lead_cluster) > 0) {
        result.cluster_var = dat_use.cluster_var \ lead_cluster
    }
    else if (rows(dat_use.cluster_var) > 0) {
        result.cluster_var = dat_use.cluster_var \ J(N_lead, 1, .)
    }
    else if (rows(lead_cluster) > 0) {
        result.cluster_var = J(N_use, 1, .) \ lead_cluster
    }
    else {
        result.cluster_var = J(0, 1, .)
    }
    
    // Derived variables (will be recomputed by sa_prepare_did_data)
    result.Gi = J(0, 1, .)
    result.It = J(0, 1, .)
    result.id_time_std = J(0, 1, .)
    result.outcome_delta = J(0, 1, .)
    
    // Metadata
    result.N = N_total
    result.n_units = rows(uniqrows(result.id_unit))
    result.n_periods = rows(uniqrows(result.id_time))
    result.treat_year = t
    result.is_panel = dat_use.is_panel
    
    return(result)
}


/*---------------------------------------------------------------------------
 * sa_prepare_did_data() - Compute Derived Variables for DID Estimation
 *
 * Derived variables required for DID estimation are computed:
 *   - G_i: group indicator (treatment status)
 *   - I_t: post-treatment indicator
 *   - id_time_std: standardized time relative to treatment
 *   - Delta_Y: outcome change from lagged group mean
 *
 * Arguments:
 *   data : struct did_data - subset data from previous processing
 *   t    : real scalar - treatment period (for time standardization)
 *
 * Returns:
 *   struct did_data with derived variables computed
 *
 * Algorithm:
 *   1. G_i = max(treatment) per unit is computed (0 = control, 1 = treated)
 *   2. I_t = 1{id_time >= t} is computed
 *   3. id_time_std = id_time - t is computed
 *   4. Delta_Y = Y - Y_bar(G_i, id_time_std - 1) is computed
 *      where Y_bar is the lagged group mean
 *---------------------------------------------------------------------------*/
struct did_data scalar sa_prepare_did_data(struct did_data scalar data,
                                            real scalar t)
{
    struct did_data scalar result
    real colvector Gi, It, id_time_std, outcome_delta
    real scalar N, j, g, ts
    real scalar mean_y
    transmorphic scalar unit_map, group_mean_map, group_has_na_map
    real colvector idx
    string scalar key, lag_key
    real scalar sum_y, n_obs
    
    // Copy input data
    result = data
    N = data.N
    
    // Handle empty data
    if (N == 0) {
        result.Gi = J(0, 1, .)
        result.It = J(0, 1, .)
        result.id_time_std = J(0, 1, .)
        result.outcome_delta = J(0, 1, .)
        return(result)
    }
    
    // Step 1: Compute Gi (group indicator)
    // Gi = 1 if unit is ever treated, 0 otherwise
    unit_map = asarray_create("real", 1)
    for (j = 1; j <= N; j++) {
        if (asarray_contains(unit_map, data.id_unit[j])) {
            if (data.treatment[j] > asarray(unit_map, data.id_unit[j])) {
                asarray(unit_map, data.id_unit[j], data.treatment[j])
            }
        }
        else {
            asarray(unit_map, data.id_unit[j], data.treatment[j])
        }
    }
    
    // Map Gi back to observations
    Gi = J(N, 1, .)
    for (j = 1; j <= N; j++) {
        Gi[j] = asarray(unit_map, data.id_unit[j])
    }
    
    // Step 2: Compute It (post-treatment indicator)
    // Explicitly exclude missing values (required for correct comparison)
    It = (data.id_time :< .) :& (data.id_time :>= t)
    
    // Step 3: Compute id_time_std (standardized time relative to treatment)
    id_time_std = data.id_time :- t
    
    // Step 4: Compute outcome_delta (Delta_Y = Y - lag_group_mean(Y))
    // Lagged group means follow the observed-sample analogue: missing outcomes
    // drop out of the mean but do not invalidate the whole group-period.
    
    // Build (Gi, id_time_std) -> (sum, count) map using hash table
    group_mean_map = asarray_create("string", 1)
    
    for (j = 1; j <= N; j++) {
        // Skip observations with missing key components
        if (!missing(Gi[j]) && !missing(id_time_std[j])) {
            key = strofreal(Gi[j]) + "_" + strofreal(id_time_std[j])
            
            if (missing(data.outcome[j])) {
                continue
            }
            else {
                // Accumulate sum and count for non-missing values
                if (asarray_contains(group_mean_map, key)) {
                    idx = asarray(group_mean_map, key)
                    idx[1] = idx[1] + data.outcome[j]  // sum
                    idx[2] = idx[2] + 1                 // count
                    asarray(group_mean_map, key, idx)
                }
                else {
                    asarray(group_mean_map, key, (data.outcome[j], 1))
                }
            }
        }
    }
    
    // Compute outcome_delta: Delta_Y = Y - Y_bar(G_i, t-1)
    outcome_delta = J(N, 1, .)
    
    for (j = 1; j <= N; j++) {
        // Skip observations with missing Gi or id_time_std
        if (missing(Gi[j]) || missing(id_time_std[j])) {
            continue
        }
        
        g = Gi[j]
        ts = id_time_std[j] - 1  // Lag by 1 period
        
        // Look up mean for (g, ts)
        lag_key = strofreal(g) + "_" + strofreal(ts)
        if (asarray_contains(group_mean_map, lag_key)) {
            idx = asarray(group_mean_map, lag_key)
            if (idx[2] > 0) {
                mean_y = idx[1] / idx[2]  // sum / count
                
                if (!missing(data.outcome[j])) {
                    outcome_delta[j] = data.outcome[j] - mean_y
                }
            }
        }
    }
    
    // Store derived variables
    result.Gi = Gi
    result.It = It
    result.id_time_std = id_time_std
    result.outcome_delta = outcome_delta
    result.treat_year = t
    
    return(result)
}


// ----------------------------------------------------------------------------
// SA MAIN ESTIMATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * sa_estimate() - SA Design Main Entry Point
 *
 * The complete SA estimation workflow is orchestrated: data validation,
 * point estimation, bootstrap variance estimation, and GMM-based double
 * DID aggregation.
 *
 * Arguments:
 *   data   : struct did_data - panel data (normalized unit/time indices)
 *   option : struct did_option - estimation options:
 *            - thres: minimum treated units per period (default=2)
 *            - lead: lead values for dynamic effects (default=0)
 *            - n_boot: bootstrap iterations (default=30)
 *            - level: confidence level (default=95)
 *            - quiet: suppress progress display (default=0)
 *
 * Returns:
 *   struct sa_ddid_result containing:
 *     - estimate: SA-Double-DID estimates (tau_dDID)
 *     - tau_did, tau_sdid: SA-DID and SA-sDID estimates
 *     - variance, std_error: bootstrap variance and standard errors
 *     - ci_low, ci_high: bootstrap percentile confidence intervals
 *     - w_did, w_sdid: GMM optimal weights
 *     - W_matrices: precision matrices
 *
 * Algorithm:
 *   1. Data normalization is validated (indices start from 1, consecutive)
 *   2. Gmat is constructed and valid periods are validated
 *   3. Point estimation is performed via sa_double_did()
 *   4. Panel bootstrap: resample units, recompute full estimation
 *   5. GMM aggregation via sa_to_ddid(point_est, boot_est, lead)
 *---------------------------------------------------------------------------*/
struct sa_ddid_result scalar sa_estimate(struct did_data scalar data,
                                          struct did_option scalar option)
{
    struct sa_ddid_result scalar result
    struct sa_point scalar point_est
    struct sa_point scalar boot_pt
    pointer(struct sa_point scalar) vector boot_est
    struct did_data scalar dat_boot
    
    real matrix Gmat
    real colvector id_time_use, time_weight, support_idx
    pointer vector id_subj_use
    
    real scalar n_boot, n_lead, b, n_boot_success
    real scalar progress_freq
    real colvector unique_times, unique_units  // For consecutive validation
    real scalar has_valid_estimate, ll  // For multi-lead validation
    
    // Step 0: Initialize and validate
    n_boot = option.n_boot
    n_lead = cols(option.lead)
    
    // Validate input data is panel format
    if (data.is_panel != 1) {
        errprintf("sa_estimate(): SA design requires panel data (not RCS)\n")
        result = sa_ddid_result()  // Initialize for error return
        return(result)
    }
    
    // Validate data has required fields
    if (data.N == 0) {
        errprintf("sa_estimate(): No observations in data\n")
        result = sa_ddid_result()  // Initialize for error return
        return(result)
    }
    
    // Step 1: Data preparation verification
    // Verify id_time is normalized (should start from 1)
    if (min(data.id_time) != 1) {
        errprintf("sa_estimate(): id_time should be normalized to start from 1\n")
        errprintf("               Found min(id_time) = %g\n", min(data.id_time))
        result = sa_ddid_result()  // Initialize for error return
        return(result)
    }
    
    // Verify id_unit is normalized (should start from 1)
    if (min(data.id_unit) != 1) {
        errprintf("sa_estimate(): id_unit should be normalized to start from 1\n")
        errprintf("               Found min(id_unit) = %g\n", min(data.id_unit))
        result = sa_ddid_result()  // Initialize for error return
        return(result)
    }
    
    // Verify id_time is consecutive integers 1, 2, ..., T
    unique_times = uniqrows(data.id_time)
    if (rows(unique_times) != max(data.id_time)) {
        errprintf("sa_estimate(): id_time must be consecutive integers 1, 2, ..., T\n")
        errprintf("               Found %g unique values but max = %g\n", 
                  rows(unique_times), max(data.id_time))
        result = sa_ddid_result()
        return(result)
    }
    
    // Also verify id_unit is consecutive
    unique_units = uniqrows(data.id_unit)
    if (rows(unique_units) != max(data.id_unit)) {
        errprintf("sa_estimate(): id_unit must be consecutive integers 1, 2, ..., N\n")
        errprintf("               Found %g unique values but max = %g\n",
                  rows(unique_units), max(data.id_unit))
        result = sa_ddid_result()
        return(result)
    }
    
    // Step 2: Compute Gmat and validate
    Gmat = create_gmat(data.id_unit, data.id_time, data.treatment)
    
    if (rows(Gmat) == 0 || cols(Gmat) == 0) {
        errprintf("sa_estimate(): Failed to create Gmat\n")
        result = sa_ddid_result()  // Initialize for error return
        return(result)
    }
    
    id_time_use = get_periods(Gmat, option.thres)
    
    if (rows(id_time_use) == 0) {
        errprintf("sa_estimate(): No valid periods found with threshold = %g\n", option.thres)
        result = sa_ddid_result()
        return(result)
    }
    
    // Get time weights for validation
    time_weight = get_time_weight(Gmat, id_time_use)
    
    // Verify weights sum to 1.0
    if (abs(sum(time_weight) - 1.0) > 1e-10) {
        errprintf("sa_estimate(): Time weights do not sum to 1.0 (sum = %g)\n", sum(time_weight))
        result = sa_ddid_result()
        return(result)
    }
    
    // Step 3: Point estimation on original data
    point_est = sa_double_did(data, option)
    
    // Check if ANY lead has valid estimates (not just the first one)
    has_valid_estimate = 0
    for (ll = 1; ll <= n_lead; ll++) {
        if (!missing(point_est.DID[ll]) || !missing(point_est.sDID[ll])) {
            has_valid_estimate = 1
            break
        }
    }
    if (!has_valid_estimate) {
        errprintf("sa_estimate(): Point estimation failed for all leads\n")
        result = sa_ddid_result()
        return(result)
    }
    
    // Step 4: Bootstrap loop for variance estimation
    // Each iteration fully recomputes Gmat, periods, subjects, and weights
    
    // Handle n_boot = 0 case (skip bootstrap)
    if (n_boot == 0) {
        errprintf("sa_estimate(): n_boot = 0, bootstrap skipped (confidence intervals unavailable)\n")
        // Return point estimates only
        result.tau_did = point_est.DID
        result.tau_sdid = point_est.sDID
        return(result)
    }
    
    // Pre-allocate pointer vector for bootstrap results
    boot_est = J(n_boot, 1, NULL)
    n_boot_success = 0
    progress_freq = 10
    
    for (b = 1; b <= n_boot; b++) {
        // Progress display
        if (option.quiet == 0 && mod(b, progress_freq) == 0) {
            printf("Bootstrap: %g/%g (%g%%)\n", b, n_boot, round(100*b/n_boot))
            displayflush()
        }
        
        // Resample panel data (unit-level resampling)
        dat_boot = sample_panel(data)
        
        // Compute SA estimates on bootstrap sample
        // (sa_double_did() internally recomputes Gmat, periods, subjects, weights)
        boot_pt = sa_double_did(dat_boot, option)
        
        // Store result if valid (check ALL leads, not just first one)
        has_valid_estimate = 0
        for (ll = 1; ll <= n_lead; ll++) {
            if (!missing(boot_pt.DID[ll]) || !missing(boot_pt.sDID[ll])) {
                has_valid_estimate = 1
                break
            }
        }
        if (has_valid_estimate) {
            // Allocate new struct and store pointer
            boot_est[b] = &(sa_point())
            (*boot_est[b]).DID = boot_pt.DID
            (*boot_est[b]).sDID = boot_pt.sDID
            n_boot_success++
        }
    }
    
    // Final progress display
    if (option.quiet == 0) {
        printf("Bootstrap: %g/%g (100%%)\n", n_boot, n_boot)
        displayflush()
    }
    
    // Check for sufficient bootstrap samples
    if (n_boot_success < 2) {
        errprintf("sa_estimate(): Bootstrap failed - only %g of %g iterations succeeded\n",
                  n_boot_success, n_boot)
        // Return point estimates only (initialize result for this error path)
        result = sa_ddid_result()
        result.tau_did = point_est.DID
        result.tau_sdid = point_est.sDID
        return(result)
    }
    
    // Warn if some bootstrap iterations failed
    if (n_boot_success < n_boot) {
        printf("Warning: %g of %g bootstrap iterations failed\n", 
               n_boot - n_boot_success, n_boot)
    }
    
    // Step 5: Compute Double DID with GMM weights
    result = sa_to_ddid(point_est, boot_est, option.lead, option.level)
    
    return(result)
}


/*---------------------------------------------------------------------------
 * _did_sa_main() - SA Estimation Entry Point (Ado Interface)
 *
 * This function serves as the entry point for SA estimation called from
 * _diddesign_sa.ado. The full SA estimation pipeline is implemented and
 * global result matrices are populated for retrieval by the ado file.
 *
 * Note: For direct Mata usage, sa_estimate() is preferred as it returns
 * a structured result without side effects.
 *
 * Arguments:
 *   lead    : real rowvector - lead values for dynamic effects
 *   n_boot  : real scalar - number of bootstrap iterations
 *   thres   : real scalar - threshold for valid periods
 *   level   : real scalar - confidence level (default: 95)
 *   quiet   : real scalar - suppress progress display (default: 0)
 *
 * Side Effects:
 *   Global matrices are populated: _sa_b, _sa_V, _sa_estimates, _sa_weights, etc.
 *---------------------------------------------------------------------------*/
real scalar sa_sync_public_ddid_display(real matrix boot_posted_joint,
                                        real colvector posted_idx,
                                        real matrix posted_joint_vcov,
                                        real scalar level)
{
    external real matrix _sa_estimates

    real colvector complete_rows, ddid_draws
    real scalar alpha, pos, coef_idx, lead_slot, est_row, var_ddid

    complete_rows = selectindex(rowmissing(boot_posted_joint) :== 0)
    if (rows(complete_rows) < 2) {
        return(0)
    }

    alpha = 1 - level / 100

    for (pos = 1; pos <= rows(posted_idx); pos++) {
        coef_idx = posted_idx[pos]
        if (mod(coef_idx - 1, 3) != 0) {
            continue
        }

        var_ddid = posted_joint_vcov[pos, pos]
        if (missing(var_ddid) || var_ddid < 0) {
            continue
        }

        ddid_draws = boot_posted_joint[complete_rows, pos]
        ddid_draws = select(ddid_draws, ddid_draws :< .)
        if (rows(ddid_draws) < 2) {
            continue
        }

        lead_slot = floor((coef_idx - 1) / 3) + 1
        est_row = 3 * (lead_slot - 1) + 1
        _sa_estimates[est_row, 3] = sqrt(var_ddid)
        _sa_estimates[est_row, 4] = quantile_sorted(ddid_draws, alpha / 2)
        _sa_estimates[est_row, 5] = quantile_sorted(ddid_draws, 1 - alpha / 2)
    }

    return(0)
}

real scalar _did_sa_main(real rowvector lead, real scalar n_boot, 
                          real scalar thres, real scalar level,
                          | real scalar quiet)
{
    // Declare external global data structure
    external struct did_data scalar did_dat
    external struct did_option scalar did_opt
    
    // Declare external global result variables for SA
    external real rowvector _sa_b
    external real matrix _sa_V
    external real matrix _sa_estimates
    external real rowvector _sa_lead_values
    external real matrix _sa_weights
    external real matrix _sa_W
    external real matrix _sa_vcov_gmm
    external real matrix _sa_bootstrap_support
    external real scalar _sa_n_boot_success
    external real scalar _sa_n_periods_valid
    external real matrix _sa_time_weights
    external real matrix _sa_time_weight_period_idx
    external real matrix _sa_time_weights_by_lead
    
    struct sa_point scalar point_est
    struct sa_point scalar boot_pt
    pointer(struct sa_point scalar) vector boot_est
    struct sa_ddid_result scalar ddid_res
    struct did_data scalar dat_boot
    
    real matrix Gmat
    real colvector id_time_use, time_weight, support_idx
    pointer vector id_subj_use
    
    real scalar n_lead, l, row, b
    real scalar tau_did, tau_sdid, tau_ddid
    real scalar var_did, var_sdid, var_ddid
    real scalar cov_did_sdid, cov_ddid_did, cov_ddid_sdid
    real scalar se_did, se_sdid, se_ddid
    real scalar ci_lo_did, ci_hi_did, ci_lo_sdid, ci_hi_sdid
    real scalar ci_lo_ddid, ci_hi_ddid
    real scalar w_did, w_sdid
    real scalar n_boot_success
    real scalar progress_freq
    real scalar has_valid_estimate, boot_has_valid, ll_check
    real scalar base_col, boot_ddid, boot_w_did, boot_w_sdid
    real scalar boot_did, boot_sdid
    real matrix boot_posted_all, boot_posted_joint, posted_joint_vcov
    real colvector posted_idx
    
    // Step 0: Set default parameters
    if (args() < 4) level = 95
    if (args() < 5) quiet = 0
    
    // Store options in did_opt for use by sa_double_did
    did_opt.thres = thres
    did_opt.lead = lead
    did_opt.n_boot = n_boot
    did_opt.level = level
    did_opt.quiet = quiet
    
    // Step 1: Initialize result storage
    n_lead = cols(lead)
    
    _sa_b = J(1, 3 * n_lead, .)
    _sa_V = J(3 * n_lead, 3 * n_lead, 0)
    _sa_estimates = J(3 * n_lead, 6, .)
    _sa_lead_values = lead
    _sa_weights = J(n_lead, 2, .)
    _sa_W = J(n_lead, 4, .)           // Flattened 2x2 matrices
    _sa_vcov_gmm = J(n_lead, 4, .)    // Flattened 2x2 matrices
    _sa_bootstrap_support = J(n_lead, 3, 0)
    _sa_n_boot_success = n_boot
    _sa_n_periods_valid = 0
    _sa_time_weights = J(0, 1, .)
    _sa_time_weight_period_idx = J(0, 1, .)
    _sa_time_weights_by_lead = J(0, 0, .)
    
    // Step 2: Compute Gmat and valid periods
    Gmat = create_gmat(did_dat.id_unit, did_dat.id_time, did_dat.treatment)
    
    if (rows(Gmat) == 0 || cols(Gmat) == 0) {
        errprintf("_did_sa_main(): Failed to create Gmat\n")
        return(1)
    }
    
    id_time_use = get_periods(Gmat, thres)

    if (rows(id_time_use) == 0) {
        errprintf("_did_sa_main(): No valid periods found with threshold = %g\n", thres)
        return(2)
    }
    
    id_subj_use = get_subjects(Gmat, id_time_use)
    time_weight = get_time_weight(Gmat, id_time_use)
    support_idx = sa_get_estimable_period_idx(id_time_use, id_subj_use, lead, max(did_dat.id_time))

    // Step 3: Obtain point estimates
    point_est = sa_double_did(did_dat, did_opt)

    if (rows(point_est.periods) > 0 && cols(point_est.weights_common) > 0) {
        real colvector union_idx, union_weight

        union_idx = selectindex(rowsum(point_est.weights_common) :> 0)
        if (rows(union_idx) > 0) {
            _sa_time_weight_period_idx = point_est.periods[union_idx]
            _sa_time_weights_by_lead = point_est.weights_common[union_idx, .]
            union_weight = rowsum(_sa_time_weights_by_lead)
            if (sum(union_weight) > 0 & !missing(sum(union_weight))) {
                _sa_time_weights = union_weight / sum(union_weight)
            }
            else {
                _sa_time_weights = J(rows(union_idx), 1, .)
            }
            _sa_n_periods_valid = rows(union_idx)
        }
        else {
            _sa_n_periods_valid = 0
            _sa_time_weight_period_idx = J(0, 1, .)
            _sa_time_weights = J(0, 1, .)
            _sa_time_weights_by_lead = J(0, n_lead, .)
        }
    }
    else {
        _sa_n_periods_valid = 0
        _sa_time_weight_period_idx = J(0, 1, .)
        _sa_time_weights = J(0, 1, .)
        _sa_time_weights_by_lead = J(0, n_lead, .)
    }
    
    // Check if ANY lead has valid estimates (not just the first one)
    has_valid_estimate = 0
    for (ll_check = 1; ll_check <= n_lead; ll_check++) {
        if (!missing(point_est.DID[ll_check]) || !missing(point_est.sDID[ll_check])) {
            has_valid_estimate = 1
            break
        }
    }
    if (!has_valid_estimate) {
        errprintf("_did_sa_main(): Point estimation failed for all leads\n")
        return(3)
    }
    
    // Step 4: Bootstrap loop for variance estimation
    boot_est = J(n_boot, 1, NULL)
    n_boot_success = 0
    progress_freq = max((1, floor(n_boot / 10)))
    
    for (b = 1; b <= n_boot; b++) {
        // Progress display
        if (quiet == 0 && mod(b, progress_freq) == 0) {
            printf("{txt}Bootstrap: %g/%g (%g%%)\n", b, n_boot, round(100*b/n_boot))
            displayflush()
        }
        
        // Sample panel data (block bootstrap by unit)
        dat_boot = sample_panel(did_dat)
        
        // Run SA estimation on bootstrap sample
        boot_pt = sa_double_did(dat_boot, did_opt)
        
        // Check if ANY lead has valid estimates
        boot_has_valid = 0
        for (ll_check = 1; ll_check <= n_lead; ll_check++) {
            if (!missing(boot_pt.DID[ll_check]) || !missing(boot_pt.sDID[ll_check])) {
                boot_has_valid = 1
                break
            }
        }
        if (boot_has_valid) {
            // Allocate new struct and store pointer
            boot_est[b] = &(sa_point())
            (*boot_est[b]).DID = boot_pt.DID
            (*boot_est[b]).sDID = boot_pt.sDID
            n_boot_success++
        }
    }
    
    // Final progress display
    if (quiet == 0) {
        printf("{txt}Bootstrap: %g/%g (100%%)\n", n_boot, n_boot)
        displayflush()
    }
    
    _sa_n_boot_success = n_boot_success
    
    // Check for sufficient bootstrap samples
    if (n_boot_success < 2) {
        errprintf("_did_sa_main(): Bootstrap failed - only %g of %g iterations succeeded\n",
                  n_boot_success, n_boot)
        return(4)
    }
    
    // Step 5: Compute Double DID via GMM
    ddid_res = sa_to_ddid(point_est, boot_est, lead, level)
    
    // Step 6: Store results in global matrices
    row = 1
    for (l = 1; l <= n_lead; l++) {
        
        // Extract results for this lead
        tau_ddid = ddid_res.estimate[l]
        tau_did = ddid_res.tau_did[l]
        tau_sdid = ddid_res.tau_sdid[l]
        
        var_ddid = ddid_res.variance[l]
        var_did = ddid_res.var_did[l]
        var_sdid = ddid_res.var_sdid[l]
        
        se_ddid = ddid_res.std_error[l]
        se_did = sqrt(var_did)
        se_sdid = sqrt(var_sdid)
        
        w_did = ddid_res.w_did[l]
        w_sdid = ddid_res.w_sdid[l]
        
        ci_lo_ddid = ddid_res.ci_low[l]
        ci_hi_ddid = ddid_res.ci_high[l]
        cov_did_sdid = .
        cov_ddid_did = .
        cov_ddid_sdid = .
        
        // Store weights
        _sa_weights[l, .] = (w_did, w_sdid)
        
        // Store W matrix (flattened) if available
        if (ddid_res.W_matrices[l] != NULL) {
            _sa_W[l, .] = vec(*ddid_res.W_matrices[l])'
        }
        
        // Store VCOV matrix (flattened) if available
        if (ddid_res.VCOV_matrices[l] != NULL) {
            _sa_vcov_gmm[l, .] = vec(*ddid_res.VCOV_matrices[l])'
            cov_did_sdid = (*ddid_res.VCOV_matrices[l])[1, 2]
            cov_ddid_did = w_did * var_did + w_sdid * cov_did_sdid
            cov_ddid_sdid = w_did * cov_did_sdid + w_sdid * var_sdid
        }
        else if (!missing(var_did) && !missing(var_sdid)) {
            // Fallback: Store only diagonal elements if VCOV not available
            _sa_vcov_gmm[l, 1] = var_did
            _sa_vcov_gmm[l, 2] = .  // Cov(DID, sDID) - not available
            _sa_vcov_gmm[l, 3] = .  // Cov(DID, sDID) - not available
            _sa_vcov_gmm[l, 4] = var_sdid
        }
        
        // Compute bootstrap percentile CIs for DID and sDID
        // (sa_to_ddid() returns only dDID CI; DID/sDID CIs computed separately)
        ci_lo_did = .
        ci_hi_did = .
        ci_lo_sdid = .
        ci_hi_sdid = .
        _sa_bootstrap_support[l, .] = _sa_bootstrap_support_counts(boot_est, l)
        
        _sa_compute_bootstrap_ci(boot_est, l, level, &ci_lo_did, &ci_hi_did, 
                                 &ci_lo_sdid, &ci_hi_sdid)
        
        // ---------------------------------------------------------------------
        // Store results in matrices
        // ---------------------------------------------------------------------
        
        // e(b): coefficient vector [SA_dDID, SA_DID, SA_sDID] for each lead
        _sa_b[1, 3*(l-1)+1] = tau_ddid
        _sa_b[1, 3*(l-1)+2] = tau_did
        _sa_b[1, 3*(l-1)+3] = tau_sdid
        
        // e(V): variance-covariance matrix (diagonal)
        _sa_V[3*(l-1)+1, 3*(l-1)+1] = var_ddid
        _sa_V[3*(l-1)+2, 3*(l-1)+2] = var_did
        _sa_V[3*(l-1)+3, 3*(l-1)+3] = var_sdid
        if (!missing(cov_ddid_did)) {
            _sa_V[3*(l-1)+1, 3*(l-1)+2] = cov_ddid_did
            _sa_V[3*(l-1)+2, 3*(l-1)+1] = cov_ddid_did
        }
        if (!missing(cov_ddid_sdid)) {
            _sa_V[3*(l-1)+1, 3*(l-1)+3] = cov_ddid_sdid
            _sa_V[3*(l-1)+3, 3*(l-1)+1] = cov_ddid_sdid
        }
        if (!missing(cov_did_sdid)) {
            _sa_V[3*(l-1)+2, 3*(l-1)+3] = cov_did_sdid
            _sa_V[3*(l-1)+3, 3*(l-1)+2] = cov_did_sdid
        }
        
        // e(estimates): full results table
        // Row order: SA_dDID, SA_DID, SA_sDID for each lead
        // Columns: lead, estimate, std.error, ci_lo, ci_hi, weight
        
        // SA-Double-DID row
        _sa_estimates[row, 1] = lead[l]
        _sa_estimates[row, 2] = tau_ddid
        _sa_estimates[row, 3] = se_ddid
        _sa_estimates[row, 4] = ci_lo_ddid
        _sa_estimates[row, 5] = ci_hi_ddid
        _sa_estimates[row, 6] = .  // No weight for dDID
        row = row + 1
        
        // SA-DID row
        _sa_estimates[row, 1] = lead[l]
        _sa_estimates[row, 2] = tau_did
        _sa_estimates[row, 3] = se_did
        _sa_estimates[row, 4] = ci_lo_did
        _sa_estimates[row, 5] = ci_hi_did
        _sa_estimates[row, 6] = w_did
        row = row + 1
        
        // SA-sDID row
        _sa_estimates[row, 1] = lead[l]
        _sa_estimates[row, 2] = tau_sdid
        _sa_estimates[row, 3] = se_sdid
        _sa_estimates[row, 4] = ci_lo_sdid
        _sa_estimates[row, 5] = ci_hi_sdid
        _sa_estimates[row, 6] = w_sdid
        row = row + 1
    }

    // Rebuild the public multi-lead e(V) on the jointly observed posted
    // bootstrap vector. Per-lead marginal blocks and zero cross-lead blocks
    // are not a valid covariance matrix for postestimation under mixed support.
    if (n_lead > 1 && n_boot_success >= 2) {
        boot_posted_all = J(n_boot, 3 * n_lead, .)
        for (b = 1; b <= n_boot; b++) {
            if (boot_est[b] == NULL) {
                continue
            }

            boot_pt = *boot_est[b]
            for (l = 1; l <= n_lead; l++) {
                base_col = 3 * (l - 1)
                boot_ddid = .
                boot_did = .
                boot_sdid = .
                boot_w_did = _sa_weights[l, 1]
                boot_w_sdid = _sa_weights[l, 2]

                if (l <= cols(boot_pt.DID)) {
                    boot_did = boot_pt.DID[l]
                }
                if (l <= cols(boot_pt.sDID)) {
                    boot_sdid = boot_pt.sDID[l]
                }
                if (!missing(boot_did) && !missing(boot_sdid) &&
                    !missing(boot_w_did) && !missing(boot_w_sdid)) {
                    boot_ddid = boot_w_did * boot_did + boot_w_sdid * boot_sdid
                }

                boot_posted_all[b, base_col + 1] = boot_ddid
                boot_posted_all[b, base_col + 2] = boot_did
                boot_posted_all[b, base_col + 3] = boot_sdid
            }
        }

        posted_idx = selectindex((_sa_b' :< .) :& (diagonal(_sa_V) :< .))
        if (rows(posted_idx) >= 2) {
            boot_posted_joint = boot_posted_all[., posted_idx]
            posted_joint_vcov = sa_posted_joint_vcov(boot_posted_joint)
            if (!missing(posted_joint_vcov)) {
                _sa_V[posted_idx, posted_idx] = posted_joint_vcov
                sa_sync_public_ddid_display(boot_posted_joint,
                                            posted_idx,
                                            posted_joint_vcov,
                                            level)
            }
        }
    }
    
    return(0)  // Success
}


/*---------------------------------------------------------------------------
 * _sa_compute_bootstrap_ci() - Compute Bootstrap Percentile CIs
 *
 * Bootstrap percentile confidence intervals are computed for SA-DID and
 * SA-sDID estimators at a specified lead index.
 *
 * Arguments:
 *   boot_est   : pointer vector - bootstrap sa_point structures
 *   lead_idx   : real scalar - lead index (1-based)
 *   level      : real scalar - confidence level (e.g., 95)
 *   ci_lo_did  : pointer(real scalar) - output: lower CI for DID
 *   ci_hi_did  : pointer(real scalar) - output: upper CI for DID
 *   ci_lo_sdid : pointer(real scalar) - output: lower CI for sDID
 *   ci_hi_sdid : pointer(real scalar) - output: upper CI for sDID
 *---------------------------------------------------------------------------*/
real rowvector _sa_bootstrap_support_counts(pointer(struct sa_point scalar) vector boot_est,
                                            real scalar lead_idx)
{
    struct sa_point scalar pt
    real scalar n_boot, b, n_valid_did, n_valid_sdid, n_joint_valid
    real scalar did_valid, sdid_valid

    n_boot = length(boot_est)
    n_valid_did = 0
    n_valid_sdid = 0
    n_joint_valid = 0

    for (b = 1; b <= n_boot; b++) {
        if (boot_est[b] == NULL) {
            continue
        }

        pt = *boot_est[b]
        if (lead_idx < 1 || lead_idx > cols(pt.DID) || lead_idx > cols(pt.sDID)) {
            continue
        }

        did_valid = !missing(pt.DID[lead_idx])
        sdid_valid = !missing(pt.sDID[lead_idx])

        if (did_valid) n_valid_did++
        if (sdid_valid) n_valid_sdid++
        if (did_valid & sdid_valid) n_joint_valid++
    }

return((n_valid_did, n_valid_sdid, n_joint_valid))
}

void _sa_compute_bootstrap_ci(pointer(struct sa_point scalar) vector boot_est,
                               real scalar lead_idx,
                               real scalar level,
                               pointer(real scalar) scalar ci_lo_did,
                               pointer(real scalar) scalar ci_hi_did,
                               pointer(real scalar) scalar ci_lo_sdid,
                               pointer(real scalar) scalar ci_hi_sdid)
{
    struct sa_point scalar pt
    real colvector boot_did, boot_sdid, boot_did_valid, boot_sdid_valid
    real scalar n_boot, b, alpha
    
    n_boot = length(boot_est)
    alpha = 1 - level / 100
    
    // Initialize with missing
    *ci_lo_did = .
    *ci_hi_did = .
    *ci_lo_sdid = .
    *ci_hi_sdid = .
    
    if (n_boot < 2) {
        return
    }
    
    // Extract bootstrap estimates
    boot_did = J(n_boot, 1, .)
    boot_sdid = J(n_boot, 1, .)
    
    for (b = 1; b <= n_boot; b++) {
        if (boot_est[b] == NULL) {
            continue
        }
        
        pt = *boot_est[b]
        
        // Check lead_idx bounds before accessing vectors
        if (lead_idx < 1 || lead_idx > cols(pt.DID) || lead_idx > cols(pt.sDID)) {
            continue
        }
        
        boot_did[b] = pt.DID[lead_idx]
        boot_sdid[b] = pt.sDID[lead_idx]
    }

    boot_did_valid = select(boot_did, boot_did :< .)
    if (rows(boot_did_valid) >= 2) {
        *ci_lo_did = quantile_sorted(boot_did_valid, alpha / 2)
        *ci_hi_did = quantile_sorted(boot_did_valid, 1 - alpha / 2)
    }

    boot_sdid_valid = select(boot_sdid, boot_sdid :< .)
    if (rows(boot_sdid_valid) >= 2) {
        *ci_lo_sdid = quantile_sorted(boot_sdid_valid, alpha / 2)
        *ci_hi_sdid = quantile_sorted(boot_sdid_valid, 1 - alpha / 2)
    }
}

/*---------------------------------------------------------------------------
 * sa_posted_joint_vcov() - Joint-valid covariance for posted SA public vector
 *
 * The public multi-lead e(V) matrix should represent the covariance of the
 * posted estimator vector itself. We therefore use only bootstrap rows where
 * every posted component is jointly observed.
 *---------------------------------------------------------------------------*/
real matrix sa_posted_joint_vcov(real matrix boot_posted)
{
    return(compute_vcov_joint_valid(boot_posted))
}


/*---------------------------------------------------------------------------
 * _did_sa_prepare_data() - Load and Normalize Data for SA Estimation
 *
 * Data is loaded from Stata into the global did_dat structure and unit/time
 * identifiers are normalized to consecutive integers (1, 2, 3, ...).
 * This function is called from _diddesign_sa.ado before _did_sa_main().
 *
 * Arguments:
 *   outcome_var   : string - outcome variable name
 *   treatment_var : string - treatment indicator variable name
 *   id_var        : string - unit identifier variable name
 *   time_var      : string - time identifier variable name
 *   cluster_var   : string - cluster variable name (or empty)
 *   covariates    : string - space-separated covariate names
 *   touse_var     : string - sample marker variable name
 *
 * Side Effects:
 *   Global did_dat structure is populated with normalized data
 *---------------------------------------------------------------------------*/
real scalar _did_sa_prepare_data(string scalar outcome_var,
                                  string scalar treatment_var,
                                  string scalar id_var,
                                  string scalar time_var,
                                  string scalar cluster_var,
                                  string scalar covariates,
                                  string scalar touse_var)
{
    // Declare external global data structure
    external struct did_data scalar did_dat
    external struct did_option scalar did_opt
    
    real colvector outcome, treatment, id_unit, id_time, cluster
    real matrix covars
    real colvector unique_units, unique_times
    real colvector id_unit_norm, id_time_norm
    real scalar N, i, n_units, n_times, j
    string rowvector covar_names
    real scalar n_covars
    
    // Step 0: Initialize global structures
    did_dat = did_data()
    did_opt = init_did_option()
    
    // Step 1: Load data from Stata
    
    // Load main variables (only for touse == 1)
    outcome = st_data(., outcome_var, touse_var)
    treatment = st_data(., treatment_var, touse_var)
    id_unit = st_data(., id_var, touse_var)
    id_time = st_data(., time_var, touse_var)
    
    N = rows(outcome)
    
    if (N == 0) {
        errprintf("_did_sa_prepare_data(): No observations selected\n")
        return(1)
    }
    
    // Load cluster variable
    if (cluster_var != "") {
        cluster = st_data(., cluster_var, touse_var)
    }
    else {
        // Keep the default unit-bootstrap path implicit so downstream SA
        // resampling uses the normalized id_unit first-appearance frame
        // rather than raw label values.
        cluster = J(0, 1, .)
    }
    
    // Load covariates if specified
    if (covariates != "") {
        covar_names = tokens(covariates)
        n_covars = cols(covar_names)
        covars = st_data(., covariates, touse_var)
    }
    else {
        n_covars = 0
        covars = J(0, 0, .)
    }
    
    // Step 2: Normalize id_unit and id_time to sequential integers (1, 2, ...)
    unique_units = unique_in_order(id_unit)
    unique_times = uniqrows(id_time)
    n_units = rows(unique_units)
    n_times = rows(unique_times)
    
    // Build mapping: original ID -> normalized index
    transmorphic scalar unit_map, time_map
    unit_map = asarray_create("real")
    time_map = asarray_create("real")
    
    for (j = 1; j <= n_units; j++) {
        asarray(unit_map, unique_units[j], j)
    }
    for (j = 1; j <= n_times; j++) {
        asarray(time_map, unique_times[j], j)
    }
    
    // Create normalized IDs
    id_unit_norm = J(N, 1, .)
    id_time_norm = J(N, 1, .)
    
    for (i = 1; i <= N; i++) {
        id_unit_norm[i] = asarray(unit_map, id_unit[i])
        id_time_norm[i] = asarray(time_map, id_time[i])
    }
    
    // Step 3: Populate global did_dat structure
    did_dat.outcome = outcome
    did_dat.treatment = treatment
    did_dat.id_unit = id_unit_norm
    did_dat.id_time = id_time_norm
    did_dat.cluster_var = cluster
    did_dat.covariates = covars
    
    // Metadata
    did_dat.N = N
    did_dat.n_units = n_units
    did_dat.n_periods = n_times
    did_dat.is_panel = 1
    
    // Derived variables will be computed during estimation
    did_dat.Gi = J(0, 1, .)
    did_dat.It = J(0, 1, .)
    did_dat.id_time_std = J(0, 1, .)
    did_dat.outcome_delta = J(0, 1, .)
    did_dat.treat_year = .
    
    return(0)  // Success
}


// ----------------------------------------------------------------------------
// PARALLEL BOOTSTRAP: SA FROM PRE-COLLECTED BOOTSTRAP
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_sa_main_from_boot() - SA GMM from Pre-Collected Bootstrap
 *
 * Parallel bootstrap path for SA design: accepts pre-collected bootstrap
 * estimates via Mata external global _par_boot_est (populated by putmata
 * in coordinator), then runs the GMM → e() storage pipeline without
 * re-running bootstrap.
 *
 * Arguments:
 *   lead    : real rowvector - lead values
 *   level   : real scalar - confidence level (e.g., 95)
 *   quiet   : real scalar - suppress progress display (default: 0)
 *
 * Returns:
 *   real scalar - 0 = success, non-zero = error code
 *
 * Side Effects:
 *   Populates global result variables: _sa_b, _sa_V, _sa_estimates, etc.
 *   Clears _par_boot_est and _par_sa_point_est after use.
 *---------------------------------------------------------------------------*/
real scalar _did_sa_main_from_boot(
    real rowvector lead,
    real scalar level,
    | real scalar quiet)
{
    external struct did_data scalar did_dat
    external struct did_option scalar did_opt
    external real matrix _par_boot_est
    external struct sa_point scalar _par_sa_point_est

    // Declare external global result variables for SA
    external real rowvector _sa_b
    external real matrix _sa_V
    external real matrix _sa_estimates
    external real rowvector _sa_lead_values
    external real matrix _sa_weights
    external real matrix _sa_W
    external real matrix _sa_vcov_gmm
    external real matrix _sa_bootstrap_support
    external real scalar _sa_n_boot_success
    external real scalar _sa_n_periods_valid
    external real matrix _sa_time_weights
    external real matrix _sa_time_weight_period_idx
    external real matrix _sa_time_weights_by_lead

    struct sa_ddid_result scalar ddid_res
    real scalar n_lead, l, row
    real scalar tau_did, tau_sdid, tau_ddid
    real scalar var_did, var_sdid, var_ddid
    real scalar se_did, se_sdid, se_ddid
    real scalar ci_lo_ddid, ci_hi_ddid
    real scalar ci_lo_did, ci_hi_did, ci_lo_sdid, ci_hi_sdid
    real scalar cov_did_sdid, cov_ddid_did, cov_ddid_sdid
    real scalar w_did, w_sdid, w_did_l, w_sdid_l
    real matrix boot_pairs, boot_posted_all
    real colvector boot_did_valid, boot_sdid_valid
    real colvector posted_idx, boot_ddid_col, boot_did_col, boot_sdid_col
    real matrix posted_joint_vcov
    real scalar n_valid_did, n_valid_sdid, n_joint_valid
    real scalar alpha, row_l, n_boot_success

    if (args() < 2) level = 95
    if (args() < 3) quiet = 0

    n_lead = cols(lead)
    alpha  = 1 - level / 100

    // Validate pre-collected bootstrap matrix
    if (rows(_par_boot_est) == 0) {
        errprintf("_did_sa_main_from_boot(): No valid bootstrap samples\n")
        return(4)
    }
    if (cols(_par_boot_est) != 2 * n_lead) {
        errprintf("_did_sa_main_from_boot(): Column count mismatch (%g vs %g expected)\n",
                  cols(_par_boot_est), 2 * n_lead)
        return(5)
    }

    // Initialize result storage
    _sa_b = J(1, 3 * n_lead, .)
    _sa_V = J(3 * n_lead, 3 * n_lead, 0)
    _sa_estimates = J(3 * n_lead, 6, .)
    _sa_lead_values = lead
    _sa_weights = J(n_lead, 2, .)
    _sa_W = J(n_lead, 4, .)
    _sa_vcov_gmm = J(n_lead, 4, .)
    _sa_bootstrap_support = J(n_lead, 3, 0)
    _sa_n_boot_success = rows(_par_boot_est)

    // Populate time weight globals from point estimate (same logic as _did_sa_main)
    _sa_n_periods_valid = 0
    _sa_time_weights = J(0, 1, .)
    _sa_time_weight_period_idx = J(0, 1, .)
    _sa_time_weights_by_lead = J(0, 0, .)

    if (rows(_par_sa_point_est.periods) > 0 && cols(_par_sa_point_est.weights_common) > 0) {
        real colvector union_idx, union_weight
        union_idx = selectindex(rowsum(_par_sa_point_est.weights_common) :> 0)
        if (rows(union_idx) > 0) {
            _sa_time_weight_period_idx = _par_sa_point_est.periods[union_idx]
            _sa_time_weights_by_lead = _par_sa_point_est.weights_common[union_idx, .]
            union_weight = rowsum(_sa_time_weights_by_lead)
            if (sum(union_weight) > 0 & !missing(sum(union_weight))) {
                _sa_time_weights = union_weight / sum(union_weight)
            }
            else {
                _sa_time_weights = J(rows(union_idx), 1, .)
            }
            _sa_n_periods_valid = rows(union_idx)
        }
    }

    // Compute Double DID via GMM using matrix-based function
    ddid_res = sa_to_ddid_matrix(_par_sa_point_est, _par_boot_est, lead, level)

    // Store results in global matrices
    row = 1
    for (l = 1; l <= n_lead; l++) {

        // Extract results for this lead
        tau_ddid = ddid_res.estimate[l]
        tau_did = ddid_res.tau_did[l]
        tau_sdid = ddid_res.tau_sdid[l]

        var_ddid = ddid_res.variance[l]
        var_did = ddid_res.var_did[l]
        var_sdid = ddid_res.var_sdid[l]

        se_ddid = ddid_res.std_error[l]
        se_did = sqrt(var_did)
        se_sdid = sqrt(var_sdid)

        w_did = ddid_res.w_did[l]
        w_sdid = ddid_res.w_sdid[l]

        ci_lo_ddid = ddid_res.ci_low[l]
        ci_hi_ddid = ddid_res.ci_high[l]

        // Store weights
        _sa_weights[l, .] = (w_did, w_sdid)

        // Store W matrix (flattened) if available
        if (ddid_res.W_matrices[l] != NULL) {
            _sa_W[l, .] = vec(*ddid_res.W_matrices[l])'
        }

        // Store VCOV matrix (flattened) and extract within-lead covariances
        cov_did_sdid  = .
        cov_ddid_did  = .
        cov_ddid_sdid = .
        if (ddid_res.VCOV_matrices[l] != NULL) {
            _sa_vcov_gmm[l, .] = vec(*ddid_res.VCOV_matrices[l])'
            cov_did_sdid = (*ddid_res.VCOV_matrices[l])[1, 2]
            if (!missing(w_did) && !missing(w_sdid) && !missing(cov_did_sdid)) {
                cov_ddid_did  = w_did  * var_did         + w_sdid * cov_did_sdid
                cov_ddid_sdid = w_did  * cov_did_sdid   + w_sdid * var_sdid
            }
        }
        else if (!missing(var_did) && !missing(var_sdid)) {
            // Fallback: store only diagonal elements if VCOV not available
            _sa_vcov_gmm[l, 1] = var_did
            _sa_vcov_gmm[l, 2] = .
            _sa_vcov_gmm[l, 3] = .
            _sa_vcov_gmm[l, 4] = var_sdid
        }

        // Compute bootstrap support counts
        boot_pairs = _par_boot_est[., (2*l - 1)..(2*l)]
        n_valid_did = rows(select(boot_pairs[., 1], boot_pairs[., 1] :< .))
        n_valid_sdid = rows(select(boot_pairs[., 2], boot_pairs[., 2] :< .))
        n_joint_valid = rows(select(boot_pairs, rowmissing(boot_pairs) :== 0))
        _sa_bootstrap_support[l, .] = (n_valid_did, n_valid_sdid, n_joint_valid)

        // Store in coefficient vector
        _sa_b[1, 3*(l-1)+1] = tau_ddid
        _sa_b[1, 3*(l-1)+2] = tau_did
        _sa_b[1, 3*(l-1)+3] = tau_sdid

        // Store in variance-covariance matrix (diagonal + off-diagonal)
        _sa_V[3*(l-1)+1, 3*(l-1)+1] = var_ddid
        _sa_V[3*(l-1)+2, 3*(l-1)+2] = var_did
        _sa_V[3*(l-1)+3, 3*(l-1)+3] = var_sdid
        if (!missing(cov_ddid_did)) {
            _sa_V[3*(l-1)+1, 3*(l-1)+2] = cov_ddid_did
            _sa_V[3*(l-1)+2, 3*(l-1)+1] = cov_ddid_did
        }
        if (!missing(cov_ddid_sdid)) {
            _sa_V[3*(l-1)+1, 3*(l-1)+3] = cov_ddid_sdid
            _sa_V[3*(l-1)+3, 3*(l-1)+1] = cov_ddid_sdid
        }
        if (!missing(cov_did_sdid)) {
            _sa_V[3*(l-1)+2, 3*(l-1)+3] = cov_did_sdid
            _sa_V[3*(l-1)+3, 3*(l-1)+2] = cov_did_sdid
        }

        // Compute bootstrap percentile CIs for DID and sDID from matrix columns
        ci_lo_did  = .
        ci_hi_did  = .
        ci_lo_sdid = .
        ci_hi_sdid = .
        boot_pairs = _par_boot_est[., (2*l - 1)..(2*l)]
        boot_did_valid  = select(boot_pairs[., 1], boot_pairs[., 1] :< .)
        if (rows(boot_did_valid) >= 2) {
            ci_lo_did = quantile_sorted(boot_did_valid,  alpha / 2)
            ci_hi_did = quantile_sorted(boot_did_valid,  1 - alpha / 2)
        }
        boot_sdid_valid = select(boot_pairs[., 2], boot_pairs[., 2] :< .)
        if (rows(boot_sdid_valid) >= 2) {
            ci_lo_sdid = quantile_sorted(boot_sdid_valid, alpha / 2)
            ci_hi_sdid = quantile_sorted(boot_sdid_valid, 1 - alpha / 2)
        }

        // Store in estimates table
        // SA-Double-DID row
        _sa_estimates[row, 1] = lead[l]
        _sa_estimates[row, 2] = tau_ddid
        _sa_estimates[row, 3] = se_ddid
        _sa_estimates[row, 4] = ci_lo_ddid
        _sa_estimates[row, 5] = ci_hi_ddid
        _sa_estimates[row, 6] = .
        row = row + 1

        // SA-DID row
        _sa_estimates[row, 1] = lead[l]
        _sa_estimates[row, 2] = tau_did
        _sa_estimates[row, 3] = se_did
        _sa_estimates[row, 4] = ci_lo_did
        _sa_estimates[row, 5] = ci_hi_did
        _sa_estimates[row, 6] = w_did
        row = row + 1

        // SA-sDID row
        _sa_estimates[row, 1] = lead[l]
        _sa_estimates[row, 2] = tau_sdid
        _sa_estimates[row, 3] = se_sdid
        _sa_estimates[row, 4] = ci_lo_sdid
        _sa_estimates[row, 5] = ci_hi_sdid
        _sa_estimates[row, 6] = w_sdid
        row = row + 1
    }

    // Rebuild multi-lead e(V) on jointly observed posted bootstrap vector.
    // Mirrors the corresponding block in _did_sa_main() for the sequential path.
    // Only needed when n_lead > 1 and enough bootstrap samples are available.
    n_boot_success = rows(_par_boot_est)
    if (n_lead > 1 && n_boot_success >= 2) {
        boot_posted_all = J(n_boot_success, 3 * n_lead, .)
        for (l = 1; l <= n_lead; l++) {
            row_l    = 3 * (l - 1)
            w_did_l  = _sa_weights[l, 1]
            w_sdid_l = _sa_weights[l, 2]
            boot_did_col  = _par_boot_est[., 2*l - 1]
            boot_sdid_col = _par_boot_est[., 2*l]
            boot_posted_all[., row_l + 2] = boot_did_col
            boot_posted_all[., row_l + 3] = boot_sdid_col
            if (!missing(w_did_l) && !missing(w_sdid_l)) {
                boot_ddid_col = _combine_bootstrap_ddid(boot_did_col, boot_sdid_col,
                                                        w_did_l, w_sdid_l)
                boot_posted_all[., row_l + 1] = boot_ddid_col
            }
        }

        posted_idx = selectindex((_sa_b' :< .) :& (diagonal(_sa_V) :< .))
        if (rows(posted_idx) >= 2) {
            real matrix boot_posted_joint
            boot_posted_joint = boot_posted_all[., posted_idx]
            posted_joint_vcov = sa_posted_joint_vcov(boot_posted_joint)
            if (!missing(posted_joint_vcov)) {
                real scalar _sync_dummy
                _sa_V[posted_idx, posted_idx] = posted_joint_vcov
                _sync_dummy = sa_sync_public_ddid_display(boot_posted_joint,
                                                          posted_idx,
                                                          posted_joint_vcov,
                                                          level)
            }
        }
    }

    // Clean up external globals (after multi-lead VCOV block which may use _par_boot_est)
    _par_boot_est = J(0, 0, .)
    _par_sa_point_est = sa_point()

    return(0)
}

// ============================================================================
// GENERALIZED K-DID FOR STAGGERED ADOPTION DESIGN
// ============================================================================

/*---------------------------------------------------------------------------
 * struct sa_point_k - K-dimensional SA Point Estimates
 *
 * Stores time-weighted K-component estimates for each lead value.
 *---------------------------------------------------------------------------*/
struct sa_point_k {
    real matrix components      // K-component estimates (kmax x n_lead)
    real colvector periods      // Public period index
    real matrix weights_common  // Common-support time weights by lead
    real scalar kmax            // Number of components
}

/*---------------------------------------------------------------------------
 * subset_data_sa_k() - Subset Data for K-DID SA Period Estimation
 *
 * Like subset_data_sa() but includes deeper pre-history {t-kmax, ..., t-1, t+lead}
 * needed for k-th order components.
 *---------------------------------------------------------------------------*/
struct did_data scalar subset_data_sa_k(struct did_data scalar data,
                                         real colvector idx_subj,
                                         real scalar t,
                                         real scalar lead,
                                         real scalar kmax)
{
    struct did_data scalar result
    real colvector units, valid_units, idx, time_filter, unit_filter, combined_filter
    real colvector idx_treat_t
    real scalar i, N_orig, N_sub, p
    transmorphic scalar valid_set, treat_map

    result = did_data()

    if (rows(idx_subj) == 0) {
        result.N = 0
        return(result)
    }

    N_orig = rows(data.id_unit)
    units = uniqrows(data.id_unit)

    if (max(idx_subj) > rows(units) || min(idx_subj) < 1) {
        result.N = 0
        return(result)
    }

    valid_units = units[idx_subj]

    valid_set = asarray_create("real", 1)
    for (i = 1; i <= rows(valid_units); i++) {
        asarray(valid_set, valid_units[i], 1)
    }

    unit_filter = J(N_orig, 1, 0)
    for (i = 1; i <= N_orig; i++) {
        if (asarray_contains(valid_set, data.id_unit[i])) {
            unit_filter[i] = 1
        }
    }

    // Preserve treatment assignment at time t
    treat_map = asarray_create("real", 1)
    idx_treat_t = selectindex(unit_filter :& (data.id_time :== t))
    for (i = 1; i <= rows(idx_treat_t); i++) {
        asarray(treat_map, data.id_unit[idx_treat_t[i]], data.treatment[idx_treat_t[i]])
    }

    // Time filter: {t-kmax, ..., t-2, t-1, t+lead}
    time_filter = J(N_orig, 1, 0)
    for (p = 1; p <= kmax; p++) {
        time_filter = time_filter :| (data.id_time :== (t - p))
    }
    time_filter = time_filter :| (data.id_time :== (t + lead))

    combined_filter = unit_filter :& time_filter
    idx = selectindex(combined_filter)

    N_sub = length(idx)
    if (N_sub == 0) {
        result.N = 0
        return(result)
    }

    result.outcome = data.outcome[idx]
    result.id_unit = data.id_unit[idx]
    result.id_time = data.id_time[idx]
    result.treatment = J(N_sub, 1, .)
    for (i = 1; i <= N_sub; i++) {
        if (asarray_contains(treat_map, result.id_unit[i])) {
            result.treatment[i] = asarray(treat_map, result.id_unit[i])
        }
        else {
            result.treatment[i] = data.treatment[idx[i]]
        }
    }

    if (cols(data.covariates) > 0 && rows(data.covariates) > 0) {
        result.covariates = data.covariates[idx, .]
    }
    else {
        result.covariates = J(0, 0, .)
    }

    if (rows(data.cluster_var) > 0) {
        result.cluster_var = data.cluster_var[idx]
    }
    else {
        result.cluster_var = J(0, 1, .)
    }

    result.N = N_sub
    result.n_units = rows(uniqrows(result.id_unit))
    result.n_periods = rows(uniqrows(result.id_time))
    result.treat_year = t
    result.is_panel = data.is_panel

    return(result)
}

/*---------------------------------------------------------------------------
 * sa_compute_did_k() - K-dimensional SA Period-Specific Estimation
 *
 * For each valid period t, computes k=1..kmax component estimators using
 * did_fit_k(), then aggregates across periods using common-target weights.
 *
 * Common-target constraint: only periods where ALL k=1..K components are
 * jointly identified enter the same GMM. This is an engineering decision
 * to ensure all moments target the same estimand.
 *---------------------------------------------------------------------------*/
struct sa_point_k scalar sa_compute_did_k(struct did_data scalar data,
                                           real colvector id_time_use,
                                           pointer vector id_subj_use,
                                           real colvector time_weight,
                                           real rowvector lead,
                                           real scalar kmax,
                                           | real scalar min_time)
{
    struct sa_point_k scalar result
    struct did_data scalar dat_use, dat_did
    real matrix est_components, treated_count
    real colvector time_weight_new, period_id_new, idx_subj, idx_subj_lead
    real colvector common_idx, weight_norm
    real rowvector comp_k
    real scalar n_periods, max_time, i, t, iter, ll, kk, n_lead
    real scalar n_valid, sum_w, all_identified
    real rowvector feasible_leads

    if (args() < 7) min_time = kmax + 1

    n_periods = rows(id_time_use)
    n_lead = length(lead)

    result.kmax = kmax
    result.components = J(kmax, n_lead, .)
    result.periods = J(0, 1, .)
    result.weights_common = J(0, n_lead, .)

    if (n_periods == 0) {
        return(result)
    }

    // Pre-allocate: est_components[period, k, lead] stored as 3D via n_periods × (kmax*n_lead)
    est_components = J(n_periods, kmax * n_lead, .)
    treated_count = J(n_periods, n_lead, 0)
    time_weight_new = J(n_periods, 1, .)
    period_id_new = J(n_periods, 1, .)

    iter = 1
    for (i = 1; i <= n_periods; i++) {
        t = id_time_use[i]

        if (t < min_time) continue

        feasible_leads = select(lead, (t :+ lead) :<= max(data.id_time))
        if (length(feasible_leads) == 0) continue

        idx_subj = *id_subj_use[i]
        if (rows(idx_subj) == 0) continue

        for (ll = 1; ll <= n_lead; ll++) {
            if (t + lead[ll] > max(data.id_time)) continue

            idx_subj_lead = sa_filter_subjects_by_lead(data, idx_subj, t, lead[ll])
            if (rows(idx_subj_lead) == 0) continue

            // Use extended subset for K-DID (deeper history)
            dat_use = subset_data_sa_k(data, idx_subj_lead, t, lead[ll], kmax)
            dat_did = sa_prepare_did_data(dat_use, t)

            // Compute K components
            comp_k = did_fit_k(dat_did.outcome, dat_did.Gi, dat_did.It,
                               dat_did.id_unit, dat_did.covariates,
                               dat_did.id_time_std, lead[ll], kmax,
                               dat_did.is_panel)

            for (kk = 1; kk <= kmax; kk++) {
                est_components[iter, kmax*(ll-1)+kk] = comp_k[kk]
            }

            // Count treated units for this period-lead (for weighting)
            treated_count[iter, ll] = sum(dat_did.Gi :== 1) / dat_did.n_periods
        }

        time_weight_new[iter] = time_weight[i]
        period_id_new[iter] = t
        iter++
    }

    n_valid = iter - 1
    if (n_valid == 0) {
        return(result)
    }

    est_components = est_components[1::n_valid, .]
    treated_count = treated_count[1::n_valid, .]
    time_weight_new = time_weight_new[1::n_valid]
    period_id_new = period_id_new[1::n_valid]
    result.periods = period_id_new
    result.weights_common = J(n_valid, n_lead, 0)

    // Common-target aggregation: for each lead, find periods where ALL
    // components k=1..kmax are identified, then aggregate with common weights
    for (ll = 1; ll <= n_lead; ll++) {
        common_idx = J(n_valid, 1, 0)
        for (i = 1; i <= n_valid; i++) {
            all_identified = 1
            for (kk = 1; kk <= kmax; kk++) {
                if (missing(est_components[i, kmax*(ll-1)+kk])) {
                    all_identified = 0
                    break
                }
            }
            if (all_identified & treated_count[i, ll] > 0) {
                common_idx[i] = 1
            }
        }

        real colvector cidx
        cidx = selectindex(common_idx)
        if (length(cidx) > 0) {
            weight_norm = treated_count[cidx, ll]
            sum_w = sum(weight_norm)
            if (sum_w > 0 & !missing(sum_w)) {
                weight_norm = weight_norm / sum_w
                for (kk = 1; kk <= kmax; kk++) {
                    result.components[kk, ll] = sum(est_components[cidx, kmax*(ll-1)+kk] :* weight_norm)
                }
                result.weights_common[cidx, ll] = weight_norm
            }
        }
    }

    return(result)
}

/*---------------------------------------------------------------------------
 * sa_double_did_k() - SA K-DID Point Estimation Coordinator
 *
 * K-dimensional extension of sa_double_did(). Uses common-target
 * aggregation across adoption periods.
 *---------------------------------------------------------------------------*/
struct sa_point_k scalar sa_double_did_k(struct did_data scalar data,
                                          struct did_option scalar option)
{
    struct sa_point_k scalar result
    real matrix Gmat
    real colvector id_time_use, time_weight
    pointer vector id_subj_use
    real scalar n_lead, kmax

    n_lead = length(option.lead)
    kmax = option.kmax
    result.kmax = kmax
    result.components = J(kmax, n_lead, .)
    result.periods = J(0, 1, .)
    result.weights_common = J(0, n_lead, .)

    Gmat = create_gmat(data.id_unit, data.id_time, data.treatment)
    if (rows(Gmat) == 0 || cols(Gmat) == 0) {
        return(result)
    }

    id_time_use = get_periods(Gmat, option.thres)
    if (rows(id_time_use) == 0) {
        return(result)
    }

    id_subj_use = get_subjects(Gmat, id_time_use)
    time_weight = get_time_weight(Gmat, id_time_use)

    result = sa_compute_did_k(data, id_time_use, id_subj_use, time_weight,
                              option.lead, kmax)

    return(result)
}

/*---------------------------------------------------------------------------
 * _did_sa_main_k() - Main SA K-DID Orchestrator
 *
 * K-dimensional extension of _did_sa_main(). Coordinates:
 *   1. K-dimensional SA point estimation
 *   2. SA bootstrap producing K components per lead
 *   3. K-dimensional GMM with J-test and numerical fallback
 *   4. Extended result storage
 *---------------------------------------------------------------------------*/
real scalar _did_sa_main_k(real rowvector lead, real scalar n_boot,
                            real scalar thres, real scalar level,
                            real scalar kmax, real scalar jtest_on,
                            | real scalar quiet)
{
    external struct did_data scalar did_dat
    external struct did_option scalar did_opt

    // SA result globals
    external real rowvector _sa_b
    external real matrix _sa_V
    external real matrix _sa_estimates
    external real rowvector _sa_lead_values
    external real matrix _sa_weights
    external real matrix _sa_W
    external real matrix _sa_vcov_gmm
    external real matrix _sa_bootstrap_support
    external real scalar _sa_n_boot_success
    external real scalar _sa_n_periods_valid
    external real matrix _sa_time_weights
    external real matrix _sa_time_weight_period_idx
    external real matrix _sa_time_weights_by_lead
    // K-DID specific
    external real matrix _sa_k_summary
    external real matrix _sa_jtest_stats

    struct sa_point_k scalar point_est, boot_pt
    struct gmm_weights_k scalar wk
    struct did_data scalar dat_boot

    real scalar n_lead, l, kk, row, b
    real scalar n_boot_success, progress_freq, has_valid, boot_has_valid, ll_check
    real scalar n_rows_per_lead, K_f, K_init_l
    real scalar alpha, z, col_start, col_end
    real matrix boot_components  // n_boot_success × (kmax * n_lead)
    real rowvector comp_b, kdid_est
    real colvector boot_comp_valid

    if (args() < 7) quiet = 0

    // Store options
    did_opt.thres = thres
    did_opt.lead = lead
    did_opt.n_boot = n_boot
    did_opt.level = level
    did_opt.quiet = quiet
    did_opt.kmax = kmax
    did_opt.jtest_on = jtest_on

    n_lead = cols(lead)
    n_rows_per_lead = 1 + kmax
    alpha = 1 - level / 100
    z = invnormal(1 - alpha / 2)

    // Initialize result storage
    _sa_b = J(1, n_rows_per_lead * n_lead, .)
    _sa_V = J(n_rows_per_lead * n_lead, n_rows_per_lead * n_lead, 0)
    _sa_estimates = J(n_rows_per_lead * n_lead, 14, .)
    _sa_lead_values = lead
    _sa_weights = J(n_lead, kmax, .)
    _sa_W = J(n_lead, kmax * kmax, .)
    _sa_vcov_gmm = J(n_lead, kmax * kmax, .)
    _sa_bootstrap_support = J(n_lead, kmax, 0)
    _sa_n_boot_success = n_boot
    _sa_n_periods_valid = 0
    _sa_time_weights = J(0, 1, .)
    _sa_time_weight_period_idx = J(0, 1, .)
    _sa_time_weights_by_lead = J(0, 0, .)
    _sa_k_summary = J(n_lead, 3, .)
    _sa_jtest_stats = J(n_lead, 3, .)

    // Step 1: Point estimates
    point_est = sa_double_did_k(did_dat, did_opt)

    // Store time weights metadata
    if (rows(point_est.periods) > 0 && cols(point_est.weights_common) > 0) {
        real colvector union_idx, union_weight
        union_idx = selectindex(rowsum(point_est.weights_common) :> 0)
        if (rows(union_idx) > 0) {
            _sa_time_weight_period_idx = point_est.periods[union_idx]
            _sa_time_weights_by_lead = point_est.weights_common[union_idx, .]
            union_weight = rowsum(_sa_time_weights_by_lead)
            if (sum(union_weight) > 0 & !missing(sum(union_weight))) {
                _sa_time_weights = union_weight / sum(union_weight)
            }
            _sa_n_periods_valid = rows(union_idx)
        }
    }

    // Check if any lead has valid estimates
    has_valid = 0
    for (ll_check = 1; ll_check <= n_lead; ll_check++) {
        for (kk = 1; kk <= kmax; kk++) {
            if (!missing(point_est.components[kk, ll_check])) {
                has_valid = 1
                break
            }
        }
        if (has_valid) break
    }
    if (!has_valid) {
        errprintf("_did_sa_main_k(): Point estimation failed for all leads\n")
        return(3)
    }

    // Step 2: Bootstrap
    boot_components = J(0, kmax * n_lead, .)
    n_boot_success = 0
    progress_freq = max((1, floor(n_boot / 10)))

    for (b = 1; b <= n_boot; b++) {
        if (quiet == 0 && mod(b, progress_freq) == 0) {
            printf("{txt}Bootstrap: %g/%g (%g%%)\n", b, n_boot, round(100*b/n_boot))
            displayflush()
        }

        dat_boot = sample_panel(did_dat)
        if (dat_boot.N == 0 || dat_boot.n_units < 2) continue

        boot_pt = sa_double_did_k(dat_boot, did_opt)

        // Check validity
        boot_has_valid = 0
        for (ll_check = 1; ll_check <= n_lead; ll_check++) {
            for (kk = 1; kk <= kmax; kk++) {
                if (!missing(boot_pt.components[kk, ll_check])) {
                    boot_has_valid = 1
                    break
                }
            }
            if (boot_has_valid) break
        }

        if (boot_has_valid) {
            // Flatten to row vector: (k1_l1, k2_l1, ..., kK_l1, k1_l2, ...)
            comp_b = J(1, kmax * n_lead, .)
            for (l = 1; l <= n_lead; l++) {
                for (kk = 1; kk <= kmax; kk++) {
                    comp_b[kmax*(l-1)+kk] = boot_pt.components[kk, l]
                }
            }
            boot_components = boot_components \ comp_b
            n_boot_success++
        }
    }

    if (quiet == 0) {
        printf("{txt}Bootstrap: %g/%g (100%%)\n", n_boot, n_boot)
        displayflush()
    }

    _sa_n_boot_success = n_boot_success
    if (n_boot_success < 2) {
        errprintf("_did_sa_main_k(): Bootstrap failed (%g/%g)\n", n_boot_success, n_boot)
        return(4)
    }

    // Step 3: GMM for each lead
    row = 1
    for (l = 1; l <= n_lead; l++) {
        col_start = kmax * (l - 1) + 1
        col_end = kmax * l

        real rowvector pt_l
        real matrix boot_l, VC_l
        pt_l = J(1, kmax, .)
        for (kk = 1; kk <= kmax; kk++) {
            pt_l[kk] = point_est.components[kk, l]
        }

        boot_l = boot_components[., col_start..col_end]

        // Determine K_init for this lead
        K_init_l = 0
        for (kk = 1; kk <= kmax; kk++) {
            if (!missing(pt_l[kk])) K_init_l = kk
            else break
        }

        // Bootstrap support
        for (kk = 1; kk <= kmax; kk++) {
            _sa_bootstrap_support[l, kk] = rows(select(boot_l[., kk], boot_l[., kk] :< .))
        }

        // GMM
        if (K_init_l >= 1) {
            VC_l = compute_vcov_joint_valid(boot_l)
            _sa_vcov_gmm[l, .] = vec(VC_l)'

            if (jtest_on && K_init_l >= 2) {
                wk = jtest_select(pt_l, VC_l, K_init_l)
            }
            else {
                wk = compute_weights_k(VC_l, kmax)
            }

            K_f = wk.K_final
            _sa_k_summary[l, .] = (K_init_l, K_f, K_f)
            _sa_weights[l, .] = wk.weights
            _sa_W[l, .] = vec(wk.W)'
            _sa_jtest_stats[l, .] = (wk.jtest_stat, wk.jtest_df, wk.jtest_pval)

            kdid_est = compute_kdid_estimate(pt_l, wk, boot_l, 1, level)
        }
        else {
            K_f = 0
            _sa_k_summary[l, .] = (K_init_l, K_init_l, 0)
            kdid_est = (., ., ., ., .)
        }

        // Store final row
        _sa_estimates[row, .] = (lead[l], kdid_est[1], kdid_est[3], kdid_est[4], kdid_est[5], .,
                                  0, ., ., ., ., K_init_l, K_f, K_f)
        _sa_b[row] = kdid_est[1]
        if (!missing(kdid_est[2])) _sa_V[row, row] = kdid_est[2]
        row++

        // Store component rows
        for (kk = 1; kk <= kmax; kk++) {
            real scalar tau_k, var_k, se_k, ci_lo_k, ci_hi_k, w_k
            tau_k = pt_l[kk]
            w_k = _sa_weights[l, kk]
            var_k = .
            se_k = .
            ci_lo_k = .
            ci_hi_k = .
            if (!missing(tau_k)) {
                boot_comp_valid = select(boot_l[., kk], boot_l[., kk] :< .)
                if (rows(boot_comp_valid) >= 2) {
                    var_k = variance(boot_comp_valid)
                    se_k = sqrt(var_k)
                    ci_lo_k = quantile_sorted(boot_comp_valid, alpha / 2)
                    ci_hi_k = quantile_sorted(boot_comp_valid, 1 - alpha / 2)
                }
            }
            _sa_estimates[row, .] = (lead[l], tau_k, se_k, ci_lo_k, ci_hi_k, w_k,
                                      kk, ., ., ., ., K_init_l, K_f, K_f)
            _sa_b[row] = tau_k
            if (!missing(var_k)) _sa_V[row, row] = var_k
            row++
        }
    }

    return(0)
}


// ----------------------------------------------------------------------------
// MODULE VERIFICATION FUNCTION
// ----------------------------------------------------------------------------

/*---------------------------------------------------------------------------
 * _did_sa_loaded() - Module Load Verification
 *
 * A confirmation message is displayed when did_sa.mata is loaded successfully.
 *---------------------------------------------------------------------------*/
void _did_sa_loaded()
{
    printf("{txt}did_sa.mata loaded successfully\n")
    printf("{txt}  - sa_estimate(): SA design main entry point\n")
    printf("{txt}  - sa_double_did(): SA point estimation\n")
}

end
