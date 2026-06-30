*! xtmunitroot version 1.1.0  28jun2026
*! Panel unit root tests with missing values (+ unknown-break inf-t bootstrap)
*! Karavias, Tzavalis & Zhang (2022, Econometrics 10(1):12) <doi:10.3390/econometrics10010012>
*! Author: Merwan Roudane (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

program define xtmunitroot, rclass
    version 14.0

    syntax varname(numeric) [if] [in] [ ,         ///
        Model(string)                             ///
        METHod(string)                            ///
        BReak(string)                             ///
        BReps(integer 399)                        ///
        TRim(real 0.15)                           ///
        SEED(string)                              ///
        Level(cilevel)                            ///
        GRAPH                                     ///
        name(string) ]

    // ------------------------------------------------------------------
    // 1. Parse the deterministic specification (models 1-4 of the paper)
    // ------------------------------------------------------------------
    if ("`model'"=="") local model "intercept"
    local model = lower("`model'")
    if inlist("`model'","intercept","i","none","constant","c") {
        local mcode 1
        local mname "Individual intercepts"
    }
    else if inlist("`model'","trend","t","linear") {
        local mcode 2
        local mname "Intercepts + individual trends"
    }
    else if inlist("`model'","break","b","sbreak") {
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

    // ------------------------------------------------------------------
    // 2. Parse the missing-value handling method
    // ------------------------------------------------------------------
    if ("`method'"=="") local method "zeroout"
    local method = lower("`method'")
    if inlist("`method'","zeroout","zero","z","closing","gaps","drop") {
        local mlist "1"
        local single 1
    }
    else if inlist("`method'","previous","prev","p","lastvalue","carry") {
        local mlist "2"
        local single 1
    }
    else if inlist("`method'","linear","lin","l","interp","interpolation") {
        local mlist "3"
        local single 1
    }
    else if inlist("`method'","all","compare","a") {
        local mlist "1 2 3"
        local single 0
    }
    else {
        di as error "method() must be {bf:zeroout}, {bf:previous}, {bf:linear} or {bf:all}"
        exit 198
    }

    // ------------------------------------------------------------------
    // 3. Panel structure (read from xtset, quote string r() results)
    // ------------------------------------------------------------------
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data are not {bf:xtset}; type {bf:xtset panelvar timevar} first"
        exit 459
    }

    marksample touse
    markout `touse' `ivar' `tvar'
    qui count if `touse'
    if (r(N)==0) {
        di as error "no observations"
        exit 2000
    }

    // common time grid t = tmin..tmax  (T+1 points, T equations)
    qui su `tvar' if `touse', meanonly
    local tmin = r(min)
    local tmax = r(max)
    local Tplus1 = `tmax' - `tmin' + 1
    local T = `Tplus1' - 1
    if (`Tplus1' < 3) {
        di as error "need at least 3 time periods on the grid"
        exit 198
    }

    tempvar gid ti
    qui egen long `gid' = group(`ivar') if `touse'
    qui gen long `ti'   = `tvar' - `tmin' + 1 if `touse'
    qui su `gid' if `touse', meanonly
    local Nunits = r(max)

    // ------------------------------------------------------------------
    // 4. Break point (equation index kb) for models 3 and 4
    // ------------------------------------------------------------------
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
            // admissible single-break equation grid, trimmed at both ends
            local kbmin = ceil(`trim'*`T')
            local kbmax = floor((1-`trim')*`T')
            if (`mcode'==4) {
                if (`kbmin'<3)      local kbmin 3
                if (`kbmax'>`T'-3)  local kbmax = `T'-3
            }
            else {
                if (`kbmin'<1)      local kbmin 1
                if (`kbmax'>`T'-1)  local kbmax = `T'-1
            }
            if (`kbmin'>`kbmax') {
                di as error "trim(`trim') leaves no admissible break dates for T=`T'"
                exit 198
            }
            local ngrid = `kbmax' - `kbmin' + 1
            local bdesc "unknown (inf-t searched over `ngrid' dates)"
            if (`single'==0) {
                di as error "method(all) is not supported with break(unknown); pick one method"
                exit 198
            }
        }
        else if (real("`break'")<1 & real("`break'")>0) {
            local kb = floor(real("`break'")*`T')
            local btime = `tmin' + `kb'
            local bdesc "fraction `break' (date `btime')"
        }
        else if (real("`break'")!=.) {
            local btime = real("`break'")
            local kb = `btime' - `tmin'
            local bdesc "date `btime'"
        }
        else {
            di as error "break() must be a date, a fraction in (0,1), or {bf:unknown}"
            exit 198
        }
        if (`unknown'==0 & (`kb'<1 | `kb'>`T'-1)) {
            di as error "break point falls outside the usable range of the time grid"
            exit 198
        }
    }

    // ==================================================================
    //  UNKNOWN-BREAK BRANCH (inf-t search + KT2019 bootstrap)
    // ==================================================================
    if (`unknown'==1) {
        if ("`seed'"!="") set seed `seed'
        local fc : word 1 of `mlist'
        tempname UB PROF
        mata: xtmur_ubreak("`varlist'","`gid'","`ti'","`touse'", `Tplus1', ///
            `mcode', `kbmin', `kbmax', `fc', `breps', `tmin', "`UB'", "`PROF'")
        local rho    = `UB'[1,1]
        local bias   = `UB'[1,2]
        local infstat= `UB'[1,3]
        local pboot  = `UB'[1,4]
        local Nused  = `UB'[1,5]
        local Ndrop  = `UB'[1,6]
        local nmiss  = `UB'[1,7]
        local Teq    = `UB'[1,8]
        local kbhat  = `UB'[1,9]
        local cv05   = `UB'[1,10]
        local cv10   = `UB'[1,11]
        local cv01   = `UB'[1,12]
        local bdate  = `tmin' + `kbhat'
        local totcell = `Nunits'*`Tplus1'
        local misspct = 100*`nmiss'/`totcell'
        local star ""
        if (`pboot'<0.10) local star "*"
        if (`pboot'<0.05) local star "**"
        if (`pboot'<0.01) local star "***"

        di ""
        di as txt "{hline 72}"
        di as txt "  Panel unit root test, structural break at an UNKNOWN date"
        di as txt "  inf-t statistic; bootstrap critical values (Karavias & Tzavalis 2019)"
        di as txt "{hline 72}"
        di as txt "  Panel variable          : " as res "`ivar'" as txt "   (N = " as res `Nunits' as txt ")"
        di as txt "  Time variable           : " as res "`tvar'" as txt "   (grid `tmin'..`tmax', T = " as res `Teq' as txt ")"
        di as txt "  Series tested           : " as res "`varlist'"
        di as txt "  Deterministics          : " as res "`mname'"
        di as txt "  Missing-value method     : " as res "`method'"
        di as txt "  Missing cells            : " as res %6.0f `nmiss' as txt " of " as res `totcell' ///
            as txt "  (" as res %4.1f `misspct' as txt "%)"
        di as txt "  Units used / dropped     : " as res `Nused' as txt " / " as res `Ndrop'
        di as txt "  Bootstrap replications   : " as res `breps'
        di as txt "{hline 72}"
        di as txt "  H0: unit root, no break   vs   H1: stationary with a break (unknown date)"
        di as txt "{hline 72}"
        di as txt "  Estimated break date    : " as res "`bdate'" as txt "   (equation index `kbhat')"
        di as txt "  inf-t statistic         : " as res %9.4f `infstat' as result "`star'"
        di as txt "  Bootstrap p-value       : " as res %9.4f `pboot'
        di as txt "  Bootstrap crit. values  : " as txt "10% " as res %7.3f `cv10' ///
            as txt "   5% " as res %7.3f `cv05' as txt "   1% " as res %7.3f `cv01'
        di as txt "{hline 72}"
        di as txt "  Reject H0 if inf-t < critical value (left tail).  * 10%  ** 5%  *** 1%"
        di as txt "{hline 72}"

        return local cmd     "xtmunitroot"
        return local depvar  "`varlist'"
        return local ivar    "`ivar'"
        return local tvar    "`tvar'"
        return local model   "`model'"
        return local method  "`method'"
        return local break   "unknown"
        return scalar N       = `Nunits'
        return scalar T       = `Teq'
        return scalar N_used  = `Nused'
        return scalar N_drop  = `Ndrop'
        return scalar n_miss  = `nmiss'
        return scalar infstat = `infstat'
        return scalar p       = `pboot'
        return scalar kbreak  = `kbhat'
        return scalar bdate   = `bdate'
        return scalar cv05    = `cv05'
        return scalar reps    = `breps'
        matrix colnames `PROF' = kindex date tstat
        return matrix profile = `PROF'

        if ("`graph'"!="") {
            if ("`name'"=="") local name "xtmunitroot"
            capture noisily xtmur_ugraph "`PROF'" `infstat' `cv05' "`bdate'" "`name'" "`mname'"
            if (_rc) di as txt "(graph step skipped: _rc=" _rc ")"
        }
        exit
    }

    // ==================================================================
    //  KNOWN-BREAK / NO-BREAK BRANCH
    // ==================================================================
    // 5. Run the engine for each requested method
    tempname RES
    matrix `RES' = J(3,8,.)
    local mnames `" "Zeroing-out (closing gaps)" "Previous value" "Linear interpolation" "'

    foreach c of local mlist {
        tempname r`c'
        mata: xtmur_engine("`varlist'","`gid'","`ti'","`touse'", `Tplus1', `mcode', `kb', `c', "`r`c''")
        matrix `RES'[`c',1] = `r`c''
    }

    // 6. Display
    // counts come back identical across methods; read from the first run
    local fc : word 1 of `mlist'
    local Nused  = `RES'[`fc',5]
    local Ndrop  = `RES'[`fc',6]
    local nmiss  = `RES'[`fc',7]
    local Teq    = `RES'[`fc',8]
    local totcell = `Nunits'*`Tplus1'
    local misspct = 100*`nmiss'/`totcell'

    di ""
    di as txt "{hline 72}"
    di as txt "  Panel unit root test with missing values"
    di as txt "  Karavias, Tzavalis & Zhang (2022, {it:Econometrics})"
    di as txt "{hline 72}"
    di as txt "  Panel variable          : " as res "`ivar'" as txt "   (N = " as res `Nunits' as txt ")"
    di as txt "  Time variable           : " as res "`tvar'" as txt "   (grid `tmin'..`tmax', T = " as res `Teq' as txt " equations)"
    di as txt "  Series tested           : " as res "`varlist'"
    di as txt "  Deterministics          : " as res "`mname'"
    if (`mcode'>=3) di as txt "  Structural break        : " as res "`bdesc'"
    di as txt "  Missing cells            : " as res %6.0f `nmiss' as txt " of " as res `totcell' ///
        as txt "  (" as res %4.1f `misspct' as txt "%)"
    di as txt "  Units used / dropped     : " as res `Nused' as txt " / " as res `Ndrop'
    di as txt "{hline 72}"
    di as txt "  H0: panel has a unit root (rho = 1)   vs   H1: stationary (rho < 1)"
    di as txt "{hline 72}"
    di as txt "  Method                       rho(adj)     bias      z-stat   p-value"
    di as txt "  {hline 68}"

    foreach c of local mlist {
        local nm : word `c' of `mnames'
        local rho  = `RES'[`c',1]
        local bias = `RES'[`c',2]
        local z    = `RES'[`c',3]
        local p    = `RES'[`c',4]
        local star ""
        if (`p'<0.10) local star "*"
        if (`p'<0.05) local star "**"
        if (`p'<0.01) local star "***"
        local rhoadj = `rho' - `bias'
        di as txt "  " %-26s "`nm'" as res ///
            %9.4f `rhoadj' "  " %8.4f `bias' "  " %9.4f `z' "  " %7.4f `p' as result "`star'"
    }
    di as txt "  {hline 68}"
    di as txt "  Significance of rejecting the unit-root null:  * 10%   ** 5%   *** 1%"
    if (`single'==0) {
        di as txt "  Higher power = more negative z / smaller p. The paper shows zeroing-out"
        di as txt "  dominates; {it:previous} and {it:linear} are impute-then-test (see help)."
    }
    di as txt "{hline 72}"

    // ------------------------------------------------------------------
    // 7. Returns
    // ------------------------------------------------------------------
    matrix colnames `RES' = rho bias z p N_used N_drop n_miss T_eq
    matrix rownames `RES' = zeroout previous linear

    return local cmd     "xtmunitroot"
    return local depvar  "`varlist'"
    return local ivar    "`ivar'"
    return local tvar    "`tvar'"
    return local model   "`model'"
    return local method  "`method'"
    return scalar N       = `Nunits'
    return scalar T       = `Teq'
    return scalar N_used  = `Nused'
    return scalar N_drop  = `Ndrop'
    return scalar n_miss  = `nmiss'
    if (`mcode'>=3) return scalar kbreak = `kb'

    if (`single'==1) {
        local c : word 1 of `mlist'
        return scalar rho  = `RES'[`c',1]
        return scalar bias = `RES'[`c',2]
        return scalar z    = `RES'[`c',3]
        return scalar p    = `RES'[`c',4]
    }
    return matrix results = `RES'

    // ------------------------------------------------------------------
    // 8. Visualization dashboard
    // ------------------------------------------------------------------
    if ("`graph'"!="") {
        if ("`name'"=="") local name "xtmunitroot"
        capture noisily xtmur_graph "`varlist'" "`ivar'" "`tvar'" "`gid'" "`ti'" ///
            "`touse'" `tmin' `tmax' `Nunits' "`RES'" "`mlist'" "`name'" "`mname'"
        if (_rc) di as txt "(graph step skipped: _rc=" _rc ")"
    }
end

// ======================================================================
//  Visualization helper  (defensive: capture SSC graph deps, plain fallback)
// ======================================================================
program define xtmur_graph
    args y ivar tvar gid ti touse tmin tmax N RES mlist name mname

    preserve
    quietly {
        keep if `touse'
        keep `gid' `ti' `y'
        // rectangular grid (units x time) with a missing flag
        fillin `gid' `ti'
        gen byte __miss = missing(`y')
        // ---- panel a: missingness map ----------------------------------
        local mapok 0
        capture heatplot __miss `gid' `ti', ///
            color(navy "230 230 230") cuts(-0.5 0.5 1.5) discrete ///
            xtitle("Time index") ytitle("Unit (group id)") ///
            title("Missing-value map", size(medium)) ///
            legend(off) name(`name'_map, replace) nodraw
        if (_rc==0) local mapok 1
        if (`mapok'==0) {
            twoway (scatter `gid' `ti' if __miss==0, msize(vsmall) mcolor(navy)) ///
                   (scatter `gid' `ti' if __miss==1, msize(small) mcolor(cranberry) msymbol(X)), ///
                   xtitle("Time index") ytitle("Unit (group id)") ///
                   title("Missing-value map", size(medium)) ///
                   legend(order(1 "observed" 2 "missing") rows(1) size(small)) ///
                   name(`name'_map, replace) nodraw
        }
    }
    // ---- panel b: method comparison (z-stat with 5% line) --------------
    preserve
    quietly {
        clear
        local nm = wordcount("`mlist'")
        set obs `nm'
        gen int  midx = _n
        gen str20 mlab = ""
        gen double zval = .
        gen double pval = .
        local row 0
        foreach c of local mlist {
            local ++row
            local lab : word `c' of `" "Zero-out" "Previous" "Linear" "'
            replace mlab = "`lab'"        in `row'
            replace zval = `RES'[`c',3]   in `row'
            replace pval = `RES'[`c',4]   in `row'
        }
        graph bar (asis) zval, over(mlab, sort(midx) label(angle(0) labsize(small))) ///
            bar(1, color(navy)) ///
            yline(-1.645, lpattern(dash) lcolor(cranberry)) ///
            ytitle("z-statistic") ///
            title("Test by missing-value method", size(medium)) ///
            note("dashed line = 5% one-sided critical value (-1.645)", size(vsmall)) ///
            name(`name'_z, replace) nodraw
    }
    restore
    restore

    // combine into one dashboard; drawing happens here (no fragile graph display)
    capture graph combine `name'_map `name'_z, ///
        title("xtmunitroot: `mname'", size(medium)) ///
        rows(1) name(`name', replace)
    if (_rc) {
        di as txt "(could not combine; the two panels are saved as " ///
            "{bf:`name'_map} and {bf:`name'_z})"
    }
end

// ======================================================================
//  Unknown-break profile plot: t(lambda) over candidate dates
// ======================================================================
program define xtmur_ugraph
    args PROF infstat cv05 bdate name mname

    preserve
    clear
    quietly svmat double `PROF', name(col)
    quietly gen byte __isinf = abs(tstat - `infstat') < 1e-8
    twoway (line tstat date, lcolor(navy) lwidth(medthick)) ///
           (scatter tstat date if __isinf==1, mcolor(cranberry) msize(large) msymbol(D)), ///
        yline(`cv05', lpattern(dash) lcolor(cranberry)) ///
        xtitle("Candidate break date") ytitle("t-statistic") ///
        title("inf-t break search: `mname'", size(medium)) ///
        legend(order(1 "t(break date)" 2 "inf-t (estimated break)") rows(1) size(small)) ///
        note("dashed line = 5% bootstrap critical value; estimated break at `bdate'", size(vsmall)) ///
        name(`name', replace)
    restore
end

// ======================================================================
//  Mata engine
// ======================================================================
version 14.0
mata:

// ---- build the deterministic regressor block Z (T x k) ---------------
real matrix xtmur_Z(real scalar T, real scalar model, real scalar kb)
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

    // models 3 and 4 : split deterministics at the break (equation kb)
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

// ---- carry-forward imputation (previous value) -----------------------
real matrix xtmur_impute_prev(real matrix Y, real scalar N, real scalar Tp)
{
    real matrix YY
    real scalar i, t

    YY = Y
    for (i=1; i<=N; i=i+1) {
        for (t=2; t<=Tp; t=t+1) {
            if (YY[i,t]==.) {
                if (YY[i,t-1]!=.) {
                    YY[i,t] = YY[i,t-1]
                }
            }
        }
    }
    return(YY)
}

// ---- linear interpolation between observed endpoints -----------------
real matrix xtmur_impute_lin(real matrix Y, real scalar N, real scalar Tp)
{
    real matrix YY
    real scalar i, t, a, b, s

    YY = Y
    for (i=1; i<=N; i=i+1) {
        t = 1
        while (t<=Tp) {
            if (YY[i,t]==.) {
                a = t-1
                while (a>=1) {
                    if (YY[i,a]!=.) {
                        break
                    }
                    a = a-1
                }
                b = t+1
                while (b<=Tp) {
                    if (YY[i,b]!=.) {
                        break
                    }
                    b = b+1
                }
                if (a>=1) {
                    if (b<=Tp) {
                        for (s=a+1; s<=b-1; s=s+1) {
                            YY[i,s] = YY[i,a] + (YY[i,b]-YY[i,a])*(s-a)/(b-a)
                        }
                        t = b
                    }
                    else {
                        t = Tp + 1
                    }
                }
                else {
                    t = b
                }
            }
            else {
                t = t + 1
            }
        }
    }
    return(YY)
}

// ---- read the panel into an N x Tplus1 level matrix (missing = .) -----
real matrix xtmur_buildY(string scalar yv, string scalar idv, string scalar tiv,
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

// ---- core estimator: returns (rho, bias, t, p, Nused, Ndrop) ----------
//      Yorig = N x Tplus1 level matrix with . for gaps (pre-imputation)
real rowvector xtmur_stat(real matrix Yorig, real scalar N, real scalar Tplus1,
                          real scalar model, real scalar kb, real scalar method)
{
    real matrix Y, Z, Lam, Lt, DZ, A, QD, M, Sm, Rm
    real colvector yfull, L, dep, dvec
    real scalar T, k, i, t, usedeq
    real scalar SXX, SXY, trLM, trLML, tSS, tSR, tRR
    real scalar Nused, Ndrop, rho, B, numAsq, Vhat, tstat, p

    T = Tplus1 - 1
    Y = Yorig
    if (method==2) {
        Y = xtmur_impute_prev(Y, N, Tplus1)
    }
    if (method==3) {
        Y = xtmur_impute_lin(Y, N, Tplus1)
    }

    Z = xtmur_Z(T, model, kb)
    k = cols(Z)

    Lam = J(T, T, 0)
    for (i=2; i<=T; i=i+1) {
        for (t=1; t<=i-1; t=t+1) {
            Lam[i,t] = 1
        }
    }
    Lt = Lam'

    SXX=0; SXY=0; trLM=0; trLML=0; tSS=0; tSR=0; tRR=0
    Nused=0; Ndrop=0

    for (i=1; i<=N; i=i+1) {
        yfull = Y[i,.]'
        dep  = J(T,1,0)
        L    = J(T,1,0)
        dvec = J(T,1,0)
        usedeq = 0
        for (t=1; t<=T; t=t+1) {
            if (yfull[t+1]!=.) {
                if (yfull[t]!=.) {
                    dep[t]  = yfull[t+1]
                    L[t]    = yfull[t]
                    dvec[t] = 1
                    usedeq  = usedeq + 1
                }
            }
        }
        if (usedeq < k+1) {
            Ndrop = Ndrop + 1
            continue
        }
        DZ = Z :* (dvec * J(1,k,1))
        if (rank(DZ) < k) {
            Ndrop = Ndrop + 1
            continue
        }
        A   = DZ' * DZ
        QD  = I(T) - DZ * invsym(A) * DZ'
        SXX = SXX + (L' * QD * L)
        SXY = SXY + (L' * QD * dep)
        M  = (dvec * dvec') :* QD
        Sm = 0.5 * (Lt*M + M*Lam)
        Rm = Lt * M * Lam
        trLM  = trLM  + trace(Lt*M)
        trLML = trLML + trace(Rm)
        tSS = tSS + trace(Sm*Sm)
        tSR = tSR + trace(Sm*Rm)
        tRR = tRR + trace(Rm*Rm)
        Nused = Nused + 1
    }

    if (Nused==0 | SXX==0 | trLML==0) {
        return((., ., ., ., Nused, Ndrop))
    }
    rho    = SXY/SXX
    B      = trLM/trLML
    numAsq = tSS - 2*B*tSR + B*B*tRR
    Vhat   = (2*numAsq/Nused) / ((trLML/Nused)^2)
    tstat  = (rho - B - 1) / sqrt(Vhat/Nused)
    p      = normal(tstat)
    return((rho, B, tstat, p, Nused, Ndrop))
}

// ---- count missing cells in the rectangular grid ---------------------
real scalar xtmur_nmiss(real matrix Y, real scalar N, real scalar Tplus1)
{
    real scalar i, t, c
    c = 0
    for (i=1; i<=N; i=i+1) {
        for (t=1; t<=Tplus1; t=t+1) {
            if (Y[i,t]==.) {
                c = c + 1
            }
        }
    }
    return(c)
}

// ---- thin wrapper for the single known/no-break statistic ------------
void xtmur_engine(string scalar yv,   string scalar idv,  string scalar tiv,
                  string scalar touse, real scalar Tplus1, real scalar model,
                  real scalar kb,     real scalar method, string scalar outname)
{
    real matrix Y
    real scalar N, T, nmiss
    real rowvector s

    Y = xtmur_buildY(yv, idv, tiv, touse, Tplus1)
    N = rows(Y)
    T = Tplus1 - 1
    nmiss = xtmur_nmiss(Y, N, Tplus1)
    s = xtmur_stat(Y, N, Tplus1, model, kb, method)
    st_matrix(outname, (s[1], s[2], s[3], s[4], s[5], s[6], nmiss, T))
}

// ---- left-tail quantile of an ascending-sorted vector ----------------
real scalar xtmur_quantile(real colvector sorted, real scalar a)
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

// ---- one bootstrap panel: null random walk, increments resampled from
//      the pooled first differences, mirroring a random unit's gaps -----
real matrix xtmur_bootY(real matrix Y, real colvector pool,
                        real scalar N, real scalar Tplus1)
{
    real matrix Yr
    real scalar P, i, j, c, idx

    P  = rows(pool)
    Yr = J(N, Tplus1, .)
    for (i=1; i<=N; i=i+1) {
        j = ceil(runiform(1,1)*N)
        if (j<1) {
            j = 1
        }
        if (j>N) {
            j = N
        }
        for (c=1; c<=Tplus1; c=c+1) {
            if (Y[j,c]==.) {
                Yr[i,c] = .
            }
            else {
                if (c==1) {
                    Yr[i,c] = 0
                }
                else {
                    if (Y[j,c-1]==.) {
                        Yr[i,c] = 0
                    }
                    else {
                        idx = ceil(runiform(1,1)*P)
                        if (idx<1) {
                            idx = 1
                        }
                        if (idx>P) {
                            idx = P
                        }
                        Yr[i,c] = Yr[i,c-1] + pool[idx]
                    }
                }
            }
        }
    }
    return(Yr)
}

// ---- unknown-break inf-t search + KT2019 bootstrap -------------------
void xtmur_ubreak(string scalar yv, string scalar idv, string scalar tiv,
                  string scalar touse, real scalar Tplus1, real scalar model,
                  real scalar kbmin, real scalar kbmax, real scalar method,
                  real scalar breps, real scalar tmin,
                  string scalar outname, string scalar profname)
{
    real matrix Y, Yr, DIFF, PROF
    real colvector pool, dall, bootinf, sorted
    real scalar N, T, nmiss, i, t, kb, gi, ng, b
    real scalar obsinf, kbhat, tval, rho, bias, Nused, Ndrop
    real scalar bi, pcount, valid, pboot, q05, q10, q01
    real rowvector s

    Y = xtmur_buildY(yv, idv, tiv, touse, Tplus1)
    N = rows(Y)
    T = Tplus1 - 1
    nmiss = xtmur_nmiss(Y, N, Tplus1)
    ng = kbmax - kbmin + 1

    // observed inf-t over the admissible break grid
    PROF = J(ng, 3, .)
    obsinf = .
    kbhat = kbmin
    rho = .; bias = .; Nused = .; Ndrop = .
    gi = 0
    for (kb=kbmin; kb<=kbmax; kb=kb+1) {
        gi = gi + 1
        s = xtmur_stat(Y, N, Tplus1, model, kb, method)
        tval = s[3]
        PROF[gi,1] = kb
        PROF[gi,2] = tmin + kb
        PROF[gi,3] = tval
        if (tval!=.) {
            if (obsinf==. | tval<obsinf) {
                obsinf = tval
                kbhat = kb
                rho = s[1]; bias = s[2]; Nused = s[5]; Ndrop = s[6]
            }
        }
    }

    // pool of observed first differences (the resampling residuals)
    DIFF = J(N, T, .)
    for (i=1; i<=N; i=i+1) {
        for (t=1; t<=T; t=t+1) {
            if (Y[i,t+1]!=.) {
                if (Y[i,t]!=.) {
                    DIFF[i,t] = Y[i,t+1] - Y[i,t]
                }
            }
        }
    }
    dall = vec(DIFF)
    pool = select(dall, dall:!=.)

    // bootstrap: re-search the inf on each null replication
    bootinf = J(breps, 1, .)
    for (b=1; b<=breps; b=b+1) {
        Yr = xtmur_bootY(Y, pool, N, Tplus1)
        bi = .
        for (kb=kbmin; kb<=kbmax; kb=kb+1) {
            s = xtmur_stat(Yr, N, Tplus1, model, kb, method)
            tval = s[3]
            if (tval!=.) {
                if (bi==. | tval<bi) {
                    bi = tval
                }
            }
        }
        bootinf[b] = bi
    }

    // p-value and left-tail critical values from the bootstrap inf
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
    q05 = xtmur_quantile(sorted, 0.05)
    q10 = xtmur_quantile(sorted, 0.10)
    q01 = xtmur_quantile(sorted, 0.01)

    st_matrix(outname, (rho, bias, obsinf, pboot, Nused, Ndrop, nmiss, T, kbhat, q05, q10, q01))
    st_matrix(profname, PROF)
}

end
