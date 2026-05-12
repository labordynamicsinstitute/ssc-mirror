{smcl}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:wmxcorr} {hline 2}}Wavelet Multiple Cross-Correlation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}{cmd:wmxcorr} {it:varlist} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt maxlag(#)} {opt level(#)}
{opt plot} {opt nod:isplay}]

{title:Description}

{pstd}
{cmd:wmxcorr} computes wavelet multiple cross-correlation at each scale
for lags -maxlag to +maxlag. At each lag, it constructs the lagged
pairwise correlation matrix from MODWT coefficients and computes the
multiple R via matrix inversion. This enables lead-lag detection across
different frequency bands.

{title:Options}

{phang}{opt maxlag(#)} maximum lag to compute (default 10){p_end}
{phang}{opt level(#)} confidence level (default 0.95){p_end}
{phang}{opt plot} produce cross-correlation lag plot{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(xcorr}{it:j}{cmd:)}}cross-correlation at level j (1 × nlags){p_end}
{synopt:{cmd:e(ci_lo}{it:j}{cmd:)}}lower CI at level j{p_end}
{synopt:{cmd:e(ci_up}{it:j}{cmd:)}}upper CI at level j{p_end}
{synopt:{cmd:e(ymaxr)}}variable with max R² per scale{p_end}

{title:Also see}

{psee}{helpb wavelet}, {helpb wmcorr}, {helpb wmreg}{p_end}
