{smcl}
{help undid_plot:undid_plot}
{hline}

{title:undid_plot}

{pstd}
Creates parallel trends and event study plots for visual diagnostics of the UN-DID estimation. 
Takes in trends data CSV files from stage two and produces visualizations to 
assess treatment effects over time.
{p_end}

{title:Command Description}

{phang}
{cmd:undid_plot} reads the trends data CSV files generated in stage two and creates various 
types of plots to visualize treatment effects. The command supports trends plots 
(aggregated, disaggregated, or silo-specific) and event study plots with confidence intervals. 
These visualizations help assess the plausibility of the parallel trends assumption and 
illustrate treatment effect dynamics.
{p_end}

{title:Syntax}

{p 8 17 2}
{cmd:undid_plot}
{cmd:,}
{cmd:dir_path(}{it:string}{cmd:)}
{p_end}

{p 8 17 2}
[{cmd:plot(}{it:string}{cmd:)}
{cmd:weights(}{it:integer}{cmd:)}
{cmd:covariates(}{it:integer}{cmd:)}
{cmd:omit(}{it:string}{cmd:)}
{cmd:only(}{it:string}{cmd:)}
{cmd:treated_colours(}{it:string}{cmd:)}
{cmd:control_colours(}{it:string}{cmd:)}
{cmd:ci(}{it:real}{cmd:)}
{cmd:event_window(}{it:numlist}{cmd:)}
{cmd:hc(}{it:integer}{cmd:)}]
{p_end}

{title:Parameters}

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt dir_path(string)}}filepath to folder containing trends data CSV files from stage two{p_end}

{syntab:Plot Type and Options}
{synopt:{opt plot(string)}}plot type: "agg", "dis", "silo", or "event" (default: "agg"){p_end}
{synopt:{opt weights(integer)}}use weights from trends data: 1 = yes, 0 = no (default: 1){p_end}
{synopt:{opt covariates(integer)}}use covariate-adjusted means: 1 = use mean_outcome_residualized, 0 = use mean_outcome (default: 0){p_end}

{syntab:Silo Selection}
{synopt:{opt omit(string)}}space-separated list of silos to exclude from plot{p_end}
{synopt:{opt only(string)}}space-separated list of silos to include in plot (excludes all others){p_end}

{syntab:Appearance}
{synopt:{opt treated_colours(string)}}space-separated list of colors for treated silos (default: "cranberry maroon red orange_red dkorange sienna brown gold pink magenta purple"){p_end}
{synopt:{opt control_colours(string)}}space-separated list of colors for control silos (default: "navy dknavy blue midblue ltblue teal dkgreen emerald forest_green mint cyan"){p_end}

{syntab:Event Study Options}
{synopt:{opt ci(real)}}confidence level for event study plots, 0-1; 0 disables confidence intervals (default: 0.95){p_end}
{synopt:{opt event_window(numlist)}}two numbers specifying [periods before, periods after] treatment to display (default: all periods){p_end}
{synopt:{opt hc(integer)}}heteroskedasticity-consistent covariance matrix estimator for event study standard errors: 0, 1, 2, 3, or 4 (default: 3){p_end}
{synoptline}
{p2colreset}{...}

{title:Plot Types}

{pstd}
The {cmd:plot()} option determines which type of visualization is created:

{synoptset 15 tabbed}{...}
{synopthdr:Plot Option}
{synoptline}

{synopt:{bf:agg}}Aggregated trends plot (default). Shows weighted average trends for 
treated and control groups over time. All treated silos are averaged into one line, and all 
control silos are averaged into another line.{p_end}

{synopt:{bf:dis}}Parallel trends plot. Shows separate trend lines for every 
individual silo, with each silo displayed as its own line.{p_end}

{synopt:{bf:silo}}Shows individual trend lines for each 
treated silo, with all control silos averaged together into a single control line.{p_end}

{synopt:{bf:event}}Event study plot. Shows treatment effects by periods relative to treatment 
with confidence intervals.{p_end}

{synoptline}
{p2colreset}{...}

{title:Examples}

{pstd}
For more examples and sample data, please visit the GitHub repository:{p_end}
{pstd}
{browse "https://github.com/ebjamieson97/undid"}{p_end}

{pstd}
{bf:Basic aggregated plot:}{p_end}

{phang2}{cmd:. undid_plot, dir_path("output/stage_two/")}{p_end}

{pstd}
Creates a trends plot showing weighted average trends for treated vs control groups.{p_end}

{pstd}
{bf:Event study plot with 95% confidence intervals:}{p_end}

{phang2}{cmd:. undid_plot, dir_path("output/stage_two/") plot("event") ci(0.95)}{p_end}

{pstd}
Creates an event study plot showing treatment effects over time with 95% confidence bands.{p_end}

{pstd}
{bf:Event study with restricted window:}{p_end}

{phang2}{cmd:. undid_plot, dir_path("output/stage_two/") plot("event") ///}{p_end}
{phang2}{cmd:    event_window(-5 10) ci(0.90)}{p_end}

{pstd}
Shows 5 periods before through 10 periods after treatment with 90% confidence intervals.{p_end}

{pstd}
{bf:Disaggregated plot with covariate adjustment:}{p_end}

{phang2}{cmd:. undid_plot, dir_path("output/stage_two/") plot("dis") covariates(1)}{p_end}

{pstd}
Shows separate trend lines for every silo using covariate-adjusted outcome means.{p_end}

{pstd}
{bf:Silo-specific plot excluding certain silos:}{p_end}

{phang2}{cmd:. undid_plot, dir_path("output/stage_two/") plot("silo") ///}{p_end}
{phang2}{cmd:    omit("California Texas")}{p_end}

{pstd}
Shows individual trend lines for treated silos (except California and Texas if they were treated) 
and an averaged control line.{p_end}

{pstd}
{bf:Custom color scheme:}{p_end}

{phang2}{cmd:. undid_plot, dir_path("output/stage_two/") plot("silo") ///}{p_end}
{phang2}{cmd:    treated_colours("red orange yellow") ///}{p_end}
{phang2}{cmd:    control_colours("blue green purple")}{p_end}

{pstd}
Creates a silo plot with custom colors for treated silos and the control line.{p_end}

{title:Package Author}

{pstd}
Eric Jamieson. Report bugs at: ericbrucejamieson@gmail.com or {browse "https://github.com/ebjamieson97/undid"}.
{p_end}

{title:Citations}

{pstd}
If you use {cmd:undid} in your research, please cite:{p_end}

{pstd}
Sunny Karim, Matthew D. Webb, Nichole Austin, and Erin Strumpf. "Difference-in-Differences 
with Unpoolable Data." {browse "https://arxiv.org/abs/2403.15910"}{p_end}

{pstd}
To cite the {cmd:undid} Stata package:{p_end}

{pstd}
Eric Jamieson (2026). undid: Difference-in-Differences with Unpoolable Data. 
Stata package version 2.0.0. {browse "https://github.com/ebjamieson97/undid"}{p_end}

{* undid_plot                                         }
{* written by Eric Jamieson                           }
{* version 2.0.0 2026-02-16                           }

{smcl}