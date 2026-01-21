{smcl}
{* *! version 0.32 2024-12-17}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "matslct##syntax"}{...}
{viewerjumpto "Description" "matslct##description"}{...}
{viewerjumpto "Options" "matslct##options"}{...}
{viewerjumpto "Examples" "matslct##examples"}{...}
{viewerjumpto "Author and support" "matslct##author"}{...}
{title:Title}
{phang}
{bf:matslct} {hline 2} Subselecting from Stata matrices using mata notation

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:matslct}
matrix_expression
[{cmd:,}
{it:options}]

{p 8 17 2}
{cmdab:matslct}
matrix_expression[{opt r:owselect};{opt c:olumnselect}]
[{cmd:,}
{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Optional}
{synopt:{opt n:ame(string)}} If specified, the returned matrix is saved in 
a matrix with that name

{synopt:{opt r:owselect(string)}}  Specify row numbers and their order.

{synopt:{opt c:olumnselect(string)}}  Specify column numbers and their order.

{synopt:{opt t:ranspose}}  Transpose the subselection matrix.

{synoptline}
{syntab:Matprint options}
{synopt:{opt s:tyle(string)}}Style for output. One of the values {bf:smcl} (default), 
{bf:csv} (semicolon separated style), 
{bf:latex or tex} (latex style),
{bf:html} (html style) and
{bf:md} (markdown style, experimental) 
{p_end}
{synopt:{opt d:ecimals(string)}}Matrix of integers specifying numbers of 
decimals at cell level. If the matrix is smaller than the data matrix the right
most column is copied to get the same number of columns. 
And likewise for the bottom row{p_end}
{synopt:{opt ti:tle(string)}}Title/caption for the matrix output{p_end}
{synopt:{opt to:p(string)}}String containing text prior to table content.
Default is dependent of the value of the style option{p_end}
{synopt:{opt u:ndertop(string)}} String containing text between header and table 
content.
Default is dependent of the value of the style option{p_end}
{synopt:{opt b:ottom(string)}}String containing text after to table content.
Default is dependent of the value of the style option{p_end}
{synopt:{opt r:eplace}}Delete an existing {help using:using} file before adding table{p_end}
{synopt:{opt noe:qstrip}}Do not remove duplicate successive roweq or coleq values{p_end}
{synopt:{opt noz:ero}}Do not show zeros in output{p_end}
{synopthdr:version 13 and up}
{synopt:{opt toxl:(string)}}A string containing up to 5 values separated 
	by a comma. The values are:{break}
	* path and filename on the excel book to save in. Excel book suffix is set/reset to {cmd:xls} for Stata 13 and to {cmd:xlsx} for Stata 14 and above{break}
	* the sheet name to save output in{break}
	* (Optional) replace - replace/overwrite the content in the sheet{break}
	* (Optional) row, column numbers for the upper right corner of the table in the sheet{break}
	* (Optional) columnn widths in parentheses. If more columns than widths the last column width is used for the rest
	{p_end}
{synopt:{opt todocx:(string)}}A string containing one or two values separated 
	by a comma. The values are:{break}
	* path and filename on the excel book to save in.{break}
	* (Optional) replace - replace/overwrite the content in the sheet{break}
	{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}The {cmdab:matslct} select a sub matrix from a matrix expression using 
the Mata row and column notation for selection and ordering.
The only difference is that selected rows and selected columns are separated by 
semicolon (;) instead of a comma(,).

{pstd}It is tested in Stata 12.1.

{marker examples}{...}
{title:Examples}

{pstd}Subselect estimates, confidence intevals and p-value for variables 
headroom and length after regression using {opt r:owselect} and {opt c:olumnselect}.{p_end}
{phang}{stata `"sysuse auto ,clear"'}{p_end}
{phang}{stata `"regress price displacement gear_ratio headroom length mpg"'}{p_end}
{phang}{stata `"matslct r(table), columnselect(3..4) rowselect(1,5,6,4) transpose"'}{p_end}

{pstd}Subselect estimates, confidence intevals and p-value for variables 
headroom and length after regression using using the 
[{opt r:owselect};{opt c:olumnselect}] notation.{p_end}
{phang}{stata `"sysuse auto ,clear"'}{p_end}
{phang}{stata `"regress price displacement gear_ratio headroom length mpg"'}{p_end}
{phang}{stata `"matslct r(table)[1,5,6,4; 3..4], transpose"'}{p_end}


{title:Stored results}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Matrices}{p_end}
{synopt:{cmd:r(matslct)}}  The subselection of the matrix.{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}



