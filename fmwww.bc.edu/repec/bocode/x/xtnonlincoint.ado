*! xtnonlincoint 1.0.0  21jun2026
*! Nonlinear panel cointegration tests with structural breaks and CSD
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! github.com/merwanroudane
*!
*! Subcommands
*!   ecm   : Nonlinear error-correction-based panel cointegration test
*!           Omay, Emirmahmutoglu & Denaux (2017, Economics Letters 157, 1-4)
*!           <doi:10.1016/j.econlet.2017.05.017>
*!   fffff : Fractional Frequency Flexible Fourier Form panel cointegration test
*!           Olayeni, Tiwari & Wohar (2021, Applied Economics Letters 28, 482-486)
*!           <doi:10.1080/13504851.2020.1761526>
*!   all   : run both tests on the same model

program define xtnonlincoint, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    if ("`sub'"=="") {
        di as error "specify a subcommand: {bf:ecm}, {bf:fffff} or {bf:all}"
        di as error "see {bf:help xtnonlincoint}"
        exit 198
    }
    if ("`sub'"=="ecm") {
        xtnonlincoint_ecm `0'
    }
    else if ("`sub'"=="fffff") {
        xtnonlincoint_fffff `0'
    }
    else if ("`sub'"=="all") {
        xtnonlincoint_all `0'
    }
    else {
        di as error "unknown subcommand {bf:`sub'}"
        di as error "valid subcommands are {bf:ecm}, {bf:fffff}, {bf:all}"
        exit 198
    }
    return add
end

*-----------------------------------------------------------------------------
* ECM : nonlinear error-correction based panel cointegration test (Omay 2017)
*-----------------------------------------------------------------------------
program define xtnonlincoint_ecm, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,        ///
        Lags(integer 1)                                   ///
        VARlags(integer 1)                                ///
        Breps(integer 299)                                ///
        Seed(integer 12345)                               ///
        Level(cilevel)                                    ///
        TRend                                             ///
        GRaph                                             ///
        noPRINT ]

    gettoken dv xv : varlist
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data are not {bf:xtset}; run {bf:xtset panelvar timevar} first"
        exit 459
    }
    marksample touse
    markout `touse' `dv' `xv' `ivar' `tvar'
    local trd = ("`trend'"!="")

    if (`lags'<0)    local lags 0
    if (`varlags'<1) local varlags 1
    if (`breps'<19)  local breps 19

    mata: _xtnlc_ecm_driver("`dv'","`xv'","`ivar'","`tvar'","`touse'", ///
        `lags', `varlags', `breps', `seed', `trd')

    if (scalar(__bal)==0) {
        di as error "{bf:xtnonlincoint ecm} requires a balanced panel"
        di as error "(every panel must have the same number of time periods)"
        exit 459
    }

    matrix colnames __ind = panel tau pvalue cv10 cv5 cv1

    if ("`print'"=="") {
        _xtnlc_ecm_table, dv(`dv') xv(`xv') lags(`lags') varlags(`varlags') ///
            breps(`breps') level(`level') trend(`trd')
    }

    if ("`graph'"!="") {
        _xtnlc_ecm_graph, level(`level')
    }

    * ---- returns ----
    return scalar N        = scalar(__N)
    return scalar T        = scalar(__T)
    return scalar lags     = `lags'
    return scalar varlags  = `varlags'
    return scalar breps    = `breps'
    return scalar stat     = scalar(__gstat)
    return scalar p        = scalar(__pval)
    return scalar cv10     = scalar(__gcv10)
    return scalar cv5      = scalar(__gcv5)
    return scalar cv1      = scalar(__gcv1)
    return local  depvar   "`dv'"
    return local  indepvars "`xv'"
    return local  test     "Nonlinear ECM-based panel cointegration (Omay et al. 2017)"
    return local  cmd      "xtnonlincoint ecm"
    return matrix indstat  = __ind
    return matrix bootdist = __bdist

    capture scalar drop __bal __N __T __gstat __pval __gcv10 __gcv5 __gcv1
    capture matrix drop __ind __bdist
end

*-----------------------------------------------------------------------------
* FFFFF : fractional frequency flexible Fourier form test (Olayeni 2021)
*-----------------------------------------------------------------------------
program define xtnonlincoint_fffff, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,        ///
        MAXLags(integer 1)                                ///
        KStep(real 0.1)                                   ///
        Breps(integer 299)                                ///
        BLock(integer 0)                                  ///
        Seed(integer 12345)                               ///
        Level(cilevel)                                    ///
        TRend                                             ///
        SPSM                                              ///
        GRaph                                             ///
        noPRINT ]

    gettoken dv xv : varlist
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data are not {bf:xtset}; run {bf:xtset panelvar timevar} first"
        exit 459
    }
    marksample touse
    markout `touse' `dv' `xv' `ivar' `tvar'
    local trd = ("`trend'"!="")

    if (`maxlags'<0)  local maxlags 0
    if (`kstep'<=0)   local kstep 0.1
    if (`breps'<19)   local breps 19

    mata: _xtnlc_fffff_driver("`dv'","`xv'","`ivar'","`tvar'","`touse'", ///
        `maxlags', `kstep', `breps', `block', `seed', `trd')

    if (scalar(__bal)==0) {
        di as error "{bf:xtnonlincoint fffff} requires a balanced panel"
        di as error "(every panel must have the same number of time periods)"
        exit 459
    }

    matrix colnames __ind  = panel kss khat phat pvalue cv10 cv5 cv1
    matrix colnames __spsm = step gmstat pvalue minkss khat panel

    if ("`print'"=="") {
        _xtnlc_fffff_table, dv(`dv') xv(`xv') maxlags(`maxlags') ///
            breps(`breps') level(`level') trend(`trd') spsm(`=("`spsm'"!="")')
    }

    if ("`graph'"!="") {
        _xtnlc_fffff_graph, level(`level')
    }

    * ---- returns ----
    return scalar N        = scalar(__N)
    return scalar T        = scalar(__T)
    return scalar maxlags  = `maxlags'
    return scalar breps    = `breps'
    return scalar stat     = scalar(__gstat)
    return scalar p        = scalar(__pval)
    return scalar cv10     = scalar(__gcv10)
    return scalar cv5      = scalar(__gcv5)
    return scalar cv1      = scalar(__gcv1)
    return scalar nstat    = scalar(__nstat)
    return local  depvar   "`dv'"
    return local  indepvars "`xv'"
    return local  test     "FFFFF panel cointegration (Olayeni et al. 2021)"
    return local  cmd      "xtnonlincoint fffff"
    return matrix indstat  = __ind
    return matrix spsm     = __spsm
    return matrix bootdist = __bdist

    capture scalar drop __bal __N __T __gstat __pval __gcv10 __gcv5 __gcv1 __nstat
    capture matrix drop __ind __spsm __bdist
end

*-----------------------------------------------------------------------------
* ALL : run both tests
*-----------------------------------------------------------------------------
program define xtnonlincoint_all, rclass
    version 14.0
    syntax varlist(min=2 numeric) [if] [in] [,        ///
        Lags(integer 1)                                   ///
        VARlags(integer 1)                                ///
        MAXLags(integer 1)                                ///
        KStep(real 0.1)                                   ///
        Breps(integer 299)                                ///
        BLock(integer 0)                                  ///
        Seed(integer 12345)                               ///
        Level(cilevel)                                    ///
        TRend                                             ///
        SPSM                                              ///
        GRaph ]

    di as text _n "{hline 78}"
    di as text "{bf:[1/2]} Nonlinear ECM-based test"
    di as text "{hline 78}"
    xtnonlincoint_ecm `varlist' `if' `in', lags(`lags') varlags(`varlags') ///
        breps(`breps') seed(`seed') level(`level') `trend' `graph'
    local e_stat = r(stat)
    local e_p    = r(p)

    di as text _n "{hline 78}"
    di as text "{bf:[2/2]} FFFFF test"
    di as text "{hline 78}"
    xtnonlincoint_fffff `varlist' `if' `in', maxlags(`maxlags') kstep(`kstep') ///
        breps(`breps') block(`block') seed(`seed') level(`level') ///
        `trend' `spsm' `graph'

    return scalar ecm_stat   = `e_stat'
    return scalar ecm_p      = `e_p'
    return scalar fffff_stat = r(stat)
    return scalar fffff_p    = r(p)
    return local  cmd        "xtnonlincoint all"
end

*-----------------------------------------------------------------------------
* ECM results table
*-----------------------------------------------------------------------------
program define _xtnlc_ecm_table
    syntax , dv(string) xv(string) lags(int) varlags(int) breps(int) ///
        level(int) trend(int)

    local nr = rowsof(__ind)
    di as text _n "{hline 74}"
    di as text "Nonlinear ECM-based panel cointegration test"
    di as text "Omay, Emirmahmutoglu & Denaux (2017)"
    di as text "{hline 74}"
    di as text "Dependent variable : " as result "`dv'"
    di as text "Regressors         : " as result "`xv'"
    local dt "demeaned"
    if (`trend') local dt "detrended"
    di as text "Deterministics     : " as result "`dt'" ///
        as text "    ECM lags: " as result "`lags'" ///
        as text "    VAR lags: " as result "`varlags'"
    di as text "Bootstrap reps     : " as result "`breps'" ///
        as text " (sieve, cross-section dependent)"
    di as text "Panels (N)         : " as result %5.0f scalar(__N) ///
        as text "    Periods (T): " as result %5.0f scalar(__T)
    di as text "{hline 74}"
    di as text "H0: no cointegration in any panel"
    di as text "H1: nonlinear (LSTAR) error correction in some panel"
    di as text "{hline 74}"
    di as text %12s "Panel" "  " %10s "tau(c)" "  " %8s "p-value" ///
        "  " %8s "cv10%" "  " %8s "cv5%" "  " %8s "cv1%"
    di as text "{hline 74}"
    forvalues i = 1/`nr' {
        local pid = __ind[`i',1]
        local ta  = __ind[`i',2]
        local pv  = __ind[`i',3]
        local c10 = __ind[`i',4]
        local c5  = __ind[`i',5]
        local c1  = __ind[`i',6]
        local st ""
        if (`pv'<0.10) local st "*"
        if (`pv'<0.05) local st "**"
        if (`pv'<0.01) local st "***"
        di as text %12.0g `pid' "  " as result %10.4f `ta' "`st'" ///
            _col(28) as result %8.3f `pv' "  " as text %8.3f `c10' ///
            "  " %8.3f `c5' "  " %8.3f `c1'
    }
    di as text "{hline 74}"
    local gs = scalar(__gstat)
    local gp = scalar(__pval)
    local gst ""
    if (`gp'<0.10) local gst "*"
    if (`gp'<0.05) local gst "**"
    if (`gp'<0.01) local gst "***"
    di as result %12s "Group mean" "  " as result %10.4f `gs' "`gst'" ///
        _col(28) as result %8.3f `gp' "  " as text %8.3f scalar(__gcv10) ///
        "  " %8.3f scalar(__gcv5) "  " %8.3f scalar(__gcv1)
    di as text "{hline 74}"
    di as text "Stars: * p<.10  ** p<.05  *** p<.01 (bootstrap, upper tail)."
    di as text "Reject H0 (=> cointegration) when tau(c) exceeds the critical value."
end

*-----------------------------------------------------------------------------
* FFFFF results table
*-----------------------------------------------------------------------------
program define _xtnlc_fffff_table
    syntax , dv(string) xv(string) maxlags(int) breps(int) level(int) ///
        trend(int) spsm(int)

    local nr = rowsof(__ind)
    di as text _n "{hline 78}"
    di as text "Fractional Frequency Flexible Fourier Form (FFFFF) cointegration test"
    di as text "Olayeni, Tiwari & Wohar (2021)"
    di as text "{hline 78}"
    di as text "Dependent variable : " as result "`dv'"
    di as text "Regressors         : " as result "`xv'"
    local dt "level (constant)"
    if (`trend') local dt "trend"
    di as text "Deterministics     : " as result "`dt'" ///
        as text "    Max lags: " as result "`maxlags'"
    di as text "Bootstrap reps     : " as result "`breps'" ///
        as text " (stationary, cross-section dependent)"
    di as text "Panels (N)         : " as result %5.0f scalar(__N) ///
        as text "    Periods (T): " as result %5.0f scalar(__T)
    di as text "{hline 78}"
    di as text "H0: no cointegration in any panel (residual has a unit root)"
    di as text "H1: nonlinear (KSS/ESTAR) cointegration with smooth Fourier breaks"
    di as text "{hline 78}"
    di as text %12s "Panel" "  " %9s "KSS" "  " %6s "k" "  " %5s "lag" ///
        "  " %8s "p-value" "  " %8s "cv10%" "  " %8s "cv5%"
    di as text "{hline 78}"
    forvalues i = 1/`nr' {
        local pid = __ind[`i',1]
        local ks  = __ind[`i',2]
        local kh  = __ind[`i',3]
        local ph  = __ind[`i',4]
        local pv  = __ind[`i',5]
        local c10 = __ind[`i',6]
        local c5  = __ind[`i',7]
        local st ""
        if (`pv'<0.10) local st "*"
        if (`pv'<0.05) local st "**"
        if (`pv'<0.01) local st "***"
        di as text %12.0g `pid' "  " as result %9.3f `ks' "`st'" ///
            _col(26) as result %6.1f `kh' "  " %5.0f `ph' ///
            "  " as result %8.3f `pv' "  " as text %8.3f `c10' "  " %8.3f `c5'
    }
    di as text "{hline 78}"
    local gs = scalar(__gstat)
    local gp = scalar(__pval)
    local gst ""
    if (`gp'<0.10) local gst "*"
    if (`gp'<0.05) local gst "**"
    if (`gp'<0.01) local gst "***"
    di as result %12s "Group mean" "  " as result %9.3f `gs' "`gst'" ///
        _col(40) as result %8.3f `gp' "  " as text %8.3f scalar(__gcv10) ///
        "  " %8.3f scalar(__gcv5)
    di as text "{hline 78}"
    di as text "Stars: * p<.10  ** p<.05  *** p<.01 (bootstrap, lower tail)."
    di as text "Reject H0 (=> cointegration) when KSS is below the critical value."

    if (`spsm') {
        local ns = rowsof(__spsm)
        di as text _n "{hline 64}"
        di as text "Sequential Panel Selection Method (SPSM)"
        di as text "{hline 64}"
        di as text %6s "Step" "  " %10s "group KSS" "  " %8s "p-value" ///
            "  " %9s "min KSS" "  " %6s "k" "  " %10s "panel"
        di as text "{hline 64}"
        forvalues i = 1/`ns' {
            local sp  = __spsm[`i',1]
            local gm  = __spsm[`i',2]
            local pv  = __spsm[`i',3]
            local mk  = __spsm[`i',4]
            local kh  = __spsm[`i',5]
            local pid = __spsm[`i',6]
            local st ""
            if (`pv'<0.10) local st "*"
            if (`pv'<0.05) local st "**"
            if (`pv'<0.01) local st "***"
            di as result %6.0f `sp' "  " %10.3f `gm' "  " %8.3f `pv' "`st'" ///
                _col(40) as result %9.3f `mk' "  " %6.1f `kh' "  " %10.0g `pid'
        }
        di as text "{hline 64}"
        di as text "Series removed (top rows, while significant) drive the"
        di as text "panel cointegration; later non-significant series do not."
    }
end

*-----------------------------------------------------------------------------
* ECM graph
*-----------------------------------------------------------------------------
program define _xtnlc_ecm_graph
    syntax , level(int)
    preserve
    clear
    qui svmat double __ind, names(col)
    qui gen long _ix = _n
    qui svmat double __bdist, name(bdist)
    local gs = scalar(__gstat)
    local gc = scalar(__gcv5)

    capture {
        twoway (bar tau _ix, barwidth(0.6) color(navy%70)) ///
               (connected cv5 _ix, lpattern(dash) lcolor(cranberry) ///
                    msymbol(none)), ///
            legend(order(1 "tau(c)" 2 "5% critical value") rows(1) size(small)) ///
            ytitle("MWALD statistic") xtitle("Panel index") ///
            title("Individual cointegration statistics", size(medium)) ///
            name(xtnlc_ecm_ind, replace) nodraw
    }
    capture {
        twoway (histogram bdist1, frequency color(navy%50)) , ///
            xline(`gs', lcolor(cranberry) lpattern(solid) lwidth(medthick)) ///
            xline(`gc', lcolor(forest_green) lpattern(dash)) ///
            xtitle("Bootstrap group-mean tau(c)") ytitle("Frequency") ///
            title("Bootstrap null distribution", size(medium)) ///
            note("Solid red = observed; dashed green = 5% critical value") ///
            name(xtnlc_ecm_boot, replace) nodraw
    }
    capture graph combine xtnlc_ecm_ind xtnlc_ecm_boot, ///
        title("Nonlinear ECM-based panel cointegration test", size(medium)) ///
        name(xtnlc_ecm, replace)
    if (_rc) {
        di as text "(graph could not be produced in this environment)"
    }
    restore
end

*-----------------------------------------------------------------------------
* FFFFF graph
*-----------------------------------------------------------------------------
program define _xtnlc_fffff_graph
    syntax , level(int)
    preserve
    clear
    qui svmat double __ind, names(col)
    qui gen long _ix = _n
    qui svmat double __spsm, name(sp)
    local gs = scalar(__gstat)

    capture {
        twoway (bar kss _ix, barwidth(0.6) color(maroon%70)) ///
               (connected cv5 _ix, lpattern(dash) lcolor(navy) msymbol(none)), ///
            legend(order(1 "KSS" 2 "5% critical value") rows(1) size(small)) ///
            ytitle("KSS statistic") xtitle("Panel index") ///
            title("Individual cointegration statistics", size(medium)) ///
            name(xtnlc_fffff_ind, replace) nodraw
    }
    capture {
        twoway (connected sp2 sp1, lcolor(navy) mcolor(navy)) , ///
            ytitle("Group-mean KSS") xtitle("SPSM step") ///
            title("Sequential panel selection", size(medium)) ///
            note("Series peeled off one per step (most stationary first)") ///
            name(xtnlc_fffff_spsm, replace) nodraw
    }
    capture graph combine xtnlc_fffff_ind xtnlc_fffff_spsm, ///
        title("FFFFF panel cointegration test", size(medium)) ///
        name(xtnlc_fffff, replace)
    if (_rc) {
        di as text "(graph could not be produced in this environment)"
    }
    restore
end

*=============================================================================
* Mata implementation
*=============================================================================
version 14.0
mata:

struct _xtnlc_pv {
    real matrix B
    real matrix W
    real matrix Z
    real colvector dnu
    real scalar khat
    real scalar phat
}

// ---- quantile (type-7 linear interpolation) ----
real scalar _xtnlc_quantile(real colvector x, real scalar pr)
{
    real colvector s
    real scalar n, h, fl
    n = rows(x)
    if (n==0) {
        return(.)
    }
    if (n==1) {
        return(x[1])
    }
    s = sort(x,1)
    h = pr*(n-1)+1
    fl = floor(h)
    if (fl<1) {
        fl = 1
    }
    if (fl>=n) {
        return(s[n])
    }
    return(s[fl] + (h-fl)*(s[fl+1]-s[fl]))
}

// ---- lag row builder: [M[s-1,], M[s-2,], ..., M[s-q,]] ----
real rowvector _xtnlc_lagrow(real matrix M, real scalar s, real scalar q)
{
    real rowvector out
    real scalar j
    out = M[s-1,]
    for (j=2; j<=q; j=j+1) {
        out = (out, M[s-j,])
    }
    return(out)
}

// ---- panel boundaries: returns N x 2 [start,end], requires sorted id ----
real matrix _xtnlc_bounds(real colvector ID)
{
    real colvector ids
    real matrix bnd
    real scalar N, i, a, n, cnt
    ids = uniqrows(ID)
    N = rows(ids)
    n = rows(ID)
    bnd = J(N, 2, 0)
    a = 1
    for (i=1; i<=N; i=i+1) {
        bnd[i,1] = a
        cnt = 0
        while (a<=n) {
            if (ID[a]!=ids[i]) {
                break
            }
            cnt = cnt + 1
            a = a + 1
        }
        bnd[i,2] = bnd[i,1] + cnt - 1
    }
    return(bnd)
}

// ======================= ECM (Omay et al. 2017) =======================

// MWALD tau(c) for one panel; returns . if not computable
real scalar _xtnlc_ecm_panel(real colvector y, real matrix X, real scalar p, ///
    real scalar trend)
{
    real scalar T, k, t0, m, i, tt, c, j, base, ncol
    real colvector u, dep, b, e, bb
    real matrix D, R, XtXi, V
    real scalar s2, r1, r2, v11, v22, v21, t1, t2, denom
    T = rows(y)
    k = cols(X)
    if (trend) {
        D = (J(T,1,1), range(1,T,1), X)
    }
    else {
        D = (J(T,1,1), X)
    }
    bb = invsym(quadcross(D,D))*quadcross(D,y)
    u = y - D*bb
    t0 = p + 2
    if (t0>T) {
        return(.)
    }
    m = T - t0 + 1
    ncol = 3 + k + p*(1+k)
    if (m<=ncol) {
        return(.)
    }
    R = J(m, ncol, 0)
    dep = J(m, 1, 0)
    for (i=1; i<=m; i=i+1) {
        tt = t0 + i - 1
        dep[i] = y[tt] - y[tt-1]
        R[i,1] = 1
        R[i,2] = u[tt-1]
        R[i,3] = u[tt-1]*u[tt-1]
        for (c=1; c<=k; c=c+1) {
            R[i,3+c] = X[tt,c] - X[tt-1,c]
        }
        base = 3 + k
        for (j=1; j<=p; j=j+1) {
            R[i,base+1] = y[tt-j] - y[tt-j-1]
            for (c=1; c<=k; c=c+1) {
                R[i,base+1+c] = X[tt-j,c] - X[tt-j-1,c]
            }
            base = base + 1 + k
        }
    }
    XtXi = invsym(quadcross(R,R))
    b = XtXi*quadcross(R,dep)
    e = dep - R*b
    s2 = quadcross(e,e)/(m-ncol)
    V = s2*XtXi
    r1 = b[2]
    r2 = b[3]
    v11 = V[2,2]
    v22 = V[3,3]
    v21 = V[3,2]
    if (v22<=0 | v11<=0) {
        return(.)
    }
    denom = v11 - v21*v21/v22
    if (denom<=0) {
        return(.)
    }
    t1 = (r1 - r2*v21/v22)
    t1 = t1*t1/denom
    t2 = 0
    if (r2<0) {
        t2 = r2*r2/v22
    }
    return(t1+t2)
}

// estimate VAR(q) on dz; fill Bmat (q*kk x kk) and centered residuals W (L x kk)
void _xtnlc_var(real matrix dz, real scalar q, real matrix Bmat, real matrix W)
{
    real scalar R, kk, s, L
    real matrix Xl, Yl
    R = rows(dz)
    kk = cols(dz)
    L = R - q
    if (L<1) {
        Bmat = J(q*kk, kk, 0)
        W = J(1, kk, 0)
        return
    }
    Xl = J(L, q*kk, 0)
    Yl = J(L, kk, 0)
    for (s=q+1; s<=R; s=s+1) {
        Xl[s-q,] = _xtnlc_lagrow(dz, s, q)
        Yl[s-q,] = dz[s,]
    }
    Bmat = invsym(quadcross(Xl,Xl))*quadcross(Xl,Yl)
    W = Yl - Xl*Bmat
    W = W :- mean(W)
}

// reconstruct z* (T x kk) from VAR coefficients and bootstrap innovations
real matrix _xtnlc_recon(real matrix Bmat, real matrix Wstar, real scalar q, ///
    real scalar T)
{
    real scalar R, kk, s
    real matrix dzs, zs
    real rowvector lr
    R = T - 1
    kk = cols(Wstar)
    dzs = J(R, kk, 0)
    for (s=q+1; s<=R; s=s+1) {
        lr = _xtnlc_lagrow(dzs, s, q)
        dzs[s,] = lr*Bmat + Wstar[s-q,]
    }
    zs = J(T, kk, 0)
    for (s=2; s<=T; s=s+1) {
        zs[s,] = zs[s-1,] + dzs[s-1,]
    }
    return(zs)
}

void _xtnlc_ecm_driver(string scalar dv, string scalar xv, string scalar idv, ///
    string scalar tvv, string scalar tousev, real scalar p, real scalar q, ///
    real scalar B, real scalar seed, real scalar trend)
{
    real colvector Y, ID, TT, ord, ids, tau, bdist, bdv, ip, c10, c5, c1
    real matrix X, bnd, BTAU, OUT
    real scalar N, i, b, T0, s, e, L, gstat
    real colvector yp, ys, idx, col, colf, rowv, rowf
    real matrix Xp, Xs, zp, dz, zs, Wst
    struct _xtnlc_pv colvector PV
    real matrix Bm, Wm

    Y  = st_data(., dv, tousev)
    X  = st_data(., tokens(xv), tousev)
    ID = st_data(., idv, tousev)
    TT = st_data(., tvv, tousev)
    ord = order((ID,TT), (1,2))
    Y = Y[ord]
    X = X[ord,]
    ID = ID[ord]
    TT = TT[ord]
    bnd = _xtnlc_bounds(ID)
    ids = uniqrows(ID)
    N = rows(bnd)

    // balanced check
    T0 = bnd[1,2] - bnd[1,1] + 1
    for (i=1; i<=N; i=i+1) {
        if ((bnd[i,2]-bnd[i,1]+1)!=T0) {
            st_numscalar("__bal", 0)
            return
        }
    }
    st_numscalar("__bal", 1)

    // observed statistics + per-panel VAR for bootstrap
    tau = J(N,1,.)
    PV = _xtnlc_pv(N)
    for (i=1; i<=N; i=i+1) {
        s = bnd[i,1]
        e = bnd[i,2]
        yp = Y[|s \ e|]
        Xp = X[|s,. \ e,.|]
        tau[i] = _xtnlc_ecm_panel(yp, Xp, p, trend)
        zp = (yp, Xp)
        dz = zp[|2,. \ rows(zp),.|] - zp[|1,. \ rows(zp)-1,.|]
        Bm = J(0,0,0)
        Wm = J(0,0,0)
        _xtnlc_var(dz, q, Bm, Wm)
        PV[i].B = Bm
        PV[i].W = Wm
    }
    bdv = select(tau, tau:<.)
    gstat = mean(bdv)

    // bootstrap
    L = rows(PV[1].W)
    BTAU = J(B, N, .)
    rseed(seed)
    for (b=1; b<=B; b=b+1) {
        idx = ceil(runiform(L,1):*L)
        idx = idx + (idx:<1)
        idx = idx - (idx:>L):*(idx:-L)
        for (i=1; i<=N; i=i+1) {
            Wst = (PV[i].W)[idx,]
            zs = _xtnlc_recon(PV[i].B, Wst, q, T0)
            ys = zs[,1]
            Xs = zs[|1,2 \ rows(zs),cols(zs)|]
            BTAU[b,i] = _xtnlc_ecm_panel(ys, Xs, p, trend)
        }
    }

    // bootstrap group distribution
    bdist = J(B,1,.)
    for (b=1; b<=B; b=b+1) {
        rowv = BTAU[b,]'
        rowf = select(rowv, rowv:<.)
        if (rows(rowf)>0) {
            bdist[b] = mean(rowf)
        }
    }
    bdv = select(bdist, bdist:<.)

    // individual p-values and critical values (upper tail)
    ip  = J(N,1,.)
    c10 = J(N,1,.)
    c5  = J(N,1,.)
    c1  = J(N,1,.)
    for (i=1; i<=N; i=i+1) {
        col = BTAU[,i]
        colf = select(col, col:<.)
        if (rows(colf)>0 & tau[i]<.) {
            ip[i] = mean(colf:>=tau[i])
            c10[i] = _xtnlc_quantile(colf, 0.90)
            c5[i]  = _xtnlc_quantile(colf, 0.95)
            c1[i]  = _xtnlc_quantile(colf, 0.99)
        }
    }

    OUT = (ids, tau, ip, c10, c5, c1)
    st_matrix("__ind", OUT)
    st_matrix("__bdist", bdv)
    st_numscalar("__N", N)
    st_numscalar("__T", T0)
    st_numscalar("__gstat", gstat)
    st_numscalar("__pval", mean(bdv:>=gstat))
    st_numscalar("__gcv10", _xtnlc_quantile(bdv,0.90))
    st_numscalar("__gcv5",  _xtnlc_quantile(bdv,0.95))
    st_numscalar("__gcv1",  _xtnlc_quantile(bdv,0.99))
}

// ======================= FFFFF (Olayeni et al. 2021) =======================

// stage-1 cointegrating-regression residual
real colvector _xtnlc_resid(real colvector y, real matrix Z, real scalar trend)
{
    real scalar T
    real matrix D
    real colvector b
    T = rows(y)
    if (trend) {
        D = (J(T,1,1), range(1,T,1), Z)
    }
    else {
        D = (J(T,1,1), Z)
    }
    b = invsym(quadcross(D,D))*quadcross(D,y)
    return(y - D*b)
}

// nonlinear ADF + Fourier fit; returns (t_gamma, ssr, m, ncol)
real rowvector _xtnlc_kss_fit(real colvector nu, real scalar k, real scalar p, ///
    real scalar trend)
{
    real scalar T, t0, m, i, tt, j, base, ncol, s2, gamma, segamma
    real colvector dep, b, e
    real matrix R, XtXi, V
    T = rows(nu)
    t0 = p + 2
    if (t0>T) {
        return((.,.,.,.))
    }
    m = T - t0 + 1
    ncol = 4 + p
    if (trend) {
        ncol = ncol + 1
    }
    if (m<=ncol) {
        return((.,.,.,.))
    }
    R = J(m, ncol, 0)
    dep = J(m, 1, 0)
    for (i=1; i<=m; i=i+1) {
        tt = t0 + i - 1
        dep[i] = nu[tt] - nu[tt-1]
        R[i,1] = 1
        R[i,2] = nu[tt-1]*nu[tt-1]*nu[tt-1]
        for (j=1; j<=p; j=j+1) {
            R[i,2+j] = nu[tt-j] - nu[tt-j-1]
        }
        base = 2 + p
        R[i,base+1] = sin(2*pi()*k*tt/T)
        R[i,base+2] = cos(2*pi()*k*tt/T)
        if (trend) {
            R[i,base+3] = tt
        }
    }
    XtXi = invsym(quadcross(R,R))
    b = XtXi*quadcross(R,dep)
    e = dep - R*b
    s2 = quadcross(e,e)/(m-ncol)
    V = s2*XtXi
    if (V[2,2]<=0) {
        return((.,.,.,.))
    }
    gamma = b[2]
    segamma = sqrt(V[2,2])
    return((gamma/segamma, quadcross(e,e), m, ncol))
}

// grid-search over (k,p); returns (t_gamma, khat, phat, aic)
real rowvector _xtnlc_kss_search(real colvector nu, real scalar pmax, ///
    real scalar trend, real colvector kgrid)
{
    real scalar ng, ik, p, aic, bestaic, bestt, bestk, bestp
    real rowvector fit
    ng = rows(kgrid)
    bestaic = .
    bestt = .
    bestk = .
    bestp = .
    for (ik=1; ik<=ng; ik=ik+1) {
        for (p=0; p<=pmax; p=p+1) {
            fit = _xtnlc_kss_fit(nu, kgrid[ik], p, trend)
            if (fit[2]<. & fit[3]>fit[4] & fit[2]>0) {
                aic = fit[3]*log(fit[2]/fit[3]) + 2*fit[4]
                if (bestaic==. | aic<bestaic) {
                    bestaic = aic
                    bestt = fit[1]
                    bestk = kgrid[ik]
                    bestp = p
                }
            }
        }
    }
    return((bestt, bestk, bestp, bestaic))
}

// stationary bootstrap index sequence (Politis-Romano)
real colvector _xtnlc_sb_index(real scalar L, real scalar meanbl)
{
    real colvector idx
    real scalar pr, t, cur
    idx = J(L,1,0)
    pr = 1/meanbl
    cur = ceil(runiform(1,1)*L)
    if (cur<1) {
        cur = 1
    }
    idx[1] = cur
    for (t=2; t<=L; t=t+1) {
        if (runiform(1,1)<pr) {
            cur = ceil(runiform(1,1)*L)
            if (cur<1) {
                cur = 1
            }
        }
        else {
            cur = cur + 1
            if (cur>L) {
                cur = 1
            }
        }
        idx[t] = cur
    }
    return(idx)
}

void _xtnlc_fffff_driver(string scalar dv, string scalar xv, string scalar idv, ///
    string scalar tvv, string scalar tousev, real scalar pmax, real scalar kstep, ///
    real scalar B, real scalar blockopt, real scalar seed, real scalar trend)
{
    real colvector Y, ID, TT, ord, ids, KSS, Khat, Phat, kgrid
    real colvector bm, bmf, bdv, ip, c10, c5, c1, dnustar, nustar, idx
    real colvector idxset, curK, curKf, active, rr, rrf
    real matrix X, bnd, BKSS, OUT, SP
    real scalar N, i, b, T0, s, e, L, gstat, meanbl, t, nstep, mn, mi, jj, ii
    real scalar om, pv
    real colvector yp, nu
    real matrix Zp
    real rowvector sr
    struct _xtnlc_pv colvector PV

    Y  = st_data(., dv, tousev)
    X  = st_data(., tokens(xv), tousev)
    ID = st_data(., idv, tousev)
    TT = st_data(., tvv, tousev)
    ord = order((ID,TT), (1,2))
    Y = Y[ord]
    X = X[ord,]
    ID = ID[ord]
    TT = TT[ord]
    bnd = _xtnlc_bounds(ID)
    ids = uniqrows(ID)
    N = rows(bnd)

    T0 = bnd[1,2] - bnd[1,1] + 1
    for (i=1; i<=N; i=i+1) {
        if ((bnd[i,2]-bnd[i,1]+1)!=T0) {
            st_numscalar("__bal", 0)
            return
        }
    }
    st_numscalar("__bal", 1)

    kgrid = range(0.1, 2, kstep)

    KSS = J(N,1,.)
    Khat = J(N,1,.)
    Phat = J(N,1,.)
    PV = _xtnlc_pv(N)
    for (i=1; i<=N; i=i+1) {
        s = bnd[i,1]
        e = bnd[i,2]
        yp = Y[|s \ e|]
        Zp = X[|s,. \ e,.|]
        nu = _xtnlc_resid(yp, Zp, trend)
        sr = _xtnlc_kss_search(nu, pmax, trend, kgrid)
        KSS[i]  = sr[1]
        Khat[i] = sr[2]
        Phat[i] = sr[3]
        PV[i].dnu = nu[|2 \ rows(nu)|] - nu[|1 \ rows(nu)-1|]
        PV[i].Z = Zp
        PV[i].khat = sr[2]
        PV[i].phat = sr[3]
    }
    curKf = select(KSS, KSS:<.)
    gstat = mean(curKf)

    // bootstrap: stationary, common index across panels (CSD)
    L = T0 - 1
    meanbl = blockopt
    if (meanbl<2) {
        meanbl = ceil(sqrt(T0))
    }
    if (meanbl<2) {
        meanbl = 2
    }
    BKSS = J(B, N, .)
    rseed(seed)
    for (b=1; b<=B; b=b+1) {
        idx = _xtnlc_sb_index(L, meanbl)
        for (i=1; i<=N; i=i+1) {
            dnustar = (PV[i].dnu)[idx]
            nustar = J(T0,1,0)
            for (t=2; t<=T0; t=t+1) {
                nustar[t] = nustar[t-1] + dnustar[t-1]
            }
            // re-impose the first-stage projection on the original Z so the
            // bootstrap residual carries the same spurious mean reversion as
            // the observed residual (Olayeni et al. 2021, steps 5-7), then
            // re-run the SAME (k,p) selection so the frequency search is part
            // of the bootstrapped statistic (correct size; otherwise the
            // selection advantage of the observed stat inflates rejections)
            nustar = _xtnlc_resid(nustar, PV[i].Z, trend)
            sr = _xtnlc_kss_search(nustar, pmax, trend, kgrid)
            BKSS[b,i] = sr[1]
        }
    }

    // group p-value (lower tail) + individual
    bm = J(B,1,.)
    for (b=1; b<=B; b=b+1) {
        rr = BKSS[b,]'
        rrf = select(rr, rr:<.)
        if (rows(rrf)>0) {
            bm[b] = mean(rrf)
        }
    }
    bdv = select(bm, bm:<.)

    ip  = J(N,1,.)
    c10 = J(N,1,.)
    c5  = J(N,1,.)
    c1  = J(N,1,.)
    for (i=1; i<=N; i=i+1) {
        rr = BKSS[,i]
        rrf = select(rr, rr:<.)
        if (rows(rrf)>0 & KSS[i]<.) {
            ip[i] = mean(rrf:<=KSS[i])
            c10[i] = _xtnlc_quantile(rrf, 0.10)
            c5[i]  = _xtnlc_quantile(rrf, 0.05)
            c1[i]  = _xtnlc_quantile(rrf, 0.01)
        }
    }

    // SPSM
    active = J(N,1,1)
    SP = J(N, 6, .)
    nstep = 0
    while (sum(active)>0) {
        idxset = select((1::N), active:==1)
        curK = KSS[idxset]
        curKf = select(curK, curK:<.)
        if (rows(curKf)==0) {
            break
        }
        om = mean(curKf)
        bm = J(B,1,.)
        for (b=1; b<=B; b=b+1) {
            rr = (BKSS[b,])'
            rr = rr[idxset]
            rrf = select(rr, rr:<.)
            if (rows(rrf)>0) {
                bm[b] = mean(rrf)
            }
        }
        bmf = select(bm, bm:<.)
        pv = mean(bmf:<=om)
        mn = .
        mi = 0
        for (jj=1; jj<=rows(idxset); jj=jj+1) {
            ii = idxset[jj]
            if (KSS[ii]<.) {
                if (mi==0) {
                    mn = KSS[ii]
                    mi = ii
                }
                else {
                    if (KSS[ii]<mn) {
                        mn = KSS[ii]
                        mi = ii
                    }
                }
            }
        }
        if (mi==0) {
            break
        }
        nstep = nstep + 1
        SP[nstep,1] = nstep
        SP[nstep,2] = om
        SP[nstep,3] = pv
        SP[nstep,4] = KSS[mi]
        SP[nstep,5] = Khat[mi]
        SP[nstep,6] = ids[mi]
        active[mi] = 0
    }
    if (nstep>0) {
        SP = SP[|1,1 \ nstep,6|]
    }

    OUT = (ids, KSS, Khat, Phat, ip, c10, c5, c1)
    st_matrix("__ind", OUT)
    st_matrix("__spsm", SP)
    st_matrix("__bdist", bdv)
    st_numscalar("__N", N)
    st_numscalar("__T", T0)
    st_numscalar("__nstat", rows(select(KSS, KSS:<.)))
    st_numscalar("__gstat", gstat)
    st_numscalar("__pval", mean(bdv:<=gstat))
    st_numscalar("__gcv10", _xtnlc_quantile(bdv,0.10))
    st_numscalar("__gcv5",  _xtnlc_quantile(bdv,0.05))
    st_numscalar("__gcv1",  _xtnlc_quantile(bdv,0.01))
}

end
