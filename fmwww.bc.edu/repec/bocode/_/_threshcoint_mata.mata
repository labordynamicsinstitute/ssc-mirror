*! _threshcoint_mata 1.0.0  16may2026  Dr Merwan Roudane
*! Mata core for the threshcoint package -- pure .mata source file.
*!
*! Loaded on demand by every public tc_* command via
*!
*!     qui capture mata: __tc_loaded()
*!     if _rc qui _tc_load
*!
*! Mata functions defined inside a Stata program (e.g. inside an .ado
*! file) are scoped to that program and removed from Mata's memory the
*! moment the program returns.  Sourcing this file at the top level via
*! `do _threshcoint_mata.mata' instead defines the functions in Mata's
*! global workspace, where they persist for the rest of the Stata
*! session.
*------------------------------------------------------------------------------

version 14.0
mata
mata set matastrict off

//------------------------------------------------------------------------------
// Sentinel function -- callers probe its existence with
//     capture mata: __tc_loaded()
// to decide whether this .mata file has already been do'd.
//------------------------------------------------------------------------------
void __tc_loaded()
{
    /* no-op */
}
// ====================================================================
//   Small utilities
// ====================================================================

real scalar tc_quantile(real colvector x, real scalar q)
{
    real colvector s
    real scalar n, h, lo, hi, fr
    if (rows(x) == 0) return(.)
    s = sort(x, 1)
    n = rows(s)
    h = q*(n-1) + 1
    if (h <= 1) return(s[1])
    if (h >= n) return(s[n])
    lo = floor(h)
    hi = lo + 1
    fr = h - lo
    return((1-fr)*s[lo] + fr*s[hi])
}

real colvector tc_seq(real scalar a, real scalar b, real scalar n)
{
    real scalar i, step
    real colvector v
    if (n < 2) return(J(1,1,a))
    v = J(n,1,.)
    step = (b - a)/(n-1)
    for (i=1; i<=n; i++) v[i] = a + (i-1)*step
    return(v)
}

real colvector tc_pick(real scalar n_total, real scalar n_pick)
{
    real colvector ix
    real scalar i
    if (n_pick >= n_total) return((1::n_total))
    ix = J(n_pick,1,.)
    for (i=1; i<=n_pick; i++) ix[i] = (((1)>(round(1 + (i-1)*(n_total-1)/(n_pick-1))))? (1) : (round(1 + (i-1)*(n_total-1)/(n_pick-1))))
    return(ix)
}

// ====================================================================
//   OLS, lag-matrix, embed, GLS-detrend
// ====================================================================

struct tc_ols_t {
    real colvector  b, resid, se, tstat, pval
    real matrix     vcov
    real scalar     ssr, sigma2, n, k, aic, bic, loglik
}

struct tc_ols_t scalar tc_ols(real colvector y, real matrix X, | real scalar addconst)
{
    real matrix XX, XXi, Xuse
    real colvector b, e
    real scalar n, k, ssr, sigma2, ll
    struct tc_ols_t scalar r
    if (args() < 3) addconst = 0
    Xuse = (addconst ? (J(rows(X),1,1), X) : X)
    n = rows(Xuse)
    k = cols(Xuse)
    XX = quadcross(Xuse, Xuse)
    XXi = invsym(XX)
    b  = XXi * quadcross(Xuse, y)
    e  = y - Xuse * b
    ssr = quadcross(e, e)
    sigma2 = (n > k ? ssr/(n - k) : .)
    r.b      = b
    r.resid  = e
    r.vcov   = sigma2 :* XXi
    r.se     = sqrt(diagonal(r.vcov))
    r.tstat  = b :/ r.se
    r.pval   = 2 :* ttail(n - k, abs(r.tstat))
    r.ssr    = ssr
    r.sigma2 = sigma2
    r.n      = n
    r.k      = k
    ll       = -0.5 * n * (ln(2 * pi()) + ln(ssr/n) + 1)
    r.aic    = -2*ll + 2*k
    r.bic    = -2*ll + k*ln(n)
    r.loglik = ll
    return(r)
}

real matrix tc_lagmat(real colvector x, real scalar lags)
{
    real scalar n, i
    real matrix out
    n = rows(x)
    out = J(n - lags, lags, .)
    for (i=1; i<=lags; i++) out[., i] = x[(lags - i + 1) :: (n - i)]
    return(out)
}

real matrix tc_embed(real colvector x, real scalar dim)
{
    real scalar n, i
    real matrix out
    n = rows(x)
    out = J(n - dim + 1, dim, .)
    for (i=0; i<dim; i++) out[., i+1] = x[(dim - i) :: (n - i)]
    return(out)
}

real colvector tc_gls_detrend(real colvector y, string scalar cse, real scalar cbar_in)
{
    real scalar T, cbar, ab, i
    real colvector yqd, ydet
    real matrix Z, Zqd, beta
    T = rows(y)
    if (cbar_in==.) cbar = (cse=="ct" ? -13.5 : -7.0)
    else            cbar = cbar_in
    ab = 1 + cbar/T
    yqd = J(T,1,.)
    yqd[1] = y[1]
    for (i=2; i<=T; i++) yqd[i] = y[i] - ab*y[i-1]
    if (cse=="ct") Z = (J(T,1,1), (1::T))
    else           Z = J(T,1,1)
    Zqd = Z
    for (i=2; i<=T; i++) Zqd[i,.] = Z[i,.] - ab*Z[i-1,.]
    beta = invsym(quadcross(Zqd,Zqd)) * quadcross(Zqd,yqd)
    ydet = y - Z*beta
    return(ydet)
}

// ====================================================================
//   Critical-value getters (cols are 1%, 5%, 10%)
// ====================================================================

real scalar tc_cv_es_phi(string scalar model, string scalar cse, real scalar sig)
{
    real matrix M; real scalar c, s
    if (model=="mtar") M = (10.13, 7.30, 6.07 \  8.91, 6.51, 5.44 \  8.71, 6.39, 5.37)
    else               M = ( 9.80, 7.06, 5.87 \  8.78, 6.42, 5.39 \  8.60, 6.33, 5.34)
    c = (cse=="nc" ? 1 : (cse=="c" ? 2 : 3))
    s = (sig==0.01 ? 1 : (sig==0.05 ? 2 : 3))
    return(M[c,s])
}

real rowvector tc_cv_es_phi_row(string scalar model, string scalar cse)
{
    return((tc_cv_es_phi(model,cse,0.01),
            tc_cv_es_phi(model,cse,0.05),
            tc_cv_es_phi(model,cse,0.10)))
}

real scalar tc_cv_gls_mtar(real scalar T, string scalar cse, real scalar sig)
{
    real matrix M_c, M_ct, M
    real colvector Tg
    real scalar s, i, w, lo, hi
    Tg = (50 \ 100 \ 250 \ 500 \ 1000 \ 2500)
    M_c  = (11.34, 8.07, 6.70 \ 10.72, 7.76, 6.47 \ 10.37, 7.54, 6.30 \ 10.22, 7.44, 6.23 \ 10.14, 7.39, 6.19 \ 10.09, 7.35, 6.16)
    M_ct = (14.54,10.89, 9.27 \ 12.52, 9.40, 8.01 \ 11.64, 8.62, 7.32 \ 11.31, 8.35, 7.09 \ 11.12, 8.20, 6.96 \ 11.01, 8.12, 6.88)
    M = (cse=="ct" ? M_ct : M_c)
    s = (sig==0.01 ? 1 : (sig==0.05 ? 2 : 3))
    if (T<=Tg[1])         return(M[1,s])
    if (T>=Tg[rows(Tg)])  return(M[rows(Tg),s])
    for (i=1; i<rows(Tg); i++) {
        if (Tg[i]<=T & T<=Tg[i+1]) {
            lo = Tg[i]
            hi = Tg[i+1]
            w  = (T - lo)/(hi - lo)
            return((1-w)*M[i,s] + w*M[i+1,s])
        }
    }
    return(.)
}

real rowvector tc_cv_gls_mtar_row(real scalar T, string scalar cse)
{
    return((tc_cv_gls_mtar(T,cse,0.01),
            tc_cv_gls_mtar(T,cse,0.05),
            tc_cv_gls_mtar(T,cse,0.10)))
}

real rowvector tc_cv_adl_bdm(real scalar m, string scalar cse)
{
    real matrix Mc, Mct
    real scalar idx
    Mc  = (-5.92,-5.07,-4.63 \ -6.26,-5.42,-4.99 \ -6.55,-5.72,-5.30 \ -6.82,-5.99,-5.58)
    Mct = (-6.43,-5.60,-5.17 \ -6.73,-5.91,-5.49 \ -7.01,-6.19,-5.78 \ -7.26,-6.45,-6.04)
    idx = (((1)>((((4)<(m))? (4) : (m))))? (1) : ((((4)<(m))? (4) : (m))))
    if (cse=="ct") return(Mct[idx,.])
    else           return(Mc[idx,.])
}

real rowvector tc_cv_adl_bo(real scalar m, string scalar cse)
{
    real matrix Mc, Mct
    real scalar idx
    Mc  = (20.21,15.90,13.78 \ 24.52,19.94,17.72 \ 28.73,23.76,21.40 \ 32.68,27.40,24.92)
    Mct = (23.87,19.34,17.10 \ 28.17,23.44,21.08 \ 32.34,27.40,24.92 \ 36.26,31.14,28.56)
    idx = (((1)>((((4)<(m))? (4) : (m))))? (1) : ((((4)<(m))? (4) : (m))))
    if (cse=="ct") return(Mct[idx,.])
    else           return(Mc[idx,.])
}

real rowvector tc_cv_supf(string scalar bk, string scalar model)
{
    real matrix M
    if (bk=="C0")      M = (13.77,10.33,8.71 \ 13.93,10.42,8.79)
    else if (bk=="CT") M = (14.15,10.71,9.08 \ 14.28,10.79,9.14)
    else if (bk=="CS") M = (15.32,11.64,9.93 \ 15.47,11.73,10.01)
    else                M = ( 8.78, 6.42,5.39 \  8.91, 6.51,5.44)
    return(model=="mtar" ? M[2,.] : M[1,.])
}

real rowvector tc_cv_bbc(string scalar tt)
{
    if      (tt=="LM") return((21.756,17.630,15.587))
    else if (tt=="LR") return((22.232,17.898,15.772))
    else                return((23.010,18.400,16.181))
}

real rowvector tc_cv_kss(string scalar cse)
{
    if (cse=="detrended") return((-4.42,-3.85,-3.58))
    else                   return((-3.93,-3.40,-3.13))
}

real rowvector tc_cv_eg(real scalar m, string scalar cse)
{
    real matrix M; real scalar idx
    M = (-3.39,-2.76,-2.45 \ -3.80,-3.18,-2.88 \ -4.14,-3.52,-3.22 \ -4.43,-3.82,-3.52)
    idx = (((1)>((((4)<(m))? (4) : (m))))? (1) : ((((4)<(m))? (4) : (m))))
    return(M[idx,.])
}

real rowvector tc_cv_adf(string scalar cse)
{
    if      (cse=="ct") return((-3.96,-3.41,-3.13))
    else if (cse=="c")  return((-3.43,-2.86,-2.57))
    else                 return((-2.58,-1.95,-1.62))
}

real rowvector tc_cv_covaug(string scalar model, real scalar m)
{
    real matrix Mt, Mm; real scalar idx
    Mt = (10.81,7.95,6.73 \ 8.42,6.15,5.16 \ 7.53,5.47,4.57)
    Mm = (10.97,8.09,6.85 \ 8.55,6.27,5.27 \ 7.63,5.56,4.66)
    idx = (((1)>((((3)<(m))? (3) : (m))))? (1) : ((((3)<(m))? (3) : (m))))
    return(model=="mtar" ? Mm[idx,.] : Mt[idx,.])
}

// ====================================================================
//   ADF / PP / Engle-Granger
// ====================================================================

struct tc_adf_t {
    real scalar stat, lags, nobs
    real rowvector cv
    string scalar cse, criterion
}

struct tc_adf_t scalar tc_adf(real colvector y, real scalar maxlag_in, string scalar cse, string scalar crit)
{
    real scalar T, mlg, p, bestlag, bestic, nobs, idx, ic
    real colvector dy, dep, ylag1
    real matrix Xreg, Lm
    struct tc_ols_t scalar rr
    struct tc_adf_t scalar out
    T = rows(y)
    mlg = (maxlag_in==. ? floor(12*(T/100)^0.25) : maxlag_in)
    dy = y[|(2) \ (T)|] - y[|(1) \ ((T-1))|]
    bestlag = 0
    bestic = .
    for (p=0; p<=mlg; p++) {
        nobs = (T-1) - p
        if (nobs < 10) {
            continue
        }
        dep   = dy[|(p+1) \ (T-1)|]
        ylag1 = y[|(p+1) \ (T-1)|]
        Xreg  = ylag1
        if (cse=="c" | cse=="ct") {
            Xreg = (J(nobs,1,1), Xreg)
        }
        if (cse=="ct") {
            Xreg = (Xreg, ((p+1)::(T-1)))
        }
        if (p > 0) {
            Lm = tc_lagmat(dy, p)
            Xreg = (Xreg, Lm[|(rows(Lm)-nobs+1), 1 \ rows(Lm), cols(Lm)|])
        }
        rr = tc_ols(dep, Xreg)
        if (crit=="bic") {
            ic = rr.bic
        }
        else {
            ic = rr.aic
        }
        if (ic < bestic | bestic == .) {
            bestic = ic
            bestlag = p
        }
    }
    p = bestlag
    nobs  = (T-1) - p
    dep   = dy[|(p+1) \ (T-1)|]
    ylag1 = y[|(p+1) \ (T-1)|]
    Xreg  = ylag1
    if (cse=="c" | cse=="ct") {
        Xreg = (J(nobs,1,1), Xreg)
    }
    if (cse=="ct") {
        Xreg = (Xreg, ((p+1)::(T-1)))
    }
    if (p > 0) {
        Lm = tc_lagmat(dy, p)
        Xreg = (Xreg, Lm[|(rows(Lm)-nobs+1), 1 \ rows(Lm), cols(Lm)|])
    }
    rr = tc_ols(dep, Xreg)
    if (cse=="c" | cse=="ct") {
        idx = 2
    }
    else {
        idx = 1
    }
    out.stat = rr.tstat[idx]
    out.lags = bestlag
    out.nobs = nobs
    out.cse  = cse
    out.criterion = crit
    out.cv   = tc_cv_adf(cse)
    return(out)
}

struct tc_pp_t {
    real scalar stat, lags, nobs
    real rowvector cv
    string scalar cse
}

struct tc_pp_t scalar tc_pp(real colvector y, string scalar cse, real scalar lags_in)
{
    real scalar T, lags, n, idx, j, w, ahat, sea, g0, lrv, gj, tau
    real colvector dy, ylag, e
    real matrix Xreg
    struct tc_ols_t scalar rr
    struct tc_pp_t scalar out
    T = rows(y)
    lags = (lags_in==. ? floor(4*(T/100)^(2/9)) : lags_in)
    dy   = y[|(2) \ (T)|] - y[|(1) \ ((T-1))|]
    n    = T - 1
    ylag = y[|(1) \ ((T-1))|]
    Xreg = ylag
    if (cse=="c" | cse=="ct") Xreg = (J(n,1,1), Xreg)
    if (cse=="ct")            Xreg = (Xreg, (1::n))
    rr = tc_ols(dy, Xreg)
    idx  = (cse=="c" | cse=="ct" ? 2 : 1)
    ahat = rr.b[idx]
    sea = rr.se[idx]
    e = rr.resid
    g0 = (e'*e)/n
    lrv = g0
    for (j=1; j<=lags; j++) {
        w  = 1 - j/(lags+1)
        gj = (e[|((j+1)) \ (n)|])' * (e[|(1) \ ((n-j))|]) / n
        lrv = lrv + 2*w*gj
    }
    tau = (sqrt(g0)/sqrt(lrv))*(ahat/sea) - 0.5*(lrv - g0)/(sqrt(lrv)*sea*sqrt(n))
    out.stat = tau
    out.lags = lags
    out.nobs = n
    out.cse  = cse
    out.cv   = tc_cv_adf(cse)
    return(out)
}

struct tc_eg_t {
    real scalar stat, lags, nobs, m
    real rowvector cv, coint_vec
    string scalar cse
    real colvector resid
}

struct tc_eg_t scalar tc_eg(real colvector y, real matrix x, real scalar maxlag_in,
                     string scalar cse, string scalar crit)
{
    struct tc_eg_t scalar out
    struct tc_ols_t scalar lr
    struct tc_adf_t scalar aa
    real scalar addc, m
    m = cols(x)
    addc = (cse != "nc")
    lr = tc_ols(y, x, addc)
    aa = tc_adf(lr.resid, maxlag_in, "nc", crit)
    out.stat = aa.stat
    out.lags = aa.lags
    out.nobs = aa.nobs
    out.m    = m
    out.coint_vec = lr.b'
    out.resid     = lr.resid
    out.cv   = tc_cv_eg(m, cse)
    out.cse  = cse
    return(out)
}

// ====================================================================
//   Threshold cointegration result struct (universal)
// ====================================================================

struct tc_thres_t {
    string scalar test_name, model, conclusion, breaktype_name
    real scalar phi_stat, gls_phi_stat, t_stat, sup_wald, sup_phi, sup_lm
    real scalar sup_t, f_star, f_asymmetry, breakpoint, sup_stat
    real scalar rho1, rho2, t_rho1, t_rho2, threshold
    real scalar lags, nregime1, nregime2, beta_est
    real scalar rho_mid, drift_low, drift_mid, drift_high, ssr_total
    real rowvector cv
    real colvector grid_values, grid_stats
}

// ====================================================================
//   1. Enders-Siklos TAR/MTAR
// ====================================================================

struct tc_thres_t scalar tc_enders_siklos(real colvector y, real matrix x, string scalar model,
        real scalar threshold, real scalar maxlag, string scalar crit, string scalar cse)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real colvector e, de, e_lag, indvar, de_lag, dep, el, iv, It, pos, neg
    real matrix X, L
    real scalar T, n, p, bestlag, bestic, start, nobs, ic
    real scalar rho1, rho2, t1, t2, omega, phi, fasy, cv_5
    real rowvector cvs

    T = rows(y)
    lr = tc_ols(y, x, (cse!="nc"))
    e = lr.resid
    de = e[|(2) \ (T)|] - e[|(1) \ ((T-1))|]
    n  = T - 1
    e_lag = e[|(1) \ ((T-1))|]
    if (model=="mtar") {
        de_lag = (0 \ de[|(1) \ ((n-1))|])
        indvar = de_lag
    }
    else indvar = e_lag

    bestlag = 0
    bestic = .
    for (p=0; p<=maxlag; p++) {
        start = (((p)>(1))? (p) : (1))
        nobs  = n - start
        if (nobs < 10) continue
        dep = de[|((start+1)) \ (n)|]
        el  = e_lag[|((start+1)) \ (n)|]
        iv  = indvar[|((start+1)) \ (n)|]
        It  = (iv :>= threshold)
        pos = el :* It
        neg = el :* (1 :- It)
        X   = (pos, neg)
        if (p>0) {
            L = tc_lagmat(de, p)
            X = (X, L[|((rows(L)-nobs+1)), 1 \ (rows(L)), cols(L)|])
        }
        rr = tc_ols(dep, X)
        ic = (crit=="bic" ? rr.bic : rr.aic)
        if (ic < bestic | bestic==.) {
            bestic = ic
            bestlag = p
        }
    }

    p = bestlag
    start = (((p)>(1))? (p) : (1))
    nobs  = n - start
    dep = de[|((start+1)) \ (n)|]
    el  = e_lag[|((start+1)) \ (n)|]
    iv  = indvar[|((start+1)) \ (n)|]
    It  = (iv :>= threshold)
    pos = el :* It
    neg = el :* (1 :- It)
    X   = (pos, neg)
    if (p>0) {
        L = tc_lagmat(de, p)
        X = (X, L[|((rows(L)-nobs+1)), 1 \ (rows(L)), cols(L)|])
    }
    rr = tc_ols(dep, X)
    rho1 = rr.b[1]
    rho2 = rr.b[2]
    t1   = rr.tstat[1]
    t2 = rr.tstat[2]
    phi  = (t1^2 + t2^2)/2
    omega = rr.vcov[1,1] + rr.vcov[2,2] - 2*rr.vcov[1,2]
    fasy = (omega > 0 ? (rho1-rho2)^2 / omega : 0)
    cvs  = tc_cv_es_phi_row(model, cse)
    cv_5 = cvs[2]
    out.test_name   = "Enders-Siklos (2001) "+(model=="mtar"?"MTAR":"TAR")+" test"
    out.model       = model
    out.phi_stat    = phi
    out.rho1=rho1
    out.rho2=rho2
    out.t_rho1=t1
    out.t_rho2=t2
    out.f_asymmetry = fasy
    out.threshold   = threshold
    out.lags        = p
    out.nregime1    = sum(It)
    out.nregime2    = nobs - sum(It)
    out.cv          = cvs
    out.conclusion  = (phi > cv_5 ? "Reject H0 (threshold cointegration) at 5%" :
                                     "Fail to reject H0 at 5%")
    return(out)
}

// ====================================================================
//   2. Cook (2007) GLS-MTAR
// ====================================================================

struct tc_thres_t scalar tc_gls_mtar(real colvector y, real matrix x, real scalar threshold,
        real scalar maxlag, string scalar cse, string scalar crit, real scalar cbar)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real colvector resid, e_gls, de, e_lag, de_lag, dep, el, dl, Mt
    real matrix X, L
    real scalar T, n, p, bestlag, bestic, start, nobs, ic
    real scalar rho1, rho2, t1, t2, phi_gls, cv_5

    T = rows(y)
    lr = tc_ols(y, x, 1)
    resid = lr.resid
    e_gls = tc_gls_detrend(resid, cse, cbar)
    n = T - 1
    de = e_gls[|(2) \ (T)|] - e_gls[|(1) \ ((T-1))|]
    e_lag  = e_gls[|(1) \ ((T-1))|]
    de_lag = (0 \ de[|(1) \ ((n-1))|])

    bestlag = 0
    bestic = .
    for (p=0; p<=maxlag; p++) {
        start = (((p)>(1))? (p) : (1))
        nobs  = n - start
        if (nobs < 10) continue
        dep = de[|((start+1)) \ (n)|]
        el  = e_lag[|((start+1)) \ (n)|]
        dl  = de_lag[|((start+1)) \ (n)|]
        Mt  = (dl :>= threshold)
        X   = (el :* Mt, el :* (1 :- Mt))
        if (p>0) {
            L = tc_lagmat(de, p)
            X = (X, L[|((rows(L)-nobs+1)), 1 \ (rows(L)), cols(L)|])
        }
        rr = tc_ols(dep, X)
        ic = (crit=="bic" ? rr.bic : rr.aic)
        if (ic < bestic | bestic==.) {
            bestic = ic
            bestlag = p
        }
    }

    p = bestlag
    start = (((p)>(1))? (p) : (1))
    nobs = n - start
    dep = de[|((start+1)) \ (n)|]
    el  = e_lag[|((start+1)) \ (n)|]
    dl  = de_lag[|((start+1)) \ (n)|]
    Mt  = (dl :>= threshold)
    X   = (el :* Mt, el :* (1 :- Mt))
    if (p>0) {
        L = tc_lagmat(de, p)
        X = (X, L[|((rows(L)-nobs+1)), 1 \ (rows(L)), cols(L)|])
    }
    rr = tc_ols(dep, X)
    rho1 = rr.b[1]
    rho2 = rr.b[2]
    t1   = rr.tstat[1]
    t2 = rr.tstat[2]
    phi_gls = (t1^2 + t2^2)/2
    cv_5 = tc_cv_gls_mtar(T, cse, 0.05)
    out.test_name  = "Cook (2007) GLS-MTAR test"
    out.gls_phi_stat = phi_gls
    out.rho1=rho1
    out.rho2=rho2
    out.t_rho1=t1
    out.t_rho2=t2
    out.threshold  = threshold
    out.lags       = p
    out.cv         = tc_cv_gls_mtar_row(T, cse)
    out.conclusion = (phi_gls > cv_5 ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    out.nregime1   = sum(Mt)
    out.nregime2 = nobs - sum(Mt)
    return(out)
}

// ====================================================================
//   3. Extended E-S (Osinska & Galecki 2022)
// ====================================================================

struct tc_thres_t scalar tc_ext_es(real colvector y, real matrix x, real colvector tv_in,
        string scalar model, real scalar maxlag, string scalar crit, real scalar trim)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr, best_rr
    real colvector e, de, e_lag, tv, sortv, grid, It, pos, neg, idxs, dx1
    real matrix X
    real scalar T, n, lo, hi, ngrid, i, tau, best_phi, best_th, phi
    real scalar rho1, rho2, t1, t2, omega, fasy
    real scalar best_n1, best_n2

    T = rows(y)
    lr = tc_ols(y, x, 1)
    e  = lr.resid
    n  = T - 1
    de = e[|(2) \ (T)|] - e[|(1) \ ((T-1))|]
    e_lag = e[|(1) \ ((T-1))|]
    if (rows(tv_in)==0) {
        dx1 = x[|(2),(1) \ (T),(1)|] - x[|(1),(1) \ ((T-1)),(1)|]
        tv = dx1
    } else {
        if (rows(tv_in)==T) tv = tv_in[|(2) \ (T)|] - tv_in[|(1) \ ((T-1))|]
        else                 tv = tv_in
    }
    if (rows(tv) > n) tv = tv[|(1) \ (n)|]
    if (rows(tv) < n) {
        de = de[|(1) \ (rows(tv))|]
        e_lag = e_lag[|(1) \ (rows(tv))|]
        n = rows(tv)
    }
    sortv = sort(tv,1)
    lo = (((1)>(floor(trim*n)))? (1) : (floor(trim*n)))
    hi = (((n)<(floor((1-trim)*n)))? (n) : (floor((1-trim)*n)))
    grid = sortv[|(lo) \ (hi)|]
    if (rows(grid) > 200) {
        ngrid = 200
        idxs = tc_pick(rows(grid), ngrid)
        grid = grid[idxs]
    }
    best_phi = -1e20
    best_th = 0
    best_n1=0
    best_n2=0
    for (i=1; i<=rows(grid); i++) {
        tau = grid[i]
        It  = (tv :>= tau)
        if (sum(It) < 5 | n - sum(It) < 5) continue
        pos = e_lag :* It
        neg = e_lag :* (1 :- It)
        X = (pos, neg)
        rr = tc_ols(de, X)
        t1 = rr.tstat[1]
        t2 = rr.tstat[2]
        phi = (t1^2 + t2^2)/2
        if (phi > best_phi) {
            best_phi = phi
            best_th = tau
            best_rr = rr
            best_n1 = sum(It)
            best_n2 = n - sum(It)
        }
    }
    rho1 = best_rr.b[1]
    rho2 = best_rr.b[2]
    t1   = best_rr.tstat[1]
    t2 = best_rr.tstat[2]
    omega = best_rr.vcov[1,1] + best_rr.vcov[2,2] - 2*best_rr.vcov[1,2]
    fasy  = (omega > 0 ? (rho1-rho2)^2/omega : 0)
    out.test_name = "Extended Enders-Siklos (Osinska & Galecki 2022)"
    out.model     = model
    out.sup_phi   = best_phi
    out.threshold = best_th
    out.rho1=rho1
    out.rho2=rho2
    out.t_rho1=t1
    out.t_rho2=t2
    out.f_asymmetry = fasy
    out.nregime1 = best_n1
    out.nregime2 = best_n2
    out.lags = 0
    return(out)
}

// ====================================================================
//   4. Covariates-augmented (Oh-Lee-Meng 2017)
// ====================================================================

struct tc_thres_t scalar tc_covaug(real colvector y, real matrix x, string scalar model,
        real scalar threshold, real scalar maxlag, string scalar crit)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real colvector e, de, e_lag, de_lag, iv, It, pos, neg
    real matrix dx, X
    real scalar T, n, rho1, rho2, t1, t2, phi, cv_5, m
    real rowvector cvs
    T = rows(y)
    m = cols(x)
    lr = tc_ols(y, x, 1)
    e = lr.resid
    n = T - 1
    de = e[|(2) \ (T)|] - e[|(1) \ ((T-1))|]
    e_lag = e[|(1) \ ((T-1))|]
    dx = x[|(2), 1 \ (T), cols(x)|] :- x[|(1), 1 \ ((T-1)), cols(x)|]
    if (model=="mtar") {
        de_lag = (0 \ de[|(1) \ ((n-1))|])
        iv = de_lag[|(2) \ (n)|]
        de = de[|(2) \ (n)|]
        e_lag = e_lag[|(2) \ (n)|]
        dx = dx[|(2), 1 \ (n), cols(dx)|]
    } else iv = e_lag
    It = (iv :>= threshold)
    pos = e_lag :* It
    neg = e_lag :* (1 :- It)
    X = (pos, neg, dx)
    rr = tc_ols(de, X)
    rho1 = rr.b[1]
    rho2 = rr.b[2]
    t1 = rr.tstat[1]
    t2 = rr.tstat[2]
    phi = (t1^2 + t2^2)/2
    cvs = tc_cv_covaug(model, m)
    cv_5 = cvs[2]
    out.test_name = "Covariates-Augmented test (Oh, Lee & Meng 2017)"
    out.model     = model
    out.phi_stat  = phi
    out.rho1=rho1
    out.rho2=rho2
    out.t_rho1=t1
    out.t_rho2=t2
    out.threshold = threshold
    out.cv        = cvs
    out.conclusion = (phi > cv_5 ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    out.nregime1 = sum(It)
    out.nregime2 = rows(It) - sum(It)
    return(out)
}

// ====================================================================
//   5. Balke-Fomby sup-Wald
// ====================================================================

struct tc_thres_t scalar tc_balke_fomby(real colvector y, real matrix x, real scalar maxlag,
        real scalar trim, real scalar n_grid)
{
    struct tc_thres_t scalar out
    struct tc_eg_t scalar eg
    struct tc_ols_t scalar rr
    real colvector e, de, el, sortv, grid, It, pos, neg, wald, valid_idx, pick, hits
    real matrix X
    real scalar n, lo, hi, i, tau, rho1, rho2, omega, sup_w, best_th
    eg = tc_eg(y, x, maxlag, "c", "aic")
    e = eg.resid
    n = rows(e) - 1
    de = e[|(2) \ ((n+1))|] - e[|(1) \ (n)|]
    el = e[|(1) \ (n)|]
    sortv = sort(el,1)
    lo = (((1)>(floor(trim*n)))? (1) : (floor(trim*n)))
    hi = (((n)<(floor((1-trim)*n)))? (n) : (floor((1-trim)*n)))
    grid = sortv[|(lo) \ (hi)|]
    if (rows(grid) > n_grid) {
        pick = tc_pick(rows(grid), n_grid)
        grid = grid[pick]
    }
    grid = uniqrows(grid)
    wald = J(rows(grid),1,.)
    for (i=1; i<=rows(grid); i++) {
        tau = grid[i]
        It = (el :>= tau)
        if (sum(It) < (((5)>(trim*n))? (5) : (trim*n)) | n - sum(It) < (((5)>(trim*n))? (5) : (trim*n))) continue
        pos = el :* It
        neg = el :* (1 :- It)
        X = (pos, neg)
        rr = tc_ols(de, X)
        rho1 = rr.b[1]
        rho2 = rr.b[2]
        omega = rr.vcov[1,1] + rr.vcov[2,2] - 2*rr.vcov[1,2]
        if (omega > 0) wald[i] = (rho1-rho2)^2 / omega
    }
    valid_idx = selectindex(wald:!=.)
    if (rows(valid_idx) == 0) {
        sup_w = .
        best_th = grid[1]
    }
    else {
        sup_w = max(wald[valid_idx])
        hits = selectindex(wald :== sup_w)
        if (rows(hits) == 0) best_th = grid[1]
        else                  best_th = grid[hits[1]]
    }
    out.test_name = "Balke-Fomby (1997) sup-Wald test"
    out.sup_wald = sup_w
    out.threshold = best_th
    out.lags = eg.lags
    out.grid_values = grid
    out.grid_stats  = wald
    return(out)
}

// ====================================================================
//   6. ADL-BDM (Li & Lee 2010)
// ====================================================================

struct tc_thres_t scalar tc_adl_bdm(real colvector y, real matrix x, real scalar maxlag,
        real scalar trim, real scalar n_grid, string scalar cse)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real colvector dy, de, y_lag, dep, dde, grid, It
    real matrix dx, x_lag, X, X1, X2
    real scalar T, n, m, i, tau, t_val, best_stat, best_th, addc, min_n, j, qv
    real rowvector cvs

    T = rows(y)
    m = cols(x)
    dy = y[|(2) \ (T)|] - y[|(1) \ ((T-1))|]
    dx = x[|(2), 1 \ (T), cols(x)|] :- x[|(1), 1 \ ((T-1)), cols(x)|]
    n  = T - 1
    y_lag = y[|(1) \ ((T-1))|]
    x_lag = x[|(1), 1 \ ((T-1)), cols(x)|]
    addc = (cse!="nc")
    lr = tc_ols(y, x, addc)
    de = lr.resid[|(2) \ (T)|] - lr.resid[|(1) \ ((T-1))|]
    min_n = (((n)<(rows(de)))? (n) : (rows(de)))
    dde = de[|(1) \ (min_n)|]
    grid = J(n_grid,1,.)
    for (j=1; j<=n_grid; j++) {
        qv = trim + (1-2*trim)*(j-1)/(n_grid-1)
        grid[j] = tc_quantile(dde, qv)
    }
    grid = uniqrows(grid)
    best_stat = 0
    best_th = 0
    for (i=1; i<=rows(grid); i++) {
        tau = grid[i]
        It = (dde :>= tau)
        if (sum(It) < (((5)>(trim*min_n))? (5) : (trim*min_n)) | min_n - sum(It) < (((5)>(trim*min_n))? (5) : (trim*min_n))) continue
        dep = dy[|(1) \ (min_n)|]
        X1 = (J(min_n,1,1), y_lag[|(1) \ (min_n)|], x_lag[|(1), 1 \ (min_n), cols(x_lag)|], dx[|(1), 1 \ (min_n), cols(dx)|])
        X2 = X1
        X = (X1 :* It, X2 :* (1:-It))
        rr = tc_ols(dep, X)
        t_val = rr.tstat[2]
        if (abs(t_val) > abs(best_stat)) {
            best_stat = t_val
            best_th = tau
        }
    }
    cvs = tc_cv_adl_bdm(m, cse)
    out.test_name = "ADL-BDM test (Li & Lee 2010)"
    out.sup_t = best_stat
    out.threshold = best_th
    out.cv = cvs
    out.conclusion = (best_stat < cvs[2] ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    return(out)
}

// ====================================================================
//   7. ADL-BO (Li & Lee 2010)
// ====================================================================

struct tc_thres_t scalar tc_adl_bo(real colvector y, real matrix x, real scalar maxlag,
        real scalar trim, real scalar n_grid, string scalar cse)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real colvector dy, de, y_lag, dep, dde, grid, It
    real matrix dx, x_lag, X
    real scalar T, n, m, i, j, qv, tau, wald, best_stat, best_th, min_n, kt
    real rowvector cvs
    T = rows(y)
    m = cols(x)
    dy = y[|(2) \ (T)|] - y[|(1) \ ((T-1))|]
    dx = x[|(2), 1 \ (T), cols(x)|] :- x[|(1), 1 \ ((T-1)), cols(x)|]
    n = T - 1
    y_lag = y[|(1) \ ((T-1))|]
    x_lag = x[|(1), 1 \ ((T-1)), cols(x)|]
    lr = tc_ols(y, x, 1)
    de = lr.resid[|(2) \ (T)|] - lr.resid[|(1) \ ((T-1))|]
    min_n = (((n)<(rows(de)))? (n) : (rows(de)))
    dde = de[|(1) \ (min_n)|]
    grid = J(n_grid,1,.)
    for (j=1; j<=n_grid; j++) {
        qv = trim + (1-2*trim)*(j-1)/(n_grid-1)
        grid[j] = tc_quantile(dde, qv)
    }
    grid = uniqrows(grid)
    best_stat = 0
    best_th = 0
    for (i=1; i<=rows(grid); i++) {
        tau = grid[i]
        It = (dde :>= tau)
        if (sum(It) < (((5)>(trim*min_n))? (5) : (trim*min_n)) | min_n - sum(It) < (((5)>(trim*min_n))? (5) : (trim*min_n))) continue
        dep = dy[|(1) \ (min_n)|]
        X = (J(min_n,1,1),
             y_lag[|(1) \ (min_n)|] :* It, x_lag[|(1), 1 \ (min_n), cols(x_lag)|] :* It,
             y_lag[|(1) \ (min_n)|] :* (1:-It), x_lag[|(1), 1 \ (min_n), cols(x_lag)|] :* (1:-It),
             dx[|(1), 1 \ (min_n), cols(dx)|])
        rr = tc_ols(dep, X)
        kt = 1 + m
        wald = sum(rr.tstat[|(2) \ ((1+kt))|]:^2)
        if (wald > best_stat) {
            best_stat = wald
            best_th = tau
        }
    }
    cvs = tc_cv_adl_bo(m, cse)
    out.test_name = "ADL-BO test (Li & Lee 2010)"
    out.sup_wald = best_stat
    out.threshold = best_th
    out.cv = cvs
    out.conclusion = (best_stat > cvs[2] ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    return(out)
}

// ====================================================================
//   8. System ADL (Li 2016)
// ====================================================================

struct tc_thres_t scalar tc_system_adl(real matrix data, real scalar lag, real scalar trim,
        real scalar n_grid, string scalar cse)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real matrix dY, Y_lag, x_rest, X
    real colvector de, dde, grid, It
    real scalar T, k, n, min_n, i, j, qv, tau, total_wald, best_stat, best_th, col
    T = rows(data)
    k = cols(data)
    dY = data[|(2), 1 \ (T), cols(data)|] :- data[|(1), 1 \ ((T-1)), cols(data)|]
    n = T - 1
    Y_lag = data[|(1), 1 \ ((T-1)), cols(data)|]
    x_rest = data[|1, (2) \ rows(data), (k)|]
    lr = tc_ols(data[.,1], x_rest, 1)
    de = lr.resid[|(2) \ (T)|] - lr.resid[|(1) \ ((T-1))|]
    min_n = (((n)<(rows(de)))? (n) : (rows(de)))
    dde = de[|(1) \ (min_n)|]
    grid = J(n_grid,1,.)
    for (j=1; j<=n_grid; j++) {
        qv = trim + (1-2*trim)*(j-1)/(n_grid-1)
        grid[j] = tc_quantile(dde, qv)
    }
    grid = uniqrows(grid)
    best_stat = 0
    best_th = 0
    for (i=1; i<=rows(grid); i++) {
        tau = grid[i]
        It = (dde :>= tau)
        if (sum(It) < (((5)>(trim*min_n))? (5) : (trim*min_n)) | min_n - sum(It) < (((5)>(trim*min_n))? (5) : (trim*min_n))) continue
        X = (J(min_n,1,1), Y_lag[|(1), 1 \ (min_n), cols(Y_lag)|] :* It, Y_lag[|(1), 1 \ (min_n), cols(Y_lag)|] :* (1:-It))
        total_wald = 0
        for (col=1; col<=k; col++) {
            rr = tc_ols(dY[|(1),(col) \ (min_n),(col)|], X)
            total_wald = total_wald + sum(rr.tstat[|(2) \ ((1+k))|]:^2)
        }
        if (total_wald > best_stat) {
            best_stat = total_wald
            best_th = tau
        }
    }
    out.test_name = "System ADL test (Li 2016)"
    out.sup_wald  = best_stat
    out.threshold = best_th
    out.lags      = lag
    return(out)
}

// ====================================================================
//   9. supF* (Schweikert 2019)
// ====================================================================

struct tc_thres_t scalar tc_supf(real colvector y, real matrix x, string scalar model,
        real scalar breaktype, real scalar maxlag, real scalar threshold,
        real scalar u, real scalar trim, string scalar crit)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr
    real colvector time, DU, z, lz, dz, ldz, pos, neg, ind, valid_ldz, mask, sidx, lc, bp_hits
    real matrix Xreg, Xtar
    real colvector fphi, fapt, rho1arr, rho2arr
    real scalar n, startp, endp, i, j, thrV, breakp, best_k, fstar, om
    real rowvector cvs
    string scalar bk_name
    n = rows(y)
    time = (1::n)
    startp = (((1)>(floor(trim*n)))? (1) : (floor(trim*n)))
    endp   = (((n)<(floor((1-trim)*n)))? (n) : (floor((1-trim)*n)))
    fphi = J(n,1,0)
    fapt = J(n,1,0)
    rho1arr = J(n,1,0)
    rho2arr = J(n,1,0)
    best_k = 0

    for (i=startp; i<=endp; i++) {
        DU = (time :>= i)
        if      (breaktype==1) Xreg = x
        else if (breaktype==2) Xreg = (x, DU)
        else if (breaktype==3) Xreg = (x, DU, time)
        else if (breaktype==4) Xreg = (x, DU, x :* DU)
        else                    Xreg = x

        lr = tc_ols(y, Xreg, 1)
        z = lr.resid
        lz = (. \ z[|(1) \ ((n-1))|])
        dz = z - lz
        ldz = (. \ dz[|(1) \ ((n-1))|])
        if (model=="tar") ind = (lz :>= threshold)
        else {
            if (u != .) {
                valid_ldz = select(ldz, ldz:!=.)
                thrV = tc_quantile(valid_ldz, u)
            }
            else thrV = threshold
            ind = (ldz :>= thrV)
        }
        pos = lz :* ind
        neg = lz :* (1 :- ind)
        Xtar = (pos, neg)
        if (maxlag > 0) {
            for (j=1; j<=maxlag; j++) {
                lc = (J(j,1,.) \ dz[|(1) \ ((n-j))|])
                Xtar = (Xtar, lc)
            }
        }
        mask = J(n,1,1)
        for (j=1; j<=cols(Xtar); j++) mask = mask :* (Xtar[.,j] :!= .)
        mask = mask :* (dz :!= .)
        if (sum(mask) < cols(Xtar) + 2) {
            if (breaktype==1) break
            continue
        }
        sidx = selectindex(mask)
        rr = tc_ols(dz[sidx], Xtar[sidx,.])
        rho1arr[i] = rr.b[1]
        rho2arr[i] = rr.b[2]
        fphi[i] = (rr.tstat[1]^2 + rr.tstat[2]^2)/2
        om = rr.vcov[1,1] + rr.vcov[2,2]
        fapt[i] = (om > 0 ? (rr.b[1]-rr.b[2])^2/om : 0)
        best_k = maxlag
        if (breaktype==1) break
    }
    fstar = max(fphi)
    bp_hits = selectindex(fphi :== fstar)
    if (rows(bp_hits) == 0) breakp = 1
    else                     breakp = bp_hits[1]
    if      (breaktype==2) bk_name = "C0"
    else if (breaktype==3) bk_name = "CT"
    else if (breaktype==4) bk_name = "CS"
    else                    bk_name = "no_break"
    cvs = tc_cv_supf(bk_name, model)
    out.test_name = "supF* test (Schweikert 2019)"
    out.model     = model
    out.f_star    = fstar
    out.f_asymmetry = fapt[breakp]
    out.rho1 = rho1arr[breakp]
    out.rho2 = rho2arr[breakp]
    out.breakpoint = (breaktype > 1 ? breakp : .)
    out.lags = best_k
    out.breaktype_name = bk_name
    out.cv = cvs
    out.conclusion = (fstar > cvs[2] ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    return(out)
}

// ====================================================================
//   10. Hansen-Seo (2002) supLM
// ====================================================================

struct tc_thres_t scalar tc_hansen_seo(real matrix data, real scalar lag, real scalar beta_in,
        real scalar trim, real scalar n_grid)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr1, rr2
    real colvector ect, w0, ects, gammas, store, e1, e2, d1, s, ix, idx_valid, hs_hits
    real matrix dY, Y, X, Xfull, DeltaX, z1, res_unr, zea, zeb, ze, v, VV, VVinv, z11y, XtXinv
    real scalar T, k, p, t, betaval, lo, hi, j, gamma, n1, teststat, maxTh
    T = rows(data)
    k = cols(data)
    p = lag
    if (beta_in==.) {
        lr = tc_ols(data[.,1], data[|1, (2) \ rows(data), (k)|], 1)
        betaval = (k > 1 ? lr.b[2] : 1)
    } else betaval = beta_in
    ect = data[.,1] - betaval :* data[.,2]
    dY = data[|(2), 1 \ (T), cols(data)|] :- data[|(1), 1 \ ((T-1)), cols(data)|]
    Y = dY[|((p+1)), 1 \ (rows(dY)), cols(dY)|]
    t = rows(Y)
    if (p > 0) {
        DeltaX = J(t,0,.)
        for (j=1; j<=p; j++) DeltaX = (DeltaX, dY[|((p-j+1)), 1 \ ((t+p-j)), cols(dY)|])
        X = (J(t,1,1), DeltaX)
    } else X = J(t,1,1)
    w0 = ect[|((p+1)) \ ((p+t))|]
    ects = sort(w0,1)
    lo = (((1)>(floor(trim*t)))? (1) : (floor(trim*t)))
    hi = (((t)<(floor((1-trim)*t)))? (t) : (floor((1-trim)*t)))
    if (n_grid > (hi - lo + 1)) n_grid = hi - lo + 1
    ix = tc_pick(hi - lo + 1, n_grid) :+ (lo - 1)
    gammas = uniqrows(ects[ix])
    Xfull = (w0, X)
    rr1 = tc_ols(Y[.,1], Xfull)
    e1 = rr1.resid
    if (k > 1) {
        rr2 = tc_ols(Y[.,2], Xfull)
        e2 = rr2.resid
    } else e2 = e1
    XtXinv = invsym(quadcross(Xfull,Xfull))
    store = J(rows(gammas),1,.)
    for (j=1; j<=rows(gammas); j++) {
        gamma = gammas[j]
        d1 = (w0 :<= gamma)
        n1 = sum(d1)
        if ((((n1)<(t - n1))? (n1) : (t - n1)) <= trim*t) continue
        z1 = Xfull :* d1
        res_unr = z1 - Xfull * (XtXinv * quadcross(Xfull, z1))
        zea = e1 :* res_unr
        zeb = e2 :* res_unr
        ze  = (zea, zeb)
        v   = quadcross(ze, ze)
        if (k > 1) z11y = (res_unr' * Y[.,1], res_unr' * Y[.,2])
        else        z11y = res_unr' * Y[.,1]
        s = vec(z11y)
        VV = v' * v
        VVinv = invsym(VV)
        store[j] = (s' * VVinv * v' * s)
    }
    idx_valid = selectindex(store:!=.)
    if (rows(idx_valid) == 0) {
        teststat = .
        maxTh = gammas[1]
    }
    else {
        teststat = max(store[idx_valid])
        hs_hits = selectindex(store :== teststat)
        if (rows(hs_hits) == 0) maxTh = gammas[1]
        else                     maxTh = gammas[hs_hits[1]]
    }
    out.test_name = "Hansen-Seo (2002) supLM test"
    out.sup_lm = teststat
    out.threshold = maxTh
    out.beta_est = betaval
    out.lags = lag
    out.grid_values = gammas
    out.grid_stats  = store
    return(out)
}

// ====================================================================
//   11. KSS (2006) Nonlinear Cointegration
// ====================================================================

struct tc_thres_t scalar tc_kss(real colvector y, real matrix x, real scalar caseN,
        real scalar maxlag, string scalar crit)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar lr, rr, lr_y, lr_xj
    real colvector u, du, uc, dep, y_dt, ucp, trend
    real matrix Mx, lags_mat, x_dt
    real scalar T, n, p, bestlag, bestic, ic, j, tstat
    real rowvector cvs
    string scalar cs
    T = rows(y)
    if (caseN==1) {
        lr = tc_ols(y, x)
    }
    else if (caseN==2) {
        lr = tc_ols(y :- mean(y), x :- mean(x))
    }
    else {
        trend = (1::T)
        lr_y = tc_ols(y, trend, 1)
        y_dt = lr_y.resid
        x_dt = J(T, cols(x), .)
        for (j=1; j<=cols(x); j++) {
            lr_xj = tc_ols(x[.,j], trend, 1)
            x_dt[.,j] = lr_xj.resid
        }
        lr = tc_ols(y_dt, x_dt)
    }
    u = lr.resid
    du = u[|(2) \ (T)|] - u[|(1) \ ((T-1))|]
    uc = u[|(1) \ ((T-1))|]:^3
    bestlag = 0
    bestic = .
    for (p=0; p<=maxlag; p++) {
        if (p==0) {
            rr = tc_ols(du, uc)
        } else {
            Mx = tc_embed(du, p+1)
            dep = Mx[.,1]
            lags_mat = Mx[|1, (2) \ rows(Mx), ((p+1))|]
            ucp = uc[|((p+1)) \ (rows(uc))|]
            if (rows(ucp) > rows(dep)) ucp = ucp[|(1) \ (rows(dep))|]
            else if (rows(ucp) < rows(dep)) dep = dep[|(1) \ (rows(ucp))|]
            rr = tc_ols(dep, (ucp, lags_mat))
        }
        ic = (crit=="bic" ? rr.bic : rr.aic)
        if (ic < bestic | bestic==.) {
            bestic = ic
            bestlag = p
        }
    }
    if (bestlag==0) rr = tc_ols(du, uc)
    else {
        Mx = tc_embed(du, bestlag+1)
        dep = Mx[.,1]
        lags_mat = Mx[|1, (2) \ rows(Mx), ((bestlag+1))|]
        ucp = uc[|((bestlag+1)) \ (rows(uc))|]
        if (rows(ucp) > rows(dep)) ucp = ucp[|(1) \ (rows(dep))|]
        else if (rows(ucp) < rows(dep)) dep = dep[|(1) \ (rows(ucp))|]
        rr = tc_ols(dep, (ucp, lags_mat))
    }
    tstat = rr.tstat[1]
    cs = (caseN==3 ? "detrended" : "raw")
    cvs = tc_cv_kss(cs)
    out.test_name = "KSS (2006) nonlinear cointegration test"
    out.t_stat = tstat
    out.lags   = bestlag
    out.cv     = cvs
    out.conclusion = (tstat < cvs[2] ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    return(out)
}

// ====================================================================
//   12. BBC (2004) Unit Root vs SETAR
// ====================================================================

struct tc_thres_t scalar tc_bbc(real colvector y_in, real scalar m, real scalar trim, string scalar tt)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar r0, rr
    real colvector y, dep, trans, sortv, grid, d_low, d_high, ix
    real matrix Mx, regs, X
    real scalar T, n, lo, hi, i, gam, best_stat, stat
    real rowvector cvs
    y = y_in :- mean(y_in)
    Mx = tc_embed(y, m+1)
    dep = Mx[.,1]
    regs = Mx[|1, (2) \ rows(Mx), ((m+1))|]
    trans = abs(Mx[.,2])
    n = rows(dep)
    sortv = sort(trans,1)
    lo = (((1)>(floor(trim*n)))? (1) : (floor(trim*n)))
    hi = (((n)<(floor((1-trim)*n)))? (n) : (floor((1-trim)*n)))
    grid = sortv[|(lo) \ (hi)|]
    if (rows(grid) > 200) {
        ix = tc_pick(rows(grid), 200)
        grid = grid[ix]
    }
    best_stat = -1e20
    for (i=1; i<=rows(grid); i++) {
        gam = grid[i]
        d_low  = (trans :<= gam)
        d_high = (trans  :> gam)
        if (sum(d_low) < m+2 | sum(d_high) < m+2) continue
        X = (d_low :* (J(n,1,1), regs), d_high :* (J(n,1,1), regs))
        rr = tc_ols(dep, X)
        if (tt=="LR") {
            r0 = tc_ols(dep, regs)
            stat = n * ln(r0.ssr / rr.ssr)
        }
        else stat = sum(rr.tstat[|(1) \ (2)|]:^2)
        if (stat > best_stat) best_stat = stat
    }
    cvs = tc_cv_bbc(tt)
    out.test_name = "BBC (2004) unit root vs SETAR test"
    out.sup_stat  = best_stat
    out.cv        = cvs
    out.conclusion = (best_stat > cvs[2] ? "Reject H0 at 5%" : "Fail to reject H0 at 5%")
    return(out)
}

// ====================================================================
//   Model fitting:  TAR/MTAR, EQ-TAR, RD-TAR, SETAR, TVECM
// ====================================================================

struct tc_thres_t scalar tc_tar_fit(real colvector e_in, real scalar threshold, real scalar maxlag,
        string scalar crit, string scalar model_choice)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar rr
    real colvector e, de, e_lag, de_lag, dep, el, iv, iv2, iv3, It, pos, neg
    real matrix X, L
    real scalar T, n, p, bestlag, bestic, start, nobs, ic, rho1, rho2, t1, t2, phi, omega, fasy
    e = e_in
    T = rows(e)
    n = T - 1
    de = e[|(2) \ (T)|] - e[|(1) \ ((T-1))|]
    e_lag = e[|(1) \ ((T-1))|]
    if (model_choice=="mtar") {
        de_lag = (0 \ de[|(1) \ ((n-1))|])
        iv = de_lag
    } else iv = e_lag

    bestlag = 0
    bestic = .
    for (p=0; p<=maxlag; p++) {
        start = (((p)>(1))? (p) : (1))
        nobs = n - start
        if (nobs < 10) continue
        dep = de[|((start+1)) \ (n)|]
        el  = e_lag[|((start+1)) \ (n)|]
        iv2 = iv[|((start+1)) \ (n)|]
        It  = (iv2 :>= threshold)
        pos = el :* It
        neg = el :* (1:-It)
        X = (pos, neg)
        if (p>0) {
            L = tc_lagmat(de, p)
            X = (X, L[|((rows(L)-nobs+1)), 1 \ (rows(L)), cols(L)|])
        }
        rr = tc_ols(dep, X)
        ic = (crit=="bic" ? rr.bic : rr.aic)
        if (ic < bestic | bestic==.) {
            bestic = ic
            bestlag = p
        }
    }
    p = bestlag
    start = (((p)>(1))? (p) : (1))
    nobs = n - start
    dep = de[|((start+1)) \ (n)|]
    el  = e_lag[|((start+1)) \ (n)|]
    iv3 = iv[|((start+1)) \ (n)|]
    It = (iv3 :>= threshold)
    pos = el :* It
    neg = el :* (1:-It)
    X = (pos, neg)
    if (p>0) {
        L = tc_lagmat(de, p)
        X = (X, L[|((rows(L)-nobs+1)), 1 \ (rows(L)), cols(L)|])
    }
    rr = tc_ols(dep, X)
    rho1 = rr.b[1]
    rho2 = rr.b[2]
    t1 = rr.tstat[1]
    t2 = rr.tstat[2]
    phi = (t1^2 + t2^2)/2
    omega = rr.vcov[1,1] + rr.vcov[2,2] - 2*rr.vcov[1,2]
    fasy = (omega > 0 ? (rho1-rho2)^2/omega : 0)
    out.test_name = (model_choice=="mtar" ? "MTAR model fit" : "TAR model fit")
    out.model = model_choice
    out.rho1 = rho1
    out.rho2 = rho2
    out.t_rho1 = t1
    out.t_rho2 = t2
    out.phi_stat = phi
    out.f_asymmetry = fasy
    out.threshold = threshold
    out.lags = p
    out.nregime1 = sum(It)
    out.nregime2 = nobs - sum(It)
    return(out)
}

// Build a 3-regime indicator: 0 if e<=-th, 2 if e>=+th, 1 otherwise.
real colvector tc_band_regime(real colvector e, real scalar th)
{
    real colvector r
    r = J(rows(e),1,1)                // start: middle
    r = r :+ (e :>= th)               // +1 if high
    r = r :- (e :<= -th)              // -1 if low
    return(r)
}

real rowvector tc_eqtar_search(real colvector e, real scalar trim, real scalar n_grid,
        real scalar maxlag, real scalar use_drift)
{
    real colvector de, el, sortabs, grid, regime, m0, m1, m2, dep
    real matrix X, L
    real scalar n, i, lo, hi, th, ssr, best_ssr, best_th
    struct tc_ols_t scalar rr
    n = rows(e) - 1
    de = e[|(2) \ ((n+1))|] - e[|(1) \ (n)|]
    el = e[|(1) \ (n)|]
    sortabs = sort(abs(el),1)
    lo = (((1)>(floor(trim*n)))? (1) : (floor(trim*n)))
    hi = (((n)<(floor((1-trim)*n)))? (n) : (floor((1-trim)*n)))
    if (lo >= hi) return((0, .))
    grid = tc_seq(sortabs[lo], sortabs[hi], n_grid)
    best_ssr = .
    best_th = grid[1]
    for (i=1; i<=rows(grid); i++) {
        th = grid[i]
        regime = tc_band_regime(el, th)
        m0 = (regime:==0)
        m1 = (regime:==1)
        m2 = (regime:==2)
        if (sum(m0) < 5 | sum(m1) < 5 | sum(m2) < 5) continue
        if (use_drift) X = (m0, m1, m2)
        else            X = (el:*m0, el:*m1, el:*m2)
        if (maxlag > 0) {
            L = tc_lagmat(de, maxlag)
            dep = de[|((maxlag+1)) \ (n)|]
            rr = tc_ols(dep, (X[|((maxlag+1)), 1 \ (n), cols(X)|], L))
        } else rr = tc_ols(de, X)
        ssr = rr.ssr
        if (ssr < best_ssr | best_ssr==.) {
            best_ssr = ssr
            best_th = th
        }
    }
    return((best_th, best_ssr))
}

struct tc_thres_t scalar tc_eqtar_fit(real colvector e, real scalar threshold_in, real scalar maxlag,
        real scalar trim, real scalar n_grid, real scalar use_drift)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar rr
    real colvector de, el, regime, m0, m1, m2, dep
    real matrix X, L
    real scalar n, threshold, th
    real rowvector srch
    n = rows(e) - 1
    de = e[|(2) \ ((n+1))|] - e[|(1) \ (n)|]
    el = e[|(1) \ (n)|]
    if (threshold_in==.) {
        srch = tc_eqtar_search(e, trim, n_grid, maxlag, use_drift)
        threshold = srch[1]
    } else threshold = threshold_in
    th = abs(threshold)
    regime = tc_band_regime(el, th)
    m0 = (regime:==0)
    m1 = (regime:==1)
    m2 = (regime:==2)
    if (use_drift) X = (m0, m1, m2)
    else            X = (el:*m0, el:*m1, el:*m2)
    if (maxlag > 0) {
        L = tc_lagmat(de, maxlag)
        dep = de[|((maxlag+1)) \ (n)|]
        rr = tc_ols(dep, (X[|((maxlag+1)), 1 \ (n), cols(X)|], L))
    } else rr = tc_ols(de, X)
    if (use_drift) {
        out.test_name  = "RD-TAR (Balke-Fomby 1997)"
        out.drift_low  = rr.b[1]
        out.drift_mid  = rr.b[2]
        out.drift_high = rr.b[3]
    } else {
        out.test_name = "EQ-TAR / Band-TAR (Balke-Fomby 1997)"
        out.rho1 = rr.b[1]
        out.rho_mid = rr.b[2]
        out.rho2 = rr.b[3]
    }
    out.threshold = th
    out.lags = maxlag
    out.nregime1 = sum(m0)
    out.nregime2 = sum(m2)
    return(out)
}

// ============= SETAR =============

struct tc_thres_t scalar tc_setar_fit(real colvector y, real scalar lag, real scalar delay,
        real scalar threshold_in, real scalar trim, real scalar n_grid)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar rr
    real matrix M, regs, X
    real colvector dep, trans, sortv, grid, d, ix
    real scalar n, T, lo, hi, i, th, best_ssr, best_th
    T = rows(y)
    M = tc_embed(y, lag+1)
    dep = M[.,1]
    regs = M[|1, (2) \ rows(M), ((lag+1))|]
    trans = (delay <= lag ? M[., delay+1] : M[.,2])
    n = rows(dep)
    if (threshold_in==.) {
        sortv = sort(trans,1)
        lo = (((1)>(floor(trim*n)))? (1) : (floor(trim*n)))
        hi = (((n)<(floor((1-trim)*n)))? (n) : (floor((1-trim)*n)))
        grid = sortv[|(lo) \ (hi)|]
        if (rows(grid) > n_grid) {
            ix = tc_pick(rows(grid), n_grid)
            grid = grid[ix]
        }
        best_ssr = .
        best_th = grid[1]
        for (i=1; i<=rows(grid); i++) {
            th = grid[i]
            d = (trans :< th)
            if (sum(d) < (((5)>(trim*n))? (5) : (trim*n)) | n - sum(d) < (((5)>(trim*n))? (5) : (trim*n))) continue
            X = (J(n,1,1):*d, regs:*d, J(n,1,1):*(1:-d), regs:*(1:-d))
            rr = tc_ols(dep, X)
            if (rr.ssr < best_ssr | best_ssr==.) {
                best_ssr = rr.ssr
                best_th = th
            }
        }
        th = best_th
    } else th = threshold_in
    d = (trans :< th)
    X = (J(n,1,1):*d, regs:*d, J(n,1,1):*(1:-d), regs:*(1:-d))
    rr = tc_ols(dep, X)
    out.test_name = "SETAR(2)"
    out.threshold = th
    out.lags = lag
    out.ssr_total = rr.ssr
    out.nregime1 = sum(d)
    out.nregime2 = n - sum(d)
    return(out)
}

// ============= TVECM =============

struct tc_thres_t scalar tc_tvecm_fit(real matrix data, real scalar lag, real scalar trim,
        real scalar beta_in, real scalar n_grid)
{
    struct tc_thres_t scalar out
    struct tc_ols_t scalar rr, lr
    real matrix dY, Y, DeltaX, X_base, X
    real colvector ect, ect_lagged, gammas, q, d, ix
    real scalar T, k, p, t, betaval, lo, hi, j, gamma, n1, total_ssr, best_ssr, best_th, col
    T = rows(data)
    k = cols(data)
    p = lag
    if (beta_in==.) {
        lr = tc_ols(data[.,1], data[|1, (2) \ rows(data), (k)|], 1)
        betaval = (k > 1 ? lr.b[2] : 1)
    } else betaval = beta_in
    ect = data[.,1] - betaval :* data[.,2]
    dY = data[|(2), 1 \ (T), cols(data)|] :- data[|(1), 1 \ ((T-1)), cols(data)|]
    Y = dY[|((p+1)), 1 \ (rows(dY)), cols(dY)|]
    t = rows(Y)
    if (p > 0) {
        DeltaX = J(t,0,.)
        for (j=1; j<=p; j++) DeltaX = (DeltaX, dY[|((p-j+1)), 1 \ ((t+p-j)), cols(dY)|])
        X_base = (J(t,1,1), DeltaX)
    } else X_base = J(t,1,1)
    ect_lagged = ect[|((p+1)) \ ((p+t))|]
    q = sort(ect_lagged,1)
    lo = (((1)>(floor(trim*t)))? (1) : (floor(trim*t)))
    hi = (((t)<(floor((1-trim)*t)))? (t) : (floor((1-trim)*t)))
    if (n_grid > (hi - lo + 1)) n_grid = hi - lo + 1
    ix = tc_pick(hi - lo + 1, n_grid) :+ (lo - 1)
    gammas = uniqrows(q[ix])
    best_ssr = .
    best_th = gammas[trunc(rows(gammas)/2)+1]
    for (j=1; j<=rows(gammas); j++) {
        gamma = gammas[j]
        d = (ect_lagged :<= gamma)
        n1 = sum(d)
        if ((((n1)<(t - n1))? (n1) : (t - n1)) < trim*t) continue
        X = (ect_lagged :* d, X_base :* d, ect_lagged :* (1:-d), X_base :* (1:-d))
        total_ssr = 0
        for (col=1; col<=k; col++) {
            rr = tc_ols(Y[.,col], X)
            total_ssr = total_ssr + rr.ssr
        }
        if (total_ssr < best_ssr | best_ssr==.) {
            best_ssr = total_ssr
            best_th = gamma
        }
    }
    d = (ect_lagged :<= best_th)
    out.test_name = "TVECM (2 regimes)"
    out.threshold = best_th
    out.beta_est  = betaval
    out.lags = lag
    out.ssr_total = best_ssr
    out.nregime1 = sum(d)
    out.nregime2 = t - sum(d)
    out.grid_values = ect_lagged
    return(out)
}

// ====================================================================
//   Helper: read data from Stata variables into a column or matrix
// ====================================================================

real colvector tc_st_data1(string scalar varname, string scalar touse)
{
    real colvector v
    st_view(v=., ., varname, touse)
    return(v)
}

real matrix tc_st_dataM(string scalar varlist, string scalar touse)
{
    real matrix M
    st_view(M=., ., tokens(varlist), touse)
    return(M)
}

// ====================================================================
//   Result helpers -- push to Stata e()
// ====================================================================

void tc_post_thres(struct tc_thres_t scalar r)
{
    st_global("e(test_name)", r.test_name)
    if (r.model != "")        st_global("e(model)", r.model)
    if (r.conclusion != "")   st_global("e(conclusion)", r.conclusion)
    if (r.breaktype_name != "")  st_global("e(breaktype)", r.breaktype_name)
    if (r.phi_stat != .)      st_numscalar("e(phi_stat)", r.phi_stat)
    if (r.gls_phi_stat != .)  st_numscalar("e(gls_phi_stat)", r.gls_phi_stat)
    if (r.t_stat != .)        st_numscalar("e(t_stat)", r.t_stat)
    if (r.sup_wald != .)      st_numscalar("e(sup_wald)", r.sup_wald)
    if (r.sup_phi != .)       st_numscalar("e(sup_phi)", r.sup_phi)
    if (r.sup_lm != .)        st_numscalar("e(sup_lm)", r.sup_lm)
    if (r.sup_t != .)         st_numscalar("e(sup_t)", r.sup_t)
    if (r.sup_stat != .)      st_numscalar("e(sup_stat)", r.sup_stat)
    if (r.f_star != .)        st_numscalar("e(f_star)", r.f_star)
    if (r.f_asymmetry != .)   st_numscalar("e(f_asymmetry)", r.f_asymmetry)
    if (r.breakpoint != .)    st_numscalar("e(breakpoint)", r.breakpoint)
    if (r.rho1 != .)          st_numscalar("e(rho1)", r.rho1)
    if (r.rho2 != .)          st_numscalar("e(rho2)", r.rho2)
    if (r.rho_mid != .)       st_numscalar("e(rho_mid)", r.rho_mid)
    if (r.drift_low != .)     st_numscalar("e(drift_low)", r.drift_low)
    if (r.drift_mid != .)     st_numscalar("e(drift_mid)", r.drift_mid)
    if (r.drift_high != .)    st_numscalar("e(drift_high)", r.drift_high)
    if (r.t_rho1 != .)        st_numscalar("e(t_rho1)", r.t_rho1)
    if (r.t_rho2 != .)        st_numscalar("e(t_rho2)", r.t_rho2)
    if (r.threshold != .)     st_numscalar("e(threshold)", r.threshold)
    if (r.lags != .)          st_numscalar("e(lags)", r.lags)
    if (r.nregime1 != .)      st_numscalar("e(nregime1)", r.nregime1)
    if (r.nregime2 != .)      st_numscalar("e(nregime2)", r.nregime2)
    if (r.beta_est != .)      st_numscalar("e(beta_est)", r.beta_est)
    if (r.ssr_total != .)     st_numscalar("e(ssr)", r.ssr_total)
    if (cols(r.cv) >= 3) {
        st_matrix("e(cv)", r.cv)
        st_matrix_colstripe("e(cv)", (J(3,1,""), ("cv01" \ "cv05" \ "cv10")))
    }
}



// ====================================================================
//   tc_run_*  -- single-call helpers.  Each takes Stata scalar/matrix
//   names as output parameters and writes results to those tempnames.
//   The ado files just call `mata: tc_run_xxx(...)` once and then read
//   from the Stata scalars/matrices.
// ====================================================================

void tc_run_adf(string scalar yvar, string scalar touse,
                real scalar maxlag, string scalar cse, string scalar crit,
                string scalar n_stat, string scalar n_lags,
                string scalar n_nobs, string scalar n_cv)
{
    struct tc_adf_t scalar r
    r = tc_adf(st_data(., yvar, touse), maxlag, cse, crit)
    st_numscalar(n_stat, r.stat)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_nobs, r.nobs)
    st_matrix(n_cv, r.cv)
}

void tc_run_pp(string scalar yvar, string scalar touse,
               string scalar cse, real scalar lagsin,
               string scalar n_stat, string scalar n_lags,
               string scalar n_nobs, string scalar n_cv)
{
    struct tc_pp_t scalar r
    r = tc_pp(st_data(., yvar, touse), cse, lagsin)
    st_numscalar(n_stat, r.stat)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_nobs, r.nobs)
    st_matrix(n_cv, r.cv)
}

void tc_run_eg(string scalar yvar, string scalar xvars, string scalar touse,
               real scalar maxlag, string scalar cse, string scalar crit,
               string scalar n_stat, string scalar n_lags,
               string scalar n_nobs, string scalar n_m,
               string scalar n_cv, string scalar n_coint)
{
    struct tc_eg_t scalar r
    r = tc_eg(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
              maxlag, cse, crit)
    st_numscalar(n_stat, r.stat)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_nobs, r.nobs)
    st_numscalar(n_m,    r.m)
    st_matrix(n_cv, r.cv)
    st_matrix(n_coint, r.coint_vec)
}

void tc_run_es(string scalar yvar, string scalar xvars, string scalar touse,
               string scalar model, real scalar threshold, real scalar maxlag,
               string scalar crit, string scalar cse,
               string scalar n_phi, string scalar n_rho1, string scalar n_rho2,
               string scalar n_t1, string scalar n_t2, string scalar n_fasy,
               string scalar n_thr, string scalar n_lags,
               string scalar n_n1, string scalar n_n2, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_enders_siklos(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                         model, threshold, maxlag, crit, cse)
    st_numscalar(n_phi,  r.phi_stat)
    st_numscalar(n_rho1, r.rho1)
    st_numscalar(n_rho2, r.rho2)
    st_numscalar(n_t1,   r.t_rho1)
    st_numscalar(n_t2,   r.t_rho2)
    st_numscalar(n_fasy, r.f_asymmetry)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
    st_matrix(n_cv, r.cv)
}

void tc_run_glsmtar(string scalar yvar, string scalar xvars, string scalar touse,
                    real scalar threshold, real scalar maxlag,
                    string scalar cse, string scalar crit, real scalar cbar,
                    string scalar n_phi, string scalar n_rho1, string scalar n_rho2,
                    string scalar n_t1, string scalar n_t2,
                    string scalar n_thr, string scalar n_lags,
                    string scalar n_n1, string scalar n_n2, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_gls_mtar(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                    threshold, maxlag, cse, crit, cbar)
    st_numscalar(n_phi,  r.gls_phi_stat)
    st_numscalar(n_rho1, r.rho1)
    st_numscalar(n_rho2, r.rho2)
    st_numscalar(n_t1,   r.t_rho1)
    st_numscalar(n_t2,   r.t_rho2)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
    st_matrix(n_cv, r.cv)
}

void tc_run_exes(string scalar yvar, string scalar xvars, string scalar touse,
                 string scalar model, real scalar maxlag, string scalar crit,
                 real scalar trim, string scalar threshvar,
                 string scalar n_phi, string scalar n_rho1, string scalar n_rho2,
                 string scalar n_t1, string scalar n_t2, string scalar n_fasy,
                 string scalar n_thr, string scalar n_lags,
                 string scalar n_n1, string scalar n_n2)
{
    struct tc_thres_t scalar r
    real colvector tv
    if (threshvar == "") tv = J(0,1,.)
    else                  tv = st_data(., threshvar, touse)
    r = tc_ext_es(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                  tv, model, maxlag, crit, trim)
    st_numscalar(n_phi,  r.sup_phi)
    st_numscalar(n_rho1, r.rho1)
    st_numscalar(n_rho2, r.rho2)
    st_numscalar(n_t1,   r.t_rho1)
    st_numscalar(n_t2,   r.t_rho2)
    st_numscalar(n_fasy, r.f_asymmetry)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
}

void tc_run_covaug(string scalar yvar, string scalar xvars, string scalar touse,
                   string scalar model, real scalar threshold,
                   real scalar maxlag, string scalar crit,
                   string scalar n_phi, string scalar n_rho1, string scalar n_rho2,
                   string scalar n_t1, string scalar n_t2,
                   string scalar n_thr, string scalar n_n1, string scalar n_n2,
                   string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_covaug(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                  model, threshold, maxlag, crit)
    st_numscalar(n_phi,  r.phi_stat)
    st_numscalar(n_rho1, r.rho1)
    st_numscalar(n_rho2, r.rho2)
    st_numscalar(n_t1,   r.t_rho1)
    st_numscalar(n_t2,   r.t_rho2)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
    st_matrix(n_cv, r.cv)
}

void tc_run_bf(string scalar yvar, string scalar xvars, string scalar touse,
               real scalar maxlag, real scalar trim, real scalar ng,
               string scalar n_supw, string scalar n_thr, string scalar n_lags,
               string scalar n_gv, string scalar n_gs)
{
    struct tc_thres_t scalar r
    r = tc_balke_fomby(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                       maxlag, trim, ng)
    st_numscalar(n_supw, r.sup_wald)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
    st_matrix(n_gv, r.grid_values)
    st_matrix(n_gs, r.grid_stats)
}

void tc_run_adlbdm(string scalar yvar, string scalar xvars, string scalar touse,
                   real scalar maxlag, real scalar trim, real scalar ng,
                   string scalar cse,
                   string scalar n_stat, string scalar n_thr, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_adl_bdm(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                   maxlag, trim, ng, cse)
    st_numscalar(n_stat, r.sup_t)
    st_numscalar(n_thr,  r.threshold)
    st_matrix(n_cv, r.cv)
}

void tc_run_adlbo(string scalar yvar, string scalar xvars, string scalar touse,
                  real scalar maxlag, real scalar trim, real scalar ng,
                  string scalar cse,
                  string scalar n_stat, string scalar n_thr, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_adl_bo(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                  maxlag, trim, ng, cse)
    st_numscalar(n_stat, r.sup_wald)
    st_numscalar(n_thr,  r.threshold)
    st_matrix(n_cv, r.cv)
}

void tc_run_sysadl(string scalar vars, string scalar touse,
                   real scalar lag, real scalar trim, real scalar ng,
                   string scalar cse,
                   string scalar n_stat, string scalar n_thr, string scalar n_lags)
{
    struct tc_thres_t scalar r
    r = tc_system_adl(st_data(., tokens(vars), touse), lag, trim, ng, cse)
    st_numscalar(n_stat, r.sup_wald)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
}

void tc_run_supf(string scalar yvar, string scalar xvars, string scalar touse,
                 string scalar model, real scalar bt, real scalar maxlag,
                 real scalar threshold, real scalar u,
                 real scalar trim, string scalar crit,
                 string scalar n_fstar, string scalar n_fasy,
                 string scalar n_rho1, string scalar n_rho2,
                 string scalar n_lags, string scalar n_bp, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_supf(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
                model, bt, maxlag, threshold, u, trim, crit)
    st_numscalar(n_fstar, r.f_star)
    st_numscalar(n_fasy,  r.f_asymmetry)
    st_numscalar(n_rho1,  r.rho1)
    st_numscalar(n_rho2,  r.rho2)
    st_numscalar(n_lags,  r.lags)
    if (r.breakpoint != .) st_numscalar(n_bp, r.breakpoint)
    st_matrix(n_cv, r.cv)
}

void tc_run_hs(string scalar vars, string scalar touse,
               real scalar lag, real scalar betain,
               real scalar trim, real scalar ng,
               string scalar n_stat, string scalar n_thr,
               string scalar n_beta, string scalar n_lags,
               string scalar n_gv, string scalar n_gs)
{
    struct tc_thres_t scalar r
    r = tc_hansen_seo(st_data(., tokens(vars), touse), lag, betain, trim, ng)
    st_numscalar(n_stat, r.sup_lm)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_beta, r.beta_est)
    st_numscalar(n_lags, r.lags)
    st_matrix(n_gv, r.grid_values)
    st_matrix(n_gs, r.grid_stats)
}

void tc_run_kss(string scalar yvar, string scalar xvars, string scalar touse,
                real scalar caseN, real scalar maxlag, string scalar crit,
                string scalar n_stat, string scalar n_lags, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_kss(st_data(., yvar, touse), st_data(., tokens(xvars), touse),
               caseN, maxlag, crit)
    st_numscalar(n_stat, r.t_stat)
    st_numscalar(n_lags, r.lags)
    st_matrix(n_cv, r.cv)
}

void tc_run_bbc(string scalar yvar, string scalar touse,
                real scalar m, real scalar trim, string scalar tt,
                string scalar n_stat, string scalar n_cv)
{
    struct tc_thres_t scalar r
    r = tc_bbc(st_data(., yvar, touse), m, trim, tt)
    st_numscalar(n_stat, r.sup_stat)
    st_matrix(n_cv, r.cv)
}

void tc_run_tar(string scalar evar, string scalar touse,
                real scalar threshold, real scalar maxlag,
                string scalar crit, string scalar model,
                string scalar n_phi, string scalar n_rho1, string scalar n_rho2,
                string scalar n_t1, string scalar n_t2, string scalar n_fasy,
                string scalar n_thr, string scalar n_lags,
                string scalar n_n1, string scalar n_n2)
{
    struct tc_thres_t scalar r
    r = tc_tar_fit(st_data(., evar, touse), threshold, maxlag, crit, model)
    st_numscalar(n_phi,  r.phi_stat)
    st_numscalar(n_rho1, r.rho1)
    st_numscalar(n_rho2, r.rho2)
    st_numscalar(n_t1,   r.t_rho1)
    st_numscalar(n_t2,   r.t_rho2)
    st_numscalar(n_fasy, r.f_asymmetry)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
}

void tc_run_eqtar(string scalar evar, string scalar touse,
                  real scalar threshold_in, real scalar maxlag,
                  real scalar trim, real scalar ng, real scalar drift,
                  string scalar n_rho1, string scalar n_rmid, string scalar n_rho2,
                  string scalar n_dlow, string scalar n_dmid, string scalar n_dhigh,
                  string scalar n_thr, string scalar n_lags,
                  string scalar n_n1, string scalar n_n2)
{
    struct tc_thres_t scalar r
    r = tc_eqtar_fit(st_data(., evar, touse), threshold_in, maxlag, trim, ng, drift)
    st_numscalar(n_rho1,  r.rho1)
    st_numscalar(n_rmid,  r.rho_mid)
    st_numscalar(n_rho2,  r.rho2)
    st_numscalar(n_dlow,  r.drift_low)
    st_numscalar(n_dmid,  r.drift_mid)
    st_numscalar(n_dhigh, r.drift_high)
    st_numscalar(n_thr,   r.threshold)
    st_numscalar(n_lags,  r.lags)
    st_numscalar(n_n1,    r.nregime1)
    st_numscalar(n_n2,    r.nregime2)
}

void tc_run_setar(string scalar yvar, string scalar touse,
                  real scalar lag, real scalar delay,
                  real scalar threshold_in, real scalar trim, real scalar ng,
                  string scalar n_thr, string scalar n_lags,
                  string scalar n_n1, string scalar n_n2, string scalar n_ssr)
{
    struct tc_thres_t scalar r
    r = tc_setar_fit(st_data(., yvar, touse), lag, delay, threshold_in, trim, ng)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
    st_numscalar(n_ssr,  r.ssr_total)
}

void tc_run_tvecm(string scalar vars, string scalar touse,
                  real scalar lag, real scalar trim,
                  real scalar betain, real scalar ng,
                  string scalar n_thr, string scalar n_beta, string scalar n_lags,
                  string scalar n_n1, string scalar n_n2,
                  string scalar n_ssr, string scalar n_ect)
{
    struct tc_thres_t scalar r
    r = tc_tvecm_fit(st_data(., tokens(vars), touse), lag, trim, betain, ng)
    st_numscalar(n_thr,  r.threshold)
    st_numscalar(n_beta, r.beta_est)
    st_numscalar(n_lags, r.lags)
    st_numscalar(n_n1,   r.nregime1)
    st_numscalar(n_n2,   r.nregime2)
    st_numscalar(n_ssr,  r.ssr_total)
    st_matrix(n_ect, r.grid_values)
}


end
