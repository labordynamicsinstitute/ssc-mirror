*! xtcipsm : Modified CADF / CIPS panel unit-root test
*!           (Westerlund & Hosseinkouchack, 2016; Pesaran, 2007)
*! Part of the -xtpdlib- library : second-generation panel data tests
*! Version 1.0.0  06jun2026
*!
*! Stata translation & implementation : Dr Merwan Roudane
*!   merwanroudane920@gmail.com  |  https://github.com/merwanroudane
*! Based on the GAUSS routine pd_cips (proc cips) by Saban Nazlioglu (TSPDLIB),
*!   snazlioglu@pau.edu.tr  -- for public non-commercial use only.
*!
*! References:
*!   Pesaran, M.H. (2007). A simple panel unit root test in the presence of
*!     cross-section dependence. J. of Applied Econometrics 22: 265-312.
*!     <doi:10.1002/jae.951>
*!   Westerlund, J., Hosseinkouchack, M. (2016). Modified CADF and CIPS panel
*!     unit root statistics with standard chi-squared and normal limiting
*!     distributions. Oxford Bulletin of Economics and Statistics 78(3): 347-364.
*!     <doi:10.1111/obes.12127>
*!
*! Note: standard (Pesaran) CIPS is also available via -xtcips- (M. Sangiacomo).
*!       xtcipsm reports it as a by-product; its purpose is the MODIFIED test.

program define xtcipsm, rclass
    version 14.0

    syntax varname [if] [in] [ ,                 ///
            MODel(string)                         ///
            MAXLags(integer 4)                    ///
            IC(integer 3)                         ///
            GRaph                                 ///
            noPRINTind                            ///
            * ]

    local gphopts `"`options'"'

    * ---------------------------------------------------------------
    * Deterministic model : none(0) | constant(1) | trend(2)
    * ---------------------------------------------------------------
    if ("`model'" == "") local model "constant"
    local model = lower("`model'")
    if !inlist("`model'", "none", "constant", "trend") {
        di as err "option model() must be {bf:none}, {bf:constant} or {bf:trend}"
        exit 198
    }
    local modeln = cond("`model'"=="none", 0, cond("`model'"=="constant", 1, 2))
    local modtxt = cond(`modeln'==0, "none", ///
                   cond(`modeln'==1, "constant", "constant & trend"))
    * degrees of freedom q for the modified statistic
    local q = cond(`modeln'==1, 2, cond(`modeln'==2, 3, 0))

    if (`maxlags' < 0) {
        di as err "option maxlags() must be >= 0"
        exit 198
    }
    if !inlist(`ic', 1, 2, 3) {
        di as err "option ic() must be 1 (AIC), 2 (SIC) or 3 (t-stat)"
        exit 198
    }
    local ictxt : word `ic' of "Akaike (AIC)" "Schwarz (SIC)" "t-stat (general-to-specific)"

    * ---------------------------------------------------------------
    * Panel structure (balanced)
    * ---------------------------------------------------------------
    qui xtset
    local id   `r(panelvar)'
    local time `r(timevar)'
    if ("`id'" == "" | "`time'" == "") {
        di as err "data must be {bf:xtset} (panelvar timevar) before using xtcipsm"
        exit 459
    }

    marksample touse
    markout `touse' `time' `id'

    tempvar cnt
    qui bysort `id' (`time') : gen long `cnt' = sum(`touse')
    qui by `id' : replace `cnt' = `cnt'[_N]
    qui summarize `cnt' if `touse', meanonly
    if (r(min) != r(max)) {
        di as err "xtcipsm requires a {bf:balanced} panel"
        exit 459
    }
    qui count if `touse'
    local NT = r(N)
    qui levelsof `id' if `touse', local(idlevels)
    local N : word count `idlevels'
    local T = `NT'/`N'
    if (`T' != int(`T') | `N' < 2 | `T' < `=`maxlags'+6') {
        di as err "panel not balanced or too small for maxlags(`maxlags')"
        exit 459
    }

    * ---------------------------------------------------------------
    * Mata engine
    * ---------------------------------------------------------------
    qui mata: xtcipsm_calc("`varlist'", "`touse'", "`id'", `modeln', ///
        `maxlags', `ic', `N', `T')

    local cips   = `xtc_cips'
    local mcips  = `xtc_mcips'
    local mpval  = `xtc_mpval'
    local mdbar  = `xtc_mdbar'
    tempname RES
    matrix `RES' = xtc_res
    matrix drop  xtc_res

    * CIPS critical values (Pesaran 2007), via lookup table
    local case = `modeln' + 1
    _xtcipsm_cv, case(`case') n(`N') t(`T')
    local cv10 = r(cv10)
    local cv5  = r(cv5)
    local cv1  = r(cv1)

    * ---------------------------------------------------------------
    * Output
    * ---------------------------------------------------------------
    di ""
    di as txt "{hline 70}"
    di as txt "  Modified CADF / CIPS panel unit-root test"
    di as txt "  Westerlund & Hosseinkouchack (2016) ; Pesaran (2007)"
    di as txt "{hline 70}"
    di as txt "  H0: " as res "all series are nonstationary (unit root in every unit)"
    di as txt "  Ha: " as res "some/all units are stationary"
    di as txt "  Variable      : " as res "`varlist'"
    di as txt "  Deterministic : " as res "`modtxt'"
    di as txt "  Lag selection : " as res "`ictxt'" as txt " (max = `maxlags')"
    di as txt "  N , T         : " as res "`N'" as txt " , " as res "`T'"
    di as txt "{hline 70}"

    if ("`printind'" == "") {
        di as txt "  Individual statistics"
        di as txt "  {hline 64}"
        di as txt "  " %6s "id" %12s "CADF" %12s "LM" %12s "M-CADF" %12s "p-val" %6s "lags"
        di as txt "  {hline 64}"
        local nr = rowsof(`RES')
        forvalues r = 1/`nr' {
            di as res "  " %6.0g `RES'[`r',1] %12.3f `RES'[`r',2] %12.3f `RES'[`r',3] ///
                %12.3f `RES'[`r',4] %12.3f `RES'[`r',5] %6.0f `RES'[`r',6]
        }
        di as txt "  {hline 64}"
        if (`q' > 0) {
            di as txt "  Individual M-CADF ~ chi2(`q'); critical values:" _continue
            di as res "  1% = " %5.2f invchi2(`q',0.99) ///
                as txt "  5% = " as res %5.2f invchi2(`q',0.95) ///
                as txt "  10% = " as res %5.2f invchi2(`q',0.90)
        }
        di ""
    }

    di as txt "  Panel statistics"
    di as txt "  {hline 64}"
    di as txt "  " %-14s "Statistic" %12s "Value" %12s "p-value" %22s "Critical values"
    di as txt "  {hline 64}"
    di as txt "  " %-14s "CIPS" as res %12.3f `cips' as txt %12s "." ///
        as txt "   10/5/1%: " as res %6.2f `cv10' " " %6.2f `cv5' " " %6.2f `cv1'
    if (`q' > 0) {
        di as txt "  " %-14s "M-CIPS (Dp)" as res %12.3f `mcips' %12.3f `mpval' ///
            as txt "   N(0,1)"
    }
    di as txt "  {hline 64}"
    di as txt "  CIPS: reject H0 if CIPS < critical value (Pesaran 2007 tables)."
    if (`cips' < `cv5') ///
        di as txt "  => CIPS rejects the unit-root null at 5%."
    else ///
        di as txt "  => CIPS does not reject the unit-root null at 5%."
    if (`q' > 0) {
        di as txt "  M-CIPS (Dp) ~ N(0,1); reported p-value is lower-tail Phi(Dp)."
        if (`mpval' < 0.05) ///
            di as txt "  => Modified CIPS rejects the unit-root null at 5%."
        else ///
            di as txt "  => Modified CIPS does not reject the unit-root null at 5%."
    }
    di as txt "{hline 70}"
    if (`modeln'==0) di as txt "  (Modified statistic requires model(constant) or model(trend).)"
    di as txt "  CADF is shown as the building block of M-CADF (= LM - CADF^2)."
    di as txt "  Standard Pesaran CADF/CIPS are also in {bf:pescadf} and {bf:xtcips}."

    * ---------------------------------------------------------------
    * Graph : individual CADF / M-CADF vs critical values
    * ---------------------------------------------------------------
    if ("`graph'" != "") {
        _xtcipsm_graph, matname(`RES') cips(`cips') cv5(`cv5') ///
            q(`q') mdf(`modeln') `gphopts'
    }

    * ---------------------------------------------------------------
    * Returns
    * ---------------------------------------------------------------
    return scalar cips   = `cips'
    if (`q'>0) {
        return scalar mcips  = `mcips'
        return scalar mpval  = `mpval'
        return scalar mdbar  = `mdbar'
    }
    return scalar cv10   = `cv10'
    return scalar cv5    = `cv5'
    return scalar cv1    = `cv1'
    return scalar N      = `N'
    return scalar T      = `T'
    return scalar model  = `modeln'
    return matrix results = `RES'
    return local  cmd    "xtcipsm"
end


* -------------------------------------------------------------------
* Pesaran (2007) CIPS critical values (non-truncated), by case/N/T
*   case 1 = none, 2 = constant, 3 = constant & trend
* -------------------------------------------------------------------
program define _xtcipsm_cv, rclass
    version 14.0
    syntax , Case(integer) N(real) T(real)

    tempname en te m1 m5 m10
    mat `en' = (10,15,20,30,50,70,100,200)
    mat `te' = (10,15,20,30,50,70,100,200)

    if `case' == 1 {
        mat `m1' = (-2.16,-2.02,-1.93,-1.85,-1.78,-1.74,-1.71,-1.70 \ /*
        */ -2.03,-1.91,-1.84,-1.77,-1.71,-1.68,-1.66,-1.63 \ /*
        */ -2.00,-1.89,-1.83,-1.76,-1.70,-1.67,-1.65,-1.62 \ /*
        */ -1.98,-1.87,-1.80,-1.74,-1.69,-1.67,-1.64,-1.61 \ /*
        */ -1.97,-1.86,-1.80,-1.74,-1.69,-1.66,-1.63,-1.61 \ /*
        */ -1.95,-1.86,-1.80,-1.74,-1.68,-1.66,-1.63,-1.61 \ /*
        */ -1.94,-1.85,-1.79,-1.74,-1.68,-1.65,-1.63,-1.61 \ /*
        */ -1.95,-1.85,-1.79,-1.73,-1.68,-1.65,-1.63,-1.61)
        mat `m5' = (-1.80,-1.71,-1.67,-1.61,-1.58,-1.56,-1.54,-1.53 \ /*
        */ -1.74,-1.67,-1.63,-1.58,-1.55,-1.53,-1.52,-1.51 \ /*
        */ -1.72,-1.65,-1.62,-1.58,-1.54,-1.53,-1.52,-1.50 \ /*
        */ -1.72,-1.65,-1.61,-1.57,-1.55,-1.54,-1.52,-1.50 \ /*
        */ -1.72,-1.64,-1.61,-1.57,-1.54,-1.53,-1.52,-1.51 \ /*
        */ -1.71,-1.65,-1.61,-1.57,-1.54,-1.53,-1.52,-1.51 \ /*
        */ -1.71,-1.64,-1.61,-1.57,-1.54,-1.53,-1.52,-1.51 \ /*
        */ -1.71,-1.65,-1.61,-1.57,-1.54,-1.53,-1.52,-1.51)
        mat `m10' = (-1.61,-1.56,-1.52,-1.49,-1.46,-1.45,-1.44,-1.43 \ /*
        */ -1.58,-1.53,-1.50,-1.48,-1.45,-1.44,-1.44,-1.43 \ /*
        */ -1.58,-1.52,-1.50,-1.47,-1.45,-1.45,-1.44,-1.43 \ /*
        */ -1.57,-1.53,-1.50,-1.47,-1.46,-1.45,-1.44,-1.43 \ /*
        */ -1.58,-1.52,-1.50,-1.47,-1.45,-1.45,-1.44,-1.43 \ /*
        */ -1.57,-1.52,-1.50,-1.47,-1.46,-1.45,-1.44,-1.43 \ /*
        */ -1.56,-1.52,-1.50,-1.48,-1.46,-1.45,-1.44,-1.43 \ /*
        */ -1.57,-1.53,-1.50,-1.47,-1.45,-1.45,-1.44,-1.43)
    }
    else if `case' == 2 {
        mat `m1' = (-2.97,-2.76,-2.64,-2.51,-2.41,-2.37,-2.33,-2.28 \ /*
        */ -2.66,-2.52,-2.45,-2.34,-2.26,-2.23,-2.19,-2.16 \ /*
        */ -2.60,-2.47,-2.40,-2.32,-2.25,-2.20,-2.18,-2.14 \ /*
        */ -2.57,-2.45,-2.38,-2.30,-2.23,-2.19,-2.17,-2.14 \ /*
        */ -2.55,-2.44,-2.36,-2.30,-2.23,-2.20,-2.17,-2.14 \ /*
        */ -2.54,-2.43,-2.36,-2.30,-2.23,-2.20,-2.17,-2.14 \ /*
        */ -2.53,-2.42,-2.36,-2.30,-2.23,-2.20,-2.18,-2.15 \ /*
        */ -2.53,-2.43,-2.36,-2.30,-2.23,-2.21,-2.18,-2.15)
        mat `m5' = (-2.52,-2.40,-2.33,-2.25,-2.19,-2.16,-2.14,-2.10 \ /*
        */ -2.37,-2.28,-2.22,-2.17,-2.11,-2.09,-2.07,-2.04 \ /*
        */ -2.34,-2.26,-2.21,-2.15,-2.11,-2.08,-2.07,-2.04 \ /*
        */ -2.33,-2.25,-2.20,-2.15,-2.11,-2.08,-2.07,-2.05 \ /*
        */ -2.33,-2.25,-2.20,-2.16,-2.11,-2.10,-2.08,-2.06 \ /*
        */ -2.33,-2.25,-2.20,-2.15,-2.12,-2.10,-2.08,-2.06 \ /*
        */ -2.32,-2.25,-2.20,-2.16,-2.12,-2.10,-2.08,-2.07 \ /*
        */ -2.32,-2.25,-2.20,-2.16,-2.12,-2.10,-2.08,-2.07)
        mat `m10' = (-2.31,-2.22,-2.18,-2.12,-2.07,-2.05,-2.03,-2.01 \ /*
        */ -2.22,-2.16,-2.11,-2.07,-2.03,-2.01,-2.00,-1.98 \ /*
        */ -2.21,-2.14,-2.10,-2.07,-2.03,-2.01,-2.00,-1.99 \ /*
        */ -2.21,-2.14,-2.11,-2.07,-2.04,-2.02,-2.01,-2.00 \ /*
        */ -2.21,-2.14,-2.11,-2.08,-2.05,-2.03,-2.02,-2.01 \ /*
        */ -2.21,-2.15,-2.11,-2.08,-2.05,-2.03,-2.02,-2.01 \ /*
        */ -2.21,-2.15,-2.11,-2.08,-2.05,-2.03,-2.03,-2.02 \ /*
        */ -2.21,-2.15,-2.11,-2.08,-2.05,-2.04,-2.03,-2.02)
    }
    else {
        mat `m1' = (-3.88,-3.61,-3.46,-3.30,-3.15,-3.10,-3.05,-2.98 \ /*
        */ -3.24,-3.09,-3.00,-2.89,-2.81,-2.77,-2.74,-2.71 \ /*
        */ -3.15,-3.01,-2.92,-2.83,-2.76,-2.72,-2.70,-2.65 \ /*
        */ -3.10,-2.96,-2.88,-2.81,-2.73,-2.69,-2.66,-2.63 \ /*
        */ -3.06,-2.93,-2.85,-2.78,-2.72,-2.68,-2.65,-2.62 \ /*
        */ -3.04,-2.93,-2.85,-2.78,-2.71,-2.68,-2.65,-2.62 \ /*
        */ -3.03,-2.92,-2.85,-2.77,-2.71,-2.68,-2.65,-2.62 \ /*
        */ -3.03,-2.91,-2.85,-2.77,-2.71,-2.67,-2.65,-2.62)
        mat `m5' = (-3.27,-3.11,-3.02,-2.94,-2.86,-2.82,-2.79,-2.75 \ /*
        */ -2.93,-2.83,-2.77,-2.70,-2.64,-2.62,-2.60,-2.57 \ /*
        */ -2.88,-2.78,-2.73,-2.67,-2.62,-2.59,-2.57,-2.55 \ /*
        */ -2.86,-2.76,-2.72,-2.66,-2.61,-2.58,-2.56,-2.54 \ /*
        */ -2.84,-2.76,-2.71,-2.65,-2.60,-2.58,-2.56,-2.54 \ /*
        */ -2.83,-2.76,-2.70,-2.65,-2.61,-2.58,-2.57,-2.54 \ /*
        */ -2.83,-2.75,-2.70,-2.65,-2.61,-2.59,-2.56,-2.55 \ /*
        */ -2.83,-2.75,-2.70,-2.65,-2.61,-2.59,-2.57,-2.55)
        mat `m10' = (-2.98,-2.89,-2.82,-2.76,-2.71,-2.68,-2.66,-2.63 \ /*
        */ -2.76,-2.69,-2.65,-2.60,-2.56,-2.54,-2.52,-2.50 \ /*
        */ -2.74,-2.67,-2.63,-2.58,-2.54,-2.53,-2.51,-2.49 \ /*
        */ -2.73,-2.66,-2.63,-2.58,-2.54,-2.52,-2.51,-2.49 \ /*
        */ -2.73,-2.66,-2.63,-2.58,-2.55,-2.53,-2.51,-2.50 \ /*
        */ -2.72,-2.66,-2.62,-2.58,-2.55,-2.53,-2.52,-2.50 \ /*
        */ -2.72,-2.66,-2.63,-2.59,-2.55,-2.53,-2.52,-2.50 \ /*
        */ -2.73,-2.66,-2.63,-2.59,-2.55,-2.54,-2.52,-2.51)
    }

    * locate T row
    local ri = 8
    forvalues r = 1/8 {
        if `t' <= `te'[1,`r'] {
            local ri = `r'
            continue, break
        }
    }
    local ci = 8
    forvalues c = 1/8 {
        if `n' <= `en'[1,`c'] {
            local ci = `c'
            continue, break
        }
    }
    return scalar cv1  = `m1'[`ri',`ci']
    return scalar cv5  = `m5'[`ri',`ci']
    return scalar cv10 = `m10'[`ri',`ci']
end


* -------------------------------------------------------------------
* Graph : per-unit CADF and M-CADF vs critical values
* -------------------------------------------------------------------
program define _xtcipsm_graph
    version 14.0
    syntax , matname(string) cips(real) cv5(real) q(real) mdf(real) [ * ]

    preserve
    clear
    qui svmat double `matname', names(col)

    local g1
    twoway (scatter CADF id, msymbol(O) mcolor("0 0 180") mlabel(id) ///
                mlabposition(12) mlabsize(vsmall)) ,                  ///
        yline(`cv5', lpattern(dash) lcolor("200 0 0"))               ///
        yline(`cips', lpattern(solid) lcolor("0 130 0"))             ///
        ytitle("CADF statistic") xtitle("Cross-section (id)")        ///
        title("Individual CADF vs Pesaran 5% CV", size(medsmall))    ///
        note("solid green = CIPS = `: di %5.3f `cips''   dashed red = 5% CV = `: di %5.3f `cv5''", ///
             size(vsmall))                                           ///
        name(_xtcipsm_cadf, replace) nodraw
    local g1 _xtcipsm_cadf

    if (`q' > 0) {
        local cvchi = invchi2(`q', 0.95)
        twoway (scatter MCADF id, msymbol(D) mcolor("130 0 130") mlabel(id) ///
                    mlabposition(12) mlabsize(vsmall)) ,                    ///
            yline(`cvchi', lpattern(dash) lcolor("200 0 0"))               ///
            ytitle("Modified CADF") xtitle("Cross-section (id)")           ///
            title("Individual M-CADF vs chi2(`q') 5% CV", size(medsmall))  ///
            note("dashed red = chi2(`q') 5% CV = `: di %5.3f `cvchi''", size(vsmall)) ///
            name(_xtcipsm_mcadf, replace) nodraw
        graph combine _xtcipsm_cadf _xtcipsm_mcadf, ///
            cols(2) title("Modified CADF / CIPS panel unit-root test", size(medium)) ///
            `options'
    }
    else {
        graph combine _xtcipsm_cadf, `options'
    }
    restore
end


* ===================================================================
* MATA ENGINE
* ===================================================================
mata:

// OLS helper : returns coefficients, residuals and standard errors
void xtcipsm_ols(real colvector y, real matrix x,
                 real colvector b, real colvector e,
                 real colvector se, real scalar ssr)
{
    real matrix xxi
    real scalar n, k, s2
    n   = rows(x)
    k   = cols(x)
    xxi = invsym(quadcross(x,x))
    b   = xxi*quadcross(x,y)
    e   = y - x*b
    ssr = quadcross(e,e)
    s2  = ssr/(n-k)
    se  = sqrt(diagonal(xxi):*s2)
}

// CADF / LM / M-CADF for one cross-section, given lag p
void xtcipsm_cadf(real colvector yi, real colvector f, real scalar model,
                  real scalar p, real scalar tau, real scalar lm, real scalar dp)
{
    real scalar T, n, j, s2
    real colvector dy, y1, df0, f1, ones
    real matrix    dyp, dfp, d, w, g, Mw, Mg
    T = rows(yi)
    n = T - p - 1                                  // effective obs

    dy  = yi[(p+2)..T] - yi[(p+1)..(T-1)]
    y1  = yi[(p+1)..(T-1)]
    df0 = f[(p+2)..T]  - f[(p+1)..(T-1)]
    f1  = f[(p+1)..(T-1)]

    if (p > 0) {
        dyp = J(n, p, .)
        dfp = J(n, p, .)
        for (j = 1; j <= p; j++) {
            dyp[., j] = yi[(p+2-j)..(T-j)] - yi[(p+1-j)..(T-1-j)]
            dfp[., j] = f[(p+2-j)..(T-j)]  - f[(p+1-j)..(T-1-j)]
        }
    }

    ones = J(n, 1, 1)
    if      (model == 1) d = ones
    else if (model == 2) d = (ones, (1::n))

    if (p == 0) {
        if (model == 0) w = (f1, df0)
        else            w = (d, f1, df0)
    }
    else {
        if (model == 0) w = (f1, df0, dfp, dyp)
        else            w = (d, f1, df0, dfp, dyp)
    }

    g  = (w, y1)
    Mg = I(n) - g*invsym(quadcross(g,g))*g'
    Mw = I(n) - w*invsym(quadcross(w,w))*w'
    s2 = (dy'*Mg*dy)/(n - cols(g))

    tau = (y1'*Mw*dy)/sqrt(s2*(y1'*Mw*y1))
    lm  = n*(1 - (dy'*Mg*dy)/(dy'*Mw*dy))
    dp  = lm - tau^2
}

// lag selection (translates _get_cadf_lag + _get_lag)
real scalar xtcipsm_lag(real colvector yi, real colvector f,
                        real scalar model, real scalar pmax, real scalar ic)
{
    real scalar T, p, j, n, k, LL, sel
    real colvector dy, ly, df, lf, dc, dt, dep, y1, f1, df0
    real colvector b, e, se, ssr, aicp, sicp, tstatp
    real matrix    x, dyp, dfp

    T  = rows(yi)
    aicp   = J(pmax+1, 1, .)
    sicp   = J(pmax+1, 1, .)
    tstatp = J(pmax+1, 1, .)

    for (p = 0; p <= pmax; p++) {
        n  = T - p - 1
        dep = yi[(p+2)..T] - yi[(p+1)..(T-1)]
        y1  = yi[(p+1)..(T-1)]
        df0 = f[(p+2)..T]  - f[(p+1)..(T-1)]
        f1  = f[(p+1)..(T-1)]
        if (p > 0) {
            dyp = J(n, p, .); dfp = J(n, p, .)
            for (j = 1; j <= p; j++) {
                dyp[., j] = yi[(p+2-j)..(T-j)] - yi[(p+1-j)..(T-1-j)]
                dfp[., j] = f[(p+2-j)..(T-j)]  - f[(p+1-j)..(T-1-j)]
            }
        }
        if (p == 0) {
            if      (model == 0) x = (y1, f1, df0)
            else if (model == 1) x = (y1, f1, df0, J(n,1,1))
            else                 x = (y1, f1, df0, J(n,1,1), (1::n))
        }
        else {
            if      (model == 0) x = (y1, f1, dyp, df0, dfp)
            else if (model == 1) x = (y1, f1, J(n,1,1), dyp, df0, dfp)
            else                 x = (y1, f1, J(n,1,1), (1::n), dyp, df0, dfp)
        }
        xtcipsm_ols(dep, x, b=., e=., se=., ssr=0)
        k  = cols(x)
        LL = -n/2*(1 + ln(2*pi()) + ln(quadcross(e,e)/n))
        aicp[p+1]   = (2*k - 2*LL)/n
        sicp[p+1]   = (k*ln(n) - 2*LL)/n
        tstatp[p+1] = abs(b[k]/se[k])
    }

    if (ic == 1)      sel = xtcipsm_minindex(aicp)
    else if (ic == 2) sel = xtcipsm_minindex(sicp)
    else {                                          // t-stat, general-to-specific
        sel = pmax + 1
        while (sel > 1) {
            if (tstatp[sel] >= 1.645) break
            sel = sel - 1
        }
    }
    return(sel - 1)                                 // actual lag order
}

real scalar xtcipsm_minindex(real colvector v)
{
    real scalar i, im, vm
    im = 1
    vm = v[1]
    for (i = 2; i <= rows(v); i++) {
        if (v[i] < vm) {
            vm = v[i]
            im = i
        }
    }
    return(im)
}

void xtcipsm_calc(string scalar yv, string scalar tousev, string scalar idv,
                  real scalar model, real scalar pmax, real scalar ic,
                  real scalar N, real scalar T)
{
    real colvector y, f, idvals, ncadf, nlm, nd, nlags
    real matrix    ymat, RES
    real scalar    i, p, tau, lm, dp, cips, q, mcips, mdbar, mpval, pv

    y    = st_data(., yv, tousev)
    ymat = (colshape(y, T))'
    f    = rowsum(ymat) :/ N
    idvals = (colshape(st_data(., idv, tousev), T))[., 1]

    ncadf = J(N,1,.); nlm = J(N,1,.); nd = J(N,1,.); nlags = J(N,1,.)
    for (i = 1; i <= N; i++) {
        p = xtcipsm_lag(ymat[.,i], f, model, pmax, ic)
        xtcipsm_cadf(ymat[.,i], f, model, p, tau=., lm=., dp=.)
        ncadf[i] = tau; nlm[i] = lm; nd[i] = dp; nlags[i] = p
    }

    cips = mean(ncadf)
    if      (model == 1) q = 2
    else if (model == 2) q = 3
    else                 q = 0
    if (q > 0) {
        mdbar = mean(nd)
        mcips = sqrt(N)*(mdbar - q)/sqrt(2*q)
        mpval = normal(mcips)
    }
    else {
        mdbar = .
        mcips = .
        mpval = .
    }

    // individual M-CADF p-values (chi2 upper tail)
    real colvector mpv
    mpv = J(N,1,.)
    if (q > 0) for (i = 1; i <= N; i++) mpv[i] = chi2tail(q, abs(nd[i]))

    RES = (idvals, ncadf, nlm, nd, mpv, nlags)

    st_local("xtc_cips",  strofreal(cips,  "%18.0g"))
    st_local("xtc_mcips", strofreal(mcips, "%18.0g"))
    st_local("xtc_mpval", strofreal(mpval, "%18.0g"))
    st_local("xtc_mdbar", strofreal(mdbar, "%18.0g"))
    st_matrix("xtc_res", RES)
    st_matrixcolstripe("xtc_res", (J(6,1,""), ("id"\"CADF"\"LM"\"MCADF"\"pval"\"lags")))
}
end
