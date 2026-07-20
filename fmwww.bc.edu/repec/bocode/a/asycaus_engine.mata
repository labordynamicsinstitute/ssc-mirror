*! asycaus_engine v1.0.4  19jul2026
*! Mata computational core for the asycaus package
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! v1.0.4:
*!   - corrected the Wald covariance Kronecker order (Sigma # (X'X)^-1) to match
*!     Hatemi-J (2012) Eq.7 / (2021) Eq.13 and the GAUSS reference (verified
*!     against Stata -vargranger-);
*!   - fixed the leverage-bootstrap CV order-statistic step (min, per the GAUSS
*!     Bootstrap_Toda routine);
*!   - lag selection now holds the estimation sample fixed at T-maxlag across
*!     candidate lags (GAUSS lag_length2 / Hatemi-J 2003);
*!   - asycaus_fourier_fit added for SSR-based Fourier frequency selection
*!     (Nazlioglu, Gormus & Soytas 2016);
*!   - asycaus_efficient rewritten as the full four-equation SURE/FGLS of
*!     Hatemi-J (2024, Eq.7 / Appendix A1-A4) (verified against -sureg-);
*!   - asycaus_pos_neg_trend added: the deterministic-trend (drift and/or linear
*!     trend) asymmetric transformation of Hatemi-J & El-Khatib (2016);
*!     trend=0 reproduces the Granger-Yoon cumulation exactly.

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
//  Deterministic-trend asymmetric transformation
//  (Hatemi-J & El-Khatib 2016, Eqs 3-5 / application Eqs 22-23).
//  For an I(1) column y: d = Dy; regress d on the chosen deterministic
//  terms; cumulate the positive (or negative) part of the RESIDUALS and
//  add back half of the fitted deterministic trajectory:
//     comp_s = det_s/2 + cumsum(resid+/-),
//     det_s  = a*s + b*s(s+1)/2 + y0 ,   y0 = y[1].
//  trend: 0 = none (identical to asycaus_pos_neg / Granger-Yoon),
//         1 = drift only, 2 = drift + linear trend.
//  By construction comp+ + comp- reproduces the level, so the equivalency
//  y = y+ + y- of Hatemi-J & El-Khatib (2016) holds.
// ============================================================
real matrix asycaus_pos_neg_trend(real matrix Y, real scalar pos, real scalar trend)
{
    real scalar K, ns, k, s, aa, bb
    real matrix d, C, X
    real colvector dk, bk, resid, dtr, sidx, pp

    if (trend <= 0) return(asycaus_pos_neg(Y, pos))
    if (rows(Y) < 2) return(J(0, cols(Y), .))

    K  = cols(Y)
    d  = Y[2..rows(Y), .] :- Y[1..rows(Y)-1, .]     // (T-1) x K
    ns = rows(d)
    sidx = (1::ns)
    C = J(ns, K, 0)

    for (k = 1; k <= K; k++) {
        dk = d[., k]
        if (trend == 1) X = J(ns, 1, 1)
        else            X = J(ns, 1, 1), sidx
        bk    = qrsolve(X'X, X'dk)
        resid = dk - X*bk
        aa = bk[1]
        bb = (trend >= 2 ? bk[2] : 0)
        dtr = aa :* sidx :+ bb :* (sidx :* (sidx :+ 1) :/ 2) :+ Y[1, k]
        if (pos) pp = resid :* (resid :> 0)
        else     pp = resid :* (resid :< 0)
        C[., k] = dtr :/ 2 :+ runningsum(pp)
    }
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
    real scalar n, T, p, bestlag, bestic, Tc, dvc, val, sbc, hqc
    real matrix Y, X, Lmax, A, R, V

    n = cols(Z); T = rows(Z)
    bestlag = minlag; bestic = .

    // Match GAUSS lag_length2: lag once at maxlag and hold the estimation
    // sample fixed at T-maxlag for ALL candidate lags (each smaller lag order
    // just uses the first p*n lag columns).  This keeps the information
    // criteria comparable across p, as required by Hatemi-J (2003).
    if (maxlag < 1 | T - maxlag < 2) return(bestlag)
    Lmax = asycaus_lagmat(Z, maxlag)          // (T-maxlag) x (n*maxlag)
    Y    = Z[maxlag+1..T, .]                   // common sample
    Tc   = rows(Y)

    for (p = maxlag; p >= minlag; p--) {
        if (p < 1) continue
        if (p == 0) X = J(Tc, 1, 1)
        else        X = J(Tc, 1, 1), Lmax[., 1..p*n]
        if (Tc < cols(X) + 2) continue
        A = qrsolve(X'X, X'Y)
        R = Y - X*A
        V = (R'R) / Tc
        dvc = det(V)
        if (dvc <= 0) continue

        if (ic == 1) val = ln(dvc) + (2/Tc) * (n*n*p + n) + n*(1+ln(2*pi()))
        else if (ic == 2) val = ln(dvc) + ((Tc + (1+p*n))*n) / (Tc - (1+p*n) - n - 1)
        else if (ic == 3) val = ln(dvc) + (1/Tc)*(n*n*p+n)*ln(Tc) + n*(1+ln(2*pi()))
        else if (ic == 4) val = ln(dvc) + (2/Tc)*(n*n*p+n)*ln(ln(Tc)) + n*(1+ln(2*pi()))
        else if (ic == 5) {
            sbc = ln(dvc) + (1/Tc)*(n*n*p+n)*ln(Tc) + n*(1+ln(2*pi()))
            hqc = ln(dvc) + (2/Tc)*(n*n*p+n)*ln(ln(Tc)) + n*(1+ln(2*pi()))
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
    // Cov(vec(A)) = Sigma (X) (X'X)^-1 for the column-stacked (equation-major)
    // vec(A) with A being q x n.  This reproduces Eq.(7) of Hatemi-J (2012) /
    // Eq.(13) of Hatemi-J (2021) and the GAUSS W_test (which pairs the reverse
    // Kronecker order (X'X)^-1 (X) Sigma with a regressor-major vecr(Ahat')).
    Wm = Sigma # invsym(X'X)         // q*n x q*n covariance for vec(A)
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
    // GAUSS Bootstrap_Toda averages the order statistic with the *adjacent*
    // one: index step = min(1, trunc(B/frac)) (= 1 for B >= frac).  Using max()
    // here averaged with the sample maximum W[B] and inflated every CV.
    real scalar c1, c5, c10
    c1  = (W[i1]  + W[min((B, i1  + min((1, trunc(B/100))) ))]) / 2
    c5  = (W[i5]  + W[min((B, i5  + min((1, trunc(B/20))) ))])  / 2
    c10 = (W[i10] + W[min((B, i10 + min((1, trunc(B/10))) ))])  / 2
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
    Wm = Sigma # invsym(X'X)          // Cov(vec(A)); see asycaus_wald note
    midm = Cmat * Wm * Cmat'
    W = ((Cmat*beta)' * invsym(midm) * (Cmat*beta))
    return((W, p))
}

// ============================================================
//  Fit criterion for selecting the optimal Fourier frequency k*.
//  Returns det of the residual covariance of the Fourier-augmented VAR.
//  Nazlioglu, Gormus & Soytas (2016) select k* by minimizing the model SSR
//  (here its multivariate analogue), NOT by maximizing the causality Wald.
// ============================================================
real scalar asycaus_fourier_fit(real matrix Z, real scalar p, real scalar addlags, ///
                                real scalar kfreq, string scalar mode)
{
    real scalar T, n, maxlag, T2
    real matrix Y, L, F, X, A, R, V

    n = cols(Z); T = rows(Z)
    maxlag = p + addlags
    L = asycaus_lagmat(Z, maxlag)
    F = asycaus_fourier_terms(T, kfreq, mode)
    F = F[maxlag+1..T, .]
    Y = Z[maxlag+1..T, .]
    T2 = rows(Y)
    X = J(T2, 1, 1), F, L
    A = qrsolve(X'X, X'Y)
    R = Y - X*A
    V = (R'R) / T2
    return(det(V))
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
    Wm = Sigma # invsym(X'X)          // Cov(vec(A)); see asycaus_wald note
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
//  Efficient asymmetric causality test — Hatemi-J (2024, arXiv:2408.03137)
//  Full four-equation autoregressive SURE / FGLS over the stacked
//  dependent vector [Z1+, Z2+, Z1-, Z2-] (Eq.7).  The efficiency gain and
//  the cross-component covariance needed for the POS-vs-NEG difference test
//  come from the joint 4x4 error covariance Omega (Appendix A1-A4):
//     Chat = [X'(Omega^-1 (x) I)X]^-1 X'(Omega^-1 (x) I)Y ,  Var(Chat)=[.]^-1 .
//  The + equations regress on lagged + components, the - equations on lagged
//  - components; an extra unrestricted Toda-Yamamoto lag (addlags) is included
//  and the causality restrictions cover lags 1..p only.
//  Returns (Wpos, Wneg, Wjoint, Wdiff, p) for the null that jvar does not
//  cause kvar (Eqs 8, 9, 10, 11 respectively).
// ============================================================
real rowvector asycaus_efficient(real matrix Zpos, real matrix Zneg, ///
                                 real scalar p, real scalar addlags, ///
                                 real scalar kvar, real scalar jvar)
{
    real scalar n, Tp, Tn, T, maxlag, q, T2, a, b, r, k
    real scalar eqPos, eqNeg, colP, colN
    real matrix Lp, Ln, Xp, Xm, Ymat, E, Om, iOm
    real matrix XpXp, XpXm, XmXm, XpY, XmY, XtXab, A, V
    real matrix Cpos, Cneg, Cjoint, Cdiff
    real colvector Chat, g, Ya
    real scalar Wp, Wn, Wjoint, Wdiff

    n = cols(Zpos)
    Tp = rows(Zpos); Tn = rows(Zneg)
    T = min((Tp, Tn))
    Zpos = Zpos[1..T, .]; Zneg = Zneg[1..T, .]

    maxlag = p + addlags
    Lp = asycaus_lagmat(Zpos, maxlag)   // (T-maxlag) x (n*maxlag)
    Ln = asycaus_lagmat(Zneg, maxlag)
    Xp = J(rows(Lp), 1, 1), Lp          // design for the + equations
    Xm = J(rows(Ln), 1, 1), Ln          // design for the - equations
    q  = cols(Xp)
    T2 = rows(Xp)

    // Dependent vectors, common sample, in equation order [Z1+, Z2+, Z1-, Z2-]
    Ymat = Zpos[maxlag+1..T, 1], Zpos[maxlag+1..T, 2], ///
           Zneg[maxlag+1..T, 1], Zneg[maxlag+1..T, 2]

    // Equation-by-equation OLS residuals -> 4x4 covariance Omega (divisor T2,
    // matching Zellner / Stata -sureg-).
    E = J(T2, 4, 0)
    for (a = 1; a <= 4; a++) {
        if (a <= 2) E[., a] = Ymat[., a] - Xp*qrsolve(Xp'Xp, Xp'Ymat[., a])
        else        E[., a] = Ymat[., a] - Xm*qrsolve(Xm'Xm, Xm'Ymat[., a])
    }
    Om  = (E'E) / T2
    iOm = invsym(Om)

    // Pre-compute the distinct design cross-products.  Equations 1,2 share Xp
    // and equations 3,4 share Xm, so only three blocks are distinct.
    XpXp = Xp'Xp; XpXm = Xp'Xm; XmXm = Xm'Xm
    XpY  = Xp'Ymat        // q x 4
    XmY  = Xm'Ymat        // q x 4

    // Assemble A = X'(Omega^-1 (x) I)X   (4q x 4q) and g = X'(Omega^-1 (x) I)Y.
    A = J(4*q, 4*q, 0)
    g = J(4*q, 1, 0)
    for (a = 1; a <= 4; a++) {
        Ya = J(q, 1, 0)
        for (b = 1; b <= 4; b++) {
            if (a <= 2 & b <= 2)      XtXab = XpXp
            else if (a <= 2 & b >  2) XtXab = XpXm
            else if (a >  2 & b <= 2) XtXab = XpXm'
            else                      XtXab = XmXm
            A[(a-1)*q+1..a*q, (b-1)*q+1..b*q] = iOm[a, b] * XtXab
            if (a <= 2) Ya = Ya + iOm[a, b]*XpY[., b]
            else        Ya = Ya + iOm[a, b]*XmY[., b]
        }
        g[(a-1)*q+1..a*q] = Ya
    }
    V    = invsym(A)
    Chat = V * g

    // Depvar (kvar) + equation is eqPos; its - equation is eqNeg.  The causal
    // coefficient of jvar at lag r sits at column 1+(r-1)*n+jvar within a block.
    eqPos = kvar
    eqNeg = kvar + 2
    Cpos  = J(p, 4*q, 0)
    Cneg  = J(p, 4*q, 0)
    Cdiff = J(p, 4*q, 0)
    for (r = 1; r <= p; r++) {
        colP = (eqPos - 1)*q + 1 + (r - 1)*n + jvar
        colN = (eqNeg - 1)*q + 1 + (r - 1)*n + jvar
        Cpos[r, colP]  =  1
        Cneg[r, colN]  =  1
        Cdiff[r, colP] =  1
        Cdiff[r, colN] = -1
    }
    Cjoint = Cpos \ Cneg

    Wp     = ((Cpos*Chat)'   * invsym(Cpos*V*Cpos')     * (Cpos*Chat))
    Wn     = ((Cneg*Chat)'   * invsym(Cneg*V*Cneg')     * (Cneg*Chat))
    Wjoint = ((Cjoint*Chat)' * invsym(Cjoint*V*Cjoint') * (Cjoint*Chat))
    Wdiff  = ((Cdiff*Chat)'  * invsym(Cdiff*V*Cdiff')   * (Cdiff*Chat))

    return((Wp, Wn, Wjoint, Wdiff, p))
}

end
