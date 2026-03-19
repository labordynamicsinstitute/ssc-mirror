*! causalspline.ado  v1.0.4  2026-03-18
*! Stata 14.1 compatible - ASCII only - rclass
program define causalspline, rclass
    version 14.0

    syntax [if] [in] ,           ///
        Outcome(varname numeric)     ///
        Treatment(varname numeric)   ///
        Confounders(varlist numeric) ///
        [ Method(string)             ///
          DFexposure(integer 4)      ///
          EVALgrid(integer 100)      ///
          BOOTreps(integer 200)      ///
          Level(cilevel)             ///
          SAVEcurve(string)          ///
          VERBose                    ///
        ]

    if "`method'" == "" local method "ipw"
    if !inlist("`method'", "ipw", "gcomp", "dr") {
        di as error "method() must be: ipw  gcomp  dr"
        exit 198
    }
    if `dfexposure' < 2 | `dfexposure' > 7 {
        di as error "dfexposure() must be 2-7"
        exit 198
    }
    local z = invnormal(1 - (100-`level')/200)

    marksample touse
    markout `touse' `outcome' `treatment' `confounders'
    qui count if `touse'
    local n = r(N)
    if `n' < 20 {
        di as error "Too few obs (n=`n')"
        exit 2001
    }

    qui sum `treatment' if `touse'
    local t_min  = r(min)
    local t_max  = r(max)
    local t_mean = r(mean)
    local t_sd   = r(sd)

    if "`verbose'" != "" {
        di as text " "
        di as text "causalspline  n=`n'  method=`method'  df=`dfexposure'  grid=`evalgrid'  B=`bootreps'"
        di as text "Treatment range: [" %6.3f `t_min' ",  " %6.3f `t_max' "]"
    }

    local nknots = `dfexposure' - 1
    if `nknots' < 1 local nknots = 1
    if `nknots' > 6 local nknots = 6

    _pctile `treatment' if `touse', nquantiles(`= `nknots' + 1')
    mat csknots = J(1, `nknots', .)
    forval ki = 1/`nknots' {
        mat csknots[1, `ki'] = r(r`ki')
    }

    if "`verbose'" != "" {
        di as text "  Interior knots: " `nknots'
    }

    tempvar ipw_w
    local ess     = .
    local ess_pct = .

    if inlist("`method'", "ipw", "dr") {
        if "`verbose'" != "" di as text "  GPS model..."
        tempvar ghat resid_g ft_x ft_m
        qui reg `treatment' `confounders' if `touse'
        qui predict double `ghat'    if `touse', xb
        qui predict double `resid_g' if `touse', resid
        qui sum `resid_g' if `touse'
        local sg = r(sd)
        qui gen double `ft_x' = normalden(`treatment', `ghat', `sg') if `touse'
        qui gen double `ft_m' = normalden(`treatment', `t_mean', `t_sd') if `touse'
        qui gen double `ipw_w' = `ft_m' / max(`ft_x', 1e-10) if `touse'
        qui sum `ipw_w' if `touse', detail
        local wlo = r(p1)
        local whi = r(p99)
        qui replace `ipw_w' = `wlo' if `ipw_w' < `wlo' & `touse'
        qui replace `ipw_w' = `whi' if `ipw_w' > `whi' & `touse'
        qui sum `ipw_w' if `touse'
        local wmn = r(mean)
        qui replace `ipw_w' = `ipw_w' / `wmn' if `touse'
        qui sum `ipw_w' if `touse'
        local sw = r(sum)
        tempvar w2
        qui gen double `w2' = `ipw_w'^2 if `touse'
        qui sum `w2' if `touse'
        local ess     = (`sw')^2 / r(sum)
        local ess_pct = round(100 * `ess' / `n', 0.1)
        drop `w2'
        if "`verbose'" != "" {
            qui sum `ipw_w' if `touse', detail
            di as text "  ESS = " %6.1f `ess' " / n = " `n' " (" `ess_pct' "%)"
            di as text "  Weight range [" %5.3f r(min) ", " %5.3f r(max) "]"
        }
    }
    else {
        qui gen double `ipw_w' = 1 if `touse'
    }

    if "`verbose'" != "" di as text "  Bootstrap (B=`bootreps')..."

    tempname ct ce cse clo chi
    mata: _cs_main("`outcome'", "`treatment'", "`confounders'",  ///
                   "`ipw_w'", "`touse'", "`method'",             ///
                   `dfexposure', `evalgrid',                      ///
                   `t_min', `t_max',                              ///
                   `bootreps', `z',                               ///
                   "`ct'", "`ce'", "`cse'", "`clo'", "`chi'")

    di as text " "
    di as text "{hline 65}"
    di as text " Causal Spline Dose-Response  [" upper("`method'") "]"
    di as text "{hline 65}"
    di as text %10s "t" %13s "E[Y(t)]" %11s "SE" %13s "Lower" %13s "Upper"
    di as text "{hline 65}"

    local rows "1"
    foreach pct in 10 25 50 75 90 {
        local j = max(1, round(`pct' * `evalgrid' / 100))
        local rows "`rows' `j'"
    }
    local rows "`rows' `evalgrid'"

    foreach j of local rows {
        if `j' >= 1 & `j' <= `evalgrid' {
            di as result %10.3f `ct'[`j',1]  %13.4f `ce'[`j',1]   ///
                         %11.4f `cse'[`j',1] %13.4f `clo'[`j',1]  ///
                         %13.4f `chi'[`j',1]
        }
    }
    di as text "{hline 65}"
    di as text "n = " as result `n'
    if inlist("`method'", "ipw", "dr") {
        di as text "ESS = " as result %6.1f `ess' ///
            as text "  (" as result `ess_pct' as text "%)"
    }
    di as text "Bootstrap reps = " as result `bootreps'

    if "`savecurve'" != "" {
        preserve
            qui drop _all
            qui set obs `evalgrid'
            qui gen double t        = .
            qui gen double estimate = .
            qui gen double se       = .
            qui gen double lower    = .
            qui gen double upper    = .
            forval j = 1/`evalgrid' {
                qui replace t        = `ct'[`j',1]  in `j'
                qui replace estimate = `ce'[`j',1]  in `j'
                qui replace se       = `cse'[`j',1] in `j'
                qui replace lower    = `clo'[`j',1] in `j'
                qui replace upper    = `chi'[`j',1] in `j'
            }
            qui save "`savecurve'", replace
        restore
        di as text "  Curve saved: " as result "`savecurve'"
    }

    // Persistent storage for companion commands
    // globals for scalars/strings, named matrices for curve data
    global CSCMD        "causalspline"
    global CSMETHOD     "`method'"
    global CSOUTCOME    "`outcome'"
    global CSTREATMENT  "`treatment'"
    global CSCONF       "`confounders'"
    global CSN          "`n'"
    global CSTMIN       "`t_min'"
    global CSTMAX       "`t_max'"
    global CSTMEAN      "`t_mean'"
    global CSTSD        "`t_sd'"
    global CSNGRID      "`evalgrid'"
    global CSDF         "`dfexposure'"
    global CSLEV        "`level'"
    global CSBREPS      "`bootreps'"
    global CSESS        "`ess'"
    global CSESPCT      "`ess_pct'"

    cap matrix drop CSCT CSCE CSCSE CSCLO CSCHI
    matrix CSCT  = `ct'
    matrix CSCE  = `ce'
    matrix CSCSE = `cse'
    matrix CSCLO = `clo'
    matrix CSCHI = `chi'

    // Return via r() for immediate post-command access
    return scalar n          = `n'
    return scalar t_min      = `t_min'
    return scalar t_max      = `t_max'
    return scalar t_mean     = `t_mean'
    return scalar t_sd       = `t_sd'
    return scalar evalgrid   = `evalgrid'
    return scalar dfexposure = `dfexposure'
    return scalar level      = `level'
    return scalar bootreps   = `bootreps'
    if inlist("`method'", "ipw", "dr") {
        return scalar ess     = `ess'
        return scalar ess_pct = `ess_pct'
    }
    return matrix curve_t   = `ct'
    return matrix curve_est = `ce'
    return matrix curve_se  = `cse'
    return matrix curve_lo  = `clo'
    return matrix curve_hi  = `chi'
    return local method      "`method'"
    return local outcome     "`outcome'"
    return local treatment   "`treatment'"
    return local confounders "`confounders'"
    return local cmd         "causalspline"
    return local title       "Causal Dose-Response (Spline)"
end


mata:

void _cs_main(string scalar yvar,
              string scalar tvar,
              string scalar xvars,
              string scalar wvar,
              string scalar touse,
              string scalar method,
              real   scalar df,
              real   scalar ng,
              real   scalar t_min,
              real   scalar t_max,
              real   scalar B,
              real   scalar z,
              string scalar rct,
              string scalar rce,
              string scalar rcse,
              string scalar rclo,
              string scalar rchi)
{
    real matrix    Y, T, X, W, S_samp, S_grid, boot_mat, X_b, S_b
    real colvector t_grid, mu_hat, se_v, lo_v, hi_v, col_j
    real colvector idx, Y_b, T_b, W_b, mu_b
    real matrix    knots
    real scalar    n, b, j

    st_view(Y, ., yvar,  touse)
    st_view(T, ., tvar,  touse)
    st_view(W, ., wvar,  touse)
    st_view(X, ., tokens(xvars), touse)
    n = rows(Y)

    knots  = st_matrix("csknots")
    t_grid = t_min :+ (0::ng-1) :* ((t_max - t_min) / (ng - 1))

    S_samp = _rcs(T,      knots, t_min, t_max, df)
    S_grid = _rcs(t_grid, knots, t_min, t_max, df)

    mu_hat = _estimate(Y, T, S_samp, X, W, S_grid, t_grid, method, n, ng)

    boot_mat = J(B, ng, .)
    rseed(12345)

    for (b = 1; b <= B; b++) {
        idx  = ceil(n :* runiform(n, 1))
        Y_b  = Y[idx]
        T_b  = T[idx]
        X_b  = X[idx,]
        S_b  = _rcs(T_b, knots, t_min, t_max, df)
        if (method == "ipw" | method == "dr") {
            W_b = _ipw_weights(T_b, X_b)
        }
        else {
            W_b = J(n, 1, 1)
        }
        mu_b = _estimate(Y_b, T_b, S_b, X_b, W_b, S_grid, t_grid, method, n, ng)
        boot_mat[b,] = mu_b'
    }

    se_v = J(ng, 1, .)
    lo_v = J(ng, 1, .)
    hi_v = J(ng, 1, .)

    for (j = 1; j <= ng; j++) {
        col_j = select(boot_mat[,j], boot_mat[,j] :!= .)
        if (rows(col_j) > 2) {
            se_v[j] = sqrt(variance(col_j))
        }
        lo_v[j] = mu_hat[j] - z * se_v[j]
        hi_v[j] = mu_hat[j] + z * se_v[j]
    }

    st_matrix(rct,  t_grid)
    st_matrix(rce,  mu_hat)
    st_matrix(rcse, se_v)
    st_matrix(rclo, lo_v)
    st_matrix(rchi, hi_v)
}


real colvector _estimate(real colvector Y,
                          real colvector T,
                          real matrix   S,
                          real matrix   X,
                          real colvector W,
                          real matrix   S_grid,
                          real colvector t_grid,
                          string scalar  method,
                          real scalar    n,
                          real scalar    ng)
{
    real colvector mu, beta, mu_ipw, mu_gc
    real matrix    XS, XS_g

    mu     = J(ng, 1, .)
    mu_ipw = J(ng, 1, .)
    mu_gc  = J(ng, 1, .)

    if (method == "ipw") {
        XS   = (J(n,1,1), S)
        XS_g = (J(ng,1,1), S_grid)
        beta = _wls(Y, XS, W)
        mu   = XS_g * beta
    }
    else if (method == "gcomp") {
        XS   = (J(n,1,1), S, X)
        beta = _ols(Y, XS)
        mu   = _std(beta, S_grid, X, ng, n)
    }
    else {
        XS     = (J(n,1,1), S)
        XS_g   = (J(ng,1,1), S_grid)
        beta   = _wls(Y, XS, W)
        mu_ipw = XS_g * beta
        XS     = (J(n,1,1), S, X)
        beta   = _ols(Y, XS)
        mu_gc  = _std(beta, S_grid, X, ng, n)
        mu     = 0.5 :* mu_ipw + 0.5 :* mu_gc
    }
    return(mu)
}


real colvector _wls(real colvector y, real matrix X, real colvector w)
{
    real matrix XtW
    XtW = X' :* w'
    return(invsym(XtW * X) * (XtW * y))
}


real colvector _ols(real colvector y, real matrix X)
{
    return(invsym(X' * X) * (X' * y))
}


real colvector _std(real colvector beta, real matrix S_grid,
                     real matrix X, real scalar ng, real scalar n)
{
    real colvector mu, pred_j
    real matrix    Xj
    real scalar    j

    mu = J(ng, 1, .)
    for (j = 1; j <= ng; j++) {
        Xj     = (J(n,1,1), J(n,1,1) * S_grid[j,], X)
        pred_j = Xj * beta
        mu[j]  = mean(pred_j)
    }
    return(mu)
}


real colvector _ipw_weights(real colvector T, real matrix X)
{
    real scalar    n, sig, t_mu, t_sig, wlo, whi
    real matrix    Xd, ws
    real colvector beta, ghat, resid, ft_x, ft_m, ft_safe, w

    n     = rows(T)
    Xd    = (J(n,1,1), X)
    beta  = invsym(Xd' * Xd) * Xd' * T
    ghat  = Xd * beta
    resid = T - ghat
    sig   = sqrt(variance(resid))
    t_mu  = mean(T)
    t_sig = sqrt(variance(T))

    ft_x    = normalden(T, ghat, J(n,1,sig))
    ft_m    = normalden(T, J(n,1,t_mu), J(n,1,t_sig))
    ft_safe = ft_x + (ft_x :< 1e-10) :* (1e-10 :- ft_x)
    w       = ft_m :/ ft_safe

    ws  = sort(w, 1)
    wlo = ws[max((1, floor(0.01*n))), 1]
    whi = ws[min((n, ceil(0.99*n))),  1]
    w   = w + (w :< wlo) :* (wlo :- w)
    w   = w - (w :> whi) :* (w :- whi)
    w   = w :/ mean(w)
    return(w)
}


real matrix _rcs(real colvector t, real matrix knots,
                  real scalar t_min, real scalar t_max,
                  real scalar df)
{
    real scalar    nk, n, k, kn_last, kn_k, kn_prev, scale_k
    real matrix    B
    real colvector trk, trlast

    nk      = cols(knots)
    n       = rows(t)
    B       = J(n, df, 0)
    B[,1]   = t
    kn_last = knots[nk]

    for (k = 1; k <= df-1; k++) {
        if (k <= nk) {
            kn_k = knots[k]
        }
        else {
            kn_k = knots[nk]
        }
        kn_prev = knots[max((nk-1, 1))]
        trk     = ((t :- kn_k)    :* (t :> kn_k)):^3
        trlast  = ((t :- kn_last) :* (t :> kn_last)):^3
        if (kn_last != kn_prev) {
            scale_k = (kn_last - kn_k) / (kn_last - kn_prev)
        }
        else {
            scale_k = 0
        }
        B[,k+1] = trk - scale_k :* trlast
    }
    return(B)
}

end
