*! boundeduroot_hlt v1.0.0  Merwan Roudane  07jul2026
*! Harvey-Leybourne-Taylor multiple level-shift test for bounded series
*! Carrion-i-Silvestre & Gadea (2024), "Detecting multiple level shifts in
*! bounded time series" -- Case A (no change in the boundaries). Faithful port
*! of HLT_test_empirical_caseA.m / test_HLT_bounds_caseA_empirical.m /
*! calcula_cv_test_fs_HLT_bounds_caseA.m / HLT_test_bounds_caseA.m.
*! Part of the boundeduroot library. github.com/merwanroudane

program define boundeduroot_hlt, rclass
    version 14.0

    syntax varname(ts) [if] [in] , ///
        Lbound(real) ///
        Ubound(real) ///
        [ Window(real 0.15) ] ///
        [ Iter(integer 400) ] ///
        [ SEED(integer 1) ] ///
        [ Level(cilevel) ] ///
        [ noGRAPH ] ///
        [ GNAME(string) ]

    if `lbound' >= `ubound' {
        di as error "lbound() must be strictly less than ubound()"
        exit 198
    }
    * window must be one of the tabulated values
    local wok = 0
    foreach w in 0.10 0.15 0.20 0.25 0.30 {
        if abs(`window'-`w') < 1e-6 local wok = 1
    }
    if !`wok' {
        di as error "window() must be one of 0.10, 0.15, 0.20, 0.25, 0.30"
        exit 198
    }

    * significance level for reporting -> percentile of the CV distribution
    local per = `level'
    if !inlist(`per',90,95,97,99,975) {
        * map cilevel to the supported grid {90,95,97.5,99}
        if `level' <= 90       local per = 90
        else if `level' <= 95  local per = 95
        else if `level' <= 98  local per = 975
        else                   local per = 99
    }

    marksample touse
    markout `touse' `varlist'
    capture qui tsset
    if _rc {
        di as error "Data are not tsset. Use {cmd:tsset} timevar first."
        exit 111
    }
    local timevar "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as error "Panel data are not supported; use a single time series."
        exit 198
    }
    markout `touse' `timevar'
    qui count if `touse'
    local N = r(N)
    if `N' < 50 {
        di as error "Insufficient observations (need at least 50)."
        exit 2001
    }
    set seed `seed'

    di _n as text "{bf:Bounded multiple level-shift test (HLT)}"
    di as text "Carrion-i-Silvestre & Gadea (2024), Case A -- Harvey, Leybourne & Taylor (2010)"
    di as text "{hline 78}"
    di as text "Computing bound-specific critical values by simulation; please be patient..."

    mata: _hlt_run("`varlist'","`touse'","`timevar'")
    * writes: __hlt_res (nb x 7): brkobs, s1v, s0v, cv_s1, cv_s0, rej_s1, rej_s0
    *         __hlt_u   (nb x 1): union-test rejection flags
    *         scalars __hlt_nb __hlt_x0 __hlt_omu __hlt_ome __hlt_wind

    tempname R U
    matrix `R' = __hlt_res
    matrix `U' = __hlt_u
    local nb = __hlt_nb

    * map break positions to time values
    tempvar tt
    qui gen double `tt' = `timevar' if `touse'
    qui sort `tt'

    di as text "  Variable        : " as result "`varlist'"
    di as text "  Observations T  : " as result `N'
    di as text "  Bounds [b, b-bar]: " as result "[`lbound', `ubound']"
    di as text "  Window (m)      : " as result %4.2f __hlt_wind
    di as text "  omega_u (levels): " as result %9.5f __hlt_omu ///
        as text "   omega_e (diffs): " as result %9.5f __hlt_ome
    di as text "  Candidate breaks: " as result `nb' as text "   CV percentile: " as result `per' "%"

    di _n as text "{hline 78}"
    di as text %-8s "Break" _col(10) %8s "date" _col(22) %9s "S1" _col(33) %9s "CV(S1)" ///
        _col(45) %9s "S0" _col(56) %9s "CV(S0)" _col(68) "shift?"
    di as text "{hline 78}"
    local anyS1 0
    local anyS0 0
    forvalues i = 1/`nb' {
        local pos = `R'[`i',1]
        local dte = `tt'[`pos']
        local s1  = `R'[`i',2]
        local s0  = `R'[`i',3]
        local c1  = `R'[`i',4]
        local c0  = `R'[`i',5]
        local r1  = `R'[`i',6]
        local r0  = `R'[`i',7]
        local u   = `U'[`i',1]
        local tag = ""
        if `r1' & `r0'      local tag "S1+S0"
        else if `r1'        local tag "S1"
        else if `r0'        local tag "S0"
        if `u'              local tag "`tag' (U)"
        if `r1' local anyS1 = `anyS1' + 1
        if `r0' local anyS0 = `anyS0' + 1
        di as text %-8s "`i'" _col(10) as result %8.0g `dte' ///
            _col(22) %9.4f `s1' _col(33) %9.4f `c1' ///
            _col(45) %9.4f `s0' _col(56) %9.4f `c0' ///
            _col(68) as text "`tag'"
    }
    di as text "{hline 78}"
    di as text "A level shift is flagged when the statistic exceeds its bound-specific CV."
    di as text "S1 uses the I(1) long-run variance; S0 uses the I(0) one; (U) = union test."
    di as text "Breaks flagged: " as result "`anyS1'" as text " by S1, " as result "`anyS0'" as text " by S0."

    return scalar N        = `N'
    return scalar nbreaks  = `nb'
    return scalar n_shift_s1 = `anyS1'
    return scalar n_shift_s0 = `anyS0'
    return scalar omega_u  = __hlt_omu
    return scalar omega_e  = __hlt_ome
    return scalar x0       = __hlt_x0
    return scalar lbound   = `lbound'
    return scalar ubound   = `ubound'
    return local  depvar  "`varlist'"
    return local  timevar "`timevar'"
    return local  cmd     "boundeduroot hlt"
    return matrix result  = `R', copy

    if "`graph'" != "nograph" {
        if "`gname'" == "" local gname bhlt
        * collect flagged break dates (S1 or S0)
        local bl ""
        forvalues i = 1/`nb' {
            if `R'[`i',6] | `R'[`i',7] {
                local pos = `R'[`i',1]
                local bl "`bl' `=`tt'[`pos']'"
            }
        }
        _hlt_plot , timevar(`timevar') depvar(`varlist') touse(`touse') ///
            lbound(`lbound') ubound(`ubound') gname(`gname') brklines(`bl')
    }

    capture matrix drop __hlt_res __hlt_u
    capture scalar drop __hlt_nb __hlt_x0 __hlt_omu __hlt_ome __hlt_wind
end

*==============================================================================
* Journal figure
*==============================================================================
program define _hlt_plot
    version 14.0
    syntax , timevar(string) depvar(string) touse(string) ///
        lbound(string) ubound(string) [ gname(string) brklines(string) ]
    local xl ""
    if "`brklines'" != "" ///
        local xl "xline(`brklines', lpattern(solid) lcolor(dkgreen) lwidth(medthin))"
    twoway (line `depvar' `timevar' if `touse', lcolor(navy) lwidth(medthin)), ///
        yline(`lbound' `ubound', lpattern(dash) lcolor(red) lwidth(medthin)) ///
        `xl' ///
        title("boundeduroot hlt: bounded series with detected level shifts", size(medsmall)) ///
        subtitle("dashed red = bounds; green = significant level shift(s)", size(small)) ///
        note("Carrion-i-Silvestre & Gadea (2024), HLT (2010).", size(vsmall)) ///
        ytitle("`depvar'") xtitle("`timevar'") ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`gname', replace)
end


*==============================================================================
*                       M A T A   E N G I N E   (_hlt_*)
*==============================================================================
version 14.0
mata:

real scalar _hlt_nbmax(real scalar m)
{
    if (abs(m-0.10) < 1e-6) return(8)
    if (abs(m-0.15) < 1e-6) return(5)
    if (abs(m-0.20) < 1e-6) return(4)
    return(3)
}

// forward-window mean minus backward-window mean
real colvector _hlt_Mj(real colvector y, real scalar wind)
{
    real colvector M
    real scalar T, t, fwd, bwd
    T = rows(y)
    M = J(T,1,0)
    for (t=1; t<=T; t++) {
        if (t-wind >= 1 & t+wind <= T) {
            fwd = mean(y[|t+1 \ t+wind|])
            bwd = mean(y[|t-wind+1 \ t|])
            M[t] = fwd - bwd
        }
    }
    return(M)
}

// sequential peak detection of an absolute-value series over [lo,hi] with
// minimum separation sep, up to nbmax peaks. Returns colvector of positions.
real colvector _hlt_peaks(real colvector av, real scalar lo, real scalar hi,
    real scalar sep, real scalar nbmax)
{
    real colvector avail, out
    real scalar t, i, best, bestv, a, b
    avail = J(rows(av),1,0)
    for (t=lo; t<=hi; t++) avail[t] = 1
    out = J(0,1,.)
    for (i=1; i<=nbmax; i++) {
        best  = 0
        bestv = -1
        for (t=lo; t<=hi; t++) {
            if (avail[t] == 1) {
                if (av[t] > bestv) {
                    bestv = av[t]
                    best  = t
                }
            }
        }
        if (best == 0) return(out)
        out = out \ best
        a = best - sep + 1
        b = best + sep - 1
        if (a < 1) a = 1
        if (b > rows(av)) b = rows(av)
        for (t=a; t<=b; t++) avail[t] = 0
    }
    return(out)
}

// impulse jumps: theta_i = dy at each break date (orthogonal impulse OLS)
real colvector _hlt_impulses(real colvector y, real colvector dates)
{
    real colvector dy, th
    real scalar T, i
    if (rows(dates) == 0) return(J(0,1,0))
    T  = rows(y)
    dy = y[|2 \ T|] - y[|1 \ T-1|]
    th = J(rows(dates),1,0)
    for (i=1; i<=rows(dates); i++) {
        if (dates[i] >= 1 & dates[i] <= rows(dy)) th[i] = dy[dates[i]]
    }
    return(th)
}

// long-run variance of first differences (lrv_e): AR-BIC, lrv = s2/b(1)^2
real scalar _hlt_lrv_e(real colvector z, real scalar kmax)
{
    real scalar n, k, kopt, bestv, r0, t, i, nef, s2, bicv, b1, lrv
    real colvector dz, dep, b, e
    real matrix Xg
    n  = rows(z)
    dz = J(n,1,.)
    dz[|2 \ n|] = z[|2 \ n|] - z[|1 \ n-1|]
    kopt  = 1
    bestv = .
    for (k=1; k<=kmax; k++) {
        nef = n - kmax
        dep = J(nef,1,0)
        Xg  = J(nef, k, 0)
        for (r0=1; r0<=nef; r0++) {
            t = kmax + r0
            dep[r0]  = dz[t]
            Xg[r0,1] = z[t-1]
            for (i=1; i<=k-1; i++) {
                Xg[r0,1+i] = dz[t-i]
            }
        }
        b  = invsym(quadcross(Xg,Xg))*quadcross(Xg,dep)
        e  = dep - Xg*b
        s2 = quadcross(e,e)/(nef - k)
        bicv = ln(s2) + k*ln(nef)/nef
        if (bicv < bestv | k==1) {
            bestv = bicv
            kopt  = k
        }
    }
    nef = n - kopt
    dep = J(nef,1,0)
    Xg  = J(nef, kopt, 0)
    for (r0=1; r0<=nef; r0++) {
        t = kopt + r0
        dep[r0]  = dz[t]
        Xg[r0,1] = z[t-1]
        for (i=1; i<=kopt-1; i++) {
            Xg[r0,1+i] = dz[t-i]
        }
    }
    b  = invsym(quadcross(Xg,Xg))*quadcross(Xg,dep)
    e  = dep - Xg*b
    s2 = quadcross(e,e)/(nef - kopt)
    b1 = b[1]
    lrv = s2/(b1^2)
    if (lrv <= 0 | lrv >= .) lrv = s2
    return(lrv)
}

// long-run variance of levels with impulse dummies (lrv_u): AR-BIC on the
// residual, dummies (and their lags) included; lrv = s2/b(1)^2.
real scalar _hlt_lrv_u(real colvector z, real scalar kmax, real matrix dum)
{
    real scalar n, nd, k, kopt, bestv, r0, t, i, j, nef, s2, bicv, b1, lrv, nc
    real colvector dz, dep, b, e
    real matrix Xg
    n  = rows(z)
    nd = cols(dum)
    dz = J(n,1,.)
    dz[|2 \ n|] = z[|2 \ n|] - z[|1 \ n-1|]
    kopt  = 1
    bestv = .
    for (k=1; k<=kmax; k++) {
        nc  = 1 + nd + (k-1) + nd*(k-1)
        nef = n - kmax
        dep = J(nef,1,0)
        Xg  = J(nef, nc, 0)
        for (r0=1; r0<=nef; r0++) {
            t = kmax + r0
            dep[r0]  = dz[t]
            Xg[r0,1] = z[t-1]
            for (j=1; j<=nd; j++) {
                Xg[r0,1+j] = dum[t,j]
            }
            for (i=1; i<=k-1; i++) {
                Xg[r0,1+nd+i] = dz[t-i]
            }
            for (j=1; j<=nd; j++) {
                for (i=1; i<=k-1; i++) {
                    Xg[r0,1+nd+(k-1)+(j-1)*(k-1)+i] = dum[t-i,j]
                }
            }
        }
        b  = invsym(quadcross(Xg,Xg))*quadcross(Xg,dep)
        e  = dep - Xg*b
        s2 = quadcross(e,e)/(nef - nc)
        bicv = ln(s2) + k*ln(nef)/nef
        if (bicv < bestv | k==1) {
            bestv = bicv
            kopt  = k
        }
    }
    k   = kopt
    nc  = 1 + nd + (k-1) + nd*(k-1)
    nef = n - k
    dep = J(nef,1,0)
    Xg  = J(nef, nc, 0)
    for (r0=1; r0<=nef; r0++) {
        t = k + r0
        dep[r0]  = dz[t]
        Xg[r0,1] = z[t-1]
        for (j=1; j<=nd; j++) {
            Xg[r0,1+j] = dum[t,j]
        }
        for (i=1; i<=k-1; i++) {
            Xg[r0,1+nd+i] = dz[t-i]
        }
        for (j=1; j<=nd; j++) {
            for (i=1; i<=k-1; i++) {
                Xg[r0,1+nd+(k-1)+(j-1)*(k-1)+i] = dum[t-i,j]
            }
        }
    }
    b  = invsym(quadcross(Xg,Xg))*quadcross(Xg,dep)
    e  = dep - Xg*b
    s2 = quadcross(e,e)/(nef - nc)
    b1 = b[1]
    lrv = s2/(b1^2)
    if (lrv <= 0 | lrv >= .) lrv = s2
    return(lrv)
}

// Skorohod folding into [binf, bsup]
real colvector _hlt_rbm(real colvector x0, real scalar binf, real scalar bsup)
{
    real colvector x
    real scalar it, bad
    x = x0
    it = 0
    bad = 1
    while (bad & it < 10000) {
        bad = 0
        if (bsup < .) {
            if (max(x) > bsup) {
                x = bsup :- abs(x :- bsup)
                bad = 1
            }
        }
        if (binf < .) {
            if (min(x) < binf) {
                x = binf :+ abs(x :- binf)
                bad = 1
            }
        }
        it = it + 1
    }
    return(x)
}

// build step-dummy (cumsum of impulses) design [const, du...] from dy-breaks
real matrix _hlt_stepdesign(real scalar T, real colvector brk)
{
    real matrix X
    real scalar nb, i, t
    nb = rows(brk)
    X  = J(T, nb+1, 0)
    X[.,1] = J(T,1,1)
    for (i=1; i<=nb; i++) {
        for (t=1; t<=T; t++) {
            if (t >= brk[i]+1) X[t,1+i] = 1
        }
    }
    return(X)
}

real matrix _hlt_impdesign(real scalar T, real colvector brk)
{
    real matrix D
    real scalar nb, i
    nb = rows(brk)
    D  = J(T, nb, 0)
    for (i=1; i<=nb; i++) {
        if (brk[i]+1 >= 1 & brk[i]+1 <= T) D[brk[i]+1, i] = 1
    }
    return(D)
}

// omega_u, omega_e from dy-detected breaks (returns 2-vector)
real rowvector _hlt_omega(real colvector y, real scalar m, real scalar kmax)
{
    real scalar T, tL, tU, sep, nbmax
    real colvector dy, adyv, brk, r, dr, b
    real matrix Xs, Di, Xd
    real scalar omu, ome
    T   = rows(y)
    tL  = round(0.15*T)
    tU  = round(0.85*T)
    sep = round(m*T)
    nbmax = _hlt_nbmax(m)
    dy  = J(T,1,0)
    dy[|2 \ T|] = y[|2 \ T|] - y[|1 \ T-1|]
    adyv = abs(dy)
    // detection window for dy is [tL+1, tU+1]; break position = index-1
    brk = _hlt_peaks(adyv, tL+1, tU+1, sep, nbmax) :- 1
    // levels LRV
    Xs = _hlt_stepdesign(T, brk)
    b  = invsym(quadcross(Xs,Xs))*quadcross(Xs,y)
    r  = y - Xs*b
    Di = _hlt_impdesign(T, brk)
    omu = _hlt_lrv_u(r, kmax, Di)
    // first-difference LRV: residual of dy on impulse dummies (drop first obs)
    dr = dy[|2 \ T|]
    if (cols(Di) >= 1) {
        Xd = Di[|2,1 \ T, cols(Di)|]
        b  = invsym(quadcross(Xd,Xd))*quadcross(Xd,dr)
        dr = dr - Xd*b
    }
    ome = _hlt_lrv_e(dr, kmax)
    return((omu, ome))
}

// simulation statistics S1_stat, S0_stat for a series
real rowvector _hlt_simstat(real colvector y, real scalar m, real scalar kmax)
{
    real scalar T, tL, tU, wind, mx, s1, s0
    real rowvector om
    real colvector M
    T    = rows(y)
    tL   = round(0.15*T)
    tU   = round(0.85*T)
    wind = round(m*T/2)
    om   = _hlt_omega(y, m, kmax)
    M    = _hlt_Mj(y, wind)
    mx   = max(abs(M[|tL \ tU|]))
    s1   = (mx/sqrt(T))/sqrt(om[2])
    s0   = (mx*sqrt(T))/sqrt(om[1])
    return((s1, s0))
}

real scalar _hlt_pctile(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, fl
    s  = sort(x,1)
    n  = rows(s)
    h  = (n-1)*(p/100) + 1
    fl = floor(h)
    if (fl >= n) return(s[n])
    if (fl < 1)  return(s[1])
    return(s[fl] + (h-fl)*(s[fl+1]-s[fl]))
}

// driver
void _hlt_run(string scalar yvar, string scalar touse, string scalar tvar)
{
    real matrix X, RES, U, X0bank, X1bank
    real colvector y, M, brkM, s1v, s0v, dates_sorted, earlier, theta
    real colvector S1sim, S0sim, x1, x0v, CVmax
    real scalar T, m, iter, per, lb, ub, x00, kmax
    real scalar tL, tU, wind, sep, nbmax, mx, i, j, nb, shift
    real scalar cinf, csup, cv1, cv0, cmax, kappa, prevrej
    real rowvector om, ss

    lb   = strtoreal(st_local("lbound"))
    ub   = strtoreal(st_local("ubound"))
    m    = strtoreal(st_local("window"))
    iter = strtoreal(st_local("iter"))
    per  = strtoreal(st_local("per"))
    if (per == 975) per = 97.5

    X   = st_data(., (yvar, tvar), touse)
    X   = sort(X, 2)
    y   = X[.,1]
    T   = rows(y)
    x00 = y[1]
    kmax = round(4*(T/100)^0.25)

    tL   = round(0.15*T)
    tU   = round(0.85*T)
    wind = round(m*T/2)
    sep  = round(m*T)
    nbmax = _hlt_nbmax(m)

    // observed omega and break detection from M_j
    om = _hlt_omega(y, m, kmax)
    M  = _hlt_Mj(y, wind)
    brkM = _hlt_peaks(abs(M), tL, tU, sep, nbmax)   // positions are actual times
    nb   = rows(brkM)
    s1v  = J(nb,1,.)
    s0v  = J(nb,1,.)
    for (i=1; i<=nb; i++) {
        s1v[i] = (abs(M[brkM[i]])/sqrt(T))/sqrt(om[2])
        s0v[i] = (abs(M[brkM[i]])*sqrt(T))/sqrt(om[1])
    }

    // one common random bank (matches rng-reset-per-break in the source)
    rseed(strtoreal(st_local("seed")))
    X0bank = J(T,iter,0)
    X0bank[|2,1 \ T,iter|] = rnormal(T-1,iter,0,1)

    RES = J(nb,7,.)
    U   = J(nb,1,0)
    prevrej = 1
    for (i=1; i<=nb; i++) {
        // cumulative level shift up to this break (breaks earlier in time)
        earlier = select(brkM, brkM :< brkM[i])
        theta = _hlt_impulses(y, sort(earlier,1))
        shift = 0
        if (rows(theta) > 0) shift = sum(theta)
        cinf = (lb - shift - x00)/sqrt(om[2]*T)
        csup = (ub - shift - x00)/sqrt(om[2]*T)

        // simulate bounded I(1) and I(0) statistic distributions
        S1sim = J(iter,1,.)
        S0sim = J(iter,1,.)
        for (j=1; j<=iter; j++) {
            x1  = _hlt_rbm(quadrunningsum(X0bank[.,j]), cinf*sqrt(T), csup*sqrt(T))
            ss  = _hlt_simstat(x1, m, kmax)
            S1sim[j] = ss[1]
            x0v = _hlt_rbm(X0bank[.,j], cinf, csup)
            ss  = _hlt_simstat(x0v, m, kmax)
            S0sim[j] = ss[2]
        }
        cv1 = _hlt_pctile(S1sim, per)
        cv0 = _hlt_pctile(S0sim, per)
        // union-test scaling
        CVmax = J(iter,1,.)
        for (j=1; j<=iter; j++) {
            CVmax[j] = max((S1sim[j], cv1*S0sim[j]/cv0))
        }
        cmax  = _hlt_pctile(CVmax, per)
        kappa = cmax/cv1

        RES[i,1] = brkM[i]
        RES[i,2] = s1v[i]
        RES[i,3] = s0v[i]
        RES[i,4] = cv1
        RES[i,5] = cv0
        RES[i,6] = (s1v[i] > cv1)
        RES[i,7] = (s0v[i] > cv0)
        // sequential union test: significant only while consecutively rejecting
        if (prevrej == 1) {
            if ((s1v[i] > kappa*cv1) | (s0v[i] > kappa*cv0)) {
                U[i] = 1
            }
            else {
                prevrej = 0
            }
        }
    }

    st_matrix("__hlt_res", RES)
    st_matrix("__hlt_u", U)
    st_numscalar("__hlt_nb", nb)
    st_numscalar("__hlt_x0", x00)
    st_numscalar("__hlt_omu", om[1])
    st_numscalar("__hlt_ome", om[2])
    st_numscalar("__hlt_wind", m)
}

end
