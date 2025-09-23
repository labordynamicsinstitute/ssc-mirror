{smcl}
{* 21sep2025}{...}
{hi:help scrash}{right:version 1.0}
{hline}

{title:Title}

{p 4 4 2}
{bf:scrash} - Calculate quarterly stock crash risk measures (NCSKEW and DUVOL)

{title:Syntax}

{p 4 4 2}
{cmd:scrash} [{cmd:using}]{p_end}
{p 6 6 2}
[{cmd:,} {cmd:SAVEpath}({it:string}) {cmd:SHEETnames}({it:string}){p_end}
{p 6 6 2}
{cmd:MARKETvars}({it:string}) {cmd:MINdays}({it:integer}) {cmd:clear}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt SAVEpath}({it:string})}save directory path{p_end}
{synopt:{opt SHEETnames}({it:string})}Excel sheet names{p_end}
{synopt:{opt MARKETvars}({it:string})}market variable names{p_end}
{synopt:{opt MINdays}({it:integer})}minimum trading days requirement{p_end}
{synopt:{opt clear}}clear memory before execution{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:scrash} calculates quarterly stock crash risk measures (NCSKEW and DUVOL)
using daily return data. The command processes individual stock returns and
market returns from Excel files, performs required data transformations,
and outputs quarterly crash risk measures.

{title:Options}

{phang}
{opt SAVEpath}({it:string}) specifies the directory where results will be saved.
Default is current working directory. May be abbreviated to {cmd:SAVE}.

{phang}
{opt SHEETnames}({it:string}) specifies Excel sheet names containing individual
stock returns (first N-1 sheets) and market returns (last sheet).
Default is "Sheet1 Sheet2". May be abbreviated to {cmd:SHEET}.

{phang}
{opt MARKETvars}({it:string}) specifies market identifier and return variables.
Default is "market mret". May be abbreviated to {cmd:MARKET}.

{phang}
{opt MINdays}({it:integer}) specifies minimum trading days required per quarter.
Default is 30. May be abbreviated to {cmd:MIN}.

{phang}
{opt clear} clears memory before command execution. May be abbreviated to {cmd:c}.

{title:Examples}

{p 4 4 2}Calculate quarterly crash risk with default settings:{p_end}
{phang2}{cmd:. scrash using returns.xlsx}{p_end}

{p 4 4 2}With custom save path and sheet names:{p_end}
{phang2}{cmd:. scrash using returns.xlsx, save(./results/) sheet(Stocks Market)}{p_end}

{p 4 4 2}With minimum 50 trading days requirement:{p_end}
{phang2}{cmd:. scrash using returns.xlsx, min(50)}{p_end}

{title:Stored results}

{p 4 4 2}
The command saves:
{p_end}
{p 6 6 2}
- quarterly_crash_dataset.dta: merged dataset{p_end}
{p 6 6 2}
- scrashrisk.dta: intermediate data with residuals{p_end}
{p 6 6 2}
- quarterly_crash_risk.dta: final results with NCSKEW and DUVOL{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}
School of Business, Anhui University of Technology(AHUT), Ma'anshan, China{p_end}
{pstd}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA), China{p_end}
{pstd}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Ding Ming{p_end}
{pstd}
School of Business, Anhui University of Technology(AHUT), Ma'anshan, China{p_end}
{pstd}
{browse "mailto:dingming0417@163.com":dingming0417@163.com}{p_end}

{title:Also see}

{p 4 4 2}
{help crash} {hline 2}
Calculate weekly stock crash risk measures

{hline}