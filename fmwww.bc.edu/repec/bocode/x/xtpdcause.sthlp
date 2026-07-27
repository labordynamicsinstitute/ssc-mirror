{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpdcause methods" "help xtpdcause_methods"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtpstat" "help xtpstat"}{...}
{vieweralsosee "xtbreaklm" "help xtbreaklm"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpdcause##syntax"}{...}
{viewerjumpto "Description" "xtpdcause##description"}{...}
{viewerjumpto "Options" "xtpdcause##options"}{...}
{viewerjumpto "Examples" "xtpdcause##examples"}{...}
{viewerjumpto "Stored results" "xtpdcause##results"}{...}
{viewerjumpto "Interpreting the output" "xtpdcause##interpret"}{...}
{viewerjumpto "References" "xtpdcause##refs"}{...}
{title:Title}

{phang}
{bf:xtpdcause} {hline 2} Panel Granger non-causality testing robust to
cross-sectional dependence (factor-corrected lag-augmented VAR)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtpdcause} {it:depvar} {it:causevar} {ifin} [{cmd:,} {it:options}]

{pstd}The data must be {helpb xtset} as a {bf:strongly balanced} panel. The test
is of the null that {it:causevar} does {bf:not} Granger-cause {it:depvar}.{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt meth:od(string)}}CSD correction: {cmd:panic} (principal-component
factors, default), {cmd:panicca} (cross-section averages) or {cmd:none}{p_end}
{synopt:{opt p:max(#)}}maximum VAR lag order (default 4){p_end}
{synopt:{opt d:max(#)}}number of extra (augmenting) lags = max integration order
(default 1){p_end}
{synopt:{opt ic(#)}}lag-selection criterion: 1=AIC, 2=BIC (default){p_end}
{synopt:{opt k:max(#)}}maximum number of common factors (PANIC only; default 3){p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpdcause} implements the panel Granger-causality test of Nazlioglu and
Karul (2024), which controls for cross-sectional dependence through a common-
factor structure before testing for causality. Each unit is estimated as a
bivariate {it:lag-augmented} VAR (Toda-Yamamoto): the VAR is fitted with the
selected lag order {it:p} plus {it:dmax} extra lags, and a Wald statistic tests
that the {it:p} lags of {it:causevar} are jointly zero in the {it:depvar}
equation. The extra lags make the Wald statistic asymptotically chi-square
regardless of the integration/cointegration properties of the series, so no
pre-testing for unit roots or cointegration is required.

{pstd}
The unit-specific Wald p-values are pooled into the Fisher panel statistics
{bf:P} (chi-square) and {bf:Pm} (standardized normal), and Holm-adjusted
individual p-values are reported to locate which panels drive a rejection.

{pstd}
{opt method(panic)} removes common factors by principal components from the
standardized first differences (Bai-Ng 2004 PANIC); the number of factors is the
Bai-Ng (2002) IC2 minimizer. {opt method(panicca)} removes a single common
factor proxied by the cross-section averages (Pesaran-type CCE). {opt method(none)}
runs the lag-augmented VAR on the raw data with an intercept (no CSD correction).
{cmd:xtpdcause} is part of the {helpb xtpdroot:xtpdroot} library. See
{helpb xtpdcause_methods:help xtpdcause methods} for the formulas.

{marker options}{...}
{title:Options}

{phang}{opt method(string)}: {cmd:panic} (default) extracts principal-component
factors; {cmd:panicca} uses cross-section averages; {cmd:none} applies no
correction (with a VAR intercept).

{phang}{opt pmax(#)}, {opt ic(#)}: the maximum VAR lag order (default 4) and the
information criterion (1=AIC, 2=BIC, the default) used to select {it:p} per unit.

{phang}{opt dmax(#)}: the number of augmenting lags, equal to the maximal
suspected order of integration (default 1). These lags are added but not tested.

{phang}{opt kmax(#)}: the maximum number of common factors when
{cmd:method(panic)} (default 3).

{marker examples}{...}
{title:Examples}

{pstd}Does {cmd:export} Granger-cause {cmd:gdp}, factors removed by PANIC?{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. xtpdcause gdp export, method(panic)}{p_end}

{pstd}The reverse direction, and the cross-section-average correction:{p_end}
{phang2}{cmd:. xtpdcause export gdp, method(panic)}{p_end}
{phang2}{cmd:. xtpdcause gdp export, method(panicca)}{p_end}

{pstd}No CSD correction, AIC lag selection, allow I(2):{p_end}
{phang2}{cmd:. xtpdcause gdp export, method(none) ic(1) dmax(2)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtpdcause} is {cmd:rclass} and stores:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(P)}, {cmd:r(P_p)}}Fisher chi-square panel statistic and p-value{p_end}
{synopt:{cmd:r(Pm)}, {cmd:r(Pm_p)}}standardized panel statistic and p-value{p_end}
{synopt:{cmd:r(nf)}}number of common factors (PANIC/PANIC-CA){p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel and time dimensions{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtpdcause}{p_end}
{synopt:{cmd:r(depvar)}, {cmd:r(cause)}}the tested variables{p_end}
{synopt:{cmd:r(method)}}{cmd:panic}, {cmd:panicca} or {cmd:none}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(units)}}per-unit {it:id}, Wald, p-value, Holm-adjusted p, lag{p_end}
{p2colreset}{...}

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
The null is that {it:causevar} does not Granger-cause {it:depvar} in {it:any}
panel. Both {bf:P} and {bf:Pm} {bf:reject for large values}. A rejection means
{it:causevar} Granger-causes {it:depvar} in at least one panel; the Holm-adjusted
per-unit p-values identify which. Because the common factors are removed first
(PANIC / PANIC-CA), the causal inference is not contaminated by shared global
shocks.

{marker refs}{...}
{title:References}

{phang}Nazlioglu, S., and M. Karul. 2024. Panel Granger causality with
cross-sectional dependence: a common-factor approach. {it:Empirical Economics}.{p_end}

{phang}Toda, H. Y., and T. Yamamoto. 1995. Statistical inference in vector
autoregressions with possibly integrated processes. {it:Journal of Econometrics}
66: 225-250.{p_end}

{phang}Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.{p_end}

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Faithful Stata port of the GAUSS routines by S. Nazlioglu (Nazlioglu-Karul
2024); the LA-VAR, PANIC and PANIC-CA panel statistics were validated
byte-for-byte against the GAUSS output. Part of the {helpb xtpdroot:xtpdroot}
library.{p_end}
