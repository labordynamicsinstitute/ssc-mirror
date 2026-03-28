{smcl}
{* *! version 2.0.0  26mar2026}{...}
{vieweralsosee "xtpcointegwe" "help xtpcointegwe"}{...}
{vieweralsosee "xtpkpss" "help xtpkpss"}{...}
{viewerjumpto "Syntax" "xtpcointegboot##syntax"}{...}
{viewerjumpto "Description" "xtpcointegboot##description"}{...}
{viewerjumpto "Options" "xtpcointegboot##options"}{...}
{viewerjumpto "Stored results" "xtpcointegboot##stored"}{...}
{viewerjumpto "Examples" "xtpcointegboot##examples"}{...}
{viewerjumpto "References" "xtpcointegboot##references"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:xtpcointegboot} {hline 2}}Bootstrap panel cointegration test (Westerlund-Edgerton, 2007){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpcointegboot}
{depvar} {indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(string)}}deterministic specification; {bf:constant} or {bf:trend}; default is {bf:constant}{p_end}
{synopt:{opt esti:mator(string)}}VAR estimator; {bf:ols} or {bf:yw} (Yule-Walker); default is {bf:yw}{p_end}
{synopt:{opt lags(#)}}VAR lag order for sieve bootstrap; default = int(4*(T/100)^(2/9)){p_end}
{synopt:{opt nboot(#)}}number of bootstrap replications; default is 399{p_end}
{synopt:{opt gr:aph}}display bootstrap distribution histogram{p_end}
{synoptline}

{pstd}
A balanced panel must be declared via {cmd:xtset} {it:panelvar} {it:timevar} before calling {cmd:xtpcointegboot}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpcointegboot} implements the bootstrap panel cointegration test proposed by
Westerlund and Edgerton (2007, {it:Economics Letters}).
The test examines the null hypothesis of {bf:cointegration} (i.e., all panel units
are cointegrated) against the alternative that at least some units are not
cointegrated.

{pstd}
The procedure computes the McCoskey and Kao (1998) LM+ test statistic from
{bf:fully modified OLS (FM-OLS)} residuals.  The FM-OLS estimator adjusts
for endogeneity and serial correlation in the cointegrating regression.
The standardized panel statistic aggregates individual LM statistics,
recentered by mean and variance correction factors that depend on the
number of regressors.

{pstd}
Because the asymptotic critical values are poorly sized when cross-sectional
dependence is present, the test employs a {bf:sieve bootstrap} to generate
panel-specific critical values.  The bootstrap scheme fits a VAR to the
first-differenced data (using OLS or Yule-Walker), generates pseudo-data from
the AR filter with resampled innovations, and recomputes the LM+ statistic
in each replication.  The bootstrap p-value measures the proportion of
bootstrap statistics that exceed the observed value.

{pstd}
Both asymptotic and bootstrap p-values are reported.  Rejection occurs in the
{bf:right tail}: large positive values indicate evidence against cointegration.


{marker options}{...}
{title:Options}

{phang}{opt model(string)} specifies the deterministic component:

{p 12 16 2}{bf:constant}: individual intercepts only.{p_end}
{p 12 16 2}{bf:trend}: individual intercepts and linear time trends.{p_end}

{phang}{opt estimator(string)} specifies the VAR estimation method for the sieve bootstrap:

{p 12 16 2}{bf:yw}: Yule-Walker estimation (recommended).  Ensures stationarity of the fitted AR process.{p_end}
{p 12 16 2}{bf:ols}: ordinary least squares estimation.{p_end}

{phang}{opt lags(#)} sets the lag order for the sieve bootstrap VAR.
Default is int(4*(T/100)^(2/9)), the Andrews-Schwarz rule.

{phang}{opt nboot(#)} the number of bootstrap replications.
Default is 399.  Increasing this improves the precision of the bootstrap
p-value at the cost of computation time.

{phang}{opt graph} displays a histogram of the bootstrap distribution of
the LM+ statistic, with a vertical line marking the observed sample value.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtpcointegboot} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(lm)}}normalized LM+ test statistic{p_end}
{synopt:{cmd:r(boot_pval)}}bootstrap p-value{p_end}
{synopt:{cmd:r(asym_pval)}}asymptotic p-value{p_end}
{synopt:{cmd:r(mu)}}adjustment mean (E[LM+] under H0){p_end}
{synopt:{cmd:r(vr)}}adjustment variance (Var[LM+] under H0){p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(K)}}number of independent variables{p_end}
{synopt:{cmd:r(lags)}}VAR lag order used{p_end}
{synopt:{cmd:r(nboot)}}number of bootstrap replications{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(indiv_lm)}}individual LM statistics (N x 1){p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(model)}}model label{p_end}
{synopt:{cmd:r(estimator)}}estimator label{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable name(s){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Setup: balanced panel with cointegrated y and x{p_end}
{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Constant model with bootstrap (default Yule-Walker){p_end}
{phang2}{cmd:. xtpcointegboot y x, model(constant) nboot(399)}{p_end}

{pstd}Trend model with OLS estimator and histogram{p_end}
{phang2}{cmd:. xtpcointegboot y x, model(trend) estimator(ols) nboot(199) graph}{p_end}

{pstd}Custom lag order{p_end}
{phang2}{cmd:. xtpcointegboot y x, model(constant) lags(4) nboot(999)}{p_end}


{marker references}{...}
{title:References}

{phang}
Westerlund, J. and D.L. Edgerton. 2007.
A panel bootstrap cointegration test.
{it:Economics Letters} 97(3): 185-190.
{p_end}

{phang}
McCoskey, S.K. and C. Kao. 1998.
A residual-based test of the null of cointegration in panel data.
{it:Econometric Reviews} 17(1): 57-84.
{p_end}

{phang}
Pedroni, P. 2004.
Panel cointegration: asymptotic and finite sample properties of pooled
time series tests with an application to the PPP hypothesis.
{it:Econometric Theory} 20(3): 597-625.
{p_end}


{title:Authors}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com
{p_end}

{title:Also see}

{psee}
Online: {manhelp xtset XT}, {manhelp xtunitroot XT}
{p_end}
{psee}
{helpb xtpcointegwe}, {helpb xtpkpss}
{p_end}
