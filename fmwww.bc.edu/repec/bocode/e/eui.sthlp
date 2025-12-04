{smcl}
{* *! version 1.7 30Nov2025}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "eui##syntax"}{...}
{viewerjumpto "Description" "eui##description"}{...}
{viewerjumpto "Options" "eui##options"}{...}
{viewerjumpto "Examples" "eui##examples"}{...}
{viewerjumpto "Authors" "eui##authors"}{...}
{viewerjumpto "Acknowledgements" "eui##acknowledgements"}{...}
{viewerjumpto "References" "eui##references"}{...}

{hline}
{help eui##eui:help eui}{right:Environmental Uncertainty Index Calculator}
{hline}

{title:Title}

{p 4 4 2}
{bf:eui} - Environmental Uncertainty Index Calculator {break}
Compute environmental uncertainty index using industry sales growth rate standard deviation

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:eui} [{cmd:using} {it:filename}], {cmd:WINDow(}{it:integer}{cmd:)} 
[{cmd:MISsing(}{it:string}{cmd:)} {cmd:SAVing(}{it:filename}{cmd:)} {cmd:REPLACE}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt WINDow(integer)}}time window for standard deviation calculation (3-5 years){p_end}

{syntab:Optional}
{synopt:{opt using}}specify Excel data file path{p_end}
{synopt:{opt MISsing(string)}}missing value treatment method: {it:drop} or {it:ipolate}{p_end}
{synopt:{opt SAVing(string)}}save results to specified file{p_end}
{synopt:{opt REPLACE}}overwrite existing files{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:eui} calculates the Environmental Uncertainty Index (EUI) using the standard deviation 
of industry sales growth rates over a specified time window (3-5 years). The program 
implements a comprehensive data processing pipeline including data cleaning, industry 
classification, growth rate calculation, and uncertainty measurement.

{p 4 4 2}
{bf:Version Information:} {it:Version 1.7 - 30 Nov 2025}

{p 4 4 2}
The algorithm follows these steps:

{p 8 12 2}
1. {bf:Data Import}: Loads data from Excel file with variables stkcd, date, code, revenue{p_end}
{p 8 12 2}
2. {bf:Data Cleaning}: Removes duplicates, handles missing values, creates year variable, and processes industry code missing values{p_end}
{p 8 12 2}
3. {bf:Industry Classification}: Creates industry codes based on classification rules{p_end}
{p 8 12 2}
4. {bf:Aggregation}: Computes total sales by industry and year{p_end}
{p 8 12 2}
5. {bf:Growth Calculation}: Calculates sales growth rates{p_end}
{p 8 12 2}
6. {bf:EUI Computation}: Computes rolling standard deviation of growth rates{p_end}
{p 8 12 2}
7. {bf:Output}: Provides comprehensive descriptive statistics and visualizations{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt WINDow(integer)} specifies the time window (in years) for calculating the rolling 
standard deviation of sales growth rates. Must be an integer between 3 and 5.

{dlgtab:Optional}

{phang}
{opt using} specifies the path to the Excel file containing the input data. If not specified, 
the program looks for "sales.xlsx" in the current directory.

{phang}
{opt MISsing(string)} specifies how to handle missing revenue values. {it:drop} removes 
observations with missing revenue (default). {it:ipolate} uses linear interpolation to fill 
missing values.

{phang}
{opt SAVing(filename)} saves the final dataset with EUI values to the specified file.

{phang}
{opt REPLACE} allows overwriting existing files when saving results.

{marker examples}{...}
{title:Examples}

{p 4 4 2}{ul:Basic usage with default settings}{p_end}

{phang2}{cmd:. eui, window(3)}{p_end}

{p 4 4 2}{ul:Specify data file and 4-year window}{p_end}

{phang2}{cmd:. eui using "sales_data.xlsx", window(4)}{p_end}

{p 4 4 2}{ul:Full parameter specification with interpolation}{p_end}

{phang2}{cmd:. eui using "sales.xlsx", window(5) missing(ipolate) saving("eui_results.dta") replace}{p_end}

{p 4 4 2}{ul:Display version information}{p_end}

{phang2}{cmd:. eui_version}{p_end}

{marker authors}{...}
{title:Authors}

{p 4 4 2}
{bf:Wu Lianghai}{break}
School of Business, Anhui University of Technology(AHUT){break}
Ma'anshan, China{break}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{p 4 4 2}
{bf:Wu Hanyan}{break}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA){break}
Nanjing, China{break}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}

{p 4 4 2}
{bf:Chen Liwen}{break}
School of Business, Anhui University of Technology(AHUT){break}
Ma'anshan, China{break}
{browse "mailto:2184844526@qq.com":2184844526@qq.com}

{marker acknowledgements}{...}
{title:Acknowledgements}

{p 4 4 2}
We gratefully acknowledge Christopher F. Baum for his generous support to {bf:Dingyuan Accounting}.

{marker references}{...}
{title:References}

{p 4 4 2}
{bf:Methodological References}{p_end}

{p 8 12 2}
Baum, C. F. 2006. {it:An Introduction to Modern Econometrics Using Stata}. College Station, TX: Stata Press.{p_end}

{p 8 12 2}
Baum, C. F. 2016. {it:An Introduction to Stata Programming}. College Station, TX: Stata Press.{p_end}

{p 8 12 2}
Ghosh, D., and Olsen, L. 2009. Environmental uncertainty and managers' use of discretionary accruals. 
{it:Accounting, Organizations and Society} 34(2): 188-205.{p_end}

{p 8 12 2}
Tosi, H., Aldag, R., and Storey, R. 1973. On the measurement of the environment: 
An assessment of the Lawrence and Lorsch environmental uncertainty subscale. 
{it:Administrative Science Quarterly} 18(1): 27-36.{p_end}

{p 8 12 2}
Dess, G. G., and Beard, D. W. 1984. Dimensions of organizational task environments. 
{it:Administrative Science Quarterly} 29(1): 52-73.{p_end}

{p 4 4 2}
{bf:Methodology Background}{p_end}

{p 8 12 2}
The Environmental Uncertainty Index (EUI) methodology is based on the standard deviation 
of industry sales growth rates over a rolling time window, following established practices 
in strategic management and accounting research. This approach has been widely adopted 
in the literature to measure environmental uncertainty, building on foundational work 
in organizational theory and strategic management.{p_end}

{title:Data Processing Details}

{p 4 4 2}
{bf:Input Variables:}{p_end}
{p 8 12 2}- stkcd: Stock code identifier{p_end}
{p 8 12 2}- date: Year of observation (original){p_end}
{p 8 12 2}- code: Industry classification code (string){p_end}
{p 8 12 2}- revenue: Sales revenue{p_end}

{p 4 4 2}
{bf:Generated Variables:}{p_end}
{p 8 12 2}- year: Numeric year variable derived from date{p_end}
{p 8 12 2}- industry: Industry classification code{p_end}
{p 8 12 2}- eui: Environmental Uncertainty Index{p_end}

{p 4 4 2}
{bf:Industry Classification Rules:}{p_end}
{p 8 12 2}- If first character of code is "C": industry = first 2 characters{p_end}
{p 8 12 2}- Otherwise: industry = first character{p_end}

{p 4 4 2}
{bf:Missing Value Handling:}{p_end}
{p 8 12 2}- Industry codes: Missing values (empty, "NA", "N/A") are filled using the most frequent code for each company from other years{p_end}
{p 8 12 2}- Revenue: Missing values are either dropped or interpolated based on user selection{p_end}
{p 8 12 2}- Observations with unclassified industries are removed{p_end}

{title:EUI Calculation Method}

{p 4 4 2}
The Environmental Uncertainty Index is calculated using the following methodology:

{p 8 12 2}
1. {bf:Industry Aggregation}: Total sales revenue is calculated for each industry-year combination{p_end}

{p 8 12 2}
2. {bf:Growth Rate Calculation}: Sales growth rates are computed for each industry using year-to-year changes{p_end}

{p 8 12 2}
3. {bf:Rolling Standard Deviation}: The EUI is computed as the standard deviation of sales growth rates over a rolling time window{p_end}

{p 8 12 2}
4. {bf:Window Requirement}: At least {it:window} years of consecutive data are required to compute EUI for a given year{p_end}

{p 4 4 2}
{bf:Important Note on Recent Years}:{p_end}
{p 8 12 2}Due to the rolling window requirement, the most recent years in the dataset may not have EUI values calculated. 
For example, with a 5-year window, EUI values will only be available for years where there are at least 5 consecutive years 
of data including that year.{p_end}

{title:Diagnostic Information}

{p 4 4 2}
The program provides comprehensive diagnostic information throughout the calculation process:

{p 8 12 2}
- Year range of input data{p_end}
{p 8 12 2}
- Industry classification results{p_end}
{p 8 12 2}
- Missing value handling statistics{p_end}
{p 8 12 2}
- EUI calculation progress by industry{p_end}
{p 8 12 2}
- Final years with available EUI values{p_end}

{title:Statistical Output}

{p 4 4 2}
The program generates comprehensive statistical reports including:

{p 8 12 2}
1. {bf:Overall EUI Statistics}: Detailed summary statistics for the complete dataset{p_end}

{p 8 12 2}
2. {bf:Industry-level Statistics}: EUI statistics aggregated by industry, showing mean, 
standard deviation, minimum, maximum, and observation count for each industry.{p_end}

{title:Visualizations}

{p 4 4 2}
The program generates the following graphical outputs:

{p 8 12 2}
- {bf:EUI Distribution Histogram}: Shows the frequency distribution of EUI values{p_end}
{p 8 12 2}
- {bf:Box Plot by Industry}: Compares EUI distributions across different industries{p_end}
{p 8 12 2}
- {bf:EUI Trend by Industry}: Line charts showing how EUI evolves over time for each industry{p_end}

{title:Limitations and Considerations}

{p 4 4 2}
{bf:Data Requirements}:{p_end}
{p 8 12 2}- At least {it:window}+1 years of data are needed to calculate the first EUI value (due to growth rate calculation){p_end}
{p 8 12 2}- Recent years may not have EUI values if insufficient data is available for the rolling window{p_end}
{p 8 12 2}- Industry classification requires valid industry codes for all observations{p_end}

{p 4 4 2}
{bf:Interpretation}:{p_end}
{p 8 12 2}- Higher EUI values indicate greater environmental uncertainty{p_end}
{p 8 12 2}- EUI values are comparable within the same industry over time{p_end}
{p 8 12 2}- Cross-industry comparisons should consider industry-specific characteristics{p_end}

{title:Also see}

{p 4 4 2}
Manual: {help import excel}, {help collapse}, {help ipolate}, {help merge}, {help tabstat}{p_end}
{p 4 4 2}
To display version information: {cmd:eui_version}{p_end}

{hline}
{*}