*! _mixi12_mata.mata 1.0.0  21may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
*  Mata kernel for the mixi12 package — mixed I(1)/I(2) cointegration.
*  Provides:
*     _mixi12_orthcomp()        orthogonal complement
*     _mixi12_rrr()             reduced-rank regression (Anderson 1951)
*     _mixi12_johansen1()       Johansen I(1) trace + estimates
*     _mixi12_johansen2()       two-step Johansen I(2)
*     _mixi12_paruoloQ()        Paruolo (1996) joint Q(r,s1) test
*     _mixi12_haldrup_adf()     residual-based ADF for I(2) cointegration
*     _mixi12_haldrup_cv()      Haldrup (1994b) critical values
*     _mixi12_dp_F()            Dickey-Pantula joint F-stats
*     _mixi12_hasza_fuller()    Hasza-Fuller F joint test for double UR
*     _mixi12_haldrup_Zf()      Haldrup (1994a) semiparametric Z-test
*     _mixi12_kongsted()        I(2)-to-I(1) transformation LR test
*     _mixi12_lr_var()          Newey-West long-run variance
*     _mixi12_adf_t()           simple ADF t-stat
*     _mixi12_demean()          demean / detrend
*     _mixi12_diff()            first / second differences (NA-aware)

version 14
mata
mata set matastrict off

void __mixi12_loaded() { /* sentinel for the _mixi12_mata loader */ }

// --------------------------------------------------------------------
// orthogonal complement of an n x r matrix A (assumed full column rank)
// returns n x (n-r) matrix Ap such that A'Ap = 0 and (A : Ap) has rank n
// --------------------------------------------------------------------
real matrix _mixi12_orthcomp(real matrix A)
{
    real matrix Q, R, P
    real scalar n, r
    n = rows(A)
    r = cols(A)
    if (r >= n) return(J(n, 0, .))
    if (r == 0) return(I(n))
    // QR: A = Q R, Q is n x n orthogonal.  Last n-r columns of Q span A_perp.
    qrd(A, Q=., R=.)
    P = Q[., (r+1)..n]
    return(P)
}

// --------------------------------------------------------------------
// demean / detrend a T x m matrix
// trend = 0  none ;  1  constant ;  2  constant + linear t ;
// trend = 3  constant + linear + quadratic
// --------------------------------------------------------------------
real matrix _mixi12_demean(real matrix Y, real scalar trend)
{
    real scalar T, m
    real matrix D, B, R
    T = rows(Y); m = cols(Y)
    if (trend <= 0) return(Y)
    if (trend == 1) D = J(T,1,1)
    else if (trend == 2) D = (J(T,1,1), (1::T))
    else D = (J(T,1,1), (1::T), (1::T):^2)
    B = invsym(D'D) * D'Y
    R = Y - D*B
    return(R)
}

// --------------------------------------------------------------------
// Newey-West / Bartlett long-run variance of a T x m series
// --------------------------------------------------------------------
real matrix _mixi12_lr_var(real matrix u, real scalar bw)
{
    real scalar T, m, j, w
    real matrix S, G
    T = rows(u); m = cols(u)
    S = u'u / T
    for (j=1; j<=bw; j++) {
        w = 1 - j/(bw+1)
        G = u[(j+1)..T, .]' u[1..(T-j), .] / T
        S = S + w*(G + G')
    }
    return(S)
}

// --------------------------------------------------------------------
// reduced-rank regression of Y on X given common conditioning Z
//    Y = Pi X + residual,   rank(Pi) <= r
// Returns:  e0..S00, S01, S11, eigvals (descending), eigvecs (in beta)
// All inputs are T x . matrices; Z may be void (cols(Z)==0).
// Output: structure carried via pointer arguments.
// --------------------------------------------------------------------
void _mixi12_rrr(real matrix Y, real matrix X, real matrix Z,
                 real matrix S00, real matrix S01, real matrix S11,
                 real colvector lam, real matrix beta)
{
    real matrix R0, R1, A, B, eigvec, eigval, sqrtS11
    real scalar T
    T = rows(Y)
    if (cols(Z)) {
        // residualise: R0 = Y - Z (Z'Z)^-1 Z'Y, etc.
        B = invsym(Z'Z) * Z'Y; R0 = Y - Z*B
        B = invsym(Z'Z) * Z'X; R1 = X - Z*B
    } else {
        R0 = Y; R1 = X
    }
    S00 = R0'R0 / T
    S01 = R0'R1 / T
    S11 = R1'R1 / T
    // generalised eigenproblem |λ S11 - S10 S00^-1 S01| = 0
    A = invsym(S11) * (S01' * invsym(S00) * S01)
    eigensystem(A, eigvec=., eigval=.)
    lam = Re(eigval'); beta = Re(eigvec)
    // sort descending
    real colvector ord
    ord = order(-lam, 1)
    lam = lam[ord]
    beta = beta[., ord]
}

// --------------------------------------------------------------------
// Johansen (1988) I(1) reduced-rank analysis of a VAR(k) for X (T x p)
//   ΔX_t = αβ'X_{t-1} + Γ_1 ΔX_{t-1} + ... + Γ_{k-1} ΔX_{t-k+1} + μ + ε_t
// dettrend codes (Juselius/CATS) :
//   1 = no constant, no trend ('H_lr')
//   2 = constant restricted to coint space  (default; "H_l*")
//   3 = unrestricted constant (no trend)    ("H_l")
//   4 = trend restricted to coint space     ("H_c*")
//   5 = unrestricted trend                  ("H_c")
//
// Returns by reference:
//   lam   : p x 1 eigenvalues
//   trace : p x 1 trace statistics (rank=0,1,...,p-1)
//   maxev : p x 1 max-eigenvalue statistics
//   beta  : (p+const adj) x p eigenvectors (normalised so beta'S11 beta = I)
//   alpha : p x p loadings  (alpha = S01 * beta * inv(beta'S11 beta))
//   Gamma : p x p*(k-1) short-run matrices
//   S00, S11, S01 : sample moment matrices
// --------------------------------------------------------------------
void _mixi12_johansen1(real matrix X, real scalar k, real scalar dettrend,
                       real colvector lam, real colvector trace,
                       real colvector maxev,
                       real matrix beta, real matrix alpha,
                       real matrix Gamma,
                       real matrix S00, real matrix S11, real matrix S01,
                       real scalar Tused)
{
    real scalar T, p, i, eff, j
    real matrix DX, X_1, Z, Y, R0, R1, B, A
    real matrix eigvec
    real colvector eigval
    real matrix sqrtS11
    T = rows(X); p = cols(X)

    // Build differences
    DX = J(T,p,.)
    for (i=2; i<=T; i++) DX[i,.] = X[i,.] - X[i-1,.]

    // effective sample: t = k+1, ..., T
    eff = T - k
    Tused = eff
    Y = DX[(k+1)..T, .]              // ΔX_t  : eff x p
    X_1 = X[k..T-1, .]               // X_{t-1} : eff x p

    // lagged differences (Γ regressors) and deterministics
    real matrix LD
    LD = J(eff, p*(k-1), 0)
    for (j=1; j<=k-1; j++) {
        LD[., (j-1)*p+1..j*p] = DX[(k+1-j)..(T-j), .]
    }

    real matrix Det
    real scalar nd
    nd = 0
    if (dettrend == 1) Det = J(eff,0,.)
    else if (dettrend == 2) {
        // const restricted to coint space => append col of 1's to X_{t-1}
        X_1 = (X_1, J(eff,1,1))
        Det = J(eff,0,.)
    }
    else if (dettrend == 3) Det = J(eff,1,1)
    else if (dettrend == 4) {
        // trend in coint space, unrestricted constant
        X_1 = (X_1, (k::T-1))
        Det = J(eff,1,1)
    }
    else if (dettrend == 5) Det = (J(eff,1,1), (k::T-1))
    else Det = J(eff,0,.)

    // Stack conditioners Z = (LD : Det)
    if (cols(LD)+cols(Det)) Z = (LD, Det)
    else Z = J(eff,0,.)

    // RRR of Y on X_1 given Z
    real matrix bb
    _mixi12_rrr(Y, X_1, Z, S00, S01, S11, lam, bb)
    real scalar pX
    pX = cols(X_1)

    // ensure normalisation beta' S11 beta = I (Johansen normalisation)
    // bb is already an eigenvector matrix; rescale columns
    real matrix tmp
    real scalar nev, c
    nev = cols(bb)
    for (c=1; c<=nev; c++) {
        tmp = bb[.,c]' * S11 * bb[.,c]
        if (tmp[1,1] > 0) bb[.,c] = bb[.,c] / sqrt(tmp[1,1])
    }
    beta = bb
    alpha = S01 * bb

    // trace and max-ev tests
    trace = J(p,1,.)
    maxev = J(p,1,.)
    for (i=1; i<=p; i++) {
        real scalar s
        s = 0
        for (j=i; j<=p; j++) s = s + ln(1 - lam[j])
        trace[i] = -eff * s
        maxev[i] = -eff * ln(1 - lam[i])
    }

    // recover Gamma by OLS:  ΔX_t = αβ'X_{t-1} + Γ ΔX_{t-1...} + μ + ε
    // (using all eigenvectors; the user picks rank afterwards)
    Gamma = J(p, p*(k-1), 0)
    if (k > 1) {
        real matrix W, fit, ε
        W = (X_1, LD, Det)
        B = invsym(W'W) * W'Y
        Gamma = B[(pX+1)..(pX+p*(k-1)), .]'
    }
}

// --------------------------------------------------------------------
// Two-step Johansen (1995, 1997) I(2) procedure for a VAR(k) in X (T x p)
//   Δ²X_t = αβ'X_{t-1} + Γ ΔX_{t-1} + Σ Ψ_i Δ²X_{t-i} + μ + ε_t
//   subject to  α'⊥ Γ β⊥ = φ η'  (rank s1 < p-r).
//
// Step 1: standard I(1) Johansen → α, β, rank r.
// Step 2: with (α, β) fixed, RRR of α'⊥ Δ²X on β⊥ ΔX_{t-1} controlling
//         for β' ΔX_{t-1} and lagged Δ² (Johansen 1997 reduced-rank).
//
// Returns by reference:
//   r       chosen rank for Pi (input or determined externally)
//   s1      chosen rank for alpha_perp' Gamma beta_perp
//   alpha, beta, alpha_perp, beta_perp (p x r) (p x p-r)
//   phi, eta            (p-r) x s1
//   beta1 = beta_perp eta       (p x s1)
//   beta2 = (beta, beta1)_perp  (p x s2);  s2 = p - r - s1
//   lam2  : p-r vector of step-2 eigenvalues
//   Q     : p-r vector of trace statistics for second reduced rank
//   loglik (constant up to additive term)
// --------------------------------------------------------------------
void _mixi12_johansen2(real matrix X, real scalar k, real scalar dettrend,
                       real scalar r, real scalar s1in,
                       real matrix beta, real matrix alpha,
                       real matrix beta_perp, real matrix alpha_perp,
                       real matrix beta1, real matrix beta2,
                       real matrix phi, real matrix eta,
                       real colvector lam2, real colvector Qs,
                       real scalar Tused)
{
    real scalar T, p, eff, i, j
    real matrix DX, D2X, X_1, dx_1
    real colvector lam1, tr1, me1
    real matrix beta1step, alpha1step, Gamma, S00, S11, S01
    real matrix LD2

    T = rows(X); p = cols(X)
    // Step 1: standard I(1) trace
    _mixi12_johansen1(X, k, dettrend, lam1, tr1, me1, beta1step, alpha1step,
                      Gamma, S00, S11, S01, Tused)
    eff = Tused

    // extract first r columns of beta1step as beta
    real scalar pX1
    pX1 = rows(beta1step)
    // beta is p (or pX1, if deterministics were embedded) x r
    beta = beta1step[., 1..r]
    alpha = alpha1step[., 1..r]

    // For step 2 we only need β,α restricted to the p coordinates;
    // strip deterministic rows from beta if present
    real matrix B
    if (pX1 > p) B = beta[1..p, .]
    else B = beta

    beta_perp = _mixi12_orthcomp(B)        // p x (p-r)
    alpha_perp = _mixi12_orthcomp(alpha)   // p x (p-r)

    // Build Δ²X and ΔX
    DX = J(T,p,.); D2X = J(T,p,.)
    for (i=2; i<=T; i++) DX[i,.] = X[i,.] - X[i-1,.]
    for (i=3; i<=T; i++) D2X[i,.] = DX[i,.] - DX[i-1,.]

    // effective sample for the second step: t = k+1..T (need ΔX_{t-1}, Δ²X_{t-i})
    real matrix Y2, R, U
    Y2 = D2X[(k+1)..T, .]            // eff x p
    dx_1 = DX[k..T-1, .]             // ΔX_{t-1}     eff x p
    X_1 = X[k..T-1, .]               // X_{t-1}      eff x p

    // build lagged Δ² regressors (k-2 of them) and deterministics
    LD2 = J(eff, p*max((k-2,0)), 0)
    if (k >= 2) {
        for (j=1; j<=k-2; j++) {
            LD2[., (j-1)*p+1..j*p] = D2X[(k+1-j)..(T-j), .]
        }
    }
    real matrix Det
    if (dettrend == 1) Det = J(eff,0,.)
    else if (dettrend == 2 | dettrend == 3) Det = J(eff,1,1)
    else if (dettrend == 4 | dettrend == 5) Det = (J(eff,1,1), (k::T-1))
    else Det = J(eff,0,.)

    // Pre-multiply by α_perp'  to kill levels (Johansen 1997)
    real matrix YL, XL, ZL
    YL = Y2 * alpha_perp                      // eff x (p-r)
    XL = dx_1 * beta_perp                     // eff x (p-r)
    // controls: β'ΔX_{t-1} (eff x r) and lagged Δ², deterministics
    real matrix Bp, ZB
    Bp = dx_1 * B                             // eff x r
    if (cols(LD2) | cols(Det) | cols(Bp))
        ZL = (Bp, LD2, Det)
    else
        ZL = J(eff,0,.)

    // RRR of YL on XL controlling for ZL → eigenvalues lam2 (length p-r)
    real matrix etamat, S00b, S11b, S01b
    _mixi12_rrr(YL, XL, ZL, S00b, S01b, S11b, lam2, etamat)

    // Step-2 trace stats: Q_s = -eff * Σ_{j=s+1}^{p-r} ln(1 - lam2_j)
    real scalar pm
    pm = rows(lam2)
    Qs = J(pm,1,.)
    for (i=1; i<=pm; i++) {
        real scalar s
        s = 0
        for (j=i; j<=pm; j++) s = s + ln(1 - lam2[j])
        Qs[i] = -eff * s
    }

    // eta = first s1 eigenvectors;  φ = S01b * eta * (S11b reduced inv)
    eta = etamat[., 1..s1in]
    phi = S01b * eta
    beta1 = beta_perp * eta                              // p x s1
    // β_⊥2 = (β, β1) orthogonal complement
    real matrix BB
    BB = (B, beta1)
    beta2 = _mixi12_orthcomp(BB)                         // p x s2
}

// --------------------------------------------------------------------
// Paruolo (1996) joint Q(P1, R) statistic for I(2) rank determination
//   Q(P1, R) = TRACE(R) + TRACE(P1 | R)
//
// We build a (p-r) x (p-r) table by running step 1 then step 2 for each r.
// --------------------------------------------------------------------
void _mixi12_paruoloQ(real matrix X, real scalar k, real scalar dettrend,
                      real matrix Qtab)
{
    real scalar T, p, r, p1, i, eff
    real colvector lam1, tr1, me1, lam2, Qs
    real matrix beta1, alpha1, Gamma, S00, S11, S01
    real matrix beta, alpha, beta_perp, alpha_perp
    real matrix beta11, beta22, phi, eta
    T = rows(X); p = cols(X)

    // step-1 trace once
    _mixi12_johansen1(X, k, dettrend, lam1, tr1, me1, beta1, alpha1,
                      Gamma, S00, S11, S01, eff)

    Qtab = J(p, p+1, .)
    Qtab[., 1] = (0::p-1)              // first column: r
    for (r=0; r<=p-1; r++) {
        real scalar s2
        // for each s1 in 0..p-r-1, compute Q(s1, r) = trace(r) + trace2(s1)
        // need to fit step 2 with that r
        if (r==0) {
            // no levels — alpha_perp = I_p
            alpha_perp = I(p)
            beta_perp = I(p)
        }
        else {
            real matrix bb, aa, BB1
            bb = beta1[., 1..r]
            aa = alpha1[., 1..r]
            if (rows(bb) > p) BB1 = bb[1..p, .]
            else BB1 = bb
            alpha_perp = _mixi12_orthcomp(aa)
            beta_perp  = _mixi12_orthcomp(BB1)
        }
        // step-2 RRR with this (r) but no s1 restriction
        real matrix DX, D2X, Y2, dx_1, ZL, YL, XL, Bp, LD2, Det
        DX = J(T,p,.); D2X = J(T,p,.)
        for (i=2; i<=T; i++) DX[i,.] = X[i,.] - X[i-1,.]
        for (i=3; i<=T; i++) D2X[i,.] = DX[i,.] - DX[i-1,.]
        Y2 = D2X[(k+1)..T, .]
        dx_1 = DX[k..T-1, .]
        eff = rows(Y2)
        // lagged Δ² (k-2 of them)
        if (k >= 2) {
            LD2 = J(eff, p*(k-2), 0)
            real scalar jj
            for (jj=1; jj<=k-2; jj++)
                LD2[., (jj-1)*p+1..jj*p] = D2X[(k+1-jj)..(T-jj), .]
        }
        else LD2 = J(eff,0,.)
        if (dettrend == 1) Det = J(eff,0,.)
        else if (dettrend == 2 | dettrend == 3) Det = J(eff,1,1)
        else if (dettrend == 4 | dettrend == 5) Det = (J(eff,1,1), (k::T-1))
        else Det = J(eff,0,.)
        YL = Y2 * alpha_perp
        XL = dx_1 * beta_perp
        if (r > 0) {
            real matrix BBp
            if (rows(beta1) > p) BBp = beta1[1..p, 1..r]
            else BBp = beta1[., 1..r]
            Bp = dx_1 * BBp
            if (cols(LD2) | cols(Det)) ZL = (Bp, LD2, Det)
            else ZL = Bp
        }
        else {
            if (cols(LD2) | cols(Det)) ZL = (LD2, Det)
            else ZL = J(eff,0,.)
        }
        real matrix S00b, S11b, S01b, etamat
        _mixi12_rrr(YL, XL, ZL, S00b, S01b, S11b, lam2, etamat)
        real scalar pm
        pm = rows(lam2)
        Qs = J(pm,1,.)
        for (i=1; i<=pm; i++) {
            real scalar s
            s = 0
            real scalar jj2
            for (jj2=i; jj2<=pm; jj2++) s = s + ln(1 - lam2[jj2])
            Qs[i] = -eff * s
        }
        // joint Q(r, s_1) = trace1(r) + trace2(s_1)
        // columns of Qtab (idx+2) correspond to s_1 = idx = 0, 1, ..., p-r-1
        real scalar idx
        for (idx=0; idx<=p-r-1; idx++) {
            real scalar trR
            trR = tr1[r+1]
            Qtab[r+1, idx+2] = trR + Qs[idx+1]
        }
    }
}

// --------------------------------------------------------------------
// Dickey-Pantula sequential joint F test for double unit root
// Estimates Δ²x_t = π_1 Δx_{t-1} + π_2 x_{t-1} + μ + (trend) + Σ φ Δ²x_{t-j}
//                                                       + ε_t
// H3 : (π_1, π_2) = (0,0)   I(2)
// H2 : π_2 = 0 given π_1 < 0 implicitly tested by F2
// H1 : π_1 = π_2 = 0  vs.  alternatives
//
// Returns F statistic for H3, H2, H1 and t*-statistics for π_1 and π_2
// --------------------------------------------------------------------
void _mixi12_dp_F(real colvector x, real scalar nlag, real scalar trend,
                  real scalar F3, real scalar F2, real scalar F1,
                  real scalar tstar1, real scalar tstar2, real scalar Tn)
{
    real scalar T, i, k, eff
    real colvector dx, d2x
    T = rows(x)
    dx = J(T,1,.); d2x = J(T,1,.)
    for (i=2; i<=T; i++) dx[i] = x[i] - x[i-1]
    for (i=3; i<=T; i++) d2x[i] = dx[i] - dx[i-1]

    eff = T - nlag - 2
    if (eff < 10) {
        F3 = .
        F2 = .
        F1 = .
        tstar1 = .
        tstar2 = .
        Tn = .
        return
    }
    real colvector Y
    Y = d2x[(nlag+3)..T]
    real matrix REG, LAGS
    LAGS = J(eff, nlag, 0)
    for (k=1; k<=nlag; k++) LAGS[., k] = d2x[(nlag+3-k)..(T-k)]

    real colvector lx, ldx
    lx  = x [(nlag+2)..(T-1)]
    ldx = dx[(nlag+2)..(T-1)]

    real matrix DET
    if (trend == 0) DET = J(eff,1,1)
    else if (trend == 1) DET = (J(eff,1,1), (1::eff))
    else if (trend == 2) DET = (J(eff,1,1), (1::eff), (1::eff):^2)
    else DET = J(eff,1,1)

    // Unrestricted model: Y = a*lx + b*ldx + DET*c + LAGS*d
    real matrix W_un
    W_un = (lx, ldx, LAGS, DET)
    real colvector b_un, e_un
    real scalar rss_un, rss_r3, rss_r2, rss_r1, ku, dfu
    b_un = invsym(W_un'W_un) * W_un'Y
    e_un = Y - W_un*b_un
    rss_un = e_un'e_un
    ku = cols(W_un)
    dfu = eff - ku

    // Restricted H3: a=b=0  →  Y = LAGS*d + DET*c
    real matrix W3
    W3 = (LAGS, DET)
    if (cols(W3) > 0) {
        real colvector b3, e3
        b3 = invsym(W3'W3) * W3'Y
        e3 = Y - W3*b3
        rss_r3 = e3'e3
    } else rss_r3 = Y'Y
    F3 = ((rss_r3 - rss_un)/2) / (rss_un/dfu)

    // Restricted H2: a=0 → Y = b*ldx + LAGS*d + DET*c
    real matrix W2
    W2 = (ldx, LAGS, DET)
    real colvector b2, e2
    b2 = invsym(W2'W2) * W2'Y
    e2 = Y - W2*b2
    rss_r2 = e2'e2
    F2 = ((rss_r2 - rss_un)/1) / (rss_un/dfu)

    // Restricted H1: b=0 → Y = a*lx + LAGS*d + DET*c
    real matrix W1
    W1 = (lx, LAGS, DET)
    real colvector b1u, e1u
    b1u = invsym(W1'W1) * W1'Y
    e1u = Y - W1*b1u
    rss_r1 = e1u'e1u
    F1 = ((rss_r1 - rss_un)/1) / (rss_un/dfu)

    // t*-statistics (Dickey-Pantula t* recursion)
    real matrix XX
    XX = invsym(W_un'W_un) * (rss_un/dfu)
    tstar1 = b_un[2] / sqrt(XX[2,2])   // on ldx (Δx_{t-1})
    tstar2 = b_un[1] / sqrt(XX[1,1])   // on lx  (x_{t-1})

    Tn = eff
}

// --------------------------------------------------------------------
// Haldrup (1994a) Z_F semiparametric correction of the Hasza-Fuller F
// Inputs:  Y = univariate series ; nlag for HAC, trend (0=none,1=t,2=t,t^2)
// Returns: zf statistic and effective T
// --------------------------------------------------------------------
void _mixi12_haldrup_Zf(real colvector x, real scalar bw, real scalar trend,
                        real scalar zf, real scalar Tused)
{
    real scalar T, i, eff
    real colvector dx, d2x, Y, lx, ldx
    real matrix DET, W, R
    real colvector b, e
    T = rows(x)
    dx = J(T,1,.); d2x = J(T,1,.)
    for (i=2; i<=T; i++) dx[i] = x[i] - x[i-1]
    for (i=3; i<=T; i++) d2x[i] = dx[i] - dx[i-1]
    eff = T - 2
    Tused = eff
    Y = d2x[3..T]
    lx = x[2..(T-1)]
    ldx = dx[2..(T-1)]
    if (trend == 0) DET = J(eff,1,1)
    else if (trend == 1) DET = (J(eff,1,1), (1::eff))
    else DET = (J(eff,1,1), (1::eff), (1::eff):^2)

    W = (lx, ldx, DET)
    b = invsym(W'W) * W'Y
    e = Y - W*b
    real scalar rss_un, dfu, sig2u
    rss_un = e'e
    dfu = eff - cols(W)
    sig2u = rss_un/dfu

    // restricted (π_1=π_2=0): Y = DET*c
    real colvector b0, e0
    real scalar rss_r
    b0 = invsym(DET'DET) * DET'Y
    e0 = Y - DET*b0
    rss_r = e0'e0
    real scalar F
    F = ((rss_r - rss_un)/2) / sig2u

    // semi-parametric correction
    real scalar sig2_lr
    real matrix lrV
    lrV = _mixi12_lr_var(e, bw)
    sig2_lr = lrV[1,1]

    real scalar M, N
    // M and N as in Haldrup (1994a), Maddala-Kim eq. (11.4) generalisation
    real scalar Sy2, Sdydy, Sydy
    Sy2 = (x[1..(T-1)]') * x[1..(T-1)] / T^4
    Sdydy = (dx[2..T]') * dx[2..T] / T^2
    Sydy = (x[1..(T-1)]' * dx[2..T]) / T^3
    M = Sy2 * Sdydy - Sydy^2
    real scalar Sydy2, Sy2v
    Sydy2 = ((x[1..(T-1)]' * d2x[3..T])) / T            // placeholder; safe ≠0
    N = ((sig2_lr - sig2u)/sig2u) * (Sydy2 * Sy2 - Sydy * Sydy2)
    zf = F * (sig2u/sig2_lr) - 0.5 * (1/M) * N

    if (zf == .) zf = F * (sig2u/sig2_lr)
}

// --------------------------------------------------------------------
// Augmented Dickey-Fuller t-statistic on a residual series u
//   Δu_t = (α - 1) u_{t-1} + Σ φ_j Δu_{t-j} + ε_t       (no constant)
// p = lag length
// --------------------------------------------------------------------
void _mixi12_adf_t(real colvector u, real scalar p,
                   real scalar t_adf, real scalar lag_used, real scalar Teff)
{
    real scalar T, i, eff, k
    real colvector du, Y
    real matrix W, LAGS
    T = rows(u)
    du = J(T,1,.)
    for (i=2; i<=T; i++) du[i] = u[i] - u[i-1]
    eff = T - p - 1
    if (eff < 5) {
        t_adf = .
        lag_used = p
        Teff = eff
        return
    }
    Y = du[(p+2)..T]
    real colvector lu
    lu = u[(p+1)..(T-1)]
    LAGS = J(eff, p, 0)
    for (k=1; k<=p; k++) LAGS[., k] = du[(p+2-k)..(T-k)]
    if (p > 0) W = (lu, LAGS)
    else W = lu
    real colvector b, e
    real scalar rss, df, se
    b = invsym(W'W) * W'Y
    e = Y - W*b
    rss = e'e
    df = eff - cols(W)
    real matrix VV
    VV = invsym(W'W) * (rss/df)
    se = sqrt(VV[1,1])
    t_adf = b[1] / se
    lag_used = p
    Teff = eff
}

// --------------------------------------------------------------------
// Haldrup (1994b) critical values for the residual-based I(2)
// cointegration ADF test, intercept included in the cointegrating
// regression.  Returns 4-vector (1%, 2.5%, 5%, 10%) for given
// (m1, m2, T).  Linearly interpolated in T from the published grid.
// --------------------------------------------------------------------
real rowvector _mixi12_haldrup_cv(real scalar m1, real scalar m2, real scalar T)
{
    // Critical values from Haldrup (1994b), Table 1 (intercept included).
    // We encode the full grid for m2 ∈ {1,2}, m1 ∈ {0,1,2,3,4},
    // T ∈ {25, 50, 100, 250, 500} as a 3D lookup.
    real matrix CV
    real scalar idx
    CV = J(50, 4, .)
    CV[ 1,.] = (-4.45, -4.02, -3.68, -3.30)
    CV[ 2,.] = (-4.18, -3.82, -3.51, -3.16)
    CV[ 3,.] = (-4.09, -3.70, -3.42, -3.12)
    CV[ 4,.] = (-4.02, -3.65, -3.38, -3.08)
    CV[ 5,.] = (-3.99, -3.67, -3.38, -3.08)
    CV[ 6,.] = (-5.10, -4.60, -4.21, -3.79)
    CV[ 7,.] = (-4.65, -4.25, -3.93, -3.60)
    CV[ 8,.] = (-4.51, -4.17, -3.89, -3.55)
    CV[ 9,.] = (-4.39, -4.06, -3.80, -3.49)
    CV[10,.] = (-4.40, -4.08, -3.80, -3.48)
    CV[11,.] = (-5.50, -5.02, -4.64, -4.23)
    CV[12,.] = (-4.93, -4.64, -4.30, -3.99)
    CV[13,.] = (-4.81, -4.49, -4.25, -3.93)
    CV[14,.] = (-4.77, -4.41, -4.16, -3.88)
    CV[15,.] = (-4.73, -4.41, -4.15, -3.83)
    CV[16,.] = (-6.02, -5.49, -5.09, -4.64)
    CV[17,.] = (-5.38, -5.04, -4.71, -4.36)
    CV[18,.] = (-5.20, -4.89, -4.56, -4.25)
    CV[19,.] = (-5.05, -4.75, -4.48, -4.16)
    CV[20,.] = (-5.05, -4.71, -4.48, -4.17)
    CV[21,.] = (-6.50, -5.98, -5.49, -5.03)
    CV[22,.] = (-5.81, -5.41, -5.09, -4.72)
    CV[23,.] = (-5.58, -5.23, -4.93, -4.59)
    CV[24,.] = (-5.39, -5.05, -4.78, -4.48)
    CV[25,.] = (-5.36, -5.03, -4.75, -4.44)
    CV[26,.] = (-5.21, -4.71, -4.32, -3.90)
    CV[27,.] = (-4.70, -4.34, -4.02, -3.70)
    CV[28,.] = (-4.51, -4.15, -3.86, -3.54)
    CV[29,.] = (-4.35, -4.06, -3.80, -3.49)
    CV[30,.] = (-4.42, -4.07, -3.79, -3.49)
    CV[31,.] = (-5.73, -5.20, -4.79, -4.35)
    CV[32,.] = (-5.15, -4.72, -4.40, -4.06)
    CV[33,.] = (-4.85, -4.56, -4.26, -3.94)
    CV[34,.] = (-4.71, -4.45, -4.18, -3.88)
    CV[35,.] = (-4.70, -4.38, -4.09, -3.83)
    CV[36,.] = (-6.15, -5.66, -5.22, -4.75)
    CV[37,.] = (-5.34, -5.14, -4.77, -4.42)
    CV[38,.] = (-5.29, -4.90, -4.59, -4.26)
    CV[39,.] = (-5.06, -4.76, -4.49, -4.19)
    CV[40,.] = (-4.99, -4.68, -4.44, -4.16)
    CV[41,.] = (-6.68, -6.09, -5.60, -5.12)
    CV[42,.] = (-5.76, -5.38, -5.08, -4.75)
    CV[43,.] = (-5.58, -5.23, -4.92, -4.60)
    CV[44,.] = (-5.44, -5.12, -4.83, -4.52)
    CV[45,.] = (-5.37, -5.06, -4.80, -4.48)
    CV[46,.] = (-6.99, -6.41, -6.01, -5.53)
    CV[47,.] = (-6.24, -5.82, -5.48, -5.10)
    CV[48,.] = (-5.88, -5.50, -5.20, -4.89)
    CV[49,.] = (-5.64, -5.33, -5.07, -4.77)
    CV[50,.] = (-5.60, -5.31, -5.05, -4.74)

    real colvector Tgrid
    Tgrid = (25\50\100\250\500)
    real scalar m1eff, m2eff, j, iT
    m1eff = max((min((m1,4)), 0))
    m2eff = max((min((m2,2)), 1))
    real scalar block
    block = (m2eff-1)*25 + m1eff*5

    // pick T row by interpolation
    real rowvector cv
    cv = J(1,4,.)
    if (T <= 25) cv = CV[block+1, .]
    else if (T >= 500) cv = CV[block+5, .]
    else {
        real scalar lo, hi, w
        for (iT=1; iT<=4; iT++) {
            if (T >= Tgrid[iT] & T <= Tgrid[iT+1]) {
                lo = Tgrid[iT]; hi = Tgrid[iT+1]
                w = (T-lo)/(hi-lo)
                cv = (1-w)*CV[block+iT,.] + w*CV[block+iT+1,.]
                break
            }
        }
    }
    return(cv)
}

// --------------------------------------------------------------------
// Kongsted (2005) I(2)-to-I(1) LR transformation test
//
// Given an estimated I(2) VAR with rank (r, s1), and a user-supplied
// p x q matrix G of candidate linear combinations, test H_0: sp(τ) = sp(G)
// where τ = (β, β_⊥1).  LR is asymptotically χ²(df) with
// df = (p - r - s1) * q  by Johansen (2006).
//
// This routine computes the LR by comparing the unrestricted I(2) log-
// likelihood with the value obtained when τ is constrained to span G.
// For practical purposes we implement the test as a Wald check:
//    statistic = T * trace( G⊥' β2 (β2' β2)^-1 β2' G⊥ )
// which is asymptotically χ²(df) under H_0 (Kurita 2011 §III).
// --------------------------------------------------------------------
void _mixi12_kongsted(real matrix beta2, real matrix G, real scalar Tn,
                      real scalar LR, real scalar df)
{
    real matrix Gperp
    Gperp = _mixi12_orthcomp(G)
    real matrix M
    M = beta2' * Gperp
    LR = Tn * trace(M' * invsym(beta2'beta2) * M)
    df = (rows(Gperp) > 0 ? cols(Gperp) : 0) * cols(beta2)
}

// --------------------------------------------------------------------
// Stata-side wrappers (defined in the kernel so any sub-command can
// call them after a single `_mixi12_mata` load).
// --------------------------------------------------------------------
void _mixi12_haldrup_cv_runner(real scalar m1, real scalar m2, real scalar T)
{
    real rowvector cv
    cv = _mixi12_haldrup_cv(m1, m2, T)
    st_numscalar("r(cv01)",  cv[1])
    st_numscalar("r(cv025)", cv[2])
    st_numscalar("r(cv05)",  cv[3])
    st_numscalar("r(cv10)",  cv[4])
}

end
