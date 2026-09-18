{smcl}
{* *! version 1.0.0 16sep2026}{...}
{vieweralsosee "stcrreg" "help stcrreg"}{...}
{vieweralsosee "stcurve" "help stcurve"}{...}

{title:Title}

{phang}
{bf:fgcifplot} {hline 2} Stata module to draw Fine-Gray cumulative-incidence plots with conventional and subdistribution risk-set summaries

{title:Syntax}

{p 8 17 2}
{cmd:fgcifplot} {it:groupvar}
[{cmd:,}
{opt values(numlist)}
{opt risktimes(numlist)}
{opt risktable(types)}
{opt at(at_spec)}
{opt name(name)}
{opt risksaving(filename)}
{opt replace}
{opt nograph}
{opt curveopts(options)}
{opt tableopts(options)}
{opt combineopts(options)}
{opt tablepct(#)}
{opt wformat(format)}]

{pstd}
{cmd:fgcifplot} is a postestimation command.  The immediately preceding estimation command must be {cmd:stcrreg}.

{title:Description}

{pstd}
{cmd:fgcifplot} draws model-based cumulative-incidence curves after Fine-Gray competing-risks regression and can place one or more risk-set summaries below the curve.

{pstd}
The command distinguishes three different quantities that are often conflated in competing-risks figures:

{phang2}
{bf:Conventional N at risk}: subjects whose observed follow-up interval still contains time t.  Subjects leave after the event of interest, a competing event, or censoring.

{phang2}
{bf:FG retained N}: the conventional risk set plus subjects who experienced a competing event before t.  Each retained competing-event subject counts as one.  This is the unweighted head count of the extended Fine-Gray risk set.

{phang2}
{bf:FG weighted total}: the conventional risk set plus retained competing-event subjects weighted by the inverse-probability-of-censoring weight used by {cmd:stcrreg}.  For a subject j with a prior competing event, the contribution at time t is the censoring-survival function evaluated at t divided by that function evaluated at the subject's competing-event time.  This quantity may be noninteger.  It is a weighted risk-set total, not a survey-style effective sample size.

{pstd}
The cumulative-incidence curves are adjusted model predictions produced by {cmd:stcurve}.  Covariates not explicitly set in {cmd:at()} follow {cmd:stcurve}'s usual postestimation defaults.  In contrast, the risk-set summaries are unadjusted observed quantities calculated within the requested groups; they are not model-adjusted predictions.

{pstd}
The default is {cmd:risktable(conventional)}.  Specify {cmd:risktable(all)} to display all three.

{title:Options}

{phang}
{opt values(numlist)} specifies the values of {it:groupvar} for which CIF curves and risk-set rows are produced.  By default, all nonmissing values of {it:groupvar} in the {cmd:stcrreg} estimation sample are used.  {it:groupvar} must be represented in the fitted model, including through factor-variable or interaction terms.

{pstd}
If {it:groupvar} has an attached Stata value label, {cmd:fgcifplot} automatically uses those labels in the curve legend and risk-table rows.  Otherwise, the numeric group values are shown.

{phang}
{opt risktimes(numlist)} specifies the displayed risk-table times and the x-axis tick positions.  Explicit values are recommended for publication figures.  If omitted, five equally spaced times spanning observed follow-up are used.

{phang}
{opt risktable(types)} specifies one or more of {cmd:conventional}, {cmd:retained}, and {cmd:weighted}.  {cmd:all} requests all three.  {cmd:none} suppresses the risk table.  The default is {cmd:conventional}.

{phang}
{opt at(at_spec)} supplies additional covariate settings to {cmd:stcurve}.  Do not repeat {it:groupvar}; {cmd:fgcifplot} supplies its requested values automatically.  Unspecified covariates follow {cmd:stcurve}'s usual postestimation behavior.

{phang}
{opt risksaving(filename)} saves all three risk-set summaries in long format with variables {cmd:risk_type}, {cmd:group_value}, {cmd:group_label}, {cmd:time}, and {cmd:value}, regardless of which summaries are displayed by {cmd:risktable()}.  Thus {cmd:risktable(none)} may be combined with {cmd:risksaving()} to export the summaries without drawing a table.  Specify {cmd:replace} to overwrite an existing file.

{phang}
{opt nograph} calculates and returns the risk-set matrices without drawing a graph.

{phang}
{opt curveopts(options)} passes graph options to the model-based CIF panel drawn by {cmd:fgcifplot}.

{phang}
{opt tableopts(options)} passes graph options to the risk-table panel.

{phang}
{opt combineopts(options)} passes options to {cmd:graph combine}.


{pstd}
When more than one risk summary is requested, the table blocks use compact vertical spacing within the allocated table panel.  The full table region remains subject to the {cmd:tablepct()} cap described below.

{phang}
{opt tablepct(#)} controls the percentage of vertical figure area allocated to the risk-table panel.  The automatic default is 22% for one table, 28% for two tables, and 33% for all three.  Values must be between 15 and 33; the table panel is therefore never allowed to occupy more than one-third of the combined figure.

{phang}
{opt wformat(format)} controls display formatting of the weighted Fine-Gray total.  The default is {cmd:%9.1f}.

{title:Stored results}

{pstd}
{cmd:fgcifplot} stores the following in {cmd:r()}:

{synoptset 24 tabbed}{...}
{synopt:{cmd:r(conventional)}}matrix of conventional numbers at risk; rows are groups and columns are requested times{p_end}
{synopt:{cmd:r(retained)}}matrix of unweighted Fine-Gray retained-set counts{p_end}
{synopt:{cmd:r(weighted)}}matrix of Fine-Gray censoring-weighted risk-set totals{p_end}
{synopt:{cmd:r(censor_survival)}}Kaplan-Meier censoring-survival G(t) evaluated at requested times{p_end}
{synopt:{cmd:r(group_values)}}row vector of plotted group values{p_end}
{synopt:{cmd:r(times)}}row vector of requested risk-table times{p_end}
{synopt:{cmd:r(groupvar)}}group variable name{p_end}
{synopt:{cmd:r(risk_types)}}risk-table types requested{p_end}
{synopt:{cmd:r(compete_var)}}competing-event variable recovered from {cmd:stcrreg}{p_end}
{synopt:{cmd:r(compete_values)}}competing-event values, when explicitly specified{p_end}

{title:Examples}

{pstd}Public Stata example:{p_end}

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. stset dftime, failure(failtype==1)}{p_end}
{phang2}{cmd:. stcrreg ifp tumsize i.pelnode, compete(failtype==2) nolog}{p_end}
{phang2}{cmd:. fgcifplot pelnode, values(0 1) risktimes(0 2 4 6 8) risktable(all)}{p_end}

{pstd}Calculate all three tables without graphing:{p_end}

{phang2}{cmd:. fgcifplot pelnode, values(0 1) risktimes(0 2 4 6 8) risktable(all) nograph}{p_end}
{phang2}{cmd:. matrix list r(conventional)}{p_end}
{phang2}{cmd:. matrix list r(retained)}{p_end}
{phang2}{cmd:. matrix list r(weighted)}{p_end}

{title:Interpretation}

{pstd}
A conventional risk table and a Fine-Gray CIF are not mathematically the same risk set.  The conventional table is a descriptive follow-up count.  Fine-Gray estimation extends the risk set by retaining subjects after competing events and downweights those retained subjects over time according to the estimated censoring distribution.  {cmd:fgcifplot} exposes both constructions rather than silently labeling them as the same quantity.


{title:Validation}

{pstd}
The distributed ancillary files include {cmd:fgcifplot_README.txt} and {cmd:fgcifplot_VALIDATION.txt}; {cmd:test_fgcifplot_knowntruth.do}, which constructs a synthetic competing-risks dataset with hand-calculable conventional, retained, and censoring-weighted risk-set values, asserts equality to the command output, and independently cross-checks the censoring survivor function against {cmd:predict, kmcensor}; {cmd:test_fgcifplot.do}, which freezes public {cmd:hypoxia} results from Stata 14.2 as a regression test; {cmd:test_fgcifplot_edgecases.do}, which checks defensive behavior and unsupported data structures; and {cmd:stress_fgcifplot.do}, which exercises four labeled groups and a denser risk-time grid for graphical layout testing.

{title:Current limitations}

{pstd}
Version 1.0 supports one record per subject, unweighted {cmd:stset} data, and entry at time zero.  Multiple-record survival data, observation weights, and delayed entry/left truncation are rejected explicitly rather than approximated.  Delayed entry requires separate validation of the Fine-Gray weighting construction before support is claimed.

{title:Methods}

{pstd}
The weighted table follows the Fine-Gray risk-pool weights used by {cmd:stcrreg}.  For a subject who has experienced a competing event before the displayed time, the retained contribution is the censoring-survival function evaluated at the displayed time divided by the same function evaluated at the competing-event time.  The censoring-survival function is estimated by Kaplan-Meier with censorings treated as the event of interest.  The implementation uses the censoring convention up to, but not including, the evaluation time.

{title:References}

{phang}
Fine, J. P., and R. J. Gray. 1999. A proportional hazards model for the subdistribution of a competing risk. {it:Journal of the American Statistical Association} 94(446): 496-509.

{title:Author}

{pstd}
Christina Laternser, PhD{break}
Email: {browse "mailto:claternser@luriechildrens.org":claternser@luriechildrens.org}

{title:License}

{pstd}
MIT License.  See {cmd:fgcifplot_LICENSE.txt}.
