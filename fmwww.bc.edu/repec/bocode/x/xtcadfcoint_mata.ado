*! xtcadfcoint_mata.ado — Mata engine for xtcadfcoint
*! Implements Banerjee & Carrion-i-Silvestre (2025, JBES)
*! "Panel Data Cointegration Testing with Structural Instabilities"
*! Translated from GAUSS code: cadfcoin_multiple.src
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! Version 1.0.1 — 14 February 2026 (audited against GAUSS)

version 14.0

mata:
mata set matastrict off

// ========================================================================
// FUNCTION: _bcs_cadfcoin_main()
// Core procedure — direct translation of CADFcoin_multiple() from GAUSS
//
// Input:
//   Y       : T x N matrix of dependent variable
//   X       : T x (N*k) matrix of regressors (horizontal concatenation)
//   model   : 0-5 deterministic specification
//   Tb      : m x 1 vector of break dates (0 = no break)
//   brk_slope    : 1 = breaks change slope params, 0 = constant
//   brk_loadings : 1 = breaks change factor loadings, 0 = constant
//   num_factors  : number of common factors
//   p_max   : max lag order for CADF augmentation
//   opt_auto : 1 = automatic lag selection, 0 = fixed
//   opt_ic   : 0=AIC, 1=BIC, 2=MAIC, 3=MBIC
//   opt_CCE  : 1 = use CCE, 0 = no CCE
//
// Output:
//   beta_ccep    : k*(m+1) x 1 pooled CCE estimator
//   SSR_resid    : 4 x 1 vector of SSR values
//   panel_t_cadf : scalar panel CIPS statistic
//   t_cadf       : N x 1 individual t-statistics
//   p_est        : N x 1 estimated lag orders
// ========================================================================

void _bcs_cadfcoin_main(
    real matrix Y,
    real matrix X,
    real scalar model,
    real colvector Tb,
    real scalar brk_slope,
    real scalar brk_loadings,
    real scalar num_factors,
    real scalar p_max,
    real scalar opt_auto,
    real scalar opt_ic,
    real scalar opt_CCE,
    real colvector beta_ccep,
    real colvector SSR_resid,
    real scalar panel_t_cadf,
    real colvector t_cadf,
    real colvector p_est)
{
    real scalar TT, N, k, n_br, i, ii
    real matrix x_deter, DU, DT, M_bar, H_bar
    real matrix x_cross_average, mat_cross_average
    real colvector y_cross_average
    real matrix EG_resid, EG_resid_detrended, EG_resid_defacdet
    real matrix DEG_resid_defacdet, DEG_resid_detrended
    real colvector y_temp
    real matrix x_temp, x_temp_brk
    real matrix beta_ccep_num, beta_ccep_den
    real scalar SSR_DEG_dt, SSR_EG_dt, SSR_DEG_df, SSR_EG_df

    TT = rows(Y)
    N  = cols(Y)
    k  = cols(X) / N

    // --- Number of structural breaks ---
    n_br = rows(Tb)
    if (n_br == 1 & Tb[1] == 0) n_br = 0

    // --- Build dummy variables ---
    // GAUSS: lines 313-329
    if (n_br > 0) {
        if (model >= 3 | brk_slope == 1 | brk_loadings == 1) {
            DU = J(TT, n_br, 0)
            DT = J(TT, n_br, 0)
            for (i = 1; i <= n_br; i++) {
                DU[., i] = (J(Tb[i], 1, 0) \ J(TT - Tb[i], 1, 1))
                DT[., i] = (J(Tb[i], 1, 0) \ range(1, TT - Tb[i], 1))
            }
        }
    }

    // --- Build deterministic component ---
    // GAUSS: lines 336-356
    if (model == 0) {
        x_deter = J(0, 0, .)  // empty — no deterministic
    }
    else if (model == 1) {
        x_deter = J(TT, 1, 1)
    }
    else if (model == 2) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1))
    }
    else if (model == 3) {
        x_deter = (J(TT, 1, 1), DU)
    }
    else if (model == 4) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1), DU)
    }
    else if (model == 5) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1), DU, DT)
    }

    // --- Build projection matrix M_bar ---
    // GAUSS: lines 359-421
    if (opt_CCE == 0) {
        // No CCE — project out deterministics only
        if (model == 0) {
            M_bar = I(TT)
        }
        else {
            H_bar = x_deter
            M_bar = I(TT) - H_bar * invsym(H_bar' * H_bar) * H_bar'
        }
    }
    else {
        // CCE: compute cross-section averages
        // GAUSS: meanc(x[.,1:N]') gives T x 1 column of row means
        x_cross_average = mean(X[., 1::N]')'

        for (i = 2; i <= k; i++) {
            x_cross_average = (x_cross_average, mean(X[., ((i-1)*N+1)::(i*N)]')')
        }

        y_cross_average = mean(Y')'

        mat_cross_average = (y_cross_average, x_cross_average)

        // Build H_bar
        // GAUSS: lines 393-417
        if (brk_loadings == 0) {
            if (model == 0) {
                H_bar = mat_cross_average
            }
            else {
                H_bar = (x_deter, mat_cross_average)
            }
        }
        else {
            // Loadings change with breaks
            H_bar = mat_cross_average
            for (i = 1; i <= n_br; i++) {
                H_bar = (H_bar, DU[., i] :* mat_cross_average)
            }
            if (model > 0) {
                H_bar = (x_deter, H_bar)
            }
        }

        M_bar = I(TT) - H_bar * invsym(H_bar' * H_bar) * H_bar'
    }

    // --- Pooled CCE estimator ---
    // GAUSS: lines 427-457
    if (brk_slope == 0) {
        beta_ccep_num = J(k, 1, 0)
        beta_ccep_den = J(k, k, 0)
    }
    else {
        beta_ccep_num = J(k * (n_br + 1), 1, 0)
        beta_ccep_den = J(k * (n_br + 1), k * (n_br + 1), 0)
    }

    for (i = 1; i <= N; i++) {
        y_temp = Y[., i]

        // Extract columns for unit i: GAUSS seqa(i, N, k) -> i, i+N, i+2N, ...
        x_temp = J(TT, 0, .)
        for (ii = 0; ii < k; ii++) {
            x_temp = (x_temp, X[., i + ii * N])
        }

        if (brk_slope == 1) {
            x_temp_brk = x_temp
            for (ii = 1; ii <= n_br; ii++) {
                x_temp_brk = (x_temp_brk, DU[., ii] :* x_temp)
            }
            x_temp = x_temp_brk
        }

        beta_ccep_den = beta_ccep_den + x_temp' * M_bar * x_temp
        beta_ccep_num = beta_ccep_num + x_temp' * M_bar * y_temp
    }

    beta_ccep = invsym(beta_ccep_den) * beta_ccep_num

    // --- Compute residuals ---
    // GAUSS: lines 463-504
    EG_resid          = J(TT, N, 0)
    EG_resid_detrended = J(TT, N, 0)
    EG_resid_defacdet  = J(TT, N, 0)

    for (i = 1; i <= N; i++) {
        y_temp = Y[., i]
        x_temp = J(TT, 0, .)
        for (ii = 0; ii < k; ii++) {
            x_temp = (x_temp, X[., i + ii * N])
        }

        if (brk_slope == 1) {
            x_temp_brk = x_temp
            for (ii = 1; ii <= n_br; ii++) {
                x_temp_brk = (x_temp_brk, DU[., ii] :* x_temp)
            }
            x_temp = x_temp_brk
        }

        EG_resid[., i] = y_temp - x_temp * beta_ccep

        if (model == 0) {
            EG_resid_detrended[., i] = EG_resid[., i]
        }
        else {
            // GAUSS: EG_resid-x_deter*(EG_resid/x_deter) — OLS detrending
            EG_resid_detrended[., i] = EG_resid[., i] - x_deter * (invsym(x_deter' * x_deter) * (x_deter' * EG_resid[., i]))
        }

        EG_resid_defacdet[., i] = M_bar * EG_resid[., i]
    }

    // SSR computations
    // GAUSS: sumc(diag(X'X)) = sum of diagonal = trace(X'X) = sum of all squared elements
    DEG_resid_defacdet  = EG_resid_defacdet[2::TT, .] - EG_resid_defacdet[1::(TT-1), .]
    DEG_resid_detrended = EG_resid_detrended[2::TT, .] - EG_resid_detrended[1::(TT-1), .]

    SSR_DEG_dt = sum(diagonal(DEG_resid_detrended' * DEG_resid_detrended))
    SSR_EG_dt  = sum(diagonal(EG_resid_detrended' * EG_resid_detrended))
    SSR_DEG_df = sum(diagonal(DEG_resid_defacdet' * DEG_resid_defacdet))
    SSR_EG_df  = sum(diagonal(EG_resid_defacdet' * EG_resid_defacdet))

    // GAUSS order: SSR_EG_defacdet | SSR_EG_detrended | SSR_DEG_defacdet | SSR_DEG_detrended
    SSR_resid = (SSR_EG_df \ SSR_EG_dt \ SSR_DEG_df \ SSR_DEG_dt)

    // --- Run CADF or ADF on residuals ---
    // GAUSS: lines 506-514
    if (opt_CCE == 0) {
        _bcs_adf_test(EG_resid, model, Tb, p_max, opt_auto, opt_ic,
                       t_cadf, p_est)
    }
    else {
        _bcs_cadf_test(EG_resid, x_cross_average, model, Tb,
                        brk_loadings, num_factors, p_max, opt_auto, opt_ic,
                        t_cadf, p_est)
    }

    panel_t_cadf = mean(t_cadf)
}


// ========================================================================
// FUNCTION: _bcs_cadf_test()
// Individual CADF cointegration statistics — translation of cadf_multiple()
// GAUSS: lines 574-803
//
// AUDIT NOTE: GAUSS uses original T (not effective T after trimming)
// in the denominator of s2 and IC formulas. Matched exactly.
// ========================================================================

void _bcs_cadf_test(
    real matrix EG_resid,
    real matrix x_cross_average,
    real scalar model,
    real colvector Tb,
    real scalar brk_loadings,
    real scalar num_factors,
    real scalar p_max,
    real scalar opt_auto,
    real scalar opt_ic,
    real colvector t_cadf,
    real colvector p_est)
{
    real scalar N, TT, k, n_br, i, ii, i_p, p_sel
    real matrix x_deter, DU, DT, DTb
    real colvector EG_resid_crossmean, DEG_resid_crossmean
    real colvector EG_resid_crossmean_lag
    real matrix DEG_resid, EG_resid_lag
    real matrix EG_resid_crossmean_lag_terms, DEG_resid_crossmean_terms
    real matrix Dx_cross_average, x_cross_average_lag
    real colvector y_temp, y_temp_orig, bhat, resid_vec
    real matrix x_temp, x_temp_orig, lagged_terms, var_bhat
    real scalar s2, tau, ic_val, best_ic
    real colvector t_ratio

    N  = cols(EG_resid)
    TT = rows(EG_resid)
    k  = cols(x_cross_average)

    n_br = rows(Tb)
    if (n_br == 1 & Tb[1] == 0) n_br = 0

    // --- Build dummies ---
    // GAUSS: lines 586-602 (adds DTb impulse dummies for CADF)
    if (n_br > 0) {
        if (model >= 3 | brk_loadings == 1) {
            DTb = J(TT, n_br, 0)
            DU  = J(TT, n_br, 0)
            DT  = J(TT, n_br, 0)
            for (i = 1; i <= n_br; i++) {
                DTb[Tb[i] + 1, i] = 1
                DU[., i] = (J(Tb[i], 1, 0) \ J(TT - Tb[i], 1, 1))
                DT[., i] = (J(Tb[i], 1, 0) \ range(1, TT - Tb[i], 1))
            }
        }
    }

    // --- Build deterministics (with impulse dummies DTb for models 3-5) ---
    // GAUSS: lines 606-626
    if (model == 0) {
        x_deter = J(0, 0, .)
    }
    else if (model == 1) {
        x_deter = J(TT, 1, 1)
    }
    else if (model == 2) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1))
    }
    else if (model == 3) {
        x_deter = (J(TT, 1, 1), DU, DTb)
    }
    else if (model == 4) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1), DU, DTb)
    }
    else if (model == 5) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1), DU, DT, DTb)
    }

    // --- Handle multiple factors ---
    // GAUSS: lines 629-646
    if (num_factors > 1) {
        if (num_factors > k + 1) {
            // rank condition not satisfied, keep all
        }
        else {
            x_cross_average = x_cross_average[., 1::(num_factors - 1)]
        }
        // GAUSS: Dx_cross_average=x_cross_average-lag(x_cross_average)
        Dx_cross_average    = x_cross_average[2::TT, .] - x_cross_average[1::(TT-1), .]
        x_cross_average_lag = (J(1, cols(x_cross_average), .) \ x_cross_average[1::(TT-1), .])
    }

    t_cadf = J(N, 1, .)
    p_est  = J(N, 1, 0)

    // Cross-section mean of residuals
    // GAUSS: meanc(EG_resid') — row means as column vector
    EG_resid_crossmean     = mean(EG_resid')'
    DEG_resid              = EG_resid[2::TT, .] - EG_resid[1::(TT-1), .]
    DEG_resid_crossmean    = mean(DEG_resid')'

    // Lagged cross-section mean
    EG_resid_lag            = (J(1, N, .) \ EG_resid[1::(TT-1), .])
    EG_resid_crossmean_lag  = (. \ EG_resid_crossmean[1::(TT-1)])

    // Build cross-section average terms
    // GAUSS: lines 661-676
    if (num_factors == 1) {
        EG_resid_crossmean_lag_terms = EG_resid_crossmean_lag[2::TT]
        DEG_resid_crossmean_terms    = DEG_resid_crossmean
    }
    else {
        EG_resid_crossmean_lag_terms = (EG_resid_crossmean_lag[2::TT], x_cross_average_lag[2::TT, .])
        DEG_resid_crossmean_terms    = (DEG_resid_crossmean, Dx_cross_average)
    }

    // Breaks affect loadings
    // GAUSS: lines 669-676
    if (brk_loadings == 1 & n_br > 0) {
        for (i = 1; i <= n_br; i++) {
            EG_resid_crossmean_lag_terms = (EG_resid_crossmean_lag_terms,
                DU[2::TT, i] :* EG_resid_crossmean_lag[2::TT])
            DEG_resid_crossmean_terms = (DEG_resid_crossmean_terms,
                DU[2::TT, i] :* DEG_resid_crossmean)
        }
    }

    // --- CADF regression for each unit ---
    // GAUSS: lines 681-799
    for (i = 1; i <= N; i++) {
        y_temp = DEG_resid[., i]  // T-1 x 1 (starts at t=2)

        if (model == 0) {
            x_temp = (EG_resid_lag[2::TT, i], EG_resid_crossmean_lag_terms, DEG_resid_crossmean_terms)
        }
        else {
            x_temp = (EG_resid_lag[2::TT, i], EG_resid_crossmean_lag_terms, DEG_resid_crossmean_terms, x_deter[2::TT, .])
        }

        if (opt_auto == 0) {
            // Fixed lag order
            // GAUSS: lines 692-740
            if (p_max > 0) {
                lagged_terms = J(TT - 1, 0, .)
                for (ii = 1; ii <= p_max; ii++) {
                    lagged_terms = (lagged_terms, _bcs_lagn(y_temp, ii))
                    lagged_terms = (lagged_terms, _bcs_lagn_mat(DEG_resid_crossmean_terms, ii))
                }
                y_temp = y_temp[(p_max + 1)::rows(y_temp)]
                x_temp = (x_temp, lagged_terms)[(p_max + 1)::rows(x_temp), .]
            }

            bhat = invsym(x_temp' * x_temp) * (x_temp' * y_temp)
            resid_vec = y_temp - x_temp * bhat
            // GAUSS uses T in denominator (line 712, 735): s2=resid'resid/(T-cols(x_temp))
            s2 = (resid_vec' * resid_vec) / (TT - cols(x_temp))
            var_bhat = s2 * invsym(x_temp' * x_temp)
            t_cadf[i] = bhat[1] / sqrt(var_bhat[1, 1])
            p_est[i]  = p_max
        }
        else {
            // Automatic lag selection
            // GAUSS: lines 742-796
            y_temp_orig = y_temp
            x_temp_orig = x_temp
            best_ic = .
            p_sel   = 0

            for (i_p = p_max; i_p >= 0; i_p--) {
                y_temp = y_temp_orig
                x_temp = x_temp_orig

                if (i_p > 0) {
                    lagged_terms = J(rows(y_temp), 0, .)
                    for (ii = 1; ii <= i_p; ii++) {
                        lagged_terms = (lagged_terms, _bcs_lagn(y_temp, ii))
                        lagged_terms = (lagged_terms, _bcs_lagn_mat(DEG_resid_crossmean_terms, ii))
                    }
                    // GAUSS: trimr(y_temp, p, 0) — remove p_max rows for comparability
                    y_temp = y_temp[(p_max + 1)::rows(y_temp)]
                    x_temp = (x_temp, lagged_terms)[(p_max + 1)::rows(x_temp), .]
                }
                // GAUSS: when i_p=0, no trimming — uses full (T-1) sample

                bhat = invsym(x_temp' * x_temp) * (x_temp' * y_temp)
                resid_vec = y_temp - x_temp * bhat
                // GAUSS: s2=resid'resid/(T-cols(x_temp)), uses original T
                s2 = (resid_vec' * resid_vec) / (TT - cols(x_temp))
                var_bhat = s2 * invsym(x_temp' * x_temp)
                t_ratio = bhat :/ sqrt(diagonal(var_bhat))

                // Information criteria — GAUSS uses T in denominator
                if (opt_ic == 0) {
                    ic_val = ln(s2) + 2 * cols(x_temp) / TT
                }
                else if (opt_ic == 1) {
                    ic_val = ln(s2) + ln(TT) * cols(x_temp) / TT
                }
                else if (opt_ic == 2) {
                    tau = (bhat[1]^2) * (x_temp[., 1]' * x_temp[., 1]) / (TT^2) / s2
                    ic_val = ln(s2) + 2 * (cols(x_temp) + tau) / TT
                }
                else {
                    tau = (bhat[1]^2) * (x_temp[., 1]' * x_temp[., 1]) / (TT^2) / s2
                    ic_val = ln(s2) + ln(TT) * (cols(x_temp) + tau) / TT
                }

                if (ic_val < best_ic | best_ic == .) {
                    best_ic = ic_val
                    p_sel   = i_p
                    t_cadf[i] = t_ratio[1]
                }
            }
            p_est[i] = p_sel
        }
    }

    panel_t_cadf = mean(t_cadf)
}


// ========================================================================
// FUNCTION: _bcs_adf_test()
// Individual ADF statistics (no CCE) — translation of adf_multiple()
// GAUSS: lines 848-1029
// ========================================================================

void _bcs_adf_test(
    real matrix EG_resid,
    real scalar model,
    real colvector Tb,
    real scalar p_max,
    real scalar opt_auto,
    real scalar opt_ic,
    real colvector t_cadf,
    real colvector p_est)
{
    real scalar N, TT, n_br, i, ii, i_p, p_sel
    real matrix x_deter, DU, DT, DTb
    real matrix DEG_resid, EG_resid_lag
    real colvector y_temp, y_temp_orig, bhat, resid_vec
    real matrix x_temp, x_temp_orig, lagged_terms, var_bhat
    real scalar s2, tau, ic_val, best_ic
    real colvector t_ratio

    N  = cols(EG_resid)
    TT = rows(EG_resid)

    n_br = rows(Tb)
    if (n_br == 1 & Tb[1] == 0) n_br = 0

    if (n_br > 0) {
        if (model >= 3) {
            DTb = J(TT, n_br, 0)
            DU  = J(TT, n_br, 0)
            DT  = J(TT, n_br, 0)
            for (i = 1; i <= n_br; i++) {
                DTb[Tb[i] + 1, i] = 1
                DU[., i] = (J(Tb[i], 1, 0) \ J(TT - Tb[i], 1, 1))
                DT[., i] = (J(Tb[i], 1, 0) \ range(1, TT - Tb[i], 1))
            }
        }
    }

    if (model == 0) {
        x_deter = J(0, 0, .)
    }
    else if (model == 1) {
        x_deter = J(TT, 1, 1)
    }
    else if (model == 2) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1))
    }
    else if (model == 3) {
        x_deter = (J(TT, 1, 1), DU, DTb)
    }
    else if (model == 4) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1), DU, DTb)
    }
    else if (model == 5) {
        x_deter = (J(TT, 1, 1), range(1, TT, 1), DU, DT, DTb)
    }

    t_cadf = J(N, 1, .)
    p_est  = J(N, 1, 0)

    DEG_resid    = EG_resid[2::TT, .] - EG_resid[1::(TT-1), .]
    EG_resid_lag = (J(1, N, .) \ EG_resid[1::(TT-1), .])

    for (i = 1; i <= N; i++) {
        y_temp = DEG_resid[., i]

        if (model == 0) {
            x_temp = EG_resid_lag[2::TT, i]
        }
        else {
            x_temp = (EG_resid_lag[2::TT, i], x_deter[2::TT, .])
        }

        if (opt_auto == 0) {
            if (p_max > 0) {
                lagged_terms = J(TT - 1, 0, .)
                for (ii = 1; ii <= p_max; ii++) {
                    lagged_terms = (lagged_terms, _bcs_lagn(y_temp, ii))
                }
                y_temp = y_temp[(p_max + 1)::rows(y_temp)]
                x_temp = (x_temp, lagged_terms)[(p_max + 1)::rows(x_temp), .]
            }

            bhat = invsym(x_temp' * x_temp) * (x_temp' * y_temp)
            resid_vec = y_temp - x_temp * bhat
            // GAUSS uses T (line 938): s2=resid'resid/(T-cols(x_temp))
            s2 = (resid_vec' * resid_vec) / (TT - cols(x_temp))
            var_bhat = s2 * invsym(x_temp' * x_temp)
            t_cadf[i] = bhat[1] / sqrt(var_bhat[1, 1])
            p_est[i]  = p_max
        }
        else {
            y_temp_orig = y_temp
            x_temp_orig = x_temp
            best_ic = .
            p_sel   = 0

            for (i_p = p_max; i_p >= 0; i_p--) {
                y_temp = y_temp_orig
                x_temp = x_temp_orig

                if (i_p > 0) {
                    lagged_terms = J(rows(y_temp), 0, .)
                    for (ii = 1; ii <= i_p; ii++) {
                        lagged_terms = (lagged_terms, _bcs_lagn(y_temp, ii))
                    }
                    y_temp = y_temp[(p_max + 1)::rows(y_temp)]
                    x_temp = (x_temp, lagged_terms)[(p_max + 1)::rows(x_temp), .]
                }
                // GAUSS: when i_p=0, no trimming — uses full (T-1) sample

                bhat = invsym(x_temp' * x_temp) * (x_temp' * y_temp)
                resid_vec = y_temp - x_temp * bhat
                s2 = (resid_vec' * resid_vec) / (TT - cols(x_temp))
                var_bhat = s2 * invsym(x_temp' * x_temp)
                t_ratio = bhat :/ sqrt(diagonal(var_bhat))

                if (opt_ic == 0) {
                    ic_val = ln(s2) + 2 * cols(x_temp) / TT
                }
                else if (opt_ic == 1) {
                    ic_val = ln(s2) + ln(TT) * cols(x_temp) / TT
                }
                else if (opt_ic == 2) {
                    tau = (bhat[1]^2) * (x_temp[., 1]' * x_temp[., 1]) / (TT^2) / s2
                    ic_val = ln(s2) + 2 * (cols(x_temp) + tau) / TT
                }
                else {
                    tau = (bhat[1]^2) * (x_temp[., 1]' * x_temp[., 1]) / (TT^2) / s2
                    ic_val = ln(s2) + ln(TT) * (cols(x_temp) + tau) / TT
                }

                if (ic_val < best_ic | best_ic == .) {
                    best_ic = ic_val
                    p_sel   = i_p
                    t_cadf[i] = t_ratio[1]
                }
            }
            p_est[i] = p_sel
        }
    }
}


// ========================================================================
// FUNCTION: _bcs_cadfcoin_endog()
// Endogenous break search — translation of CADFcoin_multiple_endog()
// GAUSS: lines 82-229
//
// AUDIT: Now includes model 5 Kim-Perron trim path
// ========================================================================

void _bcs_cadfcoin_endog(
    real matrix Y,
    real matrix X,
    real scalar model,
    real scalar m,
    real scalar trimming,
    real scalar brk_slope,
    real scalar brk_loadings,
    real scalar num_factors,
    real scalar p_max,
    real scalar opt_auto,
    real scalar opt_ic,
    real scalar opt_CCE,
    real colvector beta_ccep,
    real colvector SSR_resid,
    real scalar panel_t_cadf,
    real colvector t_cadf,
    real colvector p_est,
    real colvector Tb_est,
    real scalar panel_t_cadf_alt,
    real colvector beta_ccep_alt,
    real colvector Tb_est_alt,
    real scalar panel_t_cadf_trim,
    real colvector t_cadf_trim,
    real colvector Tb_est_trim)
{
    real scalar TT, N, k, i, ii
    real colvector beta_tmp, SSR_tmp, t_tmp, p_tmp
    real scalar panel_tmp
    real matrix mat_SSR
    real colvector Tb_try
    real scalar best_idx, best_idx_alt

    TT = rows(Y)
    N  = cols(Y)
    k  = cols(X) / N

    // Initialize trim outputs
    panel_t_cadf_trim = .
    t_cadf_trim = J(N, 1, .)
    Tb_est_trim = (0)

    if (m == 0) {
        // No break case — GAUSS lines 91-106
        _bcs_cadfcoin_main(Y, X, model, (0), 0, 0, num_factors,
            p_max, opt_auto, opt_ic, opt_CCE,
            beta_ccep, SSR_resid, panel_t_cadf, t_cadf, p_est)
        Tb_est = (0)
        panel_t_cadf_alt = panel_t_cadf
        beta_ccep_alt = beta_ccep
        Tb_est_alt = (0)
        return
    }

    if (m == 1) {
        // One break — grid search
        // GAUSS: lines 108-160
        mat_SSR = J(0, 5, .)

        for (i = floor(trimming * TT) + 1; i <= TT - floor(trimming * TT); i++) {
            Tb_try = (i)
            _bcs_cadfcoin_main(Y, X, model, Tb_try, brk_slope, brk_loadings,
                num_factors, p_max, opt_auto, opt_ic, opt_CCE,
                beta_tmp, SSR_tmp, panel_tmp, t_tmp, p_tmp)
            mat_SSR = (mat_SSR \ (i, SSR_tmp[1], SSR_tmp[2], SSR_tmp[3], SSR_tmp[4]))
        }

        // Lambda_hat: minimize SSR_EG_defacdet (column 2)
        // GAUSS: minindc(mat_SSR[.,m+1]) where m=1, so column 2
        best_idx = .
        {
            real scalar min_ssr
            min_ssr = .
            for (i = 1; i <= rows(mat_SSR); i++) {
                if (mat_SSR[i, 2] < min_ssr | min_ssr == .) {
                    min_ssr = mat_SSR[i, 2]
                    best_idx = i
                }
            }
        }
        Tb_est = (mat_SSR[best_idx, 1])

        _bcs_cadfcoin_main(Y, X, model, Tb_est, brk_slope, brk_loadings,
            num_factors, p_max, opt_auto, opt_ic, opt_CCE,
            beta_ccep, SSR_resid, panel_t_cadf, t_cadf, p_est)

        // Model 5: Kim-Perron trimmed data
        // GAUSS: lines 128-136
        if (model == 5) {
            real matrix data_combined, data_trimmed
            real colvector Tb_trimmed_kp
            real scalar trm_kp
            real colvector beta_tr, SSR_tr, t_tr, p_tr
            real scalar panel_tr

            trm_kp = 3
            data_combined = (Y, X)
            _bcs_kimperron_trim(data_combined, Tb_est, trm_kp,
                                data_trimmed, Tb_trimmed_kp)

            if (Tb_trimmed_kp[1] == 0) {
                // No break survived trimming — use model 2
                _bcs_cadfcoin_main(
                    data_trimmed[., 1::N],
                    data_trimmed[., (N+1)::cols(data_trimmed)],
                    2, Tb_trimmed_kp, 0, 0, num_factors,
                    p_max, 0, opt_ic, opt_CCE,
                    beta_tr, SSR_tr, panel_tr, t_tr, p_tr)
            }
            else {
                _bcs_cadfcoin_main(
                    data_trimmed[., 1::N],
                    data_trimmed[., (N+1)::cols(data_trimmed)],
                    model, Tb_trimmed_kp, brk_slope, brk_loadings,
                    num_factors, p_max, 0, opt_ic, opt_CCE,
                    beta_tr, SSR_tr, panel_tr, t_tr, p_tr)
            }
            panel_t_cadf_trim = panel_tr
            t_cadf_trim = t_tr
            Tb_est_trim = Tb_trimmed_kp
        }

        // Lambda_tilde: minimize SSR_EG_detrended (column 3)
        // GAUSS: minindc(mat_SSR[.,m+2]) where m=1, so column 3
        best_idx_alt = .
        {
            real scalar min_ssr2
            min_ssr2 = .
            for (i = 1; i <= rows(mat_SSR); i++) {
                if (mat_SSR[i, 3] < min_ssr2 | min_ssr2 == .) {
                    min_ssr2 = mat_SSR[i, 3]
                    best_idx_alt = i
                }
            }
        }
        Tb_est_alt = (mat_SSR[best_idx_alt, 1])

        _bcs_cadfcoin_main(Y, X, model, Tb_est_alt, brk_slope, brk_loadings,
            num_factors, p_max, opt_auto, opt_ic, opt_CCE,
            beta_ccep_alt, SSR_tmp, panel_tmp, t_tmp, p_tmp)
        panel_t_cadf_alt = panel_tmp

        return
    }

    if (m == 2) {
        // Two breaks — double grid search
        // GAUSS: lines 162-218
        mat_SSR = J(0, 6, .)

        for (i = floor(trimming * TT) + 1; i <= TT - 2 * floor(trimming * TT); i++) {
            for (ii = floor(trimming * TT) + i; ii <= TT - floor(trimming * TT); ii++) {
                Tb_try = (i \ ii)
                _bcs_cadfcoin_main(Y, X, model, Tb_try, brk_slope, brk_loadings,
                    num_factors, p_max, opt_auto, opt_ic, opt_CCE,
                    beta_tmp, SSR_tmp, panel_tmp, t_tmp, p_tmp)
                mat_SSR = (mat_SSR \ (i, ii, SSR_tmp[1], SSR_tmp[2], SSR_tmp[3], SSR_tmp[4]))
            }
        }

        // Lambda_hat: minimize SSR_EG_defacdet
        // GAUSS: minindc(mat_SSR[.,m+1]) where m=2, so column 3
        best_idx = .
        {
            real scalar min_ssr3
            min_ssr3 = .
            for (i = 1; i <= rows(mat_SSR); i++) {
                if (mat_SSR[i, 3] < min_ssr3 | min_ssr3 == .) {
                    min_ssr3 = mat_SSR[i, 3]
                    best_idx = i
                }
            }
        }
        Tb_est = (mat_SSR[best_idx, 1] \ mat_SSR[best_idx, 2])

        _bcs_cadfcoin_main(Y, X, model, Tb_est, brk_slope, brk_loadings,
            num_factors, p_max, opt_auto, opt_ic, opt_CCE,
            beta_ccep, SSR_resid, panel_t_cadf, t_cadf, p_est)

        // Model 5: Kim-Perron trimmed data
        if (model == 5) {
            real matrix data_combined2, data_trimmed2
            real colvector Tb_trimmed_kp2
            real scalar trm_kp2
            real colvector beta_tr2, SSR_tr2, t_tr2, p_tr2
            real scalar panel_tr2

            trm_kp2 = 3
            data_combined2 = (Y, X)
            _bcs_kimperron_trim(data_combined2, Tb_est, trm_kp2,
                                data_trimmed2, Tb_trimmed_kp2)

            if (Tb_trimmed_kp2[1] == 0) {
                _bcs_cadfcoin_main(
                    data_trimmed2[., 1::N],
                    data_trimmed2[., (N+1)::cols(data_trimmed2)],
                    2, Tb_trimmed_kp2, 0, 0, num_factors,
                    p_max, 0, opt_ic, opt_CCE,
                    beta_tr2, SSR_tr2, panel_tr2, t_tr2, p_tr2)
            }
            else {
                _bcs_cadfcoin_main(
                    data_trimmed2[., 1::N],
                    data_trimmed2[., (N+1)::cols(data_trimmed2)],
                    model, Tb_trimmed_kp2, brk_slope, brk_loadings,
                    num_factors, p_max, 0, opt_ic, opt_CCE,
                    beta_tr2, SSR_tr2, panel_tr2, t_tr2, p_tr2)
            }
            panel_t_cadf_trim = panel_tr2
            t_cadf_trim = t_tr2
            Tb_est_trim = Tb_trimmed_kp2
        }

        // Lambda_tilde: minimize SSR_EG_detrended
        // GAUSS: minindc(mat_SSR[.,m+2]) where m=2, so column 4
        best_idx_alt = .
        {
            real scalar min_ssr4
            min_ssr4 = .
            for (i = 1; i <= rows(mat_SSR); i++) {
                if (mat_SSR[i, 4] < min_ssr4 | min_ssr4 == .) {
                    min_ssr4 = mat_SSR[i, 4]
                    best_idx_alt = i
                }
            }
        }
        Tb_est_alt = (mat_SSR[best_idx_alt, 1] \ mat_SSR[best_idx_alt, 2])

        _bcs_cadfcoin_main(Y, X, model, Tb_est_alt, brk_slope, brk_loadings,
            num_factors, p_max, opt_auto, opt_ic, opt_CCE,
            beta_ccep_alt, SSR_tmp, panel_tmp, t_tmp, p_tmp)
        panel_t_cadf_alt = panel_tmp

        return
    }
}


// ========================================================================
// FUNCTION: _bcs_kimperron_trim()
// Kim-Perron (2009, JoE) trimmed data — translation of KimPerron_trimdata()
// GAUSS: lines 1063-1150
//
// GAUSS logic:
//   1. Compute Tb_low = Tb - trm, Tb_high = Tb + trm
//   2. Tb_final: missing if out-of-bounds, else stores low/high
//   3. packr(Tb_final) = rows where BOTH low and high are valid ("interior" breaks)
//   4. Tb_low_ind = last break with missing low (break at start of sample)
//   5. Tb_high_ind = first break with missing high (break at end of sample)
//   6. Interior breaks: trim window, compute shift S, store marker
//   7. selif: keep non-discarded obs, find new break positions
// ========================================================================

void _bcs_kimperron_trim(
    real matrix y,
    real colvector Tb,
    real scalar trm,
    real matrix ytrim,
    real colvector Tbtrim)
{
    real scalar TT, N, n_br, i, jj
    real colvector Tb_low, Tb_high
    real matrix Tb_final
    real colvector indica_disc_obs, vec_Tb_trim
    real matrix S, yh
    real scalar Tb_low_ind, Tb_high_ind
    real matrix Tb_final_filtered
    real scalar n_filtered, has_filtered

    TT = rows(y)
    N  = cols(y)
    n_br = rows(Tb)

    // GAUSS: Tb_low=Tb-trm; Tb_high=Tb+trm
    Tb_low  = Tb :- trm
    Tb_high = Tb :+ trm

    // GAUSS: Tb_final=miss(zeros(n_br,2),0) — all missing initially
    Tb_final = J(n_br, 2, .)

    // GAUSS: only fill if within bounds
    for (i = 1; i <= n_br; i++) {
        if (Tb_low[i] > 1)  Tb_final[i, 1] = Tb_low[i]
        if (Tb_high[i] < TT) Tb_final[i, 2] = Tb_high[i]
    }

    // GAUSS: Tb_final_filtered = packr(Tb_final) — keep rows with NO missing
    // Count how many rows have both columns non-missing
    n_filtered = 0
    for (i = 1; i <= n_br; i++) {
        if (Tb_final[i, 1] != . & Tb_final[i, 2] != .) {
            n_filtered++
        }
    }

    if (n_filtered > 0) {
        Tb_final_filtered = J(n_filtered, 2, .)
        jj = 0
        for (i = 1; i <= n_br; i++) {
            if (Tb_final[i, 1] != . & Tb_final[i, 2] != .) {
                jj++
                Tb_final_filtered[jj, .] = Tb_final[i, .]
            }
        }
        has_filtered = 1
    }
    else {
        has_filtered = 0
    }

    // GAUSS: Tb_low_ind = maxc(seqa(1,1,n_br) .* (Tb_final[.,1] .eq miss))
    // maxc of {i*mask[i]}: returns max index where low is missing; 0 if none missing
    // Tb_low_ind > 0 if ANY break has missing low bound
    Tb_low_ind = 0
    for (i = 1; i <= n_br; i++) {
        if (Tb_final[i, 1] == .) Tb_low_ind = i  // keeps last match (maxc)
    }

    // GAUSS: Tb_high_ind = minc(seqa(1,1,n_br) .* (Tb_final[.,2] .eq miss))
    // minc of {i*mask[i]}: when mask[i]=0, product=0, so minc returns 0
    // This means Tb_high_ind > 0 ONLY when ALL breaks have missing high bound
    // In that case it returns the smallest index (first break)
    {
        real scalar all_missing_high
        all_missing_high = 1
        Tb_high_ind = 0
        for (i = 1; i <= n_br; i++) {
            if (Tb_final[i, 2] != .) {
                all_missing_high = 0
            }
        }
        if (all_missing_high == 1) {
            Tb_high_ind = 1  // first break (minc gives smallest index)
        }
    }

    // GAUSS: indica_disc_obs = zeros(T,1)
    indica_disc_obs = J(TT, 1, 0)

    // GAUSS: trim at beginning if break is near start
    if (Tb_low_ind > 0) {
        if (Tb_final[Tb_low_ind, 2] != .) {
            indica_disc_obs[1::Tb_final[Tb_low_ind, 2]] = J(Tb_final[Tb_low_ind, 2], 1, 1)
        }
    }

    // GAUSS: trim at end if break is near end
    if (Tb_high_ind > 0) {
        if (Tb_final[Tb_high_ind, 1] != .) {
            indica_disc_obs[(Tb_final[Tb_high_ind, 1] + 1)::TT] = J(TT - Tb_final[Tb_high_ind, 1], 1, 1)
        }
    }

    // GAUSS: vec_Tb_trim = zeros(T,1)
    vec_Tb_trim = J(TT, 1, 0)

    // GAUSS: Process interior breaks (packr-filtered)
    if (has_filtered) {
        // First filtered break
        indica_disc_obs[(Tb_final_filtered[1, 1] + 1)::Tb_final_filtered[1, 2]] = J(Tb_final_filtered[1, 2] - Tb_final_filtered[1, 1], 1, 1)
        vec_Tb_trim[Tb_final_filtered[1, 1]] = Tb_final_filtered[1, 1]

        // GAUSS: S=(zeros(Tb_f[1,1]+1,1)|ones(T-Tb_f[1,1]-1,1))*(y[Tb_f[1,2],.]-y[Tb_f[1,1],.])
        S = (J(Tb_final_filtered[1, 1] + 1, 1, 0) \ J(TT - Tb_final_filtered[1, 1] - 1, 1, 1)) * (y[Tb_final_filtered[1, 2], .] - y[Tb_final_filtered[1, 1], .])

        // Subsequent filtered breaks
        for (i = 2; i <= n_filtered; i++) {
            indica_disc_obs[(Tb_final_filtered[i, 1] + 1)::Tb_final_filtered[i, 2]] = J(Tb_final_filtered[i, 2] - Tb_final_filtered[i, 1], 1, 1)
            vec_Tb_trim[Tb_final_filtered[i, 1]] = Tb_final_filtered[i, 1]

            S = S + (J(Tb_final_filtered[i, 1] + 1, 1, 0) \ J(TT - Tb_final_filtered[i, 1] - 1, 1, 1)) * (y[Tb_final_filtered[i, 2], .] - y[Tb_final_filtered[i, 1], .])
        }

        yh = y - S
    }
    else {
        yh = y
    }

    // GAUSS: trim_data = selif(yh~vec_Tb_trim, indica_disc_obs .eq 0)
    // Select non-discarded observations
    {
        real scalar n_keep, idx
        real colvector keep_idx
        real matrix trim_data

        n_keep = TT - sum(indica_disc_obs)

        if (n_keep == 0) {
            // Edge case: all data trimmed
            ytrim = J(0, N, .)
            Tbtrim = (0)
            return
        }

        keep_idx = J(n_keep, 1, 0)
        idx = 0
        for (i = 1; i <= TT; i++) {
            if (indica_disc_obs[i] == 0) {
                idx++
                keep_idx[idx] = i
            }
        }

        // trim_data = yh ~ vec_Tb_trim, selected rows
        trim_data = (yh[keep_idx, .], vec_Tb_trim[keep_idx])

        // ytrim = trim_data[., 1:N]
        ytrim = trim_data[., 1::N]

        // GAUSS: Tbtrim = selif(seqa(1,1,rows(trim_data)), trim_data[.,N+1] .gt 0)
        // = row indices in trimmed data where break marker > 0
        Tbtrim = J(0, 1, .)
        for (i = 1; i <= rows(trim_data); i++) {
            if (trim_data[i, N + 1] > 0) {
                Tbtrim = (Tbtrim \ i)
            }
        }

        // GAUSS: if ismiss(Tbtrim) eq 1 then Tbtrim=0
        if (rows(Tbtrim) == 0) {
            Tbtrim = (0)
        }
    }
}


// ========================================================================
// Helper: lag a vector by n periods
// ========================================================================
real colvector _bcs_lagn(real colvector v, real scalar n)
{
    if (n >= rows(v)) return(J(rows(v), 1, .))
    return((J(n, 1, .) \ v[1::(rows(v) - n)]))
}

// Helper: lag a matrix by n periods (each column lagged)
real matrix _bcs_lagn_mat(real matrix M, real scalar n)
{
    if (n >= rows(M)) return(J(rows(M), cols(M), .))
    return((J(n, cols(M), .) \ M[1::(rows(M) - n), .]))
}


// ========================================================================
// FUNCTION: _bcs_simulate_cv()
// Bootstrap critical values via Monte Carlo simulation under H0
// Replicates GAUSS DGP: independent random walks (no cointegration)
// GAUSS: critical_model3.gss / critical_model5.gss
// ========================================================================

void _bcs_simulate_cv(
    real scalar N,
    real scalar TT,
    real scalar k,
    real scalar model,
    real colvector Tb,
    real scalar brk_slope,
    real scalar brk_loadings,
    real scalar num_factors,
    real scalar p_max,
    real scalar opt_auto,
    real scalar opt_ic,
    real scalar opt_CCE,
    real scalar reps,
    real colvector panel_cv,
    real colvector ind_cv)
{
    real scalar discard, rep, i, ii
    real matrix Y_sim, X_sim, eps_sim
    real colvector panel_cips_dist, ind_cips_dist
    real colvector beta_tmp, SSR_tmp, t_tmp, p_tmp
    real scalar panel_tmp

    discard = 50  // burn-in observations (matching GAUSS)

    panel_cips_dist = J(reps, 1, .)
    ind_cips_dist   = J(reps, 1, .)

    for (rep = 1; rep <= reps; rep++) {

        // DGP under H0: independent random walks
        // GAUSS: Y[ii,.]=Y[ii-1,.]+eps[ii,.]; X[ii,.]=X[ii-1,.]+rndn(1,N*k)
        Y_sim = J(TT + discard, N, 0)
        X_sim = J(TT + discard, N * k, 0)

        for (ii = 2; ii <= TT + discard; ii++) {
            Y_sim[ii, .] = Y_sim[ii - 1, .] + rnormal(1, N, 0, 1)
            X_sim[ii, .] = X_sim[ii - 1, .] + rnormal(1, N * k, 0, 1)
        }

        // Discard burn-in
        Y_sim = Y_sim[(discard + 1)::(TT + discard), .]
        X_sim = X_sim[(discard + 1)::(TT + discard), .]

        // Run the test under H0
        _bcs_cadfcoin_main(Y_sim, X_sim, model, Tb, brk_slope, brk_loadings,
            num_factors, p_max, opt_auto, opt_ic, opt_CCE,
            beta_tmp, SSR_tmp, panel_tmp, t_tmp, p_tmp)

        panel_cips_dist[rep] = panel_tmp
        ind_cips_dist[rep]   = t_tmp[1]  // first unit's individual stat

        // Progress indicator every 100 reps
        if (mod(rep, 100) == 0) {
            displayas("txt")
            printf("  Bootstrap: %g / %g replications completed\n", rep, reps)
            displayflush()
        }
    }

    // Sort and compute quantiles at 1%, 2.5%, 5%, 10%
    // GAUSS: quantile(panel_t_cadf, 0.01|0.025|0.05|0.1)
    panel_cips_dist = sort(panel_cips_dist, 1)
    ind_cips_dist   = sort(ind_cips_dist, 1)

    panel_cv = J(4, 1, .)
    ind_cv   = J(4, 1, .)

    // Percentile positions
    real scalar n01, n025, n05, n10
    n01  = max((1, floor(0.01 * reps)))
    n025 = max((1, floor(0.025 * reps)))
    n05  = max((1, floor(0.05 * reps)))
    n10  = max((1, floor(0.10 * reps)))

    panel_cv[1] = panel_cips_dist[n01]
    panel_cv[2] = panel_cips_dist[n025]
    panel_cv[3] = panel_cips_dist[n05]
    panel_cv[4] = panel_cips_dist[n10]

    ind_cv[1] = ind_cips_dist[n01]
    ind_cv[2] = ind_cips_dist[n025]
    ind_cv[3] = ind_cips_dist[n05]
    ind_cv[4] = ind_cips_dist[n10]
}


end
