*! _xtpc_pme v1.1.0 — Pooled Minimum Eigenvalue (PME) Estimator
*! Multiple Long-Run Relations in Panel Data
*! Chudik, Pesaran & Smith (2025), Paper 2506.02135v3
*! Author: Dr. Merwan Roudane

program define _xtpc_pme, eclass
    version 14.0
    syntax varlist(min=2) [if] [in], ///
        [SUBsamples(integer 2) DELta(real 0.25) RANK(integer -1)]

    _xt, trequired
    local panelvar "`r(ivar)'"
    local timevar  "`r(tvar)'"

    marksample touse
    markout `touse' `panelvar' `timevar'

    local m : word count `varlist'

    qui xtdescribe if `touse'
    if r(min) != r(max) {
        di as error "xtpanelcoint pme requires a strongly balanced panel"
        exit 498
    }

    // Fix subsamples minimum
    if `subsamples' < 2 {
        local subsamples = 2
    }

    tempname r_hat

    mata: _xtpc_pme_run("`varlist'", "`panelvar'", "`timevar'", ///
        "`touse'", `subsamples', `delta', `rank')

    tempname bb VV
    matrix `bb' = (0)
    matrix colnames `bb' = r_hat
    matrix `VV' = (1)
    matrix colnames `VV' = r_hat
    matrix rownames `VV' = r_hat

    ereturn post `bb' `VV', esample(`touse')
    ereturn local cmd            "xtpanelcoint"
    ereturn local estimator      "PME (q=`subsamples')"
    ereturn local estimator_type "pme"
    ereturn local depvar         "`varlist'"
    ereturn local indepvar       ""
    ereturn scalar r_hat         = scalar(_xtpc_rhat)
    ereturn scalar m_vars        = `m'
    ereturn scalar N_g           = scalar(_xtpc_N)
    ereturn scalar T             = scalar(_xtpc_T)
    ereturn scalar delta         = `delta'
    ereturn scalar subsamples    = `subsamples'
    ereturn scalar lags          = 0
    ereturn scalar n_iter        = 0
    ereturn scalar converged     = 1
    ereturn scalar boot_ci_lo    = .
    ereturn scalar boot_ci_hi    = .
    ereturn scalar boot_reps     = 0

    cap ereturn matrix eigenvalues = _xtpc_eigvals
    cap ereturn matrix Theta       = _xtpc_Theta
    cap ereturn matrix Theta_se    = _xtpc_Theta_se
    cap ereturn matrix Theta_t     = _xtpc_Theta_t
    cap ereturn matrix Theta_p     = _xtpc_Theta_p
    cap ereturn matrix Q_ww        = _xtpc_Qww

    cap scalar drop _xtpc_N _xtpc_T _xtpc_rhat

    _xtpc_pme_display
end

mata:
mata set matastrict off

void _xtpc_pme_run(string scalar varlist, string scalar panelvar,
                    string scalar timevar, string scalar touse,
                    real scalar q, real scalar delta, real scalar r0_fixed)
{
    real matrix W_all, W_panel, w_bar, w_bar_dot, Q_ww, diff_v
    real colvector pid, tid, panels, times, sel
    real scalar n, _T, m, Tq, i, ell, r_hat, j_idx
    real matrix eigvecs, R_ww, D_inv
    real colvector eigvals, eig_R, diag_sqrt
    real scalar threshold
    real matrix B_hat, B1, B2, B1_inv, Theta_hat, B0_hat
    real matrix Omega_hat, V_theta, Q22, Q22_inv
    real colvector zeta_bar, E_bar, theta_vec, std_errors, t_ratios, p_values

    // ─── Read panel data (multiple variables) ────────────────────────────
    st_view(pid, ., panelvar, touse)
    st_view(tid, ., timevar, touse)
    W_all = st_data(., tokens(varlist), touse)
    m = cols(W_all)

    panels = uniqrows(pid)
    times  = uniqrows(tid)
    n  = rows(panels)
    _T = rows(times)

    // Reshape to (n, T, m) — stored as n blocks of (T x m) stacked
    // W_panel[((i-1)*T+1)..(i*T), .] = unit i's data
    W_panel = J(n * _T, m, .)
    for (i = 1; i <= n; i++) {
        sel = selectindex(pid :== panels[i])
        W_panel[((i-1)*_T + 1)..(i*_T), .] = W_all[sel, .]
    }

    Tq = floor(_T / q)

    // ─── Step 1: Sub-sample means ────────────────────────────────────────
    // w_bar: (n*q) x m
    w_bar = J(n * q, m, 0)
    for (i = 1; i <= n; i++) {
        for (ell = 1; ell <= q; ell++) {
            t1 = (i - 1) * _T + (ell - 1) * Tq + 1
            t2 = (i - 1) * _T + ell * Tq
            w_bar[(i-1)*q + ell, .] = mean(W_panel[t1..t2, .])
        }
    }

    // Full-sample sub-mean per unit: (n x m)
    w_bar_dot = J(n, m, 0)
    for (i = 1; i <= n; i++) {
        w_bar_dot[i, .] = mean(w_bar[((i-1)*q + 1)..(i*q), .])
    }

    // ─── Step 2: Pooled covariance Q_ww (eq 9-10) ─────────────────────────
    //  Paper: Q_{ww} = n^{-1} sum_i T^{-1} q^{-1} sum_ell dd'
    Q_ww_raw = J(m, m, 0)
    for (i = 1; i <= n; i++) {
        for (ell = 1; ell <= q; ell++) {
            diff_v = w_bar[(i-1)*q + ell, .] - w_bar_dot[i, .]
            Q_ww_raw = Q_ww_raw + diff_v' * diff_v
        }
    }
    Q_ww_raw = Q_ww_raw / (n * _T * q)   // paper-scale: eq (9-10)
    Q_ww = Q_ww_raw * _T^2               // T^2 scaling for eigenvalue ranking

    // ─── Step 3: Eigendecomposition ──────────────────────────────────────
    symeigensystem(Q_ww, eigvecs, eigvals)
    // Sort ascending
    sort_idx = order(eigvals', 1)
    eigvals_sorted = J(m, 1, 0)
    eigvecs_sorted = J(m, m, 0)
    for (j_idx = 1; j_idx <= m; j_idx++) {
        eigvals_sorted[j_idx] = eigvals[sort_idx[j_idx]]
        eigvecs_sorted[., j_idx] = eigvecs[., sort_idx[j_idx]]
    }

    // ─── Step 4: Estimate r_0 ────────────────────────────────────────────
    if (r0_fixed >= 0) {
        r_hat = r0_fixed
    }
    else {
        // Use correlation matrix for scale invariance
        diag_sqrt = sqrt(diagonal(Q_ww))
        diag_sqrt = diag_sqrt :+ (diag_sqrt :< 1e-15)
        D_inv = diag(1 :/ diag_sqrt)
        R_ww = D_inv * Q_ww * D_inv
        symeigensystem(R_ww, ., eig_R)
        eig_R = sort(eig_R', 1)
        threshold = _T^(-delta)
        r_hat = 0
        for (j_idx = 1; j_idx <= m; j_idx++) {
            if (eig_R[j_idx] < threshold) r_hat++
        }
    }

    // ─── Step 5: Extract long-run relations ──────────────────────────────
    Theta_hat = J(0, 0, .)
    std_errors_mat = J(0, 0, .)
    t_ratios_mat   = J(0, 0, .)
    p_values_mat   = J(0, 0, .)

    if (r_hat > 0 & r_hat < m) {
        B_hat = eigvecs_sorted[., 1..r_hat]

        // Identify: normalize B_{0,1} = I_{r_0}
        B1 = B_hat[1..r_hat, .]        // r_hat x r_hat
        B2 = B_hat[(r_hat+1)..m, .]    // (m - r_hat) x r_hat

        if (det(B1) != 0) {
            B1_inv = luinv(B1)
            Theta_hat = B2 * B1_inv

            // ─── Step 6: Asymptotic variance (eq 36) ─────────────────
            B0_hat = (I(r_hat) \ Theta_hat)
            mr = (m - r_hat) * r_hat
            Omega_hat = J(m * r_hat, m * r_hat, 0)

            for (i = 1; i <= n; i++) {
                zeta_bar = J(m * r_hat, 1, 0)
                for (ell = 1; ell <= q; ell++) {
                    diff_v = (w_bar[(i-1)*q + ell, .] - w_bar_dot[i, .])'
                    E_bar = B0_hat' * diff_v
                    for (r = 1; r <= r_hat; r++) {
                        zeta_bar[((r-1)*m + 1)..(r*m)] = ///
                            zeta_bar[((r-1)*m + 1)..(r*m)] + diff_v * E_bar[r] / q
                    }
                }
                Omega_hat = Omega_hat + zeta_bar * zeta_bar'
            }
            Omega_hat = Omega_hat / n

            // Extract lower block — use PAPER-SCALE Q_ww_raw for variance
            Q22_raw = Q_ww_raw[(r_hat+1)..m, (r_hat+1)..m]
            if (det(Q22_raw) != 0) Q22_inv = luinv(Q22_raw)
            else                   Q22_inv = I(m - r_hat)

            // Build index for lower block
            idx_22 = J(0, 1, .)
            for (r = 1; r <= r_hat; r++) {
                for (k = r_hat + 1; k <= m; k++) {
                    idx_22 = idx_22 \ ((r - 1) * m + k)
                }
            }

            if (rows(idx_22) > 0) {
                Omega_22 = Omega_hat[idx_22, idx_22]
                kron_IQ = I(r_hat) # Q22_inv
                // eq (36): Var[vec(Theta)] = (1/nT^2) Q22^{-1} Omega_{q,22} Q22^{-1}
                V_theta = kron_IQ * Omega_22 * kron_IQ / (n * _T^2)

                theta_vec = vec(Theta_hat)
                std_errors = sqrt(abs(diagonal(V_theta)))
                t_ratios = theta_vec :/ (std_errors :+ (std_errors :== 0) * 1e100)
                p_values = 2 * (1 :- normal(abs(t_ratios)))

                // Reshape for output
                nr = m - r_hat
                nc = r_hat
                std_errors_mat = rowshape(std_errors, nr)
                t_ratios_mat   = rowshape(t_ratios, nr)
                p_values_mat   = rowshape(p_values, nr)
            }
        }
    }

    // ─── Post to Stata ───────────────────────────────────────────────────
    st_numscalar("_xtpc_N",    n)
    st_numscalar("_xtpc_T",    _T)
    st_numscalar("_xtpc_rhat", r_hat)

    st_matrix("_xtpc_eigvals", eigvals_sorted)
    st_matrix("_xtpc_Qww",    Q_ww)

    if (rows(Theta_hat) > 0 & cols(Theta_hat) > 0) {
        st_matrix("_xtpc_Theta",    Theta_hat)
        st_matrix("_xtpc_Theta_se", std_errors_mat)
        st_matrix("_xtpc_Theta_t",  t_ratios_mat)
        st_matrix("_xtpc_Theta_p",  p_values_mat)
    }
}

end
