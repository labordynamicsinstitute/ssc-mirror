{smcl}
{* *! version 1.2.2  15may2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:Title}

{phang}
{bf:submatrix} {hline 2} Advanced Stata matrix subsetting, sorting and deleting.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd: submatrix}
{it: A}
[{cmd:,} {it:options}]

{it: A} is an existing Stata matrix

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:*{opt rownum(numlist)}} contains the numbers of the rows to be retained from {it: A} {p_end}
{synopt:*{opt droprownum(numlist)}} contains the numbers of the rows to be dropped from {it: A} {p_end}
{synopt:*{opt colnum(numlist)}} contains the numbers of the column to be retained from {it: A} {p_end}
{synopt:*{opt dropcolnum(numlist)}} contains the numbers of the column to be dropped from {it: A} {p_end}
{synopt:*{opt rownames(string)}} contains the names of the rows to be retained from {it: A} {p_end}
{synopt:*{opt droprownames(string)}} contains the names of the rows to be dropped from {it: A} {p_end}
{synopt:*{opt colnames(string)}} contains the names of the column to be retained from {it: A} {p_end}
{synopt:*{opt dropcolnames(string)}} contains the names of the column to be dropped {p_end}
{synopt:{opt rowv:arlist}} specifies that arguments in {opt droprownames} and {opt rownames} are variables {p_end}
{synopt:{opt colv:arlist}} specifies that arguments in {opt dropcolnames} and {opt colnames} are variables {p_end}
{synopt:{opt nam:esfirst}} return rows and columns based on their names first. {p_end}
{synopt:{opt ign:ore}} ignore non existing row and columns names and numbers from the subsetting options (*) . {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* subsetting options, duplicated arguments are allowed. {p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:submatrix} returns subset of a Stata matrix based on row and columns names, numbers and equations. 
Users can specify which row and/or column to keep or to drop. 


{marker options}{...}
{title:Options}

{dlgtab:Main}



{phang}
{opt rownames(string)} controls the names of the rows to be retained from matrix {it: A}.
If {it: string} does not match any element of {it: A}
returns an error unless {opt ignore} is specified (see {it: {help matrix_subscripting}}). 
Double quotes may be used to enclose strings that contain spaces. 

{phang}
{opt droprownames(string)} controls the names of the rows to be dropped from matrix {it: A}.
If {it: string} does not match any element of {it: A}
returns an error unless {opt ignore} is specified (see {it: {help matrix_subscripting}}).
Double quotes may be used to enclose strings that contain spaces. 

{phang}
{opt colnames(string)} controls the names of the columns to be retained from matrix {it: A}.
If {it: string} does not match any element of {it: A}
returns an error unless {opt ignore} is specified (see {it: {help matrix_subscripting}}).
Double quotes may be used to enclose strings that contain spaces. 

{phang}
{opt dropcolnames(string)} controls the names of the columns to be dropped from matrix {it: A}.
If {it: string} does not match any element of {it: A}
returns an error unless {opt ignore} is specified (see {it: {help matrix_subscripting}}).
Double quotes may be used to enclose strings that contain spaces. 

{phang}
{opt rownum(numlist)} controls the numbers of the rows to be retained from matrix {it: A}. 
Exits with an error if any element of {it: numlist} is larger than the row number
 of A unless {opt ignore} is specified  (see {it: {help matrix_subscripting}}).

{phang}
{opt droprownum(numlist)} controls the numbers of the rows to be dropped from matrix {it: A}.
Exits with an error if any element of {it: numlist} is larger than the  
row number of A unless {opt ignore} is specified  (see {it: {help matrix_subscripting}}).

{phang}
{opt colnum(numlist)} controls the numbers of the columns to be retained from matrix {it: A}.
Exits with an error if any element of {it: numlist} is larger than the column 
number of A unless {opt ignore} is specified  (see {it: {help matrix_subscripting}}).

{phang}
{opt dropcolnum(numlist)} controls the numbers of the columns to be dopped from matrix {it: A}.
Exits with an error if any element of {it: numlist} is larger than the column 
number of A unless {opt ignore} is specified  (see {it: {help matrix_subscripting}}).

{phang}
{opt colvarlist} requests {cmd: submatrix} to treat the names in {opt rownames} 
and {opt droprownames} as a {it:{help varlist}}. This option enables factor variable 
expansion and the use of the * character for matching 
one or more characters. 

{phang}
{opt rowvarlist} requests {cmd: submatrix} to treat the names in {opt colnames} 
and {opt dropcolnames} as a {it:{help varlist}}. This option enables factor variable 
expansion and the use of the * character for matching 
one or more characters. 

{phang} 
{opt namesfirst} prioritizes subsetting based on {cmd: rownames} and {cmd: colnames} rather than 
using {cmd: rownames} and {cmd: colnames} first.

{phang}
{opt ignore} requests {cmd: submatrix} to ignore any out of range element from {it: A}. 
It affects {opt rownames}, {opt droprownames}, {opt colnames}, {opt dropcolnames},{opt rownum},
{opt droprownum}, {opt colnum} and {opt dropcolnum}. Using this option forces 
{cmd: submatrix} to return a result anyway.

{marker examples}{...}

{title:Example 1}

{pstd} Initializing matrix A {p_end}
{phang} {cmd:. matrix A=(1,3,4,6,7,8,10 \ 1,3,4,6,7,8,10)} {p_end}

{pstd} Retaining columns 1, 5 and 7 (results in {cmd: r(mat)}) {p_end}
{phang} {cmd:. submatrix A, colnum(1 5 7)} {p_end}
{phang} {cmd:. matlist r(mat) } {p_end}

{pstd} Same as above, using column names instead of numbers {p_end}
{phang} {cmd:. submatrix A, colnames(c1 c5 c7)} {p_end}
{phang} {cmd:. matlist r(mat) } {p_end}

{pstd} Dropping columns 2,3,4 and 6, using {cmd: dropcolnum} {p_end}
{phang}{cmd:. submatrix A, dropcolnum(2(1)4 6 ) } {p_end}
{phang} {cmd:. matlist r(mat) } {p_end}

{title:Example 2}

{pstd} Loading data {p_end}
{phang}{cmd:. webuse nlswork, clear}{p_end}
{pstd}A regression with a large number of coefficients and interactions{p_end}
{phang}{cmd:. xtreg ln_wage grade age c.age#c.age ttl_exp c.ttl_exp#c.ttl_exp tenure c.tenure#c.tenure 2.race not_smsa south i.year##(i.msp i.ind_code), be}{p_end}

{pstd} Saving the result matrix {p_end}
{phang}{cmd:. matrix results=r(table)}{p_end}

{pstd} Subsetting results using row and column names (note the use of {cmd: colvarlist} of factor variable notation to select all the interactions of {cmd: .1.msp} with {cmd: .year}){p_end}
{phang}{cmd:. submatrix results, rownames(b pvalue) colnames(tenure c.tenure#c.tenure south i.year#1.msp) colvarlist }{p_end}
{phang}{cmd:.  matlist r(mat)', twidth(20)}{p_end}

{title:Example 3}

{pstd}Loading data{p_end}
{phang}{cmd:. webuse sysdsn1, clear}{p_end}

{pstd}Multinomial logit regression{p_end}
{phang}{cmd:. mlogit insure age male nonwhite i.site, base(3)}{p_end}

{pstd} Saving the result matrix {p_end}
{phang}{cmd:. matrix b=e(b)}{p_end}

{pstd} Selecting coefficients of age and male. for all equations but Uninsure (note the column operator). {p_end}
{phang}{cmd:. submatrix b, dropcolnames("Uninsure:") colnames(age male)}{p_end}
{phang}{cmd:. matlist r(mat)}{p_end}

{pstd} Resorting the columns by equation {p_end}
{phang}{cmd:. matrix b1=r(mat)}{p_end}
{phang}{cmd:. submatrix b1, colnames( Indemnity: Prepaid:)}{p_end}
{phang}{cmd:. matlist r(mat)}{p_end}

{marker storedresults}{...}
{title:Stored results}

{pstd}
{cmd:submatrix} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 11 15 2:Matrices}{p_end}
{synopt:{cmd:r(mat)}} the submatrix {p_end}
