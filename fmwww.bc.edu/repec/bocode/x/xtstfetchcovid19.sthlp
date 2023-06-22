{smcl}
{* version 1.0.0, 09Jun2023 }{...}
{cmd:help xtstfetchcovid19}
{hline}

{title:Title}

{pstd}
    {hi: Downloads COVID-19 Datasets from the COVID-19 Data Hub}
	


{title:Syntax}

{phang2}
{cmd:xtstfetchcovid19}
{cmd:,} {it:options}



{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt pathz(string)}}indicates the complete file path where to save the new downloaded dataset. This option is required {p_end}
{synopt :{opt granulev(#)}}designates the 3 different levels of granularity of the datasets. The values of {hi:#} must be: 1, 2 or 3.
Default is {hi:granulev(1)}{p_end}
{synopt:{opt sav:ing(filename [, replace])}}allows to save the new downloaded dataset that the command downloads. 
{opt replace} specifies that the file may be replaced if it already exists {p_end}
{synoptline}



{title:Description}

{pstd}
{cmd:xtstfetchcovid19} downloads COVID-19 datasets from the COVID-19 Data Hub.  The command {cmd:xtstfetchcovid19} allows to 
download COVID-19/CORONAVIRUS/SARS-CoV-2 datasets in {hi:Stata} format at 3 different levels of granularity: country-level 
data (level 1), state-level data (level 2) and city-level data (level 3). It permits to obtain time series and panel 
datasets on numerous variables, such as: the number confirmed cases, deaths, recovered cases, tests, vaccines, people 
vaccinated, hospitalized patients, people in intensive care unit, latitude, longitude, population, key google 
mobility, key apple mobility, etc. The downloaded datasets can be aggregated at any frequency: daily, weekly, monthly, 
yearly, etc. Cross-sections of the datasets can also be obtained after transforming the downloaded data. All these 
datasets come from the COVID-19 Data Hub which is a website dedicated to make integrated COVID-19 data available to 
the wider community of researchers around the world for a deeper insight into COVID-19.



{title:Options}

{phang}
{opt pathz(string)} indicates the complete file path where to save the new downloaded dataset.  In this option, you specify the 
complete file path where you want to save the data downloaded by the command. If your file path contains blank spaces, you must enclose 
the path in double quotes. This option is required.

{phang}
{opt granulev(#)} designates the 3 different levels of granularity of the datasets. The values of {hi:#} must be: 1, 2 or 3. These 
numbers correspond to the 3 different levels of granularity of the datasets: administrative area of top-level, usually 
countries (level 1); states, regions, cantons (level 2); and cities, municipalities (level 3). The default value of this 
option is {hi:granulev(1)}, meaning that by default, country-level data (level 1) will be downloaded.

{phang}
{opt sav:ing}{cmd:(}{it:{help filename}} [{cmd:,} {it:replace}]{cmd:)} allows to save the new downloaded dataset that the command 
downloads. This option indicates the name of the diskfile to be created or replaced. If {it:filename} is specified without an 
extension, {hi:.dta} will be assumed. If the {it:filename} includes blank spaces, you must enclose the {it:filename} in double 
quotes. The sub-option {opt replace} specifies that the file may be replaced if it already exists.



{title:Examples}

{p 4 8 2} Before beginning the computations, we use the {hi:set more off} instruction to tell
{hi:Stata} not to pause when displaying the output. {p_end}

{p 4 8 2}{stata "set more off"}{p_end}

{p 4 8 2} In order to ease presentation and understanding, this {hi:Examples} section is divided into 8 blocks. Each block 
treats a different topic. {p_end}

{p 4 8 2} {hi:BLOCK 1} {p_end}

{p 4 8 2} In this block, we illustrate how to use the command {cmd:xtstfetchcovid19} with minimal syntax without saving the 
data. We show how to extract the data for a group of countries (panel data) and for just one country (time series data). {p_end}

{p 4 8 2} We begin by writing the name of the command {cmd:xtstfetchcovid19}, followed by the option {opt pathz(string)}. In this 
option, we put, in double quotes, the complete file path where we want to save the data downloaded by the command. This option 
is required. {p_end}

{p 4 8 2} Before continuing, a few notes on the {opt pathz(string)} option.  Assume that you have Windows as your Operating 
System and you want to save the data downloaded by the command {cmd:xtstfetchcovid19} in a folder named {hi:"mystatagraphs"} located 
in the {hi:"C:\"} drive. So, the full path name is {hi:"C:\mystatagraphs"}. Note that, you must physically create this folder; otherwise, 
the next instruction will not work at all. Also, if you have an Operating System other than Windows, you must supply the 
correct file path according to your Platform.  {p_end}

{p 4 8 2} Since we do not specify the option {opt granulev(#)}, the default value of this option is used, in 
other words {hi:granulev(1)}. Meaning that by default, country-level data (level 1) will be downloaded. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs")"'}{p_end}

{p 4 8 2} The downloaded data do not come with labeled variables. But the variables names are 
self-descriptive. Meaning that, if you show their full names, you can infer what they are. 
Hence, we employ the {hi:describe} command with the {hi:fullnames} option to 
see the full names of the variables of the downloaded dataset. {p_end}

{p 4 8 2}{stata "describe, fullnames"}{p_end}

{p 4 8 2} Also, for your information, all the variables that come with the datasets downloaded by the command {cmd:xtstfetchcovid19} are 
fully described in the article of {hi:Guidotti (2022)}. Thus, I strongly encourage you to take a look at this paper if you need 
further information on the description of the variables that come with these datasets, please. {p_end}

{p 4 8 2} The previously downloaded database is a panel dataset for many countries in the world. If we want just to extract the 
data for a smaller number of countries, for example:  China, France, Italy and the United States, we type. {p_end}

{p 4 8 2}{stata `"keep if (administrative_area_level_1 == "China" | administrative_area_level_1 == "France" | administrative_area_level_1 == "Italy" | administrative_area_level_1 == "United States")"'}{p_end}

{p 4 8 2} If we just want to extract the data as a time series data for just one country, for example the United States, we type. {p_end}

{p 4 8 2}{stata `"keep if administrative_area_level_1 == "United States""'}{p_end}

{p 4 8 2} {hi:BLOCK 2} {p_end}

{p 4 8 2} In this block, we demonstrate how to utilize the command {cmd:xtstfetchcovid19} to save the daily data, set the date 
to a {hi:Stata} readable format and calculate the active cases. {p_end}

{p 4 8 2} To save the data, we specify the option {opt sav:ing}{cmd:(}{it:{help filename}} [{cmd:,} {it:replace}]{cmd:)} by indicating 
the name of the file in which we want to save the downloaded database, in double quotes {hi:"covid19level1daily.dta"}. We also indicate 
the sub-option {opt replace}, because we want to overwrite the file if it already exists.  {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") saving("covid19level1daily.dta", replace)"'}{p_end}

{p 4 8 2} In the downloaded dataset {hi:"covid19level1daily.dta"}, the date is the variable named {hi:"date"}. To transform the content of 
this variable to a {hi:Stata} readable date format, we first get rid of the hyphen symbol by using the string 
function {hi:subinstr()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2} Second, we transform the newly generated variable {hi:"datest1"} to a {hi:Stata} readable daily date by using the 
date function {hi:daily()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2} Third, we use the command {hi:format} to change the newly generated variable {hi:"datest2"} to a {hi:Stata} days 
calendar date format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format datest2 %td"'}{p_end}

{p 4 8 2} Now, we sort the database by {hi:"administrative_area_level_1"} and {hi:"datest2"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 datest2"}{p_end}

{p 4 8 2} Then, we group the {hi:"administrative_area_level_1"} variable by using the 
command {hi:egen} (please see {bf:{manhelp egen D}} for more details). {p_end}

{p 4 8 2}{stata "egen adminarealevel1iden = group(administrative_area_level_1)"}{p_end}

{p 4 8 2} Finally, we declare the data to be daily panel data by using the 
command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden datest2, daily"}{p_end}

{p 4 8 2} Now, we generate the {hi:Number of Active Cases of COVID-19}. In fact, many of the variables that come with the downloaded 
datasets by the command {cmd:xtstfetchcovid19} represent {hi:Cumulative Number of Cases}. But, for most practical statistical and 
econometrical purposes, we are interested in the {hi:Number of Active Cases of COVID-19}. In the next lines, we illustrate how to 
calculate the {hi:Number of Active Cases} by using the time-series operator {hi:D.}, which stands 
for {hi:The First Difference Operator} (please see {bf:{manhelp tsvarlist U}} for more details). {p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} In the 3 previous lines, we have created the number of active cases of confirmed, deaths and recovered respectively on a 
daily basis for each country in our panel database. {p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19level1daily.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 3} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a weekly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") saving("covid19level1weekly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 2. Please, see block 2 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 datest2"}{p_end}

{p 4 8 2}{stata "egen adminarealevel1iden = group(administrative_area_level_1)"}{p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden datest2, daily"}{p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} Now, we begin our weekly data aggregation. We start, by creating a weekly date by using the 
function {hi:wofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate weeklydatest = wofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"weeklydatest"} to a {hi:Stata} 
calendar weeks format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format weeklydatest %tw"'}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}, {hi:"adminarealevel1iden"}, {hi:"iso_alpha_3"}, 
and {hi:"weeklydatest"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 adminarealevel1iden iso_alpha_3 weeklydatest"}{p_end}

{p 4 8 2} We aggregate the database at a weekly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) confirmedactive deathsactive recoveredactive (median) population, by(administrative_area_level_1 adminarealevel1iden iso_alpha_3 weeklydatest)"}{p_end}
   
{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"} and {hi:"weeklydatest"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 weeklydatest"}{p_end}

{p 4 8 2} We declare the data to be weekly panel data by using the command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden weeklydatest, weekly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19level1weekly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 4} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a monthly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") saving("covid19level1monthly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 2. Please, see block 2 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 datest2"}{p_end}

{p 4 8 2}{stata "egen adminarealevel1iden = group(administrative_area_level_1)"}{p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden datest2, daily"}{p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} Now, we begin our monthly data aggregation. We start, by creating a monthly date by using the 
function {hi:mofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate monthlydatest = mofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"monthlydatest"} to a {hi:Stata} 
calendar month format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format monthlydatest %tm"'}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}, {hi:"adminarealevel1iden"}, {hi:"iso_alpha_3"}, 
and {hi:"monthlydatest"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 adminarealevel1iden iso_alpha_3 monthlydatest"}{p_end}
   
{p 4 8 2} We aggregate the database at a monthly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) confirmedactive deathsactive recoveredactive (median) population, by(administrative_area_level_1 adminarealevel1iden iso_alpha_3 monthlydatest)"}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"} and {hi:"monthlydatest"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 monthlydatest"}{p_end}
 
{p 4 8 2} We declare the data to be monthly panel data by using the command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden monthlydatest, monthly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}
 
{p 4 8 2}{stata `"save "covid19level1monthly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 5} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a yearly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") saving("covid19level1yearly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 2. Please, see block 2 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 datest2"}{p_end}

{p 4 8 2}{stata "egen adminarealevel1iden = group(administrative_area_level_1)"}{p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden datest2, daily"}{p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} Now, we begin our yearly data aggregation. We start, by creating a yearly date by using the 
function {hi:yofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate yearlydatest = yofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"yearlydatest"} to a {hi:Stata} 
calendar year format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format yearlydatest %ty"'}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}, {hi:"adminarealevel1iden"}, {hi:"iso_alpha_3"}, 
and {hi:"yearlydatest"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 adminarealevel1iden iso_alpha_3 yearlydatest"}{p_end}
   
{p 4 8 2} We aggregate the database at a yearly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) confirmedactive deathsactive recoveredactive (median) population, by(administrative_area_level_1 adminarealevel1iden iso_alpha_3 yearlydatest)"}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"} and {hi:"yearlydatest"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 yearlydatest"}{p_end}

{p 4 8 2} We declare the data to be yearly panel data by using the command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden yearlydatest, yearly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19level1yearly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 6} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data as a cross-sectional database. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") saving("covid19level1crosssec.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 2. Please, see block 2 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata `"format datest2 %td"'}{p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 datest2"}{p_end}

{p 4 8 2}{stata "egen adminarealevel1iden = group(administrative_area_level_1)"}{p_end}

{p 4 8 2}{stata "xtset adminarealevel1iden datest2, daily"}{p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}, {hi:"adminarealevel1iden"} and {hi:"iso_alpha_3"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 adminarealevel1iden iso_alpha_3"}{p_end}

{p 4 8 2} We aggregate the data as a cross-sectional database by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) confirmedactive deathsactive recoveredactive (median) population, by(administrative_area_level_1 adminarealevel1iden iso_alpha_3)"}{p_end}   

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}. {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1"}{p_end} 

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19level1crosssec.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 7} {p_end}

{p 4 8 2} In this block, we mainly show how to download states, regions and cantons level data (level 2). {p_end}

{p 4 8 2} We begin by downloading daily state-level data (level 2) by specifying the option {hi:granulev(2)}. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") granulev(2) saving("covid19level2daily.dta", replace)"'}{p_end}

{p 4 8 2} The downloaded data do not come with labeled variables. But the variables names are 
self-descriptive. Meaning that, if you show their full names, you can infer what they are. 
Hence, we employ the {hi:describe} command with the {hi:fullnames} option to 
see the full names of the variables of the downloaded dataset. {p_end}

{p 4 8 2}{stata "describe, fullnames"}{p_end}

{p 4 8 2} We perform the usual data managements we did in block 2, commenting only the lines that are new. Please, see 
block 2 for more details on these data managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata `"format datest2 %td"'}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}, {hi:"administrative_area_level_2"} and {hi:"datest2"} because we 
have state-level data (level 2). {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 administrative_area_level_2 datest2"}{p_end}

{p 4 8 2} We group the {hi:"administrative_area_level_1"} and the {hi:"administrative_area_level_2"} variables together because we 
have state-level data (level 2) by using the command {hi:egen} (please see {bf:{manhelp egen D}} for more details). {p_end}

{p 4 8 2}{stata "egen adminarealevel2iden = group(administrative_area_level_1 administrative_area_level_2)"}{p_end}

{p 4 8 2} We declare the data to be daily panel data by using the command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset adminarealevel2iden datest2, daily"}{p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19level2daily.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 8} {p_end}

{p 4 8 2} In this last block, we mainly show how to download cities and municipalities level data (level 3). {p_end}

{p 4 8 2} We begin by downloading daily city-level data (level 3) by specifying the option {hi:granulev(3)}. {p_end}

{p 4 8 2}{stata `"xtstfetchcovid19, pathz("C:\mystatagraphs") granulev(3) saving("covid19level3daily.dta", replace)"'}{p_end}

{p 4 8 2} The downloaded data do not come with labeled variables. But the variables names are 
self-descriptive. Meaning that, if you show their full names, you can infer what they are. 
Hence, we employ the {hi:describe} command with the {hi:fullnames} option to 
see the full names of the variables of the downloaded dataset. {p_end}

{p 4 8 2}{stata "describe, fullnames"}{p_end}

{p 4 8 2} We perform the usual data managements we did in block 2, commenting only the lines that are new. Please, see 
block 2 for more details on these data managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata `"format datest2 %td"'}{p_end}

{p 4 8 2} We sort the database by {hi:"administrative_area_level_1"}, {hi:"administrative_area_level_2"}, {hi:"administrative_area_level_3"} 
and {hi:"datest2"} because we have city-level data (level 3). {p_end}

{p 4 8 2}{stata "sort administrative_area_level_1 administrative_area_level_2 administrative_area_level_3 datest2"}{p_end}

{p 4 8 2} We group the {hi:"administrative_area_level_1"}, the {hi:"administrative_area_level_2"} and the
{hi:"administrative_area_level_3"} variables together because we 
have city-level data (level 3) by using the command {hi:egen} (please see {bf:{manhelp egen D}} for more details). {p_end}

{p 4 8 2}{stata "egen adminarealevel3iden = group(administrative_area_level_1 administrative_area_level_2 administrative_area_level_3)"}{p_end}

{p 4 8 2} We declare the data to be daily panel data by using the command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset adminarealevel3iden datest2, daily"}{p_end}

{p 4 8 2}{stata "generate double confirmedactive = D.confirmed"}{p_end}

{p 4 8 2}{stata "generate double deathsactive = D.deaths"}{p_end}

{p 4 8 2}{stata "generate double recoveredactive = D.recovered"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19level3daily.dta", replace"'}{p_end}

{p 4 8 2} {hi:EPILOGUE} {p_end}

{p 4 8 2} The instructions we have shown in this {hi:Examples} section, are just some of the few among the vast Data Management 
tools that can be used with the datasets that the command {cmd:xtstfetchcovid19} downloads. Hence, despite our efforts, we have 
only scratched the surface of what can be done with the command {cmd:xtstfetchcovid19}, the accompanying downloaded 
datasets, and the use of the command {cmd:xtstfetchcovid19} in conjunction with the thousands excellent and wonderful 
commands available from within {hi:Stata} for Data Management, Data Analysis, Statistics, Econometrics and Data Science. We leave 
these avenues of research to the reader/user to explore at her/his will ! {p_end}



{title:References}

{p 4 8 2}{hi:Guidotti Emanuele and Ardia David: 2020,} 
"COVID-19 Data Hub", 
{it:Journal of Open Source Software} {bf:5}(51), 2376. {p_end}

{p 4 8 2}{hi: Guidotti Emanuele: 2022,} 
"A worldwide epidemiological database for COVID-19 at fine grained spatial resolution", 
{it:Scientific Data} {bf:9}(112). {p_end}

{p 4 8 2}{hi:COVID-19 Data Hub}. Browsable at: {browse "https://covid19datahub.io"}.
{p_end}



{title:Citation}

{pstd}
The command {cmd:xtstfetchcovid19} is not an {hi:Official Stata} command. Like a paper, it is a free contribution to the research 
community. If you find the command {cmd:xtstfetchcovid19} and its accompanying datasets useful and utilize them in your 
works, please cite them like a paper as it is explained in the {hi:Suggested Citation} section of 
the {hi:IDEAS/RePEc} {it:webpage} of the command. Please, also cite {hi:Guidotti and Ardia (2020)}, {hi:Guidotti (2022)} and 
the {it:website} {hi:COVID-19 Data Hub} in your 
works.{it:Thank you infinitely, in advance, for doing all these gestures!} Please, note that citing this 
command {cmd:xtstfetchcovid19} and these references  are a good way to disseminate their use and their 
discovery by other researchers. Doing these actions, could also, potentially, help us, as a 
community, to overcome {it:COVID-19} and to help in solving other challenging current problems and those that lie ahead in the future.



{title:Acknowledgements}

{pstd}
I thank Emanuele Guidotti, David Ardia and all the Team of the {it:COVID-19 Data Hub} {it:website} for writing and making their 
programs, data, articles and {it:webpage} publicly available. This current {hi:Stata} package is based and inspired by their 
works. I would also like to, additionally, thank Emanuele Guidotti for the many fruitful exchanges we had during the 
building process of the package. The usual disclaimers apply: all errors and imperfections in this package are mine and 
all comments are very welcome.



{title:Author}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}FERDI (Fondation pour les Etudes et Recherches sur le Developpement International) {p_end}
{p 4}63 Boulevard Francois Mitterrand  {p_end}
{p 4}63000 Clermont-Ferrand   {p_end}
{p 4}France {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}



{title:Also see}

{psee}
Online:  help for {bf:{manhelp describe D}}, {bf:{manhelp generate D}}, {bf:{manhelp egen D}}, {bf:{manhelp xtset XT}},
{bf:{manhelp save D}}, {bf:{manhelp functions FN}}, {bf:{manhelp format D}}, {bf:{manhelp tsvarlist U}}, {bf:{manhelp collapse D}},  
{bf:{help probgenextval}} (if installed)
{p_end}


