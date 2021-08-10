{smcl}
{* 30apr2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{title:Title}

{pstd}{bf:ddt} {hline 2} Date/DateTime Transformations

{title:Syntax}

{phang2}{cmd:ddt} [{it:{help varelist}}] [{cmd:, dt}[{cmd:(}{it:datetimevars}{cmd:)}] {opt df:ormat(dateformat)} {opt dtf:ormat(datetimeformat)} {opt str:ingorder(date-elements)} {opt go} ]

{title:Description}

{pstd}{cmd:ddt} performs three related tasks in handling date/datetime data:

{phang2}o-{space 2}converts string to numeric{p_end}
{phang2}o-{space 2}converts between date and datetime{p_end}
{phang2}o-{space 2}assigns formats to final variables{p_end}

{pstd}Right now, all of the defaults are fixed:

{phang2}o-{space 2}If no {it:{help varelist}} is specified, variables matching {cmd:*date *datetime} are used.{p_end}
{phang2}o-{space 2}If {cmd:dt} is specified without parameters, {cmd:dt(*datetime)} is used.{p_end}
{phang2}o-{space 2}If no formats are specified, {cmd:df(%tdYYY-MM-DD)}, {cmd:dtf(%tcYYYY-MM-DD HH:MM:SS)}, and {cmd:str(YMD)} are used.

{pstd}Transformations use the non-leap-second-correcting functions, because otherwise the transformed display would not match the original.

{pstd}{cmd:ddt} shows a report with 3 example rows for every selected field, showing the original and transformed values.
If the option {opt go} is not specified, it will {it:only} present this report (headed {cmd:preview}), and {it:will not} perform the transformations.


{title:Options}

{phang}{cmd:dt}[{cmd:(}{it:datetimevars}{cmd:)}] specifies variables (from those in {it:{help varelist}}) that should hold {bf:datetime} data.

{phang}{opt df:ormat(dateformat)} specifies the format for variables that hold {bf:date} data. It is a standard Stata format string (including {cmd:%}).

{phang}{opt dtf:ormat(datetimeformat)} specifies the format for variables that hold {bf:datetime} data. It is a standard Stata format string (including {cmd:%}).

{phang}{opt str:ingorder(date-elements)} specifies the ordering of date elements in original string data (ie, {cmd:Y}, {cmd:M}, and {cmd:D}, in any order). String datetime data is assumed to be the same, followed by {cmd:hms}.

{phang}{opt go} specifies actually transforming the data. If {opt go} is not specified, {cmd:ddt} will give a preview of the results without actually changing anything.

{title:Remarks}

{pstd}{cmd:ddt} uses the size of the original data to determine whether something is date or datetime. It could possibly be wrong in some circumstances (eg, you have datetime values, but all of them occur within twelve hours of new-years 1960).
Hopefully the preview would reveal any errors.


{title:Examples}

{p2colset 4 25 25 2}
{p2col:{cmd:ddt}}transforms all variables ending in {cmd:date} or {cmd:datetime} to (numeric) {bf:date}

{p2col:{cmd:ddt, dt}}transforms all variables ending in {cmd:date} to {bf:date}, and all variables ending in {cmd:datetime} to {bf:datetime}.

{p2col:{cmd:ddt a-e, dt(a c e)}}transforms variables {cmd:a}, {cmd:c}, {cmd:e} to {bf:datetime}, and variables {cmd:b} and {cmd:d} to {bf:date}.

INCLUDE help also_lowy

