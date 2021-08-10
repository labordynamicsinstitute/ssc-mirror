{smcl}
{* *! version 1.0  7 Jun 2021}{...}
{viewerjumpto "Syntax" "_gmarktop##syntax"}{...}
{viewerjumpto "Description" "_gmarktop##description"}{...}
{viewerjumpto "Options" "_gmarktop##options"}{...}
{viewerjumpto "Author and support" "crossmat##author"}{...}

{title:Title}
{phang}
{bf:egen marktop} {hline 2} collapsing a categorical variable

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:egen}
{it:newvar}
{cmdab: = marktop(}{it:oldvar}{cmdab:)}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Optional}
{synopt:{opt t:op(#)}} Keep top most frequent. Default value is 5

{synopt:{opt s:ingles(numlist)}} A {help numlist} of {it:oldvar} values to keep 
as singles

{synopt:{opt o:ther(string)}} String label for the categori of the remaining 
values. Default value is "other"

{synopt:{opt r:eplace}}  Replace {it:newvar} if it exists

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}A categorical variable is collapsed into a new variable {it:newvar} 
keeping the {opt top} most frequent and/or a subsample of {it:oldvar} values as
single values while collapsing the remaining values into one value with label 
{opt other}.


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}


