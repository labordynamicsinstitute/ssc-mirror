*! xqcoint_robust v1.0.0 — Robust cointegration test for quantile regressions
*! Implements Section 3.3 of:
*!   Xiao, Z. (2009). Quantile cointegrating regression. J. Econometrics, 150, 248-260.
*! Distinct from xqcoint's CUSUM (Kuriyama 2016) in that it uses augmented-QR
*! residuals (not FM residuals) and provides BOTH Kolmogorov-Smirnov (KS) and
*! Cramer-von Mises (CVM) functionals of the partial-sum process Y_n(r).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop xqcoint_robust
program define xqcoint_robust, eclass sortpreserve
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], ///
        TAU(numlist >0 <1 sort) ///
        [LEADS(integer 1) LAGS(integer 1) ///
         BANDwidth(real -1) ///
         KERNel(string) ///
         GRAPH ///
         NOTABle ///
         LEVel(cilevel) ///
         SAVEks(name) SAVEcvm(name)]

    marksample touse
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 50 {
        di as err "xqcoint_robust requires at least 50 observations (got `nobs')"
        exit 2001
    }
    qui tsset
    if "`r(panelvar)'" != "" {
        di as err "xqcoint_robust is for time-series data only"
        exit 198
    }

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    local ntau : word count `tau'

    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")

    if `bandwidth' <= 0 {
        local bw = ceil(2 * `nobs'^(1/3))
    }
    else {
        local bw = `bandwidth'
    }

    di as txt _n "{hline 78}"
    di as res _col(5) "Robust Quantile Cointegration Test (Xiao 2009, Section 3.3)"
    di as txt "{hline 78}"
    di as txt _col(3) "Method            : " as res "Augmented QR (leads=`leads', lags=`lags')"
    di as txt _col(3) "Test statistic    : " as res "Y_n(r) partial-sum process"
    di as txt _col(3) "Functionals       : " as res "KS  =  sup_r |Y_n(r)|"
    di as txt _col(35) as res "CVM =  int_0^1 Y_n(r)^2 dr"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "Indep. vars       : " as res "`indepvars'"
    di as txt _col(3) "Quantiles (#=" as res `ntau' as txt "): " as res "`tau'"
    di as txt _col(3) "Kernel / bw       : " as res "`kernel'" as txt " / " as res `bw'
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt "{hline 78}"

    preserve
    qui keep if `touse'

    mata: _xqr_main("`depvar'", "`indepvars'", `leads', `lags')

    tempname ks_set cvm_set
    mat `ks_set'  = r(ks_set)
    mat `cvm_set' = r(cvm_set)

    restore

    // ----------------------------------------------------------------
    // Reference critical values (Brownian bridge approximation):
    //   KS:  sup|B(r)|  →  Kolmogorov,  cv5 = 1.358,  cv1 = 1.628
    //   CVM: ∫B(r)^2 dr →  Cramer-von Mises, cv5 = 0.461, cv1 = 0.743
    // (These are asymptotic; Xiao 2009 notes Y_n(r) has a slightly different
    // limit involving demeaned/detrended Brownian motion, so we report the
    // BB-based CVs as a reference upper bound.)
    // ----------------------------------------------------------------
    local ks_cv5 = 1.358
    local ks_cv1 = 1.628
    local cvm_cv5 = 0.461
    local cvm_cv1 = 0.743

    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Robust Cointegration Test — Y_n(r) functionals"
        di as txt _col(5) "H0: cointegration at quantile tau   |   H1: no cointegration"
        di as txt _col(5) "Reference asymptotic Brownian-bridge CVs:"
        di as txt _col(5) "   KS:  5%=" as res "`ks_cv5'"  as txt "    1%=" as res "`ks_cv1'"
        di as txt _col(5) "   CVM: 5%=" as res "`cvm_cv5'" as txt "    1%=" as res "`cvm_cv1'"
        di as txt "{hline 78}"
        di as txt "      tau      KS-stat   KS-dec        CVM-stat  CVM-dec"
        di as txt "  {hline 70}"
        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            local ks_v = `ks_set'[`r', 1]
            local cvm_v = `cvm_set'[`r', 1]
            local ks_d "Fail to reject"
            local cvm_d "Fail to reject"
            if `ks_v' > `ks_cv1' local ks_d "Reject at 1%"
            else if `ks_v' > `ks_cv5' local ks_d "Reject at 5%"
            if `cvm_v' > `cvm_cv1' local cvm_d "Reject at 1%"
            else if `cvm_v' > `cvm_cv5' local cvm_d "Reject at 5%"

            di as txt "  " %7.2f `tv' "  " _c
            di as res %12.4f `ks_v' "   " _c
            if `ks_v' > `ks_cv5' di as err %-14s "`ks_d'" _c
            else di as txt %-14s "`ks_d'" _c
            di as res %12.4f `cvm_v' "   " _c
            if `cvm_v' > `cvm_cv5' di as err "`cvm_d'"
            else di as txt "`cvm_d'"
        }
        di as txt "  {hline 70}"
    }

    if "`graph'" != "" {
        _xqcoint_robust_graph, taulist(`tau') ksmat(`ks_set') cvmmat(`cvm_set') ///
            ksref(`ks_cv5') cvmref(`cvm_cv5')
    }

    if "`saveks'" != ""  mat `saveks'  = `ks_set'
    if "`savecvm'" != "" mat `savecvm' = `cvm_set'

    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix ks_set  = `ks_set'
    ereturn matrix cvm_set = `cvm_set'
    ereturn scalar leads = `leads'
    ereturn scalar lags  = `lags'
    ereturn scalar bandwidth = `bw'
    ereturn scalar ks_cv5  = `ks_cv5'
    ereturn scalar ks_cv1  = `ks_cv1'
    ereturn scalar cvm_cv5 = `cvm_cv5'
    ereturn scalar cvm_cv1 = `cvm_cv1'
    ereturn local cmd "xqcoint_robust"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local kernel "`kernel'"
    ereturn local tau "`tau'"
    ereturn local title "Xiao (2009) Section 3.3 Robust Cointegration Test"
end


capture program drop _xqcoint_robust_graph
program define _xqcoint_robust_graph
    syntax, TAULIST(numlist) KSMAT(name) CVMMAT(name) KSREF(real) CVMREF(real)
    preserve
    drop _all
    local ntau : word count `taulist'
    qui set obs `ntau'
    qui gen double taug = .
    qui gen double ksg = .
    qui gen double cvmg = .
    forvalues r = 1/`ntau' {
        local tv : word `r' of `taulist'
        qui replace taug = `tv' in `r'
        qui replace ksg = `ksmat'[`r', 1] in `r'
        qui replace cvmg = `cvmmat'[`r', 1] in `r'
    }

    twoway (line ksg taug, lcolor(navy) lwidth(medthick)) ///
           (scatter ksg taug, mcolor(black) msize(small)), ///
        yline(`ksref', lcolor(orange) lpattern(dash)) ///
        title("KS functional: sup_r |Y_n(r)|", size(medium)) ///
        subtitle("Dashed orange line = 5% Brownian-bridge critical value", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("KS({&tau})") ///
        legend(off) graphregion(color(white)) ///
        name(xqr_ks, replace) nodraw

    twoway (line cvmg taug, lcolor(cranberry) lwidth(medthick)) ///
           (scatter cvmg taug, mcolor(black) msize(small)), ///
        yline(`cvmref', lcolor(orange) lpattern(dash)) ///
        title("CVM functional: integral Y_n(r)^2 dr", size(medium)) ///
        subtitle("Dashed orange line = 5% Cramer-von Mises critical value", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("CVM({&tau})") ///
        legend(off) graphregion(color(white)) ///
        name(xqr_cvm, replace) nodraw

    graph combine xqr_ks xqr_cvm, ///
        title("xqcoint_robust: Xiao (2009) Section 3.3", size(medium)) ///
        graphregion(color(white))

    restore
end


* ====================================================================
* MATA CORE
* ====================================================================
capture mata: mata drop _xqr_main()
capture mata: mata drop _xqr_qreg()
capture mata: mata drop _xqr_lp_fnm()
capture mata: mata drop _xqr_bound()
capture mata: mata drop _xqr_kernel()

mata:
mata set matastrict off

real matrix _xqr_kernel(real matrix x, string scalar ktype)
{
    real matrix k
    real scalar i, j, ax, z
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
                    z = 6 * pi() * ax / 5
                    k[i, j] = (25 / (12 * pi()^2 * ax^2)) * (sin(z)/z - cos(z))
                }
            }
        }
    }
    return(k)
}

real colvector _xqr_qreg(real matrix X, real colvector y, real scalar p)
{
    real scalar m, n
    real colvector u, a, b
    m = rows(X); n = cols(X)
    u = J(m, 1, 1)
    a = (1 - p) :* u
    b = X' * a
    return(-_xqr_lp_fnm(X', -y', b, u, a)')
}

real rowvector _xqr_lp_fnm(real matrix A, real rowvector c,
    real colvector b, real colvector u, real colvector x)
{
    real scalar beta, small, max_it, m, n, it, gap, mu, gg, fp, fd
    real colvector s, r, z, w, q, dx, ds, dz, dw, fx, fs, fw, fz
    real colvector xinv, sinv, xi, dxdz, dsdw, rhs
    real rowvector y, dy
    real matrix Q, AQ

    beta = 0.9995; small = 1e-5; max_it = 50
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
        Q = diag(sqrt(q))
        AQ = A * Q
        rhs = Q * r
        dy = (qrsolve(AQ', rhs))'
        dx = q :* ((dy * A)' - r)
        ds = -dx
        dz = -z :* (1 :+ dx :/ x)
        dw = -w :* (1 :+ ds :/ s)
        fx = _xqr_bound(x, dx); fs = _xqr_bound(s, ds)
        fw = _xqr_bound(w, dw); fz = _xqr_bound(z, dz)
        fp = min((min(min((fx, fs))) * beta, 1))
        fd = min((min(min((fw, fz))) * beta, 1))
        if (min((fp, fd)) < 1) {
            mu = (z' * x + w' * s)[1, 1]
            gg = ((z + fd*dz)' * (x + fp*dx) + (w + fd*dw)' * (s + fp*ds))[1, 1]
            mu = mu * (gg / mu)^3 / (2 * n)
            dxdz = dx :* dz; dsdw = ds :* dw
            xinv = 1 :/ x; sinv = 1 :/ s
            xi = mu * (xinv - sinv)
            rhs = rhs + Q * (dxdz - dsdw - xi)
            dy = (qrsolve(AQ', rhs))'
            dx = q :* (A' * dy' + xi - r - dxdz + dsdw)
            ds = -dx
            dz = mu :* xinv - z - xinv :* z :* dx - dxdz
            dw = mu :* sinv - w - sinv :* w :* ds - dsdw
            fx = _xqr_bound(x, dx); fs = _xqr_bound(s, ds)
            fw = _xqr_bound(w, dw); fz = _xqr_bound(z, dz)
            fp = min((min(min((fx, fs))) * beta, 1))
            fd = min((min(min((fw, fz))) * beta, 1))
        }
        x = x + fp :* dx; s = s + fp :* ds
        y = y + fd :* dy; w = w + fd :* dw; z = z + fd :* dz
        gap = (c * x - y * b + w' * u)[1, 1]
    }
    return(y)
}

real colvector _xqr_bound(real colvector x, real colvector dx)
{
    real colvector b
    real scalar i
    b = J(rows(x), 1, 1e20)
    for (i=1; i<=rows(x); i++) {
        if (dx[i] < 0) b[i] = -x[i] / dx[i]
    }
    return(b)
}

// =====================================================================
// MAIN: Robust cointegration test (Xiao 2009, Section 3.3)
// Y_n(r) = (1/(omega_psi * sqrt(n))) * sum_{j=1}^[nr] psi_tau(eps_jtau)
// KS  = sup_r |Y_n(r)|
// CVM = int_0^1 Y_n(r)^2 dr
// =====================================================================
void _xqr_main(string scalar yname, string scalar xnames,
    real scalar leads, real scalar lags)
{
    real colvector y_full, tau
    real matrix X_full
    real scalar T, N, Lq, M, j_lag
    string scalar kerntype

    y_full = st_data(., yname)
    X_full = st_data(., xnames)
    T = rows(y_full)
    N = cols(X_full)
    tau = strtoreal(tokens(st_local("tau")))'
    Lq = rows(tau)
    kerntype = st_local("kernel")
    M = strtoreal(st_local("bw"))

    // First-difference X
    real matrix xlag, v
    xlag = (J(1, N, 0) \ X_full[1..T-1, .])
    v = X_full - xlag

    real scalar nstart, nend, neff
    nstart = lags + 1
    nend   = T - leads
    neff   = nend - nstart + 1

    // Build augmented regressors block for Δx leads/lags
    real matrix Z_extra
    Z_extra = J(neff, 0, 0)
    for (j_lag = -lags; j_lag <= leads; j_lag++) {
        Z_extra = (Z_extra, v[(nstart+j_lag)..(nend+j_lag), .])
    }

    // Effective sample
    real colvector y_eff
    real matrix X_eff
    y_eff = y_full[nstart..nend]
    X_eff = X_full[nstart..nend, .]

    real matrix Z_aug
    Z_aug = (J(neff, 1, 1), X_eff, Z_extra)

    // Kernel weights for long-run variance of psi
    real rowvector h_set, K_row, K_row_1
    h_set = (0..M)
    K_row = _xqr_kernel(h_set / M, kerntype)
    K_row_1 = K_row[1, 2..(M+1)]

    real matrix ks_set, cvm_set
    ks_set  = J(Lq, 1, 0)
    cvm_set = J(Lq, 1, 0)

    real scalar k_ix, q, h_ix
    real colvector theta_q, eps_t, psi_t, Y_n
    real matrix psi_th_1, psi_th
    real scalar omega2_psi, omega_psi
    real scalar Delta_psipsi, Lambda_psipsi_prim

    for (k_ix=1; k_ix<=Lq; k_ix++) {
        q = tau[k_ix]

        // 1. Augmented quantile regression (Saikkonen leads/lags absorb endogeneity)
        theta_q = _xqr_qreg(Z_aug, y_eff, q)

        // 2. Residuals: subtract intercept + slope*x only (the cointegrating part)
        eps_t = y_eff - (J(neff, 1, 1), X_eff) * (theta_q[1] \ theta_q[2..(N+1)])

        // 3. psi_tau(eps_t)
        psi_t = q :- (eps_t :< 0)

        // 4. Long-run variance of psi via Bartlett kernel
        psi_th_1 = J(neff, M, 0)
        for (h_ix=1; h_ix<=M; h_ix++) {
            psi_th_1[., h_ix] = (psi_t[(h_ix+1)..neff] \ J(h_ix, 1, 0))
        }
        psi_th = (psi_t, psi_th_1)
        Delta_psipsi       = (K_row * (psi_t' * psi_th)')[1, 1] / neff
        Lambda_psipsi_prim = (K_row_1 * (psi_t' * psi_th_1)')[1, 1] / neff
        omega2_psi = Delta_psipsi + Lambda_psipsi_prim
        if (omega2_psi <= 0) omega2_psi = 1e-8
        omega_psi = sqrt(omega2_psi)

        // 5. Partial-sum process Y_n(r) = (1 / (omega_psi * sqrt(n))) * cumsum(psi)
        Y_n = runningsum(psi_t) :/ (omega_psi * sqrt(neff))

        // 6. KS and CVM functionals
        ks_set[k_ix, 1]  = max(abs(Y_n))
        cvm_set[k_ix, 1] = mean(Y_n :^ 2)
    }

    st_matrix("r(ks_set)",  ks_set)
    st_matrix("r(cvm_set)", cvm_set)
}

end
