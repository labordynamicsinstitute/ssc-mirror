{smcl}
{* *! version 1.0.0 21Aug2023}{...}
{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:cvequal} {hline 2}} Equality of coefficients of variation (CV) from {it:k} populations {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:cvequal}
{it:{help varname:varname}} 
{ifin}
, {opt by}{cmd:(}{it:{help varname:groupvar}{cmd:)}}


 
{marker description}{...}
{title:Description}

{pstd}
{opt cvequal} tests the hypothesis that the coefficients of variation (CV) are the same for {it:k} populations, with unequal sample sizes (Feltz & Miller 1996). 
This statistic is invariant under the choice of the order of the populations, and is asymptotically chi2. (Feltz & Miller 1996).  



{title:Options}

{p 4 8 2}
{opt by}{cmd:(}{it:{help varname:groupvar}{cmd:)}} is required.  It specifies a variable that identifies the groups. {p_end}



{title:Example}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse census}{p_end}

{pstd}Test equality of the coefficient of variation for the median age across all regions simultaneously
{p_end}
{phang2}{cmd:. cvequal medage, by(region)}



{title:Stored results}

{pstd}
{cmd:cvequal} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(df)}}degrees of freedom{p_end}
{synopt:{cmd:r(chi2)}}chi-squared{p_end}
{synopt:{cmd:r(pval)}}p-value for the chi-squared distribution{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Feltz, C. J., & G. E. Miller. 1996. An asymptotic test for the equality of coefficients of variation (CV) from k populations. {it:Statistics in Medicine} 15: 647-658.{p_end}



{marker citation}{title:Citation of {cmd:cvequal}}

{p 4 8 2}{cmd:cvequal} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2023). CVEQUAL: Stata module to compute the equality of coefficients of variation (CV) from {it:k} populations.



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb wscv} (if installed){p_end}

