{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg" "help xtfmg"}{...}
{vieweralsosee "xtfmg fccemg" "help xtfmg_fccemg"}{...}
{vieweralsosee "xtfmg fsurmg" "help xtfmg_fsurmg"}{...}
{vieweralsosee "xtfmg all" "help xtfmg_all"}{...}
{viewerjumpto "Syntax" "xtfmg_estimators##syntax"}{...}
{viewerjumpto "Description" "xtfmg_estimators##description"}{...}
{viewerjumpto "Stored results" "xtfmg_estimators##results"}{...}
{viewerjumpto "Examples" "xtfmg_estimators##examples"}{...}

{title:Title}

{phang}
{bf:xtfmg fe / mg / ccemg / surmg} {hline 2} benchmark estimators of the
heterogeneous panel model


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg} {c -(}{cmd:fe}{c |}{cmd:mg}{c |}{cmd:ccemg}{c |}{cmd:surmg}{c )-}
{depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt het:eroplot}}forest plot of unit-specific slopes (not {cmd:fe}){p_end}
{synopt :{opt f:ocus(varname)}}regressor shown in the heterogeneity plot{p_end}
{synopt :{opt notab:le}}suppress the coefficient table{p_end}
{synopt :{opt sav:ing(filename)}}export the table in journal format
({cmd:.tex}, {cmd:.rtf}/{cmd:.doc}, {cmd:.csv} or {cmd:.txt}); see
{helpb xtfmg_fccemg:xtfmg fccemg}{p_end}
{synopt :{opt ti:tle(string)}}caption for the exported table{p_end}
{synopt :{opt rep:lace}}overwrite the export file if it exists{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
These are the comparison estimators of the framework in Guliyev (2026);
each answers a different combination of the two problems {hline 2} slope
heterogeneity and cross-sectional dependence (CSD):

{phang}
{cmd:xtfmg fe} is the pooled within (fixed-effects) estimator with a common
slope. When the slopes genuinely differ across units it is inconsistent for
the mean slope: it converges to a weighted combination of the unit slopes in
which units with more variable regressors are over-represented (Pesaran and
Smith 1995). Reported as a cautionary benchmark.

{phang}
{cmd:xtfmg mg} is the Mean Group estimator: a separate OLS time-series
regression for each unit, averaged across units, with the nonparametric
Pesaran-Smith variance. Consistent under slope heterogeneity but biased when
a common factor drives both the regressors and the errors, because every
unit estimate is then biased in the same direction and the bias does not
average away.

{phang}
{cmd:xtfmg ccemg} is the Common Correlated Effects Mean Group estimator of
Pesaran (2006): each unit regression is augmented with the period-by-period
cross-sectional averages of (y, x), which asymptotically span the space of
the unobserved common factors, so the differential factor effect is filtered
out without estimating the factors. Idiosyncratic, heterogeneously-timed
breaks remain in the unit error; see {helpb xtfmg_fccemg:xtfmg fccemg}.

{phang}
{cmd:xtfmg surmg} estimates the N unit equations jointly by feasible-GLS
seemingly unrelated regression, exploiting the contemporaneous cross-equation
error correlation for efficiency when N is small relative to T, then averages
the FGLS unit slopes. Requires a balanced panel with T > N. It does not
filter the factor; see {helpb xtfmg_fsurmg:xtfmg fsurmg} for the
Fourier-augmented version.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mg}, {cmd:ccemg} and {cmd:surmg} store the same {cmd:r()} results as
{helpb xtfmg_fccemg:xtfmg fccemg}, without the {cmd:sin}/{cmd:cos} columns
and without {cmd:r(kfreq)}. {cmd:fe} stores {cmd:r(b)}, {cmd:r(V)},
{cmd:r(N)}, {cmd:r(Tbar)}, {cmd:r(n)}, {cmd:r(k)} and the macros
{cmd:r(estimator)}, {cmd:r(depvar)}, {cmd:r(indepvars)}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtfmg mg invest mvalue kstock}{p_end}
{phang2}{cmd:. xtfmg ccemg invest mvalue kstock, heteroplot}{p_end}
{phang2}{cmd:. xtfmg surmg invest mvalue kstock}{p_end}
{phang2}{cmd:. xtfmg fe invest mvalue kstock}{p_end}


{title:References}

{phang}Pesaran, M. H. 2006. Estimation and inference in large heterogeneous
panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.{p_end}
{phang}Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships
from dynamic heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.{p_end}
{phang}Guliyev, H. 2026. Second-generation heterogeneous panel data model
with individual and common shocks. arXiv:2606.29063.{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
