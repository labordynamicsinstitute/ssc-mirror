{smcl}
{* *! tabbit 0.6.0  McAndrew 2025}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "putexcel" "help putexcel"}{...}
{title:Title}

{phang}
{bf:tabbit} {hline 2} weighted multiway crosstabulation tables to Excel

{pstd}
{cmd:tabbit} produces sets of weighted crosstabulation tables of one or more
outcome variables by one or more breakdown variables, and writes them to
an Excel workbook using {helpb putexcel}.  The tables report weighted
percentages, unweighted Ns, and a clearly marked missing row.  The
command is designed for large sets of outcome variables and multiple
breakdown variables, with options to control sheet layout, decimal places,
whether to display the overall % column and total row, and a statistical
disclosure control rule that suppresses breakdown categories whose unweighted
column count falls below a user-specified threshold.


{title:Syntax}

{p 8 16 2}
{cmd:tabbit}
{it:varlist}
{ifin}
{helpb using}
{it:filename}{cmd:,}
{bf:breakdown(}{it:varlist}{bf:)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt breakdown(varlist)}}one or more stratifier variables; one set of tables is produced for each{p_end}

{syntab:Main}
{synopt:{opt wtvar(varname)}}weight variable (default is equal weights){p_end}
{synopt:{opt sheet(str)}}name of Excel worksheet; see {helpb putexcel set}{p_end}
{synopt:{opt replace}}replace existing Excel file of same name{p_end}
{synopt:{opt bybreakdown}}write each breakdown variable to a separate worksheet{p_end}
{synopt:{opt mincoln(#)}}suppress columns with unweighted N < {it:#}{p_end}

{syntab:Display}
{synopt:{opt decimals(#)}}number of decimal places for percentages (default {cmd:1}){p_end}
{synopt:{opt nooverall}}suppress the "Overall % (valid)" column{p_end}
{synopt:{opt nototal}}suppress the "Total %" row in the % table{p_end}
{synopt:{opt rowpct}}show row percentages instead of column percentages{p_end}
{synopt:{opt noformat}}suppress bold/italic formatting and most number formats in Excel output{p_end}

{syntab:Missing}
{synopt:{opt missingasrow}}treat missing responses as an explicit row in the main % table{p_end}
{synopt:{opt nomissing}}suppress the Missing % line and omit the missing row in the N table{p_end}

{syntab:Export}
{synopt:{opt longdata(filename)}}(reserved) name of Stata dataset for long-format export; not yet implemented{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:varlist} gives the outcome variables.  Each is cross-tabulated by each
variable in {cmd:breakdown()} using the supplied weight if present.


{title:Description}

{pstd}Virtually all survey projects have delivery of frequencies and crossbreaks for the near-full set of survey measures as a central task. This requires production of large numbers of tables of outcome variables broken down 
by multiple demographic and other explanatory variables, with weighted percentages, 
unweighted counts, and transparent treatment of missing values.

{pstd}
Doing this manually is slow, error-prone, and leads to inconsistency, making such work a pain-point.
It is especially challenging when the same tables must be reproduced across different 
survey waves, countries, or client specifications. Researchers typically need to report
both the weighted results (for inference) and unweighted N (for data quality and disclosure control):
producing these side-by-side adds more manual work, and risks being forgotten.

{pstd}
{cmd:tabbit} automates this workflow. It generates a complete and consistent set
of weighted and unweighted tables, writes them directly to Excel, and applies 
optional disclosure control. This frees analysts from repetitive copy-and-paste
work, prevents accidental inconsistencies between tables, and accelerates the early 
stages of analysis.

{pstd}
{cmd:tabbit} does so as follows. For each outcome variable in {it:varlist} and each breakdown variable in {cmd:breakdown()}, {cmd:tabbit} 
creates a table of weighted percentages and a separate table of unweighted counts, and 
writes them to an Excel workbook via {helpb putexcel}.

{pstd}
By default, missing values on the outcome variable are excluded from the
valid % rows but are shown in a separate {it:Missing %} line, where the
denominator is the weighted sum of valid plus missing responses (within
each breakdown column). The unweighted N table includes missing responses
as a row labelled "Response missing". The {cmd:missingasrow} option moves
missing responses into an explicit row in the main % and N tables, and the
{cmd:nomissing} option suppresses both the Missing % line and the missing
row in the N table.

{pstd} 
{cmd:tabbit} provides options to control sheet layout, number of decimal places, whether 
to display the overall % column and total row, and a simple statistical disclosure 
control rule that suppresses breakdown categories whose unweighted column count is
below a user-specified threshold (mincoln()).

{pstd}
Finally, {cmd:tabbit} handles multiple Excel sheets automatically. For cross-national
surveys, analysts often deliver a workbook per country with a worksheet per breakdown,
eventually hosting thousands of tables. {cmd:tabbit} helps make this task more
efficient for those working without the resources of large-scale agencies.


{title:Options}

{dlgtab:Required}

{phang}
{opt breakdown(varlist)} specifies the breakdown (stratifier) variables.  One
set of tables is produced for each variable in {it:varlist}.

{dlgtab:Main}

{phang}
{opt wtvar(varname)} specifies the weight variable to use.  If {cmd:wtvar()}
is not supplied, equal weights are used.  The code uses weighted sums and
normalises to percentages within columns (or within rows if {cmd:rowpct} is
specified).

{phang}
{opt sheet(str)} specifies the Excel worksheet name.  If {cmd:bybreakdown} is
not used, all output is written to this sheet (default {it:Frequencies}).
With {cmd:bybreakdown} the sheet name is the breakdown variable name.

{phang}
{opt replace} allows {cmd:tabbit} to overwrite an existing Excel file.  This
corresponds to the {cmd:replace} option of {helpb putexcel set}.

{phang}
{opt bybreakdown} specifies that each breakdown variable is written to a
separate worksheet in the same workbook.  Sheet names are the breakdown
variable names (truncated to 31 characters if necessary).

{phang}
{opt mincoln(#)} specifies the minimum unweighted column N for a category of
the breakdown variable to be included in the table.  Categories with
unweighted N < {it:#} are dropped from the percentage table, the missing %
calculation, and the unweighted N table.  The default is {cmd:mincoln(0)},
in which case no columns are suppressed.

{dlgtab:Missing}

{phang}
{opt missingasrow} changes the treatment of missing responses on the outcome
variable.  By default, missing responses are excluded from the valid %
rows and are summarised in a separate "Missing %" line.  With
{cmd:missingasrow}, missing responses are included as a separate row
labelled "Response missing" in the main % table, and the separate Missing %
line is omitted.

{phang}
{opt missingasrow} changes the treatment of missing responses on the outcome
variable. By default, missing responses are excluded from the valid %
rows and summarised in a separate "Missing %" line. With
{cmd:missingasrow}, missing responses are included as a separate row
labelled "Response missing" in the main % table, and the separate Missing %
line is omitted.

{phang}
{opt nomissing} suppresses missing outcomes altogether from the summary
lines. With {cmd:nomissing}, the Missing % line is not produced, and the
unweighted N table does not include a "Response missing" row. This can be
useful when missingness is being handled or reported elsewhere.

{dlgtab:Display}

{phang}
{opt decimals(#)} specifies the number of decimal places for percentages in
the % table and Missing % line.  The default is {cmd:decimals(1)}.  Values
less than 0 are treated as 0; values greater than 6 are capped at 6.

{phang}
{opt nooverall} suppresses the "Overall % (valid)" column.  By default,
{cmd:tabbit} reports the percentage distribution over the valid response
categories for each breakdown column and also for all valid responses pooled
across columns.

{phang}
{opt nototal} suppresses the "Total %" row underneath the main % table.  By
default, the Total % row shows the sum of percentages over the response
categories within each column.

{phang}
{opt rowpct} requests row percentages rather than column percentages. With
column percentages (the default), each column sums to 100 over the valid
response categories. With {cmd:rowpct}, each row sums to 100 across the
columns. The optional overall column is labelled "Overall row % (valid,
all breakdowns)" and gives the distribution of responses pooled across
columns. In this mode, the "Total %" row is replaced by a row labelled
"Column share % (of total weighted base)", showing the share of the total
weighted base contributed by each column.

{phang}
{opt noformat} suppresses most formatting in the Excel output.  With
{cmd:noformat}, the command avoids bold and italic text and uses only
minimal numeric formatting.  This option can be useful when producing very
large workbooks where Excel may run into limits on the number of distinct
cell formats.

{dlgtab:Export}

{phang}
{opt longdata(filename)} is reserved for a future option to export a
long-format Stata dataset containing the cell percentages and counts.  In the
current version of {cmd:tabbit}, this option is accepted but ignored.


{title:Remarks}

{pstd}
{cmd:tabbit} is intended for survey analysis where analysts need to produce a
large number of breakdown tables with consistent formatting. Note that the command
relies on {helpb putexcel}, which is only available from Stata 15.0.

{pstd}
The command respects any {cmd:if} or {cmd:in} qualifiers supplied by the user.
These qualifiers determine the analysis sample.  Within that sample, missing
values on the outcome and breakdown variables are handled as described
above.  In particular, {cmd:tabbit} does not silently drop observations from
the sample simply because an outcome variable is missing; those cases are
either counted in the Missing % line or, with {cmd:missingasrow}, in a
separate row.

{pstd}
Weighted bases ("Weighted base W") are the sum of the weights over non-missing
outcome values within each breakdown column.  Weighted bases are displayed as whole numbers for ease
of interpretation, even when the underlying weights are non-integer. They
correspond to the sum of the weights over non-missing outcome values within
each breakdown column. Unweighted bases ("Unweighted base N") count the number of observations contributing to the valid response
categories in each column.  The unweighted N table below the % table shows
the distribution of counts across categories, including missing responses.



{title:Examples}

{pstd}
Single breakdown, default options:

{phang2}{bf:{cmd:. tabbit var1-var10 using "breakdowns.xlsx", breakdown(gender) wtvar(dweight) replace}}{p_end}

{pstd}
Multiple breakdowns, one sheet per breakdown, disclosure control:

{phang2}{bf:{cmd:. tabbit var1-var10 using "breakdowns.xlsx", breakdown(country gender agegrp) wtvar(dweight) bybreakdown mincoln(10) replace}}{p_end}

{pstd}
Row percentages, no overall column, 0 decimal places:

{phang2}{bf:{cmd:. tabbit var1-var10 using "breakdowns.xlsx", breakdown(sex) wtvar(dweight) rowpct nooverall decimals(0) replace}}{p_end}

{pstd}
Turn off most formatting when generating a very large workbook:

{phang2}{bf:{cmd:. tabbit var1-var500 using "breakdowns.xlsx", breakdown(country gender agegrp edulevel ethnicity) wtvar(dweight) bybreakdown noformat replace}}{p_end}


{title:Author}

{pstd}
Siobhan McAndrew{break}
Honorary Senior Lecturer, Sheffield Methods Institute{break}
Email: siobhan.mcandrew@gmail.com

{title:Citation}

{pstd}
If you use {cmd:tabbit} in published work, please cite:

{pstd}
McAndrew, S. (2025). tabbit: An automated Stata tool for producing weighted cross-tabulations.
Stata package.

{title:Acknowledgements}

{pstd}
{cmd:tabbit} grew out of an applied research project requiring the automatic
generation of several thousand crosstabulations. I am grateful to David Voas
for feedback and encouragement. All errors are my own.

(ptsd) End.