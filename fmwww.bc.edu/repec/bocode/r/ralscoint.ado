*! ralscoint 1.0.1  16may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS cointegration tests:  ECM, ADL, EG, EG2  with RALS augmentation
*  Reference:  Lee, H., Lee, J., & Im, K. (2015) Studies in Nonlinear Dynamics
*              & Econometrics 19(4): 397-413.
*  Mirrors the GAUSS code RALS_coint_size_power.g and RALS_coint_crit.g from
*  the SNDE 2013-0060 supplement (Hyejin Lee 2012 dissertation, Ch. 3).
*------------------------------------------------------------------------------

program define ralscoint, rclass
    version 14.0
    capture mata: __rals_loaded()
    if _rc qui _rals_mata
    syntax varlist(min=2 ts) [if] [in], [          ///
            TREND                                  ///
            METHod(string)                         /// ecm adl eg eg2 all
            BETA(real 1)                           /// prespecified beta (ECM only)
            BW(integer 0)                          /// LR-var bandwidth ; 0 = automatic
            Graph                                  ///
            noHEADer                               ]

    if "`method'"=="" local method "all"
    local method = lower("`method'")
    if !inlist("`method'","ecm","adl","eg","eg2","all") {
        di as error "method() must be ecm, adl, eg, eg2 or all"
        exit 198
    }
    marksample touse
    qui count if `touse'
    if r(N) < 25 {
        di as error "sample too small (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be tsset before running ralscoint"
        exit 459
    }
    local timevar `r(timevar)'
    local y : word 1 of `varlist'
    local x : list varlist - y
    local kreg : list sizeof x

    local model = cond("`trend'"!="", 2, 1)

    tempname res cv
    mata: _rals_coint_engine("`y'", "`x'", "`touse'", `model', `bw', `beta', "`method'", "`res'", "`cv'")
    matrix colnames `res' = ECM_t ECM_rals ECM_rho2 ADL_t ADL_rals ADL_rho2 EG_t EG_rals EG_rho2 EG2_t EG2_rals EG2_rho2 T

    if "`header'"=="" {
        _rals_coint_header "`y'" "`x'" `model' `kreg' `bw'
    }

    _rals_coint_table `res' `cv' "`method'" `kreg' `model'

    return scalar T          = `res'[1,13]
    return scalar ECM_t      = `res'[1,1]
    return scalar ECM_rals   = `res'[1,2]
    return scalar ECM_rho2   = `res'[1,3]
    return scalar ADL_t      = `res'[1,4]
    return scalar ADL_rals   = `res'[1,5]
    return scalar ADL_rho2   = `res'[1,6]
    return scalar EG_t       = `res'[1,7]
    return scalar EG_rals    = `res'[1,8]
    return scalar EG_rho2    = `res'[1,9]
    return scalar EG2_t      = `res'[1,10]
    return scalar EG2_rals   = `res'[1,11]
    return scalar EG2_rho2   = `res'[1,12]
    return matrix cv         = `cv'
    return local  yvar       = "`y'"
    return local  xvars      = "`x'"
    return local  model      = cond(`model'==1,"constant","constant+trend")
    return local  method     = "`method'"

    if "`graph'" != "" {
        _rals_coint_graph "`y'" "`x'" "`timevar'" "`touse'"
    }
end

program define _rals_coint_header
    args y x model kreg bw
    di as text ""
    di as text "{c TLC}{hline 78}{c TRC}"
    di as text "{c |}  " as result "RALS cointegration tests (ECM/ADL/EG/EG2){col 79}{c |}"
    di as text "{c |}  Reference : Lee, Lee & Im (2015, SNDE 19(4):397-413){col 79}{c |}"
    di as text "{c |}  Dependent : " as result "`y'{col 79}{c |}"
    di as text "{c |}  Regressors: " as result "`x'{col 79}{c |}"
    di as text "{c |}  k = `kreg'   model = " as result cond(`model'==1,"constant","constant+trend") ///
                as text "   LRV bandwidth = " as result cond(`bw'==0,"auto","`bw'") as text "{col 79}{c |}"
    di as text "{c BLC}{hline 78}{c BRC}"
end

program define _rals_coint_table
    args r cv method kreg model
    di as text ""
    di as text "{hline 78}"
    di as text "  Test        Stage1 t   RALS stat   rho^2     OLS 5% CV    RALS 1%/5%/10% CVs"
    di as text "{hline 78}"
    local rows "ECM ADL EG EG2"
    local i 1
    foreach m of local rows {
        local print = 0
        if "`method'"=="all" local print 1
        if "`method'"=="`=lower("`m'")'" local print 1
        if `print' {
            local t1 = `r'[1, (`i'-1)*3 + 1]
            local t2 = `r'[1, (`i'-1)*3 + 2]
            local r2 = `r'[1, (`i'-1)*3 + 3]
            local olscv = `cv'[`i', 1]
            local rcv1  = `cv'[`i', 2]
            local rcv5  = `cv'[`i', 3]
            local rcv10 = `cv'[`i', 4]
            di as text "  `m'         " as result %8.3f `t1' "    " %8.3f `t2'      ///
               as text "    " as result %6.3f `r2'                                  ///
               as text "     " as result %8.3f `olscv'                              ///
               as text "    " as result %7.3f `rcv1' " " %7.3f `rcv5' " " %7.3f `rcv10'
        }
        local ++i
    }
    di as text "{hline 78}"
    di as text "  Reject H0 of NO cointegration when statistic < CV(5%)."
    di as text "{hline 78}"
end

program define _rals_coint_graph
    args y x timevar touse
    local xfirst : word 1 of `x'
    twoway (line `y' `timevar' if `touse', lcolor("32 119 180") lwidth(medthick))   ///
           (line `xfirst' `timevar' if `touse', lcolor("220 50 50") lpattern(dash)),///
        title("Cointegration: `y' and `xfirst'", size(medium))                       ///
        legend(order(1 "`y'" 2 "`xfirst'") row(1) size(small))                       ///
        scheme(s2color) graphregion(color(white)) name(ralscoint_`y', replace)
end

version 14.0
mata:
mata set matastrict off

void _rals_coint_engine(string scalar yname, string scalar xnames, string scalar touse,
                        real scalar model, real scalar bw, real scalar beta_pre,
                        string scalar method, string scalar rname, string scalar cvname)
{
    real colvector y
    real matrix X
    st_view(y, ., yname, touse)
    st_view(X, ., xnames, touse)
    real scalar n, k, p
    n = rows(y); k = cols(X)
    p = model - 1
    real matrix detm, detm1
    if (model==1) {
        detm  = J(n-1,1,1)
        detm1 = J(n,1,1)
    }
    else {
        detm  = J(n-1,1,1), (1::n-1)
        detm1 = J(n,1,1), (1::n)
    }

    // pre-compute helper quantities  ------------------------------------------
    real colvector dy
    real matrix dx
    dy = y[2::n] - y[1::n-1]
    dx = X[2::n,.] - X[1::n-1,.]

    // -- 1. ECM  (prespecified beta) -----------------------------------------
    real colvector zECM
    zECM = y - X*J(k,1,beta_pre)
    real colvector zECM1, dECM
    zECM1 = zECM[1::n-1]
    dECM  = zECM[2::n] - zECM[1::n-1]
    real matrix ecmX, ecmXX
    if (model==1) ecmX = zECM1, detm
    else          ecmX = zECM1, detm
    ecmXX = ecmX, dx
    // OLS for RALS auxiliary residuals (without dx, see GAUSS code)
    real matrix XA, XAi
    real colvector bA, eA, sA
    XA  = ecmX
    XAi = invsym(quadcross(XA,XA))
    bA  = XAi*quadcross(XA,dy)
    eA  = dy - XA*bA
    // OLS for stage-1 ECM stat (with dx)
    real matrix XB, XBi
    real colvector bB, eB, sB
    XB  = ecmXX
    XBi = invsym(quadcross(XB,XB))
    bB  = XBi*quadcross(XB,dy)
    eB  = dy - XB*bB
    real scalar sigB
    sigB = (eB'eB)/(rows(XB)-cols(XB))
    sB   = sqrt(diagonal(sigB*XBi))
    real scalar ECMt
    ECMt = bB[1,1]/sB[1,1]
    // RALS  augmentation on eA
    real matrix W_ecm, ECMR, ECMRi
    real colvector b_ecmR, e_ecmR, s_ecmR
    real scalar m2v, m3v, sigA
    m2v = sum(eA:^2)/rows(eA); m3v = sum(eA:^3)/rows(eA)
    W_ecm = (eA:^2 :- m2v), (eA:^3 :- m3v :- 3*m2v*eA)
    ECMR  = ecmXX, W_ecm
    ECMRi = invsym(quadcross(ECMR,ECMR))
    b_ecmR = ECMRi*quadcross(ECMR,dy)
    e_ecmR = dy - ECMR*b_ecmR
    real scalar sigAR
    sigAR = (e_ecmR'e_ecmR)/(rows(ECMR)-cols(ECMR))
    s_ecmR = sqrt(diagonal(sigAR*ECMRi))
    real scalar ECMt_rals, rho_ecm
    ECMt_rals = b_ecmR[1,1]/s_ecmR[1,1]
    rho_ecm = __rals_rho2_lr(e_ecmR, eA)

    // -- 2. ADL --------------------------------------------------------------
    real matrix ADLx, ADLxi
    real colvector b_adl, e_adl, s_adl
    if (model==1) ADLx = y[1::n-1], X[1::n-1,.], dx
    else          ADLx = y[1::n-1], X[1::n-1,.], dx, detm
    ADLxi = invsym(quadcross(ADLx,ADLx))
    b_adl = ADLxi*quadcross(ADLx,dy)
    e_adl = dy - ADLx*b_adl
    real scalar sig_adl, ADLt
    sig_adl = (e_adl'e_adl)/(rows(ADLx)-cols(ADLx))
    s_adl = sqrt(diagonal(sig_adl*ADLxi))
    ADLt = b_adl[1,1]/s_adl[1,1]
    // RALS  ----
    real matrix W_adl, ADLR, ADLRi
    real colvector b_adlR, e_adlR, s_adlR
    real scalar m2a, m3a
    m2a = sum(e_adl:^2)/rows(e_adl); m3a = sum(e_adl:^3)/rows(e_adl)
    W_adl = (e_adl:^2 :- m2a), (e_adl:^3 :- m3a :- 3*m2a*e_adl)
    ADLR  = ADLx, W_adl
    ADLRi = invsym(quadcross(ADLR,ADLR))
    b_adlR = ADLRi*quadcross(ADLR,dy)
    e_adlR = dy - ADLR*b_adlR
    real scalar sig_adlR
    sig_adlR = (e_adlR'e_adlR)/(rows(ADLR)-cols(ADLR))
    s_adlR = sqrt(diagonal(sig_adlR*ADLRi))
    real scalar ADLt_rals, rho_adl
    ADLt_rals = b_adlR[1,1]/s_adlR[1,1]
    rho_adl = __rals_rho2_lr(e_adlR, e_adl)

    // -- 3. EG ---------------------------------------------------------------
    real matrix Xa_eg, Xa_egi
    real colvector b_eg, z_eg
    if (model==1) Xa_eg = X
    else          Xa_eg = X, detm1
    Xa_egi = invsym(quadcross(Xa_eg,Xa_eg))
    b_eg = Xa_egi*quadcross(Xa_eg,y)
    z_eg = y - Xa_eg*b_eg
    real colvector d_eg, eg1
    d_eg = z_eg[2::n] - z_eg[1::n-1]
    eg1  = z_eg[1::n-1]
    real matrix Xeg, Xegi
    real colvector b_eg2, e_eg2, s_eg2
    Xeg = eg1
    Xegi = invsym(quadcross(Xeg,Xeg))
    b_eg2 = Xegi*quadcross(Xeg,d_eg)
    e_eg2 = d_eg - Xeg*b_eg2
    real scalar sig_eg, EGt
    sig_eg = (e_eg2'e_eg2)/(rows(Xeg)-cols(Xeg))
    s_eg2 = sqrt(diagonal(sig_eg*Xegi))
    EGt   = b_eg2[1,1]/s_eg2[1,1]
    // RALS
    real scalar m2e, m3e
    m2e = sum(e_eg2:^2)/rows(e_eg2); m3e = sum(e_eg2:^3)/rows(e_eg2)
    real matrix W_eg, EGR, EGRi
    W_eg = (e_eg2:^2 :- m2e), (e_eg2:^3 :- m3e :- 3*m2e*e_eg2)
    if (model==1) {
        EGR = eg1, W_eg
    }
    else {
        EGR = eg1, W_eg, detm
    }
    EGRi = invsym(quadcross(EGR,EGR))
    real colvector b_egR, e_egR, s_egR
    b_egR = EGRi*quadcross(EGR,d_eg)
    e_egR = d_eg - EGR*b_egR
    real scalar sig_egR
    sig_egR = (e_egR'e_egR)/(rows(EGR)-cols(EGR))
    s_egR = sqrt(diagonal(sig_egR*EGRi))
    real scalar EGt_rals, rho_eg
    EGt_rals = b_egR[1,1]/s_egR[1,1]
    rho_eg = __rals_rho2_lr(e_egR, e_eg2)

    // -- 4. EG2 (Lee 2012) --------------------------------------------------
    real matrix EG2x, EG2xi
    real colvector b_eg22, e_eg22, s_eg22
    if (model==1) EG2x = eg1, dx
    else          EG2x = eg1, dx, detm
    EG2xi = invsym(quadcross(EG2x,EG2x))
    b_eg22 = EG2xi*quadcross(EG2x,d_eg)
    e_eg22 = d_eg - EG2x*b_eg22
    real scalar sig_eg22, EG2t
    sig_eg22 = (e_eg22'e_eg22)/(rows(EG2x)-cols(EG2x))
    s_eg22 = sqrt(diagonal(sig_eg22*EG2xi))
    EG2t   = b_eg22[1,1]/s_eg22[1,1]
    // RALS on EG2: auxiliary residuals come from regression of d_eg on eg1[+detm]  (per GAUSS)
    real matrix Xaux
    if (model==1) Xaux = eg1
    else          Xaux = eg1, detm
    real matrix Xauxi
    Xauxi = invsym(quadcross(Xaux,Xaux))
    real colvector b_aux, e_aux
    b_aux = Xauxi*quadcross(Xaux,d_eg)
    e_aux = d_eg - Xaux*b_aux
    real scalar m2g, m3g
    m2g = sum(e_aux:^2)/rows(e_aux); m3g = sum(e_aux:^3)/rows(e_aux)
    real matrix W_eg2, EG2R, EG2Ri
    W_eg2 = (e_aux:^2 :- m2g), (e_aux:^3 :- m3g :- 3*m2g*e_aux)
    EG2R  = EG2x, W_eg2
    EG2Ri = invsym(quadcross(EG2R,EG2R))
    real colvector b_eg2R, e_eg2R, s_eg2R
    b_eg2R = EG2Ri*quadcross(EG2R,d_eg)
    e_eg2R = d_eg - EG2R*b_eg2R
    real scalar sig_eg2R
    sig_eg2R = (e_eg2R'e_eg2R)/(rows(EG2R)-cols(EG2R))
    s_eg2R = sqrt(diagonal(sig_eg2R*EG2Ri))
    real scalar EG2t_rals, rho_eg2
    EG2t_rals = b_eg2R[1,1]/s_eg2R[1,1]
    rho_eg2 = __rals_rho2_lr(e_eg2R, e_aux)

    // ---- Critical values ---------------------------------------------------
    // Each row of cvr is :  [OLS-5% , RALS-1% , RALS-5% , RALS-10%]
    real matrix cvr
    cvr = J(4,4,.)
    cvr[1,1] = __rals_cv_ols(1, model, k)
    cvr[2,1] = __rals_cv_ols(2, model, k)
    cvr[3,1] = __rals_cv_ols(3, model, k)
    cvr[4,1] = __rals_cv_ols(4, model, k)
    real rowvector c1, c2, c3, c4
    c1 = __rals_interp(__rals_cv_ecm(p), rho_ecm)
    c2 = __rals_interp(__rals_cv_adl(p), rho_adl)
    c3 = __rals_interp(__rals_cv_eg(p),  rho_eg)
    c4 = __rals_interp(__rals_cv_eg(p),  rho_eg2)
    cvr[1,2..4] = c1
    cvr[2,2..4] = c2
    cvr[3,2..4] = c3
    cvr[4,2..4] = c4

    st_matrix(rname,
        (ECMt, ECMt_rals, rho_ecm,
         ADLt, ADLt_rals, rho_adl,
         EGt,  EGt_rals,  rho_eg,
         EG2t, EG2t_rals, rho_eg2, n))
    st_matrix(cvname, cvr)
}
end
