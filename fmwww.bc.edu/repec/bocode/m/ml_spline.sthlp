{smcl}
{* *! ml_spline.sthlp  metaLong for Stata 14.1}{...}
{vieweralsosee "metalong"  "help metalong"}{...}
{vieweralsosee "ml_meta"   "help ml_meta"}{...}
{vieweralsosee "ml_plot"   "help metalong_plot"}{...}
{hline}
{title:ml_spline — Restricted Cubic Spline Time Trend for Longitudinal Meta-Analysis}

{title:Syntax}

{p 8 17 2}
{cmd:ml_spline} {cmd:,}
{cmd:metafile(}{it:filename}{cmd:)}
[{cmd:df(}{integer}{cmd:)}
{cmd:npred(}{integer}{cmd:)}
{cmd:alpha(}{real}{cmd:)}
{cmd:nolineartest}
{cmd:plot}
{cmd:saving(}{filename}{cmd:)}
{cmd:replace}]

{title:Description}

{pstd}
{cmd:ml_spline} fits a second-stage restricted cubic spline (RCS) meta-regression
using the pooled time-point estimates produced by {helpb ml_meta} as the outcome.
Precision weights (1/se²) reflect the reliability of each pooled estimate.
The command uses Stata's built-in {helpb mkspline} to construct the RCS basis.

{pstd}
The result is a smooth predicted trajectory with pointwise confidence bands,
suitable for overlaying on the observed pooled estimates in {helpb metalong_plot}.
An optional F-test for nonlinearity compares the spline to a simple linear fit.

{title:Options}

{phang}
{cmd:metafile(}{it:filename}{cmd:)} specifies the path to the results dataset
saved by {helpb ml_meta}. Required.

{phang}
{cmd:df(}{integer}{cmd:)} specifies the degrees of freedom for the restricted
cubic spline. Default is 3. A value of 1 recovers a linear weighted regression.
The number of internal knots equals df − 1, placed at quantiles of the observed
time distribution.

{phang}
{cmd:npred(}{integer}{cmd:)} specifies the number of equally-spaced prediction
points spanning the observed time range. Default is 100.

{phang}
{cmd:alpha(}{real}{cmd:)} sets the significance level for confidence bands.
Default is 0.05.

{phang}
{cmd:nolineartest} suppresses the nonlinearity F-test (spline vs linear).

{phang}
{cmd:plot} draws a quick preview twoway plot of the spline. For a fully
annotated combined figure use {helpb metalong_plot}.

{phang}
{cmd:saving(}{filename}{cmd:)} saves the prediction dataset to {it:filename}.dta.
This file is required by {helpb metalong_plot} when the {cmd:splinefile()} option is used.

{phang}
{cmd:replace} allows overwriting an existing {cmd:saving()} file.

{title:Saved prediction dataset columns}

{synoptset 15 tabbed}{...}
{synopt:{opt time}}Prediction grid time value{p_end}
{synopt:{opt theta_hat}}Spline predicted pooled effect{p_end}
{synopt:{opt se_hat}}Standard error of prediction{p_end}
{synopt:{opt ci_lb}}Lower confidence bound{p_end}
{synopt:{opt ci_ub}}Upper confidence bound{p_end}

{title:Returned r() values}

{synoptset 18 tabbed}{...}
{synopt:{cmd:r(r_squared)}}Weighted R² of the spline fit{p_end}
{synopt:{cmd:r(p_nonlinear)}}Nonlinearity F-test p-value; missing if df=1{p_end}
{synopt:{cmd:r(df)}}Spline degrees of freedom used{p_end}
{synopt:{cmd:r(alpha)}}Confidence level used{p_end}

{title:Statistical details}

{pstd}
The spline is fitted by weighted least squares:

{pstd}
min_β  Σ wt_t (theta_t − X_t β)²,   wt_t = 1/se_t²

{pstd}
where X_t is the RCS design matrix evaluated at time t. Knot positions are
placed at the {it:(1/(df))-th, (2/(df))-th, …, ((df−1)/df)-th} quantiles of
the observed time distribution.

{pstd}
Confidence bands use the standard error of prediction from the fitted weighted
regression model, with a t(n_obs − df − 1) critical value.

{pstd}
The nonlinearity test compares the weighted R² of the spline model to that of
a simple weighted linear regression via an F-statistic with (df − 1) and
(n_obs − df − 1) degrees of freedom.

{title:Example}

{phang2}{cmd:. sim_longmeta, k(20) times(0 6 12 18 24) seed(3) clear}

{phang2}{cmd:. ml_meta yi vi, study(study) time(time) saving(meta_res) replace}

{phang2}{cmd:. ml_spline, metafile(meta_res) df(3) npred(200) ///}
{phang3}{cmd:    saving(spline_res) replace}

{phang2}{cmd:. display r(r_squared)}

{phang2}{cmd:. display r(p_nonlinear)}

{phang2}{cmd:. ml_plot, metafile(meta_res) splinefile(spline_res) ///}
{phang3}{cmd:    title("Spline trend") saving(fig.gph) replace}

{title:See also}

{helpb ml_meta}, {helpb metalong_plot}, {helpb mkspline}, {helpb metalong}

{hline}
