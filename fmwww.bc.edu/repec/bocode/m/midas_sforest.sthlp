{smcl}
{* *! version 1.0.0  30mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas eforest" "help midas_eforest"}{...}
{viewerjumpto "Syntax" "midas_sforest##syntax"}{...}
{viewerjumpto "Description" "midas_sforest##description"}{...}
{viewerjumpto "Options" "midas_sforest##options"}{...}
{viewerjumpto "Examples" "midas_sforest##examples"}{...}
{viewerjumpto "Stored results" "midas_sforest##results"}{...}
{viewerjumpto "Author" "midas_sforest##author"}{...}

{title:Title}

{phang}
{bf:midas sforest} {hline 2} Summary forest plot with pooled estimates for DTA meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas sforest}
{cmd:,} {opt plott:ype(type)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt plott:ype(type)}}plot style: {bf:generic}, {bf:ellipse}, {bf:thick}, or {bf:rain}{p_end}

{syntab:Options}
{synopt:{opt level(#)}}confidence level; default is 95{p_end}
{synopt:{opt ms:cale(#)}}marker size scale; default is 0.75{p_end}
{synopt:{opt texts:cale(#)}}text size scale; default is 0.75{p_end}
{synopt:{opt cim:ethod(method)}}CI method: {bf:exact} (default), {bf:wilson}, or {bf:wald}{p_end}
{synopt:{opt pred:interval}}display 95% prediction interval{p_end}
{synopt:{opt ovl:ine}}display overall reference line at pooled estimate{p_end}
{synopt:{opt cic:olor(color)}}colour for confidence intervals{p_end}
{synopt:{opt diamc:olor(color)}}colour for summary diamond{p_end}
{synoptline}

{pstd}
{cmd:midas sforest} is a post-estimation command.  It requires prior execution of
a MIDAS estimation command ({cmd:midas mle}, {cmd:midas mh}, {cmd:midas hmc},
or {cmd:midas inla}).


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas sforest} produces coupled (paired) forest plots of study-specific
sensitivity and specificity {bf:with} a pooled summary diamond at the bottom.
This is the post-estimation version of the forest plot, designed for presenting
the final results of a DTA meta-analysis.

{pstd}
The pooled summary estimates (sensitivity, specificity, and their confidence
intervals) are extracted from the most recent MIDAS estimation command.  For
MLE, estimates come from {cmd:e(bsum)}.  For Bayesian engines (MH, HMC),
posterior medians and credible intervals are used.  For INLA, posterior
marginal summaries are used.

{pstd}
Four plot styles are available:

{phang2}{bf:generic} {hline 2} Standard square-and-whisker with summary diamond.
Each study is a square (proportional to weight) with a horizontal confidence
interval.  The pooled estimate appears as a diamond at the bottom.{p_end}

{phang2}{bf:ellipse} {hline 2} Each study shown as a confidence ellipse with
pooled diamond.  Preserves the Se-Sp correlation structure.{p_end}

{phang2}{bf:thick} {hline 2} Graduated line thickness with summary diamond.{p_end}

{phang2}{bf:rain} {hline 2} Rainforest plot with density-shaded raindrops and
summary diamond.{p_end}

{pstd}
For the exploratory forest plot without summary diamond, see
{helpb midas_eforest:midas eforest}.


{marker options}{...}
{title:Options}

{phang}
{opt plottype(type)} selects the visual style.  Required.

{phang}
{opt level(#)} confidence level.  Default is 95.

{phang}
{opt mscale(#)} scales the marker size.  Default is 0.75.

{phang}
{opt textscale(#)} scales the text size.  Default is 0.75.

{phang}
{opt cimethod(method)} CI computation method: {bf:exact} (Clopper-Pearson,
default), {bf:wilson}, or {bf:wald}.

{phang}
{opt predinterval} displays the 95% prediction interval, reflecting
between-study heterogeneity.  The prediction interval shows where a future
study's sensitivity and specificity might fall and is always wider than
the confidence interval for the pooled estimate.

{phang}
{opt ovline} draws a vertical reference line at the pooled sensitivity
and specificity estimates, making it easy to see which studies fall above
or below the summary.


{marker examples}{...}
{title:Examples}

{pstd}Basic summary forest plot{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(study) hetstats}{p_end}
{phang2}{cmd:. midas sforest, plottype(generic)}{p_end}

{pstd}With prediction intervals{p_end}
{phang2}{cmd:. midas sforest, plottype(generic) predinterval ovline}{p_end}

{pstd}Rainforest style{p_end}
{phang2}{cmd:. midas sforest, plottype(rain)}{p_end}

{pstd}After Bayesian estimation{p_end}
{phang2}{cmd:. midas mh tp fp fn tn, id(study) covariance(cholesky) chains(4)}{p_end}
{phang2}{cmd:. midas sforest, plottype(generic) predinterval}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:midas sforest} does not store additional results beyond those from the
prior estimation command.  It reads from {cmd:e(bsum)}, {cmd:e(Vsum)},
{cmd:e(varlist)}, and {cmd:e(cmd)} to construct the plot.


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}
{p_end}
