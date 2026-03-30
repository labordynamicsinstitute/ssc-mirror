*! _xtcbc_engine.ado - Core Mata engine for xtcbc
*! Implements: Kaddoura (2025, Journal of Econometrics)
*! "Estimating Coefficient-by-Coefficient Breaks in Panel Data Models"
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.1.0 - 28 March 2026

version 14.0

capture mata: mata drop cbc_*()

mata:
mata set matastrict off

// ================================================================
//  HELPER: Projection  M_A * z = z - A*(A'A)^{-1}*A'*z
// ================================================================
real matrix cbc_project_out(real matrix z, real matrix A)
{
    real scalar nc
    nc = cols(A)
    if (nc == 0) return(z)
    if (rows(A) <= nc) return(z)
    return(z - A * (invsym(cross(A,A)) * cross(A,z)))
}

// ================================================================
//  cbc_initial_estimates: Partialed-out OLS (Eq 2.4)
//  Y: N x T,  X: N x (T*p)
//  Returns T x p matrix of initial estimates beta_dot
// ================================================================
real matrix cbc_initial_estimates(real matrix Y, real matrix X, real scalar p)
{
    real scalar   N, TT, t, k, ell, col_s
    real matrix   beta_dot, Xmk
    real colvector yt, Xk_t, Xk_proj, yt_proj
    real scalar   denom

    N  = rows(Y)
    TT = cols(Y)
    beta_dot = J(TT, p, 0)

    for (t = 2; t <= TT; t++) {
        yt  = Y[.,t] :- Y[.,1]
        col_s = (t - 1) * p

        for (k = 1; k <= p; k++) {
            Xk_t = X[., col_s + k]

            Xmk = J(N, 0, .)
            for (ell = 1; ell <= p; ell++) {
                if (ell != k) Xmk = Xmk, X[., col_s + ell]
            }
            for (ell = 1; ell <= p; ell++) {
                Xmk = Xmk, X[., ell]
            }

            Xk_proj = cbc_project_out(Xk_t, Xmk)
            yt_proj = cbc_project_out(yt,   Xmk)

            denom = cross(Xk_proj, Xk_proj)
            if (denom > 1e-14) {
                beta_dot[t, k] = cross(Xk_proj, yt_proj) / denom
            }
        }
    }
    // Period 1 inherits period 2
    beta_dot[1,.] = beta_dot[2,.]
    return(beta_dot)
}

// ================================================================
//  cbc_weights: w_{k,t} = |beta_dot_{k,t} - beta_dot_{k,t-1}|^{-kappa}
//  Only computed for t >= 3 (no penalty on |beta_2 - beta_1|)
// ================================================================
real matrix cbc_weights(real matrix beta_dot, real scalar kappa)
{
    real scalar TT, p, t, k, dv
    real matrix W

    TT = rows(beta_dot)
    p  = cols(beta_dot)
    W  = J(TT, p, 0)

    for (t = 2; t <= TT; t++) {
        for (k = 1; k <= p; k++) {
            dv = abs(beta_dot[t,k] - beta_dot[t-1,k])
            W[t,k] = (dv > 1e-12 ? dv^(-kappa) : 1e12)
        }
    }
    return(W)
}

// ================================================================
//  cbc_fused_lasso: Solve CBCL objective (Eq 2.3)
//  Uses block coordinate descent with FORWARD + BACKWARD sweeps
//  and soft-thresholding on the fused penalty
//  Y: N x T,  X: N x (T*p),  W: T x p (weights)
//  Returns T x p coefficient matrix
// ================================================================
real matrix cbc_fused_lasso(real matrix Y, real matrix X,
                            real matrix W, real scalar lambda,
                            real scalar p, real scalar rho,
                            real scalar maxiter, real scalar tol)
{
    real scalar N, TT, iter, t, k, ell, col_s
    real scalar xk_sum, xk_y_sum, beta_cand, diff_prev
    real scalar threshold, change, threshold_fwd
    real matrix beta, beta_new
    real colvector yt, fitted_other, r_partial, Xk_t
    real scalar prev_val, next_val, num1, den1

    N  = rows(Y)
    TT = cols(Y)

    beta = cbc_initial_estimates(Y, X, p)

    for (iter = 1; iter <= maxiter; iter++) {
        beta_new = beta

        // === FORWARD SWEEP: t = 2,...,T ===
        for (t = 2; t <= TT; t++) {
            yt    = Y[.,t] :- Y[.,1]
            col_s = (t - 1) * p

            for (k = 1; k <= p; k++) {
                Xk_t = X[., col_s + k]

                fitted_other = J(N, 1, 0)
                for (ell = 1; ell <= p; ell++) {
                    if (ell != k) {
                        fitted_other = fitted_other + X[., col_s + ell] :* beta_new[t, ell] - X[., ell] :* beta_new[1, ell]
                    }
                }
                fitted_other = fitted_other :- X[., k] :* beta_new[1, k]

                r_partial = yt :- fitted_other
                xk_sum    = cross(Xk_t, Xk_t)
                xk_y_sum  = cross(Xk_t, r_partial)
                if (xk_sum < 1e-14) continue

                beta_cand = xk_y_sum / xk_sum
                prev_val  = beta_new[t-1, k]

                // Backward penalty: lambda * W[t,k] * |beta_t - beta_{t-1}|
                threshold = lambda * W[t,k] * N / (2 * xk_sum)

                // Forward penalty: lambda * W[t+1,k] * |beta_{t+1} - beta_t|
                if (t < TT) {
                    threshold_fwd = lambda * W[t+1,k] * N / (2 * xk_sum)
                    next_val = beta_new[t+1, k]
                }
                else {
                    threshold_fwd = 0
                    next_val = beta_cand
                }

                // Solve with both penalties using weighted median approach
                diff_prev = beta_cand - prev_val
                if (abs(diff_prev) <= threshold) {
                    beta_new[t, k] = prev_val
                }
                else {
                    beta_new[t, k] = prev_val + sign(diff_prev) * (abs(diff_prev) - threshold)
                }
            }
        }

        // === BACKWARD SWEEP: t = T-1,...,2 ===
        for (t = TT-1; t >= 2; t--) {
            yt    = Y[.,t] :- Y[.,1]
            col_s = (t - 1) * p

            for (k = 1; k <= p; k++) {
                Xk_t = X[., col_s + k]

                fitted_other = J(N, 1, 0)
                for (ell = 1; ell <= p; ell++) {
                    if (ell != k) {
                        fitted_other = fitted_other + X[., col_s + ell] :* beta_new[t, ell] - X[., ell] :* beta_new[1, ell]
                    }
                }
                fitted_other = fitted_other :- X[., k] :* beta_new[1, k]

                r_partial = yt :- fitted_other
                xk_sum    = cross(Xk_t, Xk_t)
                xk_y_sum  = cross(Xk_t, r_partial)
                if (xk_sum < 1e-14) continue

                beta_cand = xk_y_sum / xk_sum

                // Use both neighbors for the soft-thresholding
                prev_val = beta_new[t-1, k]
                next_val = beta_new[t+1, k]

                // Total penalty for this coefficient
                threshold = lambda * W[t,k] * N / (2 * xk_sum)
                threshold_fwd = lambda * W[t+1,k] * N / (2 * xk_sum)

                // Soft-threshold toward previous
                diff_prev = beta_cand - prev_val
                if (abs(diff_prev) <= threshold) {
                    beta_new[t, k] = prev_val
                }
                else {
                    beta_new[t, k] = prev_val + sign(diff_prev) * (abs(diff_prev) - threshold)
                }

                // Additional: if close to next period, fuse forward too
                if (abs(beta_new[t,k] - next_val) <= threshold_fwd * 0.5) {
                    beta_new[t,k] = next_val
                }
            }
        }

        // === Update beta_{k,1} for k = 1,...,p ===
        for (k = 1; k <= p; k++) {
            num1 = 0
            den1 = 0
            for (t = 2; t <= TT; t++) {
                yt    = Y[.,t] :- Y[.,1]
                col_s = (t - 1) * p

                fitted_other = J(N, 1, 0)
                for (ell = 1; ell <= p; ell++) {
                    fitted_other = fitted_other + X[., col_s + ell] :* beta_new[t, ell]
                }
                for (ell = 1; ell <= p; ell++) {
                    if (ell != k) {
                        fitted_other = fitted_other - X[., ell] :* beta_new[1, ell]
                    }
                }
                r_partial = yt :- fitted_other
                num1 = num1 - cross(X[.,k], r_partial)
                den1 = den1 + cross(X[.,k], X[.,k])
            }
            if (den1 > 1e-14) beta_new[1, k] = num1 / den1
        }

        change = sum(abs(beta_new :- beta)) / max((sum(abs(beta)), 1))
        beta   = beta_new
        if (change < tol) break
    }

    // Post-convergence: force beta_1 = beta_2 (period 1 inherits period 2)
    beta[1,.] = beta[2,.]

    return(beta)
}

// ================================================================
//  cbc_detect_breaks: identify breaks per coefficient
//  Only detects breaks at t = 3,...,T (period 1-2 form base regime)
//  Uses adaptive threshold based on coefficient scale
// ================================================================
void cbc_detect_breaks(real matrix beta_hat, real scalar delta,
                       real rowvector nbreaks, real matrix break_dates)
{
    real scalar TT, p, k, t, cnt, max_diff, adapt_delta

    TT = rows(beta_hat)
    p  = cols(beta_hat)
    nbreaks     = J(1, p, 0)
    break_dates = J(TT, p, 0)

    for (k = 1; k <= p; k++) {
        // Adaptive threshold: 1% of max coefficient difference
        max_diff = 0
        for (t = 3; t <= TT; t++) {
            max_diff = max((max_diff, abs(beta_hat[t,k] - beta_hat[t-1,k])))
        }
        adapt_delta = max((delta, max_diff * 0.05))

        cnt = 0
        for (t = 3; t <= TT; t++) {
            if (abs(beta_hat[t,k] - beta_hat[t-1,k]) > adapt_delta) {
                cnt++
                break_dates[cnt, k] = t
            }
        }
        nbreaks[k] = cnt
    }
}

// ================================================================
//  cbc_sub_regimes: intersection of two regime lists
// ================================================================
void cbc_sub_regimes(real scalar rk_start, real scalar rk_end,
                     real colvector ell_breaks, real scalar n_ell_breaks,
                     real scalar TT,
                     real colvector sub_starts, real colvector sub_ends,
                     real scalar n_subs)
{
    real scalar j, ell_s, ell_e, is, ie
    real colvector bnds

    sub_starts = J(TT, 1, 0)
    sub_ends   = J(TT, 1, 0)
    n_subs     = 0

    if (n_ell_breaks == 0) {
        n_subs = 1
        sub_starts[1] = rk_start
        sub_ends[1] = rk_end
        return
    }

    bnds = J(n_ell_breaks + 2, 1, 0)
    bnds[1] = 1
    for (j = 1; j <= n_ell_breaks; j++) bnds[j+1] = ell_breaks[j]
    bnds[n_ell_breaks + 2] = TT + 1

    for (j = 1; j <= n_ell_breaks + 1; j++) {
        ell_s = bnds[j]
        ell_e = bnds[j+1] - 1
        is = max((rk_start, ell_s))
        ie = min((rk_end,   ell_e))
        if (is <= ie) {
            n_subs++
            sub_starts[n_subs] = is
            sub_ends[n_subs]   = ie
        }
    }
}

// ================================================================
//  cbc_post_selection: Eq 2.5 / Appendix B
//  Returns matrix [k, regime, start_t, end_t, alpha, se]
//  FIX: For regimes starting at t=1, stacking begins at t=2
//  (ytilde_1 = y_1 - y_1 = 0, so period 1 carries no identifying info)
// ================================================================
real matrix cbc_post_selection(real matrix Y, real matrix X,
                               real scalar p,
                               real rowvector nbreaks,
                               real matrix break_dates)
{
    real scalar N, TT, k, j, ell, cc, tt, idx, max_a
    real scalar rk_s, rk_e, n_reg, col_s, n_dates, row_idx
    real scalar alpha_val, se_val, theta_v, xi_v, sigma2, denom_s, ns
    real scalar stack_s
    real matrix alpha_info, Xbreve
    real colvector reg_s, reg_e, y_stack, xk_stack
    real colvector col_block, f_col, xk_proj, y_proj, resid, res_s
    real colvector ss, se

    N  = rows(Y)
    TT = cols(Y)

    max_a = 0
    for (k = 1; k <= p; k++) max_a = max_a + nbreaks[k] + 1
    alpha_info = J(max_a, 6, 0)
    idx = 0

    for (k = 1; k <= p; k++) {
        n_reg = nbreaks[k] + 1
        reg_s = J(n_reg, 1, 0)
        reg_e = J(n_reg, 1, 0)

        reg_s[1] = 1
        for (j = 1; j <= nbreaks[k]; j++) {
            reg_e[j]   = break_dates[j,k] - 1
            reg_s[j+1] = break_dates[j,k]
        }
        reg_e[n_reg] = TT

        for (j = 1; j <= n_reg; j++) {
            rk_s    = reg_s[j]
            rk_e    = reg_e[j]
            if (rk_e < rk_s) continue

            // FIX: If regime starts at t=1, start stacking from t=2
            // because ytilde_1 = y_1 - y_1 = 0 carries no info
            stack_s = max((rk_s, 2))
            if (stack_s > rk_e) {
                // Regime only contains t=1 — shouldn't happen with t>=3 detection
                idx++
                alpha_info[idx,1] = k
                alpha_info[idx,2] = j
                alpha_info[idx,3] = rk_s
                alpha_info[idx,4] = rk_e
                alpha_info[idx,5] = 0
                alpha_info[idx,6] = 0
                continue
            }

            n_dates = rk_e - stack_s + 1

            // Stack y_tilde and X_k for dates in regime
            y_stack  = J(n_dates * N, 1, 0)
            xk_stack = J(n_dates * N, 1, 0)
            row_idx  = 0
            for (tt = stack_s; tt <= rk_e; tt++) {
                col_s = (tt - 1) * p
                y_stack[| row_idx*N+1 \ (row_idx+1)*N |]  = Y[.,tt] :- Y[.,1]
                xk_stack[| row_idx*N+1 \ (row_idx+1)*N |] = X[., col_s + k]
                row_idx++
            }

            // Build X_breve (block-diagonal for ell != k, plus F)
            Xbreve = J(n_dates * N, 0, .)
            for (ell = 1; ell <= p; ell++) {
                if (ell == k) continue
                cbc_sub_regimes(stack_s, rk_e,
                    break_dates[.,ell], nbreaks[ell], TT, ss, se, ns)

                for (cc = 1; cc <= ns; cc++) {
                    col_block = J(n_dates * N, 1, 0)
                    for (tt = ss[cc]; tt <= se[cc]; tt++) {
                        if (tt < stack_s) continue
                        col_s = (tt - 1) * p
                        col_block[| (tt-stack_s)*N+1 \ (tt-stack_s+1)*N |] = X[., col_s + ell]
                    }
                    Xbreve = Xbreve, col_block
                }
            }
            // Add first-period regressors F(r_{k,j})
            for (ell = 1; ell <= p; ell++) {
                f_col = J(n_dates * N, 1, 0)
                for (tt = stack_s; tt <= rk_e; tt++) {
                    f_col[| (tt-stack_s)*N+1 \ (tt-stack_s+1)*N |] = X[., ell]
                }
                Xbreve = Xbreve, f_col
            }

            // Project out and estimate
            alpha_val = 0
            se_val    = 0

            if (cols(Xbreve) > 0 & rows(Xbreve) > cols(Xbreve) + 1) {
                xk_proj = cbc_project_out(xk_stack, Xbreve)
                y_proj  = cbc_project_out(y_stack,  Xbreve)
                theta_v = cross(xk_proj, xk_proj) / N
                xi_v    = cross(xk_proj, y_proj)  / N
                if (abs(theta_v) > 1e-14) {
                    alpha_val = xi_v / theta_v
                    resid  = y_proj :- xk_proj :* alpha_val
                    sigma2 = cross(resid, resid) / (n_dates * N - cols(Xbreve) - 1)
                    se_val = sqrt(abs(sigma2 / (theta_v * N)))
                }
            }
            else {
                denom_s = cross(xk_stack, xk_stack)
                if (denom_s > 1e-14) {
                    alpha_val = cross(xk_stack, y_stack) / denom_s
                    res_s  = y_stack :- xk_stack :* alpha_val
                    se_val = sqrt(cross(res_s, res_s) / (rows(y_stack) - 1)) / sqrt(denom_s)
                }
            }

            idx++
            alpha_info[idx,1] = k
            alpha_info[idx,2] = j
            alpha_info[idx,3] = rk_s
            alpha_info[idx,4] = rk_e
            alpha_info[idx,5] = alpha_val
            alpha_info[idx,6] = se_val
        }
    }
    return(alpha_info[|1,1 \ idx,6|])
}

// ================================================================
//  cbc_ic1: Information criterion (Eq 3.1)
// ================================================================
real scalar cbc_ic1(real matrix Y, real matrix X, real scalar p,
                    real matrix beta_hat, real rowvector nbreaks,
                    real scalar N_obs, real scalar phi)
{
    real scalar TT, sigma2, penalty, t, k, col_s
    real colvector yt, fitted, resid_t

    TT = cols(Y)
    sigma2 = 0
    for (t = 2; t <= TT; t++) {
        yt  = Y[.,t] :- Y[.,1]
        col_s = (t - 1) * p
        fitted = J(rows(Y), 1, 0)
        for (k = 1; k <= p; k++) {
            fitted = fitted + X[., col_s+k] :* beta_hat[t,k] - X[., k] :* beta_hat[1,k]
        }
        resid_t = yt :- fitted
        sigma2 = sigma2 + cross(resid_t, resid_t)
    }
    sigma2 = sigma2 / (N_obs * (TT - 1))

    penalty = 0
    for (k = 1; k <= p; k++) penalty = penalty + nbreaks[k] + 1
    return(sigma2 + phi * penalty)
}

// ================================================================
//  cbc_estimate_homogeneous: Full Algorithm 1
// ================================================================
void cbc_estimate_homogeneous(real matrix Y, real matrix X,
                               real scalar p, real scalar kappa,
                               real scalar ngrid, real scalar c_const)
{
    real scalar N, TT, q, t, k, d_val
    real scalar lambda_min, lambda_max, phi
    real scalar max_diff, min_diff, ic_val, best_ic, best_lambda
    real scalar change_val, delta
    real matrix beta_dot, W_mat, beta_q
    real colvector lambda_grid, ic_vec
    real matrix best_beta, best_bd, bd_q
    real rowvector best_nb, nb_q
    real matrix alpha_result

    N  = rows(Y)
    TT = cols(Y)

    external real matrix    cbc_beta_hat
    external real rowvector cbc_nbreaks
    external real matrix    cbc_break_dates
    external real matrix    cbc_alpha_info
    external real colvector cbc_ic_values
    external real colvector cbc_lambda_grid
    external real scalar    cbc_optimal_lambda
    external real matrix    cbc_initial_beta

    // Step 1: Initial estimates
    beta_dot = cbc_initial_estimates(Y, X, p)
    cbc_initial_beta = beta_dot

    // Step 2: Weights
    W_mat = cbc_weights(beta_dot, kappa)

    // Step 3: Lambda grid (data-driven bounds)
    max_diff = 0
    min_diff = 1e10
    for (k = 1; k <= p; k++) {
        for (t = 3; t <= TT; t++) {
            d_val = abs(beta_dot[t,k] - beta_dot[t-1,k])
            if (d_val > max_diff) max_diff = d_val
            if (d_val > 1e-12 & d_val < min_diff) min_diff = d_val
        }
    }
    if (max_diff < 1e-10) max_diff = 1
    if (min_diff > max_diff) min_diff = max_diff / 100

    lambda_min = min_diff / (100 * N)
    lambda_max = max_diff * N * 10

    lambda_grid = J(ngrid, 1, 0)
    for (q = 1; q <= ngrid; q++) {
        lambda_grid[q] = exp(ln(lambda_min) + (q - 1) * (ln(lambda_max) - ln(lambda_min)) / (ngrid - 1))
    }

    phi = c_const * ln(N) / sqrt(N)
    delta = 1e-8

    // Step 4: Grid search
    ic_vec     = J(ngrid, 1, 1e20)
    best_ic    = 1e20
    best_lambda = lambda_grid[1]
    best_beta  = beta_dot
    best_nb    = J(1, p, 0)
    best_bd    = J(TT, p, 0)

    for (q = 1; q <= ngrid; q++) {
        beta_q = cbc_fused_lasso(Y, X, W_mat, lambda_grid[q], p, 1.0, 500, 1e-7)
        cbc_detect_breaks(beta_q, delta, nb_q, bd_q)
        ic_val = cbc_ic1(Y, X, p, beta_q, nb_q, N, phi)
        ic_vec[q] = ic_val

        if (ic_val < best_ic) {
            best_ic     = ic_val
            best_lambda = lambda_grid[q]
            best_beta   = beta_q
            best_nb     = nb_q
            best_bd     = bd_q
        }
    }

    // Step 5: Post-selection
    alpha_result = cbc_post_selection(Y, X, p, best_nb, best_bd)

    // Store
    cbc_beta_hat       = best_beta
    cbc_nbreaks        = best_nb
    cbc_break_dates    = best_bd
    cbc_alpha_info     = alpha_result
    cbc_ic_values      = ic_vec
    cbc_lambda_grid    = lambda_grid
    cbc_optimal_lambda = best_lambda
}

// ================================================================
//  cbc_csdemean: Cross-section demean matrices stored in Stata
// ================================================================
void cbc_csdemean(string scalar yname, string scalar xname)
{
    real scalar t, c
    real matrix Ym, Xm
    Ym = st_matrix(yname)
    Xm = st_matrix(xname)
    for (t = 1; t <= cols(Ym); t++) {
        Ym[.,t] = Ym[.,t] :- mean(Ym[.,t])
    }
    for (c = 1; c <= cols(Xm); c++) {
        Xm[.,c] = Xm[.,c] :- mean(Xm[.,c])
    }
    st_matrix(yname, Ym)
    st_matrix(xname, Xm)
}

end
