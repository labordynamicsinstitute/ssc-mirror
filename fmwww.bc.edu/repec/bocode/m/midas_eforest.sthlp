{smcl}
{* *! midas_eforest.sthlp  v1.0.0  Ben Adarkwa Dwamena  2026}{...}
{vieweralsosee "midas_sforest"  "help midas_sforest"}{...}
{vieweralsosee "midas_mle"      "help midas_mle"}{...}
{vieweralsosee "midas_qrsim"    "help midas_qrsim"}{...}
{vieweralsosee "midas_mh"       "help midas_mh"}{...}
{vieweralsosee "midas_hmc"      "help midas_hmc"}{...}
{vieweralsosee "midas_inla"     "help midas_inla"}{...}
{vieweralsosee "midas_het"      "help midas_het"}{...}
{vieweralsosee "midas_assess"   "help midas_assess"}{...}
{viewerjumpto "Syntax"       "midas_eforest##syntax"}{...}
{viewerjumpto "Description"  "midas_eforest##description"}{...}
{viewerjumpto "Options"      "midas_eforest##options"}{...}
{viewerjumpto "Plot types"   "midas_eforest##plottypes"}{...}
{viewerjumpto "Examples"     "midas_eforest##examples"}{...}
{viewerjumpto "References"   "midas_eforest##references"}{...}
{viewerjumpto "Author"       "midas_eforest##author"}{...}
{hline}
{title:Title}

{p2colset 5 25 27 2}{...}
{p2col:{bf:midas_eforest} {hline 2}}Exploratory coupled forest plot
(no summary diamond) for meta-analytical integration of diagnostic
accuracy studies{p_end}
{p2colreset}{...}
{hline}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas_eforest}
{it:tp} {it:fp} {it:fn} {it:tn}
[{it:if}] [{it:in}]{cmd:,}
{opt plot:type(string)}
[{opt id(varlist)}
{opt lev:el(#)}
{opt ms:cale(#)}
{opt texts:cale(#)}
{opt combs:cale(#)}
{opt cim:ethod(string)}
{opt cic:olor(colorspec)}
{opt diam:color(colorspec)}
{opt title(passthru)}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{it:tp fp fn tn}}numeric variables containing counts of true
    positives, false positives, false negatives, and true negatives{p_end}
{synopt:{opt plot:type(string)}}plot style; one of {bf:generic},
    {bf:ellipse}, {bf:thick}, or {bf:rain}{p_end}
{synoptline}
{syntab:Options}
{synopt:{opt id(varlist)}}one or two variables whose values are
    concatenated to form the study label displayed on the y-axis;
    if omitted, observation numbers are used{p_end}
{synopt:{opt lev:el(#)}}confidence level for interval bars; default
    {bf:95}{p_end}
{synopt:{opt ms:cale(#)}}marker size scale factor; default {bf:0.75}{p_end}
{synopt:{opt texts:cale(#)}}text size scale factor; default {bf:1.0}{p_end}
{synopt:{opt combs:cale(#)}}panel content scale for {cmd:graph combine}
    via {cmd:iscale()}; default {bf:0.5}; smaller values shrink markers
    and text within each combined panel{p_end}
{synopt:{opt cim:ethod(string)}}confidence interval computation method;
    {bf:exact} (default), {bf:wilson}, or {bf:wald}{p_end}
{synopt:{opt cic:olor(colorspec)}}colour for confidence interval bars;
    any Stata colorspec{p_end}
{synopt:{opt diam:color(colorspec)}}colour for the study point estimates;
    any Stata colorspec{p_end}
{synopt:{opt title(passthru)}}graph title passed through to the plot{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas_eforest} produces an exploratory coupled forest plot of
raw study-level sensitivity and specificity estimates with confidence
intervals.  The two panels — one for sensitivity, one for specificity —
are displayed side by side on a shared y-axis so that the paired
estimates for each study are directly readable across panels.

{pstd}
Unlike {helpb midas_sforest}, {cmd:midas_eforest} does {it:not} require
a prior estimation command.  It operates directly on the {it:tp fp fn tn}
variables in memory and does not read from {cmd:e()}.  It is therefore
equally useful as a pre-estimation exploratory display or as a
complement to a fitted model.

{pstd}
No summary diamond is shown.  The purpose of {cmd:midas_eforest} is to
display the raw data structure — the distribution, spread, and any
shoulder pattern of sensitivity and specificity across studies — before
or alongside formal bivariate meta-analysis.

{pstd}
The command requires the {cmd:xsvmat} package.  If not installed:
{stata ssc install xsvmat, replace}.

{pstd}
For a post-estimation plot with a pooled summary diamond, see
{helpb midas_sforest}.  For per-study heterogeneity decomposition,
see {helpb midas_het}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{it:tp fp fn tn} are the four numeric variables containing the 2{c 215}2
table cell counts.  All four must be specified in this order.

{phang}
{opt plottype(string)} specifies the visual style.
Must be one of {bf:generic}, {bf:ellipse}, {bf:thick}, or {bf:rain}.
See {help midas_eforest##plottypes:Plot types} for descriptions.

{dlgtab:Study labels}

{phang}
{opt id(varlist)} specifies one or two variables whose string or numeric
values are concatenated (space-separated) to form the study label on
the y-axis.  If two variables are specified — commonly author and year —
their values are joined as {it:author year}.  If {opt id()} is omitted,
observation numbers label the y-axis.

{dlgtab:Display}

{phang}
{opt level(#)} sets the confidence level for the per-study bars.
Default is {bf:95}.  Must be between 10 and 99.

{phang}
{opt mscale(#)} scales all markers proportionally.  Default is {bf:0.75}.

{phang}
{opt textscale(#)} scales all text elements.  Default is {bf:1.0}.

{phang}
{opt combscale(#)} sets the {cmd:iscale()} argument passed to
{cmd:graph combine}, controlling text and marker size within each
combined panel.  Default is {bf:0.5}.

{phang}
{opt cimethod(string)} specifies the per-study confidence interval
method: {bf:exact} (Clopper-Pearson; default), {bf:wilson}, or
{bf:wald}.

{phang}
{opt cicolor(colorspec)} sets the colour of confidence interval bars.

{phang}
{opt diamcolor(colorspec)} sets the colour of study point estimate
markers.


{marker plottypes}{...}
{title:Plot types}

{pstd}
The {opt plottype()} option selects from four visual styles:

{phang2}{bf:generic} — standard horizontal dot-and-bar forest plot.
The default and most widely used style.

{phang2}{bf:ellipse} — study precision is encoded as the width of a
filled ellipse around the point estimate.  Helps identify influential
studies visually.

{phang2}{bf:thick} — confidence bars are drawn as filled rectangles,
making uncertainty ranges visually prominent.  Useful for small
meta-analyses where individual study variability is of primary interest.

{phang2}{bf:rain} — a raincloud-style display combining individual
study dots with a half-density curve showing the distribution of
estimates across studies.  Particularly effective for illustrating
the heterogeneity structure before fitting a model.


{marker examples}{...}
{title:Examples}

{pstd}
{ul:Pre-estimation exploratory display}

{phang2}{cmd:. use fdgpet_axillary, clear}{p_end}
{phang2}{cmd:. midas eforest tp fp fn tn, id(author year) plottype(generic)}{p_end}

{pstd}
{ul:Ellipse plot highlighting study precision}

{phang2}{cmd:. midas eforest tp fp fn tn, id(author) plottype(ellipse)}{p_end}

{pstd}
{ul:Rain plot with 90% CI}

{phang2}{cmd:. midas eforest tp fp fn tn, id(author year) plottype(rain) level(90)}{p_end}

{pstd}
{ul:Custom colours and compact panels}

{phang2}{cmd:. midas eforest tp fp fn tn, id(author) plottype(generic) cicolor("100 150 200") combscale(0.4)}{p_end}

{pstd}
{ul:Side-by-side with summary forest plot}

{phang2}{cmd:. midas eforest tp fp fn tn, id(author year) plottype(generic)}{p_end}
{phang2}{cmd:. midas_mle tp fp fn tn, id(author) year(year)}{p_end}
{phang2}{cmd:. midas sforest, plottype(generic) predinterval}{p_end}


{marker references}{...}
{title:References}

{phang}
Dwamena, B. A. (2009).
{it:MIDAS: Meta-analytical Integration of Diagnostic Accuracy Studies}.
Statistical Software Components, Boston College Department of Economics.
{browse "https://ideas.repec.org/c/boc/bocode/s456880.html"}

{phang}
Reitsma, J. B., Glas, A. S., Rutjes, A. W. S., Scholten, R. J. P. M.,
Bossuyt, P. M., and Zwinderman, A. H. (2005).
Bivariate analysis of sensitivity and specificity produces informative
summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58(10): 982{c -}990.

{phang}
Harbord, R. M., and Whiting, P. (2009).
metandi: Meta-analysis of diagnostic accuracy using hierarchical
logistic regression.
{it:Stata Journal} 9(2): 211{c -}229.


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
Clinical Associate Professor Emeritus of Radiology{break}
(Nuclear Medicine and Molecular Imaging){break}
University of Michigan{break}
East Lansing, Michigan, USA{break}
{browse "mailto:bdwamena@umich.edu":bdwamena@umich.edu}

{pstd}
Please report bugs and suggestions via the MIDAS SSC page or by email.

{pstd}
{it:Also see}: {helpb midas_sforest}, {helpb midas_mle},
{helpb midas_qrsim}, {helpb midas_mh}, {helpb midas_hmc},
{helpb midas_inla}, {helpb midas_het}, {helpb midas_assess}
{p_end}
{hline}
