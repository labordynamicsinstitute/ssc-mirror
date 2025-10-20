{smcl}
{* *! version 1.0.0 18Oct2025}{...}
{title:Title}

{p2colset 5 19 20 2}{...}
{p2col:{hi:rotatesort} {hline 2}} sorts factors in descending order of loadings after rotate {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:rotatesort}
[{cmd:,} 
{opt for:mat}{cmd:(}{it:{help format:%fmt}}{cmd:)} 
{opt bl:anks}{cmd:(}{it:#}{cmd:)}
]


{pstd} {opt rotatesort} will only work following {helpb rotate}



{synoptset 16 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth for:mat(%fmt)}}display format for the factor loadings; default is {cmd:format(%9.5f)}{p_end}
{synopt:{opt bl:anks(#)}}display loadings as blank when |loading| < {it:#}; default is {cmd:blanks(0)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...} 
{title:Description}

{pstd}
{opt rotatesort} is a convenience tool for researchers who prefer to review the results of {helpb rotate} in descending order of the factor loadings. Sorting
the factor loadings in descending order serves two purposes. It more clearly highlights: (1) which loadings belong to which factors, and (2) which items in
a factor have the highest loadings. This is helpful for choosing which items to retain in the item reduction process.  



{title:Options}

{p 4 8 2}
{opth for:mat(%fmt)} specifies the format for displaying the factor loadings; default is {cmd:format(%9.5f)}.

{p 4 8 2} 
{opt bl:anks}{cmd:(}{it:#}{cmd:)} shows blanks for loadings with absolute values smaller than {it:#}.  



{title:Examples}

{pstd}Setup

{phang2}{cmd:. use "https://www.stata-press.com/data/r19/sp2.dta", clear}{p_end}
		
{pstd}we perform factor analysis using the PCF method and limit the output to 3 factors{p_end}		
{phang2}{cmd:. factor ghp31- ghp05, pcf factor(3)}{p_end}

{pstd}we then rotate the factors and suppress output for |values| < 0.40. We also normalize the values{p_end}		
{phang2}{cmd:. rotate, normal blanks(0.40)}{p_end}

{pstd}we now use {opt rotatesort} to resort the factor loadings in descending order suppressing |values| < 0.40. {p_end}		
{phang2}{cmd:. rotatesort, bl(0.40)}{p_end}

{pstd}It is now clear which items belong to which factors, and which items load the highest per factor {p_end}		



{marker citation}{title:Citation of {cmd:rotatesort}}

{p 4 8 2}{cmd:rotatesort} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). ROTATESORT: Stata module to sort factors in descending order of loadings after rotate



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 7 14 2} Help: {helpb factor}, {helpb rotate} {p_end}
