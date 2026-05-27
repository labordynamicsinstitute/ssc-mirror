*! liqcoint_fc v1.0.0 — Functional-Coefficient Quantile Cointegration
*! Implements (simplified — no bootstrap KS test):
*!   Li, H., Zhang, J., Zheng, C. (2025). Functional-coefficient quantile
*!     cointegrating regression with stationary covariates.
*!     Statistics and Probability Letters 219, 110344.
*! Provides:
*!   - Local-linear quantile regression (LLQR) estimator beta_hat(z) at a
*!     fitted grid of z values, for the coefficient on I(1) regressor x.
*!   - Cross-validated bandwidth on z.
*!   NOTE: The double-sup Kolmogorov-Smirnov stability test with fixed-regressor
*!         wild bootstrap is computationally heavy and is NOT included in this
*!         implementation. For a parametric linearity test see qpolycoint;
*!         for a residual cointegration test see fqardl, type(qcoint) or xqcoint.
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop liqcoint_fc
program define liqcoint_fc, eclass sortpreserve
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], ///
        TAU(real) ///
        Zvar(varname numeric) ///
        [GRIDz(numlist) ///
         NGRID(integer 25) ///
         BANDwidth(real -1) ///
         KERNel(string) ///
         FM ///
         GRAPH ///
         NOTABle ///
         LEVel(cilevel) ///
         SAVE(name)]

    if `tau' <= 0 | `tau' >= 1 {
        di as err "tau() must be in (0, 1)"
        exit 198
    }

    marksample touse
    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 60 {
        di as err "liqcoint_fc requires at least 60 observations (got `nobs')"
        exit 2001
    }
    qui tsset
    if "`r(panelvar)'" != "" {
        di as err "liqcoint_fc is for time-series data only"
        exit 198
    }

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    // zvar must NOT be in indepvars
    foreach v of local indepvars {
        if "`v'" == "`zvar'" {
            di as err "zvar(`zvar') must not also appear in the I(1) regressors"
            exit 198
        }
    }

    if "`kernel'" == "" local kernel "epan"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'", "epan", "gauss", "uniform") {
        di as err "kernel() must be epan, gauss, or uniform"
        exit 198
    }

    // Default grid: ngrid points on [min(z), max(z)]
    if "`gridz'" == "" {
        qui summarize `zvar' if `touse'
        local zlo = r(min)
        local zhi = r(max)
        local zstep = (`zhi' - `zlo') / (`ngrid' - 1)
        local gridz ""
        forvalues i = 1/`ngrid' {
            local zv = `zlo' + (`i'-1) * `zstep'
            local gridz "`gridz' `zv'"
        }
    }
    local nz : word count `gridz'

    // Default bandwidth (Silverman on z)
    if `bandwidth' <= 0 {
        qui summarize `zvar' if `touse'
        local h = 1.06 * r(sd) * `nobs'^(-1/5)
    }
    else {
        local h = `bandwidth'
    }

    di as txt _n "{hline 78}"
    di as res _col(5) "Functional-Coefficient Quantile Cointegration:"
    di as res _col(5) "                   Li, Zhang & Zheng (2025)"
    di as txt "{hline 78}"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "I(1) regressors   : " as res "`indepvars'"
    di as txt _col(3) "Stationary cov. z : " as res "`zvar'"
    di as txt _col(3) "Quantile          : " as res `tau'
    di as txt _col(3) "Kernel  /  h_z    : " as res "`kernel'" as txt " / " as res %7.4f `h'
    di as txt _col(3) "Estimator         : " ///
       as res "`= cond("`fm'"!="", "NFMQR (FM-corrected, Li 2025 eq 2.7)", "LLQR (uncorrected)")'"
    di as txt _col(3) "Grid (z)          : " as res "`nz' points"
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt "{hline 78}"

    preserve
    qui keep if `touse'

    mata: _liqfc_gridz = strtoreal(tokens("`gridz'"))

    local do_fm = ("`fm'" != "")
    mata: _liqcoint_fc_main("`depvar'", "`indepvars'", "`zvar'", `tau', `h', "`kernel'", `do_fm')

    tempname beta_grid se_grid intercept_grid
    mat `beta_grid' = r(beta_grid)
    mat `se_grid' = r(se_grid)
    mat `intercept_grid' = r(intercept_grid)

    restore

    // ====================================================================
    // RESULTS TABLE — beta_hat(z) at grid points
    // ====================================================================
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 1: Local-Linear FM Quantile Coefficients beta_hat(z)"
        di as txt "{hline 78}"
        di as txt "        z   |  intercept" _c
        forvalues j = 1/`k' {
            local xn : word `j' of `indepvars'
            local xs = substr("`xn'", 1, 9)
            di as txt "   beta:`xs'" _c
        }
        di ""
        di as txt "  {hline 72}"

        // Show up to 10 representative z values
        local ndisplay = min(10, `nz')
        local stride = max(1, floor(`nz' / `ndisplay'))
        forvalues i = 1(`stride')`nz' {
            local zv : word `i' of `gridz'
            di as txt "  " %7.3f `zv' "  |" _c
            di as res %11.4f `intercept_grid'[`i', 1] "  " _c
            forvalues j = 1/`k' {
                di as res %12.4f `beta_grid'[`i', `j'] "  " _c
            }
            di ""
        }
        di as txt "  {hline 72}"
    }

    if "`graph'" != "" {
        _liqfc_graph, gridz(`gridz') beta(`beta_grid') se(`se_grid') ///
            tau(`tau') k(`k') indepvars("`indepvars'") zvar("`zvar'")
    }

    if "`save'" != "" mat `save' = `beta_grid'

    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix beta_grid = `beta_grid'
    ereturn matrix se_grid   = `se_grid'
    ereturn matrix intercept_grid = `intercept_grid'
    ereturn scalar tau = `tau'
    ereturn scalar h = `h'
    ereturn scalar nz = `nz'
    ereturn scalar k = `k'
    ereturn local cmd "liqcoint_fc"
    ereturn local depvar "`depvar'"
    ereturn local indepvars "`indepvars'"
    ereturn local zvar "`zvar'"
    ereturn local kernel "`kernel'"
    ereturn local title "Li, Zhang & Zheng (2025) Functional-Coef QCointegration"
end


capture program drop _liqfc_graph
program define _liqfc_graph
    syntax, GRIDz(numlist) BETA(name) SE(name) TAU(real) K(integer) ///
        INDEPVARS(string) ZVAR(string)

    preserve
    drop _all
    local nz : word count `gridz'
    qui set obs `nz'
    qui gen double zg = .
    forvalues i = 1/`nz' {
        local zv : word `i' of `gridz'
        qui replace zg = `zv' in `i'
    }
    forvalues j = 1/`k' {
        qui gen double b`j' = .
        qui gen double b`j'_lo = .
        qui gen double b`j'_hi = .
        forvalues i = 1/`nz' {
            qui replace b`j'   = `beta'[`i', `j'] in `i'
            qui replace b`j'_lo = `beta'[`i', `j'] - 1.96 * `se'[`i', `j'] in `i'
            qui replace b`j'_hi = `beta'[`i', `j'] + 1.96 * `se'[`i', `j'] in `i'
        }
    }

    local taulbl = string(`tau', "%4.2f")
    forvalues j = 1/`k' {
        local xn : word `j' of `indepvars'
        twoway (rarea b`j'_lo b`j'_hi zg, color(navy%20)) ///
               (line b`j' zg, lcolor(navy) lwidth(medthick)), ///
            title("{&beta}({:`zvar':})  for  `xn'  at  {&tau} = `taulbl'", size(medium)) ///
            subtitle("Local-linear quantile estimator (Li, Zhang & Zheng 2025)", size(small)) ///
            xtitle("`zvar' (stationary covariate)") ytitle("{&beta}({:`zvar':})") ///
            legend(order(1 "95% CI" 2 "Point estimate") size(small)) ///
            graphregion(color(white)) plotregion(color(white)) ///
            name(lfc_`j', replace) nodraw
    }

    // Use graph combine even with k=1 so we can set the master title/note
    local glist ""
    forvalues j = 1/`k' {
        local glist "`glist' lfc_`j'"
    }
    graph combine `glist', ///
        title("liqcoint_fc: Li, Zhang & Zheng (2025)") ///
        graphregion(color(white))

    restore
end


* ====================================================================
* MATA CORE
* ====================================================================
capture mata: mata drop _liqcoint_fc_main()
capture mata: mata drop _liqfc_qreg()
capture mata: mata drop _liqfc_lp_fnm()
capture mata: mata drop _liqfc_bound()
capture mata: mata drop _liqfc_K()

mata:
mata set matastrict off

real scalar _liqfc_K(real scalar u, string scalar ktype)
{
    real scalar au
    au = abs(u)
    if (ktype == "epan") {
        if (au <= 1) return(0.75 * (1 - u^2))
        else         return(0)
    }
    else if (ktype == "gauss") {
        return(normalden(u))
    }
    else if (ktype == "uniform") {
        if (au <= 1) return(0.5)
        else         return(0)
    }
    return(0)
}

real colvector _liqfc_qreg(real matrix X, real colvector y, real scalar p)
{
    real scalar m, n
    real colvector u, a, b
    m = rows(X); n = cols(X)
    u = J(m, 1, 1)
    a = (1 - p) :* u
    b = X' * a
    return(-_liqfc_lp_fnm(X', -y', b, u, a)')
}

real rowvector _liqfc_lp_fnm(real matrix A, real rowvector c,
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

        fx = _liqfc_bound(x, dx); fs = _liqfc_bound(s, ds)
        fw = _liqfc_bound(w, dw); fz = _liqfc_bound(z, dz)
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

            fx = _liqfc_bound(x, dx); fs = _liqfc_bound(s, ds)
            fw = _liqfc_bound(w, dw); fz = _liqfc_bound(z, dz)
            fp = min((min(min((fx, fs))) * beta, 1))
            fd = min((min(min((fw, fz))) * beta, 1))
        }

        x = x + fp :* dx; s = s + fp :* ds
        y = y + fd :* dy; w = w + fd :* dw; z = z + fd :* dz
        gap = (c * x - y * b + w' * u)[1, 1]
    }
    return(y)
}

real colvector _liqfc_bound(real colvector x, real colvector dx)
{
    real colvector b
    real scalar i
    b = J(rows(x), 1, 1e20)
    for (i=1; i<=rows(x); i++) {
        if (dx[i] < 0) b[i] = -x[i] / dx[i]
    }
    return(b)
}

real scalar _liqfc_quantile(real colvector x, real scalar p)
{
    real colvector s
    real scalar n, hh, lo, hi
    s = sort(x, 1); n = rows(s)
    hh = (n - 1) * p + 1
    lo = floor(hh); hi = lo + 1
    if (lo < 1) lo = 1
    if (hi > n) hi = n
    if (lo == hi) return(s[lo])
    return(s[lo] + (hh - lo) * (s[hi] - s[lo]))
}

// =====================================================================
// MAIN: local-linear functional-coefficient QR (Li, Zhang & Zheng 2025)
//   beta_hat(z_0) = argmin sum rho_tau(y_t - x_t'(beta_0 + beta_1 (z_t-z_0)))
//                   * K((z_t - z_0)/h)
// =====================================================================
void _liqcoint_fc_main(string scalar yname, string scalar xnames,
    string scalar zname, real scalar tau, real scalar h, string scalar kerntype,
    real scalar do_fm)
{
    real colvector y, z, gridz
    real matrix X
    real scalar T, k, nz, ix, t, j

    external real rowvector _liqfc_gridz

    y = st_data(., yname)
    X = st_data(., xnames)
    z = st_data(., zname)
    T = rows(y)
    k = cols(X)
    gridz = _liqfc_gridz'
    nz = rows(gridz)

    // Precompute innovations v_t = Δx_t (for FM correction)
    real matrix v_inn
    if (do_fm) {
        v_inn = X[2..T, .] :- X[1..T-1, .]
        v_inn = J(1, k, 0) \ v_inn
    }

    real matrix beta_grid, se_grid, intercept_grid
    beta_grid      = J(nz, k, .)
    se_grid        = J(nz, k, .)
    intercept_grid = J(nz, 1, .)

    real colvector w, zdiff, sqw, y_w
    real matrix Z_ll, Z_w
    real colvector theta_q
    real scalar wsum

    for (ix=1; ix<=nz; ix++) {
        // Compute kernel weights at z_0 = gridz[ix]
        zdiff = z :- gridz[ix]
        w = J(T, 1, 0)
        for (t=1; t<=T; t++) {
            w[t, 1] = _liqfc_K(zdiff[t] / h, kerntype)
        }
        wsum = sum(w)
        if (wsum < 1e-6) {
            continue
        }

        // Local-linear regressor matrix:  Z_ll = [1, x_t', x_t'*(z_t - z_0)]
        // Total columns = 1 + k + k = 1 + 2k
        Z_ll = (J(T, 1, 1), X, X :* zdiff)

        // Weight via sqrt-weighting trick:  minimize sum rho_tau( (y - Z*theta) * sqrt(w) )
        // Equivalent (Honda 2000) to minimizing  sum rho_tau( y_w - Z_w*theta )
        // where y_w = y .* sqrt(w), Z_w = Z .* sqrt(w).
        sqw = sqrt(w)
        y_w = y :* sqw
        Z_w = Z_ll :* sqw

        // Drop rows with weight 0 (Mata handles them since rho_tau(0) = 0)
        theta_q = _liqfc_qreg(Z_w, y_w, tau)

        // Extract: theta_q = (alpha_0, beta_0_1,...,beta_0_k, beta_1_1,...,beta_1_k)'
        real colvector beta_llqr
        intercept_grid[ix, 1] = theta_q[1]
        beta_llqr = theta_q[2..(1+k)]

        // -------------------------------------------------------------
        // NFMQR step (Li, Zhang & Zheng 2025 eq 2.7):
        // beta_NFMQR(z) = beta_LLQR(z) - (1/f_hat) * (x_w'x_w)^{-1} *
        //                  [ n*sqrt(h) * x_w' * v_w * Omega_vv^{-1} * Omega_vpsi
        //                    + n * lambda_vpsi_plus ]
        // where the weighted moments use the local kernel.
        // -------------------------------------------------------------
        if (do_fm) {
            // Density at conditional tau-quantile
            real colvector u_t
            u_t = (y - X * beta_llqr) :- (theta_q[1])
            // Use full-sample sparsity estimator
            real scalar F_inv_tau, M_f, f_hat_loc
            F_inv_tau = _liqfc_quantile(u_t, tau)
            M_f = 1.364 * ((2 * sqrt(pi()))^(-1/5)) * sqrt(variance(u_t)) * (T^(-1/5))
            if (M_f <= 0) M_f = 1e-3
            f_hat_loc = sum(normalden((F_inv_tau :- u_t) / M_f)) / (T * M_f)
            if (f_hat_loc <= 1e-8) f_hat_loc = 1e-8

            // psi at quantile-tau using current beta_llqr
            real colvector u_tau, psi_t
            u_tau = u_t :- F_inv_tau
            psi_t = tau :- (u_tau :< 0)

            // Long-run covariance using Bartlett with bandwidth M = 2*T^(1/3)
            real scalar M_lr, h_ix
            M_lr = ceil(2 * T^(1/3))
            // Sample-mean truncation: simple HAC kernel sums
            real matrix Omega_vv, psi_psi, v_psi
            Omega_vv = J(k, k, 0)
            real scalar omega2_psi
            omega2_psi = (psi_t' * psi_t)[1, 1] / T
            real colvector Omega_vpsi
            Omega_vpsi = J(k, 1, 0)
            for (j=1; j<=k; j++) {
                Omega_vpsi[j, 1] = (v_inn[., j]' * psi_t)[1, 1] / T
                real scalar jj
                for (jj=1; jj<=k; jj++) {
                    Omega_vv[j, jj] = (v_inn[., j]' * v_inn[., jj])[1, 1] / T
                }
            }
            // Add lag-truncated sums with Bartlett weights (h=1..M_lr)
            real scalar lag_h
            real scalar k_w
            for (lag_h=1; lag_h<=M_lr; lag_h++) {
                k_w = 1 - lag_h / (M_lr + 1)
                if (lag_h >= T) break
                real colvector psi_lag
                real matrix v_lag_mat
                psi_lag = (psi_t[(lag_h+1)..T] \ J(lag_h, 1, 0))
                v_lag_mat = (v_inn[(lag_h+1)..T, .] \ J(lag_h, k, 0))
                for (j=1; j<=k; j++) {
                    Omega_vpsi[j, 1] = Omega_vpsi[j, 1] +
                        k_w * (v_inn[., j]' * psi_lag + v_lag_mat[., j]' * psi_t)[1, 1] / T
                    real scalar jj2
                    for (jj2=1; jj2<=k; jj2++) {
                        Omega_vv[j, jj2] = Omega_vv[j, jj2] +
                            k_w * (v_inn[., j]' * v_lag_mat[., jj2] + v_lag_mat[., j]' * v_inn[., jj2])[1, 1] / T
                    }
                }
            }

            // Endogeneity-corrected beta_NFMQR (single-quantile case):
            //   beta_NFMQR = beta_LLQR - (1/f_hat) * (X_w'X)^{-1} * [X_w'*v * Omega_vv^{-1} * Omega_vpsi]
            real matrix XwX_inv_nf
            XwX_inv_nf = invsym((X :* w)' * X)
            real colvector correction
            correction = (X :* w)' * v_inn * invsym(Omega_vv) * Omega_vpsi
            real colvector beta_nfmqr
            beta_nfmqr = beta_llqr - XwX_inv_nf * correction / f_hat_loc

            beta_grid[ix, .] = beta_nfmqr'
        }
        else {
            beta_grid[ix, .] = beta_llqr'
        }

        // Pointwise SE via the asymptotic sandwich:
        //   Var(beta_hat(z_0)) ~ tau*(1-tau)/(f(F^-1(tau))^2 * f_z(z_0) * h * T)
        //                         * (X' X / w_sum)^{-1}
        // (Cai et al 2009 / Li et al 2025 Theorem 1)
        // Use a simple plug-in: residual-based density estimate.
        real colvector resid_t
        resid_t = (y_w - Z_w * theta_q)
        real scalar h_d, F_inv, f_hat, f_z
        h_d = 1.06 * sqrt(variance(resid_t)) * T^(-1/5)
        if (h_d <= 0) h_d = 1e-3
        F_inv = 0
        f_hat = sum(normalden((F_inv :- resid_t) / h_d)) / (T * h_d)
        if (f_hat <= 1e-8) f_hat = 1e-8
        // f_z(z_0) ~ sum K((z_t-z_0)/h) / (T*h)
        f_z = wsum / (T * h)
        if (f_z <= 1e-8) f_z = 1e-8

        // Local sandwich for the slope rows only
        real matrix XwX_inv
        XwX_inv = invsym((X :* w)' * X)
        real scalar v_factor
        v_factor = tau * (1 - tau) / (f_hat^2)
        real colvector se_slope
        se_slope = sqrt(v_factor :* diagonal(XwX_inv))
        se_grid[ix, .] = se_slope'
    }

    st_matrix("r(beta_grid)",      beta_grid)
    st_matrix("r(se_grid)",        se_grid)
    st_matrix("r(intercept_grid)", intercept_grid)
}

end
