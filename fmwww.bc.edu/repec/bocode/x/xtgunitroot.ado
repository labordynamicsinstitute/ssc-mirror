*! xtgunitroot version 1.0.0  28jun2026
*! Generalized fixed-T panel unit root test (doubly modified estimator, DME)
*! Karavias & Tzavalis (2019, Scandinavian Journal of Statistics) <doi:10.1111/sjos.12392>
*! Robust to serial correlation, heteroskedasticity, structural breaks
*! Author: Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

program define xtgunitroot, rclass
    version 14.0

    syntax varname(numeric) [if] [in] [ ,        ///
        Model(string)                            ///
        BReak(string)                            ///
        MAXLag(integer 0)                        ///
        BReps(integer 399)                       ///
        TRim(real 0.15)                          ///
        SEED(string)                             ///
        Level(cilevel) ]

    // ---- deterministic specification --------------------------------
    if ("`model'"=="") local model "intercept"
    local model = lower("`model'")
    if inlist("`model'","intercept","i","none","constant","c") {
        local mcode 1
        local mname "Individual intercepts"
    }
    else if inlist("`model'","trend","t") {
        local mcode 2
        local mname "Intercepts + individual trends"
    }
    else if inlist("`model'","break","b") {
        local mcode 3
        local mname "Intercepts with a structural break"
    }
    else if inlist("`model'","breaktrend","bt","trendbreak","tb") {
        local mcode 4
        local mname "Intercepts + trends with a structural break"
    }
    else {
        di as error "model() must be {bf:intercept}, {bf:trend}, {bf:break} or {bf:breaktrend}"
        exit 198
    }

    if (`mcode'==2 | `mcode'==4) {
        di as error "model(`model'): incidental-trend models are not available in this version."
        di as txt  "{p 6 6 2}The DME trend-nuisance (Pi_22) correction is still under"
        di as txt  "development. Note that fixed-T panel unit root tests have trivial local"
        di as txt  "power against incidental trends (Moon, Perron & Phillips 2007), so the"
        di as txt  "intercept/break specifications are the ones with useful power. Use"
        di as txt  "{bf:model(intercept)} or {bf:model(break)}.{p_end}"
        exit 198
    }

    if (`maxlag'<0) {
        di as error "maxlag() must be >= 0"
        exit 198
    }

    // ---- panel structure --------------------------------------------
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data are not {bf:xtset}; type {bf:xtset panelvar timevar} first"
        exit 459
    }
    marksample touse
    markout `touse' `ivar' `tvar'
    qui su `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    local Tplus1 = `tmax' - `tmin' + 1
    local T = `Tplus1' - 1
    if (`Tplus1'<4) {
        di as error "need at least 4 time periods on the grid"
        exit 198
    }

    tempvar gid ti
    qui egen long `gid' = group(`ivar') if `touse'
    qui gen long `ti'   = `tvar' - `tmin' + 1 if `touse'
    qui su `gid' if `touse', meanonly
    local Nunits = r(max)

    // ---- break point (equation index) -------------------------------
    local kb 0
    local bdesc "none"
    local unknown 0
    if (`mcode'>=3) {
        if ("`break'"=="") {
            di as error "model(`model') requires {bf:break()} — a date, a fraction in (0,1), or {bf:unknown}"
            exit 198
        }
        local blow = lower("`break'")
        if (inlist("`blow'","unknown","u","search")) {
            local unknown 1
            local kbmin = ceil(`trim'*`T')
            local kbmax = floor((1-`trim')*`T')
            if (`mcode'==4) {
                if (`kbmin'<3)     local kbmin 3
                if (`kbmax'>`T'-3) local kbmax = `T'-3
            }
            else {
                if (`kbmin'<2)     local kbmin 2
                if (`kbmax'>`T'-2) local kbmax = `T'-2
            }
            if (`kbmin'>`kbmax') {
                di as error "trim(`trim') leaves no admissible break dates for T=`T'"
                exit 198
            }
            local ngrid = `kbmax' - `kbmin' + 1
            local bdesc "unknown (inf-t over `ngrid' dates)"
        }
        else if (real("`break'")<1 & real("`break'")>0) {
            local kb = floor(real("`break'")*`T')
            local bdesc "fraction `break' (date `=`tmin'+`kb'')"
        }
        else if (real("`break'")!=.) {
            local kb = real("`break'") - `tmin'
            local bdesc "date `break'"
        }
        else {
            di as error "break() must be a date, a fraction in (0,1), or {bf:unknown}"
            exit 198
        }
        if (`unknown'==0 & (`kb'<1 | `kb'>`T'-1)) {
            di as error "break point falls outside the usable range"
            exit 198
        }
    }

    // ---- run the engine ---------------------------------------------
    tempname R PROF
    if (`unknown'==0) {
        mata: xtgur_engine("`varlist'","`gid'","`ti'","`touse'", `Tplus1', ///
            `mcode', `kb', `maxlag', "`R'")
        local phi   = `R'[1,1]
        local phidm = `R'[1,2]
        local bias  = `R'[1,3]
        local z     = `R'[1,4]
        local p     = `R'[1,5]
        local Nused = `R'[1,6]
        local Ndrop = `R'[1,7]
        local Teq   = `R'[1,8]
    }
    else {
        if ("`seed'"!="") set seed `seed'
        mata: xtgur_ubreak("`varlist'","`gid'","`ti'","`touse'", `Tplus1', ///
            `mcode', `kbmin', `kbmax', `maxlag', `breps', `tmin', "`R'", "`PROF'")
        local phi   = `R'[1,1]
        local phidm = `R'[1,2]
        local bias  = `R'[1,3]
        local z     = `R'[1,4]
        local p     = `R'[1,5]
        local Nused = `R'[1,6]
        local Ndrop = `R'[1,7]
        local Teq   = `R'[1,8]
        local kbhat = `R'[1,9]
        local cv05  = `R'[1,10]
        local cv10  = `R'[1,11]
        local cv01  = `R'[1,12]
        local kb    = `kbhat'
        local bdesc "unknown -> date `=`tmin'+`kbhat''"
    }

    local star ""
    if (`p'<0.10) local star "*"
    if (`p'<0.05) local star "**"
    if (`p'<0.01) local star "***"

    // ---- display ----------------------------------------------------
    di ""
    di as txt "{hline 72}"
    di as txt "  Generalized fixed-T panel unit root test (DME)"
    di as txt "  Karavias & Tzavalis (2019, {it:Scand. J. Statist.})"
    di as txt "{hline 72}"
    di as txt "  Panel variable          : " as res "`ivar'" as txt "   (N = " as res `Nunits' as txt ")"
    di as txt "  Time variable           : " as res "`tvar'" as txt "   (grid `tmin'..`tmax', T = " as res `Teq' as txt ")"
    di as txt "  Series tested           : " as res "`varlist'"
    di as txt "  Deterministics          : " as res "`mname'"
    if (`mcode'>=3) di as txt "  Structural break        : " as res "`bdesc'"
    di as txt "  Max serial-corr. order  : " as res `maxlag'
    di as txt "  Balanced units used     : " as res `Nused' as txt " / dropped (incomplete) " as res `Ndrop'
    di as txt "{hline 72}"
    if (`unknown'==0) {
        di as txt "  H0: panel has a unit root (phi = 1)   vs   H1: stationary (phi < 1)"
    }
    else {
        di as txt "  H0: unit root, no break   vs   H1: stationary with a break (unknown date)"
    }
    di as txt "{hline 72}"
    di as txt "  WG phi-hat              : " as res %9.4f `phi'
    di as txt "  DME phi-hat (corrected) : " as res %9.4f `phidm'
    di as txt "  bias correction (b/d)   : " as res %9.4f `bias'
    if (`unknown'==0) {
        di as txt "  z-statistic             : " as res %9.4f `z' as result "`star'"
        di as txt "  p-value (one-sided)     : " as res %9.4f `p'
    }
    else {
        di as txt "  Estimated break date    : " as res "`=`tmin'+`kbhat''" as txt "   (equation index `kbhat')"
        di as txt "  inf-t statistic         : " as res %9.4f `z' as result "`star'"
        di as txt "  bootstrap p-value       : " as res %9.4f `p'
        di as txt "  bootstrap crit. values  : " as txt "10% " as res %7.3f `cv10' ///
            as txt "   5% " as res %7.3f `cv05' as txt "   1% " as res %7.3f `cv01'
    }
    di as txt "{hline 72}"
    di as txt "  Reject H0 for small (negative) z.   * 10%   ** 5%   *** 1%"
    di as txt "{hline 72}"

    // ---- returns ----------------------------------------------------
    return local cmd     "xtgunitroot"
    return local depvar  "`varlist'"
    return local ivar    "`ivar'"
    return local tvar    "`tvar'"
    return local model   "`model'"
    return scalar N      = `Nunits'
    return scalar T      = `Teq'
    return scalar N_used = `Nused'
    return scalar N_drop = `Ndrop'
    return scalar maxlag = `maxlag'
    return scalar phi    = `phi'
    return scalar phi_dme= `phidm'
    return scalar bias   = `bias'
    return scalar z      = `z'
    return scalar p      = `p'
    if (`mcode'>=3) return scalar kbreak = `kb'
    if (`unknown'==1) {
        return scalar cv05 = `cv05'
        return scalar reps = `breps'
        matrix colnames `PROF' = kindex date tstat
        return matrix profile = `PROF'
    }
end

// ======================================================================
//  Mata engine
// ======================================================================
version 14.0
mata:

// ---- deterministic block W (T x k) in LEVELS (within transform) ------
real matrix xtgur_W(real scalar T, real scalar model, real scalar kb)
{
    real colvector e, tau, e1, e2, t1, t2
    real scalar t

    e   = J(T,1,1)
    tau = (1::T)
    if (model==1) {
        return(e)
    }
    if (model==2) {
        return((e, tau))
    }
    e1 = J(T,1,0)
    e2 = J(T,1,0)
    for (t=1; t<=T; t=t+1) {
        if (t<=kb) {
            e1[t] = 1
        }
        else {
            e2[t] = 1
        }
    }
    if (model==3) {
        return((e1, e2))
    }
    t1 = tau :* e1
    t2 = tau :* e2
    return((e1, e2, t1, t2))
}

// ---- KEEP the central band (|i-j| <= p), zero outside ----------------
//      (the [.]^-_p operator of KT2019: the band carries the bias /
//      the admissible serial-correlation autocovariances)
real matrix xtgur_bandkeep(real matrix A, real scalar p)
{
    real matrix B
    real scalar n, i, j
    B = A
    n = rows(B)
    for (i=1; i<=n; i=i+1) {
        for (j=1; j<=n; j=j+1) {
            if (abs(i-j)>p) {
                B[i,j] = 0
            }
        }
    }
    return(B)
}

// ---- read the panel into an N x Tplus1 level matrix (missing = .) -----
real matrix xtgur_buildY(string scalar yv, string scalar idv, string scalar tiv,
                         string scalar touse, real scalar Tplus1)
{
    real matrix DAT, Y
    real scalar N, nr, r
    DAT = st_data(., (idv, tiv, yv), touse)
    nr  = rows(DAT)
    N = 0
    for (r=1; r<=nr; r=r+1) {
        if (DAT[r,1] > N) {
            N = DAT[r,1]
        }
    }
    Y = J(N, Tplus1, .)
    for (r=1; r<=nr; r=r+1) {
        Y[DAT[r,1], DAT[r,2]] = DAT[r,3]
    }
    return(Y)
}

// ---- Theta = banded Lambda'Q  (intercept / break models, rho = 0) -----
real matrix xtgur_theta(real matrix Lam, real matrix Q, real scalar model,
                        real scalar kb, real scalar pmax)
{
    return(xtgur_bandkeep(Lam'*Q, pmax))
}

// ---- core DME statistic for a given (level matrix, model, kb, pmax) ---
//      returns (phi, phi_dme, bias, z, p, Nused, Ndrop)
real rowvector xtgur_stat(real matrix Y, real scalar N, real scalar Tplus1,
                          real scalar model, real scalar kb, real scalar pmax)
{
    real matrix W, Q, Lam, Theta, G, DYS, Ghat
    real colvector ylag, yi, Dy
    real scalar T, k, i, t, complete, nc
    real scalar SXX, SXY, bnum, vnum, Nused, Ndrop, q
    real scalar phi, dhat, bhat, phidm, z, p

    T = Tplus1 - 1
    W = xtgur_W(T, model, kb)
    k = cols(W)
    Q = I(T) - W * invsym(W'W) * W'

    // Lambda strictly lower-triangular ones (forward partial-sum operator)
    Lam = J(T, T, 0)
    for (i=2; i<=T; i=i+1) {
        for (t=1; t<=i-1; t=t+1) {
            Lam[i,t] = 1
        }
    }

    // pass 1: levels moments + collect differences of complete units
    SXX=0; SXY=0; Ndrop=0; nc=0
    DYS = J(N, T, 0)
    for (i=1; i<=N; i=i+1) {
        complete = 1
        for (t=1; t<=Tplus1; t=t+1) {
            if (Y[i,t]==.) {
                complete = 0
            }
        }
        if (complete==0) {
            Ndrop = Ndrop + 1
            continue
        }
        yi   = Y[i, 2..Tplus1]'
        ylag = Y[i, 1..T]'
        Dy   = yi - ylag
        SXX  = SXX + (ylag' * Q * ylag)
        SXY  = SXY + (ylag' * Q * yi)
        nc = nc + 1
        DYS[nc,.] = Dy'
    }
    Nused = nc
    if (Nused==0 | SXX==0) {
        return((., ., ., ., ., Nused, Ndrop))
    }

    Theta = xtgur_theta(Lam, Q, model, kb, pmax)
    G = Q*Lam - Theta'
    Ghat = (DYS[1..nc,.]' * DYS[1..nc,.]) / nc

    bnum = nc * trace(Theta*Ghat)
    vnum = 0
    for (i=1; i<=nc; i=i+1) {
        Dy = DYS[i,.]'
        q  = Dy' * G * Dy
        vnum = vnum + q*q
    }
    if (vnum<=0) {
        return((., ., ., ., ., Nused, Ndrop))
    }

    phi   = SXY/SXX
    dhat  = SXX/Nused
    bhat  = bnum/Nused
    phidm = phi - bhat/dhat
    // z = (phidm - 1)/sqrt(Vhat/(N dhat^2)) = (SXY - bnum - SXX)/sqrt(vnum)
    z = (SXY - bnum - SXX) / sqrt(vnum)
    p = normal(z)
    return((phi, phidm, bhat/dhat, z, p, Nused, Ndrop))
}

// ---- thin wrapper (known / no break) ---------------------------------
void xtgur_engine(string scalar yv, string scalar idv, string scalar tiv,
                  string scalar touse, real scalar Tplus1, real scalar model,
                  real scalar kb, real scalar pmax, string scalar outname)
{
    real matrix Y
    real scalar N, T
    real rowvector s
    Y = xtgur_buildY(yv, idv, tiv, touse, Tplus1)
    N = rows(Y)
    T = Tplus1 - 1
    s = xtgur_stat(Y, N, Tplus1, model, kb, pmax)
    st_matrix(outname, (s[1], s[2], s[3], s[4], s[5], s[6], s[7], T))
}

// ---- left-tail quantile ----------------------------------------------
real scalar xtgur_quantile(real colvector sorted, real scalar a)
{
    real scalar n, idx
    n = rows(sorted)
    if (n==0) {
        return(.)
    }
    idx = ceil(a*n)
    if (idx<1) {
        idx = 1
    }
    if (idx>n) {
        idx = n
    }
    return(sorted[idx])
}

// ---- bootstrap null panel: random walk built from POOLED resampled
//      first differences (imposes the unit-root null; does not telescope) -
real matrix xtgur_bootY(real colvector pool, real scalar N, real scalar Tplus1)
{
    real matrix Yr
    real scalar P, i, t, idx
    P  = rows(pool)
    Yr = J(N, Tplus1, 0)
    for (i=1; i<=N; i=i+1) {
        Yr[i,1] = 0
        for (t=1; t<=Tplus1-1; t=t+1) {
            idx = ceil(runiform(1,1)*P)
            if (idx<1) {
                idx = 1
            }
            if (idx>P) {
                idx = P
            }
            Yr[i,t+1] = Yr[i,t] + pool[idx]
        }
    }
    return(Yr)
}

// ---- unknown-break inf-t + bootstrap ---------------------------------
void xtgur_ubreak(string scalar yv, string scalar idv, string scalar tiv,
                  string scalar touse, real scalar Tplus1, real scalar model,
                  real scalar kbmin, real scalar kbmax, real scalar pmax,
                  real scalar breps, real scalar tmin,
                  string scalar outname, string scalar profname)
{
    real matrix Y, Yr, PROF
    real colvector bootinf, sorted, pool, dd
    real scalar N, T, i, t, kb, gi, ng, b, complete, nc, np
    real scalar obsinf, kbhat, tval, phi, phidm, bias, Nused, Ndrop
    real scalar bi, pcount, valid, pboot, q05, q10, q01
    real rowvector s

    Y = xtgur_buildY(yv, idv, tiv, touse, Tplus1)
    N = rows(Y)
    T = Tplus1 - 1
    ng = kbmax - kbmin + 1

    // observed inf-t over the break grid
    PROF = J(ng, 3, .)
    obsinf = .; kbhat = kbmin
    phi=.; phidm=.; bias=.; Nused=.; Ndrop=.
    gi = 0
    for (kb=kbmin; kb<=kbmax; kb=kb+1) {
        gi = gi + 1
        s = xtgur_stat(Y, N, Tplus1, model, kb, pmax)
        tval = s[4]
        PROF[gi,1] = kb
        PROF[gi,2] = tmin + kb
        PROF[gi,3] = tval
        if (tval!=.) {
            if (obsinf==. | tval<obsinf) {
                obsinf = tval; kbhat = kb
                phi = s[1]; phidm = s[2]; bias = s[3]; Nused = s[5]; Ndrop = s[6]
            }
        }
    }

    // pool of first differences from complete units (resampling residuals)
    nc = 0
    np = 0
    for (i=1; i<=N; i=i+1) {
        complete = 1
        for (t=1; t<=Tplus1; t=t+1) {
            if (Y[i,t]==.) {
                complete = 0
            }
        }
        if (complete==1) {
            nc = nc + 1
        }
    }
    pool = J(nc*T, 1, 0)
    np = 0
    for (i=1; i<=N; i=i+1) {
        complete = 1
        for (t=1; t<=Tplus1; t=t+1) {
            if (Y[i,t]==.) {
                complete = 0
            }
        }
        if (complete==1) {
            for (t=1; t<=T; t=t+1) {
                np = np + 1
                pool[np] = Y[i,t+1] - Y[i,t]
            }
        }
    }
    // centre the pooled increments (impose zero-drift null)
    pool = pool :- mean(pool)

    // bootstrap: re-search inf on each null replication
    bootinf = J(breps, 1, .)
    for (b=1; b<=breps; b=b+1) {
        Yr = xtgur_bootY(pool, nc, Tplus1)
        bi = .
        for (kb=kbmin; kb<=kbmax; kb=kb+1) {
            s = xtgur_stat(Yr, nc, Tplus1, model, kb, pmax)
            tval = s[4]
            if (tval!=.) {
                if (bi==. | tval<bi) {
                    bi = tval
                }
            }
        }
        bootinf[b] = bi
    }

    pcount = 0; valid = 0
    for (b=1; b<=breps; b=b+1) {
        if (bootinf[b]!=.) {
            valid = valid + 1
            if (bootinf[b] <= obsinf) {
                pcount = pcount + 1
            }
        }
    }
    pboot = (pcount + 1) / (valid + 1)
    sorted = sort(select(bootinf, bootinf:!=.), 1)
    q05 = xtgur_quantile(sorted, 0.05)
    q10 = xtgur_quantile(sorted, 0.10)
    q01 = xtgur_quantile(sorted, 0.01)

    st_matrix(outname, (phi, phidm, bias, obsinf, pboot, Nused, Ndrop, T, kbhat, q05, q10, q01))
    st_matrix(profname, PROF)
}

end
