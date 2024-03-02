{smcl}
{viewerjumpto "Syntax" "basetable##syntax"}{...}
{viewerjumpto "Basetable varlist" "basetable##varlist"}{...}
{viewerjumpto "Basetable options" "basetable##options"}{...}
{viewerjumpto "Examples" "basetable##examples"}{...}
{viewerjumpto "Author and support" "basetable##author"}{...}


{title:Title}
{p2colset 5 10 22 2}{...}
{p2col :} Comparing a set of risk factors or effects with respect to a 
categorical variable - basetable{p_end}
{p2colreset}{...}


{title:Summary}
{p2colset 5 10 10 2}{...}
{p2col :}The command basetable is a simple yet highly efficient tool for 
interactively building the first table required in most medical/epidemiological 
papers.
{p_end}

{p2col :}The typical layout of these tables is a grouping (categorical) variable 
as column header and then a set of rows of different variables being compared by 
each group in the header and in a total.
{p_end}

{p2col :}When the interactive table building is over, the result can be inserted into 
one or more sheets in a excel workbook.{p_end}

{p2col :}If the labelling of variables and values have been done carefully the table 
outputs in the excel workbooks will be almost publication ready.{p_end}

{p2col :}The command basetable works from Stata 12 and onwards except for the option toxl. 
In Stata version 12 use the option style(csv) and the modifier using to 
specify a csv file to save the csv output in.{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}{cmd:basetable} {it:column_variable} 
	[{it:summary_variables}] [if] [in] [using]
	[{cmd:,} {it:{help basetable##options:options}}]
{p_end}

{synoptset 22 tabbed}{...}
{marker summary_variables}{...}
{synopthdr:Arguments}
{synoptline}
	{synopt :{opt column_variable}}The first argument must be a (categorical) 
    variable for subgrouping or the text "_none" for no column variable.{p_end}
	
    {synopt :{opt summary_variables}}The rest of the arguments are either 
    variable names or variable lists followed by with suboptions inside 
    parentheses or headers. 
    
	{p 34 36}* Headers (in square brackets) - 
    Headers are set by a text string in square brackets. 
    The syntax for the string inside the square brackets is:{break}
        {cmd:title_text [#] [, local_if]}{break}
    The different parts of the string are:{break}{break}
    - The title_text is a plain text string.{break}
    - The hashtag (#) is an option for adding a sub-count.{break}
    - The local_if is a Stata if expression.{break}
    - The sub-count from the hashtag matches the sub-condition.
    {p_end}
    
	{p 34 36}* Categorical variables are specified by their name followed by 
    an option string in brackets.
    Possible option strings are:{break}
	  - r or R (row percentages){break}
	  - c or C (column percentages){break} 
	  - or label value (Show only the row for this value).
      After a comma, a second argument can be added: r, R, c, C as above, or a ci
      for a Wald confidence interval.{p_end}
        {p 36 36}The p-value is by default from a chi-square test.
        Fisher's exact test can be chosen instead by option {opt e:xact}.{p_end}

    {p 34 36}* Continuous variables are specified by their name followed by 
    an option string in brackets.{break}
    An option string is a numeric format (eg %6.2f) and possibly, a local report 
    specification separated after a comma.{break}
    Types of report specifications are:{break}
        - sd (mean and sd, default),{break}
        - ci (mean and confidence interval),{break}
        - gci (geometric mean and confidence interval),{break}
        - pi (mean and prediction interval),{break}
        - iqr (median and interquartile range),{break}
        - iqi (median and interquartile interval),{break}
        - idr (median and interdecentile range),{break}
        - idi (median and interdecentile interval),{break}
        - imr (median and range), or{break}
        - imi (median, min, and max){p_end}
    {p 36 36}When the mean is reported the p-value is based on an ANOVA 
    test, and when the median is reported the p-value is based on a Kruskal 
    Wallis test.{p_end}
    {p 36 36}Centile calculation are similar to {help centile}, 
    not {help summarize}. {p_end}
{synoptline}
{p2colreset}{...}

{synoptset 24 tabbed}{...}
{marker options}{...}
{synopthdr:options}
{synoptline}
	{synopt :{opt l:og}}Show the underlying Stata output{p_end}
	{synopt :{opt n:thousands}}Add thousands separator to n values{p_end}
	{synopt :{opt pc:tformat}}Alter the format used for the percentages for the 
        categorical summary variables. The argument must be a numeric format{p_end}
	{synopt :{opt pv:format}}Alter the format used for the P value.
        The argument must be in a numeric format. There is sub-option {opt t:op} placing 
        the p-value at the top{p_end}
	{synopt:{opt e:xact}{opt (#)}}report Fisher's exact test instead of 
        chi-square tests. 
        The recommended value is 1 and 0 means no exact test.{break}
        If an error occurs, try with 5 and higher numbers. See {help tabulate:tabulate}.{p_end}
	{synopt :{opt c:ontinuousreport}}Specify overall default continuous report. 
        The values must be one of sd, iqr, iqi, idr, idi, imr, imi, ci, gci or pi{p_end}
	{synopt :{opt ca:tegoricalreport}}Specify overall default categorical report. 
        The values to set is n for count or p for percentages. 
        Default	is count (percentages).{p_end}
	{synopt :{opt notop:count}}Exclude the first row with count and percentages for 
    row columns{p_end}
	{synopt :{opt not:otal}}Exclude the Total column.{p_end}
	{synopt :{opt nop:value}}Exclude the P-value column.{p_end}
    {synopt :{opt col:umnorder}}Chose sets of column number (>1, <8) to show.{p_end}
	{synopt:{opt cap:tion(string)}}Caption for the output. Same as the {opt ti:tle} option.{p_end}
	{synopt:{opt ti:tle(string)}}Title for the output. Same as the {opt cap:tion} option.
        The {opt ti:tle} option overwrites the {opt cap:tion} option.{p_end}
	{synopt:{opt to:p(string)}}A string containing text prior to table content.
	Default is dependent of the value of the style option{p_end}
	{synopt:{opt u:ndertop(string)}}A string containing text between header and table 
        content. Default is dependent of the value of the style option{p_end}
	{synopt:{opt b:ottom(string)}}A string containing text after to table content.
	Default is dependent of the value of the style option{p_end}
	{synopt :{opt m:issing}}Show missing report to the right of the table{p_end}
	{synopt :{opt sm:all}}Specify the limit for being small wrt. hidesmall. Default is 5.{p_end}
	{synopt :{opt h:idesmall}}Hide data when count values are less than small (default 5).{break} 
		{red: Note that the number less than "small" sometimes can be deduced from surrounding values}{p_end}
	{synopt:{opt ps:eudo}}Option for using pseudo percentiles. 
		Pseudo percentiles are found by sorting the values and averaging a number of 
		values around each position. The averages are used to get percentiles.
		Option {opt sm:all} is used to set the average size
		{p_end}
	{synopt :{opt st:yle}}The output can be shown in the formats: smcl, 
		csv, html, latex or tex, or md. The default is smcl{p_end}
	{synopt :{opt r:eplace}}The styled output can be saved into a file specified by using.{break}
	If an existing file should be replaced in the process, replace should be set{p_end}
	
{synopthdr:version 13 and up}
{synopt:{opt toxl:(string)}}A string containing up to 5 values, separated 
	by a comma. The values are:{break}
	- path and filename on the excel book to save in. Excel book suffix is 
      set/reset to {cmd:xls} for Stata 13 and to {cmd:xlsx} for Stata 14 and above{break}
	- the sheet name to save output in{break}
	- (Optional) replace - replace/overwrite the content in the sheet{break}
	- (Optional) row, column numbers for the upper right corner of the table in 
      the sheet{break}
	- (Optional) columnn widths in parentheses. If more columns than widths the 
      last column width is used for the rest
	{p_end}
{synopt:{opt todocx:(string)}}A string containing one or two values separated 
	by a comma. The values are:{break}
	* path and filename on the excel book to save in.{break}
	* (Optional) replace - replace/overwrite the content in the sheet{break}
	{p_end}
{synoptline}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{phang}Retrieve a sample dataset (required for the rest of the clickable commands below):{p_end}
{phang}{stata quietly basetable_example_data}{p_end}

{phang}Continuous presentation:{p_end}
{phang}{stata basetable low age(%6.2f) age(%6.2f,sd) age(%6.2f, ci)}{p_end}

{phang}Categorical presentation:{p_end}
{phang}{stata basetable low race(c) race(r) race(white) race(white,r) race(white,ci)}{p_end}

{phang}Adding a missing report:{p_end}
{phang}{stata basetable low race(c) age(%6.2f), missing}{p_end}

{phang}Adding sub report on young (age < 20) mothers:{p_end}
{phang}{stata basetable low race(c) age(%6.2f) [Young mothers #, if age < 20] race(c) age(%6.2f), missing}{p_end}

{phang}Save table as tex/latex in file tbl1.tex at current directory:{p_end}
{phang}{stata basetable low race(c) age(%6.2f) using tbl1.tex, style(tex)}{p_end}
{phang}To see current directory:{p_end}
{phang}{stata cd}{p_end}
{phang}To see file content:{p_end}
{phang}{stata type tbl1.tex}{p_end}

{phang}Save tables for "all" and "young mothers" in sheets all and young_mothers in 
the Excel workbook tbls.xls(x) at current directory:{p_end}
{phang}{stata basetable low race(c) age(%6.2f), toxl(tbls, all)}{p_end}
{phang}{stata basetable low race(c) age(%6.2f) if age < 20, toxl(tbls, young_mothers)}{p_end}
{phang}To see current directory:{p_end}
{phang}{stata cd}{p_end}
{phang}To see the Excel workbook (stata 13):{p_end}
{phang}{stata shell tbls.xls}{p_end}
{phang}To see the Excel workbook (stata 14 and up):{p_end}
{phang}{stata shell tbls.xlsx}{p_end}

{phang}Save tables for "all" and "young mothers" in sheets all at row 6 and 
column 8:{p_end}
{phang}{stata basetable low race(c) age(%6.2f), toxl(tbls, all, replace,6,8)}{p_end}
{phang}To see the Excel workbook (stata 13):{p_end}
{phang}{stata shell tbls.xls}{p_end}
{phang}To see the Excel workbook (stata 14 and up):{p_end}
{phang}{stata shell tbls.xlsx}{p_end}

{phang}Save table for "all" the Word document tbl.docx at current directory:{p_end}
{phang}{stata basetable low race(c) age(%6.2f), todocx(tbl, all)}{p_end}
{phang}To see the Word document (One can not add several tables to the same Word file):{p_end}
{phang}{stata shell tbl.docx}{p_end}

{phang}Anonymize individuals by hiding small counts and pseudo percentiles:{p_end}
{phang}{stata basetable low age(%6.2f) ftv(c), hidesmall pseudo}{p_end}

{phang}Using group renaming to add prefix cat_ to all categorical variables:{p_end}
{phang}{stata rename (race ftv smoke) cat_=}{p_end}
{phang}Handling all renamed variables in the same way:{p_end}
{phang}{stata basetable low cat*(c), missing}{p_end}


{marker author}{...}
{title:Author and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
