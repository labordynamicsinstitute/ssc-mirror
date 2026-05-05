{smcl}
{* 02May2026}{...}
{hline}
{cmd:conservatism} {hline 2} Khan & Watts (2009) Accounting Conservatism Measurement


{title:Syntax}

{p 8 17 2}
{cmd:conservatism}
{cmd:using}
{it:directory_path}
[{cmd:,} {opt out:path(string)} {opt save}]


{title:Description}

{pstd}
{cmd:conservatism} implements the Khan & Watts (2009) accounting conservatism 
measurement model for Chinese A-share listed companies. The program calculates 
the C_SCORE measure of accounting conservatism based on firm characteristics 
including size, market-to-book ratio, and leverage.

{pstd}
The program automatically performs the following steps:

{phang}1. Loads and merges required Excel data files{p_end}
{phang}2. Cleans data and generates necessary variables{p_end}
{phang}3. Estimates the Basu (1997) model for initial values{p_end}
{phang}4. Estimates the nonlinear Khan & Watts model (with linear approximation fallback){p_end}
{phang}5. Calculates firm-year specific conservatism scores (C_SCORE){p_end}
{phang}6. Displays descriptive statistics and results summary{p_end}


{title:Options}

{phang}
{opt using} specifies the directory path containing the required Excel data files.

{phang}
{opt outpath(string)} specifies the output directory for saving results. 
If not specified, the current working directory is used.

{phang}
{opt save} saves the final dataset as both Stata (.dta) and CSV (.csv) files.
For the Stata dataset, a prompt to type {cmd:browse} is shown; 
for the CSV file, a clickable link is provided to open it directly.


{title:Required Data Files}

{pstd}
The program requires the following Excel files in the specified directory:

{phang2}• {bf:d1.xlsx} (Stock return data) - containing variables: stkcd, year, R{p_end}
{phang2}• {bf:d2.xlsx} (Price, MTB, and leverage data) - containing variables: stkcd, date, MTB, LEV{p_end}
{phang2}• {bf:d3.xlsx} (Total assets and net profit data) - containing variables: stkcd, date, ta, profit{p_end}
{phang2}• {bf:d4.xlsx} (Market value data) - containing variables: stkcd, date, MV, code{p_end}

{pstd}
All files should have 'sheet1' as the worksheet name and variable names in the first row.


{title:Model Specification}

{pstd}
The Khan & Watts (2009) model extends the Basu (1997) asymmetric timeliness 
model by allowing the conservatism coefficients to vary with firm characteristics:

{pmore}
1. Basu (1997) model: X_i,t = β0 + β1·D_i,t + β2·R_i,t + β3·D_i,t·R_i,t + ε_i,t

{pmore}
2. Khan & Watts extension:{p_end}
{pmore}   β2_i,t = μ0 + μ1·SIZE_i,t + μ2·MTB_i,t + μ3·LEV_i,t{p_end}
{pmore}   β3_i,t = λ0 + λ1·SIZE_i,t + λ2·MTB_i,t + λ3·LEV_i,t

{pmore}
3. Conservatism measure: C_SCORE_i,t = β3_i,t = λ0 + λ1·SIZE_i,t + λ2·MTB_i,t + λ3·LEV_i,t

{pstd}
Where:{p_end}
{phang2}• X = profit / lagged market value{p_end}
{phang2}• D = indicator variable for negative returns (R < 0){p_end}
{phang2}• R = stock return{p_end}
{phang2}• SIZE = natural logarithm of total assets{p_end}
{phang2}• MTB = market-to-book ratio{p_end}
{phang2}• LEV = leverage ratio{p_end}


{title:Variables Created}

{phang}
{cmd:C_SCORE} - Accounting conservatism measure based on Khan & Watts (2009)


{title:Output}

{pstd}
The program displays the following information:

{phang2}• Program version and author information{p_end}
{phang2}• Data loading and preparation progress{p_end}
{phang2}• Basu model coefficients for initial values{p_end}
{phang2}• Khan & Watts model coefficients (nonlinear or linear approximation){p_end}
{phang2}• Descriptive statistics for key variables{p_end}
{phang2}• Model type used (nonlinear/linear_approximation){p_end}
{phang2}• Final sample size{p_end}
{phang2}• If {opt save} is specified: a prompt to type {cmd:browse} for the Stata dataset, 
and a clickable link to open the CSV file{p_end}


{title:Estimation Methods}

{pstd}
The program employs two estimation approaches:

{phang2}1. {bf:Nonlinear least squares}: Primary method using Stata's {cmd:nl} command{p_end}
{phang2}2. {bf:Linear approximation}: Fallback method if nonlinear estimation fails{p_end}

{pstd}
The program automatically selects the appropriate method and reports which method was used.


{title:Examples}

{pstd}
Basic usage:{p_end}
{phang2}{cmd:. conservatism using "E:\research\data\"}{p_end}

{pstd}
With output directory and saving results:{p_end}
{phang2}{cmd:. conservatism using "E:\research\data\", outpath("E:\research\results\") save}{p_end}


{title:Error Handling}

{pstd}
The program includes robust error handling features:

{phang2}• Automatically handles missing values in key variables{p_end}
{phang2}• Provides fallback linear approximation if nonlinear estimation fails{p_end}
{phang2}• Checks data availability and provides informative error messages{p_end}
{phang2}• Validates file paths and directory existence{p_end}
{phang2}• Cleans up temporary files after execution{p_end}


{title:Authors}

{pstd}
Wu Lianghai{p_end}
{pstd}School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{pstd}Email: {browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{p_end}

{pstd}
Wu Hanyan{p_end}
{pstd}School of Economics and Management, Nanjing University of Aeronautics and Astronautics (NUAA), China{p_end}
{pstd}Email: {browse "mailto:2325476320@qq.com":2325476320@qq.com}{p_end}

{pstd}
Chen Liwen{p_end}
{pstd}School of Business, Anhui University of Technology (AHUT), Ma'anshan, China{p_end}
{pstd}Email: {browse "mailto:2184844526@qq.com":2184844526@qq.com}{p_end}


{title:Acknowledgments}

{pstd}
We sincerely appreciate Christopher F. Baum for his prompt guidance and revision suggestions.


{title:References}

{pstd}
Khan, M., and R. L. Watts. 2009. Estimation and empirical properties of a firm-year 
measure of accounting conservatism. {it:Journal of Accounting and Economics} 48: 132-150.

{pstd}
Basu, S. 1997. The conservatism principle and the asymmetric timeliness of earnings. 
{it:Journal of Accounting and Economics} 24: 3-37.


{title:Version}

{pstd}
Version 1.0.6, 02May2026
{hline}