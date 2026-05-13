{smcl}
{* *! version 1.1.0  2026-05-11}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:wmcorr} {hline 2}}Wavelet Multiple Correlation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:wmcorr} {it:varlist} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt level(#)} {opt plot} {opt nod:isplay}]

{title:Description}

{pstd}
{cmd:wmcorr} computes the wavelet multiple correlation of Fernandez-Macho
(2012). At each wavelet scale j, it:

{p 8 12 2}
1. Decomposes all variables via MODWT{break}
2. Computes the d×d pairwise correlation matrix P{break}
3. Inverts P and finds max(diag(P^-1)){break}
4. R_j = sqrt(1 - 1/max(diag(P^-1))){break}
5. The variable achieving max R² is labeled {bf:YmaxR}

{pstd}
This {bf:YmaxR} innovation means the dependent variable may change across
scales — a key methodological contribution.

{title:Options}

{phang}{opt levels(#)} decomposition levels (default 4){p_end}
{phang}{opt filter(name)} wavelet filter (default la8){p_end}
{phang}{opt level(#)} confidence level for CI (default 0.95){p_end}
{phang}{opt plot} produce scale-by-scale correlation plot with CI{p_end}

{title:Examples}

{phang2}{cmd:. wmcorr x1 x2 x3, levels(4) filter(la8) plot}{p_end}
{phang2}{cmd:. mat list e(wmcorr)}{p_end}
{phang2}{cmd:. mat list e(ymaxr)}{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(wmcorr)}}J × 3 matrix: R, CI_low, CI_up{p_end}
{synopt:{cmd:e(ymaxr)}}J × 1 vector: variable with max R² per scale{p_end}
{synopt:{cmd:e(N_eff)}}J × 1 vector: effective sample size per scale{p_end}

{title:Reference}

{phang}Fernandez-Macho, J. (2012). Wavelet multiple correlation and
cross-correlation: A multiscale analysis of Eurozone stock markets.
{it:Physica A} 391: 1097-1104.{p_end}

{title:Also see}

{psee}{helpb wavelet}, {helpb wmreg}, {helpb wmxcorr}, {helpb lmodwt}{p_end}
