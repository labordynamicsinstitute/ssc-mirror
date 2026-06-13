{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel csd" "help xttestpanel_csd"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{title:Title}

{phang}
{bf:xttestpanel serial} {hline 2} Serial-correlation tests for panel-data models

{title:Syntax}

{p 8 17 2}
{cmd:xttestpanel serial} [{depvar} {indepvars}] {ifin}
[{cmd:,} {opt model(fe|re)} {opt lags(#)} {opt graph}]

{pstd}
Postestimation form (no varlist) reuses the last {helpb xtreg}; see
{helpb xttestpanel:the overview}.

{title:Description}

{pstd}
{cmd:xttestpanel serial} tests the null of {bf:no serial correlation in the
idiosyncratic errors}. From the FE (default) or RE residuals it reports three tests:

{p 8 8 2}o {bf:Baltagi-Li LM} {hline 1} a two-sided score test for AR(1)/MA(1) serial
correlation in the remainder disturbances, in the spirit of Baltagi & Li (1995) and
Baltagi, Jung & Song (2010); asymptotically chi2(1).{p_end}
{p 8 8 2}o {bf:Born-Breitung / Wooldridge robust} {hline 1} the lag-1 score test
standardised with a by-unit (cluster-robust) variance, so it is robust to
heteroskedasticity and cross-unit heterogeneity; chi2(1).{p_end}
{p 8 8 2}o {bf:Bin Chen (2022) robust portmanteau} {hline 1} a cluster-robust
portmanteau over {it:lags} lags, robust to heteroskedasticity and weak cross-sectional
dependence in the spirit of Chen (2022); chi2({it:lags}).{p_end}

{pstd}
The lag-1 residual autocorrelation rho_hat is also reported.

{title:Options}

{phang}{opt model(fe|re)} working model; default {cmd:fe}.{p_end}
{phang}{opt lags(#)} number of lags for the Chen portmanteau; default {cmd:1}.{p_end}
{phang}{opt graph} scatter of e(t) against e(t-1) with a fitted line (slope = rho).{p_end}

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(baltagi_li)}}Baltagi-Li statistic{p_end}
{synopt:{cmd:r(p_baltagi_li)}}its p-value{p_end}
{synopt:{cmd:r(chen)}}Chen portmanteau statistic{p_end}
{synopt:{cmd:r(p_chen)}}its p-value{p_end}
{synopt:{cmd:r(rho1)}}lag-1 residual autocorrelation{p_end}

{title:Examples}

{phang2}{cmd:. xttestpanel serial ln_wage age tenure hours, graph}{p_end}
{phang2}{cmd:. xttestpanel serial ln_wage age tenure hours, lags(3)}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xttestpanel serial, lags(2)}{p_end}

{title:References}

{phang}Baltagi, B.H., and Q. Li. 1995. {it:Journal of Econometrics} 68: 133-151.{p_end}
{phang}Baltagi, B.H., B.C. Jung, and S.H. Song. 2010. {it:Journal of Econometrics} 154: 122-124.{p_end}
{phang}Chen, B. 2022. {it:Econometric Reviews} 41: 1095-1112.{p_end}
{phang}Born, B., and J. Breitung. 2016. {it:Econometric Reviews} 35: 1290-1316.{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
