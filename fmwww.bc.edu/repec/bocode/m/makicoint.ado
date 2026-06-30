*! makicoint v2.0.0  30jun2026
*! Maki (2012) Cointegration Test with Multiple Structural Breaks
*! Author: Dr Merwan Roudane
*! Email: merwanroudane920@gmail.com
*! Independent Researcher  --  github.com/merwanroudane
*!
*! Reference: Maki, D. (2012). Tests for cointegration allowing for an
*!            unknown number of breaks. Economic Modelling, 29, 2011-2015.
*!            <doi:10.1016/j.econmod.2012.04.022>
*!
*! v2.0.0 changes
*!  - General recursive break-search engine: any number of breaks (not capped at 5),
*!    bounded only by sample size and trimming.
*!  - Default reproduces the original GAUSS/tspdlib implementation exactly (matches
*!    the standard results): segment chosen by min-tau, break by ADF-regression SSR.
*!    Option -paper- switches to the Maki (2012) Steps 2/4 method (global argmin of
*!    the cointegrating-regression SSR).
*!  - Fixes the m=3 "close-breaks" branch (old code searched the degenerate gap) and
*!    removes the hand-coded m=4/5 region trees (replaced by the general recursion).
*!  - For m>5 (outside Maki Table 1): simcv() Monte-Carlo critical values, paper's method.
*!  - graph option: two-panel dashboard (fitted relation + equilibrium error).
*!  - Faster: the fixed-break design is built once per step; only candidate columns
*!    are appended per iteration (the residual is invariant to column order).

program define makicoint, rclass
    version 14.0

    syntax varlist(min=2 ts) [if] [in], ///
        Maxbreaks(integer) ///
        [ Model(integer 2) ///
          TRIMming(real 0.10) ///
          MAXLags(integer 12) ///
          LAGMethod(string) ///
          GAUSS PAPER ///
          SIMcv(integer 0) ///
          SIMt(integer 1000) ///
          SIMSeed(integer 12345) ///
          GRaph ///
          NAME(string) ///
          REG REGNewey ]

    marksample touse

    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'

    if "`panelvar'" != "" {
        di as error "Panel data not supported. Please use a single time series."
        exit 198
    }
    if "`timevar'" == "" {
        di as error "Time variable not set. Please use -tsset- first."
        exit 198
    }

    gettoken depvar indepvars : varlist
    local numindep : word count `indepvars'

    if `maxbreaks' < 1 {
        di as error "maxbreaks() must be at least 1."
        exit 198
    }
    if `model' < 0 | `model' > 3 {
        di as error "model() must be 0 (level shift), 1 (level shift with trend),"
        di as error "         2 (regime shift), or 3 (regime shift with trend)."
        exit 198
    }
    if `numindep' < 1 | `numindep' > 4 {
        di as error "Number of independent variables must be between 1 and 4."
        di as error "Maki (2012) Table 1 critical values cover up to 4 regressors."
        exit 198
    }
    if `trimming' <= 0 | `trimming' >= 0.5 {
        di as error "trimming() must be between 0 and 0.5 (exclusive)."
        exit 198
    }
    if `maxlags' < 0 {
        di as error "maxlags() must be non-negative."
        exit 198
    }
    if `simcv' < 0 {
        di as error "simcv() must be non-negative."
        exit 198
    }

    if "`lagmethod'" == "" {
        local lagmethod "tsig"
    }
    if !inlist("`lagmethod'", "tsig", "fixed", "zero", "aic", "bic") {
        di as error "lagmethod must be one of: tsig, fixed, zero, aic, bic"
        exit 198
    }
    * lagopt codes for Mata: 1=tsig, 9=fixed(maxlags), 0=zero, 2=aic, 3=bic
    local lagopt = 1
    if "`lagmethod'" == "fixed" local lagopt = 9
    if "`lagmethod'" == "zero"  local lagopt = 0
    if "`lagmethod'" == "aic"   local lagopt = 2
    if "`lagmethod'" == "bic"   local lagopt = 3

    * DEFAULT engine reproduces the original GAUSS/tspdlib results exactly, so
    * makicoint matches the standard implementation out of the box. The -gauss-
    * option is accepted for explicitness (it is the default). Option -paper-
    * switches to the Maki (2012) paper method (cointegrating-SSR break selection).
    local rule = 1
    local gssr = 1
    if "`paper'" != "" {
        local rule = 0
        local gssr = 0
    }

    preserve
    qui keep if `touse'
    qui count
    local nobs = r(N)

    if `nobs' < 20 {
        di as error "Sample too small (need at least 20 usable observations)."
        exit 198
    }

    * feasibility of the requested number of breaks given trimming
    local tb = round(`trimming' * `nobs')
    if `tb' < 1 local tb = 1
    local maxfeas = floor(`nobs' / (`tb' + 1)) - 1
    if `maxbreaks' > `maxfeas' {
        di as error "Requested maxbreaks(`maxbreaks') exceeds the feasible maximum (`maxfeas')"
        di as error "for `nobs' observations and trimming `trimming'."
        di as error "Reduce maxbreaks(), reduce trimming(), or use a longer series."
        exit 198
    }
    if `maxbreaks' > 5 & `simcv' == 0 {
        di as txt "Note: Maki (2012) Table 1 only tabulates critical values up to 5 breaks."
        di as txt "      For maxbreaks(`maxbreaks') no published CVs exist; the statistic and"
        di as txt "      break dates are reported, but critical values are left missing."
        di as txt "      Add simcv(#) (e.g. simcv(1000)) to Monte-Carlo the CVs (paper's method)."
    }

    local min_recommended = ceil((`maxbreaks' + 1) / `trimming')
    if `nobs' < `min_recommended' {
        di as txt "Note: sample size (`nobs') is small for `maxbreaks' breaks at trimming `trimming'."
        di as txt "      Recommended minimum: `min_recommended' observations. Results may be unstable."
    }

    foreach var of local varlist {
        qui count if missing(`var')
        if r(N) > 0 {
            di as error "Missing values found in `var' within the estimation sample."
            exit 198
        }
    }

    qui gen double _mkc_time = `timevar'

    mata: mkc_main("`depvar'", "`indepvars'", `maxbreaks', `model', ///
                   `trimming', `maxlags', `lagopt', `rule', `gssr', ///
                   `simcv', `simt', `simseed', `nobs')

    tempname test_stat
    scalar `test_stat' = r(test_stat)
    local tstat = `test_stat'
    local lags_used = r(lags_used)
    local cvsource  "`r(cvsource)'"

    forvalues i = 1/`maxbreaks' {
        local bp`i'     = r(bp`i')
        local bpdate`i' = r(bpdate`i')
        local bpfrac`i' = r(bpfrac`i')
    }
    local cv1  = r(cv1)
    local cv5  = r(cv5)
    local cv10 = r(cv10)

    restore

    *----------------------------------------------------------------- output
    local model0 "Level Shift"
    local model1 "Level Shift with Trend"
    local model2 "Regime Shift"
    local model3 "Regime Shift with Trend"

    local methtag "Maki (2012) paper (global min-SSR break)"
    if `rule' == 1 local methtag "GAUSS/tspdlib compatible (min-tau segment, ADF-SSR break)"

    di ""
    di as txt "{hline 78}"
    di as txt _col(8) "{bf:Maki (2012) Cointegration Test with Multiple Structural Breaks}"
    di as txt "{hline 78}"
    di ""
    di as txt "Model:" _col(28) as res "`model`model''"
    di as txt "Engine:" _col(28) as res "`methtag'"
    di as txt "Observations:" _col(28) as res `nobs'
    di as txt "Maximum breaks:" _col(28) as res `maxbreaks'
    di as txt "Trimming:" _col(28) as res %5.2f `trimming'
    di as txt "Lag selection:" _col(28) as res "`lagmethod'" as txt "  (max `maxlags', used `lags_used')"
    di as txt "Dependent variable:" _col(28) as res "`depvar'"
    di as txt "Independent variable(s):" _col(28) as res "`indepvars'"
    di ""
    di as txt "{hline 78}"
    di as txt _col(3) "H0: No cointegration"
    di as txt _col(3) "H1: Cointegration with up to `maxbreaks' break(s)"
    di as txt "{hline 78}"
    di ""

    di as txt "{hline 50}"
    di as txt _col(2) "Test Statistic" _col(24) "{c |}" _col(34) "Critical Values"
    di as txt "{hline 23}{c +}{hline 26}"
    di as txt _col(24) "{c |}" _col(31) "1%" _col(40) "5%" _col(48) "10%"
    di as txt "{hline 23}{c +}{hline 26}"
    if `cv1' < . {
        di as res _col(4) %10.4f `test_stat' _col(24) as txt "{c |}" ///
           as res _col(28) %8.3f `cv1' _col(37) %8.3f `cv5' _col(45) %8.3f `cv10'
    }
    else {
        di as res _col(4) %10.4f `test_stat' _col(24) as txt "{c |}" ///
           as res _col(31) "    n/a" _col(40) "    n/a" _col(48) "    n/a"
    }
    di as txt "{hline 50}"
    if "`cvsource'" == "simulated" {
        di as txt "Critical values: Monte-Carlo, `=r(simreps)' reps, T=`simt' (Maki 2012 method)."
    }
    else if "`cvsource'" == "table" {
        di as txt "Critical values: Maki (2012) Table 1."
    }
    else {
        di as txt "Critical values: not available for `maxbreaks' breaks (see note above)."
    }
    di ""

    di as txt "{hline 60}"
    di as txt _col(2) "Estimated Break Points"
    di as txt "{hline 60}"
    di as txt _col(4) "Break" _col(15) "Observation" _col(33) "Date" _col(50) "Fraction"
    di as txt "{hline 60}"
    forvalues i = 1/`maxbreaks' {
        if `bp`i'' > 0 {
            di as txt _col(6) as res `i' _col(18) %5.0f `bp`i'' _col(31) `bpdate`i'' _col(50) %6.4f `bpfrac`i''
        }
    }
    di as txt "{hline 60}"
    di ""

    di as txt "{hline 78}"
    local reject = 0
    if `cv1' >= . {
        di as txt "Conclusion: critical values unavailable; cannot perform inference at maxbreaks(`maxbreaks')."
    }
    else if `test_stat' < `cv1' {
        di as res "Conclusion: Reject H0 at the 1% level -- cointegration with structural break(s)."
        local reject = 1
    }
    else if `test_stat' < `cv5' {
        di as res "Conclusion: Reject H0 at the 5% level -- cointegration with structural break(s)."
        local reject = 1
    }
    else if `test_stat' < `cv10' {
        di as res "Conclusion: Reject H0 at the 10% level -- cointegration with structural break(s)."
        local reject = 1
    }
    else {
        di as res "Conclusion: Fail to reject H0 -- no evidence of cointegration."
    }
    di as txt "{hline 78}"
    di ""

    *----------------------------------------------------------- returns
    return scalar test_stat = `test_stat'
    return scalar cv1   = `cv1'
    return scalar cv5   = `cv5'
    return scalar cv10  = `cv10'
    return scalar nobs  = `nobs'
    return scalar maxbreaks = `maxbreaks'
    return scalar model = `model'
    return scalar trimming = `trimming'
    return scalar lags  = `lags_used'
    return scalar reject = `reject'
    if "`cvsource'" == "simulated" {
        return scalar simreps = `simcv'
    }
    forvalues i = 1/`maxbreaks' {
        return scalar bp`i'     = `bp`i''
        return scalar bpdate`i' = `bpdate`i''
        return scalar bpfrac`i' = `bpfrac`i''
    }
    return local cvsource   "`cvsource'"
    return local depvar     "`depvar'"
    return local indepvars  "`indepvars'"
    return local model_name "`model`model''"
    return local lagmethod  "`lagmethod'"
    return local engine     "`methtag'"

    *----------------------------------------------------- regression / graph
    if "`reg'" != "" | "`regnewey'" != "" | "`graph'" != "" {
        makicoint_post `depvar' `indepvars', timevar(`timevar') touse(`touse') ///
            model(`model') maxbreaks(`maxbreaks') ///
            bpdates(`bpdate1' `bpdate2' `bpdate3' `bpdate4' `bpdate5' `bpdate6' `bpdate7' `bpdate8') ///
            teststat(`tstat') cv5(`cv5') reject(`reject') ///
            reg(`=("`reg'"!="")') newey(`=("`regnewey'"!="")') ///
            dograph(`=("`graph'"!="")') graphname(`name') modelname("`model`model''")
    }
end


*=====================================================================
* Post-estimation: cointegrating regression at the breaks + dashboard
*=====================================================================
program define makicoint_post, rclass
    version 14.0
    syntax varlist(min=2 ts), timevar(string) touse(string) model(integer) ///
        maxbreaks(integer) bpdates(numlist) teststat(real) cv5(real) ///
        reject(integer) reg(integer) newey(integer) dograph(integer) ///
        [ graphname(string) modelname(string) ]

    gettoken depvar indepvars : varlist

    qui tsset `timevar'
    sort `timevar'

    * build regime variables from the (date-valued) break points
    local nb = 0
    local xlines ""
    capture drop _mkc_tr
    qui gen double _mkc_tr = _n if `touse'
    qui sum _mkc_tr if `touse', meanonly
    qui replace _mkc_tr = _mkc_tr - r(min) + 1 if `touse'
    foreach d of numlist `bpdates' {
        if `d' < . & `d' != 0 {
            local nb = `nb' + 1
            capture drop _mkc_du`nb'
            qui gen byte _mkc_du`nb' = (`timevar' > `d') if `touse'
            local xlines "`xlines' `d'"
        }
    }

    * assemble regressors for each Maki model
    local regvars ""
    if `model' == 0 {
        local regvars "`indepvars'"
        forvalues i = 1/`nb' {
            local regvars "`regvars' _mkc_du`i'"
        }
    }
    else if `model' == 1 {
        local regvars "_mkc_tr `indepvars'"
        forvalues i = 1/`nb' {
            local regvars "`regvars' _mkc_du`i'"
        }
    }
    else if `model' == 2 {
        local regvars "`indepvars'"
        forvalues i = 1/`nb' {
            foreach v of local indepvars {
                capture drop _mkc_x`i'_`v'
                qui gen double _mkc_x`i'_`v' = _mkc_du`i' * `v' if `touse'
                local regvars "`regvars' _mkc_x`i'_`v'"
            }
        }
        forvalues i = 1/`nb' {
            local regvars "`regvars' _mkc_du`i'"
        }
    }
    else {
        local regvars "_mkc_tr `indepvars'"
        forvalues i = 1/`nb' {
            capture drop _mkc_dtr`i'
            qui gen double _mkc_dtr`i' = _mkc_du`i' * _mkc_tr if `touse'
            local regvars "`regvars' _mkc_dtr`i'"
            foreach v of local indepvars {
                capture drop _mkc_x`i'_`v'
                qui gen double _mkc_x`i'_`v' = _mkc_du`i' * `v' if `touse'
                local regvars "`regvars' _mkc_x`i'_`v'"
            }
        }
        forvalues i = 1/`nb' {
            local regvars "`regvars' _mkc_du`i'"
        }
    }
    local regvars : list clean regvars

    if `reg' {
        di as text "Cointegrating regression at the estimated breaks (OLS):"
        regress `depvar' `regvars' if `touse'
        di ""
    }
    else if `newey' {
        qui count if `touse'
        local nwlag = floor(4 * (r(N)/100)^(2/9))
        di as text "Cointegrating regression at the estimated breaks (Newey-West, lag = `nwlag'):"
        newey `depvar' `regvars' if `touse', lag(`nwlag')
        di ""
    }

    *------------------------------------------------------------- the graph
    if `dograph' {
        capture drop _mkc_fit
        capture drop _mkc_res
        qui regress `depvar' `regvars' if `touse'
        qui predict double _mkc_fit if `touse', xb
        qui predict double _mkc_res if `touse', residuals

        if "`graphname'" == "" local graphname "makicoint_graph"

        local concl "Fail to reject H0 (no cointegration)"
        local sccolor "black"
        if `reject' {
            local concl "Reject H0: cointegration with break(s)"
            local sccolor "maroon"
        }

        local note0 = "Breaks (dashed): `xlines'   |   stat = " + string(`teststat',"%6.3f") + ",  5% cv = " + string(`cv5',"%6.3f")

        local xl ""
        foreach d of local xlines {
            local xl `xl' xline(`d', lpattern(shortdash) lcolor(gs8) lwidth(medthin))
        }

        * regime parity for alternating background shading
        qui gen double _mkc_reg = 0 if `touse'
        forvalues i = 1/`nb' {
            qui replace _mkc_reg = _mkc_reg + _mkc_du`i' if `touse'
        }
        qui gen byte _mkc_sh = (mod(_mkc_reg, 2)==0) if `touse'

        qui sum `depvar' if `touse', meanonly
        local pad1 = 0.06*(r(max)-r(min))
        qui gen double _mkc_bt1 = r(max)+`pad1' if `touse'
        qui gen double _mkc_bb1 = r(min)-`pad1' if `touse'

        qui sum _mkc_res if `touse', meanonly
        local pad2 = 0.12*(r(max)-r(min))
        qui gen double _mkc_bt2 = r(max)+`pad2' if `touse'
        qui gen double _mkc_bb2 = r(min)-`pad2' if `touse'

        capture {
            twoway ///
                (rarea _mkc_bt1 _mkc_bb1 `timevar' if _mkc_sh & `touse', color(navy%7) lwidth(none)) ///
                (line `depvar' `timevar' if `touse', lcolor(navy) lwidth(medthick)) ///
                (line _mkc_fit `timevar' if `touse', lcolor(cranberry) lpattern(dash) lwidth(medthick)) ///
                , `xl' ///
                  legend(order(2 "`depvar' (observed)" 3 "Fitted long-run relation") ///
                         rows(1) region(lstyle(none)) size(small)) ///
                  ytitle("`depvar'") xtitle("") ///
                  ylabel(, angle(horizontal) labsize(small) nogrid) xlabel(, nogrid) ///
                  title("Series and break-adjusted long-run relation", size(medsmall) color(black)) ///
                  graphregion(color(white)) plotregion(lcolor(gs13) margin(zero)) ///
                  name(_mkc_p1, replace) nodraw

            twoway ///
                (rarea _mkc_bt2 _mkc_bb2 `timevar' if _mkc_sh & `touse', color(navy%7) lwidth(none)) ///
                (line _mkc_res `timevar' if `touse', lcolor(forest_green) lwidth(medthick)) ///
                , yline(0, lcolor(gs6) lwidth(thin)) `xl' legend(off) ///
                  ytitle("Equilibrium error") xtitle("`timevar'") ///
                  ylabel(, angle(horizontal) labsize(small) nogrid) xlabel(, nogrid) ///
                  title("Cointegrating residual (deviation from long-run equilibrium)", size(medsmall) color(black)) ///
                  graphregion(color(white)) plotregion(lcolor(gs13) margin(zero)) ///
                  name(_mkc_p2, replace) nodraw

            graph combine _mkc_p1 _mkc_p2, cols(1) imargin(small) ///
                graphregion(color(white)) ///
                title("Maki (2012) cointegration test  --  `modelname'", size(medlarge) color(black)) ///
                subtitle("`concl'", size(small) color(`sccolor')) ///
                note("`note0'", size(vsmall) color(gs7)) ///
                name(`graphname', replace)
            graph display `graphname'
        }
        if _rc {
            di as txt "(graph could not be drawn: _rc=`_rc'; the numerical results above are unaffected.)"
        }
    }

    * tidy regime temporaries
    capture drop _mkc_*
end


*=====================================================================
*  Mata engine
*=====================================================================
version 14.0
mata:

// ------- OLS residual (column-order invariant) -------------------------
real colvector mkc_resid(real colvector y, real matrix X)
{
    real colvector b
    b = invsym(cross(X, X)) * cross(X, y)
    return(y - X * b)
}

// ------- fixed-break part of the cointegrating design (built once/step) -
// column order is irrelevant to the residual, so the candidate's columns
// are appended later by the search loop.
real matrix mkc_xfixed(real matrix datap, real scalar n, real scalar model,
                       real colvector fixed)
{
    real scalar k, nb, c, b
    real matrix Xf, R, blk
    real colvector u, tr
    k  = cols(datap)
    R  = datap[., 2..k]
    nb = rows(fixed)
    u  = J(n, 1, 1)
    Xf = u
    // fixed level-shift dummies
    for (c = 1; c <= nb; c++) {
        b  = fixed[c]
        Xf = Xf, (J(b, 1, 0) \ J(n - b, 1, 1))
    }
    // common trend (models 1 and 3)
    if (model == 1 | model == 3) {
        tr = (1::n)
        Xf = Xf, tr
        // broken trend (model 3)
        if (model == 3) {
            for (c = 1; c <= nb; c++) {
                b  = fixed[c]
                Xf = Xf, (J(b, 1, 0) \ ((b + 1)::n))
            }
        }
    }
    // regressors
    Xf = Xf, R
    // regime (slope) shifts (models 2 and 3)
    if (model == 2 | model == 3) {
        for (c = 1; c <= nb; c++) {
            b   = fixed[c]
            blk = (J(b, k - 1, 0) \ R[(b + 1)..n, .])
            Xf  = Xf, blk
        }
    }
    return(Xf)
}

// ------- t-sig (general-to-specific) lag, threshold 1.654 --------------
real scalar mkc_tsig(real colvector e, real scalar maxlags)
{
    real scalar n, p, i, taut, s2hat
    real colvector dy, ly, b, se, resid
    real matrix X, xtxi
    n  = rows(e)
    dy = e[2..n] - e[1..n-1]
    p  = maxlags
    while (p >= 1) {
        if (n - 1 - p >= 3) {
            X = e[(p+1)..(n-1)]
            i = 1
            while (i <= p) {
                X = X, dy[(p+1-i)..(n-1-i)]
                i = i + 1
            }
            ly    = dy[(p+1)..(n-1)]
            xtxi  = invsym(cross(X, X))
            b     = xtxi * cross(X, ly)
            resid = ly - X * b
            s2hat = cross(resid, resid) / (rows(X) - cols(X))
            se    = sqrt(diagonal(s2hat * xtxi))
            taut  = b[p+1] / se[p+1]
            if (abs(taut) > 1.654) {
                return(p)
            }
        }
        p = p - 1
    }
    return(0)
}

// ------- AIC/BIC lag --------------------------------------------------
real scalar mkc_ic(real colvector e, real scalar maxlags, real scalar useaic)
{
    real scalar n, p, i, bestlag, bestic, ic, s2, nobs, npar
    real colvector dy, ly, b, resid
    real matrix X, xtxi
    n  = rows(e)
    dy = e[2..n] - e[1..n-1]
    bestlag = 0
    bestic  = .
    for (p = 0; p <= maxlags; p++) {
        if (n - 1 - p >= 3) {
            X = e[(p+1)..(n-1)]
            if (p > 0) {
                i = 1
                while (i <= p) {
                    X = X, dy[(p+1-i)..(n-1-i)]
                    i = i + 1
                }
            }
            ly    = dy[(p+1)..(n-1)]
            xtxi  = invsym(cross(X, X))
            b     = xtxi * cross(X, ly)
            resid = ly - X * b
            nobs  = rows(X)
            npar  = cols(X)
            s2    = cross(resid, resid) / nobs
            if (useaic) {
                ic = ln(s2) + 2 * npar / nobs
            }
            else {
                ic = ln(s2) + ln(nobs) * npar / nobs
            }
            if (ic < bestic) {
                bestic  = ic
                bestlag = p
            }
        }
    }
    return(bestlag)
}

// ------- ADF tau on a residual; returns tau, sets lag and ADF-SSR ------
real scalar mkc_adf(real colvector e, real scalar lagopt, real scalar maxlags,
                    real scalar lagused, real scalar ssr_adf)
{
    real scalar n, lag, r, q, tau, s2hat
    real colvector dy, ly, b, se, resid
    real matrix X, xtxi
    n  = rows(e)
    dy = e[2..n] - e[1..n-1]
    if (lagopt == 0) {
        lag = 0
    }
    else if (lagopt == 9) {
        lag = maxlags
    }
    else if (lagopt == 1) {
        lag = mkc_tsig(e, maxlags)
    }
    else if (lagopt == 2) {
        lag = mkc_ic(e, maxlags, 1)
    }
    else {
        lag = mkc_ic(e, maxlags, 0)
    }
    lagused = lag
    r = 2 + lag
    X = e[(r-1)..(n-1)]
    if (lag > 0) {
        q = 1
        while (q <= lag) {
            X = X, dy[(r-1-q)..(n-1-q)]
            q = q + 1
        }
    }
    ly      = dy[(r-1)..(n-1)]
    xtxi    = invsym(cross(X, X))
    b       = xtxi * cross(X, ly)
    resid   = ly - X * b
    ssr_adf = cross(resid, resid)
    s2hat   = ssr_adf / (rows(X) - cols(X))
    se      = sqrt(diagonal(s2hat * xtxi))
    tau     = b[1] / se[1]
    return(tau)
}

// ------- argmin (ignoring missing) ------------------------------------
real scalar mkc_argmin(real colvector v)
{
    real scalar i, mi, mv
    mi = 1
    mv = v[1]
    for (i = 2; i <= rows(v); i++) {
        if (v[i] < mv) {
            mv = v[i]
            mi = i
        }
    }
    return(mi)
}

// ------- search for ONE additional break given the fixed set ----------
// returns the minimum tau over all eligible candidates (all segments);
// sets bp_out (chosen position) and taulag_out (lag at the min-tau cand).
// rule==0 : bp = global argmin SSR (Maki paper).
// rule==1 : bp = argmin SSR within the min-tau segment (GAUSS).
// gssr==1 : SSR = ADF-regression SSR (GAUSS); else cointegrating SSR (paper).
real scalar mkc_search(real matrix datap, real scalar n, real scalar model,
                       real scalar tb, real colvector fixed, real scalar lagopt,
                       real scalar maxlags, real scalar rule, real scalar gssr,
                       real scalar bp_out, real scalar taulag_out)
{
    real scalar k, nseg, s, a, bb, lo, hi, i, tau, ssr, ssr_adf, lagused
    real scalar segbtau, segbssr, segbpos, segbtaulag, gminssr, gminpos, smin
    real colvector y, R1, e, dui, dxi, dtri
    real colvector segtau, segpos, segtaulag
    real matrix R, Xf, X
    y  = datap[., 1]
    k  = cols(datap)
    R  = datap[., 2..k]
    Xf = mkc_xfixed(datap, n, model, fixed)

    nseg      = rows(fixed) + 1
    segtau    = J(nseg, 1, .)
    segpos    = J(nseg, 1, 0)
    segtaulag = J(nseg, 1, 0)
    gminssr   = .
    gminpos   = 0

    for (s = 1; s <= nseg; s++) {
        if (s == 1) {
            a = 0
        }
        else {
            a = fixed[s-1]
        }
        if (s == nseg) {
            bb = n
        }
        else {
            bb = fixed[s]
        }
        lo = a + tb + 1
        hi = bb - tb

        segbtau    = .
        segbssr    = .
        segbpos    = 0
        segbtaulag = 0

        for (i = lo; i <= hi; i++) {
            dui = (J(i, 1, 0) \ J(n - i, 1, 1))
            X   = Xf, dui
            if (model == 2) {
                dxi = (J(i, k - 1, 0) \ R[(i + 1)..n, .])
                X   = X, dxi
            }
            if (model == 3) {
                dtri = (J(i, 1, 0) \ ((i + 1)::n))
                dxi  = (J(i, k - 1, 0) \ R[(i + 1)..n, .])
                X    = X, dtri, dxi
            }
            e   = mkc_resid(y, X)
            tau = mkc_adf(e, lagopt, maxlags, lagused, ssr_adf)
            if (gssr == 1) {
                ssr = ssr_adf
            }
            else {
                ssr = cross(e, e)
            }
            if (tau < segbtau) {
                segbtau    = tau
                segbtaulag = lagused
            }
            if (ssr < segbssr) {
                segbssr = ssr
                segbpos = i
            }
            if (ssr < gminssr) {
                gminssr = ssr
                gminpos = i
            }
        }
        segtau[s]    = segbtau
        segpos[s]    = segbpos
        segtaulag[s] = segbtaulag
    }

    smin       = mkc_argmin(segtau)
    taulag_out = segtaulag[smin]
    if (rule == 1) {
        bp_out = segpos[smin]
    }
    else {
        bp_out = gminpos
    }
    return(segtau[smin])
}

// ------- sequential test: accumulate min-tau across steps -------------
real scalar mkc_test(real matrix datap, real scalar m, real scalar model,
                     real scalar tb, real scalar lagopt, real scalar maxlags,
                     real scalar rule, real scalar gssr,
                     real colvector breakpoints, real scalar lagused_global)
{
    real scalar n, j, tau_j, bp, taulag, runmin, nf
    real colvector fixed, alltau
    n      = rows(datap)
    fixed  = J(0, 1, .)
    alltau = J(m, 1, .)
    runmin = .
    lagused_global = 0
    for (j = 1; j <= m; j++) {
        bp     = 0
        taulag = 0
        tau_j  = mkc_search(datap, n, model, tb, fixed, lagopt, maxlags,
                            rule, gssr, bp, taulag)
        alltau[j] = tau_j
        if (bp > 0) {
            fixed = sort(fixed \ bp, 1)
        }
        if (tau_j < runmin) {
            runmin = tau_j
            lagused_global = taulag
        }
    }
    breakpoints = J(m, 1, 0)
    nf = rows(fixed)
    for (j = 1; j <= nf; j++) {
        breakpoints[j] = fixed[j]
    }
    return(min(alltau))
}

// ------- Maki (2012) Table 1 critical values (m=1..5, k=1..4) ----------
real rowvector mkc_cv(real scalar k, real scalar m, real scalar model)
{
    real matrix cm
    if (m < 1 | m > 5 | k < 1 | k > 4) {
        return((., ., .))
    }
    cm = J(5, 3, .)
    if (model == 0) {
        if (k == 1) cm = (-5.709,-4.602,-4.354 \ -5.416,-4.892,-4.610 \ -5.563,-5.083,-4.784 \ -5.776,-5.230,-4.982 \ -5.959,-5.426,-5.131)
        else if (k == 2) cm = (-5.541,-5.004,-4.733 \ -5.717,-5.211,-4.957 \ -5.943,-5.392,-5.125 \ -6.075,-5.550,-5.297 \ -6.296,-5.760,-5.491)
        else if (k == 3) cm = (-5.820,-5.341,-5.101 \ -5.984,-5.517,-5.272 \ -6.229,-5.704,-5.427 \ -6.406,-5.871,-5.603 \ -6.555,-6.038,-5.773)
        else cm = (-6.139,-5.650,-5.386 \ -6.303,-5.839,-5.575 \ -6.501,-5.992,-5.714 \ -6.640,-6.132,-5.892 \ -6.856,-6.306,-6.039)
    }
    else if (model == 1) {
        if (k == 1) cm = (-5.524,-5.038,-4.784 \ -5.708,-5.196,-4.938 \ -5.833,-5.373,-5.106 \ -6.059,-5.508,-5.245 \ -6.193,-5.699,-5.449)
        else if (k == 2) cm = (-5.840,-5.359,-5.117 \ -6.011,-5.518,-5.247 \ -6.169,-5.691,-5.408 \ -6.329,-5.831,-5.558 \ -6.530,-5.993,-5.722)
        else if (k == 3) cm = (-6.144,-5.645,-5.398 \ -6.271,-5.796,-5.538 \ -6.472,-5.957,-5.682 \ -6.575,-6.086,-5.820 \ -6.784,-6.250,-5.976)
        else cm = (-6.361,-5.913,-5.686 \ -6.556,-6.055,-5.805 \ -6.741,-6.214,-5.974 \ -6.845,-6.373,-6.096 \ -7.053,-6.494,-6.220)
    }
    else if (model == 2) {
        if (k == 1) cm = (-5.457,-4.895,-4.626 \ -5.863,-5.363,-5.070 \ -6.251,-5.703,-5.402 \ -6.596,-6.011,-5.723 \ -6.915,-6.357,-6.057)
        else if (k == 2) cm = (-6.020,-5.558,-5.287 \ -6.628,-6.093,-5.833 \ -7.031,-6.516,-6.210 \ -7.470,-6.872,-6.563 \ -7.839,-7.288,-6.976)
        else if (k == 3) cm = (-6.565,-6.035,-5.773 \ -7.232,-6.702,-6.411 \ -7.767,-7.155,-6.868 \ -8.236,-7.625,-7.329 \ -8.673,-8.110,-7.796)
        else cm = (-7.021,-6.520,-6.242 \ -7.756,-7.244,-6.964 \ -8.336,-7.803,-7.481 \ -8.895,-8.292,-8.004 \ -9.441,-8.869,-8.541)
    }
    else {
        if (k == 1) cm = (-6.048,-5.541,-5.281 \ -6.620,-6.100,-5.845 \ -7.082,-6.524,-6.267 \ -7.553,-7.009,-6.712 \ -8.004,-7.414,-7.110)
        else if (k == 2) cm = (-6.523,-6.055,-5.795 \ -7.153,-6.657,-6.397 \ -7.673,-7.145,-6.873 \ -8.217,-7.636,-7.341 \ -8.713,-8.129,-7.811)
        else if (k == 3) cm = (-6.964,-6.464,-6.220 \ -7.737,-7.201,-6.926 \ -8.331,-7.743,-7.449 \ -8.851,-8.269,-7.960 \ -9.428,-8.800,-8.508)
        else cm = (-7.400,-6.911,-6.649 \ -8.167,-7.638,-7.381 \ -8.865,-8.254,-7.977 \ -9.433,-8.871,-8.574 \ -10.08,-9.482,-9.151)
    }
    return(cm[m, .])
}

// ------- Monte-Carlo critical values for any (model,k,m) --------------
// Maki (2012) footnote 3: y_t and x_t are independent driftless random walks
// (cumulated iid N(0,I)); compute the statistic; repeat; sort; take quantiles.
real rowvector mkc_simcv(real scalar kreg, real scalar m, real scalar model,
                         real scalar trimm, real scalar lagopt, real scalar maxlags,
                         real scalar rule, real scalar gssr, real scalar simt,
                         real scalar reps, real scalar seed)
{
    real scalar r, tb, c, lg, i1, i5, i10
    real colvector stats, bpv
    real matrix datap, innov
    rseed(seed)
    tb = round(trimm * simt)
    if (tb < 1) tb = 1
    stats = J(reps, 1, .)
    for (r = 1; r <= reps; r++) {
        innov = rnormal(simt, kreg + 1, 0, 1)
        datap = J(simt, kreg + 1, 0)
        for (c = 1; c <= kreg + 1; c++) {
            datap[., c] = runningsum(innov[., c])
        }
        stats[r] = mkc_test(datap, m, model, tb, lagopt, maxlags, rule, gssr, bpv, lg)
    }
    stats = sort(stats, 1)
    i1  = ceil(0.01 * reps)
    i5  = ceil(0.05 * reps)
    i10 = ceil(0.10 * reps)
    if (i1  < 1) i1  = 1
    if (i5  < 1) i5  = 1
    if (i10 < 1) i10 = 1
    return((stats[i1], stats[i5], stats[i10]))
}

// ------- driver: read data, run test, return everything to Stata ------
void mkc_main(string scalar depvar, string scalar indepvars, real scalar m,
              real scalar model, real scalar trimm, real scalar maxlags,
              real scalar lagopt, real scalar rule, real scalar gssr,
              real scalar simcv, real scalar simt, real scalar simseed,
              real scalar nobs)
{
    real matrix datap, X
    real colvector y, breakpoints, timevals
    real scalar tb, teststat, kreg, i, lagused
    real rowvector cv
    string rowvector xvars
    string scalar src

    y     = st_data(., depvar)
    xvars = tokens(indepvars)
    X     = st_data(., xvars)
    datap = y, X
    kreg  = cols(X)
    tb    = round(trimm * nobs)
    if (tb < 1) tb = 1

    teststat = mkc_test(datap, m, model, tb, lagopt, maxlags, rule, gssr,
                        breakpoints, lagused)

    timevals = st_data(., "_mkc_time")

    // critical values
    src = "none"
    if (simcv > 0) {
        cv  = mkc_simcv(kreg, m, model, trimm, lagopt, maxlags, rule, gssr,
                        simt, simcv, simseed)
        src = "simulated"
        st_numscalar("r(simreps)", simcv)
    }
    else if (m <= 5) {
        cv  = mkc_cv(kreg, m, model)
        src = "table"
    }
    else {
        cv = (., ., .)
    }

    st_numscalar("r(test_stat)", teststat)
    st_numscalar("r(num_breaks)", m)
    st_numscalar("r(lags_used)", lagused)
    st_global("r(cvsource)", src)

    for (i = 1; i <= m; i++) {
        st_numscalar("r(bp" + strofreal(i) + ")", breakpoints[i])
        if (breakpoints[i] > 0) {
            st_numscalar("r(bpdate" + strofreal(i) + ")", timevals[breakpoints[i]])
            st_numscalar("r(bpfrac" + strofreal(i) + ")", breakpoints[i] / nobs)
        }
        else {
            st_numscalar("r(bpdate" + strofreal(i) + ")", 0)
            st_numscalar("r(bpfrac" + strofreal(i) + ")", 0)
        }
    }

    st_numscalar("r(cv1)",  cv[1])
    st_numscalar("r(cv5)",  cv[2])
    st_numscalar("r(cv10)", cv[3])
}

end
