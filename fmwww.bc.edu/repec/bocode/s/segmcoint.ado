*! segmcoint 0.1.0  24jul2026
*! Tests for segmented cointegration: Kim (2003), Davidson-Monticini (2010),
*! Martins-Rodrigues (2021), in one command.
*! Author: Dr Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub: https://github.com/merwanroudane
*
* Step -> equation map (abbreviated; full map in COMPAT_MAP.md / help methods):
*   kim : weighted-LS PPO Zrho,Zt (3.3-3.4) & ADF (3.5-3.7), inf over N_T (3.13-3.15)
*   dm  : subsample DF (3.1) / PP (3.6), min over subsamples (3.9-3.13)
*   mr  : residual sup-Wald F_A/F_B (3.2), W(m*) (3.4), Wmax (3.5)

program define segmcoint, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    if ("`sub'"=="") {
        di as error "subcommand required: {bf:kim}, {bf:dm}, or {bf:mr}"
        exit 198
    }
    if ("`sub'"=="kim")      _sc_kim `0'
    else if ("`sub'"=="dm")  _sc_dm  `0'
    else if ("`sub'"=="mr")  _sc_mr  `0'
    else {
        di as error "unknown subcommand '`sub''. Use kim, dm, or mr."
        exit 198
    }
    return add
end

*-----------------------------------------------------------------------------
* KIM (2003) : weighted-LS segmented-cointegration tests
*-----------------------------------------------------------------------------
program define _sc_kim, rclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] , ///
        [ DETerministic(string) TRIMbar(real 0.3) MINlen(real 0.05) ///
          BWidth(integer -1) ADFLags(integer 0) GRID(integer 0) noHEADer ///
          GRAPH GRAPHName(string) ]

    gettoken dv xvars : varlist
    _sc_detparse "`deterministic'"
    local dcase = r(dcase)
    local dname "`r(dname)'"

    marksample touse
    markout `touse' `varlist'
    _sc_tsrequire
    qui count if `touse'
    local T = r(N)
    if (`T' < 30) {
        di as error "too few usable observations (`T'); need >= 30"
        exit 2000
    }
    local K : word count `xvars'
    local n = `K' + 1

    if (`trimbar' <= 0 | `trimbar' >= 1) {
        di as error "trimbar() must be in (0,1)"
        exit 198
    }
    if (`n' > 6) {
        di as error "Kim critical values are tabulated for n<=6 (n = #vars = `n')"
        exit 198
    }

    tempname R CV1 CV2 DAT
    mata: sc_kim_engine("`dv'","`xvars'","`touse'", `dcase', ///
        `trimbar', `minlen', `bwidth', `adflags', `grid', `n', ///
        "`R'","`CV1'","`CV2'","`DAT'")

    * ---- display ----
    if ("`header'"=="") {
        di ""
        di as text "{hline 78}"
        di as text "Kim (2003) tests for segmented cointegration"
        di as text "{hline 78}"
        di as text "Dependent variable : " as result "`dv'"
        di as text "Regressors         : " as result "`xvars'"
        di as text "Deterministic case : " as result "`dname'" as text ///
           "   (n = `n', T = `T')"
        di as text "Max noncoint. len. : " as result %5.2f `trimbar' as text ///
           "   (l-bar; Lemma 1 conservative bound)"
        di as text "{hline 78}"
    }
    di as text ///
"  Statistic       value    1%CV     2.5%CV     5%CV     10%CV   Reject H0(no coint)?"
    di as text "{hline 78}"
    _sc_kim_row "Zrho*"   `R'[1,1] `CV1'
    _sc_kim_row "Zt*"     `R'[2,1] `CV2'
    _sc_kim_row "ADFrho*" `R'[3,1] `CV1'
    _sc_kim_row "ADFt*"   `R'[4,1] `CV2'
    di as text "{hline 78}"
    di as text "H0: no cointegration over the whole sample (rho=1 all t)."
    di as text "H1: cointegration prevails except on a noncoint. interval N_T."
    di as text "Reject when the statistic is below the (lower-tail) critical value."
    di as text ""
    di as text "Estimated noncointegration interval N_T (from inf-Zt* segmentation):"
    di as text "  fraction  [" as result %5.3f `DAT'[1,1] as text " , " ///
        as result %5.3f `DAT'[1,2] as text " ]   " ///
        as text "Lambda-max date frac. [" as result %5.3f `DAT'[1,3] ///
        as text " , " as result %5.3f `DAT'[1,4] as text " ]"
    di as text "{hline 78}"

    * ---- returns ----
    return scalar zrho   = `R'[1,1]
    return scalar zt     = `R'[2,1]
    return scalar adfrho = `R'[3,1]
    return scalar adft   = `R'[4,1]
    return scalar n      = `n'
    return scalar T      = `T'
    return scalar tau0   = `DAT'[1,1]
    return scalar tau1   = `DAT'[1,2]
    return local  dvar   "`dv'"
    return local  xvars  "`xvars'"
    return local  det    "`dname'"
    return local  cmd    "segmcoint kim"
    return matrix stat   = `R', copy
    return matrix cv_rho = `CV1', copy
    return matrix cv_t   = `CV2', copy

    * ---- graph ----
    if ("`graph'"!="" | "`graphname'"!="") {
        if ("`graphname'"=="") local graphname "segmcoint_kim"
        tempname PM
        matrix `PM' = ( `R'[2,1], `CV2'[1,3] \ `R'[1,1], `CV1'[1,3] ///
                      \ `R'[4,1], `CV2'[1,3] \ `R'[3,1], `CV1'[1,3] )
        matrix rownames `PM' = Zt Zrho ADFt ADFrho
        _sc_forest `PM' lower "Kim (2003) tests: statistic vs 5% critical value" "`graphname'"
    }
end

program define _sc_kim_row
    args nm val cvmat
    tempname c
    matrix `c' = `cvmat'
    local v   = `val'
    local c1  = `c'[1,1]
    local c25 = `c'[1,2]
    local c5  = `c'[1,3]
    local c10 = `c'[1,4]
    * lower-tail rejection: stat below CV
    local rej "no"
    if (`v' < `c10') local rej "* (10%)"
    if (`v' < `c5')  local rej "** (5%)"
    if (`v' < `c1')  local rej "*** (1%)"
    di as text %-10s "`nm'" ///
       as result %9.3f `v' "  " ///
       as result %8.2f `c1' " " %8.2f `c25' " " %8.2f `c5' " " %8.2f `c10' ///
       "   " as result "`rej'"
end

*-----------------------------------------------------------------------------
* Shared helpers
*-----------------------------------------------------------------------------
program define _sc_detparse, rclass
    args d
    if ("`d'"=="") local d "const"
    if ("`d'"=="none")        local dc 0
    else if ("`d'"=="const")  local dc 1
    else if ("`d'"=="constant") local dc 1
    else if ("`d'"=="trend")  local dc 2
    else {
        di as error "deterministic() must be none, const, or trend"
        exit 198
    }
    local nm "constant"
    if (`dc'==0) local nm "none"
    if (`dc'==2) local nm "constant + trend"
    return scalar dcase = `dc'
    return local dname "`nm'"
end

program define _sc_tsrequire
    capture qui tsset
    if (_rc) {
        di as error "data must be {bf:tsset} (single time series) for segmcoint"
        exit 459
    }
end

* forest-style diagnostic plot: statistic (bar) vs its 5% critical value (marker)
* Mplot: k x 2 matrix, col1 = statistic, col2 = 5% CV, rownames = labels
* tail = lower (reject if stat<CV, e.g. Kim/DM) or upper (reject if stat>CV, MR)
program define _sc_forest
    args Mplot tail ttl gname
    preserve
    local rn : rownames `Mplot'
    local k = rowsof(`Mplot')
    matrix colnames `Mplot' = _val _cv5
    clear
    quietly svmat double `Mplot', names(col)
    quietly gen sid = _n
    local xl ""
    local i = 1
    foreach nm of local rn {
        local xl `xl' `i' "`nm'"
        local i = `i' + 1
    }
    local subt "reject where bar passes the red 5% marker (`tail' tail)"
    capture noisily twoway ///
        (bar _val sid, barwidth(0.5) color(navy%70)) ///
        (scatter _cv5 sid, msymbol(X) msize(large) mcolor(cranberry)) ///
        , legend(order(1 "statistic" 2 "5% critical value") rows(1) size(small)) ///
          xlabel(`xl', angle(45) noticks) xtitle("") ytitle("value") ///
          yline(0, lcolor(gs10) lwidth(thin)) ///
          title("`ttl'", size(medium)) subtitle("`subt'", size(small)) ///
          graphregion(color(white)) plotregion(color(white)) ///
          name(`gname', replace)
    restore
end

*-----------------------------------------------------------------------------
* Stubs (implemented in later versions of this build)
*-----------------------------------------------------------------------------
*-----------------------------------------------------------------------------
* DAVIDSON & MONTICINI (2010): subsample extremum cointegration tests
*-----------------------------------------------------------------------------
program define _sc_dm, rclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] , ///
        [ DETerministic(string) LAMBDA0(real 0.5) STATistic(string) ///
          GRID(integer 0) noHEADer GRAPH GRAPHName(string) ]

    gettoken dv xvars : varlist
    _sc_detparse "`deterministic'"
    local dcase = r(dcase)
    local dname "`r(dname)'"
    if (`dcase'==0) {
        di as error "Davidson-Monticini requires det const or trend (mean-deviation residuals)"
        exit 198
    }
    if ("`statistic'"=="") local statistic "pp"
    if (!inlist("`statistic'","pp","df")) {
        di as error "statistic() must be pp or df"
        exit 198
    }
    local stflag = cond("`statistic'"=="pp",1,0)

    * lambda0 must match a tabulated value
    local lok = 0
    foreach L in 0.5 0.35 0.2 0.1 {
        if (abs(`lambda0'-`L')<1e-6) local lok = 1
    }
    if (!`lok') {
        di as error "lambda0() must be one of 0.5, 0.35, 0.2, 0.1 (tabulated values)"
        exit 198
    }

    marksample touse
    markout `touse' `varlist'
    _sc_tsrequire
    qui count if `touse'
    local T = r(N)
    if (`T' < 30) {
        di as error "too few usable observations (`T')"
        exit 2000
    }
    local K : word count `xvars'
    local n = `K' + 1
    if (`K' > 2) {
        di as text "note: Davidson-Monticini critical values are tabulated only for 1-2 regressors;"
        di as text "      statistics are reported but no critical values are available for K=`K'."
    }

    tempname R CV
    mata: sc_dm_engine("`dv'","`xvars'","`touse'", `dcase', `lambda0', ///
        `stflag', `grid', `K', "`R'","`CV'")

    if ("`header'"=="") {
        di ""
        di as text "{hline 78}"
        di as text "Davidson & Monticini (2010) subsample cointegration tests"
        di as text "{hline 78}"
        di as text "Dependent variable : " as result "`dv'"
        di as text "Regressors         : " as result "`xvars'"
        di as text "Deterministic case : " as result "`dname'" as text ///
           "   (K = `K' regressor(s), T = `T')"
        di as text "Subsample statistic: " as result upper("`statistic'") as text ///
           "     lambda0 = " as result %4.2f `lambda0'
        di as text "{hline 78}"
    }
    di as text ///
"  Test            min-stat    10%CV     5%CV    2.5%CV     1%CV    Reject?"
    di as text "{hline 78}"
    _sc_dm_row "QS"          `R'[1,1] `CV' 1
    _sc_dm_row "QS*"         `R'[2,1] `CV' 2
    _sc_dm_row "QI(lambda0)" `R'[3,1] `CV' 3
    _sc_dm_row "QR(lambda0)" `R'[4,1] `CV' 4
    _sc_dm_row "QR*(lambda0)"`R'[5,1] `CV' 5
    di as text "{hline 78}"
    di as text "H0: no cointegration on any subsample. Reject if min-stat < CV."
    di as text "QS split-sample; QI incremental (fwd+bwd); QR rolling (length lambda0)."
    di as text "{hline 78}"

    return scalar qs    = `R'[1,1]
    return scalar qsstar= `R'[2,1]
    return scalar qi    = `R'[3,1]
    return scalar qr    = `R'[4,1]
    return scalar qrstar= `R'[5,1]
    return scalar T     = `T'
    return scalar K     = `K'
    return local  det   "`dname'"
    return local  statistic "`statistic'"
    return local  cmd   "segmcoint dm"
    return matrix stat  = `R', copy
    return matrix cv    = `CV', copy

    if ("`graph'"!="" | "`graphname'"!="") {
        if ("`graphname'"=="") local graphname "segmcoint_dm"
        tempname PM
        matrix `PM' = ( `R'[1,1], `CV'[1,2] \ `R'[2,1], `CV'[2,2] ///
                      \ `R'[3,1], `CV'[3,2] \ `R'[4,1], `CV'[4,2] ///
                      \ `R'[5,1], `CV'[5,2] )
        matrix rownames `PM' = QS QSstar QI QR QRstar
        _sc_forest `PM' lower "Davidson-Monticini (2010): min-statistic vs 5% CV" "`graphname'"
    }
end

program define _sc_dm_row
    args nm val cvmat rr
    tempname c
    matrix `c' = `cvmat'
    local v = `val'
    * CV row rr in cvmat has cols 10,5,2.5,1
    local hasrow = (`rr' <= rowsof(`c'))
    if (`v'>=.) {
        di as text %-13s "`nm'" as result "     (n/a)"
        exit
    }
    if (!`hasrow' | `c'[`rr',1]>=.) {
        di as text %-13s "`nm'" as result %9.3f `v' as text "     (no CV)"
        exit
    }
    local c10 = `c'[`rr',1]
    local c5  = `c'[`rr',2]
    local c25 = `c'[`rr',3]
    local c1  = `c'[`rr',4]
    local rej "no"
    if (`v' < `c10') local rej "* (10%)"
    if (`v' < `c5')  local rej "** (5%)"
    if (`v' < `c1')  local rej "*** (1%)"
    di as text %-13s "`nm'" ///
       as result %9.3f `v' "  " ///
       as result %8.3f `c10' " " %8.3f `c5' " " %8.3f `c25' " " %8.3f `c1' ///
       "  " as result "`rej'"
end
*-----------------------------------------------------------------------------
* MARTINS & RODRIGUES (2021): residual-based sup-Wald tests
*-----------------------------------------------------------------------------
program define _sc_mr, rclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] , ///
        [ DETerministic(string) MAXBreaks(integer 4) TRIM(real 0.15) ///
          ADFLags(integer 0) noHEADer GRAPH GRAPHName(string) ]

    gettoken dv xvars : varlist
    _sc_detparse "`deterministic'"
    local dcase = r(dcase)
    local dname "`r(dname)'"

    marksample touse
    markout `touse' `varlist'
    _sc_tsrequire
    qui count if `touse'
    local T = r(N)
    if (`T' < 40) {
        di as error "too few usable observations (`T')"
        exit 2000
    }
    local K : word count `xvars'
    local K1 = `K' + 1
    if (`K1' > 6) {
        di as error "Martins-Rodrigues critical values are tabulated for K+1<=6 (K+1=`K1')"
        exit 198
    }
    if (`maxbreaks' < 1) local maxbreaks 1
    if (`trim' <= 0 | `trim' >= 0.5) {
        di as error "trim() must be in (0,0.5)"
        exit 198
    }

    tempname R BRK CV
    mata: sc_mr_engine("`dv'","`xvars'","`touse'", `dcase', `maxbreaks', ///
        `trim', `adflags', `K1', "`R'","`BRK'","`CV'")

    if ("`header'"=="") {
        di ""
        di as text "{hline 78}"
        di as text "Martins & Rodrigues (2021) sup-Wald tests for segmented cointegration"
        di as text "{hline 78}"
        di as text "Dependent variable : " as result "`dv'"
        di as text "Regressors         : " as result "`xvars'"
        di as text "Deterministic case : " as result "`dname'" as text ///
           "   (K+1 = `K1', T = `T')"
        di as text "Trimming eps       : " as result %4.2f `trim' as text ///
           "     ADF lags = " as result `adflags' as text ///
           "     max breaks = " as result `maxbreaks'
        di as text "{hline 78}"
    }
    di as text ///
"  Test           statistic   10%CV     5%CV    2.5%CV     1%CV    Reject?"
    di as text "{hline 78}"
    forvalues m = 1/`maxbreaks' {
        _sc_mr_row "W(`m')" `R'[`m',1] `CV' `m'
    }
    local wmrow = `maxbreaks' + 1
    _sc_mr_row "Wmax" `R'[`wmrow',1] `CV' 5
    di as text "{hline 78}"
    di as text "H0: no cointegration over the whole sample. Reject if W > CV (upper tail)."
    di as text "W(m) tests m breaks; Wmax = max over m=1..`maxbreaks' (double-max)."
    di as text ""
    * break dates for the Wmax-selected model
    local mstar = `BRK'[1,1]
    di as text "Wmax-selected number of breaks m* = " as result `mstar'
    if (`mstar' > 0) {
        di as text "Estimated break fractions (global SSR minimisation):"
        forvalues j = 1/`mstar' {
            local bj = `BRK'[1,`j'+1]
            di as text "   break `j' : fraction " as result %5.3f `bj'
        }
    }
    di as text "{hline 78}"

    return scalar wmax = `R'[`wmrow',1]
    forvalues m = 1/`maxbreaks' {
        return scalar w`m' = `R'[`m',1]
    }
    return scalar mstar = `mstar'
    return scalar T   = `T'
    return scalar K1  = `K1'
    return local  det "`dname'"
    return local  cmd "segmcoint mr"
    return matrix stat = `R', copy
    return matrix breaks = `BRK', copy
    return matrix cv = `CV', copy

    if ("`graph'"!="" | "`graphname'"!="") {
        if ("`graphname'"=="") local graphname "segmcoint_mr"
        tempname PM
        local nr = `maxbreaks' + 1
        matrix `PM' = J(`nr', 2, .)
        forvalues m = 1/`maxbreaks' {
            matrix `PM'[`m',1] = `R'[`m',1]
            if (`m' <= rowsof(`CV')) matrix `PM'[`m',2] = `CV'[`m',2]
        }
        matrix `PM'[`nr',1] = `R'[`wmrow',1]
        matrix `PM'[`nr',2] = `CV'[5,2]
        local rn ""
        forvalues m = 1/`maxbreaks' {
            local rn `rn' W`m'
        }
        local rn `rn' Wmax
        matrix rownames `PM' = `rn'
        _sc_forest `PM' upper "Martins-Rodrigues (2021): sup-Wald vs 5% CV" "`graphname'"
    }
end

program define _sc_mr_row
    args nm val cvmat rr
    tempname c
    matrix `c' = `cvmat'
    local v = `val'
    if (`v'>=.) {
        di as text %-13s "`nm'" as result "     (n/a)"
        exit
    }
    if (`rr' > rowsof(`c') | `c'[`rr',1]>=.) {
        di as text %-13s "`nm'" as result %9.3f `v' as text "     (no CV)"
        exit
    }
    local c10 = `c'[`rr',1]
    local c5  = `c'[`rr',2]
    local c25 = `c'[`rr',3]
    local c1  = `c'[`rr',4]
    local rej "no"
    if (`v' > `c10') local rej "* (10%)"
    if (`v' > `c5')  local rej "** (5%)"
    if (`v' > `c1')  local rej "*** (1%)"
    di as text %-13s "`nm'" ///
       as result %9.3f `v' "  " ///
       as result %8.3f `c10' " " %8.3f `c5' " " %8.3f `c25' " " %8.3f `c1' ///
       "  " as result "`rej'"
end

*=============================================================================
* MATA ENGINES
*=============================================================================
mata:

// ---- Bartlett long-run variance of a column vector v, bandwidth q -------
real scalar sc_lrv(real colvector v, real scalar q)
{
    real scalar n, g0, lam2, j, gj, w
    n = rows(v)
    g0 = (v'v)/n
    lam2 = g0
    for (j=1; j<=q; j++) {
        if (j < n) {
            gj = (v[(j+1)::n]' * v[1::(n-j)]) / n
            w  = 1 - j/(q+1)
            lam2 = lam2 + 2*w*gj
        }
    }
    return(lam2)
}

// ---- OLS beta via normal equations (generalized inverse for safety) -----
real colvector sc_ols(real matrix Xm, real colvector ym)
{
    return(invsym(quadcross(Xm,Xm)) * quadcross(Xm,ym))
}

// ---- default LRV / ADF bandwidths ---------------------------------------
real scalar sc_nwbw(real scalar Tc)
{
    return(floor(4*(Tc/100)^(2/9)))
}

// ---- Kim: compute (Zrho,Zt,ADFrho,ADFt) for a given C_T selection -------
//  inC : T x 1  {0,1}, 1 if obs is in the cointegration set C_T
//  design : T x kd  (deterministics + regressors)
//  returns 1x4 rowvector; missing if the segmentation is infeasible
real rowvector sc_kim_stats(real colvector y, real matrix design,
    real colvector inC, real scalar bw, real scalar adflags, real scalar n)
{
    real matrix    Xc, Wd, XtXinv
    real colvector yc, bhat, e, et, etm1, v, dep, bres, resid, rr
    real scalar    T, Tc, i, k, kk, rho, Sxx, s2, sig2rho, g0, lam2, q
    real scalar    t_rho, Zrho, Zt, npair, nadf
    real scalar    p, ADFrho, ADFt, gamma, seg, lamsig, dfa, sga, sz
    real rowvector out

    out = J(1,4,.)
    T = rows(y)
    if (sum(inC) < (n+5)) return(out)

    // weighted LS on C_T only (eq 3.1-3.2, w=1 on C_T, 0 on N_T)
    Xc = select(design, inC)
    yc = select(y, inC)
    if (rows(Xc) <= cols(Xc)+1) return(out)
    bhat = sc_ols(Xc, yc)
    e = y - design*bhat

    // AR(1) pairs within C_T contiguity: t and t-1 both in C_T
    et   = J(0,1,.)
    etm1 = J(0,1,.)
    for (i=2; i<=T; i++) {
        if (inC[i]==1) {
            if (inC[i-1]==1) {
                et   = et   \ e[i]
                etm1 = etm1 \ e[i-1]
            }
        }
    }
    npair = rows(et)
    if (npair < (n+5)) return(out)
    Tc = npair
    Sxx = quadcross(etm1,etm1)
    if (Sxx<=0) return(out)
    rho = quadcross(etm1,et)/Sxx
    v = et - rho*etm1
    s2 = quadcross(v,v)/(Tc-1)
    sig2rho = s2/Sxx
    g0 = quadcross(v,v)/Tc
    q = bw
    if (q < 0) q = sc_nwbw(Tc)
    lam2 = sc_lrv(v, q)
    if (lam2<=0) lam2 = g0
    t_rho = (rho-1)/sqrt(sig2rho)

    // Phillips-Perron-Ouliaris Zrho (3.3) and Zt (3.4)
    Zrho = Tc*(rho-1) - 0.5*(lam2-g0)*(Tc*Tc/Sxx)
    Zt   = sqrt(g0/lam2)*t_rho - 0.5*(lam2-g0)/sqrt(lam2)*(Tc/sqrt(Sxx))
    out[1,1] = Zrho
    out[1,2] = Zt

    // ---- ADF variant (3.5)-(3.7): Delta e on p lags + e_{t-1}, within C_T
    p = adflags
    if (p < 0) p = 0
    dep = J(0,1,.)
    Wd  = J(0, p+1, .)
    for (i=(p+2); i<=T; i++) {
        seg = 1
        for (k=0; k<=(p+1); k++) {
            if (inC[i-k]!=1) seg = 0
        }
        if (seg==1) {
            dep = dep \ (e[i]-e[i-1])
            rr = J(1,p+1,.)
            for (k=1; k<=p; k++) {
                rr[1,k] = e[i-k]-e[i-k-1]
            }
            rr[1,p+1] = e[i-1]
            Wd = Wd \ rr
        }
    }
    nadf = rows(dep)
    if (nadf > (p+3)) {
        bres = sc_ols(Wd, dep)
        gamma = bres[p+1,1]                 // coef on e_{t-1} = rho-1
        resid = dep - Wd*bres
        dfa = nadf - cols(Wd)
        sga = sqrt(quadcross(resid,resid)/dfa)
        XtXinv = invsym(quadcross(Wd,Wd))
        ADFt = gamma / (sga*sqrt(XtXinv[p+1,p+1]))
        lamsig = 1
        if (p>=1) {
            sz = 0
            for (kk=1; kk<=p; kk++) {
                sz = sz + bres[kk,1]
            }
            lamsig = 1/(1-sz)
        }
        ADFrho = nadf*lamsig*gamma
        out[1,3] = ADFrho
        out[1,4] = ADFt
    }
    return(out)
}

// ---- Kim main engine ----------------------------------------------------
void sc_kim_engine(string scalar dvname, string scalar xnames,
    string scalar tousename, real scalar dcase, real scalar trimbar,
    real scalar minlen, real scalar bw, real scalar adflags,
    real scalar grid, real scalar n,
    string scalar Rname, string scalar CV1name, string scalar CV2name,
    string scalar DATname)
{
    real colvector y, tvec, inC
    real matrix X, design, D, best, bestpos, R, DAT
    real scalar T, i, c, a0, a1, maxL, minL, step, ell, lamv
    real scalar LamBest, Lda0, Lda1
    real rowvector st

    y = st_data(., dvname, tousename)
    T = rows(y)
    X = J(T,0,.)
    if (xnames!="") X = st_data(., tokens(xnames), tousename)

    // deterministic design (Case I/II/III = none/const/const+trend)
    D = J(T,0,.)
    if (dcase==1) D = J(T,1,1)
    if (dcase==2) {
        tvec = (1::T)
        D = (J(T,1,1), tvec)
    }
    design = X
    if (cols(D)>0) design = (D, X)

    maxL = floor(trimbar*T)
    minL = max((1, floor(minlen*T)))
    step = grid
    if (step < 1) step = max((1, floor(T/200)))

    best = J(1,4,.)            // best (inf) stat value per column
    bestpos = J(4,2,.)         // (a0,a1) achieving each inf
    LamBest = .
    Lda0 = .
    Lda1 = .

    for (a0=0; a0<=(T-minL); a0=a0+step) {
        for (ell=minL; ell<=maxL; ell=ell+step) {
            a1 = a0+ell
            if (a1>T) continue
            inC = J(T,1,1)
            for (i=a0+1; i<=a1; i++) {
                inC[i] = 0
            }
            if (sum(inC) < (n+5)) continue
            st = sc_kim_stats(y, design, inC, bw, adflags, n)
            for (c=1; c<=4; c++) {
                if (st[1,c]<.) {
                    if (best[1,c]>=. | st[1,c] < best[1,c]) {
                        best[1,c] = st[1,c]
                        bestpos[c,1] = a0/T
                        bestpos[c,2] = a1/T
                    }
                }
            }
            // dating: Lambda_T(tau) (3.16), track argmax
            if (st[1,2]<.) {
                lamv = sc_kim_lambda(y, design, inC, a0, a1)
                if (lamv<.) {
                    if (LamBest>=. | lamv>LamBest) {
                        LamBest = lamv
                        Lda0 = a0/T
                        Lda1 = a1/T
                    }
                }
            }
        }
    }

    // assemble R (4x3): stat, tau0(inf), tau1(inf)
    R = J(4,3,.)
    for (i=1;i<=4;i++) {
        R[i,1] = best[1,i]
        R[i,2] = bestpos[i,1]
        R[i,3] = bestpos[i,2]
    }
    st_matrix(Rname, R)

    // dating output: [tau0(infZt), tau1(infZt), tau0(Lambda), tau1(Lambda)]
    DAT = (bestpos[2,1], bestpos[2,2], Lda0, Lda1)
    st_matrix(DATname, DAT)

    // critical values
    st_matrix(CV1name, sc_kim_cv(1, dcase, n))   // Zrho / ADFrho  (Table 1)
    st_matrix(CV2name, sc_kim_cv(2, dcase, n))   // Zt   / ADFt    (Table 2)
}

// ---- Lambda_T(tau) statistic for dating (3.16) --------------------------
real scalar sc_kim_lambda(real colvector y, real matrix design,
    real colvector inC, real scalar a0, real scalar a1)
{
    real matrix Xc
    real colvector yc, bhat, e
    real scalar T, num, den, i, cN, cC
    T = rows(y)
    Xc = select(design, inC)
    yc = select(y, inC)
    if (rows(Xc) <= cols(Xc)+1) return(.)
    bhat = sc_ols(Xc,yc)
    e = y - design*bhat
    num = 0
    den = 0
    cN = 0
    cC = 0
    for (i=1; i<=T; i++) {
        if (inC[i]==0) {
            num = num + e[i]^2
            cN = cN + 1
        } else {
            den = den + e[i]^2
            cC = cC + 1
        }
    }
    if (cN==0 | cC==0) return(.)
    // ((tau1-tau0)T)^-2 * sum_N e^2  /  ( Tc^-1 sum_C e^2 )
    num = num / ((a1-a0)^2)
    den = den / cC
    if (den<=0) return(.)
    return(num/den)
}

// ---- Kim critical-value tables (asymptotic, l-bar=0.3) -------------------
//  which=1 -> Table 1 (Zrho*/ADFrho*); which=2 -> Table 2 (Zt*/ADFt*)
//  returns 1x4 = [1%, 2.5%, 5%, 10%] lower-tail critical values
real rowvector sc_kim_cv(real scalar which, real scalar dcase, real scalar n)
{
    real matrix T1, T2, M
    real scalar row
    // rows: caseI n1..6 (1-6), caseII (7-12), caseIII (13-18)
    // cols: .01 .025 .05 .10 (we keep the 4 lower-tail columns)
    T1 = (
    -13,   -10.16, -8.18,  -5.68  \
    -37.2, -32.3,  -27.9,  -23.7  \
    -46.63,-41.05, -36.41, -31.61 \
    -55.89,-48.97, -44.59, -39.43 \
    -63.94,-58.4,  -52.79, -47.78 \
    -70.39,-64.3,  -59.83, -54.22 \
    -20.15,-16.73, -13.96, -11.37 \
    -87.37,-64.3,  -50.75, -39.58 \
    -105.48,-84.12,-65.53, -51.53 \
    -122.91,-96.68,-78.66, -61.95 \
    -130.86,-106.23,-87.07,-69.28 \
    -134.72,-109.84,-89.89,-73.65 \
    -29.17,-24.9,  -21.55, -18.22 \
    -107.65,-80.24,-62.54, -46.59 \
    -131.66,-101.33,-79.34,-58.96 \
    -135.59,-109.94,-87.87,-68.31 \
    -140.29,-115.59,-96.57,-74.32 \
    -144.09,-118.83,-98.31,-78.46 )

    T2 = (
    -2.51, -2.2,  -1.96, -1.61 \
    -4.23, -3.95, -3.65, -3.34 \
    -4.88, -4.49, -4.23, -3.92 \
    -5.26, -4.89, -4.68, -4.38 \
    -5.59, -5.33, -5.09, -4.86 \
    -5.89, -5.68, -5.45, -5.16 \
    -3.49, -3.12, -2.88, -2.58 \
    -8.84, -7.43, -6.36, -5.31 \
    -10.05,-8.68, -7.38, -6.22 \
    -11.04,-9.51, -8.25, -6.86 \
    -11.33,-10.03,-8.7,  -7.21 \
    -11.78,-10.14,-8.76, -7.33 \
    -3.92, -3.66, -3.4,  -3.12 \
    -10.42,-8.78, -7.74, -6.32 \
    -11.68,-9.98, -8.62, -7.23 \
    -11.9, -10.37,-9.13, -7.57 \
    -12.32,-10.8, -9.52, -7.83 \
    -12.45,-10.98,-9.53, -7.79 )

    row = dcase*6 + n
    M = T2
    if (which==1) M = T1
    return(M[row,.])
}

// =========================================================================
//  DAVIDSON & MONTICINI (2010)
// =========================================================================

// ---- DF (stflag=0) or PP (stflag=1) t-stat on a residual series z -------
real scalar sc_dfpp(real colvector z, real scalar stflag, real scalar bw)
{
    real scalar m, g, s2, seg, Sxx, tdf, g0, lam2, q, Zt, nz
    real colvector dz, zlag, u
    nz = rows(z)
    m = nz-1
    if (m < 8) return(.)
    dz = z[2::nz] - z[1::(nz-1)]
    zlag = z[1::(nz-1)]
    Sxx = quadcross(zlag,zlag)
    if (Sxx<=0) return(.)
    g = quadcross(zlag,dz)/Sxx
    u = dz - g*zlag
    s2 = quadcross(u,u)/(m-1)
    seg = sqrt(s2/Sxx)
    tdf = g/seg
    if (stflag==0) return(tdf)
    g0 = quadcross(u,u)/m
    q = bw
    if (q<0) q = sc_nwbw(m)
    lam2 = sc_lrv(u,q)
    if (lam2<=0) lam2 = g0
    Zt = sqrt(g0/lam2)*tdf - 0.5*(lam2-g0)/sqrt(lam2)*(m/sqrt(Sxx))
    return(Zt)
}

// ---- subsample cointegration statistic on obs a..b (eq 3.1-3.6) ---------
real scalar sc_dm_substat(real colvector y, real matrix X, real scalar dcase,
    real scalar a, real scalar b, real scalar stflag, real scalar bw)
{
    real scalar ns
    real matrix Dsub, Xsub, Wd
    real colvector ysub, bhat, z, tvec
    ns = b-a+1
    if (ns < 15) return(.)
    ysub = y[a::b]
    Xsub = J(ns,0,.)
    if (cols(X)>0) Xsub = X[a::b,.]
    Dsub = J(ns,1,1)
    if (dcase==2) {
        tvec = (1::ns)
        Dsub = (Dsub, tvec)
    }
    Wd = Dsub
    if (cols(Xsub)>0) Wd = (Dsub, Xsub)
    bhat = sc_ols(Wd, ysub)
    z = ysub - Wd*bhat
    return(sc_dfpp(z, stflag, bw))
}

// ---- DM engine : QS, QS*, QI, QR, QR* (min over subsamples) --------------
void sc_dm_engine(string scalar dvname, string scalar xnames,
    string scalar tousename, real scalar dcase, real scalar lambda0,
    real scalar stflag, real scalar grid, real scalar K,
    string scalar Rname, string scalar CVname)
{
    real colvector y
    real matrix X, R
    real scalar T, bw, step, L, a, b, half
    real scalar sfull, s1, s2, qs, qsstar, qi, qr, qrstar, v

    y = st_data(., dvname, tousename)
    T = rows(y)
    X = J(T,0,.)
    if (xnames!="") X = st_data(., tokens(xnames), tousename)
    bw = -1
    step = grid
    if (step < 1) step = max((1, floor(T/150)))

    sfull = sc_dm_substat(y, X, dcase, 1, T, stflag, bw)

    // split-sample QS (eq 3.9-3.10)
    half = floor(T/2)
    s1 = sc_dm_substat(y, X, dcase, 1, half, stflag, bw)
    s2 = sc_dm_substat(y, X, dcase, half+1, T, stflag, bw)
    qs = min((s1, s2))
    qsstar = min((qs, sfull))

    // incremental QI (eq 3.11): forward (1,b) and backward (a,T)
    L = floor(lambda0*T)
    qi = .
    for (b=L; b<=T; b=b+step) {
        v = sc_dm_substat(y, X, dcase, 1, b, stflag, bw)
        if (v<.) qi = min((qi, v))
    }
    for (a=1; a<=(T-L+1); a=a+step) {
        v = sc_dm_substat(y, X, dcase, a, T, stflag, bw)
        if (v<.) qi = min((qi, v))
    }

    // rolling QR (eq 3.12-3.13): windows of length L
    qr = .
    for (a=1; a<=(T-L+1); a=a+step) {
        b = a+L-1
        v = sc_dm_substat(y, X, dcase, a, b, stflag, bw)
        if (v<.) qr = min((qr, v))
    }
    qrstar = min((qr, sfull))

    R = (qs \ qsstar \ qi \ qr \ qrstar)
    st_matrix(Rname, R)
    st_matrix(CVname, sc_dm_cv(dcase, K, lambda0))
}

// ---- DM critical values (Table 1); rows QS,QS*,QI,QR,QR*; cols 10,5,2.5,1
real matrix sc_dm_cv(real scalar dcase, real scalar K, real scalar lambda0)
{
    real matrix M, QIblk
    real rowvector qsr, qssr, qrr, qrsr, qirow
    real scalar li

    M = J(5,4,.)
    if (K>2 | K<1) return(M)

    // choose lambda0 index for QI: 0.5->1,0.35->2,0.2->3,0.1->4
    li = 0
    if (abs(lambda0-0.5)<1e-6)  li = 1
    if (abs(lambda0-0.35)<1e-6) li = 2
    if (abs(lambda0-0.2)<1e-6)  li = 3
    if (abs(lambda0-0.1)<1e-6)  li = 4

    if (K==1 & dcase==1) {
        qsr  = (-3.356,-3.610,-3.851,-4.120)
        qssr = (-3.463,-3.718,-3.938,-4.228)
        QIblk = (-4.067,-4.327,-4.554,-4.846 \
                 -4.194,-4.452,-4.667,-4.935 \
                 -4.325,-4.568,-4.767,-5.032 \
                 -4.433,-4.648,-4.863,-5.143)
        qrr  = (-4.143,-4.392,-4.614,-4.864)
        qrsr = (-4.152,-4.402,-4.623,-4.873)
    }
    if (K==1 & dcase==2) {
        qsr  = (-3.791,-4.061,-4.297,-4.578)
        qssr = (-3.909,-4.165,-4.399,-4.666)
        QIblk = (-4.480,-4.745,-4.956,-5.221 \
                 -4.602,-4.860,-5.071,-5.329 \
                 -4.735,-4.969,-5.177,-5.435 \
                 .,.,.,.)
        qrr  = (-4.563,-4.803,-5.017,-5.294)
        qrsr = (-4.563,-4.803,-5.042,-5.294)
    }
    if (K==2 & dcase==1) {
        qsr  = (-3.355,-3.618,-3.867,-4.175)
        qssr = (-3.466,-3.726,-3.963,-4.258)
        QIblk = (-4.079,-4.341,-4.571,-4.854 \
                 -4.200,-4.460,-4.679,-4.950 \
                 -4.323,-4.565,-4.780,-5.050 \
                 .,.,.,.)
        qrr  = (-4.154,-4.405,-4.636,-4.888)
        qrsr = (-4.164,-4.405,-4.636,-4.888)
    }
    if (K==2 & dcase==2) {
        qsr  = (-3.795,-4.053,-4.301,-4.560)
        qssr = (-3.912,-4.165,-4.397,-4.660)
        QIblk = (-4.502,-4.755,-4.956,-5.240 \
                 -4.623,-4.858,-5.073,-5.339 \
                 -4.746,-4.973,-5.179,-5.445 \
                 .,.,.,.)
        qrr  = (-4.569,-4.797,-5.024,-5.281)
        qrsr = (-4.578,-4.811,-5.025,-5.288)
    }

    qirow = (.,.,.,.)
    if (li>=1 & li<=4) qirow = QIblk[li,.]

    M[1,.] = qsr
    M[2,.] = qssr
    M[3,.] = qirow
    // QR / QR* critical values are tabulated only for lambda0 = 0.5
    if (abs(lambda0-0.5)<1e-6) {
        M[4,.] = qrr
        M[5,.] = qrsr
    }
    return(M)
}

// =========================================================================
//  MARTINS & RODRIGUES (2021)
// =========================================================================

// ---- SSR of regressing dep on W (W may have 0 columns) ------------------
real scalar sc_seg_ssr(real colvector dep, real matrix W)
{
    real colvector b, r
    if (cols(W)==0) return(quadcross(dep,dep))
    if (rows(dep) <= cols(W)) return(.)
    b = invsym(quadcross(W,W))*quadcross(W,dep)
    r = dep - W*b
    return(quadcross(r,r))
}

// ---- all-subsample SSR matrix via incremental cross-products (O(N^2)) ---
//  C[s,e] = SSR of regressing dep[s..e] on Wmat[s..e,.] (min length h)
real matrix sc_costmat(real colvector dep, real matrix Wmat,
    real scalar N, real scalar h)
{
    real matrix C, XtX
    real colvector Xty, we
    real scalar s, e, k, Syy, de, ssr
    C = J(N,N,.)
    k = cols(Wmat)
    for (s=1; s<=N; s++) {
        Syy = 0
        XtX = J(max((k,1)),max((k,1)),0)
        Xty = J(max((k,1)),1,0)
        for (e=s; e<=N; e++) {
            de = dep[e]
            Syy = Syy + de*de
            if (k>0) {
                we = Wmat[e,.]'
                XtX = XtX + we*we'
                Xty = Xty + we*de
            }
            if ((e-s+1) >= h) {
                if (k==0) {
                    C[s,e] = Syy
                } else {
                    ssr = Syy - Xty'*invsym(XtX)*Xty
                    C[s,e] = ssr
                }
            }
        }
    }
    return(C)
}

// ---- DP min-SSR partition with alternating segment types (Bai-Perron) ---
//  kIsA=1 -> segment j free iff j even ; kIsA=0 -> free iff j odd
//  returns rowvector [SSR, brk1,...,brkm] (breaks in ADF-obs index)
real rowvector sc_mr_dp(real matrix costRest, real matrix costFree,
    real scalar N, real scalar h, real scalar m, real scalar kIsA)
{
    real matrix dp, pos
    real scalar j, i, ep, nseg, freej, tot, cval, best, bestpos
    real rowvector res
    real colvector brk
    real scalar jj, ii

    nseg = m+1
    dp  = J(nseg, N, .)
    pos = J(nseg, N, .)

    // first segment (j=1): A -> restricted ; B -> free
    freej = 1
    if (kIsA==1) freej = 0
    for (i=h; i<=N; i++) {
        if (freej==1) dp[1,i] = costFree[1,i]
        else          dp[1,i] = costRest[1,i]
    }

    for (j=2; j<=nseg; j++) {
        freej = 0
        if (kIsA==1) {
            if (mod(j,2)==0) freej = 1
        } else {
            if (mod(j,2)==1) freej = 1
        }
        for (i=j*h; i<=N; i++) {
            best = .
            bestpos = .
            for (ep=(j-1)*h; ep<=(i-h); ep++) {
                if (dp[j-1,ep]<.) {
                    if (freej==1) cval = costFree[ep+1,i]
                    else          cval = costRest[ep+1,i]
                    if (cval<.) {
                        tot = dp[j-1,ep] + cval
                        if (best>=. | tot<best) {
                            best = tot
                            bestpos = ep
                        }
                    }
                }
            }
            dp[j,i]  = best
            pos[j,i] = bestpos
        }
    }

    res = J(1, m+1, .)
    res[1,1] = dp[nseg, N]
    if (dp[nseg,N]>=.) return(res)
    // backtrack
    brk = J(m,1,.)
    ii = N
    for (jj=nseg; jj>=2; jj--) {
        ep = pos[jj, ii]
        brk[jj-1,1] = ep
        ii = ep
    }
    for (jj=1; jj<=m; jj++) {
        res[1,jj+1] = brk[jj,1]
    }
    return(res)
}

// ---- F_k scaling (eq 3.2) -----------------------------------------------
real scalar sc_mr_F(real scalar SSR0, real scalar SSRkm, real scalar m,
    real scalar dB, real scalar Tfull, real scalar p)
{
    real scalar num, den
    if (SSRkm<=0 | SSRkm>=.) return(.)
    if (mod(m,2)==0) {
        num = (Tfull - m - 2*dB - p)*(SSR0 - SSRkm)
        den = (m + 2*dB)*SSRkm
    } else {
        num = (Tfull - m - 1 - p)*(SSR0 - SSRkm)
        den = (m + 1)*SSRkm
    }
    return(num/den)
}

// ---- MR main engine -----------------------------------------------------
void sc_mr_engine(string scalar dvname, string scalar xnames,
    string scalar tousename, real scalar dcase, real scalar mbar,
    real scalar trim, real scalar p, real scalar K1,
    string scalar Rname, string scalar BRKname, string scalar CVname)
{
    real colvector y, e, dep, ecvar, bhat, tvec
    real matrix X, D, design, Lagmat, costRest, costFree, R, BRK, Wfree, Wrest
    real scalar T, N, h, i, s, ee, j, m, SSR0, tt, kk
    real rowvector dpA, dpB
    real scalar FA, FB, Wm, Wmax, mstarBest
    real rowvector bestbrk, curbrk
    real scalar useKisA

    y = st_data(., dvname, tousename)
    T = rows(y)
    X = J(T,0,.)
    if (xnames!="") X = st_data(., tokens(xnames), tousename)

    D = J(T,0,.)
    if (dcase==1) D = J(T,1,1)
    if (dcase==2) {
        tvec = (1::T)
        D = (J(T,1,1), tvec)
    }
    design = X
    if (cols(D)>0) design = (D, X)

    // full-sample OLS residuals (eq 2.1)
    bhat = sc_ols(design, y)
    e = y - design*bhat

    // ADF observation arrays: dep_t = de_t, ec = e_{t-1}, lags of de
    // Delta e_t for t=2..T ; with p lags need t=p+2..T -> N obs
    N = T - (p+1)
    if (N < 20) {
        R = J(mbar+1,1,.)
        st_matrix(Rname, R)
        st_matrix(BRKname, J(1, mbar+1, .))
        st_matrix(CVname, sc_mr_cv(K1, dcase))
        return
    }
    dep   = J(N,1,.)
    ecvar = J(N,1,.)
    Lagmat = J(N,p,.)
    for (i=1; i<=N; i++) {
        // ADF obs i corresponds to time t = p+1+i
        tt = p+1+i
        dep[i,1]   = e[tt] - e[tt-1]
        ecvar[i,1] = e[tt-1]
        for (kk=1; kk<=p; kk++) {
            Lagmat[i,kk] = e[tt-kk] - e[tt-kk-1]
        }
    }

    h = floor(trim*T)
    if (h < (p+3)) h = p+3
    if (mbar*h + h > N) {
        // reduce mbar feasibility handled by DP returning missing
    }

    // precompute segment SSRs (incremental, O(N^2))
    // free model = [1, e_{t-1}, lags] ; restricted = lags only (nothing if p=0)
    Wfree = (J(N,1,1), ecvar)
    if (p>=1) Wfree = (Wfree, Lagmat)
    Wrest = J(N,0,.)
    if (p>=1) Wrest = Lagmat
    costFree = sc_costmat(dep, Wfree, N, h)
    costRest = sc_costmat(dep, Wrest, N, h)
    SSR0 = costRest[1,N]

    R = J(mbar+1, 1, .)
    Wmax = .
    mstarBest = 0
    bestbrk = J(1, mbar, .)

    for (m=1; m<=mbar; m++) {
        dpA = sc_mr_dp(costRest, costFree, N, h, m, 1)
        dpB = sc_mr_dp(costRest, costFree, N, h, m, 0)
        FA = sc_mr_F(SSR0, dpA[1,1], m, 0, T, p)
        FB = sc_mr_F(SSR0, dpB[1,1], m, 1, T, p)
        Wm = .
        useKisA = 1
        if (FA<.) Wm = FA
        if (FB<. ) {
            if (Wm>=. | FB>Wm) {
                Wm = FB
                useKisA = 0
            }
        }
        R[m,1] = Wm
        // track Wmax and its break configuration
        if (Wm<.) {
            if (Wmax>=. | Wm>Wmax) {
                Wmax = Wm
                mstarBest = m
                // report breaks from the lower-SSR partition (Remark 3):
                // that alternative correctly identifies the stationary regimes
                curbrk = dpB
                if (dpA[1,1] <= dpB[1,1]) curbrk = dpA
                bestbrk = J(1, mbar, .)
                for (j=1; j<=m; j++) {
                    // convert ADF index to time fraction: t=p+1+idx
                    bestbrk[1,j] = (p+1+curbrk[1,j+1])/T
                }
            }
        }
    }
    R[mbar+1,1] = Wmax

    st_matrix(Rname, R)
    BRK = (mstarBest, bestbrk)
    st_matrix(BRKname, BRK)
    st_matrix(CVname, sc_mr_cv(K1, dcase))
}

// ---- segment SSR for MR (restricted lags-only, or free [1,ec,lags]) -----
real scalar sc_mr_segssr(real colvector dep, real colvector ecvar,
    real matrix Lagmat, real scalar s, real scalar ee, real scalar p,
    real scalar free)
{
    real colvector dsub
    real matrix W
    real scalar ns
    ns = ee-s+1
    dsub = dep[s::ee]
    if (free==0) {
        if (p==0) return(quadcross(dsub,dsub))
        W = Lagmat[s::ee, .]
        return(sc_seg_ssr(dsub, W))
    }
    W = J(ns,1,1), ecvar[s::ee]
    if (p>=1) W = (W, Lagmat[s::ee, .])
    return(sc_seg_ssr(dsub, W))
}

// ---- MR critical values (Table 1); rows W(1..4),Wmax; cols 10,5,2.5,1 ----
real matrix sc_mr_cv(real scalar K1, real scalar dcase)
{
    real matrix A
    A = J(5,4,.)
    if (K1<2 | K1>6) return(A)

    if (K1==2 & dcase==0) {
        A = (8.229,9.367,10.615,12.349 \ 8.362,9.329,10.334,11.958 \
             7.168,7.956,8.901,10.574 \ 6.804,7.790,8.932,11.129 \
             9.677,11.033,12.499,15.016)
    }
    if (K1==2 & dcase==1) {
        A = (8.050,9.106,10.308,12.089 \ 8.279,9.277,10.269,11.428 \
             7.069,7.764,8.684,10.329 \ 6.895,7.731,8.930,11.083 \
             9.536,10.762,12.025,14.670)
    }
    if (K1==2 & dcase==2) {
        A = (8.373,9.810,11.638,15.592 \ 8.527,9.755,11.092,12.568 \
             7.279,8.229,9.531,11.884 \ 7.152,8.311,9.561,12.126 \
             9.946,11.580,13.631,17.734)
    }
    if (K1==3 & dcase==0) {
        A = (7.812,8.915,9.829,11.476 \ 8.216,9.165,9.942,11.298 \
             6.872,7.660,8.583,9.972 \ 6.657,7.612,8.575,10.942 \
             9.403,10.539,12.085,13.887)
    }
    if (K1==3 & dcase==1) {
        A = (7.711,8.761,9.661,11.103 \ 8.036,9.090,10.050,11.470 \
             6.830,7.645,8.405,9.855 \ 6.664,7.619,8.602,10.713 \
             9.214,10.552,11.797,13.973)
    }
    if (K1==3 & dcase==2) {
        A = (7.666,8.756,9.843,11.365 \ 8.085,9.070,10.110,11.222 \
             6.863,7.597,8.467,9.612 \ 6.713,7.792,9.017,11.072 \
             9.298,10.430,11.671,13.690)
    }
    if (K1==4 & dcase==0) {
        A = (7.529,8.542,9.615,11.026 \ 7.988,8.903,9.851,11.217 \
             6.664,7.450,8.293,9.967 \ 6.492,7.495,8.661,10.835 \
             9.131,10.459,11.795,13.941)
    }
    if (K1==4 & dcase==1) {
        A = (7.669,8.628,9.721,10.707 \ 7.913,8.852,9.816,11.419 \
             6.598,7.281,8.199,9.374 \ 6.499,7.475,8.738,10.905 \
             9.093,10.330,11.597,13.785)
    }
    if (K1==4 & dcase==2) {
        A = (7.588,8.589,9.471,10.870 \ 7.985,9.049,10.000,11.291 \
             6.659,7.366,8.148,9.423 \ 6.588,7.688,9.003,11.085 \
             9.208,10.375,11.628,13.334)
    }
    if (K1==5 & dcase==0) {
        A = (7.546,8.448,9.320,10.718 \ 7.942,8.921,9.734,10.741 \
             6.516,7.171,7.915,9.175 \ 6.393,7.530,8.750,10.640 \
             8.952,9.989,11.180,13.109)
    }
    if (K1==5 & dcase==1) {
        A = (7.994,8.936,9.876,11.179 \ 7.928,8.936,9.801,11.204 \
             6.658,7.364,8.104,9.720 \ 6.418,7.449,8.683,11.017 \
             9.194,10.407,11.867,13.893)
    }
    if (K1==5 & dcase==2) {
        A = (7.947,9.000,10.037,11.751 \ 7.903,8.969,9.785,11.230 \
             6.646,7.289,8.024,9.500 \ 6.435,7.528,8.784,11.696 \
             9.279,10.461,12.084,14.375)
    }
    if (K1==6 & dcase==0) {
        A = (7.857,8.772,9.733,11.029 \ 7.882,8.832,9.875,10.910 \
             6.553,7.235,8.003,9.127 \ 6.374,7.397,8.740,11.314 \
             9.151,10.425,11.803,13.336)
    }
    if (K1==6 & dcase==1) {
        A = (8.452,9.616,10.667,11.793 \ 8.023,8.942,9.864,11.028 \
             6.740,7.450,8.199,9.480 \ 6.375,7.323,8.511,10.701 \
             9.591,10.754,11.806,13.379)
    }
    if (K1==6 & dcase==2) {
        A = (8.330,9.412,10.398,11.916 \ 7.890,8.767,9.755,10.989 \
             6.641,7.363,8.048,9.111 \ 6.458,7.454,9.080,11.956 \
             9.443,10.676,12.028,13.747)
    }
    return(A)
}
end
