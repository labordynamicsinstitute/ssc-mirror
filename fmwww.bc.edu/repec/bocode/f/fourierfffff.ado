*! fourierfffff v2.1  Omay (2015) Fractional Frequency Flexible Fourier Form DF Test
*! Economics Letters 134 (2015): 123-126
*! Extension of GAUSS Fourier_ADF to fractional frequencies
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fourierfffff, rclass
    version 14
    syntax varname(ts) [if] [in] [, Model(integer 2) Kfmin(real 0.1) Kfmax(real 2.0) KFstep(real 0.1) Kfr(real 0) Pmax(integer 8) IC(integer 3) NOTrend noFtest GRAPH]

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
        local modelname "Constant only (model=1)"
    }
    else {
        local modelname "Constant + Trend (model=2)"
    }

    di ""
    di as text "{hline 70}"
    di as text "  Fractional Frequency Flexible Fourier Form (FFFFF) DF Test"
    di as text "  Omay (2015) - Economics Letters 134:123-126"
    di as text "{hline 70}"
    di as text "  Variable : " as result "`varlist'" as text "   T = " as result `T'
    di as text "  Model    : " as result "`modelname'"
    if `kfr' > 0 {
        di as text "  k_fr     = " as result `kfr' as text " (user specified)"
    }
    else {
        di as text "  k_fr grid: [" as result `kfmin' as text ", " as result `kfmax' as text "] step=" as result `kfstep'
    }
    di as text "{hline 70}"

    mata: _fff_main("`y'", "`tvar'", "`touse'", `T', `pmax', `ic', `model', `kfmin', `kfmax', `kfstep', `kfr')

    local ADF_stat = r(ADFk)
    local kfhat    = r(kfr)
    local opt_lag  = r(p)
    local cv1      = r(cv1)
    local cv5      = r(cv5)
    local cv10     = r(cv10)
    local F_stat   = r(Fstat)
    local Fcv5     = r(Fcv5)

    if `ADF_stat' <= `cv1' {
        local sig "*** reject at 1%"
    }
    else if `ADF_stat' <= `cv5' {
        local sig "**  reject at 5%"
    }
    else if `ADF_stat' <= `cv10' {
        local sig "*   reject at 10%"
    }
    else {
        local sig "    cannot reject (unit root)"
    }

    if "`ftest'" == "" {
        if `F_stat' < . {
            di as text "  F-test (H0: no Fourier) = " as result %8.3f `F_stat' as text "   CV(5%)=" as result %6.3f `Fcv5'
            if `F_stat' >= `Fcv5' {
                di as text "  F decision: " as result "Fourier terms significant"
            }
            else {
                di as text "  F decision: " as result "Cannot reject linearity"
            }
            di ""
        }
    }

    di as text "  FFFFF-ADF statistic = " as result %9.3f `ADF_stat'
    di as text "  Fractional freq k_fr= " as result %9.4f `kfhat'
    di as text "  Lag order p         = " as result `opt_lag'
    di as text ""
    di as text "  Critical Values  [T=`T', model=`model', k_fr=`kfhat']:"
    di as text "    1%  : " as result %9.3f `cv1'
    di as text "    5%  : " as result %9.3f `cv5'
    di as text "    10% : " as result %9.3f `cv10'
    di as text ""
    di as text "  " as result "`sig'"
    di as text "{hline 70}"

    if "`graph'" != "" {
        quietly {
            tempvar sink_g cosk_g fitted_g
            gen double `sink_g' = sin(2*_pi*`kfhat'*`tvar'/`T') if `touse'
            gen double `cosk_g' = cos(2*_pi*`kfhat'*`tvar'/`T') if `touse'
            if `model' == 1 {
                reg `varlist' `sink_g' `cosk_g' if `touse'
            }
            else {
                reg `varlist' `tvar' `sink_g' `cosk_g' if `touse'
            }
            predict double `fitted_g' if `touse', xb
        }
        twoway (line `varlist' `tvar' if `touse', lcolor(blue) lwidth(thin)) ///
               (line `fitted_g' `tvar' if `touse', lcolor(red) lwidth(thick)), ///
               title("FFFFF-DF: `varlist' (k_fr=`kfhat')") ///
               legend(order(1 "`varlist'" 2 "Fourier expansion series")) ///
               graphregion(color(white)) bgcolor(white) ///
               name(fourierfffff_graph, replace)
    }

    return scalar ADFk          = `ADF_stat'
    return scalar tau_fr_stat   = `ADF_stat'
    return scalar kfr_selected  = `kfhat'
    return scalar p             = `opt_lag'
    return scalar lags_selected = `opt_lag'
    return scalar F_stat        = `F_stat'
    return scalar cv1           = `cv1'
    return scalar cv5           = `cv5'
    return scalar cv10          = `cv10'
end


mata:

void _fff_main(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar pmax, real scalar ic, real scalar model, real scalar kfmin, real scalar kfmax, real scalar kfstep, real scalar kfr_fix)
{
    real colvector y, t_vec, dy, ly, dc, dt, sink, cosk
    real scalar kf, kfhat, f_opt_lag, ADF_stat, ssr_min
    real matrix lmat, crit_v, ldy, z_reg, XtX_inv
    real scalar nsteps, i, best_i, min_dist, dd
    real colvector kf_grid, ssr_grid, tau_grid, lag_grid
    real colvector taup_v, aicp_v, sicp_v, tstatp_v, ssrp_v
    real scalar p, p_opt, nobs, ncols, ssr, tau_p, LL, aic_p, sic_p, tst_p
    real colvector dep, b, e, se_b
    real scalar F_stat, Fcv5, Fcv1, Fcv10

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    dy    = y[2..T,.] - y[1..T-1,.]
    ly    = y[1..T-1,.]
    dc    = J(T, 1, 1)
    dt    = t_vec
    lmat  = _fff_lagmatrix(dy, pmax)
    nsteps = round((kfmax - kfmin)/kfstep) + 1
    kf_grid  = J(nsteps, 1, .)
    ssr_grid = J(nsteps, 1, .)
    tau_grid = J(nsteps, 1, .)
    lag_grid = J(nsteps, 1, .)

    for (i = 1; i <= nsteps; i++) {
        kf = kfmin + (i-1)*kfstep
        kf_grid[i] = kf
        if (kfr_fix > 0 & abs(kf - kfr_fix) > kfstep/2) continue
        sink = sin(2*pi()*kf*t_vec/T)
        cosk = cos(2*pi()*kf*t_vec/T)
        taup_v   = J(pmax+1, 1, .)
        aicp_v   = J(pmax+1, 1, .)
        sicp_v   = J(pmax+1, 1, .)
        tstatp_v = J(pmax+1, 1, .)
        ssrp_v   = J(pmax+1, 1, .)
        for (p = 0; p <= pmax; p++) {
            if (p+2 > T-1) continue
            dep = dy[p+2..T-1,.]
            if (p == 0) {
                ldy = J(0,0,.)
            }
            else {
                ldy = lmat[p+2..T-1, 1..p]
            }
            z_reg = _fff_get_model_x(ly, p, model, ldy, dc, dt, sink, cosk, T)
            if (rows(z_reg) == 0) continue
            nobs  = rows(z_reg)
            ncols = cols(z_reg)
            if (nobs <= ncols) continue
            XtX_inv = invsym(cross(z_reg, z_reg))
            b       = XtX_inv * cross(z_reg, dep)
            e       = dep - z_reg * b
            ssr     = quadcross(e, e)
            se_b    = sqrt(diagonal(XtX_inv) * ssr / (nobs - ncols))
            tau_p   = b[1] / se_b[1]
            LL      = -nobs/2 * (1 + log(2*pi()) + log(ssr/nobs))
            aic_p   = (2*ncols - 2*LL) / nobs
            sic_p   = (ncols*log(nobs) - 2*LL) / nobs
            tst_p   = abs(b[ncols] / se_b[ncols])
            taup_v[p+1]   = tau_p
            aicp_v[p+1]   = aic_p
            sicp_v[p+1]   = sic_p
            tstatp_v[p+1] = tst_p
            ssrp_v[p+1]   = ssr
        }
        p_opt = _fff_get_lag(ic, pmax, aicp_v, sicp_v, tstatp_v)
        ssr_grid[i] = ssrp_v[p_opt+1]
        tau_grid[i] = taup_v[p_opt+1]
        lag_grid[i] = p_opt
    }

    if (kfr_fix > 0) {
        best_i = 1
        min_dist = abs(kf_grid[1] - kfr_fix)
        for (i = 2; i <= nsteps; i++) {
            dd = abs(kf_grid[i] - kfr_fix)
            if (dd < min_dist) {
                min_dist = dd
                best_i = i
            }
        }
    }
    else {
        best_i = 1
        ssr_min = .
        for (i = 1; i <= nsteps; i++) {
            if (ssr_grid[i] < . & (ssr_min == . | ssr_grid[i] < ssr_min)) {
                ssr_min = ssr_grid[i]
                best_i = i
            }
        }
    }
    kfhat     = kf_grid[best_i]
    ADF_stat  = tau_grid[best_i]
    f_opt_lag = lag_grid[best_i]
    F_stat = _fff_Ftest(y, t_vec, T, kfhat, f_opt_lag, model, dc, dt, dy, ly, lmat, pmax)
    Fcv5   = invFtail(2, T-6, 0.05)
    Fcv1   = invFtail(2, T-6, 0.01)
    Fcv10  = invFtail(2, T-6, 0.10)
    crit_v = _fff_getCrit(T, model, kfhat)
    st_numscalar("r(ADFk)",  ADF_stat)
    st_numscalar("r(kfr)",   kfhat)
    st_numscalar("r(p)",     f_opt_lag)
    st_numscalar("r(Fstat)", F_stat)
    st_numscalar("r(Fcv5)",  Fcv5)
    st_numscalar("r(cv1)",   crit_v[1])
    st_numscalar("r(cv5)",   crit_v[2])
    st_numscalar("r(cv10)",  crit_v[3])
}

real matrix _fff_get_model_x(real colvector ly, real scalar p, real scalar model, real matrix ldy, real colvector dc, real colvector dt, real colvector sink, real colvector cosk, real scalar T)
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

real scalar _fff_Ftest(real colvector y, real colvector t_vec, real scalar T, real scalar kf, real scalar p, real scalar model, real colvector dc, real colvector dt, real colvector dy, real colvector ly, real matrix lmat, real scalar pmax)
{
    real colvector sink, cosk, dep, y1, sbt, trnd, sinp, cosp
    real colvector b1, b2, e1, e2
    real matrix z1, z2, ldy
    real scalar ssr1, ssr2, k1, k2

    if (p+2 > T-1) return(.)
    sink = sin(2*pi()*kf*t_vec/T)
    cosk = cos(2*pi()*kf*t_vec/T)
    dep  = dy[p+2..T-1,.]
    y1   = ly[p+2..T-1,.]
    sbt  = dc[p+2..T-1,.]
    trnd = dt[p+2..T-1,.]
    sinp = sink[p+2..T-1,.]
    cosp = cosk[p+2..T-1,.]
    if (p == 0) {
        ldy = J(0,0,.)
    }
    else {
        ldy = lmat[p+2..T-1, 1..p]
    }
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
    ssr1 = quadcross(e1,e1)
    b2 = invsym(cross(z2,z2)) * cross(z2,dep)
    e2 = dep - z2 * b2
    ssr2 = quadcross(e2,e2)
    k1 = cols(z1)
    k2 = cols(z2)
    return(((ssr1-ssr2)/(k2-k1)) / (ssr2/(rows(dep)-k2)))
}

real colvector _fff_getCrit(real scalar T, real scalar model, real scalar kf)
{
    real matrix cv_table
    real scalar row_idx, col_start, kfr_round
    real colvector result

    if (T <= 100) {
        col_start = 1
    }
    else if (T <= 200) {
        col_start = 4
    }
    else if (T <= 500) {
        col_start = 7
    }
    else {
        col_start = 10
    }
    kfr_round = round(kf * 10) / 10
    if (kfr_round < 1.1 | kfr_round > 1.9) {
        if (model == 1) {
            result = (-3.75 \ -3.46 \ -3.15)
        }
        else {
            result = (-4.27 \ -4.00 \ -3.78)
        }
        return(result)
    }
    row_idx = round((kfr_round - 1.0) / 0.1)
    if (model == 1) {
        cv_table = (-4.39,-3.74,-3.42,-4.33,-3.72,-3.39,-4.27,-3.70,-3.38,-4.26,-3.68,-3.38 \ -4.31,-3.67,-3.33,-4.26,-3.64,-3.32,-4.23,-3.63,-3.31,-4.21,-3.62,-3.30 \ -4.29,-3.62,-3.26,-4.20,-3.58,-3.25,-4.19,-3.56,-3.24,-4.17,-3.56,-3.23 \ -4.22,-3.55,-3.20,-4.17,-3.53,-3.19,-4.12,-3.51,-3.17,-4.09,-3.51,-3.17 \ -4.14,-3.48,-3.13,-4.10,-3.47,-3.13,-4.07,-3.45,-3.12,-4.07,-3.45,-3.11 \ -4.10,-3.42,-3.07,-4.06,-3.40,-3.06,-4.05,-3.41,-3.06,-4.01,-3.39,-3.05 \ -4.06,-3.37,-3.01,-4.01,-3.36,-3.00,-3.99,-3.35,-3.01,-3.98,-3.34,-2.99 \ -4.00,-3.34,-2.97,-3.97,-3.32,-2.97,-3.95,-3.30,-2.96,-3.93,-3.31,-2.96 \ -3.99,-3.30,-2.94,-3.96,-3.29,-2.93,-3.94,-3.29,-2.94,-3.92,-3.28,-2.93)
    }
    else {
        cv_table = (-4.94,-4.36,-4.06,-4.87,-4.30,-4.01,-4.82,-4.29,-4.01,-4.80,-4.28,-4.00 \ -4.94,-4.35,-4.05,-4.86,-4.30,-4.00,-4.83,-4.28,-4.00,-4.80,-4.27,-4.00 \ -4.94,-4.34,-4.03,-4.85,-4.29,-4.01,-4.81,-4.27,-4.00,-4.80,-4.26,-3.99 \ -4.93,-4.32,-4.02,-4.85,-4.28,-3.98,-4.78,-4.25,-3.96,-4.78,-4.24,-3.96 \ -4.91,-4.28,-3.97,-4.81,-4.24,-3.95,-4.78,-4.21,-3.93,-4.76,-4.21,-3.92 \ -4.85,-4.23,-3.92,-4.79,-4.20,-3.90,-4.73,-4.17,-3.87,-4.71,-4.16,-3.87 \ -4.80,-4.20,-3.88,-4.74,-4.15,-3.84,-4.70,-4.14,-3.83,-4.67,-4.11,-3.81 \ -4.77,-4.14,-3.81,-4.69,-4.10,-3.79,-4.64,-4.08,-3.77,-4.64,-4.06,-3.76 \ -4.70,-4.09,-3.76,-4.64,-4.05,-3.73,-4.60,-4.02,-3.72,-4.60,-4.02,-3.72)
    }
    result = (cv_table[row_idx, col_start] \ cv_table[row_idx, col_start+1] \ cv_table[row_idx, col_start+2])
    return(result)
}

real matrix _fff_lagmatrix(real colvector x, real scalar maxlag)
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

real scalar _fff_get_lag(real scalar ic, real scalar pmax, real colvector aicp, real colvector sicp, real colvector tstatp)
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

end
