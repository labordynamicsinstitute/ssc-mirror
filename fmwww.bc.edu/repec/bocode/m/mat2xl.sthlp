{smcl}
{* *! version 0.31}{...}
{viewerjumpto "Syntax" "mat2xl##syntax"}{...}
{viewerjumpto "Description" "mat2xl##description"}{...}
{viewerjumpto "Examples" "mat2xl##examples"}{...}
{viewerjumpto "Author and support" "mat2xl##author"}{...}
{title:Title}
{phang}
{bf:mat2xl} {hline 2} convert a matrix expression into a string formatted Mata matrix
and inserts the string matrix into a sheet in an Excelbook

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:mat2xl}
matrixexpression
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt toxl:(string)}}A string containing up to 5 values separated 
	by a comma. The values are:{break}
	* path and filename on the excel book to save in. Excel book suffix is set/reset to {cmd:xls} for Stata 13 and to {cmd:xlsx} for Stata 14 and above{break}
	* the sheet name to save output in{break}
	* (Optional) replace - replace/overwrite the content in the sheet{break}
	* (Optional) row, column numbers for the upper right corner of the table in the sheet{break}
	* (Optional) columnn widths in parentheses. If more columns than widths the last column width is used for the rest
	{p_end}
{syntab:Optional}
{synopt:{opt r:ownamewidth(#)}} Set width for row equation and row name columns. 
Default value is 25{p_end}
{synopt:{opt c:ellwidth(#)}} Set width for cell columns. 
Default value is 15{p_end}
{synopt:{opt d:ecimals(string)}} Matrix of integers specifying numbers of 
decimals at cell level. 
If the matrix is smaller than the data matrix the right most column is copied 
to get the same number of columns. 
And likewise for the rows
{p_end}
{synopt:{opt h:idesmall(#)}} If set hide all values below the set value. 
Default is the value 0, ie no hidding{p_end}
{synopt:{opt n:oisily}} For debugging. Show selected values {p_end}
{synopt:{opt n:oCleanmata}} For debugging. Do not delete Mata values and instances{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{bf:mat2xl} convert a matrix expression into a string formatted Mata matrix
and inserts the string matrix into a sheet in an Excelbook.
Works for Stata version 13 and up.
{p_end}


{marker examples}{...}
{title:Examples}

{phang}Generate example matrix by {help sumat:sumat}:{p_end}
{phang}{stata `"sysuse auto, clear"'}{p_end}
{phang}{stata `"sumat price , stat(mean ci) rowby(rep78) colby(foreign)"'}{p_end}

{phang}Insert the returned matrix r(sumat) starting in 
cell (A1, row = 1 column = 1) at the "tbl1" sheet in Excel book "deleteme.xls(x)".{p_end}
{phang}No matter what suffix that is suggested in the command, the suffix naming 
convention is xls for Stata version 13 and xlsx for Stata version 14 and up.{p_end}
{phang}{stata `"mat2xl r(sumat), toxl(deleteme, tbl1)"'}{p_end}

{phang}Insert the returned matrix r(sumat) starting in 
cell (A20, row = 20 column = 1) at the "tbl1" sheet in Excel book "deleteme.xls(x)".{p_end}
{phang}{stata `"mat2xl r(sumat), toxl(deleteme, tbl1, 20, 1)"'}{p_end}

{phang}Insert the returned matrix r(sumat) starting in 
cell (C2, row = 2 column = 3) at the "tbl2" sheet in Excel book "deleteme.xls(x)".{p_end}
{phang}The sheet is replaced so old values are deleted.{p_end}
{phang}First column width is set to 30. The rest is set to 15.{p_end}
{phang}Values are shown with 3 decimals{p_end}
{phang}{stata `"mat2xl r(sumat), toxl(deleteme.xlsx, tbl2, replace, 2,3  ,  (30,15)) decimals(3)"'}{p_end}

{phang}If MS Excel is installed see the result:{p_end}
{phang}Stata 13: {stata `"shell "deleteme.xls""'}{p_end}
{phang}Stata 14 and up: {stata `"shell "deleteme.xlsx""'}{p_end}


{marker author}{...}
{title:Author and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
