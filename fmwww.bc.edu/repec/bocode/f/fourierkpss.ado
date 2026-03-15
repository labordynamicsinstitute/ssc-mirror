*! fourierkpss v2.0  Becker, Enders & Lee (2006) Fourier KPSS Stationarity Test
*! Journal of Time Series Analysis, 27(3), 381-409
*! Ported from GAUSS code by Saban Nazlioglu
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fourierkpss, rclass
    version 14
    syntax varname(ts) [if] [in] [, Model(integer 2) Kmax(integer 5) K(integer 0) NOTrend GRAPH]

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
    di as text "  Fourier KPSS Stationarity Test"
    di as text "  Becker, Enders & Lee (2006), J. Time Series Anal. 27(3):381-409"
    di as text "{hline 70}"
    di as text "  Variable : " as result "`varlist'" as text "   T = " as result `T'
    di as text "  Model    : " as result "`modelname'"
    di as text "  Kmax=" as result `kmax'
    di as text "{hline 70}"

    mata: _fkpss_main("`y'", "`tvar'", "`touse'", `T', `kmax', `model', `k')

    local KPSS_stat = r(KPSSk)
    local f         = r(k)
    local cv1       = r(cv1)
    local cv5       = r(cv5)
    local cv10      = r(cv10)

    if `KPSS_stat' >= `cv1' {
        local sig "*** reject stationarity at 1%"
    }
    else if `KPSS_stat' >= `cv5' {
        local sig "**  reject stationarity at 5%"
    }
    else if `KPSS_stat' >= `cv10' {
        local sig "*   reject stationarity at 10%"
    }
    else {
        local sig "    cannot reject stationarity"
    }

    di as text "  KPSS statistic      = " as result %9.4f `KPSS_stat'
    di as text "  Optimal frequency k = " as result `f'
    di as text ""
    di as text "  Critical Values  [T=`T', model=`model', k=`f']:"
    di as text "    1%  : " as result %9.4f `cv1'
    di as text "    5%  : " as result %9.4f `cv5'
    di as text "    10% : " as result %9.4f `cv10'
    di as text ""
    di as text "  " as result "`sig'"
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
        twoway (line `varlist' `tvar' if `touse', lcolor(blue) lwidth(thin)) ///
               (line `fitted_g' `tvar' if `touse', lcolor(red) lwidth(thick)), ///
               title("Fourier KPSS: `varlist' (k=`f')") ///
               legend(order(1 "`varlist'" 2 "Fourier expansion series")) ///
               graphregion(color(white)) bgcolor(white) ///
               name(fourierkpss_graph, replace)
    }

    return scalar KPSSk        = `KPSS_stat'
    return scalar k            = `f'
    return scalar k_selected   = `f'
    return scalar cv1          = `cv1'
    return scalar cv5          = `cv5'
    return scalar cv10         = `cv10'
end


mata:

void _fkpss_main(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar kmax, real scalar model, real scalar kfix)
{
    real colvector y, t_vec, sink, cosk
    real scalar k, f, KPSS_stat, min_ssr, ssr_k
    real matrix z, crit
    real colvector b, e, S
    real scalar lrv

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)

    f = 1
    min_ssr = .

    for (k = 1; k <= kmax; k++) {
        if (kfix > 0 & k != kfix) continue
        sink = sin(2*pi()*k*t_vec/T)
        cosk = cos(2*pi()*k*t_vec/T)
        if (model == 1) {
            z = J(T,1,1), sink, cosk
        }
        else {
            z = J(T,1,1), t_vec, sink, cosk
        }
        b = invsym(cross(z,z)) * cross(z,y)
        e = y - z * b
        ssr_k = quadcross(e,e)
        if (ssr_k < min_ssr | min_ssr == .) {
            min_ssr = ssr_k
            f = k
        }
    }

    sink = sin(2*pi()*f*t_vec/T)
    cosk = cos(2*pi()*f*t_vec/T)
    if (model == 1) {
        z = J(T,1,1), sink, cosk
    }
    else {
        z = J(T,1,1), t_vec, sink, cosk
    }
    b = invsym(cross(z,z)) * cross(z,y)
    e = y - z * b
    S = _fkpss_cumsum(e)
    lrv = quadcross(e,e) / T
    KPSS_stat = quadcross(S,S) / (T * T * lrv)

    crit = _fkpss_getCrit(T, model)

    st_numscalar("r(KPSSk)", KPSS_stat)
    st_numscalar("r(k)",     f)
    st_numscalar("r(cv1)",   crit[f,1])
    st_numscalar("r(cv5)",   crit[f,2])
    st_numscalar("r(cv10)",  crit[f,3])
}

real colvector _fkpss_cumsum(real colvector x)
{
    real scalar n, i
    real colvector S
    n = rows(x)
    S = J(n, 1, 0)
    S[1] = x[1]
    for (i = 2; i <= n; i++) {
        S[i] = S[i-1] + x[i]
    }
    return(S)
}

real matrix _fkpss_getCrit(real scalar T, real scalar model)
{
    real matrix crit

    if (model == 1) {
        if (T <= 250) {
            crit = (0.2699,0.1720,0.1318 \ 0.6671,0.4152,0.3150 \ 0.7182,0.4480,0.3393 \ 0.7222,0.4592,0.3476 \ 0.7386,0.4626,0.3518)
        }
        else if (T <= 500) {
            crit = (0.2709,0.1696,0.1294 \ 0.6615,0.4075,0.3053 \ 0.7046,0.4424,0.3309 \ 0.7152,0.4491,0.3369 \ 0.7344,0.4571,0.3415)
        }
        else {
            crit = (0.2706,0.1704,0.1295 \ 0.6526,0.4047,0.3050 \ 0.7086,0.4388,0.3304 \ 0.7163,0.4470,0.3355 \ 0.7297,0.4525,0.3422)
        }
    }
    else {
        if (T <= 250) {
            crit = (0.0716,0.0546,0.0471 \ 0.2022,0.1321,0.1034 \ 0.2103,0.1423,0.1141 \ 0.2170,0.1478,0.1189 \ 0.2177,0.1484,0.1201)
        }
        else if (T <= 500) {
            crit = (0.0720,0.0539,0.0463 \ 0.1968,0.1278,0.0995 \ 0.2091,0.1404,0.1123 \ 0.2111,0.1441,0.1155 \ 0.2178,0.1465,0.1178)
        }
        else {
            crit = (0.0718,0.0538,0.0461 \ 0.1959,0.1275,0.0994 \ 0.2081,0.1398,0.1117 \ 0.2139,0.1436,0.1149 \ 0.2153,0.1451,0.1163)
        }
    }
    return(crit)
}

end
