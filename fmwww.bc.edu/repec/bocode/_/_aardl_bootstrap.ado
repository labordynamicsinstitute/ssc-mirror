*! _aardl_bootstrap — recursive, null-imposed bootstrap engine for aardl
*! Version 2.0.0 — 2026-08-28
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Implements:
*!   bmethod(mcnown) — McNown, Sam & Goh (2018), Applied Economics, Steps 1-8.
*!                     One restricted y-equation (all lagged levels = 0) whose
*!                     residuals serve all three tests, as prescribed in Step 1:
*!                     "This same set of restrictions applies to the t-tests on
*!                     the lagged level of the dependent variable and the lagged
*!                     level of the independent variable."  Marginal Dx equations
*!                     are UNRESTRICTED and include y(t-1) (their eq. 12).
*!   bmethod(bvz)    — Bertelli, Vacca & Zoia (2022), Economic Modelling 116,
*!                     eqs. (16), (17), (18): a SEPARATE restricted y-equation
*!                     per null hypothesis; marginal VECM eqs. (19)-(20) exclude
*!                     y(t-1) (weak exogeneity of the forcing variables).
*!
*! Both use the recursive DGP  y*(t) = y*(t-1) + Dy*(t),
*! x*(t) = x*(t-1) + Dx*(t)  (MSG Steps 4-5; BVZ eq. 23), with residuals
*! recentred and df-rescaled (MSG Step 2 / BVZ eqs. 21-22) and initial
*! conditions drawn as a contiguous block from the original data (BVZ 5b).

capture program drop _aardl_bootstrap
program define _aardl_bootstrap, rclass
    version 17

    syntax , DEPvar(string)      ///
        XVars(string)            ///
        DETvars(string)          ///
        P(integer)               ///
        QMat(string)             ///
        S0(integer)              ///
        REPS(integer)            ///
        BMEThod(string)          ///
        CASEval(integer)         ///
        VCOde(integer)           ///
        HLag(integer)            ///
        TOUse(varname)           ///
        [ CONScol(integer 0) TRENDcol(integer 0) XDGP(string) ]

    local bvz = ("`bmethod'" == "bvz")
    if "`xdgp'" == "" local xdgp "rw"
    local xrw = ("`xdgp'" == "rw")

    mata: _aardl_bootrun("`depvar'", "`xvars'", "`detvars'", "`touse'", `p', ///
                         "`qmat'", `s0', `reps', `bvz', `conscol', `trendcol', ///
                         `caseval', `vcode', `hlag', `xrw')

    return scalar Fov_obs  = r(Fov_obs)
    return scalar tDV_obs  = r(tDV_obs)
    return scalar Find_obs = r(Find_obs)

    return scalar Fov_bp   = r(Fov_bp)
    return scalar tDV_bp   = r(tDV_bp)
    return scalar Find_bp  = r(Find_bp)

    foreach a in 10 5 1 {
        return scalar Fov_cv`a'  = r(Fov_cv`a')
        return scalar tDV_cv`a'  = r(tDV_cv`a')
        return scalar Find_cv`a' = r(Find_cv`a')
    }
    return scalar nvalid = r(nvalid)
end

// =========================================================================
//                              MATA ENGINE
// =========================================================================
version 17
mata:
// ---- Design matrix of the unrestricted conditional ECM --------------------
real matrix _aardl_W(real colvector y, real matrix X, real matrix D,
                     real colvector dy, real matrix dX,
                     real scalar p, real rowvector qv, real scalar s0)
{
    real scalar T, K, i, j
    real matrix W

    T = rows(y); K = cols(X)
    W = D[|(s0+1),1 \ T,.|]
    W = W , y[|s0 \ (T-1)|]
    W = W , X[|s0,1 \ (T-1),.|]
    for (j=1; j<=p; j++) W = W , dy[|(s0+1-j) \ (T-j)|]
    for (i=1; i<=K; i++) {
        for (j=0; j<=qv[i]; j++) W = W , dX[|(s0+1-j),i \ (T-j),i|]
    }
    return(W)
}

// ---- Design matrix of the marginal (Dx) equations -------------------------
real matrix _aardl_M(real colvector y, real matrix X, real matrix D,
                     real colvector dy, real matrix dX,
                     real scalar pm, real scalar s0, real scalar useylev,
                     real scalar uselev)
{
    real scalar T, K, i, j
    real matrix M

    T = rows(y); K = cols(X)
    M = D[|(s0+1),1 \ T,.|]
    if (uselev) {
        M = M , X[|s0,1 \ (T-1),.|]
        if (useylev) M = M , y[|s0 \ (T-1)|]
    }
    for (j=1; j<=pm; j++) M = M , dy[|(s0+1-j) \ (T-j)|]
    for (j=1; j<=pm; j++) {
        for (i=1; i<=K; i++) M = M , dX[|(s0+1-j),i \ (T-j),i|]
    }
    return(M)
}

// ---- One row of W, rebuilt from the simulated series ----------------------
real rowvector _aardl_wrow(real colvector ys, real matrix xs, real colvector dys,
                           real matrix dxs, real matrix D, real scalar t,
                           real scalar p, real rowvector qv)
{
    real rowvector w
    real scalar i, j, K
    K = cols(xs)
    w = D[t,] , ys[t-1] , xs[t-1,]
    for (j=1; j<=p; j++) w = w , dys[t-j]
    for (i=1; i<=K; i++) {
        for (j=0; j<=qv[i]; j++) w = w , dxs[t-j,i]
    }
    return(w)
}

// ---- One row of M, rebuilt from the simulated series ----------------------
real rowvector _aardl_mrow(real colvector ys, real matrix xs, real colvector dys,
                           real matrix dxs, real matrix D, real scalar t,
                           real scalar pm, real scalar useylev, real scalar uselev)
{
    real rowvector m
    real scalar i, j, K
    K = cols(xs)
    m = D[t,]
    if (uselev) {
        m = m , xs[t-1,]
        if (useylev) m = m , ys[t-1]
    }
    for (j=1; j<=pm; j++) m = m , dys[t-j]
    for (j=1; j<=pm; j++) {
        for (i=1; i<=K; i++) m = m , dxs[t-j,i]
    }
    return(m)
}

// ---- Covariance matrix: 0 = OLS, 1 = HC1 robust, 2 = Newey-West HAC --------
real matrix _aardl_vcov(real matrix W, real colvector e, real matrix XXi,
                        real scalar vcode, real scalar hlag)
{
    real scalar N, k, l, wgt, s2
    real matrix meat, G, Gl

    N = rows(W); k = cols(W)
    if (vcode == 0) {
        s2 = quadcross(e,e)/(N-k)
        return(s2*XXi)
    }
    G = W :* e
    meat = quadcross(G, G)
    if (vcode == 2) {
        for (l=1; l<=hlag; l++) {
            if (l >= N) break
            wgt  = 1 - l/(hlag+1)
            Gl   = quadcross(G[|(l+1),1 \ N,.|], G[|1,1 \ (N-l),.|])
            meat = meat + wgt*(Gl + transposeonly(Gl))
        }
    }
    return(XXi*meat*XXi*(N/(N-k)))
}

// ---- Wald F for an index set ---------------------------------------------
real scalar _aardl_waldF(real colvector b, real matrix V, real colvector idx)
{
    real matrix RVR, IR
    real colvector Rb
    real scalar q

    q   = rows(idx)
    Rb  = b[idx]
    RVR = V[idx, idx]
    IR  = invsym(RVR)
    if (diag0cnt(IR) > 0) return(.)
    return((transposeonly(Rb) * IR * Rb) / q)
}

// ---- Three test statistics from (yv, W) -----------------------------------
real rowvector _aardl_stats(real colvector yv, real matrix W,
                            real colvector ifov, real scalar it,
                            real colvector ifind,
                            real scalar vcode, real scalar hlag)
{
    real matrix XXi, V
    real colvector b, e
    real scalar N, k, tst

    N = rows(W); k = cols(W)
    if (N <= k+2) return((.,.,.))
    XXi = invsym(quadcross(W,W))
    if (diag0cnt(XXi) > 0) return((.,.,.))
    b = XXi*quadcross(W,yv)
    e = yv - W*b
    V = _aardl_vcov(W, e, XXi, vcode, hlag)
    if (V[it,it] <= 0) tst = .
    else               tst = b[it]/sqrt(V[it,it])
    return((_aardl_waldF(b,V,ifov), tst, _aardl_waldF(b,V,ifind)))
}

// ---- Restricted fit: coefficient vector padded with zeros -----------------
real colvector _aardl_restfit(real colvector yv, real matrix W,
                              real colvector drop, real colvector resid)
{
    real colvector keep, b, br, sel, r
    real scalar k, j, N, kr
    real matrix Wr, XXi

    k = cols(W); N = rows(W)
    sel = J(k,1,1)
    if (rows(drop) > 0) sel[drop] = J(rows(drop),1,0)
    keep = select((1::k), sel)
    Wr   = W[., keep]
    kr   = cols(Wr)
    XXi  = invsym(quadcross(Wr,Wr))
    br   = XXi*quadcross(Wr,yv)
    r    = yv - Wr*br
    // recentre and df-rescale (MSG Step 2; BVZ eqs. 21-22)
    r = (r :- mean(r)) * sqrt(N/(N-kr))
    resid[.] = r
    b = J(k,1,0)
    for (j=1; j<=kr; j++) b[keep[j]] = br[j]
    return(b)
}

// ---- Empirical bootstrap critical values (MSG eqs. 15-16; BVZ 24-25) ------
real scalar _aardl_cvupper(real colvector s, real scalar alpha)
{
    real scalar B, j
    B = rows(s)
    if (B < 3) return(.)
    j = ceil((1-alpha)*B)
    if (j < 1) j = 1
    if (j > B) j = B
    return(s[j])
}
real scalar _aardl_cvlower(real colvector s, real scalar alpha)
{
    real scalar B, j
    B = rows(s)
    if (B < 3) return(.)
    j = floor(alpha*B) + 1
    if (j < 1) j = 1
    if (j > B) j = B
    return(s[j])
}

// ---- Main driver ----------------------------------------------------------
void _aardl_bootrun(string scalar yn, string scalar xn, string scalar dn,
                    string scalar tousen,
                    real scalar p, string scalar qn, real scalar s0,
                    real scalar B, real scalar bvz,
                    real scalar conscol, real scalar trendcol,
                    real scalar caseno, real scalar vcode, real scalar hlag,
                    real scalar xrw)
{
    real colvector y, dy, yv, ifov, ifind, ys, dys, bfull, resid, jidx, cl, sc, nub
    real matrix X, D, dX, W, M, xs, dxs, eps, bm, byn, boot, epsb, nu
    real rowvector qv, obs, st, wrow, mrow
    real scalar T, K, nd, N, i, t, b, it, ic, nn, r, useylev, pm, nnull, s
    real scalar kk, nvalid
    string scalar nm

    y  = st_data(., yn,        tousen)
    X  = st_data(., tokens(xn), tousen)
    D  = st_data(., tokens(dn), tousen)
    qv = st_matrix(qn)

    T = rows(y); K = cols(X); nd = cols(D)
    N = T - s0

    dy = J(T,1,0); dy[|2 \ T|] = y[|2 \ T|] - y[|1 \ (T-1)|]
    dX = J(T,K,0); dX[|2,1 \ T,.|] = X[|2,1 \ T,.|] - X[|1,1 \ (T-1),.|]

    W  = _aardl_W(y, X, D, dy, dX, p, qv, s0)
    yv = dy[|(s0+1) \ T|]
    kk = cols(W)

    // ---- restriction index sets ------------------------------------------
    it    = nd + 1                                  // L.y
    ifind = (nd+2 :: nd+1+K)                        // L.x
    ifov  = (nd+1 :: nd+1+K)                        // L.y and L.x
    if (caseno == 2 & conscol  > 0) ifov = ifov \ conscol
    if (caseno == 4 & trendcol > 0) ifov = ifov \ trendcol
    ifov = sort(ifov, 1)

    // ---- observed statistics ---------------------------------------------
    obs = _aardl_stats(yv, W, ifov, it, ifind, vcode, hlag)
    st_numscalar("r(Fov_obs)",  obs[1])
    st_numscalar("r(tDV_obs)",  obs[2])
    st_numscalar("r(Find_obs)", obs[3])

    // ---- restricted y-equations (one per null for BVZ, one for MSG) ------
    nnull = (bvz ? 3 : 1)
    byn   = J(kk, nnull, 0)
    nu    = J(N, nnull, 0)
    resid = J(N, 1, 0)
    for (s=1; s<=nnull; s++) {
        if (s == 1)      byn[.,s] = _aardl_restfit(yv, W, ifov,  resid)
        else if (s == 2) byn[.,s] = _aardl_restfit(yv, W, J(1,1,it), resid)
        else             byn[.,s] = _aardl_restfit(yv, W, ifind, resid)
        nu[.,s] = resid
    }

    // ---- marginal equations for Dx ---------------------------------------
    useylev = (bvz ? 0 : 1)      // BVZ eq.(20) excludes y(t-1); MSG eq.(12) keeps it
    pm = p
    M  = _aardl_M(y, X, D, dy, dX, pm, s0, useylev, 1 - xrw)
    bm  = J(cols(M), K, 0)
    eps = J(N, K, 0)
    for (i=1; i<=K; i++) {
        bm[.,i]  = _aardl_restfit(dX[|(s0+1),i \ T,i|], M, J(0,1,.), resid)
        eps[.,i] = resid
    }

    // ---- bootstrap loop ---------------------------------------------------
    boot = J(B, 3, .)
    for (b=1; b<=B; b++) {
        for (s=1; s<=nnull; s++) {

            jidx = ceil(runiform(N,1):*N)
            nub  = nu[jidx, s]
            epsb = eps[jidx, .]
            nub  = nub :- mean(nub)                        // BVZ eq.(21)
            epsb = epsb :- (J(N,1,1)*mean(epsb))           // BVZ eq.(22)

            // initial block drawn from the original data (BVZ step 5b)
            r = ceil(runiform(1,1)*(T-s0))
            if (r < 1) r = 1
            ys  = J(T,1,0);  xs  = J(T,K,0)
            dys = J(T,1,0);  dxs = J(T,K,0)
            ys[|1 \ s0|]      = y[|r \ (r+s0-1)|]
            xs[|1,1 \ s0,.|]  = X[|r,1 \ (r+s0-1),.|]
            dys[|2 \ s0|]     = ys[|2 \ s0|] - ys[|1 \ (s0-1)|]
            dxs[|2,1 \ s0,.|] = xs[|2,1 \ s0,.|] - xs[|1,1 \ (s0-1),.|]

            bfull = byn[.,s]
            for (t=s0+1; t<=T; t++) {
                nn   = t - s0
                mrow = _aardl_mrow(ys, xs, dys, dxs, D, t, pm, useylev, 1 - xrw)
                for (i=1; i<=K; i++) dxs[t,i] = mrow*bm[.,i] + epsb[nn,i]
                xs[t,] = xs[t-1,] + dxs[t,]
                wrow   = _aardl_wrow(ys, xs, dys, dxs, D, t, p, qv)
                dys[t] = wrow*bfull + nub[nn]
                ys[t]  = ys[t-1] + dys[t]
            }

            st = _aardl_stats(dys[|(s0+1) \ T|],
                              _aardl_W(ys, xs, D, dys, dxs, p, qv, s0),
                              ifov, it, ifind, vcode, hlag)

            if (bvz) boot[b,s] = st[s]
            else     boot[b,.] = st
        }
    }

    // ---- critical values and p-values ------------------------------------
    st_matrix("_aardl_bootdist", boot)
    nvalid = 0
    for (ic=1; ic<=3; ic++) {
        cl = boot[.,ic]
        sc = sort(select(cl, cl :< .), 1)
        nn = rows(sc)
        if (ic == 1) nvalid = nn
        if (ic == 2) {
            st_numscalar("r(tDV_cv10)", _aardl_cvlower(sc, 0.10))
            st_numscalar("r(tDV_cv5)",  _aardl_cvlower(sc, 0.05))
            st_numscalar("r(tDV_cv1)",  _aardl_cvlower(sc, 0.01))
            st_numscalar("r(tDV_bp)",   (nn>0 ? mean(sc :<= obs[2]) : .))
        }
        else {
            nm = (ic == 1 ? "Fov" : "Find")
            st_numscalar("r("+nm+"_cv10)", _aardl_cvupper(sc, 0.10))
            st_numscalar("r("+nm+"_cv5)",  _aardl_cvupper(sc, 0.05))
            st_numscalar("r("+nm+"_cv1)",  _aardl_cvupper(sc, 0.01))
            st_numscalar("r("+nm+"_bp)",   (nn>0 ? mean(sc :>= obs[ic]) : .))
        }
    }
    st_numscalar("r(nvalid)", nvalid)
}
end
