*! xtcombreak 1.0.0  17jul2026
*! Common breaks in panel data: estimation (Bai 2010) and testing (Jiang-Kurozumi 2026)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Implements, faithfully to the two papers:
*!   Bai, J. (2010) "Common breaks in means and variances for panel data",
*!     Journal of Econometrics 157, 78-92. <doi:10.1016/j.jeconom.2009.10.020>
*!     -- subcommand: estimate.  LS / QML / feasible-GLS estimation of the common
*!        break date, Bai's parameter-free confidence interval, per-series Chow.
*!   Jiang, P. & Kurozumi, E. (2026) "A new test for common breaks in
*!     heterogeneous panel data models", Econometrics and Statistics 37, 87-125.
*!     <doi:10.1016/j.ecosta.2023.01.005>
*!     -- subcommand: test.  Self-normalised CUSUM test of the null that the
*!        break date is COMMON across units.
*!
*! Step -> equation map (full version: help xtcombreak methods):
*!   estimate
*!     E2  SiT(k) = sum_{t<=k}(Yit-Ybar_i1)^2 + sum_{t>k}(Yit-Ybar_i2)^2   Bai p.80
*!     E3  khat = argmin_{1<=k<=T-1} sum_i SiT(k)                          Bai p.80
*!     E4  UNT(k) = k*sum_i log s2_i1(k) + (T-k)*sum_i log s2_i2(k)        Bai eq.16
*!     E6  FGLS: s2_i = SiT(khat)/(T-2); khat = argmin sum_i SiT(k)/s2_i   Bai p.85
*!     E7  A_N = [sum_i d_i^2]^2 / [sum_i d_i^2 s2_i]                      Bai p.83
*!     E8  CI  = [khat - floor(c/A_N), khat + ceil(c/A_N)], c=7,11,20      Bai eq.13
*!     E9  B_N = sum_i d_i^2/s2_i   (QML scale; A_N <= B_N by Cauchy-Schwarz) Bai p.85
*!     E10 QML master scale (tau+w/2)^2/[tau+(2+k4)w/4+m3*pi]              Bai eq.19
*!     E11 per-series Chow at khat ~ chi2(1)                               Bai p.84
*!     E12 multiple breaks, one-at-a-time                                  Bai sec.6
*!   test
*!     J1  khat = argmin_{m<=k<=T-m} sum_i SSR_i(k)                        JK eq.3
*!     J3  uhat_i = Y_i - Xbar_i(khat) bhat_i(khat)                        JK eq.4
*!     J4  US_NT(k,khat) = ((NT)^(-1/2) sum_i sum_{t<=k} uhat_it)^2        JK eq.5
*!     J6  utilde from the 4-regime design [X, X1(k1,khat), X2(khat,k2), X3(k2)] JK eq.8-9
*!     J7  V_NT(k1,khat,k2), four terms (2nd and 4th are BACKWARD sums)    JK eq.10
*!     J8  S_NT = sup US / V over Lambda(eps)                              JK sec.3
*!     J10 critical values                                                 JK Table 1
*!
*! Exact reductions used (proved in help xtcombreak methods):
*!   (EQ-A) Lambda(eps) is a product set => sup US/V = [sup_k US]/[inf_{k1,k2} V]
*!   (EQ-B) V(k1,khat,k2) = A(k1) + B(k2)  => inf V = min_k1 A + min_k2 B
*!   (EQ-C) the stacked 4-regime design spans the regime-block design
*!          => utilde equals four separate per-block OLS residual vectors
*!   Net cost O(T*N*p^3) instead of O(T^3*N*p^3).

program define xtcombreak, rclass
    version 14.0

    gettoken sub 0 : 0, parse(" ,")

    if ("`sub'"=="") {
        di as error "subcommand required: {bf:estimate}, {bf:test} or {bf:all}"
        di as error "see {help xtcombreak}"
        exit 198
    }

    if ("`sub'"=="version") {
        di as text "xtcombreak version " as result "1.0.0" as text "  17jul2026"
        return local version "1.0.0"
        exit
    }

    /* abbreviations: est.. -> estimate, tes|test -> test, all -> all */
    if (regexm("`sub'","^est") | "`sub'"=="e") {
        xtcb_estimate `0'
        return add
        exit
    }
    if (regexm("`sub'","^tes") | "`sub'"=="t") {
        xtcb_test `0'
        return add
        exit
    }
    if ("`sub'"=="all") {
        xtcb_all `0'
        return add
        exit
    }

    di as error "unknown subcommand {bf:`sub'}"
    di as error "allowed: {bf:estimate}, {bf:test}, {bf:all}"
    exit 198
end


/* ====================================================================== *
 *  ALL : run the recommended pipeline (test then estimate)
 * ====================================================================== */
program define xtcb_all, rclass
    version 14.0
    /* options are split explicitly: estimate and test do NOT share an option
       set, so a single `*' passthrough would error on the other subcommand. */
    syntax varlist(min=1 numeric ts) [if] [in] [ ,   ///
        Method(string)                               ///
        BReaks(integer 1)                            ///
        ANmethod(string)                             ///
        CHow                                         ///
        TRIMming(real 0.1)                           ///
        NOCONStant                                   ///
        SIMulate                                     ///
        REPS(integer 2000)                           ///
        GRIDpoints(integer 1000)                     ///
        SEED(string)                                 ///
        SHOWindex                                    ///
        GRAPH ]

    local estopt "breaks(`breaks') `chow' `showindex' `graph'"
    if ("`method'"!="")   local estopt "`estopt' method(`method')"
    if ("`anmethod'"!="") local estopt "`estopt' anmethod(`anmethod')"

    local tstopt "trimming(`trimming') reps(`reps') gridpoints(`gridpoints') `noconstant' `simulate' `showindex' `graph'"
    if ("`seed'"!="") local tstopt "`tstopt' seed(`seed')"

    gettoken dv xv : varlist

    di ""
    di as text "{hline 79}"
    di as text "xtcombreak all" _col(20) "recommended sequence for a panel common break"
    di as text "{hline 79}"
    di as text " Stage 1 " as result "does a break exist at all?" as text "  -- NOT provided by either paper."
    di as text "          Bai (2010, p.79): estimation is 'given its existence'."
    di as text "          Run {stata xtbreak test `varlist'} first if you have not."
    di as text " Stage 2 " as result "is the break COMMON across units?" as text "  -- Jiang-Kurozumi (2026)."
    di as text " Stage 3 " as result "the date, its CI, and which series broke" as text "  -- Bai (2010)."
    di as text "{hline 79}"

    if ("`xv'"!="") {
        xtcb_test `varlist' `if' `in', `tstopt'
        local Sv = r(S)
        local c5 = r(cv05)
    }
    else {
        di ""
        di as text "note: {bf:test} needs at least one regressor (Jiang-Kurozumi eq.1);"
        di as text "      with a pure mean shift only {bf:estimate} applies."
        local Sv = .
    }

    xtcb_estimate `dv' `if' `in', `estopt'
    return add

    di ""
    di as text "{hline 79}"
    di as text "Pre-test caveat"
    di as text "{hline 79}"
    di as text " Reporting the Bai CI conditional on having passed the Jiang-Kurozumi"
    di as text " test makes it a {bf:pre-test estimator}: its true coverage is not the"
    di as text " nominal level. Neither paper quantifies this distortion."
    di as text " A non-rejection is {bf:not} a certificate of a common break -- the test"
    di as text " has low power against close breaks, unbalanced groups, and breaks in"
    di as text " opposite directions (JK Tables 6-7 and sec.5)."
    di as text "{hline 79}"
    di ""
end


/* ====================================================================== *
 *  ESTIMATE :  Bai (2010)
 * ====================================================================== */
program define xtcb_estimate, rclass
    version 14.0

    syntax varlist(numeric ts) [if] [in] [ ,      ///
        Method(string)                            ///
        BReaks(integer 1)                         ///
        TRIMming(real 0)                          ///
        Level(real 95)                            ///
        ANmethod(string)                          ///
        CImethod(string)                          ///
        CHow                                      ///
        SHOWindex                                 ///
        GRAPH                                     ///
        PROFname(string)                          ///
        SHIFTname(string) ]

    /* ---- Bai (2010) has NO regressors: refuse an indepvar list --------- */
    local nv : word count `varlist'
    if (`nv'>1) {
        gettoken dv xv : varlist
        di as error "{bf:xtcombreak estimate} takes exactly one variable."
        di as error "Bai (2010) is a pure mean/variance-shift model with no regressors (his eq.1 and eq.15)."
        di as error "You listed regressors: `xv'"
        di as error "  -> for a common break in SLOPES use {bf:xtcombreak test} (Jiang-Kurozumi) or"
        di as error "     {bf:xtbfkbreak} / {bf:xtbreak} (Baltagi-Feng-Kao / Bai-Perron)."
        exit 198
    }
    local dv `varlist'

    /* ---- options ------------------------------------------------------ */
    if ("`method'"=="") local method "ls"
    local method = lower("`method'")
    if (!inlist("`method'","ls","qml","gls")) {
        di as error "method() must be {bf:ls}, {bf:qml} or {bf:gls}"
        exit 198
    }
    if ("`anmethod'"=="") local anmethod "het"
    local anmethod = lower("`anmethod'")
    if (!inlist("`anmethod'","het","hom")) {
        di as error "anmethod() must be {bf:het} (Bai's general A_N, p.83) or {bf:hom} (his Monte-Carlo form)"
        exit 198
    }
    if ("`cimethod'"=="") local cimethod "symmetric"
    local cimethod = lower("`cimethod'")
    if (!inlist("`cimethod'","symmetric","literal")) {
        di as error "cimethod() must be {bf:symmetric} (reproduces Bai's Table 1) or {bf:literal} (eq.13 as printed)"
        di as error "see {bf:help xtcombreak methods} for why these differ"
        exit 198
    }
    if (!inlist(`level',90,95,99)) {
        di as error "level() must be 90, 95 or 99."
        di as error "Bai (2010, p.83) tabulates the constants of argmin_l{c 123}|l|+2W(l){c 125} only at these three"
        di as error "levels (7, 11, 20). Interpolating them is not supported."
        exit 198
    }
    if (`trimming'<0 | `trimming'>=0.5) {
        di as error "trimming() must lie in [0, 0.5)"
        exit 198
    }
    if (`breaks'<1) {
        di as error "breaks() must be a positive integer"
        exit 198
    }

    /* ---- panel bookkeeping -------------------------------------------- */
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data must be {help xtset} as a panel (panel and time)"
        exit 459
    }

    marksample touse
    markout `touse' `ivar' `tvar'

    tempvar tcount
    qui bysort `touse' `ivar' (`tvar'): gen long `tcount' = _N if `touse'
    qui su `tcount' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    if (`Tmin'!=`Tmax') {
        di as error "xtcombreak requires a balanced panel on the estimation sample"
        di as error "  (min T = `Tmin', max T = `Tmax')"
        exit 459
    }
    qui count if `touse'
    if (r(N)==0) {
        di as error "no observations"
        exit 2000
    }

    sort `ivar' `tvar'

    /* NOTE: the tempname must NOT be called `chow' -- that would clobber the
       local created by the CHow option in syntax above. */
    tempname prof brk ci shift chowm sig2 pars
    mata: xtcb_bai_run("`prof'","`brk'","`ci'","`shift'","`chowm'","`sig2'","`pars'")

    local N    = `r_N'
    local T    = `r_T'
    local khat = `r_khat'
    local nb   = `r_nbrk'
    local nties = `r_nties'

    /* ---- header notes on the asymptotic regime ------------------------ */
    local TNratio = `T'/`N'

    /* ---- graphs BEFORE any return matrix move (gotcha #6) ------------- */
    /* Defaults are set HERE, not in the sub-program: passing an empty
       option -- profname() -- to a syntax expecting profname(string)
       raises "something required" (r(100)). */
    if ("`profname'"=="")  local profname  "xtcb_profile"
    if ("`shiftname'"=="") local shiftname "xtcb_shift"
    if ("`graph'"!="") {
        xtcb_gest, profmat(`prof') brk(`brk') ci(`ci') shiftmat(`shift') chowmat(`chowm') ///
            method(`method') dv(`dv') level(`level') nb(`nb') n(`N') t(`T')             ///
            profname(`profname') shiftname(`shiftname')
    }

    /* ---- display ------------------------------------------------------ */
    xtcb_dest, brk(`brk') ci(`ci') shift(`shift') chowmat(`chowm') pars(`pars') ///
        method(`method') anmethod(`anmethod') dv(`dv') level(`level')           ///
        n(`N') t(`T') nb(`nb') khat(`khat') nties(`nties')                      ///
        ivar(`ivar') tvar(`tvar') trimming(`trimming') `chow' `showindex'

    /* ---- returns ------------------------------------------------------ */
    return scalar N      = `N'
    return scalar T      = `T'
    return scalar khat   = `khat'
    return scalar k_breaks = `nb'
    return scalar nties  = `nties'
    return scalar AN     = `r_AN'
    return scalar BN     = `r_BN'
    return scalar tau    = `r_tau'
    return scalar omega  = `r_omega'
    return scalar kappa  = `r_kappa'
    return scalar mu3    = `r_mu3'
    return scalar piprm  = `r_pi'
    return scalar scale  = `r_scale'
    return scalar ssr    = `r_ssr'
    return scalar TNratio = `TNratio'
    return local  method  "`method'"
    return local  anmethod "`anmethod'"
    return local  depvar  "`dv'"
    return local  panelvar "`ivar'"
    return local  timevar  "`tvar'"
    return local  cmd     "xtcombreak estimate"
    return matrix ssrprofile = `prof', copy
    return matrix breakdates = `brk', copy
    return matrix ci         = `ci', copy
    return matrix shift      = `shift', copy
    return matrix chow       = `chowm', copy
    return matrix sigma2     = `sig2', copy
end


/* ====================================================================== *
 *  TEST :  Jiang & Kurozumi (2026)
 * ====================================================================== */
program define xtcb_test, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in] [ , ///
        TRIMming(real 0.1)                         ///
        NOCONStant                                 ///
        SIMulate                                   ///
        REPS(integer 2000)                         ///
        GRIDpoints(integer 1000)                   ///
        SEED(string)                               ///
        Level(real 5)                              ///
        SHOWindex                                  ///
        GRAPH                                      ///
        CUSUMname(string)                          ///
        SHIFTname(string) ]

    gettoken dv xv : varlist

    if (`trimming'<=0 | `trimming'>=0.5) {
        di as error "trimming() must lie strictly in (0, 0.5)"
        exit 198
    }
    if (!inlist(`level',10,5,1)) {
        di as error "level() must be 10, 5 or 1 (percent)"
        di as error "Jiang-Kurozumi (2026) Table 1 tabulates only these three."
        exit 198
    }

    local hascons = 1
    if ("`noconstant'"!="") local hascons = 0

    /* the table is valid ONLY at eps = 0.1 -- refuse to misuse it -------- */
    local usetable = 1
    if (abs(`trimming'-0.1)>1e-8) local usetable = 0
    if ("`simulate'"!="") local usetable = 0

    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data must be {help xtset} as a panel (panel and time)"
        exit 459
    }

    marksample touse
    markout `touse' `ivar' `tvar'

    tempvar tcount
    qui bysort `touse' `ivar' (`tvar'): gen long `tcount' = _N if `touse'
    qui su `tcount' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    if (`Tmin'!=`Tmax') {
        di as error "xtcombreak requires a balanced panel on the estimation sample"
        di as error "  (min T = `Tmin', max T = `Tmax')"
        exit 459
    }
    sort `ivar' `tvar'

    if ("`seed'"!="") set seed `seed'

    tempname cusum brk deltas Vprof
    mata: xtcb_jk_run("`cusum'","`brk'","`deltas'","`Vprof'")

    local N    = `r_N'
    local T    = `r_T'
    local khat = `r_khat'
    local S    = `r_S'
    local tau0 = `r_tau0'
    local nume = `r_num'
    local deno = `r_den'
    local conc = `r_conc'
    local TNratio = `T'/`N'

    /* ---- critical values ---------------------------------------------- */
    tempname cvm
    local pval = .
    if (`usetable') {
        mata: xtcb_cvtable("`cvm'", `tau0')
        local cv10 = `cvm'[1,1]
        local cv05 = `cvm'[1,2]
        local cv01 = `cvm'[1,3]
        local cvsrc "Jiang-Kurozumi (2026), Table 1"
    }
    else {
        di as text "note: simulating critical values (" as result "`reps'" as text " reps, " as result "`gridpoints'" as text " grid points) ..."
        mata: xtcb_simcv("`cvm'", `tau0', `trimming', `reps', `gridpoints', `S')
        local cv10 = `cvm'[1,1]
        local cv05 = `cvm'[1,2]
        local cv01 = `cvm'[1,3]
        local pval = `cvm'[1,4]
        local cvsrc "simulated from JK Theorem 1"
    }

    local cvuse = `cv05'
    if (`level'==10) local cvuse = `cv10'
    if (`level'==1)  local cvuse = `cv01'

    /* defaults set here -- an empty cusumname() would raise r(100) */
    if ("`cusumname'"=="") local cusumname "xtcb_cusum"
    if ("`shiftname'"=="") local shiftname "xtcb_dsign"
    if ("`graph'"!="") {
        xtcb_gtest, cusummat(`cusum') deltas(`deltas') vprof(`Vprof') khat(`khat') ///
            dv(`dv') n(`N') t(`T') s(`S') cv(`cvuse') level(`level')                ///
            denom(`deno') cusumname(`cusumname') shiftname(`shiftname')
    }

    xtcb_dtest, s(`S') cv10(`cv10') cv05(`cv05') cv01(`cv01') pval(`pval')   ///
        cvsrc("`cvsrc'") khat(`khat') tau0(`tau0') n(`N') t(`T')             ///
        dv(`dv') xv(`xv') ivar(`ivar') tvar(`tvar') trimming(`trimming')     ///
        conc(`conc') num(`nume') den(`deno') brk(`brk') `showindex'          ///
        tnratio(`TNratio') usetable(`usetable')

    return scalar S      = `S'
    return scalar p      = `pval'
    return scalar cv10   = `cv10'
    return scalar cv05   = `cv05'
    return scalar cv01   = `cv01'
    return scalar khat   = `khat'
    return scalar tau0   = `tau0'
    return scalar N      = `N'
    return scalar T      = `T'
    return scalar numerator   = `nume'
    return scalar denominator = `deno'
    return scalar concord = `conc'
    return scalar TNratio = `TNratio'
    return local  depvar  "`dv'"
    return local  indepvars "`xv'"
    return local  panelvar "`ivar'"
    return local  timevar  "`tvar'"
    return local  cvsource "`cvsrc'"
    return local  cmd     "xtcombreak test"
    return matrix cusum   = `cusum', copy
    return matrix breakdate = `brk', copy
    return matrix delta   = `deltas', copy
end


/* ====================================================================== *
 *  DISPLAY : estimate
 * ====================================================================== */
program define xtcb_dest
    version 14.0
    syntax , brk(name) ci(name) shift(name) chowmat(name) pars(name)       ///
             method(string) anmethod(string) dv(string) level(real)        ///
             n(integer) t(integer) nb(integer) khat(integer)               ///
             nties(integer) ivar(string) tvar(string) trimming(real)       ///
             [ CHow SHOWindex ]

    local mname "Least squares"
    if ("`method'"=="qml") local mname "Quasi-maximum likelihood"
    if ("`method'"=="gls") local mname "Feasible GLS (two-step)"

    /* brk is 2 x nbrk: row 1 = calendar dates, row 2 = indices 1..T */
    local bd  = `brk'[1,1]
    local bdi = `brk'[2,1]
    local lo = `ci'[1,1]
    local hi = `ci'[1,2]
    local loi = `ci'[1,3]
    local hii = `ci'[1,4]

    di ""
    di as text "{hline 79}"
    di as text "Common break in means and variances for panel data" _col(62) "(Bai 2010)"
    di as text "{hline 79}"
    di as text "Estimator      : " as result "`mname'"
    di as text "Series         : " as result "`dv'" _col(45) as text "N (series)   = " as result %8.0g `n'
    di as text "Panel variable : " as result "`ivar'" _col(45) as text "T (periods)  = " as result %8.0g `t'
    di as text "Time variable  : " as result "`tvar'" _col(45) as text "T/N          = " as result %8.2f `t'/`n'
    if (`trimming'==0) {
        di as text "Trimming       : " as result "none (k in [1, T-1])" _col(45) as text "No. breaks   = " as result %8.0g `nb'
    }
    else {
        di as text "Trimming       : " as result %5.2f `trimming' _col(45) as text "No. breaks   = " as result %8.0g `nb'
    }
    di as text "{hline 79}"

    /* ---- the quantity of interest: the break date + its CI ------------ */
    di ""
    di as text "Estimated common break date" _col(48) "[`level'% conf. interval]"
    di as text "{hline 79}"
    di as text %-22s "Quantity" " " %14s "Estimate" " " %5s "" "  " %14s "Lower" " " %14s "Upper"
    di as text "{hline 79}"
    di as text %-22s "Break date (`tvar')" " " as result %14.0g `bd' " " %5s "" "  " %14.0g `lo' " " %14.0g `hi'
    if ("`showindex'"!="") {
        di as text %-22s "Break index (1..T)" " " as result %14.0g `bdi' " " %5s "" "  " %14.0g `loi' " " %14.0g `hii'
    }
    local tfrac = `khat'/`t'
    di as text %-22s "Break fraction tau0" " " as result %14.4f `tfrac'
    if (`nb'>1) {
        di as text "{hline 79}"
        di as text "Additional break dates (one-at-a-time, Bai sec.6):"
        forval j = 2/`nb' {
            local bj  = `brk'[1,`j']
            local bji = `brk'[2,`j']
            di as text "   break `j'" _col(24) as result %14.0g `bj' as text "   (index " as result %4.0f `bji' as text ")"
        }
    }
    di as text "{hline 79}"

    local anv = `pars'[1,1]
    local bnv = `pars'[1,2]
    local sc  = `pars'[1,7]
    local cst = 7
    if (`level'==95) local cst = 11
    if (`level'==99) local cst = 20

    di as text "CI from Bai eq.(13): [khat - floor(`cst'/A), khat + ceil(`cst'/A)],  A = " as result %9.4f `sc'
    di as text "  where P(|argmin_l{c 123}|l| + 2W(l){c 125}| <= `cst') ~= " as result %4.2f `level'/100 as text "  (Bai p.83, W a two-sided Gaussian random walk)"
    if (`nties'>1) {
        di as text "  note: " as result "`nties'" as text " values of k attain the minimum; the smallest is reported."
    }
    di ""

    /* ---- efficiency block --------------------------------------------- */
    di as text "Scale parameters and CI efficiency"
    di as text "{hline 79}"
    di as text %-34s "Parameter" " " %12s "Value" "  " %28s "Source"
    di as text "{hline 79}"
    di as text %-34s "A_N  (least squares scale)" " " as result %12.4f `anv' "  " as text %28s "Bai p.83"
    di as text %-34s "B_N  (QML / GLS scale)" " " as result %12.4f `bnv' "  " as text %28s "Bai p.85"
    if (`bnv'>0 & `anv'>0) {
        local rat = `bnv'/`anv'
        di as text %-34s "B_N / A_N  (>=1 always)" " " as result %12.4f `rat' "  " as text %28s "Cauchy-Schwarz, Bai p.85"
    }
    if ("`method'"=="qml" | "`method'"=="gls") {
        local tauv = `pars'[1,3]
        local omev = `pars'[1,4]
        local kapv = `pars'[1,5]
        local mu3v = `pars'[1,6]
        local piv  = `pars'[1,8]
        di as text %-34s "tau   (mean-break signal)" " " as result %12.4f `tauv' "  " as text %28s "Bai p.84"
        di as text %-34s "omega (variance-break signal)" " " as result %12.4f `omev' "  " as text %28s "Bai p.84"
        di as text %-34s "kappa (4th cumulant of eta)" " " as result %12.4f `kapv' "  " as text %28s "Bai p.85"
        di as text %-34s "mu3   (3rd moment of eta)" " " as result %12.4f `mu3v' "  " as text %28s "Bai Remark 1"
        di as text %-34s "pi    (mean-var break overlap)" " " as result %12.4f `piv' "  " as text %28s "Bai eq.19"
    }
    di as text "{hline 79}"
    di as text "A_N {c 60}= B_N always (Cauchy-Schwarz): QML/GLS is never less efficient than LS,"
    di as text "and is strictly more efficient unless sigma_i{c 94}2 is constant across i (Bai p.85)."
    di ""

    /* ---- per-series Chow ---------------------------------------------- */
    if ("`chow'"!="") {
        local nr = rowsof(`chowmat')
        di as text "Which series actually broke?  Chow test at khat, series by series"
        di as text "{hline 79}"
        di as text %-10s "Series" " " %12s "mu_i2-mu_i1" " " %12s "Chow chi2(1)" " " %9s "P>chi2" "  " %10s "sigma_i^2"
        di as text "{hline 79}"
        local nrej10 = 0
        local nrej05 = 0
        local shown = 0
        forval i = 1/`nr' {
            local id = `chowmat'[`i',1]
            local dl = `shift'[`i',2]
            local c2 = `chowmat'[`i',2]
            local pv = `chowmat'[`i',3]
            local s2 = `chowmat'[`i',4]
            if (`pv'<0.10) local nrej10 = `nrej10' + 1
            if (`pv'<0.05) local nrej05 = `nrej05' + 1
            local st = ""
            if (`pv'<0.10) local st "*"
            if (`pv'<0.05) local st "**"
            if (`pv'<0.01) local st "***"
            if (`shown'<20) {
                di as text %-10.0g `id' " " as result %12.4f `dl' " " %12.4f `c2' " " %9.3f `pv' "  " %10.4f `s2' as text " `st'"
                local shown = `shown' + 1
            }
        }
        if (`nr'>20) {
            di as text "  ... (" as result "`=`nr'-20'" as text " further series suppressed; full matrix in {bf:r(chow)})"
        }
        di as text "{hline 79}"
        di as text "Series with a detected break: " as result "`nrej05'" as text " of " as result "`nr'" as text " at 5%, " as result "`nrej10'" as text " at 10%."
        di as text "Significance: * p<.10, ** p<.05, *** p<.01."
        di as text "Valid because as N grows, series i contributes O(1/N) of khat, so khat is"
        di as text "asymptotically exogenous for series i and chi2 critical values apply (Bai p.84)."
        if (`n'<15) {
            di as text "{bf:warning}: with N = " as result "`n'" as text " that argument is thin -- series i drives ~" as result %3.0f 100/`n' as text "% of khat."
        }
        di ""
    }

    /* ---- honest notes -------------------------------------------------- */
    di as text "{hline 79}"
    di as text "Notes"
    di as text "{hline 79}"
    di as text " . Bai (2010) estimates the break {bf:given that one exists} (p.79); it provides"
    di as text "   no test for existence. Run {stata xtbreak test `dv'} for that stage."
    di as text " . Is this break really COMMON across series? Bai assumes it. Test it with"
    di as text "   {bf:xtcombreak test} (Jiang-Kurozumi 2026)."
    if (`t' < `n') {
        di as text " . {bf:T < N} (T/N = " as result %4.2f `t'/`n' as text "). The point estimate khat stays consistent under Bai's"
        di as text "   Assumption 2, which needs no T/N condition. But the {bf:CI} rests on his"
        di as text "   eq.(5), N*log(log T)/T -> 0, i.e. T large relative to N. Read the CI with care."
    }
    if (`nb'>1) {
        di as text " . Bai derives no CI for {bf:multiple} breaks; the interval above is reported"
        di as text "   for the first break only and is indicative."
        di as text " . Multiple breaks use the one-at-a-time method (Bai sec.6 / Bai 1997a)."
    }
    di as text " . Cross-sectional independence is assumed (Bai Assumption 1). Check with"
    di as text "   {stata xtcd2 `dv'} or {bf:xttestpanel csd}."
    di as text "{hline 79}"
    di ""
end


/* ====================================================================== *
 *  DISPLAY : test
 * ====================================================================== */
program define xtcb_dtest
    version 14.0
    syntax , s(real) cv10(real) cv05(real) cv01(real) pval(real)          ///
             cvsrc(string) khat(integer) tau0(real) n(integer) t(integer) ///
             dv(string) xv(string) ivar(string) tvar(string)              ///
             trimming(real) conc(real) num(real) den(real) brk(name)      ///
             tnratio(real) usetable(integer) [ SHOWindex ]

    local bd = `brk'[1,1]

    di ""
    di as text "{hline 79}"
    di as text "Test for a COMMON break in heterogeneous panels" _col(56) "(Jiang-Kurozumi)"
    di as text "{hline 79}"
    di as text "H0: k0_i = k0 for all i" _col(45) as text "(the break is common)"
    di as text "HA: k0_g1 {c 138} k0_g2 for some groups" _col(45) as text "(break dates differ)"
    di as text "{hline 79}"
    di as text "Dependent var  : " as result "`dv'" _col(45) as text "N (series)   = " as result %8.0g `n'
    di as text "Regressors     : " as result "`xv'" _col(45) as text "T (periods)  = " as result %8.0g `t'
    di as text "Panel variable : " as result "`ivar'" _col(45) as text "T/N          = " as result %8.2f `tnratio'
    di as text "Trimming (eps) : " as result %5.2f `trimming' _col(45) as text "Estimated k  = " as result %8.0g `bd'
    di as text "{hline 79}"

    di ""
    di as text "Test statistic"
    di as text "{hline 79}"
    di as text %-30s "Quantity" " " %14s "Value" "  " %28s "Reference"
    di as text "{hline 79}"
    di as text %-30s "S_NT (sup CUSUM / normaliser)" " " as result %14.4f `s' "  " as text %28s "JK sec.3"
    di as text %-30s "  numerator  sup_k US_NT" " " as result %14.4f `num' "  " as text %28s "JK eq.5"
    di as text %-30s "  denominator inf V_NT" " " as result %14.4f `den' "  " as text %28s "JK eq.10"
    di as text %-30s "tau0-hat = khat/T" " " as result %14.4f `tau0' "  " as text %28s "JK Theorem 1"
    di as text "{hline 79}"

    di ""
    di as text "Critical values" _col(50) "(`cvsrc')"
    di as text "{hline 79}"
    di as text %-14s "Level" " " %14s "Crit. value" " " %14s "Reject H0?" "  " %20s ""
    di as text "{hline 79}"
    local d10 = "no"
    local d05 = "no"
    local d01 = "no"
    if (`s'>`cv10') local d10 "YES"
    if (`s'>`cv05') local d05 "YES"
    if (`s'>`cv01') local d01 "YES"
    di as text %-14s "10%" " " as result %14.3f `cv10' " " %14s "`d10'"
    di as text %-14s "5%"  " " as result %14.3f `cv05' " " %14s "`d05'"
    di as text %-14s "1%"  " " as result %14.3f `cv01' " " %14s "`d01'"
    di as text "{hline 79}"
    if (`pval'<.) {
        di as text "p-value = " as result %6.4f `pval' as text "   (simulated; the published table gives critical values only)"
    }

    local star = ""
    if (`s'>`cv10') local star "*"
    if (`s'>`cv05') local star "**"
    if (`s'>`cv01') local star "***"

    di ""
    di as text "{hline 79}"
    di as text "Interpretation"
    di as text "{hline 79}"
    if (`s'>`cv05') {
        di as text " H0 of a common break is " as result "REJECTED" as text " at 5% `star'"
        di as text " The break date is {bf:not} common across all series. But a rejection cannot"
        di as text " tell you {bf:which} of these it is:"
        di as text "   (a) each series (or group) has its own single break; or"
        di as text "   (b) there are several COMMON breaks along the time dimension."
        di as text " JK hit exactly this ambiguity in their own application (sec.6) and fell back"
        di as text " on the Bai-Perron sequential test. Consider:"
        di as text "   {stata xtbreak test `dv' `xv', hypothesis(3) sequential}"
        di as text " and re-running this test on sub-periods."
    }
    else {
        di as text " H0 of a common break is " as result "NOT rejected" as text " at 5%."
        di as text " {bf:This is not a certificate of a common break.} The test has documented low"
        di as text " power exactly where heterogeneity is mild but real (JK sec.5, Tables 6-7):"
        di as text "   . breaks only 0.1T apart      -> power 0.317 at 10%"
        di as text "   . one group with ~2 units     -> power 0.157 at 10%"
        di as text "   . breaks in opposite directions -> power collapses (c'delta = 0)"
    }
    di as text "{hline 79}"

    /* ---- the sign-concordance diagnostic (JK sec.5 opposite-direction warning) */
    di ""
    di as text "Diagnostics"
    di as text "{hline 79}"
    di as text %-44s "Sign concordance of estimated shifts delta_i" " " as result %8.3f `conc'
    if (`conc'<0.65) {
        di as text " {bf:warning}: the estimated shifts point in mixed directions."
        di as text " JK (sec.5, p.96): with delta ~ U(-0.5,0.5) the test loses power -- 'our test is"
        di as text " useful when changes in individual coefficients are in the similar direction'."
        di as text " A non-rejection here is weak evidence."
    }
    else {
        di as text " Shifts are mostly co-directional -- the configuration JK show the test handles well."
    }
    if (`t'<50) {
        di as text " {bf:warning}: T = " as result "`t'" as text " is small. JK Table 2: at T=20 with rho=0.4 the nominal-5%"
        di as text " test rejects 14.5-16.7% of the time. Size settles only near T=200."
    }
    if (`tnratio'<1) {
        di as text " {bf:warning}: T/N = " as result %4.2f `tnratio' as text " < 1. JK Assumption 2(iii) requires T/N -> infinity."
        di as text " The null distribution and the consistency proof both rely on it."
    }
    if (`usetable'==0) {
        di as text " note: critical values were simulated, not read from JK Table 1 (which is"
        di as text "       tabulated only at eps = 0.1 and tau0 in [0.20, 0.80])."
    }
    di as text "{hline 79}"
    di as text "Cross-sectional independence is assumed (JK Assumption 3(ii)); JK leave CSD to"
    di as text "future research. Check with {stata xtcd2 `dv'}."
    di as text "{hline 79}"
    di ""
end


/* ====================================================================== *
 *  GRAPHS : estimate
 * ====================================================================== */
program define xtcb_gest
    version 14.0
    /* NOTE: the matrix options must not share a prefix with the graph-name
       options.  PROFname(string) has minimum abbreviation `prof', so a
       prof(...) option would be swallowed by it and the required option
       would read as missing ("something required", r(100)).  Hence
       profmat()/shiftmat() plus all-lowercase (non-abbreviable) names. */
    syntax , profmat(name) brk(name) ci(name) shiftmat(name) chowmat(name) ///
             method(string) dv(string) level(real) nb(integer)              ///
             n(integer) t(integer) [ profname(string) shiftname(string) ]

    if ("`profname'"=="")  local profname  "xtcb_profile"
    if ("`shiftname'"=="") local shiftname "xtcb_shift"

    local yt "Pooled SSR"
    local sub "Least-squares objective  {&Sigma}{sub:i} S{sub:iT}(k)   (Bai eq. p.80)"
    if ("`method'"=="qml") {
        local yt "QML objective"
        local sub "QML objective  U{sub:NT}(k) = k{&Sigma}{sub:i}log{&sigma}{sup:2}{sub:i1} + (T-k){&Sigma}{sub:i}log{&sigma}{sup:2}{sub:i2}   (Bai eq.16)"
    }
    if ("`method'"=="gls") {
        local yt "FGLS objective"
        local sub "Feasible GLS objective  {&Sigma}{sub:i} S{sub:iT}(k)/{&sigma}{sup:2}{sub:i}   (Bai p.85)"
    }

    local bd = `brk'[1,1]
    local lo = `ci'[1,1]
    local hi = `ci'[1,2]

    preserve
        clear
        qui set obs `=rowsof(`profmat')'
        qui svmat double `profmat', name(_cbp)
        capture confirm variable _cbp1
        if (_rc==0) {
            label var _cbp2 "`yt'"
            label var _cbp1 "Candidate break date"
            qui su _cbp2, meanonly
            local ymin = r(min)
            local ymax = r(max)
            local ypad = (`ymax'-`ymin')*0.05
            twoway (rarea _cbp2 _cbp2 _cbp1 if inrange(_cbp1,`lo',`hi'),      ///
                        color(gs14) lwidth(none))                             ///
                   (line _cbp2 _cbp1, sort lwidth(medthick) lcolor(navy)),    ///
                   xline(`bd', lpattern(dash) lcolor(cranberry) lwidth(medthick)) ///
                   xline(`lo' `hi', lpattern(shortdash) lcolor(gs8) lwidth(thin))  ///
                   title("Common break identification", size(medium))         ///
                   subtitle("`sub'", size(vsmall))                            ///
                   ytitle("`yt'") xtitle("Candidate break date")              ///
                   yscale(range(`=`ymin'-`ypad'' `=`ymax'+`ypad''))           ///
                   note("Solid red line: estimated break. Dashed grey: `level'% CI (Bai eq.13)." ///
                        "Series: `dv'.  N = `n', T = `t'.", size(vsmall))     ///
                   legend(off)                                                ///
                   graphregion(color(white)) plotregion(color(white))         ///
                   name(`profname', replace)
        }
    restore

    /* ---- per-series shift with Chow significance ---------------------- */
    preserve
        clear
        qui set obs `=rowsof(`shiftmat')'
        qui svmat double `shiftmat', name(_cbs)
        qui svmat double `chowmat', name(_cbc)
        capture confirm variable _cbs1
        if (_rc==0) {
            rename _cbs1 sid
            rename _cbs2 dshift
            rename _cbc3 pchow
            gen byte sigbrk = (pchow<0.05) if pchow<.
            qui su dshift, meanonly
            label var dshift "{&mu}{sub:i2} - {&mu}{sub:i1}"
            sort dshift
            gen long rank = _n
            twoway (scatter dshift rank if sigbrk==1, mcolor(cranberry) msymbol(O) msize(small)) ///
                   (scatter dshift rank if sigbrk==0, mcolor(gs10) msymbol(Oh) msize(small)),    ///
                   yline(0, lcolor(black) lwidth(thin))                       ///
                   title("Estimated shift by series", size(medium))           ///
                   subtitle("magnitude of break {&mu}{sub:i2} - {&mu}{sub:i1} at the common break date", size(small)) ///
                   ytitle("Shift in mean") xtitle("Series (sorted by shift)") ///
                   legend(order(1 "Chow rejects at 5%" 2 "no detected break") ///
                          size(small) rows(1) region(lstyle(none)))           ///
                   note("Bai (2010, p.84): the Chow test at the estimated common break is valid" ///
                        "series by series with chi2 critical values, because khat is asymptotically" ///
                        "exogenous for any single series as N grows.", size(vsmall))  ///
                   graphregion(color(white)) plotregion(color(white))         ///
                   name(`shiftname', replace)
        }
    restore
end


/* ====================================================================== *
 *  GRAPHS : test
 * ====================================================================== */
program define xtcb_gtest
    version 14.0
    /* same prefix trap as xtcb_gest: CUSUMname abbreviates to `cusum'. */
    syntax , cusummat(name) deltas(name) vprof(name) khat(integer) dv(string) ///
             n(integer) t(integer) s(real) cv(real) level(real)               ///
             denom(real) [ cusumname(string) shiftname(string) ]

    if ("`cusumname'"=="") local cusumname "xtcb_cusum"
    if ("`shiftname'"=="") local shiftname "xtcb_dsign"

    /* the rejection threshold on the US scale: H0 is rejected when
       sup_k US > cv * inf V, so the comparable line is cv * denom. */
    local thr = `cv'*`denom'

    preserve
        clear
        qui set obs `=rowsof(`cusummat')'
        qui svmat double `cusummat', name(_cbu)
        capture confirm variable _cbu1
        if (_rc==0) {
            qui replace _cbu4 = `thr'
            label var _cbu3 "US{sub:NT}(k, k{c 94})"
            label var _cbu1 "k"
            twoway (line _cbu3 _cbu1, sort lwidth(medthick) lcolor(navy))    ///
                   (line _cbu4 _cbu1, sort lpattern(dash) lcolor(cranberry)), ///
                   xline(`khat', lpattern(solid) lcolor(gs8) lwidth(thin))   ///
                   title("Self-normalised CUSUM process", size(medium))      ///
                   subtitle("US{sub:NT}(k,k{c 94}) and the rejection threshold  (Jiang-Kurozumi eq.5)", size(small)) ///
                   ytitle("Squared CUSUM of residuals") xtitle("k")          ///
                   legend(order(1 "US{sub:NT}(k,k{c 94})" 2 "`level'% threshold {c 215} inf V{sub:NT}") ///
                          size(small) rows(1) region(lstyle(none)))          ///
                   note("Grey line: estimated common break k{c 94} = `khat'. S{sub:NT} = sup US / inf V = " ///
                        "`=string(`s',"%9.3f")'.  N = `n', T = `t'.  Series: `dv'.", size(vsmall)) ///
                   graphregion(color(white)) plotregion(color(white))        ///
                   name(`cusumname', replace)
        }
    restore

    preserve
        clear
        qui set obs `=rowsof(`deltas')'
        qui svmat double `deltas', name(_cbd)
        capture confirm variable _cbd1
        if (_rc==0) {
            rename _cbd1 sid
            rename _cbd2 d1
            sort d1
            gen long rank = _n
            gen byte pos = (d1>0)
            twoway (scatter d1 rank if pos==1, mcolor(navy) msymbol(O) msize(small))   ///
                   (scatter d1 rank if pos==0, mcolor(cranberry) msymbol(O) msize(small)), ///
                   yline(0, lcolor(black) lwidth(thin))                      ///
                   title("Direction of the estimated shifts", size(medium))  ///
                   subtitle("first slope shift {&delta}{sub:i} per series", size(small)) ///
                   ytitle("{&delta}{sub:i}") xtitle("Series (sorted)")       ///
                   legend(order(1 "positive" 2 "negative") size(small) rows(1) region(lstyle(none))) ///
                   note("Jiang-Kurozumi (sec.5): the test loses power when shifts run in opposite" ///
                        "directions (the c'{&delta} = 0 problem). A near 50/50 split weakens a non-rejection.", size(vsmall)) ///
                   graphregion(color(white)) plotregion(color(white))        ///
                   name(`shiftname', replace)
        }
    restore
end


/* ====================================================================== *
 *  MATA ENGINE
 *  NOTE: inside this block only // comments are legal (gotcha #19).
 * ====================================================================== */
version 14.0
mata:

// ---------------------------------------------------------------- //
// wide (T x N) layout of a panel-major stacked column vector
// ---------------------------------------------------------------- //
real matrix xtcb_wide(real colvector v, real scalar N)
{
    return(rowshape(v, N)')
}

// ---------------------------------------------------------------- //
// OLS residuals of y[a..b] on X[a..b,]
// ---------------------------------------------------------------- //
real colvector xtcb_resblk(real matrix X, real colvector y,
                           real scalar a, real scalar b)
{
    real matrix Xs
    real colvector ys, bt
    Xs = X[|a,1 \ b,.|]
    ys = y[|a \ b|]
    bt = invsym(quadcross(Xs,Xs)) * quadcross(Xs,ys)
    return(ys - Xs*bt)
}

// ---------------------------------------------------------------- //
// OLS SSR of y[a..b] on X[a..b,]
// ---------------------------------------------------------------- //
real scalar xtcb_ssrblk(real matrix X, real colvector y,
                        real scalar a, real scalar b)
{
    real colvector e
    e = xtcb_resblk(X, y, a, b)
    return(quadcross(e,e))
}

// ---------------------------------------------------------------- //
// OLS coefficients of y[a..b] on X[a..b,]
// ---------------------------------------------------------------- //
real colvector xtcb_bblk(real matrix X, real colvector y,
                         real scalar a, real scalar b)
{
    real matrix Xs
    real colvector ys
    Xs = X[|a,1 \ b,.|]
    ys = y[|a \ b|]
    return(invsym(quadcross(Xs,Xs)) * quadcross(Xs,ys))
}

// ---------------------------------------------------------------- //
// Per-panel design matrix (T x p) for panel i, gathered from the wide
// (T x N) regressors in L.  Returned by value so the caller can take
// the address of the RESULT -- see the note at the call site.
// x_it includes a constant as its first element (JK sec.2).
// ---------------------------------------------------------------- //
real matrix xtcb_gatherX(pointer(real matrix) rowvector L, real scalar i,
                         real scalar T, real scalar hascons)
{
    real matrix out
    real scalar k
    out = J(T, 0, .)
    if (hascons==1) {
        out = J(T, 1, 1)
    }
    for (k=1; k<=cols(L); k++) {
        out = (out, (*L[k])[,i])
    }
    return(out)
}


// ================================================================ //
//  BAI (2010)
// ================================================================ //
void xtcb_bai_run(string scalar nmProf, string scalar nmBrk,
                  string scalar nmCI,   string scalar nmShift,
                  string scalar nmChow, string scalar nmSig,
                  string scalar nmPars)
{
    real scalar N, T, nbrk, trim, lev, i, k, j, m, hmin
    real scalar khat, nties, best, val, totssr
    string scalar touse, method, anmeth, cimeth

    method = st_local("method")
    anmeth = st_local("anmethod")
    cimeth = st_local("cimethod")
    nbrk   = strtoreal(st_local("breaks"))
    trim   = strtoreal(st_local("trimming"))
    lev    = strtoreal(st_local("level"))
    touse  = st_local("touse")

    real colvector pv, y, tvfull
    pv = st_data(., st_local("ivar"), touse)
    y  = st_data(., st_local("dv"),   touse)
    tvfull = st_data(., st_local("tvar"), touse)

    real matrix info
    info = panelsetup(pv, 1)
    N = rows(info)
    T = info[1,2] - info[1,1] + 1

    real matrix Yw, tvw
    real colvector tvals, idv
    Yw    = xtcb_wide(y, N)
    tvw   = xtcb_wide(tvfull, N)
    tvals = tvw[,1]
    idv   = xtcb_wide(pv, N)[1,]'

    // ---- cumulative sums:  S[j+1] = sum_{t=1}^{j} Y_t ---------------- //
    real matrix S, Q
    S = J(T+1, N, 0)
    Q = J(T+1, N, 0)
    for (j=1; j<=T; j++) {
        S[j+1,] = S[j,] + Yw[j,]
        Q[j+1,] = Q[j,] + Yw[j,]:^2
    }

    // ---- minimum regime length -------------------------------------- //
    // Bai's LS estimator searches k in [1, T-1] with NO trimming: that is
    // the paper's headline (a regime may hold a single observation, sec.3).
    // QML/GLS need >=2 obs per regime: at k=1, s2_i1(1) = 0 exactly and
    // log(0) = -inf.  Bai sidesteps this by assuming k0 = [T*tau0] in sec.5.
    hmin = 1
    if (method=="qml" | method=="gls") {
        hmin = 2
    }
    if (trim>0) {
        m = floor(trim*T)
        if (m > hmin) {
            hmin = m
        }
    }
    if (hmin < 1) {
        hmin = 1
    }

    // ---- first-step LS (needed by gls, and for sigma2 anyway) -------- //
    real colvector lsprof
    real scalar s1, s2, sa, sb
    lsprof = J(T, 1, .)
    for (k=hmin; k<=T-hmin; k++) {
        totssr = 0
        for (i=1; i<=N; i++) {
            sa = S[k+1,i] - S[1,i]
            sb = S[T+1,i] - S[k+1,i]
            s1 = (Q[k+1,i] - Q[1,i])   - sa*sa/k
            s2 = (Q[T+1,i] - Q[k+1,i]) - sb*sb/(T-k)
            totssr = totssr + s1 + s2
        }
        lsprof[k] = totssr
    }

    real scalar khls
    khls  = .
    best  = .
    for (k=hmin; k<=T-hmin; k++) {
        if (lsprof[k]<.) {
            if (best==. | lsprof[k]<best) {
                best = lsprof[k]
                khls = k
            }
        }
    }

    // ---- per-series sigma2 at khls:  s2_i = S_iT(khat)/(T-2) --------- //
    // Bai p.85, the first step of the feasible GLS.
    real colvector sig2i
    sig2i = J(N, 1, .)
    for (i=1; i<=N; i++) {
        sa = S[khls+1,i] - S[1,i]
        sb = S[T+1,i] - S[khls+1,i]
        s1 = (Q[khls+1,i] - Q[1,i])   - sa*sa/khls
        s2 = (Q[T+1,i] - Q[khls+1,i]) - sb*sb/(T-khls)
        sig2i[i] = (s1+s2)/(T-2)
    }

    // ---- the objective actually used -------------------------------- //
    real colvector prof
    real scalar v1, v2, ok
    prof = J(T, 1, .)
    for (k=hmin; k<=T-hmin; k++) {
        if (method=="ls") {
            prof[k] = lsprof[k]
        }
        if (method=="gls") {
            totssr = 0
            for (i=1; i<=N; i++) {
                sa = S[k+1,i] - S[1,i]
                sb = S[T+1,i] - S[k+1,i]
                s1 = (Q[k+1,i] - Q[1,i])   - sa*sa/k
                s2 = (Q[T+1,i] - Q[k+1,i]) - sb*sb/(T-k)
                if (sig2i[i]>0) {
                    totssr = totssr + (s1+s2)/sig2i[i]
                }
            }
            prof[k] = totssr
        }
        if (method=="qml") {
            totssr = 0
            ok = 1
            for (i=1; i<=N; i++) {
                sa = S[k+1,i] - S[1,i]
                sb = S[T+1,i] - S[k+1,i]
                v1 = ((Q[k+1,i] - Q[1,i])   - sa*sa/k)/k
                v2 = ((Q[T+1,i] - Q[k+1,i]) - sb*sb/(T-k))/(T-k)
                if (v1<=0 | v2<=0) {
                    ok = 0
                }
                if (ok==1) {
                    totssr = totssr + k*log(v1) + (T-k)*log(v2)
                }
            }
            if (ok==1) {
                prof[k] = totssr
            }
        }
    }

    khat  = .
    best  = .
    nties = 0
    for (k=hmin; k<=T-hmin; k++) {
        if (prof[k]<.) {
            if (best==. | prof[k]<best) {
                best  = prof[k]
                khat  = k
                nties = 1
            }
            else {
                if (prof[k]==best) {
                    nties = nties + 1
                }
            }
        }
    }
    if (khat==.) {
        errprintf("no feasible break point; reduce trimming() or check T\n")
        exit(198)
    }

    // ---- multiple breaks: one-at-a-time (Bai sec.6 / Bai 1997a) ------ //
    real rowvector bp
    real scalar r, na, nb2, redu, bestred, bestk, a, b, kk
    real rowvector segs
    bp = (khat)
    if (nbrk>1) {
        for (m=2; m<=nbrk; m++) {
            bestred = .
            bestk   = .
            segs    = (0, sort(bp',1)', T)
            for (r=1; r<=cols(segs)-1; r++) {
                a = segs[r] + 1
                b = segs[r+1]
                for (kk=a+hmin-1; kk<=b-hmin; kk++) {
                    na = kk - a + 1
                    nb2 = b - kk
                    if (na>=hmin & nb2>=hmin) {
                        redu = 0
                        for (i=1; i<=N; i++) {
                            sa = S[b+1,i] - S[a,i]
                            s1 = (Q[b+1,i] - Q[a,i]) - sa*sa/(b-a+1)
                            sa = S[kk+1,i] - S[a,i]
                            sb = S[b+1,i] - S[kk+1,i]
                            v1 = (Q[kk+1,i] - Q[a,i])  - sa*sa/na
                            v2 = (Q[b+1,i]  - Q[kk+1,i]) - sb*sb/nb2
                            redu = redu + s1 - v1 - v2
                        }
                        if (bestred==. | redu>bestred) {
                            bestred = redu
                            bestk   = kk
                        }
                    }
                }
            }
            if (bestk<.) {
                bp = (bp, bestk)
            }
        }
        bp = sort(bp', 1)'
    }

    // ---- per-series means, shifts, variances at khat ----------------- //
    real colvector mu1, mu2, dsh, s2i1, s2i2, s2iw
    mu1  = J(N,1,.)
    mu2  = J(N,1,.)
    dsh  = J(N,1,.)
    s2i1 = J(N,1,.)
    s2i2 = J(N,1,.)
    s2iw = J(N,1,.)
    for (i=1; i<=N; i++) {
        sa = S[khat+1,i] - S[1,i]
        sb = S[T+1,i] - S[khat+1,i]
        mu1[i] = sa/khat
        mu2[i] = sb/(T-khat)
        dsh[i] = mu2[i] - mu1[i]
        s2i1[i] = ((Q[khat+1,i] - Q[1,i])   - sa*sa/khat)/khat
        s2i2[i] = ((Q[T+1,i] - Q[khat+1,i]) - sb*sb/(T-khat))/(T-khat)
        s2iw[i] = (khat*s2i1[i] + (T-khat)*s2i2[i])/T
    }

    // ---- sigma2_i for A_N / B_N:  S_iT(khat)/(T-2)  (Bai p.85) ------- //
    real colvector s2use
    s2use = J(N,1,.)
    for (i=1; i<=N; i++) {
        sa = S[khat+1,i] - S[1,i]
        sb = S[T+1,i] - S[khat+1,i]
        s1 = (Q[khat+1,i] - Q[1,i])   - sa*sa/khat
        s2 = (Q[T+1,i] - Q[khat+1,i]) - sb*sb/(T-khat)
        s2use[i] = (s1+s2)/(T-2)
    }

    // ---- A_N  (Bai p.83) -------------------------------------------- //
    // general:      A_N = [sum_i d_i^2]^2 / [sum_i d_i^2 sigma_i^2]
    // homoskedastic (Bai's own Monte Carlo, p.83):
    //               A_N = sum_i d_i^2 / sigma^2,  sigma^2 = sum_i sum_t e^2/(NT-2N)
    // The two coincide when sigma_i^2 is constant -- verified in the help.
    real scalar AN, num1, den1, spool, sse
    num1 = 0
    den1 = 0
    for (i=1; i<=N; i++) {
        num1 = num1 + dsh[i]^2
        den1 = den1 + dsh[i]^2 * s2use[i]
    }
    AN = .
    if (den1>0) {
        AN = num1*num1/den1
    }
    if (anmeth=="hom") {
        sse = 0
        for (i=1; i<=N; i++) {
            sa = S[khat+1,i] - S[1,i]
            sb = S[T+1,i] - S[khat+1,i]
            s1 = (Q[khat+1,i] - Q[1,i])   - sa*sa/khat
            s2 = (Q[T+1,i] - Q[khat+1,i]) - sb*sb/(T-khat)
            sse = sse + s1 + s2
        }
        spool = sse/(N*T - 2*N)
        if (spool>0) {
            AN = num1/spool
        }
    }

    // ---- B_N  (Bai p.85):  sum_i d_i^2 / sigma_i^2 ------------------ //
    real scalar BN
    BN = 0
    for (i=1; i<=N; i++) {
        if (s2use[i]>0) {
            BN = BN + dsh[i]^2 / s2use[i]
        }
    }

    // ---- QML master scale (Bai eq.19) ------------------------------- //
    // (tau + omega/2)^2 / [tau + (2+kappa)*omega/4 + mu3*pi]
    //   tau   = sum_i (mu_i1-mu_i2)^2 / sigma_i^2
    //   omega = 2 * sum_i f(s2_i1/s2_i2),  f(x) = x - 1 - log(x)
    //   kappa = 4th cumulant of eta,  mu3 = E(eta^3)
    //   pi    = sum_i [(mu_i1-mu_i2)/sigma_i]*[(s2_i1-s2_i2)/sigma_i^2]
    // Nests Cor.5.3 (omega=0 -> tau) and Cor.5.4 (tau=0 -> omega/(2+kappa)).
    real scalar tauP, omeP, kapP, mu3P, piP, rat, fx, sc
    tauP = 0
    omeP = 0
    piP  = 0
    for (i=1; i<=N; i++) {
        if (s2iw[i]>0) {
            tauP = tauP + (mu1[i]-mu2[i])^2 / s2iw[i]
            piP  = piP + ((mu1[i]-mu2[i])/sqrt(s2iw[i])) * ((s2i1[i]-s2i2[i])/s2iw[i])
        }
        if (s2i1[i]>0 & s2i2[i]>0) {
            rat = s2i1[i]/s2i2[i]
            fx  = rat - 1 - log(rat)
            omeP = omeP + fx
        }
    }
    omeP = 2*omeP

    // standardised residuals -> kappa, mu3
    real scalar n3, n4, ntot, z
    n3 = 0
    n4 = 0
    ntot = 0
    for (i=1; i<=N; i++) {
        for (j=1; j<=T; j++) {
            z = .
            if (j<=khat) {
                if (s2i1[i]>0) {
                    z = (Yw[j,i]-mu1[i])/sqrt(s2i1[i])
                }
            }
            else {
                if (s2i2[i]>0) {
                    z = (Yw[j,i]-mu2[i])/sqrt(s2i2[i])
                }
            }
            if (z<.) {
                n3 = n3 + z^3
                n4 = n4 + z^4
                ntot = ntot + 1
            }
        }
    }
    mu3P = .
    kapP = .
    if (ntot>0) {
        mu3P = n3/ntot
        kapP = n4/ntot - 3
    }

    sc = AN
    if (method=="qml" | method=="gls") {
        sc = .
        den1 = tauP + (2+kapP)*omeP/4 + mu3P*piP
        if (den1>0) {
            sc = (tauP + omeP/2)^2 / den1
        }
        if (sc>=. | sc<=0) {
            sc = BN
        }
    }

    // ---- CI (Bai eq.13) --------------------------------------------- //
    // Bai's eq.(13) PRINTS  [khat - floor(c/A), khat + ceil(c/A)].
    // Taken literally that gives an EVEN length whenever c/A is not an
    // integer (floor = ceil-1 => length = 2*ceil), and a minimum length of
    // TWO, {khat, khat+1}.  Both contradict the paper itself:
    //   (i)  his prose on p.84 -- "the shortest confidence interval (by
    //        construction) would contain three integers (khat-1, khat,
    //        khat+1)" -- which only the symmetric ceiling form delivers;
    //   (ii) his Table 1 median lengths (9,5,5,3 / 13,7,7,5 / 23,13,9,7),
    //        which are ODD, as only 2*ceil+1 can be.
    // So the implemented form is the symmetric one, which reproduces his
    // published table; cimethod(literal) gives eq.(13) exactly as printed.
    real scalar cst, lo, hi, rad
    cst = 7
    if (lev==95) {
        cst = 11
    }
    if (lev==99) {
        cst = 20
    }
    lo = .
    hi = .
    if (sc<. & sc>0) {
        if (cimeth=="literal") {
            lo = khat - floor(cst/sc)
            hi = khat + ceil(cst/sc)
        }
        else {
            rad = ceil(cst/sc)
            lo = khat - rad
            hi = khat + rad
        }
        if (lo<1) {
            lo = 1
        }
        if (hi>T) {
            hi = T
        }
    }

    // ---- per-series Chow at khat (Bai p.84) ------------------------- //
    real matrix Chow
    real scalar cs, pvv
    Chow = J(N, 4, .)
    for (i=1; i<=N; i++) {
        Chow[i,1] = idv[i]
        cs = .
        pvv = .
        if (s2use[i]>0) {
            cs  = dsh[i]^2 / (s2use[i]*(1/khat + 1/(T-khat)))
            pvv = 1 - chi2(1, cs)
        }
        Chow[i,2] = cs
        Chow[i,3] = pvv
        Chow[i,4] = s2use[i]
    }

    // ---- outputs ---------------------------------------------------- //
    real matrix Prof, Brk, CI, Shift, Sig
    Prof = J(0,2,.)
    for (k=hmin; k<=T-hmin; k++) {
        if (prof[k]<.) {
            Prof = (Prof \ (tvals[k], prof[k]))
        }
    }

    // 2 x nbrk:  row 1 = calendar dates, row 2 = indices 1..T
    Brk = J(2, cols(bp), .)
    for (j=1; j<=cols(bp); j++) {
        Brk[1,j] = tvals[bp[j]]
        Brk[2,j] = bp[j]
    }

    CI = J(1,4,.)
    if (lo<.) {
        CI[1,1] = tvals[lo]
        CI[1,3] = lo
    }
    if (hi<.) {
        CI[1,2] = tvals[hi]
        CI[1,4] = hi
    }

    Shift = (idv, dsh, mu1, mu2)
    Sig   = (idv, s2use, s2i1, s2i2)

    real matrix Pars
    Pars = J(1,8,.)
    Pars[1,1] = AN
    Pars[1,2] = BN
    Pars[1,3] = tauP
    Pars[1,4] = omeP
    Pars[1,5] = kapP
    Pars[1,6] = mu3P
    Pars[1,7] = sc
    Pars[1,8] = piP

    st_matrix(nmProf,  Prof)
    st_matrix(nmBrk,   Brk)
    st_matrix(nmCI,    CI)
    st_matrix(nmShift, Shift)
    st_matrix(nmChow,  Chow)
    st_matrix(nmSig,   Sig)
    st_matrix(nmPars,  Pars)

    st_local("r_N",     strofreal(N))
    st_local("r_T",     strofreal(T))
    st_local("r_khat",  strofreal(khat))
    st_local("r_nbrk",  strofreal(cols(bp)))
    st_local("r_nties", strofreal(nties))
    st_local("r_AN",    strofreal(AN))
    st_local("r_BN",    strofreal(BN))
    st_local("r_tau",   strofreal(tauP))
    st_local("r_omega", strofreal(omeP))
    st_local("r_kappa", strofreal(kapP))
    st_local("r_mu3",   strofreal(mu3P))
    st_local("r_pi",    strofreal(piP))
    st_local("r_scale", strofreal(sc))
    st_local("r_ssr",   strofreal(best))
}


// ================================================================ //
//  JIANG & KUROZUMI (2026)
// ================================================================ //
void xtcb_jk_run(string scalar nmCusum, string scalar nmBrk,
                 string scalar nmDelta, string scalar nmVprof)
{
    real scalar N, T, p, hascons, trim, i, k, j, m, khat, best, tot
    string scalar touse

    trim    = strtoreal(st_local("trimming"))
    hascons = strtoreal(st_local("hascons"))
    touse   = st_local("touse")

    real colvector pv, y, tvfull
    real matrix Xall
    pv = st_data(., st_local("ivar"), touse)
    y  = st_data(., st_local("dv"),   touse)
    tvfull = st_data(., st_local("tvar"), touse)
    Xall = st_data(., st_local("xv"), touse)

    real matrix info
    info = panelsetup(pv, 1)
    N = rows(info)
    T = info[1,2] - info[1,1] + 1

    real matrix Yw, tvw
    real colvector tvals, idv
    Yw    = xtcb_wide(y, N)
    tvw   = xtcb_wide(tvfull, N)
    tvals = tvw[,1]
    idv   = xtcb_wide(pv, N)[1,]'

    // per-panel regressor matrices (T x p); x_it includes a constant
    // as its first element (JK sec.2: "the first element is unity for all t")
    real scalar pin
    pin = cols(Xall)
    p   = pin + hascons

    // Wide (T x N) form of each regressor, computed ONCE.
    pointer(real matrix) rowvector Xw
    Xw = J(1, pin, NULL)
    for (k=1; k<=pin; k++) {
        Xw[k] = &(xtcb_wide(Xall[,k], N))
    }

    // Per-panel design (T x p).  The address MUST be taken of a function
    // RESULT, not of a named local: &Xi inside a loop would alias one
    // variable, so every pointer would end up seeing the LAST panel.
    pointer(real matrix) rowvector Xp
    Xp = J(1, N, NULL)
    for (i=1; i<=N; i++) {
        Xp[i] = &(xtcb_gatherX(Xw, i, T, hascons))
    }

    // ---- trimming bound m in JK eq.(3) ------------------------------- //
    // JK write khat = argmin_{m<=k<=T-m} without giving m numerically.
    // m must be 2*[T*eps], NOT [T*eps].  Lambda(eps) needs
    //     [T*eps] <= k1 <= khat-[T*eps]   ->  khat >= 2*[T*eps]
    //     khat+[T*eps] <= k2 <= [T(1-eps)] ->  khat <= T-2*[T*eps]
    // so the admissible set is EMPTY unless khat lies in [2*[T*eps],
    // T-2*[T*eps]], i.e. tau0 in [2*eps, 1-2*eps] = [0.2, 0.8] at eps=0.1 --
    // exactly the range JK tabulate, and exactly what they state: "the
    // possible break fractions tau0 are from 0.2 to 0.8 when eps = 0.1"
    // (below their Table 1).  m = 2*[T*eps] is the only reading that makes
    // eq.(3), Lambda(eps) and Table 1's range mutually consistent.
    m = 2*floor(trim*T)
    if (m < p) {
        m = p
    }
    if (m < 1) {
        m = 1
    }
    if (2*m >= T) {
        errprintf("trimming() too large for T = %f with p = %f regressors\n", T, p)
        exit(198)
    }

    // ---- J1: khat = argmin_{m<=k<=T-m} sum_i SSR_i(k)  (JK eq.3) ----- //
    // EQ-C: [X_i, Z_i(k)] spans the two regime blocks, so SSR_i(k) is the
    // sum of the two per-block OLS SSRs -- numerically identical, far cheaper.
    real colvector kprof
    kprof = J(T, 1, .)
    for (k=m; k<=T-m; k++) {
        tot = 0
        for (i=1; i<=N; i++) {
            tot = tot + xtcb_ssrblk(*Xp[i], Yw[,i], 1, k)
            tot = tot + xtcb_ssrblk(*Xp[i], Yw[,i], k+1, T)
        }
        kprof[k] = tot
    }
    khat = .
    best = .
    for (k=m; k<=T-m; k++) {
        if (kprof[k]<.) {
            if (best==. | kprof[k]<best) {
                best = kprof[k]
                khat = k
            }
        }
    }
    if (khat==.) {
        errprintf("no feasible break point\n")
        exit(198)
    }

    // ---- J3: uhat at khat (JK eq.4) --------------------------------- //
    real matrix Uh
    Uh = J(T, N, .)
    for (i=1; i<=N; i++) {
        Uh[|1,i \ khat,i|]   = xtcb_resblk(*Xp[i], Yw[,i], 1, khat)
        Uh[|khat+1,i \ T,i|] = xtcb_resblk(*Xp[i], Yw[,i], khat+1, T)
    }

    // ---- J4: US_NT(k,khat) (JK eq.5) -------------------------------- //
    // sum over i is INSIDE the square -> collapse panels to g_t first
    real colvector g, cg, US
    g = rowsum(Uh)
    cg = J(T, 1, 0)
    cg[1] = g[1]
    for (j=2; j<=T; j++) {
        cg[j] = cg[j-1] + g[j]
    }
    US = J(T, 1, .)
    for (k=1; k<=T; k++) {
        US[k] = (cg[k]/sqrt(N*T))^2
    }

    // ---- numerator: sup over k in [T*eps, T*(1-eps)] (EQ-A) ---------- //
    real scalar klo, khi, numer
    klo = floor(trim*T)
    khi = floor((1-trim)*T)
    if (klo<1) {
        klo = 1
    }
    if (khi>T) {
        khi = T
    }
    numer = .
    for (k=klo; k<=khi; k++) {
        if (numer==. | US[k]>numer) {
            numer = US[k]
        }
    }

    // ---- denominator: EQ-B, V(k1,khat,k2) = A(k1) + B(k2) ------------ //
    // A(k1) uses only the fit on [1,k1] and [k1+1,khat];
    // B(k2) uses only the fit on [khat+1,k2] and [k2+1,T].
    real scalar k1lo, k1hi, k2lo, k2hi, k1, k2, t1, t2, t3, t4, ss, Amin, Bmin
    real matrix Ut
    real colvector gt, ct

    k1lo = floor(trim*T)
    k1hi = khat - floor(trim*T)
    k2lo = khat + floor(trim*T)
    k2hi = floor((1-trim)*T)

    if (k1lo < p) {
        k1lo = p
    }
    if (k2hi > T-p) {
        k2hi = T-p
    }

    real matrix Aprof, Bprof
    Aprof = J(0,2,.)
    Bprof = J(0,2,.)
    Amin = .
    Bmin = .

    for (k1=k1lo; k1<=k1hi; k1++) {
        if (k1>=p & khat-k1>=p) {
            Ut = J(khat, N, .)
            for (i=1; i<=N; i++) {
                Ut[|1,i \ k1,i|]      = xtcb_resblk(*Xp[i], Yw[,i], 1, k1)
                Ut[|k1+1,i \ khat,i|] = xtcb_resblk(*Xp[i], Yw[,i], k1+1, khat)
            }
            gt = rowsum(Ut)
            // term 1: FORWARD partial sums, s = 1..k1
            ct = J(khat, 1, 0)
            ct[1] = gt[1]
            for (j=2; j<=khat; j++) {
                ct[j] = ct[j-1] + gt[j]
            }
            t1 = 0
            for (j=1; j<=k1; j++) {
                ss = ct[j]/sqrt(N*T)
                t1 = t1 + ss*ss
            }
            t1 = t1/T
            // term 2: BACKWARD partial sums, s = k1+1..khat, inner t = s..khat
            t2 = 0
            for (j=k1+1; j<=khat; j++) {
                ss = (ct[khat] - ct[j-1])/sqrt(N*T)
                t2 = t2 + ss*ss
            }
            t2 = t2/T
            Aprof = (Aprof \ (k1, t1+t2))
            if (Amin==. | t1+t2<Amin) {
                Amin = t1+t2
            }
        }
    }

    for (k2=k2lo; k2<=k2hi; k2++) {
        if (k2-khat>=p & T-k2>=p) {
            Ut = J(T, N, .)
            for (i=1; i<=N; i++) {
                Ut[|khat+1,i \ k2,i|] = xtcb_resblk(*Xp[i], Yw[,i], khat+1, k2)
                Ut[|k2+1,i \ T,i|]    = xtcb_resblk(*Xp[i], Yw[,i], k2+1, T)
            }
            gt = J(T,1,0)
            for (j=khat+1; j<=T; j++) {
                gt[j] = sum(Ut[j,])
            }
            ct = J(T, 1, 0)
            for (j=khat+1; j<=T; j++) {
                ct[j] = ct[j-1] + gt[j]
            }
            // term 3: FORWARD sums from khat+1, s = khat+1..k2
            t3 = 0
            for (j=khat+1; j<=k2; j++) {
                ss = ct[j]/sqrt(N*T)
                t3 = t3 + ss*ss
            }
            t3 = t3/T
            // term 4: BACKWARD sums, s = k2+1..T, inner t = s..T
            t4 = 0
            for (j=k2+1; j<=T; j++) {
                ss = (ct[T] - ct[j-1])/sqrt(N*T)
                t4 = t4 + ss*ss
            }
            t4 = t4/T
            Bprof = (Bprof \ (k2, t3+t4))
            if (Bmin==. | t3+t4<Bmin) {
                Bmin = t3+t4
            }
        }
    }

    real scalar denom, Sstat
    denom = .
    Sstat = .
    if (Amin<. & Bmin<.) {
        denom = Amin + Bmin
        if (denom>0) {
            Sstat = numer/denom
        }
    }
    if (Sstat>=.) {
        // Should be unreachable: m = max(2*[T*eps], p) guarantees khat lies in
        // [2*[T*eps], T-2*[T*eps]], hence Lambda(eps) is non-empty.  Kept as a
        // safety net for degenerate data (e.g. collinear regressors in a block).
        errprintf("{err}the normalising process V_NT could not be computed at khat = %f.\n", khat)
        errprintf("{err}Lambda(eps) appears empty or a regime block is rank-deficient.\n")
        errprintf("{err}Try a smaller trimming() or check for collinear regressors.\n")
        exit(198)
    }

    // ---- per-series shift direction (JK sec.5 power caveat) ---------- //
    real matrix Del
    real colvector b1, b2
    real scalar npos, nneg, cc
    Del = J(N, 2, .)
    npos = 0
    nneg = 0
    for (i=1; i<=N; i++) {
        b1 = xtcb_bblk(*Xp[i], Yw[,i], 1, khat)
        b2 = xtcb_bblk(*Xp[i], Yw[,i], khat+1, T)
        Del[i,1] = idv[i]
        // the first SLOPE shift (skip the constant when present)
        j = 1
        if (hascons==1) {
            j = 2
        }
        if (rows(b1)>=j) {
            Del[i,2] = b2[j] - b1[j]
            if (Del[i,2]>0) {
                npos = npos + 1
            }
            if (Del[i,2]<=0) {
                nneg = nneg + 1
            }
        }
    }
    cc = .
    if (npos+nneg>0) {
        cc = max((npos, nneg))/(npos+nneg)
    }

    // ---- cusum matrix for the plot ---------------------------------- //
    real matrix Cus
    Cus = J(T, 4, .)
    for (k=1; k<=T; k++) {
        Cus[k,1] = k
        Cus[k,2] = tvals[k]
        Cus[k,3] = US[k]
        Cus[k,4] = .
    }
    // threshold curve = cv * denom is filled by the ado (needs the cv)

    // 2 x 1, same layout as the estimate subcommand: date / index
    real matrix Brk
    Brk = J(2,1,.)
    Brk[1,1] = tvals[khat]
    Brk[2,1] = khat

    st_matrix(nmCusum, Cus)
    st_matrix(nmBrk,   Brk)
    st_matrix(nmDelta, Del)
    st_matrix(nmVprof, (Aprof \ Bprof))

    st_local("r_N",    strofreal(N))
    st_local("r_T",    strofreal(T))
    st_local("r_khat", strofreal(khat))
    st_local("r_S",    strofreal(Sstat))
    st_local("r_tau0", strofreal(khat/T))
    st_local("r_num",  strofreal(numer))
    st_local("r_den",  strofreal(denom))
    st_local("r_conc", strofreal(cc))
}


// ================================================================ //
//  JK Table 1 critical values  (eps = 0.1, tau0 in [0.20, 0.80])
//  NOTE: the published table prints 5.162 at tau0 = 0.39 for the 10%
//  level.  Every neighbour is ~45.2 (0.38 -> 45.423, 0.40 -> 45.413):
//  the leading 4 was dropped in typesetting.  Stored here as 45.162.
// ================================================================ //
real matrix xtcb_cvmat()
{
    real matrix C
    C = J(61, 4, .)
    C[ 1,] = (0.20, 44.683, 58.000, 93.334)
    C[ 2,] = (0.21, 45.718, 59.858, 94.657)
    C[ 3,] = (0.22, 46.276, 59.513, 94.293)
    C[ 4,] = (0.23, 46.059, 59.685, 95.175)
    C[ 5,] = (0.24, 46.529, 60.253, 94.964)
    C[ 6,] = (0.25, 46.179, 59.375, 96.660)
    C[ 7,] = (0.26, 46.013, 59.314, 94.966)
    C[ 8,] = (0.27, 46.166, 59.984, 96.143)
    C[ 9,] = (0.28, 46.320, 59.641, 96.147)
    C[10,] = (0.29, 46.126, 59.472, 92.999)
    C[11,] = (0.30, 45.457, 57.897, 93.472)
    C[12,] = (0.31, 45.402, 57.797, 91.919)
    C[13,] = (0.32, 45.552, 57.722, 91.743)
    C[14,] = (0.33, 45.358, 58.284, 93.649)
    C[15,] = (0.34, 45.222, 58.992, 93.089)
    C[16,] = (0.35, 45.398, 59.376, 92.584)
    C[17,] = (0.36, 45.316, 58.525, 90.879)
    C[18,] = (0.37, 45.556, 58.329, 91.502)
    C[19,] = (0.38, 45.423, 57.710, 89.287)
    C[20,] = (0.39, 45.162, 58.428, 90.632)
    C[21,] = (0.40, 45.413, 57.989, 90.335)
    C[22,] = (0.41, 45.549, 58.119, 91.709)
    C[23,] = (0.42, 45.987, 57.619, 92.507)
    C[24,] = (0.43, 46.039, 58.082, 91.103)
    C[25,] = (0.44, 45.992, 57.755, 88.373)
    C[26,] = (0.45, 45.935, 58.262, 87.018)
    C[27,] = (0.46, 46.114, 58.039, 87.676)
    C[28,] = (0.47, 45.760, 57.398, 87.558)
    C[29,] = (0.48, 45.865, 56.650, 86.703)
    C[30,] = (0.49, 45.844, 57.083, 84.092)
    C[31,] = (0.50, 45.476, 57.809, 85.984)
    C[32,] = (0.51, 45.756, 57.819, 85.933)
    C[33,] = (0.52, 45.432, 57.391, 85.602)
    C[34,] = (0.53, 45.081, 56.906, 86.526)
    C[35,] = (0.54, 45.042, 56.957, 85.382)
    C[36,] = (0.55, 45.066, 56.481, 86.857)
    C[37,] = (0.56, 45.136, 57.023, 86.867)
    C[38,] = (0.57, 45.337, 57.199, 85.988)
    C[39,] = (0.58, 45.016, 57.061, 86.211)
    C[40,] = (0.59, 45.228, 56.656, 89.053)
    C[41,] = (0.60, 45.172, 57.241, 90.397)
    C[42,] = (0.61, 45.322, 56.988, 89.481)
    C[43,] = (0.62, 45.854, 57.699, 89.855)
    C[44,] = (0.63, 46.077, 58.336, 91.704)
    C[45,] = (0.64, 45.595, 58.398, 93.175)
    C[46,] = (0.65, 45.604, 58.478, 91.605)
    C[47,] = (0.66, 45.689, 59.002, 91.513)
    C[48,] = (0.67, 46.013, 57.876, 93.687)
    C[49,] = (0.68, 46.095, 58.768, 92.220)
    C[50,] = (0.69, 46.293, 59.020, 95.095)
    C[51,] = (0.70, 46.487, 59.175, 93.728)
    C[52,] = (0.71, 46.404, 58.840, 92.819)
    C[53,] = (0.72, 46.593, 59.804, 94.161)
    C[54,] = (0.73, 47.027, 59.090, 93.900)
    C[55,] = (0.74, 46.444, 59.781, 93.374)
    C[56,] = (0.75, 46.328, 59.942, 92.876)
    C[57,] = (0.76, 46.287, 60.022, 92.439)
    C[58,] = (0.77, 46.943, 60.321, 94.096)
    C[59,] = (0.78, 46.115, 60.078, 95.111)
    C[60,] = (0.79, 46.091, 60.739, 96.691)
    C[61,] = (0.80, 45.160, 59.248, 94.886)
    return(C)
}

void xtcb_cvtable(string scalar nm, real scalar tau0)
{
    real matrix C, out
    real scalar i, bd, bi, d
    C = xtcb_cvmat()
    bd = .
    bi = 1
    for (i=1; i<=rows(C); i++) {
        d = abs(C[i,1]-tau0)
        if (bd==. | d<bd) {
            bd = d
            bi = i
        }
    }
    if (tau0<0.195 | tau0>0.805) {
        errprintf("{err}tau0-hat = %5.3f is outside the tabulated range [0.20, 0.80]\n", tau0)
        errprintf("{err}JK Table 1 cannot be used. Re-run with the {bf:simulate} option.\n")
        exit(198)
    }
    out = J(1,4,.)
    out[1,1] = C[bi,2]
    out[1,2] = C[bi,3]
    out[1,3] = C[bi,4]
    out[1,4] = .
    st_matrix(nm, out)
}


// ================================================================ //
//  Simulate the JK Theorem 1 limiting distribution
//  Same three reductions as the sample statistic:
//    sup over tau of the numerator, inf over tau1 and tau2 separately,
//    denominator separable into a tau1 part and a tau2 part.
//  Integrals are evaluated in closed form from cumulative sums of
//  W, r*W and W^2 -> O(M) per replication instead of O(M^2).
// ================================================================ //
void xtcb_simcv(string scalar nm, real scalar tau0, real scalar eps,
                real scalar reps, real scalar M, real scalar Sobs)
{
    real scalar h, r, j, j0, j1, j2, jlo, jhi, j1lo, j1hi, j2lo, j2hi
    real scalar W0, W1v, Wt, a, b, d, c, num, best, Amin, Bmin
    real scalar I1, I2, I3, I4, sg2, srg, tt, val, nge
    real colvector W, SW, SrW, SW2, rr, out

    h  = 1/M
    j0 = round(tau0*M)
    if (j0<2) {
        j0 = 2
    }
    if (j0>M-2) {
        j0 = M-2
    }

    rr = (1::M) :* h

    jlo  = ceil(eps*M)
    jhi  = floor((1-eps)*M)
    j1lo = ceil(eps*M)
    j1hi = j0 - ceil(eps*M)
    j2lo = j0 + ceil(eps*M)
    j2hi = floor((1-eps)*M)

    if (jlo<1) {
        jlo = 1
    }
    if (j1lo<1) {
        j1lo = 1
    }
    if (j1hi<j1lo | j2hi<j2lo) {
        errprintf("trimming() leaves no admissible (tau1, tau2); reduce it\n")
        exit(198)
    }

    out = J(reps, 1, .)
    nge = 0

    for (r=1; r<=reps; r++) {
        // Brownian motion on the grid: W(j/M) = sum of iid N(0,1/M)
        W = runningsum(rnormal(M,1,0,1) :* sqrt(h))
        W0  = W[j0]
        W1v = W[M]

        // cumulative sums for the closed-form integrals
        SW  = runningsum(W :* h)
        SrW = runningsum(rr :* W :* h)
        SW2 = runningsum((W:^2) :* h)

        // ---- numerator: sup over tau in [eps, 1-eps] ---------------- //
        // W(t) - t*W(t0)/t0 - (t-t0)*[(W(1)-W(t0))/(1-t0) - W(t0)/t0]*1{t>t0}
        num = .
        c = (W1v - W0)/(1-tau0) - W0/tau0
        for (j=jlo; j<=jhi; j++) {
            tt = rr[j]
            val = W[j] - tt*W0/tau0
            if (tt>tau0) {
                val = val - (tt-tau0)*c
            }
            val = val*val
            if (num==. | val>num) {
                num = val
            }
        }

        // ---- A(tau1) = I1 + I2 ------------------------------------- //
        Amin = .
        for (j1=j1lo; j1<=j1hi; j1++) {
            a  = rr[j1]
            Wt = W[j1]
            // I1 = int_0^a [W(r) - (r/a)W(a)]^2 dr
            //    = SW2(a) - 2*(W(a)/a)*SrW(a) + (W(a)/a)^2 * a^3/3
            I1 = SW2[j1] - 2*(Wt/a)*SrW[j1] + (Wt/a)^2 * a^3/3
            // I2 = int_a^t0 [W(t0)-W(r) - (t0-r)*c]^2 dr,  c = (W(t0)-W(a))/(t0-a)
            d   = tau0 - a
            sg2 = W0*W0*d - 2*W0*(SW[j0]-SW[j1]) + (SW2[j0]-SW2[j1])
            srg = W0*d*d/2 - (tau0*(SW[j0]-SW[j1]) - (SrW[j0]-SrW[j1]))
            c   = (W0 - Wt)/d
            I2  = sg2 - 2*c*srg + c*c*d^3/3
            val = I1 + I2
            if (Amin==. | val<Amin) {
                Amin = val
            }
        }

        // ---- B(tau2) = I3 + I4 ------------------------------------- //
        Bmin = .
        for (j2=j2lo; j2<=j2hi; j2++) {
            b  = rr[j2]
            Wt = W[j2]
            // I3 = int_t0^b [W(r)-W(t0) - (r-t0)*c]^2 dr, c = (W(b)-W(t0))/(b-t0)
            d   = b - tau0
            sg2 = (SW2[j2]-SW2[j0]) - 2*W0*(SW[j2]-SW[j0]) + W0*W0*d
            srg = ((SrW[j2]-SrW[j0]) - tau0*(SW[j2]-SW[j0])) - W0*d*d/2
            c   = (Wt - W0)/d
            I3  = sg2 - 2*c*srg + c*c*d^3/3
            // I4 = int_b^1 [W(1)-W(r) - (1-r)*c]^2 dr, c = (W(1)-W(b))/(1-b)
            d   = 1 - b
            sg2 = W1v*W1v*d - 2*W1v*(SW[M]-SW[j2]) + (SW2[M]-SW2[j2])
            srg = W1v*d*d/2 - ((SW[M]-SW[j2]) - (SrW[M]-SrW[j2]))
            c   = (W1v - Wt)/d
            I4  = sg2 - 2*c*srg + c*c*d^3/3
            val = I3 + I4
            if (Bmin==. | val<Bmin) {
                Bmin = val
            }
        }

        if (Amin<. & Bmin<. & Amin+Bmin>0) {
            out[r] = num/(Amin+Bmin)
        }
    }

    // ---- critical values and the p-value ------------------------- //
    real colvector oc
    real scalar n, pv
    oc = select(out, out:<.)
    n  = rows(oc)
    if (n<10) {
        errprintf("simulation failed to produce enough draws\n")
        exit(198)
    }
    oc = sort(oc, 1)

    real matrix res
    res = J(1,4,.)
    res[1,1] = oc[ceil(0.90*n)]
    res[1,2] = oc[ceil(0.95*n)]
    res[1,3] = oc[ceil(0.99*n)]

    nge = 0
    for (j=1; j<=n; j++) {
        if (oc[j] >= Sobs) {
            nge = nge + 1
        }
    }
    pv = nge/n
    res[1,4] = pv

    st_matrix(nm, res)
}

end
