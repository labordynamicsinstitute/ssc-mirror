{smcl}
{* *! version 1.0.0 15Oct2025}{...}
{title:Title}

{p2colset 5 18 19 2}{...}
{p2col:{hi:splithalf} {hline 2}} Split-half reliability {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:splithalf}
{help varlist}
{ifin}
[, {opt ran:dom} {opt rep:s(#)}]



{synoptset 18 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt ran:dom}}randomly draws items from {it:varlist} and splits them into two-halves; default is to split items into odds and evens {p_end}
{synopt :{opt rep:s(#)}}the number of times for the random draw process to be repeated when {cmd:random} is specified; default is {cmd:reps(1)} {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{opt splithalf} computes split-half reliability to assess the internal consistency of a scale or test composed of multiple items. It involves dividing the items 
into two halves (which can be performed either deterministically or randomly) and computing the correlation between the total scores for each half. A high correlation 
suggests that the items are measuring the same underlying construct. {opt splithalf} computes (1) the correlation between the two half scores, (2) the Spearman-Brown prophecy 
formula to estimate full-scale reliability from the half-test correlation and (3) the Horst reliability coefficient which adjusts for unequal-length halves (Warrens 2016).



{title:Options}

{p 4 8 2} 
{opt rand:om} randomly draws items from {it:varlist} and splits them into two halves. For an unequal number of items, there is an additional randomization to ensure the
larger group of items varies in which half it is placed. When {opt random} is not specified, the items are assigned to a half, deterministically, according to whether 
they are an odd or even observation.   

{p 4 8 2} 
{opt rep:s(#)} the number of times to repeat the randomization and measurement process when {opt random} is specified. In this case, the reported reliability estimates are 
averages across random splits.



{title:Examples}

{pstd}
    Setup

{phang2}{cmd:. use "https://www.stata-press.com/data/r19/sp2.dta", clear}{p_end}
		
{pstd}compute split-half reliability assigning items deterministically to each half (odds and evens){p_end}		
{phang2}{cmd:. splithalf pf01- pf06}{p_end}

{pstd}assign items randomly to each half (one repetition){p_end}		
{phang2}{cmd:. splithalf pf01- pf06, rand}{p_end}

{pstd}assign items randomly to each half (10 repetitions){p_end}		
{phang2}{cmd:. splithalf pf01- pf06, rand reps(10)}{p_end}

{pstd}compute split-half reliability on an odd number of items using randomization {p_end}		
{phang2}{cmd:. splithalf pf01- pf06 mhp01, rand reps(10)}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:splithalf} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 10 14 2: Scalars}{p_end}
{synopt:{cmd:r(corr)}}correlation coefficient{p_end}
{synopt:{cmd:r(sb)}}Spearman-Brown prophecy coefficient{p_end}
{synopt:{cmd:r(horst)}}Horst coefficient{p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 10 14 2: macros}{p_end}
{synopt:{cmd:r(half1_items)}}items contained in the first half{p_end}
{synopt:{cmd:r(half2_items)}}items contained in the second half{p_end}
{p2colreset}{...}



{title:Reference}

{p 4 8 2}
Warrens, M. J. 2016. A comparison of reliability coefficients for psychometric tests that consist of two parts. {it:Advances in Data Analysis and Classification} 10: 71-84.



{marker citation}{title:Citation of {cmd:splithalf}}

{p 4 8 2}{cmd:splithalf} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). SPLITHALF: Stata module to compute split-half reliability



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 7 14 2} Help: {helpb factor}, {helpb alpha}, {helpb correlate} {p_end}
