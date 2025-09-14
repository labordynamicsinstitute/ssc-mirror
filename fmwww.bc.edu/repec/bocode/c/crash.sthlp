{smcl}
{* 13sep2025}{...}
{hi:help crash}{right:version 1.1}
{hline}

{title:Title}

{p 4 4 2}
{bf:crash} - Calculate stock crash risk measures (NCSKEW and DUVOL)

{title:Syntax}

{p 4 4 2}
{cmd:crash} [{cmd:using}]{p_end}
{p 6 6 2}
[{cmd:,} {cmd:SAVEpath}({it:string}) {cmd:SHEETnames}({it:string}){p_end}
{p 6 6 2}
{cmd:MARKETvars}({it:string}) {cmd:MINweeks}({it:integer}) {cmd:clear}]

{title:Description}

{p 4 4 2}
{cmd:crash} calculates two measures of stock crash risk - Negative Coefficient of 
Skewness (NCSKEW) and Down-to-Up Volatility (DUVOL) - following the methodology 
described in Chen, Hong, and Stein (2001) and Kim, Li, and Zhang (2011a,b).

{p 4 4 2}
The command processes individual stock return data and market return data from 
Excel files, performs necessary data transformations, estimates regressions to 
calculate residual returns, and finally computes the crash risk measures.

{title:Options}

{phang}
{cmd:using} specifies the path to the Excel file containing stock and market return data.
If not specified, the command will look for the data in the current directory.

{phang}
{cmd:SAVEpath}({it:string}) specifies the directory where results will be saved. 
Default is the current working directory.

{phang}
{cmd:SHEETnames}({it:string}) specifies the names of Excel sheets containing 
individual stock returns (first N-1 sheets) and market returns (last sheet). 
Default is "Sheet1 Sheet2 Sheet3 Sheet4 Sheet5".

{phang}
{cmd:MARKETvars}({it:string}) specifies the variable names for market identifier 
and market returns. Default is "market Wrettmv".

{phang}
{cmd:MINweeks}({it:integer}) specifies the minimum number of trading weeks required 
for a stock-year observation to be included in the analysis. Default is 30.

{phang}
{cmd:clear} clears the memory before executing the command.

{title:Remarks}

{p 4 4 2}
The command expects the Excel file to have the following structure:

{p 6 6 2}
- First N-1 sheets: Individual stock returns data with variables:{p_end}
{p 9 9 2}Stkcd (stock code), date (date), Wkret (weekly return), Wrettmv (value-weighted return){p_end}

{p 6 6 2}
- Last sheet: Market returns data with variables:{p_end}
{p 9 9 2}date (date), market (market identifier), Wrettmv (market return){p_end}

{p 4 4 2}
The command will keep only observations where market equals 1 or 4.

{title:Examples}

{p 4 4 2}
Calculate crash risk measures using default settings:{p_end}
{phang2}{cmd:cd "E:\益友学术\鼎园会计142期\report"}{p_end}
{phang2}{cmd:cap mkdir "E:/益友学术/鼎园会计142期/report/result/"}{p_end}
{phang2}{cmd:crash using returns.xlsx, savepath(./result/)}{p_end}

{p 4 4 2}
Calculate crash risk measures with custom settings:{p_end}
{phang2}{cmd:cap mkdir "E:/益友学术/鼎园会计142期/report/results/"}{p_end}
{phang2}{cmd:crash using returns.xlsx, savepath(./results/) sheetnames(Sheet1 Sheet2 Sheet3 Sheet4 Market) minweeks(40) clear}{p_end}

{p 4 4 2}
Process a file with only one individual stock sheet:{p_end}
{phang2}{cmd:cap mkdir "E:/益友学术/鼎园会计142期/report/results2/"}{p_end}
{phang2}{cmd:cd "E:\益友学术\鼎园会计142期\report\results2"}{p_end}
{phang2}{cmd:crash using returns.xlsx, savepath(./results2/) sheetnames(Individual Market)}{p_end}

{title:Stored results}

{p 4 4 2}
The command saves the following datasets:{p_end}

{p 6 6 2}
- {cmd:crash_dataset.dta}: Merged individual and market return data{p_end}
{p 6 6 2}
- {cmd:crashrisk.dta}: Intermediate data with residual returns{p_end}
{p 6 6 2}
- {cmd:stock_crash_risk.dta}: Final dataset with NCSKEW and DUVOL measures{p_end}

{p 4 4 2}
The command also exports the results to {cmd:stock_crash_risk.xlsx}.

{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT), Ma'anshan, China{p_end}
{pstd}{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA), China{p_end}
{pstd}{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Ding Ming{p_end}
{pstd}School of Business, Anhui University of Technology(AHUT), Ma'anshan, China{p_end}
{pstd}{browse "mailto:dingming0417@163.com":dingming0417@163.com}{p_end}

{title:References}

{p 4 4 2}
Chen, J., Hong, H., & Stein, J. C. (2001). Forecasting crashes: Trading volume, 
past returns, and conditional skewness in stock prices. Journal of Financial Economics, 61(3), 345-381.

{p 4 4 2}
Kim, J. B., Li, Y., & Zhang, L. (2011a). CFOs versus CEOs: Equity incentives and crashes. 
Journal of Financial Economics, 101(3), 713-730.

{p 4 4 2}
Kim, J. B., Li, Y., & Zhang, L. (2011b). Corporate tax avoidance and stock price crash risk: 
Firm-level analysis. Journal of Financial Economics, 100(3), 639-662.

{title:Also see}

{p 4 4 2}
Online: {helpb import excel}, {helpb merge}, {helpb regress}, {helpb egen}
{hline}