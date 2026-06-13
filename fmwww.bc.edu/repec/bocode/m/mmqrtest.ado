*! mmqrtest 1.0.1  12jun2026
*! Specification and diagnostic tests for MM-QR panel quantile models
*! Machado & Santos Silva (2019, J. Econometrics) and Canay (2011, Econometrics J.)
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*! https://github.com/merwanroudane

/*===========================================================================
  mmqrtest : postestimation / standalone tests around the MM-QR
             location-scale panel quantile model

     Y_it = a_i + X_it'b + (d_i + X_it'g) U_it          [M&SS 2019, eq.(5)]
     Q_Y(tau|X_it) = (a_i + d_i q(tau)) + X_it'b + X_it'g q(tau)   [eq.(6)]

  Subcommands
     scalepos  : positivity of the fitted scale  d_i + X'g          (eq.5)
     scalerel  : Wald test of g = 0 (scale relevance ; b(tau) flat) (Thm.2)
     spec      : location-scale adequacy / overidentification test  (fn.5)
     distfe    : distributional fixed effects, H0: d_i homogeneous  (eq.6)
     canay     : Canay (2011) location-shift validity (MM-QR vs Canay)
     all       : everything + summary verdict table + dashboard

  Runs as postestimation after  mmqreg / xtqreg / qregfe  or standalone:
     mmqrtest <sub> y x1 x2 ... , id(panelvar) quantile(25 50 75) ...
===========================================================================*/

program define mmqrtest, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    local len = length("`sub'")

    if      ("`sub'"==substr("scalepos",1,max(6,`len')))      mmqrt_scalepos `0'
    else if ("`sub'"==substr("scalerel",1,max(6,`len')))      mmqrt_scalerel `0'
    else if ("`sub'"==substr("specification",1,max(4,`len'))) mmqrt_spec     `0'
    else if ("`sub'"==substr("overid",1,max(4,`len')))        mmqrt_spec     `0'
    else if ("`sub'"==substr("distfe",1,max(4,`len')))        mmqrt_distfe   `0'
    else if ("`sub'"==substr("canay",1,max(3,`len')))         mmqrt_canay    `0'
    else if ("`sub'"=="all")                                  mmqrt_all      `0'
    else if ("`sub'"=="guide") {
        help mmqrtest_guide
        exit
    }
    else {
        display as error "mmqrtest: unknown subcommand {bf:`sub'}"
        display as text  "  valid subcommands: " ///
            as result "scalepos scalerel spec distfe canay all"
        exit 198
    }
    return add
end

* ==========================================================================
* shared header
* ==========================================================================
program define _mmqrt_head
    args title
    display as text _n "{hline 70}"
    display as text "  mmqrtest : `title'"
    display as text "{hline 70}"
end

* ==========================================================================
* significance stars from a p-value
* ==========================================================================
program define _mmqrt_stars, rclass
    args p
    local s ""
    if (`p' < .10) local s "*"
    if (`p' < .05) local s "**"
    if (`p' < .01) local s "***"
    return local stars "`s'"
end

* ==========================================================================
* Parula-inspired palette (MATLAB R2014b stops) -> c_local colours
* ==========================================================================
program define _mmqrt_pal
    c_local pdeep  "53 42 135"
    c_local pblue  "15 92 188"
    c_local pcyan  "33 144 200"
    c_local pteal  "18 177 173"
    c_local pgrn   "129 203 89"
    c_local pyel   "249 190 3"
    c_local pred   "200 60 50"
end

* ==========================================================================
* _mmqrt_efetch : pull model spec from e() after mmqreg / xtqreg / qregfe
* ==========================================================================
program define _mmqrt_efetch, rclass
    version 14.0
    if ("`e(cmd)'"=="") {
        display as error "mmqrtest: no estimates in memory and no varlist given"
        display as text  "  run {helpb mmqreg}/{helpb xtqreg} first, or use:" ///
            _n "  {cmd:mmqrtest} {it:sub} {it:depvar} {it:indepvars}{cmd:, id(}{it:panelvar}{cmd:)}"
        exit 301
    }
    local cmd "`e(cmd)'"
    if (!inlist("`cmd'","mmqreg","xtqreg","qregfe")) {
        display as error "mmqrtest postestimation works after mmqreg, xtqreg or qregfe"
        display as error "  (found e(cmd) = `cmd')"
        exit 301
    }
    local y "`e(depvar)'"
    local id ""
    local qpc ""
    local xn ""

    if ("`cmd'"=="mmqreg") {
        local cn  : colnames e(b)
        local eqs : coleq e(b)
        local nc  : word count `cn'
        forvalues j = 1/`nc' {
            local nm : word `j' of `cn'
            local eq : word `j' of `eqs'
            if ("`eq'"=="location" & "`nm'"!="_cons") {
                if (strpos("`nm'","o.")==0 & strpos("`nm'","b.")==0) {
                    local xn `xn' `nm'
                }
            }
        }
        tempname qth
        capture matrix `qth' = e(qth)
        if (_rc==0) {
            local ncq = colsof(`qth')
            forvalues j = 1/`ncq' {
                local qv = `qth'[1,`j']
                if (`qv'<1) local qv = `qv'*100
                local qv = round(`qv', .01)
                local qpc `qpc' `qv'
            }
        }
        local fes "`e(fevlist)'"
        local nfe : word count `fes'
        if (`nfe'==1) local id "`fes'"
    }
    else if ("`cmd'"=="xtqreg") {
        tempname bl
        capture matrix `bl' = e(b_location)
        if (_rc) {
            display as error "mmqrtest: e(b_location) not found after xtqreg"
            exit 301
        }
        local cn : colnames `bl'
        foreach nm of local cn {
            if ("`nm'"!="_cons" & strpos("`nm'","o.")==0 & strpos("`nm'","b.")==0) {
                local xn `xn' `nm'
            }
        }
        tempname qm
        capture matrix `qm' = e(q)
        if (_rc==0) {
            local ncq = colsof(`qm')
            forvalues j = 1/`ncq' {
                local qv = `qm'[1,`j']
                if (`qv'<1) local qv = `qv'*100
                local qv = round(`qv', .01)
                local qpc `qpc' `qv'
            }
        }
    }
    else {
        * qregfe : recover varlist from e(cmdline)
        local cl `"`e(cmdline)'"'
        gettoken c1 rest : cl, parse(" ,")
        local rest : subinstr local rest "," " , ", all
        gettoken yy rest : rest
        while (`"`rest'"'!="" ) {
            gettoken tk rest : rest
            if ("`tk'"=="," | "`tk'"=="if" | "`tk'"=="in") continue, break
            local xn `xn' `tk'
        }
        local q1 "`e(quantile)'"
        if ("`q1'"!="") {
            foreach qv of numlist `q1' {
                local qq = `qv'
                if (`qq'<1) local qq = `qq'*100
                local qq = round(`qq', .01)
                local qpc `qpc' `qq'
            }
        }
        local id "`e(absorb)'"
        local nfe : word count `id'
        if (`nfe'!=1) local id ""
    }

    if ("`xn'"=="") {
        display as error "mmqrtest: could not recover regressors from e()"
        exit 301
    }
    return local cmdsrc "`cmd'"
    return local y      "`y'"
    return local xn     "`xn'"
    return local id     "`id'"
    return local qpc    "`qpc'"
end

* ==========================================================================
* _mmqrt_setup : resolve (y, x, id, quantiles, touse) for a subcommand
*    called with: anything / id() / quantile() already parsed by caller,
*    `touse' marked (novarlist). Fills touse, returns spec.
* ==========================================================================
program define _mmqrt_setup, rclass
    version 14.0
    syntax , TOUSE(varname) [ VL(string) ID(string) Quantile(string) ]
    local anything `"`vl'"'

    local post 0
    if (`"`anything'"'=="") {
        local post 1
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        _mmqrt_efetch
        local y      "`r(y)'"
        local xn     "`r(xn)'"
        local eid    "`r(id)'"
        local eqpc   "`r(qpc)'"
        local cmdsrc "`r(cmdsrc)'"
        qui replace `touse' = 0 if `esamp'!=1
    }
    else {
        gettoken y xn : anything
        local cmdsrc "standalone"
        confirm numeric variable `y'
    }

    * panel id resolution: option > e() > xtset
    if ("`id'"=="") {
        if (`post' & "`eid'"!="") {
            local id "`eid'"
        }
        else {
            capture qui xtset
            if (_rc==0) local id "`r(panelvar)'"
        }
    }
    if ("`id'"=="") {
        display as error "mmqrtest: panel variable not found"
        display as text  "  {cmd:xtset} your data or supply {cmd:id(}{it:panelvar}{cmd:)}"
        exit 459
    }
    confirm variable `id'
    local nidw : word count `id'
    if (`nidw'!=1) {
        display as error "mmqrtest: id() must contain exactly one panel variable"
        exit 198
    }

    * quantiles: option > e() > default
    local qpc ""
    if (`"`quantile'"'!="") {
        capture numlist "`quantile'", range(>0 <100) sort
        if (_rc) {
            display as error "quantile() must contain numbers strictly between 0 and 100"
            exit 125
        }
        local qpc "`r(numlist)'"
    }
    else if (`post' & "`eqpc'"!="") local qpc "`eqpc'"
    else                            local qpc "25 50 75"

    * expand factor variables to display names (drop base/omitted)
    fvexpand `xn' if `touse'
    local xall "`r(varlist)'"
    local xnames ""
    foreach t of local xall {
        if (strpos("`t'","b.")==0 & strpos("`t'","o.")==0) local xnames `xnames' `t'
    }
    if ("`xnames'"=="") {
        display as error "mmqrtest: empty regressor list after factor-variable expansion"
        exit 102
    }

    markout `touse' `y'
    markout `touse' `id', strok
    return local y      "`y'"
    return local xnames "`xnames'"
    return local id     "`id'"
    return local qpc    "`qpc'"
    return scalar post  = `post'
    return local cmdsrc "`cmdsrc'"
end

* ==========================================================================
* _mmqrt_twarn : small-T warning (fixed-T bias, M&SS Theorem 4)
* ==========================================================================
program define _mmqrt_twarn, rclass
    args id touse
    tempvar tg
    qui egen byte `tg' = tag(`id') if `touse'
    qui count if `tg'==1
    local G = r(N)
    qui count if `touse'
    local N = r(N)
    local Tbar = `N'/max(`G',1)
    return scalar G    = `G'
    return scalar N    = `N'
    return scalar Tbar = `Tbar'
    if (`Tbar' < 10) {
        display as text _n "  Note: average T per unit = " as result %5.1f `Tbar' ///
            as text " (< 10)." _n ///
            "  MM-QR objects carry O(1/T) fixed-T biases (M&SS 2019, Theorem 4);" _n ///
            "  test results may over-reject. Consider the split-panel jackknife" _n ///
            "  ({cmd:mmqreg, jknife}) and treat borderline p-values with caution."
    }
end

* ==========================================================================
* _mmqrt_core : the MM-QR sequential algorithm (M&SS 2019, sec. 3.1)
*   Step 1-2: within OLS  -> beta, alpha_i, residual R
*   Step 3-4: within OLS of |R| on X -> gamma, delta_i, sigma_it
*   Step 5  : q(tau) = tau-quantile of U = R/sigma
*   optionally the Canay (2011) two-step coefficients
* ==========================================================================
program define _mmqrt_core, rclass
    version 14.0
    syntax , Y(varname numeric) XLIST(string) ID(varname) TOUSE(varname) ///
        [ QPC(numlist) DOCANAY RESvar(string) SIGvar(string) UVAR(string) ///
          ALPHAvar(string) DELTAvar(string) ABSAvar(string) ]

    local k : word count `xlist'

    * ---------- Step 1: location, within OLS ----------
    local dlist ""
    foreach v in `y' `xlist' {
        tempvar d
        qui egen double `d' = mean(`v') if `touse', by(`id')
        qui replace `d' = `v' - `d' if `touse'
        local dlist `dlist' `d'
    }
    gettoken yd xdlist : dlist
    qui regress `yd' `xdlist' if `touse'
    tempname BL
    matrix `BL' = e(b)
    local rssw_loc = e(rss)

    tempvar xb
    qui gen double `xb' = 0 if `touse'
    forvalues j = 1/`k' {
        local xj : word `j' of `xlist'
        qui replace `xb' = `xb' + `BL'[1,`j']*`xj' if `touse'
    }

    * ---------- Step 2: alpha_i and residual ----------
    tempvar e0 al R
    qui gen double `e0' = `y' - `xb' if `touse'
    qui egen double `al' = mean(`e0') if `touse', by(`id')
    qui gen double `R'  = `e0' - `al' if `touse'

    * ---------- Step 3-4: scale, Glejser within OLS ----------
    tempvar a ad
    qui gen double `a'  = abs(`R') if `touse'
    qui egen double `ad' = mean(`a') if `touse', by(`id')
    qui replace `ad' = `a' - `ad' if `touse'
    qui regress `ad' `xdlist' if `touse'
    tempname GS
    matrix `GS' = e(b)
    local rssw_scale = e(rss)

    * pooled scale regression (common intercept) - used by distfe F test
    qui regress `a' `xlist' if `touse'
    local rssp_scale = e(rss)

    tempvar zg de sig
    qui gen double `zg' = 0 if `touse'
    forvalues j = 1/`k' {
        local xj : word `j' of `xlist'
        qui replace `zg' = `zg' + `GS'[1,`j']*`xj' if `touse'
    }
    qui egen double `de' = mean(`a' - `zg') if `touse', by(`id')
    qui gen double `sig' = `de' + `zg' if `touse'

    * ---------- standardized residuals ----------
    tempvar U
    qui gen double `U' = `R'/`sig' if `touse' & `sig'>0 & `sig'<.

    * ---------- bookkeeping ----------
    qui count if `touse'
    local N = r(N)
    qui count if `touse' & `sig'<=0
    local nneg = r(N)
    tempvar tg
    qui egen byte `tg' = tag(`id') if `touse'
    qui count if `tg'==1
    local G = r(N)
    tempvar bad tgb
    qui gen byte `bad' = (`sig'<=0) if `touse'
    qui egen double `tgb' = max(`bad') if `touse', by(`id')
    qui count if `tg'==1 & `tgb'==1
    local Gneg = r(N)
    qui sum `sig' if `touse', meanonly
    local minsig  = r(min)
    local meansig = r(mean)

    * ---------- Step 5: quantiles of U ----------
    tempname QV
    local nq : word count `qpc'
    matrix `QV' = J(1,max(`nq',1),.)
    if (`nq'>0) {
        local jq = 0
        foreach q of numlist `qpc' {
            local jq = `jq' + 1
            qui qreg `U' if `touse' & `sig'>0 & `sig'<., quantile(`q')
            matrix `QV'[1,`jq'] = _b[_cons]
        }
    }

    * ---------- MM-QR coefficients per tau:  b(tau) = b + q(tau) g ----------
    tempname BMM
    if (`nq'>0) {
        forvalues jq = 1/`nq' {
            tempname brow
            matrix `brow' = `BL'[1,1..`k'] + `QV'[1,`jq']*`GS'[1,1..`k']
            matrix `BMM' = nullmat(`BMM') \ `brow'
        }
    }

    * ---------- Canay (2011) two-step ----------
    tempname BCY
    if ("`docanay'"!="" & `nq'>0) {
        tempvar yhat
        qui gen double `yhat' = `y' - `al' if `touse'
        foreach q of numlist `qpc' {
            qui qreg `yhat' `xlist' if `touse', quantile(`q')
            tempname cb crow
            matrix `cb' = e(b)
            matrix `crow' = `cb'[1,1..`k']
            matrix `BCY' = nullmat(`BCY') \ `crow'
        }
    }

    * ---------- export optional variables ----------
    if ("`resvar'"!="")   qui replace `resvar'   = `R'   if `touse'
    if ("`sigvar'"!="")   qui replace `sigvar'   = `sig' if `touse'
    if ("`uvar'"!="")     qui replace `uvar'     = `U'   if `touse'
    if ("`alphavar'"!="") qui replace `alphavar' = `al'  if `touse'
    if ("`deltavar'"!="") qui replace `deltavar' = `de'  if `touse'
    if ("`absavar'"!="")  qui replace `absavar'  = `a'   if `touse'

    * ---------- returns ----------
    return scalar N          = `N'
    return scalar G          = `G'
    return scalar k          = `k'
    return scalar nq         = `nq'
    return scalar nneg       = `nneg'
    return scalar Gneg       = `Gneg'
    return scalar minsig     = `minsig'
    return scalar meansig    = `meansig'
    return scalar rssw_loc   = `rssw_loc'
    return scalar rssw_scale = `rssw_scale'
    return scalar rssp_scale = `rssp_scale'
    tempname BLs GSs
    matrix `BLs' = `BL'[1,1..`k']
    matrix `GSs' = `GS'[1,1..`k']
    return matrix beta  = `BLs'
    return matrix gamma = `GSs'
    if (`nq'>0)  return matrix qval = `QV'
    if (`nq'>0)  return matrix bmm  = `BMM'
    if ("`docanay'"!="" & `nq'>0) return matrix bcy = `BCY'
end

* ==========================================================================
* 1) SCALEPOS : positivity of the fitted scale  (M&SS 2019, eq.(5))
* ==========================================================================
program define mmqrt_scalepos, rclass sortpreserve
    version 14.0
    syntax [anything] [if] [in] [, Id(varname) Quantile(string) GRaph ///
        name(string) GENerate(string) noHEADer ]

    marksample touse, novarlist
    local setopts touse(`touse')
    if (`"`anything'"'!="")  local setopts `setopts' vl(`anything')
    if ("`id'"!="")          local setopts `setopts' id(`id')
    if (`"`quantile'"'!="")  local setopts `setopts' quantile(`quantile')
    _mmqrt_setup, `setopts'
    local y      "`r(y)'"
    local xnames "`r(xnames)'"
    local pid    "`r(id)'"
    local qpc    "`r(qpc)'"

    fvrevar `xnames'
    local xlist "`r(varlist)'"
    markout `touse' `xlist'

    tempname ehold
    capture _estimates hold `ehold', restore nullok

    tempvar SIG DE
    qui gen double `SIG' = .
    qui gen double `DE'  = .
    _mmqrt_core, y(`y') xlist(`xlist') id(`pid') touse(`touse') ///
        sigvar(`SIG') deltavar(`DE')
    local N      = r(N)
    local G      = r(G)
    local nneg   = r(nneg)
    local Gneg   = r(Gneg)
    local minsig = r(minsig)
    local meansig= r(meansig)
    local pctneg = 100*`nneg'/`N'

    tempvar tgu
    qui egen byte `tgu' = tag(`pid') if `touse'
    qui sum `DE' if `tgu'==1, detail
    local mindel = r(min)
    qui count if `tgu'==1 & `DE'<=0
    local ndelneg = r(N)

    if ("`header'"!="noheader") _mmqrt_head "Scale Positivity Check"
    display as text ""
    display as text "  Positivity of the fitted scale function"
    display as text "  {hline 64}"
    display as text "  Quantity                                                 Value"
    display as text "  {hline 64}"
    display as text "  Mean fitted scale                                 " ///
        as result %12.4f `meansig'
    display as text "  Minimum fitted scale                              " ///
        as result %12.4f `minsig'
    display as text "  Observations with sigma_it <= 0                   " ///
        as result %12.0fc `nneg'
    display as text "  Share of observations with sigma_it <= 0 (pct)    " ///
        as result %12.2f `pctneg'
    display as text "  Units with at least one violation                 " ///
        as result %12.0fc `Gneg'
    display as text "  Unit scale intercepts delta_i <= 0                " ///
        as result %12.0fc `ndelneg'
    display as text "  {hline 64}"
    display as text "  Observations                                      " ///
        as result %12.0fc `N'
    display as text "  Units                                             " ///
        as result %12.0fc `G'
    display as text "  {hline 64}"
    if (`nneg'==0) {
        display as text "  Decision: " as result "PASS" ///
            as text " {hline 2} the positivity condition holds in-sample."
    }
    else {
        display as text "  Decision: " as error "VIOLATION" ///
            as text " {hline 2} `nneg' observation(s) have non-positive scale."
    }
    display as text "  {hline 64}"
    display as text "  Notes: sigma_it = delta_i + X'gamma is the scale fitted by the"
    display as text "  Glejser step of the MM-QR algorithm. The model requires"
    display as text "  Pr(delta_i + X'gamma > 0) = 1 (Machado and Santos Silva 2019,"
    display as text "  eq. 5); quantile estimates relying on violating observations"
    display as text "  are unreliable, and mmqrtest excludes them from U-based tests."
    display as text "  Dependent variable: `y'. Regressors: `xnames'."
    display as text "  Panel variable: `pid'."

    if ("`graph'"!="") {
        _mmqrt_pal
        if ("`name'"=="") local name "mmqrt_scalepos"
        twoway (histogram `SIG' if `touse', percent color("`pcyan'") ///
                lcolor("`pdeep'") lwidth(vthin)), ///
            xline(0, lcolor("`pred'") lpattern(dash) lwidth(medthick)) ///
            title("Fitted scale {&sigma}{sub:it} = {&delta}{sub:i} + X'{&gamma}", ///
                  color("`pdeep'") size(medium)) ///
            subtitle("MM-QR scale positivity check", color(gs6) size(small)) ///
            xtitle("fitted scale") ytitle("percent") ///
            graphregion(color(white)) plotregion(color(white)) ///
            name(`name', replace)
    }

    if ("`generate'"!="") {
        confirm new variable `generate'_sigma `generate'_delta
        qui gen double `generate'_sigma = `SIG' if `touse'
        qui gen double `generate'_delta = `DE'  if `touse'
        label variable `generate'_sigma "MM-QR fitted scale d_i + X'g"
        label variable `generate'_delta "MM-QR unit scale intercept d_i"
    }

    return scalar N        = `N'
    return scalar G        = `G'
    return scalar nneg     = `nneg'
    return scalar pctneg   = `pctneg'
    return scalar Gneg     = `Gneg'
    return scalar minsigma = `minsig'
    return local  verdict  = cond(`nneg'==0,"PASS","VIOLATION")
end

* ==========================================================================
* 2) SCALEREL : Wald test of gamma = 0  (M&SS 2019, Theorem 2)
*    H0: scale covariates irrelevant <=> b(tau) identical across tau
* ==========================================================================
program define mmqrt_scalerel, rclass
    version 14.0
    syntax [anything] [if] [in] [, Id(varname) Quantile(string) GRaph ///
        name(string) noHEADer ]

    local fresh 0
    if (`"`anything'"'=="" & "`e(cmd)'"=="mmqreg") {
        * use the mmqreg fit already in memory (keeps user's vce choice)
    }
    else {
        local fresh 1
    }

    if (`fresh') {
        capture which mmqreg
        if (_rc) {
            display as error "mmqrtest scalerel needs {bf:mmqreg} (ssc install mmqreg)"
            exit 111
        }
        marksample touse, novarlist
        local setopts touse(`touse')
        if (`"`anything'"'!="")  local setopts `setopts' vl(`anything')
        if ("`id'"!="")          local setopts `setopts' id(`id')
        if (`"`quantile'"'!="")  local setopts `setopts' quantile(`quantile')
        _mmqrt_setup, `setopts'
        local y      "`r(y)'"
        local xnames "`r(xnames)'"
        local pid    "`r(id)'"
        local qpc    "`r(qpc)'"
        tempname ehold
        capture _estimates hold `ehold', restore nullok
        capture qui mmqreg `y' `xnames' if `touse', ///
            absorb(`pid') quantile(`qpc') cluster(`pid')
        if (_rc) {
            display as error "mmqrtest scalerel: internal mmqreg refit failed (rc=" _rc ")"
            display as text  "  the absorb() option of mmqreg requires hdfe and ftools"
            exit _rc
        }
    }

    * collect scale-equation coefficients (exclude _cons and omitted)
    local cn  : colnames e(b)
    local eqs : coleq e(b)
    local nc  : word count `cn'
    local svars ""
    forvalues j = 1/`nc' {
        local nm : word `j' of `cn'
        local eq : word `j' of `eqs'
        if ("`eq'"=="scale" & "`nm'"!="_cons") {
            if (strpos("`nm'","o.")==0 & strpos("`nm'","b.")==0) local svars `svars' `nm'
        }
    }
    if ("`svars'"=="") {
        display as error "mmqrtest scalerel: no scale coefficients found in e(b)"
        display as text  "  (after mmqreg, the {it:scale} equation must be present; do not use nols)"
        exit 303
    }

    local tl ""
    foreach v of local svars {
        local tl `tl' ([scale]`v'=0)
    }
    qui test `tl'
    local df = r(df)
    local isF 0
    if (r(chi2)<.) {
        local stat = r(chi2)
        local p    = r(p)
        local slab "chi2(`df')"
    }
    else {
        local stat = r(F)
        local p    = r(p)
        local dfr  = r(df_r)
        local slab "F(`df',`dfr')"
        local isF 1
    }

    local eN = e(N)
    local vlab "analytic (M&SS 2019, Thm. 2-3)"
    if ("`e(vcetype)'"=="Robust" & "`e(clustvar)'"=="") local vlab "heteroskedasticity-robust"
    if ("`e(clustvar)'"!="") local vlab "cluster-robust by `e(clustvar)'"
    if ("`e(jk)'"!="")       local vlab "split-panel jackknife"

    if ("`header'"!="noheader") _mmqrt_head "Scale Relevance Wald Test"
    display as text ""
    display as text "  Wald test of H0: gamma = 0 (no scale effects)"
    display as text "  {hline 64}"
    display as text "  Scale equation               Coef.        Std. err.    p-value"
    display as text "  {hline 64}"
    foreach v of local svars {
        local b  = _b[scale:`v']
        local se = _se[scale:`v']
        local z  = `b'/`se'
        local pv = 2*normal(-abs(`z'))
        _mmqrt_stars `pv'
        local st "`r(stars)'"
        local vn = abbrev("`v'",20)
        display as text "  " %-20s "`vn'" as result %12.4f `b' ///
            as text %-4s " `st'" as text "  (" as result %8.4f `se' ///
            as text ")" as result %11.4f `pv'
    }
    display as text "  {hline 64}"
    _mmqrt_stars `p'
    local jst "`r(stars)'"
    display as text "  Joint Wald `slab'" _column(44) as result %12.3f `stat' ///
        as text %-4s " `jst'"
    display as text "  p-value" _column(44) as result %12.4f `p'
    display as text "  Observations" _column(44) as result %12.0fc `eN'
    display as text "  {hline 64}"
    if (`p'<.05) {
        display as text "  Decision: " as result "REJECT H0" ///
            as text " {hline 2} quantile slopes vary across tau."
    }
    else {
        display as text "  Decision: " as result "FAIL TO REJECT H0" ///
            as text " {hline 2} quantile slopes are flat across tau."
    }
    display as text "  {hline 64}"
    display as text "  Notes: in the MM-QR model the quantile coefficients are"
    display as text "  b(tau) = b + q(tau)*gamma (Machado and Santos Silva 2019, eq. 4),"
    display as text "  so H0: gamma = 0 is equivalent to slope homogeneity across all"
    display as text "  quantiles; rejection indicates genuine distributional effects."
    display as text "  Standard errors: `vlab'."
    display as text "  * p<0.10, ** p<0.05, *** p<0.01."

    if ("`graph'"!="") {
        _mmqrt_pal
        if ("`name'"=="") local name "mmqrt_scalerel"
        tempname GM
        local ns : word count `svars'
        matrix `GM' = J(`ns',3,.)
        local j = 0
        foreach v of local svars {
            local j = `j'+1
            matrix `GM'[`j',1] = _b[scale:`v']
            matrix `GM'[`j',2] = _b[scale:`v'] - 1.96*_se[scale:`v']
            matrix `GM'[`j',3] = _b[scale:`v'] + 1.96*_se[scale:`v']
        }
        preserve
        qui clear
        qui svmat double `GM', name(gsc)
        qui gen ord = _n
        local lab ""
        local j = 0
        foreach v of local svars {
            local j = `j'+1
            local lab `lab' `j' "`v'"
        }
        twoway (rcap gsc2 gsc3 ord, horizontal lcolor("`pblue'")) ///
               (scatter ord gsc1, mcolor("`pdeep'") msymbol(D) msize(medium)) ///
            , yline(0) xline(0, lcolor("`pred'") lpattern(dash)) ///
            ylabel(`lab', angle(0) labsize(small)) ytitle("") ///
            xtitle("scale coefficient (95 percent CI)") ///
            title("Scale relevance: {&gamma} coefficients", color("`pdeep'") size(medium)) ///
            subtitle("H0: {&gamma}=0 (flat quantile slopes)", color(gs6) size(small)) ///
            legend(off) graphregion(color(white)) name(`name', replace)
        restore
    }

    return scalar stat = `stat'
    return scalar df   = `df'
    return scalar p    = `p'
    return local  slab "`slab'"
    return local  verdict = cond(`p'<.05,"REJECT","NOT REJECTED")
end

* ==========================================================================
* 3) SPEC : location-scale adequacy / overidentification test
*    (M&SS 2019, footnote 5 + conclusion: orthogonality between functions
*     of U and functions of the regressors; regression-based version)
* ==========================================================================
program define mmqrt_spec, rclass sortpreserve
    version 14.0
    syntax [anything] [if] [in] [, Id(varname) Quantile(string) AUX(varlist numeric) ///
        GRaph name(string) noHEADer ]

    marksample touse, novarlist
    local setopts touse(`touse')
    if (`"`anything'"'!="")  local setopts `setopts' vl(`anything')
    if ("`id'"!="")          local setopts `setopts' id(`id')
    if (`"`quantile'"'!="")  local setopts `setopts' quantile(`quantile')
    _mmqrt_setup, `setopts'
    local y      "`r(y)'"
    local xnames "`r(xnames)'"
    local pid    "`r(id)'"
    local qpc    "`r(qpc)'"

    fvrevar `xnames'
    local xlist "`r(varlist)'"
    markout `touse' `xlist'
    if ("`aux'"!="") markout `touse' `aux'

    tempname ehold
    capture _estimates hold `ehold', restore nullok

    tempvar U SIG R
    qui gen double `U'   = .
    qui gen double `SIG' = .
    qui gen double `R'   = .
    _mmqrt_core, y(`y') xlist(`xlist') id(`pid') touse(`touse') qpc(`qpc') ///
        uvar(`U') sigvar(`SIG') resvar(`R')
    local N    = r(N)
    local G    = r(G)
    local k    = r(k)
    local nq   = r(nq)
    local nneg = r(nneg)
    tempname QV
    matrix `QV' = r(qval)

    tempvar use2
    qui gen byte `use2' = (`touse' & `SIG'>0 & `SIG'<.)

    * ---------- build auxiliary functions w(X) ----------
    local wlist ""
    local wnames ""
    if ("`aux'"!="") {
        local wlist "`aux'"
        local wnames "`aux'"
    }
    else {
        forvalues i = 1/`k' {
            local xi : word `i' of `xlist'
            local ni : word `i' of `xnames'
            tempvar w
            qui gen double `w' = `xi'*`xi' if `use2'
            local wlist `wlist' `w'
            local wnames `wnames' `ni'^2
        }
        if (`k'<=4 & `k'>1) {
            forvalues i = 1/`k' {
                local i2 = `i'+1
                forvalues j = `i2'/`k' {
                    local xi : word `i' of `xlist'
                    local xj : word `j' of `xlist'
                    local ni : word `i' of `xnames'
                    local nj : word `j' of `xnames'
                    tempvar w
                    qui gen double `w' = `xi'*`xj' if `use2'
                    local wlist `wlist' `w'
                    local wnames `wnames' `ni'x`nj'
                }
            }
        }
    }
    local nw : word count `wlist'

    * ---------- moment block A : E[ w(X) U ] = 0  (location adequacy) ----------
    qui regress `U' `wlist' `xlist' if `use2', vce(cluster `pid')
    qui testparm `wlist'
    local FA  = r(F)
    local dfA = r(df)
    local pA  = r(p)

    * ---------- moment block B : E[ w(X)(|U|-1) ] = 0  (scale adequacy) ----------
    tempvar au
    qui gen double `au' = abs(`U') if `use2'
    qui regress `au' `wlist' `xlist' if `use2', vce(cluster `pid')
    qui testparm `wlist'
    local FB  = r(F)
    local dfB = r(df)
    local pB  = r(p)

    * ---------- moment block C : quantile orthogonality per tau ----------
    *  E[ w(X)( tau - I{U <= q(tau)} ) ] = 0  beyond location/scale
    tempname CT
    matrix `CT' = J(`nq',3,.)
    local jq = 0
    local pCmin = 1
    foreach q of numlist `qpc' {
        local jq = `jq'+1
        local qv = `QV'[1,`jq']
        tempvar psi
        qui gen double `psi' = (`q'/100) - (`U' <= `qv') if `use2'
        qui regress `psi' `wlist' `xlist' if `use2', vce(cluster `pid')
        qui testparm `wlist'
        matrix `CT'[`jq',1] = `q'
        matrix `CT'[`jq',2] = r(F)
        matrix `CT'[`jq',3] = r(p)
        if (r(p)<`pCmin') local pCmin = r(p)
        drop `psi'
    }
    local pC = min(1, `nq'*`pCmin')

    * ---------- combined (Bonferroni over the three blocks) ----------
    local pcomb = min(1, 3*min(`pA',`pB',`pC'))

    if ("`header'"!="noheader") _mmqrt_head "Location-Scale Specification Test"
    display as text ""
    display as text "  Orthogonality between functions of U and functions of X"
    display as text "  {hline 64}"
    display as text "  Moment block                          F       df      p-value"
    display as text "  {hline 64}"
    _mmqrt_stars `pA'
    display as text "  A. Location: E[w(X)U] = 0     " ///
        as result %10.3f `FA' as text "  " as result %5.0f `dfA' ///
        as result %13.4f `pA' as text %-4s " `r(stars)'"
    _mmqrt_stars `pB'
    display as text "  B. Scale: E[w(X)(|U|-1)] = 0  " ///
        as result %10.3f `FB' as text "  " as result %5.0f `dfB' ///
        as result %13.4f `pB' as text %-4s " `r(stars)'"
    forvalues jq = 1/`nq' {
        local qq = `CT'[`jq',1]
        local Fq = `CT'[`jq',2]
        local pq = `CT'[`jq',3]
        _mmqrt_stars `pq'
        display as text "  C. Quantile, tau = 0." %02.0f `qq' "       " ///
            as result %10.3f `Fq' as text "  " as result %5.0f `dfA' ///
            as result %13.4f `pq' as text %-4s " `r(stars)'"
    }
    display as text "  {hline 64}"
    _mmqrt_stars `pcomb'
    display as text "  Overall (Bonferroni, A/B/C)" _column(46) ///
        as result %12.4f `pcomb' as text %-4s " `r(stars)'"
    display as text "  Observations" _column(46) as result %12.0fc `N'
    display as text "  Units" _column(46) as result %12.0fc `G'
    display as text "  {hline 64}"
    if (`pcomb'<.05) {
        display as text "  Decision: " as result "REJECT H0" ///
            as text " {hline 2} evidence against the location-scale family."
    }
    else {
        display as text "  Decision: " as result "FAIL TO REJECT H0" ///
            as text " {hline 2} the location-scale restriction stands."
    }
    display as text "  {hline 64}"
    display as text "  Notes: H0 states that regressors affect Y only through the"
    display as text "  location and scale functions, i.e. the standardized error"
    display as text "  U = (Y - a_i - X'b)/(d_i + X'g) is independent of X. The blocks"
    display as text "  test the overidentifying orthogonality conditions suggested in"
    display as text "  Machado and Santos Silva (2019, fn. 5 and sec. 7), via Wald tests"
    display as text "  of w(X) in auxiliary regressions that control for X, with"
    display as text "  standard errors clustered by `pid'. Auxiliary functions w(X):"
    display as text "  `wnames'."
    if (`nneg'>0) {
        display as text "  `nneg' observation(s) with non-positive fitted scale excluded."
    }
    display as text "  The Bonferroni combination is conservative."
    display as text "  * p<0.10, ** p<0.05, *** p<0.01."

    if ("`graph'"!="") {
        _mmqrt_pal
        if ("`name'"=="") local name "mmqrt_spec"
        preserve
        qui clear
        local nrow = 2 + `nq'
        qui set obs `nrow'
        qui gen double pval = .
        qui gen ord = _n
        qui replace pval = `pA' in 1
        qui replace pval = `pB' in 2
        local lab `"1 "A: location" 2 "B: scale""'
        forvalues jq = 1/`nq' {
            local rw = 2 + `jq'
            local pq = `CT'[`jq',3]
            local qq = round(`CT'[`jq',1])
            qui replace pval = `pq' in `rw'
            local lab `"`lab' `rw' "C: q`qq'""'
        }
        twoway (bar pval ord, barwidth(.6) color("`pteal'") lcolor("`pdeep'")) ///
            , yline(.05, lcolor("`pred'") lpattern(dash) lwidth(medthick)) ///
            xlabel(`lab', angle(25) labsize(small)) ///
            ytitle("p-value") xtitle("") ///
            title("Location-scale specification: moment blocks", ///
                  color("`pdeep'") size(medium)) ///
            subtitle("dashed line = 0.05; bars below it reject H0", ///
                  color(gs6) size(small)) ///
            legend(off) graphregion(color(white)) name(`name', replace)
        restore
    }

    return scalar F_loc   = `FA'
    return scalar p_loc   = `pA'
    return scalar F_scale = `FB'
    return scalar p_scale = `pB'
    return scalar p_quant = `pC'
    return scalar df_w    = `dfA'
    return scalar p       = `pcomb'
    matrix colnames `CT' = tau F p
    return matrix qtests  = `CT'
    return local  verdict = cond(`pcomb'<.05,"REJECT","NOT REJECTED")
end

* ==========================================================================
* 4) DISTFE : distributional fixed effects test
*    H0: d_i = d for all i  (individual effects are pure location shifters)
*    F test of unit effects in the Glejser scale regression |R| on X
* ==========================================================================
program define mmqrt_distfe, rclass sortpreserve
    version 14.0
    syntax [anything] [if] [in] [, Id(varname) Quantile(string) GRaph ///
        name(string) GENerate(string) noHEADer ]

    marksample touse, novarlist
    local setopts touse(`touse')
    if (`"`anything'"'!="")  local setopts `setopts' vl(`anything')
    if ("`id'"!="")          local setopts `setopts' id(`id')
    if (`"`quantile'"'!="")  local setopts `setopts' quantile(`quantile')
    _mmqrt_setup, `setopts'
    local y      "`r(y)'"
    local xnames "`r(xnames)'"
    local pid    "`r(id)'"
    local qpc    "`r(qpc)'"

    fvrevar `xnames'
    local xlist "`r(varlist)'"
    markout `touse' `xlist'

    tempname ehold
    capture _estimates hold `ehold', restore nullok

    tempvar DE AL
    qui gen double `DE' = .
    qui gen double `AL' = .
    _mmqrt_core, y(`y') xlist(`xlist') id(`pid') touse(`touse') ///
        deltavar(`DE') alphavar(`AL')
    local N    = r(N)
    local G    = r(G)
    local k    = r(k)
    local rssw = r(rssw_scale)
    local rssp = r(rssp_scale)

    _mmqrt_twarn `pid' `touse'

    * F test: pooled (common intercept) vs unit-specific intercepts in the
    * scale regression -- classical FE-equality F statistic
    local df1 = `G' - 1
    local df2 = `N' - `G' - `k'
    if (`df2'<=0) {
        display as error "mmqrtest distfe: not enough degrees of freedom (N-G-k <= 0)"
        exit 2001
    }
    local F = ((`rssp'-`rssw')/`df1') / (`rssw'/`df2')
    local p = Ftail(`df1',`df2',`F')

    * descriptives of d_i and corr(a_i, d_i) on one obs per unit
    tempvar tg
    qui egen byte `tg' = tag(`pid') if `touse'
    qui sum `DE' if `tg'==1, detail
    local sdd  = r(sd)
    local mind = r(min)
    local maxd = r(max)
    local medd = r(p50)
    qui corr `AL' `DE' if `tg'==1
    local rho = r(rho)

    if ("`header'"!="noheader") _mmqrt_head "Distributional Fixed-Effects Test"
    display as text ""
    display as text "  Homogeneity of the scale fixed effects, H0: delta_i = delta"
    display as text "  {hline 64}"
    display as text "  Panel A. Distribution of the estimated delta_i"
    display as text "  {hline 64}"
    display as text "  Standard deviation" _column(46) as result %12.4f `sdd'
    display as text "  Median" _column(46) as result %12.4f `medd'
    display as text "  Minimum" _column(46) as result %12.4f `mind'
    display as text "  Maximum" _column(46) as result %12.4f `maxd'
    display as text "  Correlation with location effects alpha_i" _column(46) ///
        as result %12.4f `rho'
    display as text "  {hline 64}"
    display as text "  Panel B. Fixed-effects equality test"
    display as text "  {hline 64}"
    _mmqrt_stars `p'
    display as text "  F(`df1', `df2')" _column(46) as result %12.3f `F' ///
        as text %-4s " `r(stars)'"
    display as text "  p-value" _column(46) as result %12.4f `p'
    display as text "  Observations" _column(46) as result %12.0fc `N'
    display as text "  Units" _column(46) as result %12.0fc `G'
    display as text "  {hline 64}"
    if (`p'<.05) {
        display as text "  Decision: " as result "REJECT H0" ///
            as text " {hline 2} fixed effects are distributional."
    }
    else {
        display as text "  Decision: " as result "FAIL TO REJECT H0" ///
            as text " {hline 2} fixed effects are location shifters."
    }
    display as text "  {hline 64}"
    display as text "  Notes: in MM-QR the quantile-tau fixed effect of unit i is"
    display as text "  a_i(tau) = a_i + d_i*q(tau) (Machado and Santos Silva 2019,"
    display as text "  eq. 6). Homogeneous d_i means individual effects shift every"
    display as text "  quantile equally (pure location shifters, as assumed by Koenker"
    display as text "  2004 and Canay 2011); heterogeneous d_i means they also move"
    display as text "  dispersion and tails, and location-shift estimators are"
    display as text "  inconsistent. F compares pooled vs unit intercepts in the"
    display as text "  Glejser regression of |R_it| on the regressors."
    display as text "  * p<0.10, ** p<0.05, *** p<0.01."

    if ("`graph'"!="") {
        _mmqrt_pal
        if ("`name'"=="") local name "mmqrt_distfe"
        tempname gh1 gh2
        twoway (histogram `DE' if `tg'==1, percent color("`pteal'") ///
                lcolor("`pdeep'") lwidth(vthin)), ///
            title("Scale fixed effects {&delta}{sub:i}", color("`pdeep'") size(medium)) ///
            xtitle("{&delta}{sub:i}") ytitle("percent of units") ///
            graphregion(color(white)) name(`name'_h, replace) nodraw
        twoway (scatter `DE' `AL' if `tg'==1, mcolor("`pcyan'") msize(small)) ///
               (lfit `DE' `AL' if `tg'==1, lcolor("`pred'") lpattern(dash)) ///
            , title("Location vs scale fixed effects", color("`pdeep'") size(medium)) ///
            subtitle("each dot = one unit", color(gs6) size(small)) ///
            xtitle("location effect {&alpha}{sub:i}") ytitle("scale effect {&delta}{sub:i}") ///
            legend(off) graphregion(color(white)) name(`name'_s, replace) nodraw
        graph combine `name'_h `name'_s, rows(1) graphregion(color(white)) ///
            title("Distributional fixed effects", color("`pdeep'") size(medium)) ///
            name(`name', replace)
    }

    if ("`generate'"!="") {
        confirm new variable `generate'_alpha `generate'_delta
        qui gen double `generate'_alpha = `AL' if `touse'
        qui gen double `generate'_delta = `DE' if `touse'
        label variable `generate'_alpha "MM-QR location fixed effect a_i"
        label variable `generate'_delta "MM-QR scale fixed effect d_i"
    }

    return scalar F        = `F'
    return scalar df1      = `df1'
    return scalar df2      = `df2'
    return scalar p        = `p'
    return scalar sd_delta = `sdd'
    return scalar corr_ad  = `rho'
    return scalar G        = `G'
    return scalar N        = `N'
    return local  verdict  = cond(`p'<.05,"REJECT","NOT REJECTED")
end

* ==========================================================================
* 5) CANAY : Canay (2011) location-shift validity
*    Hausman-type contrast between Canay two-step and MM-QR coefficients,
*    cluster (pairs) bootstrap over units; plus the distfe evidence.
* ==========================================================================
program define mmqrt_canay, rclass sortpreserve
    version 14.0
    syntax [anything] [if] [in] [, Id(varname) Quantile(string) Reps(integer 200) ///
        SEED(string) GRaph name(string) PVAR(string) noHEADer noDOTs ]

    marksample touse, novarlist
    local setopts touse(`touse')
    if (`"`anything'"'!="")  local setopts `setopts' vl(`anything')
    if ("`id'"!="")          local setopts `setopts' id(`id')
    if (`"`quantile'"'!="")  local setopts `setopts' quantile(`quantile')
    _mmqrt_setup, `setopts'
    local y      "`r(y)'"
    local xnames "`r(xnames)'"
    local pid    "`r(id)'"
    local qpc    "`r(qpc)'"

    fvrevar `xnames'
    local xlist "`r(varlist)'"
    markout `touse' `xlist'
    if (`reps'<50) {
        display as text "  note: reps() raised to 50 (minimum for a bootstrap VCV)"
        local reps 50
    }
    if ("`seed'"!="") set seed `seed'

    tempname ehold
    capture _estimates hold `ehold', restore nullok

    * ---------- full-sample estimates ----------
    _mmqrt_core, y(`y') xlist(`xlist') id(`pid') touse(`touse') qpc(`qpc') docanay
    local N  = r(N)
    local G  = r(G)
    local k  = r(k)
    local nq = r(nq)
    tempname BMM BCY QVF
    matrix `BMM' = r(bmm)
    matrix `BCY' = r(bcy)
    matrix `QVF' = r(qval)

    _mmqrt_twarn `pid' `touse'

    * ---------- cluster (pairs) bootstrap over units ----------
    local kq = `k'*`nq'
    tempname DB MMB CYB
    matrix `DB'  = J(`reps',`kq',.)
    matrix `MMB' = J(`reps',`kq',.)
    matrix `CYB' = J(`reps',`kq',.)

    display as text _n "  pairs cluster bootstrap over `G' units, " ///
        as result "`reps'" as text " replications"
    tempfile basef
    preserve
    qui keep if `touse'
    keep `y' `xlist' `pid'
    tempvar one
    qui gen byte `one' = 1
    qui save `basef', replace

    local bok = 0
    forvalues b = 1/`reps' {
        qui use `basef', clear
        tempvar nid
        qui bsample, cluster(`pid') idcluster(`nid')
        capture {
            _mmqrt_core, y(`y') xlist(`xlist') id(`nid') touse(`one') ///
                qpc(`qpc') docanay
            tempname bm bc
            matrix `bm' = r(bmm)
            matrix `bc' = r(bcy)
        }
        if (_rc==0) {
            local bok = `bok' + 1
            forvalues jq = 1/`nq' {
                forvalues i = 1/`k' {
                    local cc = (`jq'-1)*`k' + `i'
                    matrix `MMB'[`bok',`cc'] = `bm'[`jq',`i']
                    matrix `CYB'[`bok',`cc'] = `bc'[`jq',`i']
                    matrix `DB'[`bok',`cc']  = `bc'[`jq',`i'] - `bm'[`jq',`i']
                }
            }
        }
        if ("`dots'"!="nodots") {
            if (mod(`b',10)==0) display as text "." _continue
            if (mod(`b',500)==0) display as text " `b'"
        }
    }
    restore
    if ("`dots'"!="nodots") display as text " done (`bok' successful)"
    if (`bok' < 30) {
        display as error "mmqrtest canay: too few successful bootstrap replications (`bok')"
        exit 2001
    }
    tempname DBu MMBu CYBu
    matrix `DBu'  = `DB'[1..`bok',1...]
    matrix `MMBu' = `MMB'[1..`bok',1...]
    matrix `CYBu' = `CYB'[1..`bok',1...]
    matrix drop `DB' `MMB' `CYB'

    * bootstrap covariance of the contrast
    mata: _mmqrt_bvar("`DBu'", "__mmqrt_VD")
    mata: _mmqrt_bvar("`MMBu'", "__mmqrt_VM")
    mata: _mmqrt_bvar("`CYBu'", "__mmqrt_VC")
    tempname VD VM VC
    matrix `VD' = __mmqrt_VD
    matrix `VM' = __mmqrt_VM
    matrix `VC' = __mmqrt_VC
    capture matrix drop __mmqrt_VD __mmqrt_VM __mmqrt_VC

    * ---------- per-tau Hausman-type Wald ----------
    tempname HT
    matrix `HT' = J(`nq',4,.)
    local pmin = 1
    forvalues jq = 1/`nq' {
        local c1 = (`jq'-1)*`k' + 1
        local c2 = `jq'*`k'
        tempname dj vj vij
        matrix `dj'  = (`BCY'[`jq',1...] - `BMM'[`jq',1...])
        matrix `vj'  = `VD'[`c1'..`c2', `c1'..`c2']
        matrix `vij' = invsym(`vj')
        local dfj = `k' - diag0cnt(`vij')
        tempname w2
        matrix `w2' = `dj' * `vij' * `dj''
        local chi = `w2'[1,1]
        local pj  = chi2tail(`dfj', `chi')
        local qq : word `jq' of `qpc'
        matrix `HT'[`jq',1] = `qq'
        matrix `HT'[`jq',2] = `chi'
        matrix `HT'[`jq',3] = `dfj'
        matrix `HT'[`jq',4] = `pj'
        if (`pj'<`pmin') local pmin = `pj'
    }
    local pall = min(1, `nq'*`pmin')

    if ("`header'"!="noheader") _mmqrt_head "Canay (2011) Location-Shift Validity Test"
    display as text ""
    display as text "  Hausman-type contrast: Canay two-step vs MM-QR slopes"
    display as text "  {hline 64}"
    display as text "  Quantile                    chi2       df         p-value"
    display as text "  {hline 64}"
    forvalues jq = 1/`nq' {
        local qq  = `HT'[`jq',1]
        local ch  = `HT'[`jq',2]
        local dfj = `HT'[`jq',3]
        local pj  = `HT'[`jq',4]
        _mmqrt_stars `pj'
        display as text "  tau = 0." %02.0f `qq' "     " ///
            as result %14.3f `ch' as text "  " as result %5.0f `dfj' ///
            as result %14.4f `pj' as text %-4s " `r(stars)'"
    }
    display as text "  {hline 64}"
    _mmqrt_stars `pall'
    display as text "  Overall (Bonferroni across tau)" _column(46) ///
        as result %12.4f `pall' as text %-4s " `r(stars)'"
    display as text "  Bootstrap replications" _column(46) as result %12.0fc `bok'
    display as text "  Units resampled" _column(46) as result %12.0fc `G'
    display as text "  {hline 64}"
    if (`pall'<.05) {
        display as text "  Decision: " as result "REJECT H0" ///
            as text " {hline 2} the location-shift assumption fails."
    }
    else {
        display as text "  Decision: " as result "FAIL TO REJECT H0" ///
            as text " {hline 2} Canay's transformation is not contradicted."
    }
    display as text "  {hline 64}"
    display as text "  Notes: Canay (2011) assumes fixed effects are pure location"
    display as text "  shifters (they move every quantile equally). Under H0 the Canay"
    display as text "  two-step and MM-QR slopes share the same probability limit;"
    display as text "  under heterogeneous scale effects Canay is inconsistent (Machado"
    display as text "  and Santos Silva 2019, fn. 17). The contrast Delta(tau) ="
    display as text "  theta_Canay(tau) - b_MMQR(tau) is evaluated with a covariance"
    display as text "  matrix from a pairs cluster bootstrap resampling whole units."
    display as text "  Rejection here typically pairs with rejection in"
    display as text "  {helpb mmqrtest_distfe:mmqrtest distfe}, its structural cause."
    display as text "  * p<0.10, ** p<0.05, *** p<0.01."

    * ---------- comparison graph ----------
    if ("`graph'"!="") {
        _mmqrt_pal
        if ("`name'"=="") local name "mmqrt_canay"
        local pv 1
        if ("`pvar'"!="") {
            local pv 0
            local j = 0
            foreach nmx of local xnames {
                local j = `j'+1
                if ("`nmx'"=="`pvar'") local pv `j'
            }
            if (`pv'==0) {
                display as text "  note: pvar(`pvar') not found, plotting first regressor"
                local pv 1
            }
        }
        local pnm : word `pv' of `xnames'
        preserve
        qui clear
        qui set obs `nq'
        qui gen double tau  = .
        qui gen double tau2 = .
        qui gen double bmm = .
        qui gen double bcy = .
        qui gen double mlo = .
        qui gen double mhi = .
        qui gen double clo = .
        qui gen double cup = .
        forvalues jq = 1/`nq' {
            local cc = (`jq'-1)*`k' + `pv'
            local qq : word `jq' of `qpc'
            qui replace tau  = `qq'/100 in `jq'
            qui replace tau2 = `qq'/100 + .012 in `jq'
            qui replace bmm = `BMM'[`jq',`pv'] in `jq'
            qui replace bcy = `BCY'[`jq',`pv'] in `jq'
            local sm = sqrt(`VM'[`cc',`cc'])
            local sc = sqrt(`VC'[`cc',`cc'])
            qui replace mlo = `BMM'[`jq',`pv'] - 1.96*`sm' in `jq'
            qui replace mhi = `BMM'[`jq',`pv'] + 1.96*`sm' in `jq'
            qui replace clo = `BCY'[`jq',`pv'] - 1.96*`sc' in `jq'
            qui replace cup = `BCY'[`jq',`pv'] + 1.96*`sc' in `jq'
        }
        twoway (rcap mlo mhi tau,  lcolor("`pblue'") lwidth(medthick)) ///
               (rcap clo cup tau2, lcolor("`pred'")  lwidth(medthick)) ///
               (connected bmm tau,  lcolor("`pblue'") mcolor("`pdeep'") msymbol(O)) ///
               (connected bcy tau2, lcolor("`pred'")  mcolor("`pred'") msymbol(T) lpattern(dash)) ///
            , title("MM-QR vs Canay: `pnm'", color("`pdeep'") size(medium)) ///
            subtitle("bootstrap 95 percent CIs (pairs cluster bootstrap)", ///
                color(gs6) size(small)) ///
            xtitle("quantile {&tau}") ytitle("coefficient") ///
            legend(order(3 "MM-QR" 4 "Canay") rows(1) region(lstyle(none))) ///
            graphregion(color(white)) name(`name', replace)
        restore
    }

    local rnm ""
    foreach q of numlist `qpc' {
        local qi = round(`q')
        local rnm `rnm' q`qi'
    }
    matrix rownames `HT' = `rnm'
    matrix colnames `HT' = tau chi2 df p
    return matrix htests = `HT'
    tempname BMMr BCYr
    matrix `BMMr' = `BMM'
    matrix `BCYr' = `BCY'
    matrix colnames `BMMr' = `xnames'
    matrix colnames `BCYr' = `xnames'
    return matrix b_mmqr = `BMMr'
    return matrix b_canay = `BCYr'
    return scalar p     = `pall'
    return scalar reps  = `bok'
    return scalar G     = `G'
    return local  verdict = cond(`pall'<.05,"REJECT","NOT REJECTED")
end

* ==========================================================================
* 6) ALL : full battery + verdict summary + dashboard
* ==========================================================================
program define mmqrt_all, rclass
    version 14.0
    syntax [anything] [if] [in] [, Id(varname) Quantile(string) AUX(varlist numeric) ///
        Reps(integer 200) SEED(string) GRaph name(string) noDOTs ]

    local pass1 ""
    if ("`id'"!="")       local pass1 `pass1' id(`id')
    if (`"`quantile'"'!="") local pass1 `pass1' quantile(`quantile')
    local ifin ""
    if (`"`if'"'!="") local ifin `ifin' `if'
    if (`"`in'"'!="") local ifin `ifin' `in'
    local gopt ""
    if ("`graph'"!="") local gopt graph
    local base "mmqrt"
    if ("`name'"!="") local base "`name'"

    display as text _n "{hline 70}"
    display as result "  mmqrtest : FULL DIAGNOSTIC BATTERY FOR THE MM-QR MODEL"
    display as text "  Machado & Santos Silva (2019); Canay (2011)"
    display as text "{hline 70}"

    mmqrt_scalepos `anything' `ifin', `pass1' `gopt' name(`base'_d1)
    local v1   "`r(verdict)'"
    local s1   = r(pctneg)
    local nneg = r(nneg)

    mmqrt_scalerel `anything' `ifin', `pass1' `gopt' name(`base'_d2)
    local v2 "`r(verdict)'"
    local s2 = r(stat)
    local p2 = r(p)
    local l2 "`r(slab)'"

    local aopt ""
    if ("`aux'"!="") local aopt aux(`aux')
    mmqrt_spec `anything' `ifin', `pass1' `gopt' name(`base'_d3) `aopt'
    local v3 "`r(verdict)'"
    local p3 = r(p)

    mmqrt_distfe `anything' `ifin', `pass1' `gopt' name(`base'_d4)
    local v4 "`r(verdict)'"
    local s4 = r(F)
    local p4 = r(p)

    local ropt ""
    if ("`seed'"!="") local ropt seed(`seed')
    mmqrt_canay `anything' `ifin', `pass1' `gopt' name(`base'_d5) ///
        reps(`reps') `ropt' `dots'
    local v5 "`r(verdict)'"
    local p5 = r(p)

    display as text _n "{hline 70}"
    display as result "  SUMMARY OF VERDICTS"
    display as text "{hline 70}"
    display as text ""
    display as text "  Diagnostic battery for the MM-QR location-scale panel model"
    display as text "  {hline 66}"
    display as text "  No. Test                          Statistic    p-value    Verdict"
    display as text "  {hline 66}"
    display as text "  1   Scale positivity        " ///
        as result %9.2f `s1' as text " pct" _column(48) as text "  --     " ///
        as result "`v1'"
    display as text "  2   Scale relevance         " ///
        as result %13.3f `s2' _column(44) as result %9.4f `p2' ///
        as text "    " as result "`v2'"
    display as text "  3   Location-scale spec." _column(44) ///
        as result %9.4f `p3' as text "    " as result "`v3'"
    display as text "  4   Distributional FE       " ///
        as result %13.3f `s4' _column(44) as result %9.4f `p4' ///
        as text "    " as result "`v4'"
    display as text "  5   Canay location shift" _column(44) ///
        as result %9.4f `p5' as text "    " as result "`v5'"
    display as text "  {hline 66}"
    display as text "  Notes: (1) positivity of the fitted scale, share of violating"
    display as text "  observations (must PASS for any MM-QR output to be reliable);"
    display as text "  (2) Wald test of H0: gamma = 0, rejection means quantile slopes"
    display as text "  genuinely vary with tau; (3) overidentification test of the"
    display as text "  location-scale family itself, rejection questions MM-QR;"
    display as text "  (4) H0: delta_i homogeneous and (5) H0: location-shift fixed"
    display as text "  effects {hline 2} rejection of either favours MM-QR over"
    display as text "  Canay-type estimators. See {helpb mmqrtest_guide:mmqrtest guide}"
    display as text "  for detailed interpretation."
    display as text "{hline 70}"

    if ("`graph'"!="") {
        capture graph combine `base'_d1 `base'_d2 `base'_d3 `base'_d4 `base'_d5, ///
            rows(2) graphregion(color(white)) ///
            title("mmqrtest diagnostic dashboard", color("53 42 135")) ///
            name(`base'_dash, replace)
        if (_rc) display as text "  (dashboard combine skipped, rc=" _rc ")"
        else {
            display as text "  Graphs kept in memory: " ///
                as result "`base'_d1 ... `base'_d5, `base'_dash"
            display as text "  View any of them with: " ///
                as result "graph display `base'_d1" as text " etc."
        }
    }

    return scalar pctneg     = `s1'
    return scalar nneg       = `nneg'
    return scalar p_scalerel = `p2'
    return scalar p_spec     = `p3'
    return scalar p_distfe   = `p4'
    return scalar p_canay    = `p5'
    return local  v_scalepos "`v1'"
    return local  v_scalerel "`v2'"
    return local  v_spec     "`v3'"
    return local  v_distfe   "`v4'"
    return local  v_canay    "`v5'"
end

* ==========================================================================
* Mata helper: bootstrap covariance
* ==========================================================================
mata:
void _mmqrt_bvar(string scalar din, string scalar vout)
{
    real matrix D
    D = st_matrix(din)
    st_matrix(vout, variance(D))
}
end
