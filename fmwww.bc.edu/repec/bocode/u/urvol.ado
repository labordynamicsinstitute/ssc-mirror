*! urvol 1.0.0  09jul2026
*! Unit-root tests robust to non-stationary (time-varying) volatility.
*!   wbdf  - wild-bootstrap (A)DF/PP test   (Cavaliere 2004; Cavaliere & Taylor 2008,2009)
*!   beare - rescaled Phillips-Perron test  (Beare 2017, J. Time Ser. Anal.)
*!   bzu   - adaptive wild-bootstrap LR test (Boswijk & Zu 2018, Econometrics Journal)
*!   all   - run the three tests and print a comparison table
*! Author: Merwan Roudane, merwanroudane920@gmail.com
*! https://github.com/merwanroudane

program define urvol, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    if ("`sub'"=="") {
        di as error "urvol: specify a subcommand: {bf:wbdf}, {bf:beare}, {bf:bzu} or {bf:all}"
        di as error "see {help urvol}"
        exit 198
    }
    if ("`sub'"=="wbdf") {
        urvol_wbdf `0'
    }
    else if ("`sub'"=="beare") {
        urvol_beare `0'
    }
    else if ("`sub'"=="bzu") {
        urvol_bzu `0'
    }
    else if ("`sub'"=="all") {
        urvol_all `0'
    }
    else {
        di as error "urvol: unknown subcommand '`sub''"
        di as error "valid subcommands: wbdf, beare, bzu, all"
        exit 198
    }
    return add
end

*-------------------------------------------------------------------------------
* shared helper: read tsset, mark sample, check contiguity, return series/det
*-------------------------------------------------------------------------------
program define _urv_prep, rclass
    // validate ts data and count usable obs. The caller has ALREADY created and
    // marksample'd `touse' (gotcha: a touse created in a helper is dropped on
    // return, so it must live in the program that uses it).
    syntax , TOUSE(name) VARname(string)
    qui tsset
    local tvar "`r(timevar)'"
    if ("`tvar'"=="") {
        di as error "urvol: data must be {bf:tsset} (a single time series)"
        exit 459
    }
    if ("`r(panelvar)'"!="") {
        di as error "urvol: this is a single time-series command; data are {bf:xtset} as a panel"
        di as error "run it on one panel, e.g. {bf:keep if `r(panelvar)'==...}"
        exit 459
    }
    markout `touse' `varname'
    qui count if `touse'
    local n = r(N)
    if (`n' < 20) {
        di as error "urvol: too few usable observations (`n'); need at least 20"
        exit 2001
    }
    // contiguity check: the used sample should be a gap-free time span
    qui summ `tvar' if `touse', meanonly
    local t0 = r(min)
    local t1 = r(max)
    qui count if `tvar'>=`t0' & `tvar'<=`t1' & !missing(`varname')
    if (r(N) != `n') {
        di as text "urvol: warning - sample has internal gaps/missings; using the marked observations in time order"
    }
    return local tvar "`tvar'"
    return scalar n = `n'
end

*-------------------------------------------------------------------------------
* WBDF : wild-bootstrap (A)DF / PP test
*-------------------------------------------------------------------------------
program define urvol_wbdf, rclass
    syntax varlist(min=1 max=1 numeric ts) [if] [in] , ///
        [ Trend NOConstant Lags(integer -1) MAXLags(integer -1) IC(string) ///
          Reps(integer 999) Wild(string) STATistic(string) Seed(string) ///
          Graph GNAME(string) LEVel(cilevel) ]

    // deterministic
    local det = 1
    if ("`trend'"!="")      local det = 2
    if ("`noconstant'"!="") local det = 0
    if ("`trend'"!="" & "`noconstant'"!="") {
        di as error "urvol wbdf: {bf:trend} and {bf:noconstant} are mutually exclusive"
        exit 198
    }
    // statistic
    if ("`statistic'"=="") local statistic "t"
    if (!inlist("`statistic'","t","rho")) {
        di as error "urvol wbdf: statistic() must be {bf:t} or {bf:rho}"
        exit 198
    }
    local istat = cond("`statistic'"=="t",1,2)
    // wild scheme
    if ("`wild'"=="") local wild "rademacher"
    if (!inlist("`wild'","rademacher","normal","mammen")) {
        di as error "urvol wbdf: wild() must be {bf:rademacher}, {bf:normal} or {bf:mammen}"
        exit 198
    }
    local iwild = cond("`wild'"=="rademacher",1,cond("`wild'"=="normal",2,3))
    // ic
    if ("`ic'"=="") local ic "maic"
    if (!inlist("`ic'","maic","aic","bic","none")) {
        di as error "urvol wbdf: ic() must be {bf:maic}, {bf:aic}, {bf:bic} or {bf:none}"
        exit 198
    }
    local iic = cond("`ic'"=="aic",1,cond("`ic'"=="bic",2,cond("`ic'"=="maic",3,0)))
    if (`reps' < 99) {
        di as text "urvol wbdf: reps(`reps') is low; 999 or more is recommended"
    }
    if ("`seed'"!="") set seed `seed'

    tempvar touse
    marksample touse
    _urv_prep , touse(`touse') varname(`varlist')
    local n = r(n)
    local y "`varlist'"

    // lag handling: fixed lags() wins; else maxlags()+ic; default maxlags rule
    local lagfix = `lags'
    if (`lags' < 0) {
        if (`maxlags' < 0) {
            local maxlags = floor(12*(`n'/100)^0.25)
            if (`maxlags' > `n'/3) local maxlags = floor(`n'/3)
        }
    }
    else {
        local maxlags = `lags'
    }

    tempvar volp
    qui gen double `volp' = .
    mata: urv_wbdf("`y'","`touse'", `det', `lagfix', `maxlags', `iic', ///
        `reps', `iwild', `istat')

    local stat   = __urv_stat
    local pval   = __urv_p
    local lused  = __urv_lused
    local neff   = __urv_neff
    scalar drop __urv_stat __urv_p __urv_lused __urv_neff

    _urv_header "Wild-bootstrap (A)DF / PP unit-root test" ///
        "Cavaliere (2004); Cavaliere & Taylor (2008, 2009)" `det' `y' `neff'
    di as text "{hline 66}"
    if (`istat'==1) local statlab "ADF t-statistic"
    else            local statlab "DF coefficient (rho)"
    di as text "  Test statistic      " as text "= " as result %10.4f `stat' ///
        as text "   (`statlab')"
    di as text "  Lags included       " as text "= " as result %10.0f `lused'
    di as text "  Wild scheme         " as text "= " as result "`wild'" _col(52) "reps = " as result `reps'
    _urv_pline `pval'
    di as text "{hline 66}"
    di as text "  H0: unit root.  Bootstrap p-value is one-sided (lower tail)."

    if ("`graph'"!="") {
        _urv_bootgraph `stat' "`gname'" "Wild-bootstrap null distribution" "`statlab'"
    }

    return scalar stat  = `stat'
    return scalar p     = `pval'
    return scalar lags  = `lused'
    return scalar N     = `neff'
    return scalar reps  = `reps'
    return local  wild   "`wild'"
    return local  statistic "`statistic'"
    return local  test  "wbdf"
end

*-------------------------------------------------------------------------------
* BEARE : rescaled Phillips-Perron test
*-------------------------------------------------------------------------------
program define urvol_beare, rclass
    syntax varlist(min=1 max=1 numeric ts) [if] [in] , ///
        [ Trend NOConstant Bandwidth(real 0.1) HACbw(integer -1) ///
          Reps(integer 999) BOOTstrap ASYmptotic Seed(string) ///
          Graph GNAME(string) ]

    local det = 1
    if ("`trend'"!="")      local det = 2
    if ("`noconstant'"!="") local det = 0
    if ("`trend'"!="" & "`noconstant'"!="") {
        di as error "urvol beare: {bf:trend} and {bf:noconstant} are mutually exclusive"
        exit 198
    }
    if (`bandwidth' <= 0 | `bandwidth' >= 1) {
        di as error "urvol beare: bandwidth() must lie in (0,1); Beare (2017) recommends 0.1"
        exit 198
    }
    // p-value mode: bootstrap default; asymptotic optional (pivotal only w/ constant)
    local dobs = 1
    if ("`asymptotic'"!="" & "`bootstrap'"=="") local dobs = 0
    if ("`seed'"!="") set seed `seed'

    tempvar touse
    marksample touse
    _urv_prep , touse(`touse') varname(`varlist')
    local n = r(n)
    local y "`varlist'"

    if (`hacbw' < 0) {
        local hacbw = floor(4*((`n')/100)^(2/9))
    }

    tempvar volp rser
    qui gen double `volp' = .
    qui gen double `rser' = .
    mata: urv_beare("`y'","`touse'", `det', `bandwidth', `hacbw', ///
        `dobs', `reps', "`volp'", "`rser'")

    local zalpha = __urv_zalpha
    local zt     = __urv_zt
    local pza    = __urv_pza
    local pzt    = __urv_pzt
    local neff   = __urv_neff
    scalar drop __urv_zalpha __urv_zt __urv_pza __urv_pzt __urv_neff

    // asymptotic Dickey-Fuller critical values (constant case is pivotal)
    _urv_dfcv `det'
    local ta5 = r(tau5)
    local ra5 = r(rho5)

    _urv_header "Beare (2017) rescaled Phillips-Perron unit-root test" ///
        "kernel-rescaled series, standard DF asymptotics (constant case)" `det' `y' `neff'
    di as text "{hline 72}"
    di as text %-22s "  Statistic" %13s "value" %12s "asy. 5% cv" %14s "p-value"
    di as text "{hline 72}"
    _urv_beline "Z-alpha (rho)" `zalpha' `ra5' `pza' `dobs' 2 `det'
    _urv_beline "Z-t     (tau)" `zt'     `ta5' `pzt' `dobs' 1 `det'
    di as text "{hline 72}"
    di as text "  Volatility bandwidth h = " as result %5.3f `bandwidth' ///
        as text _col(40) "HAC bw = " as result `hacbw'
    if (`dobs') di as text "  p-value: wild bootstrap (" as result `reps' as text " reps), valid under non-pivotal cases."
    else        di as text "  p-value: asymptotic DF distribution (valid with a constant; see help for the trend case)."
    if (`det'==2) di as text "  {bf:Note}: with a linear trend the rescaled statistic is {it:not} pivotal; use bootstrap p-values."
    di as text "{hline 72}"

    if ("`graph'"!="") {
        _urv_volgraph "`y'" "`touse'" "`volp'" "`rser'" "`gname'" 1
    }

    return scalar zalpha = `zalpha'
    return scalar zt     = `zt'
    return scalar p_zalpha = `pza'
    return scalar p_zt     = `pzt'
    return scalar bandwidth = `bandwidth'
    return scalar hacbw  = `hacbw'
    return scalar N      = `neff'
    return local  test   "beare"
end

*-------------------------------------------------------------------------------
* BZU : adaptive wild-bootstrap LR test (Boswijk & Zu 2018)
*-------------------------------------------------------------------------------
program define urvol_bzu, rclass
    syntax varlist(min=1 max=1 numeric ts) [if] [in] , ///
        [ Trend NOConstant Lags(integer -1) MAXLags(integer -1) IC(string) ///
          Window(integer -1) CBAR(real 0) Reps(integer 999) Seed(string) ///
          Graph GNAME(string) ]

    local det = 1
    if ("`trend'"!="")      local det = 2
    if ("`noconstant'"!="") local det = 0
    if ("`trend'"!="" & "`noconstant'"!="") {
        di as error "urvol bzu: {bf:trend} and {bf:noconstant} are mutually exclusive"
        exit 198
    }
    if ("`ic'"=="") local ic "maic"
    if (!inlist("`ic'","maic","aic","bic","none")) {
        di as error "urvol bzu: ic() must be {bf:maic}, {bf:aic}, {bf:bic} or {bf:none}"
        exit 198
    }
    local iic = cond("`ic'"=="aic",1,cond("`ic'"=="bic",2,cond("`ic'"=="maic",3,0)))
    if ("`seed'"!="") set seed `seed'

    tempvar touse
    marksample touse
    _urv_prep , touse(`touse') varname(`varlist')
    local n = r(n)
    local y "`varlist'"

    // default GLS local-to-unity constant (Elliott-Rothenberg-Stock / Boswijk-Zu)
    local cb = `cbar'
    if (`cbar'==0) {
        if (`det'==2) local cb = -13.5
        else          local cb = -7
    }
    // lag defaults
    local lagfix = `lags'
    if (`lags' < 0) {
        if (`maxlags' < 0) {
            local maxlags = floor(12*(`n'/100)^0.25)
            if (`maxlags' < 1) local maxlags = 1
            if (`maxlags' > `n'/4) local maxlags = floor(`n'/4)
        }
    }
    else {
        local maxlags = `lags'
    }

    tempvar volp
    qui gen double `volp' = .
    mata: urv_bzu("`y'","`touse'", `det', `lagfix', `maxlags', `iic', ///
        `window', `cb', `reps', "`volp'")

    local lr    = __urv_lr
    local pval  = __urv_p
    local lused = __urv_lused
    local Nw    = __urv_win
    local neff  = __urv_neff
    scalar drop __urv_lr __urv_p __urv_lused __urv_win __urv_neff

    _urv_header "Boswijk & Zu (2018) adaptive wild-bootstrap LR unit-root test" ///
        "variance-weighted GLS-detrended likelihood ratio" `det' `y' `neff'
    di as text "{hline 66}"
    di as text "  Adaptive LR statistic = " as result %10.4f `lr'
    di as text "  Lags in AR(p)         = " as result %10.0f `lused'
    di as text "  Volatility window N   = " as result %10.0f `Nw' as text "   (exp. kernel, LOO-CV)"
    di as text "  GLS c-bar             = " as result %10.2f `cb'
    _urv_pline `pval'
    di as text "{hline 66}"
    di as text "  H0: unit root.  Reject for large negative LR (lower-tail wild-bootstrap p)."

    if ("`graph'"!="") {
        _urv_volgraph "`y'" "`touse'" "`volp'" "" "`gname'" 0
    }

    return scalar stat  = `lr'
    return scalar p     = `pval'
    return scalar lags  = `lused'
    return scalar window = `Nw'
    return scalar cbar  = `cb'
    return scalar N     = `neff'
    return scalar reps  = `reps'
    return local  test  "bzu"
end

*-------------------------------------------------------------------------------
* ALL : run the three and tabulate
*-------------------------------------------------------------------------------
program define urvol_all, rclass
    syntax varlist(min=1 max=1 numeric ts) [if] [in] , ///
        [ Trend NOConstant Reps(integer 999) Seed(string) * ]
    local det = 1
    if ("`trend'"!="")      local det = 2
    if ("`noconstant'"!="") local det = 0
    local dtopt ""
    if (`det'==2) local dtopt "trend"
    if (`det'==0) local dtopt "noconstant"
    if ("`seed'"!="") set seed `seed'

    di _n as text "{hline 72}"
    di as text as result "  urvol all" as text " : unit-root tests robust to time-varying volatility"
    di as text "{hline 72}"

    quietly {
        urvol_wbdf `varlist' `if' `in', `dtopt' reps(`reps')
        local s1 = r(stat)
        local p1 = r(p)
        urvol_bzu `varlist' `if' `in', `dtopt' reps(`reps')
        local s3 = r(stat)
        local p3 = r(p)
        urvol_beare `varlist' `if' `in', `dtopt' reps(`reps')
        local s2 = r(zt)
        local p2 = r(p_zt)
    }

    di as text %-34s "  Test" %12s "statistic" %12s "p-value" %8s " "
    di as text "{hline 72}"
    _urv_allrow "Wild-bootstrap ADF (t)     [wbdf]"  `s1' `p1'
    _urv_allrow "Beare rescaled PP (Z-t)    [beare]" `s2' `p2'
    _urv_allrow "Boswijk-Zu adaptive LR     [bzu]"   `s3' `p3'
    di as text "{hline 72}"
    di as text "  Bootstrap reps = " as result `reps' as text ".  * .10  ** .05  *** .01 (lower tail)."
    di as text "{hline 72}"

    matrix urv_all = (`s1',`p1' \ `s2',`p2' \ `s3',`p3')
    matrix colnames urv_all = statistic p_value
    matrix rownames urv_all = wbdf beare_zt bzu
    return matrix results = urv_all
    return scalar p_wbdf  = `p1'
    return scalar p_beare = `p2'
    return scalar p_bzu   = `p3'
end

*-------------------------------------------------------------------------------
* small presentation helpers
*-------------------------------------------------------------------------------
program define _urv_header
    args title src det yname neff
    local dl "no constant"
    if (`det'==1) local dl "constant"
    if (`det'==2) local dl "constant + linear trend"
    di _n as text as result "  `title'"
    di as text "  `src'"
    di as text "  Variable: " as result "`yname'" as text "   Deterministics: " as result "`dl'" ///
        as text "   Obs used: " as result `neff'
end

program define _urv_pline
    args p
    local st ""
    if (`p' < 0.10) local st "*"
    if (`p' < 0.05) local st "**"
    if (`p' < 0.01) local st "***"
    di as text "  Bootstrap p-value     = " as result %10.4f `p' as result "`st'"
end

program define _urv_allrow
    args lab s p
    local st ""
    if (`p' < 0.10) local st "*"
    if (`p' < 0.05) local st "**"
    if (`p' < 0.01) local st "***"
    di as text %-34s "  `lab'" as result %12.4f `s' %11.4f `p' as result " `st'"
end

program define _urv_beline
    args lab stat cv p dobs istat det
    local st ""
    if (`dobs') {
        if (`p' < 0.10) local st "*"
        if (`p' < 0.05) local st "**"
        if (`p' < 0.01) local st "***"
        di as text %-22s "  `lab'" as result %13.4f `stat' %12.2f `cv' %13.4f `p' as result " `st'"
    }
    else {
        // asymptotic stars from cv comparison (constant/none pivotal)
        di as text %-22s "  `lab'" as result %13.4f `stat' %12.2f `cv' %13s "  (see cv)"
    }
end

program define _urv_dfcv, rclass
    // asymptotic 5% Dickey-Fuller critical values (tau and rho / Z-alpha)
    args det
    if (`det'==0) {
        return scalar tau5 = -1.95
        return scalar rho5 = -8.1
    }
    else if (`det'==2) {
        return scalar tau5 = -3.41
        return scalar rho5 = -21.8
    }
    else {
        return scalar tau5 = -2.86
        return scalar rho5 = -14.1
    }
end

*-------------------------------------------------------------------------------
* graph helpers
*-------------------------------------------------------------------------------
program define _urv_volgraph
    args y touse volp rser gname withr
    if ("`gname'"=="") local gname "urv_vol"
    tempvar tt
    qui gen double `tt' = _n if `touse'
    if (`withr' & "`rser'"!="") {
        qui twoway (line `volp' `tt' if `touse', lcolor(navy) lwidth(medthick)), ///
            name(`gname'_v, replace) nodraw ///
            title("Estimated volatility path", size(medsmall)) ///
            ytitle("{&sigma}{sub:t}") xtitle("observation") ///
            scheme(s2color) graphregion(color(white))
        qui twoway (line `y' `tt' if `touse', lcolor(navy)) ///
            (line `rser' `tt' if `touse', lcolor(cranberry) lpattern(dash) yaxis(2)), ///
            name(`gname'_s, replace) nodraw ///
            title("Original vs. rescaled series", size(medsmall)) ///
            legend(order(1 "original" 2 "rescaled") size(vsmall) rows(1)) ///
            ytitle("original") ytitle("rescaled", axis(2)) xtitle("observation") ///
            scheme(s2color) graphregion(color(white))
        graph combine `gname'_v `gname'_s, name(`gname', replace) ///
            title("Beare (2017) rescaled PP diagnostics", size(medium)) ///
            graphregion(color(white))
    }
    else {
        qui twoway (line `volp' `tt' if `touse', lcolor(navy) lwidth(medthick)), ///
            name(`gname', replace) ///
            title("Estimated volatility path {&sigma}{sub:t}", size(medsmall)) ///
            ytitle("{&sigma}{sub:t}") xtitle("observation") ///
            scheme(s2color) graphregion(color(white))
    }
end

program define _urv_bootgraph
    args stat gname title statlab
    if ("`gname'"=="") local gname "urv_boot"
    capture confirm matrix __urv_bootdist
    if (_rc) exit
    preserve
        qui drop _all
        qui svmat double __urv_bootdist, name(bstat)
        qui twoway (histogram bstat1, bin(40) color(navy%55) freq), ///
            name(`gname', replace) ///
            xline(`stat', lcolor(cranberry) lwidth(thick)) ///
            title("`title'", size(medsmall)) ///
            subtitle("red line = observed statistic", size(vsmall)) ///
            legend(off) xtitle("`statlab'") ytitle("frequency") ///
            scheme(s2color) graphregion(color(white))
    restore
    capture matrix drop __urv_bootdist
end

*===============================================================================
* Mata engines
*===============================================================================
version 14.0
mata:

// ----- OLS: returns coefficient vector b (k x 1) -----
real colvector urv_b(real colvector y, real matrix X)
{
    real matrix XXi
    XXi = invsym(cross(X,X))
    return(XXi*cross(X,y))
}

// ----- build deterministic matrix over a length-m index (1..m mapped to times) -----
// det: 0 none, 1 const, 2 const+trend ; returns m x k (k=0,1,2)
real matrix urv_det(real scalar m, real scalar det)
{
    real colvector one, tt
    if (det==0) {
        return(J(m,0,.))
    }
    one = J(m,1,1)
    if (det==1) {
        return(one)
    }
    tt = (1::m)
    return((one, tt))
}

// ----- lag matrix of a column vector: columns are L1..Lp, rows aligned to x -----
// returns m x p with missing rows (first p) later trimmed by caller
real matrix urv_lagmat(real colvector x, real scalar p)
{
    real matrix L
    real scalar j, m
    m = rows(x)
    if (p<=0) {
        return(J(m,0,.))
    }
    L = J(m,p,.)
    for (j=1; j<=p; j++) {
        L[(j+1)::m, j] = x[1::(m-j)]
    }
    return(L)
}

// ----- ADF regression on a series x with det terms and p lagged diffs -----
// returns rowvector: (stat_t, stat_rho, ssr, k_params, nobs)
// istat unused here; both returned
real rowvector urv_adf(real colvector x, real scalar det, real scalar p)
{
    real colvector dx, y, ylag, b, e
    real matrix D, Lag, X
    real scalar m, nobs, s2, serho, tstat, rho, kk
    real matrix XXi
    m = rows(x)
    dx = x[2::m] - x[1::(m-1)]              // length m-1, index t=2..m
    ylag = x[1::(m-1)]                       // x_{t-1}
    // lagged differences of dx
    Lag = urv_lagmat(dx, p)                  // (m-1) x p
    // trim first p rows
    y = dx[(p+1)::(m-1)]
    ylag = ylag[(p+1)::(m-1)]
    nobs = rows(y)
    D = urv_det(nobs, det)
    if (p>0) {
        X = (ylag, Lag[(p+1)::(m-1), .], D)
    }
    else {
        X = (ylag, D)
    }
    kk = cols(X)
    XXi = invsym(cross(X,X))
    b = XXi*cross(X,y)
    e = y - X*b
    s2 = (e'e)/(nobs-kk)
    rho = b[1]                                // theta = alpha-1 coefficient
    serho = sqrt(s2*XXi[1,1])
    tstat = rho/serho
    return((tstat, nobs*rho, e'e, kk, nobs))
}

// ----- IC-based lag selection for ADF; returns chosen p -----
real scalar urv_seladf(real colvector x, real scalar det, real scalar pmax, real scalar iic)
{
    real scalar p, best, bp, m, val, ll, k, n0, tau0
    real rowvector r
    if (iic==0 | pmax<=0) {
        if (pmax<0) return(0)
        return(pmax)
    }
    best = .
    bp = 0
    // fix the estimation sample at pmax so IC values are comparable
    for (p=0; p<=pmax; p++) {
        r = urv_adf_fixed(x, det, p, pmax)
        n0 = r[5]
        if (n0<=0) continue
        ll = n0*ln(r[3]/n0)
        k = r[4]
        if (iic==1) {
            val = ll + 2*k
        }
        else if (iic==2) {
            val = ll + ln(n0)*k
        }
        else {
            // MAIC (Ng-Perron): penalty uses tau0 = (theta^2)*sum ylag^2 / s2
            tau0 = r[6]
            val = ll + 2*(tau0 + p)
        }
        if (val<best) {
            best = val
            bp = p
        }
    }
    return(bp)
}

// ----- ADF with sample fixed to start at pmax+2 (for comparable IC), returns
//       (tstat, nobs*rho, ssr, kparams, nobs, maic_tau0) -----
real rowvector urv_adf_fixed(real colvector x, real scalar det, real scalar p, real scalar pmax)
{
    real colvector dx, y, ylag, b, e
    real matrix D, Lag, X, XXi
    real scalar m, nobs, s2, kk, start, sylag, tau0
    m = rows(x)
    if (pmax+3 >= m) {
        return((., ., ., 1, 0, .))
    }
    dx = x[2::m] - x[1::(m-1)]
    ylag = x[1::(m-1)]
    Lag = urv_lagmat(dx, p)
    start = pmax+1                            // common first usable row in dx-index
    y = dx[(start+1)::(m-1)]                  // align to pmax
    ylag = ylag[(start+1)::(m-1)]
    nobs = rows(y)
    D = urv_det(nobs, det)
    if (p>0) {
        X = (ylag, Lag[(start+1)::(m-1), .], D)
    }
    else {
        X = (ylag, D)
    }
    kk = cols(X)
    XXi = invsym(cross(X,X))
    b = XXi*cross(X,y)
    e = y - X*b
    s2 = (e'e)/(nobs-kk)
    sylag = cross(ylag,ylag)
    tau0 = (b[1]^2)*sylag/s2
    return((b[1]/sqrt(s2*XXi[1,1]), nobs*b[1], e'e, kk, nobs, tau0))
}

// ----- wild multiplier draws, length m, scheme iwild -----
real colvector urv_wild(real scalar m, real scalar iwild)
{
    real colvector z, u
    if (iwild==1) {
        u = runiform(m,1)
        z = J(m,1,1)
        z = z - 2*(u:<0.5)                    // +1 / -1
        return(z)
    }
    if (iwild==2) {
        return(rnormal(m,1,0,1))
    }
    // Mammen two-point
    real scalar phi5, pa, va, vb, pp
    phi5 = sqrt(5)
    pa = (phi5+1)/(2*phi5)
    va = -(phi5-1)/2
    vb =  (phi5+1)/2
    u = runiform(m,1)
    z = J(m,1,vb)
    z = z + (u:<pa):*(va-vb)
    return(z)
}

// ----- WBDF engine -----
void urv_wbdf(string scalar yv, string scalar tv, real scalar det,
              real scalar lagfix, real scalar pmax, real scalar iic,
              real scalar reps, real scalar iwild, real scalar istat)
{
    real colvector x, dx, ehat, xstar, z, bdist
    real matrix D
    real scalar m, p, b, nobs, statobs, cnt, sidx
    real rowvector r
    real colvector edet, mu
    x = st_data(., yv, tv)
    m = rows(x)
    // choose lags
    if (lagfix>=0) {
        p = lagfix
    }
    else {
        p = urv_seladf(x, det, pmax, iic)
    }
    // observed statistic
    r = urv_adf(x, det, p)
    if (istat==1) {
        statobs = r[1]
    }
    else {
        statobs = r[2]
    }
    // restricted residuals under H0: regress dx on det(diff) only, resid
    dx = x[2::m] - x[1::(m-1)]
    // deterministics in the differenced null model: none->none; const->const;
    // trend->const (a trend in levels => constant drift in differences)
    real scalar ddet
    ddet = 0
    if (det>=1) ddet = 1
    if (ddet==1) {
        D = J(rows(dx),1,1)
        mu = urv_b(dx, D)
        ehat = dx - D*mu
    }
    else {
        ehat = dx
    }
    // bootstrap
    bdist = J(reps,1,.)
    cnt = 0
    for (b=1; b<=reps; b++) {
        z = urv_wild(rows(ehat), iwild)
        xstar = J(m,1,0)
        xstar[2::m] = runningsum(ehat:*z)
        if (lagfix>=0) {
            r = urv_adf(xstar, det, p)
        }
        else {
            real scalar pb
            pb = urv_seladf(xstar, det, pmax, iic)
            r = urv_adf(xstar, det, pb)
        }
        if (istat==1) {
            bdist[b] = r[1]
        }
        else {
            bdist[b] = r[2]
        }
        if (bdist[b] <= statobs) cnt = cnt + 1
    }
    st_numscalar("__urv_stat", statobs)
    st_numscalar("__urv_p", cnt/reps)
    st_numscalar("__urv_lused", p)
    st_numscalar("__urv_neff", r[5])
    st_matrix("__urv_bootdist", bdist)
}

// ----- Gaussian-kernel Nadaraya-Watson volatility over increments -----
// inc: m x 1 increments; uhat2: squared (detrended) increments; h bandwidth
// returns m x 1 sigma (sd) evaluated at r=s/m
real colvector urv_nwvol(real colvector uhat2, real scalar h)
{
    real scalar m, s, bw
    real colvector idx, sig, w
    m = rows(uhat2)
    idx = (1::m)
    sig = J(m,1,.)
    bw = m*h
    for (s=1; s<=m; s++) {
        w = exp(-0.5*((idx :- s):/bw):^2)
        sig[s] = sqrt( (w'uhat2)/colsum(w) )
    }
    return(sig)
}

// ----- HAC (Bartlett) long-run variance of residuals e -----
real scalar urv_hac(real colvector e, real scalar M)
{
    real scalar n, g0, lam, k, wk, gk
    n = rows(e)
    g0 = (e'e)/n
    lam = g0
    for (k=1; k<=M; k++) {
        wk = 1 - k/(M+1)
        gk = (e[(k+1)::n]' * e[1::(n-k)])/n
        lam = lam + 2*wk*gk
    }
    return(lam)
}

// ----- compute Beare rescaled-PP statistics on a level series x -----
// returns (zalpha, zt)
real rowvector urv_beare_stat(real colvector x, real scalar det,
                              real scalar h, real scalar M, real colvector sigout,
                              real scalar wantpath)
{
    real scalar m, T, ybar, xbar, Sxx, Sxy, phi, s2, lam, za, zt, sst, DFt, serho
    real colvector dx, uinc, uhat2, sig, rinc, ystar, Yr, Xr, e
    real scalar slope
    T = rows(x)
    dx = x[2::T] - x[1::(T-1)]                // m = T-1 increments, s=1..m
    m = rows(dx)
    // detrended increments for volatility estimate
    if (det==2) {
        slope = (x[T]-x[1])/m
        uinc = dx :- slope
    }
    else if (det==1) {
        uinc = dx :- mean(dx)
    }
    else {
        uinc = dx
    }
    uhat2 = uinc:^2
    sig = urv_nwvol(uhat2, h)
    if (wantpath) {
        sigout[.] = (sig[1] \ sig)           // length T aligned to levels
    }
    // rescaled increments (numerator: raw dx, or SP-detrended for trend)
    if (det==2) {
        rinc = (dx :- slope):/sig
    }
    else {
        rinc = dx:/sig
    }
    ystar = 0 \ runningsum(rinc)             // length T, ystar_0=0
    // PP regression of ystar_t on ystar_{t-1} (+ constant when det>=1)
    Yr = ystar[2::(T)]
    Xr = ystar[1::(T-1)]
    if (det>=1) {
        ybar = mean(Yr)
        xbar = mean(Xr)
    }
    else {
        ybar = 0
        xbar = 0
    }
    Sxx = cross(Xr:-xbar, Xr:-xbar)
    Sxy = cross(Xr:-xbar, Yr:-ybar)
    phi = Sxy/Sxx
    e = (Yr:-ybar) - phi*(Xr:-xbar)
    s2 = (e'e)/rows(e)
    lam = urv_hac(e, M)
    // Z-alpha (Cavaliere 2004 eq 6)
    za = m*(phi-1) - ((lam - s2)/2)/(Sxx/m^2)
    // Z-t
    serho = sqrt(s2/Sxx)
    DFt = (phi-1)/serho
    zt = sqrt(s2/lam)*DFt - ((lam - s2)/2)/(sqrt(lam)*sqrt(Sxx)/m)
    return((za, zt))
}

// ----- Beare engine (with optional wild bootstrap p-values) -----
void urv_beare(string scalar yv, string scalar tv, real scalar det,
               real scalar h, real scalar M, real scalar dobs, real scalar reps,
               string scalar volv, string scalar rserv)
{
    real colvector x, sigpath, rpath, dx, uinc, ehat, z, xstar, sigd
    real scalar T, m, b, ca, ct, slope
    real rowvector robs, rb
    real matrix S
    x = st_data(., yv, tv)
    T = rows(x)
    sigpath = J(T,1,.)
    robs = urv_beare_stat(x, det, h, M, sigpath, 1)
    // write volatility path and rescaled series to Stata vars
    st_store(., volv, tv, sigpath)
    // rescaled series for the plot
    dx = x[2::T] - x[1::(T-1)]
    m = rows(dx)
    if (det==2) {
        slope = (x[T]-x[1])/m
        uinc = dx :- slope
    }
    else if (det==1) {
        uinc = dx :- mean(dx)
    }
    else {
        uinc = dx
    }
    sigd = urv_nwvol(uinc:^2, h)
    if (det==2) {
        rpath = 0 \ runningsum((dx:-slope):/sigd)
    }
    else {
        rpath = 0 \ runningsum(dx:/sigd)
    }
    st_store(., rserv, tv, rpath)
    st_numscalar("__urv_zalpha", robs[1])
    st_numscalar("__urv_zt", robs[2])
    st_numscalar("__urv_neff", m)
    // p-values
    if (dobs==0) {
        st_numscalar("__urv_pza", .)
        st_numscalar("__urv_pzt", .)
        return
    }
    // restricted residuals under H0 for wild bootstrap
    if (det>=1) {
        ehat = dx :- mean(dx)
    }
    else {
        ehat = dx
    }
    ca = 0
    ct = 0
    real colvector sigdummy
    for (b=1; b<=reps; b++) {
        z = urv_wild(m, 1)
        xstar = J(T,1,0)
        xstar[2::T] = runningsum(ehat:*z)
        sigdummy = J(T,1,.)
        rb = urv_beare_stat(xstar, det, h, M, sigdummy, 0)
        if (rb[1] <= robs[1]) ca = ca + 1
        if (rb[2] <= robs[2]) ct = ct + 1
    }
    st_numscalar("__urv_pza", ca/reps)
    st_numscalar("__urv_pzt", ct/reps)
}

// ----- double-sided exponential-kernel volatility on residual index -----
// ehat2: r x 1 squared residuals at consecutive times; N window; returns r x 1 sigma2
real colvector urv_expvol(real colvector ehat2, real scalar N)
{
    real scalar r, t, s, num, den, w
    real colvector sig2, idx
    r = rows(ehat2)
    sig2 = J(r,1,.)
    for (t=1; t<=r; t++) {
        num = 0
        den = 0
        for (s=1; s<=r; s++) {
            w = exp(-5*abs((s-t)/N))
            num = num + w*ehat2[s]
            den = den + w
        }
        sig2[t] = num/den
    }
    return(sig2)
}

// ----- leave-one-out CV to choose window N over a grid -----
real scalar urv_cvN(real colvector ehat2, real scalar Nlo, real scalar Nhi)
{
    real scalar N, best, bN, r, t, cv, wtt, den, e2
    real colvector sig2
    r = rows(ehat2)
    best = .
    bN = Nlo
    for (N=Nlo; N<=Nhi; N++) {
        sig2 = urv_expvol(ehat2, N)
        cv = 0
        for (t=1; t<=r; t++) {
            den = 0
            real scalar s
            for (s=1; s<=r; s++) {
                den = den + exp(-5*abs((s-t)/N))
            }
            wtt = 1/den                       // k(0)=1
            e2 = (ehat2[t]-sig2[t])/(1-wtt)
            cv = cv + e2^2
        }
        if (cv<best) {
            best = cv
            bN = N
        }
    }
    return(bN)
}

// ----- compute BZ adaptive-LR t-statistic given series x, sigma path, det, p, cbar
// sig2full aligned to full level index 1..T ; returns the delta t-stat
real scalar urv_bzstat(real colvector x, real colvector sig2full, real scalar det,
                       real scalar p, real scalar cbar)
{
    real scalar T, cn, i, k, nobs, s2, tstat
    real colvector d1, dd, dY, Xd, dXd, y, ylag, b, e, w
    real matrix Dm, dDm, Zq, Xreg, XXi
    real colvector mu
    T = rows(x)
    cn = cbar/T
    // GLS demeaning (eq 5.2) using quasi-differences weighted by 1/sig2
    if (det==0) {
        Xd = x
    }
    else {
        // deterministic matrix d_t (T x kd), with d_0=0 convention
        if (det==1) {
            Dm = J(T,1,1)
        }
        else {
            Dm = (J(T,1,1), (1::T))
        }
        real scalar kd
        kd = cols(Dm)
        // quasi-differenced regression: t=1 special (level), t>=2 differences
        // build weighted normal equations
        real matrix A
        real colvector g
        A = J(kd,kd,0)
        g = J(kd,1,0)
        for (i=1; i<=T; i++) {
            real rowvector dt_, dtm_, qd_
            real scalar qy_, wgt
            if (i==1) {
                dt_ = Dm[1,.]
                qd_ = dt_                       // Delta d_1 = d_1
                qy_ = x[1]                       // Delta Y_1 = Y_1
                wgt = 1/sig2full[1]
            }
            else {
                dt_  = Dm[i,.]
                dtm_ = Dm[i-1,.]
                qd_ = dt_ - cn*dtm_
                qy_ = x[i] - cn*x[i-1]
                wgt = 1/sig2full[i]
            }
            A = A + wgt*(qd_'qd_)
            g = g + wgt*(qd_'qy_)
        }
        mu = invsym(A)*g
        Xd = x - Dm*mu
    }
    // weighted LS (eq 5.6): dXd_t/sig = delta Xd_{t-1}/sig + sum gamma_j dXd_{t-j}/sig
    dXd = Xd[2::T] - Xd[1::(T-1)]              // index t=2..T
    // lags of dXd
    real matrix Lag
    real scalar plag
    plag = p-1
    if (plag<0) plag = 0
    Lag = urv_lagmat(dXd, plag)
    // align: need Xd_{t-1} and p-1 lags of dXd
    real scalar start
    start = (p-1)                              // first usable dXd row index (1-based in dXd) = p
    if (start<0) start = 0
    y = dXd[(start+1)::rows(dXd)]
    ylag = Xd[(start+1)::(T-1)]                 // Xd_{t-1} aligned
    w = sig2full[(start+2)::T]                  // sigma^2 at time t (t = start+2..T)
    // weights 1/sigma
    real colvector iw
    iw = 1:/sqrt(w)
    nobs = rows(y)
    if (p-1>0) {
        Xreg = (ylag, Lag[(start+1)::rows(dXd), .])
    }
    else {
        Xreg = ylag
    }
    // apply weights
    real colvector yw
    real matrix Xw
    yw = y:*iw
    Xw = Xreg:*iw
    XXi = invsym(cross(Xw,Xw))
    b = XXi*cross(Xw,yw)
    e = yw - Xw*b
    k = cols(Xw)
    s2 = (e'e)/(nobs-k)
    tstat = b[1]/sqrt(s2*XXi[1,1])
    return(tstat)
}

// ----- BZU engine -----
void urv_bzu(string scalar yv, string scalar tv, real scalar det,
             real scalar lagfix, real scalar pmax, real scalar iic,
             real scalar winfix, real scalar cbar, real scalar reps,
             string scalar volv)
{
    real colvector x, dy, ehat, ehat2, sig2res, sig2full, z, ystar, dystar
    real scalar T, p, N, Nlo, Nhi, i, b, cnt, lrobs, m, r0
    real matrix Dd, Lag, Xr
    real colvector bcoef, gamma0, mu0
    x = st_data(., yv, tv)
    T = rows(x)
    dy = x[2::T] - x[1::(T-1)]                 // t=2..T
    m = rows(dy)
    // choose p (AR order for levels; AR(p-1) for dy)
    if (lagfix>=0) {
        p = lagfix
        if (p<1) p = 1
    }
    else {
        p = urv_seladf(x, det, pmax, iic)
        if (p<1) p = 1
    }
    // Step 1: AR(p-1) residuals of dy with constant if trend
    real matrix Ld, Xd1
    real colvector yd1, bd1, cst
    Ld = urv_lagmat(dy, p-1)
    yd1 = dy[(p)::m]                           // align: first usable row = p (needs p-1 lags)
    real scalar r0n
    r0n = rows(yd1)
    if (det==2) {
        cst = J(r0n,1,1)
    }
    else {
        cst = J(r0n,0,.)
    }
    if (p-1>0) {
        Xd1 = (Ld[(p)::m,.], cst)
    }
    else {
        Xd1 = cst
    }
    if (cols(Xd1)>0) {
        bd1 = urv_b(yd1, Xd1)
        ehat = yd1 - Xd1*bd1
    }
    else {
        bd1 = J(0,1,.)
        ehat = yd1
    }
    ehat2 = ehat:^2                            // residual index tau=1..r0n  (time p+1..T)
    r0 = rows(ehat2)
    // Step: volatility window by LOO-CV
    if (winfix>0) {
        N = winfix
    }
    else {
        Nlo = max((2, floor(0.03*r0)))
        Nhi = max((Nlo+1, floor(0.5*r0)))
        if (Nhi>r0-1) Nhi = r0-1
        N = urv_cvN(ehat2, Nlo, Nhi)
    }
    sig2res = urv_expvol(ehat2, N)             // sigma^2 at times p+1..T
    // map to full level index 1..T (backfill first p with first value)
    sig2full = J(T,1,.)
    for (i=1; i<=T; i++) {
        if (i<=p) {
            sig2full[i] = sig2res[1]
        }
        else {
            sig2full[i] = sig2res[i-p]
        }
    }
    // write volatility SD path
    st_store(., volv, tv, sqrt(sig2full))
    // observed statistic
    lrobs = urv_bzstat(x, sig2full, det, p, cbar)
    // Step 4: wild bootstrap. Reuse sig2full, p, N (paper). Recompute mu, t-stat on Y*.
    // AR(p-1) coefficients for dy under unit root (gamma_j) + constant
    real colvector gam
    real scalar cc
    cc = 0
    if (p-1>0) {
        gam = bd1[1::(p-1)]
    }
    else {
        gam = J(0,1,.)
    }
    if (det==2) {
        cc = bd1[rows(bd1)]
    }
    cnt = 0
    real colvector dyb, xb
    for (b=1; b<=reps; b++) {
        z = urv_wild(r0, 1)
        real colvector estar
        estar = ehat:*z                         // length r0 (times p+1..T)
        // regenerate dy* via AR(p-1): dyb_t = cc + sum gam_j dyb_{t-j} + estar
        dyb = J(m,1,0)
        // seed first p-1 diffs with the original dy (so Y*_1..Y*_p = Y_1..Y_p)
        for (i=1; i<=m; i++) {
            if (i<=p-1) {
                dyb[i] = dy[i]
            }
            else {
                real scalar acc, j
                acc = cc
                for (j=1; j<=p-1; j++) {
                    acc = acc + gam[j]*dyb[i-j]
                }
                // estar index: dyb index i corresponds to time i+1; residual time p+1 => i=p
                real scalar ei
                ei = i-(p-1)
                if (ei>=1) {
                    if (ei<=r0) {
                        acc = acc + estar[ei]
                    }
                }
                dyb[i] = acc
            }
        }
        xb = J(T,1,0)
        xb[1] = x[1]
        xb[2::T] = x[1] :+ runningsum(dyb)
        real scalar lrb
        lrb = urv_bzstat(xb, sig2full, det, p, cbar)
        if (lrb <= lrobs) cnt = cnt + 1
    }
    st_numscalar("__urv_lr", lrobs)
    st_numscalar("__urv_p", cnt/reps)
    st_numscalar("__urv_lused", p)
    st_numscalar("__urv_win", N)
    st_numscalar("__urv_neff", m)
    st_matrix("__urv_bootdist", J(1,1,.))
}

end
