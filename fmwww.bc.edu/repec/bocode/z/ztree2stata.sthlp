{smcl}
{* *! version 8.0  15Oct2023}{...}
{hline}
help for {hi:ztree2stata}{right:Author:  Kan Takeuchi (Ver. Oct 15, 2023)}
{hline}
{viewerdialog ztree2stata "dialog ztree2stata"}{...}
{viewerjumpto "Syntax" "ztree2stata##syntax"}{...}
{viewerjumpto "Description" "ztree2stata##description"}{...}
{viewerjumpto "Options" "ztree2stata##options"}{...}
{viewerjumpto "Remarks" "ztree2stata##remarks"}{...}
{viewerjumpto "Quick Start" "ztree2stata##quickstart"}{...}
{viewerjumpto "Examples" "ztree2stata##examples"}{...}
{viewerjumpto "Technical Notes" "ztree2stata##technicalnotes"}{...}

{p2colset 1 18 20 2}{...}
{p2col:{bf:ztree2stata} {hline 2}}Import data created by z-Tree{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmdab:ztree2stata} 
{it:{help ztree2stata##table:table}}
{cmd:using} 
{it:{help filename}} 
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt clear}}replace data in memory{p_end}
{synopt :{opt sa:ve}}save the data in memory{p_end}
{synopt :{opt replace}}overwrite existing dataset{p_end}
{synopt :{cmdab:tr:eatment(}{it:{help numlist}})}specify treatments to import{p_end}
{synopt :{cmdab:exc:ept(}{it:{help strings}})}specify strings that will be used to skip the automated renaming{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:ztree2stata} imports a z-Tree (Fischbacher, 2007) data file and converts it into Stata format.  
Specifically ztree2stata opens an ASCII text file saved by z-Tree, keeps the data of the specified table, 
renames variables using the variable names in z-Tree, and 
converts the data into numerical type if possible.  

{marker options}{...}
{title:Options}

{dlgtab:Main}
{phang}
{cmd:clear} permits the data to be loaded even if there is a dataset already in 
memory and even if that dataset has changed since the data were last saved. 

{phang}
{cmd:save} allows Stata to save the data in memory as filename-table.dta.

{phang}
{cmd:replace} permits {cmd:save} to overwrite an existing dataset. 

{phang}
{cmd:treatment(}{it:{help numlist})} specifies treatments that will be imported into memory. 
If this option is omitted, then all treatments will be imported. 

{phang}
{cmd:except(}{it:{help strings}}) specifies strings that will be used to skip the automated renaming. 
If there is any trouble with variable names, then the except option may solve it. See the example below for more details. 

{marker remarks}{...}
{title:Remarks}

{pstd}
z-Tree records the various data during the experiment in multiple tabular formats, and after the experiment is completed, 
these tables are combined and output as a single tab-delimited ASCII file with xls extension. 
Several issues arise when Stata imports the file, including: (1) The file includes several tables (e.g., subjects, globals, and clients) that must be separated for analysis; (2) Because the file includes variable names as strings, all numeric data is also interpreted as strings; and (3) When z-Tree data includes several treatments, the width of the selected table varies with treatments, resulting in variables being recorded in different columns. {cmd:ztree2stata} can handle these issues and conveniently convert the z-Tree data file into Stata?fs dta format. {p_end}

{marker quickstart}{...}
{title:Quick Start}

{pstd}
Import the subjects table of {cmd:040517_1230.xls}{p_end}
{phang2}{cmd:. ztree2stata subjects using 040517_1230.xls}{p_end}

{pstd}
Import the globals table of {cmd:040517_1230.xls} after clear the data in the memory{p_end}
{phang2}{cmd:. ztree2stata globals using 040517_1230.xls, clear}{p_end}

{pstd}
Import the data of from the 2nd and the 4th treatments and save the data in dta format{p_end}
{phang2}{cmd:. ztree2stata subjects using 040517_1230.xls, treatment(2 4) save}{p_end}

{pstd}
Import the subjects table of {cmd:040517_1230.xls} and {cmd:221211_1749.xls} and combine them{p_end}
{phang2}{cmd:. ztree2stata subjects using 040517_1230.xls, save}{p_end}
{phang2}{cmd:. ztree2stata subjects using 221213_1749.xls, clear save}{p_end}
{phang2}{cmd:. use 040517_1230-subjects, clear}{p_end}
{phang2}{cmd:. append using 221213_1749-subjects}{p_end}

{marker examples}{...}
{title:Examples}
{pstd}
{cmd:. ztree2stata subjects using 040517XY.xls}{p_end}
{phang2}
Stata reads {cmd:040517XY.xls} and keeps the data of the subjects table.{p_end}

{phang2}
{it:table} = {cmd:subjects}; Specify one of the tables which have been defined in z-Tree. {p_end}
{phang2}
{it:filename} = {cmd:040517XY.xls}; Stata looks for {cmd:040517XY.xls} in the current directory. It must be in the current directory.  {p_end}


{pstd}
{cmd:. ztree2stata globals using 040517XY.xls, tr(2 4) save}{p_end}
{phang2}
Stata opens {cmd:040517XY.xls}, keeps the data of the globals table in treatment 2 and 4, and save the data. {p_end}
 
{phang2}
{it:options} = {cmd:tr(2 4)}; Stata reads the data of treatment 2 and 4. If the data does not include some of the specified treatments, then it returns an error.  {p_end}
{phang2}
{it:options} = {cmd:save}; This option allows Stata to save the data in memory as {cmd:040517XY-globals.dta}. To overwrite the existing file, use {cmd:save} with {cmd:replace} option.  {p_end}

{pstd}
{cmd:. ztree2stata subjects using 050301AB.xls, except(foo goo) }{p_end}
{phang2}
{it:options} = {cmd:except(foo goo)}; Some issues, particularly those related to variable names, can be resolved using the 'except' option. In this example, {cmd:ztree2stata} adjusts variables containing 'foo' and/or 'goo' to foo# or goo#, where # signifies their original column position. For example, variables 'food,' 'good?' and 'goodfood!' in columns 6, 7, and 10 are renamed as 'foo6', 'goo7', and 'goo10', respectively. When a variable name includes both 'foo' and 'goo', the latter in the 'except' option determines the new name, turning 'goodfood' into 'goo10'. {p_end}

{marker technicalnotes}{...}
{title:Technical Notes}

{pstd}
ztree2stata cannot open Excel files. A data file created by z-Tree is not an Excel file but a tab-delimited 
ASCII file, while its extension is xls. Therefore, once a data file is overwritten as an Excel file, 
{cmd: ztree2stata} can no longer open it.

{pstd}
The following symbols will be deleted from the variable names:
exclamation marks (!), colons (:), semi-colons (;), equal signs (=), double quotation marks ("), and spaces ( ). 
If this leads to issues or errors due to duplicate variable names, use the {cmd: except} option.

{pstd}
The except option can be used to eliminate any other symbols or letters from variable names.

{pstd}
Note that when there is an unpaired double quotation mark in a dataset, Stata's import results may not be as intended. 

{pstd}
{it:options} = {cmd:string} is no longer required in the current version. 

{pstd}
This command is provided as it is, without any warranty.

{pstd}
Python users can utilize ztree2python (Takeuchi, 2022), to read z-Tree data files in Pandas format.

{p2colreset}{...}{marker references}{...}
{title:References}

{phang}
Fischbacher, U. 2007.
{browse "https://link.springer.com/article/10.1007/s10683-006-9159-4":z-Tree: Zurich Toolbox for Ready-made Economic Experiments}. {it:Experimental Economics} 10: 171-178.

{phang}
Takeuchi, K. 2022.
ztree2python.py, {browse "http://github.com/takekan/ztree2python"}.

{phang}
Takeuchi, K. 2023.
{browse "https://rdcu.be/daUxq":ztree2stata: A data converter for z-Tree and Stata users}. {it:Journal of the Economic Science Association} 9: 136-146.
{p_end}
