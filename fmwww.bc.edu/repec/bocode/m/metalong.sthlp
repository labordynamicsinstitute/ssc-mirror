{smcl}
{* *! version 1.0.0  metaLong for Stata 14.1}{...}
{vieweralsosee "ml_meta"        "help ml_meta"}{...}
{vieweralsosee "ml_sens"        "help ml_sens"}{...}
{vieweralsosee "ml_benchmark"   "help ml_benchmark"}{...}
{vieweralsosee "ml_spline"      "help ml_spline"}{...}
{vieweralsosee "ml_fragility"   "help ml_fragility"}{...}
{vieweralsosee "metalong_plot"  "help metalong_plot"}{...}
{vieweralsosee "sim_longmeta"   "help sim_longmeta"}{...}
{hline}
{title:metaLong for Stata 14.1}

{pstd}
{hi:metaLong} provides a workflow for synthesising evidence from studies that
report outcomes at multiple follow-up time points (longitudinal meta-analysis).

{title:Core commands}

{phang}
{helpb ml_meta} {hline 2} Pool effects at each time point using
DerSimonian-Laird tau2 and cluster-robust variance estimation.{p_end}

{phang}
{helpb ml_sens} {hline 2} Compute time-varying Impact Threshold for a
Confounding Variable (ITCV), raw and significance-adjusted forms.{p_end}

{phang}
{helpb ml_benchmark} {hline 2} Compare each covariate partial correlation
against the ITCV_adj threshold.{p_end}

{phang}
{helpb ml_spline} {hline 2} Fit a restricted cubic spline meta-regression
over follow-up time with pointwise confidence bands.{p_end}

{phang}
{helpb ml_fragility} {hline 2} Leave-one-out and leave-k-out fragility
indices across the trajectory.{p_end}

{phang}
{helpb metalong_plot} {hline 2} Combined publication-ready trajectory,
sensitivity, and fragility figures.{p_end}

{phang}
{helpb sim_longmeta} {hline 2} Simulate a longitudinal meta-analytic
dataset.{p_end}

{title:Typical workflow}

{phang2}{cmd:. sim_longmeta, k(20) times(0 6 12 24) seed(42) clear}{p_end}

{phang2}{cmd:. ml_meta yi vi, study(study) time(time) saving(meta_res) replace}{p_end}

{phang2}{cmd:. ml_sens yi vi, study(study) time(time) ///}{p_end}
{phang3}{cmd:    metafile(meta_res) saving(sens_res) replace}{p_end}

{phang2}{cmd:. ml_benchmark yi vi, study(study) time(time) ///}{p_end}
{phang3}{cmd:    metafile(meta_res) sensfile(sens_res) ///}{p_end}
{phang3}{cmd:    covariates(pub_year quality n) saving(bench_res) replace}{p_end}

{phang2}{cmd:. ml_fragility yi vi, study(study) time(time) ///}{p_end}
{phang3}{cmd:    metafile(meta_res) saving(frag_res) replace}{p_end}

{phang2}{cmd:. ml_spline, metafile(meta_res) df(3) saving(spline_res) replace}{p_end}

{phang2}{cmd:. metalong_plot, metafile(meta_res) sensfile(sens_res) ///}{p_end}
{phang3}{cmd:    splinefile(spline_res) fragfile(frag_res) ///}{p_end}
{phang3}{cmd:    saving(figure.gph) replace}{p_end}

{title:Statistical methods}

{pstd}
{bf:Pooling.} {cmd:ml_meta} fits an intercept-only weighted regression at
each time point using DerSimonian-Laird (DL) between-study variance tau2 and
inverse-variance random-effects weights 1/(vi + tau2). Standard errors are
cluster-robust (clustered by study), analogous to Hedges, Tipton & Johnson
(2010) RVE. With the default small-sample correction, inference uses a
t(k-1) distribution.

{pstd}
{bf:ITCV Sensitivity.} At each time t, {cmd:ml_sens} computes:{p_end}
{phang2}r_t = theta_t / sqrt(theta_t^2 + sy2_t){p_end}
{phang2}ITCV_t = sqrt(|r_t|){p_end}
{phang2}ITCV_adj(t) = sqrt(|r*_t|), where r*_t uses theta* = |theta_t| - crit*se_t{p_end}
{pstd}
A time point is "fragile" if ITCV_adj(t) < delta (default 0.15).

{pstd}
{bf:Benchmark.} For each covariate Z and time t, {cmd:ml_benchmark} fits a
WLS meta-regression and computes the partial correlation
r_partial = t / sqrt(t^2 + df), compared against ITCV_adj(t).

{title:Note on CR2 / Satterthwaite correction}

{pstd}
Stata 14.1 does not natively implement CR2 sandwich estimation with
Satterthwaite degrees of freedom (Tipton 2015). {hi:metaLong} uses CR1
cluster-robust SEs with t(k-1) degrees of freedom as the best available
small-sample approximation.

{title:References}

{phang}
Frank, K. A. (2000). Impact of a confounding variable on a regression
coefficient. {it:Sociological Methods & Research}, 29(2), 147-194.{p_end}

{phang}
Hedges, L. V., Tipton, E., & Johnson, M. C. (2010). Robust variance
estimation in meta-regression with dependent effect size estimates.
{it:Research Synthesis Methods}, 1(1), 39-65.{p_end}

{phang}
Tipton, E. (2015). Small sample adjustments for robust variance estimation
with meta-regression. {it:Psychological Methods}, 20(3), 375-393.{p_end}

{title:Author}

{pstd}
Subir Hait, Michigan State University{break}
Email: haitsubi@msu.edu{break}
ORCID: 0009-0004-9871-9677{break}
Stata translation of the R package {it:metaLong} v0.1.0.

{hline}
