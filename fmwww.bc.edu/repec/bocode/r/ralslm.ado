*! ralslm 1.0.0  12may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS-LM unit-root test of Meng, Im, Lee & Tieslau (2014)
*  Festschrift in Honor of Peter Schmidt (pp. 343-357), Springer.
*  Mirrors the GAUSS code rals_lm.src by Saban Nazlioglu.
*------------------------------------------------------------------------------

program define ralslm, rclass
    version 14.0
    qui _rals_mata
    syntax varname(ts) [if] [in], [                ///
            MAXLags(integer 8)                     ///
            IC(string)                             ///
            Graph                                  ///
            noHEADer                               ]

    marksample touse
    qui count if `touse'
    if r(N) < 25 {
        di as error "sample too small to compute RALS-LM (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be {bf:tsset} before running ralslm"
        exit 459
    }
    local timevar `r(timevar)'

    if "`ic'"=="" local ic "tstat"
    local ic = lower("`ic'")
    if !inlist("`ic'", "aic", "bic", "tstat") {
        di as error "ic() must be aic, bic, or tstat"
        exit 198
    }

    tempname results cv
    mata: _rals_lm_engine("`varlist'", "`touse'", `maxlags', "`ic'", "`results'", "`cv'")

    local tauLM   = `results'[1,1]
    local tauRALS = `results'[1,2]
    local rho2    = `results'[1,3]
    local T       = `results'[1,4]
    local lag     = `results'[1,5]

    if "`header'"=="" {
        _rals_print_header "RALS-LM" "Meng, Im, Lee & Tieslau (2014)" "`varlist'" `T' `lag' "`ic'" 2
    }
    _rals_print_lm_table `tauLM' `tauRALS' `rho2' `cv'

    return scalar tauLM   = `tauLM'
    return scalar tauRALS = `tauRALS'
    return scalar rho2    = `rho2'
    return scalar T       = `T'
    return scalar lag     = `lag'
    return scalar cv01_LM = `cv'[1,1]
    return scalar cv05_LM = `cv'[1,2]
    return scalar cv10_LM = `cv'[1,3]
    return scalar cv01    = `cv'[2,1]
    return scalar cv05    = `cv'[2,2]
    return scalar cv10    = `cv'[2,3]
    return local  ic      = "`ic'"
    return local  test    = "RALS-LM"
    return local  cmdline = "ralslm `varlist', maxlags(`maxlags') ic(`ic')"

    if "`graph'" != "" {
        _rals_graph_ur "`varlist'" "`timevar'" "`touse'" "RALS-LM" `tauRALS' `cv'[2,2]
    }
end

program define _rals_print_lm_table
    args tauLM tauRALS rho2 cv
    _rals_print_two_row "LM (stage 1)" "RALS-LM (stage 2)"                   ///
        `tauLM' `tauRALS' `rho2'                                             ///
        `cv'[1,1] `cv'[1,2] `cv'[1,3] `cv'[2,1] `cv'[2,2] `cv'[2,3]
    local concl_lm   = cond(`tauLM'   < `cv'[1,2], "{bf:reject} H0 (LM, 5%)",           ///
                                                    "fail to reject H0 (LM, 5%)")
    local concl_rals = cond(`tauRALS' < `cv'[2,2], "{bf:reject} H0 (RALS-LM, 5%)",      ///
                                                    "fail to reject H0 (RALS-LM, 5%)")
    di as text "  Decision (5%)"
    di as text "    {c -}{c -} LM      : " as result "`concl_lm'"
    di as text "    {c -}{c -} RALS-LM : " as result "`concl_rals'"
    di as text "{hline 80}"
    di as text "  Stage-1 CVs : Schmidt-Phillips (1992) trend-LM table."
    di as text "  Stage-2 CVs : Meng, Im, Lee & Tieslau (2014) rho^2 interpolation."
    di as text ""
end

version 14.0
mata:
mata set matastrict off

void _rals_lm_engine(string scalar yname, string scalar touse,
                     real scalar pmax, string scalar icmode,
                     string scalar rname, string scalar cvname)
{
    real colvector y, dy, dz, b0, ylm, ly, dep, ds, depf, es, ea
    real scalar T, p, psi, sig2, sig2A, tauLM, tauRALS, m2, m3, rho2
    real matrix lmat, Xs, Xa, XXi, XXi2, w, crt, cvr
    real colvector bs, ses, ba, sea
    real scalar popt, bestic, j

    st_view(y, ., yname, touse)
    T  = rows(y)
    dy = y[2::T] - y[1::T-1]
    // Schmidt-Phillips style detrending --------------------------------------
    // dy = b0 + e ; b0 is the OLS slope on a constant, i.e. the mean of dy.
    real scalar b0s
    b0s = sum(dy)/rows(dy)
    psi = y[1] - b0s
    // detrended series
    real colvector ylm0
    ylm0 = y :- psi :- (1::T)*b0s
    ylm  = ylm0[2::T]                     // drop first as in src
    real scalar Tlm
    Tlm = rows(ylm)
    ly  = ylm[1::Tlm-1]                   // y_{t-1}
    ds  = ylm[2::Tlm] - ylm[1::Tlm-1]     // Δ of detrended

    // dy needs same trimming
    real colvector dyt
    dyt = dy[2::rows(dy)]                 // align with ds

    // build lag matrix of ds
    lmat = J(rows(ds), pmax, 0)
    for (j=1; j<=pmax; j++) lmat[j+1::rows(ds), j] = ds[1::rows(ds)-j]

    // full design at pmax: [ly~const~ldy], match rals_lm.src
    real matrix Xfull
    Xfull = ly, J(rows(ly),1,1), lmat
    real colvector depfull
    depfull = dyt
    if (pmax>0) {
        depfull = depfull[pmax+1::rows(dyt)]
        Xfull   = Xfull[pmax+1::rows(dyt), .]
    }

    // lag selection ----------------------------------------------------------
    real colvector icvec, tvec
    icvec = J(pmax+1,1,.); tvec = J(pmax+1,1,.)
    for (p=0; p<=pmax; p++) {
        real matrix Xp; real matrix XXp; real colvector bpv,epv,sep
        Xp = Xfull[., 1::(2+p)]
        XXp = invsym(quadcross(Xp,Xp))
        bpv = XXp*quadcross(Xp,depfull)
        epv = depfull - Xp*bpv
        if (icmode=="bic") {
            icvec[p+1] = ln(epv'epv/rows(Xp))+cols(Xp)*ln(rows(Xp))/rows(Xp)
        }
        else {
            icvec[p+1] = ln(epv'epv/rows(Xp))+2*cols(Xp)/rows(Xp)
        }
        if (p>0) {
            sep = sqrt(diagonal((epv'epv/(rows(Xp)-cols(Xp)))*XXp))
            tvec[p+1] = abs(bpv[cols(Xp),1]/sep[cols(Xp),1])
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

    // stage 1: LM stat at chosen lag -----------------------------------------
    Xs  = Xfull[., 1::(2+popt)]
    XXi = invsym(quadcross(Xs,Xs))
    bs  = XXi*quadcross(Xs,depfull)
    es  = depfull - Xs*bs
    sig2 = (es'es)/(rows(Xs)-cols(Xs))
    ses = sqrt(diagonal(sig2*XXi))
    tauLM = bs[1]/ses[1]

    // RALS augmentation ------------------------------------------------------
    m2 = sum(es:^2)/rows(es)
    m3 = sum(es:^3)/rows(es)
    w  = (es:^2 :- m2), (es:^3 :- m3 :- 3*m2*es)
    Xa = Xs, w
    XXi2 = invsym(quadcross(Xa,Xa))
    ba   = XXi2*quadcross(Xa,depfull)
    ea   = depfull - Xa*ba
    sig2A = (ea'ea)/(rows(Xa)-cols(Xa))
    sea = sqrt(diagonal(sig2A*XXi2))
    tauRALS = ba[1]/sea[1]
    rho2 = sig2A/sig2
    if (rho2<0) rho2=0
    if (rho2>1) rho2=1

    crt = __rals_cv_lm()
    cvr = __rals_interp(crt, rho2)
    real rowvector cvLM
    cvLM = __rals_cv_lmstat(T-popt)

    real matrix CV2
    CV2 = cvLM \ cvr
    st_matrix(rname, (tauLM, tauRALS, rho2, T, popt))
    st_matrix(cvname, CV2)
}
end
