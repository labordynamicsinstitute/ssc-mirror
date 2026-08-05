*! _qardl_ecm2 v1.2.0 - GAUSS-style two-step QARDL-ECM
*! Translates qardlECM(..., ecm_type = "two-step") from GAUSS QARDL 3.1.1
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)
*!
*! This is a DIFFERENT object from _qardl_ecm.ado, which implements the
*! Cho (2022) MATLAB qardlecm.m parameterisation in terms of phi*(tau)
*! and theta(tau).  Here the ARDL long-run vector is estimated by OLS in
*! step one, the error-correction term is formed from it, and step two
*! runs a quantile regression of dy on [1, ECT(-1), dy lags, dx lags],
*! delivering alpha(tau) and the speed of adjustment rho(tau).

program define _qardl_ecm2, rclass
    version 14.0

    * Ensure the shared Mata routines are loaded
    capture mata which _qardl_qreg()
    if _rc {
        capture program drop _qardl_estimate
        qui findfile _qardl_estimate.ado
        qui run "`r(fn)'"
    }
    capture mata which _qardl_ic_design()
    if _rc {
        capture program drop _qardl_icmean
        qui findfile _qardl_icmean.ado
        qui run "`r(fn)'"
    }

    syntax varlist(min=2 numeric ts) [if] [in], P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) [COVariance(string) HAClags(integer 0)]

    marksample touse

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    if "`covariance'" == "" local covariance "iid"
    local covariance = lower("`covariance'")
    if !inlist("`covariance'", "iid", "robust", "hac") {
        di as error "covariance() must be iid, robust, or hac"
        exit 198
    }

    qui count if `touse'
    local nobs = r(N)

    qui putmata _e2_y = `depvar' if `touse', replace

    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _e2_X = (`mxvars') if `touse', replace

    mata: _e2_tau = strtoreal(tokens(st_local("tau")))'

    mata: _qardl_ecm2_estimate(_e2_y, _e2_X, `p', `q', _e2_tau, ///
        "`covariance'", `haclags')

    return matrix beta_lr = _qardl_e2_beta_lr
    return matrix alpha = _qardl_e2_alpha
    return matrix alpha_cov = _qardl_e2_alpha_cov
    return matrix rho = _qardl_e2_rho
    return matrix rho_cov = _qardl_e2_rho_cov
    return matrix bt_ecm = _qardl_e2_bt
    return scalar rho_ols = _qardl_e2_rho_ols
    return scalar N_ecm = _qardl_e2_nobs
    return scalar haclags_used = _qardl_e2_haclags
    return local covariance "`covariance'"
    return scalar p = `p'
    return scalar q = `q'
    return scalar k = `k'
end

capture mata: mata drop _qardl_ecm2_design()
capture mata: mata drop _qardl_ecm2_estimate()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// Build the two-step ECM design (Pesaran-Shin-Smith Case III:
// unrestricted intercept, no trend).  Translates
// _ardlBuildECMDesignX(..., ecm_type = "two-step", case_id = 3).
//
//   dy_t = alpha + rho*ECT_{t-1} + sum dy_{t-j} + sum dx_{t-j} + e_t
//   ECT_{t-1} = y_{t-1} - x_{t-1}'beta_lr
//
// Y is returned by reference; ONEX is the return value.
// ------------------------------------------------------------------
real matrix _qardl_ecm2_design(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector beta_lr,
    real colvector Y)
{
    real scalar nn, k0, T0, N, jj, ii, col_idx
    real matrix ONEX, dy_lags, dx_lags
    real colvector ec_lag

    nn = rows(yy)
    k0 = cols(xx)
    T0 = max((ppp, qqq))
    N  = nn - T0 - 1

    Y = yy[(T0+2)..nn] - yy[(T0+1)..(nn-1)]

    ec_lag = yy[(T0+1)..(nn-1)] - xx[(T0+1)..(nn-1), .] * beta_lr

    ONEX = (J(N, 1, 1), ec_lag)

    if (ppp > 1) {
        dy_lags = J(N, ppp-1, 0)
        for (jj = 1; jj <= ppp-1; jj++) {
            dy_lags[., jj] = yy[(T0+2-jj)..(nn-jj)] - yy[(T0+1-jj)..(nn-jj-1)]
        }
        ONEX = (ONEX, dy_lags)
    }

    if (qqq > 0) {
        dx_lags = J(N, qqq*k0, 0)
        col_idx = 1
        for (ii = 1; ii <= k0; ii++) {
            for (jj = 0; jj <= qqq-1; jj++) {
                dx_lags[., col_idx] = xx[(T0+2-jj)..(nn-jj), ii] -
                                      xx[(T0+1-jj)..(nn-jj-1), ii]
                col_idx++
            }
        }
        ONEX = (ONEX, dx_lags)
    }

    return(ONEX)
}

// ------------------------------------------------------------------
// Two-step QARDL-ECM.  Translates qardlECM() from GAUSS 3.1.1.
// ------------------------------------------------------------------
void _qardl_ecm2_estimate(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector tau,
    string scalar cov_type, real scalar hac_lags)
{
    real scalar nn, k0, ss, jj, ii, N_ecm, var1, cov_lags
    real scalar theta_start, theta_end, phi_start, phi_end, rho_ols
    real colvector hb, Y_ols, Y_ecm, bt_ols, beta_lr, fh_ecm, uu_ecm
    real colvector alpha, rho
    real matrix ONEX_ols, ONEX_ecm, bt_ecm, cc, D_ecm, D_inv_ecm
    real matrix alpha_cov, rho_cov, full_cov

    nn = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)

    // Bandwidth for the density estimates
    hb = J(ss, 1, 0)
    for (jj = 1; jj <= ss; jj++) {
        var1 = invnormal(tau[jj])
        hb[jj] = (4.5 * normalden(var1)^4 / (nn * (2*var1^2+1)^2))^0.2
    }

    // ---- Step 1: OLS ARDL on the levels design ----
    ONEX_ols = _qardl_ic_design(yy, xx, ppp, qqq, Y_ols)

    bt_ols = lusolve(cross(ONEX_ols, ONEX_ols), cross(ONEX_ols, Y_ols))

    theta_start = 2 + qqq * k0
    theta_end   = 1 + (qqq + 1) * k0
    phi_start   = 2 + (qqq + 1) * k0
    phi_end     = 1 + (qqq + 1) * k0 + ppp

    rho_ols = -(1 - colsum(bt_ols[phi_start..phi_end]))
    beta_lr = bt_ols[theta_start..theta_end] / (-rho_ols)

    // ---- Step 2: quantile regression of the ECM ----
    ONEX_ecm = _qardl_ecm2_design(yy, xx, ppp, qqq, beta_lr, Y_ecm)
    N_ecm    = rows(Y_ecm)

    bt_ecm = J(cols(ONEX_ecm), ss, 0)
    fh_ecm = J(ss, 1, 0)

    for (jj = 1; jj <= ss; jj++) {
        bt_ecm[., jj] = _qardl_qreg(Y_ecm, ONEX_ecm, tau[jj])
        uu_ecm = Y_ecm - ONEX_ecm * bt_ecm[., jj]
        fh_ecm[jj] = mean(normalden(-uu_ecm / hb[jj])) / hb[jj]
    }

    alpha = bt_ecm[1, .]'
    rho   = bt_ecm[2, .]'

    // ---- Asymptotic covariance ----
    cc = J(ss, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= ss; ii++) {
            cc[jj, ii] = (min((tau[jj], tau[ii])) - tau[jj]*tau[ii]) /
                         (fh_ecm[ii] * fh_ecm[jj])
        }
    }

    D_ecm     = ONEX_ecm' * ONEX_ecm / N_ecm
    D_inv_ecm = luinv(D_ecm)

    cov_lags = 0
    if (cov_type == "iid") {
        rho_cov   = cc * D_inv_ecm[2, 2] / N_ecm
        alpha_cov = cc * D_inv_ecm[1, 1] / N_ecm
    }
    else {
        if (cov_type == "hac") {
            cov_lags = hac_lags
            if (cov_lags == 0) cov_lags = _qardl_hac_auto(N_ecm)
        }

        full_cov = _qardl_qr_sandwich(ONEX_ecm, Y_ecm, bt_ecm, tau,
                                      fh_ecm, D_inv_ecm, cov_lags)

        alpha_cov = J(ss, ss, 0)
        rho_cov   = J(ss, ss, 0)
        for (ii = 1; ii <= ss; ii++) {
            for (jj = 1; jj <= ss; jj++) {
                alpha_cov[ii, jj] =
                    full_cov[(ii-1)*cols(ONEX_ecm)+1, (jj-1)*cols(ONEX_ecm)+1]
                rho_cov[ii, jj] =
                    full_cov[(ii-1)*cols(ONEX_ecm)+2, (jj-1)*cols(ONEX_ecm)+2]
            }
        }
    }

    st_matrix("_qardl_e2_beta_lr", beta_lr)
    st_matrix("_qardl_e2_alpha", alpha)
    st_matrix("_qardl_e2_alpha_cov", alpha_cov)
    st_matrix("_qardl_e2_rho", rho)
    st_matrix("_qardl_e2_rho_cov", rho_cov)
    st_matrix("_qardl_e2_bt", bt_ecm)
    st_numscalar("_qardl_e2_rho_ols", rho_ols)
    st_numscalar("_qardl_e2_nobs", N_ecm)
    st_numscalar("_qardl_e2_haclags", cov_lags)
}

end
