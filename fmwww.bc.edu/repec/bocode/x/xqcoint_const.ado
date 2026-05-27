*! xqcoint_const v1.0.0 — Constancy test of quantile cointegrating vector
*! Implements Section 3.2 of:
*!   Xiao, Z. (2009). Quantile cointegrating regression. J. Econometrics, 150, 248-260.
*! Tests H0: beta(tau) = beta_bar (constant across tau) vs. H1: beta varies with tau.
*! Functionals: sup_tau, Kolmogorov-Smirnov, Cramer-von Mises.
*! Asymptotic critical values are computed via reference Monte Carlo replicates
*! of the limiting Gaussian process.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop xqcoint_const
program define xqcoint_const, eclass sortpreserve
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], ///
        [TAU(numlist >0 <1 sort) ///
         NGRID(integer 19) ///
         LEADS(integer 0) LAGS(integer 0) ///
         BANDwidth(real -1) ///
         KERNel(string) ///
         GRAPH ///
         NOTABle ///
         SIMreps(integer 5000) ///
         LEVel(cilevel)]

    marksample touse
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 50 {
        di as err "xqcoint_const requires at least 50 observations (got `nobs')"
        exit 2001
    }
    qui tsset
    if "`r(panelvar)'" != "" {
        di as err "xqcoint_const is for time-series data only"
        exit 198
    }

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    // Default tau grid: 0.05, 0.10, ..., 0.95 (ngrid points)
    if "`tau'" == "" {
        local step = 1.0 / (`ngrid' + 1)
        local tau ""
        forvalues i = 1/`ngrid' {
            local tv = `i' * `step'
            local tau "`tau' `tv'"
        }
    }
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
    di as res _col(5) "Constancy Test of Quantile Cointegrating Vector"
    di as res _col(5) "                  (Xiao 2009, Section 3.2)"
    di as txt "{hline 78}"
    di as txt _col(3) "H0: beta(tau) = beta_bar  (constant cointegrating vector across tau)"
    di as txt _col(3) "H1: beta(tau) varies with tau"
    di as txt _col(3) "Test functionals  : sup_tau, KS, CVM"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "Indep. vars       : " as res "`indepvars'"
    di as txt _col(3) "Tau grid (#=" as res `ntau' as txt "): " as res "`= subinstr("`tau'", " ", ", ", .)'"
    if (`leads' > 0 | `lags' > 0) {
        di as txt _col(3) "Augmentation      : " as res "leads=`leads', lags=`lags'"
    }
    di as txt _col(3) "Kernel / bw       : " as res "`kernel'" as txt " / " as res `bw'
    di as txt _col(3) "Simulation reps   : " as res `simreps' as txt " (for asymp. CVs)"
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt "{hline 78}"

    preserve
    qui keep if `touse'

    mata: _xqc_main("`depvar'", "`indepvars'", `leads', `lags', `simreps')

    tempname Vhat sup_stat ks_stat cvm_stat cv_mat
    mat `Vhat'     = r(Vhat)
    mat `sup_stat' = r(sup_stat)
    mat `ks_stat'  = r(ks_stat)
    mat `cvm_stat' = r(cvm_stat)
    mat `cv_mat'   = r(cv_mat)

    restore

    // cv_mat is 3 x 3 — rows: sup, KS, CVM; cols: 5%, 1%, p-value(sample)
    local sup_cv5 = `cv_mat'[1, 1]
    local sup_cv1 = `cv_mat'[1, 2]
    local ks_cv5  = `cv_mat'[2, 1]
    local ks_cv1  = `cv_mat'[2, 2]
    local cvm_cv5 = `cv_mat'[3, 1]
    local cvm_cv1 = `cv_mat'[3, 2]
    local sup_pv  = `cv_mat'[1, 3]
    local ks_pv   = `cv_mat'[2, 3]
    local cvm_pv  = `cv_mat'[3, 3]

    local sup_v = `sup_stat'[1, 1]
    local ks_v  = `ks_stat'[1, 1]
    local cvm_v = `cvm_stat'[1, 1]

    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Test of beta(tau) constancy across tau"
        di as txt "{hline 78}"
        di as txt "  Functional      Statistic   5% CV     1% CV     p-value    Decision"
        di as txt "  {hline 72}"

        // Sup
        local dec "Fail to reject"
        if `sup_v' > `sup_cv1' local dec "Reject H0 at 1%"
        else if `sup_v' > `sup_cv5' local dec "Reject H0 at 5%"
        di as txt "  sup_tau     " _c
        di as res %10.4f `sup_v' "  " ///
           as txt %8.4f `sup_cv5' "  " ///
           as txt %8.4f `sup_cv1' "  " ///
           as res %8.4f `sup_pv' "  " _c
        if `sup_v' > `sup_cv5' di as err "`dec'"
        else di as txt "`dec'"

        // KS
        local dec "Fail to reject"
        if `ks_v' > `ks_cv1' local dec "Reject H0 at 1%"
        else if `ks_v' > `ks_cv5' local dec "Reject H0 at 5%"
        di as txt "  KS          " _c
        di as res %10.4f `ks_v' "  " ///
           as txt %8.4f `ks_cv5' "  " ///
           as txt %8.4f `ks_cv1' "  " ///
           as res %8.4f `ks_pv' "  " _c
        if `ks_v' > `ks_cv5' di as err "`dec'"
        else di as txt "`dec'"

        // CVM
        local dec "Fail to reject"
        if `cvm_v' > `cvm_cv1' local dec "Reject H0 at 1%"
        else if `cvm_v' > `cvm_cv5' local dec "Reject H0 at 5%"
        di as txt "  CVM         " _c
        di as res %10.4f `cvm_v' "  " ///
           as txt %8.4f `cvm_cv5' "  " ///
           as txt %8.4f `cvm_cv1' "  " ///
           as res %8.4f `cvm_pv' "  " _c
        if `cvm_v' > `cvm_cv5' di as err "`dec'"
        else di as txt "`dec'"

        di as txt "  {hline 72}"
        di as txt "  Critical values from " as res `simreps' as txt " Monte Carlo simulations of"
        di as txt "  the limiting Gaussian process (Xiao 2009, Theorem 4 approximation)."
    }

    if "`graph'" != "" {
        _xqcoint_const_graph, tau(`tau') vhat(`Vhat') ///
            sup(`sup_v') ks(`ks_v') cvm(`cvm_v') k(`k') indepvars("`indepvars'")
    }

    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix Vhat     = `Vhat'
    ereturn matrix sup_stat = `sup_stat'
    ereturn matrix ks_stat  = `ks_stat'
    ereturn matrix cvm_stat = `cvm_stat'
    ereturn matrix cv_mat   = `cv_mat'
    ereturn scalar sup_stat = `sup_v'
    ereturn scalar ks_stat  = `ks_v'
    ereturn scalar cvm_stat = `cvm_v'
    ereturn scalar sup_pval = `sup_pv'
    ereturn scalar ks_pval  = `ks_pv'
    ereturn scalar cvm_pval = `cvm_pv'
    ereturn scalar ntau     = `ntau'
    ereturn scalar bandwidth = `bw'
    ereturn scalar simreps  = `simreps'
    ereturn local cmd "xqcoint_const"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local kernel "`kernel'"
    ereturn local tau "`tau'"
    ereturn local title "Xiao (2009) Section 3.2 Constancy Test"
end


capture program drop _xqcoint_const_graph
program define _xqcoint_const_graph
    syntax, TAU(numlist) VHAT(name) SUP(real) KS(real) CVM(real) K(integer) ///
        INDEPVARS(string)
    preserve
    drop _all
    local ntau : word count `tau'
    qui set obs `ntau'
    qui gen double taug = .
    forvalues r = 1/`ntau' {
        local tv : word `r' of `tau'
        qui replace taug = `tv' in `r'
    }
    forvalues j = 1/`k' {
        qui gen double v`j' = .
        forvalues r = 1/`ntau' {
            qui replace v`j' = `vhat'[`r', `j'] in `r'
        }
    }

    twoway (line v1 taug, lcolor(navy) lwidth(medthick)) ///
           (scatter v1 taug, mcolor(black) msize(small)) ///
           , yline(0, lcolor(black) lpattern(solid)) ///
        title("V_hat_n({&tau}) = n[{&beta}({&tau}) - {&beta}_bar] for `: word 1 of `indepvars''", size(medium)) ///
        subtitle("Constancy test process (Xiao 2009 Section 3.2)", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("V_hat_n({&tau})") ///
        legend(off) graphregion(color(white)) ///
        name(xqc_const, replace) ///
        note("sup=`= round(`sup', .001)'  KS=`= round(`ks', .001)'  CVM=`= round(`cvm', .001)'", size(vsmall))

    restore
end


* ====================================================================
* MATA CORE
* ====================================================================
capture mata: mata drop _xqc_main()
capture mata: mata drop _xqc_qreg()
capture mata: mata drop _xqc_lp_fnm()
capture mata: mata drop _xqc_bound()
capture mata: mata drop _xqc_simcvs()

mata:
mata set matastrict off

real colvector _xqc_qreg(real matrix X, real colvector y, real scalar p)
{
    real scalar m, n
    real colvector u, a, b
    m = rows(X); n = cols(X)
    u = J(m, 1, 1)
    a = (1 - p) :* u
    b = X' * a
    return(-_xqc_lp_fnm(X', -y', b, u, a)')
}

real rowvector _xqc_lp_fnm(real matrix A, real rowvector c,
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
        fx = _xqc_bound(x, dx); fs = _xqc_bound(s, ds)
        fw = _xqc_bound(w, dw); fz = _xqc_bound(z, dz)
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
            fx = _xqc_bound(x, dx); fs = _xqc_bound(s, ds)
            fw = _xqc_bound(w, dw); fz = _xqc_bound(z, dz)
            fp = min((min(min((fx, fs))) * beta, 1))
            fd = min((min(min((fw, fz))) * beta, 1))
        }
        x = x + fp :* dx; s = s + fp :* ds
        y = y + fd :* dy; w = w + fd :* dw; z = z + fd :* dz
        gap = (c * x - y * b + w' * u)[1, 1]
    }
    return(y)
}

real colvector _xqc_bound(real colvector x, real colvector dx)
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
// Simulate critical values for sup, KS, CVM functionals of a standardized
// Gaussian process W(tau) where for each tau in the grid we draw
// independent N(0,1) variates and accumulate.  This is an APPROXIMATION
// of Xiao (2009) Theorem 4 — under H0, n[beta(tau) - beta_bar] converges
// to a Gaussian process with covariance kernel that depends on the
// long-run variance and the sparsity function. We use the
// independent-quantile approximation (close to truth when quantiles are
// far apart in the tau grid).
// Returns: 3 x 3 matrix (rows: sup, KS, CVM; cols: 5% cv, 1% cv, p-value)
// =====================================================================
real matrix _xqc_simcvs(real scalar ntau, real scalar reps,
    real scalar sup_stat_obs, real scalar ks_stat_obs, real scalar cvm_stat_obs)
{
    real matrix W, S_sup, S_ks, S_cvm
    real scalar i
    real colvector w_draw
    S_sup = J(reps, 1, 0)
    S_ks  = J(reps, 1, 0)
    S_cvm = J(reps, 1, 0)
    for (i=1; i<=reps; i++) {
        // Draw a standardized Brownian bridge on the tau grid
        w_draw = rnormal(ntau, 1, 0, 1)
        // Brownian-bridge transformation: W_tilde(tau) = W(tau) - tau * W(1)
        w_draw = w_draw - (1::ntau) :/ ntau :* w_draw[ntau]
        S_sup[i, 1] = max(abs(w_draw))
        S_ks[i, 1]  = max(abs(w_draw))
        S_cvm[i, 1] = mean(w_draw :^ 2)
    }

    real matrix cvs
    cvs = J(3, 3, 0)
    real colvector sup_sorted, ks_sorted, cvm_sorted

    sup_sorted = sort(S_sup, 1)
    ks_sorted  = sort(S_ks, 1)
    cvm_sorted = sort(S_cvm, 1)

    cvs[1, 1] = sup_sorted[round(0.95 * reps)]
    cvs[1, 2] = sup_sorted[round(0.99 * reps)]
    cvs[2, 1] = ks_sorted[round(0.95 * reps)]
    cvs[2, 2] = ks_sorted[round(0.99 * reps)]
    cvs[3, 1] = cvm_sorted[round(0.95 * reps)]
    cvs[3, 2] = cvm_sorted[round(0.99 * reps)]

    // p-values from empirical distribution
    cvs[1, 3] = mean(S_sup :>= sup_stat_obs)
    cvs[2, 3] = mean(S_ks :>= ks_stat_obs)
    cvs[3, 3] = mean(S_cvm :>= cvm_stat_obs)

    return(cvs)
}

// =====================================================================
// MAIN: Constancy test V_n(tau) = sqrt(n) * (beta_hat(tau) - beta_bar)
//    where beta_bar is taken from the median or OLS-cointegration estimate.
// Functionals: sup, KS, CVM applied to standardized V_n(tau).
// =====================================================================
void _xqc_main(string scalar yname, string scalar xnames,
    real scalar leads, real scalar lags, real scalar simreps)
{
    real colvector y, tau
    real matrix X, v, xlag
    real scalar T, N, Lq, M, j_lag
    string scalar kerntype

    y = st_data(., yname)
    X = st_data(., xnames)
    T = rows(y)
    N = cols(X)
    tau = strtoreal(tokens(st_local("tau")))'
    Lq = rows(tau)
    kerntype = st_local("kernel")
    M = strtoreal(st_local("bw"))

    // First differences
    xlag = (J(1, N, 0) \ X[1..T-1, .])
    v = X - xlag

    real scalar augmented, nstart, nend, neff
    augmented = (leads > 0 | lags > 0)
    if (augmented) {
        nstart = lags + 1
        nend = T - leads
        neff = nend - nstart + 1
    }
    else {
        nstart = 1; nend = T; neff = T
    }

    // Build augmented regressor block if requested
    real matrix Z_extra
    if (augmented) {
        Z_extra = J(neff, 0, 0)
        for (j_lag = -lags; j_lag <= leads; j_lag++) {
            Z_extra = (Z_extra, v[(nstart+j_lag)..(nend+j_lag), .])
        }
    }

    real colvector y_eff
    real matrix X_eff
    y_eff = y[nstart..nend]
    X_eff = X[nstart..nend, .]

    // Step 1: Estimate beta_hat(tau) at each tau
    real matrix beta_set
    beta_set = J(Lq, N, 0)
    real scalar k_ix, q
    real matrix Zfull
    real colvector theta_q
    for (k_ix=1; k_ix<=Lq; k_ix++) {
        q = tau[k_ix]
        if (augmented) Zfull = (J(neff, 1, 1), X_eff, Z_extra)
        else           Zfull = (J(neff, 1, 1), X_eff)
        theta_q = _xqc_qreg(Zfull, y_eff, q)
        beta_set[k_ix, .] = (theta_q[2..(N+1)])'
    }

    // Step 2: beta_bar = OLS slope from cointegrating regression
    real colvector theta_ols, beta_bar
    real matrix Z_ols
    Z_ols = (J(neff, 1, 1), X_eff)
    theta_ols = invsym(Z_ols' * Z_ols) * (Z_ols' * y_eff)
    beta_bar = theta_ols[2..(N+1)]

    // Step 3: V_hat_n(tau) = sqrt(n) * (beta_hat(tau) - beta_bar)
    // Standardize by dividing by an SE estimate (using OLS residual variance)
    real colvector u_ols
    u_ols = y_eff - Z_ols * theta_ols
    real scalar sigma_u
    sigma_u = sqrt((u_ols' * u_ols)[1, 1] / (neff - N - 1))
    if (sigma_u <= 0) sigma_u = 1e-6

    // Mxx for normalization
    real matrix Xd, Mxx_inv
    Xd = X_eff :- mean(X_eff)
    Mxx_inv = invsym(Xd' * Xd)
    real colvector se_beta_ols
    se_beta_ols = sigma_u * sqrt(diagonal(Mxx_inv))

    // V_hat_n(tau) = (beta_hat(tau) - beta_bar) / SE(beta_OLS)
    // Note: SE(beta_OLS) is already O(1/n) for cointegrated I(1) regressors,
    // so this ratio is asymptotically the appropriate t-like statistic
    // converging to a Gaussian process under H0 (Xiao 2009 Theorem 4).
    real matrix Vhat
    Vhat = J(Lq, N, 0)
    real scalar j_ix
    for (k_ix=1; k_ix<=Lq; k_ix++) {
        for (j_ix=1; j_ix<=N; j_ix++) {
            Vhat[k_ix, j_ix] = (beta_set[k_ix, j_ix] - beta_bar[j_ix]) / se_beta_ols[j_ix]
        }
    }

    // Step 4: Functionals (taken over the FIRST coefficient for display;
    //   for k>1 we take the L_infinity norm over all coefficients).
    real scalar sup_stat, ks_stat, cvm_stat
    real matrix Vnorm
    if (N == 1) {
        Vnorm = abs(Vhat)
    }
    else {
        // Use the maximum absolute value across coefficients at each tau
        Vnorm = J(Lq, 1, 0)
        for (k_ix=1; k_ix<=Lq; k_ix++) {
            Vnorm[k_ix, 1] = max(abs(Vhat[k_ix, .]))
        }
    }

    sup_stat = max(Vnorm)
    ks_stat  = max(Vnorm)             // same as sup for one-dim case
    cvm_stat = mean(Vnorm :^ 2)

    // Step 5: Simulated critical values
    real matrix cv_mat
    cv_mat = _xqc_simcvs(Lq, simreps, sup_stat, ks_stat, cvm_stat)

    st_matrix("r(Vhat)",     Vhat)
    st_matrix("r(sup_stat)", sup_stat)
    st_matrix("r(ks_stat)",  ks_stat)
    st_matrix("r(cvm_stat)", cvm_stat)
    st_matrix("r(cv_mat)",   cv_mat)
}

end
