*! tnardlldiag version 1.0.0  03jun2026
*! Residual diagnostics for tnardll (threshold ARDL).
*!
*! Computes, on the unrestricted-ECM residuals of the fitted tnardll model:
*!   1. Breusch-Godfrey LM test for serial correlation (up to bglags()).
*!   2. Engle ARCH-LM test and a Breusch-Pagan heteroskedasticity test.
*!   3. Jarque-Bera normality test (with skewness and kurtosis).
*!   4. Ramsey RESET functional-form test (powers 2..resetpow() of the fit).
*! The design matrix is rebuilt from the stored thresholds, so the residuals
*! reproduce the estimator exactly.

program define tnardlldiag, rclass
    version 17.0

    if "`e(cmd)'" != "tnardll" {
        di as err "tnardlldiag only works after tnardll"
        exit 301
    }

    syntax [, BGlags(integer 4) ARCHlags(integer 4) RESETpow(integer 3) ]

    if `bglags' < 1 {
        di as err "bglags() must be a positive integer"
        exit 198
    }
    if `archlags' < 1 {
        di as err "archlags() must be a positive integer"
        exit 198
    }
    if `resetpow' < 2 {
        di as err "resetpow() must be at least 2"
        exit 198
    }

    marksample touse, novarlist
    qui replace `touse' = 0 if !e(sample)

    * constant / trend flags from coefficient names
    local bn : colnames e(b)
    local consf = `: list posof "_cons" in bn' > 0
    local trf   = `: list posof "trend" in bn' > 0

    mata: _tnardll_diag(`bglags', `archlags', `resetpow', `consf', `trf')

    * ---------------- table ----------------
    di ""
    di as txt "Residual diagnostics for tnardll (D.`e(depvar)')"
    di as txt "{hline 72}"
    di as txt "  Serial correlation -- Breusch-Godfrey LM (H0: no autocorrelation)"
    di as txt "      chi2(" as res %2.0f __bg_df as txt ") = " ///
        as res %9.3f __bg_lm as txt "   Prob > chi2 = " as res %6.4f __bg_p ///
        as txt "   [lags = " as res %1.0f __bg_df as txt "]"
    di as txt "  Heteroskedasticity -- Engle ARCH-LM (H0: no ARCH)"
    di as txt "      chi2(" as res %2.0f __arch_df as txt ") = " ///
        as res %9.3f __arch_lm as txt "   Prob > chi2 = " as res %6.4f __arch_p ///
        as txt "   [lags = " as res %1.0f __arch_df as txt "]"
    di as txt "  Heteroskedasticity -- Breusch-Pagan (H0: homoskedastic)"
    di as txt "      chi2(" as res %2.0f __bp_df as txt ") = " ///
        as res %9.3f __bp_lm as txt "   Prob > chi2 = " as res %6.4f __bp_p
    di as txt "  Normality -- Jarque-Bera (H0: normal errors)"
    di as txt "      chi2(2) = " as res %9.3f __jb as txt ///
        "   Prob > chi2 = " as res %6.4f __jb_p
    di as txt "      skewness = " as res %7.4f __skew ///
        as txt "   kurtosis = " as res %7.4f __kurt
    di as txt "  Functional form -- Ramsey RESET (H0: no omitted nonlinearity)"
    di as txt "      F(" as res %2.0f __reset_df1 as txt "," ///
        as res %5.0f __reset_df2 as txt ") = " as res %9.3f __reset_f ///
        as txt "   Prob > F = " as res %6.4f __reset_p ///
        as txt "   [powers 2.." as res %1.0f `resetpow' as txt "]"
    di as txt "{hline 72}"

    * ---------------- returns ----------------
    return scalar reset_p   = __reset_p
    return scalar reset_df2 = __reset_df2
    return scalar reset_df1 = __reset_df1
    return scalar reset_F   = __reset_f
    return scalar kurtosis  = __kurt
    return scalar skewness  = __skew
    return scalar jb_p      = __jb_p
    return scalar jb        = __jb
    return scalar bp_p      = __bp_p
    return scalar bp_df     = __bp_df
    return scalar bp        = __bp_lm
    return scalar arch_p    = __arch_p
    return scalar arch_df   = __arch_df
    return scalar arch      = __arch_lm
    return scalar bg_p      = __bg_p
    return scalar bg_df     = __bg_df
    return scalar bg        = __bg_lm
end

version 17.0
mata:
mata set matastrict off

// Mata functions defined in an ado-file's trailing mata block are PRIVATE to
// that ado; they are not shared across ado files.  tnardlldiag therefore carries
// its own copies of the design-builder _tn_design() and its helpers, kept
// byte-for-byte identical to the definitions in tnardll.ado.
struct tndes {
    real colvector dyv
    real matrix    X
    real colvector keep
    real scalar    S, m, p, q, irho
    real rowvector ilr_xT, ilr_w, iphi
    real matrix    ipi
}

real colvector _tn_lag(real colvector v, real scalar k)
{
    real scalar n
    n = rows(v)
    if (k <= 0) return(v)
    if (k >= n) return(J(n,1,.))
    return( J(k,1,.) \ v[|1 \ n-k|] )
}

real colvector _tn_cumsum(real colvector v)
{
    real scalar i, n
    real colvector c
    n = rows(v)
    c = J(n,1,0)
    if (n == 0) return(c)
    c[1] = (v[1]==. ? 0 : v[1])
    for (i=2; i<=n; i++) c[i] = c[i-1] + (v[i]==. ? 0 : v[i])
    return(c)
}

real matrix _tn_seg(real colvector dx, real rowvector tau)
{
    real scalar n, S, t, s
    real matrix seg
    n = rows(dx)
    S = cols(tau) + 1
    seg = J(n, S, 0)
    for (t=1; t<=n; t++) {
        if (dx[t]==.) continue
        if (S==1) {
            seg[t,1] = dx[t]
            continue
        }
        if (dx[t] <= tau[1]) {
            seg[t,1] = dx[t]
        }
        else if (dx[t] > tau[S-1]) {
            seg[t,S] = dx[t]
        }
        else {
            for (s=2; s<=S-1; s++) {
                if (dx[t] > tau[s-1] && dx[t] <= tau[s]) seg[t,s] = dx[t]
            }
        }
    }
    return(seg)
}

struct tndes scalar _tn_design(real colvector y, real colvector xT,
        real matrix W, real scalar p, real scalar q,
        real rowvector tau, real scalar consf, real scalar trf)
{
    struct tndes scalar d
    real scalar n, S, m, s, j, jj, col
    real colvector dy, dx, dw
    real matrix seg, xseg, X, M

    n = rows(y)
    S = cols(tau) + 1
    m = cols(W)
    dy = y - _tn_lag(y,1)
    dx = xT - _tn_lag(xT,1)
    seg  = _tn_seg(dx, tau)
    xseg = J(n,S,0)
    for (s=1; s<=S; s++) xseg[.,s] = _tn_cumsum(seg[.,s])

    X = J(n,0,.)
    col = 0
    X = _tn_lag(y,1)
    col = 1
    d.irho = 1
    d.ilr_xT = J(1,S,0)
    for (s=1; s<=S; s++) {
        X = X, _tn_lag(xseg[.,s],1)
        col++
        d.ilr_xT[s] = col
    }
    d.ilr_w = (m>0 ? J(1,m,0) : J(1,0,0))
    for (j=1; j<=m; j++) {
        X = X, _tn_lag(W[.,j],1)
        col++
        d.ilr_w[j] = col
    }
    d.iphi = (p>1 ? J(1,p-1,0) : J(1,0,0))
    for (j=1; j<=p-1; j++) {
        X = X, _tn_lag(dy,j)
        col++
        d.iphi[j] = col
    }
    d.ipi = J(S,q,0)
    for (s=1; s<=S; s++) {
        for (j=0; j<=q-1; j++) {
            X = X, _tn_lag(seg[.,s],j)
            col++
            d.ipi[s,j+1] = col
        }
    }
    for (jj=1; jj<=m; jj++) {
        dw = W[.,jj] - _tn_lag(W[.,jj],1)
        for (j=0; j<=q-1; j++) {
            X = X, _tn_lag(dw,j)
            col++
        }
    }
    if (trf) {
        X = X, (1::n)
        col++
    }
    if (consf) {
        X = X, J(n,1,1)
        col++
    }

    M = dy, X
    d.keep = selectindex(rowmissing(M):==0)
    d.dyv = dy[d.keep]
    d.X   = X[d.keep, .]
    d.S = S; d.m = m; d.p = p; d.q = q
    return(d)
}

// centered R^2 of an auxiliary OLS regression
real scalar _tn_auxr2(real colvector yv, real matrix Xr)
{
    real colvector bb, ee
    real scalar rss, tss, yb
    bb  = invsym(cross(Xr,Xr)) * cross(Xr,yv)
    ee  = yv - Xr*bb
    rss = cross(ee,ee)
    yb  = mean(yv)
    tss = cross(yv:-yb, yv:-yb)
    if (tss <= 0) return(0)
    return(1 - rss/tss)
}

void _tnardll_diag(real scalar bgL, real scalar archL, real scalar resetP,
                   real scalar consf, real scalar trf)
{
    string scalar depvar, thrvar, othervars
    real scalar p, q, S, n, k, j, t, na, naux
    real colvector y, xT, b, e, e2, fit, dyv, ya
    real matrix W, thr, E, Xa, Xw, Xr
    real rowvector tauS
    real scalar r2, m1, m2, m3, m4, skew, kurt
    real scalar ssr_r, ssr_u, madd, dfu
    real colvector br, er, ec
    struct tndes scalar d

    depvar    = st_global("e(depvar)")
    thrvar    = st_global("e(thrvar)")
    othervars = st_global("e(othervars)")
    p = st_numscalar("e(p)")
    q = st_numscalar("e(q)")
    S = st_numscalar("e(S)")
    b = st_matrix("e(b)")'

    if (S >= 2) {
        thr  = st_matrix("e(thresholds)")
        tauS = thr'
    }
    else tauS = J(1,0,.)

    y  = st_data(., depvar, st_local("touse"))
    xT = st_data(., thrvar, st_local("touse"))
    if (othervars != "") W = st_data(., othervars, st_local("touse"))
    else W = J(rows(y),0,.)

    d   = _tn_design(y, xT, W, p, q, tauS, consf, trf)
    fit = d.X * b
    e   = d.dyv - fit
    dyv = d.dyv
    n   = rows(e)
    k   = cols(d.X)
    e2  = e:^2

    // ---- Breusch-Godfrey LM (presample lagged residuals set to 0) ----
    E = J(n, bgL, 0)
    for (j=1; j<=bgL; j++) {
        for (t=j+1; t<=n; t++) E[t,j] = e[t-j]
    }
    r2 = _tn_auxr2(e, (d.X, E))
    st_numscalar("__bg_lm", n*r2)
    st_numscalar("__bg_df", bgL)
    st_numscalar("__bg_p",  chi2tail(bgL, n*r2))

    // ---- Engle ARCH-LM (regress e^2 on constant + lagged e^2) ----
    if (n > archL+1) {
        na = n - archL
        ya = e2[|archL+1 \ n|]
        Xa = J(na,1,1)
        for (j=1; j<=archL; j++) Xa = Xa, e2[|archL+1-j \ n-j|]
        r2 = _tn_auxr2(ya, Xa)
        st_numscalar("__arch_lm", na*r2)
        st_numscalar("__arch_df", archL)
        st_numscalar("__arch_p",  chi2tail(archL, na*r2))
    }
    else {
        st_numscalar("__arch_lm", .)
        st_numscalar("__arch_df", archL)
        st_numscalar("__arch_p",  .)
    }

    // ---- Breusch-Pagan (Koenker n*R^2 form, regress e^2 on the design) ----
    r2 = _tn_auxr2(e2, d.X)
    st_numscalar("__bp_lm", n*r2)
    st_numscalar("__bp_df", k-1)
    st_numscalar("__bp_p",  chi2tail(k-1, n*r2))

    // ---- Jarque-Bera ----
    m1   = mean(e)
    ec   = e :- m1
    m2   = mean(ec:^2)
    m3   = mean(ec:^3)
    m4   = mean(ec:^4)
    skew = m3 / m2^1.5
    kurt = m4 / m2^2
    st_numscalar("__skew", skew)
    st_numscalar("__kurt", kurt)
    st_numscalar("__jb",   n*(skew^2/6 + (kurt-3)^2/24))
    st_numscalar("__jb_p", chi2tail(2, n*(skew^2/6 + (kurt-3)^2/24)))

    // ---- Ramsey RESET (F test on powers 2..resetP of the fitted value) ----
    ssr_r = cross(e,e)
    Xr = d.X
    for (j=2; j<=resetP; j++) Xr = Xr, fit:^j
    br = invsym(cross(Xr,Xr)) * cross(Xr,dyv)
    er = dyv - Xr*br
    ssr_u = cross(er,er)
    madd  = resetP - 1
    dfu   = n - cols(Xr)
    st_numscalar("__reset_f",   ((ssr_r-ssr_u)/madd) / (ssr_u/dfu))
    st_numscalar("__reset_df1", madd)
    st_numscalar("__reset_df2", dfu)
    st_numscalar("__reset_p",   Ftail(madd, dfu, ((ssr_r-ssr_u)/madd)/(ssr_u/dfu)))
}
end
