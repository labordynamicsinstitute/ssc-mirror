{smcl}
{.-}
help for {cmd:ltop} {right:(Roger Newson)}
{.-}
 
{title:Divide a dataset into pages without splitting internal by-groups}

{p 8 27}
{cmd:ltop} {it:newvarname} {ifin} {weight} ,
[
{cmdab:max:lperp(}{it:#}{cmd:)}
{cmd:by(}{varlist}{cmd:)} {cmd:iby(}{varlist}{cmd:)}
]

{pstd}
{cmd:fweight}s, {cmd:pweight}s,  {cmd:aweight}s, and {cmd:iweight}s are allowed for {cmd:ltop};
see {help weight}.


{title:Description}

{p}
{cmd:ltop} ("{ul:l}ines {ul:to} {ul:p}ages") creates a page-number variable,
dividing the dataset (or its by-groups)
into pages, with a maximum number of lines
per page,
optionally with internal by-groups which will not be split between pages.
{cmd:ltop} is designed for use when outputting datasets to multi-page tables,
using the {help ssc:SSC} packages
{helpb chardef}, {helpb listtab}, and {helpb docxtab}.
The user may weight pages, in case different font sizes are to be used,
or in case the first line of each internal by-group is preceded by a gap line.


{title:Options}

{phang}
{opt maxlperp(#)} specifies a maximum number of lines per page,
or a maximum sum of line weights per page,
if {help weight:weights} are specified..
It defaults to 50 lines, but should probably usually be set by the user.

{phang}
{opt by(varlist)} specifies a list of external by-variables,
defining external by-groups within which the generated page numbers are evaluated.
If {cmd:by()} is not set, then {cmd:ltop} uses 1 by-group,
which is the whole current dataset,
or the subset of the current dataset specified by the {helpb if} and/or {helpb in} qualifiers.

{phang}
{opt iby(varlist)} specifies a list of internal by-variables,
defining internal by-groups for the generated page numbers.
These internal by-groups will not be split between pages.
If at least 1 internal by-group has a number of lines
(or sum of line weights) greater than the {opt maxperp()} option,
then {cmd:ltop} will fail, and tell the user that this is the case.


{title:Remarks}

{p}
The {cmd:ltop} package is designed for use with the {help ssc:SSC} packages
{helpb chardef}, {helpb listtab}, and {helpb docxtab},
to create multi-page tables in multiple formats,
including {helpb markdown:Markdown},
plain TeX, LaTeX or HTML (using {helpb listtab}),
or in a .docx document created using {helpb putdocx}
(using {helpb docxtab}).
For more about the use of {helpb chardef} and {helpb listtab} to make tables,
see {help ltop##newson2012:Newson, 2012}.


{title:Examples}

{p}
The following example uses the {helpb sysuse:auto} dataset,
distributed with Stata,
to create a multi-page table of weight and mileage in the car models,
with a limit of 16 table rows per page,
ordered alphabetically by car model,
and with all the models from each firm in the same table page.

{p}
Set-up {helpb sysuse:auto} data and sort by firm and make:

{p 8 16}{inp:. sysuse auto, clear}{p_end}
{p 8 16}{inp:. gene firm=word(make,1)}{p_end}
{p 8 16}{inp:. lab var firm "Firm"}{p_end}
{p 8 16}{inp:. sort firm make}{p_end}
{p 8 16}{inp:. describe, full}{p_end}
{p 8 16}{inp:. tab firm, miss}{p_end}

{p}
Create page number variable {cmd:mypage}:

{p 8 16}{inp:. ltop mypage, iby(firm) maxlperp(16)}{p_end}
{p 8 16}{inp:. list firm make weight mpg mypage, sepby(mypage)}{p_end}

{p}
Create {help markdown:Markdown} document {cmd:mymddoc1.md} with multi-page table
using a {helpb capture:capture noisily} group
and the {help ssc:SSC} packages {helpb chardef} and {helpb listtab}:

{p 8 16}{inp:. tempname mdb1}{p_end}
{p 8 16}{inp:. file open `mdb1' using `"mymddoc1.md"', write replace}{p_end}
{p 8 16}{inp:. capture noisily {c -(}}{p_end}
{p 8 16}{inp:.   file write `mdb1' "# Table of weight and mileage of cars in the auto data by firm" _n}{p_end}
{p 8 16}{inp:.   chardef make weight mpg, char(varname) pref(*) suff(*) val("Car model" "Weight (US pounds)" "Mileage (mpg)")}{p_end}
{p 8 16}{inp:.   chardef make weight mpg, char(halign) val(":---" "---:" "---:")}{p_end}
{p 8 16}{inp:.   levelsof mypage, lo(mypages)}{p_end}
{p 8 16}{inp:.   foreach MP of num `mypages' {c -(}}{p_end}
{p 8 16}{inp:.     preserve}{p_end}
{p 8 16}{inp:.     keep if mypage==`MP'}{p_end}
{p 8 16}{inp:.     file write `mdb1' "## Car weight and mileage by firm, Page `MP'" _n}{p_end}
{p 8 16}{inp:.     listtab make weight mpg, handle(`mdb1') rstyle(markdown) headc(varname halign) type}{p_end}
{p 8 16}{inp:.     restore}{p_end}
{p 8 16}{inp:.   {c )-}}{p_end}
{p 8 16}{inp:. {c )-}}{p_end}
{p 8 16}{inp:. file close `mdb1'}{p_end}

{p}
Convert {help markdown:Markdown} document {cmd:mymddoc.md} to HTML document {cmd:mymddoc.htm}:

{p 8 16}{inp:. markdown mymddoc1.md, saving(mymddoc1.htm) replace}{p_end}

{p}
For more about {help capture:capture noisily groups},
see {help ltop##newson2017:Newson, 2017}.
For more about the {help ssc:SSC} packages {helpb listtab} and {helpb chardef},
and their role in making tables with header labels,
see {help ltop##newson2012:Newson, 2012}.

{p}
Alternatively, we could have used the {help ssc:SSC} packages {helpb chardef} and {helpb docxtab},
with the {helpb putdocx} utility,
to make a {cmd:.docx} file containing multi-page tables with real pages,
each with a page number and a page count,
suitable for printing to hardcopy.
The program to do this would be a bit more complicated.


{title:Author}

{p}
Roger Newson, King's College London, UK.
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{marker references}{title:References}

{marker newson2012}{phang}
Newson, R. B.  2012.
From resultssets to resultstables in Stata.
{it:The Stata Journal} 12 (2): 191-213.
Download from {browse "http://www.stata-journal.com/article.html?article=st0254":{it:The Stata Journal} website}.

{marker newson2017}{phang}
Newson, R. B.  2017.
Stata Tip 127: Use {cmd:capture noisily} groups.
{it:The Stata Journal} 17 (2): 511-514.
Download from {browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X1701700215":{it:The Stata Journal} website}.


{title:Also see}

{psee}
Manual:  {manlink U weight}, {manlink P capture}

{psee}
{space 2}Help:  {manhelp weight U}, {manhelp capture P}
{p_end}

{psee}
On-line: help for {helpb chardef}, {helpb listtab}, {helpb docxtab} if installed
{p_end}
