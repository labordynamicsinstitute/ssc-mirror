{smcl}
{* version 1.0.0, 03Jan2025 }{...}
{cmd:help xtstgathercovid19}
{hline}

{title:Title}

{pstd}
    {hi: Downloads COVID-19 Data from Our World in Data}
	


{title:Syntax}

{phang2}
{cmd:xtstgathercovid19}
{cmd:,} {it:options}



{synoptset 29 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt pathz(string)}}indicates the complete file path where to save the new downloaded dataset. This option is required {p_end}
{synopt:{opt sav:ing(filename [, replace])}}allows to save the new downloaded dataset that the command downloads. 
{opt replace} specifies that the file may be replaced if it already exists {p_end}
{synoptline}



{title:Description}

{pstd}
{cmd:xtstgathercovid19} downloads COVID-19 Data from Our World in Data. The command {cmd:xtstgathercovid19} allows to 
download COVID-19/CORONAVIRUS/SARS-CoV-2 data in {hi:Stata} format. It permits to obtain time series and panel 
datasets on numerous variables, such as: new cases, new deaths, new vaccinations, stringency index, reproduction 
rate, population, etc. The downloaded datasets can be aggregated at any frequency: daily, weekly, monthly, quarterly, 
yearly, etc. 
Cross-sections of the datasets can also be obtained after transforming the downloaded data. All these datasets 
come from Our World in Data which is a website dedicated to sharing the necessary research and data to address 
and overcome the most significant global challenges.



{title:Important Information}

{pstd}
I wrote the command {cmd:xtstgathercovid19} at the request of the readers/users of my previous 
command {bf:{help xtstfetchcovid19}} (if installed). The two commands {cmd:xtstgathercovid19} 
and {bf:{help xtstfetchcovid19}} are complementary. The typical use case scenario is 
that, you utilize the two commands to download the necessary variables or databases you need for 
your specific study from both commands in order to suit your particular analysis, because 
there are some variables, some temporal depths or datasets that exist in one command that are not in the other and vice versa.



{title:Options}

{phang}
{opt pathz(string)} indicates the complete file path where to save the new downloaded dataset.  In this option, you specify the 
complete file path where you want to save the data downloaded by the command. If your file path contains blank spaces, you must enclose 
the path in double quotes. This option is required.

{phang}
{opt sav:ing}{cmd:(}{it:{help filename}} [{cmd:,} {it:replace}]{cmd:)} allows to save the new downloaded dataset that the command 
downloads. This option indicates the name of the diskfile to be created or replaced. If {it:filename} is specified without an 
extension, {hi:.dta} will be assumed. If the {it:filename} includes blank spaces, you must enclose the {it:filename} in double 
quotes. The sub-option {opt replace} specifies that the file may be replaced if it already exists.



{title:Examples}

{p 4 8 2} Before beginning the computations, we use the {hi:set more off} instruction to tell
{hi:Stata} not to pause when displaying the output. {p_end}

{p 4 8 2}{stata "set more off"}{p_end}

{p 4 8 2} In order to ease presentation and understanding, this {hi:Examples} section is divided into 6 blocks. Each block 
treats a different topic. {p_end}

{p 4 8 2} {hi:BLOCK 1} {p_end}

{p 4 8 2} In this block, we illustrate how to use the command {cmd:xtstgathercovid19} to extract the data for a 
group of countries (panel data) and for just one country (time series data). We also demonstrate how to utilize 
the command {cmd:xtstgathercovid19} to save the daily data and set the date to a {hi:Stata} readable format. {p_end}

{p 4 8 2} We begin by writing the name of the command {cmd:xtstgathercovid19}, followed by the 
option {opt pathz(string)}. In this option, we put, in double quotes, the complete file path where we 
want to save the data downloaded by the command. This option is required. To save the data, we specify the 
option {opt sav:ing}{cmd:(}{it:{help filename}} [{cmd:,} {it:replace}]{cmd:)} by indicating the name of 
the file in which we want to save the downloaded database, in double quotes {hi:"covid19compantsdaily1.dta"}. We also 
indicate the sub-option {opt replace}, because we want to overwrite the file if it already exists. {p_end}

{p 4 8 2} Before continuing, a few notes on the {opt pathz(string)} option.  Assume that you have 
Windows as your Operating System and you want to save the data downloaded by the 
command {cmd:xtstgathercovid19} in a folder named {hi:"mystatagraphs"} 
located in the {hi:"C:\"} drive. So, the full path name is {hi:"C:\mystatagraphs"}. Note that, you must 
physically create this folder; otherwise, the next instruction will not work at all. Also, if you 
have an Operating System other than Windows, you must supply the correct file path according to your Platform.  {p_end}

{p 4 8 2}{stata `"xtstgathercovid19, pathz("C:\mystatagraphs") saving("covid19compantsdaily1.dta", replace)"'}{p_end}

{p 4 8 2} The downloaded data do not come with labeled variables. But the variables names are 
self-descriptive. Meaning that, if you show their full names, you can infer what they are. 
Hence, we employ the {hi:describe} command with the {hi:fullnames} option to 
see the full names of the variables of the downloaded dataset. {p_end}

{p 4 8 2}{stata "describe, fullnames"}{p_end}

{p 4 8 2} In this described database, we notice that {hi:Stata} gave us the full name of each 
variable. It also, automatically labeled the variable names that was truncated. {p_end}

{p 4 8 2} In the downloaded dataset {hi:"covid19compantsdaily1.dta"}, the date is the variable named {hi:"date"}. To 
transform the content of 
this variable to a {hi:Stata} readable date format, we first get rid of the hyphen symbol by using the string 
function {hi:subinstr()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2} Second, we transform the newly generated variable {hi:"datest1"} to a {hi:Stata} readable daily date by using the 
date function {hi:daily()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2} Third, we use the command {hi:format} to change the newly generated variable {hi:"datest2"} to a {hi:Stata} days 
calendar date format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format datest2 %td"'}{p_end}

{p 4 8 2} Fourth, we reorder the variables in the dataset (please see {bf:{manhelp order D}} for more details). {p_end}

{p 4 8 2}{stata "order code continent country date datest2"}{p_end}

{p 4 8 2} Fifth, we drop potential duplicate observations in the 
dataset (please see {bf:{manhelp duplicates D}} for more details). {p_end}

{p 4 8 2}{stata `"bysort country datest2: keep if _n == 1"'}{p_end}

{p 4 8 2} Now, we sort the database by {hi:"country"} and {hi:"datest2"}. {p_end}

{p 4 8 2}{stata "sort country datest2"}{p_end}

{p 4 8 2} Then, we group the {hi:"country"} variable by using the 
command {hi:egen} (please see {bf:{manhelp egen D}} for more details). {p_end}

{p 4 8 2}{stata "egen countryiden = group(country)"}{p_end}

{p 4 8 2} Finally, we declare the data to be daily panel data by using the 
command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset countryiden datest2, daily"}{p_end}

{p 4 8 2} Now, we keep only a few important variables that might be of interest to us 
(please see {bf:{manhelp drop D}} for more details). {p_end}

{p 4 8 2}{stata "keep code continent country datest2 new_cases new_deaths new_vaccinations stringency_index reproduction_rate population"}{p_end}

{p 4 8 2} Next, we save all the changes we made to our daily dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19compantsdaily1.dta", replace"'}{p_end}

{p 4 8 2} The previously downloaded database is a panel dataset for many countries in the world. If we want just to extract the 
data for a smaller number of countries, for example:  China, France, Italy and the United States, we type. {p_end}

{p 4 8 2}{stata `"keep if (country == "China" | country == "France" | country == "Italy" | country == "United States")"'}{p_end}

{p 4 8 2} Now, we save the changes we just made previously into a new dataset. {p_end}

{p 4 8 2}{stata `"save "covid19compantsdaily2.dta", replace"'}{p_end}

{p 4 8 2} If we just want to extract the data as a time series data for just one country, for example 
the United States, we type. {p_end}

{p 4 8 2}{stata `"keep if country == "United States""'}{p_end}

{p 4 8 2} Now, we finish this block, by saving the changes we just made previously into a new dataset. {p_end}

{p 4 8 2}{stata `"save "covid19compantsdaily3.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 2} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a weekly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstgathercovid19, pathz("C:\mystatagraphs") saving("covid19compantsweekly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 1. Please, see block 1 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "order code continent country date datest2"}{p_end}

{p 4 8 2}{stata "bysort country datest2: keep if _n == 1"}{p_end}

{p 4 8 2}{stata "sort country datest2"}{p_end}

{p 4 8 2}{stata "egen countryiden = group(country)"}{p_end}

{p 4 8 2}{stata "xtset countryiden datest2, daily"}{p_end}

{p 4 8 2} Now, we begin our weekly data aggregation. We start, by creating a weekly date by using the 
function {hi:wofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate weeklydatest = wofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"weeklydatest"} to a {hi:Stata} 
calendar weeks format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format weeklydatest %tw"'}{p_end}

{p 4 8 2} We sort the database by {hi:"country"}, {hi:"countryiden"}, {hi:"code"}, 
and {hi:"weeklydatest"}. {p_end}

{p 4 8 2}{stata "sort country countryiden code weeklydatest"}{p_end}

{p 4 8 2} We aggregate the database at a weekly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) new_cases new_deaths new_vaccinations (median) stringency_index reproduction_rate population, by(country countryiden code weeklydatest)"}{p_end}

{p 4 8 2} We sort the database by {hi:"country"} and {hi:"weeklydatest"}. {p_end}

{p 4 8 2}{stata "sort country weeklydatest"}{p_end}

{p 4 8 2} We declare the data to be weekly panel data by using the 
command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset countryiden weeklydatest, weekly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19compantsweekly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 3} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a monthly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstgathercovid19, pathz("C:\mystatagraphs") saving("covid19compantsmonthly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 1. Please, see block 1 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "order code continent country date datest2"}{p_end}

{p 4 8 2}{stata "bysort country datest2: keep if _n == 1"}{p_end}

{p 4 8 2}{stata "sort country datest2"}{p_end}

{p 4 8 2}{stata "egen countryiden = group(country)"}{p_end}

{p 4 8 2}{stata "xtset countryiden datest2, daily"}{p_end}

{p 4 8 2} Now, we begin our monthly data aggregation. We start, by creating a monthly date by using the 
function {hi:mofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate monthlydatest = mofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"monthlydatest"} to a {hi:Stata} 
calendar month format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format monthlydatest %tm"'}{p_end}

{p 4 8 2} We sort the database by {hi:"country"}, {hi:"countryiden"}, {hi:"code"}, 
and {hi:"monthlydatest"}. {p_end}

{p 4 8 2}{stata "sort country countryiden code monthlydatest"}{p_end}

{p 4 8 2} We aggregate the database at a monthly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) new_cases new_deaths new_vaccinations (median) stringency_index reproduction_rate population, by(country countryiden code monthlydatest)"}{p_end}

{p 4 8 2} We sort the database by {hi:"country"} and {hi:"monthlydatest"}. {p_end}

{p 4 8 2}{stata "sort country monthlydatest"}{p_end}
 
{p 4 8 2} We declare the data to be monthly panel data by using 
the command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset countryiden monthlydatest, monthly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}
 
{p 4 8 2}{stata `"save "covid19compantsmonthly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 4} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a quarterly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstgathercovid19, pathz("C:\mystatagraphs") saving("covid19compantsquarterly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 1. Please, see block 1 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "order code continent country date datest2"}{p_end}

{p 4 8 2}{stata "bysort country datest2: keep if _n == 1"}{p_end}

{p 4 8 2}{stata "sort country datest2"}{p_end}

{p 4 8 2}{stata "egen countryiden = group(country)"}{p_end}

{p 4 8 2}{stata "xtset countryiden datest2, daily"}{p_end}

{p 4 8 2} Now, we begin our quarterly data aggregation. We start, by creating a quarterly date by using the 
function {hi:qofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate quarterlydatest = qofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"quarterlydatest"} to a {hi:Stata} 
calendar quarters format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format quarterlydatest %tq"'}{p_end}

{p 4 8 2} We sort the database by {hi:"country"}, {hi:"countryiden"}, {hi:"code"}, 
and {hi:"quarterlydatest"}. {p_end}

{p 4 8 2}{stata "sort country countryiden code quarterlydatest"}{p_end}

{p 4 8 2} We aggregate the database at a quarterly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) new_cases new_deaths new_vaccinations (median) stringency_index reproduction_rate population, by(country countryiden code quarterlydatest)"}{p_end}

{p 4 8 2} We sort the database by {hi:"country"} and {hi:"quarterlydatest"}. {p_end}

{p 4 8 2}{stata "sort country quarterlydatest"}{p_end}

{p 4 8 2} We declare the data to be quarterly panel data by using the 
command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset countryiden quarterlydatest, quarterly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19compantsquarterly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 5} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data at a yearly frequency. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstgathercovid19, pathz("C:\mystatagraphs") saving("covid19compantsyearly.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 1. Please, see block 1 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata "format datest2 %td"}{p_end}

{p 4 8 2}{stata "order code continent country date datest2"}{p_end}

{p 4 8 2}{stata "bysort country datest2: keep if _n == 1"}{p_end}

{p 4 8 2}{stata "sort country datest2"}{p_end}

{p 4 8 2}{stata "egen countryiden = group(country)"}{p_end}

{p 4 8 2}{stata "xtset countryiden datest2, daily"}{p_end}

{p 4 8 2} Now, we begin our yearly data aggregation. We start, by creating a yearly date by using the 
function {hi:yofd()} (please see {bf:{manhelp functions FN}} for more details). {p_end}

{p 4 8 2}{stata "generate yearlydatest = yofd(datest2)"}{p_end}

{p 4 8 2} Then, we use the command {hi:format} to change the newly generated variable {hi:"yearlydatest"} to a {hi:Stata} 
calendar year format and to a human readable format (please see {bf:{manhelp format D}} for more details). {p_end}

{p 4 8 2}{stata `"format yearlydatest %ty"'}{p_end}

{p 4 8 2} We sort the database by {hi:"country"}, {hi:"countryiden"}, {hi:"code"}, 
and {hi:"yearlydatest"}. {p_end}

{p 4 8 2}{stata "sort country countryiden code yearlydatest"}{p_end}

{p 4 8 2} We aggregate the database at a yearly frequency by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) new_cases new_deaths new_vaccinations (median) stringency_index reproduction_rate population, by(country countryiden code yearlydatest)"}{p_end}

{p 4 8 2} We sort the database by {hi:"country"} and {hi:"yearlydatest"}. {p_end}

{p 4 8 2}{stata "sort country yearlydatest"}{p_end}

{p 4 8 2} We declare the data to be yearly panel data by using the 
command {hi:xtset} (please see {bf:{manhelp xtset XT}} for more details). {p_end}

{p 4 8 2}{stata "xtset countryiden yearlydatest, yearly"}{p_end}

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19compantsyearly.dta", replace"'}{p_end}

{p 4 8 2} {hi:BLOCK 6} {p_end}

{p 4 8 2} In this block, we mainly show how to aggregate the data as a cross-sectional database. {p_end}

{p 4 8 2} We begin by downloading the data and saving them as we did previously. {p_end}

{p 4 8 2}{stata `"xtstgathercovid19, pathz("C:\mystatagraphs") saving("covid19compantscrosssec.dta", replace)"'}{p_end}

{p 4 8 2} Then, we perform the usual data managements we did in block 1. Please, see block 1 for more details on these data 
managements. {p_end}

{p 4 8 2}{stata `"generate datest1 = subinstr(date,"-","",.)"'}{p_end}

{p 4 8 2}{stata `"generate datest2 = daily(datest1, "YMD")"'}{p_end}

{p 4 8 2}{stata `"format datest2 %td"'}{p_end}

{p 4 8 2}{stata "order code continent country date datest2"}{p_end}

{p 4 8 2}{stata "bysort country datest2: keep if _n == 1"}{p_end}

{p 4 8 2}{stata "sort country datest2"}{p_end}

{p 4 8 2}{stata "egen countryiden = group(country)"}{p_end}

{p 4 8 2}{stata "xtset countryiden datest2, daily"}{p_end}

{p 4 8 2} We sort the database by {hi:"country"}, {hi:"countryiden"} and {hi:"code"}. {p_end}

{p 4 8 2}{stata "sort country countryiden code"}{p_end}

{p 4 8 2} We aggregate the data as a cross-sectional database by making a dataset of summary statistics by using the 
command {hi:collapse} (please see {bf:{manhelp collapse D}} for more details). {p_end}

{p 4 8 2}{stata "collapse (sum) new_cases new_deaths new_vaccinations (median) stringency_index reproduction_rate population, by(country countryiden code)"}{p_end}

{p 4 8 2} We sort the database by {hi:"country"}. {p_end}

{p 4 8 2}{stata "sort country"}{p_end} 

{p 4 8 2} We finish this block by saving all the changes we made to our dataset since we last downloaded it. {p_end}

{p 4 8 2}{stata `"save "covid19compantscrosssec.dta", replace"'}{p_end}

{p 4 8 2} {hi:EPILOGUE} {p_end}

{p 4 8 2} The instructions we have shown in this {hi:Examples} section, are just some of the few among the vast Data Management 
tools that can be used with the datasets that the command {cmd:xtstgathercovid19} downloads. Hence, despite our efforts, we have 
only scratched the surface of what can be done with the command {cmd:xtstgathercovid19}, the accompanying downloaded 
datasets, and the use of the command {cmd:xtstgathercovid19} in conjunction with the thousands excellent and wonderful 
commands available from within {hi:Stata} for Data Management, Data Analysis, Statistics, Econometrics and Data Science. We leave 
these avenues of research to the reader/user to explore at her/his will ! {p_end}



{title:References}

{p 4 8 2}{hi:Edouard Mathieu, Hannah Ritchie, Lucas Rodés-Guirao, Cameron Appel, Daniel Gavrilov, Charlie Giattino, Joe Hasell, Bobbie Macdonald, Saloni Dattani, Diana Beltekian, Esteban Ortiz-Ospina and Max Roser: 2020,} 
"COVID-19 Pandemic", 
{it:Our World in Data}. {p_end}

{p 4 8 2}{hi:Our World in Data}. Browsable at: {browse "https://ourworldindata.org/coronavirus"}.
{p_end}



{title:Citation and Donation}

{pstd}
The command {cmd:xtstgathercovid19} is not an {hi:Official Stata} command. Like a paper, it is a free contribution to 
the research community. If you find the command {cmd:xtstgathercovid19} and its accompanying datasets useful and 
utilize them in your 
works, please cite them like a paper as it is explained in the {hi:Suggested Citation} section of 
the {hi:IDEAS/RePEc} {it:webpage} of the command. Please, also cite {hi:Edouard Mathieu et al. (2020)} 
and the {it:website} {hi:Our World in Data} in your 
works. Additionally, I encourage you, please, to visit the {hi:Our World in Data} {it:website}, because it contains 
many important scientific articles and awesome information on the {it:COVID-19 Pandemic} that will help you 
in your {it:COVID-19/CORONAVIRUS/SARS-CoV-2} modeling and analysis journeys.
{it:Thank you infinitely, in advance, for doing all these gestures!} Please, note that citing this 
command {cmd:xtstgathercovid19} and these references  are a good way to disseminate their use and their 
discovery by other researchers and analysts. Doing these actions, could also, potentially, help us, as a 
community, to overcome {it:COVID-19} and to help in solving other challenging current problems and those 
that lie ahead in the future.

{pstd}
I would also like to ask you about one more thing, {hi:please!} I hope you are finding my {hi:Stata Packages} useful 
and insightful. If you have appreciated the work I do and would like to support me financially in continuing 
to develop these resources, I would be incredibly grateful. You can help fund my work 
through {hi:My Patreon Page} ({browse "https://patreon.com/zavrencp?utm_medium=unknown&utm_source=join_link&utm_campaign=creatorshare_creator&utm_content=copyLink":LINK HERE}) 
or through {hi:My PayPal Page} ({browse "https://www.paypal.com/donate/?hosted_button_id=UHUUCFH9W5TQE":LINK HERE}), 
which will allow me to dedicate more time and resources to creating even better 
tools and updates. Any contribution, no matter how small, is greatly appreciated 
and will go directly towards furthering my work. 
{it:Thank you so much in advance for your valuable support !} {hi:Best and Kind Regards !} 



{title:Acknowledgements}

{pstd}
I thank Edouard Mathieu, Hannah Ritchie, Lucas Rodés-Guirao, Cameron Appel, Daniel Gavrilov, Charlie Giattino, 
Joe Hasell, Bobbie Macdonald, Saloni Dattani, Diana Beltekian, Esteban Ortiz-Ospina and Max Roser; all the Team 
of the {it:Our World in Data} {it:website}; and all their original third-party data providers authors for writing 
and making their programs, data, articles and {it:webpage} publicly available. This 
current {hi:Stata} package is based and inspired by their 
works. The usual disclaimers apply: all errors and imperfections in this package are mine and 
all comments are very welcome.



{title:Author}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}FERDI (Fondation pour les Etudes et Recherches sur le Developpement International) {p_end}
{p 4}63 Boulevard Francois Mitterrand  {p_end}
{p 4}63000 Clermont-Ferrand   {p_end}
{p 4}France {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}

{p 4}Diallo Ibrahima Amadou {p_end}
{p 4 4}Zavren Consulting and Publishing {p_end}
{p 4}{hi:E-Mail}: {browse "mailto:zavren@gmail.com":zavren@gmail.com} {p_end}



{title:Also see}

{psee}
Online:  help for {bf:{manhelp describe D}}, {bf:{manhelp generate D}}, {bf:{manhelp egen D}}, {bf:{manhelp xtset XT}},
{bf:{manhelp save D}}, {bf:{manhelp functions FN}}, {bf:{manhelp format D}}, {bf:{manhelp tsvarlist U}}, 
{bf:{manhelp collapse D}}, {bf:{manhelp order D}}, {bf:{manhelp duplicates D}}, {bf:{manhelp drop D}}, 
{bf:{help probgenextval}} (if installed), {bf:{help xtstfetchcovid19}} (if installed)
{p_end}


