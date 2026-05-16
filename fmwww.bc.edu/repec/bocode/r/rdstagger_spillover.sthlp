{smcl}
{* *! rdstagger_spillover v1.0.0 Subir Hait 2026}{...}
{title:Title}

{phang}{bf:rdstagger_spillover} {hline 2} Decompose staggered RD ATT(g,t) into direct and spillover effects

{title:Syntax}

{p 8 16 2}
{cmd:rdstagger_spillover} [{cmd:,}
{cmdab:al:pha(}{it:#}{cmd:)}
{cmd:verbose}]

{title:Description}

{pstd}
{cmd:rdstagger_spillover} decomposes each ATT(g,t) cell estimated by {cmd:rdstagger}
into a {it:spillover} component and a {it:direct} component.

{pstd}
{bf:Identification strategy.}
Under network interference, control units close to the cutoff (x near 0) may have
elevated outcomes due to spillovers from treated units.  This contaminates the
control group and causes {cmd:rdstagger} to underestimate the direct treatment effect.

{pstd}
Spillover ATT(g,t) is identified by a DiD between two groups of never-treated units:

{phang2}o {it:Near controls}: x in [-bw, 0) — exposed to spillovers{p_end}
{phang2}o {it:Far controls}: x in [-2*bw, -bw) — clean comparison group{p_end}

{pstd}
The bias-corrected direct ATT(g,t) = Total ATT(g,t) + Spillover ATT(g,t).

{title:Options}

{phang}{cmd:alpha(}{it:#}{cmd:)} sets the significance level. Default: 0.05.

{phang}{cmd:verbose} displays additional diagnostic output.

{title:Stored results}

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(spillover)}}matrix with columns: cohort, period, total_att,
spill_att, direct_att, spill_se, spill_pval, direct_se, direct_pval{p_end}
{synopt:{cmd:e(bandwidth)}}bandwidth used{p_end}

{title:Remarks}

{pstd}
Must be run immediately after {cmd:rdstagger}.  Requires at least 5 observations
in each control zone per cohort-period cell.

{title:Example}

{phang}{cmd:rdstagger_sim, n(400) periods(8) cohorts(3) spill(0.1) seed(42)}{p_end}
{phang}{cmd:rdstagger y x, cutoff(0) gvar(g) tvar(period) idvar(id) bw(1.5)}{p_end}
{phang}{cmd:rdstagger_spillover}{p_end}

{title:Author}

{pstd}Subir Hait, Michigan State University

{title:Also see}

{psee}{help rdstagger}, {help rdstagger_agg}, {help rdstagger_pretest}
