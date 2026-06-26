*! hatemicoint v2.0.0
*! Tests for cointegration with two unknown breaks (Hatemi-J 2008)
*! Author: Dr. Merwan ROUDANE, Independent Researcher
*! Email: merwanroudane920@gmail.com
*! Date: June 2026
*! Reference: Hatemi-J, A. (2008). Tests for cointegration with two unknown
*! regime shifts with an application to financial market integration.
*! Empirical Economics, 35, 497-505.
*!
*! Version history:
*! v2.0.0 - Re-engineered in Mata. Corrects the Phillips-Perron Zt* and Za*
*!          statistics (previous versions returned an invalid Zt* near zero),
*!          adds the level-shift and level-shift-with-trend models, and runs
*!          the full break grid in Mata (seconds instead of minutes). The PP
*!          and ADF statistics now reproduce the GAUSS reference implementation.
*!          Adds a graph option (series, residual and decision panels).
*! v1.0.1 - Added model() option and iid kernel option.
*! v1.0.0 - Initial release.

program define hatemicoint, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in] , ///
        [ ///
        Maxlags(integer 8) ///
        LAGSelection(string) ///
        Kernel(string) ///
        BWL(integer -999) ///
        TRIMming(real 0.15) ///
        Model(integer 3) ///
        GRAPH ///
        GRAPHTest(string) ///
        ]

    marksample touse
    qui count if `touse'
    if r(N) == 0 error 2000
    local nobs = r(N)

    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'

    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use single time series."
        exit 198
    }
    if "`timevar'" == "" {
        di as error "Time variable not set. Use {bf:tsset} to set time variable."
        exit 198
    }

    gettoken depvar indepvars : varlist
    local indepvars : list clean indepvars
    local k : word count `indepvars'

    if `k' > 4 {
        di as error "Hatemi-J (2008) tabulates critical values only for up to 4 regressors (k<=4)."
        exit 198
    }
    if `maxlags' < 0 {
        di as error "maxlags() must be non-negative"
        exit 198
    }
    if `trimming' <= 0 | `trimming' >= 0.5 {
        di as error "trimming() must be between 0 and 0.5"
        exit 198
    }
    if !inlist(`model', 1, 2, 3) {
        di as error "model() must be 1 (level shift), 2 (level shift with trend), or 3 (regime shift)"
        exit 198
    }

    if "`lagselection'" == "" local lagselection "tstat"
    local lagselection = lower("`lagselection'")
    if !inlist("`lagselection'", "aic", "sic", "tstat") {
        di as error "lagselection() must be: aic, sic, or tstat"
        exit 198
    }
    local icnum = cond("`lagselection'" == "aic", 1, cond("`lagselection'" == "sic", 2, 3))

    if "`kernel'" == "" local kernel "iid"
    local kernel = lower("`kernel'")
    if "`kernel'" == "quadraticspectral" local kernel "qs"
    if !inlist("`kernel'", "iid", "bartlett", "qs") {
        di as error "kernel() must be: iid, bartlett, or qs (quadraticspectral)"
        exit 198
    }
    local kernnum = cond("`kernel'" == "iid", 0, cond("`kernel'" == "bartlett", 1, 2))

    if "`graphtest'" == "" local graphtest "zt"
    local graphtest = lower("`graphtest'")
    if !inlist("`graphtest'", "adf", "zt", "za") {
        di as error "graphtest() must be adf, zt, or za"
        exit 198
    }
    if "`graphtest'" != "zt" & "`graph'" == "" local graph "graph"

    if `bwl' == -999 {
        local bwl = round(4 * (`nobs'/100)^(2/9))
    }
    else if `bwl' < 0 {
        di as error "bwl() must be non-negative"
        exit 198
    }

    * break grid feasibility
    local g1 = round(`trimming' * `nobs')
    local g2 = round((1 - 2*`trimming') * `nobs')
    local g3 = round((1 - `trimming') * `nobs')
    if (`g2' - `g1' + 1) < 1 | (`g3' - 2*`g1' + 1) < 1 {
        di as error "trimming() is too large for this sample (`nobs' obs): the break grid is empty."
        exit 198
    }

    tempname cv_adfzt cv_za

    preserve
    qui keep if `touse'
    sort `timevar'

    mata: hatemicoint_engine("`depvar'", "`indepvars'", "`timevar'", `model', `icnum', `maxlags', `kernnum', `bwl', `trimming')

    local adf_min  = scalar(__hc_adf)
    local lag_adf  = scalar(__hc_lag)
    local zt_min   = scalar(__hc_zt)
    local za_min   = scalar(__hc_za)
    local o1adf    = scalar(__hc_o1adf)
    local o2adf    = scalar(__hc_o2adf)
    local o1zt     = scalar(__hc_o1zt)
    local o2zt     = scalar(__hc_o2zt)
    local o1za     = scalar(__hc_o1za)
    local o2za     = scalar(__hc_o2za)
    local d1adf    = scalar(__hc_d1adf)
    local d2adf    = scalar(__hc_d2adf)
    local d1zt     = scalar(__hc_d1zt)
    local d2zt     = scalar(__hc_d2zt)
    local d1za     = scalar(__hc_d1za)
    local d2za     = scalar(__hc_d2za)

    _get_critical_values `k'
    matrix `cv_adfzt' = r(cv_adfzt)
    matrix `cv_za' = r(cv_za)

    if "`graph'" != "" {
        _hatemicoint_graph "`depvar'" "`indepvars'" "`timevar'" ///
            `model' "`graphtest'" `adf_min' `zt_min' `za_min' ///
            `cv_adfzt'[1,1] `cv_adfzt'[1,2] `cv_adfzt'[1,3] ///
            `cv_za'[1,1] `cv_za'[1,2] `cv_za'[1,3] ///
            `d1adf' `d2adf' `d1zt' `d2zt' `d1za' `d2za'
    }

    restore

    local mtxt "regime shift"
    if `model' == 1 local mtxt "level shift"
    if `model' == 2 local mtxt "level shift with trend"
    local kertxt "`kernel'"
    if "`kernel'" == "qs" local kertxt "quadratic spectral"
    if "`kernel'" == "bartlett" local kertxt "Bartlett"

    local tvfmt : format `timevar'
    local D1a : display `tvfmt' `d1adf'
    local D2a : display `tvfmt' `d2adf'
    local D1t : display `tvfmt' `d1zt'
    local D2t : display `tvfmt' `d2zt'
    local D1z : display `tvfmt' `d1za'
    local D2z : display `tvfmt' `d2za'
    local D1a = strtrim("`D1a'")
    local D2a = strtrim("`D2a'")
    local D1t = strtrim("`D1t'")
    local D2t = strtrim("`D2t'")
    local D1z = strtrim("`D1z'")
    local D2z = strtrim("`D2z'")

    di _n as text "{hline 78}"
    di    as text "Hatemi-J (2008) cointegration test with two unknown breaks"
    di    as text "{hline 78}"
    di    as text "Dependent variable" _col(28) as result "`depvar'"
    di    as text "Independent variables" _col(28) as result "`indepvars'"
    di    as text "Observations" _col(28) as result `nobs' as text "      Regressors (k):" as result " `k'"
    di    as text "Specification" _col(28) as result "`mtxt' (model `model')"
    di    as text "Trimming" _col(28) as result %5.3f `trimming'
    di    as text "Lag selection" _col(28) as result "`lagselection'" as text "   (kmax = " as result `maxlags' as text ", selected lag = " as result `lag_adf' as text ")"
    if "`kernel'" == "iid" {
        di    as text "Long-run variance" _col(28) as result "iid"
    }
    else {
        di    as text "Long-run variance" _col(28) as result "`kertxt'" as text "  (bandwidth = " as result `bwl' as text ")"
    }
    di _n as text "H0: no cointegration"
    di    as text "{hline 78}"
    di    as text %-6s "Test" %14s "Statistic" %13s "Break 1" %13s "Break 2" %9s "1%" %9s "5%" %9s "10%"
    di    as text "{hline 78}"
    di    as text %-6s "ADF*" as result %14.4f `adf_min' %13s "`D1a'" %13s "`D2a'" as text %9.3f `cv_adfzt'[1,1] %9.3f `cv_adfzt'[1,2] %9.3f `cv_adfzt'[1,3]
    di    as text %-6s "Zt*"  as result %14.4f `zt_min'  %13s "`D1t'" %13s "`D2t'" as text %9.3f `cv_adfzt'[1,1] %9.3f `cv_adfzt'[1,2] %9.3f `cv_adfzt'[1,3]
    di    as text %-6s "Za*"  as result %14.4f `za_min'  %13s "`D1z'" %13s "`D2z'" as text %9.3f `cv_za'[1,1] %9.3f `cv_za'[1,2] %9.3f `cv_za'[1,3]
    di    as text "{hline 78}"
    di    as text "ADF* = modified ADF test;  Zt*, Za* = modified Phillips-Perron tests."
    di    as text "Critical values from Hatemi-J (2008). Break columns show the time-variable value."
    di    as text "Reject H0 when the statistic is below (more negative than) the critical value."
    di _n

    return scalar adf_min = `adf_min'
    return scalar lag_adf = `lag_adf'
    return scalar tb1_adf = `o1adf'
    return scalar tb2_adf = `o2adf'
    return scalar date1_adf = `d1adf'
    return scalar date2_adf = `d2adf'
    return scalar zt_min = `zt_min'
    return scalar tb1_zt = `o1zt'
    return scalar tb2_zt = `o2zt'
    return scalar date1_zt = `d1zt'
    return scalar date2_zt = `d2zt'
    return scalar za_min = `za_min'
    return scalar tb1_za = `o1za'
    return scalar tb2_za = `o2za'
    return scalar date1_za = `d1za'
    return scalar date2_za = `d2za'
    return scalar nobs = `nobs'
    return scalar k = `k'
    return scalar model = `model'
    return matrix cv_adfzt = `cv_adfzt'
    return matrix cv_za = `cv_za'

    capture scalar drop __hc_adf __hc_lag __hc_zt __hc_za
    capture scalar drop __hc_o1adf __hc_o2adf __hc_o1zt __hc_o2zt __hc_o1za __hc_o2za
    capture scalar drop __hc_d1adf __hc_d2adf __hc_d1zt __hc_d2zt __hc_d1za __hc_d2za
end


program define _hatemicoint_graph
    args depvar indepvars timevar model rb ///
         adf zt za c1a c5a c10a c1z c5z c10z ///
         d1adf d2adf d1zt d2zt d1za d2za

    * break dates of the selected test
    if "`rb'" == "adf" {
        local bd1 = `d1adf'
        local bd2 = `d2adf'
        local rblab "ADF*"
    }
    else if "`rb'" == "za" {
        local bd1 = `d1za'
        local bd2 = `d2za'
        local rblab "Za*"
    }
    else {
        local bd1 = `d1zt'
        local bd2 = `d2zt'
        local rblab "Zt*"
    }

    * operates on the already-filtered, time-sorted data inside the caller's preserve
    local tvfmt : format `timevar'
    local Lb1 : display `tvfmt' `bd1'
    local Lb2 : display `tvfmt' `bd2'
    local Lb1 = strtrim("`Lb1'")
    local Lb2 = strtrim("`Lb2'")

    * reconstruct the cointegrating residual at the selected break
    tempvar du1 du2 ehat
    qui gen byte `du1' = `timevar' > `bd1'
    qui gen byte `du2' = `timevar' > `bd2'
    local rhs `du1' `du2'
    if `model' == 2 {
        tempvar trend
        qui gen double `trend' = _n
        local rhs `rhs' `trend'
    }
    local rhs `rhs' `indepvars'
    if `model' == 3 {
        local xc 0
        foreach v of local indepvars {
            local ++xc
            tempvar i1`xc' i2`xc'
            qui gen double `i1`xc'' = `du1' * `v'
            qui gen double `i2`xc'' = `du2' * `v'
            local rhs `rhs' `i1`xc'' `i2`xc''
        }
    }
    qui reg `depvar' `rhs'
    qui predict double `ehat', residuals

    * ---- Panel 1: series with shaded regimes and break lines ----
    qui su `depvar', meanonly
    local lo = r(min)
    local hi = r(max)
    local rg = `hi' - `lo'
    if `rg' == 0 local rg = 1
    local blo = `lo' - 0.08*`rg'
    local bhi = `hi' + 0.14*`rg'
    tempvar lo1 hi1
    qui gen double `lo1' = `blo'
    qui gen double `hi1' = `bhi'

    twoway ///
        (rarea `lo1' `hi1' `timevar' if `timevar' <= `bd1', color(ltblue) fintensity(18) lwidth(none)) ///
        (rarea `lo1' `hi1' `timevar' if `timevar' > `bd1' & `timevar' <= `bd2', color(ltkhaki) fintensity(28) lwidth(none)) ///
        (rarea `lo1' `hi1' `timevar' if `timevar' > `bd2', color(ltblue) fintensity(18) lwidth(none)) ///
        (line `depvar' `timevar', lcolor(navy) lwidth(medthick)) ///
        , xline(`bd1' `bd2', lpattern(dash) lcolor(cranberry) lwidth(medthin)) ///
        title("Dependent variable and estimated breaks", size(medsmall)) ///
        subtitle("breaks selected by the `rblab' statistic", size(small)) ///
        ytitle("`depvar'", size(small)) xtitle("") ///
        text(`bhi' `bd1' "TB1 = `Lb1'", placement(w) size(vsmall) color(cranberry)) ///
        text(`bhi' `bd2' "TB2 = `Lb2'", placement(e) size(vsmall) color(cranberry)) ///
        yscale(range(`blo' `bhi')) legend(off) ///
        graphregion(color(white)) plotregion(margin(zero)) ///
        name(__hc_g1, replace) nodraw

    * ---- Panel 2: cointegrating residual ----
    qui su `ehat', meanonly
    local elo = r(min)
    local ehi = r(max)
    local erg = `ehi' - `elo'
    if `erg' == 0 local erg = 1
    local eblo = `elo' - 0.10*`erg'
    local ebhi = `ehi' + 0.10*`erg'
    tempvar lo2 hi2
    qui gen double `lo2' = `eblo'
    qui gen double `hi2' = `ebhi'

    twoway ///
        (rarea `lo2' `hi2' `timevar' if `timevar' <= `bd1', color(ltblue) fintensity(18) lwidth(none)) ///
        (rarea `lo2' `hi2' `timevar' if `timevar' > `bd1' & `timevar' <= `bd2', color(ltkhaki) fintensity(28) lwidth(none)) ///
        (rarea `lo2' `hi2' `timevar' if `timevar' > `bd2', color(ltblue) fintensity(18) lwidth(none)) ///
        (line `ehat' `timevar', lcolor(maroon) lwidth(medthick)) ///
        , yline(0, lcolor(gs7)) ///
        xline(`bd1' `bd2', lpattern(dash) lcolor(cranberry) lwidth(medthin)) ///
        title("Cointegrating residual (test is applied here)", size(medsmall)) ///
        ytitle("residual", size(small)) xtitle("`timevar'", size(small)) ///
        yscale(range(`eblo' `ebhi')) legend(off) ///
        graphregion(color(white)) plotregion(margin(zero)) ///
        name(__hc_g2, replace) nodraw

    * ---- Panel 3: decision (statistic / 5% critical value) ----
    local nadf = `adf' / `c5a'
    local nzt  = `zt'  / `c5a'
    local nza  = `za'  / `c5z'
    local r1a  = `c1a' / `c5a'
    local r10a = `c10a'/ `c5a'
    local r1z  = `c1z' / `c5z'
    local r10z = `c10z'/ `c5z'
    local cadf = cond(`adf' < `c5a', "dkgreen", "cranberry")
    local czt  = cond(`zt'  < `c5a', "dkgreen", "cranberry")
    local cza  = cond(`za'  < `c5z', "dkgreen", "cranberry")
    local xmax = max(`nadf', `nzt', `nza', `r1a', `r1z', 1.15) * 1.10

    twoway ///
        (pci 3 0 3 `nadf', lcolor(gs11) lwidth(medthick)) ///
        (pci 2 0 2 `nzt' , lcolor(gs11) lwidth(medthick)) ///
        (pci 1 0 1 `nza' , lcolor(gs11) lwidth(medthick)) ///
        (scatteri 3 `r1a' 3 `r10a' 2 `r1a' 2 `r10a' 1 `r1z' 1 `r10z', ///
            msymbol(pipe) msize(large) mcolor(gs6)) ///
        (scatteri 3 `nadf', msymbol(O) msize(vlarge) mcolor(`cadf')) ///
        (scatteri 2 `nzt' , msymbol(O) msize(vlarge) mcolor(`czt')) ///
        (scatteri 1 `nza' , msymbol(O) msize(vlarge) mcolor(`cza')) ///
        , xline(1, lpattern(dash) lcolor(cranberry) lwidth(medthin)) ///
        ylabel(1 "Za*" 2 "Zt*" 3 "ADF*", angle(0) labsize(small)) ///
        yscale(range(0.5 3.5)) xscale(range(0 `xmax')) ///
        title("Decision: statistic / 5% critical value", size(medsmall)) ///
        subtitle("reject H0 of no cointegration when the marker is right of 1.0", size(vsmall)) ///
        xtitle("ratio to 5% critical value", size(small)) ytitle("") ///
        text(3.45 1 "5%", placement(e) size(vsmall) color(cranberry)) ///
        note("Green marker = reject at 5% (cointegration); red = fail to reject." ///
             "Grey ticks mark the 1% and 10% critical-value ratios.", size(vsmall)) ///
        legend(off) graphregion(color(white)) ///
        name(__hc_g3, replace) nodraw

    capture graph drop __hc_top
    graph combine __hc_g1 __hc_g2, rows(1) graphregion(color(white)) ///
        name(__hc_top, replace) nodraw
    graph combine __hc_top __hc_g3, cols(1) ///
        title("Hatemi-J (2008) two-break cointegration test", size(medium)) ///
        graphregion(color(white)) ysize(5) xsize(7) ///
        name(hatemicoint, replace)
    capture graph drop __hc_g1 __hc_g2 __hc_g3 __hc_top
end


program define _get_critical_values, rclass
    args k

    tempname cv_adfzt cv_za

    if `k' == 1 {
        matrix `cv_adfzt' = (-6.503, -6.015, -5.653)
        matrix `cv_za' = (-90.794, -76.003, -52.232)
    }
    else if `k' == 2 {
        matrix `cv_adfzt' = (-6.928, -6.458, -6.224)
        matrix `cv_za' = (-99.458, -83.644, -76.806)
    }
    else if `k' == 3 {
        matrix `cv_adfzt' = (-7.833, -7.352, -7.118)
        matrix `cv_za' = (-118.577, -104.860, -97.749)
    }
    else if `k' == 4 {
        matrix `cv_adfzt' = (-8.353, -7.903, -7.705)
        matrix `cv_za' = (-140.135, -123.870, -116.169)
    }

    return matrix cv_adfzt = `cv_adfzt'
    return matrix cv_za = `cv_za'
end


version 14.0
mata:
mata set matastrict off

// ---------- 1-based index of the FIRST minimum of a column vector ----------
real scalar hc_minindex(real colvector v)
{
    real scalar i, mi, mv
    mv = v[1]
    mi = 1
    for (i = 2; i <= rows(v); i++) {
        if (v[i] < mv) {
            mv = v[i]
            mi = i
        }
    }
    return(mi)
}

// ---------- regressor matrix for a given model and break dummies ----------
// model 1 = level shift              : [1, d1, d2, X]
// model 2 = level shift with trend   : [1, d1, d2, trend, X]
// model 3 = regime shift             : [1, d1, d2, X, d1#X, d2#X]
real matrix hc_buildX(real scalar model, real scalar n, real matrix X,
                      real colvector d1, real colvector d2)
{
    if (model == 3) return((J(n,1,1), d1, d2, X, (d1:*X), (d2:*X)))
    else if (model == 2) return((J(n,1,1), d1, d2, (1::n), X))
    else return((J(n,1,1), d1, d2, X))
}

// ---------- long-run variance of a residual series (TSPDLIB convention) ----------
// kern: 1 = Bartlett, 2 = quadratic spectral ; l = bandwidth
real scalar hc_lrv(real colvector resid, real scalar l, real scalar kern)
{
    real scalar T, lrv, bw, w, x1, x2
    T   = rows(resid)
    lrv = (resid' * resid) / T
    for (bw = 1; bw <= l; bw++) {
        if (kern == 1) {
            w = 1 - bw / (l + 1)
        }
        else {
            x1 = bw / l
            x2 = 6 * pi() * x1 / 5
            w  = (25 / (12 * (pi() * x1)^2)) * (sin(x2) / x2 - cos(x2))
        }
        lrv = lrv + 2 * (resid[|1 \ (T - bw)|]' * resid[|(1 + bw) \ T|]) * w / T
    }
    return(lrv)
}

// ---------- Phillips-Perron Za and Zt on a residual series ----------
// kern: 0 = iid, 1 = Bartlett, 2 = quadratic spectral ; l = bandwidth
real rowvector hc_pp(real colvector e, real scalar kern, real scalar l)
{
    real colvector dy, ly, resid
    real scalar N, b, t, ssr, s2, se1, g0, lrv, tau, Zt, lam, mbaryy, Za
    N     = rows(e)
    dy    = e[|2 \ N|] - e[|1 \ (N - 1)|]
    ly    = e[|1 \ (N - 1)|]
    b     = (ly' * dy) / (ly' * ly)
    resid = dy - ly * b
    t     = rows(resid)
    ssr   = resid' * resid
    s2    = ssr / (t - 1)
    se1   = sqrt(s2 / (ly' * ly))
    g0    = (t - 1) * s2 / t
    if (kern == 0) lrv = ssr / t
    else           lrv = hc_lrv(resid, l, kern)
    tau    = b / se1
    Zt     = tau * sqrt(g0 / lrv) - t * (lrv - g0) * se1 / (2 * sqrt(lrv) * sqrt(s2))
    lam    = 0.5 * (lrv - g0)
    mbaryy = (t * se1 / sqrt(s2))^2
    Za     = t * b - lam * mbaryy
    return((Za, Zt))
}

// ---------- ADF t-statistic on a residual series (model 0, no deterministics) ----------
// ic: 1 = Akaike, 2 = Schwarz, 3 = t-stat (general to specific, 1.645) ; returns (tau, lags)
real rowvector hc_adf(real colvector e, real scalar pmax, real scalar ic)
{
    real colvector dvec, lvec, dep, bb, res, se, aicp, sicp, tstatp, taup
    real matrix    xm, mm
    real scalar    N, p, k, nn, LL, lag, j
    N = rows(e)
    dvec = J(N, 1, .)
    lvec = J(N, 1, .)
    for (j = 2; j <= N; j++) {
        dvec[j] = e[j] - e[j - 1]
        lvec[j] = e[j - 1]
    }
    aicp   = J(pmax + 1, 1, .)
    sicp   = J(pmax + 1, 1, .)
    tstatp = J(pmax + 1, 1, .)
    taup   = J(pmax + 1, 1, .)
    p = 0
    while (p <= pmax) {
        dep = dvec[|(p + 2) \ N|]
        xm  = lvec[|(p + 2) \ N|]
        if (p > 0) {
            for (j = 1; j <= p; j++) {
                xm = xm , dvec[|(p + 2 - j) \ (N - j)|]
            }
        }
        mm  = luinv(quadcross(xm, xm))
        bb  = mm * quadcross(xm, dep)
        res = dep - xm * bb
        nn  = rows(dep)
        k   = cols(xm)
        se  = sqrt(diagonal(mm) * ((res' * res) / (nn - k)))
        taup[p + 1]   = bb[1] / se[1]
        LL = -nn / 2 * (1 + ln(2 * pi()) + ln((res' * res) / nn))
        aicp[p + 1]   = (2 * k - 2 * LL) / nn
        sicp[p + 1]   = (k * ln(nn) - 2 * LL) / nn
        tstatp[p + 1] = abs(bb[k] / se[k])
        p = p + 1
    }
    if (ic == 1) {
        lag = hc_minindex(aicp)
    }
    else if (ic == 2) {
        lag = hc_minindex(sicp)
    }
    else {
        lag = 1
        j = pmax + 1
        while (j >= 1) {
            if (tstatp[j] > 1.645) {
                lag = j
                j = 0
            }
            else {
                j = j - 1
            }
        }
    }
    return((taup[lag], lag - 1))
}

// ---------- main driver: search the two-break grid (mirrors coint_hatemiJ) ----------
void hatemicoint_engine(string scalar yvar, string scalar xvars, string scalar tvar,
                        real scalar model, real scalar ic, real scalar pmax,
                        real scalar kern, real scalar bwl, real scalar trimm)
{
    real colvector y, tv, d1, d2, ec
    real matrix    X, X1
    real scalar    n, begin, final1, final2, t1, t2
    real scalar    adfmin, ztmin, zamin, alag
    real scalar    a1, a2, z1, z2, q1, q2
    real rowvector ares, pres

    y  = st_data(., yvar)
    X  = st_data(., tokens(xvars))
    tv = st_data(., tvar)
    n  = rows(y)

    begin  = round(trimm * n)
    final1 = round((1 - 2 * trimm) * n)
    final2 = round((1 - trimm) * n)

    adfmin = 1000; ztmin = 1000; zamin = 1000
    alag = 0
    a1 = a2 = z1 = z2 = q1 = q2 = .

    for (t1 = begin; t1 <= final1; t1++) {
        for (t2 = t1 + begin; t2 <= final2; t2++) {
            d1 = J(t1, 1, 0) \ J(n - t1, 1, 1)
            d2 = J(t2, 1, 0) \ J(n - t2, 1, 1)
            X1 = hc_buildX(model, n, X, d1, d2)
            ec = y - X1 * (invsym(quadcross(X1, X1)) * quadcross(X1, y))

            ares = hc_adf(ec, pmax, ic)
            if (ares[1] < adfmin) {
                adfmin = ares[1]
                alag   = ares[2]
                a1 = t1; a2 = t2
            }
            pres = hc_pp(ec, kern, bwl)
            if (pres[2] < ztmin) {
                ztmin = pres[2]
                z1 = t1; z2 = t2
            }
            if (pres[1] < zamin) {
                zamin = pres[1]
                q1 = t1; q2 = t2
            }
        }
    }

    st_numscalar("__hc_adf",  adfmin)
    st_numscalar("__hc_lag",  alag)
    st_numscalar("__hc_zt",   ztmin)
    st_numscalar("__hc_za",   zamin)
    st_numscalar("__hc_o1adf", a1); st_numscalar("__hc_o2adf", a2)
    st_numscalar("__hc_o1zt",  z1); st_numscalar("__hc_o2zt",  z2)
    st_numscalar("__hc_o1za",  q1); st_numscalar("__hc_o2za",  q2)
    st_numscalar("__hc_d1adf", tv[a1]); st_numscalar("__hc_d2adf", tv[a2])
    st_numscalar("__hc_d1zt",  tv[z1]); st_numscalar("__hc_d2zt",  tv[z2])
    st_numscalar("__hc_d1za",  tv[q1]); st_numscalar("__hc_d2za",  tv[q2])
}

end
