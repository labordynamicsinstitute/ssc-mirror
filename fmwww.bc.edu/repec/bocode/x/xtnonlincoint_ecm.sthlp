{smcl}
{* *! version 1.0.0  21jun2026}{...}
{vieweralsosee "xtnonlincoint" "help xtnonlincoint"}{...}
{vieweralsosee "xtnonlincoint fffff" "help xtnonlincoint_fffff"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtnonlincoint_ecm##syntax"}{...}
{viewerjumpto "Description" "xtnonlincoint_ecm##description"}{...}
{viewerjumpto "Options" "xtnonlincoint_ecm##options"}{...}
{viewerjumpto "Method" "xtnonlincoint_ecm##method"}{...}
{viewerjumpto "Examples" "xtnonlincoint_ecm##examples"}{...}
{viewerjumpto "Stored results" "xtnonlincoint_ecm##results"}{...}
{viewerjumpto "References" "xtnonlincoint_ecm##references"}{...}
{viewerjumpto "Author" "xtnonlincoint_ecm##author"}{...}
{title:Title}

{phang}
{bf:xtnonlincoint ecm} {hline 2} Nonlinear error-correction based panel
cointegration test (Omay, Emirmahmutoglu & Denaux 2017)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtnonlincoint ecm} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt l:ags(#)}}lags of {it:differenced} variables in the ECM auxiliary
regression; default {cmd:lags(1)}{p_end}
{synopt:{opt var:lags(#)}}order of the panel VAR in differences used by the
sieve bootstrap; default {cmd:varlags(1)}{p_end}
{synopt:{opt tr:end}}detrend (constant + linear trend) the cointegrating
regression; default is demeaned (constant only){p_end}

{syntab:Bootstrap}
{synopt:{opt b:reps(#)}}sieve-bootstrap replications; default {cmd:breps(299)}{p_end}
{synopt:{opt s:eed(#)}}random-number seed; default {cmd:seed(12345)}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level for reporting; default {cmd:level(95)}{p_end}
{synopt:{opt gr:aph}}draw the individual-statistics bar chart and the bootstrap
null-distribution histogram{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}

{pstd}The panel must be {helpb xtset} and balanced.

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtnonlincoint ecm} implements the first nonlinear error-correction based
panel cointegration test. For each cross-section {it:i} it estimates a
conditional panel logistic smooth-transition ECM (PLSTR-ECM). Because the
transition speed is not identified under the null, the logistic transition is
replaced by its first-order Taylor expansion, giving the auxiliary regression

{p 8 8 2}
D.y(it) = rho1*u(i,t-1) + rho2*u(i,t-1)^2
+ sum_j d(ij)*D.z(i,t-j) + w(i)*D.x(it) + e(it),

{pstd}
where u(i,t-1) is the lagged cointegrating residual and z = (y, x). The null of
{it:no error correction} (hence no cointegration) is H0: rho1 = rho2 = 0; the
alternative is mixed (rho1 two-sided, rho2 one-sided), so the Abadir-Distaso
modified Wald (MWALD) statistic tau(c) is used and averaged into a group-mean
statistic. Cross-section dependence is handled by a sieve bootstrap on a panel
VAR fitted to the first differences.

{marker options}{...}
{title:Options}

{phang}
{opt lags(#)} sets the number of lagged differences D.z(i,t-j) entering the
auxiliary ECM regression. Larger values absorb more residual serial correlation
at the cost of degrees of freedom.

{phang}
{opt varlags(#)} sets the order of the panel VAR in differences whose
(whitened) residuals are resampled by the sieve bootstrap. The serial
dependence removed at this stage is re-injected through the VAR recursion when
the pseudo-data are built.

{phang}
{opt trend} adds a linear trend to the first-stage cointegrating regression
(detrended case). The default demeans only.

{phang}
{opt breps(#)} sets the number of bootstrap replications used for the
critical values and {it:p}-values. The published study uses warp-speed
bootstrap; 299-999 replications are typical.

{phang}
{opt seed(#)} fixes the seed so results are reproducible.

{phang}
{opt graph} produces a two-panel figure: a bar chart of the individual tau(c)
statistics with the 5% bootstrap critical value, and a histogram of the
bootstrap null distribution of the group statistic with the observed value
marked.

{marker method}{...}
{title:Method}

{pstd}
The MWALD statistic for panel {it:i} is

{p 8 8 2}
tau(c)_i = (rho1 - rho2*v21/v22)^2 / (v11 - v21^2/v22)
+ 1{rho2<0} * rho2^2 / v22,

{pstd}
where v11, v22 and v21 are elements of the 2x2 covariance matrix of
(rho1, rho2). The group statistic is the cross-sectional average. The bootstrap
imposes the unit-root null by cumulating VAR-generated pseudo-innovations into
I(1) pseudo-data, recomputing tau(c) on each draw; the {it:p}-value is the share
of bootstrap group statistics at least as large as the observed one.

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtnonlincoint ecm invest mvalue kstock}{p_end}
{phang2}{cmd:. xtnonlincoint ecm invest mvalue kstock, lags(2) varlags(2) trend graph}{p_end}
{phang2}{cmd:. matrix list r(indstat)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtnonlincoint ecm} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}group-mean MWALD statistic tau(c){p_end}
{synopt:{cmd:r(p)}}bootstrap {it:p}-value{p_end}
{synopt:{cmd:r(cv10)}, {cmd:r(cv5)}, {cmd:r(cv1)}}group critical values{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}number of periods{p_end}
{synopt:{cmd:r(lags)}, {cmd:r(varlags)}, {cmd:r(breps)}}option echoes{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}long-run regressors{p_end}
{synopt:{cmd:r(test)}}test label{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(indstat)}}per-panel: id, tau(c), {it:p}-value, cv10, cv5, cv1{p_end}
{synopt:{cmd:r(bootdist)}}bootstrap null distribution of the group statistic{p_end}

{marker references}{...}
{title:References}

{phang}
Abadir, K. M., and W. Distaso. 2007. Testing joint hypotheses when one of the
alternatives is one-sided. {it:Journal of Econometrics} 140: 695-718.

{phang}
Omay, T., F. Emirmahmutoglu, and Z. S. Denaux. 2017. Nonlinear error correction
based cointegration test in panel data. {it:Economics Letters} 157: 1-4.
{browse "https://doi.org/10.1016/j.econlet.2017.05.017":doi:10.1016/j.econlet.2017.05.017}.

{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
