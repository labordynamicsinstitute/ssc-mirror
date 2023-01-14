{smcl}
{* 07 Jan 2023}{...}
{hline}
help for {hi:rowsum}
{hline}

{title:Sum by row}

{title:Syntax}

{pstd}
{cmd: rowsum} {it: namelist}, {opt sumlist(varlist)} [{opt new(str)} {opt keep} {opt example(varlist)}]
{p_end}

{title:Description}

{pstd}
{cmd:rowsum} sums the values of multiple observations. It then generates a new observation and assigns the summed value to it. {break}
{it:namelist} needs at least 3 inputs: one identifier (a variable) and at least two observation names. These names cannot contain space (e.g. <North Carolina> will be regarded as <North> and <Carolina>). {break}
The new observation with summed values will be flagged with {bf:_rowsum}. {break}
{p_end}
 
{title:Options}

{pstd}
{opt sumlist(varlist)} specifies the variable list to sum up. Do not include string or categorical variables. {break} 
The program will stop if string variables are included. The program will keep running if categorical variables are included but will give a warning. {break}
If {it:varlist} is very long, <{cmd:ds, not}> could be used to generate a list of all variables except the ones specified. {break}
Values of unspecified variables (including string variables and categorical variables) of the new observation is the same as the first input observation. 
{p_end}

{pstd}
{opt new(str)} gives the new observation a new name. If no new name is given, the name of the first input observation will be used.
{p_end}

{pstd}
{opt keep} keeps the original observations. It may result in duplications if no new name is given. By default, involved observations are dropped after summing up.
{p_end}

{pstd}
{opt example(varlist)} gives examples of the summing result. By default, it uses the first variable in the {bf:sumlist()}. The user can specify variables to generate examples.
{p_end}

{title:Examples}

{pstd}
Sum the population of North and South Carolina. Generate a new observation called "Carolina_Total" and drop the original observations. Because names in <state> contains space, we need to use <state2> as the identifier.
{p_end}
{phang}
{inp:.}{stata "sysuse census, clear":  sysuse census, clear}
{p_end}
{phang}
{inp:.}{stata "rowsum state2 NC SC, sumlist(pop) new(Carolina_Total)":  rowsum state2 NC SC, sumlist(pop) new(Carolina_Total)}
{p_end}
{pstd}
We can check the result manually. A new observation called "Carolina_Total" is generated. {break}
The values of string variable <state> and categorical variable <region> are kept the same as the first input observation <NC>:
{p_end}
{phang}
{inp:.}{stata "list state2 state region pop _rowsum":  list state2 state region pop _rowsum}
{p_end}

{pstd}
Sum all variables of North and South Carolina. Generate a new observation called "Carolina_Total" and the keep the original observations. Use <pop> and <marriage> as examples. 
{p_end}
{phang}
{inp:.}{stata "sysuse census, clear":  sysuse census, clear}
{p_end}
{phang}
{inp:.}{stata "ds state state2 region, not":  ds state state2 region, not} 
{p_end}
{phang}
{inp:.}{stata "rowsum state2 NC SC, sumlist(`r(varlist)') new(Carolina_Total) keep example(pop marriage)":  rowsum state2 NC SC, sumlist(`r(varlist)') new(Carolina_Total) keep example(pop marriage)}
{p_end}
{pstd}
Check the result manually:
{p_end}
{phang}
{inp:.}{stata "list state2 state region pop _rowsum":  list state2 state region pop _rowsum}
{p_end}

{title:Author}

{pstd}
{bf:Pengzhan, Qian}. {break}
E-mail: {browse "mailto:p.qian@qmul.ac.uk":p.qian@qmul.ac.uk}. {break}
{p_end}