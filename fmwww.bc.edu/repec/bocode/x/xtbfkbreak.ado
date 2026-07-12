*! xtbfkbreak version 1.0.0  11jul2026
*! Structural breaks in heterogeneous panels with common correlated effects,
*!   optionally with endogenous regressors (instrumental-variable slopes).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*!
*! Implements, faithfully to the two papers:
*!   Baltagi, Feng & Kao (2016) "Estimation of Heterogeneous Panels with
*!     Structural Breaks", Journal of Econometrics 191, 176-195.
*!     <doi:10.1016/j.jeconom.2015.03.048>   -- CCE + common break, exogenous.
*!   Baltagi, Feng & Kao (2019) "Structural Changes in Heterogeneous Panels
*!     with Endogenous Regressors", CPR Working Paper 214, Syracuse Univ.
*!     -- adds a second endogeneity channel Cov(eps,v)!=0 handled by IV,
*!        and robustness to a break in the error-factor loadings.
*!
*! Estimation logic (see help file for the equation-by-equation mapping):
*!   Step 1  CCE transformation.  Partial out the unobserved factors f_t with
*!           the cross-section averages of y, x (and z) -- the annihilator
*!           M_w (BFK16 eq.20; BFK19 eq.19).  With no factors use nocce.
*!   Step 2  Break dates.  Least-squares (OLS) search minimising the pooled
*!           SSR over the transformed data (BFK16 eq.24; BFK19 eq.21).  OLS is
*!           consistent even under endogeneity (Perron & Yamamoto 2015), so the
*!           search stays OLS unless ivbreak is requested.
*!   Step 3  Slopes.  Regime-by-regime CCE (BFK16) or CCE-IV / 2SLS (BFK19,
*!           eq.23-24) given the estimated break dates; mean-group aggregation
*!           with Pesaran's (2006) MG variance.

program define xtbfkbreak, eclass sortpreserve
    version 14.0

    if replay() {
        if ("`e(cmd)'" != "xtbfkbreak") error 301
        Display `0'
        exit
    }

    syntax anything(equalok) [if] [in] [ , ///
        BReaks(integer 1)                  ///
        TRim(real 0.15)                    ///
        NOCce                              ///
        CSA(varlist numeric)               ///
        LAGs(integer 0)                    ///
        IVBreak                            ///
        NOCONStant                         ///
        Level(cilevel)                     ///
        GRAPH                              ///
        SSRname(string)                    ///
        COEFname(string) ]

    /* ------------------------------------------------------------------ *
     * 1. Parse   depvar [exog indepvars]  [(endog = instruments)]
     * ------------------------------------------------------------------ */
    local cmdline `anything'
    local endo ""
    local iv   ""
    if (strpos("`cmdline'","(")) {
        local ppos = strpos("`cmdline'","(")
        local pre  = substr("`cmdline'",1,`ppos'-1)
        local rest = substr("`cmdline'",`ppos'+1,.)
        local cpos = strpos("`rest'",")")
        if (`cpos'==0) {
            di as error "unbalanced parentheses in the (endogenous = instruments) list"
            exit 198
        }
        local inside = substr("`rest'",1,`cpos'-1)
        if (!strpos("`inside'","=")) {
            di as error "the parenthetical list must be of the form (endog = instruments)"
            exit 198
        }
        local epos = strpos("`inside'","=")
        local endo = trim(substr("`inside'",1,`epos'-1))
        local iv   = trim(substr("`inside'",`epos'+1,.))
    }
    else {
        local pre `cmdline'
    }

    gettoken depvar exog : pre
    local depvar = trim("`depvar'")
    local exog   = trim("`exog'")

    if ("`depvar'"=="") {
        di as error "no dependent variable specified"
        exit 198
    }

    /* validate / expand the four varlists (continuous numeric only) */
    confirm numeric variable `depvar'
    if ("`exog'"!="") {
        unab exog : `exog'
        confirm numeric variable `exog'
    }
    if ("`endo'"!="") {
        unab endo : `endo'
        confirm numeric variable `endo'
    }
    if ("`iv'"!="") {
        unab iv : `iv'
        confirm numeric variable `iv'
    }

    /* order of the full regressor set = exog then endo */
    local rlist `exog' `endo'
    local p : word count `rlist'
    if (`p'==0) {
        di as error "at least one regressor (exogenous or endogenous) is required"
        exit 198
    }
    local pen : word count `endo'
    local q   : word count `iv'
    if (`pen'>0 & `q'<`pen') {
        di as error "the model is under-identified: `q' instrument(s) for `pen' endogenous regressor(s)"
        exit 198
    }
    if (`pen'==0 & "`iv'"!="") {
        di as error "instruments supplied but no endogenous regressor listed inside ( = )"
        exit 198
    }

    /* ------------------------------------------------------------------ */
    if (`breaks'<1) {
        di as error "breaks() must be a positive integer"
        exit 198
    }
    if (`trim'<=0 | `trim'>=0.5) {
        di as error "trim() must lie strictly between 0 and 0.5"
        exit 198
    }
    if (`lags'<0) {
        di as error "lags() must be non-negative"
        exit 198
    }

    local docce = 1
    if ("`nocce'"!="") local docce = 0
    local hascons = 1
    if ("`noconstant'"!="") local hascons = 0
    local ivbr = 0
    if ("`ivbreak'"!="") local ivbr = 1
    if (`ivbr'==1 & `pen'==0) {
        di as error "ivbreak requires an endogenous regressor and instruments"
        exit 198
    }

    /* ------------------------------------------------------------------ *
     * 2. Panel bookkeeping
     * ------------------------------------------------------------------ */
    qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`ivar'"=="" | "`tvar'"=="") {
        di as error "data must be {help xtset}-declared as a panel (panel and time)"
        exit 459
    }

    marksample touse, novarlist
    markout `touse' `depvar' `rlist' `iv' `csa'
    markout `touse' `ivar' `tvar'

    /* balanced-panel check on the estimation sample */
    tempvar tcount
    qui bysort `touse' `ivar' (`tvar'): gen long `tcount' = _N if `touse'
    qui su `tcount' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    if (`Tmin'!=`Tmax') {
        di as error "xtbfkbreak requires a balanced panel on the estimation sample"
        di as error "  (min T = `Tmin', max T = `Tmax'); consider filling gaps or trimming the sample"
        exit 459
    }

    qui count if `touse'
    if (r(N)==0) {
        di as error "no observations"
        exit 2000
    }

    /* keep the data sorted panel-major, time ascending (engine relies on it) */
    sort `ivar' `tvar'

    /* ------------------------------------------------------------------ *
     * 3. Call the Mata engine
     * ------------------------------------------------------------------ */
    tempname bMG V bi brk prof
    local exogn `exog'
    local endon `endo'

    mata: xtbfk_run("`bMG'","`V'","`bi'","`brk'","`prof'")

    /* scalars the engine hands back via st_local */
    local N     = `r_N'
    local Tobs  = `r_T'
    local Teff  = `r_Teff'
    local Rreg  = `r_R'
    local kcoef = `r_kcoef'
    local nbrk  = `r_nbrk'
    local totssr = `r_ssr'

    /* ------------------------------------------------------------------ *
     * 4. Coefficient names (equation = regime)
     * ------------------------------------------------------------------ */
    local cn ""
    local ceq ""
    forval r = 1/`Rreg' {
        if (`hascons') {
            local cn  "`cn' _cons"
            local ceq "`ceq' Regime`r'"
        }
        foreach v of local rlist {
            local cn  "`cn' `v'"
            local ceq "`ceq' Regime`r'"
        }
    }
    matrix colnames `bMG' = `cn'
    matrix coleq    `bMG' = `ceq'
    matrix colnames `V'   = `cn'
    matrix rownames `V'   = `cn'
    matrix coleq    `V'   = `ceq'
    matrix roweq    `V'   = `ceq'

    /* break-date list (calendar time values) */
    local brklist ""
    forval j = 1/`nbrk' {
        local bd = `brk'[1,`j']
        local brklist "`brklist' `bd'"
    }
    local brklist = trim("`brklist'")

    /* ------------------------------------------------------------------ *
     * 5. Graphs (do BEFORE the ereturn matrix moves, using tempname mats)
     * ------------------------------------------------------------------ */
    if ("`graph'"!="") {
        MakeGraphs, prof(`prof') bmg(`bMG') vmat(`V') brk(`brk') ///
            nbrk(`nbrk') rreg(`Rreg') p(`p') hascons(`hascons')  ///
            level(`level') rlist(`rlist') depvar(`depvar')       ///
            ssrname(`ssrname') coefname(`coefname')
    }

    /* ------------------------------------------------------------------ *
     * 6. Post results
     * ------------------------------------------------------------------ */
    ereturn post `bMG' `V', esample(`touse') depname(`depvar')

    ereturn scalar N       = `N'
    ereturn scalar N_g     = `N'
    ereturn scalar T       = `Tobs'
    ereturn scalar T_eff   = `Teff'
    ereturn scalar g_min   = `Tobs'
    ereturn scalar g_max   = `Tobs'
    ereturn scalar k_breaks = `nbrk'
    ereturn scalar N_regime = `Rreg'
    ereturn scalar trim    = `trim'
    ereturn scalar lags    = `lags'
    ereturn scalar ssr     = `totssr'
    ereturn scalar df_m    = `kcoef'-1

    ereturn local breaks    "`brklist'"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`exog'"
    ereturn local endog     "`endo'"
    ereturn local insts     "`iv'"
    ereturn local csa       "`csa'"
    ereturn local panelvar  "`ivar'"
    ereturn local timevar   "`tvar'"
    if ("`docce'"=="1")  ereturn local transform "CCE (factors partialled out)"
    else                 ereturn local transform "none (no common factors)"
    if (`pen'>0)         ereturn local estimator "CCE-MG-IV (2SLS regimes)"
    else                 ereturn local estimator "CCE-MG (OLS regimes)"
    if (`ivbr'==1)       ereturn local breaksrch "IV"
    else                 ereturn local breaksrch "OLS"
    ereturn local cmdline "xtbfkbreak `0'"
    ereturn local cmd     "xtbfkbreak"
    ereturn local title   "Heterogeneous panel with structural breaks (Baltagi-Feng-Kao)"

    ereturn matrix bi     = `bi'
    ereturn matrix breakdates = `brk'
    ereturn matrix ssrprofile = `prof'

    /* ------------------------------------------------------------------ */
    Display, level(`level')
end

/* ====================================================================== *
 *  DISPLAY
 * ====================================================================== */
program define Display
    version 14.0
    syntax [, Level(cilevel) ]
    if ("`level'"=="") local level = c(level)

    local Rreg   = e(N_regime)
    local nbrk   = e(k_breaks)
    local rlist  `e(indepvars)' `e(endog)'
    local p      : word count `rlist'
    local hascons = 0
    local kcoef = colsof(e(b))
    if (`kcoef' == `Rreg'*(`p'+1)) local hascons = 1
    local bs = `hascons' + `p'

    di ""
    di as text "{hline 78}"
    di as text "Heterogeneous panel with common structural breaks   " _c
    di as text %25s "(Baltagi-Feng-Kao)"
    di as text "{hline 78}"
    di as text "Estimator      : " as result "`e(estimator)'"
    di as text "Factor control : " as result "`e(transform)'"
    di as text "Break search   : " as result "`e(breaksrch)'" as text " (Perron-Yamamoto 2015: OLS consistent under endogeneity)"
    di as text "Panel variable : " as result "`e(panelvar)'" _col(40) as text "N (groups)   = " as result %9.0g e(N)
    di as text "Time variable  : " as result "`e(timevar)'"  _col(40) as text "T (periods)  = " as result %9.0g e(T)
    di as text "Trimming       : " as result %5.2f e(trim)   _col(40) as text "T effective  = " as result %9.0g e(T_eff)
    di as text "No. of breaks  : " as result %5.0f e(k_breaks) _col(40) as text "No. regimes  = " as result %9.0g e(N_regime)
    di as text "Break date(s)  : " as result "`e(breaks)'" as text "   (last period of each pre-break regime)"
    di as text "{hline 78}"

    /* ---- Regime-specific mean-group slopes ---- */
    local z = invnormal(1-(100-`level')/200)
    di ""
    di as text "Mean-group regime slopes" _col(40) "[`level'% conf. interval]"
    di as text "{hline 78}"
    di as text %-20s "Regressor" " " %10s "Coef." " " %9s "Std.err." " " %8s "z" " " %7s "P>|z|" "  " %8s "Lower" " " %8s "Upper"
    di as text "{hline 78}"

    tempname b V
    matrix `b' = e(b)
    matrix `V' = e(V)

    forval r = 1/`Rreg' {
        di as text "Regime `r':"
        local j = 0
        foreach v of local rlist {
            local j = `j' + 1
            local idx = (`r'-1)*`bs' + `hascons' + `j'
            local co = `b'[1,`idx']
            local se = sqrt(`V'[`idx',`idx'])
            local zz = `co'/`se'
            local pv = 2*normal(-abs(`zz'))
            local lo = `co' - `z'*`se'
            local hi = `co' + `z'*`se'
            local st = ""
            if (`pv'<0.10) local st "*"
            if (`pv'<0.05) local st "**"
            if (`pv'<0.01) local st "***"
            di as text %-20s "`v'" " " as result %10.4f `co' " " %9.4f `se' " " %8.2f `zz' " " %7.3f `pv' "  " %8.4f `lo' " " %8.4f `hi' as text " `st'"
        }
        if (`hascons') {
            local idx = (`r'-1)*`bs' + 1
            local co = `b'[1,`idx']
            local se = sqrt(`V'[`idx',`idx'])
            local zz = `co'/`se'
            local pv = 2*normal(-abs(`zz'))
            local lo = `co' - `z'*`se'
            local hi = `co' + `z'*`se'
            di as text %-20s "_cons" " " as result %10.4f `co' " " %9.4f `se' " " %8.2f `zz' " " %7.3f `pv' "  " %8.4f `lo' " " %8.4f `hi'
        }
    }
    di as text "{hline 78}"

    /* ---- Structural-change contrasts:  delta = Regime(r) - Regime(r-1) ---- */
    if (`Rreg'>=2) {
        di ""
        di as text "Structural change in slopes:  {&delta} = Regime(r) - Regime(r-1)"
        di as text "{hline 78}"
        di as text %-16s "Change" " " %-12s "Regressor" " " %10s "{&delta}" " " %9s "Std.err." " " %8s "z" " " %7s "P>|z|"
        di as text "{hline 78}"
        forval r = 2/`Rreg' {
            local rm1 = `r' - 1
            di as text "Regime `r' vs `rm1':"
            local j = 0
            foreach v of local rlist {
                local j = `j' + 1
                local i2 = (`r'-1)*`bs' + `hascons' + `j'
                local i1 = (`rm1'-1)*`bs' + `hascons' + `j'
                local dl = `b'[1,`i2'] - `b'[1,`i1']
                local vv = `V'[`i2',`i2'] + `V'[`i1',`i1'] - 2*`V'[`i2',`i1']
                if (`vv'<=0) local vv = 0
                local se = sqrt(`vv')
                local zz = .
                local pv = .
                if (`se'>0) {
                    local zz = `dl'/`se'
                    local pv = 2*normal(-abs(`zz'))
                }
                local st = ""
                if (`pv'<0.10) local st "*"
                if (`pv'<0.05) local st "**"
                if (`pv'<0.01) local st "***"
                di as text _col(18) %-12s "`v'" " " as result %10.4f `dl' " " %9.4f `se' " " %8.2f `zz' " " %7.3f `pv' as text " `st'"
            }
        }
        di as text "{hline 78}"
    }
    di as text "Significance: * p<.10, ** p<.05, *** p<.01." _col(50) "MG variance: Pesaran (2006)."
    di as text "Std. errors are non-parametric mean-group standard errors across the `=e(N)' panels."
    di ""
end

/* ====================================================================== *
 *  GRAPHS
 * ====================================================================== */
program define MakeGraphs
    version 14.0
    syntax , prof(name) bmg(name) vmat(name) brk(name) nbrk(integer) ///
             rreg(integer) p(integer) hascons(integer) level(cilevel) ///
             rlist(string) depvar(string) [ ssrname(string) coefname(string) ]

    if ("`ssrname'"=="")  local ssrname  "xtbfk_ssr"
    if ("`coefname'"=="") local coefname "xtbfk_coef"
    local z = invnormal(1-(100-`level')/200)

    /* ---- (a) concentrated-SSR break identification plot ---- */
    local xl ""
    forval j = 1/`nbrk' {
        local bd = `brk'[1,`j']
        local xl "`xl' xline(`bd', lpattern(dash) lcolor(cranberry))"
    }
    preserve
        clear
        qui set obs `=rowsof(`prof')'
        qui svmat double `prof', name(_bfkp)
        capture confirm variable _bfkp1
        if (_rc==0) {
            label var _bfkp2 "Pooled SSR  {&Sigma}{sub:i} SSR{sub:i}(k)"
            label var _bfkp1 "Candidate break date"
            twoway line _bfkp2 _bfkp1, sort lwidth(medthick) lcolor(navy)   ///
                `xl'                                                        ///
                title("Break-point identification", size(medium))          ///
                subtitle("Concentrated pooled sum of squared residuals", size(small)) ///
                ytitle("Pooled SSR") xtitle("Candidate break date")        ///
                note("Minimising break date(s) shown by dashed line(s). Model: `depvar'.", size(vsmall)) ///
                graphregion(color(white)) plotregion(color(white))         ///
                name(`ssrname', replace)
        }
    restore

    /* ---- (b) regime coefficient path with CIs ---- */
    tempname pf
    tempfile pfd
    postfile `pf' int regime double coef double lo double hi int vid using "`pfd'", replace
    local bs = `hascons' + `p'
    forval r = 1/`rreg' {
        local j = 0
        foreach v of local rlist {
            local j = `j' + 1
            local idx = (`r'-1)*`bs' + `hascons' + `j'
            local co = `bmg'[1,`idx']
            local se = sqrt(`vmat'[`idx',`idx'])
            post `pf' (`r') (`co') (`co'-`z'*`se') (`co'+`z'*`se') (`j')
        }
    }
    postclose `pf'

    preserve
        use "`pfd'", clear
        local vlab ""
        local j = 0
        foreach v of local rlist {
            local j = `j' + 1
            local vlab `"`vlab' `j' "`v'""'
        }
        label define _vid `vlab', replace
        label values vid _vid
        twoway (rcap hi lo regime, lcolor(navy))                           ///
               (scatter coef regime, mcolor(cranberry) msymbol(D)),        ///
               by(vid, title("Mean-group slope by regime", size(medium))   ///
                   subtitle("point estimate and `level'% CI", size(small))  ///
                   note("Regime = interval between estimated break dates.", size(vsmall)) ///
                   graphregion(color(white)) legend(off))                  ///
               ytitle("Coefficient") xtitle("Regime")                      ///
               xlabel(1(1)`rreg') xscale(range(0.5 `=`rreg'+0.5'))          ///
               name(`coefname', replace)
    restore
end

/* ====================================================================== *
 *  MATA ENGINE
 * ====================================================================== */
version 14.0
mata:
mata set matastrict off

// ---- wide (T x N) layout of a stacked panel-major column vector ----
real matrix xtbfk_wide(real colvector v, real scalar N)
{
    return(rowshape(v, N)')
}

// ---- cross-section average (T x cols) of a stacked matrix ----
real matrix xtbfk_csa(real matrix M, real scalar N)
{
    real matrix out, w
    real scalar j
    out = J(rows(M)/N, cols(M), .)
    for (j=1; j<=cols(M); j++) {
        w = xtbfk_wide(M[,j], N)
        out[,j] = rowsum(w) :/ N
    }
    return(out)
}

// ---- regime id (T x 1), 1..R, from sorted break positions bp ----
real colvector xtbfk_regid(real rowvector bp, real scalar Teff)
{
    real colvector idx, id
    real scalar j
    idx = (1::Teff)
    id  = J(Teff, 1, 1)
    if (cols(bp)>0) {
        for (j=1; j<=cols(bp); j++) {
            id = id + (idx :> bp[j])
        }
    }
    return(id)
}

// ---- feasibility: every regime at least h periods long ----
real scalar xtbfk_feasible(real rowvector bp, real scalar Teff, real scalar h)
{
    real rowvector b
    real scalar j, ok, len
    b  = (0, bp, Teff)
    ok = 1
    for (j=1; j<=cols(b)-1; j++) {
        len = b[j+1] - b[j]
        if (len < h) {
            ok = 0
        }
    }
    return(ok)
}

// ---- regime-block design: [ cvec , X*1{reg1}, ..., X*1{regR} ] ----
// cvec is the (already M_w-transformed) intercept column, Teff x 1, or
// Teff x 0 when noconstant.  Transforming the constant makes the CCE slopes
// numerically identical to partialling out [1, ybar, xbar] (Pesaran 2006).
real matrix xtbfk_design(real matrix Xi, real colvector id, real scalar R, real matrix cvec)
{
    real matrix D, blk
    real scalar r
    D = cvec
    for (r=1; r<=R; r++) {
        blk = Xi :* (id :== r)
        D   = (D, blk)
    }
    return(D)
}

// ---- RAW regime-block design with regime-specific intercept ----
// Per regime r: [ 1{reg r} (raw indicator, if hascons) , X * 1{reg r} ].
// This is applied to RAW regressors and then premultiplied by M_w outside,
// reproducing BFK's M_w*(x*1{t>k}) (transform-after-split, eq.20-23) and
// giving each regime its own intercept (pure structural change, Bai-Perron).
real matrix xtbfk_rdesign(real matrix Xi, real colvector id, real scalar R, real scalar hascons)
{
    real matrix D, ind, blk
    real scalar r
    D = J(rows(Xi), 0, .)
    for (r=1; r<=R; r++) {
        ind = (id :== r)
        if (hascons==1) {
            D = (D, ind)
        }
        blk = Xi :* ind
        D = (D, blk)
    }
    return(D)
}

// ---- IV/OLS coefficient vector (2SLS; reduces to OLS when H==W) ----
real colvector xtbfk_fit(real colvector Y, real matrix W, real matrix H)
{
    real matrix HHi, WH, A
    real colvector c, b
    HHi = invsym(quadcross(H,H))
    WH  = quadcross(W,H)
    A   = WH * HHi * WH'
    c   = WH * HHi * quadcross(H,Y)
    b   = invsym(A) * c
    return(b)
}

// ---- pooled SSR for a given break configuration ----
// Ywt is the M_w-transformed dependent variable (Teff x N).  Xraw/Zraw are the
// RAW per-panel regressors / instruments; the regime-block design is built raw
// and premultiplied by M_w (transform-after-split, BFK eq.20-23).
real scalar xtbfk_ssr(real rowvector bp, real scalar Teff, real scalar N,
    real matrix Ywt, pointer(real matrix) rowvector Xraw,
    pointer(real matrix) rowvector Zraw, real matrix Mw,
    real scalar hascons, real scalar pex, real scalar useIV)
{
    real colvector id, Yi, b, e
    real matrix Xr, Draw, Di, HDi, Xexr, Hset, Hraw
    real scalar R, i, tot, ss
    id  = xtbfk_regid(bp, Teff)
    R   = cols(bp) + 1
    tot = 0
    for (i=1; i<=N; i++) {
        Yi   = Ywt[,i]
        Xr   = *Xraw[i]
        Draw = xtbfk_rdesign(Xr, id, R, hascons)
        Di   = Mw * Draw
        HDi  = Di
        if (useIV==1) {
            Xexr = J(Teff, 0, .)
            if (pex>0) {
                Xexr = Xr[|1,1 \ Teff,pex|]
            }
            Hset = (Xexr, *Zraw[i])
            Hraw = xtbfk_rdesign(Hset, id, R, hascons)
            HDi  = Mw * Hraw
        }
        b  = xtbfk_fit(Yi, Di, HDi)
        e  = Yi - Di*b
        ss = quadcross(e,e)
        tot = tot + ss
    }
    return(tot)
}

// ---- horizontal gather of column i across a list of (T x N) wides ----
real matrix xtbfk_gather(pointer(real matrix) rowvector L, real scalar i, real scalar Teff)
{
    real matrix out
    real scalar k
    out = J(Teff, 0, .)
    for (k=1; k<=cols(L); k++) {
        out = (out, (*L[k])[,i])
    }
    return(out)
}

// ====================================================================== //
void xtbfk_run(string scalar nmB, string scalar nmV, string scalar nmBi,
               string scalar nmBrk, string scalar nmProf)
{
    real scalar N, Tfull, Teff, docce, nlags, nbrk, hascons, ivbr
    real scalar pex, pen, p, q, trim, i, k, m, j
    real scalar useIVsrch, useIVfin, R, h
    string scalar touse

    docce   = strtoreal(st_local("docce"))
    nlags   = strtoreal(st_local("lags"))
    nbrk    = strtoreal(st_local("breaks"))
    hascons = strtoreal(st_local("hascons"))
    ivbr    = strtoreal(st_local("ivbr"))
    trim    = strtoreal(st_local("trim"))
    touse   = st_local("touse")

    // ---- read data (panel-major, time ascending) ----
    real colvector pv, y
    real matrix Xex, Xen, Ziv, Xcs
    pv = st_data(., st_local("ivar"), touse)
    y  = st_data(., st_local("depvar"), touse)

    Xex = J(rows(y),0,.)
    Xen = J(rows(y),0,.)
    Ziv = J(rows(y),0,.)
    Xcs = J(rows(y),0,.)
    if (st_local("exogn")!="") {
        Xex = st_data(., st_local("exogn"), touse)
    }
    if (st_local("endon")!="") {
        Xen = st_data(., st_local("endon"), touse)
    }
    if (st_local("iv")!="") {
        Ziv = st_data(., st_local("iv"), touse)
    }
    if (st_local("csa")!="") {
        Xcs = st_data(., st_local("csa"), touse)
    }

    pex = cols(Xex)
    pen = cols(Xen)
    p   = pex + pen
    q   = cols(Ziv)

    // ---- N, T from the panel id ----
    real matrix info
    info = panelsetup(pv, 1)
    N    = rows(info)
    Tfull = info[1,2] - info[1,1] + 1

    // time labels (identical across balanced panels)
    real colvector tvfull, tvals
    real matrix tvw
    tvfull = st_data(., st_local("tvar"), touse)
    tvw    = xtbfk_wide(tvfull, N)
    tvals  = tvw[,1]

    // ---- wide layout ----
    real matrix Yw
    Yw = xtbfk_wide(y, N)
    pointer(real matrix) rowvector Xw, Zw
    Xw = J(1, p, NULL)
    for (k=1; k<=pex; k++) {
        Xw[k] = &(xtbfk_wide(Xex[,k], N))
    }
    for (k=1; k<=pen; k++) {
        Xw[pex+k] = &(xtbfk_wide(Xen[,k], N))
    }
    Zw = J(1, q, NULL)
    for (k=1; k<=q; k++) {
        Zw[k] = &(xtbfk_wide(Ziv[,k], N))
    }

    // ---- cross-section-average design (for the CCE annihilator) ----
    real matrix Wc
    Wc = xtbfk_csa(y, N)
    if (pex>0) {
        Wc = (Wc, xtbfk_csa(Xex, N))
    }
    if (pen>0) {
        Wc = (Wc, xtbfk_csa(Xen, N))
    }
    if (q>0) {
        Wc = (Wc, xtbfk_csa(Ziv, N))
    }
    if (cols(Xcs)>0) {
        Wc = (Wc, xtbfk_csa(Xcs, N))
    }

    // ---- lags: restrict to t = nlags+1..Tfull, augment CSA with its lags ----
    real matrix Wce
    real colvector keep
    Teff = Tfull - nlags
    keep = (nlags+1 :: Tfull)
    Wce  = Wc
    if (nlags>0) {
        Wce = Wc[keep,]
        for (m=1; m<=nlags; m++) {
            Wce = (Wce, Wc[(keep :- m),])
        }
        Yw    = Yw[keep,]
        tvals = tvals[keep]
        for (k=1; k<=p; k++) {
            Xw[k] = &((*Xw[k])[keep,])
        }
        for (k=1; k<=q; k++) {
            Zw[k] = &((*Zw[k])[keep,])
        }
    }

    // ---- CCE annihilator M_w ----
    // Pesaran's (2006) CCE augmentation includes a CONSTANT alongside the
    // cross-section averages.  Under a slope break this lets W span the enlarged
    // factor space {1, f, f*1{t>k}} (Breitung-Eickmeier 2011; BFK 2019 fn.4), so
    // BOTH the factor and its regime-split copy are wiped out.  Omitting the
    // constant leaves the regime-split factor in the errors and biases the CCE
    // slopes -- while the break date stays consistent.
    if (docce==1 & hascons==1) {
        Wce = (J(Teff,1,1), Wce)
    }
    real matrix Mw
    Mw = I(Teff)
    if (docce==1) {
        Mw = Mw - Wce * invsym(quadcross(Wce,Wce)) * Wce'
    }

    // ---- RAW per-panel regressors / instruments.  Only Y is transformed;
    //      the regime-block design is built raw and premultiplied by M_w in
    //      the search and final estimation (transform-after-split). ----
    pointer(real matrix) rowvector Xraw, Zraw
    Xraw = J(1, N, NULL)
    Zraw = J(1, N, NULL)
    for (i=1; i<=N; i++) {
        Xraw[i] = &(xtbfk_gather(Xw, i, Teff))
        Zraw[i] = &(xtbfk_gather(Zw, i, Teff))
    }
    Yw = Mw * Yw

    useIVsrch = 0
    if (ivbr==1) {
        useIVsrch = 1
    }
    useIVfin = 0
    if (pen>0) {
        useIVfin = 1
    }

    // minimum regime length
    h = floor(trim*Teff)
    if (h < p + hascons + 1) {
        h = p + hascons + 1
    }
    if (h < 2) {
        h = 2
    }

    // ---- forward search for break dates (one at a time; Bai 2010) ----
    real rowvector bp, cand
    real scalar bestSSR, bestk, already, feas, s
    real matrix prof
    bp   = J(1, 0, .)
    prof = J(0, 2, .)
    for (m=1; m<=nbrk; m++) {
        bestSSR = .
        bestk   = .
        for (k=1; k<=Teff-1; k++) {
            already = 0
            if (cols(bp)>0) {
                already = sum(bp :== k)
            }
            if (already==0) {
                cand = sort((bp, k)', 1)'
                feas = xtbfk_feasible(cand, Teff, h)
                if (feas==1) {
                    s = xtbfk_ssr(cand, Teff, N, Yw, Xraw, Zraw, Mw, hascons, pex, useIVsrch)
                    if (m==1) {
                        prof = (prof \ (tvals[k], s))
                    }
                    if (bestSSR==. | s<bestSSR) {
                        bestSSR = s
                        bestk   = k
                    }
                }
            }
        }
        if (bestk==.) {
            errprintf("no feasible break point; reduce trim() or breaks()\n")
            exit(198)
        }
        bp = sort((bp, bestk)', 1)'
    }

    // ---- final regime slopes given the estimated breaks -------------------
    // Faithful BFK (eq.20-23): build the RAW regime-block design (with a
    // regime-specific intercept), THEN premultiply by M_w -- i.e. M_w acts on
    // x*1{t in regime}, not on x first.  Slopes are exogenous-OLS (2016) or
    // per-regime 2SLS (2019).  Coefficient block per regime = [cons?, slopes].
    real colvector idf, Yi, bvec, e
    real matrix Bmat, Draw, Dfi, Hraw, HDfi, Xr, Xexr, Hset
    real scalar kcoef, totssr, ss, bs
    R    = cols(bp) + 1
    idf  = xtbfk_regid(bp, Teff)
    bs   = hascons + p
    kcoef = R*bs
    Bmat = J(N, kcoef, .)
    totssr = 0
    for (i=1; i<=N; i++) {
        Yi   = Yw[,i]
        Xr   = *Xraw[i]
        Draw = xtbfk_rdesign(Xr, idf, R, hascons)
        Dfi  = Mw * Draw
        HDfi = Dfi
        if (useIVfin==1) {
            Xexr = J(Teff, 0, .)
            if (pex>0) {
                Xexr = Xr[|1,1 \ Teff,pex|]
            }
            Hset = (Xexr, *Zraw[i])
            Hraw = xtbfk_rdesign(Hset, idf, R, hascons)
            HDfi = Mw * Hraw
        }
        bvec = xtbfk_fit(Yi, Dfi, HDfi)
        Bmat[i,] = bvec'
        e  = Yi - Dfi*bvec
        ss = quadcross(e,e)
        totssr = totssr + ss
    }

    // ---- mean-group estimator + Pesaran (2006) MG variance ----
    real rowvector bMG
    real matrix dev, V
    bMG = mean(Bmat)
    dev = Bmat :- bMG
    V   = quadcross(dev, dev) :/ ((N-1)*N)

    // ---- break dates in calendar time ----
    real rowvector bdt
    bdt = J(1, cols(bp), .)
    for (j=1; j<=cols(bp); j++) {
        bdt[j] = tvals[bp[j]]
    }

    // ---- hand back to Stata ----
    st_matrix(nmB,    bMG)
    st_matrix(nmV,    V)
    st_matrix(nmBi,   Bmat)
    st_matrix(nmBrk,  bdt)
    st_matrix(nmProf, prof)

    st_local("r_N",     strofreal(N))
    st_local("r_T",     strofreal(Tfull))
    st_local("r_Teff",  strofreal(Teff))
    st_local("r_R",     strofreal(R))
    st_local("r_kcoef", strofreal(kcoef))
    st_local("r_nbrk",  strofreal(cols(bp)))
    st_local("r_ssr",   strofreal(totssr))
}

end
