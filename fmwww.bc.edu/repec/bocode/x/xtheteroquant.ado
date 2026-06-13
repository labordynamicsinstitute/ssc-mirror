*! xtheteroquant 1.0.0  12jun2026
*! Two-step estimation and bootstrap inference for the tau-quantile of the
*! cross-sectional distribution of heterogeneous unit-specific coefficients
*! in panel data.  Method: Galvao, Hounyo and Lin (2026), arXiv:2605.01923.
*! Author : Merwan Roudane  (merwanroudane920@gmail.com)
*! GitHub : https://github.com/merwanroudane

program define xtheteroquant, rclass sortpreserve
    version 14.0
    syntax [anything] [if] [in] [,            ///
        Tau(numlist >0 <1 sort)               ///
        Reps(integer 200)                     ///
        Level(cilevel)                        ///
        SEed(string)                          ///
        MINobs(integer 0)                     ///
        CIType(string)                        ///
        DESign(string)                        ///
        NULL(real 0)                          ///
        noCONStant                            ///
        PLOT                                  ///
        GRid(integer 19)                      ///
        PLOTVars(string)                      ///
        DIST                                  ///
        DETail                                ///
        GEN1(name)                            ///
        NAME(name)                            ///
        NODOTs ]

    marksample touse, novarlist

    * ------------------------------------------------------------------
    * defaults and option checks
    * ------------------------------------------------------------------
    if `"`tau'"' == "" local tau ".25 .5 .75"
    if `"`citype'"' == "" local citype "basic"
    local citype = lower("`citype'")
    if !inlist("`citype'", "basic", "percentile") {
        di as err "citype() must be {bf:basic} or {bf:percentile}"
        exit 198
    }
    if `"`design'"' == "" local design "both"
    local design = lower("`design'")
    if "`design'" == "stochastic"    local design "sqb"
    if "`design'" == "deterministic" local design "cdqb"
    if !inlist("`design'", "both", "sqb", "cdqb") {
        di as err "design() must be {bf:both}, {bf:sqb} (stochastic) or {bf:cdqb} (deterministic)"
        exit 198
    }
    if (`reps' < 2) {
        di as err "reps() must be at least 2"
        exit 198
    }
    if (`reps' < 100) {
        di as txt "note: reps() < 100; bootstrap confidence intervals and p-values will be coarse"
    }
    if (`grid' < 5 | `grid' > 99) {
        di as err "grid() must be between 5 and 99"
        exit 198
    }
    if `"`seed'"' != "" {
        qui set seed `seed'
    }

    * ------------------------------------------------------------------
    * variables: standalone varlist OR postestimation after xtreg etc.
    * ------------------------------------------------------------------
    local post 0
    tempvar esamp
    if `"`anything'"' == "" {
        if `"`e(cmd)'"' == "" {
            di as err "nothing to estimate: supply {it:depvar} [{it:indepvars}]" ///
                _n "or first fit a panel model with xtreg, regress, reghdfe, areg or xtgls"
            exit 301
        }
        if !inlist("`e(cmd)'", "xtreg", "regress", "reghdfe", "areg", "xtgls") {
            di as err "xtheteroquant postestimation works after xtreg, regress, reghdfe, areg or xtgls;" ///
                _n "found e(cmd) = `e(cmd)'.  Supply an explicit varlist instead."
            exit 322
        }
        local dv `"`e(depvar)'"'
        local xvars : colnames e(b)
        local xvars : subinstr local xvars "_cons" "", word
        if (strpos("`xvars'", ".") | strpos("`xvars'", "#")) {
            di as err "factor-variable or time-series operators detected in e(b);" ///
                _n "supply an explicit numeric varlist instead"
            exit 198
        }
        qui gen byte `esamp' = e(sample)
        local post 1
    }
    else {
        local 0 `"`anything'"'
        syntax varlist(min=1 numeric)
        gettoken dv xvars : varlist
    }

    * coefficient set
    local K : word count `xvars'
    local conames `xvars'
    local hascons 1
    if "`constant'" == "noconstant" local hascons 0
    if (`hascons') {
        local K = `K' + 1
        local conames `conames' _cons
    }
    if (`K' == 0) {
        di as err "no coefficients to estimate (no regressors and noconstant specified)"
        exit 198
    }

    * ------------------------------------------------------------------
    * panel structure
    * ------------------------------------------------------------------
    capture qui xtset
    if _rc {
        di as err "panel data not set; use {bf:xtset} {it:panelvar} [{it:timevar}]"
        exit 459
    }
    local ivar `"`r(panelvar)'"'
    local tvar `"`r(timevar)'"'

    markout `touse' `dv' `xvars' `ivar' `tvar'
    if (`post') {
        qui replace `touse' = 0 if `esamp' != 1
    }
    qui count if `touse'
    if (r(N) == 0) {
        di as err "no observations"
        exit 2000
    }

    sort `ivar' `tvar'

    * first-step coefficients saved as variables (gen1)
    local gennames ""
    local obsn ""
    if "`gen1'" != "" {
        foreach cn of local conames {
            local sfx = subinstr("`cn'", "_cons", "cons", .)
            local vn  "`gen1'_`sfx'"
            confirm new variable `vn'
        }
        foreach cn of local conames {
            local sfx = subinstr("`cn'", "_cons", "cons", .)
            local vn  "`gen1'_`sfx'"
            qui gen double `vn' = .
            label variable `vn' "first-step unit-specific coefficient on `cn'"
            local gennames `gennames' `vn'
        }
        tempvar obsv
        qui gen double `obsv' = _n
        local obsn `obsv'
    }

    * ------------------------------------------------------------------
    * tau vector: table taus first, then plotting grid (if requested)
    * ------------------------------------------------------------------
    local ntab : word count `tau'
    tempname TAU
    matrix `TAU' = J(1, `ntab', .)
    local j 1
    foreach t of local tau {
        matrix `TAU'[1, `j'] = `t'
        local j = `j' + 1
    }
    local ngrid 0
    if "`plot'" != "" {
        local ngrid `grid'
        forvalues g = 1/`ngrid' {
            matrix `TAU' = (`TAU', J(1, 1, `g'/(`ngrid'+1)))
        }
    }

    * ------------------------------------------------------------------
    * estimation + bootstrap (Mata)
    * ------------------------------------------------------------------
    local dots = ("`nodots'" == "")
    local maxmat = c(max_matsize)
    capture matrix drop __xthq_first
    mata: xthq_main("`dv'", "`xvars'", "`ivar'", "`touse'", "`TAU'",   ///
        `reps', `level', `hascons', `minobs', "`citype'", `null',     ///
        `dots', `maxmat', "`gennames'", "`obsn'")

    local Nu    = __xthq_Nu
    local ndrop = __xthq_nskip
    local Tavg  = __xthq_Tavg
    local Tmin  = __xthq_Tmin
    local Tmax  = __xthq_Tmax

    * ------------------------------------------------------------------
    * header
    * ------------------------------------------------------------------
    di
    di as txt "{bf:Quantiles of heterogeneous unit-specific coefficients}"
    di as txt "Two-step estimator with bootstrap inference (Galvao-Hounyo-Lin, 2026)"
    di
    di as txt "Dependent variable : " as res "`dv'"
    if "`xvars'" != "" {
        di as txt "Unit-specific slopes on : " as res "`xvars'"
    }
    else {
        di as txt "Intercept-only model (quantile of unit long-run means)"
    }
    di
    di as txt "First step  : unit-by-unit OLS"            _col(46) "Units used (N)  = " as res %9.0fc `Nu'
    di as txt "Second step : cross-sectional tau-quantile" _col(46) as txt "Units dropped   = " as res %9.0fc `ndrop'
    di as txt "Bootstrap   : B = " as res `reps'           as txt _col(46) "T: avg/min/max  = " as res %5.1f `Tavg' as txt "/" as res `Tmin' as txt "/" as res `Tmax'
    di as txt "CI type     : `citype' bootstrap CI"        _col(46) "CI level        = " as res "`level'%"
    if inlist("`design'", "both", "cdqb") {
        local nlo = sqrt(`Tavg')
        local nhi = `Tavg'^1.5
        if !(`Nu' > `nlo' & `Nu' < `nhi') {
            di as txt "note: N = `Nu' lies outside (sqrt(T), T^(3/2)) = (" %5.1f `nlo' ", " %7.1f `nhi' ");"
            di as txt "      the deterministic-design (CDQB) asymptotics may be less reliable here."
        }
    }

    * ------------------------------------------------------------------
    * results tables
    * ------------------------------------------------------------------
    if inlist("`design'", "both", "sqb") {
        _xthq_ptab "SQB - stochastic design (population tau-quantile)" ///
            `level' `ntab' "`conames'" `TAU' __xthq_est __xthq_seS __xthq_loS __xthq_hiS __xthq_pS `null'
    }
    if inlist("`design'", "both", "cdqb") {
        _xthq_ptab "CDQB - deterministic design (empirical tau-quantile)" ///
            `level' `ntab' "`conames'" `TAU' __xthq_est __xthq_seD __xthq_loD __xthq_hiD __xthq_pD `null'
    }
    if "`detail'" != "" {
        _xthq_dtab "`conames'" __xthq_sum1 `Nu'
    }

    * ------------------------------------------------------------------
    * quantile process plot
    * ------------------------------------------------------------------
    if "`plot'" != "" {
        local pnames `conames'
        if `"`plotvars'"' != "" {
            local pnames
            foreach pv of local plotvars {
                local okp 0
                foreach cn of local conames {
                    if "`pv'" == "`cn'" local okp 1
                }
                if (!`okp') {
                    di as err "plotvars(): `pv' is not among the estimated coefficients (`conames')"
                    exit 198
                }
                local pnames `pnames' `pv'
            }
        }
        local npan : word count `pnames'
        if (`npan' > 12) {
            di as txt "note: more than 12 coefficients; plotting the first 12 (use plotvars() to choose)"
            local pnames2
            forvalues k = 1/12 {
                local w : word `k' of `pnames'
                local pnames2 `pnames2' `w'
            }
            local pnames `pnames2'
            local npan 12
        }
        local gname "xthq_process"
        if "`name'" != "" local gname "`name'"

        preserve
        qui drop _all
        qui set obs `ngrid'
        qui gen double _tau = .
        qui gen double _est = .
        qui gen double _loS = .
        qui gen double _hiS = .
        qui gen double _loD = .
        qui gen double _hiD = .
        forvalues g = 1/`ngrid' {
            qui replace _tau = `TAU'[1, `ntab'+`g'] in `g'
        }

        local glist
        local gi 0
        foreach pn of local pnames {
            local gi = `gi' + 1
            local pidx 0
            local k 0
            foreach cn of local conames {
                local k = `k' + 1
                if "`cn'" == "`pn'" local pidx `k'
            }
            forvalues g = 1/`ngrid' {
                qui replace _est = __xthq_est[`pidx', `ntab'+`g'] in `g'
                qui replace _loS = __xthq_loS[`pidx', `ntab'+`g'] in `g'
                qui replace _hiS = __xthq_hiS[`pidx', `ntab'+`g'] in `g'
                qui replace _loD = __xthq_loD[`pidx', `ntab'+`g'] in `g'
                qui replace _hiD = __xthq_hiD[`pidx', `ntab'+`g'] in `g'
            }
            local plots
            if inlist("`design'", "both", "sqb") {
                local plots `plots' (line _loS _tau, lcolor(maroon) lpattern(dash)) (line _hiS _tau, lcolor(maroon) lpattern(dash))
            }
            if inlist("`design'", "both", "cdqb") {
                local plots `plots' (line _loD _tau, lcolor(forest_green) lpattern(shortdash)) (line _hiD _tau, lcolor(forest_green) lpattern(shortdash))
            }
            local plots `plots' (line _est _tau, lcolor(navy) lwidth(medthick))
            local ttl "`pn'"
            if "`pn'" == "_cons" local ttl "_cons (intercept)"
            if (`npan' == 1) {
                if "`design'" == "both" {
                    local legopt legend(order(5 "estimate" 1 "SQB `level'% CI" 3 "CDQB `level'% CI") rows(1))
                }
                else if "`design'" == "sqb" {
                    local legopt legend(order(3 "estimate" 1 "SQB `level'% CI") rows(1))
                }
                else {
                    local legopt legend(order(3 "estimate" 1 "CDQB `level'% CI") rows(1))
                }
                twoway `plots', yline(0, lcolor(gs12)) xlabel(0(.2)1, format(%3.1f))   ///
                    ylabel(, angle(horizontal)) title("`ttl'", size(medium))           ///
                    xtitle("{&tau}") ytitle("") `legopt'                               ///
                    name(`gname', replace)
            }
            else {
                twoway `plots', yline(0, lcolor(gs12)) xlabel(0(.2)1, format(%3.1f))   ///
                    ylabel(, angle(horizontal)) title("`ttl'", size(medium))           ///
                    xtitle("{&tau}") ytitle("") legend(off) nodraw                     ///
                    name(_xthq_g`gi', replace)
                local glist `glist' _xthq_g`gi'
            }
        }
        if (`npan' > 1) {
            graph combine `glist', cols(2)                                            ///
                title("{&tau}-quantiles of unit-specific coefficients", size(medium)) ///
                note("solid: point estimate;  dash: SQB `level'% CI (stochastic);  short-dash: CDQB `level'% CI (deterministic)", size(vsmall)) ///
                name(`gname', replace)
        }
        restore
    }

    * ------------------------------------------------------------------
    * density plot of first-step coefficients
    * ------------------------------------------------------------------
    if "`dist'" != "" {
        capture confirm matrix __xthq_first
        if _rc {
            di as txt "note: dist plot skipped (N exceeds the maximum matrix size)"
        }
        else {
            preserve
            qui drop _all
            qui svmat double __xthq_first, name(_th)
            local glist
            local gi 0
            foreach cn of local conames {
                local gi = `gi' + 1
                local xl
                forvalues t = 1/`ntab' {
                    local xl `xl' `=__xthq_est[`gi', `t']'
                }
                local ttl "`cn'"
                if "`cn'" == "_cons" local ttl "_cons (intercept)"
                twoway (kdensity _th`gi', lcolor(navy) lwidth(medthick)),             ///
                    xline(`xl', lpattern(dash) lcolor(maroon))                        ///
                    title("`ttl'", size(medium)) xtitle("first-step estimates")       ///
                    ytitle("density") ylabel(, angle(horizontal)) legend(off)         ///
                    nodraw name(_xthq_d`gi', replace)
                local glist `glist' _xthq_d`gi'
            }
            local dname "xthq_dist"
            if "`name'" != "" local dname "`name'_dist"
            graph combine `glist', cols(2)                                            ///
                title("Cross-sectional distribution of first-step coefficients", size(medium)) ///
                note("dashed lines: estimated {&tau}-quantiles at {&tau} = `tau'", size(vsmall)) ///
                name(`dname', replace)
            restore
        }
    }

    * ------------------------------------------------------------------
    * stored results
    * ------------------------------------------------------------------
    local taucols
    foreach t of local tau {
        local lab = subinstr("q" + string(`t'*100), ".", "_", .)
        local taucols `taucols' `lab'
    }

    tempname B_ SES LOS HIS PS SED LOD HID PD TAUS TBL
    matrix `B_'   = __xthq_est[1..., 1..`ntab']
    matrix `SES'  = __xthq_seS[1..., 1..`ntab']
    matrix `LOS'  = __xthq_loS[1..., 1..`ntab']
    matrix `HIS'  = __xthq_hiS[1..., 1..`ntab']
    matrix `PS'   = __xthq_pS[1..., 1..`ntab']
    matrix `SED'  = __xthq_seD[1..., 1..`ntab']
    matrix `LOD'  = __xthq_loD[1..., 1..`ntab']
    matrix `HID'  = __xthq_hiD[1..., 1..`ntab']
    matrix `PD'   = __xthq_pD[1..., 1..`ntab']
    matrix `TAUS' = `TAU'[1, 1..`ntab']
    foreach m in `B_' `SES' `LOS' `HIS' `PS' `SED' `LOD' `HID' `PD' {
        matrix rownames `m' = `conames'
        matrix colnames `m' = `taucols'
    }
    matrix colnames `TAUS' = `taucols'

    matrix `TBL' = J(`K'*`ntab', 10, .)
    local rn
    local r 0
    forvalues t = 1/`ntab' {
        local tv : word `t' of `tau'
        local eqn = subinstr("q" + string(`tv'*100), ".", "_", .)
        local p 0
        foreach cn of local conames {
            local p = `p' + 1
            local r = `r' + 1
            matrix `TBL'[`r', 1]  = `tv'
            matrix `TBL'[`r', 2]  = __xthq_est[`p', `t']
            matrix `TBL'[`r', 3]  = __xthq_seS[`p', `t']
            matrix `TBL'[`r', 4]  = __xthq_loS[`p', `t']
            matrix `TBL'[`r', 5]  = __xthq_hiS[`p', `t']
            matrix `TBL'[`r', 6]  = __xthq_pS[`p', `t']
            matrix `TBL'[`r', 7]  = __xthq_seD[`p', `t']
            matrix `TBL'[`r', 8]  = __xthq_loD[`p', `t']
            matrix `TBL'[`r', 9]  = __xthq_hiD[`p', `t']
            matrix `TBL'[`r', 10] = __xthq_pD[`p', `t']
            local rn `rn' `eqn':`cn'
        }
    }
    matrix rownames `TBL' = `rn'
    matrix colnames `TBL' = tau estimate se_sqb lb_sqb ub_sqb p_sqb se_cdqb lb_cdqb ub_cdqb p_cdqb

    return scalar N      = `Nu'
    return scalar N_drop = `ndrop'
    return scalar T_avg  = `Tavg'
    return scalar T_min  = `Tmin'
    return scalar T_max  = `Tmax'
    return scalar reps   = `reps'
    return scalar level  = `level'
    return scalar K      = `K'
    return scalar null   = `null'

    return local cmd       "xtheteroquant"
    return local depvar    "`dv'"
    return local indepvars "`xvars'"
    return local coefnames "`conames'"
    return local ivar      "`ivar'"
    return local tvar      "`tvar'"
    return local citype    "`citype'"
    return local design    "`design'"
    return local taulist   "`tau'"

    return matrix table   = `TBL'
    return matrix b       = `B_'
    return matrix se_sqb  = `SES'
    return matrix lb_sqb  = `LOS'
    return matrix ub_sqb  = `HIS'
    return matrix p_sqb   = `PS'
    return matrix se_cdqb = `SED'
    return matrix lb_cdqb = `LOD'
    return matrix ub_cdqb = `HID'
    return matrix p_cdqb  = `PD'
    return matrix taus    = `TAUS'

    tempname SM1
    matrix `SM1' = __xthq_sum1
    matrix rownames `SM1' = `conames'
    matrix colnames `SM1' = mean sd min p50 max skewness
    return matrix firststats = `SM1'

    capture confirm matrix __xthq_first
    if !_rc {
        tempname FST
        matrix `FST' = __xthq_first
        matrix colnames `FST' = `conames'
        return matrix first = `FST'
    }

    * cleanup of working objects
    foreach m in est seS loS hiS pS seD loD hiD pD sum1 phat first {
        capture matrix drop __xthq_`m'
    }
    foreach s in Nu nskip Tavg Tmin Tmax {
        capture scalar drop __xthq_`s'
    }
end


* ======================================================================
* table printer for one design
* ======================================================================
program define _xthq_ptab
    version 14.0
    args title level ntab cnames TAU EST SE LO HI P null

    di
    di as txt "{bf:`title'}"
    di as txt "{hline 23}{c TT}{hline 56}"
    di as txt "   tau     coefficient {c |}  Estimate       Boot.SE   [`level'% Conf. Interval]    P>|z|"
    di as txt "{hline 23}{c +}{hline 56}"
    forvalues t = 1/`ntab' {
        local tv = `TAU'[1, `t']
        local first 1
        local p 0
        foreach cn of local cnames {
            local p = `p' + 1
            local e_  = `EST'[`p', `t']
            local se_ = `SE'[`p', `t']
            local lo_ = `LO'[`p', `t']
            local hi_ = `HI'[`p', `t']
            local pv_ = `P'[`p', `t']
            local st ""
            if (`pv_' < .01) local st "***"
            else if (`pv_' < .05) local st "**"
            else if (`pv_' < .10) local st "*"
            if (`first') {
                di as res %6.3f `tv' as txt "  " %13s abbrev("`cn'", 13) "  {c |}" ///
                    as res %10.0g `e_' as txt %-3s "`st'" as res %10.0g `se_'      ///
                    "  " %9.0g `lo_' "  " %9.0g `hi_' "  " %7.3f `pv_'
                local first 0
            }
            else {
                di as txt %6s "" "  " %13s abbrev("`cn'", 13) "  {c |}"            ///
                    as res %10.0g `e_' as txt %-3s "`st'" as res %10.0g `se_'      ///
                    "  " %9.0g `lo_' "  " %9.0g `hi_' "  " %7.3f `pv_'
            }
        }
        if (`t' < `ntab') {
            di as txt "{hline 23}{c +}{hline 56}"
        }
    }
    di as txt "{hline 23}{c BT}{hline 56}"
    di as txt "Symmetric-tail bootstrap P, H0: theta(tau) = `null'.  * p<0.10, ** p<0.05, *** p<0.01"
end


* ======================================================================
* first-step coefficient distribution table (detail option)
* ======================================================================
program define _xthq_dtab
    version 14.0
    args cnames SM Nu

    di
    di as txt "{bf:First-step coefficient distribution across units}  (N = " as res `Nu' as txt ")"
    di as txt "{hline 15}{c TT}{hline 62}"
    di as txt "  coefficient  {c |}      mean        sd        min        p50        max      skew"
    di as txt "{hline 15}{c +}{hline 62}"
    local p 0
    foreach cn of local cnames {
        local p = `p' + 1
        di as txt %13s abbrev("`cn'", 13) "  {c |}" as res                        ///
            %10.0g `SM'[`p',1] " " %9.0g `SM'[`p',2] "  " %9.0g `SM'[`p',3]       ///
            "  " %9.0g `SM'[`p',4] "  " %9.0g `SM'[`p',5] "  " %8.3f `SM'[`p',6]
    }
    di as txt "{hline 15}{c BT}{hline 62}"
end


* ======================================================================
* Mata: first-step OLS, second-step quantiles, SQB and CDQB bootstrap
* ======================================================================
version 14.0
mata:

real scalar xthq_q(real colvector s, real scalar tau)
{
    real scalar n, j

    n = rows(s)
    j = ceil(n*tau)
    if (j < 1) j = 1
    if (j > n) j = n
    return(s[j])
}

void xthq_main(string scalar dv, string scalar xv, string scalar iv,
               string scalar touse, string scalar tauname, real scalar B,
               real scalar level, real scalar hascons, real scalar minobs,
               string scalar citype, real scalar nullv, real scalar dots,
               real scalar maxmat, string scalar gennames, string scalar obsn)
{
    real colvector y, id, Yi, Yb, s, col, u, idx, used, obs, ovec
    real matrix X, Xi, Xb, info, infoU, theta, est, thetastar
    real matrix qS, qD, seS, loS, hiS, pS, seD, loD, hiD, pD, phat, sum1
    real matrix A, XX
    real rowvector taus, gv
    real scalar n, N, K, Nu, ntau, i, ii, b, t, p, Ti, ok, k, tries
    real scalar minT, nskip, alo, ahi, qlo, qhi, Tsum, Tmin, Tmax, base, j
    real scalar m, sd, sk, r1, r2

    taus = st_matrix(tauname)
    ntau = cols(taus)

    y  = st_data(., dv, touse)
    id = st_data(., iv, touse)
    n  = rows(y)
    X  = J(n, 0, .)
    if (xv != "") X = st_data(., tokens(xv), touse)
    if (hascons) X = (X, J(n, 1, 1))
    K = cols(X)

    info = panelsetup(id, 1)
    N    = rows(info)
    minT = K + 2
    if (minobs > minT) minT = minobs

    // ---------- first step: unit-by-unit OLS ----------
    theta = J(N, K, .)
    used  = J(N, 1, 0)
    nskip = 0
    Tsum  = 0
    Tmin  = .
    Tmax  = 0
    for (i=1; i<=N; i=i+1) {
        Yi = panelsubmatrix(y, i, info)
        Xi = panelsubmatrix(X, i, info)
        Ti = rows(Yi)
        ok = 1
        if (Ti < minT) ok = 0
        if (ok) {
            XX = cross(Xi, Xi)
            A  = invsym(XX)
            for (k=1; k<=K; k=k+1) {
                if (A[k,k] <= 0) ok = 0
            }
        }
        if (ok) {
            theta[i, .] = (A*cross(Xi, Yi))'
            used[i] = 1
            Tsum = Tsum + Ti
            if (Ti < Tmin) Tmin = Ti
            if (Ti > Tmax) Tmax = Ti
        }
        if (!ok) nskip = nskip + 1
    }
    Nu = sum(used)
    if (Nu < 10) {
        errprintf("xtheteroquant: only %g usable units after screening; need at least 10\n", Nu)
        errprintf("(units need at least max(K+2, minobs()) = %g time periods and nonsingular X'X)\n", minT)
        exit(2001)
    }
    theta = select(theta, used)
    infoU = select(info, used)

    // ---------- write first-step coefficients back (gen1) ----------
    if (gennames != "") {
        gv  = st_varindex(tokens(gennames))
        obs = st_data(., obsn, touse)
        for (ii=1; ii<=Nu; ii=ii+1) {
            r1   = infoU[ii, 1]
            r2   = infoU[ii, 2]
            ovec = obs[r1::r2]
            for (p=1; p<=K; p=p+1) {
                st_store(ovec, gv[p], J(rows(ovec), 1, theta[ii, p]))
            }
        }
    }

    // ---------- second step: point estimates ----------
    est = J(K, ntau, .)
    for (p=1; p<=K; p=p+1) {
        s = sort(theta[., p], 1)
        for (t=1; t<=ntau; t=t+1) {
            est[p, t] = xthq_q(s, taus[t])
        }
    }

    // ---------- bootstrap ----------
    if (B*Nu*K*8 > 2e9) {
        errprintf("bootstrap storage too large (reps*N*K = %g cells); reduce reps()\n", B*Nu*K)
        exit(3900)
    }
    thetastar = J(B*Nu, K, .)
    qS = J(B, K*ntau, .)
    qD = J(B, K*ntau, .)

    if (dots) {
        printf("{txt}Bootstrap replications ({res}%g{txt}):\n", B)
        displayflush()
    }
    for (b=1; b<=B; b=b+1) {
        base = (b-1)*Nu
        // first-step pairs bootstrap, unit by unit (shared by SQB and CDQB)
        for (ii=1; ii<=Nu; ii=ii+1) {
            Yi = panelsubmatrix(y, ii, infoU)
            Xi = panelsubmatrix(X, ii, infoU)
            Ti = rows(Yi)
            ok = 0
            tries = 0
            while (ok == 0 & tries < 5) {
                tries = tries + 1
                idx = ceil(runiform(Ti, 1):*Ti)
                Xb  = Xi[idx, .]
                Yb  = Yi[idx]
                XX  = cross(Xb, Xb)
                A   = invsym(XX)
                ok  = 1
                for (k=1; k<=K; k=k+1) {
                    if (A[k,k] <= 0) ok = 0
                }
            }
            if (ok) {
                thetastar[base+ii, .] = (A*cross(Xb, Yb))'
            }
            if (!ok) {
                thetastar[base+ii, .] = theta[ii, .]
            }
        }
        // SQB second step: resample units, then take quantiles
        u = ceil(runiform(Nu, 1):*Nu)
        for (p=1; p<=K; p=p+1) {
            col = thetastar[base :+ u, p]
            s   = sort(col, 1)
            for (t=1; t<=ntau; t=t+1) {
                qS[b, (t-1)*K+p] = xthq_q(s, taus[t])
            }
        }
        if (dots) {
            printf("{txt}.")
            if (mod(b, 50) == 0) printf(" %5.0f\n", b)
            displayflush()
        }
    }
    if (dots) {
        if (mod(B, 50) != 0) printf("\n")
        displayflush()
    }

    // ---------- CDQB: centering probabilities, then centered quantiles ----------
    phat = J(K, ntau, .)
    for (p=1; p<=K; p=p+1) {
        for (t=1; t<=ntau; t=t+1) {
            phat[p, t] = mean(thetastar[., p] :<= est[p, t])
        }
    }
    for (b=1; b<=B; b=b+1) {
        base = (b-1)*Nu
        for (p=1; p<=K; p=p+1) {
            s = sort(thetastar[(base+1)::(base+Nu), p], 1)
            for (t=1; t<=ntau; t=t+1) {
                j = ceil(Nu*phat[p, t])
                if (j < 1) j = 1
                if (j > Nu) j = Nu
                qD[b, (t-1)*K+p] = s[j]
            }
        }
    }

    // ---------- confidence intervals, SEs and symmetric-tail p-values ----------
    alo = (1 - level/100)/2
    ahi = 1 - alo
    seS = J(K, ntau, .)
    loS = J(K, ntau, .)
    hiS = J(K, ntau, .)
    pS  = J(K, ntau, .)
    seD = J(K, ntau, .)
    loD = J(K, ntau, .)
    hiD = J(K, ntau, .)
    pD  = J(K, ntau, .)
    for (p=1; p<=K; p=p+1) {
        for (t=1; t<=ntau; t=t+1) {
            // SQB
            col = qS[., (t-1)*K+p]
            s   = sort(col, 1)
            qlo = xthq_q(s, alo)
            qhi = xthq_q(s, ahi)
            if (citype == "percentile") {
                loS[p, t] = qlo
                hiS[p, t] = qhi
            }
            if (citype != "percentile") {
                loS[p, t] = 2*est[p, t] - qhi
                hiS[p, t] = 2*est[p, t] - qlo
            }
            seS[p, t] = sqrt(variance(col))
            pS[p, t]  = mean(abs(col :- est[p, t]) :>= abs(est[p, t] - nullv))
            // CDQB
            col = qD[., (t-1)*K+p]
            s   = sort(col, 1)
            qlo = xthq_q(s, alo)
            qhi = xthq_q(s, ahi)
            if (citype == "percentile") {
                loD[p, t] = qlo
                hiD[p, t] = qhi
            }
            if (citype != "percentile") {
                loD[p, t] = 2*est[p, t] - qhi
                hiD[p, t] = 2*est[p, t] - qlo
            }
            seD[p, t] = sqrt(variance(col))
            pD[p, t]  = mean(abs(col :- est[p, t]) :>= abs(est[p, t] - nullv))
        }
    }

    // ---------- first-step distribution summary ----------
    sum1 = J(K, 6, .)
    for (p=1; p<=K; p=p+1) {
        col = theta[., p]
        m   = mean(col)
        sd  = sqrt(variance(col))
        s   = sort(col, 1)
        sum1[p, 1] = m
        sum1[p, 2] = sd
        sum1[p, 3] = s[1]
        sum1[p, 4] = xthq_q(s, .5)
        sum1[p, 5] = s[Nu]
        sk = .
        if (sd > 0) sk = mean((col :- m):^3)/(sd*sd*sd)
        sum1[p, 6] = sk
    }

    // ---------- export ----------
    st_matrix("__xthq_est",  est)
    st_matrix("__xthq_seS",  seS)
    st_matrix("__xthq_loS",  loS)
    st_matrix("__xthq_hiS",  hiS)
    st_matrix("__xthq_pS",   pS)
    st_matrix("__xthq_seD",  seD)
    st_matrix("__xthq_loD",  loD)
    st_matrix("__xthq_hiD",  hiD)
    st_matrix("__xthq_pD",   pD)
    st_matrix("__xthq_sum1", sum1)
    st_matrix("__xthq_phat", phat)
    if (Nu <= maxmat) st_matrix("__xthq_first", theta)
    st_numscalar("__xthq_Nu",    Nu)
    st_numscalar("__xthq_nskip", nskip)
    st_numscalar("__xthq_Tavg",  Tsum/Nu)
    st_numscalar("__xthq_Tmin",  Tmin)
    st_numscalar("__xthq_Tmax",  Tmax)
}

end
