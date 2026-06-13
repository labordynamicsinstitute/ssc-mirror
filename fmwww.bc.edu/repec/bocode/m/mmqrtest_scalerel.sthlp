{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest" "help mmqrtest"}{...}
{vieweralsosee "mmqrtest postestimation" "help mmqrtest_postestimation"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{viewerjumpto "Syntax" "mmqrtest_scalerel##syntax"}{...}
{viewerjumpto "Description" "mmqrtest_scalerel##description"}{...}
{viewerjumpto "Options" "mmqrtest_scalerel##options"}{...}
{viewerjumpto "Examples" "mmqrtest_scalerel##examples"}{...}
{viewerjumpto "Stored results" "mmqrtest_scalerel##results"}{...}
{title:Title}

{phang}
{bf:mmqrtest scalerel} {hline 2} Wald test of scale relevance,
H0: {it:gamma} = 0 (quantile-slope homogeneity)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mmqrtest} {cmd:scalerel} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {opt id(panelvar)} {opt q:uantile(numlist)} {opt gr:aph}
{opt name(string)} {opt noheader}]


{marker description}{...}
{title:Description}

{pstd}
In the linear MM-QR model the quantile coefficient of regressor {it:l} is
{it:beta_l(tau)} = {it:beta_l} + {it:q(tau) gamma_l} (Machado and Santos
Silva 2019, eq. 4).  Hence

{p 8 8 2}H0: {it:gamma} = 0
{space 3}<=>{space 3}
{it:beta(tau)} identical at every {it:tau},

{pstd}
i.e. the regressors do not move the scale of the conditional distribution
and quantile regression collapses to a pure location model.  This is the
one test for which the paper supplies complete asymptotic theory: the
joint distribution of the scale coefficients follows from Theorem 2, and
the authors themselves report such p-values in their applications (their
fn. 30).

{pstd}
{bf:Implementation.}  After {helpb mmqreg} the test is computed directly
from the {it:scale} equation of {cmd:e(b)}/{cmd:e(V)} via {helpb test},
inheriting whatever VCE was chosen at estimation (analytic, robust, or
cluster).  Standalone, or after a different estimator, {cmd:mmqrtest}
quietly refits {cmd:mmqreg, absorb(}{it:id}{cmd:) cluster(}{it:id}{cmd:)}
internally (this requires {cmd:mmqreg}, {cmd:hdfe} and {cmd:ftools}) and
restores your estimation results afterwards.

{pstd}
A per-coefficient table of the scale equation with significance stars is
printed alongside the joint Wald statistic.

{pstd}
{bf:Interpretation.}  Rejection means there is genuine distributional
heterogeneity: at least one regressor changes the spread (and through
{it:q(tau)} the whole quantile path), so MM-QR adds information that mean
regression cannot deliver.  Failure to reject says the quantile slopes are
statistically flat across {it:tau}.


{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)}, {opt quantile(numlist)} {hline 2} used only when an
internal refit is needed; see {helpb mmqrtest}.

{phang}
{opt graph} draws a coefficient plot of the scale equation
({it:gamma}-hat with 95% confidence intervals around a zero line).

{phang}
{opt name(string)} names the graph (default {cmd:mmqrt_scalerel}).

{phang}
{opt noheader} suppresses the title box.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75) cluster(idcode)}{p_end}
{phang2}{cmd:. mmqrtest scalerel, graph}{p_end}

{pstd}Standalone:{p_end}
{phang2}{cmd:. mmqrtest scalerel ln_wage tenure ttl_exp, id(idcode)}{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}joint Wald statistic (chi-squared or F){p_end}
{synopt:{cmd:r(df)}}degrees of freedom{p_end}
{synopt:{cmd:r(p)}}p-value{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(slab)}}statistic label, e.g. {cmd:chi2(2)}{p_end}
{synopt:{cmd:r(verdict)}}{cmd:REJECT} or {cmd:NOT REJECTED}{p_end}


{title:Author}

{pstd}
Merwan Roudane {hline 2}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{hline 2} {browse "https://github.com/merwanroudane"}
