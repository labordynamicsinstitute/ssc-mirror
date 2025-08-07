{smcl}
*! sumtex v5.5.3 WU Lianghai/Yang Lu (AHUT, Anhui University of Technology) 05Aug2025

{title:Title}

{p 4 4 2}{bf:sumtex} - Generate publication-ready descriptive statistics tables in LaTeX format{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:sumtex} [{varlist}] , 
{cmd:SAVing(}{it:filename}{cmd:)}
[
{cmd:STATs(}{it:stat_list}{cmd:)}
{cmd:FMT(}{it:format_string}{cmd:)}
{cmd:ROTate}
{cmd:REPlace}
{cmd:TItle(}{it:string}{cmd:)}
{cmd:THREELine}
{cmd:LANDscape}
]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt sav:ing(filename)}}output LaTeX filename (required){p_end}
{synopt:{opt stat:s(stat_list)}}list of statistics to display; default: "mean sd min max p50"{p_end}
{synopt:{opt fmt(format_string)}}numeric format; default "%9.3f"{p_end}
{syntab:Appearance}
{synopt:{opt rot:ate}}transpose table (variables in columns){p_end}
{synopt:{opt three:line}}use booktabs three-line table style{p_end}
{synopt:{opt land:scape}}force landscape page orientation{p_end}
{synopt:{opt ti:tle(string)}}table caption text{p_end}
{synopt:{opt rep:lace}}overwrite existing file{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{p 4 4 2}{cmd:sumtex} generates publication-quality descriptive statistics tables in standalone LaTeX format. 
The command automatically processes numeric variables, applies variable labels, escapes special LaTeX characters, 
and produces a complete compilable .tex document. Key features include:{p_end}

{p 6 6 2}- Automatic handling of numeric variables{p_end}
{p 6 6 2}- Sample size (N) displayed as integer{p_end}
{p 6 6 2}- LaTeX special character escaping (_, &, %, $, #, {, }, ^, ~){p_end}
{p 6 6 2}- Support for both portrait and landscape layouts{p_end}
{p 6 6 2}- Booktabs professional table format option{p_end}
{p 6 6 2}- Complete LaTeX document generation with geometry settings{p_end}

{title:Options}

{dlgtab:Main}

{phang}
{opt saving(filename)} specifies the output .tex file path. Required. Enclose paths with spaces in quotes.{p_end}

{phang}
{opt stats(stat_list)} specifies statistics to display. Available statistics:{p_end}
{p 12 16 2}- Central tendency: {it:mean, p50 (median), count (N)}{p_end}
{p 12 16 2}- Dispersion: {it:sd, min, max, var, cv, semean}{p_end}
{p 12 16 2}- Distribution: {it:skewness, kurtosis}{p_end}
{p 12 16 2}- Percentiles: {it:p1 p5 p10 p25 p75 p90 p95 p99}{p_end}
{p 12 16 2}- Other: {it:sum}{p_end}
{p 8 8 2}Default: {it:mean sd min max p50}{p_end}
{p 8 8 2}Note: {it:count} always displays as integer; {it:cv} suppressed when mean=0{p_end}

{phang}
{opt fmt(format_string)} defines numeric display format using Stata formatting codes. 
Must match pattern {it:%[width].[precision]f}. Invalid formats revert to default %9.3f.{p_end}

{dlgtab:Appearance}

{phang}
{opt rotate} transposes the table layout (variables in columns, statistics in rows).{p_end}

{phang}
{opt threeline} applies professional booktabs table style (toprule, midrule, bottomrule).{p_end}

{phang}
{opt landscape} forces landscape page orientation using pdflscape package.{p_end}

{phang}
{opt title(string)} specifies table caption text. LaTeX special characters not automatically escaped.{p_end}

{phang}
{opt replace} overwrites existing files without warning.{p_end}

{title:Technical notes}

{p 4 4 2}{ul:Variable handling}{p_end}
{p 6 6 2}- Omitting {varlist} processes all numeric variables in dataset{p_end}
{p 6 6 2}- String variables automatically excluded with notification{p_end}
{p 6 6 2}- Variable labels used when available; variable names used otherwise{p_end}

{p 4 4 2}{ul:Value formatting}{p_end}
{p 6 6 2}- Sample size (count) always formatted as integer (%12.0f){p_end}
{p 6 6 2}- Missing values display as "--"{p_end}
{p 6 6 2}- CV automatically suppressed when mean=0{p_end}

{p 4 4 2}{ul:LaTeX features}{p_end}
{p 6 6 2}- Automatically escapes special characters: _ & % $ # {{ }} ^ ~{p_end}
{p 6 6 2}- Required packages: geometry, array, multirow{p_end}
{p 6 6 2}- Conditionally loads: booktabs ({opt threeline}), pdflscape ({opt landscape}){p_end}
{p 6 6 2}- Generates complete compilable .tex document{p_end}

{title:Examples}

{p 4 4 2}Basic table:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. sumtex price mpg weight, saving("table1.tex")}{p_end}

{p 4 4 2}Custom statistics with count and percentiles:{p_end}
{phang2}{cmd:. sumtex price, saving(price_stats.tex) stats(count mean sd p25 p50 p75) replace}{p_end}

{p 4 4 2}Rotated table with landscape orientation:{p_end}
{phang2}{cmd:. sumtex price mpg, saving(table2.tex) rotate landscape title("Vehicle Characteristics")}{p_end}

{p 4 4 2}Full dataset summary with booktabs style:{p_end}
{phang2}{cmd:. sumtex, saving(full.tex) stats(count mean sd min max) threeline replace}{p_end}

{title:Authors}

{p 4 4 2}School of Business, Anhui University of Technology(AHUT){p_end}
{p 4 4 2}Wu Lianghai: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}
{p 4 4 2}Yang Lu: {browse "mailto:1026835594@qq.com":1026835594@qq.com}{p_end}

{title:Version}

{p 4 4 2}v5.5.3 (03Aug2025){p_end}

{title:Also see}

{p 4 4 2}
{help summarize}, 
{help tabstat}, 
{stata ssc describe esttab:esttab} (SSC), 
{stata ssc describe asdoc:asdoc} (SSC)
{p_end}