{smcl}
{* version 2.0.0  16aug2024}{...} 
{cmd:help fredusex}
{hline}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{hi:fredusex} {hline 2}}Import Federal Reserve economic data, 2024 HTML format{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 16 2}
{opt fredusex} {it:series_1} [{it:series_2} ... {it:series_k}] 
   {cmd:,} {opt data(string)} [{cmd:replace}]


{title:Description}

{pstd}
{cmd:fredusex} imports data from the 2024 HTML format of the Federal Reserve Economic Data (FRED)
repository into Stata

{pstd}
The FRED repository at {browse "http://fred.stlouisfed.org/"} 
contains more than 824,000 U.S. economic time series from 114 sources.  Each time series is
stored in a separate file that also contains a string-date variable and header
with information about the series.  {cmd:fredusex} imports series into a Stata dataset.


{title:Options}

{phang}{cmd:data(}{it:string}) is a required option that specifies the name of the Stata dataset to be created in the current working directory.
You need not include the .dta extension. If the file exists, the {cmd:replace} option
must be used. 

{phang}{cmd:replace} can be used to remove the existing output file and rewrite it.


{title:Remarks}

{pstd}
This routine updates David Drukker's very useful {cmd:freduse} routine, published in the {it:Stata Journal}
6(3) and updated in 15(3). Recent changes to the underlying text format used by FRED caused
the freduse routine to fail. Despite Stata's built-in {cmd:import fred} capability, it is useful to
have a simple way of accessing FRED data without needing an API key.

{pstd} 
As of 26 September 2024, Federal Reserve Board authors have revised Drukker's original routine,
so that the version of {cmd:freduse} on the SSC Archive works again. {cmd:fredusex} displays the variables' characteristics
in the results window; {cmd:char list} will do the same in {cmd:freduse}. {cmd:fredusex} creates 
a new .dta file, while {cmd:freduse} requires that existing data are cleared.
 
{pstd}
The names of the FRED series are not case sensitive. They will be changed to upper case,
as used in FRED. 
All series on FRED are associated with daily dates in a string format as variable {cmd:daten}.
The {cmd:date} variable is a Stata variable containing this daily date. For cnnvenience,
Stata variables {cmd:qdate} and {cmd:mdate} are the quarterly and monthly equivalents of the daily
date variable. Annual data are always aligned with January 1, while quarterly (monthly) data are 
aligned with the first day of the calendar quarter (month).


{title:Examples}

{pstd}
{cmd:. fredusex gdp mehoinusmaa646n unrate mich cpiaucsl, data(fredtest) }


{title:Author}

{pstd}
   Kit Baum{break}
   Boston College{break}
   baum@bc.edu
{p_end}
