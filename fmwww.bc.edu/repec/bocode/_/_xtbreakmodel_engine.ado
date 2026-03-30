*! _xtbreakmodel_engine.ado — Mata engine for xtbreakmodel
*! Implements: Okui & Wang (2021), Qian & Su (2016), Baltagi et al. (2016), Li et al. (2025)
*! Author: Dr Merwan Roudane
*! Version 1.0.0

capture mata: mata drop _xtbm_*()
mata:
mata set matastrict off

// ====================================================================
// UTILITY: p-norms along dimension (mirrors norms.m)
// ====================================================================
real matrix _xtbm_norms(real matrix x, real scalar p, real scalar dim)
{
    if (p == 1) return(rowsum(abs(x)))
    if (p == 2) return(sqrt(rowsum(x:*x)))
    if (p == .) return(rowmax(abs(x)))
    return(rowsum(abs(x):^p):^(1/p))
}

// row-wise L2 norms
real colvector _xtbm_rnorm2(real matrix x)
{
    return(sqrt(rowsum(x:*x)))
}

// ====================================================================
// GET_REGIME: extract regime partition from theta (mirrors get_regime.m)
// ====================================================================
real colvector _xtbm_get_regime(real matrix tht, real scalar threshold)
{
    real scalar TT, p, t
    real colvector ntht, regime
    
    TT = rows(tht)
    p = cols(tht)
    ntht = sqrt(rowsum(tht:*tht))
    
    regime = (1 \ J(0,1,.))
    for (t = 2; t <= TT; t++) {
        if (ntht[t] > threshold) {
            regime = regime \ t
        }
    }
    regime = regime \ (TT + 1)
    return(regime)
}

// ====================================================================
// POST_PLS: post-lasso estimation (mirrors post_pls.m)
// ====================================================================
void _xtbm_post_pls(real colvector Y, real matrix X, real scalar NN,
                    real colvector regime,
                    real matrix alpha, real scalar ssr, real matrix se)
{
    real scalar n, p, m, nr, TT, r, tau, Ng_tau, i, t, k, j
    real scalar s_idx, e_idx, row_out, row_in, mbar
    real matrix RX, RY, regX, regY, XX, YY, beta_full, Rres, beta_rep
    real colvector res, rres
    real matrix xi_mat, Omega_r, Phi_r, S_r, Om, Ph, Sv
    
    n = rows(X)
    p = cols(X)
    TT = n / NN
    
    // count nonzero regime entries
    nr = 0
    for (r = 1; r <= rows(regime); r++) {
        if (regime[r] != 0) nr++
    }
    m = nr - 2
    nr = nr - 1
    
    if (m == 0) {
        alpha = (lusolve(cross(X,X), cross(X,Y)))'
    }
    else {
        RX = J(TT, NN * p, 0)
        RY = J(TT, NN, 0)
        for (r = 1; r <= NN; r++) {
            RY[., r] = Y[((r-1)*TT+1)..(r*TT)]
            for (t = 1; t <= p; t++) {
                RX[., (r-1)*p + t] = X[((r-1)*TT+1)..(r*TT), t]
            }
        }
        
        // reshape: RX is T x N x p stored as T x (N*p)
        // Actually simpler: use the stacked form directly
        alpha = J(nr, p, 0)
        for (r = 2; r <= nr + 1; r++) {
            s_idx = regime[r-1]
            e_idx = regime[r] - 1
            tau = e_idx - s_idx + 1
            
            XX = J(NN * tau, p, 0)
            YY = J(NN * tau, 1, 0)
            for (i = 1; i <= NN; i++) {
                for (t = s_idx; t <= e_idx; t++) {
                    row_out = (i-1)*tau + (t - s_idx + 1)
                    row_in = (i-1)*TT + t
                    XX[row_out, .] = X[row_in, .]
                    YY[row_out] = Y[row_in]
                }
            }
            alpha[r-1, .] = (lusolve(cross(XX,XX), cross(XX,YY)))'
        }
    }
    
    // build full beta and compute SSR
    mbar = rows(alpha)
    beta_full = J(regime[mbar+1] - 1, p, 0)
    for (i = 1; i <= mbar; i++) {
        for (t = regime[i]; t <= regime[i+1] - 1; t++) {
            beta_full[t, .] = alpha[i, .]
        }
    }
    
    // replicate beta for all N
    beta_rep = J(n, p, 0)
    for (i = 1; i <= NN; i++) {
        beta_rep[((i-1)*TT+1)..(i*TT), .] = beta_full
    }
    res = Y - rowsum(X :* beta_rep)
    ssr = cross(res, res)
    
    // Standard errors
    se = J(mbar, p, 0)
    if (m == 0) {
        xi_mat = res :* X
        Om = cross(xi_mat, xi_mat) / (NN * TT)
        Ph = luinv(cross(X, X) / (NN * TT))
        Sv = Ph * Om * Ph' / (NN * TT)
        se = (sqrt(diagonal(Sv)))'
    }
    else {
        for (r = 2; r <= nr + 1; r++) {
            s_idx = regime[r-1]
            e_idx = regime[r] - 1
            tau = e_idx - s_idx + 1
            
            XX = J(NN * tau, p, 0)
            rres = J(NN * tau, 1, 0)
            for (i = 1; i <= NN; i++) {
                for (t = s_idx; t <= e_idx; t++) {
                    row_out = (i-1)*tau + (t - s_idx + 1)
                    row_in = (i-1)*TT + t
                    XX[row_out, .] = X[row_in, .]
                    rres[row_out] = res[row_in]
                }
            }
            xi_mat = rres :* XX
            Om = cross(xi_mat, xi_mat) / (NN * tau)
            Ph = luinv(cross(XX, XX) / (NN * tau))
            Sv = Ph * Om * Ph' / (tau * NN)
            se[r-1, .] = (sqrt(diagonal(Sv)))'
        }
    }
}

// ====================================================================
// PLSBCD: Block Coordinate Descent (mirrors plsbcd.m / cplsbcd.c)
// ====================================================================
real matrix _xtbm_plsbcd(real colvector y, real matrix x,
                         real scalar lambda, real colvector weight,
                         real scalar XTol, real scalar maxIter)
{
    real scalar n, p, TT, NN, t, i, j, k, iter
    real scalar errn, gam_opt, lam_w
    real matrix R_mat, r_mat, ax_t, Rn, rn, d0, d1
    real matrix s_mat, c_mat, g_mat, A_t
    real colvector ay_t, vTmp, q_vec, g_vec
    real matrix R_tmp, r_tmp, Ak, A_gam
    
    n = rows(x)
    p = cols(x)
    TT = rows(weight) + 1
    NN = n / TT
    
    // Build R(t) = X_t' X_t and r(t) = X_t' Y_t for each t
    R_mat = J(TT, p*p, 0)
    r_mat = J(TT, p, 0)
    
    for (t = 1; t <= TT; t++) {
        ax_t = J(NN, p, 0)
        ay_t = J(NN, 1, 0)
        for (i = 1; i <= NN; i++) {
            ax_t[i, .] = x[(i-1)*TT + t, .]
            ay_t[i] = y[(i-1)*TT + t]
        }
        R_mat[t, .] = vec(cross(ax_t, ax_t))'
        r_mat[t, .] = (cross(ax_t, ay_t))'
    }
    
    // Reverse cumulative sum: Rn(t) = sum_{s=t}^{T} R(s)
    R_tmp = J(TT, p*p, 0)
    r_tmp = J(TT, p, 0)
    for (t = TT; t >= 1; t--) {
        R_tmp[TT - t + 1, .] = R_mat[t, .]
        r_tmp[TT - t + 1, .] = r_mat[t, .]
    }
    // cumsum of reversed
    for (t = 2; t <= TT; t++) {
        R_tmp[t, .] = R_tmp[t, .] + R_tmp[t-1, .]
        r_tmp[t, .] = r_tmp[t, .] + r_tmp[t-1, .]
    }
    // reverse back
    Rn = J(TT, p*p, 0)
    rn = J(TT, p, 0)
    for (t = 1; t <= TT; t++) {
        Rn[t, .] = R_tmp[TT - t + 1, .]
        rn[t, .] = r_tmp[TT - t + 1, .]
    }
    
    d0 = J(TT, p, 0)
    d1 = J(TT, p, 0)
    
    errn = 1e10
    iter = 0
    
    while (errn > XTol & iter < maxIter) {
        iter++
        for (t = 1; t <= TT; t++) {
            A_t = rowshape(Rn[t, .], p)
            
            if (t == 1) {
                s_mat = J(TT, p, 0)
                c_mat = J(TT, p, 0)
                g_mat = J(TT, p, 0)
                
                for (k = 2; k <= TT; k++) {
                    Ak = rowshape(Rn[k, .], p)
                    s_mat[1, .] = s_mat[1, .] + (Ak * d0[k, .]')'
                }
                g_mat[1, .] = s_mat[1, .] - rn[1, .]
                d1[1, .] = -(lusolve(A_t, g_mat[1, .]'))'
            }
            else {
                c_mat[t, .] = c_mat[t-1, .] + d1[t-1, .]
                s_mat[t, .] = s_mat[t-1, .] - (A_t * d0[t, .]')'
                g_mat[t, .] = (A_t * c_mat[t, .]')' + s_mat[t, .] - rn[t, .]
                
                g_vec = g_mat[t, .]'
                if (norm(g_vec) <= lambda * weight[t-1]) {
                    d1[t, .] = J(1, p, 0)
                }
                else {
                    lam_w = lambda * weight[t-1]
                    // Golden section search for gamma (replaces fminsearch)
                    gam_opt = _xtbm_brent_search(A_t, lam_w, g_vec, p, XTol)
                    
                    A_gam = gam_opt * A_t + (lam_w^2 / 2) * I(p)
                    d1[t, .] = (-gam_opt * (lusolve(A_gam, g_vec)))'
                }
            }
        }
        errn = sqrt(sum((d1 - d0):^2))
        d0 = d1
    }
    return(d1)
}

// Brent-style line search for gamma (replaces MATLAB fminsearch)
real scalar _xtbm_brent_search(real matrix R, real scalar lam,
                               real colvector g, real scalar p,
                               real scalar tol)
{
    real scalar a, b, x, w, v, fx, fw, fv, d, e
    real scalar m, tol1, tol2, r_b, q_b, pp, u, fu
    real scalar GOLD, maxiter, iter
    
    GOLD = 0.381966
    a = 1e-8
    b = 1e4
    maxiter = 100
    
    x = a + GOLD * (b - a)
    w = x
    v = x
    fx = _xtbm_brent_obj(x, R, lam, g, p)
    fw = fx
    fv = fx
    d = 0
    e = 0
    
    for (iter = 1; iter <= maxiter; iter++) {
        m = 0.5 * (a + b)
        tol1 = tol * abs(x) + 1e-10
        tol2 = 2 * tol1
        
        if (abs(x - m) <= tol2 - 0.5 * (b - a)) return(x)
        
        if (abs(e) > tol1) {
            r_b = (x - w) * (fx - fv)
            q_b = (x - v) * (fx - fw)
            pp = (x - v) * q_b - (x - w) * r_b
            q_b = 2 * (q_b - r_b)
            if (q_b > 0) pp = -pp
            else q_b = -q_b
            if (abs(pp) < abs(0.5 * q_b * e) & pp > q_b * (a - x) & pp < q_b * (b - x)) {
                e = d
                d = pp / q_b
                u = x + d
                if ((u - a) < tol2 | (b - u) < tol2) d = (x < m ? tol1 : -tol1)
            }
            else {
                e = (x < m ? b - x : a - x)
                d = GOLD * e
            }
        }
        else {
            e = (x < m ? b - x : a - x)
            d = GOLD * e
        }
        
        u = x + (abs(d) >= tol1 ? d : (d > 0 ? tol1 : -tol1))
        fu = _xtbm_brent_obj(u, R, lam, g, p)
        
        if (fu <= fx) {
            if (u < x) b = x
            else a = x
            v = w; fv = fw
            w = x; fw = fx
            x = u; fx = fu
        }
        else {
            if (u < x) a = u
            else b = u
            if (fu <= fw | w == x) {
                v = w; fv = fw
                w = u; fw = fu
            }
            else if (fu <= fv | v == x | v == w) {
                v = u; fv = fu
            }
        }
    }
    return(x)
}

real scalar _xtbm_brent_obj(real scalar gam, real matrix R,
                            real scalar lam, real colvector g,
                            real scalar p)
{
    real matrix A
    real colvector q
    real scalar val
    
    if (gam < 0) return(1e10)
    A = gam * R + (lam^2 / 2) * I(p)
    q = lusolve(A, g)
    val = gam * (1 - 0.5 * g' * q)
    return(val)
}

// ====================================================================
// PLS: Penalized LS with IC-based lambda selection (mirrors pls.m)
// ====================================================================
void _xtbm_pls(real colvector Y, real matrix X, real scalar NN,
               real matrix beta_init,
               real scalar maxLambda, real scalar minLambda, real scalar nGrid,
               real colvector regime_out, real matrix alpha_out,
               real matrix se_out, real scalar ssr_out)
{
    real scalar n, p, TT, S, i, XTol, maxIter
    real scalar R_exp, lam_i, ssr_tmp, min_ic, best_i
    real colvector lambda_vec, IC, K_vec
    real matrix tht, theta_best, weight, THT
    real colvector regime_tmp
    real matrix alpha_tmp, se_tmp, diff_b
    
    n = rows(X)
    p = cols(X)
    TT = n / NN
    
    S = nGrid
    R_exp = ln(maxLambda / minLambda) / (S - 1)
    lambda_vec = J(S, 1, 0)
    for (i = 1; i <= S; i++) {
        lambda_vec[i] = minLambda * exp(R_exp * (i - 1))
    }
    
    IC = J(S, 1, 0)
    K_vec = J(S, 1, 0)
    
    XTol = 1e-4
    maxIter = 400
    
    // Adaptive weights from initial beta
    diff_b = beta_init[2..TT, .] - beta_init[1..(TT-1), .]
    weight = _xtbm_rnorm2(diff_b)
    // Invert with power -2 (kappa=2)
    for (i = 1; i <= rows(weight); i++) {
        if (weight[i] < 1e-10) weight[i] = 1e10
        else weight[i] = weight[i]^(-2)
    }
    
    THT = J(TT, S*p, 0)
    
    for (i = 1; i <= S; i++) {
        tht = _xtbm_plsbcd(Y, X, lambda_vec[i], weight, XTol, maxIter)
        THT[., ((i-1)*p+1)..(i*p)] = tht
        regime_tmp = _xtbm_get_regime(tht, XTol)
        _xtbm_post_pls(Y, X, NN, regime_tmp, alpha_tmp, ssr_tmp, se_tmp)
        K_vec[i] = rows(regime_tmp) - 2
        IC[i] = ssr_tmp / (n - NN) + 0.05 * (K_vec[i] + 1) * p * ln(NN * TT) / sqrt(NN * TT)
    }
    
    // Choose lambda with minimum IC
    min_ic = IC[1]
    best_i = 1
    for (i = 2; i <= S; i++) {
        if (IC[i] < min_ic) {
            min_ic = IC[i]
            best_i = i
        }
    }
    
    theta_best = THT[., ((best_i-1)*p+1)..(best_i*p)]
    regime_out = _xtbm_get_regime(theta_best, XTol)
    _xtbm_post_pls(Y, X, NN, regime_out, alpha_out, ssr_out, se_out)
}

// ====================================================================
// GFE_EST: Grouped Fixed Effects initialization (mirrors gfe_est.m)
// ====================================================================
void _xtbm_gfe_est(real colvector Y, real matrix X, real scalar NN,
                   real scalar TT, real scalar G,
                   real matrix est_beta, real matrix est_group)
{
    real scalar K, Nsim, max_iter, jsim, iter, k, rg
    real scalar resQ, resQ_best, deltapar, g, i, t
    real scalar has_empty, Ng, cnt, ss, resid, min_ss, min_g
    real matrix gi, gi_init, beta, par_init, par_new
    real matrix gi_auxaux, gi_best, beta_best, alpha_g
    real matrix ax_g, beta_g_full
    real colvector gi_class, gindt, ay_g
    
    K = cols(X)
    Nsim = 50  // fewer than MATLAB's 100 for speed
    resQ_best = 1e7
    max_iter = 20
    
    for (jsim = 1; jsim <= Nsim; jsim++) {
        // Random initialization
        gi_init = J(NN, G, 0)
        for (i = 1; i <= NN; i++) {
            rg = ceil(uniform(1,1) * G)
            if (rg < 1) rg = 1
            if (rg > G) rg = G
            gi_init[i, rg] = 1
        }
        gi = gi_init
        par_init = J(NN * TT, K, 0)
        deltapar = 1
        iter = 0
        beta = J(G, TT * K, 0)
        
        while (deltapar > 0 & iter < max_iter) {
            // Check empty groups
            has_empty = 0
            for (g = 1; g <= G; g++) {
                if (colsum(gi[., g]) == 0) has_empty = 1
            }
            if (has_empty) {
                gi_init = J(NN, G, 0)
                for (i = 1; i <= NN; i++) {
                    rg = ceil(uniform(1,1) * G)
                    if (rg < 1) rg = 1
                    if (rg > G) rg = G
                    gi_init[i, rg] = 1
                }
                gi = gi_init
            }
            
            // Step 1: Time-by-time OLS for each group
            for (g = 1; g <= G; g++) {
                Ng = colsum(gi[., g])
                if (Ng < 1) continue
                
                for (t = 1; t <= TT; t++) {
                    ax_g = J(Ng, K, 0)
                    ay_g = J(Ng, 1, 0)
                    cnt = 0
                    for (i = 1; i <= NN; i++) {
                        if (gi[i, g] == 1) {
                            cnt++
                            ax_g[cnt, .] = X[(i-1)*TT + t, .]
                            ay_g[cnt] = Y[(i-1)*TT + t]
                        }
                    }
                    if (cnt >= K) {
                        alpha_g = lusolve(cross(ax_g, ax_g), cross(ax_g, ay_g))
                        for (k = 1; k <= K; k++) {
                            beta[g, (t-1)*K + k] = alpha_g[k]
                        }
                    }
                }
            }
            
            // Step 2: Group assignment
            gi_auxaux = J(NN, G, 0)
            for (g = 1; g <= G; g++) {
                beta_g_full = J(TT, K, 0)
                for (t = 1; t <= TT; t++) {
                    beta_g_full[t, .] = beta[g, ((t-1)*K+1)..(t*K)]
                }
                for (i = 1; i <= NN; i++) {
                    ss = 0
                    for (t = 1; t <= TT; t++) {
                        resid = Y[(i-1)*TT + t] - X[(i-1)*TT + t, .] * beta_g_full[t, .]'
                        ss = ss + resid^2
                    }
                    gi_auxaux[i, g] = ss
                }
            }
            
            gi = J(NN, G, 0)
            gindt = J(NN, 1, 0)
            for (i = 1; i <= NN; i++) {
                min_ss = gi_auxaux[i, 1]
                min_g = 1
                for (g = 2; g <= G; g++) {
                    if (gi_auxaux[i, g] < min_ss) {
                        min_ss = gi_auxaux[i, g]
                        min_g = g
                    }
                }
                gi[i, min_g] = 1
                gindt[i] = min_g
            }
            
            // Convergence check
            par_new = J(NN * TT, K, 0)
            for (i = 1; i <= NN; i++) {
                for (t = 1; t <= TT; t++) {
                    par_new[(i-1)*TT + t, .] = beta[gindt[i], ((t-1)*K+1)..(t*K)]
                }
            }
            deltapar = sqrt(sum((par_new - par_init):^2))
            par_init = par_new
            iter++
        }
        
        resQ = cross(Y - rowsum(X :* par_new), Y - rowsum(X :* par_new))
        if (resQ < resQ_best) {
            resQ_best = resQ
            gi_best = gi
            beta_best = beta
        }
    }
    
    est_group = gi_best
    est_beta = beta_best
}

// ====================================================================
// GPLS_EST: Full GAGFL estimator (mirrors GPLS_est.m)
// ====================================================================
void _xtbm_gpls_est(real colvector Y, real matrix X, real scalar NN,
                    real scalar TT, real scalar G,
                    real matrix beta_init, real matrix gi_init,
                    real scalar maxLam, real scalar minLam, real scalar nGrid,
                    real matrix est_regime, real matrix est_alpha,
                    real matrix est_se, real matrix est_group,
                    real scalar resQ_best, real scalar num_iter)
{
    real scalar K, max_iteration, deltapar, iter, j
    real scalar g, i, t, k, Ng, cnt, rg
    real scalar has_empty, min_ss, min_g, maxnumbk, maxnumreg
    real matrix gi, par_init, par_new, beta, gi_auxaux
    real matrix beta_g_full, beta_rep, gX, gbeta_init
    real colvector gindt, gi_class, gY, U_sq, regime_g
    real matrix alpha_g, se_g
    real scalar ssr_g
    real colvector numbk
    
    K = cols(X)
    max_iteration = 20
    
    gi = gi_init
    par_init = J(NN * TT, K, 0)
    deltapar = 1
    num_iter = 0
    beta = beta_init
    numbk = J(G, 1, 0)
    
    while (deltapar > 0 & num_iter < max_iteration) {
        // Check empty groups
        has_empty = 0
        for (g = 1; g <= G; g++) {
            if (colsum(gi[., g]) == 0) has_empty = 1
        }
        if (has_empty) {
            for (i = 1; i <= NN; i++) {
                rg = ceil(uniform(1,1) * G)
                if (rg < 1) rg = 1
                if (rg > G) rg = G
                gi[i, .] = J(1, G, 0)
                gi[i, rg] = 1
            }
        }
        
        // Step 1: PLS for each group
        for (g = 1; g <= G; g++) {
            Ng = colsum(gi[., g])
            if (Ng < 2) continue
            
            // Extract group data
            gY = J(Ng * TT, 1, 0)
            gX = J(Ng * TT, K, 0)
            cnt = 0
            for (i = 1; i <= NN; i++) {
                if (gi[i, g] == 1) {
                    cnt++
                    gY[((cnt-1)*TT+1)..(cnt*TT)] = Y[((i-1)*TT+1)..(i*TT)]
                    gX[((cnt-1)*TT+1)..(cnt*TT), .] = X[((i-1)*TT+1)..(i*TT), .]
                }
            }
            
            gbeta_init = J(TT, K, 0)
            for (t = 1; t <= TT; t++) {
                gbeta_init[t, .] = beta[g, ((t-1)*K+1)..(t*K)]
            }
            
            _xtbm_pls(gY, gX, Ng, gbeta_init, maxLam, minLam, nGrid,
                      regime_g, alpha_g, se_g, ssr_g)
            
            numbk[g] = rows(alpha_g)
            
            // Transform alpha to beta
            for (j = 1; j <= numbk[g]; j++) {
                for (t = regime_g[j]; t <= regime_g[j+1] - 1; t++) {
                    for (k = 1; k <= K; k++) {
                        beta[g, (t-1)*K + k] = alpha_g[j, k]
                    }
                }
            }
        }
        
        // Step 2: Group assignment
        gi_auxaux = J(NN, G, 0)
        for (g = 1; g <= G; g++) {
            beta_g_full = J(TT, K, 0)
            for (t = 1; t <= TT; t++) {
                beta_g_full[t, .] = beta[g, ((t-1)*K+1)..(t*K)]
            }
            beta_rep = J(NN * TT, K, 0)
            for (i = 1; i <= NN; i++) {
                beta_rep[((i-1)*TT+1)..(i*TT), .] = beta_g_full
            }
            U_sq = (Y - rowsum(X :* beta_rep)):^2
            for (i = 1; i <= NN; i++) {
                gi_auxaux[i, g] = colsum(U_sq[((i-1)*TT+1)..(i*TT)])
            }
        }
        
        gi = J(NN, G, 0)
        gindt = J(NN, 1, 0)
        for (i = 1; i <= NN; i++) {
            min_ss = gi_auxaux[i, 1]
            min_g = 1
            for (g = 2; g <= G; g++) {
                if (gi_auxaux[i, g] < min_ss) {
                    min_ss = gi_auxaux[i, g]
                    min_g = g
                }
            }
            gi[i, min_g] = 1
            gindt[i] = min_g
        }
        
        // Convergence check
        par_new = J(NN * TT, K, 0)
        for (i = 1; i <= NN; i++) {
            for (t = 1; t <= TT; t++) {
                par_new[(i-1)*TT + t, .] = beta[gindt[i], ((t-1)*K+1)..(t*K)]
            }
        }
        deltapar = sqrt(sum((par_new - par_init):^2))
        par_init = par_new
        num_iter++
    }
    
    resQ_best = cross(Y - rowsum(X :* par_new), Y - rowsum(X :* par_new))
    
    // Check for empty groups
    has_empty = 0
    for (g = 1; g <= G; g++) {
        if (colsum(gi[., g]) == 0) has_empty = 1
    }
    if (has_empty) {
        est_regime = J(0, 0, .)
        est_alpha = J(0, 0, .)
        est_se = J(0, 0, .)
        est_group = gi
        return
    }
    
    // Final estimation
    est_group = gi
    maxnumbk = max(numbk)
    maxnumreg = maxnumbk + 1
    
    est_regime = J(maxnumreg, G, 0)
    est_alpha = J(maxnumbk, K * G, 0)
    est_se = J(maxnumbk, K * G, 0)
    
    for (g = 1; g <= G; g++) {
        Ng = colsum(est_group[., g])
        if (Ng < 2) continue
        
        gY = J(Ng * TT, 1, 0)
        gX = J(Ng * TT, K, 0)
        cnt = 0
        for (i = 1; i <= NN; i++) {
            if (est_group[i, g] == 1) {
                cnt++
                gY[((cnt-1)*TT+1)..(cnt*TT)] = Y[((i-1)*TT+1)..(i*TT)]
                gX[((cnt-1)*TT+1)..(cnt*TT), .] = X[((i-1)*TT+1)..(i*TT), .]
            }
        }
        
        gbeta_init = J(TT, K, 0)
        for (t = 1; t <= TT; t++) {
            gbeta_init[t, .] = beta[g, ((t-1)*K+1)..(t*K)]
        }
        
        _xtbm_pls(gY, gX, Ng, gbeta_init, maxLam, minLam, nGrid,
                  regime_g, alpha_g, se_g, ssr_g)
        
        numbk[g] = rows(alpha_g)
        for (j = 1; j <= numbk[g]; j++) {
            est_alpha[j, ((g-1)*K+1)..(g*K)] = alpha_g[j, .]
            est_se[j, ((g-1)*K+1)..(g*K)] = se_g[j, .]
        }
        for (j = 1; j <= numbk[g] + 1; j++) {
            est_regime[j, g] = regime_g[j]
        }
    }
}

// ====================================================================
// BFK: Single break detection (mirrors bfk_single_break_detect.m)
// ====================================================================
real scalar _xtbm_bfk_single(real scalar NN, real scalar TT,
                             real matrix xmat, real matrix ymat)
{
    real scalar K, kk, i, est_bp, t, min_ssr
    real matrix SSR2, Xcomb, z2, Xi
    real colvector sumSSR, bhat, yhat
    
    K = cols(xmat) / NN
    SSR2 = J(NN, TT - 1, 0)
    
    for (kk = 1; kk <= TT - 1; kk++) {
        for (i = 1; i <= NN; i++) {
            // Build X_i and z2 for unit i
            Xi = xmat[., i]
            if (K > 1) Xi = xmat[., ((i-1)*K+1)..(i*K)]
            
            z2 = J(TT, K, 0)
            for (t = kk + 1; t <= TT; t++) {
                if (K == 1) z2[t, 1] = xmat[t, i]
                else z2[t, .] = xmat[t, ((i-1)*K+1)..(i*K)]
            }
            
            Xcomb = (Xi, z2)
            bhat = lusolve(cross(Xcomb, Xcomb), cross(Xcomb, ymat[., i]))
            yhat = Xcomb * bhat
            SSR2[i, kk] = cross(ymat[., i] - yhat, ymat[., i] - yhat)
        }
    }
    
    sumSSR = colsum(SSR2)'
    min_ssr = sumSSR[1]
    est_bp = 1
    for (kk = 2; kk <= TT - 1; kk++) {
        if (sumSSR[kk] < min_ssr) {
            min_ssr = sumSSR[kk]
            est_bp = kk
        }
    }
    return(est_bp)
}

// ====================================================================
// BFK: Post-break estimation (mirrors bfk_post_break_est.m)
// ====================================================================
void _xtbm_bfk_post(real scalar NN, real scalar TT,
                    real matrix ymat, real matrix xmat,
                    real scalar ssr_out, real colvector bhat_out,
                    real colvector sehat_out)
{
    real scalar K, i, t, row
    real matrix OX, X_tot
    real colvector Y_vec, Yhat, res
    real matrix xi_mat, Omega, Phi, S_mat
    
    K = cols(xmat) / NN
    
    // Stack into (N*T) x K
    OX = J(TT * NN, K, 0)
    Y_vec = J(TT * NN, 1, 0)
    for (i = 1; i <= NN; i++) {
        for (t = 1; t <= TT; t++) {
            row = (i-1)*TT + t
            Y_vec[row] = ymat[t, i]
            if (K == 1) OX[row, 1] = xmat[t, i]
            else OX[row, .] = xmat[t, ((i-1)*K+1)..(i*K)]
        }
    }
    
    // Individual-specific OLS
    X_tot = J(TT * NN, K * NN, 0)
    for (i = 1; i <= NN; i++) {
        for (t = 1; t <= TT; t++) {
            row = (i-1)*TT + t
            X_tot[row, ((i-1)*K+1)..(i*K)] = OX[row, .]
        }
    }
    
    bhat_out = lusolve(cross(X_tot, X_tot), cross(X_tot, Y_vec))
    
    // Predict
    Yhat = X_tot * bhat_out
    res = Y_vec - Yhat
    ssr_out = cross(res, res) / (NN * TT)
    
    // Standard errors
    xi_mat = res :* X_tot
    Omega = cross(xi_mat, xi_mat) / (NN * TT)
    Phi = luinv(cross(X_tot, X_tot) / (NN * TT))
    S_mat = Phi * Omega * Phi' / (TT * NN)
    sehat_out = sqrt(diagonal(S_mat))
}

// ====================================================================
// SARA: Screening and Ranking Algorithm (Li et al. 2025)
// Static panel: covariance estimation + local statistic
// ====================================================================
void _xtbm_sara_static(real colvector Y, real matrix X, real scalar NN,
                       real scalar TT, real colvector bandwidths,
                       real scalar c1_tuning, real scalar alpha_thresh,
                       real colvector est_breaks, real scalar est_nbreaks)
{
    real scalar p, h, t, nb, bw_idx, i, s, is_local_max, tp
    real scalar row, threshold, J, ii, jj, in_filt, too_close, cnt_p
    real scalar best_ic, n_cand, ssr_0, ic_0, ssr_j, ic_j
    real matrix beta_local_L, beta_local_R, X_dm, XX_L, XX_R
    real colvector Ds_stat, local_max_idx, Y_dm, XY_L, XY_R, diff_beta
    real colvector ymean_i, stat_vals, filtered
    real rowvector xmean_i
    real matrix all_candidates
    real matrix alpha_0, se_0, alpha_j, se_j
    real colvector reg_0, reg_j, picked, order_idx
    real scalar cand_t
    
    p = cols(X)
    
    // Demean for fixed effects
    X_dm = J(rows(X), p, 0)
    Y_dm = J(rows(Y), 1, 0)
    for (i = 1; i <= NN; i++) {
        ymean_i = mean(Y[((i-1)*TT+1)..(i*TT)])
        xmean_i = mean(X[((i-1)*TT+1)..(i*TT), .])
        for (t = 1; t <= TT; t++) {
            Y_dm[(i-1)*TT + t] = Y[(i-1)*TT + t] - ymean_i
            X_dm[(i-1)*TT + t, .] = X[(i-1)*TT + t, .] - xmean_i
        }
    }
    
    // Collect candidate breaks across all bandwidths
    all_candidates = J(0, 2, .)
    
    for (bw_idx = 1; bw_idx <= rows(bandwidths); bw_idx++) {
        h = bandwidths[bw_idx]
        
        // Compute local statistic Ds(t,h) for each t
        Ds_stat = J(TT, 1, 0)
        
        for (t = h + 1; t <= TT - h; t++) {
            // Left window (t-h, t]: estimate beta
            XX_L = J(p, p, 0)
            XY_L = J(p, 1, 0)
            XX_R = J(p, p, 0)
            XY_R = J(p, 1, 0)
            
            for (s = t - h + 1; s <= t; s++) {
                for (i = 1; i <= NN; i++) {
                    row = (i-1)*TT + s
                    XX_L = XX_L + X_dm[row, .]' * X_dm[row, .]
                    XY_L = XY_L + X_dm[row, .]' * Y_dm[row]
                }
            }
            for (s = t + 1; s <= t + h; s++) {
                for (i = 1; i <= NN; i++) {
                    row = (i-1)*TT + s
                    XX_R = XX_R + X_dm[row, .]' * X_dm[row, .]
                    XY_R = XY_R + X_dm[row, .]' * Y_dm[row]
                }
            }
            
            beta_local_L = lusolve(XX_L, XY_L)
            beta_local_R = lusolve(XX_R, XY_R)
            
            // Local statistic: sqrt(N) * (beta_R - beta_L)
            diff_beta = sqrt(NN) * (beta_local_R - beta_local_L)
            Ds_stat[t] = max(abs(diff_beta))
        }
        
        // Find h-local maximizers
        for (t = h + 1; t <= TT - h; t++) {
            is_local_max = 1
            for (tp = max((h+1, t - h + 1)); tp <= min((TT - h, t + h - 1)); tp++) {
                if (tp != t & Ds_stat[tp] >= Ds_stat[t]) {
                    is_local_max = 0
                }
            }
            if (is_local_max & Ds_stat[t] > 0) {
                all_candidates = all_candidates \ (t, Ds_stat[t])
            }
        }
    }
    
    if (rows(all_candidates) == 0) {
        est_breaks = J(0, 1, .)
        est_nbreaks = 0
        return
    }
    
    // Threshold: median of local statistic values
    stat_vals = all_candidates[., 2]
    threshold = _xtbm_median(stat_vals)
    
    // Filter by threshold
    filtered = J(0, 1, .)
    for (i = 1; i <= rows(all_candidates); i++) {
        if (all_candidates[i, 2] > threshold) {
            filtered = filtered \ all_candidates[i, 1]
        }
    }
    
    // Remove duplicates (keep unique, sorted)
    if (rows(filtered) > 0) {
        filtered = uniqrows(filtered)
    }
    
    if (rows(filtered) == 0) {
        est_breaks = J(0, 1, .)
        est_nbreaks = 0
        return
    }
    
    // IC-based final selection
    n_cand = rows(filtered)
    
    // Try J=0,1,...,n_cand breaks, pick best IC
    best_ic = 1e15
    est_nbreaks = 0
    est_breaks = J(0, 1, .)
    
    for (J = 0; J <= min((n_cand, 10)); J++) {
        if (J == 0) {
            // No breaks
            reg_0 = (1 \ TT + 1)
            _xtbm_post_pls(Y, X, NN, reg_0, alpha_0, ssr_0, se_0)
            ic_0 = ssr_0 / (NN * (TT - 1)) + c1_tuning * ln(NN * TT) / sqrt(NN * TT) * (1)
            if (ic_0 < best_ic) {
                best_ic = ic_0
                est_nbreaks = 0
                est_breaks = J(0, 1, .)
            }
        }
        else {
            // Greedy: pick top J by statistic magnitude
            order_idx = order(stat_vals, -1)
            
            picked = J(0, 1, .)
            cnt_p = 0
            for (ii = 1; ii <= rows(all_candidates) & cnt_p < J; ii++) {
                cand_t = all_candidates[order_idx[ii], 1]
                in_filt = 0
                for (jj = 1; jj <= rows(filtered); jj++) {
                    if (filtered[jj] == cand_t) in_filt = 1
                }
                if (in_filt) {
                    too_close = 0
                    for (jj = 1; jj <= rows(picked); jj++) {
                        if (abs(picked[jj] - cand_t) < 2) too_close = 1
                    }
                    if (!too_close) {
                        picked = picked \ cand_t
                        cnt_p++
                    }
                }
            }
            
            if (rows(picked) == J) {
                picked = sort(picked, 1)
                reg_j = 1 \ picked \ (TT + 1)
                _xtbm_post_pls(Y, X, NN, reg_j, alpha_j, ssr_j, se_j)
                ic_j = ssr_j / (NN * (TT - 1)) + c1_tuning * ln(NN * TT) / sqrt(NN * TT) * (J + 1) * p
                if (ic_j < best_ic) {
                    best_ic = ic_j
                    est_nbreaks = J
                    est_breaks = picked
                }
            }
        }
    }
}

real scalar _xtbm_median(real colvector x)
{
    real colvector sx
    real scalar n
    sx = sort(x, 1)
    n = rows(sx)
    if (mod(n, 2) == 1) return(sx[ceil(n/2)])
    return((sx[n/2] + sx[n/2 + 1]) / 2)
}

// ====================================================================  
// SARA: Dynamic panel (GMM-based)
// ====================================================================
void _xtbm_sara_dynamic(real colvector Y, real matrix X, real scalar NN,
                        real scalar TT, real colvector bandwidths,
                        real scalar c2_tuning, real scalar alpha_thresh,
                        real colvector est_breaks, real scalar est_nbreaks)
{
    // For dynamic panels, first-difference then apply SaRa
    real scalar p, K_total, i, t, row_out, row_in1, row_in0
    real colvector dY
    real matrix dX
    
    p = cols(X)
    K_total = p + 1
    
    // First difference
    dY = J(NN * (TT - 1), 1, 0)
    dX = J(NN * (TT - 1), p, 0)
    
    for (i = 1; i <= NN; i++) {
        for (t = 2; t <= TT; t++) {
            row_out = (i-1)*(TT-1) + (t-1)
            row_in1 = (i-1)*TT + t
            row_in0 = (i-1)*TT + t - 1
            dY[row_out] = Y[row_in1] - Y[row_in0]
            dX[row_out, .] = X[row_in1, .] - X[row_in0, .]
        }
    }
    
    // Apply static SaRa on differenced data
    _xtbm_sara_static(dY, dX, NN, TT - 1, bandwidths, c2_tuning,
                      alpha_thresh, est_breaks, est_nbreaks)
    
    // Adjust break dates back to original time scale
    if (est_nbreaks > 0) {
        est_breaks = est_breaks :+ 1
    }
}

// ====================================================================
// HAUSDORFF: Distance between break date sets
// ====================================================================
real scalar _xtbm_hausdorff(real colvector est_reg, real colvector true_reg)
{
    real scalar i, j, n_est, n_true
    real scalar max_d1, max_d2, min_d
    
    n_est = rows(est_reg)
    n_true = rows(true_reg)
    
    if (n_est == 0 | n_true == 0) return(0)
    
    // D(est, true) = max over true of min over est
    max_d1 = 0
    for (j = 1; j <= n_true; j++) {
        min_d = 1e10
        for (i = 1; i <= n_est; i++) {
            if (abs(est_reg[i] - true_reg[j]) < min_d) {
                min_d = abs(est_reg[i] - true_reg[j])
            }
        }
        if (min_d > max_d1) max_d1 = min_d
    }
    
    // D(true, est) = max over est of min over true
    max_d2 = 0
    for (i = 1; i <= n_est; i++) {
        min_d = 1e10
        for (j = 1; j <= n_true; j++) {
            if (abs(est_reg[i] - true_reg[j]) < min_d) {
                min_d = abs(est_reg[i] - true_reg[j])
            }
        }
        if (min_d > max_d2) max_d2 = min_d
    }
    
    return(max(max_d1 \ max_d2))
}

// ====================================================================
// BIC for group selection (Eq. 7 from Okui & Wang 2021)
// ====================================================================
real scalar _xtbm_bic_groups(real colvector Y, real matrix X,
                            real scalar NN, real scalar TT,
                            real scalar G, real scalar np_G,
                            real scalar sigma2,
                            real matrix est_alpha_info)
{
    real scalar ssr, bic_val, n
    n = NN * TT
    
    // SSR from est_alpha_info
    ssr = 0 // placeholder - computed from residuals
    bic_val = ssr / n + sigma2 * (np_G + NN) / (n) * ln(n)
    return(bic_val)
}

end
