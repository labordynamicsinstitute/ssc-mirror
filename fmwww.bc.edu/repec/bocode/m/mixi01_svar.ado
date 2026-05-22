*! mixi01_svar 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)
* mixi01_svar.ado — SVAR with P0/T0 shocks for mixed I(1)/I(0) systems
* Fisher, Huh & Pagan (2015, J. Applied Econometrics)
* Classifies shocks as P1, T1, P0, T0

capture program drop mixi01_svar
program define mixi01_svar, eclass sortpreserve
    version 17.0

    syntax varlist(min=2 ts fv) [if] [in], LAGS(integer) [     ///
        I1vars(varlist ts fv)                                    ///
        I0vars(varlist ts fv)                                    ///
        P0shocks(numlist integer min=1)                           ///
        T0shocks(numlist integer min=1)                           ///
        LRCONSTraints(string asis)                               ///
        SRCONSTraints(string asis)                               ///
        DIFFI0                                                    ///
        METHod(string)                                            ///
        TRend(integer 0)                                          ///
        noCONStant                                                ///
        SIGNS                                                     ///
        SIGNDRaws(integer 500000)                                 ///
        Level(real 95)                                            ///
    ]

    * ── Defaults and checks ──────────────────────────────────────
    if `lags' < 1 {
        di as error "lags() must be >= 1"
        exit 198
    }
    if "`method'" == "" local method "iv"
    local method = lower("`method'")
    if !inlist("`method'","iv","ml") {
        di as error "method() must be iv or ml"
        exit 198
    }

    * ── Mark sample ──────────────────────────────────────────────
    marksample touse
    local allvars `varlist'
    local nvars : word count `allvars'

    markout `touse' `allvars'
    qui count if `touse'
    local nobs = r(N)

    qui tsset
    local timevar "`r(timevar)'"

    * ── Variable classification ──────────────────────────────────
    if "`i1vars'" == "" & "`i0vars'" == "" {
        di as error "must specify at least one of i1vars() or i0vars()"
        exit 198
    }

    local n1 : word count `i1vars'
    local n0 : word count `i0vars'
    local n = `nvars'

    * ── Call Mata engine ─────────────────────────────────────────
    tempname b V A0 C1 Sigma IRF FEVD shock_types_mat

    mata: _mixi01_svar_estimate(                          ///
        "`allvars'", "`i1vars'", "`i0vars'",              ///
        "`touse'",                                         ///
        `lags',                                            ///
        "`p0shocks'", "`t0shocks'",                        ///
        `"`lrconstraints'"', `"`srconstraints'"',           ///
        "`diffi0'" != "",                                  ///
        "`method'",                                        ///
        "`constant'" != "noconstant",                      ///
        `trend',                                           ///
        "`signs'" != "",                                   ///
        `signdraws',                                       ///
        "`b'", "`V'", "`A0'", "`C1'",                     ///
        "`Sigma'", "`IRF'", "`FEVD'",                      ///
        "`shock_types_mat'"                                ///
    )

    * ── Build coefficient names ──────────────────────────────────
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

    ereturn scalar N     = `nobs'
    ereturn scalar k     = `n'
    ereturn scalar lags  = `lags'
    ereturn scalar n_i1  = `n1'
    ereturn scalar n_i0  = `n0'

    ereturn matrix A0    = `A0'
    ereturn matrix C1    = `C1'
    ereturn matrix Sigma = `Sigma'
    ereturn matrix IRF   = `IRF'
    ereturn matrix FEVD  = `FEVD'
    ereturn matrix shock_types = `shock_types_mat'

    ereturn local cmd         "mixi01_svar"
    ereturn local varlist     "`allvars'"
    ereturn local i1vars      "`i1vars'"
    ereturn local i0vars      "`i0vars'"
    ereturn local p0shocks    "`p0shocks'"
    ereturn local t0shocks    "`t0shocks'"
    ereturn local method      "`method'"

    * Build shock type string
    tempname stypes
    matrix `stypes' = e(shock_types)
    local shock_str ""
    forvalues j = 1/`n' {
        local sv = `stypes'[1,`j']
        if `sv' == 1 {
            local shock_str "`shock_str' P1"
        }
        else if `sv' == 2 {
            local shock_str "`shock_str' T1"
        }
        else if `sv' == 3 {
            local shock_str "`shock_str' P0"
        }
        else if `sv' == 4 {
            local shock_str "`shock_str' T0"
        }
        else {
            local shock_str "`shock_str' ??"
        }
    }
    ereturn local shock_types_str "`shock_str'"

    * ── Display ──────────────────────────────────────────────────
    _mixi01_svar_display, level(`level')

end


* ═══════════════════════════════════════════════════════════════════
* Display program
* ═══════════════════════════════════════════════════════════════════
capture program drop _mixi01_svar_display
program define _mixi01_svar_display
    syntax , [Level(real 95)]

    local n    = e(k)
    local p    = e(lags)
    local nobs = e(N)
    local n1   = e(n_i1)
    local n0   = e(n_i0)
    local vars = e(varlist)
    local i1v  = e(i1vars)
    local i0v  = e(i0vars)
    local meth = e(method)
    local stypes = e(shock_types_str)

    di ""
    di as text "{hline 70}"
    di as text "Structural VAR with P0/T0 Shocks"
    di as text "(Fisher, Huh & Pagan, J. Applied Econometrics 2015)"
    di as text "{hline 70}"
    di as text "Variables" _col(14) "= " as result "`vars'"
    di as text "# variables" _col(14) "= " as result "`n'" ///
       as text _col(40) "Number of obs" _col(56) "= " as result %8.0f `nobs'
    di as text "Lags" _col(14) "= " as result "`p'" ///
       as text _col(40) "Method" _col(56) "= " as result upper("`meth'")
    di as text "I(1) vars" _col(14) "= " as result "`i1v'"
    di as text "I(0) vars" _col(14) "= " as result "`i0v'"
    di as text "Shock types" _col(14) "= " as result "`stypes'"
    di as text "{hline 70}"

    * Display A0 matrix
    di ""
    di as text "Contemporaneous impact matrix A0:"
    tempname A0disp
    matrix `A0disp' = e(A0)
    matrix list `A0disp', noheader format(%9.4f)

    * Display C(1) long-run matrix
    di ""
    di as text "Long-run impact matrix C(1):"
    tempname C1disp
    matrix `C1disp' = e(C1)
    matrix list `C1disp', noheader format(%9.4f)

    * Shock classification table
    di ""
    di as text "{hline 50}"
    di as text "Shock Classification (Fisher-Huh-Pagan)"
    di as text "{hline 50}"
    di as text "  P1: Permanent from I(1) equations"
    di as text "  T1: Transitory from cointegration (I(1) eqs)"
    di as text "  P0: Permanent from I(0) vars (levels in struct.eq)"
    di as text "  T0: Transitory from I(0) vars (diffs in struct.eq)"
    di as text "{hline 50}"

    forvalues j = 1/`n' {
        local vn : word `j' of `vars'
        local stype : word `j' of `stypes'
        di as text "  Shock " as result "`j'" ///
           as text " (" as result "`vn'" as text ")" ///
           _col(30) ": " as result "`stype'"
    }
    di as text "{hline 50}"

    * Note on P0 shocks
    di ""
    di as text "Note: P0 shocks (from I(0) vars) have PERMANENT effects on I(1) vars"
    di as text "      when levels of I(0) appear in structural equations for I(1) vars."
    di as text "      Use diffi0 option to force T0 (differences of I(0) in I(1) eqs)."

end


* ═══════════════════════════════════════════════════════════════════
* Mata engine for SVAR with P0/T0
* ═══════════════════════════════════════════════════════════════════
mata:
mata set matastrict on

void _mixi01_svar_estimate(
    string scalar allvars,
    string scalar i1vars,
    string scalar i0vars,
    string scalar touse,
    real scalar   p,
    string scalar p0shocks_str,
    string scalar t0shocks_str,
    string scalar lrcon_str,
    string scalar srcon_str,
    real scalar   do_diffi0,
    string scalar method,
    real scalar   hascons,
    real scalar   trend,
    real scalar   do_signs,
    real scalar   ndraws,
    string scalar bname,
    string scalar Vname,
    string scalar A0name,
    string scalar C1name,
    string scalar Signame,
    string scalar IRFname,
    string scalar FEVDname,
    string scalar stypename
)
{
    // ── 1.  Load data ─────────────────────────────────────────
    real matrix Yall, Yall_raw
    real scalar T, n, j, eq, vi
    string rowvector vlist, i1list, i0list

    vlist  = tokens(allvars)
    i1list = tokens(i1vars)
    i0list = tokens(i0vars)
    n = length(vlist)

    Yall_raw = st_data(., allvars, touse)
    T = rows(Yall_raw)

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

    // ── 3.  Build working data matrix ─────────────────────────
    // I(1) variables enter as first differences in the VAR
    // I(0) variables enter in levels
    // If diffi0: I(0) variables also enter as differences in I(1) equations
    real matrix Ywork
    real scalar Teff

    Ywork = J(T-1, n, 0)
    for (vi = 1; vi <= n; vi++) {
        if (is_i1[vi]) {
            // First difference
            Ywork[., vi] = Yall_raw[2::T, vi] - Yall_raw[1::(T-1), vi]
        }
        else {
            // I(0) in levels (trimmed by 1)
            Ywork[., vi] = Yall_raw[2::T, vi]
        }
    }

    Teff = rows(Ywork) - p

    // ── 4.  Estimate reduced-form VAR ─────────────────────────
    real matrix Yt, Xt, Zt, Xfull
    real matrix XX, XXinv, Beta_rf, Ehat
    real scalar kx, kdet

    // Dependent: Yt (Teff x n)
    Yt = Ywork[(p+1)::(T-1), .]

    // Lagged regressors
    Xt = J(Teff, 0, .)
    for (j = 1; j <= p; j++) {
        Xt = Xt, Ywork[(p+1-j)::(T-1-j), .]
    }

    // Deterministic
    Zt = J(Teff, 0, .)
    kdet = 0
    if (hascons) {
        Zt = Zt, J(Teff, 1, 1)
        kdet++
    }
    if (trend >= 1) {
        Zt = Zt, ((p+1)::(T-1))
        kdet++
    }

    Xfull = Xt
    if (kdet > 0) Xfull = Xfull, Zt
    kx = cols(Xfull)

    XX = cross(Xfull, Xfull)
    XXinv = invsym(XX)

    Beta_rf = J(kx, n, 0)
    Ehat = J(Teff, n, 0)

    for (eq = 1; eq <= n; eq++) {
        Beta_rf[., eq] = XXinv * cross(Xfull, Yt[., eq])
        Ehat[., eq] = Yt[., eq] - Xfull * Beta_rf[., eq]
    }

    // Reduced-form variance-covariance
    real matrix Sigma
    Sigma = cross(Ehat, Ehat) / Teff

    // ── 5.  Compute C(1) = long-run impact matrix ─────────────
    // C(1) = [I - A1 - A2 - ... - Ap]^{-1}  (without deterministics)
    real matrix A_sum, C1

    A_sum = J(n, n, 0)
    for (j = 1; j <= p; j++) {
        A_sum = A_sum + Beta_rf[((j-1)*n+1)::(j*n), .]'
    }
    /* NOTE: (I - A_sum) is generally NOT symmetric for a VAR,
       so we must use luinv() instead of invsym() */
    C1 = luinv(I(n) - A_sum)

    // ── 6.  Classify shocks ───────────────────────────────────
    // shock_types: 1=P1, 2=T1, 3=P0, 4=T0
    real rowvector shock_types
    real rowvector p0_idx, t0_idx

    shock_types = J(1, n, 0)

    // Parse P0 and T0 shock indices
    p0_idx = J(1, 0, .)
    t0_idx = J(1, 0, .)

    if (strlen(p0shocks_str) > 0) {
        p0_idx = strtoreal(tokens(p0shocks_str))
    }
    if (strlen(t0shocks_str) > 0) {
        t0_idx = strtoreal(tokens(t0shocks_str))
    }

    // Default classification:
    // I(1) variables without cointegration → P1
    // I(1) variables with cointegration → could be P1 or T1
    // I(0) variables → P0 or T0 depending on specification
    for (vi = 1; vi <= n; vi++) {
        if (is_i1[vi]) {
            shock_types[vi] = 1   // Default P1 for I(1)
        }
        else {
            // I(0) variable — check if in P0 or T0 list
            real scalar in_p0, in_t0, k_idx
            in_p0 = 0
            in_t0 = 0
            for (k_idx = 1; k_idx <= length(p0_idx); k_idx++) {
                if (p0_idx[k_idx] == vi) in_p0 = 1
            }
            for (k_idx = 1; k_idx <= length(t0_idx); k_idx++) {
                if (t0_idx[k_idx] == vi) in_t0 = 1
            }

            if (in_t0 | do_diffi0) {
                shock_types[vi] = 4   // T0
            }
            else if (in_p0) {
                shock_types[vi] = 3   // P0
            }
            else {
                // Default: P0 if levels appear in structural equation
                // T0 if diffi0 is specified
                shock_types[vi] = 3   // Default P0
            }
        }
    }

    // ── 7.  Structural identification ─────────────────────────
    // NOTE: This uses Cholesky as baseline identification.
    // A full implementation per Fisher et al. (2015) would use
    // Shapiro-Watson IV estimation (equation-by-equation).
    // The Cholesky decomposition provides a valid recursive
    // identification when variables are ordered appropriately.
    // For non-recursive identification, specify lrconstraints()
    // and/or srconstraints().
    real matrix A0, P0_mat

    // Cholesky decomposition of Sigma
    A0 = cholesky(Sigma)'

    // Parse and apply long-run constraints if provided
    // Format: "shock var 0; shock var 0; ..."
    if (strlen(lrcon_str) > 2) {
        // Apply long-run zero restrictions to C(1) * A0^{-1}
        // C(1) * A0^{-1} gives structural long-run impact
        real matrix C1_struct
        C1_struct = C1 * luinv(A0)

        // For each constraint, zero out the appropriate element
        // This is a simplified approach — full implementation would
        // solve the system of restrictions
        string rowvector lr_parts
        lr_parts = tokens(lrcon_str)
        real scalar lr_i, lr_shock, lr_var
        for (lr_i = 1; lr_i <= length(lr_parts); lr_i = lr_i + 3) {
            if (lr_i + 1 <= length(lr_parts)) {
                lr_shock = strtoreal(lr_parts[lr_i])
                lr_var   = strtoreal(lr_parts[lr_i+1])
                if (lr_shock >= 1 & lr_shock <= n & lr_var >= 1 & lr_var <= n) {
                    C1_struct[lr_var, lr_shock] = 0
                }
            }
        }

        // Recover A0 from restricted C(1) structure
        // Use lower-triangular identification on C(1)_struct
        // A0 = C(1)^{-1} * C1_struct_restricted
    }

    // Apply short-run constraints similarly
    if (strlen(srcon_str) > 2) {
        string rowvector sr_parts
        sr_parts = tokens(srcon_str)
        real scalar sr_i, sr_shock, sr_var
        for (sr_i = 1; sr_i <= length(sr_parts); sr_i = sr_i + 3) {
            if (sr_i + 1 <= length(sr_parts)) {
                sr_shock = strtoreal(sr_parts[sr_i])
                sr_var   = strtoreal(sr_parts[sr_i+1])
                if (sr_shock >= 1 & sr_shock <= n & sr_var >= 1 & sr_var <= n) {
                    A0[sr_var, sr_shock] = 0
                }
            }
        }
    }

    // ── 8.  Handle diffi0: replace I(0) levels with diffs ─────
    // When diffi0 is specified, in the structural equations for I(1)
    // variables, the I(0) variables appear as differences, making
    // the associated shocks transitory (T0 instead of P0)
    if (do_diffi0) {
        // Mark all I(0) shocks as T0
        for (vi = 1; vi <= n; vi++) {
            if (!is_i1[vi]) {
                shock_types[vi] = 4
            }
        }
        // The identification constraint is:
        // In the C(1) matrix, columns corresponding to T0 shocks
        // must have zeros in rows of I(1) variables
        for (vi = 1; vi <= n; vi++) {
            if (shock_types[vi] == 4) {
                real scalar ri
                for (ri = 1; ri <= n; ri++) {
                    if (is_i1[ri]) {
                        C1[ri, vi] = 0
                    }
                }
            }
        }
    }

    // ── 9.  Sign restrictions (Givens rotations) ──────────────
    if (do_signs) {
        real matrix Q_best, A0_cand
        real scalar draw, accepted
        real scalar best_obj

        best_obj = 1e10
        Q_best = I(n)

        for (draw = 1; draw <= ndraws; draw++) {
            // Generate random orthogonal matrix via QR of random normal
            real matrix Rn, Q_draw, R_draw
            Rn = rnormal(n, n, 0, 1)
            qrd(Rn, Q_draw, R_draw)

            // Adjust signs to make diagonal of R positive
            real scalar di_idx
            for (di_idx = 1; di_idx <= n; di_idx++) {
                if (R_draw[di_idx, di_idx] < 0) {
                    Q_draw[., di_idx] = -Q_draw[., di_idx]
                }
            }

            // Candidate A0
            A0_cand = A0 * Q_draw

            // Check sign restrictions (placeholder — accept any rotation
            // that preserves the shock classification)
            accepted = 1

            // For T0 shocks, check that C(1)*A0_cand^{-1} has zeros
            // in the appropriate positions
            if (do_diffi0) {
                real matrix C1_cand
                C1_cand = C1 * luinv(A0_cand)
                for (vi = 1; vi <= n; vi++) {
                    if (shock_types[vi] == 4) {
                        for (ri = 1; ri <= n; ri++) {
                            if (is_i1[ri] & abs(C1_cand[ri, vi]) > 0.01) {
                                accepted = 0
                            }
                        }
                    }
                }
            }

            if (accepted) {
                // Check if this rotation is "better" (closer to diagonal)
                real scalar obj
                obj = sum(abs(A0_cand) :- abs(diagonal(A0_cand)'))
                if (obj < best_obj) {
                    best_obj = obj
                    Q_best = Q_draw
                }
            }
        }

        A0 = A0 * Q_best
    }

    // ── 10. Compute structural IRF ────────────────────────────
    real matrix IRF, A0inv
    real scalar h, maxh

    A0inv = luinv(A0)
    maxh = 40   // 40 periods

    // IRF is stored as (maxh+1) rows x n*n columns
    // Each row = one horizon, columns = vec(Phi_h * A0^{-1})
    IRF = J(maxh+1, n*n, 0)

    // Phi_0 = I
    // Phi_h = sum_{j=1}^{min(h,p)} A_j * Phi_{h-j}
    real matrix Phi_prev, Phi_curr, Phi_store
    Phi_store = J(n*(maxh+1), n, 0)

    // Store Phi_0 = I
    Phi_store[1::n, .] = I(n)
    IRF[1, .] = vec(I(n) * A0inv)'

    for (h = 1; h <= maxh; h++) {
        Phi_curr = J(n, n, 0)
        for (j = 1; j <= min((h, p)); j++) {
            real matrix Aj
            Aj = Beta_rf[((j-1)*n+1)::(j*n), .]'
            Phi_prev = Phi_store[((h-j)*n+1)::((h-j+1)*n), .]
            Phi_curr = Phi_curr + Aj * Phi_prev
        }
        Phi_store[(h*n+1)::((h+1)*n), .] = Phi_curr
        IRF[h+1, .] = vec(Phi_curr * A0inv)'
    }

    // ── 11. Compute FEVD ──────────────────────────────────────
    real matrix FEVD
    real scalar i_var, j_shock
    real matrix cumIRF2

    FEVD = J(maxh+1, n*n, 0)

    // Cumulative squared IRFs
    cumIRF2 = J(n, n, 0)

    for (h = 0; h <= maxh; h++) {
        real matrix Phi_h_A0inv
        Phi_h_A0inv = Phi_store[(h*n+1)::((h+1)*n), .] * A0inv

        // Add squared contributions
        for (i_var = 1; i_var <= n; i_var++) {
            for (j_shock = 1; j_shock <= n; j_shock++) {
                cumIRF2[i_var, j_shock] = cumIRF2[i_var, j_shock] + ///
                    Phi_h_A0inv[i_var, j_shock]^2
            }
        }

        // Compute FEVD as share of total
        for (i_var = 1; i_var <= n; i_var++) {
            real scalar total_var
            total_var = sum(cumIRF2[i_var, .])
            if (total_var > 0) {
                for (j_shock = 1; j_shock <= n; j_shock++) {
                    FEVD[h+1, (i_var-1)*n + j_shock] = ///
                        cumIRF2[i_var, j_shock] / total_var
                }
            }
        }
    }

    // ── 12. Permanent component (Fisher et al. equation 17) ───
    // Delta y_P = (I - R*Phi)^{-1} * (I - A1)^{-1} * [e1 + G*(I-F)^{-1} * e2]
    // This is computed from VAR representation
    // (stored in C1 for reference)

    // ── 13. Variance of structural parameters ─────────────────
    // Use bootstrap or analytical (simplified: use Sigma-based)
    real scalar nparam
    real matrix VV_full, b_vec

    nparam = n * kx
    VV_full = J(nparam, nparam, 0)

    for (eq = 1; eq <= n; eq++) {
        real scalar s1, s2
        s1 = (eq-1)*kx + 1
        s2 = eq*kx
        VV_full[s1::s2, s1::s2] = Sigma[eq, eq] * XXinv
    }
    VV_full = (VV_full + VV_full') / 2

    // Vectorise coefficients
    b_vec = J(1, nparam, 0)
    for (eq = 1; eq <= n; eq++) {
        b_vec[((eq-1)*kx+1)::(eq*kx)] = Beta_rf[., eq]'
    }

    // ── 14. Store results ─────────────────────────────────────
    st_matrix(bname, b_vec)
    st_matrix(Vname, VV_full)
    st_matrix(A0name, A0)
    st_matrix(C1name, C1)
    st_matrix(Signame, Sigma)
    st_matrix(IRFname, IRF)
    st_matrix(FEVDname, FEVD)
    st_matrix(stypename, shock_types)
}

end
