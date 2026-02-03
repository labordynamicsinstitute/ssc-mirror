{smcl}
{* *! version 2.2.1  01Feb2026}{...}
{viewerjumpto "Syntax" "rddidplot##syntax"}{...}
{viewerjumpto "Description" "rddidplot##description"}{...}
{viewerjumpto "Options" "rddidplot##options"}{...}
{viewerjumpto "Examples" "rddidplot##examples"}{...}
{viewerjumpto "Author" "rddidplot##author"}{...}
{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{cmd:rddidplot} {hline 2}}Postestimation RD plots for rddid{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmd:rddidplot} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt title(string)}}Overall title for the combined graph (default: "Difference-in-Discontinuities").{p_end}
{synopt :{opt cilevel(#)}}Confidence interval level for {cmd:rdplot} (default 95). Set to 0 to suppress CIs.{p_end}
{synopt :{it:graph_combine_options}}Any other options are passed directly to {cmd:graph combine}.{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:rddidplot} is a postestimation command for {cmd:rddid}. It generates side-by-side RD plots
for the Treated and Control groups using {cmd:rdplot} from the rdrobust package.

{pstd}
The command reads the estimation sample, bandwidths, cutoff, and variable names from the
{cmd:e()} results left by {cmd:rddid}. You must run {cmd:rddid} before calling {cmd:rddidplot}.

{marker options}{...}
{title:Options}

{phang}
{opt title(string)} specifies the overall title for the combined graph. The default is
"Difference-in-Discontinuities". Individual panels are labeled "Treated" and "Control".

{phang}
{opt cilevel(#)} specifies the confidence level for the confidence intervals drawn by {cmd:rdplot}.
The default is 95. Set to 0 to suppress confidence intervals.

{phang}
{it:graph_combine_options} allow you to customize the combined graph. Any options not recognized
by {cmd:rddidplot} are passed directly to {cmd:graph combine}. For example, you can pass
{cmd:xsize(10)} or {cmd:ysize(5)} to control dimensions.

{marker examples}{...}
{title:Examples}

{phang}1. Basic plot after estimation{p_end}
{phang}{cmd:. rddid outcome score, group(treated) h(100)}{p_end}
{phang}{cmd:. rddidplot}{p_end}

{phang}2. Custom title{p_end}
{phang}{cmd:. rddidplot, title("RD Plots: Wealth Index")}{p_end}

{phang}3. Without confidence intervals{p_end}
{phang}{cmd:. rddidplot, cilevel(0)}{p_end}

{phang}4. 99% confidence intervals{p_end}
{phang}{cmd:. rddidplot, cilevel(99)}{p_end}

{marker also_see}{...}
{title:Also see}

{pstd}{help rddid:rddid} — Difference-in-Discontinuities estimation{p_end}

{marker author}{...}
{title:Author}
{pstd}Jonathan Dries{p_end}
{pstd}LUISS Guido Carli University{p_end}
{pstd}Email: jvdries@luiss.it{p_end}
