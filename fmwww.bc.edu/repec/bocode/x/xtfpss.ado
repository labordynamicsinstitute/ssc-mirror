*! xtfpss : Fourier Panel Stationarity test (Nazlioglu & Karul, 2017)
*! Part of the -xtpdlib- library : second-generation panel data tests
*! Version 1.0.0  06jun2026
*!
*! Stata translation & implementation : Dr Merwan Roudane
*!   merwanroudane920@gmail.com  |  https://github.com/merwanroudane
*! Based on the GAUSS routine PD_nkarul (proc PDfzk) by Saban Nazlioglu
*!   (TSPDLIB), snazlioglu@pau.edu.tr  -- for public non-commercial use only.
*!
*! Reference:
*!   Nazlioglu, S., Karul, C. (2017). The panel stationarity test with gradual
*!   shifts: an application to international commodity price shocks.
*!   Economic Modelling 61, 181-192.  <doi:10.1016/j.econmod.2016.12.003>

program define xtfpss, rclass
    version 14.0

    syntax varname [if] [in] [ ,                ///
            MODel(string)                        ///
            Freq(integer 1)                      ///
            OPTfreq                              ///
            Fmax(integer 5)                      ///
            VARm(integer 1)                      ///
            GRaph                                ///
            GENfourier(name)                     ///
            noPRINTind                           ///
            * ]

    local gphopts `"`options'"'

    * ---------------------------------------------------------------
    * Deterministic model : level (1) or trend (2)
    * ---------------------------------------------------------------
    if ("`model'" == "") local model "level"
    local model = lower("`model'")
    if !inlist("`model'", "level", "trend") {
        di as err "option model() must be {bf:level} or {bf:trend}"
        exit 198
    }
    local modeln = cond("`model'"=="level", 1, 2)
    local modtxt = cond("`model'"=="level", "Level shift (constant)", ///
                                            "Level & trend shift (constant + trend)")

    * ---------------------------------------------------------------
    * Frequency / long-run variance validation
    * ---------------------------------------------------------------
    if (`freq' < 1 | `freq' > 5) {
        di as err "option freq() : Fourier frequency must be an integer in 1..5"
        exit 198
    }
    if ("`optfreq'" != "" & (`fmax' < 1 | `fmax' > 5)) {
        di as err "option fmax() : maximum frequency must be an integer in 1..5"
        exit 198
    }
    if (`varm' < 1 | `varm' > 7) {
        di as err "option varm() : long-run variance method must be in 1..7"
        exit 198
    }
    local optf = cond("`optfreq'"=="", 0, 1)
    local lrvtxt : word `varm' of ///
        "iid" "Bartlett" "Quadratic_Spectral" "SPC-Bartlett" "SPC-QS" ///
        "Kurozumi-Bartlett" "Kurozumi-QS"
    local lrvtxt : subinstr local lrvtxt "_" " ", all

    * ---------------------------------------------------------------
    * Panel structure
    * ---------------------------------------------------------------
    qui xtset
    local id   `r(panelvar)'
    local time `r(timevar)'
    if ("`id'" == "" | "`time'" == "") {
        di as err "data must be {bf:xtset} (panelvar timevar) before using xtfpss"
        exit 459
    }

    marksample touse
    markout `touse' `time' `id'

    * balanced-panel check
    tempvar cnt
    qui bysort `id' (`time') : gen long `cnt' = sum(`touse')
    qui by `id' : replace `cnt' = `cnt'[_N]
    qui summarize `cnt' if `touse', meanonly
    local Tmin = r(min)
    local Tmax = r(max)
    if (`Tmin' != `Tmax') {
        di as err "xtfpss requires a {bf:balanced} panel (each unit must have the same T)"
        exit 459
    }
    qui count if `touse'
    local NT = r(N)
    qui levelsof `id' if `touse', local(idlevels)
    local N : word count `idlevels'
    local T = `NT'/`N'
    if (`T' != int(`T') | `N' < 2 | `T' < 5) {
        di as err "panel is not balanced or too small (need N>=2, T>=5)"
        exit 459
    }

    * ---------------------------------------------------------------
    * Generated Fourier-approximation variable (for graphing)
    * ---------------------------------------------------------------
    if ("`genfourier'" != "") {
        confirm new variable `genfourier'
        qui gen double `genfourier' = .
        local fitvar `genfourier'
    }
    else if ("`graph'" != "") {
        tempvar fitvar
        qui gen double `fitvar' = .
    }
    else local fitvar ""

    * ---------------------------------------------------------------
    * Mata engine (functions are compiled by the trailing mata block)
    * ---------------------------------------------------------------
    qui mata: xtfpss_calc("`varlist'", "`touse'", `modeln', `freq', `optf', ///
        `fmax', `varm', "`fitvar'", "`id'", `N', `T')

    local k        = `xtf_k'
    local fzk      = `xtf_fzk'
    local pval     = `xtf_pval'
    local fpk      = `xtf_fpk'
    tempname KPSS
    matrix `KPSS'  = xtf_kpss
    matrix drop    xtf_kpss
    local freqnote = cond(`optf', "  (selected by minimum SSR, 1..`fmax')", "")

    * ---------------------------------------------------------------
    * Output : journal-style table
    * ---------------------------------------------------------------
    di ""
    di as txt "{hline 64}"
    di as txt "  Fourier Panel Stationarity Test" _col(48) "(FZk)"
    di as txt "  Nazlioglu & Karul (2017), Economic Modelling 61, 181-192"
    di as txt "{hline 64}"
    di as txt "  H0: " as res "the panel is stationary" as txt " (all units stationary)"
    di as txt "  Ha: " as res "some/all units contain a unit root"
    di as txt "  Variable        : " as res "`varlist'"
    di as txt "  Deterministic   : " as res "`modtxt'"
    di as txt "  Fourier freq (k): " as res "`k'" as txt "`freqnote'"
    di as txt "  Long-run var.   : " as res "`lrvtxt'"
    di as txt "  N , T           : " as res "`N'" as txt " , " as res "`T'"
    di as txt "{hline 64}"

    if ("`printind'" == "") {
        di as txt "  Individual KPSS statistics (with common factor)"
        di as txt "  {hline 30}"
        di as txt "  " %12s "Unit (id)" "  " %14s "FKPSS"
        di as txt "  {hline 30}"
        local nr = rowsof(`KPSS')
        forvalues r = 1/`nr' {
            local idv = `KPSS'[`r',1]
            local st  = `KPSS'[`r',2]
            di as res "  " %12.0g `idv' "  " %14.4f `st'
        }
        di as txt "  {hline 30}"
        di ""
    }

    di as txt "  Panel test statistic"
    di as txt "  {hline 46}"
    di as txt "  " %-16s "FZk statistic" %14s "p-value" %14s "Decision (5%)"
    di as txt "  {hline 46}"
    local dec = cond(`pval' < 0.05, "reject H0", "do not reject")
    di as res "  " %-16.4f `fzk' %14.4f `pval' %14s "`dec'"
    di as txt "  {hline 46}"
    di as txt "  FZk ~ N(0,1) under H0; one-sided 5% critical value = 1.645."
    if (`pval' < 0.05) ///
        di as txt "  => Joint stationarity is rejected: unit root(s) present in the panel."
    else ///
        di as txt "  => Joint stationarity cannot be rejected: the panel is stationary."
    di as txt "{hline 64}"

    * ---------------------------------------------------------------
    * Graph : Fig.1-style series + Fourier approximation (small multiples)
    * ---------------------------------------------------------------
    if ("`graph'" != "") {
        xtfpss_graph `varlist' `fitvar' if `touse', id(`id') time(`time') ///
            model(`model') k(`k') `gphopts'
    }

    * ---------------------------------------------------------------
    * Returns
    * ---------------------------------------------------------------
    return scalar fzk   = `fzk'
    return scalar pval  = `pval'
    return scalar fpk   = `fpk'
    return scalar k     = `k'
    return scalar N     = `N'
    return scalar T     = `T'
    return scalar varm  = `varm'
    return scalar model = `modeln'
    return matrix kpss  = `KPSS'
    return local  lrv   "`lrvtxt'"
    return local  cmd   "xtfpss"
end

* -------------------------------------------------------------------
* Graphing helper : replicate Fig.1 of Nazlioglu & Karul (2017)
* -------------------------------------------------------------------
program define xtfpss_graph
    version 14.0
    syntax varlist(min=2 max=2) [if] [in] , id(varname) time(varname) ///
        [ model(string) k(string) * ]

    gettoken y rest : varlist
    local fit : word 2 of `varlist'

    local ttl "Series and Fourier approximation (k=`k')"
    twoway (line `y'   `time', lcolor("0 0 200") lwidth(thin))               ///
           (line `fit' `time', lcolor("200 0 0") lwidth(medthick))           ///
           `if' `in' ,                                                       ///
           by(`id', legend(off) compact title("`ttl'", size(medsmall))      ///
              note("blue = `y'      red = Fourier approximation", size(vsmall))) ///
           ytitle("") xtitle("")                                            ///
           ylabel(, labsize(vsmall) angle(horizontal)) xlabel(, labsize(vsmall)) ///
           `options'
end

* ===================================================================
* MATA ENGINE
* ===================================================================
mata:

real scalar xtfpss_lrv(real colvector e, real scalar varm)
{
    real scalar T, l, g0, lrv, j, w, x, rho, c, cval, Tu, gu0, isqs, prew
    real colvector u

    T  = rows(e)
    g0 = quadcross(e, e)/T
    if (varm == 1) return(g0)              // iid

    // AR(1) coefficient of residuals (data-dependent bandwidth / prewhitening)
    rho = quadcross(e[1..T-1], e[2..T]) / quadcross(e[1..T-1], e[1..T-1])

    prew = (varm == 4 | varm == 5)         // SPC prewhitening
    if (prew) u = e[2..T] - rho*e[1..T-1]
    else      u = e

    Tu  = rows(u)
    gu0 = quadcross(u, u)/Tu

    // bandwidth
    if (varm == 2 | varm == 3 | varm == 4 | varm == 5) {
        l = round(4*(Tu/100)^(2/9))
    }
    else if (varm == 6) {                  // Kurozumi (2002), Bartlett
        c = 0.7
        l = min((1.1447*((4*rho^2*T)/((1+rho)^2*(1-rho)^2))^(1/3), 1.1447*((4*c^2*T)/((1+c)^2*(1-c)^2))^(1/3)))
    }
    else {                                  // varm==7 : Kurozumi QS
        c = 0.7
        l = min((1.3221*((4*rho^2*T)/((1-rho)^4))^(1/5), 1.3221*((4*c^2*T)/((1-c)^4))^(1/5)))
    }
    if (l < 1) l = 1

    isqs = (varm == 3 | varm == 5 | varm == 7)
    lrv  = gu0
    if (!isqs) {                           // Bartlett kernel
        for (j = 1; j <= l & j <= Tu-1; j++) {
            w   = 1 - j/(l+1)
            lrv = lrv + 2*w*(quadcross(u[1..Tu-j], u[(j+1)..Tu])/Tu)
        }
    }
    else {                                 // Quadratic Spectral kernel
        for (j = 1; j <= Tu-1; j++) {
            x   = j/l
            w   = 25/(12*pi()^2*x^2) * (sin(6*pi()*x/5)/(6*pi()*x/5) - cos(6*pi()*x/5))
            lrv = lrv + 2*w*(quadcross(u[1..Tu-j], u[(j+1)..Tu])/Tu)
        }
    }

    if (prew) {                            // recolor + SPC boundary rule
        lrv  = lrv/((1-rho)^2)
        cval = g0*T
        if (lrv > cval) lrv = cval
    }
    if (lrv <= 0) lrv = g0
    return(lrv)
}

void xtfpss_moments(real scalar modeln, real scalar k,
                    real scalar mu, real scalar vr)
{
    // Asymptotic moments, Table 1 of Nazlioglu & Karul (2017)
    real rowvector muL, vL, muT, vT
    muL = (0.0658, 0.1410, 0.1550, 0.1600, 0.1630)
    vL  = (0.0029, 0.0176, 0.0202, 0.0214, 0.0219)
    muT = (0.0295, 0.0523, 0.0601, 0.0633, 0.0642)
    vT  = (0.00017, 0.00150, 0.00169, 0.00180, 0.00179)
    if (modeln == 1) {
        mu = muL[k]
        vr = vL[k]
    }
    else {
        mu = muT[k]
        vr = vT[k]
    }
}

void xtfpss_calc(string scalar yv, string scalar tousev,
                 real scalar modeln, real scalar kfix, real scalar optf,
                 real scalar fmax, real scalar varm, string scalar genv,
                 string scalar idv, real scalar N, real scalar T)
{
    real colvector y, ft, trend, yi, sink, cosk, e1, S, b, bd, kpss, idvals
    real matrix    ymat, Z, Zd, fitmat
    real scalar    i, k, kbest, sse, ssebest, mu, vr, fpk, fzk, pval, kmax

    y     = st_data(., yv, tousev)
    ymat  = (colshape(y, T))'               // T x N , column i = unit i
    trend = (1::T)
    ft    = rowsum(ymat) :/ N               // common factor estimate

    // frequency selection (minimum panel SSR) or fixed
    if (optf) {
        kmax = min((fmax, 5))
        ssebest = .
        kbest   = 1
        for (k = 1; k <= kmax; k++) {
            sse = 0
            sink = sin(2*pi()*k*trend/T)
            cosk = cos(2*pi()*k*trend/T)
            for (i = 1; i <= N; i++) {
                yi = ymat[., i]
                if (modeln == 1) Z = (J(T,1,1), sink, cosk, ft)
                else             Z = (J(T,1,1), trend, sink, cosk, ft)
                b   = invsym(quadcross(Z,Z))*quadcross(Z,yi)
                e1  = yi - Z*b
                sse = sse + quadcross(e1,e1)
            }
            if (sse < ssebest) {
                ssebest = sse
                kbest = k
            }
        }
        k = kbest
    }
    else k = kfix

    // individual statistics + Fourier fit
    kpss   = J(N, 1, .)
    fitmat = J(T, N, .)
    sink   = sin(2*pi()*k*trend/T)
    cosk   = cos(2*pi()*k*trend/T)
    for (i = 1; i <= N; i++) {
        yi = ymat[., i]
        if (modeln == 1) {
            Z  = (J(T,1,1), sink, cosk, ft)
            Zd = (J(T,1,1), sink, cosk)
        }
        else {
            Z  = (J(T,1,1), trend, sink, cosk, ft)
            Zd = (J(T,1,1), trend, sink, cosk)
        }
        b       = invsym(quadcross(Z,Z))*quadcross(Z,yi)
        e1      = yi - Z*b
        S       = runningsum(e1)
        kpss[i] = quadsum(S:^2)/(T^2 * xtfpss_lrv(e1, varm))
        bd          = invsym(quadcross(Zd,Zd))*quadcross(Zd,yi)
        fitmat[.,i] = Zd*bd
    }

    xtfpss_moments(modeln, k, mu=., vr=.)
    fpk  = mean(kpss)
    fzk  = sqrt(N)*(fpk - mu)/sqrt(vr)
    pval = 1 - normal(fzk)

    // id labels
    idvals = (colshape(st_data(., idv, tousev), T))[., 1]

    // store Fourier fit for graphing
    if (genv != "") {
        real matrix V
        st_view(V=., ., genv, tousev)
        V[.,1] = vec(fitmat)
    }

    // returns (passed back via locals / a plain matrix)
    st_local("xtf_k",    strofreal(k))
    st_local("xtf_fzk",  strofreal(fzk,  "%18.0g"))
    st_local("xtf_pval", strofreal(pval, "%18.0g"))
    st_local("xtf_fpk",  strofreal(fpk,  "%18.0g"))
    st_matrix("xtf_kpss", (idvals, kpss))
    st_matrixcolstripe("xtf_kpss", (J(2,1,""), ("id" \ "FKPSS")))
}
end
