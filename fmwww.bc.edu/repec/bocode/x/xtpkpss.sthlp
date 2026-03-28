{smcl}
{* *! version 2.0.0  26mar2026}{...}
{vieweralsosee "xtpcointegwe" "help xtpcointegwe"}{...}
{vieweralsosee "xtpcointegboot" "help xtpcointegboot"}{...}
{viewerjumpto "Syntax" "xtpkpss##syntax"}{...}
{viewerjumpto "Description" "xtpkpss##description"}{...}
{viewerjumpto "Options" "xtpkpss##options"}{...}
{viewerjumpto "Stored results" "xtpkpss##stored"}{...}
{viewerjumpto "Examples" "xtpkpss##examples"}{...}
{viewerjumpto "References" "xtpkpss##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:xtpkpss} {hline 2}}Panel KPSS stationarity test with structural breaks (Carrion-i-Silvestre et al., 2005){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtpkpss}
{varname}
{ifin}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mod:el(string)}}deterministic specification; {bf:constant}, {bf:trend}, {bf:constbreak}, or {bf:trendbreak}; default is {bf:constant}{p_end}
{synopt:{opt maxb:reaks(#)}}maximum number of structural breaks; default is 5{p_end}
{synopt:{opt ker:nel(string)}}kernel for LRV estimation; {bf:bartlett} or {bf:qs}; default is {bf:bartlett}{p_end}
{synopt:{opt band:width(#)}}bandwidth for kernel; default = int(4*(T/100)^(2/9)){p_end}
{synopt:{opt trim(#)}}trimming fraction for break search; default is 0.10{p_end}
{synopt:{opt gr:aph}}display individual KPSS bar chart and break date timeline{p_end}
{synoptline}

{pstd}
A balanced panel must be declared via {cmd:xtset} {it:panelvar} {it:timevar} before calling {cmd:xtpkpss}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpkpss} implements the panel stationarity test proposed by
Carrion-i-Silvestre, del Barrio-Castro, and López-Bazo (2005,
{it:Econometrics Journal}).
The test examines the null hypothesis of {bf:stationarity}
(possibly with structural breaks) against the alternative that at least some
panel units contain a unit root.

{pstd}
The test extends the univariate KPSS test of Kwiatkowski et al. (1992) to
panel data, building on the panel framework of Hadri (2000).
When structural breaks are allowed ({opt model(constbreak)} or
{opt model(trendbreak)}), the number and location of breaks are determined
endogenously for each panel unit using the sequential procedure of
Bai and Perron (1998), with the modified Bayesian information criterion
(LWZ) of Liu, Wu, and Zidek (1997) for selecting the optimal number of
breaks.

{pstd}
Two standardized panel statistics are reported:

{p 8 12 2}{bf:Z(hom)}: assumes {bf:homogeneous} long-run variance across panel units.{p_end}
{p 8 12 2}{bf:Z(het)}: allows for {bf:heterogeneous} long-run variances across units.{p_end}

{pstd}
Under the null, both statistics converge to standard normal.  Rejection
occurs in the {bf:right tail}: large positive values indicate evidence
against stationarity.


{marker options}{...}
{title:Options}

{phang}{opt model(string)} specifies the deterministic component:

{p 12 16 2}{bf:constant}: level stationarity (KPSS-mu).  Tests whether the series is stationary around a constant mean.{p_end}
{p 12 16 2}{bf:trend}: trend stationarity (KPSS-tau).  Tests whether the series is stationary around a linear trend.{p_end}
{p 12 16 2}{bf:constbreak}: level stationarity with endogenous level breaks.  Allows the intercept to shift at unknown dates.{p_end}
{p 12 16 2}{bf:trendbreak}: trend stationarity with level and slope breaks.  Allows both the intercept and the trend slope to shift.{p_end}

{phang}{opt maxbreaks(#)} the maximum number of structural breaks to consider when
{opt model()} is {bf:constbreak} or {bf:trendbreak}.
The sequential Bai-Perron procedure tests up to this many breaks; the LWZ
criterion selects the optimal number.  Default is 5.

{phang}{opt kernel(string)} specifies the kernel function used to estimate the
long-run variance:

{p 12 16 2}{bf:bartlett}: Bartlett (triangular) kernel.{p_end}
{p 12 16 2}{bf:qs}: Quadratic Spectral kernel.{p_end}

{phang}{opt bandwidth(#)} bandwidth for the kernel function.
Default is int(4*(T/100)^(2/9)), the Andrews-Schwarz rule.

{phang}{opt trim(#)} the trimming fraction used when searching for structural breaks.
Breaks are restricted to lie in [trim*T, (1-trim)*T].  Default is 0.10.

{phang}{opt graph} displays two graphs: (1) a bar chart of individual KPSS
statistics with a horizontal line at the panel mean, and (2) when breaks
are estimated, a timeline showing estimated break dates for each panel unit.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtpkpss} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(z_hom)}}homogeneous panel Z statistic{p_end}
{synopt:{cmd:r(z_het)}}heterogeneous panel Z statistic{p_end}
{synopt:{cmd:r(pval_hom)}}p-value for Z(hom) (right-tail of N(0,1)){p_end}
{synopt:{cmd:r(pval_het)}}p-value for Z(het) (right-tail of N(0,1)){p_end}
{synopt:{cmd:r(lm_hom)}}homogeneous LM statistic (before standardization){p_end}
{synopt:{cmd:r(lm_het)}}heterogeneous LM statistic (before standardization){p_end}
{synopt:{cmd:r(mu_bar)}}average correction mean{p_end}
{synopt:{cmd:r(var_bar)}}average correction variance{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(bandwidth)}}bandwidth used{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:r(kpss)}}individual KPSS statistics (N x 1){p_end}
{synopt:{cmd:r(lrvar)}}individual long-run variances (N x 1){p_end}
{synopt:{cmd:r(breaks)}}estimated break dates (maxbreaks x N){p_end}
{synopt:{cmd:r(nbreaks)}}number of breaks per unit (N x 1){p_end}

{p2col 5 25 29 2: Macros}{p_end}
{synopt:{cmd:r(model)}}model label{p_end}
{synopt:{cmd:r(kernel)}}kernel label{p_end}
{synopt:{cmd:r(depvar)}}variable name{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Setup: balanced panel{p_end}
{phang2}{cmd:. webuse pennxrate, clear}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Level stationarity test (no breaks){p_end}
{phang2}{cmd:. xtpkpss y, model(constant)}{p_end}

{pstd}Trend stationarity test{p_end}
{phang2}{cmd:. xtpkpss y, model(trend) kernel(qs) bandwidth(6)}{p_end}

{pstd}Level stationarity with structural breaks and graph{p_end}
{phang2}{cmd:. xtpkpss y, model(constbreak) maxbreaks(3) graph}{p_end}

{pstd}Trend stationarity with breaks, custom trimming{p_end}
{phang2}{cmd:. xtpkpss y, model(trendbreak) maxbreaks(5) trim(0.15)}{p_end}


{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J.L., T. del Barrio-Castro, and E. López-Bazo. 2005.
Breaking the panels: An application to the GDP per capita.
{it:Econometrics Journal} 8(2): 159-175.
{p_end}

{phang}
Hadri, K. 2000.
Testing for stationarity in heterogeneous panel data.
{it:Econometrics Journal} 3(2): 148-161.
{p_end}

{phang}
Kwiatkowski, D., P.C.B. Phillips, P. Schmidt, and Y. Shin. 1992.
Testing the null hypothesis of stationarity against the alternative
of a unit root.
{it:Journal of Econometrics} 54(1-3): 159-178.
{p_end}

{phang}
Bai, J. and P. Perron. 1998.
Estimating and testing linear models with multiple structural changes.
{it:Econometrica} 66(1): 47-78.
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
{helpb xtpcointegwe}, {helpb xtpcointegboot}
{p_end}
