*! mixi01_fmols 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
* mixi01_fmols.ado — FM-OLS with mixed I(1)/I(0) regressors
* Phillips (1995, Econometrica, Vol. 63, pp. 1023-1078)
* Fully Modified Least Squares for time series with I(1) and I(0) regressors

capture program drop mixi01_fmols
program define mixi01_fmols, eclass sortpreserve
    version 17.0

    syntax varlist(min=2 ts fv) [if] [in], [           ///
        I1vars(varlist ts fv)                           ///
        I0vars(varlist ts fv)                           ///
        auto                                            ///
        noCONStant                                      ///
        TRend(integer 0)                                ///
        KERnel(string)                                  ///
        BW(real 0)                                      ///
        BMETh(string)                                   ///
        VLAG(integer 0)                                 ///
        Level(real 95)                                  ///
    ]

    * ── 0.  Propre error checking ──────────────────────────────────
    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'","bartlett","parzen","qs","tukey") {
        di as error "kernel() must be bartlett, parzen, qs, or tukey"
        exit 198
    }
    if "`bmeth'" == "" local bmeth "andrews"
    local bmeth = lower("`bmeth'")
    if !inlist("`bmeth'","andrews","neweywest") {
        di as error "bmeth() must be andrews or neweywest"
        exit 198
    }
    if `trend' < 0 | `trend' > 2 {
        di as error "trend() must be 0, 1, or 2"
        exit 198
    }
    if "`i1vars'" != "" & "`i0vars'" != "" & "`auto'" != "" {
        di as error "cannot specify auto with both i1vars() and i0vars()"
        exit 198
    }

    * ── 1.  Mark sample ────────────────────────────────────────────
    marksample touse
    gettoken depvar indepvars : varlist
    local indepvars `indepvars'
    if "`indepvars'" == "" {
        di as error "at least one regressor required"
        exit 198
    }

    * Strip the dependent variable from i1()/i0() if the user listed it there
    local dep_in_i1 : list depvar in i1vars
    local dep_in_i0 : list depvar in i0vars
    if `dep_in_i1' {
        local i1vars : list i1vars - depvar
        di as text "  (warning: removing dependent variable {bf:`depvar'} from i1())"
    }
    if `dep_in_i0' {
        local i0vars : list i0vars - depvar
        di as text "  (warning: removing dependent variable {bf:`depvar'} from i0())"
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

    * tsset information
    qui tsset
    local timevar "`r(timevar)'"
    local panelvar "`r(panelvar)'"
    if "`panelvar'" != "" {
        di as error "mixi01_fmols is for single time-series data only"
        exit 198
    }

    * ── 2.  Classify regressors as I(0) or I(1) ───────────────────
    * Build combined lists
    local allregs `indepvars'
    local nregs : word count `allregs'

    * If auto, run ADF on each regressor
    if "`auto'" != "" {
        local i1vars ""
        local i0vars ""
        foreach v of local allregs {
            qui capture dfuller `v' if `touse', lags(4)
            if _rc == 0 {
                * Check MacKinnon p-value from dfuller
                local pval = r(p)
                if `pval' < 0.05 {
                    local i0vars `i0vars' `v'
                }
                else {
                    local i1vars `i1vars' `v'
                }
            }
            else {
                * If dfuller fails, assume I(1)
                local i1vars `i1vars' `v'
            }
        }
        if "`i1vars'" == "" & "`i0vars'" == "" {
            di as error "auto classification failed — all tests inconclusive"
            exit 198
        }
    }

    * Default: if neither auto nor explicit classification, assume all I(1)
    if "`i1vars'" == "" & "`i0vars'" == "" {
        local i1vars `allregs'
    }

    * Verify all regressors are classified
    foreach v of local allregs {
        local in1 : list v in i1vars
        local in0 : list v in i0vars
        if `in1' == 0 & `in0' == 0 {
            * Unclassified variable — assign to I(1) by default
            local i1vars `i1vars' `v'
        }
    }

    local n1 : word count `i1vars'
    local n0 : word count `i0vars'
    local m = `n1' + `n0'

    * ── 3.  Build Mata data and call estimation ───────────────────
    tempname b V Omega bw_used r2 r2a rmse lrse iorder

    mata: _mixi01_fmols_estimate(                    ///
        "`depvar'", "`i1vars'", "`i0vars'",          ///
        "`touse'",                                    ///
        "`constant'" != "noconstant",                 ///
        `trend',                                      ///
        "`kernel'",                                   ///
        `bw',                                         ///
        "`bmeth'",                                    ///
        `vlag',                                       ///
        `level',                                      ///
        "`b'", "`V'", "`Omega'", "`bw_used'",        ///
        "`r2'", "`r2a'", "`rmse'", "`lrse'",         ///
        "`iorder'"                                    ///
    )

    * ── 4.  Build coefficient names ───────────────────────────────
    local colnames ""
    * I(1) variables first
    foreach v of local i1vars {
        local colnames `colnames' `v'
    }
    * I(0) variables next
    foreach v of local i0vars {
        local colnames `colnames' `v'
    }
    * Deterministic terms
    if "`constant'" != "noconstant" {
        local colnames `colnames' _cons
    }
    if `trend' >= 1 {
        local colnames `colnames' _trend
    }
    if `trend' >= 2 {
        local colnames `colnames' _trend2
    }

    * ── 5.  Post results to e() ───────────────────────────────────
    local eqname "`depvar'"
    tempname bmat Vmat
    matrix `bmat' = `b'
    matrix `Vmat' = `V'

    local ncols = colsof(`bmat')
    if `ncols' != `:word count `colnames'' {
        * Adjust column names if mismatch (safety)
        local colnames ""
        forvalues j = 1/`ncols' {
            local colnames `colnames' x`j'
        }
    }

    matrix colnames `bmat' = `colnames'
    matrix rownames `bmat' = `eqname'
    matrix colnames `Vmat' = `colnames'
    matrix rownames `Vmat' = `colnames'

    ereturn post `bmat' `Vmat', esample(`touse') obs(`nobs')

    ereturn scalar N        = `nobs'
    ereturn scalar r2       = scalar(`r2')
    ereturn scalar r2_a     = scalar(`r2a')
    ereturn scalar rmse     = scalar(`rmse')
    ereturn scalar lrse     = scalar(`lrse')
    ereturn scalar bwidth   = scalar(`bw_used')
    ereturn scalar n_i1     = `n1'
    ereturn scalar n_i0     = `n0'
    ereturn scalar trend    = `trend'
    ereturn scalar level    = `level'

    ereturn matrix Omega    = `Omega'
    ereturn matrix iorder   = `iorder'

    ereturn local cmd       "mixi01_fmols"
    ereturn local depvar    "`depvar'"
    ereturn local i1vars    "`i1vars'"
    ereturn local i0vars    "`i0vars'"
    ereturn local kernel    "`kernel'"
    if `bw' > 0  local bmeth_disp "User"
    else         local bmeth_disp = proper("`bmeth'")
    ereturn local bmeth     "`bmeth'"
    ereturn local bmeth_disp "`bmeth_disp'"
    ereturn local constant  "`constant'"
    ereturn local properties "b V"

    * ── 6.  Display results ───────────────────────────────────────
    _mixi01_fmols_display, level(`level')

end

* ═══════════════════════════════════════════════════════════════════
* Display program
* ═══════════════════════════════════════════════════════════════════
capture program drop _mixi01_fmols_display
program define _mixi01_fmols_display
    syntax , [Level(real 95)]

    local kernel  = e(kernel)
    local bmeth   = e(bmeth)
    local bw      = e(bwidth)
    local nobs    = e(N)
    local r2      = e(r2)
    local r2a     = e(r2_a)
    local lrse    = e(lrse)
    local n1      = e(n_i1)
    local n0      = e(n_i0)
    local depvar  = e(depvar)
    local i1v     = e(i1vars)
    local i0v     = e(i0vars)

    local kerndisp = proper("`kernel'")
    if "`kernel'" == "qs" local kerndisp "Quad. Spectral"

    local bwdisp : di %6.2f `bw'
    local bwmethod "`e(bmeth_disp)'"
    if "`bwmethod'" == "" local bwmethod = proper("`bmeth'")

    local r2disp : di %8.4f `r2'
    local r2adisp : di %8.4f `r2a'
    local lrsedisp : di %8.4f `lrse'

    di ""
    di as text "{hline 65}"
    di as text "Mixed FM-OLS Regression (Phillips, Econometrica 1995)"
    di as text "{hline 65}"
    di as text "Kernel" _col(18) "= " as result "`kerndisp'" ///
       as text _col(40) "Number of obs" _col(56) "= " as result %8.0f `nobs'
    di as text "Bandwidth(`bwmethod')" _col(18) "= " as result "`bwdisp'" ///
       as text _col(40) "R-squared" _col(56) "= " as result "`r2disp'"
    di as text "Integration" _col(18) "= " as result "Mixed I(1)/I(0)" ///
       as text _col(40) "Adjusted R2" _col(56) "= " as result "`r2adisp'"

    if `n1' > 0 & `n0' > 0 {
        local convstr "O(T) / O(sqrt(T))"
    }
    else if `n1' > 0 {
        local convstr "O(T) super-cons."
    }
    else {
        local convstr "O(sqrt(T)) standard"
    }

    di as text "Convergence" _col(18) "= " as result "`convstr'" ///
       as text _col(40) "Long-run S.E." _col(56) "= " as result "`lrsedisp'"
    di as text "{hline 65}"

    * Column header
    di as text _col(14) "{c |}" _col(17) "Coef." ///
       _col(27) "Std.Err." _col(39) "t" _col(46) "P>|t|" ///
       _col(54) "[" %3.0f `level' "% Conf. Int.]"
    di as text "{hline 13}{c +}{hline 51}"

    * Get coefficient vector and VCE
    tempname bb VV
    matrix `bb' = e(b)
    matrix `VV' = e(V)
    local ncols = colsof(`bb')
    local cnames : colnames `bb'

    local alpha = (100 - `level') / 100
    local crit = invnormal(1 - `alpha'/2)

    * Track position in the coefficient vector
    local pos = 0
    local ki1 = `n1'
    local ki0 = `n0'

    * ── I(1) Regressors Panel ─────────────────────────────
    if `ki1' > 0 {
        di as text " I(1) Regressors"
        forvalues j = 1/`ki1' {
            local pos = `pos' + 1
            local vname : word `pos' of `cnames'
            local coef = `bb'[1,`pos']
            local se   = sqrt(`VV'[`pos',`pos'])
            if `se' > 0 {
                local tstat = `coef' / `se'
            }
            else {
                local tstat = .
            }
            local pval = 2 * (1 - normal(abs(`tstat')))
            local lo = `coef' - `crit' * `se'
            local hi = `coef' + `crit' * `se'
            di as text %12s abbrev("`vname'",12) " {c |}" ///
               as result %9.4f `coef' %9.4f `se' ///
               %8.2f `tstat' %7.3f `pval' ///
               %9.4f `lo' %9.4f `hi'
        }
    }

    * ── I(0) Regressors Panel ─────────────────────────────
    if `ki0' > 0 {
        di as text " I(0) Regressors"
        forvalues j = 1/`ki0' {
            local pos = `pos' + 1
            local vname : word `pos' of `cnames'
            local coef = `bb'[1,`pos']
            local se   = sqrt(`VV'[`pos',`pos'])
            if `se' > 0 {
                local tstat = `coef' / `se'
            }
            else {
                local tstat = .
            }
            local pval = 2 * (1 - normal(abs(`tstat')))
            local lo = `coef' - `crit' * `se'
            local hi = `coef' + `crit' * `se'
            di as text %12s abbrev("`vname'",12) " {c |}" ///
               as result %9.4f `coef' %9.4f `se' ///
               %8.2f `tstat' %7.3f `pval' ///
               %9.4f `lo' %9.4f `hi'
        }
    }

    * ── Deterministic terms ───────────────────────────────
    di as text "{hline 13}{c +}{hline 51}"
    forvalues j = `=`pos'+1'/`ncols' {
        local pos = `j'
        local vname : word `pos' of `cnames'
        local coef = `bb'[1,`pos']
        local se   = sqrt(`VV'[`pos',`pos'])
        if `se' > 0 {
            local tstat = `coef' / `se'
        }
        else {
            local tstat = .
        }
        local pval = 2 * (1 - normal(abs(`tstat')))
        local lo = `coef' - `crit' * `se'
        local hi = `coef' + `crit' * `se'
        di as text %12s abbrev("`vname'",12) " {c |}" ///
           as result %9.4f `coef' %9.4f `se' ///
           %8.2f `tstat' %7.3f `pval' ///
           %9.4f `lo' %9.4f `hi'
    }

    di as text "{hline 65}"
    di as text "Note: Wald tests using chi2(q) critical values are conservative."
    di as text "      I(1) coefficients: mixed normal limit (Phillips Thm 4.1b)."
    di as text "      I(0) coefficients: normal limit (Phillips Thm 4.1a)."

end

* ═══════════════════════════════════════════════════════════════════
* Mata estimation engine
* ═══════════════════════════════════════════════════════════════════
mata:
mata set matastrict on

// ── Kernel weight functions ──────────────────────────────────────
real scalar _fmols_kernel_bartlett(real scalar x)
{
    if (abs(x) < 1) return(1 - abs(x))
    return(0)
}

real scalar _fmols_kernel_parzen(real scalar x)
{
    real scalar ax
    ax = abs(x)
    if (ax <= 0.5) return(1 - 6*ax^2 + 6*ax^3)
    if (ax <= 1)   return(2*(1-ax)^3)
    return(0)
}

real scalar _fmols_kernel_qs(real scalar x)
{
    real scalar z
    if (abs(x) < 1e-8) return(1)
    z = 6 * pi() * x / 5
    return(25/(12*pi()^2*x^2) * (sin(z)/z - cos(z)))
}

real scalar _fmols_kernel_tukey(real scalar x)
{
    if (abs(x) <= 1) return((1 + cos(pi()*x))/2)
    return(0)
}

real scalar _fmols_kernel_weight(string scalar ktype, real scalar x)
{
    if (ktype == "bartlett") return(_fmols_kernel_bartlett(x))
    if (ktype == "parzen")   return(_fmols_kernel_parzen(x))
    if (ktype == "qs")       return(_fmols_kernel_qs(x))
    if (ktype == "tukey")    return(_fmols_kernel_tukey(x))
    return(_fmols_kernel_bartlett(x))
}

// ── Andrews (1991) automatic bandwidth ──────────────────────────
real scalar _fmols_andrews_bw(real matrix U, string scalar ktype)
{
    real scalar n, k, j, alphahat, rhohat_num, rhohat_den, rho_j
    real scalar sigma2_j, bw
    real colvector u_j

    n = rows(U)
    k = cols(U)

    // Fit AR(1) to each column, estimate alpha
    alphahat = 0
    for (j=1; j<=k; j++) {
        u_j = U[.,j]
        rhohat_num = 0
        rhohat_den = 0
        for (rho_j = 2; rho_j <= n; rho_j++) {
            rhohat_num = rhohat_num + u_j[rho_j] * u_j[rho_j-1]
            rhohat_den = rhohat_den + u_j[rho_j-1]^2
        }
        if (rhohat_den > 0) {
            sigma2_j = rhohat_num / rhohat_den
        }
        else {
            sigma2_j = 0
        }
        alphahat = alphahat + 4 * sigma2_j^2 / ((1-sigma2_j)^4)
    }
    alphahat = alphahat / k

    // Bandwidth formula depends on kernel type
    if (ktype == "bartlett") {
        bw = 1.1447 * (alphahat * n)^(1/3)
    }
    else if (ktype == "parzen") {
        bw = 2.6614 * (alphahat * n)^(1/5)
    }
    else if (ktype == "qs") {
        bw = 1.3221 * (alphahat * n)^(1/5)
    }
    else {
        // Tukey
        bw = 1.7462 * (alphahat * n)^(1/5)
    }

    if (bw < 1) bw = 1
    if (bw > n/2) bw = floor(n/2)

    return(bw)
}

// ── Newey-West bandwidth ────────────────────────────────────────
real scalar _fmols_nw_bw(real scalar n)
{
    return(floor(4 * (n/100)^(2/9)))
}

// ── Long-run covariance estimation ──────────────────────────────
// Computes Omega = sum_{j=-(T-1)}^{T-1} w(j/K) * Gamma(j)
real matrix _fmols_lrcov(real matrix U, real scalar bw, string scalar ktype)
{
    real scalar n, k, j
    real scalar w
    real matrix Omega, Gam

    n = rows(U)
    k = cols(U)
    Omega = J(k, k, 0)

    for (j = -(n-1); j <= (n-1); j++) {
        w = _fmols_kernel_weight(ktype, j/bw)
        if (abs(w) > 1e-15) {
            Gam = _fmols_sample_autocov(U, j)
            Omega = Omega + w * Gam
        }
    }

    // Force symmetry
    _makesymmetric(Omega)
    return(Omega)
}

// ── One-sided long-run covariance: Delta = sum_{j=0}^{T-1} w(j/K) Gamma(j)
real matrix _fmols_onesided_lrcov(real matrix U, real scalar bw, string scalar ktype)
{
    real scalar n, k, j
    real scalar w
    real matrix Delta, Gam

    n = rows(U)
    k = cols(U)
    Delta = J(k, k, 0)

    for (j = 0; j <= (n-1); j++) {
        w = _fmols_kernel_weight(ktype, j/bw)
        if (abs(w) > 1e-15) {
            Gam = _fmols_sample_autocov(U, j)
            Delta = Delta + w * Gam
        }
    }

    return(Delta)
}

// ── Sample autocovariance at lag j ──────────────────────────────
real matrix _fmols_sample_autocov(real matrix U, real scalar j)
{
    real scalar n, k, t, tstart, tend
    real matrix Gam

    n = rows(U)
    k = cols(U)
    Gam = J(k, k, 0)

    if (j >= 0) {
        tstart = 1
        tend   = n - j
        for (t = tstart; t <= tend; t++) {
            Gam = Gam + U[t, .]' * U[t+j, .]
        }
    }
    else {
        tstart = 1 - j
        tend   = n
        for (t = tstart; t <= tend; t++) {
            Gam = Gam + U[t, .]' * U[t+j, .]
        }
    }

    Gam = Gam / n
    return(Gam)
}


// ═══════════════════════════════════════════════════════════════════
// MAIN ESTIMATION FUNCTION
// ═══════════════════════════════════════════════════════════════════
void _mixi01_fmols_estimate(
    string scalar depvar,
    string scalar i1vars,
    string scalar i0vars,
    string scalar touse,
    real scalar   hascons,
    real scalar   trend,
    string scalar kernel,
    real scalar   bwidth,
    string scalar bmeth,
    real scalar   vlag,
    real scalar   level,
    string scalar bname,
    string scalar Vname,
    string scalar Omname,
    string scalar bwname,
    string scalar r2name,
    string scalar r2aname,
    string scalar rmsename,
    string scalar lrsename,
    string scalar iordname
)
{
    // ── 1. Load data ──────────────────────────────────────────
    real colvector y, sel
    real matrix X1, X2, Z, X, Xall, M1, M2
    real scalar T, m1, m2, kdet, m, ki
    string rowvector i1list, i0list

    sel = st_data(., touse)
    y   = st_data(., depvar, touse)
    T   = rows(y)

    // I(1) regressors → X2 (nonstationary)
    i1list = tokens(i1vars)
    m2 = length(i1list)
    if (m2 > 0) {
        X2 = st_data(., i1vars, touse)
    }
    else {
        X2 = J(T, 0, .)
    }

    // I(0) regressors → X1 (stationary)
    i0list = tokens(i0vars)
    m1 = length(i0list)
    if (m1 > 0) {
        X1 = st_data(., i0vars, touse)
    }
    else {
        X1 = J(T, 0, .)
    }

    // ── 2. Deterministic terms appended to X1 (stationary block) ──
    kdet = 0
    Z = J(T, 0, .)

    if (hascons) {
        Z = Z, J(T, 1, 1)
        kdet = kdet + 1
    }
    if (trend >= 1) {
        Z = Z, (1::T)
        kdet = kdet + 1
    }
    if (trend >= 2) {
        Z = Z, ((1::T):^2)
        kdet = kdet + 1
    }

    // Full regressor matrix: [X2 (I(1)), X1 (I(0)), Z (deterministics)]
    // Convention: I(1) first for super-consistent coefficients
    X = J(T, 0, .)
    if (m2 > 0) X = X, X2
    if (m1 > 0) X = X, X1
    if (kdet > 0) X = X, Z

    m = cols(X)    // total parameters

    if (m >= T) {
        errprintf("More parameters than observations\n")
        exit(error(2001))
    }

    // ── 3. OLS to get initial residuals ───────────────────────
    real matrix XX, Xy
    real colvector beta_ols, eps
    real scalar sse, sst, ybar

    XX = cross(X, X)
    Xy = cross(X, y)
    beta_ols = invsym(XX) * Xy
    eps = y - X * beta_ols

    // ── 4. Form u2 = Delta X2 (first differences of I(1) regressors) ──
    real matrix dX2, U_stacked
    real colvector eps_trim
    real scalar Tm1

    if (m2 > 0) {
        dX2 = X2[2::T, .] - X2[1::(T-1), .]
    }
    else {
        dX2 = J(T-1, 0, .)
    }

    // Trim eps to match dX2 (lose first obs)
    eps_trim = eps[2::T]
    Tm1 = T - 1

    // ── 5. Stack (eps, dX2) for long-run covariance ──────────
    if (m2 > 0) {
        U_stacked = eps_trim, dX2
    }
    else {
        U_stacked = eps_trim
    }

    // ── 6. VAR prewhitening (optional) ───────────────────────
    real matrix U_pw, B_pw
    real scalar kpw

    kpw = cols(U_stacked)

    if (vlag > 0 & Tm1 > vlag + kpw) {
        // Fit VAR(vlag) to U_stacked
        real matrix Ulag, Ucur, Bvar
        real scalar vi
        Ucur = U_stacked[(vlag+1)::Tm1, .]
        Ulag = J(Tm1-vlag, 0, .)
        for (vi = 1; vi <= vlag; vi++) {
            Ulag = Ulag, U_stacked[(vlag+1-vi)::(Tm1-vi), .]
        }
        Bvar = invsym(cross(Ulag, Ulag)) * cross(Ulag, Ucur)
        U_pw = Ucur - Ulag * Bvar
    }
    else {
        U_pw = U_stacked
    }

    // ── 7. Bandwidth selection ───────────────────────────────
    real scalar bw

    if (bwidth > 0) {
        bw = bwidth
    }
    else {
        if (bmeth == "andrews") {
            bw = _fmols_andrews_bw(U_pw, kernel)
        }
        else {
            bw = _fmols_nw_bw(Tm1)
        }
    }

    // ── 8. Long-run covariance Omega ─────────────────────────
    real matrix Omega, Delta
    real matrix Om_ee, Om_eu, Om_ue, Om_uu
    real matrix Del_0e, Del_eu, Del_uu, Del_ue

    Omega = _fmols_lrcov(U_pw, bw, kernel)
    Delta = _fmols_onesided_lrcov(U_pw, bw, kernel)

    // Revert prewhitening if used
    if (vlag > 0 & Tm1 > vlag + kpw) {
        real matrix Cmat, Cinv
        Cmat = I(kpw)
        for (vi = 1; vi <= vlag; vi++) {
            Cmat = Cmat - Bvar[((vi-1)*kpw+1)::(vi*kpw), .]
        }
        Cinv = invsym(Cmat)
        Omega = Cinv * Omega * Cinv'
        Delta = Cinv * Delta * Cinv'
    }

    // ── 9. Extract blocks ────────────────────────────────────
    // U_stacked = (eps, dX2)  cols: 1 is eps, 2..m2+1 are dX2

    real scalar Om_ee_s
    Om_ee_s = Omega[1, 1]

    if (m2 > 0) {
        Om_ee  = J(1, 1, Om_ee_s)
        Om_eu  = Omega[(1..1), (2..(m2+1))]
        Om_ue  = Omega[(2..(m2+1)), (1..1)]
        Om_uu  = Omega[(2..(m2+1)), (2..(m2+1))]

        Del_0e = J(1, 1, Delta[1, 1])
        Del_eu = Delta[(1..1), (2..(m2+1))]
        Del_ue = Delta[(2..(m2+1)), (1..1)]
        Del_uu = Delta[(2..(m2+1)), (2..(m2+1))]
    }
    else {
        Om_ee  = J(1, 1, Om_ee_s)
        Om_eu  = J(1, 0, .)
        Om_ue  = J(0, 1, .)
        Om_uu  = J(0, 0, .)
        Del_0e = J(1, 1, 0)
        Del_eu = J(1, 0, .)
        Del_ue = J(0, 1, .)
        Del_uu = J(0, 0, .)
    }

    // ── 10. FM correction ────────────────────────────────────
    // y+ = y - Omega_eu * inv(Omega_uu) * u2'
    // Where u2 = dX2
    real colvector yplus
    real matrix Om_uu_inv
    real matrix Delta_plus, Gam0_full
    real matrix Lam_eu, Lam_uu
    real scalar j2
    real colvector yplus_tail

    Delta_plus = J(1, m, 0)
    yplus = y

    if (m2 > 0 & rows(Om_uu) > 0) {
        Om_uu_inv = invsym(Om_uu)

        // Endogeneity correction on y; dX2 is (T-1)×m2, eq stays vectorised
        yplus_tail = y[(2..T), 1] - dX2 * (Om_uu_inv * Om_eu')
        yplus[(2..T), 1] = yplus_tail

        // Gamma(0) of stacked residuals
        Gam0_full = _fmols_sample_autocov(U_pw, 0)

        // Revert prewhitening on Gamma(0) if used
        if (vlag > 0 & Tm1 > vlag + kpw) {
            Gam0_full = Cinv * Gam0_full * Cinv'
        }

        // Lambda = Delta - Gamma(0)/2  [Phillips eq. (2.7)]
        Lam_eu = Del_eu - Gam0_full[(1..1), (2..(m2+1))] / 2
        Lam_uu = Del_uu - Gam0_full[(2..(m2+1)), (2..(m2+1))] / 2

        // Bias+ = Lambda_eu - Omega_eu * Omega_uu^{-1} * Lambda_uu
        // [Phillips (1995) eq. (4.7)]
        real matrix dp_i1m
        dp_i1m = Lam_eu - Om_eu * Om_uu_inv * Lam_uu
        for (j2 = 1; j2 <= m2; j2++) {
            Delta_plus[1, j2] = dp_i1m[1, j2]
        }
    }

    // ── 11. FM-OLS estimator ─────────────────────────────────
    // A+ = (Y+'X - T * Delta+') * inv(X'X)
    real matrix XpYp, beta_fm
    real colvector dp_vec

    dp_vec = Delta_plus'
    XpYp = cross(X, yplus)
    beta_fm = invsym(XX) * (XpYp - T * dp_vec)

    // ── 12. Residuals and fit statistics ─────────────────────
    real colvector resid_fm
    real scalar sse_fm, mse_fm, rmse_val

    resid_fm = y - X * beta_fm
    sse_fm = cross(resid_fm, resid_fm)
    ybar = mean(y)
    sst = cross(y :- ybar, y :- ybar)

    real scalar r2_val, r2a_val

    if (sst > 0) {
        r2_val = 1 - sse_fm / sst
    }
    else {
        r2_val = 0
    }
    r2a_val = 1 - (1 - r2_val) * (T - 1) / (T - m)

    mse_fm = sse_fm / (T - m)
    rmse_val = sqrt(mse_fm)

    // ── 13. Variance-covariance matrix ───────────────────────
    // Omega_ee.2 = Omega_ee - Omega_eu * inv(Omega_uu) * Omega_ue
    // (conditional long-run variance of eps given u2)
    real scalar Om_ee_2
    real matrix Om_ee_2_mat

    if (m2 > 0 & rows(Om_uu) > 0) {
        Om_ee_2_mat = Om_ee - Om_eu * Om_uu_inv * Om_ue
        Om_ee_2 = Om_ee_2_mat[1, 1]
    }
    else {
        Om_ee_2 = Om_ee_s
    }
    if (Om_ee_2 < 0) Om_ee_2 = abs(Om_ee_2)

    real scalar lrse_val
    lrse_val = sqrt(Om_ee_2)

    // Build block-diagonal variance matrix
    // I(1) block: V_i1 = Om_ee_2 * inv(X2'M1X2) where M1 = I - X1(X1'X1)^{-1}X1'
    // I(0) block: V_i0 = Omega_star * inv(X1'M2X1) where Omega_star uses
    //             the long-run variance of the stationary part

    real matrix VV
    VV = J(m, m, 0)

    // Stationary block indices: m2+1 .. m2+m1+kdet
    // Nonstationary block indices: 1 .. m2

    if (m2 > 0 & (m1 + kdet) > 0) {
        // Both blocks present — compute projection matrices
        real matrix X_i1, X_stat, M_stat, M_i1
        real matrix XX_i1, XX_stat

        X_i1  = X[., 1::m2]             // I(1) regressors
        X_stat = X[., (m2+1)::m]         // I(0) + deterministics

        // M_stat = I - X_stat * inv(X_stat' X_stat) * X_stat'
        XX_stat = cross(X_stat, X_stat)

        // V for I(1) coefficients: Om_ee_2 * inv(X2' M_stat X2)
        // where M_stat annihilates stationary regressors
        real matrix X2M, V_i1
        X2M = X_i1 - X_stat * (invsym(XX_stat) * cross(X_stat, X_i1))
        V_i1 = Om_ee_2 * invsym(cross(X2M, X2M))

        // M_i1 = I - X_i1 * inv(X_i1' X_i1) * X_i1'
        XX_i1 = cross(X_i1, X_i1)

        // V for I(0) + det coefficients: Om_ee_2 * inv(X_stat' M_i1 X_stat)
        real matrix XsM, V_stat
        XsM = X_stat - X_i1 * (invsym(XX_i1) * cross(X_i1, X_stat))
        V_stat = Om_ee_2 * invsym(cross(XsM, XsM))

        // Assemble (block diagonal approximation per Phillips Theorem 4.1)
        VV[1::m2, 1::m2] = V_i1
        VV[(m2+1)::m, (m2+1)::m] = V_stat
    }
    else if (m2 > 0) {
        // Only I(1) regressors
        VV = Om_ee_2 * invsym(XX)
    }
    else {
        // Only I(0)/stationary regressors
        VV = Om_ee_2 * invsym(XX)
    }

    // Force symmetry
    _makesymmetric(VV)

    // ── 14. Build integration order vector ───────────────────
    real matrix iord
    iord = J(1, m, 0)
    if (m2 > 0) {
        for (j2 = 1; j2 <= m2; j2++) {
            iord[1, j2] = 1
        }
    }
    // I(0) and deterministic terms stay at 0

    // ── 15. Store results ────────────────────────────────────
    st_matrix(bname, beta_fm')
    st_matrix(Vname, VV)
    st_matrix(Omname, Omega)
    st_numscalar(bwname, bw)
    st_numscalar(r2name, r2_val)
    st_numscalar(r2aname, r2a_val)
    st_numscalar(rmsename, rmse_val)
    st_numscalar(lrsename, lrse_val)
    st_matrix(iordname, iord)
}

end
