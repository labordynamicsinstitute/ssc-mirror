*! _xtpc_mgmw v1.1.0 — Müller-Watson Mean Group (MGMW) Estimator
*! Translated from pMWqfixedd.m
*! Author: Dr. Merwan Roudane

program define _xtpc_mgmw, eclass
    version 14.0
    syntax varlist(min=2 max=2) [if] [in], [SUBperiods(integer 5)]

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
        di as error "xtpanelcoint mgmw requires a strongly balanced panel"
        exit 498
    }

    tempname theta se tval pval ci_lo ci_hi

    mata: _xtpc_mgmw_run("`depvar'", "`indepvar'", "`panelvar'", ///
        "`timevar'", "`touse'", `subperiods')

    tempname bb VV
    matrix `bb' = (`theta')
    matrix colnames `bb' = theta
    matrix `VV' = (`se'^2)
    matrix colnames `VV' = theta
    matrix rownames `VV' = theta

    ereturn post `bb' `VV', esample(`touse')
    ereturn local cmd            "xtpanelcoint"
    ereturn local estimator      "MGMW (q=`subperiods')"
    ereturn local estimator_type "mgmw"
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
    ereturn scalar lags          = `subperiods'
    ereturn scalar n_iter        = 0
    ereturn scalar converged     = 1

    cap scalar drop _xtpc_N _xtpc_T
    _xtpc_display
end

mata:
mata set matastrict off

void _xtpc_mgmw_run(string scalar depvar, string scalar indepvar,
                      string scalar panelvar, string scalar timevar,
                      string scalar touse, real scalar q)
{
    real matrix Y, X, yh, xh, tau, Mh
    real scalar _T, n, i, j, h, m, M_agg, theta, se, tval, pval, z95
    real scalar A, B, Q, d

    _xtpc_extract_panel(depvar, indepvar, panelvar, timevar, touse, Y, X, _T, n)

    // Temporal aggregation: q sub-periods, each of length m = floor(T/q)
    h = q                   // number of sub-periods (fixed as q)
    m = floor(_T / h)       // observations per sub-period

    // Aggregate: n x h matrices
    yh = J(n, h, 0)
    xh = J(n, h, 0)
    for (j = 1; j <= h; j++) {
        t1 = (j - 1) * m + 1
        t2 = j * m
        for (i = 1; i <= n; i++) {
            yh[i, j] = mean(Y[t1..t2, i])
            xh[i, j] = mean(X[t1..t2, i])
        }
    }

    // Projection: demean
    tau = J(h, 1, 1)
    Mh  = I(h) - tau * invsym(tau' * tau) * tau'

    A = 0; B = 0
    for (i = 1; i <= n; i++) {
        xi = xh[i, .]'   // column vector h x 1
        yi = yh[i, .]'
        A = A + xi' * Mh * xi
        B = B + xi' * Mh * yi
    }

    Q = (A != 0 ? 1 / A : .)
    theta = Q * B

    // Robust SE
    d = 0
    for (i = 1; i <= n; i++) {
        xi = xh[i, .]'
        yi = yh[i, .]'
        ui = yi - theta * xi
        d = d + (xi' * Mh * ui) * (ui' * Mh * xi)
    }
    se = (Q < . ? sqrt(Q^2 * d) : .)

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
