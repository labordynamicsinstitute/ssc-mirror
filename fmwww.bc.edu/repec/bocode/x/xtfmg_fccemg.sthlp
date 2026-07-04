{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg" "help xtfmg"}{...}
{vieweralsosee "xtfmg fsurmg" "help xtfmg_fsurmg"}{...}
{vieweralsosee "xtfmg estimators" "help xtfmg_estimators"}{...}
{vieweralsosee "xtfmg all" "help xtfmg_all"}{...}
{vieweralsosee "xtfmg breaks" "help xtfmg_breaks"}{...}
{vieweralsosee "xtfmg map" "help xtfmg_map"}{...}
{viewerjumpto "Syntax" "xtfmg_fccemg##syntax"}{...}
{viewerjumpto "Description" "xtfmg_fccemg##description"}{...}
{viewerjumpto "Options" "xtfmg_fccemg##options"}{...}
{viewerjumpto "Remarks" "xtfmg_fccemg##remarks"}{...}
{viewerjumpto "Stored results" "xtfmg_fccemg##results"}{...}
{viewerjumpto "Examples" "xtfmg_fccemg##examples"}{...}
{viewerjumpto "References" "xtfmg_fccemg##references"}{...}

{title:Title}

{phang}
{bf:xtfmg fccemg} {hline 2} Fourier Common Correlated Effects Mean Group
(F-CCEMG) estimator


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg fccemg} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt k:freq(#)}}Fourier frequency k; default {cmd:kfreq(1)}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt het:eroplot}}forest plot of the unit-specific slopes{p_end}
{synopt :{opt f:ocus(varname)}}regressor shown in the heterogeneity plot;
default is the first independent variable{p_end}
{synopt :{opt four:ierplot}}plot the estimated unit-specific Fourier
components (the smooth breaks){p_end}
{synopt :{opt notab:le}}suppress the coefficient table{p_end}
{synopt :{opt sav:ing(filename)}}export the table in journal format
({cmd:.tex}, {cmd:.rtf}/{cmd:.doc}, {cmd:.csv} or {cmd:.txt}){p_end}
{synopt :{opt ti:tle(string)}}caption for the exported table{p_end}
{synopt :{opt rep:lace}}overwrite the export file if it exists{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb xtset}. An unbalanced panel is allowed;
periods missing for some units simply enter the cross-sectional averages
with fewer units.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfmg fccemg} estimates, for each unit i, the augmented regression

{p 8 8 2}
y_it = a_i + b_i' x_it + d_i' zbar_t + g_i sin(2 pi k t/T) + l_i cos(2 pi k t/T) + e_it,

{pstd}
where zbar_t = (ybar_t, xbar_t')' are the period-by-period cross-sectional
averages of the dependent variable and the regressors, and the sine and
cosine terms are a single-frequency Fourier basis with unit-specific
coefficients. The F-CCEMG estimate of the mean slope is the mean-group
average of the unit slope estimates, with the nonparametric Pesaran-Smith
(1995) variance

{p 8 8 2}
V = [N(N-1)]^-1 sum_i (b_i - b_MG)(b_i - b_MG)'.

{pstd}
The two augmentations act on orthogonal sources of variation: the
cross-sectional averages span and remove the common-factor component
(Pesaran 2006), while the unit-specific Fourier terms absorb idiosyncratic,
heterogeneously-timed structural breaks that the averages cannot reach
(Guliyev 2026). The estimator nests CCEMG (Fourier coefficients zero) and a
Fourier Mean Group regression (averages excluded) as special cases.

{pstd}
The reported {cmd:sin} and {cmd:cos} rows are the mean-group averages of the
unit-specific Fourier coefficients. Because breaks may differ in direction
across units, these averages can be insignificant even when the unit-level
Fourier terms matter; use {opt fourierplot} to inspect the unit paths.


{marker options}{...}
{title:Options}

{phang}
{opt kfreq(#)} sets the Fourier frequency k. The default, {cmd:kfreq(1)},
follows Becker, Enders and Lee (2006) and Enders and Lee (2012): a single
low frequency approximates one or two breaks of unknown timing and form
while adding only two regressors per unit. Higher frequencies can track more
elaborate break patterns but risk over-fitting the deterministic component,
a danger that is acute in small-T panels; a note is displayed for
{cmd:kfreq()} greater than 3.

{phang}
{opt level(#)} sets the confidence level for the reported intervals and for
the plot whiskers; see {helpb estimation options##level():[R] level}.

{phang}
{opt heteroplot} draws a forest plot of the unit-specific slope estimates on
the {opt focus()} variable, with unit-level confidence intervals and a
dashed line at the mean-group average. The graph is named
{cmd:xtfmg_hetero}.

{phang}
{opt focus(varname)} selects the regressor displayed by {opt heteroplot};
the default is the first independent variable.

{phang}
{opt fourierplot} plots each unit's estimated deterministic Fourier
component g_i sin(2 pi k t/T) + l_i cos(2 pi k t/T) against time, making the
heterogeneously-timed smooth breaks directly visible. The graph is named
{cmd:xtfmg_fourier}.

{phang}
{opt notable} suppresses the output table (useful in simulations); all
results remain available in {cmd:r()}.

{phang}
{opt saving(filename)} exports the coefficient table in publication format.
The format follows the file extension: {cmd:.tex} writes a LaTeX table with
booktabs rules (add \usepackage{c -(}booktabs{c )-} to the preamble) and
superscript significance stars; {cmd:.rtf} or {cmd:.doc} writes a Word table
in Times New Roman with journal-style horizontal rules; {cmd:.csv} and
{cmd:.txt} write delimited and aligned text. Coefficients carry stars,
standard errors appear in parentheses beneath, and notes report N, T, the
CD statistic and the star legend.

{phang}
{opt title(string)} sets the caption of the exported table; a sensible
default is used if omitted.

{phang}
{opt replace} permits {opt saving()} to overwrite an existing file.


{marker remarks}{...}
{title:Remarks}

{pstd}
{it:When to use F-CCEMG.} The Monte Carlo evidence in Guliyev (2026) places
F-CCEMG first on root mean squared error in almost every configuration and
near-nominal 95% coverage once N is not minimal (N >= 10). It is the
estimator of choice in the intermediate regime {hline 2} moderate
cross-sectional dependence combined with individual, heterogeneously-timed
breaks {hline 2} which is typical of small country groups such as the G7,
the BRICS and the N-11. Run {helpb xtfmg_map:xtfmg map} to locate your panel
on the regime map.

{pstd}
{it:Small N caveat.} The cross-sectional-average approximation underlying
all CCE-based estimators is asymptotic in N. With N below 10 the averages
are noisy proxies for the latent factors and the intervals are mildly
anti-conservative; report {helpb xtfmg_fsurmg:xtfmg fsurmg} alongside as the
small-N comparator, as in the G7 application of the paper.

{pstd}
{it:Consistency.} The limiting distribution of F-CCEMG is not formally
established; consistency is inherited heuristically from CCE (the Fourier
terms are bounded deterministic functions of time and do not disturb the
factor-spanning argument) and is supported by the Monte Carlo evidence.

{pstd}
{it:Units skipped.} Units whose time series is too short for the augmented
regression (T_i <= k_x + k_x + 1 + 2 + 2, with k_x regressors) or whose
augmented design is collinear are skipped and reported in the header.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtfmg fccemg} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of panel units{p_end}
{synopt:{cmd:r(N_used)}}units entering the mean-group average{p_end}
{synopt:{cmd:r(N_skip)}}units skipped{p_end}
{synopt:{cmd:r(Tbar)}}average time-series length{p_end}
{synopt:{cmd:r(n)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of regressors{p_end}
{synopt:{cmd:r(kfreq)}}Fourier frequency{p_end}
{synopt:{cmd:r(cd)}}Pesaran CD statistic (unit residuals){p_end}
{synopt:{cmd:r(cd_p)}}CD p-value{p_end}
{synopt:{cmd:r(alpha)}}Bailey-Kapetanios-Pesaran CSD exponent (simple
estimator, standardized residuals){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(estimator)}}{cmd:fccemg}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}independent variables{p_end}
{synopt:{cmd:r(ivar)}}panel variable{p_end}
{synopt:{cmd:r(tvar)}}time variable{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(b)}}1 x (k+2) mean-group estimates (slopes, sin, cos){p_end}
{synopt:{cmd:r(V)}}Pesaran-Smith variance matrix{p_end}
{synopt:{cmd:r(bunit)}}N x (k+2) unit-specific estimates{p_end}
{synopt:{cmd:r(seunit)}}N x (k+2) unit-specific standard errors{p_end}


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtfmg fccemg invest mvalue kstock}{p_end}
{phang2}{cmd:. xtfmg fccemg invest mvalue kstock, heteroplot focus(mvalue) fourierplot}{p_end}
{phang2}{cmd:. matrix list r(bunit)}{p_end}


{marker references}{...}
{title:References}

{phang}Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the
presence of an unknown number of smooth breaks.
{it:Journal of Time Series Analysis} 27: 381-409.{p_end}
{phang}Enders, W., and J. Lee. 2012. A unit root test using a Fourier series
to approximate smooth breaks.
{it:Oxford Bulletin of Economics and Statistics} 74: 574-599.{p_end}
{phang}Guliyev, H. 2026. Second-generation heterogeneous panel data model
with individual and common shocks. arXiv:2606.29063.{p_end}
{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous
panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.{p_end}
{phang}Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships
from dynamic heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
