*! _xtpc_breitung v1.1.0 — Breitung (2005) Two-Step Estimator
*! Translated from Breitung_es.m
*! Reference: Breitung (2005), Econometric Reviews 24, 151-173
*! Author: Dr. Merwan Roudane

program define _xtpc_breitung, eclass
    version 14.0
    syntax varlist(min=2 max=2) [if] [in], [Lags(integer 2)]

    _xt, trequired
    local panelvar "`r(ivar)'"
    local timevar  "`r(tvar)'"

    marksample touse
    markout `touse' `panelvar' `timevar'

    tokenize `varlist'
    local depvar   "`1'"
    local indepvar "`2'"

    qui xtdescribe if `touse'
    if r(min) != r(max) {
        di as error "xtpanelcoint breitung requires a strongly balanced panel"
        exit 498
    }

    tempname theta se tval pval ci_lo ci_hi

    mata: _xtpc_breitung_run("`depvar'", "`indepvar'", "`panelvar'", ///
        "`timevar'", "`touse'", `lags')

    tempname bb VV
    matrix `bb' = (`theta')
    matrix colnames `bb' = theta
    matrix `VV' = (`se'^2)
    matrix colnames `VV' = theta
    matrix rownames `VV' = theta

    ereturn post `bb' `VV', esample(`touse')
    ereturn local cmd            "xtpanelcoint"
    ereturn local estimator      "Breitung (2005) Two-Step"
    ereturn local estimator_type "breitung"
    ereturn local depvar         "`depvar'"
    ereturn local indepvar       "`indepvar'"
    ereturn scalar theta         = `theta'
    ereturn scalar se            = `se'
    ereturn scalar t_ratio       = `tval'
    ereturn scalar p_value       = `pval'
    ereturn scalar ci95_lo       = `ci_lo'
    ereturn scalar ci95_hi       = `ci_hi'
    ereturn scalar boot_ci_lo    = .
    ereturn scalar boot_ci_hi    = .
    ereturn scalar boot_reps     = 0
    ereturn scalar N_g           = scalar(_xtpc_N)
    ereturn scalar T             = scalar(_xtpc_T)
    ereturn scalar lags          = `lags'
    ereturn scalar n_iter        = 0
    ereturn scalar converged     = 1

    cap scalar drop _xtpc_N _xtpc_T
    _xtpc_display
end

mata:
mata set matastrict off

void _xtpc_breitung_run(string scalar depvar, string scalar indepvar,
                         string scalar panelvar, string scalar timevar,
                         string scalar touse, real scalar p)
{
    real matrix Y, X, Hi, Sig, dzi, reg, u
    real scalar _T, n, Tp, i, j, theta, se, tval, pval, z95
    real colvector beta_i, dyi, dxi, exi, b_eg, b_y, b_x, uy, ux
    real matrix alpha_i
    real scalar A, b_val, om, d_robust

    _xtpc_extract_panel(depvar, indepvar, panelvar, timevar, touse, Y, X, _T, n)
    Tp = _T - p

    // ─── Step 1: Unit-by-unit Engle-Granger ──────────────────────────────
    beta_i  = J(n, 1, 0)
    alpha_i = J(n, 2, 0)
    Sig     = J(2, 2*n, 0)  // store n 2x2 matrices side-by-side

    for (i = 1; i <= n; i++) {
        // EG regression: y_i = b*x_i + c + e_i
        reg = (X[., i], J(_T, 1, 1))
        b_eg = invsym(reg' * reg) * reg' * Y[., i]
        beta_i[i] = b_eg[1]
        exi = Y[., i] - reg * b_eg

        // Build short-run dynamics regressors
        cols = exi[p..(_T-1)]
        for (j = 2; j <= p; j++) {
            dv = Y[(p-j+2)..(_T-j+1), i] - Y[(p-j+1)..(_T-j), i]
            cols = (cols, dv[1..Tp])
        }
        for (j = 2; j <= p; j++) {
            dv = X[(p-j+2)..(_T-j+1), i] - X[(p-j+1)..(_T-j), i]
            cols = (cols, dv[1..Tp])
        }
        cols = (cols, J(Tp, 1, 1))

        // y equation
        dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
        b_y = invsym(cols' * cols) * cols' * dyi
        uy = dyi - cols * b_y
        alpha_i[i, 1] = b_y[1]

        // x equation
        dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
        b_x = invsym(cols' * cols) * cols' * dxi
        ux = dxi - cols * b_x
        alpha_i[i, 2] = b_x[1]

        u = (uy, ux)
        Sig[., (2*i-1)..(2*i)] = u' * u / (_T - 1 - p)
    }

    // ─── Step 2: Pooled regression on z+ ─────────────────────────────────
    y_ = Y[p..(_T-1), .]
    x_ = X[p..(_T-1), .]

    A = 0; b_val = 0

    for (i = 1; i <= n; i++) {
        Hi   = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        iSig = luinv(Sig[., (2*i-1)..(2*i)])
        ia   = 1 / (alpha_i[i, .] * iSig * alpha_i[i, .]')

        dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
        dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
        dyb = Hi * (dyi, dxi)
        ymb = Hi * y_[., i]
        zplus = dyb * (ia * iSig * alpha_i[i, .]') - ymb
        y2  = Hi * x_[., i]

        A     = A + y2' * y2
        b_val = b_val + y2' * zplus
    }

    theta = (abs(A) > 1e-15 ? -(b_val / A) : 0)

    // ─── Heteroskedasticity-robust SE ────────────────────────────────────
    d_robust = 0; om = 0
    for (i = 1; i <= n; i++) {
        Hi   = _xtpc_get_Hi_sys(i, _T, p, X, Y)
        iSig = luinv(Sig[., (2*i-1)..(2*i)])
        ia   = 1 / (alpha_i[i, .] * iSig * alpha_i[i, .]')

        dyi = Y[(p+1).._T, i] - Y[p..(_T-1), i]
        dxi = X[(p+1).._T, i] - X[p..(_T-1), i]
        dyb = Hi * (dyi, dxi)
        ymb = Hi * y_[., i]
        zplus = dyb * (ia * iSig * alpha_i[i, .]') - ymb
        y2  = Hi * x_[., i]
        vi  = zplus + theta * y2
        om  = om + y2' * y2
        d_robust = d_robust + (vi' * vi / (Tp - 1)) * (y2' * y2)
    }

    se = (om > 0 ? sqrt(d_robust / om^2) : .)
    tval = (se > 0 & se < . ? (theta - 1) / se : .)
    pval = (tval < . ? 2 * normal(-abs(tval)) : .)
    z95  = invnormal(0.975)

    st_numscalar("_xtpc_N", n)
    st_numscalar("_xtpc_T", _T)
    stata("scalar " + st_local("theta") + " = " + strofreal(theta, "%21.15g"))
    stata("scalar " + st_local("se")    + " = " + strofreal(se, "%21.15g"))
    stata("scalar " + st_local("tval")  + " = " + strofreal(tval, "%21.15g"))
    stata("scalar " + st_local("pval")  + " = " + strofreal(pval, "%21.15g"))
    stata("scalar " + st_local("ci_lo") + " = " + strofreal(theta - z95*se, "%21.15g"))
    stata("scalar " + st_local("ci_hi") + " = " + strofreal(theta + z95*se, "%21.15g"))
}

// Shared helpers (duplicated for standalone loading)
void _xtpc_extract_panel(string scalar depvar, string scalar indepvar,
                          string scalar panelvar, string scalar timevar,
                          string scalar touse,
                          real matrix Y, real matrix X,
                          real scalar _T, real scalar n)
{
    real colvector pid, tid, yy, xx, panels, times, sel
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

real matrix _xtpc_get_Hi_sys(real scalar i, real scalar _T, real scalar p,
                              real matrix X, real matrix Y)
{
    real scalar Tp, j
    real matrix Wi
    real colvector dv
    Tp = _T - p
    Wi = J(Tp, 0, .)
    for (j = 2; j <= p; j++) {
        dv = X[(p-j+2)..(_T-j+1), i] - X[(p-j+1)..(_T-j), i]
        Wi = (Wi, dv[1..Tp])
    }
    for (j = 2; j <= p; j++) {
        dv = Y[(p-j+2)..(_T-j+1), i] - Y[(p-j+1)..(_T-j), i]
        Wi = (Wi, dv[1..Tp])
    }
    Wi = (Wi, J(Tp, 1, 1))
    return(I(Tp) - Wi * invsym(Wi' * Wi) * Wi')
}

end
