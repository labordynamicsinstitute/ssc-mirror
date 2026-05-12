{smcl}
{* *! version 1.0.0  2026-05-10}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:xwt} {hline 2}}Cross-Wavelet Transform{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}{cmd:xwt} {it:var1 var2} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt dt(#)} {opt m:other(name)} {opt pa:ram(#)} {opt dj(#)} {opt s0(#)}
{opt nod:isplay}]

{title:Description}

{pstd}
{cmd:xwt} computes the Cross-Wavelet Transform W_xy = W_x * conj(W_y),
where W_x and W_y are the continuous wavelet transforms of {it:var1}
and {it:var2}. The cross-wavelet identifies regions of common power and
relative phase in the time-frequency plane.

{pstd}
For coherence (normalized cross-wavelet), use {helpb wtc}.

{title:Options}

{phang}{opt dt(#)} time step (default 1){p_end}
{phang}{opt mother(name)} mother wavelet: {bf:morlet} (default),
{bf:paul}, {bf:dog}{p_end}
{phang}{opt param(#)} mother-specific parameter (-1 = use mother default){p_end}
{phang}{opt dj(#)} scale spacing in sub-octaves (default 0.25){p_end}
{phang}{opt s0(#)} smallest scale (default 2*dt){p_end}
{phang}{opt nodisplay} suppress text results table{p_end}

{title:Phase interpretation}

{pmore}
{cmd:e(phase)} contains the phase of W_xy in radians:

{phang2}0    in-phase{p_end}
{phang2}+pi/2 var1 leads var2 by 1/4 cycle{p_end}
{phang2}-pi/2 var2 leads var1 by 1/4 cycle{p_end}
{phang2}+/-pi anti-phase{p_end}

{title:Examples}

{phang2}{cmd:. xwt gdp inflation, dt(0.25)}{p_end}
{phang2}{cmd:. mat list e(power)}{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(power)}}cross-wavelet amplitude |W_xy| (nscale x N){p_end}
{synopt:{cmd:e(phase)}}phase of W_xy in radians (nscale x N){p_end}
{synopt:{cmd:e(period)}}Fourier period vector{p_end}
{synopt:{cmd:e(scale)}}wavelet scale vector{p_end}
{synopt:{cmd:e(coi)}}cone of influence{p_end}

{title:Also see}

{psee}{helpb wavelet}, {helpb wt}, {helpb wtc}{p_end}
