{smcl}
{* *! version 2.0.1  10october2023}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:datefrac} {hline 2} Turn dates into fractional years}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

	{cmd:datefrac} {it:datevar} {cmd:,} {opth gen:erate(newvar)} [{cmd:order(}{it:dateorder}{cmd:)}]

{synoptset 32 tabbed}{...}
{marker datefrac_options}{...}
{synopthdr :datefrac_options}
{synoptline}
{synopt :{opth gen:erate(newvar)}}generate numeric {it:newvar} corresponding to string or numeric {it:datevar}{p_end}
{synopt :{cmd:order(}{it:dateorder}{cmd:)}}identify the day/month/year order of string {it:datevar}, such as DMY or MDY{p_end}
{synoptline}
{phang}
{it:datevar} is an existing variable in either string or Stata date format representing an exact calendar date.

{phang}
{it:dateorder} is the {it:s2} block that denotes the day, month, and year ordering/format of {it:datevar} in accordance with {help f_date}.
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{opt datefrac} takes any variable that represents an exact date and generates a numeric variable representing the fraction of that year that has passed at the beginning of that date by taking the number of days since 1 January of a given year, dividing that number by 365, and adding the resulting fraction to the given year. For example, datefrac assigns the value 2020.000 (2020 + 0/365) to the date 1 January 2020 and the value 1999.17260 (1999 + 63/365) to the date 4 March 1999. It also accounts for leap years if the year is a multiple of 4, assigning the value 2000.17486 (2000 + 64/366) to the date 4 March 2000.

{pstd}
The command is not designed for variables such as monthly dates (March 1999) that do not have information on day of year, but it will run on date-time variables that can provide information on day, month, and year.


{marker options}{...}
{title:Options}

{phang}
{opth gen:erate(newvar)} is required. It specifies the name of the numeric variable that datefrac creates.

{phang}
{cmd:order(}{it:dateorder}{cmd:)} is required if {it:datevar} is still a string variable that has not been converted to Stata date format. It is directly equivalent to {it:s2} in the help file for {help f_date}. If {it:datevar} is a variable that has already been converted to Stata date format, this option is not required.


{marker example}{...}
{title:Example}

{pstd}
If I had a string variable called "birthdate" with observations in the format "04 March 1999" and wanted to create a numeric variable called "birthdatefrac", I would use the following command:

{phang2}{cmd:. datefrac birthdate, gen(birthdatefrac) order(DMY)}

{pstd}
but if instead the variable "birthdate" was already in Stata date format, I could omit the {cmd:order()} option:

{phang2}{cmd:. datefrac birthdate, gen(birthdatefrac)}

{pstd}
and get the same result.


{marker remarks}{...}
{title:Remarks}

{pstd}
If you have any suggestions for improving this command or would like to collaborate on some similar project, email me at labhours@tmorg.org and we'll get in contact!

{pstd}