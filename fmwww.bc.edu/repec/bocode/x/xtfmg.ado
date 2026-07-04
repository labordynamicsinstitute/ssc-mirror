*! xtfmg 1.1.0  03jul2026
*! Second-generation heterogeneous panel estimators with individual and common shocks
*! FE, MG, CCEMG, SURMG, F-SURMG and the Fourier CCE Mean Group (F-CCEMG) estimator
*! Implements Guliyev (2026), Pesaran & Smith (1995), Pesaran (2006), Guliyev (2023, 2025)
*! Author: Merwan Roudane - merwanroudane920@gmail.com - https://github.com/merwanroudane

program define xtfmg, rclass
    version 14.0
    gettoken sub 0 : 0, parse(" ,")
    local sub = lower(`"`sub'"')
    if (`"`sub'"'=="") {
        di as err "xtfmg: subcommand required"
        di as err "syntax: xtfmg {fe|mg|ccemg|surmg|fsurmg|fccemg|all|breaks|map} depvar indepvars [if] [in] [, options]"
        exit 198
    }
    if      (`"`sub'"'=="fe")       xtfmg_fe `0'
    else if (`"`sub'"'=="mg")       xtfmg_mgtype mg `0'
    else if (`"`sub'"'=="ccemg")    xtfmg_mgtype ccemg `0'
    else if (`"`sub'"'=="surmg")    xtfmg_mgtype surmg `0'
    else if (`"`sub'"'=="fsurmg")   xtfmg_mgtype fsurmg `0'
    else if (`"`sub'"'=="fccemg")   xtfmg_mgtype fccemg `0'
    else if (`"`sub'"'=="all")      xtfmg_all `0'
    else if (`"`sub'"'=="breaks")   xtfmg_breaks `0'
    else if (`"`sub'"'=="map")      xtfmg_map `0'
    else {
        di as err `"xtfmg: unknown subcommand "`sub'""'
        di as err "valid subcommands: fe mg ccemg surmg fsurmg fccemg all breaks map"
        exit 198
    }
    return add
end

* ---------------------------------------------------------------------------
* read panel/time variables from xtset (quoted string r() reads)
* ---------------------------------------------------------------------------
program define xtfmg_xt, rclass
    capture qui xtset
    if (_rc) {
        di as err "xtfmg: data must be xtset with both a panel and a time variable"
        exit 459
    }
    local ivar `"`r(panelvar)'"'
    local tvar `"`r(timevar)'"'
    if (`"`ivar'"'=="" | `"`tvar'"'=="") {
        di as err "xtfmg: data must be xtset with both a panel and a time variable"
        exit 459
    }
    return local ivar `"`ivar'"'
    return local tvar `"`tvar'"'
end

* ---------------------------------------------------------------------------
* balance check on the estimation sample
* ---------------------------------------------------------------------------
program define xtfmg_balchk, rclass sortpreserve
    args touse ivar tvar
    tempvar cnt
    qui bysort `ivar' `touse' (`tvar'): gen long `cnt' = _N if `touse'
    qui su `cnt' if `touse', meanonly
    local mn = r(min)
    local mx = r(max)
    qui tab `tvar' if `touse'
    local nT = r(r)
    return scalar bal = (`mn'==`mx') & (`mx'==`nT')
end

* ---------------------------------------------------------------------------
* engine wrapper: runs the Mata estimator and returns everything in r()
* est: mg ccemg surmg fsurmg fccemg
* ---------------------------------------------------------------------------
program define xtfmg_run, rclass
    args est dv xv touse ivar tvar kfreq
    local usecce 0
    local usef 0
    local usesur 0
    if ("`est'"=="ccemg"  | "`est'"=="fccemg") local usecce 1
    if ("`est'"=="fsurmg" | "`est'"=="fccemg") local usef 1
    if ("`est'"=="surmg"  | "`est'"=="fsurmg") local usesur 1
    mata: xtfmg_engine("`dv'", "`xv'", "`ivar'", "`tvar'", "`touse'", `usecce', `usef', `usesur', `kfreq')
    return scalar N     = __xtfmg_N
    return scalar nused = __xtfmg_nused
    return scalar nskip = __xtfmg_nskip
    return scalar Tbar  = __xtfmg_Tbar
    return scalar n     = __xtfmg_n
    return scalar cd    = __xtfmg_cd
    return scalar cdp   = __xtfmg_cdp
    return scalar alpha = __xtfmg_alpha
    return matrix bmg   = __xtfmg_bmg
    return matrix Vmg   = __xtfmg_Vmg
    return matrix bu    = __xtfmg_bu
    return matrix seu   = __xtfmg_seu
    return matrix fpath = __xtfmg_fpath
    return matrix ids   = __xtfmg_ids
    capture scalar drop __xtfmg_N __xtfmg_nused __xtfmg_nskip __xtfmg_Tbar ///
        __xtfmg_n __xtfmg_cd __xtfmg_cdp __xtfmg_alpha
end

* ---------------------------------------------------------------------------
* single mean-group-type estimator: mg ccemg surmg fsurmg fccemg
* ---------------------------------------------------------------------------
program define xtfmg_mgtype, rclass
    gettoken est 0 : 0
    syntax varlist(min=2 numeric) [if] [in] [, Kfreq(integer 1) Level(cilevel) ///
        HETeroplot FOURierplot Focus(varname numeric) noTABle ///
        SAVing(string) TItle(string) REPlace]
    marksample touse
    xtfmg_xt
    local ivar `"`r(ivar)'"'
    local tvar `"`r(tvar)'"'
    markout `touse' `ivar' `tvar'
    qui count if `touse'
    if (r(N) < 10) {
        di as err "xtfmg: too few observations in the estimation sample"
        exit 2001
    }
    gettoken dv xv : varlist
    local k : word count `xv'
    if (`kfreq' < 1) {
        di as err "xtfmg: kfreq() must be a positive integer"
        exit 198
    }
    if (`kfreq' > 3) {
        di as txt "note: kfreq() > 3 risks over-fitting the deterministic component" ///
            " (Becker, Enders and Lee 2006)"
    }
    local isf = inlist("`est'", "fsurmg", "fccemg")
    if ("`fourierplot'" != "" & !`isf') {
        di as err "fourierplot is only available with fsurmg and fccemg"
        exit 198
    }
    if ("`focus'" != "") {
        local infoc : list focus in xv
        if (!`infoc') {
            di as err "focus() must name one of the independent variables"
            exit 198
        }
    }
    else local focus : word 1 of `xv'

    qui xtfmg_run `est' `dv' "`xv'" `touse' `ivar' `tvar' `kfreq'

    tempname b V bu seu fpath ids
    matrix `b'     = r(bmg)
    matrix `V'     = r(Vmg)
    matrix `bu'    = r(bu)
    matrix `seu'   = r(seu)
    matrix `fpath' = r(fpath)
    matrix `ids'   = r(ids)
    local N     = r(N)
    local nused = r(nused)
    local nskip = r(nskip)
    local Tbar  = r(Tbar)
    local nobs  = r(n)
    local cd    = r(cd)
    local cdp   = r(cdp)
    local alpha = r(alpha)

    local cn `xv'
    if (`isf') local cn `xv' sin cos
    matrix colnames `b'   = `cn'
    matrix colnames `V'   = `cn'
    matrix rownames `V'   = `cn'
    matrix colnames `bu'  = `cn'
    matrix colnames `seu' = `cn'
    local rn ""
    forvalues i = 1/`N' {
        local uid = strofreal(el(`ids',`i',1), "%12.0g")
        local rn `rn' u`uid'
    }
    matrix rownames `bu'  = `rn'
    matrix rownames `seu' = `rn'

    if ("`table'" != "notable") {
        xtfmg_head "`est'" "`dv'" `N' `nused' `nskip' `Tbar' `nobs' `kfreq' ///
            "`ivar'" "`tvar'" `cd' `cdp'
        xtfmg_ctable `b' `V' `level'
        di as txt "Mean-group average over " as res `nused' as txt ///
            " unit regressions; nonparametric Pesaran-Smith (1995) variance."
        if (inlist("`est'","surmg","fsurmg")) {
            di as txt "Unit equations estimated jointly by feasible GLS (SUR)."
        }
        if (inlist("`est'","ccemg","fccemg")) {
            di as txt "Cross-sectional averages of the dependent variable and regressors included."
        }
        if (`isf') {
            di as txt "Unit-specific single-frequency Fourier terms included, k = " as res `kfreq' as txt "."
        }
    }

    * plots must run BEFORE return matrix moves the matrices
    if ("`heteroplot'" != "") {
        xtfmg_hplot `bu' `seu' `ids' "`focus'" "`est'" `level' "`ivar'"
    }
    if ("`fourierplot'" != "") {
        xtfmg_fplot `fpath' `ids' "`est'" "`tvar'" "`ivar'"
    }

    * journal-format export (before return matrix moves b and V)
    if (`"`saving'"' != "") {
        xtfmg_elab `est'
        local elab `"`r(lab)'"'
        tempname pse
        matrix `pse' = J(1, colsof(`b'), .)
        forvalues j = 1/`=colsof(`b')' {
            matrix `pse'[1,`j'] = sqrt(el(`V',`j',`j'))
        }
        if (`"`title'"' == "") local title "`elab' estimates. Dependent variable: `dv'"
        local n1 "N = `N', average T = `=trim(string(`Tbar',"%9.1f"))', observations = `nobs'."
        local n2 ""
        if (`cd' < .) {
            local n2 "Residual CD = `=trim(string(`cd',"%9.2f"))' (p = `=trim(string(`cdp',"%9.3f"))'). Pesaran-Smith (1995) variance."
        }
        local n3 "Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01."
        xtfmg_exp, fname(`"`saving'"') `replace' title(`"`title'"') ///
            rnames(`cn') clabels(`elab') bmats(`b') semats(`pse') ///
            note1(`"`n1'"') note2(`"`n2'"') note3(`"`n3'"')
    }

    return scalar N      = `N'
    return scalar N_used = `nused'
    return scalar N_skip = `nskip'
    return scalar Tbar   = `Tbar'
    return scalar n      = `nobs'
    return scalar k      = `k'
    return scalar cd     = `cd'
    return scalar cd_p   = `cdp'
    return scalar alpha  = `alpha'
    if (`isf') return scalar kfreq = `kfreq'
    return local estimator "`est'"
    return local depvar "`dv'"
    return local indepvars "`xv'"
    return local ivar "`ivar'"
    return local tvar "`tvar'"
    return matrix seunit = `seu'
    return matrix bunit  = `bu'
    return matrix V      = `V'
    return matrix b      = `b'
end

* ---------------------------------------------------------------------------
* pooled fixed-effects benchmark (homogeneous slopes)
* ---------------------------------------------------------------------------
program define xtfmg_fe, rclass
    syntax varlist(min=2 numeric) [if] [in] [, Level(cilevel) noTABle ///
        SAVing(string) TItle(string) REPlace]
    marksample touse
    xtfmg_xt
    local ivar `"`r(ivar)'"'
    local tvar `"`r(tvar)'"'
    markout `touse' `ivar' `tvar'
    gettoken dv xv : varlist
    local k : word count `xv'
    tempname h
    capture _estimates hold `h', restore nullok
    qui xtreg `dv' `xv' if `touse', fe
    local N    = e(N_g)
    local nobs = e(N)
    local Tbar = e(g_avg)
    tempname b V
    matrix `b' = J(1, `k', .)
    forvalues j = 1/`k' {
        local v : word `j' of `xv'
        matrix `b'[1,`j'] = _b[`v']
    }
    tempname VV
    matrix `VV' = e(V)
    matrix `V' = `VV'[1..`k', 1..`k']
    matrix colnames `b' = `xv'
    matrix colnames `V' = `xv'
    matrix rownames `V' = `xv'
    if ("`table'" != "notable") {
        xtfmg_head "fe" "`dv'" `N' `N' 0 `Tbar' `nobs' 0 "`ivar'" "`tvar'" . .
        xtfmg_ctable `b' `V' `level'
        di as txt "Pooled within (fixed-effects) estimator; slopes restricted to be common."
        di as txt "Inconsistent for the mean slope when the true slopes are heterogeneous"
        di as txt "(Pesaran and Smith 1995); reported as a benchmark."
    }
    if (`"`saving'"' != "") {
        tempname pse
        matrix `pse' = J(1, `k', .)
        forvalues j = 1/`k' {
            matrix `pse'[1,`j'] = sqrt(el(`V',`j',`j'))
        }
        if (`"`title'"' == "") local title "Fixed-effects estimates. Dependent variable: `dv'"
        local n1 "N = `N', average T = `=trim(string(`Tbar',"%9.1f"))', observations = `nobs'."
        local n3 "Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01."
        xtfmg_exp, fname(`"`saving'"') `replace' title(`"`title'"') ///
            rnames(`xv') clabels(FE) bmats(`b') semats(`pse') ///
            note1(`"`n1'"') note3(`"`n3'"')
    }
    return scalar N    = `N'
    return scalar Tbar = `Tbar'
    return scalar n    = `nobs'
    return scalar k    = `k'
    return local estimator "fe"
    return local depvar "`dv'"
    return local indepvars "`xv'"
    return matrix V = `V'
    return matrix b = `b'
end

* ---------------------------------------------------------------------------
* all six estimators + journal-style comparison table (paper Table 8 style)
* ---------------------------------------------------------------------------
program define xtfmg_all, rclass
    syntax varlist(min=2 numeric) [if] [in] [, Kfreq(integer 1) Level(cilevel) ///
        COEFplot noTABle SAVing(string) TItle(string) REPlace]
    marksample touse
    xtfmg_xt
    local ivar `"`r(ivar)'"'
    local tvar `"`r(tvar)'"'
    markout `touse' `ivar' `tvar'
    qui count if `touse'
    if (r(N) < 10) {
        di as err "xtfmg: too few observations in the estimation sample"
        exit 2001
    }
    gettoken dv xv : varlist
    local k : word count `xv'
    if (`kfreq' < 1) {
        di as err "xtfmg: kfreq() must be a positive integer"
        exit 198
    }
    qui xtfmg_balchk `touse' `ivar' `tvar'
    local isbal = r(bal)

    * ---- FE ----
    tempname h
    capture _estimates hold `h', restore nullok
    qui xtreg `dv' `xv' if `touse', fe
    tempname b_fe V_fe pb_fe pse_fe
    matrix `pb_fe'  = J(1, `k'+2, .)
    matrix `pse_fe' = J(1, `k'+2, .)
    matrix `b_fe'   = J(1, `k', .)
    forvalues j = 1/`k' {
        local v : word `j' of `xv'
        matrix `b_fe'[1,`j']  = _b[`v']
        matrix `pb_fe'[1,`j'] = _b[`v']
        matrix `pse_fe'[1,`j'] = _se[`v']
    }
    tempname VVfe
    matrix `VVfe' = e(V)
    matrix `V_fe' = `VVfe'[1..`k', 1..`k']

    * ---- the five mean-group estimators ----
    local cd .
    local cdp .
    local alpha .
    local N .
    local Tbar .
    local nobs .
    foreach est in mg ccemg surmg fsurmg fccemg {
        tempname b_`est' V_`est' pb_`est' pse_`est'
        matrix `pb_`est''  = J(1, `k'+2, .)
        matrix `pse_`est'' = J(1, `k'+2, .)
        if (inlist("`est'","surmg","fsurmg") & !`isbal') {
            matrix `b_`est'' = J(1, `k', .)
            matrix `V_`est'' = J(`k', `k', .)
            local sursk 1
            continue
        }
        qui xtfmg_run `est' `dv' "`xv'" `touse' `ivar' `tvar' `kfreq'
        matrix `b_`est'' = r(bmg)
        matrix `V_`est'' = r(Vmg)
        if ("`est'"=="mg") {
            local cd    = r(cd)
            local cdp   = r(cdp)
            local alpha = r(alpha)
            local N     = r(N)
            local Tbar  = r(Tbar)
            local nobs  = r(n)
        }
        if ("`est'"=="fccemg") {
            tempname bu_fccemg seu_fccemg
            matrix `bu_fccemg'  = r(bu)
            matrix `seu_fccemg' = r(seu)
        }
        local nb = `k'
        if (inlist("`est'","fsurmg","fccemg")) local nb = `k' + 2
        forvalues j = 1/`nb' {
            matrix `pb_`est''[1,`j']  = el(`b_`est'',1,`j')
            matrix `pse_`est''[1,`j'] = sqrt(el(`V_`est'',`j',`j'))
        }
    }

    * ---- comparison table ----
    if ("`table'" != "notable") {
        di as txt ""
        di as res "Second-generation heterogeneous panel estimators - comparison"
        di as txt "Dependent variable: " as res "`dv'"
        di as txt "{hline 90}"
        di as txt %-12s "" %13s "(1)" %13s "(2)" %13s "(3)" ///
            %13s "(4)" %13s "(5)" %13s "(6)"
        di as txt %-12s "" %13s "FE" %13s "MG" %13s "CCEMG" ///
            %13s "SURMG" %13s "F-SURMG" %13s "F-CCEMG"
        di as txt "{hline 90}"
        forvalues j = 1/`=`k'+2' {
            if (`j' <= `k') local rnm : word `j' of `xv'
            else if (`j' == `k'+1) local rnm "sin"
            else local rnm "cos"
            local rowb ""
            local rows ""
            foreach e in fe mg ccemg surmg fsurmg fccemg {
                local bj = el(`pb_`e'',1,`j')
                local sj = el(`pse_`e'',1,`j')
                if (`bj' >= .) {
                    local cb ""
                    local cs ""
                }
                else {
                    local st ""
                    if (`sj' < . & `sj' > 0) {
                        local pj = 2*(1 - normal(abs(`bj'/`sj')))
                        if (`pj' < 0.01) local st "***"
                        else if (`pj' < 0.05) local st "**"
                        else if (`pj' < 0.10) local st "*"
                    }
                    local cb = string(`bj', "%9.3f") + "`st'"
                    local cs = "(" + string(`sj', "%7.3f") + ")"
                }
                local rowb `"`rowb' %13s "`cb'""'
                local rows `"`rows' %13s "`cs'""'
            }
            di as txt %-12s abbrev("`rnm'",12) as res `rowb'
            di as txt %-12s "" as txt `rows'
        }
        di as txt "{hline 90}"
        di as txt "N = " as res `N' as txt ", avg T = " as res %5.1f `Tbar' ///
            as txt ", obs = " as res `nobs' as txt ".  Fourier frequency k = " ///
            as res `kfreq' as txt "."
        di as txt "Residual CD = " as res %6.2f `cd' as txt " (p = " ///
            as res %5.3f `cdp' as txt "), CSD exponent alpha = " ///
            as res %5.3f `alpha' as txt " (Bailey-Kapetanios-Pesaran 2016)."
        di as txt "* p<0.10, ** p<0.05, *** p<0.01.  MG-type variances: Pesaran-Smith (1995)."
        di as txt "sin/cos rows: mean-group averages of the unit-specific Fourier coefficients."
        if ("`sursk'"=="1") {
            di as txt "note: SURMG and F-SURMG skipped - the estimation sample is unbalanced."
        }
        di as txt "{hline 90}"
    }

    * ---- journal-format export (before returns) ----
    if (`"`saving'"' != "") {
        if (`"`title'"' == "") {
            local title "Mean-group estimates: second-generation heterogeneous panel estimators. Dependent variable: `dv'"
        }
        local n1 "N = `N', average T = `=trim(string(`Tbar',"%9.1f"))', observations = `nobs'. Fourier frequency k = `kfreq'."
        local n2 "Residual CD = `=trim(string(`cd',"%9.2f"))' (p = `=trim(string(`cdp',"%9.3f"))'); CSD exponent alpha = `=trim(string(`alpha',"%9.3f"))' (Bailey-Kapetanios-Pesaran 2016)."
        local n3 "Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01. Mean-group variances: Pesaran-Smith (1995). sin/cos: mean-group Fourier coefficients."
        xtfmg_exp, fname(`"`saving'"') `replace' title(`"`title'"') ///
            rnames(`xv' sin cos) clabels(FE MG CCEMG SURMG F-SURMG F-CCEMG) ///
            bmats(`pb_fe' `pb_mg' `pb_ccemg' `pb_surmg' `pb_fsurmg' `pb_fccemg') ///
            semats(`pse_fe' `pse_mg' `pse_ccemg' `pse_surmg' `pse_fsurmg' `pse_fccemg') ///
            note1(`"`n1'"') note2(`"`n2'"') note3(`"`n3'"')
    }

    * ---- coefficient comparison plot (before returns) ----
    if ("`coefplot'" != "") {
        local zc = invnormal(1 - (100-`level')/200)
        local kp = min(`k', 6)
        preserve
        qui drop _all
        qui set obs 6
        qui gen idx = _n
        qui gen double bb = .
        qui gen double lo = .
        qui gen double hi = .
        local glist ""
        forvalues j = 1/`kp' {
            local v : word `j' of `xv'
            local e 0
            foreach est in fe mg ccemg surmg fsurmg fccemg {
                local ++e
                qui replace bb = el(`pb_`est'',1,`j') in `e'
                qui replace lo = el(`pb_`est'',1,`j') - `zc'*el(`pse_`est'',1,`j') in `e'
                qui replace hi = el(`pb_`est'',1,`j') + `zc'*el(`pse_`est'',1,`j') in `e'
            }
            twoway (rcap lo hi idx, lcolor(navy) lwidth(medthin)) ///
                   (scatter bb idx, mcolor(maroon) msymbol(D) msize(medium)), ///
                xlabel(1 "FE" 2 "MG" 3 "CCEMG" 4 "SURMG" 5 "F-SURMG" 6 "F-CCEMG", ///
                    angle(45) labsize(small)) ///
                yline(0, lpattern(dash) lcolor(gs8)) ///
                xtitle("") ytitle("Mean-group estimate") ///
                title("`v'", size(medium)) legend(off) ///
                xscale(range(0.5 6.5)) ///
                graphregion(color(white)) name(__xtfmgc`j', replace) nodraw
            local glist `glist' __xtfmgc`j'
        }
        restore
        graph combine `glist', cols(2) graphregion(color(white)) ///
            title("Mean-group estimates and `level'% confidence intervals", size(medium)) ///
            note("FE MG CCEMG SURMG F-SURMG F-CCEMG; Pesaran-Smith variances for MG-type estimators.", size(vsmall)) ///
            name(xtfmg_coef, replace)
        capture graph drop `glist'
    }

    * ---- combined matrices ----
    tempname BB SE
    matrix `BB' = (`pb_fe' \ `pb_mg' \ `pb_ccemg' \ `pb_surmg' \ `pb_fsurmg' \ `pb_fccemg')'
    matrix `SE' = (`pse_fe' \ `pse_mg' \ `pse_ccemg' \ `pse_surmg' \ `pse_fsurmg' \ `pse_fccemg')'
    matrix colnames `BB' = FE MG CCEMG SURMG F_SURMG F_CCEMG
    matrix colnames `SE' = FE MG CCEMG SURMG F_SURMG F_CCEMG
    matrix rownames `BB' = `xv' sin cos
    matrix rownames `SE' = `xv' sin cos

    return scalar N     = `N'
    return scalar Tbar  = `Tbar'
    return scalar n     = `nobs'
    return scalar k     = `k'
    return scalar kfreq = `kfreq'
    return scalar cd    = `cd'
    return scalar cd_p  = `cdp'
    return scalar alpha = `alpha'
    return scalar balanced = `isbal'
    return local depvar "`dv'"
    return local indepvars "`xv'"
    capture matrix colnames `b_fccemg' = `xv' sin cos
    capture matrix colnames `b_fsurmg' = `xv' sin cos
    capture matrix colnames `b_mg'     = `xv'
    capture matrix colnames `b_ccemg'  = `xv'
    capture matrix colnames `b_surmg'  = `xv'
    capture matrix colnames `b_fe'     = `xv'
    return matrix b_fe     = `b_fe'
    return matrix V_fe     = `V_fe'
    return matrix b_mg     = `b_mg'
    return matrix V_mg     = `V_mg'
    return matrix b_ccemg  = `b_ccemg'
    return matrix V_ccemg  = `V_ccemg'
    return matrix b_surmg  = `b_surmg'
    return matrix V_surmg  = `V_surmg'
    return matrix b_fsurmg = `b_fsurmg'
    return matrix V_fsurmg = `V_fsurmg'
    return matrix b_fccemg = `b_fccemg'
    return matrix V_fccemg = `V_fccemg'
    capture return matrix bunit_fccemg  = `bu_fccemg'
    capture return matrix seunit_fccemg = `seu_fccemg'
    return matrix SE = `SE'
    return matrix B  = `BB'
end

* ---------------------------------------------------------------------------
* per-unit sup-Wald intercept-break test (Andrews 1993) - paper Table 7 style
* ---------------------------------------------------------------------------
program define xtfmg_breaks, rclass
    syntax varlist(min=2 numeric) [if] [in] [, TRIM(real 0.15) PLOT ///
        SAVing(string) TItle(string) REPlace]
    if (`trim' <= 0 | `trim' >= 0.5) {
        di as err "xtfmg breaks: trim() must lie strictly between 0 and 0.5"
        exit 198
    }
    marksample touse
    xtfmg_xt
    local ivar `"`r(ivar)'"'
    local tvar `"`r(tvar)'"'
    markout `touse' `ivar' `tvar'
    gettoken dv xv : varlist
    local xv : list retokenize xv
    local k : word count `xv'
    tempname h
    capture _estimates hold `h', restore nullok
    qui levelsof `ivar' if `touse', local(units)
    local N : word count `units'
    if (`N' < 1) {
        di as err "xtfmg breaks: no panel units in the estimation sample"
        exit 2001
    }
    tempname RES
    matrix `RES' = J(`N', 3, .)
    tempvar D
    qui gen byte `D' = .
    local fmt : format `tvar'
    local i 0
    foreach u of local units {
        local ++i
        matrix `RES'[`i',3] = `u'
        qui count if `touse' & `ivar'==`u'
        if (r(N) < `k' + 6) continue
        qui su `tvar' if `touse' & `ivar'==`u', meanonly
        local t0 = r(min)
        local t1 = r(max)
        local Tspan = `t1' - `t0' + 1
        local lo = `t0' + ceil(`trim' * `Tspan')
        local hi = `t1' - ceil(`trim' * `Tspan')
        if (`lo' > `hi') continue
        local supw = -1
        local bdate = .
        forvalues tau = `lo'/`hi' {
            qui replace `D' = (`tvar' > `tau') if `touse' & `ivar'==`u'
            capture qui regress `dv' `xv' `D' if `touse' & `ivar'==`u'
            if (_rc) continue
            if (_se[`D'] <= 0) continue
            local w = (_b[`D'] / _se[`D'])^2
            if (`w' > `supw') {
                local supw = `w'
                local bdate = `tau'
            }
        }
        if (`supw' >= 0) {
            matrix `RES'[`i',1] = `supw'
            matrix `RES'[`i',2] = `bdate'
        }
    }
    matrix colnames `RES' = supWald breakdate id
    local rn ""
    foreach u of local units {
        local rn `rn' u`u'
    }
    matrix rownames `RES' = `rn'

    * Andrews (1993; 2003 corrigendum) critical values, one parameter, 15% trimming
    local cv10 = 7.12
    local cv5  = 8.68
    local cv1  = 12.16

    di as txt ""
    di as res "Structural break tests: sup-Wald for a single intercept break at unknown date"
    di as txt "Andrews (1993, 2003); trimming = " as res %4.2f `trim'
    di as txt "{hline 66}"
    di as txt %-20s "Unit" %12s "sup-Wald" %14s "Break date" %14s "Significance"
    di as txt "{hline 66}"
    local i 0
    foreach u of local units {
        local ++i
        local lb : label (`ivar') `u'
        local w  = el(`RES',`i',1)
        local bd = el(`RES',`i',2)
        local st ""
        if (`w' < .) {
            if (`w' > `cv1') local st "***"
            else if (`w' > `cv5') local st "**"
            else if (`w' > `cv10') local st "*"
        }
        local dstr ""
        if (`bd' < .) {
            local dstr : display `fmt' `bd'
            local dstr = trim("`dstr'")
        }
        di as txt %-20s abbrev(`"`lb'"',20) as res %12.2f `w' %14s "`dstr'" %14s "`st'"
    }
    di as txt "{hline 66}"
    di as txt "Critical values (one parameter, 15% trimming): 10%: " as res `cv10' ///
        as txt "  5%: " as res `cv5' as txt "  1%: " as res `cv1'
    di as txt "* p<0.10, ** p<0.05, *** p<0.01. Regression: `dv' on `xv' and a level-shift dummy."
    if (abs(`trim' - 0.15) > 0.001) {
        di as txt "note: the tabulated critical values assume 15% trimming; interpret with care."
    }

    * journal-format export (before returning the matrix)
    if (`"`saving'"' != "") {
        if (`"`title'"' == "") {
            local title "Structural break tests and break dates (sup-Wald, Andrews 1993)"
        }
        local n1 "Sup-Wald test for a single intercept break at an unknown date; trimming = `=trim(string(`trim',"%9.2f"))'."
        local n2 "Critical values (one parameter, 15% trimming): 10%: `cv10'; 5%: `cv5'; 1%: `cv1'."
        local n3 "* p<0.10, ** p<0.05, *** p<0.01. Regression: `dv' on `xv' and a level-shift dummy."
        xtfmg_exp_brk, fname(`"`saving'"') `replace' title(`"`title'"') ///
            res(`RES') ivar(`ivar') fmt(`fmt') ///
            note1(`"`n1'"') note2(`"`n2'"') note3(`"`n3'"')
    }

    * plot before returning the matrix
    if ("`plot'" != "") {
        local ylab ""
        local i 0
        foreach u of local units {
            local ++i
            local lb : label (`ivar') `u'
            local ylab `ylab' `i' `"`lb'"'
        }
        preserve
        qui drop _all
        qui svmat double `RES', name(bp)
        qui gen idx = _n
        qui su bp2, meanonly
        twoway (scatter idx bp2, mcolor(maroon) msymbol(D) msize(medium) ///
                mlabel(bp2) mlabformat(`fmt') mlabposition(3) mlabsize(small)), ///
            ylabel(`ylab', angle(0) labsize(small)) ytitle("") ///
            xtitle("Estimated break date") ///
            title("Heterogeneously-timed structural breaks", size(medium)) ///
            note("Per-unit sup-Wald intercept-break test (Andrews 1993), trimming `trim'.", size(vsmall)) ///
            graphregion(color(white)) name(xtfmg_breaks, replace)
        restore
    }

    return scalar N = `N'
    return scalar cv10 = `cv10'
    return scalar cv5  = `cv5'
    return scalar cv1  = `cv1'
    return local depvar "`dv'"
    return local indepvars "`xv'"
    return matrix breaks = `RES'
end

* ---------------------------------------------------------------------------
* regime map: CD + BKP alpha diagnostics and estimator recommendation
* ---------------------------------------------------------------------------
program define xtfmg_map, rclass
    syntax varlist(min=2 numeric) [if] [in]
    marksample touse
    xtfmg_xt
    local ivar `"`r(ivar)'"'
    local tvar `"`r(tvar)'"'
    markout `touse' `ivar' `tvar'
    gettoken dv xv : varlist
    qui xtfmg_run mg `dv' "`xv'" `touse' `ivar' `tvar' 1
    local N     = r(N)
    local Tbar  = r(Tbar)
    local nobs  = r(n)
    local cd    = r(cd)
    local cdp   = r(cdp)
    local alpha = r(alpha)

    local regime "moderate"
    if (`alpha' < .) {
        if (`alpha' < 0.5) local regime "weak"
        else if (`alpha' < 0.85) local regime "moderate"
        else local regime "strong"
    }
    else {
        if (`cdp' >= 0.05) local regime "weak"
    }
    local rec "F-CCEMG"
    if ("`regime'"=="weak" & `N' < 10) local rec "F-SURMG"
    if ("`regime'"=="strong" & `N' >= 30) local rec "CCEMG (F-CCEMG for accuracy)"

    di as txt ""
    di as res "Regime map for second-generation heterogeneous panel estimators"
    di as txt "{hline 78}"
    di as txt "Panel variable: " as res abbrev("`ivar'",16) as txt _col(44) ///
        "Number of groups  N = " as res %6.0f `N'
    di as txt "Time variable:  " as res abbrev("`tvar'",16) as txt _col(44) ///
        "Avg periods       T = " as res %6.1f `Tbar'
    di as txt _col(44) "Number of obs       = " as res %6.0f `nobs'
    di as txt "{hline 78}"
    di as txt "Cross-sectional dependence diagnostics (Mean Group residuals):"
    di as txt "  Pesaran (2015) CD statistic     = " as res %8.2f `cd' ///
        as txt "   p-value = " as res %5.3f `cdp'
    di as txt "  CSD exponent alpha (BKP 2016)   = " as res %8.3f `alpha'
    di as txt "  Dependence regime               = " as res "`regime'"
    di as txt "{hline 78}"
    di as txt "Regime map (Guliyev 2026):"
    di as txt "  Dependence {c |} very small N (<10)      moderate / large N"
    di as txt "  {hline 10}{c +}{hline 56}"
    di as txt "  weak       {c |} F-SURMG                 F-CCEMG"
    di as txt "  moderate   {c |} F-CCEMG                 F-CCEMG"
    di as txt "  strong     {c |} F-CCEMG (caution)       CCEMG / F-CCEMG"
    di as txt "{hline 78}"
    di as txt "Recommended estimator for this panel: " as res "`rec'"
    if (`N' < 10) {
        di as txt "note: with N < 10 the cross-sectional-average approximation is imprecise;"
        di as txt "      read CCE-based results with caution and report F-SURMG alongside."
    }
    di as txt "{hline 78}"

    return scalar N     = `N'
    return scalar Tbar  = `Tbar'
    return scalar n     = `nobs'
    return scalar cd    = `cd'
    return scalar cd_p  = `cdp'
    return scalar alpha = `alpha'
    return local regime "`regime'"
    return local recommend "`rec'"
end

* ---------------------------------------------------------------------------
* display helpers
* ---------------------------------------------------------------------------
program define xtfmg_head
    args est dv N nused nskip Tbar nobs kfreq ivar tvar cd cdp
    local title ""
    if ("`est'"=="fe")     local title "Pooled fixed-effects estimator (homogeneous slopes)"
    if ("`est'"=="mg")     local title "Mean Group (MG) estimator - Pesaran and Smith (1995)"
    if ("`est'"=="ccemg")  local title "Common Correlated Effects Mean Group (CCEMG) - Pesaran (2006)"
    if ("`est'"=="surmg")  local title "SUR Mean Group (SURMG) estimator - Guliyev (2023)"
    if ("`est'"=="fsurmg") local title "Fourier SUR Mean Group (F-SURMG) - Guliyev (2023, 2025)"
    if ("`est'"=="fccemg") local title "Fourier CCE Mean Group (F-CCEMG) - Guliyev (2026)"
    di as txt ""
    di as res "`title'"
    di as txt "Dependent variable: " as res "`dv'"
    di as txt "{hline 78}"
    di as txt "Panel variable: " as res abbrev("`ivar'",16) as txt _col(44) ///
        "Number of groups  N = " as res %6.0f `N'
    di as txt "Time variable:  " as res abbrev("`tvar'",16) as txt _col(44) ///
        "Avg periods       T = " as res %6.1f `Tbar'
    di as txt _col(44) "Number of obs       = " as res %6.0f `nobs'
    if (`nskip' > 0) {
        di as txt "Units skipped (insufficient T or collinear regressors): " as res `nskip'
    }
    if (`cd' < .) {
        di as txt "Residual CD statistic = " as res %6.2f `cd' ///
            as txt "   p-value = " as res %5.3f `cdp'
    }
    di as txt "{hline 78}"
end

program define xtfmg_ctable
    args b V level
    local p = colsof(`b')
    local names : colnames `b'
    local zc = invnormal(1 - (100 - `level')/200)
    di as txt %-12s "" %15s "Coefficient" %11s "Std. err." %8s "z" ///
        %9s "P>|z|" %22s "[`level'% conf. interval]"
    di as txt "{hline 78}"
    forvalues j = 1/`p' {
        local nm : word `j' of `names'
        local bj = el(`b', 1, `j')
        local sj = sqrt(el(`V', `j', `j'))
        local zj = `bj'/`sj'
        local pj = 2*(1 - normal(abs(`zj')))
        local lo = `bj' - `zc'*`sj'
        local hi = `bj' + `zc'*`sj'
        local st ""
        if (`pj' < 0.01) local st "***"
        else if (`pj' < 0.05) local st "**"
        else if (`pj' < 0.10) local st "*"
        local cb = trim(string(`bj', "%12.4f")) + "`st'"
        di as txt %-12s abbrev("`nm'",12) as res %15s "`cb'" %11.4f `sj' ///
            %8.2f `zj' %9.3f `pj' %12.4f `lo' %10.4f `hi'
    }
    di as txt "{hline 78}"
    di as txt "* p<0.10, ** p<0.05, *** p<0.01"
end

* ---------------------------------------------------------------------------
* heterogeneity (forest) plot of unit-specific slopes
* ---------------------------------------------------------------------------
program define xtfmg_hplot
    args bu seu ids focus est level ivar
    local N = rowsof(`bu')
    local cols : colnames `bu'
    local j : list posof "`focus'" in cols
    local zc = invnormal(1 - (100-`level')/200)
    tempname M
    matrix `M' = J(`N', 4, .)
    local sum = 0
    local nn = 0
    forvalues i = 1/`N' {
        matrix `M'[`i',1] = `i'
        local bi = el(`bu',`i',`j')
        local si = el(`seu',`i',`j')
        if (`bi' < .) {
            matrix `M'[`i',2] = `bi'
            local sum = `sum' + `bi'
            local ++nn
            if (`si' < .) {
                matrix `M'[`i',3] = `bi' - `zc'*`si'
                matrix `M'[`i',4] = `bi' + `zc'*`si'
            }
        }
    }
    local mn = 0
    if (`nn' > 0) local mn = `sum'/`nn'
    local ylab ""
    forvalues i = 1/`N' {
        local u = strofreal(el(`ids',`i',1), "%12.0g")
        local lb : label (`ivar') `u'
        local ylab `ylab' `i' `"`lb'"'
    }
    local EST = upper("`est'")
    preserve
    qui drop _all
    qui svmat double `M', name(hp)
    twoway (rcap hp3 hp4 hp1, horizontal lcolor(navy) lwidth(medthin)) ///
           (scatter hp1 hp2, mcolor(maroon) msymbol(D) msize(medium)), ///
        xline(`mn', lpattern(dash) lcolor(gs6)) ///
        ylabel(`ylab', angle(0) labsize(small)) ytitle("") ///
        xtitle("Unit-specific slope on `focus'") ///
        title("Slope heterogeneity across units (`EST')", size(medium)) ///
        legend(order(2 "Unit estimate" 1 "`level'% CI") rows(1) size(small)) ///
        note("Dashed line: mean-group average. Unit CIs from unit-level variances.", size(vsmall)) ///
        graphregion(color(white)) name(xtfmg_hetero, replace)
    restore
end

* ---------------------------------------------------------------------------
* fitted Fourier components plot (the estimated smooth breaks, by unit)
* ---------------------------------------------------------------------------
program define xtfmg_fplot
    args fpath ids est tvar ivar
    local N = colsof(`fpath') - 1
    local EST = upper("`est'")
    local plots ""
    local leg ""
    forvalues i = 1/`N' {
        local v = `i' + 1
        local plots `plots' (line fp`v' fp1, lwidth(medthin))
        local u = strofreal(el(`ids',`i',1), "%12.0g")
        local lb : label (`ivar') `u'
        local leg `leg' `i' `"`lb'"'
    }
    local legopt "legend(order(`leg') rows(2) size(vsmall))"
    if (`N' > 12) local legopt "legend(off)"
    preserve
    qui drop _all
    qui svmat double `fpath', name(fp)
    twoway `plots', ///
        yline(0, lpattern(dash) lcolor(gs10)) ///
        xtitle("`tvar'") ytitle("Estimated Fourier component") ///
        title("Heterogeneously-timed smooth breaks (`EST')", size(medium)) ///
        note("Unit-specific gamma_i sin(2 pi k t/T) + lambda_i cos(2 pi k t/T) from each unit equation.", size(vsmall)) ///
        `legopt' graphregion(color(white)) name(xtfmg_fourier, replace)
    restore
end

* ---------------------------------------------------------------------------
* estimator display labels
* ---------------------------------------------------------------------------
program define xtfmg_elab, rclass
    args est
    local lab "`est'"
    if ("`est'"=="fe")     local lab "FE"
    if ("`est'"=="mg")     local lab "MG"
    if ("`est'"=="ccemg")  local lab "CCEMG"
    if ("`est'"=="surmg")  local lab "SURMG"
    if ("`est'"=="fsurmg") local lab "F-SURMG"
    if ("`est'"=="fccemg") local lab "F-CCEMG"
    return local lab "`lab'"
end

* ---------------------------------------------------------------------------
* journal-format table export: coefficient/(se) layout
* writes LaTeX (booktabs), RTF/Word, CSV or aligned text by file extension
* ---------------------------------------------------------------------------
program define xtfmg_exp
    syntax , fname(string) rnames(string) clabels(string) bmats(string) ///
        semats(string) [title(string) replace note1(string) note2(string) ///
        note3(string)]
    local ncol : word count `clabels'
    local nrow : word count `rnames'
    local dot = strrpos("`fname'", ".")
    if (`dot' == 0) {
        local fname "`fname'.tex"
        local dot = strrpos("`fname'", ".")
    }
    local ext = lower(substr("`fname'", `dot'+1, .))
    if (!inlist("`ext'", "tex", "rtf", "doc", "csv", "txt")) {
        di as err "saving(): the file extension must be .tex, .rtf, .doc, .csv or .txt"
        exit 198
    }
    if ("`replace'" == "") {
        capture confirm new file `"`fname'"'
        if (_rc) {
            di as err `"saving(): file `fname' already exists; specify replace"'
            exit 602
        }
    }
    * precompute cell strings: coefficient, stars, (se)
    forvalues r = 1/`nrow' {
        forvalues c = 1/`ncol' {
            local bm : word `c' of `bmats'
            local sm : word `c' of `semats'
            local bj = el(`bm', 1, `r')
            local sj = el(`sm', 1, `r')
            local cb_`r'_`c' ""
            local st_`r'_`c' ""
            local cs_`r'_`c' ""
            if (`bj' < .) {
                local cb_`r'_`c' = trim(string(`bj', "%12.3f"))
                if (`sj' < . & `sj' > 0) {
                    local pj = 2*(1 - normal(abs(`bj'/`sj')))
                    if (`pj' < 0.01) local st_`r'_`c' "***"
                    else if (`pj' < 0.05) local st_`r'_`c' "**"
                    else if (`pj' < 0.10) local st_`r'_`c' "*"
                    local cs_`r'_`c' = "(" + trim(string(`sj', "%12.3f")) + ")"
                }
            }
        }
    }
    tempname fh
    file open `fh' using `"`fname'"', write text replace
    if ("`ext'"=="tex") {
        file write `fh' "% Table created by xtfmg on `c(current_date)'" _n
        file write `fh' "% Add \usepackage{booktabs} to the document preamble" _n
        file write `fh' "\begin{table}[htbp]" _n "\centering" _n
        local ttex `"`title'"'
        local ttex : subinstr local ttex "_" "\_", all
        local ttex : subinstr local ttex "%" "\%", all
        file write `fh' `"\caption{`ttex'}"' _n
        file write `fh' "\begin{tabular}{l*{`ncol'}{c}}" _n "\toprule" _n
        if (`ncol' > 1) {
            local hd ""
            forvalues c = 1/`ncol' {
                local hd "`hd' & (`c')"
            }
            file write `fh' `"`hd' \\"' _n
        }
        local hd ""
        forvalues c = 1/`ncol' {
            local cl : word `c' of `clabels'
            local hd "`hd' & `cl'"
        }
        file write `fh' `"`hd' \\"' _n "\midrule" _n
        forvalues r = 1/`nrow' {
            local rn : word `r' of `rnames'
            local rn : subinstr local rn "_" "\_", all
            local line "`rn'"
            local line2 ""
            forvalues c = 1/`ncol' {
                local cell "`cb_`r'_`c''"
                if ("`st_`r'_`c''" != "") local cell "`cell'\textsuperscript{`st_`r'_`c''}"
                local line "`line' & `cell'"
                local line2 "`line2' & `cs_`r'_`c''"
            }
            file write `fh' `"`line' \\"' _n
            file write `fh' `"`line2' \\"' _n
        }
        file write `fh' "\bottomrule" _n
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") {
                local ntx `"``nt''"'
                local ntx : subinstr local ntx "_" "\_", all
                local ntx : subinstr local ntx "%" "\%", all
                local ntx : subinstr local ntx "<" "\textless{}", all
                file write `fh' `"\multicolumn{`=`ncol'+1'}{l}{\footnotesize `ntx'} \\"' _n
            }
        }
        file write `fh' "\end{tabular}" _n "\end{table}" _n
    }
    else if ("`ext'"=="rtf" | "`ext'"=="doc") {
        local w = 2200
        local cellxs "`w'"
        forvalues c = 1/`ncol' {
            local w = `w' + 1400
            local cellxs "`cellxs' `w'"
        }
        file write `fh' "{\rtf1\ansi\deff0{\fonttbl{\f0\froman Times New Roman;}}" _n
        file write `fh' "\fs20" _n
        file write `fh' `"\pard\ql\b `title'\b0\par"' _n
        local topdone 0
        if (`ncol' > 1) {
            file write `fh' "\trowd\trgaph80"
            foreach x of local cellxs {
                file write `fh' "\clbrdrt\brdrs\brdrw20\cellx`x'"
            }
            file write `fh' "\pard\intbl\ql \cell"
            forvalues c = 1/`ncol' {
                file write `fh' "\pard\intbl\qc (`c')\cell"
            }
            file write `fh' "\row" _n
            local topdone 1
        }
        file write `fh' "\trowd\trgaph80"
        foreach x of local cellxs {
            if (`topdone') file write `fh' "\clbrdrb\brdrs\brdrw20\cellx`x'"
            else file write `fh' "\clbrdrt\brdrs\brdrw20\clbrdrb\brdrs\brdrw20\cellx`x'"
        }
        file write `fh' "\pard\intbl\ql \cell"
        forvalues c = 1/`ncol' {
            local cl : word `c' of `clabels'
            file write `fh' "\pard\intbl\qc `cl'\cell"
        }
        file write `fh' "\row" _n
        forvalues r = 1/`nrow' {
            local last = (`r' == `nrow')
            file write `fh' "\trowd\trgaph80"
            foreach x of local cellxs {
                file write `fh' "\cellx`x'"
            }
            local rn : word `r' of `rnames'
            file write `fh' "\pard\intbl\ql `rn'\cell"
            forvalues c = 1/`ncol' {
                local cell "`cb_`r'_`c''"
                if ("`st_`r'_`c''" != "") local cell "`cell'{\super `st_`r'_`c''}"
                file write `fh' "\pard\intbl\qc `cell'\cell"
            }
            file write `fh' "\row" _n
            file write `fh' "\trowd\trgaph80"
            foreach x of local cellxs {
                if (`last') file write `fh' "\clbrdrb\brdrs\brdrw20\cellx`x'"
                else file write `fh' "\cellx`x'"
            }
            file write `fh' "\pard\intbl\ql \cell"
            forvalues c = 1/`ncol' {
                file write `fh' "\pard\intbl\qc `cs_`r'_`c''\cell"
            }
            file write `fh' "\row" _n
        }
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") {
                file write `fh' `"\pard\ql\fs18 ``nt''\par"' _n
            }
        }
        file write `fh' "}" _n
    }
    else if ("`ext'"=="csv") {
        file write `fh' `""`title'""' _n
        local line ""
        forvalues c = 1/`ncol' {
            local cl : word `c' of `clabels'
            local line `"`line',"`cl'""'
        }
        file write `fh' `"`line'"' _n
        forvalues r = 1/`nrow' {
            local rn : word `r' of `rnames'
            local line `""`rn'""'
            local line2 `""""'
            forvalues c = 1/`ncol' {
                local line `"`line',"`cb_`r'_`c''`st_`r'_`c''""'
                local line2 `"`line2',"`cs_`r'_`c''""'
            }
            file write `fh' `"`line'"' _n
            file write `fh' `"`line2'"' _n
        }
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") file write `fh' `""``nt''""' _n
        }
    }
    else {
        file write `fh' `"`title'"' _n
        local wid = 14 + 13*`ncol'
        local rule : display _dup(`wid') "-"
        file write `fh' "`rule'" _n
        if (`ncol' > 1) {
            file write `fh' %-14s ""
            forvalues c = 1/`ncol' {
                file write `fh' %13s "(`c')"
            }
            file write `fh' _n
        }
        file write `fh' %-14s ""
        forvalues c = 1/`ncol' {
            local cl : word `c' of `clabels'
            file write `fh' %13s "`cl'"
        }
        file write `fh' _n "`rule'" _n
        forvalues r = 1/`nrow' {
            local rn : word `r' of `rnames'
            local rn = abbrev("`rn'", 14)
            file write `fh' %-14s "`rn'"
            forvalues c = 1/`ncol' {
                file write `fh' %13s "`cb_`r'_`c''`st_`r'_`c''"
            }
            file write `fh' _n %-14s ""
            forvalues c = 1/`ncol' {
                file write `fh' %13s "`cs_`r'_`c''"
            }
            file write `fh' _n
        }
        file write `fh' "`rule'" _n
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") file write `fh' `"``nt''"' _n
        }
    }
    file close `fh'
    di as txt `"journal-format table saved to `fname'"'
end

* ---------------------------------------------------------------------------
* journal-format export of the structural-break table
* ---------------------------------------------------------------------------
program define xtfmg_exp_brk
    syntax , fname(string) res(string) ivar(string) fmt(string) ///
        [title(string) replace note1(string) note2(string) note3(string)]
    local N = rowsof(`res')
    local dot = strrpos("`fname'", ".")
    if (`dot' == 0) {
        local fname "`fname'.tex"
        local dot = strrpos("`fname'", ".")
    }
    local ext = lower(substr("`fname'", `dot'+1, .))
    if (!inlist("`ext'", "tex", "rtf", "doc", "csv", "txt")) {
        di as err "saving(): the file extension must be .tex, .rtf, .doc, .csv or .txt"
        exit 198
    }
    if ("`replace'" == "") {
        capture confirm new file `"`fname'"'
        if (_rc) {
            di as err `"saving(): file `fname' already exists; specify replace"'
            exit 602
        }
    }
    forvalues i = 1/`N' {
        local u = strofreal(el(`res',`i',3), "%12.0g")
        local lb`i' : label (`ivar') `u'
        local w = el(`res',`i',1)
        local st`i' ""
        local ws`i' ""
        if (`w' < .) {
            local ws`i' = trim(string(`w', "%12.2f"))
            if (`w' > 12.16) local st`i' "***"
            else if (`w' > 8.68) local st`i' "**"
            else if (`w' > 7.12) local st`i' "*"
        }
        local bd = el(`res',`i',2)
        local ds`i' ""
        if (`bd' < .) {
            local ds`i' : display `fmt' `bd'
            local ds`i' = trim("`ds`i''")
        }
    }
    tempname fh
    file open `fh' using `"`fname'"', write text replace
    if ("`ext'"=="tex") {
        file write `fh' "% Table created by xtfmg on `c(current_date)'" _n
        file write `fh' "% Add \usepackage{booktabs} to the document preamble" _n
        file write `fh' "\begin{table}[htbp]" _n "\centering" _n
        local ttex `"`title'"'
        local ttex : subinstr local ttex "_" "\_", all
        file write `fh' `"\caption{`ttex'}"' _n
        file write `fh' "\begin{tabular}{lcc}" _n "\toprule" _n
        file write `fh' "Unit & sup-Wald & Break date \\" _n "\midrule" _n
        forvalues i = 1/`N' {
            local lb `"`lb`i''"'
            local lb : subinstr local lb "_" "\_", all
            local cell "`ws`i''"
            if ("`st`i''" != "") local cell "`cell'\textsuperscript{`st`i''}"
            file write `fh' `"`lb' & `cell' & `ds`i'' \\"' _n
        }
        file write `fh' "\bottomrule" _n
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") {
                local ntx `"``nt''"'
                local ntx : subinstr local ntx "_" "\_", all
                local ntx : subinstr local ntx "%" "\%", all
                local ntx : subinstr local ntx "<" "\textless{}", all
                file write `fh' `"\multicolumn{3}{l}{\footnotesize `ntx'} \\"' _n
            }
        }
        file write `fh' "\end{tabular}" _n "\end{table}" _n
    }
    else if ("`ext'"=="rtf" | "`ext'"=="doc") {
        local cellxs "2600 4200 5800"
        file write `fh' "{\rtf1\ansi\deff0{\fonttbl{\f0\froman Times New Roman;}}" _n
        file write `fh' "\fs20" _n
        file write `fh' `"\pard\ql\b `title'\b0\par"' _n
        file write `fh' "\trowd\trgaph80"
        foreach x of local cellxs {
            file write `fh' "\clbrdrt\brdrs\brdrw20\clbrdrb\brdrs\brdrw20\cellx`x'"
        }
        file write `fh' "\pard\intbl\ql Unit\cell\pard\intbl\qc sup-Wald\cell\pard\intbl\qc Break date\cell\row" _n
        forvalues i = 1/`N' {
            file write `fh' "\trowd\trgaph80"
            foreach x of local cellxs {
                if (`i' == `N') file write `fh' "\clbrdrb\brdrs\brdrw20\cellx`x'"
                else file write `fh' "\cellx`x'"
            }
            local cell "`ws`i''"
            if ("`st`i''" != "") local cell "`cell'{\super `st`i''}"
            file write `fh' `"\pard\intbl\ql `lb`i''\cell\pard\intbl\qc `cell'\cell\pard\intbl\qc `ds`i''\cell\row"' _n
        }
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") {
                file write `fh' `"\pard\ql\fs18 ``nt''\par"' _n
            }
        }
        file write `fh' "}" _n
    }
    else if ("`ext'"=="csv") {
        file write `fh' `""`title'""' _n
        file write `fh' `""Unit","sup-Wald","Break date""' _n
        forvalues i = 1/`N' {
            file write `fh' `""`lb`i''","`ws`i''`st`i''","`ds`i''""' _n
        }
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") file write `fh' `""``nt''""' _n
        }
    }
    else {
        file write `fh' `"`title'"' _n
        local rule : display _dup(52) "-"
        file write `fh' "`rule'" _n
        file write `fh' %-22s "Unit" %14s "sup-Wald" %16s "Break date" _n
        file write `fh' "`rule'" _n
        forvalues i = 1/`N' {
            local lb = abbrev(`"`lb`i''"', 22)
            file write `fh' %-22s `"`lb'"' %14s "`ws`i''`st`i''" %16s "`ds`i''" _n
        }
        file write `fh' "`rule'" _n
        foreach nt in note1 note2 note3 {
            if (`"``nt''"' != "") file write `fh' `"``nt''"' _n
        }
    }
    file close `fh'
    di as txt `"journal-format table saved to `fname'"'
end

* ===========================================================================
* Mata engine
* ===========================================================================
mata:

// binary search: position of x in sorted colvector v
real scalar xtfmg_bs(real colvector v, real scalar x)
{
    real scalar lo, hi, mid
    lo = 1
    hi = rows(v)
    while (lo < hi) {
        mid = floor((lo + hi)/2)
        if (v[mid] < x) {
            lo = mid + 1
        }
        else {
            hi = mid
        }
    }
    return(lo)
}

// core estimator: unit-by-unit (optionally CCE- and Fourier-augmented) OLS,
// or joint feasible-GLS SUR, followed by mean-group averaging with the
// nonparametric Pesaran-Smith variance; also computes the Pesaran CD
// statistic and the (simple) Bailey-Kapetanios-Pesaran alpha exponent
// from the residuals.
void xtfmg_engine(string scalar yv, string scalar xlist,
                  string scalar idv, string scalar tv,
                  string scalar tousev, real scalar usecce,
                  real scalar usef, real scalar usesur,
                  real scalar kfreq)
{
    real matrix X, Zb, xbar, info, W, WtWi, Vb, bu, seu, E, Es, fpath
    real matrix Sig, P, A, Ai, Wbig, Wi, Wj, Bu, Vmg, dsq
    real colvector y, id, tm, ord, tu, tidx, ybar, cnt, yi, ei, b, ball, cc2
    real colvector s, si, ci, used, idxu, ids, zt, sel, selz
    real rowvector bmg, drow
    real scalar n, k, N, nT, i, j, r, r1, r2, Ti, p, foff, nb, nskip, nused
    real scalar tmin, tmax, Tsp, s2, bal, cd, Tij, rho, cdp, alph, s2m, mu, sd
    real scalar c1, c2, d1, d2, off

    y  = st_data(., yv, tousev)
    X  = st_data(., tokens(xlist), tousev)
    id = st_data(., idv, tousev)
    tm = st_data(., tv, tousev)

    // sort by (id, t) in Mata without touching the dataset
    ord = order((id, tm), (1, 2))
    y  = y[ord]
    X  = X[ord, .]
    id = id[ord]
    tm = tm[ord]
    n = rows(y)
    k = cols(X)

    info = panelsetup(id, 1)
    N = rows(info)
    if (N < 2) {
        errprintf("xtfmg: at least 2 panel units are required\n")
        exit(459)
    }

    // time index of each observation
    tu = uniqrows(tm)
    nT = rows(tu)
    tidx = J(n, 1, .)
    for (r=1; r<=n; r++) {
        tidx[r] = xtfmg_bs(tu, tm[r])
    }

    // cross-sectional averages by period
    ybar = J(nT, 1, 0)
    xbar = J(nT, k, 0)
    cnt  = J(nT, 1, 0)
    for (r=1; r<=n; r++) {
        j = tidx[r]
        ybar[j] = ybar[j] + y[r]
        xbar[j, .] = xbar[j, .] + X[r, .]
        cnt[j] = cnt[j] + 1
    }
    ybar = ybar :/ cnt
    xbar = xbar :/ cnt
    Zb = (ybar, xbar)

    // balance requirement for SUR-type estimation
    if (usesur) {
        bal = 1
        for (i=1; i<=N; i++) {
            Ti = info[i,2] - info[i,1] + 1
            if (Ti != nT) bal = 0
        }
        if (n != N*nT) bal = 0
        if (!bal) {
            errprintf("xtfmg: SUR-based estimators (surmg, fsurmg) require a balanced panel\n")
            exit(459)
        }
        if (nT <= N) {
            errprintf("xtfmg: SUR-based estimators require T > N so the error covariance can be estimated\n")
            exit(459)
        }
    }

    // per-unit design dimension and positions
    p = k + 1
    if (usecce) p = p + k + 1
    if (usef) p = p + 2
    foff = k
    if (usecce) foff = k + k + 1
    nb = k
    if (usef) nb = k + 2

    bu    = J(N, nb, .)
    seu   = J(N, nb, .)
    used  = J(N, 1, 0)
    E     = J(nT, N, .)
    fpath = J(nT, N, .)
    if (usesur) Wbig = J(nT, N*p, 0)
    nskip = 0

    for (i=1; i<=N; i++) {
        r1 = info[i,1]
        r2 = info[i,2]
        Ti = r2 - r1 + 1
        if (Ti <= p + 1) {
            nskip = nskip + 1
            continue
        }
        yi = y[|r1 \ r2|]
        W = X[|r1, 1 \ r2, k|]
        if (usecce) {
            W = (W, Zb[tidx[|r1 \ r2|], .])
        }
        if (usef) {
            tmin = tm[r1]
            tmax = tm[r2]
            Tsp = tmax - tmin + 1
            s = tm[|r1 \ r2|] :- tmin :+ 1
            si = sin(2 :* pi() :* kfreq :* s :/ Tsp)
            ci = cos(2 :* pi() :* kfreq :* s :/ Tsp)
            W = (W, si, ci)
        }
        W = (W, J(Ti, 1, 1))
        WtWi = invsym(cross(W, W))
        if (anyof(diagonal(WtWi), 0)) {
            nskip = nskip + 1
            continue
        }
        b = WtWi * cross(W, yi)
        ei = yi - W*b
        s2 = cross(ei, ei) / (Ti - p)
        Vb = s2 :* WtWi
        bu[|i, 1 \ i, k|] = b[|1 \ k|]'
        for (j=1; j<=k; j++) {
            seu[i, j] = sqrt(Vb[j, j])
        }
        if (usef) {
            bu[i, k+1] = b[foff+1]
            bu[i, k+2] = b[foff+2]
            seu[i, k+1] = sqrt(Vb[foff+1, foff+1])
            seu[i, k+2] = sqrt(Vb[foff+2, foff+2])
            fpath[tidx[|r1 \ r2|], i] = b[foff+1] :* si + b[foff+2] :* ci
        }
        used[i] = 1
        E[tidx[|r1 \ r2|], i] = ei
        if (usesur) {
            c1 = (i-1)*p + 1
            c2 = i*p
            Wbig[|1, c1 \ nT, c2|] = W
        }
    }

    if (usesur & nskip > 0) {
        errprintf("xtfmg: some units have too few observations or collinear regressors for SUR estimation\n")
        exit(459)
    }

    // feasible-GLS SUR second stage
    if (usesur) {
        Sig = cross(E, E) :/ nT
        P = invsym(Sig)
        if (anyof(diagonal(P), 0)) {
            errprintf("xtfmg: the SUR error covariance is singular; T may be too small relative to N\n")
            exit(459)
        }
        A = J(N*p, N*p, 0)
        cc2 = J(N*p, 1, 0)
        for (i=1; i<=N; i++) {
            c1 = (i-1)*p + 1
            c2 = i*p
            Wi = Wbig[|1, c1 \ nT, c2|]
            for (j=1; j<=N; j++) {
                d1 = (j-1)*p + 1
                d2 = j*p
                Wj = Wbig[|1, d1 \ nT, d2|]
                A[|c1, d1 \ c2, d2|] = P[i, j] :* cross(Wi, Wj)
                cc2[|c1 \ c2|] = cc2[|c1 \ c2|] +
                    P[i, j] :* cross(Wi, y[|info[j,1] \ info[j,2]|])
            }
        }
        Ai = invsym(A)
        ball = Ai * cc2
        for (i=1; i<=N; i++) {
            off = (i-1)*p
            bu[|i, 1 \ i, k|] = ball[|off+1 \ off+k|]'
            for (j=1; j<=k; j++) {
                seu[i, j] = sqrt(Ai[off+j, off+j])
            }
            if (usef) {
                bu[i, k+1] = ball[off+foff+1]
                bu[i, k+2] = ball[off+foff+2]
                seu[i, k+1] = sqrt(Ai[off+foff+1, off+foff+1])
                seu[i, k+2] = sqrt(Ai[off+foff+2, off+foff+2])
            }
            r1 = info[i,1]
            r2 = info[i,2]
            c1 = (i-1)*p + 1
            c2 = i*p
            Wi = Wbig[|1, c1 \ nT, c2|]
            ei = y[|r1 \ r2|] - Wi * ball[|off+1 \ off+p|]
            E[tidx[|r1 \ r2|], i] = ei
            if (usef) {
                tmin = tm[r1]
                tmax = tm[r2]
                Tsp = tmax - tmin + 1
                s = tm[|r1 \ r2|] :- tmin :+ 1
                si = sin(2 :* pi() :* kfreq :* s :/ Tsp)
                ci = cos(2 :* pi() :* kfreq :* s :/ Tsp)
                fpath[tidx[|r1 \ r2|], i] = bu[i, k+1] :* si + bu[i, k+2] :* ci
            }
        }
    }

    // mean-group average and Pesaran-Smith variance
    idxu = selectindex(used)
    nused = rows(idxu)
    if (nused < 2) {
        errprintf("xtfmg: fewer than 2 usable panel units\n")
        exit(459)
    }
    Bu = bu[idxu, .]
    bmg = mean(Bu)
    Vmg = J(nb, nb, 0)
    for (i=1; i<=nused; i++) {
        drow = Bu[i, .] - bmg
        Vmg = Vmg + drow'drow
    }
    Vmg = Vmg :/ (nused * (nused - 1))

    // Pesaran CD from the unit residuals (pairwise overlap)
    cd = 0
    for (i=1; i<=N-1; i++) {
        for (j=i+1; j<=N; j++) {
            sel = selectindex((E[.,i] :< .) :& (E[.,j] :< .))
            Tij = rows(sel)
            if (Tij > 3) {
                rho = correlation((E[sel,i], E[sel,j]))[2,1]
                if (rho < .) cd = cd + sqrt(Tij) * rho
            }
        }
    }
    cd = sqrt(2 / (N * (N - 1))) * cd
    cdp = 2 * (1 - normal(abs(cd)))

    // simple BKP (2016) alpha exponent from standardized residuals
    Es = E
    for (i=1; i<=N; i++) {
        sel = selectindex(E[., i] :< .)
        if (rows(sel) > 2) {
            mu = mean(E[sel, i])
            sd = sqrt(variance(E[sel, i]))
            if (sd > 0) Es[sel, i] = (E[sel, i] :- mu) :/ sd
        }
    }
    zt = J(nT, 1, .)
    for (r=1; r<=nT; r++) {
        sel = selectindex(Es[r, .]' :< .)
        if (rows(sel) > 1) zt[r] = mean(Es[r, sel]')
    }
    selz = selectindex(zt :< .)
    alph = .
    if (rows(selz) > 3) {
        s2m = variance(zt[selz])
        if (s2m > 0) alph = 1 + ln(s2m) / (2 * ln(N))
    }

    // unit ids in panel order
    ids = J(N, 1, .)
    for (i=1; i<=N; i++) {
        ids[i] = id[info[i,1]]
    }

    st_matrix("__xtfmg_bmg", bmg)
    st_matrix("__xtfmg_Vmg", Vmg)
    st_matrix("__xtfmg_bu", bu)
    st_matrix("__xtfmg_seu", seu)
    st_matrix("__xtfmg_fpath", (tu, fpath))
    st_matrix("__xtfmg_ids", ids)
    st_numscalar("__xtfmg_N", N)
    st_numscalar("__xtfmg_nused", nused)
    st_numscalar("__xtfmg_nskip", nskip)
    st_numscalar("__xtfmg_Tbar", n/N)
    st_numscalar("__xtfmg_n", n)
    st_numscalar("__xtfmg_cd", cd)
    st_numscalar("__xtfmg_cdp", cdp)
    st_numscalar("__xtfmg_alpha", alph)
}

end
