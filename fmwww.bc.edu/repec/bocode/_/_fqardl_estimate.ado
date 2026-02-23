*! _fqardl_estimate v1.0.0 — Core Fourier-QARDL(p,q) estimation engine
*! Extends Cho, Kim & Shin (2015) with Fourier trigonometric terms
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fqardl_estimate
program define _fqardl_estimate, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) KSTAR(real) [NOCONStant]

    marksample touse

    * Parse variables
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    qui count if `touse'
    local nobs = r(N)

    * Put data into Mata
    qui putmata _fqardl_y = `depvar' if `touse', replace

    local mxvars ""
    local vi = 0
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _fqardl_X = (`mxvars') if `touse', replace

    * Build Fourier terms in Mata
    if `kstar' > 0 {
        tempvar _ft_sin _ft_cos _ft_trend
        qui gen double `_ft_trend' = _n if `touse'
        qui gen double `_ft_sin' = sin(2 * c(pi) * `kstar' * `_ft_trend' / `nobs') if `touse'
        qui gen double `_ft_cos' = cos(2 * c(pi) * `kstar' * `_ft_trend' / `nobs') if `touse'
        qui putmata _fqardl_Fsin = `_ft_sin' if `touse', replace
        qui putmata _fqardl_Fcos = `_ft_cos' if `touse', replace
    }
    else {
        mata: _fqardl_Fsin = J(0, 1, .)
        mata: _fqardl_Fcos = J(0, 1, .)
    }

    * Build tau vector
    mata: _fqardl_tau = strtoreal(tokens(st_local("tau")))'

    * Run estimation in Mata
    mata: _fqardl_core_estimate(_fqardl_y, _fqardl_X, `p', `q', ///
        _fqardl_tau, `kstar', _fqardl_Fsin, _fqardl_Fcos)

    * Return results
    return matrix beta = _fqardl_beta
    return matrix beta_cov = _fqardl_beta_cov
    return matrix phi = _fqardl_phi
    return matrix phi_cov = _fqardl_phi_cov
    return matrix gamma = _fqardl_gamma
    return matrix gamma_cov = _fqardl_gamma_cov
    return matrix bt_raw = _fqardl_bt_raw
    return matrix bt_se = _fqardl_bt_se
    return matrix fh_vec = _fqardl_fh
    return scalar p = `p'
    return scalar q = `q'
    return scalar k = `k'
    return scalar kstar = `kstar'
    return scalar N = `nobs'
end

* ============================================================
* Mata: IRLS Quantile Regression
* ============================================================
capture mata: mata drop _fqardl_qreg()
capture mata: mata drop _fqardl_qreg_irls()
capture mata: mata drop _fqardl_core_estimate()

mata:
mata set matastrict off

// IRLS quantile regression — robust implementation
real colvector _fqardl_qreg(real colvector y, real matrix x, real scalar tau)
{
    return(_fqardl_qreg_irls(y, x, tau))
}

real colvector _fqardl_qreg_irls(real colvector y, real matrix x,
    real scalar tau)
{
    real scalar n, m, iter, maxiter, tol, converged
    real colvector beta, beta_old, resid, w
    real matrix xwx

    n = rows(y)
    m = cols(x)
    maxiter = 300
    tol = 1e-8

    // Initialize with OLS
    beta = lusolve(cross(x, x) + 1e-10*I(m), cross(x, y))

    converged = 0
    for (iter = 1; iter <= maxiter; iter++) {
        beta_old = beta
        resid = y - x * beta

        // IRLS weights
        w = J(n, 1, 0)
        for (i = 1; i <= n; i++) {
            if (abs(resid[i]) < 1e-10) {
                w[i] = 1 / (2 * 1e-10)
            }
            else if (resid[i] > 0) {
                w[i] = tau / abs(resid[i])
            }
            else {
                w[i] = (1 - tau) / abs(resid[i])
            }
        }

        // Weighted least squares
        xwx = cross(x, w, x)
        if (det(xwx) == 0) {
            xwx = xwx + 1e-8 * I(m)
        }
        beta = lusolve(xwx, cross(x, w, y))

        if (max(abs(beta - beta_old)) < tol) {
            converged = 1
            break
        }
    }

    return(beta)
}

// ============================================================
// Main Fourier-QARDL estimation
// Extends QARDL (Cho, Kim & Shin 2015) with Fourier terms
// ============================================================
void _fqardl_core_estimate(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector tau,
    real scalar kstar, real colvector Fsin, real colvector Fcos)
{
    real scalar nn, k0, ss, jj, ii, i, nfourier
    real colvector hb, hs, za_val
    real matrix ee, eei, xxi, yyi, X_mat, ONEX, Y_vec
    real matrix bt, fh, uu
    real matrix barw, tw, mm, bb, qq_mat, midbt, bigbt, bigbtmm
    real matrix kk, kkk_vec, bbt, tilw, lll, cc, bigpi, midphi, bigphi
    real matrix midgam, bigam, bilam, bigff
    real colvector bt1, psu
    real scalar var1, var2

    nn = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)
    nfourier = (kstar > 0 ? 2 : 0)

    // Bandwidth parameters (Bofinger)
    za_val = invnormal(0.975)
    hb = J(ss, 1, 0)
    hs = J(ss, 1, 0)

    for (jj = 1; jj <= ss; jj++) {
        var1 = invnormal(tau[jj])
        hb[jj] = (4.5 * normalden(var1)^4 / (nn * (2*var1^2+1)^2))^0.2
        hs[jj] = za_val^(2/3) * (1.5 * normalden(var1)^2 / (nn * (2*var1^2+1)))^(1/3)
    }

    // First differences of x
    ee = xx[2..nn, .] - xx[1..nn-1, .]
    ee = J(1, k0, 0) \ ee

    // Build lagged differences matrix
    eei = J(nn - qqq, qqq * k0, 0)
    xxi = xx[qqq+1..nn, .]
    yyi = J(nn - ppp, ppp, 0)

    // Lagged differences of independent variables
    for (jj = 1; jj <= k0; jj++) {
        for (ii = 0; ii <= qqq-1; ii++) {
            eei[., ii+1+(jj-1)*qqq] = ee[qqq+1-ii..nn-ii, jj]
        }
    }

    // Lagged dependent variable
    for (ii = 1; ii <= ppp; ii++) {
        yyi[., ii] = yy[1+ppp-ii..nn-ii]
    }

    // Build regressor matrix
    if (ppp > qqq) {
        X_mat = (eei[rows(eei)+1-rows(yyi)..rows(eei), .],
                 xxi[rows(xxi)+1-rows(yyi)..rows(xxi), .],
                 yyi)
    }
    else {
        X_mat = (eei,
                 xxi,
                 yyi[rows(yyi)+1-rows(xxi)..rows(yyi), .])
    }

    // Add Fourier terms if k* > 0
    real scalar neff_start
    neff_start = nn - rows(X_mat) + 1

    if (nfourier > 0) {
        real matrix Fblock
        Fblock = (Fsin[neff_start..nn], Fcos[neff_start..nn])
        X_mat = (X_mat, Fblock)
    }

    // Add constant
    ONEX = (J(rows(X_mat), 1, 1), X_mat)
    Y_vec = yy[neff_start..nn]

    // Quantile regression for each tau
    real scalar ncols_onex
    ncols_onex = cols(ONEX)
    bt = J(ncols_onex, ss, 0)
    fh = J(ss, 1, 0)

    for (jj = 1; jj <= ss; jj++) {
        bt1 = _fqardl_qreg(Y_vec, ONEX, tau[jj])
        uu = Y_vec - ONEX * bt1
        fh[jj] = mean(normalden(-uu / hb[jj])) / hb[jj]
        bt[., jj] = bt1
    }

    // ============================================================
    // Long-run parameter beta: beta_j = gamma_j / (1 - sum(phi))
    // ============================================================
    barw = J(nn-1, qqq*k0, 0)
    for (jj = 1; jj <= qqq; jj++) {
        barw[jj..nn-1, k0*(jj-1)+1..k0*jj] = ee[2..nn-jj+1, .]
    }

    tw = (J(nn-1, 1, 1), barw)

    // M matrix for beta covariance
    mm = (xxi' * xxi - xxi' * tw[qqq..nn-1, .] *
         luinv(tw[qqq..nn-1, .]' * tw[qqq..nn-1, .]) *
         tw[qqq..nn-1, .]' * xxi) / (nn - qqq)^2

    // bb = 1/((1-sum(phi))*f)
    // phi indices in bt: from row 2+(qqq+1)*k0 to 1+(qqq+1)*k0+ppp
    // (Fourier terms come after phi, so phi position is unchanged)
    bb = J(ss, 1, 0)
    for (jj = 1; jj <= ss; jj++) {
        real scalar sum_phi
        sum_phi = 0
        for (i = 2+(qqq+1)*k0; i <= 1+(qqq+1)*k0+ppp; i++) {
            sum_phi = sum_phi + bt[i, jj]
        }
        bb[jj] = 1 / ((1 - sum_phi) * fh[jj])
    }

    // Omega matrix
    qq_mat = J(ss, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= ss; ii++) {
            qq_mat[jj, ii] = (min((tau[jj], tau[ii])) - tau[jj]*tau[ii]) *
                             bb[jj] * bb[ii]
        }
    }

    // Long-run parameters
    midbt = J(k0, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        real scalar denom
        denom = 0
        for (i = 2+(qqq+1)*k0; i <= 1+(qqq+1)*k0+ppp; i++) {
            denom = denom + bt[i, jj]
        }
        midbt[., jj] = bt[2+qqq*k0..1+(qqq+1)*k0, jj] / (1 - denom)
    }
    bigbt = vec(midbt)
    bigbtmm = qq_mat # luinv(mm)

    // ============================================================
    // Short-run AR parameters: phi
    // ============================================================
    real matrix yyj, xxj, wwj
    real scalar neff

    if (ppp > qqq) {
        neff = nn - ppp
        yyj = J(neff, ppp, 0)
        wwj = J(neff, qqq*k0, 0)

        for (jj = 1; jj <= ppp; jj++) {
            yyj[., jj] = yy[ppp+1-jj..nn-jj]
        }

        for (ii = 1; ii <= k0; ii++) {
            for (jj = 1; jj <= qqq; jj++) {
                wwj[., jj+(ii-1)*qqq] = ee[ppp-jj+2..nn-jj+1, ii]
            }
        }

        xxj = xx[ppp+1..nn, .]
        kk = J(neff, ss*ppp, 0)

        // Add Fourier to auxiliary regression
        real matrix aux_ONEX
        if (nfourier > 0) {
            aux_ONEX = (J(neff, 1, 1), xxj, wwj,
                        Fsin[ppp+1..nn], Fcos[ppp+1..nn])
        }
        else {
            aux_ONEX = (J(neff, 1, 1), xxj, wwj)
        }

        for (jj = 1; jj <= ppp; jj++) {
            Y_vec = yyj[., jj]
            for (ii = 1; ii <= ss; ii++) {
                bbt = _fqardl_qreg(Y_vec, aux_ONEX, tau[ii])
                kkk_vec = Y_vec - aux_ONEX * bbt
                kk[., jj+(ii-1)*ppp] = kkk_vec
            }
        }
        tilw = tw[ppp..nn-1, .]
        lll = (kk' * kk - kk' * tilw * luinv(tilw' * tilw) * tilw' * kk) / neff
    }
    else {
        neff = nn - qqq
        yyj = J(neff, ppp, 0)
        wwj = J(neff, qqq*k0, 0)

        for (jj = 1; jj <= ppp; jj++) {
            yyj[., jj] = yy[qqq+1-jj..nn-jj]
        }

        for (ii = 1; ii <= k0; ii++) {
            for (jj = 1; jj <= qqq; jj++) {
                wwj[., jj+(ii-1)*qqq] = ee[qqq-jj+2..nn-jj+1, ii]
            }
        }

        xxj = xx[qqq+1..nn, .]
        kk = J(neff, ss*ppp, 0)

        if (nfourier > 0) {
            aux_ONEX = (J(neff, 1, 1), xxj, wwj,
                        Fsin[qqq+1..nn], Fcos[qqq+1..nn])
        }
        else {
            aux_ONEX = (J(neff, 1, 1), xxj, wwj)
        }

        for (jj = 1; jj <= ppp; jj++) {
            Y_vec = yyj[., jj]
            for (ii = 1; ii <= ss; ii++) {
                bbt = _fqardl_qreg(Y_vec, aux_ONEX, tau[ii])
                kkk_vec = Y_vec - aux_ONEX * bbt
                kk[., jj+(ii-1)*ppp] = kkk_vec
            }
        }
        tilw = tw[qqq..nn-1, .]
        lll = (kk' * kk - kk' * tilw * luinv(tilw' * tilw) * tilw' * kk) / neff
    }

    // C matrix for phi covariance
    cc = J(ss, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= ss; ii++) {
            cc[jj, ii] = (min((tau[jj], tau[ii])) - tau[jj]*tau[ii]) /
                         (fh[ii] * fh[jj])
        }
    }

    // Big Pi (phi covariance)
    bigpi = J(ss*ppp, ss*ppp, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= ss; ii++) {
            real matrix psu_mat, lll_jj, lll_ji, lll_ii
            lll_jj = lll[(jj-1)*ppp+1..jj*ppp, (jj-1)*ppp+1..jj*ppp]
            lll_ji = lll[(jj-1)*ppp+1..jj*ppp, (ii-1)*ppp+1..ii*ppp]
            lll_ii = lll[(ii-1)*ppp+1..ii*ppp, (ii-1)*ppp+1..ii*ppp]
            psu_mat = luinv(lll_jj) * lll_ji * luinv(lll_ii)
            bigpi[(jj-1)*ppp+1..jj*ppp, (ii-1)*ppp+1..ii*ppp] = cc[jj,ii] * psu_mat
        }
    }

    // Phi parameters
    midphi = J(ppp, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        midphi[., jj] = bt[2+(qqq+1)*k0..1+(qqq+1)*k0+ppp, jj]
    }
    bigphi = vec(midphi)

    // Gamma parameters
    midgam = J(k0, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        midgam[., jj] = bt[2+qqq*k0..1+(qqq+1)*k0, jj]
    }
    bigam = vec(midgam)

    bilam = J(k0*ss, ss*ppp, 0)
    for (jj = 1; jj <= ss; jj++) {
        bilam[(jj-1)*k0+1..jj*k0, (jj-1)*ppp+1..jj*ppp] =
            midbt[., jj] * J(1, ppp, 1)
    }
    bigff = bilam * bigpi * bilam'

    // ============================================================
    // Raw standard errors for ALL coefficients at each tau
    // SE_j(tau) = sqrt( tau*(1-tau) / f_hat^2 * [(X'X)^-1]_jj )
    // ============================================================
    real matrix bt_se, XXinv
    bt_se = J(ncols_onex, ss, 0)
    XXinv = luinv(cross(ONEX, ONEX))
    if (det(cross(ONEX, ONEX)) == 0) {
        XXinv = luinv(cross(ONEX, ONEX) + 1e-8*I(ncols_onex))
    }

    for (jj = 1; jj <= ss; jj++) {
        real scalar qr_var_scale
        qr_var_scale = tau[jj] * (1 - tau[jj]) / (fh[jj]^2)
        for (i = 1; i <= ncols_onex; i++) {
            bt_se[i, jj] = sqrt(qr_var_scale * XXinv[i, i])
        }
    }

    // Store results in Stata matrices
    st_matrix("_fqardl_beta", bigbt)
    st_matrix("_fqardl_beta_cov", bigbtmm)
    st_matrix("_fqardl_phi", bigphi)
    st_matrix("_fqardl_phi_cov", bigpi)
    st_matrix("_fqardl_gamma", bigam)
    st_matrix("_fqardl_gamma_cov", bigff)
    st_matrix("_fqardl_bt_raw", bt)
    st_matrix("_fqardl_bt_se", bt_se)
    st_matrix("_fqardl_fh", fh)
}

end
