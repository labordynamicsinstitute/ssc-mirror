*! xtmixedroot 1.0.0  12jul2026
* Author: Merwan Roudane (merwanroudane920@gmail.com)
* https://github.com/merwanroudane
*
* Estimates theta, the fraction of I(1) (unit-root) units in a mixed panel,
* and tests H0: theta = theta0 for any theta0 in (0,1].
*
* Methods implemented (see help xtmixedroot_methods for the full
* step -> equation map):
*   - Ng, S. (2008) "A Simple Test for Nonstationarity in Mixed Panels",
*     Journal of Business & Economic Statistics 26(1), 113-127.
*     Estimators A (heterogeneous AR(p) dynamics), B (cross-sectional
*     correlation via factor proxies) and C (incidental trends), with
*     HAC (Newey-West) inference on theta-hat.
*   - Westerlund, J. (2016) "A simple test for nonstationarity in mixed
*     panels: A further investigation", Journal of Statistical Planning
*     and Inference 173, 1-30. Bias-adjusted statistics tau*_{1,T}
*     (valid for any T >= 2), tau*_{1,NT}, tau*_1 and tau*_{theta0}.
*
* Abbreviated step -> equation map (full map in the methods help):
*   V_t (cross-sec variance)          Ng eq. before Lemma 1; Westerlund Sec 3.1
*   theta-hat = mean of dV_t          Ng Thm 1; Westerlund's feasible t=2..T sum
*   AR(p) per unit, sigma_i, phi_ij   Ng Estimator A steps 1-3, eq (8)
*   D_i = prod_{k>=2}(phi_i1-phi_ik)  Ng p.117 (D_i = A^-1 B construction)
*   rescale D_i*y/sigma_i             Ng Estimator A step 4
*   factor proxies dybar_t, lags      Ng Estimator B, eq (12); Pesaran proxy
*   trend + dV on (1, 2t-1)           Ng Estimator C, eq (13)
*   HAC se of theta-hat               Ng Estimator A step 5 (Bartlett kernel)
*   theta* = theta-hat/s2e            Westerlund Sec 3.1
*   theta*_BA = theta* + theta0/T     Westerlund bias adjustment (Remark 4)
*   sigma2_theta,T / sigma2_theta,NT  Westerlund Sec 3.1.1 / 3.1.2
*   tau*_theta0                       Westerlund Theorem 2

program define xtmixedroot, rclass
    version 14.0
    syntax varname(numeric) [if] [in] [, ESTimator(string) Lags(integer 0)  ///
        MAXLags(integer 4) Factors(integer 1) PC Theta0(real 1)             ///
        HAC(integer 2) DEMean CLASSify GRaph LIST(integer 15) LEVel(cilevel) ]

    * ------------------------------------------------ panel setup
    capture quietly xtset
    if _rc {
        di as err "data must be xtset; use {bf:xtset panelvar timevar}"
        exit 459
    }
    local ivar "`r(panelvar)'"
    local tvar "`r(timevar)'"
    if ("`tvar'" == "") {
        di as err "time variable not set; use {bf:xtset panelvar timevar}"
        exit 459
    }

    marksample touse
    markout `touse' `ivar' `tvar'
    quietly count if `touse'
    if (r(N) == 0) error 2000

    * ------------------------------------------------ options
    if ("`estimator'" == "") local estimator "a"
    local estimator = lower("`estimator'")
    if (!inlist("`estimator'", "a", "b", "c")) {
        di as err "estimator() must be a, b or c"
        exit 198
    }
    local estcode = cond("`estimator'" == "a", 1, cond("`estimator'" == "b", 2, 3))
    if (`theta0' <= 0 | `theta0' > 1) {
        di as err "theta0() must lie in (0,1]; theta = 0 is not testable " ///
            "(the limiting distribution collapses; test theta0(.01) instead)"
        exit 198
    }
    if (`lags' < 0) {
        di as err "lags() must be a positive integer"
        exit 198
    }
    if (`maxlags' < 1) {
        di as err "maxlags() must be at least 1"
        exit 198
    }
    if (`hac' < 0) {
        di as err "hac() must be a nonnegative integer"
        exit 198
    }
    if (`factors' < 0) {
        di as err "factors() must be a nonnegative integer"
        exit 198
    }
    local usepc = ("`pc'" != "")
    local dem   = ("`demean'" != "")

    * ------------------------------------------------ engine
    tempname RES VMAT UMAT
    mata: _xmr_engine("`varlist'", "`ivar'", "`tvar'", "`touse'",        ///
        `estcode', `lags', `maxlags', `factors', `usepc', `theta0',      ///
        `hac', `dem', "`RES'", "`VMAT'", "`UMAT'")

    * ------------------------------------------------ unpack results
    local theta   = `RES'[1,1]
    local se      = `RES'[1,2]
    local tng     = `RES'[1,3]
    local png     = `RES'[1,4]
    local tlow    = `RES'[1,5]
    local plow    = `RES'[1,6]
    local tall    = `RES'[1,7]
    local pall    = `RES'[1,8]
    local beta    = `RES'[1,9]
    local sebeta  = `RES'[1,10]
    local thetaw  = `RES'[1,11]
    local s2e     = `RES'[1,12]
    local kappa   = `RES'[1,13]
    local s2lam   = `RES'[1,14]
    local thstar  = `RES'[1,15]
    local thba    = `RES'[1,16]
    local tau1T   = `RES'[1,17]
    local ptau1T  = `RES'[1,18]
    local tau1NT  = `RES'[1,19]
    local ptau1NT = `RES'[1,20]
    local tau1    = `RES'[1,21]
    local ptau1   = `RES'[1,22]
    local tauth   = `RES'[1,23]
    local ptauth  = `RES'[1,24]
    local tauthNT = `RES'[1,25]
    local ptauthNT = `RES'[1,26]
    local NN      = `RES'[1,27]
    local TT      = `RES'[1,28]
    local N1hat   = `RES'[1,29]
    local ngdone  = `RES'[1,30]
    local pbar    = `RES'[1,31]

    * ------------------------------------------------ display
    local estlbl = cond(`estcode' == 1, "A (heterogeneous AR(p) dynamics)", ///
        cond(`estcode' == 2, "B (A + cross-sectional correlation control)", ///
        "C (A + incidental linear trends)"))
    if (`lags' > 0) local laglbl "fixed p = `lags'"
    else            local laglbl = "BIC, 1..`maxlags' (mean p = " + string(`pbar', "%4.2f") + ")"
    if (`estcode' == 2) {
        local flbl = cond(`usepc', "first PC of D.`varlist'", "cross-sectional mean of D.`varlist'")
        local flbl "`flbl', lags 0..`factors'"
    }

    di
    di as text "{bf:Fraction of nonstationary (I(1)) units in a mixed panel}"
    di as text "Ng (2008, JBES 26:113-127); Westerlund (2016, JSPI 173:1-30)"
    di
    di as text "Panel variable: " as res "`ivar'" as text "    Time variable: " ///
        as res "`tvar'" as text "    N = " as res `NN' as text "    T = " as res `TT'
    di as text "Series: " as res "`varlist'" ///
        as text cond(`dem', "  (cross-sectionally demeaned for variance estimation)", "")
    if (`ngdone') {
        di as text "Estimator: " as res "`estlbl'"
        di as text "Lag order: " as res "`laglbl'" as text "    HAC lags (Bartlett): " as res "`hac'"
        if (`estcode' == 2) di as text "Factor proxy: " as res "`flbl'"
    }

    if (`ngdone') {
        local alpha2 = (100 - `level')/200
        local zc = invnormal(1 - `alpha2')
        local lo = `theta' - `zc'*`se'
        local hi = `theta' + `zc'*`se'
        di
        di as text "{hline 78}"
        di as text %-42s "Ng (2008) point estimate" _col(46) %9s "Estimate" ///
            _col(57) %9s "Std.Err." _col(68) "[`level'% CI]"
        di as text "{hline 78}"
        di as text "  theta  (fraction of I(1) units)" _col(46) as res %9.4f `theta' ///
            _col(57) %9.4f `se' _col(67) %6.3f `lo' as text "," as res %6.3f `hi'
        if (`estcode' == 3) {
            di as text "  var(lambda_i)  (incidental-trend var.)" _col(46) as res %9.4f `beta' ///
                _col(57) %9.4f `sebeta'
        }
        di as text "  implied number of I(1) units" _col(46) as res %9.0f `N1hat' ///
            as text "  (= [theta x N], integer part)"
        di as text "{hline 78}"
        di as text "Hypothesis tests based on theta-hat (HAC t statistics, asymptotically N(0,1))"
        di as text "{hline 78}"
        local s1 = cond(`png' < .01, "***", cond(`png' < .05, "**", cond(`png' < .1, "*", "")))
        local s2 = cond(`plow' < .01, "***", cond(`plow' < .05, "**", cond(`plow' < .1, "*", "")))
        local s3 = cond(`pall' < .01, "***", cond(`pall' < .05, "**", cond(`pall' < .1, "*", "")))
        local side1 = cond(`theta0' == 1, "H1: theta < 1     ", "H1: theta != `theta0'")
        di as text "  H0: theta = " %5.3f `theta0' "   `side1'" _col(46) as res %9.3f `tng' ///
            _col(57) as text "p = " as res %6.4f `png' as text "  `s1'"
        di as text "  H0: theta = 0.010   H1: theta > 0.01  " _col(46) as res %9.3f `tlow' ///
            _col(57) as text "p = " as res %6.4f `plow' as text "  `s2'  (any I(1) units?)"
        di as text "  H0: theta = 1.000   H1: theta < 1     " _col(46) as res %9.3f `tall' ///
            _col(57) as text "p = " as res %6.4f `pall' as text "  `s3'  (all units I(1)?)"
        di as text "{hline 78}"
    }
    else {
        di
        di as text "{hline 78}"
        di as text "Note: T = " as res `TT' as text " is too small for the Ng (2008) estimator" ///
            " (requires T >= 25;"
        di as text "      T >= 100 recommended). Only the Westerlund (2016) fixed-T statistics"
        di as text "      are reported below."
        di as text "{hline 78}"
    }

    di
    di as text "Westerlund (2016) bias-adjusted statistics"
    di as text "{hline 78}"
    di as text "  theta-hat (feasible, raw data)" _col(46) as res %9.4f `thetaw'
    di as text "  theta*  = theta-hat / s2_eps" _col(46) as res %9.4f `thstar'
    di as text "  theta*_BA = theta* + theta0/T" _col(46) as res %9.4f `thba'
    di as text "  s2_eps = " as res %7.4f `s2e' as text "   kappa_eps = " as res %7.4f `kappa' ///
        as text "   s2_lambda = " as res %7.4f `s2lam'
    if (`theta0' < 1) {
        di as text "  (s2_eps and kappa_eps from unit-wise AR(1) residuals; Westerlund Sec. 3.2)"
    }
    di as text "{hline 78}"
    if (`theta0' == 1) {
        local w1 = cond(`ptau1T' < .01, "***", cond(`ptau1T' < .05, "**", cond(`ptau1T' < .1, "*", "")))
        local w2 = cond(`ptau1NT' < .01, "***", cond(`ptau1NT' < .05, "**", cond(`ptau1NT' < .1, "*", "")))
        local w3 = cond(`ptau1' < .01, "***", cond(`ptau1' < .05, "**", cond(`ptau1' < .1, "*", "")))
        di as text "  Tests of H0: theta = 1 vs H1: theta < 1 (left-tailed)"
        di as text "  tau*_1,T   (any T >= 2; homog. intercepts)" _col(46) as res %9.3f `tau1T' ///
            _col(57) as text "p = " as res %6.4f `ptau1T' as text "  `w1'"
        di as text "  tau*_1,NT  (heterog. intercepts; large T) " _col(46) as res %9.3f `tau1NT' ///
            _col(57) as text "p = " as res %6.4f `ptau1NT' as text "  `w2'"
        di as text "  tau*_1     (large N and T)                " _col(46) as res %9.3f `tau1' ///
            _col(57) as text "p = " as res %6.4f `ptau1' as text "  `w3'"
    }
    else {
        local w1 = cond(`ptauth' < .01, "***", cond(`ptauth' < .05, "**", cond(`ptauth' < .1, "*", "")))
        local w2 = cond(`ptauthNT' < .01, "***", cond(`ptauthNT' < .05, "**", cond(`ptauthNT' < .1, "*", "")))
        di as text "  Tests of H0: theta = " %5.3f `theta0' " vs H1: theta != " %5.3f `theta0' ///
            " (two-sided; large N,T)"
        di as text "  tau*_theta0    (Theorem 2, simplified)   " _col(46) as res %9.3f `tauth' ///
            _col(57) as text "p = " as res %6.4f `ptauth' as text "  `w1'"
        di as text "  tau*_theta0,NT (sigma_theta,NT variance) " _col(46) as res %9.3f `tauthNT' ///
            _col(57) as text "p = " as res %6.4f `ptauthNT' as text "  `w2'"
    }
    di as text "{hline 78}"
    di as text "  * p<0.10, ** p<0.05, *** p<0.01." ///
        "  See {helpb xtmixedroot_methods:help xtmixedroot methods}."
    if (`ngdone' & `TT' < 100) {
        di as text "  Note: T < 100; Ng (2008) recommends T >= 100 for theta-hat. The"
        di as text "  Westerlund fixed-T statistics remain valid for any T >= 2."
    }
    if (`thstar' <= 0 & `thstar' < .) {
        di as text "  Note: theta* <= 0: the cross-sectional variance is non-increasing,"
        di as text "  which suggests theta ~ 0 (no I(1) units). tau*_theta0 is unavailable"
        di as text "  in this case; use the one-sided test of H0: theta = 0.01."
    }

    * ------------------------------------------------ classification
    if ("`classify'" != "" & `ngdone') {
        local nl = min(`list', `NN')
        di
        di as text "Classification of units (Ng 2008, Sec. 4): the [theta x N] = " ///
            as res `N1hat' as text " units"
        di as text "with the largest estimated dominant root |phi_i1| are classified I(1)."
        di as text "{hline 60}"
        di as text %12s "`ivar'" _col(16) %10s "|phi_i1|" _col(30) %10s "sigma_i" ///
            _col(44) %4s "p_i" _col(52) "class"
        di as text "{hline 60}"
        forvalues k = 1/`nl' {
            local uid   = `UMAT'[`k',1]
            local uphi  = `UMAT'[`k',2]
            local usig  = `UMAT'[`k',3]
            local up    = `UMAT'[`k',5]
            local ucls  = `UMAT'[`k',6]
            local clab = cond(`ucls' == 1, "I(1)", "I(0)")
            di as res %12.0g `uid' _col(16) %10.4f `uphi' _col(30) %10.4f `usig' ///
                _col(44) %4.0f `up' _col(52) "`clab'"
        }
        if (`nl' < `NN') di as text "  ... (" `NN' - `nl' " more units; full list in r(units))"
        di as text "{hline 60}"
    }

    * ------------------------------------------------ graph
    if ("`graph'" != "") {
        preserve
        quietly {
            clear
            set obs `TT'
            svmat double `VMAT', name(__xmrv)
            * __xmrv1 = time, __xmrv2 = raw V_t, __xmrv3 = rescaled V_t
            label variable __xmrv2 "cross-sectional variance"
            label variable __xmrv1 "`tvar'"
        }
        if (`ngdone') {
            quietly {
                gen double __idx = _n
                local b2 = cond(`estcode' == 3, `beta', 0)
                gen double __fit = __xmrv3[1] + `theta'*(__idx - 1) + `b2'*(__idx^2 - 1)
                label variable __xmrv3 "rescaled variance"
                label variable __fit "implied trend (slope = theta-hat)"
            }
            twoway (line __xmrv2 __xmrv1, lcolor(navy) lwidth(medthick)),        ///
                graphregion(color(white)) name(__xmr_g1, replace) nodraw        ///
                title("Raw data", size(medsmall)) ytitle("V{subscript:t}")      ///
                xtitle("`tvar'")
            twoway (line __xmrv3 __xmrv1, lcolor(navy) lwidth(medthick))         ///
                (line __fit __xmrv1, lcolor(cranberry) lpattern(dash)),          ///
                graphregion(color(white)) name(__xmr_g2, replace) nodraw        ///
                title("Rescaled data", size(medsmall))                          ///
                ytitle("V{subscript:t} (rescaled)") xtitle("`tvar'")            ///
                legend(order(1 "variance" 2 "slope = theta-hat") rows(1) size(small))
            graph combine __xmr_g1 __xmr_g2, rows(1) graphregion(color(white))  ///
                title("Cross-sectional variance of `varlist'", size(medium))    ///
                note("The variance of a mixed panel trends upward at rate theta (Ng 2008, Lemma 1)", size(vsmall))
            capture graph drop __xmr_g1 __xmr_g2
        }
        else {
            twoway (line __xmrv2 __xmrv1, lcolor(navy) lwidth(medthick)),        ///
                graphregion(color(white))                                        ///
                title("Cross-sectional variance of `varlist'", size(medium))    ///
                ytitle("V{subscript:t}") xtitle("`tvar'")
        }
        restore
    }

    * ------------------------------------------------ stored results
    return scalar N        = `NN'
    return scalar T        = `TT'
    return scalar theta0   = `theta0'
    return scalar level    = `level'
    if (`ngdone') {
        return scalar theta    = `theta'
        return scalar se_theta = `se'
        return scalar t        = `tng'
        return scalar p        = `png'
        return scalar t_low    = `tlow'
        return scalar p_low    = `plow'
        return scalar t_all    = `tall'
        return scalar p_all    = `pall'
        return scalar N1hat    = `N1hat'
        return scalar p_mean   = `pbar'
        if (`estcode' == 3) {
            return scalar varlambda    = `beta'
            return scalar se_varlambda = `sebeta'
        }
    }
    return scalar theta_w    = `thetaw'
    return scalar theta_star = `thstar'
    return scalar theta_ba   = `thba'
    return scalar sigma2e    = `s2e'
    return scalar kappa      = `kappa'
    return scalar sigma2lam  = `s2lam'
    if (`theta0' == 1) {
        return scalar tau1T    = `tau1T'
        return scalar p_tau1T  = `ptau1T'
        return scalar tau1NT   = `tau1NT'
        return scalar p_tau1NT = `ptau1NT'
        return scalar tau1     = `tau1'
        return scalar p_tau1   = `ptau1'
    }
    else {
        return scalar tautheta0     = `tauth'
        return scalar p_tautheta0   = `ptauth'
        return scalar tautheta0NT   = `tauthNT'
        return scalar p_tautheta0NT = `ptauthNT'
    }
    return local estimator "`estimator'"
    return local varname   "`varlist'"
    return local ivar      "`ivar'"
    return local tvar      "`tvar'"
    return local cmd       "xtmixedroot"

    matrix colnames `VMAT' = time V Vscaled
    return matrix V = `VMAT'
    if (`ngdone') {
        matrix colnames `UMAT' = id phi1 sigma D p i1
        return matrix units = `UMAT'
    }
end

* =====================================================================
* Mata engine
* =====================================================================
mata:

void _xmr_engine(string scalar yv, string scalar iv, string scalar tv,
                 string scalar touse, real scalar estcode, real scalar pfix,
                 real scalar pmax, real scalar qf, real scalar usepc,
                 real scalar theta0, real scalar M, real scalar dem,
                 string scalar resn, string scalar vmn, string scalar umn)
{
    real matrix data, Y, Yd, DY, DYr, X, XX, XXi, A, EV, UM, VM, Vb, meat
    real colvector V, Vs, dV, eta, lam, phi1, Dvec, sig, pvec, cls, times, ids
    real colvector yy, e, b, ftv, f, u, tt, chk, dt, mods, idx2, ordp
    real rowvector evals, xt
    real scalar N, T, i, t, s, k, l, p, mv, nd, s2e1, kap1, s2e0, kap0, s2lam
    real scalar thetaw, ths1, ths0, ba1, ba0, s2T, s2NT, s2NT0, sqN
    real scalar tau1T, p1T, tau1NT, p1NT, tau1, p1, tauth, pth, tauthNT, pthNT
    real scalar theta, se, tng, png, tlow, plow, tall, pall, beta, sebeta
    real scalar ngdone, pbar, N1, minT, Td, g0, gs, om2, den, sse, s4, ml
    real scalar r0, r0c, n, sig2, bic, bestbic, bestp, w, D2, sf, mf
    real scalar thsdisp, badisp, s2edisp, kapdisp
    complex rowvector L
    complex scalar lam1, Dc

    // ---------- data assembly ----------
    data = st_data(., (iv, tv, yv), touse)
    data = sort(data, (1,2))
    ids   = uniqrows(data[.,1])
    times = uniqrows(data[.,2])
    N = rows(ids)
    T = rows(times)
    if (N < 5) {
        errprintf("xtmixedroot: at least 5 cross-sectional units are required\n")
        exit(2001)
    }
    if (T < 2) {
        errprintf("xtmixedroot: at least 2 time periods are required\n")
        exit(2001)
    }
    if (rows(data) != N*T) {
        errprintf("xtmixedroot: the panel must be balanced with no gaps over the estimation sample\n")
        exit(459)
    }
    chk = J(N,1,1) # times
    if (max(abs(data[.,2] - chk)) > 0) {
        errprintf("xtmixedroot: the panel must be balanced with no gaps over the estimation sample\n")
        exit(459)
    }
    if (T > 2) {
        dt = times[|2 \ T|] - times[|1 \ T-1|]
        if (max(dt) - min(dt) > 1e-8) {
            errprintf("xtmixedroot: the time variable must be equally spaced\n")
            exit(459)
        }
    }
    Y = colshape(data[.,3], T)'

    // ---------- cross-sectional variance of the raw data ----------
    V = J(T,1,.)
    for (t=1; t<=T; t=t+1) {
        mv = sum(Y[t,.])/N
        V[t] = sum((Y[t,.] :- mv):^2)/N
    }

    // ---------- Westerlund (2016) block ----------
    thetaw = (V[T] - V[1])/T
    Yd = Y
    if (dem) {
        Yd = Y :- (rowsum(Y):/N)
    }
    DY = Yd[|2,1 \ T,N|] - Yd[|1,1 \ T-1,N|]
    nd = N*(T-1)
    s2e1 = quadsum(DY:^2)/nd
    kap1 = .
    if (s2e1 > 0) {
        kap1 = quadsum(DY:^4)/(s2e1*s2e1*nd)
    }

    // per-unit AR(1) regressions: intercepts (sigma2_lambda) and
    // residual-based error moments (used when theta0 < 1)
    lam = J(N,1,.)
    s2e0 = .
    kap0 = .
    s2lam = .
    if (T >= 4) {
        sse = 0
        s4  = 0
        for (i=1; i<=N; i=i+1) {
            yy = Yd[|2,i \ T,i|]
            X  = J(T-1,1,1), Yd[|1,i \ T-1,i|]
            XX = quadcross(X,X)
            b  = invsym(XX)*quadcross(X,yy)
            e  = yy - X*b
            lam[i] = b[1]
            sse = sse + quadsum(e:^2)
            s4  = s4  + quadsum(e:^4)
        }
        s2e0 = sse/nd
        if (s2e0 > 0) {
            kap0 = s4/(s2e0*s2e0*nd)
        }
        ml = sum(lam)/N
        s2lam = sum((lam :- ml):^2)/N
    }

    sqN = sqrt(N)
    ths1 = .
    tau1T = .
    p1T = .
    tau1NT = .
    p1NT = .
    tau1 = .
    p1 = .
    if (s2e1 > 0) {
        ths1 = thetaw/s2e1
        ba1  = ths1 + 1/T
        s2T  = 2*(T*T - 1)/(T*T) + (T - 1)/(T*T)*(kap1 - 3)
        if (s2T > 0) {
            tau1T = sqN*(ba1 - 1)/sqrt(s2T)
            p1T   = normal(tau1T)
        }
        if (s2lam < .) {
            s2NT = 2*(T*T - 1)/(T*T) + (T - 1)/(T*T)*(4*s2lam/s2e1 + kap1 - 3)
            if (s2NT > 0) {
                tau1NT = sqN*(ba1 - 1)/sqrt(s2NT)
                p1NT   = normal(tau1NT)
            }
        }
        tau1 = sqN*(ba1 - 1)/sqrt(2)
        p1   = normal(tau1)
    }

    tauth = .
    pth = .
    tauthNT = .
    pthNT = .
    ths0 = .
    if (theta0 < 1 & s2e0 < . & s2e0 > 0) {
        ths0 = thetaw/s2e0
        ba0  = ths0 + theta0/T
        den  = 2*ths0
        if (den > 1e-12) {
            tauth = sqN*(ba0 - theta0)/sqrt(den)
            pth   = 2*normal(-abs(tauth))
        }
        if (kap0 < . & s2lam < .) {
            s2NT0 = 2*(T*T - 1)/(T*T) + (T - 1)/(T*T)*(4*s2lam/s2e0 + kap0 - 3)
            if (s2NT0 > 0) {
                tauthNT = sqN*(ba0 - theta0)/(sqrt(theta0)*sqrt(s2NT0))
                pthNT   = 2*normal(-abs(tauthNT))
            }
        }
    }

    // ---------- Ng (2008) block ----------
    ngdone = 0
    theta = .
    se = .
    tng = .
    png = .
    tlow = .
    plow = .
    tall = .
    pall = .
    beta = .
    sebeta = .
    pbar = .
    N1 = .
    Vs   = J(T,1,.)
    phi1 = J(N,1,.)
    Dvec = J(N,1,.)
    sig  = J(N,1,.)
    pvec = J(N,1,.)
    cls  = J(N,1,.)
    minT = 25

    if (T >= minT) {
        ngdone = 1

        // factor proxy for Estimator B (Ng eq (12); Pesaran-type proxy)
        ftv = J(T,1,.)
        if (estcode == 2) {
            DYr = Y[|2,1 \ T,N|] - Y[|1,1 \ T-1,N|]
            if (usepc) {
                // first principal component of the differenced panel
                A = DYr*DYr'/N
                symeigensystem(A, EV = ., evals = .)
                f = EV[.,1]
                mf = sum(f)/(T-1)
                sf = sqrt(sum((f :- mf):^2)/(T-1))
                if (sf > 0) {
                    f = f/sf
                }
            }
            else {
                f = rowsum(DYr)/N
            }
            ftv[|2 \ T|] = f
        }

        // per-unit AR(p) fits (Ng Estimator A steps 1-4)
        pbar = 0
        for (i=1; i<=N; i=i+1) {
            // lag order: fixed or per-unit BIC on the common sample
            if (pfix > 0) {
                p = pfix
            }
            else {
                r0c = pmax + 1
                if (estcode == 2 & r0c < qf + 2) {
                    r0c = qf + 2
                }
                bestbic = .
                bestp = 1
                for (k=1; k<=pmax; k=k+1) {
                    sig2 = _xmr_arfit(Y[.,i], ftv, k, r0c, T, estcode, qf, b = .)
                    if (sig2 <= 0) {
                        continue
                    }
                    n = T - r0c + 1
                    bic = ln(sig2) + (k + 1 + (estcode == 2)*(qf + 1) + (estcode == 3))*ln(n)/n
                    if (bic < bestbic) {
                        bestbic = bic
                        bestp = k
                    }
                }
                p = bestp
            }
            pvec[i] = p
            pbar = pbar + p/N

            // final fit on the unit's own full sample
            r0 = p + 1
            if (estcode == 2 & r0 < qf + 2) {
                r0 = qf + 2
            }
            sig2 = _xmr_arfit(Y[.,i], ftv, p, r0, T, estcode, qf, b = .)
            // Ng step 2 verbatim: sigma_i^2 = (1/T) sum of squared residuals
            // (_xmr_arfit returns SSR/n with n = T - r0 + 1 residuals)
            sig2 = sig2*(T - r0 + 1)/T
            if (sig2 < 1e-12) {
                sig2 = 1e-12
            }
            sig[i] = sqrt(sig2)

            // dominant root and rescaling constant D_i
            // D_i = prod_{k=2}^{p} (phi_i1 - phi_ik): the partial-fractions
            // denominator defined by Ng's D_i = A^-1 B system (the printed
            // table rows for p = 3,4 contain typos; see methods help)
            if (p == 1) {
                phi1[i] = abs(b[1])
                Dvec[i] = 1
            }
            else {
                A = b[|1 \ p|]' \ (I(p-1), J(p-1,1,0))
                L = eigenvalues(A)
                mods = abs(L)'
                idx2 = order(-mods, 1)
                lam1 = L[idx2[1]]
                phi1[i] = mods[idx2[1]]
                Dc = 1
                for (k=2; k<=p; k=k+1) {
                    Dc = Dc*(lam1 - L[idx2[k]])
                }
                D2 = abs(Dc)
                if (D2 < 1e-6) {
                    D2 = 1e-6
                }
                Dvec[i] = D2
            }
        }

        // rescale (Estimator A/B: D_i*y/sigma_i; Estimator C: y/sigma_i,
        // exactly as printed in Ng's Estimator C step 4)
        for (i=1; i<=N; i=i+1) {
            if (estcode == 3) {
                w = 1/sig[i]
            }
            else {
                w = Dvec[i]/sig[i]
            }
            Y[.,i] = w*Y[.,i]
        }
        for (t=1; t<=T; t=t+1) {
            mv = sum(Y[t,.])/N
            Vs[t] = sum((Y[t,.] :- mv):^2)/N
        }
        dV = Vs[|2 \ T|] - Vs[|1 \ T-1|]
        Td = T - 1

        if (estcode <= 2) {
            // theta-hat = time average of dV (Ng Estimator A step 5);
            // HAC (Bartlett) standard error of the sample mean
            theta = sum(dV)/Td
            eta = dV :- theta
            g0 = quadcross(eta, eta)/Td
            om2 = g0
            for (s=1; s<=M; s=s+1) {
                if (s < Td) {
                    gs = quadcross(eta[|s+1 \ Td|], eta[|1 \ Td-s|])/Td
                    om2 = om2 + 2*(1 - s/(M + 1))*gs
                }
            }
            if (om2 < 0) {
                om2 = g0
            }
            se = sqrt(om2/Td)
        }
        else {
            // Estimator C: dV_t = theta + beta*(t^2-(t-1)^2) + eta_t (Ng eq (13))
            tt = (2::T)
            X = J(Td,1,1), (2*tt :- 1)
            XX = quadcross(X,X)
            XXi = invsym(XX)
            b = XXi*quadcross(X,dV)
            theta = b[1]
            beta  = b[2]
            u = dV - X*b
            meat = J(2,2,0)
            for (t=1; t<=Td; t=t+1) {
                xt = X[t,.]
                meat = meat + (u[t]*u[t])*(xt'xt)
            }
            for (s=1; s<=M; s=s+1) {
                if (s < Td) {
                    w = 1 - s/(M + 1)
                    for (t=s+1; t<=Td; t=t+1) {
                        A = X[t,.]'X[t-s,.]
                        meat = meat + w*u[t]*u[t-s]*(A + A')
                    }
                }
            }
            Vb = XXi*meat*XXi
            se = sqrt(Vb[1,1])
            sebeta = sqrt(Vb[2,2])
        }

        // hypothesis tests (Ng Sec. 4, hypotheses A, B, C)
        if (se > 0) {
            tng = (theta - theta0)/se
            if (theta0 == 1) {
                png = normal(tng)
            }
            else {
                png = 2*normal(-abs(tng))
            }
            tlow = (theta - 0.01)/se
            plow = 1 - normal(tlow)
            tall = (theta - 1)/se
            pall = normal(tall)
        }

        // classification by the dominant root (Ng Sec. 4)
        // Ng Sec. 4 verbatim: N1-hat = [theta-hat x N], the integer part
        N1 = floor(theta*N)
        if (N1 < 0) {
            N1 = 0
        }
        if (N1 > N) {
            N1 = N
        }
        cls = J(N,1,0)
        ordp = order(-phi1, 1)
        for (k=1; k<=N1; k=k+1) {
            cls[ordp[k]] = 1
        }
    }

    // ---------- outputs ----------
    // theta*/theta*_BA reported at the requested theta0: dy-based moments
    // under theta0 = 1, AR(1)-residual-based moments under theta0 < 1
    thsdisp = ths1
    s2edisp = s2e1
    kapdisp = kap1
    if (theta0 < 1 & ths0 < .) {
        thsdisp = ths0
        s2edisp = s2e0
        kapdisp = kap0
    }
    badisp = .
    if (thsdisp < .) {
        badisp = thsdisp + theta0/T
    }
    UM = ids, phi1, sig, Dvec, pvec, cls
    if (ngdone) {
        UM = UM[order(-UM[.,2], 1), .]
    }
    VM = times, V, Vs
    st_matrix(vmn, VM)
    st_matrix(umn, UM)
    st_matrix(resn, (theta, se, tng, png, tlow, plow, tall, pall, beta,
        sebeta, thetaw, s2edisp, kapdisp, s2lam, thsdisp, badisp,
        tau1T, p1T, tau1NT, p1NT, tau1, p1, tauth, pth, tauthNT, pthNT,
        N, T, N1, ngdone, pbar))
}

// OLS AR(p) fit for one unit: y_t on (const, y_{t-1..t-p} [, f_t..f_{t-q}] [, t])
// over rows r0..T; returns the residual variance and (via b) the p lag
// coefficients in b[1..p]
real scalar _xmr_arfit(real colvector y, real colvector ftv, real scalar p,
                       real scalar r0, real scalar T, real scalar estcode,
                       real scalar qf, real colvector b)
{
    real matrix X, XX
    real colvector yy, e, bb
    real scalar n, l, sig2

    n = T - r0 + 1
    if (n < p + 4) {
        b = J(p,1,.)
        return(-1)
    }
    yy = y[|r0 \ T|]
    X = J(n, 0, .)
    for (l=1; l<=p; l=l+1) {
        X = X, y[|r0-l \ T-l|]
    }
    if (estcode == 2) {
        for (l=0; l<=qf; l=l+1) {
            X = X, ftv[|r0-l \ T-l|]
        }
    }
    if (estcode == 3) {
        X = X, (r0::T)
    }
    X = X, J(n,1,1)
    XX = quadcross(X,X)
    bb = invsym(XX)*quadcross(X,yy)
    e = yy - X*bb
    sig2 = quadsum(e:^2)/n
    b = bb[|1 \ p|]
    return(sig2)
}

end
