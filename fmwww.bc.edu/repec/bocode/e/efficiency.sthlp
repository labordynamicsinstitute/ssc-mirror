{smcl}
{* October 3rd, 2025}{...}
{hline}
{title:Title}

{p 4 4 2}
{bf:efficiency} - Calculate investment efficiency based on Richardson (2006) model with single Excel file import functionality

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
{cmd:efficiency} calculates investment efficiency measures based on the Richardson (2006) model. {break}
This version includes functionality to import and merge data from multiple sheets within a single Excel file.

{p 4 4 2}
The program automatically imports data from multiple sheets (Sheet1 to Sheet10 by default) from the specified Excel file,{break}
merges them into a panel dataset, and then estimates the investment efficiency model.

{p 4 4 2}
The investment efficiency model follows Richardson (2006):

{p 8 8 2}
Invest_it = α + β₁·L1.Invest_it + β₂·L1.Size_it + β₃·L1.Lev_it + β₄·L1.Cash_it + {break}
β₅·L1.Age_it + β₆·L1.Return_it + β₇·L1.TobinQ_it + β₈·State_it + β₉·L1.SalesGrowth_it + {break}
YearDummies + IndustryDummies + ε_it

{p 4 4 2}
Where:{p_end}
{p 8 12 2}- Invest_it: Investment expenditure in year t{p_end}
{p 8 12 2}- L1.Invest_it: Lagged investment expenditure{p_end}
{p 8 12 2}- L1.Size_it: Lagged firm size (log of total assets){p_end}
{p 8 12 2}- L1.Lev_it: Lagged leverage ratio{p_end}
{p 8 12 2}- L1.Cash_it: Lagged cash holdings{p_end}
{p 8 12 2}- L1.Age_it: Lagged firm age{p_end}
{p 8 12 2}- L1.Return_it: Lagged stock return{p_end}
{p 8 12 2}- L1.TobinQ_it: Lagged Tobin's Q{p_end}
{p 8 12 2}- State_it: State ownership dummy{p_end}
{p 8 12 2}- L1.SalesGrowth_it: Lagged sales growth{p_end}

{p 4 4 2}
Investment inefficiency is measured as the absolute residual from the model:

{p 8 8 2}
Abs_InEff = |Invest_it - Invest_Predicted_it|{p_end}

{p 4 4 2}
Over-investment and under-investment are calculated as:

{p 8 8 2}
Over_Invest = max(0, Invest_it - Invest_Predicted_it){p_end}
{p 8 8 2}
Under_Invest = max(0, Invest_Predicted_it - Invest_it){p_end}

{title:Options}

{p 4 4 2}
{cmd:FILEpath(}{it:string}{cmd:)} specifies the path to the Excel file containing multiple sheets. {it:Required}.{p_end}

{p 4 4 2}
{cmd:SHEETnum(}{it:integer}{cmd:)} specifies the number of sheets to import from the Excel file. Default is 10.{p_end}

{p 4 4 2}
{cmd:SAVEpath(}{it:string}{cmd:)} specifies the path and filename to save the results dataset.{p_end}

{p 4 4 2}
{cmd:REPLACE} allows overwriting an existing file when used with {cmd:SAVEpath}.{p_end}

{title:Data Requirements}

{p 4 4 2}
The program expects a single Excel file with multiple sheets (Sheet1 to Sheet10 by default) with the following structure:{p_end}
{p 8 12 2}- Each sheet should contain a {cmd:stkcd} variable (firm identifier){p_end}
{p 8 12 2}- Each sheet should contain either a {cmd:year} variable or a {cmd:date} variable{p_end}
{p 8 12 2}- Sheets should contain various financial variables (invest, size, lev, cash, age, ret, tobinq, state, salegrowth){p_end}
{p 8 12 2}- One sheet should contain a {cmd:code} variable for industry classification{p_end}

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
The program also displays summary statistics for these variables.{p_end}

{title:References}

{p 4 4 2}
Richardson, S. (2006). Over-investment of free cash flow. {it:Review of Accounting Studies}, 11(2-3), 159-189.{p_end}

{p 4 4 2}
Biddle, G. C., Hilary, G., & Verdi, R. S. (2009). How does financial reporting quality relate to investment efficiency? {it:Journal of Accounting and Economics}, 48(2-3), 112-131.{p_end}

{p 4 4 2}
Chen, F., Hope, O. K., Li, Q., & Wang, X. (2011). Financial reporting quality and investment efficiency of private firms in emerging markets. {it:The Accounting Review}, 86(4), 1255-1288.{p_end}

{title:Acknowledgments}

{p 4 4 2}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions.{p_end}

{title:Also See}

{p 4 4 2}
Manual: {manhelp import_excel D}, {manhelp xtreg R}, {manhelp predict R}{p_end}

{hline}