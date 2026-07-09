*! ckptest 1.0.0  07jul2026
*! GLS-based unit root tests with multiple structural breaks
*! Carrion-i-Silvestre, Kim, and Perron (2009, Econometric Theory 25, 1754-1792)
*! Line-by-line Stata/Mata port of the original GAUSS code msbur.src by
*! Josep Lluis Carrion-i-Silvestre (based on Ng and Perron 2001 code),
*! last GAUSS modification July 1st 2006, distributed with CKP (2009).
*! Both estimation paths of the source are implemented:
*!   method(dp)    = sbur_multiple_gls_algorithm (estimation = 1, default)
*!   method(brute) = sbur_multiple_gls_brute     (estimation = 0)
*! Single documented deviation from the source: in the unknown-break brute
*! search min_ssra is initialized with maxdouble() instead of y'y; this is
*! outcome-identical whenever the GAUSS code runs and avoids its singular
*! matrix crash on strongly stationary series (see the Mata comment).
*! Author of the Stata port: Ozan Eruygur, AHBV University
*! GAUSS-to-Mata primitive mapping used throughout:
*!   inv()    -> luinv()      (GAUSS general LU inverse)
*!   invpd()  -> cholinv()    (GAUSS positive definite inverse)
*!   olsqr2() -> qrsolve()    (GAUSS QR least squares)
*!   y/x      -> qrsolve(x,y) (GAUSS matrix division, least squares)
*!   minc/minindc -> min with first-occurrence index helper
*! Option defaults follow the author-distributed usage and tspdlib control
*! structure: model(break), penalty(maic), kmax(4), kmin(0), method(dp),
*! maxiter(100).

program define ckptest, rclass
    version 14.0
    syntax varname(ts) [if] [in] [, Model(string) Breaks(integer 1) BREAKDates(string) METHod(string) MAXiter(integer 100) Penalty(string) KMax(integer 4) KMin(integer 0) noPRint noPREtest PRETESTAll BG BGLags(integer 0) BGDf(integer 20) ]

    local dispname `varlist'

    * ---- model option: 0 const / 1 trend / 2 slope / 3 level+slope ----
    if "`model'" == "" local model "break"
    local model = lower("`model'")
    if inlist("`model'", "0", "const", "constant") local mnum 0
    else if inlist("`model'", "1", "trend") local mnum 1
    else if inlist("`model'", "2", "slope") local mnum 2
    else if inlist("`model'", "3", "break", "both", "mixed") local mnum 3
    else {
        di as err "model() must be one of: {bf:const} (0, constant, no breaks), {bf:trend} (1, linear trend, no breaks), {bf:slope} (2, breaks in the trend slope) or {bf:break} (3, breaks in level and slope)"
        exit 198
    }

    * ---- penalty option: 0 maic / 1 bic (GAUSS input penalty) ----
    if "`penalty'" == "" local penalty "maic"
    local penalty = lower("`penalty'")
    if inlist("`penalty'", "maic", "0") local pen 0
    else if inlist("`penalty'", "bic", "1") local pen 1
    else {
        di as err "penalty() must be {bf:maic} or {bf:bic}"
        exit 198
    }

    * ---- method option: 1 dp (default) / 0 brute (GAUSS input estimation) ----
    if "`method'" == "" local method "dp"
    local method = lower("`method'")
    if inlist("`method'", "brute", "bruteforce", "0") local est 0
    else if inlist("`method'", "dp", "algorithm", "algo", "dynamic", "1") local est 1
    else {
        di as err "method() must be {bf:dp} (dynamic programming, GAUSS estimation=1, the default) or {bf:brute} (grid search, GAUSS estimation=0)"
        exit 198
    }
    if `maxiter' < 1 {
        di as err "maxiter() must be a positive integer"
        exit 198
    }
    if `kmin' < 0 | `kmax' < `kmin' {
        di as err "require 0 <= kmin() <= kmax()"
        exit 198
    }

    * ---- sample checks (wrapper-level validation, not part of the GAUSS algorithm) ----
    capture qui tsset
    if _rc {
        di as err "data must be {helpb tsset} with a time variable"
        exit 459
    }
    if "`r(panelvar)'" != "" {
        di as err "ckptest works on a single time series; data are xtset with panel variable {bf:`r(panelvar)'}"
        exit 459
    }
    local tvar "`r(timevar)'"
    marksample touse
    * resolve time-series operators (D. L. F. S.) into a temporary plain variable
    tsrevar `varlist'
    local yv `r(varlist)'
    markout `touse' `yv'
    qui tsreport if `touse'
    if r(N_gaps) > 0 {
        di as err "the estimation sample contains `r(N_gaps)' gap(s) in `tvar'; unit-root tests require a contiguous series"
        exit 498
    }
    qui count if `touse'
    local T = r(N)
    if `T' < `kmax' + 25 {
        di as err "insufficient observations (T=`T')"
        exit 2001
    }

    * ---- break setup: known dates (model[2]=0) or unknown count (model[2]=1) ----
    local known 0
    local m = `breaks'
    tempvar pos
    qui gen long `pos' = sum(`touse')
    tempname TB
    if `mnum' >= 2 {
        if "`breakdates'" != "" {
            local known 1
            local m : word count `breakdates'
            if `m' > 5 {
                di as err "the procedure is designed for up to m <= 5 structural breaks"
                exit 198
            }
            matrix `TB' = J(`m', 1, .)
            local tfmt : format `tvar'
            local i 0
            local prev = -1e300
            foreach tok of local breakdates {
                local ++i
                capture local d = `tok'
                if _rc | missing(`"`d'"') {
                    if strpos("`tfmt'", "tq") local d = quarterly("`tok'", "YQ")
                    else if strpos("`tfmt'", "tm") local d = monthly("`tok'", "YM")
                    else if strpos("`tfmt'", "th") local d = halfyearly("`tok'", "YH")
                    else if strpos("`tfmt'", "tw") local d = weekly("`tok'", "YW")
                    else if strpos("`tfmt'", "td") local d = daily("`tok'", "DMY")
                    else local d = .
                }
                if missing(`d') {
                    di as err "breakdates(): could not interpret `tok' as a value of `tvar' or an observation number"
                    exit 198
                }
                * interpretation order: (1) a value of the time variable within the
                * sample; (2) otherwise an integer observation number 1..T (position
                * within the estimation sample). For t = 1..T the two coincide.
                local posval = .
                qui su `pos' if `touse' & float(`tvar') == float(`d'), meanonly
                if r(N) > 0 local posval = r(min)
                else if `d' == int(`d') & `d' >= 1 & `d' <= `T' local posval = `d'
                if missing(`posval') {
                    di as err "breakdates(): `tok' is neither a value of `tvar' in the sample nor an observation number between 1 and `T'"
                    exit 198
                }
                if `posval' <= `prev' {
                    di as err "breakdates() must be strictly increasing"
                    exit 198
                }
                local prev = `posval'
                matrix `TB'[`i', 1] = `posval'
            }
        }
        else {
            if `m' < 1 | `m' > 5 {
                di as err "the procedure is designed for up to m <= 5 structural breaks"
                exit 198
            }
            if `est' == 0 & `m' > 3 {
                di as err "with unknown break dates the brute-force search of the GAUSS source supports breaks(1) to breaks(3) only; use {bf:method(dp)} (the default) for 4 or 5 unknown breaks, or supply known dates via breakdates()"
                exit 198
            }
            if `est' == 1 {
                local h = int(0.10*`T')
                if `h' < 5 | `T' < (`m'+2)*`h' {
                    di as err "sample too short for the dynamic programming (dp) with breaks(`m') and 10 percent trimming"
                    exit 2001
                }
            }
        }
    }
    else {
        local m 0
    }
    if !`known' matrix `TB' = J(1, 1, 0)

    * ---- Perron-Yabu (2009, JBES) pretest for a break in trend ----
    * ---- (run by default; suppressed by the nopretest option) ----
    if "`pretest'" == "" {
        * defaults of qfgls.prg: BIC (criteria=2), eps=0.15, kmax rule;
        * PY model 2 (slope shift) for model(slope), PY model 3 otherwise
        local pym = cond(`mnum' == 2, 2, 3)
        local pycrit 2
        local pyeps = 0.15
        local pyk = int(12*(`T'/100)^0.25)
        if max(int(`pyeps'*`T'), `pyk'+2) > int((1-`pyeps')*`T') {
            di as text "(pretest skipped: insufficient observations)"
            local pretest "nopretest"
        }
    }
    if "`pretest'" == "" {
        tempname PYOUT
        mata: _ckp_py("`yv'", "`touse'", `pym', `pycrit', `pyeps', `pyk', "`PYOUT'")
        local pyexpw = `PYOUT'[1,1]
        local pybp = `PYOUT'[1,2]
        local pycv10 = `PYOUT'[1,3]
        local pycv5 = `PYOUT'[1,4]
        local pycv1 = `PYOUT'[1,5]
        qui su `tvar' if `pos' == `pybp' & `touse', meanonly
        local pybd = r(min)
        local tf2 : format `tvar'
        local pybds = string(`pybd', "`tf2'")
        if "`print'" == "" {
            local pymlab "breaks in the trend slope"
            if `pym' == 3 local pymlab "breaks in level and slope"
            local pystars ""
            if `pyexpw' > `pycv10' local pystars "*"
            if `pyexpw' > `pycv5' local pystars "**"
            if `pyexpw' > `pycv1' local pystars "***"
            di
            di as text "{hline 78}"
            di as text "Pretest for a break in trend (Perron and Yabu 2009, JBES 27, 369-396)"
            di as text "{hline 78}"
            di as text "Variable   : " as result "`dispname'" as text _col(44) "Obs           = " as result %8.0f `T'
            di as text "Model      : " as result "`pymlab'"
            if "`pretestall'" != "" {
                di as text "Lags       : " as result "BIC" as text _col(44) "kmax          = " as result %8.0f `pyk'
                di as text "Trimming   : " as result %4.2f `pyeps' as text _col(44) "Break date    = " as result "`pybds'" as text " (obs `pybp')"
            }
            di as text "{hline 78}"
            di as text "  Exp-W(FS)" as result %14.6f `pyexpw' as text %-4s "`pystars'" as text _col(36) "cv:  10% " as result %6.2f `pycv10' as text "  5% " as result %6.2f `pycv5' as text "  1% " as result %6.2f `pycv1'
            di as text "{hline 78}"
            di as text "H0: no break in the trend function."
            if `pyexpw' > `pycv1' {
                di as text "Conclusion: Reject at the 1% level: evidence of a break in the trend function."
            }
            else if `pyexpw' > `pycv5' {
                di as text "Conclusion: Reject at the 5% level: evidence of a break in the trend function."
            }
            else if `pyexpw' > `pycv10' {
                di as text "Conclusion: Reject at the 10% level: evidence of a break in the trend function."
            }
            else {
                di as text "Conclusion: Do not reject at the 10% level: no evidence of a trend break. With no"
                di as text "break, the break unit root tests can over-reject (CKP 2009, Section 6)."
            }
            di as text "{hline 78}"
        }
    }

    * ---- Breusch-Godfrey setup (mkbg mechanics: zero-filled lagged residuals,
    * ---- no constant, uncentered R2, LM = n*R2 ~ chi2(p)) ----
    if `bgdf' < 0 {
        di as err "bgdf() must be a nonnegative integer"
        exit 198
    }
    local bgsel = ("`bg'" != "")
    if `bglags' < 0 {
        di as err "bglags() must be a positive integer"
        exit 198
    }
    if `bglags' > 0 {
        * explicit horizon: used as given, never capped
        local bgh = `bglags'
    }
    else {
        * automatic horizon: about two years of orders by frequency,
        * capped at 5*floor(4*(T/100)^0.25) as in narayanp
        qui tsset
        local tv `r(timevar)'
        local fmt : format `tv'
        local bgh 2
        if strpos("`fmt'", "%ty") local bgh 2
        if strpos("`fmt'", "%tq") local bgh 8
        if strpos("`fmt'", "%tm") local bgh 24
        if strpos("`fmt'", "%tw") local bgh 52
        if strpos("`fmt'", "%td") local bgh 100
        local bgcap = 5*floor(4*(`T'/100)^0.25)
        if `bgh' > `bgcap' local bgh = `bgcap'
    }
    if `bgh' < 1 local bgh 1
    scalar __ckpbg_sel = `bgsel'
    scalar __ckpbg_h = `bgh'
    scalar __ckpbg_df = `bgdf'

    tempname ST CV TBOUT
    mata: _ckp_main("`yv'", "`touse'", `mnum', `known', "`TB'", `m', `pen', `kmax', `kmin', `est', `maxiter', "`ST'", "`CV'", "`TBOUT'")
    local cbar = r(cbar)
    local krule = r(krule)
    local bgminp = scalar(__ckpbg_minp)
    local bgmino = scalar(__ckpbg_mino)
    local bgwarn = scalar(__ckpbg_warn)
    scalar drop __ckpbg_sel __ckpbg_h __ckpbg_df __ckpbg_minp __ckpbg_mino __ckpbg_warn

    * stats vector order as in the GAUSS retp: pt mpt adf za mza msb mzt
    local pt = `ST'[1,1]
    local mpt = `ST'[1,2]
    local adf = `ST'[1,3]
    local za = `ST'[1,4]
    local mza = `ST'[1,5]
    local msb = `ST'[1,6]
    local mzt = `ST'[1,7]

    * ---- break dates in time units ----
    local bdates ""
    local nbfound = rowsof(`TBOUT')
    if `mnum' >= 2 {
        local tf : format `tvar'
        forvalues i = 1/`nbfound' {
            local bp = `TBOUT'[`i',1]
            qui su `tvar' if `pos' == `bp' & `touse', meanonly
            local bd = r(min)
            local bds = string(`bd', "`tf'")
            local bdates "`bdates' `bds' (`bp')"
        }
    }

    * ---- display ----
    if "`print'" == "" {
        local mlab "constant, no breaks"
        if `mnum' == 1 local mlab "linear trend, no breaks"
        if `mnum' == 2 local mlab "breaks in the trend slope (Model I)"
        if `mnum' == 3 local mlab "breaks in level and slope (Model II)"
        local blab "estimated, brute-force GLS-SSR grid search"
        if `est' == 1 local blab "estimated, dynamic programming (dp)"
        if `known' local blab "known (user supplied)"
        local plab "MAIC"
        if `pen' == 1 local plab "BIC"
        if `bgsel' local plab "BG"
        di
        di as text "{hline 78}"
        di as text "GLS-based unit root tests with multiple structural breaks"
        di as text "Carrion-i-Silvestre, Kim, and Perron (2009, Econometric Theory 25, 1754-1792)"
        di as text "{hline 78}"
        di as text "Variable   : " as result "`dispname'" as text _col(44) "Obs           = " as result %8.0f `T'
        di as text "Model      : " as result "`mlab'"
        if `mnum' >= 2 {
            di as text "Breaks     : " as result "`nbfound'" as text "  `blab'"
            di as text "Break dates: " as result "`bdates'"
        }
        di as text "c-bar      : " as result %8.4f `cbar' as text _col(44) "Lags (`plab')   = " as result %8.0f `krule'
        if `bgminp' < . {
            di as text "BG min p   : " as result %6.4f `bgminp' as text "   (spectral AR residuals, orders 1 to `bgh', df floor `bgdf')"
        }
        else {
            di as text "BG min p   : no order with df >= `bgdf' available (orders 1 to `bgh')"
        }
        di as text "{hline 78}"
        di as text "   Test        Statistic        1%      2.5%        5%       10%"
        di as text "{hline 78}"
        * cv row mapping follows the author's sample.gss: PT,MPT -> critical_pt ; ADF,MZT -> critical_mzt ; ZA,MZA -> critical_mza ; MSB -> critical_msb
        * rows of CV: 1=msb 2=mza 3=mzt 4=pt ; columns: 1% 2.5% 5% 10%
        local names `""PT" "MPT" "ADF" "ZA" "MZA" "MSB" "MZT""'
        local cvrow "4 4 3 2 2 1 3"
        forvalues i = 1/7 {
            local nm : word `i' of `names'
            local cr : word `i' of `cvrow'
            local s = `ST'[1, `i']
            local c1 = `CV'[`cr', 1]
            local c25 = `CV'[`cr', 2]
            local c5 = `CV'[`cr', 3]
            local c10 = `CV'[`cr', 4]
            local st ""
            if `s' < `c1' local st "***"
            else if `s' < `c5' local st "**"
            else if `s' < `c10' local st "*"
            di as text %7s "`nm'" as result %14.3f `s' as text %-4s "`st'" as result %9.3f `c1' %10.3f `c25' %10.3f `c5' %10.3f `c10'
        }
        di as text "{hline 78}"
        di as text "H0: unit root.  * p<0.10, ** p<0.05, *** p<0.01."
        if `bgwarn' {
            di as text "Warning: autocorrelation could not be eliminated with kmax = `kmax' lags;"
            di as text "kmax was used. Consider increasing kmax()."
        }
        if !`bgsel' & `bgminp' < 0.05 {
            di as text "Note: the minimum BG p-value is below 0.05: the spectral AR residuals show"
            di as text "remaining autocorrelation. Consider the {bf:bg} option or a larger kmax()."
        }
        di as text "{hline 78}"
    }

    * ---- saved results ----
    return scalar T = `T'
    return scalar pt = `pt'
    return scalar mpt = `mpt'
    return scalar adf = `adf'
    return scalar za = `za'
    return scalar mza = `mza'
    return scalar msb = `msb'
    return scalar mzt = `mzt'
    return scalar cbar = `cbar'
    return scalar lags = `krule'
    return scalar bgminp = `bgminp'
    return scalar bglags = `bgh'
    return scalar bgdf = `bgdf'
    return scalar nbreaks = cond(`mnum' >= 2, `nbfound', 0)
    return local model "`mnum'"
    return local method = cond(`est' == 1, "dp", "brute")
    return local penalty "`penalty'"
    return local breakdates "`bdates'"
    return local varname "`dispname'"
    if "`pretest'" == "" {
        return scalar pyexpw = `pyexpw'
        return scalar pybreakpos = `pybp'
        return scalar pybreakdate = `pybd'
        return scalar pycv10 = `pycv10'
        return scalar pycv5 = `pycv5'
        return scalar pycv1 = `pycv1'
    }
    return local cmd "ckptest"
    matrix rownames `CV' = MSB MZA MZT PT
    matrix colnames `CV' = cv1 cv2_5 cv5 cv10
    return matrix cv = `CV', copy
    if `mnum' >= 2 {
        return matrix breakpos = `TBOUT', copy
    }
end

mata:
// ===========================================================================
// ckptest Mata library: line-by-line port of msbur.src (CKP 2009 GAUSS code)
// Every function below carries the name of the GAUSS procedure it replicates.
// ===========================================================================

// ---------------------------------------------------------------------------
// GAUSS primitives
// ---------------------------------------------------------------------------

// GAUSS trimr(x,a,b): drop a rows from the top and b rows from the bottom
real matrix _ckp_trimr(real matrix x, real scalar a, real scalar b)
{
    return(x[(a+1)::(rows(x)-b), .])
}

// GAUSS seqa(a,b,n): additive sequence a, a+b, ..., a+(n-1)b (column)
real colvector _ckp_seqa(real scalar a, real scalar b, real scalar n)
{
    return(a :+ b:*(0::(n-1)))
}

// GAUSS lagn(x,n)
real matrix _ckp_lagn(real matrix x, real scalar n)
{
    if (n > 0) {
        return(J(n, cols(x), 0) \ _ckp_trimr(x, 0, n))
    }
    else {
        return(_ckp_trimr(x, abs(n), 0) \ J(abs(n), cols(x), 0))
    }
}

// GAUSS diff(x,k)
real matrix _ckp_diff(real matrix x, real scalar k)
{
    if (k == 0) {
        return(x)
    }
    return(J(k, cols(x), 0) \ (_ckp_trimr(x, k, 0) - _ckp_trimr(_ckp_lagn(x, k), k, 0)))
}

// GAUSS minindc: index of the first occurrence of the column minimum
real scalar _ckp_minindc(real colvector v)
{
    real scalar i, n, w
    w = min(v)
    n = rows(v)
    for (i = 1; i <= n; i++) {
        if (v[i] == w) {
            return(i)
        }
    }
    return(.)
}

// GAUSS olsqr2(y,X): QR least squares; returns coefficients and residuals
void _ckp_olsqr2(real colvector y, real matrix X, real colvector b, real colvector e)
{
    b = qrsolve(X, y)
    e = y - X*b
}

// ---------------------------------------------------------------------------
// GAUSS proc(2)=glsd(y,z,cbar): quasi-GLS detrending
// ---------------------------------------------------------------------------
void _ckp_glsd(real colvector y, real matrix z, real scalar cbar, real colvector yt, real scalar ssr)
{
    real scalar nt, abar
    real colvector ya, bhat, eg
    real matrix za

    nt = rows(y)
    abar = 1 + cbar/nt
    ya = J(nt, 1, 0)
    za = J(nt, cols(z), 0)
    ya[1] = y[1]
    za[1, .] = z[1, .]
    ya[2::nt] = y[2::nt] - abar*y[1::(nt-1)]
    za[2::nt, .] = z[2::nt, .] - abar*z[1::(nt-1), .]
    // GAUSS: bhat=inv(za'za)*za'ya
    bhat = luinv(cross(za, za))*cross(za, ya)
    yt = y - z*bhat
    eg = ya - za*bhat
    ssr = cross(eg, eg)
}

// ---------------------------------------------------------------------------
// GAUSS proc(2)=olsd(y,z): OLS detrending, only the residual vector is used
// downstream (krule=s2ar(yt_ols,...))
// ---------------------------------------------------------------------------
real colvector _ckp_olsd(real colvector y, real matrix z)
{
    real colvector ahat, yd
    _ckp_olsqr2(y, z, ahat, yd)
    return(yd)
}

// ---------------------------------------------------------------------------
// GAUSS proc(1)=s2ar(yts,penalty,kmax,kmin): lag choice for the long-run
// variance (MAIC penalty=0, BIC penalty=1)
// ---------------------------------------------------------------------------
real scalar _ckp_s2ar(real colvector yts, real scalar penalty, real scalar kmax, real scalar kmin)
{
    real scalar nt, nef, k, i, kopt, sumy
    real colvector dyts, dyts0, b, e, s2e, tau, mic, kk
    real matrix reg, reg0

    nt = rows(yts)
    tau = J(kmax+1, 1, 0)
    s2e = 999*J(kmax+1, 1, 1)

    dyts = _ckp_diff(yts, 1)
    reg = _ckp_lagn(yts, 1)

    i = 1
    while (i <= kmax) {
        reg = reg, _ckp_lagn(dyts, i)
        i = i + 1
    }

    dyts0 = _ckp_trimr(dyts, kmax+1, 0)
    reg0 = _ckp_trimr(reg, kmax+1, 0)
    sumy = sum(reg0[., 1]:*reg0[., 1])
    nef = nt - kmax - 1

    k = kmin
    while (k <= kmax) {
        // GAUSS: b=dyts0/reg0[.,1:k+1] (matrix division = least squares)
        b = qrsolve(reg0[., 1::(k+1)], dyts0)
        e = dyts0 - reg0[., 1::(k+1)]*b
        s2e[k+1] = cross(e, e)/nef
        tau[k+1] = (b[1]*b[1])*sumy/s2e[k+1]
        k = k + 1
    }

    kk = _ckp_seqa(0, 1, kmax+1)

    if (penalty == 0) {
        mic = ln(s2e) + 2.0:*(kk + tau):/nef
    }
    else {
        mic = ln(s2e) + ln(nef):*kk:/nef
    }

    kopt = _ckp_minindc(mic) - 1
    return(kopt)
}

// ---------------------------------------------------------------------------
// GAUSS proc(3)=adfp(yt,kstar): ADF regression on the detrended series
// returns (adf, rho[1]+1, s2vec)
// ---------------------------------------------------------------------------
void _ckp_adfp(real colvector yt, real scalar kstar, real scalar adf, real scalar a1, real scalar s2vec)
{
    real scalar i, nef, s2e, sre, sumb
    real colvector dyt, rho, ee
    real matrix reg, xx

    reg = _ckp_lagn(yt, 1)
    dyt = _ckp_diff(yt, 1)

    i = 1
    while (i <= kstar) {
        reg = reg, _ckp_lagn(dyt, i)
        i = i + 1
    }

    dyt = _ckp_trimr(dyt, kstar+1, 0)
    reg = _ckp_trimr(reg, kstar+1, 0)

    _ckp_olsqr2(dyt, reg, rho, ee)

    nef = rows(dyt)
    s2e = cross(ee, ee)/nef
    // GAUSS: xx=inv(reg'reg)
    xx = luinv(cross(reg, reg))
    sre = xx[1, 1]*s2e
    adf = rho[1]/sqrt(sre)

    if (kstar > 0) {
        sumb = sum(rho[2::(kstar+1)])
    }
    else {
        sumb = 0
    }

    s2vec = s2e/(1 - sumb)^2
    a1 = rho[1] + 1
}

// ---------------------------------------------------------------------------
// GAUSS proc(1)=c_bar_rs(lam): response surface for the c_bar parameter,
// (5x1) vector of break fractions; regressor order exactly as in the source:
// 1, lam1..lam5, lam^2, lam^3, lam^4, |lami-lamj| (pairs (1,2)(1,3)(1,4)(1,5)
// (2,3)(2,4)(2,5)(3,4)(3,5)(4,5)), then the same pairs squared, cubed, ^4
// ---------------------------------------------------------------------------
real scalar _ckp_cbar_rs(real colvector lam)
{
    real rowvector x
    real colvector prm
    real scalar i, j, idx

    x = J(1, 61, .)
    x[1] = 1
    for (i = 1; i <= 5; i++) {
        x[1+i] = lam[i]
        x[6+i] = lam[i]^2
        x[11+i] = lam[i]^3
        x[16+i] = lam[i]^4
    }
    idx = 21
    for (i = 1; i <= 4; i++) {
        for (j = i+1; j <= 5; j++) {
            idx = idx + 1
            x[idx] = abs(lam[i] - lam[j])
            x[idx+10] = abs(lam[i] - lam[j])^2
            x[idx+20] = abs(lam[i] - lam[j])^3
            x[idx+30] = abs(lam[i] - lam[j])^4
        }
    }
    prm = (-13.12832 \ -36.53045 \ 0 \ 20.2423 \ -4.596202 \ -10.31678 \
        115.2092 \ -29.18712 \ -68.36453 \ 5.873121 \ 0 \ -130.337 \
        74.64396 \ 85.48737 \ 0 \ 0 \ 51.98117 \ -53.03452 \
        -36.27221 \ 0 \ 11.27727 \ -23.39517 \ -5.360149 \ 23.99683 \
        4.788676 \ -27.10002 \ -35.78388 \ 51.12371 \ -29.8518 \ -3.069174 \
        -37.45898 \ 64.95842 \ 5.825729 \ -88.78176 \ -11.54197 \ 83.48645 \
        125.2349 \ -173.1259 \ 80.95821 \ 2.863782 \ 118.2829 \ -80.1287 \
        0 \ 128.872 \ 6.387147 \ -118.1043 \ -199.0615 \ 247.6469 \
        -98.05947 \ 0 \ -160.5713 \ 38.52177 \ 0 \ -65.21576 \
        0 \ 62.86494 \ 117.9976 \ -127.5544 \ 46.2304 \ 0 \
        79.1693)
    return(x*prm)
}

// ---------------------------------------------------------------------------
// GAUSS proc(4)=msbur_rs(lam,c_bar): response surfaces for the critical
// values; returns a 4x4 matrix, rows MSB / MZA / MZT / PT, columns
// 1% / 2.5% / 5% / 10% (exactly the four levels of the source).
// Regressor order exactly as in the source: 1, lam, lam^2, c_bar, lam*c_bar,
// c_bar^2, lam*c_bar^2, |di-dj|*c_bar, |di-dj|^2*c_bar, ^3*c_bar, ^4*c_bar
// ---------------------------------------------------------------------------
real matrix _ckp_msbur_rs(real colvector lam, real scalar cbar)
{
    real rowvector x, critical
    real matrix P
    real scalar i, j, idx, d

    x = J(1, 63, .)
    x[1] = 1
    for (i = 1; i <= 5; i++) {
        x[1+i] = lam[i]
        x[6+i] = lam[i]^2
        x[12+i] = lam[i]*cbar
        x[18+i] = lam[i]*cbar^2
    }
    x[12] = cbar
    x[18] = cbar^2
    idx = 23
    for (i = 1; i <= 4; i++) {
        for (j = i+1; j <= 5; j++) {
            idx = idx + 1
            d = abs(lam[i] - lam[j])
            x[idx] = d*cbar
            x[idx+10] = d^2*cbar
            x[idx+20] = d^3*cbar
            x[idx+30] = d^4*cbar
        }
    }
    P = _ckp_cvparam()
    critical = x*P
    // GAUSS: critical_msb=critical[1:4]; _mza=[5:8]; _mzt=[9:12]; _pt=[13:16]
    return((critical[1], critical[2], critical[3], critical[4] \ critical[5], critical[6], critical[7], critical[8] \ critical[9], critical[10], critical[11], critical[12] \ critical[13], critical[14], critical[15], critical[16]))
}

real matrix _ckp_cvparam()
{
    real matrix P

    P = J(63, 16, 0)
    P[1,.] = (0.206065483, 0.247173646, 0.279911696, 0.311573002, -26.31391813, -20.61149374, -12.1438623, -6.08490852, -2.52133657, -1.766570893, -1.46435731, -1.277987954, -3.518835863, -3.305558261, -3.454833615, -3.240058047)
    P[2,.] = (-0.131592168, -0.083176707, -0.079273217, -0.136364352, -129.5317914, -84.29286654, -36.47970616, -31.60984523, -6.668037145, -3.349004828, -3.066463141, -3.217982311, -15.69764073, -15.89838295, -10.46560768, -18.14173976)
    P[3,.] = (-0.018230144, 0, 0, 0, -3.503797177, 0, 0, 0, -0.193154126, 0, 0, 0, 2.698367477, 0, 0, 3.094894401)
    P[4,.] = (-0.001829617, 0, 0.036867994, 0, 0, 0, 31.56762014, 13.63038899, 0, 0, 1.32634005, 0.633301965, 6.412055579, 0, 5.223542808, 4.405653332)
    P[5,.] = (-0.071694008, -0.069876819, -0.098386033, -0.063992057, -22.82788603, -13.10518388, -39.87684614, -23.51617143, -2.651936734, -1.893827718, -2.317691146, -1.235047933, -10.32717062, -1.986102341, -8.649758634, -1.987760716)
    P[6,.] = (-0.113224418, -0.123618939, -0.114531349, -0.171308084, -71.88919188, -56.62886058, -22.2258743, -45.74522263, -4.308941432, -3.028641495, -2.666831955, -3.513398467, -5.232680619, -13.76324196, -6.17789082, -12.35876925)
    P[7,.] = (0.045497638, 0.034139777, 0.033789576, 0.055316264, 47.47172982, 32.22798967, 18.27175882, 11.56516258, 2.242409839, 1.205414124, 1.172595231, 1.065619758, 4.664094355, 5.198014133, 4.311973301, 6.869459093)
    P[8,.] = (0.005667139, 0.007183722, 0.014895671, 0.00832245, 0, 5.942060926, 8.371062059, 6.269767228, 0, 0.307559368, 0.499975826, 0.381693852, 0, 0, 1.28702057, 0)
    P[9,.] = (0, 0, 0, 0.007275262, 0, 0, 0, 0, -0.085060207, 0, 0, 0.194838181, 0, 0, 0, 0)
    P[10,.] = (0.011393725, 0, 0.006925649, 0.007101886, 14.70004959, 11.44618918, 8.81485526, 8.184740859, 0.87936997, 0.56718476, 0.473032483, 0.402464154, 1.183189107, 1.643475816, 0, 1.791921929)
    P[11,.] = (0.041416456, 0.037458345, 0.036987117, 0.053884486, 37.54355821, 29.58007215, 20.19100032, 26.06901605, 2.110275336, 1.487278396, 1.44212234, 1.676575305, 4.970060977, 6.400077634, 6.119151722, 6.360822366)
    P[12,.] = (0.006744983, 0.009229194, 0.01117728, 0.012830135, 0, 0, 0.383835339, 0.85365241, 0.114546234, 0.141951363, 0.144171363, 0.139480635, -0.544592947, -0.53171116, -0.666577377, -0.74225554)
    P[13,.] = (-0.008881686, -0.005163807, -0.00419873, -0.007623439, -8.508298137, -5.471425562, -1.873513518, -2.233163794, -0.457380818, -0.223355446, -0.186935755, -0.219966762, -1.116029433, -1.044782065, -0.624407428, -1.106702061)
    P[14,.] = (-0.000477302, 0.001411259, 0.001490823, 0.000992921, 0, 0.821678805, 0.839344685, 0.693315109, 0, 0.040353055, 0.049102085, 0.044657513, 0.3017767, 0.013704832, 0.128412682, 0.273588757)
    P[15,.] = (0, 0, 0.003166102, 0.000383907, 0.315654917, 0.353092298, 2.84583848, 1.121511646, 0, 0.017148054, 0.120078208, 0.072095127, 0.636962573, 0.022144415, 0.523175329, 0.412172316)
    P[16,.] = (-0.004879334, -0.005905712, -0.007875096, -0.005118819, -0.270010842, 0, -2.545569579, -1.407264853, -0.12770179, -0.112106002, -0.155499347, -0.077321047, -0.756479306, 0, -0.693933651, 0)
    P[17,.] = (-0.005109823, -0.006312857, -0.005745887, -0.008799213, -2.346920289, -1.877066153, 0, -1.439270423, -0.15405538, -0.106423683, -0.083556342, -0.135095954, 0, -0.587410296, 0, -0.447876179)
    P[18,.] = (0.000147113, 0.000180001, 0.000216343, 0.000261777, 0.010036211, 0, 0, 0.019804635, 0.003272583, 0.002943926, 0.002822847, 0.003038937, 0, 0.004379253, 0, 0)
    P[19,.] = (-0.00018911, -0.000109989, -7.2476e-05, -0.000130686, -0.180808958, -0.117234577, -0.036217559, -0.050234142, -0.009870463, -0.004857975, -0.003790936, -0.00464363, -0.023994328, -0.021043324, -0.012868843, -0.021946248)
    P[20,.] = (0, 4.98993e-05, 3.87592e-05, 2.10757e-05, 0, 0.023326443, 0.022083426, 0.01757633, 0, 0.001151668, 0.001220296, 0.001083382, 0.007411666, 0, 0.003373215, 0.005094191)
    P[21,.] = (0, 0, 6.56928e-05, 0, 0.012434324, 0.014488305, 0.063997488, 0.02118732, 0, 0.000643625, 0.002670921, 0.001514238, 0.014861192, 0, 0.01257116, 0.009431941)
    P[22,.] = (-0.000101491, -0.000129658, -0.000170948, -0.000117271, 0, 0, -0.053703036, -0.033337638, -0.002353799, -0.002482217, -0.003375858, -0.001867064, -0.016239629, 0, -0.014642206, 0)
    P[23,.] = (-9.12367e-05, -0.000115959, -0.000107388, -0.000164942, -0.042581947, -0.034973534, 0, -0.028709714, -0.002863078, -0.002011657, -0.001581567, -0.002664683, 0, -0.01272247, -0.000903779, -0.009291186)
    P[24,.] = (0.001502737, 0.001632669, 0.001702841, 0.002021723, 1.632727956, 1.605877644, 1.004404184, 0.868853384, 0.083333993, 0.079478462, 0.065367552, 0.063715851, 0.310198878, 0.360029916, 0.330191659, 0.381965256)
    P[25,.] = (0, 0, 0, 0.001328702, 0, 0, 0.202483643, 0.620890565, 0.006479305, 0, 0.006933813, 0.032275901, 0, 0.134517084, 0, 0)
    P[26,.] = (0, 0, 0, 0, -0.192709346, 0, 0, 0.36221429, -0.021488357, 0, -0.001200112, 0.011828416, 0, 0.099982238, 0.103069901, 0.084964524)
    P[27,.] = (0.000680309, 0, 0.000414141, 0, 0.499555624, 0, 0.269613377, 0.236974663, 0.040862054, 0.022834275, 0.016456528, 0.017878489, 0.127583576, 0, 0.129658797, 0.079531443)
    P[28,.] = (0.001076323, 0.000746542, 0.001534534, 0.001854214, 1.222722601, 0.980994239, 0.952309602, 0.981692971, 0.06103088, 0.048322535, 0.062848187, 0.068704135, 0.34819102, 0.351457151, 0.285248474, 0.389323838)
    P[29,.] = (0.001602307, 0.001718432, 0.000513486, 0.001320012, 1.284000309, 0.790608102, 0.29128284, 0.192243305, 0.073187675, 0.037307962, 0.015603486, 0.008831525, 0, 0.161831707, 0.161667434, 0)
    P[30,.] = (-3.13393e-05, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.178056784)
    P[31,.] = (0.000915733, 0.000465616, 0.000828461, 0.0015141, 0.895732659, 0.635112942, 0.357984838, 0.70758854, 0.051259672, 0.033026078, 0.039391705, 0.054005928, 0.114186355, 0.272130694, 0.173459972, 0.236092255)
    P[32,.] = (0.001297134, 0.001989702, 0.001648169, 0.000516108, 1.486377973, 1.448576409, 1.438138712, 0.44934008, 0.06084729, 0.063368696, 0.060177344, 0.023938672, 0.184586257, 0.01941423, 0.270773963, 0.306240705)
    P[33,.] = (0.000779578, 0.000538182, 0.001171215, 0.001602482, 0.553062822, 0.350422194, 0.468555532, 0.425359716, 0.03353265, 0.028507047, 0.042001183, 0.043941342, 0.138176188, 0.167194529, 0.177010468, 0.210812736)
    P[34,.] = (-0.004345646, -0.005825265, -0.006868541, -0.00796319, -4.479282599, -4.8858522, -3.136191913, -2.458114748, -0.231523802, -0.248286094, -0.213133815, -0.194637365, -0.922468402, -0.985366571, -0.923999903, -1.130047)
    P[35,.] = (0, 0, -5.04974e-05, -0.004738169, 0, 0, -0.403826354, -1.909565827, -0.009229909, 0, -0.008242746, -0.098804196, 0, -0.507406066, 0, -0.021572133)
    P[36,.] = (0, 0, 0, -5.05847e-05, 0, 0, -0.417036823, -1.119339897, 0.043558418, 0, 0, -0.02166457, 0, -0.454778552, -0.405307294, -0.332490735)
    P[37,.] = (-0.004679147, -0.002222758, -0.004695542, -0.003025465, -3.000000235, -0.964674073, -1.860955551, -1.416293256, -0.208817124, -0.134046896, -0.136841302, -0.125359252, -0.631341206, 0, -0.587433653, -0.487244954)
    P[38,.] = (-0.002164419, -0.001967051, -0.005817976, -0.006214813, -2.092813644, -1.850008801, -2.941485078, -2.857336306, -0.104657956, -0.097680824, -0.195504402, -0.201534614, -1.128138371, -0.979191193, -0.703716053, -1.028065809)
    P[39,.] = (-0.005484897, -0.006163019, -0.00124581, -0.004023965, -4.057652598, -2.738110318, -0.61059659, -0.332618017, -0.222016788, -0.126749269, -0.030055771, -0.009635946, 0, -0.599177023, -0.584313329, 0)
    P[40,.] = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.089011851, 0.124842286, 0, -0.508722695)
    P[41,.] = (-0.00165207, -0.001163458, -0.003198713, -0.005190305, -1.276113948, -0.889271056, -0.747636053, -1.839058302, -0.069225581, -0.055577102, -0.112927132, -0.159646685, -0.154761007, -0.597212331, -0.288535459, -0.379766195)
    P[42,.] = (-0.003789148, -0.0064054, -0.004817945, -0.000649124, -4.496633229, -4.594051759, -4.597029802, -0.694146329, -0.167498301, -0.194612003, -0.171395671, -0.037729237, -0.67125797, 0, -0.997655245, -1.102797825)
    P[43,.] = (-0.001096697, -0.000571708, -0.00416902, -0.004537825, 0, 0, -1.150001536, -0.397475842, 0, -0.036557664, -0.117430944, -0.100061587, -0.189720447, -0.156458132, -0.171258066, -0.367949029)
    P[44,.] = (0.004725461, 0.008280992, 0.010451449, 0.011883757, 4.700545573, 6.27119741, 4.178380993, 3.094835252, 0.247801364, 0.322844187, 0.291165672, 0.255602766, 1.114026174, 1.079445866, 1.116574652, 1.435226881)
    P[45,.] = (0, 0, 0, 0.006868754, -0.046355934, 0, 0.220249151, 2.5334366, 0, 0, 0, 0.133924549, 0, 0.776781333, 0, 0.023477765)
    P[46,.] = (0, 0, 0, 0, 0.811913273, 0, 0.998239994, 1.47110097, -0.023485383, 0, 0, 0.010896637, 0, 0.75874924, 0.657353781, 0.52514633)
    P[47,.] = (0.009039167, 0.005334347, 0.009880517, 0.007579264, 5.503001956, 2.327899451, 3.493280873, 2.574956682, 0.361357325, 0.240732181, 0.272754543, 0.241334704, 1.095018463, 0, 0.92651935, 0.916080571)
    P[48,.] = (0.001237718, 0.001401401, 0.008484588, 0.008416308, 1.02572597, 1.046754093, 3.967072173, 3.760263385, 0.052317695, 0.060133444, 0.261308977, 0.263752707, 1.565059276, 1.23081264, 0.745421462, 1.252746367)
    P[49,.] = (0.008139359, 0.009159069, 0.000918836, 0.005481258, 5.865893641, 4.234610015, 0.400719375, 0.166727218, 0.311141107, 0.193402656, 0.018125688, 0, 0, 0.979632255, 0.860652087, 0)
    P[50,.] = (0, -5.0721e-05, 0, -4.79068e-05, -0.038957002, 0, 0, -0.024479515, -0.002278556, 0, 0, -0.001680802, -0.216616021, -0.359131022, 0, 0.639272615)
    P[51,.] = (0.000809364, 0.000809675, 0.004538856, 0.007550505, 0, 0, 0.474813133, 2.435657851, 0, 0.0278107, 0.141916393, 0.221121513, 0, 0.592286581, 0.142276904, 0.175199011)
    P[52,.] = (0.004893033, 0.00886491, 0.006136727, 0, 6.088534864, 6.377018844, 6.286955077, 0.283095346, 0.216868391, 0.263466015, 0.214566444, 0.01661417, 1.025111042, 0, 1.492001945, 1.627703373)
    P[53,.] = (0.000352955, 0, 0.005980789, 0.005904448, -1.299540015, -0.727894226, 1.347458203, 0, -0.07801745, 0.011508158, 0.152800184, 0.120073816, 0.059252271, 0, 0, 0.316314136)
    P[54,.] = (-0.00179525, -0.004086714, -0.005417723, -0.006105744, -1.709027953, -2.961023806, -2.016300404, -1.471404534, -0.092721304, -0.151065777, -0.142110387, -0.122864487, -0.497264715, -0.42244023, -0.500157415, -0.683828054)
    P[55,.] = (-0.000109346, -5.35444e-05, 0, -0.003596853, 0, 0, 0, -1.260438948, 0, 0, 0, -0.069784359, -0.009288362, -0.426512724, 0, 0)
    P[56,.] = (0, 0, -5.57416e-05, 0, -0.674459313, 0, -0.621350492, -0.713530106, 0, 0, 0, 0, 0, -0.427537109, -0.374390888, -0.288974182)
    P[57,.] = (-0.005138561, -0.003190206, -0.00580564, -0.004742335, -3.034884695, -1.395732499, -1.970609696, -1.436365327, -0.195891984, -0.132984979, -0.157536611, -0.138135224, -0.602410686, -0.011191895, -0.488796736, -0.530722743)
    P[58,.] = (0, 0, -0.004283777, -0.004053352, 0, 0, -1.984788663, -1.891122229, 0, 0, -0.126796139, -0.128361041, -0.785227631, -0.594785802, -0.300198458, -0.603224179)
    P[59,.] = (-0.004463549, -0.004931673, 0, -0.002862951, -3.272972482, -2.462761762, 0, 0, -0.170881185, -0.111894795, 0, 0, -0.010121395, -0.588066534, -0.443113015, 0)
    P[60,.] = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.132384584, 0.271088476, 0, -0.311195596)
    P[61,.] = (0, 0, -0.002139895, -0.003923755, 0.528575644, 0.366450912, 0, -1.31877996, 0.026385386, 0, -0.064682374, -0.114348818, 0.067265656, -0.247275032, 0, 0)
    P[62,.] = (-0.00241816, -0.004474527, -0.00297588, 0.00023128, -3.169547182, -3.321085197, -3.169497865, 0, -0.1144538, -0.135673769, -0.103644277, 0, -0.570723203, -0.03959037, -0.788709363, -0.849343883)
    P[63,.] = (0, 0, -0.002984229, -0.002989047, 0.798089652, 0.412611617, -0.64630145, 0, 0.048845232, 0, -0.074881653, -0.061526855, 0, 0, 0, -0.147843764)
    return(P)
}

// ---------------------------------------------------------------------------
// Deterministic regressor matrix for models 2 and 3, column order exactly as
// in the GAUSS source: cns ~ tend ~ [du1 ~] dt1 ~ [du2 ~] dt2 ~ ...
// (model 3 interleaves du_j and dt_j per break; model 2 has only dt_j)
// ---------------------------------------------------------------------------
real matrix _ckp_zbuild(real scalar nt, real scalar model1, real colvector tb)
{
    real matrix z
    real colvector du, dt
    real scalar j, m

    z = J(nt, 1, 1), _ckp_seqa(1, 1, nt)
    m = rows(tb)
    for (j = 1; j <= m; j++) {
        dt = J(tb[j], 1, 0) \ _ckp_seqa(1, 1, nt-tb[j])
        if (model1 == 3) {
            du = J(tb[j], 1, 0) \ J(nt-tb[j], 1, 1)
            z = z, du, dt
        }
        else {
            z = z, dt
        }
    }
    return(z)
}

// ---------------------------------------------------------------------------
// Common statistics tail, identical in sbur_multiple_gls_brute (lines
// following the break search) and sbur_multiple_gls_algorithm; transcribed
// once and used by both paths.
// ---------------------------------------------------------------------------
void _ckp_tail(real colvector y, real matrix z, real scalar cbar, real scalar model1, real scalar penalty, real scalar kmax, real scalar kmin, real rowvector stats, real scalar krule)
{
    real scalar nt, ssra, s2u, sumyt2, adf, a1, sar, bt, za, mza, msb, mzt, ssr1, pt, mpt, bgwarn, bgminp, bgmino
    real colvector yt, r, yt_ols, ytf
    real scalar ahat_s
    real colvector ahat

    nt = rows(y)

    _ckp_glsd(y, z, cbar, yt, ssra)
    // GAUSS: {ahat,r,fit}=olsqr2(yt[2:nt,1],yt[1:nt-1,1])
    _ckp_olsqr2(yt[2::nt], yt[1::(nt-1)], ahat, r)
    ahat_s = ahat[1]
    s2u = cross(r, r)/(nt-1)
    sumyt2 = sum(yt[1::(nt-1)]:^2)/(nt-1)^2

    yt_ols = _ckp_olsd(y, z)
    if (st_numscalar("__ckpbg_sel") == 1) {
        bgwarn = 0
        krule = _ckp_bgsel(yt, kmax, kmin, st_numscalar("__ckpbg_h"), st_numscalar("__ckpbg_df"), bgwarn)
        st_numscalar("__ckpbg_warn", bgwarn)
    }
    else {
        krule = _ckp_s2ar(yt_ols, penalty, kmax, kmin)
        st_numscalar("__ckpbg_warn", 0)
    }
    _ckp_bgmin(yt, krule, st_numscalar("__ckpbg_h"), st_numscalar("__ckpbg_df"), bgminp, bgmino)
    st_numscalar("__ckpbg_minp", bgminp)
    st_numscalar("__ckpbg_mino", bgmino)
    _ckp_adfp(yt, krule, adf, a1, sar)

    bt = nt - 1
    za = bt*(ahat_s - 1) - (sar - s2u)/(2*sumyt2)
    mza = ((yt[nt]^2)/bt - sar)/(2*sumyt2)
    msb = sqrt(sumyt2/sar)
    mzt = mza*msb

    _ckp_glsd(y, z, 0, ytf, ssr1)
    pt = (ssra - (1 + cbar/nt)*ssr1)/sar

    if (model1 == 0) {
        mpt = (cbar*cbar*sumyt2 - cbar*(yt[nt]^2)/nt)/sar
    }
    else {
        mpt = (cbar*cbar*sumyt2 + (1 - cbar)*(yt[nt]^2)/nt)/sar
    }

    stats = (pt, mpt, adf, za, mza, msb, mzt)
}

// ---------------------------------------------------------------------------
// GAUSS proc(9)=sbur_multiple_gls_brute(y,model,penalty,kmax,kmin)
// ---------------------------------------------------------------------------
void _ckp_brute(real colvector y, real scalar model1, real scalar known, real colvector tbin, real scalar nbrk, real scalar penalty, real scalar kmax, real scalar kmin, real rowvector stats, real colvector min_tb, real scalar cbar, real scalar krule)
{
    real scalar nt, j, jj, jjj, min_ssra, ssra
    real colvector yt, tbc
    real matrix z

    nt = rows(y)
    min_tb = J(1, 1, 0)

    if (model1 == 0) {
        z = J(nt, 1, 1)
        cbar = -7.0
    }
    else if (model1 == 1) {
        z = J(nt, 1, 1), _ckp_seqa(1, 1, nt)
        cbar = -13.5
    }
    else {
        if (known == 1) {
            // GAUSS known-break branch: min_tb = model[3:rows(model)]
            min_tb = tbin
            z = _ckp_zbuild(nt, model1, min_tb)
            if (rows(min_tb) < 5) {
                cbar = _ckp_cbar_rs((min_tb:/nt) \ J(5-rows(min_tb), 1, 0))
            }
            else {
                cbar = _ckp_cbar_rs(min_tb:/nt)
            }
        }
        else {
            // GAUSS unknown-break branch. SINGLE DOCUMENTED DEVIATION from the
            // source: GAUSS initializes min_ssra = y'y, which is not an upper
            // bound of the quasi-differenced SSR for strongly stationary series;
            // in that case no candidate is ever accepted, min_tb stays 0, and the
            // original code crashes on a singular regressor matrix (dt duplicates
            // tend). Initializing with maxdouble() returns the identical argmin
            // whenever the GAUSS code works (the minimizing candidate is then
            // below y'y anyway) and a valid result where the GAUSS code fails.
            min_ssra = maxdouble()
            if (nbrk == 1) {
                j = 3
                while (j <= nt-3) {
                    tbc = (j)
                    z = _ckp_zbuild(nt, model1, tbc)
                    cbar = _ckp_cbar_rs((j/nt) \ 0 \ 0 \ 0 \ 0)
                    _ckp_glsd(y, z, cbar, yt, ssra)
                    if (ssra < min_ssra) {
                        min_tb = tbc
                        min_ssra = ssra
                    }
                    j = j + 1
                }
                z = _ckp_zbuild(nt, model1, min_tb)
                cbar = _ckp_cbar_rs((min_tb[1]/nt) \ 0 \ 0 \ 0 \ 0)
            }
            else if (nbrk == 2) {
                j = 3
                while (j <= nt-3-2) {
                    jj = j + 2
                    while (jj <= nt-3) {
                        tbc = (j \ jj)
                        z = _ckp_zbuild(nt, model1, tbc)
                        cbar = _ckp_cbar_rs((j/nt) \ (jj/nt) \ 0 \ 0 \ 0)
                        _ckp_glsd(y, z, cbar, yt, ssra)
                        if (ssra < min_ssra) {
                            min_tb = tbc
                            min_ssra = ssra
                        }
                        jj = jj + 1
                    }
                    j = j + 1
                }
                z = _ckp_zbuild(nt, model1, min_tb)
                cbar = _ckp_cbar_rs((min_tb[1]/nt) \ (min_tb[2]/nt) \ 0 \ 0 \ 0)
            }
            else {
                j = 3
                while (j <= nt-3-4) {
                    jj = j + 2
                    while (jj <= nt-3-2) {
                        jjj = jj + 2
                        while (jjj <= nt-3) {
                            tbc = (j \ jj \ jjj)
                            z = _ckp_zbuild(nt, model1, tbc)
                            cbar = _ckp_cbar_rs((j/nt) \ (jj/nt) \ (jjj/nt) \ 0 \ 0)
                            _ckp_glsd(y, z, cbar, yt, ssra)
                            if (ssra < min_ssra) {
                                min_tb = tbc
                                min_ssra = ssra
                            }
                            jjj = jjj + 1
                        }
                        jj = jj + 1
                    }
                    j = j + 1
                }
                z = _ckp_zbuild(nt, model1, min_tb)
                cbar = _ckp_cbar_rs((min_tb[1]/nt) \ (min_tb[2]/nt) \ (min_tb[3]/nt) \ 0 \ 0)
            }
        }
    }

    _ckp_tail(y, z, cbar, model1, penalty, kmax, kmin, stats, krule)
}

// ---------------------------------------------------------------------------
// GAUSS proc(1)=ssr(start,y,z,h,last): recursive SSR, OLS detrending stage
// ---------------------------------------------------------------------------
real colvector _ckp_ssr(real scalar start, real colvector y, real matrix z, real scalar h, real scalar last)
{
    real colvector vecssr, delta1, delta2, invz, res
    real matrix inv1, inv2
    real scalar v, f, r

    vecssr = J(last, 1, 0)

    inv1 = luinv(cross(z[start::(start+h-1), .], z[start::(start+h-1), .]))
    delta1 = inv1*cross(z[start::(start+h-1), .], y[start::(start+h-1)])
    res = y[start::(start+h-1)] - z[start::(start+h-1), .]*delta1
    vecssr[start+h-1] = cross(res, res)

    r = start + h
    while (r <= last) {
        v = y[r] - z[r, .]*delta1
        invz = inv1*z[r, .]'
        f = 1 + z[r, .]*invz
        delta2 = delta1 + (invz*v)/f
        inv2 = inv1 - (invz*invz')/f
        inv1 = inv2
        delta1 = delta2
        vecssr[r] = vecssr[r-1] + v*v/f
        r = r + 1
    }

    return(vecssr)
}

// ---------------------------------------------------------------------------
// GAUSS proc(1)=ssr_gls(start,y,z,h,last): recursive SSR, GLS stage, with an
// initial impulse dummy that equals 1 at the first observation of the segment
// ---------------------------------------------------------------------------
real colvector _ckp_ssr_gls(real scalar start, real colvector y, real matrix z, real scalar h, real scalar last)
{
    real colvector vecssr, delta1, delta2, invz, res, initial_impulse
    real matrix inv1, inv2, zb
    real rowvector zr
    real scalar v, f, r

    vecssr = J(last, 1, 0)

    initial_impulse = 1 \ J(rows(z)-1, 1, 0)

    zb = z[start::(start+h-1), .], initial_impulse[1::h]
    inv1 = luinv(cross(zb, zb))
    delta1 = inv1*cross(zb, y[start::(start+h-1)])
    res = y[start::(start+h-1)] - zb*delta1
    vecssr[start+h-1] = cross(res, res)

    r = start + h
    while (r <= last) {
        zr = z[r, .], initial_impulse[r-start+1]
        v = y[r] - zr*delta1
        invz = inv1*zr'
        f = 1 + zr*invz
        delta2 = delta1 + (invz*v)/f
        inv2 = inv1 - (invz*invz')/f
        inv1 = inv2
        delta1 = delta2
        vecssr[r] = vecssr[r-1] + v*v/f
        r = r + 1
    }

    return(vecssr)
}

// ---------------------------------------------------------------------------
// GAUSS proc(2)=parti(start,b1,b2,last,bigvec,bigt)
// ---------------------------------------------------------------------------
void _ckp_parti(real scalar start, real scalar b1, real scalar b2, real scalar last, real colvector bigvec, real scalar bigt, real scalar ssrmin, real scalar dx)
{
    real colvector dvec
    real scalar j, jj, k, ini

    dvec = J(bigt, 1, 0)
    ini = (start-1)*bigt - (start-2)*(start-1)/2 + 1

    j = b1
    while (j <= b2) {
        jj = j - start
        k = j*bigt - (j-1)*j/2 + last - j
        dvec[j] = bigvec[ini+jj] + bigvec[k]
        j = j + 1
    }

    ssrmin = min(dvec[b1::b2])
    dx = (b1-1) + _ckp_minindc(dvec[b1::b2])
}

// ---------------------------------------------------------------------------
// GAUSS proc(3)=dating(y,z,h,m,q,bigt): Bai-Perron dynamic programming, OLS
// stage (the q argument is kept to mirror the GAUSS signature; it is unused
// in the GAUSS body as well)
// ---------------------------------------------------------------------------
void _ckp_dating(real colvector y, real matrix z, real scalar h, real scalar m, real scalar q, real scalar bigt, real colvector glob, real matrix datevec, real colvector bigvec, real scalar glsflag)
{
    real matrix optdat, optssr
    real colvector dvec, vecssr
    real scalar i, ssrmin, datx, j1, ib, jlast, jb, xx

    datevec = J(m, m, 0)
    optdat = J(bigt, m, 0)
    optssr = J(bigt, m, 0)
    dvec = J(bigt, 1, 0)
    glob = J(m, 1, 0)
    bigvec = J(bigt*(bigt+1)/2, 1, 0)

    i = 1
    while (i <= bigt-h+1) {
        if (glsflag == 0) {
            vecssr = _ckp_ssr(i, y, z, h, bigt)
        }
        else {
            vecssr = _ckp_ssr_gls(i, y, z, h, bigt)
        }
        bigvec[((i-1)*bigt+i-(i-1)*i/2)::(i*bigt-(i-1)*i/2)] = vecssr[i::bigt]
        i = i + 1
    }

    if (m == 1) {
        _ckp_parti(1, h, bigt-h, bigt, bigvec, bigt, ssrmin, datx)
        datevec[1, 1] = datx
        glob[1] = ssrmin
    }
    else {
        j1 = 2*h
        while (j1 <= bigt) {
            _ckp_parti(1, h, j1-h, j1, bigvec, bigt, ssrmin, datx)
            optssr[j1, 1] = ssrmin
            optdat[j1, 1] = datx
            j1 = j1 + 1
        }
        glob[1] = optssr[bigt, 1]
        datevec[1, 1] = optdat[bigt, 1]

        ib = 2
        while (ib <= m) {
            if (ib == m) {
                jlast = bigt
                jb = ib*h
                while (jb <= jlast-h) {
                    dvec[jb] = optssr[jb, ib-1] + bigvec[(jb+1)*bigt - jb*(jb+1)/2]
                    jb = jb + 1
                }
                optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                optdat[jlast, ib] = (ib*h-1) + _ckp_minindc(dvec[(ib*h)::(jlast-h)])
            }
            else {
                jlast = (ib+1)*h
                while (jlast <= bigt) {
                    jb = ib*h
                    while (jb <= jlast-h) {
                        dvec[jb] = optssr[jb, ib-1] + bigvec[jb*bigt - jb*(jb-1)/2 + jlast - jb]
                        jb = jb + 1
                    }
                    optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                    optdat[jlast, ib] = (ib*h-1) + _ckp_minindc(dvec[(ib*h)::(jlast-h)])
                    jlast = jlast + 1
                }
            }

            datevec[ib, ib] = optdat[bigt, ib]

            i = 1
            while (i <= ib-1) {
                xx = ib - i
                datevec[xx, ib] = optdat[datevec[xx+1, ib], xx]
                i = i + 1
            }
            glob[ib] = optssr[bigt, ib]

            ib = ib + 1
        }
    }
}

// ---------------------------------------------------------------------------
// GAUSS proc(1)=ssr2_gls(y,z,b,q,br): SSR contributions for all segments
// under estimated (restricted) coefficients b
// ---------------------------------------------------------------------------
real colvector _ckp_ssr2_gls(real colvector y, real matrix z, real colvector b, real scalar q, real colvector br)
{
    real scalar m, i, bigt
    real colvector bigvec2
    real matrix initial_impulse

    m = rows(br)
    bigt = rows(y)
    bigvec2 = J(bigt*(m+1), 1, 0)

    initial_impulse = 1 \ J(bigt-1, 1, 0)
    i = 1
    while (i <= m) {
        initial_impulse = initial_impulse, (J(br[i], 1, 0) \ 1 \ J(bigt-br[i]-1, 1, 0))
        i = i + 1
    }

    i = 1
    while (i <= m+1) {
        bigvec2[((i-1)*bigt+1)::(i*bigt)] = (y - (z, initial_impulse[., i])*b[((i-1)*(q+1)+1)::(i*(q+1))]):^2
        i = i + 1
    }

    return(bigvec2)
}

// ---------------------------------------------------------------------------
// GAUSS proc(2)=parti2(start,b1,b2,last,bigvec2,bigt)
// ---------------------------------------------------------------------------
void _ckp_parti2(real scalar start, real scalar b1, real scalar b2, real scalar last, real colvector bigvec2, real scalar bigt, real scalar ssrmin, real scalar dx)
{
    real colvector dvec
    real scalar j, ssr1, ssr2

    dvec = J(bigt, 1, 0)
    j = b1
    while (j <= b2) {
        ssr1 = sum(bigvec2[start::j])
        ssr2 = sum(bigvec2[(1*bigt+j+1)::(1*bigt+last)])
        dvec[j] = ssr1 + ssr2
        j = j + 1
    }

    ssrmin = min(dvec[b1::b2])
    dx = (b1-1) + _ckp_minindc(dvec[b1::b2])
}

// ---------------------------------------------------------------------------
// GAUSS proc(2)=dating2_gls(bigvec2,h,m,bigt): dynamic programming under the
// restricted coefficient estimates
// ---------------------------------------------------------------------------
void _ckp_dating2_gls(real colvector bigvec2, real scalar h, real scalar m, real scalar bigt, real colvector glob, real matrix datevec)
{
    real matrix optdat, optssr
    real colvector dvec
    real scalar i, ssrmin, datx, j1, ib, jlast, jb, xx

    datevec = J(m, m, 0)
    optdat = J(bigt, m, 0)
    optssr = J(bigt, m, 0)
    dvec = J(bigt, 1, 0)
    glob = J(m, 1, 0)

    if (m == 1) {
        _ckp_parti2(1, h, bigt-h, bigt, bigvec2, bigt, ssrmin, datx)
        datevec[1, 1] = datx
        glob[1] = ssrmin
    }
    else {
        j1 = 2*h
        while (j1 <= bigt) {
            _ckp_parti2(1, h, j1-h, j1, bigvec2[1::(2*bigt)], bigt, ssrmin, datx)
            optssr[j1, 1] = ssrmin
            optdat[j1, 1] = datx
            j1 = j1 + 1
        }

        glob[1] = optssr[bigt, 1]
        datevec[1, 1] = optdat[bigt, 1]

        ib = 2
        while (ib <= m) {
            if (ib == m) {
                jlast = bigt
                jb = ib*h
                while (jb <= jlast-h) {
                    dvec[jb] = optssr[jb, ib-1] + sum(bigvec2[(bigt*m+jb+1)::(bigt*(m+1))])
                    jb = jb + 1
                }
                optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                optdat[jlast, ib] = (ib*h-1) + _ckp_minindc(dvec[(ib*h)::(jlast-h)])
            }
            else {
                jlast = (ib+1)*h
                while (jlast <= bigt) {
                    jb = ib*h
                    while (jb <= jlast-h) {
                        dvec[jb] = optssr[jb, ib-1] + sum(bigvec2[(bigt*ib+jb+1)::(bigt*ib+jlast)])
                        jb = jb + 1
                    }
                    optssr[jlast, ib] = min(dvec[(ib*h)::(jlast-h)])
                    optdat[jlast, ib] = (ib*h-1) + _ckp_minindc(dvec[(ib*h)::(jlast-h)])
                    jlast = jlast + 1
                }
            }

            datevec[ib, ib] = optdat[bigt, ib]

            i = 1
            while (i <= ib-1) {
                xx = ib - i
                datevec[xx, ib] = optdat[datevec[xx+1, ib], xx]
                i = i + 1
            }
            glob[ib] = optssr[bigt, ib]

            ib = ib + 1
        }
    }
}

// ---------------------------------------------------------------------------
// Restriction matrix R for est2_gls, models 2 and 3, exactly as in the source
// ---------------------------------------------------------------------------
real matrix _ckp_est2_R(real scalar model1, real scalar alpha, real colvector brdates, real scalar m)
{
    real matrix R, temp
    real scalar i

    R = (-alpha, 0, 1), J(1, m*3, 0)
    temp = J(m, (m+1)*3, 0)
    i = 1
    while (i <= m) {
        if (model1 == 2) {
            temp[i, (3*i-2)::((i+1)*3)] = (-1, -brdates[i], 0, 1, brdates[i], 0)
        }
        else {
            temp[i, (3*i-2)::((i+1)*3)] = (-1, -brdates[i], 0, 1, brdates[i], -1/alpha)
        }
        i = i + 1
    }
    R = R \ temp
    if (model1 == 2) {
        temp = J(m, (m+1)*3, 0)
        i = 1
        while (i <= m) {
            temp[i, 3*(i+1)] = 1
            i = i + 1
        }
        R = R \ temp
    }
    return(R)
}

// ---------------------------------------------------------------------------
// Block diagonal regressor matrix zbar for est2_gls, exactly as in the source
// ---------------------------------------------------------------------------
real matrix _ckp_est2_zbar(real matrix z, real colvector initial_impulse, real colvector dvm, real scalar q, real scalar m, real scalar bigt)
{
    real matrix zbar, zi
    real scalar i, t1, t2, tbar

    tbar = dvm[1]
    zbar = _ckp_trimr((z, initial_impulse), 0, bigt-tbar) \ J(bigt-tbar, q+1, 0)

    i = 2
    while (i <= m) {
        t1 = dvm[i-1]
        t2 = dvm[i]
        zi = J(t1, q+1, 0) \ (_ckp_trimr(z, t1, bigt-t2), initial_impulse[1::(t2-t1)]) \ J(bigt-t2, q+1, 0)
        zbar = zbar, zi
        i = i + 1
    }

    t2 = dvm[m]
    zi = J(t2, q+1, 0) \ (_ckp_trimr(z, t2, 0), initial_impulse[1::(bigt-t2)])
    zbar = zbar, zi

    return(zbar)
}

// ---------------------------------------------------------------------------
// GAUSS proc(3)=est2_gls(y,model,q,m,bigt,trm,datevec): restricted estimation
// of breaks and coefficients (Perron and Qu 2004 restricted SSR code)
// ---------------------------------------------------------------------------
void _ckp_est2_gls(real colvector y, real scalar model1, real scalar q, real scalar m, real scalar bigt, real scalar trm, real colvector datevec_in, real colvector dx, real colvector delta, real scalar ssr_out)
{
    real scalar h, tstar, c_bar, alpha, count, ssr_iter_prev, rr, repeatflag
    real colvector br, y_gls, cns_gls, tend_gls, initial_impulse, b, e, glob2, bigvec2
    real matrix z, zbar, zz, R, datevec2

    tstar = bigt
    h = round(trm*bigt)

    br = datevec_in

    if (m < 5) {
        c_bar = _ckp_cbar_rs(sort(br:/bigt, 1) \ J(5-m, 1, 0))
    }
    else {
        c_bar = _ckp_cbar_rs(sort(br:/bigt, 1))
    }

    alpha = 1 + c_bar/bigt

    cns_gls = (1-alpha)*J(bigt, 1, 1)
    tend_gls = 1 \ ((-c_bar/bigt)*_ckp_seqa(1, 1, bigt-1) :+ 1)
    z = cns_gls, tend_gls
    y_gls = y[1] \ (y[2::bigt] - alpha*y[1::(bigt-1)])

    initial_impulse = 1 \ J(rows(z)-1, 1, 0)

    zbar = _ckp_est2_zbar(z, initial_impulse, br, q, m, bigt)

    _ckp_olsqr2(y_gls, zbar, b, e)
    // GAUSS: zz=invpd(zbar'zbar)
    zz = cholinv(cross(zbar, zbar))

    R = _ckp_est2_R(model1, alpha, br, m)

    rr = 0

    // GAUSS: delta=b+zz*R'*invpd(R*zz*R')*(rr-R*b)
    delta = b + zz*R'*cholinv(R*zz*R')*(rr :- R*b)

    // iterative estimation procedure (GAUSS goto start_iter loop, max 10)
    count = 0
    ssr_iter_prev = cross(y_gls - zbar*delta, y_gls - zbar*delta)

    repeatflag = 1
    while (repeatflag) {
        bigvec2 = _ckp_ssr2_gls(y_gls, z, delta, q, br)
        _ckp_dating2_gls(bigvec2, h, m, tstar, glob2, datevec2)

        br = datevec2[., m]

        if (m < 5) {
            c_bar = _ckp_cbar_rs(sort(br:/bigt, 1) \ J(5-m, 1, 0))
        }
        else {
            c_bar = _ckp_cbar_rs(sort(br:/bigt, 1))
        }

        alpha = 1 + c_bar/bigt

        cns_gls = (1-alpha)*J(bigt, 1, 1)
        tend_gls = 1 \ ((-c_bar/bigt)*_ckp_seqa(1, 1, bigt-1) :+ 1)
        z = cns_gls, tend_gls
        y_gls = y[1] \ (y[2::bigt] - alpha*y[1::(bigt-1)])

        zbar = _ckp_est2_zbar(z, initial_impulse, datevec2[., m], q, m, tstar)
        _ckp_olsqr2(y_gls, zbar, b, e)
        zz = cholinv(cross(zbar, zbar))

        R = _ckp_est2_R(model1, alpha, br, m)

        delta = b + zz*R'*cholinv(R*zz*R')*(rr :- R*b)
        e = y_gls - zbar*delta

        // GAUSS: if (count < 10) and (abs(e'e-ssr_iter_prev) > 1e-3)
        if (count < 10 & abs(cross(e, e) - ssr_iter_prev) > 1e-3) {
            count = count + 1
            ssr_iter_prev = cross(e, e)
        }
        else {
            repeatflag = 0
        }
    }

    dx = br
    ssr_out = cross(e, e)
}

// ---------------------------------------------------------------------------
// GAUSS proc(9)=sbur_multiple_gls_algorithm(y,model,penalty,kmax,kmin,maxiter)
// ---------------------------------------------------------------------------
void _ckp_algorithm(real colvector y, real scalar model1, real scalar nbrk, real scalar penalty, real scalar kmax, real scalar kmin, real scalar maxiter, real rowvector stats, real colvector min_tb, real scalar cbar, real scalar krule)
{
    real scalar t, trm, bigt, h, m, q, count, differe, alpha, ssr_prev_iter, ssr_est_prev, ssr_est, contflag
    real colvector datevec, bigvec, y_gls, cns_gls, tend_gls, dx, delta, glob
    real matrix z, z_gls, datevec_mat, datevec_iteration

    real scalar verbose, ndots

    t = rows(y)
    ndots = 0

    // progress feedback: dp iterations can take a while for several breaks
    verbose = (st_local("print") == "" & nbrk >= 2)
    if (verbose) {
        printf("{txt}(dynamic programming for %g breaks ", nbrk)
        displayflush()
    }

    // Computing the break points using OLS
    z = J(t, 1, 1), _ckp_seqa(1, 1, t)

    trm = 0.10
    bigt = t
    h = trunc(trm*bigt)
    m = nbrk
    q = cols(z)

    _ckp_dating(y, z, h, m, q, bigt, glob, datevec_mat, bigvec, 0)

    // Computing the break points using GLS
    datevec = select(datevec_mat[., m], datevec_mat[., m] :> 0)
    datevec = sort(datevec, 1)

    count = 0
    ssr_prev_iter = glob[m]

    differe = 0
    while (differe != -1) {
        if (m < 5) {
            cbar = _ckp_cbar_rs((datevec:/t) \ J(5-m, 1, 0))
        }
        else {
            cbar = _ckp_cbar_rs(datevec:/t)
        }

        alpha = 1 + cbar/t

        cns_gls = 1 \ ((1-alpha)*J(t-1, 1, 1))
        tend_gls = 1 \ ((-cbar/t)*_ckp_seqa(2, 1, t-1) :+ 1)
        z_gls = cns_gls, tend_gls
        y_gls = y[1] \ (y[2::t] - alpha*y[1::(t-1)])

        _ckp_dating(y_gls, z_gls, h, m, q, bigt, glob, datevec_iteration, bigvec, 1)

        if (count < maxiter & abs(glob[m] - ssr_prev_iter) > 1e-3) {
            ssr_prev_iter = glob[m]
            datevec = datevec_iteration[., m]
            count = count + 1
            if (verbose) {
                printf(".")
                ndots = ndots + 1
                if (mod(ndots, 50) == 0) {
                    printf("\n")
                }
                displayflush()
            }
        }
        else {
            differe = -1
        }
    }

    // Computing using restrictions on the parameters
    count = 0
    ssr_est_prev = cross(y, y)

    contflag = 1
    while (contflag) {
        _ckp_est2_gls(y, model1, q, m, bigt, trm, datevec, dx, delta, ssr_est)

        if (count < maxiter & abs(ssr_est - ssr_est_prev) > 1e-3) {
            count = count + 1
            ssr_est_prev = ssr_est
            datevec = sort(dx, 1)
            if (verbose) {
                printf(".")
                ndots = ndots + 1
                if (mod(ndots, 50) == 0) {
                    printf("\n")
                }
                displayflush()
            }
        }
        else {
            contflag = 0
        }
    }
    if (verbose) {
        printf(" done)\n")
        displayflush()
    }

    // Construct the matrix of regressors from the final datevec
    z = _ckp_zbuild(t, model1, datevec)

    // common statistics tail; note that, exactly as in the GAUSS source, cbar
    // is the value from the GLS dating loop and is not recomputed after the
    // restricted estimation stage
    _ckp_tail(y, z, cbar, model1, penalty, kmax, kmin, stats, krule)

    min_tb = datevec
}

// ---------------------------------------------------------------------------
// Dispatcher, GAUSS proc(9)=sbur_multiple_gls, plus Stata interface
// ---------------------------------------------------------------------------
void _ckp_main(string scalar yname, string scalar touse, real scalar model1, real scalar known, string scalar tbmat, real scalar nbrk, real scalar penalty, real scalar kmax, real scalar kmin, real scalar method, real scalar maxiter, string scalar STname, string scalar CVname, string scalar TBname)
{
    real colvector y, min_tb, tbin, lam
    real rowvector stats
    real matrix CV
    real scalar T, cbar, krule

    y = st_data(., yname, touse)
    T = rows(y)

    tbin = st_matrix(tbmat)
    if (cols(tbin) > 1) {
        tbin = tbin'
    }

    // dispatcher exactly as in sbur_multiple_gls: models 0/1 -> brute;
    // models 2/3 -> brute (estimation=0) or algorithm (estimation=1);
    // known break dates are handled by the brute proc as in the source
    if (model1 == 0 | model1 == 1) {
        _ckp_brute(y, model1, 0, tbin, 0, penalty, kmax, kmin, stats, min_tb, cbar, krule)
    }
    else if (known == 1) {
        _ckp_brute(y, model1, 1, tbin, rows(tbin), penalty, kmax, kmin, stats, min_tb, cbar, krule)
    }
    else if (method == 0) {
        _ckp_brute(y, model1, 0, tbin, nbrk, penalty, kmax, kmin, stats, min_tb, cbar, krule)
    }
    else {
        _ckp_algorithm(y, model1, nbrk, penalty, kmax, kmin, maxiter, stats, min_tb, cbar, krule)
    }

    // critical values, exactly the sample.gss mechanics:
    // lam=(min_tb/T)|zeros(5-m,1); {cv_msb,cv_mza,cv_mzt,cv_pt}=msbur_rs(lam,cbar)
    if (model1 <= 1) {
        lam = J(5, 1, 0)
    }
    else {
        lam = min_tb:/T
        if (rows(lam) < 5) {
            lam = lam \ J(5-rows(lam), 1, 0)
        }
    }
    CV = _ckp_msbur_rs(lam, cbar)

    st_matrix(STname, stats)
    st_matrix(CVname, CV)
    st_matrix(TBname, min_tb)
    st_numscalar("r(cbar)", cbar)
    st_numscalar("r(krule)", krule)
}


// ---------------------------------------------------------------------
// Perron-Yabu (2009, JBES 27, 369-396) pretest for a shift in trend:
// Exp-W_FS. Line-by-line port of qfgls.prg (Perron and Yabu, version 2,
// March 2009), reusing the GAUSS-verbatim helpers above
// (_ckp_trimr, _ckp_lagn, _ckp_diff, _ckp_seqa, _ckp_minindc).
// ---------------------------------------------------------------------

// qfgls.prg proc IC: lag length by AIC (criteria=1) or BIC (criteria=2);
// the deterministic regressors are augmented with lagged LEVELS of x
real scalar _ckp_py_ic(real colvector x, real matrix reg_in, real scalar kmax, real scalar criteria)
{
    real matrix reg, rego
    real colvector ICV, dep, e, b
    real scalar i, khat

    reg = reg_in
    ICV = J(kmax+1, 1, 0)
    dep = _ckp_trimr(x, kmax, 0)
    rego = _ckp_trimr(reg, kmax, 0)
    e = dep - rego*luinv(rego'rego)*(rego'dep)
    ICV[1] = ln((e'e)/rows(e))
    for (i=1; i<=kmax; i++) {
        reg = reg, _ckp_lagn(x, i)
        rego = _ckp_trimr(reg, kmax, 0)
        b = qrsolve(rego, dep)
        e = dep - rego*b
        if (criteria == 1) {
            ICV[i+1] = ln((e'e)/rows(e)) + (2*i)/rows(e)
        }
        else {
            ICV[i+1] = ln((e'e)/rows(e)) + (ln(rows(e))*i)/rows(e)
        }
    }
    khat = _ckp_minindc(ICV) - 1
    khat = khat*(khat>=1) + 1*(khat==0)
    return(khat)
}

// qfgls.prg proc ACV: demeaned autocovariances R(0),...,R(T-1), divisor T
real colvector _ckp_py_acv(real colvector x)
{
    real scalar T, i, j, xbar
    real colvector R

    T = rows(x)
    R = J(T, 1, 0)
    xbar = mean(x)
    for (i=1; i<=T; i++) {
        j = i - 1
        R[i] = ((x[|1,1 \ T-j,1|] :- xbar)'(x[|1+j,1 \ T,1|] :- xbar))/T
    }
    return(R)
}

// qfgls.prg proc h0W: Andrews (1991) long-run variance, Quadratic
// Spectral window with AR(1) plug-in bandwidth (no intercept in the
// plug-in regression, as in the GAUSS code)
real scalar _ckp_py_h0w(real colvector x)
{
    real scalar T, b, a, m, h0
    real colvector R, s, delta, lamda

    T = rows(x)
    b = qrsolve(x[|1,1 \ T-1,1|], x[|2,1 \ T,1|])
    a = (4*(b^2))/((1-b)^4)
    R = _ckp_py_acv(x)
    s = _ckp_seqa(1, 1, T-1)
    m = 1.3221*((a*T)^(1/5))
    delta = (6*pi()*s)/(5*m)
    lamda = 3*((sin(delta):/delta) - cos(delta)) :/ (delta:^2)
    h0 = R[1] + 2*(lamda'R[|2,1 \ T,1|])
    return(h0)
}

// qfgls.prg proc breakdate: OLS minimum-SSR single break date over the
// same trimmed range as the main loop
real scalar _ckp_py_breakdate(real colvector x, real scalar model, real scalar kmax, real scalar eps)
{
    real scalar T, TB0, TBN, TBi
    real colvector vsum, constant, trend, DUi, DTi, e
    real matrix reg

    T = rows(x)
    constant = J(T, 1, 1)
    trend = _ckp_seqa(1, 1, T)
    TB0 = max((trunc(eps*T), kmax+2))
    TBN = trunc((1-eps)*T)
    vsum = J(TBN-TB0+1, 1, 1000)
    for (TBi=TB0; TBi<=TBN; TBi++) {
        DUi = (trend :> TBi)
        DTi = (trend :> TBi) :* (trend :- TBi)
        if (model == 1) {
            reg = constant, trend, DUi
        }
        else if (model == 2) {
            reg = constant, trend, DTi
        }
        else {
            reg = constant, DUi, trend, DTi
        }
        e = (I(T) - reg*luinv(reg'reg)*reg')*x
        vsum[TBi-TB0+1] = e'e
    }
    return(TB0 + _ckp_minindc(vsum) - 1)
}

// main body of qfgls.prg: Exp-W_FS over the trimmed candidate range;
// writes (wald, TB, cv10, cv5, cv1) to OUTname
void _ckp_py(string scalar yname, string scalar touse, real scalar model, real scalar criteria, real scalar eps, real scalar kmax, string scalar OUTname)
{
    real colvector y, v_t, constant, trend, vect1, DUi, DTi, u, du, depu, gdep, v, depv, beta, e, b, ehat, DUki, DTki, gdepki
    real matrix cv, VR, reg, regu, greg, VCV, regv, vbeta, regki, gregki
    real scalar T, TBi, lam1, khat, j, ahat, vahat, tau1, t05, IP, r, k, c1, c2, ctau, rhomd1, amu, CR, amus, h0, ki, sige, wald, TB, ie

    y = st_data(., yname, touse)
    T = rows(y)

    // v_t and critical values embedded in qfgls.prg, by model
    if (model == 1) {
        VR = (0, 0, 1)
        v_t = (-4.30 \ -4.39 \ -4.39 \ -4.34 \ -4.32 \ -4.45 \ -4.42 \ -4.33 \ -4.27 \ -4.27)
        cv = (1.60, 2.07, 3.33 \ 1.52, 1.97, 3.24 \ 1.41, 1.88, 3.05 \ 1.26, 1.74, 3.12 \ 0.91, 1.33, 2.83)
    }
    else if (model == 2) {
        VR = (0, 0, 1)
        v_t = (-4.27 \ -4.41 \ -4.51 \ -4.55 \ -4.56 \ -4.57 \ -4.51 \ -4.38 \ -4.26 \ -4.26)
        cv = (1.52, 2.02, 3.37 \ 1.40, 1.93, 3.27 \ 1.28, 1.86, 3.20 \ 1.13, 1.67, 3.06 \ 0.74, 1.28, 2.61)
    }
    else {
        VR = (0, 1, 0, 0 \ 0, 0, 0, 1)
        v_t = (-4.38 \ -4.65 \ -4.78 \ -4.81 \ -4.90 \ -4.88 \ -4.75 \ -4.70 \ -4.41 \ -4.41)
        cv = (2.96, 3.55, 5.02 \ 2.82, 3.36, 4.78 \ 2.65, 3.16, 4.59 \ 2.48, 3.12, 4.47 \ 2.15, 2.79, 4.57)
    }

    constant = J(T, 1, 1)
    trend = _ckp_seqa(1, 1, T)
    vect1 = J(trunc((1-2*eps)*T)+2, 1, 0)

    for (TBi = max((trunc(eps*T), kmax+2)); TBi <= trunc((1-eps)*T); TBi++) {

        lam1 = TBi/T
        DUi = (trend :> TBi)
        DTi = (trend :> TBi) :* (trend :- TBi)
        if (model == 1) {
            reg = constant, trend, DUi
        }
        else if (model == 2) {
            reg = constant, trend, DTi
        }
        else {
            reg = constant, DUi, trend, DTi
        }

        // ---- estimation of alpha ----
        khat = _ckp_py_ic(y, reg, kmax, criteria)
        u = (I(T) - reg*luinv(reg'reg)*reg')*y
        du = _ckp_diff(u, 1)
        depu = u
        regu = _ckp_lagn(u, 1)
        for (j=1; j<=khat-1; j++) {
            regu = regu, _ckp_lagn(du, j)
        }
        depu = _ckp_trimr(depu, khat, 0)
        regu = _ckp_trimr(regu, khat, 0)
        b = luinv(regu'regu)*(regu'depu)
        ehat = depu - regu*b
        VCV = ((ehat'ehat)/rows(ehat))*luinv(regu'regu)
        ahat = b[1]
        vahat = VCV[1,1]
        tau1 = (ahat-1)/sqrt(vahat)

        // ---- upper-biased estimator ----
        if (lam1 <= 0.1) {
            t05 = v_t[1]
        }
        else if (lam1 <= 0.2) {
            t05 = v_t[2]
        }
        else if (lam1 <= 0.3) {
            t05 = v_t[3]
        }
        else if (lam1 <= 0.4) {
            t05 = v_t[4]
        }
        else if (lam1 <= 0.5) {
            t05 = v_t[5]
        }
        else if (lam1 <= 0.6) {
            t05 = v_t[6]
        }
        else if (lam1 <= 0.7) {
            t05 = v_t[7]
        }
        else if (lam1 <= 0.8) {
            t05 = v_t[8]
        }
        else if (lam1 <= 0.9) {
            t05 = v_t[9]
        }
        else {
            t05 = v_t[10]
        }
        IP = trunc((khat+1)/2)
        r = cols(reg)
        k = 10
        c1 = sqrt((1+r)*T)
        c2 = ((r+1)*T - t05*t05*(IP+T))/(t05*(t05+k)*(IP+T))
        if (tau1 > t05) {
            ctau = -tau1
        }
        else if (tau1 > -k) {
            ctau = IP*(tau1/T) - (r+1)/(tau1 + c2*(tau1+k))
        }
        else if (tau1 > -c1) {
            ctau = IP*(tau1/T) - (r+1)/tau1
        }
        else {
            ctau = 0
        }
        rhomd1 = ahat + ctau*sqrt(vahat)
        rhomd1 = 1*(rhomd1>=1) + rhomd1*(abs(rhomd1)<1) - 0.99*(rhomd1<=-1)
        amu = rhomd1

        // ---- super-efficient truncation and quasi-GLS ----
        CR = (T^0.5)*abs(amu-1)
        amus = amu*(CR>1) + 1*(CR<=1)
        gdep = y[1] \ (_ckp_trimr(y, 1, 0) - amus*_ckp_trimr(y, 0, 1))
        greg = reg[1,.] \ (_ckp_trimr(reg, 1, 0) - amus*_ckp_trimr(reg, 0, 1))
        b = luinv(greg'greg)*(greg'gdep)
        v = gdep - greg*b

        // ---- h(0) ----
        if (khat == 1) {
            h0 = (v'v)/rows(v)
        }
        else {
            if (amus == 1) {
                for (ki=1; ki<=khat-1; ki++) {
                    if (ki == 1) {
                        regv = _ckp_lagn(v, ki)
                    }
                    else {
                        regv = regv, _ckp_lagn(v, ki)
                    }
                }
                depv = _ckp_trimr(v, khat-1, 0)
                regv = _ckp_trimr(regv, khat-1, 0)
                beta = luinv(regv'regv)*(regv'depv)
                e = depv - regv*beta
                if (model == 1) {
                    vbeta = J(3, khat-1, 0)
                    for (ki=1; ki<=khat-1; ki++) {
                        DUki = (trend :> TBi-ki)
                        regki = constant, trend, DUki
                        gdepki = y[1] \ (_ckp_trimr(y, 1, 0) - amus*_ckp_trimr(y, 0, 1))
                        gregki = reg[1,.] \ (_ckp_trimr(regki, 1, 0) - amus*_ckp_trimr(regki, 0, 1))
                        vbeta[.,ki] = luinv(gregki'gregki)*(gregki'gdepki)
                    }
                    b[3] = b[3] - vbeta[3,.]*beta
                    h0 = (e'e)/(T-khat)
                }
                else if (model == 2) {
                    h0 = ((e'e)/(T-khat))/((1 - sum(beta))^2)
                }
                else {
                    vbeta = J(4, khat-1, 0)
                    for (ki=1; ki<=khat-1; ki++) {
                        DUki = (trend :> TBi-ki)
                        DTki = (trend :> TBi-ki) :* (trend :- TBi)
                        regki = constant, DUki, trend, DTki
                        gdepki = y[1] \ (_ckp_trimr(y, 1, 0) - amus*_ckp_trimr(y, 0, 1))
                        gregki = reg[1,.] \ (_ckp_trimr(regki, 1, 0) - amus*_ckp_trimr(regki, 0, 1))
                        vbeta[.,ki] = luinv(gregki'gregki)*(gregki'gdepki)
                    }
                    sige = (e'e)/(T-khat)
                    h0 = sige/((1 - sum(beta))^2)
                    b[2] = sqrt(h0)*(b[2] - vbeta[2,.]*beta)/sqrt(sige)
                }
            }
            else if (abs(amus) < 1) {
                h0 = _ckp_py_h0w(v)
            }
        }

        VCV = h0*luinv(greg'greg)
        vect1[TBi - trunc(eps*T) + 1] = (VR*b)'*luinv(VR*VCV*VR')*(VR*b)
    }

    // Exp functional exactly as in qfgls.prg (including the division by T)
    wald = ln(sum(exp(vect1:/2))/T)
    TB = _ckp_py_breakdate(y, model, kmax, eps)

    if (eps == 0.01) {
        ie = 1
    }
    else if (eps == 0.05) {
        ie = 2
    }
    else if (eps == 0.10) {
        ie = 3
    }
    else if (eps == 0.15) {
        ie = 4
    }
    else {
        ie = 5
    }
    st_matrix(OUTname, (wald, TB, cv[ie,1], cv[ie,2], cv[ie,3]))
}


// ---------------------------------------------------------------------
// Breusch-Godfrey LM machinery for the spectral AR regression, exactly
// as in narayanp (cross-validated there against estat bgodfrey, nomiss0):
// the auxiliary regression for order m drops the first m observations
// (no zero-filling), has no constant (the spectral regression has none,
// so the uncentered R-squared is used), LM = (n-m)*R2 ~ chi2(m), and its
// residual degrees of freedom are df = n - k - 2m.
// ---------------------------------------------------------------------

// LM p-value for a single BG order p on residuals ehat of the regression
// of dep on X (no constant), nomiss0 variant
real scalar _ckp_bgp(real colvector ehat, real matrix X, real scalar p)
{
    real matrix XA
    real colvector dep, ba, ea
    real scalar j, n, na, r2, lm

    n = rows(ehat)
    na = n - p
    dep = ehat[|p+1,1 \ n,1|]
    XA = X[|p+1,1 \ n,.|]
    for (j=1; j<=p; j++) {
        XA = XA, ehat[|p+1-j,1 \ n-j,1|]
    }
    ba = qrsolve(XA, dep)
    ea = dep - XA*ba
    r2 = 1 - cross(ea, ea)/cross(dep, dep)
    lm = na*r2
    return(chi2tail(p, lm))
}

// minimum BG p-value over orders 1..H on the adfp regression at lag kstar
// (orders with df = n - cols(X) - p < dffloor are skipped); returns
// (minp, minorder), missing if no admissible order
void _ckp_bgmin(real colvector yt, real scalar kstar, real scalar H, real scalar dffloor, real scalar minp, real scalar mino)
{
    real colvector dyt, ehat, b
    real matrix reg
    real scalar i, p, n, pv

    reg = _ckp_lagn(yt, 1)
    dyt = _ckp_diff(yt, 1)
    i = 1
    while (i <= kstar) {
        reg = reg, _ckp_lagn(dyt, i)
        i = i + 1
    }
    dyt = _ckp_trimr(dyt, kstar+1, 0)
    reg = _ckp_trimr(reg, kstar+1, 0)
    _ckp_olsqr2(dyt, reg, b, ehat)

    n = rows(dyt)
    minp = .
    mino = .
    for (p=1; p<=H; p++) {
        if (n - cols(reg) - 2*p < dffloor) {
            continue
        }
        pv = _ckp_bgp(ehat, reg, p)
        if (minp >= . | pv < minp) {
            minp = pv
            mino = p
        }
    }
}

// general-to-specific BG lag selection: start at kmax, walk down while
// the regression stays clean (min BG p >= 0.05 over orders 1..H); at the
// first dirty lag return to the previous clean one. If kmax itself is
// dirty, kmax is used and the warning flag is set.
real scalar _ckp_bgsel(real colvector yt, real scalar kmax, real scalar kmin, real scalar H, real scalar dffloor, real scalar warn)
{
    real scalar k, minp, mino

    warn = 0
    _ckp_bgmin(yt, kmax, H, dffloor, minp, mino)
    if (minp < 0.05) {
        warn = 1
        return(kmax)
    }
    k = kmax
    while (k > kmin) {
        _ckp_bgmin(yt, k-1, H, dffloor, minp, mino)
        if (minp < 0.05) {
            return(k)
        }
        k = k - 1
    }
    return(kmin)
}

end
*==============================================================================
* End of ckptest.ado
*==============================================================================
