{smcl}
{* 12oct2010}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "del" "del"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: dd} {hline 2} List and/or hilight variables matching name patterns or other characteristics

{title:Syntax}

{p 8 15 2}{cmd:dd} [{it:{help varelist}}] [{cmd:using} {it:{help path_el}}] [, {opt p:lain} {opt hi:light(varlist)} {opt a:lpha} {opt out(details)}]

{title:Description}

{pstd}{cmd:dd} provides a compact listing of variables similar to {cmd:ds}; however, the display is {bf:paged} so that, no matter how large the dataset, you can always look at a full screen of contiguous variables.
Also, options allow the specification of both variables to display, and variables to highlight.

{pstd}If no highlighting options are specified, variables from Stata datasets are output in three colors: one for strings, one for  numeric variables that have at least one non-missing value labeled (as a proxy for "categorical"),
and one for all other numeric variables. For non-Stata datasets (which require access to StatTransfer), only string and numeric are distinguished.

{pstd}The variables listed will be those for the data in memory, unless {cmd:using} is specified, in which case the variables will be from the specified data file.

{title:Options}
 
{phang}{opt p:lain} causes all variables to be displayed in a single color.
 
{phang}{opt hi:light(varlist)} causes variables to be displayed in two colors: one for the variables specified in {opt hi:light(varlist)} and one for the rest.

{phang}{opt a:lpha} causes the variables to be listed in alphabetical order, instead of dataset order.

INCLUDE help tabel_out2

{title:Examples}

{phang}{cmd:. dd}

{phang}{cmd:. dd some*, hilight(some*subgroup)}

{phang}{cmd:. dd using anotherfile}

{phang}{cmd:. dd a* b-c using anotherfile, hi(b*)}

