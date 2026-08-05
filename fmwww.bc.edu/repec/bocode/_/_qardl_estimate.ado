*! _qardl_estimate v1.2.0 - Core QARDL(p,q) estimation engine
*! Translates qardl.m (MATLAB) and qardl.src (GAUSS QARDL 3.1.1)
*! Author: Dr Merwan Roudane (merwanroudane920@gmail.com)

program define _qardl_estimate, rclass
    version 14.0

    syntax varlist(min=2 numeric ts) [if] [in], P(integer) Q(integer) ///
        TAU(numlist >0 <1 sort) [NOCONStant COVariance(string) HAClags(integer 0)]

    marksample touse

    * Parse variables
    gettoken depvar indepvars : varlist
    local k : word count `indepvars'

    * Covariance type
    if "`covariance'" == "" local covariance "iid"
    local covariance = lower("`covariance'")
    if !inlist("`covariance'", "iid", "robust", "hac") {
        di as error "covariance() must be iid, robust, or hac"
        exit 198
    }
    if `haclags' < 0 {
        di as error "haclags() must be non-negative"
        exit 198
    }

    * Count obs
    qui count if `touse'
    local nobs = r(N)

    * Build data matrix: depvar ~ indepvars
    qui putmata _qardl_y = `depvar' if `touse', replace

    local mxvars ""
    local vi = 0
    foreach v of local indepvars {
        local ++vi
        tempvar xv`vi'
        qui gen double `xv`vi'' = `v' if `touse'
        local mxvars `mxvars' `xv`vi''
    }

    qui putmata _qardl_X = (`mxvars') if `touse', replace

    * Build tau vector
    mata: _qardl_tau = strtoreal(tokens(st_local("tau")))'

    * Run estimation in Mata
    mata: _qardl_core_estimate(_qardl_y, _qardl_X, `p', `q', _qardl_tau, ///
        "`covariance'", `haclags')

    * Return results (set by Mata)
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
    return scalar scale_beta = _qardl_scale_beta
    return scalar scale_short = _qardl_scale_short
    return scalar haclags_used = _qardl_haclags_used
    return scalar N_eff = _qardl_neff
    return local covariance "`covariance'"
    return scalar p = `p'
    return scalar q = `q'
    return scalar k = `k'
    return scalar N = `nobs'
end

* ============================================================
* Mata: Core QARDL Estimation
* ============================================================
capture mata: mata drop _qardl_qreg()
capture mata: mata drop _qardl_fnstep()
capture mata: mata drop _qardl_qreg_irls()
capture mata: mata drop _qardl_hac_auto()
capture mata: mata drop _qardl_qr_sandwich()
capture mata: mata drop _qardl_levels_cov()
capture mata: mata drop _qardl_core_estimate()

mata:
mata set matastrict off

// ------------------------------------------------------------------
// Maximum feasible step length: largest a >= 0 with x + a*dx >= 0.
// ------------------------------------------------------------------
real colvector _qardl_fnstep(real colvector x, real colvector dx)
{
    real scalar i, n
    real colvector b

    n = rows(x)
    b = J(n, 1, 1e20)
    for (i = 1; i <= n; i++) {
        if (dx[i] < 0) b[i] = -x[i] / dx[i]
    }

    return(b)
}

// ------------------------------------------------------------------
// Exact quantile regression by the Frisch-Newton primal-dual interior
// point method (Portnoy & Koenker 1997).  This is the same class of
// solver used by GAUSS quantileFit() and by MATLAB linprog() in
// qregressMatlab.m, and reproduces the LP optimum to about 1e-8.
//
//   min_b sum_i rho_tau(y_i - x_i'b)
//
// is solved through its dual
//   min c'd  s.t.  X'd = X'(1-tau)1,  0 <= d <= 1,  c = -y.
// ------------------------------------------------------------------
real colvector _qardl_qreg(real colvector y, real matrix X, real scalar tau)
{
    real scalar n, m, it, max_it, gap, small, bstep, fp, fd, mu, g
    real matrix A, AQ, AQAQ
    real colvector c, u, x, bvec, s, yd, r, z, w, q, sq, rhs
    real colvector dy, dx, ds, dz, dw, dxdz, dsdw, xinv, sinv, xi

    n = rows(X)
    m = cols(X)
    bstep  = 0.9995
    small  = 1e-8
    max_it = 100

    A    = X'                   // m x n
    c    = -y                   // n x 1
    u    = J(n, 1, 1)
    x    = J(n, 1, 1 - tau)     // dual start
    bvec = A * x                // m x 1

    s  = u - x
    yd = qrsolve(X, c)          // least-squares start for the dual vector
    if (hasmissing(yd)) yd = J(m, 1, 0)
    r  = c - X * yd
    r  = r + 0.001 :* (r :== 0)
    z  = r :* (r :> 0)
    w  = z - r

    gap = c' * x - yd' * bvec + w' * u

    it = 0
    while (gap > small & it < max_it) {
        it++

        q  = 1 :/ (z :/ x + w :/ s)
        r  = z - w
        sq = sqrt(q)

        AQ   = A :* sq'         // m x n
        rhs  = sq :* r          // n x 1
        AQAQ = AQ * AQ'

        // least-squares solve of AQ' * dy = rhs via normal equations
        dy = cholsolve(AQAQ, AQ * rhs)
        if (hasmissing(dy)) dy = qrsolve(AQ', rhs)

        dx = q :* (X * dy - r)
        ds = -dx
        dz = -z :* (1 :+ dx :/ x)
        dw = -w :* (1 :+ ds :/ s)

        // A non-finite step means the system has gone numerically bad.
        // Stop on the last good iterate rather than iterating on garbage:
        // missing compares as larger than any number in Mata, so the loop
        // condition alone would run to max_it.
        if (hasmissing(dx) | hasmissing(dz) | hasmissing(dw)) break

        fp = min((1, bstep * min((colmin(_qardl_fnstep(x, dx)),
                                  colmin(_qardl_fnstep(s, ds))))))
        fd = min((1, bstep * min((colmin(_qardl_fnstep(w, dw)),
                                  colmin(_qardl_fnstep(z, dz))))))

        if (min((fp, fd)) < 1) {
            // Mehrotra predictor-corrector step
            mu = z' * x + w' * s
            g  = (z + fd :* dz)' * (x + fp :* dx) +
                 (w + fd :* dw)' * (s + fp :* ds)
            mu = mu * (g / mu)^3 / (2 * n)

            dxdz = dx :* dz
            dsdw = ds :* dw
            xinv = 1 :/ x
            sinv = 1 :/ s
            xi   = mu :* (xinv - sinv)

            rhs = rhs + sq :* (dxdz - dsdw - xi)
            dy  = cholsolve(AQAQ, AQ * rhs)
            if (hasmissing(dy)) dy = qrsolve(AQ', rhs)

            dx = q :* (X * dy + xi - r - dxdz + dsdw)
            ds = -dx
            dz = mu :* xinv - z - xinv :* z :* dx - dxdz
            dw = mu :* sinv - w - sinv :* w :* ds - dsdw

            if (hasmissing(dx) | hasmissing(dz) | hasmissing(dw)) break

            fp = min((1, bstep * min((colmin(_qardl_fnstep(x, dx)),
                                      colmin(_qardl_fnstep(s, ds))))))
            fd = min((1, bstep * min((colmin(_qardl_fnstep(w, dw)),
                                      colmin(_qardl_fnstep(z, dz))))))
        }

        x  = x  + fp :* dx
        s  = s  + fp :* ds
        yd = yd + fd :* dy
        w  = w  + fd :* dw
        z  = z  + fd :* dz

        gap = c' * x - yd' * bvec + w' * u
    }

    return(-yd)
}

// ------------------------------------------------------------------
// Automatic Newey-West bandwidth, matching _qardlAutomaticHACLags().
// ------------------------------------------------------------------
real scalar _qardl_hac_auto(real scalar N)
{
    real scalar L

    L = trunc(4 * (N / 100)^(2/9))
    if (L < 1)     L = 1
    if (L > N - 1) L = N - 1

    return(L)
}

// ------------------------------------------------------------------
// Cross-quantile quantile-regression sandwich covariance of the full
// coefficient vector.  Translates _qardlQRCovSandwich() from GAUSS
// 3.1.1.  hac_lags = 0 gives the heteroskedasticity-robust form.
// ------------------------------------------------------------------
real matrix _qardl_qr_sandwich(real matrix ONEX, real colvector Y,
    real matrix bt, real colvector tau, real colvector fh,
    real matrix D_inv, real scalar hac_lags)
{
    real scalar N, K, ss, ii, jj, lag, wgt
    real matrix full_cov, scores_i, scores_j, S_ij, cov_block
    real colvector resid_i, resid_j, psi_i, psi_j

    N  = rows(ONEX)
    K  = cols(ONEX)
    ss = rows(tau)

    full_cov = J(K * ss, K * ss, 0)

    for (jj = 1; jj <= ss; jj++) {
        resid_j  = Y - ONEX * bt[., jj]
        psi_j    = tau[jj] :- (resid_j :< 0)
        scores_j = ONEX :* psi_j

        for (ii = 1; ii <= ss; ii++) {
            resid_i  = Y - ONEX * bt[., ii]
            psi_i    = tau[ii] :- (resid_i :< 0)
            scores_i = ONEX :* psi_i

            S_ij = scores_i' * scores_j / N

            for (lag = 1; lag <= hac_lags; lag++) {
                wgt  = 1 - lag / (hac_lags + 1)
                S_ij = S_ij +
                    wgt * (scores_i[(lag+1)..N, .]' * scores_j[1..(N-lag), .] / N) +
                    wgt * (scores_i[1..(N-lag), .]' * scores_j[(lag+1)..N, .] / N)
            }

            cov_block = D_inv * S_ij * D_inv / (fh[ii] * fh[jj] * N)

            full_cov[((ii-1)*K+1)..(ii*K), ((jj-1)*K+1)..(jj*K)] = cov_block
        }
    }

    return(full_cov)
}

// ------------------------------------------------------------------
// Map the full sandwich covariance into beta / phi / gamma blocks.
// Translates _qardlLevelsCovFromFull().  beta = theta/(1 - sum phi) is
// handled by the delta method.  Mata passes arguments by reference, so
// bigbt_cov, phi_cov and gamma_cov are returned to the caller.
// ------------------------------------------------------------------
void _qardl_levels_cov(real matrix full_cov, real matrix bt,
    real scalar ppp, real scalar qqq, real scalar k0, real scalar ss,
    real matrix bigbt_cov, real matrix phi_cov, real matrix gamma_cov)
{
    real scalar K, theta_start, theta_end, phi_start, phi_end
    real scalar ii, jj, row_i, row_j, den_i, den_j
    real matrix trans_i, trans_j, block_ij
    real colvector theta_i, theta_j

    K           = rows(bt)
    theta_start = 2 + qqq * k0
    theta_end   = 1 + (qqq + 1) * k0
    phi_start   = 2 + (qqq + 1) * k0
    phi_end     = 1 + (qqq + 1) * k0 + ppp

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

            row_i    = (ii - 1) * K + 1
            row_j    = (jj - 1) * K + 1
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
// Main QARDL estimation.
// Translates qardl() from GAUSS qardl.src 3.1.1 and qardl.m (MATLAB).
// ------------------------------------------------------------------
void _qardl_core_estimate(real colvector yy, real matrix xx,
    real scalar ppp, real scalar qqq, real colvector tau,
    string scalar cov_type, real scalar hac_lags)
{
    real scalar nn, k0, ss, jj, ii, neff, var1, za_val, sum_phi
    real scalar theta_start, theta_end, phi_start, phi_end
    real scalar scale_beta, scale_short, cov_lags, use_sandwich
    real colvector hb, hs, bt1, Y_vec, bb, alpha, rho
    real matrix ee, eei, xxi, yyi, X_mat, ONEX, ONEX_qr, Y_qr
    real matrix bt, fh, uu, barw, tw, mm, qq_mat, midbt, bigbt, bigbtmm
    real matrix kk, kkk_vec, bbt, tilw, lll, cc, bigpi, midphi, bigphi
    real matrix midgam, bigam, bilam, bigff
    real matrix yyj, xxj, wwj, D_qr, D_inv_qr, full_cov

    nn = rows(yy)
    k0 = cols(xx)
    ss = rows(tau)

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

    // Lagged differences of the regressors (skipped when q = 0)
    if (qqq > 0) {
        eei = J(nn - qqq, qqq * k0, 0)
        xxi = xx[qqq+1..nn, .]
        for (jj = 1; jj <= k0; jj++) {
            for (ii = 0; ii <= qqq-1; ii++) {
                eei[., ii+1+(jj-1)*qqq] = ee[qqq+1-ii..nn-ii, jj]
            }
        }
    }
    else {
        xxi = xx
    }

    // Lagged dependent variable
    yyi = J(nn - ppp, ppp, 0)
    for (ii = 1; ii <= ppp; ii++) {
        yyi[., ii] = yy[1+ppp-ii..nn-ii]
    }

    // Build regressor matrix
    if (qqq == 0) {
        X_mat = (xxi[rows(xxi)+1-rows(yyi)..rows(xxi), .], yyi)
    }
    else if (ppp > qqq) {
        X_mat = (eei[rows(eei)+1-rows(yyi)..rows(eei), .],
                 xxi[rows(xxi)+1-rows(yyi)..rows(xxi), .],
                 yyi)
    }
    else {
        X_mat = (eei,
                 xxi,
                 yyi[rows(yyi)+1-rows(xxi)..rows(yyi), .])
    }

    // Add constant
    ONEX  = (J(rows(X_mat), 1, 1), X_mat)
    Y_vec = yy[nn-rows(X_mat)+1..nn]

    ONEX_qr = ONEX
    Y_qr    = Y_vec

    // Quantile regression for each tau
    bt = J(cols(ONEX), ss, 0)
    fh = J(ss, 1, 0)

    for (jj = 1; jj <= ss; jj++) {
        bt1 = _qardl_qreg(Y_vec, ONEX, tau[jj])
        uu  = Y_vec - ONEX * bt1
        fh[jj] = mean(normalden(-uu / hb[jj])) / hb[jj]
        bt[., jj] = bt1
    }

    // Coefficient block positions inside bt
    theta_start = 2 + qqq * k0
    theta_end   = 1 + (qqq + 1) * k0
    phi_start   = 2 + (qqq + 1) * k0
    phi_end     = 1 + (qqq + 1) * k0 + ppp

    // ---- Point estimates (identical in every covariance path) ----
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

    bigbt  = vec(midbt)
    bigphi = vec(midphi)
    bigam  = vec(midgam)

    neff = rows(Y_qr)

    // The Cho-Kim-Shin iid covariance formulas are only defined for
    // q > 0; q = 0 and robust/HAC use the QR sandwich, exactly as
    // GAUSS 3.1.1 does.
    use_sandwich = (qqq == 0 | cov_type != "iid")

    cov_lags = 0
    if (cov_type == "hac") {
        cov_lags = hac_lags
        if (cov_lags == 0) cov_lags = _qardl_hac_auto(neff)
    }

    if (use_sandwich) {
        D_qr     = ONEX_qr' * ONEX_qr / neff
        D_inv_qr = luinv(D_qr)
        full_cov = _qardl_qr_sandwich(ONEX_qr, Y_qr, bt, tau, fh, D_inv_qr, cov_lags)
        _qardl_levels_cov(full_cov, bt, ppp, qqq, k0, ss, bigbtmm, bigpi, bigff)

        // Sandwich covariances are ordinary covariance estimates: the
        // (n-1) normalisations below do not apply to them.
        scale_beta  = 1
        scale_short = 1
    }
    else {
        // ---- Original Cho-Kim-Shin iid covariance ----

        // Testing long-run parameter: beta
        barw = J(nn-1, qqq*k0, 0)
        for (jj = 1; jj <= qqq; jj++) {
            barw[jj..nn-1, k0*(jj-1)+1..k0*jj] = ee[2..nn-jj+1, .]
        }

        tw = (J(nn-1, 1, 1), barw)

        mm = (xxi' * xxi - xxi' * tw[qqq..nn-1, .] *
             luinv(tw[qqq..nn-1, .]' * tw[qqq..nn-1, .]) *
             tw[qqq..nn-1, .]' * xxi) / (nn - qqq)^2

        // bb = 1/((1-sum(phi))*f)
        bb = J(ss, 1, 0)
        for (jj = 1; jj <= ss; jj++) {
            bb[jj] = 1 / ((1 - colsum(bt[phi_start..phi_end, jj])) * fh[jj])
        }

        // Omega matrix
        qq_mat = J(ss, ss, 0)
        for (jj = 1; jj <= ss; jj++) {
            for (ii = 1; ii <= ss; ii++) {
                qq_mat[jj, ii] = (min((tau[jj], tau[ii])) - tau[jj]*tau[ii]) *
                                 bb[jj] * bb[ii]
            }
        }

        bigbtmm = qq_mat # luinv(mm)

        // Testing short-run parameters: phi
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
            xxj  = xx[ppp+1..nn, .]
            tilw = tw[ppp..nn-1, .]
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
            xxj  = xx[qqq+1..nn, .]
            tilw = tw[qqq..nn-1, .]
        }

        kk = J(neff, ss*ppp, 0)
        for (jj = 1; jj <= ppp; jj++) {
            Y_vec = yyj[., jj]
            ONEX  = (J(neff, 1, 1), xxj, wwj)
            for (ii = 1; ii <= ss; ii++) {
                bbt     = _qardl_qreg(Y_vec, ONEX, tau[ii])
                kkk_vec = Y_vec - ONEX * bbt
                kk[., jj+(ii-1)*ppp] = kkk_vec
            }
        }

        lll = (kk' * kk - kk' * tilw * luinv(tilw' * tilw) * tilw' * kk) / neff

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
                lll_jj  = lll[(jj-1)*ppp+1..jj*ppp, (jj-1)*ppp+1..jj*ppp]
                lll_ji  = lll[(jj-1)*ppp+1..jj*ppp, (ii-1)*ppp+1..ii*ppp]
                lll_ii  = lll[(ii-1)*ppp+1..ii*ppp, (ii-1)*ppp+1..ii*ppp]
                psu_mat = luinv(lll_jj) * lll_ji * luinv(lll_ii)
                bigpi[(jj-1)*ppp+1..jj*ppp, (ii-1)*ppp+1..ii*ppp] = cc[jj,ii] * psu_mat
            }
        }

        // Gamma covariance by the delta method
        bilam = J(k0*ss, ss*ppp, 0)
        for (jj = 1; jj <= ss; jj++) {
            bilam[(jj-1)*k0+1..jj*k0, (jj-1)*ppp+1..jj*ppp] =
                midbt[., jj] * J(1, ppp, 1)
        }
        bigff = bilam * bigpi * bilam'

        // Cho-Kim-Shin normalisation, matching _qardlLevelsSE() in
        // GAUSS 3.1.1: beta covariance is stored at (n-1)^2 scale and
        // phi/gamma covariance at (n-1) scale.
        scale_beta  = (nn - 1)^2
        scale_short = nn - 1
    }

    // Store results in Stata matrices
    st_matrix("_qardl_beta", bigbt)
    st_matrix("_qardl_beta_cov", bigbtmm)
    st_matrix("_qardl_phi", bigphi)
    st_matrix("_qardl_phi_cov", bigpi)
    st_matrix("_qardl_gamma", bigam)
    st_matrix("_qardl_gamma_cov", bigff)
    st_matrix("_qardl_alpha", alpha)
    st_matrix("_qardl_rho", rho)
    st_matrix("_qardl_bt_raw", bt)
    st_matrix("_qardl_fh", fh)
    st_numscalar("_qardl_scale_beta", scale_beta)
    st_numscalar("_qardl_scale_short", scale_short)
    st_numscalar("_qardl_haclags_used", cov_lags)
    st_numscalar("_qardl_neff", rows(Y_qr))
}

end
