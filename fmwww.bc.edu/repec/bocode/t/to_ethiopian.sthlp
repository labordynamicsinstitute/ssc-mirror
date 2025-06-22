{smcl}
{* *! version 1.0.0 20jun2025 by Gutama Girja Urago}

{hline}
{hi:to_ethiopian} — Convert Gregorian Stata dates to Ethiopian calendar
{hline}

{phang}
{cmd:to_ethiopian} converts a Gregorian date variable in Stata (%td, %tc or %tC format) into Ethiopian calendar year, month, and day components.

{title:Syntax}

{phang}
{cmd:to_ethiopian} {it:varname} {ifin} [ {cmd:,} options]

{title:Description}

{pstd}
{cmd:to_ethiopian} takes a single Gregorian date variable formatted as {cmd:%td}, {cmd:%tc} or {cmd:%tC} and generates three new variables containing the Ethiopian year, month, and day. 

{pstd}
The Ethiopian calendar differs from the Gregorian calendar in structure and new year alignment. This command ensures accurate conversion using built-in calendar rules, including leap year adjustments.

{synoptset 25}{...}
{synopthdr}
{synoptline}
{synopt :{opt eth_year(newvarname)}} Optional. Specifies the name of the new variable to generate for the Ethiopian year. eth_year if missing. {p_end}
{synopt :{opt eth_month(newvarname)}} Optional. Specifies the name of the new variable to generate for the Ethiopian month. eth_month if missing. {p_end}
{synopt :{opt eth_day(newvarname)}} Optional. Specifies the name of the new variable to generate for the Ethiopian day. eth_day if missing. {p_end}
{synoptline}
{p2colreset}{...}


{title:Remarks}

{pstd}
The input variable must be a Stata date variable with {cmd:%td}, {cmd:%tc} or {cmd:%tC} format. The output variables will be generated as integers representing the corresponding Ethiopian date components.

{title:Examples}

{phang}{cmd:. use household_survey, clear}

{phang}{cmd:. to_ethiopian interview_date, eth_year(eyear) eth_month(emonth) eth_day(eday)}

{phang}{cmd:. list interview_date eyear emonth eday if _n <= 10}


{title:Saved results}

{pstd}
None. This command creates three new variables.

{title:Author}

{phang}
Gutama Girja Urago, Laterite Consulting PLC, guturago@laterite.com

{title:See also}

{pstd}
Related: {help to_gregorian}, {help datetime}
