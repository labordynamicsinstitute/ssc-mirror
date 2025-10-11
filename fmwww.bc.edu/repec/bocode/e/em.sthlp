{smcl}
{* *! version 1.0 09Oct2025}{...}
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
{synopt:{opt using}}path to raw data Excel file; default is "D:\Academic Friends\Dingyuan Accounting 202502\data\emdata\rawdata.xlsx"{p_end}
{synopt:{opt datafolder}({it:string})}path to folder containing Excel data files; alternative to using{p_end}
{synopt:{opt outputfolder}({it:string})}path to folder for output files; default is "D:\Academic Friends\Dingyuan Accounting 202502\report"{p_end}
{synopt:{opt replace}}overwrite existing log and output files{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:em} implements the Modified Jones Model (Dechow, Sloan, and Sweeney, 1995) 
for measuring earnings management through discretionary accruals. The command 
processes financial statement data from Excel files, estimates model parameters 
by year-industry groups, and calculates both discretionary and non-discretionary accruals.

{p 4 4 2}
The command automatically handles log file management, closes any open logs before 
starting, and generates comprehensive output including descriptive statistics 
and regression results.

{title:Options}

{phang}
{opt using} specifies the path to the raw data Excel file containing all required 
data sheets. The file must contain four sheets named Sheet1, Sheet2, Sheet3, and Sheet4 
with appropriate data structure. Default is "D:\Academic Friends\Dingyuan Accounting 202502\data\emdata\rawdata.xlsx".

{phang}
{opt datafolder(string)} specifies the path to the folder containing the 
required Excel data files. This is an alternative to the using option. 
Default is "D:\Academic Friends\Dingyuan Accounting 202502\data\emdata".

{phang}
{opt outputfolder(string)} specifies the path to the folder where output 
files will be saved. The command will create several output files including 
the main dataset, log file, and statistical tables. Default is 
"D:\Academic Friends\Dingyuan Accounting 202502\report".

{phang}
{opt replace} allows overwriting existing output files. If specified, the command 
will replace any existing log file and output datasets. Without this option, 
the command will append to existing log files.

{title:Required Data File}

{p 4 4 2}
The Excel file must contain four sheets with the following data:

{phang2}
1. {bf:Sheet1} - Contains industry codes, total assets ({bf:at}), net income ({bf:ni}), and revenue ({bf:revenue}){p_end}
{phang2}
2. {bf:Sheet2} - Contains cash flow from operating activities ({bf:cfo}){p_end}
{phang2}
3. {bf:Sheet3} - Contains receivables ({bf:rec}) and fixed assets data{p_end}
{phang2}
4. {bf:Sheet4} - Contains net fixed assets ({bf:ppe}); only consolidated statements (type "A") are used{p_end}

{title:Variables Created}

{p 4 4 2}
The command creates the following key variables in the output dataset:

{phang2}
{bf:stkcd} - Stock code identifier{p_end}
{phang2}
{bf:year} - Year{p_end}
{phang2}
{bf:ta_at} - Total accruals scaled by lagged total assets{p_end}
{phang2}
{bf:nda_at} - Non-discretionary accruals scaled by lagged total assets{p_end}
{phang2}
{bf:da_at} - Discretionary accruals scaled by lagged total assets (earnings management measure){p_end}
{phang2}
{bf:alpha0, alpha1, alpha2} - Estimated coefficients from the Modified Jones Model{p_end}
{phang2}
{bf:year_ind} - Year-industry group identifier{p_end}

{title:Output Files}

{p 4 4 2}
The command generates the following output files in the outputfolder:

{phang2}
{bf:em_results.dta} - Main Stata dataset with all calculated variables and results{p_end}
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
Basic usage with default file:

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
The command stores the main results in the dataset saved as em_results.dta. 
Additionally, it generates RTF tables with descriptive statistics and 
regression results.

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