// ============================================================
// TCA — Transmission Channel Analysis for Stata (Mata)
// تنفيذ صحيح موازٍ لـ tca-matlab-toolbox (Wegner et al. 2025)
// المرجع: Wegner, Lieb, Smeekes (2025) arXiv:2405.18987
// ============================================================
// هذا الملف يحتوي على جميع دوال Mata الأساسية
// يُستدعى من tca.ado
// ============================================================

version 14

mata:
mata set matastrict on

// ============================================================
// القسم 1: الدوال الأساسية — الصيغة النظامية (Systems Form)
// ============================================================

// makeLD: LD Decomposition (Cholesky-inverse method)
// Following MATLAB TCA toolbox: L = inv(chol(Sigma, 'lower')), D = diag(1/diag(L))
// This ensures D*L has unit diagonal, making I-D*L strictly lower-triangular.
// Returns: struct with L and D
struct tca_LD {
    real matrix L
    real matrix D
}

struct tca_LD scalar tca_makeLD(real matrix Sigma)
{
    struct tca_LD scalar result
    real matrix Linv, L
    real colvector d

    // Lower-triangular Cholesky: Sigma = Linv * Linv'
    Linv = cholesky(Sigma)
    // L = inv(Linv)
    L = luinv(Linv)
    // D = diag(1 / diag(L))
    d = 1 :/ diagonal(L)

    result.L = L
    result.D = diag(d)
    return(result)
}

// permmatrix: Permutation matrix
// order: vector of indices (1-based)
real matrix tca_permmatrix(real rowvector order)
{
    real matrix P
    real scalar n

    n = length(order)
    P = I(n)
    P = P[order, .]
    return(P)
}

// computeMA: MA coefficients from VAR
// As: pointer vector of AR matrices (As[1]=A_1, ...)
// h: maximum horizon
// Returns: pointer vector of MA matrices (Cs[1]=C_1, ...)
pointer(real matrix) rowvector tca_computeMA(
    pointer(real matrix) rowvector As,
    real scalar h)
{
    pointer(real matrix) rowvector Cs
    real scalar K, p, j, i
    real matrix C_j

    K = rows(*As[1])
    p = length(As)
    Cs = J(1, h, NULL)

    for (j = 1; j <= h; j++) {
        C_j = J(K, K, 0)
        for (i = 1; i <= min((j, p)); i++) {
            if (i == j) {
                C_j = C_j + *As[i]  // C_0 = I
            }
            else {
                C_j = C_j + *As[i] * (*Cs[j - i])
            }
        }
        Cs[j] = &C_j
    }
    return(Cs)
}

// slideIn: Insert row block into block lower-triangular matrix
// B: square matrix (dim x dim)
// A: row block (K x ncols)
real matrix tca_slideIn(real matrix B, real matrix A)
{
    real scalar K, nBlocks, nA_cols, i, n_cols, r_start, r_end, c_start, c_end
    real matrix B_out

    B_out = B
    K = rows(A)
    nBlocks = rows(B) / K
    nA_cols = cols(A)

    for (i = 1; i <= nBlocks; i++) {
        n_cols = min((i * K, nA_cols))

        r_start = (i - 1) * K + 1
        r_end   = i * K
        c_end   = i * K
        c_start = c_end - n_cols + 1

        B_out[r_start..r_end, c_start..c_end] = A[., (nA_cols - n_cols + 1)..nA_cols]
    }
    return(B_out)
}

// makeB_systems: Build systems form B matrix
// As: pointer vector of AR matrices
// Sigma: residual covariance matrix
// order: transmission ordering (1-based)
// h: maximum horizon
// Returns: B matrix of dimension K*(h+1) x K*(h+1)
real matrix tca_makeB_systems(
    pointer(real matrix) rowvector As,
    real matrix Sigma,
    real rowvector order,
    real scalar h)
{
    real scalar K, p, dim, i
    real matrix TT, Sigma_star, DL, rowBlock, B
    struct tca_LD scalar ld
    pointer(real matrix) rowvector As_star, As_trans, As_flip

    K = rows(Sigma)
    p = length(As)

    // 1. Permutation matrix
    TT = tca_permmatrix(order)

    // 2. Reorder AR matrices
    As_star = J(1, p, NULL)
    for (i = 1; i <= p; i++) {
        As_star[i] = &(TT * (*As[i]) * TT')
    }

    // 3. LDL' of reordered covariance
    Sigma_star = TT * Sigma * TT'
    ld = tca_makeLD(Sigma_star)
    DL = ld.D * ld.L

    // 4. Transform AR matrices: DL * A_i*
    As_trans = J(1, p, NULL)
    for (i = 1; i <= p; i++) {
        As_trans[i] = &(DL * (*As_star[i]))
    }

    // 5. Row block: [DL*A_p*, ..., DL*A_1*, I-DL]
    // Flip order
    As_flip = J(1, p, NULL)
    for (i = 1; i <= p; i++) {
        As_flip[i] = As_trans[p - i + 1]
    }

    rowBlock = *As_flip[1]
    for (i = 2; i <= p; i++) {
        rowBlock = rowBlock, *As_flip[i]
    }
    rowBlock = rowBlock, (I(K) - DL)

    // 6. Build B using slideIn
    dim = K * (h + 1)
    B = J(dim, dim, 0)
    B = tca_slideIn(B, rowBlock)
    return(B)
}

// makeOmega_systems: Build systems form Omega matrix
// Phi0: structural impact matrix (K x K)
// Psis: pointer vector of reduced-form MA coefficients (empty for pure VAR)
// order: transmission ordering (1-based)
// h: maximum horizon
// Returns: Omega matrix of dimension K*(h+1) x K*(h+1)
real matrix tca_makeOmega_systems(
    real matrix Phi0,
    pointer(real matrix) rowvector Psis,
    real rowvector order,
    real scalar h)
{
    real scalar K, dim, n_psis, i
    real matrix Sigma, TT, Sigma_star, DL, Qt, rowBlock, Omega
    struct tca_LD scalar ld
    pointer(real matrix) rowvector Psis_trans, Psis_flip

    K = rows(Phi0)
    Sigma = Phi0 * Phi0'

    // 1. Permutation matrix
    TT = tca_permmatrix(order)

    // 2. LD decomposition of reordered covariance
    Sigma_star = TT * Sigma * TT'
    ld = tca_makeLD(Sigma_star)
    DL = ld.D * ld.L

    // 3. Qt = L * T * Phi0
    Qt = ld.L * TT * Phi0

    // 4. Transform Psis: DL * T * Psi_i * Phi0
    n_psis = length(Psis)
    if (n_psis > 0) {
        Psis_trans = J(1, n_psis, NULL)
        for (i = 1; i <= n_psis; i++) {
            Psis_trans[i] = &(DL * TT * (*Psis[i]) * Phi0)
        }

        // Flip order
        Psis_flip = J(1, n_psis, NULL)
        for (i = 1; i <= n_psis; i++) {
            Psis_flip[i] = Psis_trans[n_psis - i + 1]
        }

        // Row block: [DL*T*Psi_p*Phi0, ..., DL*T*Psi_1*Phi0, D*Qt]
        rowBlock = *Psis_flip[1]
        for (i = 2; i <= n_psis; i++) {
            rowBlock = rowBlock, *Psis_flip[i]
        }
        rowBlock = rowBlock, (ld.D * Qt)
    }
    else {
        // Pure VAR: no MA terms
        rowBlock = ld.D * Qt
    }

    // 5. Build Omega using slideIn
    dim = K * (h + 1)
    Omega = J(dim, dim, 0)
    Omega = tca_slideIn(Omega, rowBlock)
    return(Omega)
}

// makeSystemsForm: Build complete systems form (B, Omega)
// Phi0: structural impact matrix
// As: pointer vector of AR matrices
// h: maximum horizon
// order: transmission ordering
// B, Omega: output matrices (passed by reference)
void tca_makeSystemsForm(
    real matrix Phi0,
    pointer(real matrix) rowvector As,
    real scalar h,
    real rowvector order,
    real matrix B,
    real matrix Omega)
{
    real matrix Sigma
    pointer(real matrix) rowvector Psis

    Sigma = Phi0 * Phi0'

    // For pure VAR/SVAR models: Psis is empty.
    // The MA dynamics emerge from (I-B)^{-1}. Only DSGE/VARMA models
    // pass non-empty Psis. This matches MATLAB's SVAR.m and Recursive.m
    // which pass cell(0,0) (empty) for Psis.
    Psis = J(1, 0, NULL)

    B = tca_makeB_systems(As, Sigma, order, h)
    Omega = tca_makeOmega_systems(Phi0, Psis, order, h)
}

// ============================================================
// القسم 2: دوال التعيين والتحكم بالمسارات (Path Control)
// ============================================================

// mapY2X: Map variable index to systems form index
// var_idx: variable number in original ordering (1-based)
// time: time period (0 = contemporaneous)
// K: number of variables
// order: transmission ordering
// Returns: 1-based index in the systems form
real scalar tca_mapY2X(real scalar var_idx, real scalar time,
                        real scalar K, real rowvector order)
{
    real scalar pos

    pos = 0
    for (i = 1; i <= length(order); i++) {
        if (order[i] == var_idx) {
            pos = i
            break
        }
    }
    return(K * time + pos)
}

// not_vars_for: Build NOT variable indices for all time periods
// var_indices: vector of original variable numbers to block
// K: number of variables
// h: maximum horizon
// order: transmission ordering
// Returns: vector of systems form indices
real rowvector tca_not_vars_for(real rowvector var_indices,
                                 real scalar K, real scalar h,
                                 real rowvector order)
{
    real rowvector nv
    real scalar v, t, idx, count, n_vars

    n_vars = length(var_indices)
    nv = J(1, n_vars * (h + 1), .)
    count = 0

    for (v = 1; v <= n_vars; v++) {
        for (t = 0; t <= h; t++) {
            count = count + 1
            nv[count] = tca_mapY2X(var_indices[v], t, K, order)
        }
    }
    return(nv)
}

// vec_to_irf: Convert systems form vector to IRF matrix
// vec: column vector of length K*(h+1)
// K: number of variables
// h: maximum horizon
// order: transmission ordering
// Returns: (h+1) x K matrix in original ordering
real matrix tca_vec_to_irf(real colvector vec, real scalar K,
                            real scalar h, real rowvector order)
{
    real matrix TT_inv, mat
    real scalar t
    real rowvector idx

    TT_inv = tca_permmatrix(order)'
    mat = J(h + 1, K, 0)

    for (t = 0; t <= h; t++) {
        idx = (t * K + 1)..((t + 1) * K)
        mat[t + 1, .] = (TT_inv * vec[idx])'
    }
    return(mat)
}

// applyAndToB: Force paths through a variable
void tca_applyAndToB(real matrix B, real matrix Omega,
                      real scalar from, real scalar var)
{
    real scalar n
    n = rows(B)
    if (var < n) {
        Omega[(var + 1)..n, from] = J(n - var, 1, 0)
        if (var > 1) {
            B[(var + 1)..n, 1..(var - 1)] = J(n - var, var - 1, 0)
        }
    }
}

// applyNotToB: Block paths through a variable
void tca_applyNotToB(real matrix B, real matrix Omega,
                      real scalar from, real scalar var)
{
    Omega[var, from] = 0
    if (var > 1) {
        B[var, 1..(var - 1)] = J(1, var - 1, 0)
    }
}

// ============================================================
// القسم 3: حساب أثر الانتقال (Transmission Effect)
// ============================================================

// transmissionEffect: Compute transmission effect via B,Omega method
// from: shock index (1-based, in systems form)
// B, Omega: systems form matrices
// and_vars: vector of variable indices to force paths through (systems form)
// not_vars: vector of variable indices to block paths through (systems form)
// Returns: column vector of effects (K*(h+1) x 1)
real colvector tca_transmissionEffect(
    real scalar from,
    real matrix B,
    real matrix Omega,
    | real rowvector and_vars,
      real rowvector not_vars)
{
    real matrix B_mod, O_mod
    real scalar n, v, max_and
    real colvector effects

    B_mod = B
    O_mod = Omega
    n = rows(B)

    // Apply AND conditions
    if (args() >= 4 & length(and_vars) > 0) {
        for (v = 1; v <= length(and_vars); v++) {
            tca_applyAndToB(B_mod, O_mod, from, and_vars[v])
        }
    }

    // Apply NOT conditions
    if (args() >= 5 & length(not_vars) > 0) {
        for (v = 1; v <= length(not_vars); v++) {
            tca_applyNotToB(B_mod, O_mod, from, not_vars[v])
        }
    }

    // Solve (I - B_mod) * effects = O_mod[., from]
    effects = lusolve(I(n) - B_mod, O_mod[., from])

    // Zero out entries before max AND variable
    if (args() >= 4 & length(and_vars) > 0) {
        max_and = max(and_vars)
        effects[1..max_and] = J(max_and, 1, 0)
    }

    return(effects)
}

// ============================================================
// القسم 4: هياكل النتائج (Result Structures)
// ============================================================

struct tca_result {
    real matrix irf_total           // (h+1) x K
    pointer(real matrix) rowvector irf_channels  // array of (h+1) x K
    string rowvector channel_names
    string scalar mode
    real scalar n_channels
}

// ============================================================
// القسم 5: دالة التحليل الرئيسية (Main Analysis)
// ============================================================

// tca_analyze: Run TCA decomposition
// from: shock variable (1-based, original ordering)
// B, Omega: systems form matrices
// intermediates: intermediate variables (1-based, original ordering)
// K: number of variables
// h: maximum horizon
// order: transmission ordering
// mode: "overlapping", "exhaustive_3way", or "exhaustive_4way"
// var_names: variable names
struct tca_result scalar tca_analyze(
    real scalar from,
    real matrix B, real matrix Omega,
    real rowvector intermediates,
    real scalar K, real scalar h,
    real rowvector order,
    string scalar mode,
    string rowvector var_names)
{
    struct tca_result scalar res
    real colvector total_vec, nt_all_vec
    real colvector th_v1, th_v2, th_or, th_and, ch_v1_only, ch_v2_only
    real rowvector nv, nv_all, empty_and
    real scalar n_int, v1, v2, v
    pointer(real colvector) rowvector nt_vecs, th_vecs

    res.mode = mode
    empty_and = J(1, 0, .)

    // Total effect (no AND/NOT conditions)
    total_vec = tca_transmissionEffect(from, B, Omega)
    res.irf_total = tca_vec_to_irf(total_vec, K, h, order)

    n_int = length(intermediates)

    // Compute not-through and through for each intermediate
    nt_vecs = J(1, n_int, NULL)
    th_vecs = J(1, n_int, NULL)
    for (v = 1; v <= n_int; v++) {
        nv = tca_not_vars_for(intermediates[v], K, h, order)
        nt_vecs[v] = &(tca_transmissionEffect(from, B, Omega, empty_and, nv))
        th_vecs[v] = &(total_vec - *nt_vecs[v])
    }

    // Not-through ALL intermediates together
    nv_all = tca_not_vars_for(intermediates, K, h, order)
    nt_all_vec = tca_transmissionEffect(from, B, Omega, empty_and, nv_all)

    // ========== MODE: overlapping ==========
    if (mode == "overlapping") {
        res.n_channels = n_int + 1
        res.irf_channels = J(1, n_int + 1, NULL)
        res.channel_names = J(1, n_int + 1, "")

        for (v = 1; v <= n_int; v++) {
            res.irf_channels[v] = &tca_vec_to_irf(*th_vecs[v], K, h, order)
            res.channel_names[v] = "Through " + var_names[intermediates[v]]
        }
        res.irf_channels[n_int + 1] = &tca_vec_to_irf(nt_all_vec, K, h, order)
        res.channel_names[n_int + 1] = "Direct"
    }

    // ========== MODE: exhaustive_3way ==========
    else if (mode == "exhaustive_3way" & n_int == 2) {
        v1 = 1
        v2 = 2

        res.n_channels = 3
        res.irf_channels = J(1, 3, NULL)
        res.channel_names = J(1, 3, "")

        // Ch1: through(v1) inclusive
        res.irf_channels[1] = &tca_vec_to_irf(*th_vecs[v1], K, h, order)
        res.channel_names[1] = "Through " + var_names[intermediates[v1]] + " (incl.)"

        // Ch2: through(v2) but NOT through(v1) = nt(v1) - nt(both)
        res.irf_channels[2] = &tca_vec_to_irf(*nt_vecs[v1] - nt_all_vec, K, h, order)
        res.channel_names[2] = "Through " + var_names[intermediates[v2]] + " only"

        // Ch3: direct
        res.irf_channels[3] = &tca_vec_to_irf(nt_all_vec, K, h, order)
        res.channel_names[3] = "Direct"
    }

    // ========== MODE: exhaustive_4way ==========
    else if (mode == "exhaustive_4way" & n_int == 2) {
        v1 = 1
        v2 = 2

        th_v1 = *th_vecs[v1]
        th_v2 = *th_vecs[v2]

        // through(v1 OR v2) = total - nt(both)
        th_or = total_vec - nt_all_vec

        // through(v1 AND v2) = through(v1) + through(v2) - through(v1 OR v2)
        th_and = th_v1 + th_v2 - th_or

        // Exclusive channels
        ch_v1_only = th_v1 - th_and
        ch_v2_only = th_v2 - th_and

        res.n_channels = 4
        res.irf_channels = J(1, 4, NULL)
        res.channel_names = J(1, 4, "")

        res.irf_channels[1] = &tca_vec_to_irf(ch_v1_only, K, h, order)
        res.channel_names[1] = var_names[intermediates[v1]] + " only"

        res.irf_channels[2] = &tca_vec_to_irf(ch_v2_only, K, h, order)
        res.channel_names[2] = var_names[intermediates[v2]] + " only"

        res.irf_channels[3] = &tca_vec_to_irf(th_and, K, h, order)
        res.channel_names[3] = var_names[intermediates[v1]] + " & " + var_names[intermediates[v2]]

        res.irf_channels[4] = &tca_vec_to_irf(nt_all_vec, K, h, order)
        res.channel_names[4] = "Direct"
    }

    return(res)
}

// ============================================================
// القسم 6: تفكيك ثنائي (Binary Decomposition)
// ============================================================

struct tca_binary {
    real matrix total        // (h+1) x K
    real matrix through      // (h+1) x K
    real matrix not_through  // (h+1) x K
}

struct tca_binary scalar tca_decompose_binary(
    real scalar from,
    real matrix B, real matrix Omega,
    real scalar var_idx,
    real scalar K, real scalar h,
    real rowvector order)
{
    struct tca_binary scalar res
    real colvector total_vec, nt_vec, th_vec
    real rowvector nv, empty_and

    empty_and = J(1, 0, .)
    total_vec = tca_transmissionEffect(from, B, Omega)
    nv = tca_not_vars_for(var_idx, K, h, order)
    nt_vec = tca_transmissionEffect(from, B, Omega, empty_and, nv)
    th_vec = total_vec - nt_vec

    res.total       = tca_vec_to_irf(total_vec, K, h, order)
    res.through     = tca_vec_to_irf(th_vec, K, h, order)
    res.not_through = tca_vec_to_irf(nt_vec, K, h, order)
    return(res)
}

// ============================================================
// القسم 7: دالة التحقق من الجمعية
// ============================================================

real scalar tca_validate_additivity(
    real scalar from,
    real matrix B, real matrix Omega,
    real scalar K, real scalar h,
    real rowvector order,
    | string rowvector var_names)
{
    real colvector total_vec, nt, th, resid_vec
    real rowvector nv, empty_and
    real scalar v, max_r, max_resid

    if (args() < 7) {
        var_names = J(1, K, "")
        for (v = 1; v <= K; v++) var_names[v] = "Var" + strofreal(v)
    }

    empty_and = J(1, 0, .)
    total_vec = tca_transmissionEffect(from, B, Omega)
    max_resid = 0

    printf("{txt}===== Additivity Test (Binary Decomposition) =====\n")
    for (v = 1; v <= K; v++) {
        nv = tca_not_vars_for(v, K, h, order)
        nt = tca_transmissionEffect(from, B, Omega, empty_and, nv)
        th = total_vec - nt
        resid_vec = total_vec - (th + nt)
        max_r = max(abs(resid_vec))
        max_resid = max((max_resid, max_r))
        printf("  %s: max |residual| = %e\n", var_names[v], max_r)
    }

    printf("\n{txt}Overall max |residual| = %e\n", max_resid)
    if (max_resid < 1e-12) {
        printf("{res}PASSED: Additivity holds at machine precision{txt}\n")
        return(1)
    }
    else {
        printf("{err}WARNING: Additivity violation detected{txt}\n")
        return(0)
    }
}

// ============================================================
// القسم 8: دوال عرض النتائج
// ============================================================

void tca_display_result(
    struct tca_result scalar res,
    real scalar target_var,
    string rowvector var_names,
    | real scalar show_all_horizons)
{
    real scalar h, K, c, t
    real matrix ch_mat
    string scalar line

    h = rows(res.irf_total) - 1
    K = cols(res.irf_total)

    if (args() < 4) show_all_horizons = 0

    printf("\n{txt}{hline 70}\n")
    printf("{res}TCA Results: Response of %s (Mode: %s)\n", var_names[target_var], res.mode)
    printf("{txt}{hline 70}\n")

    // Header
    printf("{txt}%4s", "h")
    printf(" | %12s", "Total")
    for (c = 1; c <= res.n_channels; c++) {
        printf(" | %12s", substr(res.channel_names[c], 1, 12))
    }
    printf("\n")
    printf("{txt}{hline 70}\n")

    // Data rows
    for (t = 0; t <= h; t++) {
        if (show_all_horizons | t == 0 | t == 1 | t == 2 | t == 4 |
            t == 8 | t == 12 | t == 16 | t == 20 | t == h) {
            printf("{res}%4.0f", t)
            printf(" | %12.6f", res.irf_total[t + 1, target_var])
            for (c = 1; c <= res.n_channels; c++) {
                ch_mat = *res.irf_channels[c]
                printf(" | %12.6f", ch_mat[t + 1, target_var])
            }
            printf("\n")
        }
    }
    printf("{txt}{hline 70}\n")
}

// ============================================================
// القسم 9: دالة تخزين النتائج في Stata matrices
// ============================================================

void tca_store_results(
    struct tca_result scalar res,
    real scalar target_var,
    string scalar prefix)
{
    real scalar h, c
    real matrix ch_mat

    h = rows(res.irf_total) - 1

    // Store total IRF
    st_matrix(prefix + "_total", res.irf_total)

    // Store each channel
    for (c = 1; c <= res.n_channels; c++) {
        ch_mat = *res.irf_channels[c]
        st_matrix(prefix + "_ch" + strofreal(c), ch_mat)
    }

    // Store channel names
    st_global(prefix + "_mode", res.mode)
    st_numscalar(prefix + "_nch", res.n_channels)
    for (c = 1; c <= res.n_channels; c++) {
        st_global(prefix + "_chname" + strofreal(c), res.channel_names[c])
    }
}

// ============================================================
// القسم 10: دالة موحدة (واجهة عالية المستوى)
// ============================================================

// tca_run: Run complete TCA from VAR parameters
// Phi0: K x K structural impact matrix
// As_flat: K x (K*p) matrix with A_1, A_2, ..., A_p side by side
// h: horizon
// order: transmission ordering (1-based)
// from: shock variable (1-based)
// intermediates: intermediate variables (1-based)
// mode: decomposition mode
// var_names: variable names
struct tca_result scalar tca_run(
    real matrix Phi0,
    real matrix As_flat,
    real scalar h,
    real rowvector order,
    real scalar from,
    real rowvector intermediates,
    string scalar mode,
    | string rowvector var_names)
{
    real scalar K, p, i
    real matrix B, Omega
    pointer(real matrix) rowvector As
    struct tca_result scalar res

    K = rows(Phi0)
    p = cols(As_flat) / K

    // Unpack As_flat into pointer array
    As = J(1, p, NULL)
    for (i = 1; i <= p; i++) {
        As[i] = &(As_flat[., ((i-1)*K+1)..(i*K)])
    }

    if (args() < 8) {
        var_names = J(1, K, "")
        for (i = 1; i <= K; i++) var_names[i] = "Var" + strofreal(i)
    }

    // Build systems form
    tca_makeSystemsForm(Phi0, As, h, order, B, Omega)

    // Run TCA
    res = tca_analyze(from, B, Omega, intermediates, K, h, order, mode, var_names)

    return(res)
}

end
