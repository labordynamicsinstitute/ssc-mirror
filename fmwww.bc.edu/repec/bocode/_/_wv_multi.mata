*! Multivariate Wavelet Analysis — Multiple Correlation, Regression, Cross-correlation
*! Based on: wavemulcor R package (Fernandez-Macho 2021)
*! References: Fernandez-Macho (2012, 2018)
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
version 11
mata:
mata set matastrict on

// ═══════════════════════════════════════════════════════════════════════════
// STRUCT DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

struct _wv_wmcorr_r {
    real matrix    val        // J x 3: [R, CI_low, CI_up]
    real colvector ymaxr      // J x 1: index of variable with max R²
    real colvector N_eff      // J x 1: effective sample size per level
    string colvector varnames // variable names
    string scalar  filter
    real scalar    J
    real scalar    p          // confidence level
}

struct _wv_wmreg_r {
    real matrix    beta       // J x d: regression coefficients per scale
    real matrix    se         // J x d: standard errors
    real matrix    tstat      // J x d: t-statistics
    real matrix    pval       // J x d: p-values
    real colvector rsq        // J x 1: R² per scale
    real colvector ymaxr      // J x 1: dependent variable index
    string colvector varnames
    string scalar  filter
    real scalar    J
}

struct _wv_wmxcorr_r {
    real matrix    val        // J x (2*maxlag+1) x 3 — correlation at lags
    real colvector ymaxr      // J x 1
    real matrix    ci_lo      // J x (2*maxlag+1)
    real matrix    ci_up      // J x (2*maxlag+1)
    string scalar  filter
    real scalar    J
    real scalar    maxlag
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_wmcorr(): Wavelet Multiple Correlation
//   X:       N x d matrix (d variables, N observations)
//   filter:  filter name (default "la8")
//   J:       decomposition levels
//   p:       confidence level (default 0.95)
//   Returns: struct with R, CI, YmaxR per scale
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_wmcorr_r scalar function _wv_wmcorr(real matrix X,
                                                string scalar filter,
                                                real scalar J,
                                                | real scalar p)
{
    struct _wv_wmcorr_r scalar r
    struct _wv_modwt_r scalar wr
    real scalar d, N, j, i, k, nj, Rj, maxdiag, maxidx
    real scalar zr, se_z, z_crit, lo, hi
    real matrix Pj, Pinv
    real colvector wi, wk

    if (args() < 4 | p == .) p = 0.95

    d = cols(X)
    N = rows(X)

    r.val    = J(J, 3, .)
    r.ymaxr  = J(J, 1, .)
    r.N_eff  = J(J, 1, .)
    r.filter = filter
    r.J      = J
    r.p      = p

    // MODWT decompose each variable
    pointer(struct _wv_modwt_r scalar) colvector modwts
    modwts = J(d, 1, NULL)
    for (i = 1; i <= d; i++) {
        modwts[i] = &(_wv_modwt(X[., i], filter, J))
    }

    // At each scale j: compute pairwise correlations, invert, get R²
    for (j = 1; j <= J; j++) {
        // Effective sample size after brick-wall
        nj = floor(N / 2^j)
        r.N_eff[j] = nj

        if (nj < 3) {
            r.val[j, .] = (., ., .)
            r.ymaxr[j]  = .
            continue
        }

        // Build d x d correlation matrix
        Pj = I(d)
        for (i = 1; i <= d; i++) {
            wi = (*modwts[i]).W[j, .]'
            // Use only non-boundary coefficients
            wi = wi[rows(wi) - nj + 1 .. rows(wi)]
            for (k = i + 1; k <= d; k++) {
                wk = (*modwts[k]).W[j, .]'
                wk = wk[rows(wk) - nj + 1 .. rows(wk)]
                Pj[i, k] = correlation((wi, wk))[1, 2]
                Pj[k, i] = Pj[i, k]
            }
        }

        // Invert correlation matrix
        Pinv = luinv(Pj)

        // Find variable with max diagonal element (= max R²)
        maxdiag = 0
        maxidx  = 1
        for (i = 1; i <= d; i++) {
            if (Pinv[i, i] > maxdiag) {
                maxdiag = Pinv[i, i]
                maxidx  = i
            }
        }

        // R = sqrt(1 - 1/max(diag(P^-1)))
        Rj = sqrt(1 - 1 / maxdiag)

        // Fisher z-transform CI
        zr     = atanh(Rj)
        se_z   = 1 / sqrt(nj - 3)
        z_crit = invnormal((1 + p) / 2)
        lo     = tanh(zr - z_crit * se_z)
        hi     = tanh(zr + z_crit * se_z)

        r.val[j, .] = (Rj, lo, hi)
        r.ymaxr[j]  = maxidx
    }

    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_wmreg(): Wavelet Multiple Regression
//   X:       N x d matrix (d variables)
//   filter:  filter name
//   J:       levels
//   Returns: struct with beta, SE, t, p per scale (dependent = YmaxR)
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_wmreg_r scalar function _wv_wmreg(real matrix X,
                                              string scalar filter,
                                              real scalar J)
{
    struct _wv_wmreg_r scalar r
    struct _wv_wmcorr_r scalar wc
    struct _wv_modwt_r scalar wr
    real scalar d, N, j, i, nj, ymr, df, col, sse, mse
    real matrix XX, Xreg, var_b
    real colvector yy, bhat, resid, wi

    d = cols(X)
    N = rows(X)

    // First get wmcorr to determine YmaxR
    wc = _wv_wmcorr(X, filter, J)

    r.beta  = J(J, d - 1, .)
    r.se    = J(J, d - 1, .)
    r.tstat = J(J, d - 1, .)
    r.pval  = J(J, d - 1, .)
    r.rsq   = J(J, 1, .)
    r.ymaxr = wc.ymaxr
    r.filter = filter
    r.J     = J

    // MODWT decompose each variable
    pointer(struct _wv_modwt_r scalar) colvector modwts
    modwts = J(d, 1, NULL)
    for (i = 1; i <= d; i++) {
        modwts[i] = &(_wv_modwt(X[., i], filter, J))
    }

    // OLS regression at each scale
    for (j = 1; j <= J; j++) {
        nj  = floor(N / 2^j)
        ymr = wc.ymaxr[j]

        if (nj < d + 1 | ymr == .) continue

        // Extract dependent variable
        yy = (*modwts[ymr]).W[j, .]'
        yy = yy[rows(yy) - nj + 1 .. rows(yy)]

        // Extract independent variables
        Xreg = J(nj, d - 1, .)
        col = 0
        for (i = 1; i <= d; i++) {
            if (i == ymr) continue
            col = col + 1
            wi = (*modwts[i]).W[j, .]'
            Xreg[., col] = wi[rows(wi) - nj + 1 .. rows(wi)]
        }

        // OLS: beta = (X'X)^-1 X'y
        XX   = cross(Xreg, Xreg)
        bhat = lusolve(XX, cross(Xreg, yy))

        // Residuals and standard errors
        resid = yy - Xreg * bhat
        df    = nj - (d - 1)
        sse   = cross(resid, resid)
        mse   = sse / df

        var_b = mse * luinv(XX)

        r.beta[j, .] = bhat'
        for (i = 1; i <= d - 1; i++) {
            r.se[j, i]    = sqrt(var_b[i, i])
            r.tstat[j, i] = bhat[i] / r.se[j, i]
            r.pval[j, i]  = 2 * (1 - normal(abs(r.tstat[j, i])))
        }
        r.rsq[j] = 1 - sse / cross(yy :- mean(yy), yy :- mean(yy))
    }

    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_wmxcorr(): Wavelet Multiple Cross-Correlation
//   X:       N x d matrix
//   filter:  filter name
//   J:       levels
//   maxlag:  maximum lag (default 10)
//   p:       confidence level (default 0.95)
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_wmxcorr_r scalar function _wv_wmxcorr(real matrix X,
                                                   string scalar filter,
                                                   real scalar J,
                                                   | real scalar maxlag,
                                                   real scalar p)
{
    struct _wv_wmxcorr_r scalar r
    struct _wv_modwt_r scalar wr
    real scalar d, N, j, i, k, nj, lag, nlags, lcol, n_eff, maxd, midx, Rj, zr, se_z, zc
    real matrix Pj, Pinv
    real colvector wi, wk, wi_l, wk_l

    if (args() < 4 | maxlag == .) maxlag = 10
    if (args() < 5 | p      == .) p      = 0.95

    d     = cols(X)
    N     = rows(X)
    nlags = 2 * maxlag + 1

    r.val    = J(J, nlags, .)
    r.ci_lo  = J(J, nlags, .)
    r.ci_up  = J(J, nlags, .)
    r.ymaxr  = J(J, 1, .)
    r.filter = filter
    r.J      = J
    r.maxlag = maxlag

    // MODWT decompose
    pointer(struct _wv_modwt_r scalar) colvector modwts
    modwts = J(d, 1, NULL)
    for (i = 1; i <= d; i++) {
        modwts[i] = &(_wv_modwt(X[., i], filter, J))
    }

    // At each scale, for each lag
    for (j = 1; j <= J; j++) {
        nj = floor(N / 2^j)
        if (nj < d + 2) continue

        for (lag = -maxlag; lag <= maxlag; lag++) {
            lcol = lag + maxlag + 1

            // Build lagged correlation matrix
            Pj = I(d)
            for (i = 1; i <= d; i++) {
                wi = (*modwts[i]).W[j, .]'
                for (k = i + 1; k <= d; k++) {
                    wk = (*modwts[k]).W[j, .]'

                    // Apply lag

                    if (lag >= 0) {
                        n_eff = nj - lag
                        if (n_eff < 3) {
                            Pj[i, k] = .
                            Pj[k, i] = .
                            continue
                        }
                        wi_l = wi[rows(wi) - nj + 1 .. rows(wi) - lag]
                        wk_l = wk[rows(wk) - nj + 1 + lag .. rows(wk)]
                    }
                    else {
                        n_eff = nj + lag
                        if (n_eff < 3) {
                            Pj[i, k] = .
                            Pj[k, i] = .
                            continue
                        }
                        wi_l = wi[rows(wi) - nj + 1 - lag .. rows(wi)]
                        wk_l = wk[rows(wk) - nj + 1 .. rows(wk) + lag]
                    }

                    Pj[i, k] = correlation((wi_l, wk_l))[1, 2]
                    Pj[k, i] = Pj[i, k]
                }
            }

            // Check for missing
            if (hasmissing(Pj)) continue

            // Invert and get R
            Pinv = luinv(Pj)
            maxd = 0
            midx = 1
            for (i = 1; i <= d; i++) {
                if (Pinv[i, i] > maxd) {
                    maxd = Pinv[i, i]
                    midx = i
                }
            }

            Rj = sqrt(max((1 - 1/maxd, 0)))

            // CI
            n_eff  = nj - abs(lag)
            zr     = atanh(Rj)
            se_z   = 1 / sqrt(n_eff - 3)
            zc     = invnormal((1 + p) / 2)

            r.val[j, lcol]   = Rj
            r.ci_lo[j, lcol] = tanh(zr - zc * se_z)
            r.ci_up[j, lcol] = tanh(zr + zc * se_z)

            if (lag == 0) r.ymaxr[j] = midx
        }
    }

    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_local_corr(): Local (time-varying) wavelet multiple correlation
//   W_j:   d x nj matrix — wavelet coefficients at scale j for d variables
//   winfn: kernel window function name
//   M:     window half-width
//   p:     confidence level
//   Returns: nj x 3 matrix [R, CI_lo, CI_up]
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_local_corr(real matrix W_j, string scalar winfn,
                                     real scalar M, real scalar p)
{
    real scalar d, nj, t, i, k, maxd, midx, m
    real matrix result, Pj, Pinv
    real colvector kernel, wi, wk
    real scalar num, d1, d2, wt, idx, Rj, zr, se_z, zc

    d  = rows(W_j)
    nj = cols(W_j)

    result = J(nj, 3, .)

    // Build kernel
    kernel = _wv_kernel(winfn, M)

    for (t = 1; t <= nj; t++) {
        // Build weighted correlation matrix
        Pj = I(d)

        for (i = 1; i <= d; i++) {
            for (k = i + 1; k <= d; k++) {
                // Weighted correlation
                num = 0; d1 = 0; d2 = 0
                for (m = -M; m <= M; m++) {
                    idx = t + m
                    if (idx < 1 | idx > nj) continue
                    wt = kernel[m + M + 1]
                    num = num + wt * W_j[i, idx] * W_j[k, idx]
                    d1  = d1  + wt * W_j[i, idx]^2
                    d2  = d2  + wt * W_j[k, idx]^2
                }
                Pj[i, k] = num / (sqrt(d1) * sqrt(d2) + 1e-30)
                Pj[k, i] = Pj[i, k]
            }
        }

        Pinv = luinv(Pj)
        maxd = 0
        for (i = 1; i <= d; i++) {
            if (Pinv[i, i] > maxd) maxd = Pinv[i, i]
        }

        Rj   = sqrt(max((1 - 1/maxd, 0)))
        zr   = atanh(Rj)
        se_z = 1 / sqrt(nj - 3)
        zc   = invnormal((1 + p) / 2)

        result[t, .] = (Rj, tanh(zr - zc * se_z), tanh(zr + zc * se_z))
    }

    return(result)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_kernel(): Kernel window function
//   winfn: "gaussian" (default), "uniform", "bartlett", "epanechnikov"
//   M:     half-width
//   Returns: (2M+1) x 1 kernel weights (normalized)
// ═══════════════════════════════════════════════════════════════════════════
real colvector function _wv_kernel(string scalar winfn, real scalar M)
{
    real colvector w
    real scalar i, u, n
    n = 2 * M + 1
    w = J(n, 1, 0)

    for (i = 1; i <= n; i++) {
        u = (i - M - 1) / M

        if (winfn == "gaussian") {
            w[i] = exp(-0.5 * u^2)
        }
        else if (winfn == "uniform") {
            w[i] = 1
        }
        else if (winfn == "bartlett" | winfn == "triangular") {
            w[i] = 1 - abs(u)
        }
        else if (winfn == "epanechnikov") {
            w[i] = max((1 - u^2, 0))
        }
        else if (winfn == "tricube" | winfn == "cleveland") {
            w[i] = max(((1 - abs(u)^3)^3, 0))
        }
        else {
            // Default: Gaussian
            w[i] = exp(-0.5 * u^2)
        }
    }

    // Normalize
    w = w :/ sum(w)
    return(w)
}

end
