{smcl}
{* *! version 1.0.0 30Jun2023}{...}
{title:Title}

{p2colset 5 17 18 2}{...}
{p2col:{hi:robinson} {hline 2}} Robinson's coefficient of agreement {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:robinson}
{it:{help varname:rater1}} 
{it:{help varname:rater2}}
[{it:{help varname:rater3}} {it:...}]
{ifin} 


{p2colreset}{...}
{p 4 6 2}
{opt by} is allowed with {cmd:robinson}; see {manhelp by D}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{opt robinson} computes Robinson's coefficient of agreement between 2 or more raters (Robinson 1957). In the case of two raters, the coefficient is 
linearly related to the intraclass correlation (ICC) coefficient for a two-way mixed effects model by: ICC = (2 * {it:A}) - 1, where {it:A} is Robinson's 
agreement coefficient. In the case of more than 2 raters, ICC = ({it:k} * {it:A} - 1) / ({it:k} - 1), where {it:k} is the number of raters and {it:A} is Robinson's 
coefficient. The only difference between the ICC and Robinson's agreement coefficient is that the range of values of the ICC is -1 to 1, while the range of 
values of the agreement coefficient is 0 to 1 (Robinson 1957).   



{title:Examples}

{pstd}Setup {p_end}
{phang2}{cmd:. robinson.dta}{p_end}

{pstd}A banker and janitor in a small New England village were asked to rate on a 6 point scale the socioeconomic status of the families they knew in common.  {p_end}
{phang2}{cmd:. robinson banker janitor}{p_end}

{pstd}We now apply the bootstrap to compute 95% confidence intervals {p_end}
{phang2}{cmd:. bootstrap robinson = r(robinson), reps(1000): robinson banker janitor}{p_end}
{phang2}{cmd:. estat bootstrap, all}



{marker results}{...}
{title:Stored results}

{pstd}
{cmd:finn} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(nrows)}}number of rows (observations) {p_end}
{synopt:{cmd:r(ncols)}}number of columns (raters) {p_end}
{synopt:{cmd:r(ssb)}}sum of squares - between {p_end}
{synopt:{cmd:r(ssw)}}sum of squares - within{p_end}
{synopt:{cmd:r(ssr)}}sum of squares - residual{p_end}
{synopt:{cmd:r(sstotal)}}sum of squares - total{p_end}
{synopt:{cmd:r(robinson)}}Robinson's coefficient of agreement{p_end}
{p2colreset}{...}


{title:References}

{p 4 8 2}
Robinson, W. S. 1957. The statistical measurement of agreement. {it:American Sociological Review} 22: 17-25.{p_end}



{marker citation}{title:Citation of {cmd:robinson}}

{p 4 8 2}{cmd:robinson} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). ROBINSON: Stata module to compute Robinsons's coefficient of agreement.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb icc}, {helpb finn} (if installed), {helpb kappaetc} (if installed){p_end}

