*! _gvar_mata 1.0.1  21aug2026
*! The complete Mata computational engine of the gvar package.
*!
*! All Mata code lives in this single file so that the `struct gvarmodel`
*! definition is always compiled before the routines that use it.  Splitting it
*! across several ado-files makes the compile order depend on Stata's ado
*! loader, which is not reliable.
*!
*! Layers, in order:
*!   1  core      structures, weights, foreign variables, VECMX* ML,
*!                VARX* recovery, link matrices, stacking, solving
*!   2  test      unit roots, lag selection, diagnostics, stability
*!   3  dynamics  multipliers, IRF, FEVD, PP, HD, forecasts, TC, bootstrap
*!   4  io        the Stata interface and the model accessors
*!   5  cmd       helpers called directly by individual subcommands
*!
*! Author: Merwan Roudane
*! merwanroudane920@gmail.com
*! https://github.com/merwanroudane

* Dropped first so this file can be re-run.  Without it, reloading the engine
* -- which _gvar_engine does whenever the compiled version is not the one it
* expects -- fails with "program _gvar_mata already defined", r(110).
capture program drop _gvar_mata
program define _gvar_mata
    version 14.0
end

version 14.0

mata:

// ===========================================================================
// Engine marker -- _gvar_engine uses this to detect whether the Mata engine
// is already compiled in this session.
// ===========================================================================
string scalar gvar_version()
{
    return("1.0.1")
}



// =========================================================================
// =====  from _gvar_mata_core.ado                                          
// =========================================================================


// ===========================================================================
// 0.  The model state object
// ===========================================================================
// One instance lives in the external variable gvar_MODEL.  Every subcommand
// reads it; some extend it.  gvar save / gvar use serialise it.

struct gvarmodel {
    // ---- dimensions -------------------------------------------------------
    real scalar      N            // number of cross-section units
    real scalar      K            // total endogenous variables in x_t
    real scalar      V            // number of distinct domestic variable names
    real scalar      Traw         // periods in the estimation window
    real scalar      pmax         // GVAR lag order = max over units of (p_i,q_i)
    real scalar      ntypes       // number of weight-matrix types
    real scalar      nyears       // number of weight blocks (1 if fixed)

    // ---- identifiers ------------------------------------------------------
    string scalar    idvar, tvar
    real scalar      freq         // 1 annual, 4 quarterly, 12 monthly
    real colvector   tvals        // Traw x 1 values of the time variable
    string colvector cname, clong
    string colvector vname, vlong
    real colvector   vtype        // V x 1 weight-matrix type per variable

    // ---- specification flags (Toolbox dvflag / fvflag / gvflag) -----------
    real matrix      dflag        // N x V  1 = endogenous for that unit
    real matrix      fflag        // N x V  1 = foreign counterpart is weakly exog
    real matrix      gflag        // N x G  0 absent, 1 weakly exog, 2 endogenous
    string colvector gvname       // G x 1 global variable names
    real matrix      GDATA        // Traw x G global variable data
    real matrix      DATA0        // (N*Traw) x V untouched source block

    // ---- position bookkeeping for x_t -------------------------------------
    string colvector xname        // K x 1 variable name of each element
    string colvector xcname       // K x 1 unit name of each element
    real colvector   xunit        // K x 1 unit index of each element

    // ---- per-unit data ----------------------------------------------------
    pointer(real matrix)      colvector Yi     // Traw x k_i  domestic levels
    pointer(real matrix)      colvector Si     // Traw x ks_i weakly exogenous
    pointer(string colvector) colvector ylist
    pointer(string colvector) colvector slist
    pointer(real colvector)   colvector sglob  // ks_i x 1, 1 = unweighted global
    real colvector   ki, ksi
    real matrix      lagord       // N x 2 (p_i,q_i)
    real colvector   ecase        // N x 1 deterministic case 2/3/4
    real colvector   rnk          // N x 1 cointegrating rank

    // ---- weights -----------------------------------------------------------
    pointer(real matrix) matrix Wt        // ntypes x nyears
    pointer(real matrix) colvector Wsol   // ntypes x 1 used to solve
    real colvector   yrid                 // Traw x 1 index into 1..nyears
    real matrix      aggw                 // N x ntypes aggregation weights

    // ---- country-model estimates -------------------------------------------
    pointer(real matrix) colvector al, be, ben, Ps, ep, Om, ec
    pointer(real matrix) colvector sd, sdw, sdn
    pointer(real matrix) colvector rgr, dep
    real colvector   logl, aic, sbc

    // ---- VARX* representation ----------------------------------------------
    pointer(real colvector) colvector a0, a1
    pointer(real matrix)    colvector Th, L0, Lm, Wlink

    // ---- solved GVAR --------------------------------------------------------
    real matrix      X            // K x Traw global vector (columns = periods)
    real matrix      G0, Hs, Fs
    real colvector   d0, d1, h0, h1
    real matrix      zeta, eta, Szeta, Seta
    real colvector   eigmod

    // ---- aggregation --------------------------------------------------------
    real matrix      cw           // V x N country weights for global shocks
    string colvector rname        // R x 1 region names
    real matrix      rmemb        // N x R membership

    // ---- over-identifying restrictions on beta  (overid_restr.m) ---------
    pointer(real matrix) colvector betar   // N x 1, NULL where unrestricted
    real colvector   nunrestr              // N x 1 freely estimated per unit

    // ---- dominant unit / global exogenous model  (Toolbox section 7) -----
    // The block is NOT a unit: N stays the number of country models, because
    // every per-country loop in the package expects a beta, an alpha and a
    // residual matrix per index.  These fields are assembled into a
    // pseudo-unit only inside gvar_solvemodel.
    real colvector   dumark       // G x 1  1 = modelled by the dominant unit
    real colvector   duw          // N x 1  the entity's OWN weights, or empty
    real scalar      hasdu        // 1 once gvar dominant has estimated it
    real scalar      dulag, duqlag, ducase, duetype, durank, dunfb
    string colvector duylist      // gd x 1 names in the dominant block
    string colvector dufblist     // nfb x 1 feedback variable names
    real colvector   dua0, dua1
    real matrix      duTh, duL0, duLm
    real matrix      dubeta, dualpha, duPsi, dueps, duOm

    // ---- Bayesian posterior  (BGVAR BVAR_linear.cpp) ---------------------
    // Draws are kept per unit: the eigenvalue trim is a GLOBAL rule applied
    // after stacking, so a unit's draws cannot be discarded on their own.
    real scalar      hasbayes, bdraws, bburn, bthin, bprior, bsv
    real colvector   bfeig        // largest companion eigenvalue modulus, per draw
    pointer(real matrix) colvector bA, bL, bS, bG, bSV
    pointer(real matrix) colvector bY, bX

    // ---- flags ---------------------------------------------------------------
    real scalar      hasforeign, estimated, solved, hastrend
    string scalar    esttype      // "vecmx" | "varx" | "gvecm"
    real scalar      psc          // lag order of the serial-correlation F test
}

// ===========================================================================
// 1.  Small utilities  (Toolbox lagm.m, trimr.m, rows.m, cols.m, quantile.m)
// ===========================================================================

real matrix gvar_lagm(real matrix A, real scalar p)
{
    real scalar T, k
    real matrix B

    T = rows(A)
    k = cols(A)
    B = J(T, k, 0)
    if (p < T & k > 0) {
        B[(p+1)::T, .] = A[1::(T-p), .]
    }
    return(B)
}

real matrix gvar_trimr(real matrix x, real scalar k1, real scalar k2)
{
    real scalar k

    k = rows(x)
    if ((k1 + k2) >= k) {
        _error(3300, "gvar: estimation sample too short after trimming for lags")
    }
    return(x[(1+k1)::(k-k2), .])
}

real matrix gvar_diff(real matrix A)
{
    return(A :- gvar_lagm(A, 1))
}

// general inverse with a rank-deficiency fallback
real matrix gvar_inv(real matrix A)
{
    if (rows(A) == 0) {
        return(A)
    }
    if (rank(A) < rows(A)) {
        return(pinv(A))
    }
    return(luinv(A))
}

// symmetric inverse with a rank-deficiency fallback
real matrix gvar_sinv(real matrix A)
{
    if (rows(A) == 0) {
        return(A)
    }
    if (rank(A) < rows(A)) {
        return(pinv(A))
    }
    return(invsym(makesymmetric(A)))
}

// MATLAB's  A  and  A/B  on a symmetric moment matrix perform a Cholesky
// SOLVE, not an explicit inversion.  Every Toolbox routine that writes
// (X'X)\(X'y) or M02/M22 therefore maps to this, not to invsym().  The
// fallbacks mirror the Toolbox's own pattern of dropping to pinv() when the
// moment matrix is not positive definite (see kraplob.m, nyblom.m, schow.m).
real matrix gvar_msolve(real matrix A, real matrix B)
{
    real matrix X

    if (rows(A) == 0) {
        return(J(0, cols(B), 0))
    }
    X = cholsolve(A, B)
    if (hasmissing(X)) {
        X = lusolve(A, B)
    }
    if (hasmissing(X)) {
        X = pinv(A) * B
    }
    return(X)
}

// MATLAB's mrdivide:  A/B  ==  (B'\A')'
real matrix gvar_mrdiv(real matrix A, real matrix B)
{
    return(gvar_msolve(B', A')')
}

// Log-determinant of a positive-definite matrix, via the Cholesky factor.
//
// det() underflows to exactly zero for the residual covariance of even a
// modest system -- a 6-variable model with residual standard deviations of
// order 1e-3 gives |Sigma| ~ 1e-18, and 9 variables push it past the double
// precision floor.  ln|Sigma| = 2*sum(ln(diag(chol(Sigma)))) is computed in
// logs throughout and never underflows.
real scalar gvar_logdet(real matrix A)
{
    real matrix C

    if (rows(A) == 0) {
        return(0)
    }
    C = cholesky(makesymmetric(A))
    if (hasmissing(C)) {
        return(.)
    }
    if (min(diagonal(C)) <= 0) {
        return(.)
    }
    return(2 * colsum(ln(diagonal(C))))
}

// positive definiteness check (the Toolbox wraps chol() in try/catch)
//
// The eigenvalue test is not decoration; see gvar_ispdblock() for the case that
// forced it.  Mata's cholesky() returns a factor for matrices whose smallest
// eigenvalue is a small NEGATIVE number, so the Cholesky alone reports a
// singular covariance as positive definite and everything downstream proceeds
// on a factor that does not exist.
real scalar gvar_ispd(real matrix A)
{
    real matrix B, C
    real rowvector ev

    B = makesymmetric(A)
    C = cholesky(B)
    if (hasmissing(C)) {
        return(0)
    }
    if (min(diagonal(C)) <= 0) {
        return(0)
    }
    ev = symeigenvalues(B)
    if (hasmissing(ev)) {
        return(0)
    }
    if (min(ev) <= 1e-12 * max(ev)) {
        return(0)
    }
    return(1)
}

// empirical quantile with linear interpolation (Toolbox quantile.m)
real scalar gvar_quantile(real vector x, real scalar p)
{
    real colvector s
    real scalar n, h, lo, hi, g

    if (cols(x) > 1) {
        s = sort(x', 1)
    }
    else {
        s = sort(x, 1)
    }
    n = rows(s)
    if (n == 1) {
        return(s[1])
    }
    h  = (n - 1) * p + 1
    lo = floor(h)
    hi = ceil(h)
    if (lo < 1) {
        lo = 1
    }
    if (hi > n) {
        hi = n
    }
    g = h - lo
    return((1 - g) * s[lo] + g * s[hi])
}

// position of s in the string colvector v, 0 if absent
real scalar gvar_pos(string colvector v, string scalar s)
{
    real scalar i

    for (i = 1; i <= rows(v); i++) {
        if (v[i] == s) {
            return(i)
        }
    }
    return(0)
}

// descending sort of a row vector, returned as a column vector
real colvector gvar_sortd(real vector v)
{
    if (cols(v) > 1) {
        return(sort(v', -1))
    }
    return(sort(v, -1))
}

// ===========================================================================
// 2.  Weight matrices  (Toolbox weightmat.m, build_wmat.m)
// ===========================================================================

// From bilateral flows to weights whose COLUMNS sum to one, zero diagonal:
//     w_ij = f_ij / sum_{k != j} f_kj
real matrix gvar_weightmat(real matrix F)
{
    real scalar n, i, j, s
    real matrix W

    n = rows(F)
    W = J(n, n, 0)
    for (j = 1; j <= n; j++) {
        s = 0
        for (i = 1; i <= n; i++) {
            if (i != j) {
                if (F[i, j] < .) {
                    s = s + F[i, j]
                }
            }
        }
        if (s != 0) {
            for (i = 1; i <= n; i++) {
                if (i != j) {
                    if (F[i, j] < .) {
                        W[i, j] = F[i, j] / s
                    }
                }
            }
        }
    }
    return(W)
}

// Renormalise an existing weight matrix: zero diagonal, columns sum to one
real matrix gvar_wnorm(real matrix W0)
{
    real scalar n, j, s
    real matrix W

    W = W0
    n = cols(W)
    for (j = 1; j <= n; j++) {
        W[j, j] = 0
    }
    for (j = 1; j <= n; j++) {
        s = colsum(W[., j])
        if (s != 0) {
            W[., j] = W[., j] :/ s
        }
    }
    return(W)
}

// Equal weights, GVARX GVAR_Ft() null branch: w_ij = 1/(N-1)
real matrix gvar_wequal(real scalar n)
{
    real matrix W

    W = J(n, n, 1 / (n - 1))
    _diag(W, 0)
    return(W)
}

// ===========================================================================
// 3.  Foreign-specific variables  (Toolbox create_foreignvariables.m)
// ===========================================================================
// D is Traw x N holding one domestic variable across units, with a fully
// missing column where a unit does not have the variable.  The weight matrix
// rows of absent units are zeroed and the columns renormalised a SECOND time
// (see _INVENTORY.md trap 4).  Returns Traw x N of x*_it.

real matrix gvar_wsub(real matrix W, real colvector have)
{
    real scalar n, i, j, s
    real matrix Wx

    n  = rows(W)
    Wx = W
    for (i = 1; i <= n; i++) {
        if (have[i] == 0) {
            Wx[i, .] = J(1, n, 0)
        }
    }
    for (j = 1; j <= n; j++) {
        s = colsum(Wx[., j])
        if (s != 0) {
            Wx[., j] = Wx[., j] :/ s
        }
    }
    return(Wx)
}

real colvector gvar_havepat(real matrix D)
{
    real scalar n, i
    real colvector have

    n = cols(D)
    have = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        if (!hasmissing(D[., i])) {
            have[i] = 1
        }
    }
    return(have)
}

real matrix gvar_foreignvar(real matrix D, real matrix W)
{
    real scalar T, n, i
    real colvector have
    real matrix Wx, Db

    T    = rows(D)
    n    = cols(D)
    have = gvar_havepat(D)
    Wx   = gvar_wsub(W, have)
    Db   = D
    for (i = 1; i <= n; i++) {
        if (have[i] == 0) {
            Db[., i] = J(T, 1, 0)
        }
    }
    return(Db * Wx)
}

// Time-varying weights: yrid[t] selects the weight block for period t, as
// build_wmat.m does within each year of the estimation window.
real matrix gvar_foreignvar_tv(real matrix D,
                               pointer(real matrix) colvector Wlist,
                               real colvector yrid)
{
    real scalar T, n, t, i, ny, y
    real colvector have
    real matrix Db, FV
    pointer(real matrix) colvector Wx

    T    = rows(D)
    n    = cols(D)
    have = gvar_havepat(D)
    Db   = D
    for (i = 1; i <= n; i++) {
        if (have[i] == 0) {
            Db[., i] = J(T, 1, 0)
        }
    }
    ny = rows(Wlist)
    Wx = J(ny, 1, NULL)
    for (y = 1; y <= ny; y++) {
        Wx[y] = &(gvar_wsub(*Wlist[y], have))
    }
    FV = J(T, n, 0)
    for (t = 1; t <= T; t++) {
        FV[t, .] = Db[t, .] * (*Wx[yrid[t]])
    }
    return(FV)
}

// ===========================================================================
// 4.  The Z0 / Z1 / Z2 partition  (Toolbox mlcoint.m)
// ===========================================================================
//   case 2 : restricted intercept in the cointegration space -> Z1 = [1 , ...]
//   case 3 : unrestricted intercept in levels                -> Z2 = [1 , ...]
//   case 4 : unrestricted intercept, restricted trend        -> Z1 = [t-1, ...]
//                                                               Z2 = [1  , ...]
// Z2 ordering is [ det | Dx* (lq blocks) | Dx (lp-1 blocks) ], which is what
// gvar_vecx2varx() relies on (_INVENTORY.md trap 7).
// The blocks are returned transposed, as in the Toolbox.

void gvar_z_blocks(real matrix Y, real matrix S,
                   real scalar lp, real scalar lq,
                   real scalar maxlag, real scalar ecase,
                   real matrix Z0, real matrix Z1, real matrix Z2)
{
    real scalar i, T0, hasx
    real matrix DY, DS
    real colvector one, trend

    hasx = (cols(S) > 0)
    DY   = gvar_diff(Y)
    Z0   = DY

    if (hasx) {
        DS = gvar_diff(S)
        Z1 = gvar_lagm(Y, 1), gvar_lagm(S, 1)
        Z2 = DS
        if (lq != 1) {
            for (i = 1; i <= lq - 1; i++) {
                Z2 = Z2, gvar_lagm(DS, i)
            }
        }
        if (lp != 1) {
            for (i = 1; i <= lp - 1; i++) {
                Z2 = Z2, gvar_lagm(DY, i)
            }
        }
    }
    else {
        Z1 = gvar_lagm(Y, 1)
        Z2 = J(rows(Y), 0, 0)
        if (lp != 1) {
            for (i = 1; i <= lp - 1; i++) {
                Z2 = Z2, gvar_lagm(DY, i)
            }
        }
    }

    T0    = rows(Z1)
    trend = (1::T0)
    one   = J(T0, 1, 1)

    Z0    = gvar_trimr(Z0, maxlag, 0)
    Z1    = gvar_trimr(Z1, maxlag, 0)
    if (cols(Z2) > 0) {
        Z2 = gvar_trimr(Z2, maxlag, 0)
    }
    else {
        Z2 = J(rows(Z0), 0, 0)
    }
    trend = gvar_trimr(trend, maxlag, 0)
    one   = gvar_trimr(one, maxlag, 0)

    if (ecase == 4) {
        Z1 = (trend :- 1), Z1
        Z2 = one, Z2
    }
    if (ecase == 3) {
        Z2 = one, Z2
    }
    if (ecase == 2) {
        Z1 = one, Z1
    }

    Z0 = Z0'
    Z1 = Z1'
    Z2 = Z2'
}

// Concentrate Z2 out and return the moment matrices (Toolbox mlcoint.m)
void gvar_smoments(real matrix Z0, real matrix Z1, real matrix Z2,
                   real matrix S00, real matrix S01, real matrix S11,
                   real matrix M02, real matrix M12, real matrix M22)
{
    real scalar T
    real matrix R0, R1

    T = cols(Z0)

    if (rows(Z2) > 0) {
        M02 = (1 / T) * Z0 * Z2'
        M12 = (1 / T) * Z1 * Z2'
        M22 = (1 / T) * (Z2 * Z2')
        // Toolbox mlcoint.m:  R0 = Z0-((M02/M22)*Z2)
        R0  = Z0 - gvar_mrdiv(M02, M22) * Z2
        R1  = Z1 - gvar_mrdiv(M12, M22) * Z2
    }
    else {
        M02 = J(rows(Z0), 0, 0)
        M12 = J(rows(Z1), 0, 0)
        M22 = J(0, 0, 0)
        R0  = Z0
        R1  = Z1
    }

    S00 = (R0 * R0') / T
    S01 = (R0 * R1') / T
    S11 = (R1 * R1') / T
}

// ===========================================================================
// 5.  Cointegration test  (Toolbox cointegration_test.m)
// ===========================================================================

void gvar_cointtest(real matrix Y, real matrix S,
                    real scalar lp, real scalar lq,
                    real scalar maxlag, real scalar ecase,
                    real colvector lambda,
                    real colvector trace,
                    real colvector maxeig)
{
    real matrix Z0, Z1, Z2, S00, S01, S11, M02, M12, M22, A
    real scalar n, T, nq1, i, r
    real colvector lam, tmp

    gvar_z_blocks(Y, S, lp, lq, maxlag, ecase, Z0, Z1, Z2)
    gvar_smoments(Z0, Z1, Z2, S00, S01, S11, M02, M12, M22)

    n   = rows(Z0)
    T   = cols(Z0)
    nq1 = rows(Z1)

    A   = (gvar_sinv(S11) * S01') * (gvar_sinv(S00) * S01)
    lam = gvar_sortd(Re(eigenvalues(A)))

    if (n < nq1) {
        lam = lam[1::n]
    }
    lambda = lam

    tmp = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        if (lam[i] < 1 & lam[i] > -1) {
            tmp[i] = ln(1 - lam[i])
        }
    }

    trace  = J(n, 1, 0)
    maxeig = J(n, 1, 0)
    for (r = 1; r <= n; r++) {
        trace[r]  = -T * colsum(tmp[r::n])
        maxeig[r] = -T * tmp[r]
    }
}

// ===========================================================================
// 6.  Reduced-rank ML estimation of the VECMX*  (Toolbox mlcoint.m)
// ===========================================================================

void gvar_mlcoint(real matrix Y, real matrix S,
                  real scalar lp, real scalar lq,
                  real scalar maxlag, real scalar ecase, real scalar rk,
                  real matrix beta, real matrix alpha, real matrix Psi,
                  real matrix eps, real matrix Omega, real matrix ecm,
                  real matrix DX, real matrix dep,
                  real scalar logl, real scalar aic, real scalar sbc)
{
    real matrix Z0, Z1, Z2, S00, S01, S11, S10, M02, M12, M22
    real matrix Wv, Uv, sqS11, adjS11, Vv, rhoD
    real scalar n, T, nq1, s, i
    real rowvector rhor, lamr
    real colvector rho, lam, ord

    gvar_z_blocks(Y, S, lp, lq, maxlag, ecase, Z0, Z1, Z2)
    gvar_smoments(Z0, Z1, Z2, S00, S01, S11, M02, M12, M22)
    S10 = S01'

    n   = rows(Z0)
    T   = cols(Z0)
    nq1 = rows(Z1)

    // Step 1 -- diagonalise S11 and form S11^(-1/2)
    symeigensystem(makesymmetric(S11), Wv, rhor)
    rho  = rhor'
    ord  = order(abs(rho), -1)
    rho  = rho[ord]
    Wv   = Wv[., ord]
    rhoD = J(nq1, nq1, 0)
    for (i = 1; i <= nq1; i++) {
        if (rho[i] > 1e-14) {
            rhoD[i, i] = 1 / sqrt(rho[i])
        }
    }
    sqS11 = (Wv * rhoD) * Wv'

    // Step 2 -- symmetrised eigenvalue problem; V normalised so V'S11 V = I
    adjS11 = sqS11 * (S10 * gvar_sinv(S00)) * S01 * sqS11
    symeigensystem(makesymmetric(adjS11), Uv, lamr)
    lam = lamr'
    ord = order(abs(lam), -1)
    lam = abs(lam[ord])
    Uv  = Uv[., ord]
    Vv  = sqS11 * Uv
    if (n < nq1) {
        Vv = Vv[., 1::n]
    }

    if (rk > 0) {
        beta  = Vv[., 1::rk]
        alpha = (S01 * beta) * gvar_sinv(beta' * S11 * beta)
    }
    else {
        beta  = J(nq1, 0, 0)
        alpha = J(n, 0, 0)
    }

    if (rows(Z2) > 0) {
        // Toolbox mlcoint.m:  Psi = (M02/M22)-((alpha*beta'*M12)/M22)
        if (rk > 0) {
            Psi = gvar_mrdiv(M02, M22) - gvar_mrdiv(alpha * beta' * M12, M22)
            eps = Z0 - (alpha * beta' * Z1) - (Psi * Z2)
        }
        else {
            Psi = gvar_mrdiv(M02, M22)
            eps = Z0 - (Psi * Z2)
        }
    }
    else {
        Psi = J(n, 0, 0)
        if (rk > 0) {
            eps = Z0 - (alpha * beta' * Z1)
        }
        else {
            eps = Z0
        }
    }

    Omega = (1 / T) * (eps * eps')
    if (rk > 0) {
        ecm = beta' * Z1
        DX  = (ecm \ Z2)'
    }
    else {
        ecm = J(0, T, 0)
        DX  = Z2'
    }
    dep = Z0'
    s   = cols(DX)

    // ln|Omega| via the Cholesky factor: det(Omega) underflows to zero for
    // systems of even moderate size (see gvar_logdet)
    logl = (-T * (n / 2)) * (1 + ln(2 * pi())) - (T / 2) * gvar_logdet(Omega)
    aic  = logl - n * s
    sbc  = logl - (n * (s / 2)) * ln(T)
}

// Restricted version with beta imposed  (Toolbox mlcoint_r.m)
void gvar_mlcoint_r(real matrix Y, real matrix S,
                    real scalar lp, real scalar lq,
                    real scalar maxlag, real scalar ecase, real matrix beta_r,
                    real matrix alpha, real matrix Psi,
                    real matrix eps, real matrix Omega, real matrix ecm,
                    real matrix DX, real matrix dep,
                    real scalar logl, real scalar aic, real scalar sbc)
{
    real matrix Z0, Z1, Z2, S00, S01, S11, M02, M12, M22, beta
    real scalar n, T, s

    gvar_z_blocks(Y, S, lp, lq, maxlag, ecase, Z0, Z1, Z2)
    gvar_smoments(Z0, Z1, Z2, S00, S01, S11, M02, M12, M22)

    n = rows(Z0)
    T = cols(Z0)

    beta  = beta_r
    alpha = (S01 * beta) * gvar_sinv(beta' * S11 * beta)

    if (rows(Z2) > 0) {
        // Toolbox mlcoint_r.m:  Psi = (M02/M22)-((alpha*beta'*M12)/M22)
        Psi = gvar_mrdiv(M02, M22) - gvar_mrdiv(alpha * beta' * M12, M22)
        eps = Z0 - (alpha * beta' * Z1) - (Psi * Z2)
    }
    else {
        Psi = J(n, 0, 0)
        eps = Z0 - (alpha * beta' * Z1)
    }

    Omega = (1 / T) * (eps * eps')
    ecm   = beta' * Z1
    DX    = (ecm \ Z2)'
    dep   = Z0'
    s     = cols(DX)

    // ln|Omega| via the Cholesky factor: det(Omega) underflows to zero for
    // systems of even moderate size (see gvar_logdet)
    logl = (-T * (n / 2)) * (1 + ln(2 * pi())) - (T / 2) * gvar_logdet(Omega)
    aic  = logl - n * s
    sbc  = logl - (n * (s / 2)) * ln(T)
}

// ===========================================================================
// 7.  Standard errors  (Toolbox mlcoint.m tail, neweywest.m)
// ===========================================================================

real matrix gvar_se_ols(real matrix DX, real matrix resid)
{
    real scalar T, s, j, s2
    real matrix SE, XXi
    real colvector e

    T   = rows(DX)
    s   = cols(DX)
    SE  = J(cols(resid), s, 0)
    XXi = gvar_sinv(cross(DX, DX))
    for (j = 1; j <= cols(resid); j++) {
        e  = resid[., j]
        s2 = (1 / (T - s)) * (e' * e)
        SE[j, .] = sqrt(abs(diagonal(s2 * XXi)))'
    }
    return(SE)
}

// White HC with the Toolbox finite-sample factor T/(T-s)
real matrix gvar_se_white(real matrix DX, real matrix resid)
{
    real scalar T, s, j
    real matrix SE, XXi, meat, vc
    real colvector e

    T   = rows(DX)
    s   = cols(DX)
    SE  = J(cols(resid), s, 0)
    XXi = gvar_sinv(cross(DX, DX))
    for (j = 1; j <= cols(resid); j++) {
        e    = resid[., j]
        meat = cross(DX, e :^ 2, DX)
        vc   = (T / (T - s)) * (XXi * meat * XXi)
        SE[j, .] = sqrt(abs(diagonal(vc)))'
    }
    return(SE)
}

// Newey-West HAC  (Toolbox neweywest.m).  Bandwidth q = floor(4*(T/100)^(2/9)),
// Bartlett weights 1 - v/(q+1); the "meat" mirrors the Toolbox expression.
real matrix gvar_se_nw(real matrix DX, real matrix resid)
{
    real scalar T, s, j, v, q
    real matrix SE, XXi, cw, cwsum, vc, X1, X2
    real colvector e, e1, e2

    T   = rows(DX)
    s   = cols(DX)
    SE  = J(cols(resid), s, 0)
    XXi = gvar_sinv(cross(DX, DX))
    q   = floor(4 * (T / 100)^(2 / 9))
    if (q < 1) {
        q = 1
    }
    if (q > T - 1) {
        q = T - 1
    }

    for (j = 1; j <= cols(resid); j++) {
        e     = resid[., j]
        cwsum = J(s, s, 0)
        for (v = 1; v <= q; v++) {
            X1 = DX[(v+1)::T, .]
            X2 = DX[1::(T-v), .]
            e1 = e[(v+1)::T]
            e2 = e[1::(T-v)]
            cw = cross(X1, e1 :* e2, X2)
            cwsum = cwsum + (1 - (v / (q + 1))) * (cw + cw')
        }
        vc = (T / (T - s)) * (XXi * cross(DX, e :^ 2, DX) * XXi + XXi * cwsum * XXi)
        SE[j, .] = sqrt(abs(diagonal(vc)))'
    }
    return(SE)
}

// ===========================================================================
// 8.  VARX* recovery from the VECMX*  (Toolbox vecx2varx.m)
// ===========================================================================
//   Psi = [ det | Gamma*_1..Gamma*_lq (on Dx*) | Gamma_1..Gamma_{lp-1} (on Dx) ]
//   Phi_1   = I + Pi_x + Gamma_1
//   Phi_j   = -(Gamma_{j-1} - Gamma_j)      for j = 2 .. lp-1
//   Phi_lp  = -Gamma_{lp-1}
//   Lambda_0  = Gamma*_1
//   Lambda_j  = -Gamma*_j + Gamma*_{j+1}    for j = 2 .. lq-1
//   Lambda_lq = -Gamma*_lq
//   Lambda_1  = Pi_x* - (Lambda_0 + sum_{j>=2} Lambda_j)     [trap 8]

void gvar_vecx2varx(real scalar maxlag,
                    real scalar ki, real scalar ksi,
                    real scalar lp, real scalar lq,
                    real scalar ecase,
                    real matrix alpha, real matrix beta, real matrix Psi,
                    real colvector a0, real colvector a1,
                    real matrix Th, real matrix L0, real matrix Lm)
{
    real matrix Beta, Dco, Dend, Dfor, Pi, sumth, acc
    pointer(real matrix) colvector G, GS, PH, LA
    real scalar j, jj, k

    // ---- deterministics ----------------------------------------------------
    if (ecase == 4) {
        a0   = Psi[., 1]
        Dco  = Psi[., 2::cols(Psi)]
        a1   = alpha * beta[1, .]'
        Beta = beta[2::rows(beta), .]
    }
    if (ecase == 3) {
        a0   = Psi[., 1]
        Dco  = Psi[., 2::cols(Psi)]
        a1   = J(ki, 1, 0)
        Beta = beta
    }
    if (ecase == 2) {
        a0   = alpha * beta[1, .]'
        Dco  = Psi
        a1   = J(ki, 1, 0)
        Beta = beta[2::rows(beta), .]
    }

    Pi    = alpha * Beta'
    sumth = Pi[., 1::ki]

    // ---- endogenous block ---------------------------------------------------
    if (lp > 1) {
        Dend = Dco[., (cols(Dco) - (lp - 1) * ki + 1)::cols(Dco)]
    }
    else {
        Dend = J(ki, 0, 0)
    }

    G = J(lp, 1, NULL)
    for (j = 1; j <= lp - 1; j++) {
        k    = (j - 1) * ki + 1
        G[j] = &(Dend[., k::(k + ki - 1)])
    }

    PH = J(maxlag, 1, NULL)
    for (j = 1; j <= maxlag; j++) {
        PH[j] = &(J(ki, ki, 0))
    }

    if (lp == 1) {
        PH[1] = &(sumth + I(ki))
    }
    else if (lp == 2) {
        PH[2] = &(-(*G[1]))
        PH[1] = &(sumth + (*G[1]) + I(ki))
    }
    else {
        PH[lp] = &(-(*G[lp - 1]))
        for (j = 1; j <= lp - 2; j++) {
            jj     = lp - j
            PH[jj] = &(-((*G[jj - 1]) - (*G[jj])))
        }
        PH[1] = &(sumth + (*G[1]) + I(ki))
    }

    Th = J(ki, 0, 0)
    for (j = 1; j <= maxlag; j++) {
        Th = Th, (*PH[j])
    }

    // ---- weakly exogenous block ---------------------------------------------
    if (ksi == 0) {
        L0 = J(ki, 0, 0)
        Lm = J(ki, 0, 0)
        return
    }

    Dfor = Dco[., 1::(lq * ksi)]

    GS = J(lq, 1, NULL)
    for (j = 1; j <= lq; j++) {
        k     = (j - 1) * ksi + 1
        GS[j] = &(Dfor[., k::(k + ksi - 1)])
    }

    L0 = *GS[1]

    LA = J(maxlag, 1, NULL)
    for (j = 1; j <= maxlag; j++) {
        LA[j] = &(J(ki, ksi, 0))
    }

    if (lq >= 2) {
        LA[lq] = &(-(*GS[lq]))
        for (j = 1; j <= lq - 2; j++) {
            jj     = lq - j
            LA[jj] = &(-(*GS[jj]) + (*GS[jj + 1]))
        }
    }

    acc = L0
    for (j = 2; j <= maxlag; j++) {
        acc = acc + (*LA[j])
    }
    LA[1] = &(Pi[., (ki + 1)::cols(Pi)] - acc)

    Lm = J(ki, 0, 0)
    for (j = 1; j <= maxlag; j++) {
        Lm = Lm, (*LA[j])
    }
}

// ===========================================================================
// 9.  Link matrices  (Toolbox create_linkmatrices.m)
// ===========================================================================
// W_i is (k_i + ks_i) x K.  Top block selects the unit's own variables.  Each
// bottom row spreads weights over the units owning the matching variable and
// is renormalised to sum to one (trap 5).  A weakly exogenous GLOBAL variable
// gets an unweighted indicator row instead (sglob = 1).

real matrix gvar_linkmat(real scalar i, real scalar K,
                         real colvector ki,
                         string colvector xname, real colvector xunit,
                         string colvector ylist_i, string colvector slist_i,
                         real colvector sglob_i,
                         string colvector vname, real colvector vtype,
                         pointer(real matrix) colvector Wsol)
{
    real scalar kdom, kfor, j, m, c, offset, s, vt
    real matrix Wtop, Wbot, Wm

    kdom = rows(ylist_i)
    kfor = rows(slist_i)

    offset = 0
    for (c = 1; c <= i - 1; c++) {
        offset = offset + ki[c]
    }
    Wtop = J(kdom, offset, 0), I(kdom), J(kdom, K - kdom - offset, 0)

    if (kfor == 0) {
        return(Wtop)
    }

    Wbot = J(kfor, K, 0)
    for (j = 1; j <= kfor; j++) {
        if (sglob_i[j] == 1) {
            for (m = 1; m <= K; m++) {
                if (xname[m] == slist_i[j]) {
                    Wbot[j, m] = 1
                }
            }
        }
        else {
            vt = 1
            s  = gvar_pos(vname, slist_i[j])
            if (s > 0) {
                vt = vtype[s]
            }
            Wm = *Wsol[vt]
            for (m = 1; m <= K; m++) {
                if (xname[m] == slist_i[j]) {
                    Wbot[j, m] = Wm[xunit[m], i]
                }
            }
        }
    }
    for (j = 1; j <= kfor; j++) {
        s = rowsum(Wbot[j, .])
        if (s == 0) {
            // no trade weight reaches this variable -- e.g. a variable owned
            // by a single unit with which unit i records no trade.  Fall back
            // to an unweighted average over the units that do own it, so the
            // link-matrix row is never identically zero.
            for (m = 1; m <= K; m++) {
                if (xname[m] == slist_i[j]) {
                    Wbot[j, m] = 1
                }
            }
            s = rowsum(Wbot[j, .])
        }
        if (s != 0) {
            Wbot[j, .] = Wbot[j, .] :/ s
        }
    }

    return(Wtop \ Wbot)
}

// ===========================================================================
// 10.  Stacking and solving  (Toolbox solve_GVAR.m; BGVAR gvar_stacking.cpp)
// ===========================================================================
//   A_i  = [ I , -Lambda_i0 ]      G_0 = stack_i ( A_i W_i )
//   B_il = [ Phi_il , Lambda_il ]  H_l = stack_i ( B_il W_i )

void gvar_stack(real scalar N, real scalar K, real scalar maxlag,
                pointer(real matrix) colvector Wlink,
                pointer(real colvector) colvector a0,
                pointer(real colvector) colvector a1,
                pointer(real matrix) colvector Th,
                pointer(real matrix) colvector L0,
                pointer(real matrix) colvector Lm,
                real colvector ki, real colvector ksi,
                real matrix G0, real matrix Hs,
                real colvector h0, real colvector h1)
{
    real scalar i, j, c0, c1
    real matrix A, B, Hj

    G0 = J(0, K, 0)
    h0 = J(0, 1, 0)
    h1 = J(0, 1, 0)

    for (i = 1; i <= N; i++) {
        if (ksi[i] > 0) {
            A = I(ki[i]), (-(*L0[i]))
        }
        else {
            A = I(ki[i])
        }
        G0 = G0 \ (A * (*Wlink[i]))
        h0 = h0 \ (*a0[i])
        h1 = h1 \ (*a1[i])
    }

    Hs = J(K, 0, 0)
    for (j = 1; j <= maxlag; j++) {
        Hj = J(0, K, 0)
        for (i = 1; i <= N; i++) {
            c0 = (j - 1) * ki[i] + 1
            c1 = j * ki[i]
            if (ksi[i] > 0) {
                B = (*Th[i])[., c0::c1],
                    (*Lm[i])[., ((j-1)*ksi[i]+1)::(j*ksi[i])]
            }
            else {
                B = (*Th[i])[., c0::c1]
            }
            Hj = Hj \ (B * (*Wlink[i]))
        }
        Hs = Hs, Hj
    }
}

void gvar_reduce(real matrix X, real scalar maxlag,
                 real matrix G0, real matrix Hs,
                 real colvector h0, real colvector h1,
                 real matrix Fs, real colvector d0, real colvector d1,
                 real matrix zeta, real matrix eta,
                 real matrix Szeta, real matrix Seta)
{
    real scalar K, Traw, T, j
    real matrix acc, G0i, Xt
    real rowvector trend

    K    = rows(X)
    Traw = cols(X)
    T    = Traw - maxlag
    G0i  = gvar_inv(G0)

    trend = J(1, T, 0)
    for (j = 1; j <= T; j++) {
        trend[j] = maxlag + j - 1
    }

    Xt  = X[., (maxlag + 1)::Traw]
    acc = J(K, T, 0)
    for (j = 1; j <= maxlag; j++) {
        acc = acc + Hs[., ((j-1)*K+1)::(j*K)] * X[., (maxlag + 1 - j)::(Traw - j)]
    }

    zeta  = G0 * Xt - h0 * J(1, T, 1) - h1 * trend - acc
    Szeta = (zeta * zeta') / T

    d0 = G0i * h0
    d1 = G0i * h1

    Fs = J(K, 0, 0)
    for (j = 1; j <= maxlag; j++) {
        Fs = Fs, (G0i * Hs[., ((j-1)*K+1)::(j*K)])
    }

    eta  = G0i * zeta
    Seta = (eta * eta') / T
}

real matrix gvar_companion(real matrix Fs, real scalar K, real scalar maxlag)
{
    if (maxlag == 1) {
        return(Fs)
    }
    return(Fs \ (I(K * (maxlag - 1)), J(K * (maxlag - 1), K, 0)))
}

// ===========================================================================
// 11.  Covariance transformations
//      (Toolbox transform_varcov.m, ShrinkageCorrLstar.m)
// ===========================================================================

real matrix gvar_vcovtrans(real scalar meth, string scalar cexc,
                           real matrix Sig, string colvector xcname)
{
    real matrix V
    real scalar i, j

    if (meth == 1) {
        return(Sig)
    }
    V = Sig
    for (i = 1; i <= rows(Sig); i++) {
        for (j = 1; j <= cols(Sig); j++) {
            if (xcname[i] != xcname[j]) {
                if (meth == 2) {
                    V[i, j] = 0
                }
                if (meth == 3) {
                    if (xcname[i] != cexc & xcname[j] != cexc) {
                        V[i, j] = 0
                    }
                }
            }
        }
    }
    return(V)
}

// lam < 0 asks for the optimal shrinkage intensity to be computed internally
real matrix gvar_shrinkvcov(real matrix Sig, real scalar T, real scalar lam,
                            real scalar lamstar)
{
    real scalar n, i, j, num, den1, den2
    real matrix D, R, Ds, Rs
    real colvector vr, vm, vsq

    n = rows(Sig)
    D = diag(1 :/ sqrt(diagonal(Sig)))
    R = D * Sig * D

    vr = J(0, 1, 0)
    for (j = 1; j <= n; j++) {
        for (i = 1; i <= n; i++) {
            if (i != j) {
                vr = vr \ R[i, j]
            }
        }
    }
    vsq = vr :^ 2
    vm  = (vr :* (1 :- vsq)) / (2 * T)

    num  = colsum(vr :* (vr - vm))
    den1 = colsum(((1 :- vsq) :^ 2) / T)
    den2 = colsum((vr - vm) :^ 2)

    if (lam < 0) {
        lamstar = 1 - (num / (den1 + den2))
        if (lamstar < 0) {
            lamstar = 0
        }
        if (lamstar > 1) {
            lamstar = 1
        }
    }
    else {
        lamstar = lam
    }

    Rs = lamstar * I(n) + (1 - lamstar) * R
    Ds = diag(sqrt(diagonal(Sig)))
    return(Ds * Rs * Ds)
}

// ===========================================================================
// 12.  Average pairwise cross-section correlations
//      (Toolbox avgcorrs.m/corrmat.m; GVARX averageCORgvar; BGVAR avg.pair.cc)
// ===========================================================================

real colvector gvar_avgcorr(real matrix B)
{
    real scalar n, i
    real matrix C
    real colvector out

    n = cols(B)
    if (n < 2) {
        return(J(n, 1, .))
    }
    C   = correlation(B)
    out = J(n, 1, .)
    for (i = 1; i <= n; i++) {
        out[i] = (colsum(C[., i]) - 1) / (n - 1)
    }
    return(out)
}

// ===========================================================================
// 13.  Exact-identification normalisation of beta  (Toolbox gvar.m beta_norm)
// ===========================================================================

real matrix gvar_betanorm(real matrix beta, real scalar rk, real scalar ecase)
{
    real matrix blk

    if (rk == 0) {
        return(beta)
    }
    if (ecase == 4 | ecase == 2) {
        blk = beta[2::(rk + 1), 1::rk]
    }
    else {
        blk = beta[1::rk, 1::rk]
    }
    return(beta * gvar_inv(blk))
}


// =========================================================================
// =====  from _gvar_mata_test.ado                                          
// =========================================================================


// ===========================================================================
// 1.  Deterministic detrending  (Toolbox detrend.m)
// ===========================================================================
// d = 0 : regress on a constant
// d = 1 : regress on a constant and a linear trend

real colvector gvar_detrend(real colvector y, real scalar d)
{
    real scalar T
    real matrix X
    real colvector b

    T = rows(y)
    X = J(T, 1, 1)
    if (d == 1) {
        X = X, (1::T)
    }
    // Toolbox detrend.m:  b = (x'*x)\(x'*y)
    b = gvar_msolve(cross(X, X), cross(X, y))
    return(y - X * b)
}

// ===========================================================================
// 2.  Augmented Dickey-Fuller  (Toolbox adf.m)
// ===========================================================================
// d = 0 intercept only, d = 1 intercept and trend, p lagged changes.
// Returns (dfstat, aic, sbc, logl).  The p == 4 branch reproduces the
// Toolbox's one-observation trimming quirk exactly (_INVENTORY.md trap 1).

real rowvector gvar_adf(real colvector y, real scalar d, real scalar p)
{
    real scalar nobs, T, k, s, so, soms, dfstat, logl, aic, sbc
    real matrix z, XXi, vc
    real colvector dep, ch, b, res, one, trend

    nobs = rows(y)
    if ((nobs - 2 * p + 1) < 1) {
        return((., ., ., .))
    }

    dep = y[2::nobs] - y[1::(nobs-1)]
    z   = y[1::(nobs-1)]

    one = J(rows(z), 1, 1)
    if (d == 0) {
        z = z, one
    }
    if (d == 1) {
        trend = (1::rows(z))
        z = z, one, trend
    }

    ch = dep
    k  = 1
    while (k <= p) {
        z = z, gvar_lagm(ch, k)
        k = k + 1
    }

    if (p != 4) {
        z   = gvar_trimr(z, k - 1, 0)
        dep = gvar_trimr(dep, k - 1, 0)
    }
    else {
        z   = gvar_trimr(z, k - 2, 0)
        dep = gvar_trimr(dep, k - 2, 0)
        z[1, cols(z)] = z[2, cols(z)]
    }

    T = rows(dep)
    s = rank(z)
    if (T <= s) {
        return((., ., ., .))
    }

    XXi = gvar_sinv(cross(z, z))
    b   = XXi * cross(z, dep)
    res = dep - z * b

    so   = (res' * res) / (T - s)
    soms = (res' * res) / T
    vc   = so * XXi

    if (vc[1, 1] <= 0) {
        return((., ., ., .))
    }
    dfstat = b[1] / sqrt(vc[1, 1])

    logl = -(T / 2) * ((1 + ln(2 * pi())) + ln(soms))
    aic  = -2 * (logl / T) + 2 * (s / T)
    sbc  = -2 * (logl / T) + s * ln(T) / T

    return((dfstat, aic, sbc, logl))
}

// ===========================================================================
// 3.  Weighted-symmetric Dickey-Fuller  (Toolbox ws.m, Park-Fuller)
// ===========================================================================

real scalar gvar_ws(real colvector y, real scalar d, real scalar p)
{
    real scalar T, c, k, s1, i1, i2, q1, q2, Q, estvar, sum1q, sum2q
    real matrix zbs, zfs, As, sum1a, sum2a, indb, indf, Ainv
    real colvector x, Dx, w1, w1tr, xbs, w2, depf, bs, sum1b, sum2b, theta
    real colvector xksin1, xk
    real rowvector cf

    x = gvar_detrend(y, d)
    T = rows(x)

    c = 2
    if (d == 1) {
        c = 3
    }

    if (T - 2 * p - c <= 0) {
        return(.)
    }

    sum1a = J(p + 1, p + 1, 0)
    sum1b = J(p + 1, 1, 0)

    Dx  = gvar_trimr(x - gvar_lagm(x, 1), 1, 0)
    k   = 0
    zbs = gvar_trimr(gvar_lagm(x, 1), 1, 0)
    if (p > 0) {
        while (k < p) {
            k   = k + 1
            zbs = zbs, gvar_lagm(Dx, k)
        }
    }
    if (k > 0) {
        zbs = gvar_trimr(zbs, k, 0)
    }

    w1 = J(T, 1, 0)
    for (s1 = 1; s1 <= T; s1++) {
        if (s1 <= p + 1) {
            w1[s1] = 0
        }
        else if (s1 <= T - p) {
            w1[s1] = (s1 - p - 1) / (T - 2 * p)
        }
        else {
            w1[s1] = 1
        }
    }

    w1tr = gvar_trimr(w1, k + 1, 0)
    xbs  = gvar_trimr(x, k + 1, 0)

    for (i1 = 1; i1 <= rows(zbs); i1++) {
        sum1a = sum1a + w1tr[i1] * (zbs[i1, .]' * zbs[i1, .])
        sum1b = sum1b + w1tr[i1] * zbs[i1, .]' * xbs[i1]
    }

    w2    = gvar_trimr(w1, 1, p)
    sum2a = J(p + 1, p + 1, 0)
    sum2b = J(p + 1, 1, 0)

    k   = 0
    zfs = gvar_trimr(x, 1, 0)
    if (p > 0) {
        zfs = gvar_trimr(zfs, 0, p)
        while (k < p) {
            k      = k + 1
            xksin1 = gvar_trimr(x, k + 1, p - k)
            xk     = gvar_trimr(x, k, p - (k - 1))
            zfs    = zfs, (-(xksin1 - xk))
        }
    }
    depf = gvar_trimr(x, 0, k + 1)

    for (i2 = 1; i2 <= rows(zfs); i2++) {
        sum2a = sum2a + (1 - w2[i2]) * (zfs[i2, .]' * zfs[i2, .])
        sum2b = sum2b + (1 - w2[i2]) * zfs[i2, .]' * x[i2]
    }

    As    = sum1a + sum2a
    bs    = sum1b + sum2b
    theta = gvar_sinv(As) * bs

    sum1q = 0
    if (p > 0) {
        indb = xbs, zbs
        cf   = 1, (-theta')
    }
    else {
        indb = xbs, zbs[., 1]
        cf   = 1, (-theta[1])
    }
    for (q1 = 1; q1 <= rows(zbs); q1++) {
        sum1q = sum1q + w1tr[q1] * (cf * indb[q1, .]')^2
    }

    sum2q = 0
    if (p > 0) {
        indf = depf, zfs
        cf   = 1, (-theta[1]), (-theta[2::rows(theta)])'
    }
    else {
        indf = depf, zfs[., 1]
        cf   = 1, (-theta[1])
    }
    for (q2 = 1; q2 <= rows(zfs); q2++) {
        sum2q = sum2q + (1 - w2[q2]) * (cf * indf[q2, .]')^2
    }

    Q      = sum1q + sum2q
    Ainv   = gvar_sinv(As)
    estvar = (Q / (T - p - c)) * Ainv[1, 1]

    if (estvar <= 0) {
        return(.)
    }
    return((theta[1] - 1) / sqrt(estvar))
}

// ===========================================================================
// 4.  Additional unit-root tests (not in the three sources; standard practice)
// ===========================================================================

// Elliott-Rothenberg-Stock GLS-detrended ADF
real rowvector gvar_adfgls(real colvector y, real scalar d, real scalar p)
{
    real scalar T, cbar, abar, i, s, tstat
    real matrix Z, Za, XXi, zr
    real colvector ya, b, yd, dep, res, one, trend

    T = rows(y)
    if (d == 1) {
        cbar = -13.5
    }
    else {
        cbar = -7
    }
    abar = 1 + cbar / T

    one = J(T, 1, 1)
    if (d == 1) {
        Z = one, (1::T)
    }
    else {
        Z = one
    }

    ya = J(T, 1, 0)
    Za = J(T, cols(Z), 0)
    ya[1] = y[1]
    Za[1, .] = Z[1, .]
    for (i = 2; i <= T; i++) {
        ya[i] = y[i] - abar * y[i-1]
        Za[i, .] = Z[i, .] - abar * Z[i-1, .]
    }
    b  = gvar_sinv(cross(Za, Za)) * cross(Za, ya)
    yd = y - Z * b

    // ADF regression on the detrended series, no deterministics
    dep = yd[2::T] - yd[1::(T-1)]
    zr  = yd[1::(T-1)]
    for (i = 1; i <= p; i++) {
        zr = zr, gvar_lagm(dep, i)
    }
    if (p > 0) {
        zr  = gvar_trimr(zr, p, 0)
        dep = gvar_trimr(dep, p, 0)
    }
    s = rank(zr)
    if (rows(dep) <= s) {
        return((., .))
    }
    XXi = gvar_sinv(cross(zr, zr))
    b   = XXi * cross(zr, dep)
    res = dep - zr * b
    tstat = b[1] / sqrt(((res' * res) / (rows(dep) - s)) * XXi[1, 1])
    return((tstat, p))
}

// KPSS stationarity test with a Bartlett long-run variance
real rowvector gvar_kpss(real colvector y, real scalar d, real scalar l)
{
    real scalar T, i, v, s2, lm, g
    real colvector e, S

    T = rows(y)
    e = gvar_detrend(y, d)
    S = runningsum(e)

    s2 = (e' * e) / T
    for (v = 1; v <= l; v++) {
        g  = 0
        for (i = v + 1; i <= T; i++) {
            g = g + e[i] * e[i - v]
        }
        s2 = s2 + 2 * (1 - v / (l + 1)) * g / T
    }
    if (s2 <= 0) {
        return((., l))
    }
    lm = colsum(S :^ 2) / (T^2 * s2)
    return((lm, l))
}

// Phillips-Perron Z(t) and Z(rho)
real rowvector gvar_ppz(real colvector y, real scalar d, real scalar l)
{
    real scalar T, i, v, s2, g, lam, se, rho, tstat, zt, zrho, sig2
    real matrix X, XXi
    real colvector dep, res, b, one

    T   = rows(y)
    dep = y[2::T]
    one = J(T - 1, 1, 1)
    X   = y[1::(T-1)], one
    if (d == 1) {
        X = X, (1::(T-1))
    }
    XXi = gvar_sinv(cross(X, X))
    b   = XXi * cross(X, dep)
    res = dep - X * b
    sig2 = (res' * res) / (rows(dep) - cols(X))
    se   = sqrt(sig2 * XXi[1, 1])
    rho  = b[1]
    tstat = (rho - 1) / se

    s2 = (res' * res) / rows(dep)
    lam = s2
    for (v = 1; v <= l; v++) {
        g = 0
        for (i = v + 1; i <= rows(res); i++) {
            g = g + res[i] * res[i - v]
        }
        lam = lam + 2 * (1 - v / (l + 1)) * g / rows(res)
    }

    zt   = sqrt(s2 / lam) * tstat - ((lam - s2) / (2 * sqrt(lam))) *
           (rows(dep) * se / sqrt(s2 * rows(dep)))
    zrho = rows(dep) * (rho - 1) - (rows(dep)^2 * se^2 / (2 * s2)) * (lam - s2)
    return((zt, zrho, l))
}

// ===========================================================================
// 5.  Information criteria and lag selection
// ===========================================================================

// Toolbox AIC_SBC.m -- the DdPS *levels* form: LARGER is better
// (_INVENTORY.md trap 2).
real rowvector gvar_aicsbc(real matrix dep, real matrix X, real matrix bhat)
{
    real scalar T, s, m, logl, aic, sbc, dt
    real matrix res, Sigma

    T   = rows(X)
    s   = rank(X)
    m   = cols(dep)
    res = dep - X * bhat
    Sigma = (1 / T) * cross(res, res)
    dt  = gvar_logdet(Sigma)
    if (dt >= .) {
        return((., ., .))
    }
    logl = (-T * (m / 2)) * (1 + ln(2 * pi())) - (T / 2) * dt
    aic  = logl - m * s
    sbc  = logl - (m * (s / 2)) * ln(T)
    return((logl, aic, sbc))
}

// Toolbox Ftest_rsc.m -- F test for residual serial correlation.
// Returns (degfr, Fcrit95, F_1, ..., F_m).
real rowvector gvar_ftest_rsc(real matrix dep, real matrix X, real scalar psc)
{
    real scalar T, m, j, isc, chisq, degfr, Fcrit, kX
    real matrix w, XXi, wmw, wX
    real colvector y, A, res, wr
    real rowvector out

    T  = rows(X)
    m  = cols(dep)
    kX = rank(X)
    degfr = T - kX - psc
    out = J(1, m, .)

    if (psc <= 0 | degfr <= 0) {
        return((degfr, ., out))
    }

    XXi = gvar_sinv(cross(X, X))

    for (j = 1; j <= m; j++) {
        y   = dep[., j]
        // Toolbox Ftest_rsc.m:  Asc=(X'*X)\(X'*yidv)
        A   = gvar_msolve(cross(X, X), cross(X, y))
        res = y - X * A
        w   = J(T, psc, 0)
        for (isc = 1; isc <= psc; isc++) {
            w[., isc] = gvar_lagm(res, isc)
        }
        // w' M_X w  computed without forming the T x T annihilator
        wX  = cross(w, X)
        wmw = cross(w, w) - wX * XXi * wX'
        wr  = cross(w, res)
        chisq = T * ((wr' * gvar_sinv(wmw) * wr) / (res' * res))
        if (T - chisq != 0) {
            out[j] = ((T - kX - psc) / psc) * (chisq / (T - chisq))
        }
    }

    Fcrit = invF(psc, degfr, 0.95)
    return((degfr, Fcrit, out))
}

// Toolbox select_varxlag.m -- build the VARX*(lp,lq) with a constant AND a
// trend, estimate by OLS, return (logl, aic, sbc) and the serial-correlation F.
void gvar_varsel(real matrix endog, real matrix exog,
                 real scalar lp, real scalar lq,
                 real scalar maxlag, real scalar psc,
                 real rowvector las, real rowvector fsc)
{
    real scalar T, i
    real matrix xmat, dep, A
    real colvector one, trend

    T     = rows(endog)
    one   = J(T, 1, 1)
    trend = (1::T)
    xmat  = one, trend

    if (lp != 0) {
        for (i = 1; i <= lp; i++) {
            xmat = xmat, gvar_lagm(endog, i)
        }
    }
    if (cols(exog) > 0) {
        xmat = xmat, exog
        if (lq != 0) {
            for (i = 1; i <= lq; i++) {
                xmat = xmat, gvar_lagm(exog, i)
            }
        }
    }

    dep  = gvar_trimr(endog, maxlag, 0)
    xmat = gvar_trimr(xmat, maxlag, 0)

    // Toolbox select_varxlag.m:  A=(xmat'*xmat)\(xmat'*dep)
    A   = gvar_msolve(cross(xmat, xmat), cross(xmat, dep))
    las = gvar_aicsbc(dep, xmat, A)
    fsc = gvar_ftest_rsc(dep, xmat, psc)
}

// GVARX .VARselect -- the log-determinant form: SMALLER is better.
// Returns (AIC, HQ, SC, FPE) for the given lag order.
real rowvector gvar_varselect(real matrix y, real scalar p,
                              real scalar dettype, real matrix exog)
{
    real scalar T, K, i, ns, det1, nstar, sample
    real matrix X, dep, res, S
    real colvector one

    T = rows(y)
    K = cols(y)
    X = J(T, 0, 0)
    for (i = 1; i <= p; i++) {
        X = X, gvar_lagm(y, i)
    }
    one = J(T, 1, 1)
    if (dettype == 1) {
        X = X, one
    }
    if (dettype == 2) {
        X = X, (1::T)
    }
    if (dettype == 3) {
        X = X, one, (1::T)
    }
    if (cols(exog) > 0) {
        X = X, exog
    }

    dep = gvar_trimr(y, p, 0)
    X   = gvar_trimr(X, p, 0)
    sample = rows(dep)
    nstar  = cols(X)
    ns     = nstar - p * K

    res = dep - X * qrsolve(X, dep)
    S   = cross(res, res) / sample
    det1 = gvar_logdet(S)
    if (det1 >= .) {
        return((., ., ., .))
    }

    // det1 is already ln|S|; FPE needs the determinant itself, computed in
    // logs and exponentiated only at the end so it cannot underflow first
    return((det1 + (2 / sample) * (p * K^2 + K * ns),
            det1 + (2 * ln(ln(sample)) / sample) * (p * K^2 + K * ns),
            det1 + (ln(sample) / sample) * (p * K^2 + K * ns),
            exp(det1 + K * ln((sample + nstar) / (sample - nstar)))))
}

// ===========================================================================
// 6.  Weak exogeneity  (Toolbox test_weakexogeneity.m, select_lags_we.m)
// ===========================================================================
// For each weakly exogenous variable of unit i, regress its first difference
// on a constant, the ECM terms and lagged differences of the domestic and
// (other) foreign variables, and F-test that the ECM coefficients are zero.
// Returns (r, degfr, Fcrit, F_1, ..., F_ks).

real rowvector gvar_wetest(real matrix endog, real matrix exog,
                           real matrix exog2, real matrix ecm,
                           real scalar ls, real scalar ln_,
                           real scalar rk, real scalar conf)
{
    real scalar lagtrim, discr, j, kX, T, restr, degfr, Fcrit
    real matrix dep, ch1, ch2, c1b, c2b, ec, X, Xr, one
    real colvector Y, A, u, Ar, ur
    real rowvector Fst
    real scalar i, ssru, ssrr

    dep = gvar_diff(exog)
    dep = dep[2::rows(dep), .]

    ch1 = gvar_diff(endog)
    ch1 = ch1[2::rows(ch1), .]
    c1b = J(rows(ch1), 0, 0)
    for (i = 1; i <= ls; i++) {
        c1b = c1b, gvar_lagm(ch1, i)
    }

    c2b = J(rows(ch1), 0, 0)
    if (cols(exog2) > 0) {
        ch2 = gvar_diff(exog2)
        ch2 = ch2[2::rows(ch2), .]
        for (i = 1; i <= ln_; i++) {
            c2b = c2b, gvar_lagm(ch2, i)
        }
    }

    lagtrim = max((ls, ln_))
    if (cols(c1b) > 0) {
        c1b = gvar_trimr(c1b, lagtrim, 0)
    }
    if (cols(c2b) > 0) {
        c2b = gvar_trimr(c2b, lagtrim, 0)
    }
    dep = gvar_trimr(dep, lagtrim, 0)

    ec = ecm'
    if (lagtrim > 0) {
        ec = gvar_trimr(ec, lagtrim, 0)
    }

    discr = rows(dep) - rows(ec)
    if (discr > 0) {
        if (cols(c1b) > 0) {
            c1b = gvar_trimr(c1b, discr, 0)
        }
        if (cols(c2b) > 0) {
            c2b = gvar_trimr(c2b, discr, 0)
        }
        dep = gvar_trimr(dep, discr, 0)
    }
    if (discr < 0) {
        ec = gvar_trimr(ec, -discr, 0)
    }

    one = J(rows(dep), 1, 1)
    X   = one, ec, c1b, c2b
    Xr  = one, c1b, c2b

    T     = rows(dep)
    kX    = cols(X)
    restr = rk
    degfr = T - kX
    Fst   = J(1, cols(dep), .)

    if (restr <= 0 | degfr <= 0) {
        return((restr, degfr, ., Fst))
    }

    for (j = 1; j <= cols(dep); j++) {
        Y  = dep[., j]
        // Toolbox test_weakexogeneity.m:  A=(X'*X)\(X'*Y)
        A  = gvar_msolve(cross(X, X), cross(X, Y))
        u  = Y - X * A
        Ar = gvar_msolve(cross(Xr, Xr), cross(Xr, Y))
        ur = Y - Xr * Ar
        ssru = u' * u
        ssrr = ur' * ur
        if (ssru > 0) {
            Fst[j] = ((ssrr - ssru) / restr) / (ssru / degfr)
        }
    }

    // the level is an argument, not 0.95: gvar wetest declared level() and
    // then ignored it, so the option was a promise the code did not keep
    Fcrit = invF(restr, degfr, conf)
    return((restr, degfr, Fcrit, Fst))
}

// Lag-order criteria for the weak-exogeneity marginal model
// (Toolbox select_lags_we.m).  Returns (logl, aic, sbc, degfr, Fcrit, F...).
real rowvector gvar_selwe(real matrix endog, real matrix exog,
                          real matrix exog2, real matrix ecm,
                          real scalar ls, real scalar ln_, real scalar psc)
{
    real scalar lagtrim, discr, i
    real matrix dep, ch1, ch2, c1b, c2b, ec, X, bhat
    real colvector one
    real rowvector las, fsc

    dep = gvar_diff(exog)
    dep = dep[2::rows(dep), .]

    ch1 = gvar_diff(endog)
    ch1 = ch1[2::rows(ch1), .]
    c1b = J(rows(ch1), 0, 0)
    for (i = 1; i <= ls; i++) {
        c1b = c1b, gvar_lagm(ch1, i)
    }

    c2b = J(rows(ch1), 0, 0)
    if (cols(exog2) > 0) {
        ch2 = gvar_diff(exog2)
        ch2 = ch2[2::rows(ch2), .]
        for (i = 1; i <= ln_; i++) {
            c2b = c2b, gvar_lagm(ch2, i)
        }
    }

    lagtrim = max((ls, ln_))
    if (cols(c1b) > 0) {
        c1b = gvar_trimr(c1b, lagtrim, 0)
    }
    if (cols(c2b) > 0) {
        c2b = gvar_trimr(c2b, lagtrim, 0)
    }
    dep = gvar_trimr(dep, lagtrim, 0)

    ec = ecm'
    if (lagtrim > 0) {
        ec = gvar_trimr(ec, lagtrim, 0)
    }
    discr = rows(dep) - rows(ec)
    if (discr > 0) {
        if (cols(c1b) > 0) {
            c1b = gvar_trimr(c1b, discr, 0)
        }
        if (cols(c2b) > 0) {
            c2b = gvar_trimr(c2b, discr, 0)
        }
        dep = gvar_trimr(dep, discr, 0)
    }
    if (discr < 0) {
        ec = gvar_trimr(ec, -discr, 0)
    }

    one  = J(rows(dep), 1, 1)
    X    = one, ec, c1b, c2b
    // Toolbox select_lags_we.m:  bhat = (X'*X)\(X'*dep)
    bhat = gvar_msolve(cross(X, X), cross(X, dep))
    las  = gvar_aicsbc(dep, X, bhat)
    fsc  = gvar_ftest_rsc(dep, X, psc)
    return((las, fsc))
}

// ===========================================================================
// 7.  Structural stability battery
// ===========================================================================

// Ploberger-Kramer maximal OLS-CUSUM and its mean-square variant
// (Toolbox kraplob.m).  Returns (PKsup, PKmsq).
real rowvector gvar_kraplob(real colvector y, real matrix x)
{
    real scalar vcv, m1, m2, T, kx
    real colvector ehat, t1, t2
    real matrix XXi

    T   = rows(y)
    kx  = cols(x)
    XXi = gvar_sinv(cross(x, x))
    // Toolbox kraplob.m uses an EXPLICIT inverse with a pinv fallback
    ehat = y - x * (XXi * cross(x, y))
    vcv  = (ehat' * ehat) / (T - kx)
    if (vcv <= 0) {
        return((., .))
    }
    t1 = runningsum(ehat / sqrt(T * vcv))
    m1 = max(abs(t1))
    t2 = t1 :* t1
    m2 = mean(t2)
    return((m1, m2))
}

// Nyblom (1989) LM test and its heteroskedasticity-robust version
// (Toolbox nyblom.m).  Returns (Ny, RobNy).
real rowvector gvar_nyblom(real colvector y, real matrix z)
{
    real scalar k, seesq, lm, rlm, T
    real matrix mzinv, ex, exs, v, rv, v1, v2
    real colvector e
    real scalar j

    T = rows(y)
    k = cols(z)
    mzinv = gvar_sinv(cross(z, z))
    // Toolbox nyblom.m uses an EXPLICIT inverse with a pinv fallback
    e = y - z * (mzinv * cross(z, y))
    seesq = (e' * e) / (T - k)

    ex = J(T, k, 0)
    for (j = 1; j <= k; j++) {
        ex[., j] = z[., j] :* e
    }
    exs = J(T, k, 0)
    for (j = 1; j <= k; j++) {
        exs[., j] = runningsum(ex[., j])
    }

    v  = seesq * cross(z, z)
    rv = cross(ex, ex)
    v1 = gvar_sinv(v)
    v2 = gvar_sinv(rv)

    lm  = sum(diagonal((v1 * cross(exs, exs)) / T))
    rlm = sum(diagonal((v2 * cross(exs, exs)) / T))
    return((lm, rlm))
}

// Sequential Chow tests: Quandt LR (sup-F), Mean-F, Andrews-Ploberger exp-F
// and the heteroskedasticity-robust versions  (Toolbox schow.m).
// Returns (supF, meanF, apF, rSupF, rMeanF, rApF, breakobs).
real rowvector gvar_schow(real colvector y, real matrix x, real scalar ccut)
{
    real scalar nobs, ktrim, n1t, n2t, i, j, ss0, yy, cx
    real matrix xx, xe, xxee, x1x1, xxee1, x2x2, xxee2, v, v1
    real matrix x1x1i, x2x2i, lr
    real colvector xy, x1y, x2y, e0, b1, b2, dif
    real scalar yy1, yy2, ssb, supF, meanF, apF, rsup, rmean, rap, mo
    real colvector lr1, lr2, wpos

    nobs  = rows(y)
    cx    = cols(x)
    ktrim = floor(ccut * nobs)
    if (ktrim < cx + 2) {
        ktrim = cx + 2
    }
    n1t = ktrim
    n2t = nobs - ktrim
    if (n2t <= n1t) {
        return((., ., ., ., ., ., .))
    }

    lr = J(n2t - n1t + 1, 2, 0)

    xy = cross(x, y)
    xx = cross(x, x)
    yy = y' * y

    if (gvar_ispd(xx)) {
        e0 = y - x * (invsym(makesymmetric(xx)) * xy)
    }
    else {
        e0 = y - x * (pinv(xx) * xy)
    }
    ss0 = e0' * e0

    xe = J(nobs, cx, 0)
    for (j = 1; j <= cx; j++) {
        xe[., j] = x[., j] :* e0
    }
    xxee = cross(xe, xe)

    x1y   = cross(x[1::(n1t-1), .], y[1::(n1t-1)])
    x1x1  = cross(x[1::(n1t-1), .], x[1::(n1t-1), .])
    xxee1 = cross(xe[1::(n1t-1), .], xe[1::(n1t-1), .])
    yy1   = y[1::(n1t-1)]' * y[1::(n1t-1)]

    for (i = n1t; i <= n2t; i++) {
        x1y   = x1y   + x[i, .]' * y[i]
        x1x1  = x1x1  + x[i, .]' * x[i, .]
        xxee1 = xxee1 + xe[i, .]' * xe[i, .]
        yy1   = yy1   + y[i] * y[i]
        x2x2  = xx - x1x1
        x2y   = xy - x1y
        yy2   = yy - yy1
        xxee2 = xxee - xxee1

        x1x1i = gvar_sinv(x1x1)
        x2x2i = gvar_sinv(x2x2)

        b1 = x1x1i * x1y
        b2 = x2x2i * x2y

        ssb = (yy1 - x1y' * b1) + (yy2 - x2y' * b2)
        if (ssb > 0) {
            lr[i - n1t + 1, 1] = (nobs - 2 * cx) * ((ss0 - ssb) / ssb)
        }

        v   = x1x1i * xxee1 * x1x1i + x2x2i * xxee2 * x2x2i
        v1  = gvar_sinv(v)
        dif = b1 - b2
        lr[i - n1t + 1, 2] = dif' * v1 * dif
    }

    lr1 = lr[., 1]
    lr2 = lr[., 2]

    supF  = max(lr1)
    // Mata cannot subscript a function result inline -- assign first
    wpos  = select((1::rows(lr1)), lr1 :== supF)
    mo    = n1t + wpos[1] - 1
    meanF = mean(lr1)
    apF   = ln(mean(exp(0.5 :* lr1)))

    rsup  = max(lr2)
    rmean = mean(lr2)
    rap   = ln(mean(exp(0.5 :* lr2)))

    return((supF, meanF, apF, rsup, rmean, rap, mo))
}

// ---------------------------------------------------------------------------
// The same two tests, returning the recursive PATH rather than the summary
// statistic.  The arithmetic is identical to gvar_kraplob and gvar_schow
// above -- these exist only so that -gvar stability, graph- can draw what the
// statistic is a maximum or a mean OF.  Any change to the tests must be made
// in both places; _regress.do checks that max|path| reproduces the statistic.
// ---------------------------------------------------------------------------

// t1 = cumsum(ehat / sqrt(T * vcv))  (Toolbox kraplob.m line 30).
// PKsup is max|t1| and PKmsq is mean(t1^2).
real colvector gvar_kraplobpath(real colvector y, real matrix x)
{
    real scalar vcv, T, kx
    real colvector ehat
    real matrix XXi

    T   = rows(y)
    kx  = cols(x)
    XXi = gvar_sinv(cross(x, x))
    ehat = y - x * (XXi * cross(x, y))
    vcv  = (ehat' * ehat) / (T - kx)
    if (vcv <= 0) {
        return(J(0, 1, .))
    }
    return(runningsum(ehat / sqrt(T * vcv)))
}

// The sequential Chow F paths (Toolbox schow.m lines 112 and 131), returned
// as (break observation, lr1, lr2) so the horizontal axis is in the model's
// own time index.  QLR is max of column 2, robust QLR the max of column 3.
real matrix gvar_schowpath(real colvector y, real matrix x, real scalar ccut)
{
    real scalar nobs, ktrim, n1t, n2t, i, j, ss0, yy, cx
    real matrix xx, xe, xxee, x1x1, xxee1, x2x2, xxee2, v, v1
    real matrix x1x1i, x2x2i, lr
    real colvector xy, x1y, x2y, e0, b1, b2, dif
    real scalar yy1, yy2, ssb

    nobs  = rows(y)
    cx    = cols(x)
    ktrim = floor(ccut * nobs)
    if (ktrim < cx + 2) {
        ktrim = cx + 2
    }
    n1t = ktrim
    n2t = nobs - ktrim
    if (n2t <= n1t) {
        return(J(0, 3, .))
    }

    lr = J(n2t - n1t + 1, 3, 0)

    xy = cross(x, y)
    xx = cross(x, x)
    yy = y' * y

    if (gvar_ispd(xx)) {
        e0 = y - x * (invsym(makesymmetric(xx)) * xy)
    }
    else {
        e0 = y - x * (pinv(xx) * xy)
    }
    ss0 = e0' * e0

    xe = J(nobs, cx, 0)
    for (j = 1; j <= cx; j++) {
        xe[., j] = x[., j] :* e0
    }
    xxee = cross(xe, xe)

    x1y   = cross(x[1::(n1t-1), .], y[1::(n1t-1)])
    x1x1  = cross(x[1::(n1t-1), .], x[1::(n1t-1), .])
    xxee1 = cross(xe[1::(n1t-1), .], xe[1::(n1t-1), .])
    yy1   = y[1::(n1t-1)]' * y[1::(n1t-1)]

    for (i = n1t; i <= n2t; i++) {
        x1y   = x1y   + x[i, .]' * y[i]
        x1x1  = x1x1  + x[i, .]' * x[i, .]
        xxee1 = xxee1 + xe[i, .]' * xe[i, .]
        yy1   = yy1   + y[i] * y[i]
        x2x2  = xx - x1x1
        x2y   = xy - x1y
        yy2   = yy - yy1
        xxee2 = xxee - xxee1

        x1x1i = gvar_sinv(x1x1)
        x2x2i = gvar_sinv(x2x2)

        b1 = x1x1i * x1y
        b2 = x2x2i * x2y

        ssb = (yy1 - x1y' * b1) + (yy2 - x2y' * b2)

        lr[i - n1t + 1, 1] = i
        if (ssb > 0) {
            lr[i - n1t + 1, 2] = (nobs - 2 * cx) * ((ss0 - ssb) / ssb)
        }

        v   = x1x1i * xxee1 * x1x1i + x2x2i * xxee2 * x2x2i
        v1  = gvar_sinv(v)
        dif = b1 - b2
        lr[i - n1t + 1, 3] = dif' * v1 * dif
    }
    return(lr)
}

// ---------------------------------------------------------------------------
// Critical-value tables transcribed from strucchange 1.6-0.
//
//   gvar_scme()  is sc.me from R/critvals.R, the Brownian-bridge-increments
//                table used by OLS-MOSUM, ME and Score-MOSUM.  60 x 4: ten
//                window fractions h = 0.05(0.05)0.50 for each of k = 1..6
//                parameters, against p = 0.10, 0.05, 0.025, 0.01.  R stores
//                it column-major with dim c(60,4); it is written out here
//                row by row.
//
//   gvar_scchk() is the Brownian-motion-increments table written inline in
//                R/efp.R, which is Table 1 of Chu, Hornik & Kuan (1995),
//                used by Rec-MOSUM.  10 x 6: h = 0.05(0.05)0.50 against
//                p = 0.20, 0.15, 0.10, 0.05, 0.025, 0.01.  efp.R rescales
//                it by sqrt(h) because its statistic is scaled
//                differently, and that rescaling is applied here too.
//
// Both are filled a row at a time: a single matrix literal with 240 numbers
// exceeds what Mata will accept in one statement.
// ---------------------------------------------------------------------------
real matrix gvar_scme()
{
    real matrix T

    T = J(60, 4, .)
    T[ 1, .] = (0.7552, 0.8017, 0.8444, 0.8977)
    T[ 2, .] = (0.9809, 1.0483, 1.1119, 1.1888)
    T[ 3, .] = (1.1211, 1.2059, 1.2845, 1.3767)
    T[ 4, .] = (1.217, 1.3158, 1.4053, 1.5131)
    T[ 5, .] = (1.2811, 1.392, 1.4917, 1.6118)
    T[ 6, .] = (1.3258, 1.4448, 1.5548, 1.6863)
    T[ 7, .] = (1.3514, 1.4789, 1.5946, 1.7339)
    T[ 8, .] = (1.3628, 1.4956, 1.6152, 1.7572)
    T[ 9, .] = (1.361, 1.4976, 1.621, 1.7676)
    T[10, .] = (1.3751, 1.5115, 1.6341, 1.7808)
    T[11, .] = (0.7997, 0.8431, 0.8838, 0.9351)
    T[12, .] = (1.0448, 1.1067, 1.1654, 1.2388)
    T[13, .] = (1.203, 1.2805, 1.3509, 1.4362)
    T[14, .] = (1.3112, 1.4042, 1.4881, 1.5876)
    T[15, .] = (1.387, 1.4865, 1.5779, 1.693)
    T[16, .] = (1.4422, 1.5538, 1.653, 1.7724)
    T[17, .] = (1.4707, 1.59, 1.6953, 1.8223)
    T[18, .] = (1.4892, 1.6105, 1.7206, 1.8559)
    T[19, .] = (1.4902, 1.6156, 1.7297, 1.8668)
    T[20, .] = (1.5067, 1.6319, 1.7455, 1.8827)
    T[21, .] = (0.825, 0.8668, 0.904, 0.9519)
    T[22, .] = (1.0802, 1.1419, 1.1986, 1.27)
    T[23, .] = (1.2491, 1.3259, 1.3951, 1.482)
    T[24, .] = (1.3647, 1.4516, 1.5326, 1.6302)
    T[25, .] = (1.4449, 1.5421, 1.6322, 1.747)
    T[26, .] = (1.5045, 1.6089, 1.7008, 1.8143)
    T[27, .] = (1.5353, 1.656, 1.751, 1.8756)
    T[28, .] = (1.5588, 1.6751, 1.7809, 1.9105)
    T[29, .] = (1.563, 1.6828, 1.7901, 1.919)
    T[30, .] = (1.5785, 1.6981, 1.8071, 1.9395)
    T[31, .] = (0.8414, 0.8828, 0.9205, 0.9681)
    T[32, .] = (1.1066, 1.1663, 1.2217, 1.2918)
    T[33, .] = (1.2792, 1.3533, 1.4212, 1.5013)
    T[34, .] = (1.3973, 1.4506, 1.5593, 1.6536)
    T[35, .] = (1.4852, 1.5791, 1.669, 1.7741)
    T[36, .] = (1.5429, 1.6465, 1.742, 1.8573)
    T[37, .] = (1.5852, 1.6927, 1.7941, 1.914)
    T[38, .] = (1.6057, 1.7195, 1.8212, 1.945)
    T[39, .] = (1.6089, 1.7245, 1.8269, 1.9592)
    T[40, .] = (1.6275, 1.7435, 1.8495, 1.9787)
    T[41, .] = (0.8541, 0.8948, 0.9321, 0.9799)
    T[42, .] = (1.1247, 1.1846, 1.2395, 1.3088)
    T[43, .] = (1.304, 1.3765, 1.444, 1.5252)
    T[44, .] = (1.425, 1.5069, 1.5855, 1.6791)
    T[45, .] = (1.5154, 1.6077, 1.6921, 1.7967)
    T[46, .] = (1.5738, 1.677, 1.7687, 1.8837)
    T[47, .] = (1.6182, 1.7217, 1.8176, 1.9377)
    T[48, .] = (1.646, 1.754, 1.8553, 1.9788)
    T[49, .] = (1.6462, 1.7574, 1.8615, 1.9897)
    T[50, .] = (1.6644, 1.7777, 1.8816, 2.0085)
    T[51, .] = (0.8653, 0.9048, 0.9414, 0.988)
    T[52, .] = (1.1415, 1.1997, 1.253, 1.622)
    T[53, .] = (1.3223, 1.3938, 1.4596, 1.5392)
    T[54, .] = (1.4483, 1.5305, 1.61, 1.7014)
    T[55, .] = (1.5392, 1.6317, 1.7139, 1.8154)
    T[56, .] = (1.6025, 1.7018, 1.793, 1.9061)
    T[57, .] = (1.6462, 1.7499, 1.8439, 1.9605)
    T[58, .] = (1.6697, 1.7769, 1.8763, 1.9986)
    T[59, .] = (1.6802, 1.7889, 1.8932, 2.0163)
    T[60, .] = (1.6939, 1.8052, 1.9074, 2.0326)
    return(T)
}

real matrix gvar_scchk()
{
    real matrix T
    real colvector h
    real scalar c

    T = J(10, 6, .)
    T[ 1, .] = (3.2165, 3.3185, 3.4554, 3.6622, 3.8632, 4.1009)
    T[ 2, .] = (2.9795, 3.0894, 3.2368, 3.4681, 3.6707, 3.9397)
    T[ 3, .] = (2.8289, 2.9479, 3.1028, 3.3382, 3.5598, 3.8143)
    T[ 4, .] = (2.7099, 2.8303, 2.9874, 3.2351, 3.4604, 3.7337)
    T[ 5, .] = (2.6061, 2.7325, 2.8985, 3.1531, 3.3845, 3.6626)
    T[ 6, .] = (2.5111, 2.6418, 2.8134, 3.0728, 3.3102, 3.5907)
    T[ 7, .] = (2.4283, 2.5609, 2.7327, 3.0043, 3.2461, 3.5333)
    T[ 8, .] = (2.3464, 2.484, 2.6605, 2.9333, 3.1823, 3.4895)
    T[ 9, .] = (2.2686, 2.4083, 2.5899, 2.8743, 3.1229, 3.4123)
    T[10, .] = (2.2255, 2.3668, 2.5505, 2.8334, 3.0737, 3.3912)
    // efp.R: crit.table <- crit.table * sqrt(tableh)
    h = (1::10) :* 0.05
    for (c = 1; c <= 6; c++) {
        T[., c] = T[., c] :* sqrt(h)
    }
    return(T)
}

// ---------------------------------------------------------------------------
// Empirical fluctuation processes  (strucchange 1.6-0, R/efp.R)
//
// GVARX's .gvar.stability and vars' stability.varest both delegate to
// strucchange::efp, so efp.R is the source followed here, line for line,
// together with R/recresid.R, R/matrix.R and the tables in R/critvals.R.
//
//   1 Rec-CUSUM    Brown, Durbin & Evans (1975)      Brownian motion
//   2 OLS-CUSUM    Ploberger & Kramer (1992)         Brownian bridge
//   3 Rec-MOSUM    Bauer & Hackl (1978)              BM increments
//   4 OLS-MOSUM    Chu, Hornik & Kuan (1995)         BB increments
//   5 RE           Ploberger, Kramer & Kontrus (1989) Brownian bridge
//   6 ME           Chu, Hornik & Kuan (1995)         BB increments
//   7 Score-CUSUM  Hjort & Koning (2002)             Brownian bridge
//   8 Score-MOSUM  as above, moving-window form      BB increments
//
// Three details of efp.R are easy to get wrong and are worth naming, because
// getting any of them wrong changes every number:
//
//   * sigma is strucchange's sdev(), which DEMEANS.  sdev(x, df) is
//     sd(x)*sqrt((n-1)/df), and sd() divides the demeaned sum of squares by
//     n-1, so sdev(x, df) = sqrt(sum((x-xbar)^2)/df).  For an equation with an
//     intercept the residual mean is zero and this coincides with the
//     Toolbox's kraplob.m; without one it does not.
//
//   * the MOSUM processes divide by sqrt(n) or sqrt(nw) -- the FULL count --
//     not by sqrt of the window length.
//
//   * root.matrix() is the SYMMETRIC square root via eigendecomposition, not
//     a Cholesky factor.  RE, ME and the Score processes all use it, and a
//     Cholesky factor gives different components (though the same max-norm
//     only by coincidence, if at all).
//
// which: 1..8 as above.  Returns the process, rows x components, exactly as
// efp.R leaves it -- including the leading zero row where efp.R prepends one.
// ---------------------------------------------------------------------------

// strucchange's sdev(x, df) = sqrt(sum((x - mean(x))^2)/df).
// Pass df = . for the default df = n - 1, which makes it plain sd().
real scalar gvar_sdev(real colvector x, real scalar df)
{
    real scalar n, mu, ss, d

    n = rows(x)
    if (n < 2) return(.)
    mu = mean(x)
    ss = quadcross(x :- mu, x :- mu)
    d  = df
    if (d >= .) d = n - 1
    if (d <= 0) return(.)
    return(sqrt(ss / d))
}

// strucchange's root.matrix(): the symmetric square root by eigendecomposition.
real matrix gvar_rootmat(real matrix X)
{
    real matrix V, R
    real rowvector L

    if (rows(X) == 1 & cols(X) == 1) return(sqrt(X))
    symeigensystem(makesymmetric(X), V, L)
    // efp.R stops if any eigenvalue is negative; here a tiny negative one is
    // rounding and is floored, while a materially negative one gives up
    if (min(L) < -1e-8) return(J(rows(X), cols(X), .))
    L = L :* (L :> 0)
    R = V * diag(sqrt(L)) * V'
    return(makesymmetric(R))
}

// Standardized recursive residuals (strucchange R/recresid.R).
//   X1    <- X1 - X1 x x' X1 / f
//   betar <- betar + X1_new x e
//   f     <- 1 + x' X1 x ;  w <- (y - x'betar)/sqrt(f)
// Initialised on the first k observations, giving n-k residuals.  The rank-one
// coefficient update below is algebraically the recursion in recresid.R:
// X1_new x = X1_old x / f, so betar + (X1_old x)(e/f) is betar + X1_new x e.
real colvector gvar_recresid(real colvector y, real matrix x)
{
    real scalar T, kx, t, den, ee
    real matrix Ai
    real rowvector xt
    real colvector b, out, ax

    T  = rows(y)
    kx = cols(x)
    if (T <= kx + 1) return(J(0, 1, .))

    Ai = gvar_sinv(cross(x[1::kx, .], x[1::kx, .]))
    b  = Ai * cross(x[1::kx, .], y[1::kx])
    if (hasmissing(b)) return(J(0, 1, .))

    out = J(T - kx, 1, .)
    for (t = kx + 1; t <= T; t++) {
        xt  = x[t, .]
        ax  = Ai * xt'
        den = 1 + (xt * ax)
        if (den <= 0) return(J(0, 1, .))
        ee  = y[t] - (xt * b)
        out[t - kx] = ee / sqrt(den)
        Ai = Ai - (ax * ax') / den
        b  = b + ax * (ee / den)
    }
    if (hasmissing(out)) return(J(0, 1, .))
    return(out)
}

real matrix gvar_efpproc(real colvector y, real matrix x, real scalar which,
                         real scalar hfrac)
{
    real scalar n, k, m, nh, i, t, sg, sg2, nw
    real matrix XX, XXi, P, Q12, Qi12, xi, S, Ci, W
    real colvector e, w, bn, bt, cs, out

    n   = rows(y)
    k   = cols(x)
    XX  = cross(x, x)
    XXi = gvar_sinv(XX)
    e   = y - x * (XXi * cross(x, y))

    // ---- 1  Rec-CUSUM ---------------------------------------------------
    // w <- recresid(X,y); sigma <- sdev(w)
    // process <- cumsum(c(0,w))/(sigma*sqrt(n-k))
    if (which == 1) {
        w = gvar_recresid(y, x)
        if (rows(w) == 0) return(J(0, 1, .))
        sg = gvar_sdev(w, .)
        if (sg >= . | sg <= 0) return(J(0, 1, .))
        return((0 \ runningsum(w)) / (sg * sqrt(n - k)))
    }

    // ---- 2  OLS-CUSUM ---------------------------------------------------
    // sigma <- sdev(e, df = n-k); process <- cumsum(c(0,e))/(sigma*sqrt(n))
    if (which == 2) {
        sg = gvar_sdev(e, n - k)
        if (sg >= . | sg <= 0) return(J(0, 1, .))
        return((0 \ runningsum(e)) / (sg * sqrt(n)))
    }

    // ---- 3  Rec-MOSUM ---------------------------------------------------
    // nw <- n-k; nh <- floor(nw*h); moving sums of w over nh
    // sigma <- sdev(w, df = nw-k); process <- process/(sigma*sqrt(nw))
    if (which == 3) {
        w = gvar_recresid(y, x)
        if (rows(w) == 0) return(J(0, 1, .))
        nw = n - k
        nh = floor(nw * hfrac)
        if (nh < 1 | nh > nw) return(J(0, 1, .))
        sg = gvar_sdev(w, nw - k)
        if (sg >= . | sg <= 0) return(J(0, 1, .))
        cs  = 0 \ runningsum(w)
        out = J(nw - nh + 1, 1, .)
        for (i = 1; i <= nw - nh + 1; i++) {
            out[i] = cs[i + nh] - cs[i]
        }
        return(out / (sg * sqrt(nw)))
    }

    // ---- 4  OLS-MOSUM ---------------------------------------------------
    // nh <- floor(n*h); moving sums of e over nh; /(sigma*sqrt(n))
    if (which == 4) {
        sg = gvar_sdev(e, n - k)
        if (sg >= . | sg <= 0) return(J(0, 1, .))
        nh = floor(n * hfrac)
        if (nh < 1 | nh > n) return(J(0, 1, .))
        cs  = 0 \ runningsum(e)
        out = J(n - nh + 1, 1, .)
        for (i = 1; i <= n - nh + 1; i++) {
            out[i] = cs[i + nh] - cs[i]
        }
        return(out / (sg * sqrt(n)))
    }

    // ---- 5  RE, with rescale = TRUE (the efp() default) -----------------
    // Qi12 <- root.matrix(crossprod(X[1:i,]))/(sigma*sqrt(i))
    // process[,i-k+1] <- Qi12 (b_i - b_n),  i = k..(n-1)
    // process <- t(cbind(0, process)) * rep((k-1):n) / sqrt(n)
    if (which == 5) {
        sg = gvar_sdev(e, n - k)
        if (sg >= . | sg <= 0) return(J(0, 1, .))
        bn = XXi * cross(x, y)

        // k x (n-k+1) as in efp.R: the loop fills columns 1..n-k and leaves
        // the last one zero
        P = J(k, n - k + 1, 0)
        for (i = k; i <= n - 1; i++) {
            xi   = x[1::i, .]
            Qi12 = gvar_rootmat(cross(xi, xi)) / (sg * sqrt(i))
            if (hasmissing(Qi12)) return(J(0, 1, .))
            bt = gvar_sinv(cross(xi, xi)) * cross(xi, y[1::i])
            P[., i - k + 1] = Qi12 * (bt - bn)
        }
        // prepend the zero column, transpose, then scale row r by (k-2+r)
        P = (J(k, 1, 0), P)'
        for (t = 1; t <= rows(P); t++) {
            P[t, .] = P[t, .] :* ((k - 2 + t) / sqrt(n))
        }
        return(P)
    }

    // ---- 6  ME, with rescale = TRUE -------------------------------------
    // Qnh12 <- root.matrix(crossprod(X[(i+1):(i+nh),]))/(sigma*sqrt(nh))
    // process[,i+1] <- Qnh12 (b_i - b_n);  process <- nh*t(process)/sqrt(n)
    if (which == 6) {
        sg = gvar_sdev(e, n - k)
        if (sg >= . | sg <= 0) return(J(0, 1, .))
        nh = floor(n * hfrac)
        if (nh <= k | nh > n) return(J(0, 1, .))
        bn = XXi * cross(x, y)

        P = J(k, n - nh + 1, 0)
        for (i = 0; i <= n - nh; i++) {
            xi   = x[(i+1)::(i+nh), .]
            Qi12 = gvar_rootmat(cross(xi, xi)) / (sg * sqrt(nh))
            if (hasmissing(Qi12)) return(J(0, 1, .))
            bt = gvar_sinv(cross(xi, xi)) * cross(xi, y[(i+1)::(i+nh)])
            P[., i + 1] = Qi12 * (bt - bn)
        }
        return(nh * P' / sqrt(n))
    }

    // ---- 7 and 8  Score-CUSUM and Score-MOSUM ---------------------------
    // sigma2 <- sum(e^2)/n
    // process <- cbind(X*e, e^2 - sigma2)/sqrt(n)      <- k+1 components
    // Q12 <- root.matrix(crossprod(process))
    // cumsum with a leading zero row, then post-multiply by Q12^{-1}
    if (which == 7 | which == 8) {
        sg2 = quadcross(e, e) / n
        S   = J(n, k + 1, 0)
        for (i = 1; i <= k; i++) {
            S[., i] = x[., i] :* e
        }
        S[., k + 1] = (e :* e) :- sg2
        S = S / sqrt(n)

        Q12 = gvar_rootmat(cross(S, S))
        if (hasmissing(Q12)) return(J(0, 1, .))
        Ci = gvar_sinv(Q12)
        if (hasmissing(Ci)) return(J(0, 1, .))

        // cumulative sums with the leading zero row efp.R prepends
        W = J(n + 1, k + 1, 0)
        for (i = 1; i <= k + 1; i++) {
            W[2::(n+1), i] = runningsum(S[., i])
        }

        if (which == 7) {
            return(W * Ci)
        }

        nh = floor(n * hfrac)
        if (nh < 1 | nh > n) return(J(0, 1, .))
        // process[-(1:nh),] - process[1:(n-nh+1),] on the n+1 rows
        P = J(n - nh + 1, k + 1, .)
        for (i = 1; i <= n - nh + 1; i++) {
            P[i, .] = W[i + nh, .] - W[i, .]
        }
        return(P * Ci)
    }

    return(J(0, 1, .))
}

// The limiting process of each type, as efp.R records it:
//   1 Brownian motion  2 Brownian bridge
//   3 Brownian motion increments  4 Brownian bridge increments
real scalar gvar_efplim(real scalar which)
{
    if (which == 1) return(1)
    if (which == 2) return(2)
    if (which == 3) return(3)
    if (which == 4) return(4)
    if (which == 5) return(2)
    if (which == 6) return(4)
    if (which == 7) return(2)
    if (which == 8) return(4)
    return(0)
}

// The max functional, exactly as sctest.efp applies it:
//   for Brownian motion and Brownian bridge the FIRST row is dropped, because
//   efp.R prepended a zero there;
//   for Brownian motion the process is then divided by (1 + 2j), j = 1:n/n,
//   which is the boundary the statistic is measured against;
//   the statistic is max|.| over every row and component.
real scalar gvar_efpstat(real matrix P0, real scalar which)
{
    real matrix P
    real scalar lp, nr, t

    if (rows(P0) == 0) return(.)
    lp = gvar_efplim(which)
    P  = P0
    if (lp == 1 | lp == 2) {
        if (rows(P) < 2) return(.)
        P = P[2::rows(P), .]
    }
    nr = rows(P)
    if (lp == 1) {
        for (t = 1; t <= nr; t++) {
            P[t, .] = P[t, .] :/ (1 + 2 * t / nr)
        }
    }
    return(max(abs(P)))
}

// The path the statistic is the maximum of: the row-wise max-norm after the
// same drop and rescale, so that plotting it beside the critical value shows
// where the rejection comes from.
real matrix gvar_efppathv(real matrix P0, real scalar which)
{
    real matrix P
    real scalar lp, nr, t
    real colvector v

    if (rows(P0) == 0) return(J(1, 2, .))
    lp = gvar_efplim(which)
    P  = P0
    if (lp == 1 | lp == 2) {
        if (rows(P) < 2) return(J(1, 2, .))
        P = P[2::rows(P), .]
    }
    nr = rows(P)
    if (lp == 1) {
        for (t = 1; t <= nr; t++) {
            P[t, .] = P[t, .] :/ (1 + 2 * t / nr)
        }
    }
    v = J(nr, 1, .)
    for (t = 1; t <= nr; t++) {
        v[t] = max(abs(P[t, .]))
    }
    return((1::nr), v)
}

// ---------------------------------------------------------------------------
// p-values, following strucchange's pvalue.efp for the max functional.
//
// Brownian motion and Brownian bridge have closed forms and are reproduced
// exactly.  The two increments cases are table look-ups with linear
// interpolation, as in the source: approx(..., rule = 2) clamps outside the
// table rather than extrapolating, which is reproduced here.
//
// ncomp is the number of components of the process, strucchange's k.
// ---------------------------------------------------------------------------

// linear interpolation with end-clamping, R's approx(rule = 2)
real scalar gvar_approx(real colvector xs, real colvector ys, real scalar x)
{
    real scalar n, i

    n = rows(xs)
    if (n == 0) return(.)
    if (x <= xs[1]) return(ys[1])
    if (x >= xs[n]) return(ys[n])
    for (i = 1; i < n; i++) {
        if (x >= xs[i] & x <= xs[i+1]) {
            if (xs[i+1] == xs[i]) return(ys[i])
            return(ys[i] + (ys[i+1] - ys[i]) * (x - xs[i]) / (xs[i+1] - xs[i]))
        }
    }
    return(ys[n])
}

real scalar gvar_efppval(real scalar stat, real scalar which,
                         real scalar hfrac, real scalar ncomp)
{
    real scalar lp, p, i, kk, hh
    real matrix T
    real colvector xs, ys, tp, ipl

    if (stat >= .) return(.)
    lp = gvar_efplim(which)

    // ---- Brownian motion, max ------------------------------------------
    // p <- ifelse(x < 0.3, 1 - 0.1465*x,
    //   2*(1-pnorm(3x) + exp(-4x^2)*(pnorm(x)+pnorm(5x)-1)
    //      - exp(-16x^2)*(1-pnorm(x))))
    // p <- 1 - (1-p)^k
    if (lp == 1) {
        if (stat < 0.3) {
            p = 1 - 0.1465 * stat
        }
        else {
            p = 2 * (1 - normal(3 * stat)
                     + exp(-4 * stat^2) * (normal(stat) + normal(5*stat) - 1)
                     - exp(-16 * stat^2) * (1 - normal(stat)))
        }
        if (p < 0) p = 0
        if (p > 1) p = 1
        return(1 - (1 - p)^ncomp)
    }

    // ---- Brownian bridge, max ------------------------------------------
    // p <- ifelse(x<0.1, 1, 1-(1+2*sum_{i=1}^{100} exp(-2 i^2 x^2)(-1)^i)^k)
    if (lp == 2) {
        if (stat < 0.1) return(1)
        p = 0
        for (i = 1; i <= 100; i++) {
            p = p + exp(-2 * i^2 * stat^2) * (-1)^i
        }
        p = 1 - (1 + 2 * p)^ncomp
        if (p < 0) p = 0
        if (p > 1) p = 1
        return(p)
    }

    // ---- Brownian motion increments, max: Chu-Hornik-Kuan Table 1 ------
    if (lp == 3) {
        T  = gvar_scchk()
        xs = (1::10) :* 0.05
        tp = (0.2 \ 0.15 \ 0.1 \ 0.05 \ 0.025 \ 0.01)
        ipl = J(6, 1, .)
        for (i = 1; i <= 6; i++) {
            ipl[i] = gvar_approx(xs, T[., i], hfrac)
        }
        p = gvar_approx((0 \ ipl), (1 \ tp), stat)
        return(1 - (1 - p)^ncomp)
    }

    // ---- Brownian bridge increments, max: sc.me ------------------------
    // pvalue.efp caps k at 6 and selects rows ((k-1)*10+1):(k*10)
    if (lp == 4) {
        kk = ncomp
        if (kk > 6) kk = 6
        if (kk < 1) kk = 1
        T  = gvar_scme()
        xs = (1::10) :* 0.05
        tp = (0.1 \ 0.05 \ 0.025 \ 0.01)
        ipl = J(4, 1, .)
        for (i = 1; i <= 4; i++) {
            ipl[i] = gvar_approx(xs, T[((kk-1)*10+1)::(kk*10), i], hfrac)
        }
        return(gvar_approx((0 \ ipl), (1 \ tp), stat))
    }

    return(.)
}

// The critical value at level alpha: the statistic whose p-value is alpha.
// boundary.efp does this with uniroot over (0, 20); a bisection over the same
// interval is used here, and the p-value function is monotone decreasing in
// the statistic so the root is unique.
real scalar gvar_efpcrit(real scalar which, real scalar hfrac,
                         real scalar ncomp, real scalar alpha)
{
    real scalar lo, hi, mid, plo, phi, pm, it

    lo = 0
    hi = 20
    plo = gvar_efppval(lo, which, hfrac, ncomp)
    phi = gvar_efppval(hi, which, hfrac, ncomp)
    if (plo >= . | phi >= .) return(.)
    // the tabulated cases are flat outside the table, so a root may not exist
    if (plo < alpha | phi > alpha) return(.)

    for (it = 1; it <= 200; it++) {
        mid = (lo + hi) / 2
        pm  = gvar_efppval(mid, which, hfrac, ncomp)
        if (pm >= .) return(.)
        if (pm > alpha) lo = mid
        else            hi = mid
        if (hi - lo < 1e-10) break
    }
    return((lo + hi) / 2)
}

// The statistic, its p-value and the component count for one equation.
real rowvector gvar_efpone(real colvector y, real matrix x, real scalar which,
                           real scalar hfrac)
{
    real matrix P
    real scalar st, pv, nc

    P = gvar_efpproc(y, x, which, hfrac)
    if (rows(P) == 0) return((., ., .))
    nc = cols(P)
    st = gvar_efpstat(P, which)
    pv = gvar_efppval(st, which, hfrac, nc)
    return((st, pv, nc))
}

// One row per equation: unit, equation, statistic, p-value, components.
real matrix gvar_efptests(real scalar which, real scalar hfrac)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, DY, DX
    real scalar i, j

    m   = gvar_MODEL
    OUT = J(0, 5, .)
    for (i = 1; i <= m.N; i++) {
        DY = *m.dep[i]
        DX = *m.rgr[i]
        for (j = 1; j <= m.ki[i]; j++) {
            OUT = OUT \ (i, j, gvar_efpone(DY[., j], DX, which, hfrac))
        }
    }
    return(OUT)
}

// The plottable path for one equation.
real matrix gvar_efppath(real scalar unit, real scalar eq, real scalar which,
                         real scalar hfrac)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix DY, DX, P

    m  = gvar_MODEL
    DY = *m.dep[unit]
    DX = *m.rgr[unit]
    P  = gvar_efpproc(DY[., eq], DX, which, hfrac)
    if (rows(P) == 0) return(J(1, 2, .))
    return(gvar_efppathv(P, which))
}

// The two paths for one equation, assembled for -gvar stability, graph-.
// Column 1 is the observation index, 2 the OLS-CUSUM path (defined for every
// t), 3 and 4 the sequential Chow F and its robust version (defined only on
// the trimmed interior, missing elsewhere).
real matrix gvar_stabpath(real scalar unit, real scalar eq, real scalar ccut)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix DY, DX, SP, OUT
    real colvector t1
    real scalar T, i, row

    m  = gvar_MODEL
    DY = *m.dep[unit]
    DX = *m.rgr[unit]

    t1 = gvar_kraplobpath(DY[., eq], DX)
    // 1x4 of missing, not 0x4: the caller hands this straight to st_matrix,
    // and a Stata matrix cannot have zero rows
    if (rows(t1) == 0) return(J(1, 4, .))
    T  = rows(t1)

    SP  = gvar_schowpath(DY[., eq], DX, ccut)
    OUT = J(T, 4, .)
    for (i = 1; i <= T; i++) {
        OUT[i, 1] = i
        OUT[i, 2] = t1[i]
    }
    for (i = 1; i <= rows(SP); i++) {
        row = SP[i, 1]
        if (row >= 1 & row <= T) {
            OUT[row, 3] = SP[i, 2]
            OUT[row, 4] = SP[i, 3]
        }
    }
    return(OUT)
}

// ===========================================================================
// 8.  Residual diagnostics
// ===========================================================================

// Descriptive statistics  (Toolbox dstats.m)
real rowvector gvar_dstats(real colvector x)
{
    real scalar T, mu, md, mx, mn, sg, sk, ku

    T  = rows(x)
    mu = mean(x)
    md = gvar_quantile(x, 0.5)
    mx = max(x)
    mn = min(x)
    sg = sqrt(variance(x))
    if (sg <= 0) {
        return((mu, md, mx, mn, sg, ., .))
    }
    sk = colsum(((x :- mu) :/ sg) :^ 3) / T
    ku = colsum(((x :- mu) :/ sg) :^ 4) / T
    return((mu, md, mx, mn, sg, sk, ku))
}

// Jarque-Bera, univariate  (Toolbox jarquebera.m; GVARX .jb.uni)
real rowvector gvar_jb(real colvector x)
{
    real scalar T, mu, m2, m3, m4, b1, b2, W, p

    T  = rows(x)
    mu = mean(x)
    m2 = colsum((x :- mu) :^ 2) / T
    m3 = colsum((x :- mu) :^ 3) / T
    m4 = colsum((x :- mu) :^ 4) / T
    if (m2 <= 0) {
        return((., ., .))
    }
    b1 = (m3 / m2^(3 / 2))^2
    b2 = m4 / m2^2
    W  = T * (b1 / 6 + ((b2 - 3)^2) / 24)
    p  = chi2tail(2, W)
    return((W, 2, p))
}

// ---------------------------------------------------------------------------
// Descriptive statistics of the variable blocks  (Toolbox print_dstats.m,
// which calls dstats.m and jarquebera.m).
//
// print_dstats writes three sheets -- domestic, foreign-specific and global --
// each with Mean, Median, Maximum, Minimum, Std. dev., Skewness, Kurtosis,
// Jarque-Bera and its probability, one row per country.  This returns the same
// nine numbers for every (block, unit, variable) that exists.
//
// Note the moments are the Toolbox's: dstats.m divides the third and fourth
// central moments by T and by the plain standard deviation, so "kurtosis" here
// is the raw fourth standardised moment (3 for a normal), not excess kurtosis.
// gvar_dstats already follows that, and gvar_jb is jarquebera.m.
//
// The global block is written only when there are global variables that are
// not endogenous to some unit; with gendog() they live in that unit's domestic
// block instead, exactly as they do in the Toolbox.
//
// Returns 1 kind (1 domestic, 2 foreign-specific), 2 unit, 3 variable index
// into vname, then 4 mean 5 median 6 max 7 min 8 sd 9 skew 10 kurt
// 11 Jarque-Bera 12 its p-value.
// ---------------------------------------------------------------------------
real matrix gvar_dstatstab()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, Y, S
    real rowvector ds, jb
    real colvector x
    real scalar i, j, p, nn

    m   = gvar_MODEL
    OUT = J(0, 12, .)

    for (i = 1; i <= m.N; i++) {
        // ---- domestic ----
        Y = *m.Yi[i]
        for (j = 1; j <= cols(Y); j++) {
            x  = Y[., j]
            ds = gvar_dstats(x)
            jb = gvar_jb(x)
            // the variable's position in the model's own name list, so the
            // table columns line up with every other table in the package
            p  = gvar_pos(m.vname, (*m.ylist[i])[j])
            if (p == 0) p = rows(m.vname) + gvar_pos(m.gvname, (*m.ylist[i])[j])
            OUT = OUT \ (1, i, p, ds, jb[1], jb[3])
        }
        // ---- foreign-specific ----
        if (m.ksi[i] > 0) {
            S = *m.Si[i]
            for (j = 1; j <= cols(S); j++) {
                x  = S[., j]
                ds = gvar_dstats(x)
                jb = gvar_jb(x)
                p  = gvar_pos(m.vname, (*m.slist[i])[j])
                if (p == 0) {
                    p = rows(m.vname) + gvar_pos(m.gvname, (*m.slist[i])[j])
                }
                OUT = OUT \ (2, i, p, ds, jb[1], jb[3])
            }
        }
    }
    return(OUT)
}

// Jarque-Bera, multivariate on Cholesky-standardised residuals
// (GVARX .jb.multi).  Returns (JB, df, p, skew, dfs, ps, kurt, dfk, pk).
real rowvector gvar_jbmulti(real matrix resid)
{
    real scalar T, K, s3, s4, jb
    real matrix R, P, Rs
    real rowvector b1, b2

    T = rows(resid)
    K = cols(resid)
    R = resid :- mean(resid)
    P = cholesky(makesymmetric(cross(R, R) / T))
    if (hasmissing(P)) {
        return(J(1, 9, .))
    }
    Rs = R * (gvar_inv(P))'

    b1 = colsum(Rs :^ 3) / T
    b2 = colsum(Rs :^ 4) / T

    s3 = T * (b1 * b1') / 6
    s4 = T * ((b2 :- 3) * (b2 :- 3)') / 24
    jb = s3 + s4

    return((jb, 2 * K, chi2tail(2 * K, jb),
            s3, K, chi2tail(K, s3),
            s4, K, chi2tail(K, s4)))
}

// ARCH-LM, univariate  (GVARX .arch.uni).  Returns (chi2, df, p).
real rowvector gvar_arch1(real colvector x, real scalar q)
{
    real scalar T, i, r2, stat
    real matrix Z
    real colvector z, dep, res, one
    real scalar sst, sse

    T = rows(x)
    z = (x :- mean(x)) :/ sqrt(variance(x))
    z = z :^ 2
    dep = z[(q+1)::T]
    one = J(rows(dep), 1, 1)
    Z   = one
    for (i = 1; i <= q; i++) {
        Z = Z, z[(q+1-i)::(T-i)]
    }
    res = dep - Z * (gvar_sinv(cross(Z, Z)) * cross(Z, dep))
    sse = res' * res
    sst = colsum((dep :- mean(dep)) :^ 2)
    if (sst <= 0) {
        return((., q, .))
    }
    r2   = 1 - sse / sst
    stat = r2 * rows(dep)
    return((stat, q, chi2tail(q, stat)))
}

// ARCH-LM, multivariate  (GVARX .arch.multi).  Returns (chi2, df, p).
real rowvector gvar_archm(real matrix resid, real scalar q)
{
    real scalar T, K, ncol, i, j, c, n, stat, df, R2m
    real matrix Z, dep, X, one, res0, res1, om0, om1

    T = rows(resid)
    K = cols(resid)
    ncol = 0.5 * K * (K + 1)
    Z = J(T, ncol, 0)
    for (i = 1; i <= T; i++) {
        c = 0
        for (j = 1; j <= K; j++) {
            for (n = j; n <= K; n++) {
                c = c + 1
                Z[i, c] = resid[i, j] * resid[i, n]
            }
        }
    }

    dep = Z[(q+1)::T, .]
    one = J(rows(dep), 1, 1)
    X   = one
    for (i = 1; i <= q; i++) {
        X = X, Z[(q+1-i)::(T-i), .]
    }

    res0 = dep :- mean(dep)
    res1 = dep - X * qrsolve(X, dep)
    om0  = cross(res0, res0) / rows(dep)
    om1  = cross(res1, res1) / rows(dep)

    R2m  = 1 - (2 / (K * (K + 1))) * trace(om1 * gvar_sinv(om0))
    stat = 0.5 * rows(dep) * K * (K + 1) * R2m
    df   = q * K^2 * (K + 1)^2 / 4
    return((stat, df, chi2tail(df, stat)))
}

// Multivariate portmanteau, asymptotic and adjusted  (GVARX .pt.multi).
// Returns (Qh, dfh, ph, Qhstar, dfh, phstar).
//
//   kadj  degrees-of-freedom correction.  .pt.multi sets
//           PARAMETER <- K^2*lags.pt - nstar          for a "varest" object
//           PARAMETER <- K^2*lags.pt - nstar + K      for a "vec2var" object
//         so kadj = 0 for a VARX* fitted in levels and kadj = K for a model
//         that came from a VECM, which is what a VECMX* country model is.
real rowvector gvar_portmanteau(real matrix resid, real scalar h, real scalar p,
                                real scalar kadj)
{
    real scalar T, K, i, nstar, Qh, Qhs, df
    real matrix C0, C0i, Ci, Ut, Utm
    real colvector tr

    T = rows(resid)
    K = cols(resid)
    C0  = cross(resid, resid) / T
    C0i = gvar_sinv(C0)
    tr  = J(h, 1, 0)
    for (i = 1; i <= h; i++) {
        Ut  = resid[(i+1)::T, .]
        Utm = resid[1::(T-i), .]
        Ci  = cross(Ut, Utm) / T
        tr[i] = trace(Ci' * C0i * Ci * C0i)
    }
    nstar = K^2 * p
    Qh    = T * colsum(tr)
    Qhs   = T^2 * colsum(tr :/ (T :- (1::h)))
    df    = K^2 * h - nstar + kadj
    if (df <= 0) {
        return((Qh, df, ., Qhs, df, .))
    }
    return((Qh, df, chi2tail(df, Qh), Qhs, df, chi2tail(df, Qhs)))
}

// Breusch-Godfrey LM and the Edgerton-Shukur small-sample F  (GVARX .bgserial).
// Returns (LM, dfLM, pLM, F, df1, df2, pF).
real rowvector gvar_bgserial(real matrix resid, real matrix ylagged,
                             real scalar h)
{
    real scalar T, K, i, m, q, n, N, r, R2r, LM, Fst, df1, df2
    real matrix rl, X0, X1, r0, r1, s0, s1

    T = rows(resid)
    K = cols(resid)

    rl = J(T, K * h, 0)
    for (i = 1; i <= h; i++) {
        rl[., ((i-1)*K+1)::(i*K)] = gvar_lagm(resid, i)
    }

    X0 = ylagged, rl
    X1 = ylagged

    r0 = resid - X0 * qrsolve(X0, resid)
    r1 = resid - X1 * qrsolve(X1, resid)
    s0 = cross(r0, r0) / T
    s1 = cross(r1, r1) / T

    LM  = T * (K - trace(gvar_sinv(s1) * s0))
    df1 = h * K^2

    R2r = 1 - exp(gvar_logdet(s0) - gvar_logdet(s1))
    m   = K * h
    q   = 0.5 * K * m - 1
    n   = cols(ylagged)
    N   = T - n - m - 0.5 * (K - m + 1)
    if ((K^2 + m^2 - 5) <= 0) {
        return((LM, df1, chi2tail(df1, LM), ., ., ., .))
    }
    r   = sqrt((K^2 * m^2 - 4) / (K^2 + m^2 - 5))
    if (R2r >= 1 | R2r <= 0) {
        return((LM, df1, chi2tail(df1, LM), ., ., ., .))
    }
    Fst = (1 - (1 - R2r)^(1 / r)) / (1 - R2r)^(1 / r) * (N * r - q) / (K * m)
    df2 = floor(N * r - q)
    if (df2 <= 0) {
        return((LM, df1, chi2tail(df1, LM), Fst, df1, df2, .))
    }
    return((LM, df1, chi2tail(df1, LM), Fst, df1, df2, Ftail(df1, df2, Fst)))
}

// White / Breusch-Pagan heteroskedasticity test on one equation
// Returns (chi2, df, p).
real rowvector gvar_hetwhite(real colvector e, real matrix X)
{
    real scalar T, k, i, j, stat, df
    real matrix Z
    real colvector dep, res, one
    real scalar sst, sse, r2

    T = rows(X)
    k = cols(X)
    // White's auxiliary regression: constant, the levels, the squares and
    // the cross-products.  With X a single column this is the "special form"
    // of the test, e^2 on the fitted value and its square, with 2 d.f.
    Z = J(T, 0, 0)
    for (i = 1; i <= k; i++) {
        for (j = i; j <= k; j++) {
            Z = Z, (X[., i] :* X[., j])
        }
    }
    one = J(T, 1, 1)
    Z   = one, X, Z
    dep = e :^ 2
    res = dep - Z * (gvar_sinv(cross(Z, Z)) * cross(Z, dep))
    sse = res' * res
    sst = colsum((dep :- mean(dep)) :^ 2)
    if (sst <= 0) {
        return((., ., .))
    }
    r2   = 1 - sse / sst
    stat = T * r2
    df   = rank(Z) - 1
    if (df <= 0) {
        return((stat, df, .))
    }
    return((stat, df, chi2tail(df, stat)))
}


// =========================================================================
// =====  from _gvar_mata_dyn.ado                                           
// =========================================================================


// ===========================================================================
// 1.  Dynamic multipliers  (Toolbox dyn_multipliers.m; BGVAR get_PHI)
// ===========================================================================
//   Phi_0 = I ,  Phi_h = sum_{l=1..p} F_l Phi_{h-l}
// Returned as one K x (K*(N+1)) matrix: block h occupies columns
// (h*K+1) .. ((h+1)*K) for h = 0,...,N.

real matrix gvar_phi(real matrix Fs, real scalar K, real scalar maxlag,
                     real scalar N)
{
    real scalar t, j, idx, nb
    real matrix PX, acc

    // PX holds blocks 1..(maxlag+N+1); block t occupies columns
    // ((t-1)*K+1)..(t*K).  Blocks 1..maxlag are the zero pre-sample blocks.
    nb = maxlag + N + 1
    PX = J(K, K * nb, 0)
    PX[., (maxlag*K + 1)::((maxlag + 1) * K)] = I(K)

    for (t = maxlag + 2; t <= nb; t++) {
        acc = J(K, K, 0)
        for (j = 1; j <= maxlag; j++) {
            idx = t - j
            if (idx >= 1) {
                acc = acc + Fs[., ((j-1)*K+1)::(j*K)] *
                            PX[., ((idx-1)*K+1)::(idx*K)]
            }
        }
        PX[., ((t-1)*K+1)::(t*K)] = acc
    }

    return(PX[., (maxlag*K + 1)::(nb * K)])
}

// convenience accessor: horizon h (0-based) block of a stacked Phi
real matrix gvar_phih(real matrix PH, real scalar K, real scalar h)
{
    return(PH[., (h*K+1)::((h+1)*K)])
}

// ===========================================================================
// 2.  Impulse responses  (Toolbox irf.m)
// ===========================================================================
// sgirf = 0 : generalized IRF (Pesaran-Shin)
// sgirf = 1 : structural GIRF -- orthogonalise the leading n0 x n0 block
// sgirf = 2 : orthogonalised (Cholesky) IRF -- n0 = K
//
//   GIRF_h = Phi_h G0^{-1} Sigma e_j / sqrt(e_j' Sigma e_j)
//
// eslct is the K x 1 shock selection vector (weighted for regional/global
// shocks, negative for a negative shock).

real matrix gvar_irfmat(real scalar K, real scalar N, real matrix PH,
                        real matrix Sigma_u, real matrix G,
                        real colvector eslct,
                        real scalar sgirf, real scalar n0)
{
    real scalar i, sc
    real matrix Sg, Gg, P0, P0H, invGS, IRF

    Sg = Sigma_u
    Gg = G

    if (sgirf == 1 | sgirf == 2) {
        P0  = cholesky(makesymmetric(Sg[1::n0, 1::n0]))
        P0H = I(K)
        P0H[1::n0, 1::n0] = gvar_inv(P0)
        Sg  = P0H * Sg * P0H'
        Gg  = P0H * Gg
    }

    IRF   = J(K, N + 1, 0)
    invGS = gvar_inv(Gg) * Sg
    sc    = eslct' * Sg * eslct
    if (sc <= 0) {
        return(J(K, N + 1, .))
    }
    sc = 1 / sqrt(sc)

    for (i = 0; i <= N; i++) {
        IRF[., i + 1] = (gvar_phih(PH, K, i) * invGS * eslct) * sc
    }
    return(IRF)
}

// Structural IRF given an already-built impact matrix B0 (= G^{-1} P Q)
real matrix gvar_irfstruct(real scalar K, real scalar N, real matrix PH,
                           real matrix B0, real colvector eslct)
{
    real scalar i
    real matrix IRF

    IRF = J(K, N + 1, 0)
    for (i = 0; i <= N; i++) {
        IRF[., i + 1] = gvar_phih(PH, K, i) * B0 * eslct
    }
    return(IRF)
}

// ---------------------------------------------------------------------------
// Counterfactual impulse responses  (BGVAR R/zzz.R irfcf)
//
// Holds one variable's response at exactly zero over the whole horizon by
// feeding in offsetting shocks in a chosen direction, and returns what the
// rest of the system then does.  This is how a transmission channel is
// switched off: hold the policy rate fixed and ask what an oil shock would
// have done without the monetary response.
//
//   e0_j(h)  = Phi2[hold, j, h] / irf[hold, via, 1]
//   Phi2[i, j, h+s-1] -= irf[i, via, s] * e0_j(h)
//
// irf is the ORIGINAL Cholesky response array and is never updated; Phi2 is.
// Note the naming in irfcf() is the reverse of what its documentation says:
// the argument it calls shockvar is the row that gets zeroed, and the one it
// calls resp is the direction used to zero it.  The arguments here are named
// for what the arithmetic does.
//
// Returns the full K x (K*(nhor+1)) counterfactual response array; the caller
// picks out the column of the shock it asked about.
// ---------------------------------------------------------------------------
real matrix gvar_irfcfmat(real scalar K, real scalar nhor, real matrix PH,
                          real matrix Sigma_eta,
                          real scalar hold, real scalar via)
{
    real matrix L, IR, PHI2, aux
    real colvector e0
    real scalar h, s, H, denom

    H = nhor + 1
    L = cholesky(makesymmetric(Sigma_eta))
    if (hasmissing(L)) return(J(0, 0, .))

    IR = J(K, K * H, 0)
    for (h = 1; h <= H; h++) {
        IR[., ((h-1)*K + 1)::(h*K)] = gvar_phih(PH, K, h - 1) * L
    }
    PHI2 = IR

    // the impact response of the held variable to the instrument shock; if it
    // is zero the instrument cannot move that variable at all
    denom = IR[hold, via]
    if (denom == 0) return(J(0, 0, .))

    for (h = 1; h <= H; h++) {
        e0 = (PHI2[hold, ((h-1)*K + 1)::(h*K)] / denom)'
        for (s = 1; s <= H - h + 1; s++) {
            aux = IR[., (s-1)*K + via] * e0'
            PHI2[., ((h+s-2)*K + 1)::((h+s-1)*K)] =
                PHI2[., ((h+s-2)*K + 1)::((h+s-1)*K)] - aux
        }
    }
    return(PHI2)
}

// Driver: the counterfactual response of every variable to one shock.
real matrix gvar_cfrun(real scalar shockp, real scalar nhor,
                       real scalar hold, real scalar via,
                       real scalar vmeth, real scalar vexcl,
                       real scalar shrink, real scalar lam,
                       real scalar cumul)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Sg, Seta, PH, PHI2, OUT, iG0
    real scalar K, lamout, h

    m  = gvar_MODEL
    K  = m.K
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    // irfcf works from the REDUCED-FORM covariance Ginv S Ginv', which is
    // Sigma_eta, and factors it whole rather than block by block
    iG0  = gvar_inv(m.G0)
    Seta = iG0 * Sg * iG0'

    PH   = gvar_phi(m.Fs, K, m.pmax, nhor)
    PHI2 = gvar_irfcfmat(K, nhor, PH, Seta, hold, via)
    // 1x1, not 0x0: the caller hands this to st_matrix, which cannot take an
    // empty matrix, so failure has to be signalled by shape not by emptiness
    if (rows(PHI2) == 0) return(J(1, 1, .))

    OUT = J(K, nhor + 1, .)
    for (h = 1; h <= nhor + 1; h++) {
        OUT[., h] = PHI2[., (h-1)*K + shockp]
    }
    if (cumul == 1) {
        for (h = 2; h <= nhor + 1; h++) {
            OUT[., h] = OUT[., h] + OUT[., h - 1]
        }
    }
    return(OUT)
}

// The same thing WITHOUT the counterfactual, so the two can be compared on
// exactly the same footing: same Cholesky factor, same multipliers.
real matrix gvar_cfbase(real scalar shockp, real scalar nhor,
                        real scalar vmeth, real scalar vexcl,
                        real scalar shrink, real scalar lam,
                        real scalar cumul)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Sg, Seta, PH, L, OUT, iG0
    real scalar K, lamout, h

    m  = gvar_MODEL
    K  = m.K
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    iG0  = gvar_inv(m.G0)
    Seta = iG0 * Sg * iG0'
    L    = cholesky(makesymmetric(Seta))
    if (hasmissing(L)) return(J(1, 1, .))

    PH  = gvar_phi(m.Fs, K, m.pmax, nhor)
    OUT = J(K, nhor + 1, .)
    for (h = 1; h <= nhor + 1; h++) {
        OUT[., h] = gvar_phih(PH, K, h - 1) * L[., shockp]
    }
    if (cumul == 1) {
        for (h = 2; h <= nhor + 1; h++) {
            OUT[., h] = OUT[., h] + OUT[., h - 1]
        }
    }
    return(OUT)
}

// ===========================================================================
// 2b. Sign- and zero-restricted impulse responses
//     (BGVAR src/irf.cpp compute_irf type 3, and the shocklist that
//      R/irf.R builds for it)
//
// Identification is by rotation: the impact matrix is G0^{-1} P0G Q, where
// P0G is the block-Cholesky factor already used by the structural GIRF and Q
// is orthonormal.  Q is drawn at random and kept only if the implied
// responses satisfy the restrictions.  Zero restrictions are imposed exactly,
// column by column, by the Arias, Rubio-Ramirez & Waggoner nullspace
// algorithm; sign restrictions are imposed by rejection.
//
// The identification is a SET, not a point: every accepted Q is observation-
// ally equivalent.  gvar_signrun therefore draws many and reports quantiles
// across them, which is what the set looks like.
// ===========================================================================

// Null space, exactly as BGVAR's get_nullspace: QR of M, then drop the
// leading rank(M) columns of Q.
real matrix gvar_nullsp(real matrix M)
{
    real matrix Q, R
    real scalar r, m

    m = rows(M)
    if (m == 0) return(J(0, 0, .))
    if (cols(M) == 0) return(I(m))

    qrd(M, Q, R)
    r = rank(M)
    if (r == 0)  return(Q)
    if (r >= m)  return(J(m, 0, .))
    return(Q[., (r + 1)::m])
}

// One attempt at a rotation.  Returns Q_bar, or a K x K of missing if the
// nullspace collapsed.
//
// Zind is the zero-restriction indicator, (K*H) x K: Zind[row, s] != 0 means
// shock s is restricted to produce a zero at that (variable, horizon) row.
// irf.cpp carries a full (K*H) x (K*H) matrix per shock, but every entry the
// documented interface can produce is a 1 on the diagonal, so the matrix is
// a selection of rows and this indicator says exactly the same thing.  The
// product Ztemp * irf_restr[., idx] is then simply irf_restr[selected, idx].
// (irf.R has a second branch for ratio restrictions which reuses an
// uninitialised row index; it is unreachable from add_shockinfo and is not
// reproduced -- see gvar methods.)
real matrix gvar_signdraw(real matrix irf_restr, real matrix Zind,
                          real colvector sorder, real colvector nozero,
                          real colvector cflag, real colvector xunit,
                          real scalar Nunits, real scalar K)
{
    real matrix Q, Qbar, Qc, Rq, randMat, Zs, Rr, R2, NU
    real colvector idx, zrows, x_j, q_j, nz
    real scalar cc, Kidx, i, dv, Nrestr

    Q      = I(K)
    Qbar   = I(K)
    Nrestr = rows(Zind)
    // irf.cpp sorts the whole cube by shock_order before the attempt loop
    Zs     = Zind[., sorder]

    for (cc = 1; cc <= Nunits; cc++) {
        idx  = select((1::K), xunit :== cc)
        Kidx = rows(idx)
        if (Kidx == 0) continue
        // only blocks that carry a shock are rotated; the rest keep the raw
        // covariance block, exactly as gvar_p0g leaves them
        if (cflag[cc] != 1) continue

        randMat = rnormal(Kidx, Kidx, 0, 1)

        if (nozero[cc] == 1) {
            // no zero restrictions in this block: a plain QR rotation
            qrd(randMat, Qc, Rq)
        }
        else {
            Qc = J(Kidx, Kidx, 0)
            for (i = 1; i <= Kidx; i++) {
                zrows = select((1::Nrestr), Zs[., idx[i]] :!= 0)

                Rr = J(0, Kidx, .)
                if (rows(zrows) > 0) {
                    Rr = Rr \ irf_restr[zrows, idx]
                }
                if (i > 1) {
                    // orthogonality to the columns already fixed
                    R2 = Qc[., 1::(i-1)]'
                    Rr = Rr \ R2
                }

                NU = gvar_nullsp(Rr')
                if (cols(NU) == 0) return(J(K, K, .))

                x_j = randMat[., i]
                nz  = NU' * x_j
                dv  = nz' * nz
                if (dv <= 0) return(J(K, K, .))
                q_j = NU * (nz / sqrt(dv))
                Qc[., i] = q_j
            }
        }
        Q[idx, idx] = Qc
    }

    // undo the shock ordering: column i of Q belongs to shock sorder[i]
    for (i = 1; i <= K; i++) {
        Qbar[., sorder[i]] = Q[., i]
    }
    return(Qbar)
}

// The sign check of irf.cpp lines 193-210.  Returns 1 if every restricted
// shock column satisfies its signs on this draw.  The probabilities in Pcube
// are re-drawn every attempt, which is what makes prob() < 1 a PROBABILISTIC
// imposition rather than a weaker one.
real scalar gvar_signcheck(real matrix irf_check, real matrix Scube,
                           real matrix Pcube, real scalar K)
{
    real scalar kk, nn, Nrestr, getsum, chksum
    real colvector STemp, PTemp, prob, IrfTemp

    Nrestr = rows(Scube)
    for (kk = 1; kk <= K; kk++) {
        STemp = Scube[., kk]
        if (sum(abs(STemp)) <= 0) continue
        PTemp = Pcube[., kk]
        prob  = J(Nrestr, 1, 0)
        for (nn = 1; nn <= Nrestr; nn++) {
            if (PTemp[nn] > runiform(1, 1)) prob[nn] = 1
        }
        IrfTemp = sign(irf_check[., kk])
        getsum  = (IrfTemp :* prob)' * STemp
        chksum  = sum(abs(prob :* STemp))
        if (getsum != chksum) return(0)
    }
    return(1)
}

// Build the restriction cubes from the flat table the ado assembles, in the
// layout irf.R uses:
//   row (g-1)*K + v  is  variable v at the g-th distinct restriction horizon
//   Scube[row, s] = +1 / -1     Pcube[row, s] = probability
//   Zind[row, s]  = 1 if shock s must produce a zero there
//
// RES columns: 1 shock position, 2 restricted variable, 3 sign (+1/-1/0),
//              4 horizon as the user gave it (1 = impact), 5 probability.
// The caller guarantees horizon 1 is present, because the own-shock
// normalisation below has nowhere to go otherwise.
void gvar_signcubes(real matrix RES, real scalar K,
                    real matrix Scube, real matrix Pcube, real matrix Zind,
                    real colvector horz, real colvector sorder,
                    real colvector nozero, real colvector cflag,
                    real colvector xunit, real scalar Nunits)
{
    real scalar H, Nrestr, q, s, v, g, row, cc, i, Kidx, best, bi, g1

    real colvector idx, zsum, used

    // distinct horizons, ascending
    horz   = sort(uniqrows(RES[., 4]), 1)
    H      = rows(horz)
    Nrestr = K * H

    Scube = J(Nrestr, K, 0)
    Pcube = J(Nrestr, K, 0)
    Zind  = J(Nrestr, K, 0)

    // which blocks carry a shock (irf.R's shock.cidx)
    cflag = J(Nunits, 1, 0)
    for (q = 1; q <= rows(RES); q++) {
        cflag[xunit[RES[q, 1]]] = 1
    }

    // the own-shock normalisation of irf.R: every shocked variable responds
    // positively to its own shock on impact, with probability one
    g1 = 0
    for (i = 1; i <= H; i++) {
        if (horz[i] == 1) g1 = i
    }
    if (g1 > 0) {
        for (q = 1; q <= rows(RES); q++) {
            s = RES[q, 1]
            Scube[(g1 - 1) * K + s, s] = 1
            Pcube[(g1 - 1) * K + s, s] = 1
        }
    }

    for (q = 1; q <= rows(RES); q++) {
        s = RES[q, 1]
        v = RES[q, 2]
        g = 0
        for (i = 1; i <= H; i++) {
            if (horz[i] == RES[q, 4]) g = i
        }
        if (g == 0) continue
        row = (g - 1) * K + v
        if (RES[q, 3] == 0) {
            Zind[row, s] = 1
        }
        else {
            Scube[row, s] = RES[q, 3]
            Pcube[row, s] = RES[q, 5]
        }
    }

    // shock_order: within each block, the shocks carrying the most zero
    // restrictions are solved first.  The nullspace algorithm shrinks the
    // feasible space as it goes, so the tightest column has to be placed
    // while the space is still large enough to hold it.
    sorder = (1::K)
    nozero = J(Nunits, 1, 1)
    for (cc = 1; cc <= Nunits; cc++) {
        idx  = select((1::K), xunit :== cc)
        Kidx = rows(idx)
        if (Kidx == 0) continue
        zsum = J(Kidx, 1, 0)
        for (i = 1; i <= Kidx; i++) {
            zsum[i] = sum(abs(Zind[., idx[i]]))
        }
        if (sum(zsum) > 0) nozero[cc] = 0

        // descending selection sort; ties keep the original order, as R's
        // sort(decreasing=TRUE) does
        used = J(Kidx, 1, 0)
        for (i = 1; i <= Kidx; i++) {
            best = -1
            bi   = 1
            for (q = 1; q <= Kidx; q++) {
                if (used[q] == 0 & zsum[q] > best) {
                    best = zsum[q]
                    bi   = q
                }
            }
            used[bi]       = 1
            sorder[idx[i]] = idx[bi]
        }
    }
}

// ---------------------------------------------------------------------------
// Draw the identified set.
//
// RES     the flat restriction table described above
// nhor    reporting horizon (responses 0..nhor)
// shockp  which shock column to report (a position in x)
// ndraw   how many ACCEPTED rotations to collect
// maxtry  attempts allowed per accepted rotation (irf.cpp MaxTries)
// q1..q3  quantiles across the accepted set
//
// Returns a (3K) x (nhor+1) stack -- lower, median, upper -- of the response
// of every variable to the named shock, plus, through the by-reference
// arguments, how many rotations were accepted and how many attempts failed.
//
// Note there is no 1/sqrt(sigma_jj) scaling here: the rotation already gives
// unit structural shocks, exactly as irf.cpp returns Phi_h G0^{-1} P0G Q.
// ---------------------------------------------------------------------------
real matrix gvar_signrun(real matrix RES, real scalar nhor, real scalar shockp,
                         real scalar ndraw, real scalar maxtry,
                         real scalar vmeth, real scalar vexcl,
                         real scalar shrink, real scalar lam,
                         real scalar cumul,
                         real scalar q1, real scalar q2, real scalar q3,
                         real scalar nacc, real scalar nfail)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Sg, P0G, PH, irf_restr, Scube, Pcube, Zind, Qbar
    real matrix ACC, OUT, B0, IRFd, iG0
    real colvector horz, sorder, nozero, cflag, es
    real scalar K, Nunits, lamout, hmax, i, h, tries, ok, r, c

    m      = gvar_MODEL
    K      = m.K
    Nunits = m.N
    nacc   = 0
    nfail  = 0

    Sg  = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    gvar_signcubes(RES, K, Scube, Pcube, Zind, horz, sorder, nozero,
                   cflag, m.xunit, Nunits)

    // the block-Cholesky impact matrix, identical to the structural GIRF's
    P0G = gvar_p0g(Sg, m.xunit, Nunits, cflag)
    if (hasmissing(P0G)) return(J(0, 0, .))

    // Phi has to reach the furthest RESTRICTION horizon as well as the
    // furthest REPORTING horizon
    hmax = max((nhor, max(horz) - 1))
    PH   = gvar_phi(m.Fs, K, m.pmax, hmax)

    // irf_restr stacks the restricted horizons; the user's horizon 1 is the
    // impact response, so it indexes Phi_0
    iG0       = gvar_inv(m.G0)
    irf_restr = J(0, K, .)
    for (i = 1; i <= rows(horz); i++) {
        h = horz[i] - 1
        irf_restr = irf_restr \ (gvar_phih(PH, K, h) * iG0 * P0G)
    }

    es = J(K, 1, 0)
    es[shockp] = 1

    ACC = J((nhor + 1) * K, 0, .)
    for (i = 1; i <= ndraw; i++) {
        tries = 0
        ok    = 0
        while (ok == 0 & tries < maxtry) {
            tries = tries + 1
            Qbar  = gvar_signdraw(irf_restr, Zind, sorder, nozero, cflag,
                                  m.xunit, Nunits, K)
            if (hasmissing(Qbar)) continue
            if (gvar_signcheck(irf_restr * Qbar, Scube, Pcube, K)) ok = 1
        }
        if (ok == 0) {
            nfail = nfail + 1
            continue
        }
        nacc = nacc + 1

        B0   = iG0 * P0G * Qbar
        IRFd = gvar_irfstruct(K, nhor, PH, B0, es)
        if (cumul == 1) {
            for (h = 2; h <= cols(IRFd); h++) {
                IRFd[., h] = IRFd[., h] + IRFd[., h - 1]
            }
        }
        ACC = ACC, vec(IRFd)
    }

    if (nacc == 0) return(J(0, 0, .))

    OUT = J(3 * K, nhor + 1, .)
    for (r = 1; r <= (nhor + 1) * K; r++) {
        i = mod(r - 1, K) + 1
        c = floor((r - 1) / K) + 1
        OUT[i,           c] = gvar_quantile(ACC[r, .]', q1)
        OUT[K + i,       c] = gvar_quantile(ACC[r, .]', q2)
        OUT[2 * K + i,   c] = gvar_quantile(ACC[r, .]', q3)
    }
    return(OUT)
}

// Wrapper so the ado never has to declare Mata output arguments.
void gvar_signwrap(real matrix RES, real scalar nhor, real scalar shockp,
                   real scalar ndraw, real scalar maxtry,
                   real scalar vmeth, real scalar vexcl,
                   real scalar shrink, real scalar lam, real scalar cumul,
                   real scalar q1, real scalar q2, real scalar q3)
{
    real matrix OUT
    real scalar nacc, nfail

    nacc = nfail = 0
    OUT  = gvar_signrun(RES, nhor, shockp, ndraw, maxtry, vmeth, vexcl,
                        shrink, lam, cumul, q1, q2, q3, nacc, nfail)
    if (rows(OUT) == 0) {
        st_numscalar("r_nacc",  0)
        st_numscalar("r_nfail", nfail)
        return
    }
    st_matrix("r_sign", OUT)
    st_numscalar("r_nacc",  nacc)
    st_numscalar("r_nfail", nfail)
}

// ===========================================================================
// 3.  Forecast error variance decomposition  (Toolbox fevd.m)
// ===========================================================================
// Generalized FEVD of the variable selected by eslct, against every shock.
// NOTE: the generalized decomposition does NOT sum to one across shocks.

real matrix gvar_fevdvec(real scalar K, real scalar N, real matrix PH,
                         real matrix Sigma_u, real matrix G,
                         real colvector eslct0,
                         real scalar sgirf, real scalar n0)
{
    real scalar i, l
    real matrix Sg, Gg, P0, P0H, invG, invGS, FEVD, num, den, vslct, Phl
    real colvector eslct, scale, acc1
    real scalar acc2

    Sg = Sigma_u
    Gg = G

    if (sgirf == 1 | sgirf == 2) {
        P0  = cholesky(makesymmetric(Sg[1::n0, 1::n0]))
        P0H = I(K)
        P0H[1::n0, 1::n0] = gvar_inv(P0)
        Sg  = P0H * Sg * P0H'
        Gg  = P0H * Gg
    }

    eslct = abs(eslct0)
    vslct = I(K)
    invG  = gvar_inv(Gg)
    invGS = invG * Sg
    scale = 1 :/ diagonal(Sg)

    FEVD = J(K, N + 1, 0)
    num  = J(K, N + 1, 0)
    den  = J(K, N + 1, 0)

    for (i = 1; i <= N + 1; i++) {
        for (l = 1; l <= i; l++) {
            Phl  = gvar_phih(PH, K, l - 1)
            acc1 = ((eslct' * Phl * invGS * vslct) :^ 2)'
            num[., i] = num[., i] + acc1
            acc2 = (eslct' * Phl * invGS * invG' * Phl' * eslct)
            den[., i] = den[., i] + J(K, 1, 1) * acc2
        }
        FEVD[., i] = (scale :* num[., i]) :/ den[., i]
    }
    return(FEVD)
}

// Full K x K decomposition at every horizon, stacked as K x (K*(N+1)).
// Column block h holds, in row i and column j, the share of the h-step
// forecast error variance of variable i attributable to shock j.
real matrix gvar_fevdmat(real scalar K, real scalar N, real matrix PH,
                         real matrix Sigma_u, real matrix G,
                         real scalar sgirf, real scalar n0)
{
    real scalar h
    real matrix Sg, Gg, P0, P0H, invGS, A, num, accm, out, den, Phl

    Sg = Sigma_u
    Gg = G
    if (sgirf == 1 | sgirf == 2) {
        P0  = cholesky(makesymmetric(Sg[1::n0, 1::n0]))
        P0H = I(K)
        P0H[1::n0, 1::n0] = gvar_inv(P0)
        Sg  = P0H * Sg * P0H'
        Gg  = P0H * Gg
    }

    invGS = gvar_inv(Gg) * Sg

    num  = J(K, K, 0)
    accm = J(K, K, 0)
    out  = J(K, 0, 0)

    for (h = 0; h <= N; h++) {
        Phl  = gvar_phih(PH, K, h)
        A    = Phl * invGS
        num  = num + (A :^ 2)
        accm = accm + A * A'
        den  = J(1, K, 1) # diagonal(accm)
        out  = out, (num :/ den)
    }
    return(out)
}

// ===========================================================================
// 4.  Persistence profiles  (Toolbox pprofile.m)
// ===========================================================================
//   PP_h = diag( b' W Phi_h G^-1 S G^-1' Phi_h' W' b ) / diag( b' W G^-1 S G^-1' W' b )

real matrix gvar_pprofile(real scalar K, real scalar N, real matrix PH,
                          real matrix Sigma_u, real matrix G,
                          pointer(real matrix) colvector Wlink,
                          pointer(real matrix) colvector betan,
                          real colvector ecase, real scalar Nunits)
{
    real scalar n, i, r
    real matrix invG, invGS, Wm, bb, dnm, nm, out, blk, Phl
    real colvector dd

    invG  = gvar_inv(G)
    invGS = invG * Sigma_u
    out   = J(0, N + 1, 0)

    for (n = 1; n <= Nunits; n++) {
        bb = *betan[n]
        r  = cols(bb)
        if (r == 0) {
            continue
        }
        Wm = *Wlink[n]
        if (ecase[n] == 4 | ecase[n] == 2) {
            blk = bb[2::rows(bb), .]
        }
        else {
            blk = bb
        }
        dnm = blk' * Wm * invGS * invG' * Wm' * blk
        dd  = diagonal(dnm)
        for (i = 0; i <= N; i++) {
            Phl = gvar_phih(PH, K, i)
            nm  = blk' * Wm * Phl * invGS * invG' * Phl' * Wm' * blk
            if (i == 0) {
                out = out \ J(r, N + 1, 0)
            }
            out[(rows(out) - r + 1)::rows(out), i + 1] = diagonal(nm) :/ dd
        }
    }
    return(out)
}

// ===========================================================================
// 5.  Sign and zero restrictions  (BGVAR irf.cpp, type 3)
// ===========================================================================
// Draw an orthonormal Q by QR of a standard-normal matrix (block-wise when the
// restrictions are country-specific), enforce zero restrictions through the
// Arias-Rubio-Ramirez-Waggoner nullspace recursion, then accept if the sign
// pattern holds.  Returns 1 on success and fills Qb.

real matrix gvar_nullspace(real matrix M)
{
    real matrix Q, R, NU
    real scalar r, nc
    real colvector keep

    Q = J(rows(M), rows(M), 0)
    R = J(rows(M), cols(M), 0)
    qrd(M, Q, R)
    r  = rank(M)
    nc = cols(Q)
    if (r == 0) {
        return(Q)
    }
    if (r >= nc) {
        return(J(rows(Q), 0, 0))
    }
    keep = ((r + 1)::nc)
    NU   = Q[., keep]
    return(NU)
}

real scalar gvar_signrot(real scalar K, real matrix PH, real matrix G,
                         real matrix P0G,
                         real matrix Scube,   // K x K  sign pattern (+1/-1/0)
                         real matrix Pcube,   // K x K  imposition probability
                         pointer(real matrix) colvector Zcube,  // zero restr
                         real colvector horz, // horizons at which restrictions bind
                         real scalar maxtries,
                         real matrix Qb)
{
    real scalar H, i, j, hh, icount, ok, kk, nn, Nr, getsum, chksum, dv
    real matrix irfr, Qm, randM, R1, R2, Rt, NU, Ztemp, irfchk, Zt
    real colvector xj, qj, sgn, prob, ST, PT
    real scalar cond

    H  = rows(horz)
    Nr = K * H

    irfr = J(0, K, 0)
    for (hh = 1; hh <= H; hh++) {
        irfr = irfr \ (gvar_phih(PH, K, horz[hh]) * gvar_inv(G) * P0G)
    }

    icount = 0
    cond   = 0
    Qb     = I(K)

    while (cond == 0 & icount < maxtries) {
        randM = J(K, K, 0)
        for (i = 1; i <= K; i++) {
            for (j = 1; j <= K; j++) {
                randM[i, j] = rnormal(1, 1, 0, 1)
            }
        }

        Qm = J(K, K, 0)
        for (i = 1; i <= K; i++) {
            Zt = *Zcube[i]
            Ztemp = J(0, K, 0)
            if (rows(Zt) > 0) {
                for (j = 1; j <= rows(Zt); j++) {
                    if (sum(abs(Zt[j, .])) > 0) {
                        Ztemp = Ztemp \ Zt[j, .]
                    }
                }
            }
            Rt = J(0, K, 0)
            if (rows(Ztemp) > 0) {
                R1 = Ztemp * irfr
                Rt = Rt \ R1
            }
            if (i > 1) {
                R2 = Qm[., 1::(i-1)]'
                Rt = Rt \ R2
            }
            if (rows(Rt) == 0) {
                NU = I(K)
            }
            else {
                NU = gvar_nullspace(Rt')
            }
            if (cols(NU) == 0) {
                Qm[., i] = J(K, 1, 0)
                Qm[i, i] = 1
                continue
            }
            xj = randM[., i]
            dv = (NU' * xj)' * (NU' * xj)
            if (dv <= 0) {
                Qm[., i] = J(K, 1, 0)
                Qm[i, i] = 1
                continue
            }
            qj = NU * (NU' * xj / sqrt(dv))
            Qm[., i] = qj
        }

        Qb     = Qm
        irfchk = irfr * Qb
        sgn    = J(K, 1, 1)
        for (kk = 1; kk <= K; kk++) {
            ST = Scube[., kk]
            PT = Pcube[., kk]
            if (sum(abs(ST)) > 0) {
                prob = J(Nr, 1, 0)
                for (nn = 1; nn <= Nr; nn++) {
                    if (PT[nn] > runiform(1, 1)) {
                        prob[nn] = 1
                    }
                }
                getsum = (sign(irfchk[., kk]) :* prob)' * ST
                chksum = sum(abs(prob :* ST))
                if (getsum == chksum) {
                    sgn[kk] = 1
                }
                else {
                    sgn[kk] = 0
                }
            }
        }
        cond   = 1
        for (kk = 1; kk <= K; kk++) {
            cond = cond * sgn[kk]
        }
        icount = icount + 1
    }

    ok = 0
    if (cond == 1) {
        ok = 1
    }
    return(ok)
}

// Block-local Cholesky impact matrix P0G used by the structural routines
real matrix gvar_p0g(real matrix Smat, real colvector xunit, real scalar Nunits,
                     real colvector cflag)
{
    real scalar cc, K
    real matrix P0G, sub
    real colvector idx

    K   = rows(Smat)
    P0G = I(K)
    for (cc = 1; cc <= Nunits; cc++) {
        idx = select((1::K), xunit :== cc)
        if (rows(idx) == 0) {
            continue
        }
        if (cflag[cc] == 1) {
            sub = cholesky(makesymmetric(Smat[idx, idx]))
            if (hasmissing(sub)) {
                return(J(K, K, .))
            }
            P0G[idx, idx] = sub
        }
        else {
            P0G[idx, idx] = Smat[idx, idx]
        }
    }
    return(P0G)
}

// ===========================================================================
// 6.  Historical decomposition  (BGVAR hd.R)
// ===========================================================================
// Returns a (K*(K+2+trend)) x T stack: for each of the K structural shocks the
// contribution to every variable, then the constant, optional trend, and the
// initial condition.  The residual part is recovered by the caller as
// x - sum(parts).

real matrix gvar_hd(real matrix Y,      // T x K observed (post-sample-trim)
                    real matrix Xreg,   // T x (K*p + 1 [+1]) regressors
                    real matrix ALPHA,  // K x (K*p + 1 [+1])
                    real matrix Sigma_u,
                    real matrix rot,    // K x K rotation (identity for chol)
                    real scalar K, real scalar p, real scalar trend,
                    real scalar align, real matrix strshock)
{
    real scalar T, nn, jj
    real matrix Sch, solveA, eps, Fcomp, invAbig, Icomp
    real matrix HDs, HDc, HDi, HDt, out, CC, TT, acc
    real colvector ebig

    T    = rows(Y)

    Sch    = cholesky(makesymmetric(Sigma_u))
    solveA = Sch * rot
    eps    = (Y - Xreg * ALPHA') * (gvar_inv(solveA))'
    strshock = eps

    Fcomp = gvar_companion(ALPHA[., 1::(K*p)], K, p)

    invAbig = J(K * p, K, 0)
    invAbig[1::K, .] = solveA
    Icomp = I(K), J(K, (p - 1) * K, 0)

    HDs = J(K * p, T * K, 0)
    HDc = J(K * p, T, 0)
    HDi = J(K * p, T, 0)
    HDt = J(K * p, T, 0)

    CC = J(K * p, 1, 0)
    CC[1::K] = ALPHA[., K*p + 1]
    TT = J(K * p, 1, 0)
    if (trend == 1) {
        TT[1::K] = ALPHA[., K*p + 2]
    }

    // Period 1.
    //
    // hd.R sets HDinit_big[,1] <- XX[1,1:(pmax*bigK)] and starts every other
    // recursion at nn = 2, so at nn it carries Fcomp^(nn-1) Z0 and omits the
    // s = 1 shock and constant.  The companion identity is
    //     Z_nn = Fcomp^nn Z0 + sum_{s=1..nn} Fcomp^(nn-s) (invA eps_s + CC)
    // so the source is one application of Fcomp short on the initial block
    // and one term short on the others.  The gap is
    //     Icomp Fcomp^(nn-1) [ (Fcomp - I) Z0 + invA eps_1 + CC ]
    // which is propagated rather than damped and, with unit roots present,
    // never dies away.  hd.R absorbs it into its trailing residual slice.
    //
    //   align 0  reproduce hd.R exactly
    //   align 1  start the recursions where the identity requires
    if (align == 1) {
        for (jj = 1; jj <= K; jj++) {
            ebig = J(K, 1, 0)
            ebig[jj] = eps[1, jj]
            HDs[., jj] = invAbig * ebig
        }
        HDc[., 1] = CC
        if (trend == 1) {
            HDt[., 1] = TT * Xreg[1, K*p + 2]
        }
        HDi[., 1] = Fcomp * (Xreg[1, 1::(K*p)]')
    }
    else {
        HDi[., 1] = Xreg[1, 1::(K*p)]'
    }

    for (nn = 2; nn <= T; nn++) {
        for (jj = 1; jj <= K; jj++) {
            ebig = J(K, 1, 0)
            ebig[jj] = eps[nn, jj]
            HDs[., (nn-1)*K + jj] = invAbig * ebig +
                                    Fcomp * HDs[., (nn-2)*K + jj]
        }
        HDi[., nn] = Fcomp * HDi[., nn-1]
        HDc[., nn] = CC + Fcomp * HDc[., nn-1]
        if (trend == 1) {
            // hd.R writes  HDtrend_big[,nn] <- TT + Fcomp %*% HDtrend_big[,nn-1]
            // which feeds a CONSTANT TT in every period.  The model's
            // deterministic input at period nn is d1 * trend_nn, so the
            // coefficient has to be scaled by the trend value.  Feeding TT
            // unscaled leaves an error that grows linearly in nn and is then
            // propagated by Fcomp -- it does not average out.
            if (align == 1) {
                HDt[., nn] = TT * Xreg[nn, K*p + 2] + Fcomp * HDt[., nn-1]
            }
            else {
                HDt[., nn] = TT + Fcomp * HDt[., nn-1]
            }
        }
    }

    // collapse the companion stack back to the K observable rows
    out = J(0, T, 0)
    for (jj = 1; jj <= K; jj++) {
        out = out \ (Icomp * HDs[., (0::(T-1)) :* K :+ jj])
    }
    out = out \ (Icomp * HDc)
    if (trend == 1) {
        out = out \ (Icomp * HDt)
    }
    out = out \ (Icomp * HDi)

    // hd.R closes with the leftover slice
    //   hd_array[,,(bigK+3+trend)] <- t(xdat) - apply(hd_array,c(1,2),sum)
    // which is what makes the decomposition add back to the data exactly.
    // It is not error: the recursion starts at nn = 2, so period 1 of every
    // component except the initial condition is zero by construction.
    acc = J(K, T, 0)
    for (jj = 1; jj <= rows(out) / K; jj++) {
        acc = acc + out[((jj-1)*K+1)::(jj*K), .]
    }
    out = out \ (Y' - acc)
    return(out)
}

// ===========================================================================
// 7.  Forecasting  (Toolbox forecast_GVAR.m, con_forecast_GVAR.m)
// ===========================================================================
// Recursive point forecasts with optional element-wise lower bounds.
// X is K x Traw with columns ordered in time; lb is K x 1 with missing where
// no bound applies.

real matrix gvar_forecast(real matrix X, real scalar maxlag,
                          real matrix Fs, real colvector d0, real colvector d1,
                          real scalar h, real colvector lb)
{
    real scalar K, Traw, jj, j, i
    real matrix xf, xlag
    real colvector fc

    K    = rows(X)
    Traw = cols(X)
    xf   = J(K, h, 0)

    // xlag[,1] is the most recent observation, [,2] the one before, ...
    xlag = J(K, maxlag, 0)
    for (j = 1; j <= maxlag; j++) {
        xlag[., j] = X[., Traw - j + 1]
    }

    for (jj = 1; jj <= h; jj++) {
        fc = d0 + d1 * (Traw - 1 + jj)
        for (j = 1; j <= maxlag; j++) {
            fc = fc + Fs[., ((j-1)*K+1)::(j*K)] * xlag[., j]
        }
        for (i = 1; i <= K; i++) {
            if (lb[i] < . & fc[i] < lb[i]) {
                fc[i] = lb[i]
            }
        }
        xf[., jj] = fc
        if (maxlag > 1) {
            xlag = fc, xlag[., 1::(maxlag-1)]
        }
        else {
            xlag = fc
        }
    }
    return(xf)
}

// Conditional forecasts  (Toolbox con_forecast_GVAR.m).
// D is K x hr with missing where the path is unrestricted.
real matrix gvar_confcast(real matrix X, real scalar maxlag,
                          real matrix Fs, real colvector d0, real colvector d1,
                          real matrix Seta, real scalar h, real matrix D)
{
    real scalar K, hr, i, j, nb, s1, s2, s3, s4, t, hmax
    real matrix mu, Cf, covm, sm, Cfi, Cfnew, Om, sm1, sm2
    real matrix mus, sub
    real colvector g, sel, lbv

    K  = rows(X)
    hr = cols(D)

    lbv = J(K, 1, .)
    mu  = gvar_forecast(X, maxlag, Fs, d0, d1, h, lbv)

    // selection of the restricted elements, stacked over the restriction horizon
    sel = J(0, 1, 0)
    g   = J(0, 1, 0)
    for (t = 1; t <= hr; t++) {
        for (i = 1; i <= K; i++) {
            if (D[i, t] < .) {
                sel = sel \ ((t - 1) * K + i)
                g   = g \ (D[i, t] - mu[i, t])
            }
        }
    }
    nb = rows(sel)
    if (nb == 0) {
        return(mu)
    }

    // companion form of the reduced-form GVAR
    Cf = J(maxlag * K, maxlag * K, 0)
    for (i = 1; i <= maxlag; i++) {
        Cf[1::K, ((i-1)*K+1)::(i*K)] = Fs[., ((i-1)*K+1)::(i*K)]
    }
    for (i = 1; i <= maxlag - 1; i++) {
        Cf[(i*K+1)::((i+1)*K), ((i-1)*K+1)::(i*K)] = I(K)
    }

    covm = J(maxlag * K, maxlag * K, 0)
    covm[1::K, 1::K] = Seta

    // The Toolbox sizes omega_Hbar_tilda at K*H_bar and then indexes it with
    // the FORECAST horizon in the final loop:
    //     for h=1:con_fhorz
    //         omega_Hbar_hL = omega_Hbar_tilda(sg1:sg2,:);
    //         mu_s(:,h) = mu(:,h) + omega_Hbar_hL*Psi_kr'*inv(...)*vec(g);
    // so it is only indexable when con_fhorz <= con_fhorz_restr.  Beyond the
    // restriction horizon the conditioning information still moves the
    // forecast, through the cross-horizon block omega[h, restricted], so the
    // right fix is to build omega out to max(H, H_bar) rather than to stop.
    // Same formula, wider index range.
    hmax = h
    if (hr > hmax) hmax = hr

    sm  = J(maxlag * K, maxlag * K, 0)
    Cfi = I(maxlag * K)
    Om  = J(K * hmax, K * hmax, 0)

    for (i = 1; i <= hmax; i++) {
        s1 = (i - 1) * K + 1
        s2 = (i - 1) * K + K
        sm = sm + Cfi * covm * Cfi'
        Cfi = Cfi * Cf
        Om[s1::s2, s1::s2] = sm[1::K, 1::K]
        Cfnew = Cf
        for (j = i + 1; j <= hmax; j++) {
            s3  = (j - 1) * K + 1
            s4  = (j - 1) * K + K
            sm1 = sm * Cfnew'
            sm2 = Cfnew * sm
            Om[s1::s2, s3::s4] = sm1[1::K, 1::K]
            Om[s3::s4, s1::s2] = sm2[1::K, 1::K]
            Cfnew = Cfnew * Cf
        }
    }

    sub = Om[sel, sel]
    mus = mu
    for (t = 1; t <= h; t++) {
        s1 = (t - 1) * K + 1
        s2 = (t - 1) * K + K
        mus[., t] = mu[., t] + Om[s1::s2, sel] * gvar_sinv(sub) * g
    }
    return(mus)
}

// ===========================================================================
// 8.  Trend / cycle decomposition  (Toolbox TCdecomp.m)
// ===========================================================================
//   C_0 = I ,  C_1 = -(C_0 - F_1) ,  C_j = sum_l C_{j-l} F_l
//   C(1) = sum_j C_j
//   x^p_st(t) = C(1) * sum_{s<=t} eta_s
//   v_t = x_t - x^p_st ; regress v_t on (1,t) [or on 1 only for restricted rows]

void gvar_tcdecomp(real matrix Fs, real matrix eta, real scalar maxlag,
                   real matrix X, real colvector restr, real scalar notrend,
                   real matrix xp, real matrix xc, real matrix xpst,
                   real matrix xpdt)
{
    real scalar K, T, Tx, j, l, t, sl, nmax
    real matrix C1, Cj, Cbuf, vt, xt, XO, a, a1, a2
    real colvector trend, one, noR, isR

    K  = rows(X)
    Tx = cols(X)
    T  = Tx - maxlag
    sl = 1000

    // C_1 = I ; C_2 = -(C_1 - F_1) ; C_j = sum_l C_{j-l} F_l   (Toolbox form).
    // Only the last maxlag blocks are needed, so a rolling buffer is used
    // instead of storing all 1000 blocks.  Cbuf block m holds C_{j-m}.
    C1   = I(K)
    Cj   = -(I(K) - Fs[., 1::K])
    C1   = C1 + Cj
    Cbuf = J(K, K * maxlag, 0)
    Cbuf[., 1::K] = Cj
    if (maxlag > 1) {
        Cbuf[., (K+1)::(2*K)] = I(K)
    }

    for (j = 3; j <= sl; j++) {
        Cj   = J(K, K, 0)
        nmax = min((maxlag, j - 1))
        for (l = 1; l <= nmax; l++) {
            Cj = Cj + Cbuf[., ((l-1)*K+1)::(l*K)] * Fs[., ((l-1)*K+1)::(l*K)]
        }
        C1 = C1 + Cj
        if (maxlag > 1) {
            Cbuf = Cj, Cbuf[., 1::(K*(maxlag-1))]
        }
        else {
            Cbuf = Cj
        }
        if (maxlag == 1 & j > 3) {
            if (max(abs(Cj)) < 1e-14) {
                break
            }
        }
    }

    xpst = J(K, T, 0)
    for (t = 1; t <= T; t++) {
        xpst[., t] = C1 * rowsum(eta[., 1::t])
    }

    xt = X[., (maxlag + 1)::Tx]
    vt = xt - xpst

    trend = J(T, 1, 0)
    for (t = 1; t <= T; t++) {
        trend[t] = maxlag + t - 1
    }
    one = J(T, 1, 1)

    a = J(2, K, 0)
    if (sum(restr) > 0) {
        noR = select((1::K), restr :== 0)
        isR = select((1::K), restr :== 1)
        if (rows(noR) > 0) {
            // a1 = (x_OLS1)\(vt(x_noRes_lineIndex,:))' -- MATLAB backslash
            // on a TALL data matrix is QR least squares, not the normal
            // equations, so qrsolve is the matching operator here.
            XO = one, trend
            a1 = qrsolve(XO, vt[noR, .]')
            a[., noR] = a1
        }
        if (rows(isR) > 0) {
            // a2 = (x_OLS2)\(vt(x_Res_lineIndex,:))'
            XO = one
            a2 = qrsolve(XO, vt[isR, .]')
            a[1, isR] = a2
            a[2, isR] = J(1, rows(isR), 0)
        }
    }
    else {
        if (notrend == 1) {
            // a = x_OLSt'
            XO = one
            a1 = qrsolve(XO, vt')
            a[1, .] = a1
            a[2, .] = J(1, K, 0)
        }
        else {
            // a = x_OLSt'
            XO = one, trend
            a  = qrsolve(XO, vt')
        }
    }

    xpdt = a[1, .]' * one' + a[2, .]' * trend'
    xp   = xpst + xpdt
    xc   = vt - xpdt
}

// ===========================================================================
// 9.  Connectedness / spillovers  (Diebold-Yilmaz, from the GFEVD)
// ===========================================================================
// Takes the K x K decomposition at one horizon, row-normalises it, and returns
// a (K+3) x (K+3) augmented table plus the summary indices.
//   row i, col j = share of variable i's FEV due to shock j
//   TO_j   = sum_{i != j} theta_ij
//   FROM_i = sum_{j != i} theta_ij
//   NET_j  = TO_j - FROM_j
//   TCI    = 100 * (1/K) * sum_{i != j} theta_ij

void gvar_spill(real matrix TH, real matrix tab,
                real colvector to_, real colvector from_, real colvector net_,
                real scalar tci)
{
    real scalar K, i, j, s
    real matrix T2

    K  = rows(TH)
    T2 = TH
    for (i = 1; i <= K; i++) {
        s = rowsum(T2[i, .])
        if (s != 0) {
            T2[i, .] = T2[i, .] :/ s
        }
    }
    T2 = T2 :* 100

    from_ = J(K, 1, 0)
    to_   = J(K, 1, 0)
    for (i = 1; i <= K; i++) {
        from_[i] = rowsum(T2[i, .]) - T2[i, i]
    }
    for (j = 1; j <= K; j++) {
        to_[j] = colsum(T2[., j]) - T2[j, j]
    }
    net_ = to_ - from_
    tci  = sum(from_) / K
    tab  = T2
}

// Index of each element of x_t within the list of distinct variable names,
// so a connectedness table can be aggregated by variable as well as by unit.
real colvector gvar_getxvarid()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real colvector out
    real scalar j, p

    m   = gvar_MODEL
    out = J(m.K, 1, 0)
    for (j = 1; j <= m.K; j++) {
        p = gvar_pos(m.vname, m.xname[j])
        if (p == 0) {
            // a global variable that is endogenous somewhere: it has no
            // entry in vname, so give it its own block at the end
            p = rows(m.vname) + gvar_pos(m.gvname, m.xname[j])
        }
        out[j] = p
    }
    return(out)
}

// Aggregate a K x K connectedness table into blocks.  Diebold & Yilmaz
// (2014) and BGVAR both sum the shares within a block AFTER the rows have
// been normalised, so the block table still has rows summing to 100.
real matrix gvar_spillagg(real matrix TAB, real colvector grp)
{
    real matrix OUT
    real scalar G, i, j, a, b, K

    K = rows(TAB)
    G = 0
    for (i = 1; i <= K; i++) {
        if (grp[i] > G) G = grp[i]
    }
    OUT = J(G, G, 0)
    for (i = 1; i <= K; i++) {
        for (j = 1; j <= K; j++) {
            a = grp[i]
            b = grp[j]
            OUT[a, b] = OUT[a, b] + TAB[i, j]
        }
    }
    // rows of the block table are averages over the members of the receiving
    // block, so the row still sums to 100 rather than to 100 times its size
    for (i = 1; i <= G; i++) {
        a = 0
        for (j = 1; j <= K; j++) {
            if (grp[j] == i) a = a + 1
        }
        if (a > 0) OUT[i, .] = OUT[i, .] / a
    }
    return(OUT)
}

// Positions of the n largest elements of v, descending, as a space-separated
// string ready for st_local.  Used to pick the leading contributors out of a
// decomposition with 130-odd shocks.
string scalar gvar_ranktop(real colvector v, real scalar n)
{
    real colvector o
    real scalar i, m
    string scalar s

    o = order(-v, 1)
    m = min((n, rows(v)))
    s = ""
    for (i = 1; i <= m; i++) {
        s = s + " " + strofreal(o[i])
    }
    return(strtrim(s))
}

// ===========================================================================
// 9a.  Shrinkage of Sigma_zeta  (Toolbox ShrinkageCorrLstar.m)
// ===========================================================================
// With K variables and only T quarters, Sigma_zeta has rank at most T.  In
// the 26-unit demo K = 136 and T = 134, so it is singular by construction and
// no Cholesky of the whole matrix exists.  That is not a defect of the data:
// it is arithmetic, and it is why any orthogonalised object -- an OIRF, a
// structural GIRF over a large leading block, an orthogonal FEVD -- needs the
// covariance regularised first.
//
// The Toolbox shrinks the CORRELATION matrix towards the identity with the
// intensity that minimises the expected quadratic loss, then rescales by the
// original standard deviations, so the variances are untouched.
//
// lam missing  -> compute the optimal intensity, as MATLAB does with an empty
//                 lambda_param; otherwise use the supplied value.
// lamout       -> the intensity actually used, returned to the caller.
real matrix gvar_shrinkcov(real matrix Sig, real scalar T, real scalar lam,
                           real scalar lamout)
{
    real scalar K, i, j, num, den1, den2
    real matrix DmatR, Rmat, DmatS, Rsh
    real colvector v, vsq, vm, sd

    K  = rows(Sig)
    sd = sqrt(diagonal(Sig))
    if (min(sd) <= 0) {
        lamout = .
        return(Sig)
    }
    DmatR = diag(1 :/ sd)
    Rmat  = DmatR * Sig * DmatR

    // the off-diagonal correlations, in MATLAB's column-major order
    v = J(0, 1, 0)
    for (j = 1; j <= K; j++) {
        for (i = 1; i <= K; i++) {
            if (i != j) v = v \ Rmat[i, j]
        }
    }
    vsq = v :^ 2
    vm  = (v :* (1 :- vsq)) / (2 * T)

    num  = colsum(v :* (v - vm))
    den1 = colsum(((1 :- vsq) :^ 2) / T)
    den2 = colsum((v - vm) :^ 2)

    lamout = lam
    if (lam >= .) {
        lamout = 1 - num / (den1 + den2)
        if (lamout < 0) lamout = 0
        if (lamout > 1) lamout = 1
    }

    Rsh   = lamout * I(K) + (1 - lamout) * Rmat
    DmatS = diag(sd)
    return(DmatS * Rsh * DmatS)
}

// Is the LEADING n x n block of A positive definite?  gvar_ispd() above
// answers the same question for a whole matrix; an orthogonalisation only
// ever factors the leading block, so this is the test that governs whether
// an OIRF or a structural GIRF can be computed at all.
real scalar gvar_ispdblock(real matrix A, real scalar n)
{
    real matrix B, C
    real rowvector ev

    if (n <= 0 | n > rows(A)) return(0)
    B = makesymmetric(A[1::n, 1::n])
    C = cholesky(B)
    if (hasmissing(C)) return(0)
    if (min(diagonal(C)) <= 1e-12) return(0)

    // The Cholesky test alone is NOT enough, and that was a live defect.  Mata's
    // cholesky() is more permissive than the MATLAB chol() the Toolbox wraps in
    // try/catch: it returned a factor for a Sigma_zeta of order 136 whose
    // smallest eigenvalue was -4.0e-20 -- a matrix with no Cholesky factor at
    // all.  The diagonal test does not catch it, because a rank-deficient pivot
    // comes out near sqrt(eps) and clears 1e-12 comfortably.
    //
    // The consequence was worse than an error: gvar hd returned rc 0 and a
    // decomposition built on that factor.  It refused correctly for the ML fit,
    // whose Sigma_zeta happened to be one rank worse, and proceeded for the
    // Bayesian fit -- so which estimator you used decided whether you got a
    // warning or a silently wrong answer.
    //
    // So the eigenvalues decide, on a RELATIVE tolerance: Sigma_zeta carries
    // whatever units the data are in, and an absolute cutoff would be a
    // different test for GDP in logs than for a interest rate in percent.
    ev = symeigenvalues(B)
    if (hasmissing(ev)) return(0)
    if (min(ev) <= 1e-12 * max(ev)) return(0)
    return(1)
}

// Transformation of the covariance before it is used  (transform_varcov.m)
//   meth 1  keep the sample matrix
//   meth 2  set every cross-unit covariance to zero (block diagonal)
//   meth 3  block diagonal, but leave one unit's cross-covariances free
// Method 2 imposes that shocks are uncorrelated across units, which is the
// assumption a good many GVAR papers make when they want the generalized
// responses to be interpretable as country-specific.
real matrix gvar_transformvcov(real matrix Sig, real scalar meth,
                               real scalar exclunit)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix S
    real scalar i, j, K, ci, cj

    if (meth == 1) return(Sig)

    m = gvar_MODEL
    S = Sig
    K = rows(Sig)
    for (i = 1; i <= K; i++) {
        ci = m.xunit[i]
        for (j = 1; j <= K; j++) {
            cj = m.xunit[j]
            if (ci == cj) continue
            if (meth == 3 & (ci == exclunit | cj == exclunit)) continue
            S[i, j] = 0
        }
    }
    return(S)
}

// The covariance the dynamic routines should use.  gvar.m does the two steps
// in this order and no other:
//     pe_varcov_tx = transform_varcov(pe_meth, pe_country_exc, Sigma_zeta, .)
//     pe_varcov    = ShrinkageCorrLstar(pe_varcov_tx, cols(zeta), lambda)
// T is cols(zeta), not the number of country-model observations.
real matrix gvar_sigmause(real scalar meth, real scalar exclunit,
                          real scalar shrink, real scalar lam,
                          real scalar lamout)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Stx

    m      = gvar_MODEL
    lamout = .
    Stx    = gvar_transformvcov(m.Szeta, meth, exclunit)
    if (shrink == 0) return(Stx)
    return(gvar_shrinkcov(Stx, cols(m.zeta), lam, lamout))
}

// Is the covariance that WOULD be used positive definite over its leading
// n0 block?  gvar.m runs exactly this test, with chol(), before an OIRF and
// refuses to proceed without shrinkage when it fails.
real scalar gvar_sigmapd(real scalar meth, real scalar exclunit,
                         real scalar shrink, real scalar lam, real scalar n0)
{
    real matrix S
    real scalar lamout

    S = gvar_sigmause(meth, exclunit, shrink, lam, lamout)
    return(gvar_ispdblock(S, n0))
}

// Sign identification needs a Cholesky factor of every SHOCKED unit's block,
// not of a leading block, because gvar_p0g factors each shocked block on its
// own.  Returns the index of the first unit whose block has no factor, or 0
// if every one of them does.
real scalar gvar_signpd(real matrix RES, real scalar vmeth, real scalar vexcl,
                        real scalar shrink, real scalar lam)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Sg, sub, C
    real colvector idx, cflag
    real scalar q, cc, lamout

    m  = gvar_MODEL
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    cflag = J(m.N, 1, 0)
    for (q = 1; q <= rows(RES); q++) {
        cflag[m.xunit[RES[q, 1]]] = 1
    }

    for (cc = 1; cc <= m.N; cc++) {
        if (cflag[cc] != 1) continue
        idx = select((1::m.K), m.xunit :== cc)
        if (rows(idx) == 0) continue
        sub = Sg[idx, idx]
        C   = cholesky(makesymmetric(sub))
        if (hasmissing(C))            return(cc)
        if (min(diagonal(C)) <= 1e-12) return(cc)
    }
    return(0)
}

// Is the covariance used to GENERATE the bootstrap draws positive definite?
// Only relevant when resampling in orthogonalised space (shuffleflag == 0).
real scalar gvar_dgpd(real scalar vmeth, real scalar vexcl,
                      real scalar dgshrink, real scalar dglam)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix S
    real scalar lamout

    m = gvar_MODEL
    S = gvar_transformvcov(m.Szeta, vmeth, vexcl)
    if (dgshrink == 1) S = gvar_shrinkcov(S, cols(m.zeta), dglam, lamout)
    return(gvar_ispdblock(S, rows(S)))
}

// Rank of Sigma_zeta, so a command can say why an orthogonalisation failed.
real scalar gvar_szetarank()
{
    external struct gvarmodel scalar gvar_MODEL
    return(rank(gvar_MODEL.Szeta))
}

// ===========================================================================
// 9b.  Drivers for the dynamic-analysis subcommands
// ===========================================================================
// These take the solved model out of gvar_MODEL and hand back one matrix, so
// the ado layer never touches the struct.  Every one of them uses the same
// Phi_h recursion, so an IRF, a FEVD and a persistence profile computed at
// the same horizon are guaranteed to come from identical dynamics.
//
// The covariance handed to irf/fevd/pprofile is Sigma_ZETA, the covariance of
// the stacked country-model residuals, NOT Sigma_eta of the reduced form.
// gvar.m calls
//     IRFMAT = irf(Ky,N,PHI,pe_varcov,H0,eslct,sgirfflag,Sigma_zeta0)
//     PPres  = pprofile(PHI,pe_varcov,H0,Wy,beta_norm_gx,N,...)
// with pe_varcov built from Sigma_zeta, and irf.m then forms G\Sigma_u.
// Passing Sigma_eta instead applies G0^{-1} twice and mixes the shocks.
// Note that this cannot be caught by checking PP(0) = 1: at h = 0 the
// numerator and denominator of a persistence profile share the same Sigma,
// so the profile starts at one whichever covariance is supplied.

// ---------------------------------------------------------------------------
// Reordering of the GVAR  (reorder_GVAR.m)
//
// A structural GIRF orthogonalises the LEADING block of the system, so which
// variables sit at the front is the identifying assumption.  reorder_GVAR.m
// builds nyorder, a permutation of 1..K, from
//     firstcountries   the units to move to the front, in order
//     newordervars     the variable order within each of those units
// then permutes H0, every C_l and Sigma_zeta on both dimensions, and sets
//     sumk0        = total endogenous variables of the first countries
//     Sigma_zeta0  = Sigma_zetas(1:sumk0, 1:sumk0)
// irf.m then factors that leading block.  So n0 is DERIVED from the ordering;
// it is never a number the user supplies.
//
// The Toolbox permutes H0 and C and recomputes the reduced form.  This does
// the same rather than permuting F directly, even though
// (P G0 P')^-1 (P H_l P') = P F_l P' makes the two identical, so that the
// arithmetic path matches the source exactly.
//
// ord is the K x 1 permutation: new element i is old element ord[i].
void gvar_applyorder(real colvector ord, real matrix G0o, real matrix Fso,
                     real matrix Szo)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Hso, Hl
    real scalar l, K

    m = gvar_MODEL
    K = m.K

    G0o = m.G0[ord, ord]
    Szo = m.Szeta[ord, ord]

    Hso = J(K, 0, 0)
    for (l = 1; l <= m.pmax; l++) {
        Hl  = m.Hs[., ((l-1)*K+1)::(l*K)]
        Hso = Hso, Hl[ord, ord]
    }

    // reduced form of the permuted system, as solve_GVAR does
    Fso = J(K, 0, 0)
    for (l = 1; l <= m.pmax; l++) {
        Fso = Fso, gvar_msolve(G0o, Hso[., ((l-1)*K+1)::(l*K)])
    }
}

// Inverse of a permutation: inv[ord[i]] = i
real colvector gvar_invperm(real colvector ord)
{
    real colvector iv
    real scalar i

    iv = J(rows(ord), 1, 0)
    for (i = 1; i <= rows(ord); i++) {
        iv[ord[i]] = i
    }
    return(iv)
}

// Impulse responses to the shock selected by eslct.
//   sgirf 0 generalized (Pesaran-Shin), 1 structural GIRF, 2 orthogonalised
//   cumul 1 accumulates the responses over the horizon
//   ord   K x 1 reordering, or a 0 x 1 vector for none.  Results are mapped
//         back to the model's own variable order before they are returned,
//         so the caller never has to think about the permutation.
real matrix gvar_irfrun(real colvector eslct, real scalar N,
                        real scalar sgirf, real scalar n0, real scalar cumul,
                        real scalar vmeth, real scalar vexcl,
                        real scalar shrink, real scalar lam,
                        real colvector ord)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix PH, IRF, Sg, G0o, Fso, Szo, OUT
    real colvector es, iv
    real scalar i, lamout

    m  = gvar_MODEL
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    if (rows(ord) == 0) {
        PH  = gvar_phi(m.Fs, m.K, m.pmax, N)
        IRF = gvar_irfmat(m.K, N, PH, Sg, m.G0, eslct, sgirf, n0)
    }
    else {
        gvar_applyorder(ord, G0o, Fso, Szo)
        Szo = gvar_transformvcov(Szo, vmeth, vexcl)
        if (shrink == 1) {
            Szo = gvar_shrinkcov(Szo, cols(m.zeta), lam, lamout)
        }
        es  = eslct[ord]
        PH  = gvar_phi(Fso, m.K, m.pmax, N)
        IRF = gvar_irfmat(m.K, N, PH, Szo, G0o, es, sgirf, n0)
        // map the responses back to the model's own variable order
        iv  = gvar_invperm(ord)
        IRF = IRF[iv, .]
    }

    if (cumul == 1) {
        for (i = 2; i <= cols(IRF); i++) {
            IRF[., i] = IRF[., i] + IRF[., i - 1]
        }
    }
    return(IRF)
}

// Generalized FEVD of one variable against every shock, K x (N+1).
real matrix gvar_fevdrun(real colvector eslct, real scalar N,
                         real scalar sgirf, real scalar n0,
                         real scalar vmeth, real scalar vexcl,
                         real scalar shrink, real scalar lam,
                         real colvector ord)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix PH, Sg, G0o, Fso, Szo, FV
    real colvector es, iv
    real scalar lamout

    m  = gvar_MODEL
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    if (rows(ord) == 0) {
        PH = gvar_phi(m.Fs, m.K, m.pmax, N)
        return(gvar_fevdvec(m.K, N, PH, Sg, m.G0, eslct, sgirf, n0))
    }

    gvar_applyorder(ord, G0o, Fso, Szo)
    Szo = gvar_transformvcov(Szo, vmeth, vexcl)
    if (shrink == 1) {
        Szo = gvar_shrinkcov(Szo, cols(m.zeta), lam, lamout)
    }
    es = eslct[ord]
    PH = gvar_phi(Fso, m.K, m.pmax, N)
    FV = gvar_fevdvec(m.K, N, PH, Szo, G0o, es, sgirf, n0)
    // rows of FV are indexed by SHOCK, so undo the permutation there too
    iv = gvar_invperm(ord)
    return(FV[iv, .])
}

// The full K x K decomposition at one horizon.
real matrix gvar_fevdtab(real scalar N, real scalar sgirf, real scalar n0,
                         real scalar vmeth, real scalar vexcl,
                         real scalar shrink, real scalar lam,
                         real colvector ord)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix PH, FM, Sg, G0o, Fso, Szo, B
    real colvector iv
    real scalar lamout

    m  = gvar_MODEL
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    if (rows(ord) == 0) {
        PH = gvar_phi(m.Fs, m.K, m.pmax, N)
        FM = gvar_fevdmat(m.K, N, PH, Sg, m.G0, sgirf, n0)
        return(FM[., (N * m.K + 1)::((N + 1) * m.K)])
    }

    gvar_applyorder(ord, G0o, Fso, Szo)
    Szo = gvar_transformvcov(Szo, vmeth, vexcl)
    if (shrink == 1) {
        Szo = gvar_shrinkcov(Szo, cols(m.zeta), lam, lamout)
    }
    PH = gvar_phi(Fso, m.K, m.pmax, N)
    FM = gvar_fevdmat(m.K, N, PH, Szo, G0o, sgirf, n0)
    B  = FM[., (N * m.K + 1)::((N + 1) * m.K)]
    iv = gvar_invperm(ord)
    return(B[iv, iv])
}

// Persistence profiles of every cointegrating relation in the model.
// Row block n holds the r_n profiles of unit n; the first two columns of the
// returned matrix identify the unit and the relation within it.
real matrix gvar_pprun(real scalar N, real scalar vmeth, real scalar vexcl,
                       real scalar shrink, real scalar lam)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix PH, PP, ID, Sg
    real scalar i, j, r, nr, lamout

    m  = gvar_MODEL
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)
    PH = gvar_phi(m.Fs, m.K, m.pmax, N)
    PP = gvar_pprofile(m.K, N, PH, Sg, m.G0, m.Wlink, m.ben,
                       m.ecase, m.N)

    ID = J(0, 2, .)
    for (i = 1; i <= m.N; i++) {
        r = m.rnk[i]
        for (j = 1; j <= r; j++) {
            ID = ID \ (i, j)
        }
    }
    nr = rows(PP)
    if (rows(ID) != nr) {
        return(J(0, 0, .))
    }
    return(ID, PP)
}

// Diebold-Yilmaz connectedness from the generalized FEVD at horizon N.
// Returns the K x K row-normalised table with four extra columns:
//   K+1 from  K+2 to  K+3 net  K+4 total connectedness index (row 1 only)
real matrix gvar_spillrun(real scalar N, real scalar sgirf, real scalar n0,
                          real scalar vmeth, real scalar vexcl,
                          real scalar shrink, real scalar lam,
                          real colvector ord)
{
    real matrix TH, tab, out
    real colvector to_, from_, net_
    real scalar tci, K

    TH  = gvar_fevdtab(N, sgirf, n0, vmeth, vexcl, shrink, lam, ord)
    K   = rows(TH)
    tab = J(0, 0, .)
    to_ = J(0, 1, .)
    from_ = J(0, 1, .)
    net_  = J(0, 1, .)
    tci   = .
    gvar_spill(TH, tab, to_, from_, net_, tci)

    out = tab, from_, to_, net_, (tci \ J(K - 1, 1, .))
    return(out)
}

// The connectedness table aggregated into blocks.
//   mode 0 no aggregation (K x K)
//   mode 1 by unit
//   mode 2 by variable
// Kept in the engine so the ado never has to subscript the result of a
// function call, which Mata refuses to compile.
real matrix gvar_spillblock(real scalar N, real scalar sgirf, real scalar n0,
                            real scalar mode, real scalar vmeth,
                            real scalar vexcl, real scalar shrink,
                            real scalar lam, real colvector ord)
{
    real matrix TH

    TH = gvar_fevdtab(N, sgirf, n0, vmeth, vexcl, shrink, lam, ord)
    // row-normalise to 100 first, exactly as gvar_spill does
    TH = gvar_rownorm100(TH)
    if (mode == 1) return(gvar_spillagg(TH, gvar_getxunit()))
    if (mode == 2) return(gvar_spillagg(TH, gvar_getxvarid()))
    return(TH)
}

// ---------------------------------------------------------------------------
// Re-estimate every country VECMX* from a given window of the global vector
// and re-solve the GVAR.  This is the same code path the bootstrap walks, with
// a slice of X in place of a generated path, and it is factored out so that
// the bootstrap, the rolling windows and the hold-out evaluation cannot drift
// apart.
//
// The ranks and lag orders come from the full-sample specification: the caller
// decides whether that is the right thing, and the help says so wherever it
// matters.
//
// Returns 1 on success, 0 if any country model or the stacked system failed.
// ---------------------------------------------------------------------------
real scalar gvar_reestwin(real matrix Xw, struct gvarmodel scalar mb,
                          real matrix G0b, real matrix Hsb,
                          real colvector h0b, real colvector h1b,
                          real matrix Fsb, real colvector d0b,
                          real colvector d1b, real matrix zetab,
                          real matrix etab, real matrix Szb, real matrix Seb)
{
    real matrix Zi, Yi, Si, beta, alpha, Psi, eps, Om2, ecm, DX, dep
    real matrix Th, L0, Lm
    real matrix bduTh, bduL0, bduLm
    real colvector a0, a1, bdua0, bdua1, bki, bks
    pointer(real matrix) colvector bWl, bTh, bL0, bLm, ba0, ba1
    real scalar i, ml, bll, bai, bsb, bNS

    ml = mb.pmax
    beta = alpha = Psi = eps = Om2 = ecm = DX = dep = J(0, 0, .)
    Th = L0 = Lm = J(0, 0, .)
    a0 = a1 = J(0, 1, .)
    bll = bai = bsb = .

    for (i = 1; i <= mb.N; i++) {
        Zi = (*mb.Wlink[i]) * Xw
        Yi = Zi[1::mb.ki[i], .]'
        if (mb.ksi[i] > 0) {
            Si = Zi[(mb.ki[i] + 1)::rows(Zi), .]'
        }
        else {
            Si = J(rows(Yi), 0, 0)
        }

        gvar_mlcoint(Yi, Si, mb.lagord[i,1], mb.lagord[i,2], ml,
                     mb.ecase[i], mb.rnk[i], beta, alpha, Psi,
                     eps, Om2, ecm, DX, dep, bll, bai, bsb)
        if (rows(beta) == 0 | hasmissing(beta)) return(0)

        // A window can be too short WITHOUT producing a single missing value.
        // gvar_mlcoint falls back on a pseudo-inverse, so a regression with
        // more coefficients than observations returns finite numbers that mean
        // nothing.  Checking for missings therefore does not catch it, and a
        // rolling run over 12 observations would silently report an index.
        // eps is k_i x T, DX is T x nx, ecm is r_i x T, so the count of
        // coefficients per equation is cols(DX) + rows(ecm).
        if (cols(eps) <= cols(DX) + rows(ecm) + 5) return(0)

        gvar_vecx2varx(ml, mb.ki[i], mb.ksi[i], mb.lagord[i,1],
                       mb.lagord[i,2], mb.ecase[i], alpha, beta, Psi,
                       a0, a1, Th, L0, Lm)
        mb.a0[i] = &(a0[., .])
        mb.a1[i] = &(a1[., .])
        mb.Th[i] = &(Th[., .])
        mb.L0[i] = &(L0[., .])
        mb.Lm[i] = &(Lm[., .])
        mb.ep[i] = &(eps[., .])
        mb.be[i] = &(beta[., .])
        mb.al[i] = &(alpha[., .])
        mb.ben[i] = &(gvar_betanorm(beta, mb.rnk[i], mb.ecase[i]))
    }

    // The dominant block has to be appended here exactly as gvar_solvemodel()
    // does at :8177-8188, or the stacked system is short by the dominant
    // variables and gvar_stack() raises a 3200 conformability error -- which is
    // what every bootstrap did the moment the demo was respecified from
    // gendog() to dominant().  gvar solve worked throughout, so this only
    // surfaced on the reps path.
    //
    // The dominant-unit model is NOT re-estimated per replication: it is
    // conditioned on, so the same block is reused.  Locals first, because the
    // pointers have to outlive the expression that takes their address.
    bNS = mb.N
    bWl = mb.Wlink; bTh = mb.Th; bL0 = mb.L0; bLm = mb.Lm
    ba0 = mb.a0;    ba1 = mb.a1
    bki = mb.ki;    bks = mb.ksi
    if (mb.hasdu == 1) {
        bduTh = mb.duTh; bduL0 = mb.duL0; bduLm = mb.duLm
        bdua0 = mb.dua0; bdua1 = mb.dua1
        bNS = mb.N + 1
        bWl = bWl \ &(gvar_dulink(mb.K))
        bTh = bTh \ &bduTh
        bL0 = bL0 \ &bduL0
        bLm = bLm \ &bduLm
        ba0 = ba0 \ &bdua0
        ba1 = ba1 \ &bdua1
        bki = bki \ rows(mb.duylist)
        bks = bks \ mb.dunfb
    }

    gvar_stack(bNS, mb.K, ml, bWl, ba0, ba1, bTh, bL0,
               bLm, bki, bks, G0b, Hsb, h0b, h1b)
    gvar_reduce(Xw, ml, G0b, Hsb, h0b, h1b, Fsb, d0b, d1b,
                zetab, etab, Szb, Seb)
    if (hasmissing(Fsb)) return(0)
    return(1)
}

// ---------------------------------------------------------------------------
// The h-step forecast-error covariance, for h = 1..nh.
//
//   Omega(h) = sum_{j=0}^{h-1} Phi_j Sigma_eta Phi_j'
//
// This is the diagonal block of the Toolbox's omega_Hbar_tilda, which
// con_forecast_GVAR.m accumulates in companion form as
//   sm = sm + Cfi * covmtx * Cfi' ;  Cfi = Cfi * Cf
// and then reads the leading K x K corner of.  Accumulating Phi_j directly is
// the same series without the companion padding.
//
// NOTE the covariance is Sigma_ETA, not Sigma_zeta: the forecast error of x
// is a sum of reduced-form innovations.  This is the same distinction that
// separates gvar hd from gvar irf.
//
// Returns K x (K*nh); block h occupies columns ((h-1)K+1)..(hK).
// ---------------------------------------------------------------------------
real matrix gvar_fcomega(real scalar K, real scalar nh, real matrix PH,
                         real matrix Seta)
{
    real matrix OUT, acc, Pj
    real scalar h

    OUT = J(K, K * nh, 0)
    acc = J(K, K, 0)
    for (h = 1; h <= nh; h++) {
        Pj  = gvar_phih(PH, K, h - 1)
        acc = acc + Pj * Seta * Pj'
        OUT[., ((h-1)*K + 1)::(h*K)] = acc
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Rolling-window connectedness.
//
// This is NOT in any of the three reference implementations: none of them
// rolls the estimation window.  (The Toolbox's "window" is the trade-year
// window in build_wmat.m, which averages the flow data -- a different thing
// entirely.)  It is the standard rolling exercise of Diebold & Yilmaz (2012,
// 2014) applied to the GVAR, and it is marked as an addition in the help.
//
// For every window the WHOLE pipeline is redone on that window's data: the
// foreign variables are rebuilt from the same link matrices, every country
// VECMX* is re-estimated by reduced-rank ML, the GVAR is re-stacked and
// re-solved, and the generalized FEVD and the connectedness indices are
// recomputed.  The re-estimation is the same code path the bootstrap uses,
// with a window slice of X in place of a generated path.
//
// Two things are held at their full-sample values rather than re-selected in
// each window: the cointegrating RANKS and the LAG ORDERS.  Re-testing the
// rank in every window would make the index jump whenever a test flipped,
// which is a property of the test rather than of the connectedness.  The help
// says so, and gvar coint is there for anyone who wants to check.
//
// Returns one row per window:
//   1 first observation, 2 last observation, 3 observations used,
//   4 total connectedness index at the level by() asked for,
//   5 largest eigenvalue modulus,
//   6 the element-level index, always, so the two are never confused,
//   then, if grp is non-empty, the NET spillover of each block.
// ---------------------------------------------------------------------------
real matrix gvar_rollrun(real scalar win, real scalar stp, real scalar nhor,
                         real scalar sgirf, real scalar n0,
                         real scalar vmeth, real scalar vexcl,
                         real scalar shrink, real scalar lam,
                         real colvector grp,
                         real scalar nok, real scalar nbad)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m, mb
    real matrix Xw, OUT, row, TH, FM, PH, Sg, AGG, tab
    real matrix G0b, Hsb, Fsb, zetab, etab, Szb, Seb, Cbar
    real colvector h0b, h1b, d0b, d1b, ev, to_, from_, net_, gnet
    real scalar K, ml, T, t1, t2, i, g, G, lamout, tci
    real scalar j, a, rtci, bfr, fg

    m   = gvar_MODEL
    K   = m.K
    ml  = m.pmax
    T   = cols(m.X)
    nok = 0
    nbad = 0

    G = 0
    if (rows(grp) > 0) {
        for (i = 1; i <= rows(grp); i++) {
            if (grp[i] > G) G = grp[i]
        }
    }

    // 6 fixed columns (window, TCI at the by() level, eigenvalue, element
    // TCI) plus one NET column per block
    OUT = J(0, 6 + G, .)

    G0b = Hsb = Fsb = zetab = etab = Szb = Seb = J(0, 0, .)
    h0b = h1b = d0b = d1b = J(0, 1, .)

    for (t2 = win; t2 <= T; t2 = t2 + stp) {
        t1 = t2 - win + 1
        Xw = m.X[., t1::t2]

        mb = m
        if (gvar_reestwin(Xw, mb, G0b, Hsb, h0b, h1b, Fsb, d0b, d1b,
                          zetab, etab, Szb, Seb) == 0) {
            nbad = nbad + 1
            continue
        }

        Cbar = gvar_companion(Fsb, K, ml)
        // abs() of a complex vector is the modulus.  Third and last site of the
        // abs(Re(...)) defect; the others are at :8271 and :5891.  A sweep for
        // the pattern found all three, which is the argument for grepping the
        // whole file for a defect's SHAPE rather than fixing the instance that
        // happened to be under the debugger.
        ev   = sort(abs(eigenvalues(Cbar))', -1)
        if (rows(ev) == 0) {
            nbad = nbad + 1
            continue
        }

        Sg = gvar_transformvcov(Szb, vmeth, vexcl)
        if (shrink == 1) {
            Sg = gvar_shrinkcov(Sg, cols(zetab), lam, lamout)
        }
        PH = gvar_phi(Fsb, K, ml, nhor)
        FM = gvar_fevdmat(K, nhor, PH, Sg, G0b, sgirf, n0)
        if (hasmissing(FM)) {
            nbad = nbad + 1
            continue
        }
        TH = FM[., (nhor * K + 1)::((nhor + 1) * K)]

        tab = J(0, 0, .)
        to_ = from_ = net_ = J(0, 1, .)
        tci = .
        gvar_spill(TH, tab, to_, from_, net_, tci)

        // tci here is the ELEMENT-level index, sum(FROM)/K over all K
        // variables.  When the run is aggregated the reported index has to be
        // the BLOCK-level one, sum(FROM)/G on the aggregated table, because
        // that is what the non-rolling path reports for the same by() and the
        // two are genuinely different numbers: at block level a spillover
        // between two variables of the same country counts as "own", so the
        // block index is the lower of the two.  Reporting the element index
        // under by(unit) would silently compare unlike things across the
        // rolling and non-rolling paths.
        rtci = tci
        if (G > 0) {
            AGG  = gvar_spillagg(tab, grp)
            gnet = J(G, 1, .)
            bfr  = 0
            for (g = 1; g <= G; g++) {
                // TO block g, summed down its column excluding the diagonal
                a = 0
                for (j = 1; j <= G; j++) {
                    if (j != g) a = a + AGG[j, g]
                }
                // FROM block g, summed across its row
                fg      = rowsum(AGG[g, .]) - AGG[g, g]
                gnet[g] = a - fg
                bfr     = bfr + fg
            }
            rtci = bfr / G
        }

        row = (t1, t2, cols(Xw), rtci, ev[1], tci)
        if (G > 0) row = row, gnet'
        OUT = OUT \ row
        nok = nok + 1
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Recursive out-of-sample forecast evaluation.
//
// For each of the last H forecast origins the model is re-estimated on the
// data up to that origin ONLY, re-solved, and used to forecast forward.  The
// forecasts are then compared with what actually happened.  Nothing after an
// origin touches the estimation that produced its forecast.
//
// Why recursive rather than one split.  A single hold-out gives exactly one
// forecast per (variable, horizon), so there is nothing to average and no
// sampling variation to test against: a "root mean squared error" over one
// observation is just the absolute error, and a Diebold-Mariano statistic is
// undefined.  Rolling the origin gives H forecasts at each horizon, which is
// the setting those statistics are built for.  It costs H re-estimations.
//
// The predictive standard deviation is sqrt(Omega(h)[k,k]) with Omega(h) the
// forecast-error covariance the Toolbox builds in con_forecast_GVAR.m, so the
// log predictive score is BGVAR's lps() with a frequentist variance in place
// of the posterior one:
//     LPS = log phi(x_actual ; x_hat, sd)
//
// The benchmark is the no-change forecast x_hat = x_origin, the standard
// yardstick for macroeconomic series in levels.
//
// Returns one row per (variable, origin, horizon):
//   1 variable, 2 origin (last observation used), 3 horizon,
//   4 actual, 5 forecast, 6 error, 7 predictive sd,
//   8 log predictive score, 9 no-change forecast, 10 no-change error
// ---------------------------------------------------------------------------
real matrix gvar_evalrun(real scalar H, real scalar hmax,
                         real scalar vmeth, real scalar vexcl,
                         real scalar shrink, real scalar lam,
                         real scalar nori, real scalar nbad)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m, mb
    real matrix Xe, G0b, Hsb, Fsb, zetab, etab, Szb, Seb
    real matrix PH, OM, FC, OUT, BLK, Sg, iG0, Seta
    real colvector h0b, h1b, d0b, d1b, xlast
    real scalar K, T, Te, k, h, r, sd, act, fc, lamout, vv, zz, hh

    m    = gvar_MODEL
    K    = m.K
    T    = cols(m.X)
    nori = 0
    nbad = 0

    if (T - H < m.pmax + 10) return(J(0, 10, .))

    OUT = J(0, 10, .)
    G0b = Hsb = Fsb = zetab = etab = Szb = Seb = J(0, 0, .)
    h0b = h1b = d0b = d1b = J(0, 1, .)

    // origins T-H .. T-1; the last one forecasts a single step, to T
    for (Te = T - H; Te <= T - 1; Te++) {
        hh = T - Te
        if (hh > hmax) hh = hmax

        Xe = m.X[., 1::Te]
        mb = m
        if (gvar_reestwin(Xe, mb, G0b, Hsb, h0b, h1b, Fsb, d0b, d1b,
                          zetab, etab, Szb, Seb) == 0) {
            nbad = nbad + 1
            continue
        }

        // gvar_forecast indexes lb unconditionally, so a K-vector of missing
        // means "no bound" rather than an empty vector.  Its trend term is
        // d0 + d1*(Traw-1+j), and gvar_reduce anchors the trend at column-1,
        // so a held-out observation gets the same trend index it would have
        // had in the full sample -- the off-by-one that has to be right for
        // this to be a forecast of the same series.
        FC = gvar_forecast(Xe, m.pmax, Fsb, d0b, d1b, hh, J(K, 1, .))
        if (rows(FC) == 0) {
            nbad = nbad + 1
            continue
        }

        // the predictive variance uses Sigma_ETA, the reduced-form covariance
        Sg = gvar_transformvcov(Szb, vmeth, vexcl)
        if (shrink == 1) {
            Sg = gvar_shrinkcov(Sg, cols(zetab), lam, lamout)
        }
        iG0  = gvar_inv(G0b)
        Seta = iG0 * Sg * iG0'
        PH   = gvar_phi(Fsb, K, m.pmax, hh)
        OM   = gvar_fcomega(K, hh, PH, Seta)

        xlast = Xe[., Te]

        BLK = J(K * hh, 10, .)
        r   = 0
        for (k = 1; k <= K; k++) {
            for (h = 1; h <= hh; h++) {
                r   = r + 1
                act = m.X[k, Te + h]
                fc  = FC[k, h]
                vv  = OM[k, (h-1)*K + k]
                sd  = .
                if (vv > 0) sd = sqrt(vv)

                BLK[r, 1] = k
                BLK[r, 2] = Te
                BLK[r, 3] = h
                BLK[r, 4] = act
                BLK[r, 5] = fc
                BLK[r, 6] = act - fc
                BLK[r, 7] = sd
                // The log density is formed directly rather than as
                // ln(normalden(...)): at a long horizon the density itself
                // can underflow to zero, and ln(0) would report -inf.
                if (sd < . & sd > 0) {
                    zz = (act - fc) / sd
                    BLK[r, 8] = -0.5 * ln(2 * pi()) - ln(sd) - 0.5 * zz * zz
                }
                BLK[r, 9]  = xlast[k]
                BLK[r, 10] = act - xlast[k]
            }
        }
        OUT  = OUT \ BLK
        nori = nori + 1
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Aggregate the recursive evaluation for one variable at one horizon, across
// the forecast origins.  Kept in the engine so the ado never has to loop over
// thousands of matrix cells.
//
// Returns 1 origins used, 2 RMSE, 3 MAE, 4 bias, 5 RMSE of the no-change
// benchmark, 6 Theil's U, 7 mean log predictive score, 8 Diebold-Mariano
// statistic, 9 its two-sided p-value, 10 mean absolute error in BGVAR's
// per-cell sense.
//
// BGVAR's rmse() returns sqrt((y - yhat)^2), which is the ABSOLUTE error --
// there is no mean anywhere in it despite the name.  Column 10 reports that
// quantity so the two can be compared; column 2 is a real RMSE.
//
// The Diebold-Mariano loss differential is d = e^2 - e_benchmark^2, so a
// NEGATIVE statistic favours the GVAR.  The variance is a Newey-West estimate
// at lag h-1, the standard choice for an h-step-ahead loss differential
// (Diebold & Mariano 1995), with the Harvey, Leybourne & Newbold (1997)
// small-sample correction on top.
// ---------------------------------------------------------------------------
real rowvector gvar_evalstat(real matrix E, real scalar k, real scalar h)
{
    real colvector sel, e, eb, ls, d
    real scalar n, i, l, L, g0, gl, vd, dbar, dm, pv, w, hln
    real scalar rmse, rmseb, mae, bias, lps, theil

    sel = select((1::rows(E)), (E[., 1] :== k) :* (E[., 3] :== h))
    n   = rows(sel)
    if (n == 0) return(J(1, 10, .))

    e  = E[sel, 6]
    eb = E[sel, 10]
    ls = E[sel, 8]

    rmse  = sqrt(mean(e :* e))
    rmseb = sqrt(mean(eb :* eb))
    mae   = mean(abs(e))
    bias  = mean(e)
    theil = .
    if (rmseb > 0) theil = rmse / rmseb

    lps = .
    if (sum(ls :< .) > 0) {
        lps = mean(select(ls, ls :< .))
    }

    dm = pv = .
    d  = (e :* e) - (eb :* eb)
    if (n > 2) {
        dbar = mean(d)
        L    = h - 1
        if (L > n - 1) L = n - 1
        if (L < 0) L = 0
        g0 = 0
        for (i = 1; i <= n; i++) {
            g0 = g0 + (d[i] - dbar) ^ 2
        }
        g0 = g0 / n
        vd = g0
        for (l = 1; l <= L; l++) {
            gl = 0
            for (i = l + 1; i <= n; i++) {
                gl = gl + (d[i] - dbar) * (d[i - l] - dbar)
            }
            gl = gl / n
            w  = 1 - l / (L + 1)
            vd = vd + 2 * w * gl
        }
        if (vd > 0) {
            dm  = dbar / sqrt(vd / n)
            hln = (n + 1 - 2 * h + h * (h - 1) / n) / n
            if (hln > 0) {
                dm = dm * sqrt(hln)
                pv = 2 * ttail(n - 1, abs(dm))
            }
            else {
                dm = .
            }
        }
    }

    return((n, rmse, mae, bias, rmseb, theil, lps, dm, pv, mae))
}

// The whole evaluation table for a set of variables and horizons, one row per
// (variable, horizon), so the ado makes a single call.
//   1 variable, 2 horizon, then the ten columns of gvar_evalstat
real matrix gvar_evaltab(real matrix E, real colvector vpos, real scalar hmax)
{
    real matrix OUT
    real scalar i, h, r
    real rowvector s

    OUT = J(rows(vpos) * hmax, 12, .)
    r   = 0
    for (i = 1; i <= rows(vpos); i++) {
        for (h = 1; h <= hmax; h++) {
            r = r + 1
            s = gvar_evalstat(E, vpos[i], h)
            OUT[r, 1] = vpos[i]
            OUT[r, 2] = h
            OUT[r, 3::12] = s
        }
    }
    return(OUT)
}

// Forecast standard errors, K x nh: sqrt of the diagonal of Omega(h).
real matrix gvar_fcsd(real scalar nh, real scalar vmeth, real scalar vexcl,
                      real scalar shrink, real scalar lam)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Sg, Seta, PH, OM, OUT, iG0
    real scalar K, h, k, lamout, vv

    m  = gvar_MODEL
    K  = m.K
    Sg = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)

    // Sigma_ETA, not Sigma_zeta: the forecast error of x accumulates
    // reduced-form innovations
    iG0  = gvar_inv(m.G0)
    Seta = iG0 * Sg * iG0'
    PH   = gvar_phi(m.Fs, K, m.pmax, nh)
    OM   = gvar_fcomega(K, nh, PH, Seta)

    OUT = J(K, nh, .)
    for (h = 1; h <= nh; h++) {
        for (k = 1; k <= K; k++) {
            vv = OM[k, (h-1)*K + k]
            if (vv > 0) OUT[k, h] = sqrt(vv)
        }
    }
    return(OUT)
}

// Wrapper so the ado never declares Mata output arguments.
void gvar_evalwrap(real scalar H, real scalar hmax,
                   real scalar vmeth, real scalar vexcl,
                   real scalar shrink, real scalar lam)
{
    real matrix OUT
    real scalar nori, nbad

    nori = nbad = 0
    OUT  = gvar_evalrun(H, hmax, vmeth, vexcl, shrink, lam, nori, nbad)
    st_numscalar("r_nori", nori)
    st_numscalar("r_nbad", nbad)
    if (rows(OUT) > 0) st_matrix("r_eval", OUT)
}

// Wrapper so the ado never declares Mata output arguments.
void gvar_rollwrap(real scalar win, real scalar stp, real scalar nhor,
                   real scalar sgirf, real scalar n0,
                   real scalar vmeth, real scalar vexcl,
                   real scalar shrink, real scalar lam,
                   real colvector grp)
{
    real matrix OUT
    real scalar nok, nbad

    nok = nbad = 0
    OUT = gvar_rollrun(win, stp, nhor, sgirf, n0, vmeth, vexcl, shrink, lam,
                       grp, nok, nbad)
    st_numscalar("r_nok",  nok)
    st_numscalar("r_nbad", nbad)
    if (rows(OUT) > 0) st_matrix("r_roll", OUT)
}

real matrix gvar_rownorm100(real matrix TAB)
{
    real matrix T2
    real scalar i, s

    T2 = TAB
    for (i = 1; i <= rows(T2); i++) {
        s = rowsum(T2[i, .])
        if (s != 0) T2[i, .] = T2[i, .] :/ s
    }
    return(T2 :* 100)
}

// ===========================================================================
// 10.  The GVAR bootstrap  (Toolbox bootstrap_GVAR.m)
// ===========================================================================
// Resamples the recentred structural residuals in orthogonalised space,
// regenerates the global vector, rebuilds the foreign variables, re-estimates
// every country model, re-solves the GVAR, and recomputes the requested
// dynamic objects.  Unstable replications are discarded, up to a cap of 2B.
//
// This function is deliberately written to take the whole model struct so that
// EVERY step of the observed statistic is replicated -- see the bootstrap
// calibration rules in the stata-package skill.

real matrix gvar_bootdraw(real matrix zeta, real scalar shuffle,
                          real matrix cbvcov, real scalar mlag,
                          real scalar Traw)
{
    real scalar K, T, n
    real matrix zc, A, invA, etam, zb
    real colvector ev, idx

    K  = rows(zeta)
    T  = cols(zeta)
    zc = zeta :- (rowsum(zeta) / T)

    zb = J(K, Traw, 0)

    if (shuffle == 0) {
        A    = cholesky(makesymmetric(cbvcov))
        invA = gvar_inv(A)
        etam = invA * zc
        n    = K * T
        ev   = vec(etam)
        idx  = ceil(runiform(n, 1) :* n)
        // reassemble the K*T resampled innovations into a K x T block; the
        // particular reshape is immaterial because the draws are iid
        zb[., (mlag+1)::Traw] = A * rowshape(ev[idx], K)
    }
    else {
        idx = ceil(runiform(T, 1) :* T)
        zb[., (mlag+1)::Traw] = zc[., idx]
    }
    return(zb)
}

// ---------------------------------------------------------------------------
// The full model-level bootstrap  (bootstrap_GVAR.m)
//
// Every step of the observed statistic is replicated: the global vector is
// regenerated, the domestic and foreign blocks are rebuilt from it through
// the link matrices, every country model is re-estimated at its own
// (p, q, case, rank), the GVAR is re-stacked and re-solved, and the dynamic
// object is recomputed.  Replications whose solved GVAR is unstable are
// discarded and redrawn, up to the source's cap of 2B.
//
//   what 1 impulse responses      2 generalized FEVD      3 persistence
//        4 structural stability battery  (bootstrap_GVAR_ss.m)
//
// Returns three quantiles stacked vertically.  bootstrap_GVAR.m takes
// (0.05, 0.50, 0.95) for the dynamic objects; bootstrap_GVAR_ss.m takes
// (0.90, 0.95, 0.99) for the stability statistics, which are one-sided.
// nok counts the replications kept and ndisc those discarded as unstable.
real matrix gvar_bootdyn(real scalar B, real scalar shuffle, real scalar what,
                         real colvector eslct, real scalar Nh,
                         real scalar sgirf, real scalar n0,
                         real scalar vmeth, real scalar vexcl,
                         real scalar shrink, real scalar lam,
                         real scalar cumul,
                         real scalar q1, real scalar q2, real scalar q3,
                         real scalar dgshrink, real scalar dglam,
                         real scalar nok, real scalar ndisc)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m, mb
    real matrix zb, epsb, Xb, Zi, Yi, Si, ACC, OUT, ST, PHb, Sgb, cbv
    real matrix beta, alpha, Psi, eps, Om2, ecm, DX, dep
    pointer(real matrix) colvector bdep, brgr
    real colvector a0, a1
    real matrix Th, L0, Lm, G0b, Hsb, Fsb, zetab, etab, Szb, Seb, Cbar
    real colvector h0b, h1b, d0b, d1b, ev, qv
    real matrix Pef
    real matrix dduTh, dduL0, dduLm
    real colvector ddua0, ddua1, dki, dks
    pointer(real matrix) colvector dWl, dTh, dL0, dLm, da0, da1
    real scalar b, i, tries, maxB, K, ml, nr, nc, r, c, lamout, ok
    real scalar bll, bai, bsb, dNS

    m    = gvar_MODEL
    K    = m.K
    ml   = m.pmax
    maxB = 2 * B
    nok  = 0
    ndisc = 0
    ACC  = J(0, 0, .)

    // The covariance used to orthogonalise before iid resampling.  gvar.m
    // keeps this SEPARATE from the one used for the point estimate:
    //     if bootstrap_flag == 1 && shuffleflag == 0
    //         if use_shrinkedvcv_dg == 0 ; pe_varcov_dg = pe_varcov_tx
    //         elseif use_shrinkedvcv_dg == 1 ; ShrinkageCorrLstar(...)
    // so the transformation is shared but the shrinkage is not.  It is not
    // needed at all when whole date-columns are resampled, which is why the
    // source notes "the case of shuffleflag == 1 is dealt above".
    cbv = gvar_transformvcov(m.Szeta, vmeth, vexcl)
    if (shuffle == 0 & dgshrink == 1) {
        cbv = gvar_shrinkcov(cbv, cols(m.zeta), dglam, lamout)
    }

    beta = alpha = Psi = eps = Om2 = ecm = DX = dep = J(0, 0, .)
    bdep = J(m.N, 1, NULL)
    brgr = J(m.N, 1, NULL)
    bll = bai = bsb = .
    a0 = a1 = J(0, 1, .)
    Th = L0 = Lm = J(0, 0, .)
    G0b = Hsb = Fsb = zetab = etab = Szb = Seb = J(0, 0, .)
    h0b = h1b = d0b = d1b = J(0, 1, .)

    tries = 0
    for (b = 1; b <= B; b++) {
        ok = 0
        while (ok == 0 & tries < maxB) {
            tries = tries + 1

            zb   = gvar_bootdraw(m.zeta, shuffle, cbv, ml, cols(m.X))
            epsb = gvar_msolve(m.G0, zb)
            Xb   = gvar_bootpath(m.X, ml, m.Fs, m.d0, m.d1, epsb)

            mb = m
            for (i = 1; i <= m.N; i++) {
                Zi = (*m.Wlink[i]) * Xb
                Yi = Zi[1::m.ki[i], .]'
                if (m.ksi[i] > 0) {
                    Si = Zi[(m.ki[i] + 1)::rows(Zi), .]'
                }
                else {
                    Si = J(rows(Yi), 0, 0)
                }

                gvar_mlcoint(Yi, Si, m.lagord[i,1], m.lagord[i,2], ml,
                             m.ecase[i], m.rnk[i], beta, alpha, Psi,
                             eps, Om2, ecm, DX, dep, bll, bai, bsb)

                gvar_vecx2varx(ml, m.ki[i], m.ksi[i], m.lagord[i,1],
                               m.lagord[i,2], m.ecase[i], alpha, beta, Psi,
                               a0, a1, Th, L0, Lm)
                mb.a0[i] = &(a0[., .])
                mb.a1[i] = &(a1[., .])
                mb.Th[i] = &(Th[., .])
                mb.L0[i] = &(L0[., .])
                mb.Lm[i] = &(Lm[., .])
                mb.ep[i] = &(eps[., .])
                mb.be[i] = &(beta[., .])
                mb.al[i] = &(alpha[., .])
                mb.ben[i] = &(gvar_betanorm(beta, m.rnk[i], m.ecase[i]))
                if (what == 4 | what == 5) {
                    bdep[i] = &(dep[., .])
                    brgr[i] = &(DX[., .])
                }
            }

            // Append the dominant block, as gvar_solvemodel() does at
            // :8207-8218 and gvar_reestwin() now does too.  Without it the
            // stacked system is short by the dominant variables and
            // gvar_stack() raises 3200.  The dominant-unit model is
            // conditioned on rather than re-estimated, so the block is reused.
            dNS = m.N
            dWl = mb.Wlink; dTh = mb.Th; dL0 = mb.L0; dLm = mb.Lm
            da0 = mb.a0;    da1 = mb.a1
            dki = mb.ki;    dks = mb.ksi
            if (m.hasdu == 1) {
                dduTh = m.duTh; dduL0 = m.duL0; dduLm = m.duLm
                ddua0 = m.dua0; ddua1 = m.dua1
                dNS = m.N + 1
                dWl = dWl \ &(gvar_dulink(K))
                dTh = dTh \ &dduTh
                dL0 = dL0 \ &dduL0
                dLm = dLm \ &dduLm
                da0 = da0 \ &ddua0
                da1 = da1 \ &ddua1
                dki = dki \ rows(m.duylist)
                dks = dks \ m.dunfb
            }

            gvar_stack(dNS, K, ml, dWl, da0, da1, dTh, dL0,
                       dLm, dki, dks, G0b, Hsb, h0b, h1b)
            gvar_reduce(Xb, ml, G0b, Hsb, h0b, h1b, Fsb, d0b, d1b,
                        zetab, etab, Szb, Seb)

            Cbar = gvar_companion(Fsb, K, ml)
            // abs() of a complex vector is the MODULUS.  This was
            // abs(Re(eigenvalues(...))) -- the absolute value of the real part --
            // the same defect fixed at :8223, and this second site was missed
            // the first time.  Here it decides which bootstrap replications are
            // discarded as unstable, so it was under-reporting explosive draws.
            ev   = sort(abs(eigenvalues(Cbar))', -1)
            if (rows(ev) == 0) continue
            if (ev[1] > 1 + 1e-8) {
                ndisc = ndisc + 1
                continue
            }
            if (hasmissing(Fsb)) {
                ndisc = ndisc + 1
                continue
            }
            ok = 1
        }
        if (ok == 0) break

        // ---- the statistic, recomputed exactly as for the point estimate --
        mb.G0 = G0b
        mb.Fs = Fsb
        mb.Szeta = Szb
        Sgb = gvar_transformvcov(Szb, vmeth, vexcl)
        if (shrink == 1) {
            Sgb = gvar_shrinkcov(Sgb, cols(zetab), lam, lamout)
        }
        PHb = gvar_phi(Fsb, K, ml, Nh)

        if (what == 1) {
            ST = gvar_irfmat(K, Nh, PHb, Sgb, G0b, eslct, sgirf, n0)
            if (cumul == 1) {
                for (c = 2; c <= cols(ST); c++) {
                    ST[., c] = ST[., c] + ST[., c - 1]
                }
            }
        }
        else if (what == 2) {
            ST = gvar_fevdvec(K, Nh, PHb, Sgb, G0b, eslct, sgirf, n0)
        }
        else if (what == 3) {
            ST = gvar_pprofile(K, Nh, PHb, Sgb, G0b, mb.Wlink, mb.ben,
                               mb.ecase, mb.N)
        }
        else if (what == 4) {
            // structural_stability_tests on the re-estimated models, as
            // bootstrap_GVAR_ss.m does.  Nh carries the trimming fraction.
            ST = J(0, 10, .)
            for (i = 1; i <= m.N; i++) {
                for (c = 1; c <= m.ki[i]; c++) {
                    ST = ST \ gvar_ssrow(*bdep[i], *brgr[i], c, Nh)
                }
            }
        }
        else {
            // Empirical fluctuation processes, bootstrapped the same way.
            // Nh carries the window fraction h and n0 the process type, so
            // that only the ONE requested process is recomputed on each
            // replication rather than all eight -- with 136 equations the
            // difference is eightfold.
            ST = J(0, 1, .)
            for (i = 1; i <= m.N; i++) {
                for (c = 1; c <= m.ki[i]; c++) {
                    Pef = gvar_efpproc((*bdep[i])[., c], *brgr[i], n0, Nh)
                    if (rows(Pef) == 0) {
                        ST = ST \ J(1, 1, .)
                    }
                    else {
                        ST = ST \ gvar_efpstat(Pef, n0)
                    }
                }
            }
        }
        if (hasmissing(ST)) {
            ndisc = ndisc + 1
            continue
        }

        nok = nok + 1
        if (nok == 1) {
            nr  = rows(ST)
            nc  = cols(ST)
            ACC = J(nr * nc, 0, .)
        }
        ACC = ACC, vec(ST)
    }

    if (nok == 0) return(J(0, 0, .))

    // 5th percentile, median, 95th percentile, as bootstrap_GVAR.m takes them
    OUT = J(3 * nr, nc, .)
    for (r = 1; r <= nr * nc; r++) {
        qv = ACC[r, .]'
        i  = mod(r - 1, nr) + 1
        c  = floor((r - 1) / nr) + 1
        OUT[i,          c] = gvar_quantile(qv, q1)
        OUT[nr + i,     c] = gvar_quantile(qv, q2)
        OUT[2 * nr + i, c] = gvar_quantile(qv, q3)
    }
    return(OUT)
}

// One equation's structural stability battery, in the column order of
// gvar_stabtests: PKsup PKmsq Nyblom robNy QLR MW APW robQLR robMW robAPW.
real rowvector gvar_ssrow(real matrix DY, real matrix DX, real scalar j,
                          real scalar ccut)
{
    real rowvector kp, ny, sc

    kp = gvar_kraplob(DY[., j], DX)
    ny = gvar_nyblom(DY[., j], DX)
    sc = gvar_schow(DY[., j], DX, ccut)
    return((kp[1], kp[2], ny[1], ny[2], sc[1], sc[2], sc[3],
            sc[4], sc[5], sc[6]))
}

// Wrapper so the ado never declares Mata output arguments.
void gvar_bootwrap(real scalar B, real scalar shuffle, real scalar what,
                   real colvector eslct, real scalar Nh,
                   real scalar sgirf, real scalar n0,
                   real scalar vmeth, real scalar vexcl,
                   real scalar shrink, real scalar lam,
                   real scalar cumul,
                   real scalar q1, real scalar q2, real scalar q3,
                   real scalar dgshrink, real scalar dglam)
{
    real matrix OUT
    real scalar nok, ndisc

    nok = ndisc = 0
    OUT = gvar_bootdyn(B, shuffle, what, eslct, Nh, sgirf, n0,
                       vmeth, vexcl, shrink, lam, cumul, q1, q2, q3,
                       dgshrink, dglam, nok, ndisc)
    if (rows(OUT) == 0) OUT = J(1, 1, .)
    st_matrix("r_boot", OUT)
    st_numscalar("r_nok",   nok)
    st_numscalar("r_ndisc", ndisc)
}

// Regenerate the global vector from bootstrapped reduced-form innovations
real matrix gvar_bootpath(real matrix X, real scalar mlag, real matrix Fs,
                          real colvector d0, real colvector d1, real matrix eps)
{
    real scalar K, Traw, t, j
    real matrix Xb
    real colvector acc

    K    = rows(X)
    Traw = cols(X)
    Xb   = J(K, Traw, 0)
    Xb[., 1::mlag] = X[., 1::mlag]

    for (t = mlag + 1; t <= Traw; t++) {
        acc = J(K, 1, 0)
        for (j = 1; j <= mlag; j++) {
            acc = acc + Fs[., ((j-1)*K+1)::(j*K)] * Xb[., t-j]
        }
        Xb[., t] = d0 + d1 * (t - 1) + acc + eps[., t]
    }
    return(Xb)
}


// =========================================================================
// =====  from _gvar_mata_io.ado                                            
// =========================================================================


// ===========================================================================
// 1.  Build the model from a balanced long panel
// ===========================================================================
// DATA is (N*Traw) x V, sorted by unit then time, unit i occupying rows
// (i-1)*Traw+1 .. i*Traw.  A variable that is entirely missing for a unit is
// treated as absent for that unit, exactly as the Toolbox's dvflag does.

void gvar_build(real matrix DATA,
                string colvector cname,
                string colvector clong,
                string colvector vname,
                string colvector vlong,
                real colvector vtype,
                real scalar N,
                real scalar Traw,
                real colvector tvals,
                real scalar freq,
                string scalar idvar,
                string scalar tvar,
                real matrix dflag,
                real matrix fflag,
                string colvector gvname,
                real matrix gflag,
                real matrix GDATA)
{
    struct gvarmodel scalar m
    real scalar i, j, r0, r1, V

    V = cols(DATA)

    m.N     = N
    m.V     = V
    m.Traw  = Traw
    m.tvals = tvals
    m.freq  = freq
    m.idvar = idvar
    m.tvar  = tvar
    m.cname = cname
    m.clong = clong
    m.vname = vname
    m.vlong = vlong
    m.vtype = vtype

    m.dflag  = dflag
    m.fflag  = fflag
    m.gflag  = gflag
    m.gvname = gvname
    m.GDATA  = GDATA
    m.DATA0  = DATA

    m.ntypes = max(vtype)
    m.nyears = 1
    m.yrid   = J(Traw, 1, 1)

    // ---- per-unit raw blocks, before the endogenous/exogenous split --------
    m.Yi    = J(N, 1, NULL)
    m.ylist = J(N, 1, NULL)
    m.ki    = J(N, 1, 0)

    // NOTE: &varname points AT the variable, so a loop variable must never be
    // pointed to directly.  Subscripting yields an expression, hence a copy.
    for (i = 1; i <= N; i++) {
        r0 = (i - 1) * Traw + 1
        r1 = i * Traw
        m.Yi[i]    = &(DATA[r0::r1, .])
        m.ylist[i] = &(vname[., .])
        m.ki[i]    = V
    }

    m.hasforeign = 0
    m.estimated  = 0
    m.solved     = 0
    m.hastrend   = 0
    m.esttype    = ""
    m.psc        = 4
    m.pmax       = 1

    m.ecase  = J(N, 1, 3)
    m.rnk    = J(N, 1, 0)
    m.lagord = J(N, 2, 1)

    m.Wt   = J(m.ntypes, 1, NULL)
    m.Wsol = J(m.ntypes, 1, NULL)
    for (j = 1; j <= m.ntypes; j++) {
        m.Wt[j, 1] = &(gvar_wequal(N))
        m.Wsol[j]  = &(gvar_wequal(N))
    }

    m.aggw  = J(N, m.ntypes, 1)
    m.rname = J(0, 1, "")
    m.rmemb = J(N, 0, 0)

    external struct gvarmodel scalar gvar_MODEL
    gvar_MODEL = m
}

// ---------------------------------------------------------------------------
// 2.  Decide, per unit, which variables are endogenous and which foreign
//     counterparts enter as weakly exogenous
// ---------------------------------------------------------------------------
// dflag  : N x V  1 = variable is endogenous for that unit
// fflag  : N x V  1 = the foreign counterpart is weakly exogenous for that unit
// gflag  : N x G  0 = absent, 1 = weakly exogenous, 2 = endogenous
//          (mirrors the Toolbox's gvflag)

// Uses the flags stored by gvar_build().  Idempotent: it always rebuilds the
// unit models from the ORIGINAL per-unit data block, so it can be re-run after
// the weight matrices change.
void gvar_specify()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, j, g, N, V, G, Traw, k, r0, r1
    real matrix Yfull, Yb, Sb, dflag, fflag, gflag, GDATA, DATA0
    string colvector yl, sl, gvname
    real colvector sg
    pointer(real matrix) colvector FV

    m      = gvar_MODEL
    N      = m.N
    V      = m.V
    Traw   = m.Traw
    dflag  = m.dflag
    fflag  = m.fflag
    gflag  = m.gflag
    gvname = m.gvname
    GDATA  = m.GDATA
    DATA0  = m.DATA0
    G      = rows(gvname)

    // restore the untouched per-unit blocks so that gvar_specify() can be
    // re-run after the weight matrices change
    for (i = 1; i <= N; i++) {
        r0 = (i - 1) * Traw + 1
        r1 = i * Traw
        m.Yi[i] = &(DATA0[r0::r1, .])
    }

    // ---- foreign-variable blocks, one per domestic variable ---------------
    FV = J(V, 1, NULL)
    for (j = 1; j <= V; j++) {
        Yfull = J(Traw, N, .)
        for (i = 1; i <= N; i++) {
            Yfull[., i] = (*m.Yi[i])[., j]
        }
        if (m.nyears == 1) {
            FV[j] = &(gvar_foreignvar(Yfull, *m.Wt[m.vtype[j], 1]))
        }
        else {
            FV[j] = &(gvar_foreignvar_tv(Yfull, m.Wt[m.vtype[j], .]', m.yrid))
        }
    }

    // ---- assemble each unit model ------------------------------------------
    m.Si    = J(N, 1, NULL)
    m.slist = J(N, 1, NULL)
    m.sglob = J(N, 1, NULL)
    m.ksi   = J(N, 1, 0)

    m.xname  = J(0, 1, "")
    m.xcname = J(0, 1, "")
    m.xunit  = J(0, 1, 0)

    for (i = 1; i <= N; i++) {
        Yb = J(Traw, 0, 0)
        yl = J(0, 1, "")
        Sb = J(Traw, 0, 0)
        sl = J(0, 1, "")
        sg = J(0, 1, 0)

        for (j = 1; j <= V; j++) {
            if (dflag[i, j] == 1) {
                Yb = Yb, (*m.Yi[i])[., j]
                yl = yl \ m.vname[j]
            }
            if (fflag[i, j] == 1) {
                Sb = Sb, (*FV[j])[., i]
                sl = sl \ m.vname[j]
                sg = sg \ 0
            }
        }
        for (g = 1; g <= G; g++) {
            if (gflag[i, g] == 2) {
                Yb = Yb, GDATA[., g]
                yl = yl \ gvname[g]
            }
            if (gflag[i, g] == 1) {
                Sb = Sb, GDATA[., g]
                sl = sl \ gvname[g]
                sg = sg \ 1
            }
        }

        m.Yi[i]    = &(Yb[., .])
        m.ylist[i] = &(yl[., .])
        m.ki[i]    = cols(Yb)
        m.Si[i]    = &(Sb[., .])
        m.slist[i] = &(sl[., .])
        m.sglob[i] = &(sg[., .])
        m.ksi[i]   = cols(Sb)

        for (k = 1; k <= cols(Yb); k++) {
            m.xname  = m.xname  \ yl[k]
            m.xcname = m.xcname \ m.cname[i]
            m.xunit  = m.xunit  \ i
        }
    }

    // ---- the dominant unit's variables, appended at the END of x_t --------
    // The order matters.  gvar_linkmat computes each country's block offset by
    // summing ki over the units before it, so the country blocks have to come
    // first; and it finds a weakly exogenous variable by NAME anywhere in x_t,
    // so appending here is all that is needed for every country model to link
    // to the dominant variables.
    if (rows(m.dumark) >= G) {
        for (g = 1; g <= G; g++) {
            if (m.dumark[g] != 1) continue
            m.xname  = m.xname  \ gvname[g]
            m.xcname = m.xcname \ "dominant"
            m.xunit  = m.xunit  \ (N + 1)
        }
    }

    m.K = rows(m.xname)

    // ---- the global vector x_t (K x Traw) -----------------------------------
    m.X = J(0, Traw, 0)
    for (i = 1; i <= N; i++) {
        m.X = m.X \ (*m.Yi[i])'
    }
    if (rows(m.dumark) >= G) {
        for (g = 1; g <= G; g++) {
            if (m.dumark[g] == 1) m.X = m.X \ GDATA[., g]'
        }
    }

    // re-specifying invalidates any dominant-unit estimate: its lag order and
    // deterministic case were chosen against the previous x_t
    m.hasdu = 0

    m.hasforeign = 1
    gvar_MODEL = m
}

// ---------------------------------------------------------------------------
// 3.  Install weight matrices
// ---------------------------------------------------------------------------

void gvar_setw(real scalar typ, real matrix W)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    if (typ > m.ntypes) {
        m.Wt   = m.Wt   \ J(typ - m.ntypes, cols(m.Wt), NULL)
        m.Wsol = m.Wsol \ J(typ - m.ntypes, 1, NULL)
        m.ntypes = typ
    }
    m.Wt[typ, 1] = &(gvar_wnorm(W))
    m.Wsol[typ]  = &(gvar_wnorm(W))
    gvar_MODEL = m
}

// Install a time-varying stack: WSTACK is (N*ny) x N, block y in rows
// ((y-1)*N+1)..(y*N).  yrid maps each period to a block.
void gvar_setwtv(real scalar typ, real matrix WSTACK, real scalar ny,
                 real colvector yrid, real matrix WSOL)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar y, N
    pointer(real matrix) rowvector row

    m = gvar_MODEL
    N = m.N

    if (cols(m.Wt) < ny) {
        m.Wt = m.Wt, J(rows(m.Wt), ny - cols(m.Wt), NULL)
    }
    row = J(1, ny, NULL)
    for (y = 1; y <= ny; y++) {
        row[y] = &(gvar_wnorm(WSTACK[((y-1)*N+1)::(y*N), .]))
    }
    m.Wt[typ, 1::ny] = row
    m.Wsol[typ] = &(gvar_wnorm(WSOL))
    m.nyears = ny
    m.yrid   = yrid
    gvar_MODEL = m
}

// ---------------------------------------------------------------------------
// 4.  Setters for specification choices
// ---------------------------------------------------------------------------

void gvar_setlags(real matrix L)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    m.lagord = L
    m.pmax   = max(L)
    gvar_MODEL = m
}

void gvar_setcase(real colvector c)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    m.ecase = c
    gvar_MODEL = m
}

void gvar_setrank(real colvector r)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    m.rnk = r
    gvar_MODEL = m
}

void gvar_setpsc(real scalar p)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    m.psc = p
    gvar_MODEL = m
}

// ---------------------------------------------------------------------------
// 5.  Accessors used by the ado layer
// ---------------------------------------------------------------------------

real scalar gvar_getN()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.N)
}

real scalar gvar_getK()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.K)
}

real scalar gvar_getT()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.Traw)
}

real scalar gvar_getpmax()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.pmax)
}

string colvector gvar_getcname()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.cname)
}

string colvector gvar_getvname()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.vname)
}

string colvector gvar_getxname()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.xname)
}

string colvector gvar_getgvname()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.gvname)
}

// "unit:variable" for every element of x_t, space separated, for st_local
string scalar gvar_getxlabels()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    string scalar s
    real scalar j

    m = gvar_MODEL
    s = ""
    for (j = 1; j <= m.K; j++) {
        s = s + " " + m.xcname[j] + ":" + m.xname[j]
    }
    return(strtrim(s))
}

real colvector gvar_getxunit()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.xunit)
}

// Position of each element of x(t) WITHIN its own unit's block, i.e. the
// equation number 1..k_i of the country model it belongs to.  x(t) is stacked
// unit by unit, so this is just the running count restarting at each unit.
// Needed wherever an x-position has to be turned back into a country-model
// equation, as -gvar stability, graph- does.
real colvector gvar_getxeq()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real colvector out, seen
    real scalar j, u

    m    = gvar_MODEL
    out  = J(m.K, 1, 0)
    seen = J(m.N, 1, 0)
    for (j = 1; j <= m.K; j++) {
        u       = m.xunit[j]
        seen[u] = seen[u] + 1
        out[j]  = seen[u]
    }
    return(out)
}

string colvector gvar_getxcname()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.xcname)
}

real colvector gvar_getki()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.ki)
}

real colvector gvar_getksi()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.ksi)
}

real matrix gvar_getlags()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.lagord)
}

real colvector gvar_getcase()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.ecase)
}

real colvector gvar_getrank()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.rnk)
}

real matrix gvar_getY(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Yi[i])
}

real matrix gvar_getS(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Si[i])
}

string colvector gvar_getylist(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.ylist[i])
}

string colvector gvar_getslist(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.slist[i])
}

// Single names.  Mata cannot subscript a function result inline, so
// gvar_getylist(i)[j] is a compile error; callers use these instead.
string scalar gvar_getyname(real scalar i, real scalar j)
{
    external struct gvarmodel scalar gvar_MODEL
    return((*gvar_MODEL.ylist[i])[j])
}

string scalar gvar_getsname(real scalar i, real scalar j)
{
    external struct gvarmodel scalar gvar_MODEL
    return((*gvar_MODEL.slist[i])[j])
}

real matrix gvar_getW(real scalar typ)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Wsol[typ])
}

real scalar gvar_getntypes()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.ntypes)
}

// Declaring the external would CREATE an empty struct, so presence alone is
// not evidence that gvar setup has run; test a populated dimension instead.
// Historical decomposition  (BGVAR hd.R).
//
// Splits each observed series into the cumulated contribution of every
// structural shock, plus the constant, the trend, the initial condition and
// a leftover slice that makes the pieces add back to the data.
//
// hd.R REFUSES to do this under generalized identification:
//   "Historical decomposition of the time series not implemented for GIRFs
//    since cross-correlation is unequal to zero (and hence decompositions do
//    not sum up to original time series)."
// so the caller must supply an orthogonal scheme.  The refusal is enforced
// in the ado, where it can explain itself.
//
// Sigma_u here is the REDUCED-FORM covariance: hd.R's ALPHA holds reduced-form
// VAR coefficients and eps = (YY - XX ALPHA') solve(solveA)'.  For the GVAR
// that is Sigma_eta = G0^-1 Sigma_zeta G0^-1', which inherits the rank
// deficiency of Sigma_zeta, so it too needs the transform/shrink chain
// before it can be factored.
//
// Returns ((K+2+trend)+1) blocks of K rows by T columns:
//   1..K            contribution of the shock to each variable
//   K+1             constant
//   K+2             trend, if the model has one
//   next            initial condition
//   last            leftover
real matrix gvar_hdrun(real scalar vmeth, real scalar vexcl,
                       real scalar shrink, real scalar lam,
                       real colvector ord, real scalar align,
                       real matrix strshock)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Sz, Se, ALPHA, Xreg, Yt, Xb, G0u, Fsu, Szu, rot, OUT
    real colvector d0u, d1u, iv
    real scalar K, ml, T, Traw, l, t, lamout, hastr

    m    = gvar_MODEL
    K    = m.K
    ml   = m.pmax
    Traw = cols(m.X)
    T    = Traw - ml

    // the same covariance chain as the point IRF, then map to reduced form
    if (rows(ord) == 0) {
        Sz  = gvar_sigmause(vmeth, vexcl, shrink, lam, lamout)
        G0u = m.G0
        Fsu = m.Fs
        d0u = m.d0
        d1u = m.d1
        Xb  = m.X
    }
    else {
        gvar_applyorder(ord, G0u, Fsu, Szu)
        Sz = gvar_transformvcov(Szu, vmeth, vexcl)
        if (shrink == 1) Sz = gvar_shrinkcov(Sz, cols(m.zeta), lam, lamout)
        d0u = m.d0[ord]
        d1u = m.d1[ord]
        Xb  = m.X[ord, .]
    }
    Se = gvar_msolve(G0u, Sz) * (gvar_inv(G0u))'
    Se = makesymmetric(Se)

    hastr = 0
    if (max(abs(d1u)) > 0) hastr = 1

    // ALPHA = [F_1 ... F_p, d0, (d1)] and XX = [lags, 1, (trend)], as hd.R
    // builds them with .mlag() and cbind(...,1)
    ALPHA = Fsu, d0u
    if (hastr == 1) ALPHA = ALPHA, d1u

    Yt   = Xb[., (ml+1)::Traw]'
    Xreg = J(T, 0, 0)
    for (l = 1; l <= ml; l++) {
        Xreg = Xreg, Xb[., (ml+1-l)::(Traw-l)]'
    }
    Xreg = Xreg, J(T, 1, 1)
    if (hastr == 1) {
        // gvar_reduce builds the model's trend as  maxlag + j - 1,
        // j = 1..T.  Anything else makes ALPHA*Xreg differ from the fitted
        // values and pushes the mismatch into the recovered shocks.
        Xreg = Xreg, (ml :+ (1::T) :- 1)
    }

    rot = I(K)
    OUT = gvar_hd(Yt, Xreg, ALPHA, Se, rot, K, ml, hastr, align, strshock)

    // map the rows back to the model's own variable order
    if (rows(ord) > 0) {
        iv  = gvar_invperm(ord)
        OUT = gvar_hdreorder(OUT, iv, K)
        strshock = strshock[., iv]
    }
    return(OUT)
}

// Undo a permutation in a stacked HD matrix.  Every block's ROWS are indexed
// by responding variable, so all of them need the inverse permutation.  The
// FIRST K blocks are additionally indexed by shock, so those blocks must also
// be reordered among themselves; the constant, trend, initial-condition and
// leftover blocks carry no shock index and stay put.
real matrix gvar_hdreorder(real matrix H, real colvector iv, real scalar K)
{
    real matrix OUT, B
    real scalar nb, j, src

    nb  = rows(H) / K
    OUT = J(0, cols(H), .)
    for (j = 1; j <= nb; j++) {
        src = j
        if (j <= K) src = iv[j]
        B   = H[((src-1)*K+1)::(src*K), .]
        OUT = OUT \ B[iv, .]
    }
    return(OUT)
}

// Wrappers for the historical decomposition, so the ado declares no Mata
// output arguments.
real matrix gvar_hdwrap(real scalar vmeth, real scalar vexcl,
                        real scalar shrink, real scalar lam,
                        real colvector ord, real scalar align)
{
    real matrix H, SH

    SH = J(0, 0, .)
    H  = gvar_hdrun(vmeth, vexcl, shrink, lam, ord, align, SH)
    st_matrix("r_strshock", SH)
    return(H)
}

// Mean absolute contribution of each shock to one variable.
real colvector gvar_hdcontrib(real matrix H, real scalar K, real scalar vpos)
{
    real colvector out
    real scalar j, r

    out = J(K, 1, 0)
    for (j = 1; j <= K; j++) {
        r = (j - 1) * K + vpos
        out[j] = mean(abs(H[r, .])')
    }
    return(out)
}

// Largest absolute leftover: how far the pieces are from adding back to the
// data.  hd.R defines the last slice as exactly that residual, so this is a
// check that the slice was built and placed correctly, not that the model
// fits.
real scalar gvar_hdcheck(real matrix H, real scalar K, real scalar bleft)
{
    real matrix B

    B = H[((bleft-1)*K+1)::(bleft*K), .]
    return(max(abs(B)))
}

// ---------------------------------------------------------------------------
// Over-identifying restrictions on the cointegrating vectors
//   (Toolbox overid_restr.m; the LR test at gvar.m:1479-1481)
//
//     overid_LR  = -2 * (logl_r - logl)
//     overid_dgf = rows(beta)*cols(beta) - cols(beta)^2 - nunrestrpar
//
// The r^2 term removes the just-identifying normalisation; nunrestrpar is the
// count of coefficients the user left free, so only genuinely over-identifying
// restrictions are counted.  gvar.m takes the critical values from the
// bootstrap, not from a chi-squared table.
//
// RESTR is a stacked (unit, betarow, relation, value) list; NUNR is N x 1.
// Returns one row per restricted unit:
//   1 unit  2 LR  3 d.f.  4 asymptotic p  5 logl unrestricted  6 logl restricted
real matrix gvar_overidrun(real matrix RESTR, real colvector NUNR,
                           real scalar store)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, Br, beta, alpha, Psi, eps, Om2, ecm, DX, dep
    real scalar i, q, nb, rb, cb, df, LR, llr, ai, sb, nr

    m   = gvar_MODEL
    OUT = J(0, 6, .)
    if (rows(m.betar) != m.N) {
        m.betar   = J(m.N, 1, NULL)
        m.nunrestr = J(m.N, 1, 0)
    }

    beta = alpha = Psi = eps = Om2 = ecm = DX = dep = J(0, 0, .)
    llr = ai = sb = .

    for (i = 1; i <= m.N; i++) {
        // collect this unit's restriction rows
        nb = 0
        for (q = 1; q <= rows(RESTR); q++) {
            if (RESTR[q, 1] == i) nb = nb + 1
        }
        if (nb == 0) continue

        rb = gvar_betarows(i)
        cb = m.rnk[i]
        if (cb == 0) continue

        Br = J(rb, cb, 0)
        for (q = 1; q <= rows(RESTR); q++) {
            if (RESTR[q, 1] == i) {
                Br[RESTR[q, 2], RESTR[q, 3]] = RESTR[q, 4]
            }
        }

        gvar_mlcoint_r(*m.Yi[i], *m.Si[i], m.lagord[i,1], m.lagord[i,2],
                       m.pmax, m.ecase[i], Br, alpha, Psi, eps, Om2, ecm,
                       DX, dep, llr, ai, sb)

        LR = -2 * (llr - m.logl[i])
        nr = NUNR[i]
        df = rb * cb - cb^2 - nr
        OUT = OUT \ (i, LR, df, chi2tail(max((df, 1)), LR), m.logl[i], llr)

        if (store == 1) {
            m.betar[i]    = &(Br[., .])
            m.nunrestr[i] = nr
        }
    }
    if (store == 1) gvar_MODEL = m
    return(OUT)
}

// Rows of beta for unit i: k_i endogenous plus ks_i weakly exogenous, with a
// leading deterministic row in cases 2 and 4 (vecx2varx strips beta[1,.] in
// exactly those two cases).
real scalar gvar_betarows(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar r

    m = gvar_MODEL
    r = m.ki[i] + m.ksi[i]
    if (m.ecase[i] == 2 | m.ecase[i] == 4) r = r + 1
    return(r)
}

// Names of the beta rows for unit i, in order, space separated.
string scalar gvar_betarownames(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    string scalar s
    string colvector yl, sl
    real scalar j

    m = gvar_MODEL
    s = ""
    if (m.ecase[i] == 4) s = "_trend"
    if (m.ecase[i] == 2) s = "_cons"
    yl = *m.ylist[i]
    sl = *m.slist[i]
    for (j = 1; j <= rows(yl); j++) {
        s = s + " " + yl[j]
    }
    for (j = 1; j <= rows(sl); j++) {
        s = s + " " + sl[j] + "*"
    }
    return(strtrim(s))
}

// ---------------------------------------------------------------------------
// Granger causality  (GVARX .grangerGVAR, which calls vars::causality)
//
// vars::causality builds a restriction matrix R that picks the lag
// coefficients of the CAUSE variables out of the equations of the remaining
// variables, then
//     STATISTIC <- t(R %*% PI.vec) %*% solve(R %*% sigma.pi %*% t(R))
//                  %*% R %*% PI.vec / N
//     df1 = p * length(y1.names) * length(y2.names)
//     df2 = K * obs - length(PI)
// with sigma.pi = vcov(xMlm) = Sigma kron (Z'Z)^-1 for the multivariate
// least-squares fit, and N the number of restrictions.
//
// .grangerGVAR runs this twice for each unit: once on a plain VAR of the
// unit's own variables, and once on a VARX that carries the foreign block as
// exogenous regressors.  Reporting both is the point -- it shows whether
// conditioning on the rest of the world overturns the conclusion.
//
// Y   T x k  endogenous block
// Xex T x m  exogenous block, empty for the plain VAR
// cs, es  index vectors into the columns of Y
// Returns (F, df1, df2, p).
real rowvector gvar_gctest(real matrix Y, real matrix Xex, real scalar p,
                           real colvector cs, real colvector es,
                           real scalar robust)
{
    real matrix Z, YY, PI, U, Sig, ZZi, Spi, R, RR, W
    real colvector pv, b
    real scalar T, k, nz, i, j, l, nr, ne, df1, df2, obs, Fst, c, e

    T = rows(Y)
    k = cols(Y)

    // Z = [lags 1..p of Y, exogenous block, constant]
    Z = J(T, 0, 0)
    for (l = 1; l <= p; l++) {
        Z = Z, gvar_lagm(Y, l)
    }
    if (cols(Xex) > 0) Z = Z, Xex
    Z = Z, J(T, 1, 1)

    // drop the pre-sample rows the lags cannot fill
    YY = Y[(p+1)::T, .]
    Z  = Z[(p+1)::T, .]
    obs = rows(YY)
    nz  = cols(Z)

    PI = qrsolve(Z, YY)           // nz x k, column j = equation j
    U  = YY - Z * PI
    // vcov.mlm divides by obs - ncol(Z)
    Sig = cross(U, U) / (obs - nz)
    ZZi = gvar_sinv(cross(Z, Z))

    // sigma.pi = Sigma kron (Z'Z)^-1, matching vec(PI) stacked by equation
    Spi = Sig # ZZi
    if (robust == 1) {
        Spi = gvar_gcrobust(Z, U, ZZi, k, nz, obs)
    }

    // R picks the lags of every cause variable out of every effect equation
    nr = 0
    R  = J(0, nz * k, 0)
    for (i = 1; i <= rows(es); i++) {
        e = es[i]
        for (j = 1; j <= rows(cs); j++) {
            c = cs[j]
            for (l = 1; l <= p; l++) {
                RR = J(1, nz * k, 0)
                RR[1, (e - 1) * nz + (l - 1) * k + c] = 1
                R  = R \ RR
                nr = nr + 1
            }
        }
    }
    if (nr == 0) return((., ., ., .))

    b = vec(PI)
    W = gvar_sinv(R * Spi * R')
    Fst = ((R * b)' * W * (R * b)) / nr

    df1 = p * rows(cs) * rows(es)
    df2 = k * obs - nz * k
    if (df2 <= 0) return((Fst, df1, df2, .))
    return((Fst, df1, df2, Ftail(df1, df2, Fst)))
}

// White covariance for the stacked coefficients, the analogue of the
// vcovHC that .grangerGVAR passes in by default.  sandwich::vcovHC is not
// part of the supplied sources, so this is the standard HC0 sandwich
// sum_t (Z_t Z_t') kron (u_t u_t') reordered to match vec(PI); it is not a
// line-by-line port of sandwich and the difference is documented.
real matrix gvar_gcrobust(real matrix Z, real matrix U, real matrix ZZi,
                          real scalar k, real scalar nz, real scalar obs)
{
    real matrix M, B, Om
    real scalar t

    M = J(nz * k, nz * k, 0)
    for (t = 1; t <= obs; t++) {
        B = (U[t, .]' * U[t, .]) # (Z[t, .]' * Z[t, .])
        M = M + B
    }
    Om = I(k) # ZZi
    return(Om * M * Om)
}

// Duplication matrix  (GVARX .duplicate, used by causality()'s
// instantaneous test).
real matrix gvar_duplic(real scalar n)
{
    real matrix D
    real scalar cnt, i, j

    D   = J(n^2, n * (n + 1) / 2, 0)
    cnt = 0
    for (j = 1; j <= n; j++) {
        D[(j-1)*n + j, cnt + j] = 1
        if ((j + 1) <= n) {
            for (i = j + 1; i <= n; i++) {
                D[(j-1)*n + i, cnt + i] = 1
                D[(i-1)*n + j, cnt + i] = 1
            }
        }
        cnt = cnt + n - j
    }
    return(D)
}

// Instantaneous causality, the second test causality() returns.
//   sigma.u   <- crossprod(resid) / (obs - ncol(Z))
//   sig.vech  <- vech(sigma.u)
//   C picks the entries linking the cause block to the rest
//   lambda.w  <- obs * v' C' [2 C Dinv (S kron S) Dinv' C']^-1 C v
//   df        <- N
// Returns (chi2, df, p).
real rowvector gvar_gcinst(real matrix U, real scalar nz,
                           real colvector cs, real scalar k)
{
    real matrix Sig, D, Di, C, W
    real colvector vh, isc
    real scalar obs, i, j, q, n, lam, pos

    obs = rows(U)
    Sig = cross(U, U) / (obs - nz)

    // which elements of vech(Sigma) link a cause variable to a non-cause one
    isc = J(k, 1, 0)
    for (i = 1; i <= rows(cs); i++) isc[cs[i]] = 1

    vh  = J(0, 1, .)
    pos = 0
    n   = 0
    C   = J(0, k * (k + 1) / 2, 0)
    for (j = 1; j <= k; j++) {
        for (i = j; i <= k; i++) {
            pos = pos + 1
            vh  = vh \ Sig[i, j]
            if ((isc[i] == 1 & isc[j] == 0) | (isc[i] == 0 & isc[j] == 1)) {
                C = C \ J(1, k * (k + 1) / 2, 0)
                n = n + 1
                C[n, pos] = 1
            }
        }
    }
    if (n == 0) return((., ., .))

    D  = gvar_duplic(k)
    Di = pinv(D)
    W  = 2 * C * Di * (Sig # Sig) * Di' * C'
    lam = obs * (vh' * C' * gvar_sinv(W) * C * vh)
    return((lam, n, chi2tail(n, lam)))
}

// Driver: run the Granger test for one unit, both without and with the
// foreign block, as .grangerGVAR does.
//   1 unit  2 F(VAR)  3 df1  4 df2  5 p(VAR)  6 F(VARX) 7 df1 8 df2 9 p(VARX)
real rowvector gvar_gcrun(real scalar i, real colvector cs, real colvector es,
                          real scalar p, real scalar flag, real scalar robust)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Y, S, Xex
    real rowvector a, b, c
    real scalar l

    m = gvar_MODEL
    Y = *m.Yi[i]
    S = *m.Si[i]

    // .grangerGVAR uses embed(Ft, FLag): the foreign block at lags
    // 0, 1, ..., FLag-1
    Xex = J(rows(Y), 0, 0)
    if (cols(S) > 0 & flag >= 1) {
        for (l = 0; l <= flag - 1; l++) {
            Xex = Xex, gvar_lagm(S, l)
        }
    }

    a = gvar_gctest(Y, J(rows(Y), 0, 0), p, cs, es, robust)
    b = gvar_gctest(Y, Xex,              p, cs, es, robust)
    c = gvar_gcinstrun(Y, Xex, p, cs)
    return((i, a, b, c))
}

// Instantaneous causality on the VARX residuals.
real rowvector gvar_gcinstrun(real matrix Y, real matrix Xex, real scalar p,
                              real colvector cs)
{
    real matrix Z, YY, U
    real scalar T, l, nz

    T = rows(Y)
    Z = J(T, 0, 0)
    for (l = 1; l <= p; l++) Z = Z, gvar_lagm(Y, l)
    if (cols(Xex) > 0) Z = Z, Xex
    Z  = Z, J(T, 1, 1)
    YY = Y[(p+1)::T, .]
    Z  = Z[(p+1)::T, .]
    nz = cols(Z)
    U  = YY - Z * qrsolve(Z, YY)
    return(gvar_gcinst(U, nz, cs, cols(Y)))
}

// ===========================================================================
// The dominant unit model  (Toolbox estimate_VECM_dumodel.m, vec2var_du.m)
// ===========================================================================
// A model for the global variables themselves, used instead of attaching them
// to a country block.  With one global variable it is an AR(p), in levels or
// in first differences; with more than one it is a VECM, from which the VAR
// coefficients are recovered exactly as vecx2varx does for a country model.
//
// solve_GVAR.m then augments the system as
//     y  = [x; gxv'],   Ky = K + gxvnum
//     H0 = [G0 -J0 ; 0 I]
//     H_j= [G_j J_j ; 0 Phi_j]                        without feedback
//     H_j= [G_j 0   ; Lambda_du_j Wtilde  Phi_j]      with feedback
// Note the zero block in H0 in both cases: feedback from the country models
// enters the dominant unit only at LAGS, never contemporaneously.  That is
// what lets the block be carried as an ordinary pseudo-unit with L0 = 0 and
// Lm holding Lambda_du, so the existing stacking needs no special case.
//
//   esttype 0 levels, 1 first differences   (only when gxvnum == 1)
//   ducase  0 intercept, 1 intercept and trend   (levels AR)
//           2, 3, 4 the usual deterministic cases   (VECM)
//
// Returns a0, a1 and Theta stacked as gxvnum x (gxvnum*maxlag).
void gvar_dumodel(real matrix GX, real scalar maxlag, real scalar lp,
                  real scalar rk, real scalar ducase, real scalar esttype,
                  real colvector a0du, real colvector a1du,
                  real matrix Thdu, real matrix beta, real matrix alpha,
                  real matrix Psi, real matrix eps, real matrix Om)
{
    real scalar g, T, i, detind, nd
    real matrix X, Y, Z, ecm, DX, dep
    real colvector b, y1
    real scalar ll, ai, sb

    g = cols(GX)
    T = rows(GX)

    if (g == 1) {
        // ---------------- univariate: an AR(p) ---------------------------
        if (esttype == 0) {
            // levels:  y_t on deterministics and p own lags
            y1 = GX[(1+lp)::T, 1]
            X  = J(T, 1, 1)
            if (ducase == 1) X = X, (1::T)
            for (i = 1; i <= lp; i++) {
                X = X, gvar_lagm(GX, i)
            }
            X = gvar_trimr(X, lp, 0)
            // bhat = (X'*X)\(X'*y)
            b = gvar_msolve(cross(X, X), cross(X, y1))

            a0du = b[1]
            detind = 1
            a1du = 0
            if (ducase == 1) {
                a1du  = b[2]
                detind = 2
            }
            Thdu = J(1, maxlag, 0)
            for (i = 1; i <= maxlag; i++) {
                if (i <= lp) Thdu[1, i] = b[detind + i]
            }
            eps = y1 - X * b
        }
        else {
            // first differences: Dy_t on a constant and p lags of Dy
            y1 = GX[(1+lp)::T, 1] - GX[lp::(T-1), 1]
            Y  = GX - gvar_lagm(GX, 1)
            X  = J(T, 1, 1)
            for (i = 1; i <= lp; i++) {
                X = X, gvar_lagm(Y, i)
            }
            X  = gvar_trimr(X, lp, 0)
            y1 = gvar_trimr(Y, lp, 0)
            b  = gvar_msolve(cross(X, X), cross(X, y1))

            a0du = b[1]
            a1du = 0
            // the source maps the difference-equation coefficients back to
            // levels: Theta_1 = 1 + b_2, Theta_i = b_(1+i) - b_i,
            // Theta_lp = -b_lp, with lp = ptildel + 1
            nd   = lp + 1
            Thdu = J(1, maxlag, 0)
            for (i = 1; i <= maxlag; i++) {
                if (i == 1)                Thdu[1, i] = 1 + b[1 + i]
                else if (i > 1 & i < nd)   Thdu[1, i] = b[1 + i] - b[i]
                else if (i == nd)          Thdu[1, i] = -b[i]
            }
            eps = y1 - X * b
        }
        beta  = J(0, 0, .)
        alpha = J(0, 0, .)
        Psi   = J(0, 0, .)
        Om    = cross(eps, eps) / rows(eps)
        return
    }

    // -------------------- multivariate: a VECM ---------------------------
    // mlcoint with no weakly exogenous block
    ll = ai = sb = .
    gvar_mlcoint(GX, J(T, 0, 0), lp, 0, maxlag, ducase, rk,
                 beta, alpha, Psi, eps, Om, ecm, DX, dep, ll, ai, sb)

    gvar_vecx2varx(maxlag, g, 0, lp, 0, ducase, alpha, beta, Psi,
                   a0du, a1du, Thdu, X, Y)
}

// Trend-cycle decomposition  (Toolbox TCdecomp.m).
//
//   useeta 1  cumulate the reduced-form residual eta   (correct)
//          0  cumulate the structural residual zeta    (what gvar.m passes)
//
// TCdecomp.m documents its third argument as "eta: K x nobs matrix containing
// residuals of the reduced-form GVAR", and its C(.) recursion is built on
// C(:,:,j) = H0\H(:,:,j), i.e. the REDUCED-FORM lag matrices.  But
// gvar.m:3106 calls
//     TCdecomp(TC_RestrictionFlag, C, zeta, mlag, y, ...)
// and solve_GVAR.m:186,210 define zeta as the structural residual and
// eta = H0\zeta as the reduced-form one.  So the structural residual is
// being cumulated against a reduced-form long-run multiplier.
//
// That the recursion is the reduced-form C(1) is easy to confirm on a scalar
// AR(1): C_0 = 1, C_1 = F-1, C_j = C_{j-1}F gives sum 1 + (F-1)/(1-F) = 0
// when |F| < 1 and 1 at a unit root -- exactly the Beveridge-Nelson long-run
// multiplier, which multiplies the reduced-form innovation.
//
// Default here is the correct one; useeta 0 reproduces the Toolbox exactly.
void gvar_tcrun(real colvector restr, real scalar notrend, real scalar useeta,
                real matrix xp, real matrix xc, real matrix xpst,
                real matrix xpdt, real matrix xtil)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix U

    m = gvar_MODEL
    if (useeta == 1) U = m.eta
    else             U = m.zeta

    gvar_tcdecomp(m.Fs, U, m.pmax, m.X, restr, notrend, xp, xc, xpst, xpdt)

    // TCdecomp.m ends by checking that the cyclical component equals the
    // deviation from the permanent component, and stops if it does not.
    xtil = m.X[., (m.pmax + 1)::cols(m.X)] - xp
}

// Thin wrappers so the ado never has to declare Mata output arguments.
void gvar_tcwrap(real colvector restr, real scalar notrend, real scalar useeta)
{
    real matrix xp, xc, xpst, xpdt, xtil

    xp = xc = xpst = xpdt = xtil = J(0, 0, .)
    gvar_tcrun(restr, notrend, useeta, xp, xc, xpst, xpdt, xtil)
    st_matrix("r_xp",   xp)
    st_matrix("r_xc",   xc)
    st_matrix("r_xpst", xpst)
    st_matrix("r_xpdt", xpdt)
    st_matrix("r_xtil", xtil)
}

void gvar_tcstats(real matrix XC, real matrix XP, real scalar j)
{
    real scalar sdc, sdp, sh

    sdc = sqrt(variance(XC[j, .]'))
    sdp = sqrt(variance(XP[j, .]'))
    sh  = .
    if (sdc + sdp > 0) sh = sdc / (sdc + sdp)
    st_numscalar("r(sdc)",   sdc)
    st_numscalar("r(sdp)",   sdp)
    st_numscalar("r(share)", sh)
    st_numscalar("r(last)",  XC[j, cols(XC)])
}

real scalar gvar_getfreq()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.freq)
}

// Point forecasts, with the element-wise lower bounds of forecast_GVAR.m.
real matrix gvar_forecastrun(real scalar h, real colvector lb)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    return(gvar_forecast(m.X, m.pmax, m.Fs, m.d0, m.d1, h, lb))
}

// Conditional forecasts  (con_forecast_GVAR.m).  D is K x H_bar with missing
// where the path is free.  Note that con_forecast_GVAR calls forecast_GVAR
// with lb_flag = 0: the baseline for a conditional forecast carries no lower
// bound, so none is applied here either.
real matrix gvar_confcastrun(real scalar h, real matrix D)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    return(gvar_confcast(m.X, m.pmax, m.Fs, m.d0, m.d1, m.Seta, h, D))
}

real colvector gvar_getlogl()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.logl)
}

// Largest eigenvalue modulus of the companion matrix: 1 for a stable GVAR
// with unit roots, anything above that is explosive.
real scalar gvar_maxmod()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    if (rows(m.eigmod) == 0) return(.)
    return(m.eigmod[1])
}

real scalar gvar_isbuilt()
{
    external struct gvarmodel scalar gvar_MODEL
    real scalar n

    n = gvar_MODEL.N
    if (n == .) {
        return(0)
    }
    if (n < 2) {
        return(0)
    }
    return(1)
}

real scalar gvar_hasforeign()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.hasforeign)
}

real scalar gvar_isestimated()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.estimated)
}

real scalar gvar_issolved()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.solved)
}

real matrix gvar_getX()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.X)
}

real colvector gvar_gettvals()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.tvals)
}


// =========================================================================
// =====  from _gvar_setup.ado                                              
// =========================================================================


void _gvar_do_setup(string scalar dvars, string scalar gvars,
                    string scalar touse, string scalar uidv,
                    string scalar tv,
                    real scalar N, real scalar Traw, real scalar freq,
                    string scalar idvar, string scalar tvar,
                    string scalar cn, string scalar wt, string scalar cs)
{
    real matrix DATA, GDATA, dflag, fflag, gflag, TT
    real colvector tvals, vtype, ecase
    string colvector cname, clong, vname, gvname
    string scalar absent, partial
    real scalar i, j, V, G, nmiss

    DATA  = st_data(., dvars, touse)
    vname = tokens(dvars)'
    V     = rows(vname)

    if (strtrim(gvars) != "") {
        GDATA  = st_data(., gvars, touse)
        GDATA  = GDATA[1::Traw, .]
        gvname = tokens(gvars)'
    }
    else {
        GDATA  = J(Traw, 0, 0)
        gvname = J(0, 1, "")
    }
    G = rows(gvname)

    // the time values must line up across units: reshape the unit-major
    // column into Traw x N and require every column to be identical
    tvals = st_data(., tv, touse)
    TT    = rowshape(tvals, N)'
    for (i = 2; i <= N; i++) {
        if (max(abs(TT[., i] - TT[., 1])) > 0) {
            errprintf("gvar: the time values do not line up across units; " +
                      "every unit must span the same set of periods" + "\n")
            exit(459)
        }
    }
    tvals = TT[., 1]

    cname = tokens(cn)'
    clong = J(N, 1, "")
    for (i = 1; i <= N; i++) {
        clong[i] = st_local("__gvclong" + strofreal(i))
        if (clong[i] == "") {
            clong[i] = cname[i]
        }
    }

    vtype = strtoreal(tokens(wt))'
    ecase = strtoreal(tokens(cs))'

    // A variable is endogenous for a unit when it is fully observed there.
    // Fully absent and partially observed are reported separately: the second
    // case silently costs the unit a variable, so the user must be told.
    dflag   = J(N, V, 0)
    absent  = ""
    partial = ""
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= V; j++) {
            nmiss = missing(DATA[((i-1)*Traw+1)::(i*Traw), j])
            if (nmiss == 0) {
                dflag[i, j] = 1
            }
            else if (nmiss == Traw) {
                absent = absent + " " + cname[i] + ":" + vname[j]
            }
            else {
                partial = partial + " " + cname[i] + ":" + vname[j] +
                          "(" + strofreal(nmiss) + " of " +
                          strofreal(Traw) + " missing)"
            }
        }
    }
    st_local("__gvabsent",  strtrim(absent))
    st_local("__gvpartial", strtrim(partial))

    if (G > 0) {
        if (missing(GDATA) > 0) {
            errprintf("gvar setup: the global variables contain missing " +
                      "values. A global variable must be observed over the whole " +
                      "estimation window." + "\n")
            exit(459)
        }
    }

    fflag = dflag
    gflag = J(N, G, 1)

    gvar_build(DATA, cname, clong, vname, vname, vtype, N, Traw, tvals,
               freq, idvar, tvar, dflag, fflag, gvname, gflag, GDATA)
    gvar_setcase(ecase)
}

// Apply foreign(all), noforeign(), exclude() and gendog() to the flags
void _gvar_do_flags(real scalar forall, string scalar nofor,
                    string scalar excl, string scalar gendog,
                    string scalar domin)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, j, g, N, V, G, p, np, pos
    real matrix dflag, fflag, gflag
    string rowvector nf, ex, gd, prt
    string scalar cu, cv

    // dominant() is recorded on gvar_MODEL itself, BEFORE the local copy on
    // the next line, so that m already carries it.  Anchoring an edit on a
    // declaration line rather than on the function header put this call in
    // gvar_getPi() once; the header is the only unambiguous anchor.
    gvar_setdumark(domin)

    m     = gvar_MODEL
    N     = m.N
    V     = m.V
    G     = rows(m.gvname)
    dflag = m.dflag
    fflag = m.fflag
    gflag = m.gflag

    // foreign(all): every unit gets the star of every system variable
    if (forall == 1) {
        for (j = 1; j <= V; j++) {
            if (colsum(dflag[., j]) >= 2) {
                fflag[., j] = J(N, 1, 1)
            }
        }
    }

    // A domestic variable owned by exactly ONE unit behaves like a global
    // variable: endogenous in its owner, weakly exogenous everywhere else.
    // This is how the oil price enters Dees-di Mauro-Pesaran-Smith and BGVAR,
    // where poil sits inside the US country block.  Averaging it over the
    // single owner would instead give that unit a degenerate star equal to
    // its own series.  noforeign() overrides this below.
    for (j = 1; j <= V; j++) {
        if (colsum(dflag[., j]) == 1) {
            for (i = 1; i <= N; i++) {
                if (dflag[i, j] == 1) {
                    fflag[i, j] = 0
                }
                else {
                    fflag[i, j] = 1
                }
            }
        }
    }

    // noforeign(): never build a star for these variables (BGVAR Wex.restr)
    if (strtrim(nofor) != "") {
        nf = tokens(nofor)
        for (p = 1; p <= cols(nf); p++) {
            pos = gvar_pos(m.vname, nf[p])
            if (pos > 0) {
                fflag[., pos] = J(N, 1, 0)
            }
        }
    }

    // exclude(): unit:variable pairs removed from the domestic block, and
    // hence from that unit's star block as well
    if (strtrim(excl) != "") {
        ex = tokens(excl)
        for (p = 1; p <= cols(ex); p++) {
            prt = tokens(ex[p], ":")
            if (cols(prt) < 3) {
                continue
            }
            cu = prt[1]
            cv = prt[3]
            i  = gvar_pos(m.cname, cu)
            j  = gvar_pos(m.vname, cv)
            if (i > 0 & j > 0) {
                dflag[i, j] = 0
            }
        }
    }

    // gendog(): a global variable is endogenous in the named unit
    if (strtrim(gendog) != "" & G > 0) {
        gd = tokens(gendog)
        for (p = 1; p <= cols(gd); p++) {
            prt = tokens(gd[p], "=")
            if (cols(prt) < 3) {
                continue
            }
            g = gvar_pos(m.gvname, prt[1])
            i = gvar_pos(m.cname, prt[3])
            if (g > 0 & i > 0) {
                gflag[i, g] = 2
            }
        }
    }

    // A global variable that is weakly exogenous somewhere must be endogenous
    // SOMEWHERE, otherwise it never enters x_t and its link-matrix row is
    // identically zero.  The Toolbox handles that case through the dominant
    // unit model instead.
    for (g = 1; g <= G; g++) {
        if (rows(m.dumark) >= G) {
            // a global named in dominant() is meant to be endogenous nowhere:
            // its own block supplies it
            if (m.dumark[g] == 1) {
                // ... and if it IS endogenous somewhere, the specification is
                // contradictory.  This is gvar.m:981's duerror == 1, whose
                // message reads "Make sure that at least one global variable is
                // not included as domestic (endogenous) in any of the
                // individual country models".  Without this the variable sits
                // in a country block AND in the dominant block: it is counted
                // twice in x_t, the dominant model fits a series another unit
                // already determines, and nothing complains.  dominant() and
                // gendog() name the two ways to place a global and they are
                // alternatives, not a pair.
                if (colsum(gflag[., g] :== 2) > 0) {
                    errprintf("gvar setup: " + m.gvname[g] +
                              " is named in dominant() but is also endogenous" +
                              " in a country model.\n")
                    errprintf("       A global variable is placed EITHER by" +
                              " dominant(), which gives it its own block," +
                              " OR by\n")
                    errprintf("       gendog(" + m.gvname[g] + "=unit), which" +
                              " puts it inside that unit.  Choose one.\n")
                    exit(459)
                }
                continue
            }
        }
        if (colsum(gflag[., g] :== 1) > 0 & colsum(gflag[., g] :== 2) == 0) {
            errprintf("gvar setup: global variable " + m.gvname[g] +
                      " is weakly exogenous everywhere but endogenous nowhere. " +
                      "Make it endogenous in one unit with gendog(" + m.gvname[g] +
                      "=unit), or model it with gvar dominant." + "\n")
            exit(459)
        }
    }

    m.dflag = dflag
    m.fflag = fflag
    m.gflag = gflag
    gvar_MODEL = m
}


// =========================================================================
// =====  from _gvar_weights.ado                                            
// =========================================================================


// ===========================================================================
// Post-estimation diagnostic drivers
// ===========================================================================

// ---------------------------------------------------------------------------
// The Traw x N foreign (star) block of domestic variable j, rebuilt exactly as
// gvar_specify() builds it.
//
// gvar_specify keeps its FV blocks local and then overwrites m.Yi with the
// SELECTED domestic block, so once specification is done there is no route back
// to a star series the unit does not itself use.  m.DATA0 is the route: it is
// the untouched (N*Traw) x V source block, retained for exactly this kind of
// re-derivation.  Same weight matrix, same gvar_havepat handling of units that
// lack the variable, same time-varying branch -- so this returns the identical
// numbers gvar_specify computed and threw away.
// ---------------------------------------------------------------------------
real matrix gvar_starvar(real scalar j)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Yfull
    real scalar i, Traw, N

    m    = gvar_MODEL
    Traw = m.Traw
    N    = m.N

    Yfull = J(Traw, N, .)
    for (i = 1; i <= N; i++) {
        Yfull[., i] = m.DATA0[((i - 1) * Traw + 1)::(i * Traw), j]
    }
    if (m.nyears == 1) {
        return(gvar_foreignvar(Yfull, *m.Wt[m.vtype[j], 1]))
    }
    return(gvar_foreignvar_tv(Yfull, m.Wt[m.vtype[j], .]', m.yrid))
}

// ---------------------------------------------------------------------------
// exog_we: the foreign regressor block of the weak-exogeneity marginal model.
//
// This is a SEPARATE object from the unit's weakly exogenous block in the
// Toolbox -- fvflag_we / gvflag_we, read at gvar.m:1680-1714 -- even though its
// default is the estimation spec (fvflag_we_tmp = fvflag, gvar.m:1632, with
// globals mapped 1->1, 0->0, 2->0).  gvar.m then pauses so the user can change
// it, and its on-screen note offers, for DdPS(2007), "include the foreign
// variable, eps, in all country models by setting it to 1" (gvar.m:1666-1668).
//
// This function exists so that facility exists here too.  It does NOT change the
// default: with an empty `add` it returns the unit's own block unchanged, which
// is gvar.m's default and is what the published demo used.
//
// Do not read the eps note as describing the published sheet.  It does not.
// Solve degfr = T - (1 + r_i + ls*k_i + ln*ks_we_i) against the sheet's own
// critical values, remembering that T is capped at rows(ecm) - lagtrim by the
// discr branch of test_weakexogeneity.m:68-73:
//     ks_we = ks              -> 24 of 26 units reproduce the published degfr
//     ks_we = ks + 1{no eps}  ->  0 of 26 do
// bra is decisive on its own: the sheet's degfr is 118, which ks_we = ks gives
// and ks_we = ks + 1 turns into 117.  An earlier reading of this got the
// opposite answer by assuming every unit shares one T; units differ in
// max(ls,ln), so they do not.
//
// The two units that still miss are chl (one too many degrees of freedom) and
// usa (one too few) -- opposite signs, so not one trimming rule.  See
// gvar_methods.sthlp, "Weak exogeneity: a known deviation".
//
// Column ORDER inside the block is irrelevant: exog_we enters only as c2b, which
// appears in BOTH X and Xr, so F depends on span(c2b) alone.  Extra columns are
// therefore appended rather than interleaved into vname order.  Duplicates are
// NOT irrelevant -- degfr is T - cols(X), not T - rank(X) -- so a name the unit
// already carries is skipped.
// ---------------------------------------------------------------------------
real matrix gvar_wesi(real scalar i, string colvector add)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Swe, FVj
    string colvector sl
    real scalar a, j, g, V, G, pos

    m   = gvar_MODEL
    Swe = *m.Si[i]
    if (rows(add) == 0) {
        return(Swe)
    }
    sl = *m.slist[i]
    V  = rows(m.vname)
    G  = rows(m.gvname)

    for (a = 1; a <= rows(add); a++) {
        if (add[a] == "") {
            continue
        }
        // already carried by this unit -> skip, or degfr moves
        pos = 0
        for (j = 1; j <= rows(sl); j++) {
            if (sl[j] == add[a]) pos = j
        }
        if (pos > 0) {
            continue
        }

        // a domestic variable name asks for its foreign counterpart
        pos = 0
        for (j = 1; j <= V; j++) {
            if (m.vname[j] == add[a]) pos = j
        }
        if (pos > 0) {
            FVj = gvar_starvar(pos)
            Swe = Swe, FVj[., i]
            sl  = sl \ add[a]
            continue
        }

        // a global variable name asks for the series itself, unless this unit
        // has it endogenous -- gvar.m:1616-1627 maps gvflag 2 to gvflag_we 0
        pos = 0
        for (g = 1; g <= G; g++) {
            if (m.gvname[g] == add[a]) pos = g
        }
        if (pos > 0) {
            if (m.gflag[i, pos] == 2) {
                continue
            }
            Swe = Swe, m.GDATA[., pos]
            sl  = sl \ add[a]
        }
    }
    return(Swe)
}

// ---------------------------------------------------------------------------
// Weak exogeneity  (Toolbox test_weakexogeneity.m, gvar.m section 3.8)
//
// For each weakly exogenous variable of unit i, regress its first difference
// on a constant, the unit's error-correction terms and lagged differences of
// the domestic and foreign variables, then F-test that the ECM coefficients
// are jointly zero.
//
// Returns one row per (unit, weakly exogenous variable):
//   1 unit  2 variable index  3 r (restrictions)  4 d.f.  5 F 5% cv  6 F
// ---------------------------------------------------------------------------
real matrix gvar_wetest_all(real scalar ls, real scalar ln_,
                            real scalar conf, real matrix SEL,
                            string colvector WEADD)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT
    real rowvector res
    real scalar i, j, N, lsi, lni

    m   = gvar_MODEL
    N   = m.N
    OUT = J(0, 6, .)

    for (i = 1; i <= N; i++) {
        if (m.ksi[i] == 0 | m.rnk[i] == 0) {
            continue
        }
        // A NEGATIVE ls or ln_ means "use this unit's own VARX* orders", which is
        // what the Toolbox does: gvar.m:1767-1771 sets varxlag_we = varxlag when
        // lagselect_we is 0, so the marginal model inherits (p_i, q_i) per unit
        // rather than a single order for every unit.  The demo's exogeneity_test
        // sheet confirms it -- arg carries p*=2 q*=1 and austlia p*=1 q*=1,
        // matching VARXorder row for row.
        //
        // The old default was ls = ln = 1 for all 26 units, so arg's marginal
        // model was fitted with one domestic lag where the Toolbox uses two.
        // Every F statistic for a unit with p_i or q_i above 1 was therefore a
        // different test from the published one.
        // m.lagord is the N x 2 of (p_i, q_i); there is no m.pi / m.qi, and -pi-
        // would collide with Mata's own pi() in any case.
        lsi = ls
        lni = ln_
        if (ls  < 0) lsi = m.lagord[i, 1]
        if (ln_ < 0) lni = m.lagord[i, 2]
        // A supplied SEL matrix overrides both: it is the per-unit (ls, ln)
        // chosen by gvar_welagsel, which is what the Toolbox demo does.
        if (rows(SEL) >= i & cols(SEL) >= 2) {
            if (SEL[i, 1] >= 1) lsi = SEL[i, 1]
            if (SEL[i, 2] >= 1) lni = SEL[i, 2]
        }
        // exog and exog_we are DIFFERENT arguments in the Toolbox and must not
        // be the same matrix here: the left-hand side is the estimation block,
        // the regressor block is the marginal-model spec.  See gvar_wesi().
        res = gvar_wetest(*m.Yi[i], *m.Si[i], gvar_wesi(i, WEADD), *m.ec[i],
                          lsi, lni, m.rnk[i], conf)
        for (j = 1; j <= m.ksi[i]; j++) {
            OUT = OUT \ (i, j, res[1], res[2], res[3], res[3 + j])
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Contemporaneous effects of the foreign variables on their domestic
// counterparts  (Toolbox contmpcoeff.m)
//
// Picks out the elements of Lambda_0 whose domestic and foreign variable
// names coincide, with the matching standard errors of all three kinds.
// Returns: 1 unit  2 variable index within vname  3 coefficient
//          4 OLS se  5 White se  6 Newey-West se
// ---------------------------------------------------------------------------
real matrix gvar_contemp()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, Psi, S1, S2, S3
    real scalar i, a, b, N, off, col, vpos

    m   = gvar_MODEL
    N   = m.N
    OUT = J(0, 6, .)

    for (i = 1; i <= N; i++) {
        if (m.ksi[i] == 0) {
            continue
        }
        Psi = *m.Ps[i]
        S1  = *m.sd[i]
        S2  = *m.sdw[i]
        S3  = *m.sdn[i]

        // Psi columns: [ deterministic | Dx* block | Dx block ].  The
        // standard-error matrices are indexed over [ ecm | Z2 ], so the Dx*
        // block starts after the ECM terms and the deterministic column.
        off = 0
        if (m.ecase[i] == 3 | m.ecase[i] == 4) {
            off = 1
        }

        for (a = 1; a <= m.ki[i]; a++) {
            for (b = 1; b <= m.ksi[i]; b++) {
                if ((*m.ylist[i])[a] == (*m.slist[i])[b]) {
                    col  = off + b
                    vpos = gvar_pos(m.vname, (*m.ylist[i])[a])
                    OUT  = OUT \ (i, vpos, Psi[a, col],
                                  S1[a, m.rnk[i] + col],
                                  S2[a, m.rnk[i] + col],
                                  S3[a, m.rnk[i] + col])
                }
            }
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Average pairwise cross-section correlations  (Toolbox avgcorrs.m)
//
// For each domestic variable, the average correlation of each unit's series
// with the other units', computed on levels, on first differences and on the
// VECMX* residuals.
// Returns: 1 variable index  2 unit  3 levels  4 differences  5 residuals
// ---------------------------------------------------------------------------
real matrix gvar_avgcorr_all()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, LV, DF, RS
    real colvector own, cl, cd, cr
    real scalar i, j, N, V, ml, p, nn, T

    m   = gvar_MODEL
    N   = m.N
    V   = m.V
    ml  = m.pmax
    T   = m.Traw
    OUT = J(0, 5, .)

    for (j = 1; j <= V; j++) {
        LV  = J(T - ml, 0, 0)
        DF  = J(T - ml - 1, 0, 0)
        RS  = J(0, 0, 0)
        own = J(0, 1, 0)
        for (i = 1; i <= N; i++) {
            p = gvar_pos(*m.ylist[i], m.vname[j])
            if (p == 0) {
                continue
            }
            // trim the levels to the estimation sample, as avgcorrs.m does
            LV  = LV, (*m.Yi[i])[(ml + 1)::T, p]
            DF  = DF, ((*m.Yi[i])[(ml + 2)::T, p] - (*m.Yi[i])[(ml + 1)::(T - 1), p])
            if (m.estimated == 1) {
                if (cols(RS) == 0) {
                    RS = (*m.ep[i])[p, .]'
                }
                else {
                    RS = RS, (*m.ep[i])[p, .]'
                }
            }
            own = own \ i
        }
        nn = rows(own)
        if (nn < 2) {
            continue
        }
        cl = gvar_avgcorr(LV)
        cd = gvar_avgcorr(DF)
        if (m.estimated == 1) {
            cr = gvar_avgcorr(RS)
        }
        else {
            cr = J(nn, 1, .)
        }
        for (i = 1; i <= nn; i++) {
            OUT = OUT \ (j, own[i], cl[i], cd[i], cr[i])
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Residual diagnostics, one row per equation
//   1 unit  2 equation  3 F(sc) d.f.  4 F 5% cv  5 F(sc)
//   6 JB    7 JB p      8 ARCH chi2   9 ARCH p
//  10 mean 11 sd       12 skewness   13 kurtosis
//  14 min  15 max      16 White chi2 17 White d.f. 18 White p
//  19 R2   20 adjusted R2
//
// Columns 14-20 are the detail block.  The White statistic is the special
// form of White's test recommended when the regressor list is long relative
// to T: e^2 is regressed on the fitted value and its square, so the test
// always has 2 degrees of freedom and never runs out of observations.  A
// VECMX* equation here has up to 25 regressors against about 115 quarters,
// and the full cross-product form would need 350 of them.
// ---------------------------------------------------------------------------
real matrix gvar_resdiag(real scalar psc, real scalar archq)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, E, DY
    real rowvector fs, jb, ar, ds, wh
    real colvector fit
    real scalar i, j, N, nkp, Ti, sse, sst, r2, rb2

    m   = gvar_MODEL
    N   = m.N
    OUT = J(0, 20, .)

    for (i = 1; i <= N; i++) {
        E   = (*m.ep[i])'
        DY  = *m.dep[i]
        fs  = gvar_ftest_rsc(DY, *m.rgr[i], psc)
        Ti  = rows(E)
        // free parameters per equation: the short-run block returned by
        // gvar_mlcoint plus the r_i error-correction loadings of that equation
        nkp = cols(*m.rgr[i]) + m.rnk[i]
        for (j = 1; j <= m.ki[i]; j++) {
            jb  = gvar_jb(E[., j])
            ar  = gvar_arch1(E[., j], archq)
            ds  = gvar_dstats(E[., j])
            fit = DY[., j] - E[., j]
            wh  = gvar_hetwhite(E[., j], fit)
            sse = cross(E[., j], E[., j])
            sst = colsum((DY[., j] :- mean(DY[., j])) :^ 2)
            r2  = .
            rb2 = .
            if (sst > 0) {
                r2 = 1 - sse / sst
                if (Ti > nkp) rb2 = 1 - (1 - r2) * (Ti - 1) / (Ti - nkp)
            }
            OUT = OUT \ (i, j, fs[1], fs[2], fs[2 + j],
                         jb[1], jb[3], ar[1], ar[3],
                         ds[1], ds[5], ds[6], ds[7],
                         ds[4], ds[3], wh[1], wh[2], wh[3],
                         r2, rb2)
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Multivariate (system-wide) residual diagnostics, one row per country model.
//   (GVARX .jb.multi, .pt.multi, .bgserial, .arch.multi)
//
//   1 unit          2 k_i            3 T
//   4 JB            5 d.f.           6 p
//   7 skewness chi2 8 d.f.           9 p
//  10 kurtosis chi2 11 d.f.         12 p
//  13 Qh           14 d.f.          15 p
//  16 Qh*          17 d.f.          18 p
//  19 ARCH chi2    20 d.f.          21 p
//  22 BG LM        23 d.f.          24 p
//  25 ES F         26 d.f.1         27 d.f.2      28 p
//  29 h used by the portmanteau   30 h used by Breusch-Godfrey
//  31 q used by the ARCH test
//
// Columns 29-31 record the orders actually used.  They can fall below the
// requested ones when the auxiliary regression would otherwise have more
// regressors than observations; the table prints them so a shortened lag is
// never silently passed off as the one that was asked for.
//
// The ARCH block follows .gvar.arch, which standardises the residuals with
// scale() before forming the cross-products; the portmanteau and
// Breusch-Godfrey blocks follow .gvar.serial, which uses the raw residuals.
// ---------------------------------------------------------------------------
// Lag orders actually usable for the three system tests, given the block
// size, the sample and the width of the regressor matrix.  Shared by the
// asymptotic and the bootstrap driver so both use identical orders.
void gvar_mvorders(real scalar k, real scalar T, real scalar p, real scalar cX,
                   real scalar hpt, real scalar hbg, real scalar archq,
                   real scalar hp, real scalar hb, real scalar hq)
{
    real scalar na

    hp = hpt
    if (hp <= p)    hp = p + 1
    if (hp > T - 2) hp = T - 2

    hb = hbg
    while (hb > 1 & T <= cX + k * hb + k) hb = hb - 1

    na = 0.5 * k * (k + 1)
    hq = archq
    while (hq > 1 & (T - hq) < 3 * (1 + hq * na)) hq = hq - 1
    if ((T - hq) < 3 * (1 + hq * na)) hq = .
}

// The eight system-wide statistics, in one place so that the observed value
// and every bootstrap replicate are computed by identical code.
//   1 JB  2 skewness  3 kurtosis  4 Qh  5 Qh*  6 ARCH  7 BG LM  8 ES F
// All eight reject for large values.
real rowvector gvar_mvstats(real matrix E, real matrix X, real scalar p,
                            real scalar hp, real scalar hb, real scalar hq)
{
    real rowvector jb, pt, ar, bg, sg
    real matrix Es
    real scalar k, T, j, na

    k  = cols(E)
    T  = rows(E)
    Es = E :- mean(E)
    sg = sqrt(diagonal(cross(Es, Es) / (T - 1))')
    for (j = 1; j <= k; j++) {
        if (sg[j] > 0) Es[., j] = Es[., j] / sg[j]
    }

    jb = gvar_jbmulti(E)
    pt = gvar_portmanteau(E, hp, p, k)
    bg = gvar_bgserial(E, X, hb)
    na = 0.5 * k * (k + 1)
    if (hq < . & (T - hq) >= 3 * (1 + hq * na)) ar = gvar_archm(Es, hq)
    else                                        ar = J(1, 3, .)

    return((jb[1], jb[4], jb[7], pt[1], pt[4], ar[1], bg[1], bg[4]))
}

real matrix gvar_resdiag_mv(real scalar hpt, real scalar hbg, real scalar archq)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, E, Es, X
    real rowvector jb, pt, bg, ar, sg
    real scalar i, j, N, k, T, p, hp, hb, hq, na

    m   = gvar_MODEL
    N   = m.N
    OUT = J(0, 31, .)

    for (i = 1; i <= N; i++) {
        E = (*m.ep[i])'
        // .bgserial takes ylagged <- x$datamat[, -(1:K)], i.e. EVERY
        // regressor of the fitted model.  For a VECMX* that is the r_i
        // error-correction terms together with the short-run block; passing
        // the short-run block alone leaves the ECM in the auxiliary
        // regression's error and inflates the statistic in proportion to
        // r_i / k_i.
        X = (*m.ec[i])', (*m.rgr[i])
        k = cols(E)
        T = rows(E)
        p = m.lagord[i, 1]

        // scale(): centre each column and divide by its standard deviation
        Es = E :- mean(E)
        sg = sqrt(diagonal(cross(Es, Es) / (T - 1))')
        for (j = 1; j <= k; j++) {
            if (sg[j] > 0) Es[., j] = Es[., j] / sg[j]
        }

        // The portmanteau needs h > p for a positive d.f.; the
        // Breusch-Godfrey auxiliary regression needs T > cols(X) + k*h; and
        // the multivariate ARCH regression, which has 1 + q*k(k+1)/2
        // regressors, needs at least three observations per regressor.
        // GVARX's default q = 5 is meant for small VARs and saturates here:
        // a Monte Carlo at this model's own dimensions gives
        //
        //   observations per regressor   >= 3    2.0    1.8    1.5    1.2
        //   empirical size at nominal 5%  .06-.10  .052   .025   .005   .000
        //
        // Below a ratio of three the regression saturates and the test loses
        // all power rather than gaining size.
        gvar_mvorders(k, T, p, cols(X), hpt, hbg, archq, hp, hb, hq)

        jb = gvar_jbmulti(E)
        pt = gvar_portmanteau(E, hp, p, k)
        bg = gvar_bgserial(E, X, hb)
        na = 0.5 * k * (k + 1)
        if (hq < . & (T - hq) >= 3 * (1 + hq * na)) ar = gvar_archm(Es, hq)
        else                                        ar = J(1, 3, .)

        OUT = OUT \ (i, k, T,
                     jb[1], jb[2], jb[3],
                     jb[4], jb[5], jb[6],
                     jb[7], jb[8], jb[9],
                     pt[1], pt[2], pt[3],
                     pt[4], pt[5], pt[6],
                     ar[1], ar[2], ar[3],
                     bg[1], bg[2], bg[3],
                     bg[4], bg[5], bg[6], bg[7],
                     hp, hb, hq)
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Parametric-bootstrap p-values for the system-wide diagnostics.
//
// The asymptotic distributions of these statistics are not dependable at the
// dimensions of a country model.  A Monte Carlo that simulates from each
// fitted VARX* and re-estimates puts the adjusted portmanteau Qh* at three
// to nine times its nominal size, rising with k, and the Edgerton-Shukur F
// at about twice nominal for a unit whose cointegrating rank is close to its
// block size.  The asymptotic Qh at h = 16 and the multivariate Jarque-Bera
// are the only two that hold up.
//
// Each replication draws u_t ~ N(0, Omega_i), builds y_t forward from the
// estimated VARX* holding the weakly exogenous block at its observed path,
// re-estimates the VECMX* at the same (p, q, case, rank), and recomputes all
// eight statistics with the SAME lag orders as the observed ones.  The
// p-value is (1 + #{bootstrap >= observed}) / (1 + replications).
//
// This is the device the Toolbox uses for the structural stability tests
// (bootstrap_GVAR_ss.m); the weakly exogenous block is held fixed because it
// is weakly exogenous for the country model's parameters by assumption.
//
//   1 unit  2 replications that converged
//   3 JB  4 skewness  5 kurtosis  6 Qh  7 Qh*  8 ARCH  9 BG LM  10 ES F
// ---------------------------------------------------------------------------
real matrix gvar_resdiag_mvboot(real scalar hpt, real scalar hbg,
                                real scalar archq, real scalar reps)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, E, X, Y, S, Th, L0, Lm, C, Ys, Eb, Xb
    real matrix beta, alpha, Psi, eps, Om2, ecm, DX, dep
    pointer(real matrix) colvector bdep, brgr
    real colvector a0, a1, yt
    real rowvector obs, bs, cnt, pv
    real scalar i, j, l, t, b, N, k, ks, T, Traw, p, q, ml, ec, rk
    real scalar hp, hb, hq, nok, ll, ai, sb

    m   = gvar_MODEL
    N   = m.N
    ml  = m.pmax
    OUT = J(0, 10, .)

    beta  = J(0, 0, .)
    alpha = J(0, 0, .)
    Psi   = J(0, 0, .)
    eps   = J(0, 0, .)
    Om2   = J(0, 0, .)
    ecm   = J(0, 0, .)
    DX    = J(0, 0, .)
    dep   = J(0, 0, .)
    ll    = .
    ai    = .
    sb    = .

    for (i = 1; i <= N; i++) {
        E  = (*m.ep[i])'
        X  = (*m.ec[i])', (*m.rgr[i])
        k  = cols(E)
        T  = rows(E)
        p  = m.lagord[i, 1]
        q  = m.lagord[i, 2]
        ec = m.ecase[i]
        rk = m.rnk[i]

        gvar_mvorders(k, T, p, cols(X), hpt, hbg, archq, hp, hb, hq)
        obs = gvar_mvstats(E, X, p, hp, hb, hq)

        Y    = *m.Yi[i]
        S    = *m.Si[i]
        a0   = *m.a0[i]
        a1   = *m.a1[i]
        Th   = *m.Th[i]
        L0   = *m.L0[i]
        Lm   = *m.Lm[i]
        ks   = cols(S)
        Traw = rows(Y)
        C    = cholesky(makesymmetric(*m.Om[i]))

        cnt = J(1, 8, 0)
        nok = 0

        if (hasmissing(C) == 0) {
            for (b = 1; b <= reps; b++) {
                Ys = Y
                for (t = ml + 1; t <= Traw; t++) {
                    yt = a0 + a1 * t
                    for (l = 1; l <= ml; l++) {
                        yt = yt + Th[., ((l-1)*k+1)::(l*k)] * Ys[t-l, .]'
                    }
                    if (ks > 0) {
                        yt = yt + L0 * S[t, .]'
                        for (l = 1; l <= ml; l++) {
                            yt = yt +
                                 Lm[., ((l-1)*ks+1)::(l*ks)] * S[t-l, .]'
                        }
                    }
                    Ys[t, .] = (yt + C * rnormal(k, 1, 0, 1))'
                }

                gvar_mlcoint(Ys, S, p, q, ml, ec, rk, beta, alpha, Psi,
                             eps, Om2, ecm, DX, dep, ll, ai, sb)
                Eb = eps'
                if (hasmissing(Eb)) continue
                Xb = ecm', DX
                bs = gvar_mvstats(Eb, Xb, p, hp, hb, hq)
                nok = nok + 1
                for (j = 1; j <= 8; j++) {
                    if (bs[j] < . & obs[j] < . & bs[j] >= obs[j]) {
                        cnt[j] = cnt[j] + 1
                    }
                }
            }
        }

        pv = J(1, 8, .)
        if (nok > 0) {
            for (j = 1; j <= 8; j++) {
                if (obs[j] < .) pv[j] = (1 + cnt[j]) / (1 + nok)
            }
        }
        OUT = OUT \ (i, nok, pv)
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Structural stability battery, one row per equation
//   (Toolbox structural_stability_tests.m, kraplob.m, nyblom.m, schow.m)
//   1 unit 2 equation 3 PKsup 4 PKmsq 5 Nyblom 6 robust Nyblom
//   7 QLR  8 MW       9 APW  10 robust QLR 11 robust MW 12 robust APW
//  13 break observation
// ---------------------------------------------------------------------------
real matrix gvar_stabtests(real scalar ccut)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, DY, DX
    real rowvector kp, ny, sc
    real scalar i, j, N

    m   = gvar_MODEL
    N   = m.N
    OUT = J(0, 13, .)

    for (i = 1; i <= N; i++) {
        DY = *m.dep[i]
        DX = *m.rgr[i]
        for (j = 1; j <= m.ki[i]; j++) {
            kp = gvar_kraplob(DY[., j], DX)
            ny = gvar_nyblom(DY[., j], DX)
            sc = gvar_schow(DY[., j], DX, ccut)
            OUT = OUT \ (i, j, kp[1], kp[2], ny[1], ny[2],
                         sc[1], sc[2], sc[3], sc[4], sc[5], sc[6], sc[7])
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Estimate every country VECMX* and recover its VARX* representation
//   (Toolbox gvar.m section 3.7, mlcoint.m, mlcoint_r.m, vecx2varx.m)
//
// betar is a pointer vector of imposed cointegrating vectors, one entry per
// unit; a NULL entry means that unit is estimated exactly identified.
// ---------------------------------------------------------------------------
void gvar_estim(pointer(real matrix) colvector betar)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix beta, alpha, Psi, eps, Om, ecm, DX, dep, Th, L0, Lm
    real colvector a0, a1
    real scalar i, N, ml, ll, ai, sb, userestr

    m  = gvar_MODEL
    N  = m.N
    ml = m.pmax

    m.al  = J(N, 1, NULL)
    m.be  = J(N, 1, NULL)
    m.ben = J(N, 1, NULL)
    m.Ps  = J(N, 1, NULL)
    m.ep  = J(N, 1, NULL)
    m.Om  = J(N, 1, NULL)
    m.ec  = J(N, 1, NULL)
    m.sd  = J(N, 1, NULL)
    m.sdw = J(N, 1, NULL)
    m.sdn = J(N, 1, NULL)
    m.rgr = J(N, 1, NULL)
    m.dep = J(N, 1, NULL)
    m.a0  = J(N, 1, NULL)
    m.a1  = J(N, 1, NULL)
    m.Th  = J(N, 1, NULL)
    m.L0  = J(N, 1, NULL)
    m.Lm  = J(N, 1, NULL)
    m.logl = J(N, 1, .)
    m.aic  = J(N, 1, .)
    m.sbc  = J(N, 1, .)

    for (i = 1; i <= N; i++) {
        userestr = 0
        if (rows(betar) >= i) {
            if (betar[i] != NULL) {
                userestr = 1
            }
        }

        if (userestr == 1) {
            gvar_mlcoint_r(*m.Yi[i], *m.Si[i], m.lagord[i,1], m.lagord[i,2],
                           ml, m.ecase[i], *betar[i],
                           alpha, Psi, eps, Om, ecm, DX, dep, ll, ai, sb)
            beta = *betar[i]
            m.ben[i] = &(beta[., .])
        }
        else {
            gvar_mlcoint(*m.Yi[i], *m.Si[i], m.lagord[i,1], m.lagord[i,2],
                         ml, m.ecase[i], m.rnk[i],
                         beta, alpha, Psi, eps, Om, ecm, DX, dep, ll, ai, sb)
            m.ben[i] = &(gvar_betanorm(beta, m.rnk[i], m.ecase[i]))
        }

        m.be[i]  = &(beta[., .])
        m.al[i]  = &(alpha[., .])
        m.Ps[i]  = &(Psi[., .])
        m.ep[i]  = &(eps[., .])
        m.Om[i]  = &(Om[., .])
        m.ec[i]  = &(ecm[., .])
        m.rgr[i] = &(DX[., .])
        m.dep[i] = &(dep[., .])
        m.logl[i] = ll
        m.aic[i]  = ai
        m.sbc[i]  = sb

        m.sd[i]  = &(gvar_se_ols(DX, eps'))
        m.sdw[i] = &(gvar_se_white(DX, eps'))
        m.sdn[i] = &(gvar_se_nw(DX, eps'))

        gvar_vecx2varx(ml, m.ki[i], m.ksi[i], m.lagord[i,1], m.lagord[i,2],
                       m.ecase[i], alpha, beta, Psi, a0, a1, Th, L0, Lm)
        m.a0[i] = &(a0[., .])
        m.a1[i] = &(a1[., .])
        m.Th[i] = &(Th[., .])
        m.L0[i] = &(L0[., .])
        m.Lm[i] = &(Lm[., .])
    }

    m.estimated = 1
    m.solved    = 0
    m.esttype   = "vecmx"
    gvar_MODEL  = m
}

// ---------------------------------------------------------------------------
// Link matrices, stacking and the reduced form
//   (Toolbox create_linkmatrices.m, solve_GVAR.m)
// ---------------------------------------------------------------------------
void gvar_solvemodel()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix G0, Hs, Fs, zeta, eta, Sz, Se, Cbar
    real colvector h0, h1, d0, d1
    real scalar i, N, K, ml, ndu, NS
    pointer(real matrix)    colvector Wl, ThL, L0L, LmL
    pointer(real colvector) colvector a0L, a1L
    real colvector kiL, ksiL
    real matrix duThv, duL0v, duLmv
    real colvector dua0v, dua1v

    m  = gvar_MODEL
    N  = m.N
    K  = m.K
    ml = m.pmax

    m.Wlink = J(N, 1, NULL)
    for (i = 1; i <= N; i++) {
        m.Wlink[i] = &(gvar_linkmat(i, K, m.ki, m.xname, m.xunit,
                                    *m.ylist[i], *m.slist[i], *m.sglob[i],
                                    m.vname, m.vtype, m.Wsol))
    }

    // The dominant block is handed to the stacker as unit N+1 and to nothing
    // else.  solve_GVAR.m's H0 = [G0 -J0 ; 0 I] has a zero in its second row
    // because feedback reaches the dominant unit only at lags, so L0 = 0 and
    // Lm = Lambda_du make it an ordinary unit here.
    ndu = 0
    if (m.hasdu == 1) ndu = 1
    NS  = N + ndu

    Wl = m.Wlink; ThL = m.Th; L0L = m.L0; LmL = m.Lm
    a0L = m.a0;   a1L = m.a1
    kiL = m.ki;   ksiL = m.ksi

    if (ndu == 1) {
        // copied into plain locals first: these have to outlive the
        // expression that takes their address
        duThv = m.duTh; duL0v = m.duL0; duLmv = m.duLm
        dua0v = m.dua0; dua1v = m.dua1

        Wl  = Wl  \ &(gvar_dulink(K))
        ThL = ThL \ &duThv
        L0L = L0L \ &duL0v
        LmL = LmL \ &duLmv
        a0L = a0L \ &dua0v
        a1L = a1L \ &dua1v
        kiL  = kiL  \ rows(m.duylist)
        ksiL = ksiL \ m.dunfb
    }

    gvar_stack(NS, K, ml, Wl, a0L, a1L, ThL, L0L, LmL,
               kiL, ksiL, G0, Hs, h0, h1)

    gvar_reduce(m.X, ml, G0, Hs, h0, h1, Fs, d0, d1, zeta, eta, Sz, Se)

    Cbar = gvar_companion(Fs, K, ml)

    m.G0    = G0
    m.Hs    = Hs
    m.Fs    = Fs
    m.h0    = h0
    m.h1    = h1
    m.d0    = d0
    m.d1    = d1
    m.zeta  = zeta
    m.eta   = eta
    m.Szeta = Sz
    m.Seta  = Se
    // abs() of a COMPLEX vector is the modulus sqrt(Re^2+Im^2), which is what an
    // eigenvalue modulus means.  This used to read abs(Re(eigenvalues(Cbar))'),
    // the absolute value of the real part -- a different and smaller quantity for
    // every complex eigenvalue.  Consequences, all found by comparing the
    // spectrum with the Toolbox demo's own eigenval sheet:
    //   * complex moduli were understated, so the sorted spectrum diverged from
    //     the reference by up to 0.129 in the middle;
    //   * a nearly-imaginary eigenvalue reported ~0, giving 31 zeros where the
    //     reference has 6;
    //   * and the STABILITY TEST could pass an explosive model.  A complex pair
    //     with modulus 1.2 and real part 0.5 was reported as 0.5, i.e. stable.
    // The unit-root count was unaffected because those roots are real at 1, where
    // |Re(lambda)| and |lambda| coincide -- which is exactly why every check the
    // suite ran on this quantity passed.
    m.eigmod = sort(abs(eigenvalues(Cbar))', -1)
    m.solved = 1

    gvar_MODEL = m
}

// ---- accessors for the solved objects -------------------------------------
// NOTE: every function body is written out in full.  Mata rejects a compressed
// one-line braced block such as  f() { stmt ; return(x) }  -- the parser stops
// at the closing brace with "'}' found where nothing expected".

real matrix gvar_getG0()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.G0)
}

real matrix gvar_getHs()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.Hs)
}

real matrix gvar_getFs()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.Fs)
}

real matrix gvar_getSzeta()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.Szeta)
}

real matrix gvar_getSeta()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.Seta)
}

real matrix gvar_getzeta()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.zeta)
}

real matrix gvar_geteta()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.eta)
}

real colvector gvar_geteig()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.eigmod)
}

real colvector gvar_getd0()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.d0)
}

real colvector gvar_getd1()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.d1)
}

real matrix gvar_getWlink(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Wlink[i])
}

real matrix gvar_getbeta(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.ben[i])
}

real matrix gvar_getbetaraw(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.be[i])
}

real matrix gvar_getalpha(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.al[i])
}

real matrix gvar_geteps(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.ep[i])
}

real matrix gvar_getOmega(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Om[i])
}

real matrix gvar_getPsi(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Ps[i])
}

real matrix gvar_getse(real scalar i, real scalar which)
{
    external struct gvarmodel scalar gvar_MODEL

    if (which == 2) {
        return(*gvar_MODEL.sdw[i])
    }
    if (which == 3) {
        return(*gvar_MODEL.sdn[i])
    }
    return(*gvar_MODEL.sd[i])
}

real matrix gvar_getfit()
{
    external struct gvarmodel scalar gvar_MODEL
    return((gvar_MODEL.logl, gvar_MODEL.aic, gvar_MODEL.sbc))
}

real matrix gvar_getTh(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Th[i])
}

real matrix gvar_getL0(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.L0[i])
}

real matrix gvar_getLm(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.Lm[i])
}

real colvector gvar_geta0(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.a0[i])
}

real colvector gvar_geta1(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.a1[i])
}

real matrix gvar_getecm(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.ec[i])
}

real matrix gvar_getreg(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.rgr[i])
}

real matrix gvar_getdep(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.dep[i])
}

// The short-run regressor block of unit i's VECMX*, as the stability and
// fluctuation routines see it: the ECM terms followed by the differenced
// regressors and the deterministics.
real matrix gvar_getrgr(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    return(*gvar_MODEL.rgr[i])
}

// The long-run matrix Pi = alpha * Beta', with the restricted deterministic
// row removed, exactly as gvar_vecx2varx() forms it.  Uses the RAW beta (not
// the normalised one), which is what the recovery was based on.
real matrix gvar_getPi(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix A, B

    m = gvar_MODEL
    A = *m.al[i]
    B = *m.be[i]
    if (cols(B) == 0) {
        return(J(m.ki[i], m.ki[i] + m.ksi[i], 0))
    }
    if (m.ecase[i] == 4 | m.ecase[i] == 2) {
        B = B[2::rows(B), .]
    }
    return(A * B')
}

// ---------------------------------------------------------------------------
// VARX*(p,q) order selection  (Toolbox select_varxlag.m, gvar.m section 3.5)
//
// The Toolbox uses the DdPS *levels* form of AIC and SBC, in which LARGER is
// better (see _INVENTORY.md trap 2), and trims every candidate by the same
// global maxlag so the criteria are comparable across the grid.
//
// icsel = 2 selects on AIC, 3 on SBC.
// Returns N x 8: p, q, logL, AIC, SBC, F-serial d.f., 5% F critical value,
// largest F statistic across the unit's equations.
// ---------------------------------------------------------------------------
real matrix gvar_lagsel(real scalar maxp, real scalar maxq,
                        real scalar icsel, real scalar psc)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT
    real scalar i, p, q, N, ml, bestp, bestq, bestv, first
    real rowvector las, fsc

    m   = gvar_MODEL
    N   = m.N
    ml  = max((maxp, maxq))
    OUT = J(N, 8, .)

    for (i = 1; i <= N; i++) {
        first = 1
        bestv = .
        bestp = 1
        bestq = 1
        for (p = 1; p <= maxp; p++) {
            for (q = 1; q <= maxq; q++) {
                gvar_varsel(*m.Yi[i], *m.Si[i], p, q, ml, psc, las, fsc)
                if (las[icsel] < .) {
                    if (first == 1) {
                        bestv = las[icsel]
                        bestp = p
                        bestq = q
                        first = 0
                    }
                    else if (las[icsel] > bestv) {
                        bestv = las[icsel]
                        bestp = p
                        bestq = q
                    }
                }
            }
        }
        gvar_varsel(*m.Yi[i], *m.Si[i], bestp, bestq, ml, psc, las, fsc)
        OUT[i, 1] = bestp
        OUT[i, 2] = bestq
        OUT[i, 3] = las[1]
        OUT[i, 4] = las[2]
        OUT[i, 5] = las[3]
        OUT[i, 6] = fsc[1]
        OUT[i, 7] = fsc[2]
        if (cols(fsc) >= 3) {
            OUT[i, 8] = max(fsc[3::cols(fsc)])
        }
    }
    return(OUT)
}

// The full (p,q) grid for one unit, for gvar lags, detail
real matrix gvar_laggrid(real scalar i, real scalar maxp, real scalar maxq,
                         real scalar psc)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT
    real scalar p, q, ml, r
    real rowvector las, fsc

    m   = gvar_MODEL
    ml  = max((maxp, maxq))
    OUT = J(maxp * maxq, 7, .)
    r   = 0
    for (p = 1; p <= maxp; p++) {
        for (q = 1; q <= maxq; q++) {
            r = r + 1
            gvar_varsel(*m.Yi[i], *m.Si[i], p, q, ml, psc, las, fsc)
            OUT[r, 1] = p
            OUT[r, 2] = q
            OUT[r, 3] = las[1]
            OUT[r, 4] = las[2]
            OUT[r, 5] = las[3]
            OUT[r, 6] = fsc[2]
            if (cols(fsc) >= 3) {
                OUT[r, 7] = max(fsc[3::cols(fsc)])
            }
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Cointegration tests and rank selection
//   (Toolbox cointegration_test.m, get_rank.m)
//
// CV is the shipped Pesaran-Shin-Smith table, stacked as
// (dcase, stat, n-r, k, cv95).  For a unit with n endogenous and k weakly
// exogenous I(1) regressors, the statistic testing H0: r = j-1 is compared
// with the critical value at n-r = n-j+1, which is exactly the flipud() in
// get_rank.m.
//
// Returns one row per (unit, j) with
//   1 unit  2 j (so H0 is r = j-1)  3 eigenvalue
//   4 trace  5 trace 95% cv  6 max-eigenvalue  7 max-eig 95% cv
// ---------------------------------------------------------------------------
real scalar gvar_cvlook(real matrix CV, real scalar dcase, real scalar stat,
                        real scalar nr, real scalar k)
{
    real scalar q

    for (q = 1; q <= rows(CV); q++) {
        if (CV[q,1] == dcase & CV[q,2] == stat & CV[q,3] == nr & CV[q,4] == k) {
            return(CV[q, 5])
        }
    }
    return(.)
}

real matrix gvar_cointall(real matrix CV)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT
    real colvector lam, tr, mx
    real scalar i, j, N, n, k, ml, tcv, mcv

    m   = gvar_MODEL
    N   = m.N
    ml  = m.pmax
    OUT = J(0, 9, .)

    for (i = 1; i <= N; i++) {
        n = m.ki[i]
        k = m.ksi[i]
        gvar_cointtest(*m.Yi[i], *m.Si[i], m.lagord[i,1], m.lagord[i,2],
                       ml, m.ecase[i], lam, tr, mx)
        for (j = 1; j <= n; j++) {
            tcv = gvar_cvlook(CV, m.ecase[i], 1, n - j + 1, k)
            mcv = gvar_cvlook(CV, m.ecase[i], 2, n - j + 1, k)
            OUT = OUT \ (i, j, lam[j], tr[j], tcv, mx[j], mcv, n, k)
        }
    }
    return(OUT)
}

// Sequential rank determination: stop at the first non-rejection
// (Toolbox get_rank.m; stat = 1 trace, 2 maximum eigenvalue)
real colvector gvar_rankfrom(real matrix R, real scalar stat, real scalar N)
{
    real colvector rk
    real scalar q, i, sc, cc

    rk = J(N, 1, 0)
    for (i = 1; i <= N; i++) {
        for (q = 1; q <= rows(R); q++) {
            if (R[q, 1] == i) {
                if (stat == 1) {
                    sc = R[q, 4]
                    cc = R[q, 5]
                }
                else {
                    sc = R[q, 6]
                    cc = R[q, 7]
                }
                // A MISSING critical value means the Pesaran-Shin-Smith table
                // does not cover this (case, n-r, k) combination.  It must
                // never be read as a non-rejection -- doing so silently
                // reports rank 0 for a unit that was simply not testable.
                if (cc >= .) {
                    rk[i] = .
                    break
                }
                if (sc < . & sc > cc) {
                    rk[i] = rk[i] + 1
                }
                else {
                    break
                }
            }
        }
    }
    return(rk)
}

// ---------------------------------------------------------------------------
// Unit-root battery over every variable block  (Toolbox unitroot_tests.m)
//
// Blocks, exactly as the Toolbox reports them:
//   1  levels, intercept and trend
//   2  levels, intercept only
//   3  first differences, intercept only
//   4  second differences, intercept only
//
// The lag order is chosen by minimising AIC (icsel=2) or SBC (icsel=3) over
// p = 1..maxlag of the ADF regression, and -- faithfully to the Toolbox -- the
// WS statistic is then read off at that SAME lag rather than re-selected.
//
// Returns one row per (kind, unit, variable, block) with columns
//   1 kind (1 domestic, 2 foreign)   2 unit   3 variable   4 block
//   5 ADF      6 ADF 5% cv   7 ADF lag
//   8 WS       9 WS 5% cv
//  10 ADF-GLS 11 KPSS       12 PP Z(t)
// ---------------------------------------------------------------------------
real matrix gvar_urt(real scalar maxlag, real scalar icsel)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, A, Blk
    real colvector ser, use_
    real scalar i, j, b, p, N, nv, kind, best, bestv, dd, lk
    real rowvector a1, w1, row
    real scalar adfcv, wscv, ws1, gls1, kp1, pp1
    real rowvector g1, k1, p1

    m   = gvar_MODEL
    N   = m.N
    OUT = J(0, 12, .)

    for (kind = 1; kind <= 2; kind++) {
        for (i = 1; i <= N; i++) {
            if (kind == 1) {
                Blk = *m.Yi[i]
                nv  = m.ki[i]
            }
            else {
                Blk = *m.Si[i]
                nv  = m.ksi[i]
            }
            for (j = 1; j <= nv; j++) {
                for (b = 1; b <= 4; b++) {
                    ser = Blk[., j]
                    dd  = 0
                    if (b == 1) {
                        dd = 1
                    }
                    if (b == 3) {
                        ser = ser[2::rows(ser)] - ser[1::(rows(ser)-1)]
                    }
                    if (b == 4) {
                        ser = ser[2::rows(ser)] - ser[1::(rows(ser)-1)]
                        ser = ser[2::rows(ser)] - ser[1::(rows(ser)-1)]
                    }

                    // choose the lag on the ADF information criterion
                    best  = 1
                    bestv = .
                    for (p = 1; p <= maxlag; p++) {
                        a1 = gvar_adf(ser, dd, p)
                        if (a1[icsel] < . & a1[icsel] < bestv) {
                            bestv = a1[icsel]
                            best  = p
                        }
                    }
                    a1 = gvar_adf(ser, dd, best)
                    ws1 = gvar_ws(ser, dd, best)

                    g1 = gvar_adfgls(ser, dd, best)
                    lk = floor(4 * (rows(ser) / 100)^(2 / 9))
                    if (lk < 1) {
                        lk = 1
                    }
                    k1 = gvar_kpss(ser, dd, lk)
                    p1 = gvar_ppz(ser, dd, lk)

                    // DdPS asymptotic 5% critical values
                    if (dd == 1) {
                        adfcv = -3.45
                        wscv  = -3.24
                    }
                    else {
                        adfcv = -2.89
                        wscv  = -2.55
                    }

                    row = (kind, i, j, b, a1[1], adfcv, best,
                           ws1, wscv, g1[1], k1[1], p1[1])
                    OUT = OUT \ row
                }
            }
        }
    }
    return(OUT)
}

// Name of variable j of unit i in the domestic (kind 1) or foreign (kind 2)
// block, used by the reporting layer.
string scalar gvar_urtname(real scalar kind, real scalar i, real scalar j)
{
    external struct gvarmodel scalar gvar_MODEL

    if (kind == 1) {
        return((*gvar_MODEL.ylist[i])[j])
    }
    return((*gvar_MODEL.slist[i])[j])
}

// Rectangularise one (kind, block, statistic) slice of the gvar_urt() output
// into an N x 2*nv matrix -- statistics in the first nv columns, the matching
// critical values in the next nv.  Doing this here keeps the reporting layer
// O(N*nv) instead of scanning the whole result matrix for every cell.
// The variable names are returned in the local __urtvars.
real matrix gvar_urt_tab(real matrix R, real scalar kind, real scalar b,
                         real scalar col, real scalar cvcol)
{
    external struct gvarmodel scalar gvar_MODEL
    string colvector vl
    string scalar vn
    real matrix TAB
    real scalar q, i, p, nv, N

    N  = gvar_MODEL.N
    vl = J(0, 1, "")
    for (q = 1; q <= rows(R); q++) {
        if (R[q, 1] == kind & R[q, 4] == b) {
            vn = gvar_urtname(kind, R[q, 2], R[q, 3])
            if (gvar_pos(vl, vn) == 0) {
                vl = vl \ vn
            }
        }
    }
    nv = rows(vl)
    st_local("__urtvars", invtokens(vl'))
    if (nv == 0) {
        return(J(N, 0, .))
    }

    // Three blocks of nv columns: the statistic, its critical value, and an
    // OWNERSHIP flag.  The third is what lets the table tell "this country has
    // no long rate" apart from "the test failed".  Without it both look like a
    // missing value, and a reader cannot tell a structural blank from a
    // computational failure -- which is the difference between a fact about
    // the data and a bug.
    TAB = J(N, 3 * nv, .)
    for (q = 1; q <= rows(R); q++) {
        if (R[q, 1] == kind & R[q, 4] == b) {
            i  = R[q, 2]
            vn = gvar_urtname(kind, R[q, 2], R[q, 3])
            p  = gvar_pos(vl, vn)
            TAB[i, p]          = R[q, col]
            TAB[i, nv + p]     = R[q, cvcol]
            TAB[i, 2 * nv + p] = 1
        }
    }
    return(TAB)
}

// ---------------------------------------------------------------------------
// Build weight matrices from long bilateral-flow data.
//
// Faithful to Toolbox build_wmat.m: the FLOWS are averaged over the relevant
// years first, and the weights are computed from the averaged flows -- not
// the other way round.
//
//   sv, dv, fv, yv : names of the source-index, destination-index, flow and
//                    year variables in the data currently in memory
//   tvflag = 0     : one fixed matrix from the flows averaged over all years
//   tvflag = 1     : one matrix per year, plus a solution matrix built from
//                    the flows averaged over the last `window' years
// ---------------------------------------------------------------------------
void _gvar_flowmat(string scalar sv, string scalar dv, string scalar fv,
                   string scalar yv, real scalar N, real scalar typ,
                   real scalar tvflag, real scalar window)
{
    real colvector si, di, fl, yr, uy
    real matrix F, C, WS, FS, CS
    real scalar n, t, i, j, y, ny, lo, nn

    si = st_data(., sv)
    di = st_data(., dv)
    fl = st_data(., fv)
    n  = rows(si)

    // ---------------- fixed weights ---------------------------------------
    //
    // Divide by the number of YEARS, never by the number of contributing rows.
    //
    // This is the whole aggregation.  build_wmat.m takes mean(trd_trm) over the
    // year window for each country's own sheet, and only THEN update_matrix sums
    // the region's members.  So a cell must be summed across members and
    // averaged across years -- two different reductions over the same
    // accumulator.
    //
    // The first version divided by a per-cell count of contributing
    // observations.  For an ordinary unit that count is the number of years and
    // the answer is right; for an aggregated region it is members x years, so
    // the euro area came out as the AVERAGE of its eight members instead of
    // their SUM.  On the shipped demo that put euro's weight on usa at 0.009
    // against the Toolbox's 0.145, and because every column is renormalised the
    // error propagated into all 676 cells -- each column short by its own euro
    // share, so it did not even look like a constant rescaling.  Columns still
    // summed to one, so the one invariant being checked passed throughout.
    if (tvflag == 0) {
        ny = 1
        if (yv != "") {
            yr = st_data(., yv)
            ny = rows(uniqrows(yr))
        }
        F = J(N, N, 0)
        for (t = 1; t <= n; t++) {
            if (fl[t] < .) {
                F[si[t], di[t]] = F[si[t], di[t]] + fl[t]
            }
        }
        if (ny > 1) {
            F = F / ny
        }
        gvar_setw(typ, gvar_weightmat(F))
        return
    }

    // ---------------- time-varying weights --------------------------------
    yr = st_data(., yv)
    uy = uniqrows(yr)
    ny = rows(uy)

    WS = J(N * ny, N, 0)
    for (y = 1; y <= ny; y++) {
        F = J(N, N, 0)
        C = J(N, N, 0)
        for (t = 1; t <= n; t++) {
            if (yr[t] == uy[y] & fl[t] < .) {
                F[si[t], di[t]] = F[si[t], di[t]] + fl[t]
                C[si[t], di[t]] = C[si[t], di[t]] + 1
            }
        }
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= N; j++) {
                if (C[i, j] > 0) {
                    F[i, j] = F[i, j] / C[i, j]
                }
            }
        }
        WS[((y-1)*N+1)::(y*N), .] = gvar_weightmat(F)
    }

    // the solution matrix: average the FLOWS over the last `window' years,
    // then normalise once
    lo = ny - window + 1
    if (lo < 1) {
        lo = 1
    }
    nn = ny - lo + 1
    FS = J(N, N, 0)
    CS = J(N, N, 0)
    for (t = 1; t <= n; t++) {
        if (yr[t] >= uy[lo] & fl[t] < .) {
            FS[si[t], di[t]] = FS[si[t], di[t]] + fl[t]
            CS[si[t], di[t]] = CS[si[t], di[t]] + 1
        }
    }
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= N; j++) {
            if (CS[i, j] > 0) {
                FS[i, j] = FS[i, j] / CS[i, j]
            }
        }
    }

    st_matrix("__gvar_WS", WS)
    st_matrix("__gvar_FS", gvar_weightmat(FS))
    st_numscalar("__gvar_ny", ny)
    st_matrix("__gvar_uy", uy)
}

// ---------------------------------------------------------------------------
// Install a full specification grid over the defaults.
//
// A variable can only be declared endogenous for a unit if it is actually
// observed there, so dflag from the grid is intersected with observability;
// anything the grid asks for but the data cannot supply is reported.
// PQ holds p, q, dcase and rank, any of which may be missing.
// ---------------------------------------------------------------------------
void _gvar_apply_spec(real matrix DF, real matrix FF, real matrix GF,
                      real matrix PQ)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, j, N, V, G, nb
    string scalar bad

    m = gvar_MODEL
    N = m.N
    V = m.V
    G = rows(m.gvname)

    bad = ""
    nb  = 0
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= V; j++) {
            if (DF[i, j] == 1 & m.dflag[i, j] == 0) {
                nb  = nb + 1
                bad = bad + " " + m.cname[i] + ":" + m.vname[j]
                DF[i, j] = 0
            }
        }
    }
    st_local("__gvspecbad", strtrim(bad))
    st_local("__gvspecnbad", strofreal(nb))

    m.dflag = DF
    m.fflag = FF
    // A grid can only say 0 (absent) or 1 (weakly exogenous) for a global
    // variable; an "endogenous here" assignment made with gendog() carries a
    // 2 and must survive, so that spec() and gendog() compose.
    if (G > 0 & cols(GF) == G) {
        for (i = 1; i <= N; i++) {
            for (j = 1; j <= G; j++) {
                if (m.gflag[i, j] != 2) {
                    m.gflag[i, j] = GF[i, j]
                }
            }
        }
    }

    for (i = 1; i <= N; i++) {
        if (PQ[i, 1] < .) {
            m.lagord[i, 1] = PQ[i, 1]
        }
        if (PQ[i, 2] < .) {
            m.lagord[i, 2] = PQ[i, 2]
        }
        if (PQ[i, 3] < .) {
            m.ecase[i] = PQ[i, 3]
        }
        if (PQ[i, 4] < .) {
            m.rnk[i] = PQ[i, 4]
        }
    }
    m.pmax = max(m.lagord)

    gvar_MODEL = m
}

// Map every period of the estimation window onto a flow-year block.
// Periods before the first flow year use the first block, periods after the
// last flow year use the last block, exactly as build_wmat.m does.
void _gvar_yrmap(real colvector yv)
{
    external struct gvarmodel scalar gvar_MODEL
    real colvector tv, yrid, cy
    real scalar T, t, ny, best, i

    ny = rows(yv)
    tv = gvar_MODEL.tvals
    T  = rows(tv)

    // convert the Stata date into a calendar year for matching
    cy = J(T, 1, 0)
    for (t = 1; t <= T; t++) {
        if (gvar_MODEL.freq == 1) {
            cy[t] = tv[t]
        }
        else if (gvar_MODEL.freq == 4) {
            cy[t] = 1960 + floor(tv[t] / 4)
        }
        else if (gvar_MODEL.freq == 12) {
            cy[t] = 1960 + floor(tv[t] / 12)
        }
        else {
            cy[t] = 1960 + floor(tv[t] / 365.25)
        }
    }

    yrid = J(T, 1, 1)
    for (t = 1; t <= T; t++) {
        best = 1
        for (i = 1; i <= ny; i++) {
            if (yv[i] <= cy[t]) {
                best = i
            }
        }
        yrid[t] = best
    }
    st_matrix("__gvar_yrid", yrid)
}


// =========================================================================
// =====  from _gvar_foreign.ado                                            
// =========================================================================


// Write each unit's star variables back into the Stata dataset, aligned on
// the (unit, time) sort order established by gvar setup.
void _gvar_write_stars(string scalar pre, string scalar suf, real scalar repl)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, j, N, Traw, idx, nv
    string scalar vn
    string colvector allnames
    real matrix OUT
    real colvector col

    m    = gvar_MODEL
    N    = m.N
    Traw = m.Traw

    // Writing back relies on the dataset still being in the unit-major sort
    // order established by gvar setup, with one row per (unit, period).
    if (st_nobs() != N * Traw) {
        errprintf("gvar foreign, generate: the dataset no longer has exactly "
                  + "one row per unit and period (an if/in restriction or a change "
                  + "to the data breaks the row mapping). Re-run gvar setup on the "
                  + "estimation sample, or omit generate." + "\n")
        exit(459)
    }

    // the union of every unit's weakly exogenous variable names
    allnames = J(0, 1, "")
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= m.ksi[i]; j++) {
            vn = (*m.slist[i])[j]
            if (gvar_pos(allnames, vn) == 0) {
                allnames = allnames \ vn
            }
        }
    }
    nv = rows(allnames)
    if (nv == 0) {
        return
    }

    OUT = J(N * Traw, nv, .)
    for (i = 1; i <= N; i++) {
        for (j = 1; j <= m.ksi[i]; j++) {
            vn  = (*m.slist[i])[j]
            idx = gvar_pos(allnames, vn)
            OUT[((i-1)*Traw+1)::(i*Traw), idx] = (*m.Si[i])[., j]
        }
    }

    for (j = 1; j <= nv; j++) {
        vn = pre + allnames[j] + suf
        idx = _st_varindex(vn)
        if (idx == .) {
            idx = st_addvar("double", vn)
        }
        else {
            if (repl == 0) {
                errprintf("gvar foreign: variable " + vn +
                          " already exists; specify replace" + "\n")
                exit(110)
            }
        }
        col = J(st_nobs(), 1, .)
        col[1::(N * Traw)] = OUT[., j]
        st_store(., idx, col)
    }
}


// ---------------------------------------------------------------------------
// Contributions laid out for the stacked-bar plot (BGVAR plot.bgvar).
//
// The plot has to add up: the bars for one period must sum to the observed
// value of the series, or the picture is not a decomposition of anything.
// That means nothing may be quietly dropped.  The columns returned are
//
//     1 .. ns    the shocks named in spos, in the order given
//     ns + 1     every OTHER shock, summed
//     ns + 2     the deterministic terms, the initial condition and the
//                leftover slice, summed
//     ns + 3     the observed series -- the sum of all of the above
//
// Column ns+3 is computed by summing every row block rather than by reading
// the data back, so a discrepancy between it and the bars is impossible by
// construction and column ns+2 catches whatever the top ns do not explain.
//
// nblk is derived the way the table derives it: rows(H)/K.  Blocks beyond the
// K shock blocks are the deterministic ones, and they are ALL folded into
// ns+2 -- including the trend block when it is present.  print_hd's own
// "determ+init" column adds only const and init and omits the trend, so a
// trend model's printed TOTAL is short by the trend contribution; summing
// every remaining block avoids inheriting that.
// ---------------------------------------------------------------------------
real matrix gvar_hdparts(real matrix H, real scalar K, real scalar vpos,
                         real rowvector spos, real scalar T)
{
    real matrix    OUT
    real scalar    ns, nblk, j, b, r, c, shown, q
    real colvector tot

    ns   = length(spos)
    nblk = rows(H) / K
    OUT  = J(T, ns + 3, 0)

    // the named shocks, in the order asked for
    for (c = 1; c <= ns; c++) {
        r = (spos[c] - 1) * K + vpos
        OUT[., c] = H[r, 1::T]'
    }

    // every other shock
    for (j = 1; j <= K; j++) {
        shown = 0
        for (q = 1; q <= ns; q++) {
            if (spos[q] == j) shown = 1
        }
        if (shown) continue
        r = (j - 1) * K + vpos
        OUT[., ns + 1] = OUT[., ns + 1] + H[r, 1::T]'
    }

    // every non-shock block: constant, trend if present, initial, leftover
    for (b = K + 1; b <= nblk; b++) {
        r = (b - 1) * K + vpos
        OUT[., ns + 2] = OUT[., ns + 2] + H[r, 1::T]'
    }

    // the observed series, as the sum of every piece
    tot = J(T, 1, 0)
    for (b = 1; b <= nblk; b++) {
        r = (b - 1) * K + vpos
        tot = tot + H[r, 1::T]'
    }
    OUT[., ns + 3] = tot

    return(OUT)
}


// ===========================================================================
// The dominant unit as a pseudo-unit  (Toolbox §7)
// ===========================================================================
// gvar_dumodel() estimates the block; these functions put it into the model
// and hand it to the stacker.
//
// The design turns on one observation about solve_GVAR.m's augmentation
//
//     H0 = [G0 -J0 ; 0 I]      H_j = [G_j J_j ; 0 Phi_j]
//
// the zero block in the SECOND row of H0.  Feedback from the country models
// reaches the dominant unit only at lags, never contemporaneously, so the
// block is an ordinary unit with L0 = 0 and Lm = Lambda_du.  gvar_stack()
// therefore needs no special case: it is handed N+1 units instead of N.
//
// What must NOT happen is N becoming N+1 in the model itself.  Every
// per-country loop in the package -- coint, estimate, wetest, stability,
// diag, overid and the rest -- iterates 1..N over pointer vectors that hold
// a beta, an alpha and a residual matrix per country.  The dominant block has
// none of those in the same sense.  So N stays the number of COUNTRY models
// and the pseudo-unit is assembled locally inside gvar_solvemodel().
//
// K does grow, and that is wanted: the dominant variables belong in x_t, so
// irf, fevd, spillover and hd see them as responses and as shocks.  They are
// appended at the END of x_t, which is what lets gvar_linkmat keep working
// unchanged -- it computes each country's block offset from ki, and finds
// weakly exogenous variables by NAME anywhere in x_t.
// ---------------------------------------------------------------------------

// Which globals belong to the dominant block.  Called from _gvar_do_flags so
// that the "weakly exogenous everywhere but endogenous nowhere" check can let
// them through: that is exactly the case the dominant unit exists to cover.
void gvar_setdumark(string scalar names)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    string rowvector nm
    real scalar g, p, G

    m = gvar_MODEL
    G = rows(m.gvname)
    m.dumark = J(G, 1, 0)
    if (strtrim(names) == "") {
        gvar_MODEL = m
        return
    }
    if (G == 0) {
        errprintf("gvar setup: dominant() needs global() variables" + "\n")
        exit(198)
    }
    nm = tokens(names)
    for (p = 1; p <= cols(nm); p++) {
        g = gvar_pos(m.gvname, nm[p])
        if (g == 0) {
            errprintf("gvar setup: dominant() names " + nm[p] +
                      ", which is not one of the global() variables" + "\n")
            exit(111)
        }
        m.dumark[g] = 1
    }
    gvar_MODEL = m
}

// The entity's own weights over countries (BGVAR OE.weights$weights).
// Empty restores the default, which is the aggregation weights.
void gvar_setduw(real colvector w)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m

    m = gvar_MODEL
    if (rows(w) == 0) {
        m.duw = J(0, 1, .)
        gvar_MODEL = m
        return
    }
    if (rows(w) != m.N) {
        errprintf("gvar dominant: weights() must have one row per unit (%g)\n",
                  m.N)
        exit(198)
    }
    m.duw = w
    gvar_MODEL = m
}

real colvector gvar_getduw()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.duw)
}

real scalar gvar_hasdumark()
{
    external struct gvarmodel scalar gvar_MODEL
    if (rows(gvar_MODEL.dumark) == 0) return(0)
    return(colsum(gvar_MODEL.dumark) > 0)
}

real scalar gvar_hasdu()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.hasdu)
}

string colvector gvar_getduylist()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.duylist)
}

string colvector gvar_getdufblist()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.dufblist)
}

// The dominant variables' data, Traw x gd, in x_t order.
real matrix gvar_getduX()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT
    real scalar g, G

    m = gvar_MODEL
    G = rows(m.gvname)
    OUT = J(rows(m.GDATA), 0, 0)
    // dumark is empty on a model built before dominant() existed, or saved by
    // an earlier version; treat that as "no dominant unit" rather than dying
    // on a subscript
    if (rows(m.dumark) < G) return(OUT)
    for (g = 1; g <= G; g++) {
        if (m.dumark[g] == 1) OUT = OUT, m.GDATA[., g]
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Feedback variables: weighted aggregates of a domestic variable over units.
//
// augmentedregression.m adds xtilde*_t = Wtilde x_t to the dominant-unit
// regression, where Wtilde aggregates one domestic variable across countries.
// The weights are the AGGREGATION weights (aggw), not the trade weights: the
// series wanted is "world output", not "output as unit i sees it".  Using the
// trade matrix here would give a different series for every country and there
// is only one dominant unit.
// ---------------------------------------------------------------------------
real matrix gvar_dufb(string colvector fblist)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT, col
    real scalar j, i, s, vt, w, sw

    m = gvar_MODEL
    OUT = J(m.Traw, 0, 0)
    for (j = 1; j <= rows(fblist); j++) {
        s  = gvar_pos(m.vname, fblist[j])
        if (s == 0) {
            errprintf("gvar dominant: feedback() names " + fblist[j] +
                      ", which is not a domestic variable" + "\n")
            exit(111)
        }
        vt  = m.vtype[s]
        col = J(m.Traw, 1, 0)
        sw  = 0
        for (i = 1; i <= m.N; i++) {
            if (m.dflag[i, s] != 1) continue
            // BGVAR's OE.weights gives each other entity its OWN weight
            // vector over countries; falling back on the aggregation weights
            // is only the default, not the definition.
            if (rows(m.duw) == m.N) w = m.duw[i]
            else                    w = m.aggw[i, vt]
            if (w >= .) w = 0
            col = col + w * (*m.Yi[i])[., gvar_pos(*m.ylist[i], fblist[j])]
            sw = sw + w
        }
        if (sw <= 0) {
            errprintf("gvar dominant: feedback(" + fblist[j] +
                      ") has no unit with a positive aggregation weight" + "\n")
            exit(459)
        }
        OUT = OUT, (col / sw)
    }
    return(OUT)
}

// The pseudo-unit's link matrix: gd rows selecting the dominant variables out
// of x_t, then nfb rows aggregating a domestic variable across units.
real matrix gvar_dulink(real scalar K)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Wtop, Wbot
    real scalar gd, nfb, j, mm, s, vt, sw

    m   = gvar_MODEL
    gd  = rows(m.duylist)
    nfb = rows(m.dufblist)

    // the dominant variables sit at the END of x_t, appended by gvar_specify
    Wtop = J(gd, K - gd, 0), I(gd)
    if (nfb == 0) return(Wtop)

    Wbot = J(nfb, K, 0)
    for (j = 1; j <= nfb; j++) {
        s  = gvar_pos(m.vname, m.dufblist[j])
        vt = 1
        if (s > 0) vt = m.vtype[s]
        sw = 0
        for (mm = 1; mm <= K; mm++) {
            if (m.xname[mm] != m.dufblist[j]) continue
            if (m.xunit[mm] < 1 | m.xunit[mm] > m.N) continue
            // the SAME weights the regression used: if the link matrix
            // aggregated differently the stacked system would not reproduce
            // the block that was estimated
            if (rows(m.duw) == m.N) Wbot[j, mm] = m.duw[m.xunit[mm]]
            else                    Wbot[j, mm] = m.aggw[m.xunit[mm], vt]
            if (Wbot[j, mm] >= .) Wbot[j, mm] = 0
            sw = sw + Wbot[j, mm]
        }
        if (sw != 0) Wbot[j, .] = Wbot[j, .] :/ sw
    }
    return(Wtop \ Wbot)
}
// ---------------------------------------------------------------------------
// The augmented (second-stage) regression of the dominant unit model.
//   Toolbox augmentedregression.m
//
// This is where a0_du, a1_du, Theta_du and Lambda_du actually come from.  The
// first stage (estimate_VECM_dumodel.m) exists to produce the cointegrating
// vectors; the second stage re-estimates the short-run dynamics conditional on
// them, and it runs whether or not there are feedbacks -- isfeedback == 0 only
// sets max_qtildel = ones(gxvnum,1), it does not skip the regression.
//
// That matters more than it looks.  Fitting the feedbacks to the first-stage
// residual instead leaves Theta untouched, so Theta comes out byte-identical
// with and without feedback().  It also means the multivariate no-feedback
// path was using mlcoint's ML estimates where the Toolbox uses stage-II OLS.
//
// One design matrix per equation g:
//
//     X = [ det , lags 1..p of gxvset , lags 1..q of fback , ecm ]
//     b = (X'X) \ (X'dep)
//
// so the lag coefficients, the feedback coefficients and the error-correction
// loading are estimated TOGETHER.
//
//   univariate, levels        dep = d          gxvset = d,   fback in levels
//   univariate, differences   dep = D d        gxvset = D d, fback differenced
//   multivariate              dep = D d_g      gxvset = D d, fback differenced
//                                              plus the ecm term
//
// The recovery back to the levels representation is the telescoping map:
//     Theta_1 = I + Pi + Gamma_1,  Theta_j = -(Gamma_{j-1} - Gamma_j),
//     Theta_ptilde = -Gamma_{ptilde-1}
// with Pi = alpha Beta' present only when there is a cointegrating block, and
// the same map without the Pi and the I for Lambda.
// ---------------------------------------------------------------------------
void gvar_duaug(real matrix GX, real matrix FB, real scalar ml,
                real scalar lp, real scalar lq, real scalar ducase,
                real scalar etype,
                real matrix alpha, real matrix beta, real matrix ecm,
                real colvector a0du, real colvector a1du,
                real matrix Thdu, real matrix Lmdu,
                real matrix eps, real matrix Om)
{
    real scalar gd, nfb, T0, i, j, g, detind, mt, base, ptil, qtil, rk, c
    real matrix dep, gxvset, fb, X, Xg, b, E, Beta, Pi, ecmt
    real matrix Gam, Gamt
    real colvector depg, bg

    gd  = cols(GX)
    nfb = cols(FB)

    // ---- dependent variable and the regressor set ------------------------
    if (gd == 1 & etype == 0) {
        dep    = GX
        gxvset = GX
        fb     = FB
    }
    else {
        dep    = gvar_trimr(GX - gvar_lagm(GX, 1), 1, 0)
        gxvset = dep
        if (gd > 1) {
            gxvset = gvar_trimr(GX - gvar_lagm(GX, 1), 1, 0)
            dep    = gxvset
        }
        fb = FB
        if (nfb > 0) fb = gvar_trimr(FB - gvar_lagm(FB, 1), 1, 0)
    }
    T0 = rows(dep)

    // ---- deterministics ---------------------------------------------------
    // Only the univariate levels model can carry a trend here; the
    // multivariate one puts its trend in the restricted beta, which is why
    // a1_du below comes from alpha*beta[1,.]' rather than from the OLS.
    X = J(T0, 1, 1)
    detind = 1
    if (gd == 1 & etype == 0 & ducase == 1) {
        X = X, (1::T0)
        detind = 2
    }

    for (i = 1; i <= lp; i++) {
        X = X, gvar_lagm(gxvset, i)
    }
    if (nfb > 0) {
        for (i = 1; i <= lq; i++) {
            X = X, gvar_lagm(fb, i)
        }
    }

    // ---- the error-correction term, aligned from the FRONT ----------------
    rk = 0
    if (gd > 1 & rows(ecm) > 0) {
        ecmt = ecm'
        rk   = cols(ecmt)
        if (rows(X) > rows(ecmt)) {
            dep = gvar_trimr(dep, rows(X) - rows(ecmt), 0)
            X   = gvar_trimr(X,   rows(X) - rows(ecmt), 0)
        }
        else if (rows(X) < rows(ecmt)) {
            ecmt = gvar_trimr(ecmt, rows(ecmt) - rows(X), 0)
        }
        X = X, ecmt
    }

    mt = lp
    if (nfb > 0) mt = max((lp, lq))
    X   = gvar_trimr(X, mt, 0)
    dep = gvar_trimr(dep, mt, 0)

    // ---- one OLS per equation --------------------------------------------
    b = J(cols(X), gd, 0)
    E = J(rows(dep), gd, 0)
    for (g = 1; g <= gd; g++) {
        depg = dep[., g]
        bg   = gvar_msolve(cross(X, X), cross(X, depg))
        b[., g] = bg
        E[., g] = depg - X * bg
    }
    eps = E
    Om  = cross(E, E) / rows(E)

    a0du = J(gd, 1, 0)
    a1du = J(gd, 1, 0)
    Thdu = J(gd, gd * ml, 0)
    Lmdu = J(gd, max((nfb, 0)) * ml, 0)

    // =======================================================================
    // univariate
    // =======================================================================
    if (gd == 1) {
        a0du[1] = b[1, 1]
        if (etype == 0) {
            if (ducase == 1) a1du[1] = b[2, 1]
            for (i = 1; i <= ml; i++) {
                if (i <= lp) Thdu[1, i] = b[detind + i, 1]
            }
            if (nfb > 0) {
                base = detind + lp
                for (i = 1; i <= ml; i++) {
                    if (i > lq) continue
                    for (j = 1; j <= nfb; j++) {
                        Lmdu[1, (i-1)*nfb + j] = b[base + (i-1)*nfb + j, 1]
                    }
                }
            }
            return
        }

        // first differences: telescope back to levels
        ptil = lp + 1
        for (i = 1; i <= ml; i++) {
            if (i == 1)                     Thdu[1, i] = 1 + b[detind + 1, 1]
            else if (i > 1 & i < ptil)      Thdu[1, i] = b[detind + i, 1] -
                                                         b[detind + i - 1, 1]
            else if (i == ptil)             Thdu[1, i] = -b[detind + i - 1, 1]
        }
        if (nfb > 0) {
            base = detind + lp
            qtil = lq + 1
            for (i = 1; i <= ml; i++) {
                for (j = 1; j <= nfb; j++) {
                    c = (i-1)*nfb + j
                    if (i == 1) {
                        Lmdu[1, c] = b[base + j, 1]
                    }
                    else if (i > 1 & i < qtil) {
                        Lmdu[1, c] = b[base + (i-1)*nfb + j, 1] -
                                     b[base + (i-2)*nfb + j, 1]
                    }
                    else if (i == qtil) {
                        Lmdu[1, c] = -b[base + (i-2)*nfb + j, 1]
                    }
                }
            }
        }
        return
    }

    // =======================================================================
    // multivariate
    // =======================================================================
    // The restricted deterministic sits in the first row of beta for cases 2
    // and 4, so the intercept or trend is alpha*beta[1,.]' rather than an OLS
    // coefficient -- and in case 2 the OLS intercept must NOT be read.
    Beta = beta
    if (rows(beta) > 0) {
        if (ducase == 4) {
            a1du = alpha * beta[1, .]'
            Beta = beta[|2, 1 \ rows(beta), cols(beta)|]
        }
        else if (ducase == 2) {
            a0du = alpha * beta[1, .]'
            Beta = beta[|2, 1 \ rows(beta), cols(beta)|]
        }
    }
    if (ducase != 2) {
        for (g = 1; g <= gd; g++) a0du[g] = b[detind, g]
    }

    Gam = J(gd, gd * lp, 0)
    for (g = 1; g <= gd; g++) {
        for (i = 1; i <= lp; i++) {
            for (j = 1; j <= gd; j++) {
                Gam[g, (i-1)*gd + j] = b[detind + (i-1)*gd + j, g]
            }
        }
    }
    Gamt = J(gd, max((nfb, 1)) * max((lq, 1)), 0)
    if (nfb > 0) {
        base = detind + lp * gd
        for (g = 1; g <= gd; g++) {
            for (i = 1; i <= lq; i++) {
                for (j = 1; j <= nfb; j++) {
                    Gamt[g, (i-1)*nfb + j] = b[base + (i-1)*nfb + j, g]
                }
            }
        }
    }

    Pi = J(gd, gd, 0)
    if (rows(ecm) > 0 & rows(Beta) > 0) Pi = alpha * Beta'

    ptil = lp + 1
    for (i = 1; i <= ml; i++) {
        if (i > ptil) continue
        if (ptil == 1) {
            Thdu[., ((i-1)*gd+1)::(i*gd)] = Pi + I(gd)
        }
        else if (i == 1) {
            Thdu[., 1::gd] = Pi + Gam[., 1::gd] + I(gd)
        }
        else if (i == ptil) {
            Thdu[., ((i-1)*gd+1)::(i*gd)] = -Gam[., ((i-2)*gd+1)::((i-1)*gd)]
        }
        else {
            Thdu[., ((i-1)*gd+1)::(i*gd)] =
                -(Gam[., ((i-2)*gd+1)::((i-1)*gd)] -
                  Gam[., ((i-1)*gd+1)::(i*gd)])
        }
    }

    if (nfb > 0) {
        qtil = lq + 1
        for (i = 1; i <= ml; i++) {
            if (i > qtil) continue
            if (i == 1) {
                Lmdu[., 1::nfb] = Gamt[., 1::nfb]
            }
            else if (i == qtil) {
                Lmdu[., ((i-1)*nfb+1)::(i*nfb)] =
                    -Gamt[., ((i-2)*nfb+1)::((i-1)*nfb)]
            }
            else {
                Lmdu[., ((i-1)*nfb+1)::(i*nfb)] =
                    -(Gamt[., ((i-2)*nfb+1)::((i-1)*nfb)] -
                      Gamt[., ((i-1)*nfb+1)::(i*nfb)])
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Estimate the dominant-unit model and store it.
//
// Two stages, as the Toolbox has them:
//
//   I   estimate_VECM_dumodel.m   cointegration, when the block is multivariate
//   II  augmentedregression.m     the coefficients that are actually used
//
// Stage II runs whether or not there are feedbacks.  isfeedback == 0 only sets
// max_qtildel = ones(gxvnum,1); it does not skip the regression.  So a0_du,
// a1_du, Theta_du and Lambda_du all come from stage II, and stage I exists to
// supply alpha, beta and the error-correction term that stage II conditions
// on.
//
// The lag order of the augmented GVAR is
//
//     amaxlag = max(maxlag, ptilde, qtilde)
//
// with ptilde = max_ptildel for a univariate model in levels and
// max_ptildel + 1 otherwise, and qtilde the same for the feedbacks.  When the
// dominant block needs more lags than the country models, the GVAR lag order
// RISES and every country's Theta and Lambda are zero-padded to match.  Padding
// the block down to pmax instead would silently drop its longest lags.
// ---------------------------------------------------------------------------
void gvar_durun(real scalar lp, real scalar lq, real scalar ducase,
                real scalar etype, real scalar rk, string scalar fbnames)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix GX, FB, Th, be, al, Ps, ep, Om, Lm, ecm, DX, dep
    real colvector a0, a1
    string colvector fbl
    real scalar gd, nfb, i, j, ml, ptil, qtil, amax, ll, ai, sb
    real matrix Tp, Lp

    m  = gvar_MODEL
    GX = gvar_getduX()
    gd = cols(GX)
    if (gd == 0) {
        errprintf("gvar dominant: no global variable is marked for the "
                  + "dominant unit.  Use gvar setup, dominant(names).\n")
        exit(459)
    }
    if (gd > 1 & etype == 1) {
        errprintf("gvar dominant: diff applies to a single dominant "
                  + "variable; with more than one the block is a VECM\n")
        exit(198)
    }

    fbl = J(0, 1, "")
    if (strtrim(fbnames) != "") fbl = tokens(fbnames)'
    nfb = rows(fbl)
    FB  = J(rows(GX), 0, 0)
    if (nfb > 0) FB = gvar_dufb(fbl)

    // ---- the augmented lag order, before anything is sized ----------------
    ptil = lp
    if (!(gd == 1 & etype == 0)) ptil = lp + 1
    qtil = 0
    if (nfb > 0) {
        qtil = lq
        if (!(gd == 1 & etype == 0)) qtil = lq + 1
    }
    amax = max((m.pmax, ptil, qtil))

    // ---- stage I: cointegration, multivariate only -----------------------
    al = be = Ps = ecm = J(0, 0, .)
    if (gd > 1) {
        ll = ai = sb = .
        // maxlag here is the ORIGINAL GVAR lag order, not amaxlag: the
        // source computes amaxlag from the stage-II orders AFTER this call,
        // and feeding it back in trims two further periods and shifts the
        // error-correction term relative to the data.
        gvar_mlcoint(GX, J(rows(GX), 0, 0), lp, 0, m.pmax, ducase, rk,
                     be, al, Ps, ep, Om, ecm, DX, dep, ll, ai, sb)
    }

    // ---- stage II: the coefficients that are used -------------------------
    a0 = a1 = J(0, 1, .)
    Th = Lm = ep = Om = J(0, 0, .)
    gvar_duaug(GX, FB, amax, lp, lq, ducase, etype, al, be, ecm,
               a0, a1, Th, Lm, ep, Om)

    // ---- raise the GVAR lag order if the block needs it -------------------
    // Every country's Theta is ki x (ki*pmax) and Lambda is ki x (ksi*pmax);
    // gvar_stack reads column blocks j = 1..maxlag, so a longer maxlag with
    // unpadded country blocks is a subscript error, not a silent zero.
    if (amax > m.pmax) {
        for (i = 1; i <= m.N; i++) {
            Tp = J(m.ki[i], m.ki[i] * amax, 0)
            Tp[., 1::(m.ki[i] * m.pmax)] = *m.Th[i]
            m.Th[i] = &(Tp[., .])
            if (m.ksi[i] > 0) {
                Lp = J(m.ki[i], m.ksi[i] * amax, 0)
                Lp[., 1::(m.ksi[i] * m.pmax)] = *m.Lm[i]
                m.Lm[i] = &(Lp[., .])
            }
        }
        m.pmax = amax
    }

    m.duylist = J(gd, 1, "")
    j = 0
    for (i = 1; i <= rows(m.gvname); i++) {
        if (m.dumark[i] == 1) {
            j = j + 1
            m.duylist[j] = m.gvname[i]
        }
    }

    m.dulag   = lp
    m.duqlag  = lq
    m.ducase  = ducase
    m.duetype = etype
    m.durank  = rk
    m.duTh    = Th
    m.dua0    = a0
    m.dua1    = a1
    m.dubeta  = be
    m.dualpha = al
    m.duPsi   = Ps
    m.dueps   = ep
    m.duOm    = Om
    m.dufblist = fbl
    m.dunfb    = nfb

    // Feedback reaches the dominant unit only at lags: that is the zero in
    // solve_GVAR.m's H0 = [G0 -J0 ; 0 I].
    m.duL0 = J(gd, nfb, 0)
    m.duLm = Lm
    if (nfb == 0) m.duLm = J(gd, 0, 0)

    m.hasdu = 1
    gvar_MODEL = m
}

// Accessors used by the ado for reporting.  Written out rather than as
// one-line bodies: a braced body on a single line is a parse risk in an
// interactive mata block and this file is read by people too.

real matrix gvar_getduTh()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.duTh)
}

real matrix gvar_getduLm()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.duLm)
}

real matrix gvar_getdueps()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.dueps)
}

real matrix gvar_getduOm()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.duOm)
}

real matrix gvar_getdubeta()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.dubeta)
}

real colvector gvar_getdua0()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.dua0)
}

real colvector gvar_getdua1()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.dua1)
}

real scalar gvar_getdurank()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.durank)
}

real scalar gvar_getdunfb()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.dunfb)
}
real matrix gvar_getduL0v()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.duL0)
}

real matrix gvar_getduLmv()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.duLm)
}



// ===========================================================================
// The Bayesian country model  (BGVAR src/BVAR_linear.cpp)
// ===========================================================================
// One VARX* per unit, sampled equation by equation.  BGVAR writes the model
// in structural form
//
//     y_t' L = x_t' A L + e_t',      Sigma = L^{-1} D L^{-1}'
//
// with L unit lower triangular, and exploits the fact that conditional on the
// previous equations' residuals every equation is an independent Gaussian
// regression.  Equation m regresses y_m on [X , E_1 ... E_{m-1}]: the extra
// columns ARE the free elements of L's m-th row, so the covariance is sampled
// for free alongside the coefficients.  That is what makes a K = 136 system
// tractable at all -- no K x K joint draw is ever formed.
//
//     S_m  = exp(-0.5 h_m)                     scaling, SV or constant
//     V_p  = (X_m' X_m + V^{-1})^{-1}
//     A_p  = V_p (X_m' Y_m + V^{-1} a_m)
//     draw = A_p + chol(V_p, lower) * randn
//
// The prior variance V enters as a diagonal precision, so every prior in the
// family -- Minnesota, SSVS, Normal-Gamma, Horseshoe -- is just a different
// rule for filling V.  Only that rule changes between priors; this routine
// does not.
// ---------------------------------------------------------------------------

// A robust lower Cholesky.  V_p is a posterior covariance and is symmetric by
// construction, but it can lose positive definiteness numerically when the
// prior is very tight.  BGVAR falls back on R's pivoted chol; the symmetric
// eigen-decomposition square root is the equivalent that Mata has, and it is
// the same fallback gvar_rootmat already uses for the EFP processes.
real matrix gvar_bchol(real matrix V)
{
    real matrix L, Q, Lam
    real colvector lam

    if (hasmissing(V)) return(J(rows(V), cols(V), 0))
    L = J(0, 0, .)
    if (_cholesky(L = V) == 0) return(L)

    symeigensystem((V + V') / 2, Q, lam)
    lam = lam :* (lam :> 0)
    Lam = diag(sqrt(lam))
    return(Q * Lam * Q')
}

// The Minnesota prior variance  (helper.cpp get_Vminnesota).
//
//   own lag        (lambda1 / l)^2
//   cross lag      (lambda1 lambda2 / l)^2 * sigma_i / sigma_j
//   weakly exog    (lambda1 lambda3 / (l+1))^2 * sigma_i / sigma_j*
//   deterministic  lambda4 * sigma_i
//
// The exogenous block runs from lag ZERO -- the contemporaneous star variables
// are in the regression -- which is why its denominator is l+1 rather than l.
real matrix gvar_vmn(real scalar k, real scalar M, real scalar Mstar,
                     real scalar plag, real scalar plagstar,
                     real colvector sigmas, real scalar l1, real scalar l2,
                     real scalar l3, real scalar l4,
                     real scalar cons, real scalar trend)
{
    real matrix V
    real scalar i, j, pp, r

    V = J(k, M, 10)

    for (i = 1; i <= M; i++) {
        for (pp = 1; pp <= plag; pp++) {
            for (j = 1; j <= M; j++) {
                r = j + M * (pp - 1)
                if (i == j) V[r, i] = (l1 / pp) ^ 2
                else        V[r, i] = ((l1 * l2) / pp) ^ 2 *
                                      (sigmas[i] / sigmas[j])
            }
        }
    }
    if (Mstar > 0) {
        for (i = 1; i <= M; i++) {
            for (pp = 0; pp <= plagstar; pp++) {
                for (j = 1; j <= Mstar; j++) {
                    r = M * plag + pp * Mstar + j
                    V[r, i] = ((l1 * l3) / (pp + 1)) ^ 2 *
                              (sigmas[i] / sigmas[M + j])
                }
            }
        }
    }
    if (cons) {
        for (i = 1; i <= M; i++) {
            V[k, i] = l4 * sigmas[i]
            if (trend) V[k - 1, i] = l4 * sigmas[i]
        }
    }
    return(V)
}

// The residual standard deviation of an AR(p), used to scale the Minnesota
// prior across equations (helper.cpp get_ar).
real scalar gvar_bar(real colvector y, real scalar p)
{
    real scalar T, i
    real matrix X, b
    real colvector dep, e

    T = rows(y)
    if (T <= p + 2) return(1)
    X = J(T, 1, 1)
    for (i = 1; i <= p; i++) {
        X = X, gvar_lagm(y, i)
    }
    X   = gvar_trimr(X, p, 0)
    dep = gvar_trimr(y, p, 0)
    b   = gvar_msolve(cross(X, X), cross(X, dep))
    e   = dep - X * b
    return(sqrt(cross(e, e) / rows(e)))
}

// ---------------------------------------------------------------------------
// One Gibbs sweep over a unit  (BVAR_linear.cpp lines 342-412).
//
// TWO loops, not one.  The joint "regress y_m on [X, E_1..E_{m-1}]" version --
// which samples the coefficients and row m of L together -- is present in the
// source but sits inside a comment block at line 413.  It is NOT what runs.
// Implementing it would have been faster to write, produced plausible draws,
// and been a different sampler.
//
// Loop 1, coefficients, equation by equation.  This is a GLS draw: equation m
// is conditioned on every OTHER equation through L^{-1}, not just on the ones
// before it.  Zeroing column m of A and multiplying the residual by the last
// M-m rows of L^{-1} is what carries that information in.
//
//     A_0    = A with column m zeroed
//     Linv_0 = rows m..M of L^{-1}                      (M-m+1) x M
//     S_0    = exp(-0.5 h[., m..M])                     T x (M-m+1)
//     ztilde = vec((Y - X A_0) Linv_0') :* vec(S_0)
//     xtilde = (Linv_0[., m] # X)       :* vec(S_0)
//     V_p    = (xtilde'xtilde + V^{-1})^{-1}
//     A_p    = V_p (xtilde'ztilde + V^{-1} a_m)
//
// Loop 2, the free elements of L, one row at a time: regress this equation's
// residual on the earlier equations' residuals.
//
//     V_p = (eps_x' eps_x + Linv_prior)^{-1}
//     A_p = V_p (eps_x' eps_m + Linv_prior l_m)
//
// L starts as the identity and only its strictly lower part is drawn, so it
// is unit lower triangular throughout and Sigma = L^{-1} D L^{-1}'.
//
// The prior enters both loops only as a DIAGONAL precision, which is why
// Minnesota, SSVS, Normal-Gamma and Horseshoe are four ways of filling Vpri
// and not four samplers.
// ---------------------------------------------------------------------------
void gvar_bsweep(real matrix Y, real matrix X, real matrix Sv,
                 real matrix Vpri, real matrix Apri,
                 real matrix Lpri, real matrix lpri,
                 real matrix A, real matrix L, real matrix Linv,
                 real matrix E, real matrix Estr)
{
    real scalar T, k, M, m, i
    real matrix A0, Linv0, S0, zmat, xtilde, Vinv, Vp, Ch, epsx
    real colvector ztilde, s0v, am, Ap, draw, epsm, Sm

    T = rows(Y)
    k = cols(X)
    M = cols(Y)

    // ---- loop 1: the coefficients ---------------------------------------
    for (m = 1; m <= M; m++) {
        A0 = A
        A0[., m] = J(k, 1, 0)

        Linv0 = Linv[m::M, .]
        S0    = exp(-0.5 * Sv[., m::M])
        s0v   = vec(S0)

        zmat   = (Y - X * A0) * Linv0'
        ztilde = vec(zmat) :* s0v
        xtilde = (Linv0[., m] # X) :* (s0v * J(1, k, 1))

        Vinv = J(k, k, 0)
        for (i = 1; i <= k; i++) {
            Vinv[i, i] = 1 / Vpri[i, m]
        }
        am = Apri[., m]

        Vp = gvar_sinv(cross(xtilde, xtilde) + Vinv)
        Ap = Vp * (cross(xtilde, ztilde) + Vinv * am)
        Ch = gvar_bchol(Vp)

        draw = Ap + Ch * rnormal(k, 1, 0, 1)

        A[., m] = draw
        E[., m] = Y[., m] - X * draw
    }

    // ---- loop 2: the free elements of L ----------------------------------
    for (m = 2; m <= M; m++) {
        Sm   = exp(-0.5 * Sv[., m])
        epsm = E[., m] :* Sm
        epsx = E[., 1::(m-1)] :* (Sm * J(1, m - 1, 1))

        Vinv = J(m - 1, m - 1, 0)
        for (i = 1; i <= m - 1; i++) {
            Vinv[i, i] = 1 / Lpri[m, i]
        }
        am = lpri[m, 1::(m-1)]'

        Vp = gvar_sinv(cross(epsx, epsx) + Vinv)
        Ap = Vp * (cross(epsx, epsm) + Vinv * am)
        Ch = gvar_bchol(Vp)

        draw = Ap + Ch * rnormal(m - 1, 1, 0, 1)
        L[m, 1::(m-1)] = draw'
    }

    Linv = gvar_inv(L)
    Estr = (Y - X * A) * Linv'
}

// ---------------------------------------------------------------------------
// The regressor block for one unit  (BVAR_linear.cpp lines 62-79).
//
//     X = [ lags 1..p of y | w and lags 1..q of w | const | trend ]
//
// The star block carries the CONTEMPORANEOUS w as well as its lags, so it has
// Mstar*(q+1) columns -- which is why the Minnesota prior indexes it from lag
// zero and divides by (l+1).  Rows start at pmax+1, so p and q consume the
// same observations however they differ.
// ---------------------------------------------------------------------------
void gvar_bdata(real matrix Yraw, real matrix Wraw, real scalar plag,
                real scalar plagstar, real scalar cons, real scalar trend,
                real matrix Y, real matrix X)
{
    real scalar Traw, M, Mstar, pmax, i, T
    real matrix X0, W0, Wall

    Traw  = rows(Yraw)
    M     = cols(Yraw)
    Mstar = cols(Wraw)
    pmax  = max((plag, plagstar))

    X0 = J(Traw, 0, 0)
    for (i = 1; i <= plag; i++) {
        X0 = X0, gvar_lagm(Yraw, i)
    }
    Wall = Wraw
    for (i = 1; i <= plagstar; i++) {
        Wall = Wall, gvar_lagm(Wraw, i)
    }

    Y = Yraw[(pmax + 1)::Traw, .]
    X = X0[(pmax + 1)::Traw, .]
    if (Mstar > 0) X = X, Wall[(pmax + 1)::Traw, .]
    T = rows(Y)

    if (cons)  X = X, J(T, 1, 1)
    if (trend) X = X, (1::T)
}

// ---------------------------------------------------------------------------
// SSVS: the spike-and-slab update  (BVAR_linear.cpp prior == 2, lines 552-576)
//
// Two things in this block are easy to get backwards, and both are in the
// source rather than in the textbook.
//
// FIRST, draw_bernoulli returns ZERO with probability p:
//
//     double draw_bernoulli(double p){
//       double unif = R::runif(0,1);
//       double ret = 1;
//       if(unif < p) {ret = 0;}
//       return ret;
//     }
//
// and ast is the probability of the SPIKE -- the tight component tau0,
// weighted by the prior inclusion probability p_i.  So gamma == 0 is the
// spike, gamma == 1 is the slab, and the posterior inclusion probability is
// the mean of gamma.  Writing draw_bernoulli the usual way round would invert
// every PIP in the output while leaving the sampler apparently healthy.
//
// SECOND, the two NA fallbacks are ASYMMETRIC.  When u1 + u2 underflows,
// ast falls back to 0 -- which sends gamma to 1, the slab -- while hst falls
// back to 1, which sends omega to 0, the spike.  Underflow happens when a
// coefficient sits far out in both densities, so for A the source keeps the
// variable and for L it drops the covariance.  That is deliberate enough to
// preserve rather than tidy.
//
// tau0 and tau1 scale with the OLS standard error of each coefficient,
// sqrt(diag(kron(SIGMA_OLS, (X'X)^{-1}))), so the spike and slab are measured
// in units of what the data can resolve rather than in absolute size.
// ---------------------------------------------------------------------------

// Returns 0 with probability p, exactly as the source does.
real scalar gvar_bern(real scalar p)
{
    if (runiform(1, 1) < p) return(0)
    return(1)
}

// The OLS standard errors that scale the spike and the slab.
real matrix gvar_ssvssd(real matrix Y, real matrix X)
{
    real matrix XtXi, B, E, S, V
    real scalar T, k, M, i, j
    real matrix OUT

    T = rows(Y)
    k = cols(X)
    M = cols(Y)

    XtXi = gvar_sinv(cross(X, X))
    B    = XtXi * cross(X, Y)
    E    = Y - X * B
    S    = cross(E, E) / (T - k)

    // kron(S, XtXi) is (k*M) x (k*M); only its diagonal is wanted, and that
    // is S[j,j] * XtXi[i,i] -- forming the Kronecker product would be a
    // (kM)^2 matrix for nothing.
    OUT = J(k, M, .)
    for (j = 1; j <= M; j++) {
        for (i = 1; i <= k; i++) {
            OUT[i, j] = sqrt(S[j, j] * XtXi[i, i])
        }
    }
    return(OUT)
}

// One SSVS sweep: refill V from the coefficient draw, and Lpri from L.
void gvar_ssvs(real matrix A, real matrix Apri, real matrix L,
               real matrix lpri, real matrix sdal,
               real scalar t0, real scalar t1, real scalar pi_,
               real scalar k0, real scalar k1, real scalar qij,
               real matrix Vpri, real matrix Lpri,
               real matrix gam, real matrix omg)
{
    real scalar k, M, i, j, u1, u2, ast, hst, s0, s1

    k = rows(A)
    M = cols(A)

    for (j = 1; j <= M; j++) {
        for (i = 1; i <= k; i++) {
            s0 = t0 * sdal[i, j]
            s1 = t1 * sdal[i, j]
            u1 = normalden(A[i, j], Apri[i, j], s0) * pi_
            u2 = normalden(A[i, j], Apri[i, j], s1) * (1 - pi_)
            ast = u1 / (u1 + u2)
            if (ast >= . | (u1 + u2) == 0) ast = 0
            gam[i, j] = gvar_bern(ast)
            if (gam[i, j] == 0) Vpri[i, j] = s0 ^ 2
            else                Vpri[i, j] = s1 ^ 2
        }
    }

    for (i = 2; i <= M; i++) {
        for (j = 1; j <= i - 1; j++) {
            u1 = normalden(L[i, j], lpri[i, j], k0) * qij
            u2 = normalden(L[i, j], lpri[i, j], k1) * (1 - qij)
            hst = u1 / (u1 + u2)
            if (hst >= . | (u1 + u2) == 0) hst = 1
            omg[i, j] = gvar_bern(hst)
            if (omg[i, j] == 0) Lpri[i, j] = k0 ^ 2
            else                Lpri[i, j] = k1 ^ 2
        }
    }
}

// ---------------------------------------------------------------------------
// The log posterior of the Normal-Gamma shape tau, up to a constant.
// BVAR_linear.cpp:17 tau_post().
//
//     log p(tau | theta, lambda)  =  log dexp(tau; scale = rat)
//                                  + sum_d log dgamma(theta_d; tau, 2/(tau lambda))
//
// R's dgamma is shape-scale, and the source passes scale = 1/(tau*lambda/2),
// so the rate is tau lambda / 2 -- the same tau lambda / 2 that appears as psi
// in the GIG draw.  That is the tie that makes tau identified at all: it
// governs both the shape and the rate of the local variances.
// ---------------------------------------------------------------------------
real scalar gvar_taupost(real scalar tau, real scalar lam, real colvector th,
                         real scalar rat)
{
    real scalar lp, sc, d, i, kern

    if (tau <= 0 | missing(tau) | lam <= 0 | missing(lam)) return(.)

    // log Exp(scale = rat) density at tau
    lp = -log(rat) - tau / rat

    sc   = 2 / (tau * lam)
    kern = lngamma(tau) + tau * log(sc)
    d    = rows(th)
    for (i = 1; i <= d; i++) {
        if (th[i] <= 0) return(.)
        lp = lp + (tau - 1) * log(th[i]) - th[i] / sc - kern
    }
    if (missing(lp)) return(.)
    return(lp)
}

// ---------------------------------------------------------------------------
// One random-walk Metropolis update of the Normal-Gamma shape tau, for a single
// lag block of a single hierarchy.  BVAR_linear.cpp:614-634 (weakly exogenous)
// and 667-687 (endogenous), which are the same nine lines twice.
//
// sample_tau defaults to TRUE in BGVAR (utils.R:436), so a fixed tau is the
// exception there, not the rule.  The proposal is multiplicative,
// tau' = exp(N(0, s)) tau, which keeps tau positive; log(tau') - log(tau) is the
// Jacobian of that reparameterisation and the source adds it explicitly.
//
// The tuning is adapted over the FIRST HALF of burn-in only, from the running
// acceptance ratio.  On the source's very first sweep irep is 0, so the ratio is
// 0.0/0 = NaN and both C++ comparisons are false -- no adjustment.  Mata's
// missing compares GREATER than any number, so the same expression would fire
// the upward nudge instead; the sweep is skipped explicitly rather than left to
// that difference.
// ---------------------------------------------------------------------------
void gvar_ngtau(real matrix Vblk, real scalar prodl,
                real scalar r, real scalar c,
                real matrix TAU, real matrix TUNE, real matrix ACC,
                real scalar irep, real scalar nburn)
{
    real scalar cur, prop, pp, pc, diff, arate
    real colvector th

    cur = TAU[r, c]
    if (cur <= 0 | missing(cur)) return

    th   = vec(Vblk)
    prop = exp(rnormal(1, 1, 0, TUNE[r, c])) * cur

    pp = gvar_taupost(prop, prodl, th, 1)
    pc = gvar_taupost(cur,  prodl, th, 1)
    if (missing(pp) | missing(pc)) return

    diff = pp - pc + log(prop) - log(cur)
    if (diff > log(runiform(1, 1))) {
        TAU[r, c] = prop
        ACC[r, c] = ACC[r, c] + 1
    }

    // adapt only in the first half of burn-in, and never on the first sweep
    if (irep > 1 & irep - 1 < 0.5 * nburn) {
        arate = ACC[r, c] / (irep - 1)
        if (arate > 0.30) TUNE[r, c] = TUNE[r, c] * 1.01
        if (arate < 0.15) TUNE[r, c] = TUNE[r, c] * 0.99
    }
}

// ---------------------------------------------------------------------------
// Normal-Gamma: global-local shrinkage  (BVAR_linear.cpp prior == 3)
//
// A hierarchy with one GLOBAL variance per lag and one LOCAL variance per
// coefficient:
//
//     theta_ij ~ G(tau, tau lambda^2 / 2)      local, drawn as a GIG
//     lambda^2 ~ G(d + tau k, e + tau sum(theta) prodlambda / 2)   global
//
// and the two blocks -- endogenous lags and the weakly exogenous block -- have
// SEPARATE hierarchies, columns 0 and 1 of lambda2_A and A_tau in the source.
// Sharing one would tie the shrinkage on a country's own lags to the shrinkage
// on its trade-weighted foreign variables, which is exactly what the two
// columns exist to avoid.
//
// prodlambda is the running PRODUCT of the global variances up to the current
// lag, so shrinkage compounds with lag length: lag 3 is shrunk by
// lambda1*lambda2*lambda3, not by lambda3 alone.  Note the source takes the
// product over the lags STRICTLY BEFORE the current one when drawing lambda,
// and INCLUDING it when drawing theta -- two different products a few lines
// apart, and swapping them would still run.
//
// The GIG draws are clamped to [1e-7, 1e+7] exactly as the source does.  That
// is not decoration: chi = (A - prior)^2 goes to zero for a coefficient the
// data pins at its prior mean, and an unclamped variance of 1e-300 makes the
// next Cholesky fail.
//
// The indices below are the source's shifted by one for Mata.  A_tau is
// (pmax+1) x 2 with A_tau(0,0) = 0 unused; the endogenous hierarchy reads rows
// 1..plag of column 0, the exogenous rows 0..plagstar of column 1.
// ---------------------------------------------------------------------------
void gvar_ng(real matrix A, real matrix Apri, real scalar M, real scalar Mstar,
             real scalar plag, real scalar plagstar,
             real scalar d_lam, real scalar e_lam,
             real matrix TAU, real matrix LAM2, real matrix Vpri,
             real scalar stau, real matrix TUNE, real matrix ACC,
             real scalar irep, real scalar nburn)
{
    real scalar pp, ii, mm, r0, dl, el, prodl, lam, psi, chi, res, tt
    real matrix Ab, Vb, Pb

    // ---- the endogenous lag blocks --------------------------------------
    for (pp = 0; pp <= plag - 1; pp++) {
        r0 = pp * M
        Ab = A[(r0 + 1)::(r0 + M), .]
        Vb = Vpri[(r0 + 1)::(r0 + M), .]
        Pb = Apri[(r0 + 1)::(r0 + M), .]
        tt = TAU[pp + 2, 1]

        // the product over lags STRICTLY BEFORE this one.  Mata has no
        // prod(), and exp(sum(ln())) is safe here because every lambda^2 is a
        // gamma draw and therefore strictly positive.
        prodl = 1
        if (pp > 0) prodl = exp(sum(ln(LAM2[2::(pp + 1), 1])))

        dl = d_lam + tt * M ^ 2
        el = e_lam + 0.5 * tt * sum(Vb) * prodl
        LAM2[pp + 2, 1] = rgamma(1, 1, dl, 1 / el)

        // and now INCLUDING it
        prodl = exp(sum(ln(LAM2[2::(pp + 2), 1])))

        for (ii = 1; ii <= M; ii++) {
            for (mm = 1; mm <= M; mm++) {
                lam = tt - 0.5
                psi = tt * prodl
                chi = (Ab[ii, mm] - Pb[ii, mm]) ^ 2
                res = gvar_rgig(lam, chi, psi)
                if (res < 1e-7) res = 1e-7
                if (res > 1e+7) res = 1e+7
                Vpri[r0 + ii, mm] = res
            }
        }

        if (stau) {
            gvar_ngtau(Vpri[(r0 + 1)::(r0 + M), .], prodl, pp + 2, 1,
                       TAU, TUNE, ACC, irep, nburn)
        }
    }

    // ---- the weakly exogenous block, lag ZERO upwards -------------------
    if (Mstar > 0) {
        for (pp = 0; pp <= plagstar; pp++) {
            r0 = plag * M + pp * Mstar
            Ab = A[(r0 + 1)::(r0 + Mstar), .]
            Vb = Vpri[(r0 + 1)::(r0 + Mstar), .]
            Pb = Apri[(r0 + 1)::(r0 + Mstar), .]
            tt = TAU[pp + 1, 2]

            prodl = 1
            if (pp > 0) prodl = exp(sum(ln(LAM2[1::pp, 2])))

            dl = d_lam + tt * M * Mstar
            el = e_lam + 0.5 * tt * sum(Vb) * prodl
            LAM2[pp + 1, 2] = rgamma(1, 1, dl, 1 / el)

            prodl = exp(sum(ln(LAM2[1::(pp + 1), 2])))

            for (ii = 1; ii <= Mstar; ii++) {
                for (mm = 1; mm <= M; mm++) {
                    lam = tt - 0.5
                    psi = tt * prodl
                    chi = (Ab[ii, mm] - Pb[ii, mm]) ^ 2
                    res = gvar_rgig(lam, chi, psi)
                    if (res < 1e-7) res = 1e-7
                    if (res > 1e+7) res = 1e+7
                    Vpri[r0 + ii, mm] = res
                }
            }

            if (stau) {
                gvar_ngtau(Vpri[(r0 + 1)::(r0 + Mstar), .], prodl, pp + 1, 2,
                           TAU, TUNE, ACC, irep, nburn)
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Horseshoe  (BVAR_linear.cpp prior == 4)
//
// A global-local prior like Normal-Gamma, but with its half-Cauchy tails
// written as a pair of inverse-gamma steps -- Makalic and Schmidt's
// augmentation -- so it needs no GIG draw at all, only rgamma.  The whole
// prior is in the source; unlike the Normal-Gamma case nothing here had to be
// reconstructed from a published algorithm.
//
//     lambda_j | nu_j, tau ~ IG(1, 1/nu_j + a_j^2/(2 tau))    local
//     nu_j     | lambda_j  ~ IG(1, 1 + 1/lambda_j)            local auxiliary
//     tau      | zeta, a   ~ IG((n+1)/2, 1/zeta + sum(a^2/lambda)/2)  global
//     zeta     | tau       ~ IG(1, 1 + 1/tau)                  global auxiliary
//
// and V = tau * lambda elementwise, laid back into the coefficient block.
//
// THREE hierarchies, not two: the endogenous lags, the weakly exogenous block,
// and the free elements of L each get their own tau and zeta.  Normal-Gamma has
// only two and leaves L to a separate lambda2_L, so the layout is not
// transferable between the two priors even though both are global-local.
//
// Indexing is COLUMN-MAJOR throughout: the source's A_end(nn) is a linear index
// into an Armadillo matrix, its vectorise() is column-major, and its reshape()
// fills column-major.  Mata's colshape() fills ROW-wise, so the rebuild is
// colshape(v, nrow)' and NOT colshape(v, ncol).  Getting that backwards puts
// each coefficient's shrinkage on a different coefficient while leaving every
// marginal distribution intact -- so nothing downstream would look wrong.
//
// The deterministic rows are not touched, exactly as in the source.
//
// (n+1)/2, (nstar+1)/2 and (v+1)/2 are INTEGER divisions in the source: n, v
// and nstar are all declared int (lines 83-85).  With n = 50 the shape is 25,
// not 25.5.  Reproduced with floor() rather than silently promoted, because it
// is what runs and the difference is too small to justify diverging over.
//
// hsmode 0  the consistent update, scale 1/(1 + 1/tau) in all three blocks
//        1  reproduce the source, whose ENDOGENOUS zeta alone reads
//               zeta_A_endo = 1.0/R::rgamma(1, 1 + 1/(1 / tau_A_endo));
//           where the other two read
//               zeta = 1/R::rgamma(1, 1/(1 + 1 / tau));
//           1 + 1/(1/tau) is 1 + tau, and it is not wrapped in 1/(...), so the
//           endogenous auxiliary is drawn with scale 1+tau where the others use
//           1/(1+1/tau) = tau/(1+tau).  At tau = 0.01 that is a rate of 0.99
//           against 101, on the endogenous block only.  Two of the three lines
//           agree with each other and with the published augmentation; one does
//           not.  Source defect #11, handled the same way as defect #8.
// ---------------------------------------------------------------------------
void gvar_hs(real matrix A, real matrix L, real scalar M, real scalar Mstar,
             real scalar plag, real scalar plagstar, real scalar hsmode,
             real colvector lamE, real colvector nuE,
             real colvector lamX, real colvector nuX,
             real colvector lamL, real colvector nuL,
             real matrix TZ, real matrix Vpri, real matrix Lpri)
{
    real scalar nE, nX, nL, kX, i, j, c, r0, sc, tau
    real colvector aE, aX, aL

    // ---- the endogenous lag blocks --------------------------------------
    aE  = vec(A[1::(plag * M), .])
    nE  = rows(aE)
    tau = TZ[1, 1]
    for (i = 1; i <= nE; i++) {
        sc      = 1 / (1 / nuE[i] + 0.5 * aE[i] ^ 2 / tau)
        lamE[i] = 1 / rgamma(1, 1, 1, sc)
        nuE[i]  = 1 / rgamma(1, 1, 1, 1 / (1 + 1 / lamE[i]))
    }
    sc  = 1 / (1 / TZ[1, 2] + 0.5 * sum(aE :^ 2 :/ lamE))
    tau = 1 / rgamma(1, 1, floor((nE + 1) / 2), sc)
    TZ[1, 1] = tau
    if (hsmode == 1) TZ[1, 2] = 1 / rgamma(1, 1, 1, 1 + tau)
    else             TZ[1, 2] = 1 / rgamma(1, 1, 1, 1 / (1 + 1 / tau))
    Vpri[1::(plag * M), .] = colshape(tau * lamE, plag * M)'

    // ---- the weakly exogenous block, lag ZERO upwards -------------------
    if (Mstar > 0) {
        r0  = plag * M
        kX  = (plagstar + 1) * Mstar
        aX  = vec(A[(r0 + 1)::(r0 + kX), .])
        nX  = rows(aX)
        tau = TZ[2, 1]
        for (i = 1; i <= nX; i++) {
            sc      = 1 / (1 / nuX[i] + 0.5 * aX[i] ^ 2 / tau)
            lamX[i] = 1 / rgamma(1, 1, 1, sc)
            nuX[i]  = 1 / rgamma(1, 1, 1, 1 / (1 + 1 / lamX[i]))
        }
        sc  = 1 / (1 / TZ[2, 2] + 0.5 * sum(aX :^ 2 :/ lamX))
        tau = 1 / rgamma(1, 1, floor((nX + 1) / 2), sc)
        TZ[2, 1] = tau
        TZ[2, 2] = 1 / rgamma(1, 1, 1, 1 / (1 + 1 / tau))
        Vpri[(r0 + 1)::(r0 + kX), .] = colshape(tau * lamX, kX)'
    }

    // ---- the free elements of L -----------------------------------------
    // Strictly lower triangle, column by column, which is the order the
    // source's trimatl_ind produces.  Any CONSISTENT order gives the same
    // sampler, since each lambda is tied to its element both when read and
    // when written back -- but it has to be the same order in both places.
    nL = M * (M - 1) / 2
    if (nL > 0) {
        aL = J(nL, 1, 0)
        c  = 0
        for (j = 1; j <= M - 1; j++) {
            for (i = j + 1; i <= M; i++) {
                c++
                aL[c] = L[i, j]
            }
        }
        tau = TZ[3, 1]
        for (i = 1; i <= nL; i++) {
            sc      = 1 / (1 / nuL[i] + 0.5 * aL[i] ^ 2 / tau)
            lamL[i] = 1 / rgamma(1, 1, 1, sc)
            nuL[i]  = 1 / rgamma(1, 1, 1, 1 / (1 + 1 / lamL[i]))
        }
        sc  = 1 / (1 / TZ[3, 2] + 0.5 * sum(aL :^ 2 :/ lamL))
        tau = 1 / rgamma(1, 1, floor((nL + 1) / 2), sc)
        TZ[3, 1] = tau
        TZ[3, 2] = 1 / rgamma(1, 1, 1, 1 / (1 + 1 / tau))
        c = 0
        for (j = 1; j <= M - 1; j++) {
            for (i = j + 1; i <= M; i++) {
                c++
                Lpri[i, j] = tau * lamL[c]
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Gibbs sampler for one unit.
//
// Returns the thinned draws of A and L, and the residual scale.  Nothing is
// trimmed here: BGVAR applies the eigenvalue rule at the GLOBAL stacking
// stage (.gvar.stacking.wrapper, default 1.05), because a country model can
// be perfectly stable while the stacked system is not, and the reverse.
// Trimming per unit would discard draws the global model would have kept.
//
//   svmode 0  homoskedastic, inverse gamma on sigma^2
//          1  homoskedastic, reproducing BGVAR's cur_sv.fill(sig2)
//
// Source defect #8: BGVAR fills the LOG variance with the variance itself in
// the homoskedastic branch, so the data are weighted by exp(-sigma^2) rather
// than 1/sigma^2 and the prior dominates far more than intended.  svmode 0 is
// correct; svmode 1 reproduces the source exactly for comparison.
// ---------------------------------------------------------------------------
void gvar_brun(real matrix Yraw, real matrix Wraw,
               real scalar plag, real scalar plagstar,
               real scalar cons, real scalar trend,
               real scalar ndraw, real scalar nburn, real scalar nthin,
               real matrix Vpri, real matrix Apri,
               real scalar a1, real scalar b1, real scalar svmode,
               real scalar prior,
               real scalar t0, real scalar t1, real scalar pi_,
               real scalar k0, real scalar k1, real scalar qij,
               real scalar tau_th, real scalar d_lam,
               real scalar e_lam, real scalar stau, real scalar hsmode,
               real matrix Astore, real matrix Lstore, real matrix Sstore,
               real matrix Gstore, real matrix SVstore,
               real matrix Y, real matrix X)
{
    real scalar T, k, M, ntot, nkeep, irep, m, i, s, a_full, b_full, sig2
    real matrix Sv, A, L, Linv, E, Estr, Lpri, lpri, sdal, gam, omg, Vcur
    real matrix TAU, LAM2, TUNE, ACC, TZ, SVP
    real scalar pmx, tth, nEh, nXh, nLh, svmu, svph, svsg
    real colvector dsv, lamE, nuE, lamX, nuX, lamL, nuL, hcol

    gvar_bdata(Yraw, Wraw, plag, plagstar, cons, trend, Y, X)
    T = rows(Y)
    k = cols(X)
    M = cols(Y)

    ntot  = nburn + ndraw
    nkeep = floor(ndraw / nthin)

    // log variance, initialised as BGVAR does
    Sv   = J(T, M, -3)
    A    = J(k, M, 0)
    L    = I(M)
    Linv = I(M)
    E    = J(T, M, 0)
    Estr = J(T, M, 0)

    // a flat prior on the free elements of L, as BGVAR's L_prior/l_prior
    Lpri = J(M, M, 10)
    lpri = J(M, M, 0)

    // start at OLS so the chain does not have to walk in from nowhere
    A = gvar_msolve(cross(X, X), cross(X, Y))
    E = Y - X * A

    Astore = J(k * M, nkeep, .)
    Lstore = J(M * M, nkeep, .)
    Sstore = J(M, nkeep, .)
    // Gstore carries k*M numbers per draw.  Under SSVS those are the
    // inclusion indicators; under Normal-Gamma the slot is idle, so it holds
    // the LOCAL PRIOR VARIANCES instead.  That is deliberate: the NG
    // hierarchy shrinks V, not the coefficients, so V is the only thing a
    // compounding check can honestly look at.  The accessor's meaning
    // therefore depends on the prior, and gvar_getbprior() says which.
    Gstore = J(k * M, nkeep, .)

    // The SV state.  BGVAR initialises Sv_draw to -3 and Sv_para to
    // (mu, phi, sigma, h0) = (-10, .9, .2, -10) per equation
    // (BVAR_linear.cpp:239-246); h0 is folded into the stationary prior on h_0
    // here, so only the first three are carried.
    SVP = J(3, M, 0)
    for (m = 1; m <= M; m++) {
        SVP[1, m] = -10
        SVP[2, m] = 0.9
        SVP[3, m] = 0.2
    }
    SVstore = J(1, 1, .)
    if (svmode == 2) SVstore = J(T * M, nkeep, .)

    // BVAR_linear.cpp:155 sets V_prior.fill(10) for EVERY prior and line 169
    // calls get_Vminnesota only under "if(prior==1)".  So SSVS and Normal-Gamma
    // start from a flat variance of 10 and refill V from their own hierarchy.
    // Seeding them with the Minnesota V instead -- which is what this did --
    // changes the first coefficient sweep, and under Normal-Gamma it changes
    // more than that: the first lambda^2 draw has rate e + tau sum(V)/2, so a
    // Minnesota lag block (sum ~ 0.25) starts the hierarchy at lambda^2 ~ 176
    // instead of ~0.2 and it descends from the wrong end.
    sdal = J(k, M, 1)
    gam  = J(k, M, 1)
    omg  = J(M, M, 1)
    Vcur = Vpri
    if (prior != 1) Vcur = J(k, M, 10)
    if (prior == 2) sdal = gvar_ssvssd(Y, X)

    // Normal-Gamma state: one global variance per lag per block, plus the
    // shape tau.  Two columns -- endogenous and weakly exogenous -- because
    // the source keeps those hierarchies separate.
    //
    // tau_th missing means "use BGVAR's per-entity default", 1/ln(M), which
    // utils.R:298 substitutes whenever the entity has more than one endogenous
    // variable.  It is resolved here rather than in the ado because M varies by
    // unit and a single number could not be right for all of them.
    //
    // Resolved into a LOCAL.  Mata passes by reference, so assigning to tau_th
    // itself would write through to gvar_bayesrun's own argument and freeze the
    // first unit's 1/ln(M) for every unit after it -- silently, and only for
    // models whose units differ in M, which is most of them.
    pmx = max((plag, plagstar))
    tth = tau_th
    if (missing(tth)) {
        tth = 0.7
        if (M > 1) tth = 1 / log(M)
    }
    TAU  = J(pmx + 2, 2, tth)
    LAM2 = J(pmx + 2, 2, 1)
    TUNE = J(pmx + 2, 2, 0.43)
    ACC  = J(pmx + 2, 2, 0)

    // Horseshoe state: THREE hierarchies -- endogenous lags, weakly exogenous
    // block, free elements of L -- each with its own local lambda and nu and
    // its own global tau and zeta.  All start at one, as the source does
    // (BVAR_linear.cpp:211-214).  The max(.,1) keeps a zero-length vector out
    // of J() when Mstar is 0 or M is 1; gvar_hs skips those blocks anyway.
    nEh  = plag * M * M
    nXh  = (plagstar + 1) * cols(Wraw) * M
    nLh  = M * (M - 1) / 2
    lamE = nuE = J(max((nEh, 1)), 1, 1)
    lamX = nuX = J(max((nXh, 1)), 1, 1)
    lamL = nuL = J(max((nLh, 1)), 1, 1)
    TZ   = J(3, 2, 1)

    for (irep = 1; irep <= ntot; irep++) {

        // ---- steps 1-2: coefficients and the covariance factor ----------
        gvar_bsweep(Y, X, Sv, Vcur, Apri, Lpri, lpri, A, L, Linv, E, Estr)

        // ---- the prior: a rule for refilling V, not a second sampler -----
        if (prior == 2) {
            gvar_ssvs(A, Apri, L, lpri, sdal, t0, t1, pi_, k0, k1, qij,
                      Vcur, Lpri, gam, omg)
        }
        if (prior == 3) {
            gvar_ng(A, Apri, M, cols(Wraw), plag, plagstar, d_lam, e_lam,
                    TAU, LAM2, Vcur, stau, TUNE, ACC, irep, nburn)
        }
        if (prior == 4) {
            gvar_hs(A, L, M, cols(Wraw), plag, plagstar, hsmode,
                    lamE, nuE, lamX, nuX, lamL, nuL, TZ, Vcur, Lpri)
        }

        // ---- step 3: the variances --------------------------------------
        // svmode 0  homoskedastic, log sigma^2 stored  (the corrected default)
        //        1  homoskedastic, reproducing BGVAR's cur_sv.fill(sig2), which
        //           writes the variance into a slot every other line treats as a
        //           LOG variance -- source defect #8
        //        2  stochastic volatility
        for (m = 1; m <= M; m++) {
            if (svmode == 2) {
                // Mata cannot pass a matrix ELEMENT by reference: gvar_svsweep
                // must be handed scalars and the state written back, or the
                // (mu, phi, sigma) update would be lost every sweep.
                hcol = Sv[., m]
                svmu = SVP[1, m]
                svph = SVP[2, m]
                svsg = SVP[3, m]
                gvar_svsweep(Estr[., m], hcol, svmu, svph, svsg,
                             0, 10000, 1, 25, 1.5)
                Sv[., m]  = hcol
                SVP[1, m] = svmu
                SVP[2, m] = svph
                SVP[3, m] = svsg
            }
            else {
                dsv    = Estr[., m]
                a_full = a1 + 0.5 * T
                b_full = b1 + 0.5 * cross(dsv, dsv)
                sig2   = 1 / rgamma(1, 1, a_full, 1 / b_full)
                if (svmode == 1) Sv[., m] = J(T, 1, sig2)
                else             Sv[., m] = J(T, 1, log(sig2))
            }
        }

        // ---- step 5: storage --------------------------------------------
        if (irep > nburn) {
            if (mod(irep - nburn - 1, nthin) == 0) {
                s = floor((irep - nburn - 1) / nthin) + 1
                if (s >= 1 & s <= nkeep) {
                    Astore[., s] = vec(A)
                    Lstore[., s] = vec(L)
                    if (prior == 3 | prior == 4) Gstore[., s] = vec(Vcur)
                    else                          Gstore[., s] = vec(gam)
                    for (i = 1; i <= M; i++) {
                        Sstore[i, s] = exp(Sv[1, i])
                        if (svmode == 1) Sstore[i, s] = Sv[1, i]
                    }
                    // Under SV the variance is a PATH, and one number per
                    // equation cannot represent it.  The whole T x M log-variance
                    // surface is kept, because gvar_bslot needs every period to
                    // form the elementwise median over time that the source's
                    // stacker uses (utils.R:387).
                    if (svmode == 2) SVstore[., s] = vec(Sv)
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Write the posterior into the country-model slots that gvar solve reads.
//
// This is the step that was MISSING, and its absence was the worst defect in
// the Bayesian branch.  gvar bayes stored its draws in m.bA/bL/bS, set
// m.hasbayes = 1, and printed "Next: gvar solve stacks the posterior mean" --
// while gvar solve read m.Th/m.L0/m.Lm/m.a0/m.a1, which nothing had written.
// So gvar solve either refused (rc 301, "run gvar estimate first") or stacked
// whatever gvar estimate had left behind, and every impulse response after it
// was the MAXIMUM LIKELIHOOD model while the user believed it was Bayesian.
//
// _test44.do never caught it because all 41 of its checks read gvar_getbA()
// directly: they verify the sampler and say nothing about whether the sampler
// is connected to anything.  _test46.do exists to ask that question.
//
// The mapping is direct, because a Bayesian VARX* has no cointegration step to
// undo.  X is laid out [endog lag 1..plag | star lag 0..plagstar | cons |
// trend] and A is k x M with equations in COLUMNS, so A' has them in rows:
//
//     Theta_l  = A'[., (l-1)M+1 .. lM]
//     Lambda_0 = A'[., plag*M+1 .. plag*M+Mstar]
//     Lambda_l = A'[., plag*M+l*Mstar+1 .. plag*M+(l+1)*Mstar]
//     a0, a1   = the deterministic columns that follow
//
// Th and Lm are padded to m.pmax, the GLOBAL lag order, not to this unit's own
// p_i -- that is what gvar_vecx2varx produces and what gvar_stack indexes.  A
// unit with fewer lags than the system gets zero blocks, and writing them at
// the unit's own width would misalign every later unit in the stack.
//
// Sigma is averaged over draws as L D L', not formed from the mean of L and the
// mean of D.  Those differ: the posterior mean of a matrix product is not the
// product of the posterior means.  (L D L', not inv(L) D inv(L)' -- see the note
// in gvar_bslot and _test51.do.)
// ---------------------------------------------------------------------------
// One unit's VARX slots, from the posterior mean when s == 0 or from a single
// draw when s >= 1.  Both gvar_bpost() and gvar_btrim() go through here so the
// mapping exists in exactly one place: the trim has to build the same
// quantities per draw that the final model is built from, and two copies of
// this arithmetic would eventually disagree.
// m is taken by reference -- Mata passes struct scalars that way -- so the
// caller copies the model in and out ONCE rather than 26 times per draw.  With
// 200 draws that is 200 struct copies instead of 5200.
void gvar_bslot(struct gvarmodel scalar m, real scalar i, real scalar s)
{
    real scalar M, k, ml, plag, plagstar, Mstar, l, r0, c, t, nd, Tv
    real matrix Ad, Ld, Sd, A, At, Th, L0, Lm, Om, Lms, Lin, Y, X, Sv
    real colvector av, a0, a1

    ml = m.pmax
    Ad = *m.bA[i]
    Ld = *m.bL[i]
    Sd = *m.bS[i]
    Y  = *m.bY[i]
    X  = *m.bX[i]
    nd = cols(Ad)
    M  = m.ki[i]
    k  = rows(Ad) / M

    // vec() stacked the columns and Mata's colshape() fills ROW-wise, so the
    // column-major rebuild needs the transpose
    if (s == 0) av = rowsum(Ad) / nd
    else        av = Ad[., s]
    A  = colshape(av, k)'
    At = A'

    plag     = m.lagord[i, 1]
    plagstar = m.lagord[i, 2]
    Mstar    = m.ksi[i]

    Th = J(M, M * ml, 0)
    for (l = 1; l <= plag; l++) {
        Th[., ((l - 1) * M + 1)::(l * M)] = At[., ((l - 1) * M + 1)::(l * M)]
    }

    r0 = plag * M
    L0 = J(M, max((Mstar, 1)), 0)
    Lm = J(M, max((Mstar * ml, 1)), 0)
    if (Mstar > 0) {
        L0 = At[., (r0 + 1)::(r0 + Mstar)]
        Lm = J(M, Mstar * ml, 0)
        for (l = 1; l <= plagstar; l++) {
            Lm[., ((l - 1) * Mstar + 1)::(l * Mstar)] =
                At[., (r0 + l * Mstar + 1)::(r0 + (l + 1) * Mstar)]
        }
    }

    // gvar_bdata always writes a constant, and a trend only when asked for
    c  = r0 + (plagstar + 1) * Mstar
    a0 = At[., c + 1]
    a1 = J(M, 1, 0)
    if (m.hastrend & cols(At) > c + 1) a1 = At[., c + 2]

    // Sigma = L D L', and the direction of that is NOT a matter of taste.  This
    // code had inv(L) D inv(L)' and was wrong.  The source settles it twice:
    //
    //   BVAR_linear.cpp:412   Em_str_draw = (Y - X A) * L_drawinv.t()
    //   BVAR_linear.cpp:780   data_sv = Em_str_draw.col(mm)   <- the variance
    //                                                            step models D
    //                                                            as Var(eps_str)
    //
    // so eps_str = Linv eps and D = Var(Linv eps) = Linv Sigma Linv', hence
    // Sigma = L D L'.  utils.R:381 writes exactly that:
    //   SIGMA_store[tt,,,irep] <- L_store %*% diag(exp(Sv_store)) %*% t(L_store)
    // and BVAR_linear.cpp:809 stores L_store = L_draw, not its inverse.
    //
    // It is also what makes the sampler's own whitening work: the GLS
    // coefficient draw multiplies by Linv, which only produces independent
    // components if Linv Sigma Linv' is diagonal.
    //
    // Nothing in the suite caught this.  The checks verified Om's shape, its
    // symmetry, the ranges of what depended on it and how it responded to the
    // prior -- everything about Sigma except WHAT IT WAS.  A quantity needs at
    // least one check against an independent construction of the same thing.
    //
    // Averaged over draws for the posterior mean, NOT formed from the mean of L
    // and the mean of D: the posterior mean of a matrix product is not the
    // product of the posterior means.
    Om = J(M, M, 0)
    if (m.bsv == 2) {
        // Stochastic volatility: Sigma_t = L diag(exp(h_t)) L' varies with t, so
        // there is no single covariance and one has to be chosen.  The source
        // chooses the ELEMENTWISE MEDIAN OVER TIME:
        //
        //   utils.R:381  SIGMA_store[tt,,,irep] <- L %*% diag(exp(Sv)) %*% t(L)
        //   utils.R:387  SIGMAmed_store <- apply(SIGMA_store, c(2,3,4), median)
        //
        // margins 2,3,4 being (M, M, draws), so the margin collapsed is TIME.
        // Not the mean, and not Sigma at one period -- both of which would have
        // been reasonable guesses and both wrong.
        //
        // Note an elementwise median of PSD matrices need not itself be PSD.
        // That is the source's choice, not an oversight here, and it is why
        // gvar_ispd's eigenvalue test matters downstream.
        Sv = *m.bSV[i]
        Tv = rows(Sv) / M
        if (s == 0) {
            for (t = 1; t <= nd; t++) {
                Om = Om + gvar_svmedcov(Sv[., t], Ld[., t], M, Tv)
            }
            Om = Om / nd
        }
        else {
            Om = gvar_svmedcov(Sv[., s], Ld[., s], M, Tv)
        }
    }
    else if (s == 0) {
        for (t = 1; t <= nd; t++) {
            Lms = colshape(Ld[., t], M)'
            Om  = Om + Lms * diag(Sd[., t]) * Lms'
        }
        Om = Om / nd
    }
    else {
        Lms = colshape(Ld[., s], M)'
        Om  = Lms * diag(Sd[., s]) * Lms'
    }

    m.a0[i] = &(a0[., .])
    m.a1[i] = &(a1[., .])
    m.Th[i] = &(Th[., .])
    m.L0[i] = &(L0[., .])
    m.Lm[i] = &(Lm[., .])
    m.Om[i] = &(makesymmetric(Om))
    m.ep[i] = &((Y - X * A)')
}

// The slot arrays are allocated by gvar_estimate, so gvar bayes run on its own
// -- which is the sequence its own help page describes -- found them empty and
// gvar_bslot failed with 3301 subscript invalid.  Allocated here so the
// Bayesian path does not depend on an ML fit having happened first.
//
// Only the slots the Bayesian branch fills.  al, be, ben, Ps, ec and the
// standard errors stay unallocated on purpose: they are the cointegration
// quantities, a VARX in levels has none, and filling them with zeros would let
// gvar pp and gvar overid run and return something -- which is exactly what the
// vecmx requirement exists to prevent.
void gvar_balloc()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar N

    m = gvar_MODEL
    N = m.N
    if (rows(m.a0) != N) m.a0 = J(N, 1, NULL)
    if (rows(m.a1) != N) m.a1 = J(N, 1, NULL)
    if (rows(m.Th) != N) m.Th = J(N, 1, NULL)
    if (rows(m.L0) != N) m.L0 = J(N, 1, NULL)
    if (rows(m.Lm) != N) m.Lm = J(N, 1, NULL)
    if (rows(m.Om) != N) m.Om = J(N, 1, NULL)
    if (rows(m.ep) != N) m.ep = J(N, 1, NULL)
    gvar_MODEL = m
}

void gvar_bpost()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, N

    gvar_balloc()
    m = gvar_MODEL
    N = m.N
    for (i = 1; i <= N; i++) {
        gvar_bslot(m, i, 0)
    }

    // The model is estimated, but NOT by reduced-rank ML.  esttype says so, and
    // gvar solve keys its unit-root diagnostic off it: a Bayesian VARX in levels
    // imposes no cointegrating rank, so "K - sum(r)" has nothing to compare
    // against and the eigenvalue trim takes its place.
    m.estimated = 1
    m.solved    = 0
    m.esttype   = "bvarx"
    gvar_MODEL  = m
}

// ---------------------------------------------------------------------------
// The eigenvalue trim  (BGVAR R/utils.R .gvar.stacking.wrapper)
//
//     idx <- which(F.eigen < trim)
//
// applied per DRAW to the modulus of the largest companion eigenvalue of the
// STACKED system, and the source stops outright below 10 stable draws.
//
// It is global, not per unit, and that is the whole point: a country model can
// be perfectly stable while the stacked GVAR is not, and the reverse.  Trimming
// unit by unit would discard draws the global model would have kept.
//
// Returns the number of stable draws and leaves the moduli in feig.  The
// unstable columns are dropped from bA, bL, bS and bG together, so the four
// stay aligned -- dropping from one alone would silently pair each coefficient
// draw with another draw's covariance.
// ---------------------------------------------------------------------------
real scalar gvar_btrim(real scalar trim)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, N, nd, s, ns
    real colvector keep, feig

    gvar_balloc()
    N    = gvar_MODEL.N
    nd   = cols(*gvar_MODEL.bA[1])
    feig = J(nd, 1, .)

    // Each draw is written into the country-model slots and the system solved,
    // which is what leaves the companion eigenvalue moduli in gvar_geteig().
    // The stacking is the point: stability is a property of the ASSEMBLED GVAR,
    // not of any one country model, and the two do not imply each other in
    // either direction.
    for (s = 1; s <= nd; s++) {
        m = gvar_MODEL
        for (i = 1; i <= N; i++) {
            gvar_bslot(m, i, s)
        }
        gvar_MODEL = m
        gvar_solvemodel()
        feig[s] = max(gvar_geteig())
    }

    keep = J(0, 1, .)
    for (s = 1; s <= nd; s++) {
        if (feig[s] < trim) keep = keep \ s
    }
    ns = rows(keep)

    // Drop the unstable columns from bA, bL, bS and bG TOGETHER.  Dropping from
    // one alone would leave each surviving coefficient draw paired with another
    // draw's covariance factor, and no diagnostic would show it.
    m = gvar_MODEL
    m.bfeig = feig
    if (ns > 0 & ns < nd) {
        for (i = 1; i <= N; i++) {
            m.bA[i] = &((*m.bA[i])[., keep])
            m.bL[i] = &((*m.bL[i])[., keep])
            m.bS[i] = &((*m.bS[i])[., keep])
            m.bG[i] = &((*m.bG[i])[., keep])
        }
        m.bdraws = ns
        m.bfeig  = feig[keep]
    }
    m.solved   = 0
    gvar_MODEL = m
    return(ns)
}

// BGVAR returns the moduli as F.eigen; they are a reportable quantity, so they
// live in the model rather than being passed back through a temporary.
real colvector gvar_getbfeig()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.bfeig)
}

// "vecmx" reduced-rank ML, "bvarx" a Bayesian VARX in levels.  Commands that
// need the cointegrating vectors have to be able to tell the difference: a
// Bayesian VARX imposes no rank, so beta and alpha are whatever an earlier
// gvar estimate happened to leave behind, and using them would be silent
// nonsense rather than an error.
string scalar gvar_getesttype()
{
    external struct gvarmodel scalar gvar_MODEL
    return(gvar_MODEL.esttype)
}

// ---------------------------------------------------------------------------
// Spectral density at zero, by an AIC-selected AR fit.
//   coda's spectrum0.ar(), which BGVAR's conv.diag() reaches through
//   geweke.diag().  coda is a dependency (NAMESPACE:63), not part of the BGVAR
//   source, so this is written from the algorithm like the GIG sampler and
//   gated the same way -- _test47.do checks it against the closed form
//   sigma^2/(1-phi)^2 for an AR(1).
//
//     spec = var.pred / (1 - sum(phi))^2
//
// This is the LONG-RUN variance, and using it rather than the sample variance is
// the whole point of Geweke's diagnostic: an MCMC chain is autocorrelated, and
// the sample variance would understate the standard error of its mean and so
// reject far too often -- which reads as a broken sampler rather than a broken
// diagnostic.
//
// Yule-Walker through the Durbin-Levinson recursion, which hands back the
// prediction-error variance at every order, so the AIC sweep is free.
// ---------------------------------------------------------------------------
real scalar gvar_spec0ar(real colvector x0)
{
    real scalar n, pmax, k, j, num, a, vk, best, bic, kstar, sphi, vpred
    real colvector x, r, v, phi, prev

    n = rows(x0)
    if (n < 4) return(.)

    x = x0 :- mean(x0)
    // a constant chain has no variance; coda returns 0 rather than dividing by it
    if (max(abs(x)) <= 0) return(0)

    // R's ar() default: order.max = min(n-1, floor(10*log10(n)))
    pmax = min((n - 1, floor(10 * log10(n))))
    if (pmax < 1) pmax = 1

    // autocovariances, divided by n as R's acf does
    r = J(pmax + 1, 1, 0)
    for (k = 0; k <= pmax; k++) {
        r[k + 1] = cross(x[1::(n - k)], x[(1 + k)::n]) / n
    }
    if (r[1] <= 0) return(0)

    // Durbin-Levinson, tracking the prediction variance at each order
    v   = J(pmax + 1, 1, .)
    v[1] = r[1]
    phi  = J(0, 1, .)
    for (k = 1; k <= pmax; k++) {
        num = r[k + 1]
        for (j = 1; j <= k - 1; j++) {
            num = num - phi[j] * r[k - j + 1]
        }
        a = num / v[k]
        if (abs(a) >= 1) {
            // the recursion has left the stationary region; stop and keep the
            // orders already computed rather than propagate a negative variance
            pmax = k - 1
            break
        }
        prev = phi
        phi  = J(k, 1, 0)
        for (j = 1; j <= k - 1; j++) {
            phi[j] = prev[j] - a * prev[k - j]
        }
        phi[k]   = a
        v[k + 1] = v[k] * (1 - a ^ 2)
    }
    if (pmax < 1) return(r[1] * n / (n - 1))

    // AIC over orders 0..pmax.  Only differences matter, so R's additive
    // constant is dropped.
    kstar = 0
    best  = n * log(v[1])
    for (k = 1; k <= pmax; k++) {
        if (v[k + 1] <= 0) break
        bic = n * log(v[k + 1]) + 2 * k
        if (bic < best) {
            best  = bic
            kstar = k
        }
    }

    // re-run to the chosen order to recover its coefficients
    sphi = 0
    if (kstar > 0) {
        phi = J(0, 1, .)
        for (k = 1; k <= kstar; k++) {
            num = r[k + 1]
            for (j = 1; j <= k - 1; j++) {
                num = num - phi[j] * r[k - j + 1]
            }
            a    = num / v[k]
            prev = phi
            phi  = J(k, 1, 0)
            for (j = 1; j <= k - 1; j++) {
                phi[j] = prev[j] - a * prev[k - j]
            }
            phi[k] = a
        }
        sphi = sum(phi)
    }

    // R's ar() rescales the innovation variance by n/(n - (order+1))
    vpred = v[kstar + 1] * n / (n - (kstar + 1))
    if (abs(1 - sphi) < 1e-12) return(.)
    return(vpred / (1 - sphi) ^ 2)
}

// ---------------------------------------------------------------------------
// Geweke's (1992) Z, as coda's geweke.diag computes it.
//
// The two windows follow coda exactly: with the chain indexed 1..n,
//
//     window 1 = [1,                       1 + frac1*(n-1)]
//     window 2 = [n - frac2*(n-1),         n              ]
//
// so at the defaults the first 10% and the last 50%.  Under stationarity the two
// means are equal and Z is asymptotically standard normal.
// ---------------------------------------------------------------------------
real scalar gvar_geweke(real colvector x, real scalar frac1, real scalar frac2)
{
    real scalar n, e1, s2, n1, n2, m1, m2, v1, v2, se
    real colvector w1, w2

    n = rows(x)
    if (n < 20) return(.)

    e1 = floor(1 + frac1 * (n - 1))
    s2 = ceil(n - frac2 * (n - 1))
    if (e1 < 4)      e1 = 4
    if (s2 > n - 3)  s2 = n - 3
    if (e1 >= n | s2 < 1) return(.)

    w1 = x[1::e1]
    w2 = x[s2::n]
    n1 = rows(w1)
    n2 = rows(w2)

    m1 = mean(w1)
    m2 = mean(w2)
    v1 = gvar_spec0ar(w1) / n1
    v2 = gvar_spec0ar(w2) / n2
    if (missing(v1) | missing(v2)) return(.)

    se = sqrt(v1 + v2)
    // a chain that never moved has no Z; report missing rather than 0/0
    if (se <= 0) return(.)
    return((m1 - m2) / se)
}

// ---------------------------------------------------------------------------
// Geweke over every sampled coefficient of every unit.
//
// BGVAR runs its diagnostic on A_large, the STACKED coefficients.  This runs it
// on the per-unit draws instead, which are the parameters the sampler actually
// moves; the stacked matrix is a deterministic function of them, so a chain that
// has not converged in one has not converged in the other, and the per-unit
// version says WHICH unit.  Noted because it is a deliberate difference.
//
// A missing Z -- a coefficient that never moved, which SSVS and the shrinkage
// priors produce by design -- is excluded from the count rather than treated as
// a pass, exactly as conv.diag drops coda's failures by decrementing K.
// ---------------------------------------------------------------------------
real matrix gvar_bconvrun(real scalar crit, real scalar frac1, real scalar frac2)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, N, j, nk, ntot, nex, z, nskip
    real matrix Ad, OUT
    real colvector zi

    m    = gvar_MODEL
    N    = m.N
    ntot = 0
    nex  = 0
    nskip = 0
    OUT  = J(N, 4, 0)

    for (i = 1; i <= N; i++) {
        Ad = *m.bA[i]
        nk = rows(Ad)
        zi = J(nk, 1, .)
        for (j = 1; j <= nk; j++) {
            z = gvar_geweke(Ad[j, .]', frac1, frac2)
            zi[j] = z
        }
        OUT[i, 1] = i
        OUT[i, 2] = sum(zi :< .)
        OUT[i, 3] = sum(abs(zi) :> crit :& zi :< .)
        OUT[i, 4] = nk - sum(zi :< .)
        ntot  = ntot + OUT[i, 2]
        nex   = nex + OUT[i, 3]
        nskip = nskip + OUT[i, 4]
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// A symmetric square root that works on a SINGULAR matrix.
//
// Omega(h), the h-step forecast-error covariance, is K x K built from a
// Sigma_eta of rank at most T.  With K = 136 and T = 134 it is singular, so
// cholesky() has no factor to give and gvar_ispd() now correctly refuses it
// (see the eigenvalue test there).  BGVAR reaches the same place and falls back
// on mvrnorm, which is this: the symmetric eigen decomposition.
//
//     A = V diag(lambda) V'   ->   R = V diag(sqrt(lambda)) V',   R R' = A
//
// Eigenvalues that come out slightly NEGATIVE are rounding on a matrix that is
// singular by construction, not a signal, so they are clamped at zero.  Without
// the clamp sqrt() returns missing and the missing then passes every downstream
// comparison, which is trap 11 in _INVENTORY.md all over again.
// ---------------------------------------------------------------------------
real matrix gvar_psdroot(real matrix A)
{
    real matrix X, B
    real rowvector ev

    B = makesymmetric(A)
    symeigensystem(B, X = ., ev = .)
    if (hasmissing(ev) | hasmissing(X)) return(J(rows(A), cols(A), .))
    ev = ev :* (ev :> 0)
    return(X * diag(sqrt(ev)) * X')
}

// ---------------------------------------------------------------------------
// Sigma_zeta implied by ONE draw: block diagonal in the country covariances.
//
// This is not m.Szeta.  m.Szeta is the sample covariance of the stacked
// residuals and carries full cross-country correlation; the draw's Sigma_zeta
// is blockdiag(Omega_1, ..., Omega_N), because the sampler treats the units
// independently and never estimates a cross-unit covariance.  BGVAR uses the
// block-diagonal one -- Sig_t = Ginv %*% S_large[,,irep] %*% t(Ginv), and
// S_large is the stacked per-country matrix -- and so does this.
//
// The consequence is worth stating rather than hiding: cross-country shock
// correlation is ZERO in the predictive density, so it understates joint
// uncertainty. That is inherited from the per-unit sampler, not a choice made
// here, and it is why gvar irf still reads Sigma_zeta from the residuals.
// ---------------------------------------------------------------------------
real matrix gvar_bsigzeta(struct gvarmodel scalar m)
{
    real scalar i, N, r, ki
    real matrix S

    N = m.N
    S = J(m.K, m.K, 0)
    r = 0
    for (i = 1; i <= N; i++) {
        ki = m.ki[i]
        S[(r + 1)::(r + ki), (r + 1)::(r + ki)] = *m.Om[i]
        r = r + ki
    }
    // The dominant block closes the matrix.  gvar bayes samples the N COUNTRY
    // models only -- the dominant unit is conditioned on, not re-sampled -- so
    // without this the last gd rows and columns stay zero, S is singular by
    // construction, and every draw fails.  gvar bdic then reported "the global
    // likelihood could not be evaluated at any draw" and blamed the sampler.
    //
    // duOm is the dominant unit's own residual covariance from gvar dominant,
    // which is exactly the right thing here: it is fixed across draws because
    // the model that produced it is.
    if (m.hasdu == 1) {
        ki = rows(m.duylist)
        if (ki > 0 & r + ki <= m.K) {
            S[(r + 1)::(r + ki), (r + 1)::(r + ki)] = m.duOm
        }
    }
    return(S)
}

// ---------------------------------------------------------------------------
// The predictive density  (BGVAR predict.R, corrected)
//
// Per draw: write the draw into the country-model slots, solve, take the mean
// path from gvar_forecast() -- the SAME routine gvar forecast uses, so the two
// commands cannot drift apart -- accumulate Omega(h), and draw
//
//     x_{T+h} = mean_h + psdroot(Omega_h) * N(0, I)
//
// Note what that last line is and is not.  Omega_h is the CUMULATIVE
// forecast-error covariance, so each horizon is a draw from its own MARGINAL
// predictive.  Within one draw the horizons do not share shock realisations, so
// a row of the output is NOT a simulated path and must not be plotted as one.
// It is exactly right for the marginal intervals that get reported, which is
// what BGVAR does too.
//
// TWO DEFECTS IN BGVAR ARE NOT REPRODUCED, both settled by reading the source
// (_INVENTORY.md 29-31):
//
//   the trend: .get_companion carries the deterministic block with diag(nd), so
//   BGVAR's trend freezes at its last in-sample value and the drift is a1*T at
//   every horizon.  gvar_forecast advances it as d1*(Traw-1+h).
//
//   the state: BGVAR starts at Xn[bigT,], which .mlag fills with y_{T-1}..y_{T-p},
//   so its first companion multiply returns the FITTED value at T and horizon h
//   is really T+h-1.  gvar_forecast starts from the observed terminal values, so
//   horizon 1 is T+1.
//
// Neither is offered as a reproduction mode.  Defects #8 and #11 got bgvarsv and
// bgvarhs because reproducing them lets a user match published BGVAR output on a
// quantity that is otherwise defensible.  A forecast whose first horizon is an
// in-sample fit is not defensible, and nobody wants to match it.
//
// Returns (nsel*H) x (3 + nq): horizon, variable index, predictive mean, then
// one column per requested quantile.
// ---------------------------------------------------------------------------
real matrix gvar_bfcrun(real scalar H, real colvector sel, real rowvector qs)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, N, K, nd, s, h, j, ns, nq, r, nfail
    real matrix D, OUT, MU, PH, OM, Rt, Sz, Se, iG0
    real colvector lb, dv

    N  = gvar_MODEL.N
    K  = gvar_MODEL.K
    nd = cols(*gvar_MODEL.bA[1])
    ns = rows(sel)
    nq = cols(qs)
    lb = J(K, 1, .)

    // draws for the selected variables only: nd columns per (variable, horizon)
    D     = J(ns * H, nd, .)
    nfail = 0

    for (s = 1; s <= nd; s++) {
        m = gvar_MODEL
        for (i = 1; i <= N; i++) {
            gvar_bslot(m, i, s)
        }
        gvar_MODEL = m
        gvar_solvemodel()
        m = gvar_MODEL

        if (hasmissing(m.Fs)) {
            nfail = nfail + 1
            continue
        }

        // the draw's own Sigma_eta
        iG0 = gvar_inv(m.G0)
        Sz  = gvar_bsigzeta(m)
        Se  = iG0 * Sz * iG0'

        MU = gvar_forecast(m.X, m.pmax, m.Fs, m.d0, m.d1, H, lb)
        PH = gvar_phi(m.Fs, K, m.pmax, H)
        OM = gvar_fcomega(K, H, PH, Se)

        for (h = 1; h <= H; h++) {
            Rt = gvar_psdroot(OM[., ((h-1)*K + 1)::(h*K)])
            if (hasmissing(Rt)) {
                nfail = nfail + 1
                break
            }
            dv = MU[., h] + Rt * rnormal(K, 1, 0, 1)
            for (j = 1; j <= ns; j++) {
                D[(j - 1) * H + h, s] = dv[sel[j]]
            }
        }
    }

    // the model is left holding the posterior mean again, not the last draw.
    //
    // gvar_bpost() sets solved = 0, which is right where it is normally called
    // -- at the end of gvar bayes, where the model genuinely has not been
    // solved.  Here it is a RESTORE, and this function required a solved model
    // to start, so leaving it unsolved destroys state a read-only analysis had
    // no business touching: the next command that needs it exits 301 having
    // done nothing wrong.  Re-solve, so the model is returned as it was found.
    gvar_bpost()
    gvar_solvemodel()

    OUT = J(ns * H, 3 + nq, .)
    for (j = 1; j <= ns; j++) {
        for (h = 1; h <= H; h++) {
            r = (j - 1) * H + h
            dv = D[r, .]'
            dv = select(dv, dv :< .)
            OUT[r, 1] = h
            OUT[r, 2] = sel[j]
            if (rows(dv) > 0) {
                OUT[r, 3] = mean(dv)
                for (i = 1; i <= nq; i++) {
                    OUT[r, 3 + i] = gvar_quantile(dv, qs[i])
                }
            }
        }
    }
    return(OUT)
}

// ---------------------------------------------------------------------------
// Multivariate normal log likelihood, rows independent.
//   BGVAR helper.cpp dmvnrm_arma_fast, summed.
//
//   log L = -T n/2 log(2 pi) - T/2 log|Sigma| - 1/2 sum_t e_t' Sigma^-1 e_t
//
// Returns MISSING for a singular Sigma rather than a number.  The source falls
// back on R's pivoted chol() when armadillo's fails, which lets it return a
// value for a covariance that has no density -- and a likelihood computed from a
// singular covariance is not a likelihood.  Refusing is the only honest answer,
// and it also keeps the DIC below from quietly averaging a nonsense draw in.
//
// Note this Sigma is Ginv S Ginv' with S BLOCK DIAGONAL in the country
// covariances, so it is full rank; it is not the residual Sigma_zeta, which is
// singular at K = 136 with T = 134.  The two are different objects and this is
// the tractable one.
// ---------------------------------------------------------------------------
real scalar gvar_mvnlogl(real matrix Y, real matrix MU, real matrix Sigma)
{
    real scalar T, n, ld, q, t
    real matrix E, Si

    T = rows(Y)
    n = cols(Y)
    if (rows(MU) != T | cols(MU) != n)      return(.)
    if (rows(Sigma) != n | cols(Sigma) != n) return(.)
    if (gvar_ispd(Sigma) == 0)               return(.)

    ld = gvar_logdet(Sigma)
    if (missing(ld))                         return(.)
    Si = gvar_sinv(Sigma)
    E  = Y - MU

    // trace form: sum_t e_t' Si e_t = trace(E Si E') = sum over elements of
    // (E * Si) :* E, which avoids building a T x T product
    q = sum((E * Si) :* E)
    return(-T * n / 2 * ln(2 * pi()) - T / 2 * ld - 0.5 * q)
}

// ---------------------------------------------------------------------------
// The deviance information criterion  (BGVAR.R:1040-1058, dic())
//
//     Dbar = -2 mean_s logL(theta_s)
//     pD   = Dbar - D(theta_bar) = Dbar + 2 logL(theta_bar)
//     DIC  = Dbar + pD
//
// The global regression is the reduced form itself,
//     Y_t = d0 + d1 t + sum_l F_l Y_{t-l} + eta_t
// so X_t = [Y_{t-1}, ..., Y_{t-pmax}, 1, t] and A = [F_1'; ...; d0'; d1'].
//
// theta_bar follows the source: A_large, S_large and Ginv_large are averaged
// SEPARATELY and then combined as Ginv_mean S_mean Ginv_mean'.  That is not the
// mean of Sigma -- E[G0^-1 S G0^-1'] is not E[G0^-1] E[S] E[G0^-1]' -- and it is
// not the model gvar solve holds either, since stacking is nonlinear in the
// country coefficients.  Reproduced anyway, because DIC is a number people
// compare across papers and a different theta_bar gives a different pD.
//
// Returns (Dbar, pD, DIC, nparam, nfail) in a row vector.
// ---------------------------------------------------------------------------
real rowvector gvar_bdicrun()
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real scalar i, N, K, ml, nd, s, T, k, nc, t, l, ll, acc, nfail, Db, pD
    real matrix Y, X, A, Am, Sg, Sm, iG, iGm, S1
    real colvector one, trd

    N  = gvar_MODEL.N
    K  = gvar_MODEL.K
    ml = gvar_MODEL.pmax
    nd = cols(*gvar_MODEL.bA[1])
    m  = gvar_MODEL

    // the global regression, built once
    T   = cols(m.X) - ml
    if (T < 1) return(J(1, 5, .))
    nc  = 1
    if (m.hastrend) nc = 2
    k   = K * ml + nc

    Y = J(T, K, 0)
    X = J(T, k, 0)
    for (t = 1; t <= T; t++) {
        Y[t, .] = m.X[., t + ml]'
        for (l = 1; l <= ml; l++) {
            X[t, ((l-1)*K + 1)::(l*K)] = m.X[., t + ml - l]'
        }
        X[t, K * ml + 1] = 1
        if (nc == 2) X[t, K * ml + 2] = t + ml
    }

    Am    = J(k, K, 0)
    Sm    = J(K, K, 0)
    iGm   = J(K, K, 0)
    acc   = 0
    nfail = 0

    for (s = 1; s <= nd; s++) {
        m = gvar_MODEL
        for (i = 1; i <= N; i++) {
            gvar_bslot(m, i, s)
        }
        gvar_MODEL = m
        gvar_solvemodel()
        m = gvar_MODEL
        if (hasmissing(m.Fs)) {
            nfail = nfail + 1
            continue
        }

        A = J(k, K, 0)
        for (l = 1; l <= ml; l++) {
            A[((l-1)*K + 1)::(l*K), .] = m.Fs[., ((l-1)*K + 1)::(l*K)]'
        }
        A[K * ml + 1, .] = m.d0'
        if (nc == 2) A[K * ml + 2, .] = m.d1'

        iG = gvar_inv(m.G0)
        S1 = gvar_bsigzeta(m)
        Sg = iG * S1 * iG'

        ll = gvar_mvnlogl(Y, X * A, Sg)
        if (missing(ll)) {
            nfail = nfail + 1
            continue
        }
        acc = acc + ll
        Am  = Am  + A
        Sm  = Sm  + S1
        iGm = iGm + iG
    }

    // Restore the posterior mean AND the solved state -- see the note in
    // gvar_bfcrun.  gvar bdic only reports a number; it must not leave the
    // model unsolved behind it.  This is what made gvar_example.do fail at
    // gvar bforecast with rc 301 immediately after a successful gvar solve.
    gvar_bpost()
    gvar_solvemodel()

    if (nd - nfail < 2) return(J(1, 5, .))
    acc = acc / (nd - nfail)
    Am  = Am  / (nd - nfail)
    Sm  = Sm  / (nd - nfail)
    iGm = iGm / (nd - nfail)

    Db = -2 * acc
    ll = gvar_mvnlogl(Y, X * Am, iGm * Sm * iGm')
    if (missing(ll)) return((Db, ., ., k * K, nfail))
    pD = Db + 2 * ll
    return((Db, pD, Db + pD, k * K, nfail))
}

// ===========================================================================
// Stochastic volatility  (BGVAR BVAR_linear.cpp:778-797, sv branch)
// ===========================================================================
// The model is
//
//     log(eps_t^2 + 1e-40) = h_t + log(chi^2_1)
//     h_t = mu + phi (h_{t-1} - mu) + sigma eta_t,   eta ~ N(0,1)
//
// with mu ~ N(bmu, Bmu), phi a stretched Beta(a0,b0) on (-1,1), and
// sigma^2 ~ Gamma(1/2, 1/(2 Bsigma)) -- i.e. a normal(0, Bsigma) prior on sigma.
// Those are BGVAR's PriorSpec at BVAR_linear.cpp:250-255.
//
// WHAT IS REPRODUCED AND WHAT IS NOT.  BGVAR calls stochvol::update_fast_sv,
// which is the Kastner and Fruehwirth-Schnatter (2014) sampler with
// ancillarity-sufficiency interweaving, specific proposals and MHsteps = 2.
// stochvol is a dependency, not part of the source tree, so the algorithm cannot
// be transcribed -- the same situation as GIGrvg and coda.
//
// The TARGET is reproduced exactly: same model, same priors, same mixture. The
// ALGORITHM is the standard Kim-Shephard-Chib mixture sampler rather than the
// interweaved one. That distinction is safe to make because ASIS is an
// EFFICIENCY device -- its contribution is lower autocorrelation, not a
// different posterior -- so this converges to the same distribution and may mix
// more slowly. Which is measurable: that is what gvar bconv is for.
//
// Nothing here is bit-comparable to stochvol, and the help page says so.
// ---------------------------------------------------------------------------

// The 10-component normal mixture approximation to log(chi^2_1)
//   Omori, Chib, Shephard and Nakajima (2007), which is stochvol's table.
// Returns 10 x 3: weight, mean, variance.
//
// These constants are load-bearing.  Mistype one and every volatility path is
// biased by the same amount while looking entirely plausible, so _test50.do
// checks the table against the exact moments of log(chi^2_1):
//   mean -gamma - log 2 = -1.2704,  variance pi^2/2 = 4.9348.
real matrix gvar_svmix()
{
    real matrix P

    P = (0.00609,   1.92677, 0.11265 \
         0.04775,   1.34744, 0.17788 \
         0.13057,   0.73504, 0.26768 \
         0.20674,   0.02266, 0.40611 \
         0.22715,  -0.85173, 0.62699 \
         0.18842,  -1.97278, 0.98583 \
         0.12047,  -3.46788, 1.57469 \
         0.05591,  -5.55246, 2.54498 \
         0.01575,  -8.68384, 4.16591 \
         0.00115, -14.65000, 7.33342)
    return(P)
}

// Draw the mixture indicator for every period, given h.
// p(r_t = i | y_t, h_t) proportional to p_i / v_i * exp(-(y_t - h_t - m_i)^2 / (2 v_i))
real colvector gvar_svind(real colvector y, real colvector h, real matrix P)
{
    real scalar T, t, i, tot, u, cum
    real colvector r
    real rowvector w

    T = rows(y)
    r = J(T, 1, 1)
    w = J(1, 10, 0)
    for (t = 1; t <= T; t++) {
        tot = 0
        for (i = 1; i <= 10; i++) {
            w[i] = P[i, 1] / sqrt(P[i, 3]) *
                   exp(-(y[t] - h[t] - P[i, 2]) ^ 2 / (2 * P[i, 3]))
            tot = tot + w[i]
        }
        if (tot <= 0) {
            r[t] = 5                      // BGVAR initialises rec to 5
            continue
        }
        u   = runiform(1, 1) * tot
        cum = 0
        for (i = 1; i <= 10; i++) {
            cum = cum + w[i]
            if (u <= cum) {
                r[t] = i
                break
            }
        }
    }
    return(r)
}

// Forward filtering, backward sampling for h given the indicators.
//
// Conditional on r, the model is linear Gaussian:
//     y_t = h_t + m_{r_t} + v_{r_t} u_t
//     h_t = mu + phi (h_{t-1} - mu) + sigma eta_t
// so h is drawn by a Kalman filter forward and a simulation smoother backward.
// The state is scalar, so every operation here is scalar arithmetic and there is
// no matrix inversion to go singular.
real colvector gvar_svffbs(real colvector y, real colvector r, real matrix P,
                           real scalar mu, real scalar phi, real scalar sg)
{
    real scalar T, t, a, pv, mt, vt, K, F, hn
    real colvector af, pf, h

    T  = rows(y)
    af = J(T, 1, 0)
    pf = J(T, 1, 0)

    // stationary prior on h_0, as PriorSpec::Latent0() specifies
    a  = mu
    pv = sg ^ 2 / (1 - phi ^ 2)
    if (pv <= 0 | pv >= .) pv = sg ^ 2

    for (t = 1; t <= T; t++) {
        if (t > 1) {
            a  = mu + phi * (af[t-1] - mu)
            pv = phi ^ 2 * pf[t-1] + sg ^ 2
        }
        mt = P[r[t], 2]
        vt = P[r[t], 3]
        F  = pv + vt
        K  = pv / F
        af[t] = a + K * (y[t] - mt - a)
        pf[t] = pv * (1 - K)
    }

    h    = J(T, 1, 0)
    h[T] = af[T] + sqrt(max((pf[T], 0))) * rnormal(1, 1, 0, 1)
    for (t = T - 1; t >= 1; t--) {
        // backward step: h_t | h_{t+1}, data up to t
        F  = phi ^ 2 * pf[t] + sg ^ 2
        K  = phi * pf[t] / F
        hn = af[t] + K * (h[t+1] - mu - phi * (af[t] - mu))
        h[t] = hn + sqrt(max((pf[t] * (1 - K * phi), 0))) * rnormal(1, 1, 0, 1)
    }
    return(h)
}

// One sweep of the AR(1) parameters given h.
//
// mu and phi are a Gaussian regression, so they are drawn directly.  phi is
// rejected outright when the draw leaves (-1,1), which is BGVAR's
// IMMEDIATE_ACCEPT_REJECT_NORMAL, and sigma^2 has its Gamma(1/2, 1/(2 Bsigma))
// prior, which is conjugate to the AR(1) innovations.
// The priors are BGVAR's, and two of the three are NOT conjugate:
//
//   utils.R:752  specify_priors(mu = sv_normal(mean = bmu, sd = Bmu),
//                              phi = sv_beta(a0, b0),
//                              sigma2 = sv_gamma(shape = 0.5,
//                                                rate = 1/(2*Bsigma)))
//   BGVAR.R:433  Bsigma = 1, a0 = 25, b0 = 1.5, bmu = 0, Bmu = 100^2
//
// so sigma^2 has a GAMMA prior, not an inverse gamma, and phi a stretched Beta
// that at (25, 1.5) is strongly informative towards persistence.  Both are
// handled by independence Metropolis, which is what stochvol's
// ProposalSigma2::INDEPENDENCE and ProposalPhi settings amount to.
//
// This is the defect _test50.do caught.  The first version drew sigma^2 from an
// inverse gamma -- assuming a conjugacy that does not hold -- and used a flat
// prior on phi.  It ran, produced plausible paths, recovered the path and phi,
// and missed sigma by more than the tolerance.  Only the known-truth check
// separated it from a correct sampler.
//
// One inconsistency in the source, noted rather than resolved: utils.R:752
// passes Bmu as an SD while BVAR_linear.cpp:252 passes sqrt(Bmu) as the sd, i.e.
// treats Bmu as a VARIANCE.  The C++ path is the one that runs for BGVAR's
// sampler, so Bmu is a variance here.
void gvar_svpara(real colvector h, real scalar bmu, real scalar Bmu,
                 real scalar Bsigma, real scalar a0, real scalar b0,
                 real scalar mu, real scalar phi, real scalar sg)
{
    real scalar T, t, sxx, sxy, vhat, mhat, pnew, ssr, sm, n, s2c, s2p, la
    real colvector x, z

    T = rows(h)
    if (T < 5) return
    n = T - 1

    // ---- phi: propose from the Gaussian conditional, accept with the Beta
    //      prior ratio.  A stretched Beta(a0,b0) on (-1,1) has density
    //      proportional to ((1+phi)/2)^(a0-1) ((1-phi)/2)^(b0-1).
    x   = h[1::(T-1)] :- mu
    z   = h[2::T]     :- mu
    sxx = cross(x, x)
    sxy = cross(x, z)
    if (sxx > 0) {
        vhat = sg ^ 2 / sxx
        mhat = sxy / sxx
        pnew = mhat + sqrt(vhat) * rnormal(1, 1, 0, 1)
        // immediate reject outside the stationary region, as the source does
        if (pnew > -1 & pnew < 1 & phi > -1 & phi < 1) {
            la = (a0 - 1) * (log(1 + pnew) - log(1 + phi)) +
                 (b0 - 1) * (log(1 - pnew) - log(1 - phi))
            if (la < . & la > log(runiform(1, 1))) phi = pnew
        }
    }

    // ---- mu: conjugate, the one Gaussian step ---------------------------
    // h_t - phi h_{t-1} = mu (1 - phi) + sigma eta_t
    sm = 0
    for (t = 2; t <= T; t++) {
        sm = sm + (h[t] - phi * h[t-1])
    }
    vhat = 1 / (n * (1 - phi) ^ 2 / sg ^ 2 + 1 / Bmu)
    mhat = vhat * (sm * (1 - phi) / sg ^ 2 + bmu / Bmu)
    mu   = mhat + sqrt(vhat) * rnormal(1, 1, 0, 1)

    // ---- sigma^2: independence Metropolis ------------------------------
    // target   p(s2 | h) proportional to s2^(-0.5 - n/2) exp(-s2/(2 Bsigma)
    //                                                        - ssr/(2 s2))
    // proposal InvGamma(n/2, ssr/2), i.e. what WOULD be conjugate under a flat
    //          prior, so the ratio target/proposal collapses to
    //              0.5 log s2 - s2/(2 Bsigma)
    // and the acceptance probability is the difference of that at the two points
    ssr = 0
    for (t = 2; t <= T; t++) {
        ssr = ssr + (h[t] - mu - phi * (h[t-1] - mu)) ^ 2
    }
    if (ssr > 0) {
        s2c = sg ^ 2
        s2p = 1 / rgamma(1, 1, n / 2, 2 / ssr)
        if (s2p > 0 & s2p < .) {
            la = (0.5 * log(s2p) - s2p / (2 * Bsigma)) -
                 (0.5 * log(s2c) - s2c / (2 * Bsigma))
            if (la < . & la > log(runiform(1, 1))) sg = sqrt(s2p)
        }
    }
}

// Sigma for one draw under SV: the elementwise median over TIME of
//   Sigma_t = L diag(exp(h_t)) L'
// which is utils.R:381 followed by utils.R:387.  svec is the vectorised T x M
// log-variance surface, lvec the vectorised M x M factor.
real matrix gvar_svmedcov(real colvector svec, real colvector lvec,
                          real scalar M, real scalar Tv)
{
    real matrix H, L, OUT, acc
    real scalar a, b, t

    H   = colshape(svec, Tv)'          // Tv x M, column-major rebuild
    L   = colshape(lvec, M)'
    OUT = J(M, M, .)
    acc = J(Tv, 1, 0)

    for (a = 1; a <= M; a++) {
        for (b = 1; b <= M; b++) {
            for (t = 1; t <= Tv; t++) {
                // element (a,b) of L diag(exp(h_t)) L' is sum_j L[a,j] L[b,j] e^h_tj
                acc[t] = sum(L[a, .] :* L[b, .] :* exp(H[t, .]))
            }
            OUT[a, b] = gvar_quantile(acc, 0.5)
        }
    }
    return(makesymmetric(OUT))
}

// One full SV sweep for one equation: indicators, then h, then the parameters.
// eps is the structural residual; h is updated in place, as is (mu, phi, sg).
void gvar_svsweep(real colvector eps, real colvector h,
                  real scalar mu, real scalar phi, real scalar sg,
                  real scalar bmu, real scalar Bmu, real scalar Bsigma,
                  real scalar a0, real scalar b0)
{
    real matrix P
    real colvector y, r

    P = gvar_svmix()
    // the offset is BGVAR's, and it is not decoration: a single zero residual
    // makes log(0) and one missing then contaminates the whole path
    y = log(eps :* eps :+ 1e-40)
    r = gvar_svind(y, h, P)
    h = gvar_svffbs(y, r, P, mu, phi, sg)
    gvar_svpara(h, bmu, Bmu, Bsigma, a0, b0, mu, phi, sg)
}

// Standalone driver, for the gate: run the sampler on one series and return the
// posterior mean of h stacked over (mu, phi, sigma).
//
// Returns (T+3) x 1 -- T for the path, then THREE parameters.  This comment said
// T+4 and the code appended three, so _test50.do trusted the comment and read a
// fourth element that does not exist: 3301 subscript invalid.  BGVAR's Sv_para
// has four rows because it carries h0 as well; h0 is folded into the stationary
// prior on h_0 here, so only three come back.
real matrix gvar_svrun(real colvector eps, real scalar nsweep, real scalar nburn)
{
    real scalar T, s, mu, phi, sg, nk
    real colvector h, acc, OUT
    real scalar amu, aph, asg

    T   = rows(eps)
    h   = J(T, 1, -3)
    mu  = -1
    phi = 0.9
    sg  = 0.2
    acc = J(T, 1, 0)
    amu = aph = asg = 0
    nk  = 0

    for (s = 1; s <= nsweep; s++) {
        gvar_svsweep(eps, h, mu, phi, sg, 0, 10000, 1, 25, 1.5)
        if (s > nburn) {
            acc = acc + h
            amu = amu + mu
            aph = aph + phi
            asg = asg + sg
            nk  = nk + 1
        }
    }
    if (nk < 1) return(J(T + 4, 1, .))
    OUT = (acc / nk) \ (amu / nk) \ (aph / nk) \ (asg / nk)
    return(OUT)
}

// ---------------------------------------------------------------------------
// Accessors for the posterior.
// ---------------------------------------------------------------------------
real scalar gvar_hasbayes()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.hasbayes)
}

real matrix gvar_getbA(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    return(*gvar_MODEL.bA[i])
}

real matrix gvar_getbL(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    return(*gvar_MODEL.bL[i])
}

real matrix gvar_getbS(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    return(*gvar_MODEL.bS[i])
}

// The SSVS inclusion indicators, one column per kept draw.  Their row mean
// is the posterior inclusion probability: gamma == 1 is the SLAB, because
// draw_bernoulli returns zero with probability p and ast is the SPIKE
// probability.  Reading that the usual way round inverts every PIP.
real matrix gvar_getbG(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    return(*gvar_MODEL.bG[i])
}

// The stochastic-volatility path: (T*M) x ndraws, vectorised column-major from
// the T x M log-variance surface, so colshape(v, T)' rebuilds it.
//
// This is a SEPARATE store from gvar_getbS(), which stays M x ndraws -- one
// number per equation.  _test50.do first checked gvar_getbS for a path and found
// 5 x 100, because the path was never there to find: the accessor did not exist.
// A store with no accessor is not a feature.
real matrix gvar_getbSV(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    if (gvar_MODEL.bsv != 2) return(J(0, 0, .))
    return(*gvar_MODEL.bSV[i])
}

real scalar gvar_getbprior()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.bprior)
}

real matrix gvar_getbY(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    return(*gvar_MODEL.bY[i])
}

real matrix gvar_getbX(real scalar i)
{
    external struct gvarmodel scalar gvar_MODEL

    return(*gvar_MODEL.bX[i])
}

real scalar gvar_getbdraws()
{
    external struct gvarmodel scalar gvar_MODEL

    return(gvar_MODEL.bdraws)
}


// ---------------------------------------------------------------------------
// Run the sampler over every country model and store the draws.
//
// The unit's own lag orders are used: lagord holds (p_i, q_i) per unit, so a
// model specified with p=2, q=1 is sampled with p=2, q=1 rather than with a
// common order imposed for convenience.
// ---------------------------------------------------------------------------
void gvar_bayesrun(real scalar ndraw, real scalar nburn, real scalar nthin,
                   real scalar l1, real scalar l2, real scalar l3,
                   real scalar l4, real scalar prmean,
                   real scalar a1, real scalar b1, real scalar svmode,
                   real scalar prior,
                   real scalar t0, real scalar t1, real scalar pi_,
                   real scalar k0, real scalar k1, real scalar qij,
                   real scalar tau_th, real scalar d_lam,
                   real scalar e_lam, real scalar stau,
                   real scalar hsmode)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix Yraw, Wraw, Vpri, Apri, As, Ls, Ss, Gs, Vs, Y, X
    real colvector sigmas
    real scalar i, N, M, Mstar, plag, plagstar, k, j, cons, trend

    m = gvar_MODEL
    N = m.N

    m.bA = J(N, 1, NULL)
    m.bL = J(N, 1, NULL)
    m.bS = J(N, 1, NULL)
    m.bG = J(N, 1, NULL)
    m.bSV = J(N, 1, NULL)
    m.bY = J(N, 1, NULL)
    m.bX = J(N, 1, NULL)

    cons  = 1
    trend = m.hastrend

    for (i = 1; i <= N; i++) {
        Yraw = *m.Yi[i]
        Wraw = *m.Si[i]
        M     = cols(Yraw)
        Mstar = cols(Wraw)
        plag     = m.lagord[i, 1]
        plagstar = m.lagord[i, 2]

        // the AR(p) residual sd of every series, domestic then star, which is
        // what scales the Minnesota prior across equations (get_ar)
        sigmas = J(M + Mstar, 1, 1)
        for (j = 1; j <= M; j++) {
            sigmas[j] = gvar_bar(Yraw[., j], plag)
        }
        for (j = 1; j <= Mstar; j++) {
            sigmas[M + j] = gvar_bar(Wraw[., j], plagstar)
        }

        k = M * plag + Mstar * (plagstar + 1) + cons + trend

        Vpri = gvar_vmn(k, M, Mstar, plag, plagstar, sigmas,
                        l1, l2, l3, l4, cons, trend)

        // prior mean: prmean on the first own lag, zero elsewhere.  BGVAR
        // writes A_prior.diag() += prmean, which puts it on the leading
        // diagonal of the first lag block.
        Apri = J(k, M, 0)
        for (j = 1; j <= min((M, k)); j++) {
            Apri[j, j] = prmean
        }

        As = Ls = Ss = Gs = Vs = Y = X = J(0, 0, .)
        gvar_brun(Yraw, Wraw, plag, plagstar, cons, trend,
                  ndraw, nburn, nthin, Vpri, Apri, a1, b1, svmode,
                  prior, t0, t1, pi_, k0, k1, qij,
                  tau_th, d_lam, e_lam, stau, hsmode,
                  As, Ls, Ss, Gs, Vs, Y, X)

        m.bA[i]  = &(As[., .])
        m.bL[i]  = &(Ls[., .])
        m.bS[i]  = &(Ss[., .])
        m.bG[i]  = &(Gs[., .])
        m.bSV[i] = &(Vs[., .])
        m.bY[i]  = &(Y[., .])
        m.bX[i]  = &(X[., .])
    }

    m.bdraws  = cols(*m.bA[1])
    m.bburn   = nburn
    m.bthin   = nthin
    m.bprior  = prior
    m.bsv     = svmode
    m.hasbayes = 1
    gvar_MODEL = m
}


// ===========================================================================
// Generalised inverse Gaussian draws  (BGVAR do_rgig1.cpp)
// ===========================================================================
//     f(x)  proportional to  x^(lambda-1) exp(-(chi/x + psi x)/2),   x > 0
//
// BGVAR's do_rgig1.cpp is 55 lines and contains only the degenerate ends; the
// general case is handed to R_GetCCallable("GIGrvg", "do_rgig"), a package
// outside this source tree.  So this is written from the algorithm rather
// than transcribed, which makes it the one routine in section 12 that cannot
// be checked by reading BGVAR.  It is gated on its own moment test instead:
//
//     E[X] = sqrt(chi/psi) * K_{lambda+1}(omega) / K_lambda(omega)
//
// with omega = sqrt(chi*psi).  Nothing downstream should use it until that
// holds, because a subtly wrong GIG draw would show up as a plausible but
// wrong amount of shrinkage and nothing else.
//
// The two special cases ARE transcribed, exactly as the source has them:
//
//     chi small ->  lambda > 0 : rgamma(lambda, 2/psi)
//                   otherwise  : 1/rgamma(-lambda, 2/chi)
//     psi small ->  the same pair
//
// Note the source's psi-small branch returns rgamma(lambda, 2/psi) for
// lambda > 0 -- the chi-small formula, with 2/psi enormous precisely when psi
// is the small quantity.  Both branches carry a "// fixed" comment.  Whether
// that is the intended limit or a copy of the branch above is not decidable
// from the file, so it is reproduced and flagged rather than silently
// "corrected": changing it would change every Normal-Gamma draw in a way no
// output would reveal.
// ---------------------------------------------------------------------------

// The mode of the standardised density x^(lambda-1) exp(-omega(x+1/x)/2).
// The two expressions are algebraically the same root, written so that each
// avoids the cancellation the other suffers.
real scalar gvar_gigmode(real scalar lambda, real scalar omega)
{
    if (lambda >= 1) {
        return((sqrt((lambda - 1) ^ 2 + omega ^ 2) + (lambda - 1)) / omega)
    }
    return(omega / (sqrt((1 - lambda) ^ 2 + omega ^ 2) + (1 - lambda)))
}

// Ratio of uniforms with a mode shift, on the standardised density.
// The acceptance region is bounded by the two real roots of a cubic; fi and
// fak are the trigonometric solution of it.
//
// Returns MISSING when the cubic cannot be solved to usable precision, rather
// than falling back to the mode.  That distinction was a real defect.  As
// omega falls, both
//
//     p ~ -a^2/3    and    q ~ 2a^3/27,      a = -2(lambda+1)/omega
//
// are dominated by the same power of a, so -q/(2 sqrt(-p^3/27)) is a ratio of
// nearly equal huge numbers: it saturates at exactly 1 by omega ~ 1e-4 and
// then lands arbitrarily on either side of it, where acos() is missing.  Every
// guard below was written as "<= 0", and in Mata a missing value is GREATER
// than any number, so a missing sailed through all of them, through the caller,
// out through the Normal-Gamma 1e+7 clamp, and back into sum(V) -- which drove
// the next lambda^2 to zero, which made omega smaller still.  Self-sustaining,
// and every posterior it produced looked reasonable.
//
// Returning the mode would be no better: it is a deterministic value, and
// _test45.do checks that the mode fallback never fires precisely because a
// sampler that returns its mode is not sampling.  The caller switches to
// gvar_giggam() instead.
real scalar gvar_gigrou(real scalar lambda, real scalar omega)
{
    real scalar t, s, xm, nc, a, b, c, p, q, ca, fi, fak, y1, y2
    real scalar uplus, uminus, U, V, X, it

    t  = 0.5 * (lambda - 1)
    s  = 0.25 * omega
    xm = gvar_gigmode(lambda, omega)
    nc = t * log(xm) - s * (xm + 1 / xm)

    a = -(2 * (lambda + 1) / omega + xm)
    b = (2 * (lambda - 1) * xm / omega - 1)
    c = xm

    p = b - a * a / 3
    q = (2 * a * a * a) / 27 - (a * b) / 3 + c

    // p < 0 for every admissible (lambda, omega); if rounding pushes it to
    // zero the cubic has a triple root and the region collapses
    if (missing(p) | missing(q) | p >= 0) return(.)

    ca = -q / (2 * sqrt(-(p * p * p) / 27))

    // the analytic value lies strictly inside [-1,1].  Outside it the
    // cancellation above has eaten the precision; AT the endpoints the two
    // roots the acceptance region needs have already merged.  Both are refusals,
    // not adjustments -- clamping ca to 1 would hand back a collapsed region.
    if (missing(ca) | ca >= 1 | ca <= -1) return(.)

    fi  = acos(ca)
    fak = 2 * sqrt(-p / 3)
    y1  = fak * cos(fi / 3) - a / 3
    y2  = fak * cos(fi / 3 + 4 / 3 * pi()) - a / 3

    if (missing(y1) | missing(y2) | y1 <= 0 | y2 <= 0) return(.)

    uplus  = (y1 - xm) * exp(t * log(y1) - s * (y1 + 1 / y1) - nc)
    uminus = (y2 - xm) * exp(t * log(y2) - s * (y2 + 1 / y2) - nc)

    if (missing(uplus) | missing(uminus) | uplus <= uminus) return(.)

    it = 0
    while (1) {
        it = it + 1
        U = uminus + runiform(1, 1) * (uplus - uminus)
        V = runiform(1, 1)
        X = U / V + xm
        // "X < ." as well as "X > 0": in Mata missing passes X > 0
        if (X > 0 & X < .) {
            if (log(V) <= (t * log(X) - s * (X + 1 / X) - nc)) return(X)
        }
        // a rejection sampler that never accepts is a defect, not a wait
        if (it > 10000) return(.)
    }
}

// The small-omega regime, which the cubic above cannot reach.  The density
// factorises as
//
//     x^(lambda-1) exp(-psi x/2)  .  exp(-chi/(2x))
//
// the first factor being the Gamma(lambda, 2/psi) kernel and the second bounded
// by 1 on x > 0.  So a Gamma draw accepted with probability exp(-chi/(2x)) is
// EXACT: a dominating density, no bounding rectangle, no cubic, no tuning
// constant, nothing to lose precision in.
//
// Its acceptance rate is E[exp(-chi/2X)] under the Gamma, which rises towards 1
// as chi falls -- efficient exactly where the cubic loses precision, and poor
// only for large chi, where the cubic is sound.  The two are complements, which
// is why both are kept rather than one replacing the other.
//
// Note this is NOT the source's degenerate branch widened.  The Gamma LIMIT
// (what the source uses when chi < 11*eps) is 14% wrong at omega = 3e-4 and 73%
// wrong at omega = 0.03, which is most of the region the Normal-Gamma prior
// visits; the rejection step is what makes it exact rather than asymptotic.
//
// Requires lambda > 0.  gvar_rgig() reaches the lambda < 0 case through the
// reciprocal identity before calling this.
real scalar gvar_giggam(real scalar lambda, real scalar chi, real scalar psi)
{
    real scalar x, it

    if (lambda <= 0) return(.)

    for (it = 1; it <= 100000; it++) {
        x = rgamma(1, 1, lambda, 2 / psi)
        if (x > 0 & x < .) {
            if (chi <= 0) return(x)
            if (runiform(1, 1) < exp(-chi / (2 * x))) return(x)
        }
    }
    return(.)
}

// The draw itself.  chi and psi are folded into omega = sqrt(chi*psi) and the
// scale alpha = sqrt(chi/psi), which is the standard reduction: if Z is
// GIG(lambda, omega, omega) then alpha*Z is GIG(lambda, chi, psi).
real scalar gvar_rgig(real scalar lambda, real scalar chi, real scalar psi)
{
    real scalar eps, omega, alpha, res

    eps = 11 * 2.220446049250313e-16

    if (chi < eps) {
        if (lambda > 0) return(rgamma(1, 1, lambda, 2 / psi))
        return(1 / rgamma(1, 1, -lambda, 2 / chi))
    }
    if (psi < eps) {
        // reproduced from the source, including the branch noted above
        if (lambda > 0) return(rgamma(1, 1, lambda, 2 / psi))
        return(1 / rgamma(1, 1, -lambda, 2 / chi))
    }

    omega = sqrt(chi * psi)
    alpha = sqrt(chi / psi)

    // Two regimes, switched on omega.  Below 1 the cubic in gvar_gigrou() is
    // dominated by cancellation and the Gamma-proposal rejection is both exact
    // and efficient; above 1 the ratio-of-uniforms bound is the efficient
    // choice and the Gamma proposal's acceptance rate falls away.  They overlap
    // at omega = 1, which is where _test45.do checks the two against each other
    // and against the closed-form moments.
    //
    // gvar_gigrou() returning missing is a refusal, not a value: fall through
    // to the exact sampler rather than propagate it.  A missing here used to
    // clamp to 1e+7 in the Normal-Gamma hierarchy and never recover.

    // GIG(-lambda, chi, psi) is the reciprocal of GIG(lambda, psi, chi), so a
    // negative shape is handled by drawing the positive one and inverting.
    // That keeps the sampler in the region the ratio-of-uniforms bound was
    // derived for, and it is also what lets gvar_giggam() assume lambda > 0.
    if (lambda < 0) {
        if (omega < 1) return(1 / gvar_giggam(-lambda, psi, chi))
        res = gvar_gigrou(-lambda, omega)
        if (missing(res)) return(1 / gvar_giggam(-lambda, psi, chi))
        return(alpha / res)
    }
    if (omega < 1) return(gvar_giggam(lambda, chi, psi))
    res = gvar_gigrou(lambda, omega)
    if (missing(res)) return(gvar_giggam(lambda, chi, psi))
    return(alpha * res)
}


// ---------------------------------------------------------------------------
// The modified Bessel function of the second kind, K_nu(x).
//
// Needed only to CHECK the GIG sampler, not by the sampler itself.  Stata has
// no besselk() -- besselk(0.5,1) returns rc 133, unknown function -- so the
// integral representation is evaluated directly:
//
//     K_nu(x) = integral_0^inf exp(-x cosh t) cosh(nu t) dt
//
// The integrand decays like exp(-x cosh t), so the tail beyond
// x cosh(T) = 50 contributes less than e^-50.  Simpson on [0, T] with an even
// number of panels is more than enough for a moment check, and the routine is
// validated against the half-integer closed forms, where
//
//     K_{1/2}(x) = sqrt(pi/(2x)) exp(-x)
//
// is exact.  A quadrature used to test a sampler has to be tested itself,
// otherwise the gate just moves.
// ---------------------------------------------------------------------------
real scalar gvar_besselk(real scalar nu, real scalar x)
{
    real scalar T, n, h, s, t, i, f

    if (x <= 0) return(.)

    // upper limit: x*cosh(T) = 50
    if (50 / x >= 1) T = ln(50 / x + sqrt((50 / x) ^ 2 - 1))
    else             T = 0.01
    if (T < 0.5) T = 0.5

    // 800 panels already gives 7e-15 against the exact K_{1/2}; 4000 was
    // four times the work for no gain
    n = 800
    h = T / n
    s = 0
    for (i = 0; i <= n; i++) {
        t = i * h
        f = exp(-x * cosh(t)) * cosh(nu * t)
        if (i == 0 | i == n)      s = s + f
        else if (mod(i, 2) == 1)  s = s + 4 * f
        else                      s = s + 2 * f
    }
    return(s * h / 3)
}


// ---------------------------------------------------------------------------
// Lag-order selection for the weak-exogeneity marginal model.
// ---------------------------------------------------------------------------
// Toolbox select_lags_we.m, called from gvar.m:1730-1748.  The caller loops
// (p, q) over 1..maxls x 1..maxln, records [logl aic sbc p q] per pair, and
// picks the row MAXIMISING the chosen criterion -- info = 2 for AIC, 3 for SBC.
// Both criteria are already "higher is better": AIC_SBC.m:26-28 writes them as
// the log-likelihood MINUS a penalty.
//
// The shipped full demo uses AIC over a maximum of (2,2) -- MAIN row 55 -- and
// the result is visible in output.xls's exogeneity_test sheet: 24 of 26 units
// land on (1,1), arg on (2,1) and chl on (1,2).  chl's q* = 2 exceeds its
// estimation q = 1, which is what proves the demo selected rather than
// inheriting: inheritance cannot produce an order the country model never had.
//
// The regression assembled here is the same one gvar_wetest builds, so the two
// must stay in step.  It is written out again rather than factored because the
// trimming is where these agree or disagree, and a shared helper would hide a
// divergence rather than prevent it.
real rowvector gvar_welag1(real matrix endog, real matrix exog,
                           real matrix exog2, real matrix ecm,
                           real scalar ls, real scalar ln_)
{
    real scalar lagtrim, discr, i, T, n, s
    real matrix dep, ch1, ch2, c1b, c2b, ec, X, B, E, Sg
    real scalar logl, aic, sbc

    dep = gvar_diff(exog)
    dep = dep[2::rows(dep), .]

    ch1 = gvar_diff(endog)
    ch1 = ch1[2::rows(ch1), .]
    c1b = J(rows(ch1), 0, 0)
    for (i = 1; i <= ls; i++) {
        c1b = c1b, gvar_lagm(ch1, i)
    }

    c2b = J(rows(ch1), 0, 0)
    if (cols(exog2) > 0) {
        ch2 = gvar_diff(exog2)
        ch2 = ch2[2::rows(ch2), .]
        for (i = 1; i <= ln_; i++) {
            c2b = c2b, gvar_lagm(ch2, i)
        }
    }

    lagtrim = max((ls, ln_))
    if (cols(c1b) > 0) c1b = gvar_trimr(c1b, lagtrim, 0)
    if (cols(c2b) > 0) c2b = gvar_trimr(c2b, lagtrim, 0)
    dep = gvar_trimr(dep, lagtrim, 0)

    ec = ecm'
    if (lagtrim > 0) ec = gvar_trimr(ec, lagtrim, 0)

    // length(ECM) >= length(dep) in general; trim the regressors to match
    discr = rows(dep) - rows(ec)
    if (discr > 0) {
        if (cols(c1b) > 0) c1b = gvar_trimr(c1b, discr, 0)
        if (cols(c2b) > 0) c2b = gvar_trimr(c2b, discr, 0)
        dep = gvar_trimr(dep, discr, 0)
    }
    if (discr < 0) ec = gvar_trimr(ec, -discr, 0)

    T = rows(dep)
    if (T < 5 | rows(ec) != T) return(J(1, 3, .))

    X = J(T, 1, 1), ec
    if (cols(c1b) > 0) X = X, c1b
    if (cols(c2b) > 0) X = X, c2b
    if (rows(X) != T) return(J(1, 3, .))

    B  = gvar_inv(X' * X) * (X' * dep)
    E  = dep - X * B
    Sg = (E' * E) / T
    n  = cols(dep)
    // s = rank(X), NOT cols(X): AIC_SBC.m:20 uses the rank, so a collinear
    // regressor block is penalised for what it actually spans.
    s  = rank(X)

    logl = (-T * (n / 2)) * (1 + ln(2 * pi())) - (T / 2) * gvar_logdet(Sg)
    aic  = logl - n * s
    sbc  = logl - (n * (s / 2)) * ln(T)
    return((logl, aic, sbc))
}

// Per-unit choice of (ls, ln).  info = 2 AIC, 3 SBC.  Returns N x 2.
real matrix gvar_welagsel(real scalar maxls, real scalar maxln,
                          real scalar info, string colvector WEADD)
{
    external struct gvarmodel scalar gvar_MODEL
    struct gvarmodel scalar m
    real matrix OUT
    real rowvector cr
    real scalar i, N, p, q, best, bp, bq

    m   = gvar_MODEL
    N   = m.N
    OUT = J(N, 2, 1)

    for (i = 1; i <= N; i++) {
        if (m.ksi[i] == 0 | m.rnk[i] == 0) continue
        best = .
        bp   = 1
        bq   = 1
        for (p = 1; p <= maxls; p++) {
            for (q = 1; q <= maxln; q++) {
                // same exog / exog_we distinction as gvar_wetest_all: the
                // marginal model whose lags are being chosen is the one the
                // test will fit, so it must carry the same regressor block
                cr = gvar_welag1(*m.Yi[i], *m.Si[i], gvar_wesi(i, WEADD),
                                 *m.ec[i], p, q)
                if (cr[info] >= .) continue
                // >= not >, so ties keep the LAST (p, q) reached.  That is what
                // gvar.m:1743-1747 does: it re-scans the recorded rows and
                // assigns on "criterion == max", so the highest (p, q) with the
                // maximal value wins.  I first wrote strict > on the grounds
                // that the parsimonious order is the defensible one -- true as
                // statistics, wrong as replication, and chl came out (1,1)
                // against the demo's (1,2).  Reproducing a published table means
                // reproducing its tie-break too.
                if (best >= . | cr[info] >= best) {
                    best = cr[info]
                    bp   = p
                    bq   = q
                }
            }
        }
        OUT[i, 1] = bp
        OUT[i, 2] = bq
    }
    return(OUT)
}

// A compact "unit p,q" listing of the selected orders, for the header line.
// Kept short: 26 units of "arg 2,1" would wrap, so this reports the DISTINCT
// combinations and how many units took each, which is the informative summary.
string scalar gvar_welagshow(real matrix SEL)
{
    external struct gvarmodel scalar gvar_MODEL
    real scalar i, N, a, b, c
    real matrix U
    string scalar s

    N = gvar_MODEL.N
    if (rows(SEL) < N | cols(SEL) < 2) return("(none)")
    U = uniqrows(SEL[1::N, 1::2])
    s = ""
    for (i = 1; i <= rows(U); i++) {
        a = U[i, 1]
        b = U[i, 2]
        c = colsum((SEL[1::N, 1] :== a) :& (SEL[1::N, 2] :== b))
        if (s != "") s = s + ";  "
        s = s + sprintf("(%g,%g) x %g", a, b, c)
    }
    return(s)
}



// ---------------------------------------------------------------------------
// Pesaran, Shin and Smith (2000) 95 per cent critical values for the Johansen
// trace and maximum-eigenvalue statistics with weakly exogenous I(1)
// regressors.  Source: GVAR Toolbox 2.0, Tech/coint_critvalues.xls, as used by
// its get_rank.m.
//
// These used to ship as gvar_cv.dta, which gvar coint located with findfile and
// refused with rc 601 when it was absent.  They are constants, so they belong
// in the code: SSC caps a package description at 100 lines and 26 shipped .dta
// files did not fit that budget.  Holding them here also removes the only hard
// data-file dependency in the package.
//
// WHY 72 SEPARATE APPENDS instead of one literal.  Mata caps the number of
// tokens in a single expression: one v = (648 values) statement fails to
// compile with "too many tokens", r(3000).  Each line below is exactly one
// k-sweep, k = 0..8, for one (dcase, stat, n-r) cell -- so a statement is small
// enough to parse and any transcription slip is confined to a single row of the
// original table.
//
// The table is a FULL factorial -- dcase in (2,3,4) by stat in (1,2) by
// n-r in 1..12 by k in 0..8, which is 648 rows -- so only the values are
// stored and the four index columns are rebuilt in the same nesting order.
// The returned columns are (dcase, stat, nr, k, cv95), the order that
// _gvar_coint.ado's mkmat produced from the dataset.
// ---------------------------------------------------------------------------
real matrix gvar_cvtable()
{
    real rowvector v
    real matrix OUT
    real scalar i, dc, st, nr, k

    v = J(1, 0, .)
    v = v, (9.17, 12.34, 15.28, 18.1, 20.84, 23.51, 26.14, 28.71, 31.27)
    v = v, (20.25, 25.64, 30.82, 35.89, 40.85, 45.74, 50.57, 55.35, 60.09)
    v = v, (35.19, 42.7, 50.03, 57.23, 64.33, 71.38, 78.33, 85.26, 92.14)
    v = v, (54.09, 63.66, 73.08, 82.38, 91.59, 100.71, 109.82, 118.85, 127.83)
    v = v, (76.96, 88.59, 100.08, 111.46, 122.74, 133.95, 145.12, 156.24, 167.31)
    v = v, (103.84, 117.49, 131.02, 144.45, 157.8, 171.08, 184.31, 197.49, 210.58)
    v = v, (134.7, 150.4, 165.98, 181.47, 196.89, 212.21, 227.51, 242.73, 257.9)
    v = v, (169.54, 187.29, 204.9, 222.41, 239.87, 257.24, 274.56, 291.82, 309.04)
    v = v, (208.41, 228.13, 247.79, 267.34, 286.84, 306.26, 325.59, 344.9, 364.15)
    v = v, (251.31, 273.05, 294.71, 316.26, 337.8, 359.23, 380.63, 401.96, 423.27)
    v = v, (298.16, 321.92, 345.56, 369.16, 392.69, 416.14, 439.57, 462.93, 486.27)
    v = v, (348.98, 374.7, 400.43, 426.05, 451.62, 477.11, 502.57, 527.96, 553.33)
    v = v, (9.17, 12.34, 15.28, 18.1, 20.84, 23.51, 26.14, 28.71, 31.27)
    v = v, (15.88, 19.21, 22.35, 25.38, 28.31, 31.18, 34, 36.76, 39.48)
    v = v, (22.3, 25.68, 28.91, 32.04, 35.09, 38.07, 40.98, 43.87, 46.71)
    v = v, (28.58, 31.99, 35.27, 38.46, 41.57, 44.63, 47.63, 50.58, 53.49)
    v = v, (34.8, 38.22, 41.53, 44.75, 47.9, 51.02, 54.07, 57.08, 60.05)
    v = v, (40.95, 44.37, 47.7, 50.97, 54.17, 57.32, 60.42, 63.46, 66.46)
    v = v, (47.06, 50.51, 53.87, 57.14, 60.36, 63.54, 66.65, 69.72, 72.78)
    v = v, (53.15, 56.59, 59.95, 63.25, 66.51, 69.69, 72.85, 75.97, 79.04)
    v = v, (59.26, 62.69, 66.06, 69.38, 72.65, 75.86, 79.04, 82.18, 85.27)
    v = v, (65.3, 68.73, 72.12, 75.43, 78.71, 81.95, 85.15, 88.31, 91.44)
    v = v, (71.33, 74.76, 78.16, 81.5, 84.77, 88.01, 91.23, 94.41, 97.55)
    v = v, (77.35, 80.79, 84.19, 87.52, 90.82, 94.09, 97.31, 100.51, 103.69)
    v = v, (8.19, 11.42, 14.39, 17.23, 19.97, 22.64, 25.27, 27.85, 30.39)
    v = v, (18.11, 23.62, 28.88, 33.98, 38.95, 43.87, 48.72, 53.5, 58.24)
    v = v, (31.88, 39.56, 46.99, 54.27, 61.41, 68.48, 75.46, 82.39, 89.3)
    v = v, (49.64, 59.42, 68.97, 78.34, 87.61, 96.78, 105.91, 114.97, 123.95)
    v = v, (71.44, 83.26, 94.89, 106.36, 117.71, 128.97, 140.19, 151.33, 162.4)
    v = v, (97.26, 111.11, 124.77, 138.3, 151.72, 165.06, 178.33, 191.53, 204.67)
    v = v, (127.05, 142.93, 158.66, 174.26, 189.75, 205.15, 220.48, 235.73, 250.95)
    v = v, (160.87, 178.8, 196.54, 214.15, 231.7, 249.12, 266.49, 283.8, 301.05)
    v = v, (198.72, 218.63, 238.41, 258.04, 277.62, 297.11, 316.49, 335.85, 355.14)
    v = v, (240.58, 262.48, 284.26, 305.92, 327.53, 349.05, 370.49, 391.89, 413.22)
    v = v, (286.39, 310.33, 334.09, 357.78, 381.4, 404.93, 428.42, 451.82, 475.15)
    v = v, (336.22, 362.07, 387.9, 413.63, 439.3, 464.86, 490.33, 515.77, 541.21)
    v = v, (8.19, 11.42, 14.39, 17.23, 19.97, 22.64, 25.27, 27.85, 30.39)
    v = v, (15.02, 18.36, 21.52, 24.54, 27.48, 30.35, 33.17, 35.93, 38.65)
    v = v, (21.49, 24.87, 28.11, 31.24, 34.29, 37.27, 40.17, 43.06, 45.9)
    v = v, (27.8, 31.2, 34.49, 37.67, 40.78, 43.83, 46.84, 49.78, 52.68)
    v = v, (34.03, 37.44, 40.75, 43.98, 47.13, 50.24, 53.29, 56.3, 59.27)
    v = v, (40.19, 43.61, 46.94, 50.2, 53.4, 56.55, 59.65, 62.69, 65.69)
    v = v, (46.31, 49.75, 53.11, 56.38, 59.6, 62.77, 65.88, 68.96, 72)
    v = v, (52.41, 55.84, 59.2, 62.5, 65.75, 68.93, 72.09, 75.21, 78.28)
    v = v, (58.51, 61.94, 65.31, 68.63, 71.89, 75.1, 78.28, 81.42, 84.51)
    v = v, (64.56, 67.99, 71.37, 74.69, 77.97, 81.2, 84.39, 87.56, 90.69)
    v = v, (70.59, 74.03, 77.41, 80.75, 84.03, 87.27, 90.47, 93.65, 96.8)
    v = v, (76.61, 80.06, 83.45, 86.78, 90.08, 93.34, 96.57, 99.76, 102.94)
    v = v, (12.52, 15.46, 18.26, 20.98, 23.63, 26.24, 28.81, 31.35, 33.87)
    v = v, (25.86, 31.05, 36.09, 41.03, 45.9, 50.72, 55.5, 60.22, 64.91)
    v = v, (42.92, 50.25, 57.45, 64.54, 71.56, 78.52, 85.44, 92.29, 99.12)
    v = v, (63.87, 73.31, 82.62, 91.81, 100.96, 110.03, 119.03, 128, 136.94)
    v = v, (88.79, 100.29, 111.69, 122.96, 134.16, 145.3, 156.44, 167.47, 178.46)
    v = v, (117.69, 131.23, 144.66, 158.01, 171.33, 184.53, 197.7, 210.8, 223.88)
    v = v, (150.55, 166.15, 181.67, 197.07, 212.39, 227.68, 242.9, 258.09, 273.21)
    v = v, (187.44, 205.08, 222.61, 240.05, 257.43, 274.77, 292.03, 309.24, 326.43)
    v = v, (228.32, 247.96, 267.54, 287.03, 306.47, 325.83, 345.11, 364.38, 383.59)
    v = v, (273.2, 294.87, 316.45, 337.95, 359.4, 380.79, 402.18, 423.48, 444.75)
    v = v, (322.03, 345.74, 369.31, 392.86, 416.35, 439.78, 463.15, 486.46, 509.74)
    v = v, (374.84, 400.54, 426.17, 451.78, 477.28, 502.72, 528.13, 553.48, 578.84)
    v = v, (12.52, 15.46, 18.26, 20.98, 23.63, 26.24, 28.81, 31.35, 33.87)
    v = v, (19.38, 22.5, 25.5, 28.43, 31.28, 34.09, 36.84, 39.56, 42.24)
    v = v, (25.83, 29.04, 32.15, 35.19, 38.15, 41.08, 43.94, 46.77, 49.56)
    v = v, (32.12, 35.38, 38.55, 41.66, 44.71, 47.7, 50.64, 53.55, 56.42)
    v = v, (38.32, 41.62, 44.84, 47.99, 51.1, 54.14, 57.13, 60.1, 63.03)
    v = v, (44.47, 47.79, 51.06, 54.24, 57.38, 60.47, 63.52, 66.53, 69.5)
    v = v, (50.58, 53.94, 57.21, 60.44, 63.61, 66.72, 69.79, 72.82, 75.85)
    v = v, (56.68, 60.03, 63.33, 66.57, 69.76, 72.89, 76, 79.08, 82.12)
    v = v, (62.75, 66.11, 69.43, 72.69, 75.91, 79.08, 82.21, 85.31, 88.39)
    v = v, (68.81, 72.17, 75.5, 78.77, 82, 85.18, 88.34, 91.47, 94.57)
    v = v, (74.83, 78.21, 81.54, 84.82, 88.07, 91.27, 94.43, 97.61, 100.73)
    v = v, (80.84, 84.23, 87.57, 90.87, 94.13, 97.36, 100.54, 103.7, 106.84)

    if (cols(v) != 648) {
        errprintf("gvar_cvtable: built %g values, expected 648\n", cols(v))
        exit(499)
    }

    OUT = J(648, 5, .)
    i = 0
    for (dc = 2; dc <= 4; dc++) {
        for (st = 1; st <= 2; st++) {
            for (nr = 1; nr <= 12; nr++) {
                for (k = 0; k <= 8; k++) {
                    i++
                    OUT[i, 1] = dc
                    OUT[i, 2] = st
                    OUT[i, 3] = nr
                    OUT[i, 4] = k
                    OUT[i, 5] = v[i]
                }
            }
        }
    }
    return(OUT)
}

end
