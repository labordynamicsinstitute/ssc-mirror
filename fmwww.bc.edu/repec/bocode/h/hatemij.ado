*! hatemij v0.9.0
*! Tests for cointegration with two unknown regime shifts (Hatemi-J 2008)
*! Faithful Stata/Mata port of the author's own GAUSS code (coint2b in cItest2b.src,
*! aptech/gauss-hatemij). NOT a port of the Nazlioglu/TSPDLIB version.
*! Reference: Hatemi-J, A. (2008). Empirical Economics, 35, 497-505.
*!
*! Port verified against GAUSS output (nelsonplosser, m on bnd) to >=11 sig. digits
*! via an independent Python twin. OLS uses cholinv(X'X) to mirror GAUSS invpd(moment).

program define hatemij, rclass
    version 14.0

    * Backward compatibility: a bare reg or regnewey (no argument) selects the Zt*
    * break, as in earlier versions. Rewrite such a bare option to ...(zt) so the
    * valued syntax below can parse it. reg(adf|zt|za) / regnewey(adf|zt|za) pass through.
    gettoken hjlhs hjrhs : 0, parse(",") bind
    if `"`hjrhs'"' != "" {
        gettoken hjcomma hjopts : hjrhs, parse(",")
        local hjnew ""
        local hjchg 0
        local hjrest `"`hjopts'"'
        while `"`hjrest'"' != "" {
            gettoken hjtok hjrest : hjrest, bind
            if `"`hjtok'"' == "reg" {
                local hjtok "reg(zt)"
                local hjchg 1
            }
            else if inlist(`"`hjtok'"', "regnew", "regnewe", "regnewey") {
                local hjtok "regnewey(zt)"
                local hjchg 1
            }
            local hjnew `"`hjnew' `hjtok'"'
        }
        if `hjchg' local 0 `"`hjlhs', `hjnew'"'
    }

    syntax varlist(min=2 numeric ts) [if] [in] , [ Model(string) Choice(integer 2) Kmax(integer 12) KERnel(string) BWL(integer -1) TRImming(real 0.15) BGLags(integer -1) REG(string) REGNEWey(string) TSPdlib ]

    marksample touse
    qui count if `touse'
    if r(N) == 0 error 2000
    local nobs = r(N)

    qui tsset
    local timevar `r(timevar)'
    local panelvar `r(panelvar)'
    if "`panelvar'" != "" {
        di as error "Panel data not supported. Use a single time series."
        exit 198
    }
    if "`timevar'" == "" {
        di as error "Time variable not set. Use tsset first."
        exit 198
    }

    if "`model'" == "" local model "rs"
    local model = lower("`model'")
    if !inlist("`model'", "c", "ct", "rs") {
        di as error "model() must be c (constant), ct (constant and trend), or rs (regime shift)"
        exit 198
    }
    local mnum = cond("`model'" == "c", 2, cond("`model'" == "ct", 3, 4))
    if !inlist(`choice', 1, 2, 3, 4, 5, 6) {
        di as error "choice() must be 1 (fixed), 2 (AIC), 3 (BIC), 4 (downward-t 1.96), 5 (t-stat 1.645), or 6 (Breusch-Godfrey)"
        exit 198
    }
    if "`tspdlib'" != "" & `choice' == 5 {
        di as error "choice(5) is available only on the default path; the tspdlib path already uses the t-stat rule (1.645) under choice(4)"
        exit 198
    }
    if "`tspdlib'" != "" & `choice' == 6 {
        di as error "choice(6) (Breusch-Godfrey lag selection) is available only on the default path"
        exit 198
    }
    if "`reg'" != "" {
        local reg = lower("`reg'")
        if !inlist("`reg'", "adf", "zt", "za") {
            di as error "reg() must be adf, zt, or za (the break whose dates the regression uses)"
            exit 198
        }
    }
    if "`regnewey'" != "" {
        local regnewey = lower("`regnewey'")
        if !inlist("`regnewey'", "adf", "zt", "za") {
            di as error "regnewey() must be adf, zt, or za (the break whose dates the regression uses)"
            exit 198
        }
    }
    if `choice' == 6 & `bglags' < 0 {
        qui tsset
        local tsfmt `r(tsfmt)'
        local tdelta `r(tdelta)'
        if strpos("`tsfmt'", "q") local bglags = 8
        else if strpos("`tsfmt'", "m") local bglags = 24
        else if strpos("`tsfmt'", "w") local bglags = 52
        else if strpos("`tsfmt'", "d") local bglags = 100
        else local bglags = 2
        local bgcap = `kmax' * 5
        if `bglags' > `bgcap' local bglags = `bgcap'
        if `bglags' < 1 local bglags = 1
    }
    if `kmax' < 0 {
        di as error "kmax() must be non-negative"
        exit 198
    }
    if "`kernel'" == "" {
        if "`tspdlib'" != "" local kernel "iid"
        else local kernel "qs"
    }
    local kernel = lower("`kernel'")
    if "`kernel'" == "quadraticspectral" local kernel "qs"
    if !inlist("`kernel'", "iid", "bartlett", "qs") {
        di as error "kernel() must be iid, bartlett, or qs"
        exit 198
    }
    local knum = cond("`kernel'" == "iid", 0, cond("`kernel'" == "bartlett", 1, 2))
    if `trimming' <= 0 | `trimming' >= 0.5 {
        di as error "trimming() must be between 0 and 0.5"
        exit 198
    }
    local g_begin = round(`trimming' * `nobs')
    local g_f1 = round((1 - 2 * `trimming') * `nobs')
    local g_f2 = round((1 - `trimming') * `nobs')
    if (`g_f1' - `g_begin' + 1) < 1 | (`g_f2' - 2 * `g_begin' + 1) < 1 {
        di as error "trimming() is too large for this sample (`nobs' observations): the break grid is empty. Use a smaller value."
        exit 198
    }
    if `bwl' >= 0 & `bwl' >= `nobs' - 1 {
        di as error "bwl() must be smaller than the sample size (`nobs' observations)."
        exit 198
    }
    gettoken depvar indepvars : varlist
    local indepvars : list clean indepvars
    local k : word count `indepvars'

    if `k' > 4 {
        di as error "Hatemi-J (2008) tabulates critical values only for up to 4 regressors (m <= 4)."
        di as error "You specified `k' regressors, so the test cannot be evaluated. Use at most 4."
        exit 198
    }

    preserve
    qui keep if `touse'
    sort `timevar'

    if "`tspdlib'" != "" {
        mata: hatemij_tsp_main("`depvar'", "`indepvars'", "`timevar'", `mnum', `choice', `kmax', `knum', `bwl', `trimming')
    }
    else {
        mata: hatemij_main("`depvar'", "`indepvars'", "`timevar'", `mnum', `choice', `kmax', `knum', `bwl', `trimming', `bglags')
    }

    restore

    capture drop D1
    capture drop D2
    local rb "zt"
    if "`reg'" != "" local rb "`reg'"
    else if "`regnewey'" != "" local rb "`regnewey'"
    local rblab "Zt*"
    if "`rb'" == "adf" local rblab "ADF*"
    if "`rb'" == "za"  local rblab "Za*"
    local bd1 = scalar(__hj_d1`rb')
    local bd2 = scalar(__hj_d2`rb')
    qui gen byte D1 = (`timevar' > `bd1') if `touse'
    qui gen byte D2 = (`timevar' > `bd2') if `touse'
    label variable D1 "Hatemi-J regime dummy 1 (=1 after first `rblab' break)"
    label variable D2 "Hatemi-J regime dummy 2 (=1 after second `rblab' break)"

    if "`reg'" != "" | "`regnewey'" != "" {
        local regvars ""
        if `mnum' == 3 {
            capture drop trend
            qui gen double trend = .
            sort `touse' `timevar'
            qui by `touse': replace trend = _n if `touse'
            label variable trend "Hatemi-J linear trend (estimation order)"
            local regvars "trend"
        }
        local regvars "`regvars' `indepvars'"
        if `mnum' == 4 {
            foreach v of local indepvars {
                capture drop D1_`v'
                capture drop D2_`v'
                qui gen double D1_`v' = D1 * `v' if `touse'
                qui gen double D2_`v' = D2 * `v' if `touse'
                label variable D1_`v' "D1 x `v'"
                label variable D2_`v' "D2 x `v'"
                local regvars "`regvars' D1_`v' D2_`v'"
            }
        }
        local regvars "`regvars' D1 D2"
        local regvars : list clean regvars
    }

    local kmodel = `k'

    di _n as text "{bf:Hatemi-J (2008) two-break cointegration test}"
    di    as text "Cointegration with two unknown regime shifts"
    local mtxt "regime shift"
    if "`model'" == "c" local mtxt "constant"
    if "`model'" == "ct" local mtxt "constant and trend"
    local ctxt "AIC"
    if `choice' == 1 local ctxt "fixed (kmax)"
    if `choice' == 3 local ctxt "BIC"
    if `choice' == 4 local ctxt "downward-t (1.96)"
    if `choice' == 5 local ctxt "t-stat (1.645)"
    if `choice' == 6 local ctxt "Breusch-Godfrey GTS (bglags = `bglags')"
    if "`tspdlib'" != "" {
        local ctxt "Akaike"
        if `choice' == 1 local ctxt "fixed (kmax)"
        if `choice' == 3 local ctxt "Schwarz"
        if `choice' == 4 local ctxt "t-stat"
    }
    local llab "selected lag"
    if `choice' == 1 local llab "fixed lag"
    local lagval = scalar(__hj_lagadf)
    di _n as text "  Dependent variable" _col(27) as result "`depvar'"
    di    as text "  Independent vars"   _col(27) as result "`indepvars'"
    di    as text "  Observations"       _col(27) as result `nobs' as text "    Regressors:" as result " `k'"
    di    as text "  Specification"      _col(27) as result "`mtxt' (model `model')"
    local kertxt "quadratic spectral"
    if "`kernel'" == "iid" local kertxt "iid"
    if "`kernel'" == "bartlett" local kertxt "Bartlett"
    if "`tspdlib'" != "" {
        di as text "  Method"             _col(27) as result "TSPDLIB coint_hatemiJ"
        local bwtxt "round(4*(T/100)^(2/9))"
        if `bwl' >= 0 local bwtxt "`bwl' (user-set)"
        if "`kernel'" == "iid" local bwtxt "n/a"
        di as text "  Long-run variance" _col(27) as result "`kertxt'" as text "  (bandwidth = " as result "`bwtxt'" as text ")"
    }
    else {
        local bwtxt "Andrews (1991) automatic"
        if `bwl' >= 0 local bwtxt "`bwl' (user-set)"
        if "`kernel'" == "iid" local bwtxt "n/a"
        di as text "  Long-run variance" _col(27) as result "`kertxt'" as text "  (bandwidth = " as result "`bwtxt'" as text ")"
    }
    di    as text "  Trimming"           _col(27) as result %5.3f `trimming'
    di    as text "  Lag selection"      _col(27) as result "`ctxt'" as text "  (kmax = " as result `kmax' as text ", `llab' = " as result `lagval' as text ")"
    if `choice' == 6 {
        local bgpv = scalar(__hj_bgp)
        if scalar(__hj_bgwarn) == 1 {
            di as text "  Breusch-Godfrey"   _col(27) as result "min p = " %6.4f `bgpv' as text "  (orders 1-`bglags')"
            di as result "  Warning: residual autocorrelation could not be eliminated with kmax = `kmax' lags."
            di as result "           Results should be interpreted with caution; consider increasing kmax()."
        }
        else {
            di as text "  Breusch-Godfrey"   _col(27) as result "min p = " %6.4f `bgpv' as text "  (orders 1-`bglags'): no residual autocorrelation"
        }
    }
    di _n

    local tvfmt : format `timevar'

    local havecv = (`k' <= 4)
    if `havecv' {
        tempname cvadfzt cvza
        if `k' == 1 {
            matrix `cvadfzt' = (-6.503, -6.015, -5.653)
            matrix `cvza' = (-90.794, -76.003, -52.232)
        }
        else if `k' == 2 {
            matrix `cvadfzt' = (-6.928, -6.458, -6.224)
            matrix `cvza' = (-99.458, -83.644, -76.806)
        }
        else if `k' == 3 {
            matrix `cvadfzt' = (-7.833, -7.352, -7.118)
            matrix `cvza' = (-118.577, -104.860, -97.749)
        }
        else if `k' == 4 {
            matrix `cvadfzt' = (-8.353, -7.903, -7.705)
            matrix `cvza' = (-140.135, -123.870, -116.169)
        }
        local cz1 = `cvadfzt'[1,1]
        local cz2 = `cvadfzt'[1,2]
        local cz3 = `cvadfzt'[1,3]
        local ca1 = `cvza'[1,1]
        local ca2 = `cvza'[1,2]
        local ca3 = `cvza'[1,3]
        return matrix cv_adfzt = `cvadfzt'
        return matrix cv_za = `cvza'
    }

    local d1a : display `tvfmt' scalar(__hj_d1adf)
    local d2a : display `tvfmt' scalar(__hj_d2adf)
    local o1a : display %4.0f scalar(__hj_o1adf)
    local o2a : display %4.0f scalar(__hj_o2adf)
    local B1a = strtrim("`d1a'") + " (" + strtrim("`o1a'") + ")"
    local B2a = strtrim("`d2a'") + " (" + strtrim("`o2a'") + ")"
    local d1t : display `tvfmt' scalar(__hj_d1zt)
    local d2t : display `tvfmt' scalar(__hj_d2zt)
    local o1t : display %4.0f scalar(__hj_o1zt)
    local o2t : display %4.0f scalar(__hj_o2zt)
    local B1t = strtrim("`d1t'") + " (" + strtrim("`o1t'") + ")"
    local B2t = strtrim("`d2t'") + " (" + strtrim("`o2t'") + ")"
    local d1z : display `tvfmt' scalar(__hj_d1za)
    local d2z : display `tvfmt' scalar(__hj_d2za)
    local o1z : display %4.0f scalar(__hj_o1za)
    local o2z : display %4.0f scalar(__hj_o2za)
    local B1z = strtrim("`d1z'") + " (" + strtrim("`o1z'") + ")"
    local B2z = strtrim("`d2z'") + " (" + strtrim("`o2z'") + ")"

    di as text "H0: no cointegration."
    if `havecv' {
        di as text "{hline 71}"
        di as text %-6s "Test" %12s "Statistic" %13s "Break 1" %13s "Break 2" %9s "1%" %9s "5%" %9s "10%"
        di as text "{hline 71}"
        di as text %-6s "ADF*" as result %12.6f scalar(__hj_adf) %13s "`B1a'" %13s "`B2a'" %9.3f `cz1' %9.3f `cz2' %9.3f `cz3'
        di as text %-6s "Zt*" as result %12.6f scalar(__hj_zt) %13s "`B1t'" %13s "`B2t'" %9.3f `cz1' %9.3f `cz2' %9.3f `cz3'
        di as text %-6s "Za*" as result %12.6f scalar(__hj_za) %13s "`B1z'" %13s "`B2z'" %9.3f `ca1' %9.3f `ca2' %9.3f `ca3'
        di as text "{hline 71}"
        di as text "ADF* = Modified ADF test;  Zt*, Za* = Modified Phillips test."
        di as text "Critical values are taken from Hatemi-J (2008)."
    }
    else {
        di as text "{hline 44}"
        di as text %-6s "Test" %12s "Statistic" %13s "Break 1" %13s "Break 2"
        di as text "{hline 44}"
        di as text %-6s "ADF*" as result %12.6f scalar(__hj_adf) %13s "`B1a'" %13s "`B2a'"
        di as text %-6s "Zt*" as result %12.6f scalar(__hj_zt) %13s "`B1t'" %13s "`B2t'"
        di as text %-6s "Za*" as result %12.6f scalar(__hj_za) %13s "`B1z'" %13s "`B2z'"
        di as text "{hline 44}"
        di as text "ADF* = Modified ADF test;  Zt*, Za* = Modified Phillips test."
        di as text "Critical values are tabulated only for m <= 4 (Hatemi-J 2008)."
    }
    di as text "Break columns show the time-variable value and (observation number)."
    di _n

    if "`tspdlib'" == "" {
        tempname PT
        matrix `PT' = __hj_ptable
    }

    if "`reg'" != "" {
        di _n as text "Cointegrating regression at the `rblab' break (Stata {bf:regress}, OLS):"
        regress `depvar' `regvars' if `touse'
        di _n as text "To reproduce this regression directly in Stata:"
        di as text "    regress `depvar' `regvars'"
    }
    else if "`regnewey'" != "" {
        local nwlag = floor(4 * (`nobs'/100)^(2/9))
        di _n as text "Cointegrating regression at the `rblab' break (Newey-West HAC, lag = `nwlag'):"
        newey `depvar' `regvars' if `touse', lag(`nwlag')
        di _n as text "Newey-West lag selected automatically as floor(4*(T/100)^(2/9)) = `nwlag'."
        di as text "To reproduce this regression directly in Stata:"
        di as text "    newey `depvar' `regvars', lag(`nwlag')"
    }

    return scalar adf = scalar(__hj_adf)
    return scalar lag_adf = scalar(__hj_lagadf)
    return scalar tb1_adf = scalar(__hj_b1adf)
    return scalar tb2_adf = scalar(__hj_b2adf)
    return scalar obs1_adf = scalar(__hj_o1adf)
    return scalar obs2_adf = scalar(__hj_o2adf)
    return scalar date1_adf = scalar(__hj_d1adf)
    return scalar date2_adf = scalar(__hj_d2adf)
    return scalar zt = scalar(__hj_zt)
    return scalar tb1_zt = scalar(__hj_b1zt)
    return scalar tb2_zt = scalar(__hj_b2zt)
    return scalar obs1_zt = scalar(__hj_o1zt)
    return scalar obs2_zt = scalar(__hj_o2zt)
    return scalar date1_zt = scalar(__hj_d1zt)
    return scalar date2_zt = scalar(__hj_d2zt)
    return scalar za = scalar(__hj_za)
    return scalar tb1_za = scalar(__hj_b1za)
    return scalar tb2_za = scalar(__hj_b2za)
    return scalar obs1_za = scalar(__hj_o1za)
    return scalar obs2_za = scalar(__hj_o2za)
    return scalar date1_za = scalar(__hj_d1za)
    return scalar date2_za = scalar(__hj_d2za)
    return scalar N = `nobs'
    return scalar m = `k'
    if `choice' == 6 return scalar bgp = scalar(__hj_bgp)
    if "`tspdlib'" == "" {
        return scalar r2 = scalar(__hj_r2)
        return scalar r2_a = scalar(__hj_ar2)
        return scalar rmse = scalar(__hj_rmse)
        return scalar rss = scalar(__hj_ssr)
        return scalar mss = scalar(__hj_ssm)
        return scalar F = scalar(__hj_F)
        return scalar df_m = scalar(__hj_dfm)
        return scalar df_r = scalar(__hj_dfr)
        return matrix ptable = `PT'
    }

    capture scalar drop __hj_adf __hj_lagadf __hj_b1adf __hj_b2adf __hj_o1adf __hj_o2adf __hj_d1adf __hj_d2adf
    capture scalar drop __hj_zt __hj_b1zt __hj_b2zt __hj_o1zt __hj_o2zt __hj_d1zt __hj_d2zt
    capture scalar drop __hj_za __hj_b1za __hj_b2za __hj_o1za __hj_o2za __hj_d1za __hj_d2za
    capture scalar drop __hj_kp __hj_ssr __hj_ssm __hj_sst __hj_dfm __hj_dfr __hj_r2 __hj_ar2 __hj_rmse __hj_F
    capture scalar drop __hj_bgwarn __hj_bgp
    capture matrix drop __hj_ptable
end


version 14.0
mata:
mata set matastrict off

// ----- struct for OLS results (GAUSS estimate) -----
struct hjols {
    real colvector b
    real colvector e
    real scalar    sig2
    real colvector se
}

// ----- estimate(y, X): b=invpd(moment(X,0))*(X'y); e=y-Xb -----
struct hjols scalar hatemij_estimate(real colvector y, real matrix X)
{
    struct hjols scalar r
    real matrix XtX, m
    XtX  = X' * X
    m    = cholinv(XtX)
    r.b  = m * (X' * y)
    r.e  = y - X * r.b
    r.sig2 = (r.e' * r.e) / (rows(y) - cols(X))
    r.se = sqrt(diagonal(m) :* r.sig2)
    return(r)
}

// ----- minindc on a column vector: 1-based index of FIRST minimum -----
real scalar hatemij_minindc(real colvector v)
{
    real scalar i, mi, mv
    mv = v[1]
    mi = 1
    for (i = 2; i <= rows(v); i++) {
        if (v[i] < mv) {
            mv = v[i]
            mi = i
        }
    }
    return(mi)
}

// ----- Breusch-Godfrey LM test for serial correlation of order L -----
// uhat are the residuals of a regression on Z (no constant). Lagged residuals
// with undefined index are set to zero (the nomiss0 convention), so the full
// sample is used. Returns the p-value of LM = n * R2 ~ chi2(L) under H0 of no
// autocorrelation, where R2 is from regressing uhat on [Z, lagged uhat].
real scalar hatemij_bgodfrey(real colvector uhat, real matrix Z, real scalar L)
{
    real scalar    n, j, i, lm
    real matrix    R, ZA
    real colvector fitv

    n = rows(uhat)
    if (n <= L) return(1)
    R = J(n, L, 0)
    j = 1
    while (j <= L) {
        i = j + 1
        while (i <= n) {
            R[i, j] = uhat[i - j]
            i = i + 1
        }
        j = j + 1
    }
    ZA = Z , R
    fitv = ZA * (invsym(ZA' * ZA) * (ZA' * uhat))
    if ((uhat' * uhat) <= 0) return(1)
    lm = n * (fitv' * fitv) / (uhat' * uhat)
    if (lm < 0) lm = 0
    return(chi2tail(L, lm))
}

// ----- adf(y, X, kmax, choice) -> (tau, lag, bgwarn) ; lag = number of lags (GAUSS lag-1) -----
real rowvector hatemij_adf(real colvector y, real matrix X, real scalar kmax, real scalar choice, real scalar bglags)
{
    struct hjols scalar r0, rr
    real colvector e, de, yde, temp1, temp2, uhat
    real matrix    xe
    real scalar    N, k, n1, j, ic, lag, tstat
    real scalar    Kprev, found, bgksel, minp, L, pval, bgwarn, minpsel

    r0 = hatemij_estimate(y, X)
    e  = r0.e
    N  = rows(y)
    de = e[|2 \ N|] - e[|1 \ (N - 1)|]

    if (choice == 6) {
        Kprev   = kmax
        found   = 0
        bgksel  = 0
        bgwarn  = 0
        minpsel = 1
        k = kmax
        while (k >= 0) {
            yde = de[|(1 + k) \ (N - 1)|]
            xe  = e[|(k + 1) \ (N - 1)|]
            j = 1
            while (j <= k) {
                xe = xe , de[|(k + 1 - j) \ (N - 1 - j)|]
                j = j + 1
            }
            rr   = hatemij_estimate(yde, xe)
            uhat = rr.e
            minp = 1
            L = 1
            while (L <= bglags) {
                pval = hatemij_bgodfrey(uhat, xe, L)
                if (pval < minp) minp = pval
                L = L + 1
            }
            if (minp < 0.05) {
                bgksel = Kprev
                if (k == kmax) {
                    bgwarn  = 1
                    minpsel = minp
                }
                found = 1
                break
            }
            else {
                Kprev   = k
                minpsel = minp
            }
            k = k - 1
        }
        if (found == 0) bgksel = 0
        yde = de[|(1 + bgksel) \ (N - 1)|]
        xe  = e[|(bgksel + 1) \ (N - 1)|]
        j = 1
        while (j <= bgksel) {
            xe = xe , de[|(bgksel + 1 - j) \ (N - 1 - j)|]
            j = j + 1
        }
        rr = hatemij_estimate(yde, xe)
        tstat = rr.b[1] / rr.se[1]
        return((tstat, bgksel, bgwarn, minpsel))
    }

    temp1 = J(kmax + 1, 1, 0)
    temp2 = J(kmax + 1, 1, 0)
    ic = 0
    k  = kmax
    while (k >= 0) {
        yde = de[|(1 + k) \ (N - 1)|]
        n1  = rows(yde)
        xe  = e[|(k + 1) \ (N - 1)|]
        j = 1
        while (j <= k) {
            xe = xe , de[|(k + 1 - j) \ (N - 1 - j)|]
            j = j + 1
        }
        rr = hatemij_estimate(yde, xe)

        if (choice == 1) {
            temp1[k + 1] = -1000
            temp2[k + 1] = rr.b[1] / rr.se[1]
            break
        }
        else if (choice == 2) {
            ic = ln((rr.e' * rr.e) / n1) + 2 * (k + 2) / n1
        }
        else if (choice == 3) {
            ic = ln((rr.e' * rr.e) / n1) + (k + 2) * ln(n1) / n1
        }
        else if (choice == 4) {
            if (abs(rr.b[k + 1] / rr.se[k + 1]) >= 1.96 | k == 0) {
                temp1[k + 1] = -1000
                temp2[k + 1] = rr.b[1] / rr.se[1]
                break
            }
        }
        else if (choice == 5) {
            if (abs(rr.b[k + 1] / rr.se[k + 1]) >= 1.645 | k == 0) {
                temp1[k + 1] = -1000
                temp2[k + 1] = rr.b[1] / rr.se[1]
                break
            }
        }
        temp1[k + 1] = ic
        temp2[k + 1] = rr.b[1] / rr.se[1]
        k = k - 1
    }

    lag   = hatemij_minindc(temp1)
    tstat = temp2[lag]
    return((tstat, lag - 1, 0, .))
}

// ----- phillips(y, X) -> (za, zt) -----
real rowvector hatemij_phillips(real colvector y, real matrix X, real scalar kern, real scalar bwluser)
{
    struct hjols scalar r0
    real colvector e, e1, e2, ue, u1, u2, uu
    real scalar    N, be, nu, bu, su, a2, a1, bw, m, j, lemda, gama, c, w, p, za, sigma2, s, zt

    r0 = hatemij_estimate(y, X)
    e  = r0.e
    N  = rows(y)

    e1 = e[|1 \ (N - 1)|]
    e2 = e[|2 \ N|]
    be = (e1' * e2) / (e1' * e1)
    ue = e2 - e1 * be
    nu = rows(ue)

    if (kern == 0) {
        lemda = 0
    }
    else {
        u1 = ue[|1 \ (nu - 1)|]
        u2 = ue[|2 \ nu|]
        bu = (u1' * u2) / (u1' * u1)
        uu = u2 - u1 * bu
        su = (uu' * uu) / rows(uu)
        if (bwluser >= 0) {
            bw = bwluser
        }
        else if (kern == 2) {
            a2 = (4 * bu^2 * su / (1 - bu)^8) / (su / (1 - bu)^4)
            bw = 1.3221 * ((a2 * nu)^0.2)
        }
        else {
            a1 = 4 * bu^2 / ((1 - bu)^2 * (1 + bu)^2)
            bw = 1.1447 * ((a1 * nu)^(1 / 3))
        }
        m = bw
        j = 1
        lemda = 0
        while (j <= m) {
            gama = (ue[|1 \ (nu - j)|]' * ue[|(j + 1) \ nu|]) / nu
            if (kern == 2) {
                c = j / m
                w = (75 / (6 * pi() * c)^2) * (sin(1.2 * pi() * c) / (1.2 * pi() * c) - cos(1.2 * pi() * c))
            }
            else {
                w = 1 - j / (m + 1)
            }
            lemda = lemda + w * gama
            j = j + 1
        }
    }

    p      = sum(e1 :* e2 :- lemda) / sum(e1 :^ 2)
    za     = N * (p - 1)
    sigma2 = 2 * lemda + (ue' * ue) / nu
    s      = sigma2 / (e1' * e1)
    zt     = (p - 1) / sqrt(s)
    return((za, zt))
}

// ----- TSPDLIB long-run variance on residual e (kern 1=bartlett, 2=qs), bandwidth l -----
real scalar hatemij_tsp_lrv(real colvector e, real scalar l, real scalar kern)
{
    real scalar T, lrv, bw, w, x1, x2
    T = rows(e)
    lrv = (e' * e) / T
    bw = 1
    while (bw <= l) {
        if (kern == 1) {
            w = 1 - bw / (l + 1)
        }
        else {
            x1 = bw / l
            x2 = 6 * pi() * x1 / 5
            w = (25 / (12 * (pi() * x1)^2)) * (sin(x2) / x2 - cos(x2))
        }
        lrv = lrv + 2 * (e[|1 \ (T - bw)|]' * e[|(1 + bw) \ T|]) * w / T
        bw = bw + 1
    }
    return(lrv)
}

// ----- TSPDLIB pp(e, model=0, varm) on residual series e -> (Za, Zt) -----
// kern: 0 = iid, 1 = Bartlett, 2 = quadratic spectral ; l = bandwidth
real rowvector hatemij_tsp_pp(real colvector e, real scalar kern, real scalar l)
{
    real colvector dy, ly, resid
    real scalar    N, t, b, ssr, s2, se1, g0, lrv, tau, Zt, lam, mbaryy, Za
    N  = rows(e)
    dy = e[|2 \ N|] - e[|1 \ (N - 1)|]
    ly = e[|1 \ (N - 1)|]
    b  = (ly' * dy) / (ly' * ly)
    resid = dy - ly * b
    t   = rows(resid)
    ssr = resid' * resid
    s2  = ssr / (t - 1)
    se1 = sqrt(s2 / (ly' * ly))
    g0  = (t - 1) * s2 / t
    if (kern == 0) {
        lrv = ssr / t
    }
    else {
        lrv = hatemij_tsp_lrv(resid, l, kern)
    }
    tau = b / se1
    Zt  = tau * sqrt(g0 / lrv) - t * (lrv - g0) * se1 / (2 * sqrt(lrv) * sqrt(s2))
    lam = 0.5 * (lrv - g0)
    mbaryy = (t * se1 / sqrt(s2))^2
    Za  = t * b - lam * mbaryy
    return((Za, Zt))
}

// ----- TSPDLIB adf(e, model=0, pmax, ic) on residual series e -> (tau, lag) -----
// ic: 0 = fixed (kmax lags), 1 = Akaike, 2 = Schwarz, 3 = t-stat (general to specific)
real rowvector hatemij_tsp_adf(real colvector e, real scalar pmax, real scalar ic)
{
    real colvector dvec, lvec, dep, bb, res, se, aicp, sicp, tstatp, taup
    real matrix    xm, mm
    real scalar    N, p, k, nn, LL, lag, j
    N = rows(e)
    dvec = J(N, 1, .)
    lvec = J(N, 1, .)
    for (j = 2; j <= N; j++) {
        dvec[j] = e[j] - e[j - 1]
        lvec[j] = e[j - 1]
    }
    aicp   = J(pmax + 1, 1, .)
    sicp   = J(pmax + 1, 1, .)
    tstatp = J(pmax + 1, 1, .)
    taup   = J(pmax + 1, 1, .)
    p = 0
    while (p <= pmax) {
        dep = dvec[|(p + 2) \ N|]
        xm  = lvec[|(p + 2) \ N|]
        if (p > 0) {
            for (j = 1; j <= p; j++) {
                xm = xm , dvec[|(p + 2 - j) \ (N - j)|]
            }
        }
        mm  = luinv(quadcross(xm, xm))
        bb  = mm * quadcross(xm, dep)
        res = dep - xm * bb
        nn  = rows(dep)
        k   = cols(xm)
        se  = sqrt(diagonal(mm) * ((res' * res) / (nn - k)))
        taup[p + 1]   = bb[1] / se[1]
        LL = -nn / 2 * (1 + ln(2 * pi()) + ln((res' * res) / nn))
        aicp[p + 1]   = (2 * k - 2 * LL) / nn
        sicp[p + 1]   = (k * ln(nn) - 2 * LL) / nn
        tstatp[p + 1] = abs(bb[k] / se[k])
        p = p + 1
    }
    if (ic == 0) {
        lag = pmax + 1
    }
    else if (ic == 1) {
        lag = hatemij_minindc(aicp)
    }
    else if (ic == 2) {
        lag = hatemij_minindc(sicp)
    }
    else {
        lag = 1
        j = pmax + 1
        while (j >= 1) {
            if (abs(tstatp[j]) > 1.645) {
                lag = j
                j = 0
            }
            else {
                j = j - 1
            }
        }
    }
    return((taup[lag], lag - 1))
}

// ----- build regressor matrix for a given (model, dummies) -----
real matrix hatemij_buildX(real scalar model, real scalar n, real matrix X, real colvector d1, real colvector d2)
{
    real matrix X1
    if (model == 4) {
        X1 = J(n, 1, 1), d1, d2, X, (d1 :* X), (d2 :* X)
    }
    else if (model == 3) {
        X1 = J(n, 1, 1), d1, d2, (1::n), X
    }
    else {
        X1 = J(n, 1, 1), d1, d2, X
    }
    return(X1)
}

// ----- global minimum with minc/minindc semantics: first-row min per col, first-col global -----
real rowvector hatemij_gmin(real matrix M)
{
    real scalar R, C, r, c, cm, cr, gm, gr, gc
    R = rows(M)
    C = cols(M)
    gm = .
    gr = 0
    gc = 0
    for (c = 1; c <= C; c++) {
        cm = .
        cr = 0
        for (r = 1; r <= R; r++) {
            if (M[r, c] < cm) {
                cm = M[r, c]
                cr = r
            }
        }
        if (cm < gm) {
            gm = cm
            gc = c
            gr = cr
        }
    }
    return((gm, gr, gc))
}

// ----- main driver (mirrors coint2b) -----
void hatemij_main(string scalar yvar, string scalar xvars, string scalar tvar, real scalar model, real scalar choice, real scalar kmax, real scalar kern, real scalar bwluser, real scalar trimm, real scalar bglags)
{
    real colvector y, d1, d2, tv
    real matrix    X, X1, T1, T2, T3, T4, TW, TP, PT
    real scalar    n, begin, final1, final2, R, C, t1, t2, rr, cc
    real rowvector ares, pres, ag, ztg, zag
    real scalar    adf_stat, adf_lag, b1adf, b2adf
    real scalar    zt_stat, b1zt, b2zt, za_stat, b1za, b2za
    real scalar    db1, db2
    real scalar    o1adf, o2adf, o1zt, o2zt, o1za, o2za
    real scalar    kp, ssr, ybar, sst, ssm, dfm, dfr, r2, ar2, rmse, fstat
    struct hjols scalar fit

    y = st_data(., yvar)
    X = st_data(., tokens(xvars))
    tv = st_data(., tvar)
    n = rows(y)

    begin  = round(trimm * n)
    final1 = round((1 - 2 * trimm) * n)
    final2 = round((1 - trimm) * n)

    R = final1 - begin + 1
    C = final2 - begin * 2 + 1

    T1 = J(R, C, 999)
    T2 = J(R, C, 999)
    T3 = J(R, C, 999)
    T4 = J(R, C, 999)
    TW = J(R, C, 0)
    TP = J(R, C, .)

    t1 = begin
    while (t1 <= final1) {
        t2 = t1 + begin
        while (t2 <= final2) {
            d1 = J(t1, 1, 0) \ J(n - t1, 1, 1)
            d2 = J(t2, 1, 0) \ J(n - t2, 1, 1)
            X1 = hatemij_buildX(model, n, X, d1, d2)
            rr = t1 - begin + 1
            cc = t2 - begin * 2 + 1
            ares = hatemij_adf(y, X1, kmax, choice, bglags)
            T1[rr, cc] = ares[1]
            T2[rr, cc] = ares[2]
            TW[rr, cc] = ares[3]
            TP[rr, cc] = ares[4]
            pres = hatemij_phillips(y, X1, kern, bwluser)
            T3[rr, cc] = pres[1]
            T4[rr, cc] = pres[2]
            t2 = t2 + 1
        }
        t1 = t1 + 1
    }

    // Break observation mapping. The grid stores results at row rr = t1-begin+1
    // and column cc = t2-begin*2+1, so the true break dates are
    //   t1 = rr + begin - 1   and   t2 = cc + begin*2 - 1.
    // The first break uses + begin - 1; the second break uses + begin*2 - 1
    // to recover the actual t2 (rather than the column index).

    // ADF*
    ag = hatemij_gmin(T1)
    adf_stat = ag[1]
    adf_lag  = T2[ag[2], ag[3]]
    o1adf = ag[2] + begin - 1
    o2adf = ag[3] + begin * 2 - 1
    b1adf = o1adf / n
    b2adf = o2adf / n
    st_numscalar("__hj_bgwarn", TW[ag[2], ag[3]])
    st_numscalar("__hj_bgp",    TP[ag[2], ag[3]])

    // Za*
    zag = hatemij_gmin(T3)
    za_stat = zag[1]
    o1za = zag[2] + begin - 1
    o2za = zag[3] + begin * 2 - 1
    b1za = o1za / n
    b2za = o2za / n

    // Zt*
    ztg = hatemij_gmin(T4)
    zt_stat = ztg[1]
    o1zt = ztg[2] + begin - 1
    o2zt = ztg[3] + begin * 2 - 1
    b1zt = o1zt / n
    b2zt = o2zt / n

    // parameter table at the Zt* break (dummies placed at the true break dates)
    db1 = ztg[2] + begin - 1
    db2 = ztg[3] + begin * 2 - 1
    d1 = J(db1, 1, 0) \ J(n - db1, 1, 1)
    d2 = J(db2, 1, 0) \ J(n - db2, 1, 1)
    X1 = hatemij_buildX(model, n, X, d1, d2)
    fit = hatemij_estimate(y, X1)
    PT = fit.b , fit.se , (fit.b :/ fit.se)

    // OLS fit statistics for the cointegrating regression (at the Zt* break)
    kp   = cols(X1)
    ssr  = fit.e' * fit.e
    ybar = sum(y) / n
    sst  = (y :- ybar)' * (y :- ybar)
    ssm  = sst - ssr
    dfm  = kp - 1
    dfr  = n - kp
    r2   = 1 - ssr / sst
    ar2  = 1 - (ssr / dfr) / (sst / (n - 1))
    rmse = sqrt(ssr / dfr)
    fstat = (ssm / dfm) / (ssr / dfr)

    st_numscalar("__hj_kp",   kp)
    st_numscalar("__hj_ssr",  ssr)
    st_numscalar("__hj_ssm",  ssm)
    st_numscalar("__hj_sst",  sst)
    st_numscalar("__hj_dfm",  dfm)
    st_numscalar("__hj_dfr",  dfr)
    st_numscalar("__hj_r2",   r2)
    st_numscalar("__hj_ar2",  ar2)
    st_numscalar("__hj_rmse", rmse)
    st_numscalar("__hj_F",    fstat)

    st_numscalar("__hj_adf",    adf_stat)
    st_numscalar("__hj_lagadf", adf_lag)
    st_numscalar("__hj_b1adf",  b1adf)
    st_numscalar("__hj_b2adf",  b2adf)
    st_numscalar("__hj_o1adf",  o1adf)
    st_numscalar("__hj_o2adf",  o2adf)
    st_numscalar("__hj_d1adf",  tv[o1adf])
    st_numscalar("__hj_d2adf",  tv[o2adf])
    st_numscalar("__hj_zt",     zt_stat)
    st_numscalar("__hj_b1zt",   b1zt)
    st_numscalar("__hj_b2zt",   b2zt)
    st_numscalar("__hj_o1zt",   o1zt)
    st_numscalar("__hj_o2zt",   o2zt)
    st_numscalar("__hj_d1zt",   tv[o1zt])
    st_numscalar("__hj_d2zt",   tv[o2zt])
    st_numscalar("__hj_za",     za_stat)
    st_numscalar("__hj_b1za",   b1za)
    st_numscalar("__hj_b2za",   b2za)
    st_numscalar("__hj_o1za",   o1za)
    st_numscalar("__hj_o2za",   o2za)
    st_numscalar("__hj_d1za",   tv[o1za])
    st_numscalar("__hj_d2za",   tv[o2za])
    st_matrix("__hj_ptable",    PT)
}

// ----- TSPDLIB driver (mirrors coint_hatemiJ): adf + pp on cointegrating residuals -----
// Reports the first break as t1 and the second break as the grid column index, as the
// TSPDLIB routine does (its post-loop reassignment of the second break). No parameter table.
void hatemij_tsp_main(string scalar yvar, string scalar xvars, string scalar tvar, real scalar model, real scalar choice, real scalar kmax, real scalar kern, real scalar bwluser, real scalar trimm)
{
    real colvector y, d1, d2, tv, ec
    real matrix    X, X1, T1, T2, T3, T4
    real scalar    n, begin, final1, final2, R, C, t1, t2, rr, cc, ic, lbw
    real rowvector ares, pres, ag, ztg, zag
    real scalar    adf_stat, adf_lag, o1adf, o2adf, o1zt, o2zt, o1za, o2za

    y  = st_data(., yvar)
    X  = st_data(., tokens(xvars))
    tv = st_data(., tvar)
    n  = rows(y)

    // TSPDLIB pp bandwidth: user value if set, else round(4*(T/100)^(2/9))
    lbw = (bwluser >= 0 ? bwluser : round(4 * (n / 100)^(2 / 9)))

    begin  = round(trimm * n)
    final1 = round((1 - 2 * trimm) * n)
    final2 = round((1 - trimm) * n)
    R = final1 - begin + 1
    C = final2 - begin * 2 + 1
    T1 = J(R, C, 999)
    T2 = J(R, C, 999)
    T3 = J(R, C, 999)
    T4 = J(R, C, 999)

    // map hatemij choice to TSPDLIB ic: 1 fixed -> 0 ; 2 AIC -> 1 ; 3 BIC -> 2 ; 4 downward-t -> 3
    ic = (choice == 1 ? 0 : choice - 1)

    t1 = begin
    while (t1 <= final1) {
        t2 = t1 + begin
        while (t2 <= final2) {
            d1 = J(t1, 1, 0) \ J(n - t1, 1, 1)
            d2 = J(t2, 1, 0) \ J(n - t2, 1, 1)
            X1 = hatemij_buildX(model, n, X, d1, d2)
            ec = y - X1 * (luinv(quadcross(X1, X1)) * quadcross(X1, y))
            rr = t1 - begin + 1
            cc = t2 - begin * 2 + 1
            ares = hatemij_tsp_adf(ec, kmax, ic)
            T1[rr, cc] = ares[1]
            T2[rr, cc] = ares[2]
            pres = hatemij_tsp_pp(ec, kern, lbw)
            T3[rr, cc] = pres[1]
            T4[rr, cc] = pres[2]
            t2 = t2 + 1
        }
        t1 = t1 + 1
    }

    // first break = t1 (row); second break = grid column index (TSPDLIB reassignment)
    ag = hatemij_gmin(T1)
    adf_stat = ag[1]
    adf_lag  = T2[ag[2], ag[3]]
    o1adf = ag[2] + begin - 1
    o2adf = ag[3] + begin - 1

    zag = hatemij_gmin(T3)
    o1za = zag[2] + begin - 1
    o2za = zag[3] + begin - 1

    ztg = hatemij_gmin(T4)
    o1zt = ztg[2] + begin - 1
    o2zt = ztg[3] + begin - 1

    st_numscalar("__hj_adf",    adf_stat)
    st_numscalar("__hj_lagadf", adf_lag)
    st_numscalar("__hj_b1adf",  o1adf / n)
    st_numscalar("__hj_b2adf",  o2adf / n)
    st_numscalar("__hj_o1adf",  o1adf)
    st_numscalar("__hj_o2adf",  o2adf)
    st_numscalar("__hj_d1adf",  tv[o1adf])
    st_numscalar("__hj_d2adf",  tv[o2adf])
    st_numscalar("__hj_zt",     ztg[1])
    st_numscalar("__hj_b1zt",   o1zt / n)
    st_numscalar("__hj_b2zt",   o2zt / n)
    st_numscalar("__hj_o1zt",   o1zt)
    st_numscalar("__hj_o2zt",   o2zt)
    st_numscalar("__hj_d1zt",   tv[o1zt])
    st_numscalar("__hj_d2zt",   tv[o2zt])
    st_numscalar("__hj_za",     zag[1])
    st_numscalar("__hj_b1za",   o1za / n)
    st_numscalar("__hj_b2za",   o2za / n)
    st_numscalar("__hj_o1za",   o1za)
    st_numscalar("__hj_o2za",   o2za)
    st_numscalar("__hj_d1za",   tv[o1za])
    st_numscalar("__hj_d2za",   tv[o2za])
}

end
