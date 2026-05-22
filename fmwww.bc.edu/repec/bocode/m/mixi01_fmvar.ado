*! mixi01_fmvar 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
* mixi01_fmvar.ado — FM-VAR with mixed I(1)/I(0) variables
* Phillips (1995, Econometrica, Vol. 63, Section 5)
* Fully Modified Vector Autoregression — no unit root distributions

capture program drop mixi01_fmvar
program define mixi01_fmvar, eclass sortpreserve
    version 17.0

    syntax varlist(min=2 ts fv) [if] [in], LAGS(integer) [  ///
        I1vars(varlist ts fv)                                 ///
        I0vars(varlist ts fv)                                 ///
        auto                                                  ///
        RANK(integer -1)                                      ///
        noCONStant                                            ///
        TRend(integer 0)                                      ///
        KERnel(string)                                        ///
        BWIDth(real 0)                                        ///
        BMETh(string)                                         ///
        VLAG(integer 0)                                       ///
        Level(real 95)                                        ///
    ]

    * ── Defaults and checks ──────────────────────────────────────
    if `lags' < 1 {
        di as error "lags() must be >= 1"
        exit 198
    }
    if "`kernel'" == "" local kernel "bartlett"
    local kernel = lower("`kernel'")
    if !inlist("`kernel'","bartlett","parzen","qs","tukey") {
        di as error "kernel() must be bartlett, parzen, qs, or tukey"
        exit 198
    }
    if "`bmeth'" == "" local bmeth "andrews"
    local bmeth = lower("`bmeth'")

    * ── Mark sample ──────────────────────────────────────────────
    marksample touse
    local allvars `varlist'
    local nvars : word count `allvars'

    markout `touse' `allvars'
    if "`i1vars'" != "" markout `touse' `i1vars'
    if "`i0vars'" != "" markout `touse' `i0vars'

    qui count if `touse'
    local nobs = r(N)

    qui tsset
    local timevar "`r(timevar)'"

    * ── Auto-detect integration orders ───────────────────────────
    if "`auto'" != "" {
        local i1vars ""
        local i0vars ""
        foreach v of local allvars {
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

    * Default: all I(1) if not specified
    if "`i1vars'" == "" & "`i0vars'" == "" {
        local i1vars `allvars'
    }

    * Ensure every variable classified
    foreach v of local allvars {
        local in1 : list v in i1vars
        local in0 : list v in i0vars
        if `in1' == 0 & `in0' == 0 {
            local i1vars `i1vars' `v'
        }
    }

    local n1 : word count `i1vars'
    local n0 : word count `i0vars'
    local n = `nvars'

    * ── Call Mata estimation engine ──────────────────────────────
    tempname b V Sigma F_comp eigenvals bw_used

    mata: _mixi01_fmvar_estimate(                       ///
        "`allvars'", "`i1vars'", "`i0vars'",            ///
        "`touse'",                                       ///
        `lags', `rank',                                  ///
        "`constant'" != "noconstant",                    ///
        `trend',                                         ///
        "`kernel'", `bwidth', "`bmeth'", `vlag',         ///
        "`b'", "`V'", "`Sigma'", "`F_comp'",            ///
        "`eigenvals'", "`bw_used'"                       ///
    )

    * ── Build coefficient names ──────────────────────────────────
    * For a VAR(p) with n variables: n equations, each has n*p + det coefficients
    * Use Stata's standard ts-op notation: L.var (lag 1), L2.var (lag 2), ...
    local colnames ""
    local eqnames ""
    forvalues eq = 1/`n' {
        local eqvar : word `eq' of `allvars'
        forvalues lag = 1/`lags' {
            if `lag' == 1 {
                local lpref "L"
            }
            else {
                local lpref "L`lag'"
            }
            foreach v of local allvars {
                local colnames `colnames' `lpref'.`v'
                local eqnames `eqnames' `eqvar'
            }
        }
        if "`constant'" != "noconstant" {
            local colnames `colnames' _cons
            local eqnames `eqnames' `eqvar'
        }
        if `trend' >= 1 {
            local colnames `colnames' _trend
            local eqnames `eqnames' `eqvar'
        }
    }

    * ── Post results ─────────────────────────────────────────────
    tempname bmat Vmat
    matrix `bmat' = `b'
    matrix `Vmat' = `V'

    local ncols = colsof(`bmat')
    local nnames : word count `colnames'

    * Safety check — if names don't match, use generic
    if `ncols' != `nnames' {
        local colnames ""
        local eqnames ""
        forvalues j = 1/`ncols' {
            local colnames `colnames' c`j'
            local eqnames `eqnames' eq1
        }
    }

    matrix colnames `bmat' = `colnames'
    matrix coleq    `bmat' = `eqnames'
    matrix rownames `bmat' = y1
    matrix colnames `Vmat' = `colnames'
    matrix coleq    `Vmat' = `eqnames'
    matrix rownames `Vmat' = `colnames'
    matrix roweq    `Vmat' = `eqnames'

    ereturn post `bmat' `Vmat', esample(`touse') obs(`nobs')

    ereturn scalar N       = `nobs'
    ereturn scalar k       = `n'
    ereturn scalar lags    = `lags'
    ereturn scalar n_i1    = `n1'
    ereturn scalar n_i0    = `n0'
    ereturn scalar bwidth  = scalar(`bw_used')
    ereturn scalar rank_coint = `rank'

    ereturn matrix Sigma     = `Sigma'
    ereturn matrix F_companion = `F_comp'
    ereturn matrix eigenvalues = `eigenvals'

    ereturn local cmd      "mixi01_fmvar"
    ereturn local varlist  "`allvars'"
    ereturn local depvar   "`allvars'"
    ereturn local i1vars   "`i1vars'"
    ereturn local i0vars   "`i0vars'"
    ereturn local kernel   "`kernel'"

    * ── Display results ──────────────────────────────────────────
    _mixi01_fmvar_display, level(`level')

end

* ═══════════════════════════════════════════════════════════════════
* Display program for FM-VAR
* ═══════════════════════════════════════════════════════════════════
capture program drop _mixi01_fmvar_display
program define _mixi01_fmvar_display
    syntax , [Level(real 95)]

    local n    = e(k)
    local p    = e(lags)
    local nobs = e(N)
    local n1   = e(n_i1)
    local n0   = e(n_i0)
    local bw   = e(bwidth)
    local kern "`e(kernel)'"
    local vars "`e(varlist)'"
    local i1v  "`e(i1vars)'"
    local i0v  "`e(i0vars)'"

    di ""
    di as text "{hline 70}"
    di as text "FM-VAR Estimation (Phillips, Econometrica 1995, Section 5)"
    di as text "{hline 70}"
    di as text "Variables" _col(14) "= " as result "`vars'"
    di as text "# equations" _col(14) "= " as result "`n'"  ///
       as text _col(40) "Number of obs" _col(56) "= " as result %8.0f `nobs'
    di as text "Lags" _col(14) "= " as result "`p'" ///
       as text _col(40) "Kernel" _col(56) "= " as result proper("`kern'")
    di as text "I(1) vars" _col(14) "= " as result "`i1v'"
    di as text "I(0) vars" _col(14) "= " as result "`i0v'"
    di as text "Bandwidth" _col(14) "= " as result %6.2f `bw'

    di as text "{hline 70}"
    di as text "Key result (Theorem 5.1): NO unit root distributions in FM-VAR."
    di as text "  - Stationary coefficients: normal limit (sqrt(T) rate)"
    di as text "  - Nonstationary coefficients: mixed normal (T rate)"
    di as text "  - Unit root matrix In-r: mixed normal, NOT Dickey-Fuller"
    di as text "{hline 70}"

    tempname bb VV
    matrix `bb' = e(b)
    matrix `VV' = e(V)
    local ncols = colsof(`bb')
    local cnames : colnames `bb'

    local alpha = (100 - `level') / 100
    local crit = invnormal(1 - `alpha'/2)

    * Display equation by equation
    local kpeq = `n' * `p'   // regressors per equation (without det)

    forvalues eq = 1/`n' {
        local eqvar : word `eq' of `vars'

        * Check if this variable is I(1) or I(0)
        local in1 : list eqvar in i1v
        if `in1' {
            local eqtype "I(1)"
        }
        else {
            local eqtype "I(0)"
        }

        di ""
        di as text "Equation: " as result "`eqvar'" ///
           as text " [" as result "`eqtype'" as text "]"
        di as text "{hline 13}{c +}{hline 51}"
        di as text _col(14) "{c |}" _col(17) "Coef." ///
           _col(27) "Std.Err." _col(39) "t" _col(46) "P>|t|" ///
           _col(54) "[" %3.0f `level' "% Conf. Int.]"
        di as text "{hline 13}{c +}{hline 51}"

        * Compute offset into the vectorised b
        * Each equation has n*p + det coefficients
        local nper_eq = int(`ncols' / `n')
        local offset = (`eq' - 1) * `nper_eq'

        forvalues j = 1/`nper_eq' {
            local pos = `offset' + `j'
            if `pos' > `ncols' continue
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
    }

    di ""
    di as text "Note: All t-tests use standard normal (not DF) critical values."
    di as text "      Wald tests are conservative (bounded by chi2(q))."

end


* ═══════════════════════════════════════════════════════════════════
* Mata engine for FM-VAR
* ═══════════════════════════════════════════════════════════════════
mata:
mata set matastrict on

// ── Helper functions (self-contained) ─────────────────────────────
real scalar _fmvar_kernel_weight(string scalar ktype, real scalar x)
{
    real scalar ax, z
    ax = abs(x)
    if (ktype == "bartlett") {
        if (ax < 1) return(1 - ax)
        return(0)
    }
    if (ktype == "parzen") {
        if (ax <= 0.5) return(1 - 6*ax^2 + 6*ax^3)
        if (ax <= 1)   return(2*(1-ax)^3)
        return(0)
    }
    if (ktype == "qs") {
        if (ax < 1e-8) return(1)
        z = 6 * pi() * x / 5
        return(25/(12*pi()^2*x^2) * (sin(z)/z - cos(z)))
    }
    if (ktype == "tukey") {
        if (ax <= 1) return((1 + cos(pi()*x))/2)
        return(0)
    }
    if (ax < 1) return(1 - ax)
    return(0)
}

real matrix _fmvar_sample_autocov(real matrix U, real scalar j)
{
    real scalar n, k, t, tstart, tend
    real matrix Gam
    n = rows(U)
    k = cols(U)
    Gam = J(k, k, 0)
    if (j >= 0) {
        for (t = 1; t <= n - j; t++) {
            Gam = Gam + U[t, .]' * U[t+j, .]
        }
    }
    else {
        for (t = 1 - j; t <= n; t++) {
            Gam = Gam + U[t, .]' * U[t+j, .]
        }
    }
    return(Gam / n)
}

real matrix _fmvar_lrcov(real matrix U, real scalar bw, string scalar ktype)
{
    real scalar n, j
    real scalar w
    real matrix Omega
    n = rows(U)
    Omega = J(cols(U), cols(U), 0)
    for (j = -(n-1); j <= (n-1); j++) {
        w = _fmvar_kernel_weight(ktype, j/bw)
        if (abs(w) > 1e-15) {
            Omega = Omega + w * _fmvar_sample_autocov(U, j)
        }
    }
    return((Omega + Omega') / 2)
}

real matrix _fmvar_onesided_lrcov(real matrix U, real scalar bw, string scalar ktype)
{
    real scalar n, j
    real scalar w
    real matrix Delta
    n = rows(U)
    Delta = J(cols(U), cols(U), 0)
    for (j = 0; j <= (n-1); j++) {
        w = _fmvar_kernel_weight(ktype, j/bw)
        if (abs(w) > 1e-15) {
            Delta = Delta + w * _fmvar_sample_autocov(U, j)
        }
    }
    return(Delta)
}

real scalar _fmvar_andrews_bw(real matrix U, string scalar ktype)
{
    real scalar n, k, j, alphahat, rhohat_num, rhohat_den, rho_j, sigma2_j, bw
    real colvector u_j
    n = rows(U)
    k = cols(U)
    alphahat = 0
    for (j=1; j<=k; j++) {
        u_j = U[.,j]
        rhohat_num = 0
        rhohat_den = 0
        for (rho_j = 2; rho_j <= n; rho_j++) {
            rhohat_num = rhohat_num + u_j[rho_j] * u_j[rho_j-1]
            rhohat_den = rhohat_den + u_j[rho_j-1]^2
        }
        sigma2_j = (rhohat_den > 0) ? rhohat_num / rhohat_den : 0
        alphahat = alphahat + 4 * sigma2_j^2 / ((1-sigma2_j)^4)
    }
    alphahat = alphahat / k
    if (ktype == "bartlett") bw = 1.1447 * (alphahat * n)^(1/3)
    else if (ktype == "parzen") bw = 2.6614 * (alphahat * n)^(1/5)
    else if (ktype == "qs") bw = 1.3221 * (alphahat * n)^(1/5)
    else bw = 1.7462 * (alphahat * n)^(1/5)
    if (bw < 1) bw = 1
    if (bw > n/2) bw = floor(n/2)
    return(bw)
}

real scalar _fmvar_nw_bw(real scalar n)
{
    return(floor(4 * (n/100)^(2/9)))
}

void _mixi01_fmvar_estimate(
    string scalar allvars,
    string scalar i1vars,
    string scalar i0vars,
    string scalar touse,
    real scalar   p,
    real scalar   rank_coint,
    real scalar   hascons,
    real scalar   trend,
    string scalar kernel,
    real scalar   bwidth,
    string scalar bmeth,
    real scalar   vlag,
    string scalar bname,
    string scalar Vname,
    string scalar Signame,
    string scalar Fcompname,
    string scalar eigname,
    string scalar bwname
)
{
    // ── 1.  Load data ─────────────────────────────────────────
    real matrix Y, Yall
    real scalar T, n, j, eq
    string rowvector vlist, i1list, i0list

    vlist  = tokens(allvars)
    i1list = tokens(i1vars)
    i0list = tokens(i0vars)
    n = length(vlist)

    Yall = st_data(., allvars, touse)
    T = rows(Yall)

    // ── 2.  Construct VAR system: Yt = F1*Yt-1 + ... + Fp*Yt-p + J*zt + et
    //        Effective sample is t = p+1, ..., T
    real scalar Teff
    real matrix Yt, Xt, Zt
    real matrix Ylag

    Teff = T - p

    // Dependent: Yt (Teff x n)
    Yt = Yall[(p+1)::T, .]

    // Regressors: lagged Y stacked [Yt-1, Yt-2, ..., Yt-p]
    Xt = J(Teff, 0, .)
    for (j = 1; j <= p; j++) {
        Xt = Xt, Yall[(p+1-j)::(T-j), .]
    }

    // Deterministic terms
    Zt = J(Teff, 0, .)
    if (hascons) {
        Zt = Zt, J(Teff, 1, 1)
    }
    if (trend >= 1) {
        Zt = Zt, ((p+1)::T)
    }

    // Full regressor matrix
    real matrix Xfull
    real scalar kx, kdet
    kdet = cols(Zt)
    Xfull = Xt
    if (kdet > 0) {
        Xfull = Xfull, Zt
    }
    kx = cols(Xfull)

    // ── 3.  OLS equation-by-equation to get residuals ─────────
    real matrix XX, XXinv, Beta_ols, Ehat
    real matrix XY_eq
    real colvector beta_eq

    XX = cross(Xfull, Xfull)
    XXinv = invsym(XX)

    Beta_ols = J(kx, n, 0)
    Ehat = J(Teff, n, 0)

    for (eq = 1; eq <= n; eq++) {
        XY_eq = cross(Xfull, Yt[., eq])
        beta_eq = XXinv * XY_eq
        Beta_ols[., eq] = beta_eq
        Ehat[., eq] = Yt[., eq] - Xfull * beta_eq
    }

    // ── 4.  Classify variables and form uh ────────────────────
    // Identify which columns of Yall correspond to I(1) and I(0)
    real colvector is_i1
    real scalar ni1, ni0, vi
    string scalar vn

    is_i1 = J(n, 1, 0)
    ni1 = 0
    ni0 = 0
    for (vi = 1; vi <= n; vi++) {
        vn = vlist[vi]
        for (j = 1; j <= length(i1list); j++) {
            if (vn == i1list[j]) {
                is_i1[vi] = 1
                ni1++
                break
            }
        }
    }
    ni0 = n - ni1

    // Form uh = first differences of I(1) variables
    // For FM correction, we need Delta Y_i1 matched to residuals
    real matrix dY_i1, U_stack

    if (ni1 > 0) {
        // Extract I(1) columns and difference them
        real matrix Y_i1_all
        real scalar col_cnt, ci
        col_cnt = 0
        Y_i1_all = J(T, ni1, 0)
        ci = 0
        for (vi = 1; vi <= n; vi++) {
            if (is_i1[vi]) {
                ci++
                Y_i1_all[., ci] = Yall[., vi]
            }
        }
        // First differences, trimmed to match Ehat
        dY_i1 = Y_i1_all[(p+1)::T, .] - Y_i1_all[p::(T-1), .]
    }
    else {
        dY_i1 = J(Teff, 0, .)
    }

    // ── 5.  Long-run covariance of stacked (E, dY_i1) ─────────
    real matrix U_all, Omega_full, Delta_full
    real scalar bw, kall

    if (ni1 > 0) {
        U_all = Ehat, dY_i1
    }
    else {
        U_all = Ehat
    }

    kall = cols(U_all)

    // Bandwidth
    if (bwidth > 0) {
        bw = bwidth
    }
    else {
        if (bmeth == "andrews") {
            bw = _fmvar_andrews_bw(U_all, kernel)
        }
        else {
            bw = _fmvar_nw_bw(Teff)
        }
    }

    Omega_full = _fmvar_lrcov(U_all, bw, kernel)
    Delta_full = _fmvar_onesided_lrcov(U_all, bw, kernel)

    // ── 6.  Extract blocks: Omega_ee, Omega_eu, Omega_uu ──────
    real matrix Om_ee, Om_eu, Om_ue, Om_uu, Om_uu_inv
    real matrix Del_ee, Del_eu, Del_ue, Del_uu

    Om_ee = Omega_full[1::n, 1::n]

    if (ni1 > 0) {
        Om_eu = Omega_full[1::n, (n+1)::kall]
        Om_ue = Omega_full[(n+1)::kall, 1::n]
        Om_uu = Omega_full[(n+1)::kall, (n+1)::kall]

        Del_eu = Delta_full[1::n, (n+1)::kall]
        Del_uu = Delta_full[(n+1)::kall, (n+1)::kall]

        Om_uu_inv = invsym(Om_uu)
    }

    // ── 7.  FM correction: Y+ and bias correction ─────────────
    real matrix Yplus, Delta_plus_mat

    Yplus = Yt
    Delta_plus_mat = J(n, kx, 0)

    if (ni1 > 0) {
        // Endogeneity correction: Y+ = Y - dY_i1 * Om_uu_inv * Om_eu'
        // Applied to each row (observation)
        Yplus = Yt - dY_i1 * Om_uu_inv * Om_eu'

        // Bias correction: for each equation, form Delta+
        // Delta+ applies to the I(1) lag blocks in Xfull
        real matrix dp_eq
        dp_eq = Del_eu - Om_eu * Om_uu_inv * Del_uu   // n x ni1

        // Map dp_eq into the correct columns of the kx-dim regressor
        // The first n*p columns of Xfull are lags; only I(1) lags matter
        // For each lag j, columns corresponding to I(1) variables get the correction
        real scalar jlag, vj, col_pos
        for (eq = 1; eq <= n; eq++) {
            for (jlag = 1; jlag <= p; jlag++) {
                ci = 0
                for (vj = 1; vj <= n; vj++) {
                    col_pos = (jlag-1)*n + vj
                    if (is_i1[vj]) {
                        ci++
                        Delta_plus_mat[eq, col_pos] = dp_eq[eq, ci]
                    }
                }
            }
        }
    }

    // ── 8.  FM-VAR estimator: F+ = (Y+'X - T*Delta+) * inv(X'X) ──
    real matrix Beta_fm, XYplus

    Beta_fm = J(kx, n, 0)

    for (eq = 1; eq <= n; eq++) {
        XYplus = cross(Xfull, Yplus[., eq])
        Beta_fm[., eq] = XXinv * (XYplus - Teff * Delta_plus_mat[eq, .]')
    }

    // ── 9.  Residuals and Sigma ───────────────────────────────
    real matrix Resid_fm, Sigma
    Resid_fm = Yt - Xfull * Beta_fm
    Sigma = cross(Resid_fm, Resid_fm) / Teff

    // ── 10. Variance-covariance matrix ────────────────────────
    // For the vectorised FM-VAR: vec(F+)
    // V = Omega_ee.2 (x) inv(X'X)  (block structure)
    // where Omega_ee.2 = Om_ee - Om_eu * Om_uu_inv * Om_ue
    real matrix Om_ee_2, VV_full
    real scalar nparam

    if (ni1 > 0) {
        Om_ee_2 = Om_ee - Om_eu * Om_uu_inv * Om_ue
    }
    else {
        Om_ee_2 = Om_ee
    }
    // Force positive semi-definiteness
    Om_ee_2 = (Om_ee_2 + Om_ee_2') / 2

    // Full VCE: Kronecker product (equation by equation is simpler)
    // For display: V_eq(j) = Om_ee_2[j,j] * inv(X'X)
    nparam = n * kx
    VV_full = J(nparam, nparam, 0)

    for (eq = 1; eq <= n; eq++) {
        real scalar s_start, s_end
        s_start = (eq-1)*kx + 1
        s_end   = eq*kx
        VV_full[s_start::s_end, s_start::s_end] = Om_ee_2[eq, eq] * XXinv
    }
    VV_full = (VV_full + VV_full') / 2

    // ── 11. Companion matrix and eigenvalues ──────────────────
    real matrix F_comp, eig_r, eig_i, eigmod
    real scalar np_comp

    np_comp = n * p

    // Build companion form
    // F = [F1 F2 ... Fp; I 0 ... 0; 0 I ... 0; ...]
    F_comp = J(np_comp, np_comp, 0)
    // First block row: [F1, F2, ..., Fp]
    for (j = 1; j <= p; j++) {
        F_comp[1::n, ((j-1)*n+1)::(j*n)] = Beta_fm[((j-1)*n+1)::(j*n), .]'
    }
    // Sub-diagonal identity blocks
    if (p > 1) {
        for (j = 1; j <= (p-1); j++) {
            F_comp[(j*n+1)::((j+1)*n), ((j-1)*n+1)::(j*n)] = I(n)
        }
    }

    // Eigenvalues
    eigensystem(F_comp, eig_r, eig_i)
    if (length(eig_r) > 0) {
        // Moduli of eigenvalues
        eigmod = abs(eig_r)
    }
    else {
        eigmod = J(1, 1, .)
    }

    // ── 12. Vectorise and store ───────────────────────────────
    real rowvector b_vec
    b_vec = J(1, nparam, 0)
    for (eq = 1; eq <= n; eq++) {
        b_vec[((eq-1)*kx+1)::(eq*kx)] = Beta_fm[., eq]'
    }

    st_matrix(bname, b_vec)
    st_matrix(Vname, VV_full)
    st_matrix(Signame, Sigma)
    st_matrix(Fcompname, F_comp)
    st_matrix(eigname, Re(eigmod))
    st_numscalar(bwname, bw)
}

end
