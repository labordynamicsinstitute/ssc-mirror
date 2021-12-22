{smcl}
{* *! version 1.0  6 May 2021}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "ttestex_time##syntax"}{...}
{viewerjumpto "Description" "ttestex_time##description"}{...}
{viewerjumpto "Remarks" "ttestex_time##remarks"}{...}
{viewerjumpto "Scalars" "ttestex_time##scalars"}{...}
{viewerjumpto "Examples" "ttestex_time##examples"}{...}
{viewerjumpto "Author" "ttestex_time##author"}{...}
{title:Title}
{phang}
{bf:ttestex_time} {hline 2} Performs paired t-tests using variables and exports the results to excel for multiple dependent variables and sub-samples. 

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:ttestex_time}
namelist(min=1)
[{help if}]
{cmd:,}
rownum(integer) colnum(integer) [crosscuts(string)] per(integer) time1(string) time2(string) [space(integer 0)] [depvars2(string)] [samw(string)] [title(string)] [note(string)]

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
{synopt:{opt per(#)}} Specify 100 if you want to obtain the means of the ttest in percent (%). Specify 1 otherwise. {p_end}
{synopt:{opt time1(#/string)}} The identifier of the first time period/point of comparison. {p_end}
{synopt:{opt time2(#/string)}} The identifier of the second time period/point of comparison. {p_end}
{syntab:Optional}
{synopt:{opt crosscuts(string)}}  List of the binary/categorical variables for whose subgroups you want to limit the sample to for the t-test. 
Variables have to consist of at least two groups, which in turn must be consecutive integers. 
Do not place quotation marks around the variable names. {p_end}
{synopt:{opt space(#)}}  Useful if multiple tables should be produced below one another. Adds however many lines are specified to 
the last line. Default value is 0. {p_end}
{synopt:{opt depvars2(string)}}  Allows a second set of dependent variables, in addition to those specified in namelist.  
This is usful if you want to present only one set of outcomes in 100%. The depvars2 will be the opposite of what is specified in per.
Both orders, i.e. 100%, non-percent, or non-percent, 100% 
are possible. Insert a list of variables without quotation marks. {p_end}
{synopt:{opt samw(string)}}  Calculates the means with analytic weights. Insert the name of the variable you want to weigh by without quotation marks. 
Note that the calculation of the means is based on only those observations which have non-missing values for both variables being compared. 
Note further that the p-values will remain unchanged. All other options (e.g. depvars2, if-condition, title, etc.) are possible with or without weights. 
samw() can may be placed anywhere after the comma.{p_end}
{synopt:{opt title(string)}}  Title of the table. Do not place quotation marks around the title. Titles are in {bf:bold} by default. {p_end}
{synopt:{opt note(string)}}  Notes below the table. Do not place quotation marks around the note. Notes are in {it:italics} by default. {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}

{cmd:ttestex_time} performs a paired t-test using variables. It assumes variances to be equal. This command is useful if you wish to compare outcomes for the same individuals/observations. 
The t-tests can be performed among the total sample only but adding results for sub-samples is also possible by including binary/categorical variables (crosscuts) as an option. 
It exports the means and the p-value of the t-test to excel, as well as the labels of the dependent variables and the value labels of the binary/categorical variables. 
Multiple dependent variables and binary/categorical variables can be specified, results are exported below and to the right of one another. At least one dependent variable has to be specified after ttestex_time. 
{bf: Note that the variables you wish to compare have to have the same name, up to the ending specified in time1 & time2.}

{marker remarks}{...}
{title:Remarks}

Before running the program for {bf:the first time}, please install the {help excelcol} program by running {help ssc install excelcol}. 
Before running the program, make sure that an excel file is specified. 
Recall to close the excel file using "putexcel clear" after exporting all desired tables and potential additions to the excel sheet. 
Further, it might be useful to drop the scalars using the "scalar drop _all" or "scalar drop nspace lspace" command.

{marker scalars}{...}
{title:Scalars}

The program produces two scalars which are useful if multiple tables are to be exported to the excel sheet.
	{bf:nspace}  Refers to the last line in which something is written. This can be extended by using the space option. 
	{bf:lspace}  Refers to the last column in which something is written. 
	
{marker examples}{...}
{title:Examples}

webuse nlswork, clear // use some example data 
******Create a dataset in the wide format****
forvalues i=85(3)88 {
preserve 
keep if year==`i'
drop year 
foreach var in age msp nev_mar grade collgrad not_smsa c_city south ind_code ///
occ_code union wks_ue ttl_exp tenure hours wks_work ln_wage {
rename `var' `var'_`i'
local a : variable label `var' 
label var `var'_`i' "`a' in 19`i'"
}
tempfile `i'
save ``i''
restore
}
use `85', clear
merge 1:1 idcode using `88'
drop if _merge!=3
drop _merge
*Note: Make sure that the variables and values have sensible labels (not part of the program)
label define south 0 "did not live in the south" 1 "lived in the south" 
label values south_85 south
label define college 0 "Collage graduate in 1985" 1 "Had not graduated from college in 1985" 
label values collgrad_85 college 
cd"/Users//`=c(username)'/Documents/_ttest" // set up a working directory 
putexcel set "ttest.xlsx", sheet("Example_ttestex_time") modify //set up an excel file

***A basic example with just the totals (1)
ttestex_time hours ln_wage, rownum(1) colnum(1) time1(_85) time2(_88) per(1) 

***A basic example with a binary variable to split the sample by (2)
ttestex_time union, rownum(4) colnum(1) time1(_85) time2(_88) per(100) crosscuts(race collgrad_85)

* A more complex example, title, notes, space, if option, and depvars2. (3)
* We also use some locals here. These are not part of the program but might be useful. 

local row = 13 
local letter = 1
ttestex_time hours ln_wage, rownum(`row') colnum(`letter') time1(_85) time2(_88) ///
per(1) space(4) depvars2(union) crosscuts(race collgrad_85) title(Hours worked and ln wage in 1985 and 1988) ///
note(Full sample)

local row = nspace // this is useful as we want to continue 
* Follow up example with a loop as an example for the if option. We also make use of the lspace scalar here. (4)

forvalues i=0/1 {
ttestex_time hours ln_wage if south_85==`i', rownum(`row') colnum(`letter') time1(_85) time2(_88) ///
per(1) depvars2(union) crosscuts(race collgrad_85) title(Hours worked and ln wage in 1985 and 1988 of those who `:label (south_85) `i'') ///
note(Living in the south refers to the respondent's location in 1985)
local letter = lspace + 3
}
*
/*If sampling weight are required, simply add samw() somewhere after the comma. 
We repeat example (2) with weights.*/
ttestex_time union, rownum(4) colnum(6) time1(_85) time2(_88) per(100) crosscuts(race collgrad_85) samw(birth_yr)


putexcel clear // close excel file
scalar drop nspace lspace // drop the scalars generated by the program 


{marker author}{...}
{title:Author: Annina Hittmeyer}
Quantitative Research Analyst 
Young Lives
Oxford Department of International Development
annina.hittmeyer@qeh.ox.ac.uk

The author is gratefully indebted to María de los Ángeles Molina, Richard Freund, Jennifer López, and Grace Chang for their invaluable feedback. 





