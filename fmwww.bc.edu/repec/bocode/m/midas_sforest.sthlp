{smcl}
{* *! midas_sforest.sthlp  v1.0.0  Ben Adarkwa Dwamena  2026}{...}
{vieweralsosee "midas_mle"    "help midas_mle"}{...}
{vieweralsosee "midas_qrsim"  "help midas_qrsim"}{...}
{vieweralsosee "midas_mh"     "help midas_mh"}{...}
{vieweralsosee "midas_hmc"    "help midas_hmc"}{...}
{vieweralsosee "midas_inla"   "help midas_inla"}{...}
{vieweralsosee "midas_eforest" "help midas_eforest"}{...}
{vieweralsosee "midas_het"    "help midas_het"}{...}
{viewerjumpto "Syntax"       "midas_sforest##syntax"}{...}
{viewerjumpto "Description"  "midas_sforest##description"}{...}
{viewerjumpto "Options"      "midas_sforest##options"}{...}
{viewerjumpto "Plot types"   "midas_sforest##plottypes"}{...}
{viewerjumpto "Examples"     "midas_sforest##examples"}{...}
{viewerjumpto "References"   "midas_sforest##references"}{...}
{viewerjumpto "Author"       "midas_sforest##author"}{...}
{hline}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:midas_sforest} {hline 2}}Summary forest plot with pooled diamond
for meta-analytical integration of diagnostic accuracy studies{p_end}
{p2colreset}{...}
{hline}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas_sforest}
[{it:if}] [{it:in}]{cmd:,}
{opt plot:type(string)}
[{opt lev:el(#)}
{opt ms:cale(#)}
{opt texts:cale(#)}
{opt combs:cale(#)}
{opt pred:interval}
{opt ovl:ine}
{opt cim:ethod(string)}
{opt cic:olor(colorspec)}
{opt diam:color(colorspec)}
{opt title(passthru)}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt plot:type(string)}}plot style; one of {bf:generic},
    {bf:ellipse}, {bf:thick}, or {bf:rain}{p_end}
{synoptline}
{syntab:Options}
{synopt:{opt lev:el(#)}}confidence level for interval bars; default
    {bf:95}{p_end}
{synopt:{opt ms:cale(#)}}marker size scale factor; default {bf:0.75};
    passed as {cmd:ms()} to the internal {cmd:sforest} program{p_end}
{synopt:{opt texts:cale(#)}}text size scale factor; default {bf:1.0};
    passed as {cmd:text()} to the internal {cmd:sforest} program{p_end}
{synopt:{opt combs:cale(#)}}panel content scale for {cmd:graph combine}
    via {cmd:iscale()}; default {bf:0.5}; smaller values shrink markers
    and text within each combined panel{p_end}
{synopt:{opt pred:interval}}overlay the 95% prediction interval derived
    from between-study heterogeneity{p_end}
{synopt:{opt ovl:ine}}draw a vertical reference line at the pooled
    summary estimate{p_end}
{synopt:{opt cim:ethod(string)}}confidence interval computation method;
    {bf:exact} (default), {bf:wilson}, or {bf:wald}{p_end}
{synopt:{opt cic:olor(colorspec)}}colour for confidence interval bars;
    any Stata colorspec{p_end}
{synopt:{opt diam:color(colorspec)}}colour for the pooled summary diamond;
    any Stata colorspec{p_end}
{synopt:{opt title(passthru)}}graph title passed through to the plot{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas_sforest} is a post-estimation command in the MIDAS suite.
It produces a coupled summary forest plot — one panel for sensitivity
and one for specificity — in which each study contributes a point
estimate with confidence interval, and the pooled summary is rendered
as a filled diamond at the foot of each panel.

{pstd}
{cmd:midas_sforest} must be called after one of the five MIDAS
estimation commands:
{helpb midas_mle}, {helpb midas_qrsim}, {helpb midas_mh},
{helpb midas_hmc}, or {helpb midas_inla}.
It reads pooled estimates and study-level random effects from {cmd:e()}.

{pstd}
The command requires the {cmd:xsvmat} package.  If not installed, Stata
will prompt you to install it from SSC:
{stata ssc install xsvmat, replace}.

{pstd}
For a pre-estimation exploratory forest plot without a summary diamond,
see {helpb midas_eforest}.  For per-study heterogeneity decomposition,
see {helpb midas_het}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt plottype(string)} specifies the visual style of the forest plot.
Must be one of {bf:generic}, {bf:ellipse}, {bf:thick}, or {bf:rain}.
See {help midas_sforest##plottypes:Plot types} for descriptions.

{dlgtab:Display}

{phang}
{opt level(#)} sets the confidence level.  Default is {bf:95} for 95%
confidence intervals.  Must be an integer between 10 and 99.

{phang}
{opt mscale(#)} scales all markers proportionally.  Default is {bf:0.75}.
Increase for larger markers; reduce for dense plots with many studies.

{phang}
{opt textscale(#)} scales all text elements in the plot proportionally.
Default is {bf:1.0}.

{phang}
{opt combscale(#)} sets the {cmd:iscale()} argument passed to
{cmd:graph combine}.  This controls the proportional size of text and
markers within each panel of the combined two-panel plot.  Default is
{bf:0.5}.  Smaller values produce more compact panels.

{phang}
{opt predinterval} adds a 95% prediction interval to each panel,
representing the range of true sensitivity or specificity expected in a
new study given the estimated between-study heterogeneity.  This option
is particularly informative when heterogeneity is high.

{phang}
{opt ovline} adds a vertical reference line at the pooled summary value
in each panel.

{phang}
{opt cimethod(string)} specifies the method for computing per-study
confidence intervals for the forest plot bars.  Options are {bf:exact}
(Clopper-Pearson; default), {bf:wilson}, and {bf:wald}.

{phang}
{opt cicolor(colorspec)} sets the colour of the confidence interval
bars.  Accepts any valid Stata colour specification, including RGB
triplets such as {bf:"51 105 173"}.

{phang}
{opt diamcolor(colorspec)} sets the colour of the pooled summary
diamond.  Accepts any valid Stata colour specification.


{marker plottypes}{...}
{title:Plot types}

{pstd}
The {opt plottype()} option selects from four visual styles:

{phang2}{bf:generic} — standard horizontal dot-and-bar forest plot.
Each study is a filled circle with a horizontal confidence bar.
This is the default style and is appropriate for most publications.

{phang2}{bf:ellipse} — study weights are encoded as filled ellipses
whose width is proportional to the study's precision weight.
Useful for emphasising the influence of large studies.

{phang2}{bf:thick} — confidence bars are rendered as thick filled
rectangles rather than thin lines, giving a more visually prominent
display of the uncertainty range.

{phang2}{bf:rain} — a raincloud-style plot combining dot estimates
with a half-density representation of the distribution of study
estimates.  Particularly useful for visualising the spread of
heterogeneous results.


{marker examples}{...}
{title:Examples}

{pstd}
{ul:Basic usage after MLE — generic plot}

{phang2}{cmd:. use fdgpet_axillary, clear}{p_end}
{phang2}{cmd:. midas_mle tp fp fn tn, id(author) year(year)}{p_end}
{phang2}{cmd:. midas sforest, plottype(generic)}{p_end}

{pstd}
{ul:Ellipse plot with prediction interval}

{phang2}{cmd:. midas sforest, plottype(ellipse) predinterval}{p_end}

{pstd}
{ul:Rain plot with 90% CI and overall reference line}

{phang2}{cmd:. midas sforest, plottype(rain) level(90) ovline}{p_end}

{pstd}
{ul:Custom colours and compact panels}

{phang2}{cmd:. midas sforest, plottype(generic) cicolor("100 150 200") diamcolor("200 80 50") combscale(0.4)}{p_end}

{pstd}
{ul:After HMC estimation}

{phang2}{cmd:. midas hmc tp fp fn tn, id(author) modelfile("model.stan") chains(4) iter(2000)}{p_end}
{phang2}{cmd:. midas sforest, plottype(thick) predinterval ovline}{p_end}


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
Higgins, J. P. T., Thompson, S. G., Deeks, J. J., and Altman, D. G.
(2003).
Measuring inconsistency in meta-analyses.
{it:BMJ} 327: 557{c -}560.

{phang}
Riley, R. D., Higgins, J. P. T., and Deeks, J. J. (2011).
Interpretation of random effects meta-analyses.
{it:BMJ} 342: d549.


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
{it:Also see}: {helpb midas_mle}, {helpb midas_qrsim}, {helpb midas_mh},
{helpb midas_hmc}, {helpb midas_inla}, {helpb midas_eforest},
{helpb midas_het}
{p_end}
{hline}
