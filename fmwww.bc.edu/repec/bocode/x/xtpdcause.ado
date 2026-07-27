*! xtpdcause 1.0.0  23jul2026
*! Panel Granger non-causality tests robust to cross-sectional dependence
*! Lag-augmented VAR (Toda-Yamamoto) with PANIC / PANIC-CA factor correction
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program xtpdcause, rclass
    version 14.0
    syntax varlist(min=2 max=2) [if] [in] , [ METHOD(string) ///
        Pmax(integer 4) Dmax(integer 1) IC(integer 2) Kmax(integer 3) ]

    gettoken yv xv : varlist
    if ("`method'"=="") local method "panic"
    local method = strlower("`method'")
    if !inlist("`method'","none","panic","panicca") {
        di as error "method() must be none, panic or panicca"
        exit 198
    }
    if `ic'!=1 & `ic'!=2 {
        di as error "ic() must be 1 (AIC) or 2 (BIC)"
        exit 198
    }

    // ---- panel structure --------------------------------------------
    _xt, treq
    local id "`r(ivar)'"
    local tv "`r(tvar)'"
    marksample touse
    markout `touse' `yv' `xv'
    qui xtset
    if "`r(balanced)'"!="strongly balanced" {
        di as error "xtpdcause requires a strongly balanced panel"
        exit 451
    }
    tempvar tag
    qui by `id': gen byte `tag' = _n==1 if `touse'
    qui count if `tag'
    local N = r(N)
    qui count if `touse'
    local T = r(N)/`N'
    if `T'*`N' != r(N) {
        di as error "panel is not balanced over the estimation sample"
        exit 451
    }

    // ---- dispatch to Mata -------------------------------------------
    tempname OUT STAT
    mata: _pdc_run("`yv'","`xv'","`touse'", `N', `T', "`method'", ///
        `pmax', `dmax', `ic', `kmax', "`OUT'", "`STAT'")

    // ---- header + table ---------------------------------------------
    local mlab = cond("`method'"=="panic","PANIC (PCA factors)", ///
        cond("`method'"=="panicca","PANIC-CA (cross-section averages)","LA-VAR (no factor correction)"))
    di ""
    di as txt "Panel Granger non-causality test" _col(72) "N = " as res %5.0f `N'
    di as txt "H0: {res:`xv'}{txt} does not Granger-cause {res:`yv'}{txt} (in any panel)" ///
        _col(72) "T = " as res %5.0f `T'
    di as txt "CSD correction: " as res "`mlab'"
    if inlist("`method'","panic","panicca") ///
        di as txt "Common factors removed: " as res %2.0f `STAT'[1,5]
    di as txt "{hline 66}"
    di as txt %5s "unit" _col(12) "Wald" _col(24) "p-value" _col(36) "Holm p" _col(50) "lag"
    di as txt "{hline 66}"
    forvalues i = 1/`N' {
        di as res %5.0f `OUT'[`i',1] _col(9) %9.3f `OUT'[`i',2] ///
            _col(21) %9.3f `OUT'[`i',3] _col(33) %9.3f `OUT'[`i',4] _col(49) %3.0f `OUT'[`i',5]
    }
    di as txt "{hline 66}"
    di as txt "Fisher P (chi2, " as res %3.0f 2*`N' as txt " df)" _col(40) as res %9.3f `STAT'[1,1] ///
        as txt "   p = " as res %6.3f `STAT'[1,2]
    di as txt "Pm (standardized)" _col(40) as res %9.3f `STAT'[1,3] ///
        as txt "   p = " as res %6.3f `STAT'[1,4]
    di as txt "{hline 66}"
    di as txt "Reject H0 (=> `xv' Granger-causes `yv') for large P/Pm."

    // ---- returns -----------------------------------------------------
    return scalar P     = `STAT'[1,1]
    return scalar P_p   = `STAT'[1,2]
    return scalar Pm    = `STAT'[1,3]
    return scalar Pm_p  = `STAT'[1,4]
    if inlist("`method'","panic","panicca") return scalar nf = `STAT'[1,5]
    return matrix units = `OUT'
    return local method "`method'"
    return local cause  "`xv'"
    return local depvar "`yv'"
    return local cmd    "xtpdcause"
    return scalar N = `N'
    return scalar T = `T'
end

version 14.0
mata:

// column-stack the two variables country-major: rows (i-1)*T+1..i*T = unit i
real matrix _pdc_data(string scalar yv, string scalar xv, string scalar touse,
    real scalar N, real scalar T)
{
    real matrix D
    D = st_data(., (yv, xv), touse)   // already sorted id-major by xtset
    return(D)
}
real colvector _pdc_lagn(real colvector x, real scalar n)
{
    real scalar r
    r = rows(x)
    if (n >= 0) return((J(n,1,0) \ x[1..r-n]))
    return((x[(1-n)..r] \ J(-n,1,0)))
}
// build (ya, yl): p lags of each column of y, columns ordered var1 lags1..p, var2 lags1..p
void _pdc_lagp(real matrix y, real scalar p, real matrix ya, real matrix yl)
{
    real scalar nk, i, j, r
    real matrix ylag
    nk = cols(y)
    r  = rows(y)
    ylag = J(r, nk*p, 0)
    i = 1
    while (i <= nk) {
        j = 1
        while (j <= p) {
            ylag[.,j+p*(i-1)] = _pdc_lagn(y[.,i], j)
            j = j + 1
        }
        i = i + 1
    }
    ya = y[(p+1)..r,.]
    yl = ylag[(p+1)..r,.]
}
// VAR information criterion (with intercept), matches _get_icvalue
real rowvector _pdc_ic(real matrix dep, real matrix z, real scalar p)
{
    real matrix b, e, vc
    real scalar t, nk, aic, sbc
    t = rows(dep)
    b = invsym(cross(z,z))*cross(z,dep)
    e = dep - z*b
    vc = cross(e,e)/t
    nk = cols(dep)
    aic = ln(det(vc)) + (2/t)*(nk*nk*p+nk) + nk*(1+ln(2*pi()))
    sbc = ln(det(vc)) + (1/t)*(nk*nk*p+nk)*ln(t) + nk*(1+ln(2*pi()))
    return((aic, sbc))
}
real scalar _pdc_getp(real matrix y, real scalar pmax, real scalar ic)
{
    real colvector aicp, sbcp
    real matrix ya, yl, z
    real rowvector v
    real scalar p, t
    aicp = J(pmax,1,0)
    sbcp = J(pmax,1,0)
    p = 1
    while (p <= pmax) {
        _pdc_lagp(y, p, ya, yl)
        t = rows(ya)
        z = yl , J(t,1,1)
        v = _pdc_ic(ya, z, p)
        aicp[p] = v[1]
        sbcp[p] = v[2]
        p = p + 1
    }
    if (ic==1) return(_pdc_argmin(aicp))
    return(_pdc_argmin(sbcp))
}
real scalar _pdc_argmin(real colvector v)
{
    real scalar i, im, mn
    mn = v[1]
    im = 1
    i = 2
    while (i <= rows(v)) {
        if (v[i] < mn) {
            mn = v[i]
            im = i
        }
        i = i + 1
    }
    return(im)
}
// lag-augmented VAR Wald for "var2 does not cause var1" (Toda-Yamamoto)
real scalar _pdc_wald(real matrix VARy, real matrix z, real scalar p, real scalar dmax)
{
    real matrix b, u, Su, zr, br, ur, Sr
    real scalar t, rssr, rssur, df, F, W, q
    t = rows(VARy) + p + dmax
    b = invsym(cross(z,z))*cross(z,VARy)
    u = VARy - z*b
    Su = cross(u,u)
    q = p + dmax
    if (dmax >= 1) zr = z[.,1..q] , z[.,(2*q)..cols(z)]
    else           zr = z[.,1..p] , z[.,(2*p+1)..cols(z)]
    br = invsym(cross(zr,zr))*cross(zr,VARy)
    ur = VARy - zr*br
    Sr = cross(ur,ur)
    rssr = Sr[1,1]
    rssur = Su[1,1]
    df = t - cols(z) - p - dmax
    F = ((rssr-rssur)/p)/(rssur/df)
    W = F*p
    return(W)
}
// LA-VAR Fisher across the panel; returns per-unit (Wald, pval, lag)
real matrix _pdc_lavar(real matrix data, real scalar T, real scalar N,
    real scalar pmax, real scalar dmax, real scalar ic, real scalar cons)
{
    real matrix out, y_i, ya, yl, z
    real scalar i, p, W
    out = J(N,3,0)
    i = 1
    while (i <= N) {
        y_i = data[((i-1)*T+1)..(i*T),.]
        p = _pdc_getp(y_i, pmax, ic)
        _pdc_lagp(y_i, p+dmax, ya, yl)
        if (cons) z = yl , J(rows(yl),1,1)
        else      z = yl
        W = _pdc_wald(ya, z, p, dmax)
        out[i,1] = W
        out[i,2] = chi2tail(p, W)
        out[i,3] = p
        i = i + 1
    }
    return(out)
}
// Bai-Ng (2002) IC2 number of factors on x (T x n)
real scalar _pdc_fnumber(real matrix x, real scalar kmax)
{
    real matrix vx, xc
    real colvector s, v0, ic2, ks
    real scalar t, n, c, ti
    t = rows(x)
    n = cols(x)
    xc = x :- mean(x)          // local copy: do NOT modify caller's matrix
    vx = cross(xc,xc)/(t*n)
    s = symeigenvalues(vx)'      // eigenvalues, descending (n x 1)
    v0 = J(kmax+1,1,0)
    ti = 1
    while (ti <= kmax+1) {
        v0[ti] = sum(s[ti..rows(s)])
        ti = ti + 1
    }
    c = min((sqrt(n), sqrt(t)))
    ks = (0::kmax)
    ic2 = ln(v0) :+ ks:*((n+t)/(n*t))*ln(c^2)
    return(_pdc_argmin(ic2) - 1)
}
// PCA (Bai-Ng) returning Fhat (T x nf) and lambda (n x nf)
void _pdc_pca(real matrix X, real scalar nf, real matrix Fhat, real matrix lambda)
{
    real matrix vecs
    real colvector vals, idx
    real scalar t, n
    t = rows(X)
    n = cols(X)
    if (t < n) {
        symeigensystem(cross(X',X'), vecs, vals)
        idx = _pdc_topidx(vals', nf)
        Fhat = sqrt(t)*vecs[.,idx]
        lambda = cross(X, Fhat)/t
    }
    else {
        symeigensystem(cross(X,X), vecs, vals)
        idx = _pdc_topidx(vals', nf)
        lambda = sqrt(n)*vecs[.,idx]
        Fhat = X*lambda/n
    }
}
real colvector _pdc_topidx(real colvector vals, real scalar nf)
{
    real colvector o
    o = order(vals, -1)          // descending eigenvalue order
    return(o[1..nf])
}
real matrix _pdc_cumsum(real matrix X)
{
    real matrix C
    real scalar j
    C = X
    j = 1
    while (j <= cols(X)) {
        C[.,j] = runningsum(X[.,j])
        j = j + 1
    }
    return(C)
}
// stack a (T-1) x N de-factored block into a ((T-1)*N) x 1 country-major vector
real colvector _pdc_stack(real matrix M, real scalar Tm1, real scalar N)
{
    real colvector v
    real scalar i
    v = J(Tm1*N,1,0)
    i = 1
    while (i <= N) {
        v[((i-1)*Tm1+1)..(i*Tm1)] = M[.,i]
        i = i + 1
    }
    return(v)
}
// build the standardized first-differenced (T-1) x 2N matrix
real matrix _pdc_diffstd(real matrix data, real scalar T, real scalar N)
{
    real matrix dy, yi, dyi
    real scalar i, j, sd
    dy = J(T-1, 2*N, 0)
    j = 1
    while (j <= 2) {
        i = 1
        while (i <= N) {
            yi = data[((i-1)*T+1)..(i*T), j]
            dyi = yi[2..T] - yi[1..T-1]
            sd = sqrt(variance(dyi))
            dy[., N*(j-1)+i] = dyi/sd
            i = i + 1
        }
        j = j + 1
    }
    return(dy)
}
real matrix _pdc_holm(real colvector pval)
{
    real matrix idp, sp, sap
    real colvector padj
    real scalar N, j
    N = rows(pval)
    idp = (1::N), pval
    sp = sort(idp, 2)
    padj = J(N,1,0)
    j = 1
    while (j <= N) {
        padj[j] = (N-j+1)*sp[j,2]
        if (j != 1) {
            if (padj[j-1] > 0.05 & padj[j] < padj[j-1]) {
                if (padj[j-1] < 1) padj[j] = padj[j-1]
                else padj[j] = 1
            }
            else {
                if (padj[j] > 1) padj[j] = 1
            }
        }
        j = j + 1
    }
    sap = sort((sp[.,1], padj), 1)
    return(sap[.,2])
}

// ---------- driver ---------------------------------------------------
void _pdc_run(string scalar yv, string scalar xv, string scalar touse,
    real scalar N, real scalar T, string scalar method, real scalar pmax,
    real scalar dmax, real scalar ic, real scalar kmax,
    string scalar outname, string scalar statname)
{
    real matrix data, dy, Fhat, lambda, m1, m2, lav, out
    real colvector y1, y2, Fp, Ci, pval
    real scalar nf, P, Pm, Ppv, Pmpv, Tm1
    data = _pdc_data(yv, xv, touse, N, T)
    nf = 0
    if (method=="none") {
        lav = _pdc_lavar(data, T, N, pmax, dmax, ic, 1)
    }
    else {
        dy = _pdc_diffstd(data, T, N)
        Tm1 = T - 1
        if (method=="panic") {
            nf = _pdc_fnumber(dy, kmax)
            _pdc_pca(dy, nf, Fhat, lambda)
            m1 = _pdc_cumsum(dy[.,1..N] - Fhat*lambda[1..N,.]')
            m2 = _pdc_cumsum(dy[.,(N+1)..(2*N)] - Fhat*lambda[(N+1)..(2*N),.]')
        }
        else {
            Fp = mean(dy')'                       // (T-1) x 1 cross-section average
            Ci = (invsym(cross(Fp,Fp))*cross(Fp,dy))'   // (2N) x 1 loadings
            m1 = _pdc_cumsum(dy[.,1..N] - Fp*Ci[1..N]')
            m2 = _pdc_cumsum(dy[.,(N+1)..(2*N)] - Fp*Ci[(N+1)..(2*N)]')
            nf = 1
        }
        y1 = _pdc_stack(m1, Tm1, N)
        y2 = _pdc_stack(m2, Tm1, N)
        lav = _pdc_lavar((y1, y2), Tm1, N, pmax, dmax, ic, 0)
    }
    pval = lav[.,2]
    P    = -2*sum(ln(pval))
    Pm   = (P - 2*N)/sqrt(4*N)
    Ppv  = chi2tail(2*N, P)
    Pmpv = 1 - normal(Pm)
    out = (1::N), lav[.,1], pval, _pdc_holm(pval), lav[.,3]
    st_matrix(outname, out)
    st_matrixcolstripe(outname, (J(5,1,""), ("id","Wald","pval","Holm_p","lag")'))
    st_matrix(statname, (P, Ppv, Pm, Pmpv, nf))
}

end
