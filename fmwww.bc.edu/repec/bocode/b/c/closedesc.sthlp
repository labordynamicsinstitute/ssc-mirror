{smcl}
{* *! version 1.0.0  25sept2018}{...}
{vieweralsosee "[D] describe" "help describe"}{...}
{vieweralsosee "[D] ds" "help ds"}{...}
{vieweralsosee "findname" "help findname"}{...}
{viewerjumpto "Syntax" "closedesc##syntax"}{...}
{viewerjumpto "Description" "closedesc##description"}{...}
{viewerjumpto "Examples" "closedesc##examples"}{...}
{viewerjumpto "Stored results" "closedesc##results"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{cmd:closedesc} {hline 2}}Describe other variables close to a variable{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}{cmd:closedesc} {it:{help varname:varname}}
    , [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt n(#)}}number of variables before and/or after the focal variable, the default is 3 {p_end}
{synopt:{opt forw:ard}}only display variables after the focal variable, the default is {it:forward} and {it:backward}{p_end}
{synopt:{opt backw:ard}}only display variables before the focal variable, the default is {it:forward} and {it:backward}{p_end}

{synoptline}
{p2colreset}{...}
	

{marker description}{...}
{title:Description}

{pstd}
{cmd:closedesc} describes variables close to a variable. Often datasets order
their variables by topic, so if you found a relevant variable in a dataset, it often
helps to also look at the variables around it. Similar to when you find a book
in a library, it often pays to look at the other books on the same shelf.  


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse nlsw88}{p_end}

{pstd}Find three variables before and after {cmd:union}{p_end}
{phang2}{cmd:. closedesc union}{p_end}

{pstd}Find three variables before {cmd:union}{p_end}
{phang2}{cmd:. closedesc union, backward}{p_end}

{pstd}Find five variable after {cmd:union} (except that in the dataset there are 
only four variables after {cmd:union}){p_end}
{phang2}{cmd:. closedesc union, forward n(5)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:closedesc} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(varlist)}}the varlist of found variables{p_end}
{p2colreset}{...}
