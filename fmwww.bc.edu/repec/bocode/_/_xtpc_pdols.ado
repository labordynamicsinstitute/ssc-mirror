*! _xtpc_pdols v1.1.0 — Panel Dynamic OLS (PDOLS)
*! Mark & Sul (2003). Translated from PDOLS_e.m
*! Author: Dr. Merwan Roudane

program define _xtpc_pdols, eclass
    version 14.0
    syntax varlist(min=2 max=2) [if] [in], [LEADSlags(integer 4)]

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
        di as error "xtpanelcoint pdols requires a strongly balanced panel"
        exit 498
    }

    tempname theta se tval pval ci_lo ci_hi

    mata: _xtpc_pdols_run("`depvar'", "`indepvar'", "`panelvar'", ///
        "`timevar'", "`touse'", `leadslags')

    tempname bb VV
    matrix `bb' = (`theta')
    matrix colnames `bb' = theta
    matrix `VV' = (`se'^2)
    matrix colnames `VV' = theta
    matrix rownames `VV' = theta

    ereturn post `bb' `VV', esample(`touse')
    ereturn local cmd            "xtpanelcoint"
    ereturn local estimator      "PDOLS (q=`leadslags')"
    ereturn local estimator_type "pdols"
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
    ereturn scalar lags          = `leadslags'
    ereturn scalar n_iter        = 0
    ereturn scalar converged     = 1

    cap scalar drop _xtpc_N _xtpc_T
    _xtpc_display
end

mata:
mata set matastrict off

void _xtpc_pdols_run(string scalar depvar, string scalar indepvar,
                      string scalar panelvar, string scalar timevar,
                      string scalar touse, real scalar q)
{
    real matrix Y, X, DX, DX_dm, M
    real scalar _T, n, T_eff, i, j, theta, se, tval, pval, z95
    real scalar A, b_val, d2
    real colvector dx, yi, xi, yi_dm, xi_dm, col, ei, xt
    real rowvector idx_r

    _xtpc_extract_panel(depvar, indepvar, panelvar, timevar, touse, Y, X, _T, n)

    T_eff = _T - 2*q
    A = 0; b_val = 0

    for (i = 1; i <= n; i++) {
        dx = X[2.._T, i] - X[1..(_T-1), i]  // diff(X[:,i])

        // Build leads/lags matrix of dX
        DX = J(T_eff, 2*q + 1, 0)
        for (j = -q; j <= q; j++) {
            col = J(T_eff, 1, 0)
            for (t = 1; t <= T_eff; t++) {
                idx = q + t + j   // 1-indexed into dx
                if (idx >= 1 & idx <= rows(dx)) {
                    col[t] = dx[idx]
                }
            }
            DX[., j + q + 1] = col
        }

        yi = Y[(q+1)..(q+T_eff), i]
        xi = X[(q+1)..(q+T_eff), i]
        yi_dm = yi :- mean(yi)
        xi_dm = xi :- mean(xi)
        DX_dm = DX :- mean(DX)

        M = I(T_eff) - DX_dm * invsym(DX_dm' * DX_dm) * DX_dm'
        A     = A + (M * xi_dm)' * (M * xi_dm)
        b_val = b_val + (M * xi_dm)' * (M * yi_dm)
    }

    theta = (abs(A) > 1e-15 ? b_val / A : 0)

    // Robust SE
    d2 = 0
    for (i = 1; i <= n; i++) {
        dx = X[2.._T, i] - X[1..(_T-1), i]
        DX = J(T_eff, 2*q + 1, 0)
        for (j = -q; j <= q; j++) {
            col = J(T_eff, 1, 0)
            for (t = 1; t <= T_eff; t++) {
                idx = q + t + j
                if (idx >= 1 & idx <= rows(dx)) col[t] = dx[idx]
            }
            DX[., j + q + 1] = col
        }
        yi = Y[(q+1)..(q+T_eff), i]
        xi = X[(q+1)..(q+T_eff), i]
        DX_dm = DX :- mean(DX)
        M  = I(T_eff) - DX_dm * invsym(DX_dm' * DX_dm) * DX_dm'
        xt = M * (xi :- mean(xi))
        ei = M * (yi :- mean(yi)) - theta * xt
        d2 = d2 + (ei' * ei / T_eff) * (xt' * xt)
    }

    se   = (A > 0 ? sqrt(d2 / A^2) : .)
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

end
