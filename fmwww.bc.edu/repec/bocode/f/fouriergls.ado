*! fouriergls v2.1  Rodrigues & Taylor (2012) Fourier GLS Unit Root Test
*! Oxford Bulletin of Economics and Statistics, 74(5): 736-759
*! Port of GAUSS code by Saban Nazlioglu
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fouriergls, rclass
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
        local modelname "Constant only (model=1)"
    }
    else {
        local modelname "Constant + Trend (model=2)"
    }

    di ""
    di as text "{hline 70}"
    di as text "  Fourier GLS Unit Root Test"
    di as text "  Rodrigues & Taylor (2012), Oxford Bull.Econ.Stat. 74(5):736-759"
    di as text "{hline 70}"
    di as text "  Variable : " as result "`varlist'" as text "   T = " as result `T'
    di as text "  Model    : " as result "`modelname'"
    di as text "  Pmax=" as result `pmax' as text "  Kmax=" as result `kmax' as text "  IC=" as result `ic'
    di as text "{hline 70}"

    mata: _fgls_main("`y'", "`tvar'", "`touse'", `T', `pmax', `kmax', `ic', `model', `k')

    local GLS_stat = r(GLSk)
    local f        = r(k)
    local opt_lag  = r(p)
    local cv1      = r(cv1)
    local cv5      = r(cv5)
    local cv10     = r(cv10)
    local cbar     = r(cbar)

    if `GLS_stat' <= `cv1' {
        local sig "*** reject at 1%"
    }
    else if `GLS_stat' <= `cv5' {
        local sig "**  reject at 5%"
    }
    else if `GLS_stat' <= `cv10' {
        local sig "*   reject at 10%"
    }
    else {
        local sig "    cannot reject (unit root)"
    }

    di as text "  GLS (ADF) statistic = " as result %9.3f `GLS_stat'
    di as text "  Frequency   k       = " as result `f'
    di as text "  c_bar               = " as result %9.4f `cbar'
    di as text "  Lag order   p       = " as result `opt_lag'
    di as text ""
    di as text "  Critical Values  [T=`T', model=`model', k=`f']:"
    di as text "    1%  : " as result %9.3f `cv1'
    di as text "    5%  : " as result %9.3f `cv5'
    di as text "    10% : " as result %9.3f `cv10'
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
        twoway (line `varlist' `tvar' if `touse', lcolor(blue) lwidth(thin)) (line `fitted_g' `tvar' if `touse', lcolor(red) lwidth(thick)), title("Fourier GLS: `varlist' (k=`f')") legend(order(1 "`varlist'" 2 "Fourier expansion series")) graphregion(color(white)) bgcolor(white) name(fouriergls_graph, replace)
    }

    return scalar GLSk         = `GLS_stat'
    return scalar ters_stat    = `GLS_stat'
    return scalar k            = `f'
    return scalar k_selected   = `f'
    return scalar p            = `opt_lag'
    return scalar lags_selected= `opt_lag'
    return scalar cbar         = `cbar'
    return scalar cv1          = `cv1'
    return scalar cv5          = `cv5'
    return scalar cv10         = `cv10'
end


program define fourierGLSFTest, rclass
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

    mata: _fgls_Ftest("`y'", "`tvar'", "`touse'", `T', `k', `p', `model')

    local F_stat = r(Fstat)
    local Fcv1   = r(Fcv1)
    local Fcv5   = r(Fcv5)
    local Fcv10  = r(Fcv10)

    di ""
    di as text "  Fourier GLS F-Test for Linearity"
    di as text "  H0: no Fourier terms (alpha_k=beta_k=0)"
    di as text "  k=" as result `k' as text "  p=" as result `p' as text "  model=" as result `model'
    di as text "  F-statistic = " as result %9.3f `F_stat'
    di as text "  CV: 1%=" as result %6.3f `Fcv1' as text "  5%=" as result %6.3f `Fcv5' as text "  10%=" as result %6.3f `Fcv10'
    if `F_stat' >= `Fcv5' {
        di as text "  Decision: reject linearity (Fourier terms significant)"
    }
    else {
        di as text "  Decision: cannot reject linearity"
    }

    return scalar Fstat = `F_stat'
    return scalar Fcv1  = `Fcv1'
    return scalar Fcv5  = `Fcv5'
    return scalar Fcv10 = `Fcv10'
end


mata:

void _fgls_main(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar pmax, real scalar kmax, real scalar ic, real scalar model, real scalar kfix)
{
    real colvector y, t_vec, sink, cosk, ygls, dy_gls, ly_gls
    real colvector ssrk, tauk, keep_p
    real scalar k, f, GLS_stat, opt_lag, cbar_f, ms, kk, cbar
    real matrix crit, z, lmat, z_reg, ldy, XtX_inv
    real colvector taup_v, aicp_v, sicp_v, tstatp_v, ssrp_v
    real scalar p, p_opt, nobs, ncols, ssr, tau_p, aic_p, sic_p, tst_p
    real colvector dep, y1, b, e, se_b

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    ssrk   = J(kmax, 1, .)
    tauk   = J(kmax, 1, .)
    keep_p = J(kmax, 1, .)

    for (k = 1; k <= kmax; k++) {
        if (kfix > 0 & k != kfix) continue
        cbar = _fgls_getCbar(model, k)
        sink = sin(2*pi()*k*t_vec/T)
        cosk = cos(2*pi()*k*t_vec/T)
        if (model == 1) {
            z = J(T,1,1), sink, cosk
        }
        else {
            z = J(T,1,1), t_vec, sink, cosk
        }
        ygls = _fgls_glsDetrend(y, z, cbar, T)
        dy_gls = ygls[2..T,.] - ygls[1..T-1,.]
        ly_gls = ygls[1..T-1,.]
        lmat = _fgls_lagmatrix(dy_gls, pmax)
        taup_v   = J(pmax+1, 1, .)
        aicp_v   = J(pmax+1, 1, .)
        sicp_v   = J(pmax+1, 1, .)
        tstatp_v = J(pmax+1, 1, .)
        ssrp_v   = J(pmax+1, 1, .)
        for (p = 0; p <= pmax; p++) {
            if (p+2 > T-1) continue
            dep = dy_gls[p+2..T-1,.]
            y1  = ly_gls[p+2..T-1,.]
            if (p == 0) {
                z_reg = y1
            }
            else {
                ldy = lmat[p+2..T-1, 1..p]
                z_reg = y1, ldy
            }
            nobs  = rows(z_reg)
            ncols = cols(z_reg)
            if (nobs <= ncols) continue
            XtX_inv = invsym(cross(z_reg, z_reg))
            b       = XtX_inv * cross(z_reg, dep)
            e       = dep - z_reg * b
            ssr     = quadcross(e, e)
            se_b    = sqrt(diagonal(XtX_inv) * ssr / (nobs - ncols))
            tau_p   = b[1] / se_b[1]
            aic_p   = log(ssr/nobs) + 2*(ncols+2)/nobs
            sic_p   = log(ssr/nobs) + (ncols+2)*log(nobs)/nobs
            tst_p   = b[ncols] / se_b[ncols]
            taup_v[p+1]   = tau_p
            aicp_v[p+1]   = aic_p
            sicp_v[p+1]   = sic_p
            tstatp_v[p+1] = tst_p
            ssrp_v[p+1]   = ssr
        }
        p_opt     = _fgls_get_lag(ic, pmax, aicp_v, sicp_v, tstatp_v)
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
        for (kk = 2; kk <= kmax; kk++) {
            if (ssrk[kk] < . & ssrk[kk] < ms) {
                ms = ssrk[kk]
                f = kk
            }
        }
    }
    GLS_stat = tauk[f]
    opt_lag  = keep_p[f]
    cbar_f   = _fgls_getCbar(model, f)
    crit     = _fgls_getCrit(T, model)
    st_numscalar("r(GLSk)", GLS_stat)
    st_numscalar("r(k)",    f)
    st_numscalar("r(p)",    opt_lag)
    st_numscalar("r(cbar)", cbar_f)
    st_numscalar("r(cv1)",  crit[f,1])
    st_numscalar("r(cv5)",  crit[f,2])
    st_numscalar("r(cv10)", crit[f,3])
}

real colvector _fgls_glsDetrend(real colvector y, real matrix z, real scalar cbar, real scalar T)
{
    real scalar a
    real colvector ya, bhat
    real matrix za

    a       = 1 + cbar/T
    ya      = J(T, 1, 0)
    za      = J(T, cols(z), 0)
    ya[1]   = y[1]
    za[1,.] = z[1,.]
    ya[2..T]   = y[2..T] :- a * y[1..T-1]
    za[2..T,.] = z[2..T,.] :- a * z[1..T-1,.]
    bhat    = invsym(cross(za, za)) * cross(za, ya)
    return(y :- z * bhat)
}

real scalar _fgls_getCbar(real scalar model, real scalar k)
{
    real matrix cbars

    cbars = (-7.00,-13.50 \ -12.25,-22.00 \ -8.25,-16.25 \ -7.75,-14.75 \ -7.50,-14.25 \ -7.25,-14.00)
    return(cbars[k+1, model])
}

real matrix _fgls_getCrit(real scalar T, real scalar model)
{
    real matrix crit

    if (model == 1) {
        if (T <= 150) {
            crit = (-3.911,-3.294,-2.328 \ -3.298,-2.601,-2.187 \ -3.131,-2.359,-2.005 \ -2.934,-2.256,-1.918 \ -2.888,-2.200,-1.880)
        }
        else if (T <= 350) {
            crit = (-3.780,-3.176,-2.828 \ -3.278,-2.473,-2.099 \ -2.989,-2.226,-1.896 \ -2.884,-2.179,-1.830 \ -2.840,-2.120,-1.787)
        }
        else {
            crit = (-3.637,-3.017,-2.661 \ -3.074,-2.377,-1.990 \ -2.916,-2.175,-1.808 \ -2.773,-2.079,-1.732 \ -2.745,-2.022,-1.695)
        }
    }
    else {
        if (T <= 150) {
            crit = (-4.771,-4.175,-3.879 \ -4.278,-3.647,-3.316 \ -4.044,-3.367,-3.037 \ -3.920,-3.232,-2.902 \ -3.797,-3.149,-2.831)
        }
        else if (T <= 350) {
            crit = (-4.593,-4.041,-3.749 \ -4.191,-3.569,-3.228 \ -3.993,-3.300,-2.950 \ -3.852,-3.174,-2.852 \ -3.749,-3.075,-2.761)
        }
        else {
            crit = (-4.462,-3.917,-3.651 \ -4.073,-3.438,-3.108 \ -3.822,-3.220,-2.868 \ -3.701,-3.092,-2.758 \ -3.603,-3.012,-2.690)
        }
    }
    return(crit)
}

void _fgls_Ftest(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar k, real scalar p, real scalar model)
{
    real colvector y, t_vec, dy, ly, ygls1, ygls2, sink, cosk, dy2, ly2
    real colvector dep1, dep2, y1, y2, b1, e1, b2, e2
    real matrix z1, z2, z_r, z_u, lmat, ldy1, ldy2v
    real scalar cbar, ssr1, ssr2, k1, k2, F_stat, Fcv1, Fcv5, Fcv10

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    cbar  = _fgls_getCbar(model, k)
    sink  = sin(2*pi()*k*t_vec/T)
    cosk  = cos(2*pi()*k*t_vec/T)
    if (model == 1) {
        z_r = J(T,1,1)
    }
    else {
        z_r = J(T,1,1), t_vec
    }
    z_u = z_r, sink, cosk
    ygls1 = _fgls_glsDetrend(y, z_r, cbar, T)
    ygls2 = _fgls_glsDetrend(y, z_u, cbar, T)
    dy  = ygls1[2..T,.] - ygls1[1..T-1,.]
    ly  = ygls1[1..T-1,.]
    lmat = _fgls_lagmatrix(dy, p)
    dy2 = ygls2[2..T,.] - ygls2[1..T-1,.]
    ly2 = ygls2[1..T-1,.]
    dep1 = dy[p+2..T-1,.]
    dep2 = dy2[p+2..T-1,.]
    y1   = ly[p+2..T-1,.]
    y2   = ly2[p+2..T-1,.]
    if (p == 0) {
        z1 = y1
        z2 = y2
    }
    else {
        ldy1  = lmat[p+2..T-1, 1..p]
        lmat  = _fgls_lagmatrix(dy2, p)
        ldy2v = lmat[p+2..T-1, 1..p]
        z1 = y1, ldy1
        z2 = y2, ldy2v
    }
    b1 = invsym(cross(z1,z1)) * cross(z1, dep1)
    e1 = dep1 - z1 * b1
    ssr1 = quadcross(e1, e1)
    b2 = invsym(cross(z2,z2)) * cross(z2, dep2)
    e2 = dep2 - z2 * b2
    ssr2 = quadcross(e2, e2)
    k1 = cols(z1)
    k2 = cols(z2)
    F_stat = ((ssr1 - ssr2) / (k2 - k1)) / (ssr2 / (rows(dep1) - k2))
    Fcv1  = invFtail(2, rows(dep1)-k2, 0.01)
    Fcv5  = invFtail(2, rows(dep1)-k2, 0.05)
    Fcv10 = invFtail(2, rows(dep1)-k2, 0.10)
    st_numscalar("r(Fstat)", F_stat)
    st_numscalar("r(Fcv1)",  Fcv1)
    st_numscalar("r(Fcv5)",  Fcv5)
    st_numscalar("r(Fcv10)", Fcv10)
}

real matrix _fgls_lagmatrix(real colvector x, real scalar maxlag)
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

real scalar _fgls_get_lag(real scalar ic, real scalar pmax, real colvector aicp, real colvector sicp, real colvector tstatp)
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
