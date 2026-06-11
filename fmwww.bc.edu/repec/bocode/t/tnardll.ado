*! tnardll version 1.0.0  03jun2026
*! Threshold (Nonlinear) Autoregressive Distributed Lag model -- TARDL
*!
*! Implements the Threshold ARDL of Cho, Greenwood-Nimmo & Shin (2020c,d),
*! surveyed in Cho, Greenwood-Nimmo & Shin (2021, "Recent Developments of the
*! Autoregressive Distributed Lag Modelling Framework"). The threshold/momentum
*! decomposition is applied to the FIRST differences of one regressor around one
*! or more UNKNOWN thresholds (tau), estimated by profile (concentrated) least
*! squares.  Number of regimes S in {1,2,3} chosen by information criteria
*! (six criteria: AIC/SIC/HQIC and the Pitarakis 2006 modified pAIC/pSIC/pHQIC)
*! or fixed by the user.  Threshold existence is tested by a quasi-likelihood
*! ratio (QLR) statistic with a fixed-regressor wild bootstrap p-value
*! (the asymptotic null law is non-pivotal: Davies 1977/87 problem).
*!
*! Author: Dr Merwan Roudane <merwanroudane920@gmail.com>
*! https://github.com/merwanroudane

program define tnardll, eclass sortpreserve
    version 17.0

    if replay() {
        if "`e(cmd)'" != "tnardll" {
            error 301
        }
        Display `0'
        exit
    }

    syntax varlist(min=2 numeric ts)  [if] [in] [ ,    ///
            THReshold(varname numeric)                 ///
            Lags(numlist integer >=1 max=2)            ///
            REGimes(integer 0)                         ///
            MAXReg(integer 3)                          ///
            IC(string)                                 ///
            TRim(real 0.15)                            ///
            GRid(integer 50)                           ///
            QLR                                        ///
            Breps(integer 499)                         ///
            SEED(string)                               ///
            noCONStant                                 ///
            TRend                                      ///
            Robust                                     ///
            Level(cilevel)                             ///
            noDOTS ]

    * ---------------------------------------------------------------
    * Parse variable lists
    * ---------------------------------------------------------------
    gettoken depvar indeps : varlist
    local indeps : list retokenize indeps
    if "`indeps'" == "" {
        di as err "at least one regressor is required"
        exit 102
    }

    * threshold (decomposed) variable
    if "`threshold'" == "" {
        gettoken thrvar : indeps
    }
    else {
        local thrvar "`threshold'"
        local ck : list thrvar in indeps
        if !`ck' {
            di as err "threshold() variable {bf:`thrvar'} must be among the regressors"
            exit 198
        }
    }
    * other (linear) regressors
    local othervars : list indeps - thrvar

    * ---------------------------------------------------------------
    * Lags
    * ---------------------------------------------------------------
    if "`lags'" == "" {
        local p 1
        local q 1
    }
    else {
        tokenize `lags'
        local p `1'
        local q = cond("`2'"=="", "`1'", "`2'")
    }

    * ---------------------------------------------------------------
    * Information criterion
    * ---------------------------------------------------------------
    if "`ic'" == "" local ic "sic"
    local ic = lower("`ic'")
    local okic "aic sic hqic paic psic phqic"
    if !`: list ic in okic' {
        di as err "ic() must be one of: `okic'"
        exit 198
    }

    * regimes / maxreg bounds (S in {1,2,3})
    if `maxreg' > 3 {
        di as txt "note: maximum supported regimes is 3 (two thresholds); maxreg() set to 3"
        local maxreg 3
    }
    if `maxreg' < 1 local maxreg 1
    if `regimes' != 0 & (`regimes' < 1 | `regimes' > 3) {
        di as err "regimes() must be 1, 2 or 3 (0 = choose by information criterion)"
        exit 198
    }
    if `trim' <= 0 | `trim' >= 0.5 {
        di as err "trim() must lie strictly between 0 and 0.5"
        exit 198
    }
    if `grid' < 5 local grid 5

    * vce
    local vce = cond("`robust'"!="", "robust", "ols")

    * constant / trend flags
    local consflag = cond("`constant'"=="", 1, 0)
    local trflag   = cond("`trend'"!="",   1, 0)

    * seed
    if "`seed'" != "" {
        set seed `seed'
    }

    * ---------------------------------------------------------------
    * tsset & sample
    * ---------------------------------------------------------------
    qui tsset
    if "`r(panelvar)'" != "" {
        di as err "tnardll requires a pure time series (use tsset {it:timevar}); panel data not supported"
        exit 198
    }
    local timevar "`r(timevar)'"
    local tdelta = cond("`r(tdelta)'"=="", 1, `r(tdelta)')

    marksample touse
    markout `touse' `depvar' `indeps'
    qui count if `touse'
    if r(N) == 0 {
        di as err "no observations"
        exit 2000
    }

    tempvar used
    qui gen byte `used' = 0

    * ---------------------------------------------------------------
    * Hand off to Mata engine
    * ---------------------------------------------------------------
    mata: _tnardll_run()

    * scalars / locals returned via st_* in Mata:
    *   __err (string, nonempty => abort)
    if "`__err'" != "" {
        di as err "`__err'"
        exit 459
    }

    * ---------------------------------------------------------------
    * Build coefficient names (order MUST match Mata design column order)
    * ---------------------------------------------------------------
    local S = __S
    local m : word count `othervars'
    local names ""
    * 1. error-correction term (rho on y_{t-1})
    local names "`names' ec"
    * 2. long-run levels: threshold regimes then other vars
    forvalues s = 1/`S' {
        local names "`names' lr_`thrvar'_r`s'"
    }
    foreach w of local othervars {
        local names "`names' lr_`w'"
    }
    * 3. short-run Dy lags 1..p-1
    forvalues j = 1/`=`p'-1' {
        local names "`names' D`j'.`depvar'"
    }
    * 4. short-run Dx regime lags 0..q-1
    forvalues s = 1/`S' {
        forvalues j = 0/`=`q'-1' {
            local names "`names' D`j'.`thrvar'_r`s'"
        }
    }
    * 5. short-run other-var diffs 0..q-1
    foreach w of local othervars {
        forvalues j = 0/`=`q'-1' {
            local names "`names' D`j'.`w'"
        }
    }
    * 6. trend
    if `trflag' local names "`names' trend"
    * 7. constant
    if `consflag' local names "`names' _cons"

    * sanitise names to valid Stata coefficient names
    local cnames ""
    foreach nm of local names {
        local cnames "`cnames' `=strtoname("`nm'")'"
    }

    matrix colnames __b = `cnames'
    matrix colnames __V = `cnames'
    matrix rownames __V = `cnames'

    * long-run coefficient names (returned by Mata in __lrnames)
    local lrc ""
    foreach nm of local __lrnames {
        local lrc "`lrc' `=strtoname("`nm'")'"
    }
    matrix colnames __lrb = `lrc'
    matrix colnames __lrV = `lrc'
    matrix rownames __lrV = `lrc'

    * ---------------------------------------------------------------
    * Post results
    * ---------------------------------------------------------------
    ereturn post __b __V , esample(`used') depname(`depvar') obs(`=__N')

    ereturn local cmd       "tnardll"
    ereturn local cmdline   "tnardll `0'"
    ereturn local title     "Threshold (Nonlinear) ARDL -- TARDL"
    ereturn local depvar    "`depvar'"
    ereturn local indepvars "`indeps'"
    ereturn local thrvar    "`thrvar'"
    ereturn local othervars "`othervars'"
    ereturn local timevar   "`timevar'"
    ereturn local ic        "`ic'"
    ereturn local vce       "`vce'"
    ereturn local properties "b V"
    ereturn local predict   "tnardll_p"
    ereturn local marginsnotok "_ALL"

    ereturn scalar N        = __N
    ereturn scalar k        = __k
    ereturn scalar df_r     = __df_r
    ereturn scalar S        = __S
    ereturn scalar nthr     = __S - 1
    ereturn scalar p        = `p'
    ereturn scalar q        = `q'
    ereturn scalar rho      = __rho
    ereturn scalar ssr      = __ssr
    ereturn scalar rmse     = __rmse
    ereturn scalar r2       = __r2
    ereturn scalar r2_a     = __r2_a
    ereturn scalar trim     = `trim'
    ereturn scalar grid     = `grid'
    ereturn scalar level    = `level'
    ereturn scalar cons     = `consflag'
    ereturn scalar trend    = `trflag'
    ereturn scalar pss_k    = __pssk
    ereturn scalar Fpss     = __Fpss
    ereturn scalar tBDM     = __tBDM
    ereturn scalar lr_asym_chi2 = __lachi2
    ereturn scalar lr_asym_df   = __ladf
    ereturn scalar lr_asym_p    = __lap
    ereturn scalar sr_asym_chi2 = __sachi2
    ereturn scalar sr_asym_df   = __sadf
    ereturn scalar sr_asym_p    = __sap

    if "`qlr'" != "" {
        ereturn scalar qlr   = __qlr
        ereturn scalar qlr_p = __qlrp
        ereturn scalar breps = `breps'
    }

    if `S' >= 2 {
        matrix colnames __thr = tau
        ereturn matrix thresholds = __thr
    }
    ereturn matrix lr_b   = __lrb
    ereturn matrix lr_V   = __lrV
    ereturn matrix ictable = __ictab
    capture confirm matrix __profile
    if !_rc {
        ereturn matrix profile = __profile
    }
    * structural pieces for multipliers
    ereturn matrix theta = __theta
    capture confirm matrix __phi
    if !_rc  ereturn matrix phi = __phi
    ereturn matrix pimat = __pimat

    * ---------------------------------------------------------------
    * PSS bounds-test critical values via Kripfganz & Schneider (2020)
    * surface regression (ships with -ardl-).  Mapped to a determ. case:
    *   no constant -> 1 ; unrestricted constant -> 3 ; +trend -> 5.
    * k = number of long-run forcing terms (S regimes + other levels);
    * bounds are an approximate reference for the threshold decomposition.
    * ---------------------------------------------------------------
    local pcase = cond(`consflag'==0, 1, cond(`trflag'==1, 5, 3))
    ereturn scalar pss_case = `pcase'
    local pk = e(pss_k)
    capture qui ardlbounds , case(`pcase') stat(f) k(`pk') siglevels(10 5 1)
    if !_rc {
        tempname Fcv tcv
        matrix `Fcv' = r(cvmat)
        ereturn matrix F_critval = `Fcv'
        capture qui ardlbounds , case(`pcase') stat(t) k(`pk') siglevels(10 5 1)
        if !_rc {
            matrix `tcv' = r(cvmat)
            ereturn matrix t_critval = `tcv'
        }
    }

    Display , level(`level')
end

* =====================================================================
* Display
* =====================================================================
program define Display
    syntax [, Level(cilevel) ]
    if "`level'" == "" local level = e(level)

    local depvar  "`e(depvar)'"
    local thrvar  "`e(thrvar)'"
    local S       = e(S)
    local p       = e(p)
    local q       = e(q)

    di ""
    di as txt "{hline 78}"
    di as txt "Threshold (Nonlinear) ARDL                       " ///
              _col(50) "Number of obs " _col(66) "= " as res %9.0f e(N)
    di as txt "Dependent variable: " as res "`depvar'" ///
              _col(50) as txt "Regimes (S)   " _col(66) "= " as res %9.0f e(S)
    di as txt "Threshold variable: " as res "D.`thrvar'" ///
              _col(50) as txt "ARDL(p,q)     " _col(66) "= " as res "(`p',`q')"
    di as txt "Adjustment (rho)  : " as res %9.4f e(rho) ///
              _col(50) as txt "Adj. R-squared" _col(66) "= " as res %9.4f e(r2_a)

    * thresholds
    local nthr = e(nthr)
    if `nthr' > 0 {
        matrix b = e(thresholds)
        local tlist ""
        forvalues i = 1/`nthr' {
            local tv = b[`i',1]
            local tlist "`tlist' `:di %7.4f `tv''"
        }
        di as txt "Estimated threshold(s) in D.`thrvar':" as res "`tlist'"
    }
    else {
        di as txt "Estimated threshold(s): " as res "(none -- linear ARDL)"
    }
    di as txt "{hline 78}"

    * ---------------- Long-run table -----------------
    di ""
    di as txt "Long-run coefficients (beta = -theta/rho), delta-method SE"
    _coltab_header , level(`level')

    matrix lb = e(lr_b)
    matrix lV = e(lr_V)
    local lrnames : colnames lb
    local zc = invnormal(1 - (100-`level')/200)
    local i 0
    foreach nm of local lrnames {
        local ++i
        local est = lb[1,`i']
        local se  = sqrt(lV[`i',`i'])
        _coltab_row , name("`nm'") b(`est') se(`se') z(`zc')
    }
    di as txt "{hline 78}"

    * ---------------- Short-run / ECM table -----------------
    di ""
    di as txt "Short-run dynamics and error-correction (unrestricted ECM)"
    _coltab_header , level(`level')
    matrix bb = e(b)
    matrix VV = e(V)
    local bn : colnames bb
    local i 0
    foreach nm of local bn {
        local ++i
        local est = bb[1,`i']
        local se  = sqrt(VV[`i',`i'])
        _coltab_row , name("`nm'") b(`est') se(`se') z(`zc')
    }
    di as txt "{hline 78}"

    * ---------------- Tests -----------------
    di ""
    di as txt "Asymmetry / threshold tests"
    di as txt "{hline 78}"
    di as txt "  Long-run regime equality (H0: beta^(s) all equal)"
    di as txt "      chi2(" as res e(lr_asym_df) as txt ") = " ///
        as res %8.3f e(lr_asym_chi2) as txt "   Prob > chi2 = " as res %6.4f e(lr_asym_p)
    di as txt "  Short-run regime equality (H0: sum pi^(s) all equal)"
    di as txt "      chi2(" as res e(sr_asym_df) as txt ") = " ///
        as res %8.3f e(sr_asym_chi2) as txt "   Prob > chi2 = " as res %6.4f e(sr_asym_p)
    if !missing(e(qlr)) {
        di as txt "  QLR threshold-existence test (H0: linear ARDL vs S=2 TARDL)"
        di as txt "      QLR = " as res %8.3f e(qlr) ///
            as txt "   bootstrap p = " as res %6.4f e(qlr_p) ///
            as txt "   (B = " as res e(breps) as txt ")"
    }
    local pk = e(pss_k)
    local pcase = e(pss_case)
    di as txt "  PSS bounds test of no levels relationship (H0: no cointegration)"
    di as txt "      F = " as res %8.3f e(Fpss) ///
        as txt "    t(rho) = " as res %8.3f e(tBDM) ///
        as txt "    [k = " as res `pk' as txt ", case " as res `pcase' as txt "]"
    capture confirm matrix e(F_critval)
    if !_rc {
        matrix Fcv = e(F_critval)
        di as txt "      Kripfganz-Schneider (2020) asymptotic critical bounds:"
        di as txt "                  10%               5%                1%"
        di as txt "                I(0)    I(1)     I(0)    I(1)     I(0)    I(1)"
        di as txt "        F   " as res %8.3f Fcv[1,1] %8.3f Fcv[1,2] ///
            "  " %8.3f Fcv[1,3] %8.3f Fcv[1,4] ///
            "  " %8.3f Fcv[1,5] %8.3f Fcv[1,6]
        capture confirm matrix e(t_critval)
        if !_rc {
            matrix tcv = e(t_critval)
            di as txt "        t   " as res %8.3f tcv[1,1] %8.3f tcv[1,2] ///
                "  " %8.3f tcv[1,3] %8.3f tcv[1,4] ///
                "  " %8.3f tcv[1,5] %8.3f tcv[1,6]
        }
        local fi0 = Fcv[1,3]
        local fi1 = Fcv[1,4]
        local Fv  = e(Fpss)
        if `Fv' > `fi1'      local fdec "F > I(1) => reject H0: a levels relationship exists"
        else if `Fv' < `fi0' local fdec "F < I(0) => do not reject H0: no levels relationship"
        else                 local fdec "I(0) <= F <= I(1) => inconclusive"
        di as txt "      Decision (5%): " as res "`fdec'"
    }
    else {
        di as txt "      compare F,t to Pesaran/Shin/Smith (2001) I(0)/I(1) bounds"
        di as txt "      (install {bf:ardl} (Kripfganz/Schneider) for automatic bounds)"
    }
    di as txt "{hline 78}"

    * ---------------- IC table -----------------
    matrix ict = e(ictable)
    di ""
    di as txt "Regime selection -- information criteria (chosen S minimises {bf:`e(ic)'})"
    di as txt "{hline 78}"
    di as txt "    S  " _col(12) "AIC" _col(24) "SIC" _col(36) "HQIC" ///
        _col(48) "pAIC" _col(60) "pSIC" _col(72) "pHQIC"
    local nr = rowsof(ict)
    forvalues r = 1/`nr' {
        local sval = ict[`r',1]
        di as res %5.0f `sval' as txt "  " ///
            _col(8)  as res %10.4f ict[`r',2] ///
            _col(20) as res %10.4f ict[`r',3] ///
            _col(32) as res %10.4f ict[`r',4] ///
            _col(44) as res %10.4f ict[`r',5] ///
            _col(56) as res %10.4f ict[`r',6] ///
            _col(68) as res %10.4f ict[`r',7]
    }
    di as txt "{hline 78}"
    di as txt "Note: threshold p-value bootstrap is fixed-regressor wild (Rademacher);"
    di as txt "      see {help tnardll##refs:references}. Long-run SEs are FM-type asymptotic."
end

* small helpers for coefficient tables
program define _coltab_header
    syntax , Level(cilevel)
    di as txt "{hline 78}"
    di as txt %-22s "" _col(23) "{c |}" ///
        _col(27) "Coef." _col(39) "Std.err." _col(51) "z" _col(58) "P>|z|" ///
        _col(66) "[`level'% c.i.]"
    di as txt "{hline 23}{c +}{hline 54}"
end

program define _coltab_row
    syntax , name(string) b(real) se(real) z(real)
    if `se' <= 0 | missing(`se') {
        di as txt %-22s abbrev("`name'",22) _col(23) "{c |}" ///
            _col(25) as res %10.4f `b' _col(37) as txt "  (dropped/exact)"
        exit
    }
    local zst = `b'/`se'
    local pv  = 2*normal(-abs(`zst'))
    local lo  = `b' - `z'*`se'
    local hi  = `b' + `z'*`se'
    di as txt %-22s abbrev("`name'",22) _col(23) "{c |}" ///
        _col(25) as res %10.4f `b' ///
        _col(37) as res %10.4f `se' ///
        _col(49) as res %7.2f `zst' ///
        _col(57) as res %6.3f `pv' ///
        _col(64) as res %9.4f `lo' " " %9.4f `hi'
end

* =====================================================================
* Mata engine
* =====================================================================
version 17.0
mata:
mata set matastrict off

// ---- helpers ---------------------------------------------------------
real colvector _tn_lag(real colvector v, real scalar k)
{
    real scalar n
    n = rows(v)
    if (k <= 0) return(v)
    if (k >= n) return(J(n,1,.))
    return( J(k,1,.) \ v[|1 \ n-k|] )
}

real colvector _tn_cumsum(real colvector v)
{
    real scalar i, n
    real colvector c
    n = rows(v)
    c = J(n,1,0)
    if (n == 0) return(c)
    c[1] = (v[1]==. ? 0 : v[1])
    for (i=2; i<=n; i++) c[i] = c[i-1] + (v[i]==. ? 0 : v[i])
    return(c)
}

// segment the difference series dx into S regime-columns given thresholds tau
real matrix _tn_seg(real colvector dx, real rowvector tau)
{
    real scalar n, S, t, s
    real matrix seg
    n = rows(dx)
    S = cols(tau) + 1
    seg = J(n, S, 0)
    for (t=1; t<=n; t++) {
        if (dx[t]==.) continue
        if (S==1) {
            seg[t,1] = dx[t]
            continue
        }
        if (dx[t] <= tau[1]) {
            seg[t,1] = dx[t]
        }
        else if (dx[t] > tau[S-1]) {
            seg[t,S] = dx[t]
        }
        else {
            for (s=2; s<=S-1; s++) {
                if (dx[t] > tau[s-1] && dx[t] <= tau[s]) seg[t,s] = dx[t]
            }
        }
    }
    return(seg)
}

// build design; returns dependent (dyv) and regressors (X) over usable rows,
// plus column-index bookkeeping and the surviving row indices (keep)
struct tndes {
    real colvector dyv
    real matrix    X
    real colvector keep
    real scalar    S, m, p, q, irho
    real rowvector ilr_xT, ilr_w, iphi
    real matrix    ipi
}

struct tndes scalar _tn_design(real colvector y, real colvector xT,
        real matrix W, real scalar p, real scalar q,
        real rowvector tau, real scalar consf, real scalar trf)
{
    struct tndes scalar d
    real scalar n, S, m, s, j, jj, col
    real colvector dy, dx, dw
    real matrix seg, xseg, X, M
    real rowvector pirow

    n = rows(y)
    S = cols(tau) + 1
    m = cols(W)
    dy = y - _tn_lag(y,1)
    dx = xT - _tn_lag(xT,1)
    seg  = _tn_seg(dx, tau)
    xseg = J(n,S,0)
    for (s=1; s<=S; s++) xseg[.,s] = _tn_cumsum(seg[.,s])

    X = J(n,0,.)
    col = 0
    // 1. rho : y_{t-1}
    X = _tn_lag(y,1)
    col = 1
    d.irho = 1
    // 2. long-run levels: threshold regimes
    d.ilr_xT = J(1,S,0)
    for (s=1; s<=S; s++) {
        X = X, _tn_lag(xseg[.,s],1)
        col++
        d.ilr_xT[s] = col
    }
    // long-run levels: other vars
    d.ilr_w = (m>0 ? J(1,m,0) : J(1,0,0))
    for (j=1; j<=m; j++) {
        X = X, _tn_lag(W[.,j],1)
        col++
        d.ilr_w[j] = col
    }
    // 3. short-run Dy lags 1..p-1
    d.iphi = (p>1 ? J(1,p-1,0) : J(1,0,0))
    for (j=1; j<=p-1; j++) {
        X = X, _tn_lag(dy,j)
        col++
        d.iphi[j] = col
    }
    // 4. short-run Dx regime lags 0..q-1
    d.ipi = J(S,q,0)
    for (s=1; s<=S; s++) {
        for (j=0; j<=q-1; j++) {
            X = X, _tn_lag(seg[.,s],j)
            col++
            d.ipi[s,j+1] = col
        }
    }
    // 5. short-run other-var diffs 0..q-1
    for (jj=1; jj<=m; jj++) {
        dw = W[.,jj] - _tn_lag(W[.,jj],1)
        for (j=0; j<=q-1; j++) {
            X = X, _tn_lag(dw,j)
            col++
        }
    }
    // 6. trend
    if (trf) {
        X = X, (1::n)
        col++
    }
    // 7. constant
    if (consf) {
        X = X, J(n,1,1)
        col++
    }

    M = dy, X
    d.keep = selectindex(rowmissing(M):==0)
    d.dyv = dy[d.keep]
    d.X   = X[d.keep, .]
    d.S = S; d.m = m; d.p = p; d.q = q
    return(d)
}

// OLS fit: returns ssr; optionally fills b, V
real scalar _tn_ols(real colvector yv, real matrix X, real scalar robust,
                    real colvector b, real matrix V)
{
    real scalar n, k, ssr, s2
    real colvector e
    real matrix XtXi, meat
    n = rows(X); k = cols(X)
    XtXi = invsym(cross(X,X))
    b = XtXi * cross(X, yv)
    e = yv - X*b
    ssr = cross(e,e)
    if (n > k) s2 = ssr/(n-k)
    else s2 = ssr/n
    if (robust) {
        meat = cross(X, e:^2, X)
        V = (n/(n-k)) * XtXi * meat * XtXi
    }
    else {
        V = s2 * XtXi
    }
    return(ssr)
}

// candidate thresholds from the difference series
real colvector _tn_cand(real colvector dx, real scalar trim, real scalar G)
{
    real colvector v, sv, sub, idx
    real scalar nd, lo, hi
    v = dx[selectindex(dx:!=.)]
    sv = sort(v,1)
    nd = rows(sv)
    lo = floor(trim*nd)+1
    hi = ceil((1-trim)*nd)
    if (lo < 1) lo = 1
    if (hi > nd) hi = nd
    if (hi < lo) {
        lo = 1
        hi = nd
    }
    sub = sv[|lo \ hi|]
    sub = uniqrows(sub)
    if (rows(sub) > G) {
        idx = round(rangen(1, rows(sub), G))
        sub = sub[idx]
        sub = uniqrows(sub)
    }
    return(sub)
}

// profile least squares for a given number of regimes S
// returns min ssr; fills besttau (rowvector length S-1) and (optionally) profile
real scalar _tn_profile(real colvector y, real colvector xT, real matrix W,
        real scalar p, real scalar q, real scalar S,
        real colvector cand, real scalar minobs,
        real scalar consf, real scalar trf,
        rowvector besttau, real matrix profile)
{
    real scalar best, ng, i, j, ssr, nb, na, nm, ok
    real rowvector tau
    real colvector dx, b
    struct tndes scalar d
    real matrix V

    best = .
    besttau = J(1, S-1, .)
    ng = rows(cand)
    dx = xT - _tn_lag(xT,1)

    if (S == 1) {
        d = _tn_design(y, xT, W, p, q, J(1,0,.), consf, trf)
        best = _tn_ols(d.dyv, d.X, 0, b, V)
        profile = J(0,0,.)
        return(best)
    }
    else if (S == 2) {
        profile = J(ng, 2, .)
        for (i=1; i<=ng; i++) {
            tau = cand[i]
            nb = sum(dx :<= tau)
            na = sum(dx :> tau)
            profile[i,1] = cand[i]
            if (nb < minobs | na < minobs) continue
            d = _tn_design(y, xT, W, p, q, tau, consf, trf)
            ssr = _tn_ols(d.dyv, d.X, 0, b, V)
            profile[i,2] = ssr
            if (ssr < best) {
                best = ssr
                besttau = tau
            }
        }
        return(best)
    }
    else {
        // S == 3 : two thresholds tau1 < tau2
        profile = J(0,0,.)
        for (i=1; i<=ng-1; i++) {
            for (j=i+1; j<=ng; j++) {
                tau = (cand[i], cand[j])
                nb = sum(dx :<= tau[1])
                nm = sum((dx :> tau[1]) :& (dx :<= tau[2]))
                na = sum(dx :> tau[2])
                if (nb < minobs | nm < minobs | na < minobs) continue
                d = _tn_design(y, xT, W, p, q, tau, consf, trf)
                ssr = _tn_ols(d.dyv, d.X, 0, b, V)
                if (ssr < best) {
                    best = ssr
                    besttau = tau
                }
            }
        }
        return(best)
    }
}

// QLR statistic + fixed-regressor wild bootstrap p-value (S=1 null vs S=2 alt)
void _tn_qlr(real colvector y, real colvector xT, real matrix W,
        real scalar p, real scalar q, real colvector cand, real scalar minobs,
        real scalar consf, real scalar trf, real scalar B,
        real scalar nN, real scalar qlr_obs, real scalar pval, real scalar dots)
{
    struct tndes scalar d0, d
    real scalar ng, i, bcount, bi, ssr0, ssrT, ssr, nb, na
    real scalar ssr0b, ssrTb, qlrb
    real colvector b0, fit0, e0, dyb, bb, dx
    real matrix V, X0
    pointer(real matrix) rowvector Xs
    pointer(real matrix) rowvector Hs
    real rowvector v

    dx = xT - _tn_lag(xT,1)
    // null design (linear ARDL)
    d0 = _tn_design(y, xT, W, p, q, J(1,0,.), consf, trf)
    X0 = d0.X
    ssr0 = _tn_ols(d0.dyv, X0, 0, b0, V)
    fit0 = X0 * b0
    e0   = d0.dyv - fit0
    nN   = rows(d0.dyv)

    // alternative: profile over candidates, store admissible designs
    ng = rows(cand)
    ssrT = .
    Xs = J(1,0, NULL)
    Hs = J(1,0, NULL)
    for (i=1; i<=ng; i++) {
        nb = sum(dx :<= cand[i])
        na = sum(dx :>  cand[i])
        if (nb < minobs | na < minobs) continue
        d = _tn_design(y, xT, W, p, q, cand[i], consf, trf)
        if (rows(d.dyv) != nN) continue   // alignment guard
        ssr = _tn_ols(d.dyv, d.X, 0, bb, V)
        if (ssr < ssrT) ssrT = ssr
        Xs = Xs, &(d.X)
        Hs = Hs, &(invsym(cross(d.X,d.X)) * d.X')
    }
    qlr_obs = nN * (1 - ssrT/ssr0)

    // bootstrap
    real scalar H0pre
    real matrix H0
    H0 = invsym(cross(X0,X0)) * X0'
    bcount = 0
    real scalar nstore
    nstore = cols(Xs)
    for (bi=1; bi<=B; bi++) {
        v = (runiform(1,nN) :> 0.5) :* 2 :- 1     // Rademacher +/-1
        dyb = fit0 + e0 :* v'
        // null
        ssr0b = quadcross(dyb,dyb) - quadcross(dyb, X0*(H0*dyb))
        // alternative: min over stored designs
        ssrTb = .
        for (i=1; i<=nstore; i++) {
            ssr = quadcross(dyb,dyb) - quadcross(dyb, (*Xs[i])*((*Hs[i])*dyb))
            if (ssr < ssrTb) ssrTb = ssr
        }
        qlrb = nN * (1 - ssrTb/ssr0b)
        if (qlrb >= qlr_obs) bcount++
        if (dots) {
            if (mod(bi,50)==0) printf(".")
            displayflush()
        }
    }
    if (dots) printf("\n")
    pval = (bcount+1)/(B+1)
}

// =====================================================================
// main driver -- reads options & data from Stata, writes results back
// =====================================================================
void _tnardll_run()
{
    real scalar p, q, S, fixedS, maxreg, trim, G, consf, trf, robust
    real scalar doqlr, B, dots, minobs, level
    real scalar i, s, j, nN, k, ssr, sigma2, rmse, tss, r2, r2a, nthr
    real scalar ssr1, ssrS, qlr_obs, qlr_p
    string scalar depvar, thrvar, othervars, touse, ic
    real colvector y, xT, tv, b, cand, rowsused, keepflag, lrb_v, dx
    real matrix W, X, V, Wdummy, profile, ictab, lrV, thetaM, piM, phiM
    struct tndes scalar d
    real rowvector besttau, tauS, lrnames_idx
    real scalar tdelta, ndiff

    // ---- read options ----
    depvar    = st_local("depvar")
    thrvar    = st_local("thrvar")
    othervars = st_local("othervars")
    touse     = st_local("used")               // we will fill esample here
    p   = strtoreal(st_local("p"))
    q   = strtoreal(st_local("q"))
    fixedS  = strtoreal(st_local("regimes"))
    maxreg  = strtoreal(st_local("maxreg"))
    trim    = strtoreal(st_local("trim"))
    G       = strtoreal(st_local("grid"))
    consf   = strtoreal(st_local("consflag"))
    trf     = strtoreal(st_local("trflag"))
    robust  = (st_local("vce")=="robust")
    doqlr   = (st_local("qlr")!="")
    B       = strtoreal(st_local("breps"))
    dots    = (st_local("dots")!="nodots")
    level   = strtoreal(st_local("level"))
    ic      = st_local("ic")

    // ---- pull data over the marked sample (already time-ordered) ----
    real colvector tvar0
    tvar0 = st_data(., st_local("touse"))           // selection vector full length
    rowsused = selectindex(tvar0)                   // dataset rows in the sample

    y  = st_data(., depvar, st_local("touse"))
    xT = st_data(., thrvar, st_local("touse"))
    if (othervars != "") W = st_data(., othervars, st_local("touse"))
    else W = J(rows(y), 0, .)
    tv = st_data(., st_local("timevar"), st_local("touse"))

    // contiguity check
    tdelta = strtoreal(st_local("tdelta"))
    if (rows(tv) > 1) {
        ndiff = sum( (tv[|2 \ rows(tv)|] - tv[|1 \ rows(tv)-1|]) :!= tdelta )
        if (ndiff > 0) {
            st_local("__err", "gaps in the time series are not supported; sample must be contiguous after tsset")
            return
        }
    }

    if (rows(y) < p+q+10) {
        st_local("__err", "too few observations for the requested lag structure")
        return
    }

    // ---- candidate thresholds & minimum regime size ----
    dx = xT - _tn_lag(xT,1)
    cand = _tn_cand(dx, trim, G)
    minobs = max((ceil(0.05*rows(y)), p+q+2))

    // ---- information criteria over S = 1..maxreg ----
    real scalar Smax
    Smax = maxreg
    ictab = J(Smax, 7, .)
    real colvector ssrS_vec
    real matrix tau_store
    ssrS_vec = J(Smax,1,.)
    tau_store = J(Smax, 2, .)

    for (s=1; s<=Smax; s++) {
        ssr = _tn_profile(y, xT, W, p, q, s, cand, minobs, consf, trf, besttau, profile)
        if (ssr==.) continue
        // effective N for this S (rows used)
        d = _tn_design(y, xT, W, p, q, (s==1 ? J(1,0,.) : besttau), consf, trf)
        nN = rows(d.dyv)
        sigma2 = ssr/nN
        // parameter counts
        real scalar npar, nthrp, npar0
        npar  = cols(d.X)            // regression coefficients
        nthrp = s - 1                // thresholds
        // IC = log(sigma2) + (c_T/T)*npars
        real scalar cAIC, cSIC, cHQ
        cAIC = 2
        cSIC = log(nN)
        cHQ  = 2*log(log(nN))
        // standard ICs count thresholds; Pitarakis (p*) exclude them
        ictab[s,1] = s
        ictab[s,2] = log(sigma2) + (cAIC/nN)*(npar+nthrp)   // AIC
        ictab[s,3] = log(sigma2) + (cSIC/nN)*(npar+nthrp)   // SIC
        ictab[s,4] = log(sigma2) + (cHQ /nN)*(npar+nthrp)   // HQIC
        ictab[s,5] = log(sigma2) + (cAIC/nN)*(npar)         // pAIC
        ictab[s,6] = log(sigma2) + (cSIC/nN)*(npar)         // pSIC
        ictab[s,7] = log(sigma2) + (cHQ /nN)*(npar)         // pHQIC
        ssrS_vec[s] = ssr
        if (s >= 2) {
            tau_store[s,1] = besttau[1]
            if (s == 3) tau_store[s,2] = besttau[2]
        }
    }

    // ---- choose S ----
    real scalar iccol
    if (ic=="aic") iccol = 2
    else if (ic=="sic") iccol = 3
    else if (ic=="hqic") iccol = 4
    else if (ic=="paic") iccol = 5
    else if (ic=="psic") iccol = 6
    else iccol = 7

    if (fixedS != 0) {
        S = fixedS
    }
    else {
        real scalar bestic, bs
        bestic = .
        bs = 1
        for (s=1; s<=Smax; s++) {
            if (ictab[s,iccol] != . && ictab[s,iccol] < bestic) {
                bestic = ictab[s,iccol]
                bs = s
            }
        }
        S = bs
    }

    // ---- final fit at chosen S ----
    nthr = S - 1
    if (S == 1) tauS = J(1,0,.)
    else if (S == 2) tauS = tau_store[2,1]
    else tauS = (tau_store[3,1], tau_store[3,2])

    // if fixedS was given we may not have profiled it -- ensure tau available
    // (Mata does not short-circuit &&, so guard the subscript with a nested if:
    //  for S==1 tauS is the 1x0 empty vector and tauS[1] would be invalid)
    if (S >= 2) {
        if (tauS[1]==.) {
            ssr = _tn_profile(y, xT, W, p, q, S, cand, minobs, consf, trf, besttau, profile)
            tauS = besttau
        }
    }

    d = _tn_design(y, xT, W, p, q, tauS, consf, trf)
    ssr = _tn_ols(d.dyv, d.X, robust, b, V)
    nN = rows(d.dyv)
    k  = cols(d.X)
    sigma2 = ssr/(nN-k)
    rmse = sqrt(sigma2)
    tss = quadcross(d.dyv :- mean(d.dyv), d.dyv :- mean(d.dyv))
    r2  = 1 - ssr/tss
    r2a = 1 - (1-r2)*(nN-1)/(nN-k)

    real scalar rho
    rho = b[d.irho]

    // ---- long-run coefficients beta = -theta/rho (delta method) ----
    real scalar nlr, idx
    nlr = S + d.m
    lrb_v = J(nlr,1,.)
    lrV   = J(nlr,nlr,0)
    real rowvector lridx
    lridx = (d.ilr_xT, d.ilr_w)         // indices of long-run level coeffs
    // build via delta method using submatrix over (rho, theta_j)
    real scalar t1, t2
    real colvector grad
    real matrix Vsub
    for (i=1; i<=nlr; i++) {
        idx = lridx[i]
        lrb_v[i] = -b[idx]/rho
    }
    // covariance via stacked Jacobian: beta_i = -b[idx_i]/rho
    // d beta_i/d b[idx_i] = -1/rho ; d beta_i/d rho = b[idx_i]/rho^2
    real matrix Jac
    real rowvector allidx
    allidx = (d.irho, lridx)            // rho first, then thetas
    Vsub = V[allidx, allidx]
    Jac = J(nlr, 1+nlr, 0)
    for (i=1; i<=nlr; i++) {
        Jac[i,1]   = b[lridx[i]]/rho^2     // wrt rho
        Jac[i,1+i] = -1/rho                // wrt theta_i
    }
    lrV = Jac * Vsub * Jac'

    // ---- asymmetry tests ----
    // long-run: H0 theta^(s) all equal across regimes (s=1..S) -> on level coeffs of xT
    real scalar lachi2, ladf, lap, sachi2, sadf, sap
    if (S >= 2) {
        real matrix R, Vr, RbR
        real colvector Rb
        // long-run: differences of consecutive theta (xT regimes)
        R = J(S-1, k, 0)
        for (i=1; i<=S-1; i++) {
            R[i, d.ilr_xT[i]]   =  1
            R[i, d.ilr_xT[i+1]] = -1
        }
        Rb  = R*b
        RbR = R*V*R'
        lachi2 = (Rb' * invsym(RbR) * Rb)
        ladf = S-1
        lap = chi2tail(ladf, lachi2)

        // short-run: sum_j pi^(s) equal across regimes
        R = J(S-1, k, 0)
        for (i=1; i<=S-1; i++) {
            for (j=1; j<=q; j++) {
                R[i, d.ipi[i,j]]   =  1
                R[i, d.ipi[i+1,j]] = -1
            }
        }
        Rb  = R*b
        RbR = R*V*R'
        sachi2 = (Rb' * invsym(RbR) * Rb)
        sadf = S-1
        sap = chi2tail(sadf, sachi2)
    }
    else {
        lachi2=.; ladf=0; lap=.
        sachi2=.; sadf=0; sap=.
    }

    // ---- PSS bounds test : F for rho=0 and all long-run levels =0 ----
    real scalar pssk, Fpss, tBDM
    real rowvector bidx
    real matrix Rp, Vp
    real colvector Rbp
    pssk = nlr
    bidx = (d.irho, lridx)
    Rp = J(cols(bidx), k, 0)
    for (i=1; i<=cols(bidx); i++) Rp[i, bidx[i]] = 1
    Rbp = Rp*b
    Vp  = Rp*V*Rp'
    Fpss = (Rbp' * invsym(Vp) * Rbp) / cols(bidx)
    tBDM = b[d.irho]/sqrt(V[d.irho,d.irho])

    // ---- QLR (optional) ----
    if (doqlr) {
        real scalar nNq
        if (dots) printf("{txt}bootstrapping QLR (B=%g) ", B)
        _tn_qlr(y, xT, W, p, q, cand, minobs, consf, trf, B, nNq, qlr_obs, qlr_p, dots)
        st_numscalar("__qlr", qlr_obs)
        st_numscalar("__qlrp", qlr_p)
    }

    // ---- structural pieces for multipliers ----
    // theta : S-vector (level coeffs on xT regimes)
    thetaM = J(S,1,.)
    for (s=1; s<=S; s++) thetaM[s] = b[d.ilr_xT[s]]
    // pi : S x q
    piM = J(S,q,.)
    for (s=1; s<=S; s++) for (j=1; j<=q; j++) piM[s,j] = b[d.ipi[s,j]]
    // phi : (p-1) vector
    if (p > 1) {
        phiM = J(p-1,1,.)
        for (j=1; j<=p-1; j++) phiM[j] = b[d.iphi[j]]
        st_matrix("__phi", phiM)
    }

    // ---- write esample flag ----
    keepflag = J(st_nobs(),1,0)
    keepflag[rowsused[d.keep]] = J(rows(d.keep),1,1)
    st_store(., st_local("used"), keepflag)

    // ---- write results back ----
    st_matrix("__b", b')
    st_matrix("__V", V)
    st_matrix("__lrb", lrb_v')
    st_matrix("__lrV", lrV)
    st_matrix("__ictab", ictab[selectindex(ictab[.,1]:!=.), .])
    st_matrix("__theta", thetaM)
    st_matrix("__pimat", piM)
    if (S >= 2) st_matrix("__thr", tauS')
    if (S == 2 && rows(profile) > 0) st_matrix("__profile", profile)

    // long-run coefficient names (for colnames in ado)
    string scalar lrnm
    lrnm = ""
    for (s=1; s<=S; s++) lrnm = lrnm + " lr_" + thrvar + "_r" + strofreal(s)
    if (othervars != "") {
        string rowvector ow
        ow = tokens(othervars)
        for (j=1; j<=cols(ow); j++) lrnm = lrnm + " lr_" + ow[j]
    }
    st_local("__lrnames", lrnm)

    st_numscalar("__S", S)
    st_numscalar("__N", nN)
    st_numscalar("__k", k)
    st_numscalar("__df_r", nN-k)
    st_numscalar("__rho", rho)
    st_numscalar("__ssr", ssr)
    st_numscalar("__rmse", rmse)
    st_numscalar("__r2", r2)
    st_numscalar("__r2_a", r2a)
    st_numscalar("__lachi2", lachi2)
    st_numscalar("__ladf", ladf)
    st_numscalar("__lap", lap)
    st_numscalar("__sachi2", sachi2)
    st_numscalar("__sadf", sadf)
    st_numscalar("__sap", sap)
    st_numscalar("__pssk", pssk)
    st_numscalar("__Fpss", Fpss)
    st_numscalar("__tBDM", tBDM)
    st_local("__err", "")
}
end
