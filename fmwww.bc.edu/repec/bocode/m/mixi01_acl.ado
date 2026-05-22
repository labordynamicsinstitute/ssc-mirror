*! mixi01_acl 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
* mixi01_acl.ado — Augmented Cointegrating Linear (ACL) regression
* Peng & Dong (2021, SSRN-3943779)
* Plain-OLS for y_t = beta'x_t + alpha'z_t + e_t with x I(1), z I(0).
* Coefficients are asymptotically normal (alpha at sqrt(T)-rate, beta at T-rate
* mixed-normal). Self-normalized Wald tests follow Theorem 2.

capture program drop mixi01_acl
program define mixi01_acl, eclass sortpreserve
    version 17.0

    syntax varlist(min=2 ts fv) [if] [in], [           ///
        I1vars(varlist ts fv)                           ///
        I0vars(varlist ts fv)                           ///
        I1(varlist ts fv)                               ///
        I0(varlist ts fv)                               ///
        auto                                            ///
        noCONStant                                      ///
        TRend(integer 0)                                ///
        COINTtest                                       ///
        ADFlags(integer 4)                              ///
        Level(real 95)                                  ///
    ]

    * Aliases: i1()/i0() are accepted as shorthand for i1vars()/i0vars()
    if "`i1vars'" == "" & "`i1'" != "" local i1vars `i1'
    if "`i0vars'" == "" & "`i0'" != "" local i0vars `i0'

    if `trend' < 0 | `trend' > 2 {
        di as error "trend() must be 0, 1, or 2"
        exit 198
    }

    * ── Mark sample ────────────────────────────────────────────────
    marksample touse
    gettoken depvar indepvars : varlist
    if "`indepvars'" == "" {
        di as error "at least one regressor required"
        exit 198
    }

    markout `touse' `depvar' `indepvars'
    if "`i1vars'" != "" markout `touse' `i1vars'
    if "`i0vars'" != "" markout `touse' `i0vars'

    qui count if `touse'
    local nobs = r(N)
    if `nobs' < 10 {
        di as error "insufficient observations (need at least 10)"
        exit 2001
    }

    qui tsset
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as error "mixi01_acl is for single time-series data only"
        exit 198
    }

    * ── Classify regressors ───────────────────────────────────────
    local allregs `indepvars'

    if "`auto'" != "" {
        local i1vars ""
        local i0vars ""
        foreach v of local allregs {
            qui capture dfuller `v' if `touse', lags(4)
            if _rc == 0 {
                if r(p) < 0.05 {
                    local i0vars `i0vars' `v'
                }
                else {
                    local i1vars `i1vars' `v'
                }
            }
            else {
                local i1vars `i1vars' `v'
            }
        }
    }

    if "`i1vars'" == "" & "`i0vars'" == "" {
        local i1vars `allregs'
    }

    foreach v of local allregs {
        local in1 : list v in i1vars
        local in0 : list v in i0vars
        if `in1' == 0 & `in0' == 0 {
            local i1vars `i1vars' `v'
        }
    }

    local n1 : word count `i1vars'
    local n0 : word count `i0vars'

    * ── Mata estimation ───────────────────────────────────────────
    tempname b V XX r2 r2a rmse sigma2 iorder Sxx Szz
    tempvar resid_var
    qui gen double `resid_var' = .

    mata: _mixi01_acl_estimate(                       ///
        "`depvar'", "`i1vars'", "`i0vars'",           ///
        "`touse'",                                     ///
        "`constant'" != "noconstant",                  ///
        `trend',                                       ///
        "`b'", "`V'", "`XX'", "`Sxx'", "`Szz'",       ///
        "`r2'", "`r2a'", "`rmse'", "`sigma2'",        ///
        "`iorder'", "`resid_var'"                      ///
    )

    * ── Column / equation names ───────────────────────────────────
    local colnames ""
    foreach v of local i1vars {
        local colnames `colnames' `v'
    }
    foreach v of local i0vars {
        local colnames `colnames' `v'
    }
    if "`constant'" != "noconstant" {
        local colnames `colnames' _cons
    }
    if `trend' >= 1 {
        local colnames `colnames' _trend
    }
    if `trend' >= 2 {
        local colnames `colnames' _trend2
    }

    tempname bmat Vmat
    matrix `bmat' = `b'
    matrix `Vmat' = `V'

    local ncols = colsof(`bmat')
    if `ncols' != `: word count `colnames'' {
        local colnames ""
        forvalues j = 1/`ncols' {
            local colnames `colnames' x`j'
        }
    }

    matrix colnames `bmat' = `colnames'
    matrix rownames `bmat' = `depvar'
    matrix colnames `Vmat' = `colnames'
    matrix rownames `Vmat' = `colnames'

    ereturn post `bmat' `Vmat', esample(`touse') obs(`nobs')

    ereturn scalar N       = `nobs'
    ereturn scalar r2      = scalar(`r2')
    ereturn scalar r2_a    = scalar(`r2a')
    ereturn scalar rmse    = scalar(`rmse')
    ereturn scalar sigma2  = scalar(`sigma2')
    ereturn scalar n_i1    = `n1'
    ereturn scalar n_i0    = `n0'
    ereturn scalar trend   = `trend'
    ereturn scalar level   = `level'

    ereturn matrix XX      = `XX'
    ereturn matrix Sxx     = `Sxx'
    ereturn matrix Szz     = `Szz'
    ereturn matrix iorder  = `iorder'

    ereturn local cmd       "mixi01_acl"
    ereturn local depvar    "`depvar'"
    ereturn local i1vars    "`i1vars'"
    ereturn local i0vars    "`i0vars'"
    ereturn local constant  "`constant'"
    ereturn local properties "b V"

    * ── Display ───────────────────────────────────────────────────
    _mixi01_acl_display, level(`level')

    * ── Optional: residual ADF test (Peng-Dong specification check) ─
    if "`cointtest'" != "" {
        _mixi01_acl_cointtest `resid_var', adflags(`adflags')
    }
end


* ═══════════════════════════════════════════════════════════════════
*  Residual ADF test — validates the ACL specification
*  Peng & Dong (2021), Section 5: stationarity of {e_t} confirms ACL
* ═══════════════════════════════════════════════════════════════════
capture program drop _mixi01_acl_cointtest
program define _mixi01_acl_cointtest, eclass
    syntax varname, [ADFlags(integer 4)]

    di ""
    di as text "{hline 65}"
    di as text "ACL specification check: ADF test on residuals"
    di as text "(Peng & Dong, 2021, Sec. 5 — residuals should be I(0))"
    di as text "{hline 65}"

    capture noisily dfuller `varlist', lags(`adflags')
    if _rc {
        di as error "  Could not run dfuller on residuals (rc = " _rc ")"
        exit 0
    }

    local adf_t   = r(Zt)
    local adf_p   = r(p)
    local adf_lag = `adflags'

    di as text "  ADF (no constant) statistic" _col(36) "= " ///
       as result %9.4f `adf_t'
    di as text "  Approx. p-value"             _col(36) "= " ///
       as result %9.4f `adf_p'
    di as text "  Augmentation lags"           _col(36) "= " ///
       as result %9.0f `adf_lag'

    if `adf_p' < 0.05 {
        di as text ""
        di as text as result "  Reject H0 of unit root in residuals" _c
        di as text " ==> ACL specification supported."
    }
    else {
        di as text ""
        di as text as error "  Fail to reject H0 of unit root in residuals" _c
        di as text " ==> ACL specification " _c
        di as error "NOT supported"
        di as text "  (residuals appear non-stationary; check regressor"
        di as text "  classification or consider FM-OLS / VECM)."
    }
    di as text "{hline 65}"

    ereturn scalar adf_resid_t = `adf_t'
    ereturn scalar adf_resid_p = `adf_p'
    ereturn scalar adf_resid_lags = `adf_lag'
end


* ═══════════════════════════════════════════════════════════════════
*  Display
* ═══════════════════════════════════════════════════════════════════
capture program drop _mixi01_acl_display
program define _mixi01_acl_display
    syntax , [Level(real 95)]

    local nobs   = e(N)
    local r2     = e(r2)
    local r2a    = e(r2_a)
    local rmse   = e(rmse)
    local sigma2 = e(sigma2)
    local n1     = e(n_i1)
    local n0     = e(n_i0)
    local depvar = e(depvar)
    local i1v    = e(i1vars)
    local i0v    = e(i0vars)

    local r2disp     : di %8.4f `r2'
    local r2adisp    : di %8.4f `r2a'
    local rmsedisp   : di %8.4f `rmse'
    local sigma2disp : di %8.4f `sigma2'

    di ""
    di as text "{hline 65}"
    di as text "Augmented Cointegrating Linear (ACL) Regression"
    di as text "(Peng & Dong, SSRN 3943779, 2021)"
    di as text "{hline 65}"
    di as text "Dep. variable"  _col(18) "= " as result "`depvar'" ///
       as text _col(40) "Number of obs" _col(56) "= " as result %8.0f `nobs'
    di as text "Integration"    _col(18) "= " as result "Mixed I(1)/I(0)" ///
       as text _col(40) "R-squared"     _col(56) "= " as result "`r2disp'"
    di as text "I(1) regressors" _col(18) "= " as result "`n1'" ///
       as text _col(40) "Adjusted R2"   _col(56) "= " as result "`r2adisp'"
    di as text "I(0) regressors" _col(18) "= " as result "`n0'" ///
       as text _col(40) "sigma^2 (1/n)" _col(56) "= " as result "`sigma2disp'"
    di as text "Estimator"      _col(18) "= " as result "Plain OLS (no FM)" ///
       as text _col(40) "RMSE"          _col(56) "= " as result "`rmsedisp'"
    di as text "{hline 65}"

    di as text _col(14) "{c |}" _col(17) "Coef." ///
       _col(27) "Std.Err." _col(39) "z" _col(46) "P>|z|" ///
       _col(54) "[" %3.0f `level' "% Conf. Int.]"
    di as text "{hline 13}{c +}{hline 51}"

    tempname bb VV
    matrix `bb' = e(b)
    matrix `VV' = e(V)
    local ncols = colsof(`bb')
    local cnames : colnames `bb'

    local alpha = (100 - `level') / 100
    local crit = invnormal(1 - `alpha'/2)

    local pos = 0
    local ki1 = `n1'
    local ki0 = `n0'

    if `ki1' > 0 {
        di as text " I(1) regressors"
        forvalues j = 1/`ki1' {
            local pos = `pos' + 1
            local vname : word `pos' of `cnames'
            local coef = `bb'[1, `pos']
            local se   = sqrt(`VV'[`pos', `pos'])
            if `se' > 0 {
                local tstat = `coef' / `se'
            }
            else {
                local tstat = .
            }
            local pval = 2 * (1 - normal(abs(`tstat')))
            local lo = `coef' - `crit' * `se'
            local hi = `coef' + `crit' * `se'
            di as text %12s abbrev("`vname'", 12) " {c |}" ///
               as result %9.4f `coef' %9.4f `se' ///
               %8.2f `tstat' %7.3f `pval' ///
               %9.4f `lo' %9.4f `hi'
        }
    }

    if `ki0' > 0 {
        di as text " I(0) regressors"
        forvalues j = 1/`ki0' {
            local pos = `pos' + 1
            local vname : word `pos' of `cnames'
            local coef = `bb'[1, `pos']
            local se   = sqrt(`VV'[`pos', `pos'])
            if `se' > 0 {
                local tstat = `coef' / `se'
            }
            else {
                local tstat = .
            }
            local pval = 2 * (1 - normal(abs(`tstat')))
            local lo = `coef' - `crit' * `se'
            local hi = `coef' + `crit' * `se'
            di as text %12s abbrev("`vname'", 12) " {c |}" ///
               as result %9.4f `coef' %9.4f `se' ///
               %8.2f `tstat' %7.3f `pval' ///
               %9.4f `lo' %9.4f `hi'
        }
    }

    if `pos' < `ncols' {
        di as text "{hline 13}{c +}{hline 51}"
        forvalues j = `=`pos'+1'/`ncols' {
            local pos = `j'
            local vname : word `pos' of `cnames'
            local coef = `bb'[1, `pos']
            local se   = sqrt(`VV'[`pos', `pos'])
            if `se' > 0 {
                local tstat = `coef' / `se'
            }
            else {
                local tstat = .
            }
            local pval = 2 * (1 - normal(abs(`tstat')))
            local lo = `coef' - `crit' * `se'
            local hi = `coef' + `crit' * `se'
            di as text %12s abbrev("`vname'", 12) " {c |}" ///
               as result %9.4f `coef' %9.4f `se' ///
               %8.2f `tstat' %7.3f `pval' ///
               %9.4f `lo' %9.4f `hi'
        }
    }

    di as text "{hline 65}"
    di as text "Note: V = sigma^2 (X'X)^-1; self-normalized (Peng-Dong Thm 2)."
end


* ═══════════════════════════════════════════════════════════════════
*  Mata estimation engine
* ═══════════════════════════════════════════════════════════════════
mata:
mata set matastrict on

void _mixi01_acl_estimate(
    string scalar depvar,
    string scalar i1vars,
    string scalar i0vars,
    string scalar touse,
    real scalar   hascons,
    real scalar   trend,
    string scalar bname,
    string scalar Vname,
    string scalar XXname,
    string scalar Sxxname,
    string scalar Szzname,
    string scalar r2name,
    string scalar r2aname,
    string scalar rmsename,
    string scalar sigma2name,
    string scalar iordname,
    string scalar residname
)
{
    real colvector y
    real matrix X1, X2, Z, X
    real scalar T, m1, m2, kdet, m, j

    y = st_data(., depvar, touse)
    T = rows(y)

    // I(1) regressors -> X2
    if (strlen(strtrim(i1vars)) > 0) {
        X2 = st_data(., i1vars, touse)
        m2 = cols(X2)
    }
    else {
        X2 = J(T, 0, .)
        m2 = 0
    }

    // I(0) regressors -> X1
    if (strlen(strtrim(i0vars)) > 0) {
        X1 = st_data(., i0vars, touse)
        m1 = cols(X1)
    }
    else {
        X1 = J(T, 0, .)
        m1 = 0
    }

    // Deterministic terms
    Z = J(T, 0, .)
    kdet = 0
    if (hascons) {
        Z = Z, J(T, 1, 1)
        kdet++
    }
    if (trend >= 1) {
        Z = Z, (1::T)
        kdet++
    }
    if (trend >= 2) {
        Z = Z, ((1::T):^2)
        kdet++
    }

    // Full design: X = [X2 (I(1)), X1 (I(0)), Z (det)]
    X = J(T, 0, .)
    if (m2 > 0)   X = X, X2
    if (m1 > 0)   X = X, X1
    if (kdet > 0) X = X, Z

    m = cols(X)

    if (m >= T) {
        errprintf("ACL: more parameters than observations\n")
        exit(error(2001))
    }

    // OLS
    real matrix XX, XXinv
    real colvector b_hat, resid
    real scalar sse, sigma2, ybar, sst, r2_val, r2a_val, rmse_val

    XX    = cross(X, X)
    XXinv = invsym(XX)
    b_hat = XXinv * cross(X, y)
    resid = y - X * b_hat

    sse = (cross(resid, resid))[1, 1]

    // Peng-Dong Corollary 1: sigma^2 = (1/n) sum e_t^2
    sigma2 = sse / T

    ybar = mean(y)
    sst  = (cross(y :- ybar, y :- ybar))[1, 1]
    if (sst > 0) {
        r2_val = 1 - sse / sst
    }
    else {
        r2_val = 0
    }
    r2a_val = 1 - (1 - r2_val) * (T - 1) / (T - m)
    rmse_val = sqrt(sigma2)

    // Variance: V = sigma^2 (X'X)^{-1}
    real matrix V
    V = sigma2 * XXinv
    V = (V + V') / 2

    // Self-normalisation blocks: Sxx = sum x_t x_t', Szz = sum z_t z_t'
    real matrix Sxx, Szz
    if (m2 > 0) {
        Sxx = cross(X2, X2)
    }
    else {
        Sxx = J(0, 0, .)
    }
    if (m1 > 0) {
        Szz = cross(X1, X1)
    }
    else {
        Szz = J(0, 0, .)
    }

    // Integration-order indicator
    real matrix iord
    iord = J(1, m, 0)
    if (m2 > 0) {
        for (j = 1; j <= m2; j++) {
            iord[1, j] = 1
        }
    }

    // Store
    st_matrix(bname, b_hat')
    st_matrix(Vname, V)
    st_matrix(XXname, XX)
    if (m2 > 0) st_matrix(Sxxname, Sxx)
    else        st_matrix(Sxxname, J(1, 1, .))
    if (m1 > 0) st_matrix(Szzname, Szz)
    else        st_matrix(Szzname, J(1, 1, .))
    st_numscalar(r2name, r2_val)
    st_numscalar(r2aname, r2a_val)
    st_numscalar(rmsename, rmse_val)
    st_numscalar(sigma2name, sigma2)
    st_matrix(iordname, iord)

    // Write residuals back to the Stata tempvar (touse-filtered rows)
    if (strlen(residname) > 0) {
        st_store(., residname, touse, resid)
    }
}

end
