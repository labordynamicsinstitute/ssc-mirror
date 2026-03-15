{smcl}
{* 14mar2026}{...}
{cmd:help xtgets_plot} {right:version 1.0.0}
{hline}

{title:Title}

{p2colset 5 25 27 2}{...}
{p2col :{hi:xtgets_plot} {hline 2}}Postestimation visualizations for {cmd:xtgets}{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}{cmd:xtgets_plot} [{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt type(string)}}Plot type: {cmd:breaks}, {cmd:heatmap}, {cmd:grid} (default), {cmd:counter}, {cmd:residuals}{p_end}
{synopt :{opt sav:ing(filename)}}Save graph to disk{p_end}
{synopt :{opt scheme(schemename)}}Stata graph scheme{p_end}
{synopt :{opt title(string)}}Custom title for the graph{p_end}
{synopt :{opt plust(#)}}Extra periods for counterfactual projection; default {cmd:0}{p_end}
{synopt :{opt combine}}Combine subgraphs into a single graph{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:xtgets_plot} produces postestimation graphs after running {cmd:xtgets}.  It
replicates the plotting functions of the R {cmd:getspanel} package.  The command
must be called immediately after {cmd:xtgets} (it reads from {cmd:e()}).

{pstd}
Five plot types are available, each serving a different diagnostic purpose.


{title:Plot Types}

{dlgtab:type(breaks) — Break Detection Timeline}

{pstd}
Scatter plot showing detected break dates by panel unit.  Each retained indicator
is plotted as a point on a unit (y-axis) vs time (x-axis) grid.  Different marker
shapes distinguish indicator types: circle = FESIS, diamond = IIS, triangle = CSIS,
square = TIS.

{pstd}
{bf:Use for:} Quick overview of which units had breaks and when.

{pstd}
{it:R equivalent:} {cmd:plot(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(breaks)}{p_end}


{dlgtab:type(heatmap) — Effect Heatmap}

{pstd}
Heatmap showing the magnitude and sign of break effects over time for each unit.
Blue shading = positive effects (increase in dependent variable); red shading =
negative effects (decrease).  Darker colours = larger magnitude.  For FESIS,
shading extends from the break date to the end of the sample.

{pstd}
{bf:Use for:} Visualizing the direction and strength of detected breaks across
the full panel.

{pstd}
{it:R equivalent:} {cmd:plot(is1)} (heatmap view){p_end}

{phang}{cmd:. xtgets_plot, type(heatmap)}{p_end}


{dlgtab:type(grid) — Fitted vs Actual Grid}

{pstd}
Small-multiple grid with one panel per unit.  Each panel shows:{p_end}

{p 8 8 2}{bf:Black line (+):} Actual values of the dependent variable.{p_end}
{p 8 8 2}{bf:Blue line:} Fitted values from the final model (with break indicators).{p_end}
{p 8 8 2}{bf:Red vertical lines:} Dates of detected breaks.{p_end}

{pstd}
{bf:Use for:} Assessing model fit and checking whether breaks align with visible
changes in the data.

{pstd}
{it:R equivalent:} {cmd:plot_grid(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(grid) saving(mygrid)}{p_end}


{dlgtab:type(counter) — Counterfactual Analysis}

{pstd}
Shows actual vs counterfactual trajectories for units with detected breaks.
Only units that have at least one break are shown.{p_end}

{p 8 8 2}{bf:Black line (+):} Actual values.{p_end}
{p 8 8 2}{bf:Red dashed line:} Counterfactual (predicted without break indicators).{p_end}
{p 8 8 2}{bf:Blue line:} Fitted values (with break indicators).{p_end}
{p 8 8 2}{bf:Red shaded area:} Difference = estimated break effect.{p_end}

{pstd}
{bf:Use for:} Estimating "what would have happened" in the absence of the
break/treatment.  The gap between actual and counterfactual is the treatment
effect.

{pstd}
{it:R equivalent:} {cmd:plot_counterfactual(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(counter)}{p_end}


{dlgtab:type(residuals) — Residual Analysis}

{pstd}
Small-multiple grid showing residuals from the final model for each unit.
A horizontal red dashed line at zero is shown for reference.

{pstd}
{bf:Use for:} Diagnosing model adequacy.  Well-behaved residuals should be
centred around zero with no visible patterns, trends, or heteroscedasticity.

{pstd}
{it:R equivalent:} {cmd:plot_residuals(is1)}{p_end}

{phang}{cmd:. xtgets_plot, type(residuals)}{p_end}


{title:Examples}

{pstd}{bf:Full estimation and plotting workflow:}{p_end}

{phang}{cmd:. xtset country year}{p_end}
{phang}{cmd:. xtgets emissions lgdp lpop, fesis effect(twoways) t_pval(0.01)}{p_end}
{phang}{cmd:. xtgets_plot, type(breaks) saving(breaks_plot)}{p_end}
{phang}{cmd:. xtgets_plot, type(heatmap) saving(heatmap_plot)}{p_end}
{phang}{cmd:. xtgets_plot, type(grid) saving(grid_plot)}{p_end}
{phang}{cmd:. xtgets_plot, type(counter) saving(counterfactual_plot)}{p_end}
{phang}{cmd:. xtgets_plot, type(residuals) saving(residuals_plot)}{p_end}


{title:Remarks}

{pstd}
{cmd:xtgets_plot} requires that {cmd:xtgets} was the last estimation command
run.  It reads all information from {cmd:e()} results.  If you run another
estimation command between {cmd:xtgets} and {cmd:xtgets_plot}, the plot command
will fail.

{pstd}
For large panels (many units), the grid, counterfactual, and residual plots
may be crowded.  Consider using {opt saving()} to save the graph and viewing
it at full size in the Graph Editor, or restrict the sample to a subset of units.


{title:Author}

{pstd}Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:Also see}

{psee}
{helpb xtgets}
{p_end}
