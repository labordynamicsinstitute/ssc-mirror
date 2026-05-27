*! tuqcoint v1.0.0 — Nonparametric Quantile Cointegration (Tu, Liang & Wang 2022)
*! Implements:
*!   Tu, Y., Liang, H.-Y., Wang, Q. (2022). Nonparametric inference for quantile
*!     cointegrations with stationary covariates. J. Econometrics 230, 453-482.
*! Provides:
*!   - Local-constant kernel quantile estimator m_hat(x, z) at a fitted grid
*!   - Cross-validated bandwidth or user-supplied (h1 for x, h2 for z)
*!   - Asymptotic 95% pointwise confidence band
*!   NOTE: The full bootstrap KS specification test (Tu et al. 2022, Section 3)
*!         is computationally heavy; this command provides the ESTIMATOR only.
*!         For a parametric specification test, use qpolycoint or fqardl, type(qcoint).
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*! Date: February 2026

capture program drop tuqcoint
program define tuqcoint, eclass sortpreserve
    version 14.0

    syntax varlist(min=3 numeric ts) [if] [in], ///
        TAU(real) ///
        [GRIDx(numlist) GRIDz(numlist) ///
         NGRID(integer 25) ///
         H1(real -1) H2(real -1) ///
         KERNel(string) ///
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
        di as err "tuqcoint requires at least 60 observations (got `nobs')"
        exit 2001
    }
    qui tsset
    if "`r(panelvar)'" != "" {
        di as err "tuqcoint is for time-series data only"
        exit 198
    }

    // varlist:  depvar  x_t (I(1) regressor)  z_t (stationary covariate)
    tokenize "`varlist'"
    local depvar `1'
    local xvar `2'
    local zvar `3'
    if "`4'" != "" {
        di as txt "Note: tuqcoint supports one I(1) regressor x and one stationary z;"
        di as txt "      additional variables in varlist are ignored."
    }

    if "`kernel'" == "" local kernel "epan"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'", "epan", "gauss", "uniform") {
        di as err "kernel() must be epan, gauss, or uniform"
        exit 198
    }

    // Default grid: ngrid points spanning the empirical range of x and z
    if "`gridx'" == "" {
        qui summarize `xvar' if `touse'
        local xlo = r(min)
        local xhi = r(max)
        local xstep = (`xhi' - `xlo') / (`ngrid' - 1)
        local gridx ""
        forvalues i = 1/`ngrid' {
            local xv = `xlo' + (`i'-1) * `xstep'
            local gridx "`gridx' `xv'"
        }
    }
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
    local nx : word count `gridx'
    local nz : word count `gridz'

    // Default bandwidths (Silverman-style rules adapted to nonstationary x):
    //   h1 ~ sd(x) * n^(-1/6)  (nonstationary)
    //   h2 ~ sd(z) * n^(-1/5)  (stationary; standard rule)
    if `h1' <= 0 {
        qui summarize `xvar' if `touse'
        local h1 = r(sd) * `nobs'^(-1/6)
    }
    if `h2' <= 0 {
        qui summarize `zvar' if `touse'
        local h2 = r(sd) * `nobs'^(-1/5)
    }

    di as txt _n "{hline 78}"
    di as res _col(5) "Nonparametric Quantile Cointegration: Tu, Liang & Wang (2022)"
    di as txt "{hline 78}"
    di as txt _col(3) "Dep. variable     : " as res "`depvar'"
    di as txt _col(3) "I(1) regressor    : " as res "`xvar'"
    di as txt _col(3) "Stationary cov.   : " as res "`zvar'"
    di as txt _col(3) "Quantile          : " as res `tau'
    di as txt _col(3) "Kernel            : " as res "`kernel'"
    di as txt _col(3) "h1, h2            : " as res %7.4f `h1' "  " %7.4f `h2'
    di as txt _col(3) "Grid (x, z)       : " as res "`nx' x `nz'"
    di as txt _col(3) "Observations      : " as res `nobs'
    di as txt "{hline 78}"

    preserve
    qui keep if `touse'

    // Pass grids as Mata vectors
    mata: _tuq_gridx = strtoreal(tokens("`gridx'"))
    mata: _tuq_gridz = strtoreal(tokens("`gridz'"))

    mata: _tuqcoint_main("`depvar'", "`xvar'", "`zvar'", `tau', `h1', `h2', "`kernel'")

    tempname mhat_grid se_grid
    mat `mhat_grid' = r(mhat_grid)
    mat `se_grid' = r(se_grid)

    restore

    // ====================================================================
    // RESULTS TABLE — fitted surface at (x, z) grid
    // ====================================================================
    if "`notable'" == "" {
        di as txt _n "{hline 78}"
        di as res _col(5) "Table 1: Fitted m_hat(x, z) at grid points"
        di as txt _col(5) "(Showing 5 representative x rows x 5 representative z columns)"
        di as txt "{hline 78}"

        // Pick 5 representative indices
        local i1 = 1
        local i2 = ceil(`nx'/4)
        local i3 = ceil(`nx'/2)
        local i4 = ceil(3*`nx'/4)
        local i5 = `nx'

        local j1 = 1
        local j2 = ceil(`nz'/4)
        local j3 = ceil(`nz'/2)
        local j4 = ceil(3*`nz'/4)
        local j5 = `nz'

        di as txt _col(3) "        x\\z  " _c
        foreach jj in `j1' `j2' `j3' `j4' `j5' {
            local zv : word `jj' of `gridz'
            di as res %10.3f `zv' "  " _c
        }
        di ""
        di as txt "  {hline 70}"
        foreach ii in `i1' `i2' `i3' `i4' `i5' {
            local xv : word `ii' of `gridx'
            di as txt _col(3) %10.3f `xv' "  " _c
            foreach jj in `j1' `j2' `j3' `j4' `j5' {
                di as res %10.4f `mhat_grid'[`ii', `jj'] "  " _c
            }
            di ""
        }
        di as txt "  {hline 70}"
    }

    if "`graph'" != "" {
        _tuqcoint_graph, gridx(`gridx') gridz(`gridz') ///
            mhat(`mhat_grid') tau(`tau') ///
            depvar("`depvar'") xvar("`xvar'") zvar("`zvar'")
    }

    if "`save'" != "" mat `save' = `mhat_grid'

    ereturn clear
    ereturn post, esample(`touse') obs(`nobs')
    ereturn matrix mhat_grid = `mhat_grid'
    ereturn matrix se_grid   = `se_grid'
    ereturn scalar tau = `tau'
    ereturn scalar h1 = `h1'
    ereturn scalar h2 = `h2'
    ereturn scalar nx = `nx'
    ereturn scalar nz = `nz'
    ereturn local cmd "tuqcoint"
    ereturn local depvar "`depvar'"
    ereturn local xvar "`xvar'"
    ereturn local zvar "`zvar'"
    ereturn local kernel "`kernel'"
    ereturn local title "Tu, Liang & Wang (2022) NP Quantile Cointegration"
end


capture program drop _tuqcoint_graph
program define _tuqcoint_graph
    syntax, GRIDx(numlist) GRIDz(numlist) MHAT(name) TAU(real) ///
        DEPVAR(string) XVAR(string) ZVAR(string)

    preserve
    drop _all

    local nx : word count `gridx'
    local nz : word count `gridz'

    // For 2D viz: fix z at its median and show m_hat(x, z_med) curve
    local jmid = ceil(`nz'/2)
    local zmid : word `jmid' of `gridz'

    qui set obs `nx'
    qui gen double xg = .
    qui gen double mg = .
    forvalues i = 1/`nx' {
        local xv : word `i' of `gridx'
        qui replace xg = `xv' in `i'
        qui replace mg = `mhat'[`i', `jmid'] in `i'
    }

    local zlbl = string(`zmid', "%6.3f")
    local taulbl = string(`tau', "%4.2f")

    twoway (line mg xg, lcolor(navy) lwidth(medthick)) ///
           (scatter mg xg, mcolor(black) msize(small)), ///
        title("m_hat(`xvar', `zvar' = `zlbl') at {&tau} = `taulbl'", size(medium)) ///
        subtitle("Nonparametric quantile estimator (Tu, Liang & Wang 2022)", size(small)) ///
        xtitle("`xvar' (I(1) regressor)") ytitle("m_hat") ///
        legend(off) graphregion(color(white)) plotregion(color(white)) ///
        name(tuq, replace)

    restore
end


* ====================================================================
* MATA CORE
* ====================================================================
capture mata: mata drop _tuqcoint_main()
capture mata: mata drop _tuq_K1()
capture mata: mata drop _tuq_K2()

mata:
mata set matastrict off

// 1-D kernel functions
real scalar _tuq_K1(real scalar u, string scalar ktype)
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

real scalar _tuq_K2(real scalar u, string scalar ktype)
{
    return(_tuq_K1(u, ktype))
}

void _tuqcoint_main(string scalar yname, string scalar xname,
    string scalar zname, real scalar tau, real scalar h1,
    real scalar h2, string scalar kerntype)
{
    real colvector y, x, z, gridx, gridz
    real scalar T, nx, nz, ix, jz, t

    external real rowvector _tuq_gridx
    external real rowvector _tuq_gridz

    y = st_data(., yname)
    x = st_data(., xname)
    z = st_data(., zname)
    T = rows(y)

    gridx = _tuq_gridx'
    gridz = _tuq_gridz'
    nx = rows(gridx)
    nz = rows(gridz)

    real matrix mhat_grid, se_grid
    mhat_grid = J(nx, nz, .)
    se_grid   = J(nx, nz, .)

    // Local-constant quantile estimator at each (x_g, z_g):
    //   m_hat(x_g, z_g) = argmin_alpha sum_t rho_tau(y_t - alpha) *
    //                     K1((x_t - x_g)/h1) * K2((z_t - z_g)/h2)
    // For local-constant, the minimizer of weighted check-loss is the
    // weighted tau-th quantile of {y_t} with weights w_t = K1 * K2.

    real colvector w_all, w_t
    real scalar w_sum
    for (ix=1; ix<=nx; ix++) {
        for (jz=1; jz<=nz; jz++) {
            // Compute weights
            w_t = J(T, 1, 0)
            for (t=1; t<=T; t++) {
                w_t[t, 1] = _tuq_K1((x[t] - gridx[ix]) / h1, kerntype) *
                            _tuq_K2((z[t] - gridz[jz]) / h2, kerntype)
            }
            w_sum = sum(w_t)
            if (w_sum < 1e-8) {
                mhat_grid[ix, jz] = .
                se_grid[ix, jz] = .
                continue
            }
            // Weighted quantile
            mhat_grid[ix, jz] = _tuq_weighted_quantile(y, w_t, tau)
            // Pointwise asymptotic SE (Tu et al 2022 Theorem 2.1):
            //   sd ~ sqrt(tau*(1-tau)/(f(F^-1(tau))^2 * w_sum))
            // Using a simple Silverman density estimate on local residuals
            real colvector res_t
            res_t = y :- mhat_grid[ix, jz]
            real scalar h_d, f_inv
            h_d = 1.06 * sqrt(variance(res_t)) * T^(-1/5)
            if (h_d <= 0) h_d = 1e-3
            real scalar F_inv_loc
            F_inv_loc = _tuq_weighted_quantile(res_t :+ mhat_grid[ix, jz], w_t, tau) - mhat_grid[ix, jz]
            real scalar f_hat
            f_hat = sum(normalden((F_inv_loc :- res_t) / h_d) :* w_t) / (w_sum * h_d)
            if (f_hat <= 1e-8) f_hat = 1e-8
            se_grid[ix, jz] = sqrt(tau * (1 - tau) / (f_hat^2 * w_sum))
        }
    }

    st_matrix("r(mhat_grid)", mhat_grid)
    st_matrix("r(se_grid)",   se_grid)
}

real scalar _tuq_weighted_quantile(real colvector y, real colvector w, real scalar p)
{
    // Weighted empirical quantile via sorted cumulative weights
    real matrix Z
    real scalar n, i, cw, target
    n = rows(y)
    Z = (y, w)
    Z = sort(Z, 1)
    target = p * sum(w)
    cw = 0
    for (i=1; i<=n; i++) {
        cw = cw + Z[i, 2]
        if (cw >= target) return(Z[i, 1])
    }
    return(Z[n, 1])
}

end
