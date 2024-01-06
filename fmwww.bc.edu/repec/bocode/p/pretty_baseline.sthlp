{smcl}
{* *! version 2.0 2 January 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "pretty_baseline##syntax"}{...}
{viewerjumpto "Description" "pretty_baseline##description"}{...}
{viewerjumpto "Options" "pretty_baseline##options"}{...}
{viewerjumpto "Remarks" "pretty_baseline##remarks"}{...}
{viewerjumpto "Examples" "pretty_baseline##examples"}{...}
{hline}
help for {cmd:pretty_baseline} {right: Version 2.0 13 December 2023}
{hline}
{title:Author}
{tab}Rafael Gafoor 
{tab}University College London, London UNITED KINGDOM 
{tab}{cmd:r.gafoor@ucl.ac.uk}

{tab} I acknowledge the invaluable assistance of Ian White (MRC CTU) who helped to debug and test the package

{tab}{bf:Version} 	     {bf:Date}    		  {bf:Comments}
{tab}1.0		26 January 2023		First release

{tab}2.0		2 January 2024		Includes options for formatting of categorical and continuous data
{tab}						Option for ordering of display
{tab}						Option to save the table and add a title
{tab}						Median and IQR option for skewed data

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:pretty_baseline}
[{help if}]
[{help in}]
[{help fweight}]
[{cmd:,}
{it:options}]


{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt by:}({help varname})} - grouping variable by which results are to be presented

{syntab:Optional}
{synopt:{opt contn:ormal}({help varname})} - continuous, normally distributed variables. Summary statistics of mean and standard deviation returned{p_end}
{synopt:{opt conts:kewed}({help varname})} - continuous, skewed variables. Summary statistics of median and interquartile range returned.{p_end}
{synopt:{opt categ:orical}({help varname})} - categorical variables. Summary statistics of frequency and percentages returned. {p_end}
{synopt:{opt fcont:}({help string})} - format for display of continuous variables{p_end}
{synopt:{opt fcateg:}({help string})} - format for display of categorical variables{p_end}
{synopt:{opt title:}({help string})} - title of table{p_end}
{synopt:{opt sav:ing}({help string})} - option to save and name baseline table{p_end}
{synopt:{opt pos:ition}({help string})} - option to change sequence of presentation of the variables of the table ("categ", "contn", "conts"){p_end}
{synopt:{opt replace:}} - specifies whether or not the file on disk is to be replaced with the version in memory if an identically named file already exists on disk{p_end}
{synoptline}


{p2colreset}{...}
{p 4 6 2}

{title:Description}

{phang}{marker description}{cmd:pretty_baseline} generates a table of baseline characteristics of publication quality.{p_end}

{pstd}
{opt pretty_baseline} generates grouped results by any categorical variable with greater than or equal to 2 groups.
If there is missingness in the grouping variable, a column with missing values will be produced. There are 4 types of data which
are accommodated. Normally distributed continuous variables, continuous variables with a skewed distribution, categorical variables.
For continuous variables the mean and standard deviation or the median and inter quartile range (IQR) will be produced respectively
for normally distributed or for skewed data. The default number of decimal places for all statistics for continuous data are two 
decimal places after the decimal point. For categorical data, the counts and percentages are shown. The percentage output 
has a default of 1 decimal place. The decimal place options can be changed for either categorical or continuous data using the {it:fcateg} 
or {it:fcont} options. Guidance can be found in Stata help files for the formatting options [{help format}].

{pstd}
The default sequence of vertical presentation of the categoriesof variables is output in:"normally distributed continuous", "skewed continuous" and "categorical".
This default can be changed with the option {it:position}. The input accepts a sequence of strings "contn", "conts" and "categ".

{pstd}
The default table is saved as an .docx document, however can be invoked as the table is retained in memory. To recall the
table the command {cmd:collect layout} can be issued to the console. The default location for the resultant file is the working directory
although another file location can be specified.

{pstd}
The default variable labels for the table are the value labels from the dataset. Where value labels are not specified, variable names will be presented.


{marker examples}{...}

{title:Examples}
{marker examples}{...}

{phang} {cmd:. webuse nhanes2l, clear}{p_end}
{tab}Second National Health and Nutrition Examination Survey

{tab} {bf: Basic Table}
{phang} {cmd:. pretty_baseline, by(sex) contn(age) conts(height weight) categ(race)}

{tab} {bf:Table with formatting of output}
{phang} {cmd:. pretty_baseline, by(sex) contn(age) conts(height weight) categ(race) fcont(%9.3fc) fcateg(%9.1fc)}

{tab} {bf:Table with formatted output, title, saving word document, and changing order of output}
{phang} {cmd:. pretty_baseline, by(sex) contn(age) conts(height weight) categ(race) fcont(%9.3fc) fcateg(%9.1fc)} /// {p_end}
{tab}{cmd: title(Table 1: Table of Baseline Characteristics) saving(Table_1) position("conts" "contn" "categ")}











