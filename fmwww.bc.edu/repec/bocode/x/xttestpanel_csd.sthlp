{smcl}
{* *! version 1.0.0 09jun2026}{...}
{vieweralsosee "xttestpanel" "help xttestpanel"}{...}
{vieweralsosee "xttestpanel het" "help xttestpanel_het"}{...}
{vieweralsosee "xttestpanel serial" "help xttestpanel_serial"}{...}
{vieweralsosee "xttestpanel func" "help xttestpanel_func"}{...}
{vieweralsosee "xttestpanel hausman" "help xttestpanel_hausman"}{...}
{vieweralsosee "xttestpanel vif" "help xttestpanel_vif"}{...}
{title:Title}

{phang}
{bf:xttestpanel csd} {hline 2} Cross-sectional dependence tests for panel-data models

{title:Syntax}

{p 8 17 2}
{cmd:xttestpanel csd} [{depvar} {indepvars}] {ifin}
[{cmd:,} {opt model(fe|re|pool)} {opt graph}]

{pstd}
Postestimation form (no varlist) reuses the last {helpb xtreg}; see
{helpb xttestpanel:the overview}.

{title:Description}

{pstd}
{cmd:xttestpanel csd} tests the null of {bf:cross-sectional independence} (errors
uncorrelated across panel units). It computes the pairwise residual correlations and
reports:

{p 8 8 2}o {bf:Pesaran (2004) CD} {hline 1} the standard CD test based on the average
pairwise correlation; ~ N(0,1).{p_end}
{p 8 8 2}o {bf:Baltagi-Kao-Peng (2016) bias-corrected CD} {hline 1} a
serial-correlation-robust rescaling of CD, which corrects the size distortion that
serial correlation in the errors induces in the ordinary CD test.{p_end}
{p 8 8 2}o {bf:Breusch-Pagan (1980) LM} {hline 1} the sum of squared pairwise
correlations; ~ chi2({it:N(N-1)/2}); appropriate when {it:T} is large relative to {it:N}.{p_end}
{p 8 8 2}o {bf:Pesaran scaled LM} {hline 1} the standardized LM for large panels; ~ N(0,1).{p_end}

{pstd}
The mean absolute and mean signed pairwise correlations are also reported.

{pstd}
{it:Note:} the BKP statistic is implemented as a serial-correlation-robust correction
to CD using the panel's lag-1 residual autocorrelation; the exact finite-sample
constants of Baltagi, Kao & Peng (2016) may differ.

{title:Options}

{phang}{opt model(fe|re|pool)} working model; default {cmd:fe}.{p_end}
{phang}{opt graph} heatmap of the residual cross-unit correlation matrix (uses
{helpb heatplot} if installed; otherwise the matrix is listed).{p_end}

{title:Stored results}

{synoptset 16 tabbed}{...}
{synopt:{cmd:r(cd)}}Pesaran CD statistic{p_end}
{synopt:{cmd:r(p_cd)}}its p-value{p_end}
{synopt:{cmd:r(bkp)}}bias-corrected CD statistic{p_end}
{synopt:{cmd:r(p_bkp)}}its p-value{p_end}
{synopt:{cmd:r(bplm)}}Breusch-Pagan LM statistic{p_end}
{synopt:{cmd:r(p_bplm)}}its p-value{p_end}
{synopt:{cmd:r(abs_rho)}}mean absolute pairwise correlation{p_end}

{title:Examples}

{phang2}{cmd:. xttestpanel csd ln_wage age tenure hours, graph}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xttestpanel csd}{p_end}

{title:References}

{phang}Pesaran, M.H. 2004/2015. {it:Econometric Reviews} 34: 1089-1117.{p_end}
{phang}Baltagi, B.H., C. Kao, and B. Peng. 2016. {it:Econometrics} 4: 44.{p_end}
{phang}Breusch, T.S., and A.R. Pagan. 1980. {it:Review of Economic Studies} 47: 239-253.{p_end}

{title:Author}
{pstd}Merwan Roudane {hline 1} merwanroudane920@gmail.com {hline 1}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
