{smcl}
{* *! factsheetplot 0.1.0 24aug2026}{...}
{vieweralsosee "graph display" "help graph_display"}{...}
{vieweralsosee "graph export" "help graph_export"}{...}

{title:Title}

{phang}
{bf:factsheetplot} {hline 2} Apply standardized factsheet style to a Stata
graph

{title:Syntax}

{p 8 17 2}
{cmd:factsheetplot}
[{cmd:using} {it:filename}]
[{cmd:,} {opt graph(name)} {opt set} {opt width(#)} {opt replace}]

{title:Description}

{pstd}
{cmd:factsheetplot} redraws the current Stata graph using the factsheet scheme
and an 8-by-5 aspect ratio. If {cmd:using} is specified, the redrawn graph is
exported to {it:filename}.

{pstd}
The command standardizes the graph background, type treatment, axes, default
plot colors, dimensions, and export resolution. It does not change the data,
estimates, labels, reference lines, or other substantive content used to
create the graph.

{pstd}
Researchers may retain meaningful visual distinctions by specifying options
such as {cmd:lcolor()}, {cmd:lpattern()}, and {cmd:mcolor()} in the original
graph command. Explicit graph options take precedence over the factsheet
scheme.

{title:Options}

{phang}
{opt graph(name)} redraws and exports the named graph instead of the current
graph.

{phang}
{opt set} makes the factsheet scheme the default for graphs subsequently
created in the current Stata session. This setting is not permanent. When
{opt set} is used by itself, it does not require an open graph.

{phang}
{opt width(#)} sets the exported image width in pixels. The default is
{cmd:width(1600)}.

{phang}
{opt replace} permits {cmd:graph export} to overwrite an existing file.

{title:Examples}

{pstd}Convert and export the current graph:{p_end}
{phang2}{cmd:. synth outcome predictors, trunit(1) trperiod(20) fig}{p_end}
{phang2}{cmd:. factsheetplot using "figures/scm_outcome.png", replace}{p_end}

{pstd}Activate the style before running a graph producing command:{p_end}
{phang2}{cmd:. factsheetplot, set}{p_end}
{phang2}{cmd:. twoway (line observed date) (line comparison date)}{p_end}
{phang2}{cmd:. factsheetplot using "figures/outcome.png", replace}{p_end}

{pstd}Retain meaningful colors selected in the original graph command:{p_end}
{phang2}{cmd:. factsheetplot, set}{p_end}
{phang2}{cmd:. local higher "67 57 107"}{p_end}
{phang2}{cmd:. local lower  "27 177 190"}{p_end}
{phang2}{cmd:. twoway (line higher_gap date, lcolor("`higher'")) (line lower_gap date, lcolor("`lower'"))}{p_end}
{phang2}{cmd:. factsheetplot using "figures/price_groups.png", replace}{p_end}

{pstd}Convert a named graph:{p_end}
{phang2}{cmd:. factsheetplot using "figures/outcome.png", graph(results) replace}{p_end}

{title:Remarks}

{pstd}
Post-hoc conversion works best when the original graph relies on scheme
defaults. If a graph producing command hard codes colors, fonts, regions, or
legend positions, run {cmd:factsheetplot, set} before that command and remove
unnecessary explicit style options where practical.

{pstd}
The built-in figure produced by {cmd:synth} is one example: {cmd:synth}
explicitly draws both series in black. {cmd:factsheetplot} standardizes the
surrounding graph but preserves those hard coded line colors. To use another
palette, save the {cmd:synth} output and recreate the graph with {cmd:twoway}.

{pstd}
{cmd:factsheetplot} cannot infer the substantive meaning of individual plot
elements. If an automatic graph command does not expose options for styling
individual series, use the standard palette or recreate the graph from the
command's saved output.

{title:Author}

{pstd}
Samuel Sturm{break}
Support: {browse "mailto:ssturm@jhu.edu":ssturm@jhu.edu}

{title:License}

{pstd}
MIT License. See the bundled {cmd:factsheetplot.license} file.{p_end}
