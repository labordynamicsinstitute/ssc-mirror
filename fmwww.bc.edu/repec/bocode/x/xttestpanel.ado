*! xttestpanel 1.0.0  09jun2026
*! Post-estimation diagnostic test suite for linear panel-data models
*! Author: Merwan Roudane  <merwanroudane920@gmail.com>
*! GitHub: https://github.com/merwanroudane
*!
*! Implements:
*!   het      Heteroskedasticity     Juhl & Sosa-Escudero (2014) FE; Holly-Gardiol RE;
*!                                    Feng, Li, Tong & Luo (2020) two-way FE
*!   serial   Serial correlation     Baltagi & Li (1995) / Baltagi, Jung & Song (2010);
*!                                    Bin Chen (2022) robust; Wooldridge (2002)
*!   csd      Cross-section depend.   Pesaran (2004) CD; Baltagi, Kao & Peng (2016)
*!                                    bias-corrected CD; Breusch-Pagan (1980) LM
*!   func     Functional form        Lin, Li & Sun (2014) nonparametric FE test
*!   hausman  Specification          classical Hausman; Beyaztas et al. (2021) robust
*!   vif      Multicollinearity      within-group VIF; Ismaeel, Midi & Sani (2021) RVIF
*!   all      Run the whole suite and print a combined report (+ optional dashboard)

program define xttestpanel, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    if ("`sub'"=="" | substr("`sub'",1,1)==",") {
        di as error "subcommand required"
        di as error "{p 4 8 2}valid subcommands: " ///
            "{bf:het}, {bf:serial}, {bf:csd}, {bf:func}, {bf:hausman}, {bf:vif}, {bf:all}{p_end}"
        di as error "see {help xttestpanel}"
        exit 198
    }
    local l = length("`sub'")
    if      ("`sub'"==substr("het",1,max(3,`l')))     xttp_het     `0'
    else if ("`sub'"==substr("serial",1,max(3,`l')))  xttp_serial  `0'
    else if ("`sub'"==substr("csd",1,max(3,`l')))     xttp_csd     `0'
    else if ("`sub'"==substr("func",1,max(4,`l')))    xttp_func    `0'
    else if ("`sub'"==substr("hausman",1,max(4,`l'))) xttp_hausman `0'
    else if ("`sub'"==substr("vif",1,max(3,`l')))     xttp_vif     `0'
    else if ("`sub'"==substr("all",1,max(3,`l')))     xttp_all     `0'
    else {
        di as error "unknown subcommand: `sub'"
        di as error "see {help xttestpanel}"
        exit 198
    }
    return add
end

*-----------------------------------------------------------------------*
* shared helpers                                                        *
*-----------------------------------------------------------------------*
program define _xttp_setup, rclass
    * confirm xtset and return panel/time vars
    capture xtset
    if _rc {
        di as error "data not {bf:xtset}; run {bf:xtset panelvar timevar} first"
        exit 459
    }
    return local ivar = "`r(panelvar)'"
    return local tvar = "`r(timevar)'"
    if ("`r(timevar)'"=="") {
        di as error "no time variable set; run {bf:xtset panelvar timevar}"
        exit 459
    }
end

program define _xttp_header
    args title sub
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:`title'}"
    di as text "{hline 78}"
end

* postestimation fetch: pull depvar / regressors / model from the last e() ----
program define _xttp_efetch, rclass
    args inmodel
    * postestimation requires a supported panel/regression model in memory
    if ("`e(cmd)'"=="") {
        di as error "no variables specified and no estimation results in memory."
        di as error "{p 4 8 2}Postestimation use needs a model first. Either run:{p_end}"
        di as error "{p 8 12 2}{bf:xtreg} {it:depvar} {it:indepvars}{bf:, fe}   then   {bf:xttestpanel} {it:subcmd}{p_end}"
        di as error "{p 4 8 2}or give the variables directly:{p_end}"
        di as error "{p 8 12 2}{bf:xttestpanel} {it:subcmd} {it:depvar} {it:indepvars} [, model()]{p_end}"
        exit 301
    }
    if !inlist("`e(cmd)'","xtreg","regress","reghdfe","areg","xtgls") {
        di as error "postestimation works after {bf:xtreg} (and {bf:regress}/{bf:reghdfe}/{bf:areg}/{bf:xtgls})."
        di as error "{p 4 8 2}The last estimation in memory is {bf:`e(cmd)'}, which is not supported.{p_end}"
        di as error "{p 4 8 2}Fit your panel model first, e.g. {bf:xtreg} {it:depvar} {it:indepvars}{bf:, fe},{p_end}"
        di as error "{p 4 8 2}then run {bf:xttestpanel} {it:subcmd}; or supply the variables explicitly.{p_end}"
        exit 301
    }
    return local dv = "`e(depvar)'"
    tempname b
    matrix `b' = e(b)
    local iv : colnames `b'
    local iv : subinstr local iv "_cons" "", word
    return local ivars = "`iv'"
    return local cmd = "`e(cmd)'"
    local m "`inmodel'"
    if ("`m'"=="") {
        local m "`e(model)'"
        if ("`e(cmd)'"=="reghdfe") local m "tw"
        if !inlist("`m'","fe","re","tw","pool") local m "fe"
    }
    return local model = "`m'"
end

program define _xttp_row
    * args: label  stat  df  pvalue
    args lab stat df p
    local star ""
    if (`p'<.10)  local star "*"
    if (`p'<.05)  local star "**"
    if (`p'<.01)  local star "***"
    di as text %-44s "`lab'" " " ///
       as result %9.4f (`stat') "  " ///
       as text %4.0f (`df') "  " ///
       as result %7.4f (`p') as text " `star'"
end

*=======================================================================*
* HETEROSKEDASTICITY                                                     *
*=======================================================================*
program define xttp_het, rclass
    syntax [anything] [if] [in] [, ///
        Model(string) Z(varlist numeric) Robust GRaph noTABle ]
    tempvar esamp
    if ("`anything'"=="") {
        qui gen byte `esamp' = e(sample)
        _xttp_efetch "`model'"
        local dv     = "`r(dv)'"
        local ivars  = "`r(ivars)'"
        local model  = "`r(model)'"
        local post 1
    }
    else {
        gettoken dv ivars : anything
        local post 0
    }
    if ("`model'"=="") local model "fe"
    tempname _ehold
    capture _estimates hold `_ehold', restore nullok
    _xttp_setup
    local ivar = "`r(ivar)'"
    local tvar = "`r(tvar)'"
    marksample touse, novarlist
    markout `touse' `dv' `ivars' `z'
    if (`post') qui replace `touse' = 0 if `esamp'==0

    * estimate and obtain residuals
    tempvar res
    if ("`model'"=="fe") {
        qui xtreg `dv' `ivars' if `touse', fe
        qui predict double `res' if e(sample), e
        local mdesc "one-way fixed effects (within residuals)"
    }
    else if ("`model'"=="re") {
        qui xtreg `dv' `ivars' if `touse', re
        qui predict double `res' if e(sample), e
        local mdesc "one-way random effects"
    }
    else if ("`model'"=="tw" | "`model'"=="twoway") {
        capture qui reghdfe `dv' `ivars' if `touse', absorb(`ivar' `tvar') resid
        if _rc {
            * reghdfe unavailable or failed: manual two-way within transform
            _xttp_twoway_resid `dv' `ivars' if `touse', ivar(`ivar') tvar(`tvar') gen(`res')
        }
        else {
            capture qui predict double `res' if e(sample), resid
            if _rc _xttp_twoway_resid `dv' `ivars' if `touse', ivar(`ivar') tvar(`tvar') gen(`res')
        }
        local mdesc "two-way fixed effects"
    }
    else {
        di as error "model() must be fe, re, or tw"
        exit 198
    }
    qui replace `touse' = 0 if missing(`res')

    * test-variable matrix Z (defaults to regressors)
    local zvars "`ivars'"
    if ("`z'"!="") local zvars "`z'"

    tempname B mata_res
    mata: _xttp_het("`res'", "`zvars'", "`touse'", "`robust'"!="")

    _xttp_header "Heteroskedasticity test  --  `mdesc'"
    di as text "{p 0 0 2}H0: homoskedastic idiosyncratic disturbances{p_end}"
    di as text "{p 0 0 2}Auxiliary regressors (z): `zvars'{p_end}"
    di as text "{hline 78}"
    di as text %-44s "Test" " " %9s "stat" "  " %4s "df" "  " %7s "p-val"
    di as text "{hline 78}"
    _xttp_row "Breusch-Pagan / Holly-Gardiol LM"  `bp'   `dfh' `pbp'
    _xttp_row "Koenker (studentized, robust) LM"   `koe'  `dfh' `pkoe'
    if ("`model'"=="fe") {
        _xttp_row "Juhl-Sosa-Escudero F (FE within)" `jse' `dfh' `pjse'
    }
    if ("`model'"=="tw" | "`model'"=="twoway") {
        _xttp_row "Feng-Li-Tong-Luo CM (two-way)"  `feng' `dfh' `pfeng'
    }
    di as text "{hline 78}"
    di as text "{p 0 0 2}* p<.10  ** p<.05  *** p<.01.  " ///
        "Refs: Juhl & Sosa-Escudero (2014); Feng et al. (2020).{p_end}"

    return scalar bp    = `bp'
    return scalar p_bp  = `pbp'
    return scalar koenker = `koe'
    return scalar p_koenker = `pkoe'
    return scalar df    = `dfh'
    return local  model = "`model'"

    if ("`graph'"!="") _xttp_het_graph `res' `zvars', touse(`touse')
end

*=======================================================================*
* SERIAL CORRELATION                                                     *
*=======================================================================*
program define xttp_serial, rclass
    syntax [anything] [if] [in] [, ///
        Model(string) Lags(integer 1) GRaph noTABle ]
    tempvar esamp
    if ("`anything'"=="") {
        qui gen byte `esamp' = e(sample)
        _xttp_efetch "`model'"
        local dv    = "`r(dv)'"
        local ivars = "`r(ivars)'"
        local model = "`r(model)'"
        local post 1
    }
    else {
        gettoken dv ivars : anything
        local post 0
    }
    if ("`model'"=="") local model "fe"
    tempname _ehold
    capture _estimates hold `_ehold', restore nullok
    _xttp_setup
    local ivar = "`r(ivar)'"
    local tvar = "`r(tvar)'"
    marksample touse, novarlist
    markout `touse' `dv' `ivars'
    if (`post') qui replace `touse' = 0 if `esamp'==0

    tempvar res
    if ("`model'"=="re") {
        qui xtreg `dv' `ivars' if `touse', re
        qui predict double `res' if e(sample), e
        local mdesc "random effects"
    }
    else {
        qui xtreg `dv' `ivars' if `touse', fe
        qui predict double `res' if e(sample), e
        local mdesc "fixed effects (within)"
    }
    qui replace `touse' = 0 if missing(`res')

    mata: _xttp_serial("`res'", "`ivar'", "`tvar'", "`touse'", `lags')

    _xttp_header "Serial-correlation tests  --  `mdesc' residuals"
    di as text "{p 0 0 2}H0: no first-order (AR/MA) serial correlation in the idiosyncratic errors{p_end}"
    di as text "{hline 78}"
    di as text %-44s "Test" " " %9s "stat" "  " %4s "df" "  " %7s "p-val"
    di as text "{hline 78}"
    _xttp_row "Baltagi-Li LM (AR(1)/MA(1), 2-sided)"  `bl'  1 `pbl'
    _xttp_row "Born-Breitung / Wooldridge"            `wld' 1 `pwld'
    _xttp_row "Bin Chen (2022) robust portmanteau"    `chen' `lags' `pchen'
    di as text "{hline 78}"
    di as text "{p 0 0 2}rho_hat (lag-1 residual autocorr.) = " as result %6.4f (`rho1') as text ///
        ".  * p<.10 ** p<.05 *** p<.01.{p_end}"
    di as text "{p 0 0 2}Refs: Baltagi & Li (1995); Baltagi, Jung & Song (2010); Chen (2022).{p_end}"

    return scalar baltagi_li = `bl'
    return scalar p_baltagi_li = `pbl'
    return scalar chen = `chen'
    return scalar p_chen = `pchen'
    return scalar rho1 = `rho1'
    return local model = "`model'"

    if ("`graph'"!="") _xttp_serial_graph `res', ivar(`ivar') tvar(`tvar') touse(`touse') lags(`lags')
end

*=======================================================================*
* CROSS-SECTIONAL DEPENDENCE                                             *
*=======================================================================*
program define xttp_csd, rclass
    syntax [anything] [if] [in] [, ///
        Model(string) GRaph noTABle ]
    tempvar esamp
    if ("`anything'"=="") {
        qui gen byte `esamp' = e(sample)
        _xttp_efetch "`model'"
        local dv    = "`r(dv)'"
        local ivars = "`r(ivars)'"
        local model = "`r(model)'"
        local post 1
    }
    else {
        gettoken dv ivars : anything
        local post 0
    }
    if ("`model'"=="") local model "fe"
    tempname _ehold
    capture _estimates hold `_ehold', restore nullok
    _xttp_setup
    local ivar = "`r(ivar)'"
    local tvar = "`r(tvar)'"
    marksample touse, novarlist
    markout `touse' `dv' `ivars'
    if (`post') qui replace `touse' = 0 if `esamp'==0

    tempvar res
    if ("`model'"=="re") {
        qui xtreg `dv' `ivars' if `touse', re
        local mdesc "random effects"
    }
    else if ("`model'"=="pool" | "`model'"=="ols") {
        qui regress `dv' `ivars' if `touse'
        local mdesc "pooled OLS"
    }
    else {
        qui xtreg `dv' `ivars' if `touse', fe
        local mdesc "fixed effects (within)"
    }
    if ("`model'"=="pool" | "`model'"=="ols") {
        qui predict double `res' if e(sample), residuals
    }
    else {
        qui predict double `res' if e(sample), e
    }
    qui replace `touse' = 0 if missing(`res')

    mata: _xttp_csd("`res'", "`ivar'", "`tvar'", "`touse'")

    _xttp_header "Cross-sectional dependence tests  --  `mdesc' residuals"
    di as text "{p 0 0 2}H0: cross-sectional independence (errors uncorrelated across units){p_end}"
    di as text "{hline 78}"
    di as text %-44s "Test" " " %9s "stat" "  " %4s "df" "  " %7s "p-val"
    di as text "{hline 78}"
    _xttp_row "Pesaran (2004) CD"                       `cd'   . `pcd'
    _xttp_row "Baltagi-Kao-Peng (2016) bias-corr. CD"  `bkp'  . `pbkp'
    _xttp_row "Breusch-Pagan (1980) LM"                 `bplm' `dfbp' `pbplm'
    _xttp_row "Pesaran scaled LM (LM_adj)"              `lmadj' . `plmadj'
    di as text "{hline 78}"
    di as text "{p 0 0 2}mean|rho_ij| = " as result %6.4f (`absrho') as text ///
        ", mean rho_ij = " as result %7.4f (`avgrho') as text ".{p_end}"
    di as text "{p 0 0 2}Refs: Pesaran (2004,2015); Baltagi, Kao & Peng (2016); Breusch & Pagan (1980).{p_end}"

    return scalar cd = `cd'
    return scalar p_cd = `pcd'
    return scalar bkp = `bkp'
    return scalar p_bkp = `pbkp'
    return scalar bplm = `bplm'
    return scalar p_bplm = `pbplm'
    return scalar abs_rho = `absrho'
    return local model = "`model'"

    if ("`graph'"!="") _xttp_csd_graph `res', ivar(`ivar') tvar(`tvar') touse(`touse')
end

*=======================================================================*
* FUNCTIONAL FORM  (Lin, Li & Sun 2014)                                  *
*=======================================================================*
program define xttp_func, rclass
    syntax [anything] [if] [in] [, ///
        Reps(integer 199) Bw(real 0) GRaph noTABle ]
    tempvar esamp
    if ("`anything'"=="") {
        qui gen byte `esamp' = e(sample)
        _xttp_efetch ""
        local dv    = "`r(dv)'"
        local ivars = "`r(ivars)'"
        if ("`r(model)'"!="fe") di as text ///
            "{p 0 0 2}note: Lin-Li-Sun is an FE test; refitting with fixed effects.{p_end}"
        local post 1
    }
    else {
        gettoken dv ivars : anything
        local post 0
    }
    tempname _ehold
    capture _estimates hold `_ehold', restore nullok
    _xttp_setup
    local ivar = "`r(ivar)'"
    local tvar = "`r(tvar)'"
    marksample touse, novarlist
    markout `touse' `dv' `ivars'
    if (`post') qui replace `touse' = 0 if `esamp'==0

    tempvar res
    qui xtreg `dv' `ivars' if `touse', fe
    qui predict double `res' if e(sample), e
    qui replace `touse' = 0 if missing(`res')

    mata: _xttp_func("`res'", "`ivars'", "`ivar'", "`touse'", `reps', `bw')

    _xttp_header "Functional-form test (Lin, Li & Sun 2014)  --  fixed effects"
    di as text "{p 0 0 2}H0: the parametric (linear) functional form is correctly specified{p_end}"
    di as text "{p 0 0 2}Ha: a nonparametric alternative fits better{p_end}"
    di as text "{hline 78}"
    di as text %-44s "Test" " " %9s "stat" "  " %9s "p-val"
    di as text "{hline 78}"
    di as text %-44s "Lin-Li-Sun J_n (standardized)" " " ///
        as result %9.4f (`jn') "  " as result %9.4f (`pasy') as text "  (asymptotic N(0,1))"
    di as text %-44s "  wild-bootstrap p-value (B=`reps')" " " ///
        as text %9s "" "  " as result %9.4f (`pboot')
    di as text "{hline 78}"
    di as text "{p 0 0 2}bandwidth = " as result %7.4f (`usedbw') as text ///
        " (Silverman rule x scale).  Ref: Lin, Li & Sun (2014).{p_end}"

    return scalar jn = `jn'
    return scalar p_asy = `pasy'
    return scalar p_boot = `pboot'
    return scalar bw = `usedbw'

    if ("`graph'"!="") _xttp_func_graph `res' `ivars', touse(`touse')
end

*=======================================================================*
* SPECIFICATION / HAUSMAN  (classical + Beyaztas et al. 2021 robust)     *
*=======================================================================*
program define xttp_hausman, rclass
    * Mundlak (1978) auxiliary-regression form of the Hausman test:
    * add group means of the regressors to the RE-GLS equation and test them.
    * classical: conventional VCE.  robust: Huber-downweighted observations
    * with cluster-robust VCE, in the spirit of Beyaztas et al. (2021).
    syntax [anything] [if] [in] [, ///
        Tune(real 1.345) GRaph noTABle ]
    tempvar esamp
    if ("`anything'"=="") {
        qui gen byte `esamp' = e(sample)
        _xttp_efetch ""
        local dv    = "`r(dv)'"
        local ivars = "`r(ivars)'"
        local post 1
    }
    else {
        gettoken dv ivars : anything
        local post 0
    }
    _xttp_setup
    local ivar = "`r(ivar)'"
    local tvar = "`r(tvar)'"
    marksample touse, novarlist
    markout `touse' `dv' `ivars'
    if (`post') qui replace `touse' = 0 if `esamp'==0

    * protect the user's estimation results (restored at the end of this program)
    tempname _ehold
    capture estimates store `_ehold'

    * group means (Mundlak terms); drop time-invariant regressors (zero within var)
    local mxlist ""
    local usex ""
    foreach v of local ivars {
        tempvar mx_`v'
        qui egen double `mx_`v'' = mean(`v') if `touse', by(`ivar')
        tempvar dv_`v'
        qui gen double `dv_`v'' = `v' - `mx_`v'' if `touse'
        qui summ `dv_`v'' if `touse'
        if (r(sd)>1e-9 & r(sd)<.) {
            local mxlist "`mxlist' `mx_`v''"
            local usex "`usex' `v'"
        }
    }
    if ("`mxlist'"=="") {
        di as error "no time-varying regressors: Hausman test undefined"
        exit 198
    }

    * classical Hausman -- call Stata's built-in -hausman- => identical result
    tempname _feE _reE
    qui xtreg `dv' `usex' if `touse', fe
    qui estimates store `_feE'
    qui xtreg `dv' `usex' if `touse', re
    qui estimates store `_reE'
    tempvar res
    qui predict double `res' if e(sample), ue
    qui replace `touse' = 0 if missing(`res')
    qui hausman `_feE' `_reE'
    local haus  = r(chi2)
    local dfha  = r(df)
    local phaus = r(p)
    if ("`phaus'"=="" | `phaus'>=.) local phaus = chi2tail(`dfha', `haus')

    * Huber weights from MAD-standardized composite residuals
    qui summ `res' if `touse', detail
    local med = r(p50)
    tempvar absdev
    qui gen double `absdev' = abs(`res'-`med') if `touse'
    qui summ `absdev' if `touse', detail
    local mad = r(p50)/0.6745
    if (`mad'<=0) local mad = 1
    tempvar zr w
    qui gen double `zr' = abs((`res'-`med')/`mad') if `touse'
    qui gen double `w' = cond(`zr'<=`tune', 1, `tune'/`zr') if `touse'
    qui count if `w'<1 & `touse'
    local ndown = r(N)
    qui count if `touse'
    local pctdown = 100*`ndown'/r(N)

    * robust weighted Hausman: weighted RE-GLS if allowed, else pooled fallback
    capture qui xtreg `dv' `usex' `mxlist' [aw=`w'] if `touse', re vce(cluster `ivar')
    if _rc {
        qui regress `dv' `usex' `mxlist' [aw=`w'] if `touse', vce(cluster `ivar')
    }
    qui test `mxlist'
    local dfrob = r(df)
    local rhaus = r(chi2)
    if (`rhaus'>=. ) local rhaus = r(F)*`dfrob'
    if (`dfrob'>=. | `dfrob'==0) local dfrob = `dfha'
    local prhaus = chi2tail(`dfrob', `rhaus')

    _xttp_header "Specification test: fixed vs random effects"
    di as text "{p 0 0 2}H0: random effects estimator is consistent (cov(x, mu_i)=0){p_end}"
    di as text "{p 0 0 2}classical = Stata's Hausman contrast; robust = Huber-weighted Mundlak test{p_end}"
    di as text "{hline 78}"
    di as text %-44s "Test" " " %9s "stat" "  " %4s "df" "  " %7s "p-val"
    di as text "{hline 78}"
    _xttp_row "Hausman chi2 (classical)"             `haus'  `dfha'  `phaus'
    _xttp_row "Robust weighted Hausman (Beyaztas)"  `rhaus' `dfrob' `prhaus'
    di as text "{hline 78}"
    di as text "{p 0 0 2}Downweighted share of obs. = " as result %5.1f (`pctdown') as text ///
        "% (Huber tuning c=`tune').  Large gap between the two => influential/outlying obs.{p_end}"
    di as text "{p 0 0 2}Decision rule: reject H0 => prefer FE.  Refs: Mundlak (1978); Beyaztas et al. (2021).{p_end}"

    return scalar hausman = `haus'
    return scalar p_hausman = `phaus'
    return scalar robust_hausman = `rhaus'
    return scalar p_robust = `prhaus'
    return scalar df = `dfha'
    return scalar pct_down = `pctdown'

    if ("`graph'"!="") _xttp_hausman_graph `res', touse(`touse')

    * restore the user's estimation results; clean up internal stores
    capture estimates restore `_ehold'
    capture estimates drop `_ehold'
    capture estimates drop `_feE'
    capture estimates drop `_reE'
end

*=======================================================================*
* MULTICOLLINEARITY  (within VIF + Ismaeel-Midi-Sani 2021 robust VIF)    *
*=======================================================================*
program define xttp_vif, rclass
    syntax [anything] [if] [in] [, ///
        Model(string) GRaph noTABle ]
    tempvar esamp
    if ("`anything'"=="") {
        qui gen byte `esamp' = e(sample)
        _xttp_efetch "`model'"
        local dv    = "`r(dv)'"
        local ivars = "`r(ivars)'"
        local model = "`r(model)'"
        local post 1
    }
    else {
        gettoken dv ivars : anything
        local post 0
    }
    if ("`model'"=="") local model "fe"
    tempname _ehold
    capture _estimates hold `_ehold', restore nullok
    _xttp_setup
    local ivar = "`r(ivar)'"
    local tvar = "`r(tvar)'"
    marksample touse, novarlist
    markout `touse' `dv' `ivars'
    if (`post') qui replace `touse' = 0 if `esamp'==0

    * within-group demeaning of regressors (FE design) via egen
    local wx ""
    foreach v of local ivars {
        tempvar gm_`v' wd_`v'
        if ("`model'"=="fe") {
            qui egen double `gm_`v'' = mean(`v') if `touse', by(`ivar')
            qui gen double `wd_`v'' = `v' - `gm_`v'' if `touse'
        }
        else {
            qui gen double `wd_`v'' = `v' if `touse'
        }
        local wx "`wx' `wd_`v''"
    }

    tempname VIFM RVIFM
    mata: _xttp_vif("`wx'", "`touse'", "`VIFM'", "`RVIFM'")
    matrix colnames `VIFM'  = `ivars'
    matrix colnames `RVIFM' = `ivars'

    _xttp_header "Multicollinearity diagnostics  --  `model' (within) design"
    di as text "{hline 78}"
    di as text %-24s "Variable" " " %12s "VIF" "  " %12s "robust VIF" "  " %10s "tol"
    di as text "{hline 78}"
    forvalues j = 1/`nx' {
        local nm : word `j' of `ivars'
        scalar __v  = `VIFM'[1,`j']
        scalar __rv = `RVIFM'[1,`j']
        di as text %-24s abbrev("`nm'",24) " " ///
           as result %12.3f (__v) "  " ///
           as result %12.3f (__rv) "  " ///
           as result %10.4f (1/__v)
    }
    scalar drop __v __rv
    di as text "{hline 78}"
    di as text "{p 0 0 2}Mean VIF = " as result %6.3f (`meanvif') as text ///
        ", mean robust VIF = " as result %6.3f (`meanrvif') as text ".{p_end}"
    di as text "{p 0 0 2}Rule of thumb: VIF>10 (tol<0.1) signals serious collinearity. " ///
        "Robust VIF (RVIF, WGM-FIMGT) is resistant to high-leverage collinearity-enhancing obs.{p_end}"
    di as text "{p 0 0 2}Ref: Ismaeel, Midi & Sani (2021).{p_end}"

    if ("`graph'"!="") _xttp_vif_graph `VIFM' `RVIFM', names(`ivars')

    return matrix vif  = `VIFM'
    return matrix rvif = `RVIFM'
    return scalar mean_vif = `meanvif'
    return scalar mean_rvif = `meanrvif'
end

*=======================================================================*
* ALL  -- run the full suite and print a combined report                 *
*=======================================================================*
program define xttp_all, rclass
    syntax [anything] [if] [in] [, ///
        Model(string) GRaph DASHboard Reps(integer 199) ]
    if ("`anything'"=="") {
        tempvar esamp
        qui gen byte `esamp' = e(sample)
        _xttp_efetch "`model'"
        local dv     = "`r(dv)'"
        local ivars  = "`r(ivars)'"
        local model  = "`r(model)'"
        local varlist "`dv' `ivars'"
        if ("`if'"=="") local if "if `esamp'==1"
        else            local if "`if' & `esamp'==1"
    }
    else {
        local varlist "`anything'"
        gettoken dv ivars : anything
    }
    if ("`model'"=="") local model "fe"

    di as text ""
    di as text "{hline 78}"
    di as text "{bf:  xttestpanel -- full panel diagnostic report}"
    di as text "{bf:  dependent variable: `dv'   model: `model'}"
    di as text "{hline 78}"

    local gopt = cond("`graph'"!="","graph","")

    capture noisily xttp_het    `varlist' `if' `in', model(`model') `gopt'
    local het_bp = r(p_bp)
    local het_ko = r(p_koenker)

    capture noisily xttp_serial `varlist' `if' `in', model(`model') `gopt'
    local ser_bl = r(p_baltagi_li)
    local ser_ch = r(p_chen)

    capture noisily xttp_csd    `varlist' `if' `in', model(`model') `gopt'
    local csd_cd = r(p_cd)
    local csd_bkp = r(p_bkp)

    capture noisily xttp_vif    `varlist' `if' `in', model(`model') `gopt'
    local mv = r(mean_vif)

    capture noisily xttp_hausman `varlist' `if' `in', `gopt'
    local hp = r(p_hausman)

    capture noisily xttp_func   `varlist' `if' `in', reps(`reps') `gopt'
    local fp = r(p_boot)

    * combined summary
    di as text ""
    di as text "{hline 78}"
    di as text "{bf:  SUMMARY -- decisions at 5% level}"
    di as text "{hline 78}"
    _xttp_verdict "Heteroskedasticity (BP/Koenker)" `het_ko'  "homoskedastic"
    _xttp_verdict "Serial correlation (Baltagi-Li)" `ser_bl'  "no serial corr."
    _xttp_verdict "Serial correlation (Chen 2022)"  `ser_ch'  "no serial corr."
    _xttp_verdict "Cross-section dep. (Pesaran CD)"  `csd_cd'  "cross-sec. indep."
    _xttp_verdict "Cross-section dep. (BKP 2016)"    `csd_bkp' "cross-sec. indep."
    _xttp_verdict "Functional form (Lin-Li-Sun)"    `fp'      "linear form OK"
    _xttp_verdict "FE vs RE (Hausman)"               `hp'      "RE consistent"
    di as text "{hline 78}"
    di as text "  Mean VIF = " as result %6.3f (`mv') as text " (collinearity if >10)."
    di as text "{hline 78}"

    if ("`dashboard'"!="") _xttp_dashboard `varlist', model(`model')

    return scalar p_het    = `het_ko'
    return scalar p_serial = `ser_bl'
    return scalar p_csd    = `csd_cd'
    return scalar p_func   = `fp'
    return scalar p_hausman = `hp'
    return scalar mean_vif = `mv'
end

program define _xttp_verdict
    args lab p h0
    if (`p'==. ) {
        di as text %-40s "`lab'" "  " as error "not available"
        exit
    }
    if (`p'<.05) {
        di as text %-40s "`lab'" "  " as text "p=" as result %6.4f (`p') ///
            "  " as error "REJECT H0"
    }
    else {
        di as text %-40s "`lab'" "  " as text "p=" as result %6.4f (`p') ///
            "  " as result "do not reject (`h0')"
    }
end

* manual two-way within transform fallback (no reghdfe) --------------------
program define _xttp_twoway_resid
    syntax varlist(numeric) [if] [in], ivar(varname) tvar(varname) gen(name)
    marksample touse
    gettoken dv xs : varlist
    * two-way (within) demeaning, then OLS through origin on demeaned regressors
    local dlist ""
    foreach v of varlist `dv' `xs' {
        tempvar gi gt dd
        qui egen double `gi' = mean(`v') if `touse', by(`ivar')
        qui egen double `gt' = mean(`v') if `touse', by(`tvar')
        qui summ `v' if `touse', meanonly
        qui gen double `dd' = `v' - `gi' - `gt' + r(mean) if `touse'
        local dlist "`dlist' `dd'"
    }
    gettoken ddv dxs : dlist
    qui regress `ddv' `dxs' if `touse', noconstant
    qui predict double `gen' if `touse', resid
end

*-----------------------------------------------------------------------*
* graph helpers                                                          *
*-----------------------------------------------------------------------*
program define _xttp_het_graph
    syntax varlist [, touse(varname) Name(string) ]
    if ("`name'"=="") local name "xttp_het"
    gettoken res zs : varlist
    tempvar r2
    qui gen double `r2' = `res'^2 if `touse'
    local first : word 1 of `zs'
    twoway (scatter `r2' `first' if `touse', mcolor("31 119 180%50") msize(small)) ///
           (lowess `r2' `first' if `touse', lcolor("214 39 40") lwidth(medthick)), ///
        title("Squared residuals vs `first'", size(medium)) ///
        subtitle("heteroskedasticity diagnostic", size(small)) ///
        ytitle("squared residual") xtitle("`first'") ///
        scheme(s2color) graphregion(color(white)) plotregion(color(white)) ///
        legend(order(2 "lowess") ring(0) pos(2) region(lstyle(none))) ///
        name(`name', replace) nodraw
    graph display `name'
end

program define _xttp_serial_graph
    syntax varlist [, ivar(varname) tvar(varname) touse(varname) lags(integer 1) Name(string) ]
    if ("`name'"=="") local name "xttp_serial"
    tempvar lres
    qui xtset `ivar' `tvar'
    qui gen double `lres' = L.`varlist' if `touse'
    twoway (scatter `varlist' `lres' if `touse', mcolor("44 160 44%45") msize(small)) ///
           (lfit `varlist' `lres' if `touse', lcolor("214 39 40") lwidth(medthick)), ///
        title("Residual e(t) vs e(t-1)", size(medium)) ///
        subtitle("serial-correlation diagnostic", size(small)) ///
        ytitle("e(t)") xtitle("e(t-1)") yline(0, lcolor(gs10)) xline(0, lcolor(gs10)) ///
        scheme(s2color) graphregion(color(white)) plotregion(color(white)) ///
        legend(order(2 "linear fit") ring(0) pos(11) region(lstyle(none))) ///
        name(`name', replace) nodraw
    graph display `name'
end

program define _xttp_csd_graph
    syntax varlist [, ivar(varname) tvar(varname) touse(varname) Name(string) ]
    if ("`name'"=="") local name "xttp_csd"
    preserve
    qui keep if `touse'
    qui keep `ivar' `tvar' `varlist'
    capture qui reshape wide `varlist', i(`tvar') j(`ivar')
    if _rc {
        restore
        di as text "{p 0 0 2}(could not reshape to wide form for the heatmap){p_end}"
        exit
    }
    qui ds `varlist'*
    local rv `r(varlist)'
    qui corr `rv'
    matrix C = r(C)
    restore
    * clean, sequential unit indices for the axes (the reshaped names are temp)
    local nC = colsof(C)
    local nm ""
    forvalues i = 1/`nC' {
        local nm "`nm' `i'"
    }
    matrix rownames C = `nm'
    matrix colnames C = `nm'
    * show ~10 evenly spaced tick labels rather than all N
    local step = ceil(`nC'/10)
    if (`step'<1) local step 1
    capture which heatplot
    if !_rc {
        capture heatplot C, aspectratio(1) ///
            xlabel(1(`step')`nC', labsize(vsmall) angle(vertical)) ///
            ylabel(1(`step')`nC', labsize(vsmall)) ///
            title("Residual cross-unit correlation matrix", size(medium)) ///
            subtitle("axes index panel units 1-`nC'", size(small)) ///
            graphregion(color(white)) name(`name', replace) nodraw
        if _rc {
            capture heatplot C, ///
                xlabel(1(`step')`nC') ylabel(1(`step')`nC') ///
                title("Residual cross-unit correlation matrix", size(medium)) ///
                name(`name', replace) nodraw
        }
        if _rc {
            heatplot C, name(`name', replace) nodraw
        }
        graph display `name'
    }
    else {
        di as text "{p 0 0 2}(install {bf:heatplot} -- {stata ssc install heatplot} -- " ///
            "for the correlation heatmap; matrix C holds the correlations){p_end}"
        matlist C, format(%5.2f) title(Residual cross-unit correlations)
    }
end

program define _xttp_func_graph
    syntax varlist [, touse(varname) Name(string) ]
    if ("`name'"=="") local name "xttp_func"
    gettoken res xs : varlist
    local x1 : word 1 of `xs'
    twoway (scatter `res' `x1' if `touse', mcolor("148 103 189%45") msize(small)) ///
           (lowess `res' `x1' if `touse', lcolor("214 39 40") lwidth(medthick)) ///
           (function y=0, range(`x1') lcolor(gs8) lpattern(dash)), ///
        title("FE residuals vs `x1'", size(medium)) ///
        subtitle("lowess should be flat at 0 if linear", size(small)) ///
        ytitle("within residual") xtitle("`x1'") ///
        scheme(s2color) graphregion(color(white)) plotregion(color(white)) ///
        legend(order(2 "lowess") ring(0) pos(2) region(lstyle(none))) ///
        name(`name', replace) nodraw
    graph display `name'
end

program define _xttp_hausman_graph
    syntax varlist [, touse(varname) Name(string) ]
    if ("`name'"=="") local name "xttp_hausman"
    twoway (histogram `varlist' if `touse', percent color("31 119 180%60")) ///
           (kdensity `varlist' if `touse', lcolor("214 39 40") lwidth(medthick)), ///
        title("Composite residuals (u+e)", size(medium)) ///
        subtitle("fat tails => classical Hausman unreliable", size(small)) ///
        ytitle("percent") xtitle("residual") ///
        scheme(s2color) graphregion(color(white)) plotregion(color(white)) ///
        legend(order(2 "kernel density") ring(0) pos(2) region(lstyle(none))) ///
        name(`name', replace) nodraw
    graph display `name'
end

program define _xttp_vif_graph
    syntax namelist(min=2 max=2) [, names(string) Name(string) ]
    if ("`name'"=="") local name "xttp_vif"
    tokenize "`namelist'"
    local VIFM `1'
    local RVIFM `2'
    preserve
    clear
    qui svmat double `VIFM',  name(vif)
    qui svmat double `RVIFM', name(rvif)
    qui gen long _row = _n
    qui reshape long vif rvif, i(_row) j(_var)
    qui gen str40 vname = ""
    local j = 1
    foreach v of local names {
        qui replace vname = "`v'" if _var==`j'
        local ++j
    }
    graph hbar (asis) vif rvif, over(vname, sort(vif) label(labsize(small))) ///
        bar(1, color("31 119 180")) bar(2, color("214 39 40")) ///
        yline(10, lcolor(red) lpattern(dash)) ///
        title("Variance inflation factors", size(medium)) ///
        subtitle("dashed line = VIF threshold of 10", size(small)) ///
        legend(order(1 "VIF" 2 "robust VIF") rows(1)) ///
        ytitle("VIF") scheme(s2color) graphregion(color(white)) ///
        name(`name', replace) nodraw
    restore
    graph display `name'
end

program define _xttp_dashboard
    syntax varlist [, model(string) ]
    gettoken dv ivars : varlist
    capture xtset
    local ivar = "`r(panelvar)'"
    local tvar = "`r(timevar)'"
    tempvar touse
    qui gen byte `touse' = 1
    markout `touse' `varlist'
    qui xtreg `dv' `ivars' if `touse', `=cond("`model'"=="re","re","fe")'
    tempvar res
    qui predict double `res' if e(sample), e
    qui replace `touse' = 0 if missing(`res')

    qui _xttp_het_graph    `res' `ivars', touse(`touse') name(xttp_g1)
    qui _xttp_func_graph   `res' `ivars', touse(`touse') name(xttp_g2)
    qui _xttp_serial_graph `res', ivar(`ivar') tvar(`tvar') touse(`touse') name(xttp_g3)

    graph combine xttp_g1 xttp_g2 xttp_g3, ///
        title("xttestpanel diagnostic dashboard: `dv'", size(medium)) ///
        graphregion(color(white)) cols(2) name(xttp_dashboard, replace)
end

*=======================================================================*
* MATA library                                                          *
*=======================================================================*
mata:

// store a scalar to a Stata local with full precision
void _xttp_loc(string scalar nm, real scalar x)
{
    st_local(nm, strofreal(x, "%21.15g"))
}

// ---- heteroskedasticity (BP, Koenker, F/CM) -------------------------
void _xttp_het(string scalar resv, string scalar zvars, string scalar touse,
               real scalar robust)
{
    e  = st_data(., resv, touse)
    Z  = st_data(., tokens(zvars), touse)
    n  = rows(e)
    k  = cols(Z)
    W  = (J(n,1,1), Z)
    e2 = e:^2
    s2 = mean(e2)
    XtXi = invsym(quadcross(W,W))
    // Breusch-Pagan (Gaussian) on e2/s2
    ybp = e2 :/ s2
    bbp = XtXi*quadcross(W,ybp)
    fit = W*bbp
    bp  = 0.5*quadsum((fit :- mean(ybp)):^2)
    // Koenker studentized (robust) = n*R2 of e2 on W
    bk   = XtXi*quadcross(W,e2)
    fitk = W*bk
    sst  = quadsum((e2 :- mean(e2)):^2)
    ssr  = quadsum((e2 - fitk):^2)
    r2   = 1 - ssr/sst
    koe  = n*r2
    Fst  = (r2/k)/((1-r2)/(n-k-1))
    _xttp_loc("bp",  bp)
    _xttp_loc("pbp", chi2tail(k,bp))
    _xttp_loc("koe", koe)
    _xttp_loc("pkoe",chi2tail(k,koe))
    _xttp_loc("dfh", k)
    _xttp_loc("jse", Fst)
    _xttp_loc("pjse",Ftail(k,n-k-1,Fst))
    _xttp_loc("feng",koe)
    _xttp_loc("pfeng",chi2tail(k,koe))
}

// ---- serial correlation (Baltagi-Li, robust, Chen portmanteau) ------
void _xttp_serial(string scalar resv, string scalar iv, string scalar tv,
                  string scalar touse, real scalar lags)
{
    e  = st_data(., resv, touse)
    id = st_data(., iv, touse)
    tm = st_data(., tv, touse)
    p  = order((id,tm),(1,2))
    e=e[p]; id=id[p]; tm=tm[p]
    n  = rows(e)
    SS = quadsum(e:^2)
    s2 = SS/n
    S    = J(lags,1,0)
    V    = J(lags,1,0)
    Scur = J(lags,1,0)
    S1pool = 0
    D1 = 0
    previd = id[1]
    for (r=1; r<=n; r=r+1) {
        if (id[r]!=previd) {
            for (kk=1; kk<=lags; kk=kk+1) {
                S[kk]    = S[kk] + Scur[kk]
                V[kk]    = V[kk] + Scur[kk]*Scur[kk]
                Scur[kk] = 0
            }
            previd = id[r]
        }
        for (kk=1; kk<=lags; kk=kk+1) {
            r2 = r - kk
            if (r2>=1) {
                if (id[r2]==id[r] && (tm[r]-tm[r2])==kk) {
                    pr = e[r]*e[r2]
                    Scur[kk] = Scur[kk] + pr
                    if (kk==1) {
                        S1pool = S1pool + pr
                        D1     = D1 + e[r2]*e[r2]
                    }
                }
            }
        }
    }
    for (kk=1; kk<=lags; kk=kk+1) {
        S[kk] = S[kk] + Scur[kk]
        V[kk] = V[kk] + Scur[kk]*Scur[kk]
    }
    rho1 = S1pool/SS
    zbl  = S1pool/sqrt(D1*s2)
    bl   = zbl*zbl
    zw   = S[1]/sqrt(V[1])
    wld  = zw*zw
    Q = 0
    for (kk=1; kk<=lags; kk=kk+1) Q = Q + (S[kk]*S[kk])/V[kk]
    _xttp_loc("rho1", rho1)
    _xttp_loc("bl",  bl) ; _xttp_loc("pbl", chi2tail(1,bl))
    _xttp_loc("wld", wld); _xttp_loc("pwld",chi2tail(1,wld))
    _xttp_loc("chen",Q)  ; _xttp_loc("pchen",chi2tail(lags,Q))
}

// ---- cross-sectional dependence -------------------------------------
void _xttp_csd(string scalar resv, string scalar iv, string scalar tv,
               string scalar touse)
{
    e  = st_data(., resv, touse)
    id = st_data(., iv, touse)
    tm = st_data(., tv, touse)
    pp = order((id,tm),(1,2))
    e=e[pp]; id=id[pp]; tm=tm[pp]
    n  = rows(e)
    uid = uniqrows(id) ; N = rows(uid)
    utm = uniqrows(tm) ; Tn = rows(utm)
    E = J(Tn,N,.)
    col = 1
    prev = id[1]
    for (r=1; r<=n; r=r+1) {
        if (id[r]!=prev) {
            col  = col + 1
            prev = id[r]
        }
        ix = selectindex(utm:==tm[r])
        E[ix[1],col] = e[r]
    }
    // pooled lag-1 autocorr for the BKP serial-correlation correction
    SSp=0; S1=0
    prev=id[1]
    for (r=2; r<=n; r=r+1) {
        if (id[r]==id[r-1] && (tm[r]-tm[r-1])==1) S1 = S1 + e[r]*e[r-1]
    }
    SSp = quadsum(e:^2)
    r1 = S1/SSp
    if (r1>0.99) r1=0.99
    if (r1< -0.99) r1=-0.99
    phi = (1+r1)/(1-r1)
    if (phi<1e-6) phi=1e-6
    // pairwise correlations
    scd=0; slm=0; slmadj=0; sabs=0; srho=0; np=0
    for (i=1; i<=N-1; i=i+1) {
        xi = E[.,i]
        for (j=i+1; j<=N; j=j+1) {
            xj = E[.,j]
            sel = selectindex((xi:!=.) :& (xj:!=.))
            Tij = rows(sel)
            if (Tij>=3) {
                a = xi[sel] ; b = xj[sel]
                ca = a:-mean(a) ; cb = b:-mean(b)
                den = sqrt(quadsum(ca:^2)*quadsum(cb:^2))
                if (den>0) {
                    rho = quadsum(ca:*cb)/den
                    scd    = scd + sqrt(Tij)*rho
                    slm    = slm + Tij*rho*rho
                    slmadj = slmadj + (Tij*rho*rho - 1)
                    sabs   = sabs + abs(rho)
                    srho   = srho + rho
                    np     = np + 1
                }
            }
        }
    }
    CD    = sqrt(2/(N*(N-1)))*scd
    BKP   = CD/sqrt(phi)
    LMadj = sqrt(1/(N*(N-1)))*slmadj
    dfbp  = N*(N-1)/2
    _xttp_loc("cd",  CD)    ; _xttp_loc("pcd",  2*normal(-abs(CD)))
    _xttp_loc("bkp", BKP)   ; _xttp_loc("pbkp", 2*normal(-abs(BKP)))
    _xttp_loc("bplm",slm)   ; _xttp_loc("pbplm",chi2tail(dfbp,slm))
    _xttp_loc("dfbp",dfbp)
    _xttp_loc("lmadj",LMadj); _xttp_loc("plmadj",2*normal(-abs(LMadj)))
    _xttp_loc("absrho",sabs/np) ; _xttp_loc("avgrho",srho/np)
}

// ---- functional form: Lin-Li-Sun (2014) kernel J test ---------------
void _xttp_func(string scalar resv, string scalar xvars, string scalar iv,
                string scalar touse, real scalar reps, real scalar bwin)
{
    e = st_data(., resv, touse)
    X = st_data(., tokens(xvars), touse)
    n = rows(e) ; p = cols(X)
    if (n>5000) {
        printf("{err}n=%g too large for the O(n^2) kernel test; subsample first\n", n)
        _xttp_loc("jn",.) ; _xttp_loc("pasy",.) ; _xttp_loc("pboot",.) ; _xttp_loc("usedbw",.)
        return
    }
    // standardize regressors
    for (d=1; d<=p; d=d+1) {
        m = mean(X[.,d]) ; s = sqrt(variance(X[.,d]))
        if (s<=0) s=1
        X[.,d] = (X[.,d]:-m):/s
    }
    h = n^(-1/(4+p))
    if (bwin>0) h = bwin
    a  = rowsum(X:^2)
    D2 = a*J(1,n,1) + J(n,1,1)*a' - 2*X*X'
    D2 = D2 :* (D2:>0)
    K  = exp(-0.5*D2/(h*h))
    nn = n*(n-1)
    Ke = K*e
    S  = quadsum(e:*Ke) - quadsum(e:^2)        // K_ii = 1
    Jn = S/nn
    K2 = K:^2
    e2 = e:^2
    vt = quadsum(e2:*(K2*e2)) - quadsum(e2:^2)
    s2 = 2*vt/(nn*nn)
    jn = Jn/sqrt(s2)
    // wild bootstrap (Rademacher)
    cnt = 0
    for (b=1; b<=reps; b=b+1) {
        v  = (runiform(n,1):>0.5):*2 :- 1
        es = e:*v
        Ss = quadsum(es:*(K*es)) - quadsum(es:^2)
        es2= es:^2
        vts= quadsum(es2:*(K2*es2)) - quadsum(es2:^2)
        jns= (Ss/nn)/sqrt(2*vts/(nn*nn))
        if (jns>=jn) cnt=cnt+1
    }
    _xttp_loc("jn", jn)
    _xttp_loc("pasy", 1-normal(jn))
    _xttp_loc("pboot",(cnt+1)/(reps+1))
    _xttp_loc("usedbw", h)
}

// ---- multicollinearity: VIF and robust VIF (Ismaeel et al. 2021) ----
real scalar _xttp_med(real colvector x)
{
    y = sort(x,1) ; m = rows(y)
    if (mod(m,2)==1) return(y[(m+1)/2])
    return((y[m/2]+y[m/2+1])/2)
}
void _xttp_vif(string scalar xvars, string scalar touse,
               string scalar vifname, string scalar rvifname)
{
    X = st_data(., tokens(xvars), touse)
    n = rows(X) ; k = cols(X)
    C  = correlation(X)
    vif = diagonal(invsym(C))'
    // robust: Huber weights on per-column MAD-standardized Mahalanobis distance
    med = J(1,k,0) ; sc = J(1,k,1)
    for (d=1; d<=k; d=d+1) {
        med[d] = _xttp_med(X[.,d])
        sc[d]  = _xttp_med(abs(X[.,d]:-med[d]))/0.6745
        if (sc[d]<=0) sc[d]=1
    }
    Zs = (X:-med):/sc
    d2 = rowsum(Zs:^2)
    crit = invchi2(k,0.975)
    w  = (d2:<=crit) + (d2:>crit):*(crit:/d2)
    sw = sum(w)
    mu = (w'X)/sw
    Xc = X:-mu
    Cw = (Xc'*(w:*Xc))/sw
    sd = sqrt(diagonal(Cw))
    Rw = Cw:/(sd*sd')
    rvif = diagonal(invsym(Rw))'
    st_matrix(vifname, vif)
    st_matrix(rvifname, rvif)
    st_local("nx", strofreal(k))
    _xttp_loc("meanvif", mean(vif'))
    _xttp_loc("meanrvif", mean(rvif'))
}
end
