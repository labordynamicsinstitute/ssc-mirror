{smcl}
{* ml_benchmark.sthlp — metaLong for Stata 14.1}{...}
{vieweralsosee "metalong" "help metalong"}{...}
{vieweralsosee "ml_sens"  "help ml_sens"}{...}
{hline}
{title:ml_benchmark — Benchmark Calibration of ITCV Against Observed Covariates}

{title:Syntax}

{p 8 17 2}
{cmd:ml_benchmark} {it:yi vi} [{it:if}] [{it:in}] {cmd:,}
{cmdab:stu:dy(}{varname}{cmd:)}
{cmdab:ti:me(}{varname}{cmd:)}
{cmd:metafile(}{it:filename}{cmd:)}
{cmd:sensfile(}{it:filename}{cmd:)}
{cmdab:cov:ariates(}{varlist}{cmd:)}
[{it:options}]

{title:Description}

{pstd}
For each covariate Z and time t: centres Z, fits weighted meta-regression
yi ~ 1 + Z_centred with cluster-robust SE, extracts partial correlation
r_partial = t / sqrt(t^2 + df), and compares to the ITCV_adj(t) threshold.
If |r_partial| >= ITCV_adj(t), an unobserved confounder of that strength
would suffice to nullify the effect — calibrating the fragility threshold.

{title:Options}

{phang}{cmd:covariates(}{varlist}{cmd:)} — One or more numeric study-level moderators.

{phang}{cmd:mink(}{int}{cmd:)} — Minimum studies per time point. Default 3 (one more
than ml_meta, since regression needs additional degrees of freedom).

{phang}{cmd:nosmallsample} — Z-based inference instead of t(k-2).

{phang}{cmd:saving()} / {cmd:replace} — Save results dataset.

{title:Saved dataset variables}

{phang}{it:time, covariate, k, r_partial, t_stat, df, p_val, itcv_alpha, beats}

{hline}
