*! fflm2 1.0.0  23jul2026
*! Two-break LM unit-root test with RALS and RALS2 (factor) augmentation
*! Lee-Strazicich two-break LM + Meng-Lee-Tieslau RALS critical values
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program fflm2, rclass
    version 14.0
    syntax varname(ts) [if] [in] , [ Rals(integer 0) Factors(varlist) ///
        Pmax(integer 8) IC(integer 3) Trim(real 0.10) ]

    if !inlist(`rals',0,1,2) {
        di as error "rals() must be 0 (plain LM2), 1 (RALS) or 2 (RALS + factors)"
        exit 198
    }
    if `rals'==2 & "`factors'"=="" {
        di as error "rals(2) requires factors(varlist)"
        exit 198
    }
    if `ic'<1 | `ic'>3 {
        di as error "ic() must be 1 (AIC), 2 (BIC) or 3 (t-stat)"
        exit 198
    }

    marksample touse
    markout `touse' `factors'
    qui tsset
    local tv "`r(timevar)'"
    qui su `tv' if `touse', meanonly
    local tmin = r(min)
    tempname STAT
    mata: _fl2_run("`varlist'", "`factors'", "`touse'", `rals', ///
        `pmax', `ic', `trim', `tmin', "`STAT'")

    local lab = cond(`rals'==0,"Two-break LM", ///
        cond(`rals'==1,"RALS two-break LM","RALS2 (factor) two-break LM"))
    di ""
    di as txt "`lab' unit-root test" _col(56) "Obs = " as res %5.0f `STAT'[1,8]
    di as txt "H0: unit root (nonstationary)   Deterministics: level & trend breaks"
    di as txt "{hline 64}"
    di as txt "Test statistic" _col(30) "= " as res %9.4f `STAT'[1,1]
    di as txt "Interpolated p-value" _col(30) "= " as res %9.4f `STAT'[1,2]
    di as txt "First break" _col(30) "= " as res %9.0f `STAT'[1,3]
    di as txt "Second break" _col(30) "= " as res %9.0f `STAT'[1,4]
    di as txt "Selected lag" _col(30) "= " as res %9.0f `STAT'[1,5]
    if `rals'>=1 di as txt "RALS rho-squared" _col(30) "= " as res %9.4f `STAT'[1,6]
    di as txt "{hline 64}"
    di as txt "Critical values:" _col(34) "1%" _col(46) "5%" _col(58) "10%"
    di as txt "  " _col(30) as res %10.3f `STAT'[1,9] %12.3f `STAT'[1,10] %12.3f `STAT'[1,11]
    di as txt "{hline 64}"
    di as txt "Reject H0 (=> stationary) for test statistic below the critical value."

    return scalar stat  = `STAT'[1,1]
    return scalar p     = `STAT'[1,2]
    return scalar break1 = `STAT'[1,3]
    return scalar break2 = `STAT'[1,4]
    return scalar lag   = `STAT'[1,5]
    if `rals'>=1 return scalar rho2 = `STAT'[1,6]
    return scalar cv1   = `STAT'[1,9]
    return scalar cv5   = `STAT'[1,10]
    return scalar cv10  = `STAT'[1,11]
    return scalar N     = `STAT'[1,8]
    return local  rals  "`rals'"
    return local  cmd   "fflm2"
end

version 14.0
mata:

real colvector _fl2_lagn(real colvector x, real scalar n)
{
    real scalar r
    r = rows(x)
    if (n > 0) return((J(n,1,0) \ x[1..r-n]))
    if (n < 0) return((x[(1-n)..r] \ J(-n,1,0)))
    return(x)
}
real colvector _fl2_diff(real colvector x)
{
    real scalar r
    r = rows(x)
    return((0 \ (x[2..r]-x[1..r-1])))
}
real matrix _fl2_diffM(real matrix x)
{
    real scalar r
    r = rows(x)
    return((J(1,cols(x),0) \ (x[2..r,.]-x[1..r-1,.])))
}
void _fl2_ols(real colvector y, real matrix X, real colvector b,
    real colvector e, real scalar sig2, real colvector se, real scalar ssr)
{
    real matrix m
    m = invsym(cross(X,X))
    b = qrsolve(X, y)                    // QR solve (matches GAUSS y/x); stabler than normal equations
    e = y - X*b
    ssr = cross(e,e)
    sig2 = ssr/(rows(y)-cols(X))
    se = sqrt(diagonal(m)*sig2)
}
real scalar _fl2_argmin(real colvector v)
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
real scalar _fl2_argmax(real colvector v)
{
    real scalar i, im, mx
    mx = v[1]
    im = 1
    i = 2
    while (i <= rows(v)) {
        if (v[i] > mx) {
            mx = v[i]
            im = i
        }
        i = i + 1
    }
    return(im)
}
// build the two-break LM regression at breaks (tb1,tb2) and lag p; return dep, x, and the score ylm
void _fl2_reg(real colvector y, real scalar tb1, real scalar tb2, real scalar p,
    real colvector dep, real matrix x, real colvector ylm)
{
    real scalar t, nobs, j, s0
    real colvector dt, du1, du2, dy, b0, st, s2, dylm, ls, zb
    real matrix z, dz, ds, lmat
    t = rows(y)
    dt = (1::t)
    du1 = (J(tb1,1,0) \ J(t-tb1,1,1))
    du2 = (J(tb2,1,0) \ J(t-tb2,1,1))
    z = dt, du1, du2
    dy = _fl2_diff(y)[2..t]
    dz = _fl2_diffM(z)[2..t,.]
    b0 = qrsolve(dz, dy)
    s0 = y[1] - (z[1,.]*b0)[1,1]
    zb = z*b0
    st = (y :- s0) - zb
    nobs = t
    s2 = J(nobs,1,0)
    s2[1..tb1] = st[1..tb1] :/ (tb1/nobs)
    s2[(tb1+1)..nobs] = st[(tb1+1)..nobs] :/ ((nobs-tb1)/nobs)
    ylm = s2
    dylm = _fl2_diff(ylm)[2..t]
    lmat = J(rows(dylm), p+1, 0)
    j = 1
    while (j <= p) {
        lmat[.,j] = _fl2_lagn(dylm, j)
        j = j + 1
    }
    dep = _fl2_diff(y)[(p+2)..t]
    ls  = _fl2_lagn(ylm,1)[(p+2)..t]
    dz  = _fl2_diffM(z)[(p+2)..t,.]
    if (p==0) x = ls, dz
    else {
        ds = lmat[(p+1)..rows(lmat),.]
        x = ls, dz, ds[.,1..p]
    }
}
// RALS regression exactly as in the source RALS_LM2_trend_break (0-based lag)
void _fl2_ralsreg(real colvector y, real scalar tb1, real scalar tb2, real scalar lag,
    real colvector dep, real matrix x)
{
    real scalar t, nobs, j, s0
    real colvector dt, du1, du2, dy, dyf, b0, st, s2, ylm, ly, dylm, y1, zb
    real matrix z, dz, dzf, lmat, ldy
    t = rows(y)
    dt = (1::t)
    du1 = (J(tb1,1,0) \ J(t-tb1,1,1))
    du2 = (J(tb2,1,0) \ J(t-tb2,1,1))
    z = dt, du1, du2
    dy = _fl2_diff(y)[2..t]                 // trimr(diff(y),1,0)
    dz = _fl2_diffM(z)[2..t,.]              // trimr(diff(z),1,0)
    b0 = qrsolve(dz, dy)
    s0 = y[1] - (z[1,.]*b0)[1,1]
    zb = z*b0
    st = (y :- s0) - zb
    nobs = t
    s2 = J(nobs,1,0)
    s2[1..tb1] = st[1..tb1] :/ (tb1/nobs)
    s2[(tb1+1)..nobs] = st[(tb1+1)..nobs] :/ ((nobs-tb1)/nobs)
    ylm = s2[2..t]                          // trimr(ylm,1,0)
    ly = _fl2_lagn(ylm,1)
    dylm = _fl2_diff(ylm)                   // diff of trimmed ylm (leading 0)
    if (lag==0) {
        dep = dy
        y1  = ly
        x = y1, dz
    }
    else {
        lmat = J(rows(dylm), lag, 0)
        j = 1
        while (j <= lag) {
            lmat[.,j] = _fl2_lagn(dylm, j)
            j = j + 1
        }
        dep = dy[(lag+1)..rows(dy)]
        y1  = ly[(lag+1)..rows(ly)]
        ldy = lmat[(lag+1)..rows(lmat),.]
        dzf = dz[(lag+1)..rows(dz),.]
        x = y1, dzf, ldy
    }
}
// grid-search the two breaks (min LM stat); returns tb1,tb2,LM,lag
real rowvector _fl2_search(real colvector y, real scalar pmax, real scalar ic, real scalar trim)
{
    real scalar t, T1, T2, tb1, tb2, LMmin, tb1m, tb2m, p, lag, lagt, stat
    real colvector dep, ylm, taup, aicp, sicp, tstatp, b, e, se
    real scalar sig2, ssr
    real matrix x
    t = rows(y)
    T1 = round(trim*t)
    T2 = round((1-trim)*t)
    if (T1 < pmax+2) T1 = pmax + 3
    LMmin = 1000; tb1m = 0; tb2m = 0; lag = 1
    tb1 = T1
    while (tb1 <= T2) {
        tb2 = tb1 + 2
        while (tb2 <= T2) {
            taup = J(pmax+1,1,0); aicp = J(pmax+1,1,0); sicp = J(pmax+1,1,0); tstatp = J(pmax+1,1,0)
            p = 0
            while (p <= pmax) {
                _fl2_reg(y, tb1, tb2, p, dep, x, ylm)
                _fl2_ols(dep, x, b, e, sig2, se, ssr)
                taup[p+1] = b[1]/se[1]
                aicp[p+1] = ln(cross(e,e)/rows(x)) + 2*(cols(x)+2)/rows(x)
                sicp[p+1] = ln(cross(e,e)/rows(x)) + (cols(x)+2)*ln(rows(x))/rows(x)
                tstatp[p+1] = abs(b[cols(x)]/se[cols(x)])
                p = p + 1
            }
            if (ic==1) lag = _fl2_argmin(aicp)
            else if (ic==2) lag = _fl2_argmin(sicp)
            else {
                lagt = _fl2_argmax(tstatp)
                if (abs(tstatp[lagt]) > 1.645) lag = lagt
                else lag = 1
            }
            stat = taup[lag]
            if (stat < LMmin) {
                LMmin = stat; tb1m = tb1; tb2m = tb2
            }
            tb2 = tb2 + 1
        }
        tb1 = tb1 + 1
    }
    // NOTE: like the source routine, `lag` is left at the value from the LAST grid
    // cell (it is never re-selected at the optimal breaks); the RALS step reuses it.
    return((tb1m, tb2m, LMmin, lag))
}
// Lee-Strazicich (2003) Table 2 critical values (level & trend breaks), by (lam1,lam2)
real rowvector _fl2_cv_lm(real scalar T, real scalar tb1, real scalar tb2)
{
    real matrix c1, c5, c10
    real scalar lam1, lam2, r, cc
    c1  = (-6.16, -6.41, -6.33 \ 0, -6.45, -6.42 \ 0, 0, -6.32)
    c5  = (-5.59, -5.74, -5.71 \ 0, -5.67, -5.65 \ 0, 0, -5.73)
    c10 = (-5.27, -5.32, -5.33 \ 0, -5.31, -5.32 \ 0, 0, -5.32)
    lam1 = tb1/T
    lam2 = tb2/T
    if (lam1 < 0.30) r = 1
    else if (lam1 <= 0.55) r = 2
    else r = 3
    if (lam2 < 0.45) cc = 1
    else if (lam2 <= 0.70) cc = 2
    else cc = 3
    return((c1[r,cc], c5[r,cc], c10[r,cc]))
}
// Meng-Lee-Tieslau (2017) RALS-LM two-break critical values, Hansen interp on rho2
real rowvector _fl2_cv_rals(real scalar r2)
{
    real matrix M
    real scalar r210, a, b, wa
    M = (-3.258, -2.599, -2.242 \ -3.586, -2.953, -2.610 \ -3.821, -3.212, -2.881 \
         -4.006, -3.149, -3.100 \ -4.153, -3.591, -3.286 \ -4.281, -3.741, -3.444 \
         -4.398, -3.867, -3.579 \ -4.496, -3.982, -3.703 \ -4.592, -4.079, -3.811 \
         -4.672, -4.158, -3.907)
    if (r2 < 0.1) return(M[1,.])
    r210 = r2*10
    if (r210 >= 10) return(M[10,.])
    a = floor(r210); b = ceil(r210)
    wa = b - r210
    return(wa*M[a,.] + (1-wa)*M[b,.])
}
// p-value interpolation (left tail) matching pval_interp
real scalar _fl2_pval(real scalar stat, real rowvector cv)
{
    real colvector c, s
    real scalar K, idx, p, i
    c = cv'                          // ascending: cv1 < cv5 < cv10
    s = (0.01 \ 0.05 \ 0.10)
    K = 3
    if (stat <= c[1]) p = s[1]*exp((stat-c[1])/(c[2]-c[1])*ln(s[2]/s[1]))
    else if (stat >= c[K]) p = 1 - (1-s[K])*((c[K]-stat)/(c[K]-c[K-1]))
    else {
        idx = 0
        i = 1
        while (i <= K) {
            if (stat >= c[i]) idx = idx + 1
            i = i + 1
        }
        p = s[idx] + (s[idx+1]-s[idx])*((stat-c[idx])/(c[idx+1]-c[idx]))
    }
    if (p < 0) p = 0
    if (p > 1) p = 1
    return(p)
}

void _fl2_run(string scalar vn, string scalar fv, string scalar touse,
    real scalar rals, real scalar pmax, real scalar ic, real scalar trim,
    real scalar tmin, string scalar statname)
{
    real colvector y, dep, ylm, e1, se, b, e2, e3
    real matrix x, more, w
    real rowvector sr, cv
    real scalar T, tb1, tb2, LM, lag, stat, p2, sig2, sig2A, ssr, m2, m3, pval
    y = st_data(., vn, touse)
    T = rows(y)
    sr = _fl2_search(y, pmax, ic, trim)
    tb1 = sr[1]; tb2 = sr[2]; LM = sr[3]; lag = sr[4]
    stat = LM; p2 = .
    if (rals==0) {
        cv = _fl2_cv_lm(T, tb1, tb2)
        pval = _fl2_pval(LM, cv)
    }
    else {
        // RALS uses the same (last-grid) lag as the source, converted to 0-based
        _fl2_ralsreg(y, tb1, tb2, lag-1, dep, x)
        _fl2_ols(dep, x, b, e1, sig2, se, ssr)
        e2 = e1:^2; e3 = e1:^3
        m2 = sum(e2)/T; m3 = sum(e3)/T
        w = (e2 :- m2), (e3 :- m3 :- 3*m2*e1)
        if (rals==2 & fv!="") {
            more = st_data(., fv, touse)
            more = more[(rows(more)-rows(dep)+1)..rows(more), .]
            x = x, w, more
        }
        else x = x, w
        _fl2_ols(dep, x, b, e1, sig2A, se, ssr)
        stat = b[1]/se[1]
        p2 = sig2A/sig2
        if (p2 > 1) p2 = 1
        cv = _fl2_cv_rals(p2)
        pval = _fl2_pval(stat, cv)
    }
    st_matrix(statname, (stat, pval, tmin+tb1-1, tmin+tb2-1, lag-1, p2, ., T, cv[1], cv[2], cv[3]))
}

end
