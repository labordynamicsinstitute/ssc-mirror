{smcl}
{* *! version 2.1.0  30mar2026}{...}
{vieweralsosee "[R] midas" "help midas"}{...}
{vieweralsosee "[R] midas rgsroc" "help midas_rgsroc"}{...}
{viewerjumpto "Syntax" "midas_bvsroc##syntax"}{...}
{viewerjumpto "Description" "midas_bvsroc##description"}{...}
{viewerjumpto "Options" "midas_bvsroc##options"}{...}
{viewerjumpto "Area analysis" "midas_bvsroc##area"}{...}
{viewerjumpto "Stored results" "midas_bvsroc##results"}{...}
{viewerjumpto "Examples" "midas_bvsroc##examples"}{...}
{viewerjumpto "References" "midas_bvsroc##references"}{...}
{viewerjumpto "Author" "midas_bvsroc##author"}{...}

{title:Title}

{phang}
{bf:midas bvsroc} {hline 2} Bivariate summary ROC plot with confidence and prediction regions


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:midas bvsroc}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Regions}
{synopt:{opt cel:lipse}}confidence ellipse (line only){p_end}
{synopt:{opt pel:lipse}}prediction ellipse (line only){p_end}
{synopt:{opt cre:gion}}confidence region (shaded area){p_end}
{synopt:{opt pre:gion}}prediction region (shaded area){p_end}

{syntab:Display}
{synopt:{opt me:an}}display summary operating point with Se/Sp values{p_end}
{synopt:{opt da:ta}}overlay individual study points{p_end}
{synopt:{opt la:beldata}}label study points with IDs{p_end}
{synopt:{opt w:eighted}}size study points by bivariate weight{p_end}
{synopt:{opt lg:nd}}show legend{p_end}
{synopt:{opt lgnp:os(#)}}legend position; default is 6{p_end}

{syntab:Analysis}
{synopt:{opt ar:ea}}compute and display region area indices{p_end}

{syntab:Appearance}
{synopt:{opt level(#)}}confidence level; default is 95{p_end}
{synopt:{opt conf:color(color)}}confidence region colour{p_end}
{synopt:{opt pred:color(color)}}prediction region colour{p_end}
{synopt:{opt summ:color(color)}}summary point colour{p_end}
{synopt:{opt pointo:pts(string)}}marker options for study points{p_end}
{synopt:{opt summo:pts(string)}}marker options for summary diamond{p_end}
{synoptline}

{pstd}
{cmd:midas bvsroc} is a post-estimation command.  Run {cmd:midas mle},
{cmd:midas mh}, {cmd:midas hmc}, or {cmd:midas inla} first.

{pstd}
{opt pregion} and {opt pellipse} are mutually exclusive.
{opt cregion} and {opt cellipse} are mutually exclusive.


{marker description}{...}
{title:Description}

{pstd}
{cmd:midas bvsroc} plots the bivariate summary ROC curve in
sensitivity-by-specificity space.  It displays the summary operating
point (pooled Se and Sp) together with confidence and prediction
regions derived from the bivariate normal model on the logit scale,
back-transformed to probability space.

{pstd}
The {bf:confidence region} reflects uncertainty in the {it:pooled estimate}
(analogous to a confidence interval).  The {bf:prediction region} reflects
between-study heterogeneity and shows where a {it:new study's} Se-Sp pair
is expected to fall.


{marker options}{...}
{title:Options}

{phang}
{opt cellipse} / {opt cregion} displays the confidence region as a line
or shaded area.

{phang}
{opt pellipse} / {opt pregion} displays the prediction region as a line
or shaded area.

{phang}
{opt mean} displays the summary operating point with numeric Se and Sp
values and credible/confidence intervals.

{phang}
{opt data} overlays individual study-specific (Se, Sp) points.

{phang}
{opt weighted} sizes study points proportional to their bivariate weight
from {cmd:e(studywgts)}.

{phang}
{opt area} computes and displays five heterogeneity indices based on the
prediction and confidence region areas.  See {help midas_bvsroc##area:Area analysis}
below for details.


{marker area}{...}
{title:Area analysis}

{pstd}
When {opt area} is specified, {cmd:midas bvsroc} computes the area of the
prediction and confidence regions using the Shoelace (Surveyor's) formula
via the {cmd:polyarea} helper, then derives five heterogeneity indices:

{p2colset 5 38 40 2}{...}
{p2col:{bf:Index}}{bf:Description}{p_end}
{p2line}
{p2col:{bf:Overlap Coefficient}}ACR / APR.  Ranges (0, 1].  Value of 1 means
identical regions (no excess heterogeneity); smaller values indicate greater
heterogeneity.{p_end}
{p2col:{bf:Heterogeneity Area Index}}APR - ACR.  Absolute excess area in the
Se x Sp unit square attributable to between-study variability.{p_end}
{p2col:{bf:Log Area Ratio (LAR)}}ln(APR / ACR).  Unbounded, log-scale symmetric.
Value of 0 means no excess heterogeneity; exp(LAR) gives the multiplicative
factor by which the prediction region exceeds the confidence region.  This is
the recommended primary index.{p_end}
{p2col:{bf:Standardized Area Difference}}Cohen's {it:d} analog computed on the
square-root-area scale: 2(sqrt(APR) - sqrt(ACR)) / (sqrt(APR) + sqrt(ACR)).
Treats sqrt(area) as an effective "radius" for standardized comparison.{p_end}
{p2col:{bf:Area Ratio}}(APR - ACR) / APR.  Legacy index, retained for backward
compatibility.  Ranges [0, 1).{p_end}
{p2line}

{pstd}
{bf:Interpretation thresholds} (based on LAR):

{phang2}LAR < 1.5 {hline 2} {bf:LOW} heterogeneity.  Prediction region
is less than 4.5x larger than confidence region.  Summary point is reliable.{p_end}
{phang2}1.5 {ul:<} LAR < 2.5 {hline 2} {bf:MODERATE} heterogeneity.  Consider
subgroup analysis or meta-regression.{p_end}
{phang2}LAR {ul:>} 2.5 {hline 2} {bf:HIGH} heterogeneity.  Prediction region
is more than 12x larger.  Summary point may not represent individual
settings.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:midas bvsroc} stores the following in {cmd:r()}:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:r(summ_sens)}}pooled sensitivity{p_end}
{synopt:{cmd:r(summ_spec)}}pooled specificity{p_end}
{synopt:{cmd:r(summ_sens_lb)}}sensitivity lower bound{p_end}
{synopt:{cmd:r(summ_sens_ub)}}sensitivity upper bound{p_end}
{synopt:{cmd:r(summ_spec_lb)}}specificity lower bound{p_end}
{synopt:{cmd:r(summ_spec_ub)}}specificity upper bound{p_end}

{pstd}
When {opt area} is specified:

{synopt:{cmd:r(pred_area)}}prediction region area (APR){p_end}
{synopt:{cmd:r(conf_area)}}confidence region area (ACR){p_end}
{synopt:{cmd:r(overlap_coef)}}overlap coefficient (ACR/APR){p_end}
{synopt:{cmd:r(het_area_index)}}heterogeneity area index (APR-ACR){p_end}
{synopt:{cmd:r(log_area_ratio)}}log area ratio ln(APR/ACR){p_end}
{synopt:{cmd:r(std_area_diff)}}standardized area difference{p_end}
{synopt:{cmd:r(area_ratio)}}legacy area ratio (APR-ACR)/APR{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Basic bivariate SROC with ellipses{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. midas bvsroc, cellipse pellipse data mean}{p_end}

{pstd}With weighted points and region areas{p_end}
{phang2}{cmd:. midas bvsroc, cellipse pellipse data mean weighted area}{p_end}

{pstd}Shaded regions with legend{p_end}
{phang2}{cmd:. midas bvsroc, cregion pregion data mean lgnd}{p_end}

{pstd}Custom colours{p_end}
{phang2}{cmd:. midas bvsroc, cregion pregion mean confcolor(navy%40) predcolor(orange%30)}{p_end}

{pstd}Retrieve area indices after estimation{p_end}
{phang2}{cmd:. midas bvsroc, cellipse pellipse mean area}{p_end}
{phang2}{cmd:. display "LAR = " r(log_area_ratio)}{p_end}
{phang2}{cmd:. display "Prediction " exp(r(log_area_ratio)) "x larger than confidence"}{p_end}


{marker references}{...}
{title:References}

{phang}
Reitsma JB, Glas AS, Rutjes AWS, Scholten RJPM, Bossuyt PM, Zwinderman AH.
2005. Bivariate analysis of sensitivity and specificity produces informative
summary measures in diagnostic reviews.
{it:Journal of Clinical Epidemiology} 58: 982-990.

{phang}
Harbord RM, Deeks JJ, Egger M, Whiting P, Sterne JAC. 2007.
A unification of models for meta-analysis of diagnostic test accuracy
studies. {it:Biostatistics} 8: 239-251.


{marker author}{...}
{title:Author}

{pstd}
Ben Adarkwa Dwamena, MD{break}
University of Michigan / BennyBeauBooks{break}
{browse "mailto:ben@bennybeaubooks.com":ben@bennybeaubooks.com}
{p_end}
