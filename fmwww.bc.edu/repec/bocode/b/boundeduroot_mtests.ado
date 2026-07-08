*! boundeduroot_mtests v1.0.0  Merwan Roudane  07jul2026
*! GLS-based M unit-root tests for bounded processes
*! Carrion-i-Silvestre & Gadea (2013), "GLS-based unit root tests for
*! bounded processes" -- faithful port of the companion MATLAB code
*! (estima_M_tests_bounded.m / cv_M_tests_bounded.m).
*! Part of the boundeduroot library. github.com/merwanroudane

program define boundeduroot_mtests, rclass
    version 14.0

    syntax varname(ts) [if] [in] , ///
        Lbound(string) ///
        [ Ubound(string) ] ///
        [ Iter(integer 1000) ] ///
        [ MAXLag(integer -1) ] ///
        [ SEED(integer 16384) ] ///
        [ Level(cilevel) ] ///
        [ noGRAPH ] ///
        [ GNAME(string) ]

    * ---- bounds ------------------------------------------------------------
    local lb = lower("`lbound'")
    local ub = lower("`ubound'")
    local lbval = .
    if !inlist("`lb'","",".","inf","-inf","none") {
        capture confirm number `lbound'
        if _rc {
            di as error "lbound() must be a number or . for one-sided"
            exit 198
        }
        local lbval = real("`lbound'")
    }
    local ubval = .
    if !inlist("`ub'","",".","inf","+inf","none") {
        capture confirm number `ubound'
        if _rc {
            di as error "ubound() must be a number or . for one-sided"
            exit 198
        }
        local ubval = real("`ubound'")
    }
    if `lbval'==. & `ubval'==. {
        di as error "Specify at least one finite bound in lbound() or ubound()."
        exit 198
    }
    if `lbval'!=. & `ubval'!=. {
        if `lbval' >= `ubval' {
            di as error "lower bound must be strictly less than upper bound"
            exit 198
        }
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
    if `N' < 30 {
        di as error "Insufficient observations (need at least 30)."
        exit 2001
    }
    if `maxlag' == -1 local maxlag = floor(12*(`N'/100)^0.25)
    if `iter' < 100 {
        di as error "iter() must be at least 100"
        exit 198
    }
    set seed `seed'

    di _n as text "{bf:Bounded M unit-root tests} (Carrion-i-Silvestre & Gadea 2013)"
    di as text "{hline 78}"

    * ---- engine ------------------------------------------------------------
    mata: _bmt_run("`varlist'","`touse'","`timevar'")
    * writes: __bmt_sta (6x3), __bmt_cv_msb __bmt_cv_mza __bmt_cv_mzt (6x4),
    *         __bmt_c (6x2), scalars __bmt_kap_ar __bmt_kap_np __bmt_x0

    tempname STA CVM CVA CVT CIN
    matrix `STA' = __bmt_sta
    matrix `CVM' = __bmt_cv_msb
    matrix `CVA' = __bmt_cv_mza
    matrix `CVT' = __bmt_cv_mzt
    matrix `CIN' = __bmt_c
    local rn "OLS_ar OLS_np GLSERS_ar GLSERS_np GLSBOUNDS_ar GLSBOUNDS_np"
    matrix rownames `STA' = `rn'
    matrix colnames `STA' = MSB MZa MZt
    matrix rownames `CVM' = `rn'
    matrix rownames `CVA' = `rn'
    matrix rownames `CVT' = `rn'
    matrix colnames `CVM' = cv1 cv2_5 cv5 cv10
    matrix colnames `CVA' = cv1 cv2_5 cv5 cv10
    matrix colnames `CVT' = cv1 cv2_5 cv5 cv10
    matrix rownames `CIN' = `rn'
    matrix colnames `CIN' = c_inf c_sup

    * ---- configuration block -------------------------------------------------
    local lbtxt = cond(`lbval'==., "-inf", string(`lbval'))
    local ubtxt = cond(`ubval'==., "+inf", string(`ubval'))
    di as text "  Variable        : " as result "`varlist'"
    di as text "  Observations T  : " as result `N'
    di as text "  Bounds [b, b-bar]: " as result "[`lbtxt', `ubtxt']"
    di as text "  X0 (first obs)  : " as result %9.5f __bmt_x0
    di as text "  kappa-hat (GLS-BOUNDS): " as result %8.4f __bmt_kap_ar ///
        as text " (parametric)   " as result %8.4f __bmt_kap_np as text " (nonparametric)"
    di as text "  Simulated CVs   : " as result `iter' as text " draws, folded (reflected) Brownian motion, seed(`seed')"

    * ---- results table -------------------------------------------------------
    local plab1 "OLS demeaning"
    local plab2 "GLS-ERS demeaning (c-bar = -7)"
    local plab3 "GLS-BOUNDS demeaning (c-bar = kappa-hat)"

    di _n as text "{hline 78}"
    di as text %-26s "Detrending / LRV" _col(30) %8s "MSB" _col(44) %9s "MZa" ///
        _col(58) %9s "MZt"
    di as text "{hline 78}"
    forvalues p = 1/3 {
        di as text "{bf:`plab`p''}"
        forvalues s = 1/2 {
            local r = (`p'-1)*2 + `s'
            local lrvlab = cond(`s'==1, "  parametric (SAR)", "  nonparametric (QS)")
            local out ""
            forvalues c = 1/3 {
                local st = `STA'[`r',`c']
                if `c'==1 matrix __cvx = `CVM'
                if `c'==2 matrix __cvx = `CVA'
                if `c'==3 matrix __cvx = `CVT'
                local star ""
                if `st' < __cvx[`r',4] local star "*"
                if `st' < __cvx[`r',3] local star "**"
                if `st' < __cvx[`r',1] local star "***"
                local st`c' = `st'
                local sr`c' "`star'"
            }
            di as text %-26s "`lrvlab'" _col(30) as result %8.4f `st1' as text %-3s "`sr1'" ///
                _col(44) as result %9.4f `st2' as text %-3s "`sr2'" ///
                _col(58) as result %9.4f `st3' as text %-3s "`sr3'"
        }
    }
    di as text "{hline 78}"
    di as text "H0: bounded unit root.  All three tests reject for SMALL values of the"
    di as text "statistic:  * p<.10   ** p<.05   *** p<.01  (bound-specific simulated CVs)."

    * ---- CV table -------------------------------------------------------------
    local siglev = 100 - `level'
    local cvcol = 3
    if `siglev' <= 1       local cvcol = 1
    else if `siglev' <= 3  local cvcol = 2
    else if `siglev' <= 5  local cvcol = 3
    else                   local cvcol = 4
    di _n as text "Simulated `siglev'% critical values (given the bounds and estimated c, c-bar):"
    di as text "{hline 78}"
    di as text %-26s "Detrending / LRV" _col(30) %8s "MSB" _col(44) %9s "MZa" ///
        _col(58) %9s "MZt"
    di as text "{hline 78}"
    local lab1 "OLS / SAR"
    local lab2 "OLS / QS"
    local lab3 "GLS-ERS / SAR"
    local lab4 "GLS-ERS / QS"
    local lab5 "GLS-BOUNDS / SAR"
    local lab6 "GLS-BOUNDS / QS"
    forvalues r = 1/6 {
        di as text %-26s "  `lab`r''" _col(30) as result %8.4f `CVM'[`r',`cvcol'] ///
            _col(44) %9.4f `CVA'[`r',`cvcol'] _col(58) %9.4f `CVT'[`r',`cvcol']
    }
    di as text "{hline 78}"
    di as text "c-hat ranges over configs: [" as result %6.3f `CIN'[1,1] as text "," ///
        as result %6.3f `CIN'[6,1] as text "] (lower)   [" ///
        as result %6.3f `CIN'[1,2] as text "," as result %6.3f `CIN'[6,2] as text "] (upper)"

    * ---- returns ---------------------------------------------------------------
    return scalar N        = `N'
    return scalar x0       = __bmt_x0
    return scalar kappa_ar = __bmt_kap_ar
    return scalar kappa_np = __bmt_kap_np
    return scalar lbound   = `lbval'
    return scalar ubound   = `ubval'
    return scalar iter     = `iter'
    return local  depvar  "`varlist'"
    return local  timevar "`timevar'"
    return local  cmd     "boundeduroot mtests"
    return matrix stats   = `STA', copy
    return matrix cv_msb  = `CVM', copy
    return matrix cv_mza  = `CVA', copy
    return matrix cv_mzt  = `CVT', copy
    return matrix cpars   = `CIN', copy

    * ---- graph -------------------------------------------------------------------
    if "`graph'" != "nograph" {
        if "`gname'" == "" local gname bmtests
        _bmt_plot , timevar(`timevar') depvar(`varlist') touse(`touse') ///
            lbound(`lbval') ubound(`ubval') gname(`gname')
    }

    capture matrix drop __bmt_sta __bmt_cv_msb __bmt_cv_mza __bmt_cv_mzt __bmt_c __cvx
    capture scalar drop __bmt_kap_ar __bmt_kap_np __bmt_x0
end

*==============================================================================
* Journal figure: series + bounds, and statistic-vs-CV dot chart
*==============================================================================
program define _bmt_plot
    version 14.0
    syntax , timevar(string) depvar(string) touse(string) ///
        [ lbound(string) ubound(string) gname(string) ]

    local yl ""
    if !inlist("`lbound'",".","") ///
        local yl "`yl' yline(`lbound', lpattern(dash) lcolor(red) lwidth(medthin))"
    if !inlist("`ubound'",".","") ///
        local yl "`yl' yline(`ubound', lpattern(dash) lcolor(red) lwidth(medthin))"

    twoway (line `depvar' `timevar' if `touse', lcolor(navy) lwidth(medthin)), ///
        `yl' ///
        title("Bounded series", size(medium)) ///
        subtitle("dashed red = bounds", size(small)) ///
        ytitle("`depvar'") xtitle("`timevar'") ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`gname'_series, replace) nodraw

    * dot chart: statistic vs 5% critical value across the 6 configurations
    preserve
    qui {
        clear
        set obs 6
        gen cfg = _n
        gen msb  = .
        gen mza  = .
        gen mzt  = .
        gen cvmsb = .
        gen cvmza = .
        gen cvmzt = .
        forvalues r = 1/6 {
            replace msb   = __bmt_sta[`r',1]    in `r'
            replace mza   = __bmt_sta[`r',2]    in `r'
            replace mzt   = __bmt_sta[`r',3]    in `r'
            replace cvmsb = __bmt_cv_msb[`r',3] in `r'
            replace cvmza = __bmt_cv_mza[`r',3] in `r'
            replace cvmzt = __bmt_cv_mzt[`r',3] in `r'
        }
        label define __bmtc 1 "OLS/SAR" 2 "OLS/QS" 3 "ERS/SAR" 4 "ERS/QS" ///
            5 "BND/SAR" 6 "BND/QS", replace
        label values cfg __bmtc
    }
    twoway (scatter mzt cfg, mcolor(navy) msymbol(circle)) ///
           (scatter cvmzt cfg, mcolor(red) msymbol(diamond)), ///
        legend(order(1 "MZt statistic" 2 "5% simulated CV") rows(1) size(small)) ///
        title("MZt vs bound-specific critical value", size(medium)) ///
        xlabel(1(1)6, valuelabel angle(45) labsize(small)) ///
        xtitle("") ytitle("MZt") ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(`gname'_cv, replace) nodraw
    restore

    capture graph combine `gname'_series `gname'_cv, ///
        title("boundeduroot mtests: Carrion-i-Silvestre & Gadea (2013)", size(medsmall)) ///
        note("Below its CV the statistic rejects the bounded unit-root null.", size(vsmall)) ///
        graphregion(color(white)) name(`gname', replace)
    if _rc {
        capture graph display `gname'_series
    }
end


*==============================================================================
*                       M A T A   E N G I N E   (_bmt_*)
*==============================================================================
version 14.0
mata:

// ---------------------------------------------------------------------------
// Skorohod folding of a path into [binf, bsup]  (rbm.m)
// A missing bound (.) disables that side.
// ---------------------------------------------------------------------------
real colvector _bmt_rbm(real colvector x0, real scalar binf, real scalar bsup)
{
    real colvector x
    real scalar it, bad
    x  = x0
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

// ---------------------------------------------------------------------------
// GLS (quasi-difference) demeaning with noncentrality cbar  (det_gls)
// ---------------------------------------------------------------------------
real colvector _bmt_detgls(real colvector y, real scalar cbar)
{
    real scalar nt, abar, bhat
    real colvector ya, za, z
    nt   = rows(y)
    z    = J(nt,1,1)
    abar = 1 + cbar/nt
    ya   = y
    za   = z
    ya[|2 \ nt|] = y[|2 \ nt|] :- abar*y[|1 \ nt-1|]
    za[|2 \ nt|] = z[|2 \ nt|] :- abar*z[|1 \ nt-1|]
    bhat = quadcross(za,ya)/quadcross(za,za)
    return(y :- z*bhat)
}

// ---------------------------------------------------------------------------
// Ng-Perron MAIC lag selection on a detrended series (s2ar)
// ---------------------------------------------------------------------------
real scalar _bmt_maic(real colvector d, real scalar kmax)
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

// ---------------------------------------------------------------------------
// AR spectral long-run variance from ADF regression with k lags (adfp)
// on an already-detrended series; s2vec = s2e/(1-sum b)^2.
// ---------------------------------------------------------------------------
real scalar _bmt_sar(real colvector d, real scalar k)
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

// ---------------------------------------------------------------------------
// Parametric long-run variance (estima_lrv_ar):
//   detm==0 : OLS demeaning (Perron-Qu 2007)
//   detm==1 : GLS demeaning at cbar (Ng-Perron 2001)
// ---------------------------------------------------------------------------
real scalar _bmt_lrv_ar(real colvector y, real scalar cbar, real scalar detm,
    real scalar kmax)
{
    real colvector d
    real scalar kopt
    if (detm == 0) {
        d = y :- mean(y)
    }
    else {
        d = _bmt_detgls(y, cbar)
    }
    kopt = _bmt_maic(d, kmax)
    return(_bmt_sar(d, kopt))
}

// ---------------------------------------------------------------------------
// Nonparametric long-run variance (estima_lrv_np), QS kernel with the
// Newey-West (1994) automatic bandwidth.
// ---------------------------------------------------------------------------
real scalar _bmt_lrv_np(real colvector y, real scalar cbar, real scalar detm)
{
    real colvector d, dy, res, acov
    real scalar T, nr, beta, n, j, s0, s2w, gam, mbw, xx, kw, lrv
    T = rows(y)
    if (detm == 0) {
        d = y :- mean(y)
    }
    else {
        d = _bmt_detgls(y, cbar)
    }
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

// ---------------------------------------------------------------------------
// Bilinear interpolation of kappa(c_low, c_up) on the CSG (2013) grid
// (read_values_kappa, 417 points). Values clamped to the grid hull.
// ---------------------------------------------------------------------------
real matrix _bmt_kappa_table()
{
    string scalar kstr
    real colvector v
    real matrix K
    real scalar i
    kstr = ""
    kstr = kstr + "-1.0500 0 -7.2188 -1.0500 0.1000 -8.5000 -1.0500 0.1500 -11.0625 -1.0500 0.2000 -15.3750 -1.0500 0.2500 -16.5625 -1.0500 0.3000 -14.4160 -1.0500 0.3500 -12.3395 -1.0500 0.4000 -10.5712 "
    kstr = kstr + "-1.0500 0.4500 -9.4609 -1.0500 0.5000 -8.6716 -1.0500 0.5500 -8.0278 -1.0500 0.6000 -7.6946 -1.0500 0.6500 -7.4791 -1.0500 0.7000 -7.3560 -1.0500 0.7500 -7.2637 -1.0500 0.8000 -7.2175 "
    kstr = kstr + "-1.0500 0.8500 -7.2175 -1.0500 0.9000 -7.2175 -1.0500 0.9500 -7.2175 -1.0500 1.0000 -7.2175 -1.0500 1.0500 -7.2175 -1.0000 0 -7.2175 -1.0000 0.1000 -8.4983 -1.0000 0.1500 -11.0608 "
    kstr = kstr + "-1.0000 0.2000 -15.3733 -1.0000 0.2500 -16.5921 -1.0000 0.3000 -14.4154 -1.0000 0.3500 -12.3493 -1.0000 0.4000 -10.5581 -1.0000 0.4500 -9.4623 -1.0000 0.5000 -8.6589 -1.0000 0.5500 -8.0283 "
    kstr = kstr + "-1.0000 0.6000 -7.6859 -1.0000 0.6500 -7.4804 -1.0000 0.7000 -7.3588 -1.0000 0.7500 -7.2511 -1.0000 0.8000 -7.2242 -1.0000 0.8500 -7.2126 -1.0000 0.9000 -7.2126 -1.0000 0.9500 -7.2126 "
    kstr = kstr + "-1.0000 1.0000 -7.2126 -1.0000 1.0500 -7.2126 -0.9500 0 -7.2126 -0.9500 0.1000 -8.5016 -0.9500 0.1500 -11.0328 -0.9500 0.2000 -15.4078 -0.9500 0.2500 -16.5953 -0.9500 0.3000 -14.4215 "
    kstr = kstr + "-0.9500 0.3500 -12.3303 -0.9500 0.4000 -10.5633 -0.9500 0.4500 -9.4622 -0.9500 0.5000 -8.6635 -0.9500 0.5500 -8.0327 -0.9500 0.6000 -7.6904 -0.9500 0.6500 -7.4849 -0.9500 0.7000 -7.3479 "
    kstr = kstr + "-0.9500 0.7500 -7.2554 -0.9500 0.8000 -7.2094 -0.9500 0.8500 -7.2094 -0.9500 0.9000 -7.2094 -0.9500 0.9500 -7.2094 -0.9500 1.0000 -7.2094 -0.9500 1.0500 -7.2094 -0.9000 0 -7.2094 "
    kstr = kstr + "-0.9000 0.1000 -8.5058 -0.9000 0.1500 -11.0371 -0.9000 0.2000 -15.4121 -0.9000 0.2500 -16.5996 -0.9000 0.3000 -14.4258 -0.9000 0.3500 -12.3346 -0.9000 0.4000 -10.5675 -0.9000 0.4500 -9.4573 "
    kstr = kstr + "-0.9000 0.5000 -8.6680 -0.9000 0.5500 -8.0317 -0.9000 0.6000 -7.6908 -0.9000 0.6500 -7.4848 -0.9000 0.7000 -7.3478 -0.9000 0.7500 -7.2553 -0.9000 0.8000 -7.2094 -0.9000 0.8500 -7.2094 "
    kstr = kstr + "-0.9000 0.9000 -7.2094 -0.9000 0.9500 -7.2094 -0.9000 1.0000 -7.2094 -0.9000 1.0500 -7.2094 -0.8500 0 -7.2094 -0.8500 0.1000 -8.5058 -0.8500 0.1500 -11.0370 -0.8500 0.2000 -15.4120 "
    kstr = kstr + "-0.8500 0.2500 -16.5995 -0.8500 0.3000 -14.4257 -0.8500 0.3500 -12.3345 -0.8500 0.4000 -10.5675 -0.8500 0.4500 -9.4572 -0.8500 0.5000 -8.6679 -0.8500 0.5500 -8.0316 -0.8500 0.6000 -7.6907 "
    kstr = kstr + "-0.8500 0.6500 -7.4848 -0.8500 0.7000 -7.3477 -0.8500 0.7500 -7.2553 -0.8500 0.8000 -7.2093 -0.8500 0.8500 -7.2093 -0.8500 0.9000 -7.2093 -0.8500 0.9500 -7.2093 -0.8500 1.0000 -7.2093 "
    kstr = kstr + "-0.8500 1.0500 -7.2093 -0.8000 0 -7.2093 -0.8000 0.1000 -8.5057 -0.8000 0.1500 -11.0370 -0.8000 0.2000 -15.4120 -0.8000 0.2500 -16.5995 -0.8000 0.3000 -14.4256 -0.8000 0.3500 -12.3344 "
    kstr = kstr + "-0.8000 0.4000 -10.5674 -0.8000 0.4500 -9.4572 -0.8000 0.5000 -8.6679 -0.8000 0.5500 -8.0316 -0.8000 0.6000 -7.6907 -0.8000 0.6500 -7.4847 -0.8000 0.7000 -7.3477 -0.8000 0.7500 -7.2552 "
    kstr = kstr + "-0.8000 0.8000 -7.2092 -0.8000 0.8500 -7.2092 -0.8000 0.9000 -7.2092 -0.8000 0.9500 -7.2092 -0.8000 1.0000 -7.2092 -0.8000 1.0500 -7.2092 -0.7500 0 -7.2556 -0.7500 0.1000 -8.5056 "
    kstr = kstr + "-0.7500 0.1500 -11.0369 -0.7500 0.2000 -15.4119 -0.7500 0.2500 -16.5994 -0.7500 0.3000 -14.4256 -0.7500 0.3500 -12.3344 -0.7500 0.4000 -10.5674 -0.7500 0.4500 -9.4571 -0.7500 0.5000 -8.6678 "
    kstr = kstr + "-0.7500 0.5500 -8.0315 -0.7500 0.6000 -7.6906 -0.7500 0.6500 -7.4846 -0.7500 0.7000 -7.3630 -0.7500 0.7500 -7.2553 -0.7500 0.8000 -7.2553 -0.7500 0.8500 -7.2094 -0.7500 0.9000 -7.2094 "
    kstr = kstr + "-0.7500 0.9500 -7.2094 -0.7500 1.0000 -7.2094 -0.7500 1.0500 -7.2094 -0.7000 0 -7.3808 -0.7000 0.1000 -8.5058 -0.7000 0.1500 -11.0370 -0.7000 0.2000 -15.4120 -0.7000 0.2500 -16.5995 "
    kstr = kstr + "-0.7000 0.3000 -14.4257 -0.7000 0.3500 -12.3345 -0.7000 0.4000 -10.5675 -0.7000 0.4500 -9.4572 -0.7000 0.5000 -8.6680 -0.7000 0.5500 -8.0620 -0.7000 0.6000 -7.7286 -0.7000 0.6500 -7.5212 "
    kstr = kstr + "-0.7000 0.7000 -7.3706 -0.7000 0.7500 -7.3099 -0.7000 0.8000 -7.2346 -0.7000 0.8500 -7.2346 -0.7000 0.9000 -7.2346 -0.7000 0.9500 -7.2346 -0.7000 1.0000 -7.2346 -0.7000 1.0500 -7.2346 "
    kstr = kstr + "-0.6500 0 -7.6711 -0.6500 0.1000 -8.5305 -0.6500 0.1500 -11.0617 -0.6500 0.2000 -15.3742 -0.6500 0.2500 -16.5617 -0.6500 0.3000 -14.4152 -0.6500 0.3500 -12.3387 -0.6500 0.4000 -10.5704 "
    kstr = kstr + "-0.6500 0.4500 -9.4785 -0.6500 0.5000 -8.7239 -0.6500 0.5500 -8.1484 -0.6500 0.6000 -7.8333 -0.6500 0.6500 -7.6670 -0.6500 0.7000 -7.5288 -0.6500 0.7500 -7.4826 -0.6500 0.8000 -7.4518 "
    kstr = kstr + "-0.6500 0.8500 -7.4441 -0.6500 0.9000 -7.4441 -0.6500 0.9500 -7.4441 -0.6500 1.0000 -7.4441 -0.6500 1.0500 -7.4441 -0.6000 0 -8.0456 -0.6000 0.1000 -8.7331 -0.6000 0.1500 -11.0456 "
    kstr = kstr + "-0.6000 0.2000 -15.3893 -0.6000 0.2500 -16.5768 -0.6000 0.3000 -14.4079 -0.6000 0.3500 -12.3384 -0.6000 0.4000 -10.7014 -0.6000 0.4500 -9.5872 -0.6000 0.5000 -8.8638 -0.6000 0.5500 -8.3485 "
    kstr = kstr + "-0.6000 0.6000 -8.0456 -0.6000 0.6500 -7.8822 -0.6000 0.7000 -7.8060 -0.6000 0.7500 -7.7752 -0.6000 0.8000 -7.7752 -0.6000 0.8500 -7.7598 -0.6000 0.9000 -7.7598 -0.6000 0.9500 -7.7598 "
    kstr = kstr + "-0.6000 1.0000 -7.7598 -0.6000 1.0500 -7.7598 -0.5500 0 -8.6502 -0.5500 0.1000 -9.0877 -0.5500 0.1500 -11.2439 -0.5500 0.2000 -15.4627 -0.5500 0.2500 -16.5877 -0.5500 0.3000 -14.4598 "
    kstr = kstr + "-0.5500 0.3500 -12.4291 -0.5500 0.4000 -10.7445 -0.5500 0.4500 -9.8055 -0.5500 0.5000 -9.1283 -0.5500 0.5500 -8.6439 -0.5500 0.6000 -8.4318 -0.5500 0.6500 -8.3125 -0.5500 0.7000 -8.2391 "
    kstr = kstr + "-0.5500 0.7500 -8.1936 -0.5500 0.8000 -8.1782 -0.5500 0.8500 -8.1782 -0.5500 0.9000 -8.1782 -0.5500 0.9500 -8.1782 -0.5500 1.0000 -8.1782 -0.5500 1.0500 -8.1782 -0.5000 0 -9.4436 "
    kstr = kstr + "-0.5000 0.1000 -9.5373 -0.5000 0.1500 -11.8811 -0.5000 0.2000 -15.6936 -0.5000 0.2500 -16.6311 -0.5000 0.3000 -14.5031 -0.5000 0.3500 -12.5417 -0.5000 0.4000 -11.0461 -0.5000 0.4500 -10.1076 "
    kstr = kstr + "-0.5000 0.5000 -9.4302 -0.5000 0.5500 -9.0369 -0.5000 0.6000 -8.8607 -0.5000 0.6500 -8.7467 -0.5000 0.7000 -8.7467 -0.5000 0.7500 -8.7171 -0.5000 0.8000 -8.7171 -0.5000 0.8500 -8.7171 "
    kstr = kstr + "-0.5000 0.9000 -8.7171 -0.5000 0.9500 -8.7171 -0.5000 1.0000 -8.7171 -0.5000 1.0500 -8.7171 -0.4500 0 -10.5904 -0.4500 0.1000 -10.4078 -0.4500 0.1500 -12.8131 -0.4500 0.2000 -16.8756 "
    kstr = kstr + "-0.4500 0.2500 -16.9693 -0.4500 0.3000 -14.7579 -0.4500 0.3500 -12.9347 -0.4500 0.4000 -11.4871 -0.4500 0.4500 -10.6041 -0.4500 0.5000 -10.1008 -0.4500 0.5500 -9.7504 -0.4500 0.6000 -9.6619 "
    kstr = kstr + "-0.4500 0.6500 -9.6174 -0.4500 0.7000 -9.5714 -0.4500 0.7500 -9.5560 -0.4500 0.8000 -9.5099 -0.4500 0.8500 -9.5099 -0.4500 0.9000 -9.5099 -0.4500 0.9500 -9.5099 -0.4500 1.0000 -9.5099 "
    kstr = kstr + "-0.4500 1.0500 -9.5099 -0.4000 0 -12.2594 -0.4000 0.1000 -11.6227 -0.4000 0.1500 -14.4313 -0.4000 0.2000 -18.4000 -0.4000 0.2500 -17.6725 -0.4000 0.3000 -15.3953 -0.4000 0.3500 -13.5595 "
    kstr = kstr + "-0.4000 0.4000 -12.2651 -0.4000 0.4500 -11.4767 -0.4000 0.5000 -11.0677 -0.4000 0.5500 -10.8063 -0.4000 0.6000 -10.7601 -0.4000 0.6500 -10.7140 -0.4000 0.7000 -10.6986 -0.4000 0.7500 -10.6986 "
    kstr = kstr + "-0.4000 0.8000 -10.6986 -0.4000 0.8500 -10.6986 -0.4000 0.9000 -10.6986 -0.4000 0.9500 -10.6986 -0.4000 1.0000 -10.6986 -0.4000 1.0500 -10.6986 -0.3500 0 -14.5265 -0.3500 0.1000 -13.7023 "
    kstr = kstr + "-0.3500 0.1500 -17.0421 -0.3500 0.2000 -20.6359 -0.3500 0.2500 -18.8292 -0.3500 0.3000 -16.5165 -0.3500 0.3500 -14.5341 -0.3500 0.4000 -13.3634 -0.3500 0.4500 -12.7256 -0.3500 0.5000 -12.3300 "
    kstr = kstr + "-0.3500 0.5500 -12.1865 -0.3500 0.6000 -12.0963 -0.3500 0.6500 -12.0963 -0.3500 0.7000 -12.0660 -0.3500 0.7500 -12.0660 -0.3500 0.8000 -12.0660 -0.3500 0.8500 -12.0660 -0.3500 0.9000 -12.0660 "
    kstr = kstr + "-0.3500 0.9500 -12.0660 -0.3500 1.0000 -12.0660 -0.3500 1.0500 -12.0660 -0.3000 0 -17.9401 -0.3000 0.1000 -16.7467 -0.3000 0.1500 -21.6862 -0.3000 0.2000 -23.3112 -0.3000 0.2500 -20.8072 "
    kstr = kstr + "-0.3000 0.3000 -17.9358 -0.3000 0.3500 -16.2863 -0.3000 0.4000 -15.2209 -0.3000 0.4500 -14.6005 -0.3000 0.5000 -14.2680 -0.3000 0.5500 -14.2376 -0.3000 0.6000 -14.2376 -0.3000 0.6500 -14.2376 "
    kstr = kstr + "-0.3000 0.7000 -14.2376 -0.3000 0.7500 -14.2376 -0.3000 0.8000 -14.2376 -0.3000 0.8500 -14.2376 -0.3000 0.9000 -14.2376 -0.3000 0.9500 -14.2376 -0.3000 1.0000 -14.2376 -0.3000 1.0500 -14.2376 "
    kstr = kstr + "-0.2500 0 -23.2055 -0.2500 0.1000 -22.1723 -0.2500 0.1500 -28.4555 -0.2500 0.2000 -27.5023 -0.2500 0.2500 -23.1836 -0.2500 0.3000 -20.5154 -0.2500 0.3500 -18.8388 -0.2500 0.4000 -17.7081 "
    kstr = kstr + "-0.2500 0.4500 -17.0341 -0.2500 0.5000 -16.8697 -0.2500 0.5500 -16.7255 -0.2500 0.6000 -16.7107 -0.2500 0.6500 -16.7107 -0.2500 0.7000 -16.7107 -0.2500 0.7500 -16.7107 -0.2500 0.8000 -16.7107 "
    kstr = kstr + "-0.2500 0.8500 -16.7107 -0.2500 0.9000 -16.7107 -0.2500 0.9500 -16.7107 -0.2500 1.0000 -16.7107 -0.2500 1.0500 -16.7107 -0.2000 0 -32.4755 -0.2000 0.1000 -32.6005 -0.2000 0.1500 -38.4755 "
    kstr = kstr + "-0.2000 0.2000 -32.4616 -0.2000 0.2500 -27.3497 -0.2000 0.3000 -23.4455 -0.2000 0.3500 -20.4055 -0.2000 0.4000 -18.2375 -0.2000 0.4500 -16.6459 -0.2000 0.5000 -15.9442 -0.2000 0.5500 -15.5319 "
    kstr = kstr + "-0.2000 0.6000 -15.4731 -0.2000 0.6500 -15.4731 -0.2000 0.7000 -15.4731 -0.2000 0.7500 -15.4731 -0.2000 0.8000 -15.4731 -0.2000 0.8500 -15.4731 -0.2000 0.9000 -15.4731 -0.2000 0.9500 -15.4731 "
    kstr = kstr + "-0.2000 1.0000 -15.4731 -0.2000 1.0500 -15.4731 -0.1500 0 -51.2194 -0.1500 0.1000 -55.9069 -0.1500 0.1500 -51.2265 -0.1500 0.2000 -38.2680 -0.1500 0.2500 -28.3652 -0.1500 0.3000 -21.4902 "
    kstr = kstr + "-0.1500 0.3500 -17.2152 -0.1500 0.4000 -14.7971 -0.1500 0.4500 -12.8630 -0.1500 0.5000 -12.0242 -0.1500 0.5500 -11.4961 -0.1500 0.6000 -11.2067 -0.1500 0.6500 -11.0883 -0.1500 0.7000 -11.0883 "
    kstr = kstr + "-0.1500 0.7500 -11.0883 -0.1500 0.8000 -11.0883 -0.1500 0.8500 -11.0883 -0.1500 0.9000 -11.0883 -0.1500 0.9500 -11.0883 -0.1500 1.0000 -11.0883 -0.1500 1.0500 -11.0883 -0.1000 0 -99.5817 "
    kstr = kstr + "-0.1000 0.1000 -99.5817 -0.1000 0.1500 -55.4845 -0.1000 0.2000 -31.9151 -0.1000 0.2500 -22.0123 -0.1000 0.3000 -16.4706 -0.1000 0.3500 -13.5372 -0.1000 0.4000 -11.6924 -0.1000 0.4500 -10.5616 "
    kstr = kstr + "-0.1000 0.5000 -9.4556 -0.1000 0.5500 -8.8475 -0.1000 0.6000 -8.6355 -0.1000 0.6500 -8.4868 -0.1000 0.7000 -8.4423 -0.1000 0.7500 -8.3655 -0.1000 0.8000 -8.3348 -0.1000 0.8500 -8.3348 "
    kstr = kstr + "-0.1000 0.9000 -8.3348 "
    v = strtoreal(tokens(kstr))'
    K = J(rows(v)/3, 3, .)
    for (i=1; i<=rows(K); i++) {
        K[i,1] = v[3*i-2]
        K[i,2] = v[3*i-1]
        K[i,3] = v[3*i]
    }
    return(K)
}

real scalar _bmt_kappa(real scalar cinf0, real scalar csup0)
{
    real matrix K
    real colvector clg, cug
    real scalar cinf, csup, il, iu, i, w1, w2
    real scalar k11, k12, k21, k22, kl, kh
    K = _bmt_kappa_table()
    // grids: c_low ascending -1.05..-0.10 step .05; c_up {0,.10,.15,...,1.05}
    clg = range(-1.05, -0.10, 0.05)
    cug = 0 \ range(0.10, 1.05, 0.05)
    cinf = cinf0
    csup = csup0
    if (cinf >= .) cinf = -1.05
    if (csup >= .) csup = 1.05
    if (cinf < -1.05) cinf = -1.05
    if (cinf > -0.10) cinf = -0.10
    if (csup <  0.00) csup = 0.00
    if (csup >  1.05) csup = 1.05
    il = 1
    for (i=1; i<=rows(clg)-1; i++) {
        if (cinf >= clg[i]) il = i
    }
    iu = 1
    for (i=1; i<=rows(cug)-1; i++) {
        if (csup >= cug[i]) iu = i
    }
    k11 = _bmt_klook(K, clg[il],   cug[iu])
    k12 = _bmt_klook(K, clg[il],   cug[iu+1])
    k21 = _bmt_klook(K, clg[il+1], cug[iu])
    k22 = _bmt_klook(K, clg[il+1], cug[iu+1])
    w1 = 0
    if (clg[il+1] > clg[il]) w1 = (cinf - clg[il])/(clg[il+1] - clg[il])
    w2 = 0
    if (cug[iu+1] > cug[iu]) w2 = (csup - cug[iu])/(cug[iu+1] - cug[iu])
    kl = k11 + w2*(k12 - k11)
    kh = k21 + w2*(k22 - k21)
    return(kl + w1*(kh - kl))
}

real scalar _bmt_klook(real matrix K, real scalar cl, real scalar cu)
{
    real scalar i, best, bestd, d
    best  = .
    bestd = .
    for (i=1; i<=rows(K); i++) {
        if (abs(K[i,1]-cl) < 1e-6) {
            d = abs(K[i,2]-cu)
            if (d < bestd | bestd >= .) {
                bestd = d
                best  = K[i,3]
            }
        }
    }
    return(best)
}

// ---------------------------------------------------------------------------
// M statistics (2013 convention: no X0^2 term in the MZa numerator)
// returns (MSB, MZa, MZt)
// ---------------------------------------------------------------------------
real rowvector _bmt_mstats(real colvector d, real scalar lrv)
{
    real scalar T, ss, msb, mza
    T   = rows(d)
    ss  = quadcross(d[|1 \ T-1|], d[|1 \ T-1|])
    msb = sqrt(ss/(lrv*T^2))
    mza = (d[T]^2/T - lrv)/(2*ss/T^2)
    return((msb, mza, mza*msb))
}

real scalar _bmt_quantile(real colvector x, real scalar p)
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

// ---------------------------------------------------------------------------
// Driver
// ---------------------------------------------------------------------------
void _bmt_run(string scalar yvar, string scalar touse, string scalar tvar)
{
    real matrix X, STA, CVM, CVA, CVT, C
    real colvector y, d, x, ysim, dsim
    real rowvector mm, kapcfg, detcfg, npcfg
    real scalar T, kmax, iter, lb, ub, x0, i, j, c
    real scalar lrv, lrv0, cinf0, csup0, kap0, kap_ar, kap_np, kk
    real scalar cinf, csup, lsim
    real matrix S
    string scalar rs

    lb   = strtoreal(st_local("lbval"))
    ub   = strtoreal(st_local("ubval"))
    kmax = strtoreal(st_local("maxlag"))
    iter = strtoreal(st_local("iter"))

    X  = st_data(., (yvar, tvar), touse)
    X  = sort(X, 2)
    y  = X[.,1]
    T  = rows(y)
    x0 = y[1]

    STA = J(6,3,.)
    C   = J(6,2,.)
    CVM = J(6,4,.)
    CVA = J(6,4,.)
    CVT = J(6,4,.)

    // ------- observed statistics, config by config (estima_M_tests_bounded)
    // 1: OLS + SAR
    d   = y :- mean(y)
    lrv = _bmt_lrv_ar(y, ., 0, kmax)
    STA[1,.] = _bmt_mstats(d, lrv)
    C[1,1] = _bmt_cpar(lb, x0, lrv, T)
    C[1,2] = _bmt_cpar(ub, x0, lrv, T)
    // 2: OLS + NP
    lrv = _bmt_lrv_np(y, ., 0)
    STA[2,.] = _bmt_mstats(d, lrv)
    C[2,1] = _bmt_cpar(lb, x0, lrv, T)
    C[2,2] = _bmt_cpar(ub, x0, lrv, T)
    // 3: GLS-ERS + SAR
    d   = _bmt_detgls(y, -7)
    lrv = _bmt_lrv_ar(y, -7, 1, kmax)
    STA[3,.] = _bmt_mstats(d, lrv)
    C[3,1] = _bmt_cpar(lb, x0, lrv, T)
    C[3,2] = _bmt_cpar(ub, x0, lrv, T)
    // 4: GLS-ERS + NP
    lrv = _bmt_lrv_np(y, -7, 1)
    STA[4,.] = _bmt_mstats(d, lrv)
    C[4,1] = _bmt_cpar(lb, x0, lrv, T)
    C[4,2] = _bmt_cpar(ub, x0, lrv, T)
    // 5: GLS-BOUNDS + SAR (two-stage kappa, stats use stage-1 lrv)
    lrv0  = _bmt_lrv_ar(y, ., 0, kmax)
    cinf0 = _bmt_cpar(lb, x0, lrv0, T)
    csup0 = _bmt_cpar(ub, x0, lrv0, T)
    kap0  = _bmt_kappa(cinf0, csup0)
    lrv   = _bmt_lrv_ar(y, kap0, 1, kmax)
    C[5,1] = _bmt_cpar(lb, x0, lrv, T)
    C[5,2] = _bmt_cpar(ub, x0, lrv, T)
    kap_ar = _bmt_kappa(C[5,1], C[5,2])
    d = _bmt_detgls(y, kap_ar)
    STA[5,.] = _bmt_mstats(d, lrv)
    // 6: GLS-BOUNDS + NP
    lrv0  = _bmt_lrv_np(y, ., 0)
    cinf0 = _bmt_cpar(lb, x0, lrv0, T)
    csup0 = _bmt_cpar(ub, x0, lrv0, T)
    kap0  = _bmt_kappa(cinf0, csup0)
    lrv   = _bmt_lrv_np(y, kap0, 1)
    C[6,1] = _bmt_cpar(lb, x0, lrv, T)
    C[6,2] = _bmt_cpar(ub, x0, lrv, T)
    kap_np = _bmt_kappa(C[6,1], C[6,2])
    d = _bmt_detgls(y, kap_np)
    STA[6,.] = _bmt_mstats(d, lrv)

    // ------- simulated critical values (cv_M_tests_bounded) ----------------
    // config -> (detrending kappa or OLS, parametric/np)
    detcfg = (0, 0, 1, 1, 1, 1)          // 0 OLS, 1 GLS
    kapcfg = (., ., -7, -7, _bmt_kappa(C[5,1],C[5,2]), _bmt_kappa(C[6,1],C[6,2]))
    npcfg  = (0, 1, 0, 1, 0, 1)          // 0 SAR, 1 NP

    rs = rseed()
    for (c=1; c<=6; c++) {
        rseed(rs)                         // common random-walk bank across configs
        cinf = C[c,1]
        csup = C[c,2]
        S = J(iter,3,.)
        for (j=1; j<=iter; j++) {
            x = J(T,1,0)
            x[|2 \ T|] = rnormal(T-1,1,0,1)
            x = quadrunningsum(x)
            ysim = _bmt_rbm(x, _bmt_scb(cinf,T), _bmt_scb(csup,T))
            if (detcfg[c] == 0) {
                dsim = ysim :- mean(ysim)
            }
            else {
                dsim = _bmt_detgls(ysim, kapcfg[c])
            }
            if (npcfg[c] == 0) {
                lsim = _bmt_lrv_ar(ysim, kapcfg[c], detcfg[c], kmax)
            }
            else {
                lsim = _bmt_lrv_np(ysim, kapcfg[c], detcfg[c])
            }
            S[j,.] = _bmt_mstats(dsim, lsim)
        }
        CVM[c,.] = (_bmt_quantile(S[.,1],.01), _bmt_quantile(S[.,1],.025),
                    _bmt_quantile(S[.,1],.05), _bmt_quantile(S[.,1],.10))
        CVA[c,.] = (_bmt_quantile(S[.,2],.01), _bmt_quantile(S[.,2],.025),
                    _bmt_quantile(S[.,2],.05), _bmt_quantile(S[.,2],.10))
        CVT[c,.] = (_bmt_quantile(S[.,3],.01), _bmt_quantile(S[.,3],.025),
                    _bmt_quantile(S[.,3],.05), _bmt_quantile(S[.,3],.10))
    }

    st_matrix("__bmt_sta", STA)
    st_matrix("__bmt_cv_msb", CVM)
    st_matrix("__bmt_cv_mza", CVA)
    st_matrix("__bmt_cv_mzt", CVT)
    st_matrix("__bmt_c", C)
    st_numscalar("__bmt_kap_ar", kap_ar)
    st_numscalar("__bmt_kap_np", kap_np)
    st_numscalar("__bmt_x0", x0)
}

// bound parameter c = (b - X0)/sqrt(lrv*T); missing bound stays missing
real scalar _bmt_cpar(real scalar b, real scalar x0, real scalar lrv,
    real scalar T)
{
    if (b >= .) return(.)
    return((b - x0)/sqrt(lrv*T))
}

// scaled bound c*sqrt(T); missing stays missing (disables folding side)
real scalar _bmt_scb(real scalar cv, real scalar T)
{
    if (cv >= .) return(.)
    return(cv*sqrt(T))
}

end
