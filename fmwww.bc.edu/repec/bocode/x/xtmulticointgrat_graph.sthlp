{smcl}
{* *! version 1.0.0  22may2026}{...}
{cmd:help xtmulticointgrat_graph}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:xtmulticointgrat_graph} {hline 2} publication-quality diagnostic graphs
after {helpb xtmulticointgrat}.

{title:Syntax}

{p 8 14 2}
{cmd:xtmulticointgrat_graph} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt lay:out(name)}}{bf:default}, {bf:factors}, {bf:residuals},
{bf:stage}, {bf:adf}, {bf:compact}{p_end}
{synopt :{opt save(filename)}}export the combined graph to a file{p_end}
{synopt :{opt name(name)}}name of the produced combined graph{p_end}
{synopt :{opt sch:eme(name)}}graph scheme (default {bf:s1color}){p_end}
{synopt :{opt ti:tle(string)}}override default title{p_end}
{synopt :{opt sub:title(string)}}override default subtitle{p_end}
{synopt :{opt note(string)}}override default note{p_end}
{synopt :{opt ycolor(color)}}primary line color (default navy){p_end}
{synopt :{opt xcolor(color)}}secondary line color (default maroon){p_end}
{synopt :{opt hea:tcolors(list)}}colors for the loadings heatmap{p_end}
{synopt :{opt scale(#)}}global text-size multiplier{p_end}
{synoptline}

{title:Layouts}

{phang}{bf:default}{p_end}
{pmore}
2x3 dashboard combining estimated common factors, factor-loadings heatmap,
idiosyncratic and stage-2 residual spaghetti plots, cumulated stage-1 residual
spaghetti, and the histogram of per-i ADF t-statistics with the 5% reference
line.  Designed for inclusion in OBES / JBES / JAE-style figures.

{phang}{bf:factors}{p_end}
{pmore}
Common factor time-paths + loadings heatmap (uses {helpb heatplot} if
installed; otherwise falls back to a mean-|loading| bar chart).

{phang}{bf:residuals}{p_end}
{pmore}
Spaghetti plot of the idiosyncratic component e_i,t (above) and the stage-2
multicoint residual u_i,t (below).

{phang}{bf:stage}{p_end}
{pmore}
Spaghetti plot of the stage-1 cumulated residual S_i,t per panel.

{phang}{bf:adf}{p_end}
{pmore}
Histogram + dot plot of per-i ADF t-statistics with the asymptotic 5%
critical value overlaid.  This is the default after {cmd:approach(indep)}.

{phang}{bf:compact}{p_end}
{pmore}
Two-row figure for slide presentations: factors on top, idiosyncratic
spaghetti below.

{title:Examples}

{p 8 16 2}{stata "xtmulticointgrat sales prod, factors"}{p_end}
{p 8 16 2}{stata "xtmulticointgrat_graph"}{p_end}
{p 8 16 2}{stata "xtmulticointgrat_graph, layout(factors) save(figA.png)"}{p_end}
{p 8 16 2}{stata "xtmulticointgrat_graph, layout(residuals) scheme(stcolor)"}{p_end}

{title:Author}

{phang}
{bf:Dr Merwan Roudane}{p_end}
{phang}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{phang}
{bf:xtmulticointgrat_graph} v1.0.0 - 22 May 2026.

{title:Also see}

{psee}Online:  {helpb xtmulticointgrat}, {helpb heatplot}{p_end}
