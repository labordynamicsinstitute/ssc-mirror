{smcl}
{* *! version 0.31}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "strofnum" "help strofnum"}{...}
{viewerjumpto "Syntax" "strtonum##syntax"}{...}
{viewerjumpto "Description" "strtonum##description"}{...}
{viewerjumpto "Examples" "strtonum##examples"}{...}
{title:Title}
{phang}
{bf:strtonum} {hline 2} replaces a string variable with a categorical numeric 
variable with a value label.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:strtonum}
varlist(min=1)
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt b:ase(#)}} Start value for the value label definition. 
Default value is 1.{p_end}
{synopt:{opt k:eep}} Option for keeping the original string variables.
The original variable is renamed with a __ prefix and placed after the new 
numeric variable{p_end}
{synopt:{opt l:abel(name)}} specifies the name of the value label to be used
and added to if the named value label already exists{p_end}
{synopt:{opt e:xtend}} specifies that {varname} will be encoded if there are 
values contained in {it:varname} that are not present in {opt l:abel(name)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:strtonum} transforms a string variable into a numerical integer variable with
a value label starting with the value specified by the base option.{p_end}
{pstd}Default is 1.{p_end}
{pstd}
The variable label is copied to the new variable.

{marker examples}{...}
{title:Examples}

{phang}{stata `"sysuse auto, clear"'}{p_end}
{phang}{stata `"strtonum make"'}{p_end}

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
