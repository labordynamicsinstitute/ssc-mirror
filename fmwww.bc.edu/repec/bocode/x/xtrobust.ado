*! xtrobust 1.0.0  18jul2026
*! Robust estimation of linear panel data models in the presence of outliers.
*! S-estimator (Rousseeuw-Yohai) and Weighted Likelihood Estimator (WLE,
*! Agostinelli-Markatou) for fixed- and random-effects models.
*! Implements Jaseem & Mohammad, Al-Nahrain J. Science 27(4) (2024) 40-46.
*! Part of the xtoutliers suite.
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
program define xtrobust, rclass
    version 14.0

    syntax varlist(numeric min=2) [if] [in] [ ,             ///
        FE RE                                                ///
        Method(string)                                       ///
        NSAMP(integer 200)                                   ///
        Csteps(integer 2)                                    ///
        Tune(real 1.547)                                     ///
        Bconst(real 0.199)                                   ///
        BWidth(real 0.5)                                     ///
        Seed(integer -1)                                     ///
        Level(cilevel)                                       ///
        GRAPH name(string) ]

    gettoken dv ivars : varlist

    // model
    local nmodel = ("`fe'" != "") + ("`re'" != "")
    if (`nmodel' == 0) {
        di as error "specify fe or re"
        exit 198
    }
    if (`nmodel' > 1) {
        di as error "specify only one of fe / re"
        exit 198
    }
    local model = cond("`fe'"!="","fe","re")

    // method
    if ("`method'" == "") local method "all"
    if (!inlist("`method'","s","wle","all")) {
        di as error "method() must be s, wle, or all"
        exit 198
    }

    // panel
    capture qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'" == "") {
        di as error "xtrobust requires the data to be -xtset-"
        exit 459
    }

    marksample touse
    markout `touse' `ivar' `tvar'
    qui count if `touse'
    if (r(N) < 10) {
        di as error "too few observations"
        exit 2001
    }

    // RE variance components from a preliminary xtreg,re
    tempname _h
    capture _estimates hold `_h', restore nullok
    local sigE2 = 0
    local sigV2 = 0
    if ("`model'" == "re") {
        capture qui xtreg `dv' `ivars' if `touse', re
        if (_rc) {
            di as error "preliminary xtreg,re failed (rc=`_rc'); check the model"
            exit _rc
        }
        local sigE2 = e(sigma_e)^2
        local sigV2 = e(sigma_u)^2
    }

    // integer id, obs number, sort for panelsetup
    tempvar idn obsno idval tval
    qui egen long `idn' = group(`ivar') if `touse'
    capture confirm numeric variable `ivar'
    if (_rc == 0) qui gen double `idval' = `ivar'
    else          qui gen double `idval' = `idn'
    if ("`tvar'" != "") qui gen double `tval' = `tvar'
    else                qui gen double `tval' = .
    qui gen long `obsno' = _n
    sort `idn' `tvar' `obsno'

    // output variables
    tempvar ws wwle rols rs rwle fols fs fwle
    foreach v in ws wwle rols rs rwle fols fs fwle {
        qui gen double ``v'' = .
    }

    local modnum = cond("`model'"=="fe",1,2)

    mata: _xtrob_engine("`dv'", "`ivars'", "`idn'", "`touse'",            ///
        `modnum', `sigE2', `sigV2', `tune', `bconst', `nsamp', `csteps',  ///
        `bwidth', `seed',                                                 ///
        "`ws'", "`wwle'", "`rols'", "`rs'", "`rwle'",                     ///
        "`fols'", "`fs'", "`fwle'")

    local N   = r(N)
    local k   = r(k)
    local scS = r(scaleS)
    local scW = r(scaleWLE)
    tempname bO VO bS VS bW VW
    matrix `bO' = r(b_ols)
    matrix `VO' = r(V_ols)
    matrix `bS' = r(b_s)
    matrix `VS' = r(V_s)
    matrix `bW' = r(b_wle)
    matrix `VW' = r(V_wle)

    // display names (RE keeps a constant)
    local dnames "`ivars'"
    if ("`model'" == "re") local dnames "`ivars' _cons"
    foreach m in bO VO bS VS bW VW {
        matrix colnames ``m'' = `dnames'
    }
    matrix rownames `VO' = `dnames'
    matrix rownames `VS' = `dnames'
    matrix rownames `VW' = `dnames'

    // ---------------- journal-style output ----------------
    di ""
    di as text "{hline 79}"
    di as text "Robust panel estimation" ///
        _col(50) as text "N (obs)  = " as result %9.0g `N'
    di as text "Model: " as result "`model'" ///
        _col(50) as text "Regressors = " as result %7.0g `k'
    di as text "Tuning c = " as result %5.3f `tune' ///
        as text "  M-scale K = " as result %5.3f `bconst'
    di as text "S-scale   = " as result %8.5f `scS' ///
        as text "   WLE-scale = " as result %8.5f `scW'
    di as text "{hline 79}"

    di as text %-14s "Variable" ///
        _col(15) %10s "OLS" _col(27) %10s "S-est" _col(40) %10s "WLE"
    di as text _col(15) %10s "(SE)" _col(27) %10s "(SE)" _col(40) %10s "(SE)"
    di as text "{hline 79}"
    local nc = colsof(`bO')
    forvalues i = 1/`nc' {
        local vn : word `i' of `dnames'
        local bo = `bO'[1,`i']
        local so = sqrt(`VO'[`i',`i'])
        local bs = `bS'[1,`i']
        local ss = sqrt(`VS'[`i',`i'])
        local bw = `bW'[1,`i']
        local sw = sqrt(`VW'[`i',`i'])
        local po = 2*ttail(`N'-`k', abs(`bo'/`so'))
        local ps = 2*normal(-abs(`bs'/`ss'))
        local pw = 2*normal(-abs(`bw'/`sw'))
        _xtrob_star `po'
        local st_o "`r(star)'"
        _xtrob_star `ps'
        local st_s "`r(star)'"
        _xtrob_star `pw'
        local st_w "`r(star)'"
        di as text %-14s abbrev("`vn'",14) ///
            _col(15) as result %10.5f `bo' "`st_o'" ///
            _col(27) %10.5f `bs' "`st_s'" _col(40) %10.5f `bw' "`st_w'"
        di as text _col(15) as result "(" %7.5f `so' ")" ///
            _col(27) "(" %7.5f `ss' ")" _col(40) "(" %7.5f `sw' ")"
    }
    di as text "{hline 79}"
    di as text "* p<.10  ** p<.05  *** p<.01   (S,WLE SE asymptotic; OLS SE classical)"

    // ---------------- stored results ----------------
    return scalar N        = `N'
    return scalar k        = `k'
    return scalar scaleS   = `scS'
    return scalar scaleWLE = `scW'
    return local  model    "`model'"
    return local  method   "`method'"
    return local  depvar   "`dv'"
    return local  cmd      "xtrobust"
    return matrix b_ols  = `bO'
    return matrix V_ols  = `VO'
    return matrix b_s    = `bS'
    return matrix V_s    = `VS'
    return matrix b_wle  = `bW'
    return matrix V_wle  = `VW'

    // ---------------- figures ----------------
    if ("`graph'" != "") {
        if ("`name'" == "") local name "xtrobust"
        _xtrob_graph `ws' `wwle' `rs' `fs' `rwle' `fwle' `obsno' `touse' "`name'"
    }

    sort `obsno'
end

program define _xtrob_star, rclass
    args p
    local s ""
    if (`p' < 0.10) local s "*"
    if (`p' < 0.05) local s "**"
    if (`p' < 0.01) local s "***"
    return local star "`s'"
end

program define _xtrob_graph
    args ws wwle rs fs rwle fwle obsno touse name
    preserve
    qui keep if `touse'
    tempvar oo
    qui gen long `oo' = `obsno'
    local sch "graphregion(color(white)) plotregion(color(white))"

    qui twoway (dropline `ws' `oo', lcolor(navy) mcolor(navy)) ///
        , yline(1, lcolor(gs10)) title("(a) S-estimator weights", size(medsmall)) ///
        ytitle("weight") xtitle("Observation") ylabel(0(.25)1) ///
        `sch' name(`name'_a, replace) nodraw

    qui twoway (dropline `wwle' `oo', lcolor(cranberry) mcolor(cranberry)) ///
        , yline(1, lcolor(gs10)) title("(b) WLE weights", size(medsmall)) ///
        ytitle("weight") xtitle("Observation") ylabel(0(.25)1) ///
        `sch' name(`name'_b, replace) nodraw

    qui twoway (scatter `rs' `fs', mcolor(navy) msize(small)) ///
        , yline(0, lcolor(gs10)) title("(c) S: resid vs fitted", size(medsmall)) ///
        ytitle("residual") xtitle("fitted") ///
        `sch' name(`name'_c, replace) nodraw

    qui twoway (scatter `rwle' `fwle', mcolor(cranberry) msize(small)) ///
        , yline(0, lcolor(gs10)) title("(d) WLE: resid vs fitted", size(medsmall)) ///
        ytitle("residual") xtitle("fitted") ///
        `sch' name(`name'_d, replace) nodraw

    graph combine `name'_a `name'_b `name'_c `name'_d, ///
        title("Robust diagnostics", size(medium)) `sch' name(`name', replace)
    restore
end

// ======================================================================
// Mata engine for xtrobust
// ======================================================================
version 14.0
mata:

// ---- Tukey biweight pieces ----
real colvector _xtrob_rho(real colvector u, real scalar c)
{
    real colvector t, out
    t = (u:/c):^2
    out = (c^2/6) :* (1 :- (1 :- t):^3)
    out = out :* (abs(u) :<= c) :+ (c^2/6) :* (abs(u) :> c)
    return(out)
}
real colvector _xtrob_wt(real colvector u, real scalar c)
{
    real colvector t, out
    t = (u:/c):^2
    out = ((1 :- t):^2) :* (abs(u) :<= c)
    return(out)
}
real colvector _xtrob_psip(real colvector u, real scalar c)
{
    real colvector t, out
    t = (u:/c):^2
    out = ((1 :- t) :* ((1 :- t) :- 4 :* t)) :* (abs(u) :<= c)
    return(out)
}
real scalar _xtrob_mad(real colvector r)
{
    real scalar m
    m = 0.6745
    return( _xtrob_median(abs(r)) / m )
}
real scalar _xtrob_median(real colvector x)
{
    real colvector s
    real scalar n, h
    s = sort(x, 1)
    n = rows(s)
    h = ceil(n/2)
    if (mod(n,2) == 1) return(s[h])
    return((s[n/2] + s[n/2+1]) / 2)
}
real scalar _xtrob_mscale(real colvector r, real scalar c, real scalar b)
{
    real scalar s, it, m
    s = _xtrob_mad(r)
    if (s <= 0) s = mean(abs(r)) + 1e-8
    for (it=1; it<=200; it++) {
        m = mean(_xtrob_rho(r:/s, c))
        if (m <= 0) {
            it = 200
        }
        else {
            s = s * sqrt(m/b)
        }
    }
    return(s)
}

// ---- fast-S ----
real colvector _xtrob_fastS(real colvector y, real matrix X, real scalar c,
    real scalar b, real scalar nsamp, real scalar csteps)
{
    real scalar n, p, t, cc, it, s, bestsc
    real colvector perm, idx, r, w, bt, bn, bestb
    n = rows(y)
    p = cols(X)
    bestsc = .
    bestb  = J(p,1,0)
    for (t=1; t<=nsamp; t++) {
        perm = jumble((1::n))
        idx  = perm[1..p]
        bt   = invsym(cross(X[idx,.], X[idx,.])) * cross(X[idx,.], y[idx])
        r    = y - X*bt
        for (cc=1; cc<=csteps; cc++) {
            s  = _xtrob_mscale(r, c, b)
            if (s <= 0) s = 1e-8
            w  = _xtrob_wt(r:/s, c)
            bt = invsym(cross(X, w, X)) * cross(X, w, y)
            r  = y - X*bt
        }
        s = _xtrob_mscale(r, c, b)
        if (s < bestsc) {
            bestsc = s
            bestb  = bt
        }
    }
    // full IRLS refinement from the best candidate
    bt = bestb
    r  = y - X*bt
    for (it=1; it<=500; it++) {
        s  = _xtrob_mscale(r, c, b)
        w  = _xtrob_wt(r:/s, c)
        bn = invsym(cross(X, w, X)) * cross(X, w, y)
        if (mreldif(bn, bt) < 1e-9) {
            bt = bn
            it = 500
        }
        else {
            bt = bn
            r  = y - X*bt
        }
    }
    return(bt)
}

// ---- WLE (Agostinelli-Markatou), starting from a robust fit ----
real colvector _xtrob_wle(real colvector y, real matrix X, real colvector bstart,
    real scalar s, real scalar bwmult)
{
    real scalar n, it, i, h, sm
    real colvector b, r, fstar, mstar, delta, num, wt, d, bn
    n = rows(y)
    b = bstart
    h = bwmult * s
    if (h <= 0) h = 0.5
    sm = sqrt(s^2 + h^2)
    for (it=1; it<=300; it++) {
        r = y - X*b
        fstar = J(n,1,0)
        for (i=1; i<=n; i++) {
            d = (r[i] :- r) :/ h
            fstar[i] = mean(normalden(d)) / h
        }
        mstar = normalden(r:/sm) :/ sm
        delta = (fstar :/ mstar) :- 1
        num   = 2 :* (sqrt(delta :+ 1) :- 1) :+ 1     // A(delta)+1
        num   = num :* (num :> 0)                     // positive part
        wt    = num :/ (delta :+ 1)
        wt    = wt :* (wt :<= 1) :+ (wt :> 1)          // cap at 1
        wt    = wt :* (wt :> 0)
        bn = invsym(cross(X, wt, X)) * cross(X, wt, y)
        if (mreldif(bn, b) < 1e-9) {
            b  = bn
            it = 300
        }
        else {
            b = bn
        }
    }
    return(b)
}

real colvector _xtrob_wleW(real colvector r, real scalar s, real scalar bwmult)
{
    real scalar n, i, h, sm
    real colvector fstar, mstar, delta, num, wt, d
    n = rows(r)
    h = bwmult * s
    if (h <= 0) h = 0.5
    sm = sqrt(s^2 + h^2)
    fstar = J(n,1,0)
    for (i=1; i<=n; i++) {
        d = (r[i] :- r) :/ h
        fstar[i] = mean(normalden(d)) / h
    }
    mstar = normalden(r:/sm) :/ sm
    delta = (fstar :/ mstar) :- 1
    num   = 2 :* (sqrt(delta :+ 1) :- 1) :+ 1
    num   = num :* (num :> 0)
    wt    = num :/ (delta :+ 1)
    wt    = wt :* (wt :<= 1) :+ (wt :> 1)
    wt    = wt :* (wt :> 0)
    return(wt)
}

void _xtrob_engine(string scalar yv, string scalar xv, string scalar idnv,
    string scalar tousev, real scalar model, real scalar sigE2, real scalar sigV2,
    real scalar c, real scalar b, real scalar nsamp, real scalar csteps,
    real scalar bwmult, real scalar seed,
    string scalar wsv, string scalar wwv, string scalar r0v, string scalar rsv,
    string scalar rwv, string scalar f0v, string scalar fsv, string scalar fwv)
{
    real colvector y, idn, yd, Ti, lami
    real matrix X, Xd, info
    real scalar N, k, g, a, bb, Tg, n, p
    real colvector bols, rols, ws, bs, rs, scale_s, wwle, bwle, rwle
    real colvector wS, wW
    real scalar sS, sW, tau_s, num_s, den_s
    real matrix Vols, Vs, Vw, XWXi
    real colvector fols, fs, fw, u

    st_view(y=.,   ., yv,   tousev)
    st_view(X=.,   ., tokens(xv), tousev)
    st_view(idn=., ., idnv, tousev)
    N = rows(y)
    k = cols(X)
    info = panelsetup(idn, 1)
    n = rows(info)

    // per-obs T_i
    Ti = J(N,1,.)
    for (g=1; g<=n; g++) {
        a  = info[g,1]
        bb = info[g,2]
        Tg = bb - a + 1
        Ti[|a \ bb|] = J(Tg,1,Tg)
    }

    if (model == 1) {
        // FE: within transform, no constant
        yd = _xtrob_dm(y, info)
        Xd = _xtrob_dmM(X, info)
        p  = k
    }
    else {
        // RE: quasi-demean with lambda_i, keep constant
        lami = 1 :- sqrt( sigE2 :/ (sigE2 :+ Ti :* sigV2) )
        yd = _xtrob_qdm(y, info, lami)
        Xd = _xtrob_qdmM(X, info, lami)
        Xd = (Xd, 1 :- lami)          // quasi-demeaned constant
        p  = k + 1
    }

    if (seed >= 0) rseed(seed)

    // ---- OLS ----
    bols = invsym(cross(Xd,Xd)) * cross(Xd, yd)
    rols = yd - Xd*bols
    Vols = ((rols'rols)/(N-p)) * invsym(cross(Xd,Xd))
    fols = Xd*bols

    // ---- S ----
    bs = _xtrob_fastS(yd, Xd, c, b, nsamp, csteps)
    rs = yd - Xd*bs
    sS = _xtrob_mscale(rs, c, b)
    fs = Xd*bs
    u  = rs :/ sS
    wS = _xtrob_wt(u, c)
    // asymptotic var: s^2 * mean(psi^2)/mean(psi')^2 * (X'X)^{-1}
    num_s = mean((_xtrob_wt(u,c) :* u):^2)          // psi = u*w(u)
    den_s = mean(_xtrob_psip(u, c))
    if (den_s == 0) den_s = 1e-6
    tau_s = sS^2 * num_s / (den_s^2)
    Vs = tau_s * invsym(cross(Xd,Xd))

    // ---- WLE (start from S) ----
    bwle = _xtrob_wle(yd, Xd, bs, sS, bwmult)
    rwle = yd - Xd*bwle
    sW = _xtrob_mscale(rwle, c, b)
    fw = Xd*bwle
    wW = _xtrob_wleW(rwle, sS, bwmult)
    // weighted sandwich var
    XWXi = invsym(cross(Xd, wW, Xd))
    Vw   = (sum(wW :* (rwle:^2)) / (N-p)) * XWXi * cross(Xd, wW:^2, Xd) * XWXi

    // ---- write back ----
    st_store(., wsv, tousev, wS)
    st_store(., wwv, tousev, wW)
    st_store(., r0v, tousev, rols)
    st_store(., rsv, tousev, rs)
    st_store(., rwv, tousev, rwle)
    st_store(., f0v, tousev, fols)
    st_store(., fsv, tousev, fs)
    st_store(., fwv, tousev, fw)

    st_matrix("r(b_ols)", bols')
    st_matrix("r(V_ols)", Vols)
    st_matrix("r(b_s)",   bs')
    st_matrix("r(V_s)",   Vs)
    st_matrix("r(b_wle)", bwle')
    st_matrix("r(V_wle)", Vw)
    st_numscalar("r(N)", N)
    st_numscalar("r(k)", k)
    st_numscalar("r(scaleS)",   sS)
    st_numscalar("r(scaleWLE)", sW)
}

// demeaning helpers
real colvector _xtrob_dm(real colvector z, real matrix info)
{
    real scalar g, a, b
    real colvector out
    out = z
    for (g=1; g<=rows(info); g++) {
        a = info[g,1]
        b = info[g,2]
        out[|a \ b|] = z[|a \ b|] :- mean(z[|a \ b|])
    }
    return(out)
}
real matrix _xtrob_dmM(real matrix X, real matrix info)
{
    real scalar g, a, b
    real matrix out
    out = X
    for (g=1; g<=rows(info); g++) {
        a = info[g,1]
        b = info[g,2]
        out[|a,1 \ b,cols(X)|] = X[|a,1 \ b,cols(X)|] :- mean(X[|a,1 \ b,cols(X)|])
    }
    return(out)
}
real colvector _xtrob_qdm(real colvector z, real matrix info, real colvector lam)
{
    real scalar g, a, b
    real colvector out
    out = z
    for (g=1; g<=rows(info); g++) {
        a = info[g,1]
        b = info[g,2]
        out[|a \ b|] = z[|a \ b|] :- lam[|a \ b|] :* mean(z[|a \ b|])
    }
    return(out)
}
real matrix _xtrob_qdmM(real matrix X, real matrix info, real colvector lam)
{
    real scalar g, a, b, j
    real matrix out
    real rowvector mu
    out = X
    for (g=1; g<=rows(info); g++) {
        a = info[g,1]
        b = info[g,2]
        mu = mean(X[|a,1 \ b,cols(X)|])
        for (j=1; j<=cols(X); j++) {
            out[|a,j \ b,j|] = X[|a,j \ b,j|] :- lam[|a \ b|] :* mu[j]
        }
    }
    return(out)
}

end
