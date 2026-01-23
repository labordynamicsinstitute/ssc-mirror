{smcl}
{* *! version 1.0.0 20jan2026}{...}
{cmd:help reshapelabel}

{title:Title}

{p 4 4 2}
{cmd:reshapelabel} — Reshape long to wide using a string j-variable and
apply j-variable values as column labels

{title:Syntax}

{p 8 15 2}
{cmd:reshapelabel},
{cmd:metric(}{it:varname}{cmd:)}
{cmd:jvar(}{it:varname}{cmd:)}
{cmd:ivar(}{it:varlist}{cmd:)}

{title:Description}

{p 4 4 2}
{cmd:reshapelabel} reshapes data from long to wide when the j-variable
is a string (including strings with spaces) and applies the string values
of the j-variable as variable labels on the reshaped wide variables.

{p 4 4 2}
This command is a safe wrapper around {cmd:reshape wide} that:
{p_end}
{p 8 8 2}
• accepts a string j-variable{break}
• encodes the j-variable internally{break}
• reshapes wide using numeric codes{break}
• applies the original string values as variable labels{break}
• verifies that the data are uniquely indexed prior to reshaping
{p_end}

{title:Options}

{dlgtab:Options}

{phang}
{cmd:metric(}{it:varname}{cmd:)}
specifies the variable to be reshaped wide.

{phang}
{cmd:jvar(}{it:varname}{cmd:)}
specifies the string variable whose distinct values define the wide columns.
This variable may contain spaces.

{phang}
{cmd:ivar(}{it:varlist}{cmd:)}
specifies the variables that uniquely identify observations in long form.

{title:Remarks}

{p 4 4 2}
The command requires that the combination of {cmd:ivar()} and {cmd:jvar()}
uniquely identifies the dataset. If this condition is not met, the command
exits with error code 459 and displays a custom error message.

{p 4 4 2}
Internally, the command sorts by the j-variable before encoding to ensure
that the numeric codes assigned to j-variable values are stable and
independent of observation order.

{p 4 4 2}
After reshaping, the resulting wide variables are labeled using the original
string values of the j-variable.

{title:Examples}

{p 4 4 2}
Basic usage:

{p 8 8 2}
{cmd:. input str1 firm str10 month sales}
{cmd:. "A" "Jan 2024" 10}
{cmd:. "A" "Feb 2024" 12}
{cmd:. "B" "Jan 2024"  8}
{cmd:. "B" "Feb 2024"  9}
{cmd:. end}

{p 8 8 2}
{cmd:. reshapelabel, metric(sales) jvar(month) ivar(firm)}

{p 4 4 2}
This produces variables {cmd:sales1}, {cmd:sales2}, etc., labeled
{cmd:"Jan 2024"}, {cmd:"Feb 2024"}, and so on.

{title:Returned results}

{p 4 4 2}
None.

{title:Errors}

{p 4 4 2}
459 — The i-variable(s) do not uniquely index the dataset.

{title:Author}

{p 4 4 2}
Written by {it:Arthi Thiruppathi}.

{p 4 4 2}
{help reshape}
