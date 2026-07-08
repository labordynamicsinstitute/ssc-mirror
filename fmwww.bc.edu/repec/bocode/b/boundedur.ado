*! boundedur v2.0.0  Merwan Roudane  07jul2026
*! Unit-root tests for bounded time series -- a library
*! Base command implements Cavaliere & Xu (2014, J.Econometrics 178, 259-272)
*! Algorithm 1 (simulation-based ADF and M tests) faithfully.
*! github.com/merwanroudane  --  merwanroudane920@gmail.com
*!
*! Dispatcher:
*!   boundedur <varname> , lbound() [ubound() ...]   -> Cavaliere-Xu (2014) tests
*!   boundedur cx      <varname> , ...               -> same, explicit
*!   boundedur mtests  <varname> , ...               -> Carrion-i-Silvestre & Gadea (2013)
*!   boundedur breaks  <varname> , ...               -> (in development) CSG (2016)
*!   boundedur hlt     <varname> , ...               -> (in development) CSG (2024)

program define boundedur, rclass
    version 14.0

    * ---- dispatcher: peek at the first token --------------------------------
    gettoken sub rest : 0, parse(" ,")
    local sub = lower("`sub'")

    if inlist("`sub'","cx","mtests","breaks","hlt") {
        local 0 `"`rest'"'
        if "`sub'" == "cx" {
            boundedur_cx `0'
        }
        else if "`sub'" == "mtests" {
            boundedur_stub "mtests" "Carrion-i-Silvestre & Gadea (2013), GLS M-tests for bounded series"
        }
        else if "`sub'" == "breaks" {
            boundedur_stub "breaks" "Carrion-i-Silvestre & Gadea (2016), bounds+breaks"
        }
        else {
            boundedur_stub "hlt" "Carrion-i-Silvestre & Gadea (2024), HLT level-shift"
        }
    }
    else {
        * no recognised subcommand -> default to the Cavaliere-Xu tests
        boundedur_cx `0'
    }
    return add
end

*==============================================================================
* Placeholder for library modules still under construction
*==============================================================================
program define boundedur_stub
    args name desc
    di as error "boundedur `name': `desc' is not yet available in this release."
    di as text  "This module is on the roadmap; see {help boundedur##roadmap:help boundedur}."
    exit 198
end


*==============================================================================
* boundedur cx : Cavaliere & Xu (2014) simulation-based ADF and M tests
*==============================================================================
program define boundedur_cx, rclass
    version 14.0

    syntax varname(ts) [if] [in] , ///
        Lbound(string) ///
        [ Ubound(string) ] ///
        [ Test(string) ] ///
        [ Lags(integer -1) ] ///
        [ MAXLag(integer -1) ] ///
        [ Nsim(integer 499) ] ///
        [ Nstep(integer -1) ] ///
        [ DETrend(string) ] ///
        [ REColor ] ///
        [ KRClag(integer -1) ] ///
        [ GLSc(real -7.0) ] ///
        [ SEED(integer -1) ] ///
        [ SAVESIM(name) ] ///
        [ noGRAPH ] ///
        [ GNAME(string) ] ///
        [ Level(cilevel) ]

    * ---- parse bounds (allow . / "inf" for one-sided) -----------------------
    local lb = lower("`lbound'")
    local ub = lower("`ubound'")
    local lbval = .
    if !inlist("`lb'","",".","inf","-inf","+inf","none") {
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

    * ---- sample / time handling --------------------------------------------
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
        di as error "Panel data are not supported; use a single time series (tsset time)."
        exit 198
    }
    if "`timevar'" == "" {
        di as error "Data are not tsset. Use {cmd:tsset} timevar first."
        exit 111
    }
    markout `touse' `timevar'
    qui count if `touse'
    local N = r(N)
    if `N' < 15 {
        di as error "Insufficient observations (need at least 15)."
        exit 2001
    }

    * ---- detrending ---------------------------------------------------------
    if "`detrend'" == "" local detrend "constant"
    local detrend = lower("`detrend'")
    if !inlist("`detrend'","constant","gls","none") {
        di as error "detrend() must be constant, gls or none"
        exit 198
    }
    local detcode = 0
    if "`detrend'"=="gls"  local detcode = 1
    if "`detrend'"=="none" local detcode = 2

    * ---- test selection -----------------------------------------------------
    if "`test'"=="" local test "all"
    local test = lower("`test'")
    if !inlist("`test'","adfalpha","adft","mzalpha","mzt","msb","all") {
        di as error "test() must be one of: adfalpha adft mzalpha mzt msb all"
        exit 198
    }

    * ---- lag machinery ------------------------------------------------------
    if `maxlag' == -1 local maxlag = floor(12*(`N'/100)^0.25)
    if `nstep'  == -1 local nstep  = `N'        // Remark 4.4: n=T best in finite samples
    if `nstep'  < `N' {
        di as text "note: nstep(`nstep') < T; paper requires n>=T. Resetting to T=`N'."
        local nstep = `N'
    }
    local recol = 0
    if "`recolor'" != "" local recol = 1
    if `seed' > 0 set seed `seed'

    * ---- bounds echo --------------------------------------------------------
    di _n as text "{bf:Bounded unit-root tests} " as text "(Cavaliere & Xu 2014, {it:J. Econometrics} 178)"
    di as text "{hline 78}"

    * ---- call the Mata engine ----------------------------------------------
    tempname RES
    mata: _bur_cx_run("`varlist'","`touse'","`timevar'")
    * The Mata driver writes:
    *   scalars: __bur_k __bur_kmax __bur_s2ar __bur_x0 __bur_cinf __bur_csup
    *   matrix : __bur_res  (5 x 3: statistic, pvalue, cv5)  rownames set below
    *   matrix : __bur_sim  (nsim x 3) if requested

    local siglev = 100 - `level'
    matrix `RES' = __bur_res
    matrix rownames `RES' = ADF_alpha ADF_t MZ_alpha MZ_t MSB
    matrix colnames `RES' = Statistic p_value CV_`siglev'

    local k     = __bur_k
    local s2ar  = __bur_s2ar
    local x0    = __bur_x0
    local cinf  = __bur_cinf
    local csup  = __bur_csup

    * ---- configuration block ------------------------------------------------
    di as text "  Variable        : " as result "`varlist'"
    di as text "  Time variable   : " as result "`timevar'"
    di as text "  Observations T  : " as result `N'
    local lbtxt = cond(`lbval'==., "-inf", string(`lbval'))
    local ubtxt = cond(`ubval'==., "+inf", string(`ubval'))
    di as text "  Bounds [b, b-bar]: " as result "[`lbtxt', `ubtxt']"
    di as text "  Detrending      : " as result "`detrend'" ///
        cond("`detrend'"=="gls"," (c-bar=`glsc')","")
    di as text "  Lags (MAIC)     : " as result `k' as text "  (kmax=`maxlag')"
    di as text "  Long-run var s^2: " as result %9.5f `s2ar'
    di as text "  X0 (first obs)  : " as result %9.5f `x0'
    local citxt = cond(`cinf'==., "-inf", string(`cinf',"%7.4f"))
    local cstxt = cond(`csup'==., "+inf", string(`csup',"%7.4f"))
    di as text "  Bound params    : " as text "c-hat=" as result "`citxt'" ///
        as text "   c-bar-hat=" as result "`cstxt'"
    local krcuse = cond(`krclag'==-1, `k', `krclag')
    local rctxt = ""
    if `recol' & `krcuse' >= 1 local rctxt "   (re-coloured, krc=`krcuse')"
    if `recol' & `krcuse' < 1  local rctxt "   (re-colouring requested but krc=0: inactive)"
    di as text "  MC replications : " as result `nsim' as text "   steps n=" as result `nstep' as text "`rctxt'"

    * ---- results table ------------------------------------------------------
    di _n as text "{hline 78}"
    di as text %-12s "Test" _col(20) %10s "Statistic" _col(34) %9s "p-value" ///
        _col(46) %10s "CV(`siglev'%)" _col(60) "Decision"
    di as text "{hline 78}"

    local names ADF_alpha ADF_t MZ_alpha MZ_t MSB
    local disp  "ADF*_alpha ADF*_t MZ*_alpha MZ*_t MSB*"
    local keep  "adfalpha adft mzalpha mzt msb"
    forvalues i = 1/5 {
        local nm  : word `i' of `names'
        local sh  : word `i' of `disp'
        local kv  : word `i' of `keep'
        if "`test'"=="all" | "`test'"=="`kv'" {
            local st = `RES'[`i',1]
            local pv = `RES'[`i',2]
            local cv = `RES'[`i',3]
            local star = ""
            if `pv' < .10  local star "*"
            if `pv' < .05  local star "**"
            if `pv' < .01  local star "***"
            local dec = cond(`pv' < `siglev'/100, "Reject H0", "Fail to reject")
            di as text %-12s "`sh'" _col(20) as result %10.4f `st' ///
                _col(34) %9.4f `pv' as result "`star'" _col(46) as result %10.4f `cv' ///
                _col(60) as text "`dec'"
        }
    }
    di as text "{hline 78}"
    di as text "H0: bounded unit root, b in [`lbtxt', `ubtxt'].  * .10  ** .05  *** .01"
    di as text "ADF/MZ reject for large negative values; MSB rejects for small values."
    di as text "p-values: Monte Carlo (Cavaliere-Xu Algorithm 1, B=`nsim', n=`nstep')."

    * ---- returns ------------------------------------------------------------
    return scalar N       = `N'
    return scalar lags    = `k'
    return scalar s2ar    = `s2ar'
    return scalar x0      = `x0'
    return scalar c_lower = `cinf'
    return scalar c_upper = `csup'
    return scalar lbound  = `lbval'
    return scalar ubound  = `ubval'
    return scalar adf_alpha = `RES'[1,1]
    return scalar adf_t     = `RES'[2,1]
    return scalar mz_alpha  = `RES'[3,1]
    return scalar mz_t      = `RES'[4,1]
    return scalar msb       = `RES'[5,1]
    return scalar p_adf_alpha = `RES'[1,2]
    return scalar p_adf_t     = `RES'[2,2]
    return scalar p_mz_alpha  = `RES'[3,2]
    return scalar p_mz_t      = `RES'[4,2]
    return scalar p_msb       = `RES'[5,2]
    return local  detrend "`detrend'"
    return local  timevar "`timevar'"
    return local  depvar  "`varlist'"
    return local  cmd     "boundedur"
    return matrix results = `RES', copy

    * ---- optional: save the simulated null distribution ---------------------
    if "`savesim'" != "" {
        capture drop `savesim'1 `savesim'2 `savesim'3
        qui svmat double __bur_sim, name(`savesim')
        di as text "note: simulated null draws saved in `savesim'1 (alpha), `savesim'2 (t), `savesim'3 (msb)."
    }

    * ---- journal-style graphics --------------------------------------------
    if "`graph'" != "nograph" {
        boundedur_plot_cx, timevar(`timevar') depvar(`varlist') touse(`touse') ///
            lbound(`lbval') ubound(`ubval') gname(`gname') ///
            astat(`=`RES'[3,1]') acv(`=`RES'[3,3]')
    }

    * ---- tidy engine leftovers ---------------------------------------------
    capture matrix drop __bur_res __bur_sim
    capture scalar drop __bur_k __bur_kmax __bur_s2ar __bur_x0 __bur_cinf __bur_csup
end


*==============================================================================
* Journal-style graphics for boundedur cx
*==============================================================================
program define boundedur_plot_cx
    version 14.0
    syntax , timevar(string) depvar(string) touse(string) ///
        [ lbound(string) ubound(string) gname(string) astat(string) acv(string) ]

    if "`gname'" == "" local gname boundedur

    * ---- Panel A: the bounded series with the bounds drawn ------------------
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

    local glist `gname'_series

    * ---- Panel B: simulated (MC) null distribution vs observed -------------
    capture confirm matrix __bur_sim
    if !_rc {
        preserve
        clear
        qui svmat double __bur_sim, name(bsim)
        local xl ""
        if "`astat'" != "" local xl "`xl' xline(`astat', lcolor(navy) lwidth(medthick))"
        if "`acv'"   != "" local xl "`xl' xline(`acv', lcolor(red) lpattern(dash))"
        twoway (histogram bsim1, percent color(gs12) lcolor(gs9)), ///
            `xl' ///
            title("MC null distribution: MZ*{sub:{&alpha}}", size(medium)) ///
            subtitle("navy = observed statistic; red dash = critical value", size(small)) ///
            xtitle("MZ*{sub:{&alpha}}") ytitle("percent") ///
            graphregion(color(white)) plotregion(color(white)) ///
            name(`gname'_null, replace) nodraw
        restore
        local glist `glist' `gname'_null
    }

    capture graph combine `glist', ///
        title("boundedur: Cavaliere & Xu (2014) bounded unit-root test", size(medsmall)) ///
        note("Regulated Brownian-motion null via Algorithm 1 (clipping construction).", size(vsmall)) ///
        graphregion(color(white)) name(`gname', replace)
    if _rc {
        capture graph display `gname'_series
    }
end


*==============================================================================
*                              M A T A   E N G I N E
*==============================================================================
version 14.0
mata:
mata set matastrict off

// -------------------------------------------------------------------------
// GLS (quasi-difference) de-meaning for a constant, Elliott-Rothenberg-Stock
// -------------------------------------------------------------------------
real colvector _bur_detgls(real colvector y, real scalar cbar)
{
    real scalar nt, abar, bhat
    real colvector z, ya, za
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

// -------------------------------------------------------------------------
// Ng-Perron MAIC lag selection over a FIXED effective sample (t=kmax+2..T)
// -------------------------------------------------------------------------
real scalar _bur_maic(real colvector d, real scalar kmax)
{
    real scalar T, nef, k, i, r, t, sumy, s2, tau, mic, best, bestv
    real colvector dep, bb, e
    real matrix Rg, Xk, iXk
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
        iXk = invsym(quadcross(Xk,Xk))
        bb  = iXk*quadcross(Xk,dep)
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

// -------------------------------------------------------------------------
// ADF regression on de-trended series d with k augmenting lags.
// Returns colvector: (adf_alpha \ adf_t \ alpha1 \ s2ar \ pi \ se \ lagcoefs)
// -------------------------------------------------------------------------
real colvector _bur_adf(real colvector d, real scalar k)
{
    real scalar T, nobs, r, t, i, alpha1, s2, se, pi, adfa, adft, s2ar
    real colvector dep, b, e, out
    real matrix Rg, iXtX
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
    iXtX = invsym(quadcross(Rg,Rg))
    b    = iXtX*quadcross(Rg,dep)
    e    = dep - Rg*b
    s2   = quadcross(e,e)/nobs
    se   = sqrt(iXtX[1,1]*s2)
    pi   = b[1]
    alpha1 = 1
    if (k >= 1) {
        alpha1 = 1 - sum(b[|2 \ k+1|])
    }
    s2ar = s2/(alpha1^2)
    adfa = T*pi/alpha1
    adft = pi/se
    out  = (adfa \ adft \ alpha1 \ s2ar \ pi \ se)
    if (k >= 1) {
        out = out \ b[|2 \ k+1|]
    }
    return(out)
}

// -------------------------------------------------------------------------
// M statistics from de-trended series d and long-run variance lrv.
// Cavaliere-Xu (2014) convention: numerator includes the -T^{-1} X0^2 term.
// -------------------------------------------------------------------------
real rowvector _bur_mstats(real colvector d, real scalar lrv)
{
    real scalar T, sslag, mza, msb, mzt
    T     = rows(d)
    sslag = quadcross(d[|1 \ T-1|], d[|1 \ T-1|])
    mza   = (d[T]^2/T - d[1]^2/T - lrv)/(2*sslag/(T^2))
    msb   = sqrt(sslag/(T^2*lrv))
    mzt   = mza*msb
    return((mza, mzt, msb))
}

// -------------------------------------------------------------------------
// Re-colouring filter (eq. 4.14): alpha_krc(L)/alpha_krc(1) u_t = eps_t
//   => u_t = (1-sum a) eps_t + sum_i a_i u_{t-i} ,  unit long-run variance.
// -------------------------------------------------------------------------
real colvector _bur_recolor(real colvector eps, real colvector a)
{
    real scalar n, p, t, i, s, a1
    real colvector u
    n  = rows(eps)
    p  = rows(a)
    a1 = 1 - sum(a)
    u  = J(n,1,0)
    for (t=1; t<=n; t++) {
        s = a1*eps[t]
        for (i=1; i<=p; i++) {
            if (t-i >= 1) {
                s = s + a[i]*u[t-i]
            }
        }
        u[t] = s
    }
    return(u)
}

// -------------------------------------------------------------------------
// Empirical quantile (type-7, linear interpolation)
// -------------------------------------------------------------------------
real scalar _bur_quantile(real colvector x, real scalar p)
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

// -------------------------------------------------------------------------
// Monte Carlo null distribution (Algorithm 1, Steps i-iii) via the
// clipping construction. Returns B x 3 matrix: (lambda_alpha, lambda_t, lambda_msb).
// -------------------------------------------------------------------------
real matrix _bur_cx_sim(real scalar cinf, real scalar csup, real scalar n, ///
    real scalar B, real scalar recol, real colvector acoef)
{
    real matrix S
    real colvector eps, u, Xp, Xt
    real scalar b, t, xprev, xv, sq, m, A, num, La, Lmsb, Lt
    S  = J(B, 3, .)
    sq = sqrt(n)
    for (b=1; b<=B; b++) {
        eps = rnormal(n,1,0,1)
        if (recol==1 & rows(acoef)>0) {
            u = _bur_recolor(eps, acoef)
        }
        else {
            u = eps
        }
        Xp    = J(n+1,1,0)
        xprev = 0
        for (t=1; t<=n; t++) {
            xv = xprev + u[t]/sq
            if (csup < .) {
                if (xv > csup) xv = csup
            }
            if (cinf < .) {
                if (xv < cinf) xv = cinf
            }
            Xp[t+1] = xv
            xprev   = xv
        }
        m   = mean(Xp)
        Xt  = Xp :- m
        A   = mean(Xt[|2 \ n+1|]:^2)
        num = Xt[n+1]^2 - Xt[1]^2 - 1
        La  = num/(2*A)
        Lmsb = sqrt(A)
        Lt   = La*Lmsb
        S[b,1] = La
        S[b,2] = Lt
        S[b,3] = Lmsb
    }
    return(S)
}

// -------------------------------------------------------------------------
// Driver for  boundedur cx
// -------------------------------------------------------------------------
void _bur_cx_run(string scalar yvar, string scalar touse, string scalar tvar)
{
    real matrix X, R, S
    real colvector y, d, ar, arc, acoef
    real rowvector mm
    real scalar T, kmax, k, detcode, glsc, B, n, recol, krc
    real scalar lb, ub, x0, s2ar, sAR, cinf, csup, lev
    real scalar adfa, adft, mza, mzt, msb
    real scalar p_adfa, p_adft, p_mza, p_mzt, p_msb, cva, cvt, cvm

    lb      = strtoreal(st_local("lbval"))
    ub      = strtoreal(st_local("ubval"))
    kmax    = strtoreal(st_local("maxlag"))
    detcode = strtoreal(st_local("detcode"))
    glsc    = strtoreal(st_local("glsc"))
    B       = strtoreal(st_local("nsim"))
    n       = strtoreal(st_local("nstep"))
    recol   = strtoreal(st_local("recol"))
    krc     = strtoreal(st_local("krclag"))
    k       = strtoreal(st_local("lags"))
    lev     = 1 - strtoreal(st_local("level"))/100   // significance-level tail (e.g. 0.05)

    X  = st_data(., (yvar, tvar), touse)
    X  = sort(X, 2)
    y  = X[.,1]
    T  = rows(y)
    x0 = y[1]

    if (detcode==0) {
        d = y :- mean(y)
    }
    else if (detcode==1) {
        d = _bur_detgls(y, glsc)
    }
    else {
        d = y
    }

    if (k < 0) k = _bur_maic(d, kmax)
    if (k > T-4) k = T-4
    if (k < 0) k = 0

    ar    = _bur_adf(d, k)
    adfa  = ar[1]
    adft  = ar[2]
    s2ar  = ar[4]
    sAR   = sqrt(s2ar)

    mm  = _bur_mstats(d, s2ar)
    mza = mm[1]
    mzt = mm[2]
    msb = mm[3]

    cinf = .
    csup = .
    if (lb < .) cinf = (lb - x0)/(sAR*sqrt(T))
    if (ub < .) csup = (ub - x0)/(sAR*sqrt(T))

    acoef = J(0,1,.)
    if (recol==1) {
        if (krc < 0) krc = k
        if (krc >= 1) {
            arc   = _bur_adf(d, krc)
            acoef = arc[|7 \ 6+krc|]
        }
    }

    S = _bur_cx_sim(cinf, csup, n, B, recol, acoef)

    p_adfa = mean(S[.,1] :<= adfa)
    p_adft = mean(S[.,2] :<= adft)
    p_mza  = mean(S[.,1] :<= mza)
    p_mzt  = mean(S[.,2] :<= mzt)
    p_msb  = mean(S[.,3] :<= msb)

    cva = _bur_quantile(S[.,1], lev)
    cvt = _bur_quantile(S[.,2], lev)
    cvm = _bur_quantile(S[.,3], lev)

    R = J(5,3,.)
    R[1,.] = (adfa, p_adfa, cva)
    R[2,.] = (adft, p_adft, cvt)
    R[3,.] = (mza,  p_mza,  cva)
    R[4,.] = (mzt,  p_mzt,  cvt)
    R[5,.] = (msb,  p_msb,  cvm)

    st_matrix("__bur_res", R)
    st_matrix("__bur_sim", S)
    st_numscalar("__bur_k",    k)
    st_numscalar("__bur_kmax", kmax)
    st_numscalar("__bur_s2ar", s2ar)
    st_numscalar("__bur_x0",   x0)
    st_numscalar("__bur_cinf", cinf)
    st_numscalar("__bur_csup", csup)
}

end

