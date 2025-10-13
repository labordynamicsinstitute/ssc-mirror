{smcl}
{* *! version 1.0.0 07Oct2025}{...}
{title:Title}

{p2colset 5 15 16 2}{...}
{p2col:{hi:menger} {hline 2}} Menger curvature {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Using data with an ordered {it:X} variable and a continuous {it:Y} variable 

{p 8 14 2}
{cmd:menger}
{it:xvar}
{it:yvar}
{ifin}
[, {opt gr:aph} {opt de:tail}]



{pstd}
Post-estimation after {helpb factor} and {helpb pca}

{p 8 14 2}
{cmd:menger_estat}
[, {opt gr:aph} ]



{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt de:tail}}display a table with the menger curvatures; available only for {opt menger} {p_end}
{synopt :{opt gr:aph}}graph of {it:yvar} on {it:xvar} with the maximum curvature (elbow) displayed{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}


{marker description}{...}
{title:Description}

{pstd}
{opt menger} computes the Menger curvature, which is a concept from geometry that measures 
how "curved" a triplet of points is, based on the circle that passes through them (see the 
{browse "https://en.wikipedia.org/wiki/Menger_curvature":wikipedia} entry for greater detail). {opt menger} iterates 
through each triplet of values in {it:yvar} and finds the curvature value. The maximum curvature point indicates 
where the curve becomes more "flat" -- generally referred to as the "elbow" or "knee". {opt menger_estat} computes 
the Menger curvature as a post-estimation command following {helpb factor} and {helpb pca}, as a means of finding an alternative number 
of factors (components) to that used in Stata's official {helpb factor} or "eye-balled" with {helpb screeplot}.



{title:Options}

{p 4 8 2} 
{opt de:tail} displays a table of each value of {it:yvar} and its corresponding curvature value. This allows
the user to see where the maximum curvature value is located, and its corresponding {it:xvar} value. {opt detail}
is only available for {opt menger}.

{p 4 8 2} 
{opt gr:aph} displays a graph of {it:yvar} on {it:xvar} with the maximum curvature (elbow) displayed. When specified
in {opt menger_estat}, the graph is identical to that implemented in {helpb screeplot}.



{title:Examples}

{pstd}
{opt (1) Compute Menger curvature from data:}{p_end}

    Setup (enter data directly into Stata)
        {cmd:. clear all}
        {cmd:. input factor eigenvalue}
		{cmd:1 1.08361}
		{cmd:2 0.76609}
		{cmd:3 0.22793}
		{cmd:4 0.03324}
		{cmd:5 0.01239}
		{cmd:6 -0.00017}
		{cmd:end}

{pstd}compute the Menger curvature, show the details of each computation and graph the results{p_end}

{phang2}{cmd:. menger factor eigenvalue, detail graph}{p_end}


{pstd}
{opt (2) Compute the Menger curvature after {helpb factor}:}{p_end}

    Setup
        {cmd:. use "https://www.stata-press.com/data/r19/sp2.dta", clear}
		
{pstd}perform a factor analysis{p_end}		
{phang2}{cmd:. factor ghp31- ghp05, ipf}{p_end}

{pstd}find the "elbow" empirically using the menger curvature and display the results in a graph{p_end}	
{phang2}{cmd:. menger_estat, gr}{p_end}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:menger} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 10 14 2: Scalars}{p_end}
{synopt:{cmd:r(elbow)}}the corresponding point on {it:xvar} where the maximum curvature is located{p_end}
{p2colreset}{...}

{synoptset 12 tabbed}{...}
{p2col 5 10 14 2: Matrix}{p_end}
{synopt:{cmd:r(results)}}matrix containing the {it:xvars}, {it:yvars}, and curvatures{p_end}
{p2colreset}{...}


{pstd}
{cmd:menger_estat} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 10 14 2: Scalar}{p_end}
{synopt:{cmd:r(elbow)}}the corresponding point on {it:xvar} where the maximum curvature is located{p_end}
{p2colreset}{...}



{marker citation}{title:Citation of {cmd:menger}}

{p 4 8 2}{cmd:menger} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). MENGER: Stata module to compute the Menger curvature.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}

