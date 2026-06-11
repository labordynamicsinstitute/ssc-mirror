*! lqqr.mata 1.0.0 16may2026
*! Mata library for the qqr package
*! Author: Merwan Roudane

version 14
mata:
mata set matastrict on
mata set matafavor speed

// ─────────────────────────────────────────────────────────────────────
// Empirical CDF: rank-based F_hat(x_i) in (0,1)
// ─────────────────────────────────────────────────────────────────────
real colvector lqqr_ecdf(real colvector x)
{
    real scalar n
    real colvector r
    n = rows(x)
    r = J(n,1,.)
    r[order(x,1)] = (1::n)
    return((r :- 0.5) :/ n)
}

// ─────────────────────────────────────────────────────────────────────
// Gaussian kernel
// ─────────────────────────────────────────────────────────────────────
real matrix lqqr_gauss(real matrix u)
{
    return(exp(-0.5 :* u :^ 2) :/ sqrt(2*pi()))
}

// Silverman rule-of-thumb bandwidth
real scalar lqqr_silverman(real colvector x)
{
    real scalar n, sd, iqr, sigma
    n   = rows(x)
    sd  = sqrt(variance(x))
    iqr = lqqr_iqr(x)
    sigma = min((sd, iqr/1.349))
    if (sigma<=0 | sigma==.) sigma = sd
    return(0.9 * sigma * n^(-1/5))
}

real scalar lqqr_iqr(real colvector x)
{
    real colvector s
    real scalar n, q1, q3
    s = sort(x,1)
    n = rows(s)
    q1 = s[max((1,floor(0.25*n)))]
    q3 = s[max((1,floor(0.75*n)))]
    return(q3 - q1)
}

// ─────────────────────────────────────────────────────────────────────
// IRLS weighted quantile regression  (Hunter & Lange 2000)
//   minimises  Σ w_i ρ_τ(y_i - x_i'β)
//   y : n×1   X : n×k (include constant)   w : n×1 (nonneg)   tau : (0,1)
//   returns β (k×1)
// ─────────────────────────────────────────────────────────────────────
real colvector lqqr_wqreg(real colvector y, real matrix X,
                          real colvector w, real scalar tau,
                          | real scalar maxit, real scalar tol)
{
    real colvector b, b_old, r, wi, sgn
    real matrix XtWX
    real scalar iter, eps, dlt

    if (args()<5) maxit = 200
    if (args()<6) tol   = 1e-7
    eps = 1e-6

    b = invsym(quadcross(X, w, X)) * quadcross(X, w, y)
    for (iter=1; iter<=maxit; iter++) {
        b_old = b
        r   = y :- X*b
        sgn = (r:>=0) :- (r:<0)
        wi  = w :/ (abs(r) :+ eps) :* (1 :+ (2*tau-1) :* sgn)
        XtWX = quadcross(X, wi, X)
        if (hasmissing(XtWX) | det(XtWX)==0) return(b_old)
        b   = invsym(XtWX) * quadcross(X, wi, y)
        dlt = max(abs(b :- b_old))
        if (dlt < tol) break
    }
    return(b)
}

// Check-function loss (for pseudo-R²)
real scalar lqqr_rholoss(real colvector r, real scalar tau, real colvector w)
{
    real colvector u
    u = tau :* r :- (r :< 0) :* r
    if (rows(w)==rows(r)) return(quadsum(w :* u))
    return(quadsum(u))
}

// Empirical quantile of a vector
real scalar lqqr_quant(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, idx
    s = sort(x,1)
    n = rows(s)
    h = (n-1)*p + 1
    idx = floor(h)
    if (idx<1) idx = 1
    if (idx>=n) return(s[n])
    return(s[idx] + (h-idx)*(s[idx+1]-s[idx]))
}

// ─────────────────────────────────────────────────────────────────────
// Bivariate QQR core (kernel method)
//   For each (tau, theta) pair, fit local linear weighted quantile
//   regression  y = b0 + b1*(x - x_theta)  with weights
//   K_h(F_hat(x_i) - theta)/h.
//   Returns long-format matrix:  [tau, theta, coef, se, tstat, pval, r2]
// ─────────────────────────────────────────────────────────────────────
real matrix lqqr_qqr_kernel(real colvector y, real colvector x,
                            real colvector tau,   // M×1 (response quantiles)
                            real colvector theta, // L×1 (predictor quantiles)
                            real scalar h_in,
                            real scalar boot_se,
                            real scalar n_boot)
{
    real scalar n, M, L, i, j, k, h, x_theta, b1, b0, se, tv, pv, r2, rho_m, rho_0, ymed
    real colvector Fx, w, xc, beta, r, idx, bsamp, vals
    real matrix X, OUT
    real scalar row

    n = rows(y)
    M = rows(tau)
    L = rows(theta)
    OUT = J(M*L, 7, .)
    Fx = lqqr_ecdf(x)
    h  = (h_in>0 ? h_in : lqqr_silverman(Fx))

    row = 0
    for (j=1; j<=L; j++) {
        x_theta = lqqr_quant(x, theta[j])
        w  = lqqr_gauss((Fx :- theta[j]) :/ h) :/ h
        xc = x :- x_theta
        X  = J(n,1,1), xc
        for (i=1; i<=M; i++) {
            row++
            beta = lqqr_wqreg(y, X, w, tau[i])
            b0 = beta[1]; b1 = beta[2]

            r     = y :- X*beta
            rho_m = lqqr_rholoss(r, tau[i], w)
            ymed  = lqqr_quant(y, tau[i])
            rho_0 = lqqr_rholoss(y :- ymed, tau[i], w)
            r2    = (rho_0>0 ? max((0, 1 - rho_m/rho_0)) : 0)

            // Standard error (bootstrap)
            if (boot_se & n_boot>0) {
                bsamp = J(n_boot,1,.)
                for (k=1; k<=n_boot; k++) {
                    idx = ceil(runiform(n,1) :* n)
                    bsamp[k] = lqqr_wqreg(y[idx], (J(n,1,1), x[idx]:-x_theta), w[idx], tau[i])[2]
                }
                vals = select(bsamp, bsamp:!=.)
                se = (rows(vals)>5 ? sqrt(variance(vals)) : .)
            }
            else {
                // sparsity-free approx SE via residual variance
                se = sqrt(tau[i]*(1-tau[i]) / quadsum(w) / variance(xc, w))
            }
            tv = (se>0 ? b1/se : .)
            pv = (se>0 ? 2*(1 - normal(abs(tv))) : .)

            OUT[row, 1] = tau[i]
            OUT[row, 2] = theta[j]
            OUT[row, 3] = b1
            OUT[row, 4] = se
            OUT[row, 5] = tv
            OUT[row, 6] = pv
            OUT[row, 7] = r2
        }
    }
    return(OUT)
}

// ─────────────────────────────────────────────────────────────────────
// Bivariate QQR — subset method (Sim-Zhou simplified)
// ─────────────────────────────────────────────────────────────────────
real matrix lqqr_qqr_subset(real colvector y, real colvector x,
                            real colvector tau, real colvector theta,
                            real scalar min_obs)
{
    real scalar n, M, L, i, j, x_thresh, n_sub, b0, b1, se, tv, pv, r2, rho_m, rho_0, ymed
    real colvector sel, ys, xs, beta, ws, r
    real matrix Xs, OUT
    real scalar row

    n = rows(y)
    M = rows(tau)
    L = rows(theta)
    OUT = J(M*L, 7, .)
    row = 0

    for (j=1; j<=L; j++) {
        x_thresh = lqqr_quant(x, theta[j])
        sel = (x :<= x_thresh)
        ys  = select(y, sel)
        xs  = select(x, sel)
        n_sub = rows(ys)

        for (i=1; i<=M; i++) {
            row++
            OUT[row, 1] = tau[i]
            OUT[row, 2] = theta[j]
            if (n_sub < min_obs) continue
            Xs = J(n_sub,1,1), xs
            ws = J(n_sub,1,1)
            beta = lqqr_wqreg(ys, Xs, ws, tau[i])
            b0 = beta[1]; b1 = beta[2]
            r     = ys :- Xs*beta
            rho_m = lqqr_rholoss(r, tau[i], ws)
            ymed  = lqqr_quant(ys, tau[i])
            rho_0 = lqqr_rholoss(ys :- ymed, tau[i], ws)
            r2    = (rho_0>0 ? max((0, 1 - rho_m/rho_0)) : 0)
            se    = sqrt(tau[i]*(1-tau[i]) / n_sub / variance(xs))
            tv    = b1/se
            pv    = 2*(1 - normal(abs(tv)))
            OUT[row, 3] = b1
            OUT[row, 4] = se
            OUT[row, 5] = tv
            OUT[row, 6] = pv
            OUT[row, 7] = r2
        }
    }
    return(OUT)
}

// ─────────────────────────────────────────────────────────────────────
// Multivariate QQR
//   y = b0 + Σ_p b_p (x_p - x_p,theta)  with kernel weights on the
//   pivot variable's empirical CDF.
//   pivot_col : index of which X-column drives the (tau,theta) grid.
//   Returns long-format:
//     [tau, theta, var_index, coef, se, tstat, pval]
// ─────────────────────────────────────────────────────────────────────
real matrix lqqr_mqqr(real colvector y, real matrix Xall,
                      real colvector tau, real colvector theta,
                      real scalar pivot_col, real scalar h_in)
{
    real scalar n, M, L, K, i, j, k, h, b1, se, tv, pv, x_theta
    real colvector Fx, w, beta, xp, sevec
    real matrix X, Xc, OUT, S
    real scalar row

    n = rows(y)
    K = cols(Xall)
    M = rows(tau)
    L = rows(theta)
    OUT = J(M*L*K, 7, .)

    xp = Xall[, pivot_col]
    Fx = lqqr_ecdf(xp)
    h  = (h_in>0 ? h_in : lqqr_silverman(Fx))

    row = 0
    for (j=1; j<=L; j++) {
        // Center each X column at its theta-quantile
        Xc = J(n, K, .)
        for (k=1; k<=K; k++) {
            x_theta = lqqr_quant(Xall[,k], theta[j])
            Xc[,k]  = Xall[,k] :- x_theta
        }
        X = J(n,1,1), Xc
        w = lqqr_gauss((Fx :- theta[j]) :/ h) :/ h

        for (i=1; i<=M; i++) {
            beta = lqqr_wqreg(y, X, w, tau[i])
            // Approximate SE from W = Σ w_i x_i x_i'
            S = invsym(quadcross(X, w, X)) * (tau[i]*(1-tau[i]))
            sevec = sqrt(diagonal(S))
            for (k=1; k<=K; k++) {
                row++
                b1 = beta[k+1]
                se = sevec[k+1]
                tv = (se>0 ? b1/se : .)
                pv = (se>0 ? 2*(1 - normal(abs(tv))) : .)
                OUT[row, 1] = tau[i]
                OUT[row, 2] = theta[j]
                OUT[row, 3] = k
                OUT[row, 4] = b1
                OUT[row, 5] = se
                OUT[row, 6] = tv
                OUT[row, 7] = pv
            }
        }
    }
    return(OUT)
}

// ─────────────────────────────────────────────────────────────────────
// Local-constant kernel conditional quantile  Q_tau(y | x)
//   Vectorised  ‒ used by causality test.
// ─────────────────────────────────────────────────────────────────────
real colvector lqqr_lcqr(real colvector x_eval, real colvector y,
                         real scalar h, real scalar tau)
{
    real scalar n, i, j, csum, hit, wsum
    real colvector fv, sortidx, ysort, w, wj

    n = rows(x_eval)
    if (n==0) return(J(0,1,.))
    fv      = J(n, 1, .)
    sortidx = order(y, 1)
    ysort   = y[sortidx]

    for (i=1; i<=n; i++) {
        // Gaussian kernel weights at evaluation point i  (column vector n×1)
        w    = exp(-0.5 :* ((x_eval :- x_eval[i]) :/ h):^2)
        wsum = colsum(w)
        if (wsum<=0) {
            fv[i] = ysort[n]
            continue
        }
        w  = w :/ wsum
        wj = w[sortidx]        // n×1 reordered by y-sort
        csum = 0
        hit  = n
        for (j=1; j<=n; j++) {
            csum = csum + wj[j]
            if (csum >= tau) {
                hit = j
                j   = n
            }
        }
        fv[i] = ysort[hit]
    }
    return(fv)
}

// ─────────────────────────────────────────────────────────────────────
// Nonparametric Quantile Causality (Balcilar et al.; Jeong-Härdle-Song)
//   x_lag1 → y_t  at quantile tau, moment ∈ {1, 2}
//   Returns matrix Q×3:  [tau, T_stat, pvalue]
// ─────────────────────────────────────────────────────────────────────
// Outer-difference matrix:  D[i,j] = v[i] - v[j]
// Mata in some Stata builds does NOT broadcast (T×1) :- (1×T), so we
// construct it explicitly via matrix multiplication.
real matrix lqqr_diffmat(real colvector v)
{
    real scalar n
    real rowvector ones_r
    real colvector ones_c
    n      = rows(v)
    ones_r = J(1, n, 1)
    ones_c = J(n, 1, 1)
    return(v * ones_r - ones_c * v')
}

real matrix lqqr_npcause(real colvector y, real colvector x,
                         real colvector q, real scalar moment,
                         real scalar h_in)
{
    real scalar n, T, j, h, hv, qj, qrh, qx, sd_y, sd_x, scale, numv, dens, statj, pv
    real colvector yt, ylag, xlag, ytm, fv, ifv
    real matrix Ky, Kx, K, OUT, NUM, Dyy, Dxx

    n = rows(y)
    if (n<5) return(J(0,3,.))

    yt   = y[2::n]
    ylag = y[1::n-1]
    xlag = x[1::n-1]
    T    = rows(yt)
    ytm  = yt :^ moment

    if (h_in>0) hv = h_in
    else        hv = lqqr_silverman(ytm)
    h = hv

    sd_y = sqrt(variance(ylag))
    sd_x = sqrt(variance(xlag))
    if (sd_x>0) scale = sd_y / sd_x
    else        scale = 1

    OUT  = J(rows(q), 3, .)

    for (j=1; j<=rows(q); j++) {
        qj  = q[j]
        qrh = h * (qj*(1-qj)/0.25)^0.2
        qx  = qrh * scale

        fv  = lqqr_lcqr(ylag, ytm, qrh, qj)
        ifv = (ytm :<= fv) :- qj

        Dyy = lqqr_diffmat(ylag) :/ qrh
        Dxx = lqqr_diffmat(xlag) :/ qx
        Ky  = lqqr_gauss(Dyy)
        Kx  = lqqr_gauss(Dxx)
        K   = Ky :* Kx

        NUM  = ifv' * K * ifv
        dens = quadsum(K :^ 2)
        if (dens>0 & rows(NUM)==1 & cols(NUM)==1) {
            numv  = NUM[1,1]
            statj = numv * sqrt(T / (2*qj*(1-qj)) / (T-1) / dens)
            pv    = 2*(1 - normal(abs(statj)))
        }
        else {
            statj = .
            pv    = .
        }
        OUT[j, 1] = qj
        OUT[j, 2] = statj
        OUT[j, 3] = pv
    }
    return(OUT)
}

// ─────────────────────────────────────────────────────────────────────
// Helper functions previously inline in ado files
// Moved here so ado autoload never hits Mata braces.
// ─────────────────────────────────────────────────────────────────────

// ── from qqr.ado ────────────────────────────────────────────────────

void lqqr_qqr_run(string scalar yvar, string scalar xvar, string scalar tvar,
              string scalar Tnm, string scalar Thnm,
              real scalar h, string scalar method,
              real scalar boot, real scalar nb,
              string scalar OUTnm)
{
    real colvector y, x, tau, theta
    real matrix OUT
    y     = st_data(., yvar, tvar)
    x     = st_data(., xvar, tvar)
    tau   = st_matrix(Tnm)
    theta = st_matrix(Thnm)
    if (method=="kernel") {
        OUT = lqqr_qqr_kernel(y, x, tau, theta, h, boot, nb)
    }
    else {
        OUT = lqqr_qqr_subset(y, x, tau, theta, 10)
    }
    st_matrix(OUTnm, OUT)
}

void lqqr_qqr_reshape(string scalar OUTnm, real scalar M, real scalar L,
                  string scalar Bnm, string scalar SEnm,
                  string scalar Tstm, string scalar Pnm, string scalar R2nm)
{
    real matrix OUT, B, SE, Tst, P, R2
    real scalar i, j, k
    OUT = st_matrix(OUTnm)
    B   = J(M, L, .)
    SE  = J(M, L, .)
    Tst = J(M, L, .)
    P   = J(M, L, .)
    R2  = J(M, L, .)
    k = 0
    for (j=1; j<=L; j++) {
        for (i=1; i<=M; i++) {
            k++
            B[i,j]   = OUT[k,3]
            SE[i,j]  = OUT[k,4]
            Tst[i,j] = OUT[k,5]
            P[i,j]   = OUT[k,6]
            R2[i,j]  = OUT[k,7]
        }
    }
    st_matrix(Bnm,   B)
    st_matrix(SEnm,  SE)
    st_matrix(Tstm,  Tst)
    st_matrix(Pnm,   P)
    st_matrix(R2nm,  R2)
}

void lqqr_summary_mat(string scalar OUTnm, string scalar Snm)
{
    real matrix OUT
    real colvector c, p
    real scalar n_total
    OUT = st_matrix(OUTnm)
    c = select(OUT[,3], OUT[,3]:!=.)
    p = select(OUT[,6], OUT[,6]:!=.)
    n_total = rows(c)
    st_matrix(Snm, (mean(c), lqqr_quant(c,0.5), min(c), max(c), sqrt(variance(c)),
                    sum(p:<0.10), sum(p:<0.05), sum(p:<0.01), n_total))
}

// ═════════════════════════════════════════════════════════════════════
// JOINT BOOTSTRAP + FORMAL TESTS / DIAGNOSTICS on beta(tau,theta)
// Cell order everywhere: k = (j-1)*M + i   (theta-major, tau-minor),
// matching lqqr_qqr_kernel / lqqr_qqr_reshape.
// ═════════════════════════════════════════════════════════════════════

// Re-estimate the WHOLE slope grid on a (possibly resampled) sample.
// method: 1 = kernel (Sim-Zhou), 2 = subset.  Returns (M*L) x 1 slopes.
real colvector lqqr_betagrid(real colvector y, real colvector x,
                             real colvector tau, real colvector theta,
                             real scalar h, real scalar method)
{
    real scalar    n, M, L, i, j, row, x_theta, x_thresh, n_sub
    real colvector Fx, w, xc, beta, out, sel, ys, xs, ws
    real matrix    X, Xs

    n = rows(y); M = rows(tau); L = rows(theta)
    out = J(M*L, 1, .)
    row = 0
    if (method==1) {
        Fx = lqqr_ecdf(x)
        for (j=1; j<=L; j++) {
            x_theta = lqqr_quant(x, theta[j])
            w  = lqqr_gauss((Fx :- theta[j]) :/ h) :/ h
            xc = x :- x_theta
            X  = J(n,1,1), xc
            for (i=1; i<=M; i++) {
                row++
                beta = lqqr_wqreg(y, X, w, tau[i])
                out[row] = beta[2]
            }
        }
    }
    else {
        for (j=1; j<=L; j++) {
            x_thresh = lqqr_quant(x, theta[j])
            sel = (x :<= x_thresh)
            ys  = select(y, sel); xs = select(x, sel); n_sub = rows(ys)
            for (i=1; i<=M; i++) {
                row++
                if (n_sub < 10) continue
                Xs = J(n_sub,1,1), xs
                ws = J(n_sub,1,1)
                beta = lqqr_wqreg(ys, Xs, ws, tau[i])
                out[row] = beta[2]
            }
        }
    }
    return(out)
}

// Joint bootstrap for the qqr command: one resample index reused across
// ALL cells per replication, so cross-cell covariance is preserved.
// Appends percentile CI columns (lo,hi) to OUT and stashes the full draw
// matrix + point estimates in Mata externals for lqqr_qqr_bootlong().
void lqqr_qqr_bootci(string scalar yvar, string scalar xvar,
                     string scalar tvar, string scalar Tnm, string scalar Thnm,
                     real scalar h_in, string scalar method,
                     real scalar nb, real scalar level, string scalar OUTnm)
{
    external real matrix    lqqr_BOOTDRAW
    external real colvector  lqqr_BOOTBHAT, lqqr_BOOTTAU, lqqr_BOOTTH
    real colvector y, x, tau, theta, bhat, idx, Fx, tcell, thcell, v
    real matrix    DRAW, OUT, CI
    real scalar    n, M, L, P, b, c, meth, h0, a, i, j, k

    y = st_data(., yvar, tvar); x = st_data(., xvar, tvar)
    tau = st_matrix(Tnm); theta = st_matrix(Thnm)
    n = rows(y); M = rows(tau); L = rows(theta); P = M*L
    meth = (method=="subset" ? 2 : 1)
    Fx = lqqr_ecdf(x); h0 = (h_in>0 ? h_in : lqqr_silverman(Fx))

    bhat = lqqr_betagrid(y, x, tau, theta, h0, meth)
    DRAW = J(nb, P, .)
    for (b=1; b<=nb; b++) {
        idx = ceil(runiform(n,1) :* n)
        DRAW[b,.] = lqqr_betagrid(y[idx], x[idx], tau, theta, h0, meth)'
    }

    a = (1 - level/100)/2
    CI = J(P, 2, .)
    for (c=1; c<=P; c++) {
        v = select(DRAW[,c], DRAW[,c]:!=.)
        if (rows(v)>5) {
            CI[c,1] = lqqr_quant(v, a)
            CI[c,2] = lqqr_quant(v, 1-a)
        }
    }
    OUT = st_matrix(OUTnm)
    st_matrix(OUTnm, (OUT, CI))

    tcell = J(P,1,.); thcell = J(P,1,.); k = 0
    for (j=1; j<=L; j++) {
        for (i=1; i<=M; i++) {
            k++
            tcell[k] = tau[i]
            thcell[k] = theta[j]
        }
    }
    lqqr_BOOTDRAW = DRAW; lqqr_BOOTBHAT = bhat
    lqqr_BOOTTAU  = tcell; lqqr_BOOTTH  = thcell
}

// Write the stashed draws to the (emptied) current dataset in long form:
// rep tau theta beta, with rep==0 = point estimate, rep 1..B = draws.
void lqqr_qqr_bootlong()
{
    external real matrix    lqqr_BOOTDRAW
    external real colvector  lqqr_BOOTBHAT, lqqr_BOOTTAU, lqqr_BOOTTH
    real scalar    B, P, Ntot, r, b, c
    real colvector rep, tt, th, be

    B = rows(lqqr_BOOTDRAW); P = cols(lqqr_BOOTDRAW)
    Ntot = (B+1)*P
    rep = J(Ntot,1,.); tt = J(Ntot,1,.); th = J(Ntot,1,.); be = J(Ntot,1,.)
    r = 0
    for (c=1; c<=P; c++) {
        r++; rep[r] = 0; tt[r] = lqqr_BOOTTAU[c]; th[r] = lqqr_BOOTTH[c]; be[r] = lqqr_BOOTBHAT[c]
    }
    for (b=1; b<=B; b++) {
        for (c=1; c<=P; c++) {
            r++; rep[r] = b; tt[r] = lqqr_BOOTTAU[c]; th[r] = lqqr_BOOTTH[c]; be[r] = lqqr_BOOTDRAW[b,c]
        }
    }
    (void) st_addobs(Ntot)
    (void) st_addvar("double", ("rep","tau","theta","beta"))
    st_store(., ("rep","tau","theta","beta"), (rep, tt, th, be))
}

// Reconstruct the joint draw matrix from a long draws dataset (the CURRENT
// data: vars rep tau theta beta) into Mata externals used by the consumers.
//   lqqr_RDRAW  (B x P)   lqqr_RBHAT (P x 1)   lqqr_RUTAU (M x 1)
//   lqqr_RUTH   (L x 1)   lqqr_RTCELL/lqqr_RTHCELL (P x 1)
void lqqr_boot_recon()
{
    external real matrix    lqqr_RDRAW
    external real colvector  lqqr_RBHAT, lqqr_RUTAU, lqqr_RUTH, lqqr_RTCELL, lqqr_RTHCELL
    real colvector rep, tau, theta, beta
    real scalar    M, L, P, B, it, jt, k, o, nobs

    rep = st_data(.,"rep"); tau = st_data(.,"tau")
    theta = st_data(.,"theta"); beta = st_data(.,"beta")
    lqqr_RUTAU = uniqrows(tau); lqqr_RUTH = uniqrows(theta)
    M = rows(lqqr_RUTAU); L = rows(lqqr_RUTH); P = M*L
    B = max(rep)
    lqqr_RDRAW = J(B, P, .); lqqr_RBHAT = J(P, 1, .)
    lqqr_RTCELL = J(P,1,.); lqqr_RTHCELL = J(P,1,.)
    k = 0
    for (jt=1; jt<=L; jt++) {
        for (it=1; it<=M; it++) {
            k++
            lqqr_RTCELL[k] = lqqr_RUTAU[it]
            lqqr_RTHCELL[k] = lqqr_RUTH[jt]
        }
    }
    nobs = rows(rep)
    for (o=1; o<=nobs; o++) {
        it = selectindex(lqqr_RUTAU :== tau[o])[1]
        jt = selectindex(lqqr_RUTH  :== theta[o])[1]
        k  = (jt-1)*M + it
        if (rep[o]==0) lqqr_RBHAT[k] = beta[o]
        else           lqqr_RDRAW[rep[o], k] = beta[o]
    }
}

// Formal tests on beta(tau,theta) using the joint bootstrap.
//   testcode: 1=zero (H0: all beta=0)
//             2=symmetry in tau about 0.5 (H0: beta(tau,theta)=beta(1-tau,theta))
//             3=constancy / equality of slopes across quantiles
//   dimcode (testcode 3 only): 1=across tau (within each theta), 2=across theta
// Returns RES = (q, KS, pKS, CvM, pCvM, Wald, pWald_chi2, pWald_boot).
void lqqr_qqtest_run(real scalar testcode, real scalar dimcode, string scalar RESnm)
{
    external real matrix    lqqr_RDRAW
    external real colvector  lqqr_RBHAT, lqqr_RUTAU, lqqr_RUTH
    real matrix    R, Dboot, Dc, Vd, invV, AB, ABs
    real rowvector mb
    real colvector dhat, sd, KSb, CvMb, Wb
    real scalar    P, M, L, B, q, i, j, r, mi, KS, CvM, Wald, pKS, pCvM, pWc, pWb

    M = rows(lqqr_RUTAU); L = rows(lqqr_RUTH); P = M*L; B = rows(lqqr_RDRAW)

    if (testcode==1) {
        R = I(P); q = P
    }
    else if (testcode==2) {
        q = floor(M/2)*L
        R = J(q, P, 0); r = 0
        for (j=1; j<=L; j++) {
            for (i=1; i<=floor(M/2); i++) {
                mi = M+1-i; r++
                R[r,(j-1)*M+i] = 1; R[r,(j-1)*M+mi] = -1
            }
        }
    }
    else {
        if (dimcode==2) {
            q = M*(L-1); R = J(q, P, 0); r = 0
            for (i=1; i<=M; i++) {
                for (j=2; j<=L; j++) {
                r++
                R[r,(j-1)*M+i] = 1
                R[r,i] = -1
            }
            }
        }
        else {
            q = (M-1)*L; R = J(q, P, 0); r = 0
            for (j=1; j<=L; j++) {
                for (i=2; i<=M; i++) {
                r++
                R[r,(j-1)*M+i] = 1
                R[r,(j-1)*M+1] = -1
            }
            }
        }
    }

    dhat  = R*lqqr_RBHAT
    Dboot = lqqr_RDRAW*R'
    mb    = mean(Dboot)
    Vd    = quadcross(Dboot:-mb, Dboot:-mb) / (B-1)
    sd    = sqrt(diagonal(Vd))
    for (i=1; i<=rows(sd); i++) if (sd[i]<=0 | sd[i]==.) sd[i] = 1e-12

    Dc  = Dboot :- J(B,1,1)*dhat'
    AB  = abs(Dc) :/ (J(B,1,1)*sd')
    KSb = rowmax(AB)
    KS  = max(abs(dhat):/sd)
    pKS = mean(KSb :>= KS)

    ABs  = (Dc :/ (J(B,1,1)*sd')) :^ 2
    CvMb = rowsum(ABs)
    CvM  = sum((dhat:/sd):^2)
    pCvM = mean(CvMb :>= CvM)

    invV = invsym(Vd)
    Wald = (dhat' * invV * dhat)[1,1]
    pWc  = chi2tail(rows(dhat), Wald)
    Wb = J(B,1,.)
    for (i=1; i<=B; i++) Wb[i] = (Dc[i,] * invV * Dc[i,]')[1,1]
    pWb = mean(Wb :>= Wald)

    st_matrix(RESnm, (rows(dhat), KS, pKS, CvM, pCvM, Wald, pWc, pWb))
}

// Per-quantile CI ribbon slice. fixdim: 1 = fix theta (vary tau), 2 = fix
// tau (vary theta). Returns OUT = (xval, bhat, lo, hi, jlo, jhi) for the
// slice nearest fixval (pointwise + sup/joint bootstrap band).
void lqqr_ribbon_data(real scalar fixdim, real scalar fixval,
                      real scalar level, string scalar OUTnm)
{
    external real matrix    lqqr_RDRAW
    external real colvector  lqqr_RBHAT, lqqr_RUTAU, lqqr_RUTH, lqqr_RTCELL, lqqr_RTHCELL
    real colvector idxc, xval, bh, lo, hi, sd, v, dvec, gband, fixgrid
    real matrix    Dsl, ABj
    real scalar    M, L, P, B, ns, c, a, fv, dpos, jq, s

    M = rows(lqqr_RUTAU); L = rows(lqqr_RUTH); P = M*L; B = rows(lqqr_RDRAW)
    a = (1 - level/100)/2

    // nearest grid value on the fixed dimension
    fixgrid = (fixdim==1 ? lqqr_RUTH : lqqr_RUTAU)
    dpos = 1
    for (c=1; c<=rows(fixgrid); c++) if (abs(fixgrid[c]-fixval) < abs(fixgrid[dpos]-fixval)) dpos = c
    fv = fixgrid[dpos]

    // cells of the slice + the varying-axis value
    idxc = J(0,1,.); xval = J(0,1,.)
    for (c=1; c<=P; c++) {
        if (fixdim==1) {
            if (lqqr_RTHCELL[c]==fv) {
                idxc = idxc \ c
                xval = xval \ lqqr_RTCELL[c]
            }
        }
        else {
            if (lqqr_RTCELL[c]==fv) {
                idxc = idxc \ c
                xval = xval \ lqqr_RTHCELL[c]
            }
        }
    }
    ns = rows(idxc)
    bh = lqqr_RBHAT[idxc]
    Dsl = lqqr_RDRAW[, idxc']            // B x ns
    lo = J(ns,1,.); hi = J(ns,1,.); sd = J(ns,1,.)
    for (s=1; s<=ns; s++) {
        v = select(Dsl[,s], Dsl[,s]:!=.)
        if (rows(v)>5) {
            lo[s] = lqqr_quant(v,a)
            hi[s] = lqqr_quant(v,1-a)
            sd[s] = sqrt(variance(v))
        }
        else {
            lo[s] = bh[s]
            hi[s] = bh[s]
            sd[s] = 1e-12
        }
    }
    for (s=1; s<=ns; s++) if (sd[s]<=0 | sd[s]==.) sd[s] = 1e-12

    // joint (sup-t) band: critical value over the slice
    ABj = abs(Dsl :- J(B,1,1)*bh') :/ (J(B,1,1)*sd')
    gband = rowmax(ABj)
    gband = select(gband, gband:!=.)
    jq = lqqr_quant(gband, level/100)

    st_matrix(OUTnm, (xval, bh, lo, hi, bh:-jq*sd, bh:+jq*sd))
}

// Asymmetry surface: diff(tau,theta) = beta(tau,theta) - beta(1-tau,theta),
// with a two-sided bootstrap p per cell. Returns OUT = (tau, theta, diff, p).
void lqqr_qqdiff_asym(string scalar OUTnm)
{
    external real matrix    lqqr_RDRAW
    external real colvector  lqqr_RBHAT, lqqr_RUTAU, lqqr_RUTH, lqqr_RTCELL, lqqr_RTHCELL
    real matrix    OUT
    real colvector dvec
    real scalar    M, L, P, B, i, j, k, mi, km, diff, pv, pl, pu

    M = rows(lqqr_RUTAU); L = rows(lqqr_RUTH); P = M*L; B = rows(lqqr_RDRAW)
    OUT = J(P, 4, .)
    for (j=1; j<=L; j++) {
        for (i=1; i<=M; i++) {
            k  = (j-1)*M + i
            mi = M+1-i
            km = (j-1)*M + mi
            diff = lqqr_RBHAT[k] - lqqr_RBHAT[km]
            dvec = lqqr_RDRAW[,k] - lqqr_RDRAW[,km]
            dvec = select(dvec, dvec:!=.)
            if (rows(dvec)>5) {
                pl = mean(dvec :<= 0); pu = mean(dvec :>= 0)
                pv = 2*min((pl, pu)); if (pv>1) pv = 1
            }
            else pv = .
            OUT[k,1] = lqqr_RTCELL[k]; OUT[k,2] = lqqr_RTHCELL[k]
            OUT[k,3] = diff;           OUT[k,4] = pv
        }
    }
    st_matrix(OUTnm, OUT)
}

// Per-cell summary for difference-of-surfaces across two files:
// OUT = (tau, theta, bhat, sd) for every cell of the CURRENT draws data.
void lqqr_cellsummary(string scalar OUTnm)
{
    external real matrix    lqqr_RDRAW
    external real colvector  lqqr_RBHAT, lqqr_RTCELL, lqqr_RTHCELL
    real matrix    OUT
    real colvector v
    real scalar    P, c

    P = rows(lqqr_RBHAT)
    OUT = J(P, 4, .)
    for (c=1; c<=P; c++) {
        v = select(lqqr_RDRAW[,c], lqqr_RDRAW[,c]:!=.)
        OUT[c,1] = lqqr_RTCELL[c]; OUT[c,2] = lqqr_RTHCELL[c]
        OUT[c,3] = lqqr_RBHAT[c]
        OUT[c,4] = (rows(v)>5 ? sqrt(variance(v)) : .)
    }
    st_matrix(OUTnm, OUT)
}

// Combine two per-cell summaries (each tau,theta,bhat,sd) into a difference
// surface: OUT = (tau, theta, diff=b1-b2, p) with p from a normal-approx z
// using independent-sample SEs.  Cells are matched on (tau,theta).
void lqqr_qqdiff_combine(string scalar Anm, string scalar Bnm, string scalar OUTnm)
{
    real matrix    A, Bm, OUT
    real scalar    P, c, d, r, diff, se, z

    A = st_matrix(Anm); Bm = st_matrix(Bnm)
    P = rows(A)
    OUT = J(P, 4, .)
    for (c=1; c<=P; c++) {
        // find matching cell in Bm (same tau & theta)
        d = 0
        for (r=1; r<=P; r++) {
            if (Bm[r,1]==A[c,1] & Bm[r,2]==A[c,2]) {
                d = r
                break
            }
        }
        OUT[c,1] = A[c,1]; OUT[c,2] = A[c,2]
        if (d==0) continue
        diff = A[c,3] - Bm[d,3]
        se   = sqrt(A[c,4]^2 + Bm[d,4]^2)
        OUT[c,3] = diff
        if (se>0 & se<.) {
            z = diff/se
            OUT[c,4] = 2*normal(-abs(z))
        }
    }
    st_matrix(OUTnm, OUT)
}

// Print a coefficient matrix with significance stars
void lqqr_print_matrix(string scalar Bnm, string scalar Pnm,
                       real colvector tau, real colvector theta)
{
    real matrix B, P
    real scalar M, L, i, j, b, pv

    B = st_matrix(Bnm)
    P = st_matrix(Pnm)
    M = rows(B)
    L = cols(B)
    if (M==0 | L==0 | rows(tau)==0 | rows(theta)==0) {
        printf("  (no data to print)\n")
        return
    }

    printf("  tau/theta")
    for (j=1; j<=L; j++) printf("    %5.2f", theta[j])
    printf("\n")
    printf("  ---------")
    for (j=1; j<=L; j++) printf("---------")
    printf("\n")

    for (i=1; i<=M; i++) {
        printf("    %5.2f ", tau[i])
        for (j=1; j<=L; j++) {
            b  = B[i,j]
            pv = P[i,j]
            if (b == .) {
                printf("    .    ")
                continue
            }
            if      (pv != . & pv < 0.01) printf(" %7.3f***", b)
            else if (pv != . & pv < 0.05) printf(" %7.3f** ", b)
            else if (pv != . & pv < 0.10) printf(" %7.3f*  ", b)
            else                          printf(" %7.3f   ", b)
        }
        printf("\n")
    }
}

// ── from mqqr.ado ───────────────────────────────────────────────────

void lqqr_mqqr_run(string scalar yvar, string scalar Xvars, string scalar tvar,
               string scalar Tnm, string scalar Thnm,
               real scalar pivot, real scalar h,
               string scalar OUTnm)
{
    real colvector y, tau, theta
    real matrix X, OUT
    y     = st_data(., yvar, tvar)
    X     = st_data(., tokens(Xvars), tvar)
    tau   = st_matrix(Tnm)
    theta = st_matrix(Thnm)
    OUT = lqqr_mqqr(y, X, tau, theta, pivot, h)
    st_matrix(OUTnm, OUT)
}

void lqqr_mqqr_var_summary(string scalar OUTnm, real scalar k, string scalar vname)
{
    real matrix OUT
    real colvector c, p, mask
    real scalar nsig, n, mb
    OUT = st_matrix(OUTnm)
    if (rows(OUT)==0 | cols(OUT) < 7) return
    mask = (OUT[,3] :== k)
    c = select(OUT[,4], mask)
    c = select(c, c :!= .)
    p = select(OUT[,7], mask)
    p = select(p, p :!= .)
    n = rows(c)
    if (n==0) {
        printf("  %-12s  (no valid cells)\n", vname)
        return
    }
    nsig = (rows(p)>0 ? sum(p :< 0.05) : 0)
    mb   = mean(c)
    printf("  %-12s  mean_beta = %9.4f   sig(5%%) = %3.0f / %3.0f\n",
            vname, mb, nsig, n)
}

// ── from qqgcause.ado ───────────────────────────────────────────────

void lqqr_qqgcause_run(string scalar yvar, string scalar xvar, string scalar tvar,
                   string scalar Tnm, real scalar moment, real scalar h,
                   string scalar OUTnm)
{
    real colvector y, x, q
    real matrix OUT
    y = st_data(., yvar, tvar)
    x = st_data(., xvar, tvar)
    q = st_matrix(Tnm)
    OUT = lqqr_npcause(y, x, q, moment, h)
    st_matrix(OUTnm, OUT)
}

void lqqr_qqgcause_print(string scalar OUTnm)
{
    real matrix OUT
    real scalar i
    string scalar sg
    OUT = st_matrix(OUTnm)
    for (i=1; i<=rows(OUT); i++) {
        sg = ""
        if (abs(OUT[i,2]) > 2.58) sg = "***"
        else if (abs(OUT[i,2]) > 1.96) sg = "**"
        else if (abs(OUT[i,2]) > 1.645) sg = "*"
        printf("  %5.2f    %8.3f    %6.4f   %s\n",
                OUT[i,1], OUT[i,2], OUT[i,3], sg)
    }
}

// ── from qqkrls.ado ─────────────────────────────────────────────────

void lqqr_qqkrls_step(string scalar dvar, real matrix TAU, real scalar nboot,
                  string scalar Dnm)
{
    real colvector d, idx, boot_betas
    real scalar n_sub, M, i, b, beta_i, se_i, pv
    real matrix D

    d = st_data(., dvar)
    d = select(d, d:!=.)
    n_sub = rows(d)

    M = rows(TAU)
    D = J(M, 4, .)
    for (i=1; i<=M; i++) {
        D[i,1] = TAU[i]
        if (n_sub < 5) continue
        beta_i = lqqr_quant(d, TAU[i])
        boot_betas = J(nboot, 1, .)
        for (b=1; b<=nboot; b++) {
            idx = ceil(runiform(n_sub,1) :* n_sub)
            boot_betas[b] = lqqr_quant(d[idx], TAU[i])
        }
        se_i = sqrt(variance(boot_betas))
        pv = (se_i>0 ? 2*(1 - normal(abs(beta_i/se_i))) : .)
        D[i,2] = beta_i
        D[i,3] = se_i
        D[i,4] = pv
    }
    st_matrix(Dnm, D)
}

void lqqr_qqkrls_summarize(string scalar OUTnm)
{
    real matrix OUT
    real colvector c, p
    real scalar nv, n5, n1, nt, sdv
    OUT = st_matrix(OUTnm)
    if (rows(OUT)==0 | cols(OUT) < 6) {
        printf("  (no results matrix)\n")
        return
    }
    c = select(OUT[,3], OUT[,3]:!=.)
    p = select(OUT[,6], OUT[,6]:!=.)
    nv = rows(c)
    if (nv==0) {
        printf("  no valid cells\n")
        return
    }
    nt = rows(p)
    n5 = (nt>0 ? sum(p:<0.05) : 0)
    n1 = (nt>0 ? sum(p:<0.01) : 0)
    sdv = (nv>=2 ? sqrt(variance(c)) : 0)
    printf("\n  {bf:Coefficient statistics}\n")
    printf("    mean   = %9.4f\n", mean(c))
    printf("    median = %9.4f\n", lqqr_quant(c, 0.5))
    printf("    min    = %9.4f\n", min(c))
    printf("    max    = %9.4f\n", max(c))
    printf("    sd     = %9.4f\n", sdv)
    printf("\n  {bf:Significance}\n")
    printf("    p<0.05 : %4.0f / %4.0f\n", n5, nt)
    printf("    p<0.01 : %4.0f / %4.0f\n", n1, nt)
    printf("{hline 62}\n")
}

// ── from qqtable.ado ────────────────────────────────────────────────

void lqqr_qqtable_print(string scalar valvar, real scalar digits, real scalar want_stars)
{
    real colvector tau, theta, val, pv, taus, thetas
    real scalar M, L, i, j, k, b, p, nrows
    string scalar star, line

    tau   = st_data(., "tau")
    theta = st_data(., "theta")
    val   = st_data(., valvar)
    if (want_stars) pv = st_data(., "p")
    else            pv = J(rows(val), 1, .)

    taus   = uniqrows(tau)
    thetas = uniqrows(theta)
    M = rows(taus)
    L = rows(thetas)
    nrows = rows(tau)

    line = "  ---------"
    for (j=1; j<=L; j++) line = line + "----------"
    printf("\n")
    printf("  tau/theta")
    for (j=1; j<=L; j++) printf("    %6.2f", thetas[j])
    printf("\n%s\n", line)

    for (i=1; i<=M; i++) {
        printf("    %5.2f ", taus[i])
        for (j=1; j<=L; j++) {
            b = .
            p = .
            for (k=1; k<=nrows; k++) {
                if (tau[k]==taus[i] & theta[k]==thetas[j]) {
                    b = val[k]
                    p = pv[k]
                    k = nrows
                }
            }
            star = "   "
            if (want_stars & p != .) {
                if      (p < 0.01) star = "***"
                else if (p < 0.05) star = "** "
                else if (p < 0.10) star = "*  "
            }
            if (b == .) printf("    .     ")
            else        printf(" %7.3f%s", b, star)
        }
        printf("\n")
    }
    printf("%s\n", line)
    if (want_stars) {
        printf("  significance: * p<0.10  ** p<0.05  *** p<0.01\n")
    }
}

// ── from _qqcolors.ado ──────────────────────────────────────────────

void lqqr_qqcolors_gen(string scalar map, real scalar n,
                   real scalar zmin, real scalar zmax,
                   string scalar Cnm, string scalar CutNm)
{
    real matrix anchors, C
    real colvector t, cuts
    real scalar i, k, j, m, pos, frac

    // Define key anchor colors (R, G, B in [0,255])
    if (map=="jet") {
        anchors = (
            0,   0,   143 \
            0,   0,   255 \
            0,   127, 255 \
            0,   255, 255 \
            127, 255, 127 \
            255, 255, 0   \
            255, 127, 0   \
            255, 0,   0   \
            127, 0,   0
        )
    }
    else if (map=="parula") {
        anchors = (
            53,  42,  135 \
            15,  92,  221 \
            18,  125, 216 \
            7,   156, 207 \
            21,  177, 180 \
            89,  189, 140 \
            165, 190, 107 \
            225, 185, 82  \
            252, 206, 46  \
            249, 251, 14
        )
    }
    else if (map=="viridis") {
        anchors = (
            68,  1,   84  \
            72,  40,  120 \
            62,  73,  137 \
            49,  104, 142 \
            38,  130, 142 \
            31,  158, 137 \
            53,  183, 121 \
            109, 205, 89  \
            180, 222, 44  \
            253, 231, 37
        )
    }
    else if (map=="plasma") {
        anchors = (
            13,  8,   135 \
            75,  3,   161 \
            125, 3,   168 \
            168, 34,  150 \
            203, 70,  121 \
            229, 107, 93  \
            248, 148, 65  \
            253, 195, 40  \
            240, 249, 33
        )
    }
    else if (map=="hot") {
        anchors = (
            10,  0,   0   \
            128, 0,   0   \
            255, 0,   0   \
            255, 128, 0   \
            255, 255, 0   \
            255, 255, 200 \
            255, 255, 255
        )
    }
    else if (map=="cool") {
        anchors = (
            0,   255, 255 \
            127, 127, 255 \
            255, 0,   255
        )
    }
    else if (map=="redblue" | map=="rwb") {
        anchors = (
            5,   48,  97  \
            33,  102, 172 \
            67,  147, 195 \
            146, 197, 222 \
            209, 229, 240 \
            247, 247, 247 \
            253, 219, 199 \
            244, 165, 130 \
            214, 96,  77  \
            178, 24,  43  \
            103, 0,   31
        )
    }
    else if (map=="redgreen" | map=="rdgrn" | map=="rdylgn") {
        // ColorBrewer RdYlGn: red (most negative) -> yellow -> green (most
        // positive). Matches Adebayo, Ozkan & Eweade (2024) QQ-KRLS figures
        // where green=positive and red=negative average marginal effects.
        anchors = (
            165, 0,   38  \
            215, 48,  39  \
            244, 109, 67  \
            253, 174, 97  \
            254, 224, 139 \
            255, 255, 191 \
            217, 239, 139 \
            166, 217, 106 \
            102, 189, 99  \
            26,  152, 80  \
            0,   104, 55
        )
    }
    else if (map=="redwhitegreen" | map=="rwg" | map=="rdwhgn") {
        // Diverging red -> white -> green, WHITE centred at zero. Cleaner than
        // RdYlGn (no yellow midpoint); matches the QQ-KRLS heatmap (Fig. 3 of
        // Adebayo, Ozkan & Eweade 2024): red = negative, white ~ 0, green = +.
        anchors = (
            103, 0,   31  \
            178, 24,  43  \
            214, 96,  77  \
            244, 165, 130 \
            253, 219, 199 \
            247, 247, 247 \
            217, 240, 211 \
            173, 221, 142 \
            120, 198, 121 \
            49,  163, 84  \
            0,   104, 55
        )
    }

    k = rows(anchors)
    // Interpolate to n colors
    C = J(n, 3, .)
    for (i=1; i<=n; i++) {
        t = J(1,1,(i-1)/(n-1))
        pos = t[1] * (k-1) + 1
        m = floor(pos)
        if (m < 1)   m = 1
        if (m >= k)  m = k-1
        frac = pos - m
        for (j=1; j<=3; j++) {
            C[i,j] = anchors[m,j] + frac*(anchors[m+1,j] - anchors[m,j])
            if (C[i,j] < 0)   C[i,j] = 0
            if (C[i,j] > 255) C[i,j] = 255
        }
    }

    st_matrix(Cnm, C)

    // twoway contour: N colors require N-1 INTERIOR cuts.
    if (n >= 2) {
        cuts = rangen(zmin, zmax, n+1)        // n+1 evenly spaced including endpoints
        cuts = cuts[2::n]                     // drop endpoints -> n-1 interior cuts
    }
    else {
        cuts = (zmin + zmax) / 2
    }
    st_matrix(CutNm, cuts')
}

end
