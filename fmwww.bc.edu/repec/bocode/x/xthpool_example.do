*! xthpool_example.do  -- worked examples and Monte Carlo validation
*! Westerlund & Hess (2011) Hausman poolability test
*! Author: Merwan Roudane  (merwanroudane920@gmail.com)
*
*  Run AFTER the package is available, e.g.
*      net install xthpool, from("<folder>") replace
*  (or, when developing, run  do xthpool.ado  first).
*  We use  clear  (not clear all) so a just-loaded xthpool survives.

clear
set more off

*-------------------------------------------------------------------------------
* Data-generating process of Westerlund & Hess (2011), eqs (1)-(5)
*   y_it = alpha_i + beta_i * x_it + e_it        (cointegrated system)
*   x_it = x_{i,t-1} + v_it                       (unit-root regressor)   [DEFACT off]
*   x_it = gamma_i*g_t + w_it, w random walk      (common-factor regr.)   [DEFACT on]
*   e_it = lambda_i * f_t + u_it                  (common factor error)
* The common factors f_t (and g_t) are drawn ONCE and shared across units.
* Under H0: beta_i = 1 for all i (poolable).  Under H1: a fraction FRAC of the
* units get beta_i ~ U(0,1) (non-poolable), the rest stay at 1.
*-------------------------------------------------------------------------------
capture program drop simwh
program define simwh
    syntax , [ N(integer 10) T(integer 50) FRAC(real 0) DEFACT ENDOG(real 0) RHO(real 0) ]
    clear
    local NT = `n'*`t'
    quietly set obs `NT'
    gen long id = ceil(_n/`t')
    bysort id: gen long t = _n

    // factor loadings lambda_i, intercepts alpha_i (unit-specific, constant in t)
    bysort id (t): gen double lam = rnormal(1,1) if _n==1
    bysort id (t): replace lam = lam[1]
    bysort id (t): gen double alpha = rnormal() if _n==1
    bysort id (t): replace alpha = alpha[1]

    // common factor f_t : draw for the first unit, copy to all units at each t
    gen double f = rnormal() if id==1
    bysort t (id): replace f = f[1]

    // regressor innovation v and idiosyncratic error u.
    // ENDOG induces contemporaneous corr(u,v) (idiosyncratic endogeneity,
    // Delta_uv != 0) -> exercises the bias correction.  RHO adds AR(1) serial
    // correlation in u -> exercises the lagged part of the long-run covariance.
    gen double v = rnormal()
    gen double ue = `endog'*v + sqrt(1-`endog'^2)*rnormal()
    bysort id (t): gen double u = ue
    if (`rho' != 0) {
        // recursive AR(1) without needing tsset: u[_n-1] is the already-updated
        // previous period within each id (data are sorted by id then t)
        bysort id (t): replace u = `rho'*u[_n-1] + ue if _n>1
    }

    if ("`defact'" != "") {
        // observable common (stationary) factor g_t, shared across units
        bysort id (t): gen double gam = rnormal(1,1) if _n==1
        bysort id (t): replace gam = gam[1]
        gen double g = rnormal() if id==1
        bysort t (id): replace g = g[1]
        bysort id (t): gen double w = sum(v)
        gen double x = gam*g + w
    }
    else {
        bysort id (t): gen double x = sum(v)      // pure unit root
    }

    gen double e = lam*f + u

    // beta_i : first FRAC*N units non-poolable
    bysort id (t): gen double bdraw = runiform() if _n==1
    bysort id (t): replace bdraw = bdraw[1]
    gen double beta = cond(id <= `frac'*`n', bdraw, 1)

    gen double y = alpha + beta*x + e
    xtset id t
end

*===============================================================================
* 1. DEMONSTRATION -- single panel
*===============================================================================
di as txt _n "{hline 78}"
di as txt "1a. Poolable panel (H0 true, beta_i = 1 for all i): expect NO rejection"
di as txt "{hline 78}"
set seed 101
simwh, n(20) t(100) frac(0)
xthpool y x

di as txt _n "{hline 78}"
di as txt "1b. Non-poolable panel (H1, 30% of units have beta_i != 1): expect rejection"
di as txt "{hline 78}"
set seed 102
simwh, n(20) t(100) frac(0.3)
xthpool y x, graph name(demoH1)

di as txt _n "{hline 78}"
di as txt "1c. Iterative sequential-drop scheme on the non-poolable panel"
di as txt "{hline 78}"
xthpool y x, iterate

di as txt _n "{hline 78}"
di as txt "1d. Regressor driven by an observable common factor -> defactor(g)"
di as txt "{hline 78}"
set seed 103
simwh, n(20) t(100) frac(0.3) defact
di as txt "-- raw regressor (may be undersized):"
xthpool y x
di as txt "-- defactored on g:"
xthpool y x, defactor(g)

*===============================================================================
* 2. MONTE CARLO  -- size and power (vary the seed every replication)
*===============================================================================
local reps  = 100
local Nmc   = 10
local Tmc   = 50

di as txt _n "{hline 78}"
di as txt "2. Monte Carlo: `reps' reps, N=`Nmc', T=`Tmc', nominal 5% level"
di as txt "{hline 78}"

// ---- size (H0 true) ----
local rej = 0
forvalues r = 1/`reps' {
    set seed `=2000+`r''
    quietly simwh, n(`Nmc') t(`Tmc') frac(0)
    quietly xthpool y x
    if (r(p) < 0.05) local rej = `rej' + 1
}
local size = `rej'/`reps'
di as result "   Empirical size (beta_i=1)          = " %5.3f `size' as txt "  (target ~0.05, below is safe)"

// ---- power (H1 true, 30% non-poolable) ----
local rej = 0
forvalues r = 1/`reps' {
    set seed `=5000+`r''
    quietly simwh, n(`Nmc') t(`Tmc') frac(0.3)
    quietly xthpool y x
    if (r(p) < 0.05) local rej = `rej' + 1
}
local power = `rej'/`reps'
di as result "   Empirical power (30% non-poolable) = " %5.3f `power' as txt "  (should be high)"

// ---- size under ENDOGENEITY (H0 true, corr(u,v)=0.5) ----
// This case exercises the bias correction: without the contemporaneous term
// in the one-sided long-run covariance, H_i would be inflated and the test
// oversized.  With the faithful correction, size stays near/below nominal.
local rej = 0
forvalues r = 1/`reps' {
    set seed `=8000+`r''
    quietly simwh, n(`Nmc') t(`Tmc') frac(0) endog(0.5)
    quietly xthpool y x
    if (r(p) < 0.05) local rej = `rej' + 1
}
local sizeen = `rej'/`reps'
di as result "   Empirical size, endogenous (corr=0.5) = " %5.3f `sizeen' as txt "  (bias correction should keep this controlled)"

// ---- size under SERIAL CORRELATION (H0 true, AR(1) rho=0.5) ----
local rej = 0
forvalues r = 1/`reps' {
    set seed `=9000+`r''
    quietly simwh, n(`Nmc') t(`Tmc') frac(0) rho(0.5)
    quietly xthpool y x
    if (r(p) < 0.05) local rej = `rej' + 1
}
local sizesc = `rej'/`reps'
di as result "   Empirical size, serial corr (rho=0.5) = " %5.3f `sizesc' as txt "  (Newey-West lagged term should keep this controlled)"

di as txt _n "Done."
