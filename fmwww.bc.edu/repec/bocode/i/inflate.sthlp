{smcl}
{* *! version 1.0.0  2022-01-06}{...}
{vieweralsosee "import fred" "help import fred"}{...}
{vieweralsosee "freduse" "help freduse"}{...}
{vieweralsosee "cpigen" "help cpigen"}{...}
{vieweralsosee "cpiget" "help cpiget"}{...}
{viewerjumpto "Syntax" "inflate##syntax"}{...}
{viewerjumpto "Description" "inflate##description"}{...}
{viewerjumpto "Updating the CPI series" "inflate##updatecpi"}{...}
{viewerjumpto "Options" "inflate##options"}{...}
{viewerjumpto "Examples" "inflate##examples"}{...}
{viewerjumpto "Author" "inflate##author"}{...}
{viewerjumpto "Acknowledgements" "inflate##acknowledgements"}{...}
{viewerjumpto "Also See" "inflate##alsosee"}{...}
{viewerjumpto "License" "inflate##license"}{...}

{title:Title}

{pstd}
{hi:inflate} {hline 2} Inflate variables to real dollars using the CPI-U series


{marker syntax}{title:Syntax}

{pstd} Inflate variables

{p 8 15 2}
{cmd:inflate}
{varlist} {ifin}{cmd:,}
{{cmdab:y:ear(}{it:{varname}}{cmd:)}| {opth start(int)}} {opth end(int)} [{it:options}]


{synoptset 35 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Main}
{synopt :{cmdab:y:ear(}{it:{varname}}{cmd:)}}year variable {p_end}
{synopt :{opth start(int)}}start date between 1913-today. {p_end}
{synopt :{opth end(int)}}end date between 1913-today. {p_end}

{syntab :More Precise Time Periods}
{synopt :{cmdab:h:alf(}{it:{varname}}{cmd:)}}half variable {p_end}
{synopt :{cmdab:q:uarter(}{it:{varname}}{cmd:)}}quarter variable {p_end}
{synopt :{cmdab:m:onth(}{it:{varname}}{cmd:)}}month variable {p_end}

{syntab : Variable Creation}
{synopt :{cmdab:gen:erate(}{it:{varlist}}{cmd:)}}specify the name of the new inflated variable {p_end}
{synopt :{opt replace}}replaces variable with the inflated version instead of making a new variable  {p_end}
{synopt :{opt keepcpi}}keeps cpi values and multiplier used to inflate the variables {p_end}

{syntab : CPI Data}
{synopt :{opt update}}updates CPI data to most recent release from FRED {p_end}
{synopt :{opt cpicheck}}opens the current CPI data file stored {p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:inflate} is a one-line command to inflate (or deflate) variables from any year to any other year based on the annual average Consumer Price Index All Urban, All Items U.S. City Average. {cmd:inflate} adjusts to the year specified in 
{cmd:end(}{it:{help int:int}}{cmd:)} using either a constant starting year in {opth start(int)} or a year variable that can change across observations in {cmdab:y:ear(}{it:{varname}}{cmd:)}. 
Inflation is calculated according to the simple formula: newvar = oldvar*(CPI_end / CPI_start or CPI_year). 

{pstd}
By default, {cmd:inflate} generates a new inflated variable suffixed with "_real" ordered after the original variable.

{pstd}
{cmd:inflate} relies on functionality introduced in Stata 16, specifically frame/frames. {cmd:inflate} requires {bf:{help freduse:freduse}} to pull CPI data from FRED.

{marker updatecpi}{...}
{title:Updating the CPI series}

{pstd}
{cmd:inflate} uses the {browse "https://fred.stlouisfed.org/series/CPIAUCNS":CPIAUCNS} series from FRED.

{phang}
To update the CPI series stored locally to the most recent release, run:

{pmore}
{stata inflate, update}

{pstd}
{cmd:inflate} stores the CPI series in a Stata dta file in {bf:{help sysdir:PLUS}}/i folder. 
This file contains annual, biannual, and quarterly averages in addition to the monthly values. 

{phang}
To view your current CPI data file, run:

{pmore}
{stata inflate, cpicheck}

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}{cmdab:y:ear(}{it:{varname}}{cmd:)} chooses the year variable used to match with starting CPI values. 
Inflates each observation to the end() date based on its year in the specified variable. 
The variable in {cmdab:y:ear(}{it:{varname}}{cmd:)} should be numeric and take values in 1913-current year.

{phang}{opth start(int)}  chooses a constant starting year as the base for inflation to the date in end(). 

{pmore} You can also choose a more precise time period as the start date including year-half, year-quarter, or year-month. 
More precise time periods are inputted as year then the time period type, then which half, quarter, or month. 
For example, to inflate from July 1985, input 1985M07 or 1985M7.

{phang}{opth end(int)}  chooses a constant end year to inflate to.  

{pmore} You can also choose a more precise time period as the end date including year-half, year-quarter, or year-month. 
More precise time periods are inputted as year then the time period type, then which half, quarter, or month. 
For example, to inflate to the first quarter of 2021, input 2021Q01 or 2021Q1.

{dlgtab:More Precise Time Periods}

{phang}{cmdab:h:alf(}{it:{varname}}{cmd:)} specifies the half variable used to match with starting CPI values. 
{cmdab:h:alf(}{it:{varname}}{cmd:)} must be used in combination with {cmdab:y:ear(}{it:{varname}}{cmd:)}. 
Inflates each observation to the end() date based on its year and half values in the specified variables. 
The variable in {cmdab:h:alf(}{it:{varname}}{cmd:)} should be numeric and take values 1 or 2.

{phang}{cmdab:q:uarter(}{it:{varname}}{cmd:)} specifies the quarter variable used to match with starting CPI values. 
{cmdab:q:uarter(}{it:{varname}}{cmd:)} must be used in combination with {cmdab:y:ear(}{it:{varname}}{cmd:)}. 
Inflates each observation to the end() date based on its year and quarter values in the specified variables. 
The variable in {cmdab:q:uarter(}{it:{varname}}{cmd:)} should be numeric and take values in 1-4.

{phang}{cmdab:m:onth(}{it:{varname}}{cmd:)}  specifies the month variable used to match with starting CPI values. 
{cmdab:m:onth(}{it:{varname}}{cmd:)}  must be used in combination with {cmdab:y:ear(}{it:{varname}}{cmd:)}. 
Inflates each observation to the end() date based on its year and month values in the specified variables. 
The variable in {cmdab:m:onth(}{it:{varname}}{cmd:)} should be numeric and take values in 1-12.

{dlgtab:Variable Creation}

{phang}{cmdab:gen:erate(}{it:{varlist}}{cmd:)} allows you to specify the new variable names, 
rather than naming each variable oldvariablename_real.

{phang}{opt replace} replaces the current variable with an inflated version, dropping the original variable.

{phang}{opt keepcpi} generates variables with the base CPI values, the end CPI value, and CPI_end / CPI_base as start_cpi, end_cpi, and inflator in addition to the new inflated variables.

{dlgtab:CPI Data}

{phang}{opt update} updates the CPI series to the most recent FRED release. 
Replaces CPI data in the {bf:{help sysdir:PLUS}}/i folder.

{phang}{opt checkcpi} opens the local CPI data that {cmd:inflate} is using in the current Stata session.

{marker examples}{...}
{title:Examples}

{marker example_binning}{...}
{pstd}{bf:Example 1: One variable with a constant start year}

{pstd}Load NLSW 1988 Data.{p_end}
{phang2}. {stata clear}{p_end}
{phang2}. {stata sysuse nlsw88}{p_end}

{pstd}Inflate the hourly wage from 1988 to 2020 $.{p_end}
{phang2}. {stata inflate wage, start(1988) end(2020)}{p_end}

{pstd}There is now an inflated wage variable called wage_real in the dataset ordered after the original variable.{p_end}

{pstd}To do the same thing but keep the CPI values used: {p_end}
{phang2}. {stata drop wage_real}{p_end}
{phang2}. {stata inflate wage, start(1988) end(2020) keepcpi}{p_end}

{pstd}{bf:Example 2: Multiple variables, inflate on year() and month()}

{pstd}Install freduse via ssc.{p_end}
{phang2}. {stata clear}{p_end}
{phang2}. {stata ssc install freduse}{p_end}

{pstd}Load monthly time series of the nominal M1 and M2 money stocks from FRED.{p_end}
{phang2}. {stata freduse M1SL M2SL}{p_end}

{pstd}Make year and month variables.{p_end}
{phang2}. {stata gen year = year(daten)}{p_end}
{phang2}. {stata gen month = month(daten)}{p_end}

{pstd}Inflate both series to 2020 $.{p_end}
{phang2}. {stata inflate M1SL M2SL, year(year) month(month) end(2020)}{p_end}

{marker author}{...}
{title:Author}

{pstd}Sean McCulloch{p_end}
{pstd}sean_mcculloch@brown.edu{p_end}

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}{cmd:inflate} would not be able to update the CPI series easily without FRED providing the CPI data series in their publicly available API and the functionality of David Drukker's {cmd:freduse}. 

{pstd}
FRED Citation: U.S. Bureau of Labor Statistics, Consumer Price Index for All Urban Consumers: All Items in U.S. City Average [CPIAUCSL], retrieved from FRED, Federal Reserve Bank of St. Louis

{marker alsosee}{...}
{title:Also See}

{pstd} 
Built in: {stata "help import fred": import fred}{p_end}
{pstd} 
Online: {stata "findit freduse": freduse (on SSC)}{p_end}
{pstd} 
Online: {stata "findit cpigen": cpigen (on SSC)}{p_end}
{pstd}
Online: {stata "findit cpiget": cpiget (on SSC)}{p_end}

{marker license}{...}
{title:License}

{pstd} 
MIT License

{pstd} 
Copyright (c) 2022 Sean McCulloch

{pstd} 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

{pstd} 
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

{pstd} 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

{pstd}
-----------------------