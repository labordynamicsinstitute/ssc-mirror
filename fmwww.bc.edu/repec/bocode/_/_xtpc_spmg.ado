*! _xtpc_spmg v1.1.0 — System Pooled Mean Group (SPMG) Estimator
*! Direct translation of sPMGeHR.m / sPMGebinferenceHR.m
*! Chudik, Pesaran & Smith (2023), WP 415
*! Author: Dr. Merwan Roudane

program define _xtpc_spmg, eclass
    version 14.0
    syntax varlist(min=2 max=2) [if] [in], ///
        [Lags(integer 2) MAXiter(integer 500) PRECision(real 1e-4) ///
         BOOTstrap(integer 0) SEED(integer 1234)]

    _xt, trequired
    local panelvar "`r(ivar)'"
    local timevar  "`r(tvar)'"

    marksample touse
    markout `touse' `panelvar' `timevar'

    tokenize `varlist'
    local depvar   "`1'"
    local indepvar "`2'"

    // Verify balanced panel
    qui xtdescribe if `touse'
    if r(min) != r(max) {
        di as error "xtpanelcoint spmg requires a strongly balanced panel"
        exit 498
    }

    tempname b V theta se tval pval ci_lo ci_hi ///
             boot_lo boot_hi niter conv

    mata: _xtpc_spmg_run("`depvar'", "`indepvar'", "`panelvar'", ///
        "`timevar'", "`touse'", `lags', `maxiter', `precision', ///
        `bootstrap', `seed')

    // Post results with proper b and V for estimates store
    tempname bb VV
    matrix `bb' = (`theta')
    matrix colnames `bb' = theta
    matrix `VV' = (`se'^2)
    matrix colnames `VV' = theta
    matrix rownames `VV' = theta

    ereturn post `bb' `VV', esample(`touse')
    ereturn local cmd            "xtpanelcoint"
    ereturn local estimator      "System PMG (SPMG)"
    ereturn local estimator_type "spmg"
    ereturn local depvar         "`depvar'"
    ereturn local indepvar       "`indepvar'"
    ereturn scalar theta         = `theta'
    ereturn scalar se            = `se'
    ereturn scalar t_ratio       = `tval'
    ereturn scalar p_value       = `pval'
    ereturn scalar ci95_lo       = `ci_lo'
    ereturn scalar ci95_hi       = `ci_hi'
    ereturn scalar boot_ci_lo    = `boot_lo'
    ereturn scalar boot_ci_hi    = `boot_hi'
    ereturn scalar boot_reps     = `bootstrap'
    ereturn scalar N_g           = scalar(_xtpc_N)
    ereturn scalar T             = scalar(_xtpc_T)
    ereturn scalar lags          = `lags'
    ereturn scalar n_iter        = `niter'
    ereturn scalar converged     = `conv'

    cap scalar drop _xtpc_N _xtpc_T

    _xtpc_display
end

// ═══════════════════════════════════════════════════════════════════════════════
// Mata implementation
// ═══════════════════════════════════════════════════════════════════════════════
mata:
mata set matastrict off

void _xtpc_spmg_run(string scalar depvar, string scalar indepvar,
                     string scalar panelvar, string scalar timevar,
                     string scalar touse,
                     real scalar p, real scalar maxiter,
                     real scalar precision, real scalar bootreps,
                     real scalar seed)
{
    real matrix Y, X, phi, sigi2, Hi, dzi, ex
    real scalar _T, n, beta, beta_new, Tp, i, j, niter, converged
    real scalar theta, se, tval, pval, z95, d, denom
    real colvector exi, dyi, dxi, Xi
    real rowvector phi_i
    real matrix iSi
    real scalar A, b_val

    // ─── Extract panel data ──────────────────────────────────────────────
    _xtpc_extract_panel(depvar, indepvar, panelvar, timevar, touse, Y, X, _T, n)

    Tp = _T - p

    // ─── Step 0: Engle-Granger initial estimate ──────────────────────────
    beta = _xtpc_eg_init(Y, X)

    // Lagged levels: y_{t-1}, x_{t-1}  (rows p..T-1 in 1-indexed)
    y_ = Y[p..(_T-1), .]
    x_ = X[p..(_T-1), .]

    // ─── Step 1: Initial phi_i (2x1) and Sigma_i (2x2) ──────────────────
    ex = y_ - beta * x_
    phi  = J(n, 2, 0)
    sigi2 = J(2*n, 2, 0)  // store n 2x2 matrices stacked

    for (i = 1; i <= n; i++) {
        Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        exi = ex[., i]
        dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
        dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
        dzi = (dyi, dxi)
        denom = exi' * Hi * exi
        if (abs(denom) > 1e-15) {
            phi[i, .] = (exi' * Hi * dzi) / denom
        }
        resid = dzi - exi * phi[i, .]
        sigi2[(2*i-1)..(2*i), .] = (resid' * Hi * resid) / Tp
    }

    // ─── Step 2: Iterate until convergence ───────────────────────────────
    converged = 0
    niter = 0

    while (niter < maxiter & !converged) {
        // Update theta
        A = 0
        b_val = 0
        for (i = 1; i <= n; i++) {
            Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
            Xi  = x_[., i]
            iSi = luinv(sigi2[(2*i-1)..(2*i), .])
            phi_iSi_phi = phi[i, .] * iSi * phi[i, .]'
            A = A + (-phi_iSi_phi) * (Xi' * Hi * Xi)

            dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
            dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
            dzi = (dyi, dxi)
            b_val = b_val + Xi' * Hi * (dzi - y_[., i] * phi[i, .]) * iSi * phi[i, .]'
        }
        beta_new = (abs(A) > 1e-15 ? b_val / A : beta)

        // Update phi_i and Sigma_i
        ex = y_ - beta_new * x_
        phi  = J(n, 2, 0)
        sigi2 = J(2*n, 2, 0)

        for (i = 1; i <= n; i++) {
            Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
            exi = ex[., i]
            dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
            dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
            dzi = (dyi, dxi)
            denom = exi' * Hi * exi
            if (abs(denom) > 1e-15) {
                phi[i, .] = (exi' * Hi * dzi) / denom
            }
            resid = dzi - exi * phi[i, .]
            sigi2[(2*i-1)..(2*i), .] = (resid' * Hi * resid) / Tp
        }

        converged = (abs(beta_new - beta) < precision)
        beta = beta_new
        niter++
    }

    theta = beta

    // ─── Step 3: Asymptotic standard error ───────────────────────────────
    d = 0
    for (i = 1; i <= n; i++) {
        Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        Xi  = x_[., i]
        iSi = luinv(sigi2[(2*i-1)..(2*i), .])
        d = d + (phi[i, .] * iSi * phi[i, .]') * (Xi' * Hi * Xi)
    }
    se = (d > 0 ? sqrt(1/d) : .)

    tval = (se < . & se > 0 ? (theta - 1) / se : .)
    pval = (tval < . ? 2 * normal(-abs(tval)) : .)
    z95  = invnormal(0.975)

    // ─── Step 4: Bootstrap (optional) ────────────────────────────────────
    boot_lo = .
    boot_hi = .
    if (bootreps > 0) {
        _xtpc_spmg_bootstrap(Y, X, theta, phi, sigi2, p, _T, n, Tp,
                              maxiter, precision, bootreps, seed,
                              boot_lo, boot_hi)
    }

    // ─── Return to Stata ─────────────────────────────────────────────────
    st_numscalar("_xtpc_N", n)
    st_numscalar("_xtpc_T", _T)

    stata("scalar " + st_local("theta")   + " = " + strofreal(theta, "%21.15g"))
    stata("scalar " + st_local("se")      + " = " + strofreal(se, "%21.15g"))
    stata("scalar " + st_local("tval")    + " = " + strofreal(tval, "%21.15g"))
    stata("scalar " + st_local("pval")    + " = " + strofreal(pval, "%21.15g"))
    stata("scalar " + st_local("ci_lo")   + " = " + strofreal(theta - z95*se, "%21.15g"))
    stata("scalar " + st_local("ci_hi")   + " = " + strofreal(theta + z95*se, "%21.15g"))
    stata("scalar " + st_local("boot_lo") + " = " + strofreal(boot_lo, "%21.15g"))
    stata("scalar " + st_local("boot_hi") + " = " + strofreal(boot_hi, "%21.15g"))
    stata("scalar " + st_local("niter")   + " = " + strofreal(niter))
    stata("scalar " + st_local("conv")    + " = " + strofreal(converged))
}

// ─── SPMG Wild Bootstrap ─────────────────────────────────────────────────────
void _xtpc_spmg_bootstrap(real matrix Y, real matrix X,
                            real scalar theta0,
                            real matrix phi, real matrix sigi2,
                            real scalar p, real scalar _T,
                            real scalar n, real scalar Tp,
                            real scalar maxiter, real scalar precision,
                            real scalar bootreps, real scalar seed,
                            real scalar boot_lo, real scalar boot_hi)
{
    real matrix Y_boot, X_boot, resid_y, resid_x
    real colvector kappa, boot_t
    real scalar b, i, t, t_idx, eps_y, eps_x
    real scalar d_boot, se_boot
    real scalar theta_b, se_b, conv_b

    rseed(seed)

    // Compute residuals under H0: theta = theta0
    y_ = Y[p..(_T-1), .]
    x_ = X[p..(_T-1), .]
    ex = y_ - theta0 * x_

    resid_y = J(Tp, n, 0)
    resid_x = J(Tp, n, 0)

    for (i = 1; i <= n; i++) {
        Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        exi = ex[., i]
        dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
        dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
        dzi = (dyi, dxi)
        fitted = exi * phi[i, .]
        resid_y[., i] = dyi - fitted[., 1]
        resid_x[., i] = dxi - fitted[., 2]
    }

    boot_t = J(0, 1, .)

    for (b = 1; b <= bootreps; b++) {
        // Rademacher weights
        kappa = (2 * (runiform(Tp, 1) :> 0.5)) :- 1

        Y_boot = Y
        X_boot = X

        for (i = 1; i <= n; i++) {
            for (t = p+1; t <= _T; t++) {
                t_idx = t - p
                eps_y = kappa[t_idx] * resid_y[t_idx, i]
                eps_x = kappa[t_idx] * resid_x[t_idx, i]
                ecm = Y_boot[t-1, i] - theta0 * X_boot[t-1, i]
                Y_boot[t, i] = Y_boot[t-1, i] + phi[i, 1] * ecm + eps_y
                X_boot[t, i] = X_boot[t-1, i] + phi[i, 2] * ecm + eps_x
            }
        }

        // Re-estimate on bootstrap sample
        _xtpc_spmg_core(Y_boot, X_boot, p, maxiter, precision,
                         theta_b, se_b, conv_b)

        if (conv_b & se_b > 0 & se_b < .) {
            boot_t = boot_t \ ((theta_b - theta0) / se_b)
        }
    }

    if (rows(boot_t) < 10) {
        boot_lo = .
        boot_hi = .
        return
    }

    // 95th percentile of |t*|
    q975 = _xtpc_percentile(abs(boot_t), 95)

    // Original SE
    d_boot = 0
    for (i = 1; i <= n; i++) {
        Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        Xi  = x_[., i]
        iSi = luinv(sigi2[(2*i-1)..(2*i), .])
        d_boot = d_boot + (phi[i, .] * iSi * phi[i, .]') * (Xi' * Hi * Xi)
    }
    se_boot = (d_boot > 0 ? sqrt(1/d_boot) : .)

    boot_lo = theta0 - q975 * se_boot
    boot_hi = theta0 + q975 * se_boot
}

// ─── Core SPMG estimator (no bootstrap, used by bootstrap loop) ──────────────
void _xtpc_spmg_core(real matrix Y, real matrix X,
                      real scalar p, real scalar maxiter,
                      real scalar precision,
                      real scalar theta, real scalar se, real scalar conv)
{
    real scalar _T, n, Tp, beta, beta_new, niter, d, denom
    real matrix phi, sigi2, ex, Hi, dzi
    real colvector exi, dyi, dxi, Xi
    real scalar A, b_val

    _T = rows(Y)
    n  = cols(Y)
    Tp = _T - p

    beta = _xtpc_eg_init(Y, X)
    y_ = Y[p..(_T-1), .]
    x_ = X[p..(_T-1), .]

    ex   = y_ - beta * x_
    phi  = J(n, 2, 0)
    sigi2 = J(2*n, 2, 0)

    for (i = 1; i <= n; i++) {
        Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        exi = ex[., i]
        dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
        dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
        dzi = (dyi, dxi)
        denom = exi' * Hi * exi
        if (abs(denom) > 1e-15) phi[i, .] = (exi' * Hi * dzi) / denom
        resid = dzi - exi * phi[i, .]
        sigi2[(2*i-1)..(2*i), .] = (resid' * Hi * resid) / Tp
    }

    conv = 0
    niter = 0
    while (niter < maxiter & !conv) {
        A = 0; b_val = 0
        for (i = 1; i <= n; i++) {
            Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
            Xi  = x_[., i]
            iSi = luinv(sigi2[(2*i-1)..(2*i), .])
            A = A + (-(phi[i, .] * iSi * phi[i, .]')) * (Xi' * Hi * Xi)
            dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
            dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
            dzi = (dyi, dxi)
            b_val = b_val + Xi' * Hi * (dzi - y_[., i] * phi[i, .]) * iSi * phi[i, .]'
        }
        beta_new = (abs(A) > 1e-15 ? b_val / A : beta)

        ex = y_ - beta_new * x_
        phi  = J(n, 2, 0)
        sigi2 = J(2*n, 2, 0)
        for (i = 1; i <= n; i++) {
            Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
            exi = ex[., i]
            dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
            dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
            dzi = (dyi, dxi)
            denom = exi' * Hi * exi
            if (abs(denom) > 1e-15) phi[i, .] = (exi' * Hi * dzi) / denom
            resid = dzi - exi * phi[i, .]
            sigi2[(2*i-1)..(2*i), .] = (resid' * Hi * resid) / Tp
        }
        conv = (abs(beta_new - beta) < precision)
        beta = beta_new
        niter++
    }

    theta = beta
    d = 0
    for (i = 1; i <= n; i++) {
        Hi  = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        Xi  = x_[., i]
        iSi = luinv(sigi2[(2*i-1)..(2*i), .])
        d = d + (phi[i, .] * iSi * phi[i, .]') * (Xi' * Hi * Xi)
    }
    se = (d > 0 ? sqrt(1/d) : .)
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared helper functions
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Extract balanced panel into T×n matrices ────────────────────────────────
void _xtpc_extract_panel(string scalar depvar, string scalar indepvar,
                          string scalar panelvar, string scalar timevar,
                          string scalar touse,
                          real matrix Y, real matrix X,
                          real scalar _T, real scalar n)
{
    real colvector pid, tid, yy, xx
    real colvector panels, times, sel
    real scalar i

    st_view(pid, ., panelvar, touse)
    st_view(tid, ., timevar, touse)
    st_view(yy,  ., depvar,  touse)
    st_view(xx,  ., indepvar, touse)

    panels = uniqrows(pid)
    times  = uniqrows(tid)
    n  = rows(panels)
    _T = rows(times)

    Y = J(_T, n, .)
    X = J(_T, n, .)

    for (i = 1; i <= n; i++) {
        sel = selectindex(pid :== panels[i])
        Y[., i] = yy[sel]
        X[., i] = xx[sel]
    }
}

// ─── Pooled Engle-Granger FE initial estimator ──────────────────────────────
real scalar _xtpc_eg_init(real matrix Y, real matrix X)
{
    real scalar _T, n, i
    real matrix tau, Mh
    real scalar A, B

    _T = rows(Y)
    n  = cols(Y)
    tau = J(_T, 1, 1)
    Mh  = I(_T) - tau * invsym(tau' * tau) * tau'
    A = 0; B = 0
    for (i = 1; i <= n; i++) {
        A = A + X[., i]' * Mh * X[., i]
        B = B + X[., i]' * Mh * Y[., i]
    }
    return(B / A)
}

// ─── Projection matrix: regular (PMG) ────────────────────────────────────────
// W_i = [dX_{p lags}, dY_{p-1 lags}, 1]
real matrix _xtpc_get_Hi(real scalar i, real scalar _T, real scalar p,
                          real matrix X, real matrix Y)
{
    real scalar Tp, j
    real matrix Wi
    real colvector dv

    Tp = _T - p
    Wi = J(Tp, 0, .)

    // p X-lags: j = 1, ..., p
    for (j = 1; j <= p; j++) {
        dv = X[(p-j+2)..(_T-j+1), i] - X[(p-j+1)..(_T-j), i]
        Wi = (Wi, dv[1..Tp])
    }
    // (p-1) Y-lags: j = 2, ..., p
    for (j = 2; j <= p; j++) {
        dv = Y[(p-j+2)..(_T-j+1), i] - Y[(p-j+1)..(_T-j), i]
        Wi = (Wi, dv[1..Tp])
    }
    Wi = (Wi, J(Tp, 1, 1))
    return(I(Tp) - Wi * invsym(Wi' * Wi) * Wi')
}

// ─── Projection matrix: system (SPMG, Breitung) ─────────────────────────────
// W_i = [dX_{p-1 lags}, dY_{p-1 lags}, 1]  (j=2:p)
real matrix _xtpc_get_Hi_sys(real scalar i, real scalar _T, real scalar p,
                              real matrix X, real matrix Y)
{
    real scalar Tp, j
    real matrix Wi
    real colvector dv

    Tp = _T - p
    Wi = J(Tp, 0, .)

    // (p-1) X-lags: j = 2, ..., p
    for (j = 2; j <= p; j++) {
        dv = X[(p-j+2)..(_T-j+1), i] - X[(p-j+1)..(_T-j), i]
        Wi = (Wi, dv[1..Tp])
    }
    // (p-1) Y-lags: j = 2, ..., p
    for (j = 2; j <= p; j++) {
        dv = Y[(p-j+2)..(_T-j+1), i] - Y[(p-j+1)..(_T-j), i]
        Wi = (Wi, dv[1..Tp])
    }
    Wi = (Wi, J(Tp, 1, 1))
    return(I(Tp) - Wi * invsym(Wi' * Wi) * Wi')
}

// ─── Percentile function ─────────────────────────────────────────────────────
real scalar _xtpc_percentile(real colvector x, real scalar pct)
{
    real colvector sx
    real scalar idx
    sx = sort(x, 1)
    idx = ceil(rows(sx) * pct / 100)
    if (idx < 1) idx = 1
    if (idx > rows(sx)) idx = rows(sx)
    return(sx[idx])
}

end
