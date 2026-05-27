*! asycaus_engine v1.0.0  24may2026
*! Mata computational core for the asycaus package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

version 14.0
mata:
mata clear
mata set matastrict off

// ============================================================
//  Positive / Negative cumulative components (Granger-Yoon 2002)
// ============================================================
real matrix asycaus_pos_neg(real matrix Y, real scalar pos)
{
    real scalar T, K, t, k
    real matrix d, P, C

    T = rows(Y)
    K = cols(Y)
    if (T < 2) return(J(0, K, .))

    d = Y[2..T, .] :- Y[1..T-1, .]
    P = J(T-1, K, 0)
    for (t = 1; t <= T-1; t++) {
        for (k = 1; k <= K; k++) {
            if (pos) {
                if (d[t, k] > 0) P[t, k] = d[t, k]
            }
            else {
                if (d[t, k] < 0) P[t, k] = d[t, k]
            }
        }
    }
    C = J(T-1, K, 0)
    for (k = 1; k <= K; k++) C[., k] = runningsum(P[., k])
    return(C)
}

// ============================================================
//  Build lagged regressor matrix
// ============================================================
real matrix asycaus_lagmat(real matrix Y, real scalar p)
{
    real scalar T, K, t, j
    real matrix L

    T = rows(Y); K = cols(Y)
    if (p < 1 | T-p < 1) return(J(0, 0, .))
    L = J(T-p, K*p, .)
    for (t = p+1; t <= T; t++) {
        for (j = 1; j <= p; j++) {
            L[t-p, (j-1)*K+1..j*K] = Y[t-j, .]
        }
    }
    return(L)
}

// ============================================================
//  Information criterion selection (HJC + 4 standard)
//  ic: 1=AIC 2=AICC 3=SBC 4=HQC 5=HJC
// ============================================================
real scalar asycaus_lag_select(real matrix Z, real scalar minlag, ///
                               real scalar maxlag, real scalar ic)
{
    real scalar n, T, p, bestlag, bestic, q, dvc, val, aic, sbc, hqc, aicc
    real matrix Y, X, L, A, R, V

    n = cols(Z); T = rows(Z)
    bestlag = minlag; bestic = .

    for (p = maxlag; p >= minlag; p--) {
        if (p < 1) continue
        L = asycaus_lagmat(Z, p)
        if (rows(L) < cols(L)+2) continue
        Y = Z[p+1..T, .]
        X = J(rows(L), 1, 1), L
        A = qrsolve(X'X, X'Y)
        R = Y - X*A
        V = (R'R) / rows(Y)
        dvc = det(V)
        if (dvc <= 0) continue

        if (ic == 1) val = ln(dvc) + (2/rows(Y)) * (n*n*p + n) + n*(1+ln(2*pi()))
        else if (ic == 2) val = ln(dvc) + ((rows(Y) + (1+p*n))*n) / (rows(Y) - (1+p*n) - n - 1)
        else if (ic == 3) val = ln(dvc) + (1/rows(Y))*(n*n*p+n)*ln(rows(Y)) + n*(1+ln(2*pi()))
        else if (ic == 4) val = ln(dvc) + (2/rows(Y))*(n*n*p+n)*ln(ln(rows(Y))) + n*(1+ln(2*pi()))
        else if (ic == 5) {
            sbc = ln(dvc) + (1/rows(Y))*(n*n*p+n)*ln(rows(Y)) + n*(1+ln(2*pi()))
            hqc = ln(dvc) + (2/rows(Y))*(n*n*p+n)*ln(ln(rows(Y))) + n*(1+ln(2*pi()))
            val = (sbc + hqc)/2
        }
        else val = .

        if (bestic == . | val <= bestic) {
            bestic = val
            bestlag = p
        }
    }
    return(bestlag)
}

string scalar asycaus_ic_name(real scalar ic)
{
    if (ic == 1) return("AIC")
    if (ic == 2) return("AICC")
    if (ic == 3) return("SBC")
    if (ic == 4) return("HQC")
    if (ic == 5) return("HJC")
    return("USER")
}

// ============================================================
//  Wald non-causality test in VAR(p) augmented with addlags
//  Tests whether variable jvar does NOT cause variable kvar.
//  Returns Wald statistic and degrees of freedom (= p).
// ============================================================
real rowvector asycaus_wald(real matrix Z, real scalar p, real scalar addlags, ///
                            real scalar kvar, real scalar jvar)
{
    real scalar maxlag, T, n, q, T2, i, r, c, idx
    real matrix Y, L, X, A, R, V, Sigma, beta, C, mid, Wm
    real scalar W

    n = cols(Z); T = rows(Z)
    maxlag = p + addlags
    L = asycaus_lagmat(Z, maxlag)
    if (rows(L) < cols(L)+2) return((., p))
    Y = Z[maxlag+1..T, .]
    X = J(rows(L), 1, 1), L
    T2 = rows(Y)
    q = cols(X)

    A = qrsolve(X'X, X'Y)            // q x n
    R = Y - X*A
    Sigma = (R'R) / (T2 - q)

    // vec(A): stacks columns of A.  Coefficient on jvar at lag r in equation
    // for kvar is A[1 + (r-1)*n + jvar, kvar].  In vec(A), index =
    //   (kvar-1)*q + 1 + (r-1)*n + jvar.
    // We restrict r = 1..p (not the augmentation lags p+1..p+addlags).
    C = J(p, q*n, 0)
    for (r = 1; r <= p; r++) {
        idx = (kvar - 1)*q + 1 + (r - 1)*n + jvar
        C[r, idx] = 1
    }
    beta = vec(A)
    Wm = invsym(X'X) # Sigma         // q*n x q*n covariance for vec(A)
    mid = C * Wm * C'
    W = ((C*beta)' * invsym(mid) * (C*beta))
    return((W, p))
}

// ============================================================
//  Leverage-adjusted bootstrap critical values (Hacker-Hatemi-J)
// ============================================================
real rowvector asycaus_boot_cv(real matrix Z, real scalar p, real scalar addlags, ///
                               real scalar kvar, real scalar jvar, ///
                               real scalar B, real scalar seed)
{
    real scalar n, T, maxlag, q, T2, b, r, c, t, i, idx
    real matrix Y, L, X, Ah, Rh, R, Aur, Ahatr, leverage, adj, simerr
    real matrix Zsim, Xsim, Ysim, Lsim, Asim, Rsim, Sigsim, Cmat, beta, midm, Hmat
    real colvector W
    real rowvector cv
    real scalar Wb

    n = cols(Z); T = rows(Z)
    maxlag = p + addlags
    L = asycaus_lagmat(Z, maxlag)
    Y = Z[maxlag+1..T, .]
    X = J(rows(L), 1, 1), L
    T2 = rows(Y)
    q = cols(X)

    // Estimate RESTRICTED VAR under H0: no causality from jvar to kvar.
    // We zero out coefficients on jvar lags 1..p (not augmentation lags) in
    // equation for kvar.
    Ahatr = qrsolve(X'X, X'Y)
    // Re-estimate the equation for kvar with restrictions imposed.
    real colvector restr
    restr = J(q, 1, 0)
    for (r = 1; r <= p; r++) restr[1 + (r-1)*n + jvar] = 1
    real matrix Xr, br
    Xr = select(X, !restr')
    br = qrsolve(Xr'Xr, Xr'Y[., kvar])
    real colvector bf
    bf = J(q, 1, 0)
    idx = 1
    for (i = 1; i <= q; i++) {
        if (restr[i] == 0) {
            bf[i] = br[idx]
            idx++
        }
    }
    Ahatr[., kvar] = bf

    Rh = Y - X*Ahatr

    // Leverages from the restricted-equation (column kvar) design Xr
    real matrix Hr, Hf
    Hr = Xr * invsym(Xr'Xr) * Xr'
    Hf = X  * invsym(X'X)  * X'
    real colvector lev_k, lev_o
    lev_k = diagonal(Hr)
    lev_o = diagonal(Hf)
    // Build T2 x n leverage matrix: column kvar -> lev_k, others -> lev_o
    leverage = J(T2, n, 0)
    for (c = 1; c <= n; c++) leverage[., c] = (c == kvar ? lev_k : lev_o)
    adj = sqrt(1 :- leverage)
    // protect against division by zero
    adj = editmissing(adj, 1)
    real matrix adjR
    adjR = Rh :/ adj

    if (seed != .) rseed(seed)
    W = J(B, 1, .)

    real matrix Zlags
    Zlags = Z[1..maxlag, .]

    for (b = 1; b <= B; b++) {
        // Resample residuals with replacement, one index per column
        simerr = J(T2, n, .)
        for (t = 1; t <= T2; t++) {
            for (c = 1; c <= n; c++) {
                idx = ceil(runiform(1,1) * T2)
                if (idx < 1) idx = 1
                if (idx > T2) idx = T2
                simerr[t, c] = adjR[idx, c]
            }
        }
        // Center each column
        for (c = 1; c <= n; c++) simerr[., c] = simerr[., c] :- mean(simerr[., c])

        // Recursively build Zsim using Ahatr (restricted) coefficients
        Zsim = Zlags
        for (t = 1; t <= T2; t++) {
            real rowvector lagsrow
            lagsrow = J(1, n*maxlag, .)
            for (i = 1; i <= maxlag; i++) {
                lagsrow[1, (i-1)*n+1..i*n] = Zsim[rows(Zsim)-i+1, .]
            }
            real rowvector xrow, yrow
            xrow = (1, lagsrow)
            yrow = xrow * Ahatr + simerr[t, .]
            Zsim = Zsim \ yrow
        }
        // Now estimate UNRESTRICTED VAR on Zsim and compute Wald
        real rowvector Wres
        Wres = asycaus_wald(Zsim, p, addlags, kvar, jvar)
        W[b] = Wres[1]
    }
    // Sort and compute 1%, 5%, 10% upper critical values (averaged with next)
    W = sort(W, 1)
    real scalar i1, i5, i10
    i1  = B - trunc(B/100)
    i5  = B - trunc(B/20)
    i10 = B - trunc(B/10)
    real scalar c1, c5, c10
    c1  = (W[i1]  + W[min((B, i1  + max((1, trunc(B/100))) ))]) / 2
    c5  = (W[i5]  + W[min((B, i5  + max((1, trunc(B/20))) ))])  / 2
    c10 = (W[i10] + W[min((B, i10 + max((1, trunc(B/10))) ))])  / 2
    cv = (c1, c5, c10)
    return(cv)
}

// ============================================================
//  Fourier sin/cos terms (Enders-Lee / Nazlioglu)
// ============================================================
real matrix asycaus_fourier_terms(real scalar T, real scalar k, string scalar mode)
{
    real colvector tt, sn, cs
    real matrix F
    real scalar j

    tt = (1::T)
    if (mode == "single") {
        sn = sin(2 * pi() * k * tt :/ T)
        cs = cos(2 * pi() * k * tt :/ T)
        F = sn, cs
    }
    else {
        // cumulative: sum from j=1..k
        F = J(T, 0, .)
        for (j = 1; j <= k; j++) {
            sn = sin(2 * pi() * j * tt :/ T)
            cs = cos(2 * pi() * j * tt :/ T)
            F = F, sn, cs
        }
    }
    return(F)
}

// ============================================================
//  Fourier-augmented VAR Wald test
// ============================================================
real rowvector asycaus_wald_fourier(real matrix Z, real scalar p, real scalar addlags, ///
                                    real scalar kvar, real scalar jvar, ///
                                    real scalar kfreq, string scalar mode)
{
    real scalar T, n, maxlag, T2, q, r, c, idx
    real matrix Y, L, F, X, A, R, Sigma, Wm, Cmat, beta, midm
    real scalar W

    n = cols(Z); T = rows(Z)
    maxlag = p + addlags
    L = asycaus_lagmat(Z, maxlag)
    F = asycaus_fourier_terms(T, kfreq, mode)
    F = F[maxlag+1..T, .]
    Y = Z[maxlag+1..T, .]
    T2 = rows(Y)
    X = J(T2, 1, 1), F, L
    q = cols(X)
    A = qrsolve(X'X, X'Y)
    R = Y - X*A
    Sigma = (R'R) / (T2 - q)

    real scalar nF
    nF = cols(F)

    // coefficient on jvar at lag r in equation for kvar lives at row
    // 1 + nF + (r-1)*n + jvar of A (rows indexed by column of X).
    Cmat = J(p, q*n, 0)
    for (r = 1; r <= p; r++) {
        idx = (kvar - 1)*q + 1 + nF + (r - 1)*n + jvar
        Cmat[r, idx] = 1
    }
    beta = vec(A)
    Wm = invsym(X'X) # Sigma
    midm = Cmat * Wm * Cmat'
    W = ((Cmat*beta)' * invsym(midm) * (Cmat*beta))
    return((W, p))
}

// ============================================================
//  Breitung-Candelon (2006) spectral causality at frequency omega
//  Returns Wald-type statistic ~ chi^2(2) under H0 of no causality
//  at frequency omega.
// ============================================================
real scalar asycaus_bc_at_omega(real matrix Z, real scalar p, real scalar omega, ///
                                real scalar kvar, real scalar jvar)
{
    real scalar T, n, T2, q, r
    real matrix Y, L, X, A, R, Sigma, Wm, Cmat, beta, midm
    real scalar W

    n = cols(Z); T = rows(Z)
    L = asycaus_lagmat(Z, p)
    Y = Z[p+1..T, .]
    X = J(rows(L), 1, 1), L
    T2 = rows(Y); q = cols(X)
    A = qrsolve(X'X, X'Y)
    R = Y - X*A
    Sigma = (R'R) / (T2 - q)

    // Restrictions: sum_{r=1..p} a_{kvar,jvar,r} cos(r*omega) = 0
    //               sum_{r=1..p} a_{kvar,jvar,r} sin(r*omega) = 0
    Cmat = J(2, q*n, 0)
    for (r = 1; r <= p; r++) {
        real scalar ix
        ix = (kvar - 1)*q + 1 + (r - 1)*n + jvar
        Cmat[1, ix] = cos(r*omega)
        Cmat[2, ix] = sin(r*omega)
    }
    beta = vec(A)
    Wm = invsym(X'X) # Sigma
    midm = Cmat * Wm * Cmat'
    W = ((Cmat*beta)' * invsym(midm) * (Cmat*beta))
    return(W)
}

// ============================================================
//  Quantile VAR Wald non-causality test (asymptotic)
//  Uses Stata's qreg via callout; here we provide a simple
//  iteratively reweighted least squares quantile estimator.
// ============================================================
real colvector asycaus_qreg(real colvector y, real matrix X, real scalar tau)
{
    real scalar k, n, iter
    real colvector b, b0, r, w
    real matrix W

    n = rows(y); k = cols(X)
    // Start at OLS
    b = qrsolve(X'X, X'y)
    for (iter = 1; iter <= 100; iter++) {
        r = y - X*b
        // weight w_i = tau if r > 0 else (1-tau), then divided by |r|
        w = (r :> 0) :* tau :+ (r :<= 0) :* (1 - tau)
        w = w :/ (abs(r) :+ 1e-6)
        W = diag(w)
        b0 = b
        b = qrsolve(X'(W*X), X'(W*y))
        if (max(abs(b - b0)) < 1e-7) break
    }
    return(b)
}

real rowvector asycaus_wald_quant(real matrix Z, real scalar p, real scalar addlags, ///
                                  real scalar kvar, real scalar jvar, real scalar tau)
{
    real scalar T, n, maxlag, T2, q, r, idx
    real matrix Y, L, X
    real colvector b, e
    real scalar W, sig

    n = cols(Z); T = rows(Z)
    maxlag = p + addlags
    L = asycaus_lagmat(Z, maxlag)
    Y = Z[maxlag+1..T, .]
    X = J(rows(L), 1, 1), L
    T2 = rows(Y); q = cols(X)

    // Estimate quantile regression for equation kvar
    b = asycaus_qreg(Y[., kvar], X, tau)
    e = Y[., kvar] - X*b
    // Sparsity estimate via Bofinger bandwidth
    real scalar h
    h = T2^(-1/5) * (4.5 * normalden(invnormal(tau))^4 /
                    (2*invnormal(tau)^2 + 1)^2 )^(1/5)
    real scalar f_hat
    // Estimate f(F^-1(tau)) by kernel on residuals at zero
    f_hat = mean(normalden(e :/ h)) / h
    if (f_hat <= 0) f_hat = 1e-6
    // Asymptotic variance: tau*(1-tau)/f_hat^2 * (X'X)^-1
    real matrix V
    V = (tau*(1-tau)/(f_hat^2)) * invsym(X'X)

    // Build restriction
    real matrix Cmat
    Cmat = J(p, q, 0)
    for (r = 1; r <= p; r++) {
        idx = 1 + (r - 1)*n + jvar
        Cmat[r, idx] = 1
    }
    W = ((Cmat*b)' * invsym(Cmat*V*Cmat') * (Cmat*b))
    return((W, p))
}

// ============================================================
//  Fourier detrending of the Zcomp Stata matrix (helper for
//  asycaus_quantile.ado).  Reads Zcomp from Stata, removes the
//  Fourier sin/cos fit, writes the residual matrix back to Zcomp.
// ============================================================
void asycaus_qfourier_detrend(real scalar kmax)
{
    real matrix Zc, F, X, B, R
    real scalar Tc
    Zc = st_matrix("Zcomp")
    Tc = rows(Zc)
    F  = asycaus_fourier_terms(Tc, kmax, "cumulative")
    X  = J(Tc, 1, 1), F
    B  = qrsolve(X'X, X'Zc)
    R  = Zc - X*B
    st_matrix("Zcomp", R)
}

// ============================================================
//  Efficient asymmetric test via SUR-style joint estimation
//  Combines positive and negative components into one system,
//  tests joint and difference restrictions.
// ============================================================
real rowvector asycaus_efficient(real matrix Zpos, real matrix Zneg, ///
                                 real scalar p, real scalar addlags, ///
                                 real scalar kvar, real scalar jvar)
{
    real scalar n, Tp, Tn, T, q, r, idx
    real matrix Yp, Yn, Lp, Ln, Xp, Xn, Y, X, A, R, Sigma, Wm, C1, C2, beta, midm
    real scalar Wp, Wn, Wjoint, Wdiff

    n = cols(Zpos)
    Tp = rows(Zpos); Tn = rows(Zneg)
    T = min((Tp, Tn))
    Zpos = Zpos[1..T, .]; Zneg = Zneg[1..T, .]

    // Build stacked system: equations for kvar in pos and neg models share X structure
    // but coefficients differ. We estimate two unrestricted regressions and form
    // a Wald test using joint covariance from the SUR.
    real scalar maxlag
    maxlag = p + addlags
    Lp = asycaus_lagmat(Zpos, maxlag)
    Ln = asycaus_lagmat(Zneg, maxlag)
    Yp = Zpos[maxlag+1..T, kvar]
    Yn = Zneg[maxlag+1..T, kvar]
    Xp = J(rows(Lp), 1, 1), Lp
    Xn = J(rows(Ln), 1, 1), Ln
    q = cols(Xp)

    // Compute OLS first to get residuals
    real colvector bp, bn, ep, en
    bp = qrsolve(Xp'Xp, Xp'Yp)
    bn = qrsolve(Xn'Xn, Xn'Yn)
    ep = Yp - Xp*bp
    en = Yn - Xn*bn
    real scalar sp, sn, scov, det2
    sp  = (ep'ep) / (rows(ep) - q)
    sn  = (en'en) / (rows(en) - q)
    scov = (ep'en) / max((rows(ep), rows(en)))
    det2 = sp*sn - scov^2

    // GLS / SUR using inverse Sigma kron I
    real matrix Sig, iSig, big_X, big_Y
    Sig = (sp, scov \ scov, sn)
    iSig = invsym(Sig)

    real scalar T2
    T2 = rows(Xp)
    // Block-diagonal X for the two equations
    real matrix Xblock
    Xblock = (Xp, J(T2, q, 0) \ J(T2, q, 0), Xn)
    real colvector Yblock
    Yblock = Yp \ Yn

    // SUR estimator: (X' (iSig kron I) X)^-1 X' (iSig kron I) Y
    real matrix Omega_inv
    Omega_inv = iSig # I(T2)
    real colvector bsur
    real matrix Vsur
    Vsur = invsym(Xblock'Omega_inv*Xblock)
    bsur = Vsur*Xblock'Omega_inv*Yblock

    // C1: causality from jvar in positive system
    // C2: causality from jvar in negative system
    // Joint: both restrictions; Diff: bpos = bneg
    C1 = J(p, 2*q, 0); C2 = J(p, 2*q, 0)
    real matrix Cdiff
    Cdiff = J(p, 2*q, 0)
    for (r = 1; r <= p; r++) {
        idx = 1 + (r - 1)*n + jvar
        C1[r, idx]      =  1
        C2[r, q + idx]  =  1
        Cdiff[r, idx]      =  1
        Cdiff[r, q + idx]  = -1
    }
    Wp     = ((C1*bsur)'    * invsym(C1*Vsur*C1')       * (C1*bsur))
    Wn     = ((C2*bsur)'    * invsym(C2*Vsur*C2')       * (C2*bsur))
    real matrix Cjoint
    Cjoint = C1 \ C2
    Wjoint = ((Cjoint*bsur)' * invsym(Cjoint*Vsur*Cjoint') * (Cjoint*bsur))
    Wdiff  = ((Cdiff*bsur)' * invsym(Cdiff*Vsur*Cdiff') * (Cdiff*bsur))

    return((Wp, Wn, Wjoint, Wdiff, p))
}

end
