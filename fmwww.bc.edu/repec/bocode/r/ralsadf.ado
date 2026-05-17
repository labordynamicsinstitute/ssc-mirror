*! ralsadf 1.0.1  16may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS-ADF unit-root test of Im, Lee & Tieslau (2014)
*  Festschrift in Honor of Peter Schmidt (pp. 315-342), Springer.
*  Mirrors the GAUSS code rals_adf.src by Saban Nazlioglu.
*------------------------------------------------------------------------------

program define ralsadf, rclass
    version 14.0
    capture mata: __rals_loaded()
    if _rc qui _rals_mata
    syntax varname(ts) [if] [in], [                ///
            TREND                                  ///
            MAXLags(integer 8)                     ///
            IC(string)                             ///
            Level(real 95)                         ///
            Graph                                  ///
            noHEADer                               ]

    marksample touse
    qui count if `touse'
    if r(N) < 20 {
        di as error "sample too small to compute RALS-ADF (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be {bf:tsset} before running ralsadf"
        exit 459
    }
    local timevar `r(timevar)'

    if "`ic'"=="" local ic "tstat"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "tstat") {
        di as error "ic() must be aic, bic, or tstat"
        exit 198
    }
    local model = cond("`trend'" != "", 2, 1)

    tempname results cv
    mata: _rals_adf_engine("`varlist'", "`touse'", `model', `maxlags', "`ic'", "`results'", "`cv'")
    matrix colnames `results' = tau_ADF tau_RALS rho2 p T lag_used
    matrix colnames `cv'      = cv01 cv05 cv10

    local tauADF  = `results'[1,1]
    local tauRALS = `results'[1,2]
    local rho2    = `results'[1,3]
    local lag     = `results'[1,5]
    local T       = `results'[1,4]

    if "`header'"=="" {
        _rals_print_header "RALS-ADF" "Im, Lee & Tieslau (2014)" "`varlist'" `T' `lag' "`ic'" `model'
    }

    _rals_print_stat_table `tauADF' `tauRALS' `rho2' `cv'

    return scalar tauADF  = `tauADF'
    return scalar tauRALS = `tauRALS'
    return scalar rho2    = `rho2'
    return scalar T       = `T'
    return scalar lag     = `lag'
    return scalar cv01_DF   = `cv'[1,1]
    return scalar cv05_DF   = `cv'[1,2]
    return scalar cv10_DF   = `cv'[1,3]
    return scalar cv01      = `cv'[2,1]
    return scalar cv05      = `cv'[2,2]
    return scalar cv10      = `cv'[2,3]
    return local  ic        = "`ic'"
    return local  model     = cond(`model'==1, "constant", "constant+trend")
    return local  test      = "RALS-ADF"
    return local  cmdline   = "ralsadf `varlist', `trend' maxlags(`maxlags') ic(`ic')"

    if "`graph'" != "" {
        _rals_graph_ur "`varlist'" "`timevar'" "`touse'" "RALS-ADF" `tauRALS' `cv'[2,2]
    }
end

*------------------------------------------------------------------------------
* Mata engine.  Mirrors rals_adf.src step by step.
*------------------------------------------------------------------------------
version 14.0
mata:
mata set matastrict off

void _rals_adf_engine(string scalar yname, string scalar touse,
                      real scalar model, real scalar pmax, string scalar icmode,
                      string scalar rname, string scalar cvname)
{
    real colvector y, dy, ly, dep, y1, e, e_first, b
    real matrix X, w, Xa, lmat, dc, dt, crt, cvr
    real scalar T, p, sig2, sig2A, tauADF, tauRALS, m2, m3, rho2, n0
    real scalar j

    st_view(y, ., yname, touse)
    T = rows(y)

    dy = y[2::T] - y[1::T-1]
    ly = y[1::T-1]
    dc = J(T-1, 1, 1)
    dt = (2::T)

    // lag matrix of dy used for selection
    lmat = J(rows(dy), pmax, 0)
    for (j=1; j<=pmax; j++) lmat[j+1::rows(dy), j] = dy[1::rows(dy)-j]

    // build full design at pmax
    real matrix Xfull
    if (model==1) Xfull = ly, dc, lmat
    else          Xfull = ly, dc, dt, lmat
    real colvector depf
    depf = dy
    if (pmax>0) {
        depf  = depf[pmax+1::rows(dy)]
        Xfull = Xfull[pmax+1::rows(dy), .]
    }
    n0 = cols(Xfull) - pmax  // # deterministic + y(-1)

    // lag selection ------------------------------------------------------------
    real scalar popt, bestic, valic
    real colvector icvec, tvec
    icvec = J(pmax+1,1,.); tvec = J(pmax+1,1,.)
    for (p=0; p<=pmax; p++) {
        real matrix Xp
        Xp = Xfull[., 1::(n0+p)]
        real matrix XX, XXi
        real colvector bp, ep
        XX  = quadcross(Xp,Xp); XXi = invsym(XX)
        bp  = XXi*quadcross(Xp,depf)
        ep  = depf - Xp*bp
        real scalar np
        np = rows(Xp)
        if (icmode=="bic") {
            icvec[p+1] = ln(ep'ep/np) + cols(Xp)*ln(np)/np
        }
        else {
            icvec[p+1] = ln(ep'ep/np) + 2*cols(Xp)/np
        }
        if (p>0) {
            real colvector se
            se = sqrt(diagonal((ep'ep/(np-cols(Xp)))*XXi))
            tvec[p+1] = abs(bp[cols(Xp),1]/se[cols(Xp),1])
        }
    }
    if (icmode=="tstat") {
        popt = 0
        for (p=pmax; p>=1; p--) {
            if (tvec[p+1]>=1.645) {
                popt = p
                break
            }
        }
    }
    else {
        popt = 0
        bestic = icvec[1]
        for (p=1; p<=pmax; p++) {
            if (icvec[p+1] < bestic) {
                bestic = icvec[p+1]
                popt = p
            }
        }
    }

    // Stage 1 (ADF at chosen lag) ---------------------------------------------
    real matrix Xs
    Xs = Xfull[., 1::(n0+popt)]
    real colvector bs, es
    XXi = invsym(quadcross(Xs,Xs))
    bs  = XXi * quadcross(Xs, depf)
    es  = depf - Xs*bs
    sig2 = (es'es)/(rows(Xs)-cols(Xs))
    real colvector ses
    ses = sqrt(diagonal(sig2*XXi))
    tauADF = bs[1]/ses[1]

    // RALS augmentation -------------------------------------------------------
    m2 = sum(es:^2)/rows(es)
    m3 = sum(es:^3)/rows(es)
    w  = (es:^2 :- m2), (es:^3 :- m3 :- 3*m2*es)
    real matrix Xa2
    Xa2 = Xs, w
    real matrix XXi2
    real colvector ba, ea, sea
    XXi2 = invsym(quadcross(Xa2,Xa2))
    ba   = XXi2 * quadcross(Xa2, depf)
    ea   = depf - Xa2*ba
    sig2A = (ea'ea)/(rows(Xa2)-cols(Xa2))
    sea   = sqrt(diagonal(sig2A*XXi2))
    tauRALS = ba[1]/sea[1]
    rho2 = sig2A/sig2
    if (rho2<0) rho2 = 0
    if (rho2>1) rho2 = 1

    // CV interpolation --------------------------------------------------------
    crt = __rals_cv_adf(model)
    cvr = __rals_interp(crt, rho2)
    real rowvector cvDF
    cvDF = __rals_cv_df(T-popt, model)

    real matrix R, CV2
    R   = (tauADF, tauRALS, rho2, T, popt, popt)
    CV2 = cvDF \ cvr     // 2x3: row 1 = DF CVs, row 2 = RALS CVs
    st_matrix(rname, R)
    st_matrix(cvname, CV2)
}
end

*------------------------------------------------------------------------------
* ralsadf-specific result printer
*------------------------------------------------------------------------------
program define _rals_print_stat_table
    args tauADF tauRALS rho2 cv
    _rals_print_two_row "ADF (stage 1)" "RALS-ADF (stage 2)"                 ///
        `tauADF' `tauRALS' `rho2'                                            ///
        `cv'[1,1] `cv'[1,2] `cv'[1,3] `cv'[2,1] `cv'[2,2] `cv'[2,3]
    local concl_df   = cond(`tauADF'  < `cv'[1,2], "{bf:reject} H0 (ADF, 5%)",          ///
                                                    "fail to reject H0 (ADF, 5%)")
    local concl_rals = cond(`tauRALS' < `cv'[2,2], "{bf:reject} H0 (RALS-ADF, 5%)",     ///
                                                    "fail to reject H0 (RALS-ADF, 5%)")
    di as text "  Decision (5%)"
    di as text "    {c -}{c -} ADF      : " as result "`concl_df'"
    di as text "    {c -}{c -} RALS-ADF : " as result "`concl_rals'"
    di as text "{hline 80}"
    di as text "  Stage-1 CVs : MacKinnon (1996) response surfaces."
    di as text "  Stage-2 CVs : Hansen (1995) rho^2 interpolation (Im, Lee & Tieslau 2014)."
    di as text "  Decision rule: reject H0 (unit root) when statistic < CV(5%)."
    di as text ""
end

