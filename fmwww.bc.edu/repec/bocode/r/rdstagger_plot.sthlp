{smcl}
{* *! version 1.0.0 Subir Hait 2026}{...}
{viewerjumpto "Syntax"      "rdstagger_plot##syntax"}{...}
{viewerjumpto "Description" "rdstagger_plot##description"}{...}
{viewerjumpto "Options"     "rdstagger_plot##options"}{...}
{viewerjumpto "Examples"    "rdstagger_plot##examples"}{...}

{title:Title}

{p 4 18 2}
{bf:rdstagger_plot} {hline 2} Coefficient plot for aggregated staggered RD estimates
{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:rdstagger_plot} [{cmd:,}
{opt title(string)}
{opt name(string)}
{opt saving(filename[, replace])}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt title(string)}}graph title; a default is set based on aggregation type{p_end}
{synopt:{opt name(string)}}graph name in memory; default {cmd:rdstagger_plot}{p_end}
{synopt:{opt saving(filename[, replace])}}save graph to disk{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rdstagger_plot} produces a coefficient plot of the aggregated ATT
estimates stored by {helpb rdstagger_agg}. It must be run after both
{helpb rdstagger} and {helpb rdstagger_agg}.

{pstd}
Point estimates are shown as circles with capped spikes for 95%
confidence intervals. For event-study ({cmd:dynamic}) aggregation:
pre-treatment estimates are shown in cranberry (dark red) and
post-treatment estimates in navy. A dotted vertical line marks
event time {hline 1}0.5 (the last pre-treatment period). A dashed
horizontal line marks zero.

{pstd}
For group or calendar aggregation, all estimates are shown in navy.

{marker options}{...}
{title:Options}

{phang}
{opt title(string)} overrides the default graph title.

{phang}
{opt name(string)} assigns a name to the graph in Stata's graph memory
so it can be retrieved with {cmd:graph display}. Default: {cmd:rdstagger_plot}.

{phang}
{opt saving(filename[, replace])} saves the graph to {it:filename}{cmd:.gph}.
Include the {cmd:replace} suboption to overwrite an existing file.

{marker examples}{...}
{title:Examples}

{pstd}Full workflow:{p_end}
{phang2}{cmd:. rdstagger_sim, n(400) periods(8) cohorts(3) seed(42)}{p_end}
{phang2}{cmd:. rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)}{p_end}
{phang2}{cmd:. rdstagger_agg, type(dynamic)}{p_end}
{phang2}{cmd:. rdstagger_plot}{p_end}

{pstd}Save to file:{p_end}
{phang2}{cmd:. rdstagger_plot, title("Event study") saving(eventstudy, replace)}{p_end}

{pstd}Group-level plot:{p_end}
{phang2}{cmd:. rdstagger_agg, type(group)}{p_end}
{phang2}{cmd:. rdstagger_plot, title("ATT by cohort")}{p_end}

{title:Also see}

{psee}
{helpb rdstagger}, {helpb rdstagger_agg}, {helpb rdstagger_pretest}
{p_end}
