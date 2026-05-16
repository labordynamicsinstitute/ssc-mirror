*! ralslmb 1.0.0  12may2026  Dr Merwan Roudane  <merwanroudane920@gmail.com>
*! RALS-LM unit-root test WITH STRUCTURAL BREAKS
*  Reference:
*    Meng, Lee & Payne (2017) Studies in Nonlinear Dynamics & Econometrics 21(1):31-45.
*    Meng, Im, Lee & Tieslau (2014) -- Festschrift, Springer.
*  Mirrors the GAUSS code rals_lm_breaks.src by Saban Nazlioglu.
*------------------------------------------------------------------------------

program define ralslmb, rclass
    version 14.0
    qui _rals_mata
    syntax varname(ts) [if] [in], [                ///
            MODel(integer 2)                       /// 1=level break ; 2=level+trend break
            BReaks(integer 1)                      /// 1 or 2
            MAXLags(integer 8)                     ///
            IC(string)                             ///
            TRimm(real 0.10)                       ///
            Graph                                  ///
            noHEADer                               ]

    if !inlist(`model',1,2) {
        di as error "model() must be 1 (level break) or 2 (level+trend break)"
        exit 198
    }
    if !inlist(`breaks',1,2) {
        di as error "breaks() must be 1 or 2"
        exit 198
    }
    marksample touse
    qui count if `touse'
    if r(N) < 30 {
        di as error "sample too small for ralslmb (N=" r(N) ")"
        exit 2001
    }
    capture tsset
    if _rc {
        di as error "data must be {bf:tsset} before running ralslmb"
        exit 459
    }
    local timevar `r(timevar)'

    if "`ic'"=="" local ic "tstat"
    local ic = lower("`ic'")
    if !inlist("`ic'","aic","bic","tstat") {
        di as error "ic() must be aic, bic or tstat"
        exit 198
    }

    tempname res cv
    mata: _rals_lmb_engine("`varlist'", "`touse'", `model', `breaks', `maxlags', "`ic'", `trimm', "`res'", "`cv'")

    local LMmin   = `res'[1,1]
    local tauRALS = `res'[1,2]
    local rho2    = `res'[1,3]
    local lag     = `res'[1,4]
    local tb1     = `res'[1,5]
    local tb2     = `res'[1,6]
    local T       = `res'[1,7]

    if "`header'"=="" {
        _rals_print_header "RALS-LM (breaks)" "Meng, Lee & Payne (2017)" "`varlist'" `T' `lag' "`ic'" `model'
    }
    _rals_print_lmb_table `LMmin' `tauRALS' `rho2' `cv' `breaks' `tb1' `tb2' "`timevar'" "`touse'"

    return scalar LMmin   = `LMmin'
    return scalar tauRALS = `tauRALS'
    return scalar rho2    = `rho2'
    return scalar T       = `T'
    return scalar lag     = `lag'
    return scalar tb1     = `tb1'
    if `breaks'==2 return scalar tb2 = `tb2'
    return scalar cv01_LM = `cv'[1,1]
    return scalar cv05_LM = `cv'[1,2]
    return scalar cv10_LM = `cv'[1,3]
    return scalar cv01    = `cv'[2,1]
    return scalar cv05    = `cv'[2,2]
    return scalar cv10    = `cv'[2,3]
    return local  test    = "RALS-LM with breaks"
    return local  cmdline = "ralslmb `varlist', model(`model') breaks(`breaks') maxlags(`maxlags') ic(`ic') trimm(`trimm')"

    if "`graph'" != "" {
        _rals_graph_lmb "`varlist'" "`timevar'" "`touse'" `tauRALS' `cv'[2,2] `tb1' `tb2' `breaks'
    }
end

program define _rals_print_lmb_table
    args LMmin tauRALS rho2 cv brks tb1 tb2 timevar touse
    _rals_print_two_row "LM_min (stage 1)" "RALS-LM (stage 2)"               ///
        `LMmin' `tauRALS' `rho2'                                             ///
        `cv'[1,1] `cv'[1,2] `cv'[1,3] `cv'[2,1] `cv'[2,2] `cv'[2,3]
    qui levelsof `timevar' if `touse', local(tvals)
    local tb1_label : word `tb1' of `tvals'
    di as text "  Break date #1 (index `tb1') : " as result "`tb1_label'"
    if `brks'==2 {
        local tb2_label : word `tb2' of `tvals'
        di as text "  Break date #2 (index `tb2') : " as result "`tb2_label'"
    }
    local concl_lm = cond(`LMmin'   < `cv'[1,2], "{bf:reject} H0 (LM_min, 5%)",         ///
                                                  "fail to reject H0 (LM_min, 5%)")
    local concl_r  = cond(`tauRALS' < `cv'[2,2], "{bf:reject} H0 (RALS-LM, 5%)",        ///
                                                  "fail to reject H0 (RALS-LM, 5%)")
    di as text "  Decision (5%)"
    di as text "    {c -}{c -} LM_min  : " as result "`concl_lm'"
    di as text "    {c -}{c -} RALS-LM : " as result "`concl_r'"
    di as text "{hline 80}"
    di as text "  Stage-1 CVs : Lee-Strazicich (2003) mid-range."
    di as text "  Stage-2 CVs : Meng, Lee & Payne (2017) rho^2 interpolation."
    di as text ""
end

program define _rals_graph_lmb
    args y timevar touse stat cv5 tb1 tb2 brks
    qui levelsof `timevar' if `touse', local(tvals)
    local tb1_val : word `tb1' of `tvals'
    local tb2_val : word `tb2' of `tvals'
    local sf : di %6.3f `stat'
    local cf : di %6.3f `cv5'
    local note "RALS-LM stat = `sf'   |   5% CV = `cf'"
    if `brks'==1 {
        twoway (line `y' `timevar' if `touse', lcolor("32 119 180") lwidth(medthick)),    ///
               xline(`tb1_val', lpattern(dash) lwidth(medthick) lcolor("220 50 50"))      ///
               title("RALS-LM with structural breaks", size(medium))                       ///
               subtitle("`note'", size(small))                                             ///
               note("Vertical line marks the endogenously selected break date.",          ///
                    size(vsmall))                                                          ///
               ytitle("`y'") xtitle("`timevar'")                                           ///
               legend(off)                                                                 ///
               scheme(s2color) graphregion(color(white)) name(ralslmb_`y', replace)
    }
    else {
        twoway (line `y' `timevar' if `touse', lcolor("32 119 180") lwidth(medthick)),    ///
               xline(`tb1_val' `tb2_val', lpattern(dash) lwidth(medthick)                 ///
                     lcolor("220 50 50"))                                                  ///
               title("RALS-LM with structural breaks", size(medium))                       ///
               subtitle("`note'", size(small))                                             ///
               note("Vertical lines mark the two endogenously selected break dates.",     ///
                    size(vsmall))                                                          ///
               ytitle("`y'") xtitle("`timevar'")                                           ///
               legend(off)                                                                 ///
               scheme(s2color) graphregion(color(white)) name(ralslmb_`y', replace)
    }
end

version 14.0
mata:
mata set matastrict off

void _rals_lmb_engine(string scalar yname, string scalar touse,
                      real scalar model, real scalar nbr, real scalar pmax,
                      string scalar icmode, real scalar trimm,
                      string scalar rname, string scalar cvname)
{
    real colvector y
    real scalar T, T1, T2, tb1, tb2, tb1m, tb2m, LMmin
    real scalar p, popt, rho2_best, lmbest, j
    real scalar bestic, popt_p
    st_view(y, ., yname, touse)
    T  = rows(y)
    T1 = round(trimm*T)
    T2 = round((1-trimm)*T)
    if (T1<pmax+2) T1 = pmax+3
    LMmin = 1e+10
    tb1m  = T1; tb2m = T1+3
    real scalar tauRALS_best, p_best
    tauRALS_best = .; rho2_best = .; p_best = 0

    tb1 = T1
    while (tb1 <= T2) {
        if (model==1) tb2 = tb1+2
        else          tb2 = tb1+3
        if (nbr==1) tb2 = T2     // skip inner loop, single break
        while (tb2 <= T2) {
            // construct deterministic z ---------------------------------------
            real matrix z
            real colvector du1, du2, dt1, dt2, dts
            dts = (1::T)
            if (nbr==1) {
                du1 = J(tb1,1,0) \ J(T-tb1,1,1)
                if (model==1) z = (dts, du1)
                else {
                    dt1 = J(tb1,1,0) \ (1::T-tb1)
                    z = (dts, du1, dt1)
                }
            }
            else { // nbr==2
                du1 = J(tb1,1,0) \ J(T-tb1,1,1)
                du2 = J(tb2,1,0) \ J(T-tb2,1,1)
                if (model==1) z = (dts, du1, du2)
                else {
                    dt1 = J(tb1,1,0) \ (1::T-tb1)
                    dt2 = J(tb2,1,0) \ (1::T-tb2)
                    z = (dts, du1, dt1, du2, dt2)
                }
            }
            // detrending  ------------------------------------------------------
            real colvector dy, b0v, s0, s
            real matrix dz
            dy = y[2::T] - y[1::T-1]
            dz = z[2::T,.] - z[1::T-1,.]
            b0v = invsym(quadcross(dz,dz))*quadcross(dz,dy)
            s0  = y[1] - z[1,.]*b0v
            s   = y :- s0 :- z*b0v

            // transformation for model 2 (Meng-Lee-Payne) ---------------------
            real colvector ylm, st
            if (model==1) ylm = s
            else {
                real scalar nobs
                nobs = T
                st = J(nobs,1,0)
                if (nbr==1) {
                    st[1::tb1]      = s[1::tb1]      :/ (tb1/nobs)
                    st[tb1+1::nobs] = s[tb1+1::nobs] :/ ((nobs-tb1)/nobs)
                }
                else {
                    st[1::tb1]           = s[1::tb1]           :/ (tb1/nobs)
                    st[tb1+1::tb2]       = s[tb1+1::tb2]       :/ ((tb2-tb1)/nobs)
                    st[tb2+1::nobs]      = s[tb2+1::nobs]      :/ ((nobs-tb2)/nobs)
                }
                ylm = st
            }

            // build regressors -----------------------------------------------
            real colvector ds
            ds = ylm[2::rows(ylm)] - ylm[1::rows(ylm)-1]
            real matrix dsl
            dsl = J(rows(ds), pmax, 0)
            for (j=1; j<=pmax; j++) dsl[j+1::rows(ds), j] = ds[1::rows(ds)-j]

            // search p from 0..pmax
            real colvector taup, aicp, sicp, tstatp, taur, rho2v
            taup   = J(pmax+1,1,.)
            aicp   = J(pmax+1,1,.)
            sicp   = J(pmax+1,1,.)
            tstatp = J(pmax+1,1,.)
            taur   = J(pmax+1,1,.)
            rho2v  = J(pmax+1,1,.)
            for (p=0; p<=pmax; p++) {
                real colvector dep, s1
                real matrix dzp, dsp, X, XXi, XX
                dep = dy[p+1::rows(dy)]
                s1  = ylm[1::T-1]; s1 = s1[p+1::rows(s1)]
                dzp = dz[p+1::rows(dz), .]
                if (p==0) X = s1, dzp
                else      X = s1, dzp, dsl[p+1::rows(dsl), 1::p]
                XX  = quadcross(X,X)
                XXi = invsym(XX)
                real colvector bv, ev
                bv = XXi*quadcross(X,dep)
                ev = dep - X*bv
                real scalar sig2v
                sig2v = (ev'ev)/(rows(X)-cols(X))
                real colvector sev
                sev = sqrt(diagonal(sig2v*XXi))
                taup[p+1]   = bv[1,1]/sev[1,1]
                aicp[p+1]   = ln(ev'ev/rows(X)) + 2*(cols(X)+2)/rows(X)
                sicp[p+1]   = ln(ev'ev/rows(X)) + (cols(X)+2)*ln(rows(X))/rows(X)
                tstatp[p+1] = abs(bv[cols(X),1]/sev[cols(X),1])

                // RALS augmentation
                real colvector e2, e3
                real scalar m2v, m3v, sig2A_v
                e2 = ev:^2; e3 = ev:^3
                m2v = sum(e2)/rows(ev); m3v = sum(e3)/rows(ev)
                real matrix W, XA, XAi
                W  = (e2 :- m2v), (e3 :- m3v :- 3*m2v*ev)
                XA = X, W
                XAi = invsym(quadcross(XA,XA))
                real colvector ba, eaa, sea
                ba  = XAi*quadcross(XA,dep)
                eaa = dep - XA*ba
                sig2A_v = (eaa'eaa)/(rows(XA)-cols(XA))
                sea = sqrt(diagonal(sig2A_v*XAi))
                taur[p+1]  = ba[1,1]/sea[1,1]
                rho2v[p+1] = sig2A_v/sig2v
            }
            // pick optimal lag
            real scalar laglm
            if (icmode=="tstat") {
                laglm = 1
                for (p=pmax; p>=1; p--) {
                    if (tstatp[p+1] >= 1.645) {
                        laglm = p+1
                        break
                    }
                }
            }
            else if (icmode=="aic") {
                laglm = 1
                bestic = aicp[1]
                for (p=1; p<=pmax; p++) {
                    if (aicp[p+1] < bestic) {
                        bestic = aicp[p+1]
                        laglm  = p+1
                    }
                }
            }
            else {
                laglm = 1
                bestic = sicp[1]
                for (p=1; p<=pmax; p++) {
                    if (sicp[p+1] < bestic) {
                        bestic = sicp[p+1]
                        laglm  = p+1
                    }
                }
            }

            if (taup[laglm] < LMmin) {
                LMmin = taup[laglm]
                tb1m  = tb1
                if (nbr==2) tb2m = tb2
                tauRALS_best = taur[laglm]
                rho2_best    = rho2v[laglm]
                p_best       = laglm - 1
            }
            if (nbr==1) {
                break
            }
            tb2++
        }
        tb1++
    }

    // CV
    real matrix crt, cvr
    crt = __rals_cv_lm_breaks(model, nbr)
    cvr = __rals_interp(crt, rho2_best)
    real rowvector cvLM
    cvLM = __rals_cv_lmstat_breaks(model, nbr, T-p_best)

    real matrix CV2
    CV2 = cvLM \ cvr
    st_matrix(rname, (LMmin, tauRALS_best, rho2_best, p_best, tb1m, tb2m, T))
    st_matrix(cvname, CV2)
}
end
