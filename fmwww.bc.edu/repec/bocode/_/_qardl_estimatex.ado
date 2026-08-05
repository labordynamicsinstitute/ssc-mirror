*! _qardl_estimatex v1.2.0 - QARDL with per-regressor distributed-lag orders
*! Translates qardlX from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! Each regressor gets its own q.  The Cho-Kim-Shin iid covariance
*! formulas are written for a single scalar q and do not generalise to a
*! heterogeneous lag structure, so this path always uses the
*! quantile-regression sandwich, exactly as qardlX does in GAUSS (whose
*! cov_type defaults to "robust").

program define _qardl_estimatex, rclass
    version 14.0

    capture mata which _qardl_qreg()
    if _rc {
        capture program drop _qardl_estimate
        qui findfile _qardl_estimate.ado
        qui run "`r(fn)'"
    }

    syntax varlist(min=2 numeric ts) [if] [in], P(integer) ///
        QVEC(numlist integer >=0) TAU(numlist >0 <1 sort) ///
        [NOCONStant COVariance(string) HAClags(integer 0)]

    marksample touse

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'
    local nq : word count `qvec'

    if `nq' != `k' {
        di as error "qvec() must have `k' elements, one per regressor; got `nq'"
        exit 198
    }

    if "`covariance'" == "" local covariance "robust"
    local covariance = lower("`covariance'")
    if "`covariance'" == "iid" {
        di as error "covariance(iid) is not defined for per-regressor lag orders"
        di as error "use covariance(robust) or covariance(hac), or a scalar q()"
        exit 198
    }
    if !inlist("`covariance'", "robust", "hac") {
        di as error "covariance() must be robust or hac"
        exit 198
    }

    qui count if `touse'
    local nobs = r(N)

    qui putmata _qx_y = `depvar' if `touse', replace
    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _qx_X = (`mxvars') if `touse', replace

    mata: _qx_tau = strtoreal(tokens(st_local("tau")))'
    mata: _qx_qvec = strtoreal(tokens(st_local("qvec")))'

    mata: _qardl_corex_estimate(_qx_y, _qx_X, `p', _qx_qvec, _qx_tau, ///
        "`covariance'", `haclags')

    return matrix beta = _qardl_beta
    return matrix beta_cov = _qardl_beta_cov
    return matrix phi = _qardl_phi
    return matrix phi_cov = _qardl_phi_cov
    return matrix gamma = _qardl_gamma
    return matrix gamma_cov = _qardl_gamma_cov
    return matrix alpha = _qardl_alpha
    return matrix rho = _qardl_rho
    return matrix bt_raw = _qardl_bt_raw
    return matrix fh_vec = _qardl_fh
    return scalar scale_beta = 1
    return scalar scale_short = 1
    return scalar haclags_used = _qardl_haclags_used
    return scalar N_eff = _qardl_neff
    return local covariance "`covariance'"
    return scalar p = `p'
    return scalar k = `k'
    return scalar N = `nobs'
end

capture mata: mata drop _qardl_design_qvec()
capture mata: mata drop _qardl_levels_cov_pos()
capture mata: mata drop _qardl_corex_estimate()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// Levels design with a per-regressor lag vector.
// Translates _qardlBuildLevelsDesignX().  For a constant qvec this
// produces exactly the same matrix as _qardl_ic_design().
//
// Column layout: [1, dx terms (variable-major), x levels, y lags]
// theta_start and phi_start are returned by reference.
// ------------------------------------------------------------------
real matrix _qardl_design_qvec(real colvector yy, real matrix xx,
    real scalar ppp, real colvector qvec, real colvector Y,
    real scalar theta_start, real scalar phi_start)
{
    real scalar nn, k0, qmax, T0, N, ii, jj, col_idx, qsum
    real matrix ee, dx_terms, y_lags, X

    nn = rows(yy)
    k0 = cols(xx)
    qmax = colmax(qvec)
    qsum = colsum(qvec)
    T0 = max((ppp, qmax))
    N = nn - T0

    Y = yy[(T0+1)..nn]

    ee = xx[2..nn, .] - xx[1..nn-1, .]
    ee = J(1, k0, 0) \ ee

    if (qsum > 0) {
        dx_terms = J(N, qsum, 0)
        col_idx = 1
        for (ii = 1; ii <= k0; ii++) {
            for (jj = 0; jj <= qvec[ii] - 1; jj++) {
                dx_terms[., col_idx] = ee[(T0+1-jj)..(nn-jj), ii]
                col_idx++
            }
        }
        X = (dx_terms, xx[(T0+1)..nn, .])
    }
    else {
        X = xx[(T0+1)..nn, .]
    }

    y_lags = J(N, ppp, 0)
    for (jj = 1; jj <= ppp; jj++) {
        y_lags[., jj] = yy[(T0+1-jj)..(nn-jj)]
    }

    X = (X, y_lags)

    theta_start = 2 + qsum
    phi_start   = theta_start + k0

    return((J(N, 1, 1), X))
}

// ------------------------------------------------------------------
// Delta-method mapping of the full sandwich covariance into the beta,
// phi and gamma blocks, given explicit block positions.
// Translates _qardlLevelsCovFromFullPositions().
// ------------------------------------------------------------------
void _qardl_levels_cov_pos(real matrix full_cov, real matrix bt,
    real scalar theta_start, real scalar phi_start, real scalar k0,
    real scalar ppp, real scalar ss,
    real matrix bigbt_cov, real matrix phi_cov, real matrix gamma_cov)
{
    real scalar K, theta_end, phi_end, ii, jj, row_i, row_j, den_i, den_j
    real matrix trans_i, trans_j, block_ij
    real colvector theta_i, theta_j

    K = rows(bt)
    theta_end = theta_start + k0 - 1
    phi_end   = phi_start + ppp - 1

    bigbt_cov = J(k0 * ss, k0 * ss, 0)
    phi_cov   = J(ppp * ss, ppp * ss, 0)
    gamma_cov = J(k0 * ss, k0 * ss, 0)

    for (ii = 1; ii <= ss; ii++) {
        theta_i = bt[theta_start..theta_end, ii]
        den_i   = 1 - colsum(bt[phi_start..phi_end, ii])

        trans_i = J(k0, K, 0)
        trans_i[., theta_start..theta_end] = I(k0) / den_i
        trans_i[., phi_start..phi_end]     = (theta_i / den_i^2) * J(1, ppp, 1)

        for (jj = 1; jj <= ss; jj++) {
            theta_j = bt[theta_start..theta_end, jj]
            den_j   = 1 - colsum(bt[phi_start..phi_end, jj])

            trans_j = J(k0, K, 0)
            trans_j[., theta_start..theta_end] = I(k0) / den_j
            trans_j[., phi_start..phi_end]     = (theta_j / den_j^2) * J(1, ppp, 1)

            row_i = (ii - 1) * K + 1
            row_j = (jj - 1) * K + 1
            block_ij = full_cov[row_i..(row_i+K-1), row_j..(row_j+K-1)]

            bigbt_cov[((ii-1)*k0+1)..(ii*k0), ((jj-1)*k0+1)..(jj*k0)] =
                trans_i * block_ij * trans_j'

            gamma_cov[((ii-1)*k0+1)..(ii*k0), ((jj-1)*k0+1)..(jj*k0)] =
                block_ij[theta_start..theta_end, theta_start..theta_end]

            phi_cov[((ii-1)*ppp+1)..(ii*ppp), ((jj-1)*ppp+1)..(jj*ppp)] =
                block_ij[phi_start..phi_end, phi_start..phi_end]
        }
    }
}

// ------------------------------------------------------------------
// QARDL with a per-regressor lag vector.  Translates qardlX().
// ------------------------------------------------------------------
void _qardl_corex_estimate(real colvector yy, real matrix xx,
    real scalar ppp, real colvector qvec, real colvector tau,
    string scalar cov_type, real scalar hac_lags)
{
    real scalar nn, k0, ss, jj, neff, var1, sum_phi, cov_lags
    real scalar theta_start, phi_start, theta_end, phi_end
    real colvector hb, Y, bt1, alpha, rho, uu
    real matrix ONEX, bt, fh, midbt, midphi, midgam
    real matrix D_qr, D_inv_qr, full_cov, bigbtmm, bigpi, bigff

    nn = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)

    hb = J(ss, 1, 0)
    for (jj = 1; jj <= ss; jj++) {
        var1 = invnormal(tau[jj])
        hb[jj] = (4.5 * normalden(var1)^4 / (nn * (2*var1^2+1)^2))^0.2
    }

    ONEX = _qardl_design_qvec(yy, xx, ppp, qvec, Y, theta_start, phi_start)
    neff = rows(Y)

    theta_end = theta_start + k0 - 1
    phi_end   = phi_start + ppp - 1

    bt = J(cols(ONEX), ss, 0)
    fh = J(ss, 1, 0)

    for (jj = 1; jj <= ss; jj++) {
        bt1 = _qardl_qreg(Y, ONEX, tau[jj])
        uu = Y - ONEX * bt1
        fh[jj] = mean(normalden(-uu / hb[jj])) / hb[jj]
        bt[., jj] = bt1
    }

    midbt  = J(k0, ss, 0)
    midphi = J(ppp, ss, 0)
    midgam = J(k0, ss, 0)
    alpha  = J(ss, 1, 0)
    rho    = J(ss, 1, 0)

    for (jj = 1; jj <= ss; jj++) {
        sum_phi = colsum(bt[phi_start..phi_end, jj])
        midbt[., jj]  = bt[theta_start..theta_end, jj] / (1 - sum_phi)
        midphi[., jj] = bt[phi_start..phi_end, jj]
        midgam[., jj] = bt[theta_start..theta_end, jj]
        alpha[jj] = bt[1, jj]
        rho[jj]   = -(1 - sum_phi)
    }

    cov_lags = 0
    if (cov_type == "hac") {
        cov_lags = hac_lags
        if (cov_lags == 0) cov_lags = _qardl_hac_auto(neff)
    }

    D_qr     = ONEX' * ONEX / neff
    D_inv_qr = luinv(D_qr)
    full_cov = _qardl_qr_sandwich(ONEX, Y, bt, tau, fh, D_inv_qr, cov_lags)
    _qardl_levels_cov_pos(full_cov, bt, theta_start, phi_start, k0, ppp, ss,
                          bigbtmm, bigpi, bigff)

    st_matrix("_qardl_beta", vec(midbt))
    st_matrix("_qardl_beta_cov", bigbtmm)
    st_matrix("_qardl_phi", vec(midphi))
    st_matrix("_qardl_phi_cov", bigpi)
    st_matrix("_qardl_gamma", vec(midgam))
    st_matrix("_qardl_gamma_cov", bigff)
    st_matrix("_qardl_alpha", alpha)
    st_matrix("_qardl_rho", rho)
    st_matrix("_qardl_bt_raw", bt)
    st_matrix("_qardl_fh", fh)
    st_numscalar("_qardl_haclags_used", cov_lags)
    st_numscalar("_qardl_neff", neff)
}

end
