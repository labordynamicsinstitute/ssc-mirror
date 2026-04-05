{smcl}
{* coefconv_plot.sthlp -- help file for coefconv_plot v1.0.0 *}
{hline}
{title:Title}

{pstd}{bf:coefconv_plot} {hline 2} Visualization of regression coefficient meaningfulness{p_end}

{hline}
{title:Syntax}

{pstd}
{cmd:coefconv_plot} [{cmd:,} {it:options}]
{p_end}

{synoptset 22 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt gr:ate(#)}}growth rate for discrete delta-X = grate x Xbar; default {bf:0.01} (1%){p_end}
{synopt:{opt lev:el(#)}}CI level for forest plot; default {bf:95}{p_end}
{synopt:{opt sch:eme(str)}}Stata graph scheme (e.g. s1color, lean2){p_end}
{synopt:{opt sav:ing(stub[,replace])}}save graphs: stub_std.gph, stub_pratt.gph, stub_eff_X.gph{p_end}
{synopt:{opt noSTD}}skip the standardized slopes forest plot{p_end}
{synopt:{opt noPRATT}}skip the Pratt importance bar chart{p_end}
{synopt:{opt noEFFects}}skip the per-variable discrete effects plots{p_end}
{synoptline}

{hline}
{title:Description}

{pstd}
{cmd:coefconv_plot} is the visualization companion to {helpb coefconv}.
It produces three separately named graphs (opened simultaneously in Stata's
Graph window) to assess which coefficients are statistically and practically
meaningful.  Run immediately after any OLS regression before any other
estimation command.

{pstd}
The program calls {cmd:coefconv} internally (silently) so no prior call to
{cmd:coefconv} is required.

{pstd}
Each graph is assigned a unique {cmd:name()} so all three remain open
at once: {bf:ccv_std} (Graph 1), {bf:ccv_pratt} (Graph 2), and
{bf:ccv_eff_}{it:varname} (Graph 3, one per predictor).

{hline}
{title:Graph 1 -- Standardized Slopes Forest Plot}

{pstd}
{it:Graph name:} {bf:ccv_std}

{pstd}
{it:Question answered:} Which predictors have effects that are both
statistically distinguishable from zero and large enough to matter?

{pstd}
{it:What is displayed:}

{p2colset 5 30 32 2}
{p2col:{bf:Diamond markers}}beta* (fully standardized slope = beta x sdX / sdY)
for each predictor. {bf:Navy} = significant at the chosen level;
{bf:Gray} = not significant.{p_end}
{p2col:{bf:Horizontal lines}}Confidence intervals of width +/- z(alpha/2) x SE(beta*),
where SE(beta*) = SE(beta) x sdX / sdY.{p_end}
{p2col:{bf:Vertical dashed lines}}Cohen (1988) benchmarks at +/-0.20 (small),
+/-0.50 (medium), +/-0.80 (large).{p_end}
{p2col:{bf:Vertical solid line}}Zero reference. CIs that do not cross zero
indicate statistical significance.{p_end}

{pstd}
{it:How to read it:}

{phang2}A large navy diamond beyond the 0.50 dashes: the predictor is
significant AND has a medium-to-large standardized effect.{p_end}
{phang2}A small navy diamond between 0 and 0.20: statistically significant
but too small to clear Cohen's minimum threshold.{p_end}
{phang2}A gray diamond regardless of size: the effect is indistinguishable
from zero given sampling variability.{p_end}
{phang2}Comparing diamonds: beta* = 0.60 represents three times the effect
of beta* = 0.20 in standard-deviation units.{p_end}

{hline}
{title:Graph 2 -- Pratt Importance Bar Chart}

{pstd}
{it:Graph name:} {bf:ccv_pratt}

{pstd}
{it:Question answered:} How much of the explained variance (R-squared) does
each predictor account for, net of correlations among predictors?

{pstd}
{it:What is displayed:}
Horizontal bars showing each predictor's Pratt percentage of R-squared,
sorted ascending by absolute magnitude (smallest at bottom).
{bf:Navy} bars = productive predictors.
{bf:Cranberry} bars = suppressor variables (negative Pratt index).

{pstd}
{it:How to read it:}

{phang2}A bar at 60% means the predictor explains 60% of the model's R-squared.
All bars sum to 100% by construction.{p_end}
{phang2}A suppressor variable (cranberry bar) boosts the R-squared contribution
of other predictors by absorbing error variance. Do not remove it.{p_end}
{phang2}A predictor can have a significant beta but a low Pratt% -- it is
statistically reliable but makes a small unique contribution to fit.{p_end}
{phang2}Predictors are sorted so the most important appears at the top,
making visual ranking immediate.{p_end}

{hline}
{title:Graph 3 -- Discrete Effects Bar Chart}

{pstd}
{it:Graph name:} {bf:ccv_eff_}{it:varname} (one graph per predictor)

{pstd}
{it:Question answered:} How large is this predictor's effect in the original
units of Y, across a range of realistic assumptions about the size of the
change in X?

{pstd}
{it:What is displayed:}
For each predictor, nine delta-Y scenarios are drawn as horizontal bars on a
common axis (all in Y-units), sorted by absolute magnitude ascending.
{bf:Navy} bars = positive delta-Y.  {bf:Cranberry} bars = negative delta-Y.

{pstd}
{it:Nine scenarios and their interpretation:}

{p2colset 5 32 34 2}
{p2col:{bf:Growth rate (default 1%)}}beta x (grate x Xbar).
Smallest realistic shift. Asks: is even a 1% expansion in X meaningful
in Y-unit terms? Controlled by the {opt grate()} option.{p_end}

{p2col:{bf:+/- 1 SD}}beta x sdX.
Standard effect-size unit used throughout social science.
Spans roughly the 16th to 84th percentile of X.{p_end}

{p2col:{bf:+/- 2 SD}}beta x 2*sdX.
Near-complete distributional range, spanning approximately p2 to p98.
Comparable to the range recommended by Gelman & Hill for continuous
predictors.{p_end}

{p2col:{bf:IQR (Q25 to Q75)}}beta x (X_p75 - X_p25).
Effect for the typical middle 50% of the distribution.
Most robust scenario because it is unaffected by extreme outliers in X.
Preferred for policy communication.{p_end}

{p2col:{bf:Full range (min to max)}}beta x (X_max - X_min).
Maximum theoretically possible effect within the observed data.
Sensitive to outliers; useful as an upper ceiling.{p_end}

{p2col:{bf:p50 to p10}}beta x (X_p10 - X_p50).
Effect of a downward shift from the median to the 10th percentile.
Negative delta-X when beta > 0.{p_end}

{p2col:{bf:p50 to p25}}beta x (X_p25 - X_p50).
Smaller downward shift from the median.{p_end}

{p2col:{bf:p50 to p75}}beta x (X_p75 - X_p50).
Upward shift from the median to the 75th percentile.{p_end}

{p2col:{bf:p50 to p90}}beta x (X_p90 - X_p50).
Larger upward shift from the median to the 90th percentile.{p_end}

{pstd}
{it:How to read it:}

{phang2}The bottom bar (Growth 1%) is the minimum realistic benchmark.
If this bar is already large in Y-unit terms the predictor matters even
for small changes in X.{p_end}
{phang2}The IQR bar is the most policy-relevant: it answers "what is
the effect of moving from a below-average to an above-average value of X?"{p_end}
{phang2}If all bars are tiny relative to the mean of Y or to substantive
thresholds in your field, the predictor may be statistically significant
but practically negligible.{p_end}
{phang2}Bars are sorted by |delta-Y| so the "effect ladder" is immediately
visible -- the most consequential scenario is always at the top.{p_end}

{hline}
{title:Interpreting Coefficient Meaningfulness}

{pstd}
A coefficient is meaningful on two independent dimensions which the three
graphs address together:

{pstd}
{bf:Statistical meaningfulness} -- answered by Graph 1 (forest plot).
The CI must not cross zero. A significant result rules out a zero effect
with the chosen level of confidence. But significance alone does not
indicate the effect is large.

{pstd}
{bf:Practical meaningfulness} -- answered jointly by Graph 1 (beta* size),
Graph 2 (Pratt share), and Graph 3 (delta-Y magnitude):

{p2colset 5 24 26 2}
{p2col:{bf:beta* threshold}}In social science, beta* >= 0.10 is a minimum
meaningful effect; 0.30 is medium; 0.50 is large (Cohen 1988). Different
fields use different benchmarks.{p_end}

{p2col:{bf:Pratt threshold}}A predictor with Pratt% < 5% makes a small
unique contribution to R-squared even if its beta is significant.{p_end}

{p2col:{bf:delta-Y threshold}}Compare the IQR scenario's delta-Y to the
mean of Y or to a field-specific minimum important difference.
For example: in wage research a $0.05/hour effect may be negligible;
in a clinical trial a 2-point reduction on a 100-point scale may matter.{p_end}

{pstd}
The {it:most meaningful} predictors satisfy all four criteria simultaneously:
significant beta, large beta*, large Pratt%, and substantial delta-Y.

{hline}
{title:Usage Examples}

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight foreign}{p_end}
{phang2}{cmd:. coefconv_plot}{p_end}

{phang2}{it:// Forest plot and Pratt chart only (skip per-variable plots)}{p_end}
{phang2}{cmd:. coefconv_plot, noeffects}{p_end}

{phang2}{it:// 90% CI, 5% growth rate}{p_end}
{phang2}{cmd:. coefconv_plot, level(90) grate(0.05)}{p_end}

{phang2}{it:// Save all graphs with stub "auto_plots"}{p_end}
{phang2}{cmd:. coefconv_plot, saving(auto_plots, replace)}{p_end}

{phang2}{it:// Forest plot only, 99% CI, s1color scheme}{p_end}
{phang2}{cmd:. coefconv_plot, nopratt noeffects level(99) scheme(s1color)}{p_end}

{phang2}{it:// Browse a saved graph later}{p_end}
{phang2}{cmd:. graph use auto_plots_std}{p_end}
{phang2}{cmd:. graph use auto_plots_eff_weight}{p_end}

{hline}
{title:Technical Notes}

{pstd}
{bf:SE of beta*:} Computed as SE(beta) x sdX / sdY where SE(beta) comes from
sqrt(e(V)[j,j]). Valid for OLS. Interpret with caution for IV or FE models
where the VCE matrix structure differs.

{pstd}
{bf:Sorting in Graph 3:} Scenarios are sorted by |delta-Y| ascending
(smallest at bottom) so the graph reads as an effect ladder. The growth-rate
scenario typically sits at the bottom and full-range at the top.

{pstd}
{bf:Factor variables:} Predictors using Stata factor notation (e.g. i.region)
are skipped in Graphs 2 and 3 because they cannot be summarized by a single
mean, SD, or set of quantiles. Their raw beta appears in Graph 1.

{pstd}
{bf:Graph names:} Stata keeps all named graphs open simultaneously. To list
open graphs type {cmd:graph dir}. To bring any graph to the front type
{cmd:graph display} {it:name}.

{hline}
{title:Dependencies}

{pstd}
Requires {helpb coefconv} to be in the adopath.
Place both {cmd:coefconv.ado} and {cmd:coefconv_plot.ado} in the same
directory (e.g. ~/ado/personal/ on Mac/Linux or C:\ado\personal\ on Windows).

{hline}
{title:Author}

{pstd}
Dr Noman Arshed{break}
Senior Lecturer, Department of Business Analytics{break}
Sunway Business School, Sunway University{break}
{browse "mailto:nouman.arshed@gmail.com":nouman.arshed@gmail.com}
{p_end}

{hline}
{title:Also see}

{pstd}{helpb coefconv}, {helpb regress}, {helpb margins}, {helpb coefplot}{p_end}
