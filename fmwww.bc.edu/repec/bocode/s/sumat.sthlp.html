{smcl}
{* *! version 0.23}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help statsby" "help statsby"}{...}
{vieweralsosee "Help table" "help table"}{...}
{vieweralsosee "Help summarize" "help summarize"}{...}
{vieweralsosee "Help basetable (if installed)" "help basetable"}{...}
{vieweralsosee "Help outsum (if installed)" "help outsum"}{...}
{vieweralsosee "Help outtable (if installed)" "help outtable"}{...}
{vieweralsosee "Help statsmat (if installed)" "help statsmat"}{...}
{vieweralsosee "Help tabexport (if installed)" "help tabexport"}{...}
{vieweralsosee "Help tabout (if installed)" "help tabout"}{...}
{vieweralsosee "Help tabstatmat (if installed)" "help tabstatmat"}{...}
{viewerjumpto "Syntax" "sumat##syntax"}{...}
{viewerjumpto "Description" "sumat##description"}{...}
{viewerjumpto "List of statistics" "sumat##statistics"}{...}
{viewerjumpto "Examples" "sumat##examples"}{...}
{viewerjumpto "Stored results" "sumat##results"}{...}
{viewerjumpto "Author and support" "sumat##author"}{...}
{title:Title}
{phang}{bf:sumat} Statistical summary table - A wrapper and extension of 
{help summarize:summarize}

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:sumat} varlist [{help if}] [{help in}] [{help using}] {cmd:,}
statistics({help sumat##statistics:list of statistics}) 
[{it:options} {it:matprint_options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt stat:istics(string)}}Specify {help sumat##statistics:list of statistics}
to get summarized for each variable{p_end}
{syntab:Optional}
{synopt:{opt p:pct(integer 95)}}An integer between 0 and 100 specifying the
p value used in confidence and predection intervals{p_end}
{synopt: {opt row:by(varname)}}The name of a categorical variable used to group by 
rowwise{p_end}
{synopt: {opt col:by(varname)}}The name of a categorical variable used to group by 
columnwise{p_end}
{synopt:{opt t:otal}}Add a row and/or a column total. 
Only if {opt row:by} and/or {opt col:by} is used{p_end}
{synopt:{opt f:ull}}Get all summary rows even if they are empty. 
Option only if {opt row:by} or {opt col:by} is set.
Is set by default if both {opt row:by} and {opt col:by} is set{p_end}
{synopt:{opt nol:abel}} Do not use variable labels and value labels as row and 
column eq and names{p_end}
{synopt:{opt h:ide(integer)}}To use pseudo percentiles. 
Pseudo percentiles are found by sorting the values and averaging a number of 
values around each position. The averages are used to get percentiles
Specify the non negative integer to average around. 
Default is zero, i.e. use original values{p_end}
{synopt:{opt v:erbose}} Show underlying Stata commands used. Sometimes only Mata 
code is used{p_end}
{synopt:{opt tr:ansposed}} Transpose the returned matrix{p_end}
{synoptline}
{syntab:Matprint options}
{synopt:{opt s:tyle(string)}} Style for output. One of the values {bf:smcl} (default), 
{bf:csv} (semicolon separated style), 
{bf:latex or tex} (latex style),
{bf:html} (html style) and
{bf:md} (markdown style, experimental) 
{p_end}
{synopt:{opt d:ecimals(string)}} Matrix of integers specifying numbers of 
decimals at cell level. If the matrix is smaller than the data matrix the right
most column is copied to get the same number of columns. 
And likewise for the bottom row{p_end}
{synopt:{opt ti:tle(string)}} Title/caption for the matrix output{p_end}
{synopt:{opt to:p(string)}} String containing text prior to table content.
Default is dependent of the value of the style option{p_end}
{synopt:{opt u:ndertop(string)}} String containing text between header and table 
content.
Default is dependent of the value of the style option{p_end}
{synopt:{opt b:ottom(string)}} String containing text after to table content.
Default is dependent of the value of the style option{p_end}
{synopt:{opt r:eplace}} Delete an existing {help using:using} file before adding table{p_end}
{synopthdr:version 13 and up}
{synopt:{opt toxl:(string)}}A string containing up to 5 values separated 
	by a comma. The values are:{break}
	* path and filename on the excel book to save in. Excel book suffix is set/reset to {cmd:xls} for Stata 13 and to {cmd:xlsx} for Stata 14 and above{break}
	* the sheet name to save output in{break}
	* (Optional) replace - replace/overwrite the content in the sheet{break}
	* (Optional) row, column numbers for the upper right corner of the table in the sheet{break}
	* (Optional) columnn widths in parentheses. If more columns than widths the last column width is used for the rest
	{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:sumat} is a flexible tool to generate survey tables. It differs from 
existing tools in that more statistics are possible to report and in that
the summary table is saved for further data handling.

{pstd}
{cmd:sumat} is integrated with {help matprint:matprint} such that styling in smcl,
html, latex, csv and markdown is quite easy.


{marker statistics}{...}
{title:List of statistics}
{phang} Any non lowercase version of statistics below will also do as an argument.

{dlgtab:From summarize}
{phang} Only for non string variables. In case of a string variable the value 
missing (.) is returned.

{synoptset 25 tabbed}{...}
{synopt:{cmd:n count}}number of observations{p_end}
{synopt:{cmd:sum}}sum of variable{p_end}
{synopt:{cmd:sum_w}}sum of the weights{p_end}
{synopt:{cmd:mean}}mean{p_end}
{synopt:{cmd:sd}}standard deviation{p_end}
{synopt:{cmd:Var}}variance{p_end}
{synopt:{cmd:skewness}}skewness{p_end}
{synopt:{cmd:kurtosis}}kurtosis{p_end}
{synopt:{cmd:min}}minimum{p_end}
{synopt:{cmd:max}}maximum{p_end}
{dlgtab:Derived values}
{synoptset 25 tabbed}{...}
{synopt:{cmd:pX}}Xst percentile for X an integer between 1 and 99. Calculations
are similar to to those from the command {help centile} and not as in 
{help summarize}{p_end}
{synopt:{cmd:median}}50st percentile{p_end}
{synopt:{cmd:semean}}Standard error of mean (= standard deviation / sqrt(n)){p_end}
{synopt:{cmd:gmean}}The geometric mean{p_end}
{synopt:{cmd:gsd}}Exponentiated standard deviation of the geometric mean{p_end}
{synopt:{cmd:gse}}Exponentiated standard error of the geometric mean{p_end}
{synopt:{cmd:cv}}Coefficient of variation (= standard dviation / mean){p_end}
{synopt:{cmd:range}}(= max - min){p_end}
{synopt:{cmd:ci}}confidence interval (= mean +/- z(alfa) * standard deviation / sqrt(n)). 
The value for alfa can be set by option {opt p:pct}{p_end}
{synopt:{cmd:pi}}prediction interval (= mean +/- z(alfa) * standard deviation). 
The value for alfa can be set by option {opt p:pct}{p_end}
{synopt:{cmd:iqr}}interquartile range (= p75 - p25){p_end}
{synopt:{cmd:iqi}}interquartile interval (= (p25, p75)){p_end}
{synopt:{cmd:idi}}interdecentile interval = (p10, p90)){p_end}
{synopt:{cmd:fraction}}The row fraction of nonmissing values. 
Only interesting together with the {opt row:by} option{p_end}
{synopt:{cmd:missing}}number of missing values for the variable. 
Works for all types of variables{p_end}
{synopt:{cmd:unique}}number of unique non missing values for the variable 
Works for all types of variables{p_end}

{marker examples}{...}
{title:Examples}

{phang}{stata `"sysuse auto ,clear"'}{p_end}

{phang} Create a summary matrix statistics n, fraction, missing, 
unique, mean, sd and a 75% interquartile interval for the variables price and 
mpg by foreign (columns) and rep78 (rows)
(see {help matprint:matprint}):{p_end}
{phang}{stata `"sumat price mpg, statistics(n fraction missing unique median iqi) rowby(rep78) colby(foreign) decimals(J(1,2,(0,2,0,0,1,1,1)))"'}{p_end}

{phang}The output from {cmd: sumat} can easily be exported to excel (and word) 
using option {opt toxl:}.{p_end}
{phang}Here the output is saved in sheet "tbl" at the Excel workbook "tbls.xls(x)"
in current directory:{p_end}
{phang}{stata `"sumat price mpg, statistics(median iqi) rowby(rep78) colby(foreign) decimals(1) toxl(tbls, tbl)"'}{p_end}
{phang}To see current directory:{p_end}
{phang}{stata cd}{p_end}
{phang}To see Excel workbook (stata 13):{p_end}
{phang}{stata shell tbls.xls}{p_end}
{phang}To see Excel workbook (stata 14 and up):{p_end}
{phang}{stata shell tbls.xlsx}{p_end}

{phang}The option {opt f:ull} is to maintain same tablesize when using {opt row:by}:{p_end}
{phang}{stata `"sumat foreign if !foreign, statistics(n fraction) rowby(rep78) total full"'}{p_end}
{phang}{stata `"sumat foreign if foreign, statistics(n fraction) rowby(rep78) total full"'}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:sumat} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrix}{p_end}
{synopt:{cmd:r(sumat)}}The matrix containing all the specified values{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Section for General Practice, {break}
	Dept. Of Public Health, {break}
	Aarhus University
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":nhbr@ph.au.dk}
{p_end}
