{smcl}
{* *! version 1.2 02May2026}{...}
{hline}
{cmd:em} {hline 2} Modified Jones Model for Earnings Management Measurement
{hline}

{title:Title}

{p 4 4 2}
{bf:em} - Calculate earnings management measures using the Modified Jones Model (Dechow et al., 1995)

{title:Syntax}

{p 8 8 2}
{cmd:em} [using] [, {opt datafolder}({it:string}) {opt outputfolder}({it:string}) {opt replace}]

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt using}}path to raw data Excel file; default is "rawdata.xlsx" in the current working directory{p_end}
{synopt:{opt datafolder}({it:string})}path to folder containing the Excel data file; alternative to using{p_end}
{synopt:{opt outputfolder}({it:string})}path to folder for output files; default is the current working directory{p_end}
{synopt:{opt replace}}overwrite existing log and output files{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:em} implements the Modified Jones Model (Dechow, Sloan, and Sweeney, 1995) 
for measuring earnings management through discretionary accruals. The command 
processes financial statement data from an Excel file, estimates model parameters 
by year-industry groups, and calculates both discretionary and non-discretionary accruals.

{p 4 4 2}
The command automatically handles log file management, closes any open logs before 
starting, and generates comprehensive output including descriptive statistics 
and regression results. All output files (Stata dataset, Excel file, log, and RTF tables) 
are saved in the specified output folder (by default, the current working directory). 
The full path to the Excel results file is displayed in the Stata results window.

{p 4 4 2}
Starting with version 1.2, all file path macros are enclosed in compound double quotes 
({cmd:`"`macroname'"'}) to robustly handle spaces and special characters in directory names.

{title:Options}

{phang}
{opt using} specifies the path to the raw data Excel file containing all required 
data sheets. The file must contain four sheets named Sheet1, Sheet2, Sheet3, and Sheet4 
with appropriate data structure. Default is "rawdata.xlsx" in the current working directory.

{phang}
{opt datafolder(string)} specifies the path to the folder containing the 
required Excel data file. This is an alternative to the using option. 
The command will look for a file named "rawdata.xlsx" inside this folder.

{phang}
{opt outputfolder(string)} specifies the path to the folder where output 
files will be saved. The command will create several output files including 
the main dataset, Excel file, log file, and statistical tables. Default is 
the current working directory.

{phang}
{opt replace} allows overwriting existing output files. If specified, the command 
will replace any existing log file, output dataset, and Excel file. Without this option, 
the command will append to existing log files.

{title:Required Data File}

{p 4 4 2}
The Excel file must contain four sheets with the following data. All sheets must include 
a string variable {bf:date} (e.g., "20201231") from which the year is extracted, and a numeric 
variable {bf:stkcd} for firm identifier. The {bf:code} variable in Sheet1 contains industry codes.

{phang2}
1. {bf:Sheet1} - Contains {bf:stkcd}, {bf:date}, {bf:code} (industry code), {bf:at} (total assets), {bf:ni} (net income), and {bf:revenue}{p_end}
{phang2}
2. {bf:Sheet2} - Contains {bf:stkcd}, {bf:date}, and {bf:cfo} (cash flow from operating activities){p_end}
{phang2}
3. {bf:Sheet3} - Contains {bf:stkcd}, {bf:date}, and {bf:rec} (receivables){p_end}
{phang2}
4. {bf:Sheet4} - Contains {bf:stkcd}, {bf:date}, {bf:type} ("A" for consolidated, "B" for parent), and {bf:ppe} (net fixed assets){p_end}

{title:Variables Created}

{p 4 4 2}
The command creates the following key variables in the output dataset:

{phang2}
{bf:stkcd} - Stock code identifier{p_end}
{phang2}
{bf:year} - Year extracted from {bf:date}{p_end}
{phang2}
{bf:ta_at} - Total accruals scaled by lagged total assets{p_end}
{phang2}
{bf:nda_at} - Non-discretionary accruals scaled by lagged total assets{p_end}
{phang2}
{bf:da_at} - Discretionary accruals scaled by lagged total assets
{p_end}
{phang2}
{bf:alpha0, alpha1, alpha2} - Estimated coefficients from the Modified Jones Model{p_end}
{phang2}
{bf:year_ind} - Year-industry group identifier{p_end}

{title:Output Files}

{p 4 4 2}
The command generates the following output files in the output folder:

{phang2}
{bf:em_results.dta} - Main Stata dataset with all calculated variables and results{p_end}
{phang2}
{bf:em_results.xlsx} - Same data exported to Excel; the file path is displayed in the results window{p_end}
{phang2}
{bf:earnings_management_analysis.log} - Detailed log file of the analysis process{p_end}
{phang2}
{bf:descriptive_stats_variables.rtf} - Descriptive statistics for all model variables{p_end}
{phang2}
{bf:descriptive_stats_em.rtf} - Descriptive statistics for earnings management measures{p_end}
{phang2}
{bf:jones_model_regression.rtf} - Example regression results from one year-industry group{p_end}

{title:Remarks}

{p 4 4 2}
The Modified Jones Model is estimated separately for each year-industry group 
to account for temporal and sectoral variations in accrual patterns. The model 
is specified as:

{p 8 8 2}
TA/AT_{t-1} = α₀(1/AT_{t-1}) + α₁(ΔREV/AT_{t-1}) + α₂(PPE/AT_{t-1}) + ε

{p 4 4 2}
where TA is total accruals, AT is total assets, ΔREV is change in revenue, 
and PPE is property, plant, and equipment.

{title:Examples}

{p 4 4 2}
Basic usage with default file in current directory:

{phang2}{cmd:. em}{p_end}

{p 4 4 2}
Specify custom data file:

{phang2}{cmd:. em using "C:/myproject/data/rawdata.xlsx"}{p_end}

{p 4 4 2}
Specify custom folders:

{phang2}{cmd:. em, datafolder("C:/myproject/data") outputfolder("C:/myproject/results")}{p_end}

{p 4 4 2}
Overwrite existing files:

{phang2}{cmd:. em, replace}{p_end}

{p 4 4 2}
Combine custom file with replace option:

{phang2}{cmd:. em using "C:/myproject/data/rawdata.xlsx", replace}{p_end}

{title:Stored Results}

{p 4 4 2}
The command stores the main results in the dataset saved as em_results.dta and also 
exports them to em_results.xlsx. Additionally, it generates RTF tables with descriptive 
statistics and regression results.

{title:Version History}

{p 4 4 2}
1.2 (02May2026): Improved robustness of macro references using compound double quotes to prevent errors when file paths contain spaces or special characters.

{p 4 4 2}
1.0 (23Apr2026): Initial release.

{title:Authors}

{p 4 4 2}
Wu Lianghai{p_end}
{p 6 6 2}School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 6 6 2}Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{p 4 4 2}
Wu Hanyan{p_end}
{p 6 6 2}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), China{p_end}
{p 6 6 2}Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{p 4 4 2}
Liu Rui{p_end}
{p 6 6 2}School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{p 6 6 2}Email: {browse "mailto:3221241855@qq.com":3221241855@qq.com}{p_end}

{p 4 4 2}
Yang Lu{p_end}
{p 6 6 2}Finance Bureau of Rugao City, Nantong City, Jiangsu Province, China{p_end}
{p 6 6 2}Email: {browse "mailto:1026835594@qq.com":1026835594@qq.com}{p_end}

{title:Acknowledgments}

{p 4 4 2}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions.

{title:Reference}

{p 4 4 2}
Dechow, P. M., Sloan, R. G., & Sweeney, A. P. (1995). Detecting earnings management. 
{it:The Accounting Review}, 70(2), 193-225.

{title:Also see}

{p 4 4 2}
Manual: {helpb import excel}, {helpb statsby}, {helpb xtset}, {helpb egen}{p_end}

{hline}