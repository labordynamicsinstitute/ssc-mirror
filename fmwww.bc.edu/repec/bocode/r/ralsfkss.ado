*! ralsfkss 1.0.0  12may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS-Fourier KSS unit-root test
*  Reference:  Yilanci & Ozgur (2025) Politicka Ekonomie 73(3): 528-565.
*  Step 1: Fourier de-trending (Christopoulos & Leon-Ledesma 2010).
*  Step 2: KSS-type regression on residuals:  Δu_t = φ u^3_{t-1} + Σ ζ_i Δu_{t-i} + e_t
*  Step 3: Add RALS w-augmentation built from the stage-2 residuals.
*------------------------------------------------------------------------------

program define ralsfkss, rclass
    version 14.0
    qui _rals_mata
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
    marksample touse
    qui count if `touse'
    if r(N) < 30 {
        di as error "sample too small for RALS-FKSS (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be tsset before running ralsfkss"
        exit 459
    }
    local timevar `r(timevar)'

    if "`ic'"=="" local ic "aic"
    local ic = lower("`ic'")
    if !inlist("`ic'","aic","bic","tstat") {
        di as error "ic() must be aic, bic, or tstat"
        exit 198
    }
    local model = cond("`trend'"!="", 2, 1)

    tempname res cv
    mata: _rals_fkss_engine("`varlist'", "`touse'", `model', `maxlags', "`ic'", `fmax', `frequency', "`res'", "`cv'")

    local tauKSS  = `res'[1,1]
    local tauRALS = `res'[1,2]
    local rho2    = `res'[1,3]
    local T       = `res'[1,4]
    local lag     = `res'[1,5]
    local kfreq   = `res'[1,6]

    if "`header'"=="" {
        _rals_print_header "RALS-FKSS" "Yilanci & Ozgur (2025)" "`varlist'" `T' `lag' "`ic'" `model'
    }
    _rals_print_two_row "Fourier KSS (stage 1)" "RALS-FKSS (stage 2)"        ///
        `tauKSS' `tauRALS' `rho2'                                            ///
        `cv'[1,1] `cv'[1,2] `cv'[1,3] `cv'[2,1] `cv'[2,2] `cv'[2,3]
    di as text "  Optimal Fourier frequency k = " as result `kfreq'
    local concl_f = cond(`tauKSS'  < `cv'[1,2], "{bf:reject} H0 (FKSS, 5%)",            ///
                                                 "fail to reject H0 (FKSS, 5%)")
    local concl_r = cond(`tauRALS' < `cv'[2,2], "{bf:reject} H0 (RALS-FKSS, 5%)",       ///
                                                 "fail to reject H0 (RALS-FKSS, 5%)")
    di as text "  Decision (5%)"
    di as text "    {c -}{c -} FKSS      : " as result "`concl_f'"
    di as text "    {c -}{c -} RALS-FKSS : " as result "`concl_r'"
    di as text "{hline 80}"
    di as text "  Stage-1 CVs : Christopoulos & Leon-Ledesma (2010) Fourier-KSS table."
    di as text "  Stage-2 CVs : Yilanci & Ozgur (2025)."
    di as text "{hline 80}"

    return scalar tauKSS  = `tauKSS'
    return scalar tauRALS = `tauRALS'
    return scalar rho2    = `rho2'
    return scalar T       = `T'
    return scalar lag     = `lag'
    return scalar kfreq   = `kfreq'
    return scalar cv01_FKSS = `cv'[1,1]
    return scalar cv05_FKSS = `cv'[1,2]
    return scalar cv10_FKSS = `cv'[1,3]
    return scalar cv01      = `cv'[2,1]
    return scalar cv05      = `cv'[2,2]
    return scalar cv10      = `cv'[2,3]
    return local  test      = "RALS-FKSS"

    if "`graph'" != "" {
        _rals_graph_fadf "`varlist'" "`timevar'" "`touse'" `tauRALS' `cv'[2,2] `kfreq' `T'
    }
end

version 14.0
mata:
mata set matastrict off

void _rals_fkss_engine(string scalar yname, string scalar touse,
                       real scalar model, real scalar pmax, string scalar icmode,
                       real scalar fmax, real scalar fix_k,
                       string scalar rname, string scalar cvname)
{
    real colvector y, u, du, ulag, dep, s, c, t_, j
    real scalar T, k, kbest, ssrmin, popt, p, j_
    st_view(y, ., yname, touse)
    T = rows(y)
    real scalar kfrom, kto
    if (fix_k>0) {
        kfrom = fix_k
        kto   = fix_k
    }
    else {
        kfrom = 1
        kto   = fmax
    }

    // Stage 1: Fourier de-trending  (Christopoulos & Leon-Ledesma 2010)
    ssrmin = 1e+20; kbest = 1
    real colvector ubest
    ubest = J(T,1,.)
    for (k=kfrom; k<=kto; k++) {
        s = sin(2*pi()*(1::T)*k/T)
        c = cos(2*pi()*(1::T)*k/T)
        real matrix Z
        if (model==1) Z = J(T,1,1), s, c
        else          Z = J(T,1,1), (1::T), s, c
        real colvector bv, uv
        bv = invsym(quadcross(Z,Z))*quadcross(Z,y)
        uv = y - Z*bv
        real scalar ssrv
        ssrv = uv'uv
        if (ssrv < ssrmin) {
            ssrmin = ssrv
            kbest  = k
            ubest  = uv
        }
    }
    u = ubest

    // Stage 2: KSS regression  Δu_t = φ u^3_{t-1} + Σ ζ_i Δu_{t-i} + e_t
    du   = u[2::T] - u[1::T-1]
    ulag = u[1::T-1]
    real colvector u3
    u3 = ulag:^3
    // lag matrix of du
    real matrix lmat
    lmat = J(rows(du), pmax, 0)
    for (j_=1; j_<=pmax; j_++) lmat[j_+1::rows(du), j_] = du[1::rows(du)-j_]

    real matrix Xfull
    Xfull = u3, lmat
    real colvector depf
    depf = du
    if (pmax>0) {
        depf  = depf[pmax+1::rows(du)]
        Xfull = Xfull[pmax+1::rows(du), .]
    }

    // lag selection
    real colvector icvec, tvec
    real scalar bestic
    icvec = J(pmax+1,1,.); tvec = J(pmax+1,1,.)
    for (p=0; p<=pmax; p++) {
        real matrix Xp,XXi
        real colvector bp,ep,sep
        Xp  = Xfull[., 1::(1+p)]
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
        popt = 0
        for (p=pmax; p>=1; p--) {
            if (tvec[p+1] >= 1.645) {
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

    real matrix Xs, XXi_s
    real colvector bs_, es_, ses_
    Xs    = Xfull[., 1::(1+popt)]
    XXi_s = invsym(quadcross(Xs,Xs))
    bs_   = XXi_s*quadcross(Xs,depf)
    es_   = depf - Xs*bs_
    real scalar sig2
    sig2  = (es_'es_)/(rows(Xs)-cols(Xs))
    ses_  = sqrt(diagonal(sig2*XXi_s))
    real scalar tauKSS
    tauKSS = bs_[1,1]/ses_[1,1]

    // RALS augmentation
    real scalar m2, m3, sig2A
    m2 = sum(es_:^2)/rows(es_)
    m3 = sum(es_:^3)/rows(es_)
    real matrix W, Xa, XaI
    real colvector ba, ea, sea
    W   = (es_:^2 :- m2), (es_:^3 :- m3 :- 3*m2*es_)
    Xa  = Xs, W
    XaI = invsym(quadcross(Xa,Xa))
    ba  = XaI*quadcross(Xa,depf)
    ea  = depf - Xa*ba
    sig2A = (ea'ea)/(rows(Xa)-cols(Xa))
    sea   = sqrt(diagonal(sig2A*XaI))
    real scalar tauRALS, rho2
    tauRALS = ba[1,1]/sea[1,1]
    rho2 = sig2A/sig2
    if (rho2<0) rho2=0
    if (rho2>1) rho2=1

    // CV.  Stage-2 RALS CVs use the RALS-LM table as a conservative proxy
    // (Yilanci-Ozgur 2025 §4.1 reports identical shape).
    real matrix crt, cvr
    crt = __rals_cv_lm()
    cvr = __rals_interp(crt, rho2)
    real rowvector cvKSS
    cvKSS = __rals_cv_fkss(T-popt, kbest, model)

    real matrix CV2
    CV2 = cvKSS \ cvr
    st_matrix(rname, (tauKSS, tauRALS, rho2, T, popt, kbest))
    st_matrix(cvname, CV2)
}
end
