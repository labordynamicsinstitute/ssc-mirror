*! _xtquantilebreak_engine.ado — Mata engine for xtquantilebreak
*! Shrinkage Quantile Regression for Panel Data with Multiple Structural Breaks
*! Implements: Zhang, Zhu, Feng & He (2022, Canadian Journal of Statistics 50:820-851)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Version 1.0.0

version 14.0

capture mata: mata drop _xtqb_run()
capture mata: mata drop _xtqb_qrmm()
capture mata: mata drop _xtqb_solvek()
capture mata: mata drop _xtqb_alpha()
capture mata: mata drop _xtqb_obj()
capture mata: mata drop _xtqb_postlasso()
capture mata: mata drop _xtqb_se_regime()
capture mata: mata drop _xtqb_breaks()
capture mata: mata drop _xtqb_maxabs()

mata:

// ====================================================================
//  maximum absolute element of a matrix
// ====================================================================
real scalar _xtqb_maxabs(real matrix M)
{
    return(colmax(rowmax(abs(M))')[1,1])
}

// ====================================================================
//  Unpenalized weighted-MM quantile regression (Hunter & Lange 2000)
// ====================================================================
real colvector _xtqb_qrmm(real matrix X, real colvector y, real scalar tau)
{
    real scalar n, k, it, eps
    real colvector b, bb, r, w, z
    real matrix A

    n = rows(X); k = cols(X); eps = 1e-6
    A = quadcross(X, X)
    b = lusolve(A, quadcross(X, y))
    if (hasmissing(b)) b = J(k, 1, 0)

    for (it = 1; it <= 200; it++) {
        r = y - X * b
        w = 1 :/ (abs(r) :+ eps)
        z = y :+ (2*tau - 1) :/ w
        A = quadcross(X, w, X)
        bb = lusolve(A, quadcross(X, w, z))
        if (hasmissing(bb)) return(b)
        if (mreldif(bb, b) < 1e-7) return(bb)
        b = bb
    }
    return(b)
}

// ====================================================================
//  Penalized fused-L1 QR for one quantile (theta reparameterization)
//  min (1/NT) sum rho_tau(ytil - X*beta_t) + (lam2/T) sum w_t ||theta_t||_1
//  beta_t = sum_{j<=t} theta_j.  Returns beta and theta (T x pp).
// ====================================================================
void _xtqb_solvek(real matrix Yt, pointer matrix Xc,
                  real scalar N, real scalar T, real scalar pp,
                  real colvector omega, real scalar lam2, real scalar tau,
                  real matrix beta, real matrix theta)
{
    real scalar it, t, j, jp, d, eps, dtol, BIG, idx, ad, l1n
    real matrix theta0, A, Xt, thnew, bnew
    real colvector r, w, z, ctil, sol, ridge, Mc, Cc
    pointer matrix St, Vt, Mt, Ct

    eps = 1e-6; dtol = 1e-5; BIG = 1e12
    theta = J(T, pp, 0)
    beta  = J(T, pp, 0)

    for (it = 1; it <= 60; it++) {
        St = J(T, 1, NULL); Vt = J(T, 1, NULL)
        for (t = 1; t <= T; t++) {
            Xt = *Xc[t]
            r  = Yt[., t] - Xt * beta[t, .]'
            w  = 1 :/ (abs(r) :+ eps)
            z  = Yt[., t] :+ (2*tau - 1) :* (abs(r) :+ eps)
            St[t] = &(quadcross(Xt, w, Xt))
            Vt[t] = &(quadcross(Xt, w, z))
        }
        // cumulative-from-top: M_t = sum_{s>=t} S_s ; C_t = sum_{s>=t} V_s
        Mt = J(T, 1, NULL); Ct = J(T, 1, NULL)
        Mc = J(pp, pp, 0); Cc = J(pp, 1, 0)
        for (t = T; t >= 1; t--) {
            Mc = Mc + *St[t]
            Cc = Cc + *Vt[t]
            Mt[t] = &(Mc + J(pp, pp, 0))
            Ct[t] = &(Cc + J(pp, 1, 0))
        }
        // assemble normal-equation system (T*pp square)
        A = J(T*pp, T*pp, 0)
        ctil = J(T*pp, 1, 0)
        for (j = 1; j <= T; j++) {
            ctil[((j-1)*pp+1)..(j*pp)] = *Ct[j]
            for (jp = j; jp <= T; jp++) {
                A[((j-1)*pp+1)..(j*pp), ((jp-1)*pp+1)..(jp*pp)] = *Mt[jp]
                if (jp > j)
                    A[((jp-1)*pp+1)..(jp*pp), ((j-1)*pp+1)..(j*pp)] = (*Mt[jp])'
            }
        }
        // ridge from fused-L1 LQA on theta_t (t>=2).
        // iteration 1 = unpenalized saturated warm start (ridge 0) so that
        // genuine breaks appear; LQA shrinkage kicks in from iteration 2.
        ridge = J(T*pp, 1, 0)
        if (it > 1) {
            for (t = 2; t <= T; t++) {
                l1n = sum(abs(theta[t, .]))
                for (d = 1; d <= pp; d++) {
                    idx = (t-1)*pp + d
                    ad = abs(theta[t, d])
                    if (l1n < dtol) ridge[idx] = BIG
                    else ridge[idx] = lam2 * N * omega[t] / (ad + eps)
                }
            }
        }
        for (j = 1; j <= T*pp; j++) A[j, j] = A[j, j] + ridge[j]

        sol = cholsolve(A, ctil)
        if (hasmissing(sol)) sol = lusolve(A, ctil)
        if (hasmissing(sol)) break

        thnew = J(T, pp, 0)
        for (t = 1; t <= T; t++)
            for (d = 1; d <= pp; d++) thnew[t, d] = sol[(t-1)*pp + d]
        for (t = 2; t <= T; t++)
            if (sum(abs(thnew[t, .])) < dtol) thnew[t, .] = J(1, pp, 0)

        bnew = J(T, pp, 0)
        bnew[1, .] = thnew[1, .]
        for (t = 2; t <= T; t++) bnew[t, .] = bnew[t-1, .] + thnew[t, .]

        theta0 = theta
        theta = thnew
        beta  = bnew
        if (it > 2 & mreldif(thnew, theta0) < 1e-6) break
    }
}

// ====================================================================
//  Penalized weighted-median update of individual effects alpha
// ====================================================================
real colvector _xtqb_alpha(real matrix Y, pointer matrix Xc, pointer matrix Beta,
                           real scalar N, real scalar T, real scalar pp,
                           real scalar K, real rowvector tau, real scalar lam1)
{
    real colvector alpha, evals, cands, fvals
    real scalar i, t, k, c, ncand, best, jc, pen, a, f, e, rr
    real matrix Bk, Xt

    alpha = J(N, 1, 0)
    pen = lam1 * K * T
    for (i = 1; i <= N; i++) {
        evals = J(K*T, 1, 0); c = 0
        for (k = 1; k <= K; k++) {
            Bk = *Beta[k]
            for (t = 1; t <= T; t++) {
                Xt = *Xc[t]
                c++
                evals[c] = Y[i, t] - (Xt[i, .] * Bk[t, .]')
            }
        }
        cands = evals \ 0
        ncand = rows(cands)
        fvals = J(ncand, 1, 0)
        for (jc = 1; jc <= ncand; jc++) {
            a = cands[jc]
            f = pen * abs(a)
            for (c = 1; c <= K*T; c++) {
                rr = evals[c] - a
                f = f + rr * (tau[ceil(c/T)] - (rr < 0))
            }
            fvals[jc] = f
        }
        best = 1
        for (jc = 2; jc <= ncand; jc++) if (fvals[jc] < fvals[best]) best = jc
        alpha[i] = cands[best]
    }
    return(alpha)
}

// ====================================================================
//  Break detection for one quantile: theta -> regime start periods
// ====================================================================
real colvector _xtqb_breaks(real matrix theta, real scalar T, real scalar tol)
{
    real colvector starts
    real scalar t
    starts = 1
    for (t = 2; t <= T; t++)
        if (sum(abs(theta[t, .])) > tol) starts = starts \ t
    return(starts)
}

// ====================================================================
//  Powell kernel sandwich SE for QR coefficients on a regime sub-sample
// ====================================================================
real colvector _xtqb_se_regime(real matrix Xr, real colvector yr,
                               real colvector b, real scalar tau)
{
    real scalar n, pp, h, su
    real colvector u, fhat, se
    real matrix D, Jm, iD, V

    n = rows(Xr); pp = cols(Xr)
    u = yr - Xr * b
    su = sqrt(variance(u))
    if (su <= 0 | su == .) su = 1
    h = 1.06 * su * n^(-0.2)
    if (h <= 0) h = 1e-3
    fhat = normalden(u :/ h) :/ h
    D = quadcross(Xr, fhat, Xr)
    Jm = quadcross(Xr, Xr)
    iD = invsym(D)
    if (hasmissing(iD)) iD = pinv(D)
    V = tau * (1 - tau) * iD * Jm * iD
    se = sqrt(diagonal(V))
    return(se)
}

// ====================================================================
//  POST-LASSO refit + SEs + sigma^2
// ====================================================================
void _xtqb_postlasso(real matrix Y, pointer matrix Xc, pointer matrix Theta,
                     real scalar N, real scalar T, real scalar pp, real scalar K,
                     real rowvector tau, real scalar lam1, real scalar thrtol,
                     real colvector alphaIn,
                     real matrix regInfo, real matrix regCoef, real matrix regSE,
                     real matrix betaPath, real matrix brkMat, real colvector aPL,
                     real scalar sig2)
{
    real scalar k, t, i, r, nseg, s, e, it, d, totrows, row, nobs, rr, val, rrr
    pointer matrix Starts, Beta
    real colvector alph, st, anew, ypool, bcoef
    real matrix Bk, Xt, Xpool

    Starts = J(K, 1, NULL)
    brkMat = J(K, T, 0)
    totrows = 0
    for (k = 1; k <= K; k++) {
        st = _xtqb_breaks(*Theta[k], T, thrtol)
        Starts[k] = &(st :+ 0)
        totrows = totrows + rows(st)
        for (r = 2; r <= rows(st); r++) brkMat[k, st[r]] = 1
    }

    alph = alphaIn
    Beta = J(K, 1, NULL)
    for (k = 1; k <= K; k++) Beta[k] = &(J(T, pp, 0))

    for (it = 1; it <= 12; it++) {
        for (k = 1; k <= K; k++) {
            st = *Starts[k]
            nseg = rows(st)
            Bk = J(T, pp, 0)
            for (r = 1; r <= nseg; r++) {
                s = st[r]
                if (r < nseg) e = st[r+1] - 1
                else e = T
                nobs = N * (e - s + 1)
                Xpool = J(nobs, pp, 0); ypool = J(nobs, 1, 0); rr = 0
                for (t = s; t <= e; t++) {
                    Xt = *Xc[t]
                    for (i = 1; i <= N; i++) {
                        rr++
                        Xpool[rr, .] = Xt[i, .]
                        ypool[rr] = Y[i, t] - alph[i]
                    }
                }
                bcoef = _xtqb_qrmm(Xpool, ypool, tau[k])
                for (t = s; t <= e; t++) Bk[t, .] = bcoef'
            }
            Beta[k] = &(Bk :+ 0)
        }
        anew = _xtqb_alpha(Y, Xc, Beta, N, T, pp, K, tau, lam1)
        if (it > 1 & mreldif(anew, alph) < 1e-6) {
            alph = anew
            break
        }
        alph = anew
    }
    aPL = alph

    regInfo = J(totrows, 4, 0)
    regCoef = J(totrows, pp, 0)
    regSE   = J(totrows, pp, 0)
    betaPath = J(T, K*pp, 0)
    row = 0
    for (k = 1; k <= K; k++) {
        st = *Starts[k]
        nseg = rows(st)
        Bk = *Beta[k]
        for (t = 1; t <= T; t++)
            for (d = 1; d <= pp; d++) betaPath[t, (k-1)*pp + d] = Bk[t, d]
        for (r = 1; r <= nseg; r++) {
            s = st[r]
            if (r < nseg) e = st[r+1] - 1
            else e = T
            row++
            regInfo[row, 1] = k; regInfo[row, 2] = r
            regInfo[row, 3] = s; regInfo[row, 4] = e
            regCoef[row, .] = Bk[s, .]
            nobs = N * (e - s + 1)
            Xpool = J(nobs, pp, 0); ypool = J(nobs, 1, 0); rr = 0
            for (t = s; t <= e; t++) {
                Xt = *Xc[t]
                for (i = 1; i <= N; i++) {
                    rr++
                    Xpool[rr, .] = Xt[i, .]
                    ypool[rr] = Y[i, t] - alph[i]
                }
            }
            regSE[row, .] = _xtqb_se_regime(Xpool, ypool, Bk[s, .]', tau[k])'
        }
    }

    val = 0
    for (k = 1; k <= K; k++) {
        Bk = *Beta[k]
        for (t = 1; t <= T; t++) {
            Xt = *Xc[t]
            for (i = 1; i <= N; i++) {
                rrr = Y[i, t] - alph[i] - (Xt[i, .] * Bk[t, .]')
                val = val + rrr * (tau[k] - (rrr < 0))
            }
        }
    }
    sig2 = val / (K * N * T)
    if (sig2 <= 0) sig2 = 1e-8
}

// ====================================================================
//  MAIN DRIVER
// ====================================================================
void _xtqb_run(real matrix y_mat, real matrix x_mat,
               real scalar N, real scalar T, real scalar p,
               real rowvector tauin, real scalar lam1,
               real rowvector lam2grid, real scalar kappa,
               real scalar maxiter, real scalar tol,
               real scalar addcons, real scalar rconst)
{
    real scalar K, pp, i, t, k, d, it, nlam, lg, lam2, bcd
    real scalar bestIC, bestlam, rho_pen, mnNT, nbtot, thrtol, bmax, bestNbtot, sig2
    real rowvector tau, ICvec
    real matrix Y, Xt, Bk, Bk2, bk, thk, bb
    real matrix regInfo, regCoef, regSE, betaPath, brkMat
    real matrix bestBrk, bestRegCoef, bestRegSE, bestRegInfo, bestBetaPath
    real colvector alpha, alph, anew, om, st, aPL, bestAlpha
    pointer matrix Xc, BetaPrelim, Omega, Beta, Theta

    tau = tauin
    K = cols(tau)
    pp = p + addcons
    Y = y_mat

    // per-period design blocks Xc[t] = N x pp (const first if addcons)
    Xc = J(T, 1, NULL)
    for (t = 1; t <= T; t++) {
        Xt = J(N, pp, 0)
        if (addcons) Xt[., 1] = J(N, 1, 1)
        for (d = 1; d <= p; d++)
            for (i = 1; i <= N; i++) Xt[i, addcons + d] = x_mat[i, (t-1)*p + d]
        Xc[t] = &(Xt :+ 0)
    }

    // STEP 1: preliminary estimate (no fusion) -> adaptive weights
    alpha = J(N, 1, 0)
    BetaPrelim = J(K, 1, NULL)
    for (k = 1; k <= K; k++) BetaPrelim[k] = &(J(T, pp, 0))
    for (it = 1; it <= 8; it++) {
        for (k = 1; k <= K; k++) {
            Bk = J(T, pp, 0)
            for (t = 1; t <= T; t++) {
                Xt = *Xc[t]
                Bk[t, .] = _xtqb_qrmm(Xt, Y[., t] - alpha, tau[k])'
            }
            BetaPrelim[k] = &(Bk :+ 0)
        }
        alpha = _xtqb_alpha(Y, Xc, BetaPrelim, N, T, pp, K, tau, lam1)
    }

    Omega = J(K, 1, NULL)
    for (k = 1; k <= K; k++) {
        Bk2 = *BetaPrelim[k]
        om = J(T, 1, 1)
        for (t = 2; t <= T; t++) {
            bmax = sum(abs(Bk2[t, .] - Bk2[t-1, .]))
            if (bmax < 1e-6) bmax = 1e-6
            om[t] = bmax^(-kappa)
        }
        Omega[k] = &(om :+ 0)
    }

    // STEP 2-4: lambda grid + IC selection
    nlam = cols(lam2grid)
    ICvec = J(1, nlam, .)
    mnNT = min((N, T))
    rho_pen = rconst * ln(mnNT) / mnNT
    bestIC = .
    bestlam = lam2grid[1]

    for (lg = 1; lg <= nlam; lg++) {
        lam2 = lam2grid[lg]
        alph = alpha
        Beta = J(K, 1, NULL)
        Theta = J(K, 1, NULL)
        for (k = 1; k <= K; k++) Beta[k] = BetaPrelim[k]

        for (bcd = 1; bcd <= maxiter; bcd++) {
            for (k = 1; k <= K; k++) {
                _xtqb_solvek(Y :- (alph # J(1, T, 1)), Xc, N, T, pp,
                             *Omega[k], lam2, tau[k], bk, thk)
                Beta[k] = &(bk :+ 0)
                Theta[k] = &(thk :+ 0)
            }
            anew = _xtqb_alpha(Y, Xc, Beta, N, T, pp, K, tau, lam1)
            if (bcd > 1 & mreldif(anew, alph) < tol) {
                alph = anew
                break
            }
            alph = anew
        }

        bmax = 0
        for (k = 1; k <= K; k++) {
            bb = *Beta[k]
            if (_xtqb_maxabs(bb) > bmax) bmax = _xtqb_maxabs(bb)
        }
        thrtol = 1e-3 * (1 + bmax)
        nbtot = 0
        for (k = 1; k <= K; k++) {
            st = _xtqb_breaks(*Theta[k], T, thrtol)
            nbtot = nbtot + (rows(st) - 1)
        }

        _xtqb_postlasso(Y, Xc, Theta, N, T, pp, K, tau, lam1, thrtol,
                        alph, regInfo, regCoef, regSE, betaPath, brkMat, aPL, sig2)

        ICvec[lg] = ln(sig2) + rho_pen * (nbtot + K)

        if (bestIC == . | ICvec[lg] < bestIC) {
            bestIC = ICvec[lg]; bestlam = lam2
            bestBrk = brkMat; bestRegCoef = regCoef; bestRegSE = regSE
            bestRegInfo = regInfo; bestBetaPath = betaPath; bestAlpha = aPL
            bestNbtot = nbtot
        }
    }

    st_matrix("__xtqb_reginfo", bestRegInfo)
    st_matrix("__xtqb_regcoef", bestRegCoef)
    st_matrix("__xtqb_regse",   bestRegSE)
    st_matrix("__xtqb_betapath", bestBetaPath)
    st_matrix("__xtqb_brkmat",  bestBrk)
    st_matrix("__xtqb_alpha",   bestAlpha)
    st_matrix("__xtqb_icvec",   ICvec)
    st_matrix("__xtqb_lamgrid", lam2grid)
    st_numscalar("__xtqb_lambda", bestlam)
    st_numscalar("__xtqb_ic", bestIC)
    st_numscalar("__xtqb_nbreaks", bestNbtot)
    st_numscalar("__xtqb_pp", pp)
    st_numscalar("__xtqb_K", K)
}

end
