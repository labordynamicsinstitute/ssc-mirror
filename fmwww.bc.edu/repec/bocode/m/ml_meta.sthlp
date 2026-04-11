{smcl}
{* *! version 1.0.0  metaLong for Stata 14.1}{...}
{vieweralsosee "metalong"     "help metalong"}{...}
{vieweralsosee "ml_sens"      "help ml_sens"}{...}
{vieweralsosee "ml_benchmark" "help ml_benchmark"}{...}
{vieweralsosee "ml_spline"    "help ml_spline"}{...}
{vieweralsosee "ml_fragility" "help ml_fragility"}{...}
{vieweralsosee "ml_plot"      "help metalong_plot"}{...}
{hline}
{title:ml_meta — Longitudinal Meta-Analysis with Robust Variance Estimation}

{title:Syntax}

{p 8 17 2}
{cmd:ml_meta} {it:yi vi} [{it:if}] [{it:in}] {cmd:,}
{cmdab:stu:dy(}{varname}{cmd:)}
{cmdab:ti:me(}{varname}{cmd:)}
[{it:options}]

{title:Description}

{pstd}
{cmd:ml_meta} fits a random-effects meta-analytic model at each unique time point
in a long-format dataset. The pooled estimate uses DerSimonian-Laird tau2 and
inverse-variance random-effects weights. Standard errors are cluster-robust
(Huber-White sandwich), clustered by study.

{title:Options}

{phang}{cmd:study(}{varname}{cmd:)} — Study (cluster) identifier variable. Required.

{phang}{cmd:time(}{varname}{cmd:)} — Numeric follow-up time variable. Required.

{phang}{cmd:alpha(}{real}{cmd:)} — Significance level for CIs and p-values. Default 0.05.

{phang}{cmd:mink(}{int}{cmd:)} — Minimum number of studies required to fit a model
at a given time point. Default 2.

{phang}{cmd:nosmallsample} — Use z-based (Wald) inference instead of t(k-1).
By default, the t(k-1) distribution is used as a small-sample correction.

{phang}{cmd:saving(}{filename}{cmd:)} — Save results dataset to {it:filename}.

{phang}{cmd:replace} — Allow overwriting an existing {cmd:saving()} file.

{title:Returned values (r-class)}

{pstd}The following are stored in {cmd:r()}:

{phang}{cmd:r(meta)} — Matrix with one row per time point.
Columns: {it:time k theta se df t_stat p_val ci_lb ci_ub tau2}.

{phang}{cmd:r(alpha)} — Significance level used.

{phang}{cmd:r(n_times)} — Number of time points.

{title:Saved dataset variables}

{synoptset 18 tabbed}{...}
{synopt:{opt time}}Follow-up time{p_end}
{synopt:{opt k}}Number of studies{p_end}
{synopt:{opt theta}}Pooled effect (RE){p_end}
{synopt:{opt se}}Cluster-robust standard error{p_end}
{synopt:{opt df}}Degrees of freedom{p_end}
{synopt:{opt t_stat}}t-statistic{p_end}
{synopt:{opt p_val}}Two-sided p-value{p_end}
{synopt:{opt ci_lb}}Lower confidence bound{p_end}
{synopt:{opt ci_ub}}Upper confidence bound{p_end}
{synopt:{opt tau2}}DL between-study variance{p_end}
{synopt:{opt sig}}1 if significant at alpha{p_end}

{title:Statistical method}

{pstd}
At each time point t:

{pstd}(1) Fixed-effects weights: wi = 1/vi.

{pstd}(2) Q statistic: Q = sum(wi*(yi - theta_FE)^2).

{pstd}(3) DL tau2: max(0, (Q - (k-1)) / c) where c = sum(wi) - sum(wi^2)/sum(wi).

{pstd}(4) RE weights: wi_RE = 1/(vi + tau2).

{pstd}(5) Pooled estimate: intercept from
{cmd:regress yi [aw=wi_RE] if t==tt, vce(cluster study)}.

{pstd}(6) Inference: t(k-1) distribution (small-sample default).

{title:Example}

{phang2}{cmd:. sim_longmeta, k(20) times(0 6 12 24) seed(42) clear}

{phang2}{cmd:. ml_meta yi vi, study(study) time(time) saving(meta_res) replace}

{phang2}{cmd:. use meta_res, clear}

{phang2}{cmd:. list}

{title:References}

{phang}Hedges, L.V., Tipton, E., & Johnson, M.C. (2010).
{it:Research Synthesis Methods}, 1(1), 39-65.

{phang}Tipton, E. (2015). {it:Psychological Methods}, 20(3), 375-393.

{hline}
