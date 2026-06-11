*! xtpgc : Bootstrap panel Granger causality in heterogeneous mixed panels
*!         (Emirmahmutoglu & Kose, 2011 Fisher ; Konya, 2006 SUR-Wald)
*! Part of the -xtpdlib- library : second-generation panel data tests
*! Version 1.0.0  06jun2026
*!
*! Stata translation & implementation : Dr Merwan Roudane
*!   merwanroudane920@gmail.com  |  https://github.com/merwanroudane
*! Based on the GAUSS routines pd_cause / PDcaus_Fisher / PDcaus_SURwald by
*!   Saban Nazlioglu (TSPDLIB), snazlioglu@pau.edu.tr
*!   -- for public non-commercial use only.
*!
*! References:
*!   Emirmahmutoglu, F., Kose, N. (2011). Testing for Granger causality in
*!     heterogeneous mixed panels. Economic Modelling 28: 870-876.
*!     <doi:10.1016/j.econmod.2010.10.018>
*!   Konya, L. (2006). Exports and growth: Granger causality analysis on OECD
*!     countries with a panel data approach. Economic Modelling 23: 978-992.
*!     <doi:10.1016/j.econmod.2006.04.008>
*!   Kar, M., Nazlioglu, S., Agir, H. (2011). Financial development and economic
*!     growth nexus in the MENA countries: bootstrap panel Granger causality
*!     analysis. Economic Modelling 28: 685-693.
*!     <doi:10.1016/j.econmod.2010.05.015>
*!
*! Note: the Dumitrescu-Hurlin (2012) Zbar test is available via -xtgcause-.

program define xtpgc, rclass
    version 14.0

    syntax varlist(min=2) [if] [in] [ ,           ///
            METHod(string)                         ///
            MAXLags(integer 4)                     ///
            DMAX(integer 1)                        ///
            IC(integer 1)                          ///
            Breps(integer 1000)                    ///
            SEED(string)                           ///
            NOBoot                                 ///
            GRaph                                  ///
            noPRINTind                             ///
            * ]

    local gphopts `"`options'"'

    if ("`method'" == "") local method "fisher"
    local method = lower("`method'")
    if !inlist("`method'", "fisher", "konya", "surwald") {
        di as err "option method() must be {bf:fisher} or {bf:konya}"
        exit 198
    }
    if ("`method'"=="surwald") local method "konya"

    if !inlist(`ic', 1, 2) {
        di as err "option ic() must be 1 (AIC) or 2 (SIC)"
        exit 198
    }
    if (`maxlags' < 1) {
        di as err "option maxlags() must be >= 1"
        exit 198
    }
    if (`dmax' < 0) {
        di as err "option dmax() must be >= 0"
        exit 198
    }
    local doboot = cond("`noboot'"=="", 1, 0)
    if ("`seed'" != "") set seed `seed'
    local ictxt = cond(`ic'==1, "Akaike (AIC)", "Schwarz (SIC)")

    * variable list (number of equations)
    local K : word count `varlist'
    if ("`method'"=="konya" & `K' != 2) {
        di as err "method(konya) requires exactly 2 variables"
        exit 198
    }

    * ---------------------------------------------------------------
    * Panel structure (balanced)
    * ---------------------------------------------------------------
    qui xtset
    local id   `r(panelvar)'
    local time `r(timevar)'
    if ("`id'" == "" | "`time'" == "") {
        di as err "data must be {bf:xtset} (panelvar timevar) before using xtpgc"
        exit 459
    }

    marksample touse
    markout `touse' `time' `id' `varlist'

    tempvar cnt
    qui bysort `id' (`time') : gen long `cnt' = sum(`touse')
    qui by `id' : replace `cnt' = `cnt'[_N]
    qui summarize `cnt' if `touse', meanonly
    if (r(min) != r(max)) {
        di as err "xtpgc requires a {bf:balanced} panel"
        exit 459
    }
    qui count if `touse'
    local NT = r(N)
    qui levelsof `id' if `touse', local(idlevels)
    local N : word count `idlevels'
    local T = `NT'/`N'
    if (`T' != int(`T') | `N' < 2 | `T' < `=`maxlags'+`dmax'+6') {
        di as err "panel not balanced or too short for maxlags(`maxlags') dmax(`dmax')"
        exit 459
    }

    * ---------------------------------------------------------------
    * Header
    * ---------------------------------------------------------------
    di ""
    di as txt "{hline 72}"
    if ("`method'"=="fisher") {
        di as txt "  Bootstrap Panel Granger Causality {hline 2} Fisher (Emirmahmutoglu-Kose 2011)"
    }
    else {
        di as txt "  Bootstrap Panel Granger Causality {hline 2} SUR-Wald (Konya 2006)"
    }
    di as txt "{hline 72}"
    di as txt "  Variables     : " as res "`varlist'"
    di as txt "  N , T         : " as res "`N'" as txt " , " as res "`T'"
    di as txt "  Lag selection : " as res "`ictxt'" as txt " (max = `maxlags')"
    if ("`method'"=="fisher") ///
        di as txt "  Extra lags    : " as res "dmax = `dmax'" as txt " (Toda-Yamamoto augmentation)"
    if (`doboot') ///
        di as txt "  Bootstrap     : " as res "`breps' replications" ///
            as txt cond("`seed'"!="", "  (seed `seed')", "")
    else ///
        di as txt "  Bootstrap     : " as res "off" as txt " (asymptotic results only)"
    di as txt "{hline 72}"

    * ---------------------------------------------------------------
    * Engine + display
    * ---------------------------------------------------------------
    if ("`method'"=="fisher") {
        qui mata: xtpgc_fisher("`varlist'", "`touse'", "`id'", `N', `T', `K', ///
            `maxlags', `dmax', `ic', `doboot', `breps')
        tempname PAIRS UNITS
        matrix `PAIRS' = xtg_pairs
        matrix `UNITS' = xtg_units
        matrix drop xtg_pairs xtg_units

        local np = rowsof(`PAIRS')
        forvalues pr = 1/`np' {
            local e  = `PAIRS'[`pr',1]
            local c  = `PAIRS'[`pr',2]
            local ev : word `e' of `varlist'
            local cv : word `c' of `varlist'
            di ""
            di as txt "  H0: " as res "`cv'" as txt " does not Granger-cause " as res "`ev'"
            di as txt "  {hline 56}"
            if ("`printind'"=="") {
                di as txt "  " %6s "id" %8s "lag" %14s "Wald" %12s "p-value"
                di as txt "  {hline 56}"
                forvalues r = 1/`=`N'' {
                    local rr = (`pr'-1)*`N' + `r'
                    di as res "  " %6.0g `UNITS'[`rr',2] %8.0f `UNITS'[`rr',3] ///
                        %14.3f `UNITS'[`rr',4] %12.3f `UNITS'[`rr',5]
                }
                di as txt "  {hline 56}"
            }
            local fish  = `PAIRS'[`pr',3]
            local fpv   = `PAIRS'[`pr',4]
            local df2   = 2*`N'
            di as txt "  " %-22s "Fisher statistic" as res %12.3f `fish' ///
                as txt "   asy. p-value [chi2(`df2')]: " as res %6.3f `fpv'
            if (`doboot') {
                di as txt "  " %-22s "Bootstrap crit. val." ///
                    as txt "  1%=" as res %8.3f `PAIRS'[`pr',7] ///
                    as txt "  5%=" as res %8.3f `PAIRS'[`pr',6] ///
                    as txt "  10%=" as res %8.3f `PAIRS'[`pr',5]
                local bdec = cond(`fish' > `PAIRS'[`pr',6], "reject H0 at 5%", "do not reject at 5%")
                di as txt "  Decision (bootstrap 5%): " as res "`bdec'"
            }
            else {
                local adec = cond(`fpv' < 0.05, "reject H0 at 5%", "do not reject at 5%")
                di as txt "  Decision (asymptotic 5%): " as res "`adec'"
            }
        }
        di as txt "{hline 72}"

        if ("`graph'"!="") _xtpgc_graph_fisher, matname(`PAIRS') vars(`varlist') ///
            boot(`doboot') `gphopts'
        return matrix pairs   = `PAIRS'
        return matrix units   = `UNITS'
    }
    else {
        qui mata: xtpgc_konya("`varlist'", "`touse'", "`id'", `N', `T', ///
            `maxlags', `ic', `doboot', `breps')
        tempname PAIRS UNITS
        matrix `PAIRS' = xtg_pairs
        matrix `UNITS' = xtg_units
        matrix drop xtg_pairs xtg_units

        local np = rowsof(`PAIRS')
        forvalues pr = 1/`np' {
            local e  = `PAIRS'[`pr',1]
            local c  = `PAIRS'[`pr',2]
            local ev : word `e' of `varlist'
            local cv : word `c' of `varlist'
            di ""
            di as txt "  H0: " as res "`cv'" as txt " does not Granger-cause " as res "`ev'"
            di as txt "  {hline 60}"
            di as txt "  " %6s "id" %12s "Wald" %12s "1% CV" %12s "5% CV" %12s "10% CV"
            di as txt "  {hline 60}"
            forvalues r = 1/`=`N'' {
                local rr = (`pr'-1)*`N' + `r'
                local sig = cond(`UNITS'[`rr',3] > `UNITS'[`rr',5], "*", " ")
                di as res "  " %6.0g `UNITS'[`rr',2] %12.3f `UNITS'[`rr',3] ///
                    %12.3f `UNITS'[`rr',4] %12.3f `UNITS'[`rr',5] %12.3f `UNITS'[`rr',6] ///
                    as txt " `sig'"
            }
            di as txt "  {hline 60}"
            di as txt "  '*' = reject non-causality at 5% (Wald > bootstrap 5% CV)."
        }
        di as txt "{hline 72}"

        if ("`graph'"!="") _xtpgc_graph_konya, matname(`UNITS') pairs(`PAIRS') ///
            vars(`varlist') n(`N') `gphopts'
        return matrix pairs   = `PAIRS'
        return matrix units   = `UNITS'
    }

    return scalar N      = `N'
    return scalar T      = `T'
    return local  method "`method'"
    return local  cmd    "xtpgc"
end


* -------------------------------------------------------------------
* Graphs
* -------------------------------------------------------------------
program define _xtpgc_graph_fisher
    version 14.0
    syntax , matname(string) vars(string) boot(real) [ * ]
    preserve
    clear
    tempname G
    matrix `G' = `matname'
    qui svmat double `G', names(c)
    local nd = _N
    qui gen seq = _n
    capture label drop _xtpgcdir
    forvalues r = 1/`nd' {
        local e = c1[`r']
        local c = c2[`r']
        local ev : word `e' of `vars'
        local cv : word `c' of `vars'
        label define _xtpgcdir `r' "`cv' -> `ev'", add
    }
    label values seq _xtpgcdir
    if (`boot') {
        twoway (bar c3 seq, barwidth(0.6) color("70 110 180"))            ///
               (scatter c6 seq, msymbol(D) mcolor("200 0 0")) ,           ///
            xlabel(1/`nd', valuelabel angle(45) labsize(vsmall) noticks)  ///
            legend(order(1 "Fisher" 2 "Bootstrap 5% CV")                  ///
                   size(vsmall) rows(1))                                   ///
            ytitle("Fisher statistic") xtitle("")                         ///
            title("Panel Fisher causality by direction", size(medsmall))  ///
            note("bar above marker => reject non-causality at 5%", size(vsmall)) ///
            `options'
    }
    else {
        twoway (bar c3 seq, barwidth(0.6) color("70 110 180")) ,          ///
            xlabel(1/`nd', valuelabel angle(45) labsize(vsmall) noticks)  ///
            ytitle("Fisher statistic") xtitle("")                         ///
            title("Panel Fisher causality by direction", size(medsmall))  ///
            `options'
    }
    restore
end

program define _xtpgc_graph_konya
    version 14.0
    syntax , matname(string) pairs(string) vars(string) n(integer) [ * ]
    preserve
    clear
    tempname G P
    matrix `G' = `matname'
    matrix `P' = `pairs'
    qui svmat double `G', names(c)
    rename c1 pair
    rename c2 id
    rename c3 wald
    rename c5 cv5
    capture label drop _xtpgckdir
    forvalues r = 1/`=rowsof(`P')' {
        local e = `P'[`r',1]
        local c = `P'[`r',2]
        local ev : word `e' of `vars'
        local cv : word `c' of `vars'
        label define _xtpgckdir `r' "`cv' -> `ev'", add
    }
    label values pair _xtpgckdir
    qui gen byte rej = wald > cv5 & !missing(cv5)
    twoway (bar wald id if rej==0, color("130 160 200"))      ///
           (bar wald id if rej==1, color("200 60 60"))        ///
           (line cv5 id, sort lpattern(dash) lcolor(black)) , ///
           by(pair, note("") legend(off)                      ///
                title("Konya country-specific Wald vs 5% bootstrap CV", size(medsmall))) ///
           ytitle("Wald") xtitle("Cross-section (id)")        ///
           `options'
    restore
end


* ===================================================================
* MATA ENGINE
* ===================================================================
mata:

// ---- shared helpers --------------------------------------------------

// design matrix [const, lag1(allvars), ..., lagq(allvars)] ; n x (1+K*q)
real matrix xtpgc_design(real matrix yi, real scalar q)
{
    real scalar T, K, n, L
    real matrix X
    T = rows(yi); K = cols(yi); n = T - q
    X = J(n, 1 + K*q, 0)
    X[., 1] = J(n, 1, 1)
    for (L = 1; L <= q; L++)
        X[., (2+(L-1)*K)..(1+L*K)] = yi[(q+1-L)..(T-L), .]
    return(X)
}

// VAR lag selection by AIC(1)/SIC(2)
real scalar xtpgc_lagsel(real matrix yi, real scalar pmax, real scalar ic)
{
    real scalar T, K, p, n, best, val, bestp, ld
    real matrix X, Y, B, U, Sig
    T = rows(yi); K = cols(yi)
    best = .; bestp = 1
    for (p = 1; p <= pmax; p++) {
        n = T - p
        X = xtpgc_design(yi, p)
        Y = yi[(p+1)..T, .]
        B = invsym(quadcross(X,X))*quadcross(X,Y)
        U = Y - X*B
        Sig = quadcross(U,U)/n
        ld  = ln(det(Sig))
        if (ic == 1) val = ld + 2*(K*K*p)/n
        else         val = ld + (K*K*p)*ln(n)/n
        if (val < best) {
            best = val
            bestp = p
        }
    }
    return(bestp)
}

// single-equation Wald for restriction R*b=0, given precomputed (X'X)^-1
real scalar xtpgc_waldx(real colvector dep, real matrix X, real matrix xxi,
                        real matrix R)
{
    real scalar n, kk, s2, W
    real colvector b, u, rb
    n = rows(X); kk = cols(X)
    b  = xxi*quadcross(X,dep)
    u  = dep - X*b
    s2 = quadcross(u,u)/(n - kk)
    rb = R*b
    W  = (rb' * invsym(R*(s2*xxi)*R') * rb)
    return(W)
}

// restriction matrix selecting cause c at lags 1..p in design [const,lagblocks]
real matrix xtpgc_Rmat(real scalar K, real scalar q, real scalar c, real scalar p)
{
    real scalar L, ncol
    real matrix R
    ncol = 1 + K*q
    R = J(p, ncol, 0)
    for (L = 1; L <= p; L++) R[L, 1 + (L-1)*K + c] = 1
    return(R)
}

// ---- Emirmahmutoglu & Kose (2011) Fisher ----------------------------
void xtpgc_fisher(string scalar yvars, string scalar tousev, string scalar idv,
                  real scalar N, real scalar T, real scalar K,
                  real scalar pmax, real scalar dmax, real scalar ic,
                  real scalar doboot, real scalar breps)
{
    real matrix Yall, yi, X, Xr, R, PAIRS, UNITS, NeH0, NzH0, Fb, xxi
    real colvector idvals, dep, br, ur, yhat0, keep, Npval, Nwald, Nlag
    real colvector qv, pv, ord, pvb, ystar
    real scalar np, e, c, i, p, q, n, W, fisher, asy, pr, kk, b2
    transmorphic Adx, Axi

    Yall   = st_data(., tokens(yvars), tousev)
    idvals = (colshape(st_data(., idv, tousev), T))[., 1]

    np = K*(K-1)
    PAIRS = J(np, 7, .)
    UNITS = J(np*N, 5, .)

    pr = 0
    for (e = 1; e <= K; e++) {
        for (c = 1; c <= K; c++) {
            if (c == e) continue
            pr++
            Npval = J(N,1,.); Nwald = J(N,1,.); Nlag = J(N,1,.)
            NeH0 = J(T, N, 0); NzH0 = J(T, N, 0)
            qv = J(N,1,.); pv = J(N,1,.)
            Adx = asarray_create("real", 1)
            Axi = asarray_create("real", 1)

            for (i = 1; i <= N; i++) {
                yi  = Yall[((i-1)*T+1)..(i*T), .]
                p   = xtpgc_lagsel(yi, pmax, ic)
                q   = p + dmax
                n   = T - q
                X   = xtpgc_design(yi, q)
                xxi = invsym(quadcross(X,X))
                dep = yi[(q+1)..T, e]
                R   = xtpgc_Rmat(K, q, c, p)
                W   = xtpgc_waldx(dep, X, xxi, R)
                Nwald[i] = W
                Npval[i] = chi2tail(p, W)
                Nlag[i]  = p

                // restricted (null) model : drop cause c lags 1..p
                keep = J(cols(X),1,1)
                for (kk = 1; kk <= p; kk++) keep[1 + (kk-1)*K + c] = 0
                Xr     = select(X, keep')
                br     = invsym(quadcross(Xr,Xr))*quadcross(Xr,dep)
                ur     = dep - Xr*br
                ur     = ur :- mean(ur)
                yhat0  = Xr*br
                NeH0[(q+1)..T, i] = ur
                NzH0[(q+1)..T, i] = yhat0

                asarray(Adx, i, X)
                asarray(Axi, i, xxi)
                qv[i] = q; pv[i] = p
            }

            fisher = -2*sum(ln(Npval))
            asy    = chi2tail(2*N, fisher)

            for (i = 1; i <= N; i++)
                UNITS[(pr-1)*N + i, .] = (pr, idvals[i], Nlag[i], Nwald[i], Npval[i])
            PAIRS[pr, 1] = e; PAIRS[pr, 2] = c
            PAIRS[pr, 3] = fisher; PAIRS[pr, 4] = asy

            // fixed-design bootstrap with cross-section dependence
            if (doboot) {
                Fb = J(breps, 1, .)
                for (b2 = 1; b2 <= breps; b2++) {
                    ord = ceil(runiform(T,1):*T)
                    pvb = J(N,1,.)
                    for (i = 1; i <= N; i++) {
                        q   = qv[i]; p = pv[i]
                        X   = asarray(Adx, i)
                        xxi = asarray(Axi, i)
                        ystar = NzH0[.,i] + NeH0[ord, i]
                        ystar = ystar[(q+1)..T]
                        R   = xtpgc_Rmat(K, q, c, p)
                        pvb[i] = chi2tail(p, xtpgc_waldx(ystar, X, xxi, R))
                    }
                    Fb[b2] = -2*sum(ln(pvb))
                }
                Fb = sort(Fb, 1)
                PAIRS[pr, 5] = Fb[ceil(breps*0.90)]
                PAIRS[pr, 6] = Fb[ceil(breps*0.95)]
                PAIRS[pr, 7] = Fb[ceil(breps*0.99)]
            }
        }
    }

    st_matrix("xtg_pairs", PAIRS)
    st_matrix("xtg_units", UNITS)
}

// ---- Konya (2006) SUR-Wald ------------------------------------------
void xtpgc_konya(string scalar yvars, string scalar tousev, string scalar idv,
                 real scalar N, real scalar T, real scalar pmax, real scalar ic,
                 real scalar doboot, real scalar breps)
{
    real matrix Yall, PAIRS, UNITS, Ye, Yc, CVb
    real colvector idvals, wald
    real scalar np, e, c, pr, i, p

    Yall   = st_data(., tokens(yvars), tousev)
    idvals = (colshape(st_data(., idv, tousev), T))[., 1]

    np = 2
    PAIRS = J(np, 2, .)
    UNITS = J(np*N, 6, .)

    pr = 0
    for (e = 1; e <= 2; e++) {
        c = 3 - e
        pr++
        // build per-unit T x 2 = (effect, cause)
        Ye = J(T, N, .); Yc = J(T, N, .)
        for (i = 1; i <= N; i++) {
            Ye[., i] = Yall[((i-1)*T+1)..(i*T), e]
            Yc[., i] = Yall[((i-1)*T+1)..(i*T), c]
        }
        // lag selection (common p)
        p = xtpgc_konya_lag(Ye, Yc, N, T, pmax, ic)
        xtpgc_konya_fit(Ye, Yc, N, T, p, doboot, breps, wald=., CVb=.)

        PAIRS[pr,1] = e; PAIRS[pr,2] = c
        for (i = 1; i <= N; i++) {
            if (doboot)
                UNITS[(pr-1)*N+i, .] = (pr, idvals[i], wald[i], CVb[i,1], CVb[i,2], CVb[i,3])
            else
                UNITS[(pr-1)*N+i, .] = (pr, idvals[i], wald[i], ., ., .)
        }
    }
    st_matrix("xtg_pairs", PAIRS)
    st_matrix("xtg_units", UNITS)
}

// build per-unit SUR design and return effect-eq Wald (cause lags = 0) for all units
// arrangement per unit : [const, eff lags 1..p, cause lags 1..p] -> k = 1+2p
void xtpgc_konya_fit(real matrix Ye, real matrix Yc, real scalar N, real scalar T,
                     real scalar p, real scalar doboot, real scalar breps,
                     real colvector wald, real matrix CVb)
{
    real scalar n, k, i, L, j, b2
    real matrix X, Xr, e, eb, cove, coveb, IT, xx, covb, covbb, R, Wb, NeH0, NzH0, invO
    real colvector y, bsur, bsurb, bi, br, ur, yi, rb, ord, ystk, wi
    transmorphic Adx

    n = T - p
    k = 1 + 2*p
    IT = I(n)

    // stacked dependent and block design
    y   = J(N*n, 1, .)
    xx  = J(N*n, N*k, 0)
    e   = J(n, N, .)
    Adx = asarray_create("real", 1)
    for (i = 1; i <= N; i++) {
        X = J(n, k, 1)
        for (L = 1; L <= p; L++) {
            X[., 1+L]   = Ye[(p+1-L)..(T-L), i]
            X[., 1+p+L] = Yc[(p+1-L)..(T-L), i]
        }
        yi = Ye[(p+1)..T, i]
        y[((i-1)*n+1)..(i*n)] = yi
        xx[((i-1)*n+1)..(i*n), ((i-1)*k+1)..(i*k)] = X
        bi = invsym(quadcross(X,X))*quadcross(X,yi)
        e[., i] = yi - X*bi
        asarray(Adx, i, X)
    }
    cove = quadcross(e,e)/n
    invO = invsym(cove) # IT
    covb = invsym(xx' * invO * xx)
    bsur = covb * (xx' * (invO * y))

    // per-unit Wald : cause coefficients (last p in each unit block) = 0
    wald = J(N, 1, .)
    for (i = 1; i <= N; i++) {
        R = J(p, N*k, 0)
        for (j = 1; j <= p; j++) R[j, (i-1)*k + 1 + p + j] = 1
        rb = R*bsur
        wald[i] = (rb' * invsym(R*covb*R') * rb)
    }

    if (!doboot) {
        CVb = J(N,3,.)
        return
    }

    // fixed-design bootstrap : regenerate effect under null (no cause), joint resample
    NeH0 = J(n, N, .); NzH0 = J(n, N, .)
    for (i = 1; i <= N; i++) {
        X  = asarray(Adx, i)
        Xr = X[., 1..(1+p)]                       // const + own lags (null)
        br = invsym(quadcross(Xr,Xr))*quadcross(Xr, Ye[(p+1)..T,i])
        ur = Ye[(p+1)..T,i] - Xr*br
        ur = ur :- mean(ur)
        NeH0[., i] = ur
        NzH0[., i] = Xr*br
    }

    Wb = J(breps, N, .)
    for (b2 = 1; b2 <= breps; b2++) {
        ord  = ceil(runiform(n,1):*n)
        ystk = J(N*n, 1, .)
        for (i = 1; i <= N; i++)
            ystk[((i-1)*n+1)..(i*n)] = NzH0[.,i] + NeH0[ord, i]
        // re-estimate SUR with original design, new dependent
        eb = J(n, N, .)
        for (i = 1; i <= N; i++) {
            X = asarray(Adx, i)
            bi = invsym(quadcross(X,X))*quadcross(X, ystk[((i-1)*n+1)..(i*n)])
            eb[., i] = ystk[((i-1)*n+1)..(i*n)] - X*bi
        }
        coveb = quadcross(eb,eb)/n
        invO  = invsym(coveb) # IT
        covbb = invsym(xx' * invO * xx)
        bsurb = covbb * (xx' * (invO * ystk))
        for (i = 1; i <= N; i++) {
            R = J(p, N*k, 0)
            for (j = 1; j <= p; j++) R[j, (i-1)*k + 1 + p + j] = 1
            rb = R*bsurb
            Wb[b2, i] = (rb' * invsym(R*covbb*R') * rb)
        }
    }
    CVb = J(N, 3, .)
    for (i = 1; i <= N; i++) {
        wi = sort(Wb[., i], 1)
        CVb[i,1] = wi[ceil(breps*0.99)]      // 1%
        CVb[i,2] = wi[ceil(breps*0.95)]      // 5%
        CVb[i,3] = wi[ceil(breps*0.90)]      // 10%
    }
}

real scalar xtpgc_konya_lag(real matrix Ye, real matrix Yc, real scalar N,
                            real scalar T, real scalar pmax, real scalar ic)
{
    real scalar p, n, k, i, L, best, val, bestp, ld
    real matrix X, e, cove
    real colvector yi, bi
    best = .; bestp = 1
    for (p = 1; p <= pmax; p++) {
        n = T - p; k = 1 + 2*p
        e = J(n, N, .)
        for (i = 1; i <= N; i++) {
            X = J(n, k, 1)
            for (L = 1; L <= p; L++) {
                X[., 1+L]   = Ye[(p+1-L)..(T-L), i]
                X[., 1+p+L] = Yc[(p+1-L)..(T-L), i]
            }
            yi = Ye[(p+1)..T, i]
            bi = invsym(quadcross(X,X))*quadcross(X,yi)
            e[., i] = yi - X*bi
        }
        cove = quadcross(e,e)/n
        ld   = ln(det(cove))
        if (ic == 1) val = ld + 2*(N*k*p)/T
        else         val = ld + (N*k*p)*ln(T)/T
        if (val < best) {
            best = val
            bestp = p
        }
    }
    return(bestp)
}
end
