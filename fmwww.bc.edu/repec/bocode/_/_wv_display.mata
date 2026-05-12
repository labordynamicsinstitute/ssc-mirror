*! Display, Colormaps & Visualization Utilities — lwavelet package
*! MATLAB-style colormaps: Jet, Parula, Turbo
*! Author: Dr. Merwan Roudane <merwanroudane920@gmail.com>
version 11
mata:
mata set matastrict on

// ═══════════════════════════════════════════════════════════════════════════
// MATLAB JET COLORMAP — Classic rainbow (blue → cyan → green → yellow → red)
// Control points: (0,0,.5) → (0,0,1) → (0,1,1) → (1,1,0) → (1,0,0) → (.5,0,0)
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_cmap_jet(real scalar n)
{
    real matrix cmap
    real scalar i, t
    real scalar r, g, b

    cmap = J(n, 3, 0)

    for (i = 1; i <= n; i++) {
        t = (i - 1) / max((n - 1, 1))

        // Red channel
        if (t < 0.375) r = 0
        else if (t < 0.625) r = (t - 0.375) / 0.25
        else if (t < 0.875) r = 1
        else r = 1 - (t - 0.875) / 0.25 * 0.5 + 0.5

        // Green channel
        if (t < 0.125) g = 0
        else if (t < 0.375) g = (t - 0.125) / 0.25
        else if (t < 0.625) g = 1
        else if (t < 0.875) g = 1 - (t - 0.625) / 0.25
        else g = 0

        // Blue channel
        if (t < 0.125) b = 0.5 + t / 0.125 * 0.5
        else if (t < 0.375) b = 1
        else if (t < 0.625) b = 1 - (t - 0.375) / 0.25
        else b = 0

        // Clamp
        cmap[i, .] = (min((max((r, 0)), 1)),
                       min((max((g, 0)), 1)),
                       min((max((b, 0)), 1)))
    }
    return(cmap)
}

// ═══════════════════════════════════════════════════════════════════════════
// MATLAB PARULA COLORMAP — Modern blue → teal → yellow (MATLAB default)
// Defined by 9 control points, linearly interpolated
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_cmap_parula(real scalar n)
{
    real matrix ctrl, cmap
    real scalar i, t, nc, seg
    real scalar frac

    // Parula control points (MATLAB R2024a approximation)
    ctrl = (0.2422, 0.1504, 0.6603 \
            0.2810, 0.1857, 0.7280 \
            0.1786, 0.3478, 0.8239 \
            0.0689, 0.5315, 0.7790 \
            0.1280, 0.6904, 0.6296 \
            0.2992, 0.7987, 0.4163 \
            0.6350, 0.8467, 0.2383 \
            0.9270, 0.7950, 0.2065 \
            0.9769, 0.9839, 0.0805)

    nc   = rows(ctrl)
    cmap = J(n, 3, 0)

    for (i = 1; i <= n; i++) {
        t = (i - 1) / max((n - 1, 1)) * (nc - 1)
        seg = min((floor(t) + 1, nc - 1))
        frac = t - (seg - 1)

        cmap[i, .] = ctrl[seg, .] + frac * (ctrl[seg + 1, .] - ctrl[seg, .])
    }
    return(cmap)
}

// ═══════════════════════════════════════════════════════════════════════════
// GOOGLE TURBO COLORMAP — Perceptually improved rainbow
// Defined by 16 control points
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_cmap_turbo(real scalar n)
{
    real matrix ctrl, cmap
    real scalar i, t, nc, seg, frac

    // Turbo colormap control points (Mikhailov 2019)
    ctrl = (0.1900, 0.0718, 0.2322 \
            0.2535, 0.2650, 0.5294 \
            0.2628, 0.4435, 0.7376 \
            0.1680, 0.6032, 0.8440 \
            0.0923, 0.7340, 0.8546 \
            0.1889, 0.8339, 0.7314 \
            0.3975, 0.8943, 0.5380 \
            0.5888, 0.9220, 0.3327 \
            0.7614, 0.9089, 0.1688 \
            0.8864, 0.8511, 0.1110 \
            0.9596, 0.7430, 0.1530 \
            0.9869, 0.5987, 0.1661 \
            0.9628, 0.4325, 0.1541 \
            0.8938, 0.2823, 0.1201 \
            0.7960, 0.1569, 0.0975 \
            0.6471, 0.0588, 0.0824)

    nc   = rows(ctrl)
    cmap = J(n, 3, 0)

    for (i = 1; i <= n; i++) {
        t = (i - 1) / max((n - 1, 1)) * (nc - 1)
        seg = min((floor(t) + 1, nc - 1))
        frac = t - (seg - 1)

        cmap[i, .] = ctrl[seg, .] + frac * (ctrl[seg + 1, .] - ctrl[seg, .])
    }
    return(cmap)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_rgb2stata(): Convert RGB (0-1) to Stata color string "R G B"
// ═══════════════════════════════════════════════════════════════════════════
string scalar function _wv_rgb2stata(real scalar r, real scalar g,
                                      real scalar b)
{
    return(strofreal(round(r*255)) + " " +
           strofreal(round(g*255)) + " " +
           strofreal(round(b*255)))
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_cmap_get(): Get colormap by name
//   name:  "jet", "parula", "turbo"
//   n:     number of colors
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_cmap_get(string scalar name, real scalar n)
{
    if (name == "jet")    return(_wv_cmap_jet(n))
    if (name == "parula") return(_wv_cmap_parula(n))
    if (name == "turbo")  return(_wv_cmap_turbo(n))

    // Default: parula
    return(_wv_cmap_parula(n))
}

// ═══════════════════════════════════════════════════════════════════════════
// DISPLAY UTILITIES — Beautiful formatted output
// ═══════════════════════════════════════════════════════════════════════════

// Header box with double-line border
void function _wv_display_header(string scalar title, string scalar subtitle)
{
    real scalar w
    w = max((strlen(title), strlen(subtitle))) + 4
    if (w < 60) w = 60

    printf("\n")
    printf("{txt}{hline " + strofreal(w) + "}\n")
    printf("{bf:  %s}\n", title)
    if (subtitle != "") {
        printf("{txt}  %s\n", subtitle)
    }
    printf("{txt}{hline " + strofreal(w) + "}\n")
}

// Sub-header
void function _wv_display_subheader(string scalar title)
{
    printf("\n{txt}{bf:%s}\n", title)
    printf("{txt}{hline " + strofreal(strlen(title) + 2) + "}\n")
}

// Key-value pair display
void function _wv_display_kv(string scalar key, string scalar value)
{
    printf("{txt}  %-25s {res}%s\n", key, value)
}

// Significance stars
string scalar function _wv_stars(real scalar pval)
{
    if (pval == .) return("")
    if (pval < 0.001) return("***")
    if (pval < 0.01)  return("**")
    if (pval < 0.05)  return("*")
    if (pval < 0.10)  return("+")
    return("")
}

// Scale label (period interpretation)
string scalar function _wv_scale_label(real scalar j, real scalar dt)
{
    real scalar period_lo, period_hi

    period_lo = 2^j * dt
    period_hi = 2^(j+1) * dt

    return(strofreal(period_lo) + "-" + strofreal(period_hi))
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_modwt(): Display MODWT results beautifully
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_modwt(struct _wv_modwt_r scalar r,
                                 string scalar varname)
{
    real scalar j, total_var, cum_pct, svar, pct
    real colvector wvar

    _wv_display_header("Maximal Overlap Discrete Wavelet Transform (MODWT)",
                       "lwavelet package — Dr. Merwan Roudane")

    _wv_display_kv("Variable:", varname)
    _wv_display_kv("Observations:", strofreal(r.N))
    _wv_display_kv("Filter:", r.filter + " (L=" + strofreal(_wv_filter_length(r.filter)) + ")")
    _wv_display_kv("Decomposition levels:", strofreal(r.J))
    _wv_display_kv("Boundary:", "periodic")

    // Wavelet variance table
    _wv_display_subheader("Wavelet Variance Decomposition")

    printf("{txt}  {hline 70}\n")
    printf("{txt}  {bf:%-8s %12s %12s %12s %12s}\n",
           "Level", "Period", "Variance", "% Total", "Cumulative %")
    printf("{txt}  {hline 70}\n")

    total_var = 0
    wvar = J(r.J, 1, .)
    for (j = 1; j <= r.J; j++) {
        wvar[j] = mean(r.W[j, .]' :^ 2)
        total_var = total_var + wvar[j]
    }
    // Add scaling variance
    svar = mean(r.V :^ 2)
    total_var = total_var + svar

    cum_pct = 0
    for (j = 1; j <= r.J; j++) {
        pct = wvar[j] / total_var * 100
        cum_pct = cum_pct + pct
        printf("{res}  D" + strofreal(j))
        printf("%9s %12.6f %10.2f", _wv_scale_label(j, 1), wvar[j], pct)
        printf("%s %11.2f", "%", cum_pct)
        printf("%s\n", "%")
    }
    cum_pct = cum_pct + svar / total_var * 100
    printf("{res}  S" + strofreal(r.J))
    printf("%9s %12.6f %10.2f", ">" + strofreal(2^(r.J+1)), svar, svar/total_var*100)
    printf("%s %11.2f", "%", cum_pct)
    printf("%s\n", "%")

    printf("{txt}  {hline 70}\n")
    printf("{res}  %s %12s %12.6f %10.2f", "Total", "", total_var, 100)
    printf("%s\n", "%")
    printf("{txt}  {hline 70}\n")
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_wmcorr(): Display wavelet multiple correlation beautifully
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_wmcorr(struct _wv_wmcorr_r scalar r,
                                  string colvector vnames)
{
    real scalar j
    string scalar ymname

    _wv_display_header("Wavelet Multiple Correlation",
                       "lwavelet package — Dr. Merwan Roudane")

    _wv_display_kv("Variables:", invtokens(vnames'))
    _wv_display_kv("Filter:", r.filter)
    _wv_display_kv("Levels:", strofreal(r.J))
    _wv_display_kv("Confidence:", strofreal(r.p * 100) + "%")

    _wv_display_subheader("Scale-by-Scale Multiple Correlation")

    printf("{txt}  {hline 76}\n")
    printf("{txt}  {bf:%-8s %10s %10s %12s %12s %12s}\n",
           "Level", "Period", "R", "[CI Low", "CI High]", "YmaxR")
    printf("{txt}  {hline 76}\n")

    for (j = 1; j <= r.J; j++) {
        if (r.ymaxr[j] != . & r.ymaxr[j] <= rows(vnames)) {
            ymname = vnames[r.ymaxr[j]]
        }
        else {
            ymname = "—"
        }

        if (r.val[j, 1] == .) {
            printf("{txt}  D" + strofreal(j))
            printf("%10s %10s %12s %12s %12s\n",
                   _wv_scale_label(j, 1), "n/a", ".", ".", ".")
        }
        else {
            printf("{res}  D" + strofreal(j))
            printf("%10s %10.4f %12.4f %12.4f %12s\n",
                   _wv_scale_label(j, 1),
                   r.val[j, 1], r.val[j, 2], r.val[j, 3], ymname)
        }
    }
    printf("{txt}  {hline 76}\n")

    printf("\n{txt}  Note: YmaxR = variable with highest R{c 178} at each scale\n")
    printf("{txt}  CI computed via Fisher z-transform\n")
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_wmreg(): Display wavelet multiple regression
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_wmreg(struct _wv_wmreg_r scalar r,
                                 string colvector vnames)
{
    real scalar j, i, d, col
    string scalar depname

    d = cols(r.beta)

    _wv_display_header("Wavelet Multiple Regression",
                       "lwavelet package — Dr. Merwan Roudane")

    for (j = 1; j <= r.J; j++) {
        if (r.ymaxr[j] == .) continue

        depname = vnames[r.ymaxr[j]]

        printf("\n{txt}  {bf:Level D" + strofreal(j) + "} (Period " + _wv_scale_label(j, 1) + ") ")
        printf("Dependent: {res}%s{txt} R2 = {res}%10.4f\n",
               depname, r.rsq[j])
        printf("{txt}  {hline 68}\n")
        printf("{txt}  {bf:%-16s %10s %10s %10s %8s %4s}\n",
               "Variable", "Coef.", "Std.Err.", "t-stat", "p-value", "")
        printf("{txt}  {hline 68}\n")

        col = 0
        for (i = 1; i <= rows(vnames); i++) {
            if (i == r.ymaxr[j]) continue
            col = col + 1
            if (col > d) break

            printf("{res}  %-16s %10.4f %10.4f %10.4f %8.4f %4s\n",
                   vnames[i], r.beta[j, col], r.se[j, col],
                   r.tstat[j, col], r.pval[j, col],
                   _wv_stars(r.pval[j, col]))
        }
        printf("{txt}  {hline 68}\n")
    }

    printf("\n{txt}  Signif: *** 0.001  ** 0.01  * 0.05  + 0.10\n")
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_cwt(): Display CWT scale-averaged power table
//   r:       CWT result struct
//   sig:     significance vector (nscale x 1)
//   varname: variable name
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_cwt(struct _wv_cwt_r scalar r,
                               real colvector sig,
                               string scalar varname)
{
    real scalar ns, band, j1, j2
    real scalar plo, phi, avgp, avgs

    _wv_display_header("Continuous Wavelet Transform (CWT)",
                       "lwavelet package — Dr. Merwan Roudane")

    _wv_display_kv("Variable:", varname)
    _wv_display_kv("Observations:", strofreal(r.N))
    _wv_display_kv("Mother wavelet:", r.mother + " (param=" + strofreal(r.param) + ")")
    _wv_display_kv("Scale spacing:", strofreal(rows(r.scale)) + " scales")
    _wv_display_kv("Time step:", strofreal(r.dt))

    printf("\n{txt}  Period range:       {res}%9.2f — %9.2f\n",
           min(r.period), max(r.period))
    printf("\n")

    printf("{txt}  {bf:Scale-Averaged Wavelet Power}\n")
    printf("{txt}  {hline 50}\n")
    printf("{txt}  {bf:Period Range     Avg. Power    Significance}\n")
    printf("{txt}  {hline 50}\n")

    ns = rows(r.scale)
    for (band = 1; band <= min((5, ns)); band++) {
        j1 = max((1, round((band - 1) / 5 * ns) + 1))
        j2 = min((round(band / 5 * ns), ns))
        plo = r.period[j1]
        phi = r.period[j2]
        avgp = mean(vec(r.power[j1..j2, .]))
        avgs = mean(sig[j1..j2])
        printf("{res}  %6.2f-%-8.2f %12.4f    %s\n",
               plo, phi, avgp, (avgp > avgs ? "{bf:***}" : ""))
    }
    printf("{txt}  {hline 50}\n")
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_xwt(): Display XWT scale-averaged cross-wavelet power
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_xwt(struct _wv_xwt_r scalar r,
                               string scalar var1, string scalar var2)
{
    real scalar ns, bb, j1x, j2x
    real scalar plo2, phi2, avgpow, avgpha

    printf("\n")
    printf("{txt}{hline 60}\n")
    printf("{txt}{bf:  Cross-Wavelet Transform (XWT)}\n")
    printf("{txt}  lwavelet package — Dr. Merwan Roudane\n")
    printf("{txt}{hline 60}\n")
    printf("\n")
    printf("{txt}  Variable X:        {res}%s\n", var1)
    printf("{txt}  Variable Y:        {res}%s\n", var2)
    printf("{txt}  Observations:      {res}%g\n", r.N)
    printf("\n")

    printf("{txt}  {bf:Scale-Averaged Cross-Wavelet Power}\n")
    printf("{txt}  {hline 55}\n")
    printf("{txt}  {bf:Period Range     XWT Power     Avg. Phase (°)}\n")
    printf("{txt}  {hline 55}\n")

    ns = rows(r.scale)
    for (bb = 1; bb <= min((5, ns)); bb++) {
        j1x = max((1, round((bb-1)/5*ns) + 1))
        j2x = min((round(bb/5*ns), ns))
        plo2 = r.period[j1x]
        phi2 = r.period[j2x]
        avgpow = mean(vec(r.power[j1x..j2x, .]))
        avgpha = mean(vec(r.phase[j1x..j2x, .])) * 180 / pi()
        printf("{res}  %6.2f-%-8.2f %12.4f    %8.1f°\n",
               plo2, phi2, avgpow, avgpha)
    }
    printf("{txt}  {hline 55}\n")
    printf("\n")
    printf("{txt}  Phase: 0°=in-phase, 90°=X leads, -90°=Y leads, ±180°=anti-phase\n")
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_wtc(): Display WTC scale-averaged coherence
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_wtc(struct _wv_wtc_r scalar r,
                               string scalar var1, string scalar var2,
                               real scalar nrands)
{
    real scalar ns, bbb, j1c, j2c
    real scalar plo3, phi3, avgrsq, avgph, avgsig
    real scalar nsig, ntot, si, sj

    printf("\n")
    printf("{txt}  Variable X:        {res}%s\n", var1)
    printf("{txt}  Variable Y:        {res}%s\n", var2)
    printf("{txt}  Observations:      {res}%g\n", r.N)
    printf("{txt}  MC surrogates:     {res}%g\n", nrands)
    printf("\n")

    printf("{txt}  {bf:Scale-Averaged Wavelet Coherence}\n")
    printf("{txt}  {hline 65}\n")
    printf("{txt}  {bf:Period Range     Avg. R²     Avg. Phase (°)    Significant}\n")
    printf("{txt}  {hline 65}\n")

    ns = rows(r.scale)
    for (bbb = 1; bbb <= min((6, ns)); bbb++) {
        j1c = max((1, round((bbb-1)/6*ns) + 1))
        j2c = min((round(bbb/6*ns), ns))
        plo3 = r.period[j1c]
        phi3 = r.period[j2c]
        avgrsq = mean(vec(r.rsq[j1c..j2c, .]))
        avgph  = mean(vec(r.phase[j1c..j2c, .])) * 180 / pi()

        // Count significant cells
        nsig = 0
        ntot = (j2c - j1c + 1) * cols(r.rsq)
        for (si = j1c; si <= j2c; si++) {
            for (sj = 1; sj <= cols(r.rsq); sj++) {
                if (r.rsq[si, sj] > r.signif[si]) nsig++
            }
        }
        avgsig = nsig / ntot * 100

        printf("{res}  %6.2f-%-8.2f %10.4f    %8.1f°       %5.1f%%\n",
               plo3, phi3, avgrsq, avgph, avgsig)
    }
    printf("{txt}  {hline 65}\n")
    printf("\n")
    printf("{txt}  Phase: 0°=in-phase, 90°=X leads, -90°=Y leads, ±180°=anti-phase\n")
    printf("{txt}  Significance: Monte Carlo 95%% level (%g AR(1) surrogates)\n", nrands)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_display_wmxcorr(): Display wavelet multiple cross-correlation
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_display_wmxcorr(struct _wv_wmxcorr_r scalar r,
                                    string colvector vnames)
{
    real scalar j, ll, maxr, maxl
    real scalar rm5, r0, rp5, ml
    real rowvector rr

    printf("\n")
    printf("{txt}{hline 60}\n")
    printf("{txt}{bf:  Wavelet Multiple Cross-Correlation}\n")
    printf("{txt}  lwavelet package — Dr. Merwan Roudane\n")
    printf("{txt}{hline 60}\n")
    printf("\n")
    printf("{txt}  Variables:         {res}%s\n", invtokens(vnames'))
    printf("{txt}  Filter:            {res}%s\n", r.filter)
    printf("{txt}  Levels:            {res}%g\n", r.J)
    printf("{txt}  Max lag:           {res}±%g\n", r.maxlag)
    printf("\n")

    printf("{txt}  {bf:Cross-Correlation at Key Lags}\n")
    printf("{txt}  {hline 70}\n")
    printf("{txt}  {bf:Level    Lag -5      Lag 0      Lag +5     Peak Lag   Peak R}\n")
    printf("{txt}  {hline 70}\n")

    ml = r.maxlag
    for (j = 1; j <= r.J; j++) {
        rr = r.val[j, .]
        maxr = 0
        maxl = 0
        for (ll = 1; ll <= cols(rr); ll++) {
            if (rr[ll] != . & rr[ll] > maxr) {
                maxr = rr[ll]
                maxl = ll - ml - 1
            }
        }
        rm5 = ((ml - 5 + 1 >= 1 & ml - 5 + 1 <= cols(rr)) ? rr[ml-5+1] : .)
        r0  = rr[ml + 1]
        rp5 = ((ml + 5 + 1 >= 1 & ml + 5 + 1 <= cols(rr)) ? rr[ml+5+1] : .)
        printf("{res}  D%-6.0g %8.4f   %8.4f   %8.4f   %6.0g    %8.4f\n",
               j, rm5, r0, rp5, maxl, maxr)
    }
    printf("{txt}  {hline 70}\n")
    printf("\n")
    printf("{txt}  Positive lag = first variable leads\n")
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_plot_cwt_colors(): Extract colormap colors into Stata locals
//   Called from _wv_plot_cwt program in wt.ado
// ═══════════════════════════════════════════════════════════════════════════
void function _wv_plot_cwt_colors(string scalar cmapname, real scalar ncolors)
{
    real matrix cmap
    real scalar ci

    cmap = _wv_cmap_get(cmapname, ncolors)
    for (ci = 1; ci <= ncolors; ci++) {
        st_local("color" + strofreal(ci),
                 _wv_rgb2stata(cmap[ci, 1], cmap[ci, 2], cmap[ci, 3]))
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_smooth_rows(): Row-wise 1-D Gaussian smoother for cosmetic display.
//   Smooths each row independently along the time axis with stddev `sigma`.
//   Used by wtc plot to soften the residual coherence-window edge streaks.
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_smooth_rows(real matrix X, real scalar sigma)
{
    real scalar nr, nc, i, j, k, M, w, sum_w, sum_v
    real matrix out

    nr = rows(X)
    nc = cols(X)
    M  = ceil(2 * sigma)
    out = J(nr, nc, .)

    for (i = 1; i <= nr; i++) {
        for (j = 1; j <= nc; j++) {
            sum_w = 0
            sum_v = 0
            for (k = max((1, j - M)); k <= min((nc, j + M)); k++) {
                w = exp(-0.5 * ((k - j) / sigma)^2)
                sum_w = sum_w + w
                sum_v = sum_v + w * X[i, k]
            }
            out[i, j] = sum_v / sum_w
        }
    }
    return(out)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_median_2d(): 2-D median filter on a (2M+1)x(2M+1) window.
//   Removes isolated spike pixels (Gaussian only spreads them out).
//   Standard image-processing pre-filter for streak/salt-and-pepper noise.
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_median_2d(real matrix X, real scalar M)
{
    real scalar nr, nc, i, j, k, l, cnt, mid
    real matrix out
    real colvector buf, slice

    nr  = rows(X)
    nc  = cols(X)
    out = J(nr, nc, .)
    buf = J((2*M+1)*(2*M+1), 1, .)

    for (i = 1; i <= nr; i++) {
        for (j = 1; j <= nc; j++) {
            cnt = 0
            for (k = max((1, i - M)); k <= min((nr, i + M)); k++) {
                for (l = max((1, j - M)); l <= min((nc, j + M)); l++) {
                    cnt = cnt + 1
                    buf[cnt] = X[k, l]
                }
            }
            slice = sort(buf[1..cnt], 1)
            mid = ceil((cnt + 1) / 2)
            out[i, j] = slice[mid]
        }
    }
    return(out)
}

// ═══════════════════════════════════════════════════════════════════════════
// _wv_smooth_2d(): 2-D separable Gaussian smoother (time then scale).
//   sigma_t along columns, sigma_s along rows. Used by wtc plot to wipe
//   out smoothing-window streak artefacts while preserving overall pattern.
// ═══════════════════════════════════════════════════════════════════════════
real matrix function _wv_smooth_2d(real matrix X,
                                    real scalar sigma_t,
                                    real scalar sigma_s)
{
    real scalar nr, nc, i, j, k, Mt, Ms, w, sum_w, sum_v
    real matrix tmp, out

    nr = rows(X)
    nc = cols(X)
    Mt = ceil(2 * sigma_t)
    Ms = ceil(2 * sigma_s)
    tmp = J(nr, nc, .)
    out = J(nr, nc, .)

    // First pass: smooth along time (columns).
    for (i = 1; i <= nr; i++) {
        for (j = 1; j <= nc; j++) {
            sum_w = 0
            sum_v = 0
            for (k = max((1, j - Mt)); k <= min((nc, j + Mt)); k++) {
                w = exp(-0.5 * ((k - j) / sigma_t)^2)
                sum_w = sum_w + w
                sum_v = sum_v + w * X[i, k]
            }
            tmp[i, j] = sum_v / sum_w
        }
    }

    // Second pass: smooth along scale (rows).
    for (i = 1; i <= nr; i++) {
        for (j = 1; j <= nc; j++) {
            sum_w = 0
            sum_v = 0
            for (k = max((1, i - Ms)); k <= min((nr, i + Ms)); k++) {
                w = exp(-0.5 * ((k - i) / sigma_s)^2)
                sum_w = sum_w + w
                sum_v = sum_v + w * tmp[k, j]
            }
            out[i, j] = sum_v / sum_w
        }
    }

    return(out)
}

end
