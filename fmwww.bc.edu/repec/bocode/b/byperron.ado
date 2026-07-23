*! byperron 1.5.1 22jul2026 Ozan Eruygur
* Estimating and testing multiple structural changes in linear models using band spectral regressions
* Port of the official MATLAB code bsr_codes (Yohei Yamamoto, February 19, 2013) accompanying
* Yamamoto, Y. and P. Perron (2013), Estimating and testing multiple structural changes in
* linear models using band spectral regressions, The Econometrics Journal 16, 400-429.
* The port replicates the MATLAB computations exactly, including all numerical conventions.

program byperron, eclass
    version 14.0
    syntax varlist(min=2 numeric ts) [if] [in] [, METHod(string) WL(real -1) WH(real -1) MAXbreaks(integer 5) TRIM(real 0.15) ROBust(integer 1) HETDAT(integer 1) HETVAR(integer 0) PREwhit(integer 0) NODEMEAN DETrend(string) NOALign]

    * method
    if `"`method'"' == "" local method "trun"
    local method = lower(`"`method'"')
    if !inlist(`"`method'"', "full", "trun", "band") {
        di as error "method() must be full, trun, or band"
        exit 198
    }
    if `"`method'"' == "full" local mcode 1
    if `"`method'"' == "trun" local mcode 2
    if `"`method'"' == "band" local mcode 3

    * band limits (in multiples of pi)
    if `"`method'"' == "band" {
        if `wl' == -1 | `wh' == -1 {
            di as error "method(band) requires both wl() and wh()"
            exit 198
        }
        if !(`wl' >= 0 & `wl' < `wh' & `wh' <= 1) {
            di as error "band limits must satisfy 0 <= wl < wh <= 1 (in multiples of pi)"
            exit 198
        }
    }
    else {
        if `wl' != -1 | `wh' != -1 {
            di as error "wl() and wh() are only allowed with method(band)"
            exit 198
        }
        local wl 0
        local wh 1
    }

    * covariance options
    foreach opt in robust hetdat hetvar prewhit {
        if !inlist(``opt'', 0, 1) {
            di as error "`opt'() must be 0 or 1"
            exit 198
        }
    }
    if `prewhit' == 1 & `"`method'"' != "full" {
        di as error "prewhit(1) is only allowed with method(full)"
        exit 198
    }

    * trimming: only tabulated values (as in the original code)
    local ieps 0
    if abs(`trim' - 0.05) < 1e-8 local ieps 1
    if abs(`trim' - 0.10) < 1e-8 local ieps 2
    if abs(`trim' - 0.15) < 1e-8 local ieps 3
    if abs(`trim' - 0.20) < 1e-8 local ieps 4
    if abs(`trim' - 0.25) < 1e-8 local ieps 5
    if `ieps' == 0 {
        di as error "trim() must be one of 0.05, 0.10, 0.15, 0.20, 0.25 (tabulated critical values)"
        exit 198
    }
    local cv1cols : word `ieps' of 9 8 5 3 2
    if `maxbreaks' < 1 | `maxbreaks' > `cv1cols' {
        di as error "maxbreaks() must be between 1 and `cv1cols' for trim(`trim')"
        exit 198
    }

    * sample and variables
    marksample touse, novarlist
    tsrevar `varlist'
    local rvlist `r(varlist)'
    markout `touse' `rvlist'
    gettoken yrv xrv : rvlist
    gettoken depvar indepvars : varlist
    local q : word count `xrv'
    if `q' > 10 {
        di as error "at most 10 regressors are allowed (critical value tables)"
        exit 198
    }

    * operator structure: lag orders and differencing depths of the regressors and depvar
    local maxlag 0
    local shift 0
    local align 0
    tsunab xfull : `indepvars'
    local nx : word count `xfull'
    capture tsset
    local dtvar0 `r(timevar)'
    local tdelta0 = r(tdelta)
    if `tdelta0' >= . local tdelta0 1
    if `"`dtvar0'"' != "" {
        local fbase .
        forvalues k = 1/`nx' {
            local v : word `k' of `xfull'
            local rvk : word `k' of `xrv'
            local lg 0
            local ds 0
            local dotpos = strpos("`v'", ".")
            if `dotpos' > 0 {
                local ops = upper(substr("`v'", 1, `dotpos' - 1))
                if regexm("`ops'", "L([0-9]+)") local lg = real(regexs(1))
                else if strpos("`ops'", "L") local lg 1
                if regexm("`ops'", "D([0-9]+)") local ds = real(regexs(1))
                else if strpos("`ops'", "D") local ds 1
                if regexm("`ops'", "S([0-9]+)") local ds = `ds' + real(regexs(1))
                else if strpos("`ops'", "S") local ds = `ds' + 1
            }
            if `lg' > `maxlag' local maxlag = `lg'
            if `ds' > `shift' local shift = `ds'
            local wr`k' = `lg' + `ds'
            qui sum `dtvar0' if !missing(`rvk'), meanonly
            local sk = r(min) - `lg'*`tdelta0'
            if `fbase' >= . | `sk' > `fbase' local fbase = `sk'
        }
    }

    * frame alignment: the transformed regressors define a frame that starts where their
    * differencing first becomes computable; all transformations are computed within that
    * frame, exactly as in the original code, so the observations before the frame and the
    * first observation of the frame consumed by the dependent variable step are excluded.
    * Only active when a regressor involves differencing; disable with noalign.
    if `shift' > 0 & "`noalign'" == "" & `"`dtvar0'"' != "" {
        local treq .
        forvalues k = 1/`nx' {
            local cand = `fbase' + `wr`k''*`tdelta0'
            if `treq' >= . | `cand' > `treq' local treq = `cand'
        }
        tsunab yfull : `depvar'
        local v : word 1 of `yfull'
        local lgy 0
        local dsy 0
        local dotpos = strpos("`v'", ".")
        if `dotpos' > 0 {
            local ops = upper(substr("`v'", 1, `dotpos' - 1))
            if regexm("`ops'", "L([0-9]+)") local lgy = real(regexs(1))
            else if strpos("`ops'", "L") local lgy 1
            if regexm("`ops'", "D([0-9]+)") local dsy = real(regexs(1))
            else if strpos("`ops'", "D") local dsy 1
            if regexm("`ops'", "S([0-9]+)") local dsy = `dsy' + real(regexs(1))
            else if strpos("`ops'", "S") local dsy = `dsy' + 1
        }
        local dy = `dsy'
        if `dy' < 1 local dy 1
        local cand = `fbase' + (`dy' + `lgy')*`tdelta0'
        if `cand' > `treq' local treq = `cand'
        qui count if `touse' & `dtvar0' < `treq'
        if r(N) > 0 local align 1
        qui replace `touse' = 0 if `dtvar0' < `treq'
    }

    qui count if `touse'
    local bigt = r(N)
    if `bigt' == 0 error 2000
    local h = ceil(`trim' * `bigt')
    if (`maxbreaks' + 1) * `h' > `bigt' {
        di as error "sample too small: need (maxbreaks+1)*ceil(trim*T) <= T"
        exit 198
    }

    * detrend window: with detrend(linear) the linear trend for the dependent variable is
    * fitted on the estimation sample extended back by the maximum lag order among the
    * regressors, so that the trend is computed over the same span as in the original code,
    * which detrends the dependent variable before the regressor lags drop the low order
    * observations at the front of the sample. Observations before the estimation sample
    * enter the detrend window whenever the dependent variable is observed there.
    tempvar tousey
    qui gen byte `tousey' = `touse'
    if "`detrend'" == "linear" {
        if `maxlag' > 0 & `"`dtvar0'"' != "" {
            qui sum `dtvar0' if `touse', meanonly
            local tstart = r(min)
            qui replace `tousey' = 1 if inrange(`dtvar0', `tstart' - `maxlag'*`tdelta0', `tstart' - `tdelta0') & !missing(`yrv')
        }
    }

    * time variable for date labels, if the data are tsset
    local tfmt ""
    tempvar tv
    qui gen double `tv' = .
    capture tsset
    if _rc == 0 & `"`r(timevar)'"' != "" {
        local timevar `r(timevar)'
        qui replace `tv' = `timevar'
        local tfmt : format `timevar'
    }

    if `robust' == 1 & `hetdat' == 0 {
        di as text "note: the case hetdat=0 is not allowed with robust=1 in the original code; hetdat is ignored"
    }

    local demean 1
    if "`nodemean'" != "" local demean 0

    if `"`detrend'"' == "" local detrend "none"
    local detrend = lower(`"`detrend'"')
    if !inlist(`"`detrend'"', "none", "linear") {
        di as error "detrend() must be none or linear"
        exit 198
    }
    local dtcode 0
    if `"`detrend'"' == "linear" local dtcode 1

    * computation
    tempname SUPF WSUPF GLB DATEVEC SUPFSEQ CVSUPF CVSEQ CVDMAX UDMAX WDMAX TVALS
    capture matrix drop __bsrb_supfseq
    mata: _bsrbreak_main("`yrv'", "`xrv'", "`touse'", "`tousey'", "`tv'", `mcode', `wl', `wh', `maxbreaks', `h', `robust', `hetdat', `hetvar', `prewhit', `ieps', `demean', `dtcode')
    matrix `SUPF' = __bsrb_supf
    matrix `WSUPF' = __bsrb_wsupf
    matrix `GLB' = __bsrb_glb
    matrix `DATEVEC' = __bsrb_datevec
    matrix `CVSUPF' = __bsrb_cvsupf
    matrix `CVSEQ' = __bsrb_cvseq
    matrix `CVDMAX' = __bsrb_cvdmax
    matrix `TVALS' = __bsrb_tvals
    scalar `UDMAX' = __bsrb_udmax
    scalar `WDMAX' = __bsrb_wdmax
    local m = `maxbreaks'
    if `m' >= 2 matrix `SUPFSEQ' = __bsrb_supfseq
    capture matrix drop __bsrb_supf __bsrb_wsupf __bsrb_glb __bsrb_datevec __bsrb_cvsupf __bsrb_cvseq __bsrb_cvdmax __bsrb_tvals __bsrb_supfseq
    capture scalar drop __bsrb_udmax __bsrb_wdmax

    * display
    di
    di as text "Yamamoto-Perron (2013) band spectral structural change tests"
    di as text "{hline 70}"
    if `mcode' == 1 di as text "Method          : " as result "full spectrum (Bai-Perron time domain)"
    if `mcode' == 2 di as text "Method          : " as result "truncation, per-segment L = ceil(log(n))"
    if `mcode' == 3 di as text "Method          : " as result "band spectrum [" %6.4f `wl' "*pi, " %6.4f `wh' "*pi]"
    di as text "Dependent var   : " as result "`depvar'"
    di as text "Regressors (q=`q'): " as result "`indepvars'"
    di as text "Sample          : " as result "T = `bigt'" as text ", trim = " as result %4.2f `trim' as text ", h = " as result "`h'"
    di as text "Max breaks (m)  : " as result "`m'"
    di as text "Covariance      : " as result "robust=`robust' hetdat=`hetdat' hetvar=`hetvar' prewhit=`prewhit'"
    if `demean' == 1 di as text "Centering       : " as result "depvar and regressors demeaned over the estimation sample"
    else di as text "Centering       : " as result "none (nodemean); data used as supplied"
    if `dtcode' == 1 {
        if `maxlag' > 0 di as text "Detrending      : " as result "depvar linearly detrended; trend fitted on the estimation sample extended back by `maxlag' periods"
        else di as text "Detrending      : " as result "depvar linearly detrended over the estimation sample"
    }
    if `align' == 1 di as text "Alignment       : " as result "sample aligned to the differenced regressor frame, as in the original code"
    di as text "{hline 70}"
    di as text "supF tests of 0 vs k breaks (scaled by q)"
    di as text "        k       supF      cv10%       cv5%     cv2.5%       cv1%"
    forvalues i = 1/`m' {
        di as text %9.0f `i' "  " as result %9.4f `SUPF'[`i',1] "  " as text %9.2f `CVSUPF'[1,`i'] "  " %9.2f `CVSUPF'[2,`i'] "  " %9.2f `CVSUPF'[3,`i'] "  " %9.2f `CVSUPF'[4,`i']
    }
    di as text "{hline 70}"
    di as text "Dmax tests against an unknown number of breaks"
    di as text "UDmax = " as result %9.4f `UDMAX' as text "   cv10/5/2.5/1% : " as result %6.2f `CVDMAX'[1,1] " " %6.2f `CVDMAX'[2,1] " " %6.2f `CVDMAX'[3,1] " " %6.2f `CVDMAX'[4,1]
    di as text "WDmax = " as result %9.4f `WDMAX' as text "   cv10/5/2.5/1% : " as result %6.2f `CVDMAX'[1,2] " " %6.2f `CVDMAX'[2,2] " " %6.2f `CVDMAX'[3,2] " " %6.2f `CVDMAX'[4,2]
    di as text "(WDmax uses 5 percent level weights, as in the original code)"
    if `m' >= 2 {
        di as text "{hline 70}"
        di as text "supF(l+1|l) sequential tests (l = 1, ..., m-1)"
        di as text "    l+1|l       supF    new break      cv10%     cv5%   cv2.5%     cv1%"
        forvalues i = 1/`=`m'-1' {
            local nd = `SUPFSEQ'[`i',2]
            local dlab "`nd'"
            if `"`tfmt'"' != "" & `nd' >= 1 {
                local dnum = `TVALS'[`nd',1]
                local dtxt = strtrim(`"`: di `tfmt' `dnum''"')
                local dlab `"`dtxt'"'
            }
            di as text %6.0f `=`i'+1' "|" %-3.0f `i' as result %11.4f `SUPFSEQ'[`i',1] "  " as result %-12s "`dlab'" as text %8.2f `CVSEQ'[1,`=`i'+1'] " " %8.2f `CVSEQ'[2,`=`i'+1'] " " %8.2f `CVSEQ'[3,`=`i'+1'] " " %8.2f `CVSEQ'[4,`=`i'+1']
        }
    }
    di as text "{hline 70}"
    di as text "Break dates from global minimization of the band spectral SSR"
    forvalues i = 1/`m' {
        local dl ""
        forvalues jj = 1/`i' {
            local nd = `DATEVEC'[`jj',`i']
            if `"`tfmt'"' != "" & `nd' >= 1 {
                local dnum = `TVALS'[`nd',1]
                local dtxt = strtrim(`"`: di `tfmt' `dnum''"')
                local dl `"`dl' `dtxt'"'
            }
            else local dl `"`dl' `nd'"'
        }
        local ssrtxt = strtrim(`"`: di %14.8g `GLB'[`i',1]'"')
        di as text "  m = `i' :" as result "`dl'" as text "   SSR = " as result "`ssrtxt'"
    }
    di as text "{hline 70}"
    local mhat 0
    local capped 0
    local np 1
    local v1 : di %8.2f `SUPF'[1,1]
    local w1 : di %8.2f `CVSUPF'[2,1]
    if `SUPF'[1,1] >= `CVSUPF'[2,1] {
        local mhat 1
        local pl1 "supF   = `v1' >= `w1'  --> 1"
        if `m' >= 2 {
            local sl 1
            local sgo 1
            while `sgo' & `sl' <= `m' - 1 {
                local vv : di %8.2f `SUPFSEQ'[`sl',1]
                local ww : di %8.2f `CVSEQ'[2,`=`sl'+1']
                local np = `np' + 1
                if `SUPFSEQ'[`sl',1] >= `CVSEQ'[2,`=`sl'+1'] {
                    local mhat = `sl' + 1
                    local pl`np' "F(`=`sl'+1'|`sl') = `vv' >= `ww'  --> `mhat'"
                    local sl = `sl' + 1
                }
                else {
                    local pl`np' "F(`=`sl'+1'|`sl') = `vv' <  `ww'  --> stop at `mhat'"
                    local sgo 0
                }
            }
            if `sgo' == 1 & `mhat' == `m' {
                local capped 1
                local pl`np' "`pl`np''   [limit at maxbreaks(`m')]"
            }
        }
    }
    else local pl1 "supF   = `v1' <  `w1'  --> no break"
    if `mhat' == 0 {
        di as result ">>> SELECTED: no break   (sequential procedure, 5% level)"
        forvalues ip = 1/`np' {
            di as text "    `pl`ip''"
        }
    }
    else {
        local dl ""
        forvalues jj = 1/`mhat' {
            local nd = `DATEVEC'[`jj',`mhat']
            if `"`tfmt'"' != "" & `nd' >= 1 {
                local dnum = `TVALS'[`nd',1]
                local dtxt = strtrim(`"`: di `tfmt' `dnum''"')
                local dl `"`dl' `dtxt'"'
            }
            else local dl `"`dl' `nd'"'
        }
        local bword "breaks"
        if `mhat' == 1 local bword "break"
        di as result `">>> SELECTED: `mhat' `bword'   date(s):`dl'   (sequential, 5% level; dates = global m = `mhat' row)"'
        forvalues ip = 1/`np' {
            di as text "    `pl`ip''"
        }
    }
    di as text "{hline 70}"
    if `"`tfmt'"' == "" di as text "Break dates are observation indices within the estimation sample."

    * stored results
    ereturn post, esample(`touse')
    ereturn scalar N = `bigt'
    ereturn scalar h = `h'
    ereturn scalar q = `q'
    ereturn scalar m = `m'
    ereturn scalar trim = `trim'
    ereturn scalar robust = `robust'
    ereturn scalar hetdat = `hetdat'
    ereturn scalar hetvar = `hetvar'
    ereturn scalar prewhit = `prewhit'
    ereturn scalar demean = `demean'
    ereturn scalar detrend = `dtcode'
    ereturn scalar align = `align'
    ereturn scalar mseq = `mhat'
    if `mcode' == 3 {
        ereturn scalar wl = `wl'
        ereturn scalar wh = `wh'
    }
    ereturn scalar udmax = `UDMAX'
    ereturn scalar wdmax = `WDMAX'
    ereturn local method `"`method'"'
    ereturn local detrendtype `"`detrend'"'
    ereturn local depvar `"`depvar'"'
    ereturn local indepvars `"`indepvars'"'
    ereturn local cmdline `"byperron `0'"'
    ereturn local cmd "byperron"
    ereturn matrix supf = `SUPF'
    ereturn matrix wsupf = `WSUPF'
    ereturn matrix glb = `GLB'
    ereturn matrix datevec = `DATEVEC'
    if `m' >= 2 ereturn matrix supfseq = `SUPFSEQ'
    ereturn matrix cv_supf = `CVSUPF'
    ereturn matrix cv_seq = `CVSEQ'
    ereturn matrix cv_dmax = `CVDMAX'
end

version 14.0
mata:
mata set matastrict on

// ---------------------------------------------------------------------------
// Harvey (1978) real finite Fourier transform matrix
// element formulas and branch order identical to selectmatreal.m / _trun.m
// ---------------------------------------------------------------------------
real matrix _bsrbreak_buildw(real scalar l)
{
    real matrix w
    real rowvector s
    real scalar t
    w = J(l, l, 0)
    s = 1..l
    for (t=1; t<=l; t++) {
        if (t==1) {
            w[t,.] = J(1, l, l^(-1/2))
        }
        else if (t==l & mod(l,2)==0) {
            w[t,.] = l^(-1/2) :* ((-1):^(s:+1))
        }
        else if (mod(t,2)==0) {
            w[t,.] = (2/l)^(1/2) :* cos(pi():*t:*(s:-1):/l)
        }
        else {
            w[t,.] = (2/l)^(1/2) :* sin(pi():*(t-1):*(s:-1):/l)
        }
    }
    return(w)
}

// ---------------------------------------------------------------------------
// selection matrix omega = W'AW with caching by segment length l
// meth: 2 = truncation (selectmatreal_trun.m), 3 = band (selectmatreal.m)
// ---------------------------------------------------------------------------
real matrix _bsrbreak_selmat(real scalar l, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache, real scalar na)
{
    real matrix w, omega
    real colvector adiag
    real scalar L, j, fjp, fj
    if (cache[l] != NULL) {
        na = nacache[l]
        return(*(cache[l]))
    }
    w = _bsrbreak_buildw(l)
    if (meth == 2) {
        L = ceil(ln(l))
        if (L >= l) L = l - 1
        adiag = J(l, 1, 1)
        if (L >= 1) adiag[|1 \ L|] = J(L, 1, 0)
    }
    else {
        adiag = J(l, 1, 0)
        if (wl == 0) adiag[1] = 1
        for (j=2; j<=l; j++) {
            if (mod(j,2)==0) {
                fjp = j*pi()
                fj = fjp/l
                if (wl <= fj & wh >= fj) adiag[j] = 1
            }
            else {
                adiag[j] = adiag[j-1]
            }
        }
    }
    omega = (w :* adiag)' * w
    na = sum(adiag)
    cache[l] = &omega
    nacache[l] = na
    return(omega)
}

// ---------------------------------------------------------------------------
// olsqr.m : b = inv(x'x)x'y using the LU-based inverse as MATLAB inv()
// ---------------------------------------------------------------------------
real colvector _bsrbreak_olsqr(real colvector y, real matrix x)
{
    return(luinv(x'*x)*x'*y)
}

// ---------------------------------------------------------------------------
// ssr.m : recursive SSR vector, full spectrum
// ---------------------------------------------------------------------------
real colvector _bsrbreak_ssrvec_full(real scalar start, real colvector y, real matrix z, real scalar h, real scalar last)
{
    real colvector vecssr, delta1, delta2, invz
    real matrix inv1, inv2
    real scalar r, v, f
    real colvector res
    vecssr = J(last, 1, 0)
    inv1 = luinv(z[|start,1 \ start+h-1,.|]' * z[|start,1 \ start+h-1,.|])
    delta1 = inv1 * (z[|start,1 \ start+h-1,.|]' * y[|start \ start+h-1|])
    res = y[|start \ start+h-1|] - z[|start,1 \ start+h-1,.|] * delta1
    vecssr[start+h-1] = res'*res
    for (r=start+h; r<=last; r++) {
        v = y[r] - z[r,.] * delta1
        invz = inv1 * z[r,.]'
        f = 1 + z[r,.] * invz
        delta2 = delta1 + (invz * v) / f
        inv2 = inv1 - (invz * invz') / f
        inv1 = inv2
        delta1 = delta2
        vecssr[r] = vecssr[r-1] + v*v/f
    }
    return(vecssr)
}

// ---------------------------------------------------------------------------
// ssr_trun.m / ssr_bsr.m : SSR vector on band-filtered data
// ---------------------------------------------------------------------------
real colvector _bsrbreak_ssrvec_band(real scalar start, real colvector y, real matrix z, real scalar h, real scalar last, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache)
{
    real colvector vecssr, yf, delta, res
    real matrix omega, zf
    real scalar r, l, na
    vecssr = J(last, 1, 0)
    for (r=start+h-1; r<=last; r++) {
        l = r - start + 1
        omega = _bsrbreak_selmat(l, meth, wl, wh, cache, nacache, na=.)
        zf = omega * z[|start,1 \ r,.|]
        yf = omega * y[|start \ r|]
        delta = luinv(zf'*zf) * zf' * yf
        res = yf - zf * delta
        vecssr[r] = res'*res
    }
    return(vecssr)
}

// ---------------------------------------------------------------------------
// first-occurrence minimum and maximum, as MATLAB min/max
// ---------------------------------------------------------------------------
void _bsrbreak_minfirst(real colvector v, real scalar mn, real scalar idx)
{
    real scalar i
    mn = v[1]
    idx = 1
    for (i=2; i<=rows(v); i++) {
        if (v[i] < mn) {
            mn = v[i]
            idx = i
        }
    }
}

void _bsrbreak_maxfirst(real colvector v, real scalar mx, real scalar idx)
{
    real scalar i
    mx = v[1]
    idx = 1
    for (i=2; i<=rows(v); i++) {
        if (v[i] > mx) {
            mx = v[i]
            idx = i
        }
    }
}

// ---------------------------------------------------------------------------
// parti.m : optimal one-break partition from the triangular SSR vector
// ---------------------------------------------------------------------------
void _bsrbreak_parti(real scalar start, real scalar b1, real scalar b2, real scalar last, real colvector bigvec, real scalar bigt, real scalar ssrmin, real scalar dx)
{
    real colvector dvec
    real scalar ini, j, jj, k, idx
    dvec = J(bigt, 1, 0)
    ini = (start-1)*bigt - (start-2)*(start-1)/2 + 1
    for (j=b1; j<=b2; j++) {
        jj = j - start
        k = j*bigt - (j-1)*j/2 + last - j
        dvec[j] = bigvec[ini+jj] + bigvec[k]
    }
    _bsrbreak_minfirst(dvec[|b1 \ b2|], ssrmin=., idx=.)
    dx = (b1-1) + idx
}

// ---------------------------------------------------------------------------
// dating.m / dating_trun.m / dating_bsr.m : dynamic programming
// ---------------------------------------------------------------------------
void _bsrbreak_dating(real colvector y, real matrix z, real scalar h, real scalar m, real scalar bigt, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache, real colvector glb, real matrix datevec, real colvector bigvec)
{
    real matrix optdat, optssr
    real colvector dvec, vecssr
    real scalar i, j1, ib, jb, jlast, ssrmin, datx, mn, idx, xx
    datevec = J(m, m, 0)
    optdat = J(bigt, m, 0)
    optssr = J(bigt, m, 0)
    dvec = J(bigt, 1, 0)
    glb = J(m, 1, 0)
    bigvec = J(bigt*(bigt+1)/2, 1, 0)
    for (i=1; i<=bigt-h+1; i++) {
        if (meth == 1) vecssr = _bsrbreak_ssrvec_full(i, y, z, h, bigt)
        else vecssr = _bsrbreak_ssrvec_band(i, y, z, h, bigt, meth, wl, wh, cache, nacache)
        bigvec[|(i-1)*bigt+i-(i-1)*i/2 \ i*bigt-(i-1)*i/2|] = vecssr[|i \ bigt|]
    }
    if (m == 1) {
        _bsrbreak_parti(1, h, bigt-h, bigt, bigvec, bigt, ssrmin=., datx=.)
        datevec[1,1] = datx
        glb[1] = ssrmin
    }
    else {
        for (j1=2*h; j1<=bigt; j1++) {
            _bsrbreak_parti(1, h, j1-h, j1, bigvec, bigt, ssrmin=., datx=.)
            optssr[j1,1] = ssrmin
            optdat[j1,1] = datx
        }
        glb[1] = optssr[bigt,1]
        datevec[1,1] = optdat[bigt,1]
        for (ib=2; ib<=m; ib++) {
            if (ib == m) {
                jlast = bigt
                for (jb=ib*h; jb<=jlast-h; jb++) {
                    dvec[jb] = optssr[jb,ib-1] + bigvec[(jb+1)*bigt - jb*(jb+1)/2]
                }
                _bsrbreak_minfirst(dvec[|ib*h \ jlast-h|], mn=., idx=.)
                optssr[jlast,ib] = mn
                optdat[jlast,ib] = (ib*h-1) + idx
            }
            else {
                for (jlast=(ib+1)*h; jlast<=bigt; jlast++) {
                    for (jb=ib*h; jb<=jlast-h; jb++) {
                        dvec[jb] = optssr[jb,ib-1] + bigvec[jb*bigt - jb*(jb-1)/2 + jlast - jb]
                    }
                    _bsrbreak_minfirst(dvec[|ib*h \ jlast-h|], mn=., idx=.)
                    optssr[jlast,ib] = mn
                    optdat[jlast,ib] = (ib*h-1) + idx
                }
            }
            datevec[ib,ib] = optdat[bigt,ib]
            for (i=1; i<=ib-1; i++) {
                xx = ib - i
                datevec[xx,ib] = optdat[datevec[xx+1,ib],xx]
            }
            glb[ib] = optssr[bigt,ib]
        }
    }
}

// ---------------------------------------------------------------------------
// pzbar.m : time-domain diagonal partition of z
// ---------------------------------------------------------------------------
real matrix _bsrbreak_pzbar(real matrix zz, real scalar m, real colvector bb)
{
    real matrix zb
    real scalar nt, q1, i
    nt = rows(zz)
    q1 = cols(zz)
    zb = J(nt, (m+1)*q1, 0)
    zb[|1,1 \ bb[1],q1|] = zz[|1,1 \ bb[1],.|]
    for (i=2; i<=m; i++) {
        zb[|bb[i-1]+1,(i-1)*q1+1 \ bb[i],i*q1|] = zz[|bb[i-1]+1,1 \ bb[i],.|]
    }
    zb[|bb[m]+1,m*q1+1 \ nt,(m+1)*q1|] = zz[|bb[m]+1,1 \ nt,.|]
    return(zb)
}

// ---------------------------------------------------------------------------
// pyzbar_trun.m / pyzbar_bsr.m : band-filtered diagonal partition
// meth 1 returns the time-domain quantities so that the same code paths apply
// ---------------------------------------------------------------------------
void _bsrbreak_pyzbar(real colvector yy, real matrix zz, real scalar m, real colvector bb, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache, real colvector yb, real matrix zb, real matrix zfull, real colvector na)
{
    real matrix omega, zf
    real colvector yf
    real scalar nt, q1, i, n
    nt = rows(zz)
    q1 = cols(zz)
    if (meth == 1) {
        yb = yy
        zb = _bsrbreak_pzbar(zz, m, bb)
        zfull = zz
        na = J(m+1, 1, .)
        na[1] = bb[1]
        for (i=2; i<=m; i++) na[i] = bb[i] - bb[i-1]
        na[m+1] = nt - bb[m]
        return
    }
    yb = J(nt, 1, 0)
    zb = J(nt, (m+1)*q1, 0)
    zfull = J(nt, q1, 0)
    na = J(m+1, 1, 0)
    omega = _bsrbreak_selmat(bb[1], meth, wl, wh, cache, nacache, n=.)
    yf = omega * yy[|1 \ bb[1]|]
    zf = omega * zz[|1,1 \ bb[1],.|]
    yb[|1 \ bb[1]|] = yf
    zb[|1,1 \ bb[1],q1|] = zf
    zfull[|1,1 \ bb[1],.|] = zf
    na[1] = n
    for (i=2; i<=m; i++) {
        omega = _bsrbreak_selmat(bb[i]-bb[i-1], meth, wl, wh, cache, nacache, n=.)
        yf = omega * yy[|bb[i-1]+1 \ bb[i]|]
        zf = omega * zz[|bb[i-1]+1,1 \ bb[i],.|]
        yb[|bb[i-1]+1 \ bb[i]|] = yf
        zb[|bb[i-1]+1,(i-1)*q1+1 \ bb[i],i*q1|] = zf
        zfull[|bb[i-1]+1,1 \ bb[i],.|] = zf
        na[i] = n
    }
    omega = _bsrbreak_selmat(nt-bb[m], meth, wl, wh, cache, nacache, n=.)
    yf = omega * yy[|bb[m]+1 \ nt|]
    zf = omega * zz[|bb[m]+1,1 \ nt,.|]
    yb[|bb[m]+1 \ nt|] = yf
    zb[|bb[m]+1,m*q1+1 \ nt,(m+1)*q1|] = zf
    zfull[|bb[m]+1,1 \ nt,.|] = zf
    na[m+1] = n
}

// ---------------------------------------------------------------------------
// plambda.m and psigmq.m
// ---------------------------------------------------------------------------
real matrix _bsrbreak_plambda(real colvector b, real scalar m, real scalar bigt)
{
    real matrix lambda
    real scalar k
    lambda = J(m+1, m+1, 0)
    lambda[1,1] = b[1]/bigt
    for (k=2; k<=m; k++) lambda[k,k] = (b[k]-b[k-1])/bigt
    lambda[m+1,m+1] = (bigt-b[m])/bigt
    return(lambda)
}

real matrix _bsrbreak_psigmq(real colvector res, real colvector b, real scalar i, real scalar nt)
{
    real matrix sigmat
    real scalar kk
    sigmat = J(i+1, i+1, 0)
    sigmat[1,1] = res[|1 \ b[1]|]'*res[|1 \ b[1]|]/b[1]
    for (kk=2; kk<=i; kk++) {
        sigmat[kk,kk] = res[|b[kk-1]+1 \ b[kk]|]'*res[|b[kk-1]+1 \ b[kk]|]/(b[kk]-b[kk-1])
    }
    sigmat[i+1,i+1] = res[|b[i]+1 \ nt|]'*res[|b[i]+1 \ nt|]/(nt-b[i])
    return(sigmat)
}

// ---------------------------------------------------------------------------
// correcthc.m : White heteroskedasticity robust with (nt-d) correction
// ---------------------------------------------------------------------------
real matrix _bsrbreak_correcthc(real matrix reg, real colvector res)
{
    real matrix vmat
    real scalar nt, d
    nt = rows(reg)
    d = cols(reg)
    vmat = reg :* res
    return(vmat'*vmat/(nt-d))
}

// ---------------------------------------------------------------------------
// kern.m, bandw.m, jhatpr.m, correct.m : HAC with quadratic spectral kernel
// ---------------------------------------------------------------------------
real scalar _bsrbreak_kern(real scalar x)
{
    real scalar del
    del = 6*pi()*x/5
    return(3*(sin(del)/del - cos(del))/(del*del))
}

real scalar _bsrbreak_bandw(real matrix vhat)
{
    real scalar nt, d, a2n, a2d, i, b, sig, a2
    real colvector e
    nt = rows(vhat)
    d = cols(vhat)
    a2n = 0
    a2d = 0
    for (i=1; i<=d; i++) {
        b = _bsrbreak_olsqr(vhat[|2,i \ nt,i|], vhat[|1,i \ nt-1,i|])
        e = vhat[|2,i \ nt,i|] - b*vhat[|1,i \ nt-1,i|]
        sig = e'*e
        sig = sig/(nt-1)
        a2n = a2n + 4*b*b*sig*sig/(1-b)^8
        a2d = a2d + sig*sig/(1-b)^4
    }
    a2 = a2n/a2d
    return(1.3221*(a2*nt)^.2)
}

real matrix _bsrbreak_jhatpr(real matrix vmat)
{
    real matrix jhat
    real scalar nt, d, st, j
    nt = rows(vmat)
    d = cols(vmat)
    st = _bsrbreak_bandw(vmat)
    jhat = vmat'*vmat
    for (j=1; j<=nt-1; j++) {
        jhat = jhat + _bsrbreak_kern(j/st) :* (vmat[|j+1,1 \ nt,.|]'*vmat[|1,1 \ nt-j,.|])
    }
    for (j=1; j<=nt-1; j++) {
        jhat = jhat + _bsrbreak_kern(j/st) :* (vmat[|1,1 \ nt-j,.|]'*vmat[|j+1,1 \ nt,.|])
    }
    return(jhat/(nt-d))
}

real matrix _bsrbreak_correct(real matrix reg, real colvector res, real scalar prewhit)
{
    real matrix vmat, bmat, vstar, jh
    real colvector b
    real scalar nt, d, i
    nt = rows(reg)
    d = cols(reg)
    vmat = reg :* res
    if (prewhit == 1) {
        bmat = J(d, d, 0)
        vstar = J(nt-1, d, 0)
        for (i=1; i<=d; i++) {
            b = _bsrbreak_olsqr(vmat[|2,i \ nt,i|], vmat[|1,1 \ nt-1,.|])
            bmat[.,i] = b
            vstar[.,i] = vmat[|2,i \ nt,i|] - vmat[|1,1 \ nt-1,.|]*b
        }
        jh = _bsrbreak_jhatpr(vstar)
        return(luinv(I(d)-bmat)*jh*(luinv(I(d)-bmat))')
    }
    return(_bsrbreak_jhatpr(vmat))
}

// ---------------------------------------------------------------------------
// round half away from zero, exactly as MATLAB round()
// ---------------------------------------------------------------------------
real scalar _bsrbreak_roundm(real scalar x)
{
    real scalar r
    if (x >= 0) {
        r = floor(x)
        if (x - r >= .5) r = r + 1
        return(r)
    }
    r = ceil(x)
    if (r - x >= .5) r = r - 1
    return(r)
}

// ---------------------------------------------------------------------------
// pna_trun.m / pna.m : per-segment degrees of freedom used in pvdel
// meth 2: n - ceil(log(n)) per segment ; meth 3: rounded frequency counts
// ---------------------------------------------------------------------------
real colvector _bsrbreak_pna(real scalar m, real colvector b, real scalar bigt, real scalar meth, real scalar wl, real scalar wh)
{
    real colvector na, jl, jh
    real scalar i, n, L, pa, pb, pv
    na = J(m+1, 1, 0)
    jl = J(m+1, 1, 0)
    jh = J(m+1, 1, 0)
    n = b[1]
    if (meth == 2) {
        L = ceil(ln(n))
        jl[1] = L
        jh[1] = n
    }
    else {
        pb = 2*pi()
        pa = wl*n
        pv = pa/pb
        jl[1] = _bsrbreak_roundm(pv)
        pa = wh*n
        pv = pa/pb
        jh[1] = _bsrbreak_roundm(pv)
    }
    for (i=2; i<=m; i++) {
        n = b[i] - b[i-1]
        if (meth == 2) {
            L = ceil(ln(n))
            jl[i] = L
            jh[i] = n
        }
        else {
            pb = 2*pi()
            pa = wl*n
            pv = pa/pb
            jl[i] = _bsrbreak_roundm(pv)
            pa = wh*n
            pv = pa/pb
            jh[i] = _bsrbreak_roundm(pv)
        }
    }
    n = bigt - b[m]
    if (meth == 2) {
        L = ceil(ln(n))
        jl[m+1] = L
        jh[m+1] = n
    }
    else {
        pb = 2*pi()
        pa = wl*n
        pv = pa/pb
        jl[m+1] = _bsrbreak_roundm(pv)
        pa = wh*n
        pv = pa/pb
        jh[m+1] = _bsrbreak_roundm(pv)
    }
    na = jh - jl
    return(na)
}

// ---------------------------------------------------------------------------
// pvdel.m / pvdel_trun.m / pvdel_bsr.m for the pure structural change case
// replicates the net behavior including the overwrite of the hetdat=0 zeros
// under robust=1 present in the original code
// ---------------------------------------------------------------------------
real matrix _bsrbreak_pvdel(real colvector y, real matrix z, real scalar i, real scalar q, real scalar bigt, real colvector b, real scalar prewhit, real scalar robust, real scalar hetdat, real scalar hetvar, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache)
{
    real colvector ybar, delv, res, na
    real matrix zbar, zfull, reg, vdel, sig, lambda, hc, regj
    real scalar j, seglen
    _bsrbreak_pyzbar(y, z, i, b, meth, wl, wh, cache, nacache, ybar=., zbar=., zfull=., na=.)
    if (meth != 1) na = _bsrbreak_pna(i, b, bigt, meth, wl, wh)
    delv = _bsrbreak_olsqr(ybar, zbar)
    res = ybar - zbar*delv
    reg = zbar
    vdel = J((i+1)*q, (i+1)*q, 0)
    if (robust == 0) {
        if (hetdat==1 & hetvar==0) {
            vdel = (res'*res/bigt) :* luinv(reg'*reg)
        }
        if (hetdat==1 & hetvar==1) {
            sig = _bsrbreak_psigmq(res, b, i, bigt)
            vdel = (sig # I(q)) * luinv(reg'*reg)
        }
        if (hetdat==0 & hetvar==0) {
            lambda = _bsrbreak_plambda(b, i, bigt)
            vdel = (res'*res/bigt) :* luinv(lambda # (zfull'*zfull))
        }
        if (hetdat==0 & hetvar==1) {
            lambda = _bsrbreak_plambda(b, i, bigt)
            sig = _bsrbreak_psigmq(res, b, i, bigt)
            vdel = (sig # I(q)) * luinv(lambda # (zfull'*zfull))
        }
    }
    else {
        if (meth == 1) {
            if (hetvar == 1) {
                hc = J((i+1)*q, (i+1)*q, 0)
                hc[|1,1 \ q,q|] = b[1] :* _bsrbreak_correct(z[|1,1 \ b[1],.|], res[|1 \ b[1]|], prewhit)
                for (j=2; j<=i; j++) {
                    seglen = b[j] - b[j-1]
                    hc[|(j-1)*q+1,(j-1)*q+1 \ j*q,j*q|] = seglen :* _bsrbreak_correct(z[|b[j-1]+1,1 \ b[j],.|], res[|b[j-1]+1 \ b[j]|], prewhit)
                }
                hc[|i*q+1,i*q+1 \ (i+1)*q,(i+1)*q|] = (bigt-b[i]) :* _bsrbreak_correct(z[|b[i]+1,1 \ bigt,.|], res[|b[i]+1 \ bigt|], prewhit)
                vdel = luinv(reg'*reg)*hc*luinv(reg'*reg)
            }
            else {
                hc = _bsrbreak_correct(zfull, res, prewhit)
                lambda = _bsrbreak_plambda(b, i, bigt)
                vdel = bigt :* luinv(reg'*reg)*(lambda # hc)*luinv(reg'*reg)
            }
        }
        else {
            if (hetvar == 1) {
                hc = J((i+1)*q, (i+1)*q, 0)
                hc[|1,1 \ q,q|] = na[1] :* _bsrbreak_correcthc(zfull[|1,1 \ na[1],q|], res[|1 \ na[1]|])
                for (j=2; j<=i; j++) {
                    regj = zfull[|sum(na[|1 \ j-1|])+1,1 \ sum(na[|1 \ j|]),q|]
                    hc[|(j-1)*q+1,(j-1)*q+1 \ j*q,j*q|] = na[j] :* _bsrbreak_correcthc(regj, res[|sum(na[|1 \ j-1|])+1 \ sum(na[|1 \ j|])|])
                }
                regj = zfull[|sum(na[|1 \ i|])+1,1 \ sum(na),q|]
                hc[|i*q+1,i*q+1 \ (i+1)*q,(i+1)*q|] = na[i] :* _bsrbreak_correcthc(regj, res[|sum(na[|1 \ i|])+1 \ sum(na)|])
                vdel = luinv(reg'*reg)*hc*luinv(reg'*reg)
            }
            else {
                hc = _bsrbreak_correcthc(zfull, res)
                lambda = _bsrbreak_plambda(b, i, bigt)
                vdel = bigt :* luinv(reg'*reg)*(lambda # hc)*luinv(reg'*reg)
            }
        }
    }
    return(vdel)
}

// ---------------------------------------------------------------------------
// pftest.m / pftest_trun.m / pftest_bsr.m for the pure structural change case
// ---------------------------------------------------------------------------
real scalar _bsrbreak_pftest(real colvector y, real matrix z, real scalar i, real scalar q, real scalar bigt, real colvector bvec, real scalar prewhit, real scalar robust, real scalar hetdat, real scalar hetvar, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache)
{
    real matrix rsub, rmat, vdel
    real colvector ybar, delta, na
    real matrix zbar, zfull
    real scalar j, fstar
    rsub = J(i, i+1, 0)
    for (j=1; j<=i; j++) {
        rsub[j,j] = -1
        rsub[j,j+1] = 1
    }
    rmat = rsub # I(q)
    _bsrbreak_pyzbar(y, z, i, bvec, meth, wl, wh, cache, nacache, ybar=., zbar=., zfull=., na=.)
    delta = _bsrbreak_olsqr(ybar, zbar)
    vdel = _bsrbreak_pvdel(y, z, i, q, bigt, bvec, prewhit, robust, hetdat, hetvar, meth, wl, wh, cache, nacache)
    fstar = delta'*rmat'*luinv(rmat*vdel*rmat')*rmat*delta
    if (meth == 1) return((bigt-(i+1)*q)*fstar/(bigt*i))
    return((sum(na)-(i+1)*q)*fstar/(bigt*i))
}

// ---------------------------------------------------------------------------
// spflp1.m / spflp1_trun.m / spflp1_bsr.m for the pure structural change case
// ---------------------------------------------------------------------------
void _bsrbreak_spflp1(real colvector bigvec, real colvector dt, real scalar nseg, real colvector y, real matrix z, real scalar h, real scalar q, real scalar prewhit, real scalar robust, real scalar hetdat, real scalar hetvar, real scalar meth, real scalar wl, real scalar wh, pointer(real matrix) colvector cache, real colvector nacache, real scalar maxf, real scalar newd)
{
    real colvector ftestv, dv, ds, bsub
    real scalar bigt, inc, is, seglen, ssris, dsis, news
    ftestv = J(nseg, 1, 0)
    bigt = rows(z)
    dv = J(nseg+1, 1, 0)
    if (nseg >= 2) dv[|2 \ nseg|] = dt
    dv[nseg+1] = bigt
    ds = J(nseg, 1, 0)
    inc = 0
    for (is=1; is<=nseg; is++) {
        seglen = dv[is+1] - dv[is]
        if (seglen >= 2*h) {
            _bsrbreak_parti(dv[is]+1, dv[is]+h, dv[is+1]-h, dv[is+1], bigvec, bigt, ssris=., dsis=.)
            ds[is] = dsis
            bsub = J(1, 1, ds[is]-dv[is])
            ftestv[is] = _bsrbreak_pftest(y[|dv[is]+1 \ dv[is+1]|], z[|dv[is]+1,1 \ dv[is+1],.|], 1, q, seglen, bsub, prewhit, robust, hetdat, hetvar, meth, wl, wh, cache, nacache)
        }
        else {
            inc = inc + 1
            ftestv[is] = 0
        }
    }
    if (inc == nseg) {
        printf("{txt}note: given the location of the breaks from the global optimization there was no more place to insert an additional break satisfying the minimal length requirement\n")
    }
    _bsrbreak_maxfirst(ftestv, maxf=., news=.)
    newd = ds[news]
}

// ---------------------------------------------------------------------------
// main driver
// ---------------------------------------------------------------------------
void _bsrbreak_main(string scalar yname, string scalar xnames, string scalar tousename, string scalar touseyname, string scalar tvname, real scalar meth, real scalar wlpi, real scalar whpi, real scalar m, real scalar h, real scalar robust, real scalar hetdat, real scalar hetvar, real scalar prewhit, real scalar ieps, real scalar demean, real scalar dtcode)
{
    real colvector y, glb, bigvec, nacache, tvals, trend, yw
    real matrix z, datevec, cv5, cvsupf, cvseq, cvdmax, supfseq, cv
    real colvector ftest, wftest
    real scalar bigt, q, wl, wh, i, s, udmax, wdmax, dum, supfl, ndat, nw
    pointer(real matrix) colvector cache
    y = st_data(., yname, tousename)
    z = st_data(., tokens(xnames), tousename)
    tvals = st_data(., tvname, tousename)
    bigt = rows(y)
    q = cols(z)
    if (dtcode == 1) {
        yw = st_data(., yname, touseyname)
        nw = rows(yw)
        trend = (1::nw)
        yw = yw - trend * (luinv(trend'*trend) * (trend'*yw))
        y = yw[|nw-bigt+1 \ nw|]
    }
    if (demean == 1) {
        y = y :- mean(y)
        z = z :- mean(z)
    }
    wl = wlpi*pi()
    wh = whpi*pi()
    cache = J(bigt, 1, NULL)
    nacache = J(bigt, 1, .)
    _bsrbreak_dating(y, z, h, m, bigt, meth, wl, wh, cache, nacache, glb=., datevec=., bigvec=.)
    ftest = J(m, 1, 0)
    wftest = J(m, 1, 0)
    cv5 = _bsrbreak_getcv1(ieps, 2)
    for (i=1; i<=m; i++) {
        ftest[i] = _bsrbreak_pftest(y, z, i, q, bigt, datevec[|1,i \ i,i|], prewhit, robust, hetdat, hetvar, meth, wl, wh, cache, nacache)
        wftest[i] = cv5[q,1]*ftest[i]/cv5[q,i]
    }
    _bsrbreak_maxfirst(ftest, udmax=., dum=.)
    _bsrbreak_maxfirst(wftest, wdmax=., dum=.)
    if (m >= 2) {
        supfseq = J(m-1, 2, .)
        for (i=1; i<=m-1; i++) {
            _bsrbreak_spflp1(bigvec, datevec[|1,i \ i,i|], i+1, y, z, h, q, prewhit, robust, hetdat, hetvar, meth, wl, wh, cache, nacache, supfl=., ndat=.)
            supfseq[i,1] = supfl
            supfseq[i,2] = ndat
        }
        st_matrix("__bsrb_supfseq", supfseq)
    }
    cvsupf = J(4, m, .)
    cvseq = J(4, m, .)
    cvdmax = J(4, 2, .)
    for (s=1; s<=4; s++) {
        cv = _bsrbreak_getcv1(ieps, s)
        cvsupf[s,.] = cv[|q,1 \ q,m|]
        cv = _bsrbreak_getcv2(ieps, s)
        cvseq[s,.] = cv[|q,1 \ q,m|]
        cv = _bsrbreak_getdmax(ieps, s)
        cvdmax[s,.] = cv[q,.]
    }
    st_matrix("__bsrb_supf", ftest)
    st_matrix("__bsrb_wsupf", wftest)
    st_matrix("__bsrb_glb", glb)
    st_matrix("__bsrb_datevec", datevec)
    st_matrix("__bsrb_cvsupf", cvsupf)
    st_matrix("__bsrb_cvseq", cvseq)
    st_matrix("__bsrb_cvdmax", cvdmax)
    st_matrix("__bsrb_tvals", tvals)
    st_numscalar("__bsrb_udmax", udmax)
    st_numscalar("__bsrb_wdmax", wdmax)
}

real matrix _bsrbreak_getcv1(real scalar ieps, real scalar signif)
{
    real matrix cv
    if (ieps==1 & signif==1) {
        cv = J(10, 9, .)
        cv[1,.] = (8.02, 7.87, 7.07, 6.61, 6.14, 5.74, 5.4, 5.09, 4.81)
        cv[2,.] = (11.02, 10.48, 9.61, 8.99, 8.5, 8.06, 7.66, 7.32, 7.01)
        cv[3,.] = (13.43, 12.73, 11.76, 11.04, 10.49, 10.02, 9.59, 9.21, 8.86)
        cv[4,.] = (15.53, 14.65, 13.63, 12.91, 12.33, 11.79, 11.34, 10.93, 10.55)
        cv[5,.] = (17.42, 16.45, 15.44, 14.69, 14.05, 13.51, 13.02, 12.59, 12.18)
        cv[6,.] = (19.38, 18.15, 17.17, 16.39, 15.74, 15.18, 14.63, 14.18, 13.74)
        cv[7,.] = (21.23, 19.93, 18.75, 17.98, 17.28, 16.69, 16.16, 15.69, 15.24)
        cv[8,.] = (22.92, 21.56, 20.43, 19.58, 18.84, 18.21, 17.69, 17.19, 16.7)
        cv[9,.] = (24.75, 23.15, 21.98, 21.12, 20.37, 19.72, 19.13, 18.58, 18.09)
        cv[10,.] = (26.13, 24.7, 23.48, 22.57, 21.83, 21.16, 20.57, 20.03, 19.55)
        return(cv)
    }
    if (ieps==1 & signif==2) {
        cv = J(10, 9, .)
        cv[1,.] = (9.63, 8.78, 7.85, 7.21, 6.69, 6.23, 5.86, 5.51, 5.2)
        cv[2,.] = (12.89, 11.6, 10.46, 9.71, 9.12, 8.65, 8.19, 7.79, 7.46)
        cv[3,.] = (15.37, 13.84, 12.64, 11.83, 11.15, 10.61, 10.14, 9.71, 9.32)
        cv[4,.] = (17.6, 15.84, 14.63, 13.71, 12.99, 12.42, 11.91, 11.49, 11.04)
        cv[5,.] = (19.5, 17.6, 16.4, 15.52, 14.79, 14.19, 13.63, 13.16, 12.7)
        cv[6,.] = (21.59, 19.61, 18.23, 17.27, 16.5, 15.86, 15.29, 14.77, 14.3)
        cv[7,.] = (23.5, 21.3, 19.83, 18.91, 18.1, 17.43, 16.83, 16.28, 15.79)
        cv[8,.] = (25.22, 23.03, 21.48, 20.46, 19.66, 18.97, 18.37, 17.8, 17.3)
        cv[9,.] = (27.08, 24.55, 23.16, 22.08, 21.22, 20.49, 19.9, 19.29, 18.79)
        cv[10,.] = (28.49, 26.17, 24.59, 23.59, 22.71, 21.93, 21.34, 20.74, 20.17)
        return(cv)
    }
    if (ieps==1 & signif==3) {
        cv = J(10, 9, .)
        cv[1,.] = (11.17, 9.81, 8.52, 7.79, 7.22, 6.7, 6.27, 5.92, 5.56)
        cv[2,.] = (14.53, 12.64, 11.2, 10.29, 9.69, 9.1, 8.64, 8.18, 7.8)
        cv[3,.] = (17.17, 14.91, 13.44, 12.49, 11.75, 11.13, 10.62, 10.14, 9.72)
        cv[4,.] = (19.35, 16.85, 15.44, 14.43, 13.64, 13.01, 12.46, 11.94, 11.49)
        cv[5,.] = (21.47, 18.75, 17.26, 16.13, 15.4, 14.75, 14.19, 13.66, 13.17)
        cv[6,.] = (23.73, 20.8, 19.15, 18.07, 17.21, 16.49, 15.84, 15.29, 14.78)
        cv[7,.] = (25.23, 22.54, 20.85, 19.68, 18.79, 18.03, 17.38, 16.79, 16.31)
        cv[8,.] = (27.21, 24.2, 22.41, 21.29, 20.39, 19.63, 18.98, 18.34, 17.78)
        cv[9,.] = (29.13, 25.92, 24.14, 22.97, 21.98, 21.28, 20.59, 19.98, 19.39)
        cv[10,.] = (30.67, 27.52, 25.69, 24.47, 23.45, 22.71, 21.95, 21.34, 20.79)
        return(cv)
    }
    if (ieps==1 & signif==4) {
        cv = J(10, 9, .)
        cv[1,.] = (13.58, 10.95, 9.37, 8.5, 7.85, 7.21, 6.75, 6.33, 5.98)
        cv[2,.] = (16.64, 13.78, 12.06, 11, 10.28, 9.65, 9.11, 8.66, 8.22)
        cv[3,.] = (19.25, 16.27, 14.48, 13.4, 12.56, 11.8, 11.22, 10.67, 10.19)
        cv[4,.] = (21.2, 18.21, 16.43, 15.21, 14.45, 13.7, 13.04, 12.48, 12.02)
        cv[5,.] = (23.99, 20.18, 18.19, 17.09, 16.14, 15.34, 14.81, 14.26, 13.72)
        cv[6,.] = (25.95, 22.18, 20.29, 18.93, 17.97, 17.2, 16.54, 15.94, 15.35)
        cv[7,.] = (28.01, 24.07, 21.89, 20.68, 19.68, 18.81, 18.1, 17.49, 16.96)
        cv[8,.] = (29.6, 25.66, 23.44, 22.22, 21.22, 20.4, 19.66, 19.03, 18.46)
        cv[9,.] = (31.66, 27.42, 25.13, 24.01, 23.06, 22.18, 21.35, 20.63, 19.94)
        cv[10,.] = (33.62, 29.14, 26.9, 25.58, 24.44, 23.49, 22.75, 22.09, 21.47)
        return(cv)
    }
    if (ieps==2 & signif==1) {
        cv = J(10, 8, .)
        cv[1,.] = (7.42, 6.93, 6.09, 5.44, 4.85, 4.32, 3.83, 3.22)
        cv[2,.] = (10.37, 9.43, 8.48, 7.68, 7.02, 6.37, 5.77, 4.98)
        cv[3,.] = (12.77, 11.61, 10.53, 9.69, 8.94, 8.21, 7.49, 6.57)
        cv[4,.] = (14.81, 13.56, 12.36, 11.43, 10.61, 9.86, 9.04, 8.01)
        cv[5,.] = (16.65, 15.32, 14.06, 13.1, 12.2, 11.4, 10.54, 9.4)
        cv[6,.] = (18.65, 17.01, 15.75, 14.7, 13.78, 12.92, 11.98, 10.8)
        cv[7,.] = (20.34, 18.71, 17.26, 16.19, 15.26, 14.35, 13.4, 12.13)
        cv[8,.] = (22.01, 20.32, 18.9, 17.75, 16.79, 15.82, 14.8, 13.45)
        cv[9,.] = (23.79, 21.88, 20.43, 19.28, 18.22, 17.24, 16.19, 14.77)
        cv[10,.] = (25.29, 23.33, 21.89, 20.71, 19.63, 18.59, 17.5, 16)
        return(cv)
    }
    if (ieps==2 & signif==2) {
        cv = J(10, 8, .)
        cv[1,.] = (9.1, 7.92, 6.84, 6.03, 5.37, 4.8, 4.23, 3.58)
        cv[2,.] = (12.25, 10.58, 9.29, 8.37, 7.62, 6.9, 6.21, 5.41)
        cv[3,.] = (14.6, 12.82, 11.46, 10.41, 9.59, 8.8, 8.01, 7.03)
        cv[4,.] = (16.76, 14.72, 13.3, 12.25, 11.29, 10.42, 9.58, 8.46)
        cv[5,.] = (18.68, 16.5, 15.07, 13.93, 13, 12.1, 11.16, 9.96)
        cv[6,.] = (20.76, 18.32, 16.81, 15.67, 14.65, 13.68, 12.63, 11.34)
        cv[7,.] = (22.62, 20.04, 18.45, 17.19, 16.14, 15.11, 14.09, 12.71)
        cv[8,.] = (24.34, 21.69, 20.01, 18.74, 17.66, 16.65, 15.54, 14.07)
        cv[9,.] = (26.2, 23.36, 21.63, 20.32, 19.19, 18.09, 16.89, 15.4)
        cv[10,.] = (27.64, 24.87, 23.11, 21.79, 20.58, 19.47, 18.29, 16.7)
        return(cv)
    }
    if (ieps==2 & signif==3) {
        cv = J(10, 8, .)
        cv[1,.] = (10.56, 8.9, 7.55, 6.64, 5.88, 5.22, 4.61, 3.9)
        cv[2,.] = (13.86, 11.63, 10.14, 9.05, 8.17, 7.4, 6.63, 5.73)
        cv[3,.] = (16.55, 13.9, 12.35, 11.12, 10.19, 9.28, 8.43, 7.4)
        cv[4,.] = (18.62, 15.88, 14.22, 12.96, 11.94, 11.05, 10.06, 8.93)
        cv[5,.] = (20.59, 17.71, 16.02, 14.68, 13.67, 12.71, 11.68, 10.42)
        cv[6,.] = (23.05, 19.69, 17.82, 16.47, 15.31, 14.24, 13.2, 11.89)
        cv[7,.] = (24.65, 21.34, 19.41, 18.13, 16.9, 15.84, 14.67, 13.25)
        cv[8,.] = (26.5, 22.98, 20.95, 19.69, 18.52, 17.35, 16.15, 14.67)
        cv[9,.] = (28.25, 24.73, 22.68, 21.29, 20.01, 18.76, 17.56, 16)
        cv[10,.] = (29.8, 26.37, 24.27, 22.71, 21.42, 20.21, 18.94, 17.33)
        return(cv)
    }
    if (ieps==2 & signif==4) {
        cv = J(10, 8, .)
        cv[1,.] = (13, 10.14, 8.42, 7.31, 6.48, 5.74, 5.05, 4.28)
        cv[2,.] = (16.19, 12.9, 11.12, 9.87, 8.84, 8.01, 7.18, 6.18)
        cv[3,.] = (18.72, 15.38, 13.38, 11.97, 10.93, 9.94, 8.99, 7.85)
        cv[4,.] = (20.75, 17.24, 15.3, 13.93, 12.78, 11.67, 10.64, 9.47)
        cv[5,.] = (23.12, 18.93, 16.91, 15.61, 14.42, 13.31, 12.3, 11)
        cv[6,.] = (25.5, 21.15, 19.04, 17.48, 16.19, 15.11, 13.88, 12.55)
        cv[7,.] = (27.19, 22.97, 20.68, 19.14, 17.81, 16.59, 15.43, 13.92)
        cv[8,.] = (29.01, 24.51, 22.4, 20.68, 19.41, 18.08, 16.83, 15.3)
        cv[9,.] = (30.81, 26.3, 23.95, 22.33, 20.88, 19.56, 18.35, 16.79)
        cv[10,.] = (32.8, 28.24, 25.63, 23.83, 22.32, 21.04, 19.73, 18.1)
        return(cv)
    }
    if (ieps==3 & signif==1) {
        cv = J(10, 5, .)
        cv[1,.] = (7.04, 6.28, 5.21, 4.41, 3.47)
        cv[2,.] = (9.81, 8.63, 7.54, 6.51, 5.27)
        cv[3,.] = (12.08, 10.75, 9.51, 8.29, 6.9)
        cv[4,.] = (14.26, 12.6, 11.21, 9.97, 8.37)
        cv[5,.] = (16.14, 14.37, 12.9, 11.5, 9.79)
        cv[6,.] = (17.97, 16.02, 14.45, 13, 11.19)
        cv[7,.] = (19.7, 17.67, 16.04, 14.55, 12.59)
        cv[8,.] = (21.41, 19.16, 17.47, 15.88, 13.89)
        cv[9,.] = (23.06, 20.82, 19.07, 17.38, 15.23)
        cv[10,.] = (24.65, 22.26, 20.42, 18.73, 16.54)
        return(cv)
    }
    if (ieps==3 & signif==2) {
        cv = J(10, 5, .)
        cv[1,.] = (8.58, 7.22, 5.96, 4.99, 3.91)
        cv[2,.] = (11.47, 9.75, 8.36, 7.19, 5.85)
        cv[3,.] = (13.98, 11.99, 10.39, 9.05, 7.46)
        cv[4,.] = (16.19, 13.77, 12.17, 10.79, 9.09)
        cv[5,.] = (18.23, 15.62, 13.93, 12.38, 10.52)
        cv[6,.] = (20.08, 17.37, 15.58, 13.9, 11.94)
        cv[7,.] = (21.87, 18.98, 17.23, 15.55, 13.4)
        cv[8,.] = (23.7, 20.62, 18.69, 16.96, 14.77)
        cv[9,.] = (25.65, 22.35, 20.18, 18.4, 16.11)
        cv[10,.] = (27.03, 23.8, 21.62, 19.79, 17.44)
        return(cv)
    }
    if (ieps==3 & signif==3) {
        cv = J(10, 5, .)
        cv[1,.] = (10.18, 8.14, 6.72, 5.51, 4.34)
        cv[2,.] = (12.96, 10.75, 9.15, 7.81, 6.38)
        cv[3,.] = (15.76, 13.13, 11.23, 9.72, 8.03)
        cv[4,.] = (18.13, 14.99, 13.06, 11.55, 9.66)
        cv[5,.] = (19.95, 16.92, 14.98, 13.25, 11.21)
        cv[6,.] = (22.15, 18.62, 16.5, 14.68, 12.63)
        cv[7,.] = (24.2, 20.4, 18.25, 16.41, 14.18)
        cv[8,.] = (25.77, 21.97, 19.71, 17.91, 15.52)
        cv[9,.] = (27.69, 23.68, 21.28, 19.29, 16.88)
        cv[10,.] = (29.27, 24.99, 22.74, 20.81, 18.26)
        return(cv)
    }
    if (ieps==3 & signif==4) {
        cv = J(10, 5, .)
        cv[1,.] = (12.29, 9.36, 7.6, 6.19, 4.91)
        cv[2,.] = (15.37, 12.15, 10.27, 8.65, 7)
        cv[3,.] = (18.26, 14.45, 12.16, 10.56, 8.71)
        cv[4,.] = (20.23, 16.55, 14.26, 12.42, 10.53)
        cv[5,.] = (22.4, 18.37, 16.16, 14.25, 12.14)
        cv[6,.] = (24.45, 20.06, 17.57, 15.73, 13.44)
        cv[7,.] = (26.71, 21.87, 19.42, 17.44, 15.02)
        cv[8,.] = (28.51, 23.58, 20.96, 19, 16.56)
        cv[9,.] = (30.62, 25.32, 22.72, 20.38, 17.87)
        cv[10,.] = (32.16, 26.82, 24.41, 22.09, 19.27)
        return(cv)
    }
    if (ieps==4 & signif==1) {
        cv = J(10, 3, .)
        cv[1,.] = (6.72, 5.59, 4.37)
        cv[2,.] = (9.37, 7.91, 6.43)
        cv[3,.] = (11.59, 9.93, 8.21)
        cv[4,.] = (13.72, 11.7, 9.9)
        cv[5,.] = (15.51, 13.46, 11.5)
        cv[6,.] = (17.39, 15.05, 12.91)
        cv[7,.] = (19.11, 16.67, 14.46)
        cv[8,.] = (20.86, 18.16, 15.88)
        cv[9,.] = (22.38, 19.71, 17.3)
        cv[10,.] = (23.95, 21.13, 18.65)
        return(cv)
    }
    if (ieps==4 & signif==2) {
        cv = J(10, 3, .)
        cv[1,.] = (8.22, 6.53, 5.08)
        cv[2,.] = (10.98, 8.98, 7.13)
        cv[3,.] = (13.47, 11.09, 9.12)
        cv[4,.] = (15.67, 12.94, 10.78)
        cv[5,.] = (17.66, 14.69, 12.45)
        cv[6,.] = (19.55, 16.35, 13.91)
        cv[7,.] = (21.33, 18.14, 15.55)
        cv[8,.] = (23.19, 19.58, 17.1)
        cv[9,.] = (24.91, 21.23, 18.58)
        cv[10,.] = (26.38, 22.62, 19.91)
        return(cv)
    }
    if (ieps==4 & signif==3) {
        cv = J(10, 3, .)
        cv[1,.] = (9.77, 7.49, 5.73)
        cv[2,.] = (12.59, 10, 7.92)
        cv[3,.] = (15.28, 12.25, 9.91)
        cv[4,.] = (17.67, 14.11, 11.66)
        cv[5,.] = (19.51, 15.96, 13.49)
        cv[6,.] = (21.47, 17.66, 14.97)
        cv[7,.] = (23.36, 19.41, 16.56)
        cv[8,.] = (25.26, 20.94, 18.03)
        cv[9,.] = (26.96, 22.69, 19.51)
        cv[10,.] = (28.62, 24.04, 20.96)
        return(cv)
    }
    if (ieps==4 & signif==4) {
        cv = J(10, 3, .)
        cv[1,.] = (11.94, 8.77, 6.58)
        cv[2,.] = (14.92, 11.3, 8.95)
        cv[3,.] = (17.6, 13.4, 10.91)
        cv[4,.] = (19.82, 15.74, 12.99)
        cv[5,.] = (21.75, 17.21, 14.6)
        cv[6,.] = (23.8, 19.25, 16.29)
        cv[7,.] = (26.16, 21.03, 17.81)
        cv[8,.] = (27.71, 22.71, 19.37)
        cv[9,.] = (29.67, 24.43, 20.74)
        cv[10,.] = (31.38, 25.73, 22.34)
        return(cv)
    }
    if (ieps==5 & signif==1) {
        cv = J(10, 2, .)
        cv[1,.] = (6.35, 4.88)
        cv[2,.] = (8.96, 7.06)
        cv[3,.] = (11.17, 9.01)
        cv[4,.] = (13.22, 10.74)
        cv[5,.] = (14.98, 12.39)
        cv[6,.] = (16.77, 13.96)
        cv[7,.] = (18.45, 15.53)
        cv[8,.] = (20.15, 16.91)
        cv[9,.] = (21.69, 18.42)
        cv[10,.] = (23.29, 19.84)
        return(cv)
    }
    if (ieps==5 & signif==2) {
        cv = J(10, 2, .)
        cv[1,.] = (7.86, 5.8)
        cv[2,.] = (10.55, 8.17)
        cv[3,.] = (13.04, 10.16)
        cv[4,.] = (15.19, 11.91)
        cv[5,.] = (17.12, 13.65)
        cv[6,.] = (18.97, 15.38)
        cv[7,.] = (20.75, 16.97)
        cv[8,.] = (22.56, 18.43)
        cv[9,.] = (24.18, 19.93)
        cv[10,.] = (25.77, 21.34)
        return(cv)
    }
    if (ieps==5 & signif==3) {
        cv = J(10, 2, .)
        cv[1,.] = (9.32, 6.69)
        cv[2,.] = (12.21, 9.16)
        cv[3,.] = (14.66, 11.22)
        cv[4,.] = (17.04, 13)
        cv[5,.] = (18.96, 14.86)
        cv[6,.] = (20.93, 16.53)
        cv[7,.] = (22.85, 18.25)
        cv[8,.] = (24.56, 19.68)
        cv[9,.] = (26.31, 21.38)
        cv[10,.] = (27.8, 22.79)
        return(cv)
    }
    if (ieps==5 & signif==4) {
        cv = J(10, 2, .)
        cv[1,.] = (11.44, 7.92)
        cv[2,.] = (14.34, 10.3)
        cv[3,.] = (17.08, 12.55)
        cv[4,.] = (19.22, 14.65)
        cv[5,.] = (21.51, 16.18)
        cv[6,.] = (23.12, 18.1)
        cv[7,.] = (25.67, 19.91)
        cv[8,.] = (27.1, 21.41)
        cv[9,.] = (29.12, 23.23)
        cv[10,.] = (30.86, 24.51)
        return(cv)
    }
    return(J(0,0,.))
}

real matrix _bsrbreak_getcv2(real scalar ieps, real scalar signif)
{
    real matrix cv
    if (ieps==1 & signif==1) {
        cv = J(10, 10, .)
        cv[1,.] = (8.02, 9.56, 10.45, 11.07, 11.65, 12.07, 12.47, 12.7, 13.07, 13.34)
        cv[2,.] = (11.02, 12.79, 13.72, 14.45, 14.9, 15.35, 15.81, 16.12, 16.44, 16.58)
        cv[3,.] = (13.43, 15.26, 16.38, 17.07, 17.52, 17.91, 18.35, 18.61, 18.92, 19.19)
        cv[4,.] = (15.53, 17.54, 18.55, 19.3, 19.8, 20.15, 20.48, 20.73, 20.94, 21.1)
        cv[5,.] = (17.42, 19.38, 20.46, 21.37, 21.96, 22.47, 22.77, 23.23, 23.56, 23.81)
        cv[6,.] = (19.38, 21.51, 22.81, 23.64, 24.19, 24.59, 24.86, 25.27, 25.53, 25.87)
        cv[7,.] = (21.23, 23.41, 24.51, 25.07, 25.75, 26.3, 26.74, 27.06, 27.46, 27.7)
        cv[8,.] = (22.92, 25.15, 26.38, 27.09, 27.77, 28.15, 28.61, 28.9, 29.19, 29.49)
        cv[9,.] = (24.75, 26.99, 28.11, 29.03, 29.69, 30.18, 30.61, 30.93, 31.14, 31.46)
        cv[10,.] = (26.13, 28.4, 29.68, 30.62, 31.25, 31.81, 32.37, 32.78, 33.09, 33.53)
        return(cv)
    }
    if (ieps==1 & signif==2) {
        cv = J(10, 10, .)
        cv[1,.] = (9.63, 11.14, 12.16, 12.83, 13.45, 14.05, 14.29, 14.5, 14.69, 14.88)
        cv[2,.] = (12.89, 14.5, 15.42, 16.16, 16.61, 17.02, 17.27, 17.55, 17.76, 17.97)
        cv[3,.] = (15.37, 17.15, 17.97, 18.72, 19.23, 19.59, 19.94, 20.31, 21.05, 21.2)
        cv[4,.] = (17.6, 19.33, 20.22, 20.75, 21.15, 21.55, 21.9, 22.27, 22.63, 22.83)
        cv[5,.] = (19.5, 21.43, 22.57, 23.33, 23.9, 24.34, 24.62, 25.14, 25.34, 25.51)
        cv[6,.] = (21.59, 23.72, 24.66, 25.29, 25.89, 26.36, 26.84, 27.1, 27.26, 27.4)
        cv[7,.] = (23.5, 25.17, 26.34, 27.19, 27.96, 28.25, 28.64, 28.84, 28.97, 29.14)
        cv[8,.] = (25.22, 27.18, 28.21, 28.99, 29.54, 30.05, 30.45, 30.79, 31.29, 31.75)
        cv[9,.] = (27.08, 29.1, 30.24, 30.99, 31.48, 32.46, 32.71, 32.89, 33.15, 33.43)
        cv[10,.] = (28.49, 30.65, 31.9, 32.83, 33.57, 34.27, 34.53, 35.01, 35.33, 35.65)
        return(cv)
    }
    if (ieps==1 & signif==3) {
        cv = J(10, 10, .)
        cv[1,.] = (11.17, 12.88, 14.05, 14.5, 15.03, 15.37, 15.56, 15.73, 16.02, 16.39)
        cv[2,.] = (14.53, 16.19, 17.02, 17.55, 17.98, 18.15, 18.46, 18.74, 18.98, 19.22)
        cv[3,.] = (17.17, 18.75, 19.61, 20.31, 21.33, 21.59, 21.78, 22.07, 22.41, 22.73)
        cv[4,.] = (19.35, 20.76, 21.6, 22.27, 22.84, 23.44, 23.74, 24.14, 24.36, 24.54)
        cv[5,.] = (21.47, 23.34, 24.37, 25.14, 25.58, 25.79, 25.96, 26.39, 26.6, 26.84)
        cv[6,.] = (23.73, 25.41, 26.37, 27.1, 27.42, 28.02, 28.39, 28.75, 29.13, 29.44)
        cv[7,.] = (25.23, 27.24, 28.25, 28.84, 29.14, 29.72, 30.41, 30.76, 31.09, 31.43)
        cv[8,.] = (27.21, 29.01, 30.09, 30.79, 31.8, 32.5, 32.81, 32.86, 33.2, 33.6)
        cv[9,.] = (29.13, 31.04, 32.48, 32.89, 33.47, 33.98, 34.25, 34.74, 34.88, 35.07)
        cv[10,.] = (30.67, 32.87, 34.27, 35.01, 35.86, 36.32, 36.65, 36.9, 37.15, 37.41)
        return(cv)
    }
    if (ieps==1 & signif==4) {
        cv = J(10, 10, .)
        cv[1,.] = (13.58, 15.03, 15.62, 16.39, 16.6, 16.9, 17.04, 17.27, 17.32, 17.61)
        cv[2,.] = (16.64, 17.98, 18.66, 19.22, 20.03, 20.87, 20.97, 21.19, 21.43, 21.74)
        cv[3,.] = (19.25, 21.33, 22.01, 22.73, 23.13, 23.48, 23.7, 23.79, 23.84, 24.59)
        cv[4,.] = (21.2, 22.84, 24.04, 24.54, 24.96, 25.36, 25.51, 25.58, 25.63, 25.88)
        cv[5,.] = (23.99, 25.58, 26.32, 26.84, 27.39, 27.86, 27.9, 28.32, 28.38, 28.39)
        cv[6,.] = (25.95, 27.42, 28.6, 29.44, 30.18, 30.52, 30.64, 30.99, 31.25, 31.33)
        cv[7,.] = (28.01, 29.14, 30.61, 31.43, 32.56, 32.75, 32.9, 33.25, 33.25, 33.85)
        cv[8,.] = (29.6, 31.8, 32.84, 33.6, 34.23, 34.57, 34.75, 35.01, 35.5, 35.65)
        cv[9,.] = (31.66, 33.47, 34.6, 35.07, 35.49, 37.08, 37.12, 37.23, 37.47, 37.68)
        cv[10,.] = (33.62, 35.86, 36.68, 37.41, 38.2, 38.7, 38.91, 39.09, 39.11, 39.12)
        return(cv)
    }
    if (ieps==2 & signif==1) {
        cv = J(10, 10, .)
        cv[1,.] = (7.42, 9.05, 9.97, 10.49, 10.91, 11.29, 11.86, 12.26, 12.57, 12.84)
        cv[2,.] = (10.37, 12.19, 13.2, 13.79, 14.37, 14.68, 15.07, 15.42, 15.81, 16.09)
        cv[3,.] = (12.77, 14.54, 15.64, 16.46, 16.94, 17.35, 17.68, 17.93, 18.35, 18.55)
        cv[4,.] = (14.81, 16.7, 17.84, 18.51, 19.13, 19.5, 19.93, 20.15, 20.46, 20.67)
        cv[5,.] = (16.65, 18.61, 19.74, 20.46, 21.04, 21.56, 21.96, 22.46, 22.72, 22.96)
        cv[6,.] = (18.65, 20.63, 22.03, 22.9, 23.57, 24.08, 24.38, 24.73, 25.1, 25.29)
        cv[7,.] = (20.34, 22.55, 23.84, 24.59, 24.97, 25.48, 26.18, 26.48, 26.86, 26.97)
        cv[8,.] = (22.01, 24.24, 25.49, 26.31, 26.98, 27.55, 27.92, 28.16, 28.64, 28.89)
        cv[9,.] = (23.79, 26.14, 27.34, 28.16, 28.83, 29.33, 29.86, 30.23, 30.46, 30.74)
        cv[10,.] = (25.29, 27.59, 28.75, 29.71, 30.35, 30.99, 31.41, 31.82, 32.25, 32.61)
        return(cv)
    }
    if (ieps==2 & signif==2) {
        cv = J(10, 10, .)
        cv[1,.] = (9.1, 10.55, 11.36, 12.35, 12.97, 13.45, 13.88, 14.12, 14.45, 14.51)
        cv[2,.] = (12.25, 13.83, 14.73, 15.46, 16.13, 16.55, 16.82, 17.07, 17.34, 17.58)
        cv[3,.] = (14.6, 16.53, 17.43, 17.98, 18.61, 19.02, 19.25, 19.61, 19.94, 20.35)
        cv[4,.] = (16.76, 18.56, 19.53, 20.24, 20.72, 21.13, 21.55, 21.83, 22.08, 22.4)
        cv[5,.] = (18.68, 20.57, 21.6, 22.55, 23, 23.63, 24.13, 24.48, 24.82, 25.14)
        cv[6,.] = (20.76, 23.01, 24.14, 24.77, 25.48, 25.89, 26.25, 26.77, 26.96, 27.14)
        cv[7,.] = (22.62, 24.64, 25.57, 26.54, 27.04, 27.51, 28.14, 28.44, 28.74, 28.87)
        cv[8,.] = (24.34, 26.42, 27.66, 28.25, 28.99, 29.34, 29.86, 30.29, 30.5, 30.68)
        cv[9,.] = (26.2, 28.23, 29.44, 30.31, 30.77, 31.35, 31.91, 32.6, 32.71, 32.86)
        cv[10,.] = (27.64, 29.78, 31.02, 31.9, 32.71, 33.32, 33.95, 34.29, 34.52, 34.81)
        return(cv)
    }
    if (ieps==2 & signif==3) {
        cv = J(10, 10, .)
        cv[1,.] = (10.56, 12.37, 13.46, 14.13, 14.51, 14.88, 15.37, 15.47, 15.62, 15.79)
        cv[2,.] = (13.86, 15.51, 16.55, 17.07, 17.58, 17.98, 18.19, 18.55, 18.92, 19.02)
        cv[3,.] = (16.55, 17.99, 19.06, 19.65, 20.35, 21.4, 21.57, 21.76, 22.07, 22.53)
        cv[4,.] = (18.62, 20.3, 21.18, 21.86, 22.4, 22.83, 23.42, 23.63, 23.77, 24.14)
        cv[5,.] = (20.59, 22.57, 23.66, 24.5, 25.14, 25.46, 25.77, 25.87, 26.02, 26.34)
        cv[6,.] = (23.05, 24.79, 25.91, 26.8, 27.14, 27.42, 27.85, 28.1, 28.55, 28.89)
        cv[7,.] = (24.65, 26.56, 27.53, 28.51, 28.87, 29.08, 29.43, 29.85, 30.35, 30.68)
        cv[8,.] = (26.5, 28.29, 29.36, 30.34, 30.68, 31.82, 32.42, 32.64, 32.82, 33.08)
        cv[9,.] = (28.25, 30.31, 31.41, 32.6, 32.86, 33.39, 33.79, 34, 34.35, 34.75)
        cv[10,.] = (29.8, 31.9, 33.34, 34.31, 34.81, 35.65, 36.23, 36.36, 36.65, 36.72)
        return(cv)
    }
    if (ieps==2 & signif==4) {
        cv = J(10, 10, .)
        cv[1,.] = (13, 14.51, 15.44, 15.73, 16.39, 16.6, 16.78, 16.9, 16.99, 17.04)
        cv[2,.] = (16.19, 17.58, 18.31, 18.98, 19.63, 20.09, 20.3, 20.87, 20.97, 21.13)
        cv[3,.] = (18.72, 20.35, 21.6, 22.35, 22.96, 23.37, 23.53, 23.71, 23.79, 23.84)
        cv[4,.] = (20.75, 22.4, 23.55, 24.13, 24.54, 24.96, 25.11, 25.5, 25.56, 25.58)
        cv[5,.] = (23.12, 25.14, 25.79, 26.32, 26.6, 26.96, 27.39, 27.51, 27.75, 27.75)
        cv[6,.] = (25.5, 27.14, 27.92, 28.75, 29.44, 30.12, 30.18, 30.29, 30.52, 30.64)
        cv[7,.] = (27.19, 28.87, 29.51, 30.43, 31.38, 32.56, 32.62, 32.87, 32.9, 33.25)
        cv[8,.] = (29.01, 30.68, 32.52, 32.86, 33.27, 34.1, 34.26, 34.38, 34.57, 34.72)
        cv[9,.] = (30.81, 32.86, 33.92, 34.6, 35.07, 35.66, 37.08, 37.12, 37.22, 37.23)
        cv[10,.] = (32.8, 34.81, 36.32, 36.65, 37.15, 38.2, 38.6, 38.7, 38.8, 39.09)
        return(cv)
    }
    if (ieps==3 & signif==1) {
        cv = J(10, 10, .)
        cv[1,.] = (7.04, 8.51, 9.41, 10.04, 10.58, 11.03, 11.43, 11.75, 12.01, 12.2)
        cv[2,.] = (9.81, 11.4, 12.29, 12.9, 13.47, 13.98, 14.36, 14.7, 15.11, 15.28)
        cv[3,.] = (12.08, 13.91, 14.96, 15.68, 16.35, 16.81, 17.24, 17.51, 17.87, 18.12)
        cv[4,.] = (14.26, 16.11, 17.31, 18, 18.45, 18.84, 19.22, 19.61, 19.92, 20.07)
        cv[5,.] = (16.14, 18.14, 19.1, 19.84, 20.5, 20.96, 21.42, 21.68, 21.95, 22.28)
        cv[6,.] = (17.97, 20.01, 21.16, 22.08, 22.64, 23.02, 23.35, 23.7, 24.1, 24.37)
        cv[7,.] = (19.7, 21.79, 22.87, 24.06, 24.68, 25.1, 25.66, 25.97, 26.29, 26.5)
        cv[8,.] = (21.41, 23.62, 24.74, 25.63, 26.39, 26.73, 27.29, 27.56, 28.06, 28.46)
        cv[9,.] = (23.06, 25.54, 26.68, 27.6, 28.25, 28.79, 29.19, 29.52, 29.94, 30.43)
        cv[10,.] = (24.65, 26.92, 28.26, 29.18, 29.88, 30.4, 30.9, 31.4, 31.75, 32.03)
        return(cv)
    }
    if (ieps==3 & signif==2) {
        cv = J(10, 10, .)
        cv[1,.] = (8.58, 10.13, 11.14, 11.83, 12.25, 12.66, 13.08, 13.35, 13.75, 13.89)
        cv[2,.] = (11.47, 12.95, 14.03, 14.85, 15.29, 15.8, 16.16, 16.44, 16.77, 16.84)
        cv[3,.] = (13.98, 15.72, 16.83, 17.61, 18.14, 18.74, 19.09, 19.41, 19.68, 19.77)
        cv[4,.] = (16.19, 18.11, 18.93, 19.64, 20.19, 20.54, 21.21, 21.42, 21.72, 21.97)
        cv[5,.] = (18.23, 19.91, 20.99, 21.71, 22.37, 22.77, 23.15, 23.42, 24.04, 24.42)
        cv[6,.] = (20.08, 22.11, 23.04, 23.77, 24.43, 24.75, 24.96, 25.22, 25.61, 25.93)
        cv[7,.] = (21.87, 24.17, 25.13, 26.03, 26.65, 27.06, 27.37, 27.9, 28.18, 28.36)
        cv[8,.] = (23.7, 25.75, 26.81, 27.65, 28.48, 28.8, 29.08, 29.3, 29.5, 29.69)
        cv[9,.] = (25.65, 27.66, 28.91, 29.67, 30.52, 30.96, 31.48, 31.77, 31.94, 32.33)
        cv[10,.] = (27.03, 29.24, 30.45, 31.45, 32.12, 32.5, 32.84, 33.12, 33.22, 33.85)
        return(cv)
    }
    if (ieps==3 & signif==3) {
        cv = J(10, 10, .)
        cv[1,.] = (10.18, 11.86, 12.66, 13.4, 13.89, 14.32, 14.73, 14.89, 15.22, 15.29)
        cv[2,.] = (12.96, 14.92, 15.81, 16.51, 16.84, 17.18, 17.61, 17.84, 18.32, 18.76)
        cv[3,.] = (15.76, 17.7, 18.87, 19.42, 19.77, 20.45, 20.57, 20.82, 21.51, 22)
        cv[4,.] = (18.13, 19.7, 20.66, 21.46, 21.97, 22.52, 22.79, 22.82, 23.03, 23.13)
        cv[5,.] = (19.95, 21.72, 22.81, 23.47, 24.42, 24.83, 25.28, 25.59, 25.98, 26.29)
        cv[6,.] = (22.15, 23.79, 24.76, 25.22, 25.93, 26.58, 26.99, 27.11, 27.4, 27.76)
        cv[7,.] = (24.2, 26.03, 27.06, 27.91, 28.36, 28.72, 29.17, 29.43, 29.66, 30)
        cv[8,.] = (25.77, 27.72, 28.8, 29.33, 29.69, 30.02, 30.46, 30.74, 30.9, 31.07)
        cv[9,.] = (27.69, 29.67, 31, 31.78, 32.33, 33.06, 33.51, 33.68, 34.16, 34.58)
        cv[10,.] = (29.27, 31.47, 32.54, 33.15, 33.85, 34.32, 34.45, 34.76, 34.94, 35.15)
        return(cv)
    }
    if (ieps==3 & signif==4) {
        cv = J(10, 10, .)
        cv[1,.] = (12.29, 13.89, 14.8, 15.28, 15.76, 16.27, 16.63, 16.77, 16.81, 17.01)
        cv[2,.] = (15.37, 16.84, 17.72, 18.67, 19.17, 19.46, 19.74, 19.93, 20.12, 20.53)
        cv[3,.] = (18.26, 19.77, 20.75, 21.98, 22.46, 22.69, 22.93, 23.11, 23.12, 23.15)
        cv[4,.] = (20.23, 21.97, 22.8, 23.06, 23.76, 24.55, 24.85, 25.11, 25.53, 25.57)
        cv[5,.] = (22.4, 24.42, 25.53, 26.17, 26.53, 26.77, 26.96, 27.1, 27.35, 27.37)
        cv[6,.] = (24.45, 25.93, 27.09, 27.56, 28.2, 29.61, 29.62, 30.27, 30.45, 30.56)
        cv[7,.] = (26.71, 28.36, 29.3, 29.86, 30.52, 30.89, 30.95, 31.03, 31.11, 31.17)
        cv[8,.] = (28.51, 29.69, 30.65, 31.03, 31.87, 32.42, 32.67, 33, 33.11, 33.45)
        cv[9,.] = (30.62, 32.33, 33.51, 34.28, 34.94, 35.71, 36.03, 36.34, 36.48, 36.49)
        cv[10,.] = (32.16, 33.85, 34.58, 35.14, 36.15, 36.76, 36.92, 37.37, 37.87, 37.96)
        return(cv)
    }
    if (ieps==4 & signif==1) {
        cv = J(10, 10, .)
        cv[1,.] = (6.72, 8.13, 9.07, 9.66, 10.17, 10.59, 10.95, 11.28, 11.64, 11.89)
        cv[2,.] = (9.37, 10.92, 11.9, 12.5, 12.89, 13.38, 13.84, 14.15, 14.41, 14.66)
        cv[3,.] = (11.59, 13.43, 14.43, 15.16, 15.72, 16.24, 16.69, 16.95, 17.32, 17.42)
        cv[4,.] = (13.72, 15.59, 16.67, 17.53, 18.17, 18.52, 18.84, 19.12, 19.43, 19.67)
        cv[5,.] = (15.51, 17.59, 18.76, 19.43, 20.02, 20.53, 20.91, 21.21, 21.59, 21.7)
        cv[6,.] = (17.39, 19.49, 20.65, 21.37, 22.07, 22.57, 22.9, 23.12, 23.38, 23.63)
        cv[7,.] = (19.11, 21.24, 22.42, 23.2, 24.13, 24.68, 25, 25.31, 25.76, 26.03)
        cv[8,.] = (20.86, 23.09, 24.3, 25.14, 25.76, 26.27, 26.59, 27.06, 27.41, 27.58)
        cv[9,.] = (22.38, 24.8, 26.1, 26.88, 27.47, 28.05, 28.4, 28.79, 29.16, 29.51)
        cv[10,.] = (23.95, 26.33, 27.5, 28.5, 29.13, 29.52, 30.07, 30.43, 30.87, 31.17)
        return(cv)
    }
    if (ieps==4 & signif==2) {
        cv = J(10, 10, .)
        cv[1,.] = (8.22, 9.71, 10.66, 11.34, 11.93, 12.3, 12.68, 12.92, 13.21, 13.61)
        cv[2,.] = (10.98, 12.55, 13.46, 14.22, 14.78, 15.37, 15.81, 16.13, 16.44, 16.69)
        cv[3,.] = (13.47, 15.25, 16.36, 17.08, 17.51, 18.08, 18.44, 18.89, 19.01, 19.35)
        cv[4,.] = (15.67, 17.61, 18.54, 19.21, 19.8, 20.22, 20.53, 21.06, 21.31, 21.55)
        cv[5,.] = (17.66, 19.5, 20.63, 21.4, 21.72, 22.19, 22.72, 23.01, 23.24, 23.67)
        cv[6,.] = (19.55, 21.44, 22.64, 23.19, 23.75, 24.28, 24.46, 24.75, 24.96, 25.02)
        cv[7,.] = (21.33, 23.31, 24.75, 25.38, 26.1, 26.47, 26.87, 27.15, 27.37, 27.74)
        cv[8,.] = (23.19, 25.23, 26.39, 27.19, 27.63, 28.09, 28.49, 28.7, 28.83, 29.02)
        cv[9,.] = (24.91, 26.92, 28.1, 28.93, 29.64, 30.29, 30.87, 31.09, 31.39, 31.67)
        cv[10,.] = (26.38, 28.56, 29.62, 30.48, 31.23, 31.96, 32.2, 32.38, 32.72, 32.9)
        return(cv)
    }
    if (ieps==4 & signif==3) {
        cv = J(10, 10, .)
        cv[1,.] = (9.77, 11.34, 12.31, 12.99, 13.61, 13.87, 14.25, 14.37, 14.73, 14.86)
        cv[2,.] = (12.59, 14.22, 15.39, 16.14, 16.69, 17, 17.18, 17.53, 17.65, 17.83)
        cv[3,.] = (15.28, 17.08, 18.1, 18.91, 19.35, 19.7, 20, 20.21, 20.53, 20.72)
        cv[4,.] = (17.67, 19.22, 20.25, 21.19, 21.55, 21.88, 22.18, 22.52, 22.77, 22.82)
        cv[5,.] = (19.51, 21.42, 22.28, 23.04, 23.67, 24.2, 24.47, 24.79, 24.94, 25.28)
        cv[6,.] = (21.47, 23.21, 24.28, 24.76, 25.02, 25.7, 26.07, 26.43, 26.73, 26.95)
        cv[7,.] = (23.36, 25.47, 26.47, 27.2, 27.74, 28.21, 28.4, 28.63, 29.09, 29.29)
        cv[8,.] = (25.26, 27.19, 28.1, 28.7, 29.02, 29.41, 29.62, 29.91, 30.11, 30.46)
        cv[9,.] = (26.96, 28.98, 30.34, 31.13, 31.67, 31.89, 32.26, 32.84, 33.14, 33.51)
        cv[10,.] = (28.62, 30.5, 31.97, 32.39, 32.9, 33.2, 33.9, 34.33, 34.53, 34.76)
        return(cv)
    }
    if (ieps==4 & signif==4) {
        cv = J(10, 10, .)
        cv[1,.] = (11.94, 13.61, 14.31, 14.8, 15.26, 15.76, 15.87, 16.23, 16.33, 16.63)
        cv[2,.] = (14.92, 16.69, 17.41, 17.72, 18.27, 19.06, 19.17, 19.23, 19.54, 19.74)
        cv[3,.] = (17.6, 19.35, 20.02, 20.64, 21.23, 21.98, 22.19, 22.54, 22.9, 22.93)
        cv[4,.] = (19.82, 21.55, 22.27, 22.8, 23.06, 23.76, 23.97, 24.55, 24.78, 24.85)
        cv[5,.] = (21.75, 23.67, 24.6, 25.18, 25.76, 26.29, 26.42, 26.53, 26.65, 26.67)
        cv[6,.] = (23.8, 25.02, 26.24, 26.77, 27.27, 27.76, 28.12, 28.48, 28.56, 28.8)
        cv[7,.] = (26.16, 27.74, 28.5, 29.17, 29.66, 30.52, 30.66, 30.89, 30.93, 30.95)
        cv[8,.] = (27.71, 29.02, 29.71, 30.2, 30.78, 31.03, 31.8, 32.42, 32.42, 32.47)
        cv[9,.] = (29.67, 31.67, 32.52, 33.28, 33.81, 34.81, 35.22, 35.54, 35.71, 36.03)
        cv[10,.] = (31.38, 32.9, 34.12, 34.68, 35, 36.15, 36.76, 36.92, 37.14, 37.37)
        return(cv)
    }
    if (ieps==5 & signif==1) {
        cv = J(10, 10, .)
        cv[1,.] = (6.35, 7.79, 8.7, 9.22, 9.71, 10.06, 10.45, 10.89, 11.16, 11.3)
        cv[2,.] = (8.96, 10.5, 11.47, 12.13, 12.56, 12.94, 13.29, 13.76, 14.03, 14.22)
        cv[3,.] = (11.17, 12.96, 13.96, 14.58, 15.13, 15.54, 15.93, 16.47, 16.79, 16.96)
        cv[4,.] = (13.22, 15.16, 16.14, 16.94, 17.52, 17.97, 18.34, 18.67, 18.84, 19.04)
        cv[5,.] = (14.98, 16.98, 18.12, 18.87, 19.47, 19.9, 20.47, 20.74, 21, 21.44)
        cv[6,.] = (16.77, 18.88, 20.03, 20.83, 21.41, 21.83, 22.28, 22.58, 22.83, 23.04)
        cv[7,.] = (18.45, 20.69, 21.81, 22.73, 23.49, 24.19, 24.6, 24.87, 25.08, 25.6)
        cv[8,.] = (20.15, 22.51, 23.56, 24.42, 25.11, 25.61, 25.95, 26.43, 26.59, 26.9)
        cv[9,.] = (21.69, 24.08, 25.45, 26.19, 26.79, 27.33, 27.78, 28.23, 28.54, 28.99)
        cv[10,.] = (23.29, 25.72, 26.97, 27.69, 28.55, 29.13, 29.48, 29.9, 30.3, 30.75)
        return(cv)
    }
    if (ieps==5 & signif==2) {
        cv = J(10, 10, .)
        cv[1,.] = (7.86, 9.29, 10.12, 10.93, 11.37, 11.82, 12.2, 12.65, 12.79, 13.09)
        cv[2,.] = (10.55, 12.19, 12.97, 13.84, 14.32, 14.92, 15.28, 15.48, 15.87, 16.34)
        cv[3,.] = (13.04, 14.65, 15.6, 16.51, 17.08, 17.39, 17.76, 18.08, 18.32, 18.72)
        cv[4,.] = (15.19, 17, 18.1, 18.72, 19.14, 19.63, 20.1, 20.5, 20.98, 21.23)
        cv[5,.] = (17.12, 18.94, 20.02, 20.81, 21.45, 21.72, 22.1, 22.69, 22.98, 23.15)
        cv[6,.] = (18.97, 20.89, 21.92, 22.66, 23.09, 23.42, 23.96, 24.28, 24.46, 24.75)
        cv[7,.] = (20.75, 22.78, 24.24, 24.93, 25.66, 26.03, 26.28, 26.56, 26.87, 27.21)
        cv[8,.] = (22.56, 24.54, 25.71, 26.5, 27.01, 27.51, 27.74, 28.09, 28.48, 28.7)
        cv[9,.] = (24.18, 26.28, 27.42, 28.27, 29.03, 29.67, 30.34, 30.79, 30.93, 31.13)
        cv[10,.] = (25.77, 27.75, 29.18, 30.02, 30.83, 31.4, 31.92, 32.2, 32.38, 32.72)
        return(cv)
    }
    if (ieps==5 & signif==3) {
        cv = J(10, 10, .)
        cv[1,.] = (9.32, 10.94, 11.86, 12.66, 13.09, 13.51, 13.85, 14.16, 14.37, 14.7)
        cv[2,.] = (12.21, 13.85, 14.94, 15.48, 16.34, 16.55, 16.8, 16.82, 17.06, 17.34)
        cv[3,.] = (14.66, 16.56, 17.4, 18.12, 18.72, 19.01, 19.4, 19.73, 20.02, 20.5)
        cv[4,.] = (17.04, 18.73, 19.64, 20.52, 21.23, 21.71, 21.95, 22.24, 22.56, 22.79)
        cv[5,.] = (18.96, 20.83, 21.75, 22.69, 23.15, 23.82, 24.2, 24.43, 24.77, 24.83)
        cv[6,.] = (20.93, 22.7, 23.49, 24.35, 24.75, 25.02, 25.58, 25.83, 26.3, 26.68)
        cv[7,.] = (22.85, 24.93, 26.05, 26.66, 27.21, 27.75, 27.99, 28.36, 28.61, 29.09)
        cv[8,.] = (24.56, 26.51, 27.52, 28.1, 28.7, 29.01, 29.46, 29.69, 29.93, 30.11)
        cv[9,.] = (26.31, 28.28, 29.67, 30.81, 31.13, 31.73, 32.26, 32.84, 33.14, 33.28)
        cv[10,.] = (27.8, 30.07, 31.4, 32.2, 32.72, 33, 33.2, 34.02, 34.37, 34.68)
        return(cv)
    }
    if (ieps==5 & signif==4) {
        cv = J(10, 10, .)
        cv[1,.] = (11.44, 13.09, 14.02, 14.63, 14.89, 15.29, 15.76, 16.13, 16.17, 16.23)
        cv[2,.] = (14.34, 16.34, 16.81, 17.18, 17.61, 17.83, 17.85, 18.32, 18.67, 19.06)
        cv[3,.] = (17.08, 18.72, 19.58, 20.45, 20.72, 21.27, 21.98, 22.46, 22.54, 22.57)
        cv[4,.] = (19.22, 21.23, 22.07, 22.61, 22.89, 23.17, 23.77, 23.97, 24.55, 24.78)
        cv[5,.] = (21.51, 23.15, 24.36, 24.82, 25.18, 25.76, 25.98, 26.42, 26.43, 26.53)
        cv[6,.] = (23.12, 24.75, 25.73, 26.58, 26.99, 27.44, 27.56, 28, 28.12, 28.56)
        cv[7,.] = (25.67, 27.21, 28.21, 28.8, 29.43, 29.86, 30.38, 30.55, 30.71, 30.89)
        cv[8,.] = (27.1, 28.7, 29.53, 30.02, 30.74, 31.01, 31.8, 32.42, 32.42, 32.47)
        cv[9,.] = (29.12, 31.13, 32.52, 33.25, 33.62, 34.65, 34.81, 35.22, 35.54, 35.71)
        cv[10,.] = (30.86, 32.72, 33.54, 34.58, 34.94, 35.58, 36.15, 36.91, 36.92, 37.14)
        return(cv)
    }
    return(J(0,0,.))
}

real matrix _bsrbreak_getdmax(real scalar ieps, real scalar signif)
{
    real matrix cv
    if (ieps==1 & signif==1) {
        cv = J(10, 2, .)
        cv[1,.] = (8.78, 9.14)
        cv[2,.] = (11.69, 12.33)
        cv[3,.] = (14.05, 14.76)
        cv[4,.] = (16.17, 16.95)
        cv[5,.] = (17.94, 18.85)
        cv[6,.] = (19.92, 20.89)
        cv[7,.] = (21.79, 22.81)
        cv[8,.] = (23.53, 24.55)
        cv[9,.] = (25.19, 26.4)
        cv[10,.] = (26.66, 27.79)
        return(cv)
    }
    if (ieps==1 & signif==2) {
        cv = J(10, 2, .)
        cv[1,.] = (10.17, 10.91)
        cv[2,.] = (13.27, 14.19)
        cv[3,.] = (15.8, 16.82)
        cv[4,.] = (17.88, 19.07)
        cv[5,.] = (19.74, 20.95)
        cv[6,.] = (21.9, 23.27)
        cv[7,.] = (23.77, 25.02)
        cv[8,.] = (25.51, 26.83)
        cv[9,.] = (27.28, 28.78)
        cv[10,.] = (28.75, 30.16)
        return(cv)
    }
    if (ieps==1 & signif==3) {
        cv = J(10, 2, .)
        cv[1,.] = (11.52, 12.53)
        cv[2,.] = (14.69, 16.04)
        cv[3,.] = (17.36, 18.79)
        cv[4,.] = (19.51, 20.89)
        cv[5,.] = (21.57, 23.04)
        cv[6,.] = (23.83, 25.22)
        cv[7,.] = (25.46, 26.92)
        cv[8,.] = (27.32, 28.98)
        cv[9,.] = (29.2, 30.82)
        cv[10,.] = (30.84, 32.46)
        return(cv)
    }
    if (ieps==1 & signif==4) {
        cv = J(10, 2, .)
        cv[1,.] = (13.74, 15.02)
        cv[2,.] = (16.79, 18.11)
        cv[3,.] = (19.38, 20.81)
        cv[4,.] = (21.25, 22.81)
        cv[5,.] = (24, 25.46)
        cv[6,.] = (26.07, 27.63)
        cv[7,.] = (28.02, 29.57)
        cv[8,.] = (29.6, 31.32)
        cv[9,.] = (31.72, 33.32)
        cv[10,.] = (33.86, 35.47)
        return(cv)
    }
    if (ieps==2 & signif==1) {
        cv = J(10, 2, .)
        cv[1,.] = (8.05, 8.63)
        cv[2,.] = (10.86, 11.71)
        cv[3,.] = (13.26, 14.14)
        cv[4,.] = (15.23, 16.27)
        cv[5,.] = (17.06, 18.14)
        cv[6,.] = (19.06, 20.22)
        cv[7,.] = (20.76, 22.03)
        cv[8,.] = (22.42, 23.71)
        cv[9,.] = (24.24, 25.66)
        cv[10,.] = (25.64, 27.05)
        return(cv)
    }
    if (ieps==2 & signif==2) {
        cv = J(10, 2, .)
        cv[1,.] = (9.52, 10.39)
        cv[2,.] = (12.59, 13.66)
        cv[3,.] = (14.85, 16.07)
        cv[4,.] = (17, 18.38)
        cv[5,.] = (18.91, 20.3)
        cv[6,.] = (21.01, 22.55)
        cv[7,.] = (22.8, 24.34)
        cv[8,.] = (24.56, 26.1)
        cv[9,.] = (26.48, 27.99)
        cv[10,.] = (27.82, 29.46)
        return(cv)
    }
    if (ieps==2 & signif==3) {
        cv = J(10, 2, .)
        cv[1,.] = (10.83, 12.06)
        cv[2,.] = (14.15, 15.33)
        cv[3,.] = (16.64, 18.04)
        cv[4,.] = (18.75, 20.3)
        cv[5,.] = (20.68, 22.22)
        cv[6,.] = (23.25, 24.66)
        cv[7,.] = (24.75, 26.47)
        cv[8,.] = (26.54, 28.24)
        cv[9,.] = (28.33, 30.02)
        cv[10,.] = (29.9, 31.58)
        return(cv)
    }
    if (ieps==2 & signif==4) {
        cv = J(10, 2, .)
        cv[1,.] = (13.07, 14.53)
        cv[2,.] = (16.19, 17.8)
        cv[3,.] = (18.75, 20.42)
        cv[4,.] = (20.75, 22.35)
        cv[5,.] = (23.16, 24.81)
        cv[6,.] = (25.55, 27.28)
        cv[7,.] = (27.23, 28.87)
        cv[8,.] = (29.01, 30.62)
        cv[9,.] = (30.81, 32.74)
        cv[10,.] = (32.82, 34.51)
        return(cv)
    }
    if (ieps==3 & signif==1) {
        cv = J(10, 2, .)
        cv[1,.] = (7.46, 8.2)
        cv[2,.] = (10.16, 11.15)
        cv[3,.] = (12.4, 13.58)
        cv[4,.] = (14.58, 15.88)
        cv[5,.] = (16.49, 17.8)
        cv[6,.] = (18.23, 19.66)
        cv[7,.] = (20, 21.46)
        cv[8,.] = (21.7, 23.31)
        cv[9,.] = (23.38, 24.99)
        cv[10,.] = (24.9, 26.62)
        return(cv)
    }
    if (ieps==3 & signif==2) {
        cv = J(10, 2, .)
        cv[1,.] = (8.88, 9.91)
        cv[2,.] = (11.7, 12.81)
        cv[3,.] = (14.23, 15.59)
        cv[4,.] = (16.37, 17.83)
        cv[5,.] = (18.42, 19.96)
        cv[6,.] = (20.3, 21.86)
        cv[7,.] = (22.04, 23.81)
        cv[8,.] = (23.87, 25.63)
        cv[9,.] = (25.81, 27.53)
        cv[10,.] = (27.23, 29.06)
        return(cv)
    }
    if (ieps==3 & signif==3) {
        cv = J(10, 2, .)
        cv[1,.] = (10.39, 11.67)
        cv[2,.] = (13.18, 14.58)
        cv[3,.] = (15.87, 17.41)
        cv[4,.] = (18.24, 19.82)
        cv[5,.] = (20.1, 21.76)
        cv[6,.] = (22.27, 23.97)
        cv[7,.] = (24.26, 26.1)
        cv[8,.] = (25.88, 27.8)
        cv[9,.] = (27.78, 29.78)
        cv[10,.] = (29.36, 31.47)
        return(cv)
    }
    if (ieps==3 & signif==4) {
        cv = J(10, 2, .)
        cv[1,.] = (12.37, 13.83)
        cv[2,.] = (15.41, 17.01)
        cv[3,.] = (18.26, 19.86)
        cv[4,.] = (20.39, 21.95)
        cv[5,.] = (22.49, 24.5)
        cv[6,.] = (24.55, 26.68)
        cv[7,.] = (26.75, 28.76)
        cv[8,.] = (28.51, 30.4)
        cv[9,.] = (30.62, 32.71)
        cv[10,.] = (32.17, 34.25)
        return(cv)
    }
    if (ieps==4 & signif==1) {
        cv = J(10, 2, .)
        cv[1,.] = (6.96, 7.67)
        cv[2,.] = (9.66, 10.46)
        cv[3,.] = (11.84, 12.79)
        cv[4,.] = (13.94, 15.05)
        cv[5,.] = (15.74, 16.8)
        cv[6,.] = (17.62, 18.76)
        cv[7,.] = (19.3, 20.56)
        cv[8,.] = (21.09, 22.45)
        cv[9,.] = (22.55, 24)
        cv[10,.] = (24.17, 25.6)
        return(cv)
    }
    if (ieps==4 & signif==2) {
        cv = J(10, 2, .)
        cv[1,.] = (8.43, 9.27)
        cv[2,.] = (11.16, 12.15)
        cv[3,.] = (13.66, 14.73)
        cv[4,.] = (15.79, 17.04)
        cv[5,.] = (17.76, 19.11)
        cv[6,.] = (19.69, 21.04)
        cv[7,.] = (21.46, 22.76)
        cv[8,.] = (23.28, 24.68)
        cv[9,.] = (25.04, 26.4)
        cv[10,.] = (26.51, 28.02)
        return(cv)
    }
    if (ieps==4 & signif==3) {
        cv = J(10, 2, .)
        cv[1,.] = (9.94, 10.93)
        cv[2,.] = (12.68, 13.87)
        cv[3,.] = (15.31, 16.65)
        cv[4,.] = (17.73, 19.12)
        cv[5,.] = (19.59, 20.84)
        cv[6,.] = (21.56, 23.09)
        cv[7,.] = (23.4, 25.03)
        cv[8,.] = (25.31, 26.91)
        cv[9,.] = (27.02, 28.54)
        cv[10,.] = (28.67, 30.31)
        return(cv)
    }
    if (ieps==4 & signif==4) {
        cv = J(10, 2, .)
        cv[1,.] = (12.02, 13.16)
        cv[2,.] = (14.92, 16.52)
        cv[3,.] = (17.6, 18.89)
        cv[4,.] = (19.9, 21.27)
        cv[5,.] = (21.75, 23.39)
        cv[6,.] = (23.8, 25.17)
        cv[7,.] = (26.16, 27.71)
        cv[8,.] = (27.71, 29.3)
        cv[9,.] = (29.67, 31.67)
        cv[10,.] = (31.4, 32.99)
        return(cv)
    }
    if (ieps==5 & signif==1) {
        cv = J(10, 2, .)
        cv[1,.] = (6.55, 7.09)
        cv[2,.] = (9.16, 9.8)
        cv[3,.] = (11.31, 12.01)
        cv[4,.] = (13.36, 14.16)
        cv[5,.] = (15.12, 15.93)
        cv[6,.] = (16.94, 17.92)
        cv[7,.] = (18.6, 19.61)
        cv[8,.] = (20.3, 21.38)
        cv[9,.] = (21.81, 22.81)
        cv[10,.] = (23.43, 24.43)
        return(cv)
    }
    if (ieps==5 & signif==2) {
        cv = J(10, 2, .)
        cv[1,.] = (8.01, 8.69)
        cv[2,.] = (10.67, 11.49)
        cv[3,.] = (13.15, 13.99)
        cv[4,.] = (15.28, 16.13)
        cv[5,.] = (17.14, 18.11)
        cv[6,.] = (19.1, 20.02)
        cv[7,.] = (20.84, 21.81)
        cv[8,.] = (22.62, 23.6)
        cv[9,.] = (24.28, 25.4)
        cv[10,.] = (25.8, 27.01)
        return(cv)
    }
    if (ieps==5 & signif==3) {
        cv = J(10, 2, .)
        cv[1,.] = (9.37, 10.24)
        cv[2,.] = (12.25, 13.02)
        cv[3,.] = (14.67, 15.64)
        cv[4,.] = (17.13, 18.17)
        cv[5,.] = (18.97, 19.92)
        cv[6,.] = (20.97, 22.08)
        cv[7,.] = (22.89, 24.38)
        cv[8,.] = (24.61, 25.76)
        cv[9,.] = (26.38, 27.55)
        cv[10,.] = (27.91, 29.13)
        return(cv)
    }
    if (ieps==5 & signif==4) {
        cv = J(10, 2, .)
        cv[1,.] = (11.5, 12.27)
        cv[2,.] = (14.34, 15.41)
        cv[3,.] = (17.08, 18.03)
        cv[4,.] = (19.22, 20.34)
        cv[5,.] = (21.51, 22.39)
        cv[6,.] = (23.12, 24.27)
        cv[7,.] = (25.67, 26.77)
        cv[8,.] = (27.12, 28.29)
        cv[9,.] = (29.12, 30.57)
        cv[10,.] = (30.87, 32.2)
        return(cv)
    }
    return(J(0,0,.))
}

end
