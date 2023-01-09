{smcl}
{* *! version 0.28 2022-12-30}{...}
{viewerjumpto "Syntax" "subselect##syntax"}{...}
{viewerjumpto "Description" "subselect##description"}{...}
{viewerjumpto "Examples" "subselect##examples"}{...}
{viewerjumpto "Author" "subselect##author"}{...}
{title:Title}

{phang}
{bf:subselect} {hline 2} Mark all group ids that satisfy {help if} and {help in} 
conditions at least once

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:subselect}
varlist
[{help if}]
[{help in}]
[using]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt g:enerate(name)}}Specify name of generated marker variable.
One of options {opt g:enerate(name)}, {opt k:eep}, or {opt d:rop} must be set

{synopt:{opt c:lear}}In combination with {opt:using}. Clears data editor

{synopt:{opt r:eplace}}Replace the marking variable named in {opt g:enerate(name)}

{synopt:{opt n:egate}}Negate the marking

{synopt:{opt k:eep}}Keep if at least one marking. 
One of options {opt g:enerate(name)}, {opt k:eep}, or {opt d:rop} must be set.
No marking variable is created

{synopt:{opt d:rop}}Drop if at least one marking.
One of options {opt g:enerate(name)}, {opt k:eep}, or {opt d:rop} must be set.
No marking variable is created


{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{title:Description}
{pstd}
{cmd:subselect} generates a marker variable with name specified by option 
{opt gen:erate(name)}. The grouping variable is specified the varname argument.
The marker marks all group ids, where at least one row per group id satisfies 
the conditions in {help if} and {help in}.

{marker examples}{...}
{title:Examples}

{pstd}Example data:{p_end}
{phang}{stata `"use http://www.stata-press.com/data/r15/nlswork.dta, clear"'}{p_end}

{pstd}The nlswork data frame contains data about 4711 young working women who 
had an age of 14–26 years in 1968. 
These data are collected within the "National Longitudinal Survey" over the 
years 1968-1988 (with gaps). 
There are 28534 observations in total.
The unique keys are variables {it:idcode} and {it:year}.

{pstd}Mark all persons (idcode) that at some row in the dataset has been minor (age 18 or below):{p_end}
{phang}{stata `"subselect idcode if age <= 18, gen(age18)"'}{p_end}

{pstd}To see the generated variable for the first 2 person ids:{p_end}
{phang}{stata `"list idcode age age18 if idcode < 3, noobs sepby(idcode)"'}{p_end}
{pstd}The person with idcode 1 has age 18 at start and is marked whereas the person
with idcode 2 do not age 18 at any time and hence is not marked.{p_end}

{pstd}Using {help sumat} to see unique number of persons at different ages:{p_end}
{phang}{stata `"sumat idcode, statistics(unique) rowby(age) decimals(0)"'}{p_end}

{pstd}To see the unique number of persons who has been minor in the dataset at least once:{p_end}
{phang}{stata `"sumat idcode if age18, statistics(unique) rowby(age) decimals(0)"'}{p_end}
{pstd}By restricting the to the persons who are minor at some age some of the 
higher ages are excluded.{p_end}

{pstd}To see unique number of persons who never has been minor in the dataset at different ages:{p_end}
{phang}{stata `"sumat idcode if !age18, statistics(unique) rowby(age) decimals(0)"'}{p_end}

{pstd}To keep all rows for persons by {it:idcode} having no missing registration 
of the variable {it:union} {p_end}
{phang}{stata `"subselect idcode if mi(union) using "http://www.stata-press.com/data/r15/nlswork.dta", clear negate keep"'}{p_end}
{pstd}Now we only have persons with no missing registration of {it:union}{p_end}
{phang}{stata `"codebook union"'}{p_end}

{pstd}To drop all rows for persons by {it:idcode} who never have been maried in the 
period from year 68 to year 88. {p_end}
{phang}{stata `"subselect idcode if msp using "http://www.stata-press.com/data/r15/nlswork.dta", clear negate drop"'}{p_end}
{pstd}To see the selected rows for the first 2 person ids:{p_end}
{phang}{stata `"list idcode msp if inlist(idcode, 1, 2), noobs sepby(idcode)"'}{p_end}
{pstd}The person with idcode 1 has been married in the years 71 to 75 whereas 
person with idcode 2 have been married in the years 71 to 83.{p_end}

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
