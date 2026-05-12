{smcl}
{* *! version 1.0.0  2026-05-10}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:wt} {hline 2}}Continuous Wavelet Transform{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:wt} {it:varname} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt dt(#)} {opt m:other(name)} {opt pa:ram(#)} {opt dj(#)} {opt s0(#)}
{opt siglvl(#)} {opt plot} {opt col:ormap(name)} {opt nod:isplay}]

{title:Description}

{pstd}
{cmd:wt} computes the Continuous Wavelet Transform (CWT) of a time series
using the FFT convolution theorem. The CWT provides a two-dimensional
representation of signal power as a function of time and frequency (period).

{pstd}
Three mother wavelets are supported:

{phang2}{bf:morlet} (default) — complex-valued, optimal time-frequency
localization, k0=6{p_end}
{phang2}{bf:paul} — complex-valued, sharper time localization, m=4{p_end}
{phang2}{bf:dog} — real-valued, Derivative of Gaussian, m=2{p_end}

{title:Options}

{phang}{opt dt(#)} time step (default 1){p_end}
{phang}{opt mother(name)} mother wavelet: morlet, paul, dog (default morlet){p_end}
{phang}{opt param(#)} wavelet-specific parameter (-1 = use default){p_end}
{phang}{opt dj(#)} scale spacing in sub-octaves (default 0.25){p_end}
{phang}{opt s0(#)} smallest scale (default 2*dt){p_end}
{phang}{opt siglvl(#)} significance level for AR(1) test (default 0.95){p_end}
{phang}{opt plot} produce time-frequency power heatmap (smooth gradient,
log-scaled period axis, colorbar in log-power units){p_end}
{phang}{opt colormap(name)} heatmap colormap: {bf:parula} (default,
MATLAB-style), {bf:jet}, {bf:turbo}{p_end}

{title:Examples}

{phang2}{cmd:. wt gdp, dt(1) mother(morlet) plot}{p_end}
{phang2}{cmd:. wt gdp, dt(1) plot colormap(jet)}{p_end}
{phang2}{cmd:. mat list e(power)}{p_end}
{phang2}{cmd:. mat list e(period)}{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(power)}}wavelet power |W|² (nscale × N){p_end}
{synopt:{cmd:e(period)}}Fourier period (nscale × 1){p_end}
{synopt:{cmd:e(scale)}}wavelet scale (nscale × 1){p_end}
{synopt:{cmd:e(coi)}}cone of influence (N × 1){p_end}
{synopt:{cmd:e(signif)}}significance level per scale (nscale × 1){p_end}

{title:References}

{phang}Torrence, C. & Compo, G.P. (1998). A practical guide to wavelet
analysis. {it:Bull. Amer. Meteor. Soc.} 79: 61-78.{p_end}

{title:Also see}

{psee}{helpb wavelet}, {helpb xwt}, {helpb wtc}{p_end}
