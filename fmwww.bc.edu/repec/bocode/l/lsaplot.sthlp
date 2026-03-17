{smcl}
{* 13feb2026}{...}
{hline}
{cmd:lsaplot} {hline 2} Plot event-study/dynamic treatment effects for difference-in-differences
{hline}

{title:Syntax}

{p 8 15 2}
{cmd:lsaplot} {depvar} [{indepvars}]
{ifin}
{cmd:,}
{cmdab:Treat(}{it:varname}{cmd:)}
{cmdab:ID(}{it:varname}{cmd:)}
{cmdab:Time(}{it:varname}{cmd:)}
[{cmdab:start(}{it:#}{cmd:)}
{cmdab:end(}{it:#}{cmd:)}
{cmdab:base(}{it:#}{cmd:)}
{cmdab:level(}{it:#}{cmd:)}
{cmdab:cluster(}{it:varname}{cmd:)}
{cmdab:absorb(}{it:fe_spec}{cmd:)}
{cmdab:bin}
{cmdab:trim}
{cmdab:title(}{it:string}{cmd:)}
{cmdab:keepdata}
{cmdab:nograph}
{cmdab:name(}{it:name}{cmd:)} ]


{title:Description}

{pstd}
{cmd:lsaplot} estimates and plots dynamic treatment effects (coefficients for each relative time period) from an event-study or staggered difference-in-differences (DID) model. It automatically generates publication-ready graphs with point estimates and confidence intervals.

{pstd}
The command features a "smart engine" that switches between estimation methods:
{p_end}
{pmore}1. For standard two-way fixed effects models, it uses the efficient {cmd:xtreg}.
{p_end}
{pmore}2. When high-dimensional fixed effects (via {cmd:absorb()}) or non-nested clustering is detected, it automatically switches to {cmd:reghdfe} to avoid estimation errors.

{pstd}
Two methods are provided for handling observations outside the specified event-time window ({cmd:start} to {cmd:end}):
{p_end}
{pmore}1. {cmd:bin} (binning/cohorting, recommended): Pools all pre-periods before {cmd:start} into the {cmd:start} period and all post-periods after {cmd:end} into the {cmd:end} period. This helps capture cumulative long-term effects.
{p_end}
{pmore}2. {cmd:trim} (trimming): Drops all treated observations whose event time falls outside the specified window.
{p_end}
{pmore}3. Default (not recommended): Neither bins nor trims. Variation from outside the window remains in the base group, which may lead to biased estimates.


{title:Options}

{phang}
{cmd:Treat(}{it:varname}{cmd:)} specifies a numeric variable indicating the first period when a unit receives treatment (e.g., the year of policy adoption). For never-treated control units, this variable should be 0 or a missing value (.). This variable is used to generate relative-time dummies. {it:Required}.

{phang}
{cmd:ID(}{it:varname}{cmd:)} specifies the panel unit identifier (e.g., firm ID, city code). {it:Required}.

{phang}
{cmd:Time(}{it:varname}{cmd:)} specifies the time identifier (e.g., year). {it:Required}.

{phang}
{cmd:start(}{it:#}{cmd:)} sets the first relative period to be included in the estimation and plot (e.g., -5). Defaults to the minimum computable relative period in the sample.

{phang}
{cmd:end(}{it:#}{cmd:)} sets the last relative period to be included (e.g., 5). Defaults to the maximum computable relative period.

{phang}
{cmd:base(}{it:#}{cmd:)} defines the base (omitted) relative period. The coefficient for this period is normalized to zero and excluded from the plot. Default is -1.

{phang}
{cmd:level(}{it:#}{cmd:)} sets the confidence level for confidence intervals, e.g., 90, 95 (the default), or 99.

{phang}
{cmd:cluster(}{it:varname}{cmd:)} specifies the level for cluster-robust standard errors (e.g., industry, province). Any level is allowed. The default is heteroskedasticity-robust standard errors ({cmd:robust}).

{phang}
{cmd:absorb(}{it:fe_spec}{cmd:)} manually specifies high-dimensional fixed effects to absorb, using syntax like {cmd:absorb(firm_id year industry#year)}. When this option is specified, the command forces the use of {cmd:reghdfe} and strictly follows this specification; it {bf:does not} automatically include time fixed effects.

{phang}
{cmd:bin} enables binning for observations outside the event window. All periods earlier than {cmd:start} are binned into the {cmd:start} period; all periods later than {cmd:end} are binned into the {cmd:end} period.

{phang}
{cmd:trim} enables trimming for observations outside the event window. It drops all {bf:treated} observations whose relative time is outside the [{cmd:start}, {cmd:end}] window.

{phang}
{cmd:title(}{it:string}{cmd:)} adds a custom title to the generated graph.

{phang}
{cmd:keepdata} retains the intermediate dataset (containing relative time, coefficients, confidence intervals, etc.) in memory after estimation, replacing the current data.

{phang}
{cmd:nograph} runs the estimation but suppresses graph output. Useful for quickly checking regression results.

{phang}
{cmd:name(}{it:name}{cmd:)} assigns a name to the generated graph for later use with commands like {cmd:graph combine}.


{title:Examples}

{pstd}Basic example: Quick preview of dynamic effects{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. // Generate gvar (first treatment year)}{p_end}
{phang2}{cmd:. bys idcode: egen gvar = min(year) if union == 1}{p_end}
{phang2}{cmd:. replace gvar = 0 if mi(gvar)}{p_end}
{phang2}{cmd:. lsaplot ln_wage, treat(gvar) id(idcode) time(year)}{p_end}

{pstd}Standard DID plot: Set window, cluster, and use binning{p_end}
{phang2}{cmd:. lsaplot ln_wage tenure hours, treat(gvar) id(idcode) time(year) start(-5) end(5) cl(idcode) bin title("Dynamic Effects on Wage")}{p_end}

{pstd}High-dimensional fixed effects with trimming{p_end}
{phang2}{cmd:. lsaplot ln_wage, treat(gvar) id(idcode) time(year) absorb(idcode occ_code#year) cl(occ_code) trim}{p_end}

{pstd}Create and combine multiple graphs{p_end}
{phang2}{cmd:. lsaplot ln_wage, treat(gvar) id(idcode) time(year) start(-3) bin name(fig1, replace)}{p_end}
{phang2}{cmd:. lsaplot hours, treat(gvar) id(idcode) time(year) start(-3) bin name(fig2, replace)}{p_end}
{phang2}{cmd:. graph combine fig1 fig2, row(1)}{p_end}


{title:Stored results}

{pstd}
{cmd:lsaplot} stores standard estimation results in {cmd:e()}, the contents of which depend on the underlying engine used ({cmd:xtreg} or {cmd:reghdfe}).
{p_end}
{pstd}
If the {cmd:keepdata} option is specified, the resulting dataset in memory will contain the following variables used for plotting:
{it:reltime}, {it:beta}, {it:cil}, {it:ciu} (representing relative time, coefficient estimate, lower and upper confidence interval bounds, respectively).


{title:Installation and requirements}

{pstd}
{cmd:lsaplot} is self-contained but relies on external packages for advanced features. It is recommended to install:
{p_end}
{phang2}{cmd:. ssc install reghdfe, replace}{p_end}
{phang2}{cmd:. ssc install ftools, replace}{p_end}
{pstd}
The latest version can also be installed from GitHub:
{p_end}
{phang2}{cmd:. net install lsaplot, from(https://raw.githubusercontent.com/hurilen/lsaplot/main/) replace}{p_end}


{title:Author}

Linze Li
School of Public Finance and Taxation, Shandong University of Finance and Economics
Email: lilinze626@gmail.com


{title:References}

{pstd}
Sun, L., and S. Abraham. 2021. Estimating Dynamic Treatment Effects in Event Studies with Heterogeneous Treatment Effects. {it:Journal of Econometrics}.{p_end}
{pstd}
For methodological discussions on event-study and staggered DID designs, please refer to the recent econometrics literature.
{p_end}
