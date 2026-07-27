{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpanicsb methods" "help xtpanicsb_methods"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtfaclm" "help xtfaclm"}{...}
{vieweralsosee "xtbreaklm" "help xtbreaklm"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpanicsb##syntax"}{...}
{viewerjumpto "Description" "xtpanicsb##description"}{...}
{viewerjumpto "Options" "xtpanicsb##options"}{...}
{viewerjumpto "Examples" "xtpanicsb##examples"}{...}
{viewerjumpto "Stored results" "xtpanicsb##results"}{...}
{viewerjumpto "Interpreting the output" "xtpanicsb##interpret"}{...}
{viewerjumpto "References" "xtpanicsb##refs"}{...}
{title:Title}

{phang}
{bf:xtpanicsb} {hline 2} PANIC panel unit-root test with sharp structural breaks
(Bai and Carrion-i-Silvestre 2009)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtpanicsb} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(string)}}break specification: {cmd:constant} (level breaks) or
{cmd:trend} (level & trend breaks, default){p_end}
{synopt:{opt b:reaks(#)}}number of structural breaks per unit (default 2){p_end}
{synopt:{opt k:max(#)}}maximum number of common factors (default 2){p_end}
{synopt:{opt pb:ar(#)}}lags for the prewhitened long-run variance (default 3){p_end}
{synopt:{opt t:rim(#)}}trimming fraction for the break search (default 0.15){p_end}
{synopt:{opt f:actors(#)}}fix the number of common factors instead of estimating{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpanicsb} implements the PANIC panel unit-root test with sharp structural
breaks of Bai and Carrion-i-Silvestre (2009). For each unit the break dates are
estimated by the Bai-Perron (1998) dynamic-programming global minimiser, common
factors are extracted from the break-adjusted first differences by principal
components (iterated with the break estimation until the idiosyncratic variance
stabilises), and the {it:modified Sargan-Bhargava} (MSB) statistic is computed on
the cumulated idiosyncratic component. The unit p-values come from the finite-
sample response surface of Bai and Carrion-i-Silvestre and are pooled into the
Fisher-type panel statistics {bf:Pval-chi} and {bf:Pval-normal} (the simplified
tests that account for the estimated breaks).

{pstd}
Removing the common factors makes the test robust to strong cross-sectional
dependence, while the sharp breaks accommodate structural change of unknown
timing. {cmd:xtpanicsb} is part of the {helpb xtpdroot:xtpdroot} library. See
{helpb xtpanicsb_methods:help xtpanicsb methods} for the algorithm.

{marker options}{...}
{title:Options}

{phang}{opt model(string)}: {cmd:trend} (breaks in level and trend, the default) or
{cmd:constant} (level breaks only).

{phang}{opt breaks(#)}: the number of breaks per unit (default 2). With
{cmd:trim(0.15)} the maximum is 5.

{phang}{opt kmax(#)}, {opt factors(#)}: the maximum number of common factors
(default 2), estimated by the Bai-Ng (2002) panel BIC; or fixed at {it:#} with
{opt factors()}.

{phang}{opt pbar(#)}: the autoregressive order for the Sul-Phillips-Choi
prewhitened long-run variance (default 3).

{phang}{opt trim(#)}: the fraction trimmed at each end in the break search
(default 0.15), which also caps the maximum number of breaks.

{marker examples}{...}
{title:Examples}

{pstd}PANIC test with two level-and-trend breaks:{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtpanicsb lrgdp, model(trend) breaks(2)}{p_end}

{pstd}Level breaks only, one common factor imposed:{p_end}
{phang2}{cmd:. xtpanicsb lrgdp, model(constant) factors(1)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpanicsb} is {cmd:rclass} and stores:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(Pchi)}, {cmd:r(Pchi_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pnorm)}, {cmd:r(Pnorm_p)}}standardized panel statistic and p-value{p_end}
{synopt:{cmd:r(nf)}}number of common factors{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit {it:id}, MSB, p-value, break1, break2, lag{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is a unit root in each panel. The per-unit MSB statistic {bf:rejects for
small values}, and the panel {bf:Pval-chi} and {bf:Pval-normal} reject for large
values, in favour of stationarity of the idiosyncratic component once common
factors and sharp breaks are removed. The break columns report the estimated
break {it:periods} in the units of your time variable.

{dlgtab:A note on reproducibility}

{pstd}
The per-unit MSB statistics, estimated break dates and the number of common
factors reproduce the source GAUSS routine (Bai and Carrion-i-Silvestre) to the
last reported digit. The pooled {bf:Pval-chi} / {bf:Pval-normal} are computed from
the same finite-sample response surface; because that surface is extremely steep
(the p-value is a logistic function with very large coefficients applied to the
regime-partitioned statistic), it magnifies the last one or two significant digits
of the iterated idiosyncratic component, and the pooled p-value can differ slightly
across linear-algebra libraries even when every per-unit statistic matches.

{marker refs}{...}
{title:References}

{phang}Bai, J., and J. L. Carrion-i-Silvestre. 2009. Structural changes, common
stochastic trends, and unit roots in panel data. {it:Review of Economic Studies}
76: 471-501.{p_end}

{phang}Bai, J., and P. Perron. 1998. Estimating and testing linear models with
multiple structural changes. {it:Econometrica} 66: 47-78.{p_end}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routines of J. L. Carrion-i-Silvestre
(carrionlib / Panicbrk); the per-unit MSB statistics, break dates and factor count
were validated byte-for-byte against the GAUSS output on the health-expenditure
panel. Part of the {helpb xtpdroot:xtpdroot} library.{p_end}
