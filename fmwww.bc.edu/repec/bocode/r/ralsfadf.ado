*! ralsfadf 1.0.1  16may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS-Fourier ADF unit-root test (Yilanci, Aydin & Aydin 2019)
*  MPRA Paper No. 96797.  Critical values from Tables 1a / 1b of the paper,
*  Hansen (1995) interpolation across rho^2 and bilinear in T.
*------------------------------------------------------------------------------

program define ralsfadf, rclass
    version 14.0
    capture mata: __rals_loaded()
    if _rc qui _rals_mata
    syntax varname(ts) [if] [in], [                ///
            TREND                                  ///
            MAXLags(integer 8)                     ///
            IC(string)                             ///
            FMAX(integer 5)                        ///
            FREQuency(real -1)                     ///
            Graph                                  ///
            noHEADer                               ]

    if `fmax' < 1 | `fmax' > 5 {
        di as error "fmax() must be between 1 and 5"
        exit 198
    }
    if `frequency' != -1 & (`frequency'<1 | `frequency'>5) {
        di as error "frequency() must be between 1 and 5"
        exit 198
    }
    marksample touse
    qui count if `touse'
    if r(N) < 25 {
        di as error "sample too small for RALS-FADF (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be {bf:tsset} before running ralsfadf"
        exit 459
    }
    local timevar `r(timevar)'

    if "`ic'"=="" local ic "tstat"
    local ic = lower("`ic'")
    if !inlist("`ic'","aic","bic","tstat") {
        di as error "ic() must be aic, bic, or tstat"
        exit 198
    }
    local model = cond("`trend'"!="", 2, 1)

    tempname res cv
    mata: _rals_fadf_engine("`varlist'", "`touse'", `model', `maxlags', "`ic'", `fmax', `frequency', "`res'", "`cv'")

    local tauFADF  = `res'[1,1]
    local tauRALS  = `res'[1,2]
    local rho2     = `res'[1,3]
    local T        = `res'[1,4]
    local lag      = `res'[1,5]
    local kfreq    = `res'[1,6]
    local ssr      = `res'[1,7]

    if "`header'"=="" {
        _rals_print_header "RALS-FADF" "Yilanci, Aydin & Aydin (2019, MPRA 96797)" "`varlist'" `T' `lag' "`ic'" `model'
    }
    _rals_print_fadf_table `tauFADF' `tauRALS' `rho2' `cv' `kfreq' `ssr'

    return scalar tauFADF = `tauFADF'
    return scalar tauRALS = `tauRALS'
    return scalar rho2    = `rho2'
    return scalar T       = `T'
    return scalar lag     = `lag'
    return scalar kfreq   = `kfreq'
    return scalar ssr     = `ssr'
    return scalar cv01_FADF = `cv'[1,1]
    return scalar cv05_FADF = `cv'[1,2]
    return scalar cv10_FADF = `cv'[1,3]
    return scalar cv01      = `cv'[2,1]
    return scalar cv05      = `cv'[2,2]
    return scalar cv10      = `cv'[2,3]
    return local  test      = "RALS-FADF"
    return local  cmdline   = "ralsfadf `varlist', `trend' maxlags(`maxlags') ic(`ic') fmax(`fmax')"

    if "`graph'" != "" {
        _rals_graph_fadf "`varlist'" "`timevar'" "`touse'" `tauRALS' `cv'[2,2] `kfreq' `T'
    }
end

program define _rals_print_fadf_table
    args tauFADF tauRALS rho2 cv kfreq ssr
    _rals_print_two_row "Fourier ADF (stage 1)" "RALS-FADF (stage 2)"        ///
        `tauFADF' `tauRALS' `rho2'                                           ///
        `cv'[1,1] `cv'[1,2] `cv'[1,3] `cv'[2,1] `cv'[2,2] `cv'[2,3]
    di as text "  Optimal Fourier frequency k = " as result `kfreq'           ///
       as text "    SSR minimum = " as result %10.4f `ssr'
    local concl_f = cond(`tauFADF' < `cv'[1,2], "{bf:reject} H0 (FADF, 5%)",            ///
                                                 "fail to reject H0 (FADF, 5%)")
    local concl_r = cond(`tauRALS' < `cv'[2,2], "{bf:reject} H0 (RALS-FADF, 5%)",       ///
                                                 "fail to reject H0 (RALS-FADF, 5%)")
    di as text "  Decision (5%)"
    di as text "    {c -}{c -} FADF      : " as result "`concl_f'"
    di as text "    {c -}{c -} RALS-FADF : " as result "`concl_r'"
    di as text "{hline 80}"
    di as text "  Stage-1 CVs : Enders & Lee (2012) Fourier-ADF table."
    di as text "  Stage-2 CVs : Yilanci, Aydin & Aydin (2019) RALS-FADF table."
    di as text ""
end

* _rals_graph_fadf is defined in its own .ado (shared with ralsfkss).

version 14.0
mata:
mata set matastrict off

void _rals_fadf_engine(string scalar yname, string scalar touse,
                       real scalar model, real scalar pmax, string scalar icmode,
                       real scalar fmax, real scalar fix_k,
                       string scalar rname, string scalar cvname)
{
    real colvector y, dy, ly, t, s, c
    real scalar T, p, sig2, sig2A, tauFADF, tauRALS, m2, m3, rho2
    real scalar kbest, ssrmin, popt, bestic, j, k
    real matrix lmat
    st_view(y, ., yname, touse)
    T  = rows(y)
    dy = y[2::T] - y[1::T-1]
    ly = y[1::T-1]
    t  = (2::T)
    real scalar Tobs
    Tobs = T

    // pre-build lag matrix of dy
    lmat = J(rows(dy), pmax, 0)
    for (j=1; j<=pmax; j++) lmat[j+1::rows(dy), j] = dy[1::rows(dy)-j]

    // Step A: grid search for optimal Fourier frequency using OLS SSR --------
    ssrmin = 1e+20; kbest = 1
    real scalar kfrom, kto
    if (fix_k>0) {
        kfrom = fix_k
        kto   = fix_k
    }
    else {
        kfrom = 1
        kto   = fmax
    }

    real colvector pi_
    pi_ = J(1,1,pi())                       // unused; kept for parity
    real scalar p_force
    p_force = pmax

    for (k=kfrom; k<=kto; k++) {
        s = sin(2*pi()*(2::T)*k/Tobs)
        c = cos(2*pi()*(2::T)*k/Tobs)
        real matrix Xfull
        if (model==1) Xfull = ly, J(rows(ly),1,1), s, c, lmat
        else          Xfull = ly, J(rows(ly),1,1), (2::T), s, c, lmat
        real scalar ndet
        ndet = (model==1 ? 4 : 5)            // y(-1) + const + s + c [+ trend]
        real colvector depf
        depf = dy
        real matrix Xf
        Xf = Xfull
        if (pmax>0) {
            depf = depf[pmax+1::rows(dy)]
            Xf   = Xf[pmax+1::rows(dy), .]
        }
        // pick lag via icmode  ----------------------------------------------
        real scalar popt_k
        real colvector icvec, tvec
        icvec = J(pmax+1,1,.); tvec = J(pmax+1,1,.)
        for (p=0; p<=pmax; p++) {
            real matrix Xp,XXi
            real colvector bp,ep,sep
            Xp  = Xf[., 1::(ndet+p)]
            XXi = invsym(quadcross(Xp,Xp))
            bp  = XXi*quadcross(Xp,depf)
            ep  = depf - Xp*bp
            if (icmode=="bic") {
                icvec[p+1] = ln(ep'ep/rows(Xp)) + cols(Xp)*ln(rows(Xp))/rows(Xp)
            }
            else {
                icvec[p+1] = ln(ep'ep/rows(Xp)) + 2*cols(Xp)/rows(Xp)
            }
            if (p>0) {
                sep = sqrt(diagonal((ep'ep/(rows(Xp)-cols(Xp)))*XXi))
                tvec[p+1] = abs(bp[cols(Xp),1]/sep[cols(Xp),1])
            }
        }
        if (icmode=="tstat") {
            popt_k = 0
            for (p=pmax; p>=1; p--) {
                if (tvec[p+1] >= 1.645) {
                    popt_k = p
                    break
                }
            }
        }
        else {
            popt_k = 0
            bestic = icvec[1]
            for (p=1; p<=pmax; p++) {
                if (icvec[p+1] < bestic) {
                    bestic = icvec[p+1]
                    popt_k = p
                }
            }
        }
        real matrix Xs
        Xs = Xf[., 1::(ndet+popt_k)]
        real matrix XXi_s
        real colvector bs_, es_
        XXi_s = invsym(quadcross(Xs,Xs))
        bs_   = XXi_s*quadcross(Xs,depf)
        es_   = depf - Xs*bs_
        real scalar ssrv
        ssrv = es_'es_
        if (ssrv < ssrmin) {
            ssrmin = ssrv
            kbest  = k
            popt   = popt_k
        }
    }

    // Step B: at kbest fit the final FADF and RALS extension ------------------
    s = sin(2*pi()*(2::T)*kbest/Tobs)
    c = cos(2*pi()*(2::T)*kbest/Tobs)
    real matrix Xfull2, Xf2
    if (model==1) Xfull2 = ly, J(rows(ly),1,1), s, c, lmat
    else          Xfull2 = ly, J(rows(ly),1,1), (2::T), s, c, lmat
    real scalar ndet2
    ndet2 = (model==1 ? 4 : 5)
    real colvector depf2
    depf2 = dy; Xf2 = Xfull2
    if (pmax>0) {
        depf2 = depf2[pmax+1::rows(dy)]
        Xf2   = Xf2[pmax+1::rows(dy), .]
    }
    real matrix Xs2, XXi2
    real colvector bs2, es2, sebs2
    Xs2 = Xf2[., 1::(ndet2+popt)]
    XXi2 = invsym(quadcross(Xs2,Xs2))
    bs2  = XXi2*quadcross(Xs2,depf2)
    es2  = depf2 - Xs2*bs2
    sig2 = (es2'es2)/(rows(Xs2)-cols(Xs2))
    sebs2 = sqrt(diagonal(sig2*XXi2))
    tauFADF = bs2[1,1]/sebs2[1,1]

    // RALS augmentation
    m2 = sum(es2:^2)/rows(es2)
    m3 = sum(es2:^3)/rows(es2)
    real matrix W, Xa, XaI
    real colvector ba, ea, sea
    W   = (es2:^2 :- m2), (es2:^3 :- m3 :- 3*m2*es2)
    Xa  = Xs2, W
    XaI = invsym(quadcross(Xa,Xa))
    ba  = XaI*quadcross(Xa,depf2)
    ea  = depf2 - Xa*ba
    sig2A = (ea'ea)/(rows(Xa)-cols(Xa))
    sea = sqrt(diagonal(sig2A*XaI))
    tauRALS = ba[1,1]/sea[1,1]
    rho2 = sig2A/sig2
    if (rho2<0) rho2=0
    if (rho2>1) rho2=1

    // CV lookup (n approx = T-popt, k=1, since 1 regressor i.e. y itself) ----
    real rowvector cvr, cvFADF
    cvr    = __rals_fadf_cv(T-popt, 1, model, rho2)
    cvFADF = __rals_cv_fadf(T-popt, kbest, model)

    real matrix CV2
    CV2 = cvFADF \ cvr
    st_matrix(rname, (tauFADF, tauRALS, rho2, T, popt, kbest, ssrmin))
    st_matrix(cvname, CV2)
}
end
