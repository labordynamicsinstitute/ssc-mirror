{smcl}
{* *! ml_sens.sthlp — metaLong for Stata 14.1}{...}
{vieweralsosee "metalong"  "help metalong"}{...}
{vieweralsosee "ml_meta"   "help ml_meta"}{...}
{hline}
{title:ml_sens — Time-Varying Sensitivity Analysis via Longitudinal ITCV}

{title:Syntax}

{p 8 17 2}
{cmd:ml_sens} {it:yi vi} [{it:if}] [{it:in}] {cmd:,}
{cmdab:stu:dy(}{varname}{cmd:)}
{cmdab:ti:me(}{varname}{cmd:)}
{cmd:metafile(}{it:filename}{cmd:)}
[{cmd:alpha(}{real}{cmd:)} {cmd:delta(}{real}{cmd:)} {cmd:saving(}{filename}{cmd:)} {cmd:replace}]

{title:Description}

{pstd}
{cmd:ml_sens} computes the Impact Threshold for a Confounding Variable (ITCV) at
each follow-up time point. Two versions: raw ITCV (to nullify the estimate) and
significance-adjusted ITCV_adj (to render the estimate non-significant). A time
point is "fragile" if ITCV_adj < delta.

{title:Required options}

{phang}{cmd:study(}{varname}{cmd:)}, {cmd:time(}{varname}{cmd:)} — As in {helpb ml_meta}.

{phang}{cmd:metafile(}{filename}{cmd:)} — Path to dataset saved by {helpb ml_meta}.

{title:Options}

{phang}{cmd:alpha(}{real}{cmd:)} — Significance level. Default 0.05.

{phang}{cmd:delta(}{real}{cmd:)} — Fragility threshold. Time points with
ITCV_adj < delta are flagged as fragile. Default 0.15.

{phang}{cmd:saving(}{filename}{cmd:)} / {cmd:replace} — Save results.

{title:Returned values}

{phang}{cmd:r(sens)} — Matrix: {it:time theta se df sy r_effect itcv itcv_alpha fragile}.

{phang}{cmd:r(itcv_min)}, {cmd:r(itcv_mean)}, {cmd:r(frag_prop)}.

{title:Formulas}

{pstd}
sy2 = sum(wi*(yi - theta)^2) / sum(wi)  [weighted variance of effects]

{pstd}
r = theta / sqrt(theta^2 + sy2)  [correlation-scale effect]

{pstd}
ITCV = sqrt(|r|)

{pstd}
theta* = |theta| - crit*se;  if theta* > 0: ITCV_adj = sqrt(|r*|), else 0.

{title:Reference}

{phang}Frank, K.A. (2000). {it:Sociological Methods & Research}, 29(2), 147-194.

{hline}
