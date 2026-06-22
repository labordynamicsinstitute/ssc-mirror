{smcl}
{* *! version 1.0.0  20jun2026  Dr Merwan Roudane}{...}
{vieweralsosee "xtpqcce" "help xtpqcce"}{...}
{viewerjumpto "Postestimation" "xtpqcce_postestimation##post"}{...}
{viewerjumpto "Graphs" "xtpqcce_postestimation##graph"}{...}
{viewerjumpto "Examples" "xtpqcce_postestimation##ex"}{...}
{title:Title}

{phang}
{bf:xtpqcce postestimation} {hline 2} Postestimation tools for {helpb xtpqcce}


{marker post}{...}
{title:Postestimation}

{pstd}
After {cmd:xtpqcce} the headline coefficients are posted in {cmd:e(b)}/{cmd:e(V)}
with one equation per quantile (equation name {cmd:q}{it:XX}, where {it:XX}=100*tau).
Standard postestimation commands therefore work, for example{p_end}

{phang2}{cmd:. test [q90]x1 = [q10]x1}{space 6}(equal effect in the two tails?){p_end}
{phang2}{cmd:. lincom [q50]x1 - [q50]x2}{p_end}
{phang2}{cmd:. xtpqcce}{space 22}(replay the last results){p_end}

{pstd}Richer detail is kept in dedicated matrices: {cmd:e(mg)} (mean-group
estimates), {cmd:e(SE)}, {cmd:e(V_mg)}, {cmd:e(b_i)} (per-unit estimates, one row
per panel, useful for studying heterogeneity), and for {bf:qmg} also
{cmd:e(lr_mg)}, {cmd:e(lr_SE)} and {cmd:e(hl_mg)} (long-run effects and
half-lives). With {bf:csqr bc} the bias-corrected mean group is {cmd:e(bc_mg)}.{p_end}


{marker graph}{...}
{title:Graphs}

{pstd}
{cmd:xtpqcce_graph} redraws the quantile-process figure (one panel per regressor:
the mean-group / bias-corrected coefficient across the quantiles, with a shaded
pointwise confidence band and a zero reference line).{p_end}

{p 8 17 2}{cmd:xtpqcce_graph} [{cmd:,}
{opt coef(main|long)}
{opt level(#)}
{opt titles(string)}
{opt name(string)}
{opt export(filename)}
{it:combine_options}]

{phang}{opt coef(main)} (default) plots the headline coefficient (bias-corrected
for {bf:csqr bc}); {opt coef(long)} plots the long-run effect ({bf:qmg} only).{p_end}

{phang}{opt level(#)} sets the band's confidence level (default e(level)).{p_end}

{phang}{opt titles(string)} supplies per-panel titles; {opt export()} saves the
figure; {opt name()} names the combined graph.{p_end}


{marker ex}{...}
{title:Examples}

{phang2}{cmd:. xtpqcce y x1 x2, csqr quantiles(0.1(0.1)0.9) bc}{p_end}
{phang2}{cmd:. xtpqcce_graph, export(fig1.png)}{p_end}
{phang2}{cmd:. xtpqcce y x1 x2, qmg quantiles(0.1 0.5 0.9) lrun}{p_end}
{phang2}{cmd:. xtpqcce_graph, coef(long)}{p_end}


{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
