{smcl}
{* Version 1.0 18September2023}{...}
{cmd: help stckar}

{bf:stckar} {hline 2} draws stacked area graphs

{p}
This package generates a stacked area graph of up to 10 variables. The variables are sorted by a summary statistic to improve the read- and comparability of the graph. It allows for (alternating) positive and negative variable values.

{title:Syntax}

{pstd}
{cmd:stckar}
{it:varlist}
[if]
[{cmd:,}
{it:options}]

{pstd}
where {it:varlist} is 

		{it:y1} [{it:y2 ... y10}] {it:x}
		
{title:Options}
{synoptset}
{synopthdr:Option}
{synoptline}
{synopt:{opt notot:al}}supresses the line plot of the total of all variables {p_end}
{synopt:{opt nosort}}set input order of {it:y-variables} as the plotting order, starting on the highest layer {p_end}
{synopt:{opt nolabels}}use variable names instead of variable labels for the legend {p_end}
{synopt:{opt nodraw}}the standard {help nodraw_option:nodraw option} {p_end}
{synopt:{opt ord:er}}displays the plotting order {p_end}
{synopt:{opt nofixedcolors}}deactivates the feature that the graph colors are fixed to the variable input order {p_end}
{synopt:{opt stat:istics(stat)}}Defines which statistic of the {help summarize:summary command} should be used for ordering the variables, variables with summary values closer to 0 are plotted closer to the x-axis. {p_end}
{synopt:{opt scheme(scheme)}}use this option to set a specific {help schemes:scheme} for the graph {p_end}
{synopt:{opt graphopt:ions(options)}}accepts the standard {help twoway_options:twoway options} for styling the graph {p_end}
{synopt:{opt areaopt:ions(options)}}should accept the standard {help twoway_options:twoway options} for the area graphs {p_end}
{synopt:{opt lineopt:ions(options)}}accepts {help line:line options} for the total line {p_end}


{title:Notes}

{pstd}
By standard the command generates a legend with the variable labels, for variables without a label the variable name is used.{p_end}
{pstd}
The legend entries can be overwritten by using {opt graphopt:ions(options)}. As the command reorganizes the input order of the variables it is necessary to adjust the labeling order according to the order determined by the command.{p_end}
{pstd}
Use the {opt ord:er} option and then adjust the command accordingly.{p_end}

{pstd}
The total line is always the last. Meaning that if you e.g. input 7 {it:y-variables} the option to modify the label of the total would be graphoptions(legend(label(8 {it:label for total}))).

{pstd}
Also the colors assigned to the variables are determined by the variable input order.{p_end}
{pstd}
The implementation of this feature limits the use of {opt scheme()} in the {opt graph/area/lineoptions()}, as this will not change the variable colors unless you also use {opt nofixedcolors}.{p_end}

{pstd}
While sorting is active (that is no use of {opt nosort}) the input order of {it:y-variables} is irrelevant in almost all cases and different input orders should lead to identical graphs.

{pstd}
The package utilizes the {help twoway area:standard area command} and calculates the correct sums.

{pstd}
The command was written with Stata 16.1.


{title:Examples}

{ul:Example 1} - some macroeconomic data

	{stata webuse klein2}
	{stata stckar c i g year, lineoptions(lcolor(red)) graphoptions(legend(label(4 "y")))}

{ul:Example 2} - change in prison population by length of prison term

	{stata "use http://fmwww.bc.edu/ec-p/data/wooldridge/prison"}
	{stata collapse cag0_14 cag15_17 cag18_24 cag25_34, by(year)}
	{stata stckar cag0_14 cag15_17 cag18_24 cag25_34 year}
