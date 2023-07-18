{smcl}
{* *! version 1.0.0 16Jul2023}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:maxwell} {hline 2}} Maxwell's random error (RE) coefficient of agreement between 2 raters for binary data  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Using data stored in memory

{p 8 17 2}
{cmd:maxwell} {it:{help varname:rater1}} {it:{help varname:rater2}} [if] [in] [{cmd:,} {opt tab}] 


{pstd}
Immediate form of {cmd:maxwelli}

{p 8 17 2}
{cmd:maxwelli} {it:#a #b #c #d} [{cmd:,} {opt tab}] 


{pstd}
Immediate form of {cmd:maxwelli} referring to a saved 2 X 2 matrix

{p 8 17 2}
{cmd:maxwelli} {it:{help matrix define:matname}}  [{cmd:,} {opt tab}]


{phang}
{it:#a}: (rater1 = 1 and rater2 = 1); {it:#b}: (rater1 = 1 and rater2 = 0); 
{it:#c}: (rater1 = 0 and rater2 = 1); {it:#d}: (rater1 = 0 and rater2 = 0).
{it:#a}, {it:#b}, {it:#c}, and {it:#d} must all be positive integers.    


{synoptset 19 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt tab}}display 2 X 2 contingency table{p_end}
{synoptline}

 
{p 4 6 2}
{p2colreset}{...}				
	
{title:Description}

{pstd}
{cmd:maxwell} computes Maxwell's random error (RE) coefficient of agreement between 2 raters on a binary variable (Maxwell 1977). The RE coefficient measures the excess
of agreement over disagreement between two raters. It is attractive because of the weak assumptions in its derivation: doubtful cases are resolved in a truly random way
without reference to prior probabilities of incidence, and allowance is made for the possibility that {it:a}, the probability of agreement between raters, may differ
from cases in which an outcome is positive to those in which it is negative (Maxwell 1977).   

{pstd}
{cmd:maxwelli} is the immediate form of {cmd:maxwell}; see {help immed}.


{title:Options}

{p 4 8 2}
{cmd:tab} requests that the data be displayed in a 2 X 2 contingency table with both column and row percentages presented.


{title:Examples}

{pstd}Using data stored in memory{p_end}

{phang2}{cmd:. use maxwell.dta}{p_end}

{phang2}{cmd:. maxwell rater1 rater2}{p_end}

{phang2}{cmd:. bootstrap re = r(maxwell), reps(1000): maxwell rater1 rater2}{p_end}

{pstd}Entering values manually using {cmd:maxwelli}{p_end}

{phang2}{cmd:. maxwelli 13 3 2 12}{p_end}

{phang2}{cmd:. maxwelli 13 3 2 12, tab}{p_end}

{pstd}Referring to a matrix using {cmd:maxwelli}{p_end}

{phang2}{cmd:. matrix input B = (13 3\2 12)}{p_end}

{phang2}{cmd:. maxwelli B, tab}{p_end}


{title:Stored results}

{pstd}
{cmd:maxwell} and {cmd:maxwelli} store the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(ntar)}}number of targets (observations){p_end}
{synopt:{cmd:r(nrat)}}number of raters (will always be two){p_end}
{synopt:{cmd:r(maxwell)}}Maxwell's RE coefficient{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Maxwell, A. E. 1977. Coefficients of agreement between observers and their interpretation. {it:British Journal of Psychiatry} 130: 79-83.


{marker citation}{title:Citation of {cmd:maxwell}}

{p 4 8 2}{cmd:maxwell} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2023). MAXWELL: Stata module for computing Maxwell's random error (RE) coefficient of agreement between 2 raters for binary data {p_end}


{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{p_end}
{p 4 8 2}{browse "http://www.lindenconsulting.org"}{p_end}

         

{title:Also see}

{p 4 8 2} Online: {helpb kappa}, {helpb kappaetc} (if installed){p_end}

