*! _2snardl_mata.do
*! Mata routines for twostep_nardl
*! Based on Cho, Greenwood-Nimmo & Shin (2019)
*! Two-Step Estimation of the NARDL Model

version 14

// Drop existing definitions to allow re-sourcing
capture mata: mata drop _2snardl_psum()
capture mata: mata drop _2snardl_neweywest()
capture mata: mata drop _2snardl_fmols()
capture mata: mata drop _2snardl_fmtols()
capture mata: mata drop _2snardl_wald_lr_k1()
capture mata: mata drop _2snardl_wald_general()
capture mata: mata drop _2snardl_wald_sr()
capture mata: mata drop _2snardl_dynmult()
capture mata: mata drop _2snardl_optimlag()
capture mata: mata drop _2snardl_run_step1_k1()
capture mata: mata drop _2snardl_run_step1_kn()
capture mata: mata drop _2snardl_run_wald_lr_k1()
capture mata: mata drop _2snardl_run_wald_lr_kn()
capture mata: mata drop _2snardl_run_wald_sr()
capture mata: mata drop _2snardl_run_dynmult()
capture mata: mata drop _2snardl_hacresult()
capture mata: mata drop _2snardl_fmols_result()
capture mata: mata drop _2snardl_fmtols_result()
capture mata: mata drop _2snardl_wald_result()

// ============================================================================
// PARTIAL SUM DECOMPOSITION
// ============================================================================
mata:
mata set matastrict on

void _2snardl_psum(string scalar xvar, string scalar touse, ///
                   string scalar posvar, string scalar negvar, ///
                   real scalar threshold)
{
    real colvector x, dx, xpos, xneg
    real scalar T, i

    x = st_data(., xvar, touse)
    T = rows(x)

    dx   = J(T, 1, 0)
    xpos = J(T, 1, 0)
    xneg = J(T, 1, 0)

    dx[1] = 0
    for (i = 2; i <= T; i++) {
        dx[i] = x[i] - x[i-1]
    }

    xpos[1] = max((dx[1] - threshold, 0))
    xneg[1] = min((dx[1] - threshold, 0))
    for (i = 2; i <= T; i++) {
        xpos[i] = xpos[i-1] + max((dx[i] - threshold, 0))
        xneg[i] = xneg[i-1] + min((dx[i] - threshold, 0))
    }

    st_store(., posvar, touse, xpos)
    st_store(., negvar, touse, xneg)
}

end


// ============================================================================
// NEWEY-WEST HAC COVARIANCE ESTIMATOR
// ============================================================================
mata:
mata set matastrict on

struct _2snardl_hacresult {
    real matrix Sigma
    real matrix Pi
}

struct _2snardl_hacresult scalar _2snardl_neweywest(real matrix G, ///
                                                    real scalar bw)
{
    real scalar T, m, ell, kk
    real scalar omega_k
    real matrix Gamma0, Gamma_k, Sigma, Pi
    struct _2snardl_hacresult scalar result

    T = rows(G)
    m = cols(G)

    if (bw <= 0) {
        ell = floor(T^0.25)
    }
    else {
        ell = bw
    }

    G = G :- mean(G)

    Gamma0 = cross(G, G) / T
    Sigma = Gamma0
    Pi = Gamma0

    for (kk = 1; kk <= ell; kk++) {
        Gamma_k = cross(G[1::T-kk, .], G[kk+1::T, .]) / T
        omega_k = 1 - kk / (1 + ell)

        Sigma = Sigma + omega_k * (Gamma_k + Gamma_k')
        Pi = Pi + Gamma_k'
    }

    result.Sigma = Sigma
    result.Pi    = Pi

    return(result)
}

end


// ============================================================================
// FM-OLS ESTIMATOR (k=1 decomposed variable, + optional linear variables)
// ============================================================================
mata:
mata set matastrict on

struct _2snardl_fmols_result {
    real colvector beta_lr
    real colvector beta_lin
    real matrix    V_lr
    real matrix    V_lin
    real matrix    V_lr_full
    real scalar    alpha
    real scalar    lambda
    real scalar    eta
    real colvector rho_vec
    real matrix    V_rho
    real scalar    tau2
    real colvector uhat
    real colvector ect
    real scalar    method
    real scalar    n_lin
}

struct _2snardl_fmols_result scalar _2snardl_fmols(real colvector y, ///
                                                     real colvector xpos, ///
                                                     real colvector x, ///
                                                     real colvector xneg, ///
                                                     real matrix    zlin, ///
                                                     real scalar    use_fmols, ///
                                                     real scalar    bw)
{
    struct _2snardl_fmols_result scalar result
    struct _2snardl_hacresult scalar hac

    real scalar T, i, n_lin, n_nonstat
    real matrix Q, QQ, QQinv
    real colvector rho_hat, uhat
    real matrix G
    real colvector dx
    real matrix dz
    real matrix Sigma_hat, Pi_hat
    real matrix Sigma11, sigma12_vec, sigma21_vec
    real scalar sigma22_sc
    real colvector y_tilde
    real colvector nu_hat
    real matrix S
    real colvector Qy_adj
    real matrix J_delta

    T = rows(y)
    n_lin = cols(zlin)
    result.n_lin = n_lin

    // Build Q matrix: [1, x_pos, x, z1, ..., zm]
    Q = J(T, 1, 1), xpos, x
    if (n_lin > 0) {
        Q = Q, zlin
    }

    // OLS estimate
    QQ    = cross(Q, Q)
    QQinv = invsym(QQ)
    rho_hat = QQinv * cross(Q, y)

    // Residuals
    uhat = y - Q * rho_hat

    // First differences of x (the original asymmetric variable)
    dx    = J(T, 1, 0)
    dx[1] = 0
    for (i = 2; i <= T; i++) {
        dx[i] = x[i] - x[i-1]
    }

    // First differences of linear variables
    if (n_lin > 0) {
        dz = J(T, n_lin, 0)
        for (i = 2; i <= T; i++) {
            dz[i, .] = zlin[i, .] - zlin[i-1, .]
        }
    }

    if (use_fmols == 0) {
        // ---- OLS only ----
        result.alpha   = rho_hat[1]
        result.lambda  = rho_hat[2]
        result.eta     = rho_hat[3]
        result.rho_vec = rho_hat
        result.tau2    = variance(uhat)
        result.V_rho   = result.tau2 * QQinv
        result.method  = 1
    }
    else {
        // ---- FM-OLS ----
        // G matrix: [dx, dz1, ..., dzm, uhat]
        // Non-stationary directions: x, z1, ..., zm
        n_nonstat = 1 + n_lin
        G = dx
        if (n_lin > 0) {
            G = G, dz
        }
        G = G, uhat

        hac = _2snardl_neweywest(G, bw)
        Sigma_hat = hac.Sigma
        Pi_hat    = hac.Pi

        // Partition: first n_nonstat cols are non-stationary, last col is u
        Sigma11 = Sigma_hat[1::n_nonstat, 1::n_nonstat]
        sigma12_vec = Sigma_hat[1::n_nonstat, n_nonstat+1]
        sigma21_vec = Sigma_hat[n_nonstat+1, 1::n_nonstat]'
        sigma22_sc  = Sigma_hat[n_nonstat+1, n_nonstat+1]

        // FM-adjusted dependent variable
        // G_nonstat = [dx, dz] ; projection removes endogeneity
        y_tilde = y - (G[., 1::n_nonstat]) * invsym(Sigma11) * sigma12_vec

        // Bias correction vector
        nu_hat = Pi_hat[1::n_nonstat, n_nonstat+1] - Pi_hat[1::n_nonstat, 1::n_nonstat] * invsym(Sigma11) * sigma12_vec

        // Selection matrix: maps Q [1, xpos, x, z1, ..., zm] to the non-stationary part
        // Non-stationary regressors are x (col 3), z1 (col 4), ..., zm (col 3+n_lin)
        // S is n_nonstat x (3+n_lin) mapping
        S = J(n_nonstat, 2, 0), I(n_nonstat)

        // FM-OLS estimator
        Qy_adj  = cross(Q, y_tilde) - T * S' * nu_hat
        rho_hat = QQinv * Qy_adj

        // Long-run variance tau^2
        result.tau2 = sigma22_sc - sigma21_vec' * invsym(Sigma11) * sigma12_vec

        result.alpha   = rho_hat[1]
        result.lambda  = rho_hat[2]
        result.eta     = rho_hat[3]
        result.rho_vec = rho_hat
        result.V_rho   = result.tau2 * QQinv
        result.method  = 2

        // Recompute residuals with FM-OLS estimates
        uhat = y - Q * rho_hat
    }

    // Recover beta_pos = lambda + eta, beta_neg = eta
    result.beta_lr = (rho_hat[2] + rho_hat[3] \ rho_hat[3])

    // VCE for (beta_pos, beta_neg) via delta method
    // rho = [alpha, lambda, eta, gamma1, ..., gamma_m]
    // beta_pos = lambda + eta => d/d_alpha=0, d/d_lambda=1, d/d_eta=1, d/d_gamma_i=0
    // beta_neg = eta          => d/d_alpha=0, d/d_lambda=0, d/d_eta=1, d/d_gamma_i=0
    J_delta = (0, 1, 1, J(1, n_lin, 0) \ 0, 0, 1, J(1, n_lin, 0))
    result.V_lr = J_delta * result.V_rho * J_delta'

    // Linear variable LR coefficients: gamma_1, ..., gamma_m
    if (n_lin > 0) {
        result.beta_lin = rho_hat[4::3+n_lin]
        // VCE for linear variable LR coefficients
        // J_lin maps rho to gamma: zeros for [alpha, lambda, eta], I for [gamma]
        result.V_lin = result.V_rho[4::3+n_lin, 4::3+n_lin]
    }
    else {
        result.beta_lin = J(0, 1, 0)
        result.V_lin = J(0, 0, 0)
    }

    // Full LR VCE: [beta_pos, beta_neg, gamma1, ..., gamma_m]
    if (n_lin > 0) {
        // J_full: maps rho_vec to [beta_pos, beta_neg, gamma1, ..., gamma_m]
        result.V_lr_full = (J_delta \ (J(n_lin, 3, 0), I(n_lin))) * result.V_rho * (J_delta \ (J(n_lin, 3, 0), I(n_lin)))'
    }
    else {
        result.V_lr_full = result.V_lr
    }

    result.uhat = uhat

    // ECT = y - alpha - beta_pos * x_pos - beta_neg * x_neg - gamma' * z
    result.ect = y :- rho_hat[1] :- result.beta_lr[1] * xpos :- result.beta_lr[2] * xneg
    if (n_lin > 0) {
        result.ect = result.ect :- zlin * result.beta_lin
    }

    return(result)
}

end


// ============================================================================
// FM-TOLS ESTIMATOR (k>1 decomposed variables, + optional linear variables)
// ============================================================================
mata:
mata set matastrict on

struct _2snardl_fmtols_result {
    real matrix    beta_pos
    real matrix    beta_neg
    real colvector beta_lin
    real matrix    V_lr
    real matrix    V_lin
    real matrix    V_lr_full
    real colvector rho_vec
    real matrix    V_rho
    real scalar    tau2
    real colvector uhat
    real colvector ect
    real scalar    method
    real scalar    n_lin
}

struct _2snardl_fmtols_result scalar _2snardl_fmtols( ///
    real colvector y, ///
    real matrix xpos, ///
    real matrix x, ///
    real matrix xneg, ///
    real matrix zlin, ///
    real scalar use_fm, ///
    real scalar bw)
{
    struct _2snardl_fmtols_result scalar result
    struct _2snardl_hacresult scalar hac

    real scalar T, kk, n_lin, i, n_nonstat
    real colvector tt
    real matrix mhat, dmhat, dx, dz
    real matrix R, RR, RRinv
    real colvector rho_hat, uhat
    real matrix G
    real matrix Sigma_bar, Pi_bar
    real matrix Sigma11
    real colvector sigma12_vec, sigma21_vec
    real scalar sigma22_sc
    real colvector y_bar, nu_bar
    real matrix Sbar, ell_t
    real colvector Ry_adj
    real colvector xp_i
    real scalar mu_hat_i, denom
    real colvector lambda_hat, eta_hat
    real matrix J_delta

    T = rows(y)
    kk = cols(xpos)
    n_lin = cols(zlin)
    result.n_lin = n_lin

    // --- Step 1a: Detrend x_pos ---
    tt = (1::T)
    mhat = J(T, kk, 0)

    for (i = 1; i <= kk; i++) {
        xp_i = xpos[., i]
        denom = cross(tt, tt)
        mu_hat_i = cross(tt, xp_i) / denom
        mhat[., i] = xp_i :- mu_hat_i * tt
    }

    // First differences
    dmhat = J(T, kk, 0)
    dx    = J(T, kk, 0)
    for (i = 2; i <= T; i++) {
        dmhat[i, .] = mhat[i, .] - mhat[i-1, .]
        dx[i, .]    = x[i, .] - x[i-1, .]
    }

    // First differences of linear variables
    if (n_lin > 0) {
        dz = J(T, n_lin, 0)
        for (i = 2; i <= T; i++) {
            dz[i, .] = zlin[i, .] - zlin[i-1, .]
        }
    }

    // --- Step 1b: Build regressor matrix R = [1, t, m_hat, x, z] ---
    R = J(T, 1, 1), tt, mhat, x
    if (n_lin > 0) {
        R = R, zlin
    }

    // OLS
    RR    = cross(R, R)
    RRinv = invsym(RR)
    rho_hat = RRinv * cross(R, y)
    uhat = y - R * rho_hat

    // Non-stationary directions: dmhat (kk cols), dx (kk cols), dz (n_lin cols)
    n_nonstat = 2*kk + n_lin

    if (use_fm == 0) {
        result.tau2   = variance(uhat)
        result.V_rho  = result.tau2 * RRinv
        result.method = 3
    }
    else {
        G = dmhat, dx
        if (n_lin > 0) {
            G = G, dz
        }
        G = G, uhat

        hac = _2snardl_neweywest(G, bw)
        Sigma_bar = hac.Sigma
        Pi_bar    = hac.Pi

        Sigma11     = Sigma_bar[1::n_nonstat, 1::n_nonstat]
        sigma12_vec = Sigma_bar[1::n_nonstat, n_nonstat+1]
        sigma21_vec = Sigma_bar[n_nonstat+1, 1::n_nonstat]'
        sigma22_sc  = Sigma_bar[n_nonstat+1, n_nonstat+1]

        ell_t = dmhat, dx
        if (n_lin > 0) {
            ell_t = ell_t, dz
        }

        y_bar = y - ell_t * invsym(Sigma11) * sigma12_vec

        nu_bar = Pi_bar[1::n_nonstat, n_nonstat+1] - Pi_bar[1::n_nonstat, 1::n_nonstat] * invsym(Sigma11) * sigma12_vec

        // Sbar maps R cols to non-stationary directions
        // R = [1, t, m_hat(kk), x(kk), z(n_lin)]
        // Non-stat regressors start at col 3: m_hat(kk), x(kk), z(n_lin) = 2*kk+n_lin cols
        Sbar = J(n_nonstat, 2, 0), I(n_nonstat)

        Ry_adj  = cross(R, y_bar) - T * Sbar' * nu_bar
        rho_hat = RRinv * Ry_adj
        uhat    = y - R * rho_hat

        result.tau2   = sigma22_sc - sigma21_vec' * invsym(Sigma11) * sigma12_vec
        result.V_rho  = result.tau2 * RRinv
        result.method = 4
    }

    result.rho_vec = rho_hat

    // rho_hat = [alpha, trend, lambda_1..lambda_kk, eta_1..eta_kk, gamma_1..gamma_n_lin]
    // positions: 1=alpha, 2=trend, 3..2+kk=lambda, 3+kk..2+2*kk=eta, 3+2*kk..2+2*kk+n_lin=gamma
    lambda_hat = rho_hat[3::2+kk]
    eta_hat    = rho_hat[3+kk::2+2*kk]

    result.beta_pos = lambda_hat + eta_hat
    result.beta_neg = eta_hat

    // Linear variable LR coefficients
    if (n_lin > 0) {
        result.beta_lin = rho_hat[3+2*kk::2+2*kk+n_lin]
    }
    else {
        result.beta_lin = J(0, 1, 0)
    }

    // Delta method for VCE of [beta_pos, beta_neg]
    // J_delta maps rho to [beta_pos, beta_neg]:
    //   beta_pos_i = lambda_i + eta_i
    //   beta_neg_i = eta_i
    // rho has 2+2*kk+n_lin elements
    J_delta = J(kk, 1, 0), J(kk, 1, 0), I(kk), I(kk), J(kk, n_lin, 0) \ ///
              J(kk, 1, 0), J(kk, 1, 0), J(kk, kk, 0), I(kk), J(kk, n_lin, 0)
    result.V_lr = J_delta * result.V_rho * J_delta'

    // VCE for linear variables
    if (n_lin > 0) {
        result.V_lin = result.V_rho[3+2*kk::2+2*kk+n_lin, 3+2*kk::2+2*kk+n_lin]
    }
    else {
        result.V_lin = J(0, 0, 0)
    }

    // Full LR VCE: [beta_pos, beta_neg, gamma]
    if (n_lin > 0) {
        result.V_lr_full = (J_delta \ (J(n_lin, 2, 0), J(n_lin, 2*kk, 0), I(n_lin))) * result.V_rho * (J_delta \ (J(n_lin, 2, 0), J(n_lin, 2*kk, 0), I(n_lin)))'
    }
    else {
        result.V_lr_full = result.V_lr
    }

    result.uhat = uhat

    // ECT = y - alpha - beta_pos' * x_pos - beta_neg' * x_neg - gamma' * z
    result.ect = y :- rho_hat[1] :- xpos * result.beta_pos :- xneg * result.beta_neg
    if (n_lin > 0) {
        result.ect = result.ect :- zlin * result.beta_lin
    }

    return(result)
}

end


// ============================================================================
// WALD TEST FOR SYMMETRY
// ============================================================================
mata:
mata set matastrict on

struct _2snardl_wald_result {
    real scalar W
    real scalar df
    real scalar p
}

struct _2snardl_wald_result scalar _2snardl_wald_lr_k1( ///
    real scalar lambda_hat, ///
    real scalar V_lambda, ///
    real scalar r)
{
    struct _2snardl_wald_result scalar result

    result.W  = (lambda_hat - r)^2 / V_lambda
    result.df = 1
    result.p  = 1 - chi2(1, result.W)

    return(result)
}

struct _2snardl_wald_result scalar _2snardl_wald_general( ///
    real colvector theta_hat, ///
    real matrix    V_theta, ///
    real matrix    R_sel, ///
    real colvector r)
{
    struct _2snardl_wald_result scalar result
    real colvector diff
    real matrix    meat

    diff = R_sel * theta_hat - r
    meat = R_sel * V_theta * R_sel'
    result.W  = diff' * invsym(meat) * diff
    result.df = rows(R_sel)
    result.p  = 1 - chi2(result.df, result.W)

    return(result)
}

// SR Wald test: accounts for linear variable coefficients in the SR vector
// SR coefficient vector layout:
//   [ECT, L1.Dy, ..., Lp.Dy,
//    D.xpos1, ..., L(q-1).D.xpos_k, D.xneg1, ..., L(q-1).D.xneg_k,
//    D.z1, ..., L(r-1).D.z_m,
//    exog, _cons]
// n_lin_sr = total number of linear variable SR coefficients
struct _2snardl_wald_result scalar _2snardl_wald_sr( ///
    real colvector zeta_hat, ///
    real matrix    V_zeta, ///
    real scalar    p_lag, ///
    real scalar    q_lag, ///
    real scalar    kk, ///
    real scalar    n_lin_sr, ///
    string scalar  test_type)
{
    struct _2snardl_wald_result scalar result

    real scalar n_params, idx_pi_pos_start, idx_pi_neg_start
    real matrix R_sel
    real colvector r
    real matrix block_pos, block_neg
    real scalar ii, jj

    n_params = cols(V_zeta)
    // Positions: 1=ECT, 2..1+p_lag=lagged Dy, then pi_pos, pi_neg, lin_sr, exog, _cons
    idx_pi_pos_start = 1 + p_lag + 1
    idx_pi_neg_start = idx_pi_pos_start + q_lag * kk

    if (test_type == "additive") {
        R_sel = J(kk, 1 + p_lag, 0)
        block_pos = J(kk, q_lag*kk, 0)
        block_neg = J(kk, q_lag*kk, 0)
        for (ii = 1; ii <= kk; ii++) {
            for (jj = 0; jj < q_lag; jj++) {
                block_pos[ii, jj*kk + ii] = 1
                block_neg[ii, jj*kk + ii] = -1
            }
        }
        R_sel = R_sel, block_pos, block_neg
        r = J(kk, 1, 0)
    }
    else if (test_type == "impact") {
        R_sel = J(kk, 1 + p_lag, 0)
        block_pos = J(kk, q_lag*kk, 0)
        block_neg = J(kk, q_lag*kk, 0)
        for (ii = 1; ii <= kk; ii++) {
            block_pos[ii, ii] = 1
            block_neg[ii, ii] = -1
        }
        R_sel = R_sel, block_pos, block_neg
        r = J(kk, 1, 0)
    }
    else {
        R_sel = J(q_lag*kk, 1 + p_lag, 0)
        R_sel = R_sel, I(q_lag*kk), -I(q_lag*kk)
        r = J(q_lag*kk, 1, 0)
    }

    // Pad R_sel with trailing zeros for lin_sr, exog, _cons
    if (cols(R_sel) < n_params) {
        R_sel = R_sel, J(rows(R_sel), n_params - cols(R_sel), 0)
    }

    result = _2snardl_wald_general(zeta_hat, V_zeta, R_sel, r)

    return(result)
}

end


// ============================================================================
// DYNAMIC MULTIPLIER COMPUTATION
// ============================================================================
mata:
mata set matastrict on

real matrix _2snardl_dynmult(real colvector zeta_hat, ///
                              real colvector beta_lr, ///
                              real scalar    p_lag, ///
                              real scalar    q_lag, ///
                              real scalar    kk, ///
                              real scalar    H)
{
    real scalar rho, h, j, idx
    real colvector phi
    real matrix pi_pos, pi_neg
    real matrix mult_pos, mult_neg
    real matrix dy_pos, dy_neg
    real rowvector cum_pos_prev, cum_neg_prev

    rho = zeta_hat[1]

    if (p_lag > 0) {
        phi = zeta_hat[3::2+p_lag]
    }
    else {
        phi = J(0, 1, 0)
    }

    // Extract pi_pos and pi_neg as q x k matrices
    pi_pos = J(q_lag, kk, 0)
    pi_neg = J(q_lag, kk, 0)
    idx = 2 + p_lag + 1
    for (j = 1; j <= q_lag; j++) {
        pi_pos[j, .] = zeta_hat[idx::idx+kk-1]'
        idx = idx + kk
    }
    for (j = 1; j <= q_lag; j++) {
        pi_neg[j, .] = zeta_hat[idx::idx+kk-1]'
        idx = idx + kk
    }

    // Initialize
    dy_pos = J(H, kk, 0)
    dy_neg = J(H, kk, 0)

    for (h = 1; h <= H; h++) {
        if (h <= q_lag) {
            dy_pos[h, .] = dy_pos[h, .] + pi_pos[h, .]
            dy_neg[h, .] = dy_neg[h, .] + pi_neg[h, .]
        }

        for (j = 1; j <= min((p_lag, h-1)); j++) {
            dy_pos[h, .] = dy_pos[h, .] + phi[j] * dy_pos[h-j, .]
            dy_neg[h, .] = dy_neg[h, .] + phi[j] * dy_neg[h-j, .]
        }

        if (h >= 2) {
            cum_pos_prev = colsum(dy_pos[1::h-1, .])
            cum_neg_prev = colsum(dy_neg[1::h-1, .])
            dy_pos[h, .] = dy_pos[h, .] + rho * (cum_pos_prev - beta_lr[1::kk]')
            dy_neg[h, .] = dy_neg[h, .] + rho * (cum_neg_prev - beta_lr[kk+1::2*kk]')
        }
    }

    // Cumulative multipliers
    mult_pos = J(H, kk, 0)
    mult_neg = J(H, kk, 0)
    mult_pos[1, .] = dy_pos[1, .]
    mult_neg[1, .] = dy_neg[1, .]
    for (h = 2; h <= H; h++) {
        mult_pos[h, .] = mult_pos[h-1, .] + dy_pos[h, .]
        mult_neg[h, .] = mult_neg[h-1, .] + dy_neg[h, .]
    }

    return((mult_pos, mult_neg))
}

end


// ============================================================================
// LAG SELECTION (adapted from ardl)
// ============================================================================
mata:
mata set matastrict on

real rowvector _2snardl_optimlag( ///
    real matrix y_data, ///
    real matrix X_data, ///
    real matrix lagcombs, ///
    string scalar ic_type)
{
    real scalar ncombs, T, kk, i
    real scalar ic_val, ic_min, optimcomb
    real scalar sigma2, ll
    real matrix cX, cXX, cXXinv
    real colvector cXy
    real scalar ee

    ncombs = rows(lagcombs)
    T = rows(y_data)

    ic_min = .
    optimcomb = 1

    for (i = 1; i <= ncombs; i++) {
        cX = X_data
        kk = cols(cX)

        cXX    = cross(cX, cX)
        cXXinv = invsym(cXX)
        cXy    = cross(cX, y_data)

        ee = cross(y_data, y_data) - cXy' * cXXinv * cXy
        sigma2 = ee / T
        ll = T * log(2 * pi()) + T * log(sigma2) + T

        if (ic_type == "aic") {
            ic_val = ll + 2 * kk
        }
        else {
            ic_val = ll + kk * log(T)
        }

        if (ic_val < ic_min) {
            ic_min = ic_val
            optimcomb = i
        }
    }

    return(lagcombs[optimcomb, .])
}

end


// ============================================================================
// STATA-FACING WRAPPER FUNCTIONS
// Called from twostep_nardl.ado via single-line mata: statements
// ============================================================================
mata:
mata set matastrict on

// Step 1 wrapper for k=1 (FM-OLS or OLS), with optional linear variables
void _2snardl_run_step1_k1(string scalar depvar, string scalar xposvar, ///
                            string scalar xvar, string scalar xnegvar, ///
                            string scalar linvars, ///
                            string scalar touse, real scalar use_fmols, ///
                            real scalar bw, ///
                            string scalar b_lr_name, string scalar V_lr_name, ///
                            string scalar tau2_name, string scalar alpha_name, ///
                            string scalar ect_name, ///
                            string scalar b_lin_name, string scalar V_lin_name)
{
    struct _2snardl_fmols_result scalar res
    real colvector yy, xp, xx, xn
    real matrix zl

    yy = st_data(., depvar, touse)
    xp = st_data(., xposvar, touse)
    xx = st_data(., xvar, touse)
    xn = st_data(., xnegvar, touse)

    // Load linear variables (may be empty)
    if (strlen(strtrim(linvars)) > 0) {
        zl = st_data(., tokens(linvars), touse)
    }
    else {
        zl = J(rows(yy), 0, 0)
    }

    res = _2snardl_fmols(yy, xp, xx, xn, zl, use_fmols, bw)

    st_matrix(b_lr_name, res.beta_lr')
    st_matrix(V_lr_name, res.V_lr)
    st_numscalar(tau2_name, res.tau2)
    st_numscalar(alpha_name, res.alpha)
    st_store(., ect_name, touse, res.ect)

    // Store linear variable LR coefficients
    if (res.n_lin > 0) {
        st_matrix(b_lin_name, res.beta_lin')
        st_matrix(V_lin_name, res.V_lin)
    }
    else {
        st_matrix(b_lin_name, J(1, 0, 0))
        st_matrix(V_lin_name, J(0, 0, 0))
    }
}

// Step 1 wrapper for k>1 (FM-TOLS or TOLS), with optional linear variables
void _2snardl_run_step1_kn(string scalar depvar, string scalar xposvars, ///
                            string scalar xvars, string scalar xnegvars, ///
                            string scalar linvars, ///
                            string scalar touse, real scalar use_fm, ///
                            real scalar bw, ///
                            string scalar b_lr_name, string scalar V_lr_name, ///
                            string scalar tau2_name, string scalar alpha_name, ///
                            string scalar ect_name, ///
                            string scalar b_lin_name, string scalar V_lin_name)
{
    struct _2snardl_fmtols_result scalar res
    real colvector yy
    real matrix xp, xx, xn, zl

    yy = st_data(., depvar, touse)
    xp = st_data(., tokens(xposvars), touse)
    xx = st_data(., tokens(xvars), touse)
    xn = st_data(., tokens(xnegvars), touse)

    // Load linear variables (may be empty)
    if (strlen(strtrim(linvars)) > 0) {
        zl = st_data(., tokens(linvars), touse)
    }
    else {
        zl = J(rows(yy), 0, 0)
    }

    res = _2snardl_fmtols(yy, xp, xx, xn, zl, use_fm, bw)

    st_matrix(b_lr_name, (res.beta_pos \ res.beta_neg)')
    st_matrix(V_lr_name, res.V_lr)
    st_numscalar(tau2_name, res.tau2)
    st_numscalar(alpha_name, res.rho_vec[1])
    st_store(., ect_name, touse, res.ect)

    // Store linear variable LR coefficients
    if (res.n_lin > 0) {
        st_matrix(b_lin_name, res.beta_lin')
        st_matrix(V_lin_name, res.V_lin)
    }
    else {
        st_matrix(b_lin_name, J(1, 0, 0))
        st_matrix(V_lin_name, J(0, 0, 0))
    }
}

// LR Wald test wrapper for k=1
void _2snardl_run_wald_lr_k1(string scalar b_lr_name, string scalar V_lr_name, ///
                              string scalar W_name, string scalar p_name)
{
    struct _2snardl_wald_result scalar wres
    real scalar lam, Vlam

    lam  = st_matrix(b_lr_name)[1,1] - st_matrix(b_lr_name)[1,2]
    Vlam = (1, -1) * st_matrix(V_lr_name) * (1 \ -1)

    wres = _2snardl_wald_lr_k1(lam, Vlam, 0)

    st_numscalar(W_name, wres.W)
    st_numscalar(p_name, wres.p)
}

// LR Wald test wrapper for k>1
void _2snardl_run_wald_lr_kn(string scalar b_lr_name, string scalar V_lr_name, ///
                              real scalar kk, ///
                              string scalar W_name, string scalar p_name)
{
    struct _2snardl_wald_result scalar wres
    real colvector bv
    real matrix Vm, Rsel
    real colvector rv

    bv  = st_matrix(b_lr_name)'
    Vm  = st_matrix(V_lr_name)
    Rsel = I(kk), -I(kk)
    rv  = J(kk, 1, 0)

    wres = _2snardl_wald_general(bv, Vm, Rsel, rv)

    st_numscalar(W_name, wres.W)
    st_numscalar(p_name, wres.p)
}

// SR Wald test wrapper (updated to pass n_lin_sr)
void _2snardl_run_wald_sr(string scalar b_sr_name, string scalar V_sr_name, ///
                           real scalar p_lag, real scalar q_lag, real scalar kk, ///
                           real scalar n_lin_sr, ///
                           string scalar test_type, ///
                           string scalar W_name, string scalar p_name)
{
    struct _2snardl_wald_result scalar wres
    real colvector zhat
    real matrix Vz

    zhat = st_matrix(b_sr_name)'
    Vz   = st_matrix(V_sr_name)

    wres = _2snardl_wald_sr(zhat, Vz, p_lag, q_lag, kk, n_lin_sr, test_type)

    st_numscalar(W_name, wres.W)
    st_numscalar(p_name, wres.p)
}

// Dynamic multiplier wrapper
void _2snardl_run_dynmult(string scalar b_sr_name, string scalar b_lr_name, ///
                           real scalar p_lag, real scalar q_lag, ///
                           real scalar kk, real scalar H, ///
                           string scalar result_name)
{
    real colvector zeta, blr
    real matrix mult

    zeta = st_matrix(b_sr_name)'
    blr  = st_matrix(b_lr_name)'

    mult = _2snardl_dynmult(zeta, blr, p_lag, q_lag, kk, H)

    st_matrix(result_name, mult)
}

end
