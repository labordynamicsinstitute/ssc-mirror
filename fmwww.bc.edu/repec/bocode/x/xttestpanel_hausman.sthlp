{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{vieweralsosee "hausman" "help hausman"}{...}
{title:Title}

{phang}
{bf:xttestpanel hausman} {hline 2} FE-vs-RE specification test (classical + robust)

{title:Syntax}

{p 8 17 2}
{cmd:xttestpanel hausman} [{depvar} {indepvars}] {ifin}
[{cmd:,} {opt tune(#)} {opt graph}]

{pstd}
Postestimation form (no varlist) reuses the last {helpb xtreg}; the test always fits
both FE and RE internally, so {opt model()} is not needed.

{title:Description}

{pstd}
{cmd:xttestpanel hausman} tests whether the random-effects estimator is consistent,
i.e. whether the regressors are uncorrelated with the unit effects. It fits both FE
and RE internally and reports two statistics:

{p 8 8 2}o {bf:Classical Hausman} {hline 1} the standard Hausman (1978) contrast
{it:(b_FE - b_RE)' (V_FE - V_RE)^(-1) (b_FE - b_RE)}, computed by calling Stata's
built-in {helpb hausman}. It therefore reproduces {cmd:hausman}'s chi-squared and
degrees of freedom {bf:exactly}.{p_end}
{p 8 8 2}o {bf:Robust weighted Hausman} {hline 1} a {bf:Mundlak (1978)}
auxiliary-regression test (the group means of the regressors are added to the RE-GLS
equation and tested jointly) computed after {bf:Huber down-weighting} of
outlying/high-leverage observations, with a cluster-robust (by unit) variance,
following the robust specification test of {bf:Beyaztas, Bandyopadhyay & Mandal
(2021)}. A large gap between the classical and robust statistics flags influential
observations driving the classical decision.{p_end}

{pstd}
You can verify the classical row against the built-in command:{p_end}
{p 8 12 2}{cmd:. xtreg y x1 x2, fe}{break}{cmd:. estimates store fe}{break}{cmd:. xtreg y x1 x2, re}{break}{cmd:. estimates store re}{break}{cmd:. hausman fe re}{p_end}

{pstd}
{bf:Decision:} reject H0 => the RE estimator is inconsistent => prefer fixed effects.

{title:Options}

{phang}{opt tune(#)} Huber tuning constant for the robust weights; default {cmd:1.345}
(95% Gaussian efficiency). Smaller => more aggressive down-weighting.{p_end}
{phang}{opt graph} histogram and kernel density of the composite residuals (u+e); fat
tails indicate that the classical Hausman test may be unreliable.{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(hausman)}}classical Hausman statistic{p_end}
{synopt:{cmd:r(p_hausman)}}its p-value{p_end}
{synopt:{cmd:r(robust_hausman)}}robust weighted statistic{p_end}
{synopt:{cmd:r(p_robust)}}its p-value{p_end}
{synopt:{cmd:r(pct_down)}}% of observations down-weighted{p_end}
{synopt:{cmd:r(df)}}degrees of freedom{p_end}

{title:Examples}

{phang2}{cmd:. xttestpanel hausman ln_wage age tenure hours, graph}{p_end}
{phang2}{cmd:. xttestpanel hausman ln_wage age tenure hours, tune(1.0)}{p_end}

{title:References}

{phang}Beyaztas, B.H., S. Bandyopadhyay, and A. Mandal. 2021. {it:arXiv:2104.07723}.{p_end}
{phang}Mundlak, Y. 1978. {it:Econometrica} 46: 69-85.{p_end}
{phang}Hausman, J.A. 1978. {it:Econometrica} 46: 1251-1271.{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
