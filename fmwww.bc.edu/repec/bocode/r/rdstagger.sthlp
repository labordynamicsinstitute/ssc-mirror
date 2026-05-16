{smcl}
{* *! version 1.0.0 Subir Hait 2026}{...}
{viewerjumpto "Syntax"        "rdstagger##syntax"}{...}
{viewerjumpto "Description"   "rdstagger##description"}{...}
{viewerjumpto "Options"       "rdstagger##options"}{...}
{viewerjumpto "Remarks"       "rdstagger##remarks"}{...}
{viewerjumpto "Saved results" "rdstagger##saved"}{...}
{viewerjumpto "Examples"      "rdstagger##examples"}{...}
{viewerjumpto "References"    "rdstagger##references"}{...}
{viewerjumpto "Author"        "rdstagger##author"}{...}

{title:Title}

{p 4 18 2}
{bf:rdstagger} {hline 2} Staggered Regression Discontinuity with Network Interference
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rdstagger} {it:yvar xvar} {ifin}{cmd:,}
{opt cutoff(#)}
{opt gvar(varname)}
{opt tvar(varname)}
{opt idvar(varname)}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt cutoff(#)}}RD cutoff value on the running variable{p_end}
{synopt:{opt gvar(varname)}}cohort variable: period unit i first received treatment;
{cmd:.} for never-treated{p_end}
{synopt:{opt tvar(varname)}}calendar time period variable{p_end}
{synopt:{opt idvar(varname)}}unit identifier{p_end}
{syntab:Optional}
{synopt:{opt bw(#)}}RD bandwidth (required, must be positive){p_end}
{synopt:{opt kernel(string)}}{cmd:triangular} (default), {cmd:epanechnikov}, or {cmd:uniform}{p_end}
{synopt:{opt control(string)}}{cmd:nevertreated} (default) or {cmd:notyetreated}{p_end}
{synopt:{opt cov:ariates(varlist)}}additional covariates entered linearly{p_end}
{synopt:{opt boot:strap}}use bootstrap standard errors{p_end}
{synopt:{opt nboot(#)}}bootstrap replications; default 499{p_end}
{synopt:{opt alpha(#)}}significance level for CIs; default 0.05{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rdstagger} estimates ATT(g,t) {hline 1} the average treatment effect
for the cohort of units first treated in period g, measured at calendar
time t {hline 1} within a unified framework that combines three
identification strategies:

{phang2}
(1) {bf:Regression discontinuity (RD)}: treatment eligibility is determined
by a running variable crossing a known cutoff. Kernel weights concentrate
the comparison on observations near the cutoff.

{phang2}
(2) {bf:Staggered difference-in-differences}: units adopt treatment at
heterogeneous times (cohorts), following the framework of Callaway and
Sant'Anna (2021). This avoids the forbidden-comparison problem of
two-way fixed effects estimators under treatment effect heterogeneity.

{phang2}
(3) {bf:Network interference}: units may receive spillover effects through
a network of neighbors. The command estimates both the direct ATT (on
treated units) and the share of neighbors treated as a spillover proxy
(Manski, 2013).

{pstd}
For each cohort-period cell, {cmd:rdstagger} computes a kernel-weighted
DiD using the pre-treatment period immediately before treatment adoption
as the base period (g{hline 1}1).

{marker options}{...}
{title:Options}

{phang}
{opt cutoff(#)} specifies the RD threshold. Units whose running variable
falls below this value are treatment-eligible by design.

{phang}
{opt gvar(varname)} is the cohort variable. It should equal the first
calendar period in which unit i was treated. Set to missing ({cmd:.})
for never-treated units. Must not equal 0 or 1 (period indexing should
start at 2 or higher so that base period g{hline 1}1 exists).

{phang}
{opt tvar(varname)} is the calendar time variable (integer).

{phang}
{opt idvar(varname)} is the panel unit identifier.

{phang}
{opt bw(#)} sets the RD bandwidth. A positive value must be supplied
by the user (e.g. {opt bw(1.5)}). Choose a bandwidth that provides
sufficient observations on both sides of the cutoff within each
cohort-period cell. Automatic bandwidth selection via {cmd:rdrobust}
will be available in a future release.

{phang}
{opt kernel(string)} specifies the kernel weighting function.
{cmd:triangular} (default) assigns weight 1{hline 1}|x{hline 1}c|/h
to observations within bandwidth h. {cmd:epanechnikov} uses a
quadratic kernel. {cmd:uniform} assigns equal weight to all units
within the bandwidth.

{phang}
{opt control(string)} specifies the comparison group.
{cmd:nevertreated} (default) compares each cohort to units with
{cmd:gvar = .}. {cmd:notyetreated} also includes units whose treatment
cohort is strictly later than the calendar period being evaluated.

{phang}
{opt covariates(varlist)} includes additional regressors in the
outcome model. Covariates enter linearly and are mean-centered within
each cohort-period cell.

{phang}
{opt bootstrap} requests bootstrap standard errors. The bootstrap
resamples units within each cohort-period cell. This is more reliable
than the analytic approximation in small cells but is substantially
slower. For exploration, use {opt nboot(199)}.

{phang}
{opt nboot(#)} sets the number of bootstrap replications. Default 499.
Ignored unless {opt bootstrap} is specified.

{phang}
{opt alpha(#)} sets the significance level for confidence intervals.
Default 0.05 (95% CI).

{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Standard errors.} When {opt bootstrap} is not specified, standard
errors are computed as a conservative analytic approximation
(pooled standard deviation divided by square root of effective sample
size within the cell). These are suitable for large samples. For
small cohort-period cells or heteroskedastic outcomes, {opt bootstrap}
is recommended.

{pstd}
{bf:Base period.} The base period for cohort g is g{hline 1}1. Cells
with fewer than five treated or control observations are set to missing.

{pstd}
{bf:Aggregation.} Use {helpb rdstagger_agg} to collapse ATT(g,t) into
event-study, cohort-level, calendar-time, or overall summaries.
Use {helpb rdstagger_pretest} to test pre-treatment parallel trends.
Use {helpb rdstagger_plot} to produce coefficient plots.

{marker saved}{...}
{title:Saved results}

{pstd}{cmd:rdstagger} saves the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:e(attgt)}}ATT(g,t) matrix. Rows = cohort{hline 1}period cells.
Columns: (1) cohort, (2) period, (3) ATT, (4) SE, (5) CI lower,
(6) CI upper, (7) p-value, (8) N treated, (9) N control,
(10) pre/post indicator (1=post){p_end}
{syntab:Scalars}
{synopt:{cmd:e(N)}}total observations used{p_end}
{synopt:{cmd:e(bandwidth)}}bandwidth applied{p_end}
{synopt:{cmd:e(n_cohorts)}}number of cohorts{p_end}
{synopt:{cmd:e(n_periods)}}number of periods{p_end}
{syntab:Macros}
{synopt:{cmd:e(cmd)}}{cmd:rdstagger}{p_end}
{synopt:{cmd:e(control)}}control group used{p_end}
{synopt:{cmd:e(kernel)}}kernel used{p_end}
{synopt:{cmd:e(yvar)}}outcome variable{p_end}
{synopt:{cmd:e(xvar)}}running variable{p_end}
{synopt:{cmd:e(gvar)}}cohort variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Basic workflow with simulated data:{p_end}

{phang2}{cmd:. rdstagger_sim, n(400) periods(8) cohorts(3) direct(0.3) spill(0.1) seed(42)}{p_end}
{phang2}{cmd:. rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)}{p_end}
{phang2}{cmd:. rdstagger_pretest, method(both)}{p_end}
{phang2}{cmd:. rdstagger_agg, type(dynamic)}{p_end}
{phang2}{cmd:. rdstagger_plot}{p_end}
{phang2}{cmd:. rdstagger_spillover}{p_end}

{pstd}With not-yet-treated controls and bootstrap SEs:{p_end}
{phang2}{cmd:. rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id)}{p_end}
{phang2}{cmd:    bw(1.5) control(notyetreated) bootstrap nboot(299)}{p_end}

{pstd}All aggregation types:{p_end}
{phang2}{cmd:. rdstagger_agg, type(dynamic)}{p_end}
{phang2}{cmd:. rdstagger_agg, type(group)}{p_end}
{phang2}{cmd:. rdstagger_agg, type(calendar)}{p_end}
{phang2}{cmd:. rdstagger_agg, type(overall)}{p_end}

{marker references}{...}
{title:References}

{phang}
Callaway, B., and Sant'Anna, P. H. C. (2021).
Difference-in-differences with multiple time periods.
{it:Journal of Econometrics}, 225(2), 200{c -}230.
{browse "https://doi.org/10.1016/j.jeconom.2020.12.001"}

{phang}
Calonico, S., Cattaneo, M. D., and Titiunik, R. (2014).
Robust nonparametric confidence intervals for regression-discontinuity designs.
{it:Econometrica}, 82(6), 2295{c -}2326.
{browse "https://doi.org/10.3982/ECTA11757"}

{phang}
Manski, C. F. (2013).
Identification of treatment response with social interactions.
{it:The Econometrics Journal}, 16(1), S1{c -}S23.
{browse "https://doi.org/10.1111/j.1368-423X.2012.00368.x"}

{phang}
Imbens, G., and Lemieux, T. (2008).
Regression discontinuity designs: A guide to practice.
{it:Journal of Econometrics}, 142(2), 615{c -}635.

{marker author}{...}
{title:Author}

{pstd}
Subir Hait{break}
Michigan State University{break}
haitsubi@msu.edu{break}
{browse "https://github.com/causalfragility-lab/rdstagger-stata"}

{pstd}
Please report bugs and suggestions via the GitHub repository above.

{title:Also see}

{psee}
{helpb rdstagger_sim} {hline 2} simulate panel data{break}
{helpb rdstagger_agg} {hline 2} aggregate ATT(g,t){break}
{helpb rdstagger_pretest} {hline 2} pre-treatment falsification tests{break}
{helpb rdstagger_plot} {hline 2} event-study plot{break}
{helpb rdstagger_spillover} {hline 2} decompose direct vs spillover ATT
{p_end}
