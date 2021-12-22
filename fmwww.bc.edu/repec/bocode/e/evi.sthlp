{smcl}
{* 15oct2021}{...}
{cmd:help evi}
{hline}

{title:Title}

{pstd} {cmd:evi} {hline 2} Epidemic Volatility Index (EVI) for detecting epidemic waves



{title:Syntax}

{p 8 14 2} {cmd: evi} {it:varlist} {ifin} [, options]
	
{pstd} {it:varlist} should contain two variables and be entered in the following order: {it:cases} and {it:time} 



{title:Description}

{pstd} {cmd:evi} is based on the volatility of the newly reported {it:cases} per unit of {it:time} (ideally per day) and issues an early warning when the rate of the volatility change exceeds a threshold ('c').
Issuance of consecutive early warnings is a strong indication of an upcoming epidemic wave.
EVI is calculated for a rolling window of time series epidemic data ('lag'). At each step, the observations within the window are obtained by shifting the window forward over the time series data one observation at a time.
The user should provide the minimum rise in mean cases between two consecutive weeks ('r') that, if present, should be detected.



{title:Modules required}

{pstd} Users need to install {stata ssc install diagt:diagt} and {stata ssc install rangestat:rangestat}



{title:Options}

{pstd} {cmd:lag(#1 #2)} specifies the range of 'lag'. It is not recommended to use values ≤ 6 (by default the range is 7 to 10).

{pstd} {cmd:c(#1 #2)} specifies the range of 'c' (by default the range is 0.01 to 0.05).

{phang2} NOTE: It is recommended when running EVI in a server to specify the range for 'lag' from 7 to 28 and for 'c' from 0.01 to 0.5. {p_end}

{pstd} {cmd:cumulative} specifies that {it:cases} contain cumulative number of cases, rather than new cases per unit of time.

{pstd} {cmd:r(#)} specifies the cut-off value for 'r' (by default it is 1.2, indicating an increase in the mean of cases of ≥ 20%). 

{pstd} {cmd:mov(#)} specifies the size of the moving average of cases (by default it is 7, to estimate weekly moving average of cases). 


Selection of best {cmd:lag} and {cmd:c} to estimate {cmd:evi}
{pstd} {cmd:youden} specifies that the selection is done based on the highest Youden's J statistic (default). 

{pstd} {cmd:sensitivity(#)} specifies the maximum sensitivity desired to select 'lag' and 'c'. 

{pstd} {cmd:specificity(#)} specifies the maximum specificity desired to select 'lag' and 'c'. 


Time series graph and saved data
{pstd} {cmd:logarithmic} displays the number of cases (x-axis) in the time series in the log10 scale. 

{pstd} {cmd:nograph} suppresses the time series graph. 

{pstd} {cmd:norsample} do not add new variables ({it:_status _lag _c _sens _spec _youden _evi}) to the dataset. 



{title:Examples}


{pstd} The data for the example is taken from the COVID-19 Data Repository maintained by the Center for Systems Science and Engineering at the Johns Hopkins University (https://github.com/CSSEGISandData/COVID-19).{p_end}
{phang2} {stata "use http://fmwww.bc.edu/repec/bocode/e/evi_example_data.dta":. use http://fmwww.bc.edu/repec/bocode/e/evi_example_data.dta } {p_end}

{pstd} EVI for the first 150 days of cumulative COVID-19 data from Italy.{p_end}
{phang2} Note: It takes approximately 5 minutes to complete the command {p_end}
{phang2}{stata "evi cases day, cumulative log":. evi cases day, cumulative log} {p_end}



{title:Authors}

{pstd} Luis Furuya-Kanamori, UQ Centre for Clinical Research, The University of Queensland, Australia{p_end}
{pstd} {browse "mailto:l.furuya@uq.edu.au?subject=EVI Stata enquiry":l.furuya@uq.edu.au}{p_end}

{pstd} Polychronis Kostoulas, Faculty of Public Health, University of Thessaly, Greece{p_end}
{pstd} {browse "mailto:pkost@uth.gr?subject=EVI Stata enquiry":pkost@uth.gr}{p_end}


	
{title:References}

{pstd} Kostoulas P {it:et al.} The Epidemic Volatility Index: an early warning tool for epidemics. DOI:{browse "10.22541/au.161918947.77588494/v2"}

{pstd} The Epidemic Volatility Index: Predictions for COVID-19. {browse "http://83.212.174.99:3838/"}



{title:Funding}

{pstd} LFK was supported by an Australian National Health and Medical Research Council Fellowship (APP1158469).
