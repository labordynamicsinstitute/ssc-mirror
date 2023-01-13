{smcl}
{.-}
help for {cmd:docxtab} {right:(Roger Newson)}
{.-}
 
{title:List variables to a {cmd:.docx} table with head or foot rows from {help char:characteristics}}

{p 8 21 2}
{cmd:docxtab} [ {varlist} ] {ifin} , {opt tab:lename(tablename)} [
  {break}
  {cmdab:headc:hars}{cmd:(}{it:namelist}{cmd:)} {cmdab:footc:hars}{cmd:(}{it:namelist}{cmd:)}
  {cmdab:headf:ormat}{cmd:(}{it:cell_fmt_options}{cmd:)} {cmdab:footf:ormat}{cmd:(}{it:cell_fmt_options}{cmd:)}
  {cmdab:tcol:chars}{cmd:(}{it:namelist}{cmd:)}
  {cmdab:trow:seq}{cmd:(}{newvar}{cmd:)}
  {it:table_data_options}
  ]

{pstd}
where {it:tablename} is a table name for a generated table acceptable to {helpb putdocx_table:putdocx table},
{it:cell_fmt_options} are cell format options recognized by {helpb putdocx table},
and {it:table_data_options} are any options acceptable to the command 

{pstd}
{cmd:putdocx table tablename = data(}{varlist}{cmd:)} [ , {cmd:varnames} {cmd:obsno} {it:table_options} ]

{pstd}
including {cmd:varnames} and {cmd:obsno}.

{title:Description}

{pstd}
{cmd:docxtab} lists the variables in the {varlist} (or all variables, if the {varlist}
is absent) to an Office Open XML ({cmd:.docx}) table acceptable to {helpb putdocx_table:putdocx table},
with added header rows above and footer rows below,
extracted from {help char:variable characteristics}.
These characteristics may be multiple
(allowing multiple header and footer rows),
and each characteristic may be set for multiple variables by the {help ssc:SSC} package {helpb chardef}.
The generated {cmd:.docx} table table can then be modified using other {helpb putdocx_table:putdocx table} commands,
to change the formatting of rows, columns, or cells.


{title:Options for {cmd:docxtab}}

{phang}
{opt tablename(tablename)} must be specified.
It specifies a table name for the generated {cmd:.docx} table,
acceptable to {helpb putdocx_table:putdocx table}.
This {cmd:.docx} table can then be modified using further {helpb putdocx_table:putdocx table} commands,
to modify formats of rows, columns, and cells.

{phang}
{cmd:headchars(}{it:namelist}{cmd:)} specifies a list of {help char:variable characteristic names},
used to create table header rows containing the values of these characteristics for the variables in the {varlist}.
These header rows appear before the first of the table rows containing the variable values,
and also before the variable names row specified by the {cmd:varnames} option,
if that option is specified.
This option enables the user to add column header labels for the variables in the {varlist}.

{phang}
{cmd:footchars(}{it:namelist}{cmd:)} specifies a list of {help char:variable characteristic names},
used to create table footer rows containing the values of these characteristics for the variables in the {varlist}.
These header rows appear after the last of the table rows containing the variable values.
This option enables the user to add column footer labels for the variables in the {varlist}.
in multiple local macros.
For instance, the user might want two header rows,
one containing variable names, and the other containing variable labels.

{phang}
{cmd:headformat(}{it:cell_fmt_options}{cmd:)} specifies a list of {help putdocx table:cell format options},
recognized by {helpb putdocx table},
to apply to the header rows.
For instance, {cmd:headformat(italic)} specifies that the header rows will all be in italic fonts.

{phang}
{cmd:footformat(}{it:cell_fmt_options}{cmd:)} specifies a list of {help putdocx table:cell format options},
recognized by {helpb putdocx table},
to apply to the footer rows.
For instance, {cmd:footformat(italic)} specifies that the footer rows will all be in italic fonts.

{phang}
{cmd:tcolchars(}{it:namelist}{cmd:)} specifies a list of {help char:variable characteristic names},
naming characteristics set to contain table cell format options
for the corresponding variables in the {varlist}.
For instance, if a characteristic in the {it:namelist} belonging to a variable in the {varlist}
has value {cmd:halign(right)},
then the column of the generated table containing that variable will be right-aligned.

{phang}
{cmd:trowseq(}{newvar}{cmd:)} specifies the name of a generated variable,
to contain, in each observation,
the table row sequence corresponding to that observation.
If the observation does not correspond to a table row,
then the generated variable is set to missing.
A {cmd:trowseq()} variable can then be used to format a subset of table rows.
Note that, if the option {cmd:varnames} is specified,
then the table row sequence starts at the number of header rows plus 2,
but otherwise the table row sequence starts at the number of header rows plus 1.


{title:Remarks}

{pstd}
{cmd:docxtab} is intended to give the {cmd:.docx} user some of the functionality of {helpb listtab},
which is described in {help docxtab##docxtab_newson2012:Newson (2012)}.
{helpb listtab} and {cmd:docxtab} frequently use {help char:variable characteristics},
frequently set using the {help ssc:SSC} package {helpb chardef},
to create header and footer rows for tables.
The packages {helpb listtab}, {helpb chardef}, and {cmd:docxtab}
are intended mainly for use with resultssets,
which are described in {help docxtab##docxtab_newson2022:Newson (2022)},
{help docxtab##docxtab_newson2012:Newson (2012)}, {help docxtab##docxtab_newson2006:Newson (2006)},
{help docxtab##docxtab_newson2004:Newson (2004)}, and {help docxtab##docxtab_newson2003:Newson (2003)}.


{title:Examples}

{pstd}
The following example demonstrates the creation of a {cmd:.docx} document,
containing a table with one header row extracted from a characteristic
and column alignments extracted from another characteristic.
The table has 1 row for each of the 22 non-US car models in the {helpb sysuse:auto} data.

{pstd}
Set up:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep if foreign}{p_end}
{phang2}{cmd:. describe, full}{p_end}

{pstd}
Assign characteristics {cmd:varhandle} and {cmd:colfmt} to variables {cmd:make}, {cmd:mpg}, and {cmd:weight},
using the {help ssc:SSC} package {helpb chardef}:

{phang2}{cmd:. chardef make mpg weight, char(varhandle) values("Car model" "Miles per US gallon" "Weight (US pounds)")}{p_end}
{phang2}{cmd:. chardef make mpg weight, char(colfmt) values("halign(left)" "halign(right)" "halign(right)")}{p_end}
{phang2}{cmd:. char list}{p_end}

{pstd}
Create document in the file {cmd:myword.docx},
with the first line of variable handles italicized,
and the table columns aligned left, right, and right:

{phang2}{cmd:. putdocx begin,  pagesize(A4)}{p_end}
{phang2}{cmd:. docxtab make mpg weight, tablename(mytable) headchar(varhandle) headformat(italic) tcolchar(colfmt)}{p_end}
{phang2}{cmd:. return list}{p_end}
{phang2}{cmd:. putdocx describe mytable}{p_end}
{phang2}{cmd:. putdocx save "myword.docx", replace}{p_end}

{pstd}
The following more advanced example inputs odd-numbered car models from the {helpb sysuse:auto} data,
and creates a {cmd:.docx} document,
containing a table of car models,
with separate gap rows introducing the US and non-US cars.
To do this, we use the {help ssc:SSC} packages
{helpb chardef}, {helpb insingap}, {helpb ingap}, and {helpb sdecode}.

{pstd}
Set up

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep if mod(_n,2)}{p_end}
{phang2}{cmd:. describe, full}{p_end}

{pstd}
Create document

{phang2}{cmd:. putdocx begin, pagesize(A4)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clonevar rowlab=make}{p_end}
{phang2}{cmd:. sdecode mpg, replace}{p_end}
{phang2}{cmd:. sdecode weight, replace}{p_end}
{phang2}{cmd:. chardef rowlab mpg weight, char(varhandle) values("Car model" "Miles per US gallon" "Weight (US pounds)")}{p_end}
{phang2}{cmd:. insingap foreign, row(rowlab) grdecode(foreign) prefix("Odd-numbered ") suffix(" Cars:") gapind(gapobs)}{p_end}
{phang2}{cmd:. docxtab rowlab mpg weight, tablename(theirtable) headchar(varhandle) headformat(italic) trowseq(rowseq)}{p_end}
{phang2}{cmd:. levelsof rowseq if gapobs, local(gaplist)}{p_end}
{phang2}{cmd:. putdocx table theirtable(`gaplist',.), bold}{p_end}
{phang2}{cmd:. putdocx table theirtable(.,.), halign(right)}{p_end}
{phang2}{cmd:. restore}{p_end}
{phang2}{cmd:. putdocx save "theirword.docx", replace}{p_end}

{pstd}
Note that we generate the table between a {helpb preserve} statement and a {helpb restore} statement,
because we modify existing variables and add new ones when generating the table.
We use {helpb clonevar} and {helpb sdecode} to create the variables be tabulated,
as string variables.
We use {helpb chardef} as before, to set the characteristic {cmd:varhandle}
for these variables.
We use {helpb insingap} to add gap rows to the dataset in memory,
containing gap row labels.
We then use {cmd:docxtab} to create the first version of the table,
with a {cmd:trowseq()} option to store the table row sequence numbers in the variable {cmd:rowseq},
and then use {helpb putdocx table} to modify the gap rows to be bold,
and to right-justify all cells in the table.

{pstd}
More complicated examples are possible,
generating more complicated tables with multiple head and/or foot rows
from multiple variable characteristics.


{title:Saved results}

{pstd}
{cmd:docxtab} saves the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(fbody)}}first row of table body{p_end}
{synopt:{cmd:r(lbody)}}last row of table body{p_end}
{synopt:{cmd:r(nbody)}}number of rows in table body{p_end}
{synopt:{cmd:r(fhead)}}first row of table head{p_end}
{synopt:{cmd:r(lhead)}}last row of table head{p_end}
{synopt:{cmd:r(nhead)}}number of rows in table head{p_end}
{synopt:{cmd:r(ffoot)}}first row of table foot{p_end}
{synopt:{cmd:r(lfoot)}}last row of table foot{p_end}
{synopt:{cmd:r(nfoot)}}number of rows in table foot{p_end}
{synopt:{cmd:r(nrow)}}total number of rows in table{p_end}
{synopt:{cmd:r(ncol)}}total number of columns in table{p_end}
{p2colreset}{...}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(varlist)}}input {varlist}{p_end}
{synopt:{cmd:r(tcolseq)}}list of table column sequences corresponding to input {varlist}{p_end}
{p2colreset}{...}

{pstd}
The total number of rows in the table {cmd:r(nrow)}
is equal to the sum of {cmd:r(nhead)}, {cmd:r(nbody)}, and {cmd:r(nfoot)}
(the numbers of rows in the table head, body, and foot, respectively),
plus one more row of variable names if the option {cmd:varnames} is specified.
The total number of columns in the table {cmd:r(ncol)}
is equal to the total number of variables in the input {varlist},
plus one more column of table body row sequence numbers,
if the {cmd:obsno} option is specified.
The options {cmd:varnames} and {cmd:obsno}
will probably not be necessary very often.


{title:Author}

{pstd}
Roger Newson, King's College London, UK.
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{marker references}{title:References}

{phang}
{marker docxtab_newson2022}{...}
Newson, R. B.  2022.
Resultssets in resultstables in Stata 16-plus.
Presented at {browse "http://ideas.repec.org/s/boc/lsug22.html" :the 2022 London Stata Conference, London, 8 September, 2022}.

{phang}
{marker docxtab_newson2012}{...}
Newson, R. B.  2012.
From resultssets to resultstables in Stata.
{it:The Stata Journal} 12 (2): 191-213.
Download from {browse "http://www.stata-journal.com/article.html?article=st0254":{it:The Stata Journal} website}.

{phang}
{marker docxtab_newson2006}{...}
Newson, R.  2006. 
Resultssets, resultsspreadsheets and resultsplots in Stata.
Presented at {browse "http://ideas.repec.org/s/boc/dsug06.html" :the 4th German Stata User Meeting, Mannheim, 31 March, 2006}.

{phang}
{marker docxtab_newson2004}{...}
Newson, R.  2004.
From datasets to resultssets in Stata.
Presented at {browse "http://ideas.repec.org/s/boc/usug04.html" :the 10th United Kingdom Stata Users' Group Meeting, London, 29 June, 2004}.

{phang}
{marker docxtab_newson2003}{...}
Newson, R.  2003.
Confidence intervals and {it:p}-values for delivery to the end user.
{it:The Stata Journal} 3(3): 245-269.
Download from {browse "http://www.stata-journal.com/article.html?article=st0043":{it:The Stata Journal} website}.


{title:Also see}

{p 4 13 2}
Help for {helpb putdocx}, {helpb putdocx_table:putdocx table}
{p_end}
{p 4 13 2}
Help for {helpb chardef}, {helpb sdecode}, {helpb ingap}, {helpb insingap}, {helpb listtab} if installed
{p_end}
