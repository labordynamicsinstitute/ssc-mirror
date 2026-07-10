*! _trop_estat_mht — Multiple hypothesis testing correction for trop

/*==============================================================================
  _trop_estat_mht

  Perform multiple hypothesis testing correction on treatment effects.

  Syntax:
    estat mht [, method(string) source(string) alpha(real)]

  Options:
    method(string)  - Correction method: bonferroni, holm, or bh (default: bh)
    source(string)  - Source of effects: cells or eventstudy (default: cells)
    alpha(real)     - Significance level (default: 0.05)

  Description:
    Applies family-wise error rate (FWER) or false discovery rate (FDR)
    corrections to multiple treatment effect estimates from trop.

    Methods:
      bonferroni    - Bonferroni correction (FWER): p_adj_i = min(K * p_i, 1)
      holm          - Holm step-down (FWER): sequential correction with
                      p_adj_(i) = max_{j<=i} min(p_(j) * (K-j+1), 1)
      bh            - Benjamini-Hochberg (FDR): sequential correction with
                      p_adj_(i) = min_{j>=i} min(p_(j) * K/j, 1)

    Sources:
      cells         - Individual cell-level effects from e(tau_matrix)
                      (requires method(twostep))
      eventstudy    - Event study horizon effects from prior estat eventstudy
==============================================================================*/

program define _trop_estat_mht, rclass
    version 17
    syntax [, Method(string) SOurce(string) Alpha(real 0.05)]

    // --- Default values ---
    if "`method'" == "" local method "bh"
    if "`source'" == "" local source "cells"

    // --- Validate method ---
    if !inlist("`method'", "bonferroni", "holm", "bh") {
        di as error "method() must be bonferroni, holm, or bh (Benjamini-Hochberg)"
        exit 198
    }

    // --- Validate alpha ---
    if `alpha' <= 0 | `alpha' >= 1 {
        di as error "alpha() must be between 0 and 1 (exclusive)"
        exit 198
    }

    // --- Check trop estimation results ---
    if "`e(cmd)'" != "trop" {
        di as error "estat mht requires trop estimation results"
        exit 301
    }

    // --- Validate source and extract effects ---
    if "`source'" == "eventstudy" {
        // From prior estat eventstudy results stored in r()
        capture confirm matrix r(event_effects)
        if _rc {
            di as error "estat mht with source(eventstudy) requires prior" ///
                " 'estat eventstudy' results"
            di as error "  Run: estat eventstudy"
            di as error "  Then: estat mht, source(eventstudy)"
            exit 301
        }
        tempname effects_mat
        matrix `effects_mat' = r(event_effects)
    }
    else if "`source'" == "cells" {
        // From e(tau_matrix) — requires twostep method
        capture confirm matrix e(tau_matrix)
        if _rc {
            di as error "e(tau_matrix) not found." ///
                " Run trop with method(twostep)."
            exit 301
        }
        if "`e(method)'" != "twostep" {
            di as error "source(cells) requires method(twostep)"
            exit 459
        }
    }
    else {
        di as error "source() must be eventstudy or cells"
        exit 198
    }

    // --- Pass alpha to Mata via temporary scalar ---
    tempname alpha_sc
    scalar `alpha_sc' = `alpha'

    // --- Execute correction in Mata ---
    if "`source'" == "eventstudy" {
        mata: _mht_execute("`effects_mat'", "eventstudy", "`method'", ///
            st_numscalar("`alpha_sc'"))
    }
    else {
        mata: _mht_execute("", "cells", "`method'", ///
            st_numscalar("`alpha_sc'"))
    }

    // --- Display results ---
    local K = scalar(__mht_K)
    local n_sig_raw = scalar(__mht_n_sig_raw)
    local n_sig_adj = scalar(__mht_n_sig_adj)

    // Method label
    if "`method'" == "bonferroni" {
        local method_label "Bonferroni (FWER)"
    }
    else if "`method'" == "holm" {
        local method_label "Holm step-down (FWER)"
    }
    else {
        local method_label "Benjamini-Hochberg (FDR)"
    }

    di as txt _n "{hline 70}"
    di as txt "Multiple Hypothesis Testing Correction"
    di as txt "{hline 70}"
    di as txt "  Method:           " as res "`method_label'"
    di as txt "  Source:           " as res "`source'"
    di as txt "  Number of tests:  " as res `K'
    di as txt "  Alpha level:      " as res %5.3f `alpha'
    di as txt ""
    di as txt "  Significant (raw):      " ///
        as res `n_sig_raw' as txt " / " as res `K'
    di as txt "  Significant (adjusted): " ///
        as res `n_sig_adj' as txt " / " as res `K'
    di as txt "{hline 70}"

    // Display detailed table if K is manageable
    if `K' <= 30 & `K' > 0 {
        di as txt ""
        di as txt _col(5) %10s "Effect" _col(18) %10s "SE" ///
            _col(31) %10s "p(raw)" _col(44) %10s "p(adj)" _col(57) "Sig?"
        di as txt "{hline 70}"
        forvalues i = 1/`K' {
            local eff = __mht_result[`i', 1]
            local se  = __mht_result[`i', 2]
            local praw = __mht_result[`i', 3]
            local padj = __mht_result[`i', 4]
            local sig = cond(`padj' < `alpha', "*", "")
            di as txt _col(5) %10.4f `eff' _col(18) %10.4f `se' ///
                _col(31) %10.4f `praw' _col(44) %10.4f `padj' _col(57) "`sig'"
        }
        di as txt "{hline 70}"
        di as txt "  * significant at alpha=" %4.2f `alpha' ///
            " after `method' correction"
    }
    else if `K' > 30 {
        di as txt ""
        di as txt "  (Table suppressed: K > 30. Access results via r(mht_results).)"
    }

    // --- Return results ---
    return matrix mht_results = __mht_result
    return scalar K = `K'
    return scalar n_significant_raw = `n_sig_raw'
    return scalar n_significant_adj = `n_sig_adj'
    return scalar alpha = `alpha'
    return local method "`method'"
    return local source "`source'"

    // --- Cleanup temporary scalars/matrices ---
    capture matrix drop __mht_result
    capture scalar drop __mht_K __mht_n_sig_raw __mht_n_sig_adj
end

/*==============================================================================
  Mata Implementation
==============================================================================*/

version 17
mata:
mata set matastrict on

/*------------------------------------------------------------------------------
  _mht_execute()

  Main entry point for multiple hypothesis testing correction.

  Arguments:
    effects_matname - Stata matrix name for eventstudy effects (or "" for cells)
    source          - "eventstudy" or "cells"
    method          - "bonferroni", "holm", or "bh"
    alpha           - Significance threshold

  Side effects:
    Creates Stata scalars __mht_K, __mht_n_sig_raw, __mht_n_sig_adj
    Creates Stata matrix __mht_result (K x 4: effect, se, p_raw, p_adj)
------------------------------------------------------------------------------*/
void _mht_execute(string scalar effects_matname, string scalar source,
    string scalar method, real scalar alpha)
{
    real colvector effects, ses, p_raw, p_adj
    real scalar K

    // --- Extract effects and standard errors ---
    if (source == "eventstudy") {
        _mht_extract_eventstudy(effects_matname, effects, ses)
    }
    else {
        _mht_extract_cells(effects, ses)
    }

    K = rows(effects)
    if (K == 0) {
        errprintf("No valid effects found for MHT correction\n")
        exit(error(2000))
    }

    // --- Compute raw two-sided p-values ---
    p_raw = _mht_compute_pvalues(effects, ses)

    // --- Apply correction ---
    if (method == "bonferroni") {
        p_adj = _mht_bonferroni(p_raw, K)
    }
    else if (method == "holm") {
        p_adj = _mht_holm(p_raw, K)
    }
    else {
        p_adj = _mht_bh(p_raw, K)
    }

    // --- Store results back to Stata ---
    _mht_store_results(effects, ses, p_raw, p_adj, alpha)
}

/*------------------------------------------------------------------------------
  _mht_extract_eventstudy()

  Extract effects and SE from event study results matrix.
  Expected layout: [horizon, effect, se, ci_lower, ci_upper, n_cells]
------------------------------------------------------------------------------*/
void _mht_extract_eventstudy(string scalar matname,
    real colvector effects, real colvector ses)
{
    real matrix emat

    emat = st_matrix(matname)
    if (rows(emat) == 0 | cols(emat) < 3) {
        effects = J(0, 1, .)
        ses = J(0, 1, .)
        return
    }
    effects = emat[., 2]
    ses = emat[., 3]
}

/*------------------------------------------------------------------------------
  _mht_extract_cells()

  Extract cell-level treatment effects from e(tau_matrix).
  Uses e(se) as a common standard error approximation for individual cells.
  Filters out missing values.
------------------------------------------------------------------------------*/
void _mht_extract_cells(real colvector effects, real colvector ses)
{
    real matrix tau_m
    real colvector tau_vec
    real scalar global_se, r, c, nrows, ncols

    tau_m = st_matrix("e(tau_matrix)")
    nrows = rows(tau_m)
    ncols = cols(tau_m)

    if (nrows == 0 | ncols == 0) {
        effects = J(0, 1, .)
        ses = J(0, 1, .)
        return
    }

    // Retrieve global SE from bootstrap (best available approximation)
    global_se = st_numscalar("e(se)")
    if (global_se == . | global_se <= 0) {
        errprintf("e(se) not available or non-positive;" +
            " cannot compute p-values for cells\n")
        effects = J(0, 1, .)
        ses = J(0, 1, .)
        return
    }

    // Flatten tau_matrix, keeping only non-missing entries (column-major)
    tau_vec = J(0, 1, .)
    for (c = 1; c <= ncols; c++) {
        for (r = 1; r <= nrows; r++) {
            if (tau_m[r, c] < .) {
                tau_vec = tau_vec \ tau_m[r, c]
            }
        }
    }

    effects = tau_vec
    ses = J(rows(effects), 1, global_se)
}

/*------------------------------------------------------------------------------
  _mht_compute_pvalues()

  Compute two-sided p-values from z-statistics: p = 2 * (1 - Phi(|z|)).
  Returns missing for entries where SE is missing or non-positive.
------------------------------------------------------------------------------*/
real colvector _mht_compute_pvalues(real colvector effects, real colvector ses)
{
    real colvector p_raw
    real scalar K, i, z

    K = rows(effects)
    p_raw = J(K, 1, .)

    for (i = 1; i <= K; i++) {
        if (ses[i] > 0 & ses[i] < .) {
            z = abs(effects[i] / ses[i])
            p_raw[i] = 2 * (1 - normal(z))
        }
    }
    return(p_raw)
}

/*------------------------------------------------------------------------------
  _mht_bonferroni()

  Bonferroni correction: p_adj_i = min(K * p_i, 1)
  Controls Family-Wise Error Rate (FWER).
------------------------------------------------------------------------------*/
real colvector _mht_bonferroni(real colvector p_raw, real scalar K)
{
    real colvector p_adj
    real scalar i

    p_adj = J(K, 1, .)
    for (i = 1; i <= K; i++) {
        if (p_raw[i] < .) {
            p_adj[i] = min((p_raw[i] * K, 1))
        }
    }
    return(p_adj)
}

/*------------------------------------------------------------------------------
  _mht_holm()

  Holm step-down procedure (FWER control).
  Algorithm:
    1. Sort p-values ascending: p_(1) <= p_(2) <= ... <= p_(K)
    2. For i = 1,...,K: p_adj_(i) = max_{j<=i} min(p_(j) * (K-j+1), 1)
  The step-down ensures monotonicity: p_adj_(1) <= p_adj_(2) <= ... <= p_adj_(K)
------------------------------------------------------------------------------*/
real colvector _mht_holm(real colvector p_raw, real scalar K)
{
    real colvector p_adj, p_sorted, perm
    real scalar i, adj_i, running_max

    perm = order(p_raw, 1)
    p_sorted = p_raw[perm]
    p_adj = J(K, 1, .)

    running_max = 0
    for (i = 1; i <= K; i++) {
        if (p_sorted[i] < .) {
            adj_i = min((p_sorted[i] * (K - i + 1), 1))
            running_max = max((running_max, adj_i))
            p_adj[perm[i]] = running_max
        }
    }
    return(p_adj)
}

/*------------------------------------------------------------------------------
  _mht_bh()

  Benjamini-Hochberg procedure (FDR control).
  Algorithm:
    1. Sort p-values descending: p_(K) >= p_(K-1) >= ... >= p_(1)
    2. Process from largest to smallest:
       p_adj_(i) = min_{j>=i} min(p_(j) * K/j, 1)
    This enforces monotonicity via a running minimum from the top.
------------------------------------------------------------------------------*/
real colvector _mht_bh(real colvector p_raw, real scalar K)
{
    real colvector p_adj, perm_desc, p_sorted_desc
    real scalar i, rank_i, adj_i, running_min

    perm_desc = order(p_raw, -1)
    p_sorted_desc = p_raw[perm_desc]
    p_adj = J(K, 1, .)

    running_min = 1
    for (i = 1; i <= K; i++) {
        // rank_i is the ascending rank of this observation
        rank_i = K - i + 1
        if (p_sorted_desc[i] < .) {
            adj_i = min((p_sorted_desc[i] * K / rank_i, 1))
            running_min = min((running_min, adj_i))
            p_adj[perm_desc[i]] = running_min
        }
    }
    return(p_adj)
}

/*------------------------------------------------------------------------------
  _mht_store_results()

  Store computed results as Stata matrix and scalars for display layer.
------------------------------------------------------------------------------*/
void _mht_store_results(real colvector effects, real colvector ses,
    real colvector p_raw, real colvector p_adj, real scalar alpha)
{
    real matrix result
    real scalar K, n_sig_raw, n_sig_adj

    K = rows(effects)
    result = (effects, ses, p_raw, p_adj)

    // Count significant tests
    n_sig_raw = sum(p_raw :< alpha)
    n_sig_adj = sum(p_adj :< alpha)

    // Handle missing in sum (treat as 0 if all missing)
    if (n_sig_raw == .) n_sig_raw = 0
    if (n_sig_adj == .) n_sig_adj = 0

    st_matrix("__mht_result", result)
    st_numscalar("__mht_K", K)
    st_numscalar("__mht_n_sig_raw", n_sig_raw)
    st_numscalar("__mht_n_sig_adj", n_sig_adj)
}

end
