*! Bivariate Wavelet Analysis — XWT, WTC, PWTC, Smoothing
*! Based on: biwavelet R package (Gouhier 2024)
*! References: Grinsted et al. (2004), Torrence & Webster (1998)
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
version 11
mata:
mata set matastrict on

// ═══════════════════════════════════════════════════════════════════════════
// STRUCT DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

struct _wv_xwt_r {
    complex matrix wave     // nscale x N  cross-wavelet spectrum
    real matrix    power    // nscale x N  |W_xy|
    real matrix    phase    // nscale x N  phase difference
    real colvector period
    real colvector scale
    real colvector coi
    real matrix    signif   // nscale x N  significance (1 = significant)
    real scalar    N
    real scalar    dt
}

struct _wv_wtc_r {
    real matrix    rsq      // nscale x N  coherence R²
    real matrix    phase    // nscale x N  phase difference
    real colvector period
    real colvector scale
    real colvector coi
    real matrix    signif   // nscale x N  Monte Carlo significance level
    real scalar    N
    real scalar    dt
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_xwt(): Cross-Wavelet Transform
//   x, y:  two input signals (N x 1)
//   dt:    time step
//   Returns: cross-wavelet result struct
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_xwt_r scalar function _wv_xwt(real colvector x, real colvector y,
                                          real scalar dt,
                                          | string scalar mother,
                                          real scalar param, real scalar dj,
                                          real scalar s0, real scalar Jtot)
{
    struct _wv_xwt_r scalar r
    struct _wv_cwt_r scalar w1, w2
    real scalar i, j, ns
    real colvector sig1, sig2
    real matrix sig_level

    // Defaults
    if (args() < 4 | mother == "") mother = "morlet"
    if (args() < 5 | param  == .) param  = -1
    if (args() < 6 | dj     == .) dj     = 0.25
    if (args() < 7 | s0     == .) s0     = 2 * dt
    if (args() < 8 | Jtot   == .) Jtot   = .

    // CWT of both signals
    w1 = _wv_cwt(x, dt, mother, param, dj, s0, Jtot)
    w2 = _wv_cwt(y, dt, mother, param, dj, s0, Jtot)

    ns = rows(w1.scale)

    // Cross-wavelet spectrum: W_xy = W_x * conj(W_y)
    r.wave = w1.wave :* conj(w2.wave)

    // Power = |W_xy|
    r.power = sqrt(Re(r.wave):^2 + Im(r.wave):^2)

    // Phase = atan2(Im, Re)
    r.phase = atan2(Im(r.wave), Re(r.wave))

    // Significance: chi-squared test
    // Zar = |W_xy| / (sigma_x * sigma_y)
    // Under H0: Zar^2 ~ chi2(2)/2  (Torrence & Compo 1998)
    sig1 = _wv_cwt_signif(x, dt, w1.scale, mother, param)
    sig2 = _wv_cwt_signif(y, dt, w2.scale, mother, param)

    sig_level = sqrt(sig1 * sig2')
    r.signif  = J(ns, w1.N, 0)
    for (i = 1; i <= ns; i++) {
        for (j = 1; j <= w1.N; j++) {
            r.signif[i, j] = (r.power[i, j] > sig_level[i, i])
        }
    }

    r.period = w1.period
    r.scale  = w1.scale
    r.coi    = w1.coi
    r.N      = w1.N
    r.dt     = dt

    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_smooth(): Wavelet smoothing (time + scale)
//   W:      complex matrix (nscale x N)
//   dt:     time step
//   scale:  scale vector
//   dj:     scale spacing
//   Returns: smoothed complex matrix
//
//   Smoothing follows Torrence & Webster (1998):
//   Time:  Gaussian with e-folding time = sqrt(2) * scale
//   Scale: Boxcar over 0.6 * ln(2) / dj scale intervals
// ═══════════════════════════════════════════════════════════════════════════
complex matrix function _wv_smooth(complex matrix W, real scalar dt,
                                    real colvector scale, real scalar dj)
{
    complex matrix Ws
    real scalar ns, N, i, j, t, hw, hs, ii
    real colvector kernel
    complex colvector row_smooth
    complex scalar acc, acc2
    real scalar idx, cnt, kw, sum_w
    complex matrix Ws2

    ns = rows(W)
    N  = cols(W)
    Ws = W

    // === Step 1: Smooth in time (Gaussian convolution per scale) ===
    //   Boundary handling: truncate-and-renormalize, NOT circular wrap.
    //   Circular wrap (mod) leaks data across the time-series edges and
    //   manifests as vertical streaks in the wavelet coherence display.
    for (i = 1; i <= ns; i++) {
        // Half-width of Gaussian kernel ~ sqrt(2) * scale / dt
        hw = round(sqrt(2) * scale[i] / dt)
        if (hw < 1) hw = 1
        if (hw > N/2) hw = N/2

        // Build Gaussian kernel (unnormalized; renormalized per position
        // so partial kernels at edges still average correctly).
        kernel = J(2*hw + 1, 1, .)
        for (t = -hw; t <= hw; t++) {
            kernel[t + hw + 1] = exp(-0.5 * (t * dt / scale[i])^2)
        }

        // Convolve this row with boundary truncation + renormalization.
        row_smooth = J(N, 1, C(0, 0))
        for (j = 1; j <= N; j++) {
            acc   = C(0, 0)
            sum_w = 0
            for (t = -hw; t <= hw; t++) {
                idx = j + t
                if (idx >= 1 & idx <= N) {
                    kw    = kernel[t + hw + 1]
                    acc   = acc + kw * W[i, idx]
                    sum_w = sum_w + kw
                }
            }
            row_smooth[j] = acc / sum_w
        }
        Ws[i, .] = row_smooth'
    }

    // === Step 2: Smooth in scale (boxcar) ===
    hs = max((round(0.6 / (2 * dj)), 1))
    Ws2 = Ws
    for (j = 1; j <= N; j++) {
        for (i = 1; i <= ns; i++) {
            acc2 = C(0, 0)
            cnt  = 0
            for (ii = max((i - hs, 1)); ii <= min((i + hs, ns)); ii++) {
                acc2 = acc2 + Ws[ii, j]
                cnt  = cnt + 1
            }
            Ws2[i, j] = acc2 / cnt
        }
    }

    return(Ws2)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_wtc(): Wavelet Coherence
//   x, y:  two input signals
//   dt:    time step
//   Returns: coherence result struct
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_wtc_r scalar function _wv_wtc(real colvector x, real colvector y,
                                          real scalar dt,
                                          | string scalar mother,
                                          real scalar param, real scalar dj,
                                          real scalar s0, real scalar Jtot,
                                          real scalar nrands)
{
    struct _wv_wtc_r scalar r
    struct _wv_cwt_r scalar w1, w2
    complex matrix Sxy, W12
    real matrix Sxx, Syy, sinv, P1, P2
    real scalar ns, N, i, j

    // Defaults
    if (args() < 4  | mother == "") mother = "morlet"
    if (args() < 5  | param  == .) param  = -1
    if (args() < 6  | dj     == .) dj     = 0.25
    if (args() < 7  | s0     == .) s0     = 2 * dt
    if (args() < 8  | Jtot   == .) Jtot   = .
    if (args() < 9  | nrands == .) nrands = 300

    // CWT of both signals
    w1 = _wv_cwt(x, dt, mother, param, dj, s0, Jtot)
    w2 = _wv_cwt(y, dt, mother, param, dj, s0, Jtot)

    ns = rows(w1.scale)
    N  = w1.N

    // Scale normalization: divide by scale
    sinv = J(ns, N, .)
    for (i = 1; i <= ns; i++) {
        sinv[i, .] = J(1, N, 1 / w1.scale[i])
    }

    // Cross-spectrum: W1 * conj(W2) / scale
    W12 = (w1.wave :* conj(w2.wave))
    for (i = 1; i <= ns; i++) {
        W12[i, .] = W12[i, .] :/ w1.scale[i]
    }

    // Auto-spectra
    P1 = (Re(w1.wave):^2 + Im(w1.wave):^2)
    P2 = (Re(w2.wave):^2 + Im(w2.wave):^2)
    for (i = 1; i <= ns; i++) {
        P1[i, .] = P1[i, .] :/ w1.scale[i]
        P2[i, .] = P2[i, .] :/ w1.scale[i]
    }

    // Smooth everything
    Sxy = _wv_smooth(W12, dt, w1.scale, dj)
    Sxx = Re(_wv_smooth(C(P1, J(ns, N, 0)), dt, w1.scale, dj))
    Syy = Re(_wv_smooth(C(P2, J(ns, N, 0)), dt, w1.scale, dj))

    // Coherence: R² = |S(W_xy)|² / (S(|W_x|²) * S(|W_y|²))
    r.rsq = (Re(Sxy):^2 + Im(Sxy):^2) :/ (Sxx :* Syy :+ 1e-30)

    // Clamp to [0, 1]
    for (i = 1; i <= ns; i++) {
        for (j = 1; j <= N; j++) {
            if (r.rsq[i, j] > 1) r.rsq[i, j] = 1
            if (r.rsq[i, j] < 0) r.rsq[i, j] = 0
        }
    }

    // Phase
    r.phase = atan2(Im(Sxy), Re(Sxy))

    // Monte Carlo significance
    r.signif = _wv_wtc_mc(x, y, dt, mother, param, dj, s0, Jtot, nrands,
                           w1.scale)

    r.period = w1.period
    r.scale  = w1.scale
    r.coi    = w1.coi
    r.N      = N
    r.dt     = dt

    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_wtc_mc(): Monte Carlo significance for WTC
//   Generates AR(1) surrogates and computes coherence distribution
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_wtc_mc(real colvector x, real colvector y,
                                 real scalar dt, string scalar mother,
                                 real scalar param, real scalar dj,
                                 real scalar s0, real scalar Jtot,
                                 real scalar nrands,
                                 real colvector scale)
{
    real scalar ar1_x, ar1_y, N, ns, i, j, rr
    real matrix sig95, rsq_dist, P1s, P2s, SP1, SP2, Rsq
    real colvector sx, sy, col
    struct _wv_cwt_r scalar ww1, ww2
    complex matrix W12s, SW12

    N  = rows(x)
    ns = rows(scale)

    ar1_x = _wv_ar1(x)
    ar1_y = _wv_ar1(y)

    // Matrix to store max coherence per scale across realizations
    rsq_dist = J(nrands, ns, 0)

    for (rr = 1; rr <= nrands; rr++) {
        // Generate AR(1) surrogates
        sx = J(N, 1, 0)
        sy = J(N, 1, 0)
        sx[1] = rnormal(1, 1, 0, 1)
        sy[1] = rnormal(1, 1, 0, 1)
        for (i = 2; i <= N; i++) {
            sx[i] = ar1_x * sx[i-1] + rnormal(1, 1, 0, 1) * sqrt(1 - ar1_x^2)
            sy[i] = ar1_y * sy[i-1] + rnormal(1, 1, 0, 1) * sqrt(1 - ar1_y^2)
        }

        // CWT of surrogates
        ww1 = _wv_cwt(sx, dt, mother, param, dj, s0, Jtot)
        ww2 = _wv_cwt(sy, dt, mother, param, dj, s0, Jtot)

        W12s = ww1.wave :* conj(ww2.wave)
        P1s  = Re(ww1.wave):^2 + Im(ww1.wave):^2
        P2s  = Re(ww2.wave):^2 + Im(ww2.wave):^2

        for (i = 1; i <= ns; i++) {
            W12s[i, .] = W12s[i, .] :/ scale[i]
            P1s[i, .]  = P1s[i, .]  :/ scale[i]
            P2s[i, .]  = P2s[i, .]  :/ scale[i]
        }

        SW12 = _wv_smooth(W12s, dt, scale, dj)
        SP1  = Re(_wv_smooth(C(P1s, J(ns, N, 0)), dt, scale, dj))
        SP2  = Re(_wv_smooth(C(P2s, J(ns, N, 0)), dt, scale, dj))

        Rsq = (Re(SW12):^2 + Im(SW12):^2) :/ (SP1 :* SP2 :+ 1e-30)

        // Store max coherence per scale (across time)
        for (i = 1; i <= ns; i++) {
            rsq_dist[rr, i] = max(Rsq[i, .])
        }

        // Progress
        if (mod(rr, 50) == 0) {
            printf("  Monte Carlo: %g / %g surrogates\n", rr, nrands)
            displayflush()
        }
    }

    // 95th percentile per scale
    sig95 = J(ns, 1, .)
    for (i = 1; i <= ns; i++) {
        col = sort(rsq_dist[., i], 1)
        sig95[i] = col[ceil(0.95 * nrands)]
    }

    return(sig95)
}

end
