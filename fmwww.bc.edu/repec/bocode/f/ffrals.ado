*! ffrals 1.0.0  23jul2026
*! Flexible-Fourier LM unit-root test with RALS and RALS2 (factor) augmentation
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
program ffrals, rclass
    version 14.0
    syntax varname(ts) [if] [in] , [ Rals(integer 0) Factors(varlist) ///
        Fmax(integer 4) Pmax(integer 8) IC(integer 3) ///
        Nsim(integer 50000) Seed(integer 2345) ]

    if !inlist(`rals',0,1,2) {
        di as error "rals() must be 0 (plain FLM), 1 (RALS) or 2 (RALS + factors)"
        exit 198
    }
    if `rals'==2 & "`factors'"=="" {
        di as error "rals(2) requires factors(varlist) (the common and group factors)"
        exit 198
    }
    if `ic'<1 | `ic'>3 {
        di as error "ic() must be 1 (AIC), 2 (BIC) or 3 (t-stat)"
        exit 198
    }

    marksample touse
    markout `touse' `factors'
    tsunab v : `varlist'
    tempname STAT
    mata: _ffr_run("`varlist'", "`factors'", "`touse'", `rals', ///
        `fmax', `pmax', `ic', `nsim', `seed', "`STAT'")

    // ---- display -----------------------------------------------------
    local lab = cond(`rals'==0,"Flexible-Fourier LM", ///
        cond(`rals'==1,"RALS Flexible-Fourier LM","RALS2 (factor) Flexible-Fourier LM"))
    di ""
    di as txt "`lab' unit-root test" _col(56) "Obs = " as res %5.0f `STAT'[1,7]
    di as txt "H0: unit root (nonstationary)"
    di as txt "{hline 64}"
    di as txt "Test statistic" _col(30) "= " as res %9.4f `STAT'[1,1]
    di as txt "Simulated p-value" _col(30) "= " as res %9.4f `STAT'[1,2]
    di as txt "Selected Fourier frequency" _col(30) "= " as res %9.0f `STAT'[1,3]
    di as txt "Selected lag" _col(30) "= " as res %9.0f `STAT'[1,4]
    if `rals'>=1 di as txt "RALS rho-squared" _col(30) "= " as res %9.4f `STAT'[1,5]
    di as txt "{hline 64}"
    di as txt "Simulated critical values:" _col(34) "1%" _col(46) "5%" _col(58) "10%"
    di as txt "  " _col(30) as res %10.3f `STAT'[1,8] %12.3f `STAT'[1,9] %12.3f `STAT'[1,10]
    di as txt "{hline 64}"
    di as txt "Reject H0 (=> stationary) for test statistic below the critical value."
    di as txt "p-values from `nsim' Monte-Carlo replications (seed `seed')."

    // ---- returns -----------------------------------------------------
    return scalar stat  = `STAT'[1,1]
    return scalar p     = `STAT'[1,2]
    return scalar freq  = `STAT'[1,3]
    return scalar lag   = `STAT'[1,4]
    if `rals'>=1 return scalar rho2 = `STAT'[1,5]
    return scalar cv1   = `STAT'[1,8]
    return scalar cv5   = `STAT'[1,9]
    return scalar cv10  = `STAT'[1,10]
    return scalar N     = `STAT'[1,7]
    return local  rals  "`rals'"
    return local  cmd   "ffrals"
end

version 14.0
mata:

real colvector _ffr_lagn(real colvector x, real scalar n)
{
    real scalar r
    r = rows(x)
    if (n > 0)  return((J(n,1,0) \ x[1..r-n]))
    if (n < 0)  return((x[(1-n)..r] \ J(-n,1,0)))
    return(x)
}
real matrix _ffr_lagnM(real matrix x, real scalar n)
{
    real scalar r
    r = rows(x)
    if (n > 0)  return((J(n,cols(x),0) \ x[1..r-n,.]))
    if (n < 0)  return((x[(1-n)..r,.] \ J(-n,cols(x),0)))
    return(x)
}
// GAUSS diff(x,1): leading zero then first differences (length preserved)
real colvector _ffr_diff(real colvector x)
{
    real scalar r
    r = rows(x)
    return((0 \ (x[2..r] - x[1..r-1])))
}
real colvector _ffr_diffv(real colvector x)
{
    return(_ffr_diff(x))
}
// OLS: returns b, e, sig2, se, ssr through arguments
void _ffr_ols(real colvector y, real matrix X, real colvector b,
    real colvector e, real scalar sig2, real colvector se, real scalar ssr)
{
    real matrix m
    m = invsym(cross(X,X))
    b = m*cross(X,y)
    e = y - X*b
    ssr = cross(e,e)
    sig2 = ssr/(rows(y)-cols(X))
    se = sqrt(diagonal(m)*sig2)
}
real scalar _ffr_argmin(real colvector v)
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
// LM score (detrended) series for one Fourier frequency k
real colvector _ffr_score(real colvector y, real scalar k)
{
    real scalar t
    real colvector dt, sink, cosk, dy, dsink, dcosk, b0, psi
    real matrix z, dz
    t = rows(y)
    dt = (1::t)
    sink = sin(2*pi()*k*(1::t)/t)
    cosk = cos(2*pi()*k*(1::t)/t)
    z = dt, sink, cosk
    dy = _ffr_diff(y)[2..t]
    dsink = _ffr_diff(sink)[2..t]
    dcosk = _ffr_diff(cosk)[2..t]
    dz = J(rows(dy),1,1), dsink, dcosk
    b0 = invsym(cross(dz,dz))*cross(dz,dy)
    psi = y[1] - (dz[1,.]*b0)[1,1]
    return((y :- psi) - z*b0)
}
// general-to-specific / IC lag selection given per-lag statistics
real scalar _ffr_getlag(real scalar ic, real scalar pmax,
    real colvector aicp, real colvector sicp, real colvector tp)
{
    real scalar lag, jj
    if (ic==1) return(_ffr_argmin(aicp))
    if (ic==2) return(_ffr_argmin(sicp))
    if (pmax==0) return(1)
    jj = pmax + 1
    lag = 1
    while (jj >= 1) {
        if (abs(tp[jj]) > 1.645) {
            lag = jj
            jj = 0
        }
        else jj = jj - 1
    }
    return(lag)
}
// LM regression at frequency k, lag p: returns residuals + stat via args
// z = [lag(score), const, dsin, dcos, (lagged dscore)]
void _ffr_lmreg(real colvector ylm, real scalar k, real scalar p,
    real colvector dep, real matrix z)
{
    real scalar t, j
    real colvector dy, ly, sink, cosk, y1, sbt, sinp, cosp
    real matrix lmat
    t = rows(ylm)
    dy = _ffr_diff(ylm)
    ly = _ffr_lagn(ylm,1)
    sink = _ffr_diff(sin(2*pi()*k*(1::t)/t))
    cosk = _ffr_diff(cos(2*pi()*k*(1::t)/t))
    lmat = J(t, p+1, 0)
    j = 1
    while (j <= p) {
        lmat[.,j] = _ffr_lagn(dy,j)
        j = j + 1
    }
    dep  = dy[(p+2)..t]
    y1   = ly[(p+2)..t]
    sbt  = J(rows(y1),1,1)
    sinp = sink[(p+2)..t]
    cosp = cosk[(p+2)..t]
    if (p==0) z = y1, sbt, sinp, cosp
    else      z = y1, sbt, sinp, cosp, lmat[(p+2)..t, 1..p]
}
// full Fourier LM with frequency search; returns (LM, f, lag)
real rowvector _ffr_flm(real colvector y, real scalar fmax, real scalar pmax, real scalar ic)
{
    real scalar k, p, f, lag, LM
    real colvector ssrk, tauk, ylm, dep, taup, aicp, sicp, tp, ssrp, b, e, se
    real scalar sig2, ssr
    real matrix z
    ssrk = J(fmax,1,0)
    tauk = J(fmax,1,0)
    k = 1
    while (k <= fmax) {
        ylm = _ffr_score(y, k)
        taup = J(pmax+1,1,0)
        aicp = J(pmax+1,1,0)
        sicp = J(pmax+1,1,0)
        tp   = J(pmax+1,1,0)
        ssrp = J(pmax+1,1,0)
        p = 0
        while (p <= pmax) {
            _ffr_lmreg(ylm, k, p, dep, z)
            _ffr_ols(dep, z, b, e, sig2, se, ssr)
            taup[p+1] = b[1]/se[1]
            aicp[p+1] = ln(cross(e,e)/rows(z)) + 2*(k+2)/rows(z)
            sicp[p+1] = ln(cross(e,e)/rows(z)) + (cols(z)+2)*ln(rows(z))/rows(z)
            tp[p+1]   = b[cols(z)]/se[cols(z)]
            ssrp[p+1] = ssr
            p = p + 1
        }
        lag = _ffr_getlag(ic, pmax, aicp, sicp, tp)
        ssrk[k] = ssrp[lag]
        tauk[k] = taup[lag]
        k = k + 1
    }
    f = _ffr_argmin(ssrk)
    LM = tauk[f]
    // recover the lag chosen AT frequency f (recompute selection)
    ylm = _ffr_score(y, f)
    taup = J(pmax+1,1,0); aicp = J(pmax+1,1,0); sicp = J(pmax+1,1,0); tp = J(pmax+1,1,0)
    p = 0
    while (p <= pmax) {
        _ffr_lmreg(ylm, f, p, dep, z)
        _ffr_ols(dep, z, b, e, sig2, se, ssr)
        taup[p+1] = b[1]/se[1]
        aicp[p+1] = ln(cross(e,e)/rows(z)) + 2*(f+2)/rows(z)
        sicp[p+1] = ln(cross(e,e)/rows(z)) + (cols(z)+2)*ln(rows(z))/rows(z)
        tp[p+1]   = b[cols(z)]/se[cols(z)]
        p = p + 1
    }
    lag = _ffr_getlag(ic, pmax, aicp, sicp, tp)
    return((LM, f, lag))
}
// null-distribution Fourier LM0 statistic for one random walk (frequency k)
real scalar _ffr_flm0(real colvector y, real scalar k)
{
    real scalar t
    real colvector dt, sink, cosk, dy, dsink, dcosk, b0, psi, s, s1, dyf, b, e, se
    real scalar sig2, ssr
    real matrix z, dz, x
    t = rows(y)
    dt = (1::t)
    sink = sin(2*pi()*k*(1::t)/t)
    cosk = cos(2*pi()*k*(1::t)/t)
    z = dt, sink, cosk
    dy = _ffr_diff(y)[2..t]
    dsink = _ffr_diff(sink)[2..t]
    dcosk = _ffr_diff(cosk)[2..t]
    dz = J(rows(dy),1,1), dsink, dcosk
    b0 = invsym(cross(dz,dz))*cross(dz,dy)
    psi = y[1] - (dz[1,.]*b0)[1,1]
    s = (y :- psi) - z*b0
    s1 = _ffr_lagn(s,1)[2..t]
    dyf = _ffr_diff(y)[2..t]
    x = s1, dz
    _ffr_ols(dyf, x, b, e, sig2, se, ssr)
    return(b[1]/se[1])
}
// simulate the FLM0 null distribution (nsim random walks of length T, freq k)
real colvector _ffr_mcdist(real scalar T, real scalar k, real scalar nsim)
{
    real colvector MCt, e, y
    real scalar s
    MCt = J(nsim,1,0)
    s = 1
    while (s <= nsim) {
        e = rnormal(T,1,0,1)
        y = runningsum(e)
        MCt[s] = _ffr_flm0(y, k)
        s = s + 1
    }
    return(MCt)
}

// ---------- driver ---------------------------------------------------
void _ffr_run(string scalar vn, string scalar fv, string scalar touse,
    real scalar rals, real scalar fmax, real scalar pmax, real scalar ic,
    real scalar nsim, real scalar seed, string scalar statname)
{
    real colvector y, dep, ly, e1, se, b, e2, e3, w2, w3, MCt, MCr, Zdraw, cvv
    real matrix z, x, more, w
    real rowvector flm
    real scalar T, f, lag, LM, stat, p2, sig2, sig2A, ssr, m2, m3, pval, k
    y = st_data(., vn, touse)
    T = rows(y)
    flm = _ffr_flm(y, fmax, pmax, ic)
    LM = flm[1]
    f  = flm[2]
    lag = flm[3]
    k = f
    stat = LM
    p2 = .
    rseed(seed)
    MCt = _ffr_mcdist(T, k, nsim)
    if (rals==0) {
        pval = mean(MCt :<= LM)
        cvv = _ffr_quantile(MCt, (0.01\0.05\0.10))
    }
    else {
        // re-detrend at selected f and build the LM regression at chosen lag
        real colvector ylm
        ylm = _ffr_score(y, f)
        _ffr_lmreg(ylm, f, lag, dep, z)
        _ffr_ols(dep, z, b, e1, sig2, se, ssr)
        e2 = e1:^2
        e3 = e1:^3
        m2 = sum(e2)/T
        m3 = sum(e3)/T
        w = (e2 :- m2), (e3 :- m3 :- 3*m2*e1)
        if (rals==2 & fv!="") {
            more = st_data(., fv, touse)
            more = more[(rows(more)-rows(dep)+1)..rows(more), .]
            x = z, w, more
        }
        else x = z, w
        _ffr_ols(dep, x, b, e1, sig2A, se, ssr)
        stat = b[1]/se[1]
        p2 = sig2A/sig2
        // RALS null distribution: sqrt(p2)*FLM0 + sqrt(1-p2)*N(0,1)
        Zdraw = rnormal(nsim,1,0,1)
        MCr = sqrt(p2):*MCt + sqrt(1-p2):*Zdraw
        pval = mean(MCr :< stat)
        cvv = _ffr_quantile(MCr, (0.01\0.05\0.10))
    }
    st_matrix(statname, (stat, pval, f, lag-1, p2, ., T, cvv[1], cvv[2], cvv[3]))
}
real colvector _ffr_quantile(real colvector x, real colvector q)
{
    real colvector xs, out
    real scalar i, n, h
    xs = sort(x, 1)
    n = rows(xs)
    out = J(rows(q),1,0)
    i = 1
    while (i <= rows(q)) {
        h = q[i]*n
        if (h < 1) out[i] = xs[1]
        else if (h >= n) out[i] = xs[n]
        else out[i] = xs[floor(h)] + (h-floor(h))*(xs[floor(h)+1]-xs[floor(h)])
        i = i + 1
    }
    return(out)
}

end
