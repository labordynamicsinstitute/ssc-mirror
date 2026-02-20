*! _rbfmvar_mata.ado — Mata engine for rbfmvar
*! Implements the RBFM-VAR estimator from:
*!   Chang, Y. (2000). Vector Autoregressions with Unknown Mixtures
*!   of I(0), I(1), and I(2) Components.
*!   Econometric Theory, 16(6), 905-926.
*!
*! Version 2.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com

capture mata: mata drop rbfmvar_estimate()
capture mata: mata drop _rbfm_ecm_reparameterize()
capture mata: mata drop _rbfm_ols_var()
capture mata: mata drop _rbfm_construct_vhat()
capture mata: mata drop _rbfm_kernel_weight()
capture mata: mata drop _rbfm_kernel_lrv()
capture mata: mata drop _rbfm_kernel_olrv()
capture mata: mata drop _rbfm_andrews_bandwidth()
capture mata: mata drop _rbfm_correct()
capture mata: mata drop _rbfm_wald_test()
capture mata: mata drop _rbfm_granger_test()
capture mata: mata drop _rbfm_select_lags()
capture mata: mata drop _rbfm_irf_compute()
capture mata: mata drop _rbfm_irf_bootstrap()
capture mata: mata drop _rbfm_fevd_compute()
capture mata: mata drop _rbfm_forecast_compute()
capture mata: mata drop _rbfm_ic_table()

version 14.0
mata:
mata set matastrict on

// ========================================================================
// FUNCTION: rbfmvar_estimate()
// Master orchestrator — called from Stata, posts all results
// ========================================================================

void rbfmvar_estimate(
    string scalar varnames,
    real   scalar p_lags,
    string scalar kernel_type,
    real   scalar bw_user,
    string scalar granger_spec,
    string scalar touse_name,
    real   scalar irf_horizon,
    real   scalar irf_boot_reps,
    real   scalar irf_ci_level,
    real   scalar do_fevd,
    real   scalar forecast_steps)
{
    real matrix Y_raw, Y, Z, W, X, F_ols, E_hat, V_hat
    real matrix Omega_ev, Omega_vv, Delta_vdw
    real matrix F_plus, Gamma_plus, A_plus
    real matrix Sigma_e
    real scalar T, n, nobs, bw
    string rowvector vnames
    real colvector touse_vec

    // --- Parse variable names ---
    vnames = tokens(varnames)
    n = length(vnames)

    // --- Load data ---
    touse_vec = st_data(., touse_name)
    Y_raw = st_data(., vnames)

    // Keep only touse observations
    Y_raw = select(Y_raw, touse_vec)
    nobs = rows(Y_raw)

    // --- Lag selection if requested ---
    // (p_lags is already determined by the .ado caller)

    // --- ECM reparameterization: build Z, W, Y for Eq. 3 ---
    _rbfm_ecm_reparameterize(Y_raw, p_lags, Y, Z, W)
    T = rows(Y)
    X = (Z, W)

    // --- OLS-VAR estimation of Eq. 3 ---
    _rbfm_ols_var(Y, X, Z, W, F_ols, E_hat)

    // --- Construct v_hat (Eq. 11) ---
    _rbfm_construct_vhat(Y_raw, p_lags, F_ols, X, V_hat)

    // --- Bandwidth selection ---
    if (bw_user < 0) {
        bw = _rbfm_andrews_bandwidth(V_hat, kernel_type)
    }
    else {
        bw = bw_user
    }

    // --- Kernel LRV estimation ---
    _rbfm_kernel_lrv(E_hat, V_hat, kernel_type, bw, Omega_ev, Omega_vv)

    // --- One-sided LRV ---
    real matrix dW
    dW = W[2::T, .] - W[1::(T-1), .]
    // Pad first row with zeros
    dW = (J(1, cols(W), 0) \ dW)
    _rbfm_kernel_olrv(V_hat, dW, kernel_type, bw, Delta_vdw)

    // --- RBFM-VAR correction (Eq. 12-13) ---
    _rbfm_correct(Y, Z, W, X, E_hat, V_hat, Omega_ev, Omega_vv, Delta_vdw, T, F_plus, Gamma_plus, A_plus)

    // --- Residual covariance ---
    Sigma_e = (E_hat' * E_hat) / T

    // --- Standard errors for F⁺ ---
    // Var(vec(F̂')) = Σ̂_ε ⊗ (X'X)⁻¹  (Eq. 20)
    // SE for F⁺[i,j] = sqrt( Sigma_e[i,i] * XpXinv[j,j] )
    real matrix XpXinv_post, SE_mat
    XpXinv_post = invsym(cross(X, X))
    SE_mat = J(n, cols(X), 0)
    real scalar ii, jj
    for (ii = 1; ii <= n; ii++) {
        for (jj = 1; jj <= cols(X); jj++) {
            SE_mat[ii, jj] = sqrt(Sigma_e[ii, ii] * XpXinv_post[jj, jj])
        }
    }

    // --- Post results to Stata ---
    st_matrix("r(F_ols)", F_ols)
    st_matrix("r(F_plus)", F_plus)
    st_matrix("r(Sigma_e)", Sigma_e)
    st_matrix("r(SE_mat)", SE_mat)
    st_matrix("r(Omega_ev)", Omega_ev)
    st_matrix("r(Omega_vv)", Omega_vv)
    st_matrix("r(Delta_vdw)", Delta_vdw)
    st_numscalar("r(nobs)", nobs)
    st_numscalar("r(T_eff)", T)
    st_numscalar("r(n_vars)", n)
    st_numscalar("r(p_lags)", p_lags)
    st_numscalar("r(bandwidth)", bw)

    // --- Extract Π₁ and Π₂ matrices for display ---
    // F_ols = (Γ, A) where A = (Π₁_hat, Π₂_hat)
    // W = (Δy_{t-1}', y_{t-1}')' so A has 2n columns
    real matrix Pi1_ols, Pi2_ols, Pi1_plus, Pi2_plus
    real scalar ncols_z
    ncols_z = cols(Z)

    if (cols(W) == 2*n) {
        Pi1_ols  = F_ols[., (ncols_z+1)::(ncols_z+n)]
        Pi2_ols  = F_ols[., (ncols_z+n+1)::cols(F_ols)]
        Pi1_plus = F_plus[., (ncols_z+1)::(ncols_z+n)]
        Pi2_plus = F_plus[., (ncols_z+n+1)::cols(F_plus)]
    }
    else {
        Pi1_ols  = F_ols[., (ncols_z+1)::cols(F_ols)]
        Pi2_ols  = J(n, 0, .)
        Pi1_plus = F_plus[., (ncols_z+1)::cols(F_plus)]
        Pi2_plus = J(n, 0, .)
    }

    st_matrix("r(Pi1_ols)", Pi1_ols)
    st_matrix("r(Pi2_ols)", Pi2_ols)
    st_matrix("r(Pi1_plus)", Pi1_plus)
    st_matrix("r(Pi2_plus)", Pi2_plus)

    if (ncols_z > 0) {
        st_matrix("r(Gamma_ols)", F_ols[., 1::ncols_z])
        st_matrix("r(Gamma_plus)", F_plus[., 1::ncols_z])
    }

    // --- Granger causality test ---
    if (granger_spec != "") {
        real scalar wald_stat, wald_pval, wald_df
        _rbfm_granger_test(granger_spec, vnames, F_plus, Sigma_e, X, T, n, p_lags, ncols_z, wald_stat, wald_pval, wald_df)
        st_numscalar("r(wald_stat)", wald_stat)
        st_numscalar("r(wald_pval)", wald_pval)
        st_numscalar("r(wald_df)", wald_df)
    }

    // --- IRF if requested ---
    if (irf_horizon > 0) {
        real matrix irf_mat
        _rbfm_irf_compute(F_plus, Sigma_e, n, p_lags, ncols_z, irf_horizon, irf_mat)
        st_matrix("r(irf)", irf_mat)
        st_numscalar("r(irf_horizon)", irf_horizon)

        // --- Bootstrap IRF CI ---
        if (irf_boot_reps > 0) {
            real matrix irf_lo, irf_hi
            _rbfm_irf_bootstrap(Y_raw, p_lags, kernel_type, bw, n, ncols_z, 
                irf_horizon, irf_boot_reps, irf_ci_level, irf_lo, irf_hi)
            st_matrix("r(irf_lo)", irf_lo)
            st_matrix("r(irf_hi)", irf_hi)
            st_numscalar("r(irf_ci_level)", irf_ci_level)
            st_numscalar("r(irf_boot_reps)", irf_boot_reps)
        }
    }

    // --- FEVD if requested ---
    if (do_fevd > 0 & irf_horizon > 0) {
        real matrix fevd_mat
        _rbfm_fevd_compute(F_plus, Sigma_e, n, p_lags, ncols_z, irf_horizon, fevd_mat)
        st_matrix("r(fevd)", fevd_mat)
    }

    // --- Forecast if requested ---
    if (forecast_steps > 0) {
        real matrix fcast_mat, fcast_se
        _rbfm_forecast_compute(Y_raw, F_plus, Sigma_e, n, p_lags, ncols_z, 
            forecast_steps, fcast_mat, fcast_se)
        st_matrix("r(forecast)", fcast_mat)
        st_matrix("r(forecast_se)", fcast_se)
        st_numscalar("r(forecast_steps)", forecast_steps)
    }

    // --- Store residuals for density plot ---
    st_matrix("r(residuals)", E_hat)
}


// ========================================================================
// FUNCTION: _rbfm_ecm_reparameterize()
// Reparameterize levels VAR into Eq. 3 form (Chang 2000, p.907)
//   y_t = Γ z_t + A w_t + ε_t
// Dependent: y_t (LEVELS, not differences)
// z_t = (Δ²y_{t-1},...,Δ²y_{t-p+2})' — stationary regressors
// w_t = (Δy_{t-1}', y_{t-1}')' — nonstationary regressors
// ========================================================================

void _rbfm_ecm_reparameterize(
    real matrix Y_raw,
    real scalar p,
    real matrix Y,
    real matrix Z,
    real matrix W)
{
    real scalar nobs, n, T, t, j, p_eff
    real matrix dY, d2Y

    nobs = rows(Y_raw)
    n    = cols(Y_raw)

    // First differences
    dY = Y_raw[2::nobs, .] - Y_raw[1::(nobs-1), .]

    // Second differences
    d2Y = dY[2::rows(dY), .] - dY[1::(rows(dY)-1), .]

    // Effective sample start: need Δy_{t-1} which requires dY row ≥ 1
    // dY row k = Δy at original time k+1
    // Δy_{t-1} at t_orig = p_eff + t → dY row p_eff + t - 2
    // For t=1: p_eff + 1 - 2 = p_eff - 1 ≥ 1 requires p_eff ≥ 2
    p_eff = max((p, 2))

    T = nobs - p_eff
    if (T < 10) {
        errprintf("Insufficient observations (T=%g, need at least 10)\n", T)
        exit(2001)
    }

    // Dependent variable: y_t (LEVELS per Eq. 3)
    Y = Y_raw[(p_eff+1)::nobs, .]

    // Build Z = (Δ²y_{t-1}, ..., Δ²y_{t-p+2})  [stationary regressors]
    if (p >= 3) {
        Z = J(T, n*(p-2), 0)
        for (t = 1; t <= T; t++) {
            // Original time for row t: t_orig = p_eff + t
            for (j = 1; j <= p-2; j++) {
                // Δ²y_{t-j}: d2Y row (t_orig - j - 2) = p_eff + t - j - 2
                real scalar d2_idx
                d2_idx = p_eff + t - j - 2
                if (d2_idx >= 1 & d2_idx <= rows(d2Y)) {
                    Z[t, (n*(j-1)+1)::(n*j)] = d2Y[d2_idx, .]
                }
            }
        }
    }
    else {
        Z = J(T, 0, .)
    }

    // Build W = (Δy_{t-1}', y_{t-1}')  [nonstationary regressors]
    real matrix dY_lag1, Y_lag1

    dY_lag1 = J(T, n, 0)
    Y_lag1  = J(T, n, 0)

    for (t = 1; t <= T; t++) {
        // Original time for row t of Y: t_orig = p_eff + t
        // dY row k corresponds to Δy at original time k+1
        // Δy_{t-1} at original time p_eff+t-1 → dY row p_eff+t-2
        dY_lag1[t, .] = dY[p_eff + t - 2, .]
        // y_{t-1}: Y_raw row t_orig - 1 = p_eff + t - 1
        Y_lag1[t, .] = Y_raw[p_eff + t - 1, .]
    }

    W = (dY_lag1, Y_lag1)
}


// ========================================================================
// FUNCTION: _rbfm_ols_var()
// OLS estimation of the reparameterized model (Eq. 3)
// ========================================================================

void _rbfm_ols_var(
    real matrix Y,
    real matrix X,
    real matrix Z,
    real matrix W,
    real matrix F_ols,
    real matrix E_hat)
{
    real matrix XpX, XpXinv

    XpX = cross(X, X)
    XpXinv = invsym(XpX)
    F_ols = (Y' * X) * XpXinv
    E_hat = Y - X * F_ols'
}


// ========================================================================
// FUNCTION: _rbfm_construct_vhat()
// Construct v_hat_t per Eq. 11
// v_hat_t = (Δ²y_{t-1}, Δy_{t-1} - N_hat * Δy_{t-2})'
// N_hat is OLS from: Δy_{t-1} = N * Δy_{t-2} + error
// ========================================================================

void _rbfm_construct_vhat(
    real matrix Y_raw,
    real scalar p,
    real matrix F_ols,
    real matrix X,
    real matrix V_hat)
{
    real scalar nobs, n, T, p_eff
    real matrix dY, d2Y, dY_lag1, dY_lag2, N_hat
    real matrix v1, v2
    real scalar t

    nobs = rows(Y_raw)
    n    = cols(Y_raw)
    p_eff = max((p, 2))

    // Differences
    dY  = Y_raw[2::nobs, .] - Y_raw[1::(nobs-1), .]
    d2Y = dY[2::rows(dY), .] - dY[1::(rows(dY)-1), .]

    T = rows(X)

    // Build Δy_{t-1} and Δy_{t-2} aligned to effective sample
    dY_lag1 = J(T, n, 0)
    dY_lag2 = J(T, n, 0)

    for (t = 1; t <= T; t++) {
        dY_lag1[t, .] = dY[p_eff + t - 2, .]
        if (p_eff + t - 3 >= 1) {
            dY_lag2[t, .] = dY[p_eff + t - 3, .]
        }
    }

    // OLS: Δy_{t-1} = N * Δy_{t-2} + error
    N_hat = (dY_lag1' * dY_lag2) * invsym(cross(dY_lag2, dY_lag2))

    // v1 = Δ²y_{t-1}
    v1 = J(T, n, 0)
    for (t = 1; t <= T; t++) {
        if (p_eff + t - 3 >= 1) {
            v1[t, .] = d2Y[p_eff + t - 3, .]
        }
    }

    // v2 = Δy_{t-1} - N_hat * Δy_{t-2}
    v2 = dY_lag1 - dY_lag2 * N_hat'

    // V_hat = (v1, v2) — each T x n, combined T x 2n
    V_hat = (v1, v2)
}


// ========================================================================
// FUNCTION: _rbfm_kernel_weight()
// Kernel weight function
// ========================================================================

real scalar _rbfm_kernel_weight(real scalar x, string scalar kernel)
{
    real scalar w, z

    if (kernel == "bartlett") {
        w = (abs(x) <= 1) ? (1 - abs(x)) : 0
    }
    else if (kernel == "parzen") {
        z = abs(x)
        if (z <= 0.5) {
            w = 1 - 6*z^2 + 6*z^3
        }
        else if (z <= 1) {
            w = 2*(1 - z)^3
        }
        else {
            w = 0
        }
    }
    else {
        // Quadratic Spectral (QS)
        if (x == 0) {
            w = 1
        }
        else {
            z = 6 * pi() * x / 5
            w = (25 / (12 * pi()^2 * x^2)) * (sin(z)/z - cos(z))
        }
    }

    return(w)
}


// ========================================================================
// FUNCTION: _rbfm_andrews_bandwidth()
// Andrews (1991) automatic bandwidth selection
// ========================================================================

real scalar _rbfm_andrews_bandwidth(
    real matrix V_hat,
    string scalar kernel)
{
    real scalar T, n_v, i, rho_hat, alpha_hat, bw
    real scalar num, den
    real matrix v_i
    real colvector rho_vec

    T   = rows(V_hat)
    n_v = cols(V_hat)

    // Estimate AR(1) coefficients for each component of v_hat
    num = 0
    den = 0

    for (i = 1; i <= n_v; i++) {
        v_i = V_hat[., i]
        rho_hat = (v_i[1::(T-1)]' * v_i[2::T]) / (v_i[1::(T-1)]' * v_i[1::(T-1)])
        if (abs(rho_hat) >= 1) rho_hat = 0.97 * sign(rho_hat)

        if (kernel == "bartlett") {
            num = num + 4 * rho_hat^2 / ((1 - rho_hat)^2 * (1 + rho_hat)^2)
            den = den + 1
        }
        else if (kernel == "parzen") {
            num = num + 4 * rho_hat^2 / ((1 - rho_hat)^4 * (1 + rho_hat)^4)
            den = den + 1
        }
        else {
            // QS kernel
            num = num + 4 * rho_hat^2 / ((1 - rho_hat)^4 * (1 + rho_hat)^4)
            den = den + 1
        }
    }

    alpha_hat = num / den

    if (kernel == "bartlett") {
        bw = 1.1447 * (alpha_hat * T)^(1/3)
    }
    else if (kernel == "parzen") {
        bw = 2.6614 * (alpha_hat * T)^(1/5)
    }
    else {
        // QS kernel
        bw = 1.3221 * (alpha_hat * T)^(1/5)
    }

    bw = max((bw, 1))
    bw = min((bw, T/3))

    return(bw)
}


// ========================================================================
// FUNCTION: _rbfm_kernel_lrv()
// Kernel estimates of long-run covariance matrices:
//   Omega_ev = lrvar(epsilon, v)
//   Omega_vv = lrvar(v, v)
// ========================================================================

void _rbfm_kernel_lrv(
    real matrix E_hat,
    real matrix V_hat,
    string scalar kernel,
    real scalar bw,
    real matrix Omega_ev,
    real matrix Omega_vv)
{
    real scalar T, j
    real scalar w_j
    real matrix Gamma_ev_j, Gamma_vv_j

    T = rows(E_hat)

    // Lag 0
    Omega_ev = (E_hat' * V_hat) / T
    Omega_vv = (V_hat' * V_hat) / T

    // Lags 1 to bw (or until kernel weight is negligible)
    real scalar max_lag
    if (kernel == "bartlett" | kernel == "parzen") {
        max_lag = floor(bw)
    }
    else {
        max_lag = min((floor(3 * bw), T - 1))
    }

    for (j = 1; j <= max_lag; j++) {
        w_j = _rbfm_kernel_weight(j / bw, kernel)
        if (abs(w_j) < 1e-12) continue

        // Γ_εv(j) = (1/T) Σ ε_{t+j} v_t'
        Gamma_ev_j = (E_hat[(j+1)::T, .]' * V_hat[1::(T-j), .]) / T
        // Γ_εv(-j) = (1/T) Σ ε_t v_{t+j}' = Γ_vε(j)'
        real matrix Gamma_ev_neg_j
        Gamma_ev_neg_j = (V_hat[(j+1)::T, .]' * E_hat[1::(T-j), .])' / T

        Gamma_vv_j = (V_hat[(j+1)::T, .]' * V_hat[1::(T-j), .]) / T

        // Ω_εv = Σ w(j/K) [Γ_εv(j) + Γ_εv(-j)] — correct two-sided sum
        Omega_ev = Omega_ev + w_j * (Gamma_ev_j + Gamma_ev_neg_j)
        // Ω_vv: Γ_vv(-j) = Γ_vv(j)' (same subscripts), so transpose is correct
        Omega_vv = Omega_vv + w_j * (Gamma_vv_j + Gamma_vv_j')
    }
}


// ========================================================================
// FUNCTION: _rbfm_kernel_olrv()
// One-sided long-run covariance: Delta_vdw = sum_{j=0}^{K} w(j/K) * Gamma_v,dw(j)
// This is the one-sided (forward) LRV
// ========================================================================

void _rbfm_kernel_olrv(
    real matrix V_hat,
    real matrix dW,
    string scalar kernel,
    real scalar bw,
    real matrix Delta_vdw)
{
    real scalar T, j, max_lag
    real scalar w_j
    real matrix Gamma_j

    T = rows(V_hat)

    // Lag 0
    Delta_vdw = (V_hat' * dW) / T

    if (kernel == "bartlett" | kernel == "parzen") {
        max_lag = floor(bw)
    }
    else {
        max_lag = min((floor(3 * bw), T - 1))
    }

    for (j = 1; j <= max_lag; j++) {
        w_j = _rbfm_kernel_weight(j / bw, kernel)
        if (abs(w_j) < 1e-12) continue

        // One-sided LRV: Δ̂_vΔw = Σ_{j≥0} w(j/K) · (1/T) Σ_t v̂_t · Δw_{t+j}'
        // v̂ at time t aligned with Δw at time t+j (forward)
        Gamma_j = (V_hat[1::(T-j), .]' * dW[(j+1)::T, .]) / T
        Delta_vdw = Delta_vdw + w_j * Gamma_j
    }
}


// ========================================================================
// FUNCTION: _rbfm_correct()
// Apply RBFM-VAR correction per Eq. 12-13
// F⁺ = (Y'Z, Y⁺'W - T·Â⁺)(X'X)⁻¹
//   Y⁺ = Y' - Ω̂_εv · Ω̂_vv⁻¹ · V'
//   Â⁺ = (0,I) · Δ̂_vΔw  (serial correlation)
// ========================================================================

void _rbfm_correct(
    real matrix Y,
    real matrix Z,
    real matrix W,
    real matrix X,
    real matrix E_hat,
    real matrix V_hat,
    real matrix Omega_ev,
    real matrix Omega_vv,
    real matrix Delta_vdw,
    real scalar T,
    real matrix F_plus,
    real matrix Gamma_plus,
    real matrix A_plus)
{
    real matrix Omega_vv_inv, Y_plus_t, XpXinv
    real matrix YpW_corrected
    real matrix A_correction
    real scalar n, ncols_w

    n = cols(Y)
    ncols_w = cols(W)

    // Ω̂_vv⁻¹ using Moore-Penrose (may be singular per paper)
    Omega_vv_inv = pinv(Omega_vv)

    // Y⁺' = Y' - Ω̂_εv · Ω̂_vv⁻¹ · V'
    // => Y⁺ = Y - V * (Ω̂_vv⁻¹' * Ω̂_εv')
    Y_plus_t = Y - V_hat * (Omega_vv_inv' * Omega_ev')

    // Â⁺ = (0_n x n*(p-2), I_n ⊗ [0,I]) · Δ̂_vΔw
    // Simpler: Â⁺ is n x 2n, constructed from one-sided LRV
    // The serial correction term relates v̂ to Δw
    // (0,I) selects the Δw part
    // Δ̂_vΔw is (2n x 2n) — picking n-to-2n rows gives the v₂ component
    if (ncols_w == 2*n) {
        A_correction = Delta_vdw[(n+1)::(2*n), .]
    }
    else {
        A_correction = Delta_vdw
    }

    // Y⁺'W corrected
    YpW_corrected = Y_plus_t' * W - T * A_correction

    // X'X inverse
    XpXinv = invsym(cross(X, X))

    // F⁺ = (Y'Z, Y⁺'W - T·Â⁺)(X'X)⁻¹
    // Note: Z part uses ORIGINAL Y (not corrected), per Eq. 12
    if (cols(Z) > 0) {
        F_plus = ((Y' * Z), YpW_corrected) * XpXinv
    }
    else {
        F_plus = YpW_corrected * XpXinv
    }

    // Extract components
    if (cols(Z) > 0) {
        Gamma_plus = F_plus[., 1::cols(Z)]
        A_plus     = F_plus[., (cols(Z)+1)::cols(F_plus)]
    }
    else {
        Gamma_plus = J(n, 0, .)
        A_plus     = F_plus
    }
}


// ========================================================================
// FUNCTION: _rbfm_wald_test()
// Modified Wald test W_F⁺ per Eq. 20 of Chang (2000)
// W_F⁺ = (R vec(F⁺) - r)' [R (Σ̂_ε ⊗ (X'X)⁻¹) R']⁻¹ (R vec(F⁺) - r)
// Σ̂_ε = E'E/T (usual estimator), so Var(vec(F̂)) = Σ̂_ε ⊗ (X'X)⁻¹
// Conservative p-value from χ²_q bound (Theorem 2)
// ========================================================================

void _rbfm_wald_test(
    real matrix R,
    real colvector r_vec,
    real matrix F_plus,
    real matrix Sigma_e,
    real matrix X,
    real scalar T,
    real scalar wald_stat,
    real scalar wald_pval,
    real scalar wald_df)
{
    real colvector vecF, Rf_r
    real matrix XpXinv, V_mat, V_inv

    vecF = vec(F_plus')
    Rf_r = R * vecF - r_vec

    XpXinv = invsym(cross(X, X))

    // Variance: Var(vec(F̂)) = Σ̂_ε ⊗ (X'X)⁻¹
    // where Σ̂_ε = E'E/T is the usual covariance estimator
    V_mat = R * (Sigma_e # XpXinv) * R'
    V_inv = invsym(V_mat)

    // Standard Wald: no extra T since Σ̂_ε already normalized by T
    wald_stat = Rf_r' * V_inv * Rf_r
    wald_df   = rows(R)
    wald_pval = 1 - chi2(wald_df, wald_stat)
    if (wald_pval < 0) wald_pval = 0
}


// ========================================================================
// FUNCTION: _rbfm_granger_test()
// Build R matrix for Granger non-causality and call Wald test
// Spec format: "y1 -> y2" meaning "test H₀: y1 does NOT Granger-cause y2"
// ========================================================================

void _rbfm_granger_test(
    string scalar granger_spec,
    string rowvector vnames,
    real matrix F_plus,
    real matrix Sigma_e,
    real matrix X,
    real scalar T,
    real scalar n,
    real scalar p,
    real scalar ncols_z,
    real scalar wald_stat,
    real scalar wald_pval,
    real scalar wald_df)
{
    string rowvector parts
    string scalar cause_var, effect_var
    real scalar i_cause, i_effect, i, found
    real matrix R
    real colvector r_vec
    real scalar np_total, j, row_idx

    // Parse "cause -> effect"
    parts = tokens(granger_spec)
    if (length(parts) < 3) {
        errprintf("granger() format: 'varname -> varname'\n")
        exit(198)
    }
    cause_var  = parts[1]
    effect_var = parts[3]

    // Find variable indices
    i_cause = 0
    i_effect = 0
    for (i = 1; i <= n; i++) {
        if (vnames[i] == cause_var)  i_cause  = i
        if (vnames[i] == effect_var) i_effect = i
    }

    if (i_cause == 0) {
        errprintf("Variable '%s' not found in model\n", cause_var)
        exit(198)
    }
    if (i_effect == 0) {
        errprintf("Variable '%s' not found in model\n", effect_var)
        exit(198)
    }

    // Build restriction matrix R for H₀: coefficients of cause_var in effect_var equation = 0
    // F⁺ is n x np_total (n equations × np_total regressors)
    // vecF = vec(F⁺') stacks COLUMNS of F⁺' = stacks ROWS of F⁺
    //   F⁺' is (np_total × n), so vec(F⁺') has n*np_total elements
    //   Position of F⁺[eq, reg] in vec(F⁺') = (eq-1)*np_total + reg
    //
    // We need to set to zero: for the effect equation (row i_effect of F⁺),
    // ALL columns corresponding to cause_var in Γ (Δ²y lags), Π₁, and Π₂

    np_total = cols(X)  // = ncols_z + 2*n = n*(p-2) + 2*n = n*p

    // Count restrictions:
    // - In Γ: (p-2) lags of Δ²y, each has cause_var column → (p-2) restrictions
    // - In Π₁ (Δy_{t-1}): cause_var column → 1 restriction
    // - In Π₂ (y_{t-1}): cause_var column → 1 restriction
    // Total = p restrictions

    real scalar n_restrictions, k
    n_restrictions = max((p - 2, 0)) + 2  // (p-2) from Γ (if p≥3) + 1 from Π₁ + 1 from Π₂

    R = J(n_restrictions, n * np_total, 0)
    r_vec = J(n_restrictions, 1, 0)

    // vec(F⁺') maps: element F⁺[eq, reg] -> position (eq-1)*np_total + reg
    row_idx = 0

    // Restrictions on Γ: Δ²y_{t-j} blocks for j = 1,...,p-2
    // In F⁺, Γ occupies columns 1 to ncols_z = n*(p-2)
    // Block j of Γ: columns n*(j-1)+1 to n*j contain Δ²y_{t-j}
    // Within each block, cause_var is at column n*(j-1) + i_cause
    for (k = 1; k <= p - 2; k++) {
        row_idx = row_idx + 1
        j = n * (k - 1) + i_cause
        R[row_idx, (i_effect-1)*np_total + j] = 1
    }

    // Restriction on Π₁: F⁺[i_effect, ncols_z + i_cause] = 0
    row_idx = row_idx + 1
    j = ncols_z + i_cause
    R[row_idx, (i_effect-1)*np_total + j] = 1

    // Restriction on Π₂: F⁺[i_effect, ncols_z + n + i_cause] = 0
    row_idx = row_idx + 1
    j = ncols_z + n + i_cause
    R[row_idx, (i_effect-1)*np_total + j] = 1

    // Call Wald test
    _rbfm_wald_test(R, r_vec, F_plus, Sigma_e, X, T, wald_stat, wald_pval, wald_df)
}


// ========================================================================
// FUNCTION: _rbfm_select_lags()
// Information criterion lag selection for VAR order
// ========================================================================

real scalar _rbfm_select_lags(
    real matrix Y_raw,
    real scalar max_p,
    string scalar ic_type)
{
    real scalar n, nobs, p, T, best_p
    real scalar ic_val, best_ic, logdet_sigma
    real matrix Y, Z, W, X, F_tmp, E_tmp, Sigma

    n    = cols(Y_raw)
    nobs = rows(Y_raw)
    best_ic = .
    best_p  = 1

    for (p = 1; p <= max_p; p++) {
        T = nobs - 2 - p + 2
        if (T < 3*n) continue

        _rbfm_ecm_reparameterize(Y_raw, p, Y, Z, W)
        T = rows(Y)
        X = (Z, W)

        _rbfm_ols_var(Y, X, Z, W, F_tmp, E_tmp)

        Sigma = (E_tmp' * E_tmp) / T
        logdet_sigma = ln(det(Sigma))

        if (ic_type == "aic") {
            ic_val = logdet_sigma + 2 * n^2 * p / T
        }
        else if (ic_type == "bic") {
            ic_val = logdet_sigma + n^2 * p * ln(T) / T
        }
        else {
            // HQ
            ic_val = logdet_sigma + 2 * n^2 * p * ln(ln(T)) / T
        }

        if (ic_val < best_ic | best_ic == .) {
            best_ic = ic_val
            best_p  = p
        }
    }

    return(best_p)
}


// ========================================================================
// FUNCTION: _rbfm_irf_compute()
// Impulse Response Functions from the RBFM-VAR estimates
// Uses Cholesky decomposition of Sigma for orthogonalized IRFs
// ========================================================================

void _rbfm_irf_compute(
    real matrix F_plus,
    real matrix Sigma_e,
    real scalar n,
    real scalar p,
    real scalar ncols_z,
    real scalar horizon,
    real matrix irf_mat)
{
    real matrix A_companion, J_mat, Phi_h, P_chol
    real matrix irf_h
    real scalar h, total_np, comp_dim
    real matrix Pi1, Pi2, Gamma_est
    real scalar i, k

    // Extract Γ (stationary), Π₁, and Π₂
    if (ncols_z > 0) {
        Gamma_est = F_plus[., 1::ncols_z]
    }
    Pi1 = F_plus[., (ncols_z+1)::(ncols_z+n)]
    Pi2 = F_plus[., (ncols_z+n+1)::cols(F_plus)]

    // Reconstruct levels VAR A₁,...,A_p from ECM parameters
    // The ECM form (Eq. 3) relates to the levels VAR (Eq. 1) via:
    //   Φ = Γ with Φ_k = Σ_{j=k}^{p} (j-k+1)·A_j  for k = 1,...,p-2
    //   Π₁ = -Σ_{k=2}^{p} (k-1)·A_k,  Π₂ = Σ_{k=1}^{p} A_k
    //
    // For p=1: y_t = Π₁·Δy_{t-1} + Π₂·y_{t-1} + ε_t
    //        = (Π₁+Π₂)·y_{t-1} - Π₁·y_{t-2} + ε_t  → VAR(2) in levels
    //   A₁ = Π₁ + Π₂,  A₂ = -Π₁
    //
    // For p=2: y_t = Γ₁·Δ²y_{t-1} + Π₁·Δy_{t-1} + Π₂·y_{t-1} (no Γ, ncols_z=0 here)
    //   Actually p=2 ⟹ ncols_z = 0, same as p=1 reconstruction
    //   Still: A₁ = Π₁ + Π₂,  A₂ = -Π₁
    //
    // General: recover A matrices from the definitions on p.908.
    //   A_p = (-1)^(p-1) component from the recursion.
    //   We use the cleaner approach: build the p-th order levels VAR companion.

    // For any p, the ECM Eq.3 can be inverted:
    //   y_t = (Π₁+Π₂+I)·y_{t-1} + Σ Γ contributions from higher lags
    // The most reliable approach:
    //   From Eq. 3: y_t = Γ·z_t + Π₁·Δy_{t-1} + Π₂·y_{t-1} + ε_t
    //   Substituting z_t and Δy back into levels form:
    //   The companion form always ends up being p+1 dimensional in levels.

    // Direct reconstruction for the general case:
    // The ECM form with Δ²y lags gives a levels VAR of order p+1:
    //   y_t = A₁·y_{t-1} + A₂·y_{t-2} + ... + A_{p+1}·y_{t-(p+1)} + ε_t
    // We can derive A matrices by collecting terms.
    //
    // Simpler: note that ECM Eq. 3 is:
    //   y_t = [Γ₁,...,Γ_{p-2}] · [Δ²y_{t-1},...,Δ²y_{t-p+2}]' + Π₁·Δy_{t-1} + Π₂·y_{t-1} + ε_t
    //
    // Expanding Δ²y_{t-j} = y_{t-j} - 2·y_{t-j-1} + y_{t-j-2} and Δy_{t-1} = y_{t-1} - y_{t-2}:
    //   y_t = Σ_{j=1}^{p-2} Γ_j·(y_{t-j} - 2·y_{t-j-1} + y_{t-j-2}) + Π₁·(y_{t-1} - y_{t-2}) + Π₂·y_{t-1} + ε_t
    //
    // Collecting coefficients on y_{t-1},...,y_{t-p}:

    real scalar p_levels
    p_levels = p  // The levels VAR order: ECM with p lags → levels VAR(p) in the Chang setup
                  // Actually: the highest lag in y is max(1 from Δy, p-2+2 from Δ²y lags) = p
                  // But Δ²y_{t-j} = y_{t-j} - 2y_{t-j-1} + y_{t-j-2} reaches y_{t-p+2-2} = y_{t-p}
                  // And Δy_{t-1} = y_{t-1} - y_{t-2}
                  // So the highest lag of y is max(p, 2) = p (since p ≥ 1)

    // Build A matrices: A_k is the coefficient on y_{t-k} in the levels VAR
    real matrix A_levs
    A_levs = J(n, n * p_levels, 0)  // A_levs = (A₁, A₂, ..., A_p)

    // Contributions from Π₂·y_{t-1}
    A_levs[., 1::n] = A_levs[., 1::n] + Pi2

    // Contributions from Π₁·Δy_{t-1} = Π₁·y_{t-1} - Π₁·y_{t-2}
    A_levs[., 1::n] = A_levs[., 1::n] + Pi1
    if (p_levels >= 2) {
        A_levs[., (n+1)::(2*n)] = A_levs[., (n+1)::(2*n)] - Pi1
    }

    // Contributions from Γ_j·Δ²y_{t-j} for j = 1,...,p-2
    // Δ²y_{t-j} = y_{t-j} - 2·y_{t-j-1} + y_{t-j-2}
    // → coefficient on y_{t-j}: +Γ_j
    // → coefficient on y_{t-j-1}: -2·Γ_j
    // → coefficient on y_{t-j-2}: +Γ_j
    for (k = 1; k <= p - 2; k++) {
        real matrix Gamma_k
        Gamma_k = Gamma_est[., (n*(k-1)+1)::(n*k)]

        // y_{t-k}: +Γ_k
        A_levs[., (n*(k-1)+1)::(n*k)] = A_levs[., (n*(k-1)+1)::(n*k)] + Gamma_k

        // y_{t-k-1}: -2·Γ_k
        if (k + 1 <= p_levels) {
            A_levs[., (n*k+1)::(n*(k+1))] = A_levs[., (n*k+1)::(n*(k+1))] - 2 * Gamma_k
        }

        // y_{t-k-2}: +Γ_k
        if (k + 2 <= p_levels) {
            A_levs[., (n*(k+1)+1)::(n*(k+2))] = A_levs[., (n*(k+1)+1)::(n*(k+2))] + Gamma_k
        }
    }

    // Build companion matrix of dimension p_levels * n
    comp_dim = p_levels * n
    A_companion = J(comp_dim, comp_dim, 0)

    // First n rows: (A₁, A₂, ..., A_p)
    A_companion[1::n, .] = A_levs

    // Identity blocks below
    if (p_levels >= 2) {
        A_companion[(n+1)::comp_dim, 1::((p_levels-1)*n)] = I((p_levels-1)*n)
    }

    // Cholesky of Sigma
    P_chol = cholesky(Sigma_e)

    // Selection matrix: picks first n rows
    J_mat = (I(n), J(n, comp_dim - n, 0))

    // IRF: Φ_h = J * A^h * J' * P
    irf_mat = J(n*n, horizon+1, 0)

    for (h = 0; h <= horizon; h++) {
        if (h == 0) {
            Phi_h = I(comp_dim)
        }
        else {
            Phi_h = A_companion
            for (i = 2; i <= h; i++) {
                Phi_h = Phi_h * A_companion
            }
        }
        irf_h = J_mat * Phi_h * J_mat' * P_chol
        irf_mat[., h+1] = vec(irf_h)
    }
}


// ========================================================================
// FUNCTION: _rbfm_irf_bootstrap()
// Residual-based bootstrap for IRF confidence intervals
// Uses centered residuals, resamples, reconstructs data, re-estimates
// ========================================================================

void _rbfm_irf_bootstrap(
    real matrix Y_raw,
    real scalar p_lags,
    string scalar kernel_type,
    real scalar bw,
    real scalar n,
    real scalar ncols_z,
    real scalar horizon,
    real scalar B,
    real scalar ci_level,
    real matrix irf_lo,
    real matrix irf_hi)
{
    real scalar b, T, nobs, h, idx
    real matrix Y, Z, W, X, F_ols, E_hat, V_hat
    real matrix Omega_ev, Omega_vv, Delta_vdw, dW
    real matrix F_plus_b, Gamma_plus_b, A_plus_b, Sigma_e_b
    real matrix irf_mat_b, irf_store
    real matrix E_centered, Y_boot
    real scalar p_eff, alpha_lo, alpha_hi
    real colvector boot_idx
    real scalar n_irf_elem, b_ok

    // ECM reparameterization of original data
    _rbfm_ecm_reparameterize(Y_raw, p_lags, Y, Z, W)
    T = rows(Y)
    X = (Z, W)
    _rbfm_ols_var(Y, X, Z, W, F_ols, E_hat)

    // Center residuals
    E_centered = E_hat :- mean(E_hat)

    nobs  = rows(Y_raw)
    p_eff = max((p_lags, 2))

    // Storage: B rows x n_irf_elem cols (one bootstrap draw per row)
    n_irf_elem = n * n * (horizon + 1)
    irf_store  = J(B, n_irf_elem, .)

    alpha_lo = (100 - ci_level) / 2 / 100
    alpha_hi = 1 - alpha_lo

    b_ok = 0

    for (b = 1; b <= B; b++) {
        // Resample residuals with replacement
        boot_idx = ceil(T :* runiform(T, 1))
        boot_idx = rowmax((boot_idx, J(T, 1, 1)))
        boot_idx = rowmin((boot_idx, J(T, 1, T)))

        real matrix E_boot
        E_boot = E_centered[boot_idx, .]

        // Reconstruct Y_boot from fitted values + bootstrap residuals
        // Y_boot = X * F_ols' + E_boot (in the ECM representation)
        real matrix Y_boot_ecm
        Y_boot_ecm = X * F_ols' + E_boot

        // Rebuild full Y_raw_boot from Y_boot_ecm
        // Use original initial values + reconstructed levels
        Y_boot = Y_raw[1::p_eff, .]
        for (h = 1; h <= T; h++) {
            Y_boot = Y_boot \ Y_boot_ecm[h, .]
        }

        // Re-estimate RBFM-VAR on bootstrap data
        real matrix Yb, Zb, Wb, Xb, F_ols_b, E_hat_b, V_hat_b
        real matrix Omega_ev_b, Omega_vv_b, Delta_vdw_b, dWb
        real scalar Tb, ncols_z_b

        _rbfm_ecm_reparameterize(Y_boot, p_lags, Yb, Zb, Wb)
        Tb = rows(Yb)
        if (Tb < 5) continue

        Xb = (Zb, Wb)
        _rbfm_ols_var(Yb, Xb, Zb, Wb, F_ols_b, E_hat_b)
        _rbfm_construct_vhat(Y_boot, p_lags, F_ols_b, Xb, V_hat_b)

        // Guard: row counts must match before kernel LRV
        if (rows(E_hat_b) != Tb | rows(V_hat_b) != Tb) continue

        _rbfm_kernel_lrv(E_hat_b, V_hat_b, kernel_type, bw, Omega_ev_b, Omega_vv_b)

        dWb = Wb[2::Tb, .] - Wb[1::(Tb-1), .]
        dWb = (J(1, cols(Wb), 0) \ dWb)
        _rbfm_kernel_olrv(V_hat_b, dWb, kernel_type, bw, Delta_vdw_b)

        _rbfm_correct(Yb, Zb, Wb, Xb, E_hat_b, V_hat_b,
            Omega_ev_b, Omega_vv_b, Delta_vdw_b, Tb,
            F_plus_b, Gamma_plus_b, A_plus_b)

        Sigma_e_b = (E_hat_b' * E_hat_b) / Tb

        // Guard: Sigma must be positive definite for Cholesky in irf_compute
        if (det(Sigma_e_b) <= 0) continue

        // Compute IRFs from bootstrap estimates
        ncols_z_b = cols(Zb)
        _rbfm_irf_compute(F_plus_b, Sigma_e_b, n, p_lags, ncols_z_b, horizon, irf_mat_b)

        // Guard: irf_mat_b must have correct dimensions
        if (rows(irf_mat_b) != n*n | cols(irf_mat_b) != horizon+1) continue

        // Store as a row: vec(irf_mat_b)' is 1 x n_irf_elem
        b_ok = b_ok + 1
        irf_store[b_ok, .] = vec(irf_mat_b)'
    }

    // Trim to successful draws
    if (b_ok < 2) {
        irf_lo = J(n*n, horizon+1, 0)
        irf_hi = J(n*n, horizon+1, 0)
        return
    }
    irf_store = irf_store[1::b_ok, .]

    // Compute percentile-based CI
    irf_lo = J(n*n, horizon+1, 0)
    irf_hi = J(n*n, horizon+1, 0)

    real scalar lo_idx, hi_idx, irf_row, irf_col
    real colvector sorted_col

    lo_idx = max((1, ceil(b_ok * alpha_lo)))
    hi_idx = min((b_ok, floor(b_ok * alpha_hi)))
    if (hi_idx < lo_idx) hi_idx = b_ok

    for (idx = 1; idx <= n_irf_elem; idx++) {
        // Sort this element across bootstrap draws (column of irf_store)
        sorted_col = sort(irf_store[., idx], 1)

        // Map idx to (row, col) in irf_mat
        irf_col = ceil(idx / (n*n))
        irf_row = idx - (irf_col - 1) * (n*n)

        irf_lo[irf_row, irf_col] = sorted_col[lo_idx]
        irf_hi[irf_row, irf_col] = sorted_col[hi_idx]
    }
}


// ========================================================================
// FUNCTION: _rbfm_fevd_compute()
// Forecast Error Variance Decomposition
// FEVD_h(i,j) = Σ_{s=0}^{h} [Φ_s·P]²_{ij} / Σ_{s=0}^{h} Σ_k [Φ_s·P]²_{ik}
// ========================================================================

void _rbfm_fevd_compute(
    real matrix F_plus,
    real matrix Sigma_e,
    real scalar n,
    real scalar p,
    real scalar ncols_z,
    real scalar horizon,
    real matrix fevd_mat)
{
    // First compute all IRF matrices (Cholesky-orthogonalized)
    real matrix irf_mat
    _rbfm_irf_compute(F_plus, Sigma_e, n, p, ncols_z, horizon, irf_mat)

    // fevd_mat: n*n rows x (horizon+1) cols
    // fevd_mat[(i-1)*n + j, h+1] = proportion of var i's FEV due to shock j at horizon h
    fevd_mat = J(n*n, horizon + 1, 0)

    real scalar h, s, i, j, k
    real matrix Phi_s_P, cum_num, cum_denom

    // Cumulative numerator and denominator
    cum_num   = J(n, n, 0)   // cum_num[i,j] = Σ [Φ_s·P]²_{ij}
    cum_denom = J(n, 1, 0)   // cum_denom[i] = Σ_j cum_num[i,j]

    for (h = 0; h <= horizon; h++) {
        // Extract Φ_h · P from irf_mat column h+1
        // irf_mat[., h+1] = vec(Φ_h · P) where Φ_h·P is n x n
        Phi_s_P = rowshape(irf_mat[., h+1], n)

        // Accumulate squared responses
        cum_num = cum_num + Phi_s_P :^ 2

        // Compute denominator for each variable
        cum_denom = J(n, 1, 0)
        for (i = 1; i <= n; i++) {
            for (k = 1; k <= n; k++) {
                cum_denom[i] = cum_denom[i] + cum_num[i, k]
            }
        }

        // FEVD proportions
        for (i = 1; i <= n; i++) {
            for (j = 1; j <= n; j++) {
                real scalar row_idx
                row_idx = (i - 1) * n + j
                if (cum_denom[i] > 0) {
                    fevd_mat[row_idx, h+1] = cum_num[i, j] / cum_denom[i]
                }
            }
        }
    }
}


// ========================================================================
// FUNCTION: _rbfm_forecast_compute()
// Multi-step ahead forecast from the levels VAR companion form
// Includes forecast error standard errors from accumulated Σ_ε
// ========================================================================

void _rbfm_forecast_compute(
    real matrix Y_raw,
    real matrix F_plus,
    real matrix Sigma_e,
    real scalar n,
    real scalar p,
    real scalar ncols_z,
    real scalar steps,
    real matrix fcast_mat,
    real matrix fcast_se)
{
    real scalar nobs, p_levels, comp_dim, h, k, i
    real matrix Pi1, Pi2, Gamma_est, A_levs, A_companion, J_mat
    real matrix state, Phi_h, Sigma_accum, P_chol

    nobs = rows(Y_raw)

    // Extract Pi1, Pi2 from F_plus
    Pi1 = F_plus[., (ncols_z+1)::(ncols_z+n)]
    Pi2 = F_plus[., (ncols_z+n+1)::cols(F_plus)]

    if (ncols_z > 0) {
        Gamma_est = F_plus[., 1::ncols_z]
    }

    // Reconstruct levels VAR A matrices (same as in IRF)
    p_levels = p
    A_levs = J(n, n * p_levels, 0)

    A_levs[., 1::n] = A_levs[., 1::n] + Pi2
    A_levs[., 1::n] = A_levs[., 1::n] + Pi1
    if (p_levels >= 2) {
        A_levs[., (n+1)::(2*n)] = A_levs[., (n+1)::(2*n)] - Pi1
    }

    for (k = 1; k <= p - 2; k++) {
        real matrix Gamma_k
        Gamma_k = Gamma_est[., (n*(k-1)+1)::(n*k)]
        A_levs[., (n*(k-1)+1)::(n*k)] = A_levs[., (n*(k-1)+1)::(n*k)] + Gamma_k
        if (k + 1 <= p_levels) {
            A_levs[., (n*k+1)::(n*(k+1))] = A_levs[., (n*k+1)::(n*(k+1))] - 2 * Gamma_k
        }
        if (k + 2 <= p_levels) {
            A_levs[., (n*(k+1)+1)::(n*(k+2))] = A_levs[., (n*(k+1)+1)::(n*(k+2))] + Gamma_k
        }
    }

    // Build companion matrix
    comp_dim = p_levels * n
    A_companion = J(comp_dim, comp_dim, 0)
    A_companion[1::n, .] = A_levs
    if (p_levels >= 2) {
        A_companion[(n+1)::comp_dim, 1::((p_levels-1)*n)] = I((p_levels-1)*n)
    }

    // Selection matrix
    J_mat = (I(n), J(n, comp_dim - n, 0))

    // Build initial state from last p observations of Y_raw
    state = J(comp_dim, 1, 0)
    for (k = 1; k <= p_levels; k++) {
        if (nobs - k + 1 >= 1) {
            state[((k-1)*n+1)::(k*n)] = Y_raw[nobs - k + 1, .]'
        }
    }

    // Forecast and accumulate error variance
    fcast_mat = J(n, steps, 0)
    fcast_se  = J(n, steps, 0)
    Sigma_accum = J(n, n, 0)

    for (h = 1; h <= steps; h++) {
        state = A_companion * state
        fcast_mat[., h] = J_mat * state

        // Accumulate forecast error variance
        if (h == 1) {
            Phi_h = I(comp_dim)
        }
        else {
            Phi_h = I(comp_dim)
            for (i = 1; i <= h-1; i++) {
                Phi_h = Phi_h * A_companion
            }
        }
        Sigma_accum = Sigma_accum + J_mat * Phi_h * J_mat' * Sigma_e * (J_mat * Phi_h * J_mat')'

        for (i = 1; i <= n; i++) {
            fcast_se[i, h] = sqrt(Sigma_accum[i, i])
        }
    }
}


// ========================================================================
// FUNCTION: _rbfm_ic_table()
// Compute information criteria for all lag orders (for display)
// Returns matrix: rows = lag orders, cols = (p, AIC, BIC, HQ, T)
// ========================================================================

void _rbfm_ic_table(
    real matrix Y_raw,
    real scalar max_p)
{
    real scalar n, nobs, p, T, ic_aic, ic_bic, ic_hq, logdet_sigma
    real matrix Y, Z, W, X, F_tmp, E_tmp, Sigma
    real matrix ic_results
    real scalar row_idx

    n    = cols(Y_raw)
    nobs = rows(Y_raw)
    ic_results = J(max_p, 5, .)
    row_idx = 0

    for (p = 1; p <= max_p; p++) {
        T = nobs - 2 - p + 2
        if (T < 3*n) continue

        _rbfm_ecm_reparameterize(Y_raw, p, Y, Z, W)
        T = rows(Y)
        X = (Z, W)
        _rbfm_ols_var(Y, X, Z, W, F_tmp, E_tmp)

        Sigma = (E_tmp' * E_tmp) / T
        logdet_sigma = ln(det(Sigma))

        if (logdet_sigma == . | logdet_sigma == .) continue

        row_idx = row_idx + 1
        ic_results[row_idx, 1] = p
        ic_results[row_idx, 2] = logdet_sigma + 2 * n^2 * p / T
        ic_results[row_idx, 3] = logdet_sigma + n^2 * p * ln(T) / T
        ic_results[row_idx, 4] = logdet_sigma + 2 * n^2 * p * ln(ln(T)) / T
        ic_results[row_idx, 5] = T
    }

    if (row_idx > 0) {
        st_matrix("r(ic_table)", ic_results[1::row_idx, .])
    }
}


end
