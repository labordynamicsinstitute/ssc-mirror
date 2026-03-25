{smcl}
{* March 24th, 2026}{...}
{hline}
{title:Title}

{p 4 4 2}
{bf:efficiency} - Calculate investment efficiency based on Richardson (2006) with robust multi-sheet merge

{title:Authors}

{p 4 4 2}
Wu Lianghai{break}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{break}
E-mail: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}

{p 4 4 2}
Wu Hanyan{break}
School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), Nanjing, China{break}
E-mail: {browse "mailto:2325476320@qq.com":2325476320@qq.com}

{p 4 4 2}
Chen Liwen{break}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{break}
E-mail: {browse "mailto:2184844526@qq.com":2184844526@qq.com}

{p 4 4 2}
Liu Changyun{break}
School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{break}
E-mail: {browse "mailto:2437563124@qq.com":2437563124@qq.com}

{title:Syntax}

{p 4 4 2}
{cmd:efficiency} {cmd:,} {break}
{cmd:FILEpath(}{it:string}{cmd:)} {break}
[{cmd:SHEETnum(}{it:integer}{cmd:)} {break}
{cmd:SAVEpath(}{it:string}{cmd:)} {break}
{cmd:REPLACE}]

{title:Description}

{p 4 4 2}
{cmd:efficiency} calculates investment efficiency measures following Richardson (2006).{break}
This version imports data from multiple sheets (Sheet1 to Sheet`SHEETnum') of a single Excel file,{break}
automatically merges them by {bf:stkcd} and year, and then estimates the investment efficiency model.

{p 4 4 2}
Each sheet must contain at least {bf:stkcd} and either a numeric {bf:year} variable or a {bf:date} variable.{break}
Variables can be spread across sheets; the program will combine them into a single panel dataset.{break}
If a sheet cannot be imported or lacks key variables, a warning is issued and the sheet is skipped.{break}
After merging, the program checks that all required variables exist; if any are missing, an error is returned.

{p 4 4 2}
The investment efficiency model is estimated using fixed-effects panel regression with clustered standard errors:

{p 8 8 2}
Invest_it = α + β1*L1.Invest_it + β2*L1.Size_it + β3*L1.Lev_it + β4*L1.Cash_it + {break}
β5*L1.Age_it + β6*L1.Return_it + β7*L1.TobinQ_it + β8*State_it + β9*L1.SalesGrowth_it + {break}
YearDummies + IndustryDummies + ε_it

{p 4 4 2}
Investment inefficiency is measured as the absolute residual:

{p 8 8 2}
Abs_InEff = |Invest_it - Invest_Predicted_it|

{p 4 4 2}
Over-investment and under-investment are defined as:

{p 8 8 2}
Over_Invest = max(0, Invest_it - Invest_Predicted_it){break}
Under_Invest = max(0, Invest_Predicted_it - Invest_it)

{title:Options}

{p 4 4 2}
{cmd:FILEpath(}{it:string}{cmd:)} specifies the path to the Excel file containing multiple sheets. {it:Required}.

{p 4 4 2}
{cmd:SHEETnum(}{it:integer}{cmd:)} specifies the number of sheets to import (from Sheet1 to Sheet`SHEETnum'). Default is 10.

{p 4 4 2}
{cmd:SAVEpath(}{it:string}{cmd:)} specifies the path and filename to save the results dataset.

{p 4 4 2}
{cmd:REPLACE} allows overwriting an existing file when used with {cmd:SAVEpath}.

{title:Data Requirements}

{p 4 4 2}
The program expects a single Excel file with multiple sheets (Sheet1, Sheet2, ...). Each sheet must contain:{p_end}
{p 8 12 2}• {bf:stkcd} (firm identifier) – numeric or string{p_end}
{p 8 12 2}• either a numeric {bf:year} variable or a {bf:date} variable (string or Stata date){p_end}
{p 8 12 2}• any subset of the following variables (they can be distributed across sheets):{p_end}
{p 12 16 2}{bf:invest}, {bf:size}, {bf:lev}, {bf:cash}, {bf:age}, {bf:ret}, {bf:tobinq}, {bf:state}, {bf:salegrowth}{p_end}
{p 8 12 2}• one sheet must contain a {bf:code} or {bf:indcd} variable for industry classification (Chinese stock codes preferred){p_end}

{p 4 4 2}
All numeric variables will be automatically converted if imported as strings.{p_end}

{title:Examples}

{p 4 4 2}
Basic usage with default 10 sheets:{p_end}
{p 8 12 2}{cmd:. efficiency, filepath("E:\research_data\rawdata.xlsx")}{p_end}

{p 4 4 2}
Specify different number of sheets:{p_end}
{p 8 12 2}{cmd:. efficiency, filepath("E:\research_data\rawdata.xlsx") sheetnum(8)}{p_end}

{p 4 4 2}
Save results to file:{p_end}
{p 8 12 2}{cmd:. efficiency, filepath("E:\research_data\rawdata.xlsx") savepath("results.dta") replace}{p_end}

{title:Stored Results}

{p 4 4 2}
The program adds the following variables to the dataset:{p_end}
{p 8 12 2}{cmd:Invest_Predicted}: Predicted normal investment level{p_end}
{p 8 12 2}{cmd:Abs_InEff}: Absolute investment inefficiency{p_end}
{p 8 12 2}{cmd:Over_Invest}: Over-investment measure{p_end}
{p 8 12 2}{cmd:Under_Invest}: Under-investment measure{p_end}

{p 4 4 2}
Summary statistics for these variables are displayed after estimation.{p_end}

{title:References}

{p 4 4 2}
Richardson, S. (2006). Over-investment of free cash flow. {it:Review of Accounting Studies}, 11(2-3), 159-189.

{p 4 4 2}
Biddle, G. C., Hilary, G., & Verdi, R. S. (2009). How does financial reporting quality relate to investment efficiency? {it:Journal of Accounting and Economics}, 48(2-3), 112-131.

{p 4 4 2}
Chen, F., Hope, O. K., Li, Q., & Wang, X. (2011). Financial reporting quality and investment efficiency of private firms in emerging markets. {it:The Accounting Review}, 86(4), 1255-1288.

{title:Acknowledgments}

{p 4 4 2}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions.

{title:Also See}

{p 4 4 2}
Manual: {manhelp import_excel D}, {manhelp xtreg R}, {manhelp predict R}

{hline}
{*}