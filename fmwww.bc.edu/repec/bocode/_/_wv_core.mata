*! MODWT/DWT/MRA Core Engine — lwavelet package
*! Implements: MODWT, iMODWT, DWT, iDWT, MRA
*! Based on: wavelets R package (Aldrich 2020), Percival & Walden (2000)
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
version 11
mata:
mata set matastrict on

// ═══════════════════════════════════════════════════════════════════════════
// STRUCT DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

struct _wv_modwt_r {
    real matrix    W       // J x N  wavelet coefficients
    real colvector V       // N x 1  final-level scaling coefficients
    string scalar  filter  // filter name
    real scalar    J       // number of decomposition levels
    real scalar    N       // number of observations
}

struct _wv_dwt_r {
    pointer(real colvector) colvector W  // J pointers to wavelet coefficients
    pointer(real colvector) scalar    V  // final-level scaling coefficients
    string scalar  filter
    real scalar    J
    real scalar    N
}

struct _wv_mra_r {
    real matrix    D       // J x N  detail components
    real colvector S       // N x 1  smooth component
    string scalar  filter
    real scalar    J
    real scalar    N
    string scalar  method  // "dwt" or "modwt"
}

// ═══════════════════════════════════════════════════════════════════════════
// MODWT FORWARD STEP — single level
//   V_in:  input scaling coefficients (N x 1)
//   h, g:  MODWT-scaled wavelet/scaling filters
//   j:     current decomposition level (1-indexed)
//   W_out: output wavelet coefficients (N x 1)
//   V_out: output scaling coefficients (N x 1)
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_modwt_fwd(real colvector V_in, real colvector h,
                             real colvector g, real scalar j,
                             real colvector W_out, real colvector V_out)
{
    real scalar N, L, t, l, k, step
    N    = rows(V_in)
    L    = rows(h)
    step = 2^(j - 1)

    W_out = J(N, 1, 0)
    V_out = J(N, 1, 0)

    for (t = 1; t <= N; t++) {
        for (l = 1; l <= L; l++) {
            k = mod(t - 1 - (l - 1) * step, N) + 1
            if (k < 1) k = k + N
            W_out[t] = W_out[t] + h[l] * V_in[k]
            V_out[t] = V_out[t] + g[l] * V_in[k]
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODWT BACKWARD STEP — single level (inverse)
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_modwt_bwd(real colvector W_in, real colvector V_in,
                             real colvector h, real colvector g,
                             real scalar j, real colvector V_out)
{
    real scalar N, L, t, l, k, step
    N    = rows(W_in)
    L    = rows(h)
    step = 2^(j - 1)

    V_out = J(N, 1, 0)

    for (t = 1; t <= N; t++) {
        for (l = 1; l <= L; l++) {
            k = mod(t - 1 + (l - 1) * step, N) + 1
            if (k < 1) k = k + N
            V_out[t] = V_out[t] + h[l] * W_in[k] + g[l] * V_in[k]
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_modwt(): Full MODWT decomposition
//   x:       input time series (N x 1)
//   filter:  filter name (e.g., "la8")
//   J:       number of decomposition levels
//   Returns: struct _wv_modwt_r with W (J x N), V (N x 1)
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_modwt_r scalar function _wv_modwt(real colvector x,
                                              string scalar filter,
                                              real scalar J)
{
    struct _wv_modwt_r scalar r
    real colvector h, g, V_cur, W_j, V_j
    real scalar j, N, Jmax

    N = rows(x)

    // Validate
    Jmax = _wv_max_level(N, filter)
    if (J > Jmax) {
        errprintf("Requested %g levels exceeds max %g for N=%g with %s filter\n",
                  J, Jmax, N, filter)
        _error(3498)
    }

    // Get MODWT-scaled filters
    _wv_get_filter(filter, "modwt", h, g)

    // Initialize
    r.W      = J(J, N, 0)
    r.filter = filter
    r.J      = J
    r.N      = N
    V_cur    = x

    // Pyramid algorithm — no downsampling
    for (j = 1; j <= J; j++) {
        _wv_modwt_fwd(V_cur, h, g, j, W_j, V_j)
        r.W[j, .] = W_j'
        V_cur = V_j
    }

    r.V = V_cur
    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_imodwt(): Inverse MODWT — reconstruct signal from MODWT coefficients
// ═══════════════════════════════════════════════════════════════════════════
real colvector function _wv_imodwt(struct _wv_modwt_r scalar r)
{
    real colvector h, g, V_cur, V_new
    real scalar j

    _wv_get_filter(r.filter, "modwt", h, g)

    V_cur = r.V

    for (j = r.J; j >= 1; j--) {
        _wv_modwt_bwd(r.W[j, .]', V_cur, h, g, j, V_new)
        V_cur = V_new
    }

    return(V_cur)
}

// ═══════════════════════════════════════════════════════════════════════════
// DWT FORWARD STEP — single level (with downsampling)
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_dwt_fwd(real colvector V_in, real colvector h,
                           real colvector g,
                           real colvector W_out, real colvector V_out)
{
    real scalar N, L, Nhalf, t, l, k
    N     = rows(V_in)
    L     = rows(h)
    Nhalf = N / 2

    W_out = J(Nhalf, 1, 0)
    V_out = J(Nhalf, 1, 0)

    for (t = 1; t <= Nhalf; t++) {
        for (l = 1; l <= L; l++) {
            k = mod(2 * t - 1 - (l - 1), N) + 1
            if (k < 1) k = k + N
            W_out[t] = W_out[t] + h[l] * V_in[k]
            V_out[t] = V_out[t] + g[l] * V_in[k]
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// DWT BACKWARD STEP — single level (with upsampling)
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_dwt_bwd(real colvector W_in, real colvector V_in,
                           real colvector h, real colvector g,
                           real colvector V_out)
{
    real scalar N, Nhalf, L, t, l, k, j2
    Nhalf = rows(W_in)
    N     = 2 * Nhalf
    L     = rows(h)

    V_out = J(N, 1, 0)

    for (t = 1; t <= N; t++) {
        for (l = 1; l <= L; l++) {
            if (mod(t - 1 + l - 1, 2) == 0) {
                j2 = (t - 1 + l - 1) / 2
                k  = mod(j2, Nhalf) + 1
                V_out[t] = V_out[t] + h[l] * W_in[k] + g[l] * V_in[k]
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_dwt(): Full DWT decomposition
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_dwt_r scalar function _wv_dwt(real colvector x,
                                          string scalar filter,
                                          real scalar J)
{
    struct _wv_dwt_r scalar r
    real colvector h, g, V_cur, W_j, V_j
    real scalar j, N

    N = rows(x)

    _wv_get_filter(filter, "dwt", h, g)

    r.W      = J(J, 1, NULL)
    r.filter = filter
    r.J      = J
    r.N      = N
    V_cur    = x

    for (j = 1; j <= J; j++) {
        _wv_dwt_fwd(V_cur, h, g, W_j, V_j)
        r.W[j] = &W_j
        V_cur  = V_j
    }

    r.V = &V_cur
    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_idwt(): Inverse DWT — reconstruct signal
// ═══════════════════════════════════════════════════════════════════════════
real colvector function _wv_idwt(struct _wv_dwt_r scalar r)
{
    real colvector h, g, V_cur, V_new
    real scalar j

    _wv_get_filter(r.filter, "dwt", h, g)

    V_cur = *r.V

    for (j = r.J; j >= 1; j--) {
        _wv_dwt_bwd(*r.W[j], V_cur, h, g, V_new)
        V_cur = V_new
    }

    return(V_cur)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_mra(): Multiresolution Analysis
//   Decomposes signal into J detail components (D1,...,DJ) and smooth (SJ)
//   method: "modwt" (default) or "dwt"
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_mra_r scalar function _wv_mra(real colvector x,
                                          string scalar filter,
                                          real scalar J,
                                          | string scalar method)
{
    struct _wv_mra_r   scalar mr
    struct _wv_modwt_r scalar wr
    real colvector h, g, V_cur, V_new
    real matrix W_zero
    real scalar j, jj, N

    if (args() < 4) method = "modwt"
    N = rows(x)

    mr.filter = filter
    mr.J      = J
    mr.N      = N
    mr.method = method
    mr.D      = J(J, N, 0)

    if (method == "modwt") {
        // MODWT-based MRA
        wr = _wv_modwt(x, filter, J)
        _wv_get_filter(filter, "modwt", h, g)

        // Detail j: reconstruct with W_j, all other W=0, V=0
        for (j = 1; j <= J; j++) {
            // Create zeroed MODWT result with only level j active
            W_zero = J(J, N, 0)
            W_zero[j, .] = wr.W[j, .]
            V_cur = J(N, 1, 0)

            // Reconstruct from level J down
            for (jj = J; jj >= 1; jj--) {
                _wv_modwt_bwd(W_zero[jj, .]', V_cur, h, g, jj, V_new)
                V_cur = V_new
            }
            mr.D[j, .] = V_cur'
        }

        // Smooth: reconstruct with all W=0, only V
        V_cur = wr.V
        for (j = J; j >= 1; j--) {
            _wv_modwt_bwd(J(N, 1, 0), V_cur, h, g, j, V_new)
            V_cur = V_new
        }
        mr.S = V_cur
    }
    else {
        errprintf("DWT-based MRA not yet implemented — use method(modwt)\n")
        _error(3498)
    }

    return(mr)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_brick_wall(): Apply brick wall (zero boundary coefficients)
//   W:      J x N matrix of MODWT coefficients
//   filter: filter name
//   J:      number of levels
//   Returns: J x N matrix with boundary coefficients set to missing
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_brick_wall(real matrix W, string scalar filter,
                                     real scalar J)
{
    real matrix Wb
    real scalar j, L, Lj

    L  = _wv_filter_length(filter)
    Wb = W

    for (j = 1; j <= J; j++) {
        Lj = min(((2^j - 1) * (L - 1) + 1, cols(W)))
        if (Lj < cols(W)) {
            Wb[j, 1..Lj] = J(1, Lj, .)
        }
    }

    return(Wb)
}

end
