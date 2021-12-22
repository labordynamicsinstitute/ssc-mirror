{smcl}
{* *! version 1.0  5 May 2021}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "ttestex##syntax"}{...}
{viewerjumpto "Description" "ttestex##description"}{...}
{viewerjumpto "Remarks" "ttestex##remarks"}{...}
{viewerjumpto "Scalars" "ttestex##scalars"}{...}
{viewerjumpto "Examples" "ttestex##examples"}{...}
{viewerjumpto "Author" "ttestex##author"}{...}
{title:Title}
{phang}
{bf:ttestex} {hline 2} Performs two sample t-test using groups and exports the results to excel for multiple dependent and by multiple binary variables. 

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:ttestex}
namelist(min=1)
[{help if}]
{cmd:,}
rownum(integer) colnum(integer) crosscuts(string) per(integer)  [space(integer 0)]  [depvars2(string)] [samw(string)] [title(string)] [note(string)] 

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt rownum(#)}} The row number in which you want to start. If the title 
option is specified, the title will start in this row. If title is not specified, 
the label of the first variable in namelist will start in this row. The row number 
must be equal or greater 1.  {p_end}
{synopt:{opt colnum(#)}} The column in which you want to start. A corresponds to 1, B to 2, 
C to 3, and so on. Columns beyond Z are possible. The starting column is the column in which "Total",
the crosscute variable labels, and if specified the title and tablenotes appear. The column number 
must be equal or greater 1. {p_end}
{synopt:{opt crosscuts(string)}}  List of the group/binary-variables you want to perform the ttest by. 
Variables have to consist of two groups. Note that they need not to be coded as 0 and 1. However, they must be consecutive integers. 
At least one variable has to be specified. Do not place quotation marks around the variable names. {p_end}
{synopt:{opt per(#)}} Specify 100 if you want to obtain the means of the ttest in percent (%). Specify 1 otherwise. {p_end}
{syntab:Optional}
{synopt:{opt space(#)}}  Useful if multiple tables should be produced below one another. Adds however many lines are specified to 
the last p-value line. Default value is 0. {p_end}
{synopt:{opt depvars2(string)}}  Allows a second set of dependent variables, in addition to those specified in namelist.  
This is usful if you want to present only one set of outcomes in 100%. The depvars2 will be the opposite of what is specified in per.
Both orders, i.e. 100%, non-percent, or non-percent, 100% 
are possible. Insert a list of variables without quotation marks. {p_end}
{synopt:{opt samw(string)}}  Calculates the means with analytic weights. Insert the name of the variable you want to weigh by without quotation marks. 
Note that the p-values will remain unchanged. All other options (e.g. depvars2, if-condition, title, etc.) are possible with or without weights. 
samw() can may be placed anywhere after the comma.{p_end}
{synopt:{opt title(string)}}  Title of the table. Do not place quotation marks around the title. Titles are in {bf:bold} by default. {p_end}
{synopt:{opt note(string)}}  Notes below the table. Do not place quotation marks around the note. Notes are in {it:italics} by default. {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{cmd:ttestex} performs two sample t-tests on the equality of means using binary variables. This is useful to compare outcomes between e.g., males/females at one point in time. 
It assumes variances to be equal. It exports the means and the p-value of the t-test to excel, as well as the labels of the dependent variables and the value labels of the binary variables. 
Multiple dependent variables and binary variables can be specified, results are exported below and to the right of one another. 
{bf: At least one dependent (after ttestex) and one binary variable have to be specified.}


{marker remarks}{...}
{title:Remarks}

Before running the program for {bf:the first time}, please install the {help excelcol} program by running {help ssc install excelcol}. 
Before running the program, make sure that an excel file is specified. 
Recall to close the excel file using "putexcel clear" after exporting all desired tables and potential additions to the excel sheet. 
Further, it might be useful to drop the scalars using the "scalar drop _all" or "scalar drop nspace lspace" command.

{marker scalars}{...}
{title:Scalars}

The program produces two scalars which are useful if multiple tables are to be exported to the excel sheet.
	{bf:nspace}  Refers to the last p-value line in which something is written. This can be extended by using the space option. 
	{bf:lspace}  Refers to the last column in which something is written. 

{marker examples}{...}
{title:Examples}

sysuse nlsw88, clear // use some example data 
cd"/Users//`=c(username)'/Documents/_ttest" // set up a working directory 
putexcel set "ttest.xlsx", sheet("Example_ttestex") modify //set up an excel file 
*Note: Make sure that the variables and values have sensible labels*

* Basic example (1) 
ttestex age hours, rownum(1) colnum(1) crosscuts(married collgrad) per(1) 

/* A more complex example, title, notes, space, if option, and depvars2. 
We also use some locals here. These are not required for the program to run 
but might be useful if the command is used as part of a dofile exporting 
multiple results to excel. (2) 
*/
local row = 8
local letter = 1
ttestex age hours, rownum(`row') colnum(`letter') crosscuts(married collgrad) ///
  per(1) depvars2(union) space(4) title(Age and hours worked by variables of interest) note(Note: Full sample)
  
local row = nspace // this is useful as we want 
* Follow up example with a loop as an example for the if option. We also make use of the lspace scalar here. (3)
forvalues i=0/1 {
ttestex age hours if smsa==`i', rownum(`row') colnum(`letter') crosscuts(married collgrad) ///
  per(1) depvars2(union) space(4) title(Age and hours worked by variables of interest) note(Sample `:label (smsa) `i'')
local letter = lspace + 3
}
*
/*If sampling weight are required, simply add samw() somewhere after the comma. 
We repeat example (1) with weights.*/
ttestex age hours, rownum(1) colnum(7) crosscuts(married collgrad) per(1) samw(grade)

putexcel clear // close excel file
scalar drop nspace lspace // drop the scalars generated by the program 

{marker author}{...}
{title:Author: Annina Hittmeyer}
Quantitative Research Analyst 
Young Lives
Oxford Department of International Development
annina.hittmeyer@qeh.ox.ac.uk

The author is gratefully indebted to María de los Ángeles Molina, Richard Freund, Jennifer López, and Grace Chang for their invaluable feedback and helpful input. 



