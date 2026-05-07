{smcl}
{* *! version 1.0  05may2026}{...}
{cmd:help manybars}
{hline}
{viewerjumpto "Syntax" "manybars##syntax"}{...}
{viewerjumpto "Options table" "manybars##options_table"}{...}
{viewerjumpto "Description" "manybars##description"}{...}
{viewerjumpto "Main options" "manybars##main_options"}{...}
{viewerjumpto "Graph and legend options" "manybars##graph_options"}{...}
{viewerjumpto "Examples" "manybars##examples"}{...}
{viewerjumpto "Stored results" "manybars##stored_results"}{...}

{title:Title}

{p 4 16 2}
{bf:manybars} {hline 2} Bar graphs of a summary statistic for an outcome {it:y} variable at specific values of multiple indicator {it:x} variables{p_end}


{marker syntax}{...}
{title:Syntax}

{p 4 11 2}
{cmd:manybars} {it:varname} {ifin}, xvars({it:varlist}) [stat({it:statistic})] [{it:options}]
{p_end}


{marker options_table}{...}
{synoptset 39 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Main options}
{synopt:{opt x:vars(varlist)}}Categorical indicator {it:x} variables. At least one {opt xvar} is required.{p_end}
{synopt:{opt s:tat(statistic [, stat_options])}}The summary statistic that will be calculated for {it:varname}{p_end}
{synopt:{opt d:isplayvalues(numlist)}}Optional values of the {it:xvars} at which {it:stat} will be calculated{p_end}
{synopt:{opt over:vars(varlist)}}Optional categorical variables for further grouping{p_end}
{synopt:{opt now:arn}}Suppress warning messages about missing values{p_end}

{syntab:Graph options}
{synopt:{opt h:orizontal}}Display the graph horizontally{p_end}
{synopt:{opt gra:phopts(optional_graph_options)}}Options for the graph (but not for the legend){p_end}
{synopt:{opt add:tolegend(optional_legend_options)}}Additional options for the graph legend{p_end}
{synopt:{opt newl:egend(optional_legend_options)}}Replacement options for the graph legend{p_end}
{synopt:{opt var:label}}Display variable labels for the {it:xvars} instead of the default display of value labels{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:manybars} generates bar graphs showing a summary statistic for an outcome variable, computed separately at user-specified values of one or more indicator variables. This adds functionality to Stata's native {cmd:graph bar} command, which requires a single categorical grouping variable for each {opt over()} call and cannot draw bars for multiple separate indicator variables in a single graph.
{p_end}

{pstd}
The command accepts one or more numeric indicator variables as {it:x} variables ("{it:xvars}") and computes the specified statistic (default: mean) of the outcome at a specific value of each indicator (default: 1), displaying the results as a grouped bar graph with legend labels drawn from value or variable labels. The {opt displayvalues()} option allows the user to specify which value of each {it:xvar} defines the subgroup of interest. Optionally, bars can be further grouped by one or more (usually categorical) grouping variables using the {opt overvars()} option. This produces clustered bar graphs that compare the statistic, at each {it:xvar=displayvalue}, across those {it:over}-variables. 
{p_end}

{pstd}The program will exit with an error if {it:xvar=displayvalue} has zero observations for any bar.
{p_end}

{title:Options}

{marker main_options}{...}
{dlgtab:Main Options}

{phang}
{opt xvars(varlist)} specifies one or more categorical explanatory variables for which the value(s) of the {it:y}-variable will be computed and graphed. {opt xvars} is required.
{p_end}

{phang}
{opt stat(statistic)} allows the user to specify any of the following statistics to be graphed:
{p_end} 
{p 12 12 12}{cmd:mean} {cmd:sd} {cmd:skew} {cmd:kurt} {cmd:min} {cmd:max} {cmd:count} {cmd:total} {cmd:median} {cmd:iqr} {cmd:mode} {cmd:mad} {cmd:mdev}
{p_end}

{phang}
Optional {it:stat_options} are any options for the underlying {help egen} command used to generate the values of {it:varname} for display. These options are passed directly to {cmd:egen} without validation. Do not include {opt by()} within {it:stat_options}, as it will return an error. Use the {opt overvars()} option instead.
{p_end}

{phang}
{opt displayvalues(numlist)} optionally specifies the values of the {it:xvars} at which the requested {opt stat} will be calculated. 

{p 8 8 2}If {opt displayvalues} are not specified, the default value of 1 will be used for each {it:xvar}.
{p_end}

{p 8 8 2}If a single {opt displayvalue} is specified, that value will be used for each {it:xvar}.
{p_end}

{p 8 8 2}Alternatively, users may specify a number of {opt displayvalues} equal to the number of {it:xvars}. In this case, the first {it:displayvalue} will be used for the first variable, the second value will be used for the second variable, and so on. If the number of supplied values does not equal the number of variables, an error will be returned. 
{p_end}

{phang}
{opt overvars(varlist)} are optional additional categorical variables over which the {opt stat} will be graphed at each level of the {it:xvars}, similar to many commands' {opt by}, {opt within}, and {opt over} options. Note that, unlike {cmd:graph bar}'s native repeatable {opt over()} option, in {cmd:manybars} all grouping variables are listed in a single list of {opt overvars}. {cmd:graph bar}'s {it:over_suboptions} are not supported. 
{p_end}

{phang}
The {opt nowarn} option suppresses warning messages about missing values on the {it:yvar}, {it:xvars}, and {it:overvars} that are displayed by default. Only observations with complete data on the relevant variables are included in the graph. {opt nowarn} does not prevent the program from exiting if there is an error.
{p_end}

{phang}
Note: {cmd:graph bar} and {cmd:graph hbar} do not differentiate between bars with zero height (i.e., there are valid observations but they all equal zero) from bars that are not drawn because the entire bar is missing (i.e., all observations for {cmd:xvar=displayvalue} are missing). One way to graph the difference is to add {opt blabel(bar)} to {opt graphopts()}. 
{p_end}

{marker graph_options}{...}
{dlgtab:Graph and Legend Options}

{phang}
The {opt horizontal} option changes the graph call to {cmd:graph hbar}. If {opt horizontal} is not specified, the graph call will be {cmd:graph bar}.
{p_end}

{phang}
{opt graphopts()} are passed as-is to {cmd:graph bar}.
{p_end}

{phang}
{opt addtolegend()} allows any of {cmd:graph bar}'s {help graph_bar##legending_options:legend_options} to be {ul:added} to {cmd:manybars}'s default {opt legend()} call. Do not include "legend()" within {opt addtolegend()}, as it will return an error.
{p_end}

{phang}
{opt newlegend()} may not be combined with {opt addtolegend()}. {opt newlegend()} completely {ul:replaces} {cmd:manybars}'s default legend, starting over from {cmd:graph bar, legend({help graph_bar##legending_options:legend_options})}. Do not include "legend()" within {opt newlegend()}, as it will return an error.
{p_end}

{phang}
By default, the graph legend will display the applicable value label for the {it:displayvalue} of each {it:xvar}. Option {opt varlabel} requests that the {it:xvar} variable name(s) be displayed instead. 
{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{ul:Basic syntax}{p_end}

{p 8 8 4}{stata "sysuse nlsw88"}
{p_end}

{p 8 24 4}Vertical graph: {stata "manybars wage, xvars(union collgrad)"}
{p_end}

{p 8 26 4}Horizontal graph: {stata "manybars wage, xvars(union collgrad) horizontal"}
{p_end}

{pstd}{ul:Specifying displayvalues}{p_end}

{p 8 8 4}{stata "sysuse nlsw88"}
{p_end}

{p 8 34 4}Same value for all {it:xvars}: {stata "manybars tenure, xvar(c_city never_married collgrad) displayvalues(0)"}
{p_end}

{p 8 31 4}Specifying each value: {stata "manybars tenure, xvar(c_city never_married collgrad) displayvalues(1 1 0)"}
{p_end}

{p 8 55 4}Graphing more than one level of the same {it:xvar}: {stata "manybars tenure, xvar(c_city never_married collgrad collgrad) displayvalues(1 1 0 1)"}
{p_end}

{pstd}{ul:Modifying the graph and the legend}{p_end}

{p 8 8 4}{stata "sysuse nlsw88"}
{p_end}

{p 8 26 4}Adding {opt graphopts}: {stata "manybars wage, xvars(union collgrad) graphopts(bargap(11) ti(Great Graph!))"}
{p_end}

{p 8 47 4}Adding to the legend with {opt addtolegend}: {stata "manybars wage, xvars(union collgrad) graphopts(bargap(11) ti(Great Graph!)) addtolegend(pos(6))"}
{p_end}

{p 8 45 4}Replacing the legend with {opt newlegend}: {stata `"manybars wage, xvars(union collgrad) graphopts(bargap(11) ti(Great Graph!)) newlegend(label(1 "Union Member") label(2 "Bachelor's Degree or Higher") pos(6) region(lc(pink)))"'}
{p_end}

{pstd}{ul:Addressing uninformative bars and legend labels}{p_end}

{p 8 8 4}{stata "webuse lbw"}
{p_end}

{p 8 27 4}Zero bar heights: {stata "manybars ftv, stat(median) xvar(smoke ptl) d(0)"}
{p_end}

{p 8 30 4}Improved with {opt blabel}: {stata "manybars ftv, stat(median) xvar(smoke ptl) d(0) graph(blab(bar, size(large)))"}
{p_end}

{p 8 36 4}Better legend with {opt varlabel}: {stata "manybars ftv, stat(median) xvar(smoke ptl) d(0) graph(blab(bar, size(large))) varlabel"}
{p_end}

{pstd}{ul:Grouping bars with overvars}{p_end}

{p 8 8 4}{stata "webuse lbw"}
{p_end}

{p 8 21 4}One {opt overvar}: {stata "manybars lwt, xvar(ht ptl) over(smoke) varlabel"}
{p_end}

{p 8 22 4}Two {opt overvars}: {stata "manybars lwt, xvar(ht ptl) over(smoke race) varlabel addtolegend(pos(6))"}
{p_end}

{pstd}{ul:Specifying options for the egen command with stat_options} (see {help egen:help egen}){p_end}

{p 8 8 4}{stata "sysuse nlsw88"}
{p_end}

{p 8 24 4}No stat_option: {stata "manybars grade, stat(mode) xv(married) overvar(race union) graph(blab(bar) name(g_mode, replace) ti(stat: mode))"}
{p_end}

{p 8 29 4}Using a stat_option: {stata `"manybars grade, stat(mode, maxmode) xv(married) overvar(race union) graph(blab(bar) name(g_max, replace) ti("stat: mode, maxmode"))"'}
{p_end}

{p 8 19 4}Comparison: {stata "graph combine g_mode g_max, ycom"}
{p_end}


{marker stored_results}{...}
{title:Stored Results}

{pstd}
{cmd:manybars} saves the following in {cmd:r()}: 
{p_end}

{pstd}Scalars:{p_end}
{synoptset 24 tabbed}{...}
{synopt:{cmd:r(N_graphed)}}the sample size used in the graph{p_end}
{synopt:{cmd:r(N_missing)}}the number of missing observations excluded from the graph due to missingness{p_end}
{synopt:{cmd:r(n_xvars)}}the number of {it:xvars}{p_end}

{pstd}Macros:{p_end}
{synopt:{cmd:r(yvar)}}the {it:y} variable{p_end}
{synopt:{cmd:r(xvars)}}the {it:x} variable(s){p_end}
{synopt:{cmd:r(overvars)}}the {it:over} variable(s){p_end}
{synopt:{cmd:r(stat)}}the statistic calculated for the {it:y} variable{p_end}
{synopt:{cmd:r(cmd)}}manybars{p_end}

{marker author}{...}
{hline}
{title:Author}

{pstd}Brian Shaw, Indiana University, USA{p_end}
{pstd}bpshaw@iu.edu{p_end}
