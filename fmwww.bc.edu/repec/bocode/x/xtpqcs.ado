*! xtpqcs v1.0.0  20feb2026
*! Panel Quantile Regression with Common Shocks
*! Implements Chiang, Galvao & Wei (2026, arXiv:2602.19201)
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
*!
*! Estimates the fixed-effects panel quantile regression model
*!     Q_tau(Y_it | X_it, alpha_i) = alpha_i(tau) + X_it' beta(tau)
*! using the standard unregularized Koenker (2004) estimator and reports
*! the robust covariance V_hat = Gamma^-1 Sigma_hat Gamma^-1 of
*! Chiang, Galvao & Wei (2026), which remains consistent in the presence
*! (or absence) of pervasive common time shocks B_t.
*!
*! Under the common-shock framework  sqrt(T)*(beta_hat - beta_0) -> N(0,V).
*! Reported standard errors are sqrt(diag(V)/T).

program define xtpqcs, eclass sortpreserve
    version 14.0

    if replay() {
        if "`e(cmd)'" != "xtpqcs" error 301
        Display `0'
        exit
    }

    syntax varlist(min=2 numeric) [if] [in], ///
        Id(varname numeric)                        ///
        Time(varname numeric)                      ///
    [                                              ///
        Quantile(real 0.5)                         ///
        Bandwidth(real 0)                          ///
        Kernel(string)                             ///
        COMPare                                    ///
        Level(cilevel)                             ///
        noHEader                                   ///
    ]

    if `quantile' <= 0 | `quantile' >= 1 {
        di as err "quantile() must lie strictly between 0 and 1"
        exit 198
    }
    if "`kernel'" == "" local kernel "gaussian"
    if !inlist("`kernel'","gaussian","epanechnikov","uniform") {
        di as err "kernel() must be gaussian, epanechnikov, or uniform"
        exit 198
    }

    marksample touse
    markout `touse' `id' `time'

    gettoken depvar indepvars : varlist

    qui count if `touse'
    if r(N) == 0 error 2000
    local nobs = r(N)

    tempvar idnum tnum
    qui egen long `idnum' = group(`id')   if `touse'
    qui egen long `tnum'  = group(`time')  if `touse'

    qui su `idnum' if `touse', meanonly
    local N = r(max)
    qui su `tnum'  if `touse', meanonly
    local T = r(max)

    if `N' < 2 {
        di as err "need at least 2 cross-sectional units"
        exit 459
    }
    if `T' < 5 {
        di as err "need at least 5 time periods for sensible inference"
        exit 459
    }

    local p : word count `indepvars'

    /*-----------------------------------------------------------------*/
    /*  Step 1.  FEQR – Koenker (2004) via iterative concentration     */
    /*  Solves  min_{alpha,beta} (1/NT) sum rho_tau(Y-alpha_i-X'beta)  */
    /*  by iterating:                                                   */
    /*    (a) alpha_i(beta) = Q_tau{Y_it - X_it'beta}  per unit i      */
    /*    (b) beta(alpha) from qreg of (Y-alpha_i) on X (p params)     */
    /*  Converges to the exact Koenker (2004) solution.                 */
    /*-----------------------------------------------------------------*/

    sort `touse' `idnum' `tnum'

    * Initialise beta from pooled qreg (always fast – no dummies)
    qui qreg `depvar' `indepvars' if `touse', quantile(`quantile')

    tempname bcoef
    matrix `bcoef' = J(1,`p',0)
    local cn ""
    local j = 0
    foreach v of local indepvars {
        local ++j
        matrix `bcoef'[1,`j'] = _b[`v']
        local cn "`cn' `v'"
    }
    matrix colnames `bcoef' = `cn'

    * Iterate in Mata: compute alpha_i then update beta via qreg
    tempvar ahat yresid
    tempname bcoef_old
    qui gen double `ahat'   = 0 if `touse'
    qui gen double `yresid' = 0 if `touse'

    forvalues iter = 1/50 {
        matrix `bcoef_old' = `bcoef'

        * (a) Mata: alpha_i = tau-quantile of (Y-X'beta) per unit
        mata: _xtpqcs_update_alpha("`depvar'", "`indepvars'", ///
            "`idnum'", "`ahat'", "`touse'", "`bcoef'", `quantile')

        * (b) yresid = Y - alpha_i  =>  qreg on X (fast, p params)
        qui replace `yresid' = `depvar' - `ahat' if `touse'
        qui qreg `yresid' `indepvars' if `touse', ///
            quantile(`quantile')

        local j = 0
        foreach v of local indepvars {
            local ++j
            matrix `bcoef'[1,`j'] = _b[`v']
        }
        matrix colnames `bcoef' = `cn'

        * Check convergence
        local maxdiff = 0
        forvalues jj = 1/`p' {
            local diff = abs(`bcoef'[1,`jj'] - `bcoef_old'[1,`jj'])
            if `diff' > `maxdiff' local maxdiff = `diff'
        }
        if `maxdiff' < 1e-6 {
            continue, break
        }
    }

    /*-----------------------------------------------------------------*/
    /*  Step 2.  Compute residuals                                     */
    /*-----------------------------------------------------------------*/
    tempvar res
    qui gen double `res' = `depvar' - `ahat' if `touse'
    local j = 0
    foreach v of local indepvars {
        local ++j
        qui replace `res' = `res' - `v' * `bcoef'[1,`j'] if `touse'
    }

    /*-----------------------------------------------------------------*/
    /*  Step 3.  Bandwidth (Silverman with floor at 0.05 as in paper). */
    /*  Section 5 of Chiang, Galvao & Wei (2026):                      */
    /*     h = max(0.05, 1.06 * sd(eps_hat) * N^{-1/5})                */
    /*  where N is the cross-sectional dimension only.                 */
    /*-----------------------------------------------------------------*/
    qui su `res' if `touse'
    local sd = r(sd)
    if `bandwidth' == 0 {
        local h = max(0.05, 1.06 * `sd' * (`N')^(-1/5))
    }
    else {
        local h = `bandwidth'
    }

    /*-----------------------------------------------------------------*/
    /*  Step 4.  Compute Vrob, Vcl, Gamma, Sigma, Omega via Mata       */
    /*-----------------------------------------------------------------*/

    tempname Vrob Vcl Gamma Sigma Omega bMata
    matrix `bMata' = `bcoef'

    mata: xtpqcs_compute(                                              ///
        "`depvar'", "`indepvars'", "`idnum'", "`tnum'", "`ahat'",       ///
        "`touse'", `quantile', `h', "`kernel'", "`bMata'",              ///
        "`Vrob'", "`Vcl'", "`Gamma'", "`Sigma'", "`Omega'")

    matrix rownames `Vrob'  = `indepvars'
    matrix colnames `Vrob'  = `indepvars'
    matrix rownames `Vcl'   = `indepvars'
    matrix colnames `Vcl'   = `indepvars'
    matrix rownames `Gamma' = `indepvars'
    matrix colnames `Gamma' = `indepvars'
    matrix rownames `Sigma' = `indepvars'
    matrix colnames `Sigma' = `indepvars'
    matrix rownames `Omega' = `indepvars'
    matrix colnames `Omega' = `indepvars'

    if "`compare'" != "" {
        local Vuse `Vcl'
        local vtype "Classical Kato et al. (2012) sandwich"
    }
    else {
        local Vuse `Vrob'
        local vtype "Robust to common shocks (Chiang, Galvao & Wei 2026)"
    }

    /*-----------------------------------------------------------------*/
    /*  Step 5.  Post results                                          */
    /*  Note: ereturn post consumes b and V, so we pass copies.        */
    /*-----------------------------------------------------------------*/
    tempname bpost Vpost
    matrix `bpost' = `bcoef'
    matrix `Vpost' = `Vuse'
    ereturn post `bpost' `Vpost', esample(`touse') depname(`depvar') ///
        obs(`nobs')

    ereturn matrix V_robust    = `Vrob'
    ereturn matrix V_classical = `Vcl'
    ereturn matrix Gamma_hat   = `Gamma'
    ereturn matrix Sigma_hat   = `Sigma'
    ereturn matrix Omega_hat   = `Omega'

    ereturn scalar quantile  = `quantile'
    ereturn scalar N_g       = `N'
    ereturn scalar T         = `T'
    ereturn scalar bandwidth = `h'
    ereturn scalar df_r      = `T' - `p'

    ereturn local  kernel    "`kernel'"
    ereturn local  ivar      "`id'"
    ereturn local  tvar      "`time'"
    ereturn local  depvar    "`depvar'"
    ereturn local  vcetype   "`vtype'"
    ereturn local  vce       "robust_cgw"
    ereturn local  cmdline   `"xtpqcs `0'"'
    ereturn local  cmd       "xtpqcs"

    if "`header'" == "" Display, level(`level')
end

/*=====================================================================*/
/*  Display routine                                                    */
/*=====================================================================*/
program define Display
    syntax [, Level(cilevel)]

    di ""
    di as txt "{hline 78}"
    di as res "  Panel Quantile Regression with Common Shocks  (xtpqcs)"
    di as txt "  Chiang, Galvao & Wei (2026, arXiv:2602.19201)"
    di as txt "  Stata implementation: Dr. Merwan Roudane"
    di as txt "{hline 78}"
    di as txt "  Dependent variable    : " as res "`e(depvar)'"
    di as txt "  Panel id              : " as res "`e(ivar)'" ///
       _col(45) as txt "Number of obs    = " as res %10.0fc e(N)
    di as txt "  Time variable         : " as res "`e(tvar)'" ///
       _col(45) as txt "Number of groups = " as res %10.0fc e(N_g)
    di as txt "  Quantile              : " as res %5.3f e(quantile) ///
       _col(45) as txt "Time periods     = " as res %10.0fc e(T)
    di as txt "  Bandwidth (h)         : " as res %7.4f e(bandwidth) ///
       _col(45) as txt "Kernel           = " as res "`e(kernel)'"
    di as txt "  Std. err. type        : " as res "`e(vcetype)'"
    di as txt "{hline 78}"
    ereturn display, level(`level')
    di as txt "{hline 78}"
    di as txt "  Asymptotic theory: sqrt(T)*(beta_hat - beta_0) -> N(0,V)"
    di as txt "  V = Gamma^-1 * Sigma * Gamma^-1.  Reported SE = sqrt(diag(V)/T)."
    di as txt "  Stored: e(V_robust), e(V_classical), e(Gamma_hat),"
    di as txt "          e(Sigma_hat), e(Omega_hat)."
    di as txt "{hline 78}"
end

/*=====================================================================*/
/*  Mata work-horse                                                    */
/*=====================================================================*/
version 14.0
mata:
mata set matastrict off

void xtpqcs_compute(string scalar yvar,    string scalar xvars,
                    string scalar idvar,   string scalar tvar,
                    string scalar avar,    string scalar touse,
                    real scalar tau,       real scalar h,
                    string scalar kernel,  string scalar bname,
                    string scalar Vrob_nm, string scalar Vcl_nm,
                    string scalar G_nm,    string scalar S_nm,
                    string scalar O_nm)
{
    real colvector y, id, tt, ahat, eps, K, fihat, bhat, mbar, perm, t_sorted, d
    real matrix    X, gammahat, glong, psi, Gamma, Sigma, Omega, Vrob, Vcl
    real matrix    infoI, infoT, mNt, dpsi, Ginv, Ki, Xi
    real scalar    n, p, N, T, i, t, j, ilo, ihi, Ti

    /* pull data */
    st_view(y , ., yvar , touse)
    st_view(X , ., xvars, touse)
    st_view(id, ., idvar, touse)
    st_view(tt, ., tvar , touse)
    st_view(ahat, ., avar, touse)

    n = rows(y)
    p = cols(X)

    /* coefficient vector from Stata (1 x p row -> p x 1 col) */
    bhat = st_matrix(bname)'

    /* residuals */
    eps = y - ahat - X*bhat

    /* kernel weights K_h(eps) */
    K = xtpqcs_kernel(eps, h, kernel)

    /* panel info by id (data sorted by touse, id, t) */
    infoI = panelsetup(id, 1)
    N = rows(infoI)

    fihat    = J(N,1,0)
    gammahat = J(N,p,0)
    for (i=1; i<=N; i++) {
        ilo = infoI[i,1]
        ihi = infoI[i,2]
        Ti  = ihi - ilo + 1
        Ki  = K[|ilo \ ihi|]
        Xi  = X[|ilo,1 \ ihi,p|]
        fihat[i] = mean(Ki)
        if (fihat[i] > 1e-12) {
            gammahat[i,] = (Ki' * Xi) :/ (Ti * fihat[i])
        }
    }

    /* expand gamma_i to obs level */
    glong = J(n,p,0)
    for (i=1; i<=N; i++) {
        ilo = infoI[i,1]
        ihi = infoI[i,2]
        for (j=ilo; j<=ihi; j++) glong[j,] = gammahat[i,]
    }

    /* psi_it = (tau - 1{eps_it<=0}) * (X_it - gamma_i) */
    psi = (tau :- (eps :<= 0)) :* (X - glong)

    /* Gamma_hat = (1/n) sum_it K_h(eps_it) X_it (X_it - gamma_i)' */
    Gamma = (K :* X)' * (X - glong) :/ n
    Gamma = (Gamma + Gamma') :/ 2

    /* Aggregate psi by t for Sigma */
    perm     = order(tt, 1)
    t_sorted = tt[perm]
    dpsi     = psi[perm,]
    infoT    = panelsetup(t_sorted, 1)
    T        = rows(infoT)

    mNt = J(T,p,0)
    for (t=1; t<=T; t++) {
        ilo = infoT[t,1]
        ihi = infoT[t,2]
        mNt[t,] = mean(dpsi[|ilo,1 \ ihi,p|])
    }
    mbar  = mean(mNt)
    Sigma = J(p,p,0)
    for (t=1; t<=T; t++) {
        d = (mNt[t,] - mbar)'
        Sigma = Sigma + d*d'
    }
    Sigma = Sigma :/ T
    Sigma = (Sigma + Sigma') :/ 2

    /* Robust V (paper eq. 9):  V = Gamma^-1 Sigma Gamma^-1            */
    /* Theorem 1:  sqrt(T)(b - b0) -> N(0, V), so var(b) ~ V/T          */
    Ginv = invsym(Gamma)
    Vrob = Ginv * Sigma * Ginv
    Vrob = (Vrob + Vrob') :/ 2
    Vrob = Vrob :/ T

    /* Classical Kato et al. (2012) sandwich for comparison             */
    /* sqrt(NT)(b-b0) -> N(0, tau(1-tau) Gamma^-1 Omega Gamma^-1)       */
    /* with Omega ~ E[(X-gamma)(X-gamma)']                              */
    Omega = (X - glong)' * (X - glong) :/ n
    Omega = (Omega + Omega') :/ 2
    Vcl   = tau*(1-tau) * Ginv * Omega * Ginv :/ n
    Vcl   = (Vcl + Vcl') :/ 2

    /* export to Stata */
    st_matrix(Vrob_nm, Vrob)
    st_matrix(Vcl_nm , Vcl )
    st_matrix(G_nm   , Gamma)
    st_matrix(S_nm   , Sigma)
    st_matrix(O_nm   , Omega)
}

real colvector xtpqcs_kernel(real colvector u, real scalar h, string scalar k)
{
    real colvector z
    z = u :/ h
    if (k == "gaussian") {
        return( normalden(z) :/ h )
    }
    else if (k == "epanechnikov") {
        return( (0.75 :* (1 :- z:^2) :* (abs(z) :<= 1)) :/ h )
    }
    else {
        return( (0.5 :* (abs(z) :<= 1)) :/ h )
    }
}

/*-----------------------------------------------------------------*/
/*  _xtpqcs_update_alpha: compute alpha_i = tau-quantile of         */
/*  (Y_it - X_it'beta) per panel unit i.  Writes into the existing  */
/*  Stata variable named by avar.                                   */
/*-----------------------------------------------------------------*/
void _xtpqcs_update_alpha(string scalar yvar,  string scalar xvars,
                          string scalar idvar, string scalar avar,
                          string scalar touse, string scalar bname,
                          real scalar tau)
{
    real colvector y, id, resid, qi
    real matrix    X, ahat, infoI
    real scalar    N, i, ilo, ihi, p
    real rowvector bhat

    st_view(y , ., yvar , touse)
    st_view(X , ., xvars, touse)
    st_view(id, ., idvar, touse)
    st_view(ahat, ., avar, touse)

    bhat  = st_matrix(bname)
    p     = cols(X)
    resid = y - X * bhat'

    infoI = panelsetup(id, 1)
    N     = rows(infoI)

    for (i=1; i<=N; i++) {
        ilo = infoI[i,1]
        ihi = infoI[i,2]
        qi  = _xtpqcs_quantile(resid[|ilo \ ihi|], tau)
        ahat[|ilo \ ihi|] = J(ihi-ilo+1, 1, qi)
    }
}

/*  Compute the tau-th sample quantile of a column vector           */
real scalar _xtpqcs_quantile(real colvector x, real scalar tau)
{
    real colvector sx
    real scalar n, h, lo, hi

    sx = sort(x, 1)
    n  = rows(sx)
    h  = (n - 1) * tau + 1
    lo = floor(h)
    hi = ceil(h)
    if (lo < 1)  lo = 1
    if (hi > n)  hi = n
    if (lo == hi) return(sx[lo])
    return(sx[lo] + (h - lo) * (sx[hi] - sx[lo]))
}
end
