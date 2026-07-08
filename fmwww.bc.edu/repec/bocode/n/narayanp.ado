*! narayanp 1.0.0  Narayan-Popp (2010) two-break ADF unit root test
*! Stata/Mata port of the GAUSS tspdlib routine ADF_2breaks (S. Nazlioglu)
*! Reference: Narayan, P.K. and Popp, S. (2010), "A new unit root test with two
*! structural breaks in level and slope at unknown time", Journal of Applied
*! Statistics 37, 1425-1438.
program define narayanp, rclass
    version 14.0
    syntax varname(ts) [if] [in] [, MODel(integer 1) PMAX(integer 8) IC(integer 3) TRIM(real 0.10) SEQuential SIMul BG BGLags(integer -1) BGDF(integer 20)]
    local seq = ("`sequential'" != "")
    local simflag = ("`simul'" != "")
    if `seq' & `simflag' {
        display as error "sequential and simul cannot be combined; choose one break-search procedure"
        exit 198
    }
    local bgflag = ("`bg'" != "")
    if `bglags' != -1 & `bglags' < 1 {
        display as error "bglags() must be a positive integer"
        exit 198
    }
    if `bgdf' < 1 {
        display as error "bgdf() must be a positive integer"
        exit 198
    }

    * ----------------------------------------------------------------
    * Option validation
    * ----------------------------------------------------------------
    if !inlist(`model', 1, 2) {
        display as error "model() must be 1 (M1, break in level) or 2 (M2, break in level and slope)"
        exit 198
    }
    if !inlist(`ic', 1, 2, 3) {
        display as error "ic() must be 1 (AIC), 2 (SIC), or 3 (t-sig, general-to-specific)"
        exit 198
    }
    if `pmax' < 0 {
        display as error "pmax() must be a non-negative integer"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        display as error "trim() must lie strictly between 0 and 0.5"
        exit 198
    }

    * ----------------------------------------------------------------
    * Input series. Time-series operators (D.y, D2.y, L.y, ...) are
    * supported: the expression is evaluated into a temporary variable
    * and the leading missing values it creates are trimmed from the
    * sample. Internal missing values (gaps) still abort, as in the
    * GAUSS routine (_checkForMissings).
    * ----------------------------------------------------------------
    local ylab `varlist'
    local yvar `varlist'
    if strpos("`varlist'", ".") {
        tempvar tsv
        qui gen double `tsv' = `varlist'
        local yvar `tsv'
    }
    marksample touse, novarlist
    tempvar obsn
    qui gen long `obsn' = _n
    qui summarize `obsn' if `touse' & !missing(`yvar'), meanonly
    if r(N) == 0 {
        display as error "`ylab' has no nonmissing observations in the selected sample"
        exit 2000
    }
    qui replace `touse' = 0 if `obsn' < r(min) | `obsn' > r(max)
    qui count if `touse' & missing(`yvar')
    if r(N) > 0 {
        display as error "`ylab' contains internal missing values (gaps) in the selected sample; narayanp requires a gap-free series"
        exit 416
    }
    qui count if `touse'
    local nobs = r(N)
    local kmin = cond(`model' == 2, 2 * `pmax' + 9, 2 * `pmax' + 7)
    if `seq' | `simflag' local kmin = `kmin' + 2
    if `nobs' < `kmin' {
        display as error "too few observations for the chosen pmax() and model()"
        exit 2001
    }

    * ----------------------------------------------------------------
    * Time variable (for reporting break periods)
    * ----------------------------------------------------------------
    qui tsset
    local tvar `r(timevar)'
    local tsfmt `r(tsfmt)'

    * ----------------------------------------------------------------
    * Default BG horizon: roughly two years of autocorrelation orders,
    * chosen from the data frequency (quarterly 8, monthly 24, weekly 52,
    * daily 100, yearly 2, otherwise 2), then capped at five times the
    * conservative lag bound floor(4*(T/100)^0.25) and floored at 1. An explicit
    * bglags() overrides and is never capped. The horizon is used both by
    * the bg lag selection and by the post-selection BG diagnostic that is
    * reported for every lag-selection method.
    * ----------------------------------------------------------------
    if `bglags' == -1 {
        if strpos("`tsfmt'", "q") local bglags = 8
        else if strpos("`tsfmt'", "m") local bglags = 24
        else if strpos("`tsfmt'", "w") local bglags = 52
        else if strpos("`tsfmt'", "d") local bglags = 100
        else if strpos("`tsfmt'", "y") local bglags = 2
        else local bglags = 2
        local kcons = floor(4*((`nobs'/100)^0.25))
        if `kcons' < 1 local kcons = 1
        local bgcap = 5 * `kcons'
        if `bglags' > `bgcap' local bglags = `bgcap'
        if `bglags' < 1 local bglags = 1
    }

    * ----------------------------------------------------------------
    * Engine (Mata). Results are written into temporary scalars.
    * ----------------------------------------------------------------
    tempname tstat tb1 tb2 lags cv1 cv5 cv10 nused frac1 frac2 tval1 tval2 dp bgp fst
    mata: _narayanp_engine("`yvar'", "`tvar'", "`touse'", `model', `pmax', `ic', `trim', `seq', `simflag', `bgflag', `bglags', `bgdf', "`tstat'", "`tb1'", "`tb2'", "`lags'", "`cv1'", "`cv5'", "`cv10'", "`nused'", "`frac1'", "`frac2'", "`tval1'", "`tval2'", "`dp'", "`bgp'", "`fst'")

    * ----------------------------------------------------------------
    * Display
    * ----------------------------------------------------------------
    local modtxt "M1, break in level"
    if `model' == 2 local modtxt "M2, break in level and slope"
    local bstxt "full grid, min ADF t (tspdlib)"
    if `seq' local bstxt "sequential (paper, Eqs. 10-11)"
    if `simflag' local bstxt "simultaneous, max impulse F (paper, Eq. 9)"
    local ictxt "t-sig (general-to-specific)"
    if `ic' == 1 local ictxt "AIC"
    if `ic' == 2 local ictxt "SIC"
    if `bgflag' local ictxt "Breusch-Godfrey, orders 1-`bglags'"
    local tfmt : format `tvar'

    display ""
    display as text "Narayan-Popp (2010) two-break ADF unit root test"
    display as text "{hline 63}"
    display as text "Series"     _col(16) as result "`ylab'"
    display as text "Model"      _col(16) as result "`model'" as text "  (`modtxt')"
    display as text "Break search" _col(16) as result "`bstxt'"
    display as text "Lag order"  _col(16) as result %2.0f scalar(`lags') as text "  (max `pmax', selected by `ictxt')"
    display as text "BG min p-value" _col(16) as result %6.4f scalar(`bgp') as text "  (orders 1 to `bglags', df floor `bgdf', at winning regression)"
    display as text "Trimming"   _col(16) as result %4.2f `trim' as text _col(34) "Obs used" _col(45) as result %5.0f scalar(`nused')
    display as text "{hline 63}"
    display as text _col(3) "Test statistic" _col(22) "1% crit." _col(36) "5% crit." _col(50) "10% crit."
    display as result _col(3) %9.4f scalar(`tstat') as text _col(22) as result %8.3f scalar(`cv1') as text _col(36) as result %8.3f scalar(`cv5') as text _col(50) as result %8.3f scalar(`cv10')
    display as text "{hline 63}"
    display as text "Estimated break points:"
    display as text "  TB1 = obs " as result %3.0f scalar(`tb1') as text "   period " as result `tfmt' scalar(`tval1') as text "   (fraction " as result %5.3f scalar(`frac1') as text ")"
    display as text "  TB2 = obs " as result %3.0f scalar(`tb2') as text "   period " as result `tfmt' scalar(`tval2') as text "   (fraction " as result %5.3f scalar(`frac2') as text ")"
    display as text "{hline 63}"
    if `bgflag' & scalar(`dp') == 1 {
        display as result "Warning: autocorrelation could not be eliminated with pmax = `pmax' lags"
        display as result "at the selected break dates; pmax was used. Consider increasing pmax()."
        display as text "{hline 63}"
    }
    if !`bgflag' & scalar(`bgp') < 0.05 {
        display as result "Warning: Breusch-Godfrey detects residual autocorrelation at the selected"
        display as result "breaks and lag (min p < 0.05). Consider the bg option or a larger pmax()."
        display as text "{hline 63}"
    }
    if scalar(`tstat') < scalar(`cv1') {
        display as text "H0: unit root -- rejected at the 1% level."
    }
    else if scalar(`tstat') < scalar(`cv5') {
        display as text "H0: unit root -- rejected at the 5% level."
    }
    else if scalar(`tstat') < scalar(`cv10') {
        display as text "H0: unit root -- rejected at the 10% level."
    }
    else {
        display as text "H0: unit root -- cannot be rejected at the 10% level."
    }

    * ----------------------------------------------------------------
    * Returned results
    * ----------------------------------------------------------------
    return scalar tstat = scalar(`tstat')
    return scalar tb1   = scalar(`tb1')
    return scalar tb2   = scalar(`tb2')
    return scalar frac1 = scalar(`frac1')
    return scalar frac2 = scalar(`frac2')
    return scalar lags  = scalar(`lags')
    return scalar cv1   = scalar(`cv1')
    return scalar cv5   = scalar(`cv5')
    return scalar cv10  = scalar(`cv10')
    return scalar N     = scalar(`nused')
    return local ic     "`ic'"
    local lstxt = cond(`bgflag', "bg", cond(`ic'==1, "aic", cond(`ic'==2, "sic", "tsig")))
    return local lagsel "`lstxt'"
    return scalar bglags = `bglags'
    return scalar bgminp = scalar(`bgp')
    return scalar bgdf = `bgdf'
    return local model  "`model'"
    local bsret "grid"
    if `seq' local bsret "sequential"
    if `simflag' local bsret "simultaneous"
    return local breaksearch "`bsret'"
    if `simflag' return scalar fstat = scalar(`fst')
    return local varname "`ylab'"
end

* ====================================================================
* Mata engine: faithful port of GAUSS tspdlib ADF_2breaks and helpers
*   (myols, _runFourierOLS, __lag_selection_loop with
*    ENFORCE_SAMPLE_SIZE=1, _get_lag, __get_ur_z_det,
*    _getFourierDeterministic). Inside Mata, comments use // and /* */
*    because * is the multiplication operator.
* ====================================================================
version 14.0
mata:
mata set matastrict off

// index of the (first) minimum element, matching GAUSS minindc
real scalar _np_minindc(real colvector v)
{
    real scalar i, im, m
    im = 1
    m  = v[1]
    for (i=2; i<=rows(v); i++) {
        if (v[i] < m) {
            m  = v[i]
            im = i
        }
    }
    return(im)
}

// lag a (matrix) series by n with missing fill at the top: GAUSS lagn
real matrix _np_lagn(real matrix x, real scalar n)
{
    real scalar r
    real matrix out
    r   = rows(x)
    out = J(r, cols(x), .)
    if (n < r) {
        out[(n+1)::r, .] = x[1::(r-n), .]
    }
    return(out)
}

// remove top rows and bottom rows: GAUSS trimr
real matrix _np_trimr(real matrix x, real scalar top, real scalar bot)
{
    real scalar r
    r = rows(x)
    return(x[(top+1)::(r-bot), .])
}

// additive sequence: GAUSS seqa
real colvector _np_seqa(real scalar a, real scalar inc, real scalar n)
{
    return(a :+ inc :* (0::(n-1)))
}

// OLS as in GAUSS myols + _runFourierOLS (fourier=0, tstat_adj=0).
// Returns (tau_on_col1, aic, sic, |t_on_last_col|, ssr).
real rowvector _np_ols(real colvector dep, real matrix x)
{
    real matrix xtxi
    real colvector b, e, se
    real scalar ssr, n, k, sig2, taup, ll, aicp, sicp, tstatp
    xtxi   = luinv(cross(x, x))
    b      = xtxi * cross(x, dep)
    e      = dep - x * b
    ssr    = cross(e, e)
    n      = rows(dep)
    k      = cols(x)
    sig2   = ssr / (n - k)
    se     = sqrt(diagonal(xtxi) :* sig2)
    taup   = b[1] / se[1]
    ll     = -n/2 * (1 + ln(2 * pi()) + ln(ssr / n))
    aicp   = (2 * k - 2 * ll) / n
    sicp   = (k * ln(n) - 2 * ll) / n
    tstatp = abs(b[k] / se[k])
    return((taup, aicp, sicp, tstatp, ssr))
}

// lag order selection as in GAUSS _get_lag
real scalar _np_getlag(real scalar ic, real scalar pmax, real colvector aicp, real colvector sicp, real colvector tstatp)
{
    real scalar p, j
    if (ic == 1) {
        return(_np_minindc(aicp))
    }
    if (ic == 2) {
        return(_np_minindc(sicp))
    }
    // ic == 3 : general-to-specific t-significance, top down from pmax
    j = pmax + 1
    while (j >= 1) {
        if (abs(tstatp[j]) > 1.645) {
            break
        }
        j = j - 1
    }
    p = j
    if (p == 0) {
        p = 1
    }
    return(p)
}

// Fast lag selection on the fixed enforced sample (rows pmax+2..t, common to
// every candidate lag). The full-lag design X'X (XX) and X'y (Xy) are formed
// once per candidate break pair with a single cross-product; for lag order p
// the required X'X is the leading (3+d+p) principal submatrix, so no further
// cross-products are needed. The column layout [ly, dc, dt, D, dy_1..dy_pmax]
// makes the t-statistic column the last one at every lag. SSR is obtained
// algebraically (SSR = y'y - b'X'y). The selected lag's t-ratio (the actual
// test statistic) is recomputed exactly on the full sample in the caller, so
// the reported statistic is unaffected by this fast selection. Returns p_opt.
real scalar _np_fastsel(real matrix XX, real colvector Xy, real scalar yy, real scalar pmax, real scalar ic, real scalar ne, real scalar d)
{
    real scalar p, kp, ssr, ll, sig2
    real colvector aicp, sicp, tstatp, b, xyk
    real matrix m
    aicp   = J(pmax + 1, 1, .)
    sicp   = J(pmax + 1, 1, .)
    tstatp = J(pmax + 1, 1, .)
    for (p=0; p<=pmax; p++) {
        kp  = 3 + d + p
        m   = luinv(XX[1::kp, 1::kp])
        xyk = Xy[1::kp]
        b   = m * xyk
        ssr = yy - sum(b :* xyk)
        ll  = -ne/2 * (1 + ln(2 * pi()) + ln(ssr / ne))
        aicp[p+1] = (2 * kp - 2 * ll) / ne
        sicp[p+1] = (kp * ln(ne) - 2 * ll) / ne
        sig2 = ssr / (ne - kp)
        tstatp[p+1] = abs(b[kp] / sqrt(m[kp, kp] * sig2))
    }
    return(_np_getlag(ic, pmax, aicp, sicp, tstatp))
}

// Candidate regression for the sequential procedure of Narayan and Popp
// (2010, Eqs. 10-11). The regressors are x = (y_lag, Z, dy-lags) where Z is
// the paper-form deterministic set including the one-period impulse dummies.
// Lag selection uses the same enforced-common-sample mechanics as the grid;
// the full-sample regression at the selected lag then delivers the t-ratio
// of a requested column (the impulse-dummy coefficient during the break
// search) and of column 1 (the ADF statistic). Returns (t_col, tau, p_opt).
real rowvector _np_seqreg(real colvector depy, real colvector basex, real matrix Z, real matrix lmat, real scalar pmax, real scalar ic, real scalar col)
{
    real scalar p, popt, plag, n, k, sig2, ssr, tcol, tau
    real colvector aicp, sicp, tstatp, dep, dep2, b, e
    real matrix x, x2, rl, xtxi
    real rowvector os
    aicp   = J(pmax + 1, 1, .)
    sicp   = J(pmax + 1, 1, .)
    tstatp = J(pmax + 1, 1, .)
    for (p=0; p<=pmax; p++) {
        dep = _np_trimr(depy, p + 1, 0)
        x   = (_np_trimr(basex, p + 1, 0), _np_trimr(Z, p + 1, 0))
        if (p > 0) {
            rl = _np_trimr(lmat[., 1::p], p + 1, 0)
            x  = (x, rl)
        }
        dep2 = _np_trimr(dep, pmax - p, 0)
        x2   = _np_trimr(x, pmax - p, 0)
        os          = _np_ols(dep2, x2)
        aicp[p+1]   = os[2]
        sicp[p+1]   = os[3]
        tstatp[p+1] = os[4]
    }
    popt = _np_getlag(ic, pmax, aicp, sicp, tstatp)
    plag = popt - 1
    dep  = _np_trimr(depy, plag + 1, 0)
    x    = (_np_trimr(basex, plag + 1, 0), _np_trimr(Z, plag + 1, 0))
    if (plag > 0) {
        x = (x, _np_trimr(lmat[., 1::plag], plag + 1, 0))
    }
    xtxi = luinv(cross(x, x))
    b    = xtxi * cross(x, dep)
    e    = dep - x * b
    ssr  = cross(e, e)
    n    = rows(dep)
    k    = cols(x)
    sig2 = ssr / (n - k)
    tcol = b[col] / sqrt(xtxi[col, col] * sig2)
    tau  = b[1] / sqrt(xtxi[1, 1] * sig2)
    return((tcol, tau, popt))
}

// Candidate-pair regression for the simultaneous procedure of Narayan and
// Popp (2010, Eq. 9): identical lag-selection mechanics to _np_seqreg, but
// the returned criterion is the F statistic for the joint significance of
// the two impulse-dummy coefficients (columns c1 and c2 of the regressor
// matrix). Returns (F, tau, popt).
real rowvector _np_simreg(real colvector depy, real colvector basex, real matrix Z, real matrix lmat, real scalar pmax, real scalar ic, real scalar c1, real scalar c2)
{
    real scalar p, popt, plag, n, k, sig2, ssr, tau, Fs
    real colvector aicp, sicp, tstatp, dep, dep2, b, e, bc, idx
    real matrix x, x2, rl, xtxi, Vi
    real rowvector os
    aicp   = J(pmax + 1, 1, .)
    sicp   = J(pmax + 1, 1, .)
    tstatp = J(pmax + 1, 1, .)
    for (p=0; p<=pmax; p++) {
        dep = _np_trimr(depy, p + 1, 0)
        x   = (_np_trimr(basex, p + 1, 0), _np_trimr(Z, p + 1, 0))
        if (p > 0) {
            rl = _np_trimr(lmat[., 1::p], p + 1, 0)
            x  = (x, rl)
        }
        dep2 = _np_trimr(dep, pmax - p, 0)
        x2   = _np_trimr(x, pmax - p, 0)
        os          = _np_ols(dep2, x2)
        aicp[p+1]   = os[2]
        sicp[p+1]   = os[3]
        tstatp[p+1] = os[4]
    }
    popt = _np_getlag(ic, pmax, aicp, sicp, tstatp)
    plag = popt - 1
    dep  = _np_trimr(depy, plag + 1, 0)
    x    = (_np_trimr(basex, plag + 1, 0), _np_trimr(Z, plag + 1, 0))
    if (plag > 0) {
        x = (x, _np_trimr(lmat[., 1::plag], plag + 1, 0))
    }
    xtxi = luinv(cross(x, x))
    b    = xtxi * cross(x, dep)
    e    = dep - x * b
    ssr  = cross(e, e)
    n    = rows(dep)
    k    = cols(x)
    sig2 = ssr / (n - k)
    tau  = b[1] / sqrt(xtxi[1, 1] * sig2)
    idx  = (c1 \ c2)
    bc   = b[idx]
    Vi   = luinv(xtxi[idx, idx] * sig2)
    if (missing(Vi[1, 1])) {
        Fs = .
    }
    else {
        Fs = (bc' * Vi * bc) / 2
    }
    return((Fs, tau, popt))
}

// Single regression at a fixed lag, returning the joint impulse F and tau;
// used by the simultaneous procedure under bg lag selection.
real rowvector _np_fitf(real colvector depy, real colvector basex, real matrix Z, real matrix lmat, real scalar plag, real scalar c1, real scalar c2)
{
    real scalar n, k, sig2, ssr, tau, Fs
    real colvector dep, b, e, bc, idx
    real matrix x, xtxi, Vi
    dep = _np_trimr(depy, plag + 1, 0)
    x   = (_np_trimr(basex, plag + 1, 0), _np_trimr(Z, plag + 1, 0))
    if (plag > 0) {
        x = (x, _np_trimr(lmat[., 1::plag], plag + 1, 0))
    }
    xtxi = luinv(cross(x, x))
    if (missing(xtxi[1, 1])) {
        return((., ., 0))
    }
    b    = xtxi * cross(x, dep)
    e    = dep - x * b
    ssr  = cross(e, e)
    n    = rows(dep)
    k    = cols(x)
    sig2 = ssr / (n - k)
    tau  = b[1] / sqrt(xtxi[1, 1] * sig2)
    idx  = (c1 \ c2)
    bc   = b[idx]
    Vi   = luinv(xtxi[idx, idx] * sig2)
    if (missing(Vi[1, 1])) {
        return((., tau, 0))
    }
    Fs = (bc' * Vi * bc) / 2
    return((Fs, tau, 1))
}

// Breusch-Godfrey test on the residuals of a candidate test regression,
// following the convention of -estat bgodfrey, lags(l) nomiss0-: for each
// order l = 1..bglags the auxiliary regression of the trimmed residuals on
// the original regressors (same rows) plus l lagged residuals is run on
// complete cases only, LM = n2*R2 with the centered R2, compared with
// chi2(l) at the 5 percent level. Returns 1 as soon as any order rejects
// (autocorrelation present), 0 if all orders pass.
real scalar _np_bgdirty(real colvector e, real matrix x, real scalar bglags, real scalar dfmin)
{
    real scalar n, k, l, n2, j, ssr, tss, lm
    real colvector e0, ba
    real matrix El, Xa, xtxia
    n = rows(e)
    k = cols(x)
    for (l=1; l<=bglags; l++) {
        n2 = n - l
        if (n - k - 2*l < dfmin) {
            continue
        }
        if (n2 <= k + l + 1) {
            continue
        }
        e0 = e[(l+1)::n]
        El = J(n2, l, 0)
        for (j=1; j<=l; j++) {
            El[., j] = e[(l+1-j)::(n-j)]
        }
        Xa = (x[(l+1)::n, .], El)
        xtxia = luinv(cross(Xa, Xa))
        if (missing(xtxia[1, 1])) {
            continue
        }
        ba  = xtxia * cross(Xa, e0)
        ssr = cross(e0 - Xa * ba, e0 - Xa * ba)
        tss = cross(e0 :- mean(e0), e0 :- mean(e0))
        lm  = n2 * (1 - ssr / tss)
        if (chi2tail(l, lm) < 0.05) {
            return(1)
        }
    }
    return(0)
}

// Minimum Breusch-Godfrey p-value over orders 1..bglags (no early exit),
// same conventions as _np_bgdirty; used only for reporting at the winning
// break dates and selected lag. Returns missing if no order is testable.
real scalar _np_bgminp(real colvector e, real matrix x, real scalar bglags, real scalar dfmin)
{
    real scalar n, k, l, n2, j, ssr, tss, lm, p, mp
    real colvector e0, ba
    real matrix El, Xa, xtxia
    n  = rows(e)
    k  = cols(x)
    mp = .
    for (l=1; l<=bglags; l++) {
        n2 = n - l
        if (n - k - 2*l < dfmin) {
            continue
        }
        if (n2 <= k + l + 1) {
            continue
        }
        e0 = e[(l+1)::n]
        El = J(n2, l, 0)
        for (j=1; j<=l; j++) {
            El[., j] = e[(l+1-j)::(n-j)]
        }
        Xa = (x[(l+1)::n, .], El)
        xtxia = luinv(cross(Xa, Xa))
        if (missing(xtxia[1, 1])) {
            continue
        }
        ba  = xtxia * cross(Xa, e0)
        ssr = cross(e0 - Xa * ba, e0 - Xa * ba)
        tss = cross(e0 :- mean(e0), e0 :- mean(e0))
        lm  = n2 * (1 - ssr / tss)
        p   = chi2tail(l, lm)
        if (p < mp) {
            mp = p
        }
    }
    return(mp)
}

// General-to-specific lag selection by Breusch-Godfrey on the candidate
// regression itself: x = (y_lag, Z, dy-lags) at lag K on its full sample.
// Walk K = pmax..0; at the first K whose residuals show autocorrelation,
// return the previous (clean) K; if pmax itself is dirty, return pmax with
// the dirty-at-pmax flag set; if no K is dirty, return 0. The returned tau
// and t_col come from the regression at the selected K, so no refit is
// needed. Returns (K, tau, t_col, dirty_at_pmax, ok).
real rowvector _np_bgwalk(real colvector depy, real colvector basex, real matrix Z, real matrix lmat, real scalar pmax, real scalar bglags, real scalar dfmin, real scalar col)
{
    real scalar K, Kprev, n, k, sig2, ssr, tau, tcol, tauprev, tcolprev, dirty
    real colvector dep, b, e
    real matrix x, xtxi
    Kprev    = pmax
    tauprev  = .
    tcolprev = .
    for (K=pmax; K>=0; K--) {
        dep = _np_trimr(depy, K + 1, 0)
        x   = (_np_trimr(basex, K + 1, 0), _np_trimr(Z, K + 1, 0))
        if (K > 0) {
            x = (x, _np_trimr(lmat[., 1::K], K + 1, 0))
        }
        xtxi = luinv(cross(x, x))
        if (missing(xtxi[1, 1])) {
            return((0, ., ., 0, 0))
        }
        b    = xtxi * cross(x, dep)
        e    = dep - x * b
        ssr  = cross(e, e)
        n    = rows(dep)
        k    = cols(x)
        sig2 = ssr / (n - k)
        tau  = b[1] / sqrt(xtxi[1, 1] * sig2)
        tcol = b[col] / sqrt(xtxi[col, col] * sig2)
        dirty = _np_bgdirty(e, x, bglags, dfmin)
        if (dirty) {
            if (K == pmax) {
                return((pmax, tau, tcol, 1, 1))
            }
            return((Kprev, tauprev, tcolprev, 0, 1))
        }
        Kprev    = K
        tauprev  = tau
        tcolprev = tcol
    }
    return((0, tauprev, tcolprev, 0, 1))
}

// Main engine: GAUSS ADF_2breaks grid search over (tb1, tb2).
void _narayanp_engine(string scalar yname, string scalar tvarname, string scalar tousename, real scalar model, real scalar pmax, real scalar ic, real scalar trim, real scalar seq, real scalar simul, real scalar bg, real scalar bglags, real scalar bgdf, string scalar s_tstat, string scalar s_tb1, string scalar s_tb2, string scalar s_lags, string scalar s_cv1, string scalar s_cv5, string scalar s_cv10, string scalar s_n, string scalar s_f1, string scalar s_f2, string scalar s_tv1, string scalar s_tv2, string scalar s_dp, string scalar s_bgp, string scalar s_fst)
{
    real colvector y, tv, dy, ly, dc, dt, du1, du2, dt1, dt2, depR, Xy, dep
    real colvector D1, DU1L, DT1L, D2c, DU2L, DT2L
    real matrix zdet, lmat, L3, Ldy, DR, Dfull, Xfull, XX, xf, Zs
    real scalar t, tt1, tt2, tb1, tb2, admin, tb1m, tb2m, optlag, j
    real scalar Rlo, ne, d, popt, plag, yy
    real scalar tb1s, tb2s, gap, tbest, att, colx, tb, dpm, bgpv, fstat
    real colvector bw, ew, D2w, DU2w, DT2w
    real matrix xw, xiw
    real rowvector cv, of, rv, rw

    y  = st_data(., yname, tousename)
    tv = st_data(., tvarname, tousename)
    t  = rows(y)

    if (missing(y) > 0) {
        _error("variable has missing values in the sample; narayanp requires a gap-free series")
    }

    dy = y - _np_lagn(y, 1)
    ly = _np_lagn(y, 1)
    dc = J(t, 1, 1)
    dt = _np_seqa(1, 1, t)

    tt1 = max((3 + pmax, ceil(trim * t)))
    tt2 = min((t - 3 - pmax, floor((1 - trim) * t)))
    if (tt1 < pmax + 2) {
        tt1 = pmax + 3
    }

    // matrix of lags 1..pmax of dy
    lmat = J(t, pmax, .)
    for (j=1; j<=pmax; j++) {
        lmat[., j] = _np_lagn(dy, j)
    }

    admin  = 1000
    tb1m   = 0
    tb2m   = 0
    optlag = .
    dpm    = 0
    fstat  = .

    if (seq == 1) {
        // ------------------------------------------------------------
        // Sequential procedure, Narayan and Popp (2010, Eqs. 10-11),
        // on the paper-form test regressions (Eq. 7 for M1, Eq. 8 for
        // M2): each break contributes a one-period impulse dummy
        // 1(t = TB+1) and a lagged level-shift dummy 1(t > TB+1), plus
        // a lagged trend-shift dummy for M2.
        // ------------------------------------------------------------
        // step 1: single break maximizing |t| of the impulse coefficient
        tbest = -1
        tb1s  = 0
        for (tb=tt1; tb<=tt2; tb++) {
            D1   = (J(tb, 1, 0) \ 1 \ J(t - tb - 1, 1, 0))
            DU1L = (J(tb + 1, 1, 0) \ J(t - tb - 1, 1, 1))
            if (model == 1) {
                Zs = (dc, dt, D1, DU1L)
            }
            else {
                DT1L = (J(tb + 1, 1, 0) \ _np_seqa(1, 1, t - tb - 1))
                Zs   = (dc, dt, D1, DU1L, DT1L)
            }
            if (bg == 1) {
                rw = _np_bgwalk(dy, ly, Zs, lmat, pmax, bglags, bgdf, 4)
                if (rw[5] == 0) {
                    att = .
                }
                else {
                    att = abs(rw[3])
                }
            }
            else {
                rv  = _np_seqreg(dy, ly, Zs, lmat, pmax, ic, 4)
                att = abs(rv[1])
            }
            if (att < . & att > tbest) {
                tbest = att
                tb1s  = tb
            }
        }
        if (tb1s == 0) {
            _error("sequential step 1 found no admissible break date; increase the sample or reduce pmax()/trim()")
        }
        // step 2: impose TB1, maximize |t| of the second impulse coefficient
        if (model == 1) {
            gap = 2
        }
        else {
            gap = 3
        }
        D1   = (J(tb1s, 1, 0) \ 1 \ J(t - tb1s - 1, 1, 0))
        DU1L = (J(tb1s + 1, 1, 0) \ J(t - tb1s - 1, 1, 1))
        if (model == 2) {
            DT1L = (J(tb1s + 1, 1, 0) \ _np_seqa(1, 1, t - tb1s - 1))
        }
        tbest = -1
        tb2s  = 0
        for (tb=tt1; tb<=tt2; tb++) {
            if (abs(tb - tb1s) < gap) {
                continue
            }
            D2c  = (J(tb, 1, 0) \ 1 \ J(t - tb - 1, 1, 0))
            DU2L = (J(tb + 1, 1, 0) \ J(t - tb - 1, 1, 1))
            if (model == 1) {
                Zs   = (dc, dt, D1, DU1L, D2c, DU2L)
                colx = 6
            }
            else {
                DT2L = (J(tb + 1, 1, 0) \ _np_seqa(1, 1, t - tb - 1))
                Zs   = (dc, dt, D1, DU1L, DT1L, D2c, DU2L, DT2L)
                colx = 7
            }
            if (bg == 1) {
                rw = _np_bgwalk(dy, ly, Zs, lmat, pmax, bglags, bgdf, colx)
                if (rw[5] == 1) {
                    att = abs(rw[3])
                }
                else {
                    att = .
                }
                if (att < . & att > tbest) {
                    tbest  = att
                    tb2s   = tb
                    admin  = rw[2]
                    optlag = rw[1] + 1
                    dpm    = rw[4]
                }
            }
            else {
                rv  = _np_seqreg(dy, ly, Zs, lmat, pmax, ic, colx)
                att = abs(rv[1])
                if (att < . & att > tbest) {
                    tbest  = att
                    tb2s   = tb
                    admin  = rv[2]
                    optlag = rv[3]
                }
            }
        }
        if (tb2s == 0) {
            _error("sequential step 2 found no admissible break date; increase the sample or reduce pmax()/trim()")
        }
        // report breaks in chronological order
        tb1m = min((tb1s, tb2s))
        tb2m = max((tb1s, tb2s))
    }
    else if (simul == 1) {
        // ------------------------------------------------------------
        // Simultaneous procedure, Narayan and Popp (2010, Eq. 9), on
        // the paper-form test regressions: over all admissible break
        // pairs, choose the pair maximizing the F statistic for the
        // joint significance of the two impulse-dummy coefficients.
        // ------------------------------------------------------------
        if (model == 1) {
            gap = 2
        }
        else {
            gap = 3
        }
        tbest = -1
        tb1   = tt1
        while (tb1 <= tt2 - gap) {
            D1   = (J(tb1, 1, 0) \ 1 \ J(t - tb1 - 1, 1, 0))
            DU1L = (J(tb1 + 1, 1, 0) \ J(t - tb1 - 1, 1, 1))
            if (model == 2) {
                DT1L = (J(tb1 + 1, 1, 0) \ _np_seqa(1, 1, t - tb1 - 1))
            }
            tb2 = tb1 + gap
            while (tb2 <= tt2) {
                D2c  = (J(tb2, 1, 0) \ 1 \ J(t - tb2 - 1, 1, 0))
                DU2L = (J(tb2 + 1, 1, 0) \ J(t - tb2 - 1, 1, 1))
                if (model == 1) {
                    Zs   = (dc, dt, D1, DU1L, D2c, DU2L)
                    colx = 6
                }
                else {
                    DT2L = (J(tb2 + 1, 1, 0) \ _np_seqa(1, 1, t - tb2 - 1))
                    Zs   = (dc, dt, D1, DU1L, DT1L, D2c, DU2L, DT2L)
                    colx = 7
                }
                if (bg == 1) {
                    rw = _np_bgwalk(dy, ly, Zs, lmat, pmax, bglags, bgdf, 4)
                    if (rw[5] == 1) {
                        of = _np_fitf(dy, ly, Zs, lmat, rw[1], 4, colx)
                        if (of[3] == 1) {
                            att = of[1]
                        }
                        else {
                            att = .
                        }
                    }
                    else {
                        att = .
                    }
                    if (att < . & att > tbest) {
                        tbest  = att
                        fstat  = att
                        tb1m   = tb1
                        tb2m   = tb2
                        admin  = of[2]
                        optlag = rw[1] + 1
                        dpm    = rw[4]
                    }
                }
                else {
                    rv  = _np_simreg(dy, ly, Zs, lmat, pmax, ic, 4, colx)
                    att = rv[1]
                    if (att < . & att > tbest) {
                        tbest  = att
                        fstat  = att
                        tb1m   = tb1
                        tb2m   = tb2
                        admin  = rv[2]
                        optlag = rv[3]
                    }
                }
                tb2 = tb2 + 1
            }
            tb1 = tb1 + 1
        }
    }
    else if (bg == 1) {
        // ------------------------------------------------------------
        // Full grid search with Breusch-Godfrey lag selection: at every
        // candidate break pair the lag is chosen by the general-to-
        // specific BG walk on that pair's own test regression.
        // ------------------------------------------------------------
        tb1 = tt1
        while (tb1 <= tt2) {
            if (model == 1) {
                tb2 = tb1 + 2
            }
            else {
                tb2 = tb1 + 3
            }
            while (tb2 <= tt2) {
                du1 = (J(tb1, 1, 0) \ J(t - tb1, 1, 1))
                du2 = (J(tb2, 1, 0) \ J(t - tb2, 1, 1))
                if (model == 1) {
                    zdet = (dc, dt, du1, du2)
                }
                else {
                    dt1  = (J(tb1, 1, 0) \ _np_seqa(1, 1, t - tb1))
                    dt2  = (J(tb2, 1, 0) \ _np_seqa(1, 1, t - tb2))
                    zdet = (dc, dt, du1, dt1, du2, dt2)
                }
                rw = _np_bgwalk(dy, ly, zdet, lmat, pmax, bglags, bgdf, 1)
                if (rw[5] == 1 & rw[2] < admin) {
                    tb1m   = tb1
                    tb2m   = tb2
                    admin  = rw[2]
                    optlag = rw[1] + 1
                    dpm    = rw[4]
                }
                tb2 = tb2 + 1
            }
            tb1 = tb1 + 1
        }
    }
    else {
        // ------------------------------------------------------------
        // Full grid search, GAUSS tspdlib ADF_2breaks.
        // ------------------------------------------------------------
        // Fixed pieces on the enforced sample rows (pmax+2..t), common to
        // every candidate lag: the deterministic-free columns split into
        // the left part [ly, dc, dt] and the dy-lag part, with the dummies
        // inserted between them per candidate pair.
        Rlo  = pmax + 2
        ne   = t - pmax - 1
        depR = dy[Rlo::t]
        yy   = cross(depR, depR)
        L3   = (ly[Rlo::t], dc[Rlo::t], dt[Rlo::t])
        Ldy  = lmat[Rlo::t, .]

        tb1 = tt1
        while (tb1 <= tt2) {
            if (model == 1) {
                tb2 = tb1 + 2
            }
            else {
                tb2 = tb1 + 3
            }
            while (tb2 <= tt2) {
                du1 = (J(tb1, 1, 0) \ J(t - tb1, 1, 1))
                du2 = (J(tb2, 1, 0) \ J(t - tb2, 1, 1))
                if (model == 1) {
                    // z_det order: const, trend, du1, du2
                    zdet  = (dc, dt, du1, du2)
                    Dfull = (du1, du2)
                }
                else {
                    dt1 = (J(tb1, 1, 0) \ _np_seqa(1, 1, t - tb1))
                    dt2 = (J(tb2, 1, 0) \ _np_seqa(1, 1, t - tb2))
                    // z_det order: const, trend, du1, dt1, du2, dt2
                    zdet  = (dc, dt, du1, dt1, du2, dt2)
                    Dfull = (du1, dt1, du2, dt2)
                }
                // full-lag design on the enforced sample, one cross-product per pair
                DR     = Dfull[Rlo::t, .]
                d      = cols(DR)
                Xfull  = (L3, DR, Ldy)
                XX     = cross(Xfull, Xfull)
                Xy     = cross(Xfull, depR)
                popt   = _np_fastsel(XX, Xy, yy, pmax, ic, ne, d)
                // exact full-sample statistic at the selected lag
                plag = popt - 1
                dep  = _np_trimr(dy, plag + 1, 0)
                xf   = (_np_trimr(ly, plag + 1, 0), _np_trimr(zdet, plag + 1, 0))
                if (plag > 0) {
                    xf = (xf, _np_trimr(lmat[., 1::plag], plag + 1, 0))
                }
                of = _np_ols(dep, xf)
                if (of[1] < admin) {
                    tb1m   = tb1
                    tb2m   = tb2
                    admin  = of[1]
                    optlag = popt
                }
                tb2 = tb2 + 1
            }
            tb1 = tb1 + 1
        }
    }

    if (tb1m == 0) {
        _error("no admissible break-date pair for the given pmax(), trim() and sample size; increase the sample or reduce pmax()/trim()")
    }

    // Post-selection Breusch-Godfrey diagnostic: the minimum BG p-value of
    // the winning regression (selected break dates at the selected lag),
    // computed for every lag-selection method. For the sequential path the
    // paper-form regressors are rebuilt at the sorted dates; the regression
    // is symmetric in the two breaks' columns, so the residuals equal those
    // of the detection-order regression.
    bgpv = .
    if (optlag < .) {
        plag = optlag - 1
        if (seq == 1 | simul == 1) {
            D1   = (J(tb1m, 1, 0) \ 1 \ J(t - tb1m - 1, 1, 0))
            DU1L = (J(tb1m + 1, 1, 0) \ J(t - tb1m - 1, 1, 1))
            D2w  = (J(tb2m, 1, 0) \ 1 \ J(t - tb2m - 1, 1, 0))
            DU2w = (J(tb2m + 1, 1, 0) \ J(t - tb2m - 1, 1, 1))
            if (model == 1) {
                xw = (dc, dt, D1, DU1L, D2w, DU2w)
            }
            else {
                DT1L = (J(tb1m + 1, 1, 0) \ _np_seqa(1, 1, t - tb1m - 1))
                DT2w = (J(tb2m + 1, 1, 0) \ _np_seqa(1, 1, t - tb2m - 1))
                xw = (dc, dt, D1, DU1L, DT1L, D2w, DU2w, DT2w)
            }
        }
        else {
            du1 = (J(tb1m, 1, 0) \ J(t - tb1m, 1, 1))
            du2 = (J(tb2m, 1, 0) \ J(t - tb2m, 1, 1))
            if (model == 1) {
                xw = (dc, dt, du1, du2)
            }
            else {
                dt1 = (J(tb1m, 1, 0) \ _np_seqa(1, 1, t - tb1m))
                dt2 = (J(tb2m, 1, 0) \ _np_seqa(1, 1, t - tb2m))
                xw = (dc, dt, du1, dt1, du2, dt2)
            }
        }
        dep = _np_trimr(dy, plag + 1, 0)
        xw  = (_np_trimr(ly, plag + 1, 0), _np_trimr(xw, plag + 1, 0))
        if (plag > 0) {
            xw = (xw, _np_trimr(lmat[., 1::plag], plag + 1, 0))
        }
        xiw = luinv(cross(xw, xw))
        if (missing(xiw[1, 1]) == 0) {
            bw   = xiw * cross(xw, dep)
            ew   = dep - xw * bw
            bgpv = _np_bgminp(ew, xw, bglags, bgdf)
        }
    }

    // Critical values, Narayan & Popp (2010, Table 3); T = full sample size
    if (model == 1) {
        if (t <= 50) {
            cv = (-5.259, -4.514, -4.143)
        }
        else if (t <= 200) {
            cv = (-4.958, -4.316, -3.980)
        }
        else if (t <= 400) {
            cv = (-4.731, -4.136, -3.825)
        }
        else {
            cv = (-4.672, -4.081, -3.772)
        }
    }
    else {
        if (t <= 50) {
            cv = (-5.949, -5.181, -4.789)
        }
        else if (t <= 200) {
            cv = (-5.576, -4.937, -4.596)
        }
        else if (t <= 400) {
            cv = (-5.318, -4.741, -4.430)
        }
        else {
            cv = (-5.287, -4.692, -4.396)
        }
    }

    st_numscalar(s_tstat, admin)
    st_numscalar(s_tb1, tb1m)
    st_numscalar(s_tb2, tb2m)
    st_numscalar(s_lags, optlag - 1)
    st_numscalar(s_cv1, cv[1])
    st_numscalar(s_cv5, cv[2])
    st_numscalar(s_cv10, cv[3])
    st_numscalar(s_n, t)
    st_numscalar(s_f1, tb1m / t)
    st_numscalar(s_f2, tb2m / t)
    st_numscalar(s_tv1, tv[tb1m])
    st_numscalar(s_tv2, tv[tb2m])
    st_numscalar(s_dp, dpm)
    st_numscalar(s_bgp, bgpv)
    st_numscalar(s_fst, fstat)
}
end
