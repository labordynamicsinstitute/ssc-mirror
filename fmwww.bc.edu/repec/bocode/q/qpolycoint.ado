*! qpolycoint v1.0.0 — Quantile Polynomial Cointegration (Li, Zheng & Guo 2016)
*! Implements:
*!   Li, H., Zheng, C., Guo, Y. (2016). Estimation and test for quantile nonlinear
*!     cointegrating regression. Economics Letters 148, 27-32.
*! Provides:
*!   - Fully-modified quantile polynomial cointegrating regression estimator
*!   - Wald-type linearity test  Q ~ chi2_{k(p-1)}
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop qpolycoint
program define qpolycoint, eclass sortpreserve
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], ///
        TAU(numlist >0 <1 sort) ///
        [Porder(integer 3) ///
         BANDwidth(real -1) ///
         KERNel(string) ///
         GRAPH ///
         NOTABle ///
         NOTEST ///
         LEVel(cilevel) ///
         SAVEcoef(name) ///
         SAVEtest(name)]

    marksample touse
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 40 {
        di as err "qpolycoint requires at least 40 observations (got `nobs')"
        exit 2001
    }
    qui tsset
    if "`r(panelvar)'" != "" {
        di as err "qpolycoint is for time-series data only"
        exit 198
    }

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    local ntau : word count `tau'
    local p = `porder'
    if `p' < 2 | `p' > 5 {
        di as err "porder() must be between 2 and 5 (Li 2016 recommend 2 or 3)"
        exit 198
    }

    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'", "bartlett", "parzen", "qs") {
        di as err "kernel() must be bartlett, parzen, or qs"
        exit 198
    }

    if `bandwidth' <= 0 {
        local bw = ceil(2 * `nobs'^(1/3))
    }
    else {
        local bw = `bandwidth'
    }

    // Restriction count: each quantile has k*(p-1) restrictions
    local nrestr = `k' * (`p' - 1)

    // ====================================================================
    // HEADER
    // ====================================================================
    di as txt _n "{hline 78}"
    di as res _col(5) "Quantile Polynomial Cointegration: Li, Zheng & Guo (2016)"
    di as txt "{hline 78}"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "Indep. vars       : " as res "`indepvars'"
    di as txt _col(3) "Polynomial order  : " as res `p' as txt "  (linear + powers 2..`p')"
    di as txt _col(3) "Quantiles (#=" as res `ntau' as txt "): " as res "`tau'"
    di as txt _col(3) "Kernel / bandwidth: " as res "`kernel'" as txt " / " as res `bw'
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt "{hline 78}"

    // ====================================================================
    // Run Mata core (faithful to Li 2016 Theorem 1-4)
    // ====================================================================
    preserve
    qui keep if `touse'

    mata: _qpolycoint_main("`depvar'", "`indepvars'", `p')

    // Pull results back
    tempname coef_set tQ_set pval_set fm_se
    mat `coef_set' = r(coef_set)
    mat `tQ_set'   = r(tQ_set)
    mat `pval_set' = r(pval_set)
    mat `fm_se'    = r(fm_se)

    local cv5_q = invchi2(`nrestr', 0.95)
    local cv1_q = invchi2(`nrestr', 0.99)

    restore

    // ====================================================================
    // RESULTS TABLE — coefficient panel
    // ====================================================================
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 1: FM Quantile Polynomial Coefficients (Li et al. 2016)"
        di as txt "{hline 78}"

        // Header line
        local hdr = "   tau   |    const  "
        forvalues pp = 1/`p' {
            forvalues j = 1/`k' {
                local xname : word `j' of `indepvars'
                local xs = substr("`xname'", 1, 7)
                if `pp' == 1 local hdr "`hdr'   `xs'    "
                else         local hdr "`hdr'  `xs'^`pp'   "
            }
        }
        di as txt "  `hdr'"
        di as txt "  {hline 72}"

        local ncols = 1 + `k' * `p'
        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            di as txt "  " %5.2f `tv' "   |" _c
            forvalues c = 1/`ncols' {
                di as res %10.4f `coef_set'[`r', `c'] _c
            }
            di ""
        }
        di as txt "  {hline 72}"
    }

    // ====================================================================
    // LINEARITY WALD TEST TABLE
    // ====================================================================
    if "`notest'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 2: Wald-type Linearity Test  (Li et al. 2016, Theorem 3-4)"
        di as txt _col(5) "H0: gamma_2(tau) = ... = gamma_`p'(tau) = 0    (linear cointegration)"
        di as txt _col(5) "H1: at least one polynomial coefficient is non-zero"
        di as txt _col(5) "Test statistic  Q ~ chi2(`nrestr')  under H0"
        di as txt "{hline 78}"
        di as txt "        tau        Q-stat     df      p-value     5% cv     1% cv    Decision"
        di as txt "  {hline 75}"

        forvalues r = 1/`ntau' {
            local tv : word `r' of `tau'
            local qstat = `tQ_set'[`r', 1]
            local pval = `pval_set'[`r', 1]

            if `qstat' > `cv1_q'      local dec "Reject H0 at 1%"
            else if `qstat' > `cv5_q' local dec "Reject H0 at 5%"
            else                       local dec "Fail to reject"

            di as txt "  " %7.2f `tv' "  " _c
            di as res %12.4f `qstat' "  " ///
               as txt %3.0f `nrestr' "  " ///
               as res %10.4f `pval' "  " ///
               as txt %8.4f `cv5_q' "  " ///
               as txt %8.4f `cv1_q' "  " _c
            if `qstat' > `cv5_q' di as err "`dec'"
            else di as txt "`dec'"
        }
        di as txt "  {hline 75}"
    }

    // ====================================================================
    // GRAPH
    // ====================================================================
    if "`graph'" != "" {
        _qpolycoint_graph, taulist(`tau') coef(`coef_set') wstat(`tQ_set') ///
            cv5(`cv5_q') cv1(`cv1_q') porder(`p') k(`k') ///
            depvar("`depvar'") indepvars("`indepvars'")
    }

    if "`savecoef'" != "" mat `savecoef' = `coef_set'
    if "`savetest'" != "" mat `savetest' = `tQ_set'

    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix coef_set = `coef_set'
    ereturn matrix tQ_set   = `tQ_set'
    ereturn matrix pval_set = `pval_set'
    ereturn matrix fm_se    = `fm_se'
    ereturn scalar porder    = `p'
    ereturn scalar k         = `k'
    ereturn scalar ntau      = `ntau'
    ereturn scalar nrestr    = `nrestr'
    ereturn scalar bandwidth = `bw'
    ereturn scalar cv5_q     = `cv5_q'
    ereturn scalar cv1_q     = `cv1_q'
    ereturn local cmd        "qpolycoint"
    ereturn local depvar     "`depvar'"
    ereturn local indepvars  "`indepvars'"
    ereturn local kernel     "`kernel'"
    ereturn local tau        "`tau'"
    ereturn local title      "Li, Zheng & Guo (2016) Polynomial QCointegration"
end


* ====================================================================
* GRAPH SUBROUTINE
* ====================================================================
capture program drop _qpolycoint_graph
program define _qpolycoint_graph
    syntax, TAULIST(numlist) COEF(name) WSTAT(name) CV5(real) CV1(real) ///
        PORDER(integer) K(integer) DEPVAR(string) INDEPVARS(string)

    preserve
    drop _all
    local ntau : word count `taulist'
    qui set obs `ntau'
    qui gen double tau = .
    forvalues r = 1/`ntau' {
        local tv : word `r' of `taulist'
        qui replace tau = `tv' in `r'
    }

    // Linear coefficient on first x (column 2 in coef_set)
    qui gen double beta1 = .
    forvalues r = 1/`ntau' {
        qui replace beta1 = `coef'[`r', 2] in `r'
    }
    qui gen double qstat = .
    forvalues r = 1/`ntau' {
        qui replace qstat = `wstat'[`r', 1] in `r'
    }

    twoway (line beta1 tau, lcolor(navy) lwidth(medthick)) ///
           (scatter beta1 tau, mcolor(black) msize(small)), ///
        title("Linear coefficient {&beta}({&tau}) on `:word 1 of `indepvars''", size(medium)) ///
        xtitle("Quantile {&tau}") ytitle("{&beta}{sup:+}({&tau})") ///
        legend(off) graphregion(color(white)) plotregion(color(white)) ///
        name(qpc_b, replace) nodraw

    local df = `k' * (`porder' - 1)
    twoway (line qstat tau, lcolor(navy) lwidth(medthick)) ///
           (scatter qstat tau, mcolor(black) msize(small)), ///
        yline(`cv5', lcolor(orange) lpattern(dash)) ///
        yline(`cv1', lcolor(red) lpattern(dash)) ///
        title("Linearity test Q({&tau})", size(medium)) ///
        subtitle("Dashed: 5% (orange) and 1% (red) {&chi}{sup:2}(`df') critical values", size(small)) ///
        xtitle("Quantile {&tau}") ytitle("Q({&tau})") ///
        legend(off) graphregion(color(white)) plotregion(color(white)) ///
        name(qpc_q, replace) nodraw

    graph combine qpc_b qpc_q, ///
        title("qpolycoint: Li, Zheng & Guo (2016)", size(medium)) ///
        graphregion(color(white))

    restore
end


* ====================================================================
* MATA CORE
* ====================================================================
capture mata: mata drop _qpolycoint_main()
capture mata: mata drop _qpc_qreg()
capture mata: mata drop _qpc_lp_fnm()
capture mata: mata drop _qpc_bound()
capture mata: mata drop _qpc_kernel()
capture mata: mata drop _qpc_quantile()

mata:
mata set matastrict off

real matrix _qpc_kernel(real matrix x, string scalar ktype)
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

real scalar _qpc_quantile(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, h, lo, hi
    s = sort(x, 1); n = rows(s)
    h = (n - 1) * p + 1
    lo = floor(h); hi = lo + 1
    if (lo < 1) lo = 1
    if (hi > n) hi = n
    if (lo == hi) return(s[lo])
    return(s[lo] + (h - lo) * (s[hi] - s[lo]))
}

real colvector _qpc_qreg(real matrix X, real colvector y, real scalar p)
{
    real scalar m, n
    real colvector u, a, b
    m = rows(X); n = cols(X)
    u = J(m, 1, 1)
    a = (1 - p) :* u
    b = X' * a
    return(-_qpc_lp_fnm(X', -y', b, u, a)')
}

real rowvector _qpc_lp_fnm(real matrix A, real rowvector c,
    real colvector b, real colvector u, real colvector x)
{
    real scalar beta, small, max_it, m, n, it, gap, mu, gg, fp, fd
    real colvector s, r, z, w, q, dx, ds, dz, dw, fx, fs, fw, fz
    real colvector xinv, sinv, xi, dxdz, dsdw, rhs
    real rowvector y, dy
    real matrix Q, AQ

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
        Q = diag(sqrt(q))
        AQ = A * Q
        rhs = Q * r
        dy = (qrsolve(AQ', rhs))'
        dx = q :* ((dy * A)' - r)
        ds = -dx
        dz = -z :* (1 :+ dx :/ x)
        dw = -w :* (1 :+ ds :/ s)

        fx = _qpc_bound(x, dx); fs = _qpc_bound(s, ds)
        fw = _qpc_bound(w, dw); fz = _qpc_bound(z, dz)
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

            fx = _qpc_bound(x, dx); fs = _qpc_bound(s, ds)
            fw = _qpc_bound(w, dw); fz = _qpc_bound(z, dz)
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

real colvector _qpc_bound(real colvector x, real colvector dx)
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
// MAIN: Li, Zheng & Guo (2016) — FM polynomial QR + Wald linearity test
// =====================================================================
void _qpolycoint_main(string scalar yname, string scalar xnames, real scalar pord)
{
    real colvector y, tau
    real matrix X, Xpoly, v
    real scalar T, k, Lq, M, ntotal, kpoly
    string scalar kerntype

    y = st_data(., yname)
    X = st_data(., xnames)
    T = rows(y)
    k = cols(X)
    tau = strtoreal(tokens(st_local("tau")))'
    Lq = rows(tau)
    kerntype = st_local("kernel")
    M = strtoreal(st_local("bw"))

    // Build polynomial regressors: x, x^2, ..., x^p
    // For each x-variable, append its powers as new columns
    kpoly = k * pord                   // total number of x-power columns
    ntotal = 1 + kpoly                 // + 1 for intercept

    Xpoly = J(T, kpoly, 0)
    real scalar j, pp, col_ix
    col_ix = 0
    for (pp=1; pp<=pord; pp++) {
        for (j=1; j<=k; j++) {
            col_ix = col_ix + 1
            Xpoly[., col_ix] = X[., j] :^ pp
        }
    }

    // First-differences of original X (innovations v_t for FM correction)
    real matrix Xlag
    Xlag = (J(1, k, 0) \ X[1..T-1, .])
    v = X - Xlag

    // Demean Xpoly for Mxx
    real rowvector Xmean
    real matrix Xpoly_d
    Xmean = mean(Xpoly)
    Xpoly_d = Xpoly :- Xmean

    // Kernel weights
    real rowvector h_set, K_row, K_row_1
    h_set = (0..M)
    K_row = _qpc_kernel(h_set / M, kerntype)
    K_row_1 = K_row[1, 2..(M+1)]

    // Initial OLS for u_hat
    real matrix Z_full
    real colvector theta_ols, u_hat
    Z_full = (J(T, 1, 1), Xpoly)
    theta_ols = invsym(Z_full' * Z_full) * (Z_full' * y)
    u_hat = y - Z_full * theta_ols

    // Storage
    real matrix coef_set, tQ_set, pval_set, fm_se_set
    coef_set  = J(Lq, ntotal, 0)
    tQ_set    = J(Lq, 1, 0)
    pval_set  = J(Lq, 1, 0)
    fm_se_set = J(Lq, ntotal, 0)

    real scalar k_ix, q, F_inv_tau, M_f, f_hat
    real colvector theta_q, u_tau, psi
    real matrix Omega_vv, Omega_vpsi_v
    real scalar omega2_psi_v

    for (k_ix=1; k_ix<=Lq; k_ix++) {
        q = tau[k_ix]

        // QR
        theta_q = _qpc_qreg(Z_full, y, q)
        u_tau = y - Z_full * theta_q
        psi = q :- (u_tau :< 0)

        // Density at F^{-1}(tau)
        F_inv_tau = _qpc_quantile(u_hat, q)
        M_f = 1.364 * ((2 * sqrt(pi()))^(-1/5)) * sqrt(variance(u_hat)) * (T^(-1/5))
        f_hat = sum(normalden((F_inv_tau :- u_hat) / M_f)) / (T * M_f)
        if (f_hat <= 0) f_hat = 1e-6

        // Long-run covariances using kernel (k x k for vv, k x 1 for v-psi, scalar psi)
        real matrix psi_th_1, v_th_full_n, v_th_1_only_n, psi_th
        real scalar n_ix, h_ix, m_ix
        real matrix Delta_vv, Lambda_vv_prim
        real colvector Delta_vpsi, Lambda_vpsi_prim
        real scalar Delta_psipsi, Lambda_psipsi_prim

        psi_th_1 = J(T, M, 0)
        for (h_ix=1; h_ix<=M; h_ix++) {
            psi_th_1[., h_ix] = (psi[(h_ix+1)..T] \ J(h_ix, 1, 0))
        }
        psi_th = (psi, psi_th_1)
        Delta_psipsi       = (K_row * (psi' * psi_th)')[1, 1] / T
        Lambda_psipsi_prim = (K_row_1 * (psi' * psi_th_1)')[1, 1] / T
        omega2_psi_v = Delta_psipsi + Lambda_psipsi_prim

        Delta_vpsi       = J(k, 1, 0)
        Lambda_vpsi_prim = J(k, 1, 0)
        Delta_vv         = J(k, k, 0)
        Lambda_vv_prim   = J(k, k, 0)

        for (n_ix=1; n_ix<=k; n_ix++) {
            v_th_full_n = J(T, M+1, 0)
            v_th_full_n[., 1] = v[., n_ix]
            for (h_ix=1; h_ix<=M; h_ix++) {
                v_th_full_n[., h_ix+1] = (v[(h_ix+1)..T, n_ix] \ J(h_ix, 1, 0))
            }
            v_th_1_only_n = v_th_full_n[., 2..(M+1)]
            Delta_vpsi[n_ix, 1] = (K_row * (v[., n_ix]' * psi_th)')[1, 1] / T
            Lambda_vpsi_prim[n_ix, 1] = (K_row_1 * (psi' * v_th_1_only_n)')[1, 1] / T
            for (m_ix=1; m_ix<=k; m_ix++) {
                Delta_vv[m_ix, n_ix] = (K_row * (v[., m_ix]' * v_th_full_n)')[1, 1] / T
                Lambda_vv_prim[m_ix, n_ix] = (K_row_1 * (v[., m_ix]' * v_th_1_only_n)')[1, 1] / T
            }
        }
        real colvector Omega_vpsi
        Omega_vv   = Delta_vv + Lambda_vv_prim
        Omega_vpsi = Delta_vpsi + Lambda_vpsi_prim
        real rowvector Omega_psiv
        Omega_psiv = Omega_vpsi'

        // omega^2_{psi.v} for SE
        omega2_psi_v = omega2_psi_v - (Omega_psiv * invsym(Omega_vv) * Omega_vpsi)[1, 1]
        if (omega2_psi_v <= 0) omega2_psi_v = 1e-8

        // FM correction (Li 2016 eq 6):
        //   theta_fm = theta - f^{-1} * (z'z)^{-1} * [sum z_t v_t' Omega_vv^{-1} Omega_vpsi + A]
        // Here z_t = (1, X_t, X_t^2, ..., X_t^p)' and v_t = Delta X_t (original I(1) regressors only).
        //
        // The matrix sum_t z_t v_t' is (ntotal x k):
        //   row 1: 0' (since z_1=1, v sum is scalar but mismatched dim - drop intercept row)
        //   rest: powers
        // Simpler: build Z_full' * v which is (ntotal x k).
        real matrix Zv
        Zv = Z_full' * v

        // A = [0, M_1', M_2', ..., M_p']' where each M_j is k-vector of
        //   j * lambda_{vi,psi}^{+} * sum_t x_{i,t}^{j-1}, i = 1..k
        // (Li 2016 eq 6, where lambda_{vi,psi}^{+} is the endogeneity-corrected
        //  one-sided long-run covariance)
        real colvector lambda_vpsi_plus
        lambda_vpsi_plus = Lambda_vpsi_prim - Lambda_vv_prim * invsym(Omega_vv) * Omega_vpsi
        // (using Lambda_vv_prim, Lambda_vpsi_prim as proxies for the one-sided lambdas)

        real colvector A_vec
        A_vec = J(ntotal, 1, 0)
        real scalar row_ix
        row_ix = 1   // skip intercept row (zero)
        for (pp=1; pp<=pord; pp++) {
            for (j=1; j<=k; j++) {
                row_ix = row_ix + 1
                // sum_t x_{j,t}^{p-1}
                real scalar sum_xpm1
                if (pp == 1) sum_xpm1 = T
                else         sum_xpm1 = sum(X[., j] :^ (pp - 1))
                A_vec[row_ix, 1] = pp * lambda_vpsi_plus[j] * sum_xpm1
            }
        }

        // (z'z)^{-1}
        real matrix Zd_full
        Zd_full = (J(T, 1, 1), Xpoly_d)
        real matrix ZdZd_inv
        ZdZd_inv = invsym(Zd_full' * Zd_full)

        real colvector theta_fm
        theta_fm = theta_q - (1/f_hat) * ZdZd_inv * (Zv * invsym(Omega_vv) * Omega_vpsi + A_vec)

        coef_set[k_ix, .] = theta_fm'

        // FM SE: Var(theta_fm) ~ (omega^2_{psi.v} / f^2) * (z'z)^{-1}
        real colvector se_fm
        se_fm = sqrt(omega2_psi_v :* diagonal(ZdZd_inv)) :/ f_hat
        fm_se_set[k_ix, .] = se_fm'

        // ---- WALD TEST: H0: gamma_2 = ... = gamma_p = 0 ----
        // The restricted coefficients are theta_fm[2+k .. ntotal] (powers 2..p, k each)
        // Wald = theta_R' * Var(theta_R)^{-1} * theta_R
        // where Var(theta_R) = (omega^2_{psi.v}/f^2) * [(z'z)^{-1}]_{RR}
        real scalar nrestr
        nrestr = k * (pord - 1)
        if (nrestr > 0) {
            real colvector theta_R
            real matrix Var_R
            theta_R = theta_fm[(2+k)..ntotal, 1]
            Var_R = (omega2_psi_v / f_hat^2) * ZdZd_inv[(2+k)..ntotal, (2+k)..ntotal]
            real scalar W
            W = (theta_R' * invsym(Var_R) * theta_R)[1, 1]
            tQ_set[k_ix, 1] = W
            pval_set[k_ix, 1] = chi2tail(nrestr, W)
        }
        else {
            tQ_set[k_ix, 1] = .
            pval_set[k_ix, 1] = .
        }
    }

    st_matrix("r(coef_set)", coef_set)
    st_matrix("r(tQ_set)",   tQ_set)
    st_matrix("r(pval_set)", pval_set)
    st_matrix("r(fm_se)",    fm_se_set)
}

end
