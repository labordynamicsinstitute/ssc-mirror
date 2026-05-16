*! ralsfadl 1.0.0  12may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS-Fourier ADL cointegration test
*  Reference:  Yilanci, V., Ulucak, R., Zhang, Y., & Andreoni, V. (2022).
*              Sustainable Development 31(2): 812-824.
*              (extends Banerjee, Arcabic & Lee 2017 ADL Fourier model with
*              the RALS w-augmentation of Im & Schmidt 2008.)
*  Mirrors the Eviews programs ralsfadl1.prg .. ralsfadl4.prg in the
*  RALS-FADL.zip supplement and supports 1-4 regressors.
*------------------------------------------------------------------------------

program define ralsfadl, rclass
    version 14.0
    qui _rals_mata
    syntax varlist(min=2 ts) [if] [in], [          ///
            TREND                                  ///
            MAXLags(integer 3)                     ///
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
    if r(N) < 25 {
        di as error "sample too small (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be tsset before running ralsfadl"
        exit 459
    }
    local timevar `r(timevar)'
    local y : word 1 of `varlist'
    local x : list varlist - y
    local kreg : list sizeof x
    if `kreg' < 1 | `kreg' > 4 {
        di as error "ralsfadl supports 1-4 regressors (you supplied `kreg')"
        exit 198
    }

    local model = cond("`trend'"!="", 2, 1)

    tempname res cv
    mata: _rals_fadl_engine("`y'", "`x'", "`touse'", `model', `maxlags', `fmax', `frequency', "`res'", "`cv'")

    local tFADL  = `res'[1,1]
    local tRALS  = `res'[1,2]
    local rho2   = `res'[1,3]
    local k_     = `res'[1,4]
    local T      = `res'[1,5]
    local lagy   = `res'[1,6]
    local minAIC = `res'[1,7]

    if "`header'"=="" {
        _rals_fadl_header "`y'" "`x'" `model' `kreg' `T'
    }
    _rals_fadl_table `tFADL' `tRALS' `rho2' `cv' `k_' `lagy' `minAIC' `kreg' `model'

    return scalar tauFADL = `tFADL'
    return scalar tauRALS = `tRALS'
    return scalar rho2    = `rho2'
    return scalar kfreq   = `k_'
    return scalar T       = `T'
    return scalar lag     = `lagy'
    return scalar AIC     = `minAIC'
    return scalar cv01    = `cv'[1,1]
    return scalar cv05    = `cv'[1,2]
    return scalar cv10    = `cv'[1,3]
    return local  test    = "RALS-FADL"

    if "`graph'" != "" {
        _rals_fadl_graph "`y'" "`x'" "`timevar'" "`touse'" `k_' `T'
    }
end

program define _rals_fadl_header
    args y x model kreg T
    di as text ""
    di as text "{c TLC}{hline 78}{c TRC}"
    di as text "{c |}  " as result "RALS-Fourier ADL cointegration test{col 79}{c |}"
    di as text "{c |}  Reference : Yilanci, Ulucak, Zhang & Andreoni (2022, Sustainable Dev.){col 79}{c |}"
    di as text "{c |}  Dependent : " as result "`y'" as text "{col 79}{c |}"
    di as text "{c |}  Regressors: " as result "`x'" as text "{col 79}{c |}"
    di as text "{c |}  k = `kreg'   T = `T'   model = " as result cond(`model'==1,"constant","constant+trend") as text "{col 79}{c |}"
    di as text "{c BLC}{hline 78}{c BRC}"
end

program define _rals_fadl_table
    args tFADL tRALS rho2 cv kfreq lag aic kreg model
    di as text ""
    di as text "{hline 78}"
    di as text "  Test                        Statistic        rho^2        1%        5%       10%"
    di as text "{hline 78}"
    di as text "  Fourier ADL (stage 1)      " as result %10.4f `tFADL'   ///
        as text "          .            .         .         ."
    di as text "  RALS-FADL (stage 2)        " as result %10.4f `tRALS'  ///
        as text "    " as result %8.4f `rho2'                              ///
        as text "  " as result %8.3f `cv'[1,1] " " %8.3f `cv'[1,2] " " %8.3f `cv'[1,3]
    di as text "{hline 78}"
    di as text "  Optimal Fourier frequency k = " as result `kfreq'                   ///
        as text "    Δy lag = " as result `lag'                                       ///
        as text "    minAIC = " as result %8.4f `aic'
    local concl = cond(`tRALS' < `cv'[1,2], "{bf:reject} H0: no cointegration at 5%", ///
                                              "fail to reject H0: no cointegration at 5%")
    di as result "  Conclusion: `concl'."
    di as text "{hline 78}"
    di as text ""
end

program define _rals_fadl_graph
    args y x timevar touse kfreq T
    local xfirst : word 1 of `x'
    tempvar fc fs
    local pi = _pi
    qui gen `fc' = sin(2*`pi'*_n*`kfreq'/`T')+cos(2*`pi'*_n*`kfreq'/`T') if `touse'
    twoway (line `y' `timevar' if `touse', lcolor("32 119 180") lwidth(medthick) yaxis(1))      ///
           (line `xfirst' `timevar' if `touse', lcolor("220 50 50") lpattern(dash) yaxis(1))    ///
           (line `fc' `timevar' if `touse', lcolor("80 80 80") lpattern(solid) yaxis(2)),       ///
        title("RALS-Fourier ADL: `y' on `xfirst'", size(medium))                                 ///
        subtitle("Optimal Fourier frequency k=`kfreq'", size(small))                             ///
        legend(order(1 "`y'" 2 "`xfirst'" 3 "Fourier component") row(1) size(small))             ///
        ytitle("levels") xtitle("`timevar'")                                                     ///
        scheme(s2color) graphregion(color(white)) name(ralsfadl_`y', replace)
end

version 14.0
mata:
mata set matastrict off

void _rals_fadl_engine(string scalar yname, string scalar xnames, string scalar touse,
                       real scalar model, real scalar pmax, real scalar fmax,
                       real scalar fix_k, string scalar rname, string scalar cvname)
{
    real colvector y
    real matrix X
    st_view(y, ., yname, touse)
    st_view(X, ., xnames, touse)
    real scalar n, k, kk, kbest, popt, j_
    n  = rows(y)
    k  = cols(X)
    real colvector dy
    real matrix dX
    dy = y[2::n] - y[1::n-1]
    dX = X[2::n,.] - X[1::n-1,.]

    real scalar kfrom, kto
    if (fix_k>0) {
        kfrom = fix_k
        kto   = fix_k
    }
    else {
        kfrom = 1
        kto   = fmax
    }

    real scalar bestAIC, AICv, p, jx
    bestAIC = 1e+20; kbest = 1; popt = 1
    real colvector best_dep
    real matrix best_X
    real colvector best_b, best_e
    real scalar best_n

    // Grid over Fourier frequency and lag of Δy (Δx uses same lag for parity
    // with the Eviews loops in ralsfadl{1..4}.prg).
    for (kk=kfrom; kk<=kto; kk++) {
        real colvector ss, cc
        ss = sin(2*pi()*(2::n)*kk/n)
        cc = cos(2*pi()*(2::n)*kk/n)
        for (p=1; p<=pmax; p++) {
            // build design ----------------------------------------------------
            // y on detm + y(-1) + X(-1) + Δx(-1..-p) + Δy(-1..-p) + s + c
            real matrix Lm_dy
            Lm_dy = J(rows(dy), p, 0)
            for (j_=1; j_<=p; j_++) Lm_dy[j_+1::rows(dy), j_] = dy[1::rows(dy)-j_]
            real matrix Lm_dx
            Lm_dx = J(rows(dy), p*k, 0)
            for (jx=1; jx<=k; jx++) {
                for (j_=1; j_<=p; j_++) {
                    Lm_dx[j_+1::rows(dy), (jx-1)*p + j_] = dX[1::rows(dy)-j_, jx]
                }
            }
            real matrix detm
            if (model==1) detm = J(rows(dy),1,1)
            else          detm = J(rows(dy),1,1), (2::n)
            real matrix Xall
            Xall = detm, y[1::n-1], X[1::n-1,.], Lm_dx, Lm_dy, ss, cc
            // trim leading p rows
            real colvector depf
            depf = dy[p+1::rows(dy)]
            real matrix Xf
            Xf = Xall[p+1::rows(Xall), .]
            // OLS  ------------------------------------------------------------
            real matrix XX, XXi
            real colvector bv, ev
            XX  = quadcross(Xf,Xf)
            XXi = invsym(XX)
            bv  = XXi*quadcross(Xf,depf)
            ev  = depf - Xf*bv
            real scalar nObs, kobs, AICc
            nObs = rows(Xf); kobs = cols(Xf)
            AICc = ln(ev'ev/nObs) + 2*(kobs+2)/nObs
            if (AICc < bestAIC) {
                bestAIC = AICc; kbest = kk; popt = p
                best_dep = depf; best_X = Xf; best_b = bv; best_e = ev; best_n = nObs
            }
        }
    }

    // stage-1 statistic: t on X(-1)[,1]  -> column position is detcols + 1 (y(-1)) + 1 (first X(-1))
    real scalar detcols
    detcols = (model==1 ? 1 : 2)
    real scalar pos
    pos = detcols + 1 + 1            // y(-1) then first X(-1)  --> Stata uses the same convention
    // We compute t on the X(-1)[,1] regressor (the first regressor's level lag)
    // as the EViews code does:  @tstats(2) where position 2 is x(-1) under
    // a constant-only model.   In general (constant + trend), x(-1) is at
    // position 3 (counting from 1 in the design matrix).
    // pos already encodes this.
    real matrix XXi_
    XXi_ = invsym(quadcross(best_X,best_X))
    real colvector se
    real scalar sig2
    sig2 = (best_e'best_e)/(rows(best_X)-cols(best_X))
    se   = sqrt(diagonal(sig2*XXi_))
    real scalar tFADL
    tFADL = best_b[pos,1] / se[pos,1]

    // RALS augmentation
    real scalar m2v, m3v, sig2A
    m2v = sum(best_e:^2)/rows(best_e)
    m3v = sum(best_e:^3)/rows(best_e)
    real matrix W, XR, XRi
    real colvector bR, eR, sR
    W   = (best_e:^2 :- m2v), (best_e:^3 :- m3v :- 3*m2v*best_e)
    XR  = best_X, W
    XRi = invsym(quadcross(XR,XR))
    bR  = XRi*quadcross(XR,best_dep)
    eR  = best_dep - XR*bR
    sig2A = (eR'eR)/(rows(XR)-cols(XR))
    sR    = sqrt(diagonal(sig2A*XRi))
    real scalar tRALS, rho2
    tRALS = bR[pos,1]/sR[pos,1]
    rho2  = sig2A/sig2
    if (rho2<0) rho2=0
    if (rho2>1) rho2=1

    // CV: use RALS-Fourier ADF table parameterised by # of regressors
    real rowvector cvr
    cvr = __rals_fadf_cv(n-popt, k+1, model, rho2)

    st_matrix(rname, (tFADL, tRALS, rho2, kbest, n, popt, bestAIC))
    st_matrix(cvname, cvr)
}
end
