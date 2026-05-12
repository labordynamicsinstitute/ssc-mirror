{smcl}
{* *! version 1.0.0  2026-05-10}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:wtc} {hline 2}}Wavelet Coherence with Monte-Carlo significance{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}{cmd:wtc} {it:var1 var2} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt dt(#)} {opt m:other(name)} {opt pa:ram(#)} {opt dj(#)}
{opt s0(#)} {opt nrands(#)} {opt plot} {opt col:ormap(name)} {opt nod:isplay}]

{title:Description}

{pstd}
{cmd:wtc} computes wavelet coherence between two time series. Coherence
is the localized correlation in the time-frequency plane:

{pmore}
R²(s,t) = |S(s^-1 W_xy)|² / [S(s^-1 |W_x|²) * S(s^-1 |W_y|²)]

{pstd}
where S is a smoothing operator (Gaussian in time, boxcar in scale)
following Torrence & Webster (1999). Statistical significance is tested
via Monte Carlo simulation against AR(1) surrogate pairs (default
{cmd:nrands(300)}).

{pstd}
The CWT pre-processing applies a 5% cosine taper plus anti-symmetric
edge reflection before the FFT, eliminating the high-frequency ringing
artefacts that produce streaks in zero-padded implementations.

{title:Options}

{phang}{opt dt(#)} time step (default 1){p_end}
{phang}{opt mother(name)} mother wavelet: {bf:morlet} (default),
{bf:paul}, {bf:dog}{p_end}
{phang}{opt param(#)} mother-specific parameter (-1 = use mother's
default: 6 for morlet, 4 for paul, 2 for dog){p_end}
{phang}{opt dj(#)} scale spacing in sub-octaves (default 0.25){p_end}
{phang}{opt s0(#)} smallest scale (default 2*dt){p_end}
{phang}{opt nrands(#)} number of Monte Carlo surrogates (default 300).
Set higher (1000+) for tight publication confidence intervals; lower
(50-100) for fast exploration{p_end}
{phang}{opt plot} produce a Grinsted-style coherence heatmap with:
log-period y-axis, dashed cone-of-influence line, phase arrows
(drawn where R² > 0.5), and a 2-D smoothing/median display filter{p_end}
{phang}{opt colormap(name)} heatmap colormap: {bf:jet} (default,
matches Grinsted toolbox), {bf:parula}, {bf:turbo}{p_end}
{phang}{opt nodisplay} suppress the text results table{p_end}

{title:Phase-arrow convention}

{pmore}
Arrows are sub-sampled across the time/scale grid; direction encodes
the phase of W_xy at that point:

{phang2}{cmd:>}  in-phase (var1 and var2 move together){p_end}
{phang2}{cmd:<}  anti-phase (move opposite){p_end}
{phang2}{cmd:^}  var1 leads var2 by 1/4 cycle{p_end}
{phang2}{cmd:v}  var2 leads var1 by 1/4 cycle{p_end}

{title:Examples}

{phang2}{cmd:. wtc gdp inflation, dt(0.25) plot}{p_end}
{phang2}{cmd:. wtc gdp inflation, nrands(1000) plot colormap(parula)}{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(dt)}}time step{p_end}
{synopt:{cmd:e(nrands)}}Monte Carlo surrogate count{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:wtc}{p_end}
{synopt:{cmd:e(var1)} {cmd:e(var2)}}variable names{p_end}
{synopt:{cmd:e(mother)}}mother wavelet used{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(rsq)}}coherence R² (nscale x N){p_end}
{synopt:{cmd:e(phase)}}phase difference in radians (nscale x N){p_end}
{synopt:{cmd:e(signif)}}MC significance threshold per scale (nscale x 1){p_end}
{synopt:{cmd:e(period)}}Fourier period vector{p_end}
{synopt:{cmd:e(scale)}}wavelet scale vector{p_end}
{synopt:{cmd:e(coi)}}cone-of-influence period at each time (N x 1){p_end}

{title:References}

{phang}Grinsted, A., Moore, J.C., Jevrejeva, S. (2004). Application of
the cross wavelet transform and wavelet coherence to geophysical time
series. {it:Nonlin. Proc. Geophys.} 11: 561-566.{p_end}

{phang}Torrence, C., Webster, P.J. (1999). Interdecadal changes in the
ENSO-monsoon system. {it:J. Climate} 12: 2679-2690.{p_end}

{title:Also see}

{psee}{helpb wavelet}, {helpb wt}, {helpb xwt}{p_end}
