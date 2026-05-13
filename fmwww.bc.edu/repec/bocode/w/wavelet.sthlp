{smcl}
{* *! version 1.1.0  2026-05-11}{...}
{viewerjumpto "Syntax" "wavelet##syntax"}{...}
{viewerjumpto "Description" "wavelet##description"}{...}
{viewerjumpto "Commands" "wavelet##commands"}{...}
{viewerjumpto "Examples" "wavelet##examples"}{...}
{viewerjumpto "Stored results" "wavelet##results"}{...}
{viewerjumpto "Methods" "wavelet##methods"}{...}
{viewerjumpto "References" "wavelet##references"}{...}
{viewerjumpto "Author" "wavelet##author"}{...}
{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:wavelet} {hline 2}}Wavelet analysis for time series: CWT, MODWT, XWT, WTC,
wavelet multiple correlation, wavelet multiple regression{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Main dispatcher:

{p 8 17 2}
{cmd:wavelet} {it:subcommand} [{it:varlist}] [{cmd:,} {it:options}]

{pstd}
Available subcommands:

{synoptset 14}{...}
{synopt :{help lmodwt:{bf:lmodwt}}}Maximal Overlap Discrete Wavelet Transform{p_end}
{synopt :{help wt:{bf:wt}}}Continuous Wavelet Transform (CWT){p_end}
{synopt :{help xwt:{bf:xwt}}}Cross-Wavelet Transform{p_end}
{synopt :{help wtc:{bf:wtc}}}Wavelet Coherence (with Monte Carlo significance){p_end}
{synopt :{help wmcorr:{bf:wmcorr}}}Wavelet Multiple Correlation{p_end}
{synopt :{help wmreg:{bf:wmreg}}}Wavelet Multiple Regression{p_end}
{synopt :{help wmxcorr:{bf:wmxcorr}}}Wavelet Multiple Cross-Correlation{p_end}
{synopt :{bf:about}}Package information{p_end}
{synopt :{bf:filters}}List available wavelet filters{p_end}
{synoptline}

{pstd}
Or use commands directly:

{p 8 17 2}
{help lmodwt:{cmd:lmodwt}} {it:varname} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt mra} {opt gen:erate(prefix)}]

{p 8 17 2}
{help wt:{cmd:wt}} {it:varname} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt dt(#)} {opt m:other(name)} {opt pa:ram(#)} {opt dj(#)} {opt plot}]

{p 8 17 2}
{help xwt:{cmd:xwt}} {it:var1 var2} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt dt(#)} {opt m:other(name)} {opt pa:ram(#)} {opt dj(#)}]

{p 8 17 2}
{help wtc:{cmd:wtc}} {it:var1 var2} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt dt(#)} {opt m:other(name)} {opt nrands(#)} {opt plot}]

{p 8 17 2}
{help wmcorr:{cmd:wmcorr}} {it:varlist} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt level(#)} {opt plot}]

{p 8 17 2}
{help wmreg:{cmd:wmreg}} {it:varlist} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt plot}]

{p 8 17 2}
{help wmxcorr:{cmd:wmxcorr}} {it:varlist} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt maxlag(#)} {opt plot}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:wavelet} ({bf:lwavelet}) is a comprehensive wavelet analysis package for
Stata implementing both discrete and continuous wavelet transforms, bivariate
analysis (cross-wavelet, coherence), and multivariate frequency-band analysis
(multiple correlation, regression, cross-correlation).

{pstd}
The package provides tools for decomposing time series into frequency bands,
testing for co-movement between pairs of series across scales, and performing
regression analysis at different temporal resolutions. This is the first
complete wavelet analysis package for Stata, with functionality comparable to
R packages {cmd:biwavelet}, {cmd:wavelets}, and {cmd:wavemulcor}.


{title:Installation}

{pstd}
{cmd:. ssc install lwavelet}

{pstd}
The Mata library {bf:lwavelet.mlib} ships pre-compiled with the package
and is loaded automatically by Stata on first use.  The source files
{bf:_wv_*.mata} and the build script {bf:_build_lwavelet.do} are also
included for users who wish to rebuild from source.


{marker commands}{...}
{title:Commands}

{dlgtab:Discrete Wavelet Transforms}

{phang}
{help lmodwt:{cmd:lmodwt}} {it:varname}{cmd:,} {opt levels(#)} {opt filter(name)} [{opt mra}
{opt generate(prefix)}]
{break}
Computes the Maximal Overlap Discrete Wavelet Transform. The MODWT
decomposes a time series into frequency bands (wavelet scales) using a
non-decimated pyramid algorithm. Unlike the DWT, the MODWT preserves the
original sample size at each decomposition level.

{pmore}
{opt levels(#)} specifies the number of decomposition levels J. Default is 4.
{break}
{opt filter(name)} specifies the wavelet filter. Default is {bf:la8} (Least
Asymmetric, length 8). See {cmd:wavelet filters} for full list.
{break}
{opt mra} computes the Multiresolution Analysis, decomposing the signal into
J detail components (D1,...,DJ) and one smooth component (SJ).
{break}
{opt generate(prefix)} generates variables {it:prefix}_D1,...,{it:prefix}_DJ,
{it:prefix}_SJ containing the MRA components.

{dlgtab:Continuous Wavelet Transforms}

{phang}
{help wt:{cmd:wt}} {it:varname}{cmd:,} [{opt dt(#)} {opt mother(name)} {opt param(#)}
{opt dj(#)} {opt s0(#)} {opt siglvl(#)} {opt plot} {opt colormap(name)}]
{break}
Computes the Continuous Wavelet Transform using the FFT convolution theorem.
Supports Morlet (default), Paul, and DOG mother wavelets.

{pmore}
{opt dt(#)} time step (default 1).
{break}
{opt mother(name)} mother wavelet: {bf:morlet} (default), {bf:paul}, or {bf:dog}.
{break}
{opt param(#)} mother-specific parameter (default: k0=6 for Morlet, m=4 for
Paul, m=2 for DOG).
{break}
{opt dj(#)} scale spacing in sub-octaves (default 0.25 = 4 sub-octaves).
{break}
{opt plot} produces a time-frequency power spectrum heatmap.
{break}
{opt colormap(name)} colormap for plotting: {bf:jet}, {bf:parula}, or
{bf:turbo} (default).

{phang}
{help xwt:{cmd:xwt}} {it:var1 var2}{cmd:,} [options same as {help wt:{cmd:wt}}]
{break}
Computes the Cross-Wavelet Transform: W_xy = W_x * conj(W_y). Identifies
common power and relative phase between two time series across scales.

{phang}
{help wtc:{cmd:wtc}} {it:var1 var2}{cmd:,} [{opt nrands(#)} plus options same as {help wt:{cmd:wt}}]
{break}
Computes Wavelet Coherence: R² = |S(W_xy)|² / (S(|W_x|²) * S(|W_y|²)).
Significance is tested via Monte Carlo simulation using AR(1) surrogates.

{pmore}
{opt nrands(#)} number of Monte Carlo surrogates (default 300).

{dlgtab:Multivariate Wavelet Analysis}

{phang}
{help wmcorr:{cmd:wmcorr}} {it:varlist}{cmd:,} [{opt levels(#)} {opt filter(name)}
{opt level(#)} {opt plot}]
{break}
Computes wavelet multiple correlation at each scale following
Fernandez-Macho (2012). At each scale j, the algorithm inverts the d×d
pairwise correlation matrix and computes R² = 1 - 1/max(diag(P^-1)).

{pmore}
{opt level(#)} confidence level for Fisher z-transform CI (default 0.95).
{break}
{opt plot} produces a scale-by-scale correlation plot with CI bands.

{phang}
{help wmreg:{cmd:wmreg}} {it:varlist}{cmd:,} [{opt levels(#)} {opt filter(name)} {opt plot}]
{break}
Performs OLS regression at each wavelet scale. The dependent variable is
automatically selected as the variable yielding maximum R² ({bf:YmaxR}).

{phang}
{help wmxcorr:{cmd:wmxcorr}} {it:varlist}{cmd:,} [{opt levels(#)} {opt filter(name)}
{opt maxlag(#)} {opt plot}]
{break}
Computes wavelet multiple cross-correlation at each scale for lags
-maxlag to +maxlag, enabling lead-lag analysis across frequency bands.


{marker examples}{...}
{title:Examples}

{pstd}
A single coherent walkthrough using Stata's built-in Lütkepohl quarterly
macro dataset (1960q1–1982q4, log levels of investment, income, and
consumption). The full runnable script ships with the package as
{bf:example_lwavelet.do}.

{pstd}
{bf:Setup}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}
{bf:1. MODWT decomposition of investment}

{pmore}
With N=92 quarterly observations, J=3 is the maximum admissible level
for the LA(8) filter. The three detail bands cover periods of 6–12 months
(D1), 1–2 years (D2), and 2–4 years (D3); S3 captures everything slower
than ~4 years (trend + long cycle).

{phang2}{cmd:. lmodwt inv, levels(3) filter(la8) mra generate(_inv)}{p_end}
{phang2}{cmd:. matrix list e(wvar), format(%9.4f)}{p_end}

{pstd}
{bf:2. CWT power spectrum of investment}

{phang2}{cmd:. wt inv, dt(0.25) mother(morlet) plot colormap(turbo)}{p_end}

{pstd}
{bf:3. Cross-wavelet transform inv–inc}

{phang2}{cmd:. xwt inv inc, dt(0.25) mother(morlet)}{p_end}

{pstd}
{bf:4. Wavelet coherence with Monte Carlo significance and phase arrows}

{phang2}{cmd:. wtc inv inc, dt(0.25) nrands(500) plot}{p_end}

{pstd}
{bf:5. Wavelet multiple correlation across inv, inc, consump}

{phang2}{cmd:. wmcorr inv inc consump, levels(3) filter(la8) plot}{p_end}
{phang2}{cmd:. matrix list e(wmcorr), format(%9.4f)}{p_end}
{phang2}{cmd:. matrix list e(ymaxr)}{p_end}

{pstd}
{bf:6. Wavelet multiple regression (auto-selects dependent variable per scale)}

{phang2}{cmd:. wmreg inv inc consump, levels(3) filter(la8) plot}{p_end}
{phang2}{cmd:. matrix list e(rsq), format(%9.4f)}{p_end}

{pstd}
{bf:7. Wavelet multiple cross-correlation (lead-lag, ±8 quarters)}

{phang2}{cmd:. wmxcorr inv inc consump, levels(3) filter(la8) maxlag(8) plot}{p_end}

{pstd}
To run the entire example end-to-end with narrative comments and
interpretive notes, execute the bundled script:

{phang2}{cmd:. do example_lwavelet.do}{p_end}


{marker results}{...}
{title:Stored results}

{dlgtab:lmodwt}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(J)}}number of decomposition levels{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(W{it:j})}}wavelet coefficients at level {it:j} (1 x N){p_end}
{synopt:{cmd:e(VJ)}}final-level scaling coefficients (1 x N) — named VJ because V is reserved by ereturn post{p_end}
{synopt:{cmd:e(wvar)}}wavelet variance per level (J x 1){p_end}

{dlgtab:wt}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(power)}}wavelet power spectrum (nscale x N){p_end}
{synopt:{cmd:e(period)}}Fourier period vector (nscale x 1){p_end}
{synopt:{cmd:e(scale)}}wavelet scale vector (nscale x 1){p_end}
{synopt:{cmd:e(coi)}}cone of influence (N x 1){p_end}
{synopt:{cmd:e(signif)}}significance levels (nscale x 1){p_end}

{dlgtab:wmcorr}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(wmcorr)}}correlation, CI_low, CI_up (J x 3){p_end}
{synopt:{cmd:e(ymaxr)}}variable with max R² per scale (J x 1){p_end}
{synopt:{cmd:e(N_eff)}}effective sample size per scale (J x 1){p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:MODWT:} The non-decimated pyramid algorithm applies the wavelet filter h
and scaling filter g at each level j with step size 2^(j-1) using circular
convolution:

{pmore}
W_j[t] = sum_{l=0}^{L-1} h_l * V_{j-1}[t - 2^{j-1} * l  mod  N]
{break}
V_j[t] = sum_{l=0}^{L-1} g_l * V_{j-1}[t - 2^{j-1} * l  mod  N]

{pstd}
{bf:CWT:} Computed via the FFT convolution theorem. The signal is padded to
the next power of 2, transformed to frequency domain, multiplied by the
daughter wavelet at each scale, and inverse-transformed:

{pmore}
W(a,b) = IFFT[FFT(x) * Psi*(a*omega)]

{pstd}
{bf:Wavelet Multiple Correlation:} At each scale j, compute the d×d pairwise
correlation matrix P from MODWT coefficients. Then:

{pmore}
R_j = sqrt(1 - 1/max(diag(P_j^{-1})))
{break}
CI: atanh(R) ± z_p / sqrt(n_j - 3), back-transformed via tanh().

{pstd}
{bf:Wavelet Coherence:} Smoothed cross-spectrum divided by auto-spectra:

{pmore}
R²(s,t) = |S(s^{-1} W_xy)|² / [S(s^{-1} |W_x|²) * S(s^{-1} |W_y|²)]
{break}
Smoothing: Gaussian in time, boxcar (0.6/dj) in scale.


{marker references}{...}
{title:References}

{phang}
Fernandez-Macho, J. (2012). Wavelet multiple correlation and cross-correlation:
A multiscale analysis of Eurozone stock markets.
{it:Physica A} 391: 1097-1104.

{phang}
Grinsted, A., Moore, J.C., Jevrejeva, S. (2004). Application of the cross
wavelet transform and wavelet coherence to geophysical time series.
{it:Nonlinear Processes in Geophysics} 11: 561-566.

{phang}
Liu, Y., Liang, X.S., Weisberg, R.H. (2007). Rectification of the bias in
the wavelet power spectrum. {it:J. Atmos. Oceanic Technol.} 24: 2093-2102.

{phang}
Percival, D.B., Walden, A.T. (2000). {it:Wavelet Methods for Time Series}
{it:Analysis}. Cambridge University Press.

{phang}
Torrence, C., Compo, G.P. (1998). A practical guide to wavelet analysis.
{it:Bull. Amer. Meteor. Soc.} 79: 61-78.

{phang}
Torrence, C., Webster, P.J. (1999). Interdecadal changes in the ENSO-
monsoon system. {it:J. Climate} 12: 2679-2690.

{phang}
Veleda, D., Montagne, R., Araujo, M. (2012). Cross-wavelet bias corrected by
normalizing scales. {it:J. Atmos. Oceanic Technol.} 29: 1401-1408.


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
Please cite as:{break}
Roudane, M. (2026). lwavelet: Wavelet analysis for time series in Stata.
Statistical Software Components, Boston College Department of Economics.
{p_end}


{title:Also see}

{psee}
Per-command help (click to open):

{p2colset 8 22 24 2}{...}
{p2col :{help lmodwt}}MODWT decomposition (discrete){p_end}
{p2col :{help wt}}Continuous wavelet transform{p_end}
{p2col :{help xwt}}Cross-wavelet transform{p_end}
{p2col :{help wtc}}Wavelet coherence + Monte Carlo{p_end}
{p2col :{help wmcorr}}Wavelet multiple correlation{p_end}
{p2col :{help wmreg}}Wavelet multiple regression{p_end}
{p2col :{help wmxcorr}}Wavelet multiple cross-correlation{p_end}
{p2colreset}{...}

{psee}
Stata 18+ built-in: {help modwt} (decimated DWT/MODWT — different from {help lmodwt:lmodwt}).
