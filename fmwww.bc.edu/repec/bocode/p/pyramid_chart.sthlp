{smcl}
{* *! version 1.1}{...}
{hline}
help file for {cmd:pyramid_chart}
{hline}

{title:Title}
{p 4 8 2} {hi:pyramid_chart}
{p_end}

{title:Description}
{p 4 4 2} {cmd:pyramid_chart} generates a population pyramid chart for a given numeric variable, with categories defined by two categorical variables. The chart displays the distribution of the numeric variable across the levels of the first categorical variable, split by the levels of the second categorical variable.
{p_end}

{title:Syntax}
{p 4 4 2} {cmd:pyramid_chart} {it:varname} {ifin} , {cmd:over(}{it:varname}{cmd:)} {cmd:by(}{it:varname}{cmd:)} {cmd:dec(}{it:integer}{cmd:)} [{help twoway_options}]
{p_end}

{title:Options}
{phang} {cmd:over(}{it:varname}{cmd:)} specifies the categorical variable that defines the y-axis categories.{p_end}
{phang} {cmd:by(}{it:varname}{cmd:)} specifies the categorical variable that splits the data into two groups (e.g., male and female).{p_end}
{phang} {cmd:dec(}{it:integer}{cmd:)} specifies the number of decimal places for the percentage labels on the bars of the pyramid. Note that this does not affect the decimal points in the x axis which are fixed as integers.{p_end}

{title:Remarks}
{p 4 4 2} {cmd:pyramid_chart} can only accept one variable in the {bf:varname} following the {cmd:pyramid_chart} command.{p_end}
{p 4 4 2} The {cmd:pyramid_chart} command requires that the levels of the variable specified in the {bf:by()} option be labeled, with labels for categories 1 and 2.{p_end}
{p 4 4 2} It is important that the dataset has a numeric variable in {bf:varname}, a categorical variable in {bf:over()}, a categorical variable in {bf:by()}, and the dataset is {bf:long}. If it is wide, first perform {help reshape} before calling the {cmd:pyramid_chart} command.{p_end}

{title:Examples}
{p 4 8 2} {ul:{bf:Example 1:}}{p_end}
{p 4 8 2} The following example reshapes the dataset into a long dataset containing the three required variables: {bf:population}, {bf:sex}, and {bf:agegrp}.{p_end}

{input}{space 8} sysuse pop2000.dta, clear
{input}{space 8} keep agegrp maletotal femtotal
{input}{space 8} rename maletotal population1
{input}{space 8} rename femtotal population2
{input}{space 8} reshape long population, i(agegrp) j(sex)
{input}{space 8} label define sexlbl 1 "Male" 2 "Female"
{input}{space 8} label values sex sexlbl
{input}{space 8} label variable population "Population"
{input}{space 8} label variable sex "Sex"
{input}{space 8} pyramid_chart population, over(agegrp) by(sex) dec(0)

{text}

{p 4 8 2} {ul:{bf:Example 2:}}{p_end}
{p 4 8 2} The following example reshapes the dataset into a long dataset containing the three required variables: {bf:population}, {bf:sex}, and {bf:agegrp}, and then adds some options from the {help twoway_options} for additional formatting.{p_end}

{input}{space 8} sysuse pop2000.dta, clear
{input}{space 8} keep agegrp maletotal femtotal
{input}{space 8} rename maletotal population1
{input}{space 8} rename femtotal population2
{input}{space 8} reshape long population, i(agegrp) j(sex)
{input}{space 8} label define sexlbl 1 "Male" 2 "Female"
{input}{space 8} label values sex sexlbl
{input}{space 8} label variable population "Population"
{input}{space 8} label variable sex "Sex"
{input}{space 8} pyramid_chart population, over(agegrp) by(sex) dec(1) title("Population Pyramid for year 2000") subtitle("in percentages") xtitle("Percentage") ytitle("Age groups")

{text}
{title:Authors}
{p 4 4 2} Written by Masud Rahman, Economist, UNHCR. For queries, DM: http://www.twitter.com/masudtweets {p_end}

{title:Also see}
{p 4 4 2} {help graph}, {help twoway}, {help twoway_options} {help reshape}{p_end}

{title:Contributing}
{p 4 4 2}{cmd: pyramid_chart} is open for development on {browse "https://github.com/masud90/pyramid_chart":GitHub} under MIT license. Feel free to request features, or contribute to the package by submitting pull requests. {p_end}