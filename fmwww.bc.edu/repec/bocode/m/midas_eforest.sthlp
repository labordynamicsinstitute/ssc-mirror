{smcl}
{* *! version 1.0.0  30mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas sforest" "help midas_sforest"}{...}
{viewerjumpto "Syntax" "midas_eforest##syntax"}{...}
{viewerjumpto "Description" "midas_eforest##description"}{...}
{viewerjumpto "Options" "midas_eforest##options"}{...}
{viewerjumpto "Examples" "midas_eforest##examples"}{...}
{viewerjumpto "Author" "midas_eforest##author"}{...}

{title:Title}

{phang}
{bf:midas eforest} {hline 2} Exploratory coupled forest plot for DTA meta-analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas eforest}
{cmd:,} {opt plott:ype(type)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt plott:ype(type)}}plot style: {bf:generic}, {bf:ellipse}, {bf:thick}, or {bf:rain}{p_end}

{syntab:Options}
{synopt:{opt level(#)}}confidence level; default is 95{p_end}
{synopt:{opt ms:cale(#)}}marker size scale; default is 0.30{p_end}
{synopt:{opt texts:cale(#)}}text size scale; default is 0.30{p_end}
{synopt:{opt cim:ethod(method)}}CI method: {bf:exact} (default), {bf:wilson}, or {bf:wald}{p_end}
{synopt:{opt cic:olor(color)}}colour for confidence intervals{p_end}
{synopt:{opt diamc:olor(color)}}colour for diamond markers{p_end}
{synoptline}

{pstd}
{cmd:midas eforest} is a post-estimation command.  It requires prior execution of
a MIDAS estimation command ({cmd:midas mle}, {cmd:midas mh}, {cmd:midas hmc},
or {cmd:midas inla}).


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas eforest} produces coupled (paired) forest plots of study-specific
sensitivity and specificity {bf:without} a pooled summary diamond.  This is
the exploratory version of the forest plot, designed for visual inspection
of study-level accuracy before interpreting pooled estimates.

{pstd}
Four plot styles are available:

{phang2}{bf:generic} {hline 2} Standard square-and-whisker plot.  Each study is a
square (proportional to weight) with a horizontal confidence interval.{p_end}

{phang2}{bf:ellipse} {hline 2} Each study's bivariate uncertainty is shown as a
confidence ellipse.  Preserves the Se-Sp correlation structure.{p_end}

{phang2}{bf:thick} {hline 2} Graduated line thickness proportional to study weight.{p_end}

{phang2}{bf:rain} {hline 2} Density-shaded raindrops reflecting study weight and
uncertainty.{p_end}

{pstd}
For the summary forest plot with pooled diamond and prediction intervals,
see {helpb midas_sforest:midas sforest}.


{marker options}{...}
{title:Options}

{phang}
{opt plottype(type)} selects the visual style.  Required.

{phang}
{opt level(#)} confidence level for study-specific intervals.  Default is 95.

{phang}
{opt mscale(#)} scales the marker size.  Default is 0.30.

{phang}
{opt textscale(#)} scales the text size.  Default is 0.30.

{phang}
{opt cimethod(method)} CI computation method: {bf:exact} (Clopper-Pearson,
default), {bf:wilson}, or {bf:wald}.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. midas mle tp fp fn tn, id(study)}{p_end}
{phang2}{cmd:. midas eforest, plottype(generic)}{p_end}

{phang2}{cmd:. midas eforest, plottype(ellipse)}{p_end}

{phang2}{cmd:. midas eforest, plottype(rain)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}
{p_end}
