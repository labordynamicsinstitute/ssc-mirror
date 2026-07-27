{smcl}
{* *! version 2.1.0  15jul2026}{...}
{viewerjumpto "Syntax" "pathintdid##syntax"}{...}
{viewerjumpto "Description" "pathintdid##description"}{...}
{viewerjumpto "Options" "pathintdid##options"}{...}
{viewerjumpto "Stored results" "pathintdid##results"}{...}
{viewerjumpto "Examples" "pathintdid##examples"}{...}
{viewerjumpto "References" "pathintdid##references"}{...}
{title:Title}

{phang}
{bf:pathintdid} {hline 2} Path-Integrated Difference-in-Differences (PI-DiD) estimator, with inference

{pstd}
(Formerly distributed as {bf:pidid}, renamed at the request of the Stata
Journal editors so that the command name would remain distinctive from a
possible future official StataCorp command.)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pathintdid} {it:depvar} {ifin} {cmd:,}
{cmd:panelvar(}{it:varname}{cmd:)}
{cmd:timevar(}{it:varname}{cmd:)}
{cmd:treatvar(}{it:varname}{cmd:)}
{cmd:t0(}{it:#}{cmd:)}
[{cmd:t1(}{it:#}{cmd:)} {cmd:level(}{it:#}{cmd:)} {cmd:graph} {cmd:notable} {cmd:nose}
{cmd:xtitle(}{it:string}{cmd:)} {cmd:ytitle(}{it:string}{cmd:)}
{cmd:title(}{it:string}{cmd:)} {cmd:name(}{it:string}{cmd:)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt panelvar(varname)}}unit (id) identifier{p_end}
{synopt:{opt timevar(varname)}}calendar/period variable{p_end}
{synopt:{opt treatvar(varname)}}time-invariant 0/1 treatment-group indicator{p_end}
{synopt:{opt t0(#)}}baseline period (start of the post-treatment window){p_end}

{syntab:Optional}
{synopt:{opt t1(#)}}evaluation horizon (endline); default is the maximum
observed value of {it:timevar}{p_end}
{synopt:{opt level(#)}}confidence level for the reported interval; default
is {cmd:level(95)}{p_end}
{synopt:{opt graph}}draw the treated vs. counterfactual paths with the
cumulative-effect area shaded{p_end}
{synopt:{opt notable}}suppress the printed period-by-period c0(t)/c1(t)/tau(t) table{p_end}
{synopt:{opt nose}}skip the standard-error/t-statistic/confidence-interval
calculation and report point estimates only (faster; also useful if the
panel is too small or too unbalanced for inference){p_end}
{synopt:{opt xtitle}{cmd:(}{it:string}{cmd:)}}graph x-axis title{p_end}
{synopt:{opt ytitle}{cmd:(}{it:string}{cmd:)}}graph y-axis title{p_end}
{synopt:{opt title}{cmd:(}{it:string}{cmd:)}}graph title{p_end}
{synopt:{opt name}{cmd:(}{it:string}{cmd:)}}graph name, passed to {cmd:name()}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:pathintdid} implements the Path-Integrated Difference-in-Differences
framework: instead of comparing treated and control outcomes at a single
endline date, it treats the treatment effect as a trajectory

{center:tau(t) = c1(t) - c0(t)}

{pstd}
where c1(t) and c0(t) are the (group-mean) treated and control outcome
paths over time, and integrates the baseline-differenced gap

{center:tauhat(t) = tau(t) - tau(t0)}

{pstd}
over the post-treatment window [t0, t1] using the trapezoidal rule to
obtain the cumulative causal effect

{center:sigma = INTEGRAL_t0^t1 tauhat(t) dt}

{pstd}
and the path-integrated Average Treatment Effect on the Treated,
tau-bar = sigma / (t1 - t0). For comparison, {cmd:pathintdid} also reports
the conventional static two-period DiD estimate, tauhat(t1), which uses
only the two boundary dates and can be zero (or misleadingly small)
whenever a transitory intervention's effect has fully decayed by t1, even
though sigma remains strictly positive.

{pstd}
Unless {opt nose} is specified, {cmd:pathintdid} also computes a standard
error, t-statistic, p-value, and confidence interval for sigma, tau-bar,
and the static estimate, following the estimation theory of the companion
paper (Salavi 2026): the standard error is built from the individual-level,
baseline-differenced trajectories Delta Y_i,k = Y_i,tk - Y_i,t0 of every
unit i observed at every date on the integration grid, using a
group-specific (treated/control) sample covariance matrix combined
according to

{center:Omega-hat = Sigma1-hat/pi-hat + Sigma0-hat/(1-pi-hat)}

{pstd}
and the trapezoidal-rule weights w implied by the integration grid, giving
Var(sigma-hat) = w'Omega-hat w / N. This requires at least two treated and
two control units with a complete record at every grid date within
[t0,t1]; a dataset with only one unit per group (e.g., two pre-aggregated
cohort means) cannot support inference, and {cmd:pathintdid} will report
point estimates only, with a note explaining why. See Salavi (2026) for
the full identification assumptions (SUTVA, random sampling, path-level
parallel trends, no anticipation, path smoothness, moment conditions)
under which this standard error is consistent.

{pstd}
{cmd:pathintdid} works with panel or repeated cross-section data for the
point estimates (c0(t), c1(t), sigma, tau-bar are computed from group-time
means via {cmd:collapse}, so {it:panelvar} does not need to be balanced
across periods for those). Standard errors, however, require individual-
level data and are computed only from units with a complete trajectory
across the requested integration grid.

{pstd}
The companion command {help pathintdidrobust} implements the robustness
checks and specification tests of section 5 of the companion paper: a
dynamic placebo test for pre-treatment parallel trends, a sensitivity
check of sigma-hat to grid density and to the quadrature rule
(trapezoidal vs. Simpson's 1/3 rule), and an anticipation-robust bounding
estimator with its sensitivity curve. Run it alongside {cmd:pathintdid}
whenever the identifying assumptions (parallel trends, no anticipation,
path smoothness) deserve a formal check rather than a visual one.


{marker options}{...}
{title:Options}

{phang}
{opt panelvar(varname)} identifies the individual/unit. Point estimates use
it only for sample validation and need not be balanced; standard errors use
it to build each unit's own baseline-differenced trajectory and therefore
do require, for each unit used in inference, an observation at every grid
date within [t0,t1].

{phang}
{opt timevar(varname)} is the calendar-time or period variable over which
the trajectory is observed.

{phang}
{opt treatvar(varname)} must be a time-invariant indicator equal to 1 for
treated units and 0 for control units.

{phang}
{opt t0(#)} is the reference/baseline period marking the start of the
integration window. Under parallel pre-trends, tau(t0) should be
approximately zero; {cmd:pathintdid} reports tau(t0) as a diagnostic and,
regardless of its value, nets it out of sigma, tau-bar, and the static
estimate by construction.

{phang}
{opt t1(#)} is the terminal evaluation date (endline). If omitted, it
defaults to the last period observed in the data. Setting {cmd:t1()} to an
intermediate rejoining date t2 recovers the full, horizon-invariant
cumulative effect described in the paper.

{phang}
{opt level(#)} sets the confidence level (default 95) used for the
reported confidence intervals and the critical value in the t-test.

{phang}
{opt graph} produces a twoway plot of c0(t) and c1(t) with the region
between them, over [t0, t1], shaded to represent sigma.

{phang}
{opt notable} suppresses the printed c0(t)/c1(t)/tau(t) table (results are
still returned in {cmd:r()}).

{phang}
{opt nose} skips the standard-error/t-statistic/confidence-interval
calculation.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:pathintdid} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars (always returned)}{p_end}
{synopt:{cmd:r(sigma)}}cumulative causal effect{p_end}
{synopt:{cmd:r(att_path)}}path-integrated ATT (sigma / (t1-t0)){p_end}
{synopt:{cmd:r(did_static)}}conventional static DiD, tauhat(t1){p_end}
{synopt:{cmd:r(tau_t0)}}pre-treatment gap at t0 (parallel-trends check){p_end}
{synopt:{cmd:r(t0)}}baseline period used{p_end}
{synopt:{cmd:r(t1)}}endline period used{p_end}
{synopt:{cmd:r(level)}}confidence level used{p_end}

{p2col 5 20 24 2: Scalars (returned only when standard errors are computed)}{p_end}
{synopt:{cmd:r(se_sigma)}}standard error of sigma{p_end}
{synopt:{cmd:r(t_sigma)}}t-statistic for H0: sigma = 0{p_end}
{synopt:{cmd:r(p_sigma)}}two-sided p-value{p_end}
{synopt:{cmd:r(ci_sigma_lb)}, {cmd:r(ci_sigma_ub)}}confidence interval for sigma{p_end}
{synopt:{cmd:r(se_att)}, {cmd:r(t_att)}, {cmd:r(p_att)}}standard error/t/p for tau-bar{p_end}
{synopt:{cmd:r(ci_att_lb)}, {cmd:r(ci_att_ub)}}confidence interval for tau-bar{p_end}
{synopt:{cmd:r(se_did)}, {cmd:r(t_did)}, {cmd:r(p_did)}}standard error/t/p for the static estimate{p_end}
{synopt:{cmd:r(ci_did_lb)}, {cmd:r(ci_did_ub)}}confidence interval for the static estimate{p_end}
{synopt:{cmd:r(N1)}, {cmd:r(N0)}}number of treated/control units used for inference{p_end}
{synopt:{cmd:r(df)}}degrees of freedom used for the t critical value (N1+N0-2){p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup: a 20-unit individual-level panel (10 treated, 10 control)
whose group means approximate the training-program illustration in
Salavi (2026), with genuine unit-level variation so that standard errors
can be computed.{p_end}

{phang2}{cmd:. use trainingpanel, clear}{p_end}

{pstd}Path-integrated estimate, with standard errors, t-statistics, and
95% confidence intervals:{p_end}

{phang2}{cmd:. pathintdid consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) graph}{p_end}

{pstd}
This reports sigma, tau-bar, and the static DiD estimate together with
their standard errors, t-statistics, and confidence intervals. In the
bundled example, sigma is large and statistically significant while the
static endpoint estimate is small and statistically indistinguishable
from zero -- exactly the endpoint-subtraction-bias pattern the paper
describes, now shown with genuine sampling uncertainty rather than an
exact zero.

{pstd}Suppressing the SE/t/CI machinery (point estimates only, faster):{p_end}

{phang2}{cmd:. pathintdid consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) nose}{p_end}

{pstd}Running the section 5 robustness checks and specification tests
(dynamic placebo test, grid-density/Simpson sensitivity, and the
anticipation-robust bounding estimator, shifting the baseline back by up
to two pre-treatment grid points):{p_end}

{phang2}{cmd:. pathintdidrobust consumption, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(4) maxanticip(2)}{p_end}


{marker references}{...}
{title:References}

{phang}
Salavi, C. A-F. 2026. "Path-Integrated Difference-in-Differences (PI-DiD):
Identification, Estimation, and Inference for Cumulative Treatment
Effects." Working paper, African School of Economics.

{title:Also see}

{psee}
{help pathintdidplot}

{psee}
{help pathintdidrobust}
