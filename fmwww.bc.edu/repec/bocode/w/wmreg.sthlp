{smcl}
{* *! version 1.0.0  2026-05-10}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col:{bf:wmreg} {hline 2}}Wavelet Multiple Regression{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:wmreg} {it:varlist} [{cmd:if}] [{cmd:in}]{cmd:,}
[{opt l:evels(#)} {opt f:ilter(name)} {opt plot} {opt nod:isplay}]

{title:Description}

{pstd}
{cmd:wmreg} performs OLS regression at each wavelet scale. The dependent
variable is automatically selected via {bf:YmaxR} (the variable yielding
maximum R² at that scale). Reports coefficients, standard errors,
t-statistics, and p-values per scale.

{title:Examples}

{phang2}{cmd:. wmreg y x1 x2 x3, levels(4) plot}{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(rsq)}}R² per scale (J × 1){p_end}
{synopt:{cmd:e(ymaxr)}}dependent variable index per scale (J × 1){p_end}
{synopt:{cmd:e(beta}{it:j}{cmd:)}}coefficients at level j{p_end}
{synopt:{cmd:e(se}{it:j}{cmd:)}}standard errors at level j{p_end}
{synopt:{cmd:e(tstat}{it:j}{cmd:)}}t-statistics at level j{p_end}
{synopt:{cmd:e(pval}{it:j}{cmd:)}}p-values at level j{p_end}

{title:Also see}

{psee}{helpb wavelet}, {helpb wmcorr}, {helpb wmxcorr}{p_end}
