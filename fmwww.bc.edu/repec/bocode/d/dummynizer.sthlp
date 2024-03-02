{smcl}
{* *! version 0.31}{...}
{viewerjumpto "Syntax" "ado_nhb/dummynizer##syntax"}{...}
{viewerjumpto "Description" "ado_nhb/dummynizer##description"}{...}
{viewerjumpto "Examples" "ado_nhb/dummynizer##examples"}{...}
{viewerjumpto "Examples" "ado_nhb/dummynizer##examples"}{...}
{viewerjumpto "Author and support" "ado_nhb/dummynizer##author"}{...}
{title:Title}
{phang}
{bf:dummynizer} {hline 2} Generating Stata dummy variables using Mata syntax

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:dummynizer}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt mat:acode(string)}}The mata codeblock to generate dummy variables.{p_end}
{synopt:{opt pre:fix(string)}}Choose your own prefix for variables names. Default is v.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
Generating Stata dummy variables using Mata syntax.
Names are a prefix and a four digits number.

{marker examples}{...}
{title:Examples}

{pstd}Creating a set of dummy variables.{p_end}
{phang}{stata `"dummynizer, matacode(J(3, 1, I(4)), I(3) # J(4,1,1), J(3,1,1::4), (1::3) # J(4,1,1)) prefix(demo) clear"'}{p_end}
{pstd}Listing dummy variables.{p_end}
{phang}{stata `"list, sep(4)"'}{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
