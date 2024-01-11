{smcl}
{* *! eth_to_eth2grecal 1.0}
{cmd:help eth2grecal}
{hline}

{title:Title}

{phang}
{bf:eth2grecal} {hline 2} Convert Ethiopian calendar dates to Gregorian calendar dates

{title:Syntax}

{p 8 17 2}
{cmdab:eth2grecal}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth et_year(varname)}}specifies Ethiopian calendar year {it:varname}{p_end}
{synopt:{opth et_month(varname)}}specifies Ethiopian calendar month {it:varname}{p_end}
{synopt:{opth et_day(varname)}}specifies Ethiopian calendar day {it:varname}{p_end}

{title:Description}

{pstd}
{cmd:eth2grecal} converts dates from the Ethiopian calendar to the Gregorian calendar. It
creates new variables for the Gregorian year, month, and day based on the provided 
Ethiopian date variables. The conversion is accurate for Ethiopian calendar dates within 
the Gregorian year range of 1901-2099.


{title:Options}

{dlgtab:Main}

{phang}
{opth et_year(varname)} specifies the variable containing the Ethiopian calendar year.

{phang}
{opth et_month(varname)} specifies the variable containing the Ethiopian calendar month.

{phang}
{opth et_day(varname)} specifies the variable containing the Ethiopian calendar day.

{title:Background: The Ethiopian calendar}

{pstd}
The Ethiopian calendar, also known as the Ge'ez calendar, is closely related to the Coptic
and Julian calendars but has its own unique features. It comprises 13 months: 12 months
each consisting of 30 days, and an additional month, Pagume, with 5 days (6 days in leap years).
Similar to the Julian calendar, the Ethiopian calendar has a leap year every four years without
exception, contrasting with the Gregorian calendar's more complex leap year system. The Ethiopian
New Year typically falls on September 11th in the Gregorian calendar, or September 12th in
Gregorian leap years. Depending on the time of year, the Ethiopian calendar is seven or 
eight years behind the Gregorian calendar.

{title:Remarks}

{pstd}
The command checks for the existence of g_year, g_month, and g_day variables in the dataset before running. 
If these variables already exist, the command will not proceed to prevent overwriting existing data.

{p 4 4 2}
The conversion is accurate for Ethiopian calendar dates within the Gregorian year range of 1901-2099. 
This is because the Ethiopian and Gregorian calendars differ in their leap year calculations
when it comes to centurial years: 1900 and 2100 are leap years 
in the Ethiopian calendar but not in the Gregorian calendar, leading to potential offsets in date 
conversions outside this range.

{p 4 4 2}
The command does not convert the date if:

    a) the Ethiopian calendar date is outside of the Gregorian year range of 1901-2099;
    b) the Ethiopian calendar month is not within the range of 1-13;
    c) the Ethiopian calendar day is not within the range of 1-30 for the 1st-12th months, or not within the range of 1-6 for the 13th month.

{title:Example}

{pstd}
Suppose you have a dataset with Ethiopian calendar date variables named e_year, e_month, and e_day. To convert these dates to the Gregorian calendar, you would use the following command:

{pstd}
. eth2grecal, et_year(e_year) et_month(e_month) et_day(e_day)

{pstd}
This command will create three new variables in your dataset: g_year, g_month, and g_day, which represent the Gregorian year, month, and day, respectively.

{title:Author}

{phang} Kalle Hirvonen, International Food Policy Research Institute (IFPRI), k.hirvonen@cgiar.org

{title:Last updated}

{phang}4 January 2024 (25 Tahsas 2016 in Ethiopian calendar)
