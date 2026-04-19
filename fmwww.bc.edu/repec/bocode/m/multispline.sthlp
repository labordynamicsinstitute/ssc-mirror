{smcl}
{* version 0.2.0  Subir Hait  Michigan State University  2026-04-18}{...}
{cmd:help multispline}{right:MultiSpline v0.2.0}
{hline}

{title:Title}

{phang}
{bf:multispline} {hline 2} Spline-Based Nonlinear Modeling for Multilevel
and Longitudinal Data

{title:Syntax}

{p 8 17 2}
{cmd:multispline} {depvar} {indepvar} [{it:controls}] {ifin} {cmd:,}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Clustering}
{synopt:{opt cl:uster(varlist)}}up to 2 grouping variables; higher level
  first for nested models{p_end}
{synopt:{opt nested}}nested random effects {cmd:(higher/lower)} instead
  of cross-classified{p_end}

{syntab:Spline specification}
{synopt:{opt df(# | auto)}}degrees of freedom; {cmd:auto} selects by AIC
  or BIC; default {cmd:auto}{p_end}
{synopt:{opt df_r:ange(string)}}candidate df values for auto selection;
  default {cmd:"2 3 4 5 6"}{p_end}
{synopt:{opt cr:iterion(aic|bic)}}information criterion; default {cmd:aic}{p_end}
{synopt:{opt me:thod(ns|bs)}}spline basis: natural cubic ({cmd:ns},
  default) or B-spline ({cmd:bs}){p_end}
{synopt:{opt bs_d:egree(#)}}B-spline polynomial degree; default {cmd:3}{p_end}
{synopt:{opt fa:mily(gaussian|logit|probit)}}outcome family; default
  {cmd:gaussian}; use {cmd:logit} or {cmd:probit} for binary outcomes{p_end}

{syntab:Diagnostics}
{synopt:{opt comp:are}}compare spline against linear and polynomial
  models (AIC, BIC, LRT){p_end}
{synopt:{opt poly_d:egrees(string)}}polynomial degrees for comparison;
  default {cmd:"2 3"}{p_end}
{synopt:{opt r2}}Nakagawa-Schielzeth marginal and conditional R-squared
  with level-specific variance partition{p_end}
{synopt:{opt icc}}intraclass correlation coefficients with interpretation{p_end}
{synopt:{opt het}}cluster heterogeneity: BLUP plot and LRT (random
  slopes vs intercepts){p_end}
{synopt:{opt nhet(#)}}number of clusters to show in het plot;
  default {cmd:30}{p_end}

{syntab:Random effects}
{synopt:{opt rands:lope}}allow spline trajectory to vary across
  clusters (random spline slopes){p_end}

{syntab:Post-estimation}
{synopt:{opt pr:edict_grid(#)}}prediction grid points; default {cmd:100}{p_end}
{synopt:{opt le:vel(#)}}confidence level; default {cmd:95}{p_end}
{synopt:{opt der:ivatives}}first and second derivatives with CI bands{p_end}
{synopt:{opt tu:rning_points}}local maxima, minima, and slope regions{p_end}
{synopt:{opt pl:ot(type)}}inline plot: {cmd:trajectory}, {cmd:slope},
  {cmd:curvature}, or {cmd:combo}{p_end}
{synopt:{opt sa:ving(filename)}}save prediction dataset for
  {cmd:multispline_plot}{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:multispline} fits nonlinear regression models using natural cubic
splines or B-splines, with optional multilevel random effects via
{cmd:mixed} (Gaussian) or {cmd:melogit}/{cmd:meprobit} (binary). It
provides a complete workflow from fitting through model comparison,
R-squared decomposition, derivative-based interpretation, cluster
heterogeneity diagnostics, and publication-ready plots.

{pstd}
All functionality is self-contained in a single {cmd:.ado} file requiring
only base Stata ({cmd:regress}, {cmd:mixed}, {cmd:melogit},
{cmd:meprobit}, {cmd:mkspline}).

{title:Model types}

{pstd}
The model fitted depends on the options supplied:

{p2colset 6 26 28 2}{...}
{p2col:{bf:OLS}}No {cmd:cluster()}, {cmd:family(gaussian)}
   -  single-level linear regression with spline terms{p_end}
{p2col:{bf:LMM}}With {cmd:cluster()}, {cmd:family(gaussian)}
   -  mixed-effects regression via {cmd:mixed}{p_end}
{p2col:{bf:LMM-nested}}{cmd:cluster(g1 g2) nested}
   -  {cmd:mixed ... || g1: || g2:}{p_end}
{p2col:{bf:LMM-cross}}{cmd:cluster(g1 g2)} without {cmd:nested}
   -  cross-classified via {cmd:|| _all: R.g1 || g2:}{p_end}
{p2col:{bf:LMM-rslope}}{cmd:randslope}
   -  spline basis enters as random slopes{p_end}
{p2col:{bf:Logit/{bf:Probit}}}{cmd:family(logit|probit)}, no {cmd:cluster()}
   -  single-level binary regression{p_end}
{p2col:{bf:GLMM-Logit}}{cmd:family(logit)} with {cmd:cluster()}
   -  multilevel logistic via {cmd:melogit}{p_end}

{title:Derivatives and turning points}

{pstd}
The {cmd:derivatives} option computes numerical first (d1) and second
(d2) derivatives of the predicted spline curve across the x-grid,
with delta-method confidence intervals. d1 represents the marginal
effect of x at each point. d2 represents curvature. Note: d2 CIs may
be wide due to numerical differentiation  -  treat them cautiously.

{pstd}
{cmd:turning_points} detects where d1 changes sign (local maxima or
minima) and identifies contiguous slope-direction regions.

{title:R-squared decomposition}

{pstd}
For LMM models, {cmd:r2} reports Nakagawa-Schielzeth (2013) marginal
R-squared (R2m, variance from fixed effects only) and conditional
R-squared (R2c, fixed plus random effects), following the formula
extended by Nakagawa, Johnson and Schielzeth (2017).

{pstd}
For GLMM (logit), the denominator includes the distribution-specific
variance (pi^2/3 for logit, 1 for probit) following the Nakagawa
et al. (2017) extension.

{title:Cluster heterogeneity (het)}

{pstd}
The {cmd:het} option: (1) fits a random-slope model and performs an LRT
comparing random slopes vs random intercepts to test whether the
nonlinear trajectory shape varies across clusters; (2) plots
cluster-specific BLUP-based trajectories against the population mean
for visual inspection. Only available for single-cluster Gaussian LMMs.

{title:Examples}

{pstd}{ul:OLS with automatic df and trajectory plot}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. multispline price mpg, df(auto) compare plot(trajectory)}{p_end}

{pstd}{ul:OLS with derivatives and turning points}{p_end}
{phang2}{cmd:. multispline price mpg, df(auto) derivatives turning_points plot(combo)}{p_end}

{pstd}{ul:Single-cluster LMM with R-squared and ICC}{p_end}
{phang2}{cmd:. multispline score age female ses,}{p_end}
{phang2}{cmd:    cluster(student_id) df(auto) r2 icc compare plot(trajectory)}{p_end}

{pstd}{ul:Nested multilevel (higher-level cluster first)}{p_end}
{phang2}{cmd:. multispline score age female ses,}{p_end}
{phang2}{cmd:    cluster(school_id student_id) nested}{p_end}
{phang2}{cmd:    df(auto) r2 icc compare derivatives turning_points plot(combo)}{p_end}

{pstd}{ul:Cross-classified multilevel}{p_end}
{phang2}{cmd:. multispline score age female ses,}{p_end}
{phang2}{cmd:    cluster(school_id neighbourhood_id)}{p_end}
{phang2}{cmd:    df(4) r2 icc plot(trajectory)}{p_end}

{pstd}{ul:Random spline slopes}{p_end}
{phang2}{cmd:. multispline score age, cluster(student_id) df(3) randslope r2}{p_end}

{pstd}{ul:Cluster heterogeneity diagnostics}{p_end}
{phang2}{cmd:. multispline score age female ses,}{p_end}
{phang2}{cmd:    cluster(student_id) df(3) het nhet(25)}{p_end}

{pstd}{ul:Binary outcome - single level logit}{p_end}
{phang2}{cmd:. multispline pass age female ses,}{p_end}
{phang2}{cmd:    family(logit) df(auto) compare plot(trajectory)}{p_end}

{pstd}{ul:Binary outcome - multilevel GLMM logit}{p_end}
{phang2}{cmd:. multispline pass age female ses,}{p_end}
{phang2}{cmd:    cluster(student_id) family(logit) df(3) r2 plot(trajectory)}{p_end}

{pstd}{ul:B-spline basis}{p_end}
{phang2}{cmd:. multispline score age, cluster(student_id) method(bs) df(4) plot(trajectory)}{p_end}

{pstd}{ul:Save predictions for separate plotting}{p_end}
{phang2}{cmd:. multispline score age, cluster(student_id) df(auto) derivatives saving(pred)}{p_end}
{phang2}{cmd:. multispline_plot, using(pred) type(trajectory) xvar(age)}{p_end}
{phang2}{cmd:. multispline_plot, using(pred) type(combo)      xvar(age)}{p_end}

{title:Stored results}

{pstd}
{cmd:multispline} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{synopt:{cmd:e(cmd)}}       {cmd:multispline}{p_end}
{synopt:{cmd:e(yvar)}}      outcome variable name{p_end}
{synopt:{cmd:e(xvar)}}      focal predictor name{p_end}
{synopt:{cmd:e(method)}}    spline method (ns or bs){p_end}
{synopt:{cmd:e(model_type)}}OLS, LMM, LMM-nested, LMM-cross, LMM-rslope,
  Logit, GLMM-Logit, etc.{p_end}
{synopt:{cmd:e(df)}}        degrees of freedom selected{p_end}
{synopt:{cmd:e(aic)}}       AIC of fitted model{p_end}
{synopt:{cmd:e(bic)}}       BIC of fitted model{p_end}

{title:References}

{pstd}
Nakagawa, S. and Schielzeth, H. (2013).
A general and simple method for obtaining R-squared from generalized
linear mixed-effects models.
{it:Methods in Ecology and Evolution}, 4(2), 133-142.

{pstd}
Nakagawa, S., Johnson, P.C.D. and Schielzeth, H. (2017).
The coefficient of determination R-squared from generalized linear
mixed-effects models revisited and expanded.
{it:Journal of the Royal Society Interface}, 14(134), 20170213.

{pstd}
Rights, J.D. and Sterba, S.K. (2019).
Quantifying explained variance in multilevel models.
{it:Psychological Methods}, 24(3), 309-338.

{title:Author}

{pstd}
Subir Hait, Michigan State University{break}
haitsubi@msu.edu{break}
ORCID: 0009-0004-9871-9677{break}
https://github.com/causalfragility-lab/MultiSpline-Stata

{title:Also see}

{psee}
{helpb multispline_plot} for post-estimation plots from saved datasets{p_end}
{psee}
{helpb mixed}, {helpb melogit}, {helpb meprobit}, {helpb regress},
{helpb mkspline}{p_end}
