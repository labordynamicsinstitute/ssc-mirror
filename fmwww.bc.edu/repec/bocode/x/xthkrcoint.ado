*! xthkrcoint 1.0.0  08jul2026
*! Hadri, Kurozumi & Rao (2015) panel cointegration test (N fixed, T large)
*! Null of cointegration; DOLS-residual autocovariance statistic; CSD-robust
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane
*  Reference: Hadri, K., Kurozumi, E. & Rao, Y. (2015). Novel Panel
*  Cointegration Tests Emending for Cross-Section Dependence with N Fixed.
*  Econometrics Journal, 18(3), 363-411. doi:10.1111/ectj.12054

program define xthkrcoint, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in] [ ,   ///
        TRend                                         ///
        K(integer -1)                                 ///
        M(integer -1)                                 ///
        J(integer -1)                                 ///
        A(real 2)                                     ///
        Delta(real 0.5)                               ///
        OLS                                           ///
        NOINDividual                                  ///
        GRaph                                         ///
        KSENS(numlist integer >0 sort)               ///
        NAME(string)                                  ///
        SCHeme(string)                                ///
        TITle(string) ]

    // --------------------------------------------------------------------
    // 0.  Parse the dependent variable and I(1) regressors
    // --------------------------------------------------------------------
    gettoken depvar xvars : varlist
    local xvars = strtrim("`xvars'")
    if ("`xvars'"=="") {
        di as error "at least one I(1) regressor must be specified"
        exit 198
    }

    local trendflag = ("`trend'"!="")
    local dools     = ("`ols'"!="")           // extra OLS-residual comparator
    local showind   = ("`noindividual'"=="")
    local dograph   = ("`graph'"!="")
    if ("`scheme'"=="")  local scheme "s2color"
    if ("`name'"=="")    local name  "xthkr"

    // sensitivity requested if the user asked for a grid, or graph is on
    local wantks = 0
    if ("`ksens'"!="" | `dograph'==1) local wantks = 1

    // --------------------------------------------------------------------
    // 1.  Recover the panel / time identifiers from xtset (or tsset)
    // --------------------------------------------------------------------
    capture qui xtset
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`tvar'"=="") {
        capture qui tsset
        local tvar "`r(timevar)'"
    }
    if ("`tvar'"=="") {
        di as error "data must be {help xtset:xtset} (panel) or {help tsset:tsset} (single series) first"
        exit 459
    }
    if ("`ivar'"=="") {                        // single time series -> N = 1
        tempvar _one
        qui gen byte `_one' = 1
        local ivar `_one'
    }

    // --------------------------------------------------------------------
    // 2.  Estimation sample
    // --------------------------------------------------------------------
    marksample touse, novarlist
    markout `touse' `depvar' `xvars' `ivar' `tvar'
    qui count if `touse'
    if (r(N)==0) {
        di as error "no observations"
        exit 2000
    }

    // --------------------------------------------------------------------
    // 3.  Build the K-sensitivity grid (passed to Mata as a space list)
    // --------------------------------------------------------------------
    local ksgrid "`ksens'"                     // may be empty -> Mata builds default

    // --------------------------------------------------------------------
    // 4.  Call the Mata computation engine
    // --------------------------------------------------------------------
    tempname PANEL INDIV KSENS RCFLAG

    mata: xthkr_run()

    if (scalar(`RCFLAG')==1) {
        di as error "effective sample too small: K is not smaller than (T-2M-1)."
        di as error "reduce k() / m() or supply a longer T."
        exit 198
    }
    if (scalar(`RCFLAG')==2) {
        di as error "panel is not strongly balanced over the estimation sample."
        di as error "xthkrcoint requires equal T for every unit (no gaps)."
        exit 451
    }

    // --------------------------------------------------------------------
    // 5.  Unpack the pooled results
    // --------------------------------------------------------------------
    local S     = `PANEL'[1,1]
    local p     = `PANEL'[1,2]
    local Sbc   = `PANEL'[1,3]
    local pbc   = `PANEL'[1,4]
    local Sols  = `PANEL'[1,5]
    local pols  = `PANEL'[1,6]
    local Cbar  = `PANEL'[1,7]
    local omega = `PANEL'[1,8]
    local bias  = `PANEL'[1,9]
    local Kused = `PANEL'[1,10]
    local Mused = `PANEL'[1,11]
    local Jused = `PANEL'[1,12]
    local Npan  = `PANEL'[1,13]
    local Tlen  = `PANEL'[1,14]
    local neff  = `PANEL'[1,15]
    local na    = `PANEL'[1,16]
    local pcnt  = `PANEL'[1,17]
    local pxnt  = `PANEL'[1,18]

    // --------------------------------------------------------------------
    // 6.  Journal-style output
    // --------------------------------------------------------------------
    if ("`trendflag'"=="1") local detlab "constant & linear trend"
    else                    local detlab "constant"
    if ("`title'"=="") local title "Hadri-Kurozumi-Rao panel cointegration test"

    _hkr_stars, p(`pbc')
    local st_bc "`r(stars)'"
    _hkr_stars, p(`p')
    local st_s "`r(stars)'"

    di ""
    di as text "{hline 78}"
    di as text "`title'"
    di as text "N fixed, T {c -}> infinity  {c |}  H0: all units are cointegrated"
    di as text "{hline 78}"
    di as text "Deterministics       : " as result "`detlab'"                     ///
       _col(48) as text "Panels  (N) = " as result %6.0f `Npan'
    di as text "Test residuals       : " as result "DOLS (leads & lags)"          ///
       _col(48) as text "Periods (T) = " as result %6.0f `Tlen'
    di as text "Long-run variance    : " as result "Bartlett kernel"              ///
       _col(48) as text "Eff. obs    = " as result %6.0f `neff'
    di as text "Lag order   K = " as result %4.0f `Kused'                         ///
       as text "   Leads/lags M = " as result %3.0f `Mused'                       ///
       as text "   Bandwidth J = " as result %4.0f `Jused'                        ///
       as text "   (T-K) = " as result %5.0f `na'
    di as text "{hline 78}"
    di as text %-34s "Pooled statistic"                                           ///
       _col(38) %10s "Value" _col(52) %10s "p-value" _col(64) %8s "Decision"
    di as text "{hline 78}"
    di as text %-34s "  S_K   (autocov., uncorrected)"                            ///
       as result _col(38) %10.4f `S' _col(52) %10.4f `p'
    di as text %-34s "  S~_K  (bias-corrected)"                                   ///
       as result _col(38) %10.4f `Sbc' _col(52) %10.4f `pbc'                      ///
       as result _col(64) "`st_bc'"
    if (`dools'==1) {
        di as text %-34s "  S_K   (OLS residuals)"                                ///
           as result _col(38) %10.4f `Sols' _col(52) %10.4f `pols'
    }
    di as text "{hline 78}"
    if (`pbc' < 0.05) {
        di as text "Decision (5%): " as result                                    ///
           "reject H0 {c -}> evidence AGAINST panel cointegration."
    }
    else {
        di as text "Decision (5%): " as result                                    ///
           "do not reject H0 {c -}> panel cointegration is supported."
    }
    di as text "One-sided upper-tail test.  Stars: *** p<.01, ** p<.05, * p<.10."
    di as text "{hline 78}"

    // --------------------------------------------------------------------
    // 7.  Per-unit table
    // --------------------------------------------------------------------
    if (`showind'==1 & `Npan'>1) {
        di ""
        di as text "Unit-specific cointegration tests (bias-corrected)"
        di as text "{hline 66}"
        di as text %6s "Unit" _col(10) %7s "T_i" _col(20) %10s "S_K"             ///
           _col(32) %10s "S~_K" _col(46) %9s "p-value" _col(58) %8s ""
        di as text "{hline 66}"
        forvalues i = 1/`Npan' {
            local uid  = `INDIV'[`i',1]
            local uti  = `INDIV'[`i',2]
            local us   = `INDIV'[`i',4]
            local usbc = `INDIV'[`i',5]
            local upbc = `INDIV'[`i',7]
            _hkr_stars, p(`upbc')
            local ust "`r(stars)'"
            if (`upbc' < 0.05) local dec "not coint."
            else               local dec "coint."
            di as result %6.0f `uid' _col(10) %7.0f `uti'                        ///
               _col(20) %10.4f `us' _col(32) %10.4f `usbc'                       ///
               _col(46) %9.4f `upbc' as text _col(57) "`ust'"                    ///
               _col(58) as text "  `dec'"
        }
        di as text "{hline 66}"
        di as text "H0 (per unit): the series is cointegrated.  *** / ** / * = 1/5/10%."
    }

    // --------------------------------------------------------------------
    // 8.  Publication graphs
    // --------------------------------------------------------------------
    if (`dograph'==1) {
        _hkr_graphs, indiv(`INDIV') ksens(`KSENS') npan(`Npan')                  ///
            name(`name') scheme(`scheme') kused(`Kused')
    }

    // --------------------------------------------------------------------
    // 9.  Returned results
    // --------------------------------------------------------------------
    return local  cmd      "xthkrcoint"
    return local  depvar   "`depvar'"
    return local  regr     "`xvars'"
    return local  det      "`detlab'"
    return local  null     "panel cointegration"
    return scalar N        = `Npan'
    return scalar T        = `Tlen'
    return scalar Teff     = `neff'
    return scalar na       = `na'
    return scalar K        = `Kused'
    return scalar M        = `Mused'
    return scalar J        = `Jused'
    return scalar S        = `S'
    return scalar p        = `p'
    return scalar Sbc      = `Sbc'
    return scalar pbc      = `pbc'
    return scalar Cbar     = `Cbar'
    return scalar omega_a  = `omega'
    return scalar bias     = `bias'
    if (`dools'==1) {
        return scalar Sols = `Sols'
        return scalar pols = `pols'
    }
    matrix colnames `INDIV' = unit T_i K S_K S_bc p_S p_bc S_ols p_ols
    return matrix indiv    = `INDIV'
    if (`wantks'==1) {
        matrix colnames `KSENS' = K S_K S_bc p_S p_bc
        return matrix ksens = `KSENS'
    }
    matrix colnames `PANEL' = S_K p_S S_bc p_bc S_ols p_ols Cbar omega_a bias ///
        K M J N T Teff na p_c p_x trend ols
    return matrix panel    = `PANEL'
end

// ------------------------------------------------------------------------
//  Significance stars from a one-sided p-value
// ------------------------------------------------------------------------
program define _hkr_stars, rclass
    syntax , p(real)
    local s ""
    if (`p' < 0.10) local s "*"
    if (`p' < 0.05) local s "**"
    if (`p' < 0.01) local s "***"
    return local stars "`s'"
end

// ------------------------------------------------------------------------
//  Publication-quality graphs (forest plot + K-sensitivity)
// ------------------------------------------------------------------------
program define _hkr_graphs
    syntax , indiv(name) ksens(name) npan(integer) name(string) ///
        scheme(string) kused(real)

    tempname IND KS
    matrix `IND' = `indiv'
    capture matrix `KS' = `ksens'
    local haveks = (_rc==0)

    preserve
    clear

    // ---- (1) Forest / caterpillar plot of unit bias-corrected statistics --
    quietly {
        svmat double `IND', name(iv)
        // iv1 unit, iv2 T_i, iv3 K, iv4 S_K, iv5 S_bc, iv6 p_S, iv7 p_bc
        gen double _stat = iv5
        gen double _pv   = iv7
        gen double _uid  = iv1
        gen long   _ord  = _n
        gen byte   _rej  = (_pv < 0.05)
        gen double _zero = 0
    }
    twoway                                                                       ///
        (rspike _zero _stat _ord, horizontal lcolor(gs11) lwidth(vthin))         ///
        (scatter _ord _stat if _rej==0,                                          ///
              msymbol(O) mcolor(navy) msize(medium))                            ///
        (scatter _ord _stat if _rej==1,                                          ///
              msymbol(O) mcolor(cranberry) msize(medium)),                       ///
        xline(0, lcolor(gs8) lpattern(solid))                                    ///
        xline(1.645, lcolor(orange) lpattern(dash))                              ///
        xline(2.326, lcolor(cranberry) lpattern(shortdash))                      ///
        ylabel(1(1)`npan', angle(0) labsize(small) grid glcolor(gs15))          ///
        ytitle("Cross-section unit")                                             ///
        xtitle("Bias-corrected statistic  S~{sub:K}")                            ///
        title("Unit-specific cointegration tests", size(medium))                 ///
        subtitle("N fixed, T large {c -}> HKR (2015)", size(small))              ///
        legend(order(2 "Not rejected" 3 "Rejected (5%)") size(small)             ///
              region(lstyle(none)) rows(1) pos(6))                               ///
        note("Vertical lines: 5% (1.645) and 1% (2.326) one-sided critical values.", ///
              size(vsmall))                                                       ///
        scheme(`scheme') plotregion(style(none))                                 ///
        name(`name'_units, replace) nodraw

    // ---- (2) K-sensitivity curve -----------------------------------------
    if (`haveks'==1) {
        clear
        quietly {
            svmat double `KS', name(ks)
            // ks1 K, ks2 S_K, ks3 S_bc, ks4 p_S, ks5 p_bc
        }
        twoway                                                                   ///
            (line ks3 ks1, lcolor(navy) lwidth(medthick))                        ///
            (line ks2 ks1, lcolor(gs9) lpattern(dash) lwidth(medium)),           ///
            yline(1.645, lcolor(orange) lpattern(dash))                          ///
            yline(2.326, lcolor(cranberry) lpattern(shortdash))                  ///
            xline(`kused', lcolor(gs12) lpattern(dot))                           ///
            ytitle("Pooled statistic") xtitle("Lag order  K")                    ///
            title("Sensitivity to the lag order K", size(medium))                ///
            legend(order(1 "S~{sub:K} (bias-corrected)" 2 "S{sub:K} (uncorrected)") ///
                  size(small) region(lstyle(none)) rows(1) pos(6))               ///
            note("Horizontal lines: 5% and 1% critical values. Dotted line: reported K.", ///
                  size(vsmall))                                                   ///
            scheme(`scheme') plotregion(style(none))                             ///
            name(`name'_ksens, replace) nodraw

        graph combine `name'_units `name'_ksens,                                 ///
            cols(2) imargin(medium)                                              ///
            title("Hadri-Kurozumi-Rao panel cointegration diagnostics",          ///
                  size(medsmall))                                                 ///
            scheme(`scheme') name(`name', replace)
        graph display `name'
    }
    else {
        graph display `name'_units
    }

    restore
end

// ========================================================================
//  MATA COMPUTATION ENGINE
// ========================================================================
version 14.0
mata:

// -- Bartlett long-run variance of a raw series (no demeaning) ------------
real scalar _hkr_lrv(real colvector s, real scalar J)
{
    real scalar n, g0, gj, j, t, lrv
    n = rows(s)
    g0 = 0
    for (t=1; t<=n; t++) {
        g0 = g0 + s[t]*s[t]
    }
    g0 = g0/n
    lrv = g0
    for (j=1; j<=J; j++) {
        gj = 0
        for (t=j+1; t<=n; t++) {
            gj = gj + s[t]*s[t-j]
        }
        gj = gj/n
        lrv = lrv + 2*(1 - j/(J+1))*gj
    }
    if (lrv <= 0) {
        lrv = g0
    }
    return(lrv)
}

// -- Cross-product series a_{K,t} = r_t * r_{t-K} -------------------------
real colvector _hkr_avec(real colvector r, real scalar K)
{
    real scalar n, na, m
    real colvector a
    n = rows(r)
    na = n - K
    a = J(na, 1, 0)
    for (m=1; m<=na; m++) {
        a[m] = r[K+m]*r[m]
    }
    return(a)
}

// -- DOLS-residual vector for one panel -----------------------------------
real colvector _hkr_dols(real colvector yi, real matrix xi, real scalar M,
                         real scalar trend, real scalar Tlen)
{
    real scalar px, t0, t1, neff, ncol, row, col, tt, j, c
    real matrix v, W, XtX
    real colvector yv, b, res
    px = cols(xi)
    v = J(Tlen, px, 0)
    for (tt=2; tt<=Tlen; tt++) {
        for (c=1; c<=px; c++) {
            v[tt,c] = xi[tt,c] - xi[tt-1,c]
        }
    }
    t0 = M + 2
    t1 = Tlen - M
    neff = t1 - t0 + 1
    ncol = 1 + trend + px + (2*M+1)*px
    W  = J(neff, ncol, 0)
    yv = J(neff, 1, 0)
    row = 0
    for (tt=t0; tt<=t1; tt++) {
        row = row + 1
        col = 1
        W[row,col] = 1
        if (trend==1) {
            col = col + 1
            W[row,col] = tt
        }
        for (c=1; c<=px; c++) {
            col = col + 1
            W[row,col] = xi[tt,c]
        }
        for (j=-M; j<=M; j++) {
            for (c=1; c<=px; c++) {
                col = col + 1
                W[row,col] = v[tt-j,c]
            }
        }
        yv[row] = yi[tt]
    }
    XtX = quadcross(W,W)
    b   = invsym(XtX)*quadcross(W,yv)
    res = yv - W*b
    return(res)
}

// -- Plain OLS residuals on [det, levels], full sample --------------------
real colvector _hkr_ols(real colvector yi, real matrix xi, real scalar trend,
                        real scalar Tlen)
{
    real scalar px, ncol, row, col, tt, c
    real matrix W
    real colvector b, res
    px = cols(xi)
    ncol = 1 + trend + px
    W = J(Tlen, ncol, 0)
    for (tt=1; tt<=Tlen; tt++) {
        col = 1
        W[tt,col] = 1
        if (trend==1) {
            col = col + 1
            W[tt,col] = tt
        }
        for (c=1; c<=px; c++) {
            col = col + 1
            W[tt,col] = xi[tt,c]
        }
    }
    b = invsym(quadcross(W,W))*quadcross(W,yi)
    res = yi - W*b
    return(res)
}

// -- Pooled panel statistic at a given K ----------------------------------
//    R      : neff x N standardized DOLS residuals
//    bcomp  : N x 1  (omega^2_eta / sigma^2_eta)
//    returns rowvector (S, p, Sbc, pbc, Cbar, omega_a, bias)
real rowvector _hkr_pool(real matrix R, real colvector bcomp, real scalar K,
                         real scalar J, real scalar pc, real scalar px)
{
    real scalar N, neff, na, i, C, omega, bias, S, Sbc, p, pbc, sq
    real colvector A, ai
    N = cols(R)
    neff = rows(R)
    na = neff - K
    A = J(na, 1, 0)
    for (i=1; i<=N; i++) {
        ai = _hkr_avec(R[.,i], K)
        A = A + ai
    }
    C = colsum(A)/sqrt(na)
    omega = _hkr_lrv(A, J)
    sq = sqrt(omega)
    bias = ((pc+px)*colsum(bcomp))/sqrt(na)
    S   = C/sq
    Sbc = (C+bias)/sq
    p   = 1 - normal(S)
    pbc = 1 - normal(Sbc)
    return((S, p, Sbc, pbc, C, omega, bias))
}

// -- Main driver ----------------------------------------------------------
void xthkr_run()
{
    real colvector y, id, tt, bcomp, sig2, res, r, Ai
    real matrix X, info, R, Rols, INDIV, KSENS, PANEL
    real scalar N, px, pc, trend, Mopt, Kopt, Jopt, aa, dd, dools, wantks
    real scalar Tlen, i, r1, r2, Ti, M, J, K, neff, na, ok
    real scalar sigma, w2eta, Ci, omi, bi, Si, Sbci, pi, pbi
    real scalar solsp, polsp, ncols, kmin, kmax, ng, g, kg
    real rowvector pr
    real colvector yi, resols, rols
    real matrix xi
    string rowvector xn

    y  = st_data(., st_local("depvar"), st_local("touse"))
    xn = tokens(st_local("xvars"))
    X  = st_data(., xn, st_local("touse"))
    id = st_data(., st_local("ivar"), st_local("touse"))
    tt = st_data(., st_local("tvar"), st_local("touse"))

    px    = cols(X)
    trend = strtoreal(st_local("trendflag"))
    pc    = 1 + trend
    Mopt  = strtoreal(st_local("m"))
    Kopt  = strtoreal(st_local("k"))
    Jopt  = strtoreal(st_local("j"))
    aa    = strtoreal(st_local("a"))
    dd    = strtoreal(st_local("delta"))
    dools = strtoreal(st_local("dools"))
    wantks= strtoreal(st_local("wantks"))

    info = panelsetup(id, 1)
    N = rows(info)

    // balance check
    Tlen = info[1,2] - info[1,1] + 1
    ok = 1
    for (i=1; i<=N; i++) {
        if ((info[i,2]-info[i,1]+1) != Tlen) {
            ok = 0
        }
    }
    if (ok==0) {
        st_numscalar(st_local("RCFLAG"), 2)
        return
    }

    // resolve tuning parameters
    if (Mopt < 0) M = floor(2*(Tlen/100)^(1/5))
    else          M = Mopt
    if (M < 1) M = 1
    if (Jopt < 0) J = floor(12*(Tlen/100)^(1/4))
    else          J = Jopt
    if (J < 1) J = 1
    if (Kopt < 0) K = floor((aa*Tlen)^dd)
    else          K = Kopt
    if (K < 1) K = 1

    neff = Tlen - 2*M - 1
    na = neff - K
    if (na < 1) {
        st_numscalar(st_local("RCFLAG"), 1)
        return
    }

    // per-panel standardized DOLS residuals and bias components
    R     = J(neff, N, 0)
    bcomp = J(N, 1, 0)
    sig2  = J(N, 1, 0)
    INDIV = J(N, 9, 0)

    for (i=1; i<=N; i++) {
        r1 = info[i,1]
        r2 = info[i,2]
        yi = y[|r1 \ r2|]
        xi = X[|r1,1 \ r2,px|]

        res = _hkr_dols(yi, xi, M, trend, Tlen)
        sigma = sqrt(mean(res:^2))
        r = res:/sigma
        R[.,i] = r
        sig2[i] = sigma*sigma
        w2eta = _hkr_lrv(res, J)
        bcomp[i] = w2eta/sig2[i]

        // individual statistic
        Ai = _hkr_avec(r, K)
        Ci = colsum(Ai)/sqrt(na)
        omi = _hkr_lrv(Ai, J)
        bi = ((pc+px)*bcomp[i])/sqrt(na)
        Si = Ci/sqrt(omi)
        Sbci = (Ci+bi)/sqrt(omi)
        pi = 1 - normal(Si)
        pbi = 1 - normal(Sbci)

        INDIV[i,1] = id[r1]
        INDIV[i,2] = Tlen
        INDIV[i,3] = K
        INDIV[i,4] = Si
        INDIV[i,5] = Sbci
        INDIV[i,6] = pi
        INDIV[i,7] = pbi

        // optional OLS-residual comparator (individual)
        if (dools==1) {
            resols = _hkr_ols(yi, xi, trend, Tlen)
            rols = resols:/sqrt(mean(resols:^2))
            // use same K on full-sample residuals
            Aols = _hkr_avec(rols, K)
            Cols = colsum(Aols)/sqrt(rows(rols)-K)
            omols = _hkr_lrv(Aols, J)
            INDIV[i,8] = Cols/sqrt(omols)
            INDIV[i,9] = 1 - normal(INDIV[i,8])
        }
    }

    // pooled panel statistic at the reported K
    pr = _hkr_pool(R, bcomp, K, J, pc, px)

    // pooled OLS comparator
    solsp = .
    polsp = .
    if (dools==1) {
        // rebuild pooled OLS series
        Rp = J(Tlen, N, 0)
        for (i=1; i<=N; i++) {
            r1 = info[i,1]
            r2 = info[i,2]
            yi = y[|r1 \ r2|]
            xi = X[|r1,1 \ r2,px|]
            resols = _hkr_ols(yi, xi, trend, Tlen)
            Rp[.,i] = resols:/sqrt(mean(resols:^2))
        }
        nao = Tlen - K
        Ao = J(nao,1,0)
        for (i=1; i<=N; i++) {
            Ao = Ao + _hkr_avec(Rp[.,i], K)
        }
        Co = colsum(Ao)/sqrt(nao)
        omo = _hkr_lrv(Ao, J)
        solsp = Co/sqrt(omo)
        polsp = 1 - normal(solsp)
    }

    // assemble PANEL row
    PANEL = J(1, 20, 0)
    PANEL[1,1]  = pr[1]        // S
    PANEL[1,2]  = pr[2]        // p
    PANEL[1,3]  = pr[3]        // Sbc
    PANEL[1,4]  = pr[4]        // pbc
    PANEL[1,5]  = solsp        // Sols
    PANEL[1,6]  = polsp        // pols
    PANEL[1,7]  = pr[5]        // Cbar
    PANEL[1,8]  = pr[6]        // omega_a
    PANEL[1,9]  = pr[7]        // bias
    PANEL[1,10] = K
    PANEL[1,11] = M
    PANEL[1,12] = J
    PANEL[1,13] = N
    PANEL[1,14] = Tlen
    PANEL[1,15] = neff
    PANEL[1,16] = na
    PANEL[1,17] = pc
    PANEL[1,18] = px
    PANEL[1,19] = trend
    PANEL[1,20] = dools

    st_matrix(st_local("PANEL"), PANEL)
    st_matrix(st_local("INDIV"), INDIV)

    // K-sensitivity sweep
    if (wantks==1) {
        ksl = tokens(st_local("ksgrid"))
        if (cols(ksl) > 0) {
            KSENS = J(cols(ksl), 5, .)
            for (g=1; g<=cols(ksl); g++) {
                kg = strtoreal(ksl[g])
                if (kg >= 1 & kg < neff) {
                    pr = _hkr_pool(R, bcomp, kg, J, pc, px)
                    KSENS[g,1] = kg
                    KSENS[g,2] = pr[1]
                    KSENS[g,3] = pr[3]
                    KSENS[g,4] = pr[2]
                    KSENS[g,5] = pr[4]
                }
            }
        }
        else {
            // default grid: ~16 points from (0.5T)^.5 up to (3T)^.5
            kmin = floor((0.5*Tlen)^0.5)
            kmax = floor((3*Tlen)^0.5)
            if (kmin < 2) kmin = 2
            if (kmax >= neff) kmax = neff - 1
            if (kmax <= kmin) kmax = kmin + 1
            ng = 16
            KSENS = J(ng, 5, .)
            for (g=1; g<=ng; g++) {
                kg = round(kmin + (kmax-kmin)*(g-1)/(ng-1))
                if (kg < 1) kg = 1
                pr = _hkr_pool(R, bcomp, kg, J, pc, px)
                KSENS[g,1] = kg
                KSENS[g,2] = pr[1]
                KSENS[g,3] = pr[3]
                KSENS[g,4] = pr[2]
                KSENS[g,5] = pr[4]
            }
        }
        st_matrix(st_local("KSENS"), KSENS)
    }

    st_numscalar(st_local("RCFLAG"), 0)
}

end
