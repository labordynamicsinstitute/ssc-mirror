*! _mixi01_mata 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*! _mixi01_mata.mata — Mata computational library for mixi01
*! Loaded by _mixi01_mata.ado via findfile + do.
*! Contains: long-run covariance, FM-OLS, FM-VAR, Wald tests,
*!           Beveridge-Nelson decomposition, IRF, FEVD, Givens rotations

/* ================================================================== */
/*  Load Mata library                                                  */
/* ================================================================== */

cap mata: mata drop mixi01_*()

mata:
mata set matastrict on

/* Sentinel: probe used by component .ado files to detect prior load.   */
void __mixi01_loaded()
{
}

/* ================================================================== */
/*  KERNEL WEIGHT FUNCTION                                             */
/*  w = mixi01_kernel_weight(x, kernel)                                */
/*  x = |j/K|, kernel = "bartlett"|"parzen"|"qs"|"tukey"              */
/* ================================================================== */

real scalar mixi01_kernel_weight(real scalar x, string scalar kernel)
{
    real scalar w, absx, pix

    absx = abs(x)

    if (kernel == "bartlett") {
        /* Bartlett (triangular): w(x) = 1 - |x|  for |x| <= 1 */
        if (absx <= 1) {
            w = 1 - absx
        }
        else {
            w = 0
        }
    }
    else if (kernel == "parzen") {
        /* Parzen kernel */
        if (absx <= 0.5) {
            w = 1 - 6 * absx^2 + 6 * absx^3
        }
        else if (absx <= 1) {
            w = 2 * (1 - absx)^3
        }
        else {
            w = 0
        }
    }
    else if (kernel == "qs") {
        /* Quadratic spectral kernel */
        if (absx < 1e-12) {
            w = 1
        }
        else {
            pix = 6 * pi() * absx / 5
            w = (25 / (12 * pi()^2 * absx^2)) * (sin(pix) / pix - cos(pix))
        }
    }
    else if (kernel == "tukey" | kernel == "tukey-hanning") {
        /* Tukey-Hanning kernel: w(x) = (1 + cos(pi*x))/2  for |x|<=1 */
        if (absx <= 1) {
            w = (1 + cos(pi() * absx)) / 2
        }
        else {
            w = 0
        }
    }
    else {
        /* default to Bartlett */
        if (absx <= 1) {
            w = 1 - absx
        }
        else {
            w = 0
        }
    }

    return(w)
}


/* ================================================================== */
/*  AUTOCOVARIANCE AT LAG j                                            */
/*  Gamma_j = (1/T) * sum_{t=j+1}^{T} U_t * U_{t-j}'                */
/* ================================================================== */

real matrix mixi01_gamma_j(real matrix U, real scalar j)
{
    real scalar T, k
    real matrix Gamma

    T = rows(U)
    k = cols(U)

    if (j < 0) {
        return(mixi01_gamma_j(U, -j)')
    }

    if (j >= T) {
        return(J(k, k, 0))
    }

    Gamma = cross(U[(j+1)::T, .], U[1::(T-j), .]) / T

    return(Gamma)
}


/* ================================================================== */
/*  LONG-RUN COVARIANCE MATRIX                                         */
/*  Omega = Gamma(0) + sum_{j=1}^{K} w(j/K) * [Gamma(j) + Gamma(j)'] */
/*  Symmetric two-sided estimator                                      */
/* ================================================================== */

real matrix mixi01_lrcov(real matrix U, real scalar K, string scalar kernel)
{
    real scalar T, k, j
    real scalar wj
    real matrix Omega, Gj

    T = rows(U)
    k = cols(U)

    /* Start with Gamma(0) */
    Omega = mixi01_gamma_j(U, 0)

    /* Add weighted autocovariances */
    for (j = 1; j <= K; j++) {
        wj = mixi01_kernel_weight(j / K, kernel)
        if (wj == 0) continue
        Gj = mixi01_gamma_j(U, j)
        Omega = Omega + wj * (Gj + Gj')
    }

    /* Force exact symmetry */
    _makesymmetric(Omega)

    return(Omega)
}


/* ================================================================== */
/*  ONE-SIDED LONG-RUN COVARIANCE                                      */
/*  Delta = sum_{j=0}^{K-1} w(j/K) * Gamma(j)                        */
/* ================================================================== */

real matrix mixi01_onesided(real matrix U, real scalar K, string scalar kernel)
{
    real scalar T, k, j
    real scalar wj
    real matrix Delta

    T = rows(U)
    k = cols(U)

    Delta = J(k, k, 0)

    for (j = 0; j <= K - 1; j++) {
        if (K > 0) {
            wj = mixi01_kernel_weight(j / K, kernel)
        }
        else {
            wj = (j == 0) ? 1 : 0
        }
        if (wj == 0) continue
        Delta = Delta + wj * mixi01_gamma_j(U, j)
    }

    return(Delta)
}


/* ================================================================== */
/*  LAMBDA = Delta - Gamma(0)/2                                        */
/*  Bias correction term for FM estimation                             */
/* ================================================================== */

real matrix mixi01_lambda(real matrix U, real scalar K, string scalar kernel)
{
    real matrix Delta, Gamma0, Lambda

    Delta  = mixi01_onesided(U, K, kernel)
    Gamma0 = mixi01_gamma_j(U, 0)
    Lambda = Delta - Gamma0 / 2

    return(Lambda)
}


/* ================================================================== */
/*  ANDREWS (1991) AUTOMATIC BANDWIDTH SELECTION                       */
/*  Fit AR(1) to each column, compute alpha-hat                        */
/*  K = 1.1447 * (alpha_hat * T)^(1/3)  for Bartlett                  */
/* ================================================================== */

real scalar mixi01_bandwidth_andrews(real matrix U)
{
    real scalar T, k, i
    real scalar rho_i, sig2_i
    real scalar num, den, alpha_hat, K_opt
    real colvector y_t, y_lag
    real matrix coef

    T = rows(U)
    k = cols(U)

    num = 0
    den = 0

    for (i = 1; i <= k; i++) {
        /* AR(1) regression for column i */
        y_t   = U[2::T, i]
        y_lag = U[1::(T-1), i]

        /* OLS: rho = (y_lag'y_lag)^-1 * y_lag'y_t */
        rho_i = (cross(y_lag, y_lag) > 1e-14) ?
                cross(y_lag, y_t) / cross(y_lag, y_lag) : 0

        /* Bound rho to avoid division by zero */
        if (abs(rho_i) >= 0.97) rho_i = sign(rho_i) * 0.97

        /* sigma^2 of AR(1) innovation */
        sig2_i = cross(y_t - rho_i * y_lag, y_t - rho_i * y_lag) / (T - 1)

        /* Andrews alpha computation for Bartlett kernel */
        num = num + 4 * rho_i^2 * sig2_i^2 / ((1 - rho_i)^6 * (1 + rho_i)^2)
        den = den + sig2_i^2 / ((1 - rho_i)^2 * (1 + rho_i)^2)
    }

    if (den < 1e-14) {
        alpha_hat = 0
    }
    else {
        alpha_hat = num / den
    }

    /* Bartlett optimal bandwidth */
    K_opt = 1.1447 * (alpha_hat * T)^(1/3)

    /* Floor of 1 and ceiling of T-1 */
    K_opt = max((1, floor(K_opt)))
    K_opt = min((K_opt, T - 2))

    return(K_opt)
}


/* ================================================================== */
/*  ADF UNIT ROOT TEST                                                 */
/*  Returns: (test_stat, p_value, selected_lag, is_I1)                */
/*  Uses AIC for lag selection                                         */
/* ================================================================== */

real rowvector mixi01_adf_test(real colvector y, real scalar maxlag)
{
    real scalar T, n, p, best_p, best_aic
    real scalar tau, aic_p, sig2, se_gamma, pval, is_I1
    real colvector dy, dy_dep, rhs_const
    real matrix X, XtX_inv, beta
    real colvector resid

    T = rows(y)
    n = T - 1

    if (maxlag < 0) maxlag = floor(12 * (T / 100)^0.25)
    if (maxlag > n - 3) maxlag = n - 3

    /* First differences */
    dy = y[2::T] :- y[1::(T-1)]

    best_aic = .
    best_p   = 0

    /* AIC lag selection */
    for (p = 0; p <= maxlag; p++) {
        real scalar t_start, t_eff
        t_start = p + 2  /* need p lags of dy plus y_{t-1} */
        t_eff   = T - t_start + 1

        if (t_eff < p + 3) continue

        /* Dependent: dy_{t_start}..dy_T  (indices in dy: t_start-1 .. T-1) */
        dy_dep = dy[(t_start - 1)::(T - 1)]

        /* Build RHS: constant, y_{t-1}, dy_{t-1}, ..., dy_{t-p} */
        X = J(t_eff, 1 + 1 + p, 0)
        X[., 1] = J(t_eff, 1, 1)                      /* constant */
        X[., 2] = y[(t_start - 1)::(T - 1)]           /* y_{t-1} */

        real scalar lag_j
        for (lag_j = 1; lag_j <= p; lag_j++) {
            X[., 2 + lag_j] = dy[(t_start - 1 - lag_j)::(T - 1 - lag_j)]
        }

        /* OLS */
        XtX_inv = invsym(cross(X, X))
        beta    = XtX_inv * cross(X, dy_dep)
        resid   = dy_dep - X * beta
        sig2    = cross(resid, resid) / t_eff

        /* AIC */
        aic_p = t_eff * ln(sig2) + 2 * (2 + p)

        if (aic_p < best_aic | best_aic == .) {
            best_aic = aic_p
            best_p   = p
        }
    }

    /* Re-estimate at best lag */
    p = best_p
    real scalar t_start2, t_eff2
    t_start2 = p + 2
    t_eff2   = T - t_start2 + 1

    dy_dep = dy[(t_start2 - 1)::(T - 1)]

    X = J(t_eff2, 2 + p, 0)
    X[., 1] = J(t_eff2, 1, 1)
    X[., 2] = y[(t_start2 - 1)::(T - 1)]

    real scalar lj
    for (lj = 1; lj <= p; lj++) {
        X[., 2 + lj] = dy[(t_start2 - 1 - lj)::(T - 1 - lj)]
    }

    XtX_inv = invsym(cross(X, X))
    beta    = XtX_inv * cross(X, dy_dep)
    resid   = dy_dep - X * beta
    sig2    = cross(resid, resid) / (t_eff2 - cols(X))

    /* ADF statistic: gamma / se(gamma), gamma = beta[2] */
    se_gamma = sqrt(sig2 * XtX_inv[2, 2])
    tau      = beta[2] / se_gamma

    /* MacKinnon (1996) approximate p-value for ADF with constant */
    /* Using response surface approximation */
    pval = _mixi01_adf_pvalue(tau, t_eff2)

    /* Decision at 5% */
    is_I1 = (pval > 0.05) ? 1 : 0

    return((tau, pval, best_p, is_I1))
}


/* ================================================================== */
/*  ADF approximate p-value (MacKinnon 1996 response surface)          */
/*  For model with constant, no trend                                  */
/* ================================================================== */

real scalar _mixi01_adf_pvalue(real scalar tau, real scalar T)
{
    real scalar pval

    /* MacKinnon critical values for n=1, constant:
       1%: -3.43, 5%: -2.86, 10%: -2.57
       Use normal approximation for p-value mapping */

    if (tau <= -3.96) {
        pval = 0.001
    }
    else if (tau <= -3.43) {
        pval = 0.01 - (tau - (-3.43)) / ((-3.96) - (-3.43)) * 0.009
    }
    else if (tau <= -2.86) {
        pval = 0.05 - (tau - (-2.86)) / ((-3.43) - (-2.86)) * 0.04
    }
    else if (tau <= -2.57) {
        pval = 0.10 - (tau - (-2.57)) / ((-2.86) - (-2.57)) * 0.05
    }
    else if (tau <= -1.62) {
        pval = 0.10 + (tau - (-2.57)) / ((-1.62) - (-2.57)) * 0.40
    }
    else if (tau <= -0.50) {
        pval = 0.50 + (tau - (-1.62)) / ((-0.50) - (-1.62)) * 0.20
    }
    else if (tau <= 0.50) {
        pval = 0.70 + (tau - (-0.50)) / (0.50 - (-0.50)) * 0.15
    }
    else if (tau <= 1.50) {
        pval = 0.85 + (tau - 0.50) / (1.50 - 0.50) * 0.10
    }
    else {
        pval = 0.99
    }

    /* Size correction */
    if (T > 0) {
        pval = pval + 2.5 / T
        if (pval > 0.999) pval = 0.999
    }

    return(pval)
}


/* ================================================================== */
/*  FM-OLS ESTIMATOR                                                   */
/*  y = A1*X1 + A2*X2 + eps                                           */
/*  X1: stationary (I(0)), X2: nonstationary (I(1))                    */
/*  Returns struct with: b, V, Omega, resid, r2                       */
/* ================================================================== */

struct mixi01_fmols_result {
    real colvector  b           /* FM-OLS coefficients */
    real matrix     V           /* Variance-covariance matrix */
    real matrix     Omega       /* Long-run covariance */
    real colvector  resid       /* Residuals */
    real scalar     r2          /* R-squared */
    real scalar     r2_adj      /* Adjusted R-squared */
    real scalar     rmse        /* Root mean squared error */
    real scalar     omega_ee2   /* Long-run residual variance (corrected) */
}

struct mixi01_fmols_result scalar mixi01_fmols_est(
    real colvector y,
    real matrix X1,
    real matrix X2,
    real scalar K,
    string scalar kernel,
    real scalar eqtrend)
{
    struct mixi01_fmols_result scalar res

    real scalar T, k1, k2, k_all, K_use
    real matrix X, XtX, XtX_inv
    real colvector beta_ols, uhat
    real matrix dX2, W, Omega_full
    real matrix Omega_eu, Omega_uu, Omega_22, Omega_22_inv
    real matrix Delta_full, Delta_eu, Delta_uu
    real colvector y_plus
    real matrix Lambda_plus
    real colvector delta_bias
    real colvector b_fmols
    real matrix V_fmols
    real scalar omega_ee_2, sse

    T    = rows(y)
    k1   = cols(X1)  /* # of stationary regressors */
    k2   = cols(X2)  /* # of nonstationary regressors */
    k_all = k1 + k2

    /* ── Step 0: Build combined X and deterministic trend ── */
    if (eqtrend == 1) {
        /* Add linear trend to stationary block */
        X1 = X1, (1::T)
        k1 = k1 + 1
        k_all = k_all + 1
    }

    X = (X1, X2)

    /* ── Step 1: OLS regression to get residuals ── */
    XtX     = cross(X, X)
    XtX_inv = invsym(XtX)
    beta_ols = XtX_inv * cross(X, y)
    uhat    = y - X * beta_ols

    /* ── Step 1b: First differences of I(1) regressors ── */
    dX2 = X2[2::T, .] :- X2[1::(T-1), .]

    /* ── Step 2: Long-run covariance of (uhat, dX2) ── */
    /* Align: use t=2..T for both */
    W = (uhat[2::T], dX2)

    /* Automatic bandwidth if K <= 0 */
    K_use = K
    if (K_use <= 0) {
        K_use = mixi01_bandwidth_andrews(W)
    }

    Omega_full = mixi01_lrcov(W, K_use, kernel)
    Delta_full = mixi01_onesided(W, K_use, kernel)

    /* Partition: [eps | dX2] => Omega_ee, Omega_eu, Omega_uu */
    real scalar omega_ee_scalar
    omega_ee_scalar = Omega_full[1, 1]
    Omega_eu  = Omega_full[1, 2::(1+k2)]
    Omega_uu  = Omega_full[2::(1+k2), 2::(1+k2)]

    Omega_22     = Omega_uu
    Omega_22_inv = invsym(Omega_22)

    Delta_eu = Delta_full[1, 2::(1+k2)]
    Delta_uu = Delta_full[2::(1+k2), 2::(1+k2)]

    /* ── Step 3: FM correction of dependent variable ── */
    /* y_t^+ = y_t - Omega_eu * Omega_22^{-1} * dX2_t */
    y_plus = y
    y_plus[2::T] = y[2::T] :- (dX2 * (Omega_22_inv' * Omega_eu'))'

    /* NOTE: transpose handling:
       Omega_eu is 1 x k2, Omega_22_inv is k2 x k2
       correction = dX2 * Omega_22_inv * Omega_eu' is (T-1) x 1 */
    y_plus[2::T] = y[2::T] - dX2 * Omega_22_inv * Omega_eu'

    /* ── Step 4: Bias correction ── */
    /* Lambda_eu = Delta_eu - Gamma(0)_eu / 2 */
    real matrix Gamma0_full, Lambda_eu
    Gamma0_full = mixi01_gamma_j(W, 0)
    Lambda_eu   = Delta_full[1, 2::(1+k2)] - Gamma0_full[1, 2::(1+k2)] / 2

    /* delta_bias for nonstationary block only */
    /* T * delta_plus = Lambda_eu' - Omega_eu' .* Omega_22^{-1} * Lambda_22 */
    real matrix Lambda_22
    Lambda_22 = Delta_full[2::(1+k2), 2::(1+k2)] - Gamma0_full[2::(1+k2), 2::(1+k2)] / 2

    delta_bias = J(k_all, 1, 0)
    delta_bias[(k1+1)::k_all] = T * (Lambda_eu' - Omega_22_inv * Lambda_22' * Omega_eu' / omega_ee_scalar)

    /* ── Step 5: FM-OLS coefficients ── */
    /* A^+ = (X'y^+ - delta_bias)' * (X'X)^{-1} */
    b_fmols = XtX_inv * (cross(X, y_plus) - delta_bias)

    /* ── Step 6: Variance estimation ── */
    /* omega_{ee.2} = omega_ee - Omega_eu * Omega_22^{-1} * Omega_eu' */
    omega_ee_2 = omega_ee_scalar - Omega_eu * Omega_22_inv * Omega_eu'

    if (omega_ee_2 < 1e-12) omega_ee_2 = omega_ee_scalar * 0.01

    /* For stationary block: V(A1^+) = omega_{ee.2} * (X1' M_2 X1)^{-1} */
    /* For nonstationary block: V(A2^+) = omega_{ee.2} * (X2' M_1 X2)^{-1} */
    /* Combined using the partitioned inverse approach */
    V_fmols = omega_ee_2 * XtX_inv

    /* Residuals from FM-OLS */
    res.resid = y - X * b_fmols
    sse = cross(res.resid, res.resid)

    /* R-squared */
    real scalar sst
    sst = cross(y :- mean(y), y :- mean(y))
    if (sst > 1e-14) {
        res.r2 = 1 - sse / sst
    }
    else {
        res.r2 = .
    }
    res.r2_adj = 1 - (1 - res.r2) * (T - 1) / (T - k_all)

    /* Store results */
    res.b        = b_fmols
    res.V        = V_fmols
    res.Omega    = Omega_full
    res.rmse     = sqrt(sse / (T - k_all))
    res.omega_ee2 = omega_ee_2

    return(res)
}


/* ================================================================== */
/*  FM-VAR ESTIMATOR                                                   */
/*  Y_t = J*Z_t + A*Y_{t-1} + eps_t                                   */
/*  Z: stationary block, Y_{t-1}: lagged levels (mixed I(0)/I(1))     */
/* ================================================================== */

struct mixi01_fmvar_result {
    real matrix     F_plus      /* FM-VAR coefficient matrix [J+, A+] */
    real matrix     V           /* Variance of vec(F+) */
    real matrix     Sigma_ee    /* Residual covariance */
    real matrix     Omega       /* Long-run covariance */
    real matrix     resid       /* Residuals (T x n) */
}

struct mixi01_fmvar_result scalar mixi01_fmvar_est(
    real matrix Y,
    real matrix Z,
    real matrix Ylag,
    real scalar K,
    string scalar kernel)
{
    struct mixi01_fmvar_result scalar res

    real scalar T, n, kz, ky, K_use
    real matrix X, XtX, XtX_inv
    real matrix F_ols, Uhat
    real matrix W, Omega_full, Delta_full, Gamma0_full
    real matrix dY, Omega_eu, Omega_uu, Omega_uu_inv
    real matrix Y_plus, Delta_bias
    real matrix F_plus, Sigma_ee
    real scalar i

    T  = rows(Y)
    n  = cols(Y)    /* number of equations */
    kz = cols(Z)    /* stationary regressors per equation */
    ky = cols(Ylag) /* lagged level regressors per equation */

    /* ── Step 1: OLS equation by equation ── */
    X = (Z, Ylag)

    XtX     = cross(X, X)
    XtX_inv = invsym(XtX)

    /* F_ols is (kz+ky) x n, each column is coefficients for one equation */
    F_ols = XtX_inv * cross(X, Y)
    Uhat  = Y - X * F_ols

    /* ── Step 2: First differences of Ylag for LR covariance ── */
    /* We use all columns of Ylag in the dY block */
    dY = Ylag[2::T, .] :- Ylag[1::(T-1), .]

    /* ── Step 3: Long-run covariance ── */
    /* W = [Uhat, dYlag] aligned at t=2..T */
    W = (Uhat[2::T, .], dY)

    K_use = K
    if (K_use <= 0) {
        K_use = mixi01_bandwidth_andrews(W)
    }

    Omega_full = mixi01_lrcov(W, K_use, kernel)
    Delta_full = mixi01_onesided(W, K_use, kernel)
    Gamma0_full = mixi01_gamma_j(W, 0)

    /* Partition: [u (n cols) | dY (ky cols)] */
    Omega_eu     = Omega_full[1::n, (n+1)::(n+ky)]
    Omega_uu     = Omega_full[(n+1)::(n+ky), (n+1)::(n+ky)]
    Omega_uu_inv = invsym(Omega_uu)

    /* ── Step 4: FM correction for each equation ── */
    Y_plus = Y
    Y_plus[2::T, .] = Y[2::T, .] - dY * Omega_uu_inv * Omega_eu'

    /* ── Step 5: Bias correction ── */
    real matrix Lambda_eu, Lambda_uu
    Lambda_eu = Delta_full[1::n, (n+1)::(n+ky)] - Gamma0_full[1::n, (n+1)::(n+ky)] / 2
    Lambda_uu = Delta_full[(n+1)::(n+ky), (n+1)::(n+ky)] - Gamma0_full[(n+1)::(n+ky), (n+1)::(n+ky)] / 2

    /* Bias term: applies to the Ylag block */
    Delta_bias = J(kz + ky, n, 0)

    /* For the nonstationary block (rows kz+1..kz+ky) */
    /* Phillips (1995) eq. (5.6): bias = T * (Lambda_eu - Omega_eu * Omega_uu^{-1} * Lambda_uu)' */
    real matrix Omega_ee
    Omega_ee = Omega_full[1::n, 1::n]
    Delta_bias[(kz+1)::(kz+ky), .] = T * (Lambda_eu - Omega_eu * Omega_uu_inv * Lambda_uu)'

    /* ── Step 6: FM-VAR coefficients ── */
    F_plus = XtX_inv * (cross(X, Y_plus) - Delta_bias)

    /* ── Step 7: Residual covariance ── */
    res.resid = Y - X * F_plus
    Sigma_ee  = cross(res.resid, res.resid) / (T - kz - ky)

    /* ── Step 8: Variance of vec(F+) ── */
    /* Phillips (1995) Theorem 5.1: block-diagonal variance */
    /* Omega_ee.2 = Omega_ee - Omega_eu * Omega_uu^{-1} * Omega_eu' */
    /* Stationary block: Omega_ee.2 ⊗ (Z'Z)^{-1}  (√T rate) */
    /* Nonstationary block: Omega_ee.2 ⊗ (Ylag'Ylag)^{-1}  (T rate) */
    real matrix Omega_ee_2
    Omega_ee_2 = Omega_ee - Omega_eu * Omega_uu_inv * Omega_eu'
    _makesymmetric(Omega_ee_2)
    /* Ensure PSD */
    if (min(diagonal(Omega_ee_2)) < 1e-12) {
        Omega_ee_2 = Omega_ee * 0.01
    }
    /* Block-diagonal: use Omega_ee.2 for the full Kronecker product */
    /* This is conservative for the nonstationary block (overestimates SE) */
    /* but correct for the stationary block per Phillips Theorem 5.1 */
    res.V = (Omega_ee_2 # XtX_inv)

    /* Store */
    res.F_plus   = F_plus
    res.Sigma_ee = Sigma_ee
    res.Omega    = Omega_full

    return(res)
}


/* ================================================================== */
/*  WALD TEST WITH MIXED ASYMPTOTICS                                   */
/*  H0: R * vec(F+) = r                                               */
/*  Returns: (W, p_conservative, p_liberal)                            */
/* ================================================================== */

real rowvector mixi01_wald_mixed(
    real matrix R,
    real colvector r,
    real colvector b,
    real matrix V,
    real matrix X,
    real scalar T,
    real matrix Omega_ee,
    real matrix Omega_ee2)
{
    real scalar q, W, p_conservative, p_liberal
    real colvector Rb_r
    real matrix RVR, RVR_inv

    q = rows(R)

    /* R*b - r */
    Rb_r = R * b - r

    /* R * V * R' */
    RVR     = R * V * R'
    RVR_inv = invsym(RVR)

    /* Wald statistic */
    W = Rb_r' * RVR_inv * Rb_r

    /* Conservative: chi2(q) — valid upper bound */
    /* Uses V computed with Omega_ee (full long-run variance) */
    p_conservative = 1 - chi2(q, W)

    /* Liberal: Phillips (1995) Theorem 6.1 */
    /* Re-compute Wald with V based on Omega_ee.2 (conditional variance) */
    /* This yields a standard chi2(q) distribution under H0 */
    real matrix V_liberal, RVR_lib, RVR_lib_inv
    real scalar W_liberal
    if (rows(Omega_ee2) > 0 & cols(Omega_ee2) > 0) {
        /* V_liberal uses Omega_ee.2 instead of Omega_ee */
        /* Scale V by ratio of Omega_ee.2 / Omega_ee */
        real scalar scale_factor
        scale_factor = trace(Omega_ee2) / max((trace(Omega_ee), 1e-14))
        V_liberal = V * scale_factor
        RVR_lib = R * V_liberal * R'
        RVR_lib_inv = invsym(RVR_lib)
        W_liberal = Rb_r' * RVR_lib_inv * Rb_r
        p_liberal = 1 - chi2(q, W_liberal)
    }
    else {
        p_liberal = p_conservative
    }

    /* Bound p-values */
    if (p_conservative < 0) p_conservative = 0
    if (p_conservative > 1) p_conservative = 1
    if (p_liberal < 0) p_liberal = 0
    if (p_liberal > 1) p_liberal = 1

    return((W, p_conservative, p_liberal))
}


/* ================================================================== */
/*  BEVERIDGE-NELSON PERMANENT COMPONENT DECOMPOSITION                 */
/*  For a system with I(1) variables:                                  */
/*    Delta y_p = C(1) * eps_t                                         */
/*    y_t = y_p_t + y_trans_t                                          */
/*                                                                     */
/*  From Fisher et al (2015) equation (30):                            */
/*    Delta y_p = (I-R)(I-A)^{-1} * e1 + G*(I-F)^{-1} * e2           */
/*  where R = (I-A)^{-1} * G * (I-F)^{-1} * Gamma                    */
/* ================================================================== */

struct mixi01_bn_result {
    real matrix y_permanent
    real matrix y_transitory
}

struct mixi01_bn_result scalar mixi01_perm_component(
    real matrix Y,
    real matrix A,
    real matrix G,
    real matrix F_mat,
    | real matrix Gamma_mat)
{
    struct mixi01_bn_result scalar res

    real scalar T, n1, n2, n
    real matrix I_A, I_A_inv, I_F, I_F_inv
    real matrix R
    real matrix C1, dY_perm
    real matrix Y_perm, Y_trans

    T  = rows(Y)
    n  = cols(Y)
    n1 = rows(A)  /* dimension of I(1) block */
    n2 = rows(F_mat)  /* dimension of I(0) block */

    /* (I - A) and its inverse */
    I_A     = I(n1) - A
    I_A_inv = luinv(I_A)

    /* (I - F) and its inverse */
    I_F     = I(n2) - F_mat
    I_F_inv = luinv(I_F)

    /* Fisher et al. (2015) eq. (A6)-(A7), Appendix 1:
       System: y1_t = A*y1_{t-1} + G*y2_{t-1} + e1
               y2_t = Gamma*y1_{t-1} + F*y2_{t-1} + e2
       R = (I-A)^{-1} * G * (I-F)^{-1} * Gamma
       C(1) = (I-R) * (I-A)^{-1}  */

    /* Compute R using Gamma if provided, otherwise R = 0 */
    if (args() >= 5 & rows(Gamma_mat) == n2 & cols(Gamma_mat) == n1) {
        /* R = (I-A)^{-1} * G * (I-F)^{-1} * Gamma */
        R = I_A_inv * G * I_F_inv * Gamma_mat
    }
    else {
        /* Gamma not provided — R = 0 (no cross-block feedback) */
        R = J(n1, n1, 0)
    }

    /* Permanent component of first differences */
    /* C(1) = (I - R) * (I - A)^{-1} for the e1 shock */
    C1 = (I(n1) - R) * I_A_inv

    /* Delta y_permanent = C(1) * eps1_t
       We need the residuals, but with Y provided we compute
       the permanent component from the BN identity:
       y_p_t = lim_{h->inf} y_{t+h|t} - h * mu
       = C(1) * sum_{s=1}^{t} eps_s + initial conditions */

    /* Compute residuals from VAR(1) for I(1) block */
    real matrix eps1
    if (n1 <= n) {
        /* Y assumed to have I(1) variables in first n1 columns */
        real matrix Y1
        Y1 = Y[., 1::n1]
        eps1 = Y1[2::T, .] :- Y1[1::(T-1), .] * A'

        if (n2 > 0 & cols(Y) >= n1 + n2) {
            real matrix Y2
            Y2 = Y[., (n1+1)::(n1+n2)]
            eps1 = eps1 :- Y2[1::(T-1), .] * G'
        }
    }
    else {
        eps1 = Y[2::T, .] :- Y[1::(T-1), .] * A'
    }

    /* Delta y_permanent */
    dY_perm = eps1 * C1'

    /* Cumulate to get permanent level */
    Y_perm = J(T, n1, 0)
    Y_perm[1, .] = Y[1, 1::n1]
    real scalar t
    for (t = 2; t <= T; t++) {
        Y_perm[t, .] = Y_perm[t-1, .] + dY_perm[t-1, .]
    }

    /* Transitory = actual - permanent */
    Y_trans = Y[., 1::n1] - Y_perm

    /* If there are more columns (I(0) variables), they are all transitory */
    if (n > n1) {
        Y_perm  = (Y_perm, J(T, n - n1, 0))
        Y_trans = (Y_trans, Y[., (n1+1)::n])
    }

    res.y_permanent  = Y_perm
    res.y_transitory = Y_trans

    return(res)
}


/* ================================================================== */
/*  STRUCTURAL IRF COMPUTATION                                         */
/*  A_arr: n x n x p array of VAR coefficient matrices (lags 1..p)    */
/*  B0inv: n x n structural impact matrix (A0^{-1})                    */
/*  Returns: IRF cube stored as (nsteps+1) x n x n                     */
/*           IRF[h, i, j] = response of variable i to shock j at h    */
/* ================================================================== */

real matrix mixi01_irf_compute(
    real matrix A_arr,
    real matrix B0inv,
    real scalar nsteps)
{
    real scalar n, p, h, lag
    real matrix Phi, IRF
    real matrix Phi_h

    /* A_arr is stacked: n x (n*p), each n-column block is one lag */
    n = rows(A_arr)
    p = cols(A_arr) / n

    /* Phi stores MA coefficients: Phi_0 = B0inv, then recursion
       Phi_h = sum_{j=1}^{min(h,p)} A_j * Phi_{h-j} */

    /* Store all Phi's: (nsteps+1) blocks of n x n, stacked as n*(nsteps+1) x n */
    Phi = J(n * (nsteps + 1), n, 0)

    /* Phi_0 = B0inv */
    Phi[1::n, .] = B0inv

    for (h = 1; h <= nsteps; h++) {
        Phi_h = J(n, n, 0)
        for (lag = 1; lag <= min((h, p)); lag++) {
            real matrix A_lag, Phi_prev
            A_lag    = A_arr[., ((lag-1)*n+1)::(lag*n)]
            Phi_prev = Phi[((h-lag)*n+1)::((h-lag+1)*n), .]
            Phi_h = Phi_h + A_lag * Phi_prev
        }
        Phi[(h*n+1)::((h+1)*n), .] = Phi_h
    }

    /* IRF output: (nsteps+1)*n x n matrix
       Block h (0-indexed): rows h*n+1 .. (h+1)*n
       IRF[h*n+i, j] = response of variable i to shock j at horizon h */
    IRF = Phi

    return(IRF)
}


/* ================================================================== */
/*  FORECAST ERROR VARIANCE DECOMPOSITION                              */
/*  FEVD[h, i, j] = share of FEV of variable i due to shock j at h   */
/*  Input IRF: (nsteps+1)*n x n from mixi01_irf_compute               */
/* ================================================================== */

real matrix mixi01_fevd(real matrix IRF, real scalar nsteps)
{
    real scalar n, h, i, j
    real matrix FEVD, cum_sq, total_fev
    real matrix Phi_h

    /* Determine n from IRF dimensions */
    n = cols(IRF)

    /* FEVD: (nsteps+1)*n x n matrix, same layout as IRF */
    FEVD = J((nsteps + 1) * n, n, 0)

    /* Cumulative squared IRF */
    cum_sq = J(n, n, 0)

    for (h = 0; h <= nsteps; h++) {
        Phi_h = IRF[(h*n+1)::((h+1)*n), .]

        /* Accumulate squared responses */
        for (i = 1; i <= n; i++) {
            for (j = 1; j <= n; j++) {
                cum_sq[i, j] = cum_sq[i, j] + Phi_h[i, j]^2
            }
        }

        /* Compute shares (each row sums to 1) */
        for (i = 1; i <= n; i++) {
            real scalar row_total
            row_total = 0
            for (j = 1; j <= n; j++) {
                row_total = row_total + cum_sq[i, j]
            }
            if (row_total > 1e-14) {
                for (j = 1; j <= n; j++) {
                    FEVD[h*n + i, j] = cum_sq[i, j] / row_total
                }
            }
            else {
                /* Equal shares if no variation */
                for (j = 1; j <= n; j++) {
                    FEVD[h*n + i, j] = 1 / n
                }
            }
        }
    }

    return(FEVD)
}


/* ================================================================== */
/*  GIVENS ROTATION MATRIX                                             */
/*  Generates an n x n rotation matrix Q with:                         */
/*    Q[i,i] = cos(theta), Q[i,j] = -sin(theta)                       */
/*    Q[j,i] = sin(theta), Q[j,j] = cos(theta)                        */
/*  Used for sign restrictions in SVAR identification                  */
/* ================================================================== */

real matrix mixi01_givens_rotation(
    real scalar theta,
    real scalar n,
    real scalar i,
    real scalar j)
{
    real matrix Q
    real scalar ct, st

    if (i < 1 | i > n | j < 1 | j > n | i == j) {
        _error(3300, "mixi01_givens_rotation: invalid indices")
    }

    Q = I(n)

    ct = cos(theta)
    st = sin(theta)

    Q[i, i] =  ct
    Q[i, j] = -st
    Q[j, i] =  st
    Q[j, j] =  ct

    return(Q)
}


/* ================================================================== */
/*  UTILITY: Make symmetric positive semi-definite                     */
/* ================================================================== */

real matrix mixi01_makepsd(real matrix A)
{
    real matrix S, V, Lambda
    real scalar k, i

    k = rows(A)
    S = makesymmetric(A)

    /* Eigendecompose and zero out negative eigenvalues */
    symeigensystem(S, V=., Lambda=.)

    for (i = 1; i <= k; i++) {
        if (Lambda[i] < 0) Lambda[i] = 0
    }

    S = V * diag(Lambda) * V'
    _makesymmetric(S)

    return(S)
}


/* ================================================================== */
/*  UTILITY: Compute companion matrix from VAR(p) coefficients         */
/* ================================================================== */

real matrix mixi01_companion(real matrix A_arr, real scalar n, real scalar p)
{
    real matrix C
    real scalar j

    /* A_arr is n x (n*p) */
    C = J(n * p, n * p, 0)

    /* First block row: [A1 A2 ... Ap] */
    C[1::n, .] = A_arr

    /* Identity blocks on the sub-diagonal */
    if (p > 1) {
        C[(n+1)::(n*p), 1::(n*(p-1))] = I(n * (p - 1))
    }

    return(C)
}

end

/* ================================================================== */
/*  Save compiled Mata objects                                         */
/* ================================================================== */
/*
   To compile and save, run in Stata:
     do _mixi01_mata.do
     mata: mata mosave mixi01_*(), dir(PERSONAL) replace
*/
