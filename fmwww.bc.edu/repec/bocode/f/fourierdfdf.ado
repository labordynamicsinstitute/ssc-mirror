*! fourierdfdf v1.0  Cai & Omay (2021) Double Frequency Fourier DF Unit Root Test
*! Computational Economics, 59: 445-470
*! With Sieve Bootstrap extension (Gerolimetto & Magrini, RIEDS 2026)
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fourierdfdf, rclass
    version 14
    syntax varname(ts) [if] [in] [, Model(integer 2) Kmax(real 3) DK(real 1) Pmax(integer 8) IC(integer 3) NOTrend GRAPH BOOTstrap BREPS(integer 500)]

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
    di as text "  Double Frequency Fourier Dickey-Fuller Unit Root Test"
    di as text "  Cai & Omay (2021), Computational Economics 59:445-470"
    if "`bootstrap'" != "" {
        di as text "  Sieve Bootstrap: Gerolimetto & Magrini (RIEDS 2026)"
    }
    di as text "{hline 70}"
    di as text "  Variable : " as result "`varlist'" as text "   T = " as result `T'
    di as text "  Model    : " as result "`modelname'"
    di as text "  Kmax=" as result `kmax' as text "  Dk=" as result `dk' as text "  Pmax=" as result `pmax' as text "  IC=" as result `ic'
    di as text "{hline 70}"

    mata: _dfdf_main("`y'", "`tvar'", "`touse'", `T', `pmax', `ic', `model', `kmax', `dk')

    local tau_stat  = r(tau_dfr)
    local ks        = r(ks)
    local kc        = r(kc)
    local opt_lag   = r(p)
    local F_stat    = r(F_dfr)
    local cv1       = r(cv1)
    local cv5       = r(cv5)
    local cv10      = r(cv10)
    local Fcv90     = r(Fcv90)
    local Fcv95     = r(Fcv95)
    local Fcv99     = r(Fcv99)

    * F-test for linearity
    di as text "  F-test for nonlinear trend (H0: alpha=beta=0)"
    di as text "  F_Dfr statistic     = " as result %9.3f `F_stat'
    di as text "  F CV: 90%=" as result %6.3f `Fcv90' as text "  95%=" as result %6.3f `Fcv95' as text "  99%=" as result %6.3f `Fcv99'
    if `F_stat' >= `Fcv95' {
        di as text "  Decision: " as result "Reject linearity - double Fourier terms significant"
    }
    else {
        di as text "  Decision: " as result "Cannot reject linearity (standard DF may be preferred)"
    }
    di ""

    * Bootstrap critical values if requested
    if "`bootstrap'" != "" {
        di as text "  Computing Sieve Bootstrap critical values (B=`breps') ..."
        mata: _dfdf_sieve_bootstrap("`y'", "`tvar'", "`touse'", `T', `pmax', `ic', `model', `ks', `kc', `breps')
        local bcv1  = r(bcv1)
        local bcv5  = r(bcv5)
        local bcv10 = r(bcv10)

        if `tau_stat' <= `bcv1' {
            local sig "*** reject at 1% (bootstrap)"
        }
        else if `tau_stat' <= `bcv5' {
            local sig "**  reject at 5% (bootstrap)"
        }
        else if `tau_stat' <= `bcv10' {
            local sig "*   reject at 10% (bootstrap)"
        }
        else {
            local sig "    cannot reject (unit root)"
        }

        di as text "  tau_Dfr statistic   = " as result %9.3f `tau_stat'
        di as text "  Optimal (k_s, k_c)  = (" as result `ks' as text ", " as result `kc' as text ")"
        di as text "  Lag order p         = " as result `opt_lag'
        di ""
        di as text "  Bootstrap Critical Values (B=`breps'):"
        di as text "    1%  : " as result %9.3f `bcv1'
        di as text "    5%  : " as result %9.3f `bcv5'
        di as text "    10% : " as result %9.3f `bcv10'
        di ""
        di as text "  Asymptotic Critical Values:"
        di as text "    1%  : " as result %9.3f `cv1'
        di as text "    5%  : " as result %9.3f `cv5'
        di as text "    10% : " as result %9.3f `cv10'

        return scalar bcv1  = `bcv1'
        return scalar bcv5  = `bcv5'
        return scalar bcv10 = `bcv10'
    }
    else {
        if `tau_stat' <= `cv1' {
            local sig "*** reject at 1%"
        }
        else if `tau_stat' <= `cv5' {
            local sig "**  reject at 5%"
        }
        else if `tau_stat' <= `cv10' {
            local sig "*   reject at 10%"
        }
        else {
            local sig "    cannot reject (unit root)"
        }

        di as text "  tau_Dfr statistic   = " as result %9.3f `tau_stat'
        di as text "  Optimal (k_s, k_c)  = (" as result `ks' as text ", " as result `kc' as text ")"
        di as text "  Lag order p         = " as result `opt_lag'
        di ""
        di as text "  Asymptotic Critical Values (T=`T'):"
        di as text "    1%  : " as result %9.3f `cv1'
        di as text "    5%  : " as result %9.3f `cv5'
        di as text "    10% : " as result %9.3f `cv10'
    }

    di ""
    di as text "  " as result "`sig'"
    di as text "{hline 70}"

    * Graph: 3 lines matching Cai & Omay (2021) Fig 1-2
    *   Black thick = Observed series (Breaks)
    *   Red thick   = Double frequency method (ks, kc)
    *   Blue thin   = Single frequency method (best single k)
    if "`graph'" != "" {
        quietly {
            * Double frequency fit (ks, kc)
            tempvar sins_g cosc_g fitted_dfr
            gen double `sins_g' = sin(2*_pi*`ks'*`tvar'/`T') if `touse'
            gen double `cosc_g' = cos(2*_pi*`kc'*`tvar'/`T') if `touse'
            if `model' == 1 {
                reg `varlist' `sins_g' `cosc_g' if `touse'
            }
            else {
                reg `varlist' `tvar' `sins_g' `cosc_g' if `touse'
            }
            predict double `fitted_dfr' if `touse', xb

            * Single frequency fit (best k by min SSR)
            tempvar sink1 cosk1 fitted_sfr
            local best_ssr = .
            local best_k1 = 1
            forvalues kk = 1/5 {
                tempvar s_tmp c_tmp
                gen double `s_tmp' = sin(2*_pi*`kk'*`tvar'/`T') if `touse'
                gen double `c_tmp' = cos(2*_pi*`kk'*`tvar'/`T') if `touse'
                if `model' == 1 {
                    reg `varlist' `s_tmp' `c_tmp' if `touse'
                }
                else {
                    reg `varlist' `tvar' `s_tmp' `c_tmp' if `touse'
                }
                local this_ssr = e(rss)
                if `this_ssr' < `best_ssr' {
                    local best_ssr = `this_ssr'
                    local best_k1 = `kk'
                }
                drop `s_tmp' `c_tmp'
            }
            gen double `sink1' = sin(2*_pi*`best_k1'*`tvar'/`T') if `touse'
            gen double `cosk1' = cos(2*_pi*`best_k1'*`tvar'/`T') if `touse'
            if `model' == 1 {
                reg `varlist' `sink1' `cosk1' if `touse'
            }
            else {
                reg `varlist' `tvar' `sink1' `cosk1' if `touse'
            }
            predict double `fitted_sfr' if `touse', xb
        }
        twoway (line `varlist' `tvar' if `touse', lcolor(black) lwidth(thick)) (line `fitted_dfr' `tvar' if `touse', lcolor(red) lwidth(medthick)) (line `fitted_sfr' `tvar' if `touse', lcolor(blue) lwidth(thin)), title("DFDF: `varlist'") legend(order(1 "`varlist'" 2 "Double frequency (ks=`ks', kc=`kc')" 3 "Single frequency (k=`best_k1')") size(small)) graphregion(color(white)) bgcolor(white) name(fourierdfdf_graph, replace)
    }

    return scalar tau_dfr      = `tau_stat'
    return scalar ks           = `ks'
    return scalar kc           = `kc'
    return scalar p            = `opt_lag'
    return scalar F_dfr        = `F_stat'
    return scalar cv1          = `cv1'
    return scalar cv5          = `cv5'
    return scalar cv10         = `cv10'
    return scalar Fcv90        = `Fcv90'
    return scalar Fcv95        = `Fcv95'
    return scalar Fcv99        = `Fcv99'
end


mata:

void _dfdf_main(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar pmax, real scalar ic, real scalar model, real scalar kmax, real scalar dk)
{
    real colvector y, t_vec, dy, ly, sink, cosk
    real scalar ks, kc, ks_opt, kc_opt, p_opt, tau_opt, ssr_min
    real scalar nks, nkc, iks, ikc
    real matrix lmat, crit_tau, crit_F
    real scalar tau_ks_kc, ssr_ks_kc, p_ks_kc, F_stat
    real colvector taup_v, aicp_v, sicp_v, tstatp_v, ssrp_v
    real scalar p, nobs, ncols, ssr, tau_p, LL, aic_p, sic_p, tst_p
    real colvector dep, b, e, se_b
    real matrix z_reg_v
    real matrix XtX_inv

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    dy    = y[2..T,.] - y[1..T-1,.]
    ly    = y[1..T-1,.]
    lmat  = _dfdf_lagmatrix(dy, pmax)

    nks = round((kmax - dk) / dk) + 1
    nkc = nks
    ssr_min = .
    ks_opt  = dk
    kc_opt  = dk
    p_opt   = 0
    tau_opt = .

    for (iks = 1; iks <= nks; iks++) {
        ks = iks * dk
        for (ikc = 1; ikc <= nkc; ikc++) {
            kc = ikc * dk
            sink = sin(2*pi()*ks*t_vec/T)
            cosk = cos(2*pi()*kc*t_vec/T)
            taup_v   = J(pmax+1, 1, .)
            aicp_v   = J(pmax+1, 1, .)
            sicp_v   = J(pmax+1, 1, .)
            tstatp_v = J(pmax+1, 1, .)
            ssrp_v   = J(pmax+1, 1, .)
            for (p = 0; p <= pmax; p++) {
                if (p+2 > T-1) continue
                dep = dy[p+2..T-1,.]
                z_reg_v = _dfdf_build_x(ly, p, model, lmat, sink, cosk, T)
                if (rows(z_reg_v) == 0) continue
                nobs  = rows(z_reg_v)
                ncols = cols(z_reg_v)
                if (nobs <= ncols) continue
                XtX_inv = invsym(cross(z_reg_v, z_reg_v))
                b       = XtX_inv * cross(z_reg_v, dep)
                e       = dep - z_reg_v * b
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
            p = _dfdf_get_lag(ic, pmax, aicp_v, sicp_v, tstatp_v)
            ssr_ks_kc = ssrp_v[p+1]
            tau_ks_kc = taup_v[p+1]
            p_ks_kc   = p
            if (ssr_ks_kc < . & (ssr_min == . | ssr_ks_kc < ssr_min)) {
                ssr_min = ssr_ks_kc
                ks_opt  = ks
                kc_opt  = kc
                p_opt   = p_ks_kc
                tau_opt = tau_ks_kc
            }
        }
    }

    F_stat = _dfdf_Ftest(y, t_vec, T, ks_opt, kc_opt, p_opt, model, dy, ly, lmat)
    crit_tau = _dfdf_getCritTau(T, model, ks_opt, kc_opt)
    crit_F   = _dfdf_getCritF(T, model, kmax, dk)

    st_numscalar("r(tau_dfr)", tau_opt)
    st_numscalar("r(ks)",      ks_opt)
    st_numscalar("r(kc)",      kc_opt)
    st_numscalar("r(p)",       p_opt)
    st_numscalar("r(F_dfr)",   F_stat)
    st_numscalar("r(cv10)",    crit_tau[1])
    st_numscalar("r(cv5)",     crit_tau[2])
    st_numscalar("r(cv1)",     crit_tau[3])
    st_numscalar("r(Fcv90)",   crit_F[1])
    st_numscalar("r(Fcv95)",   crit_F[2])
    st_numscalar("r(Fcv99)",   crit_F[3])
}

real matrix _dfdf_build_x(real colvector ly, real scalar p, real scalar model, real matrix lmat, real colvector sink, real colvector cosk, real scalar T)
{
    real colvector yt_t, c_t, sink_t, cosk_t, trend_t
    real matrix x, ldy

    if (p+2 > T-1) return(J(0,0,.))
    yt_t   = ly[p+2..T-1,.]
    c_t    = J(T-1-p-1, 1, 1)
    sink_t = sink[p+2..T-1,.]
    cosk_t = cosk[p+2..T-1,.]
    trend_t= (p+2..T-1)'
    if (model == 1) {
        x = yt_t, c_t, sink_t, cosk_t
    }
    else {
        x = yt_t, c_t, trend_t, sink_t, cosk_t
    }
    if (p > 0) {
        ldy = lmat[p+2..T-1, 1..p]
        x = x, ldy
    }
    return(x)
}

real scalar _dfdf_Ftest(real colvector y, real colvector t_vec, real scalar T, real scalar ks, real scalar kc, real scalar p, real scalar model, real colvector dy, real colvector ly, real matrix lmat)
{
    real colvector dep, y1, sbt, trnd, sinp, cosp
    real colvector b1, b2, e1, e2
    real matrix z1, z2, ldy
    real scalar ssr1, ssr2, k1, k2

    if (p+2 > T-1) return(.)
    sinp = sin(2*pi()*ks*t_vec/T)
    cosp = cos(2*pi()*kc*t_vec/T)
    dep  = dy[p+2..T-1,.]
    y1   = ly[p+2..T-1,.]
    sbt  = J(rows(dep), 1, 1)
    trnd = (p+2..T-1)'
    sinp = sinp[p+2..T-1,.]
    cosp = cosp[p+2..T-1,.]

    if (p == 0) {
        if (model == 1) {
            z1 = y1, sbt
        }
        else {
            z1 = y1, sbt, trnd
        }
    }
    else {
        ldy = lmat[p+2..T-1, 1..p]
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
    return(((ssr1 - ssr2) / (k2 - k1)) / (ssr2 / (rows(dep) - k2)))
}

real colvector _dfdf_getCritTau(real scalar T, real scalar model, real scalar ks, real scalar kc)
{
    real scalar ks_r, kc_r
    real colvector cv

    ks_r = round(ks)
    kc_r = round(kc)
    if (ks_r < 1) ks_r = 1
    if (kc_r < 1) kc_r = 1
    if (ks_r > 3) ks_r = 3
    if (kc_r > 3) kc_r = 3

    if (model == 1) {
        if (T <= 100) {
            if (ks_r==1 & kc_r==1) cv = (-3.526 \ -3.852 \ -4.580)
            else if (ks_r==1 & kc_r==2) cv = (-3.502 \ -3.910 \ -4.739)
            else if (ks_r==1 & kc_r==3) cv = (-3.332 \ -3.755 \ -4.509)
            else if (ks_r==2 & kc_r==1) cv = (-3.481 \ -3.882 \ -4.744)
            else if (ks_r==2 & kc_r==2) cv = (-2.888 \ -3.274 \ -4.013)
            else if (ks_r==2 & kc_r==3) cv = (-2.927 \ -3.367 \ -4.210)
            else if (ks_r==3 & kc_r==1) cv = (-3.252 \ -3.646 \ -4.522)
            else if (ks_r==3 & kc_r==2) cv = (-2.885 \ -3.269 \ -4.061)
            else cv = (-2.705 \ -3.081 \ -3.868)
        }
        else if (T <= 200) {
            if (ks_r==1 & kc_r==1) cv = (-3.486 \ -3.798 \ -4.403)
            else if (ks_r==1 & kc_r==2) cv = (-3.463 \ -3.823 \ -4.480)
            else if (ks_r==1 & kc_r==3) cv = (-3.260 \ -3.615 \ -4.360)
            else if (ks_r==2 & kc_r==1) cv = (-3.371 \ -3.761 \ -4.426)
            else if (ks_r==2 & kc_r==2) cv = (-2.909 \ -3.271 \ -3.942)
            else if (ks_r==2 & kc_r==3) cv = (-2.907 \ -3.283 \ -3.975)
            else if (ks_r==3 & kc_r==1) cv = (-3.238 \ -3.609 \ -4.392)
            else if (ks_r==3 & kc_r==2) cv = (-2.864 \ -3.278 \ -4.044)
            else cv = (-2.716 \ -3.056 \ -3.727)
        }
        else {
            if (ks_r==1 & kc_r==1) cv = (-3.455 \ -3.762 \ -4.363)
            else if (ks_r==1 & kc_r==2) cv = (-3.394 \ -3.781 \ -4.468)
            else if (ks_r==1 & kc_r==3) cv = (-3.320 \ -3.662 \ -4.314)
            else if (ks_r==2 & kc_r==1) cv = (-3.349 \ -3.731 \ -4.390)
            else if (ks_r==2 & kc_r==2) cv = (-2.906 \ -3.257 \ -3.934)
            else if (ks_r==2 & kc_r==3) cv = (-2.895 \ -3.259 \ -3.946)
            else if (ks_r==3 & kc_r==1) cv = (-3.202 \ -3.576 \ -4.258)
            else if (ks_r==3 & kc_r==2) cv = (-2.891 \ -3.273 \ -3.960)
            else cv = (-2.704 \ -3.026 \ -3.646)
        }
    }
    else {
        if (T <= 100) {
            if (ks_r==1 & kc_r==1) cv = (-4.100 \ -4.452 \ -5.062)
            else if (ks_r==1 & kc_r==2) cv = (-4.038 \ -4.432 \ -5.200)
            else if (ks_r==1 & kc_r==3) cv = (-3.862 \ -4.257 \ -5.031)
            else if (ks_r==2 & kc_r==1) cv = (-4.230 \ -4.580 \ -5.332)
            else if (ks_r==2 & kc_r==2) cv = (-3.728 \ -4.076 \ -4.778)
            else if (ks_r==2 & kc_r==3) cv = (-3.770 \ -4.207 \ -5.056)
            else if (ks_r==3 & kc_r==1) cv = (-4.030 \ -4.407 \ -5.133)
            else if (ks_r==3 & kc_r==2) cv = (-3.754 \ -4.170 \ -5.000)
            else cv = (-3.434 \ -3.808 \ -4.631)
        }
        else if (T <= 200) {
            if (ks_r==1 & kc_r==1) cv = (-4.026 \ -4.320 \ -4.956)
            else if (ks_r==1 & kc_r==2) cv = (-3.959 \ -4.300 \ -4.939)
            else if (ks_r==1 & kc_r==3) cv = (-3.839 \ -4.199 \ -4.842)
            else if (ks_r==2 & kc_r==1) cv = (-4.117 \ -4.438 \ -5.046)
            else if (ks_r==2 & kc_r==2) cv = (-3.659 \ -4.001 \ -4.696)
            else if (ks_r==2 & kc_r==3) cv = (-3.721 \ -4.053 \ -4.784)
            else if (ks_r==3 & kc_r==1) cv = (-3.922 \ -4.251 \ -4.889)
            else if (ks_r==3 & kc_r==2) cv = (-3.699 \ -4.046 \ -4.717)
            else cv = (-3.420 \ -3.759 \ -4.395)
        }
        else {
            if (ks_r==1 & kc_r==1) cv = (-4.023 \ -4.302 \ -4.870)
            else if (ks_r==1 & kc_r==2) cv = (-3.945 \ -4.264 \ -4.894)
            else if (ks_r==1 & kc_r==3) cv = (-3.803 \ -4.147 \ -4.775)
            else if (ks_r==2 & kc_r==1) cv = (-4.102 \ -4.393 \ -4.966)
            else if (ks_r==2 & kc_r==2) cv = (-3.677 \ -3.990 \ -4.582)
            else if (ks_r==2 & kc_r==3) cv = (-3.691 \ -4.037 \ -4.694)
            else if (ks_r==3 & kc_r==1) cv = (-3.928 \ -4.250 \ -4.871)
            else if (ks_r==3 & kc_r==2) cv = (-3.665 \ -4.016 \ -4.620)
            else cv = (-3.448 \ -3.783 \ -4.354)
        }
    }
    return(cv)
}

real colvector _dfdf_getCritF(real scalar T, real scalar model, real scalar kmax, real scalar dk)
{
    real scalar km
    real colvector cv

    km = round(kmax)
    if (km < 1) km = 1
    if (km > 3) km = 3

    if (model == 1) {
        if (T <= 100) {
            if (km == 1) cv = (6.097 \ 7.521 \ 10.982)
            else if (km == 2) cv = (7.479 \ 9.099 \ 12.731)
            else cv = (7.939 \ 9.478 \ 13.175)
        }
        else if (T <= 200) {
            if (km == 1) cv = (5.701 \ 7.076 \ 10.027)
            else if (km == 2) cv = (6.842 \ 8.165 \ 11.198)
            else cv = (7.400 \ 8.701 \ 11.504)
        }
        else {
            if (km == 1) cv = (5.708 \ 7.017 \ 9.674)
            else if (km == 2) cv = (6.734 \ 8.023 \ 10.461)
            else cv = (7.107 \ 8.372 \ 11.197)
        }
    }
    else {
        if (T <= 100) {
            if (km == 1) cv = (7.355 \ 8.921 \ 12.813)
            else if (km == 2) cv = (8.974 \ 10.729 \ 14.910)
            else cv = (9.785 \ 11.450 \ 15.195)
        }
        else if (T <= 200) {
            if (km == 1) cv = (7.087 \ 8.546 \ 11.435)
            else if (km == 2) cv = (8.423 \ 9.942 \ 13.139)
            else cv = (9.100 \ 10.554 \ 13.346)
        }
        else {
            if (km == 1) cv = (6.762 \ 8.217 \ 11.298)
            else if (km == 2) cv = (8.139 \ 9.524 \ 12.289)
            else cv = (8.798 \ 10.095 \ 12.869)
        }
    }
    return(cv)
}


void _dfdf_sieve_bootstrap(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar pmax, real scalar ic, real scalar model, real scalar ks_fix, real scalar kc_fix, real scalar B)
{
    real colvector y, t_vec, dy, resid, ar_coef, x_star, y_star
    real colvector boot_tau, sink, cosk, dep, b, e, se_b
    real matrix X_ar, XtX_inv, lmat, z_reg_v
    real scalar p_ar, i, j, n_dy, ssr, nobs, ncols, tau_b
    real scalar cv1, cv5, cv10
    real colvector taup_v, aicp_v, sicp_v, tstatp_v, ssrp_v
    real scalar p, p_b, tau_p, LL, aic_p, sic_p, tst_p

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    dy    = y[2..T,.] - y[1..T-1,.]
    n_dy  = rows(dy)

    p_ar = min((floor(sqrt(n_dy)), 12))
    if (p_ar < 1) p_ar = 1
    X_ar = J(n_dy - p_ar, p_ar, 0)
    for (j = 1; j <= p_ar; j++) {
        X_ar[.,j] = dy[p_ar+1-j..n_dy-j,.]
    }
    dep = dy[p_ar+1..n_dy,.]
    XtX_inv = invsym(cross(X_ar, X_ar))
    ar_coef = XtX_inv * cross(X_ar, dep)
    resid = dep - X_ar * ar_coef
    resid = resid :- mean(resid)

    boot_tau = J(B, 1, .)
    sink = sin(2*pi()*ks_fix*t_vec/T)
    cosk = cos(2*pi()*kc_fix*t_vec/T)

    for (i = 1; i <= B; i++) {
        x_star = J(n_dy, 1, 0)
        for (j = p_ar+1; j <= n_dy; j++) {
            x_star[j] = resid[ceil(rows(resid) * uniform(1,1))]
            for (p = 1; p <= p_ar; p++) {
                x_star[j] = x_star[j] + ar_coef[p] * x_star[j-p]
            }
        }
        y_star = J(T, 1, 0)
        y_star[1] = 0
        for (j = 2; j <= T; j++) {
            y_star[j] = y_star[j-1] + x_star[j-1]
        }
        dy = y_star[2..T,.] - y_star[1..T-1,.]
        lmat = _dfdf_lagmatrix(dy, pmax)

        taup_v   = J(pmax+1, 1, .)
        aicp_v   = J(pmax+1, 1, .)
        sicp_v   = J(pmax+1, 1, .)
        tstatp_v = J(pmax+1, 1, .)
        ssrp_v   = J(pmax+1, 1, .)

        for (p = 0; p <= pmax; p++) {
            if (p+2 > T-1) continue
            dep = dy[p+2..T-1,.]
            z_reg_v = _dfdf_build_x(y_star[1..T-1,.], p, model, lmat, sink, cosk, T)
            if (rows(z_reg_v) == 0) continue
            nobs  = rows(z_reg_v)
            ncols = cols(z_reg_v)
            if (nobs <= ncols) continue
            XtX_inv = invsym(cross(z_reg_v, z_reg_v))
            b       = XtX_inv * cross(z_reg_v, dep)
            e       = dep - z_reg_v * b
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
        p_b = _dfdf_get_lag(ic, pmax, aicp_v, sicp_v, tstatp_v)
        boot_tau[i] = taup_v[p_b+1]
    }

    _sort(boot_tau, 1)
    cv1  = boot_tau[max((1, floor(0.01*B)))]
    cv5  = boot_tau[max((1, floor(0.05*B)))]
    cv10 = boot_tau[max((1, floor(0.10*B)))]

    st_numscalar("r(bcv1)",  cv1)
    st_numscalar("r(bcv5)",  cv5)
    st_numscalar("r(bcv10)", cv10)
}


real matrix _dfdf_lagmatrix(real colvector x, real scalar maxlag)
{
    real scalar n, j
    real matrix L

    n = rows(x)
    L = J(n, maxlag, 0)
    for (j = 1; j <= maxlag; j++) {
        L[j+1..n, j] = x[1..n-j,.]
    }
    return(L)
}

real scalar _dfdf_get_lag(real scalar ic, real scalar pmax, real colvector aicp, real colvector sicp, real colvector tstatp)
{
    real scalar p, best_p, best_val

    if (ic == 1) {
        best_val = aicp[1]
        best_p = 0
        for (p = 1; p <= pmax; p++) {
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
        for (p = 1; p <= pmax; p++) {
            if (sicp[p+1] < . & sicp[p+1] < best_val) {
                best_val = sicp[p+1]
                best_p = p
            }
        }
        return(best_p)
    }
    best_p = 0
    for (p = pmax; p >= 1; p--) {
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
