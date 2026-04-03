{smcl}
{* version 2.00  25mar2026}{...}
{cmd:help midas pubbias}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas pubbias} {hline 2} Deeks funnel plot for publication bias in diagnostic meta-analysis

{hline}

{title:Syntax}

{p 8 18 2}
{cmd:midas pubbias}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Plot elements}
{synopt:{cmd:wgt}}weight study points by effective sample size (bubble plot){p_end}
{synopt:{cmd:nowgt}}display unweighted equal-size study points{p_end}
{synopt:{cmd:regline}}overlay the weighted regression line{p_end}
{synopt:{cmd:sumline}}add a vertical reference line at the summary log DOR{p_end}

{syntab:Styling}
{synopt:{cmd:pointopts(}{it:scatter_options}{cmd:)}}marker options for the study scatter points{p_end}
{synopt:{cmd:regopts(}{it:line_options}{cmd:)}}line options for the regression line{p_end}
{synopt:{it:graph_options}}any {helpb twoway} options{p_end}

{syntab:Inference}
{synopt:{cmd:level(}{it:#}{cmd:)}}confidence level for the asymmetry test; default {cmd:level(95)}{p_end}
{synoptline}

{hline}

{title:Description}

{pstd}
{cmd:midas pubbias} produces the Deeks et al. (2005) funnel plot for assessing
publication bias and small-study effects in a diagnostic accuracy meta-analysis.
It plots the log diagnostic odds ratio (log DOR) on the x-axis against 1/sqrt(ESS)
on the y-axis, where ESS = 4n1n2/(n1+n2) is the effective sample size. Smaller
studies appear higher in the plot. A funnel that is asymmetric (non-zero intercept
in the regression of log DOR on 1/sqrt(ESS)) suggests selective reporting.

{pstd}
The regression is run with ESS weights and reported with a formal test of the
intercept. A significant p-value (typically p < 0.10) is taken as evidence of
asymmetry. The command must follow a {cmd:midas mle}, {cmd:midas qrsim},
{cmd:midas mh}, {cmd:midas hmc}, or {cmd:midas inla} estimation.

{pstd}
{cmd:wgt} and {cmd:nowgt} are mutually exclusive.

{hline}

{title:Options}

{phang}
{cmd:wgt} sizes study points proportionally to their effective sample size
(area-weighted bubble plot).

{phang}
{cmd:nowgt} displays all study points at a uniform size.

{phang}
{cmd:regline} overlays the fitted weighted regression line.

{phang}
{cmd:sumline} draws a vertical reference line at the summary log DOR from the
estimation model.

{phang}
{cmd:pointopts(}{it:scatter_options}{cmd:)} overrides the default study point
style (default: open circles, grey fill), e.g.
{cmd:pointopts(mcolor(navy) msymbol(circle_hollow))}.

{phang}
{cmd:regopts(}{it:line_options}{cmd:)} overrides the default regression line
style (default: dashed thin), e.g.
{cmd:regopts(lcolor(maroon) lwidth(medium) lpattern(solid))}.

{phang}
{cmd:level(}{it:#}{cmd:)} sets the confidence level for the asymmetry
regression. Default is {cmd:level(95)}. Note: many authors use {cmd:level(90)}
for publication bias testing.

{hline}

{title:Examples}

{pstd}Standard Deeks funnel with regression line:{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. midas pubbias, wgt regline}{p_end}

{pstd}Custom styling with summary reference line:{p_end}
{phang2}{cmd:. midas pubbias, wgt regline sumline pointopts(mcolor(navy)) regopts(lcolor(maroon) lwidth(medium))}{p_end}

{pstd}Unweighted, 90% level:{p_end}
{phang2}{cmd:. midas pubbias, nowgt regline level(90)}{p_end}

{hline}

{title:References}

{phang}
Deeks JJ, Macaskill P, Irwig L. The performance of tests of publication bias
and other sample size effects in systematic reviews of diagnostic test accuracy
was assessed. {it:Journal of Clinical Epidemiology} 2005;{bf:58}:882–893.
{browse "https://doi.org/10.1016/j.jclinepi.2005.01.016"}
{p_end}

{phang}
Egger M, Davey Smith G, Schneider M, Minder C. Bias in meta-analysis detected
by a simple, graphical test. {it:BMJ} 1997;{bf:315}:629–634.
{browse "https://doi.org/10.1136/bmj.315.7109.629"}
{p_end}

{hline}

{title:Also see}

{psee}
{helpb midas}, {helpb midas binsse}
