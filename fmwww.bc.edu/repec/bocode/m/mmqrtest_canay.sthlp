{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqrtest distfe" "help mmqrtest_distfe"}{...}
{vieweralsosee "mmqrtest postestimation" "help mmqrtest_postestimation"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{viewerjumpto "Syntax" "mmqrtest_canay##syntax"}{...}
{viewerjumpto "Description" "mmqrtest_canay##description"}{...}
{viewerjumpto "Methods" "mmqrtest_canay##methods"}{...}
{viewerjumpto "Options" "mmqrtest_canay##options"}{...}
{viewerjumpto "Examples" "mmqrtest_canay##examples"}{...}
{viewerjumpto "Stored results" "mmqrtest_canay##results"}{...}
{title:Title}

{phang}
{bf:mmqrtest canay} {hline 2} Validity test of Canay's (2011)
location-shift assumption (MM-QR vs Canay contrast)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mmqrtest} {cmd:canay} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {opt id(panelvar)} {opt q:uantile(numlist)} {opt r:eps(#)}
{opt seed(#)} {opt pvar(varname)} {opt gr:aph} {opt name(string)}
{opt nodots} {opt noheader}]


{marker description}{...}
{title:Description}

{pstd}
Canay (2011) builds a simple two-step panel quantile estimator on the
assumption that the fixed effects {it:alpha_i} are {bf:pure location shift}
variables {hline 2} they move every conditional quantile by the same
amount.  The assumption is maintained, not tested, in his paper.  Machado
and Santos Silva (2019, fn. 17) document what happens when it fails: with
scale-relevant fixed effects, Canay's estimator deteriorates sharply while
MM-QR remains consistent.

{pstd}
{cmd:mmqrtest canay} turns that comparison into a formal Hausman-type
test.  Under H0 (location shift only) the Canay two-step slopes
{it:theta_C(tau)} and the MM-QR slopes {it:beta(tau)} estimate the same
object; under the alternative they diverge.  The contrast
{it:Delta(tau)} = {it:theta_C(tau)} - {it:beta(tau)} is evaluated with a
covariance matrix obtained from a pairs cluster bootstrap that resamples
whole units (neither paper provides the joint limiting distribution of the
two estimators, so the bootstrap is the appropriate route).

{pstd}
Because the structural reason for failure of H0 is heterogeneity of the
scale fixed effects, {helpb mmqrtest_distfe:mmqrtest distfe} is the natural
companion: run both, and read rejection in either as evidence against
location-shift estimators for your data.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Canay two-step} (Canay 2011, sec. 4): (1) within (fixed-effects) OLS
of {it:Y} on {it:X} gives {it:theta}-hat; {it:alpha_i}-hat is the unit mean
of {it:Y} - {it:X'theta}-hat; (2) standard quantile regression of
{it:Y} - {it:alpha_i}-hat on {it:X} at each {it:tau}.

{pstd}
{bf:MM-QR}: the sequential algorithm of Machado and Santos Silva (2019,
sec. 3.1), giving {it:beta(tau)} = {it:beta}-hat + {it:q(tau)}-hat
{it:gamma}-hat.

{pstd}
{bf:Bootstrap}: units are resampled with replacement ({helpb bsample},
{cmd:cluster() idcluster()}); both estimators are recomputed in every
replication; V[{it:Delta(tau)}] is the bootstrap covariance.  The per-
{it:tau} statistic {it:Delta'V^(-1)Delta} is chi-squared with rank(V)
degrees of freedom under H0; the overall p-value is Bonferroni across
{it:tau}.  Slopes only are compared (intercepts are not separately
identified under the two normalizations).


{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)}, {opt quantile(numlist)} {hline 2} see {helpb mmqrtest}.

{phang}
{opt reps(#)} sets bootstrap replications; default 200, minimum 50.  Use
500+ for publication results.

{phang}
{opt seed(#)} sets the random-number seed for reproducibility.

{phang}
{opt pvar(varname)} chooses the regressor displayed in the comparison
graph (default: the first regressor).

{phang}
{opt graph} draws the MM-QR and Canay coefficient paths across {it:tau}
with bootstrap 95% confidence intervals.

{phang}
{opt name(string)} names the graph (default {cmd:mmqrt_canay}).

{phang}
{opt nodots} suppresses the bootstrap progress dots;
{opt noheader} suppresses the title box.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75)}{p_end}
{phang2}{cmd:. mmqrtest canay, reps(500) seed(12345) pvar(tenure) graph}{p_end}

{pstd}Standalone:{p_end}
{phang2}{cmd:. mmqrtest canay ln_wage tenure ttl_exp, id(idcode) quantile(10 50 90)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(p)}}overall p-value (Bonferroni across tau){p_end}
{synopt:{cmd:r(reps)}}successful bootstrap replications{p_end}
{synopt:{cmd:r(G)}}number of units{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(htests)}}per-{it:tau} results (tau, chi2, df, p){p_end}
{synopt:{cmd:r(b_mmqr)}}MM-QR slope path, rows = quantiles{p_end}
{synopt:{cmd:r(b_canay)}}Canay slope path, rows = quantiles{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:REJECT} or {cmd:NOT REJECTED}{p_end}


{title:References}

{phang}
Canay, I. A. 2011.  A simple approach to quantile regression for panel
data.  {it:The Econometrics Journal} 14: 368-386.
{browse "https://doi.org/10.1111/j.1368-423X.2011.00349.x"}

{phang}
Machado, J. A. F., and J. M. C. Santos Silva. 2019.  Quantiles via moments.
{it:Journal of Econometrics} 213: 145-173.
{browse "https://doi.org/10.1016/j.jeconom.2019.04.009"}


{title:Author}

{pstd}
Merwan Roudane {hline 2}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{hline 2} {browse "https://github.com/merwanroudane"}
