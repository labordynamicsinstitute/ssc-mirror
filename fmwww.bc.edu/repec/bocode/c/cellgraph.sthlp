{smcl}
{.-}
help for {cmd:cellgraph} {right:(Johannes F. Schmieder)}
{.-}

 
{title:Title}

{p 4 4 2}{cmd:cellgraph} {hline 2} Command to collapse data to cell level and graph the results.

{marker syntax}
{title:Syntax}

{p 8 15 2}
{cmd:cellgraph} {it:varlist} [{help if}] [{help in}] , {cmd:by(}{it:byvar1 byvar2}{cmd:)} [{cmd:,} {it:options}]

{p 4 4 2}where {it:varlist} is a variable or a list of variables. {it:byvar1} and {it:byvar2} are the variables that define the cells. 
The data is collapsed to cell level, where each cell is defined by {it:byvar1} if only one variable is provided or the combination of the values of {it:byvar1} and {it:byvar2} if two variables are provided.

  {it:options}{col 26}description
  {hline 70}
  {ul:Main}
    {cmd:name(}{it:graphname}{cmd:)} {col 34}provide a graph name (just like the name option in other graph commands).
    {cmd:stat(}{it:statistics}{cmd:)} {col 34}the cell statistic to be used. If not specified "mean" is assumed. 
    {col 34}Other possibilities: min, max, sum, sd, var, p10, p25, p50, p75, p90, etc.
    {cmd:list} {col 34}list collapsed data at the end of the command.
    {cmd:saving(}{it:filename}{cmd:, replace)}: {col 34}save collapsed data to a file.
    {cmd:baseline(}{it:string}{cmd:)}: {col 34}normalize series to this baseline observation (subtraction).

  {ul:Graph options}
    {cmd:lpattern}: {col 34}specify line pattern.
    {cmd:lpatterns(}{it:string}{cmd:)}: {col 34}specify multiple line patterns.
    {cmd:scatter}: {col 34}create a scatter plot.
    {cmd:line}: {col 34}create a line plot.
    {cmd:gradient}: {col 34}apply a color gradient as the gradient for the second by variable.
    {cmd:colors(}{it:col1; col2; ...}{cmd:)} {col 34}provide a list of colors to replace standard palette. 
    {col 34}Separate colors with semicolons. E.g. colors(dkgreen; cranberry; dknavy) or colors(234 40 100; 128 0 128).
    {cmd:lwidth(}{it:string}{cmd:)}: {col 34}specify line width.
    {cmd:*} {col 34}provide any twoway options to pass through to the call of the twoway command
    {col 34}see the example for why this might be useful. Can also be used to 
    {col 34}overwrite options that are given as standard, for example {cmd:title(My Title)}
    {col 34}would overwrite the standard title with "My Title"

  {ul: Marker options}
    {cmd:msymbols(}{it:symbol1 symbol2 ...}{cmd:)} {col 34}Change marker symbol where {it:symbol1 etc} is of {help symbolstyle}.
    {cmd:nomsymbol}: {col 34}do not use marker symbols.
    {cmd:msize(}{it:string}{cmd:)}: {col 34}specify marker size.
    {cmd:mcounts}: {col 34}display observation counts next to markers.

  {ul: Binning options}
    {cmd:binscatter(}{it:integer}{cmd:)}: {col 34}create a binned scatter plot with the specified number of bins.
    {cmd:bin(}{it:real}{cmd:)} {col 34}bin the data by the specified real number as bin width.
    {cmd:lfit}: {col 34}add a linear fit line for each plotted statistic.
    {cmd:coef}: {col 34}display regression coefficients.
    {cmd:45deg}: {col 34}add a 45-degree reference line.

  {ul: Confidence intervals}
    {cmd:noci} {col 34}don't display confidence intervals.
    {cmd:cipattern(}{it:string}{cmd:)}: {col 34}specify confidence interval pattern, either 'shaded' or 'lines'.
    {cmd:ciopacity(}{it:integer}{cmd:)}: {col 34}specify the opacity for confidence intervals (0-100).

  {ul: Controlling for covariates}
    {cmd:controls(}{it:varlist}{cmd:)}: {col 34}partial out specified covariates before collapsing.
    {col 34}Internally runs a regression of each outcome on {it:varlist} with
    {col 34}fixed effects for the first {it:by} variable, then subtracts the
    {col 34}fitted component due to the controls (mean-centered) so the plot
    {col 34}reflects variation net of controls. Requires {help reghdfe}.

  {ul: Legend options}
    {cmd:addnotes}: {col 34}Add notes with sample sizes to the legend.
    {cmd:samplenotes(}{it:string}{cmd:)}: {col 34}add sample notes to the plot.
    {cmd:nonotes} {col 34}don't display any notes in legend.
    {cmd:nodate} {col 34}don't display date in notes.

  {ul: Computational Tools}
    {cmd:gtools}: {col 34}use gtools for data processing.
    {cmd:ftools}: {col 34}use ftools for data processing.

  {ul: Category Ordering}
    {cmd:xorder(}{it:varname}{cmd:)}: {col 34}order categories of first by-variable by mean of {it:varname}.
    {col 34}Only works with categorical by-variables (string or with value labels).
    {col 34}Suboptions:
    {col 34}  {cmd:descending} - sort in descending order (highest first)
    {col 34}  {cmd:stat(}{it:statname}{cmd:)} - use specified statistic instead of mean
    {col 34}Example: {cmd:xorder(wage, descending stat(median))}

  {ul: Axis Label Options}
    {cmd:xlabel(}{it:suboptions}{cmd:)}: {col 34}additional x-axis label suboptions (e.g., ang(45), labsize(small)).
    {col 34}These are merged with the auto-generated category labels.
    {cmd:ylabel(}{it:suboptions}{cmd:)}: {col 34}additional y-axis label suboptions (e.g., format(%9.2f), labsize(small)).

  {hline 70}


{marker description}
{title:Description}

{p 4 4 2}Data is collapsed to cell level, where cells are defined by one or two categorical variables (byvar1 and byvar2) and cell means (or other statistics) of a third variable ({it:varname}) are graphed.

{marker requirements}
{title:Requirements}

{p 4 4 2}{cmd:cellgraph} requires Stata 18 or newer. The base command has no
user-written dependencies. Option {cmd:controls()} requires {help reghdfe};
option {cmd:gtools} requires {help gtools}; and option {cmd:ftools} requires
{help ftools}.

{marker examples}
{title:Examples}

{space 8}{hline 10} {it:Example 1 - Basic Plot: One outcome variable one by variable} {hline 10}
{cmd}{...}
{* example_start - ex1}{...}
          sysuse nlsw88, clear
          keep if grade>=8
          cellgraph wage, by(grade) 
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex1 using cellgraph.sthlp, preserve:click to run})}

{space 8}{hline 10} {it:Example 2 - One outcome variable, two by variables, marker counts} {hline 10}
{cmd}{...}
{* example_start - ex2}{...}
          sysuse nlsw88, clear
          gen logwage = log(wage) if grade>=8
          label var logwage "Log Wage"
          cellgraph logwage, by(grade union) mcounts
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex2 using cellgraph.sthlp, preserve:click to run})}

{space 8}{hline 10} {it:Example 3 - One outcome variable, two by variables, manual RGBcolors} {hline 10}
{cmd}{...}
{* example_start - ex3}{...}
          sysuse nlsw88, clear
          gen logwage = log(wage) if grade>=8
          label var logwage "Log Wage"
          cellgraph logwage, by(grade union) colors(128 0 128; 0 128 128)
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex3 using cellgraph.sthlp, preserve:click to run})}

{space 8}{hline 10} {it:Example 4 - Multiple Statistics one by variable, color gradient} {hline 10}
{cmd}{...}
{* example_start - ex4}{...}
          sysuse nlsw88, clear
          gen logwage = log(wage) if grade>=8
          label var logwage "Log Wage"
          cellgraph logwage, by(grade) stat(p10 p25 p50 p75 p90) gradient 
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex4 using cellgraph.sthlp,  preserve:click to run})}


{space 8}{hline 10} {it:Example 5 - Two Outcomes, two statistics} {hline 10}
{cmd}{...}
{* example_start - ex5}{...}
          sysuse nlsw88, clear
          cellgraph wage hours if grade>=8 , by(grade) stat (mean median) mcounts ciopacity(20)
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex5 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 6 - Binned Scatterplot with Linear Fit} {hline 10}
{cmd}{...}
{* example_start - ex6}{...}
          sysuse auto , clear
          cellgraph mpg, by(weight) binscatter(20) scatter noci lfit coef legend(off)
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex6 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 7 - Binned Scatterplot with 2 Groups} {hline 10}
{cmd}{...}
{* example_start - ex7}{...}
          sysuse auto , clear
          cellgraph mpg, by(weight foreign) binscatter(20) scatter noci lfit coef
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex7 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 8 - Ordering Categories by Outcome Variable} {hline 10}
{cmd}{...}
{* example_start - ex8}{...}
          sysuse nlsw88, clear
          cellgraph wage, by(occupation) xorder(wage, descending)
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex8 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 9 - Rotated X-axis Labels} {hline 10}
{cmd}{...}
{* example_start - ex9}{...}
          sysuse nlsw88, clear
          cellgraph wage, by(occupation) xorder(wage, descending) xlabel(ang(45))
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex9 using cellgraph.sthlp,  preserve:click to run})}

{space 8}{hline 10} {it:Example 10 - Custom Axis Label Formatting} {hline 10}
{cmd}{...}
{* example_start - ex10}{...}
          sysuse nlsw88, clear
          cellgraph wage, by(occupation) xlabel(ang(45) labsize(small)) ylabel(format(%9.2f))
{* example_end}{...}
{txt}{...}
{space 8}{hline 80}
{space 8}{it:({stata cellgraph_run ex10 using cellgraph.sthlp,  preserve:click to run})}


{marker author}
{title:Author}

{p}
Johannes F. Schmieder, Boston University, USA

{p}
Email: {browse "mailto:johannes@bu.edu":johannes@bu.edu}

Comments welcome!

{marker also}
{title:Also see}

{p 0 21}
On-line:  help for {help collapse}, {help tabstat}
{p_end}
