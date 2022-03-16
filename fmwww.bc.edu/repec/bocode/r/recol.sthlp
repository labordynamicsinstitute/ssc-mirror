{smcl}

{title:Title}

{phang}
{bf:recol} {hline 2} Dynamically resize columns in Stata's data browser


{title:Syntax}

{p 8}
{cmd:recol} [{varlist}] [{cmd:,} {it:options}]

{synoptset}{...}
{synopthdr}
{synoptline}

{p2coldent:{opth m:axwidth(#)}}The maximum allowable column width, in characters, for each {it:var} in {it:varlist}.
When {cmd:maxwidth} is not specified, a default value of 50 is used.

{p2coldent:{opth u:serows(#)}}To achieve faster execution, {cmd:recol} only examines the first 100
rows and uses the content of those rows to infer the appropriate width of the column.
The {cmd:userows} option indicates how many rows to use instead.

{p2coldent:{opt f:ull}}To achieve faster execution, {cmd:recol} only examines the first 100 rows and uses the content of those rows to infer the appropriate width of the column.
The {cmd:full} option causes the program to examine all rows to infer the appropriate width
of the column.
This may be useful if there are many missing values at the beginning of the data, but the program will slow down with larger datasets.
If {cmd:full} and {cmd:userows} are both specified, {cmd:full} is used and {cmd:userows} is ignored.

{p2coldent:{opt c:ompress}}Some users frequently pair the {cmd:compress} command with {cmd:recol}. Use this option to compress the data at the end.

{synoptline}


{title:Description}

{pstd}{cmd:recol} examines your variable names and the content of your variables in order to determine the appropriate display widths for your columns in the data browser.
It works with both string and numeric variables.

{pstd}For example, suppose you have a rather long variable name ({it:your_long_variable_name}) which gets truncated by Stata when displaying your data in the Browser ({it:your_long_v~e}).
Rather than manually clicking and dragging to resize the column every time, {cmd:recol} widens your columns automatically to display the full variable names.

{pstd}A common issue with string variables is excessively long content.
This can result in jumpy horizontal scrolling from columns that are too wide.
{cmd:recol} reduces these column widths to a predefined max width, resulting in easier data browsing.

{pstd}Submit issues on the {browse "https://github.com/justan0theruser/recol":GitHub page}.


{title:Examples}

{hline}
{pstd}Dynamically resize all columns in the data{p_end}
{phang}{cmd:. recol}{p_end}

{pstd}Dynamically resize a subset of columns with a max width of 25 characters{p_end}
{phang}{cmd:. recol var1 var2 var3, max(25)}{p_end}

{pstd}Dynamically resize a single column, using the first 2,000 observations to determine width{p_end}
{phang}{cmd:. recol var1, userows(2000)}{p_end}

{pstd}Dynamically resize a single column, using the full set of observations to determine width{p_end}
{phang}{cmd:. recol var1, full}{p_end}

{pstd}Dynamically resize all columns and then compress the data{p_end}
{phang}{cmd:. recol, c}{p_end}
{hline}


{title:Author}

Tyson Van Alfen
Email: tyson@vanalfen.io
Website: https://vanalfen.io
