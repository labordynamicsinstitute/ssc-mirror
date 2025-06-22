{smcl}
{* *! version 1.0.0 20jun2025 by Gutama Girja Urago}

{hline}
{hi:to_gregorian} — Convert Ethiopian date components to Gregorian Stata date
{hline}

{phang}
{cmd:to_gregorian} converts Ethiopian calendar year, month, and day variables into a single Stata-formatted Gregorian date (%td) variable.

{title:Syntax}

{phang}
{cmd:to_gregorian} {it:year month day} {ifin} {cmd:,} {opt gre_date(newvarname)}

{title:Description}

{pstd}
{cmd:to_gregorian} accepts three input variables representing an Ethiopian calendar date — specifically: year, month, and day — and generates a Gregorian calendar date in Stata's internal `%td` format.


{synoptset 25}{...}
{synopthdr}
{synoptline}
{synopt :{opt gre_date(newvarname)}} Optional. Specifies the name of the new variable to generate containing the Gregorian Stata date (%td). gre_date if missing.{p_end}
{synoptline}
{p2colreset}{...}

{title:Remarks}

{pstd}
The order of the input variables must be: Ethiopian year, Ethiopian month, Ethiopian day. All three must be numeric. The command performs validity checks and handles leap years based on the Ethiopian calendar system.

{title:Examples}

{phang}
{cmd:. use census_data, clear}

{phang}
{cmd:. to_gregorian eth_year eth_month eth_day, gre_date(gregorian_birth)}

{phang}
{cmd:. list eth_year eth_month eth_day gregorian_birth if _n <= 10}


{title:Saved results}

{pstd}
None. This command creates three new variables.

{title:Author}

{phang}
Gutama Girja Urago, Laterite Consulting PLC, guturago@laterite.com

{title:See also}

{pstd}
Related: {help to_ethiopian}, {help datetime}
