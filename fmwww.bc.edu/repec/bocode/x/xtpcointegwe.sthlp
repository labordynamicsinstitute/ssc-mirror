{smcl}
{* *! version 2.0.0  26mar2026}{...}
{vieweralsosee "xtpcointegboot" "help xtpcointegboot"}{...}
{vieweralsosee "xtpkpss" "help xtpkpss"}{...}
{viewerjumpto "Syntax" "xtpcointegwe##syntax"}{...}
{viewerjumpto "Description" "xtpcointegwe##description"}{...}
{viewerjumpto "Options" "xtpcointegwe##options"}{...}
{viewerjumpto "Stored results" "xtpcointegwe##stored"}{...}
{viewerjumpto "Examples" "xtpcointegwe##examples"}{...}
{viewerjumpto "References" "xtpcointegwe##references"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col:{bf:xtpcointegwe} {hline 2}}Panel cointegration test with structural breaks and common factors (Westerlund-Edgerton, 2008){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpcointegwe}
{depvar} {indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(string)}}deterministic specification; {bf:nobreak}, {bf:levelshift}, or {bf:regimeshift}; default is {bf:nobreak}{p_end}
{synopt:{opt lags(#)}}number of ADF augmentation lags; default = int(4*(T/100)^(2/9)){p_end}
{synopt:{opt band:width(#)}}bandwidth for Fejer kernel in LRV estimation; default = int(4*(T/100)^(2/9)){p_end}
{synopt:{opt trim(#)}}trimming fraction for break search; default is 0.10{p_end}
{synopt:{opt maxf:actors(#)}}maximum number of common factors via Bai-Ng IC; default is 5{p_end}
{synopt:{opt gr:aph}}display multi-panel line graph with estimated break dates{p_end}
{synoptline}

{pstd}
A balanced panel must be declared via {cmd:xtset} {it:panelvar} {it:timevar} before calling {cmd:xtpcointegwe}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpcointegwe} implements the panel cointegration test proposed by
Westerlund and Edgerton (2008, {it:Oxford Bulletin of Economics and Statistics}).
The test examines the null hypothesis of {bf:no cointegration} (i.e., all panel units
exhibit a spurious regression) against the alternative that at least some units
are cointegrated.

{pstd}
The procedure is based on estimating individual ADF regressions on the residuals of the
cointegrating regression, augmented with leads and lags of the first-differenced regressors
and break dummies where applicable. Cross-sectional dependence is accommodated through
a {bf:common factor} structure estimated via principal components; the number of factors
is selected by the Bai and Ng (2002) ICp1 information criterion.

{pstd}
Two standardized panel statistics are reported:

{p 8 12 2}{bf:PD-Tau} (t-ratio based): based on the sum of individual ADF t-statistics.{p_end}
{p 8 12 2}{bf:PD-Phi} (coefficient based): based on the sum of individual ADF rho-coefficients, scaled by the long-run-to-short-run variance ratio.{p_end}

{pstd}
Under the null, both statistics converge to standard normal. Rejection occurs in the
{bf:left tail}: large negative values indicate evidence of cointegration.


{marker options}{...}
{title:Options}

{phang}{opt model(string)} specifies the deterministic component:

{p 12 16 2}{bf:nobreak}: no structural break; the cointegrating regression contains an intercept and trend (Case 1).{p_end}
{p 12 16 2}{bf:levelshift}: a single level break at an endogenously estimated date (Case 2).{p_end}
{p 12 16 2}{bf:regimeshift}: shifts in both the level and the slope coefficient at an unknown date (Case 3).{p_end}

{phang}{opt lags(#)} sets the number of lags in the ADF regression for serial correlation.
Default is int(4*(T/100)^(2/9)), following the Andrews-Schwarz rule.

{phang}{opt bandwidth(#)} the bandwidth for the Fejer kernel used in the long-run
variance estimation. Default is int(4*(T/100)^(2/9)).

{phang}{opt trim(#)} the trimming fraction used when searching for structural breaks.
Breaks are restricted to lie in the interval [trim*T, (1-trim)*T]. Default is 0.10.

{phang}{opt maxfactors(#)} maximum number of common factors considered for the
Bai-Ng information criterion. Set to 0 to disable factor estimation. Default is 5.

{phang}{opt graph} displays a combined line graph showing each panel's dependent variable
over time with vertical dashed lines at estimated break dates. Only available when
{opt model()} is {bf:levelshift} or {bf:regimeshift}.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtpcointegwe} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(zt)}}PD-Tau test statistic{p_end}
{synopt:{cmd:r(za)}}PD-Phi test statistic{p_end}
{synopt:{cmd:r(pval_zt)}}p-value for PD-Tau (left-tail of N(0,1)){p_end}
{synopt:{cmd:r(pval_za)}}p-value for PD-Phi (left-tail of N(0,1)){p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(nfactors)}}number of common factors selected{p_end}
{synopt:{cmd:r(lags)}}number of ADF lags used{p_end}
{synopt:{cmd:r(bandwidth)}}bandwidth used{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(breaks)}}estimated break dates (N x 1 vector){p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(model)}}model label{p_end}
{synopt:{cmd:r(depvar)}}dependent variable name{p_end}
{synopt:{cmd:r(indepvars)}}independent variable name(s){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Setup: balanced panel with cointegrated y and x{p_end}
{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}No structural break model{p_end}
{phang2}{cmd:. xtpcointegwe y x, model(nobreak) maxfactors(3)}{p_end}

{pstd}Level shift model with graphical output{p_end}
{phang2}{cmd:. xtpcointegwe y x, model(levelshift) maxfactors(3) graph}{p_end}

{pstd}Regime shift with wider trimming and custom lags{p_end}
{phang2}{cmd:. xtpcointegwe y x, model(regimeshift) trim(0.15) lags(4) bandwidth(4)}{p_end}


{marker references}{...}
{title:References}

{phang}
Westerlund, J. and D.L. Edgerton. 2008.
A simple test for cointegration in dependent panels with structural breaks.
{it:Oxford Bulletin of Economics and Statistics} 70(5): 665-704.
{p_end}

{phang}
Bai, J. and S. Ng. 2002.
Determining the number of factors in approximate factor models.
{it:Econometrica} 70(1): 191-221.
{p_end}

{phang}
Gregory, A.W. and B.E. Hansen. 1996.
Residual-based tests for cointegration in models with regime shifts.
{it:Journal of Econometrics} 70(1): 99-126.
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
{helpb xtpcointegboot}, {helpb xtpkpss}
{p_end}
