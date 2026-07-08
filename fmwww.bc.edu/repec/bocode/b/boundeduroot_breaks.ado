*! boundeduroot_breaks v1.0.0  Merwan Roudane  07jul2026
*! Bounded unit-root tests allowing structural breaks in the mean
*! Carrion-i-Silvestre & Gadea (2016), "Bounds, breaks and unit root tests",
*! Journal of Time Series Analysis 37(2), 165-181 -- faithful port of the
*! companion MATLAB code (main_unem.m, breaks*_dif.m, tests_b*.m, rbm_brk.m).
*! Part of the boundeduroot library. github.com/merwanroudane

program define boundeduroot_breaks, rclass
    version 14.0

    syntax varname(ts) [if] [in] , ///
        Lbound(real) ///
        Ubound(real) ///
        [ BReaks(string) ] ///
        [ METHod(string) ] ///
        [ Iter(integer 1000) ] ///
        [ MAXLag(integer -1) ] ///
        [ SEED(integer 16384) ] ///
        [ Level(cilevel) ] ///
        [ noGRAPH ] ///
        [ GNAME(string) ]

    if `lbound' >= `ubound' {
        di as error "lbound() must be strictly less than ubound()"
        exit 198
    }

    * ---- method (LRV): 1=parametric SAR, 2=nonparametric QS (default) -------
    if "`method'" == "" local method "np"
    local method = lower("`method'")
    if inlist("`method'","2","np","nonparametric") local metcode = 2
    else if inlist("`method'","1","ar","sar","parametric") local metcode = 1
    else {
        di as error "method() must be ar|sar|parametric or np|nonparametric"
        exit 198
    }

    * ---- which break configurations to show --------------------------------
    if "`breaks'" == "" local breaks "all"
    local breaks = lower("`breaks'")
    if !inlist("`breaks'","0","1","2","all") {
        di as error "breaks() must be 0, 1, 2 or all"
        exit 198
    }

    * ---- sample ------------------------------------------------------------
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
    if `N' < 40 {
        di as error "Insufficient observations (need at least 40)."
        exit 2001
    }
    if `maxlag' == -1 local maxlag = round(4*(`N'/100)^0.25)
    set seed `seed'

    di _n as text "{bf:Bounded unit-root tests with structural breaks}"
    di as text "Carrion-i-Silvestre & Gadea (2016), {it:J. Time Series Analysis} 37(2)"
    di as text "{hline 78}"

    * ---- engine ------------------------------------------------------------
    mata: _bbk_run("`varlist'","`touse'","`timevar'")
    * writes: __bbk_sta (3x5) stat rows [0,1,2 breaks] cols MSB MZa MZt VR ADF
    *         __bbk_cv5 (3x5)  5% simulated CVs
    *         __bbk_tb  (1x2)  estimated break positions (1-break, first of 2)
    *         __bbk_tb2 (1x2)  the two 2-break positions
    *         scalars __bbk_nbrec (recommended #breaks), __bbk_x0

    tempname STA CV5
    matrix `STA' = __bbk_sta
    matrix `CV5' = __bbk_cv5
    matrix rownames `STA' = no_break one_break two_breaks
    matrix colnames `STA' = MSB MZa MZt VR ADF
    matrix rownames `CV5' = no_break one_break two_breaks
    matrix colnames `CV5' = MSB MZa MZt VR ADF

    local x0    = __bbk_x0
    local nbrec = __bbk_nbrec
    local tb1   = __bbk_tb1
    local tb2a  = __bbk_tb2a
    local tb2b  = __bbk_tb2b

    * translate positions to time-variable values
    tempvar tt
    qui gen double `tt' = `timevar' if `touse'
    qui sort `tt'
    local dtb1  = `tt'[`tb1']
    local dtb2a = `tt'[`tb2a']
    local dtb2b = `tt'[`tb2b']

    di as text "  Variable        : " as result "`varlist'"
    di as text "  Observations T  : " as result `N'
    di as text "  Bounds [b, b-bar]: " as result "[`lbound', `ubound']"
    di as text "  LRV estimator   : " as result cond(`metcode'==2,"nonparametric (QS)","parametric (SAR)")
    di as text "  Break selection : " as result "`nbrec'" as text " break(s) (SBIC, first-differenced mean model)"
    di as text "  1-break date    : " as result "`dtb1'" as text "  (obs `tb1')"
    di as text "  2-break dates   : " as result "`dtb2a'" as text ", " as result "`dtb2b'" ///
        as text "  (obs `tb2a', `tb2b')"

    * ---- results table -----------------------------------------------------
    local siglev = 100 - `level'
    di _n as text "{hline 78}"
    di as text %-14s "Configuration" _col(16) %8s "MSB" _col(27) %9s "MZa" ///
        _col(39) %8s "MZt" _col(50) %8s "VR" _col(61) %8s "ADF"
    di as text "{hline 78}"
    local labs `""no break" "1 break" "2 breaks""'
    forvalues r = 1/3 {
        local nbk = `r'-1
        if "`breaks'"=="all" | "`breaks'"=="`nbk'" {
            local lab : word `r' of `labs'
            local line ""
            forvalues c = 1/5 {
                local st = `STA'[`r',`c']
                local cv = `CV5'[`r',`c']
                local star = ""
                * MSB, VR reject small; MZa, MZt, ADF reject large-negative -> all left tail
                if `st' < `cv' local star "*"
                local s`c' = `st'
                local k`c' "`star'"
            }
            di as text %-14s "`lab'" _col(16) as result %8.3f `s1' as text "`k1'" ///
                _col(27) as result %9.3f `s2' as text "`k2'" ///
                _col(39) as result %8.3f `s3' as text "`k3'" ///
                _col(50) as result %8.3f `s4' as text "`k4'" ///
                _col(61) as result %8.3f `s5' as text "`k5'"
        }
    }
    di as text "{hline 78}"
    di as text "`siglev'% bound-specific simulated critical values:"
    forvalues r = 1/3 {
        local nbk = `r'-1
        if "`breaks'"=="all" | "`breaks'"=="`nbk'" {
            local lab : word `r' of `labs'
            di as text %-14s "`lab'" _col(16) as result %8.3f `CV5'[`r',1] ///
                _col(27) %9.3f `CV5'[`r',2] _col(39) %8.3f `CV5'[`r',3] ///
                _col(50) %8.3f `CV5'[`r',4] _col(61) %8.3f `CV5'[`r',5]
        }
    }
    di as text "{hline 78}"
    di as text "H0: bounded unit root (with the stated number of level breaks)."
    di as text "A * marks rejection at `siglev'%: every statistic rejects in the left tail."

    * ---- returns -----------------------------------------------------------
    return scalar N       = `N'
    return scalar x0      = `x0'
    return scalar nbreaks = `nbrec'
    return scalar tb1     = `tb1'
    return scalar tb2_1   = `tb2a'
    return scalar tb2_2   = `tb2b'
    return scalar lbound  = `lbound'
    return scalar ubound  = `ubound'
    return local  depvar  "`varlist'"
    return local  timevar "`timevar'"
    return local  cmd     "boundeduroot breaks"
    return matrix stats   = `STA', copy
    return matrix cv5     = `CV5', copy

    * ---- graph -------------------------------------------------------------
    if "`graph'" != "nograph" {
        if "`gname'" == "" local gname bbreaks
        _bbk_plot , timevar(`timevar') depvar(`varlist') touse(`touse') ///
            lbound(`lbound') ubound(`ubound') gname(`gname') ///
            dtb1(`dtb1') dtb2a(`dtb2a') dtb2b(`dtb2b') nbrec(`nbrec')
    }

    capture matrix drop __bbk_sta __bbk_cv5
    capture scalar drop __bbk_x0 __bbk_nbrec __bbk_tb1 __bbk_tb2a __bbk_tb2b
end

*==============================================================================
* Journal figure: series with bounds and estimated break lines
*==============================================================================
program define _bbk_plot
    version 14.0
    syntax , timevar(string) depvar(string) touse(string) ///
        lbound(string) ubound(string) [ gname(string) ///
        dtb1(string) dtb2a(string) dtb2b(string) nbrec(string) ]

    local xl ""
    if `nbrec' == 1 & "`dtb1'" != "" ///
        local xl "xline(`dtb1', lpattern(solid) lcolor(dkgreen) lwidth(medthin))"
    if `nbrec' >= 2 & "`dtb2a'" != "" ///
        local xl "xline(`dtb2a' `dtb2b', lpattern(solid) lcolor(dkgreen) lwidth(medthin))"

    twoway (line `depvar' `timevar' if `touse', lcolor(navy) lwidth(medthin)), ///
        yline(`lbound' `ubound', lpattern(dash) lcolor(red) lwidth(medthin)) ///
        `xl' ///
        title("boundeduroot breaks: bounded series with estimated level breaks", size(medsmall)) ///
        subtitle("dashed red = bounds; green = SBIC-selected break(s)", size(small)) ///
        note("Carrion-i-Silvestre & Gadea (2016).", size(vsmall)) ///
        ytitle("`depvar'") xtitle("`timevar'") ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`gname', replace)
end


*==============================================================================
*                       M A T A   E N G I N E   (_bbk_*)
*==============================================================================
version 14.0
mata:

// ---- piecewise Skorohod folding across break segments (rbm_brk) -----------
real colvector _bbk_rbm_seg(real colvector x0, real scalar binf, real scalar bsup)
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

real colvector _bbk_rbm_brk(real colvector x, real colvector cinf,
    real colvector csup, real colvector Tb)
{
    real colvector vec, y
    real scalar T, ns, i, a, b
    T   = rows(x)
    vec = 0 \ Tb \ T
    ns  = rows(vec) - 1
    y   = x
    for (i=1; i<=ns; i++) {
        a = vec[i] + 1
        b = vec[i+1]
        y[|a \ b|] = _bbk_rbm_seg(x[|a \ b|], cinf[i], csup[i])
    }
    return(y)
}

// ---- MAIC lag selection on a detrended series -----------------------------
real scalar _bbk_maic(real colvector d, real scalar kmax)
{
    real scalar T, nef, k, i, r, t, sumy, s2, tau, mic, best, bestv
    real colvector dep, bb, e
    real matrix Rg, Xk
    T   = rows(d)
    nef = T - kmax - 1
    if (nef < 5) return(0)
    dep = J(nef,1,0)
    Rg  = J(nef, kmax+1, 0)
    for (r=1; r<=nef; r++) {
        t = kmax + 1 + r
        dep[r]  = d[t] - d[t-1]
        Rg[r,1] = d[t-1]
        for (i=1; i<=kmax; i++) {
            Rg[r,1+i] = d[t-i] - d[t-i-1]
        }
    }
    sumy  = quadcross(Rg[.,1], Rg[.,1])
    best  = 0
    bestv = .
    for (k=0; k<=kmax; k++) {
        Xk  = Rg[|1,1 \ nef,k+1|]
        bb  = invsym(quadcross(Xk,Xk))*quadcross(Xk,dep)
        e   = dep - Xk*bb
        s2  = quadcross(e,e)/nef
        tau = (bb[1]^2 * sumy)/s2
        mic = ln(s2) + 2*(k+tau)/nef
        if (mic < bestv | k==0) {
            bestv = mic
            best  = k
        }
    }
    return(best)
}

// ---- parametric SAR long-run variance from ADF regression (adfp) ----------
real scalar _bbk_sar(real colvector d, real scalar k)
{
    real scalar T, nobs, r, t, i, s2, sumb
    real colvector dep, b, e
    real matrix Rg
    T    = rows(d)
    nobs = T - k - 1
    dep  = J(nobs,1,0)
    Rg   = J(nobs, k+1, 0)
    for (r=1; r<=nobs; r++) {
        t = k + 1 + r
        dep[r]  = d[t] - d[t-1]
        Rg[r,1] = d[t-1]
        for (i=1; i<=k; i++) {
            Rg[r,1+i] = d[t-i] - d[t-i-1]
        }
    }
    b  = invsym(quadcross(Rg,Rg))*quadcross(Rg,dep)
    e  = dep - Rg*b
    s2 = quadcross(e,e)/nobs
    sumb = 0
    if (k >= 1) sumb = sum(b[|2 \ k+1|])
    return(s2/((1-sumb)^2))
}

// ---- nonparametric QS long-run variance on a detrended series -------------
real scalar _bbk_lrv_np(real colvector d)
{
    real colvector dy, res, acov
    real scalar T, beta, nr, n, j, s0, s2w, gam, mbw, xx, kw, lrv
    T    = rows(d)
    dy   = d[|2 \ T|] - d[|1 \ T-1|]
    beta = quadcross(d[|1 \ T-1|], dy)/quadcross(d[|1 \ T-1|], d[|1 \ T-1|])
    res  = dy - d[|1 \ T-1|]*beta
    nr   = rows(res)
    acov = J(nr,1,0)
    for (j=0; j<=nr-1; j++) {
        acov[j+1] = quadcross(res[|j+1 \ nr|], res[|1 \ nr-j|])/nr
    }
    n = floor(4*(T/100)^(2/25))
    if (n > nr-1) n = nr-1
    mbw = 0
    if (n > 0) {
        s0  = acov[1]
        s2w = 0
        for (j=1; j<=n; j++) {
            s0  = s0  + 2*acov[j+1]
            s2w = s2w + 2*(j^2)*acov[j+1]
        }
        if (s0 != 0) {
            gam = 1.3221*((s2w/s0)^2)^(1/5)
            mbw = gam*T^(1/5)
            if (mbw > T) mbw = T
        }
    }
    lrv = acov[1]
    if (mbw > 0) {
        for (j=1; j<=nr-1; j++) {
            xx = j/mbw
            kw = (25/(12*pi()^2*xx^2))*(sin(1.2*pi()*xx)/(1.2*pi()*xx) - cos(1.2*pi()*xx))
            lrv = lrv + 2*acov[j+1]*kw
        }
    }
    if (lrv <= 0) lrv = acov[1]
    return(lrv)
}

// ---- ADF t-stat with a constant and MAIC lags on a detrended series -------
real scalar _bbk_adf(real colvector d, real scalar kmax)
{
    real scalar T, k, nobs, r, t, i, se, s2
    real colvector dep, b, e
    real matrix Rg
    T = rows(d)
    k = _bbk_maic(d, kmax)
    nobs = T - k - 1
    dep = J(nobs,1,0)
    Rg  = J(nobs, k+2, 0)
    for (r=1; r<=nobs; r++) {
        t = k + 1 + r
        dep[r]  = d[t] - d[t-1]
        Rg[r,1] = 1
        Rg[r,2] = d[t-1]
        for (i=1; i<=k; i++) {
            Rg[r,2+i] = d[t-i] - d[t-i-1]
        }
    }
    b  = invsym(quadcross(Rg,Rg))*quadcross(Rg,dep)
    e  = dep - Rg*b
    s2 = quadcross(e,e)/nobs
    se = sqrt(luinv(quadcross(Rg,Rg))[2,2]*s2)
    return(b[2]/se)
}

// ---- the five statistics from a detrended series and its LRV --------------
real rowvector _bbk_stats(real colvector d, real scalar lrv, real scalar kmax)
{
    real scalar T, ss, msb, mza, mzt, vr, adf
    real colvector cs
    T   = rows(d)
    ss  = quadcross(d[|1 \ T-1|], d[|1 \ T-1|])
    msb = sqrt(ss/(lrv*T^2))
    mza = (d[T]^2/T - lrv)/(2*ss/T^2)
    mzt = mza*msb
    cs  = quadrunningsum(d)
    vr  = (quadcross(cs,cs)/T^2)/quadcross(d,d)
    adf = _bbk_adf(d, kmax)
    return((msb, mza, mzt, vr, adf))
}

real scalar _bbk_quantile(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, fl
    s  = sort(x,1)
    n  = rows(s)
    h  = (n-1)*p + 1
    fl = floor(h)
    if (fl >= n) return(s[n])
    if (fl < 1)  return(s[1])
    return(s[fl] + (h-fl)*(s[fl+1]-s[fl]))
}

// ---- OLS detrend: residual of y on design X -------------------------------
real colvector _bbk_detr(real colvector y, real matrix X)
{
    real colvector b
    b = invsym(quadcross(X,X))*quadcross(X,y)
    return(y - X*b)
}

// build step-dummy design [const, DU_1, ...] for break positions Tb (colvector)
real matrix _bbk_design(real scalar T, real colvector Tb)
{
    real matrix X
    real scalar nb, i, t
    nb = rows(Tb)
    X  = J(T, nb+1, 0)
    X[.,1] = J(T,1,1)
    for (i=1; i<=nb; i++) {
        for (t=1; t<=T; t++) {
            if (t > Tb[i]) X[t,1+i] = 1
        }
    }
    return(X)
}

// ---- 1-break estimation: argmax |dy| in trimmed range ---------------------
real scalar _bbk_break1(real colvector y)
{
    real colvector dy
    real scalar t, k, i, best, bestv, ad
    dy = y[|2 \ rows(y)|] - y[|1 \ rows(y)-1|]
    t  = rows(dy)
    k  = round(0.15*t)
    best  = k + 1
    bestv = -1
    for (i=k+1; i<=t-k; i++) {
        ad = abs(dy[i])
        if (ad > bestv) {
            bestv = ad
            best  = i
        }
    }
    return(best)
}

// ---- 2-break estimation: maximise dy[i]^2+dy[j]^2, |i-j|>=k ----------------
real rowvector _bbk_break2(real colvector y)
{
    real colvector dy
    real scalar t, k, i, j, bi, bj, bv, v
    dy = y[|2 \ rows(y)|] - y[|1 \ rows(y)-1|]
    t  = rows(dy)
    k  = floor(0.15*t)
    bi = k
    bj = 2*k
    bv = -1
    for (i=k; i<=t-2*k; i++) {
        for (j=k+i; j<=t-k; j++) {
            v = dy[i]^2 + dy[j]^2
            if (v > bv) {
                bv = v
                bi = i
                bj = j
            }
        }
    }
    return((bi+1, bj+1))
}

// ---- recommended number of breaks by SBIC on the first-differenced model --
real scalar _bbk_nbreaks(real colvector y, real scalar tb1, real scalar tb2a,
    real scalar tb2b)
{
    real colvector dy
    real scalar t, ssr0, ssr1, ssr2, b0, b1, b2, best, i
    real colvector bic
    dy   = y[|2 \ rows(y)|] - y[|1 \ rows(y)-1|]
    t    = rows(dy)
    ssr0 = quadcross(dy,dy)
    ssr1 = ssr0 - dy[tb1]^2
    ssr2 = ssr0 - dy[tb2a]^2 - dy[tb2b]^2
    bic  = J(3,1,.)
    bic[1] = ln(ssr0/t) + ln(t)/t*0
    bic[2] = ln(ssr1/t) + ln(t)/t*1
    bic[3] = ln(ssr2/t) + ln(t)/t*2
    best = 1
    for (i=2; i<=3; i++) {
        if (bic[i] < bic[best]) best = i
    }
    return(best-1)
}

// ---- driver ---------------------------------------------------------------
void _bbk_run(string scalar yvar, string scalar touse, string scalar tvar)
{
    real matrix X, STA, CV5, Xd
    real colvector y, d, Tb, cinf, csup, mns, ysim, dsim, scinf, scsup
    real scalar T, kmax, iter, metcode, lb, ub, x0, r, j, nb, lrv, lsim
    real scalar tb1, tb2a, tb2b, nbrec
    real rowvector t2, obs
    real matrix S
    real colvector Tbsim
    string scalar rs

    lb      = strtoreal(st_local("lbound"))
    ub      = strtoreal(st_local("ubound"))
    kmax    = strtoreal(st_local("maxlag"))
    iter    = strtoreal(st_local("iter"))
    metcode = strtoreal(st_local("metcode"))

    X  = st_data(., (yvar, tvar), touse)
    X  = sort(X, 2)
    y  = X[.,1]
    T  = rows(y)
    x0 = y[1]

    tb1  = _bbk_break1(y)
    t2   = _bbk_break2(y)
    tb2a = t2[1]
    tb2b = t2[2]
    if (tb2a > tb2b) {
        j    = tb2a
        tb2a = tb2b
        tb2b = j
    }
    nbrec = _bbk_nbreaks(y, tb1-1, tb2a-1, tb2b-1)

    STA = J(3,5,.)
    CV5 = J(3,5,.)

    rs = rseed()
    for (r=1; r<=3; r++) {
        nb = r - 1
        if (nb == 0) Tb = J(0,1,.)
        if (nb == 1) Tb = tb1
        if (nb == 2) Tb = (tb2a \ tb2b)

        // observed statistics
        Xd = _bbk_design(T, Tb)
        d  = _bbk_detr(y, Xd)
        if (metcode == 1) lrv = _bbk_sar(d, _bbk_maic(d, kmax))
        else              lrv = _bbk_lrv_np(d)
        STA[r,.] = _bbk_stats(d, lrv, kmax)

        // per-segment bounds (means shift by the estimated jumps; use x0 + cum jumps)
        mns = _bbk_segmeans(y, Tb, x0)
        cinf = J(nb+1,1,.)
        csup = J(nb+1,1,.)
        for (j=1; j<=nb+1; j++) {
            cinf[j] = (lb - mns[j])/sqrt(lrv*T)
            csup[j] = (ub - mns[j])/sqrt(lrv*T)
        }
        scinf = cinf :* sqrt(T)
        scsup = csup :* sqrt(T)

        // simulated critical values (rbm_brk piecewise folding, n = T)
        rseed(rs)
        S = J(iter,5,.)
        for (j=1; j<=iter; j++) {
            ysim = J(T,1,0)
            ysim[|2 \ T|] = rnormal(T-1,1,0,1)
            ysim = quadrunningsum(ysim)
            ysim = _bbk_rbm_brk(ysim, scinf, scsup, Tb)
            dsim = _bbk_detr(ysim, Xd)
            if (metcode == 1) lsim = _bbk_sar(dsim, _bbk_maic(dsim, kmax))
            else              lsim = _bbk_lrv_np(dsim)
            S[j,.] = _bbk_stats(dsim, lsim, kmax)
        }
        for (j=1; j<=5; j++) {
            CV5[r,j] = _bbk_quantile(S[.,j], .05)
        }
    }

    st_matrix("__bbk_sta", STA)
    st_matrix("__bbk_cv5", CV5)
    st_numscalar("__bbk_x0", x0)
    st_numscalar("__bbk_nbrec", nbrec)
    st_numscalar("__bbk_tb1", tb1)
    st_numscalar("__bbk_tb2a", tb2a)
    st_numscalar("__bbk_tb2b", tb2b)
}

// segment mean levels: x0, x0+jump1, x0+jump1+jump2 (jumps from dy at breaks)
real colvector _bbk_segmeans(real colvector y, real colvector Tb, real scalar x0)
{
    real colvector dy, mns
    real scalar nb, i, cum
    nb = rows(Tb)
    mns = J(nb+1,1,x0)
    if (nb == 0) return(mns)
    dy  = y[|2 \ rows(y)|] - y[|1 \ rows(y)-1|]
    cum = x0
    for (i=1; i<=nb; i++) {
        cum = cum + dy[Tb[i]-1]
        mns[i+1] = cum
    }
    return(mns)
}

end
