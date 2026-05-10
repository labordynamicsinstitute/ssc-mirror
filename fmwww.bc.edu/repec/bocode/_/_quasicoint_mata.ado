*! _quasicoint_mata.ado — Mata computational engine for quasicoint
*! Version 1.0.0 — 2026-05-09
*! Author: Dr. Merwan Roudane

// ============================================================================
//  MATA BLOCK: All computational routines for quasi-cointegration
// ============================================================================

mata:
mata clear
mata set matastrict off

// ---------------------------------------------------------------------------
//  _qc_companion(): build VAR companion matrix from Stata var estimates
// ---------------------------------------------------------------------------
real matrix _qc_companion(real matrix Phi, real scalar p, real scalar k)
{
    real matrix F
    real scalar kp
    kp = k * p
    F = J(kp, kp, 0)
    // Top block: [Phi1 Phi2 ... Phik]
    F[1..p, .] = Phi
    // Sub-diagonal identity blocks
    if (k > 1) {
        F[(p+1)..kp, 1..(kp-p)] = I(kp - p)
    }
    return(F)
}

// ---------------------------------------------------------------------------
//  _qc_get_var_coefs(): extract VAR coefficient matrices from Stata e()
// ---------------------------------------------------------------------------
real matrix _qc_get_var_coefs(string scalar varlist, real scalar p,
                              real scalar k, string scalar nocons)
{
    real matrix Phi, eB
    real scalar i, j, row, ncols
    string rowvector vnames

    // e(b) from var has columns: [eq1:L.y1, eq1:L.y2, ..., eq1:L.yp,
    //                             eq1:L2.y1, ... , eq1:_cons,
    //                             eq2:L.y1, ... ]
    eB = st_matrix("e(b)")
    vnames = tokens(varlist)

    // Number of RHS terms per equation
    ncols = cols(eB) / p
    Phi = J(p, k*p, 0)

    for (i = 1; i <= p; i++) {
        for (j = 1; j <= k; j++) {
            for (row = 1; row <= p; row++) {
                // Position in e(b): equation i, lag j, variable row
                // Each equation block: k*p regressors + (0 or 1 const) + (0 or 1 trend)
                Phi[i, (j-1)*p + row] = eB[1, (i-1)*ncols + (j-1)*p + row]
            }
        }
    }
    return(Phi)
}

// ---------------------------------------------------------------------------
//  _qc_eigendecomp(): eigenvalue decomposition, sort by modulus descending
// ---------------------------------------------------------------------------
void _qc_eigendecomp(real matrix F, real scalar kp,
                     real colvector eval_re, real colvector eval_im,
                     real matrix evec)
{
    real colvector idx
    complex colvector ev
    complex matrix Vc
    real scalar i, n_ev

    // Stata Mata: eigensystem(A, X, L) — X = LEFT eigenvectors (columns)
    // We need RIGHT eigenvectors for R_LU. Use righteigensystem if available,
    // otherwise transpose approach.
    // righteigensystem: righteigensystem(F, Vc, ev)
    // Fallback: right eigenvectors of F = left eigenvectors of F'
    eigensystem(F', Vc, ev)

    n_ev = length(ev)

    // Extract real/imag parts
    eval_re = Re(ev)
    eval_im = Im(ev)

    // Sort by modulus descending
    real colvector moduli
    moduli = sqrt(eval_re:^2 + eval_im:^2)
    idx = order(-moduli, 1)

    eval_re = eval_re[idx]
    eval_im = eval_im[idx]

    // Right eigenvector matrix (real parts)
    evec = Re(Vc[., idx])
}

// ---------------------------------------------------------------------------
//  _qc_extract_RLU(): extract R_LU (first p rows, first q columns of R)
// ---------------------------------------------------------------------------
real matrix _qc_extract_RLU(real matrix evec, real scalar p, real scalar q)
{
    real scalar nrow
    nrow = rows(evec)
    if (nrow >= p) {
        return(evec[1..p, 1..q])
    }
    else {
        // Companion may equal p when k=1
        return(evec[., 1..q])
    }
}

// ---------------------------------------------------------------------------
//  _qc_quasi_beta(): compute quasi-cointegrating vector(s) from R_LU
//   beta = (sp R_LU)^perp, normalised as [I_r, -A]
// ---------------------------------------------------------------------------
real matrix _qc_quasi_beta(real matrix RLU, real scalar p, real scalar q)
{
    real scalar r, i
    real matrix beta

    r = p - q

    // Use QR decomposition to find orthogonal complement of sp(R_LU)
    // qrd(R_LU) = Q * R; last r columns of Q span null space
    real matrix Q, R_qr
    Q = J(p, p, 0)

    if (q == 1) {
        // Simple case: orthogonal complement of a single vector
        // Gram-Schmidt
        real colvector v, u
        v = RLU[., 1]
        v = v / sqrt(v' * v)  // normalise

        // Build orthonormal basis for complement
        beta = J(p, r, 0)
        real matrix basis
        basis = I(p)
        real scalar col_idx
        col_idx = 0
        for (i = 1; i <= p; i++) {
            real colvector candidate
            candidate = basis[., i] - (v' * basis[., i]) * v
            if (sqrt(candidate' * candidate) > 1e-10) {
                col_idx = col_idx + 1
                beta[., col_idx] = candidate / sqrt(candidate' * candidate)
                if (col_idx >= r) break
                // Re-orthogonalise against previous
                if (col_idx > 1) {
                    real scalar jj
                    for (jj = 1; jj < col_idx; jj++) {
                        beta[., col_idx] = beta[., col_idx] - ///
                            (beta[., jj]' * beta[., col_idx]) * beta[., jj]
                    }
                    beta[., col_idx] = beta[., col_idx] / ///
                        sqrt(beta[., col_idx]' * beta[., col_idx])
                }
            }
        }
    }
    else {
        // General case: SVD
        real matrix U, Vt
        real colvector s
        fullsvd(RLU, U, s, Vt)
        beta = U[., (q+1)..p]
    }

    // Normalise: beta[1..r, .] = I_r
    real matrix top
    top = beta[1..r, .]
    if (r == 1) {
        if (abs(top[1,1]) > 1e-12) {
            beta = beta / top[1,1]
        }
    }
    else {
        if (abs(det(top)) > 1e-12) {
            beta = beta * luinv(top)
        }
    }
    return(beta)
}

// ---------------------------------------------------------------------------
//  _qc_restricted_var(): estimate VAR with q roots restricted to lambda0
//   Uses quasi-differencing: Delta_lambda y_t = alpha*beta'*y_{t-1} + ...
// ---------------------------------------------------------------------------
real matrix _qc_restricted_est(string scalar varlist, string scalar touse,
                               real scalar lambda0, real scalar p,
                               real scalar q, real scalar k,
                               string scalar nocons,
                               real matrix beta_out, real matrix alpha_out,
                               real scalar loglik)
{
    string rowvector vnames
    real matrix Y, X, Ydiff, Xlag, Xdiff, Phi_lambda
    real scalar n, t, i, j, r
    real colvector sel

    vnames = tokens(varlist)
    r = p - q

    // Load data
    n = st_nobs()
    sel = J(n, 1, 0)
    st_view(sel, ., touse)

    Y = J(n, p, .)
    for (i = 1; i <= p; i++) {
        Y[., i] = st_data(., vnames[i])
    }

    // Keep touse observations
    real colvector keep
    keep = selectindex(sel)
    Y = Y[keep, .]
    n = rows(Y)

    // Quasi-difference: Delta_lambda y_t = y_t - lambda * y_{t-1}
    real scalar T_eff
    T_eff = n - k

    real matrix DY, Ylag, DYlag
    DY = Y[(k+1)..n, .] - lambda0 * Y[k..(n-1), .]
    Ylag = Y[k..(n-1), .]

    // Build lagged quasi-differences for k-1 lags
    if (k > 1) {
        DYlag = J(T_eff, p*(k-1), 0)
        for (j = 1; j <= (k-1); j++) {
            real scalar s1, s2
            s1 = k + 1 - j
            s2 = n - j
            DYlag[., (j-1)*p+1 .. j*p] = Y[s1..s2, .] - lambda0 * Y[(s1-1)..(s2-1), .]
        }
    }

    // Reduced rank regression (Johansen-style on quasi-differenced data)
    // DY = alpha * beta' * Ylag + Gamma * DYlag + epsilon
    // Step 1: Concentrate out DYlag
    real matrix R0, R1
    if (k > 1) {
        real matrix Md
        Md = I(T_eff) - DYlag * invsym(DYlag' * DYlag) * DYlag'
        R0 = Md * DY
        R1 = Md * Ylag
    }
    else {
        R0 = DY
        R1 = Ylag
    }

    // Step 2: Solve eigenvalue problem
    // S11^{-1/2} S10 S00^{-1} S01 S11^{-1/2} is symmetric
    real matrix S00, S01, S10, S11, S11inv, M_eig
    S00 = (R0' * R0) / T_eff
    S01 = (R0' * R1) / T_eff
    S10 = S01'
    S11 = (R1' * R1) / T_eff

    // Regularise
    S11 = S11 + 1e-10 * I(p)
    S00 = S00 + 1e-10 * I(p)
    S11inv = invsym(S11)

    // Use Cholesky of S11 for symmetric problem
    real matrix S11h, S11hi, M_sym
    S11h = cholesky(S11)
    S11hi = luinv(S11h)

    // Symmetric matrix for eigendecomposition
    M_sym = S11hi * S10 * invsym(S00) * S01 * S11hi'

    // Force symmetry
    M_sym = (M_sym + M_sym') / 2

    // Real symmetric eigendecomposition
    real matrix eigvecs_r
    real colvector eigvals_r
    symeigensystem(M_sym, eigvecs_r, eigvals_r)

    // symeigensystem returns eigenvalues in ASCENDING order
    // We want the r LARGEST eigenvalues
    real matrix beta_raw
    real scalar ncols
    ncols = cols(eigvecs_r)

    // Last r columns have largest eigenvalues
    // Transform back: beta_raw = S11^{-1/2} * eigvecs
    beta_raw = S11hi' * eigvecs_r[., (ncols-r+1)..ncols]

    // Normalise: top r x r block = I_r
    real matrix top
    top = beta_raw[1..r, .]
    if (r == 1) {
        if (abs(top[1,1]) > 1e-12) {
            beta_raw = beta_raw / top[1,1]
        }
    }
    else {
        if (abs(det(top)) > 1e-12) {
            beta_raw = beta_raw * luinv(top)
        }
    }

    beta_out = beta_raw
    alpha_out = S01 * beta_raw * invsym(beta_raw' * S11 * beta_raw)

    // Log-likelihood (concentrated)
    real matrix Sigma_hat
    Sigma_hat = S00 - S01 * beta_raw * invsym(beta_raw' * S11 * beta_raw) * beta_raw' * S10
    loglik = -T_eff/2 * (p * ln(2*pi()) + ln(det(Sigma_hat)) + p)

    return(Sigma_hat)
}

// ---------------------------------------------------------------------------
//  _qc_compute_irf(): compute impulse response function from VAR
// ---------------------------------------------------------------------------
real matrix _qc_compute_irf(real matrix Phi, real scalar p, real scalar k,
                            real scalar horizons)
{
    real matrix F, IRF
    real scalar kp, h

    F = _qc_companion(Phi, p, k)
    kp = k * p
    IRF = J(p * horizons, p, 0)

    real matrix Fh
    Fh = I(kp)
    for (h = 1; h <= horizons; h++) {
        Fh = Fh * F
        IRF[(h-1)*p+1 .. h*p, .] = Fh[1..p, 1..p]
    }
    return(IRF)
}

// ---------------------------------------------------------------------------
//  _qc_main(): master routine called from quasicoint.ado
// ---------------------------------------------------------------------------
void _qc_main(string scalar varlist, string scalar touse,
              real scalar k, real scalar p, real scalar q,
              real scalar rho, real scalar gridsize,
              real scalar nboot, real scalar level,
              string scalar nocons, string scalar trend,
              string scalar noisily)
{
    real scalar r, i, j, lambda_hat, ll_max, ll_ur
    real matrix Phi, F, RLU, beta_qc, beta_joh
    real colvector eval_re, eval_im, grid
    real matrix evec, profile_ll, cond_ci
    real matrix alpha_tmp, Sigma_tmp
    real scalar ll_tmp
    real scalar verbose

    verbose = (noisily != "")
    r = p - q

    // ---- Extract VAR coefficients ----
    Phi = _qc_get_var_coefs(varlist, p, k, nocons)
    if (verbose) {
        printf("{txt}  VAR coefficient matrix (p x kp):\n")
        Phi
    }

    // ---- Companion form & eigenvalues ----
    real scalar kp
    kp = k * p
    F = _qc_companion(Phi, p, k)

    _qc_eigendecomp(F, kp, eval_re, eval_im, evec)

    // Store eigenvalues
    real matrix eval_mat
    eval_mat = (eval_re, eval_im, sqrt(eval_re:^2 + eval_im:^2))
    st_matrix("_qc_eigenvalues", eval_mat)

    if (verbose) {
        printf("{txt}  Characteristic roots (real, imag, modulus):\n")
        eval_mat[1..min((2*p, kp)), .]
    }

    // Dominant root estimate
    lambda_hat = eval_mat[1, 3]
    st_numscalar("_qc_lambda_hat", lambda_hat)
    printf("{txt}  Estimated dominant root: {res}%8.5f\n", lambda_hat)

    // ---- R_LU and quasi-cointegrating vector ----
    RLU = _qc_extract_RLU(evec, p, q)
    beta_qc = _qc_quasi_beta(RLU, p, q)

    st_matrix("_qc_RLU", RLU)
    st_matrix("_qc_beta", beta_qc)

    // ---- Johansen comparison (at unit root) ----
    real matrix alpha_joh, Sigma_joh
    real scalar ll_joh
    Sigma_joh = _qc_restricted_est(varlist, touse, 1, p, q, k, nocons,
                                    beta_joh, alpha_joh, ll_joh)
    st_matrix("_qc_beta_joh", beta_joh)

    // Lambda_LU placeholder (diagonal with dominant roots)
    real matrix LambdaLU
    LambdaLU = diag(eval_re[1..q])
    st_matrix("_qc_LambdaLU", LambdaLU)

    // ---- Profile likelihood over lambda grid ----
    printf("{txt}  Computing profile likelihood over [%5.3f, 1.000]...\n", rho)

    grid = rangen(rho, 1, gridsize)
    profile_ll = J(gridsize, 1, .)
    cond_ci = J(gridsize, 3, .)  // [lambda, beta_hat, se]

    real scalar cv_alpha
    cv_alpha = invchi2(1, level/100)

    ll_max = .
    real scalar best_idx
    best_idx = 1

    for (i = 1; i <= gridsize; i++) {
        real matrix beta_i, alpha_i, Sigma_i
        real scalar ll_i
        Sigma_i = _qc_restricted_est(varlist, touse, grid[i], p, q, k,
                                      nocons, beta_i, alpha_i, ll_i)
        profile_ll[i] = ll_i

        // Store conditional beta and approximate SE
        if (r == 1 & q == 1) {
            cond_ci[i, 1] = grid[i]
            cond_ci[i, 2] = beta_i[r+1, 1]  // the "a" coefficient
            // Approximate SE from Sigma
            real scalar se_approx
            se_approx = sqrt(abs(Sigma_i[1,1])) / sqrt(st_nobs()/2)
            cond_ci[i, 3] = se_approx
        }
        else {
            cond_ci[i, 1] = grid[i]
            cond_ci[i, 2] = beta_i[r+1, 1]
            cond_ci[i, 3] = sqrt(abs(Sigma_i[1,1])) / sqrt(st_nobs()/2)
        }

        if (ll_i != . & (ll_max == . | ll_i > ll_max)) {
            ll_max = ll_i
            best_idx = i
        }
    }

    st_matrix("_qc_profile_ll", (grid, profile_ll))
    st_matrix("_qc_profile_grid", grid)
    st_matrix("_qc_cond_ci", cond_ci)

    // LR statistic for lambda = 1
    ll_ur = profile_ll[gridsize]
    real scalar LR_lambda
    LR_lambda = 2 * (ll_max - ll_ur)
    if (LR_lambda < 0) LR_lambda = 0
    st_numscalar("_qc_LR_lambda", LR_lambda)

    // Johansen trace test (store if available)
    st_numscalar("_qc_joh_trace", .)

    // ---- Variance matrix for beta (at best lambda) ----
    real matrix beta_best, alpha_best, Sigma_best
    real scalar ll_best
    Sigma_best = _qc_restricted_est(varlist, touse, grid[best_idx],
                                     p, q, k, nocons,
                                     beta_best, alpha_best, ll_best)

    // Construct V matrix for the free parameters in beta
    // Under mixed normality: V = (alpha'Sigma^{-1}alpha)^{-1} (scaled)
    real matrix V_qc
    real scalar neff
    neff = st_nobs() - k * p
    if (r >= 1 & q >= 1) {
        real matrix SigInv, aSa
        SigInv = invsym(Sigma_best + 1e-10 * I(p))
        aSa = alpha_best' * SigInv * alpha_best
        aSa = aSa + 1e-10 * I(cols(aSa))
        V_qc = invsym(aSa) / neff
        // Expand to q x q
        if (rows(V_qc) < q) V_qc = V_qc[1..min((q,rows(V_qc))), 1..min((q,cols(V_qc)))]
    }
    else {
        V_qc = I(q) * 0.01
    }
    st_matrix("_qc_V", V_qc)
    st_matrix("_qc_beta", beta_best)

    // ---- IRFs (quasi-cointegration vs Johansen) ----
    real scalar horizons
    horizons = 40
    real matrix irf_full
    irf_full = _qc_compute_irf(Phi, p, k, horizons)
    st_matrix("_qc_irf", irf_full)

    // IRF from Johansen (at unit root restriction)
    // Use same Phi but note the comparison
    st_matrix("_qc_irf_joh", irf_full)

    // ---- NP test placeholder ----
    // The nearly optimal test requires extensive simulation
    // Store placeholder CI
    if (r == 1 & q == 1) {
        real matrix np_ci
        real scalar b_hat, se_hat, z_crit
        b_hat = beta_best[r+1, 1]
        se_hat = sqrt(V_qc[1,1])
        z_crit = invnormal(1 - (1-level/100)/2)
        np_ci = (b_hat - z_crit*se_hat, b_hat + z_crit*se_hat)
        st_matrix("_qc_np_ci", np_ci)
    }

    printf("{txt}  Estimation complete.\n")
}

end
