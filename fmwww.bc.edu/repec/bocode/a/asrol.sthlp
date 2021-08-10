{smcl}
{right:version:  2.0.0}
{cmd:help asrol} {right:21 Feb 2017}
{hline}

{title:Title}

{p 4 8}{cmd:asrol}  -  Generates rolling-window descriptive statistics {p_end}


{title:Syntax}

{p 4 6 2}
{cmd:asrol}
varlist [if] [in], {cmd:} 
{cmdab:s:tat(}{it:statistic}{cmd:)}
{cmdab:w:indow(}{it:[rangevar] # }{cmd:) [}
{cmdab:g:en(}{it:newvar}{cmd:)}
{cmdab:sm:iss}{cmd:}
{cmdab:by:(}{it:varlist}{cmd:)}
{cmdab:min:imum:(}{it: # }{cmd:) ]}

{p 4 4 2}
The underlined letters signifies that users can abbreviate the full words only to the underlined letters. {p_end}



{title:Description}

{p 4 4 2} {cmd: asrol} calculates descriptive statistics in a user's defined rolling-window.{cmd: asrol} efficiently handles all types of data structures such as  
data declared as time series or panel data, undeclared data, or data with duplicate values, missing values or data having time series gaps. 
{p_end}

{p 4 4 2} {cmd: asrol} uses efficient codings in the Mata language which makes this version extremely fast as compared to other available programs. The speed efficiency matters more in large data sets. This version also overcomes limitation of the earlier version of {help asrol} which could calculate statistics
in a rolling window of 104.{cmd: asrol} can accoomodate any length of the rolling window.{p_end}


{title:Syntax Details}

{p 4 4 2}
The program has 2 required options: They are: {break}
1. {opt s:tat}: to specify required statistics. The following statistics are allowed; {p_end}

{p 8 8 4} {opt sd } 	for standard deviation {p_end}
{p 8 8 2} {opt mean } 	for mean {p_end}
{p 8 4 4} {opt sum} 	for sum or total {p_end}
{p 8 8 2} {opt median} 	for median {p_end}
{p 8 8 2} {opt count} 	for counting number of non-missing observations in the given window {p_end}
{p 8 8 2} {opt missing} for counting number of missing observations in the given window {p_end}
{p 8 8 2} {opt min} 	for finding minimum value in the given window {p_end}
{p 8 8 2} {opt max} 	for finding maximum value in the given window {p_end}
{p 8 8 2} {opt first} 	for finding the first observation in the given window {p_end}
{p 8 8 2} {opt last} 	for finding the last observation in the given window {p_end}

 
{p 4 4 2} 2. {opt w:indow}: specifies length of the rolling window.  The {opt w:indow} option accepts up to two arguments. If we have already declared our data as panel or time series data, {cmd: asrol} will automatically
pick the time variable. In such cases, option {opt w:indow} can have one argument, that is the length of the window, e.g., window(5). If our data is time series or panel, then we have to specify
the time variable as first argument of the option {opt w:indow}. For example, if our time variable is year and we want a rolling window of 5, then option {opt w:indow} will look like: 
window(year 5) {p_end}


{title:Optional Options}

{p 4 4 2} 1. {opt g:en}: This is an optional option to generate new variable, where the variable name is enclosed in paranthesis after {opt g:en}. 
 If we do not specify this option, arsol2 will automatically generate a new variable with the name format of {it:stat_varname}. {p_end}

{p 4 4 2} 2. {opt sm:iss} {break}
 The option {opt sm:iss} forces asrol to omit required statistics at the start of the rolling window. Compare results 
 of {opt Example 1} below with the results of {opt Example 3} where we use option {opt sm:iss}. 
 In {opt Example 3}, asrol finds mean starting with the fourth observation of each panel, i.e. 
 the rolling window does not start working unless it reaches the required level of 4 observations. {p_end}
 
 {p 4 4 2} 
 3. {opt  min:mum} {break}
 The option {opt min:} forces asrol to find required statistics where the minimum 
 number of observations are available. If a specific rolling window does not have that many 
 observations, values of the new variable will be replaced with missing values. {p_end}
 
  {p 4 4 2} 
 4. {cmdab:by:( }{it:varlist}{cmd: )} {break}
 asrol is {it: byable} and hence the rolling statistics can be calculated using a single variable as sorting filter or using multiple variables. For example, we can find mean profitability
 for each company in a rolling window of 5 years. Here, we use a single filter, that is company. Imagine that we have a data set of 40 countries, each one having 60 industries, and each industry 
 has 1000 firms. We might be interested in finding mean profitability of each industry within each country in a rolling window of 5 years. In that case, we shall use the option {cmd:by} 
 as shown below: {break}
  {cmd: asrol profitability, window(year 5) stat(mean), by(country industry)} {p_end}

 
{title:Example 1: Find Rolling Mean}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) " :. asrol invest, stat(mean) win(4) } {p_end}

{p 4 8 2} This command calculates mean for the variable invest using a four years rolling window and 
stores the results in a new variable, {it:mean4_invest}. 


 {title:Example 2: Find Rolling Standard Deviation} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(sd) win(6) " :. asrol invest, stat(sd) win(6)} {p_end}
 
 {p 4 8 2} This command calculates standard deviation for the variable invest using a six years 
 rolling window and stores the results in a new variable , {it:sd4_invest} {p_end}

   
 {title:Example 3:  For Rolling Mean with missing values at start of each panel} 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) smiss " :. asrol invest, stat(mean) win(4) smiss } {p_end}
 
{p 4 4 2}
 This command calculates mean for the variable invest using a four years 
 rolling window and stores the results in a new variable , {it:mean4_invest}. The {opt smiss} option 
 forces asrol to skip calculation of mean at the start of each panel, unless the legnth of the rolliwng window is reached.
 Compare these results with the results reported in {cmd: Example 1 above}. In Example 1, asrol calculates mean values 
 right from the first observation, adds new observation to the rolling window untill the length of the rolling window is reached. 
{p_end}
 
 
 {title:Example 4:  Rolling mean with minimum number of observaton} 
 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) min(3) " :. asrol invest, stat(mean) win(4) min(3) }

 
 {title:Example 5:  Rolling mean with minimum number of observaton including the start of the panel} 
 
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asrol invest, stat(mean) win(4) min(3) smiss " :. asrol invest, stat(mean) win(4) min(3) smiss} {p_end}

 
 {title:Example 6: Using by option for two or three variables} 
 
 {p 4 8 2} We shall generate a dummy data of 5 countries, 50 industries, 50 years, and 5000 firms for further examples.  {p_end}

  
clear
set obs 50
gen industry=_n
gen year=_n+1917
expand 5
bys industry: gen country=_n
expand 1000
bys ind: gen company=_n
gen profit=uniform()

{title:Mean by country and industry in a rolling window of 10 years} 
 {p 4 8 2}{stata "asrol profit, stat(mean) win(year 10) by(country industry)" :. asrol profit, stat(mean) win(year 10) by(country industry)} {p_end}
 {p 4 8 2} {cmd: NOTE:} Since the data cannot be declared as panel data on the basis of country and industry, we have to specify the range variable in the window option.

{title:Author}


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: *
*                                                                   *
*            Dr. Attaullah Shah                                     *
*            Institute of Management Sciences, Peshawar, Pakistan   *
*            Email: attaullah.shah@imsciences.edu.pk                *
*           {browse "www.OpenDoors.Pk": www.OpenDoors.Pk}                                       *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*


{marker also}{...}
{title:Also see}

{psee}
{help rolling}, 
{stata "ssc desc mvsumm":mvsumm}, 
{stata "ssc desc tsegen":tsegen}, 
{stata "ssc desc ascol":ascol}, 
{stata "ssc desc asreg":asreg}
{p_end}



{title:Acknowledgements}

{p 4 4 2}
 For creating group identifiers, I could have used egen's function, group. But for speed efficiency, 
 Nick Cox's solution of creating group idnetifier was preffered({browse "http://www.stata.com/support/faqs/data-management/creating-group-identifiers": See here}). 
 For finding median in the Mata language, I used the approach suggested by Daniel Klein,
({browse "http://www.statalist.org/forums/forum/general-stata-discussion/mata/1335405-can-i-use-mata-to-calculate-a-median-of-the-outcome-in-the-exposed-and-unexposed-groups-following-matching-with-teffects-psmatch": See here})  {p_end}
