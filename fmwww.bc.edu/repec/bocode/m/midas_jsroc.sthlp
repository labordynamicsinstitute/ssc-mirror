{smcl}
{* *! version 3.1  14aug2026}{...}
{cmd:help midas_jsroc}
{hline}

{title:Title}

{phang}
{bf:midas_jsroc} {hline 2} Joint summary ROC curve with confidence and
prediction regions/ellipses (MIDAS suite post-estimation)


{title:Syntax}

{p 8 16 2}
{cmd:midas_jsroc} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:SROC curve}
{synopt:{opt sc:urve}}draw the summary ROC curve; assumed if no other plot element is requested{p_end}
{synopt:{opt curvecolor(colorstyle)}}line color for the SROC curve; default black{p_end}
{synopt:{opt curveopts(line_options)}}override line options for the SROC curve entirely{p_end}
{synopt:{opt noextrap:olate}}draw the curve only within the range of observed specificities{p_end}

{syntab:Regions and ellipses}
{synopt:{opt cr:egion}}shaded joint confidence region about the summary point{p_end}
{synopt:{opt ce:llipse}}confidence ellipse (outline only); may not be combined with {cmd:cregion}{p_end}
{synopt:{opt pr:egion}}shaded joint prediction region for a future study{p_end}
{synopt:{opt pe:llipse}}prediction ellipse (outline only); may not be combined with {cmd:pregion}{p_end}
{synopt:{opt confcolor(colorstyle)}}fill/line color for the confidence region; default blue{p_end}
{synopt:{opt predcolor(colorstyle)}}fill/line color for the prediction region; default green{p_end}
{synopt:{opt l:evel(#)}}confidence level for regions and intervals; default {cmd:level(95)}{p_end}

{syntab:Data and summary point}
{synopt:{opt d:ata}}overlay observed study-level (sensitivity, specificity) pairs{p_end}
{synopt:{opt w:eighted}}size observed points by study weights from {cmd:e(studywgts)}{p_end}
{synopt:{opt label:data}}label observed points with study numbers{p_end}
{synopt:{opt me:an}}display summary operating point and results table{p_end}
{synopt:{opt summcolor(colorstyle)}}marker color for the summary point; default black{p_end}
{synopt:{opt pointopts(marker_options)}}override marker options for observed data{p_end}
{synopt:{opt summopts(marker_options)}}override marker options for the summary point{p_end}

{syntab:Legend and other}
{synopt:{opt lg:nd}}display legend; default is {cmd:legend(off)}{p_end}
{synopt:{opt lgnp:os(#)}}legend clock position; default {cmd:lgnpos(6)}{p_end}
{synopt:{opt area}}compute region areas and heterogeneity indices{p_end}
{synopt:{it:twoway_options}}other options passed to {helpb twoway}{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:midas_jsroc} is a post-estimation command of the MIDAS suite.  It must
be run after one of the midas estimation subcommands ({cmd:midas mle},
{cmd:qrsim}, {cmd:mh}, {cmd:hmc}, or {cmd:inla}); all model-based
quantities are recovered from the stored {cmd:e()} results and the 2x2
counts in {cmd:e(varlist)}.  Nothing is refit.

{pstd}
Every plot element is opt-in: the Rutter-Gatsonis-equivalent summary ROC
curve ({cmd:scurve}), the joint {cmd:level()}% confidence region or
ellipse about the summary operating point, the joint prediction region or
ellipse for a future study, the observed study estimates (optionally
weighted and labeled), and the summary operating point.  If no element is
requested, the SROC curve is drawn by default so that the command never
produces an empty plot.  When the curve is drawn, the area under the
curve is reported (trapezoidal integration over the full curve, with a
Wilson-type confidence interval).  With {cmd:noextrapolate}, the plotted
curve is clipped to the range of observed specificities; the AUC is still
computed over the full curve.

{pstd}
With {cmd:area}, the areas of the prediction and confidence regions are
computed by polygon integration, and heterogeneity indices (overlap
coefficient, heterogeneity area index, log area ratio, and standardized
area difference) are reported with a traffic-light interpretation.


{title:Examples}

{phang}{cmd:. midas mle tp fp fn tn}{p_end}
{phang}{cmd:. midas_jsroc, scurve data mean lgnd}{p_end}

{pstd}Curve clipped to the observed data, custom color:{p_end}

{phang}{cmd:. midas_jsroc, scurve noextrapolate curvecolor(maroon) data mean lgnd}{p_end}

{pstd}Shaded regions with areas and heterogeneity assessment:{p_end}

{phang}{cmd:. midas_jsroc, scurve cregion pregion data weighted mean lgnd area}{p_end}

{pstd}Ellipse outlines only, custom colors and legend position:{p_end}

{phang}{cmd:. midas_jsroc, cellipse pellipse confcolor(navy) predcolor(dkgreen) mean lgnd lgnpos(7)}{p_end}


{title:Stored results}

{pstd}
{cmd:midas_jsroc} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:r(AUC)}}area under the SROC curve{p_end}
{synopt:{cmd:r(AUClo)}, {cmd:r(AUChi)}}confidence limits for AUC{p_end}
{synopt:{cmd:r(beta)}, {cmd:r(alpha)}}HSROC shape and accuracy parameters{p_end}
{synopt:{cmd:r(summ_sens)}, {cmd:r(summ_spec)}}summary sensitivity and specificity (with {cmd:mean}){p_end}
{synopt:{cmd:r(summ_sens_lb)}, {cmd:r(summ_sens_ub)}}limits for summary sensitivity{p_end}
{synopt:{cmd:r(summ_spec_lb)}, {cmd:r(summ_spec_ub)}}limits for summary specificity{p_end}
{synopt:{cmd:r(pred_area)}, {cmd:r(conf_area)}}region areas (with {cmd:area}){p_end}
{synopt:{cmd:r(area_ratio)}, {cmd:r(overlap_coef)}}area ratio and overlap coefficient{p_end}
{synopt:{cmd:r(het_area_index)}, {cmd:r(log_area_ratio)}}heterogeneity area index and log area ratio{p_end}
{synopt:{cmd:r(std_area_diff)}}standardized area difference{p_end}


{title:Author}

{pstd}
Ben A. Dwamena, MD{break}
Division of Nuclear Medicine and Molecular Imaging, Department of Radiology{break}
University of Michigan, Ann Arbor{break}
bdwamena@umich.edu


{title:Also see}

{psee}
Online: {helpb midas}, {helpb midas_bvsroc}, {helpb integ}
{p_end}
