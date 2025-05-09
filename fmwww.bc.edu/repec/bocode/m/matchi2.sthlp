{smcl}
{* *! version 1.0.1 07May2025}{...}

{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:matchi2} {hline 2}} Calculates Pearson's chi-squared from a two-way matrix of frequency counts  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:matchi2}
{it:matrix_name}
[{cmd:,} 
{opth tit:le(strings:string)}]

{pstd}
{it: matrix_name} identifies a two-way matrix (i.e. containing at least two rows) of frequency counts. 


	
{title:Description}

{pstd}
{cmd:matchi2} calculates and displays Pearson's chi-squared for the hypothesis that the rows and columns in a two-way matrix are independent. It is a convenient alternative 
to {helpb tabi} when data are already stored in matrix form.



{title:Options}

{p 4 8 2}
{opth tit:le(strings:string)} title displayed above table{p_end}



{title:Examples}

{pstd}
Generate a 2 X 3 matrix of frequency counts {p_end}

{phang2}{cmd:. matrix A = (30, 18, 38 \ 13, 7, 22)}

{pstd}
Specify row and column names {p_end}

{phang2}{cmd:. matrix rownames A = Yes No}

{phang2}{cmd:. matrix colnames A = Left Center Right}


{pstd}
Redisplay the matrix in table format and report Pearson's chi-squared  {p_end}

{phang2}{cmd:. matchi2 A}

{pstd}
Add a title  {p_end}

{phang2}{cmd:. matchi2 A, title(Doesn't this work great?)}



{title:Stored results}

{pstd}
{cmd:matchi2} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 18 19 2: scalars}{p_end}
{synopt:{cmd:r(p)}}p-value for Pearson's chi-squared test{p_end}
{synopt:{cmd:r(chi2)}}Pearson's chi-squared test{p_end}
{synopt:{cmd:r(r)}}number of rows{p_end}
{synopt:{cmd:r(c)}}number of columns{p_end}



{marker citation}{title:Citation of {cmd:matchi2}}

{p 4 8 2}{cmd:matchi2} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel (2025). MATCHI2: Stata module for calculating Pearson's chi-squared from a two-way matrix of frequency counts. {p_end}



{title:Author}

{p 4 8 2}	Ariel Linden{p_end}
{p 4 8 2}	President, Linden Consulting Group, LLC{p_end}
{p 4 8 2}   alinden@lindenconsulting.org{p_end}



{title:Also see}

{p 4 8 2} Online: {helpb tabi}{p_end}

