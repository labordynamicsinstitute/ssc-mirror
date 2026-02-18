*! _qadf_mata.ado - Mata library for QADF (Quantile ADF) unit root test
*! Version 1.0.0, February 2026
*! Author: Dr. Merwan Roudane
*! Email: merwanroudane920@gmail.com
*!
*! Reference:
*!   Koenker, R., Xiao, Z., 2004.
*!   Unit Root Quantile Autoregression Inference.
*!   Journal of the American Statistical Association 99, 775-787.
*!
*! Critical values from:
*!   Hansen, B. (1995). Rethinking the Univariate Approach to Unit Root Tests.
*!   Econometric Theory, 11, 1148-1171.
*!
*! GAUSS code reference: Saban Nazlioglu (TSPDLIB)

capture program drop _qadf_mata
program define _qadf_mata
    version 14.0
    di as txt "QADF Mata library loaded successfully."
end

version 14.0
capture mata: mata drop qadf_qreg()
capture mata: mata drop qadf_adf_lagsel()
capture mata: mata drop qadf_bw_hs()
capture mata: mata drop qadf_bw_bofinger()
capture mata: mata drop qadf_get_bw()
capture mata: mata drop qadf_delta2()
capture mata: mata drop qadf_tstat()
capture mata: mata drop qadf_hansen_cv()
capture mata: mata drop qadf_compute()
capture mata: mata drop qadf_bootstrap_dgp()
capture mata: mata drop qadf_compute_vec()
capture mata: mata drop qadf_bootstrap()
capture mata: mata drop qadf_bootstrap_process()
mata:
mata set matastrict off

// ============================================================================
// Quantile Regression via Iteratively Reweighted Least Squares (IRLS)
// Matches: core.py:_quantile_regression
// ============================================================================
real matrix qadf_qreg(real colvector y, real matrix X, real scalar tau,
                       | real scalar max_iter, real scalar tol)
{
    real scalar n, k, iter
    real colvector beta, beta_new, resid, weights
    real matrix W, XtWX

    if (args() < 4) max_iter = 1000
    if (args() < 5) tol = 1e-8

    n = rows(X)
    k = cols(X)

    // Initial OLS estimate
    beta = qrsolve(X, y)

    for (iter = 1; iter <= max_iter; iter++) {
        resid = y - X * beta
        // Weights: tau/|r| if r >= 0, (1-tau)/|r| if r < 0
        weights = J(n, 1, 0)
        for (i = 1; i <= n; i++) {
            if (resid[i] >= 0) {
                weights[i] = tau / (abs(resid[i]) + 1e-10)
            }
            else {
                weights[i] = (1 - tau) / (abs(resid[i]) + 1e-10)
            }
        }

        // Weighted least squares
        XtWX = cross(X, weights, X)
        beta_new = cholsolve(XtWX, cross(X, weights, y))
        if (beta_new == J(0, 0, .)) {
            beta_new = qrsolve(X :* sqrt(weights), y :* sqrt(weights))
        }

        if (max(abs(beta_new - beta)) < tol) {
            beta = beta_new
            break
        }
        beta = beta_new
    }

    return(beta)
}

// ============================================================================
// ADF Lag Selection using Information Criteria
// Matches: core.py:_adf_lag_selection (GAUSS approach)
// ============================================================================
real rowvector qadf_adf_lagsel(real colvector y, real scalar pmax,
                                string scalar ic)
{
    real scalar n, best_ic, best_lag, best_adf_t, p
    real scalar trim_start, n_eff, k_reg, ssr, sigma2, ic_val, adf_t
    real colvector dy, y_dep, y_lag, resid, beta
    real matrix X, dy_lags, XtX_inv

    n = rows(y)
    dy = y[2::n] - y[1::(n-1)]
    // y1 = y[1::(n-1)]

    best_ic = .
    best_lag = 0
    best_adf_t = 0

    for (p = 0; p <= pmax; p++) {
        trim_start = p + 1  // 0-indexed in Python, 1-indexed here
        // Dependent: dy[trim_start+1 .. n-1] (using 1-indexed)
        if (trim_start + 1 > rows(dy)) continue
        y_dep = dy[(trim_start + 1)::rows(dy)]
        // Lagged level: y[trim_start+1 .. n-1]
        y_lag = y[(trim_start + 1)::(n - 1)]

        n_eff = rows(y_dep)
        if (n_eff < 5) continue

        // Build X: constant, y_{t-1}
        X = J(n_eff, 1, 1), y_lag

        if (p > 0) {
            // Lagged differences
            dy_lags = J(rows(dy), p, 0)
            for (j = 1; j <= p; j++) {
                for (t = j + 1; t <= rows(dy); t++) {
                    dy_lags[t, j] = dy[t - j]
                }
            }
            dy_lags = dy_lags[(trim_start + 1)::rows(dy), .]
            X = X, dy_lags
        }

        k_reg = cols(X)

        // OLS
        beta = qrsolve(X, y_dep)
        resid = y_dep - X * beta
        ssr = cross(resid, resid)
        sigma2 = ssr / (n_eff - k_reg)

        // Standard error of rho coefficient (index 2)
        XtX_inv = cholinv(cross(X, X))
        if (XtX_inv == J(0, 0, .)) {
            XtX_inv = invsym(cross(X, X))
        }
        adf_t = beta[2] / sqrt(sigma2 * XtX_inv[2, 2])

        // Information criterion
        if (ic == "aic") {
            ic_val = ln(ssr / n_eff) + 2 * k_reg / n_eff
        }
        else if (ic == "bic") {
            ic_val = ln(ssr / n_eff) + k_reg * ln(n_eff) / n_eff
        }
        else {
            // t-stat rule
            if (p > 0) {
                real scalar se_last, t_last
                se_last = sqrt(sigma2 * XtX_inv[k_reg, k_reg])
                t_last = abs(beta[k_reg] / se_last)
                if (t_last < 1.96) {
                    ic_val = .
                }
                else {
                    ic_val = -p
                }
            }
            else {
                ic_val = 0
            }
        }

        if (ic_val < best_ic) {
            best_ic = ic_val
            best_lag = p
            best_adf_t = adf_t
        }
    }

    return((best_lag, best_adf_t))
}

// ============================================================================
// Hall-Sheather Bandwidth
// Matches: core.py:bandwidth_hs
// Reference: Hall, P. and Sheather, S.J. (1988). JRSS-B 50(3), 381-391.
// ============================================================================
real scalar qadf_bw_hs(real scalar tau, real scalar n, | real scalar alpha)
{
    real scalar x0, f0, h

    if (args() < 3) alpha = 0.05

    x0 = invnormal(tau)
    f0 = normalden(x0)

    h = n^(-1/3) * (invnormal(1 - alpha/2))^(2/3) * ///
        ((1.5 * f0^2) / (2 * x0^2 + 1))^(1/3)

    return(h)
}

// ============================================================================
// Bofinger Bandwidth
// Matches: core.py:bandwidth_bofinger
// Reference: Bofinger, E. (1975). Australian Journal of Statistics, 17, 1-7.
// ============================================================================
real scalar qadf_bw_bofinger(real scalar tau, real scalar n)
{
    real scalar x0, f0, h

    x0 = invnormal(tau)
    f0 = normalden(x0)

    h = n^(-0.2) * ((4.5 * f0^4) / (2 * x0^2 + 1)^2)^0.2

    return(h)
}

// ============================================================================
// Combined Bandwidth with boundary adjustments
// Matches: core.py:_get_bandwidth (GAUSS: __get_qr_adf_h)
// ============================================================================
real scalar qadf_get_bw(real scalar tau, real scalar n, | real scalar alpha)
{
    real scalar h

    if (args() < 3) alpha = 0.05

    h = qadf_bw_hs(tau, n, alpha)

    if (tau <= 0.5 & h > tau) {
        h = qadf_bw_bofinger(tau, n)
        if (h > tau) {
            h = tau / 1.5
        }
    }

    if (tau > 0.5 & h > 1 - tau) {
        h = qadf_bw_bofinger(tau, n)
        if (h > (1 - tau)) {
            h = (1 - tau) / 1.5
        }
    }

    return(h)
}

// ============================================================================
// Calculate delta² (nuisance parameter)
// Matches: core.py:_calculate_delta2 (GAUSS code exactly)
//
// GAUSS:
//   res = y - (ones(rows(x),1)~x) * qr_beta
//   ind = res .< 0
//   phi = tau - ind
//   cov = sumc((w - meanc(w)) .* (phi - meanc(phi)))/(rows(w) - 1)
//   delta2 = (cov/(stdc(w) * sqrt(tau * (1-tau))))^2
// ============================================================================
real scalar qadf_delta2(real colvector y_dep, real matrix X_full,
                         real colvector dy_trimmed, real scalar tau,
                         real colvector qr_beta)
{
    real scalar n, cov_val, std_w, delta2
    real colvector resid, ind, phi, w, w_c, phi_c

    // Residuals
    resid = y_dep - X_full * qr_beta

    // Indicator for negative residuals
    ind = (resid :< 0)

    // psi_tau(u) = tau - I(u < 0)
    phi = J(rows(resid), 1, tau) - ind

    // w = dy (first differences)
    w = dy_trimmed
    n = rows(w)

    // Ensure same length
    if (rows(phi) > n) {
        phi = phi[(rows(phi) - n + 1)::rows(phi)]
    }
    if (rows(w) > rows(phi)) {
        w = w[(rows(w) - rows(phi) + 1)::rows(w)]
        n = rows(w)
    }

    // GAUSS: cov = sumc((w - meanc(w)) .* (phi - meanc(phi)))/(rows(w) - 1)
    w_c = w :- mean(w)
    phi_c = phi :- mean(phi)
    cov_val = sum(w_c :* phi_c) / (n - 1)

    // GAUSS: delta2 = (cov/(stdc(w) * sqrt(tau * (1-tau))))^2
    std_w = sqrt(variance(w))
    if (std_w < 1e-10) std_w = 1e-10

    delta2 = (cov_val / (std_w * sqrt(tau * (1 - tau))))^2

    return(delta2)
}

// ============================================================================
// Calculate QADF t-statistic
// Matches: core.py:_calculate_qadf_statistic (equation 9, GAUSS-exact)
//
// GAUSS:
//   h = __get_qr_adf_h(tau, n)
//   rq1 = __get_qr_adf_beta(y, x, tau+h)
//   rq2 = __get_qr_adf_beta(y, x, tau-h)
//   z = ones(rows(x), 1)~x
//   mz = meanc(z)
//   q1 = mz' * rq1
//   q2 = mz' * rq2
//   fz = 2 * h/(q1 - q2)
//   xx = ones(rows(x), 1)
//   if p > 0 then xx = ones(rows(x), 1)~dyl
//   PX = eye(rows(xx)) - xx * inv(xx'xx) * xx'
//   QURadf = fz/sqrt(tau*(1-tau)) * sqrt(Y1'*PX*Y1) * (rho_tau-1)
// ============================================================================
real scalar qadf_tstat(real colvector y_dep, real colvector y_lag,
                        real matrix dyl, real matrix X_no_const,
                        real scalar rho_tau, real scalar tau,
                        real scalar n, real scalar p, string scalar model)
{
    real scalar h, tau_upper, tau_lower, fz, y1_proj, qadf_stat
    real colvector rq1, rq2, mz, y1_vec
    real matrix X_with_const, xx, PX

    // Get bandwidth: h = __get_qr_adf_h(tau, n)
    h = qadf_get_bw(tau, n)

    // Ensure tau +/- h stays in valid range
    tau_upper = min((tau + h, 0.999))
    tau_lower = max((tau - h, 0.001))

    // z = ones(rows(x), 1) ~ x  (add constant)
    X_with_const = J(rows(y_dep), 1, 1), X_no_const

    // rq1 = __get_qr_adf_beta(y, x, tau+h)
    rq1 = qadf_qreg(y_dep, X_with_const, tau_upper)
    // rq2 = __get_qr_adf_beta(y, x, tau-h)
    rq2 = qadf_qreg(y_dep, X_with_const, tau_lower)

    // mz = meanc(z)
    mz = mean(X_with_const)'

    // q1 = mz' * rq1; q2 = mz' * rq2
    // fz = 2 * h / (q1 - q2)
    real scalar q1, q2
    q1 = mz' * rq1
    q2 = mz' * rq2

    if (q1 - q2 != 0) {
        fz = 2 * h / (q1 - q2)
    }
    else {
        fz = 0.01
    }
    // GAUSS: if fz < 0 then fz = 0.01
    if (fz < 0) fz = 0.01

    // Build projection matrix PX
    // xx = ones(rows(x), 1)
    xx = J(rows(y_dep), 1, 1)

    // if p > 0 then xx = ones(rows(x), 1) ~ dyl
    if (p > 0 & rows(dyl) > 0 & cols(dyl) > 0) {
        xx = xx, dyl
    }

    // NOTE: GAUSS code does NOT include trend in xx for model==2
    // PX only projects out constant and lagged diffs, NOT trend

    // PX = eye(rows(xx)) - xx * inv(xx'xx) * xx'
    PX = I(rows(xx)) - xx * invsym(cross(xx, xx)) * xx'

    // sqrt(Y1' * PX * Y1)
    y1_vec = y_lag
    if (rows(y1_vec) > rows(y_dep)) {
        y1_vec = y1_vec[(rows(y1_vec) - rows(y_dep) + 1)::rows(y1_vec)]
    }
    else if (rows(y1_vec) < rows(y_dep)) {
        y1_vec = J(rows(y_dep) - rows(y1_vec), 1, y1_vec[1]) \ y1_vec
    }

    y1_proj = y1_vec' * PX * y1_vec
    if (y1_proj <= 0) y1_proj = 1e-10

    // QURadf = fz/sqrt(tau*(1-tau)) * sqrt(Y1'*PX*Y1) * (rho_tau - 1)
    qadf_stat = (fz / sqrt(tau * (1 - tau))) * sqrt(y1_proj) * (rho_tau - 1)

    return(qadf_stat)
}

// ============================================================================
// Hansen (1995) Critical Values - Table II
// Matches: critical_values.py / core.py:_get_critical_values_hansen
//
// Interpolation based on delta2 = 0.1, 0.2, ..., 1.0
// Returns: (cv_1pct, cv_5pct, cv_10pct)
// ============================================================================
real rowvector qadf_hansen_cv(real scalar delta2, string scalar model)
{
    real matrix cv_nc, cv_c, cv_ct, cv_table
    real rowvector cv
    real scalar r210, r2a, r2b, wa

    // No constant model
    cv_nc = (-2.4611512, -1.7832090, -1.4189957 \
           -2.4943410, -1.8184897, -1.4589747 \
           -2.5152783, -1.8516957, -1.5071775 \
           -2.5509773, -1.8957720, -1.5323511 \
           -2.5520784, -1.8949965, -1.5418830 \
           -2.5490848, -1.8981677, -1.5625462 \
           -2.5547456, -1.9343180, -1.5889045 \
           -2.5761273, -1.9387996, -1.6020210 \
           -2.5511921, -1.9328373, -1.6128210 \
           -2.5658000, -1.9393000, -1.6156000)

    // Constant model (default in Koenker & Xiao 2004)
    cv_c = (-2.7844267, -2.1158290, -1.7525193 \
          -2.9138762, -2.2790427, -1.9172046 \
          -3.0628184, -2.3994711, -2.0573070 \
          -3.1376157, -2.5070473, -2.1680520 \
          -3.1914660, -2.5841611, -2.2520173 \
          -3.2437157, -2.6399560, -2.3163270 \
          -3.2951006, -2.7180169, -2.4085640 \
          -3.3627161, -2.7536756, -2.4577709 \
          -3.3896556, -2.8074982, -2.5037759 \
          -3.4336000, -2.8621000, -2.5671000)

    // Constant and trend model
    cv_ct = (-2.9657928, -2.3081543, -1.9519926 \
           -3.1929596, -2.5482619, -2.1991651 \
           -3.3727717, -2.7283918, -2.3806008 \
           -3.4904849, -2.8669056, -2.5315918 \
           -3.6003166, -2.9853079, -2.6672416 \
           -3.6819803, -3.0954760, -2.7815263 \
           -3.7551759, -3.1783550, -2.8728146 \
           -3.8348596, -3.2674954, -2.9735550 \
           -3.8800989, -3.3316415, -3.0364171 \
           -3.9638000, -3.4126000, -3.1279000)

    // Select table
    if (model == "nc") {
        cv_table = cv_nc
    }
    else if (model == "c") {
        cv_table = cv_c
    }
    else if (model == "ct") {
        cv_table = cv_ct
    }
    else {
        cv_table = cv_c  // default
    }

    // Interpolation
    if (delta2 < 0.1) {
        cv = cv_table[1, .]
    }
    else if (delta2 >= 1.0) {
        cv = cv_table[10, .]
    }
    else {
        r210 = delta2 * 10
        r2a = floor(r210)
        r2b = ceil(r210)

        if (r2a == r2b) {
            cv = cv_table[r2a, .]
        }
        else {
            wa = r2b - r210
            cv = wa * cv_table[r2a, .] + (1 - wa) * cv_table[r2b, .]
        }
    }

    return(cv)
}

// ============================================================================
// Full QADF test at a single quantile (called by qadf.ado)
// Returns results via st_numscalar / st_local
// ============================================================================
void qadf_compute(string scalar varname, real scalar tau, string scalar model,
                   real scalar pmax, string scalar ic, string scalar touse)
{
    real scalar n_orig, p, adf_t, trim_start, n_eff
    real scalar rho_tau, rho_ols, alpha_tau, delta2, qadf_stat, coef_stat
    real scalar half_life
    real colvector y, dy, y_dep, y_lag, dy_trimmed
    real colvector qr_beta, ols_beta
    real matrix X, dyl, X_no_const
    real rowvector lagsel, cv

    // Get data
    y = st_data(., varname, touse)
    n_orig = rows(y)

    // Lag selection
    lagsel = qadf_adf_lagsel(y, pmax, ic)
    p = lagsel[1]
    adf_t = lagsel[2]

    // First differences
    dy = y[2::n_orig] - y[1::(n_orig - 1)]

    // Trim
    trim_start = p + 1

    // Dependent: y[trim_start+1 .. n_orig]  (1-indexed)
    y_dep = y[(trim_start + 1)::n_orig]
    // Lagged level: y[trim_start .. n_orig-1]
    y_lag = y[trim_start::(n_orig - 1)]

    n_eff = rows(y_dep)

    // Build regressor matrix: y_{t-1}
    X_no_const = y_lag

    // Create lagged differences if p > 0
    if (p > 0) {
        dyl = J(n_eff, p, 0)
        for (j = 1; j <= p; j++) {
            // delta_y_{t-j} for each obs
            real scalar start_idx
            start_idx = trim_start - j  // 1-indexed in dy
            for (i = 1; i <= n_eff; i++) {
                dyl[i, j] = dy[start_idx + i - 1]
            }
        }
        X_no_const = X_no_const, dyl
        dy_trimmed = dy[trim_start::(trim_start + n_eff - 1)]
    }
    else {
        dyl = J(0, 0, .)
        dy_trimmed = dy[1::n_eff]
    }

    // Add trend if model='ct'
    if (model == "ct") {
        X_no_const = X_no_const, (1::n_eff)
    }

    // Full design matrix X = [constant, X_no_const]
    X = J(n_eff, 1, 1), X_no_const

    // ---- Quantile regression ----
    qr_beta = qadf_qreg(y_dep, X, tau)
    alpha_tau = qr_beta[1]
    rho_tau = qr_beta[2]

    // ---- OLS for comparison ----
    ols_beta = qrsolve(X, y_dep)
    rho_ols = ols_beta[2]

    // ---- Delta² ----
    delta2 = qadf_delta2(y_dep, X, dy_trimmed, tau, qr_beta)
    // Bound to [0.01, 0.99]
    delta2 = max((0.01, min((0.99, delta2))))

    // ---- QADF t-statistic ----
    if (p > 0) {
        qadf_stat = qadf_tstat(y_dep, y_lag, dyl, X_no_const, ///
                                rho_tau, tau, n_eff, p, model)
    }
    else {
        qadf_stat = qadf_tstat(y_dep, y_lag, J(0,0,.), X_no_const, ///
                                rho_tau, tau, n_eff, p, model)
    }

    // ---- Coefficient statistic ----
    coef_stat = n_eff * (rho_tau - 1)

    // ---- Hansen critical values ----
    cv = qadf_hansen_cv(delta2, model)

    // ---- Half-life ----
    if (rho_tau >= 1 | rho_tau <= 0) {
        half_life = .
    }
    else {
        half_life = ln(0.5) / ln(abs(rho_tau))
        if (half_life <= 0) half_life = .
    }

    // ---- Return results to Stata ----
    st_numscalar("r(qadf_stat)", qadf_stat)
    st_numscalar("r(coef_stat)", coef_stat)
    st_numscalar("r(rho_tau)", rho_tau)
    st_numscalar("r(rho_ols)", rho_ols)
    st_numscalar("r(alpha_tau)", alpha_tau)
    st_numscalar("r(delta2)", delta2)
    st_numscalar("r(half_life)", half_life)
    st_numscalar("r(lags)", p)
    st_numscalar("r(nobs)", n_eff)
    st_numscalar("r(cv1)", cv[1])
    st_numscalar("r(cv5)", cv[2])
    st_numscalar("r(cv10)", cv[3])
    st_numscalar("r(adf_t)", adf_t)
}

// ============================================================================
// Bootstrap DGP under H0 (unit root)
// Matches: bootstrap.py:generate_bootstrap_sample
//
// Procedure:
//   1. Fit AR(p) to dy_t and obtain residuals u_hat
//   2. Draw iid samples {u*} from centered residuals
//   3. Generate w*_t = sum(beta_j * w*_{t-j}) + u*_t
//   4. Generate y*_t = y*_{t-1} + w*_t (unit root imposed)
// ============================================================================
real colvector qadf_bootstrap_dgp(real colvector y, real scalar p)
{
    real scalar n, q, n_dy
    real colvector dy, betas, resid, centered, u_star, dy_star, y_star
    real matrix X_ar

    n = rows(y)
    dy = y[2::n] - y[1::(n-1)]
    n_dy = rows(dy)

    q = max((p, 1))

    // Step 1: Fit AR(q) to first differences
    if (q > 0 & n_dy > q) {
        X_ar = J(n_dy - q, q, 0)
        for (j = 1; j <= q; j++) {
            for (t = 1; t <= n_dy - q; t++) {
                X_ar[t, j] = dy[q + t - j]
            }
        }
        betas = qrsolve(X_ar, dy[(q + 1)::n_dy])
        resid = dy[(q + 1)::n_dy] - X_ar * betas
    }
    else {
        betas = J(0, 1, 0)
        resid = dy :- mean(dy)
    }

    // Step 2: Center residuals and draw bootstrap
    centered = resid :- mean(resid)
    real scalar m
    m = rows(centered)
    u_star = J(m, 1, 0)
    for (i = 1; i <= m; i++) {
        u_star[i] = centered[ceil(uniform(1, 1) * m)]
    }

    // Step 3: Generate bootstrap diffs
    dy_star = dy[1::q]  // initialize
    for (i = 1; i <= m; i++) {
        real scalar dy_t
        dy_t = u_star[i]
        if (rows(betas) > 0) {
            for (j = 1; j <= q; j++) {
                real scalar idx
                idx = rows(dy_star) - j + 1
                if (idx >= 1) dy_t = dy_t + betas[j] * dy_star[idx]
            }
        }
        dy_star = dy_star \ dy_t
    }

    // Step 4: Integrate under null (unit root)
    y_star = J(n, 1, y[1])
    for (i = 2; i <= min((n, rows(dy_star) + 1)); i++) {
        y_star[i] = y_star[i-1] + dy_star[i-1]
    }

    return(y_star)
}

// ============================================================================
// Full QADF on a data vector (used internally for bootstrap)
// Returns: (qadf_stat, coef_stat, rho_tau, delta2)
// ============================================================================
real rowvector qadf_compute_vec(real colvector y, real scalar tau,
                                 string scalar model, real scalar pmax,
                                 string scalar ic)
{
    real scalar n_orig, p, adf_t, trim_start, n_eff
    real scalar rho_tau, rho_ols, alpha_tau, delta2, qadf_stat, coef_stat
    real colvector dy, y_dep, y_lag, dy_trimmed
    real colvector qr_beta, ols_beta
    real matrix X, X_no_const, dyl
    real rowvector lagsel

    n_orig = rows(y)

    lagsel = qadf_adf_lagsel(y, pmax, ic)
    p = lagsel[1]

    dy = y[2::n_orig] - y[1::(n_orig - 1)]
    trim_start = p + 1

    if (trim_start + 1 > n_orig) return((., ., ., .))

    y_dep = y[(trim_start + 1)::n_orig]
    y_lag = y[trim_start::(n_orig - 1)]
    n_eff = rows(y_dep)
    if (n_eff < 10) return((., ., ., .))

    X_no_const = y_lag
    if (p > 0) {
        dyl = J(n_eff, p, 0)
        for (j = 1; j <= p; j++) {
            real scalar si
            si = trim_start - j
            for (i = 1; i <= n_eff; i++) {
                dyl[i, j] = dy[si + i - 1]
            }
        }
        X_no_const = X_no_const, dyl
        dy_trimmed = dy[trim_start::(trim_start + n_eff - 1)]
    }
    else {
        dyl = J(0, 0, .)
        dy_trimmed = dy[1::n_eff]
    }

    if (model == "ct") {
        X_no_const = X_no_const, (1::n_eff)
    }

    X = J(n_eff, 1, 1), X_no_const

    qr_beta = qadf_qreg(y_dep, X, tau)
    rho_tau = qr_beta[2]

    delta2 = qadf_delta2(y_dep, X, dy_trimmed, tau, qr_beta)
    delta2 = max((0.01, min((0.99, delta2))))

    if (p > 0) {
        qadf_stat = qadf_tstat(y_dep, y_lag, dyl, X_no_const, ///
                                rho_tau, tau, n_eff, p, model)
    }
    else {
        qadf_stat = qadf_tstat(y_dep, y_lag, J(0,0,.), X_no_const, ///
                                rho_tau, tau, n_eff, p, model)
    }

    coef_stat = n_eff * (rho_tau - 1)

    return((qadf_stat, coef_stat, rho_tau, delta2))
}

// ============================================================================
// Bootstrap: compute p-value and critical values for single tau
// ============================================================================
void qadf_bootstrap(string scalar varname, real scalar tau, string scalar model,
                     real scalar pmax, string scalar ic, real scalar nreps,
                     real scalar seed, string scalar touse, real scalar obs_qadf_stat)
{
    real scalar i, p
    real colvector y, y_star, t_boot, u_boot
    real rowvector res, lagsel
    real matrix boot_results

    y = st_data(., varname, touse)

    // Get optimal lag from original data
    lagsel = qadf_adf_lagsel(y, pmax, ic)
    p = lagsel[1]

    if (seed != .) rseed(seed)

    t_boot = J(nreps, 1, .)
    u_boot = J(nreps, 1, .)

    for (i = 1; i <= nreps; i++) {
        y_star = qadf_bootstrap_dgp(y, p)
        res = qadf_compute_vec(y_star, tau, model, pmax, ic)
        if (res[1] != .) {
            t_boot[i] = res[1]
            u_boot[i] = res[2]
        }
    }

    // Remove missing
    real colvector sel
    sel = (t_boot :!= .)
    t_boot = select(t_boot, sel)
    u_boot = select(u_boot, sel)

    real scalar n_valid
    n_valid = rows(t_boot)

    if (n_valid < 10) {
        st_numscalar("r(boot_nvalid)", n_valid)
        return
    }

    // Sort for percentiles
    real colvector t_sorted, u_sorted
    t_sorted = sort(t_boot, 1)
    u_sorted = sort(u_boot, 1)

    // Critical values (left-tail)
    st_numscalar("r(boot_cv1_t)", t_sorted[max((1, floor(n_valid * 0.01)))])
    st_numscalar("r(boot_cv5_t)", t_sorted[max((1, floor(n_valid * 0.05)))])
    st_numscalar("r(boot_cv10_t)", t_sorted[max((1, floor(n_valid * 0.10)))])

    st_numscalar("r(boot_cv1_u)", u_sorted[max((1, floor(n_valid * 0.01)))])
    st_numscalar("r(boot_cv5_u)", u_sorted[max((1, floor(n_valid * 0.05)))])
    st_numscalar("r(boot_cv10_u)", u_sorted[max((1, floor(n_valid * 0.10)))])

    // p-value (proportion of bootstrap stats <= observed stat)
    // obs_qadf_stat is passed as parameter from qadf_boot.ado
    st_numscalar("r(boot_pvalue)", sum(t_boot :<= obs_qadf_stat) / n_valid)

    st_numscalar("r(boot_nvalid)", n_valid)
    st_numscalar("r(boot_nreps)", nreps)
}

// ============================================================================
// Bootstrap for QKS/QCM (process-level bootstrap)
// ============================================================================
void qadf_bootstrap_process(string scalar varname, string scalar quantile_str,
                             string scalar model, real scalar pmax,
                             string scalar ic, real scalar nreps,
                             real scalar seed, string scalar touse)
{
    real scalar i, j, nq, p
    real colvector y, y_star, quantiles
    real colvector qks_a_boot, qks_t_boot, qcm_a_boot, qcm_t_boot
    real rowvector res, lagsel

    y = st_data(., varname, touse)

    // Parse quantiles
    quantiles = strtoreal(tokens(quantile_str))'

    nq = rows(quantiles)

    lagsel = qadf_adf_lagsel(y, pmax, ic)
    p = lagsel[1]

    if (seed != .) rseed(seed)

    qks_a_boot = J(nreps, 1, .)
    qks_t_boot = J(nreps, 1, .)
    qcm_a_boot = J(nreps, 1, .)
    qcm_t_boot = J(nreps, 1, .)

    for (i = 1; i <= nreps; i++) {
        y_star = qadf_bootstrap_dgp(y, p)

        real colvector t_stats, u_stats
        t_stats = J(nq, 1, .)
        u_stats = J(nq, 1, .)

        for (j = 1; j <= nq; j++) {
            res = qadf_compute_vec(y_star, quantiles[j], model, pmax, ic)
            t_stats[j] = res[1]
            u_stats[j] = res[2]
        }

        if (anyof(t_stats, .)) continue

        // QKS
        qks_a_boot[i] = max(abs(u_stats))
        qks_t_boot[i] = max(abs(t_stats))

        // QCM (trapezoidal)
        real colvector dtau
        dtau = J(nq, 1, 0)
        for (j = 1; j < nq; j++) {
            dtau[j] = quantiles[j+1] - quantiles[j]
        }
        dtau[nq] = dtau[nq-1]

        qcm_a_boot[i] = sum(u_stats:^2 :* dtau)
        qcm_t_boot[i] = sum(t_stats:^2 :* dtau)
    }

    // Remove missing
    real colvector sel
    sel = (qks_t_boot :!= .)
    qks_a_boot = select(qks_a_boot, sel)
    qks_t_boot = select(qks_t_boot, sel)
    qcm_a_boot = select(qcm_a_boot, sel)
    qcm_t_boot = select(qcm_t_boot, sel)

    real scalar nv
    nv = rows(qks_t_boot)

    if (nv < 10) {
        st_numscalar("r(boot_nvalid)", nv)
        return
    }

    // Upper-tail CVs (right-tail for supremum/integral stats)
    real colvector sa, st, ca, ct
    sa = sort(qks_a_boot, 1)
    st = sort(qks_t_boot, 1)
    ca = sort(qcm_a_boot, 1)
    ct = sort(qcm_t_boot, 1)

    st_numscalar("r(boot_qks_a_1)", sa[max((1, ceil(nv * 0.99)))])
    st_numscalar("r(boot_qks_a_5)", sa[max((1, ceil(nv * 0.95)))])
    st_numscalar("r(boot_qks_a_10)", sa[max((1, ceil(nv * 0.90)))])

    st_numscalar("r(boot_qks_t_1)", st[max((1, ceil(nv * 0.99)))])
    st_numscalar("r(boot_qks_t_5)", st[max((1, ceil(nv * 0.95)))])
    st_numscalar("r(boot_qks_t_10)", st[max((1, ceil(nv * 0.90)))])

    st_numscalar("r(boot_qcm_a_1)", ca[max((1, ceil(nv * 0.99)))])
    st_numscalar("r(boot_qcm_a_5)", ca[max((1, ceil(nv * 0.95)))])
    st_numscalar("r(boot_qcm_a_10)", ca[max((1, ceil(nv * 0.90)))])

    st_numscalar("r(boot_qcm_t_1)", ct[max((1, ceil(nv * 0.99)))])
    st_numscalar("r(boot_qcm_t_5)", ct[max((1, ceil(nv * 0.95)))])
    st_numscalar("r(boot_qcm_t_10)", ct[max((1, ceil(nv * 0.90)))])

    st_numscalar("r(boot_nvalid)", nv)
}

end

*==============================================================================
* End of _qadf_mata.ado
*==============================================================================
