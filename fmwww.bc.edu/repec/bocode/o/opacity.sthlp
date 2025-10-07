[file name]: opacity.sthlp
[file content begin]
{smcl}
{title:Title}

{phang}
{bf:opacity} {hline 2} Calculate information opacity measures following Bhattacharya et al. (2003)


{title:Syntax}

{p 8 17 2}
{cmd:opacity} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt savepath(string)}}path for saving output datasets{p_end}
{synopt:{opt logpath(string)}}path for saving log files and tables{p_end}
{synopt:{opt replace}}replace existing output files{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:opacity} calculates information opacity measures for listed companies 
following the methodology of Bhattacharya, Daouk, and Welker (2003). 
The program computes three components of information opacity and combines 
them into a comprehensive opacity index.

{pstd}
The three components are:

{p 8 12 2}
1. {it:Earnings volatility}: Standard deviation of return on assets scaled by absolute earnings{p_end}
{p 8 12 2}
2. {it:Cash flow volatility}: Standard deviation of cash flows from operations scaled by absolute cash flows{p_end}
{p 8 12 2}
3. {it:Stock price synchronicity}: 1 minus R-squared from market model regression{p_end}

{pstd}
The comprehensive opacity index is the average of these three components.


{title:Options}

{phang}
{opt savepath(string)} specifies the directory path for saving intermediate 
and final datasets. If not specified, the current working directory is used.

{phang}
{opt logpath(string)} specifies the directory path for saving log files 
and output tables. If not specified, the current working directory is used.

{phang}
{opt replace} allows the program to replace existing output files with the same names.


{title:Required Data File}

{pstd}
The program requires the following Excel file in the working directory:

{p 8 12 2}- {bf:opacity.xlsx}: Contains all data in four worksheets:{p_end}
{p 12 15 2}  {bf:Sheet1}: Market return data with variables {it:year}, {it:mkt}, {it:mkt_ret}{p_end}
{p 12 15 2}  {bf:Sheet2}: Firm characteristics with {it:stkcd}, {it:year}, {it:mkt}{p_end}
{p 12 15 2}  {bf:Sheet3}: Accounting data with {it:stkcd}, {it:date}, {it:roa}, {it:cfo}, {it:at}{p_end}
{p 12 15 2}  {bf:Sheet4}: Industry classification with {it:stkcd}, {it:date}, {it:code}{p_end}


{title:Dependencies}

{pstd}
The program requires the {cmd:asreg} package for rolling window regressions. 
If not installed, the program will display an error message with installation instructions.


{title:File Location}

{pstd}
The program expects the opacity.xlsx file to be located in the current working directory.
If the file is not found, the program will display an error message with instructions.


{title:Output}

{pstd}
The program generates the following output:

{p 8 12 2}- {bf:opacity_final.dta}: Final dataset with opacity measures{p_end}
{p 8 12 2}- {bf:descriptive_statistics.rtf}: Descriptive statistics table{p_end}
{p 8 12 2}- {bf:yearly_statistics.rtf}: Year-by-year statistics{p_end}
{p 8 12 2}- {bf:industry_statistics.rtf}: Industry comparison table{p_end}
{p 8 12 2}- {bf:opacity.log}: Log file with execution details{p_end}


{title:Variables Created}

{pstd}
{cmd:opacity} creates the following variables:

{p2colset 10 25 37 2}{...}
{p2col:Variable}Description{p_end}
{p2line}
{p2col:{cmd:earnsync}}Earnings volatility component{p_end}
{p2col:{cmd:cfsync}}Cash flow volatility component{p_end}
{p2col:{cmd:pricesync}}Stock price synchronicity component{p_end}
{p2col:{cmd:opacity}}Comprehensive information opacity index{p_end}
{p2line}


{title:Remarks}

{pstd}
This implementation is specifically designed for Chinese A-share listed companies 
and follows the original methodology from Bhattacharya et al. (2003) with 
adaptations for the Chinese market context.

{pstd}
The program requires the {cmd:asreg} package for rolling window regressions. 
If the package is not installed, the program will provide instructions to install it using:
{break}{cmd:ssc install asreg, replace}


{title:Examples}

{pstd}
Basic usage:{p_end}
{phang2}{cmd:. opacity}{p_end}

{pstd}
Specify custom paths:{p_end}
{phang2}{cmd:. opacity, savepath("D:/research/data") logpath("D:/research/output")}{p_end}

{pstd}
Replace existing files:{p_end}
{phang2}{cmd:. opacity, replace}{p_end}


{title:References}

{pstd}
Bhattacharya, U., Daouk, H., & Welker, M. 2003. The world price of earnings opacity. 
{it:The Accounting Review} 78(3): 641-678.

{pstd}
Wu, L., Liu, R., & Jin, X. 2025. Information Opacity Measurement for Chinese Listed Companies. 
Anhui University of Technology.


{title:Authors}

{pstd}
Wu Lianghai, Liu Rui, Jin Xuening{p_end}
{pstd}
Anhui University of Technology (AHUT){p_end}
{pstd}
Ma'anshan, China{p_end}
{pstd}
E-mail: {browse "agd2010@yeah.net":agd2010@yeah.net}{p_end}
{pstd}
Date: October 2, 2025{p_end}
[file content end]