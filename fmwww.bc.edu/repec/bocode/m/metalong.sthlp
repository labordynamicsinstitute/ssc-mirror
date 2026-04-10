{smcl}
{* *! version 1.0.0  metaLong for Stata 14.1}{...}
{vieweralsosee "ml_meta"      "help ml_meta"}{...}
{vieweralsosee "ml_sens"      "help ml_sens"}{...}
{vieweralsosee "ml_benchmark" "help ml_benchmark"}{...}
{vieweralsosee "ml_spline"    "help ml_spline"}{...}
{vieweralsosee "ml_fragility" "help ml_fragility"}{...}
{vieweralsosee "ml_plot"      "help ml_plot"}{...}
{vieweralsosee "sim_longmeta" "help sim_longmeta"}{...}
{hline}
{title:metaLong for Stata 14.1}

{pstd}
{hi:metaLong} provides a coherent workflow for synthesising evidence from studies
that report outcomes at multiple follow-up time points (longitudinal meta-analysis).

{title:Core commands}

{phang}{helpb ml_meta} — Pool effects at each time point with DerSimonian-Laird tau2
and cluster-robust variance estimation (RVE), analogous to RVE + Tipton correction.

{phang}{helpb ml_sens} — Compute the time-varying Impact Threshold for a Confounding
Variable (ITCV): both raw and significance-adjusted forms.

{phang}{helpb ml_benchmark} — Regress each observed study-level covariate on effect sizes
and compare its partial correlation against the ITCV_adj threshold.

{phang}{helpb ml_spline} — Fit a restricted cubic spline meta-regression over follow-up
time with pointwise confidence bands.

{phang}{helpb ml_fragility} — Leave-one-out and leave-k-out fragility indices across
the trajectory.

{phang}{helpb ml_plot} — Combined publication-ready trajectory, sensitivity, and
fragility figures.

{phang}{helpb sim_longmeta} — Simulate a longitudinal meta-analytic dataset.

{title:Typical workflow}

{phang2}{cmd:. sim_longmeta, k(20) times(0 6 12 24) seed(42) saving(mydata) clear}

{phang2}{cmd:. use mydata}

{phang2}{cmd:. ml_meta yi vi, study(study) time(time) saving(meta_res) replace}

{phang2}{cmd:. ml_sens yi vi, study(study) time(time) metafile(meta_res) saving(sens_res) replace}

{phang2}{cmd:. ml_benchmark yi vi, study(study) time(time) ///}
{phang3}{cmd:    metafile(meta_res) sensfile(sens_res) ///}
{phang3}{cmd:    covariates(pub_year quality n) saving(bench_res) replace}

{phang2}{cmd:. ml_fragility yi vi, study(study) time(time) metafile(meta_res) saving(frag_res) replace}

{phang2}{cmd:. ml_spline, metafile(meta_res) df(3) saving(spline_res) replace}

{phang2}{cmd:. ml_plot, metafile(meta_res) sensfile(sens_res) splinefile(spline_res) ///}
{phang3}{cmd:    fragfile(frag_res) title("My Longitudinal MA") saving(figure.gph) replace}

{title:Statistical methods}

{pstd}
{bf:Pooling.} {cmd:ml_meta} fits an intercept-only weighted regression at each time
point using DerSimonian-Laird (DL) between-study variance tau2 and inverse-variance
random-effects weights (1/(vi + tau2)). Standard errors are cluster-robust
(clustered by study), analogous to Hedges, Tipton & Johnson (2010) RVE. With the
default {cmd:smallsample} correction, inference uses a t(k-1) distribution.

{pstd}
{bf:ITCV Sensitivity.} At each time t:
r_t = theta_t / sqrt(theta_t^2 + sy2_t),  ITCV_t = sqrt(|r_t|)
ITCV_adj(t) = sqrt(|r*_t|) where r*_t uses theta* = |theta_t| - crit * se_t.
A time point is "fragile" if ITCV_adj(t) < delta (default 0.15).

{pstd}
{bf:Benchmark.} For each covariate Z and time t, fits WLS meta-regression
yi ~ 1 + (Z - mean(Z)) with cluster-robust SE. The partial correlation
r_partial = t / sqrt(t^2 + df) is compared to the ITCV_adj(t) threshold.

{title:Note on CR2 / Satterthwaite correction}

{pstd}
Stata 14.1 does not natively implement CR2 sandwich estimation with Satterthwaite
degrees of freedom (Tipton 2015). {cmd:metaLong} uses CR1 cluster-robust SEs
(standard Stata {cmd:vce(cluster)}) with t(k-1) degrees of freedom as the best
available small-sample approximation. For the exact CR2+Satterthwaite estimator,
install the {cmd:ivreg2} and {cmd:avar} user-written packages and contact the author.

{title:References}

{phang}Frank, K. A. (2000). Impact of a confounding variable on a regression coefficient.
{it:Sociological Methods & Research}, 29(2), 147-194.

{phang}Hedges, L. V., Tipton, E., & Johnson, M. C. (2010). Robust variance estimation
in meta-regression with dependent effect size estimates.
{it:Research Synthesis Methods}, 1(1), 39-65.

{phang}Tipton, E. (2015). Small sample adjustments for robust variance estimation with
meta-regression. {it:Psychological Methods}, 20(3), 375-393.

{title:Author}

{pstd}Subir Hait, Michigan State University{break}
Email: haitsubi@msu.edu{break}
ORCID: 0009-0004-9871-9677{break}
Stata translation of the R package {it:metaLong} v0.1.0.

{hline}
