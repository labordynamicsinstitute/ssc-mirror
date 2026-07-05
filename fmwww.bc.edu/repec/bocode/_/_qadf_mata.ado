*! _qadf_mata.ado - Mata library for the QADF (quantile ADF) unit-root test
*! Version 1.1.0, 03 July 2026
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
*! GAUSS code reference: qr_adf.src, Saban Nazlioglu (tspdlib)
*!
*! Version 1.1.0 changes (exact compatibility with the GAUSS source):
*!   - quantile regressions now solved exactly by Stata's qreg (the ado files
*!     pass the coefficient vectors here); the IRLS approximation is gone
*!   - ADF lag selection uses the tspdlib penalties ln(ssr/n)+2(k+2)/n (AIC)
*!     and ln(ssr/n)+(k+2)ln(n)/n (SIC/BIC), and the general-to-specific
*!     t-stat rule with the 1.645 threshold (previously 1.96)
*!   - delta-squared is no longer clamped to [0.01, 0.99] (the critical-value
*!     interpolation saturates by itself, as in the source)
*!   - the bootstrap re-runs the entire procedure (including lag re-selection)
*!     on every replication through the qadf_core command

capture program drop _qadf_mata
program define _qadf_mata
    version 14.0
    di as txt "QADF Mata library (v1.1.0) loaded successfully."
end

version 14.0
mata:

// presence check used by the ado files to avoid recompiling on every call
void qadfm_ping()
{
    return
}

// ---------------------------------------------------------------------------
// tspdlib _get_lag: index (1..pmax+1) of the selected lag+1
// icn 1 = AIC (first minimum), 2 = SIC/BIC, 3 = general-to-specific t-stat
// with the 1.645 threshold, exactly as in the GAUSS source
// ---------------------------------------------------------------------------
real scalar qadfm_getlagidx(real scalar icn, real colvector aicp,
    real colvector sicp, real colvector tstatp)
{
    real scalar pidx, j, n
    real colvector v

    n = rows(aicp)
    pidx = 1
    if (icn == 1) {
        v = aicp
        for (j = 2; j <= n; j++) {
            if (v[j] < v[pidx]) {
                pidx = j
            }
        }
    }
    else if (icn == 2) {
        v = sicp
        for (j = 2; j <= n; j++) {
            if (v[j] < v[pidx]) {
                pidx = j
            }
        }
    }
    else {
        pidx = 1
        j = n
        while (j >= 2) {
            if (tstatp[j] > 1.645) {
                pidx = j
                break
            }
            j = j - 1
        }
    }
    return(pidx)
}

// ---------------------------------------------------------------------------
// tspdlib ADF(y, 1, pmax, ic) lag selection (constant model), exact:
// dep = dy trimmed twice; x = [y_{t-1}, const, dy lags]; (k+2) penalties.
// Sets r(adflag) = selected lag count and r(adf_t) = ADF t at that lag.
// ---------------------------------------------------------------------------
void qadfm_adfsel(string scalar yname, string scalar touse,
    real scalar pmax, real scalar icn)
{
    real colvector y, dy, y1, dep, bb, ee, sevec, taup, aicp, sicp, tstatp
    real matrix lmat, X, XX
    real scalar T, p, lo, n1, kx, pidx, j

    y = st_data(., yname, touse)
    T = rows(y)
    dy = y[2::T] - y[1::(T-1)]
    y1 = y[1::(T-1)]
    lmat = J(T-1, pmax, 0)
    for (j = 1; j <= pmax; j++) {
        if (T-1-j >= 1) {
            lmat[(j+1)::(T-1), j] = dy[1::(T-1-j)]
        }
    }
    taup = J(pmax+1, 1, .)
    aicp = J(pmax+1, 1, .)
    sicp = J(pmax+1, 1, .)
    tstatp = J(pmax+1, 1, .)
    for (p = 0; p <= pmax; p++) {
        lo = p + 2
        dep = dy[lo::(T-1)]
        X = y1[lo::(T-1)], J(rows(dep), 1, 1)
        if (p > 0) {
            X = X, lmat[lo::(T-1), 1::p]
        }
        n1 = rows(dep)
        kx = cols(X)
        XX = invsym(cross(X, X))
        bb = XX*cross(X, dep)
        ee = dep - X*bb
        sevec = sqrt(diagonal(XX)*(cross(ee, ee)/(n1-kx)))
        taup[p+1] = bb[1]/sevec[1]
        aicp[p+1] = ln(cross(ee, ee)/n1) + 2*(kx+2)/n1
        sicp[p+1] = ln(cross(ee, ee)/n1) + (kx+2)*ln(n1)/n1
        tstatp[p+1] = abs(bb[kx]/sevec[kx])
    }
    pidx = qadfm_getlagidx(icn, aicp, sicp, tstatp)
    st_numscalar("r(adflag)", pidx - 1)
    st_numscalar("r(adf_t)", taup[pidx])
}

// ---------------------------------------------------------------------------
// bandwidth (GAUSS: bandwidth + __get_qr_adf_h)
// Hall-Sheather (1988) with the Bofinger (1975) fallback and boundary caps
// ---------------------------------------------------------------------------
real scalar qadfm_bwhs(real scalar tau, real scalar n)
{
    real scalar x0, f0

    x0 = invnormal(tau)
    f0 = normalden(x0)
    return(n^(-1/3) * invnormal(1 - 0.05/2)^(2/3) * ((1.5*f0^2)/(2*x0^2 + 1))^(1/3))
}

real scalar qadfm_bwbof(real scalar tau, real scalar n)
{
    real scalar x0, f0

    x0 = invnormal(tau)
    f0 = normalden(x0)
    return(n^(-0.2) * ((4.5*f0^4)/(2*x0^2 + 1)^2)^0.2)
}

real scalar qadfm_h(real scalar tau, real scalar n)
{
    real scalar h

    h = qadfm_bwhs(tau, n)
    if (tau <= 0.5 & h > tau) {
        h = qadfm_bwbof(tau, n)
        if (h > tau) {
            h = tau/1.5
        }
    }
    if (tau > 0.5 & h > 1 - tau) {
        h = qadfm_bwbof(tau, n)
        if (h > 1 - tau) {
            h = (1 - tau)/1.5
        }
    }
    return(h)
}

// ---------------------------------------------------------------------------
// Hansen (1995) critical values interpolated on delta2 (GAUSS crit_QRadf)
// model: 1 = constant, 2 = constant + trend
// ---------------------------------------------------------------------------
real rowvector qadfm_cv(real scalar r2, real scalar model)
{
    real matrix crt
    real rowvector ct
    real scalar r210, r2a, r2b, wa

    if (model == 1) {
        crt = (-2.7844267, -2.1158290, -1.7525193 \
               -2.9138762, -2.2790427, -1.9172046 \
               -3.0628184, -2.3994711, -2.0573070 \
               -3.1376157, -2.5070473, -2.1680520 \
               -3.1914660, -2.5841611, -2.2520173 \
               -3.2437157, -2.6399560, -2.3163270 \
               -3.2951006, -2.7180169, -2.4085640 \
               -3.3627161, -2.7536756, -2.4577709 \
               -3.3896556, -2.8074982, -2.5037759 \
               -3.4336, -2.8621, -2.5671)
    }
    else {
        crt = (-2.9657928, -2.3081543, -1.9519926 \
               -3.1929596, -2.5482619, -2.1991651 \
               -3.3727717, -2.7283918, -2.3806008 \
               -3.4904849, -2.8669056, -2.5315918 \
               -3.6003166, -2.9853079, -2.6672416 \
               -3.6819803, -3.0954760, -2.7815263 \
               -3.7551759, -3.1783550, -2.8728146 \
               -3.8348596, -3.2674954, -2.9735550 \
               -3.8800989, -3.3316415, -3.0364171 \
               -3.9638, -3.4126, -3.1279)
    }
    if (r2 < 0.1) {
        ct = crt[1, .]
    }
    else {
        r210 = r2*10
        if (r210 >= 10) {
            ct = crt[10, .]
        }
        else {
            r2a = floor(r210)
            r2b = ceil(r210)
            if (r2a < 1) {
                r2a = 1
            }
            if (r2a == r2b) {
                ct = crt[r2a, .]
            }
            else {
                wa = r2b - r210
                ct = wa*crt[r2a, .] + (1 - wa)*crt[r2b, .]
            }
        }
    }
    return(ct)
}

// ---------------------------------------------------------------------------
// per-quantile QADF computation from the three qreg coefficient vectors
// (GAUSS QRADF tail: __get_qr_adf_stat and __get_qr_adf_delta2, exact)
// X columns (xvars) in GAUSS order: y1, dyl(1..p), (trend)
// Sets r(rho_tau) r(alpha_tau) r(rho_ols) r(delta2) r(tn) r(cv1) r(cv5) r(cv10)
// ---------------------------------------------------------------------------
void qadfm_finish(string scalar yname, string scalar xvars,
    string scalar esamp, real scalar tau, real scalar h,
    string scalar b0name, string scalar b1name, string scalar b2name,
    real scalar p, real scalar model)
{
    real colvector Y, y1, bg0, bg1, bg2, res, ind, phi, w, bols, tvec
    real matrix X, Xc, xx, ixx
    real rowvector b0, b1, b2, z1m, cv
    real scalar n, k, rho_tau, alpha_tau, rho_ols, q1, q2, dq, fz, y1p, stat
    real scalar mw, mphi, covv, sdw, delta2

    Y = st_data(., yname, esamp)
    X = st_data(., tokens(xvars), esamp)
    n = rows(Y)
    Xc = J(n, 1, 1), X

    // reorder e(b): Stata puts _cons last, GAUSS puts it first
    b0 = st_matrix(b0name)
    k = cols(b0)
    bg0 = b0[k] \ b0[1::(k-1)]'
    b1 = st_matrix(b1name)
    bg1 = b1[k] \ b1[1::(k-1)]'
    b2 = st_matrix(b2name)
    bg2 = b2[k] \ b2[1::(k-1)]'

    alpha_tau = bg0[1]
    rho_tau = bg0[2]

    // OLS comparison (GAUSS: beta_ols = y/(ones~x))
    bols = invsym(cross(Xc, Xc))*cross(Xc, Y)
    rho_ols = bols[2]

    // density at the quantile: fz = 2h / (q1 - q2)
    z1m = 1, mean(X)
    q1 = z1m*bg1
    q2 = z1m*bg2
    dq = q1 - q2
    if (dq == 0) {
        fz = 0.01
    }
    else {
        fz = 2*h/dq
    }
    if (fz < 0) {
        fz = 0.01
    }

    // projection off [1, dyl] only (the source excludes the trend)
    y1 = X[., 1]
    if (p > 0) {
        xx = J(n, 1, 1), X[., 2::(p+1)]
    }
    else {
        xx = J(n, 1, 1)
    }
    ixx = invsym(cross(xx, xx))
    tvec = cross(xx, y1)
    y1p = cross(y1, y1) - tvec'*ixx*tvec
    if (y1p < 0) {
        y1p = 0
    }
    stat = fz/sqrt(tau*(1 - tau)) * sqrt(y1p) * (rho_tau - 1)

    // delta2 with w = dy (unclamped, exactly as the source)
    res = Y - Xc*bg0
    ind = res :< 0
    phi = J(n, 1, tau) - ind
    w = Y - y1
    mw = mean(w)
    mphi = mean(phi)
    covv = sum((w :- mw) :* (phi :- mphi))/(n - 1)
    sdw = sqrt(sum((w :- mw) :* (w :- mw))/(n - 1))
    delta2 = (covv/(sdw*sqrt(tau*(1 - tau))))^2

    cv = qadfm_cv(delta2, model)

    st_numscalar("r(rho_tau)", rho_tau)
    st_numscalar("r(alpha_tau)", alpha_tau)
    st_numscalar("r(rho_ols)", rho_ols)
    st_numscalar("r(delta2)", delta2)
    st_numscalar("r(tn)", stat)
    st_numscalar("r(cv1)", cv[1])
    st_numscalar("r(cv5)", cv[2])
    st_numscalar("r(cv10)", cv[3])
}

// ---------------------------------------------------------------------------
// Bootstrap preparation (Koenker & Xiao 2004, section 3.2, AR sieve):
//   1. select the lag order p on the observed series (source ADF rule)
//   2. fit an AR(q) (q = max(p,1), no constant) to dy by OLS
//   3. store the centred residuals and AR coefficients in externals
// Sets r(p) (selected lag), r(T) (series length), r(m) (residual count)
// ---------------------------------------------------------------------------
void qadfm_boot_prep(string scalar yname, string scalar touse,
    real scalar pmax, real scalar icn)
{
    external real colvector __qadfm_mu, __qadfm_betas, __qadfm_dyq
    external real scalar __qadfm_y1v, __qadfm_T, __qadfm_q
    real colvector y, dy, resid
    real matrix X_ar
    real scalar T, ndy, p, q, j, t

    y = st_data(., yname, touse)
    T = rows(y)
    dy = y[2::T] - y[1::(T-1)]
    ndy = rows(dy)

    qadfm_adfsel(yname, touse, pmax, icn)
    p = st_numscalar("r(adflag)")

    q = max((p, 1))
    if (ndy > q) {
        X_ar = J(ndy - q, q, 0)
        for (j = 1; j <= q; j++) {
            for (t = 1; t <= ndy - q; t++) {
                X_ar[t, j] = dy[q + t - j]
            }
        }
        __qadfm_betas = qrsolve(X_ar, dy[(q+1)::ndy])
        resid = dy[(q+1)::ndy] - X_ar*__qadfm_betas
    }
    else {
        __qadfm_betas = J(0, 1, 0)
        resid = dy :- mean(dy)
    }
    __qadfm_mu = resid :- mean(resid)
    __qadfm_dyq = dy[1::q]
    __qadfm_y1v = y[1]
    __qadfm_T = T
    __qadfm_q = q

    st_numscalar("r(p)", p)
    st_numscalar("r(T)", T)
    st_numscalar("r(m)", rows(__qadfm_mu))
}

// draw one bootstrap series under the unit-root null (AR sieve on dy)
real colvector qadfm_drawy()
{
    external real colvector __qadfm_mu, __qadfm_betas, __qadfm_dyq
    external real scalar __qadfm_y1v, __qadfm_T, __qadfm_q
    real colvector idx, ustar, dystar, ystar
    real scalar m, q, T, i, j, dy_t, pos, nb

    m = rows(__qadfm_mu)
    q = __qadfm_q
    T = __qadfm_T
    idx = ceil(m :* runiform(m, 1))
    for (i = 1; i <= m; i++) {
        if (idx[i] < 1) {
            idx[i] = 1
        }
    }
    ustar = __qadfm_mu[idx]
    dystar = J(q + m, 1, 0)
    dystar[1::q] = __qadfm_dyq
    nb = rows(__qadfm_betas)
    for (i = 1; i <= m; i++) {
        dy_t = ustar[i]
        if (nb > 0) {
            for (j = 1; j <= q; j++) {
                pos = q + i - j
                if (pos >= 1) {
                    dy_t = dy_t + __qadfm_betas[j]*dystar[pos]
                }
            }
        }
        dystar[q + i] = dy_t
    }
    ystar = J(T, 1, __qadfm_y1v)
    for (i = 2; i <= T; i++) {
        ystar[i] = ystar[i-1] + dystar[i-1]
    }
    return(ystar)
}

// ---------------------------------------------------------------------------
// Single-quantile bootstrap: per replication draw y*, recompute the FULL
// test (including lag re-selection) via qadf_core, collect t_n and U_n.
// Left-tail critical values and the bootstrap p-value.
// ---------------------------------------------------------------------------
void qadfm_boot(string scalar ystar, real scalar tau, string scalar model,
    real scalar pmax, real scalar icn, real scalar nreps, real scalar seed,
    real scalar obs_t)
{
    real colvector yb, t_boot, u_boot, sel, t_sorted, u_sorted
    real scalar r, rc, nv, i1, i5, i10
    string scalar cmd

    if (seed < .) {
        rseed(seed)
    }
    cmd = "capture quietly qadf_core " + ystar + ", tau(" + ///
        strofreal(tau, "%18.0g") + ") model(" + model + ") pmax(" + ///
        strofreal(pmax, "%12.0g") + ") icn(" + strofreal(icn, "%12.0g") + ")"
    t_boot = J(nreps, 1, .)
    u_boot = J(nreps, 1, .)
    for (r = 1; r <= nreps; r++) {
        yb = qadfm_drawy()
        st_store(., ystar, yb)
        stata(cmd)
        rc = st_numscalar("c(rc)")
        if (rc == 0) {
            t_boot[r] = st_numscalar("r(tn)")
            u_boot[r] = st_numscalar("r(Un)")
        }
    }
    sel = (t_boot :< .)
    t_boot = select(t_boot, sel)
    u_boot = select(u_boot, sel)
    nv = rows(t_boot)
    st_numscalar("r(boot_nvalid)", nv)
    st_numscalar("r(boot_nreps)", nreps)
    if (nv < 10) {
        return
    }
    t_sorted = sort(t_boot, 1)
    u_sorted = sort(u_boot, 1)
    i1 = max((1, floor(nv*0.01)))
    i5 = max((1, floor(nv*0.05)))
    i10 = max((1, floor(nv*0.10)))
    st_numscalar("r(boot_cv1_t)", t_sorted[i1])
    st_numscalar("r(boot_cv5_t)", t_sorted[i5])
    st_numscalar("r(boot_cv10_t)", t_sorted[i10])
    st_numscalar("r(boot_cv1_u)", u_sorted[i1])
    st_numscalar("r(boot_cv5_u)", u_sorted[i5])
    st_numscalar("r(boot_cv10_u)", u_sorted[i10])
    st_numscalar("r(boot_pvalue)", sum(t_boot :<= obs_t)/nv)
}

// ---------------------------------------------------------------------------
// Process-level bootstrap for QKS/QCM: per replication compute the test at
// every requested quantile from the SAME pseudo-series, then the sup and
// Cramer-von-Mises functionals. Upper-tail critical values.
// ---------------------------------------------------------------------------
void qadfm_bootproc(string scalar ystar, string scalar taulist,
    string scalar model, real scalar pmax, real scalar icn,
    real scalar nreps, real scalar seed)
{
    real colvector yb, quantiles, t_stats, u_stats, dtau, sel
    real colvector qks_a, qks_t, qcm_a, qcm_t, sa, stv, ca, ct
    real scalar r, rc, nv, j, nq, bad, j1, j5, j10
    string scalar cmd

    if (seed < .) {
        rseed(seed)
    }
    quantiles = strtoreal(tokens(taulist))'
    nq = rows(quantiles)
    dtau = J(nq, 1, 1)
    for (j = 1; j < nq; j++) {
        dtau[j] = quantiles[j+1] - quantiles[j]
    }
    if (nq >= 2) {
        dtau[nq] = dtau[nq-1]
    }
    qks_a = J(nreps, 1, .)
    qks_t = J(nreps, 1, .)
    qcm_a = J(nreps, 1, .)
    qcm_t = J(nreps, 1, .)
    for (r = 1; r <= nreps; r++) {
        yb = qadfm_drawy()
        st_store(., ystar, yb)
        t_stats = J(nq, 1, .)
        u_stats = J(nq, 1, .)
        bad = 0
        for (j = 1; j <= nq; j++) {
            cmd = "capture quietly qadf_core " + ystar + ", tau(" + ///
                strofreal(quantiles[j], "%18.0g") + ") model(" + model + ///
                ") pmax(" + strofreal(pmax, "%12.0g") + ") icn(" + ///
                strofreal(icn, "%12.0g") + ")"
            stata(cmd)
            rc = st_numscalar("c(rc)")
            if (rc != 0) {
                bad = 1
                break
            }
            t_stats[j] = st_numscalar("r(tn)")
            u_stats[j] = st_numscalar("r(Un)")
        }
        if (bad == 1) {
            continue
        }
        if (missing(t_stats) > 0) {
            continue
        }
        qks_a[r] = max(abs(u_stats))
        qks_t[r] = max(abs(t_stats))
        qcm_a[r] = sum((u_stats:^2) :* dtau)
        qcm_t[r] = sum((t_stats:^2) :* dtau)
    }
    sel = (qks_t :< .)
    qks_a = select(qks_a, sel)
    qks_t = select(qks_t, sel)
    qcm_a = select(qcm_a, sel)
    qcm_t = select(qcm_t, sel)
    nv = rows(qks_t)
    st_numscalar("r(boot_nvalid)", nv)
    if (nv < 10) {
        return
    }
    sa = sort(qks_a, 1)
    stv = sort(qks_t, 1)
    ca = sort(qcm_a, 1)
    ct = sort(qcm_t, 1)
    j1 = max((1, ceil(nv*0.99)))
    j5 = max((1, ceil(nv*0.95)))
    j10 = max((1, ceil(nv*0.90)))
    st_numscalar("r(boot_qks_a_1)", sa[j1])
    st_numscalar("r(boot_qks_a_5)", sa[j5])
    st_numscalar("r(boot_qks_a_10)", sa[j10])
    st_numscalar("r(boot_qks_t_1)", stv[j1])
    st_numscalar("r(boot_qks_t_5)", stv[j5])
    st_numscalar("r(boot_qks_t_10)", stv[j10])
    st_numscalar("r(boot_qcm_a_1)", ca[j1])
    st_numscalar("r(boot_qcm_a_5)", ca[j5])
    st_numscalar("r(boot_qcm_a_10)", ca[j10])
    st_numscalar("r(boot_qcm_t_1)", ct[j1])
    st_numscalar("r(boot_qcm_t_5)", ct[j5])
    st_numscalar("r(boot_qcm_t_10)", ct[j10])
}

end

*==============================================================================
* End of _qadf_mata.ado
*==============================================================================
