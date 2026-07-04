{smcl}
{* *! version 1.0.0  03jul2026}{...}
{vieweralsosee "xtfmg" "help xtfmg"}{...}
{vieweralsosee "xtfmg fccemg" "help xtfmg_fccemg"}{...}
{vieweralsosee "xtfmg estimators" "help xtfmg_estimators"}{...}
{vieweralsosee "xtfmg all" "help xtfmg_all"}{...}
{vieweralsosee "xtfmg map" "help xtfmg_map"}{...}
{viewerjumpto "Syntax" "xtfmg_fsurmg##syntax"}{...}
{viewerjumpto "Description" "xtfmg_fsurmg##description"}{...}
{viewerjumpto "Options" "xtfmg_fsurmg##options"}{...}
{viewerjumpto "Remarks" "xtfmg_fsurmg##remarks"}{...}
{viewerjumpto "Stored results" "xtfmg_fsurmg##results"}{...}
{viewerjumpto "Examples" "xtfmg_fsurmg##examples"}{...}

{title:Title}

{phang}
{bf:xtfmg fsurmg} {hline 2} Fourier Seemingly Unrelated Regressions Mean
Group (F-SURMG) estimator


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtfmg fsurmg} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt k:freq(#)}}Fourier frequency k; default {cmd:kfreq(1)}{p_end}
{synopt :{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt het:eroplot}}forest plot of the unit-specific slopes{p_end}
{synopt :{opt f:ocus(varname)}}regressor shown in the heterogeneity plot{p_end}
{synopt :{opt four:ierplot}}plot the estimated unit-specific Fourier components{p_end}
{synopt :{opt notab:le}}suppress the coefficient table{p_end}
{synopt :{opt sav:ing(filename)}}export the table in journal format
({cmd:.tex}, {cmd:.rtf}/{cmd:.doc}, {cmd:.csv} or {cmd:.txt}); see
{helpb xtfmg_fccemg:xtfmg fccemg}{p_end}
{synopt :{opt ti:tle(string)}}caption for the exported table{p_end}
{synopt :{opt rep:lace}}overwrite the export file if it exists{p_end}
{synoptline}
{p 4 6 2}Requires a {bf:balanced} panel with {bf:T > N} on the estimation
sample, so the N x N contemporaneous error covariance can be estimated.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfmg fsurmg} estimates the system of unit equations

{p 8 8 2}
y_it = a_i + b_i' x_it + g_i sin(2 pi k t/T) + l_i cos(2 pi k t/T) + e_it,
{space 4}i = 1, ..., N,

{pstd}
jointly as a seemingly unrelated regression: an initial equation-by-equation
OLS provides residuals from which the N x N contemporaneous error covariance
is estimated, and the system is then re-estimated by feasible generalized
least squares. The F-SURMG estimate is the mean-group average of the FGLS
unit slopes, with the nonparametric Pesaran-Smith (1995) variance. The
efficiency gain comes entirely from the off-diagonal elements of the error
covariance {hline 2} the manifestation of the common factors {hline 2} and
is realisable only when T is large relative to N.

{pstd}
The unit-specific Fourier pair approximates structural breaks of unknown
number, timing and form occurring at different dates in different units
(Becker, Enders and Lee 2006; Enders and Lee 2012), while consuming only two
degrees of freedom per unit, unlike dummy-variable schemes.

{pstd}
F-SURMG does not include cross-sectional averages and so does not filter the
common factor directly; it is designed for the {bf:small-N, weak-dependence}
corner of the regime map, where the Monte Carlo evidence in Guliyev (2026)
shows it delivers the best-calibrated inference (N around 5). As the
dependence strengthens, the uncorrected factor bias becomes decisive and
{helpb xtfmg_fccemg:xtfmg fccemg} should be used instead.


{marker options}{...}
{title:Options}

{phang}
{opt kfreq(#)} sets the Fourier frequency; default 1. See
{helpb xtfmg_fccemg:xtfmg fccemg}.

{phang}
{opt level(#)}, {opt heteroplot}, {opt focus(varname)}, {opt fourierplot},
{opt notable}: as in {helpb xtfmg_fccemg:xtfmg fccemg}.


{marker remarks}{...}
{title:Remarks}

{pstd}
If the estimation sample is unbalanced, or T <= N, or any unit equation is
collinear, the command exits with an informative error (r(459)): the SUR
covariance cannot be estimated reliably in those cases. Use
{helpb xtfmg_fccemg:xtfmg fccemg} or {helpb xtfmg_estimators:xtfmg mg} for
unbalanced panels.

{pstd}
The smooth Fourier approximation represents a sharp, instantaneous break
only imperfectly; it captures the low-frequency content of the shift, which
is adequate for estimating the mean slope but should be borne in mind when
the breaks are genuinely abrupt.


{marker results}{...}
{title:Stored results}

{pstd}
Identical to {helpb xtfmg_fccemg:xtfmg fccemg} with
{cmd:r(estimator)} = {cmd:fsurmg}: scalars {cmd:r(N)}, {cmd:r(N_used)},
{cmd:r(N_skip)}, {cmd:r(Tbar)}, {cmd:r(n)}, {cmd:r(k)}, {cmd:r(kfreq)},
{cmd:r(cd)}, {cmd:r(cd_p)}, {cmd:r(alpha)}; matrices {cmd:r(b)},
{cmd:r(V)}, {cmd:r(bunit)}, {cmd:r(seunit)} (each with {cmd:sin} and
{cmd:cos} columns).


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}
{phang2}{cmd:. xtfmg fsurmg invest mvalue kstock}{p_end}
{phang2}{cmd:. xtfmg fsurmg invest mvalue kstock, fourierplot kfreq(2)}{p_end}


{title:References}

{phang}Becker, R., W. Enders, and J. Lee. 2006. A stationarity test in the
presence of an unknown number of smooth breaks.
{it:Journal of Time Series Analysis} 27: 381-409.{p_end}
{phang}Enders, W., and J. Lee. 2012. A unit root test using a Fourier series
to approximate smooth breaks.
{it:Oxford Bulletin of Economics and Statistics} 74: 574-599.{p_end}
{phang}Guliyev, H. 2025. Heterogeneous panel data model with sharp and smooth
changes: Testing the green growth hypothesis in G7 countries.
{it:Innovation and Green Development} 4(3): 100245.{p_end}
{phang}Guliyev, H. 2026. Second-generation heterogeneous panel data model
with individual and common shocks. arXiv:2606.29063.{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}
{p_end}
