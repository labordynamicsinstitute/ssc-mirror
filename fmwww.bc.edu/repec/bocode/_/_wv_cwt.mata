*! CWT Engine — Continuous Wavelet Transform
*! Implements: CWT, mother wavelets (Morlet/Paul/DOG), COI, significance
*! Based on: biwavelet R package (Gouhier 2024), Torrence & Compo (1998)
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
version 11
mata:
mata set matastrict on

// ═══════════════════════════════════════════════════════════════════════════
// STRUCT DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════

struct _wv_cwt_r {
    complex matrix wave     // nscale x N  wavelet coefficients
    real matrix    power    // nscale x N  |wave|^2
    real colvector period   // nscale x 1  Fourier periods
    real colvector scale    // nscale x 1  wavelet scales
    real colvector coi      // N x 1      cone of influence
    real matrix    signif   // nscale x 1  significance levels
    real scalar    dt       // time step
    string scalar  mother  // mother wavelet name
    real scalar    param   // mother wavelet parameter
    real scalar    N       // number of observations
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_morlet(): Morlet wavelet in frequency domain
//   k:     angular frequency vector (N x 1)
//   scale: wavelet scale
//   param: k0 parameter (default 6)
//   daughter: output daughter wavelet (complex, N x 1)
//   ff:       Fourier factor (output)
//   coi_f:    COI factor (output)
//   dof:      degrees of freedom for significance (output)
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_morlet(real colvector k, real scalar scale,
                          real scalar param,
                          complex colvector daughter,
                          real scalar ff, real scalar coi_f,
                          real scalar dofmin)
{
    real scalar k0, norm, N
    real colvector expnt, Hk

    k0 = (param < 0 ? 6 : param)
    N  = rows(k)

    // Heaviside step function
    Hk = (k :> 0)

    // Normalization
    norm = sqrt(scale * k[2]) * (pi()^(-0.25)) * sqrt(N)

    // Exponent
    expnt = -((scale :* k :- k0):^2) :/ 2 :* Hk

    // Daughter wavelet (complex)
    daughter = C(norm :* exp(expnt) :* Hk, J(N, 1, 0))

    // Fourier factor
    ff = 4 * pi() / (k0 + sqrt(2 + k0^2))

    // COI factor
    coi_f = 1 / sqrt(2)

    // Degrees of freedom
    dofmin = 2
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_paul(): Paul wavelet in frequency domain
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_paul(real colvector k, real scalar scale,
                        real scalar param,
                        complex colvector daughter,
                        real scalar ff, real scalar coi_f,
                        real scalar dofmin)
{
    real scalar m, norm, N
    real colvector expnt, Hk

    m = (param < 0 ? 4 : param)
    N = rows(k)

    Hk = (k :> 0)

    norm = sqrt(scale * k[2]) * (2^m / sqrt(m * _wv_factorial(2*m - 1))) * sqrt(N)

    expnt = -(scale :* k) :* Hk

    daughter = C(norm :* ((scale :* k):^m) :* exp(expnt) :* Hk, J(N, 1, 0))

    ff    = 4 * pi() / (2 * m + 1)
    coi_f = 1 / sqrt(2)
    dofmin = 2
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_dog(): Derivative of Gaussian wavelet in frequency domain
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_dog(real colvector k, real scalar scale,
                       real scalar param,
                       complex colvector daughter,
                       real scalar ff, real scalar coi_f,
                       real scalar dofmin)
{
    real scalar m, norm, N
    real colvector expnt

    m = (param < 0 ? 2 : param)
    N = rows(k)

    norm = sqrt(scale * k[2]) * sqrt(2 * pi()) *
           (-sqrt(-1))^(m+1) / sqrt(exp(lngamma(m + 0.5))) * sqrt(N)

    expnt = -((scale :* k):^2) :/ 2

    daughter = C(Re(norm) :* ((scale :* k):^m) :* exp(expnt),
                 Im(norm) :* ((scale :* k):^m) :* exp(expnt))

    ff    = 2 * pi() / sqrt(m + 0.5)
    coi_f = 1 / sqrt(2)
    dofmin = (mod(m, 2) == 0 ? 1 : 2)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_cwt(): Continuous Wavelet Transform
//   x:      input signal (N x 1)
//   dt:     time step (e.g., 1 for annual)
//   mother: "morlet" (default), "paul", "dog"
//   param:  mother-specific parameter (-1 = default)
//   dj:     scale spacing (default 0.25 = 4 sub-octaves)
//   s0:     smallest scale (default 2*dt)
//   Jtot:   number of scales (default = auto)
// ═══════════════════════════════════════════════════════════════════════════
struct _wv_cwt_r scalar function _wv_cwt(real colvector x, real scalar dt,
                                          | string scalar mother,
                                          real scalar param, real scalar dj,
                                          real scalar s0, real scalar Jtot)
{
    struct _wv_cwt_r scalar r
    complex colvector f_signal, daughter
    real colvector k, x_demean
    real scalar N, N2, ff, coi_f, dofmin
    real scalar i, j, pi2
    complex colvector conv

    // Defaults
    if (args() < 3 | mother == "") mother = "morlet"
    if (args() < 4 | param  == .) param  = -1
    if (args() < 5 | dj     == .) dj     = 0.25
    if (args() < 6 | s0     == .) s0     = 2 * dt
    if (args() < 7 | Jtot   == .) Jtot   = .

    mother = strlower(strtrim(mother))

    // Resolve param sentinel (-1) to mother-specific default so e(param) is meaningful
    if (param < 0) {
        if      (mother == "morlet") param = 6
        else if (mother == "paul")   param = 4
        else if (mother == "dog")    param = 2
    }
    N = rows(x)
    pi2 = 2 * pi()

    // De-mean
    x_demean = x :- mean(x)

    // Tukey cosine taper at both ends — 5% of length each side.  Bringing
    // signal to ~0 at the absolute boundaries kills residual high-frequency
    // ringing that anti-symmetric padding can't fully suppress.
    real scalar taper_n, taper_k, taper_w
    taper_n = round(0.05 * N)
    if (taper_n < 2) taper_n = 2
    if (taper_n > N / 2) taper_n = floor(N / 2)
    for (taper_k = 1; taper_k <= taper_n; taper_k++) {
        taper_w = 0.5 * (1 - cos(pi() * (taper_k - 1) / (taper_n - 1)))
        x_demean[taper_k]         = x_demean[taper_k] * taper_w
        x_demean[N - taper_k + 1] = x_demean[N - taper_k + 1] * taper_w
    }

    // Pad to next power of 2
    N2 = 2^ceil(ln(N) / ln(2))

    // Compute angular frequencies
    k = J(N2, 1, 0)
    for (i = 2; i <= N2/2 + 1; i++) {
        k[i] = pi2 * (i - 1) / (N2 * dt)
    }
    for (i = N2/2 + 2; i <= N2; i++) {
        k[i] = -pi2 * (N2 - i + 1) / (N2 * dt)
    }

    // Determine Fourier factor from mother wavelet
    _wv_dispatch_mother(mother, k, 1, param, daughter, ff, coi_f, dofmin)

    // Auto-compute number of scales
    if (Jtot == .) {
        Jtot = floor(ln(N * dt / s0) / (dj * ln(2)))
    }

    // Compute scale vector
    r.scale = J(Jtot + 1, 1, .)
    for (j = 0; j <= Jtot; j++) {
        r.scale[j + 1] = s0 * 2^(j * dj)
    }

    // Period vector
    r.period = ff :* r.scale

    // FFT of padded signal — anti-symmetric reflection at the right edge.
    //   x_padded[N+k] = 2*x[N] - x[N-k+1]
    // This continues the local trend smoothly past the boundary, killing
    // both the data-to-zero discontinuity AND the slope-reversal kink that
    // symmetric reflection introduces for non-stationary signals.
    real colvector x_padded
    real scalar pad_k, src_idx
    x_padded = J(N2, 1, 0)
    for (pad_k = 1; pad_k <= N; pad_k++) {
        x_padded[pad_k] = x_demean[pad_k]
    }
    for (pad_k = 1; pad_k <= N2 - N; pad_k++) {
        src_idx = N - pad_k + 1
        if (src_idx < 1) src_idx = 1
        x_padded[N + pad_k] = 2 * x_demean[N] - x_demean[src_idx]
    }
    f_signal = fft(C(x_padded, J(N2, 1, 0)))

    // Initialize output
    r.wave  = C(J(Jtot + 1, N, 0), J(Jtot + 1, N, 0))
    r.power = J(Jtot + 1, N, 0)

    // CWT via convolution theorem
    for (j = 1; j <= Jtot + 1; j++) {
        _wv_dispatch_mother(mother, k, r.scale[j], param,
                            daughter, ff, coi_f, dofmin)

        // Convolution: IFFT(FFT(signal) * daughter)
        conv = invfft(f_signal :* daughter)

        // Store only non-padded portion
        r.wave[j, .] = conv[1..N]'
        r.power[j, .] = (Re(conv[1..N]) :^2 + Im(conv[1..N]) :^2)'
    }

    // Cone of influence
    r.coi = J(N, 1, .)
    for (i = 1; i <= N; i++) {
        r.coi[i] = coi_f * dt * min((i - 1, N - i))
    }
    // Ensure COI doesn't go below smallest period
    for (i = 1; i <= N; i++) {
        if (r.coi[i] < sqrt(2) * dt) r.coi[i] = sqrt(2) * dt
    }

    // Store metadata
    r.dt     = dt
    r.mother = mother
    r.param  = param
    r.N      = N

    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_dispatch_mother(): Route to correct mother wavelet function
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_dispatch_mother(string scalar mother, real colvector k,
                                   real scalar scale, real scalar param,
                                   complex colvector daughter,
                                   real scalar ff, real scalar coi_f,
                                   real scalar dofmin)
{
    if (mother == "morlet") {
        _wv_morlet(k, scale, param, daughter, ff, coi_f, dofmin)
    }
    else if (mother == "paul") {
        _wv_paul(k, scale, param, daughter, ff, coi_f, dofmin)
    }
    else if (mother == "dog") {
        _wv_dog(k, scale, param, daughter, ff, coi_f, dofmin)
    }
    else {
        _error(3498, "Unknown mother wavelet: " + mother +
               ". Use morlet, paul, or dog.")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_ar1(): Estimate AR(1) coefficient from a time series
// ═══════════════════════════════════════════════════════════════════════════
real scalar function _wv_ar1(real colvector x)
{
    real colvector xc
    real scalar N, r

    xc = x :- mean(x)
    N  = rows(xc)

    r = sum(xc[1..N-1] :* xc[2..N]) / sum(xc :^ 2)
    return(r)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_ar1_spectrum(): AR(1) red-noise spectrum
//   ar1:    AR(1) coefficient
//   period: period vector
//   dt:     time step
//   Returns: theoretical power spectrum
// ═══════════════════════════════════════════════════════════════════════════
real colvector function _wv_ar1_spectrum(real scalar ar1,
                                          real colvector period,
                                          real scalar dt)
{
    real colvector freq, spec
    real scalar pi2

    pi2  = 2 * pi()
    freq = dt :/ period

    spec = (1 - ar1^2) :/ (1 :- 2 :* ar1 :* cos(pi2 :* freq) :+ ar1^2)

    return(spec)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_cwt_signif(): CWT significance testing against AR(1) red noise
//   x:       input signal
//   dt:      time step
//   scale:   scale vector
//   mother:  mother wavelet name
//   param:   mother parameter
//   siglvl:  significance level (default 0.95)
//   Returns: significance vector (nscale x 1)
// ═══════════════════════════════════════════════════════════════════════════
real colvector function _wv_cwt_signif(real colvector x, real scalar dt,
                                        real colvector scale,
                                        string scalar mother,
                                        real scalar param,
                                        | real scalar siglvl)
{
    real scalar ar1, sigma2, dofmin, ff, coi_f
    real colvector fft_theor, signif, period
    complex colvector daughter
    real colvector k

    if (args() < 6 | siglvl == .) siglvl = 0.95

    // Estimate AR(1)
    ar1    = _wv_ar1(x)
    sigma2 = variance(x)

    // Get DOF from mother
    k = (0 \ 2 * pi() / (rows(x) * dt))
    _wv_dispatch_mother(mother, k, scale[1], param,
                        daughter, ff, coi_f, dofmin)

    // Compute theoretical spectrum
    period    = ff :* scale
    fft_theor = _wv_ar1_spectrum(ar1, period, dt)

    // Significance: chi-squared test
    signif = sigma2 :* fft_theor :* invchi2(dofmin, siglvl) :/ dofmin

    return(signif)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_factorial(): Simple factorial function
// ═══════════════════════════════════════════════════════════════════════════
real scalar function _wv_factorial(real scalar n)
{
    real scalar result, i

    if (n <= 1) return(1)

    result = 1
    for (i = 2; i <= n; i++) {
        result = result * i
    }
    return(result)
}

end
