*! _fqardl_ecm v1.0.0 — Fourier-QARDL Error Correction Model estimation
*! Extends QARDL-ECM (Cho, Kim & Shin 2015) with Fourier trigonometric terms
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

capture program drop _fqardl_ecm
program define _fqardl_ecm, rclass
    version 14.0

    * Ensure core Mata function is available
    capture mata: mata which _fqardl_qreg()
    if _rc {
        capture program drop _fqardl_estimate
        qui findfile _fqardl_estimate.ado
        qui run "`r(fn)'"
    }

    syntax varlist(min=2 numeric ts) [if] [in], P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) KSTAR(real) [NOCONStant]

    marksample touse

    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    qui count if `touse'
    local nobs = r(N)

    * First run standard Fourier-QARDL
    _fqardl_estimate `varlist' if `touse', p(`p') q(`q') ///
        tau(`tau') kstar(`kstar') `noconstant'

    tempname beta beta_cov phi phi_cov gamma gamma_cov bt_raw bt_se fh_vec
    mat `beta' = r(beta)
    mat `beta_cov' = r(beta_cov)
    mat `phi' = r(phi)
    mat `phi_cov' = r(phi_cov)
    mat `gamma' = r(gamma)
    mat `gamma_cov' = r(gamma_cov)
    mat `bt_raw' = r(bt_raw)
    mat `bt_se' = r(bt_se)
    mat `fh_vec' = r(fh_vec)

    * Put data into Mata for ECM computation
    qui putmata _ecm_y = `depvar' if `touse', replace

    local vi = 0
    local mxvars ""
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }
    qui putmata _ecm_X = (`mxvars') if `touse', replace

    * Fourier terms
    if `kstar' > 0 {
        tempvar _ft_sin _ft_cos _ft_trend
        qui gen double `_ft_trend' = _n if `touse'
        qui gen double `_ft_sin' = sin(2 * c(pi) * `kstar' * `_ft_trend' / `nobs') if `touse'
        qui gen double `_ft_cos' = cos(2 * c(pi) * `kstar' * `_ft_trend' / `nobs') if `touse'
        qui putmata _ecm_Fsin = `_ft_sin' if `touse', replace
        qui putmata _ecm_Fcos = `_ft_cos' if `touse', replace
    }
    else {
        mata: _ecm_Fsin = J(0, 1, .)
        mata: _ecm_Fcos = J(0, 1, .)
    }

    mata: _ecm_tau = strtoreal(tokens(st_local("tau")))'

    * Run ECM estimation in Mata
    mata: _fqardl_ecm_estimate(_ecm_y, _ecm_X, `p', `q', ///
        _ecm_tau, `kstar', _ecm_Fsin, _ecm_Fcos)

    * Return all results
    return matrix beta = `beta'
    return matrix beta_cov = `beta_cov'
    return matrix phi = `phi'
    return matrix phi_cov = `phi_cov'
    return matrix gamma = `gamma'
    return matrix gamma_cov = `gamma_cov'
    return matrix phi_ecm = _fqardl_phi_ecm
    return matrix phi_ecm_cov = _fqardl_phi_ecm_cov
    return matrix theta = _fqardl_theta
    return matrix theta_cov = _fqardl_theta_cov
    return matrix bt_raw = `bt_raw'
    return matrix bt_se = `bt_se'
    return matrix fh_vec = `fh_vec'
    return scalar p = `p'
    return scalar q = `q'
    return scalar k = `k'
    return scalar kstar = `kstar'
    return scalar N = `nobs'
end

capture mata: mata drop _fqardl_ecm_estimate()

mata:
mata set matastrict off

void _fqardl_ecm_estimate(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector tau,
    real scalar kstar, real colvector Fsin, real colvector Fcos)
{
    real scalar nn, k0, ss, jj, ii, i, rr, neff, nfourier
    real colvector hb, hs, bt1
    real matrix ee, eei, xxi, yyi, X_mat, ONEX, Y_vec
    real matrix bt, fh, uu, barw, tw, mm, bb, qq_mat
    real matrix midbt, midphi
    real matrix kk, kkk_vec, bbt, kka, tilw, llla, cc
    real matrix bigpib, bigphi_vec, dd1, bigphia, bigpia, R1, A, A1, A2
    real matrix gg, gg1, gg2, dg, uu2, barw1, QQQ, psiu, sigmma, distmt
    real matrix distmt1, distmt2, distmt3, thett1, thett2, thett3, thett4
    real matrix thett34, thett345, thett, distthett
    real scalar var1, sum_phi

    nn = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)
    nfourier = (kstar > 0 ? 2 : 0)

    // Bandwidth
    hb = J(ss, 1, 0)
    hs = J(ss, 1, 0)
    for (jj = 1; jj <= ss; jj++) {
        var1 = invnormal(tau[jj])
        hb[jj] = (4.5 * normalden(var1)^4 / (nn*(2*var1^2+1)^2))^0.2
        hs[jj] = invnormal(0.975)^(2/3) * (1.5*normalden(var1)^2 / (nn*(2*var1^2+1)))^(1/3)
    }

    // Data construction
    ee = xx[2..nn, .] - xx[1..nn-1, .]
    ee = J(1, k0, 0) \ ee

    eei = J(nn-qqq, qqq*k0, 0)
    xxi = xx[qqq+1..nn, .]
    yyi = J(nn-ppp, ppp, 0)

    for (jj = 1; jj <= k0; jj++) {
        for (ii = 0; ii <= qqq-1; ii++) {
            eei[., ii+1+(jj-1)*qqq] = ee[qqq+1-ii..nn-ii, jj]
        }
    }
    for (ii = 1; ii <= ppp; ii++) {
        yyi[., ii] = yy[1+ppp-ii..nn-ii]
    }

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

    real scalar neff_start
    neff_start = nn - rows(X_mat) + 1

    // Add Fourier terms
    if (nfourier > 0) {
        X_mat = (X_mat, Fsin[neff_start..nn], Fcos[neff_start..nn])
    }

    ONEX = (J(rows(X_mat), 1, 1), X_mat)
    Y_vec = yy[neff_start..nn]

    // Quantile regression
    bt = J(cols(ONEX), ss, 0)
    fh = J(ss, 1, 0)

    if (ppp > qqq) {
        uu = J(nn-ppp, ss, 0)
    }
    else {
        uu = J(nn-qqq, ss, 0)
    }

    for (jj = 1; jj <= ss; jj++) {
        bt1 = _fqardl_qreg(Y_vec, ONEX, tau[jj])
        uu[., jj] = Y_vec - ONEX * bt1
        fh[jj] = mean(normalden(-uu[., jj] / hb[jj])) / hb[jj]
        bt[., jj] = bt1
    }

    // barw and tw
    barw = J(nn-1, qqq*k0, 0)
    for (jj = 1; jj <= qqq; jj++) {
        barw[jj..nn-1, k0*(jj-1)+1..k0*jj] = ee[2..nn-jj+1, .]
    }
    tw = (J(nn-1, 1, 1), barw)

    // phi coefficients for ECM
    real matrix xxj_ecm
    if (ppp > qqq) {
        neff = nn - ppp
        real matrix yyj_ecm, wwj_ecm
        yyj_ecm = J(neff, ppp, 0)
        wwj_ecm = J(neff, qqq*k0, 0)

        for (jj = 1; jj <= ppp; jj++) {
            yyj_ecm[., jj] = yy[ppp+1-jj..nn-jj]
        }
        for (ii = 1; ii <= k0; ii++) {
            for (jj = 1; jj <= qqq; jj++) {
                wwj_ecm[., jj+(ii-1)*qqq] = ee[ppp-jj+2..nn-jj+1, ii]
            }
        }
        xxj_ecm = xx[ppp+1..nn, .]
        kk = J(neff, ss*ppp, 0)

        real matrix aux_ONEX_ecm
        if (nfourier > 0) {
            aux_ONEX_ecm = (J(neff, 1, 1), xxj_ecm, wwj_ecm,
                            Fsin[ppp+1..nn], Fcos[ppp+1..nn])
        }
        else {
            aux_ONEX_ecm = (J(neff, 1, 1), xxj_ecm, wwj_ecm)
        }

        for (jj = 1; jj <= ppp; jj++) {
            Y_vec = yyj_ecm[., jj]
            for (ii = 1; ii <= ss; ii++) {
                bbt = _fqardl_qreg(Y_vec, aux_ONEX_ecm, tau[ii])
                kkk_vec = Y_vec - aux_ONEX_ecm * bbt
                kk[., jj+(ii-1)*ppp] = kkk_vec
            }
        }
    }
    else {
        neff = nn - qqq
        real matrix yyj_e2, wwj_e2
        yyj_e2 = J(neff, ppp, 0)
        wwj_e2 = J(neff, qqq*k0, 0)

        for (jj = 1; jj <= ppp; jj++) {
            yyj_e2[., jj] = yy[qqq+1-jj..nn-jj]
        }
        for (ii = 1; ii <= k0; ii++) {
            for (jj = 1; jj <= qqq; jj++) {
                wwj_e2[., jj+(ii-1)*qqq] = ee[qqq-jj+2..nn-jj+1, ii]
            }
        }
        xxj_ecm = xx[qqq+1..nn, .]
        kk = J(neff, ss*ppp, 0)

        if (nfourier > 0) {
            aux_ONEX_ecm = (J(neff, 1, 1), xxj_ecm, wwj_e2,
                            Fsin[qqq+1..nn], Fcos[qqq+1..nn])
        }
        else {
            aux_ONEX_ecm = (J(neff, 1, 1), xxj_ecm, wwj_e2)
        }

        for (jj = 1; jj <= ppp; jj++) {
            Y_vec = yyj_e2[., jj]
            for (ii = 1; ii <= ss; ii++) {
                bbt = _fqardl_qreg(Y_vec, aux_ONEX_ecm, tau[ii])
                kkk_vec = Y_vec - aux_ONEX_ecm * bbt
                kk[., jj+(ii-1)*ppp] = kkk_vec
            }
        }
    }

    // Remove first column of each tau block for ECM
    real colvector dd_idx
    dd_idx = J(ss, 1, 0)
    dd_idx[1] = 1
    for (jj = 2; jj <= ss; jj++) {
        dd_idx[jj] = 1 + ppp*(jj-1)
    }

    real scalar ncols_kk, ncols_kka, col_keep, is_remove
    ncols_kk = cols(kk)
    ncols_kka = ncols_kk - ss
    kka = J(rows(kk), ncols_kka, 0)
    col_keep = 0
    for (jj = 1; jj <= ncols_kk; jj++) {
        is_remove = 0
        for (ii = 1; ii <= ss; ii++) {
            if (jj == dd_idx[ii]) is_remove = 1
        }
        if (!is_remove) {
            col_keep++
            kka[., col_keep] = kk[., jj]
        }
    }

    if (ppp > qqq) {
        tilw = tw[ppp..nn-1, .]
        llla = (kka' * kka - kka' * tilw * luinv(tilw' * tilw) * tilw' * kka) / neff
    }
    else {
        tilw = tw[qqq..nn-1, .]
        llla = (kka' * kka - kka' * tilw * luinv(tilw' * tilw) * tilw' * kka) / neff
    }

    // C matrix
    cc = J(ss, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= ss; ii++) {
            cc[jj, ii] = (min((tau[jj], tau[ii])) - tau[jj]*tau[ii]) / (fh[ii]*fh[jj])
        }
    }

    // Big Pi for ECM phi (p-1 dimensional)
    real scalar pp1
    pp1 = ppp - 1
    if (pp1 < 1) pp1 = 1

    bigpib = J(ss*pp1, ss*pp1, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= ss; ii++) {
            real matrix llla_jj, llla_ji, llla_ii, psu_mat
            llla_jj = llla[(jj-1)*pp1+1..jj*pp1, (jj-1)*pp1+1..jj*pp1]
            llla_ji = llla[(jj-1)*pp1+1..jj*pp1, (ii-1)*pp1+1..ii*pp1]
            llla_ii = llla[(ii-1)*pp1+1..ii*pp1, (ii-1)*pp1+1..ii*pp1]
            psu_mat = luinv(llla_jj) * llla_ji * luinv(llla_ii)
            bigpib[(jj-1)*pp1+1..jj*pp1, (ii-1)*pp1+1..ii*pp1] = cc[jj,ii] * psu_mat
        }
    }

    // Extract phi and reparameterize for ECM
    midphi = J(ppp, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        midphi[., jj] = bt[2+(qqq+1)*k0..1+(qqq+1)*k0+ppp, jj]
    }
    bigphi_vec = vec(midphi)

    // Remove first element per quantile block
    real colvector bigphi_ecm
    real scalar nkeep
    nkeep = rows(bigphi_vec) - ss
    bigphi_ecm = J(nkeep, 1, 0)
    col_keep = 0
    for (jj = 1; jj <= rows(bigphi_vec); jj++) {
        is_remove = 0
        for (ii = 1; ii <= ss; ii++) {
            if (jj == dd_idx[ii]) is_remove = 1
        }
        if (!is_remove) {
            col_keep++
            bigphi_ecm[col_keep] = bigphi_vec[jj]
        }
    }

    // Upper triangular cumulative sum transformation
    A = J(pp1, pp1, 0)
    for (i = 1; i <= pp1; i++) {
        for (jj = i; jj <= pp1; jj++) {
            A[i, jj] = 1
        }
    }
    A1 = A
    A2 = I(ss)
    R1 = A2 # A1

    bigphia = -R1 * bigphi_ecm
    bigpia = R1 * bigpib * R1'

    // Theta computation
    if (ppp > qqq) {
        gg1 = J(1+qqq*k0, 1, sqrt(neff))
        gg2 = J(k0, 1, neff)
    }
    else {
        gg1 = J(1+qqq*k0, 1, sqrt(neff))
        gg2 = J(k0, 1, neff)
    }
    gg = gg1 \ gg2
    dg = diag(gg)

    uu2 = uu

    if (ppp > qqq) {
        barw1 = barw[ppp..nn-1, .]
    }
    else {
        barw1 = barw[qqq..nn-1, .]
    }

    // Q matrix
    real scalar r1
    real rowvector r2, r3
    real matrix r5, r6, r9

    r1 = 1
    r2 = colsum(barw1) / neff
    r3 = colsum(xxj_ecm) / neff^(3/2)
    r5 = barw1' * barw1 / neff
    r6 = barw1' * xxj_ecm / neff^(3/2)
    r9 = xxj_ecm' * xxj_ecm / neff^2

    QQQ = (r1, r2, r3 \ r2', r5, r6 \ r3', r6', r9)

    // Psi matrix
    psiu = J(neff, ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (rr = 1; rr <= neff; rr++) {
            if (uu2[rr, jj] <= 0) {
                psiu[rr, jj] = tau[jj] - 1
            }
            else {
                psiu[rr, jj] = tau[jj]
            }
        }
    }

    sigmma = psiu' * psiu / neff

    // Distribution matrix
    real scalar dim1
    dim1 = 1 + k0*qqq + k0
    distmt = J(ss*dim1, ss*dim1, 0)

    for (ii = 1; ii <= ss; ii++) {
        for (jj = 1; jj <= ss; jj++) {
            distmt[(ii-1)*dim1+1..ii*dim1, (jj-1)*dim1+1..jj*dim1] =
                neff * fh[ii]^(-1) * fh[jj]^(-1) * sigmma[ii,jj] *
                luinv(dg) * luinv(QQQ) * luinv(dg)
        }
    }

    // Extract distmt blocks for theta covariance
    distmt1 = J(ss*qqq*k0, ss*qqq*k0, 0)
    distmt2 = J(ss*qqq*k0, ss*qqq*k0, 0)
    distmt3 = J(ss*qqq*k0, ss*qqq*k0, 0)

    for (ii = 1; ii <= ss; ii++) {
        for (jj = 1; jj <= ss; jj++) {
            distmt1[(ii-1)*qqq*k0+1..(ii-1)*qqq*k0+k0*qqq,
                    (jj-1)*qqq*k0+1..(jj-1)*qqq*k0+k0*qqq] =
                distmt[2+(ii-1)*dim1..qqq*k0+1+(ii-1)*dim1,
                       2+(jj-1)*dim1..qqq*k0+1+(jj-1)*dim1]

            real matrix A00, A01, A02
            A00 = distmt[qqq*k0+2+(ii-1)*dim1..1+qqq*k0+k0+(ii-1)*dim1,
                        qqq*k0+2+(jj-1)*dim1..1+qqq*k0+k0+(jj-1)*dim1]
            A01 = J(k0*(qqq-1), k0*(qqq-1), 0)
            A02 = J(k0, k0*(qqq-1), 0)
            distmt3[(ii-1)*qqq*k0+1..(ii-1)*qqq*k0+k0*qqq,
                    (jj-1)*qqq*k0+1..(jj-1)*qqq*k0+k0*qqq] =
                (A00, A02 \ A02', A01)

            real matrix B01, B02, B03
            B01 = J(k0*(qqq-1), k0*(qqq-1), 0)
            if (qqq > 1) {
                B02 = distmt[k0+2+(ii-1)*dim1..qqq*k0+1+(ii-1)*dim1,
                            qqq*k0+2+(jj-1)*dim1..1+qqq*k0+k0+(jj-1)*dim1]
            }
            else {
                B02 = J(0, k0, 0)
            }
            B03 = distmt[2+(ii-1)*dim1..k0+1+(ii-1)*dim1,
                        qqq*k0+2+(jj-1)*dim1..qqq*k0+1+k0+(jj-1)*dim1]
            if (qqq > 1) {
                distmt2[(ii-1)*qqq*k0+1..(ii-1)*qqq*k0+k0*qqq,
                        (jj-1)*qqq*k0+1..(jj-1)*qqq*k0+k0*qqq] =
                    (B03, B02' \ B02, B01)
            }
            else {
                distmt2[(ii-1)*qqq*k0+1..(ii-1)*qqq*k0+k0*qqq,
                        (jj-1)*qqq*k0+1..(jj-1)*qqq*k0+k0*qqq] = B03
            }
        }
    }

    distthett = distmt1 + distmt3 + 2*distmt2

    // Theta parameters
    thett1 = J(k0*(qqq+1), ss, 0)
    for (jj = 1; jj <= ss; jj++) {
        for (ii = 1; ii <= k0*(qqq+1); ii++) {
            thett1[ii, jj] = bt[1+ii, jj]
        }
    }

    thett2 = J(k0*qqq*ss, 1, 0)
    for (jj = 1; jj <= ss; jj++) {
        thett2[k0*qqq*(jj-1)+1..k0*qqq*jj] = thett1[1..k0*qqq, jj]
    }

    thett3 = thett1[k0*qqq+1..k0*qqq+k0, 1..ss]
    thett4 = J(k0*(qqq-1), ss, 0)
    thett34 = thett3 \ thett4

    thett345 = J(k0*qqq*ss, 1, 0)
    for (ii = 1; ii <= ss; ii++) {
        thett345[1+(k0*qqq)*(ii-1)..(k0*qqq)*ii] = thett34[., ii]
    }

    thett = thett2 + thett345

    // Store ECM results
    st_matrix("_fqardl_phi_ecm", bigphia)
    st_matrix("_fqardl_phi_ecm_cov", bigpia)
    st_matrix("_fqardl_theta", thett)
    st_matrix("_fqardl_theta_cov", distthett)
}

end
