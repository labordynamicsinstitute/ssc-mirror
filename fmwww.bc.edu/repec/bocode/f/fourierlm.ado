*! fourierlm v2.0 - Enders & Lee (2012a) Fourier LM Unit Root Test
*! Oxford Bulletin of Economics and Statistics, 74(4), 574-599
*! Ported from GAUSS code by Saban Nazlioglu
*! Compatible with Stata 14+
*! Package: ffrroot v1.0
*! Author: Dr. Merwan Roudane (merwanroudane920@gmail.com)
*! Date: 11 March 2026

program define fourierlm, rclass
    version 14
    syntax varname(ts) [if] [in] [, Kmax(integer 5) K(integer 0) Pmax(integer 8) IC(integer 3) GRAPH]

    marksample touse
    tsset
    local tvar `r(timevar)'

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

    di ""
    di as text "{hline 70}"
    di as text "  Fourier LM Unit Root Test"
    di as text "  Enders & Lee (2012a), Oxford Bull. Econ. Stat. 74(4):574-599"
    di as text "{hline 70}"
    di as text "  Variable: " as result "`varlist'" as text "   T=" as result `T' as text "   Pmax=" as result `pmax' as text "   Kmax=" as result `kmax' as text "   IC=" as result `ic'
    di as text "{hline 70}"

    mata: _flm_main("`y'", "`tvar'", "`touse'", `T', `pmax', `kmax', `ic', `k')

    local LM_stat  = r(LMk)
    local f        = r(k)
    local opt_lag  = r(p)
    local cv1      = r(cv1)
    local cv5      = r(cv5)
    local cv10     = r(cv10)

    if `LM_stat' <= `cv1' {
        local sig "*** (1%)"
    }
    else if `LM_stat' <= `cv5' {
        local sig "** (5%)"
    }
    else if `LM_stat' <= `cv10' {
        local sig "* (10%)"
    }
    else {
        local sig "not significant"
    }

    di as text "  LM test (Enders & Lee, 2012)"
    di as text "  {hline 50}"
    di as text "  Optimal frequency k    = " as result `f'
    di as text "  Optimal lag p          = " as result `opt_lag'
    di as text "  LM statistic           = " as result %9.3f `LM_stat'
    di as text ""
    di as text "  Critical Values (T=`T', k=`f'):"
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
            reg `varlist' `tvar' `sink_g' `cosk_g' if `touse'
            predict double `fitted_g' if `touse', xb
        }
        twoway (line `varlist' `tvar' if `touse', lcolor(blue) lwidth(thin)) ///
               (line `fitted_g' `tvar' if `touse', lcolor(red) lwidth(thick)), ///
               title("Fourier LM: `varlist' (k=`f')") ///
               legend(order(1 "`varlist'" 2 "Fourier expansion series")) ///
               graphregion(color(white)) bgcolor(white) ///
               name(fourierlm_graph, replace)
    }

    return scalar LMk          = `LM_stat'
    return scalar k            = `f'
    return scalar p            = `opt_lag'
    return scalar cv1          = `cv1'
    return scalar cv5          = `cv5'
    return scalar cv10         = `cv10'
    return scalar lm_stat      = `LM_stat'
    return scalar k_selected   = `f'
    return scalar lags_selected= `opt_lag'
end


mata:

void _flm_main(string scalar yvar, string scalar tvar, string scalar touse, real scalar T, real scalar pmax, real scalar kmax, real scalar ic, real scalar kfix)
{
    real colvector y, t_vec, dy0, sink, cosk, dsink, dcosk, ylm
    real colvector dy_ylm, ly_ylm, dc_ylm, dt_ylm
    real colvector ssrk, tauk, keep_p
    real colvector taup_v, aicp_v, sicp_v, tstatp_v, ssrp_v
    real colvector dep, y1, sbt, trnd, sinp, cosp, b, e, se_b
    real matrix z_det, lmat, z_reg, ldy, XtX_inv, crit
    real scalar k, f, LM_stat, opt_lag, min_s, kk
    real scalar p, p_opt, nobs, ncols, ssr, tau_p, aic_p, sic_p, tst_p, LL

    y     = st_data(., yvar, touse)
    t_vec = st_data(., tvar, touse)
    dy0   = y[2..T,.] - y[1..T-1,.]

    ssrk   = J(kmax, 1, .)
    tauk   = J(kmax, 1, .)
    keep_p = J(kmax, 1, .)

    for (k=1; k<=kmax; k++) {
        if (kfix > 0 & k != kfix) continue

        sink  = sin(2*pi()*k*t_vec/T)
        cosk  = cos(2*pi()*k*t_vec/T)
        dsink = sink[2..T,.] - sink[1..T-1,.]
        dcosk = cosk[2..T,.] - cosk[1..T-1,.]

        z_det = t_vec, sink, cosk
        ylm   = _flm_detrendData(y, z_det, dy0, dsink, dcosk)

        dy_ylm = ylm[2..T,.] - ylm[1..T-1,.]
        ly_ylm = ylm[1..T-1,.]
        dc_ylm = J(T-1, 1, 1)
        dt_ylm = t_vec[2..T,.]

        lmat = _flm_lagmatrix(dy_ylm, pmax)

        taup_v   = J(pmax+1, 1, .)
        aicp_v   = J(pmax+1, 1, .)
        sicp_v   = J(pmax+1, 1, .)
        tstatp_v = J(pmax+1, 1, .)
        ssrp_v   = J(pmax+1, 1, .)

        for (p=0; p<=pmax; p++) {
            dep  = dy_ylm[p+2..T-1,.]
            y1   = ly_ylm[p+2..T-1,.]
            sbt  = dc_ylm[p+2..T-1,.]
            trnd = dt_ylm[p+2..T-1,.]
            sinp = dsink[p+2..T-1,.]
            cosp = dcosk[p+2..T-1,.]

            if (p == 0) {
                z_reg = y1, sbt, sinp, cosp
            }
            else {
                ldy   = lmat[p+2..T-1, 1..p]
                z_reg = y1, sbt, sinp, cosp, ldy
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

            LL    = -nobs/2 * (1 + log(2*pi()) + log(ssr/nobs))
            aic_p = (2*ncols - 2*LL) / nobs
            sic_p = (ncols*log(nobs) - 2*LL) / nobs
            tst_p = b[ncols] / se_b[ncols]

            taup_v[p+1]   = tau_p
            aicp_v[p+1]   = aic_p
            sicp_v[p+1]   = sic_p
            tstatp_v[p+1] = tst_p
            ssrp_v[p+1]   = ssr
        }

        p_opt = _flm_get_lag(ic, pmax, aicp_v, sicp_v, tstatp_v)

        ssrk[k]   = ssrp_v[p_opt+1]
        tauk[k]   = taup_v[p_opt+1]
        keep_p[k] = p_opt
    }

    if (kfix > 0) {
        f = kfix
    }
    else {
        f = 1
        min_s = ssrk[1]
        for (kk=2; kk<=kmax; kk++) {
            if (ssrk[kk] < min_s) {
                min_s = ssrk[kk]
                f = kk
            }
        }
    }

    LM_stat = tauk[f]
    opt_lag = keep_p[f]
    crit    = _flm_getCrit(T)

    st_numscalar("r(LMk)", LM_stat)
    st_numscalar("r(k)",   f)
    st_numscalar("r(p)",   opt_lag)
    st_numscalar("r(cv1)", crit[f,1])
    st_numscalar("r(cv5)", crit[f,2])
    st_numscalar("r(cv10)",crit[f,3])
}

real colvector _flm_detrendData(real colvector y, real matrix z, real colvector dy, real colvector dsink, real colvector dcosk)
{
    real matrix dz
    real colvector b0
    real scalar psi_

    dz   = J(rows(dy),1,1), dsink, dcosk
    b0   = invsym(cross(dz,dz)) * cross(dz,dy)
    psi_ = y[1] - (dz[1,.] * b0)[1,1]
    return(y :- psi_ :- z * b0)
}

real matrix _flm_lagmatrix(real colvector x, real scalar maxlag)
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

real scalar _flm_get_lag(real scalar ic, real scalar pmax, real colvector aicp, real colvector sicp, real colvector tstatp)
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

real matrix _flm_getCrit(real scalar T)
{
    real matrix crit

    if (T <= 150) {
        crit = (-4.69,-4.10,-3.82 \ -4.25,-3.57,-3.23 \ -3.98,-3.31,-2.96 \ -3.85,-3.18,-2.86 \ -3.75,-3.11,-2.81)
    }
    else if (T <= 349) {
        crit = (-4.61,-4.07,-3.79 \ -4.18,-3.55,-3.23 \ -3.94,-3.30,-2.98 \ -3.80,-3.18,-2.88 \ -3.73,-3.12,-2.83)
    }
    else if (T <= 500) {
        crit = (-4.57,-4.05,-3.78 \ -4.13,-3.54,-3.22 \ -3.94,-3.31,-2.98 \ -3.81,-3.19,-2.88 \ -3.75,-3.14,-2.83)
    }
    else {
        crit = (-4.56,-4.03,-3.77 \ -4.15,-3.54,-3.22 \ -3.94,-3.30,-2.98 \ -3.80,-3.19,-2.88 \ -3.74,-3.13,-2.83)
    }
    return(crit)
}

end
