*! mindf 1.0.0 08jul2026 Ozan Eruygur
* Harvey, Leybourne and Taylor (2013, Journal of Econometrics 177, 265-284)
* Minimum Dickey-Fuller unit root tests with multiple trend breaks (MDF1, MDF2, MDF3)
* Port of the original GAUSS code mindf.gp (Granger Centre, University of Nottingham)

program define mindf, rclass
    version 14

    syntax varname(numeric ts) [if] [in], BREAKs(integer) [KMAX(integer -1) LAGS(integer -1)]

    if !inlist(`breaks',1,2,3) {
        di as err "breaks() must be 1, 2 or 3"
        exit 198
    }
    * trimming and minimum break separation are fixed at 0.15, as in HLT and the original GAUSS code
    local trim = 0.15
    local sepf = 0.15
    if `lags' < -1 {
        di as err "lags() must be a nonnegative integer"
        exit 198
    }
    if `kmax' < -1 {
        di as err "kmax() must be a nonnegative integer"
        exit 198
    }

    quietly capture tsset
    if _rc {
        di as err "data must be tsset with a time variable"
        exit 459
    }
    if "`r(panelvar)'" != "" {
        di as err "panel data are not supported; mindf requires a single time series"
        exit 459
    }
    local tvar `r(timevar)'
    local tfmt : format `tvar'

    tsrevar `varlist'
    local yv `r(varlist)'

    marksample touse, novarlist
    markout `touse' `yv'

    quietly tsreport if `touse'
    if r(N_gaps) > 0 {
        di as err "sample contains gaps in the time series; mindf requires a contiguous sample"
        exit 498
    }

    quietly count if `touse'
    local n = r(N)
    if `n' < 25 {
        di as err "insufficient observations (N = `n'); at least 25 required"
        exit 2001
    }

    local kmaxv = cond(`kmax'==-1, floor(12*(`n'/100)^0.25), `kmax')
    local tbL = floor(`trim'*`n')
    local tbU = floor((1-`trim')*`n')
    local sepn = floor(`sepf'*`n')
    if `tbL' < 1 | `tbU' <= `tbL' {
        di as err "trimming leaves no admissible break dates"
        exit 498
    }
    if `tbL' + (`breaks'-1)*`sepn' > `tbU' {
        di as err "insufficient sample for breaks(`breaks')"
        exit 498
    }
    if `lags' >= 0 & `n' - `lags' - 1 < `lags' + 3 {
        di as err "lags() too large for the available sample"
        exit 498
    }

    mata: mindf_run("`yv'", "`touse'", "`tvar'", `breaks', `tbL', `tbU', `sepn', `kmaxv', `lags', 0)

    * critical values from HLT (2013), Table 1 (trim 0.15, separation 0.15)
    if `breaks' == 1 {
        local cv10 = -3.57
        local cv5  = -3.85
        local cv1  = -4.40
        local cbar = 17.6
    }
    if `breaks' == 2 {
        local cv10 = -4.30
        local cv5  = -4.58
        local cv1  = -5.10
        local cbar = 21.5
    }
    if `breaks' == 3 {
        local cv10 = -4.81
        local cv5  = -5.06
        local cv1  = -5.58
        local cbar = 25.5
    }

    di as text ""
    di as text "Harvey, Leybourne and Taylor (2013) minimum Dickey-Fuller test (MDF`breaks')"
    di as text "{hline 72}"
    local dfirst = trim(`"`: display `tfmt' `=scalar(__MDF_tfirst)''"')
    local dlast = trim(`"`: display `tfmt' `=scalar(__MDF_tlast)''"')
    di as text "Series           : " as result "`varlist'"
    di as text "Sample           : " as result "`dfirst'" as text " - " as result "`dlast'" as text "   (T = " as result `n' as text ")"
    di as text "Trend breaks     : " as result "`breaks'" as text "   (model: constant, trend, broken trends; GLS cbar = " as result "`cbar'" as text ")"
    di as text "Trimming         : " as result "`trim'" as text "   minimum break separation: " as result "`sepf'"
    if `lags' == -1 {
        di as text "Lag selection    : " as result "MAIC" as text " on OLS-detrended residuals (Perron-Qu 2007), kmax = " as result "`kmaxv'"
    }
    else {
        di as text "Lag selection    : " as result "fixed, k = `lags'"
    }
    di as text "{hline 72}"
    di as text "MDF`breaks' statistic   : " as result %8.3f scalar(__MDF_stat)
    di as text "Critical values  :   1%: " as result %7.2f `cv1' as text "    5%: " as result %7.2f `cv5' as text "   10%: " as result %7.2f `cv10'
    di as text "{hline 72}"
    di as text "Break dates minimizing the DF statistic:"
    forvalues i = 1/`breaks' {
        local dtb = trim(`"`: display `tfmt' `=scalar(__MDF_t`i')''"')
        di as text "  break `i' : obs " as result %4.0f scalar(__MDF_i`i') as text "   date " as result "`dtb'"
    }
    di as text "  k at argmin = " as result %2.0f scalar(__MDF_kopt)
    di as text "{hline 72}"

    return scalar mdf    = scalar(__MDF_stat)
    return scalar breaks = `breaks'
    return scalar cbar   = `cbar'
    return scalar cv1    = `cv1'
    return scalar cv5    = `cv5'
    return scalar cv10   = `cv10'
    return scalar N      = `n'
    return scalar trim   = `trim'
    return scalar sep    = `sepf'
    return scalar kmax   = `kmaxv'
    return scalar k      = scalar(__MDF_kopt)
    forvalues i = 1/`breaks' {
        return scalar obs`i' = scalar(__MDF_i`i')
        return scalar tb`i'  = scalar(__MDF_t`i')
    }
    return local varname `varlist'
    return local cmd mindf

    capture scalar drop __MDF_stat __MDF_kopt __MDF_tfirst __MDF_tlast
    forvalues i = 1/3 {
        capture scalar drop __MDF_i`i' __MDF_t`i' __MDF_ki`i' __MDF_kt`i' __MDF_g`i' __MDF_kap`i'
    }
    capture scalar drop __MDF_om2 __MDF_bw
end

version 14
mata:

// ----------------------------------------------------------------
// local GLS detrending, port of proc GLS_bt in mindf.gp
// quasi-difference with alpha = 1 - cbar/n, first row kept in levels
// returns the level-detrended series y - x*beta
// ----------------------------------------------------------------
real colvector mindf_glsbt(real colvector y, real matrix x, real scalar cbar)
{
    real scalar n, a
    real colvector ye, beta
    real matrix ze

    n = rows(y)
    a = 1 - cbar/n
    ye = y[1] \ (y[2::n] - a*y[1::n-1])
    ze = x[1,.] \ (x[2::n,.] - a*x[1::n-1,.])
    beta = invsym(quadcross(ze,ze))*quadcross(ze,ye)
    return(y - x*beta)
}

// ----------------------------------------------------------------
// GLS regression returning coefficients and quasi-differenced
// residuals, port of proc GLS_bt2 in mindf.gp (used by kappa block)
// ----------------------------------------------------------------
void mindf_glsbt2(real colvector y, real matrix x, real scalar cbar, real colvector beta, real colvector r)
{
    real scalar n, a
    real colvector ye
    real matrix ze

    n = rows(y)
    a = 1 - cbar/n
    ye = y[1] \ (y[2::n] - a*y[1::n-1])
    ze = x[1,.] \ (x[2::n,.] - a*x[1::n-1,.])
    beta = invsym(quadcross(ze,ze))*quadcross(ze,ye)
    r = ye - ze*beta
}

// ----------------------------------------------------------------
// ADF t-statistic without deterministics, port of proc DF
// regression: dr_t = pi*r_{t-1} + sum_j psi_j dr_{t-j} + e_t
// effective sample t = k+2 .. n, s2 df-corrected
// ----------------------------------------------------------------
real scalar mindf_df(real colvector r, real scalar k)
{
    real scalar n, lo, T, j, s2
    real colvector dr, dep, b, res
    real matrix X, iXX

    n = rows(r)
    dr = J(n,1,.)
    dr[2::n] = r[2::n] - r[1::n-1]
    lo = k + 2
    T = n - k - 1
    X = J(T, 1+k, 0)
    X[.,1] = r[lo-1::n-1]
    for (j=1; j<=k; j++) {
        X[.,1+j] = dr[lo-j::n-j]
    }
    dep = dr[lo::n]
    iXX = invsym(quadcross(X,X))
    b = iXX*quadcross(X,dep)
    res = dep - X*b
    s2 = quadcross(res,res)/(T - cols(X))
    return(b[1]/sqrt(s2*iXX[1,1]))
}

// ----------------------------------------------------------------
// MAIC lag selection, port of proc kMAIC (Ng-Perron 2001)
// common effective sample t = kmax+2 .. n for all candidate k
// s2 = RSS/(n-kmax-1) without df correction, first minimum returned
// ----------------------------------------------------------------
real scalar mindf_kmaic(real colvector r, real scalar kmax)
{
    real scalar n, lo, T, k, j, s2, tauk, crit, best, kopt
    real colvector dr, dep, b, res
    real matrix X, iXX

    n = rows(r)
    dr = J(n,1,.)
    dr[2::n] = r[2::n] - r[1::n-1]
    lo = kmax + 2
    T = n - kmax - 1
    dep = dr[lo::n]
    best = .
    kopt = 0
    for (k=0; k<=kmax; k++) {
        X = J(T, 1+k, 0)
        X[.,1] = r[lo-1::n-1]
        for (j=1; j<=k; j++) {
            X[.,1+j] = dr[lo-j::n-j]
        }
        iXX = invsym(quadcross(X,X))
        b = iXX*quadcross(X,dep)
        res = dep - X*b
        s2 = quadcross(res,res)/(n - kmax - 1)
        tauk = (b[1]^2)*quadcross(X[.,1],X[.,1])/s2
        crit = ln(s2) + 2*(tauk + k)/(n - kmax - 1)
        if (crit < best) {
            best = crit
            kopt = k
        }
    }
    return(kopt)
}

// ----------------------------------------------------------------
// Bartlett kernel long-run variance, port of proc bart
// ----------------------------------------------------------------
real scalar mindf_bart(real colvector u, real scalar l)
{
    real scalar n, j, s

    n = rows(u)
    s = quadcross(u,u)
    if (l > 0) {
        for (j=1; j<=l; j++) {
            s = s + 2*(1 - j/(l+1))*quadcross(u[j+1::n], u[1::n-j])
        }
    }
    return(s/n)
}

// ----------------------------------------------------------------
// broken trend regressor DT_t(tb) = max(t - tb, 0)
// ----------------------------------------------------------------
real colvector mindf_dt(real scalar n, real scalar tb)
{
    return(J(tb,1,0) \ (1::n-tb))
}

// ----------------------------------------------------------------
// lag order for one candidate: fixed k or MAIC on OLS-detrended
// residuals (Perron-Qu 2007 hybrid, as in mindf.gp)
// ----------------------------------------------------------------
real scalar mindf_getk(real colvector y, real matrix z, real scalar kmax, real scalar lagsu)
{
    real colvector bo

    if (lagsu >= 0) return(lagsu)
    bo = invsym(quadcross(z,z))*quadcross(z,y)
    return(mindf_kmaic(y - z*bo, kmax))
}

// ----------------------------------------------------------------
// main engine
// ----------------------------------------------------------------
void mindf_run(string scalar yname, string scalar tousen, string scalar tvname, real scalar m, real scalar tbL, real scalar tbU, real scalar sepn, real scalar kmax, real scalar lagsu, real scalar dokap)
{
    real colvector y, tv, cn, tr, rg, dep, b, res, beta, rq
    real matrix z, X
    real scalar n, cbar, best, b1, b2, b3, kbest, tb1, tb2, tb3, kk, s
    real scalar rbest, r1, r2, r3, rss, i, l, om2, T1
    real colvector e

    y = st_data(., yname, tousen)
    tv = st_data(., tvname, tousen)
    n = rows(y)

    if (m == 1) cbar = 17.6
    if (m == 2) cbar = 21.5
    if (m == 3) cbar = 25.5

    cn = J(n,1,1)
    tr = (1::n)

    best = .
    b1 = b2 = b3 = .
    kbest = .

    if (m == 1) {
        for (tb1=tbL; tb1<=tbU; tb1++) {
            z = cn, tr, mindf_dt(n,tb1)
            rg = mindf_glsbt(y, z, cbar)
            kk = mindf_getk(y, z, kmax, lagsu)
            s = mindf_df(rg, kk)
            if (s < best) {
                best = s
                b1 = tb1
                kbest = kk
            }
        }
    }
    if (m == 2) {
        for (tb1=tbL; tb1<=tbU-sepn; tb1++) {
            for (tb2=tb1+sepn; tb2<=tbU; tb2++) {
                z = cn, tr, mindf_dt(n,tb1), mindf_dt(n,tb2)
                rg = mindf_glsbt(y, z, cbar)
                kk = mindf_getk(y, z, kmax, lagsu)
                s = mindf_df(rg, kk)
                if (s < best) {
                    best = s
                    b1 = tb1
                    b2 = tb2
                    kbest = kk
                }
            }
        }
    }
    if (m == 3) {
        for (tb1=tbL; tb1<=tbU-2*sepn; tb1++) {
            for (tb2=tb1+sepn; tb2<=tbU-sepn; tb2++) {
                for (tb3=tb2+sepn; tb3<=tbU; tb3++) {
                    z = cn, tr, mindf_dt(n,tb1), mindf_dt(n,tb2), mindf_dt(n,tb3)
                    rg = mindf_glsbt(y, z, cbar)
                    kk = mindf_getk(y, z, kmax, lagsu)
                    s = mindf_df(rg, kk)
                    if (s < best) {
                        best = s
                        b1 = tb1
                        b2 = tb2
                        b3 = tb3
                        kbest = kk
                    }
                }
            }
        }
    }

    st_numscalar("__MDF_stat", best)
    st_numscalar("__MDF_kopt", kbest)
    st_numscalar("__MDF_tfirst", tv[1])
    st_numscalar("__MDF_tlast", tv[n])
    st_numscalar("__MDF_i1", b1)
    st_numscalar("__MDF_t1", tv[b1])
    if (m >= 2) {
        st_numscalar("__MDF_i2", b2)
        st_numscalar("__MDF_t2", tv[b2])
    }
    if (m >= 3) {
        st_numscalar("__MDF_i3", b3)
        st_numscalar("__MDF_t3", tv[b3])
    }

    if (dokap == 0) return

    // ------------------------------------------------------------
    // kappa diagnostics, HLT (2013) Section 4.3
    // step 1: break dates by SSR minimization in first differences
    //         (regressors: constant and level-shift dummies DU,
    //          the first-difference counterparts of broken trends)
    // ------------------------------------------------------------
    dep = y[2::n] - y[1::n-1]
    e = (2::n)
    T1 = n - 1
    rbest = .
    r1 = r2 = r3 = .

    if (m == 1) {
        for (tb1=tbL; tb1<=tbU; tb1++) {
            X = J(T1,1,1), (e :> tb1)
            b = invsym(quadcross(X,X))*quadcross(X,dep)
            res = dep - X*b
            rss = quadcross(res,res)
            if (rss < rbest) {
                rbest = rss
                r1 = tb1
            }
        }
    }
    if (m == 2) {
        for (tb1=tbL; tb1<=tbU-sepn; tb1++) {
            for (tb2=tb1+sepn; tb2<=tbU; tb2++) {
                X = J(T1,1,1), (e :> tb1), (e :> tb2)
                b = invsym(quadcross(X,X))*quadcross(X,dep)
                res = dep - X*b
                rss = quadcross(res,res)
                if (rss < rbest) {
                    rbest = rss
                    r1 = tb1
                    r2 = tb2
                }
            }
        }
    }
    if (m == 3) {
        for (tb1=tbL; tb1<=tbU-2*sepn; tb1++) {
            for (tb2=tb1+sepn; tb2<=tbU-sepn; tb2++) {
                for (tb3=tb2+sepn; tb3<=tbU; tb3++) {
                    X = J(T1,1,1), (e :> tb1), (e :> tb2), (e :> tb3)
                    b = invsym(quadcross(X,X))*quadcross(X,dep)
                    res = dep - X*b
                    rss = quadcross(res,res)
                    if (rss < rbest) {
                        rbest = rss
                        r1 = tb1
                        r2 = tb2
                        r3 = tb3
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------
    // step 2: local GLS regression at the estimated dates
    // step 3: kappa_i = gamma_i * omega^{-1} * sqrt(T), omega^2 by
    //         Bartlett kernel on quasi-differenced GLS residuals,
    //         bandwidth floor(12*(T/100)^(1/4))
    // ------------------------------------------------------------
    z = cn, tr, mindf_dt(n,r1)
    if (m >= 2) z = z, mindf_dt(n,r2)
    if (m >= 3) z = z, mindf_dt(n,r3)

    beta = .
    rq = .
    mindf_glsbt2(y, z, cbar, beta, rq)
    l = floor(12*(n/100)^0.25)
    om2 = mindf_bart(rq, l)

    st_numscalar("__MDF_om2", om2)
    st_numscalar("__MDF_bw", l)
    st_numscalar("__MDF_ki1", r1)
    st_numscalar("__MDF_kt1", tv[r1])
    st_numscalar("__MDF_g1", beta[3])
    st_numscalar("__MDF_kap1", beta[3]*sqrt(n)/sqrt(om2))
    if (m >= 2) {
        st_numscalar("__MDF_ki2", r2)
        st_numscalar("__MDF_kt2", tv[r2])
        st_numscalar("__MDF_g2", beta[4])
        st_numscalar("__MDF_kap2", beta[4]*sqrt(n)/sqrt(om2))
    }
    if (m >= 3) {
        st_numscalar("__MDF_ki3", r3)
        st_numscalar("__MDF_kt3", tv[r3])
        st_numscalar("__MDF_g3", beta[5])
        st_numscalar("__MDF_kap3", beta[5]*sqrt(n)/sqrt(om2))
    }
}

end
