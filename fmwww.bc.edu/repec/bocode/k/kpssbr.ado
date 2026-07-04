*! kpssbr 1.0.2  June 2026
*! KPSS unit root tests with up to 2 structural breaks
*!   - breaks(0) : KPSS (1992)
*!   - breaks(1) : Kurozumi (2002)
*!   - breaks(2) : Carrion-i-Silvestre & Sanso (2007)
*!
*! Port of Tsung-wu Ho (2025) COINT::kpss / kpss_1br / kpss_2br
*! R functions (bandwidth selection from cointReg 0.2.0).
*!
*! Author:
*!   H. Ozan Eruygur
*!   AHBV University, Ankara, Turkiye.
*!   Department of Economics
*!   https://www.ozaneruygur.com
*!   eruygur@gmail.com
*!
*!   Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik),
*!   Ankara, Turkiye.
*!   https://www.eruygurakademi.com
*!   eruygurakademi@gmail.com
*!
*!   kpssbr v1.0.2 -- June 2026

capture program drop kpssbr
program define kpssbr, rclass
    version 14
    syntax varname(ts) [if] [in] [, TREND BREaks(integer 0) Model(string) LAGs(string) USE(string asis) TRIM(real 0.10) TRACE ]

    * ---- defaults & validation -------------------------------------------
    if ("`lags'" == "") local lags "short"
    if !inlist(`breaks', 0, 1, 2) {
        di as error "breaks() must be 0, 1, or 2"
        exit 198
    }

    * use() parsing: "" -> NULL ; "nw ba" -> method=nw kernel=ba ;
    *                "15" -> fixed lag ; "and qs" etc.
    local use_method ""
    local use_kernel ""
    local use_fixed  ""
    local use_null   0
    if `"`use'"' == "" {
        local use_null = 1
    }
    else {
        local n_use : word count `use'
        if (`n_use' == 1) {
            local tok1 : word 1 of `use'
            capture confirm number `tok1'
            if (_rc == 0) {
                local use_fixed = `tok1'
            }
            else {
                di as error "use() with one token must be a number; got '`tok1''"
                exit 198
            }
        }
        else if (`n_use' == 2) {
            local use_method : word 1 of `use'
            local use_kernel : word 2 of `use'
            local use_method = lower("`use_method'")
            local use_kernel = lower("`use_kernel'")
            if !inlist("`use_method'", "nw", "and") {
                di as error "use() first token must be nw or and"
                exit 198
            }
            if !inlist("`use_kernel'", "ba", "pa", "qs") {
                di as error "use() second token must be ba, pa, or qs"
                exit 198
            }
        }
        else {
            di as error "use() takes at most 2 tokens"
            exit 198
        }
    }

    * lags() parsing
    local lags_kind ""
    local lags_fixed = .
    if inlist("`lags'", "short", "long", "nil") {
        local lags_kind "`lags'"
    }
    else {
        capture confirm number `lags'
        if (_rc) {
            di as error "lags() must be short, long, nil, or an integer"
            exit 198
        }
        local lags_kind "fixed"
        local lags_fixed = `lags'
    }

    * model() validation per mode
    if (`breaks' == 0) {
        * model is irrelevant; trend opt drives deterministic part
        if ("`model'" != "") {
            di as txt "(model() ignored when breaks(0); use 'trend' option)"
        }
        local detcode = cond("`trend'" != "", 2, 1)   /* 1=intercept, 2=intercept+trend */
    }
    else if (`breaks' == 1) {
        if ("`model'" == "") local model "intercept"
        if !inlist("`model'", "intercept", "both") {
            di as error "for breaks(1), model() must be intercept or both"
            exit 198
        }
        local detcode = cond("`model'" == "intercept", 1, 2)
    }
    else {  /* breaks==2 */
        if ("`model'" == "") local model "1"
        if !inlist("`model'", "1", "2", "3", "4") {
            di as error "for breaks(2), model() must be 1, 2, 3, or 4"
            exit 198
        }
        local detcode = `model'
    }

    * ---- sample selection -------------------------------------------------
    marksample touse
    qui count if `touse'
    local T = r(N)
    if (`T' < 10) {
        di as error "Too few observations (T=`T')"
        exit 2001
    }

    * materialise ts-operated varlist into a plain double tempvar
    tempvar yv
    qui gen double `yv' = `varlist' if `touse'

    * ---- dispatch ---------------------------------------------------------
    local use_isfixed 0
    local use_fixed_val 0
    if "`use_fixed'" != "" {
        local use_isfixed 1
        local use_fixed_val `use_fixed'
    }

    if (`breaks' == 0) {
        mata: kpssbr_main_classic("`yv'", "`touse'", `detcode', "`lags_kind'", `lags_fixed', `use_null', "`use_method'", "`use_kernel'", `use_isfixed', `use_fixed_val')
    }
    else if (`breaks' == 1) {
        mata: kpssbr_main_1br("`yv'", "`touse'", `detcode', "`lags_kind'", `lags_fixed', `use_null', "`use_method'", "`use_kernel'", `use_isfixed', `use_fixed_val', `trim')
    }
    else {
        local tr = cond("`trace'" != "", 1, 0)
        mata: kpssbr_main_2br("`yv'", "`touse'", `detcode', "`lags_kind'", `lags_fixed', `use_null', "`use_method'", "`use_kernel'", `use_isfixed', `use_fixed_val', `tr')
    }

    * ---- display & return -------------------------------------------------
    local stat  = r(teststat)
    local Lused = r(lag)
    local cv10  = r(cv10)
    local cv5   = r(cv5)
    local cv25  = r(cv25)
    local cv1   = r(cv1)

    di _newline
    di as txt "{hline 72}"
    if (`breaks' == 0) {
        di as txt " KPSS Stationarity Test"
        di as txt " Kwiatkowski, Phillips, Schmidt & Shin (1992)"
    }
    else if (`breaks' == 1) {
        di as txt " KPSS with One Structural Break"
        di as txt " Kurozumi (2002)"
    }
    else {
        di as txt " KPSS with Two Structural Breaks"
        di as txt " Carrion-i-Silvestre & Sanso (2007)"
    }
    di as txt "{hline 72}"
    di as txt " Variable    : " as res "`varlist'"
    if (`breaks' == 0) {
        if `detcode' == 1 local detstr "intercept"
        else              local detstr "intercept + trend"
        di as txt " Deterministic : " as res "`detstr'"
    }
    else if (`breaks' == 1) {
        if "`model'" == "intercept" local mlbl "level shift only"
        else                         local mlbl "level + slope shift"
        di as txt " Model       : " as res "`model'" as txt "  (`mlbl')"
    }
    else {
        local mname = ""
        if `detcode' == 1 local mname "AAn (level shifts, no trend)"
        if `detcode' == 2 local mname "AA  (level shifts + trend)"
        if `detcode' == 3 local mname "BB  (trend shifts)"
        if `detcode' == 4 local mname "CC  (level + trend shifts)"
        di as txt " Model       : " as res "`detcode' - `mname'"
    }
    if (`use_null' == 1) {
        di as txt " Lag spec    : " as res "lags(`lags')"
    }
    else if ("`use_fixed'" != "") {
        di as txt " Lag spec    : " as res "use(`use_fixed') (fixed, Bartlett kernel)"
    }
    else {
        di as txt " Lag spec    : " as res "use(`use_method' `use_kernel')"
    }
    di as txt " Lags used   : " as res %5.0f `Lused'
    di as txt " N obs       : " as res %5.0f `T'
    * ---- optional calendar date for break points ------------------------
    * If the dataset has been tsset with a calendar format (%tm, %tq, %ty,
    * %td, %tw, %th, %tc, %tC), also display the calendar date next to
    * the break-point observation number. This does NOT change the core
    * results; it is a display-only enhancement.
    *
    * Capture the r() values from the Mata dispatch BEFORE calling any
    * other command that might overwrite r().
    local rbp  = cond(`breaks' == 1, r(bpoint),  .)
    local rbp1 = cond(`breaks' == 2, r(bpoint1), .)
    local rbp2 = cond(`breaks' == 2, r(bpoint2), .)

    local tsfmt ""
    local tsvar ""
    local t0    = .
    quietly capture tsset
    if _rc == 0 {
        local tsfmt "`r(tsfmt)'"
        local tsvar "`r(timevar)'"
        if "`tsvar'" != "" {
            qui summarize `tsvar' if `touse', meanonly
            local t0 = r(min)
        }
    }

    if (`breaks' == 1) {
        local bp = `rbp'
        if !missing(`t0') & "`tsfmt'" != "" {
            local bpdate = `t0' + `bp' - 1
            local bpstr  : display `tsfmt' `bpdate'
            local bpstr = trim("`bpstr'")
            di as txt " Break point : " as res %5.0f `bp' as txt "  (" as res "`bpstr'" as txt ")"
        }
        else {
            di as txt " Break point : " as res %5.0f `bp' as txt "  (observation number within sample)"
        }
    }
    if (`breaks' == 2) {
        local bp1 = `rbp1'
        local bp2 = `rbp2'
        if !missing(`t0') & "`tsfmt'" != "" {
            local bp1d = `t0' + `bp1' - 1
            local bp2d = `t0' + `bp2' - 1
            local bp1s : display `tsfmt' `bp1d'
            local bp1s = trim("`bp1s'")
            local bp2s : display `tsfmt' `bp2d'
            local bp2s = trim("`bp2s'")
            di as txt " Break 1     : " as res %5.0f `bp1' as txt "  (" as res "`bp1s'" as txt ")"
            di as txt " Break 2     : " as res %5.0f `bp2' as txt "  (" as res "`bp2s'" as txt ")"
        }
        else {
            di as txt " Break 1     : " as res %5.0f `bp1'
            di as txt " Break 2     : " as res %5.0f `bp2'
        }
    }
    di as txt "{hline 72}"
    di as txt " Test statistic : " as res %12.6f `stat'
    di as txt " Critical values:"
    di as txt "    10%  : " as res %10.6f `cv10'
    di as txt "     5%  : " as res %10.6f `cv5'
    if (`breaks' == 0) {
        di as txt "   2.5%  : " as res %10.6f `cv25'
    }
    di as txt "     1%  : " as res %10.6f `cv1'
    * ----- H0 message: matches deterministic specification -----
    if (`breaks' == 0) {
        if (`detcode' == 1) {
            di as txt " H0: `varlist' is level stationary. Reject if statistic > critical value."
        }
        else {
            di as txt " H0: `varlist' is trend stationary. Reject if statistic > critical value."
        }
    }
    else if (`breaks' == 1) {
        if ("`model'" == "intercept") {
            di as txt " H0: `varlist' is level stationary with a level shift. Reject if statistic > critical value."
        }
        else {
            di as txt " H0: `varlist' is trend stationary with a level + slope shift. Reject if statistic > critical value."
        }
    }
    else {
        * breaks(2)
        if (`detcode' == 1) {
            di as txt " H0: `varlist' is level stationary with two level shifts. Reject if statistic > critical value."
        }
        else if (`detcode' == 2) {
            di as txt " H0: `varlist' is trend stationary with two level shifts. Reject if statistic > critical value."
        }
        else if (`detcode' == 3) {
            di as txt " H0: `varlist' is trend stationary with two slope shifts. Reject if statistic > critical value."
        }
        else {
            di as txt " H0: `varlist' is trend stationary with two level + slope shifts. Reject if statistic > critical value."
        }
    }
    di as txt "{hline 72}"

    return scalar teststat = `stat'
    return scalar lag      = `Lused'
    return scalar cv10     = `cv10'
    return scalar cv5      = `cv5'
    return scalar cv1      = `cv1'
    if (`breaks' == 0) return scalar cv25 = `cv25'
    if (`breaks' == 1) {
        return scalar bpoint = `rbp'
        if !missing(`t0') & "`tsfmt'" != "" {
            return scalar bpdate = `t0' + `rbp' - 1
            return local  tsfmt  "`tsfmt'"
        }
    }
    if (`breaks' == 2) {
        return scalar bpoint1 = `rbp1'
        return scalar bpoint2 = `rbp2'
        if !missing(`t0') & "`tsfmt'" != "" {
            return scalar bp1date = `t0' + `rbp1' - 1
            return scalar bp2date = `t0' + `rbp2' - 1
            return local  tsfmt   "`tsfmt'"
        }
    }
    return scalar N        = `T'
    return scalar breaks   = `breaks'
    return local  model    "`model'"
    return local  cmd      "kpssbr"
end


* ===========================================================================
*                                 Mata
* ===========================================================================

mata:

mata set matastrict on

/* --------------------------------------------------------------------------
   getBandwidth: Andrews (1991) and Newey-West (1994) automatic bandwidth.
   Verbatim port of cointReg::getBandwidth (cointReg 0.2.0, bandwidth.R).
   -------------------------------------------------------------------------- */

real scalar kpssbr_bw_and(real matrix u, string scalar kernel)
{
    real scalar T, k, j, denom, numer, a, bw, b
    real colvector rhovec, sigma2vec, my, mx, resid

    T = rows(u)
    k = cols(u)
    rhovec    = J(k, 1, 0)
    sigma2vec = J(k, 1, 0)

    for (j = 1; j <= k; j++) {
        my = u[2::T, j]
        mx = u[1::(T-1), j]
        b  = (mx' * my) / (mx' * mx)
        resid = my :- mx :* b
        rhovec[j]    = b
        sigma2vec[j] = (1/T) * sum(resid:^2)
    }

    denom = sum(sigma2vec:^2 :/ (1 :- rhovec):^4)

    if (kernel == "ba") {
        numer = sum(4 :* rhovec:^2 :* sigma2vec:^2 :/
                    ((1 :- rhovec):^6 :* (1 :+ rhovec):^2))
    }
    else {
        numer = sum(4 :* rhovec:^2 :* sigma2vec:^2 :/ (1 :- rhovec):^8)
    }
    a = numer / denom

    if      (kernel == "ba") bw = 1.1447 * (a * T)^(1/3)
    else if (kernel == "pa") bw = 2.6614 * (a * T)^(1/5)
    else if (kernel == "qs") bw = 1.3221 * (a * T)^(1/5)
    else if (kernel == "th") bw = 1.7462 * (a * T)^(1/5)
    else if (kernel == "tr") bw = 0.661  * (a * T)^(1/5)
    else                     bw = 1.1447 * (a * T)^(1/3)

    if (bw > T - 1) bw = T - 1
    return(bw)
}

real scalar kpssbr_bw_nw(real matrix u, string scalar kernel)
{
    real scalar T, k, npower, n, s0, s1, s2, q, Tpower, gam, bw, j
    real colvector u_w, umatw, sigma

    T = rows(u)
    k = cols(u)
    u_w = J(k, 1, 1)

    if      (kernel == "ba") npower = 2/9
    else if (kernel == "pa") npower = 4/25
    else if (kernel == "qs") npower = 2/25
    else                     npower = 2/9

    n = floor(4 * (T / 100)^npower)
    if (n < 1) n = 1

    umatw = u * u_w
    sigma = J(n + 1, 1, 0)
    for (j = 0; j <= n; j++) {
        sigma[j+1] = sum(umatw[(j+1)::T] :* umatw[1::(T-j)]) / T
    }

    s0 = sigma[1] + 2 * sum(sigma[2::(n+1)])

    s1 = 0
    s2 = 0
    if (kernel == "ba") {
        s1 = 2 * sum((1::n) :* sigma[2::(n+1)])
        q = 1
    }
    else {
        s2 = 2 * sum((1::n):^2 :* sigma[2::(n+1)])
        q = 2
    }
    Tpower = 1 / (2 * q + 1)

    if      (kernel == "ba") gam = 1.1447 * ((s1 / s0)^2)^Tpower
    else if (kernel == "pa") gam = 2.6614 * ((s2 / s0)^2)^Tpower
    else                     gam = 1.3221 * ((s2 / s0)^2)^Tpower

    bw = gam * T^Tpower
    return(bw)
}

real scalar kpssbr_bw_auto(real matrix u, string scalar method, string scalar kernel)
{
    if (method == "and") return(kpssbr_bw_and(u, kernel))
    return(kpssbr_bw_nw(u, kernel))
}

/* --------------------------------------------------------------------------
   Kernel-based long-run variance estimators used by COINT::kpss.
   Verbatim port of Bartlett_uni / QS_uni / Parzen_uni from
   COINT/R/uroot_breaks.R (Ho 2025).
   -------------------------------------------------------------------------- */

real scalar kpssbr_Bartlett_uni(real colvector e, real scalar v)
{
    real scalar T, lrv, i, w
    T = rows(e)
    lrv = (e' * e) / T
    if (v >= 1) {
        for (i = 1; i <= v; i++) {
            if (i >= T) break
            w   = 1 - i/(v + 1)
            lrv = lrv + 2 * (e[1::(T-i)]' * e[(i+1)::T]) * w / T
        }
    }
    return(lrv)
}

real scalar kpssbr_QS_uni(real colvector e, real scalar v)
{
    real scalar T, lrv, i, x1, x2, w
    T = rows(e)
    lrv = (e' * e) / T
    if (v >= 1) {
        for (i = 1; i <= v; i++) {
            if (i >= T) break
            x1 = i / v
            x2 = 6 * pi() * x1 / 5
            w  = (25 / (12 * (pi() * x1)^2)) * (sin(x2)/x2 - cos(x2))
            lrv = lrv + 2 * (e[1::(T-i)]' * e[(i+1)::T]) * w / T
        }
    }
    return(lrv)
}

real scalar kpssbr_Parzen_uni(real colvector e, real scalar v)
{
    real scalar T, A, i, half, m, e1mean, e2mean, sum_t1t2
    real colvector t1, t2, e_full

    T = rows(e)
    if (v > T) v = T - 1
    A = 0
    if (v < 1) {
        /* When v=0 the R loop body never executes, so A stays 0;
           A/T = 0 is returned. R kpss() never reaches Parzen with
           v=0 in practice because Parzen is only triggered when
           use=(method,"pa") with method-selected positive bw, but
           we mirror the behaviour exactly. */
        return(0)
    }

    /* max(seq(v/2)) in R: floor(v/2) when v>=2, but max(seq(0.5))=1
       when v==1 (since seq(0.5)==1 in R). We replicate this oddity. */
    if (v == 1) {
        half = 1
    }
    else {
        half = floor(v / 2)
    }

    for (i = 1; i <= v; i++) {
        if (i >= T) break
        if (i <= half) {
            m = 1 - 6 * (i/(v+1))^2 + 6 * (abs(i)/(v+1))^3
        }
        else {
            m = 2 * (1 - (abs(i)/(v+1)))^3
        }

        /* R:
             t1 = e[-seq(i)] - mean(.)
             t2 = embed(e,i+1)[,-seq(i)] - mean(.)
           t1 is e[(i+1)..T] de-meaned over those rows.
           For univariate input, embed(e,i+1)[,-seq(i)] is e[1..(T-i)],
           de-meaned over those rows. Both vectors have length T-i.
        */
        t1 = e[(i+1)::T]
        t2 = e[1::(T-i)]
        e1mean = sum(t1) / (T - i)
        e2mean = sum(t2) / (T - i)
        t1 = t1 :- e1mean
        t2 = t2 :- e2mean
        sum_t1t2 = t1' * t2
        A = A + m * sum_t1t2
    }
    return(A / T)
}

/* --------------------------------------------------------------------------
   Lag-length selectors (R: trunc(4*(T/100)^(2/9)) etc.).  Note that the
   R code uses trunc(), which for positive numbers is floor().
   -------------------------------------------------------------------------- */

real scalar kpssbr_default_lag(real scalar T, string scalar kind, real scalar fixed)
{
    if (kind == "short") return(floor(4  * (T/100)^(2/9)))
    if (kind == "long")  return(floor(12 * (T/100)^(2/9)))
    if (kind == "nil")   return(0)
    if (kind == "fixed") return(floor(fixed))
    return(floor(4 * (T/100)^(2/9)))
}

/* --------------------------------------------------------------------------
   Full kpss statistic given y AND deterministic matrix Xm (T x k).
   This is the function used by both the classic test and the inner loop
   of the break tests. We need y (not just residuals) because the auto-
   bandwidth in R is computed on y, not on residuals.
   -------------------------------------------------------------------------- */

real scalar kpssbr_full(real colvector y, real matrix Xm,
                      string scalar lags_kind, real scalar lags_fixed,
                      real scalar use_null, string scalar use_method,
                      string scalar use_kernel,
                      real scalar use_isfixed, real scalar use_fixed,
                      real scalar lag_out)
{
    real scalar T, lmax, lrv, eta, j, bw
    real colvector e, S, b
    real matrix ymat

    T = rows(y)

    /* OLS via QR with column pivoting -- matches R's lm.fit(),
       which is what residuals(lm(data.frame(y, ...))) calls.
       This is essential for break-search models where the design
       matrix can become numerically rank-deficient.

       qrsolve(A, b) returns least-squares solution and is stable
       under rank deficiency. */
    b = qrsolve(Xm, y)
    e = y - Xm * b

    /* Pick lag according to the R logic.  R order:
         if !is.null(use):
           if length(use)==2: lmax = trunc(getBandwidth(y, bandwidth=use[1], kernel=use[2]))
           if is.numeric(use): lmax = as.integer(use)   [Bartlett used]
         else: by lags=
    */
    if (use_null == 0) {
        if (use_isfixed == 1) {
            lmax = floor(use_fixed)
            if (lmax < 0) lmax = floor(4 * (T/100)^(2/9))
            lrv  = kpssbr_Bartlett_uni(e, lmax)
        }
        else {
            ymat = y
            bw   = kpssbr_bw_auto(ymat, use_method, use_kernel)
            lmax = floor(bw)
            if (use_kernel == "ba")      lrv = kpssbr_Bartlett_uni(e, lmax)
            else if (use_kernel == "qs") lrv = kpssbr_QS_uni(e, lmax)
            else if (use_kernel == "pa") lrv = kpssbr_Parzen_uni(e, lmax)
            else                         lrv = kpssbr_Bartlett_uni(e, lmax)
        }
    }
    else {
        lmax = kpssbr_default_lag(T, lags_kind, lags_fixed)
        lrv  = kpssbr_Bartlett_uni(e, lmax)
    }

    /* eta */
    S = J(T, 1, 0)
    S[1] = e[1]
    for (j = 2; j <= T; j++) S[j] = S[j-1] + e[j]
    eta = (S' * S) / (T^2 * lrv)

    lag_out = lmax
    return(eta)
}

/* --------------------------------------------------------------------------
   Classic KPSS (no break).
   detcode: 1=intercept only, 2=intercept+trend (matches help example
   where x=cbind(const,trend) - a 2-col deterministic matrix).
   -------------------------------------------------------------------------- */

void kpssbr_main_classic(string scalar yvar, string scalar tousev,
                       real scalar detcode,
                       string scalar lags_kind, real scalar lags_fixed,
                       real scalar use_null, string scalar use_method,
                       string scalar use_kernel,
                       real scalar use_isfixed, real scalar use_fixed)
{
    real colvector y, trend
    real scalar T, eta, lmax
    real matrix Xm
    real rowvector cval

    y = st_data(., yvar, tousev)
    y = select(y, !missing(y))
    T = rows(y)

    if (detcode == 1) {
        Xm = J(T, 1, 1)
    }
    else {
        trend = (1::T) :/ T
        Xm = (J(T, 1, 1), trend)
    }

    lmax = 0
    eta  = kpssbr_full(y, Xm, lags_kind, lags_fixed,
                     use_null, use_method, use_kernel,
                     use_isfixed, use_fixed, lmax)

    /* Critical values (R values: 10% 5% 2.5% 1%) */
    if (detcode == 1) {
        cval = (0.347, 0.463, 0.574, 0.739)
    }
    else {
        cval = (0.119, 0.146, 0.176, 0.216)
    }

    st_numscalar("r(teststat)", eta)
    st_numscalar("r(lag)",      lmax)
    st_numscalar("r(cv10)",     cval[1])
    st_numscalar("r(cv5)",      cval[2])
    st_numscalar("r(cv25)",     cval[3])
    st_numscalar("r(cv1)",      cval[4])
}

/* --------------------------------------------------------------------------
   KPSS with ONE structural break (Kurozumi 2002).
   detcode: 1=intercept (du1 only), 2=both (trend, dt1, du1).
   Search bpoint over idx = T1:T2 where T1=round(trim*T), T2=round((1-trim)*T).
   -------------------------------------------------------------------------- */

void kpssbr_main_1br(string scalar yvar, string scalar tousev,
                   real scalar detcode,
                   string scalar lags_kind, real scalar lags_fixed,
                   real scalar use_null, string scalar use_method,
                   string scalar use_kernel,
                   real scalar use_isfixed, real scalar use_fixed,
                   real scalar trim)
{
    real colvector y, trend, du1, dt1, roll_stat, idx
    real scalar T, T1, T2, k, z, lmax, eta, bpoint, teststat, TBi, lmin
    real matrix Xm
    real matrix cv_mat
    real rowvector cv_use

    y = st_data(., yvar, tousev)
    y = select(y, !missing(y))
    T = rows(y)

    trend = (1::T) :/ T
    T1 = round(trim * T)
    T2 = round((1 - trim) * T)
    if (T1 < 1) T1 = 1
    if (T2 > T) T2 = T
    if (T1 >= T2) {
        errprintf("Trim too aggressive: T1=%g T2=%g\n", T1, T2)
        exit(198)
    }
    idx = (T1::T2)
    k = rows(idx)
    roll_stat = J(k, 1, .)

    /* Loop over candidate break points */
    for (z = 1; z <= k; z++) {
        if (detcode == 1) {
            /* intercept: x = cbind(const, du1) */
            du1 = J(T, 1, 0)
            du1[|idx[z]+1, 1 \ T, 1|] = J(T - idx[z], 1, 1)
            Xm  = (J(T, 1, 1), du1)
        }
        else {
            /* both: in R kpss(y, x=cbind(trend,dt1,du1)) does
                 datmat = data.frame(y, trend, dt1, du1)
                 e = residuals(lm(datmat))
               lm() on a data.frame ADDS an intercept automatically, so
               the regression is y ~ 1 + trend + dt1 + du1.
            */
            du1 = J(T, 1, 0)
            du1[|idx[z]+1, 1 \ T, 1|] = J(T - idx[z], 1, 1)
            dt1 = J(T, 1, 0)
            dt1[|idx[z]+1, 1 \ T, 1|] = (1::(T - idx[z])) :/ T
            Xm  = (J(T, 1, 1), trend, dt1, du1)
        }

        lmax = 0
        eta  = kpssbr_full(y, Xm, lags_kind, lags_fixed,
                         use_null, use_method, use_kernel,
                         use_isfixed, use_fixed, lmax)
        roll_stat[z] = eta
    }

    /* min over idx */
    teststat = roll_stat[1]
    lmin = 1
    for (z = 2; z <= k; z++) {
        if (roll_stat[z] < teststat) {
            teststat = roll_stat[z]
            lmin = z
        }
    }
    bpoint = idx[lmin]

    /* Critical values from Kurozumi (2002): 5-row matrix indexed by TBi */
    if (detcode == 1) {
        cv_mat = (0.28299, 0.37538, 0.60388 \
                  0.22915, 0.30212, 0.48265 \
                  0.18678, 0.24247, 0.38052 \
                  0.16007, 0.20106, 0.30162 \
                  0.15176, 0.18688, 0.26842)
    }
    else {
        cv_mat = (0.09724, 0.12046, 0.17704 \
                  0.09724, 0.12046, 0.14208 \
                  0.06485, 0.07889, 0.11308 \
                  0.05570, 0.06615, 0.09122 \
                  0.05267, 0.06163, 0.08216)
    }

    /* TBi = round(10 * bpoint/T) ; if (TBi > 5) TBi = 10 - TBi */
    TBi = round(10 * bpoint / T)
    if (TBi > 5) TBi = 10 - TBi
    if (TBi < 1) TBi = 1
    if (TBi > 5) TBi = 5

    /* R: cv = rev(cv_mat[TBi,])  -> columns are 10%, 5%, 1% */
    cv_use = cv_mat[TBi, .]
    /* original column order in R was (10%-like, 5%-like, 1%-like)?
       Actually in R the cval object after t(as.matrix(rev(...))) is
       columns c("1%","5%","10%"), but rev reverses so original storage
       is (10%, 5%, 1%) ascending in restrictiveness... Let's re-check:

       R code:
         cv = t(as.matrix(rev(cval[TBi,,drop=F])))
         colnames(cv) = c("1%","5%","10%")
       rev() on a 1x3 thing gives a vector reversed.  The TBi rows of
       cv_mat in the source list are 5%-like, 1%-like, 0.1%-like values
       (largest=most extreme).  After rev they become (1%,5%,10%) by
       the column naming.  We replicate this: in OUR cv_mat we have:
         col 1 -> 5% (small)
         col 2 -> 2.5% (mid)  -- actually let's read the R code values
         col 3 -> 1%  (largest)
       After R does rev(cv_mat[TBi,]) and labels them ("1%","5%","10%"):
         label "1%"  := original col 3
         label "5%"  := original col 2
         label "10%" := original col 1

       So mapping is:
         cv1  = cv_mat[TBi, 3]
         cv5  = cv_mat[TBi, 2]
         cv10 = cv_mat[TBi, 1]
    */
    st_numscalar("r(teststat)", teststat)
    st_numscalar("r(lag)",      lmax)
    st_numscalar("r(bpoint)",   bpoint)
    st_numscalar("r(cv10)",     cv_use[1])
    st_numscalar("r(cv5)",      cv_use[2])
    st_numscalar("r(cv25)",     .)
    st_numscalar("r(cv1)",      cv_use[3])
}

/* --------------------------------------------------------------------------
   KPSS with TWO structural breaks (Carrion-i-Silvestre & Sanso 2007).
   model: 1=AAn 2=AA 3=BB 4=CC.
   -------------------------------------------------------------------------- */

void kpssbr_main_2br(string scalar yvar, string scalar tousev,
                   real scalar modnum,
                   string scalar lags_kind, real scalar lags_fixed,
                   real scalar use_null, string scalar use_method,
                   string scalar use_kernel,
                   real scalar use_isfixed, real scalar use_fixed,
                   real scalar trace_on)
{
    real colvector y, trend, du1, du2, dt1, dt2, idx1, idx2
    real scalar T, tb1, tb2, n1, n2, i, j, lmax, eta
    real scalar teststat, bp1, bp2, lam1, lam2, lam1row, lam2col
    real scalar cv1v, cv5v, cv10v, tmp
    real scalar bestmin, best_i, best_j
    real matrix Xm, rollStat
    real matrix mat_cv1, mat_cv5, mat_cv10

    /* These are conditionally assigned in the model branches; declare
       them all here so 'mata set matastrict on' is happy. */
    du1 = .
    du2 = .
    dt1 = .
    dt2 = .

    y = st_data(., yvar, tousev)
    y = select(y, !missing(y))
    T = rows(y)

    trend = (1::T) :/ T

    tb1 = 2
    tb2 = tb1 + 2
    idx1 = (tb1::(T - 4))
    idx2 = (tb2::(T - 2))
    n1 = rows(idx1)
    n2 = rows(idx2)

    rollStat = J(n2, n1, 1e30)
    /* R structure:
       rollStat <- sapply(idx1, roll1)
         roll1(z) = sapply(idx2, roll2) where outer z is idx1[i].
       sapply returns a matrix whose columns are the inner sapply outputs;
       so rollStat has dim n2 x n1, with rollStat[j,i] = stat at (idx1[i], idx2[j]).
       Then R does:
         R=which.min(apply(rollStat,1,min)) -> row of overall min (idx2-side)
         C=which.min(rollStat[R,])          -> col of overall min in that row (idx1-side)
         bp1=idx1[C]; bp2=idx2[R]
         teststat = min(rollStat)
    */

    for (i = 1; i <= n1; i++) {
        if (trace_on == 1 & mod(i, 50) == 0) {
            printf("{txt}  outer step %g of %g (%g remaining)\n",
                   i, n1, n1 - i)
        }
        if (modnum == 1) {
            du1 = J(T, 1, 0)
            if (idx1[i] < T) du1[|idx1[i]+1, 1 \ T, 1|] = J(T - idx1[i], 1, 1)
        }
        else if (modnum == 2) {
            du1 = J(T, 1, 0)
            if (idx1[i] < T) du1[|idx1[i]+1, 1 \ T, 1|] = J(T - idx1[i], 1, 1)
        }
        else if (modnum == 3) {
            dt1 = J(T, 1, 0)
            if (idx1[i] < T) dt1[|idx1[i]+1, 1 \ T, 1|] = (1::(T - idx1[i])) :/ T
        }
        else {  /* model 4 */
            du1 = J(T, 1, 0)
            dt1 = J(T, 1, 0)
            if (idx1[i] < T) {
                du1[|idx1[i]+1, 1 \ T, 1|] = J(T - idx1[i], 1, 1)
                dt1[|idx1[i]+1, 1 \ T, 1|] = (1::(T - idx1[i])) :/ T
            }
        }

        for (j = 1; j <= n2; j++) {
            /* second break must be strictly after the first */
            if (idx2[j] <= idx1[i]) continue

            if (modnum == 1) {
                du2 = J(T, 1, 0)
                if (idx2[j] < T) du2[|idx2[j]+1, 1 \ T, 1|] = J(T - idx2[j], 1, 1)
                Xm  = (du1, du2)
                /* R: x = cbind(du1,du2); datmat = data.frame(y, x)
                   -> lm(y ~ du1 + du2) has an intercept by default.
                   So we must add a column of ones. */
                Xm = (J(T, 1, 1), Xm)
            }
            else if (modnum == 2) {
                du2 = J(T, 1, 0)
                if (idx2[j] < T) du2[|idx2[j]+1, 1 \ T, 1|] = J(T - idx2[j], 1, 1)
                /* R: x = cbind(trend, du1, du2)
                   datmat = data.frame(y, x); lm(datmat) has intercept */
                Xm = (J(T, 1, 1), trend, du1, du2)
            }
            else if (modnum == 3) {
                dt2 = J(T, 1, 0)
                if (idx2[j] < T) dt2[|idx2[j]+1, 1 \ T, 1|] = (1::(T - idx2[j])) :/ T
                Xm = (J(T, 1, 1), trend, dt1, dt2)
            }
            else {
                du2 = J(T, 1, 0)
                dt2 = J(T, 1, 0)
                if (idx2[j] < T) {
                    du2[|idx2[j]+1, 1 \ T, 1|] = J(T - idx2[j], 1, 1)
                    dt2[|idx2[j]+1, 1 \ T, 1|] = (1::(T - idx2[j])) :/ T
                }
                Xm = (J(T, 1, 1), trend, du1, du2, dt1, dt2)
            }

            lmax = 0
            eta  = kpssbr_full(y, Xm, lags_kind, lags_fixed,
                             use_null, use_method, use_kernel,
                             use_isfixed, use_fixed, lmax)
            rollStat[j, i] = eta
        }
    }

    /* Find overall min */
    bestmin = rollStat[1, 1]
    best_i  = 1
    best_j  = 1
    for (i = 1; i <= n1; i++) {
        for (j = 1; j <= n2; j++) {
            if (rollStat[j, i] < bestmin) {
                bestmin = rollStat[j, i]
                best_i  = i
                best_j  = j
            }
        }
    }
    teststat = bestmin
    bp1 = idx1[best_i]
    bp2 = idx2[best_j]
    if (bp1 > bp2) {
        tmp = bp1; bp1 = bp2; bp2 = tmp
    }

    /* Critical-value matrices from CSS2007 (8x8) */
    if (modnum == 1) {
        mat_cv1 = (0.4758,0.3659,0.2802,0.2299,0.2275,0.2883,0.3664,0.4758 \
                   0,0.3682,0.2832,0.2109,0.1835,0.2075,0.2897,0.3612      \
                   0,0,0.2874,0.2077,0.1588,0.1620,0.2178,0.2937           \
                   0,0,0,0.2330,0.1733,0.1648,0.1811,0.2292                \
                   0,0,0,0,0.2271,0.2109,0.2027,0.2239                     \
                   0,0,0,0,0,0.2919,0.2846,0.2862                          \
                   0,0,0,0,0,0,0.3666,0.3692                               \
                   0,0,0,0,0,0,0,0.4853)
        mat_cv5 = (0.2992,0.2344,0.1890,0.1560,0.1581,0.1883,0.2339,0.3001 \
                   0,0.2339,0.1802,0.1423,0.1289,0.1390,0.1821,0.2366      \
                   0,0,0.1846,0.1401,0.1153,0.1165,0.1421,0.1859           \
                   0,0,0,0.1585,0.1266,0.1165,0.1275,0.1571                \
                   0,0,0,0,0.1564,0.1443,0.1388,0.1547                     \
                   0,0,0,0,0,0.1834,0.1830,0.1847                          \
                   0,0,0,0,0,0,0.2328,0.2332                               \
                   0,0,0,0,0,0,0,0.3009)
        mat_cv10 = (0.2262,0.1789,0.1441,0.1258,0.1286,0.1455,0.1770,0.2260 \
                    0,0.1775,0.1402,0.1148,0.1053,0.1116,0.1394,0.1791       \
                    0,0,0.1432,0.1128,0.0959,0.0963,0.1136,0.1441            \
                    0,0,0,0.1276,0.1049,0.0965,0.1043,0.1279                 \
                    0,0,0,0,0.1564,0.1151,0.1120,0.1264                      \
                    0,0,0,0,0,0.1440,0.1409,0.1438                           \
                    0,0,0,0,0,0,0.1774,0.1785                                \
                    0,0,0,0,0,0,0,0.2289)
    }
    else if (modnum == 2) {
        mat_cv1 = (0.1456,0.1169,0.1247,0.1601,0.1616,0.1270,0.1157,0.1444 \
                   0,0.1192,0.1002,0.1219,0.1400,0.1175,0.1028,0.1214      \
                   0,0,0.1252,0.1187,0.1253,0.1248,0.1147,0.1268           \
                   0,0,0,0.1604,0.1405,0.1272,0.1399,0.1574                \
                   0,0,0,0,0.1679,0.1191,0.1159,0.1590                     \
                   0,0,0,0,0,0.1223,0.1020,0.1260                          \
                   0,0,0,0,0,0,0.1205,0.1180                               \
                   0,0,0,0,0,0,0,0.1421)
        mat_cv5 = (0.0988,0.0834,0.0899,0.1073,0.1080,0.0910,0.0825,0.0992 \
                   0,0.0843,0.0750,0.0860,0.0948,0.0849,0.0749,0.0845      \
                   0,0,0.0895,0.0848,0.0898,0.0886,0.0831,0.0898           \
                   0,0,0,0.1069,0.0958,0.0896,0.0934,0.1051                \
                   0,0,0,0,0.1087,0.0833,0.0836,0.1061                     \
                   0,0,0,0,0,0.0894,0.0746,0.0900                          \
                   0,0,0,0,0,0,0.0856,0.0843                               \
                   0,0,0,0,0,0,0,0.0999)
        mat_cv10 = (0.0797,0.0699,0.0748,0.0858,0.0855,0.0750,0.0693,0.0801 \
                    0,0.0701,0.0641,0.0710,0.0771,0.0702,0.0643,0.0696       \
                    0,0,0.0739,0.0706,0.0740,0.0736,0.0691,0.0741            \
                    0,0,0,0.0860,0.0771,0.0742,0.0747,0.0850                 \
                    0,0,0,0,0.0859,0.0699,0.0698,0.0867                      \
                    0,0,0,0,0,0.0741,0.0633,0.0743                           \
                    0,0,0,0,0,0,0.0714,0.0699                                \
                    0,0,0,0,0,0,0,0.0815)
    }
    else if (modnum == 3) {
        mat_cv1 = (0.1524,0.1298,0.1098,0.1040,0.1003,0.1175,0.1393,0.1565 \
                   0,0.1205,0.1021,0.0892,0.0879,0.0963,0.1134,0.1357      \
                   0,0,0.0966,0.0820,0.0780,0.0827,0.0974,0.1153           \
                   0,0,0,0.0797,0.0751,0.0766,0.0888,0.1040                \
                   0,0,0,0,0.0803,0.0829,0.0910,0.1032                     \
                   0,0,0,0,0,0.0968,0.0993,0.1089                          \
                   0,0,0,0,0,0,0.1200,0.1282                               \
                   0,0,0,0,0,0,0,0.1518)
        mat_cv5 = (0.1060,0.0897,0.0766,0.0723,0.0738,0.0803,0.0937,0.1068 \
                   0,0.0822,0.0715,0.0650,0.0634,0.0681,0.0785,0.0929      \
                   0,0,0.0679,0.0601,0.0573,0.0599,0.0683,0.0802           \
                   0,0,0,0.0591,0.0556,0.0565,0.0633,0.0737                \
                   0,0,0,0,0.0590,0.0590,0.0646,0.0731                     \
                   0,0,0,0,0,0.0684,0.0709,0.0772                          \
                   0,0,0,0,0,0,0.0818,0.0886                               \
                   0,0,0,0,0,0,0,0.1021)
        mat_cv10 = (0.0848,0.0729,0.0630,0.0603,0.0613,0.0664,0.0755,0.0864 \
                    0,0.0669,0.0593,0.0540,0.0529,0.0562,0.0644,0.0754       \
                    0,0,0.0561,0.0504,0.0484,0.0502,0.0568,0.0659            \
                    0,0,0,0.0500,0.0473,0.0483,0.0528,0.0609                 \
                    0,0,0,0,0.0502,0.0500,0.0539,0.0606                      \
                    0,0,0,0,0,0.0570,0.0584,0.0634                           \
                    0,0,0,0,0,0,0.0674,0.0722                                \
                    0,0,0,0,0,0,0,0.0831)
    }
    else {
        mat_cv1 = (0.1439,0.1116,0.0852,0.0691,0.0704,0.0856,0.1098,0.1430 \
                   0,0.1100,0.0835,0.0644,0.0556,0.0634,0.0849,0.1113      \
                   0,0,0.0855,0.0652,0.0506,0.0503,0.0637,0.0845           \
                   0,0,0,0.0699,0.0560,0.0501,0.0550,0.0695                \
                   0,0,0,0,0.0704,0.0629,0.0637,0.0707                     \
                   0,0,0,0,0,0.0874,0.0840,0.0858                          \
                   0,0,0,0,0,0,0.1122,0.1124                               \
                   0,0,0,0,0,0,0,0.1425)
        mat_cv5 = (0.0972,0.0772,0.0605,0.0518,0.0520,0.0606,0.0765,0.0965 \
                   0,0.0763,0.0591,0.0470,0.0424,0.0466,0.0586,0.0757      \
                   0,0,0.0601,0.0474,0.0390,0.0389,0.0467,0.0605           \
                   0,0,0,0.0518,0.0425,0.0389,0.0423,0.0518                \
                   0,0,0,0,0.0521,0.0466,0.0470,0.0523                     \
                   0,0,0,0,0,0.0615,0.0586,0.0608                          \
                   0,0,0,0,0,0,0.0768,0.0766                               \
                   0,0,0,0,0,0,0,0.0966)
        mat_cv10 = (0.0788,0.0626,0.0508,0.0441,0.0444,0.0504,0.0625,0.0775 \
                    0,0.0621,0.0487,0.0399,0.0360,0.0397,0.0485,0.0619       \
                    0,0,0.0501,0.0398,0.0339,0.0340,0.0397,0.0500            \
                    0,0,0,0.0442,0.0367,0.0340,0.0365,0.0442                 \
                    0,0,0,0,0.0444,0.0397,0.0399,0.0443                      \
                    0,0,0,0,0,0.0507,0.0486,0.0503                           \
                    0,0,0,0,0,0,0.0620,0.0625                                \
                    0,0,0,0,0,0,0,0.0780)
    }

    /* lam1 = tb1/T, lam2 = tb2/T (R uses the LOWER bounds tb1=2, tb2=4
       defined at the top, NOT the best break points!  Replicate verbatim.) */
    lam1 = tb1 / T
    lam2 = tb2 / T

    if      (lam1 <= 0.15) lam1row = 1
    else if (lam1 <= 0.85) lam1row = round(10 * lam1)
    else                   lam1row = 8

    if      (lam2 <= 0.25) lam2col = 1
    else if (lam2 <= 0.95) lam2col = round(10 * lam2)
    else                   lam2col = 8

    cv1v  = mat_cv1[lam1row,  lam2col]
    cv5v  = mat_cv5[lam1row,  lam2col]
    cv10v = mat_cv10[lam1row, lam2col]

    st_numscalar("r(teststat)", teststat)
    st_numscalar("r(lag)",      lmax)
    st_numscalar("r(bpoint1)",  bp1)
    st_numscalar("r(bpoint2)",  bp2)
    st_numscalar("r(cv10)",     cv10v)
    st_numscalar("r(cv5)",      cv5v)
    st_numscalar("r(cv25)",     .)
    st_numscalar("r(cv1)",      cv1v)
}

end
