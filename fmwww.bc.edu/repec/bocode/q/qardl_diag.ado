*! qardl_diag v1.2.0 - Residual diagnostics for QARDL
*! Translates ardlResidualDiagnostics and printARDLResidualDiagnostics
*! from GAUSS QARDL 3.1.1 (diagnostics.src)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Postestimation after qardl:
*!   qardl_diag [, lags(#) graph]
*!
*! Every test is applied separately to the residual series of each
*! quantile, since a QARDL fit produces one residual series per tau.

program define qardl_diag, rclass
    version 14.0

    capture mata which _qardl_ic_design()
    if _rc {
        capture program drop _qardl_icmean
        qui findfile _qardl_icmean.ado
        qui run "`r(fn)'"
    }

    syntax [, LAGS(integer 0) GRAPH NOTABle]

    if "`e(cmd)'" != "qardl" {
        di as error "qardl estimation results not found"
        exit 301
    }

    * The scalar levels design is assumed below; a per-regressor lag
    * vector needs the generalised design and is not supported here.
    capture confirm matrix e(qvec)
    if _rc == 0 {
        di as error "not supported after qvec(); re-estimate with a scalar q()"
        exit 198
    }

    if `lags' < 0 {
        di as error "lags() must be non-negative"
        exit 198
    }

    local p = e(p)
    local q = e(q)
    local k = e(k)
    local ntau = e(ntau)
    local depvar "`e(depvar)'"
    local indepvars "`e(indepvars)'"

    tempname bt tau_vec
    mat `bt' = e(bt_raw)
    mat `tau_vec' = e(tau)

    * Rebuild the estimation sample and the levels design
    tempvar touse
    qui gen byte `touse' = e(sample)

    qui putmata _dg_y = `depvar' if `touse', replace
    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _dg_X = (`mxvars') if `touse', replace

    mata: _qardl_diag_run(_dg_y, _dg_X, `p', `q', "`bt'", `lags')

    tempname D cusum cusumsq
    mat `D' = _qardl_dg_results
    mat `cusum' = _qardl_dg_cusum
    mat `cusumsq' = _qardl_dg_cusumsq
    local nobs_r = _qardl_dg_nobs
    local lags_u = _qardl_dg_lags

    if "`notable'" == "" {
        _qardl_diag_print `D' `tau_vec' `nobs_r' `lags_u'
    }

    if "`graph'" != "" {
        _qardl_diag_graph `cusum' `cusumsq' `tau_vec' `nobs_r'
    }

    return matrix diag = `D'
    return matrix cusum = `cusum'
    return matrix cusumsq = `cusumsq'
    return scalar lags = `lags_u'
    return scalar N = `nobs_r'
end

* ============================================================
* Diagnostics table
*   D has one row per (quantile, test): columns are
*   [tau_index, test_index, statistic, df, p-value]
* ============================================================
capture program drop _qardl_diag_print
program define _qardl_diag_print
    args D tau_vec nobs lags

    local ntau = rowsof(`tau_vec')
    local ntest = 8

    di as txt _n "{hline 78}"
    di as res "  QARDL Residual Diagnostics"
    di as txt "{hline 78}"
    di as txt "  Residual observations : " as res `nobs' _c
    di as txt "        Serial-correlation lags : " as res `lags'
    di as txt "  One residual series per quantile is tested separately."
    di as txt "{hline 78}"

    local t1 "Ljung-Box"
    local t2 "Breusch-Godfrey"
    local t3 "Breusch-Pagan"
    local t4 "ARCH LM"
    local t5 "Jarque-Bera"
    local t6 "RESET"
    local t7 "CUSUM"
    local t8 "CUSUMSQ"

    local h1 "H0: no serial correlation up to `lags' lags"
    local h2 "H0: no serial correlation up to `lags' lags"
    local h3 "H0: homoskedastic residuals"
    local h4 "H0: no ARCH effects up to `lags' lags"
    local h5 "H0: residuals are normally distributed"
    local h6 "H0: no neglected nonlinearity in the fit"
    local h7 "H0: parameter stability (mean)"
    local h8 "H0: parameter stability (variance)"

    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        di as txt _n "  {hline 4} tau = " %5.2f `tv' " {hline 60}"
        di as txt "  {ralign 18:Test}" _c
        di as txt "  {ralign 14:Statistic}" _c
        di as txt "  {ralign 8:df}" _c
        di as txt "  {ralign 12:p-value}" _c
        di as txt "  {ralign 5:Sig.}" _c
        di as txt "  {ralign 14:Verdict}"
        di as txt "  {hline 74}"

        forvalues j = 1/`ntest' {
            local row = (`t' - 1) * `ntest' + `j'
            local st = `D'[`row', 3]
            local df = `D'[`row', 4]
            local pv = `D'[`row', 5]

            if `pv' >= .          local star ""
            else if `pv' < 0.01   local star "***"
            else if `pv' < 0.05   local star "**"
            else if `pv' < 0.10   local star "*"
            else                  local star ""

            if `pv' >= .          local verdict "n/a"
            else if `pv' < 0.05   local verdict "Reject H0"
            else                  local verdict "OK"

            di as txt "  {ralign 18:`t`j''}" _c
            di as res "  {ralign 14:" %12.4f `st' "}" _c
            if `df' >= . {
                di as txt "  {ralign 8:.}" _c
            }
            else {
                di as txt "  {ralign 8:`= `df''}" _c
            }
            if `pv' < 0.05 {
                di as res "  {ralign 12:" %10.4f `pv' "}" _c
                di as res "  {ralign 5:`star'}" _c
                di as res "  {ralign 14:`verdict'}"
            }
            else {
                di as txt "  {ralign 12:" %10.4f `pv' "}" _c
                di as txt "  {ralign 5:`star'}" _c
                di as res "  {ralign 14:`verdict'}"
            }
        }
    }

    di as txt "  {hline 74}"
    di as txt "  *** p<0.01, ** p<0.05, * p<0.10"

    di as txt _n "  {bf:Null hypotheses}"
    di as txt "  {hline 74}"
    forvalues j = 1/`ntest' {
        di as txt "  {ralign 18:`t`j''}" _c
        di as txt "   `h`j''"
    }
    di as txt "  {hline 74}"
    di as txt "  CUSUM and CUSUMSQ p-values use the Kolmogorov-Smirnov"
    di as txt "  asymptotic distribution; the 5% critical value is 1.3581."
    di as txt "  Rejection of the serial-correlation or ARCH nulls suggests"
    di as txt "  reporting covariance(hac) standard errors."
    di as txt "{hline 78}"
end

* ============================================================
* CUSUM / CUSUMSQ paths
* ============================================================
capture program drop _qardl_diag_graph
program define _qardl_diag_graph
    args cusum cusumsq tau_vec nobs

    local ntau = rowsof(`tau_vec')

    preserve
    clear
    qui set obs `nobs'
    qui gen int obsn = _n

    local pc ""
    local pq ""
    forvalues t = 1/`ntau' {
        local tv = `tau_vec'[`t', 1]
        local tlab : di %4.2f `tv'

        qui gen double cs`t' = .
        qui gen double cq`t' = .
        forvalues i = 1/`nobs' {
            qui replace cs`t' = `cusum'[`i', `t'] in `i'
            qui replace cq`t' = `cusumsq'[`i', `t'] in `i'
        }

        twoway (line cs`t' obsn, lcolor("0 51 102") lwidth(medthick)) ///
               (function y =  1.3581, range(1 `nobs') lcolor(red) lpattern(dash)) ///
               (function y = -1.3581, range(1 `nobs') lcolor(red) lpattern(dash)), ///
            title("{bf:CUSUM, tau = `tlab'}", size(small) color("0 51 102")) ///
            xtitle("Observation", size(vsmall)) ytitle("", size(vsmall)) ///
            legend(off) graphregion(color(white)) ///
            name(qardl_cusum`t', replace) nodraw
        local pc "`pc' qardl_cusum`t'"

        twoway (line cq`t' obsn, lcolor("0 102 51") lwidth(medthick)) ///
               (function y = 0, range(1 `nobs') lcolor(gs8) lpattern(dash)), ///
            title("{bf:CUSUMSQ, tau = `tlab'}", size(small) color("0 102 51")) ///
            xtitle("Observation", size(vsmall)) ytitle("", size(vsmall)) ///
            legend(off) graphregion(color(white)) ///
            name(qardl_cusumsq`t', replace) nodraw
        local pq "`pq' qardl_cusumsq`t'"
    }

    graph combine `pc' `pq', ///
        title("{bf:QARDL residual stability}", size(medsmall) color("0 51 102")) ///
        graphregion(color(white)) name(qardl_stability, replace)

    di as txt _n "  Graph created: " as res "qardl_stability"

    restore
end

* ============================================================
* Mata
* ============================================================
capture mata: mata drop _qardl_dg_r2()
capture mata: mata drop _qardl_dg_ljungbox()
capture mata: mata drop _qardl_dg_bglm()
capture mata: mata drop _qardl_dg_archlm()
capture mata: mata drop _qardl_dg_bp()
capture mata: mata drop _qardl_dg_reset()
capture mata: mata drop _qardl_dg_jb()
capture mata: mata drop _qardl_dg_kspv()
capture mata: mata drop _qardl_diag_run()

mata:
mata set matastrict off

// R-squared of an auxiliary regression, clipped to [0,1].
real scalar _qardl_dg_r2(real colvector y, real matrix X)
{
    real colvector bt, e, d
    real scalar rss, tss, r2

    bt = pinv(X' * X) * X' * y
    e  = y - X * bt
    rss = e' * e
    d = y :- mean(y)
    tss = d' * d

    if (tss <= 1e-14) return(0)

    r2 = 1 - rss / tss
    if (r2 < 0) r2 = 0
    if (r2 > 1) r2 = 1

    return(r2)
}

// Ljung-Box Q on the demeaned residual series.
real rowvector _qardl_dg_ljungbox(real colvector e, real scalar lags)
{
    real scalar nobs, denom, hh, acf_h, qstat
    real colvector u

    nobs = rows(e)
    u = e :- mean(e)
    denom = u' * u
    if (denom <= 1e-14) return((., ., .))

    qstat = 0
    for (hh = 1; hh <= lags; hh++) {
        acf_h = (u[(hh+1)..nobs]' * u[1..(nobs-hh)]) / denom
        qstat = qstat + acf_h^2 / (nobs - hh)
    }
    qstat = nobs * (nobs + 2) * qstat

    return((qstat, lags, chi2tail(lags, qstat)))
}

// Breusch-Godfrey LM: e on [1, fitted, e(-1)..e(-L)].
real rowvector _qardl_dg_bglm(real colvector e, real colvector fitted,
    real scalar lags)
{
    real scalar nobs, N, jj, df, stat, rnk_z, rnk_base
    real colvector y
    real matrix lagmat, base, z

    nobs = rows(e)
    N = nobs - lags
    if (N <= lags + 2) return((0, lags, 1))

    y = e[(lags+1)..nobs]
    lagmat = J(N, lags, 0)
    for (jj = 1; jj <= lags; jj++) {
        lagmat[., jj] = e[(lags+1-jj)..(nobs-jj)]
    }
    base = (J(N, 1, 1), fitted[(lags+1)..nobs])
    z = (base, lagmat)

    rnk_z = rank(z)
    rnk_base = rank(base)
    df = rnk_z - rnk_base
    if (df < 1) return((0, 1, 1))

    stat = N * _qardl_dg_r2(y, z)

    return((stat, df, chi2tail(df, stat)))
}

// Engle ARCH LM: e^2 on [1, e^2(-1)..e^2(-L)].
real rowvector _qardl_dg_archlm(real colvector e, real scalar lags)
{
    real scalar nobs, N, jj, stat
    real colvector e2, y
    real matrix lagmat, z

    nobs = rows(e)
    N = nobs - lags
    if (N <= lags + 1) return((0, lags, 1))

    e2 = e :* e
    y = e2[(lags+1)..nobs]
    lagmat = J(N, lags, 0)
    for (jj = 1; jj <= lags; jj++) {
        lagmat[., jj] = e2[(lags+1-jj)..(nobs-jj)]
    }
    z = (J(N, 1, 1), lagmat)

    stat = N * _qardl_dg_r2(y, z)

    return((stat, lags, chi2tail(lags, stat)))
}

// Breusch-Pagan: e^2 on [1, fitted].
real rowvector _qardl_dg_bp(real colvector e, real colvector fitted)
{
    real scalar nobs, df, stat, rnk
    real colvector y
    real matrix z

    nobs = rows(e)
    y = e :* e
    z = (J(nobs, 1, 1), fitted)

    rnk = rank(z' * z)
    df = rnk - 1
    if (df < 1) return((., ., .))

    stat = nobs * _qardl_dg_r2(y, z)

    return((stat, df, chi2tail(df, stat)))
}

// Ramsey RESET: e on [1, fitted, fitted^2, fitted^3].
//
// The fitted values are standardised before the powers are formed.  The
// span of [1, f, f^2, f^3] is invariant to an affine transformation of
// f, so the statistic is unchanged in exact arithmetic, but the raw
// version is catastrophically ill-conditioned whenever the fitted values
// are large: with f of order 1e3, f^3 is of order 1e9 and the condition
// number of the auxiliary design reaches 4e9.  Stata's rank() then
// reports a rank deficiency that is not there and the test collapses to
// a statistic of exactly zero.  Standardising brings the condition
// number down to about 5.
real rowvector _qardl_dg_reset(real colvector e, real colvector fitted)
{
    real scalar nobs, df, stat, rnk_z, rnk_base, sd
    real colvector f
    real matrix base, z

    nobs = rows(e)

    sd = sqrt(variance(fitted))
    if (sd <= 1e-14) return((0, 1, 1))
    f = (fitted :- mean(fitted)) / sd

    base = (J(nobs, 1, 1), f)
    z = (base, f:^2, f:^3)

    rnk_z = rank(z)
    rnk_base = rank(base)
    df = rnk_z - rnk_base
    if (df < 1) return((0, 1, 1))

    stat = nobs * _qardl_dg_r2(e, z)

    return((stat, df, chi2tail(df, stat)))
}

// Jarque-Bera normality.
real rowvector _qardl_dg_jb(real colvector e)
{
    real scalar nobs, m2, skew, kurt, jb
    real colvector u

    nobs = rows(e)
    u = e :- mean(e)
    m2 = mean(u :* u)
    if (m2 <= 1e-14) return((., ., .))

    skew = mean(u :* u :* u) / (m2^(3/2))
    kurt = mean(u :* u :* u :* u) / (m2^2)
    jb = (nobs / 6) * (skew^2 + ((kurt - 3)^2) / 4)

    return((jb, 2, chi2tail(2, jb)))
}

// Kolmogorov-Smirnov asymptotic tail probability.
real scalar _qardl_dg_kspv(real scalar stat)
{
    real scalar jj, term, pv, sgn

    if (stat <= 0) return(1)

    pv = 0
    sgn = 1
    for (jj = 1; jj <= 100; jj++) {
        term = exp(-2 * (jj^2) * (stat^2))
        pv = pv + sgn * term
        if (term < 1e-12) break
        sgn = -sgn
    }

    pv = 2 * pv
    if (pv < 0) pv = 0
    if (pv > 1) pv = 1

    return(pv)
}

// ------------------------------------------------------------------
// Run every diagnostic on every quantile's residual series.
// Result rows are ordered (tau, test) with tests
//   1 Ljung-Box  2 BG LM  3 Breusch-Pagan  4 ARCH LM
//   5 Jarque-Bera 6 RESET 7 CUSUM  8 CUSUMSQ
// ------------------------------------------------------------------
void _qardl_diag_run(real colvector yy, real matrix xx, real scalar ppp,
    real scalar qqq, string scalar bt_name, real scalar max_lags)
{
    real scalar nobs, ss, jj, lags, row, denom, c_stat, sq_stat
    real colvector Y, e, f, u, c_path, sq_path
    real matrix ONEX, bt, resid, fitted, res, cusum, cusumsq
    real rowvector out

    ONEX = _qardl_ic_design(yy, xx, ppp, qqq, Y)
    bt = st_matrix(bt_name)

    fitted = ONEX * bt
    resid  = Y * J(1, cols(bt), 1) - fitted

    nobs = rows(resid)
    ss   = cols(resid)

    lags = max_lags
    if (lags == 0) {
        lags = trunc(sqrt(nobs))
        if (lags < 1) lags = 1
        if (lags > 12) lags = 12
        if (lags > nobs - 1) lags = nobs - 1
    }

    res     = J(ss * 8, 5, .)
    cusum   = J(nobs, ss, .)
    cusumsq = J(nobs, ss, .)

    for (jj = 1; jj <= ss; jj++) {
        e = resid[., jj]
        f = fitted[., jj]

        row = (jj - 1) * 8

        out = _qardl_dg_ljungbox(e, lags);      res[row+1, .] = (jj, 1, out)
        out = _qardl_dg_bglm(e, f, lags);       res[row+2, .] = (jj, 2, out)
        out = _qardl_dg_bp(e, f);               res[row+3, .] = (jj, 3, out)
        out = _qardl_dg_archlm(e, lags);        res[row+4, .] = (jj, 4, out)
        out = _qardl_dg_jb(e);                  res[row+5, .] = (jj, 5, out)
        out = _qardl_dg_reset(e, f);            res[row+6, .] = (jj, 6, out)

        // CUSUM and CUSUMSQ stability paths
        u = e :- mean(e)
        denom = u' * u
        if (denom > 1e-14) {
            c_path  = runningsum(u) / sqrt(denom)
            c_stat  = max(abs(c_path))
            sq_path = runningsum(u :* u) / denom - (1::nobs) / nobs
            sq_stat = sqrt(nobs) * max(abs(sq_path))

            res[row+7, .] = (jj, 7, c_stat,  ., _qardl_dg_kspv(c_stat))
            res[row+8, .] = (jj, 8, sq_stat, ., _qardl_dg_kspv(sq_stat))

            cusum[., jj]   = c_path
            cusumsq[., jj] = sq_path
        }
        else {
            res[row+7, .] = (jj, 7, ., ., .)
            res[row+8, .] = (jj, 8, ., ., .)
        }
    }

    st_matrix("_qardl_dg_results", res)
    st_matrix("_qardl_dg_cusum", cusum)
    st_matrix("_qardl_dg_cusumsq", cusumsq)
    st_numscalar("_qardl_dg_nobs", nobs)
    st_numscalar("_qardl_dg_lags", lags)
}

end
