*! version 1.11.1  31jul2026  H. Ozan Eruygur
*! qrbreak: Structural breaks in quantile regression (testing and estimation)
*! Port of the R package QR.break v1.0.3 (Zhongjun Qu, Tatsushi Oka, Samuel Messer)
*! References: Qu (2008, J. Econometrics 146, 170-184); Oka and Qu (2011, J. Econometrics 162, 248-267)
*! Author: H. Ozan Eruygur, AHBV University, Ankara, Turkiye. Department of Economics
*! https://www.ozaneruygur.com  eruygur@gmail.com
*! Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.
*! https://www.eruygurakademi.com  eruygurakademi@gmail.com

program qrbreak, eclass
    version 16.0
    syntax [varlist(min=2 numeric fv ts default=none)] [if] [in] [, SELFtest TAU(numlist >0 <1 min=1 sort) NSize(integer 1) TRIM(real 0.15) MAXbreaks(integer 3) Alpha(integer 5) CILevel(integer 95) TIME(varname) NORM(string)]

    * built-in numerical self test against embedded R reference values
    if ("`selftest'" != "") {
        mata: qrb_selftest()
        exit
    }
    if ("`varlist'" == "") {
        di as error "varlist required"
        exit 100
    }
    if ("`tau'" == "") {
        di as error "option tau() required"
        exit 198
    }
    if ("`norm'" == "") local norm "cholesky"
    if ("`norm'" != "cholesky" & "`norm'" != "spectral") {
        di as error "norm() must be cholesky or spectral"
        exit 198
    }

    * genuine panels (data xtset with a panel variable) are outside the scope
    * of this command; repeated cross sections must be declared through
    * nsize(), and a single time series carries no panel declaration
    if (`nsize' == 1) {
        capture quietly xtset
        if (_rc == 0 & "`r(panelvar)'" != "") {
            di as txt "data are xtset as a panel (panel variable: `r(panelvar)'); qrbreak is designed for a single time series or for repeated cross sections declared with nsize(); it is not suitable for genuine panel data; see help qrbreak"
            exit 459
        }
    }

    * try to load the compiled core (qrbreak_core plugin); if none loads, the
    * pure Mata path below computes the very same results, only more slowly.
    * On macOS the two architectures are tried in turn; the one matching the
    * machine loads and the other fails harmlessly
    global QRB_PLUGIN "0"
    if ("`c(os)'" == "Windows") {
        capture program qrbreak_core, plugin using("qrbreak_core_windows.plugin")
        if (_rc == 0 | _rc == 110) global QRB_PLUGIN "1"
    }
    else if ("`c(os)'" == "MacOSX") {
        capture program qrbreak_core, plugin using("qrbreak_core_macosx_arm64.plugin")
        if (_rc == 0 | _rc == 110) global QRB_PLUGIN "1"
        else {
            capture program qrbreak_core, plugin using("qrbreak_core_macosx_x86_64.plugin")
            if (_rc == 0 | _rc == 110) global QRB_PLUGIN "1"
        }
    }
    else {
        capture program qrbreak_core, plugin using("qrbreak_core_unix.plugin")
        if (_rc == 0 | _rc == 110) global QRB_PLUGIN "1"
    }

    marksample touse
    gettoken depvar indepvars : varlist

    * expand factor-variable and time-series operators into plain variables,
    * mirroring what model.matrix() does on the R side: base and omitted
    * levels are dropped (they would collide with the intercept) and every
    * remaining term is materialized as a temporary numeric variable
    fvexpand `depvar' if `touse'
    if (`: word count `r(varlist)'' > 1) {
        di as error "the dependent variable may not be a factor variable"
        exit 198
    }
    fvrevar `depvar' if `touse'
    local depvar `r(varlist)'
    if ("`indepvars'" != "") {
        fvexpand `indepvars' if `touse'
        local expx `r(varlist)'
        local keepx ""
        foreach tk of local expx {
            if (strpos("`tk'", "b.") == 0 & strpos("`tk'", "o.") == 0) local keepx "`keepx' `tk'"
        }
        if ("`keepx'" == "") {
            di as error "all independent variables were dropped as base or omitted factor levels"
            exit 198
        }
        fvrevar `keepx' if `touse'
        local indepvars `r(varlist)'
    }

    * ---- replicate input validations of rq.break() ----
    if (`nsize' < 1) {
        di as error "nsize() must be at least 1"
        exit 198
    }
    if (`trim' < 0 | `trim' > 0.5) {
        di as error "trim() must be between 0 and 0.5 (inclusive)"
        exit 198
    }
    if (`maxbreaks'*`trim' > 1) {
        di as error "maxbreaks()*trim() exceeds 1: too many regimes or minimum regime length too large; decrease maxbreaks(), trim(), or both"
        exit 198
    }
    if (`maxbreaks' > 10) {
        di as error "maxbreaks() cannot exceed 10"
        exit 198
    }
    if (`alpha' != 10 & `alpha' != 5 & `alpha' != 1) {
        di as error "alpha() must be 10, 5, or 1 (percent significance level for determining the number of breaks)"
        exit 198
    }
    if (`cilevel' != 90 & `cilevel' != 95) {
        di as error "cilevel() must be 90 or 95 (coverage level for break date confidence intervals)"
        exit 198
    }
    local va = cond(`alpha'==10, 1, cond(`alpha'==5, 2, 3))
    local vb = cond(`cilevel'==90, 1, 2)

    qui count if `touse'
    local NT = r(N)
    if (`NT' == 0) error 2000
    if (mod(`NT', `nsize') != 0) {
        di as error "number of usable observations (`NT') is not a multiple of nsize() (`nsize')"
        exit 198
    }

    * time variable may be numeric or string
    local timetype ""
    if ("`time'" != "") {
        capture confirm numeric variable `time'
        if (_rc == 0) local timetype "num"
        else local timetype "str"
    }

    * ---- computation is done entirely in Mata ----
    mata: qrb_main("`depvar'", "`indepvars'", "`touse'", "`tau'", `nsize', `trim', `maxbreaks', `va', `vb', "`time'", "`timetype'", "`norm'")

    * ---- post e() results ----
    ereturn clear
    ereturn post, esample(`touse')
    ereturn local norm "`norm'"
    ereturn local cmd "qrbreak"
    ereturn local cmdline "qrbreak `0'"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local timevar "`time'"
    ereturn scalar N = `NT'
    ereturn scalar T = $QRB_T
    ereturn scalar nsize = `nsize'
    ereturn scalar trim = `trim'
    ereturn scalar trimsize = $QRB_TRIMSIZE
    ereturn scalar maxbreaks = `maxbreaks'
    ereturn scalar alpha = `alpha'
    ereturn scalar cilevel = `cilevel'
    ereturn scalar ntau = $QRB_NTAU
    tempname tmp
    matrix `tmp' = QRB_tau
    ereturn matrix tau = `tmp'
    local ntau = $QRB_NTAU
    forvalues k = 1/`ntau' {
        foreach nm in sq_test sq_cv sq_nbreak sq_dates {
            capture confirm matrix QRB_`nm'_`k'
            if (_rc == 0) {
                matrix `tmp' = QRB_`nm'_`k'
                ereturn matrix `nm'_`k' = `tmp'
            }
        }
        foreach nm in sq_ci sq_coef sq_bsize mq_coef mq_bsize {
            capture confirm matrix QRB_`nm'_`k'
            if (_rc == 0) {
                matrix `tmp' = QRB_`nm'_`k'
                ereturn matrix `nm'_`k' = `tmp'
            }
        }
    }
    foreach nm in dq_test dq_cv dq_nbreak_all dq_dates dq_ci {
        capture confirm matrix QRB_`nm'
        if (_rc == 0) {
            matrix `tmp' = QRB_`nm'
            ereturn matrix `nm' = `tmp'
        }
    }
    capture ereturn scalar dq_nbreak = scalar(QRB_dq_nbreak)
    forvalues k = 1/`ntau' {
        capture ereturn scalar sq_nb_`k' = scalar(QRB_sq_nb_`k')
    }
    * clean up globals used for transport
    capture macro drop QRB_T QRB_TRIMSIZE QRB_NTAU
    foreach s in dq_nbreak {
        capture scalar drop QRB_`s'
    }
    forvalues k = 1/`ntau' {
        capture scalar drop QRB_sq_nb_`k'
    }
    qui qrbreak_dropmats
end

program qrbreak_dropmats
    * drop all transport matrices with prefix QRB_
    local allm : all matrices "QRB_*"
    foreach m of local allm {
        capture matrix drop `m'
    }
end

version 16.0
mata:
mata set matastrict on

// ================================================================================
// qrbreak Mata library: faithful port of R package QR.break v1.0.3 and of the
// required internals of R package quantreg v6.1 (rqbr.f, rqfnb.f,
// bandwidth.rq, summary.rq with se="nid").
// All algorithmic loops and accumulation orders mirror the originals so that
// results replicate R to machine precision wherever the originals are
// deterministic.
// ================================================================================

// Fortran SIGN(1d0, z): +1 if z >= 0, -1 if z < 0
real scalar qrb_fsign(real scalar z)
{
    return(z >= 0 ? 1 : -1)
}

// R round(x) for digits = 0: IEC 60559 round-half-to-even
real scalar qrb_rround(real scalar x)
{
    real scalar fl, fr
    if (x < 0) return(-qrb_rround(-x))
    fl = floor(x)
    fr = x - fl
    if (fr > 0.5) return(fl + 1)
    if (fr < 0.5) return(fl)
    return(mod(fl, 2) == 0 ? fl : fl + 1)
}

// R seq(from, to, by): values from + (0..n)*by with n = int((to-from)/by + 1e-10), clamped at to
real rowvector qrb_seq(real scalar from, real scalar to, real scalar by)
{
    real scalar n
    real rowvector v
    n = trunc((to - from)/by + 1e-10)
    v = from :+ (0..n)*by
    if (by > 0) v = colmin((v \ J(1, n+1, to)))
    else v = colmax((v \ J(1, n+1, to)))
    return(v)
}

// sum of the check function: R Rho(u, tau) = u*(tau - (u < 0)); R sum() accumulates
// in extended precision, mirrored here with quadsum
real scalar qrb_rho(real colvector u, real scalar tau)
{
    return(quadsum(u :* (tau :- (u :< 0))))
}

// --------------------------------------------------------------------------------
// qrb_rqbr(): modified Barrodale-Roberts simplex for quantile regression.
// Verbatim port of rqbr.f (Koenker-d'Orey) for the path used by quantreg's
// rq.fit.br() with ci=FALSE and 0 < tau < 1. A is the full design matrix
// (including the constant), B is the response. Fills coef; returns the ift
// flag: 0 ok, 1 solution may be nonunique, 2 premature end.
// --------------------------------------------------------------------------------
real scalar qrb_rqbr(real matrix A, real colvector B, real scalar t, real colvector coef, | real colvector eres)
{
    real scalar m, nn, n, m1, n1, n2, m2, m3, m4, n3, n4
    real scalar toler, big, ift, kount, kr, kl, stage, test, init
    real scalar i, j, k, jj, in, out, pivot, d, mx, mn, aux, state, done, kk, a2, a3, din
    real matrix wa
    real colvector x, negrows, s4, sel, wbv, sidxv, dcol, dmask, colnew, ridx, kkv, sgn
    real rowvector v, brow

    m = rows(A)
    nn = cols(A)
    n = nn
    toler = epsilon(1)^(2/3)
    big = maxdouble()
    ift = 0
    m1 = m + 1
    n1 = n + 1
    n2 = n + 2
    m2 = m + 2
    m3 = m + 3
    m4 = m + 4
    n3 = n + 3
    n4 = n + 4
    wa = J(m + 5, n4, 0)
    wa[m2, nn+1] = 1
    x = J(n, 1, 0)
    // tableau setup; element-independent operations are vectorized, which
    // keeps every per-element rounding identical to the scalar original
    wa[|1, 1 \ m, nn|] = A
    wa[|1, n4 \ m, n4|] = n :+ (1::m)
    wa[|1, n2 \ m, n2|] = B
    wa[|1, n3 \ m, n3|] = J(m, 1, 0)
    wa[|1, n1 \ m, n1|] = wa[|1, n2 \ m, n2|] - wa[|1, n3 \ m, n3|]
    negrows = selectindex(wa[|1, n1 \ m, n1|] :< 0)
    if (rows(negrows) > 0) wa[negrows, .] = -wa[negrows, .]
    s4 = 2*(wa[|1, n4 \ m, n4|] :>= 0) :- 1
    for (j = 1; j <= n; j++) {
        wa[m4, j] = j
        a2 = 0
        a3 = 0
        for (i = 1; i <= m; i++) {
            aux = wa[i, j]
            a2 = a2 + aux*(1 - s4[i])
            a3 = a3 + aux*s4[i]
        }
        wa[m2, j] = a2
        wa[m3, j] = 2*a3
    }
    // note: the column-means row wa(m+5, .) of the Fortran original is never
    // read on this path (it only feeds sol(2) in the whole-process case), so
    // its computation is omitted; the tableau arithmetic is unaffected
    init = 0
    kount = 0
    for (j = 1; j <= n; j++) wa[m1, j] = wa[m2, j] + wa[m3, j]*t
    stage = 1
    kr = 1
    kl = 1
    in = 0
    out = 0
    jj = 0
    k = 0
    test = 0
    pivot = 0
    wbv = J(0, 1, 0)
    sidxv = J(0, 1, 0)
    state = 30
    done = 0
    while (!done) {
        if (state == 30) {
            mx = -1
            for (j = kr; j <= n; j++) {
                if (abs(wa[m4, j]) <= n) {
                    d = abs(wa[m1, j])
                    if (d > mx) {
                        mx = d
                        in = j
                    }
                }
            }
            if (wa[m1, in] < 0) wa[|1, in \ m4, in|] = -wa[|1, in \ m4, in|]
            state = 72
        }
        else if (state == 55) {
            mx = -big
            in = 0
            for (j = kr; j <= n; j++) {
                d = wa[m1, j]
                if (d < 0) {
                    if (d > -2) continue
                    d = -d - 2
                }
                if (d > mx) {
                    mx = d
                    in = j
                }
            }
            if (mx <= toler) {
                state = 54
                continue
            }
            if (wa[m1, in] <= 0) {
                wa[|1, in \ m4, in|] = -wa[|1, in \ m4, in|]
                wa[m1, in] = wa[m1, in] - 2
                wa[m2, in] = wa[m2, in] - 2
            }
            state = 72
        }
        else if (state == 72) {
            sel = selectindex(wa[|kl, in \ m, in|] :> toler)
            k = rows(sel)
            test = (k > 0)
            if (k > 0) {
                sel = sel :+ (kl - 1)
                wbv = wa[sel, n1] :/ wa[sel, in]
                sidxv = sel
            }
            state = 79
        }
        else if (state == 79) {
            if (k <= 0) test = 0
            else {
                mn = big
                for (i = 1; i <= k; i++) {
                    if (wbv[i] < mn) {
                        jj = i
                        mn = wbv[i]
                        out = sidxv[i]
                    }
                }
                wbv[jj] = wbv[k]
                sidxv[jj] = sidxv[k]
                k = k - 1
            }
            if (!test & stage) {
                state = 81
                continue
            }
            if (!test) {
                ift = 2
                done = 1
                continue
            }
            pivot = wa[out, in]
            if (wa[m1, in] - pivot - pivot <= toler) {
                state = 10
                continue
            }
            v = wa[|out, kr \ out, n3|]
            wa[|m1, kr \ m1, n3|] = (wa[|m1, kr \ m1, n3|] - v) - v
            wa[|m2, kr \ m2, n3|] = (wa[|m2, kr \ m2, n3|] - v) - v
            wa[|out, kr \ out, n3|] = -v
            wa[out, n4] = -wa[out, n4]
            state = 79
        }
        else if (state == 81) {
            v = wa[|1, kr \ m4, kr|]'
            wa[|1, kr \ m4, kr|] = wa[|1, in \ m4, in|]
            wa[|1, in \ m4, in|] = v'
            kr = kr + 1
            state = 20
        }
        else if (state == 10) {
            din = wa[out, in]
            wa[|out, kr \ out, n3|] = wa[|out, kr \ out, n3|]/pivot
            wa[out, in] = din
            dcol = wa[|1, in \ m3, in|]
            dmask = dcol
            dmask[out] = 0
            brow = wa[|out, kr \ out, n3|]
            brow[in - kr + 1] = 0
            wa[|1, kr \ m3, n3|] = wa[|1, kr \ m3, n3|] - dmask*brow
            colnew = -dcol/pivot
            colnew[out] = 1/pivot
            wa[|1, in \ m3, in|] = colnew
            d = wa[out, n4]
            wa[out, n4] = wa[m4, in]
            wa[m4, in] = d
            kount = kount + 1
            if (!stage) {
                state = 55
                continue
            }
            kl = kl + 1
            v = wa[|out, kr \ out, n4|]
            wa[|out, kr \ out, n4|] = wa[|kount, kr \ kount, n4|]
            wa[|kount, kr \ kount, n4|] = v
            state = 20
        }
        else if (state == 20) {
            if (kount + kr == n1) {
                stage = 0
                state = 55
            }
            else state = 30
        }
        else if (state == 54) {
            if (kr == 1) {
                for (j = 1; j <= n; j++) {
                    d = abs(wa[m1, j])
                    if (d <= toler | 2 - d <= toler) {
                        ift = 1
                        break
                    }
                }
            }
            for (i = 1; i <= kl - 1; i++) {
                kk = abs(wa[i, n4])
                x[kk] = wa[i, n1]*qrb_fsign(wa[i, n4])
            }
            done = 1
        }
    }
    // Fortran label 50: residual vector e; observations in the basis (the
    // interpolated points of the quantile regression fit) remain exactly zero,
    // which makes the sign classification (e <= 0) deterministic
    if (args() >= 5) {
        eres = J(m, 1, 0)
        if (kl <= m) {
            ridx = kl::m
            kkv = abs(wa[ridx, n4]) :- n
            sgn = 2*(wa[ridx, n4] :>= 0) :- 1
            eres[kkv] = wa[ridx, n1] :* sgn
        }
    }
    coef = x
    return(ift)
}

// --------------------------------------------------------------------------------
// qrb_rq(): mirrors quantreg's rq.fit.br(x, y, tau, ci = FALSE): singularity
// check, rqbr call, residuals = y - x %*% coef. Fills coef and resid; returns
// the ift flag.
// --------------------------------------------------------------------------------
real scalar qrb_rq(real matrix X, real colvector y, real scalar tau, real colvector coef, real colvector resid)
{
    real scalar ift
    if (rank(X) < cols(X)) _error(3352, "singular design matrix")
    coef = J(cols(X), 1, 0)
    ift = qrb_rqbr(X, y, tau, coef)
    resid = y - X*coef
    return(ift)
}

// bandwidth.rq of quantreg: Hall-Sheather (hs = 1) or Bofinger (hs = 0)
real scalar qrb_bandwidth(real scalar p, real scalar n, real scalar hs, | real scalar alpha)
{
    real scalar x0, f0
    if (args() < 4) alpha = 0.05
    x0 = invnormal(p)
    f0 = normalden(x0)
    if (hs) return(n^(-1/3)*invnormal(1 - alpha/2)^(2/3)*((1.5*f0^2)/(2*x0^2 + 1))^(1/3))
    else return(n^(-0.2)*((4.5*f0^4)/(2*x0^2 + 1)^2)^0.2)
}

// --------------------------------------------------------------------------------
// qrb_rqfnb(): Frisch-Newton interior point method with Mehrotra corrector.
// Verbatim port of rqfnb.f (lpfnb + stepy) as called by quantreg's
// rq.fit.fnb(x, y, tau) with its defaults beta = 0.99995, eps = 1e-6.
// Returns the coefficient vector.
// --------------------------------------------------------------------------------
real colvector qrb_rqfnb(real matrix X, real colvector yv, real scalar tau)
{
    real scalar n, p, beta, eps, gap, it, maxit, deltap, deltad, mu, g, i, dxdz, dsdw
    real colvector cc, bb, xx, ss, zz, ww, dd, uu, dx, ds, dz, dw, dr, yd, dy, rhs_
    real matrix ada

    beta = 0.99995
    eps = 1e-6
    maxit = 500
    n = rows(X)
    p = cols(X)
    cc = -yv
    bb = (1 :- tau)*quadcolsum(X)'
    xx = J(n, 1, 1 - tau)
    uu = J(n, 1, 1)
    dd = J(n, 1, 1)
    ada = cross(X, dd, X)
    yd = cholsolve(ada, cross(X, cc))
    ss = cc - X*yd
    zz = J(n, 1, 0)
    ww = J(n, 1, 0)
    for (i = 1; i <= n; i++) {
        if (abs(ss[i]) < eps) {
            zz[i] = max((ss[i], 0)) + eps
            ww[i] = max((-ss[i], 0)) + eps
        }
        else {
            zz[i] = max((ss[i], 0))
            ww[i] = max((-ss[i], 0))
        }
        ss[i] = uu[i] - xx[i]
    }
    gap = cross(zz, xx) + cross(ww, ss)
    it = 0
    dx = J(n, 1, 0)
    ds = J(n, 1, 0)
    dz = J(n, 1, 0)
    dw = J(n, 1, 0)
    dr = J(n, 1, 0)
    while (gap > eps & it < maxit) {
        it = it + 1
        dd = 1 :/ (zz :/ xx + ww :/ ss)
        ds = zz - ww
        dz = dd :* ds
        dy = bb - cross(X, xx) + cross(X, dz)
        rhs_ = dy
        ada = cross(X, dd, X)
        dy = cholsolve(ada, dy)
        ds = X*dy - ds
        deltap = maxdouble()
        deltad = maxdouble()
        for (i = 1; i <= n; i++) {
            dx[i] = dd[i]*ds[i]
            ds[i] = -dx[i]
            dz[i] = -zz[i]*(dx[i]/xx[i] + 1)
            dw[i] = -ww[i]*(ds[i]/ss[i] + 1)
            if (dx[i] < 0) deltap = min((deltap, -xx[i]/dx[i]))
            if (ds[i] < 0) deltap = min((deltap, -ss[i]/ds[i]))
            if (dz[i] < 0) deltad = min((deltad, -zz[i]/dz[i]))
            if (dw[i] < 0) deltad = min((deltad, -ww[i]/dw[i]))
        }
        deltap = min((beta*deltap, 1))
        deltad = min((beta*deltad, 1))
        if (min((deltap, deltad)) < 1) {
            mu = cross(xx, zz) + cross(ss, ww)
            g = mu + deltap*cross(dx, zz) + deltad*cross(dz, xx) + deltap*deltad*cross(dz, dx) + deltap*cross(ds, ww) + deltad*cross(dw, ss) + deltap*deltad*cross(ds, dw)
            mu = mu*((g/mu)^3)/(2*n)
            dr = dd :* (mu :* (1 :/ ss - 1 :/ xx) + dx :* dz :/ xx - ds :* dw :/ ss)
            dy = rhs_ + cross(X, dr)
            dy = cholsolve(ada, dy)
            uu = X*dy
            deltap = maxdouble()
            deltad = maxdouble()
            for (i = 1; i <= n; i++) {
                dxdz = dx[i]*dz[i]
                dsdw = ds[i]*dw[i]
                dx[i] = dd[i]*(uu[i] - zz[i] + ww[i]) - dr[i]
                ds[i] = -dx[i]
                dz[i] = -zz[i] + (mu - zz[i]*dx[i] - dxdz)/xx[i]
                dw[i] = -ww[i] + (mu - ww[i]*ds[i] - dsdw)/ss[i]
                if (dx[i] < 0) deltap = min((deltap, -xx[i]/dx[i]))
                if (ds[i] < 0) deltap = min((deltap, -ss[i]/ds[i]))
                if (dz[i] < 0) deltad = min((deltad, -zz[i]/dz[i]))
                if (dw[i] < 0) deltad = min((deltad, -ww[i]/dw[i]))
            }
            deltap = min((beta*deltap, 1))
            deltad = min((beta*deltad, 1))
        }
        xx = xx + deltap*dx
        ss = ss + deltap*ds
        yd = yd + deltad*dy
        zz = zz + deltad*dz
        ww = ww + deltad*dw
        gap = cross(zz, xx) + cross(ww, ss)
    }
    return(-yd)
}

// --------------------------------------------------------------------------------
// gen.mat.rho: objective function values for all admissible segments starting
// at a given date (port of gen.mat.rho.R)
// --------------------------------------------------------------------------------
real matrix qrb_genmatrho(real colvector y, real matrix x, real rowvector vec_tau, real scalar n_size, real scalar trim_size, real scalar start, real scalar last)
{
    real scalar n_tau, col01, col02, loc01, loc02, j, k
    real matrix mat_rho, Xfull, X
    real colvector yseg, b, res

    n_tau = cols(vec_tau)
    mat_rho = J(last, n_tau, 0)
    col01 = n_size*(start - 1) + 1
    loc01 = start + trim_size - 1
    loc02 = last
    Xfull = (J(rows(y), 1, 1), x)
    for (j = loc01; j <= loc02; j++) {
        col02 = n_size*j
        yseg = y[|col01 \ col02|]
        X = Xfull[|col01, 1 \ col02, cols(Xfull)|]
        if (diag0cnt(invsym(cross(X, X))) > 0) _error(3352, "singular design matrix in a subsample")
        for (k = 1; k <= n_tau; k++) {
            b = J(cols(X), 1, 0)
            (void) qrb_rqbr(X, yseg, vec_tau[k], b)
            res = yseg - X*b
            mat_rho[j, k] = qrb_rho(res, vec_tau[k])
        }
    }
    return(mat_rho)
}

// --------------------------------------------------------------------------------
// gen.long: objective values for all possible segments, stored in the packed
// layout used by the dynamic program (port of gen.long.R, unchanged through v1.0.3)
// --------------------------------------------------------------------------------
void qrb_genlong(real colvector y, real matrix x, real rowvector vec_tau, real scalar n_size, real scalar trim_size, real matrix mat_long, real colvector vec_long)
{
    real scalar t_size, n_tau, i, row01, row02, jlo, jhi, ndot
    real matrix mat_out

    t_size = rows(y)/n_size
    n_tau = cols(vec_tau)
    if (st_global("QRB_PLUGIN") == "1") {
        st_matrix("QRB_PY", y)
        st_matrix("QRB_PX", x)
        st_matrix("QRB_TAU", vec_tau)
        st_matrix("QRB_ML", J(t_size*(t_size + 1)/2, n_tau, 0))
        st_matrix("QRB_VL", J(t_size*(t_size + 1)/2, 1, 0))
        printf("{txt}(computing segment quantile regressions; one dot per 20 segment fits)\n")
        displayflush()
        ndot = 0
        for (i = 1; i <= t_size - trim_size + 1; i++) {
            jlo = i + trim_size - 1
            while (jlo <= t_size) {
                jhi = jlo + 19
                if (jhi > t_size) jhi = t_size
                stata("plugin call qrbreak_core, genlongp " + strofreal(n_size, "%12.0g") + " " + strofreal(trim_size, "%12.0g") + " " + strofreal(i, "%12.0g") + " " + strofreal(jlo, "%12.0g") + " " + strofreal(jhi, "%12.0g"))
                printf(".")
                ndot = ndot + 1
                if (mod(ndot, 60) == 0) printf("\n")
                displayflush()
                jlo = jhi + 1
            }
        }
        printf("\n")
        displayflush()
        mat_long = st_matrix("QRB_ML")
        vec_long = st_matrix("QRB_VL")
        return
    }
    mat_long = J(t_size*(t_size + 1)/2, n_tau, 0)
    vec_long = J(t_size*(t_size + 1)/2, 1, 0)
    printf("{txt}(computing segment quantile regressions; one dot per start period)\n")
    displayflush()
    for (i = 1; i <= t_size - trim_size + 1; i++) {
        printf(".")
        if (mod(i, 60) == 0) printf("\n")
        displayflush()
        mat_out = qrb_genmatrho(y, x, vec_tau, n_size, trim_size, i, t_size)
        row01 = (i - 1)*t_size + i - (i - 1)*i/2
        row02 = i*t_size - (i - 1)*i/2
        mat_long[|row01, 1 \ row02, n_tau|] = mat_out[|i, 1 \ t_size, n_tau|]
        if (n_tau > 1) {
            vec_long[|row01 \ row02|] = quadrowsum(mat_out[|i, 1 \ t_size, n_tau|])
        }
    }
    printf("\n")
    displayflush()
}

// --------------------------------------------------------------------------------
// partition (port of partition.R); loc_min and rho_min returned by reference
// --------------------------------------------------------------------------------
void qrb_partition(real colvector vec_long, real scalar start, real scalar b1, real scalar b2, real scalar last, real scalar t_size, real scalar loc_min, real scalar rho_min)
{
    real scalar ini, j, loc01, loc02, mn, jmin
    real colvector temp_rho

    ini = (start - 1)*t_size - (start - 2)*(start - 1)/2 + 1
    temp_rho = J(t_size, 1, 0)
    for (j = b1; j <= b2; j++) {
        loc01 = j - start + ini
        loc02 = j*t_size - (j - 1)*j/2 + last - j
        temp_rho[j] = vec_long[loc01] + vec_long[loc02]
    }
    mn = .
    jmin = b1
    for (j = b1; j <= b2; j++) {
        if (temp_rho[j] < mn) {
            mn = temp_rho[j]
            jmin = j
        }
    }
    loc_min = jmin
    rho_min = temp_rho[jmin]
}

// --------------------------------------------------------------------------------
// brdate: break dates by dynamic programming (verbatim port of brdate.R,
// including the original loop structure in which the ib-loop is nested inside
// the j1-loop; this is redundant computation but is kept for exactness)
// --------------------------------------------------------------------------------
real matrix qrb_brdate(real colvector y, real matrix x, real scalar n_size, real scalar m, real scalar trim_size, real colvector vec_long)
{
    real scalar t_size, j1, ib, jlast, jb, beg01, end01, min_loc, i, xx2, lm, rm, mn, jj
    real matrix mat_date, mat_opt_loc, mat_opt_rho
    real colvector dvec, vec_global

    t_size = rows(y)/n_size
    mat_date = J(m, m, 0)
    mat_opt_loc = J(t_size, m, 0)
    mat_opt_rho = J(t_size, m, 0)
    dvec = J(t_size, 1, 0)
    vec_global = J(m, 1, 0)
    lm = 0
    rm = 0
    if (m == 1) {
        qrb_partition(vec_long, 1, trim_size, t_size - trim_size, t_size, t_size, lm, rm)
        mat_date[1, 1] = lm
        vec_global[1] = rm
    }
    else {
        for (j1 = 2*trim_size; j1 <= t_size; j1++) {
            qrb_partition(vec_long, 1, trim_size, j1 - trim_size, j1, t_size, lm, rm)
            mat_opt_rho[j1, 1] = rm
            mat_opt_loc[j1, 1] = lm
        }
        vec_global[1] = mat_opt_rho[t_size, 1]
        mat_date[1, 1] = mat_opt_loc[t_size, 1]
        // in the R original the ib-loop sits inside the j1-loop and all of its
        // work is overwritten on every pass; only the final pass, with column 1
        // fully filled, determines the results, so running it once after the
        // j1-loop reproduces the original arithmetic exactly
        for (ib = 2; ib <= m; ib++) {
                if (ib == m) {
                    jlast = t_size
                    beg01 = ib*trim_size
                    end01 = t_size - trim_size
                    for (jb = beg01; jb <= end01; jb++) {
                        dvec[jb] = mat_opt_rho[jb, ib-1] + vec_long[(jb + 1)*t_size - jb*(jb + 1)/2]
                    }
                    mn = .
                    min_loc = beg01
                    for (jj = beg01; jj <= end01; jj++) {
                        if (dvec[jj] < mn) {
                            mn = dvec[jj]
                            min_loc = jj
                        }
                    }
                    mat_opt_rho[jlast, ib] = dvec[min_loc]
                    mat_opt_loc[jlast, ib] = min_loc
                }
                else {
                    for (jlast = (ib + 1)*trim_size; jlast <= t_size; jlast++) {
                        beg01 = ib*trim_size
                        end01 = jlast - trim_size
                        for (jb = beg01; jb <= end01; jb++) {
                            dvec[jb] = mat_opt_rho[jb, ib-1] + vec_long[jb*t_size - jb*(jb - 1)/2 + jlast - jb]
                        }
                        mn = .
                        min_loc = beg01
                        for (jj = beg01; jj <= end01; jj++) {
                            if (dvec[jj] < mn) {
                                mn = dvec[jj]
                                min_loc = jj
                            }
                        }
                        mat_opt_rho[jlast, ib] = dvec[min_loc]
                        mat_opt_loc[jlast, ib] = min_loc
                    }
                }
                mat_date[ib, ib] = mat_opt_loc[t_size, ib]
                for (i = 1; i <= ib - 1; i++) {
                    xx2 = ib - i
                    mat_date[xx2, ib] = mat_opt_loc[mat_date[xx2 + 1, ib], xx2]
                }
                vec_global[ib] = mat_opt_rho[t_size, ib]
        }
    }
    return(mat_date)
}

// --------------------------------------------------------------------------------
// sample.split (port of sample.split.R)
// --------------------------------------------------------------------------------
void qrb_samplesplit(real colvector y, real matrix x, real scalar v_date, real scalar n_size, real colvector y1, real matrix x1, real colvector y2, real matrix x2)
{
    real scalar nt01, nt_size
    nt01 = v_date*n_size
    nt_size = rows(y)
    y1 = y[|1 \ nt01|]
    x1 = x[|1, 1 \ nt01, cols(x)|]
    y2 = y[|nt01 + 1 \ nt_size|]
    x2 = x[|nt01 + 1, 1 \ nt_size, cols(x)|]
}

// --------------------------------------------------------------------------------
// sq.test.0vs1: SQ test of 0 versus 1 break (port of sq.test.0vs1.R)
// --------------------------------------------------------------------------------
real matrix qrb_specinvsq(real matrix bigX)
{
    /* spectral normalization of QR.break 1.0.3: invsq = Mtilde^(-1/2) D^(-1) */
    real matrix MM, Mt, V, W
    real colvector dscale
    real rowvector lam
    real scalar pp

    pp = cols(bigX)
    MM = cross(bigX, bigX)
    dscale = sqrt(diagonal(MM))
    if (min(dscale) <= 0) {
        errprintf("a column of the regressor matrix is identically zero; the spectral normalization is not defined\n")
        exit(198)
    }
    Mt = MM :/ (dscale*dscale')
    V = .
    lam = .
    symeigensystem(Mt, V, lam)
    if (min(lam) <= 0 | min(lam)/max(lam) < 1e-12) {
        errprintf("the regressor matrix is (nearly) collinear; the spectral test statistic is not well defined (this can occur when a regressor is nearly constant)\n")
        exit(198)
    }
    W = V' :/ sqrt(lam')
    return((V*W) :/ dscale')
}

real scalar qrb_sqtest0vs1(real colvector y, real matrix x, real scalar v_tau, real scalar n_size)
{
    real scalar t_size, j, end1, p
    real matrix bigX, L, invsq, M
    real colvector res, temp, H1n, HH, b
    real rowvector difH

    if (st_global("QRB_PLUGIN") == "1") {
        st_matrix("QRB_PY", y)
        st_matrix("QRB_PX", x)
        st_matrix("QRB_TAU", (v_tau))
        st_matrix("QRB_OUT", J(1, 1, 0))
        stata("plugin call qrbreak_core, sqtest " + strofreal(n_size, "%12.0g") + " " + st_global("QRB_SPECTRAL"))
        return(st_matrix("QRB_OUT")[1, 1])
    }
    t_size = rows(y)/n_size
    bigX = (J(rows(y), 1, 1), x)
    p = cols(bigX)
    if (st_global("QRB_SPECTRAL") == "1") invsq = qrb_specinvsq(bigX)
    else {
        L = cholesky(cross(bigX, bigX))
        invsq = solvelower(L, I(p))
    }
    b = J(p, 1, 0)
    (void) qrb_rqbr(bigX, y, v_tau, b)
    res = y - quadrowsum(bigX :* b')
    temp = (res :<= 0) :- v_tau
    M = invsq*bigX'
    H1n = M*temp
    difH = J(1, t_size, 0)
    for (j = 2; j <= t_size; j++) {
        end1 = n_size*j
        HH = bigX[|1, 1 \ end1, p|]'temp[|1 \ end1|]
        difH[j] = max(abs(invsq*HH - (j/t_size)*H1n))
    }
    return(max(difH)/sqrt(v_tau*(1 - v_tau)))
}

// --------------------------------------------------------------------------------
// sq.test.lvsl_1: SQ test of l versus l+1 breaks (port of sq.test.lvsl_1.R)
// --------------------------------------------------------------------------------
real scalar qrb_sqtestl(real colvector y, real matrix x, real scalar v_tau, real scalar n_size, real rowvector vec_date)
{
    real scalar n_break, j, v_date
    real colvector vec_test, rem_y, y1, y2
    real matrix rem_x, x1, x2
    real rowvector pre_date

    n_break = cols(vec_date)
    vec_test = J(n_break + 1, 1, 0)
    rem_y = y
    rem_x = x
    pre_date = (0, vec_date)
    y1 = J(0, 1, 0)
    y2 = J(0, 1, 0)
    x1 = J(0, 0, 0)
    x2 = J(0, 0, 0)
    for (j = 1; j <= n_break; j++) {
        v_date = vec_date[j] - pre_date[j]
        qrb_samplesplit(rem_y, rem_x, v_date, n_size, y1, x1, y2, x2)
        rem_y = y2
        rem_x = x2
        vec_test[j] = qrb_sqtest0vs1(y1, x1, v_tau, n_size)
    }
    vec_test[n_break + 1] = qrb_sqtest0vs1(rem_y, rem_x, v_tau, n_size)
    return(max(vec_test))
}

// --------------------------------------------------------------------------------
// dq.test.0vs1: DQ test of 0 versus 1 break (port of dq.test.0vs1.R)
// --------------------------------------------------------------------------------
real scalar qrb_dqtest0vs1(real colvector y, real matrix x, real scalar q_L, real scalar q_R, real scalar n_size)
{
    real scalar t_size, p_size, n_tau, k, tt, end1, v_tau, mx, dd
    real matrix bigX, L, invsq, Hlambda, difH, M
    real colvector res, temp, HH, b, Qstat
    real rowvector seq_tau, H1n

    if (st_global("QRB_PLUGIN") == "1") {
        st_matrix("QRB_PY", y)
        st_matrix("QRB_PX", x)
        st_matrix("QRB_OUT", J(1, 1, 0))
        t_size = rows(y)/n_size
        seq_tau = qrb_seq(q_L, q_R, 1/t_size)
        mx = 0
        for (k = 1; k <= cols(seq_tau); k++) {
            st_matrix("QRB_TAU", (seq_tau[k]))
            stata("plugin call qrbreak_core, maxdif " + strofreal(n_size, "%12.0g") + " " + st_global("QRB_SPECTRAL"))
            dd = st_matrix("QRB_OUT")[1, 1]
            if (dd > mx) mx = dd
            if (mod(k, 10) == 0) {
                printf(".")
                displayflush()
            }
        }
        if (cols(seq_tau) >= 10) {
            printf("\n")
            displayflush()
        }
        return(mx)
    }
    t_size = rows(y)/n_size
    bigX = (J(rows(y), 1, 1), x)
    p_size = cols(bigX)
    if (st_global("QRB_SPECTRAL") == "1") invsq = qrb_specinvsq(bigX)
    else {
        L = cholesky(cross(bigX, bigX))
        invsq = solvelower(L, I(p_size))
    }
    seq_tau = qrb_seq(q_L, q_R, 1/t_size)
    n_tau = cols(seq_tau)
    Qstat = J(n_tau, 1, 0)
    M = invsq*bigX'
    for (k = 1; k <= n_tau; k++) {
        v_tau = seq_tau[k]
        b = J(p_size, 1, 0)
        (void) qrb_rqbr(bigX, y, v_tau, b)
        res = y - quadrowsum(bigX :* b')
        temp = (res :<= 0) :- v_tau
        H1n = (M*temp)'
        Hlambda = J(t_size, p_size, 0)
        difH = J(t_size, p_size, 0)
        for (tt = 2; tt <= t_size; tt++) {
            end1 = tt*n_size
            HH = bigX[|1, 1 \ end1, p_size|]'temp[|1 \ end1|]
            Hlambda[tt, .] = (invsq*HH)'
            difH[tt, .] = Hlambda[tt, .] - (tt/t_size)*H1n
        }
        Qstat[k] = max(abs(difH))
    }
    return(max(Qstat))
}

// --------------------------------------------------------------------------------
// dq.test.lvsl_1: DQ test of l versus l+1 breaks (port of dq.test.lvsl_1.R)
// --------------------------------------------------------------------------------
real scalar qrb_dqtestl(real colvector y, real matrix x, real scalar q_L, real scalar q_R, real scalar n_size, real rowvector vec_date)
{
    real scalar n_break, j, v_date
    real colvector vec_test, rem_y, y1, y2
    real matrix rem_x, x1, x2
    real rowvector pre_date

    n_break = cols(vec_date)
    vec_test = J(n_break + 1, 1, 0)
    rem_y = y
    rem_x = x
    pre_date = (0, vec_date)
    y1 = J(0, 1, 0)
    y2 = J(0, 1, 0)
    x1 = J(0, 0, 0)
    x2 = J(0, 0, 0)
    for (j = 1; j <= n_break; j++) {
        v_date = vec_date[j] - pre_date[j]
        qrb_samplesplit(rem_y, rem_x, v_date, n_size, y1, x1, y2, x2)
        rem_y = y2
        rem_x = x2
        vec_test[j] = qrb_dqtest0vs1(y1, x1, q_L, q_R, n_size)
    }
    vec_test[n_break + 1] = qrb_dqtest0vs1(rem_y, rem_x, q_L, q_R, n_size)
    return(max(vec_test))
}

// --------------------------------------------------------------------------------
// sq: number of breaks via sequential SQ tests (port of sq.R); results
// returned by reference: vec_test (1 x m_max), mat_cv (3 x m_max),
// mat_date_opt (3 x m_max), vec_nb (3 x 1)
// --------------------------------------------------------------------------------
void qrb_sq(real colvector y, real matrix x, real scalar v_tau, real scalar n_size, real scalar m_max, real scalar trim_size, real matrix mat_date, real rowvector vec_test, real matrix mat_cv, real matrix mat_date_opt, real colvector vec_nb)
{
    real scalar p_size, a, k, nb
    real rowvector vec_loc

    p_size = cols(x) + 1
    vec_nb = J(3, 1, 0)
    vec_test = J(1, m_max, 0)
    mat_cv = J(3, m_max, 0)
    vec_test[1] = qrb_sqtest0vs1(y, x, v_tau, n_size)
    mat_cv[., 1] = qrb_getcvsq(0, p_size)
    for (a = 1; a <= 3; a++) {
        if (mat_cv[a, 1] < vec_test[1]) vec_nb[a] = 1
    }
    if (m_max >= 2) {
        for (k = 1; k <= m_max - 1; k++) {
            if (max(vec_nb) == k) {
                vec_loc = mat_date[|1, k \ k, k|]'
                vec_test[k + 1] = qrb_sqtestl(y, x, v_tau, n_size, vec_loc)
                mat_cv[., k + 1] = qrb_getcvsq(k, p_size)
                for (a = 1; a <= 3; a++) {
                    if (vec_nb[a] == k & mat_cv[a, k + 1] < vec_test[k + 1]) vec_nb[a] = vec_nb[a] + 1
                }
            }
        }
    }
    mat_date_opt = J(3, m_max, 0)
    for (a = 1; a <= 3; a++) {
        nb = vec_nb[a]
        if (nb >= 1) mat_date_opt[|a, 1 \ a, nb|] = mat_date[|1, nb \ nb, nb|]'
    }
}

// --------------------------------------------------------------------------------
// dq: number of breaks via sequential DQ tests (port of dq.R)
// --------------------------------------------------------------------------------
void qrb_dq(real colvector y, real matrix x, real rowvector vec_tau, real scalar q_L, real scalar q_R, real scalar n_size, real scalar m_max, real scalar trim_size, real matrix mat_date, real scalar d_Sym, real matrix table_cv, real rowvector vec_test, real matrix mat_cv, real matrix mat_date_opt, real colvector vec_nb)
{
    real scalar p_size, a, k, nb
    real rowvector vec_loc

    p_size = cols(x) + 1
    vec_nb = J(3, 1, 0)
    vec_test = J(1, m_max, 0)
    mat_cv = J(3, m_max, 0)
    vec_test[1] = qrb_dqtest0vs1(y, x, q_L, q_R, n_size)
    mat_cv[., 1] = qrb_getcvdq(0, p_size, q_L, q_R, d_Sym, table_cv)
    for (a = 1; a <= 3; a++) {
        if (mat_cv[a, 1] < vec_test[1]) vec_nb[a] = 1
    }
    if (m_max >= 2) {
        for (k = 1; k <= m_max - 1; k++) {
            if (max(vec_nb) == k) {
                vec_loc = mat_date[|1, k \ k, k|]'
                vec_test[k + 1] = qrb_dqtestl(y, x, q_L, q_R, n_size, vec_loc)
                mat_cv[., k + 1] = qrb_getcvdq(k, p_size, q_L, q_R, d_Sym, table_cv)
                for (a = 1; a <= 3; a++) {
                    if (vec_nb[a] == k & mat_cv[a, k + 1] < vec_test[k + 1]) vec_nb[a] = vec_nb[a] + 1
                }
            }
        }
    }
    mat_date_opt = J(3, m_max, 0)
    for (a = 1; a <= 3; a++) {
        nb = vec_nb[a]
        if (nb >= 1) mat_date_opt[|a, 1 \ a, nb|] = mat_date[|1, nb \ nb, nb|]'
    }
}

// --------------------------------------------------------------------------------
// rq.est.full: quantile regression with all coefficients allowed to change at
// the estimated break dates (port of rq.est.full.R); the design matrix has a
// stairs structure so that the coefficients on the added blocks are the break
// sizes; X and coef returned by reference
// --------------------------------------------------------------------------------
void qrb_rqestfull(real colvector y, real matrix x, real scalar v_tau, real rowvector vec_date, real scalar n_size, real colvector coef, real matrix X, real colvector resid)
{
    real scalar nt_size, p_size, n_break, i, r_beg, c_beg, c_end
    real matrix x1, b_size

    x1 = (J(rows(y), 1, 1), x)
    nt_size = rows(y)
    p_size = cols(x1)
    n_break = cols(vec_date)
    b_size = J(nt_size, n_break*p_size, 0)
    for (i = 1; i <= n_break; i++) {
        r_beg = n_size*vec_date[i] + 1
        c_beg = p_size*(i - 1) + 1
        c_end = p_size*i
        b_size[|r_beg, c_beg \ nt_size, c_end|] = x1[|r_beg, 1 \ nt_size, p_size|]
    }
    X = (J(nt_size, 1, 1), x, b_size)
    (void) qrb_rq(X, y, v_tau, coef, resid)
}

// --------------------------------------------------------------------------------
// summary.rq with se="nid" (port from quantreg v6.1 summary.rq): returns the
// 4-column coefficient table (Value, Std. Error, t value, Pr(>|t|)); fis
// count of non-positive density estimates returned by reference
// --------------------------------------------------------------------------------
real matrix qrb_summarynid(real matrix X, real colvector y, real scalar tau, real colvector coef, real scalar nfis)
{
    real scalar n, p, rdf, eps, h, j
    real colvector bhi, blo, dyhat, f, serr, tv, pv
    real matrix fxxinv, xx, cov, tab, Lf, Ri

    n = rows(X)
    p = cols(X)
    rdf = n - p
    eps = epsilon(1)^(1/2)
    h = qrb_bandwidth(tau, n, 1)
    while ((tau - h < 0) | (tau + h > 1)) h = h/2
    bhi = J(p, 1, 0)
    blo = J(p, 1, 0)
    (void) qrb_rqbr(X, y, tau + h, bhi)
    (void) qrb_rqbr(X, y, tau - h, blo)
    dyhat = X*(bhi - blo)
    nfis = sum(dyhat :<= 0)
    f = (2*h) :/ (dyhat :- eps)
    f = f :* (f :> 0)
    Lf = cholesky(cross(X, f, X))
    Ri = solvelower(Lf, I(p))
    fxxinv = Ri'Ri
    xx = cross(X, X)
    cov = tau*(1 - tau)*fxxinv*xx*fxxinv
    serr = sqrt(diagonal(cov))
    tv = coef :/ serr
    if (rdf > 0) pv = 2*ttail(rdf, abs(tv))
    else pv = J(p, 1, .)
    tab = (coef, serr, tv, pv)
    return(tab)
}

// --------------------------------------------------------------------------------
// rq.est.regime: regime-by-regime estimates with nid standard errors (port of
// rq.est.regime.R); returns the stacked (n_break+1)*p x 4 table; fis counts
// per regime returned by reference
// --------------------------------------------------------------------------------
real matrix qrb_rqestregime(real colvector y, real matrix x, real scalar v_tau, real rowvector vec_date, real scalar n_size, real colvector vfis)
{
    real scalar n_break, j, v_date, nf
    real colvector rem_y, y1, y2, b, res
    real matrix rem_x, x1, x2, out, X, tab
    real rowvector pre_date

    n_break = cols(vec_date)
    out = J(0, 4, 0)
    vfis = J(n_break + 1, 1, 0)
    rem_y = y
    rem_x = x
    pre_date = (0, vec_date)
    y1 = J(0, 1, 0)
    y2 = J(0, 1, 0)
    x1 = J(0, 0, 0)
    x2 = J(0, 0, 0)
    nf = 0
    for (j = 1; j <= n_break; j++) {
        v_date = vec_date[j] - pre_date[j]
        qrb_samplesplit(rem_y, rem_x, v_date, n_size, y1, x1, y2, x2)
        rem_y = y2
        rem_x = x2
        X = (J(rows(y1), 1, 1), x1)
        b = J(cols(X), 1, 0)
        res = J(0, 1, 0)
        (void) qrb_rq(X, y1, v_tau, b, res)
        tab = qrb_summarynid(X, y1, v_tau, b, nf)
        vfis[j] = nf
        out = out \ tab
    }
    X = (J(rows(rem_y), 1, 1), rem_x)
    b = J(cols(X), 1, 0)
    res = J(0, 1, 0)
    (void) qrb_rq(X, rem_y, v_tau, b, res)
    tab = qrb_summarynid(X, rem_y, v_tau, b, nf)
    vfis[n_break + 1] = nf
    out = out \ tab
    return(out)
}

// --------------------------------------------------------------------------------
// moment: H and J matrices for break date confidence intervals (port of
// moment.R); uses the Bofinger bandwidth and the Frisch-Newton fits, exactly
// as the original
// --------------------------------------------------------------------------------
void qrb_moment(real colvector y, real matrix x, real scalar v_tau, real matrix H, real matrix Jm, real scalar nfis)
{
    real scalar eps, nt_size, h
    real matrix x1
    real colvector bhi, blo, dyhat, f

    eps = epsilon(1)^(2/3)
    nt_size = rows(y)
    x1 = (J(nt_size, 1, 1), x)
    h = qrb_bandwidth(v_tau, nt_size, 0)
    if (v_tau + h > 1) _error(3300, "v.tau + h > 1: error in summary.rq")
    if (v_tau - h < 0) _error(3300, "v.tau - h < 0: error in summary.rq")
    bhi = qrb_rqfnb(x1, y, v_tau + h)
    blo = qrb_rqfnb(x1, y, v_tau - h)
    dyhat = x1*(bhi - blo)
    nfis = sum(dyhat :<= 0)
    f = (2*h) :/ (dyhat :- eps)
    f = f :* (f :> 0)
    H = (1/nt_size)*cross(f :* x1, x1)
    Jm = (1/nt_size)*cross(x1, x1)
}

// --------------------------------------------------------------------------------
// ci.date.m.sub (port of ci.date.m.sub.R)
// --------------------------------------------------------------------------------
real rowvector qrb_cidatemsub(real colvector yL, real matrix xL, real colvector yR, real matrix xR, real scalar v_date, real matrix mat_size0, real rowvector vec_tau, real scalar n_size, real scalar v_b, real scalar nfis)
{
    real scalar n_tau, i, s, v_tau, temp, piL, piR, s2L, s2R, nf1, nf2
    real matrix mat_size, matL, matR, HL, JL, HR, JR
    real colvector vec_size, vec_sizeS
    real rowvector vec_Q, vec_ci

    n_tau = cols(vec_tau)
    mat_size = mat_size0*sqrt(n_size)
    matL = J(n_tau, 2, 0)
    matR = J(n_tau, 2, 0)
    HL = .
    JL = .
    HR = .
    JR = .
    nf1 = 0
    nf2 = 0
    nfis = 0
    for (i = 1; i <= n_tau; i++) {
        v_tau = vec_tau[i]
        vec_size = mat_size[., i]
        qrb_moment(yL, xL, v_tau, HL, JL, nf1)
        qrb_moment(yR, xR, v_tau, HR, JR, nf2)
        nfis = nfis + nf1 + nf2
        matL[i, 1] = vec_size'HL*vec_size
        matR[i, 1] = vec_size'HR*vec_size
        for (s = 1; s <= n_tau; s++) {
            vec_sizeS = mat_size[., s]
            temp = min((v_tau, vec_tau[s])) - v_tau*vec_tau[s]
            matL[i, 2] = matL[i, 2] + temp*vec_size'JL*vec_sizeS
            matR[i, 2] = matR[i, 2] + temp*vec_size'JR*vec_sizeS
        }
    }
    piL = quadsum(matL[., 1])
    piR = quadsum(matR[., 1])
    s2L = quadsum(matL[., 2])
    s2R = quadsum(matR[., 2])
    vec_Q = (7.7, 11.0)
    vec_ci = J(1, 3, 0)
    vec_ci[1] = v_date
    vec_ci[2] = v_date - qrb_rround(vec_Q[v_b]*s2L/(piL^2)) - 1
    vec_ci[3] = v_date + qrb_rround(vec_Q[v_b]*s2R/(piR^2)) + 1
    return(vec_ci)
}

// --------------------------------------------------------------------------------
// ci.date.m: confidence intervals for break dates (port of ci.date.m.R)
// --------------------------------------------------------------------------------
real matrix qrb_cidatem(real colvector y, real matrix x, real rowvector vec_tau, real rowvector vec_date, real scalar n_size, real scalar v_b, real scalar nfis)
{
    real scalar n_break, n_tau, p_size, k, i, v_tau, date02, v_date, beg_row, end_row, nf
    real matrix mat_ci, mat_size, xL, xR, x_rem, temp_size, Xf
    real colvector vec_b, yL, yR, y_rem, rf

    n_break = cols(vec_date)
    n_tau = cols(vec_tau)
    p_size = cols(x) + 1
    mat_ci = J(n_break, 3, 0)
    mat_ci[., 1] = vec_date'
    mat_size = J(n_break*p_size, n_tau, 0)
    Xf = .
    rf = J(0, 1, 0)
    for (k = 1; k <= n_tau; k++) {
        v_tau = vec_tau[k]
        vec_b = J(0, 1, 0)
        qrb_rqestfull(y, x, v_tau, vec_date, n_size, vec_b, Xf, rf)
        mat_size[., k] = vec_b[|p_size + 1 \ (n_break + 1)*p_size|]
    }
    yL = J(0, 1, 0)
    yR = J(0, 1, 0)
    y_rem = J(0, 1, 0)
    xL = J(0, 0, 0)
    xR = J(0, 0, 0)
    x_rem = J(0, 0, 0)
    qrb_samplesplit(y, x, vec_date[1], n_size, yL, xL, y_rem, x_rem)
    nfis = 0
    nf = 0
    if (n_break >= 2) {
        for (i = 1; i <= n_break - 1; i++) {
            date02 = vec_date[i + 1] - vec_date[i]
            qrb_samplesplit(y_rem, x_rem, date02, n_size, yR, xR, y_rem, x_rem)
            v_date = vec_date[i]
            beg_row = p_size*(i - 1) + 1
            end_row = p_size*i
            temp_size = mat_size[|beg_row, 1 \ end_row, n_tau|]
            mat_ci[i, .] = qrb_cidatemsub(yL, xL, yR, xR, v_date, temp_size, vec_tau, n_size, v_b, nf)
            nfis = nfis + nf
            yL = yR
            xL = xR
        }
    }
    v_date = vec_date[n_break]
    beg_row = p_size*(n_break - 1) + 1
    end_row = p_size*n_break
    temp_size = mat_size[|beg_row, 1 \ end_row, n_tau|]
    mat_ci[n_break, .] = qrb_cidatemsub(yL, xL, y_rem, x_rem, v_date, temp_size, vec_tau, n_size, v_b, nf)
    nfis = nfis + nf
    return(mat_ci)
}

// --------------------------------------------------------------------------------
// get.cv.sq: critical values of the SQ test from the stored table (port of
// get.cv.sq.R and input.all.cv.R)
// --------------------------------------------------------------------------------
real colvector qrb_getcvsq(real scalar n_break, real scalar p_size)
{
    real matrix cvt
    real scalar row_beg, row_end
    cvt = qrb_cvsq_table()
    row_beg = 4*(p_size - 1) + 2
    row_end = 4*(p_size - 1) + 4
    return(cvt[|row_beg, n_break + 1 \ row_end, n_break + 1|])
}

// --------------------------------------------------------------------------------
// res.surface: response surface critical values for the DQ test with a
// symmetric quantile range (port of res.surface.R)
// --------------------------------------------------------------------------------
real colvector qrb_ressurface(real scalar p, real scalar l, real scalar q_L, real scalar q_R, real scalar d_Sym)
{
    real colvector vec_cv
    if (d_Sym != 1) _error(3300, "res.surface is only for the DQ test with a symmetric quantile range")
    vec_cv = J(3, 1, 0)
    vec_cv[1] = 0.9481 + 0.0062*p + 0.0166*(l + 1) - 0.1386*(1/p)
    vec_cv[2] = 0.9944 + 0.0058*p + 0.0157*(l + 1) - 0.1284*(1/p)
    vec_cv[3] = 1.0929 + 0.0050*p + 0.0134*(l + 1) - 0.1134*(1/p)
    vec_cv[1] = vec_cv[1] - 0.0004*(l + 1)*p + 0.0018*(l + 1)*q_L
    vec_cv[2] = vec_cv[2] - 0.0004*(l + 1)*p + 0.0017*(l + 1)*q_L
    vec_cv[3] = vec_cv[3] - 0.0002*(l + 1)*p + 0.0010*(l + 1)*q_L
    vec_cv[1] = vec_cv[1]*exp(-0.0801*(1/(l + 1)) - 0.0004*(1/(q_L*(l + 1))) - 0.0254*q_L)
    vec_cv[2] = vec_cv[2]*exp(-0.0716*(1/(l + 1)) - 0.0005*(1/(q_L*(l + 1))) - 0.0203*q_L)
    vec_cv[3] = vec_cv[3]*exp(-0.0565*(1/(l + 1)) - 0.0000*(1/(q_L*(l + 1))) - 0.0062*q_L)
    return(vec_cv)
}

// --------------------------------------------------------------------------------
// get.cv.dq (port of get.cv.dq.R)
// --------------------------------------------------------------------------------
real colvector qrb_getcvdq(real scalar n_break, real scalar p_size, real scalar q_L, real scalar q_R, real scalar d_Sym, real matrix table_cv)
{
    if (d_Sym == 1) return(qrb_ressurface(p_size, n_break, q_L, q_R, d_Sym))
    else return(table_cv[|4, n_break + 1 \ 6, n_break + 1|])
}

// --------------------------------------------------------------------------------
// vec.prob.DQ: simulated limiting distribution draws (port of vec.prob.DQ.R).
// Note: this uses Stata's runiform() where R uses runif(); the original code
// does not set a random seed, so the simulated critical values are inherently
// stochastic in both implementations.
// --------------------------------------------------------------------------------
real colvector qrb_vecprobDQ(real scalar n_grid, real scalar n_dim, real scalar n_sim, real rowvector vec_tau)
{
    real scalar n_tau, s, d, i, v_tau, sq
    real colvector vec_p, vec_max, vec_limit, vec_e, vec_bm, vec_BB, vec_lamda

    n_tau = cols(vec_tau)
    // R seq(0, 1, length.out = n.grid) semantics: multiply by the reciprocal
    // and pin the last element to exactly 1 (verified empirically against R)
    vec_lamda = (0::(n_grid - 1))*(1/(n_grid - 1))
    vec_lamda[n_grid] = 1
    vec_p = J(n_sim, 1, 0)
    sq = sqrt(n_grid)
    vec_max = J(n_dim, 1, 0)
    vec_limit = J(n_tau, 1, 0)
    for (s = 1; s <= n_sim; s++) {
        if (mod(s, 250) == 0) {
            printf(".")
            if (mod(s, 15000) == 0) printf("\n")
            displayflush()
        }
        for (d = 1; d <= n_dim; d++) {
            vec_e = runiform(n_grid, 1)
            for (i = 1; i <= n_tau; i++) {
                v_tau = vec_tau[i]
                vec_bm = runningsum(vec_e :<= v_tau)
                vec_BB = (vec_bm - vec_lamda*vec_bm[n_grid])/sq
                vec_limit[i] = max(abs(vec_BB))
            }
            vec_max[d] = max(vec_limit)
        }
        vec_p[s] = max(vec_max)
    }
    return(vec_p)
}

// --------------------------------------------------------------------------------
// critical.DQtest_specific: simulated critical values for the DQ test with a
// quantile range for which no response surface is available (port of
// critical.DQtest_specific.R)
// --------------------------------------------------------------------------------
real matrix qrb_criticalDQspecific(real matrix x, real scalar m_max, real rowvector vec_tau)
{
    real scalar p_size, n_grid, n_sim, beg_tau, end_tau, k, j
    real rowvector cont_tau, vec_nn
    real matrix mat_prob, mat_index, table_cv, mat_cv
    real colvector vec_p, vec_name

    p_size = cols(x) + 1
    n_grid = 500
    n_sim = 50000
    vec_nn = 1..m_max
    mat_prob = J(3, m_max, 0)
    mat_prob[1, .] = 0.90 :^ (1 :/ vec_nn)
    mat_prob[2, .] = 0.95 :^ (1 :/ vec_nn)
    mat_prob[3, .] = 0.99 :^ (1 :/ vec_nn)
    mat_index = J(3, m_max, 0)
    for (k = 1; k <= 3; k++) {
        for (j = 1; j <= m_max; j++) mat_index[k, j] = qrb_rround(mat_prob[k, j]*n_sim)
    }
    beg_tau = min(vec_tau)
    end_tau = max(vec_tau)
    cont_tau = qrb_seq(beg_tau, end_tau, 1/n_grid)
    vec_p = qrb_vecprobDQ(n_grid, p_size, n_sim, cont_tau)
    vec_p = sort(vec_p, 1)
    mat_cv = J(3, m_max, 0)
    for (k = 1; k <= 3; k++) {
        for (j = 1; j <= m_max; j++) mat_cv[k, j] = vec_p[mat_index[k, j]]
    }
    table_cv = J(2, m_max, 0)
    table_cv[1, .] = J(1, m_max, beg_tau)
    table_cv[2, .] = J(1, m_max, end_tau)
    return(table_cv \ J(1, m_max, p_size) \ mat_cv)
}

// --------------------------------------------------------------------------------
// cv.sq: simulated critical values for the SQ test (port of cv.sq.R); this is
// a stand-alone utility mirroring the exported R function; the main command
// uses the stored table via qrb_getcvsq()
// --------------------------------------------------------------------------------
real matrix qrb_cvsq_sim(real scalar p_size, real scalar m_max)
{
    real scalar tau, n_grid, n_sim, k, j
    real rowvector vec_nn
    real matrix mat_prob, mat_index, mat_cv
    real colvector vec_p

    tau = 0.5
    n_grid = max((1000, 50*p_size))
    n_sim = 500000
    vec_nn = 1..m_max
    mat_prob = J(3, m_max, 0)
    mat_prob[1, .] = 0.90 :^ (1 :/ vec_nn)
    mat_prob[2, .] = 0.95 :^ (1 :/ vec_nn)
    mat_prob[3, .] = 0.99 :^ (1 :/ vec_nn)
    mat_index = J(3, m_max, 0)
    for (k = 1; k <= 3; k++) {
        for (j = 1; j <= m_max; j++) mat_index[k, j] = qrb_rround(mat_prob[k, j]*n_sim)
    }
    vec_p = qrb_vecprobDQ(n_grid, p_size, n_sim, (tau))
    vec_p = sort(vec_p, 1)
    mat_cv = J(3, m_max, 0)
    for (k = 1; k <= 3; k++) {
        for (j = 1; j <= m_max; j++) mat_cv[k, j] = vec_p[mat_index[k, j]]
    }
    return(J(1, m_max, p_size) \ (mat_cv/sqrt(tau*(1 - tau))))
}

// --------------------------------------------------------------------------------
// input.all.cv: stored critical values of the SQ test (port of input.all.cv.R)
// rows: blocks of 4 per number of coefficients p = 1..100 (p, then the 90, 95,
// and 99 percent critical values); columns: number of breaks 1..10
// --------------------------------------------------------------------------------
real matrix qrb_cvsq_p1()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "1.000000 1.000000 1.000000 1.000000 1.000000 1.000000 1.000000 1.000000 1.000000 1.000000"
    s[2] = "1.210592 1.338982 1.410205 1.460535 1.497571 1.528086 1.552713 1.573415 1.591775 1.607729"
    s[3] = "1.343541 1.464904 1.532201 1.577530 1.611970 1.640902 1.663567 1.683699 1.699716 1.715987"
    s[4] = "1.615452 1.718203 1.774801 1.813229 1.845833 1.873373 1.890529 1.909965 1.921867 1.938264"
    s[5] = "2.000000 2.000000 2.000000 2.000000 2.000000 2.000000 2.000000 2.000000 2.000000 2.000000"
    s[6] = "1.338982 1.459712 1.527010 1.572149 1.606526 1.634825 1.658566 1.677748 1.694905 1.711365"
    s[7] = "1.464144 1.576454 1.638940 1.681990 1.714847 1.740424 1.762519 1.781132 1.797149 1.813103"
    s[8] = "1.717506 1.816331 1.874069 1.912434 1.939530 1.962068 1.984100 2.003346 2.019363 2.030695"
    s[9] = "3.000000 3.000000 3.000000 3.000000 3.000000 3.000000 3.000000 3.000000 3.000000 3.000000"
    s[10] = "1.409825 1.525807 1.588989 1.633432 1.666036 1.692752 1.715417 1.733776 1.751186 1.765747"
    s[11] = "1.529859 1.637547 1.696234 1.738018 1.769166 1.794300 1.817091 1.836274 1.851404 1.866535"
    s[12] = "1.772332 1.869827 1.922437 1.959283 1.989734 2.013032 2.031391 2.045573 2.057285 2.067161"
    s[13] = "4.000000 4.000000 4.000000 4.000000 4.000000 4.000000 4.000000 4.000000 4.000000 4.000000"
    s[14] = "1.459269 1.570693 1.632609 1.675089 1.708200 1.734093 1.755555 1.773724 1.789488 1.804492"
    s[15] = "1.574681 1.679331 1.737955 1.777903 1.808354 1.834121 1.855203 1.873879 1.888693 1.904774"
    s[16] = "1.811267 1.907623 1.957953 1.997458 2.026897 2.046522 2.062033 2.076277 2.091092 2.100905"
    s[17] = "5.000000 5.000000 5.000000 5.000000 5.000000 5.000000 5.000000 5.000000 5.000000 5.000000"
    s[18] = "1.495988 1.604563 1.665466 1.708010 1.740107 1.764988 1.786576 1.805252 1.821649 1.836400"
    s[19] = "1.609058 1.712315 1.768660 1.809051 1.840389 1.865332 1.886161 1.905090 1.919588 1.933199"
    s[20] = "1.843617 1.936175 1.990241 2.026137 2.051270 2.069440 2.090269 2.103184 2.115212 2.127178"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p2()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "6.000000 6.000000 6.000000 6.000000 6.000000 6.000000 6.000000 6.000000 6.000000 6.000000"
    s[2] = "1.525300 1.632229 1.692309 1.733903 1.765178 1.789995 1.811900 1.829563 1.846086 1.859951"
    s[3] = "1.636218 1.737828 1.793730 1.833741 1.863623 1.888250 1.909902 1.926299 1.942379 1.955484"
    s[4] = "1.866598 1.957763 2.012462 2.045573 2.069313 2.092928 2.108945 2.122999 2.136168 2.149462"
    s[5] = "7.000000 7.000000 7.000000 7.000000 7.000000 7.000000 7.000000 7.000000 7.000000 7.000000"
    s[6] = "1.549484 1.656476 1.715797 1.756884 1.787906 1.813672 1.834184 1.851848 1.867358 1.881729"
    s[7] = "1.660148 1.760430 1.817091 1.855203 1.885211 1.910092 1.929844 1.947381 1.962195 1.977642"
    s[8] = "1.887680 1.980175 2.030695 2.062349 2.089952 2.110338 2.128507 2.141802 2.156426 2.169721"
    s[9] = "8.000000 8.000000 8.000000 8.000000 8.000000 8.000000 8.000000 8.000000 8.000000 8.000000"
    s[10] = "1.570313 1.675279 1.734853 1.776447 1.807025 1.830956 1.851848 1.869764 1.885211 1.900026"
    s[11] = "1.679584 1.780182 1.835071 1.873373 1.903761 1.926235 1.946558 1.964094 1.980808 1.995749"
    s[12] = "1.906420 1.998218 2.045763 2.077734 2.104703 2.124455 2.141802 2.157376 2.172127 2.184472"
    s[13] = "9.000000 9.000000 9.000000 9.000000 9.000000 9.000000 9.000000 9.000000 9.000000 9.000000"
    s[14] = "1.588736 1.692436 1.751566 1.790818 1.821966 1.846340 1.866409 1.884262 1.900342 1.913700"
    s[15] = "1.696234 1.794680 1.850075 1.887490 1.916486 1.941809 1.960169 1.979921 1.996382 2.009233"
    s[16] = "1.919271 2.011956 2.059184 2.094131 2.117808 2.139143 2.158769 2.175166 2.188967 2.201059"
    s[17] = "10.000000 10.000000 10.000000 10.000000 10.000000 10.000000 10.000000 10.000000 10.000000 10.000000"
    s[18] = "1.604436 1.707313 1.765494 1.806328 1.835767 1.859191 1.880273 1.897810 1.913510 1.926995"
    s[19] = "1.711492 1.809810 1.862800 1.901735 1.930984 1.954471 1.976123 1.994609 2.008980 2.022148"
    s[20] = "1.933833 2.024681 2.070200 2.105336 2.131609 2.152881 2.172317 2.187005 2.202072 2.212581"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p3()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "11.000000 11.000000 11.000000 11.000000 11.000000 11.000000 11.000000 11.000000 11.000000 11.000000"
    s[2] = "1.619821 1.721748 1.779929 1.819180 1.848492 1.872803 1.892872 1.911231 1.925539 1.940100"
    s[3] = "1.725483 1.822409 1.876475 1.914270 1.943392 1.967639 1.989671 2.006891 2.021895 2.034114"
    s[4] = "1.945924 2.036330 2.084064 2.117302 2.143511 2.166429 2.184092 2.199666 2.212391 2.225496"
    s[5] = "12.000000 12.000000 12.000000 12.000000 12.000000 12.000000 12.000000 12.000000 12.000000 12.000000"
    s[6] = "1.632419 1.734283 1.790881 1.830323 1.859508 1.884262 1.905280 1.921867 1.938391 1.951116"
    s[7] = "1.738398 1.834121 1.887617 1.925666 1.954914 1.979288 2.001636 2.017337 2.031835 2.043927"
    s[8] = "1.957193 2.045952 2.094447 2.126608 2.152818 2.175736 2.193209 2.207707 2.219862 2.233283"
    s[9] = "13.000000 13.000000 13.000000 13.000000 13.000000 13.000000 13.000000 13.000000 13.000000 13.000000"
    s[10] = "1.644701 1.745805 1.802403 1.841528 1.870777 1.895087 1.915600 1.933453 1.948267 1.961182"
    s[11] = "1.749730 1.844947 1.899076 1.937188 1.965677 1.990810 2.010436 2.027086 2.041584 2.053486"
    s[12] = "1.968589 2.055955 2.103057 2.136041 2.163770 2.185295 2.203908 2.217393 2.230688 2.243223"
    s[13] = "14.000000 14.000000 14.000000 14.000000 14.000000 14.000000 14.000000 14.000000 14.000000 14.000000"
    s[14] = "1.655970 1.755935 1.813039 1.851404 1.880970 1.905723 1.925286 1.943012 1.957510 1.971691"
    s[15] = "1.759607 1.854633 1.909142 1.946178 1.975553 2.000497 2.019110 2.035317 2.048865 2.061526"
    s[16] = "1.977706 2.063552 2.111984 2.146170 2.172570 2.194475 2.211125 2.227459 2.241577 2.251200"
    s[17] = "15.000000 15.000000 15.000000 15.000000 15.000000 15.000000 15.000000 15.000000 15.000000 15.000000"
    s[18] = "1.665403 1.765494 1.822156 1.859951 1.889959 1.914460 1.935352 1.951559 1.967450 1.980934"
    s[19] = "1.769356 1.863686 1.917562 1.955421 1.984543 2.008157 2.027720 2.043547 2.057285 2.069440"
    s[20] = "1.987582 2.071656 2.119517 2.152818 2.179977 2.201629 2.218343 2.235816 2.248731 2.259430"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p4()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "16.000000 16.000000 16.000000 16.000000 16.000000 16.000000 16.000000 16.000000 16.000000 16.000000"
    s[2] = "1.675089 1.775434 1.830702 1.869447 1.899266 1.922437 1.943392 1.959409 1.975553 1.989608"
    s[3] = "1.779422 1.873246 1.926425 1.962891 1.993090 2.015374 2.034747 2.050194 2.063742 2.075644"
    s[4] = "1.995938 2.077734 2.125658 2.160225 2.186372 2.208276 2.227459 2.242590 2.255062 2.265064"
    s[5] = "17.000000 17.000000 17.000000 17.000000 17.000000 17.000000 17.000000 17.000000 17.000000 17.000000"
    s[6] = "1.684332 1.783727 1.839186 1.877424 1.907496 1.931300 1.950229 1.967639 1.983150 1.997585"
    s[7] = "1.786956 1.880843 1.934972 1.971248 2.001573 2.022781 2.041774 2.056905 2.070263 2.083431"
    s[8] = "2.003915 2.085584 2.132876 2.166366 2.192006 2.213911 2.231637 2.247021 2.260126 2.270762"
    s[9] = "18.000000 18.000000 18.000000 18.000000 18.000000 18.000000 18.000000 18.000000 18.000000 18.000000"
    s[10] = "1.692246 1.790501 1.846530 1.884452 1.914143 1.938961 1.957573 1.975173 1.990241 2.004485"
    s[11] = "1.794300 1.887680 1.941809 1.978212 2.007018 2.029556 2.047345 2.062983 2.076088 2.090015"
    s[12] = "2.009233 2.092231 2.138510 2.172254 2.199540 2.218912 2.238348 2.252339 2.264178 2.275067"
    s[13] = "19.000000 19.000000 19.000000 19.000000 19.000000 19.000000 19.000000 19.000000 19.000000 19.000000"
    s[14] = "1.700159 1.798225 1.853177 1.891416 1.920917 1.945038 1.965170 1.981947 1.997585 2.009803"
    s[15] = "1.802213 1.895404 1.948267 1.985429 2.013095 2.035823 2.053929 2.069440 2.083431 2.096916"
    s[16] = "2.015501 2.099259 2.145031 2.179154 2.205428 2.227965 2.244932 2.259177 2.270762 2.285956"
    s[17] = "20.000000 20.000000 20.000000 20.000000 20.000000 20.000000 20.000000 20.000000 20.000000 20.000000"
    s[18] = "1.708010 1.805949 1.859761 1.898886 1.928008 1.951306 1.971818 1.988721 2.004485 2.016071"
    s[19] = "1.809621 1.902495 1.955104 1.992203 2.019933 2.042344 2.060577 2.075138 2.090649 2.102677"
    s[20] = "2.022338 2.104766 2.150792 2.184726 2.211315 2.233727 2.250503 2.263925 2.275764 2.291084"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p5()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "21.000000 21.000000 21.000000 21.000000 21.000000 21.000000 21.000000 21.000000 21.000000 21.000000"
    s[2] = "1.715606 1.812395 1.867232 1.904889 1.933720 1.957667 1.977554 1.993911 2.008915 2.021624"
    s[3] = "1.816161 1.908301 1.960609 1.996971 2.024507 2.047513 2.065105 2.081345 2.095348 2.108587"
    s[4] = "2.026743 2.111529 2.156658 2.190725 2.215790 2.237560 2.257212 2.271039 2.282160 2.291339"
    s[5] = "22.000000 22.000000 22.000000 22.000000 22.000000 22.000000 22.000000 22.000000 22.000000 22.000000"
    s[6] = "1.722428 1.820152 1.873979 1.911346 1.940592 1.964405 1.983061 2.000510 2.014557 2.028055"
    s[7] = "1.823773 1.914693 1.967917 2.003638 2.031676 2.053569 2.072939 2.090223 2.102678 2.117219"
    s[8] = "2.034255 2.119852 2.164352 2.197494 2.222953 2.243201 2.258125 2.273324 2.288029 2.300759"
    s[9] = "23.000000 23.000000 23.000000 23.000000 23.000000 23.000000 23.000000 23.000000 23.000000 23.000000"
    s[10] = "1.728600 1.825509 1.879558 1.916976 1.944848 1.968254 1.987913 2.004287 2.018197 2.030772"
    s[11] = "1.829204 1.920261 1.971950 2.007572 2.033852 2.056026 2.074710 2.089800 2.103659 2.115465"
    s[12] = "2.036316 2.117364 2.163355 2.194768 2.219406 2.240348 2.256773 2.272172 2.284029 2.294551"
    s[13] = "24.000000 24.000000 24.000000 24.000000 24.000000 24.000000 24.000000 24.000000 24.000000 24.000000"
    s[14] = "1.736288 1.832834 1.887006 1.923458 1.950519 1.974066 1.992749 2.008447 2.023760 2.036713"
    s[15] = "1.836301 1.926732 1.977051 2.011625 2.039313 2.060933 2.077691 2.093533 2.107593 2.119631"
    s[16] = "2.041480 2.121461 2.169662 2.204091 2.228505 2.250510 2.269579 2.281424 2.297796 2.310749"
    s[17] = "25.000000 25.000000 25.000000 25.000000 25.000000 25.000000 25.000000 25.000000 25.000000 25.000000"
    s[18] = "1.742121 1.836598 1.891128 1.928675 1.957570 1.981122 2.000189 2.017717 2.032527 2.045616"
    s[19] = "1.840493 1.932162 1.984836 2.021023 2.048470 2.070708 2.087646 2.102728 2.116950 2.130718"
    s[20] = "2.051006 2.132756 2.179542 2.211653 2.235522 2.252823 2.271256 2.283621 2.297706 2.307263"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p6()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "26.000000 26.000000 26.000000 26.000000 26.000000 26.000000 26.000000 26.000000 26.000000 26.000000"
    s[2] = "1.748736 1.845072 1.898535 1.935088 1.964040 1.987185 2.007169 2.022841 2.037402 2.049487"
    s[3] = "1.848360 1.938632 1.990814 2.026172 2.053074 2.076048 2.094111 2.108373 2.122721 2.135105"
    s[4] = "2.055721 2.137795 2.184084 2.215684 2.238572 2.257318 2.271965 2.289900 2.303564 2.314496"
    s[5] = "27.000000 27.000000 27.000000 27.000000 27.000000 27.000000 27.000000 27.000000 27.000000 27.000000"
    s[6] = "1.753722 1.848264 1.902213 1.940143 1.968469 1.991751 2.009949 2.026453 2.041100 2.053932"
    s[7] = "1.851936 1.943290 1.995221 2.030084 2.056958 2.079998 2.097188 2.112723 2.127168 2.138345"
    s[8] = "2.060065 2.140242 2.184224 2.218603 2.243661 2.261738 2.278362 2.292122 2.301968 2.313346"
    s[9] = "28.000000 28.000000 28.000000 28.000000 28.000000 28.000000 28.000000 28.000000 28.000000 28.000000"
    s[10] = "1.758384 1.854017 1.907737 1.944263 1.972308 1.995003 2.014603 2.031644 2.045551 2.057205"
    s[11] = "1.857265 1.947893 1.998060 2.034777 2.060796 2.082727 2.099730 2.116273 2.129608 2.142980"
    s[12] = "2.063624 2.145426 2.192383 2.225623 2.251184 2.271969 2.288742 2.305744 2.317474 2.326873"
    s[13] = "29.000000 29.000000 29.000000 29.000000 29.000000 29.000000 29.000000 29.000000 29.000000 29.000000"
    s[14] = "1.764200 1.858480 1.912126 1.949534 1.976248 1.998359 2.017389 2.033700 2.047438 2.060161"
    s[15] = "1.861923 1.953340 2.002056 2.036854 2.063097 2.084918 2.102969 2.116997 2.131895 2.144182"
    s[16] = "2.065380 2.146756 2.193696 2.224543 2.249663 2.269454 2.288592 2.302656 2.317663 2.329262"
    s[17] = "30.000000 30.000000 30.000000 30.000000 30.000000 30.000000 30.000000 30.000000 30.000000 30.000000"
    s[18] = "1.768602 1.863028 1.915426 1.953251 1.981431 2.002686 2.021909 2.038066 2.052535 2.065074"
    s[19] = "1.866645 1.957247 2.005615 2.041649 2.068795 2.089912 2.108240 2.125395 2.139279 2.151026"
    s[20] = "2.071551 2.153300 2.197395 2.229605 2.256131 2.278420 2.293337 2.309459 2.320621 2.332781"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p7()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "31.000000 31.000000 31.000000 31.000000 31.000000 31.000000 31.000000 31.000000 31.000000 31.000000"
    s[2] = "1.774165 1.867566 1.920432 1.956868 1.984350 2.007078 2.026328 2.043677 2.058501 2.071291"
    s[3] = "1.871042 1.960377 2.010423 2.046498 2.074177 2.095920 2.113400 2.127207 2.141965 2.155280"
    s[4] = "2.076669 2.157248 2.201882 2.233562 2.258782 2.281083 2.295743 2.310140 2.323258 2.333720"
    s[5] = "32.000000 32.000000 32.000000 32.000000 32.000000 32.000000 32.000000 32.000000 32.000000 32.000000"
    s[6] = "1.777955 1.871295 1.926048 1.961789 1.989681 2.011882 2.031645 2.047436 2.061914 2.074672"
    s[7] = "1.875172 1.965197 2.014697 2.050813 2.078049 2.098593 2.116510 2.133021 2.145122 2.158537"
    s[8] = "2.080519 2.161163 2.207536 2.240056 2.263821 2.284615 2.299250 2.313727 2.326829 2.339462"
    s[9] = "33.000000 33.000000 33.000000 33.000000 33.000000 33.000000 33.000000 33.000000 33.000000 33.000000"
    s[10] = "1.782490 1.875977 1.928588 1.964776 1.992246 2.015088 2.033361 2.050679 2.064503 2.076566"
    s[11] = "1.879590 1.968329 2.018462 2.053724 2.079612 2.100722 2.118099 2.133775 2.148137 2.160050"
    s[12] = "2.081523 2.161902 2.204480 2.239205 2.263749 2.279872 2.298892 2.312418 2.326750 2.336514"
    s[13] = "34.000000 34.000000 34.000000 34.000000 34.000000 34.000000 34.000000 34.000000 34.000000 34.000000"
    s[14] = "1.786227 1.880472 1.932434 1.970720 1.999270 2.021654 2.039383 2.054686 2.069047 2.081210"
    s[15] = "1.883727 1.974003 2.024566 2.058055 2.084436 2.105906 2.123893 2.139995 2.155412 2.167803"
    s[16] = "2.087005 2.170087 2.216282 2.248544 2.271355 2.291341 2.305787 2.320234 2.332853 2.345015"
    s[17] = "35.000000 35.000000 35.000000 35.000000 35.000000 35.000000 35.000000 35.000000 35.000000 35.000000"
    s[18] = "1.789248 1.883527 1.936229 1.973050 2.001451 2.024686 2.044203 2.060604 2.074736 2.088267"
    s[19] = "1.887299 1.976330 2.028294 2.063693 2.091411 2.114263 2.131293 2.146601 2.162072 2.174400"
    s[20] = "2.094336 2.177079 2.223002 2.254110 2.276634 2.297272 2.314274 2.330211 2.341336 2.352817"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p8()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "36.000000 36.000000 36.000000 36.000000 36.000000 36.000000 36.000000 36.000000 36.000000 36.000000"
    s[2] = "1.795504 1.888710 1.941275 1.978222 2.006548 2.028952 2.047714 2.064118 2.078608 2.090452"
    s[3] = "1.892221 1.981969 2.032175 2.067157 2.093440 2.115136 2.132352 2.147288 2.159552 2.171579"
    s[4] = "2.095693 2.174514 2.220842 2.252155 2.277887 2.297042 2.314101 2.328461 2.343999 2.352280"
    s[5] = "37.000000 37.000000 37.000000 37.000000 37.000000 37.000000 37.000000 37.000000 37.000000 37.000000"
    s[6] = "1.798827 1.892353 1.944913 1.981051 2.008035 2.030618 2.049580 2.065222 2.079909 2.091753"
    s[7] = "1.895748 1.984320 2.033284 2.068642 2.095350 2.117279 2.135159 2.151480 2.165463 2.176855"
    s[8] = "2.098091 2.178842 2.224737 2.258260 2.280818 2.299779 2.316629 2.329756 2.342657 2.353245"
    s[9] = "38.000000 38.000000 38.000000 38.000000 38.000000 38.000000 38.000000 38.000000 38.000000 38.000000"
    s[10] = "1.802683 1.895199 1.947316 1.983292 2.010160 2.031930 2.050728 2.065974 2.078925 2.091609"
    s[11] = "1.898605 1.986385 2.035023 2.069501 2.094630 2.116279 2.132588 2.147737 2.161147 2.172165"
    s[12] = "2.097191 2.174484 2.220367 2.255160 2.277872 2.296984 2.315033 2.330038 2.342843 2.354223"
    s[13] = "39.000000 39.000000 39.000000 39.000000 39.000000 39.000000 39.000000 39.000000 39.000000 39.000000"
    s[14] = "1.806159 1.898600 1.951723 1.987997 2.015860 2.038470 2.057758 2.073606 2.088130 2.099749"
    s[15] = "1.902156 1.991460 2.042003 2.076488 2.102933 2.123963 2.141927 2.157055 2.170881 2.184429"
    s[16] = "2.105373 2.186149 2.229767 2.263322 2.287304 2.304710 2.319977 2.332409 2.343726 2.355647"
    s[17] = "40.000000 40.000000 40.000000 40.000000 40.000000 40.000000 40.000000 40.000000 40.000000 40.000000"
    s[18] = "1.811159 1.903577 1.955033 1.991409 2.018546 2.040896 2.059666 2.075304 2.089622 2.102776"
    s[19] = "1.907112 1.994676 2.043961 2.078861 2.105886 2.125864 2.143851 2.158952 2.173360 2.185575"
    s[20] = "2.108526 2.187700 2.234659 2.270342 2.294660 2.312759 2.330925 2.344393 2.356630 2.368554"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p9()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "41.000000 41.000000 41.000000 41.000000 41.000000 41.000000 41.000000 41.000000 41.000000 41.000000"
    s[2] = "1.813944 1.906084 1.957651 1.994666 2.021614 2.043560 2.062078 2.078161 2.091182 2.104095"
    s[3] = "1.909253 1.997576 2.046794 2.081157 2.107156 2.128693 2.146996 2.161138 2.175065 2.187719"
    s[4] = "2.109097 2.190479 2.235751 2.267721 2.291026 2.310579 2.327567 2.338755 2.350850 2.360076"
    s[5] = "42.000000 42.000000 42.000000 42.000000 42.000000 42.000000 42.000000 42.000000 42.000000 42.000000"
    s[6] = "1.816978 1.908882 1.960572 1.997333 2.024862 2.047734 2.066198 2.082520 2.095682 2.107596"
    s[7] = "1.912375 2.000909 2.051144 2.085223 2.110840 2.131154 2.148848 2.163798 2.176565 2.188645"
    s[8] = "2.113106 2.190974 2.236551 2.267823 2.291922 2.310240 2.328766 2.342302 2.353655 2.365777"
    s[9] = "43.000000 43.000000 43.000000 43.000000 43.000000 43.000000 43.000000 43.000000 43.000000 43.000000"
    s[10] = "1.820984 1.912790 1.964313 2.000100 2.028099 2.051342 2.069185 2.085262 2.099834 2.111836"
    s[11] = "1.916122 2.003753 2.054874 2.088233 2.114947 2.136203 2.154528 2.170003 2.183150 2.195333"
    s[12] = "2.117336 2.198604 2.245089 2.274112 2.298419 2.318109 2.335370 2.347734 2.358412 2.369652"
    s[13] = "44.000000 44.000000 44.000000 44.000000 44.000000 44.000000 44.000000 44.000000 44.000000 44.000000"
    s[14] = "1.824723 1.916770 1.969183 2.005405 2.032707 2.055181 2.073719 2.089309 2.102436 2.114342"
    s[15] = "1.920435 2.008837 2.057935 2.092159 2.117231 2.138716 2.155431 2.170284 2.185235 2.197451"
    s[16] = "2.119539 2.200069 2.244570 2.274238 2.298864 2.319205 2.335319 2.351665 2.363610 2.375108"
    s[17] = "45.000000 45.000000 45.000000 45.000000 45.000000 45.000000 45.000000 45.000000 45.000000 45.000000"
    s[18] = "1.827344 1.919770 1.970952 2.007041 2.034244 2.056423 2.075976 2.092587 2.106048 2.118534"
    s[19] = "1.923332 2.010397 2.060060 2.095699 2.121534 2.143000 2.161297 2.176952 2.191556 2.203611"
    s[20] = "2.124271 2.206030 2.252093 2.283664 2.306386 2.327046 2.341895 2.356162 2.368366 2.380646"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p10()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "46.000000 46.000000 46.000000 46.000000 46.000000 46.000000 46.000000 46.000000 46.000000 46.000000"
    s[2] = "1.831245 1.922704 1.974565 2.010318 2.037709 2.060601 2.078360 2.094323 2.107601 2.119319"
    s[3] = "1.926096 2.013529 2.063848 2.097026 2.122657 2.145204 2.162364 2.176803 2.189465 2.200820"
    s[4] = "2.125323 2.202816 2.248074 2.281088 2.305522 2.324514 2.342817 2.358235 2.369990 2.382651"
    s[5] = "47.000000 47.000000 47.000000 47.000000 47.000000 47.000000 47.000000 47.000000 47.000000 47.000000"
    s[6] = "1.832619 1.924020 1.974691 2.010889 2.038236 2.060752 2.080178 2.095511 2.109790 2.122067"
    s[7] = "1.927357 2.013998 2.064212 2.098707 2.125228 2.146498 2.164500 2.179482 2.192672 2.204791"
    s[8] = "2.127652 2.207549 2.250843 2.280912 2.304763 2.324821 2.342402 2.356383 2.371136 2.383413"
    s[9] = "48.000000 48.000000 48.000000 48.000000 48.000000 48.000000 48.000000 48.000000 48.000000 48.000000"
    s[10] = "1.835909 1.926782 1.978549 2.015290 2.042280 2.064504 2.081913 2.097518 2.111557 2.124848"
    s[11] = "1.929896 2.018898 2.067448 2.101092 2.128047 2.149796 2.167222 2.181363 2.194296 2.207042"
    s[12] = "2.130430 2.209510 2.255236 2.284812 2.310542 2.329942 2.349155 2.365168 2.378034 2.389333"
    s[13] = "49.000000 49.000000 49.000000 49.000000 49.000000 49.000000 49.000000 49.000000 49.000000 49.000000"
    s[14] = "1.838915 1.929544 1.980889 2.016461 2.043453 2.065100 2.083133 2.098395 2.112205 2.124942"
    s[15] = "1.932794 2.020025 2.068185 2.101299 2.128555 2.150284 2.168697 2.182936 2.195888 2.208707"
    s[16] = "2.131063 2.210605 2.256901 2.290031 2.314879 2.332995 2.350648 2.366389 2.377624 2.389405"
    s[17] = "50.000000 50.000000 50.000000 50.000000 50.000000 50.000000 50.000000 50.000000 50.000000 50.000000"
    s[18] = "1.841793 1.932885 1.983978 2.019288 2.045858 2.069004 2.087875 2.104538 2.117935 2.130500"
    s[19] = "1.936359 2.022521 2.072029 2.107387 2.133669 2.154766 2.171829 2.186987 2.200032 2.211877"
    s[20] = "2.136214 2.214118 2.262521 2.294694 2.318319 2.336855 2.351645 2.368643 2.380840 2.396623"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p11()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "51.000000 51.000000 51.000000 51.000000 51.000000 51.000000 51.000000 51.000000 51.000000 51.000000"
    s[2] = "1.844541 1.935608 1.986837 2.022791 2.050340 2.072201 2.089930 2.105095 2.119265 2.132706"
    s[3] = "1.939135 2.026240 2.075200 2.108482 2.136233 2.157519 2.175450 2.191003 2.204304 2.215724"
    s[4] = "2.138827 2.218226 2.265476 2.296319 2.321661 2.341037 2.357569 2.372485 2.384776 2.394596"
    s[5] = "52.000000 52.000000 52.000000 52.000000 52.000000 52.000000 52.000000 52.000000 52.000000 52.000000"
    s[6] = "1.846872 1.938388 1.989322 2.025316 2.052089 2.073126 2.091614 2.107611 2.121495 2.133689"
    s[7] = "1.941678 2.028349 2.076537 2.110433 2.136979 2.158440 2.175780 2.191958 2.204726 2.215999"
    s[8] = "2.139092 2.218625 2.264187 2.294732 2.318472 2.337940 2.353197 2.366418 2.379019 2.389765"
    s[9] = "53.000000 53.000000 53.000000 53.000000 53.000000 53.000000 53.000000 53.000000 53.000000 53.000000"
    s[10] = "1.849234 1.940768 1.992467 2.027842 2.054726 2.076212 2.095323 2.111397 2.125697 2.139000"
    s[11] = "1.944332 2.030849 2.079498 2.114521 2.142505 2.163625 2.179655 2.194497 2.208328 2.220296"
    s[12] = "2.144822 2.222232 2.267111 2.297471 2.322360 2.342819 2.359392 2.372489 2.385176 2.398097"
    s[13] = "54.000000 54.000000 54.000000 54.000000 54.000000 54.000000 54.000000 54.000000 54.000000 54.000000"
    s[14] = "1.851585 1.942413 1.992896 2.028619 2.055316 2.076764 2.094947 2.111118 2.125479 2.138000"
    s[15] = "1.945878 2.031643 2.079716 2.114256 2.141109 2.162443 2.180169 2.195015 2.208163 2.220199"
    s[16] = "2.143761 2.222481 2.267688 2.301230 2.326001 2.343542 2.359913 2.372077 2.382203 2.395066"
    s[17] = "55.000000 55.000000 55.000000 55.000000 55.000000 55.000000 55.000000 55.000000 55.000000 55.000000"
    s[18] = "1.855107 1.944134 1.994620 2.030456 2.057010 2.078639 2.096064 2.111131 2.126322 2.137934"
    s[19] = "1.947408 2.033314 2.081843 2.114876 2.141541 2.162976 2.181789 2.196412 2.210049 2.222355"
    s[20] = "2.143761 2.224755 2.272231 2.303086 2.326879 2.346010 2.362534 2.377323 2.391280 2.403780"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p12()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "56.000000 56.000000 56.000000 56.000000 56.000000 56.000000 56.000000 56.000000 56.000000 56.000000"
    s[2] = "1.857211 1.947672 1.998404 2.034135 2.062114 2.085016 2.102625 2.117452 2.130091 2.143014"
    s[3] = "1.951142 2.037416 2.087676 2.120450 2.145944 2.167807 2.184753 2.201106 2.214704 2.225818"
    s[4] = "2.148334 2.227722 2.270704 2.304773 2.329404 2.351158 2.369563 2.383971 2.398677 2.410789"
    s[5] = "57.000000 57.000000 57.000000 57.000000 57.000000 57.000000 57.000000 57.000000 57.000000 57.000000"
    s[6] = "1.859549 1.949295 1.998751 2.033729 2.060134 2.081423 2.100253 2.115731 2.129446 2.142490"
    s[7] = "1.952793 2.036701 2.084645 2.118834 2.144989 2.165016 2.181952 2.197153 2.210343 2.222664"
    s[8] = "2.147448 2.224702 2.268188 2.301180 2.326388 2.343536 2.359171 2.373306 2.386285 2.394911"
    s[9] = "58.000000 58.000000 58.000000 58.000000 58.000000 58.000000 58.000000 58.000000 58.000000 58.000000"
    s[10] = "1.862539 1.953074 2.002960 2.037819 2.064722 2.087654 2.105948 2.121974 2.135298 2.147289"
    s[11] = "1.956584 2.041214 2.090434 2.124652 2.150658 2.172872 2.189616 2.203350 2.216750 2.229228"
    s[12] = "2.153489 2.231175 2.275963 2.307439 2.332408 2.350330 2.366575 2.383191 2.394195 2.406571"
    s[13] = "59.000000 59.000000 59.000000 59.000000 59.000000 59.000000 59.000000 59.000000 59.000000 59.000000"
    s[14] = "1.865273 1.955264 2.006622 2.041272 2.067032 2.088646 2.107414 2.122847 2.137032 2.148919"
    s[15] = "1.958723 2.044431 2.091306 2.126044 2.151841 2.173642 2.191411 2.204921 2.217133 2.228708"
    s[16] = "2.154276 2.230444 2.275458 2.309659 2.333246 2.351626 2.370693 2.384504 2.396928 2.408166"
    s[17] = "60.000000 60.000000 60.000000 60.000000 60.000000 60.000000 60.000000 60.000000 60.000000 60.000000"
    s[18] = "1.867979 1.957653 2.007659 2.043297 2.070850 2.092827 2.110567 2.126213 2.139752 2.151429"
    s[19] = "1.960807 2.046621 2.095932 2.129172 2.155155 2.176024 2.193618 2.208399 2.222596 2.233761"
    s[20] = "2.157699 2.235514 2.281672 2.311198 2.333175 2.350379 2.367316 2.383059 2.394662 2.409127"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p13()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "61.000000 61.000000 61.000000 61.000000 61.000000 61.000000 61.000000 61.000000 61.000000 61.000000"
    s[2] = "1.869235 1.958933 2.010470 2.045175 2.072327 2.093517 2.110976 2.127415 2.140931 2.153248"
    s[3] = "1.962354 2.048418 2.096415 2.130337 2.156598 2.178120 2.196138 2.212220 2.225772 2.237245"
    s[4] = "2.159448 2.239265 2.284636 2.318535 2.342622 2.358859 2.375784 2.391700 2.404325 2.416084"
    s[5] = "62.000000 62.000000 62.000000 62.000000 62.000000 62.000000 62.000000 62.000000 62.000000 62.000000"
    s[6] = "1.871407 1.961610 2.012437 2.046724 2.073882 2.095836 2.113640 2.128627 2.142710 2.154499"
    s[7] = "1.964948 2.049958 2.099197 2.131467 2.157663 2.178365 2.196320 2.210809 2.224092 2.235625"
    s[8] = "2.160201 2.237283 2.282396 2.314492 2.337373 2.356579 2.374835 2.387620 2.400382 2.411127"
    s[9] = "63.000000 63.000000 63.000000 63.000000 63.000000 63.000000 63.000000 63.000000 63.000000 63.000000"
    s[10] = "1.874263 1.963775 2.013747 2.048624 2.075104 2.095699 2.114530 2.130248 2.144088 2.156083"
    s[11] = "1.967079 2.051917 2.098992 2.133190 2.159387 2.180322 2.197704 2.213931 2.228676 2.239053"
    s[12] = "2.161945 2.241362 2.286118 2.317271 2.341941 2.364200 2.381027 2.394912 2.408944 2.421516"
    s[13] = "64.000000 64.000000 64.000000 64.000000 64.000000 64.000000 64.000000 64.000000 64.000000 64.000000"
    s[14] = "1.876519 1.965741 2.016768 2.052080 2.079080 2.100808 2.118845 2.133842 2.148442 2.161395"
    s[15] = "1.969190 2.055561 2.104311 2.137036 2.164335 2.185588 2.202906 2.218490 2.232260 2.243942"
    s[16] = "2.166810 2.246341 2.290327 2.319085 2.341255 2.361281 2.377362 2.391343 2.402516 2.413226"
    s[17] = "65.000000 65.000000 65.000000 65.000000 65.000000 65.000000 65.000000 65.000000 65.000000 65.000000"
    s[18] = "1.877374 1.967471 2.017682 2.053207 2.080720 2.101775 2.120207 2.135378 2.149027 2.161563"
    s[19] = "1.970808 2.056597 2.104982 2.138542 2.164684 2.185211 2.202455 2.218328 2.231728 2.243195"
    s[20] = "2.166671 2.245852 2.293783 2.324957 2.348874 2.368883 2.384918 2.398350 2.414784 2.425323"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p14()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "66.000000 66.000000 66.000000 66.000000 66.000000 66.000000 66.000000 66.000000 66.000000 66.000000"
    s[2] = "1.880693 1.969742 2.019755 2.053821 2.080415 2.102187 2.120909 2.136359 2.150184 2.162890"
    s[3] = "1.973088 2.057293 2.105258 2.139789 2.166077 2.187152 2.205061 2.220511 2.233492 2.245185"
    s[4] = "2.168261 2.248161 2.294258 2.327269 2.351278 2.370453 2.385471 2.399285 2.412413 2.423779"
    s[5] = "67.000000 67.000000 67.000000 67.000000 67.000000 67.000000 67.000000 67.000000 67.000000 67.000000"
    s[6] = "1.882526 1.972602 2.023376 2.058014 2.084510 2.105868 2.124523 2.140217 2.153620 2.165836"
    s[7] = "1.976017 2.061212 2.109191 2.143395 2.169086 2.189443 2.207407 2.221501 2.235338 2.247183"
    s[8] = "2.171284 2.249370 2.291044 2.324835 2.348350 2.365911 2.381759 2.396215 2.406945 2.416386"
    s[9] = "68.000000 68.000000 68.000000 68.000000 68.000000 68.000000 68.000000 68.000000 68.000000 68.000000"
    s[10] = "1.884305 1.974096 2.024016 2.059527 2.087177 2.108529 2.125795 2.141447 2.155796 2.168269"
    s[11] = "1.977365 2.062968 2.111718 2.145291 2.171024 2.191650 2.210167 2.224820 2.238987 2.251157"
    s[12] = "2.173264 2.252883 2.293812 2.323561 2.351241 2.374481 2.391959 2.407005 2.418236 2.430527"
    s[13] = "69.000000 69.000000 69.000000 69.000000 69.000000 69.000000 69.000000 69.000000 69.000000 69.000000"
    s[14] = "1.886556 1.976584 2.026232 2.061211 2.087047 2.109013 2.127554 2.142797 2.156954 2.169828"
    s[15] = "1.979999 2.064617 2.111985 2.146193 2.172819 2.192495 2.208568 2.223682 2.236655 2.247801"
    s[16] = "2.175060 2.250032 2.294241 2.326485 2.352450 2.370329 2.387151 2.402730 2.413442 2.426089"
    s[17] = "70.000000 70.000000 70.000000 70.000000 70.000000 70.000000 70.000000 70.000000 70.000000 70.000000"
    s[18] = "1.888788 1.978671 2.029278 2.063181 2.090041 2.111673 2.129180 2.145537 2.159073 2.170716"
    s[19] = "1.981898 2.066563 2.114919 2.149054 2.173749 2.194957 2.212164 2.227178 2.240183 2.253217"
    s[20] = "2.175971 2.255468 2.300134 2.330954 2.353698 2.373446 2.387852 2.400006 2.414470 2.424837"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p15()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "71.000000 71.000000 71.000000 71.000000 71.000000 71.000000 71.000000 71.000000 71.000000 71.000000"
    s[2] = "1.890284 1.979475 2.029755 2.064485 2.091536 2.114047 2.131932 2.147027 2.159966 2.172139"
    s[3] = "1.982700 2.068032 2.117120 2.149855 2.175222 2.197932 2.215656 2.231215 2.244040 2.256109"
    s[4] = "2.177842 2.258171 2.303192 2.335407 2.358069 2.378868 2.394370 2.410458 2.422546 2.433924"
    s[5] = "72.000000 72.000000 72.000000 72.000000 72.000000 72.000000 72.000000 72.000000 72.000000 72.000000"
    s[6] = "1.891516 1.981875 2.032240 2.067611 2.094304 2.116134 2.133732 2.149616 2.163833 2.175391"
    s[7] = "1.985218 2.071029 2.119265 2.153005 2.178383 2.198166 2.215171 2.229832 2.242632 2.254774"
    s[8] = "2.180448 2.257535 2.303492 2.334028 2.358451 2.377373 2.392692 2.406159 2.419515 2.429027"
    s[9] = "73.000000 73.000000 73.000000 73.000000 73.000000 73.000000 73.000000 73.000000 73.000000 73.000000"
    s[10] = "1.894925 1.983532 2.033574 2.068620 2.095492 2.116929 2.135400 2.150786 2.165329 2.176288"
    s[11] = "1.987062 2.071632 2.120159 2.154134 2.179209 2.200801 2.218265 2.232445 2.246044 2.257656"
    s[12] = "2.181477 2.259770 2.305475 2.335949 2.359545 2.379903 2.397286 2.410095 2.423177 2.434654"
    s[13] = "74.000000 74.000000 74.000000 74.000000 74.000000 74.000000 74.000000 74.000000 74.000000 74.000000"
    s[14] = "1.896717 1.985632 2.035347 2.070272 2.096440 2.117765 2.135507 2.151089 2.163827 2.175507"
    s[15] = "1.988983 2.073214 2.120858 2.153738 2.178067 2.198902 2.216386 2.231640 2.244004 2.254795"
    s[16] = "2.180600 2.257399 2.301230 2.331941 2.355559 2.376821 2.394572 2.405096 2.417150 2.428785"
    s[17] = "75.000000 75.000000 75.000000 75.000000 75.000000 75.000000 75.000000 75.000000 75.000000 75.000000"
    s[18] = "1.897678 1.985849 2.035008 2.070621 2.097183 2.117925 2.135174 2.150263 2.163879 2.176955"
    s[19] = "1.989046 2.073775 2.120870 2.153451 2.180057 2.200860 2.218370 2.233232 2.246300 2.258653"
    s[20] = "2.182374 2.260805 2.306131 2.334827 2.357704 2.378525 2.394389 2.409660 2.422553 2.434027"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p16()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "76.000000 76.000000 76.000000 76.000000 76.000000 76.000000 76.000000 76.000000 76.000000 76.000000"
    s[2] = "1.899438 1.989196 2.038874 2.073710 2.100825 2.121834 2.139512 2.155423 2.169070 2.181308"
    s[3] = "1.992313 2.077117 2.124507 2.158745 2.184374 2.205955 2.223855 2.238297 2.251551 2.263807"
    s[4] = "2.186680 2.266206 2.313869 2.342915 2.369159 2.388852 2.404438 2.416762 2.432185 2.441844"
    s[5] = "77.000000 77.000000 77.000000 77.000000 77.000000 77.000000 77.000000 77.000000 77.000000 77.000000"
    s[6] = "1.900595 1.988961 2.040254 2.074690 2.101245 2.122800 2.139976 2.155167 2.169035 2.181705"
    s[7] = "1.992185 2.078073 2.125915 2.158274 2.184352 2.204249 2.221325 2.235427 2.248684 2.258917"
    s[8] = "2.186504 2.261069 2.306927 2.335442 2.359351 2.379935 2.396818 2.412587 2.424369 2.434695"
    s[9] = "78.000000 78.000000 78.000000 78.000000 78.000000 78.000000 78.000000 78.000000 78.000000 78.000000"
    s[10] = "1.903229 1.991749 2.042560 2.077584 2.103162 2.124780 2.143532 2.158309 2.171845 2.185086"
    s[11] = "1.995019 2.080516 2.128361 2.161463 2.188150 2.209037 2.226270 2.241153 2.255158 2.267536"
    s[12] = "2.190368 2.269639 2.312014 2.345395 2.368624 2.389388 2.403122 2.419180 2.430958 2.439583"
    s[13] = "79.000000 79.000000 79.000000 79.000000 79.000000 79.000000 79.000000 79.000000 79.000000 79.000000"
    s[14] = "1.904994 1.993692 2.043702 2.077587 2.104051 2.125445 2.145212 2.159661 2.172852 2.184771"
    s[15] = "1.997004 2.080738 2.128741 2.162852 2.187623 2.207938 2.225288 2.238971 2.252219 2.264846"
    s[16] = "2.189783 2.266941 2.311810 2.342835 2.365841 2.382925 2.396833 2.411185 2.423998 2.432806"
    s[17] = "80.000000 80.000000 80.000000 80.000000 80.000000 80.000000 80.000000 80.000000 80.000000 80.000000"
    s[18] = "1.906160 1.995224 2.044402 2.079978 2.106453 2.128452 2.145984 2.161530 2.175021 2.187720"
    s[19] = "1.998561 2.083205 2.131608 2.164456 2.190227 2.211673 2.229576 2.244727 2.258209 2.268932"
    s[20] = "2.192244 2.271052 2.314085 2.346309 2.370427 2.388449 2.403481 2.417351 2.429442 2.440410"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p17()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "81.000000 81.000000 81.000000 81.000000 81.000000 81.000000 81.000000 81.000000 81.000000 81.000000"
    s[2] = "1.908166 1.996594 2.046905 2.081740 2.108370 2.129420 2.146914 2.162050 2.175384 2.187586"
    s[3] = "2.000072 2.084852 2.132136 2.165108 2.190333 2.210583 2.228427 2.244215 2.256967 2.268291"
    s[4] = "2.192475 2.270278 2.311958 2.340599 2.365002 2.385415 2.401916 2.417688 2.433211 2.441958"
    s[5] = "82.000000 82.000000 82.000000 82.000000 82.000000 82.000000 82.000000 82.000000 82.000000 82.000000"
    s[6] = "1.910182 1.998171 2.048875 2.084080 2.110384 2.132498 2.149437 2.165897 2.179232 2.190715"
    s[7] = "2.001516 2.086960 2.135309 2.169219 2.193717 2.213652 2.231330 2.246852 2.258351 2.269865"
    s[8] = "2.195554 2.271930 2.316911 2.347148 2.373651 2.392015 2.408391 2.420369 2.432630 2.441530"
    s[9] = "83.000000 83.000000 83.000000 83.000000 83.000000 83.000000 83.000000 83.000000 83.000000 83.000000"
    s[10] = "1.911684 1.999524 2.049711 2.085538 2.111691 2.133645 2.150915 2.166360 2.180076 2.192617"
    s[11] = "2.002801 2.088397 2.136429 2.169892 2.195782 2.215739 2.232867 2.248850 2.262715 2.274418"
    s[12] = "2.198289 2.276865 2.320325 2.350945 2.375615 2.393454 2.410343 2.426528 2.441112 2.450331"
    s[13] = "84.000000 84.000000 84.000000 84.000000 84.000000 84.000000 84.000000 84.000000 84.000000 84.000000"
    s[14] = "1.913332 2.001196 2.051048 2.085781 2.112122 2.133906 2.151251 2.166700 2.180862 2.193136"
    s[15] = "2.004724 2.089015 2.137162 2.169904 2.195811 2.216294 2.233353 2.248118 2.261222 2.271923"
    s[16] = "2.198134 2.274091 2.318592 2.349652 2.372582 2.390486 2.405567 2.419068 2.429681 2.440815"
    s[17] = "85.000000 85.000000 85.000000 85.000000 85.000000 85.000000 85.000000 85.000000 85.000000 85.000000"
    s[18] = "1.914369 2.002578 2.052304 2.087322 2.112997 2.134253 2.152325 2.168917 2.182231 2.193458"
    s[19] = "2.005914 2.090390 2.137495 2.171892 2.196578 2.216744 2.233278 2.248310 2.260411 2.272541"
    s[20] = "2.199090 2.274693 2.321169 2.351638 2.376295 2.396519 2.411053 2.424887 2.436981 2.447515"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p18()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "86.000000 86.000000 86.000000 86.000000 86.000000 86.000000 86.000000 86.000000 86.000000 86.000000"
    s[2] = "1.916211 2.003808 2.053250 2.088297 2.114335 2.136165 2.154838 2.170056 2.182677 2.194887"
    s[3] = "2.006880 2.091313 2.139570 2.172865 2.197512 2.217327 2.233957 2.249203 2.260959 2.272935"
    s[4] = "2.199896 2.274772 2.321809 2.355480 2.379467 2.399517 2.414507 2.428101 2.439963 2.450449"
    s[5] = "87.000000 87.000000 87.000000 87.000000 87.000000 87.000000 87.000000 87.000000 87.000000 87.000000"
    s[6] = "1.918670 2.006838 2.056044 2.090419 2.117013 2.138488 2.156617 2.171288 2.184738 2.196243"
    s[7] = "2.009899 2.093857 2.141633 2.174251 2.199087 2.220410 2.237723 2.252135 2.264756 2.275772"
    s[8] = "2.201305 2.278248 2.321053 2.351216 2.375551 2.393449 2.408866 2.422957 2.435299 2.445158"
    s[9] = "88.000000 88.000000 88.000000 88.000000 88.000000 88.000000 88.000000 88.000000 88.000000 88.000000"
    s[10] = "1.919014 2.008063 2.057049 2.092080 2.118585 2.140216 2.158318 2.173740 2.187064 2.198956"
    s[11] = "2.011421 2.095171 2.143205 2.176886 2.202321 2.222130 2.239690 2.254920 2.267326 2.279636"
    s[12] = "2.204282 2.281692 2.326490 2.355990 2.378842 2.400178 2.417019 2.430987 2.441673 2.453921"
    s[13] = "89.000000 89.000000 89.000000 89.000000 89.000000 89.000000 89.000000 89.000000 89.000000 89.000000"
    s[14] = "1.920964 2.009709 2.059502 2.093547 2.119694 2.141002 2.158591 2.174461 2.187460 2.199287"
    s[15] = "2.013058 2.096788 2.144270 2.177574 2.202744 2.223122 2.240394 2.254903 2.268805 2.279776"
    s[16] = "2.205183 2.282054 2.325479 2.357873 2.382652 2.401493 2.417404 2.433011 2.445943 2.454993"
    s[17] = "90.000000 90.000000 90.000000 90.000000 90.000000 90.000000 90.000000 90.000000 90.000000 90.000000"
    s[18] = "1.922584 2.011020 2.061046 2.095466 2.121602 2.142225 2.160031 2.175605 2.189561 2.201926"
    s[19] = "2.014380 2.098468 2.145181 2.179176 2.205041 2.225187 2.243298 2.258222 2.271058 2.282582"
    s[20] = "2.207519 2.285783 2.329447 2.361640 2.384344 2.401461 2.416299 2.428280 2.439433 2.448373"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p19()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "91.000000 91.000000 91.000000 91.000000 91.000000 91.000000 91.000000 91.000000 91.000000 91.000000"
    s[2] = "1.923038 2.010730 2.060025 2.095332 2.121736 2.143701 2.161235 2.176545 2.189438 2.201737"
    s[3] = "2.013943 2.098350 2.146478 2.179341 2.204755 2.225045 2.243093 2.258332 2.271752 2.282891"
    s[4] = "2.206678 2.285023 2.325421 2.356557 2.379611 2.398656 2.415837 2.429727 2.440925 2.449561"
    s[5] = "92.000000 92.000000 92.000000 92.000000 92.000000 92.000000 92.000000 92.000000 92.000000 92.000000"
    s[6] = "1.925318 2.013751 2.063437 2.098164 2.124568 2.145991 2.164656 2.179897 2.192849 2.204615"
    s[7] = "2.016983 2.101158 2.149511 2.183295 2.207455 2.229076 2.246427 2.261931 2.275139 2.285860"
    s[8] = "2.209815 2.288117 2.330006 2.358744 2.382757 2.400678 2.414836 2.433449 2.446902 2.457321"
    s[9] = "93.000000 93.000000 93.000000 93.000000 93.000000 93.000000 93.000000 93.000000 93.000000 93.000000"
    s[10] = "1.927067 2.015220 2.064788 2.098350 2.124708 2.146076 2.164119 2.179815 2.194647 2.207782"
    s[11] = "2.018519 2.101858 2.149855 2.183304 2.210659 2.232279 2.249741 2.264958 2.277670 2.289449"
    s[12] = "2.213258 2.291714 2.333150 2.362990 2.386856 2.405738 2.424355 2.437440 2.452291 2.463287"
    s[13] = "94.000000 94.000000 94.000000 94.000000 94.000000 94.000000 94.000000 94.000000 94.000000 94.000000"
    s[14] = "1.928218 2.015340 2.065472 2.100443 2.126605 2.147912 2.166128 2.181189 2.195071 2.206811"
    s[15] = "2.018829 2.103796 2.150719 2.184138 2.209704 2.230396 2.247848 2.262984 2.275320 2.287048"
    s[16] = "2.211865 2.289556 2.333200 2.362796 2.388026 2.409470 2.424649 2.436787 2.447608 2.457460"
    s[17] = "95.000000 95.000000 95.000000 95.000000 95.000000 95.000000 95.000000 95.000000 95.000000 95.000000"
    s[18] = "1.928658 2.016088 2.066005 2.099656 2.125082 2.146096 2.163309 2.179631 2.192897 2.204256"
    s[19] = "2.019730 2.102680 2.149023 2.182729 2.207648 2.227776 2.243950 2.257485 2.270140 2.282368"
    s[20] = "2.209939 2.284616 2.326290 2.355212 2.381670 2.401218 2.416464 2.430433 2.440796 2.450854"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_p20()
{
    string colvector s
    real matrix m
    real scalar i
    s = J(20, 1, "")
    s[1] = "96.000000 96.000000 96.000000 96.000000 96.000000 96.000000 96.000000 96.000000 96.000000 96.000000"
    s[2] = "1.930647 2.018230 2.067982 2.102835 2.128881 2.149490 2.167584 2.182875 2.196259 2.207544"
    s[3] = "2.021478 2.105879 2.152516 2.185919 2.211051 2.231539 2.248851 2.263125 2.276575 2.288504"
    s[4] = "2.213487 2.291018 2.331574 2.363599 2.385892 2.405496 2.422020 2.435169 2.445919 2.458238"
    s[5] = "97.000000 97.000000 97.000000 97.000000 97.000000 97.000000 97.000000 97.000000 97.000000 97.000000"
    s[6] = "1.931880 2.019558 2.069171 2.103663 2.129391 2.150623 2.168213 2.183783 2.196949 2.209457"
    s[7] = "2.022993 2.106737 2.153478 2.186715 2.212200 2.232383 2.248830 2.263992 2.275884 2.287623"
    s[8] = "2.214166 2.290087 2.335714 2.368412 2.391273 2.408839 2.422704 2.437960 2.450392 2.459104"
    s[9] = "98.000000 98.000000 98.000000 98.000000 98.000000 98.000000 98.000000 98.000000 98.000000 98.000000"
    s[10] = "1.933654 2.021258 2.071204 2.105036 2.131584 2.151973 2.169860 2.185192 2.197988 2.209232"
    s[11] = "2.024565 2.107999 2.155694 2.188511 2.211653 2.233284 2.250652 2.266177 2.280185 2.291336"
    s[12] = "2.214224 2.294182 2.337847 2.368687 2.393964 2.414289 2.429085 2.443362 2.455901 2.467792"
    s[13] = "99.000000 99.000000 99.000000 99.000000 99.000000 99.000000 99.000000 99.000000 99.000000 99.000000"
    s[14] = "1.935151 2.021787 2.070760 2.106073 2.131806 2.153162 2.170647 2.185380 2.199102 2.211934"
    s[15] = "2.024871 2.109141 2.155925 2.188344 2.215208 2.235530 2.252693 2.267478 2.279954 2.292608"
    s[16] = "2.217615 2.294607 2.338065 2.369146 2.393230 2.411398 2.428084 2.441565 2.453995 2.466218"
    s[17] = "100.000000 100.000000 100.000000 100.000000 100.000000 100.000000 100.000000 100.000000 100.000000 100.000000"
    s[18] = "1.936395 2.023618 2.073595 2.107984 2.134300 2.155857 2.174262 2.188809 2.202218 2.213551"
    s[19] = "2.027228 2.111425 2.158606 2.191926 2.216465 2.237315 2.252546 2.266397 2.279976 2.291128"
    s[20] = "2.218700 2.293334 2.336607 2.367397 2.391121 2.411292 2.427655 2.441794 2.454451 2.464777"
    m = J(20, 10, 0)
    for (i = 1; i <= 20; i++) m[i, .] = strtoreal(tokens(s[i]))
    return(m)
}

real matrix qrb_cvsq_table()
{
    return(qrb_cvsq_p1() \ qrb_cvsq_p2() \ qrb_cvsq_p3() \ qrb_cvsq_p4() \ qrb_cvsq_p5() \ qrb_cvsq_p6() \ qrb_cvsq_p7() \ qrb_cvsq_p8() \ qrb_cvsq_p9() \ qrb_cvsq_p10() \ qrb_cvsq_p11() \ qrb_cvsq_p12() \ qrb_cvsq_p13() \ qrb_cvsq_p14() \ qrb_cvsq_p15() \ qrb_cvsq_p16() \ qrb_cvsq_p17() \ qrb_cvsq_p18() \ qrb_cvsq_p19() \ qrb_cvsq_p20())
}

// --------------------------------------------------------------------------------
// display helpers
// --------------------------------------------------------------------------------
void qrb_printtesttable(string scalar testlab, real rowvector test, real rowvector cvrow)
{
    real scalar m_max, j
    m_max = cols(test)
    printf("{txt}%16s", "")
    for (j = 1; j <= m_max; j++) printf("{txt}%12s", sprintf("%g Breaks", j))
    printf("\n")
    printf("{txt}%-16s", testlab)
    for (j = 1; j <= m_max; j++) printf("{res}%12s", sprintf("%10.4g", test[j]))
    printf("\n")
    printf("{txt}%-16s", "Critical values")
    for (j = 1; j <= m_max; j++) printf("{res}%12s", sprintf("%10.4g", cvrow[j]))
    printf("\n")
}

void qrb_printci(real matrix mat_ci)
{
    real scalar i
    printf("{txt}%10s%14s%16s%16s\n", "", "Estimate", "CI_Lower_Bound", "CI_Upper_Bound")
    for (i = 1; i <= rows(mat_ci); i++) {
        printf("{txt}%-10s{res}%14.0f%16.0f%16.0f\n", sprintf("Break %g", i), mat_ci[i, 1], mat_ci[i, 2], mat_ci[i, 3])
    }
}

void qrb_printcitime_num(real matrix mat_ci, real colvector tnum)
{
    real scalar i
    printf("{txt}%10s%14s%16s%16s\n", "", "Estimate", "CI_Lower_Bound", "CI_Upper_Bound")
    for (i = 1; i <= rows(mat_ci); i++) {
        printf("{txt}%-10s{res}%14.10g%16.10g%16.10g\n", sprintf("Break %g", i), tnum[mat_ci[i, 1]], tnum[mat_ci[i, 2]], tnum[mat_ci[i, 3]])
    }
}

void qrb_printcitime_str(real matrix mat_ci, string colvector tstr)
{
    real scalar i
    printf("{txt}%10s%14s%16s%16s\n", "", "Estimate", "CI_Lower_Bound", "CI_Upper_Bound")
    for (i = 1; i <= rows(mat_ci); i++) {
        printf("{txt}%-10s{res}%14s%16s%16s\n", sprintf("Break %g", i), tstr[mat_ci[i, 1]], tstr[mat_ci[i, 2]], tstr[mat_ci[i, 3]])
    }
}

void qrb_printcoeftab(real matrix tab)
{
    real scalar i
    printf("{txt}%12s%12s%14s%12s%12s\n", "", "Value", "Std. Error", "t value", "Pr(>|t|)")
    for (i = 1; i <= rows(tab); i++) {
        printf("{txt}%-12s{res}%12.4f%14.4f%12.2f%12.3f\n", (i == 1 ? "Intercept" : sprintf("x%g", i - 1)), tab[i, 1], tab[i, 2], tab[i, 3], tab[i, 4])
    }
}

// --------------------------------------------------------------------------------
// qrb_main: full pipeline, a faithful port of rq.break() with verbose output
// --------------------------------------------------------------------------------
// label a break index either as the corresponding time value (when a time
// variable is available and the index is inside the sample) or as the plain
// observation index
string scalar qrb_timelab(real scalar idx2, real scalar rangeok, string scalar timetype, real colvector tnum, string colvector tstr)
{
    if (idx2 >= .) return(".")
    if (!rangeok) return(strofreal(idx2))
    if (timetype == "num") return(strofreal(tnum[idx2]))
    return(tstr[idx2])
}

// combined break-date table: one row per break, each cell showing the date
// label with the observation index in parentheses (index only when no usable
// time variable is available)
void qrb_printci2(real matrix ci, real scalar rangeok, string scalar timetype, real colvector tnum, string colvector tstr)
{
    real scalar i
    string scalar s1, s2, s3
    printf("{txt}%-10s%20s%20s%20s\n", "", "Estimate", "CI_Lower_Bound", "CI_Upper_Bound")
    for (i = 1; i <= rows(ci); i++) {
        if (rangeok) {
            s1 = sprintf("%s (%g)", qrb_timelab(ci[i, 1], 1, timetype, tnum, tstr), ci[i, 1])
            s2 = sprintf("%s (%g)", qrb_timelab(ci[i, 2], 1, timetype, tnum, tstr), ci[i, 2])
            s3 = sprintf("%s (%g)", qrb_timelab(ci[i, 3], 1, timetype, tnum, tstr), ci[i, 3])
        }
        else {
            s1 = strofreal(ci[i, 1])
            s2 = strofreal(ci[i, 2])
            s3 = strofreal(ci[i, 3])
        }
        printf("{txt}Break %-4.0f{res}%20s%20s%20s\n", i, s1, s2, s3)
    }
}

void qrb_main(string scalar dep, string scalar indep, string scalar touse, string scalar taustr, real scalar n_size, real scalar trim_e, real scalar m_max, real scalar v_a, real scalar v_b, string scalar timevar, string scalar timetype, string scalar normmethod)
{
    real scalar N_tau, T_size, trim_size, p_size, q_L, q_R, i, k, j, v_tau, n_break, nf, nf2, d_Sym, has_time, beg01, end01
    real matrix x, mat_long, mat_date, mat_cv, mat_date_opt, mat_ci, table_cv, Xfull, regime_tab, fulltab, coef_sub
    real colvector y, vec_long, vec_nb_out, bfull, rfull, vfis, tnum, idx
    real rowvector vec_tau, vec_test, vec_date, vec_level
    string colvector tstr, sumlines
    string scalar eqnm, dstr, la1, la2, la3, concl_dstr, concl_src, concl_q, partno
    real scalar rangeok, bqi, concl_nb
    real scalar i2, nblk, ndist, blen, cur, blkfail
    real colvector tfull_n
    string colvector tfull_s
    string matrix rstr, cstr

    st_global("QRB_SPECTRAL", normmethod == "spectral" ? "1" : "0")
    y = st_data(., dep, touse)
    x = st_data(., tokens(indep), touse)
    vec_tau = strtoreal(tokens(taustr))
    N_tau = cols(vec_tau)

    // when a time variable is available, learn or validate the number of
    // observations per period from its block structure (each period must be
    // one contiguous block of equal length, as in the R original)
    if (timevar != "") {
        nblk = 1
        blen = 0
        cur = 1
        blkfail = 0
        if (timetype == "num") {
            tfull_n = st_data(., timevar, touse)
            ndist = rows(uniqrows(tfull_n))
            for (i2 = 2; i2 <= rows(y); i2++) {
                if (tfull_n[i2] != tfull_n[i2 - 1]) {
                    nblk = nblk + 1
                    if (blen == 0) blen = cur
                    else if (cur != blen) blkfail = 1
                    cur = 1
                }
                else cur = cur + 1
            }
        }
        else {
            tfull_s = st_sdata(., timevar, touse)
            ndist = rows(uniqrows(tfull_s))
            for (i2 = 2; i2 <= rows(y); i2++) {
                if (tfull_s[i2] != tfull_s[i2 - 1]) {
                    nblk = nblk + 1
                    if (blen == 0) blen = cur
                    else if (cur != blen) blkfail = 1
                    cur = 1
                }
                else cur = cur + 1
            }
        }
        if (blen == 0) blen = cur
        else if (cur != blen) blkfail = 1
        if (ndist != nblk) {
            errprintf("observations belonging to the same period of %s are not contiguous; sort the data so that each period forms one block of rows\n", timevar)
            exit(198)
        }
        if (blkfail) {
            errprintf("the time variable %s shows unequal numbers of observations per period; qrbreak requires the same number of observations in every period\n", timevar)
            exit(198)
        }
        if (n_size == 1 & blen > 1) {
            n_size = blen
            printf("{txt}(nsize() not specified; detected {res}%g{txt} observations per period from %s)\n", blen, timevar)
            displayflush()
        }
        else if (n_size > 1 & blen != n_size) {
            errprintf("nsize(%g) conflicts with the period structure of %s, which shows %g observations per period\n", n_size, timevar, blen)
            exit(198)
        }
    }

    T_size = rows(y)/n_size
    if (T_size != floor(T_size)) {
        errprintf("number of usable observations is not a multiple of the number of observations per period\n")
        exit(198)
    }
    if (T_size > 400) {
        printf("{txt}note: %g time periods; the computational load grows roughly with the fourth\n", T_size)
        printf("{txt}power of the number of periods, so this run may take many minutes or longer.\n")
        printf("{txt}If your data are repeated cross sections you may have forgotten nsize();\n")
        printf("{txt}when time() is given, qrbreak detects it automatically.\n")
        displayflush()
    }
    trim_size = qrb_rround(T_size*trim_e)
    p_size = cols(x) + 1
    if (trim_e*rows(x) < p_size) {
        errprintf("trim()*N must be at least the number of regressors; otherwise the estimation results are not unique; consider increasing trim()\n")
        exit(198)
    }
    if (p_size > 100) {
        errprintf("the number of regressors cannot exceed 100\n")
        exit(198)
    }
    q_L = min(vec_tau)
    q_R = max(vec_tau)
    has_time = (timevar != "")
    tnum = J(0, 1, 0)
    tstr = J(0, 1, "")
    idx = (0::(T_size - 1))*n_size :+ 1
    if (has_time) {
        if (timetype == "num") tnum = st_data(., timevar, touse)[idx]
        else tstr = st_sdata(., timevar, touse)[idx]
    }
    vec_level = (10, 5, 1)

    // objective function values for all admissible segments
    mat_long = .
    vec_long = J(0, 1, 0)
    qrb_genlong(y, x, vec_tau, n_size, trim_size, mat_long, vec_long)

    // transport: basic quantities
    st_global("QRB_T", strofreal(T_size))
    st_global("QRB_TRIMSIZE", strofreal(trim_size))
    st_global("QRB_NTAU", strofreal(N_tau))
    st_matrix("QRB_tau", vec_tau)

    sumlines = J(0, 1, "")
    concl_nb = 0
    concl_dstr = ""
    concl_src = "SQ"
    concl_q = ""
    if (normmethod == "spectral") {
        (void) qrb_specinvsq((J(rows(x), 1, 1), x))
        printf("{txt}(subgradient normalization: spectral)\n")
    }
    printf("{txt}========================================================================\n")
    printf("{txt} PART 1. SINGLE-QUANTILE ANALYSIS (SQ tests, each quantile separately)\n")
    printf("{txt}========================================================================\n")
    vec_test = J(1, m_max, 0)
    mat_cv = J(3, m_max, 0)
    mat_date_opt = J(3, m_max, 0)
    vec_nb_out = J(3, 1, 0)
    for (i = 1; i <= N_tau; i++) {
        v_tau = vec_tau[i]
        printf("{txt}------------------------------------------------------------------------\n")
        printf("{txt} 1.%g  Quantile {res}%g{txt} -- sequential SQ break tests\n", i, v_tau)
        printf("{txt}------------------------------------------------------------------------\n")
        mat_date = qrb_brdate(y, x, n_size, m_max, trim_size, mat_long[., i])
        qrb_sq(y, x, v_tau, n_size, m_max, trim_size, mat_date, vec_test, mat_cv, mat_date_opt, vec_nb_out)
        qrb_printtesttable("SQ test", vec_test, mat_cv[v_a, .])
        st_matrix("QRB_sq_test_" + strofreal(i), vec_test)
        st_matrix("QRB_sq_cv_" + strofreal(i), mat_cv)
        st_matrix("QRB_sq_nbreak_" + strofreal(i), vec_nb_out)
        st_matrix("QRB_sq_dates_" + strofreal(i), mat_date_opt)
        st_numscalar("QRB_sq_nb_" + strofreal(i), vec_nb_out[v_a])
        n_break = vec_nb_out[v_a]
        if (n_break == 0) {
            printf("{txt}--> DECISION at quantile {res}%g{txt} (%g%% level): {res}0 breaks\n", v_tau, vec_level[v_a])
            sumlines = sumlines \ sprintf("SQ           %-13s 0        -", strofreal(v_tau))
            if (N_tau == 1) {
                concl_nb = 0
                concl_q = strofreal(v_tau)
            }
        }
        if (n_break >= 1) {
            vec_date = mat_date_opt[|v_a, 1 \ v_a, n_break|]
            bfull = J(0, 1, 0)
            rfull = J(0, 1, 0)
            Xfull = .
            qrb_rqestfull(y, x, v_tau, vec_date, n_size, bfull, Xfull, rfull)
            nf = 0
            fulltab = qrb_summarynid(Xfull, y, v_tau, bfull, nf)
            nf2 = 0
            mat_ci = qrb_cidatem(y, x, (v_tau), vec_date, n_size, v_b, nf2)
            rangeok = has_time & (missing(mat_ci) == 0) & !(min(mat_ci[., 2]) < 1 | T_size < max(mat_ci[., 3]))
            dstr = ""
            for (bqi = 1; bqi <= n_break; bqi++) {
                la1 = qrb_timelab(mat_ci[bqi, 1], rangeok, timetype, tnum, tstr)
                la2 = qrb_timelab(mat_ci[bqi, 2], rangeok, timetype, tnum, tstr)
                la3 = qrb_timelab(mat_ci[bqi, 3], rangeok, timetype, tnum, tstr)
                if (bqi > 1) dstr = dstr + ", "
                dstr = dstr + sprintf("%s [%s - %s]", la1, la2, la3)
                if (bqi == 1) sumlines = sumlines \ sprintf("SQ           %-13s %-8s %s [%s - %s]", strofreal(v_tau), strofreal(n_break), la1, la2, la3)
                else sumlines = sumlines \ sprintf("%-36s %s [%s - %s]", "", la1, la2, la3)
            }
            printf("{txt}--> DECISION at quantile {res}%g{txt} (%g%% level): {res}%g break(s)\n", v_tau, vec_level[v_a], n_break)
            printf("{txt}    date(s): {res}%s\n", dstr)
            if (N_tau == 1) {
                concl_nb = n_break
                concl_dstr = dstr
                concl_q = strofreal(v_tau)
            }
            printf("\n{txt}   1.%sa  Break dates and their %g%% confidence intervals\n\n", strofreal(i), 100 - vec_level[v_b])
            qrb_printci2(mat_ci, rangeok, timetype, tnum, tstr)
            st_matrix("QRB_sq_ci_" + strofreal(i), mat_ci)
            if (missing(mat_ci)) {
                printf("{txt}Warning: some confidence limits could not be computed (degenerate conditional density estimates at this quantile)\n")
            }
            else if (min(mat_ci[., 2]) < 1 | T_size < max(mat_ci[., 3])) {
                printf("{txt}Warning: confidence interval is out of the range\n")
            }
            printf("\n{txt}   1.%sb  Regime coefficient estimates\n", strofreal(i))
            vfis = J(0, 1, 0)
            regime_tab = qrb_rqestregime(y, x, v_tau, vec_date, n_size, vfis)
            for (j = 1; j <= n_break + 1; j++) {
                printf("\n{txt} Regime_%g\n", j)
                qrb_printcoeftab(regime_tab[|(j - 1)*p_size + 1, 1 \ j*p_size, 4|])
            }
            st_matrix("QRB_sq_coef_" + strofreal(i), regime_tab)
            rstr = J(0, 2, "")
            for (j = 1; j <= n_break + 1; j++) {
                eqnm = sprintf("Regime_%g", j)
                rstr = rstr \ (eqnm, "Intercept")
                for (k = 2; k <= p_size; k++) rstr = rstr \ (eqnm, sprintf("x%g", k - 1))
            }
            cstr = ("", "Value" \ "", "StdErr" \ "", "t" \ "", "p")
            st_matrixrowstripe("QRB_sq_coef_" + strofreal(i), rstr)
            st_matrixcolstripe("QRB_sq_coef_" + strofreal(i), cstr)
            printf("\n{txt}   1.%sc  Break sizes (differences between consecutive regimes)\n\n", strofreal(i))
            coef_sub = J(0, 4, 0)
            rstr = J(0, 2, "")
            for (j = 1; j <= n_break; j++) {
                beg01 = 1 + p_size*j
                end01 = p_size*(j + 1)
                printf("{txt}  Regime %g   minus Regime %g\n", j + 1, j)
                qrb_printcoeftab(fulltab[|beg01, 1 \ end01, 4|])
                printf("\n")
                coef_sub = coef_sub \ fulltab[|beg01, 1 \ end01, 4|]
                eqnm = sprintf("R%g_minus_R%g", j + 1, j)
                rstr = rstr \ (eqnm, "Intercept")
                for (k = 2; k <= p_size; k++) rstr = rstr \ (eqnm, sprintf("x%g", k - 1))
            }
            st_matrix("QRB_sq_bsize_" + strofreal(i), coef_sub)
            st_matrixrowstripe("QRB_sq_bsize_" + strofreal(i), rstr)
            st_matrixcolstripe("QRB_sq_bsize_" + strofreal(i), cstr)
        }
    }

    if (N_tau > 1) {
        printf("{txt}========================================================================\n")
        printf("{txt} PART 2. MULTIPLE-QUANTILE ANALYSIS (DQ test, quantiles jointly)\n")
        printf("{txt}========================================================================\n")
        d_Sym = (abs(q_L - (1 - q_R)) <= 1e-5)
        table_cv = J(0, 0, 0)
        if (!d_Sym | p_size > 20 | m_max > 5) {
            printf("{txt}(computing the DQ critical values by simulation; one dot per 250 draws)\n")
            displayflush()
            table_cv = qrb_criticalDQspecific(x, m_max, vec_tau)
            printf("\n")
        }
        printf("{txt}------------------------------------------------------------------------\n")
        printf("{txt} 2.1  Joint DQ break tests (quantile range {res}%g{txt} - {res}%g{txt})\n", q_L, q_R)
        printf("{txt}------------------------------------------------------------------------\n")
        mat_date = qrb_brdate(y, x, n_size, m_max, trim_size, vec_long)
        qrb_dq(y, x, vec_tau, q_L, q_R, n_size, m_max, trim_size, mat_date, d_Sym, table_cv, vec_test, mat_cv, mat_date_opt, vec_nb_out)
        n_break = vec_nb_out[v_a]
        qrb_printtesttable("DQ test", vec_test, mat_cv[v_a, .])
        concl_src = "DQ (joint)"
        concl_nb = n_break
        concl_dstr = ""
        concl_q = strofreal(q_L) + "-" + strofreal(q_R)
        if (n_break == 0) {
            printf("{txt}--> DECISION (joint, %g%% level): {res}0 breaks\n", vec_level[v_a])
            sumlines = sumlines \ sprintf("DQ (joint)   %-13s 0        -", strofreal(q_L) + "-" + strofreal(q_R))
        }
        st_matrix("QRB_dq_test", vec_test)
        st_matrix("QRB_dq_cv", mat_cv)
        st_matrix("QRB_dq_nbreak_all", vec_nb_out)
        st_matrix("QRB_dq_dates", mat_date_opt)
        st_numscalar("QRB_dq_nbreak", vec_nb_out[v_a])
        if (n_break >= 1) {
            vec_date = mat_date_opt[|v_a, 1 \ v_a, n_break|]
            nf2 = 0
            mat_ci = qrb_cidatem(y, x, vec_tau, vec_date, n_size, v_b, nf2)
            rangeok = has_time & (missing(mat_ci) == 0) & !(min(mat_ci[., 2]) < 1 | T_size < max(mat_ci[., 3]))
            dstr = ""
            for (bqi = 1; bqi <= n_break; bqi++) {
                la1 = qrb_timelab(mat_ci[bqi, 1], rangeok, timetype, tnum, tstr)
                la2 = qrb_timelab(mat_ci[bqi, 2], rangeok, timetype, tnum, tstr)
                la3 = qrb_timelab(mat_ci[bqi, 3], rangeok, timetype, tnum, tstr)
                if (bqi > 1) dstr = dstr + ", "
                dstr = dstr + sprintf("%s [%s - %s]", la1, la2, la3)
                if (bqi == 1) sumlines = sumlines \ sprintf("DQ (joint)   %-13s %-8s %s [%s - %s]", strofreal(q_L) + "-" + strofreal(q_R), strofreal(n_break), la1, la2, la3)
                else sumlines = sumlines \ sprintf("%-36s %s [%s - %s]", "", la1, la2, la3)
            }
            concl_dstr = dstr
            printf("{txt}--> DECISION (joint, %g%% level): {res}%g break(s)\n", vec_level[v_a], n_break)
            printf("{txt}    date(s): {res}%s\n", dstr)
            printf("\n{txt}------------------------------------------------------------------------\n")
            printf("{txt} 2.2  Break dates and their %g%% confidence intervals\n", 100 - vec_level[v_b])
            printf("{txt}------------------------------------------------------------------------\n\n")
            qrb_printci2(mat_ci, rangeok, timetype, tnum, tstr)
            st_matrix("QRB_dq_ci", mat_ci)
            if (missing(mat_ci)) {
                printf("{txt}Warning: some confidence limits could not be computed (degenerate conditional density estimates at this quantile)\n")
            }
            else if (min(mat_ci[., 2]) < 1 | T_size < max(mat_ci[., 3])) {
                printf("{txt}Warning: confidence interval is out of the range\n")
            }
            for (k = 1; k <= N_tau; k++) {
                v_tau = vec_tau[k]
                printf("\n{txt}------------------------------------------------------------------------\n")
                printf("{txt} 2.%s  Quantile {res}%g{txt} -- regime coefficients and break sizes\n", strofreal(k + 2), v_tau)
                printf("{txt}------------------------------------------------------------------------\n")
                printf("\n{txt}   2.%sa  Regime coefficient estimates\n", strofreal(k + 2))
                vfis = J(0, 1, 0)
                regime_tab = qrb_rqestregime(y, x, v_tau, vec_date, n_size, vfis)
                for (j = 1; j <= n_break + 1; j++) {
                    printf("\n{txt} Regime_%g\n", j)
                    qrb_printcoeftab(regime_tab[|(j - 1)*p_size + 1, 1 \ j*p_size, 4|])
                }
                st_matrix("QRB_mq_coef_" + strofreal(k), regime_tab)
                rstr = J(0, 2, "")
                for (j = 1; j <= n_break + 1; j++) {
                    eqnm = sprintf("Regime_%g", j)
                    rstr = rstr \ (eqnm, "Intercept")
                    for (i = 2; i <= p_size; i++) rstr = rstr \ (eqnm, sprintf("x%g", i - 1))
                }
                cstr = ("", "Value" \ "", "StdErr" \ "", "t" \ "", "p")
                st_matrixrowstripe("QRB_mq_coef_" + strofreal(k), rstr)
                st_matrixcolstripe("QRB_mq_coef_" + strofreal(k), cstr)
                printf("\n{txt}   2.%sb  Break sizes (differences between consecutive regimes)\n\n", strofreal(k + 2))
                bfull = J(0, 1, 0)
                rfull = J(0, 1, 0)
                Xfull = .
                qrb_rqestfull(y, x, v_tau, vec_date, n_size, bfull, Xfull, rfull)
                nf = 0
                regime_tab = qrb_summarynid(Xfull, y, v_tau, bfull, nf)
                coef_sub = J(0, 4, 0)
                rstr = J(0, 2, "")
                for (j = 1; j <= n_break; j++) {
                    beg01 = 1 + p_size*j
                    end01 = p_size*(j + 1)
                    printf("{txt}  Regime %g   minus Regime %g\n", j + 1, j)
                    qrb_printcoeftab(regime_tab[|beg01, 1 \ end01, 4|])
                    printf("\n")
                    coef_sub = coef_sub \ regime_tab[|beg01, 1 \ end01, 4|]
                    eqnm = sprintf("R%g_minus_R%g", j + 1, j)
                    rstr = rstr \ (eqnm, "Intercept")
                    for (i = 2; i <= p_size; i++) rstr = rstr \ (eqnm, sprintf("x%g", i - 1))
                }
                st_matrix("QRB_mq_bsize_" + strofreal(k), coef_sub)
                st_matrixrowstripe("QRB_mq_bsize_" + strofreal(k), rstr)
                st_matrixcolstripe("QRB_mq_bsize_" + strofreal(k), cstr)
            }
        }
    }
    partno = "2"
    if (N_tau > 1) partno = "3"
    printf("\n{txt}========================================================================\n")
    printf("{txt} PART %s. SUMMARY AND CONCLUSIONS\n", partno)
    printf("{txt}========================================================================\n")
    printf("{txt}Test         Quantile(s)   Breaks   Break date(s) [%g%% CI]\n", 100 - vec_level[v_b])
    for (i = 1; i <= rows(sumlines); i++) printf("{txt}%s\n", sumlines[i])
    printf("\n")
    if (N_tau > 1) {
        printf("{txt}Note: the SQ tests examine each quantile in isolation; the DQ test pools\n")
        printf("{txt}all specified quantiles and is the primary test for the overall decision.\n")
    }
    else printf("{txt}Note: with a single quantile specified, the sequential SQ test provides the overall decision.\n")
    if (concl_nb >= 1) {
        printf("{txt}Conclusion: the %s test over quantile(s) {res}%s{txt} detects {res}%g{txt}\n", concl_src, concl_q, concl_nb)
        printf("{txt}structural break(s) at the %g%% level, dated {res}%s{txt}.\n", vec_level[v_a], concl_dstr)
        printf("{txt}Regime coefficients conditional on these break dates are reported above.\n")
    }
    else printf("{txt}Conclusion: the %s test over quantile(s) {res}%s{txt} detects no structural break at the %g%% level.\n", concl_src, concl_q, vec_level[v_a])
}

// --------------------------------------------------------------------------------
// built-in self test: compares core building blocks against reference values
// computed in R (quantreg 6.1 environment); requires gdp.dta in memory for the
// solver checks
// --------------------------------------------------------------------------------
void qrb_chk(string scalar label, real scalar got, real scalar want, real scalar tol, real scalar npass, real scalar nfail)
{
    real scalar dd
    dd = abs(got - want)/(abs(want) + 1)
    if (dd <= tol) {
        printf("{txt}%-26s got = {res}%21.15g  {txt}want = {res}%21.15g  {txt}reldif = {res}%8.1e  {txt}PASS\n", label, got, want, dd)
        npass = npass + 1
    }
    else {
        printf("{txt}%-26s got = {res}%21.15g  {txt}want = {res}%21.15g  {txt}reldif = {res}%8.1e  {err}FAIL\n", label, got, want, dd)
        nfail = nfail + 1
    }
}

void qrb_selftest()
{
    real scalar npass, nfail, ift, ift8
    real rowvector s
    real colvector y, x1c, x2c, b, b8, bf, res, res8
    real matrix X

    npass = 0
    nfail = 0
    printf("\n{txt}qrbreak self test: core components against R reference values\n\n")
    printf("{txt}--- micro functions ---\n")
    qrb_chk("rround(0.5)", qrb_rround(0.5), 0, 0, npass, nfail)
    qrb_chk("rround(1.5)", qrb_rround(1.5), 2, 0, npass, nfail)
    qrb_chk("rround(2.5)", qrb_rround(2.5), 2, 0, npass, nfail)
    qrb_chk("rround(37.05)", qrb_rround(37.05), 37, 0, npass, nfail)
    s = qrb_seq(0.2, 0.8, 1/247)
    qrb_chk("seq length", cols(s), 149, 0, npass, nfail)
    qrb_chk("seq[2]", s[2], 0.204048582995951, 1e-14, npass, nfail)
    qrb_chk("seq[last]", s[cols(s)], 0.79919028340081, 1e-14, npass, nfail)
    qrb_chk("bandwidth Bofinger", qrb_bandwidth(0.5, 247, 0), 0.215194498732041, 1e-14, npass, nfail)
    qrb_chk("bandwidth Hall-Sheather", qrb_bandwidth(0.5, 247, 1), 0.154847265292496, 1e-14, npass, nfail)
    if (_st_varindex("gdp") == . | _st_varindex("lag1") == . | _st_varindex("lag2") == .) {
        printf("\n{txt}(solver checks skipped: load gdp.dta first, then run qrbreak, selftest again)\n")
    }
    else {
        y = st_data(., "gdp")
        x1c = st_data(., "lag1")
        x2c = st_data(., "lag2")
        X = (J(rows(y), 1, 1), x1c, x2c)
        printf("\n{txt}--- rqbr (Barrodale-Roberts) solver, gdp full sample ---\n")
        b = J(3, 1, 0)
        ift = qrb_rqbr(X, y, 0.2, b)
        res = y - X*b
        qrb_chk("tau=0.2 coef intercept", b[1], -0.928025444764908, 1e-12, npass, nfail)
        qrb_chk("tau=0.2 coef lag1", b[2], 0.287690380675866, 1e-12, npass, nfail)
        qrb_chk("tau=0.2 coef lag2", b[3], 0.23615144597334, 1e-12, npass, nfail)
        qrb_chk("tau=0.2 rho", qrb_rho(res, 0.2), 249.428003588153, 1e-12, npass, nfail)
        qrb_chk("tau=0.2 nresneg", sum(res :<= 0), 52, 0, npass, nfail)
        qrb_chk("tau=0.2 ift flag", ift, 0, 0, npass, nfail)
        b8 = J(3, 1, 0)
        ift8 = qrb_rqbr(X, y, 0.8, b8)
        res8 = y - X*b8
        qrb_chk("tau=0.8 coef intercept", b8[1], 4.80394437666912, 1e-12, npass, nfail)
        qrb_chk("tau=0.8 coef lag1", b8[2], 0.442048072032511, 1e-12, npass, nfail)
        qrb_chk("tau=0.8 coef lag2", b8[3], -0.0592572048798019, 1e-12, npass, nfail)
        qrb_chk("tau=0.8 rho", qrb_rho(res8, 0.8), 247.329963248544, 1e-12, npass, nfail)
        qrb_chk("tau=0.8 nresneg", sum(res8 :<= 0), 197, 0, npass, nfail)
        qrb_chk("tau=0.8 ift flag", ift8, 0, 0, npass, nfail)
        printf("\n{txt}--- rqfnb (Frisch-Newton) solver, gdp full sample, tau=0.5 ---\n")
        printf("{txt}(iterative interior point method: agreement to about 1e-9 is the expected outcome here)\n")
        bf = qrb_rqfnb(X, y, 0.5)
        qrb_chk("fnb coef intercept", bf[1], 1.93757835309377, 1e-8, npass, nfail)
        qrb_chk("fnb coef lag1", bf[2], 0.334680618438449, 1e-8, npass, nfail)
        qrb_chk("fnb coef lag2", bf[3], 0.0486863664241789, 1e-8, npass, nfail)
    }
    printf("\n{txt}self test: {res}%g {txt}passed, {res}%g {txt}failed\n", npass, nfail)
}

end
