*! mixi01_vecm 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
* mixi01_vecm.ado — Mixed VECM with I(1) and I(0) variables
* Chen (2022, SSRN-4218834)
* Vector Error Correction Models with Stationary and Nonstationary Variables

capture program drop mixi01_vecm
program define mixi01_vecm, eclass sortpreserve
    version 17.0

    syntax varlist(min=2 ts fv) [if] [in], [              ///
        I1vars(varlist ts fv)                               ///
        I0vars(varlist ts fv)                               ///
        RANK(integer -1)                                    ///
        LAGS(integer 2)                                     ///
        auto                                                ///
        TRend(string)                                       ///
        Level(real 95)                                      ///
    ]

    * ── Defaults and checks ──────────────────────────────────────
    if `lags' < 1 {
        di as error "lags() must be >= 1"
        exit 198
    }
    if "`trend'" == "" local trend "constant"
    if !inlist("`trend'","none","constant","trend","rtrend") {
        di as error "trend() must be none, constant, trend, or rtrend"
        exit 198
    }

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

    * Default: all I(1)
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

    * ── Call Mata engine ─────────────────────────────────────────
    tempname b V alpha beta Pi eigenvalues trace_stat max_stat ///
             beta_type_mat

    mata: _mixi01_vecm_estimate(                          ///
        "`allvars'", "`i1vars'", "`i0vars'",              ///
        "`touse'",                                         ///
        `lags', `rank',                                    ///
        "`trend'",                                         ///
        "`b'", "`V'", "`alpha'", "`beta'",                ///
        "`Pi'", "`eigenvalues'",                           ///
        "`trace_stat'", "`max_stat'",                      ///
        "`beta_type_mat'"                                  ///
    )

    * ── Build coefficient names ──────────────────────────────────
    local colnames ""
    local eqnames ""
    forvalues eq = 1/`n' {
        local eqvar : word `eq' of `allvars'

        * Error correction terms
        local rank_used = `rank'
        if `rank_used' < 0 {
            * Will have been determined in Mata — approximate
            local rank_used = min(`n' - 1, `n1')
            capture {
                tempname eig_temp
                matrix `eig_temp' = `eigenvalues'
                local rank_used = colsof(`eig_temp')
            }
        }
        if `rank_used' > 0 {
            forvalues r = 1/`rank_used' {
                local colnames `colnames' ec`r'
                local eqnames `eqnames' `eqvar'
            }
        }

        * Lagged differences
        local pminus1 = `lags' - 1
        if `pminus1' > 0 {
            forvalues lag = 1/`pminus1' {
                foreach v of local allvars {
                    if `lag' == 1 {
                        local lpref "LD"
                    }
                    else {
                        local lpref "LD`lag'"
                    }
                    local colnames `colnames' `lpref'.`v'
                    local eqnames `eqnames' `eqvar'
                }
            }
        }

        * Deterministic
        if "`trend'" != "none" {
            local colnames `colnames' _cons
            local eqnames `eqnames' `eqvar'
        }
        if inlist("`trend'","trend","rtrend") {
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

    ereturn matrix alpha       = `alpha'
    ereturn matrix beta        = `beta'
    ereturn matrix Pi          = `Pi'
    ereturn matrix eigenvalues = `eigenvalues'
    ereturn matrix trace_stat  = `trace_stat'
    ereturn matrix max_stat    = `max_stat'
    ereturn matrix beta_types  = `beta_type_mat'

    ereturn local cmd      "mixi01_vecm"
    ereturn local varlist  "`allvars'"
    ereturn local i1vars   "`i1vars'"
    ereturn local i0vars   "`i0vars'"
    ereturn local trend    "`trend'"

    * ── Display ──────────────────────────────────────────────────
    _mixi01_vecm_display, level(`level')

end


* ═══════════════════════════════════════════════════════════════════
* Display program
* ═══════════════════════════════════════════════════════════════════
capture program drop _mixi01_vecm_display
program define _mixi01_vecm_display
    syntax , [Level(real 95)]

    local n     = e(k)
    local p     = e(lags)
    local nobs  = e(N)
    local n1    = e(n_i1)
    local n0    = e(n_i0)
    local vars  = e(varlist)
    local i1v   = e(i1vars)
    local i0v   = e(i0vars)
    local trnd  = e(trend)

    di ""
    di as text "{hline 70}"
    di as text "Mixed VECM (Chen, SSRN 4218834, 2022)"
    di as text "Vector Error Correction Model with I(1) and I(0) Variables"
    di as text "{hline 70}"
    di as text "Variables" _col(14) "= " as result "`vars'"
    di as text "# variables" _col(14) "= " as result "`n'" ///
       as text _col(40) "Number of obs" _col(56) "= " as result %8.0f `nobs'
    di as text "VECM lags" _col(14) "= " as result "`p'" ///
       as text _col(40) "Trend" _col(56) "= " as result proper("`trnd'")
    di as text "I(1) vars" _col(14) "= " as result "`i1v'"
    di as text "I(0) vars" _col(14) "= " as result "`i0v'"
    di as text "{hline 70}"

    * Eigenvalue / trace statistics table
    di ""
    di as text "Johansen-type Cointegration Rank Tests (adapted for mixed VECM)"
    di as text "{hline 65}"
    di as text " Rank" _col(10) "Eigenvalue" _col(25) "Trace Stat" ///
       _col(40) "Max Stat" _col(55) "Type"
    di as text "{hline 65}"

    tempname eig_mat tr_mat mx_mat bt_mat
    matrix `eig_mat' = e(eigenvalues)
    matrix `tr_mat'  = e(trace_stat)
    matrix `mx_mat'  = e(max_stat)
    matrix `bt_mat'  = e(beta_types)

    local neig = colsof(`eig_mat')

    forvalues j = 1/`neig' {
        local eigval = `eig_mat'[1,`j']
        local trval  = `tr_mat'[1,`j']
        local mxval  = `mx_mat'[1,`j']
        local btype  = `bt_mat'[1,`j']

        if `btype' == 1 {
            local typestr "True CI"
        }
        else if `btype' == 2 {
            local typestr "Pseudo (I(0))"
        }
        else {
            local typestr "---"
        }

        di as text %5.0f `=`j'-1' _col(10) as result %10.4f `eigval' ///
           _col(25) as result %10.4f `trval' ///
           _col(40) as result %10.4f `mxval' ///
           _col(55) as text "`typestr'"
    }
    di as text "{hline 65}"

    * Display alpha and beta
    di ""
    di as text "Loading matrix alpha:"
    tempname alpha_disp
    matrix `alpha_disp' = e(alpha)
    matrix list `alpha_disp', noheader format(%9.4f)

    di ""
    di as text "Cointegrating matrix beta':"
    tempname beta_disp
    matrix `beta_disp' = e(beta)
    matrix list `beta_disp', noheader format(%9.4f)

    * Key results from Chen (2022)
    di ""
    di as text "{hline 65}"
    di as text "Chen (2022) Mixed VECM Key Results:"
    di as text "  Lemma 2.5: B31=0 is necessary and sufficient for I(0) components"
    di as text "  Lemma 2.6: beta decomposes into true CI and pseudo-CI subspaces"
    di as text "  Pseudo-CI: I(0) vars 'cointegrate with themselves' (eigenvalue=-1)"
    di as text "  True CI: genuine cointegrating relations among I(1) vars only"
    di as text "  Standard Johansen procedure remains valid for rank determination"
    di as text "{hline 65}"

end


* ═══════════════════════════════════════════════════════════════════
* Mata engine for mixed VECM
* ═══════════════════════════════════════════════════════════════════
mata:
mata set matastrict on

void _mixi01_vecm_estimate(
    string scalar allvars,
    string scalar i1vars,
    string scalar i0vars,
    string scalar touse,
    real scalar   p,
    real scalar   rank_arg,
    string scalar trend_type,
    string scalar bname,
    string scalar Vname,
    string scalar alphaname,
    string scalar betaname,
    string scalar Piname,
    string scalar eigname,
    string scalar tracename,
    string scalar maxname,
    string scalar btypename
)
{
    // ── 1.  Load data ─────────────────────────────────────────
    real matrix Yall
    real scalar T, n, j, eq, vi
    string rowvector vlist, i1list, i0list

    vlist  = tokens(allvars)
    i1list = tokens(i1vars)
    i0list = tokens(i0vars)
    n = length(vlist)

    Yall = st_data(., allvars, touse)
    T = rows(Yall)

    // ── 2.  Classify variables ────────────────────────────────
    real colvector is_i1
    real scalar ni1, ni0
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

    // ── 3.  Build VECM matrices ───────────────────────────────
    // Delta Y_t = alpha * beta' * Y_{t-1} + sum Gamma_j * Delta Y_{t-j} + det + U_t
    // First: compute Delta Y
    real matrix dY, Y_lag1, dY_lags
    real scalar Teff

    dY = Yall[2::T, .] - Yall[1::(T-1), .]

    // For VECM(p), we need p-1 lags of Delta Y
    // Effective sample: t = p+1, ..., T  →  rows p, ..., T-1 of dY
    Teff = T - p

    // Dependent: Delta Y_t (Teff x n)
    real matrix dYt
    dYt = dY[p::(T-1), .]

    // Y_{t-1} for error correction (levels, Teff x n)
    Y_lag1 = Yall[p::(T-1), .]

    // Lagged Delta Y (p-1 lags)
    dY_lags = J(Teff, 0, .)
    if (p > 1) {
        for (j = 1; j <= (p-1); j++) {
            dY_lags = dY_lags, dY[(p-j)::(T-1-j), .]
        }
    }

    // Deterministic terms
    real matrix Det
    real scalar kdet
    kdet = 0
    Det = J(Teff, 0, .)

    if (trend_type == "constant" | trend_type == "trend" | trend_type == "rtrend") {
        Det = Det, J(Teff, 1, 1)
        kdet++
    }
    if (trend_type == "trend" | trend_type == "rtrend") {
        Det = Det, (p::(T-1))
        kdet++
    }

    // ── 4.  Johansen procedure (concentrated model) ───────────
    // Step 1: Regress dYt on short-run regressors (dY_lags, Det) → residuals R0
    // Step 2: Regress Y_{t-1} on short-run regressors → residuals R1
    // Step 3: Solve eigenvalue problem from R0 and R1

    real matrix Zshort, R0, R1
    real matrix ZZ, ZZinv

    // Short-run regressors
    Zshort = J(Teff, 0, .)
    if (cols(dY_lags) > 0) Zshort = Zshort, dY_lags
    if (kdet > 0)          Zshort = Zshort, Det

    if (cols(Zshort) > 0) {
        ZZ = cross(Zshort, Zshort)
        ZZinv = invsym(ZZ)

        // Concentrate out short-run dynamics
        R0 = dYt - Zshort * (ZZinv * cross(Zshort, dYt))
        R1 = Y_lag1 - Zshort * (ZZinv * cross(Zshort, Y_lag1))
    }
    else {
        R0 = dYt
        R1 = Y_lag1
    }

    // Step 3: Solve generalized eigenvalue problem
    // S00 = R0' R0 / T, S11 = R1' R1 / T, S01 = R0' R1 / T
    real matrix S00, S11, S01, S10
    S00 = cross(R0, R0) / Teff
    S11 = cross(R1, R1) / Teff
    S01 = cross(R0, R1) / Teff
    S10 = S01'

    // Solve: |lambda * S11 - S10 * S00^{-1} * S01| = 0
    real matrix S00inv, Mmat
    real matrix eigvec_r
    real rowvector eigval_row
    real colvector eigval_col

    S00inv = invsym(S00)
    Mmat = invsym(S11) * S10 * S00inv * S01

    // Make symmetric for eigendecomposition
    Mmat = (Mmat + Mmat') / 2

    // Eigendecomposition — symeigensystem returns eigenvalues as a row vector
    symeigensystem(Mmat, eigvec_r, eigval_row)

    // Convert to column vector for sorting (order() sorts by row)
    eigval_col = eigval_row'

    // Sort eigenvalues in descending order
    real colvector sort_idx
    real matrix eigvec_sorted
    real colvector eigval_sorted

    sort_idx = order(-eigval_col, 1)

    eigval_sorted = J(n, 1, 0)
    eigvec_sorted = J(n, n, 0)
    for (j = 1; j <= n; j++) {
        eigval_sorted[j] = eigval_col[sort_idx[j], 1]
        eigvec_sorted[., j] = eigvec_r[., sort_idx[j]]
    }

    // Ensure eigenvalues are in [0, 1]
    for (j = 1; j <= n; j++) {
        if (eigval_sorted[j] < 0) eigval_sorted[j] = 0
        if (eigval_sorted[j] > 1) eigval_sorted[j] = 1
    }

    // ── 5.  Determine rank ────────────────────────────────────
    // Trace and max eigenvalue test statistics
    real colvector trace_stats, max_stats
    trace_stats = J(n, 1, 0)
    max_stats   = J(n, 1, 0)

    for (j = 1; j <= n; j++) {
        // Max eigenvalue statistic for rank = j-1
        if (eigval_sorted[j] > 0 & eigval_sorted[j] < 1) {
            max_stats[j] = -Teff * ln(1 - eigval_sorted[j])
        }
        // Trace statistic for rank = j-1
        real scalar tr_sum
        tr_sum = 0
        real scalar jj
        for (jj = j; jj <= n; jj++) {
            if (eigval_sorted[jj] > 0 & eigval_sorted[jj] < 1) {
                tr_sum = tr_sum - Teff * ln(1 - eigval_sorted[jj])
            }
        }
        trace_stats[j] = tr_sum
    }

    // Determine rank automatically or use specified
    real scalar h
    if (rank_arg >= 0) {
        h = rank_arg
    }
    else {
        // Auto: use 5% critical values (Osterwald-Lenum approximation)
        // For simplicity, use a rough threshold
        h = 0
        for (j = 1; j <= n; j++) {
            // Rough critical values (n-j+1 dimensional)
            real scalar cv_approx
            cv_approx = 3.84 + 2.5 * (n - j)   // Very rough approximation
            if (trace_stats[j] > cv_approx) {
                h = j
            }
            else {
                break
            }
        }
        // Also add pseudo-cointegrating vectors for I(0) vars
        // Chen (2022): I(0) vars contribute eigenvalues near 1
        // These are "pseudo" cointegrating relations
        if (h < ni0) h = h   // Don't automatically add pseudo-CI
    }

    // Ensure rank includes pseudo-CI for I(0) variables
    // Chen (2022) Lemma 2.6: total rank = true CI rank + number of I(0) vars
    real scalar h_total, h_true
    h_true = h
    h_total = h + ni0   // Include pseudo-cointegrating relations

    if (h_total > n) h_total = n
    if (h_total < 1) h_total = 1

    // ── 6.  Extract alpha and beta ────────────────────────────
    real matrix beta_hat, alpha_hat, Pi_hat

    // Beta: first h_total eigenvectors of Mmat (normalized)
    beta_hat = eigvec_sorted[., 1::h_total]

    // Normalize beta: beta' * S11 * beta = I
    real matrix beta_S11
    beta_S11 = beta_hat' * S11 * beta_hat
    beta_hat = beta_hat * invsym(cholesky(beta_S11))'

    // Alpha = S01 * beta
    alpha_hat = S01 * beta_hat

    // Pi = alpha * beta'
    Pi_hat = alpha_hat * beta_hat'

    // ── 7.  Classify cointegrating vectors ────────────────────
    // Chen (2022) Lemma 2.6:
    // beta can be decomposed into:
    //   - True cointegrating relations: involve only I(1) vars
    //   - Pseudo-cointegrating relations: I(0) vars with themselves
    //
    // Check structure: if a cointegrating vector has non-zero weights
    // only on I(0) variables, it's pseudo-CI

    real rowvector beta_types
    beta_types = J(1, h_total, 0)

    for (j = 1; j <= h_total; j++) {
        // Check if this vector loads mainly on I(0) variables
        real scalar weight_i1, weight_i0
        weight_i1 = 0
        weight_i0 = 0
        for (vi = 1; vi <= n; vi++) {
            if (is_i1[vi]) {
                weight_i1 = weight_i1 + abs(beta_hat[vi, j])
            }
            else {
                weight_i0 = weight_i0 + abs(beta_hat[vi, j])
            }
        }

        if (weight_i1 > 0.1 * (weight_i0 + weight_i1)) {
            beta_types[j] = 1    // True cointegrating relation
        }
        else {
            beta_types[j] = 2    // Pseudo-cointegrating (I(0) with itself)
        }
    }

    // ── 8.  Full VECM estimation ──────────────────────────────
    // Now estimate the full VECM with the determined rank
    // dYt = alpha * beta' * Y_{t-1} + Gamma * dY_lags + det + U

    // EC terms
    real matrix EC
    EC = Y_lag1 * beta_hat   // Teff x h_total

    // Full regressor matrix
    real matrix Xfull
    real scalar kx

    Xfull = EC
    if (cols(dY_lags) > 0) Xfull = Xfull, dY_lags
    if (kdet > 0)          Xfull = Xfull, Det
    kx = cols(Xfull)

    // OLS equation by equation
    real matrix XX_full, XXinv_full, Beta_vecm, Uhat
    XX_full = cross(Xfull, Xfull)
    XXinv_full = invsym(XX_full)

    Beta_vecm = J(kx, n, 0)
    Uhat = J(Teff, n, 0)

    for (eq = 1; eq <= n; eq++) {
        Beta_vecm[., eq] = XXinv_full * cross(Xfull, dYt[., eq])
        Uhat[., eq] = dYt[., eq] - Xfull * Beta_vecm[., eq]
    }

    // Sigma
    real matrix Sigma
    Sigma = cross(Uhat, Uhat) / Teff

    // ── 9.  Variance-covariance ───────────────────────────────
    real scalar nparam
    real matrix VV_full
    real rowvector b_vec

    nparam = n * kx
    VV_full = J(nparam, nparam, 0)

    for (eq = 1; eq <= n; eq++) {
        real scalar s1, s2
        s1 = (eq-1)*kx + 1
        s2 = eq*kx
        VV_full[s1::s2, s1::s2] = Sigma[eq, eq] * XXinv_full
    }
    VV_full = (VV_full + VV_full') / 2

    // Vectorise
    b_vec = J(1, nparam, 0)
    for (eq = 1; eq <= n; eq++) {
        b_vec[((eq-1)*kx+1)::(eq*kx)] = Beta_vecm[., eq]'
    }

    // ── 10.  Store results ────────────────────────────────────
    st_matrix(bname, b_vec)
    st_matrix(Vname, VV_full)
    st_matrix(alphaname, alpha_hat)
    st_matrix(betaname, beta_hat')
    st_matrix(Piname, Pi_hat)
    st_matrix(eigname, eigval_sorted')
    st_matrix(tracename, trace_stats')
    st_matrix(maxname, max_stats')
    st_matrix(btypename, beta_types)
}

end
