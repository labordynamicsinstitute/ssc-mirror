{smcl}
{* *! version 1.0.2  03jul2026}{...}
{title:Copyright}
Copyright 2026 Xuanyu Cai and Wenli Xu
{vieweralsosee "diddesign" "help diddesign"}{...}
{vieweralsosee "diddesign_check" "help diddesign_check"}{...}
{vieweralsosee "diddesign_plot" "help diddesign_plot"}{...}
{vieweralsosee "diddesign_intro" "help diddesign_intro"}{...}
{viewerjumpto "Syntax" "diddesign_plot##syntax"}{...}
{viewerjumpto "Description" "diddesign_plot##description"}{...}
{viewerjumpto "Options" "diddesign_plot##options"}{...}
{viewerjumpto "Methods and formulas" "diddesign_plot##methods"}{...}
{viewerjumpto "References" "diddesign_plot##references"}{...}

{title:Title}

{phang}
{bf:diddesign_plot} {hline 2} Visualization for Double DID Results and Diagnostics

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:diddesign_plot}
[{cmd:,} {it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Plot Type}
{synopt:{opt type(plottype)}}type of plot; default depends on source command{p_end}

{syntab:Output}
{synopt:{opt saving(filename)}}save graph to file{p_end}
{synopt:{opt name(string)}}name for graph window{p_end}
{synopt:{opt replace}}allow overwriting existing file{p_end}

{syntab:Appearance}
{synopt:{opt scheme(schemename)}}graph scheme{p_end}
{synopt:{opt title(string)}}graph title{p_end}
{synopt:{opt xtitle(string)}}x-axis title{p_end}
{synopt:{opt ytitle(string)}}y-axis title{p_end}
{synopt:{opt xlabel(axis_label)}}passthru to {help twoway_options:twoway xlabel()}; overrides the auto-detected year axis on pattern plots{p_end}
{synopt:{opt ylabel(axis_label)}}passthru to {help twoway_options:twoway ylabel()}; overrides the hidden unit axis on pattern plots{p_end}
{synopt:{opt ci}}show 90% SD-based bands around group-period mean outcomes on trends plot{p_end}
{synopt:{opt band}}show CI as ribbon instead of error bars (estimates plot){p_end}
{synopt:{opt level(#)}}confidence level for estimates plot CI; default is {cmd:level(90)}{p_end}
{synopt:{opt colorcheck}}distinguish placebo and DID estimates by color (estimates plot){p_end}
{synopt:{opt estcolor(colorname)}}color for DID estimates; default {cmd:navy} (requires {opt colorcheck}){p_end}
{synopt:{opt checkcolor(colorname)}}color for placebo estimates; default {cmd:cranberry} (requires {opt colorcheck}){p_end}

{syntab:Data Sources}
{synopt:{opt use_check(name)}}overlay placebo estimates from stored results{p_end}
{synoptline}

{pstd}
where {it:plottype} is one of {cmd:estimates}, {cmd:trends}, {cmd:placebo}, {cmd:both}, or {cmd:pattern}.

{marker description}{...}
{title:Description}

{pstd}
{cmd:diddesign_plot} creates visualizations for Double DID estimation results 
and diagnostic results. It can be run after {cmd:diddesign} or {cmd:diddesign_check}. 
The command reads the stored estimation results from {cmd:e()} and generates 
the appropriate plots.

{pstd}
The default plot type depends on the source command:

{phang2}
After {cmd:diddesign}: default is {cmd:estimates}

{phang2}
After {cmd:diddesign_check}: default is {cmd:both}

{pstd}
Five types of plots are available:

{phang2}
{cmd:estimates} - Double DID estimates across lead values with CI at specified level (default 90%, requires {cmd:diddesign})

{phang2}
{cmd:trends} - Treatment and control group outcome trends over time (requires {cmd:diddesign_check})

{phang2}
{cmd:placebo} - Placebo test results with standardized equivalence confidence intervals (requires {cmd:diddesign_check})

{phang2}
{cmd:both} - Combined two-panel plot (requires {cmd:diddesign_check})

{phang2}
{cmd:pattern} - Treatment timing pattern heatmap (SA design only, requires {cmd:diddesign_check})

{marker options}{...}
{title:Options}

{dlgtab:Plot Type}

{phang}
{opt type(plottype)} specifies the type of plot to generate:

{p 8 12 2}
{cmd:estimates} shows Double DID estimates across lead values with 90% confidence 
intervals. This is the default when run after {cmd:diddesign}.

{p 8 12 2}
{cmd:trends} shows outcome trends for treatment and control groups over time.
Available for standard DID designs only. Requires {cmd:diddesign_check} results.

{p 8 12 2}
{cmd:placebo} shows placebo test results with 95% standardized equivalence 
confidence intervals. Requires {cmd:diddesign_check} results.

{p 8 12 2}
{cmd:both} combines two plots side by side. This is the default when run after 
{cmd:diddesign_check}. For standard DID: placebo (left) + trends (right). 
For SA design: placebo (left) + pattern (right).

{p 8 12 2}
{cmd:pattern} shows treatment timing pattern as a heatmap with units on the 
y-axis and time on the x-axis. Units are sorted by treatment timing in 
descending order (never-treated units at bottom, earliest-treated units at top). 
Available for SA design only. Requires {cmd:diddesign_check} results.

{dlgtab:Output}

{phang}
{opt saving(filename)} saves the graph to the specified file. Supported formats 
include .png, .pdf, .eps, .svg, and .tif. If no extension is provided, .png is used.

{phang}
{opt replace} allows overwriting an existing file.

{phang}
{opt name(string)} specifies the name for the graph window.

{dlgtab:Appearance}

{phang}
{opt scheme(schemename)} specifies the graph scheme.

{phang}
{opt title(string)} specifies the graph title.

{phang}
{opt xtitle(string)} specifies the x-axis title.

{phang}
{opt ytitle(string)} specifies the y-axis title.

{phang}
{opt xlabel(axis_label)} and {opt ylabel(axis_label)} pass their arguments directly
to {helpb twoway_options:twoway}'s {cmd:xlabel()}/{cmd:ylabel()}. On the pattern plot,
{cmd:diddesign_plot} auto-detects a calendar year axis from the caller's {cmd:time()}
variable when the time span matches the number of columns in {cmd:e(Gmat)}; specifying
{opt xlabel()} explicitly overrides that default. When auto-detection is not applicable
(for example, on data where columns do not correspond to consecutive calendar periods),
a user-supplied {opt xlabel()} is required to produce a labelled axis.

{phang}
{opt ci} shows 90% SD-based bands around group-period mean outcomes on the trends plot.

{phang}
{opt band} displays confidence intervals as a shaded ribbon instead of error bars 
on the estimates plot.

{phang}
{opt colorcheck} enables two-color mode on the estimates plot when {opt use_check()} 
is also specified. Placebo estimates (negative time) are drawn in one color and DID 
estimates (positive time) in another, making the pre/post trajectory visually 
distinct. The default colors are {cmd:cranberry} for placebo estimates and 
{cmd:navy} for DID estimates. Without this option, all points are drawn in black.

{phang}
{opt estcolor(colorname)} sets the color for DID estimates (positive time) when 
{opt colorcheck} is specified. Any Stata color name or RGB specification is 
accepted. Default is {cmd:navy}.

{phang}
{opt checkcolor(colorname)} sets the color for placebo estimates (negative time) 
when {opt colorcheck} is specified. Default is {cmd:cranberry}.

{phang}
{opt level(#)} specifies the confidence level for the confidence intervals displayed 
on the estimates plot. # must be between 1 and 99. The default is {cmd:level(90)}, 
which produces 90% confidence intervals. To obtain 95% confidence intervals, 
specify {cmd:level(95)}.

{dlgtab:Data Sources}

{phang}
{opt use_check(name)} overlays placebo estimates from stored {cmd:diddesign_check} 
results. The named results must have been saved using {cmd:estimates store} and 
must use the same design, same outcome variable, same treatment variable, same
data type, same cluster variable, same covariate specification, and the same
{cmd:if}/{cmd:in} sample restriction as the current estimate. For panel
results, the stored diagnostic object must also use the same {cmd:id()}
variable and the same {cmd:time()} variable as the current estimate. For repeated
cross-section results, the stored diagnostic object must also use the same
post-treatment indicator variable, that is, the same {cmd:post()} definition,
as the current estimate. When specified, 
placebo estimates (at negative time = -lag) are combined with estimation results 
(at positive time = lead) to show the full pre- and post-treatment trajectory.

{marker methods}{...}
{title:Methods and formulas}

{pstd}
{cmd:diddesign_plot} generates visualizations based on stored {cmd:e()} results 
from {cmd:diddesign} or {cmd:diddesign_check}.

{pstd}
{bf:Estimates plot}

{pstd}
The estimates plot displays Double DID point estimates with confidence intervals 
at the level specified by {opt level()} (default 90%). The plot is generated from 
the {cmd:e(estimates)} matrix. The confidence intervals are computed as:

{p 8 8 2}
CI = estimate +/- z_{(1+level/100)/2} * SE

{pstd}
where z_{(1+level/100)/2} = invnormal((1 + level/100) / 2). For the default 90% CI, 
this gives z_{0.95} = invnormal(0.95) = 1.645. For 95% CI, z_{0.975} = invnormal(0.975) = 1.960. 
When the {cmd:use_check()} option is specified, placebo estimates from pre-treatment 
periods are placed at negative time values (-lag) to create a complete trajectory.

{pstd}
{bf:Placebo plot}

{pstd}
The placebo plot displays 95% standardized equivalence confidence intervals for 
pre-treatment placebo estimates. The plot is generated from the {cmd:e(placebo)} 
matrix. The equivalence CI is computed using the TOST (Two One-Sided Tests) method:

{p 8 8 2}
EqCI95 = (-nu, nu)

{pstd}
where nu = max(|estimate + z_{0.95} * SE|, |estimate - z_{0.95} * SE|). This 
symmetric interval centered at zero indicates the range within which the true 
effect lies with 95% confidence under the null hypothesis of no pre-trend.

{pstd}
{bf:Trends plot}

{pstd}
The trends plot displays mean outcomes for treatment and control groups across 
time periods relative to treatment assignment. The plot is generated from the 
{cmd:e(trends)} matrix which contains group-time means, standard deviations, 
and cell counts. When {opt ci} is specified, the command plots 90% confidence 
bands using the stored group-period outcome standard deviation {it:SD}, matching 
the reference DIDdesign R implementation. This plot is available for standard DID 
designs only.

{pstd}
{bf:Pattern plot}

{pstd}
The pattern plot displays treatment timing as a heatmap. Units are sorted by 
their first treatment time in descending order, with never-treated units at the 
bottom and earliest-treated units at the top. The plot is generated from the 
{cmd:e(Gmat)} matrix. This plot is available for SA designs only.

{pstd}
{bf:Combined plot}

{pstd}
The combined plot arranges two subplots side by side. For standard DID designs, 
the placebo plot is displayed on the left and the trends plot on the right. For 
SA designs, the placebo plot is displayed on the left and the pattern plot on 
the right.

{marker references}{...}
{title:References}

{phang}
Egami, N. and S. Yamauchi. 2023.
Using Multiple Pretreatment Periods to Improve Difference-in-Differences
and Staggered Adoption Designs.
{it:Political Analysis} 31(2): 195-212.
{browse "https://doi.org/10.1017/pan.2022.8"}
{p_end}

{title:Author}

{pstd}
Xuanyu Cai{break}
City University of Macau{break}
xuanyuCAI@outlook.com

{pstd}
Wenli Xu{break}
City University of Macau{break}
wlxu@cityu.edu.mo

{title:Also see}

{psee}
Online: {helpb diddesign}, {helpb diddesign_check}, {helpb diddesign_plot}, {helpb diddesign_intro}
{p_end}
