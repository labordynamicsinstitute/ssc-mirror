*! xtvsom 1.0.0  18jul2026
*! Variance Shift Outlier Model (VSOM) for panel data.
*! Detects and accommodates outliers by shifting (down-weighting) their variance.
*! Implements Ismadyaliana, Setiawan & Purnomo, MethodsX 13 (2024) 102900,
*! building on Gumedze (2008) and Thompson (1985).
*! Part of the xtoutliers suite.
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
program define xtvsom, rclass
    version 14.0

    syntax [anything(name=vlist)] [if] [in] [ ,           ///
        FE OLS IV                                          ///
        Alpha(real 0.05)                                   ///
        Reps(integer 2000)                                 ///
        Seed(integer -1)                                   ///
        CUToff(real -1)                                    ///
        Level(cilevel)                                     ///
        GRAPH                                              ///
        name(string)                                       ///
        NOLABel ]

    // -------------------------------------------------------------------
    // 1. Determine mode: postestimation (empty vlist) vs standalone
    // -------------------------------------------------------------------
    local post = ("`vlist'" == "")

    local model ""
    if ("`fe'"  != "") local model "fe"
    if ("`ols'" != "") local model "ols"
    if ("`iv'"  != "") local model "iv"

    if (`post') {
        // read e() BEFORE holding it
        _xtvsom_efetch
        local dv    "`r(depvar)'"
        local ivars "`r(indepvars)'"
        local endog "`r(endog)'"
        local insts "`r(insts)'"
        local ivfe  "`r(ivfe)'"
        if ("`model'" == "") local model "`r(model)'"
    }
    else {
        gettoken dv ivars : vlist
        if ("`model'" == "") {
            di as error "specify a model: fe, ols, or iv"
            exit 198
        }
        if ("`model'" == "iv") {
            di as error "iv (simultaneous) mode is postestimation only:" ///
                _n "   run -ivregress 2sls- (or -xtivreg-), then -xtvsom-"
            exit 198
        }
    }
    if ("`dv'" == "") {
        di as error "could not determine the dependent variable"
        exit 198
    }

    // protect the caller's e() (restored on exit) now that we have read it
    tempname _h
    capture _estimates hold `_h', restore nullok

    // panel setup (needed for fe)
    capture qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`model'" == "fe" & "`ivar'" == "") {
        di as error "fe requires the data to be -xtset-"
        exit 459
    }

    marksample touse, novarlist
    markout `touse' `dv' `ivars' `endog' `insts' `ivar' `tvar'

    // -------------------------------------------------------------------
    // 2. Build the design.  For IV: first-stage fitted endogenous (2SLS).
    // -------------------------------------------------------------------
    local xnames "`ivars'"
    if ("`model'" == "iv") {
        if ("`ivfe'" == "1" & "`ivar'" == "") {
            di as error "FE 2SLS (xtivreg,fe) requires the data to be -xtset-"
            exit 459
        }
        local exog : list ivars - endog
        local fitnames ""
        local j 0
        foreach yv of local endog {
            local ++j
            tempvar yh`j'
            // e(insts) already contains the included exogenous regressors.
            // For FE-IV, add unit dummies so the first stage absorbs the FE
            // (LSDV first stage); the engine's within transform then yields
            // the within-fitted endogenous regressor.
            if ("`ivfe'" == "1") {
                qui regress `yv' `insts' i.`ivar' if `touse'
            }
            else {
                qui regress `yv' `insts' if `touse'
            }
            qui predict double `yh`j'' if `touse', xb
            local fitnames "`fitnames' `yh`j''"
        }
        local xnames "`fitnames' `exog'"
        if ("`ivfe'" == "1") local modnum 1   // FE 2SLS (within design)
        else                 local modnum 0   // pooled 2SLS design
        local dispx "`endog' `exog'"           // display names for the structural eq
    }
    else if ("`model'" == "fe") {
        local modnum 1
        local dispx "`ivars'"
    }
    else {
        local modnum 0
        local dispx "`ivars'"
    }

    // integer panel id + obs number + stable sort for panelsetup
    tempvar idn obsno idval tval
    if ("`ivar'" != "") {
        qui egen long `idn' = group(`ivar') if `touse'
    }
    else {
        qui gen long `idn' = 1 if `touse'
    }
    // numeric panel value for reporting (original id if numeric, else group)
    capture confirm numeric variable `ivar'
    if (_rc == 0 & "`ivar'" != "") qui gen double `idval' = `ivar'
    else                           qui gen double `idval' = `idn'
    // numeric time value for reporting
    if ("`tvar'" != "") qui gen double `tval' = `tvar'
    else                qui gen double `tval' = .
    qui gen long `obsno' = _n
    sort `idn' `tvar' `obsno'

    // output variables written by the Mata engine
    tempvar t2 psi s2i wgt res0 resV
    qui gen double `t2'   = .
    qui gen double `psi'  = .
    qui gen double `s2i'  = .
    qui gen double `wgt'  = .
    qui gen double `res0' = .
    qui gen double `resV' = .

    // -------------------------------------------------------------------
    // 3. Mata engine
    // -------------------------------------------------------------------
    mata: _xtvsom_engine("`dv'", "`xnames'", "`idn'", "`idval'", "`tval'",   ///
        "`obsno'", "`touse'", `modnum', `alpha', `reps', `seed', `cutoff',  ///
        "`t2'", "`psi'", "`s2i'", "`wgt'", "`res0'", "`resV'")

    // scalars posted by the engine
    local N      = r(N)
    local p      = r(p)
    local sig2   = r(sig2)
    local cut    = r(cutoff)
    local nout   = r(nout)
    local ssr0   = r(ssr0)
    local ssrv   = r(ssrv)
    local sig2v  = r(sig2v)
    tempname b0 V0 bV VV OL
    matrix `b0' = r(b0)
    matrix `V0' = r(V0)
    matrix `bV' = r(bV)
    matrix `VV' = r(VV)
    if (`nout' > 0) matrix `OL' = r(outliers)

    matrix colnames `b0' = `dispx'
    matrix colnames `bV' = `dispx'
    matrix colnames `V0' = `dispx'
    matrix rownames `V0' = `dispx'
    matrix colnames `VV' = `dispx'
    matrix rownames `VV' = `dispx'

    // -------------------------------------------------------------------
    // 4. Journal-style output
    // -------------------------------------------------------------------
    local ml = "`model'"
    if ("`ml'" == "iv") local ml "iv (2SLS, simultaneous)"
    di ""
    di as text "{hline 78}"
    di as text "Variance Shift Outlier Model (VSOM)" _col(50) "N (obs)   = " as result %9.0g `N'
    di as text "Model: " as result "`ml'" _col(50) as text "Params p  = " as result %9.0g `p'
    di as text "Outlier cutoff (max t{c 94}2, {&alpha}=" as result %4.3f `alpha' as text ")" ///
        _col(50) as text "cutoff    = " as result %9.4f `cut'
    di as text "{hline 78}"
    di as text "Outliers detected: " as result `nout' as text "   (t{c 94}2 > cutoff)"
    di as text "SSR  null model : " as result %12.5f `ssr0'
    di as text "SSR  VSOM model : " as result %12.5f `ssrv' ///
        as text "   ({&Delta} = " as result %6.2f 100*(`ssrv'-`ssr0')/`ssr0' as text "%)"
    di as text "{hline 78}"

    // coefficient comparison table (null vs VSOM)
    di ""
    di as text "Coefficient comparison"
    di as text "{hline 78}"
    di as text %-14s "Variable" ///
        _col(15) %11s "Null b" _col(27) %10s "Null SE" ///
        _col(40) %11s "VSOM b" _col(52) %10s "VSOM SE" _col(64) %10s "VSOM t"
    di as text "{hline 78}"
    local nc = colsof(`b0')
    forvalues i = 1/`nc' {
        local vn : word `i' of `dispx'
        local b0i = `b0'[1,`i']
        local s0i = sqrt(`V0'[`i',`i'])
        local bvi = `bV'[1,`i']
        local svi = sqrt(`VV'[`i',`i'])
        local tvi = `bvi'/`svi'
        local pvi = 2*ttail(`N'-`p', abs(`tvi'))
        local star ""
        if (`pvi' < 0.10) local star "*"
        if (`pvi' < 0.05) local star "**"
        if (`pvi' < 0.01) local star "***"
        di as text %-14s abbrev("`vn'",14) ///
            _col(15) as result %11.5f `b0i' _col(27) %10.5f `s0i' ///
            _col(40) %11.5f `bvi' _col(52) %10.5f `svi' _col(64) %9.3f `tvi' as result "`star'"
    }
    di as text "{hline 78}"
    di as text "* p<.10  ** p<.05  *** p<.01   (VSOM = feasible GLS = WLS, weights 1/(1+{&psi}))"

    // outlier detail table
    if (`nout' > 0) {
        di ""
        di as text "Detected outliers"
        di as text "{hline 78}"
        di as text %-8s "obs" _col(9) %-10s "panel" _col(20) %-8s "time" ///
            _col(28) %10s "t{c 94}2" _col(40) %10s "psi" ///
            _col(51) %11s "resid0" _col(63) %11s "residVSOM"
        di as text "{hline 78}"
        local nr = rowsof(`OL')
        forvalues r = 1/`nr' {
            local ob  = `OL'[`r',1]
            local idv = `OL'[`r',2]
            local tv  = `OL'[`r',3]
            local t2r = `OL'[`r',4]
            local psr = `OL'[`r',5]
            local r0r = `OL'[`r',7]
            local rVr = `OL'[`r',8]
            local plab "`idv'"
            if ("`nolabel'" == "" & "`ivar'" != "") {
                local plab : label (`ivar') `idv'
                if ("`plab'" == "") local plab "`idv'"
            }
            di as text %-8.0f `ob' _col(9) as result %-10s abbrev("`plab'",10) ///
                _col(20) as result %-8.0f `tv' ///
                _col(28) %10.4f `t2r' _col(40) %10.4f `psr' ///
                _col(51) %11.5f `r0r' _col(63) %11.5f `rVr'
        }
        di as text "{hline 78}"
    }

    // -------------------------------------------------------------------
    // 5. Stored results
    // -------------------------------------------------------------------
    return scalar N       = `N'
    return scalar p       = `p'
    return scalar nout    = `nout'
    return scalar cutoff  = `cut'
    return scalar alpha   = `alpha'
    return scalar sigma2  = `sig2'
    return scalar sigma2v = `sig2v'
    return scalar ssr0    = `ssr0'
    return scalar ssrv    = `ssrv'
    return local  model   "`model'"
    return local  depvar  "`dv'"
    return local  cmd     "xtvsom"
    return matrix b_null  = `b0'
    return matrix V_null  = `V0'
    return matrix b_vsom  = `bV'
    return matrix V_vsom  = `VV'
    if (`nout' > 0) return matrix outliers = `OL'

    // -------------------------------------------------------------------
    // 6. Figures (reproduce the four MethodsX figure types)
    // -------------------------------------------------------------------
    if ("`graph'" != "") {
        if ("`name'" == "") local name "xtvsom"
        // outlier flag and the residual threshold |e| = sqrt(cutoff*sigma^2)
        tempvar outf
        qui gen byte `outf' = (`t2' > `cut') if `touse'
        local ethr = sqrt(`cut' * `sig2')
        _xtvsom_graph `t2' `psi' `s2i' `res0' `resV' `obsno' `outf' `touse' ///
            `cut' `ethr' "`name'"
    }

    // restore user's original sort
    sort `obsno'
end

// ----------------------------------------------------------------------
// Fetch model info from e() for postestimation mode
// ----------------------------------------------------------------------
program define _xtvsom_efetch, rclass
    if ("`e(cmd)'" == "") {
        di as error "no previous estimation results; " ///
            "fit -xtreg,fe- / -regress- / -ivregress 2sls- first, or run standalone"
        exit 301
    }
    local ec "`e(cmd)'"
    local ok = inlist("`ec'","xtreg","regress","ivregress","xtivreg","areg","reghdfe")
    if (!`ok') {
        di as error "xtvsom does not support postestimation after -`ec'-"
        exit 321
    }
    return local depvar "`e(depvar)'"

    // regressors = colnames of e(b) minus _cons
    local iv : colnames e(b)
    local iv : subinstr local iv "_cons" "", word all
    return local indepvars "`iv'"

    // model detection
    local m "ols"
    if inlist("`ec'","xtreg","xtivreg","areg","reghdfe") {
        local mo "`e(model)'"
        if ("`mo'" == "fe" | "`ec'" == "areg" | "`ec'" == "reghdfe") local m "fe"
        else if ("`mo'" == "re") local m "fe"   // VSOM path uses the within design
    }
    if inlist("`ec'","ivregress","xtivreg") {
        local m "iv"
        return local endog "`e(instd)'"
        return local insts "`e(insts)'"
        // FE-IV (xtivreg,fe) vs pooled 2SLS (ivregress)
        return local ivfe = ("`e(model)'" == "fe")
    }
    return local model "`m'"
end

// ----------------------------------------------------------------------
// Graphs: (a) t2 with cutoff  (b) residual null vs VSOM
//         (c) psi spikes      (d) sigma2_i
// ----------------------------------------------------------------------
program define _xtvsom_graph
    args t2 psi s2i res0 resV obsno outf touse cut ethr name

    preserve
    qui keep if `touse'
    tempvar oo
    qui gen long `oo' = `obsno'

    local sch "graphregion(color(white)) plotregion(color(white))"
    local cutstr = string(`cut', "%6.3f")

    // (a) t^2 by observation, cutoff line, outliers labelled (paper Fig 1/5/9)
    qui twoway ///
        (scatter `t2' `oo' if `outf'==0, mcolor(navy) msize(small)) ///
        (scatter `t2' `oo' if `outf'==1, mcolor(red) msize(medium) ///
            mlabel(`oo') mlabcolor(red) mlabsize(small) mlabposition(12)) ///
        , yline(`cut', lcolor(red) lpattern(dash)) ///
        title("(a) Standardized squared residual", size(medsmall)) ///
        ytitle("t{superscript:2}") xtitle("Observation") ///
        legend(off) note("cutoff = `cutstr'") ///
        `sch' name(`name'_a, replace) nodraw

    // (b) null vs VSOM residuals, two dashed bounds, outliers labelled
    //     (paper Fig 2/6/10): null outliers sit outside the bounds, their
    //     VSOM counterparts are pulled back inside.
    qui twoway ///
        (scatter `res0' `oo' if `outf'==0, mcolor(salmon) msize(vsmall)) ///
        (scatter `resV' `oo' if `outf'==0, mcolor(teal)   msize(vsmall)) ///
        (scatter `res0' `oo' if `outf'==1, mcolor(red)  msize(small) ///
            mlabel(`oo') mlabcolor(red) mlabsize(vsmall) mlabposition(12)) ///
        (scatter `resV' `oo' if `outf'==1, mcolor(dkgreen) msize(small) ///
            mlabel(`oo') mlabcolor(black) mlabsize(vsmall) mlabposition(6)) ///
        , yline(`ethr' -`ethr', lcolor(blue) lpattern(dash)) ///
        yline(0, lcolor(gs12)) ///
        title("(b) Residuals: null vs VSOM", size(medsmall)) ///
        ytitle("Residual") xtitle("Observation") ///
        legend(order(1 "null" 2 "VSOM") size(small) rows(1)) ///
        `sch' name(`name'_b, replace) nodraw

    // (c) variance-shift component psi (paper Fig 3/7/11)
    qui twoway (dropline `psi' `oo', lcolor(dkgreen) mcolor(dkgreen)) ///
        , title("(c) Variance-shift component {&psi}", size(medsmall)) ///
        ytitle("{&psi}{subscript:it}") xtitle("Observation") ///
        `sch' name(`name'_c, replace) nodraw

    // (d) variance estimate sigma^2 (paper Fig 4/8/12)
    qui twoway (scatter `s2i' `oo', mcolor(orange) msize(small)) ///
        , title("(d) Variance estimate {&sigma}{superscript:2}", size(medsmall)) ///
        ytitle("{&sigma}{superscript:2}{subscript:it}") xtitle("Observation") ///
        `sch' name(`name'_d, replace) nodraw

    graph combine `name'_a `name'_b `name'_c `name'_d, ///
        title("VSOM diagnostics", size(medium)) ///
        `sch' name(`name', replace)

    restore
end

// ======================================================================
// Mata engine for xtvsom
// ======================================================================
version 14.0
mata:

// demean a column vector within panels defined by panelsetup info
real colvector _xtvsom_dm(real colvector z, real matrix info)
{
    real scalar g, a, b
    real colvector out
    out = z
    for (g=1; g<=rows(info); g++) {
        a = info[g,1]
        b = info[g,2]
        out[|a \ b|] = z[|a \ b|] :- mean(z[|a \ b|])
    }
    return(out)
}

// demean a matrix within panels
real matrix _xtvsom_dmM(real matrix X, real matrix info)
{
    real scalar g, a, b
    real matrix out
    real rowvector mu
    out = X
    for (g=1; g<=rows(info); g++) {
        a = info[g,1]
        b = info[g,2]
        mu = mean(X[|a,1 \ b,cols(X)|])
        out[|a,1 \ b,cols(X)|] = X[|a,1 \ b,cols(X)|] :- mu
    }
    return(out)
}

// type-7 empirical quantile
real scalar _xtvsom_quant(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, pos, lo, fr
    s = sort(x, 1)
    n = rows(s)
    if (n == 1) return(s[1])
    pos = p*(n-1) + 1
    lo  = floor(pos)
    fr  = pos - lo
    if (lo >= n) return(s[n])
    return(s[lo] + fr*(s[lo+1] - s[lo]))
}

void _xtvsom_engine(string scalar yv, string scalar xv, string scalar idnv,
    string scalar idvalv, string scalar tvalv, string scalar obsv,
    string scalar tousev, real scalar model, real scalar alpha,
    real scalar reps, real scalar seed, real scalar cutin,
    string scalar t2v, string scalar psiv, string scalar s2v,
    string scalar wv, string scalar r0v, string scalar rVv)
{
    real colvector y, idn, idval, tval, obsno, Tvec, yd
    real matrix X, Xd, info
    real scalar N, k, p, npan, g, a, b, sig2
    real colvector e, h, hlev, t2, b0, r, rV, psi, s2i, w
    real matrix M, MW
    real colvector bV, mx, z, zt, ez, diagVV, diagV0
    real matrix V0, VV
    real scalar j, i, dpq, cutoff, nout, ssr0, ssrv, sig2v
    real colvector oidx
    real matrix OL

    st_view(y=.,     ., yv,     tousev)
    st_view(X=.,     ., tokens(xv), tousev)
    st_view(idn=.,   ., idnv,   tousev)
    st_view(idval=., ., idvalv, tousev)
    st_view(tval=.,  ., tvalv,  tousev)
    st_view(obsno=., ., obsv,   tousev)

    N = rows(y)
    k = cols(X)
    info = panelsetup(idn, 1)
    npan = rows(info)

    // ---- design + degrees of freedom ----
    if (model == 1) {
        // FE: within transform, no constant; p = npan + k
        yd = _xtvsom_dm(y, info)
        Xd = _xtvsom_dmM(X, info)
        p  = npan + k
        // per-obs T_i for the mean-projection leverage
        Tvec = J(N,1,.)
        for (g=1; g<=npan; g++) {
            a = info[g,1]
            b = info[g,2]
            Tvec[|a \ b|] = J(b-a+1, 1, b-a+1)
        }
    }
    else {
        // pooled / 2SLS structural design: add a constant
        yd = y
        Xd = (X, J(N,1,1))
        p  = k + 1
        Tvec = J(N,1,.)
    }

    M  = invsym(cross(Xd, Xd))
    b0 = M * cross(Xd, yd)
    e  = yd - Xd*b0
    sig2 = (e'e) / (N - p)

    // leverage (diagonal of hat) computed row-wise, no NxN matrix
    hlev = rowsum((Xd*M) :* Xd)
    if (model == 1) h = hlev :+ (1:/Tvec)
    else            h = hlev

    // guard 1-h
    for (i=1; i<=N; i++) {
        if (h[i] >= 1) h[i] = 0.9999999
    }

    t2 = (e:^2) :/ (sig2 :* (1 :- h))

    // ---- cutoff via parametric bootstrap of max t2 ----
    if (cutin > 0) {
        cutoff = cutin
    }
    else {
        if (seed >= 0) rseed(seed)
        mx = J(reps, 1, .)
        for (j=1; j<=reps; j++) {
            z = rnormal(N, 1, 0, 1)
            if (model == 1) zt = _xtvsom_dm(z, info)
            else            zt = z
            ez = zt - Xd*(M*cross(Xd, zt))
            mx[j] = max( (ez:^2) :/ (((ez'ez)/(N-p)) :* (1 :- h)) )
        }
        cutoff = _xtvsom_quant(mx, 1 - alpha)
    }

    // ---- detection + variance-shift estimates ----
    psi = J(N,1,0)
    s2i = J(N,1,sig2)
    for (i=1; i<=N; i++) {
        if (t2[i] > cutoff & t2[i] > 1) {
            dpq = (N - p) - t2[i]
            if (dpq > 0) {
                psi[i] = (N-p)*(t2[i]-1) / (dpq*(1-h[i]))
                s2i[i] = dpq/(N-p-1) * sig2
            }
            else {
                psi[i] = 1e6
                s2i[i] = sig2 * 1e-6
            }
        }
    }
    w = 1 :/ (1 :+ psi)

    // ---- VSOM refit = WLS with weights w (diagonal P^{-1}) ----
    MW = invsym(cross(Xd, w, Xd))
    bV = MW * cross(Xd, w, yd)
    r  = yd - Xd*bV
    rV = w :* r                    // = y - Xb_V - D theta  (see methods help)

    ssr0 = e'e
    ssrv = rV'rV
    sig2v = sum(w :* (r:^2)) / (N - p)

    V0 = sig2  * M
    VV = sig2v * MW

    // FE: strip the design's leading structure? No — Xd is slopes only for FE,
    // (X, cons) for pooled; return the coefficient block for the display names.
    // For pooled/2SLS drop the constant column so dims match dispx (k names).
    if (model == 1) {
        // slopes are b0[1..k]; already k of them
        diagV0 = diagonal(V0)
        diagVV = diagonal(VV)
        st_matrix("r(b0)", b0')
        st_matrix("r(bV)", bV')
        st_matrix("r(V0)", V0)
        st_matrix("r(VV)", VV)
    }
    else {
        // drop constant (last column) for reporting to match k display names
        st_matrix("r(b0)", (b0[1..k])')
        st_matrix("r(bV)", (bV[1..k])')
        st_matrix("r(V0)", V0[1..k, 1..k])
        st_matrix("r(VV)", VV[1..k, 1..k])
    }

    // ---- write back per-obs variables ----
    st_store(., t2v,  tousev, t2)
    st_store(., psiv, tousev, psi)
    st_store(., s2v,  tousev, s2i)
    st_store(., wv,   tousev, w)
    st_store(., r0v,  tousev, e)
    st_store(., rVv,  tousev, rV)

    // ---- outlier list matrix ----
    oidx = select((1::N), t2 :> cutoff)
    nout = rows(oidx)
    if (nout > 0) {
        OL = J(nout, 9, .)
        for (i=1; i<=nout; i++) {
            g = oidx[i]
            OL[i,1] = obsno[g]
            OL[i,2] = idval[g]
            OL[i,3] = tval[g]
            OL[i,4] = t2[g]
            OL[i,5] = psi[g]
            OL[i,6] = s2i[g]
            OL[i,7] = e[g]
            OL[i,8] = rV[g]
            OL[i,9] = w[g]
        }
        st_matrix("r(outliers)", OL)
    }

    st_numscalar("r(N)",     N)
    st_numscalar("r(p)",     p)
    st_numscalar("r(sig2)",  sig2)
    st_numscalar("r(sig2v)", sig2v)
    st_numscalar("r(cutoff)",cutoff)
    st_numscalar("r(nout)",  nout)
    st_numscalar("r(ssr0)",  ssr0)
    st_numscalar("r(ssrv)",  ssrv)
}

end

