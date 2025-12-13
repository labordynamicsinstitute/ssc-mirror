{smcl}
{* *! version 2.1 12Dec2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "tabstat" "help tabstat"}{...}
{vieweralsosee "tabstat2excel" "help tabstat2excel"}{...}
{viewerjumpto "Syntax" "tab2excel##syntax"}{...}
{viewerjumpto "Description" "tab2excel##description"}{...}
{viewerjumpto "Options" "tab2excel##options"}{...}
{viewerjumpto "Examples" "tab2excel##examples"}{...}
{viewerjumpto "Authors" "tab2excel##authors"}{...}
{viewerjumpto "Also see" "tab2excel##alsosee"}{...}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{bf:tab2excel} {hline 2}}Export tabstat results to Excel with enhanced features{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tab2excel} {varlist} [{cmd:if} {it:exp}] [{cmd:in} {it:range}] [{cmd:,}
{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab :Main}
{synopt :{opt lang:uage(string)}}output language, either "chinese" or "english"{p_end}
{synopt :{opt file:name(string)}}output Excel filename{p_end}
{synopt :{opt ti:tle(string)}}title for the Excel sheet{p_end}
{synopt :{opt rep:lace}}replace existing Excel file{p_end}
{synopt :{opt stat:istics(string)}}statistics to export, e.g., "n mean sd min max"{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tab2excel} exports descriptive statistics from {cmd:tabstat} to an Excel file with enhanced formatting features.
The command provides bilingual support (Chinese/English) and automatically formats statistics with appropriate number formats.

{pstd}
Key features:{p_end}
{p 8 12}{hline 60}{p_end}
{p 8 12}• Bilingual output (Chinese/English) with automatic header translation{p_end}
{p 8 12}• Excel hyperlink output for easy file access{p_end}
{p 8 12}• Variable labels support in Excel{p_end}
{p 8 12}• Automatic number formatting (integers for counts, 2 decimals for other stats){p_end}
{p 8 12}• Professional Excel formatting with borders and bold headers{p_end}
{p 8 12}{hline 60}{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Main}
{phang}
{opt language(string)} specifies the output language. Valid values are "chinese" (default) and "english".
When set to "chinese", column headers and titles are displayed in Chinese. When set to "english", 
they appear in English.

{phang}
{opt filename(string)} specifies the output Excel filename. Default is "summary.xlsx".

{phang}
{opt title(string)} specifies the title for the Excel sheet. If not specified, a default title
is used based on the selected language: "描述性统计" for Chinese or "Descriptive Statistics" for English.

{phang}
{opt replace} allows overwriting an existing Excel file. If this option is not specified and
the file already exists, the command will return an error.

{phang}
{opt statistics(string)} specifies which statistics to export. The string should contain
statistic names separated by spaces. Available statistics include:

{p 8 12}{cmd:n} - Number of observations{p_end}
{p 8 12}{cmd:mean} - Mean{p_end}
{p 8 12}{cmd:sd} - Standard deviation{p_end}
{p 8 12}{cmd:var} - Variance{p_end}
{p 8 12}{cmd:cv} - Coefficient of variation{p_end}
{p 8 12}{cmd:sem} - Standard error of the mean{p_end}
{p 8 12}{cmd:skew} - Skewness{p_end}
{p 8 12}{cmd:kurt} - Kurtosis{p_end}
{p 8 12}{cmd:sum} - Sum{p_end}
{p 8 12}{cmd:p1} - 1st percentile{p_end}
{p 8 12}{cmd:p5} - 5th percentile{p_end}
{p 8 12}{cmd:p10} - 10th percentile{p_end}
{p 8 12}{cmd:p25} - 25th percentile{p_end}
{p 8 12}{cmd:p50} - Median (50th percentile){p_end}
{p 8 12}{cmd:p75} - 75th percentile{p_end}
{p 8 12}{cmd:p90} - 90th percentile{p_end}
{p 8 12}{cmd:p95} - 95th percentile{p_end}
{p 8 12}{cmd:p99} - 99th percentile{p_end}
{p 8 12}{cmd:min} - Minimum{p_end}
{p 8 12}{cmd:max} - Maximum{p_end}
{p 8 12}{cmd:iqr} - Interquartile range{p_end}
{p 8 12}{cmd:range} - Range{p_end}

{pstd}Default is {cmd:n mean p25 p50 p75 min max}.

{marker examples}{...}
{title:Examples}

{phang}{ul:Example 1: Basic usage with default options}{p_end}
{pmore}{inp:. sysuse auto, clear}{p_end}
{pmore}{inp:. tab2excel price mpg weight}{p_end}

{phang}{ul:Example 2: Custom statistics with Chinese output}{p_end}
{pmore}{inp:. sysuse auto, clear}{p_end}
{pmore}{inp:. tab2excel price mpg weight, language(chinese) statistics(n mean sd skew kurt min max) title("汽车数据统计摘要") filename("car_stats.xlsx") replace}{p_end}

{phang}{ul:Example 3: English output with custom title}{p_end}
{pmore}{inp:. sysuse auto, clear}{p_end}
{pmore}{inp:. tab2excel price mpg weight, language(english) statistics(n mean p25 p50 p75) title("Automobile Data Summary") filename("auto_summary.xlsx") replace}{p_end}

{phang}{ul:Example 4: Using if condition}{p_end}
{pmore}{inp:. sysuse auto, clear}{p_end}
{pmore}{inp:. tab2excel price mpg weight if foreign == 1, language(english) filename("foreign_cars.xlsx") replace}{p_end}

{marker authors}{...}
{title:Authors}

{pstd}
Wu Lianghai, Liu Rui, Li Min, School of Business, Anhui University of Technology(AHUT) Ma'anshan, China{break}
{browse "mailto:agd2010@yeah.net":agd2010@yeah.net}{break}
{browse "mailto:3221241855@qq.com":3221241855@qq.com}{break}
{browse "mailto:748726942@qq.com":748726942@qq.com}

{pstd}
Wu Hanyan, School of Economics and Management, Nanjing University of Aeronautics and Astronautics(NUAA) Nanjing, China{break}
{browse "mailto:2325476320@qq.com":2325476320@qq.com}

{pstd}
Wu Xinzhuo, University of Bristol(UB){break}
{browse "mailto:2957833979@qq.com":2957833979@qq.com}

{pstd}
Development date: 12 December 2025

{marker alsosee}{...}
{title:Also see}

{psee}
Online: {help tabstat}, {help tabstat2excel}, {help putexcel}
{*}