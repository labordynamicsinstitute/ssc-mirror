{smcl}
{* *! version 1.0.0 09Dec2024}{...}
{title:Title}

{p2colset 5 13 14 2}{...}
{p2col:{hi:pace} {hline 2}} Convert between minutes per mile and miles per hour {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Convert minutes per mile to miles per hour

{p 8 14 2}
{cmd:mph}
{it:minutes per mile} 
[, {opt dp(#)}]

{pstd}
{it:minutes per mile} must be specified as minutes:seconds (e.g. 5:20) {p_end}


{pstd}
Convert miles per hour to minutes per mile 

{p 8 14 2}
{cmd:mpm}
{it:miles per hour} 



{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt dp(#)}}decimal places for displaying miles per hour pace; default is {cmd:one decimal place}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
The {opt pace} package converts between {it:miles per hour} and {it:minutes per mile}. This is intended to be a useful tool for runners 
who may know their pace in one metric but would like to compute their pace in the other metric (such as when running on the treadmill
and the pace is presented only in miles per hour).

 

{title:Options}

{p 4 8 2} 
{cmd:dp(#)} specifies the number of decimal places to display the {it:miles per hour} pace. Any integer specified outside of 0-3 will result
in a display of up to 8 decimal places. The default is 1 decimal place.



{title:Examples}

{pstd}
{opt (1) Convert minutes per mile to miles per hour:}{p_end}

{phang2}{cmd:. mph 6:00}{p_end}
{phang2}{cmd:. mph 5:20, dp(2)}{p_end}
{phang2}{cmd:. mph 4:40, dp(3)}{p_end}


{pstd}
{opt (2) Convert miles per hour to minutes per mile:}{p_end}
{phang2}{cmd:. mpm 10.0}{p_end}
{phang2}{cmd:. mpm 11.2}{p_end}
{phang2}{cmd:. mpm 12}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mph} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 10 14 2: Scalars}{p_end}
{synopt:{cmd:r(mph)}}miles per hour{p_end}
{p2colreset}{...}

{pstd}
{cmd:mpm} stores the following in {cmd:r()}:

{synoptset 10 tabbed}{...}
{p2col 5 10 14 2: Macro}{p_end}
{synopt:{cmd:r(mpm)}}minutes per mile{p_end}
{p2colreset}{...}



{marker citation}{title:Citation of {cmd:pace}}

{p 4 8 2}{cmd:pace} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2024). PACE: Stata module to convert between minutes per mile and miles per hour.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}

