*! _finegray_mata Version 1.0.0  2026/04/06
*! Mata forward-backward scan engine for Fine-Gray regression
*! Author: Timothy P Copeland
*! Department of Clinical Neuroscience, Karolinska Institutet
*! Program class: internal (stores results in Stata matrices)

/*
Internal command: Fits Fine-Gray subdistribution hazard model using
the forward-backward scan algorithm (Kawaguchi et al. 2021).
Called by finegray. Not intended for direct user invocation.

Algorithm: O(np) per Newton-Raphson iteration
  1. KM censoring distribution G(t) (supports left truncation)
  2. Incremental risk-set tracking with entry-time pointer
  3. Backward scan: weighted sums for competing-event subjects
  4. Combine at cause-event times for score/Hessian
  5. Newton-Raphson with step halving

Key detail: processes observations in time-point groups to correctly
handle tied events (Breslow method) and prevent double-counting of
competing events at tied cause-event times.

Left truncation: subjects enter the risk set at _t0 and exit at _t.
The entry-time pointer advances through subjects sorted by _t0,
adding them to the active risk set as event times are processed.
When all _t0 == 0, this degenerates to the original full-cumsum
algorithm.
*/

* Loading guard
capture program drop _finegray_mata_loaded
program define _finegray_mata_loaded
    version 16.0
    local _orig_varabbrev = c(varabbrev)
    set varabbrev off
    capture noisily {
        display as text "_finegray_mata is loaded"
    }
    local rc = _rc
    set varabbrev `_orig_varabbrev'
    if `rc' exit `rc'
end

mata:
mata set matastrict on

/* Single-stratum KM of censoring distribution (with left truncation) */
real colvector _finegray_km_censor_single(
    real colvector t,
    real colvector delta,
    real scalar censval,
    real colvector event_type,
    real colvector t0)
{
    real scalar n, i, j, surv, n_risk_at_t, n_cens_at_t, cur_time, ep
    real colvector G, ord, entry_ord

    n = rows(t)
    G = J(n, 1, 1)
    ord = order(t, 1)
    entry_ord = order(t0, 1)

    surv = 1
    ep = 1  /* entry pointer */
    n_risk_at_t = 0

    /* For LT-KM we need to count the risk set dynamically.
       Risk set at time t = subjects with t0 <= t AND _t >= t.
       Process entry events (sorted by t0) and exit events (sorted by _t)
       simultaneously. */

    /* Precompute: how many subjects have entered by each event time */
    /* Use two-pointer merge: advance entry pointer as we scan event times */

    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries: subjects with t0 <= cur_time */
        while (ep <= n) {
            if (t0[entry_ord[ep]] > cur_time) break
            /* Only count if subject is still alive (t >= cur_time) */
            if (t[entry_ord[ep]] >= cur_time) {
                n_risk_at_t++
            }
            ep++
        }

        /* Count censoring events in this time group */
        n_cens_at_t = 0
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            if (event_type[ord[j]] == censval & delta[ord[j]] == 0) {
                n_cens_at_t++
            }
            j++
        }

        if (n_cens_at_t > 0 & n_risk_at_t > 0) {
            surv = surv * (1 - n_cens_at_t / n_risk_at_t)
        }

        /* Assign G to all obs at this time, then remove them from risk set */
        while (i < j) {
            G[ord[i]] = surv
            n_risk_at_t--
            i++
        }
    }

    real scalar n_trunc
    n_trunc = 0
    for (i = 1; i <= n; i++) {
        if (G[i] < 1e-10) {
            G[i] = 1e-10
            n_trunc++
        }
    }
    if (n_trunc > 0) {
        printf("{txt}note: G(t) truncated to 1e-10 for %g observations;" +
            " inference may be sensitive\n", n_trunc)
    }

    return(G)
}

/* KM of censoring distribution, optionally stratified by byg */
real colvector _finegray_km_censor(
    real colvector t,
    real colvector delta,
    real scalar censval,
    real colvector event_type,
    real colvector byg_id,
    real colvector t0)
{
    real scalar n, g, nlev
    real colvector G, levels, sel

    n = rows(t)
    G = J(n, 1, 1)

    levels = uniqrows(byg_id)
    nlev = rows(levels)
    if (nlev > 1) {
        for (g = 1; g <= nlev; g++) {
            sel = selectindex(byg_id :== levels[g])
            G[sel] = _finegray_km_censor_single(t[sel], delta[sel],
                censval, event_type[sel], t0[sel])
        }
        return(G)
    }

    G = _finegray_km_censor_single(t, delta, censval, event_type, t0)
    return(G)
}

/* Log pseudo-likelihood via incremental risk-set scan with Breslow ties.
   Supports left truncation via entry-time pointer. */
real scalar _finegray_loglik(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector t0)
{
    real scalar n, p, i, j, k, ll, raw_bwd, idx, cur_time
    real scalar risk_S0, ep
    real colvector eta, expeta, is_cause, is_compete, ord, entry_ord

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    ord = order(t, 1)
    entry_ord = order(t0, 1)

    /* Incremental risk-set tracking */
    risk_S0 = 0
    ep = 1
    ll = 0
    raw_bwd = 0
    i = 1

    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries: subjects with t0 <= cur_time AND t >= cur_time */
        while (ep <= n) {
            if (t0[entry_ord[ep]] > cur_time) break
            if (t[entry_ord[ep]] >= cur_time) {
                risk_S0 = risk_S0 + expeta[entry_ord[ep]]
            }
            ep++
        }

        /* Find end of this time group */
        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }

        /* Process all cause events at this time (Breslow) */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                ll = ll + eta[idx] - log(risk_S0 + G[idx] * raw_bwd)
            }
        }

        /* AFTER processing cause events, add competing events to backward */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                raw_bwd = raw_bwd + expeta[idx] / G[idx]
            }
        }

        /* Remove exiting subjects from risk set */
        for (k = i; k < j; k++) {
            risk_S0 = risk_S0 - expeta[ord[k]]
        }

        i = j
    }

    return(ll)
}

/* Score vector and observed information via incremental risk-set scan.
   Supports left truncation. */
void _finegray_score_info(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector score,
    real matrix info,
    real colvector t0)
{
    real scalar n, p, i, j, k, idx, bwd_s0_raw, S0_total, cur_time
    real scalar risk_S0, ep
    real colvector eta, expeta, is_cause, is_compete, ord, entry_ord
    real matrix bwd_s2_raw, S2_total, risk_S2
    real rowvector bwd_s1_raw, S1_total, z_bar, risk_S1

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    ord = order(t, 1)
    entry_ord = order(t0, 1)

    /* Incremental risk-set sums */
    risk_S0 = 0
    risk_S1 = J(1, p, 0)
    risk_S2 = J(p, p, 0)
    ep = 1

    score = J(p, 1, 0)
    info = J(p, p, 0)
    bwd_s0_raw = 0
    bwd_s1_raw = J(1, p, 0)
    bwd_s2_raw = J(p, p, 0)

    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries */
        while (ep <= n) {
            if (t0[entry_ord[ep]] > cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                risk_S0 = risk_S0 + expeta[idx]
                risk_S1 = risk_S1 + expeta[idx] * Z[idx, .]
                risk_S2 = risk_S2 + expeta[idx] * (Z[idx, .]' * Z[idx, .])
            }
            ep++
        }

        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }

        /* Process cause events at this time */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                S0_total = risk_S0 + G[idx] * bwd_s0_raw
                S1_total = risk_S1 + G[idx] * bwd_s1_raw
                S2_total = risk_S2 + G[idx] * bwd_s2_raw

                z_bar = S1_total / S0_total

                score = score + (Z[idx, .] - z_bar)'
                info = info + S2_total / S0_total - z_bar' * z_bar
            }
        }

        /* Add competing events to backward */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                bwd_s0_raw = bwd_s0_raw + expeta[idx] / G[idx]
                bwd_s1_raw = bwd_s1_raw + expeta[idx] / G[idx] * Z[idx, .]
                bwd_s2_raw = bwd_s2_raw + expeta[idx] / G[idx] *
                    (Z[idx, .]' * Z[idx, .])
            }
        }

        /* Remove exiting subjects */
        for (k = i; k < j; k++) {
            idx = ord[k]
            risk_S0 = risk_S0 - expeta[idx]
            risk_S1 = risk_S1 - expeta[idx] * Z[idx, .]
            risk_S2 = risk_S2 - expeta[idx] * (Z[idx, .]' * Z[idx, .])
        }

        i = j
    }
}

/* Robust (sandwich) variance estimator with left truncation support */
real matrix _finegray_robust_var(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real matrix info_inv,
    string scalar clust_var,
    real colvector clust_id,
    real colvector t0)
{
    real scalar n, p, i, j, k, idx, bwd_s0_raw, running_invS0
    real scalar S0_t, use_cluster, cur_time, risk_S0, ep
    real scalar running_ginvS0, total_ginvS0
    real colvector eta, expeta, is_cause, is_compete, ord, entry_ord
    real colvector cum_invS0, cum_ginvS0, clev, sel
    real matrix scores, cum_zbars, cum_gzbars, meat, clust_scores
    real rowvector bwd_s1_raw, running_zbar_sum, z_bar_t, S1_t, risk_S1
    real rowvector running_gzbars, total_gzbars

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    ord = order(t, 1)
    entry_ord = order(t0, 1)

    /* Incremental risk-set sums */
    risk_S0 = 0
    risk_S1 = J(1, p, 0)
    ep = 1

    /* Compute individual score residuals */
    scores = J(n, p, 0)
    bwd_s0_raw = 0
    bwd_s1_raw = J(1, p, 0)
    cum_zbars = J(n, p, 0)
    cum_invS0 = J(n, 1, 0)
    running_invS0 = 0
    running_zbar_sum = J(1, p, 0)

    /* G-weighted cumulative sums for IPCW at-risk correction */
    cum_ginvS0 = J(n, 1, 0)
    cum_gzbars = J(n, p, 0)
    running_ginvS0 = 0
    running_gzbars = J(1, p, 0)

    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries */
        while (ep <= n) {
            if (t0[entry_ord[ep]] > cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                risk_S0 = risk_S0 + expeta[idx]
                risk_S1 = risk_S1 + expeta[idx] * Z[idx, .]
            }
            ep++
        }

        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }

        /* Process cause events */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                S0_t = risk_S0 + G[idx] * bwd_s0_raw
                S1_t = risk_S1 + G[idx] * bwd_s1_raw
                z_bar_t = S1_t / S0_t

                scores[idx, .] = Z[idx, .] - z_bar_t
                running_invS0 = running_invS0 + 1 / S0_t
                running_zbar_sum = running_zbar_sum + z_bar_t / S0_t
                running_ginvS0 = running_ginvS0 + G[idx] / S0_t
                running_gzbars = running_gzbars + G[idx] * z_bar_t / S0_t
            }
        }

        /* Assign cumulative terms to all obs at this time */
        for (k = i; k < j; k++) {
            idx = ord[k]
            cum_invS0[idx] = running_invS0
            cum_zbars[idx, .] = running_zbar_sum
            cum_ginvS0[idx] = running_ginvS0
            cum_gzbars[idx, .] = running_gzbars
        }

        /* Add competing events to backward */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                bwd_s0_raw = bwd_s0_raw + expeta[idx] / G[idx]
                bwd_s1_raw = bwd_s1_raw + expeta[idx] / G[idx] * Z[idx, .]
            }
        }

        /* Remove exiting subjects */
        for (k = i; k < j; k++) {
            idx = ord[k]
            risk_S0 = risk_S0 - expeta[idx]
            risk_S1 = risk_S1 - expeta[idx] * Z[idx, .]
        }

        i = j
    }

    /* Subtract the at-risk contribution for all subjects */
    for (i = 1; i <= n; i++) {
        scores[i, .] = scores[i, .] - expeta[i] *
            (Z[i, .] * cum_invS0[i] - cum_zbars[i, .])
    }

    /* IPCW at-risk correction for competing event subjects.
       Competing events stay in the risk set after their event time
       with weight G(T_j)/G(T_i). The at-risk subtraction above only
       covers times up to T_i (weight=1). This adds the IPCW-weighted
       contribution from cause events after T_i. */
    total_ginvS0 = running_ginvS0
    total_gzbars = running_gzbars
    for (i = 1; i <= n; i++) {
        if (is_compete[i]) {
            scores[i, .] = scores[i, .] -
                (expeta[i] / G[i]) *
                (Z[i, .] * (total_ginvS0 - cum_ginvS0[i]) -
                 (total_gzbars - cum_gzbars[i, .]))
        }
    }

    /* Compute meat */
    use_cluster = (clust_var != "" & rows(clust_id) == n)
    if (use_cluster) {
        clev = uniqrows(clust_id)
        clust_scores = J(rows(clev), p, 0)
        for (i = 1; i <= rows(clev); i++) {
            sel = selectindex(clust_id :== clev[i])
            clust_scores[i, .] = colsum(scores[sel, .])
        }
        meat = clust_scores' * clust_scores
    }
    else {
        meat = scores' * scores
    }

    return(info_inv * meat * info_inv)
}

/* Compute baseline cumulative subhazard (with left truncation) */
real matrix _finegray_basehazard(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real colvector t0)
{
    real scalar n, p, i, j, k, idx, bwd_s0_raw, cum_bh
    real scalar n_events, ev_idx, S0_t, cur_time, risk_S0, ep
    real colvector eta, expeta, is_cause, is_compete, ord, entry_ord
    real matrix result

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    ord = order(t, 1)
    entry_ord = order(t0, 1)

    risk_S0 = 0
    ep = 1

    n_events = sum(is_cause)
    result = J(n_events, 2, .)

    bwd_s0_raw = 0
    cum_bh = 0
    ev_idx = 0

    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries */
        while (ep <= n) {
            if (t0[entry_ord[ep]] > cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                risk_S0 = risk_S0 + expeta[idx]
            }
            ep++
        }

        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }

        /* Process cause events - accumulate baseline hazard */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                S0_t = risk_S0 + G[idx] * bwd_s0_raw
                cum_bh = cum_bh + 1 / S0_t
                ev_idx++
                result[ev_idx, 1] = t[idx]
                result[ev_idx, 2] = cum_bh
            }
        }

        /* Add competing events to backward */
        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                bwd_s0_raw = bwd_s0_raw + expeta[idx] / G[idx]
            }
        }

        /* Remove exiting subjects */
        for (k = i; k < j; k++) {
            risk_S0 = risk_S0 - expeta[ord[k]]
        }

        i = j
    }

    return(result)
}

/* Schoenfeld residuals at each cause-event time (with left truncation).
   Returns n_fail x (p+1) matrix: [time, resid_1, ..., resid_p]
   Optionally scales by diag(info_inv) for Grambsch-Therneau test. */
real matrix _finegray_schoenfeld(
    real colvector t,
    real colvector delta,
    real scalar cause,
    real scalar censval,
    real colvector event_type,
    real matrix Z,
    real colvector beta,
    real colvector G,
    real scalar do_scale,
    real colvector t0)
{
    real scalar n, p, i, j, k, idx, bwd_s0_raw, S0_total, cur_time
    real scalar ev_idx, n_events, risk_S0, ep
    real colvector eta, expeta, is_cause, is_compete, ord, entry_ord, score_vec
    real colvector row_id
    real matrix result, info_mat, risk_S1_mat
    real rowvector bwd_s1_raw, S1_total, z_bar, risk_S1

    n = rows(t)
    p = cols(Z)

    eta = Z * beta
    expeta = exp(eta)
    is_cause = (event_type :== cause) :& (delta :== 1)
    is_compete = (event_type :!= cause) :& (event_type :!= censval) :& (delta :== 1)

    /* Stable sort by t, breaking ties by row index.
       Mata's order() is not stable, so tied event times get an
       arbitrary ordering that may not match finegray_predict's
       assignment sort (_t _obs_id).  Adding the row index as
       a secondary key forces a deterministic tie-break. */
    row_id = (1::n)
    ord = order((t, row_id), (1, 1))
    entry_ord = order((t0, row_id), (1, 1))

    risk_S0 = 0
    risk_S1 = J(1, p, 0)
    ep = 1

    n_events = sum(is_cause)
    result = J(n_events, p + 1, .)

    bwd_s0_raw = 0
    bwd_s1_raw = J(1, p, 0)
    ev_idx = 0

    i = 1
    while (i <= n) {
        cur_time = t[ord[i]]

        /* Add entries */
        while (ep <= n) {
            if (t0[entry_ord[ep]] > cur_time) break
            idx = entry_ord[ep]
            if (t[idx] >= cur_time) {
                risk_S0 = risk_S0 + expeta[idx]
                risk_S1 = risk_S1 + expeta[idx] * Z[idx, .]
            }
            ep++
        }

        j = i
        while (j <= n) {
            if (t[ord[j]] != cur_time) break
            j++
        }

        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_cause[idx]) {
                S0_total = risk_S0 + G[idx] * bwd_s0_raw
                S1_total = risk_S1 + G[idx] * bwd_s1_raw
                z_bar = S1_total / S0_total

                ev_idx++
                result[ev_idx, 1] = t[idx]
                result[ev_idx, 2..p+1] = Z[idx, .] - z_bar
            }
        }

        for (k = i; k < j; k++) {
            idx = ord[k]
            if (is_compete[idx]) {
                bwd_s0_raw = bwd_s0_raw + expeta[idx] / G[idx]
                bwd_s1_raw = bwd_s1_raw + expeta[idx] / G[idx] * Z[idx, .]
            }
        }

        /* Remove exiting subjects */
        for (k = i; k < j; k++) {
            idx = ord[k]
            risk_S0 = risk_S0 - expeta[idx]
            risk_S1 = risk_S1 - expeta[idx] * Z[idx, .]
        }

        i = j
    }

    /* Grambsch-Therneau scaling: multiply by diag(V) */
    if (do_scale & n_events > 0) {
        _finegray_score_info(t, delta, cause, censval, event_type,
            Z, beta, G, score_vec, info_mat, t0)
        real matrix info_inv
        info_inv = invsym(info_mat)
        if (missing(info_inv[1,1])) {
            info_inv = invsym(info_mat + 1e-6 * I(p))
        }
        for (k = 1; k <= p; k++) {
            result[., k+1] = result[., k+1] * info_inv[k, k]
        }
    }

    return(result)
}

/* Compute Schoenfeld residuals from stored e() results and post to Stata */
void _finegray_schoenfeld_compute(
    string scalar varlist_str,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    real scalar do_scale)
{
    real colvector t, delta, event_type, G, byg_id, beta, t0
    real matrix Z, sch
    string rowvector vars
    real scalar p

    vars = tokens(varlist_str)
    p = length(vars)

    Z = st_data(., vars)
    t = st_data(., "_t")
    delta = st_data(., "_d")
    event_type = st_data(., events_str)
    t0 = st_data(., "_t0")

    beta = st_matrix("e(b)")'

    if (byg_str != "") {
        byg_id = st_data(., byg_str)
    }
    else {
        byg_id = J(rows(t), 1, 1)
    }

    G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0)

    sch = _finegray_schoenfeld(t, delta, cause, censval, event_type,
        Z, beta, G, do_scale, t0)

    st_matrix("_finegray_schoenfeld", sch)
}

/* Main engine: Newton-Raphson with step halving */
void _finegray_engine(
    string scalar varlist_str,
    string scalar events_str,
    real scalar cause,
    real scalar censval,
    string scalar byg_str,
    string scalar vce_type,
    string scalar clust_str,
    real scalar max_iter,
    real scalar tol,
    real scalar show_log)
{
    real colvector t, delta, event_type, G, byg_id, t0
    real matrix Z, V, bh
    real colvector beta, beta_new, score_vec, step, clust_id
    real matrix info_mat, info_inv
    real scalar n, p, ll, ll_new, ll_0, converged, iter
    real scalar step_scale, halving, max_halvings, chi2, df_m
    string rowvector vars

    /* Read data */
    vars = tokens(varlist_str)
    p = length(vars)

    Z = st_data(., vars)
    t = st_data(., "_t")
    delta = st_data(., "_d")
    event_type = st_data(., events_str)
    t0 = st_data(., "_t0")
    n = rows(t)

    /* Read byg variable if specified */
    if (byg_str != "") {
        byg_id = st_data(., byg_str)
    }
    else {
        byg_id = J(n, 1, 1)
    }

    /* Compute censoring distribution */
    G = _finegray_km_censor(t, delta, censval, event_type, byg_id, t0)

    /* Starting values: zeros */
    beta = J(p, 1, 0)

    /* Null log-likelihood */
    ll_0 = _finegray_loglik(t, delta, cause, censval, event_type, Z,
        J(p, 1, 0), G, t0)
    ll = ll_0

    if (show_log) {
        printf("{txt}Iteration 0: log pseudo-likelihood = {res}%12.6f\n", ll)
    }

    converged = 0
    max_halvings = 20

    for (iter = 1; iter <= max_iter; iter++) {
        /* Score and information */
        _finegray_score_info(t, delta, cause, censval, event_type,
            Z, beta, G, score_vec, info_mat, t0)

        /* Newton-Raphson step */
        info_inv = invsym(info_mat)
        if (missing(info_inv[1,1])) {
            info_inv = invsym(info_mat + 0.001 * I(p))
            if (missing(info_inv[1,1])) {
                errprintf("information matrix is singular\n")
                exit(error(498))
            }
        }

        step = info_inv * score_vec

        /* Step halving */
        step_scale = 1
        ll_new = .
        for (halving = 1; halving <= max_halvings; halving++) {
            beta_new = beta + step_scale * step
            ll_new = _finegray_loglik(t, delta, cause, censval,
                event_type, Z, beta_new, G, t0)

            if (ll_new > ll) break
            step_scale = step_scale / 2
        }

        /* If no improving step found, flag nonconvergence and stop */
        if (ll_new <= ll) {
            if (show_log) {
                printf("{txt}Iteration %g: step halving failed;" +
                    " no improving step found\n", iter)
            }
            break
        }

        if (show_log) {
            printf("{txt}Iteration %g: log pseudo-likelihood = {res}%12.6f\n",
                iter, ll_new)
        }

        /* Check convergence */
        if (abs(ll_new - ll) < tol & max(abs(beta_new - beta)) < sqrt(tol)) {
            converged = 1
            beta = beta_new
            ll = ll_new
            break
        }

        beta = beta_new
        ll = ll_new
    }

    if (!converged & show_log) {
        printf("{err}Warning: did not converge in %g iterations\n", max_iter)
    }

    /* Final information for variance */
    _finegray_score_info(t, delta, cause, censval, event_type,
        Z, beta, G, score_vec, info_mat, t0)
    info_inv = invsym(info_mat)
    if (missing(info_inv[1,1])) {
        errprintf("Warning: information matrix is singular at solution; " +
            "standard errors may be unreliable\n")
        info_inv = invsym(info_mat + 1e-6 * I(p))
    }

    /* Variance estimation */
    if (vce_type == "robust" | vce_type == "cluster") {
        if (vce_type == "cluster") {
            clust_id = st_data(., clust_str)
            real scalar n_clust
            n_clust = rows(uniqrows(clust_id))
            if (n_clust < p + 1) {
                printf("{err}Warning: number of clusters (%g) < " +
                    "number of parameters + 1 (%g);" +
                    " clustered SEs may be unreliable\n",
                    n_clust, p + 1)
            }
        }
        else {
            clust_id = J(n, 1, .)
        }
        V = _finegray_robust_var(t, delta, cause, censval, event_type,
            Z, beta, G, info_inv, clust_str, clust_id, t0)
    }
    else {
        V = info_inv
    }

    /* Compute baseline hazard */
    bh = _finegray_basehazard(t, delta, cause, censval, event_type,
        Z, beta, G, t0)

    /* Model chi2: df_m = rank of V (excludes omitted/collinear terms) */
    real scalar k, rank
    rank = 0
    for (k = 1; k <= p; k++) {
        if (V[k, k] > 0) rank++
    }
    df_m = rank
    chi2 = beta' * invsym(V) * beta

    /* Post results to Stata matrices */
    st_matrix("_finegray_b", beta')
    st_matrix("_finegray_V", V)
    st_matrix("_finegray_basehaz", bh)
    st_matrixcolstripe("_finegray_basehaz", (J(2,1,""), ("time" \ "cumhazard")))
    st_matrix("_finegray_ll", ll)
    st_matrix("_finegray_ll_0", ll_0)
    st_matrix("_finegray_chi2", chi2)
    st_matrix("_finegray_df_m", df_m)
    st_matrix("_finegray_conv", converged)
}

/* Step function lookup via binary search: O(n log n_bh) instead of O(n * n_bh).
   For each observation in the touse sample, finds the largest basehaz time <= t
   and assigns the corresponding cumulative hazard to H0var. */
void _finegray_step_lookup(
    string scalar bh_matname,
    string scalar tvar,
    string scalar H0var,
    string scalar tousevar)
{
    real matrix bh
    real colvector times, H0, touse_vec, sel
    real scalar i, lo, hi, mid, n_bh, n_sel

    bh = st_matrix(bh_matname)
    n_bh = rows(bh)

    touse_vec = st_data(., tousevar)
    sel = selectindex(touse_vec)
    n_sel = length(sel)

    times = st_data(sel, tvar)
    H0 = J(n_sel, 1, 0)

    for (i = 1; i <= n_sel; i++) {
        if (times[i] >= .) continue
        lo = 1
        hi = n_bh
        while (lo <= hi) {
            mid = trunc((lo + hi) / 2)
            if (bh[mid, 1] <= times[i]) lo = mid + 1
            else hi = mid - 1
        }
        if (hi >= 1) H0[i] = bh[hi, 2]
    }

    st_store(sel, H0var, H0)
}

/* Assign Schoenfeld residuals from matrix to variables via index lookup.
   O(N) instead of O(N * n_fail) from forvalues replace-if loops.
   ccvar holds cumulative cause-event index (1..n_fail) for cause events,
   missing for non-events. varnames are the target variable names. */
void _finegray_assign_schoenfeld_vars(
    string scalar matname,
    string scalar ccvar,
    string rowvector varnames,
    real scalar p)
{
    real matrix sch
    real colvector cc, vals
    real scalar i, n, col

    sch = st_matrix(matname)
    cc = st_data(., ccvar)
    n = rows(cc)

    for (col = 1; col <= p; col++) {
        vals = J(n, 1, .)
        for (i = 1; i <= n; i++) {
            if (cc[i] < . & cc[i] >= 1) {
                vals[i] = sch[cc[i], col + 1]
            }
        }
        st_store(., varnames[col], vals)
    }
}

end
