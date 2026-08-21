*! xtflucbreak 1.0.0  07aug2026
*! Fluctuation test for structural change in heterogeneous panel data models,
*!   with or without common correlated effects (CCE).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Implements, faithfully to:
*!   Li F, Xiao Y & Chen Z (2024) "A Fluctuation Test for Structural Change
*!     Detection in Heterogeneous Panel Data Models", Journal of Systems
*!     Science & Complexity 37(3), 1184-1208.
*!     <doi:10.1007/s11424-024-2064-0>
*!   Benchmarks (option compare) from
*!   Antoch J, Hanousek J, Horvath L, Huskova M & Wang S (2018) "Structural
*!     breaks in panel data: Large number of panels and short length time
*!     series", Econometric Reviews 38(7), 828-855.
*!     <doi:10.1080/07474938.2018.1454378>
*!   CCE filter follows Baltagi B H, Feng Q & Kao C (2016), J. Econometrics
*!     191, 176-195 <doi:10.1016/j.jeconom.2015.03.048>, as in xtbfkbreak.
*!
*! Step -> equation map (full version: help xtflucbreak methods)
*!  NO CCE  (Li-Xiao-Chen section 3)
*!   F1  bhat_i        = (Xi'Xi)^-1 Xi'Yi                             eq.(2) p.1187
*!   F2  bhat_i(k)     = (Xi(k)'Xi(k))^-1 Xi(k)'Yi(k)                 p.1187
*!   F3  Qhat_i        = Xi'Xi/T ;  sighat_i^2 = (1/T) sum_t (e_it-ebar_i)^2  p.1187
*!   F4  S(k) = N^(-1/2) sum_i { (1/sighat_i)(k/sqrt T) Qhat_i^(1/2)(bhat_i(k)-bhat_i) }  p.1187
*!   F5  reject if max_{1<k<T} |S(k)^(j)| >= C1(alpha*) for some j    Remark 3.5
*!       alpha* = 1-(1-alpha)^(1/K)                    (Sidak)        Remark 3.5
*!   F6  P(sup|B|>=x) = 2 sum_{k>=1} (-1)^(k+1) exp(-2k^2x^2)         Remark 3.5
*!       (the Kolmogorov distribution; C1(.02532)=1.4781)
*!   F7  V(k) = sum_i { (k/sighat_i) Qhat_i^(1/2)(bhat_i(k)-bhat_i) }
*!       khat = argmax_{1<k<T} ||V(k)||                               Remark 3.7
*!       (khat = LAST pre-break period; see X1i(T) on p.1189)
*!  CCE     (Li-Xiao-Chen section 4)
*!   F8  Wbar = (ybar_t, xbar_t') ; Mw = I - Wbar(Wbar'Wbar)^-1 Wbar' p.1190
*!   F9  Ytil = Mw Y, Xtil = Mw X ; btil_i = (Xtil'Xtil)^-1 Xtil'Ytil eq.(4) p.1191
*!   F10 Qchk_i = Xtil_i'Xtil_i/T ; Stil(k) as F4 ; needs sqrt(T)/N->0 Thm 4.8
*!  COMPARE (Antoch et al. 2018)
*!   A1  s_it = sum_{v<=t} x_iv ehat_iv  =  Z_it (bhat_it - bhat_iT)  eq.(2.9)
*!   A2  Wald1: U1_N(t) = sum_i s_it' s_it            (C = Z_it Z_it)     S1
*!   A3  Wald2: U2_N(t) = sum_i s_it' Z_iT^-1 s_it    (C = Z_it Z_iT^-1 Z_it) S2
*!   A4  CUSUM: V_N(t)  = sum_i sum_{s<=t} ehat_is^2                    eq.(2.5)
*!   A5  Ahat1_N(t) = sum_i sigchk_i^2 tr(C_it(Z_it^-1 - Z_iT^-1))      eq.(3.1)-(3.2)
*!   A6  Ahat2_N(t) = sum_i sigchk_i^2 (t - tr(Z_it Z_iT^-1))           eq.(3.3)-(3.4)
*!   A7  sigchk_i^2 = (1/(T-d)) sum_t ehat_it^2                         eq.(3.10)
*!   A8  stat = max_t |N^(-1/2)(U_N(t) - Ahat_N(t))|                    sec.4.2
*!   A9  wild bootstrap: phi_it = q_it - mean_j q_jt ; phi*_it = zeta_i phi_it,
*!       zeta_i ~ N(0,1) ; u* = max_t |N^(-1/2) sum_i phi*_it|          sec.4.1-4.2
*!
*! Two documented departures from the printed text of Li-Xiao-Chen (both are
*! internal inconsistencies of the paper; see help xtflucbreak methods):
*!   (D1) Remark 3.5/4.9 typeset |.| INSIDE the sum over i.  Taken literally,
*!        N^(-1/2) sum_i |B_i(s)| diverges under H0 and the Kolmogorov critical
*!        value is not applicable.  Theorem 3.4/4.8 and the quoted distribution
*!        function both require |.| OUTSIDE.  We follow the theorems.
*!   (D2) The section-4 statistic Stil(k) as printed omits 1/sigtil_i, yet
*!        Theorem 4.8 claims a STANDARD Brownian bridge, which requires it.
*!        Default = with the scaling; nosigmascale reproduces the printed form.


/* ====================================================================== *
 *  MAIN
 * ====================================================================== */
program define xtflucbreak, rclass sortpreserve
    version 14.0

    syntax [anything(equalok)] [if] [in] [ ,     ///
        CCE                                      ///
        NOCCEConstant                            ///
        CCALags(integer 0)                       ///
        NOCONStant                               ///
        Level(real 5)                            ///
        TRIMming(real 0.10)                      ///
        ASYMptotic                               ///
        NOSIGMAscale                             ///
        CHOLesky                                 ///
        COMPare                                  ///
        REPS(integer 1000)                       ///
        SEED(string)                             ///
        GRAPH                                    ///
        FLUCname(string)                         ///
        BREAKname(string)                        ///
        UNITname(string)                         ///
        COMPname(string)                         ///
        SHOWunits                                ///
        LISTunits(integer 10)                    ///
        NOWARNings ]

    /* ---------------- 0. option validation ----------------------------- */
    if (`level'<=0 | `level'>=100) {
        di as error "level() must lie strictly between 0 and 100"
        exit 198
    }
    if (`trimming'<0 | `trimming'>=0.5) {
        di as error "trimming() must lie in [0, 0.5)"
        exit 198
    }
    if (`ccalags'<0) {
        di as error "ccalags() must be non-negative"
        exit 198
    }
    if (`reps'<50) {
        di as error "reps() must be at least 50"
        exit 198
    }
    if ("`cce'"=="" & `ccalags'>0) {
        di as error "ccalags() requires the {bf:cce} option"
        exit 198
    }
    if ("`cce'"=="" & "`nocceconstant'"!="") {
        di as error "nocceconstant requires the {bf:cce} option"
        exit 198
    }

    /* ---------------- 1. varlist or postestimation --------------------- */
    local post 0
    if (`"`anything'"'=="") {
        _xtfb_efetch
        local depvar "`r(dv)'"
        local xvars  "`r(xv)'"
        local ecce   = r(cce)
        local esrc   "`r(src)'"
        local post 1
        if (`ecce'==1 & "`cce'"=="") {
            local cce "cce"
            local autocce 1
        }
    }
    else {
        gettoken depvar xvars : anything
        capture unab depvar : `depvar'
        if (_rc) {
            di as error "invalid dependent variable {bf:`depvar'}"
            exit 198
        }
        if ("`xvars'"!="") {
            capture unab xvars : `xvars'
            if (_rc) {
                di as error "invalid independent variable list"
                exit 198
            }
        }
    }
    if ("`xvars'"=="" & "`noconstant'"!="") {
        di as error "nothing to test: no regressors and noconstant specified"
        exit 198
    }

    /* ---------------- 2. panel structure ------------------------------- */
    capture qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if (_rc | "`ivar'"=="" | "`tvar'"=="") {
        di as error "data must be {help xtset} as a panel (panel and time variable)"
        exit 459
    }

    marksample touse, novarlist
    markout `touse' `depvar' `xvars' `ivar' `tvar'
    if (`post') {
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        qui replace `touse' = 0 if `esamp'==0
    }

    qui count if `touse'
    if (r(N)==0) {
        di as error "no observations"
        exit 2000
    }

    tempvar tcount
    qui bysort `touse' `ivar' (`tvar'): gen long `tcount' = _N if `touse'
    qui su `tcount' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    if (`Tmin'!=`Tmax') {
        di as error "xtflucbreak requires a BALANCED panel on the estimation sample"
        di as error "  (min T = `Tmin', max T = `Tmax')"
        di as error "  The statistic S(k) sums over i at a COMMON k, so every panel"
        di as error "  must share the same time grid.  See {help xtbalance} or drop"
        di as error "  the short panels with an -if- restriction."
        exit 459
    }
    sort `ivar' `tvar'

    /* ---------------- 3. switches for Mata ----------------------------- */
    local docce = 0
    if ("`cce'"!="") local docce = 1
    local ccecons = 1
    if ("`nocceconstant'"!="") local ccecons = 0
    local hascons = 1
    if ("`noconstant'"!="") local hascons = 0
    local sigsc = 1
    if ("`nosigmascale'"!="") local sigsc = 0
    local usechol = 0
    if ("`cholesky'"!="") local usechol = 1
    local dofs = 1
    if ("`asymptotic'"!="") local dofs = 0
    local docmp = 0
    if ("`compare'"!="") local docmp = 1
    local alpha = `level'/100

    if ("`seed'"!="") set seed `seed'

    /* ---------------- 4. engine ---------------------------------------- */
    tempname Smat Vmat Stat Bimat Shmat Sigmat Cmpmat CProf
    mata: xtfb_run("`Smat'","`Vmat'","`Stat'","`Bimat'","`Shmat'","`Sigmat'","`Cmpmat'","`CProf'")

    if ("`r_err'"!="") {
        di as error "`r_err'"
        exit 498
    }

    local N     = `r_N'
    local T     = `r_T'
    local K     = `r_K'
    local klo   = `r_klo'
    local khi   = `r_khi'
    local khat  = `r_khat'
    local stat  = `r_stat'
    local statasy = `r_statasy'
    local pasy  = `r_pasy'
    local cv    = `r_cv'
    local pval  = `r_p'
    local astar = `r_astar'
    local jmax  = `r_jmax'
    local bdate = `r_bdate'
    local bpost = `r_bpost'
    local frpos = `r_frpos'
    local reject = 0
    if (`stat'>=`cv') local reject = 1

    if (`docmp') {
        if ("`r_cmpok'"!="1") {
            di as text "note: the benchmark tests could not be computed on this sample"
            di as text "      (the Antoch et al. grid d <= t <= T-d is empty for K = `K'); compare skipped."
            local docmp = 0
        }
    }

    local kfrac = `khat'/`T'
    local TNrat = `T'/`N'
    local rtTN  = sqrt(`T')/`N'

    /* render the break dates on the time variable's own display format, so a
       %td / %tq panel shows dates rather than the underlying integer */
    local tfmt : format `tvar'
    local bdstr "`bdate'"
    local bpstr "`bpost'"
    capture local bdstr : display `tfmt' `bdate'
    capture local bpstr : display `tfmt' `bpost'
    local bdstr = trim("`bdstr'")
    local bpstr = trim("`bpstr'")
    if ("`bdstr'"=="") local bdstr "`bdate'"
    if ("`bpstr'"=="") local bpstr "`bpost'"

    /* ---------------- 5. graphs (BEFORE the return-matrix moves) -------- */
    if ("`graph'"!="") {
        if ("`flucname'"=="")  local flucname  "xtfb_fluc"
        if ("`breakname'"=="") local breakname "xtfb_break"
        if ("`unitname'"=="")  local unitname  "xtfb_units"
        if ("`compname'"=="")  local compname  "xtfb_compare"
        _xtfb_graphs, smat(`Smat') vmat(`Vmat') shmat(`Shmat') cprof(`CProf') ///
            k(`K') cv(`cv') khat(`khat') bdate(`bdate') n(`N') t(`T')         ///
            depvar(`depvar') xvars(`xvars') level(`level') docce(`docce')     ///
            docmp(`docmp') flucname(`flucname') breakname(`breakname')        ///
            unitname(`unitname') compname(`compname') tvar(`tvar')
    }

    /* ---------------- 6. display --------------------------------------- */
    _xtfb_display, stat(`stat') cv(`cv') pval(`pval') astar(`astar')       ///
        level(`level') reject(`reject') jmax(`jmax') k(`K') n(`N') t(`T')  ///
        klo(`klo') khi(`khi') khat(`khat') bdate(`bdate') bpost(`bpost')   ///
        kfrac(`kfrac') tnrat(`TNrat') rttn(`rtTN') frpos(`frpos')          ///
        depvar(`depvar') xvars(`xvars') ivar(`ivar') tvar(`tvar')          ///
        docce(`docce') ccecons(`ccecons') ccalags(`ccalags')               ///
        hascons(`hascons') sigsc(`sigsc') usechol(`usechol')               ///
        dofs(`dofs') statasy(`statasy') pasy(`pasy')                       ///
        trimming(`trimming') statmat(`Stat') shmat(`Shmat') sigmat(`Sigmat') ///
        docmp(`docmp') cmpmat(`Cmpmat') reps(`reps') post(`post')          ///
        esrc("`esrc'") autocce("`autocce'") listunits(`listunits')         ///
        bdstr("`bdstr'") bpstr("`bpstr'")                                  ///
        `showunits' `nowarnings'

    /* ---------------- 7. returns --------------------------------------- */
    return scalar stat     = `stat'
    return scalar stat_lxc = `statasy'
    return scalar p_lxc    = `pasy'
    return scalar cv       = `cv'
    return scalar p        = `pval'
    return scalar alphastar = `astar'
    return scalar level    = `level'
    return scalar reject   = `reject'
    return scalar khat     = `khat'
    return scalar breakdate = `bdate'
    return scalar breakpost = `bpost'
    return scalar kfrac    = `kfrac'
    return scalar N        = `N'
    return scalar T        = `T'
    return scalar K        = `K'
    return scalar kmin     = `klo'
    return scalar kmax     = `khi'
    return scalar jmax     = `jmax'
    return scalar fracpos  = `frpos'
    if (`docmp') {
        return scalar wald1    = `Cmpmat'[1,1]
        return scalar wald1_cv = `Cmpmat'[1,2]
        return scalar wald1_p  = `Cmpmat'[1,3]
        return scalar wald2    = `Cmpmat'[2,1]
        return scalar wald2_cv = `Cmpmat'[2,2]
        return scalar wald2_p  = `Cmpmat'[2,3]
        return scalar cusum    = `Cmpmat'[3,1]
        return scalar cusum_cv = `Cmpmat'[3,2]
        return scalar cusum_p  = `Cmpmat'[3,3]
        return scalar reps     = `reps'
    }
    return local depvar    "`depvar'"
    return local indepvars "`xvars'"
    return local panelvar  "`ivar'"
    return local timevar   "`tvar'"
    if (`docce') {
        return local transform "CCE (cross-section averages partialled out)"
    }
    else {
        return local transform "none"
    }
    return local sigmascale "`sigsc'"
    if (`dofs') {
        return local statistic "finite-sample standardised"
    }
    else {
        return local statistic "literal LXC (asymptotic)"
    }
    return local root      "symmetric"
    if (`usechol') return local root "cholesky"
    return local cmdline   "xtflucbreak `0'"
    return local cmd       "xtflucbreak"

    return matrix S       = `Smat', copy
    return matrix V       = `Vmat', copy
    return matrix stats   = `Stat', copy
    return matrix bi      = `Bimat', copy
    return matrix shift   = `Shmat', copy
    return matrix sigma   = `Sigmat', copy
    if (`docmp') {
        return matrix compare = `Cmpmat', copy
        return matrix cprofile = `CProf', copy
    }
end


/* ====================================================================== *
 *  POSTESTIMATION FETCH
 *  Reads depvar / regressors / whether a CCE-type estimator was used from
 *  the estimation results in memory.  e() is NOT modified.
 * ====================================================================== */
program define _xtfb_efetch, rclass
    version 14.0

    local ecmd "`e(cmd)'"
    if ("`ecmd'"=="") {
        di as error "no estimation results found"
        di as error "either give a varlist:  {bf:xtflucbreak depvar indepvars , ...}"
        di as error "or fit a supported model first (see {help xtflucbreak postestimation})"
        exit 301
    }
    local ok "xtreg regress areg reghdfe xtgls xtmg xtcce xtdcce2 xtbfkbreak xtpmg xtfmg"
    local isok 0
    foreach c of local ok {
        if ("`ecmd'"=="`c'") local isok 1
    }
    if (`isok'==0) {
        di as error "xtflucbreak postestimation does not support {bf:`ecmd'}"
        di as error "supported: `ok'"
        di as error "run it standalone instead: {bf:xtflucbreak depvar indepvars , ...}"
        exit 301
    }

    local dv "`e(depvar)'"
    /* xtmg with -augment impose- stores e(depvar) as the TWO-WORD string
       "adjusted <y>".  Any multi-word e(depvar) is reduced to its last token,
       which must exist as a variable. */
    if (wordcount("`dv'")>1) {
        local dv : word `=wordcount("`dv'")' of `dv'
    }
    capture confirm variable `dv'
    if (_rc | "`dv'"=="") {
        di as error "could not recover the dependent variable from e() after {bf:`ecmd'}"
        di as error "  (e(depvar) = {bf:`e(depvar)'})"
        di as error "run xtflucbreak standalone with an explicit varlist"
        exit 301
    }

    /* regressors: prefer the estimator's own locals, else colnames e(b) */
    local xv "`e(indepvars)'"
    if ("`xv'"=="") local xv "`e(indepvar)'"
    if ("`xv'"=="") local xv "`e(rhs)'"
    if ("`e(endog)'"!="") local xv "`xv' `e(endog)'"
    if ("`xv'"=="") {
        capture local bn : colnames e(b)
        if (_rc==0) {
            local xv ""
            foreach nm of local bn {
                /* drop equation prefixes  eq:var  -> var */
                local nm2 = subinstr("`nm'",":"," ",.)
                local nm2 : word `=wordcount("`nm2'")' of `nm2'
                if ("`nm2'"!="_cons" & "`nm2'"!="`dv'") {
                    capture confirm variable `nm2'
                    if (_rc==0) {
                        local dup 0
                        foreach q of local xv {
                            if ("`q'"=="`nm2'") local dup 1
                        }
                        if (`dup'==0) local xv "`xv' `nm2'"
                    }
                }
            }
        }
    }
    local xv : list clean xv
    if ("`xv'"=="") {
        di as error "could not recover the regressor list from e() after {bf:`ecmd'}"
        di as error "run xtflucbreak standalone with an explicit varlist"
        exit 301
    }

    /* did the fitted model already control for common factors?
       Scan every macro an estimator might record it in.  xtmg (v1.0.1) does
       NOT set e(cmdline); it flags the variant in e(title2) as "CCEMG" / "AMG"
       / "MG", so that macro has to be read explicitly. */
    local cce 0
    if ("`ecmd'"=="xtdcce2") local cce 1
    if ("`ecmd'"=="xtcce")   local cce 1
    if ("`ecmd'"=="xtfmg")   local cce 1
    foreach mac in title2 model estimator transform title cmdline properties {
        local mv = lower("`e(`mac')'")
        if (strpos("`mv'","cce")>0) local cce 1
        if (strpos("`mv'","common correlated")>0) local cce 1
        if (strpos("`mv'","amg")>0) local cce 1
        if (strpos("`mv'","augmented mean group")>0) local cce 1
    }

    return local dv  "`dv'"
    return local xv  "`xv'"
    return local src "`ecmd'"
    return scalar cce = `cce'
end


/* ====================================================================== *
 *  DISPLAY
 * ====================================================================== */
program define _xtfb_display
    version 14.0
    syntax , stat(real) cv(real) pval(real) astar(real) level(real)        ///
             reject(integer) jmax(integer) k(integer) n(integer)           ///
             t(integer) klo(integer) khi(integer) khat(integer)            ///
             bdate(real) bpost(real) kfrac(real) tnrat(real) rttn(real)    ///
             frpos(real) depvar(string) ivar(string) tvar(string)          ///
             docce(integer) ccecons(integer) ccalags(integer)              ///
             hascons(integer) sigsc(integer) usechol(integer)              ///
             trimming(real) statmat(name) shmat(name) sigmat(name)         ///
             docmp(integer) cmpmat(name) reps(integer) post(integer)       ///
             listunits(integer) dofs(integer) statasy(real) pasy(real)     ///
             [ xvars(string) esrc(string) autocce(string)                  ///
               bdstr(string) bpstr(string)                                 ///
               SHOWunits NOWARNings ]

    local branch "Section 3: no common correlated effects"
    if (`docce') local branch "Section 4: common correlated effects (CCE)"
    local rootnm "symmetric  Qhat^(1/2)"
    if (`usechol') local rootnm "Cholesky   Qhat = LL'"

    local nccetxt ""
    if (`docce'==0) local nccetxt " nocce"

    di ""
    di as text "{hline 79}"
    di as text "Fluctuation test for structural change in heterogeneous panels" _col(64) "(LXC 2024)"
    di as text "{hline 79}"
    di as text "H0: delta_i = 0 for all i" _col(46) as text "(no change in the slopes)"
    di as text "HA: delta_i != 0 for i in Pi, |Pi|/N -> c" _col(46) as text "(change in some panels)"
    di as text "{hline 79}"
    di as text "Dependent var  : " as result "`depvar'" _col(45) as text "N (panels)   = " as result %9.0g `n'
    di as text "Regressors     : " as result "`xvars'" _col(45) as text "T (periods)  = " as result %9.0g `t'
    if (`hascons' & `docce'==0) {
        di as text "                 " as result "_cons" _col(45) as text "K (coefs)    = " as result %9.0g `k'
    }
    else {
        di as text "" _col(45) as text "K (coefs)    = " as result %9.0g `k'
    }
    di as text "Panel variable : " as result "`ivar'" _col(45) as text "T/N          = " as result %9.3f `tnrat'
    di as text "Time variable  : " as result "`tvar'" _col(45) as text "sqrt(T)/N    = " as result %9.4f `rttn'
    di as text "Branch         : " as result "`branch'"
    if (`docce') {
        local ccc "with constant"
        if (`ccecons'==0) local ccc "no constant (literal LXC eq. p.1190)"
        di as text "  CCE filter   : " as result "Mw from (ybar, xbar), `ccc', `ccalags' lag(s)"
    }
    di as text "Qhat root      : " as result "`rootnm'"
    local sgs "yes  (1/sigmahat_i)"
    if (`sigsc'==0) local sgs "no   (nosigmascale: literal LXC section-4 display)"
    di as text "Sigma scaling  : " as result "`sgs'"
    if (`trimming'>0) {
        di as text "Trimming       : " as result %5.3f `trimming' as text " of T at each end"
    }
    di as text "Search grid    : " as result "k = `klo' ... `khi'" as text "  (k must admit an invertible Xi(k)'Xi(k) in every panel)"
    if (`post') {
        di as text "Source         : " as result "postestimation after `esrc'"
        if ("`autocce'"!="") {
            di as text "                 " as text "CCE branch selected automatically (the fitted model controls for factors)"
        }
    }
    di as text "{hline 79}"

    /* ---- component-wise test ------------------------------------------ */
    di ""
    di as text "Fluctuation statistic:  max_k |S(k)^(j)|" _col(52) "(LXC eq. p.1187, Rem. 3.5)"
    di as text "{hline 79}"
    di as text %-11s "Component" " " %11s "Statistic" " " %11s "Crit. value" " " %10s "p-value" " " %7s "Reject" " " %12s "LXC as printed"
    di as text "{hline 79}"
    forvalues j = 1/`k' {
        local sj = `statmat'[`j',1]
        local pj = `statmat'[`j',3]
        local aj = `statmat'[`j',5]
        local rj = "no"
        if (`statmat'[`j',4]==1) local rj "YES"
        local st = ""
        if (`pj'<0.10) local st "*"
        if (`pj'<0.05) local st "**"
        if (`pj'<0.01) local st "***"
        local tag "`j'"
        if (`j'==`jmax') local tag "`j' <-"
        di as text %-11s "`tag'" " " as result %11.4f `sj' " " as text %11.4f `cv' " " as result %10.4f `pj' " " as text %7s "`rj'" " " as text %12.4f `aj' "  " as result "`st'"
    }
    di as text "{hline 79}"
    di as text "Overall (max over j)" _col(23) as result %11.4f `stat' as text " vs " as result %8.4f `cv' as text "   p = " as result %6.4f `pval'
    di as text "{hline 79}"
    if (`dofs') {
        di as text " Statistic uses the {bf:finite-sample standardisation}: each S(k) component is"
        di as text " rescaled by sqrt( s(1-s) / Var[S(k)] ), with Var[S(k)] the exact conditional"
        di as text " variance (1/N)sum_i (k{c 178}/T) diag(Qhat_i{c 94}(1/2)(A_ik{c 94}-1 - A_iT{c 94}-1)Qhat_i{c 94}(1/2))."
        di as text " It converges to s(1-s), so this is LXC's statistic asymptotically, but it is"
        di as text " correctly sized in finite samples where the literal form is not.  The last"
        di as text " column is the literal LXC statistic; {bf:asymptotic} makes it the decision rule."
        di as text " Literal LXC overall statistic = " as result %8.4f `statasy' as text "   p = " as result %6.4f `pasy'
    }
    else {
        di as text " {bf:asymptotic} specified: the decision uses the literal LXC statistic."
        di as text " {bf:warning}: at these sample sizes that statistic over-rejects.  Measured"
        di as text " empirical size at the nominal 5% level, LXC Model 1, iid errors, N = 50:"
        di as text "     T = 50, trimming(0.10)  ->  0.050        T = 25, trimming(0.10)  ->  0.255"
        di as text "     T = 50, trimming(0)     ->  0.674        T = 25, trimming(0.15)  ->  0.140"
        di as text " See {help xtflucbreak_methods:help xtflucbreak methods} for the cause and the evidence."
    }
    di as text "{hline 79}"
    di as text " C1(alpha*) inverts the Kolmogorov law  P(sup|B| >= x) = 2 sum (-1)^(k+1) exp(-2k^2x^2)"
    di as text " alpha* = 1 - (1-alpha)^(1/K) = " as result %7.5f `astar' as text "  (Sidak, K = `k');  overall alpha = " as result %5.3f `=`level'/100'
    di as text " Overall p-value = 1 - (1 - min_j p_j)^K.    * p<.10   ** p<.05   *** p<.01"
    di as text " Components are Qhat_i^(1/2)-ROTATED combinations of the K coefficients, not"
    di as text " individual regressors (the rotation differs by panel).  Read the shift table"
    di as text " below for effects in the original coefficient space."
    di as text "{hline 79}"

    /* ---- decision ----------------------------------------------------- */
    di ""
    di as text "{hline 79}"
    di as text "Decision at the " as result `level' as text "% level"
    di as text "{hline 79}"
    if (`reject') {
        di as text " H0 of parameter constancy is " as result "REJECTED" as text "."
        di as text " Component " as result "`jmax'" as text " of Qhat_i^(1/2)(betahat_i(k) - betahat_i) fluctuates beyond the"
        di as text " Brownian-bridge band.  A change point is present in at least a fraction c > 0"
        di as text " of the panels (LXC Theorem 3.6 / 4.10)."
    }
    else {
        di as text " H0 of parameter constancy is " as result "NOT rejected" as text " at `level'%."
        di as text " {bf:This is not a certificate of stability.}  LXC's own power tables show the"
        di as text " test is weakest when (a) only a small fraction of panels break, (b) the break"
        di as text " sits near an endpoint (k0 = T/4 or 3T/4), and (c) T is small relative to the"
        di as text " size of delta_i.  Read the break-date block below as descriptive only."
    }
    di as text "{hline 79}"

    /* ---- break date --------------------------------------------------- */
    di ""
    di as text "Change-point estimator" _col(56) "(LXC Remark 3.7 / 4.11)"
    di as text "{hline 79}"
    if ("`bdstr'"=="") local bdstr "`bdate'"
    if ("`bpstr'"=="") local bpstr "`bpost'"
    di as text %-40s "khat = argmax_k ||V(k)||   (index)" " " as result %12.0f `khat'
    di as text %-40s "  last PRE-break period (`tvar')" " " as result %12s "`bdstr'"
    di as text %-40s "  first POST-break period (`tvar')" " " as result %12s "`bpstr'"
    di as text %-40s "  khat / T" " " as result %12.4f `kfrac'
    di as text "{hline 79}"
    di as text " Model: y_it = x_it'(beta_i + delta_i 1{c 123}t > k0{c 125}) + e_it, so the break takes effect at khat+1."
    di as text " khat is consistent (Thm 3.8/4.12) but LXC derive {bf:no} limiting distribution for it,"
    di as text " so no confidence interval is reported.  For a break-date CI and regime slopes:"
    di as text "   {stata xtbfkbreak `depvar' `xvars', breaks(1)`nccetxt'}"
    di as text "{hline 79}"

    /* ---- per-unit shift summary --------------------------------------- */
    di ""
    di as text "Per-panel shift at khat:  deltahat_i = betahat_i(post) - betahat_i(pre)"
    di as text "{hline 79}"
    di as text %-14s "Component j" " " %12s "mean" " " %12s "sd" " " %12s "% positive" "  "
    di as text "{hline 79}"
    forvalues j = 1/`k' {
        local mj = `shmat'[`n'+1,`j'+1]
        local sj = `shmat'[`n'+2,`j'+1]
        local pj = `shmat'[`n'+3,`j'+1]
        di as text %-14s "`j'" " " as result %12.4f `mj' " " %12.4f `sj' " " %12.1f `pj'
    }
    di as text "{hline 79}"
    di as text " Sign concordance (max over j of |pct.positive - 50| / 50) = " as result %5.3f `frpos'
    if (`frpos'<0.40) {
        di as text " {bf:note}: the panel-level shifts point in mixed directions.  The fluctuation"
        di as text " statistic aggregates SIGNED deviations across i, so offsetting breaks cancel"
        di as text " and power falls.  A non-rejection above is weak evidence in this configuration."
    }
    di as text " These are unrestricted regime OLS contrasts, reported in the ORIGINAL coefficient"
    di as text " space (unlike the S(k) components, which are Qhat_i^(1/2)-rotated)."
    di as text "{hline 79}"

    if ("`showunits'"!="") {
        di ""
        di as text "Per-panel shift norms  ||deltahat_i||   (first `listunits' panels)"
        di as text "{hline 79}"
        di as text %-14s "Panel id" " " %12s "||deltahat||" " " %12s "sigmahat_i" "  "
        di as text "{hline 79}"
        local nshow = min(`listunits',`n')
        forvalues r = 1/`nshow' {
            local idv = `shmat'[`r',1]
            local nv  = 0
            forvalues j = 1/`k' {
                local nv = `nv' + (`shmat'[`r',`j'+1])^2
            }
            local nv = sqrt(`nv')
            local sg = `sigmat'[`r',2]
            di as text %-14.0g `idv' " " as result %12.4f `nv' " " %12.4f `sg'
        }
        di as text "{hline 79}"
        di as text " (rows are in panel-id order; use r(shift) and r(sigma) to sort as you like)"
        di as text "{hline 79}"
    }

    /* ---- benchmarks --------------------------------------------------- */
    if (`docmp') {
        di ""
        di as text "Benchmark tests on the SAME sample" _col(52) "(Antoch et al. 2018)"
        di as text "{hline 79}"
        di as text %-32s "Test" " " %12s "Statistic" " " %11s "Boot. cv" " " %10s "Boot. p" " " %7s "Reject"
        di as text "{hline 79}"
        local nmz `""Wald 1 (C = Z_it Z_it)" "Wald 2 (C = Z_it Z_iT^-1 Z_it)" "CUSUM  (V_N(t), resid. squares)""'
        forvalues r = 1/3 {
            local nm : word `r' of `nmz'
            local s0 = `cmpmat'[`r',1]
            local c0 = `cmpmat'[`r',2]
            local p0 = `cmpmat'[`r',3]
            local d0 "no"
            if (`s0'>`c0') local d0 "YES"
            di as text %-32s "`nm'" " " as result %12.4f `s0' " " as text %11.4f `c0' " " as result %10.4f `p0' " " as text %7s "`d0'"
        }
        di as text "{hline 79}"
        di as text " Wild bootstrap, " as result "`reps'" as text " replications (Antoch et al. sec. 4.2, algorithm steps 2a-3)."
        di as text " Computed on the RAW (untransformed) data with an intercept -- exactly as in"
        di as text " LXC Tables 1-9.  Antoch et al. have no CCE variant; that is the point of the"
        di as text " comparison, and it is why these tests lose power under common factors."
        di as text "{hline 79}"
    }

    /* ---- warnings ------------------------------------------------------ */
    if ("`nowarnings'"=="") {
        local anyw 0
        if (`t'<50) local anyw 1
        if (`docce' & `rttn'>0.15) local anyw 1
        if (`docce'==0 & `n'<20) local anyw 1
        if (`khat'<=`klo' | `khat'>=`khi') local anyw 1
        if (`anyw') {
            di ""
            di as text "Diagnostics"
            di as text "{hline 79}"
            if (`t'<50) {
                di as text " {bf:warning}: T = " as result "`t'" as text " is below the smallest T in LXC's Monte Carlo (T=50)."
                di as text "   The limit is (N,T) -> infinity jointly; with short T the Brownian-bridge"
                di as text "   approximation to max|S(k)| is unreliable in both directions."
            }
            if (`docce' & `rttn'>0.15) {
                di as text " {bf:warning}: sqrt(T)/N = " as result %5.3f `rttn' as text " is not small.  Theorem 4.8 requires"
                di as text "   sqrt(T)/N -> 0 for the CCE branch; the O(N^(-1/2)) factor-estimation"
                di as text "   error is not negligible here and the test can over-reject."
            }
            if (`docce'==0 & `n'<20) {
                di as text " {bf:warning}: N = " as result "`n'" as text " panels.  S(k) is a CLT over i; with few panels the"
                di as text "   Gaussian aggregation step (LXC Appendix, p.1205) has not kicked in."
            }
            if (`khat'<=`klo' | `khat'>=`khi') {
                di as text " {bf:warning}: khat sits on the edge of the search grid.  Either the break is"
                di as text "   near an endpoint (where LXC Table 4 shows power is lowest) or there is no"
                di as text "   break and the argmax is picking up noise."
            }
            di as text "{hline 79}"
        }
        if (`docce'==0) {
            di as text "Cross-sectional independence is assumed in the section-3 branch (Assumption 3.1)."
            di as text "Check with {stata xtcd2 `depvar'} and re-run with {bf:cce} if it is rejected."
            di as text "{hline 79}"
        }
    }
    di ""
end


/* ====================================================================== *
 *  GRAPHS
 * ====================================================================== */
program define _xtfb_graphs
    version 14.0
    syntax , smat(name) vmat(name) shmat(name) cprof(name) k(integer)      ///
             cv(real) khat(integer) bdate(real) n(integer) t(integer)      ///
             depvar(string) level(real) docce(integer) docmp(integer)      ///
             flucname(string) breakname(string) unitname(string)           ///
             compname(string) tvar(string) [ xvars(string) ]

    local btag "`bdate'"

    /* ---- 1. fluctuation paths ----------------------------------------- */
    preserve
        clear
        qui set obs `=rowsof(`smat')'
        qui svmat double `smat', name(_fbs)
        capture confirm variable _fbs1
        if (_rc==0) {
            local plot ""
            local leg ""
            forvalues j = 1/`k' {
                qui gen double _fba`j' = abs(_fbs`=`j'+2')
                local plot `"`plot' (line _fba`j' _fbs2, sort lwidth(medthick))"'
                local leg  `"`leg' `j' "Component `j'""'
            }
            qui gen double _fbcv = `cv'
            local plot `"`plot' (line _fbcv _fbs2, sort lpattern(dash) lcolor(cranberry) lwidth(medthick))"'
            local cvtxt = string(`cv',"%6.4f")
            local leg  `"`leg' `=`k'+1' "critical value `cvtxt'""'
            twoway `plot',                                                      ///
                xline(`btag', lpattern(solid) lcolor(gs9) lwidth(thin))          ///
                title("Fluctuation paths |S(k){sup:(j)}|", size(medium))         ///
                subtitle("Li-Xiao-Chen (2024) fluctuation test", size(small))    ///
                ytitle("|S(k)|") xtitle("`tvar'")                                ///
                legend(order(`leg') size(vsmall) rows(1) region(lstyle(none)))   ///
                note("Dashed line: `level'% Sidak-adjusted Kolmogorov critical value." ///
                     "Grey line: estimated change point khat = `btag' (last pre-break period).  N = `n', T = `t'.", size(vsmall)) ///
                graphregion(color(white)) plotregion(color(white))               ///
                name(`flucname', replace)
        }
    restore

    /* ---- 2. break-date profile ---------------------------------------- */
    preserve
        clear
        qui set obs `=rowsof(`vmat')'
        qui svmat double `vmat', name(_fbv)
        capture confirm variable _fbv3
        if (_rc==0) {
            twoway (line _fbv3 _fbv2, sort lwidth(medthick) lcolor(navy)),       ///
                xline(`btag', lpattern(dash) lcolor(cranberry) lwidth(medthick)) ///
                title("Change-point identification", size(medium))               ///
                subtitle("||V(k)|| profile (LXC Remark 3.7)", size(small))       ///
                ytitle("||V(k)||") xtitle("`tvar'")                              ///
                note("Maximising k marked by the dashed line: khat = `btag'." ///
                     "No confidence interval: LXC prove consistency but not a limit law for khat.", size(vsmall)) ///
                graphregion(color(white)) plotregion(color(white))               ///
                name(`breakname', replace)
        }
    restore

    /* ---- 3. per-panel shifts ------------------------------------------ */
    preserve
        clear
        qui set obs `=rowsof(`shmat')-3'
        qui svmat double `shmat', name(_fbd)
        capture confirm variable _fbd2
        if (_rc==0) {
            sort _fbd2
            qui gen long _fbr = _n
            qui gen byte _fbp = (_fbd2>0)
            twoway (scatter _fbd2 _fbr if _fbp==1, mcolor(navy) msymbol(O) msize(small))       ///
                   (scatter _fbd2 _fbr if _fbp==0, mcolor(cranberry) msymbol(O) msize(small)), ///
                yline(0, lcolor(black) lwidth(thin))                                 ///
                title("Direction of the panel-level shifts", size(medium))            ///
                subtitle("{&delta}hat{sub:i} for component 1 at khat = `btag'", size(small)) ///
                ytitle("{&delta}hat{sub:i}") xtitle("Panel (sorted)")                 ///
                legend(order(1 "positive" 2 "negative") size(small) rows(1) region(lstyle(none))) ///
                note("S(k) aggregates SIGNED deviations across i: a near 50/50 split means offsetting" ///
                     "breaks and low power, so a non-rejection is weak evidence there.", size(vsmall)) ///
                graphregion(color(white)) plotregion(color(white))                    ///
                name(`unitname', replace)
        }
    restore

    /* ---- 4. benchmark profiles ---------------------------------------- */
    if (`docmp') {
        preserve
            clear
            qui set obs `=rowsof(`cprof')'
            qui svmat double `cprof', name(_fbc)
            capture confirm variable _fbc5
            if (_rc==0) {
                twoway (line _fbc3 _fbc2, sort lwidth(medthick) lcolor(navy))           ///
                       (line _fbc4 _fbc2, sort lwidth(medthick) lcolor(forest_green) lpattern(shortdash)) ///
                       (line _fbc5 _fbc2, sort lwidth(medthick) lcolor(cranberry) lpattern(dot)),         ///
                    xline(`btag', lpattern(solid) lcolor(gs9) lwidth(thin))             ///
                    title("Benchmark detection processes", size(medium))                ///
                    subtitle("|standardised| Wald 1, Wald 2 and CUSUM (Antoch et al. 2018)", size(small)) ///
                    ytitle("|N{sup:-1/2}(U{sub:N}(t) - A{sub:N}(t))|") xtitle("`tvar'")   ///
                    legend(order(1 "Wald 1" 2 "Wald 2" 3 "CUSUM") size(small) rows(1) region(lstyle(none))) ///
                    note("Series are on different scales by construction (different weighting matrices C{sub:i,t})." ///
                         "Grey line: khat from the fluctuation test.", size(vsmall))     ///
                    graphregion(color(white)) plotregion(color(white))                   ///
                    name(`compname', replace)
            }
        restore
    }
end


/* ====================================================================== *
 *  MATA ENGINE
 *  NOTE: inside this block only // comments are legal.
 * ====================================================================== */
version 14.0
mata:

// ------------------------------------------------------------------ //
// wide (T x N) layout of a panel-major stacked column vector
// ------------------------------------------------------------------ //
real matrix xtfb_wide(real colvector v, real scalar N)
{
    return(rowshape(v, N)')
}

// ------------------------------------------------------------------ //
// cross-section averages: T x cols(M)
// ------------------------------------------------------------------ //
real matrix xtfb_csa(real matrix M, real scalar N)
{
    real matrix out, w
    real scalar j, T
    T = rows(M)/N
    out = J(T, 0, .)
    for (j=1; j<=cols(M); j++) {
        w = xtfb_wide(M[,j], N)
        out = (out, rowsum(w):/N)
    }
    return(out)
}

// ------------------------------------------------------------------ //
// per-panel design matrix (T x K); constant appended LAST
// ------------------------------------------------------------------ //
real matrix xtfb_gather(pointer(real matrix) rowvector L, real scalar i,
                        real scalar T, real scalar addcons)
{
    real matrix out
    real scalar k
    out = J(T, 0, .)
    for (k=1; k<=cols(L); k++) {
        out = (out, (*L[k])[,i])
    }
    if (addcons==1) {
        out = (out, J(T,1,1))
    }
    return(out)
}

// ------------------------------------------------------------------ //
// symmetric positive semi-definite square root  A = A^(1/2) A^(1/2)
// ------------------------------------------------------------------ //
real matrix xtfb_symroot(real matrix A)
{
    real matrix X, S
    real rowvector lam
    real scalar j, K
    S = (A + A') :/ 2
    symeigensystem(S, X=., lam=.)
    K = cols(lam)
    for (j=1; j<=K; j++) {
        if (lam[j] < 1e-14) {
            lam[j] = 0
        }
    }
    return(X * diag(sqrt(lam)) * X')
}

// ------------------------------------------------------------------ //
// first t at which sum_{s<=t} x_s x_s' is invertible; 0 if never
// ------------------------------------------------------------------ //
real scalar xtfb_kfull(real matrix Xi)
{
    real matrix Z, Zi
    real colvector xt
    real scalar t, K, T
    K = cols(Xi)
    T = rows(Xi)
    Z = J(K,K,0)
    for (t=1; t<=T; t++) {
        xt = Xi[t,]'
        Z = Z + xt*xt'
        if (t>=K) {
            Zi = invsym(Z)
            if (diag0cnt(Zi)==0) {
                return(t)
            }
        }
    }
    return(0)
}

// ------------------------------------------------------------------ //
// Kolmogorov tail:  P(sup_{0<=u<=1} |B(u)| >= x)
//   large x : 2 sum_{k>=1} (-1)^(k+1) exp(-2 k^2 x^2)      (LXC Rem 3.5)
//   small x : theta-function form, numerically stable
// ------------------------------------------------------------------ //
real scalar xtfb_kq(real scalar x)
{
    real scalar s, k, tk, cdf
    if (x <= 0) {
        return(1)
    }
    if (x < 1) {
        s = 0
        for (k=1; k<=60; k++) {
            tk = 2*k - 1
            s = s + exp(-(tk*tk)*pi()*pi()/(8*x*x))
        }
        cdf = sqrt(2*pi())/x * s
        if (cdf > 1) {
            cdf = 1
        }
        return(1 - cdf)
    }
    s = 0
    for (k=1; k<=120; k++) {
        tk = exp(-2*k*k*x*x)
        if (mod(k,2)==1) {
            s = s + tk
        }
        if (mod(k,2)==0) {
            s = s - tk
        }
    }
    s = 2*s
    if (s < 0) {
        s = 0
    }
    if (s > 1) {
        s = 1
    }
    return(s)
}

// ------------------------------------------------------------------ //
// inverse: C1(a) solving P(sup|B| >= x) = a
// ------------------------------------------------------------------ //
real scalar xtfb_kinv(real scalar a)
{
    real scalar lo, hi, mid, j, q
    lo = 0.02
    hi = 8
    for (j=1; j<=300; j++) {
        mid = (lo+hi)/2
        q = xtfb_kq(mid)
        if (q > a) {
            lo = mid
        }
        if (q <= a) {
            hi = mid
        }
    }
    return((lo+hi)/2)
}

// ------------------------------------------------------------------ //
// upper-tail quantile of a bootstrap sample
// ------------------------------------------------------------------ //
real scalar xtfb_bq(real colvector v, real scalar alpha)
{
    real colvector s
    real scalar B, idx
    B = rows(v)
    s = sort(v, 1)
    idx = ceil((1-alpha)*B)
    if (idx < 1) {
        idx = 1
    }
    if (idx > B) {
        idx = B
    }
    return(s[idx])
}

// ================================================================== //
// MAIN ENGINE
// ================================================================== //
void xtfb_run(string scalar nmS,   string scalar nmV,   string scalar nmStat,
              string scalar nmBi,  string scalar nmSh,  string scalar nmSig,
              string scalar nmCmp, string scalar nmCP)
{
    real scalar N, Tfull, Teff, docce, ccecons, nlags, hascons, trim
    real scalar sigsc, usechol, docmp, reps, alpha, K, p, i, k, j, t, dofs
    real scalar kfmax, klo, khi, khat, best, astar, cv, pmin, pj, statmax, jmax
    real scalar s2, sw, addc, bdate, bpost, frpos
    string scalar touse

    st_local("r_err", "")

    docce   = strtoreal(st_local("docce"))
    ccecons = strtoreal(st_local("ccecons"))
    nlags   = strtoreal(st_local("ccalags"))
    hascons = strtoreal(st_local("hascons"))
    trim    = strtoreal(st_local("trimming"))
    sigsc   = strtoreal(st_local("sigsc"))
    usechol = strtoreal(st_local("usechol"))
    dofs    = strtoreal(st_local("dofs"))
    docmp   = strtoreal(st_local("docmp"))
    reps    = strtoreal(st_local("reps"))
    alpha   = strtoreal(st_local("alpha"))
    touse   = st_local("touse")

    // ---------------- data ---------------------------------------- //
    real colvector pv, y, tvfull
    real matrix Xall
    pv     = st_data(., st_local("ivar"),   touse)
    y      = st_data(., st_local("depvar"), touse)
    tvfull = st_data(., st_local("tvar"),   touse)
    Xall   = J(rows(y), 0, .)
    if (st_local("xvars")!="") {
        Xall = st_data(., st_local("xvars"), touse)
    }
    p = cols(Xall)

    real matrix info
    info  = panelsetup(pv, 1)
    N     = rows(info)
    Tfull = info[1,2] - info[1,1] + 1

    real colvector ids
    ids = pv[info[,1]]

    real matrix Yw, tvw
    real colvector tvals
    Yw    = xtfb_wide(y, N)
    tvw   = xtfb_wide(tvfull, N)
    tvals = tvw[,1]

    pointer(real matrix) rowvector Xw
    Xw = J(1, p, NULL)
    for (k=1; k<=p; k++) {
        Xw[k] = &(xtfb_wide(Xall[,k], N))
    }

    // ---------------- CCE annihilator (LXC F8) --------------------- //
    // Wbar = (ybar_t, xbar_t').  Pesaran's (2006) augmentation adds a
    // CONSTANT, which is what xtbfkbreak does and what makes the two
    // commands agree numerically; nocceconstant reproduces the literal
    // display on LXC p.1190.
    real matrix Wc, Wce, Mw
    real colvector keep
    Teff = Tfull
    keep = (1::Tfull)
    Wce  = J(Tfull, 0, .)
    if (docce==1) {
        Wc   = (xtfb_csa(y, N), xtfb_csa(Xall, N))
        Teff = Tfull - nlags
        keep = ((nlags+1) :: Tfull)
        Wce  = Wc[keep,]
        for (j=1; j<=nlags; j++) {
            Wce = (Wce, Wc[(keep :- j),])
        }
        if (ccecons==1) {
            Wce = (J(Teff,1,1), Wce)
        }
    }
    if (Teff < Tfull) {
        Yw    = Yw[keep,]
        tvals = tvals[keep]
        for (k=1; k<=p; k++) {
            Xw[k] = &((*Xw[k])[keep,])
        }
    }
    Mw = I(Teff)
    if (docce==1) {
        Mw = Mw - Wce * invsym(quadcross(Wce,Wce)) * Wce'
    }

    // ---------------- design width --------------------------------- //
    // section 3: x_it = (x, 1).  section 4: the intercept is absorbed by
    // M_w, so adding a constant would give an exactly collinear column.
    addc = hascons
    if (docce==1) {
        addc = 0
    }
    K = p + addc
    if (K < 1) {
        st_local("r_err", "no regressors to test")
        return
    }
    if (Teff < K + 2) {
        st_local("r_err", "T is too short for K = " + strofreal(K) + " coefficients")
        return
    }

    // ---------------- per-panel loop (LXC F1-F4) ------------------- //
    real matrix Ssum, Vsum, Bi, Sig, Xi, A, Ai, Qi, Ri
    real colvector yi, bfull, bnum, bk, ei, dvec, xt, dcen
    real matrix ATinv, Akinv
    real scalar kf, vscl

    Ssum  = J(Teff, K, 0)
    Vsum  = J(Teff, K, 0)
    Bi    = J(N, K+1, .)
    Sig   = J(N, 2, .)
    kfmax = K

    for (i=1; i<=N; i++) {
        Xi = xtfb_gather(Xw, i, Teff, addc)
        yi = Yw[,i]
        if (docce==1) {
            Xi = Mw * Xi
            yi = Mw * yi
        }
        A = quadcross(Xi, Xi)
        ATinv = invsym(A)
        if (diag0cnt(ATinv)>0) {
            st_local("r_err", "panel " + strofreal(ids[i]) + ": the regressor matrix is rank deficient over the full sample")
            return
        }
        bfull = ATinv * quadcross(Xi, yi)
        ei    = yi - Xi*bfull
        dcen  = ei :- (sum(ei)/Teff)
        s2    = quadcross(dcen, dcen) / Teff
        if (s2 <= 0) {
            st_local("r_err", "panel " + strofreal(ids[i]) + ": zero residual variance (perfect fit)")
            return
        }
        sw = 1
        if (sigsc==1) {
            sw = 1/sqrt(s2)
        }
        // scale of the term's variance: 1 when the 1/sigmahat_i factor is on,
        // sigmahat_i^2 when it is off (nosigmascale)
        vscl = sw*sw*s2

        Bi[i,1] = ids[i]
        Bi[|i,2 \ i,K+1|] = bfull'
        Sig[i,1] = ids[i]
        Sig[i,2] = sqrt(s2)

        Qi = A :/ Teff
        Ri = xtfb_symroot(Qi)
        if (usechol==1) {
            Ri = cholesky(Qi)
        }

        Ai   = J(K,K,0)
        bnum = J(K,1,0)
        kf   = 0
        for (t=1; t<=Teff; t++) {
            xt   = Xi[t,]'
            Ai   = Ai + xt*xt'
            bnum = bnum + xt*yi[t]
            if (t>=K) {
                Akinv = invsym(Ai)
                if (kf==0) {
                    if (diag0cnt(Akinv)==0) {
                        kf = t
                    }
                }
                if (kf>0) {
                    bk   = Akinv * bnum
                    dvec = Ri * (bk - bfull)
                    Ssum[t,] = Ssum[t,] + (sw*(t/sqrt(Teff))) :* dvec'
                    // exact variance of this term conditional on X, under
                    // Var(e_i) = sigma_i^2 I:
                    //   Var[(k/sqrt T) R (bhat_i(k)-bhat_i)]
                    //     = (k^2/T) R (A_k^-1 - A_T^-1) R  * sigma_i^2
                    // The asymptotic limit of the diagonal is s(1-s); using the
                    // exact form instead removes the O(K/k) finite-sample
                    // inflation (E[A_k^-1] = Sigma^-1/(k-K-1), not Sigma^-1/k).
                    Vsum[t,] = Vsum[t,] + (vscl*(t*t/Teff)) :* diagonal(Ri*(Akinv-ATinv)*Ri)'
                }
            }
        }
        if (kf==0) {
            st_local("r_err", "panel " + strofreal(ids[i]) + ": no recursive subsample of full rank")
            return
        }
        if (kf>kfmax) {
            kfmax = kf
        }
    }
    Ssum = Ssum :/ sqrt(N)
    Vsum = Vsum :/ N

    // ---------------- search grid ---------------------------------- //
    klo = max((kfmax, 2))
    khi = Teff - 1
    if (trim>0) {
        klo = max((klo, ceil(trim*Teff)))
        khi = min((khi, floor((1-trim)*Teff)))
    }
    if (klo >= khi) {
        st_local("r_err", "the admissible search grid is empty (klo = " + strofreal(klo) + ", khi = " + strofreal(khi) + "); reduce trimming() or lengthen T")
        return
    }

    // ---------------- finite-sample standardisation ---------------- //
    // S(k)^(j) has asymptotic variance s(1-s); its EXACT variance is Vsum.
    // Rescaling to the asymptotic target restores the Brownian-bridge
    // calibration in finite samples.  Vsum -> s(1-s) as (N,T) -> infinity,
    // so this is asymptotically the paper's own statistic.
    real matrix Sstd, Suse
    real scalar sfrac, tgt, vv
    Sstd = J(Teff, K, 0)
    for (t=klo; t<=khi; t++) {
        sfrac = t/Teff
        tgt   = sfrac*(1-sfrac)
        for (j=1; j<=K; j++) {
            vv = Vsum[t,j]
            if (vv < 1e-12) {
                vv = 1e-12
            }
            Sstd[t,j] = Ssum[t,j]*sqrt(tgt/vv)
        }
    }
    Suse = Sstd
    if (dofs==0) {
        Suse = Ssum
    }

    // ---------------- statistics (LXC F5-F6) ----------------------- //
    real rowvector stat, statA
    real matrix Stat
    stat  = J(1, K, 0)
    statA = J(1, K, 0)
    for (j=1; j<=K; j++) {
        stat[j]  = max(abs(Suse[|klo,j \ khi,j|]))
        statA[j] = max(abs(Ssum[|klo,j \ khi,j|]))
    }
    astar = 1 - (1-alpha)^(1/K)
    cv    = xtfb_kinv(astar)

    Stat = J(K, 5, .)
    pmin = 1
    statmax = stat[1]
    jmax = 1
    for (j=1; j<=K; j++) {
        pj = xtfb_kq(stat[j])
        Stat[j,1] = stat[j]
        Stat[j,2] = cv
        Stat[j,3] = pj
        Stat[j,4] = 0
        Stat[j,5] = statA[j]
        if (stat[j] >= cv) {
            Stat[j,4] = 1
        }
        if (pj < pmin) {
            pmin = pj
        }
        if (stat[j] > statmax) {
            statmax = stat[j]
            jmax = j
        }
    }
    real scalar pooled, statasy
    pooled  = 1 - (1-pmin)^K
    statasy = max(statA)

    // ---------------- change point (LXC F7) ------------------------ //
    real matrix Vv
    real colvector vn
    Vv = Ssum :* sqrt(N*Teff)
    vn = J(Teff, 1, .)
    for (t=klo; t<=khi; t++) {
        vn[t] = sqrt(Vv[t,]*Vv[t,]')
    }
    khat = klo
    best = vn[klo]
    for (t=klo+1; t<=khi; t++) {
        if (vn[t] > best) {
            best = vn[t]
            khat = t
        }
    }
    bdate = tvals[khat]
    bpost = tvals[khat]
    if (khat < Teff) {
        bpost = tvals[khat+1]
    }

    // ---------------- per-panel regime contrasts ------------------- //
    real matrix Sh
    real colvector b1, b2
    real matrix X1, X2, S1v, S2v
    real scalar okpre, okpost
    Sh = J(N+3, K+1, .)
    okpre  = (khat >= K)
    okpost = ((Teff - khat) >= K)
    for (i=1; i<=N; i++) {
        Sh[i,1] = ids[i]
        if (okpre) {
            if (okpost) {
                Xi = xtfb_gather(Xw, i, Teff, addc)
                yi = Yw[,i]
                if (docce==1) {
                    Xi = Mw * Xi
                    yi = Mw * yi
                }
                X1 = Xi[|1,1 \ khat,.|]
                X2 = Xi[|khat+1,1 \ Teff,.|]
                S1v = invsym(quadcross(X1,X1))
                S2v = invsym(quadcross(X2,X2))
                if (diag0cnt(S1v)==0) {
                    if (diag0cnt(S2v)==0) {
                        b1 = S1v * quadcross(X1, yi[|1 \ khat|])
                        b2 = S2v * quadcross(X2, yi[|khat+1 \ Teff|])
                        Sh[|i,2 \ i,K+1|] = (b2 - b1)'
                    }
                }
            }
        }
    }
    // summary rows: mean, sd, % positive
    real colvector cj
    real scalar nv, mj, sj, np, r
    frpos = 0
    for (j=1; j<=K; j++) {
        cj = Sh[|1,j+1 \ N,j+1|]
        nv = 0
        mj = 0
        np = 0
        for (r=1; r<=N; r++) {
            if (cj[r] < .) {
                nv = nv + 1
                mj = mj + cj[r]
                if (cj[r] > 0) {
                    np = np + 1
                }
            }
        }
        if (nv > 0) {
            mj = mj/nv
            sj = 0
            for (r=1; r<=N; r++) {
                if (cj[r] < .) {
                    sj = sj + (cj[r]-mj)*(cj[r]-mj)
                }
            }
            if (nv > 1) {
                sj = sqrt(sj/(nv-1))
            }
            Sh[N+1,j+1] = mj
            Sh[N+2,j+1] = sj
            Sh[N+3,j+1] = 100*np/nv
            if (abs(100*np/nv - 50)/50 > frpos) {
                frpos = abs(100*np/nv - 50)/50
            }
        }
    }

    // ---------------- output matrices ------------------------------ //
    real matrix Sout, Vout
    real scalar ng, rix
    ng = khi - klo + 1
    // columns: k | time | decision path (K) | literal LXC path (K)
    Sout = J(ng, 2*K+2, .)
    Vout = J(ng, 3, .)
    rix = 0
    for (t=klo; t<=khi; t++) {
        rix = rix + 1
        Sout[rix,1] = t
        Sout[rix,2] = tvals[t]
        Sout[|rix,3 \ rix,K+2|] = Suse[t,]
        Sout[|rix,K+3 \ rix,2*K+2|] = Ssum[t,]
        Vout[rix,1] = t
        Vout[rix,2] = tvals[t]
        Vout[rix,3] = vn[t]
    }

    st_matrix(nmS,    Sout)
    st_matrix(nmV,    Vout)
    st_matrix(nmStat, Stat)
    st_matrix(nmBi,   Bi)
    st_matrix(nmSh,   Sh)
    st_matrix(nmSig,  Sig)

    // "%18.0g" keeps full precision: the default %9.0g would round a daily
    // date or a long test statistic on its way back into a Stata local.
    st_local("r_N",     strofreal(N,     "%18.0g"))
    st_local("r_T",     strofreal(Teff,  "%18.0g"))
    st_local("r_K",     strofreal(K,     "%18.0g"))
    st_local("r_klo",   strofreal(klo,   "%18.0g"))
    st_local("r_khi",   strofreal(khi,   "%18.0g"))
    st_local("r_khat",  strofreal(khat,  "%18.0g"))
    st_local("r_stat",  strofreal(statmax, "%18.0g"))
    st_local("r_statasy", strofreal(statasy, "%18.0g"))
    st_local("r_pasy",  strofreal(1-(1-xtfb_kq(statasy))^K, "%18.0g"))
    st_local("r_cv",    strofreal(cv,    "%18.0g"))
    st_local("r_p",     strofreal(pooled, "%18.0g"))
    st_local("r_astar", strofreal(astar, "%18.0g"))
    st_local("r_jmax",  strofreal(jmax,  "%18.0g"))
    st_local("r_bdate", strofreal(bdate, "%18.0g"))
    st_local("r_bpost", strofreal(bpost, "%18.0g"))
    st_local("r_frpos", strofreal(frpos, "%18.0g"))

    // ---------------- benchmarks (Antoch et al.) ------------------- //
    if (docmp==1) {
        xtfb_compare(nmCmp, nmCP, Xw, Yw, ids, N, Teff, p, hascons, tvals,
                     reps, alpha)
    }
}

// ================================================================== //
// BENCHMARKS: Wald 1, Wald 2, CUSUM  (Antoch et al. 2018, A1-A9)
// Always on the RAW data with an intercept -- exactly the configuration
// LXC use in Tables 1-9.
// ================================================================== //
void xtfb_compare(string scalar nmCmp, string scalar nmCP,
                  pointer(real matrix) rowvector Xw, real matrix Yw,
                  real colvector ids, real scalar N, real scalar T,
                  real scalar p, real scalar hascons, real colvector tvals,
                  real scalar reps, real scalar alpha)
{
    real scalar Kc, i, t, tlo, thi, ng, kf, kfmax, b, j
    real matrix Xi, Zt, ZT, ZTi, Zti, C1, C2
    real colvector yi, bT, e, st, xt
    real scalar s2a, cs
    real matrix Q1, Q2, QV, A1, A2, AV
    real rowvector u1p, u2p, uvp
    real scalar u1, u2, uv
    real matrix P1, P2, PV
    real colvector z, bs1, bs2, bsv
    real scalar m1, m2, mv
    real matrix Cmp, CP

    st_local("r_cmpok", "0")

    Kc = p + hascons
    if (Kc < 1) {
        return
    }

    kfmax = Kc
    for (i=1; i<=N; i++) {
        Xi = xtfb_gather(Xw, i, T, hascons)
        kf = xtfb_kfull(Xi)
        if (kf==0) {
            return
        }
        if (kf>kfmax) {
            kfmax = kf
        }
    }
    tlo = max((kfmax, Kc))
    thi = T - Kc
    if (tlo >= thi) {
        return
    }
    ng = thi - tlo + 1

    Q1 = J(N, ng, 0)
    Q2 = J(N, ng, 0)
    QV = J(N, ng, 0)
    A1 = J(N, ng, 0)
    A2 = J(N, ng, 0)
    AV = J(N, ng, 0)

    for (i=1; i<=N; i++) {
        Xi  = xtfb_gather(Xw, i, T, hascons)
        yi  = Yw[,i]
        ZT  = quadcross(Xi, Xi)
        ZTi = invsym(ZT)
        bT  = ZTi * quadcross(Xi, yi)
        e   = yi - Xi*bT
        s2a = quadcross(e, e) / (T - Kc)
        Zt  = J(Kc, Kc, 0)
        st  = J(Kc, 1, 0)
        cs  = 0
        for (t=1; t<=T; t++) {
            xt = Xi[t,]'
            Zt = Zt + xt*xt'
            st = st + xt*e[t]
            cs = cs + e[t]*e[t]
            if (t>=tlo) {
                if (t<=thi) {
                    j   = t - tlo + 1
                    Zti = invsym(Zt)
                    C1  = Zt*Zt
                    C2  = Zt*ZTi*Zt
                    Q1[i,j] = quadcross(st, st)
                    Q2[i,j] = (st' * ZTi * st)
                    QV[i,j] = cs
                    A1[i,j] = s2a * trace(C1*(Zti - ZTi))
                    A2[i,j] = s2a * trace(C2*(Zti - ZTi))
                    AV[i,j] = s2a * (t - trace(Zt*ZTi))
                }
            }
        }
    }

    // observed statistics (A8)
    u1p = (colsum(Q1) - colsum(A1)) :/ sqrt(N)
    u2p = (colsum(Q2) - colsum(A2)) :/ sqrt(N)
    uvp = (colsum(QV) - colsum(AV)) :/ sqrt(N)
    u1 = max(abs(u1p))
    u2 = max(abs(u2p))
    uv = max(abs(uvp))

    // wild bootstrap (A9)
    P1 = Q1 :- (J(N,1,1) * (colsum(Q1):/N))
    P2 = Q2 :- (J(N,1,1) * (colsum(Q2):/N))
    PV = QV :- (J(N,1,1) * (colsum(QV):/N))

    bs1 = J(reps,1,.)
    bs2 = J(reps,1,.)
    bsv = J(reps,1,.)
    for (b=1; b<=reps; b++) {
        z = rnormal(N,1,0,1)
        bs1[b] = max(abs((P1' * z) :/ sqrt(N)))
        bs2[b] = max(abs((P2' * z) :/ sqrt(N)))
        bsv[b] = max(abs((PV' * z) :/ sqrt(N)))
    }

    m1 = 0
    m2 = 0
    mv = 0
    for (b=1; b<=reps; b++) {
        if (bs1[b] >= u1) {
            m1 = m1 + 1
        }
        if (bs2[b] >= u2) {
            m2 = m2 + 1
        }
        if (bsv[b] >= uv) {
            mv = mv + 1
        }
    }

    Cmp = J(3, 3, .)
    Cmp[1,1] = u1
    Cmp[1,2] = xtfb_bq(bs1, alpha)
    Cmp[1,3] = m1/reps
    Cmp[2,1] = u2
    Cmp[2,2] = xtfb_bq(bs2, alpha)
    Cmp[2,3] = m2/reps
    Cmp[3,1] = uv
    Cmp[3,2] = xtfb_bq(bsv, alpha)
    Cmp[3,3] = mv/reps

    CP = J(ng, 5, .)
    for (j=1; j<=ng; j++) {
        CP[j,1] = tlo + j - 1
        CP[j,2] = tvals[tlo + j - 1]
        CP[j,3] = abs(u1p[j])
        CP[j,4] = abs(u2p[j])
        CP[j,5] = abs(uvp[j])
    }

    st_matrix(nmCmp, Cmp)
    st_matrix(nmCP,  CP)
    st_local("r_cmpok", "1")
}

end
