*! _cobreakcoint_mata.ado — Mata engine for cobreakcoint
*! Version 1.0.0 — 2026-04-18
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Faithful translation of MATLAB code by Carrion-i-Silvestre & Kim (2019)
*! Files: longvar.m, DOLS_reg_maker.m, CK_Qknown_new.m,
*!        CK_Qunknown1_Bdate.m, CK_Qunknown2_Bdate.m, Application_Rev.m

version 14
set matastrict off

// ═══════════════════════════════════════════════════════════════════════════
//  MATA CODE BLOCK
// ═══════════════════════════════════════════════════════════════════════════

mata:
mata clear

// ─────────────────────────────────────────────────────────────────────────
//  _cbc_longvar()  —  Long-run variance estimator  [longvar.m]
//
//  Estimate 2*pi*h(0) using the Quadratic Spectral kernel
//  with Andrews (1991) data-dependent bandwidth (AR(1) approximation).
//  c = 1 if vhat includes an intercept term (in first column), else c = 0.
// ─────────────────────────────────────────────────────────────────────────
real matrix _cbc_longvar(real matrix vhat, real scalar c)
{
    real scalar T, n, j, i, idx, ind
    real matrix Gamma, gamma, S, Shat
    real colvector rho, sig, v, vh, vl, e
    real scalar r, numerator, denominator, alpha, m, d, w

    T = rows(vhat)
    n = cols(vhat)

    // Compute all autocovariance matrices Gamma(j), j = 0,...,T-1
    Gamma = J(T*n, n, 0)
    for (j = 0; j <= T-1; j++) {
        gamma = (1/T) * vhat[j+1::T,.]' * vhat[1::T-j,.]
        Gamma[n*j+1::n*(j+1), .] = gamma
    }

    // Andrews (1991) bandwidth selection via AR(1) approximation
    rho = J(n-c, 1, 0)
    sig = J(n-c, 1, 0)

    for (i = 1+c; i <= n; i++) {
        v  = vhat[., i]
        vh = v[2::T]
        vl = v[1::T-1]
        r  = lusolve(vl'*vl, vl'*vh)
        rho[i-c] = r
        e  = vh - vl * r
        sig[i-c] = (e'*e) / T
    }

    numerator   = 0
    denominator = 0
    for (idx = 1; idx <= n-c; idx++) {
        numerator   = numerator   + 4 * (rho[idx]^2) * (sig[idx]^2) / ((1-rho[idx])^8)
        denominator = denominator + (sig[idx]^2) / ((1-rho[idx])^4)
    }

    alpha = numerator / denominator
    m     = 1.3221 * (alpha * T)^(1/5)

    // Apply QS kernel
    S = Gamma[1::n, .]

    for (ind = 1; ind <= T-1; ind++) {
        d = 6 * pi() * (ind/m) / 5
        w = 3 * (sin(d)/d - cos(d)) / (d^2)
        S = S + w * Gamma[ind*n+1::ind*n+n, .]
    }

    for (ind = 1; ind <= T-1; ind++) {
        d = 6 * pi() * (-ind/m) / 5
        w = 3 * (sin(d)/d - cos(d)) / (d^2)
        S = S + w * Gamma[ind*n+1::ind*n+n, .]'
    }

    Shat = S * (T / (T - n))
    return(Shat)
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_dols_reg()  —  Build DOLS regressors  [DOLS_reg_maker.m]
//
//  Returns matrix U of first differences of x plus leads and lags.
// ─────────────────────────────────────────────────────────────────────────
real matrix _cbc_dols_reg(real matrix x, real scalar klags, real scalar kleads)
{
    real scalar T, Tn, idx
    real matrix dx, U

    T  = rows(x)
    Tn = T - kleads - klags - 1

    dx = x[2::T, .] - x[1::T-1, .]
    U  = dx[1::Tn, .]
    for (idx = 2; idx <= kleads + klags + 1; idx++) {
        U = U, dx[idx::Tn+idx-1, .]
    }
    return(U)
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_qknown()  —  Q statistics with known break dates  [CK_Qknown_new.m]
//
//  Inputs:
//    y       — T x 1 dependent variable
//    x       — T x px regressors
//    Model   — 1 or 2
//    Tb      — m x 1 vector of break dates (empty for no-break case)
//    lbar    — lambda_hat scalar
//    klags   — number of DOLS lags
//    kleads  — number of DOLS leads
//
//  Returns: Q1 (robust CI), Q2 (CI+CB), Q3 (CI+CT)
// ─────────────────────────────────────────────────────────────────────────
real rowvector _cbc_qknown(real colvector y, real matrix x,
                           real scalar Model, real colvector Tb,
                           real scalar lbar, real scalar klags, real scalar kleads)
{
    real scalar T, m, Theta_hat, Tn, adj, px
    real colvector D0, DT0, y0, ycb, yct, y1, res1
    real matrix DU, W0, W0cb, W0ct, WW0, WW0cb, WW0ct, U
    real matrix Psi_theta_hat, W1, WW1
    real scalar s20, s2cb, s2ct, ssr0, ssrcb, ssrct, ssr1
    real scalar Q1, Q2, Q3
    real scalar j
    real matrix d, dd, dx, alphax, dX0, dXl, dXh, A, Ex, SG, SGx
    real colvector cx

    T  = rows(x)
    px = cols(x)
    m = rows(Tb)
    if (m > 0) {
        if (Tb[1] == .) m = 0
    }
    Theta_hat = 1 - lbar / T

    D0  = J(T, 1, 1)
    DT0 = (1::T)

    // Generate step dummy variables
    DU = J(T, 0, .)
    for (j = 1; j <= m; j++) {
        DU = DU, (J(Tb[j], 1, 0) \ J(T - Tb[j], 1, 1))
    }

    // Adjustment for Model II cotrending
    if (Model == 1 | m == 0) {
        adj = 0
    }
    else {
        // Model II adjustment (only when breaks present)
        d  = D0, DU, DT0
        dd = d[2::T, .] - d[1::T-1, .]
        dd = dd[., 2::cols(dd)]
        dx = x[2::T, .] - x[1::T-1, .]

        alphax = lusolve(dd'*dd, dd'*dx)
        cx     = alphax[rows(alphax), .]'

        dX0  = dx - dd * alphax
        dXl  = dX0[1::rows(dX0)-1, .]
        dXh  = dX0[2::rows(dX0), .]
        A    = (lusolve(dXl'*dXl, dXl'*dXh))'
        Ex   = dXh - dXl * A'
        SG   = (Ex'*Ex) / (T - 1)
        SGx  = cholesky(SG)
        adj  = -2 * ln(cx' * luinv(SGx) * (I(rows(A)) - A) * cx) + ln(cx'*cx)
    }

    // Build regressors depending on endogeneity correction
    if (klags == 0 & kleads == 0) {
        Tn = T
        if (Model == 1) {
            if (m > 0) W0 = x, D0, DU
            else       W0 = x, D0
            W0cb = x, D0
            W0ct = W0cb
        }
        else {
            if (m > 0) W0 = x, D0, DU, DT0
            else       W0 = x, D0, DT0
            W0cb = x, D0, DT0
            W0ct = x, D0
        }
    }
    else {
        Tn  = T - kleads - klags - 1
        y   = y[klags+2::T-kleads]
        U   = _cbc_dols_reg(x, klags, kleads)
        x   = x[klags+2::T-kleads, .]
        D0  = D0[klags+2::T-kleads]
        if (m > 0) {
            DU = DU[klags+2::T-kleads, .]
        }
        DT0 = DT0[klags+2::T-kleads]

        if (Model == 1) {
            if (m > 0) W0 = x, D0, DU, U
            else       W0 = x, D0, U
            W0cb = x, D0, U
            W0ct = W0cb
        }
        else {
            if (m > 0) W0 = x, D0, DU, DT0, U
            else       W0 = x, D0, DT0, U
            W0cb = x, D0, DT0, U
            W0ct = x, D0, U
        }
    }

    WW0   = W0' * W0
    WW0cb = W0cb' * W0cb
    WW0ct = W0ct' * W0ct

    // Detrend y under different hypotheses
    y0  = y - W0   * lusolve(WW0,   W0'  * y)
    ycb = y - W0cb * lusolve(WW0cb, W0cb' * y)
    yct = y - W0ct * lusolve(WW0ct, W0ct' * y)

    // Long-run variance estimates
    s20  = _cbc_longvar(y0,  0)[1,1] * ((Tn-1) / (Tn - cols(W0)))
    s2cb = _cbc_longvar(ycb, 0)[1,1] * ((Tn-1) / (Tn - cols(W0cb)))
    s2ct = _cbc_longvar(yct, 0)[1,1] * ((Tn-1) / (Tn - cols(W0ct)))

    // Sum of squared residuals
    ssr0   = y0'  * y0
    ssrcb  = ycb' * ycb
    ssrct  = yct' * yct

    // Psi^(1/2) matrix for the alternative model
    Psi_theta_hat = I(Tn) + (1 - Theta_hat) * (lowertriangle(J(Tn, Tn, 1)) - I(Tn))

    // Transform for alternative hypothesis
    y1  = lusolve(Psi_theta_hat, y)
    W1  = lusolve(Psi_theta_hat, W0)
    WW1 = W1' * W1
    res1 = y1 - W1 * lusolve(WW1, W1' * y1)
    ssr1 = res1' * res1

    // Test statistics
    Q1 = -2 * (-ssr0  /s20 /2 - ln(det(WW0))  /2 + ssr1/s20 /2 + ln(det(WW1))/2)
    Q2 = -2 * (-ssrcb /s2cb/2 - ln(det(WW0cb))/2 + ssr1/s2cb/2 + ln(det(WW1))/2) + m*ln(T)
    Q3 = -2 * (-ssrct /s2ct/2 - ln(det(WW0ct))/2 + ssr1/s2ct/2 + ln(det(WW1))/2) + adj + (m+2)*ln(T)

    return((Q1, Q2, Q3))
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_qunknown1()  —  Q statistics with 1 unknown break  [CK_Qunknown1_Bdate.m]
//
//  Returns: (Q1, Q2, Q3, Tbhat)
// ─────────────────────────────────────────────────────────────────────────
real rowvector _cbc_qunknown1(real colvector y_orig, real matrix x_orig,
                              real scalar Model, real scalar lbar,
                              real scalar klags, real scalar kleads)
{
    real scalar T, m, epsi, Theta_hat, Tn, adj
    real colvector D0, DT0, y, ycb, yct, y1, y1cb
    real matrix x, W0cb, W0ct, WW0cb, WW0ct, U
    real matrix Psi_theta_hat, W1cb, WW1cb
    real scalar s2cb, s2ct, s2temp
    real scalar L0cb, L0ct, maxL0, maxL1, maxL1cb, maxL1ct
    real scalar Tb, Tbtemp, Tbhat, SSR0, SSRtemp
    real scalar L0temp, L1temp, L1tempcb, L1tempct
    real colvector DU, DU0, DUhat, res0, DU1, res1
    real scalar Q1, Q2, Q3
    real matrix d, dd, dx, alphax, dX0, dXl, dXh, A, Ex, SG, SGx
    real colvector cx

    m    = 1
    T    = rows(x_orig)
    epsi = 0.15

    // Make local copies to avoid modifying originals
    y = y_orig
    x = x_orig

    Theta_hat = 1 - lbar / T
    D0  = J(T, 1, 1)
    DT0 = (1::T)

    // Build base regressors (without break dummies)
    if (klags == 0 & kleads == 0) {
        Tn = T
        if (Model == 1) {
            W0cb = x, D0
            W0ct = W0cb
        }
        else {
            W0cb = x, D0, DT0
            W0ct = x, D0
        }
    }
    else {
        Tn  = T - kleads - klags - 1
        y   = y[klags+2::T-kleads]
        D0  = D0[klags+2::T-kleads]
        DT0 = DT0[klags+2::T-kleads]
        U   = _cbc_dols_reg(x, klags, kleads)
        x   = x[klags+2::T-kleads, .]

        if (Model == 1) {
            W0cb = x, D0, U
            W0ct = W0cb
        }
        else {
            W0cb = x, D0, DT0, U
            W0ct = x, D0, U
        }
    }

    WW0cb = W0cb' * W0cb
    WW0ct = W0ct' * W0ct

    ycb = y - W0cb * lusolve(WW0cb, W0cb' * y)
    yct = y - W0ct * lusolve(WW0ct, W0ct' * y)

    s2cb = _cbc_longvar(ycb, 0)[1,1] * ((Tn-1) / (Tn - cols(W0cb)))
    s2ct = _cbc_longvar(yct, 0)[1,1] * ((Tn-1) / (Tn - cols(W0ct)))

    L0cb = -(ycb'*ycb) / s2cb / 2 - ln(det(WW0cb)) / 2
    L0ct = -(yct'*yct) / s2ct / 2 - ln(det(WW0ct)) / 2

    // ── Step 1: Find break date minimizing SSR under cointegration ──
    Tbtemp = 0
    SSR0   = ycb' * ycb
    for (Tb = round(Tn*epsi)+1; Tb <= Tn - round(Tn*epsi); Tb++) {
        DU  = J(Tb, 1, 0) \ J(Tn - Tb, 1, 1)
        DU0 = DU - W0cb * lusolve(WW0cb, W0cb' * DU)
        res0 = ycb - DU0 * lusolve(DU0'*DU0, DU0'*ycb)
        SSRtemp = res0' * res0
        if (SSRtemp < SSR0) {
            SSR0   = SSRtemp
            Tbtemp = Tb
        }
    }

    DUhat = J(Tbtemp, 1, 0) \ J(Tn - Tbtemp, 1, 1)
    DUhat = DUhat - W0cb * lusolve(WW0cb, W0cb' * DUhat)
    res0  = ycb - DUhat * lusolve(DUhat'*DUhat, DUhat'*ycb)
    s2temp = _cbc_longvar(res0, 0)[1,1] * ((Tn-1) / (Tn - cols(W0cb) - 1))

    // ── Step 2: Transform for alternative hypothesis ──
    Psi_theta_hat = I(Tn) + (1 - Theta_hat) * (lowertriangle(J(Tn, Tn, 1)) - I(Tn))

    y1    = lusolve(Psi_theta_hat, y)
    W1cb  = lusolve(Psi_theta_hat, W0cb)
    WW1cb = W1cb' * W1cb
    y1cb  = y1 - W1cb * lusolve(WW1cb, W1cb' * y1)

    maxL0   = L0cb - 1000 * abs(L0cb)
    maxL1   = -(y1cb'*y1cb) / s2cb / 2 - ln(det(WW1cb)) / 2
    maxL1   = maxL1 - 1000 * abs(maxL1)
    maxL1cb = maxL1
    maxL1ct = -(y1cb'*y1cb) / s2ct / 2 - ln(det(WW1cb)) / 2
    maxL1ct = maxL1ct - 1000 * abs(maxL1ct)

    // ── Step 3: Search for break date maximizing likelihood ──
    Tbhat = 0
    for (Tb = round(Tn*epsi)+1; Tb <= Tn - round(Tn*epsi); Tb++) {
        DU  = J(Tb, 1, 0) \ J(Tn - Tb, 1, 1)

        // Under H0 (cointegration)
        DU0  = DU - W0cb * lusolve(WW0cb, W0cb' * DU)
        res0 = ycb - DU0 * lusolve(DU0'*DU0, DU0'*ycb)
        L0temp = -(res0'*res0) / s2temp / 2 - ln(det(WW0cb)) / 2 - ln(det(DU0'*DU0)) / 2

        if (L0temp > maxL0) {
            maxL0 = L0temp
            Tbhat = Tb
        }

        // Under H1 (no cointegration)
        DU1  = lusolve(Psi_theta_hat, DU)
        DU1  = DU1 - W1cb * lusolve(WW1cb, W1cb' * DU1)
        res1 = y1cb - DU1 * lusolve(DU1'*DU1, DU1'*y1cb)

        L1temp   = -(res1'*res1) / s2temp / 2 - ln(det(WW1cb)) / 2 - ln(det(DU1'*DU1)) / 2
        L1tempcb = -(res1'*res1) / s2cb   / 2 - ln(det(WW1cb)) / 2 - ln(det(DU1'*DU1)) / 2
        L1tempct = -(res1'*res1) / s2ct   / 2 - ln(det(WW1cb)) / 2 - ln(det(DU1'*DU1)) / 2

        maxL1   = max((maxL1,   L1temp))
        maxL1cb = max((maxL1cb, L1tempcb))
        maxL1ct = max((maxL1ct, L1tempct))
    }

    // ── Model II trend adjustment ──
    if (Model == 1) {
        adj = 0
    }
    else {
        DUhat = J(Tbhat, 1, 0) \ J(Tn - Tbhat, 1, 1)
        d  = D0, DUhat, DT0
        dd = d[2::rows(d), .] - d[1::rows(d)-1, .]
        dd = dd[., 2::cols(dd)]
        dx = x[2::rows(x), .] - x[1::rows(x)-1, .]

        alphax = lusolve(dd'*dd, dd'*dx)
        cx     = alphax[rows(alphax), .]'

        dX0  = dx - dd * alphax
        dXl  = dX0[1::rows(dX0)-1, .]
        dXh  = dX0[2::rows(dX0), .]
        A    = (lusolve(dXl'*dXl, dXl'*dXh))'
        Ex   = dXh - dXl * A'
        SG   = (Ex'*Ex) / (T - 1)
        SGx  = cholesky(SG)
        adj  = -2 * ln(cx' * luinv(SGx) * (I(rows(A)) - A) * cx) + ln(cx'*cx)
    }

    Q1 = -2 * (maxL0 - maxL1)
    Q2 = -2 * (L0cb  - maxL1cb) + m * ln(T)
    Q3 = -2 * (L0ct  - maxL1ct) + adj + (m+2) * ln(T)

    return((Q1, Q2, Q3, Tbhat))
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_qunknown2()  —  Q statistics with 2 unknown breaks  [CK_Qunknown2_Bdate.m]
//
//  Returns: (Q1, Q2, Q3, Tbhat1, Tbhat2)
// ─────────────────────────────────────────────────────────────────────────
real rowvector _cbc_qunknown2(real colvector y_orig, real matrix x_orig,
                              real scalar Model, real scalar lbar,
                              real scalar klags, real scalar kleads)
{
    real scalar T, m, epsi, Theta_hat, Tn, adj
    real colvector D0, DT0, y, ycb, yct, y1, y1cb
    real matrix x, W0cb, W0ct, WW0cb, WW0ct, U
    real matrix Psi_theta_hat, W1cb, WW1cb
    real scalar s2cb, s2ct, s2temp
    real scalar L0cb, L0ct, maxL0, maxL1, maxL1cb, maxL1ct
    real scalar Tb, Tb2, SSR0, SSRtemp
    real scalar L0temp, L1temp, L1tempcb, L1tempct
    real matrix DU0mat, DU0, DU1mat, DU1
    real colvector res0, res1
    real rowvector Tbtemp, Tbhat
    real scalar Q1, Q2, Q3
    real matrix DUhat, d, dd, dx, alphax, dX0, dXl, dXh, A, Ex, SG, SGx
    real colvector cx

    m    = 2
    T    = rows(x_orig)
    epsi = 0.15

    y = y_orig
    x = x_orig

    Theta_hat = 1 - lbar / T
    D0  = J(T, 1, 1)
    DT0 = (1::T)

    // Build base regressors
    if (klags == 0 & kleads == 0) {
        Tn = T
        if (Model == 1) {
            W0cb = x, D0
            W0ct = W0cb
        }
        else {
            W0cb = x, D0, DT0
            W0ct = x, D0
        }
    }
    else {
        Tn  = T - kleads - klags - 1
        y   = y[klags+2::T-kleads]
        D0  = D0[klags+2::T-kleads]
        DT0 = DT0[klags+2::T-kleads]
        U   = _cbc_dols_reg(x, klags, kleads)
        x   = x[klags+2::T-kleads, .]

        if (Model == 1) {
            W0cb = x, D0, U
            W0ct = W0cb
        }
        else {
            W0cb = x, D0, DT0, U
            W0ct = x, D0, U
        }
    }

    WW0cb = W0cb' * W0cb
    WW0ct = W0ct' * W0ct

    ycb = y - W0cb * lusolve(WW0cb, W0cb' * y)
    yct = y - W0ct * lusolve(WW0ct, W0ct' * y)

    s2cb = _cbc_longvar(ycb, 0)[1,1] * ((Tn-1) / (Tn - cols(W0cb)))
    s2ct = _cbc_longvar(yct, 0)[1,1] * ((Tn-1) / (Tn - cols(W0ct)))

    L0cb = -(ycb'*ycb) / s2cb / 2 - ln(det(WW0cb)) / 2
    L0ct = -(yct'*yct) / s2ct / 2 - ln(det(WW0ct)) / 2

    // ── Pre-compute all projected dummy columns ──
    DU0mat = lowertriangle(J(Tn, Tn, 1), 0)
    DU0mat = DU0mat - W0cb * lusolve(WW0cb, W0cb' * DU0mat)

    // ── Step 1: Grid search for break dates minimizing SSR ──
    Tbtemp = (0, 0)
    SSR0   = ycb' * ycb
    DU0    = J(Tn, 2, 0)

    for (Tb = round(Tn*epsi)+1; Tb <= Tn - round(Tn*epsi)*2; Tb++) {
        DU0[., 1] = DU0mat[., Tb+1]
        for (Tb2 = Tb + round(Tn*epsi); Tb2 <= Tn - round(Tn*epsi); Tb2++) {
            DU0[., 2] = DU0mat[., Tb2+1]
            res0 = ycb - DU0 * lusolve(DU0'*DU0, DU0'*ycb)
            SSRtemp = res0' * res0
            if (SSRtemp < SSR0) {
                SSR0   = SSRtemp
                Tbtemp = (Tb, Tb2)
            }
        }
    }

    DUhat = DU0mat[., Tbtemp[1]+1], DU0mat[., Tbtemp[2]+1]
    res0  = ycb - DUhat * lusolve(DUhat'*DUhat, DUhat'*ycb)
    s2temp = _cbc_longvar(res0, 0)[1,1] * ((Tn-1) / (Tn - cols(W0cb) - 2))

    // ── Step 2: Transform for alternative hypothesis ──
    Psi_theta_hat = I(Tn) + (1 - Theta_hat) * (lowertriangle(J(Tn, Tn, 1)) - I(Tn))

    y1    = lusolve(Psi_theta_hat, y)
    W1cb  = lusolve(Psi_theta_hat, W0cb)
    WW1cb = W1cb' * W1cb
    y1cb  = y1 - W1cb * lusolve(WW1cb, W1cb' * y1)

    maxL0   = L0cb - 1000 * abs(L0cb)
    maxL1   = -(y1cb'*y1cb) / s2cb / 2 - ln(det(WW1cb)) / 2
    maxL1   = maxL1 - 1000 * abs(maxL1)
    maxL1cb = maxL1
    maxL1ct = -(y1cb'*y1cb) / s2ct / 2 - ln(det(WW1cb)) / 2
    maxL1ct = maxL1ct - 1000 * abs(maxL1ct)

    // Pre-compute transformed projected dummies
    DU1mat = lusolve(Psi_theta_hat, lowertriangle(J(Tn, Tn, 1), 0))
    DU1mat = DU1mat - W1cb * lusolve(WW1cb, W1cb' * DU1mat)

    // ── Step 3: Grid search maximizing likelihood ──
    Tbhat = (0, 0)
    DU0   = J(Tn, 2, 0)
    DU1   = J(Tn, 2, 0)

    for (Tb = round(Tn*epsi)+1; Tb <= Tn - round(Tn*epsi)*2; Tb++) {
        DU0[., 1] = DU0mat[., Tb+1]
        DU1[., 1] = DU1mat[., Tb+1]

        for (Tb2 = Tb + round(Tn*epsi); Tb2 <= Tn - round(Tn*epsi); Tb2++) {
            DU0[., 2] = DU0mat[., Tb2+1]
            res0 = ycb - DU0 * lusolve(DU0'*DU0, DU0'*ycb)
            L0temp = -(res0'*res0) / s2temp / 2 - ln(det(WW0cb)) / 2 - ln(det(DU0'*DU0)) / 2

            if (L0temp > maxL0) {
                maxL0 = L0temp
                Tbhat = (Tb, Tb2)
            }

            DU1[., 2] = DU1mat[., Tb2+1]
            res1 = y1cb - DU1 * lusolve(DU1'*DU1, DU1'*y1cb)

            L1temp   = -(res1'*res1) / s2temp / 2 - ln(det(WW1cb)) / 2 - ln(det(DU1'*DU1)) / 2
            L1tempcb = -(res1'*res1) / s2cb   / 2 - ln(det(WW1cb)) / 2 - ln(det(DU1'*DU1)) / 2
            L1tempct = -(res1'*res1) / s2ct   / 2 - ln(det(WW1cb)) / 2 - ln(det(DU1'*DU1)) / 2

            maxL1   = max((maxL1,   L1temp))
            maxL1cb = max((maxL1cb, L1tempcb))
            maxL1ct = max((maxL1ct, L1tempct))
        }
    }

    // ── Model II adjustment ──
    if (Model == 1) {
        adj = 0
    }
    else {
        DUhat = DU0mat[., Tbhat[1]+1], DU0mat[., Tbhat[2]+1]
        d  = D0, DUhat, DT0
        dd = d[2::rows(d), .] - d[1::rows(d)-1, .]
        dd = dd[., 2::cols(dd)]
        dx = x[2::rows(x), .] - x[1::rows(x)-1, .]

        alphax = lusolve(dd'*dd, dd'*dx)
        cx     = alphax[rows(alphax), .]'

        dX0  = dx - dd * alphax
        dXl  = dX0[1::rows(dX0)-1, .]
        dXh  = dX0[2::rows(dX0), .]
        A    = (lusolve(dXl'*dXl, dXl'*dXh))'
        Ex   = dXh - dXl * A'
        SG   = (Ex'*Ex) / (T - 1)
        SGx  = cholesky(SG)
        adj  = -2 * ln(cx' * luinv(SGx) * (I(rows(A)) - A) * cx) + ln(cx'*cx)
    }

    Q1 = -2 * (maxL0 - maxL1)
    Q2 = -2 * (L0cb  - maxL1cb) + m * ln(T)
    Q3 = -2 * (L0ct  - maxL1ct) + adj + (m+2) * ln(T)

    return((Q1, Q2, Q3, Tbhat[1], Tbhat[2]))
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_get_lbar()  —  Lambda-bar parameters from paper's Appendix
//
//  Returns lambda_hat for given (model, m, px)
//  Data from Lbar{m}{Model}n.txt files
// ─────────────────────────────────────────────────────────────────────────
real scalar _cbc_get_lbar(real scalar model, real scalar m, real scalar px)
{
    real matrix Lbar

    // Model 1 tables
    if (model == 1) {
        // m=0 breaks: Lbar01n.txt col 4
        if (m == 0) {
            Lbar = (9.1 \ 10.8 \ 12.4 \ 13.9 \ 15.5)
        }
        // m=1 break: Lbar11n.txt col 4
        else if (m == 1) {
            Lbar = (11.4 \ 12.9 \ 14.4 \ 15.9 \ 17.4)
        }
        // m=2 breaks: Lbar21n.txt col 4
        else {
            Lbar = (13.8 \ 15.2 \ 16.6 \ 18.0 \ 19.3)
        }
    }
    // Model 2 tables
    else {
        if (m == 0) {
            Lbar = (13.3 \ 14.6 \ 16.0 \ 17.4 \ 19.1)
        }
        else if (m == 1) {
            Lbar = (14.9 \ 16.3 \ 17.6 \ 19.1 \ 20.6)
        }
        else {
            Lbar = (16.9 \ 18.1 \ 19.5 \ 20.9 \ 22.7)
        }
    }

    if (px >= 1 & px <= 5) {
        return(Lbar[px])
    }
    else {
        // Extrapolate linearly for px > 5
        return(Lbar[5] + (px - 5) * (Lbar[5] - Lbar[4]))
    }
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_get_dmax_params()  —  Dmax tuning parameters from Application_Rev.m
//
//  Returns 3x3 matrix: rows = m=0,1,2; cols = (a_m, cv99, b_m)
//  For cobreaking (type=1) or cotrending (type=2)
// ─────────────────────────────────────────────────────────────────────────
real matrix _cbc_get_dmax_params(real scalar model, real scalar px, real scalar type)
{
    real matrix TB

    if (type == 1) {
        // Cobreaking: TB_CB
        if (model == 1) {
            if (px == 1) TB = (1.68, 4.06 \ 11.27, 14.91 \ 18.96, 23.26)
            else         TB = (1.69, 4.07 \ 12.13, 15.97 \ 20.42, 24.92)
        }
        else {
            if (px == 1) TB = (1.77, 4.02 \ 13.07, 16.76 \ 22.02, 26.43)
            else         TB = (1.83, 4.10 \ 13.55, 17.38 \ 22.93, 27.31)
        }
    }
    else {
        // Cotrending: TB_CT
        if (model == 1) {
            // No cotrending test for Model I
            TB = (0, 1 \ 0, 1 \ 0, 1)
        }
        else {
            if (px == 1) TB = (6.78, 9.94 \ 17.43, 21.54 \ 26.36, 31.10)
            else         TB = (6.93, 10.00 \ 18.10, 22.11 \ 27.33, 31.81)
        }
    }

    // Add b_m column (cv99 - cv95 = col2 - col1)
    TB = TB, TB[., 2] - TB[., 1]
    return(TB)
}


// ─────────────────────────────────────────────────────────────────────────
//  _cbc_get_critval()  —  Critical values for individual Q tests
//
//  Returns (cv10, cv05, cv01) row vector
//  Based on Application_Rev.m line 120 (5% CVs for Model II, px=1)
// ─────────────────────────────────────────────────────────────────────────
real rowvector _cbc_get_critval(real scalar model, real scalar px,
                                real scalar m, string scalar testtype)
{
    // Critical values from paper Table S-I (Supplementary Appendix)
    // Format: (10%, 5%, 1%) — reject if Q > cv

    if (model == 2 & px == 1) {
        if (testtype == "Qr") {
            if (m == 0) return((0.88, 1.77, 6.63))
            if (m == 1) return((0.89, 1.79, 6.87))
            if (m == 2) return((0.86, 1.73, 6.55))
        }
        if (testtype == "Qcb") {
            if (m == 0) return((0.88, 1.77, 6.63))
            if (m == 1) return((8.56, 13.07, 23.03))
            if (m == 2) return((15.29, 22.02, 36.99))
        }
        if (testtype == "Qct") {
            if (m == 0) return((3.78, 6.78, 14.32))
            if (m == 1) return((12.22, 17.43, 28.79))
            if (m == 2) return((19.57, 26.36, 41.06))
        }
        if (testtype == "Dmax_cb") {
            return((0.20, 0.39, 1.00))
        }
        if (testtype == "Dmax_ct") {
            return((0.16, 0.32, 1.00))
        }
    }
    else if (model == 2 & px == 2) {
        if (testtype == "Qr") {
            if (m == 0) return((0.91, 1.83, 6.84))
            if (m == 1) return((0.92, 1.84, 7.01))
            if (m == 2) return((0.89, 1.80, 6.78))
        }
        if (testtype == "Qcb") {
            if (m == 0) return((0.91, 1.83, 6.84))
            if (m == 1) return((8.92, 13.55, 23.72))
            if (m == 2) return((15.93, 22.93, 38.30))
        }
        if (testtype == "Qct") {
            if (m == 0) return((3.91, 6.93, 14.58))
            if (m == 1) return((12.59, 18.10, 29.73))
            if (m == 2) return((20.19, 27.33, 42.18))
        }
        if (testtype == "Dmax_cb") {
            return((0.21, 0.40, 1.00))
        }
        if (testtype == "Dmax_ct") {
            return((0.17, 0.33, 1.00))
        }
    }
    else if (model == 1 & px == 1) {
        if (testtype == "Qr") {
            if (m == 0) return((0.84, 1.68, 6.30))
            if (m == 1) return((0.85, 1.70, 6.45))
            if (m == 2) return((0.82, 1.65, 6.15))
        }
        if (testtype == "Qcb") {
            if (m == 0) return((0.84, 1.68, 6.30))
            if (m == 1) return((7.48, 11.27, 20.12))
            if (m == 2) return((13.02, 18.96, 32.18))
        }
        if (testtype == "Qct") {
            // No cotrending for Model I
            return((., ., .))
        }
        if (testtype == "Dmax_cb") {
            return((0.20, 0.39, 1.00))
        }
        if (testtype == "Dmax_ct") {
            return((., ., .))
        }
    }
    else if (model == 1 & px == 2) {
        if (testtype == "Qr") {
            if (m == 0) return((0.85, 1.69, 6.38))
            if (m == 1) return((0.86, 1.71, 6.53))
            if (m == 2) return((0.83, 1.66, 6.25))
        }
        if (testtype == "Qcb") {
            if (m == 0) return((0.85, 1.69, 6.38))
            if (m == 1) return((7.98, 12.13, 21.44))
            if (m == 2) return((13.82, 20.42, 34.18))
        }
        if (testtype == "Qct") {
            return((., ., .))
        }
        if (testtype == "Dmax_cb") {
            return((0.21, 0.40, 1.00))
        }
        if (testtype == "Dmax_ct") {
            return((., ., .))
        }
    }

    // Default fallback
    return((., ., .))
}


// ─────────────────────────────────────────────────────────────────────────
//  cobreakcoint_main()  —  Main orchestration function  [Application_Rev.m]
//
//  Called from cobreakcoint.ado. Stores results in Stata matrices/scalars.
// ─────────────────────────────────────────────────────────────────────────
void cobreakcoint_main(string scalar depvar, string scalar indepvar,
                       string scalar touse,
                       real scalar Model, real scalar maxbreaks,
                       string scalar klags_str, real scalar verbose)
{
    real colvector y, x_vec
    real matrix x
    real scalar T, px, k, nk
    real matrix TestM, Bmat, Bfm
    real rowvector Q0, Q1, Q2, ACV5
    real scalar lbar0, lbar1, lbar2
    real matrix TB_CB, TB_CT
    real scalar a0, a1, a2, b0, b1, b2, c0, c1, c2, d0, d1, d2
    real scalar Q4, Q5
    real rowvector klags_vec
    real scalar i

    // ── Load data from Stata ──
    st_view(y,  ., depvar,  touse)
    st_view(x,  ., tokens(indepvar), touse)

    T  = rows(y)
    px = cols(x)

    // ── Parse lags/leads string (e.g., "1 3 5 7 9") ──
    klags_vec = strtoreal(tokens(klags_str))
    nk = cols(klags_vec)

    // ── Lambda-bar parameters ──
    lbar0 = _cbc_get_lbar(Model, 0, px)
    lbar1 = _cbc_get_lbar(Model, 1, px)
    lbar2 = _cbc_get_lbar(Model, 2, px)

    // ── Dmax tuning parameters ──
    TB_CB = _cbc_get_dmax_params(Model, px, 1)
    TB_CT = _cbc_get_dmax_params(Model, px, 2)

    a0 = TB_CB[1,1]; a1 = TB_CB[2,1]; a2 = TB_CB[3,1]
    b0 = TB_CB[1,3]; b1 = TB_CB[2,3]; b2 = TB_CB[3,3]
    c0 = TB_CT[1,1]; c1 = TB_CT[2,1]; c2 = TB_CT[3,1]
    d0 = TB_CT[1,3]; d1 = TB_CT[2,3]; d2 = TB_CT[3,3]

    // ── Main loop over leads/lags ──
    TestM = J(0, 12, .)
    Bmat  = J(0, 6, .)

    for (i = 1; i <= nk; i++) {
        k = klags_vec[i]

        if (verbose) {
            printf("  Computing k = %g (lags = leads = %g) ...\n", k, k)
        }

        // No break (m=0) — known break with Tb=[]
        Q0 = _cbc_qknown(y, x, Model, J(0,1,.), lbar0, k, k)

        // 1 unknown break
        Q1 = _cbc_qunknown1(y, x, Model, lbar1, k, k)

        // 2 unknown breaks (only if maxbreaks >= 2)
        if (maxbreaks >= 2) {
            Q2 = _cbc_qunknown2(y, x, Model, lbar2, k, k)
        }
        else {
            Q2 = (., ., ., ., .)
        }

        // Combine: (Q01,Q02,Q03, Q11,Q12,Q13, Q21,Q22,Q23)
        // Indices:   1    2   3    4   5   6    7   8   9
        Q4 = max(( (Q0[1]-a0)/b0, (Q1[1]-a1)/b1, (Q2[1]-a2)/b2 ))
        Q5 = max(( (Q0[3]-c0)/d0, (Q1[3]-c1)/d1, (Q2[3]-c2)/d2 ))

        TestM = TestM \ (Q0[1], Q0[2], Q0[3], Q1[1], Q1[2], Q1[3],
                         Q2[1], Q2[2], Q2[3], Q4, Q5, k)

        // Break date info
        if (maxbreaks >= 2) {
            Bmat = Bmat \ (Q1[4]+(k+2), 0, 0, Q2[4]+(k+2), Q2[5]+(k+2), k)
        }
        else {
            Bmat = Bmat \ (Q1[4]+(k+2), 0, 0, ., ., k)
        }
    }

    // ── Critical values row (5% level) ──
    ACV5 = _cbc_get_critval(Model, px, 0, "Qr")[2],
           _cbc_get_critval(Model, px, 0, "Qcb")[2],
           _cbc_get_critval(Model, px, 0, "Qct")[2],
           _cbc_get_critval(Model, px, 1, "Qr")[2],
           _cbc_get_critval(Model, px, 1, "Qcb")[2],
           _cbc_get_critval(Model, px, 1, "Qct")[2],
           _cbc_get_critval(Model, px, 2, "Qr")[2],
           _cbc_get_critval(Model, px, 2, "Qcb")[2],
           _cbc_get_critval(Model, px, 2, "Qct")[2],
           _cbc_get_critval(Model, px, 0, "Dmax_cb")[2],
           _cbc_get_critval(Model, px, 0, "Dmax_ct")[2],
           0

    // ── Break fractions ──
    Bfm = round(Bmat[., 1::cols(Bmat)-1] / T * 100) / 100

    // ── Store results in Stata ──
    st_matrix("_cbc_TestM", TestM)
    st_matrix("_cbc_ACV5",  ACV5)
    st_matrix("_cbc_Bmat",  Bmat)
    st_matrix("_cbc_Bfm",   Bfm)

    st_numscalar("_cbc_T",     T)
    st_numscalar("_cbc_px",    px)
    st_numscalar("_cbc_model", Model)
    st_numscalar("_cbc_nk",    nk)
    st_numscalar("_cbc_maxm",  maxbreaks)
}

end
