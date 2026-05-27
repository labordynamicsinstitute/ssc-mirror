*! xqcoint v1.0.0 — Xiao (2009) FM Quantile Cointegration + Kuriyama (2016) CUSUM
*! Stata implementation of:
*!   Xiao, Z. (2009). Quantile cointegrating regression. J. Econometrics, 150, 248-260.
*!   Kuriyama, N. (2016). Testing cointegration in quantile regressions.
*!                       Stud. Nonlinear Dyn. Econom. 20(2), 107-121.
*! Critical values for CUSUM from Hao & Inder (1996) Table 1.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop xqcoint
program define xqcoint, eclass sortpreserve
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], ///
        TAU(numlist >0 <1 sort) ///
        [BANDwidth(real -1) ///
         KERNel(string) ///
         LEADS(integer 0) ///
         LAGS(integer 0) ///
         WALDtest(string) ///
         GRAPH ///
         NOCUSUM ///
         NOTABle ///
         LEVel(cilevel) ///
         SAVEbeta(name) ///
         SAVEcs(name)]

    marksample touse
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 30 {
        di as err "xqcoint requires at least 30 observations (got `nobs')"
        exit 2001
    }

    // Time-series setup check
    qui tsset
    local timevar "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as err "xqcoint is for time-series data only (no panels)"
        exit 198
    }

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    local ntau : word count `tau'

    // Kernel default
    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'", "bartlett", "parzen", "qs") {
        di as err "kernel() must be bartlett, parzen, or qs"
        exit 198
    }

    // Bandwidth: default is plug-in M = 2*T^(1/3) (Andrews 1991 / Kuriyama 2016)
    if `bandwidth' <= 0 {
        local bw = ceil(2 * `nobs'^(1/3))
    }
    else {
        local bw = `bandwidth'
    }

    // Validate leads/lags
    if `leads' < 0 | `lags' < 0 {
        di as err "leads() and lags() must be nonnegative"
        exit 198
    }
    if (`leads' + `lags') >= `nobs' / 4 {
        di as err "leads() + lags() too large for sample size"
        exit 198
    }
    local augmented = (`leads' > 0 | `lags' > 0)

    // ====================================================================
    // HEADER
    // ====================================================================
    di as txt _n "{hline 78}"
    if `augmented' {
        di as res _col(5) "Quantile Cointegration: Augmented FM-QR (Xiao 2009 eq.11)"
    }
    else {
        di as res _col(5) "Quantile Cointegration: FMQR (Xiao 2009) + Kuriyama (2016) CUSUM"
    }
    di as txt "{hline 78}"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "Indep. vars       : " as res "`indepvars'"
    di as txt _col(3) "Number of x-vars  : " as res `k'
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt _col(3) "Quantiles (#=" as res `ntau' as txt "): " as res "`tau'"
    di as txt _col(3) "Kernel            : " as res "`kernel'"
    di as txt _col(3) "Bandwidth         : " as res `bw' as txt "  (default 2T^(1/3))"
    if `augmented' {
        di as txt _col(3) "Augmentation      : " as res "leads=`leads', lags=`lags'" ///
           as txt "  (Saikkonen-style, Xiao 2009 eq.11)"
    }
    if "`waldtest'" != "" {
        di as txt _col(3) "Wald test         : " as res "`waldtest'"
    }
    di as txt "{hline 78}"

    // ====================================================================
    // Pull data into Mata via st_data (more robust than putmata)
    // ====================================================================
    preserve
    qui keep if `touse'

    // Pass names as locals; mata function reads via st_data
    c_local _xq_yname  "`depvar'"
    c_local _xq_xnames "`indepvars'"

    mata: _xqcoint_main("`depvar'", "`indepvars'", `leads', `lags')

    // Pull results back
    tempname beta_set t_set cs_set rej05 rej01 alpha_set wald_set wald_pval
    mat `beta_set'  = r(beta_set)
    mat `t_set'     = r(t_set)
    mat `cs_set'    = r(cs_set)
    mat `rej05'     = r(rej05)
    mat `rej01'     = r(rej01)
    mat `alpha_set' = r(alpha_set)
    mat `wald_set'  = r(wald_set)
    mat `wald_pval' = r(wald_pval)

    // Critical values used (k regressors). For k=1: 5%=1.1684, 1%=1.4255 (Hao-Inder 1996 Tab 1).
    local cv5 = r(cv5)
    local cv1 = r(cv1)

    restore

    // ====================================================================
    // RESULTS TABLE — FM coefficients
    // ====================================================================
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 1: Fully-Modified Quantile Coefficient Estimates (Xiao 2009)"
        di as txt "{hline 78}"
        di as txt _col(3) "{c |} {ralign 6:tau}" _c
        di as txt " {c |} {ralign 12:intercept}" _c
        forvalues j = 1/`k' {
            local xname : word `j' of `indepvars'
            local xshort = substr("`xname'", 1, 11)
            di as txt " {c |} {ralign 12:`xshort'}" _c
        }
        di as txt " {c |}"
        di as txt "  {hline 74}"

        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            di as txt _col(3) "{c |} " as res %5.2f `tv' "  " _c
            di as txt "{c |}" as res %12.4f `alpha_set'[`r', 1] " " _c
            forvalues j = 1/`k' {
                di as txt "{c |}" as res %12.4f `beta_set'[`r', `j'] " " _c
            }
            di as txt "{c |}"
            // t-statistics below in parens
            di as txt _col(3) "{c |} " as txt "       " _c
            di as txt "{c |}" as txt %12s " " _c
            forvalues j = 1/`k' {
                di as txt "{c |}" as txt "(" %8.3f `t_set'[`r', `j'] ")  " _c
            }
            di as txt "{c |}"
        }
        di as txt "  {hline 74}"
        di as txt _col(3) "{it:t-statistics in parentheses (H0: beta = 0)}"
    }

    // ====================================================================
    // CUSUM TEST TABLE
    // ====================================================================
    if "`nocusum'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 2: CUSUM Test for Null of Quantile Cointegration (Kuriyama 2016)"
        di as txt _col(5) "H0: cointegration at quantile tau  |  H1: no cointegration"
        di as txt _col(5) "Critical values: Hao-Inder (1996) Table 1, k=" as res "`k'" as txt " regressors"
        di as txt "{hline 78}"
        di as txt _col(3) "    tau    CS(tau)    5% cv    1% cv    Decision"
        di as txt "  {hline 60}"
        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            local cs = `cs_set'[`r', 1]
            local r05 = `rej05'[`r', 1]
            local r01 = `rej01'[`r', 1]
            if `r01' == 1 local dec "Reject H0 at 1% (no cointegration)"
            else if `r05' == 1 local dec "Reject H0 at 5% (no cointegration)"
            else local dec "Fail to reject (cointegrated)"

            di as txt _col(3) %7.2f `tv' "  " ///
               as res %8.4f `cs' "  " ///
               as txt %7.4f `cv5' "  " ///
               as txt %7.4f `cv1' "  " _c
            if `r01' == 1 di as err " `dec'"
            else if `r05' == 1 di as err " `dec'"
            else di as txt " `dec'"
        }
        di as txt "  {hline 60}"
    }

    // ====================================================================
    // WALD TEST TABLE (Xiao 2009, Theorem 3)
    // ====================================================================
    if "`waldtest'" != "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 3: Linear Restriction Wald Test (Xiao 2009, Theorem 3)"
        di as txt _col(5) "H0: beta(tau) = (`waldtest')   (joint test on all slopes)"
        di as txt _col(5) "Test statistic  W ~ chi2(`k')  under H0"
        di as txt "{hline 78}"
        local cv5_w = invchi2(`k', 0.95)
        local cv1_w = invchi2(`k', 0.99)
        di as txt "       tau      W-stat       p-value     5% cv     1% cv    Decision"
        di as txt "  {hline 72}"
        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            local wv = `wald_set'[`r', 1]
            local pv = `wald_pval'[`r', 1]
            local dec "Fail to reject"
            if `wv' > `cv1_w' local dec "Reject H0 at 1%"
            else if `wv' > `cv5_w' local dec "Reject H0 at 5%"

            di as txt "  " %7.2f `tv' "  " _c
            di as res %12.4f `wv' "  " ///
               as res %10.4f `pv' "  " ///
               as txt %8.4f `cv5_w' "  " ///
               as txt %8.4f `cv1_w' "  " _c
            if `wv' > `cv5_w' di as err "`dec'"
            else di as txt "`dec'"
        }
        di as txt "  {hline 72}"
    }

    // ====================================================================
    // OPTIONAL: save matrices
    // ====================================================================
    if "`savebeta'" != "" {
        mat `savebeta' = `beta_set'
        local snames ""
        foreach v of local indepvars {
            local snames "`snames' `v'"
        }
        mat colnames `savebeta' = `snames'
        local rnames ""
        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            local rnames "`rnames' tau`=round(`tv'*100)'"
        }
        mat rownames `savebeta' = `rnames'
    }
    if "`savecs'" != "" {
        mat `savecs' = `cs_set'
    }

    // ====================================================================
    // GRAPH
    // ====================================================================
    if "`graph'" != "" {
        _xqcoint_graph, tau(`tau') beta(`beta_set') cs(`cs_set') ///
            cv5(`cv5') cv1(`cv1') depvar("`depvar'") indepvars("`indepvars'")
    }

    // ====================================================================
    // RETURN
    // ====================================================================
    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix beta_set  = `beta_set'
    ereturn matrix t_set     = `t_set'
    ereturn matrix alpha_set = `alpha_set'
    ereturn matrix cs_set    = `cs_set'
    ereturn matrix rej05     = `rej05'
    ereturn matrix rej01     = `rej01'
    ereturn matrix wald_set  = `wald_set'
    ereturn matrix wald_pval = `wald_pval'
    ereturn scalar bandwidth = `bw'
    ereturn scalar leads     = `leads'
    ereturn scalar lags      = `lags'
    ereturn scalar k         = `k'
    ereturn scalar ntau      = `ntau'
    ereturn scalar cv5       = `cv5'
    ereturn scalar cv1       = `cv1'
    ereturn local cmd        "xqcoint"
    ereturn local method     "`= cond(`augmented', "Augmented FM-QR", "FMQR")'"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local kernel     "`kernel'"
    ereturn local tau        "`tau'"
    ereturn local title      "Xiao(2009) FMQR + Kuriyama(2016) CUSUM"
end


* ====================================================================
* GRAPH SUBROUTINE — coefficient and test-statistic plots across tau
* ====================================================================
capture program drop _xqcoint_graph
program define _xqcoint_graph
    syntax, TAU(numlist) BETA(name) CS(name) CV5(real) CV1(real) ///
        DEPVAR(string) INDEPVARS(string)

    preserve
    drop _all

    local ntau : word count `tau'
    local k = colsof(`beta')

    qui set obs `ntau'
    qui gen double tau = .
    forvalues r = 1/`ntau' {
        local tv : word `r' of `tau'
        qui replace tau = `tv' in `r'
    }
    forvalues j = 1/`k' {
        qui gen double beta`j' = .
        forvalues r = 1/`ntau' {
            qui replace beta`j' = `beta'[`r', `j'] in `r'
        }
    }
    qui gen double cs = .
    forvalues r = 1/`ntau' {
        qui replace cs = `cs'[`r', 1] in `r'
    }

    // Coefficient plot (each xvar in its own panel)
    local plotcmds ""
    local i = 0
    foreach v of local indepvars {
        local ++i
        local g`i' "beta`i'"
        local plotcmds "`plotcmds' (line beta`i' tau, lcolor("`=cond(`i'==1,"navy",cond(`i'==2,"cranberry",cond(`i'==3,"forest_green","dkorange")))'") lwidth(medthick)) (scatter beta`i' tau, mcolor(black) msize(small))"
    }

    twoway `plotcmds', ///
        title("FM Quantile Cointegration Coefficients", size(medium)) ///
        subtitle("Xiao (2009): y = `depvar' regressed on `indepvars'", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("{&beta}{sup:+}({&tau})") ///
        legend(order(1 "`indepvars'") size(small)) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(xq_beta, replace) nodraw

    // CUSUM test statistic plot
    twoway (line cs tau, lcolor(navy) lwidth(medthick)) ///
           (scatter cs tau, mcolor(black) msize(small)) ///
           , yline(`cv5', lcolor(orange) lpattern(dash)) ///
             yline(`cv1', lcolor(red) lpattern(dash)) ///
        title("Kuriyama (2016) CUSUM Test Statistic", size(medium)) ///
        subtitle("Dashed: 5% (orange) and 1% (red) Hao-Inder critical values", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("CS({&tau})") ///
        legend(off) ///
        graphregion(color(white)) plotregion(color(white)) ///
        name(xq_cs, replace) nodraw

    graph combine xq_beta xq_cs, ///
        title("xqcoint: Xiao(2009) FM + Kuriyama(2016) CUSUM", size(medium)) ///
        graphregion(color(white))

    restore
end


* ====================================================================
* MATA CORE
* ====================================================================
capture mata: mata drop _xqcoint_main()
capture mata: mata drop _xqcoint_qreg()
capture mata: mata drop _xqcoint_lp_fnm()
capture mata: mata drop _xqcoint_kernel()
capture mata: mata drop _xqcoint_hi_cv()

mata:
mata set matastrict off

// --------------------------------------------------------------------
// Kernel function selector
// --------------------------------------------------------------------
real matrix _xqcoint_kernel(real matrix x, string scalar ktype)
{
    real matrix k
    real scalar i, j, ax

    k = J(rows(x), cols(x), 0)
    for (i=1; i<=rows(x); i++) {
        for (j=1; j<=cols(x); j++) {
            ax = abs(x[i, j])
            if (ktype == "bartlett") {
                k[i, j] = (ax <= 1) * (1 - ax)
            }
            else if (ktype == "parzen") {
                if (ax <= 0.5)      k[i, j] = 1 - 6*ax^2 + 6*ax^3
                else if (ax <= 1)   k[i, j] = 2 * (1 - ax)^3
                else                k[i, j] = 0
            }
            else if (ktype == "qs") {
                if (ax < 1e-10) k[i, j] = 1
                else {
                    real scalar z
                    z = 6 * pi() * ax / 5
                    k[i, j] = (25 / (12 * pi()^2 * ax^2)) * (sin(z)/z - cos(z))
                }
            }
        }
    }
    return(k)
}

// --------------------------------------------------------------------
// Hao-Inder (1996) Table 1 critical values for CUSUM (k regressors, no trend)
//   k=1: 10%=1.0477  5%=1.1684  1%=1.4255
//   k=2: 10%=1.0980  5%=1.2238  1%=1.4884
//   k=3: 10%=1.1318  5%=1.2611  1%=1.5326
//   k=4: 10%=1.1581  5%=1.2895  1%=1.5664
//   k=5: 10%=1.1789  5%=1.3128  1%=1.5945
// (Hao K. & Inder B. 1996, Econ. Letters 50, 179-187)
// --------------------------------------------------------------------
real matrix _xqcoint_hi_cv(real scalar k)
{
    real matrix tab
    real scalar kk
    tab = (1, 1.0477, 1.1684, 1.4255 \
           2, 1.0980, 1.2238, 1.4884 \
           3, 1.1318, 1.2611, 1.5326 \
           4, 1.1581, 1.2895, 1.5664 \
           5, 1.1789, 1.3128, 1.5945)
    kk = min((k, 5))
    return(tab[kk, 2..4])  // returns (10%, 5%, 1%)
}

// --------------------------------------------------------------------
// Quantile regression via Frisch-Newton interior-point
// Ported from Koenker & Morillo / Eilers rq_fnm.m
// --------------------------------------------------------------------
real colvector _xqcoint_qreg(real matrix X, real colvector y, real scalar p)
{
    real scalar m, n
    real colvector u, a, b

    m = rows(X); n = cols(X)
    u = J(m, 1, 1)
    a = (1 - p) :* u
    b = X' * a
    return(-_xqcoint_lp_fnm(X', -y', b, u, a)')
}

real rowvector _xqcoint_lp_fnm(real matrix A, real rowvector c,
    real colvector b, real colvector u, real colvector x)
{
    real scalar beta, small, max_it, m, n, it, gap, mu, gg
    real colvector s, r, z, w, q, dx, ds, dz, dw, fx, fs, fw, fz
    real colvector xinv, sinv, xi, dxdz, dsdw
    real rowvector y, fp_, fd_, dy
    real scalar fp, fd

    beta = 0.9995
    small = 1e-5
    max_it = 50
    m = rows(A); n = cols(A)

    s = u - x
    y = (qrsolve(A', c'))'
    r = (c - y * A)'
    for (it=1; it<=n; it++) {
        if (r[it] == 0) r[it] = 0.001
    }
    z = r :* (r :> 0)
    w = z - r
    gap = (c * x - y * b + w' * u)[1, 1]

    it = 0
    while (gap > small & it < max_it) {
        it = it + 1
        q = 1 :/ (z :/ x + w :/ s)
        r = z - w
        real matrix Q, AQ
        Q = diag(sqrt(q))
        AQ = A * Q
        real colvector rhs
        rhs = Q * r
        dy = (qrsolve(AQ', rhs))'
        dx = q :* ((dy * A)' - r)
        ds = -dx
        dz = -z :* (1 :+ dx :/ x)
        dw = -w :* (1 :+ ds :/ s)

        fx = _xqcoint_bound(x, dx)
        fs = _xqcoint_bound(s, ds)
        fw = _xqcoint_bound(w, dw)
        fz = _xqcoint_bound(z, dz)

        fp = min((min(min((fx, fs))) * beta, 1))
        fd = min((min(min((fw, fz))) * beta, 1))

        if (min((fp, fd)) < 1) {
            mu = (z' * x + w' * s)[1, 1]
            gg = ((z + fd*dz)' * (x + fp*dx) + (w + fd*dw)' * (s + fp*ds))[1, 1]
            mu = mu * (gg / mu)^3 / (2 * n)

            dxdz = dx :* dz
            dsdw = ds :* dw
            xinv = 1 :/ x
            sinv = 1 :/ s
            xi = mu * (xinv - sinv)
            rhs = rhs + Q * (dxdz - dsdw - xi)
            dy = (qrsolve(AQ', rhs))'
            dx = q :* (A' * dy' + xi - r - dxdz + dsdw)
            ds = -dx
            dz = mu :* xinv - z - xinv :* z :* dx - dxdz
            dw = mu :* sinv - w - sinv :* w :* ds - dsdw

            fx = _xqcoint_bound(x, dx)
            fs = _xqcoint_bound(s, ds)
            fw = _xqcoint_bound(w, dw)
            fz = _xqcoint_bound(z, dz)
            fp = min((min(min((fx, fs))) * beta, 1))
            fd = min((min(min((fw, fz))) * beta, 1))
        }

        x = x + fp :* dx
        s = s + fp :* ds
        y = y + fd :* dy
        w = w + fd :* dw
        z = z + fd :* dz
        gap = (c * x - y * b + w' * u)[1, 1]
    }
    return(y)
}

real colvector _xqcoint_bound(real colvector x, real colvector dx)
{
    real colvector b
    real scalar i
    b = J(rows(x), 1, 1e20)
    for (i=1; i<=rows(x); i++) {
        if (dx[i] < 0) b[i] = -x[i] / dx[i]
    }
    return(b)
}

// --------------------------------------------------------------------
// MAIN — Xiao 2009 FM-QR + Kuriyama 2016 CUSUM
// --------------------------------------------------------------------
void _xqcoint_main(string scalar yname, string scalar xnames,
    real scalar leads, real scalar lags)
{
    real colvector y, tau, rho_v_col, ss_v_col
    real matrix X, xlag, v, vlag
    real scalar T, N, Lq, k_ix, n_ix, h_ix, M
    string scalar kerntype

    y = st_data(., yname)
    X = st_data(., xnames)

    T = rows(y)
    N = cols(X)
    tau = strtoreal(tokens(st_local("tau")))'
    Lq = rows(tau)
    kerntype = st_local("kernel")
    M = strtoreal(st_local("bw"))

    real scalar augmented, nstart, nend, neff
    augmented = (leads > 0 | lags > 0)
    if (augmented) {
        nstart = lags + 1
        nend   = T - leads
        neff   = nend - nstart + 1
    }
    else {
        nstart = 1
        nend   = T
        neff   = T
    }

    // --- Build xlag, v, vlag (mimic Kuriyama MATLAB code) ---
    xlag = (J(1, N, 0) \ X[1..T-1, .])
    v    = X - xlag
    vlag = (J(1, N, 0) \ v[1..T-1, .])

    // --- Build augmented-regressor block of Delta-x leads/lags ---
    // For each lag j in [-lags, leads], stack v[(nstart+j)..(nend+j), .] as a block.
    // Z_aug_extra is built from the FULL-length v before any trimming.
    real matrix Z_aug_extra
    real scalar j_lag
    if (augmented) {
        Z_aug_extra = J(neff, 0, 0)
        for (j_lag = -lags; j_lag <= leads; j_lag++) {
            Z_aug_extra = (Z_aug_extra, v[(nstart+j_lag)..(nend+j_lag), .])
        }
        // Trim y, X, v to effective sample and redefine T so the kernel-based
        // long-run covariance loop further down sees a clean 1..T_eff indexing.
        y = y[nstart..nend]
        X = X[nstart..nend, .]
        v = v[nstart..nend, .]
        T = neff
        // Recompute xlag, vlag on the trimmed sample for any later use
        xlag = (J(1, N, 0) \ X[1..T-1, .])
        vlag = (J(1, N, 0) \ v[1..T-1, .])
    }

    // --- AR(1) on v for each x: rho_v and s^2_v (for kernel BW reference) ---
    rho_v_col = J(N, 1, 0)
    ss_v_col  = J(N, 1, 0)
    real matrix Z1
    real colvector b1, res1
    for (n_ix=1; n_ix<=N; n_ix++) {
        Z1 = (J(T, 1, 1), vlag[., n_ix])
        b1 = invsym(Z1' * Z1) * (Z1' * v[., n_ix])
        rho_v_col[n_ix] = b1[2]
        res1 = v[., n_ix] - Z1 * b1
        ss_v_col[n_ix] = (res1' * res1) / (T - 1)
    }

    // --- Initial OLS for theta and u_hat (used in density estimation) ---
    real matrix Z2
    real colvector theta_ols, u_hat
    Z2 = (J(T, 1, 1), X)
    theta_ols = invsym(Z2' * Z2) * (Z2' * y)
    u_hat = y - Z2 * theta_ols

    // --- Storage ---
    real matrix beta_set_fm, t_set_fm, cs_set, alpha_set
    real matrix rej05, rej01, wald_set, wald_pval
    beta_set_fm = J(Lq, N, 0)
    t_set_fm    = J(Lq, N, 0)
    cs_set      = J(Lq, 1, 0)
    alpha_set   = J(Lq, 1, 0)
    rej05       = J(Lq, 1, 0)
    rej01       = J(Lq, 1, 0)
    wald_set    = J(Lq, 1, .)
    wald_pval   = J(Lq, 1, .)

    // Parse Wald restriction: H0: beta(tau) = r_vec (N-vector)
    string scalar wstr
    real colvector r_vec
    real scalar do_wald
    wstr = st_local("waldtest")
    do_wald = (wstr != "")
    if (do_wald) {
        r_vec = strtoreal(tokens(wstr))'
        if (rows(r_vec) != N) {
            printf("{err}waldtest() must have %g values (one per I(1) regressor)\n", N)
            do_wald = 0
        }
    }

    // Hao-Inder critical values
    real matrix cv_row
    cv_row = _xqcoint_hi_cv(N)
    real scalar cv5_v, cv1_v
    cv5_v = cv_row[1, 2]
    cv1_v = cv_row[1, 3]

    // Kernel weights
    real rowvector h_set, K_row, K_row_1
    h_set = (0..M)
    K_row = _xqcoint_kernel(h_set / M, kerntype)
    K_row_1 = K_row[1, 2..(M+1)]

    real scalar h, q
    real colvector theta_q, beta_q, u_tau, psi, psilag
    real colvector rho_1, res_psi
    real scalar rho_psi, ss_psi
    real scalar F_inv_tau, M_f, f_hat
    real matrix psi_th_1, v_th_1, v_th, psi_th, ZZ
    real scalar Delta_psipsi, Lambda_psipsi_prim, omega2_psi
    real matrix Delta_vpsi, Lambda_vpsi_prim, Omega_vpsi
    real matrix Delta_vv, Lambda_vv_prim, Omega_vv
    real rowvector Omega_psiv
    real matrix Delta_vpsi_plus
    real scalar omega2_psiv
    real colvector beta_fm
    real matrix xdemean, Mxx
    real colvector se_beta_fm
    real colvector y_plus, u_tau_plus, psi_plus
    real scalar cs_q

    // --- Main loop over quantiles ---
    for (k_ix=1; k_ix<=Lq; k_ix++) {
        q = tau[k_ix]

        // QR estimate at quantile q. If augmented, include leads/lags of Δx.
        // y, X, v have already been trimmed to the effective sample (T = neff).
        real matrix Zfull
        if (augmented) {
            Zfull = (J(T, 1, 1), X, Z_aug_extra)
        }
        else {
            Zfull = (J(T, 1, 1), X)
        }
        theta_q = _xqcoint_qreg(Zfull, y, q)
        alpha_set[k_ix, 1] = theta_q[1]
        beta_q = theta_q[2..(N+1)]
        // Residual: use ONLY the cointegrating part (1 + x), excluding Δx terms
        u_tau = y - (J(T, 1, 1), X) * (theta_q[1] \ beta_q)
        psi = q :- (u_tau :< 0)

        // Density estimate at F^{-1}(q) using Gaussian kernel + Silverman BW
        F_inv_tau = _xq_quantile(u_hat, q)
        M_f = 1.364 * ((2 * sqrt(pi()))^(-1/5)) * sqrt(variance(u_hat)) * (T^(-1/5))
        f_hat = sum(normalden((F_inv_tau :- u_hat) / M_f)) / (T * M_f)
        if (f_hat <= 0) f_hat = 1e-6

        // Long-run variance of psi using AR(1) and kernel
        psilag = (0 \ psi[1..T-1])
        ZZ = (J(T, 1, 1), psilag)
        rho_1 = invsym(ZZ' * ZZ) * (ZZ' * psi)
        rho_psi = rho_1[2]
        res_psi = psi - ZZ * rho_1
        ss_psi = (res_psi' * res_psi) / (T - 1)

        // Two-sided long-run covariance matrices
        psi_th_1 = J(T, M, 0)
        v_th_1   = J(T, M, 0)  // will reshape below
        // We need v_th_1 as a 3-D-like structure; use cell-by-N matrices
        // For multi-N: store as (T, M, N) — emulate with N matrices
        real matrix v_th_1_n
        // We'll build Omega_vv (N x N), Delta_vpsi (N x 1) etc directly
        for (h_ix=1; h_ix<=M; h_ix++) {
            psi_th_1[., h_ix] = (psi[(h_ix+1)..T] \ J(h_ix, 1, 0))
        }

        // psi cross-products
        psi_th = (psi, psi_th_1)  // T x (M+1)
        Delta_psipsi        = (K_row * (psi' * psi_th)')[1, 1] / T
        Lambda_psipsi_prim  = (K_row_1 * (psi' * psi_th_1)')[1, 1] / T
        omega2_psi          = Delta_psipsi + Lambda_psipsi_prim

        // For each (h, n) we need v cross-products. Build matrices on the fly.
        Delta_vpsi        = J(N, 1, 0)
        Lambda_vpsi_prim  = J(N, 1, 0)
        Delta_vv          = J(N, N, 0)
        Lambda_vv_prim    = J(N, N, 0)

        // Construct v_th for each n via shifting
        real matrix v_th_full_n, v_n_lag
        for (n_ix=1; n_ix<=N; n_ix++) {
            v_th_full_n = J(T, M+1, 0)
            v_th_full_n[., 1] = v[., n_ix]
            for (h_ix=1; h_ix<=M; h_ix++) {
                v_th_full_n[., h_ix+1] = (v[(h_ix+1)..T, n_ix] \ J(h_ix, 1, 0))
            }
            // Delta_vpsi[n] = sum_h K(h/M) * (v_n' * psi_th[h]) / T   ;  psi_th has h=0..M
            Delta_vpsi[n_ix, 1] = (K_row * (v[., n_ix]' * psi_th)')[1, 1] / T

            // Lambda_vpsi_prim[n] = sum_{h>=1} K(h/M) * (psi' * v_th_1_n[h]) / T
            // (note: this is psi at t, v_n at t+h, both T-vectors)
            real matrix v_th_1_only_n
            v_th_1_only_n = v_th_full_n[., 2..(M+1)]
            Lambda_vpsi_prim[n_ix, 1] = (K_row_1 * (psi' * v_th_1_only_n)')[1, 1] / T

            // Delta_vv[., n] = sum_{h=0..M} K(h/M) * (v[., m]' * v_th_full_n[., h+1]) / T  for each m
            real scalar m_ix
            for (m_ix=1; m_ix<=N; m_ix++) {
                Delta_vv[m_ix, n_ix] = (K_row * (v[., m_ix]' * v_th_full_n)')[1, 1] / T
                Lambda_vv_prim[m_ix, n_ix] = (K_row_1 * (v[., m_ix]' * v_th_1_only_n)')[1, 1] / T
            }
        }

        Omega_vpsi = Delta_vpsi + Lambda_vpsi_prim     // N x 1
        Omega_vv   = Delta_vv + Lambda_vv_prim         // N x N
        Omega_psiv = Omega_vpsi'                       // 1 x N

        Delta_vpsi_plus = Delta_vpsi - Delta_vv * invsym(Omega_vv) * Omega_vpsi
        omega2_psiv = omega2_psi - (Omega_psiv * invsym(Omega_vv) * Omega_vpsi)[1, 1]
        if (omega2_psiv <= 0) omega2_psiv = 1e-8

        // Demeaned X
        real rowvector xmean
        xmean = mean(X)
        xdemean = X :- xmean
        Mxx = xdemean' * xdemean

        // FM coefficient (Phillips-Hansen / Xiao 2009 eq 11)
        beta_fm = beta_q - invsym(Mxx * f_hat) * ///
            (xdemean' * v * invsym(Omega_vv) * Omega_vpsi + T * Delta_vpsi_plus)

        beta_set_fm[k_ix, .] = beta_fm'

        // SE for FM coefficient — Xiao (2009) Theorem 2:
        //   T(beta_fm - beta) ~ MN(0, (omega2_psiv / f_hat^2) * Mxx^{-1})
        real matrix Mxx_inv
        Mxx_inv = invsym(Mxx)
        se_beta_fm = sqrt(omega2_psiv :* diagonal(Mxx_inv)) :/ f_hat

        t_set_fm[k_ix, .] = (beta_fm :/ se_beta_fm)'

        // ---- CUSUM test (Kuriyama 2016 / Xiao-Phillips 2002) ----
        // FM residuals: y_plus = y - (Omega_psiv * Omega_vv^-1 * v')'
        //               u_plus = y_plus - [1 X]*theta_fm
        //               psi_plus = tau - I(u_plus < 0)
        real colvector theta_fm
        theta_fm = (alpha_set[k_ix, 1] \ beta_fm)
        y_plus = y - (Omega_psiv * invsym(Omega_vv) * v')'
        u_tau_plus = y_plus - (J(T, 1, 1), X) * theta_fm
        psi_plus = q :- (u_tau_plus :< 0)

        cs_q = max(abs(runningsum(psi_plus))) / sqrt(T * omega2_psiv)
        cs_set[k_ix, 1] = cs_q

        rej05[k_ix, 1] = (abs(cs_q) > cv5_v)
        rej01[k_ix, 1] = (abs(cs_q) > cv1_v)

        // ---- Linear Restriction Wald Test (Xiao 2009, Theorem 3) ----
        // H0: beta(tau) = r_vec  (joint N restrictions)
        // W = (beta_fm - r)' Var(beta_fm)^{-1} (beta_fm - r) ~ chi2(N)
        if (do_wald) {
            real matrix Var_beta_fm
            real colvector diff_b
            Var_beta_fm = (omega2_psiv / f_hat^2) * Mxx_inv
            diff_b = beta_fm - r_vec
            wald_set[k_ix, 1] = (diff_b' * invsym(Var_beta_fm) * diff_b)[1, 1]
            wald_pval[k_ix, 1] = chi2tail(N, wald_set[k_ix, 1])
        }
    }

    // ---- Push results back to Stata ----
    st_matrix("r(beta_set)", beta_set_fm)
    st_matrix("r(t_set)",    t_set_fm)
    st_matrix("r(alpha_set)", alpha_set)
    st_matrix("r(cs_set)",   cs_set)
    st_matrix("r(rej05)",    rej05)
    st_matrix("r(rej01)",    rej01)
    st_matrix("r(wald_set)", wald_set)
    st_matrix("r(wald_pval)", wald_pval)
    st_numscalar("r(cv5)",   cv5_v)
    st_numscalar("r(cv1)",   cv1_v)
}

// Empirical quantile of a column vector (linear interpolation)
real scalar _xq_quantile(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, lo, hi
    s = sort(x, 1)
    n = rows(s)
    h = (n - 1) * p + 1
    lo = floor(h)
    hi = lo + 1
    if (lo < 1) lo = 1
    if (hi > n) hi = n
    if (lo == hi) return(s[lo])
    return(s[lo] + (h - lo) * (s[hi] - s[lo]))
}

end
