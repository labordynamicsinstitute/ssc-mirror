*! fourierdf v2.0 - Enders & Lee (2012b) Fourier ADF Unit Root Test
*! Economics Letters, 117 (2012), 196-199
*! Ported from GAUSS code by Saban Nazlioglu
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fourierdf, rclass
    version 14
    syntax varname(ts) [if] [in] [, Model(integer 2) Kmax(integer 5) K(integer 0) Pmax(integer 8) IC(integer 3) NOTrend GRAPH]

    marksample touse
    tsset
    local tvar `r(timevar)'

    if "`notrend'" != "" {
        local model = 1
    }

    quietly {
        tempvar y
        gen double `y' = `varlist' if `touse'
        count if `touse'
        local T = r(N)
    }
    if `T' < 20 {
        di as error "Insufficient observations"
        exit 2001
    }

    if `model' == 1 {
        local modelname "Constant only (Model 1)"
    }
    else {
        local modelname "Constant + Trend (Model 2)"
    }

    di ""
    di as text "{hline 70}"
    di as text "  Fourier ADF Unit Root Test"
    di as text "  Enders & Lee (2012b), Economics Letters 117:196-199"
    di as text "{hline 70}"
    di as text "  Variable: " as result "`varlist'" as text "   T=" as result `T'
    di as text "  Model: " as result "`modelname'"
    di as text "  Pmax=" as result `pmax' as text "   Kmax=" as result `kmax' as text "   IC=" as result `ic'
    di as text "{hline 70}"

    mata: _fdf_main("`y'", "`tvar'", "`touse'", `T', `pmax', `kmax', `ic', `model', `k')

    local ADF_stat = r(ADFk)
    local f        = r(k)
    local opt_lag  = r(p)
    local cv1      = r(cv1)
    local cv5      = r(cv5)
    local cv10     = r(cv10)

    if `ADF_stat' <= `cv1' {
        local sig "*** (1%)"
    }
    else if `ADF_stat' <= `cv5' {
        local sig "** (5%)"
    }
    else if `ADF_stat' <= `cv10' {
        local sig "* (10%)"
    }
    else {
        local sig "not significant"
    }

    di as text "  Fourier ADF test (Enders & Lee, 2012b)"
    di as text "  {hline 50}"
    di as text "  Optimal frequency k    = " as result `f'
    di as text "  Optimal lag p          = " as result `opt_lag'
    di as text "  ADF statistic          = " as result %9.3f `ADF_stat'
    di as text ""
    di as text "  Critical Values (T=`T', model=`model', k=`f'):"
    di as text "    1%  : " as result %9.3f `cv1'
    di as text "    5%  : " as result %9.3f `cv5'
    di as text "    10% : " as result %9.3f `cv10'
    di as text ""
    di as text "  " as result "`sig'"
    if `ADF_stat' <= `cv5' {
        di as text "  Conclusion: Reject unit root null at 5%"
    }
    else {
        di as text "  Conclusion: Cannot reject unit root null"
    }
    di as text "{hline 70}"

    if "`graph'" != "" {
        quietly {
            tempvar sink_g cosk_g fitted_g
            gen double `sink_g' = sin(2*_pi*`f'*`tvar'/`T') if `touse'
            gen double `cosk_g' = cos(2*_pi*`f'*`tvar'/`T') if `touse'
            if `model' == 1 {
                reg `varlist' `sink_g' `cosk_g' if `touse'
            }
            else {
                reg `varlist' `tvar' `sink_g' `cosk_g' if `touse'
            }
            predict double `fitted_g' if `touse', xb
        }
        twoway (line `varlist' `tvar' if `touse', lcolor(blue) lwidth(thin)) (line `fitted_g' `tvar' if `touse', lcolor(red) lwidth(thick)), title("Fourier ADF: `varlist' (k=`f')") legend(order(1 "`varlist'" 2 "Fourier expansion series")) graphregion(color(white)) bgcolor(white) name(fourierdf_graph, replace)
    }

    return scalar ADFk         = `ADF_stat'
    return scalar k            = `f'
    return scalar p            = `opt_lag'
    return scalar cv1          = `cv1'
    return scalar cv5          = `cv5'
    return scalar cv10         = `cv10'
    return scalar tau_stat     = `ADF_stat'
    return scalar k_selected   = `f'
    return scalar lags_selected= `opt_lag'
end


program define fourierADFftest, rclass
    version 14
    syntax varname(ts) [if] [in], K(integer) P(integer) [Model(integer 2) NOTrend]

    marksample touse
    tsset
    local tvar `r(timevar)'

    if "`notrend'" != "" {
        local model = 1
    }

    quietly {
        tempvar y
        gen double `y' = `varlist' if `touse'
        count if `touse'
        local T = r(N)
    }

    mata: _fdf_Ftest("`y'", "`tvar'", "`touse'", `T', `k', `p', `model')

    local F_stat = r(Fstat)
    local Fcv1   = r(Fcv1)
    local Fcv5   = r(Fcv5)
    local Fcv10  = r(Fcv10)

    di ""
    di as text "  Fourier ADF F-Test for Linearity"
    di as text "  H0: no Fourier terms (alpha_k = beta_k = 0)"
    di as text "  {hline 50}"
    di as text "  k=" as result `k' as text "  p=" as result `p'
    di as text "  F-statistic = " as result %9.3f `F_stat'
    di as text "  Critical Values: 1%=" as result %6.3f `Fcv1' as text "  5%=" as result %6.3f `Fcv5' as text "  10%=" as result %6.3f `Fcv10'
    if `F_stat' >= `Fcv5' {
        di as text "  Decision: " as result "Reject linearity - Fourier terms significant"
    }
    else {
        di as text "  Decision: " as result "Cannot reject linearity"
    }

    return scalar Fstat = `F_stat'
    return scalar Fcv1  = `Fcv1'
    return scalar Fcv5  = `Fcv5'
    return scalar Fcv10 = `Fcv10'
end


mata:

void _fdf_main(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar pmax, real scalar kmax, real scalar ic, real scalar model, real scalar kfix)
{
    real colvector y, t_vec, dy, ly, dc, dt, sink, cosk
    real scalar k, f, ADF_stat, opt_lag, ms, kk
    real colvector ssrk, tauk, keep_p
    real matrix crit, lmat, ldy, z_reg, XtX_inv
    real colvector taup_v, aicp_v, sicp_v, tstatp_v, ssrp_v
    real scalar p, p_opt, nobs, ncols, ssr, tau_p, aic_p, sic_p, tst_p, LL
    real colvector dep, b, e, se_b

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    dy = y[2..T,.] - y[1..T-1,.]
    ly = y[1..T-1,.]
    dc = J(T, 1, 1)
    dt = t_vec
    lmat = _fdf_lagmatrix(dy, pmax)
    ssrk   = J(kmax, 1, .)
    tauk   = J(kmax, 1, .)
    keep_p = J(kmax, 1, .)

    for (k=1; k<=kmax; k++) {
        if (kfix > 0 & k != kfix) continue
        sink = sin(2*pi()*k*t_vec/T)
        cosk = cos(2*pi()*k*t_vec/T)
        taup_v   = J(pmax+1, 1, .)
        aicp_v   = J(pmax+1, 1, .)
        sicp_v   = J(pmax+1, 1, .)
        tstatp_v = J(pmax+1, 1, .)
        ssrp_v   = J(pmax+1, 1, .)

        for (p=0; p<=pmax; p++) {
            if (p+2 > T-1) continue
            dep = dy[p+2..T-1,.]
            if (p == 0) {
                ldy = J(0, 0, .)
            }
            else {
                ldy = lmat[p+2..T-1, 1..p]
            }
            z_reg = _fdf_get_model_x(ly, p, model, ldy, dc, dt, sink, cosk, T)
            if (rows(z_reg) == 0) continue
            nobs  = rows(z_reg)
            ncols = cols(z_reg)
            if (nobs <= ncols) continue
            XtX_inv = invsym(cross(z_reg, z_reg))
            b = XtX_inv * cross(z_reg, dep)
            e = dep - z_reg * b
            ssr = quadcross(e, e)
            se_b = sqrt(diagonal(XtX_inv) * ssr / (nobs - ncols))
            tau_p = b[1] / se_b[1]
            LL = -nobs/2 * (1 + log(2*pi()) + log(ssr/nobs))
            aic_p = (2*ncols - 2*LL) / nobs
            sic_p = (ncols*log(nobs) - 2*LL) / nobs
            tst_p = abs(b[ncols] / se_b[ncols])
            taup_v[p+1]   = tau_p
            aicp_v[p+1]   = aic_p
            sicp_v[p+1]   = sic_p
            tstatp_v[p+1] = tst_p
            ssrp_v[p+1]   = ssr
        }
        p_opt = _fdf_get_lag(ic, pmax, aicp_v, sicp_v, tstatp_v)
        ssrk[k]   = ssrp_v[p_opt+1]
        tauk[k]   = taup_v[p_opt+1]
        keep_p[k] = p_opt
    }

    if (kfix > 0) {
        f = kfix
    }
    else {
        f = 1
        ms = ssrk[1]
        for (kk=2; kk<=kmax; kk++) {
            if (ssrk[kk] < ms) {
                ms = ssrk[kk]
                f = kk
            }
        }
    }
    ADF_stat = tauk[f]
    opt_lag  = keep_p[f]
    crit = _fdf_getCrit(T, model)
    st_numscalar("r(ADFk)", ADF_stat)
    st_numscalar("r(k)",    f)
    st_numscalar("r(p)",    opt_lag)
    st_numscalar("r(cv1)",  crit[f,1])
    st_numscalar("r(cv5)",  crit[f,2])
    st_numscalar("r(cv10)", crit[f,3])
}

real matrix _fdf_get_model_x(real colvector ly, real scalar p, real scalar model, real matrix ldy, real colvector dc, real colvector dt, real colvector sink, real colvector cosk, real scalar T)
{
    real colvector yt_t, c_t, sink_t, cosk_t, trend_t
    real matrix x

    if (p+2 > T-1) return(J(0,0,.))
    yt_t   = ly[p+2..T-1,.]
    c_t    = dc[p+2..T-1,.]
    sink_t = sink[p+2..T-1,.]
    cosk_t = cosk[p+2..T-1,.]
    trend_t= dt[p+2..T-1,.]
    x = yt_t, c_t, sink_t, cosk_t
    if (model == 2) {
        x = x, trend_t
    }
    if (p > 0) {
        x = x, ldy
    }
    return(x)
}

real matrix _fdf_getCrit(real scalar T, real scalar model)
{
    real matrix crit

    if (model == 1) {
        if (T <= 150) {
            crit = (-4.42,-3.81,-3.49 \ -3.97,-3.27,-2.91 \ -3.77,-3.07,-2.71 \ -3.64,-2.97,-2.64 \ -3.58,-2.93,-2.60)
        }
        else if (T <= 349) {
            crit = (-4.37,-3.78,-3.47 \ -3.93,-3.26,-2.92 \ -3.74,-3.06,-2.72 \ -3.62,-2.98,-2.65 \ -3.55,-2.94,-2.62)
        }
        else if (T <= 500) {
            crit = (-4.35,-3.76,-3.46 \ -3.91,-3.26,-2.91 \ -3.70,-3.06,-2.72 \ -3.62,-2.97,-2.66 \ -3.56,-2.94,-2.62)
        }
        else {
            crit = (-4.31,-3.75,-3.45 \ -3.89,-3.25,-2.90 \ -3.69,-3.05,-2.71 \ -3.61,-2.96,-2.64 \ -3.53,-2.93,-2.61)
        }
    }
    else {
        if (T <= 150) {
            crit = (-4.95,-4.35,-4.05 \ -4.69,-4.05,-3.71 \ -4.45,-3.78,-3.44 \ -4.29,-3.65,-3.29 \ -4.20,-3.56,-3.22)
        }
        else if (T <= 349) {
            crit = (-4.87,-4.31,-4.02 \ -4.62,-4.01,-3.69 \ -4.38,-3.77,-3.43 \ -4.27,-3.63,-3.31 \ -4.18,-3.56,-3.24)
        }
        else if (T <= 500) {
            crit = (-4.81,-4.29,-4.01 \ -4.57,-3.99,-3.67 \ -4.38,-3.76,-3.43 \ -4.25,-3.64,-3.31 \ -4.18,-3.56,-3.25)
        }
        else {
            crit = (-4.80,-4.27,-4.00 \ -4.58,-3.98,-3.67 \ -4.38,-3.75,-3.43 \ -4.24,-3.63,-3.30 \ -4.16,-3.55,-3.24)
        }
    }
    return(crit)
}

real matrix _fdf_getFstatcv(real scalar model, real scalar T)
{
    real matrix crit

    if (model == 1) {
        if (T <= 150) {
            crit = (10.35, 7.58, 6.35)
        }
        else if (T <= 349) {
            crit = (10.02, 7.41, 6.25)
        }
        else if (T <= 500) {
            crit = (9.78, 7.29, 6.16)
        }
        else {
            crit = (9.72, 7.25, 6.11)
        }
    }
    else {
        if (T <= 150) {
            crit = (12.21, 9.14, 7.78)
        }
        else if (T <= 349) {
            crit = (11.70, 8.88, 7.62)
        }
        else if (T <= 500) {
            crit = (11.52, 8.76, 7.53)
        }
        else {
            crit = (11.35, 8.71, 7.50)
        }
    }
    return(crit)
}

real matrix _fdf_lagmatrix(real colvector x, real scalar maxlag)
{
    real scalar n, j
    real matrix L

    n = rows(x)
    L = J(n, maxlag, 0)
    for (j=1; j<=maxlag; j++) {
        L[j+1..n, j] = x[1..n-j,.]
    }
    return(L)
}

real scalar _fdf_get_lag(real scalar ic, real scalar pmax, real colvector aicp, real colvector sicp, real colvector tstatp)
{
    real scalar p, best_p, best_val

    if (ic == 1) {
        best_val = aicp[1]
        best_p = 0
        for (p=1; p<=pmax; p++) {
            if (aicp[p+1] < . & aicp[p+1] < best_val) {
                best_val = aicp[p+1]
                best_p = p
            }
        }
        return(best_p)
    }
    if (ic == 2) {
        best_val = sicp[1]
        best_p = 0
        for (p=1; p<=pmax; p++) {
            if (sicp[p+1] < . & sicp[p+1] < best_val) {
                best_val = sicp[p+1]
                best_p = p
            }
        }
        return(best_p)
    }
    best_p = 0
    for (p=pmax; p>=1; p--) {
        if (tstatp[p+1] < .) {
            if (abs(tstatp[p+1]) >= 1.645) {
                best_p = p
                break
            }
        }
    }
    return(best_p)
}

void _fdf_Ftest(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar k, real scalar p, real scalar model)
{
    real colvector y, t_vec, dy, ly, dc, dt, sink, cosk, dep
    real colvector sinp, cosp, y1, sbt, trnd, b1, b2, e1, e2
    real matrix lmat, ldy, z1, z2, cv_f
    real scalar ssr1, ssr2, k1, k2, F_stat

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    dy = y[2..T,.] - y[1..T-1,.]
    ly = y[1..T-1,.]
    dc = J(T, 1, 1)
    dt = t_vec
    sink = sin(2*pi()*k*t_vec/T)
    cosk = cos(2*pi()*k*t_vec/T)
    lmat = _fdf_lagmatrix(dy, p)
    dep  = dy[p+2..T-1,.]
    y1   = ly[p+2..T-1,.]
    sbt  = dc[p+2..T-1,.]
    trnd = dt[p+2..T-1,.]
    if (p == 0) {
        ldy = J(0,0,.)
    }
    else {
        ldy = lmat[p+2..T-1, 1..p]
    }
    sinp = sink[p+2..T-1,.]
    cosp = cosk[p+2..T-1,.]
    if (p == 0) {
        if (model == 1) {
            z1 = y1, sbt
        }
        else {
            z1 = y1, sbt, trnd
        }
    }
    else {
        if (model == 1) {
            z1 = y1, sbt, ldy
        }
        else {
            z1 = y1, sbt, trnd, ldy
        }
    }
    z2 = z1, sinp, cosp
    b1 = invsym(cross(z1,z1)) * cross(z1,dep)
    e1 = dep - z1 * b1
    ssr1 = quadcross(e1, e1)
    b2 = invsym(cross(z2,z2)) * cross(z2,dep)
    e2 = dep - z2 * b2
    ssr2 = quadcross(e2, e2)
    k1 = cols(z1)
    k2 = cols(z2)
    F_stat = ((ssr1 - ssr2) / (k2 - k1)) / (ssr2 / (rows(dep) - k2))
    cv_f = _fdf_getFstatcv(model, T)
    st_numscalar("r(Fstat)", F_stat)
    st_numscalar("r(Fcv1)",  cv_f[1,1])
    st_numscalar("r(Fcv5)",  cv_f[1,2])
    st_numscalar("r(Fcv10)", cv_f[1,3])
}

end
