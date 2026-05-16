{smcl}
{* *! version 1.0.0 Subir Hait 2026}{...}
{viewerjumpto "Syntax"        "rdstagger_agg##syntax"}{...}
{viewerjumpto "Description"   "rdstagger_agg##description"}{...}
{viewerjumpto "Options"       "rdstagger_agg##options"}{...}
{viewerjumpto "Saved results" "rdstagger_agg##saved"}{...}
{viewerjumpto "Examples"      "rdstagger_agg##examples"}{...}

{title:Title}

{p 4 18 2}
{bf:rdstagger_agg} {hline 2} Aggregate ATT(g,t) estimates from {helpb rdstagger}
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rdstagger_agg} [{cmd:,} {opt type(string)}]

{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt type(string)}}aggregation type; default {cmd:dynamic}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rdstagger_agg} collapses the full ATT(g,t) matrix stored by
{helpb rdstagger} into interpretable summary estimands. Four aggregation
types are available. All estimates use post-treatment cells only, except
{cmd:dynamic} which includes pre-treatment cells for falsification.

{pstd}
Standard errors for aggregated quantities are computed by the
delta-method approximation: SE(mean) = sqrt(sum(SE_i^2)) / K, where
K is the number of cells averaged. This assumes independence across
cohort-period cells.

{pstd}
Results are stored back in {cmd:e()} alongside the original
{cmd:rdstagger} scalars and matrices, so {helpb rdstagger_pretest}
and {helpb rdstagger_plot} remain available after aggregation.

{marker options}{...}
{title:Options}

{phang}
{opt type(string)} selects the aggregation scheme:

{p2colset 9 28 28 2}{...}
{p2col:{cmd:dynamic}}Event-study aggregation. Averages ATT(g,t) across
cohorts with the same event time k = t{hline 1}g. Reports estimates for
k = -(G{hline 1}2), ..., -1 (pre-treatment) and 0, 1, ..., T{hline 1}1
(post-treatment). Pre-treatment estimates should be near zero if parallel
trends holds; use {helpb rdstagger_pretest} for a formal test.{p_end}
{p2col:{cmd:group}}Cohort aggregation. Reports the average post-treatment
ATT for each treatment cohort g, averaged over all post-treatment
calendar periods.{p_end}
{p2col:{cmd:calendar}}Calendar-time aggregation. Reports the average ATT
in each calendar period t, averaged over all cohorts treated by period t.{p_end}
{p2col:{cmd:overall}}Single overall ATT: simple unweighted average of all
post-treatment ATT(g,t) cells.{p_end}

{marker saved}{...}
{title:Saved results}

{pstd}{cmd:rdstagger_agg} saves in {cmd:e()}:

{synoptset 22 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:e(agg)}}aggregated estimates matrix. Columns: (1) index
(event time, cohort, or period), (2) ATT, (3) SE, (4) CI lower,
(5) CI upper, (6) p-value. For {cmd:dynamic}: column (7) = post indicator.{p_end}
{synopt:{cmd:e(attgt)}}original ATT(g,t) matrix from {helpb rdstagger}{p_end}
{syntab:Scalars}
{synopt:{cmd:e(N)}}observations (preserved from {helpb rdstagger}){p_end}
{synopt:{cmd:e(overall_att)}}overall ATT (type overall only){p_end}
{synopt:{cmd:e(overall_se)}}SE of overall ATT (type overall only){p_end}
{syntab:Macros}
{synopt:{cmd:e(agg_type)}}aggregation type used{p_end}
{synopt:{cmd:e(cmd)}}{cmd:rdstagger}{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. rdstagger_sim, n(400) periods(8) cohorts(3) seed(42)}{p_end}
{phang2}{cmd:. rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)}{p_end}

{pstd}Event-study:{p_end}
{phang2}{cmd:. rdstagger_agg, type(dynamic)}{p_end}
{phang2}{cmd:. rdstagger_plot}{p_end}

{pstd}Cohort-level ATT:{p_end}
{phang2}{cmd:. rdstagger_agg, type(group)}{p_end}

{pstd}Calendar-time ATT:{p_end}
{phang2}{cmd:. rdstagger_agg, type(calendar)}{p_end}

{pstd}Overall ATT:{p_end}
{phang2}{cmd:. rdstagger_agg, type(overall)}{p_end}
{phang2}{cmd:. di "Overall ATT = " e(overall_att)}{p_end}

{title:Also see}

{psee}
{helpb rdstagger}, {helpb rdstagger_pretest}, {helpb rdstagger_plot}
{p_end}
