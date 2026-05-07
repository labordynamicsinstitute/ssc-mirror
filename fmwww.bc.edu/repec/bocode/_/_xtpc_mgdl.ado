*! _xtpc_mgdl v1.1.0 — Mean Group Distributed Lag (MGDL) for IRFs
*! Choi & Chudik (2024), Paper 0423r1
*! Author: Dr. Merwan Roudane
*! v1.1.0: Added c_j estimation (eq 4), corrected variance (eq 7-8)

program define _xtpc_mgdl, eclass
    version 14.0
    syntax varlist(min=2 max=2) [if] [in], ///
        PRODuct(varname) LOCation(varname) ///
        [HORizon(integer 4) AUGmented BONFerroni]

    _xt, trequired
    local timevar "`r(tvar)'"

    marksample touse
    markout `touse' `product' `location' `timevar'

    tokenize `varlist'
    local depvar   "`1'"
    local shockvar "`2'"

    local do_aug  = ("`augmented'"  != "")
    local do_bonf = ("`bonferroni'" != "")

    tempname nM nN nT

    mata: _xtpc_mgdl_run("`depvar'", "`shockvar'", "`product'", ///
        "`location'", "`timevar'", "`touse'", ///
        `horizon', `do_aug', `do_bonf')

    tempname bb VV
    matrix `bb' = (0)
    matrix colnames `bb' = delta
    matrix `VV' = (1)
    matrix colnames `VV' = delta
    matrix rownames `VV' = delta

    ereturn post `bb' `VV', esample(`touse')
    ereturn local cmd            "xtpanelcoint"
    ereturn local estimator      "MGDL (h=`horizon')"
    ereturn local estimator_type "mgdl"
    ereturn local depvar         "`depvar'"
    ereturn local indepvar       "`shockvar'"
    ereturn local product_var    "`product'"
    ereturn local location_var   "`location'"
    ereturn scalar horizon       = `horizon'
    ereturn scalar N_g           = scalar(_xtpc_N)
    ereturn scalar T             = scalar(_xtpc_T)
    ereturn scalar M_products    = scalar(_xtpc_M)
    ereturn scalar N_locations   = scalar(_xtpc_NL)
    ereturn scalar lags          = `horizon'
    ereturn scalar n_iter        = 0
    ereturn scalar converged     = 1
    ereturn scalar boot_ci_lo    = .
    ereturn scalar boot_ci_hi    = .
    ereturn scalar boot_reps     = 0

    // Matrices posted from Mata
    cap ereturn matrix cum_mult   = _xtpc_cum_mult
    cap ereturn matrix cum_ci_lo  = _xtpc_cum_ci_lo
    cap ereturn matrix cum_ci_hi  = _xtpc_cum_ci_hi
    cap ereturn matrix product_irfs = _xtpc_prod_irfs
    cap ereturn matrix location_irfs = _xtpc_loc_irfs
    cap ereturn matrix significant  = _xtpc_signif

    cap scalar drop _xtpc_N _xtpc_T _xtpc_M _xtpc_NL

    _xtpc_mgdl_display
end

mata:
mata set matastrict off

void _xtpc_mgdl_run(string scalar depvar, string scalar shockvar,
                      string scalar prodvar, string scalar locvar,
                      string scalar timevar, string scalar touse,
                      real scalar h, real scalar do_aug, real scalar do_bonf)
{
    real colvector prod_id, loc_id, tim_id, yy, vv
    real colvector prods, locs, times, sel
    real scalar M, N, _T, T_eff, i, j, ell, t
    real matrix V, W, b_hat_ij, var_b_ij, coeffs, resid_v
    real matrix b_i, c_j, b_hat_3d
    real colvector delta_hat, var_delta, se_delta, ci_lo, ci_hi
    real scalar omega_sq, avg_var, alpha_adj, z_crit, sigma2
    real colvector xij, significant

    // Read data
    st_view(prod_id, ., prodvar, touse)
    st_view(loc_id,  ., locvar,  touse)
    st_view(tim_id,  ., timevar, touse)
    st_view(yy,      ., depvar,  touse)
    st_view(vv,      ., shockvar, touse)

    prods = uniqrows(prod_id)
    locs  = uniqrows(loc_id)
    times = uniqrows(tim_id)
    M  = rows(prods)
    N  = rows(locs)
    _T = rows(times)

    T_eff = _T - h - 1
    if (T_eff < 3) {
        errprintf("MGDL: T_eff = %g too small (T=%g, h=%g)\n", T_eff, _T, h)
        exit(error(2001))
    }

    // Allocate: store b_hat as (M*N) x (h+1)
    b_hat_all = J(M * N, h + 1, 0)
    var_b_all = J(M * N, h + 1, 0)

    // Unit-level DL regressions (eq 17 of paper)
    for (i = 1; i <= M; i++) {
        for (j = 1; j <= N; j++) {
            sel = selectindex((prod_id :== prods[i]) :& (loc_id :== locs[j]))
            if (rows(sel) < _T) continue
            y_ij = yy[sel]
            v_ij = vv[sel]

            // Dependent: x_{ij,t} for t = h+2,...,T
            xij = y_ij[(h + 2).._T]

            // Augmentation: lagged dependent x_{ij,t-h-1}
            x_lag = y_ij[(h + 1)..(_T - 1)]

            // Shock lag matrix: V[s, ell+1] = v_{t-ell}
            V = J(T_eff, h + 1, 0)
            for (ell = 0; ell <= h; ell++) {
                for (t = 1; t <= T_eff; t++) {
                    idx = h + 1 + t - ell
                    if (idx >= 1 & idx <= _T) V[t, ell + 1] = v_ij[idx]
                }
            }

            W = (V, x_lag, J(T_eff, 1, 1))

            k_reg = cols(W)
            row_idx = (i - 1) * N + j

            WtW = W' * W
            if (det(WtW) != 0) {
                coeffs = invsym(WtW) * W' * xij
                b_hat_all[row_idx, .] = coeffs[1..(h+1)]'
                resid_v = xij - W * coeffs
                sigma2 = resid_v' * resid_v / max((T_eff - k_reg, 1))
                WtW_inv = invsym(WtW)
                for (ell = 1; ell <= h + 1; ell++) {
                    var_b_all[row_idx, ell] = sigma2 * WtW_inv[ell, ell]
                }
            }
        }
    }

    // ─── Mean group: product IRFs b_i = N^{-1} sum_j b_{ij} (eq 3) ──────
    b_i = J(M, h + 1, 0)
    for (i = 1; i <= M; i++) {
        row_start = (i - 1) * N + 1
        row_end   = i * N
        b_i[i, .] = mean(b_hat_all[row_start..row_end, .])
    }

    // ─── Location effects: c_j = M^{-1} sum_i (b_{ij} - b_i) (eq 4) ────
    c_j = J(N, h + 1, 0)
    for (j = 1; j <= N; j++) {
        for (i = 1; i <= M; i++) {
            row_idx = (i - 1) * N + j
            c_j[j, .] = c_j[j, .] + (b_hat_all[row_idx, .] - b_i[i, .])
        }
        c_j[j, .] = c_j[j, .] / M
    }

    // ─── Cumulative multiplier: delta_i = sum_ell b_{i,ell} ─────────────
    delta_hat = J(M, 1, 0)
    for (i = 1; i <= M; i++) {
        delta_hat[i] = rowsum(b_i[i, .])
    }

    // ─── Variance using omega_ij = b_ij - b_i - c_j (eq 7) ─────────────
    var_delta = J(M, 1, 0)
    for (i = 1; i <= M; i++) {
        row_start = (i - 1) * N + 1
        cum_ij = J(N, 1, 0)
        for (j = 1; j <= N; j++) {
            row_idx = row_start + j - 1
            // omega_ij = b_ij - b_i - c_j  (eq 7-8)
            omega_ij = b_hat_all[row_idx, .] - b_i[i, .] - c_j[j, .]
            cum_ij[j] = rowsum(omega_ij)
        }
        // Var = (1/(N*(N-1))) * sum_j omega_ij^2  (eq 7 applied to cumulative)
        omega_sq = sum(cum_ij :^ 2) / (N * (N - 1))

        if (do_aug) {
            // Augmented variance: add (M/T) * sigma_v^{-2} * kappa_{hi}
            // For cumulative multiplier, sum the per-coefficient variances
            cum_var_ij = J(N, 1, 0)
            for (j = 1; j <= N; j++) {
                row_idx = row_start + j - 1
                cum_var_ij[j] = rowsum(var_b_all[row_idx, .])
            }
            omega_sq = omega_sq + (M / _T) * mean(cum_var_ij)
        }
        var_delta[i] = omega_sq
    }

    se_delta = sqrt(var_delta)

    // Bonferroni correction (family-wise across products)
    if (do_bonf) alpha_adj = 0.05 / M
    else         alpha_adj = 0.05
    z_crit = invnormal(1 - alpha_adj / 2)

    ci_lo = delta_hat - z_crit * se_delta
    ci_hi = delta_hat + z_crit * se_delta
    significant = (ci_lo :> 0) :| (ci_hi :< 0)

    // Post to Stata
    st_numscalar("_xtpc_N",  M * N)
    st_numscalar("_xtpc_T",  _T)
    st_numscalar("_xtpc_M",  M)
    st_numscalar("_xtpc_NL", N)

    st_matrix("_xtpc_cum_mult",  delta_hat)
    st_matrix("_xtpc_cum_ci_lo", ci_lo)
    st_matrix("_xtpc_cum_ci_hi", ci_hi)
    st_matrix("_xtpc_prod_irfs", b_i)
    st_matrix("_xtpc_loc_irfs",  c_j)
    st_matrix("_xtpc_signif",    significant)
}

end
