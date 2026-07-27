{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpstat methods" "help xtpstat_methods"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpstat##syntax"}{...}
{viewerjumpto "Description" "xtpstat##description"}{...}
{viewerjumpto "Options" "xtpstat##options"}{...}
{viewerjumpto "Examples" "xtpstat##examples"}{...}
{viewerjumpto "Stored results" "xtpstat##results"}{...}
{viewerjumpto "Interpreting the output" "xtpstat##interpret"}{...}
{viewerjumpto "References" "xtpstat##refs"}{...}
{title:Title}

{phang}
{bf:xtpstat} {hline 2} Panel {it:stationarity} tests robust to cross-sectional
dependence: Yin-Wu (2000), Bai-Ng (2005) PANIC, and Hadri-Kurozumi (2012)
cross-section-augmented KPSS combination tests

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtpstat} {varname} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt meth:od(string)}}CSD correction: {cmd:yinwu} (none), {cmd:panic}
(principal components, default), or {cmd:hkca} (cross-section averages){p_end}
{synopt:{opt mod:el(string)}}deterministic terms: {cmd:constant} or {cmd:trend} (default){p_end}
{synopt:{opt k:max(#)}}maximum number of common factors (PANIC only; default 5){p_end}
{synopt:{opt icf:actor(#)}}factor-number criterion: 1=PCp, 2=ICp (default), 3=AIC/BIC{p_end}
{synopt:{opt f:actors(#)}}override the estimated number of factors with a fixed value{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpstat} implements the PANIC panel {it:stationarity} test of Bai and Ng
(2005) — the stationarity counterpart of {helpb xtpanic}. Common factors are
extracted from the differenced data by principal components; the idiosyncratic
component is cumulated and tested for {it:stationarity} with a KPSS statistic;
and the resulting p-values are combined into the panel statistics {bf:Ppc}
(Fisher chi-square), {bf:Pm} (standardized normal), {bf:Zpc} (inverse-normal /
Choi) and {bf:W} (Hadri-type LM). Removing the common factors first makes the
test robust to strong cross-sectional dependence of an unknown form.

{pstd}
The long-run variance for the KPSS statistic is estimated with the
Sul-Phillips-Choi (2003) prewhitened Bartlett kernel; p-values use the paper's
response surface. {cmd:xtpstat} is part of the {helpb xtpdroot:xtpdroot}
library. See {helpb xtpstat_methods:help xtpstat methods} for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt model(string)}: {cmd:constant} (level stationarity) or {cmd:trend}
(trend stationarity, the default).

{phang}{opt kmax(#)}, {opt icfactor(#)}: the maximum number of common factors
(default 5) and the Bai-Ng (2002) criterion (default ICp). The number of factors
is the ICp2 minimizer.

{phang}{opt factors(#)} fixes the number of common factors at {it:#} instead of
estimating it (useful for replication or sensitivity analysis).

{marker examples}{...}
{title:Examples}

{pstd}Trend-stationarity of a panel with common factors removed:{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtpstat lco2, model(trend)}{p_end}

{pstd}Fix the number of factors at 3 (e.g. to match a published study):{p_end}
{phang2}{cmd:. xtpstat lco2, model(trend) factors(3)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpstat} is {cmd:rclass} and stores:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(Ppc)}, {cmd:r(Ppc_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pm)}, {cmd:r(Pm_p)}}standardized panel statistic and p-value{p_end}
{synopt:{cmd:r(Zpc)}, {cmd:r(Zpc_p)}}inverse-normal (Choi) statistic and p-value{p_end}
{synopt:{cmd:r(W)}, {cmd:r(W_p)}}Hadri-type LM statistic and p-value{p_end}
{synopt:{cmd:r(nf)}}number of common factors{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit {it:id}, KPSS statistic, p-value{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is that the idiosyncratic component is {it:stationary}. All of {bf:Ppc},
{bf:Pm} and {bf:W} {bf:reject for large values} (and {bf:Zpc} for very negative
values), i.e. reject stationarity in favour of a unit root. Because the common
factors are removed first, a rejection reflects genuine non-stationarity in the
unit-specific dynamics rather than shared co-movement.

{marker refs}{...}
{title:References}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{phang}Sul, D., P. C. B. Phillips, and C.-Y. Choi. 2005. Prewhitening bias in HAC
estimation. {it:Oxford Bulletin of Economics and Statistics} 67: 517-546.{p_end}

{phang}Nazlioglu, S., et al. 2021. Convergence in OPEC carbon dioxide emissions.
{it:Economic Modelling} 100: 105498.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routine {cmd:BNG_PANICkpss} by S. Nazlioglu;
validated byte-for-byte against the GAUSS output on the OPEC CO2 data (P=61.710;
subgroup P=9.152). Part of the {helpb xtpdroot:xtpdroot} library.{p_end}
