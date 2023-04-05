{smcl}
{* *! version 17.0 30mar2023}{...}
{viewerjumpto "Syntax" "dgraph##syntax"}{...}
{viewerjumpto "Description" "dgraph##description"}{...}
{viewerjumpto "Options" "dgraph##options"}{...}
{viewerjumpto "Example" "dgraph##example"}{...}

{p2col:{bf:dgraph}}Plots and tables for stacked t tests

{marker syntax}{...}
{title:Syntax}
{p}
{cmd:dgraph} {varlist}(min=1){cmd:,} {opt by(string)} [ {opt label} {opt long}  {opt reverse} {opt echo} {opt suppress} {opt ci(num)} {opt graphoptions} ]

{marker description}{...}
{title:Description}
{pstd}
This package generates a stacked coefficient plot for two-tailed t-tests. 
It is very useful for showcasing, through a very simple line of code, a graphical 
representation of covariates imbalance between groups. Several dependent variables 
can be tested in a single run. Results can be stored in a LaTeX table.

{pstd}
For more info and updates, please visit: https://github.com/DiegoCiccia/dgraph

{marker options}{...}
{title:Options}

{opt Baseline options:}
{phang}{opt varlist}: (required) outcome variables. Only numeric variables can be included in varlist.

{phang}{opt by(string)}: (required) dummy variable defining two estimation groups. It can be numeric or string, but it must take only two distinct values.

{phang}{opt label}: use variable labels in place of variable names.

{phang}{opt long}: stack confidence intervals horizontally (starting from the left side);. By default, confidence intervals are stacked vertically (starting from the bottom).

{phang}{opt reverse}: shown point estimates as the average y(1) - y(0). As in the Stata ttest command, by default y(0) - y(1) is shown.

{phang}{opt echo}: print in the Stata console a table with the numeric values of the average difference between groups and upper/lower bounds for the estimate for each of the variables in varlist.

{phang}{opt suppress}: (often used in combination with echo and tabsaving) the graph is not produced, while values can be still displayed in console or printed in file.

{phang}{opt ci(num)}: level of confidence. By default, ci(95) is specified

{opt Graph options}
{phang}{opt title(string)}, {opt subtitle(string)}: specify title and subtitle of the graph. By default, no title nor subtitle.

{phang}{opt lc(string)}, {opt lw(num)}, {opt lp(string)}: change the color, width and patters of the lines in confidence intervals.

{phang}{opt mc(string)}, {opt ms(num)}: change color and size of scatter points for point estimates and upper/lower bounds.

{phang}{opt sl(num)}, {opt sw(num)}: change length and width of segments at the edges of confidence intervals.

{phang}{opt seplc(string)}, {opt seplp(string)}, {opt seplw(num)}: change the color, width and pattern of the separation line (0 by default).

{phang}{opt labsize(num)}, {opt labangle(num)}: change size and angle orientation of variable labels on the graph.

{phang}{opt scheme(string)}: change the graph scheme.

{phang}{opt ysize(num)}, {opt xsize(num)}: change the axes sizes.

{phang}{opt saving(string)}: save the graph as a .gph file.

{phang}{opt replace}: replaces previous savings.

{phang}{opt tabsaving(string)}: saves the echo output as a TeX tabular (automatic replace).


{marker example}{...}
{title:Example}
{hline}
{pstd}Setup

{phang2}{cmd:clear}

{phang2}{cmd:set seed 0}

{phang2}{cmd:set obs 20000}

{phang2}{cmd:forv i = 1/30 }{c -(} 

{phang2}{cmd:    gen var_`i' = rnormal()}

{phang2}{cmd:    label var var_`i' "Dep Var `i'"}

{phang2}{cmd:}{c )-}

{phang2}{cmd:gen D = runiform() > 0.5}

{phang2}{cmd:tostring D, replace}

{pstd}Test all 30 variables generated by the previous routine by dummy string D.

{phang2}{cmd:dgraph var_*, by(D) long labangle(45) label scheme(white_tableau) title("Graph") reverse mc(black) msize(1) lw(0.2) ci(90) labsize(vsmall) saving(gr_sample) replace echo tabsaving(table)}

{hline}